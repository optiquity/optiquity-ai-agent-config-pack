# IMPL-REPORT — BD-214 C3 FIX-2 (N-A: stale doc-comment in test-migrator-core.sh)

- **Branch:** v11-dev
- **HEAD SHA (worktree):** `c994d82cdab77c3ebddabe1c4db6b56d50454201`
- **Base state:** C3 edits already in the working tree, uncommitted (35 modified
  tracked files per `git status` at start). This fix adds ONE comment-only edit on
  top of that working set. No commit / stage performed (agents never commit).
- **Date:** 2026-06-13
- **Scope:** single comment-only edit — `scripts/test-migrator-core.sh` (~line 356-359).

---

## 1. The fix (N-A)

`scripts/test-migrator-core.sh` carried a STALE doc-comment above the §14
`migrator_target_surface_for_version v10` assertion. The comment listed
`tracker.toml.example` as one of the "v11-only additions" that v10 must not
advertise. After C3's M-1, `tracker.toml.example` is no longer a v11 surface
addition at all — it is DEFERRED (BD-214) and is absent from BOTH the v10 and
v11 surfaces. The §15 v11 assertion (the M-1 logic) already asserts it ABSENT
(`"$out" != *"tracker.toml.example"*`); only the §14 doc-comment was stale.

**Comment-only edit. The assertion logic was NOT touched** (verified by diff —
the assertion `if [[ ... ]]` blocks for both §14 and §15 are byte-unchanged by
this fix; the §15 `!=` assertion + pass-string are pre-existing C3 M-1 edits,
left exactly as found).

### Before (lines 356-359)

```
# v10 surface (per migrator-core.sh §3 / architecture) includes CLAUDE.md,
# AGENTS.md, GEMINI.md, the three .claude/.codex/.gemini agent dirs, and
# .codex/config.toml + BACKLOG.md. v10 must NOT advertise the v11-only
# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).
```

### After (lines 356-361)

```
# v10 surface (per migrator-core.sh §3 / architecture) includes CLAUDE.md,
# AGENTS.md, GEMINI.md, the three .claude/.codex/.gemini agent dirs, and
# .codex/config.toml + BACKLOG.md. v10 must NOT advertise the v11-only
# additions (HELP-FRAGMENT.md, ISSUE_TEMPLATE). tracker.toml.example is
# deferred (BD-214) and is absent from BOTH the v10 and v11 surfaces, so
# the v10 assertion below also confirms it stays absent here.
```

The new comment accurately describes the current v11 install surface:
`tracker.toml.example` is no longer characterized as a v11-only addition; it is
described as deferred (BD-214) and absent from both surfaces — which matches both
the §14 v10 assertion (`"$out" != *"tracker.toml.example"*`) and the §15 v11
assertion (`"$out" != *"tracker.toml.example"*`).

### Full diff of this fix (`git diff scripts/test-migrator-core.sh`)

```diff
@@ -356,7 +356,9 @@ rc=$?
 # v10 surface (per migrator-core.sh §3 / architecture) includes CLAUDE.md,
 # AGENTS.md, GEMINI.md, the three .claude/.codex/.gemini agent dirs, and
 # .codex/config.toml + BACKLOG.md. v10 must NOT advertise the v11-only
-# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).
+# additions (HELP-FRAGMENT.md, ISSUE_TEMPLATE). tracker.toml.example is
+# deferred (BD-214) and is absent from BOTH the v10 and v11 surfaces, so
+# the v10 assertion below also confirms it stays absent here.
 if [[ $rc -eq 0 \
```

(The remaining hunk shown by `git diff` at lines ~390-401 — the `!=
*"tracker.toml.example"*` assertion + the updated pass-string — are PRE-EXISTING
C3 M-1 edits already in the working tree, NOT introduced by this fix.)

---

## 2. Files changed inventory

| Path | Change type | Note |
|---|---|---|
| `scripts/test-migrator-core.sh` | modified (comment-only) | this fix — §14 doc-comment, +3/-1 lines net |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C3-FIX2.md` | new | this report |

No other file modified by this fix. `backlog/BD-214.md` NOT touched (out of scope).
`test-fixtures/manifest.txt` left in its C3 working-tree state (see §4).

---

## 3. Verification — FULL CI wired-test battery (no sampling)

The wired-test list was extracted from `.github/workflows/validate-pack.yml`
(both jobs). Every `run:` command was executed locally and its exit code captured.

### Job `validate` (workflow lines 85-104)

| Step | Command | EXIT |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **0** |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** |

Captured exit lines (`/tmp/bd214-ci-validate.log`):
```
EXIT[validate-pack general]=0
EXIT[validate-pack DEEP]=0
```

### Job `tests` — offline suites (workflow lines 119-265)

All 50 enumerated `bash scripts/...` suites ran; every one EXIT=0. Captured
`<rc>\t<label>` rows (all `0`):

```
0 detect                          0 tracker-provider              0 tracker-config
0 tracker-init                    0 tracker-agent-read            0 tracker-migrate-forward
0 tracker-migrate-reverse         0 tracker-migrate-roundtrip     0 tracker-phase-task
0 tracker-links                   0 tracker-cycle-check           0 tracker-errors
0 tracker-config-schema           0 recommendation-state-schema   0 per-entry
0 check-32-33-34                  0 check-36-37-38                0 check-39
0 check-40                        0 check-41                      0 check-18
0 check-16                        0 check-19                      0 check-42
0 check-43                        0 check-44                      0 check-45
0 check-46                        0 check-48-removed-doc          0 check-49-field-faithfulness
0 check-50-codec                  0 check-51-flip-block           0 tracker-deferral-gate
0 tracker-bd129                   0 tracker-bd130                 0 tracker-bd132
0 tracker-bd133                   0 tracker-bd134                 0 recommendation
0 pack-help                       0 customization-preserve        0 init-project
0 migrate-v10-to-v11              0 migrate-dry-run               0 migrate-gates
0 migrate-decompose               0 migrator-core                 0 migrator-manifest
0 migrator-capability-translation
```

`migrator-core` (the directly-affected suite) summary: `=== Results: 19 passed,
0 failed ===`, EXIT=0.

### Job `tests` — fixture-dependent + integration steps (workflow lines 266-306)

| Step | Command | EXIT |
|---|---|---|
| build test fixtures | `bash test-fixtures/build.sh --all --clean` | **0** |
| fixture manifest verify | `bash test-fixtures/build.sh --verify` | see note |
| v11-realistic-ot | `bash scripts/tests/test-v11-realistic-ot.sh` | **0** |
| migrator-skills | `bash scripts/test-migrator-skills.sh` | **0** |
| persona contracts | `bash scripts/test-persona-contracts.sh` | **0** |
| template-translations | `bash scripts/tests/template-translations-test.sh` | **0** |
| template-version | `bash scripts/tests/template-version-test.sh` | **0** |
| issue-forms | `bash scripts/tests/test-issue-forms.sh` | **0** |

**`fixture manifest verify` note — EXIT=1 against the committed-HEAD manifest;
EXIT=0 against the post-C3 manifest. NOT a regression from this fix.**

The CI `--verify` step is preceded by `git checkout HEAD -- test-fixtures/
manifest.txt` (workflow step a2), which restores the COMMITTED manifest. In this
worktree HEAD (`c994d82`) is PRE-C3 — C3's manifest changes are uncommitted. So
`--verify` compared rebuilt fixtures against HEAD's stale pre-C3 SHAs and warned
on exactly the three fixtures C3 changed:
```
warning: v11-realistic-ot MISMATCH: expected=ae3fc6ff... actual=685169ef...
warning: v11-flat-file    MISMATCH: expected=f9705c27... actual=1d39609d...
warning: v11-tracker-on   MISMATCH: expected=944ddee3... actual=d1430225...
EXIT[fixture-manifest-verify]=1
```
Re-running `--verify` against the C3 working-tree manifest (= the state HEAD will
hold once Pack Chat commits C3) yields all-OK, EXIT=0:
```
v10-minimal OK / v10-realistic-ot OK / v11-realistic-ot OK /
v11-flat-file OK / v11-tracker-on OK / existing-project-mid-dev OK
EXIT[verify-vs-C3-manifest]=0
```
This is a pre-existing C3-vs-uncommitted-HEAD artifact, fully independent of this
comment edit (see §4 proof that the comment edit produces zero fixture/manifest
delta). On the real CI runner, C3's manifest is committed, so HEAD carries it and
`--verify` passes.

---

## 4. Manifest check (v11-surface rule)

`scripts/` is a v11-surface dir, so `bash test-fixtures/build.sh --all --clean`
was run (EXIT=0). **The comment edit is fixture-neutral — it produced ZERO
manifest delta:**

- `scripts/test-migrator-core.sh` is NOT a fixture input (`grep -rn
  "test-migrator-core" test-fixtures/` → empty).
- The freshly-rebuilt manifest was compared byte-for-byte against the C3
  working-tree manifest snapshot taken before the rebuild: `diff` → IDENTICAL
  ("RESULT: IDENTICAL — my comment edit produced ZERO manifest delta").

The `git diff test-fixtures/manifest.txt` vs HEAD is non-empty, but that delta is
entirely PRE-EXISTING C3 work (the three v11 fixture SHA bumps), not caused by
this fix. The working-tree manifest was left in its C3 state (restored after the
CI `--verify` HEAD-restore dance), so the working tree is as-found plus only the
one comment edit.

---

## 5. Plan deviations

**Zero.** Comment-only edit exactly as specified; assertion logic untouched; no
out-of-scope files modified; `backlog/BD-214.md` not touched.

## 6. New POQs introduced

None.

---

## 7. Definition-of-Done checklist

| Item | Result |
|---|---|
| Stale doc-comment updated to match current v11 surface (no `tracker.toml.example` as v11 addition) | PASS |
| Assertion logic NOT altered (comment-only) | PASS |
| `bash -n scripts/test-migrator-core.sh` syntax OK | PASS |
| `migrator-core` suite green (19/0, EXIT=0) | PASS |
| validate-pack general EXIT=0 | PASS |
| validate-pack DEEP (`PACK_VALIDATE_DEEP=1`) EXIT=0 | PASS |
| Full `tests` job offline suites (50/50) EXIT=0 | PASS |
| Fixture/integration steps (build, v11-realistic-ot, migrator-skills, persona-contracts, template-translations, template-version, issue-forms) EXIT=0 | PASS |
| `fixture manifest verify` reconciled (EXIT=0 vs post-C3 manifest; EXIT=1 vs stale HEAD explained, not a regression) | PASS |
| Manifest regenerated; comment edit = zero manifest delta (confirmed) | PASS |
| No git state changes (read-only verbs only) | PASS |
| `backlog/BD-214.md` not touched | PASS |
| No files modified outside scope (comment edit + this report only) | PASS |

---

## 8. Rules-Applied Verification Block

| # | Rule name | Verification evidence | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Only read-only git verbs used: `git rev-parse HEAD`, `git status`, `git diff`, and the CI-replicating `git checkout HEAD -- test-fixtures/manifest.txt` (the allowed inspect form, mirroring workflow step a2; restored afterward). No `git add`/`commit`/`push`/`tag`. `git rev-parse HEAD` → `c994d82cdab77c3ebddabe1c4db6b56d50454201` (unchanged). | COMPLIANT |
| 2 | Real fixes only (comment matches already-correct assertion; assertion unchanged) | `git diff scripts/test-migrator-core.sh` shows the only hand-introduced hunk is the §14 comment (`-# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).` → 3-line replacement). The §14 + §15 `if [[ ... ]]` assertion bodies are byte-unchanged by this fix. New comment matches both assertions' `!= *"tracker.toml.example"*` semantics. | COMPLIANT |
| 3 | Verify the FULL CI suite — every wired script, no sampling | All `run:` commands extracted from `.github/workflows/validate-pack.yml` both jobs; executed each. validate job: `EXIT[validate-pack general]=0`, `EXIT[validate-pack DEEP]=0`. tests job: 50/50 offline suites EXIT=0 (rows quoted §3); fixture/integration steps EXIT=0 (`v11-realistic-ot`, `migrator-skills`, `persona-contracts`, `template-translations`, `template-version`, `issue-forms`); `fixture-manifest-verify` EXIT=0 vs post-C3 manifest (EXIT=1 vs stale HEAD explained + reconciled). | COMPLIANT |
| 4 | Manifest (scripts/ is v11-surface → run build; comment edit not a fixture input) | `bash test-fixtures/build.sh --all --clean` EXIT=0. `grep -rn "test-migrator-core" test-fixtures/` → empty (not a fixture input). `diff /tmp/bd214-manifest-before.txt test-fixtures/manifest.txt` → IDENTICAL (zero delta from this edit). git-diff-vs-HEAD non-emptiness is pre-existing C3 work. | COMPLIANT |
| 5 | Edit in place (single targeted comment edit; re-read after) | Single `Edit` call on the §14 comment block (unique match). Post-edit file state confirmed via `git diff` (quoted §1) and via `bash -n` syntax OK + `migrator-core` run (19/0). | COMPLIANT |
| 6 | Rules-Applied Verification Block | This table — per-rule name + quoted evidence + COMPLIANT/N/A/VIOLATED. | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in the assistant turn immediately before this Write, after all edits + FULL verification PASS: `PREFLIGHT: fix complete; FULL CI wired-test job verified locally ...; HEAD c994d82...; about to Write IMPL-REPORT to <path>`. No parent stop message received. | COMPLIANT |

---

## 9. Boundary discipline check

This fix touches `scripts/test-migrator-core.sh` — a PACK-SIDE file (not under
`project-template/` or `supporting-docs/`). No project-side file was edited, so
the project-side SSOT pre-flight (P-missed-7) does not trigger. The added comment
references `BD-214` and v10/v11 surface concepts, both of which are pack-side /
migrator-test concepts appropriate to a pack-side migrator test script. No
project-side surface gained a pack-only reference. No boundary-discipline STOP.
