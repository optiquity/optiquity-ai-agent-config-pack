# PACK-REVIEW-BD-204-C2 — Check 29′ no-mirror staleness guard

**Verdict: PASS.** HEAD `7ba527c`. No findings at any severity. The
measure-then-bound guard is correctly placed and sized; the negative test
proves it does not over-admit; scope is pack-only; full CI battery green.

---

## Check 1 — Guard placement: PASS

`_check_mirror_staleness` (`scripts/validate-pack.py:2699`) ordering at
HEAD `7ba527c`:

- `:2731-2735` `mode != "tracker"` soft-pass (pre-existing)
- `:2737-2741` `forward_complete is not True` soft-pass (pre-existing)
- `:2744-2754` **NEW guard** (`if "mirror" not in cfg or not
  cfg.get("mirror", {}).get("enabled"):` → `ok(...)`; `return`)
- `:2756-2761` `last_forward_run` missing/empty FAIL
- `:2763-2767` `[mirror]` table missing/malformed FAIL
- `:2769+` per-file staleness FAIL loop

The guard sits AFTER both soft-passes and BEFORE the FAIL branches — exactly
per plan §C-2 step 2 and design §2.2.C1. Placement correct.

## Check 2 — Measure-then-bound / over-admit (KEY): PASS

Guard condition: `"mirror" not in cfg or not cfg.get("mirror", {}).get("enabled")`.

Truth analysis against the design's three legitimate shapes:

- (b) tracker + NO `[mirror]` table → `"mirror" not in cfg` True → soft-pass. Correct.
- (b) tracker + `[mirror] enabled=false`/absent → `.get("enabled")` falsy →
  `not falsy` True → soft-pass. Correct (no monolith to enforce against).
- (c) tracker + `[mirror] enabled=true` → `"mirror" in cfg` True AND
  `.get("enabled")` is `True` → `not True` False → whole expr **False** →
  falls through to the FAIL branches and enforces staleness. **Does NOT
  over-admit.**

The guard is sized to exactly the no-mirror legitimate set; a
claims-mirror-but-missing config cannot escape the FAIL path. Load-bearing
correctness property holds.

## Check 3 — Encoding surfaces lock-step + negative test is real: PASS

`scripts/tests/tracker-config-schema-test.sh` gained:

- **Test 15 (positive):** tracker + `forward_complete=true` + NO `[mirror]` →
  asserts exit 0 AND grep of `"no-mirror surface, mirror-staleness check N/A"`
  (15.1 / 15.2).
- **Test 16 (negative):** tracker + `[mirror] enabled=true` +
  `location_backlog="BACKLOG.md"` + **no `BACKLOG.md` planted** → asserts exit
  nonzero (16.1) AND grep of `"BACKLOG.md.*does not exist on disk"` (16.2).

The negative test genuinely exercises the over-admit path: the harness
`run_check29_at` re-points `mod.REPO_ROOT` at the fixture and the fixture has
no `BACKLOG.md`, so `_check_mirror_staleness` reaches the per-file
`does not exist on disk` FAIL (`:2779`). 16.2 asserts that exact message —
i.e. it proves the guard let the config through to enforcement, not that the
script merely ran. Real negative coverage.

Schema leg `_validate_tracker_toml` UNCHANGED (`git diff` shows no hunk
touching it). Both `tracker.toml.pack-example` and
`tracker.toml.project-example` UNCHANGED (not in `git diff --name-only`).
Validator + staleness-asserting test moved together in one commit; example
schema correctly untouched.

## Check 4 — Pack-only + scope: PASS

`git diff --name-only` = exactly:
```
scripts/tests/tracker-config-schema-test.sh
scripts/validate-pack.py
```
Nothing under `project-template/`; no `tracker.toml.project-example` edit; no
`tracker.toml.pack-example` edit. Manifest unchanged: neither changed file is
a manifest-tracked content surface that alters `test-fixtures/manifest.txt`
(scripts/ test + validator); `git status` shows no manifest delta — correctly
unchanged. (Untracked `IMPL-REPORT-BD-204-C2.md` present but not reviewed per
prompt.)

## Check 5 — Full CI battery: PASS

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `EXIT=0` — `PASSED — all checks clean`; Check 29 green (pack-example schema OK, `tracker.toml absent … soft-passes`) |
| `bash scripts/tests/tracker-config-schema-test.sh` | `EXIT=0` — `PASS: 32 / FAIL: 0`; Tests 15.1/15.2/16.1/16.2 all PASS |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | `EXIT=0` — `PASS: 74 / FAIL: 0` |
| `bash scripts/tests/test-v11-realistic-ot.sh` | `EXIT=0` — `PASS: 33 / FAIL: 0` |

---

## Findings

**None** (BLOCKER / MUST / SHOULD / NIT all empty).

---

## Rules-Applied Verification Block

| Rule | Evidence (HEAD `7ba527c`) | Conclusion |
|---|---|---|
| CI-guard measure-then-bound | Guard `if "mirror" not in cfg or not cfg.get("mirror", {}).get("enabled")` (`:2751`) sized to (b) only; (c) `enabled=true` → expr False → FAIL path. Test 16.1 `→ exit nonzero` + 16.2 `BACKLOG.md.*does not exist on disk` PASS prove no over-admit. | COMPLIANT |
| Enumerate ENCODING surfaces | Validator (`_check_mirror_staleness`) + staleness-asserting test (`tracker-config-schema-test.sh` Tests 15/16) updated in same commit; `_validate_tracker_toml` + both `*example` files show zero diff hunks. | COMPLIANT |
| Empirical evidence | All findings cite `git diff` line ranges + function `:2699-2761`; CI re-run table quotes verbatim exit codes + summary lines. | COMPLIANT |
| Scope deliverables — no noise | Report = headline + 5 checks + over-admit analysis + CI table + findings + block. No sprawl. | COMPLIANT |
| Pack/project separation | `git diff --name-only` = 2 scripts/ files; no `project-template/`, no `tracker.toml.project-example` edit. | COMPLIANT |
| Rules-Applied Verification Block | This table + read-doc table below. | COMPLIANT |

### Read-doc attestation

| Doc | Read | Conclusion |
|---|---|---|
| `PLAN-BD-204.md` § Commit C-2 (`:208-251`) | Read in full | COMPLIANT |
| `ARCHITECTURE-BD-204.md` §2.2 (C1 + 3 config shapes) | Read (DP-1/§2.2 region) | COMPLIANT |
| `scripts/validate-pack.py` `_check_mirror_staleness` full fn (`:2699-2790`) | Read in full | COMPLIANT |
| `scripts/tests/tracker-config-schema-test.sh` diff + helpers (`:43-110`, Tests 15/16) | Read in full | COMPLIANT |
| `CLAUDE.md` `## Pack memory` | Read (session context) | COMPLIANT |
| coder IMPL-REPORT | NOT read (per prompt — independent verification) | N/A: by-design |
