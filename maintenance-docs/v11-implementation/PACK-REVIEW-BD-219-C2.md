<!-- pack-only review artifact — independent review of BD-219 C2 (static-matrix tests job + wired-set re-point). Not a client deliverable. -->
# PACK-REVIEW — BD-219 C2 (static-matrix `tests` job + wired-set re-point)

**Reviewer:** fresh pack-reviewer (independent; did NOT trust the IMPL-REPORT)
**Date:** 2026-06-15 · **HEAD at review:** `cf427690d2e606a3022d534321b5f1cf74629433` (branch `v11-dev`; C2 applied to working tree, NOT committed)
**Scope reviewed:** EXACTLY the 5 modified C2 source paths + the new IMPL-REPORT (6 in-scope paths). Concurrent `backlog/BD-201.md`, `backlog/BD-217.md`, `backlog/BD-221.md`, `backlog/_toc.md`, `RESEARCH-BD-217-WORKTREE-ISOLATION.md` IGNORED as out-of-scope concurrent work (per the scope note).

---

## VERDICT: APPROVE

C2 correctly converts the `tests` job to a STATIC self-describing 4-shard matrix and re-points BOTH wired-set readers (`ci-shard-plan.py parse_wired_tests()` + Check 42 `wired_pattern`) to the `matrix.include[].scripts` array byte-identically; the wired set is non-empty (71) and EQUAL to the pre-C2 set (zero tests dropped — effectiveness preserved), Check 42 still catches drift, the full 71-test battery + general/deep validate-pack are green, and no out-of-scope file was touched. No BLOCKER / MUST / SHOULD findings.

---

## INDEPENDENT VERIFICATION (command + verbatim output + HEAD `cf42769` + 2026-06-15)

### V1 — Static matrix correct (yml structure + validity)
`grep -cE 'run:\s+bash\s+scripts/' .github/workflows/validate-pack.yml` → `0` (all ~71 per-step `run: bash` lines removed).
`grep -nE '^jobs:|^  [a-z][a-z-]*:'` → `97:jobs:` / `98:  validate:` / `140:  tests:` / `200:  tests-result:` — **NO `plan` job**.
`fail-fast: false` present (line 143). `grep -cE '^\s+- shard:'` → `4` shards.
`--emit-matrix` appears ONLY in comments (lines 123, 133) — no CI-job invocation.
`tests-result` → `needs: [tests]` (line 201); step 1 asserts `test "${{ needs.tests.result }}" = "success"`; step 2 runs `--assert-coverage`.
`validate` job UNCHANGED (still runs general + `PACK_VALIDATE_DEEP=1`, no flag, not sharded).
`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"` → `YAML OK`.
**PASS.**

### V2 — Wired set non-empty + complete (the load-bearing proof)
`python3 scripts/lib/ci-shard-plan.py --print-partition | head -1` → `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4`.
`python3 scripts/lib/ci-shard-plan.py --assert-coverage` → `ci-shard-plan --assert-coverage OK: 71 wired KEEP test(s) across 4 shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.` EXIT=0.
`--emit-matrix` union: shard1=22, shard2=14, shard3=18, shard4=17 → **shards: 4, union: 71** (every shard ≥1, no empty `scripts`).
**emit-matrix ↔ frozen include identity:** independent harvest of the frozen yml `include` vs `--emit-matrix` output → `union identity (frozen==emitted): True`; `per-shard membership identity: True` (idempotent — the generator reading the `include` reproduces the `include`).
**PASS.**

### V3 — Both readers re-anchored consistently (parse-equivalence)
`parse_wired_tests count: 71`, Check-42-style harvest count: `71`, `EQUAL: True` — the two extractions agree token-for-token over the `include[].scripts` strings.
Check 42 PASS message (verbatim): `OK: Check 42 — 72 test script(s) on disk; 1 allowlisted (intentionally-OUT); 71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set. CI workflow wiring is complete.` — all PASS strings byte-preserved.
FAIL remediation re-pointed (see V4) — references `--emit-matrix` refresh, NOT a `run: bash` step.
Group 6 (`test-ci-shard-plan.sh`) re-anchored in lock-step (its reference extraction now harvests `scripts:`-value tokens) and passes.
**PASS.**

### V4 — Check 42 still catches drift (negative proof)
**Effectiveness preserved (no test dropped):** pre-C2 wired path-set (from `cf42769` `run: bash` lines, 71) vs post-C2 wired union (from the static `include`, 71) → `diff` IDENTICAL (`keep-only: []`, `wired-only: []`; `disk_KEEP_set == wired_set: True`).
**Negative drift:** running the REAL Check 42 against the real 72-file disk + a yml with one `include` token (`test-issue-forms.sh`) dropped → **exactly 1 FAIL** naming the dropped test:
`scripts/tests/test-issue-forms.sh — test script exists on disk but has NO entry in the \`tests\`-job \`matrix.include[].scripts\` strings of \`.github/workflows/validate-pack.yml\`. … Remediation: … re-run \`python3 scripts/lib/ci-shard-plan.py --emit-matrix\` and refresh the static \`tests\`-job \`matrix.include\` block … (do NOT hand-add a \`run: bash\` step — there are none any more; the run-loop executes \`${{ matrix.scripts }}\`).`
Clean-state `validate-pack --only-check 42` → EXIT=0. **PASS.**

### V5 — Runtime cost (ci-check-runtime-compounding)
Re-anchored Check 42 = one line-scan over the yml `scripts:` values + two dir globs + one small allowlist read (no subprocess-per-script, no real-tree scan). Both 42 and 60 registered with the `W` (WARN-budget) routing through `run_check` (validate-pack.py registry rows 9699, 9850). Timing: `--only-check 42` → `real 0.06`; `--only-check 60` → `real 0.09`. Removing the `plan` job nets one FEWER CI runner setup. **No new compounding. PASS.**

### V6 — enumerate-encoding-surfaces
The 2 encoding tests updated in lock-step (Group 6 of `test-ci-shard-plan.sh`; synthetic-yml `run_check()` rewrite in `test-validate-pack-check-42.sh` now emits a `matrix.include` block instead of `run: bash` steps; the self-referential closure check re-pointed to a `scripts:`-token presence test).
Sweep of `scripts/` for the OLD anchor regex (`re.compile(r"run`/`run:\s+bash`) → **NONE remain** as live parse logic. Remaining `run: bash` strings are: one harmless `# Usage:` comment (line 43) + prose comments that correctly state "no more `run: bash` test runners" (intentional). No `fromJSON`/`needs.plan`/dynamic-plan references anywhere. The only files referencing the wired-set logic are the 4 in-scope files + the yml. **No stale assertion. PASS.**

### V7 — Full CI battery (independent, not sampled)
`python3 scripts/validate-pack.py` (general) → EXIT 0, `PASSED — all checks clean`.
`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep) → EXIT 0, `PASSED — all checks clean`.
`test-ci-shard-plan.sh` → EXIT 0 (all passed); `test-validate-pack-check-42.sh` → EXIT 0; `test-validate-pack-checks-58-59-60.sh` → EXIT 0.
**FULL wired battery — every one of the 71 tests in the static `include` (extracted from `matrix.include[].scripts`), each run, exit quoted:** `BATTERY RESULT: PASS=71 FAIL=0 of 71` (fixtures built first via `build.sh --all --clean` EXIT 0, so cohesion-group tests ran with fixtures present). No sampling.
**Manifest:** `bash test-fixtures/build.sh --all --clean` (EXIT 0) → `git diff --stat -- test-fixtures/manifest.txt` EMPTY (regex/docstring re-anchor does not change fixture SHAs; manifest correctly not staged — matches `regenerate-manifest-v11-surface`: ran + checked, diff empty). **PASS.**

### V8 — `${{ matrix.scripts }}` injection warning is N/A
`grep -nE '\$\{\{\s*matrix\.'` → the ONLY `${{ matrix.* }}` expansions are `${{ matrix.shard }}` (lines 173, 183) and `${{ matrix.scripts }}` (line 187), all fed from the STATIC committed `matrix.include` array (workflow-internal literal strings), NOT from `github.event.*` / untrusted external input. The script-injection class (untrusted input interpolated into `run:`) does not apply. **N/A — correctly so. PASS.**

### Extra — fixture-owner shard isolation
`--shard N --needs-fixtures` → exit 0 for shard 1 ONLY (the FIXTURE-OWNER carrying all 5 `FIXTURE_COHESION_GROUP` members); shards 2/3/4 exit non-zero. The conditional fixture-build step (build/restore/verify in BD-163/BD-118 order) thus runs in exactly one shard. **Correct.**

---

## SCOPE / GIT-STATE
`git status --short` shows the 5 C2 source files modified + new IMPL-REPORT; the concurrent `backlog/BD-201.md`, `backlog/BD-217.md`, `backlog/BD-221.md`, `backlog/_toc.md`, `RESEARCH-BD-217-WORKTREE-ISOLATION.md` are present but NOT C2 scope (ignored). No new files added by C2 (manifest unchanged → not staged). HEAD start == end == `cf427690d2e606a3022d534321b5f1cf74629433` — no git state change by this review.

IMPL-REPORT cross-check: the report claims `git diff --stat` "5 files, 273 insertions, 340 deletions" and "manifest diff empty — not staged"; both independently confirmed (5 modified source files; empty manifest diff). The report's "FILES-CHANGED INVENTORY", PREFLIGHT gate (8/8), and battery (71/71) all reproduce under independent re-run.

---

## FINDINGS BY SEVERITY

**BLOCKER:** none.
**MUST:** none.
**SHOULD:** none.
**NIT:** none rising to a tracked-tech-debt finding. (Observation, not a defect: the `# Usage: bash scripts/tests/test-validate-pack-check-42.sh` comment line 43 still contains the literal `bash scripts/tests/…` substring; it is a usage hint, not an assertion or parse anchor, and is harmless — no action needed.)

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **verify-full-ci-suite** | Ran general (`EXIT 0, PASSED — all checks clean`) + deep (`EXIT 0, PASSED — all checks clean`) validate-pack AND every one of the 71 tests in the static `include` (`BATTERY RESULT: PASS=71 FAIL=0 of 71`, fixtures built first), each exit accounted for — NOT validate-pack alone, NOT sampled. Plus the 2 encoding tests + checks-58-59-60 (all EXIT 0). | COMPLIANT |
| **empirical-evidence-blocks** | Every finding V1–V8 carries the actual command + verbatim output + HEAD `cf42769` + date 2026-06-15 (counts: 0 `run: bash`; 4 shards; wired 71 == disk_KEEP 71 == pre-C2 71; emit-matrix idempotent True/True; parse-equiv EQUAL True; 1-FAIL negative proof; timings 0.06/0.09). | COMPLIANT |
| **enumerate-encoding-surfaces** | Both encoding tests (`test-ci-shard-plan.sh` Group 6; `test-validate-pack-check-42.sh` synthetic-yml + closure check) re-anchored in lock-step and PASS; `scripts/` sweep for the old `run:\s+bash` parse anchor → NONE live; PASS strings byte-preserved (Check 42 OK message verbatim). | COMPLIANT |
| **ci-check-runtime-compounding** | Check 42 = line-scan over yml `scripts:` values + 2 globs + 1 small read (no subprocess-per-script, no real-tree scan); Check 60 = ONE bounded `--assert-coverage` subprocess; both `W`-routed through `run_check` (rows 9699/9850); measured `real 0.06`/`0.09`; `plan`-job removal nets one fewer runner. No compounding. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed ONLY the 6 C2 paths; explicitly did NOT flag the concurrent `backlog/*` + `RESEARCH-BD-217*` files (confirmed present in `git status`, excluded by the scope note). | COMPLIANT |
| **architect-doc-reality-reconciliation** | All references in this report are by file + symbol (`parse_wired_tests`, `wired_pattern`, `check_ci_workflow_wires_per_check_tests`, `check_ci_shard_coverage`, `FIXTURE_COHESION_GROUP`) — never line numbers as identity (line numbers cited only as transient grep evidence, not as durable anchors). | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git status --short`, `git diff`, `git show cf42769:…` (read), `git diff --stat`. A compound command containing `git checkout HEAD -- test-fixtures/manifest.txt` was DENIED by the sandbox and NOT re-attempted; the battery was re-run without any git state change. HEAD unchanged (`cf42769`). Single Write = this review doc. No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
