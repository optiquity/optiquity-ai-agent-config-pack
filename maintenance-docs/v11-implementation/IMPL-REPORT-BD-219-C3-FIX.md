# IMPL-REPORT — BD-219 C3 Fix (comment-drift / enumerate-encoding-surfaces)

**Branch:** v11-dev  
**HEAD SHA:** 3afccec3b780e68e32b8605dd205bd78a793e4  
**Regime:** in-place (C3 working-tree changes pre-present; edits made in place)  
**Fix scope:** `pack-only`; comment-only edits to `scripts/validate-pack.py` — zero logic change

---

## Summary

BD-219 C3 generalized Check 42 from "CI workflow wires all per-check test files"
(BD-184 original scope) to "CI workflow wires every CI-eligible test"
(set-equality `disk_KEEP_set == wired_set` over the full set). The C3 coder's
removal sweep was `.sh`-only and missed three stale CHECK-42 comment sites inside
`scripts/validate-pack.py`. This fix updates those three sites. No logic, behavior,
or test changes — comments only.

---

## enumerate-encoding-surfaces grep (before)

Command run:

```
grep -n "wires all per-check\|all per-check test files\|per-check test file\|wires all per" \
  scripts/validate-pack.py
```

Output (all stale sites in the file, pre-fix):

```
260:  42. CI workflow wires all per-check test files (BD-184): enumerates
6666:# ── Check 42: CI workflow wires all per-check test files (BD-184) ──────────
8667:# NARROW self-exception (decision 1): the single new per-check test file is
9673:        # ── BD-184: CI workflow wires all per-check test files. Closes the
```

Repo-wide grep (all non-archive files):

```
grep -rn "wires all per-check\|all per-check test files\|per-check test file\|wires all per" \
  . --include="*.py" --include="*.sh" --include="*.yml" --include="*.md" --include="*.txt" \
  | grep -v ".git/"
```

Sites in `scripts/validate-pack.py`: the 4 hits above.  
Sites in `maintenance-docs/archive/` and `maintenance-docs/v11-implementation/`: historical records only — correct to leave unchanged.  
Sites in `backlog/` and `pack-ops/`: references to BD-184's original scope title or general "per-check test files" concept in non-Check-42-comment context — not stale descriptions of Check 42's generalized logic; correct to leave.

**Line 8667 assessment:** This is in the Check 53 section (`_CHECK_53_SELF_TEST_ALLOWLIST`), describing the self-exception for Check 53's own test file (`test-validate-pack-check-53.sh`). "The single new per-check test file" there means Check 53's own per-check test — accurate for Check 53's self-exception, unrelated to Check 42's scope. Left unchanged.

---

## Sites updated (3 total)

### Site 1 — check-list summary (line ~260)

**Before:**
```
  42. CI workflow wires all per-check test files (BD-184): enumerates
      `scripts/tests/test-validate-pack-check*.sh` files on disk and
      verifies every one has a corresponding `bash scripts/tests/<file>`
      invocation in `.github/workflows/validate-pack.yml`. The glob
      `check*` (no trailing dash) catches BOTH single-check filenames
      (`test-validate-pack-check-NN.sh`) AND bundled-check filenames
      (`test-validate-pack-checks-NN-NN-NN.sh`). Closes the "missing
      test wiring" gap class that surfaced 5 times across 3 fix cycles
      in the BD-175 emergency batch. Self-referential closure: this
      check's PASS state depends on its OWN test
      (`test-validate-pack-check-42.sh`) being wired — BD-184 ships
      check + test + wiring together so the closure holds. No
      exemption mechanism: unwired tests must be wired (use
      workflow `if:` gates for intentionally-not-running tests).
```

**After:**
```
  42. CI workflow wires every CI-eligible test (BD-184, BD-219):
      set-equality gate `disk_KEEP_set == wired_set` where
      `disk_KEEP_set` = {`scripts/test*.sh` + `scripts/tests/*.sh`}
      minus `scripts/ci-test-wiring-allowlist.txt` (the
      measure-then-bound STRIP set), and `wired_set` = scripts with
      a `run: bash scripts/…sh` invocation in
      `.github/workflows/validate-pack.yml`. Fails naming: (a) any
      KEEP script on disk with no wiring line; (b) any allowlisted
      script that is now wired (allowlist staleness). Closes the
      "missing test wiring" gap class (BD-184 original scope, now
      generalized in BD-219 to the full CI-eligible set).
      Self-referential closure: `test-validate-pack-check-42.sh`
      must itself appear in both the disk KEEP set and the wired set.
```

### Site 2 — section header (line ~6666)

**Before:**
```
# ── Check 42: CI workflow wires all per-check test files (BD-184) ──────────
```

**After:**
```
# ── Check 42: CI workflow wires every CI-eligible test (BD-184, BD-219) ────
```

### Site 3 — main() inline comment (line ~9673)

**Before:**
```
        # ── BD-184: CI workflow wires all per-check test files. Closes the
        # "missing test wiring" gap class permanently — surfaced 5 times in
        # the BD-175 batch alone (caught each time by reviewer attention).
        # Lands LAST in main() because it gates a CI infrastructure invariant
        # rather than any single pack-product surface; logical position is
        # end-of-list (mirrors Check 41's end-of-list landing for the
        # adjacent BD-180 inventory gate).
```

**After:**
```
        # ── BD-184 / BD-219: CI workflow wires every CI-eligible test.
        # Set-equality gate `disk_KEEP_set == wired_set` over the full
        # CI-eligible test set (BD-219 generalized from BD-184's original
        # per-check subset). Closes the "missing test wiring" gap class
        # permanently. Lands LAST in main() because it gates a CI
        # infrastructure invariant rather than any single pack-product
        # surface; logical position is end-of-list (mirrors Check 41's
        # end-of-list landing for the adjacent BD-180 inventory gate).
```

---

## enumerate-encoding-surfaces grep (after)

```
grep -n "wires all per-check\|all per-check test files\|wires all per" \
  scripts/validate-pack.py
```

Output: (empty — zero stale occurrences remain in `scripts/validate-pack.py`)

The "per-check test file" grep now returns only line 8667 (Check 53 section, accurate for Check 53, not stale).

---

## Verification

### validate-pack.py general run
```
python3 scripts/validate-pack.py
```
Exit: **0**  
Final line: `PASSED — all checks clean`

### validate-pack.py DEEP run
```
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py
```
Exit: **0**  
Final line: `PASSED — all checks clean`

### Check-42 test
```
bash scripts/tests/test-validate-pack-check-42.sh
```
Exit: **0**  
```
=== Group 0: Module import + Check 42 symbol registration ===
  PASS validate-pack.py imports + Check 42 symbol registered

=== Group 1: Real-state-at-HEAD PASS verification ===
OK
  PASS real-state-at-HEAD Check 42 PASSes + self-referential closure holds (test-42 file + wiring both present)

=== Group 2: Synthetic REPO_ROOT PASS/FAIL tests ===
OK
  PASS Synthetic PASS/FAIL tests (T1-T8: KEEP wiring across both dirs, multi-unwired surfacing, allowlist exemption + staleness, lenient skips)

=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py --only-check 42 exits 0; Check 42 runs and reports clean

=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

No test in the check-42 test file asserts on comment text — the Group 3 assertion checks the runtime banner string `"Check 42: CI workflow wires every CI-eligible test"` which matches the (already-updated) `print()` call in the C3 implementation, not the comments changed here.

### Manifest regeneration
```
bash test-fixtures/build.sh --all --clean
```
`git diff test-fixtures/manifest.txt` output: **(empty)** — comment-only change produces no manifest delta.

### git status
```
git status --short
```
```
 M .github/workflows/validate-pack.yml
 M scripts/tests/test-validate-pack-check-42.sh
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-219-C3.md
?? scripts/ci-shard-weights.tsv
?? scripts/ci-test-wiring-allowlist.txt
?? scripts/lib/ci-shard-plan.py
?? scripts/tests/test-ci-shard-plan.sh
?? scripts/tests/test-validate-pack-checks-58-59-60.sh
```

The pre-existing C3 modified files (`.github/workflows/validate-pack.yml`,
`scripts/tests/test-validate-pack-check-42.sh`) were already present before this fix.
This fix's only new change: `scripts/validate-pack.py` (already M from C3; this fix
adds comment edits on top of the C3 logic changes).

---

## Plan deviations

None. The fix executed exactly as described in the task prompt.

---

## New POQs introduced

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All stale Check 42 comment sites in `scripts/validate-pack.py` updated to generalized scope | PASS |
| Line 8667 (Check 53 self-exception) assessed and correctly left unchanged | PASS |
| `grep -n` confirms zero stale phrasings remain in `scripts/validate-pack.py` | PASS |
| Zero logic / behavior change — comments only | PASS |
| `python3 scripts/validate-pack.py` exits 0 | PASS |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` exits 0 | PASS |
| `bash scripts/tests/test-validate-pack-check-42.sh` exits 0 (4/4 pass) | PASS |
| No test in check-42.sh asserts on comment text (no enumerate-encoding-surfaces miss) | PASS |
| `bash test-fixtures/build.sh --all --clean` run; manifest diff empty | PASS |
| `git status --short` shows only pre-existing C3 modified files plus `validate-pack.py` | PASS |
| No state-changing git verbs used | PASS |

---

## Files changed

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (comments only — 3 stale Check 42 descriptions updated) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3-FIX.md` | new (this report) |

---

## Boundary discipline check

All edits are in `scripts/validate-pack.py` (pack-side) and the IMPL-REPORT
(maintenance-docs, pack-side). No project-template or supporting-docs files touched.
No boundary discipline investigation needed.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Commands run: `git rev-parse HEAD`, `git status --short`, `git diff` (read-only). No `git add`, `git commit`, `git checkout`, `git restore`, or any other state-changing verb invoked at any point. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Three targeted `Edit` calls, each replacing only the stale comment block. The file was Read before editing. No full-file Write issued. | COMPLIANT |
| **architect-doc-reality-reconciliation** | All updated comments describe Check 42's scope by concept (`disk_KEEP_set == wired_set`, `BD-184 / BD-219`, `CI-eligible test`, `allowlist`) — no line numbers. | COMPLIANT |
| **enumerate-encoding-surfaces** | Ran `grep -n` for all stale phrasing variants in `scripts/validate-pack.py`; ran repo-wide grep across `.py`, `.sh`, `.yml`, `.md`, `.txt` files. Assessed every hit. Confirmed the check-42 test file (`test-validate-pack-check-42.sh`) does not assert on comment text. 3 stale sites updated; 1 accurately-left site (line 8667, Check 53 context) documented with rationale. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `bash test-fixtures/build.sh --all --clean` run; `git diff test-fixtures/manifest.txt` output empty. Comment-only change produces no manifest delta (expected). | COMPLIANT |
| **verify-full-ci-suite** | `python3 scripts/validate-pack.py` exit 0; `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` exit 0; `bash scripts/tests/test-validate-pack-check-42.sh` exit 0 (4/4 pass). The fix is comment-only so only the check-42 test is the directly relevant per-check test; no integration test output is pinned to comment text. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Only `scripts/validate-pack.py` comment edits made. No other file modified. Report written to the named path. | COMPLIANT |
| **preflight-stop-means-stop** | PREFLIGHT line emitted immediately before the IMPL-REPORT Write, after all edits and all verifications passed. No partial report on failure path needed. | COMPLIANT |
| **rules-applied-verification-block** | This block. Per-rule evidence quoted; COMPLIANT/N/A stated per rule. | COMPLIANT |
