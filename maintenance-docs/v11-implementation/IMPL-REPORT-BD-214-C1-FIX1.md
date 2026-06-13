# IMPL-REPORT — BD-214 C1 review fixes (FIX-1)

**Author:** pack-coder (fresh fix-coder spawn). **Date:** 2026-06-13.
**Branch:** `v11-dev`. **HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747`
(unchanged — agent ran no state-changing git verb; C1 changes remain uncommitted
in the working tree).
**Scope:** the five user-approved C1 review fixes (S-1+N-3 chmod, S-2 advisory
token both-sides, N-1 dead-constant removal, N-2 advisory alignment). Nothing else.

---

## Fix-by-fix

### S-2 — advisory RIGHT side canonicalized (`Resolution:` → `Resolved:`)

`scripts/pack-td.sh`, BACKLOG-patch advisory heredoc (cmd_promote).

The C1 edit had already fixed the LEFT side (`Resolution: n/a` → `Resolved: n/a`).
The reviewer flagged the RIGHT side still read non-canonical `Resolution: $res_text`.
Corrected the RIGHT side to `Resolved: $res_text` so the whole advisory line is
self-consistent.

**Before (working-tree state inherited from C1):**
```
  Status: Open       → Status: Resolved
  Resolved: n/a    → Resolution: $res_text
```
**After (S-2 + N-2 applied together):**
```
  Status: Open    → Status: Resolved
  Resolved: n/a   → Resolved: $res_text
```

Genuine canonicalization, not a band-aid: the verb's own `resolve`/promote flow
sets `Status: Resolved` + a `Resolved:` field; the advisory now names the same
canonical field on both sides.

### N-2 — advisory column alignment (cosmetic)

Same two lines (folded into the S-2 edit since they share the line pair). The
arrows are now column-aligned: each left label + padding places the `→` at the
same byte offset (19):
- `  Status: Open    →` = 2 + `Status: Open` (12) + 4 spaces → arrow at col 19
- `  Resolved: n/a   →` = 2 + `Resolved: n/a` (13) + 3 spaces → arrow at col 19

Verified with `awk '... grep "→"'`:
```
4:  Status: Open    → Status: Resolved
5:  Resolved: n/a   → Resolved: $res_text
```

### N-1 — dead constant removed (`_CHECK_51_VERB_GATE_FILES`)

`scripts/validate-pack.py`, Check 51 block (~line 7980).

Zero-reference verification BEFORE removal:
```
$ grep -rn "_CHECK_51_VERB_GATE_FILES" scripts/ .github/ test-fixtures/
scripts/validate-pack.py:7980:_CHECK_51_VERB_GATE_FILES = (
```
Only the definition appears — no consumer. Leg 2 of Check 51 hardcodes the paths
directly (`REPO_ROOT / "scripts/pack-tracker.sh"` at :8024, `... "scripts/tracker-migrate.sh"`
at :8025), so the tuple was genuinely dead. Removed the 4-line definition:
```python
-_CHECK_51_VERB_GATE_FILES = (
-    "scripts/pack-tracker.sh",
-    "scripts/tracker-migrate.sh",
-)
```
`_CHECK_51_CLAMP_FILE` (above it, still used by leg 1) and the leg-4 patterns
(below it) are untouched. Genuine dead-code removal; no assertion or behavior
change — Check 51 still PASSES legs 1/2/4.

### S-1 + N-3 — executable bit restored (chmod-only, 20 files)

The C1 override-export edits dropped `+x` on 17 existing tracker/recommendation
test scripts (mode `100755 → 100644`); the 3 newly-created C1 test files were
created `100644`. Restored `+x` on all 20 (chmod is a filesystem op — no
`git add`/`update-index` run).

**17 existing scripts (`100755 → 100644` → restored to `100755`):**
- `scripts/tests/template-translations-test.sh`
- `scripts/tests/test-migrate-v10-to-v11-gates.sh`
- `scripts/tests/test-tracker-phase-task.sh`
- `scripts/tests/test-tracker-promote-direct.sh`
- `scripts/tests/test-tracker-promote-path1.sh`
- `scripts/tests/test-tracker-promote-path2.sh`
- `scripts/tests/tracker-bd129-gh-repo-test.sh`
- `scripts/tests/tracker-bd130-doctor-wired-test.sh`
- `scripts/tests/tracker-bd132-race-test.sh`
- `scripts/tests/tracker-bd133-header-preservation-test.sh`
- `scripts/tests/tracker-bd134-close-retry-test.sh`
- `scripts/tests/tracker-config-test.sh`
- `scripts/tests/tracker-init-test.sh`
- `scripts/tests/tracker-migrate-forward-test.sh`
- `scripts/tests/tracker-migrate-reverse-test.sh`
- `scripts/tests/tracker-migrate-roundtrip-test.sh`
- `scripts/tests/tracker-provider-test.sh`

**3 new C1 test files (created `100644` → restored to `100755`):**
- `scripts/tests/test-validate-pack-check-51-flip-block.sh`
- `scripts/tests/test-validate-pack-check-50-codec-single-source.sh`
- `scripts/tests/tracker-deferral-gate-test.sh`

Post-chmod verification:
```
$ git diff --summary | grep -i "mode change"
NONE
$ for f in (3 new files): stat -f '%Lp'
755 test-validate-pack-check-51-flip-block.sh
755 test-validate-pack-check-50-codec-single-source.sh
755 tracker-deferral-gate-test.sh
```
chmod-only confirmed — `git diff --stat` for the two content-edited files shows
only the S-2/N-2 line pair and the N-1 removal; no test-script content lines
changed.

---

## Out-of-scope item SURFACED (not fixed)

Four other modified test scripts are currently mode `644` but were ALSO `644` at
HEAD (`git ls-tree HEAD` confirms `100644` for each) — i.e. their non-executable
state is PRE-EXISTING, not a C1 regression, so they are OUTSIDE the approved
"17 scripts that lost +x during C1" scope. I did NOT chmod them (doing so would
introduce a new mode change beyond the approved fix):
- `scripts/tests/recommendation-test.sh`
- `scripts/tests/test-tracker-cycle-check.sh`
- `scripts/tests/test-tracker-links.sh`
- `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`

These run fine via `bash <script>` (the test harness invokes them with `bash`,
not as bare executables — all batteries passed). Flag for Pack Chat/user: if a
separate decision wants these executable too, that is a distinct (non-C1-fix)
change and was deliberately left out per the scope boundary.

---

## Verification battery (all EXIT=0)

| Command | Result |
|---|---|
| `python3 -c "import ast; ast.parse(...)"` (validate-pack.py) | `SYNTAX OK` |
| `bash -n scripts/pack-td.sh` | `BASH SYNTAX OK` |
| `python3 scripts/validate-pack.py` (full) | `EXIT=0` — `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | `DEEP EXIT=0` — `PASSED — all checks clean` |
| `bash scripts/tests/test-validate-pack-check-51-flip-block.sh` | `EXIT=0` — PASS: 3 / FAIL: 0 |
| `bash scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | `EXIT=0` — PASS: 3 / FAIL: 0 |
| `bash scripts/tests/tracker-deferral-gate-test.sh` | `EXIT=0` — PASS: 12 / FAIL: 0 |
| `bash scripts/tests/test-v11-realistic-ot.sh` (integration) | `EXIT=0` — PASS: 33 / FAIL: 0 |

Key validate-pack tail (full run):
```
── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ──
  OK: Check 50 — no reproduced gz64/base64 codec in validate-pack.py; Check 49 sub-invokes the shared batch codec (OQ-4 single-source)

── Check 51: BD-214 tracker-deferral flip-block guard (legs 1/2/4) ──
  OK: Check 51 — BD-214 flip-block guard: clamp marker present (leg 1), init + enable-recommendations + forward-arm gates present (leg 2), entry-content artifact grep-zero over backlog/ + changelog/ (leg 4). Legs 3/5 land in later commits with their fix-recipes.

PASSED — all checks clean
```

Check 50 (the EE-2 asymmetry the C1 test closes) and Check 51 (the deferral guard)
both PASS — the N-1 dead-constant removal did not affect Check 51's behavior.

---

## Manifest regen (v11-surface rule)

`scripts/pack-td.sh` + `scripts/validate-pack.py` are under `scripts/` (a
v11-surface dir), so the rule fires. Ran:
```
$ bash test-fixtures/build.sh --all --clean
BUILD EXIT=0 ; manifest written
$ git diff --stat test-fixtures/manifest.txt
(empty — no diff)
```
**Manifest diff is EMPTY.** The manifest hashes fixture-file content; it does not
hash `scripts/` source or file mode bits, so the two tiny content edits + the
chmod-only changes produce no manifest delta. Manifest reflects reality with no
diff — nothing to stage. (Per the rule, a manifest is staged only when its diff
is non-empty.)

---

## Files changed inventory

| Path | Change type |
|---|---|
| `scripts/pack-td.sh` | modified (content: S-2 token + N-2 alignment, 1 line pair) |
| `scripts/validate-pack.py` | modified (content: N-1 dead-constant removal) |
| `scripts/tests/template-translations-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-tracker-phase-task.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-tracker-promote-direct.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-tracker-promote-path1.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-tracker-promote-path2.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-bd132-race-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-config-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-init-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-migrate-forward-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/tracker-provider-test.sh` | mode `+x` restored (chmod only) |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | mode `+x` set (new file, chmod only) |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | mode `+x` set (new file, chmod only) |
| `scripts/tests/tracker-deferral-gate-test.sh` | mode `+x` set (new file, chmod only) |

No new files created (report-only output is this IMPL-REPORT, which is the
caller-specified deliverable, not an in-scope source file).

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| S-1+N-3 — 17 regressed scripts restored to `100755` | PASS |
| S-1+N-3 — 3 new C1 test files set to `100755` | PASS |
| S-1+N-3 — no `mode change` remaining in `git diff --summary` | PASS |
| S-1+N-3 — chmod-only (no content lines changed in test scripts) | PASS |
| S-2 — advisory RIGHT side `Resolution:` → `Resolved:` | PASS |
| N-2 — advisory arrows column-aligned | PASS |
| N-1 — `_CHECK_51_VERB_GATE_FILES` zero-ref verified then removed | PASS |
| Edits in place, targeted (no full rewrite) | PASS |
| No out-of-scope file edited | PASS |
| validate-pack full EXIT=0 | PASS |
| validate-pack DEEP EXIT=0 | PASS |
| check-50 / check-51 / gate tests EXIT=0 | PASS |
| integration test-v11-realistic-ot EXIT=0 | PASS |
| manifest regen run; diff reported (empty) | PASS |
| No state-changing git verb run | PASS |

---

## Plan deviations

ZERO. The five fixes were applied exactly as scoped; no architecture or behavior
change. One out-of-scope observation (4 pre-existing-`644` test scripts) was
SURFACED, not fixed (see "Out-of-scope item SURFACED").

## New POQs introduced

None.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status`, `git status --short`, `git diff`, `git diff --stat`, `git diff --summary`, `git ls-tree HEAD ...`. Zero `add/commit/push/tag/reset/stash/checkout/rm`. `chmod` used for the executable bit (filesystem op, not a git index op — no `git update-index` run). HEAD still `0027b106789e09bad2d7cdb380c8c499d7d0f747`. | COMPLIANT |
| 2. Real fixes only — no band-aids | S-2 = genuine canonicalization to the verb's own `Resolved:` field (matches `Status: Resolved` semantics); N-1 = genuine dead-code removal after `grep -rn` proved zero references (leg 2 hardcodes paths at :8024-8025). No assertion changed; Check 51 still asserts legs 1/2/4 and PASSES. | COMPLIANT |
| 3. Verify the full CI suite | `python3 scripts/validate-pack.py` EXIT=0; `PACK_VALIDATE_DEEP=1 ...` EXIT=0; `test-v11-realistic-ot.sh` EXIT=0 (33/33); check-51 EXIT=0 (3/3); check-50 EXIT=0 (3/3); gate EXIT=0 (12/12). All quoted in the battery table. | COMPLIANT |
| 4. Regenerate manifest on v11-surface commits | `bash test-fixtures/build.sh --all --clean` EXIT=0; `git diff --stat test-fixtures/manifest.txt` → empty (manifest hashes fixtures, not `scripts/` source or mode bits). Manifest reflects reality with no diff; nothing to stage per the non-empty-diff condition. | COMPLIANT |
| 5. Edit in place, not full rewrite | `scripts/pack-td.sh` diff = exactly the 1 advisory line pair (`git diff` quoted); `scripts/validate-pack.py` removal = the 4-line dead-constant tuple only. Targeted anchored edits; no full rewrite. | COMPLIANT |
| 6. Filename uniqueness / no new files | No source file created. Only deliverable written is this IMPL-REPORT at the caller-specified path (`IMPL-REPORT-BD-214-C1-FIX1.md` — unique under `find . -name`). | COMPLIANT |
| 7. Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cells. | COMPLIANT |
| 8. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 5/5 fixes complete; verification PASS; HEAD 0027b106789e09bad2d7cdb380c8c499d7d0f747; about to Write IMPL-REPORT to <path>` in the message immediately before this Write. No stop/halt/revert message received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete:
CLAUDE.md (full, incl. all `## Pack memory`, via system context);
`maintenance-docs/v11-implementation/PLAN-BD-214-TRACKER-DEFERRAL.md` (full, 500
lines, every section incl. Revision log / §4 C1 / §5 / §11 / §12 / §12a);
`scripts/pack-td.sh` (full, 336 lines); `scripts/validate-pack.py` Check-51 region
(:7960-8064, the dead-constant + check body) read directly before editing. No
named document was derived rather than read.

**End of IMPL-REPORT-BD-214-C1-FIX1.md**
