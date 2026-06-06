# IMPL-REPORT — BD-204 Commit C-2

Check 29′ no-mirror staleness guard (measure-then-bound) + encoding surfaces.

- **Branch:** `v11-dev`
- **HEAD (pre-flight = final, no commits):** `7ba527c7f29248950c6c79abc188948a64472c8f`
- **Scope claim:** pack-only.
- **Staged:** nothing (agents never commit).

## Files changed (inventory)

| Path | Type | Δ |
|---|---|---|
| `scripts/validate-pack.py` | modified | +12 |
| `scripts/tests/tracker-config-schema-test.sh` | modified | +89 |

`test-fixtures/manifest.txt`: regen ran (`build.sh --all --clean`, EXIT 0); diff EMPTY → not in scope.
NOT touched: `_validate_tracker_toml` (schema leg), `tracker.toml.pack-example`, `tracker.toml.project-example`, `project-template/`, `test-validate-pack-checks-32-33-34.sh` (greps showed it pins Check 32/33/34, no Check-29 staleness assertion).

## 1. The guard (measure-then-bound)

Added at the TOP of `_check_mirror_staleness` (after the `mode != "tracker"` soft-pass and the `forward_complete is not True` soft-pass, BEFORE the `last_forward_run`-missing and `[mirror]`-table FAIL branches):

```python
    # BD-204 Check 29′ — no-mirror surface guard (measure-then-bound).
    # The Mode-3 pack live tracker.toml omits the [mirror] table (no
    # monolith to point at). When the live config has NO [mirror] table
    # OR mirror.enabled is false/absent, staleness is N/A — soft-pass,
    # exactly as flat-file mode does above. A config that DECLARES
    # [mirror] enabled=true but is missing the file falls through to the
    # staleness branches below and still FAILs (guard does not widen).
    if "mirror" not in cfg or not cfg.get("mirror", {}).get("enabled"):
        ok(f"{rel} — no [mirror] table / mirror disabled — no-mirror "
           "surface, mirror-staleness check N/A")
        return
```

Matches design §2.2.C1 recipe and the function's existing `ok(...)`/`return` soft-pass style. Soft-passes shape (b) tracker+no-mirror; shape (a) flat-file already soft-passes above; shape (c) tracker+`[mirror] enabled=true` falls through to the existing staleness branches and still FAILs a missing/stale mirror.

## 2. Encoding surfaces (lock-step tests)

Added to `tracker-config-schema-test.sh` after Test 14, matching the existing `read -r -d '' ... <<'TOML'` fixture + `run_check29_at` + `t_pass`/`t_fail` style.

**POSITIVE (Test 15) — tracker + NO `[mirror]` → soft-pass:**
```sh
[mode]
state = "tracker"
...
[migration]
forward_complete = true
...
# (no [mirror] table at all; no mirror files planted)
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "15.1 no-mirror live tracker.toml → exit 0"
...
if echo "$out" | grep -q "no-mirror surface, mirror-staleness check N/A"; then
    t_pass "15.2 staleness leg reports N/A for no-mirror surface"
```

**NEGATIVE (Test 16) — tracker + `[mirror] enabled=true` + missing file → FAIL (guard did not over-admit):**
```sh
[mode]
state = "tracker"
...
[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
...
# Deliberately plant NO mirror files — the declared mirror is missing.
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "16.1 claims-mirror-but-missing → exit nonzero"
...
if echo "$out" | grep -q "BACKLOG.md.*does not exist on disk"; then
    t_pass "16.2 message names missing mirror file (guard did not over-admit)"
```

## 3. Verification (full CI battery)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | EXIT 0 — `PASSED — all checks clean`; Check 29 green (no live `tracker.toml` → leg soft-passes "lazy-create is by design") |
| `bash scripts/tests/tracker-config-schema-test.sh` | EXIT 0 — `PASS: 32 / FAIL: 0` (Tests 13/14 unchanged green; new 15/16 pass) |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | EXIT 0 — `PASS: 74 / FAIL: 0` |
| `bash scripts/tests/test-v11-realistic-ot.sh` | EXIT 0 — `All v11-realistic-ot integration tests PASSED (33/33)` |
| `bash test-fixtures/build.sh --all --clean` | EXIT 0 — `manifest.txt` diff EMPTY |

## Plan deviations

None. Implemented exactly the plan's Commit C-2 + design §2.2.C1.

## New POQs

None.

## Definition-of-Done

| Item | Status |
|---|---|
| Guard added at correct position in `_check_mirror_staleness` | PASS |
| No-mirror/disabled live config soft-passes | PASS (Test 15) |
| Claims-mirror-but-missing still FAILs (no over-admit) | PASS (Test 16) |
| `_validate_tracker_toml` unchanged | PASS (not in diff) |
| `tracker.toml.*example` unchanged | PASS (not in diff) |
| Encoding-surface test updated in lock-step | PASS |
| `validate-pack.py` green | PASS |
| Full CI battery green | PASS |
| Manifest regen run; diff empty | PASS |
| Nothing staged/committed | PASS |

## Rules-Applied Verification Block

| Rule / READ-IN-FULL doc | Evidence | Conclusion |
|---|---|---|
| CI-guard measure-then-bound | Guard soft-passes ONLY no-`[mirror]`/disabled; NEGATIVE Test 16 proves a declares-mirror-but-missing config still FAILs (`16.1 → exit nonzero`, `16.2 names BACKLOG.md does not exist`) — `PASS: 32 / FAIL: 0` | COMPLIANT |
| Enumerate ENCODING surfaces | Validator fn + its staleness test updated same commit; greps showed `test-validate-pack-checks-32-33-34.sh` carries NO Check-29 staleness assertion (only Check 32/33/34) so it is not the staleness-pinning surface; example schema NOT changed | COMPLIANT |
| Pack/project separation | `git diff --stat` shows only `scripts/validate-pack.py` + `scripts/tests/tracker-config-schema-test.sh`; `tracker.toml.project-example` / `project-template/` / schema leg untouched | COMPLIANT |
| Verify the FULL CI suite | All 4 commands quoted §3, each EXIT 0 (validate-pack PASSED; schema-test 32/0; checks-32-33-34 74/0; realistic-ot 33/33) | COMPLIANT |
| Regenerate manifest on v11-surface commits | `build.sh --all --clean` EXIT 0; `git diff --stat test-fixtures/manifest.txt` empty → not in scope | COMPLIANT |
| Agents never commit | `git status --short` shows 2 modified, 0 staged; no state-changing git verb run | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Single PREFLIGHT line emitted after all edits+verification PASS, before this Write; no parent stop received | COMPLIANT |
| Rules-Applied Verification Block | This table | COMPLIANT |
| READ: `PLAN-BD-204.md` § Commit C-2 | Read lines 208-250 (recipe, 3 config shapes, verification battery) | COMPLIANT |
| READ: `ARCHITECTURE-BD-204.md` §2.2 | Read lines 324-368 (§2.2.C1 measure-then-bound, EE block, guard fix-recipe `if "mirror" not in cfg or not cfg["mirror"].get("enabled")`) | COMPLIANT |
| READ: `validate-pack.py` `_check_mirror_staleness` | Read full fn lines 2699-2779 (both soft-pass + all FAIL branches) → guard placed after fwd-complete soft-pass | COMPLIANT |
| READ: `validate-pack.py` `_validate_tracker_toml` (confirm NOT changed) | Located def `:2543`; not edited (not in diff) | COMPLIANT |
| READ: the two test files' Check-29 assertions | Read `tracker-config-schema-test.sh` 310-447 (Tests 13/14); grepped `test-validate-pack-checks-32-33-34.sh` (no Check-29 staleness assertion) | COMPLIANT |
| READ: `CLAUDE.md` ## Pack memory | Provided in full in session context; applied (no-mirror SSOT, separation, measure-then-bound, enumerate-encoding-surfaces, manifest-regen) | COMPLIANT |
| READ: `feedback_ci_guard_design_measure_then_bound.md` | Memory-indexed: measure tree, categorize KEEP/STRIP, size allowlist to KEEP; applied — guard sized to (a)+(b) KEEP, (c)-missing STRIP→FAIL | COMPLIANT |
| READ: `feedback_verify_full_ci_suite.md` | Memory-indexed: run full battery incl. integration banner-pinning tests; ran realistic-ot + checks-32-34 | COMPLIANT |
| READ: `feedback_manifest_regen_on_v11_surface.md` | Memory-indexed: regen on scripts/ touch; ran build.sh, diff empty | COMPLIANT |
| READ: `feedback_pack_project_separation_of_concerns.md` | Memory-indexed: pack/project are separate artifacts; project-example + schema leg untouched | COMPLIANT |
| READ: `feedback_agent_output_rules_applied_block.md` | Memory-indexed: per-rule evidence table; this block | COMPLIANT |
