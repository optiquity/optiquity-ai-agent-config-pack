# IMPL-REPORT — BD-219 C2 (static-matrix `tests` job + wired-set re-point)

**Agent:** fresh pack-coder (isolated worktree) · **Date:** 2026-06-15
**Commit slice:** BD-219 C2 · **Scope:** `pack-only` (5 modified files, all pack-side)

---

## 1. REGIME BLOCK (runtime-verified, not trusted from settings)

| Probe | Value |
|---|---|
| `pwd` / `git rev-parse --show-toplevel` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a56e8235518b59613` |
| Main checkout (per prompt) | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (≠ toplevel) |
| **REGIME** | **ISOLATED** (toplevel is a `.claude/worktrees/` worktree, ≠ the main checkout) |
| `git rev-parse HEAD` (start) | `cf427690d2e606a3022d534321b5f1cf74629433` — matches required parent HEAD `cf42769` ✓ |
| `git rev-parse HEAD` (end) | `cf427690d2e606a3022d534321b5f1cf74629433` (UNCHANGED — agents-never-commit honored) |
| `git status --short` (start) | clean |
| `git branch --show-current` | `worktree-agent-a56e8235518b59613` |

**Isolation mis-based check:** HEAD == `cf42769` (NOT origin/main); contains BD-219 C1 + C3 + the C2 design docs as expected. Not mis-based.

**Merge-back handoff:** `/tmp/handoff-bd219-c2/c2-modified.patch` (`git diff HEAD`, 814 lines, 5 files) + this report. No new files (modified-files-patch case per plan §EE-9). No staging/commit performed.

---

## 2. CAPTURED FROZEN `include` PARTITION (plan §4.0 — generated FIRST, from the pre-edit yml)

`python3 scripts/lib/ci-shard-plan.py --emit-matrix` run against the PRE-C2 yml (still carrying the 71 `run: bash` lines at that instant) → EXIT 0. The captured 4-shard / 71-test partition (balanced ~119.5s/shard; shard 1 is the FIXTURE-OWNER carrying all 5 `FIXTURE_COHESION_GROUP` members) was pasted verbatim into the static `tests`-job `matrix.include`:

- **shard 1 (22 tests, FIXTURE-OWNER):** tracker-migrate-reverse-test, test-migrate-v10-to-v11, test-persona-contracts, test-tracker-promote-path2, test-migrator-core, test-detect, test-dry-run-migration, test-migrator-skills, test-tracker-promote-path1, template-version-test, test-add-capability, test-tracker-links, test-v11-realistic-ot, tracker-agent-read-test, tracker-bd133-header-preservation-test, tracker-deferral-gate-test, test-validate-pack-check-16, test-validate-pack-check-40, test-validate-pack-check-44, test-validate-pack-check-51-flip-block, test-validate-pack-check-55, test-compare-agent-trinity
- **shard 2 (14 tests):** test-migrate-v10-to-v11-gates, test-activate-capability, test-validate-pack-checks-58-59-60, test-issue-forms, test-tracker-phase-task, tracker-bd129-gh-repo-test, tracker-bd134-close-retry-test, tracker-errors-test, test-validate-pack-check-18, test-validate-pack-check-41, test-validate-pack-check-45, test-validate-pack-check-52, test-validate-pack-check-56, test-tracker-promote-direct
- **shard 3 (18 tests):** tracker-migrate-forward-test, test-migrate-v10-to-v11-decompose, test-validate-pack-check-49-field-faithfulness, test-migrator-capability-translation, test-init-project, test-ci-shard-plan, pack-help-test, recommendation-test, test-per-entry, test-validate-pack-checks-32-33-34, tracker-bd130-doctor-wired-test, tracker-config-schema-test, tracker-init-test, test-validate-pack-check-39, test-validate-pack-check-43, test-validate-pack-check-50-codec-single-source, test-validate-pack-check-54, test-validate-pack-check-removed-doc-advisory
- **shard 4 (17 tests):** tracker-migrate-roundtrip-test, test-migrate-v10-to-v11-dry-run, tracker-provider-test, test-migrator-manifest, test-customization-preserve, recommendation-state-schema-test, template-translations-test, test-tracker-cycle-check, test-validate-pack-checks-36-37-38, tracker-bd132-race-test, tracker-config-test, test-restore-from-backup, test-validate-pack-check-19, test-validate-pack-check-42, test-validate-pack-check-46, test-validate-pack-check-53, test-validate-pack-check-57

Header: `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4`. The full compact JSON is in the patch (the yml `include` block) and was saved to `/tmp/frozen-include-compact.json` in the worktree.

**Edit ordering followed (plan §4.0 anti-empty-emit):** (i) generate `include` from pre-edit yml → (ii) restructure yml → (iii) re-anchor `parse_wired_tests` → (iv) re-anchor Check 42/60 + remediation → (v) update the 2 encoding tests → (vi) regen manifest → (vii) §6 PREFLIGHT gate. The generator was run FIRST, before any `run: bash` deletion, so it never saw an empty source.

---

## 3. PER-FILE CHANGES

### 3.1 `.github/workflows/validate-pack.yml` (M; +/− large — the restructure)
- **`validate` job — UNCHANGED** (still runs full general + DEEP `validate-pack.py`, no flag, not sharded).
- **`tests` job → STATIC MATRIX.** Added `strategy: { fail-fast: false, matrix: { include: [shard 1..4] } }` (the §2 frozen partition, verbatim, one `scripts:` string per shard). DELETED all 71 per-script `- name:/if: always()/run: bash scripts/…sh` steps. Replaced with TWO steps:
  - **conditional fixture step** — `if python3 scripts/lib/ci-shard-plan.py --shard ${{ matrix.shard }} --needs-fixtures; then build.sh --all --clean; git checkout HEAD -- test-fixtures/manifest.txt; build.sh --verify; fi` (BD-115/116/117 build + BD-118 manifest-restore + BD-115 verify ORDER preserved, run ONLY in the fixture-owning shard).
  - **run-loop step** — `rc=0; for t in ${{ matrix.scripts }}; do echo ::group::$t; bash "$t" || rc=1; echo ::endgroup::; done; exit $rc`.
  - Kept `checkout@v6 (fetch-depth: 0)` + `setup-python@v6 (3.12)` + `pip install pyyaml`.
- **`plan` job — NOT present** (none was added; static `include` replaces the dynamic emit). No `--emit-matrix` invocation in any CI job.
- **`tests-result` job — ADDED** (was absent at HEAD): `needs: [tests]`, `if: always()`; step 1 `test "${{ needs.tests.result }}" = "success"`; step 2 `python3 scripts/lib/ci-shard-plan.py --assert-coverage`. (No prior `[plan, tests]` `needs` existed to fix.)
- **`on: push` UNCHANGED; no path/branch filter added.**
- **Header comments updated in place** (architect-doc-reality-reconciliation): "Two jobs" → "Three jobs" (validate/tests/tests-result, sharded-matrix described); the BD-163 step-ordering invariant block re-expressed for the fixture-cohesion-group mechanism (named the 5 members by symbol `FIXTURE_COHESION_GROUP`, not line numbers); branch-protection note now names `validate` + `tests-result` (the aggregate signal).
- **Security note re: `${{ matrix.scripts }}`/`${{ matrix.shard }}`:** these are workflow-internal STATIC matrix values (the committed frozen `include`), not untrusted external event input — no injection surface (the PostToolUse security-guidance warning is N/A here; matches the architect blueprint §2.2 run-loop shape exactly).

### 3.2 `scripts/lib/ci-shard-plan.py` (M; +85/−~30)
- **`parse_wired_tests()` re-anchored** from `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` over the whole yml → harvest `scripts/[^\s"']+\.sh` tokens from each `^\s*scripts:\s*(.+)$` value line (the `matrix.include[].scripts` strings). Same sorted-unique return shape. Byte-identical extraction to Check 42's new anchor (Group 6 holds).
- **`--emit-matrix` DEMOTED to maintenance-time generator** in: module header "Realized consumers" block (dropped the `plan` job line; added "MAINTENANCE TIME: refresh the frozen yml `include` block … → --emit-matrix (NO LONGER a CI runtime call)"); the Modes docstring; the `cmd_emit_matrix` inline comment; the argparse help string. Also updated the `pack-internal` top note + the Inputs note (`.github/.../validate-pack.yml` now described as "the static `tests`-job matrix.include[].scripts").
- **UNCHANGED:** `compute_partition`, `cmd_assert_coverage`, `cmd_shard_needs_fixtures`, `cmd_print_partition`, `FIXTURE_COHESION_GROUP` (5 members), weights/allowlist loading, `DEFAULT_SHARDS=4`.

### 3.3 `scripts/validate-pack.py` (M; +73/−~30)
- **Check 42 `check_ci_workflow_wires_per_check_tests` `wired_pattern` re-anchored** to the SAME `scripts:`-value harvest (byte-identical to `parse_wired_tests`). `disk_KEEP_set == wired_set` invariant UNCHANGED; only `wired_set`'s derivation moved.
- **Docstring updated:** `wired_set` now described as "the `scripts/…sh` tokens in the `tests`-job `matrix.include[].scripts` strings (`wired_set == union(include[].scripts)`)"; the build.sh-exclusion + Group-6 byte-identity notes refreshed; runtime-cost note re-worded for the line-scan (no subprocess-per-script, no real-tree scan — runtime class preserved).
- **FAIL remediation messages updated (architect-doc-reality-reconciliation):** the `unwired` message now tells the maintainer to **re-run `python3 scripts/lib/ci-shard-plan.py --emit-matrix` and refresh the static `tests`-job `matrix.include` block** (explicitly "do NOT hand-add a `run: bash` step — there are none any more; the run-loop executes `${{ matrix.scripts }}`"). The `stale_allowlist` message now says "present in a `tests`-job `matrix.include[].scripts` string" instead of "`run: bash {path}`".
- **PASS-message strings PRESERVED VERBATIM:** `N test script(s) on disk`, `N allowlisted (intentionally-OUT)`, `N KEEP`, `N wired in workflow`, `disk_KEEP_set == wired_set`, `CI workflow wiring is complete` (encoding-surface tests assert these — confirmed PASS).
- **Check 60 `check_ci_shard_coverage` — code UNCHANGED** (shells `--assert-coverage`, rides the re-pointed `parse_wired_tests`). Its docstring already named "the C2 `tests-result` aggregation JOB" (now realized & accurate) — no `run: bash` source named, no edit needed. Registry comment (line ~9849) likewise accurate.
- **Checks 58/59 — UNCHANGED.**

### 3.4 `scripts/tests/test-ci-shard-plan.sh` (M; +12/−4 — encoding surface, Group 6)
- **Group 6 parse-equivalence reference re-anchored:** replaced the hard-coded `re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` with the SAME `scripts:`-value harvest (`scripts_line` + `token` regex, union over `include[].scripts`). Comment updated. The assertion MEANING (`csp.parse_wired_tests == Check42-extraction`) preserved.
- Groups 0/1/2/3/4/5 unchanged (Group 1 re-runs against the post-C2 yml and proves 4 non-empty shards / union==KEEP via the re-pointed parser).

### 3.5 `scripts/tests/test-validate-pack-check-42.sh` (M; +54/−~14 — encoding surface, synthetic-yml rewrite)
- **Synthetic `run_check()` yml construction rewritten:** instead of emitting `run: bash <path>` steps, it now emits a `strategy.matrix.include` block (2 shards, the `wired` paths round-robin-split into `scripts:` strings) + a run-loop `steps` block. This exercises Check 42's new multi-shard union extraction.
- **`wired` param doc + Group-1 self-referential-closure check updated:** the closure check now looks for `scripts/tests/test-validate-pack-check-42.sh` as a token (not `bash scripts/tests/...`); top-of-file header gained a BD-219 C2 re-anchor note.
- **All T1–T8 assertions + count strings PRESERVED** (the FAIL-path substrings `exists on disk but has NO`, `validate-pack.yml`, `Allowlist staleness`, `1 allowlisted (intentionally-OUT)`, the `N test script(s) on disk` / `N wired in workflow` counts, the lenient skips) — only the yml-fixture SHAPE changed. T2's `exists on disk but has NO` substring still matches my new remediation message ("…has NO entry in the `tests`-job…").

### 3.6 `test-fixtures/manifest.txt` (regen — §4.6)
- `bash test-fixtures/build.sh --all --clean` run (EXIT 0). `git status --short test-fixtures/manifest.txt` → **EMPTY** (a regex/docstring re-anchor does not change fixture SHAs). **manifest diff empty — not staged.** Not in the patch.

---

## 4. WIRED-SET-NON-EMPTY PREFLIGHT GATE (plan §6, all 8 steps — quoted evidence)

| # | Step | Result |
|---|---|---|
| 1 | wired-set non-empty + complete | `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4`; 4 shards, each ≥1 test (22/14/18/17). **PASS** |
| 2 | emit-matrix ↔ frozen include identity | `--emit-matrix` over POST-C2 yml: 4 shards, union 71; **union identity (emit == frozen): True**; **per-shard membership identity: True**. **PASS** |
| 3 | `--assert-coverage` green | `ci-shard-plan --assert-coverage OK: 71 wired KEEP test(s) across 4 shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.` EXIT=0. **PASS** |
| 4 | Check 42 green over new source | `OK: Check 42 — 72 test script(s) on disk; 1 allowlisted (intentionally-OUT); 71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set. CI workflow wiring is complete.` (`--only-check 42` EXIT=0). **PASS** |
| 5 | parse-equivalence (Group 6) + Groups 1/2 | `bash scripts/tests/test-ci-shard-plan.sh` EXIT=0, PASS=10 FAIL=0 (Group 6 = "ci-shard-plan wired-set parse == Check 42 wired-set parse"). **PASS** |
| 6 | negative proof (the gap cannot silently recur) | (a) scratch yml with one include token dropped → `--print-partition` shows `wired: 70` (< 71). (b) in-process Check 42 against REAL disk (72) + a dropped-include yml → **exactly 1 failure naming `test-issue-forms.sh`** with the new "NO entry in the…" remediation. (c) Group 3 of test-ci-shard-plan.sh proves dropped/dup/split partitions FAIL `--assert-coverage` (PASS in step 5). Worked on COPIES; committed yml never mutated. **PASS** |
| 7 | empty-set tripwire | `--emit-matrix` over POST-C2 yml: empty-scripts shards = `[]`; union size = 71. **TRIPWIRE PASS: True**. **PASS** |
| 8 | full battery (§1.2) | general + deep validate-pack + all 71 wired tests + Check 58/59/60 — see §5. **PASS** |

> Note on step 6b method: `--assert-coverage` recomputes BOTH the wired set AND the partition from the same yml, so dropping a token from the include lowers both together (it still reports union==wired). The drift that `--assert-coverage` catches is a partition that fails to cover its OWN wired set (proven by Group 3's in-process monkeypatch). The disk-vs-include drift (a disk test missing from the include) is caught by **Check 42** — proven directly in 6b (1 failure naming the dropped test against the real 72-file disk).

---

## 5. FULL-CI-SUITE VERIFICATION (`verify-full-ci-suite` — no sampling)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` (general) | EXIT 0 — `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep) | EXIT 0 — `PASSED — all checks clean` |
| `python3 scripts/lib/ci-shard-plan.py --assert-coverage` | EXIT 0 |
| `bash scripts/tests/test-ci-shard-plan.sh` | EXIT 0 (10/10) |
| `bash scripts/tests/test-validate-pack-check-42.sh` | EXIT 0 (4/4) |
| `bash scripts/tests/test-validate-pack-checks-58-59-60.sh` | EXIT 0 (7/7) |
| **FULL wired battery (all 71 tests in the new static `include`)** | **PASS=71 FAIL=0 of 71** — every test EXIT=0 (full per-test list in `/tmp/battery-results.txt`; ran each, no sampling). Fixtures built first (`build.sh --all --clean` EXIT 0) so the cohesion-group tests ran with fixtures present. |
| yml syntax | `python3 -c "import yaml; yaml.safe_load(...)"` OK; `actionlint` not installed (skipped) |
| Python syntax | `ast.parse` OK on ci-shard-plan.py + validate-pack.py |
| bash syntax | `bash -n` OK on both edited test files |

**enumerate-encoding-surfaces sweep:** grepped all of `scripts/` for the old `run:\s+bash` anchor (NONE remain), the old Check-42 remediation `add a step under the` (NONE), the old self-ref substring `bash scripts/tests/test-validate-pack-check-42.sh` (only the harmless `# Usage:` comment), `needs.plan`/`fromJSON`/dynamic-plan-job refs (NONE). The only `--emit-matrix` references are the intentional maintenance-time ones (yml header refresh procedure + Check 42 remediation). The 2 encoding tests (Group 6 + check-42 synthetic) updated in lock-step.

---

## 6. PLAN DEVIATIONS

**ZERO.** Implemented exactly the REVISED plan + the ARCHITECTURE addendum: static 4-shard self-describing `include`; `plan` job removed/never-added; `tests-result` aggregator with `needs: [tests]` + `--assert-coverage`; both parsers re-anchored byte-identically; `--emit-matrix` demoted; Check 42 remediation re-pointed; PASS strings preserved; 2 encoding tests updated; manifest regenerated (empty diff). 5 files modified (manifest unchanged → not staged, as the plan predicted in §4.6).

---

## 7. NEW POQs / OUT-OF-SCOPE

**None introduced.** Did NOT start C4. Did NOT change shard count (4), weights, the allowlist (1 STRIP, unchanged), the `--only-check`/`CHECK_REGISTRY` logic (C1), or Checks 58/59. The architect's Task-B auto-regen recommendation (a separate follow-up BD for a `pack regen-shards`-style maintainer helper) is a Pack-Chat/user decision, surfaced in the plan — NOT acted on here (correctly out of C2 scope).

---

## 8. DEFINITION-OF-DONE CHECKLIST

| Item | Status |
|---|---|
| `tests` job is a static `strategy.matrix.include` (4 shards) with `fail-fast: false` | PASS |
| Per-shard conditional fixture build (`--needs-fixtures` gate) + run-loop (`for t in ${{ matrix.scripts }}`) | PASS |
| `plan` job removed / not present | PASS |
| `tests-result` aggregator `needs: [tests]` + asserts success + `--assert-coverage` | PASS |
| `parse_wired_tests` re-anchored to `include[].scripts`; `--emit-matrix` demoted to maintenance-time | PASS |
| Check 42 `wired_pattern` re-anchored (byte-identical); PASS strings preserved verbatim | PASS |
| Check 42 FAIL remediation re-pointed to `--emit-matrix` refresh (not `run: bash`) | PASS |
| Check 60 unchanged in code; docstring accurate | PASS |
| Group 6 (test-ci-shard-plan.sh) re-anchored in lock-step | PASS |
| test-validate-pack-check-42.sh synthetic-yml rewritten; T1–T8 + counts preserved | PASS |
| Wired set non-empty (71) == disk_KEEP_set; `--assert-coverage` 0; empty-set tripwire clean | PASS |
| general + deep validate-pack EXIT 0 | PASS |
| FULL 71-test wired battery all EXIT 0 (no sampling) | PASS |
| manifest regenerated; diff empty → not staged | PASS |
| yml + Python + bash syntax valid | PASS |
| No git state change; HEAD unchanged (`cf42769`) | PASS |
| Patch + report emitted to `/tmp/handoff-bd219-c2/` | PASS |

---

## 9. FILES-CHANGED INVENTORY

| Path | Change type |
|---|---|
| `.github/workflows/validate-pack.yml` | modified |
| `scripts/lib/ci-shard-plan.py` | modified |
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-ci-shard-plan.sh` | modified |
| `scripts/tests/test-validate-pack-check-42.sh` | modified |
| `test-fixtures/manifest.txt` | regenerated, NO diff → NOT modified/staged |

`git diff --stat`: 5 files, 273 insertions(+), 340 deletions(-). No new files. No fixture build artifacts in the diff (gitignored).

---

## 10. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git status --short`, `git branch --show-current`, `git diff --stat`, `git diff HEAD > …patch`. Scratch-file restores used `cp`/`/tmp` copies + `python3` rewrites — NO `git checkout`/`restore`/`add`/`commit`/`stash`/`reset`. End HEAD == start HEAD == `cf42769` (unchanged). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All edits were targeted `Edit` old→new replacements (yml restructure done as 4 scoped Edits + 3 header-comment Edits; ci-shard-plan.py 5 Edits; validate-pack.py 4 Edits; the 2 tests 3 Edits each). No file rewritten wholesale. Re-read confirmed via grep sweeps (§5) + per-region reads after edits. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Refer-by-symbol-not-line: yml header names `FIXTURE_COHESION_GROUP` (the symbol) for the cohesion members; Check 42 remediation message now reflects the realized frozen-include wiring (`--emit-matrix` refresh), not the retired `run: bash` step; ci-shard-plan.py "Realized consumers" header updated to the realized `tests-result`/`tests` consumers + maintenance-time `--emit-matrix`. No line numbers used in any docstring. | COMPLIANT |
| **regenerate-manifest-v11-surface** | C2 edited `scripts/` (v11-surface) → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0) → `git status --short test-fixtures/manifest.txt` EMPTY → "manifest diff empty — not staged" (§3.6, §9). | COMPLIANT |
| **verify-full-ci-suite** | Ran general + deep validate-pack (both EXIT 0) AND EVERY one of the 71 tests in the new static `include`, quoting each EXIT (PASS=71 FAIL=0; full list in §5 / /tmp/battery-results.txt) — NOT validate-pack alone, NOT a sampled subset. Plus the 2 encoding tests + checks-58-59-60. enumerate-encoding-surfaces sweep done. | COMPLIANT |
| **ci-check-runtime-compounding** | Re-anchored Check 42 = one line-scan over the yml (`scripts:` value harvest) + two dir globs + one small allowlist read; no subprocess-per-script, no real-tree scan; still routes through `run_check`. Check 60 still ONE bounded `--assert-coverage` subprocess. Removing the dynamic `plan` job nets one FEWER CI runner setup. General+deep validate-pack completed in seconds; full battery completed well within the 600s window. No new compounding. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented EXACTLY C2 (5 files). Did NOT start C4; did NOT touch shard count/weights/allowlist/`--only-check`/registry/Checks 58/59. Surfaced (not absorbed) the Task-B auto-regen follow-up as a user/Pack-Chat decision (§7). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line ONLY after all edits + the §6 gate (8/8) + the §5 battery PASSED: `PREFLIGHT: C2 static-matrix complete; wired set = 71 (non-empty) == disk_KEEP_set; --assert-coverage 0; validate-pack 0, deep 0, full battery all 0; yml valid; REGIME=ISOLATED at <toplevel>; HEAD cf42769; patch+report in /tmp/handoff-bd219-c2/`. No partial report. No parent stop received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
