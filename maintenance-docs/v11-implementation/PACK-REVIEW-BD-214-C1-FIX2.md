# PACK-REVIEW-BD-214-C1-FIX2 — CI hotfix review

- **Reviewer:** fresh pack-reviewer (independent)
- **Branch / HEAD:** v11-dev @ 2d3f3d088969c9624880226c51b1fe0e04cd6987
- **Scope under review:** hotfix adding `PACK_TRACKER_DEFERRAL_OVERRIDE=1` to
  `scripts/tests/tracker-agent-read-test.sh` (the CI-wired test C1 missed).

## VERDICT: CLEAN (APPROVE)

No BLOCKER / MUST / SHOULD / NIT findings. The hotfix is correct, minimal,
genuine (not a band-aid), in scope, and the FULL CI `tests` + `validate`
jobs pass end-to-end when run with the correct wired paths.

---

## 1. Fix is correct + minimal (VERIFIED)

`git diff scripts/tests/tracker-agent-read-test.sh` is **additions-only** —
exactly the override export + its 3-line comment inserted after `set -u`:

```
+# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
+# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
+# code exercised under the clamp (never set it in a live run).
+export PACK_TRACKER_DEFERRAL_OVERRIDE=1
+
```

- **No assertion deleted/altered.** `git diff ... | grep '^-'` returns
  `NO removed lines — additions only`.
- **Style/placement matches the sanctioned reference.** A byte-diff of the
  4-line block (lines 15–18) against `scripts/tests/tracker-config-test.sh`
  reports `BLOCKS IDENTICAL`. Same post-`set -u` placement, same comment text.

## 2. Not a band-aid — the seam is genuine + design-sanctioned (VERIFIED)

- The override is the design `§3 "Dormant-but-testable"` test-only seam,
  implemented in `scripts/lib/tracker-config.sh` `tracker_mode()` (lines
  190–193): when `PACK_TRACKER_DEFERRAL_OVERRIDE != 1` the function clamps to
  `flat-file` and emits the deferral notice; `=1` re-enables real tracker-mode
  resolution. Comment explicitly marks it TEST-ONLY / "never in a live run."
- **The override is load-bearing (proved by removal).** Running a copy of the
  test with the export line stripped: `Passed: 8 / Failed: 49`. With the
  export present: `Passed: 57 / Failed: 0`. The 49 failures are precisely the
  tracker-mode-dependent assertions — so the override genuinely re-arms the
  dormant path; it does not mask anything.
- **Tracker-mode group PASSES (not skips).** Group 1.2 (`1.2 tracker mode
  detected`) and all of Group 3 (`3.1`–`3.4`, tracker reads via fake `gh`)
  report `PASS` lines. Full run: `Failed: 0`, `All tests passed.`, EXIT=0.

## 3. FULL CI `tests` + `validate` jobs — every wired command run (VERIFIED)

Run-commands extracted programmatically from `.github/workflows/validate-pack.yml`
(both jobs), then executed individually in CI order.

### validate job
| command | EXIT |
|---|---|
| `python3 scripts/validate-pack.py` | 0 (`PASSED — all checks clean`) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | 0 (`PASSED — all checks clean`) |

### tests job (all 58 wired run-commands)
All EXIT=0. Selected/representative results (every step verified individually):

```
bash scripts/test-detect.sh                                  EXIT=0
bash scripts/tests/tracker-provider-test.sh                  EXIT=0
bash scripts/tests/tracker-config-test.sh                    EXIT=0
bash scripts/tests/tracker-init-test.sh                      EXIT=0
bash scripts/tests/tracker-agent-read-test.sh                EXIT=0   <- THE FIXED TEST
bash scripts/tests/tracker-migrate-forward-test.sh           EXIT=0
bash scripts/tests/tracker-migrate-reverse-test.sh           EXIT=0
bash scripts/tests/tracker-migrate-roundtrip-test.sh         EXIT=0
bash scripts/tests/test-tracker-phase-task.sh                EXIT=0
bash scripts/tests/test-tracker-links.sh                     EXIT=0
bash scripts/tests/test-tracker-cycle-check.sh               EXIT=0
bash scripts/tests/tracker-errors-test.sh                    EXIT=0
bash scripts/tests/tracker-config-schema-test.sh             EXIT=0
bash scripts/tests/recommendation-state-schema-test.sh       EXIT=0
bash scripts/tests/test-per-entry.sh                         EXIT=0
bash scripts/tests/test-validate-pack-checks-32-33-34.sh     EXIT=0
bash scripts/tests/test-validate-pack-checks-36-37-38.sh     EXIT=0
bash scripts/tests/test-validate-pack-check-39.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-40.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-41.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-18.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-16.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-19.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-42.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-43.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-44.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-45.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-46.sh            EXIT=0
bash scripts/tests/test-validate-pack-check-removed-doc-advisory.sh        EXIT=0
bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh       EXIT=0
bash scripts/tests/test-validate-pack-check-50-codec-single-source.sh      EXIT=0
bash scripts/tests/test-validate-pack-check-51-flip-block.sh               EXIT=0
bash scripts/tests/tracker-deferral-gate-test.sh             EXIT=0
bash scripts/tests/tracker-bd129-gh-repo-test.sh             EXIT=0
bash scripts/tests/tracker-bd130-doctor-wired-test.sh        EXIT=0
bash scripts/tests/tracker-bd132-race-test.sh                EXIT=0
bash scripts/tests/tracker-bd133-header-preservation-test.sh EXIT=0
bash scripts/tests/tracker-bd134-close-retry-test.sh         EXIT=0
bash scripts/tests/recommendation-test.sh                    EXIT=0
bash scripts/tests/pack-help-test.sh                         EXIT=0
bash scripts/tests/test-customization-preserve.sh            EXIT=0
bash scripts/tests/test-init-project.sh                      EXIT=0
bash scripts/tests/test-migrate-v10-to-v11.sh                EXIT=0
bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh        EXIT=0
bash scripts/tests/test-migrate-v10-to-v11-gates.sh          EXIT=0
bash scripts/tests/test-migrate-v10-to-v11-decompose.sh      EXIT=0
bash scripts/test-migrator-core.sh                           EXIT=0
bash scripts/test-migrator-manifest.sh                       EXIT=0
bash scripts/test-migrator-capability-translation.sh         EXIT=0
bash test-fixtures/build.sh --all --clean                    EXIT=0
git checkout HEAD -- test-fixtures/manifest.txt              EXIT=0
bash test-fixtures/build.sh --verify                         EXIT=0
bash scripts/tests/test-v11-realistic-ot.sh                  EXIT=0
bash scripts/test-migrator-skills.sh                         EXIT=0
bash scripts/test-persona-contracts.sh                       EXIT=0
bash scripts/tests/template-translations-test.sh             EXIT=0
bash scripts/tests/template-version-test.sh                  EXIT=0
bash scripts/tests/test-issue-forms.sh                       EXIT=0
```

**Reviewer-process note (not a finding):** On my first sweep I mistyped the
four migrate-test paths as `scripts/test-migrate-*` (dropping the `tests/`
segment), producing transient EXIT=127 `No such file or directory`. These are
NOT CI failures — the CI paths are `scripts/tests/test-migrate-v10-to-v11*.sh`,
and re-run at the correct wired paths all four return EXIT=0 (shown above). The
defect that motivated this hotfix was *sampling*; I record the typo+correction
transparently to prove the full list (not a sample) was run.

## 4. No scope creep (VERIFIED)

Final `git status --short`:
```
 M backlog/BD-214.md
 M scripts/tests/tracker-agent-read-test.sh
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C1-FIX2.md
```
- The **only** hotfix-attributable change is
  `scripts/tests/tracker-agent-read-test.sh`.
- `backlog/BD-214.md` is the pre-existing user dated Note (2026-06-12,
  GH-Issues disposition + scratch-repo cleanup) — its diff is solely that one
  appended `Note (...)` line, no test-related content, untouched by the fix.
- The untracked `IMPL-REPORT-BD-214-C1-FIX2.md` is the fix-coder's own report
  (expected artifact, not a code change).

## 5. Manifest (VERIFIED)

`bash test-fixtures/build.sh --all --clean` → EXIT=0; `git diff --stat
test-fixtures/manifest.txt` → **empty** (no drift). Committed manifest restored
afterward. Note: the hotfix touches only `scripts/tests/`, which the
`regenerate-manifest-v11-surface` rule does include (`scripts/` is a v11
surface), but the regen produces zero diff, so nothing additional needs
staging.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **1. Agents never commit** | Ran only `git diff`, `git status`, `git checkout HEAD -- <path>` (read-only restore of a build artifact, CI's own step) and `git rev-parse`. No `add`/`commit`/`push`/`tag`. | COMPLIANT |
| **2. Read-only mandate (Write only the report)** | Sole Write call is this file at the prompted path. The `git checkout HEAD -- test-fixtures/manifest.txt` reverts a transient build-artifact write to its committed state (CI-mirrored), leaving the tree as found. Final `git status` shows no reviewer-introduced changes. | COMPLIANT |
| **3. Independent verification (full wired list, evidenced)** | Run-commands extracted via `python3` regex from `validate-pack.yml`; every one of the 58 `tests`-job commands + 2 `validate`-job commands executed with quoted EXIT (§3 table). No sampling. | COMPLIANT |
| **4. Real-fixes-only enforcement** | `git diff` shows additions-only (no `^-` lines); removal-of-override experiment proves 49 assertions genuinely fail without it (load-bearing seam, not masking); tracker-mode group reports PASS not SKIP. | COMPLIANT |
| **5. Severity-tagged findings** | No findings; verdict CLEAN. Process note recorded (not a severity finding) with file:path context. | COMPLIANT |
| **6. Rules-Applied Verification Block** | This block; each rule has named evidence + conclusion. | COMPLIANT |
| **7. PREFLIGHT + STOP-MEANS-STOP** | Emitted `PREFLIGHT: review complete; full CI tests job run; about to Write <path>` immediately before this Write; no parent stop received. | COMPLIANT |
