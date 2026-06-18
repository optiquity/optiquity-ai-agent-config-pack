# IMPL-REPORT — BD-228 commit C2 (pack-only)

**Author:** pack-coder (isolated-worktree regime)
**Date:** 2026-06-17
**Commit:** C2 of the APPROVED plan `/tmp/handoff-bd228-planner/PLAN-BD-228-MANIFEST-METHOD.md`
**Scope:** `pack-only`

---

## Regime + base verification

- **Regime:** ISOLATED WORKTREE (harness-created). Confirmed at STEP 0.
- **pwd:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afea52183d85fa2ba` (a `.claude/worktrees/agent-…` path — correct).
- **Branch:** `worktree-agent-afea52183d85fa2ba`
- **HEAD at start AND end:** `3bad27667c10aa0888e6f30ae452e39efdb2075b` (short `3bad276`) — matches the prompt's expected base. No commits made (agents never commit).
- **Handoff dir created:** `mkdir -p /tmp/handoff-bd228-C2` (first action).
- **Base sanity:** the plan, the design doc, and `scripts/validate-pack.py` were all present and read in full before editing.

**Patch NOT emitted** per the prompt's HARD CONSTRAINT ("Do NOT emit a patch yet … Reviewed-clean patch requested later"). Edits left in the working tree for the orchestrator's review/fix cycle.

---

## Per-task summary

### Task 1 — Add `check_manifest_structural()` = Check 62

- **File:** `scripts/validate-pack.py` (modified)
- **Location:** inserted after `check_fixture_dependent_location()` (Check 61) and before `check_validate_job_carries_no_only_check()` (Check 58 def). Function def now at **line 6834**.
- **Line delta:** +~100 lines (one check function with docstring).
- **What it asserts** (design §3.2, cheap structural well-formedness screen on `test-fixtures/manifest.txt`, skipping `#`/blank lines):
  - (a) exactly `len(_load_fixture_names())` data rows (== 6 on the current tree);
  - (b) row NAMES, as a SET, equal `_load_fixture_names()` (the build.sh `FIXTURE_NAMES` set);
  - (c) each row is `<name>  <sha>` and the SHA matches `^[0-9a-f]{40}$`.
- **Cheap (ci-check-runtime-compounding):** ONE small file read + a per-line regex over the 6-row manifest + reuse of the existing `_load_fixture_names()` helper. NO fixture rebuild, NO subprocess, NO subprocess-per-entry, NO whole-real-tree scan. Routes through `run_check` (per-check WARN budget).
- **Not the SHA-correctness authority:** the docstring states plainly that SHA-correctness stays the existing CI `build.sh --verify`; Check 62 only catches a truncated/garbled/wrong-count/wrong-name/non-hex manifest fast in the always-run `validate` job. It does NOT assert SHA-CORRECTNESS, so a comment-only fixture-input edit that leaves the manifest unchanged is never a false positive (design §3.2(ii)).
- **Lenient:** if `build.sh` / `FIXTURE_NAMES` is absent (no oracle) → `ok(...)` SKIP, mirroring the Check 61 lenient pattern.

### Task 2 — Register Check 62 + bump `CHECK_REGISTRY_EXPECTED_COUNT` 59→60 (gap G1)

- **File:** `scripts/validate-pack.py` (modified)
- **Registry entry:** added `(62, "check_manifest_structural", check_manifest_structural, W),` to `_build_check_registry()` at the registry tail (after Check 61), now at **line 9992**, with an inline rationale comment.
- **Count bump:** `CHECK_REGISTRY_EXPECTED_COUNT = 59` → `60` (now **line 492**); the explanatory comment block above the constant updated to record the BD-228 `+1` (62 manifest structural screen).
- **Runtime confirmation:** `len(_build_check_registry()) == 60 == CHECK_REGISTRY_EXPECTED_COUNT`; Check 59 reports "CHECK_REGISTRY has 60 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT)".
- G1 was confirmed load-bearing: without the bump Check 59 would FAIL.

### Task 3 — Add `scripts/tests/test-validate-pack-check-62.sh` (NEW)

- **File:** `scripts/tests/test-validate-pack-check-62.sh` (new, +~280 lines, `chmod +x`)
- **Modeled on:** `scripts/tests/test-validate-pack-check-61.sh` (per-check-test convention).
- **Self-provisioned (test-infra-self-provisioned):** every malformed/well-formed manifest is built in a `/tmp` scratch `REPO_ROOT` (synthetic `build.sh` `FIXTURE_NAMES` array + synthetic `manifest.txt`); the **real `test-fixtures/manifest.txt` is NEVER mutated**.
- **Coverage:**
  - Group 0: module import + Check 62 symbol registration + count-invariant (`len(registry) == EXPECTED_COUNT`, `62 in registry`).
  - Group 1: real-state-at-HEAD PASS (the committed manifest is well-formed).
  - Group 2 (T1-T6): well-formed PASS; wrong-row-count FAIL; non-hex SHA FAIL; wrong-fixture-name FAIL; missing-manifest FAIL; lenient SKIP when `FIXTURE_NAMES` absent.
  - Group 3: e2e `validate-pack.py --only-check 62` exits 0 on HEAD.
- Auto-wires by the `scripts/tests/*.sh` disk glob (no allowlist / shard edit).

---

## Verification (results quoted)

| Verification | Command | Result |
|---|---|---|
| Default validate-pack | `python3 scripts/validate-pack.py` | **exit 0** — "PASSED — all checks clean" |
| DEEP validate-pack | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **exit 0** — "PASSED — all checks clean" |
| NEW fail lines | `grep "^FAIL:"` on both default + deep output | **NONE** ("NO FAIL LINES") |
| Check 62 runs + passes | `python3 scripts/validate-pack.py --only-check 62` | **exit 0** — "Check 62 — test-fixtures/manifest.txt structurally well-formed: 6 data row(s), names == build.sh FIXTURE_NAMES, every SHA a 40-hex token" |
| Check 59 (registry count) | `python3 scripts/validate-pack.py --only-check 59` | **exit 0** — "CHECK_REGISTRY has 60 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT)" |
| Check 42 (per-check-test wiring) | `--only-check 42` | **OK** — "74 test script(s) on disk; … 73 KEEP" (new check-62 test counted) |
| Check 45 (rationale bijection) | `--only-check 45` | **OK** — "22 pointer(s); 22 section(s); bijection holds" (unchanged by C2) |
| Check 60 (shard coverage) | `--only-check 60` | **OK** — "union(shards) == wired_KEEP_set, pairwise-disjoint, fixture cohesion group co-located" |
| Check 62 appears in full run | `grep -c "Check 62"` default output | **2** (banner + OK line) |
| New per-check test (FAIL + pass legs) | `bash scripts/tests/test-validate-pack-check-62.sh` | **exit 0** — PASS: 4, FAIL: 0 (T1-T6 incl. wrong-count/non-hex/wrong-name/missing FAIL + well-formed/lenient PASS) |
| `--only-check 62` selector | (above) | passes |
| `--only-check 59` selector | (above) | passes |
| Python syntax | `python3 -c "ast.parse(...)"` | "py syntax OK" |
| Bash syntax | `bash -n scripts/tests/test-validate-pack-check-62.sh` | "bash syntax OK" |
| Shard matrix builds | `python3 scripts/lib/ci-shard-plan.py --emit-matrix` | **exit 0**; new check-62 test present (grep count 1) |
| Shard coverage assert | `python3 scripts/lib/ci-shard-plan.py --assert-coverage` | **exit 0** — "73 wired KEEP test(s) across 4 shard(s)" |

### Full wired CI battery (verify-full-ci-suite)

Enumerated the wired KEEP set from `ci-shard-plan.py --emit-matrix` (73 scripts), built fixtures **once** (`bash test-fixtures/build.sh --all --clean`, exit 0), then ran every wired test:

```
=== BATTERY TOTALS ===
PASS=73  FAIL=0  TOTAL=73
FAILED:
```

The new `scripts/tests/test-validate-pack-check-62.sh` is in the wired set and passed as part of the battery.

---

## Out-of-scope finding (surfaced, NOT fixed) — local manifest SHA delta

When fixtures were rebuilt locally for the battery (`build.sh --all --clean`), the regenerated manifest differed from the committed `test-fixtures/manifest.txt` in **3 of 6 rows** (`v11-realistic-ot`, `v11-flat-file`, and one other). This is an **environmental/worktree-base condition**, NOT a C2 defect and NOT in C2 scope:

- C2 is dog-fooding the self-hosting rule (plan §3): C2 carries **no per-commit manifest** and does **not** stage/modify `test-fixtures/manifest.txt`. The manifest is reconciled by the orchestrator at BD-228's push via `scripts/manifest-sync.sh` (the very mechanism this BD installs).
- Check 62 is a STRUCTURAL screen and passed regardless (it does not assert SHA-correctness — by design). The authoritative SHA gate (`build.sh --verify`) is the orchestrator/CI's responsibility at push.
- I restored the committed manifest content using a **read-only** `git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt` redirect (NOT a state-changing git verb) so my working tree carries only the two in-scope changes.

Flagging for the orchestrator: at BD-228's push the push-time `manifest-sync.sh` reconciliation (plan §3) will determine the manifest's final committed SHAs. The local delta here is informational; do not treat it as a C2 deliverable.

---

## Plan deviations

**One deviation — helper name correction (mechanical, not a redesign):**

- The plan (EB-3) and design (§3.2) both name the build.sh-FIXTURE_NAMES helper **`_fixture_names_from_build_sh()`** at line 6714. **That symbol does not exist.** The actual helper at line 6713-6727 is named **`_load_fixture_names()`** (verified: `grep -n "_fixture_names_from_build_sh" scripts/validate-pack.py` returns nothing; `_load_fixture_names` is the real symbol used by Check 61).
- **Action taken:** Check 62 reuses the REAL helper `_load_fixture_names()` (the plan's clear intent — "reuse the existing helper" — preserved; only the name was wrong in the spec). No new helper added; no behavior change. This is a spec typo, not a design fork.

No other deviations. All other plan PICKs carried unchanged (structural screen only; 6-row / name-set / 40-hex assertions; lenient SKIP; `build.sh --verify` stays the SHA authority; count bump 59→60; both encoding surfaces — check + per-check test — landed in lock-step).

---

## New POQs introduced

None.

---

## Boundary discipline check

C2 is strictly `pack-only` and edits only pack-side validator + pack-side test infra:

- `scripts/validate-pack.py` — pack-side validator (not under `project-template/`, `supporting-docs/`, or any client-shipped surface).
- `scripts/tests/test-validate-pack-check-62.sh` — pack-side test infra (not shipped to clients).

No project-side (`project-template/`, `supporting-docs/`) file touched → the project-side SSOT investigation pre-flight is **N/A for C2** (no project-side edit). No reference to a pack-only file added to any client surface (none touched). No boundary-discipline stop.

---

## Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | `check_manifest_structural()` added as Check 62 (design §3.2) | **PASS** |
| 2 | Check 62 reuses existing fixture-names helper (`_load_fixture_names()`) | **PASS** |
| 3 | Check 62 asserts row count == 6, names == FIXTURE_NAMES set, SHA ^[0-9a-f]{40}$ | **PASS** |
| 4 | Check 62 is cheap (file-read + regex; no rebuild/subprocess/whole-tree scan) | **PASS** |
| 5 | Check 62 routes through `run_check` (per-check WARN budget) | **PASS** |
| 6 | Check 62 registered in `_build_check_registry()` (entry 62) | **PASS** |
| 7 | `CHECK_REGISTRY_EXPECTED_COUNT` bumped 59 → 60 (G1) | **PASS** |
| 8 | Runtime registry count == 60 == EXPECTED_COUNT; Check 59 green | **PASS** |
| 9 | `scripts/tests/test-validate-pack-check-62.sh` added (NEW) | **PASS** |
| 10 | Test has malformed-FAIL legs + well-formed-PASS leg | **PASS** |
| 11 | Test self-provisioned in /tmp; real manifest never mutated | **PASS** |
| 12 | New test auto-wires by glob (Check 42 counts it; matrix includes it) | **PASS** |
| 13 | Default validate-pack exit 0; no NEW fail lines | **PASS** |
| 14 | DEEP validate-pack exit 0; no NEW fail lines | **PASS** |
| 15 | `--only-check 62` passes; `--only-check 59` passes | **PASS** |
| 16 | Full wired CI battery green (73/73) | **PASS** |
| 17 | Boundary: `pack-only`; only the 2 named files touched; no manifest staged | **PASS** |
| 18 | No state-changing git verb run | **PASS** |
| 19 | No patch emitted (per prompt); edits left for review cycle | **PASS** |

---

## Files changed inventory

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (add `check_manifest_structural` Check 62 + registry entry + count bump 59→60 + comment update) |
| `scripts/tests/test-validate-pack-check-62.sh` | new |

**NOT changed / not staged:** `test-fixtures/manifest.txt` (self-hosting — reconciled at push by orchestrator); no other file.

---

## Full file content of the NEW file

For re-apply without re-derivation, the complete new file is at
`scripts/tests/test-validate-pack-check-62.sh` in the worktree (the orchestrator
will pick it up from the working tree / patch at review-clean). It is ~280 lines;
its structure is: shebang + header docstring; `t_pass`/`t_fail` helpers;
Group 0 (import + registration + count invariant); Group 1 (real-state PASS);
Group 2 (synthetic /tmp REPO_ROOT, T1 well-formed PASS / T2 wrong-count FAIL /
T3 non-hex FAIL / T4 wrong-name FAIL / T5 missing FAIL / T6 lenient SKIP);
Group 3 (e2e `--only-check 62`); summary with exit code. The synthetic
`run_check(manifest_body, omit_fixture_names)` writes a synthetic `build.sh`
(`FIXTURE_NAMES=(alpha beta gamma)`) + manifest into a fresh `mkdtemp` tree,
swaps `mod.REPO_ROOT`, invokes `mod.check_manifest_structural()` under a
`mod.failures` save/restore + stdout capture, and `rmtree`s the scratch tree.
SHA token used in synthetic rows: `0123456789abcdef0123456789abcdef01234567`.

The `scripts/validate-pack.py` change is a targeted in-place edit (3 hunks:
function insertion at ~6834, registry entry at ~9992, count constant + comment
at ~470-492); not a rewrite.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | Only read-only git verbs run: `git rev-parse --short HEAD` → `3bad276`; `git status --short` (inspection); `git diff` (inspection); `git show HEAD:test-fixtures/manifest.txt > …` (read-only patch-emit / file-content read, redirected to restore the working file). NO `git add/commit/push/tag/stash/checkout/restore/rm/mv/reset/merge/apply`. Final `git rev-parse HEAD` == `3bad27667c10aa0888e6f30ae452e39efdb2075b` (unchanged — no commit made). | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op on own authority. The Check-62 test provisions `/tmp` scratch trees (`mkdtemp` + `rmtree` of only those tmp dirs). The real `test-fixtures/manifest.txt` was rewritten only by `build.sh --all --clean` (a build artifact write) and immediately restored to committed content via the read-only `git show` redirect — final `git status` shows manifest UNMODIFIED. No `rm -rf`, no `git rm`, no overwrite of a trusted tracked file left in place. | COMPLIANT |
| 3 | **preflight-stop-means-stop** | Emitted the `PREFLIGHT: 3/3 in-scope edits complete; verification PASS; HEAD 3bad276…; about to Write IMPL-REPORT…` line ONLY after all edits + all verification PASSED (default+DEEP exit 0, check-62 test exit 0, Check 59 green at count 60, battery 73/73). No parent stop/halt message received; had one arrived, work would have halted immediately. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | STEP 0: `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afea52183d85fa2ba` (a `.claude/worktrees/agent-…` path — ISOLATED WORKTREE confirmed); `git rev-parse --short HEAD` → `3bad276` (== expected base). Both reported; did not STOP because the regime + base matched. | COMPLIANT |
| 5 | **ci-check-runtime-compounding** | Check 62 body is pure file-read + per-line regex over the 6-row `test-fixtures/manifest.txt` + reuse of `_load_fixture_names()`; NO `build.sh` rebuild, NO `subprocess`, NO subprocess-per-entry, NO whole-real-tree scan. Routes through `run_check` (per-check WARN budget = 2.0s). Default full run stayed exit 0 (total-run budget not tripped); `--only-check 62` ran instantly. | COMPLIANT |
| 6 | **enumerate-encoding-surfaces** | Adding a check touched ALL coupled surfaces in lock-step in C2: the check fn (`check_manifest_structural`), the registry entry (`(62, …)`), the count constant (`CHECK_REGISTRY_EXPECTED_COUNT 59→60` + its comment block), and the per-check test (`test-validate-pack-check-62.sh`). Verified symmetric: Check 59 green (count matches), Check 42 counts the new test (74 on disk), matrix wires it. No asymmetric coverage. | COMPLIANT |
| 7 | **edit-in-place-not-full-rewrite** | `scripts/validate-pack.py` edited with 3 targeted `Edit` hunks (function insertion, registry tuple, count constant + comment), NOT a rewrite. Re-read the edited regions post-edit: count constant at line 492 (`= 60`), registry entry at 9992 (`(62, "check_manifest_structural"`), fn def at 6834 — all intact; py `ast.parse` OK. | COMPLIANT |
| 8 | **verify-full-ci-suite** | Ran the FULL wired battery, not just validate-pack: enumerated 73 wired KEEP tests from `ci-shard-plan.py --emit-matrix`, built fixtures once, ran each → `PASS=73 FAIL=0 TOTAL=73`. Plus default + DEEP validate-pack (both exit 0) + the new per-check test (exit 0) + Check 42/45/59/60 selectors + matrix-build + assert-coverage. | COMPLIANT |
| 9 | **test-infra-self-provisioned** | `test-validate-pack-check-62.sh` provisions its own `/tmp` scratch `REPO_ROOT` via `tempfile.mkdtemp(prefix="vp-check62-")`, writes synthetic `build.sh`+`manifest.txt` there, and `shutil.rmtree`s it after each case. It NEVER reads or mutates the real `test-fixtures/manifest.txt` (Group 1 reads it read-only via a `mod.failures` save/restore + stdout capture, asserting only). Final `git status` confirms the real manifest is unmodified. | COMPLIANT |
| 10 | **rules-applied-verification-block** | This table — each rule named, with quoted evidence (commands/paths/counts/exit codes) and a COMPLIANT conclusion; no empty-evidence cell. | COMPLIANT |

---

**End of IMPL-REPORT — C2.**
