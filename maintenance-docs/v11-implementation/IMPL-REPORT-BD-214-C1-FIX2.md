# IMPL-REPORT — BD-214 C1 CI hotfix (FIX-2)

**Branch:** v11-dev
**Pre-flight HEAD:** `2d3f3d088969c9624880226c51b1fe0e04cd6987`
**Final HEAD (worktree, agents never commit):** `2d3f3d088969c9624880226c51b1fe0e04cd6987`
**Role:** fresh pack-coder (CI hotfix; implement + verify; no stage/commit)

---

## 1. The failure (root cause)

C1 (`2d3f3d0`) added a deferral clamp to `tracker_mode()` in
`scripts/lib/tracker-config.sh`, gated by the TEST-ONLY seam
`PACK_TRACKER_DEFERRAL_OVERRIDE=1` (design §3 Layer A, line 226). It added
that override export to 21 dormant tracker/recommendation test scripts so
they stay green — but **missed `scripts/tests/tracker-agent-read-test.sh`**,
which is CI-wired in `.github/workflows/validate-pack.yml` at the
"tracker-agent-read tests" step (line 133) and has a tracker-mode read group
(group 1 mode-detection + group 3 tracker read) that fails under the clamp.

### Failure reproduced at pre-flight (before fix)

```
$ bash scripts/tests/tracker-agent-read-test.sh ; echo EXIT=$?
=== Summary ===
Passed: 49
Failed: 8
EXIT=1
```

The 8 failing assertions (the tracker-mode group, exactly as predicted):

```
FAIL 1.2 tracker mode detected
FAIL 3.1 BD-001 tracker rc=0
FAIL 3.1 BD-001 source line tracker
FAIL 3.1 BD-001 source state lowercase
FAIL 3.1 BD-001 title
FAIL 3.1 BD-001 body content
FAIL 3.2 TD-010 source line tracker
FAIL 3.2 TD-010 description
```

The file carried ZERO `PACK_TRACKER_DEFERRAL_OVERRIDE` references pre-fix.

---

## 2. The fix (minimal, pattern-matched)

Added the `PACK_TRACKER_DEFERRAL_OVERRIDE=1` export to
`scripts/tests/tracker-agent-read-test.sh`, **exactly matching** the
placement/pattern used in the 21 already-overridden test scripts. Reference
copied verbatim from `scripts/tests/tracker-config-test.sh` (lines 15-18):
same comment text, same location (after `set -u`, before `REPO_ROOT=`),
same `export` idiom.

This is the design-sanctioned test-only seam (ARCHITECTURE-BD-214 §3 line
279: "Dormant-but-testable: every tracker test script exports
`PACK_TRACKER_DEFERRAL_OVERRIDE=1`"). It lets `tracker_mode()` compute
normally for this dormant tracker test — restoring pre-C1 behavior. NO
assertion was altered, deleted, or weakened.

### Diff (single targeted insertion)

```diff
 set -u

+# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
+# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
+# code exercised under the clamp (never set it in a live run).
+export PACK_TRACKER_DEFERRAL_OVERRIDE=1
+
 REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
 LIB_DIR="$REPO_ROOT/scripts/lib"
```

### Verification — target test PASSES (group genuinely passes, not skips)

```
$ bash scripts/tests/tracker-agent-read-test.sh ; echo EXIT=$?
=== Summary ===
Passed: 57
Failed: 0
All tests passed.
EXIT=0
```

The 8 previously-failing assertions now PASS (not skip — `Passed: 57` =
prior 49 PASS + the 8 formerly-failing now PASS; the tracker-mode group runs
and asserts real values):

```
PASS 1.2 tracker mode detected
PASS 3.1 BD-001 tracker rc=0
PASS 3.1 BD-001 source line tracker
PASS 3.1 BD-001 source state lowercase
PASS 3.1 BD-001 state lowercase (no OPEN uppercase)
PASS 3.1 BD-001 title
PASS 3.1 BD-001 body content
PASS 3.2 TD-010 source line tracker
PASS 3.2 TD-010 description
```

---

## 3. Completeness sweep (prevent whack-a-mole)

### 3a. Grep every tracker-exercising test script for the override

Matcher: scripts under `scripts/` matching any of `tracker-config.sh`,
`tracker_mode`, `mode.state`, `state = "tracker"` (24 scripts). Override
status after my fix:

| Status | Script |
|---|---|
| MISSING | scripts/test-detect.sh |
| HAS | scripts/tests/test-migrate-v10-to-v11-gates.sh |
| HAS | scripts/tests/test-tracker-cycle-check.sh |
| HAS | scripts/tests/test-tracker-links.sh |
| HAS | scripts/tests/test-tracker-phase-task.sh |
| HAS | scripts/tests/test-tracker-promote-direct.sh |
| HAS | scripts/tests/test-tracker-promote-path1.sh |
| HAS | scripts/tests/test-tracker-promote-path2.sh |
| HAS | scripts/tests/test-validate-pack-check-51-flip-block.sh |
| HAS | scripts/tests/tracker-agent-read-test.sh *(fixed this report)* |
| HAS | scripts/tests/tracker-bd129-gh-repo-test.sh |
| HAS | scripts/tests/tracker-bd130-doctor-wired-test.sh |
| HAS | scripts/tests/tracker-bd132-race-test.sh |
| HAS | scripts/tests/tracker-bd133-header-preservation-test.sh |
| HAS | scripts/tests/tracker-bd134-close-retry-test.sh |
| HAS | scripts/tests/tracker-bd204-lossless-roundtrip-test.sh |
| MISSING | scripts/tests/tracker-config-schema-test.sh |
| HAS | scripts/tests/tracker-config-test.sh |
| HAS | scripts/tests/tracker-deferral-gate-test.sh |
| HAS | scripts/tests/tracker-init-test.sh |
| HAS | scripts/tests/tracker-migrate-forward-test.sh |
| HAS | scripts/tests/tracker-migrate-reverse-test.sh |
| HAS | scripts/tests/tracker-migrate-roundtrip-test.sh |
| HAS | scripts/tests/tracker-provider-test.sh |

### 3b. Two MISSING-override scripts evaluated — both PASS, both incidental matches

The rule: add the override ONLY if a script exercises tracker mode AND
fails when run. Both MISSING scripts were run:

```
EXIT=0  scripts/test-detect.sh              (=== Results: 100 passed, 0 failed ===)
EXIT=0  scripts/tests/tracker-config-schema-test.sh   (PASS: 40  FAIL: 0)
```

- `test-detect.sh` — matches the grep because it references tracker tokens
  as detection signals (the `detect.sh` capability detector reads tracker
  markers); it never evaluates `tracker_mode()`. Passes; no override needed.
- `tracker-config-schema-test.sh` — validates `tracker.toml` SCHEMA
  structure (Check 29 surface), not `tracker_mode()` evaluation. Passes; no
  override needed.

Neither fails under the clamp, so per the rule **neither is modified.**

### Sweep conclusion

`scripts/tests/tracker-agent-read-test.sh` was the **sole** remaining gap —
the only tracker-exercising test script that both lacked the override AND
failed under the clamp. Evidence: §1 (it failed) + §2 (now passes) + §3b
(the other two MISSING-override scripts pass without the override and only
match incidentally). No other script requires the override.

---

## 4. FULL CI `tests` job verified locally (Rule 3 — the failure that caused this hotfix)

I ran the COMPLETE CI battery the way CI does. The wired run-command list
was extracted programmatically from `.github/workflows/validate-pack.yml`
(both jobs), not hand-enumerated.

### `validate` job (2 invocations)

```
EXIT=0 :: python3 scripts/validate-pack.py                         → PASSED — all checks clean
EXIT=0 :: PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py    → PASSED — all checks clean
```

### `tests` job (57 wired run-commands + the CI restore-manifest step)

Every step EXIT=0. The CI `restore committed manifest before verify` step
(`git checkout HEAD -- test-fixtures/manifest.txt`, read-only path checkout)
was replicated between `--all --clean` and `--verify` so `--verify` is
non-tautological, matching the workflow ordering.

```
EXIT=0 :: bash scripts/test-detect.sh
EXIT=0 :: bash scripts/tests/tracker-provider-test.sh
EXIT=0 :: bash scripts/tests/tracker-config-test.sh
EXIT=0 :: bash scripts/tests/tracker-init-test.sh
EXIT=0 :: bash scripts/tests/tracker-agent-read-test.sh
EXIT=0 :: bash scripts/tests/tracker-migrate-forward-test.sh
EXIT=0 :: bash scripts/tests/tracker-migrate-reverse-test.sh
EXIT=0 :: bash scripts/tests/tracker-migrate-roundtrip-test.sh
EXIT=0 :: bash scripts/tests/test-tracker-phase-task.sh
EXIT=0 :: bash scripts/tests/test-tracker-links.sh
EXIT=0 :: bash scripts/tests/test-tracker-cycle-check.sh
EXIT=0 :: bash scripts/tests/tracker-errors-test.sh
EXIT=0 :: bash scripts/tests/tracker-config-schema-test.sh
EXIT=0 :: bash scripts/tests/recommendation-state-schema-test.sh
EXIT=0 :: bash scripts/tests/test-per-entry.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-checks-36-37-38.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-39.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-40.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-41.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-18.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-16.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-19.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-42.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-43.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-44.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-45.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-46.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-removed-doc-advisory.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-50-codec-single-source.sh
EXIT=0 :: bash scripts/tests/test-validate-pack-check-51-flip-block.sh
EXIT=0 :: bash scripts/tests/tracker-deferral-gate-test.sh
EXIT=0 :: bash scripts/tests/tracker-bd129-gh-repo-test.sh
EXIT=0 :: bash scripts/tests/tracker-bd130-doctor-wired-test.sh
EXIT=0 :: bash scripts/tests/tracker-bd132-race-test.sh
EXIT=0 :: bash scripts/tests/tracker-bd133-header-preservation-test.sh
EXIT=0 :: bash scripts/tests/tracker-bd134-close-retry-test.sh
EXIT=0 :: bash scripts/tests/recommendation-test.sh
EXIT=0 :: bash scripts/tests/pack-help-test.sh
EXIT=0 :: bash scripts/tests/test-customization-preserve.sh
EXIT=0 :: bash scripts/tests/test-init-project.sh
EXIT=0 :: bash scripts/tests/test-migrate-v10-to-v11.sh
EXIT=0 :: bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
EXIT=0 :: bash scripts/tests/test-migrate-v10-to-v11-gates.sh
EXIT=0 :: bash scripts/tests/test-migrate-v10-to-v11-decompose.sh
EXIT=0 :: bash scripts/test-migrator-core.sh
EXIT=0 :: bash scripts/test-migrator-manifest.sh
EXIT=0 :: bash scripts/test-migrator-capability-translation.sh
EXIT=0 :: bash test-fixtures/build.sh --all --clean
EXIT=0 :: git checkout HEAD -- test-fixtures/manifest.txt (CI restore step)
EXIT=0 :: bash test-fixtures/build.sh --verify
EXIT=0 :: bash scripts/tests/test-v11-realistic-ot.sh
EXIT=0 :: bash scripts/test-migrator-skills.sh
EXIT=0 :: bash scripts/test-persona-contracts.sh
EXIT=0 :: bash scripts/tests/template-translations-test.sh
EXIT=0 :: bash scripts/tests/template-version-test.sh
EXIT=0 :: bash scripts/tests/test-issue-forms.sh
```

**TOTAL NONZERO STEPS: 0.** Full CI tests job is green locally.

---

## 5. Manifest regeneration (Rule 4 — v11-surface commit)

`scripts/tests/` is v11-surface, so I ran the manifest rebuild:

```
$ bash test-fixtures/build.sh --all --clean   → EXIT=0
$ git diff --stat test-fixtures/manifest.txt  → (empty)
```

**Manifest diff is EMPTY (expected).** The manifest hashes the
git-tracked source fixtures; the edited file is a test SCRIPT, not a
fixture input, so its content does not change any manifest SHA. No manifest
update needed in the commit. (The `--verify` run in §4 also passed against
the restored committed manifest.)

---

## 6. Files changed inventory

| Path | Change type | Notes |
|---|---|---|
| `scripts/tests/tracker-agent-read-test.sh` | modified | +4 lines (3-line comment + 1 export), single insertion after `set -u` |

Not mine (pre-existing at pre-flight, left untouched): `backlog/BD-214.md`
(shown `modified` in the opening `git status`; my session never edited it).
No new files. No deletions.

Final `git status --short`:
```
 M backlog/BD-214.md            (pre-existing — not this session)
 M scripts/tests/tracker-agent-read-test.sh   (this fix)
```

---

## 7. Plan deviations

**Zero.** The fix is exactly the pattern-matched override insertion the
hotfix prompt + design §3 specify. No assertions touched. No additional
scripts modified (sweep proved none needed).

## 8. New POQs introduced

**None.**

## 9. Definition-of-Done checklist

| Item | Result |
|---|---|
| Override added to `tracker-agent-read-test.sh`, pattern-matched to existing scripts | PASS (§2 diff) |
| Target test EXIT=0; tracker-mode group genuinely PASSES (not skips) | PASS (§2: 57 passed, 0 failed; group asserts real values) |
| No assertion deleted/weakened (real fix, no band-aid) | PASS (§2 diff = pure insertion) |
| Completeness sweep: tracker-agent-read is the ONLY remaining gap | PASS (§3a/§3b — other 2 MISSING scripts pass + are incidental) |
| Full CI `validate` job verified locally (both invocations) | PASS (§4 — both EXIT=0, all checks clean) |
| Full CI `tests` job verified locally (all 57 wired steps + restore) | PASS (§4 — 0 nonzero steps) |
| Manifest regenerated; diff reported | PASS (§5 — empty, expected) |
| Edit in place, not full rewrite; re-read after | PASS (single Edit, verified via `git diff`) |
| Agents never commit (git read-only only) | PASS (§10) |
| IMPL-REPORT written to specified path | PASS (this file) |

---

## 10. Rules-Applied Verification Block

| # | Rule | Evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **Agents never commit** (git read-only) | Only git verbs run: `git rev-parse HEAD`, `git status`, `git diff`, and `git checkout HEAD -- test-fixtures/manifest.txt` (read-only path-checkout, replicating CI; no branch/index mutation). No `add`/`commit`/`push`/`tag`. Final HEAD unchanged: `2d3f3d08896...`. | COMPLIANT |
| 2 | **Real fixes only — no band-aids** | Diff is a pure insertion of the design-sanctioned test-only seam (design §3 line 279); zero assertions changed. Target test went `Failed: 8` → `Failed: 0` with the tracker-mode group `PASS` (real value asserts: `PASS 3.1 BD-001 body content`, `PASS 1.2 tracker mode detected`) — passes, does not skip. | COMPLIANT |
| 3 | **Verify the FULL CI tests job locally** | §4: `validate` job both invocations EXIT=0 (`PASSED — all checks clean`); `tests` job all 57 wired run-commands + CI restore step → `TOTAL NONZERO STEPS: 0`. Wired list extracted programmatically from `validate-pack.yml`, not hand-picked. | COMPLIANT |
| 4 | **Regenerate manifest on v11-surface commits** | §5: ran `bash test-fixtures/build.sh --all --clean` (EXIT=0); `git diff --stat test-fixtures/manifest.txt` empty. Test-script edit does not change a fixture SHA → manifest unchanged (expected). | COMPLIANT |
| 5 | **Edit in place, not full rewrite** | Single `Edit` call inserting 4 lines after `set -u`; `git diff` shows one hunk, no other lines touched. Post-edit state confirmed via `git diff scripts/tests/tracker-agent-read-test.sh`. | COMPLIANT |
| 6 | **Rules-Applied Verification Block** | This table. | COMPLIANT |
| 7 | **PREFLIGHT + STOP-MEANS-STOP** | Emitted before this Write: `PREFLIGHT: fix complete; FULL CI tests job verified locally; HEAD 2d3f3d088969...; about to Write IMPL-REPORT to .../IMPL-REPORT-BD-214-C1-FIX2.md`. No parent stop message received. | COMPLIANT |
