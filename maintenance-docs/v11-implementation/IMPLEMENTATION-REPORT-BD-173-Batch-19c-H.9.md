# IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9

**Commit:** H.9 — Leak sweep Categories A + B (per-entry skeleton sweep)
**BD:** BD-173 (Batch 19c)
**Branch:** v11-dev
**HEAD at start:** `c8d61ee44d22990f34d6374d3726e6c88e3ca3a6`
**Author:** pack-coder (background subagent)
**Date:** 2026-05-23

---

## §1 Scope

**Surface:** project-side per-entry skeleton files under
`project-template/docs/project/{backlog,implementation-plan,changelog}/`.

**Files modified (7):**

1. `project-template/docs/project/backlog/_rules.md`
2. `project-template/docs/project/backlog/_intro.md`
3. `project-template/docs/project/implementation-plan/_rules.md`
4. `project-template/docs/project/implementation-plan/_intro.md`
5. `project-template/docs/project/changelog/_rules.md`
6. `project-template/docs/project/changelog/_intro.md` (Category B)
7. `project-template/docs/project/changelog/_format.md` (Category B)

**Categories applied:**
- Category A — Drop architect-doc cite clause; preserve rule wording: **27 leaks** (25 audit-specified + 2 audit-gap catches)
- Category B — Replace architect-doc cite with sibling reference or descriptive prose: **5 leaks**

**Total leaks closed:** 32 / 32 = **30 audit-specified** (per AUDIT-PRE-19C-BOUNDARY-LEAKS.md + ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md §1.1-§1.2 + PLAN-CLEANUP-BATCH-19C.md H.9) **+ 2 audit-gap catches** (scope-expanded by Pack Chat decision at H.9 review-fix triage; see §1.1 audit-vocabulary-gap note).

**Companion file modified:** `test-fixtures/manifest.txt` (RC9 v11-surface manifest regen).

**Out-of-scope:** no other files touched. Audit doc unmodified. H.6/H.7 additions
unchanged (verified via diff scope).

### §1.1 Audit-vocabulary-gap note (+2 audit-gap catches)

The audit at `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` §0.1 enumerated the vocabulary scanned for leaks. That vocabulary listed `ARCHITECTURE-*` (pack-internal design docs), `AUDIT-USER-CURATION`, `maintenance-docs`, etc. — but did NOT include `RESEARCH-*` as a leak vocabulary class. As a result, the audit's §1.19 inventory of 24 architect-doc cites in the 7 per-entry skeleton files did not surface 2 sibling cites pointing at `RESEARCH-PER-ENTRY-SPLIT.md` (which lives at `maintenance-docs/v11-research/`, pack-internal, not at client install).

Initial coder pass observed these 2 leaks and surfaced them in §7.1 as out-of-scope. Pack Chat reviewed the observation at H.9 review-fix triage and decided to scope-expand H.9 to close them in the same commit (logical-fit: same-leak-class as Category A, same file set as H.9 — `changelog/_rules.md` + `changelog/_format.md`; pre-emption: H.14's planned Check 43 (basename-index class-test) would catch these and fail CI). This fix-coder pass closed both leaks per Category A (drop the cite clause; rule wording stands inline).

**Audit doc unchanged:** the audit is a snapshot of what was inventoried at scan time. The vocabulary-gap discovery is documented here in the IMPL-REPORT (the record of what was actually shipped), not retroactively in the audit. Future audits should add `RESEARCH-*` to the leak vocabulary class enumeration.

---

## §2 Edits applied

### §2.1 `project-template/docs/project/backlog/_rules.md` (Category A — 8 leaks)

| Audit line | Category | BEFORE (cite text) | AFTER (action) |
|---|---|---|---|
| 5 | A | `(updates only on pack version bump per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §3.3).` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §3.3` clause; sentence ends at `bump).` |
| 16 | A | `digit zero-padded TD-NNN per ``ARCHITECTURE-V3.3-DELTA.md`` §6.4.` | Dropped ` per ``ARCHITECTURE-V3.3-DELTA.md`` §6.4` clause; sentence ends at `TD-NNN.` |
| 21 | A | `byte-additive on the legacy monolithic per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3` clause; sentence ends at `monolithic.` |
| 23 | A | `back-pointer ABOVE the bold-header per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2;` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2` clause; clause now ends at `bold-header;` |
| 25 | A | `Grammar: ``ARCHITECTURE-V3.1-DELTA.md`` §3 A2 + ``ARCHITECTURE-V3.3-DELTA.md`` §6.4.` | Deleted the entire `Grammar:` provenance sentence (it was nothing but the cite). |
| 33 | A | `inline ``✅ RESOLVED (Phase NN)`` annotation per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3` clause; bullet ends at `annotation.` |
| 36 | A | `Project backlog uses only these two states (per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3).` | Dropped `(per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3)` parenthetical; sentence ends at `two states.` |
| 45 | A | `read this list at runtime per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §7.5.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §7.5` clause; sentence ends at `at runtime.` |

### §2.2 `project-template/docs/project/backlog/_intro.md` (Category A — 3 leaks)

| Audit line | Category | BEFORE | AFTER |
|---|---|---|---|
| 32 | A | `add the ``✅ RESOLVED (Phase NN)`` annotation to the bold-header per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3` clause; sentence ends at `bold-header.` |
| 37 | A | `identifiers may appear in ``Blockers:`` / ``Unblocks:`` / prose per ``ARCHITECTURE-V3.3-DELTA.md`` §5.3.` | Dropped ` per ``ARCHITECTURE-V3.3-DELTA.md`` §5.3` clause; sentence ends at `prose.` |
| 51 | A | `Mode 2 → Mode 3 transition contract (per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §5.6).` | Dropped `(per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §5.6)` parenthetical; sentence ends at `transition contract.` |

### §2.3 `project-template/docs/project/implementation-plan/_rules.md` (Category A — 7 leaks)

| Audit line | Category | BEFORE | AFTER |
|---|---|---|---|
| 5 | A | `(updates only on pack version bump per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §3.3).` | Same shape as §2.1/line 5 — dropped cite clause; sentence ends at `bump).` |
| 18 | A | `(no ``phase-N.M.md`` per-task files) per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`` §6.4 BD-167 spec.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`` §6.4 BD-167 spec` clause; sentence ends at `per-task files).` |
| 23 | A | `Phase epic + tasks inline per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.4: H2 phase heading ...` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.4` clause; sentence reads `Phase epic + tasks inline: H2 phase heading ...` |
| 28 | A | `back-pointer ABOVE the phase heading per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2` clause; sentence ends at `phase heading.` |
| 29 | A | `Parser contract: ``ARCHITECTURE-V3.3-DELTA.md`` §4.1.` | Deleted the `Parser contract:` provenance sentence (pure cite). |
| 33 | A | `Phase-state vocabulary per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3: pending / in-progress / ...` | Dropped ` per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3` clause; sentence reads `Phase-state vocabulary: pending / in-progress / ...` |
| 45 | A | `read this list at runtime per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §7.5.` | Same shape as §2.1/line 45 — dropped cite clause; sentence ends at `at runtime.` |

### §2.4 `project-template/docs/project/implementation-plan/_intro.md` (Category A — 2 leaks)

| Audit line | Category | BEFORE | AFTER |
|---|---|---|---|
| 42 | A | `Phase-state vocabulary is per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3: pending / in-progress / done / deferred / merged-into / superseded-by. Annotate the H2 phase heading with ... per the same reference.` | Dropped ` is per ``ARCHITECTURE-V3.3-DELTA.md`` §6.3` clause + tail ` per the same reference`. Bullet now reads `Phase-state vocabulary: pending / in-progress / done / deferred / merged-into / superseded-by. Annotate the H2 phase heading with ...` |
| 59 | A | `Mode 2 → Mode 3 transition contract (per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §5.6).` | Dropped `(per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §5.6)` parenthetical; sentence ends at `transition contract.` |

### §2.5 `project-template/docs/project/changelog/_rules.md` (Category A — 6 leaks; 5 audit-specified + 1 audit-gap)

| Audit line | Category | BEFORE | AFTER |
|---|---|---|---|
| 5 | A | `(updates only on pack version bump per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §3.3).` | Same shape — dropped cite clause; sentence ends at `bump).` |
| 19 | A | `trailing slug optional for human readability per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.5 + ``scripts/lib/per-entry/_lib.sh`` post-BD-164-retro Option B (slug optional).` | Dropped the architect-doc clause ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.5 +`; preserved the client-side `scripts/lib/per-entry/_lib.sh` reference and BD-NNN provenance (BD-NNN is AMBIGUOUS bucket, out of H.9 scope per plan H.9 + audit §1.19). Final reads `trailing slug optional for human readability per ``scripts/lib/per-entry/_lib.sh`` post-BD-164-retro Option B (slug optional).` |
| ~24 (AUDIT-GAP) | A | `Shape per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 422–448: H3 heading (...), then body fields per the Format Rules in ``_format.md``.` | Dropped ` per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 422–448` clause. Final reads `Shape: H3 heading (...), then body fields per the Format Rules in ``_format.md``.` The shape spec is the inline H3 heading description that follows; the cite was pure source-of-shape provenance. See §1.1 audit-vocabulary-gap note. |
| 30 | A | `back-pointer ABOVE the H3 heading per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2.` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`` §2` clause; sentence ends at `H3 heading.` |
| 45 | A | `read this list at runtime per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §7.5.` | Same shape — dropped cite clause; sentence ends at `at runtime.` |
| 48 | A | `(no pack analog per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.5).` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.5` clause; sentence ends at `(no pack analog).` |

### §2.6 `project-template/docs/project/changelog/_intro.md` (Category B — 1 leak)

| Audit line | Category | BEFORE | AFTER | Shape |
|---|---|---|---|---|
| 53 | B | `Mode 2 → Mode 3 transition contract (per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §5.6).` | Replaced cite with sibling `_rules.md` reference: `Mode 2 → Mode 3 transition contract (read ``docs/project/changelog/_rules.md`` § "Write authority" for the regenerated-mirror rule).` | B-1 (sibling reference) |

**Judgment-call rationale (B-1 vs B-2):** the surrounding prose describes the regenerated-mirror rule in tracker mode. The sibling `_rules.md` § "Write authority" already states the regenerated-mirror rule for the project-side mirror; pointing the reader to the sibling closes the navigational dead-end the architect-doc cite created. Shape B-1 preserves the cross-reference's navigational value at client install.

**Note on category split with `backlog/_intro.md:51` and `implementation-plan/_intro.md:59`:** those two lines carry an identical "Mode 2 → Mode 3 transition contract (per `ARCHITECTURE-*.md` §5.6)" cite, classified as Category A in the audit. The classification asymmetry is preserved per the audit + plan inventory: per the V2 architect's Cat A/B split, the two Cat A drops are clean removals while the Cat B substitution adds the sibling cite for the changelog case (potentially because changelog is the file pair with a dedicated `_format.md` whose mirror-regeneration semantics differ slightly). This decision is the audit's call; H.9 implements both shapes as specified.

### §2.7 `project-template/docs/project/changelog/_format.md` (Category B — 4 leaks + Category A — 1 audit-gap leak)

| Audit line | Category | BEFORE | AFTER | Shape |
|---|---|---|---|---|
| 5 | B | `analog (per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.5 and §11).` | Replaced cite with sibling `_rules.md` reference: `analog (see ``docs/project/changelog/_rules.md`` § "Supporting files").` | B-1 (sibling reference) |
| 7 | B | `Pack-shipped immutable: updates only on pack version bump (per ``ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`` §3.3).` | Dropped the parenthetical cite; sentence ends at `bump.` | B-2 (descriptive prose / drop) |
| ~11 (AUDIT-GAP) | A | `Each per-entry file contains one v10-grammar CHANGELOG entry. The shape (per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 411–421):` | Dropped `(per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 411–421)` parenthetical. Final reads `Each per-entry file contains one v10-grammar CHANGELOG entry. The shape:` — the code-block that follows IS the shape spec; the cite was pure source-of-shape provenance. See §1.1 audit-vocabulary-gap note. | A (drop) |
| 50 | B | `per-entry files do not contain ``---`` separators (the file boundary IS the separator per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.0).` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.0` clause; parenthetical ends at `the file boundary IS the separator).` | B-2 (drop) |
| 56 | B | `(The ``✅ RESOLVED (Phase NN)`` annotation goes in the TD entry's bold-header per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3.)` | Dropped ` per ``ARCHITECTURE-PER-ENTRY-SPLIT.md`` §3.3` clause; parenthetical ends at `bold-header.)` |  B-2 (drop) |

**Judgment-call rationale (B-1 vs B-2):**
- Line 5: sibling `_rules.md` § "Supporting files" explicitly describes `_format.md` as project-side-only-with-no-pack-analog — direct project-side analog exists; Shape B-1 used.
- Lines 7, 50, 56: the surrounding rule is stated inline; the architect-doc cite was pure provenance. Shape B-2 (drop) is cleaner than fabricating a sibling pointer where the project-side rule is already adjacent. Per plan H.9 "coder examines each line and picks B-1 or B-2 based on local prose context; both are acceptable per V2."

**Note on line numbering vs current file state:** lines 5 + 7 collapsed into a single Edit operation (the two leaks were in adjacent prose); current file state at lines 5-6 reads `analog (see ``docs/project/changelog/_rules.md`` § "Supporting files"). Pack-shipped immutable: updates only on pack version bump.` Both leaks are closed.

---

## §3 Verification

### §3.1 validate-pack.py

```
$ python3 scripts/validate-pack.py
... 42 checks ...
PASSED — all checks clean
```

All 42 checks PASS. Notable:
- **Check 37 (Project-side pack-only deny-list, BD-175 M5b):** OK — 146 project-side files walked, zero deny-list contamination. Check 37's deny-list does NOT enumerate bare `ARCHITECTURE-*.md` filenames (per ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md §3.6 Gap 1 — Check 43 is the planned mechanical class-test, due in H.14). H.9 leaks were invisible to Check 37 pre-edit and remain invisible post-edit; the validation here is a non-regression check, not a positive leak-closure detector. The boundary grep below is the affirmative closure check.

### §3.2 Fixture build

```
$ bash test-fixtures/build.sh --all --clean
... built v10-realistic-ot HEAD 4c62945f72b037908b38967d5d8f019745263258
... built v11-realistic-ot HEAD e54982e5887aaa4c3b496c271bf2d15e856617a4
... built v11-flat-file    HEAD 1bdb504e771b5edb9654d0c0b2de511a76aa0716
... built v11-tracker-on   HEAD 68ff1bb71b43a1c844fddda525d6d6c349000a61
... built existing-project-mid-dev HEAD a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
manifest written: /Users/david/.../test-fixtures/manifest.txt
```

All 6 fixtures rebuilt cleanly.

### §3.3 Manifest diff (RC9 v11-surface rule)

```
$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

3-row delta in manifest — expected (project-template/ is v11-surface; v11-* fixture HEAD SHAs drift). Manifest is left modified for Pack Chat to stage alongside the H.9 commit. NOT staged or committed (per pack memory `agents_never_commit`).

### §3.4 Boundary grep

```
$ grep -rnE "ARCHITECTURE-PER-ENTRY-SPLIT|ARCHITECTURE-V3\.[13]-DELTA|ARCHITECTURE-V3\.md|maintenance-docs/|AUDIT-USER-CURATION|RESEARCH-PER-ENTRY-SPLIT|RESEARCH-" project-template/docs/project/{backlog,implementation-plan,changelog}/{_rules,_intro,_format}.md
BOUNDARY OK — no architect/research-doc cites remain in the 7 H.9 files
```

All 32 leaks closed (30 audit-specified + 2 audit-gap catches) across the 7 H.9 files. Wider scan across `project-template/docs/project/` with the expanded RESEARCH-* vocabulary:

```
$ grep -rnE "maintenance-docs/|ARCHITECTURE-V3\.md|ARCHITECTURE-V11-|AUDIT-USER-CURATION|RESEARCH-PER-ENTRY-SPLIT|RESEARCH-" project-template/docs/project/
(no output) → BOUNDARY OK — directory clean.
```

### §3.5 File-level diff stats

```
$ git diff --stat project-template/docs/project/
 project-template/docs/project/backlog/_intro.md    |  8 +++-----
 project-template/docs/project/backlog/_rules.md    | 23 ++++++++-------------
 project-template/docs/project/changelog/_format.md | 13 +++++-------
 project-template/docs/project/changelog/_intro.md  |  3 ++-
 project-template/docs/project/changelog/_rules.md  | 19 +++++++----------
 .../docs/project/implementation-plan/_intro.md     | 11 +++++-----
 .../docs/project/implementation-plan/_rules.md     | 24 ++++++++--------------
 7 files changed, 39 insertions(+), 62 deletions(-)
```

Exactly 7 files modified — matches PLAN H.9 spec + 2 audit-gap catches (concentrated in `changelog/_rules.md` and `changelog/_format.md`; net delta in those two files grew by +2 dropped-cite lines vs. the pre-audit-gap-catch state). Net -23 lines across all 7 files (cite clauses removed). No other project-template/ files touched.

### §3.6 Full diff stat (scope confirmation)

```
$ git diff --stat
 project-template/docs/project/backlog/_intro.md    |  8 +++-----
 project-template/docs/project/backlog/_rules.md    | 23 ++++++++-------------
 project-template/docs/project/changelog/_format.md | 13 +++++-------
 project-template/docs/project/changelog/_intro.md  |  3 ++-
 project-template/docs/project/changelog/_rules.md  | 19 +++++++----------
 .../docs/project/implementation-plan/_intro.md     | 11 +++++-----
 .../docs/project/implementation-plan/_rules.md     | 24 ++++++++--------------
 test-fixtures/manifest.txt                         |  6 +++---
 8 files changed, 42 insertions(+), 65 deletions(-)
```

8 files changed total: 7 H.9 scope files + manifest. No out-of-scope edits.

---

## §4 Cross-references

- **ARCHITECTURE-CLEANUP-BATCH-19C-V2.md §H.9** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` line 1137+) — commit scoping. H.9 ABSORBS Categories A + B per Option (b) sequencing decision.
- **PLAN-CLEANUP-BATCH-19C.md H.9** (`maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` line 360+) — implementation spec (files, lines, BEFORE/AFTER patterns, verification command list, RC9 manifest regen, PREFLIGHT shape).
- **AUDIT-PRE-19C-BOUNDARY-LEAKS.md §1.19** (`maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` line 352+) — authoritative leak inventory with file/line classification.
- **ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md §1.1-§1.2** (`maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` line 18+) — Cat A + Cat B fix-shape definitions; Shape B-1 (sibling reference) vs Shape B-2 (descriptive prose) substitution guidance.
- **Pack memory `RC9 manifest regen on v11-surface commits`** (pack-root `CLAUDE.md` § Pack memory) — manifest regen required for v11-surface diff; manifest left modified per `agents_never_commit`.

---

## §5 Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | All 30 Category A + B leaks closed across the 7 named files per AUDIT-PRE-19C-BOUNDARY-LEAKS.md spec | PASS — 32/32 = 30 audit-specified (25 Cat A + 5 Cat B) + 2 audit-gap catches (both Cat A); verified via §3.4 boundary grep with expanded RESEARCH-* vocabulary |
| 2 | No new leaks introduced (boundary grep returns "BOUNDARY OK") | PASS — `BOUNDARY OK — no architect/research-doc cites remain in the 7 H.9 files` (RESEARCH-* added to grep vocabulary post-audit-gap-discovery) |
| 3 | Surrounding rule wording preserved (Cat A: rule intelligible without cite; Cat B: substitution reads cleanly) | PASS — verified per §2 BEFORE/AFTER table; rules read cleanly post-edit. Spot-checked all 7 files via re-Read after final edits. |
| 4 | `python3 scripts/validate-pack.py` PASS | PASS — all 42 checks clean |
| 5 | Manifest v11-* row drift | PASS — 3 v11-* row deltas (v11-realistic-ot, v11-flat-file, v11-tracker-on HEADs); manifest left modified for Pack Chat staging |
| 6 | IMPL-REPORT at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.md` | PASS — this file |

---

## §6 Out-of-scope confirmations

- **Only 7 named files touched** (plus manifest regen).
- **H.6 / H.7 additions unchanged.** Did not touch `project-template/docs/pack/PM-CHAT.md` (H.7 surface), `supporting-docs/METHODOLOGY.md` (H.6 surface), or any other H.0-H.7 surface. Per §3.6 diff stat, only the 7 H.9 files + manifest carry changes.
- **Audit doc not modified.** `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` is the source of truth for the leak inventory; left untouched.
- **No git state-changing operations.** No `git add`, `git commit`, `git push`, `git mv`, `git rm`, `git reset`, `git checkout -- <path>`, `git restore`. Only read-only verbs (`git rev-parse`, `git status`, `git diff`).
- **Manifest left modified (NOT staged).** Per pack memory `agents_never_commit`, Pack Chat will stage and commit.

---

## §7 Open questions / deferrals

### §7.1 RESEARCH-PER-ENTRY-SPLIT.md cites — CLOSED (audit-gap scope-expand)

**Initial observation (resolved):** the initial H.9 coder pass identified 2 cites in the 7 H.9 files that reference `RESEARCH-PER-ENTRY-SPLIT.md` (lives at `maintenance-docs/v11-research/`, pack-internal, not at client install):

- `project-template/docs/project/changelog/_rules.md` line ~24: `Shape per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 422–448`
- `project-template/docs/project/changelog/_format.md` line ~11: `shape (per ``RESEARCH-PER-ENTRY-SPLIT.md`` §3 lines 411–421)`

Both were NOT in the audit's §1.19 inventory because audit §0.1 vocabulary did not include `RESEARCH-*` as a leak class (only `ARCHITECTURE-PER-ENTRY-SPLIT*`, `ARCHITECTURE-V3.1-DELTA`, `ARCHITECTURE-V3.3-DELTA`, `AUDIT-USER-CURATION`, `maintenance-docs`, etc.). The strategy doc §1.7 note acknowledges "the audit's 36-leak total counts 24 per-entry-tree leaks (audit §1.19); Categories A + B above account for 25 + 5 = 30 per-entry-tree leaks across 7 files. The discrepancy is one of cite-counting (the audit grouped some adjacent cites; my by-fix-shape split unpacks them)." These 2 `RESEARCH-*` cites were NOT part of either count — they were a separate class the audit's vocabulary missed.

**Pack Chat triage decision (closed):** Pack Chat scope-expanded H.9 to absorb the 2 audit-gap leaks in the same commit, per:
- **Logical fit (FIT):** same file set as H.9 (`changelog/_rules.md` + `changelog/_format.md`); same leak class (project-side cite of a pack-internal `maintenance-docs/v11-research/` doc); same fix shape (Cat A — drop cite clause).
- **Size (SIZE):** trivially small (2 cite-clause drops, 1 line each).
- **Unblocked (BLOCKED):** no dependency on any pending work.
- **Pre-emption of Check 43 (H.14):** the planned basename-index scanner at H.14 catches `RESEARCH-*` class refs since they resolve to `maintenance-docs/v11-research/` targets. Leaving them in would fail CI at H.14 and require a separate fix-coder pass. Absorbing them in H.9 keeps H.14 green.

**Fix-coder pass (this report):** both cites closed per Category A — drop the cite clause. The shape spec is inline (the H3 heading description in `_rules.md`; the fenced code-block in `_format.md`), so the rules read cleanly without the source-of-shape attribution. See §2.5 (`changelog/_rules.md` line ~24) and §2.7 (`changelog/_format.md` line ~11) BEFORE/AFTER rows. Total H.9 leak count revised from 30/30 to **32/32 = 30 audit-specified + 2 audit-gap catches**.

**Implication for future audits:** the audit-vocabulary class enumeration at AUDIT-PRE-19C-BOUNDARY-LEAKS.md §0.1 should be extended to include `RESEARCH-*` as a leak vocabulary class in any subsequent boundary-scan. The audit itself is left unmodified per "audit is a snapshot" convention; the gap is documented here in the IMPL-REPORT (the record of what was actually shipped) and should propagate to future audit scope via Check 43's class-test (H.14) — Check 43 catches by basename-index resolution, not by enumerated vocabulary, so it is robust against this class of audit-vocabulary gap.

### §7.2 Observation — Cat A vs Cat B asymmetry at parallel sites

`backlog/_intro.md:51`, `implementation-plan/_intro.md:59`, and `changelog/_intro.md:53` all carry the same `(per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.6)` cite in identical Mode 2 → Mode 3 prose context. The audit + strategy classify the first two as Cat A (drop) and the third as Cat B (substitute). I implemented the asymmetry per spec (drop both Cat A instances cleanly; add sibling `_rules.md` reference to the Cat B instance). Reading the resulting prose post-edit, the asymmetry is slightly visible — the changelog case has a "(read `docs/project/changelog/_rules.md` § 'Write authority' ...)" tail that the backlog and implementation-plan cases lack.

**Possible drivers of the asymmetry (architect-call, not coder-call):** the changelog `_intro.md` is the only one with a sibling `_format.md`, which arguably warrants the additional sibling reference; the backlog and implementation-plan trees do not have `_format.md` so a sibling reference there would be less natural. This is consistent with the strategy doc §1.2's "the cited content has a clean project-side analog already present in sibling skeleton files" framing.

No remediation needed; flagging as an observation for the inline reviewer pass (per plan H.9 reviewer focus dimension "Each cite correctly dropped OR replaced. Verify each of the 30 cites named in audit §1.19 has been remediated").

### §7.3 No plan deviations (scope-expand authorized by Pack Chat)

Zero deviations from the PLAN H.9 spec for the 30 audit-specified cites. Every line in audit §1.19 / strategy §1.1+§1.2 was located, matched its expected BEFORE text, and was edited per the categorical fix-shape (Cat A: drop clause; Cat B: substitute with sibling reference or descriptive prose).

The 2 RESEARCH-* audit-gap catches in §7.1 are NOT plan deviations — they are an authorized scope-expand of H.9 by Pack Chat triage at the H.9 review-fix gate. The expansion fits the SIZE/BLOCKED/FIT criteria of `feedback-deferral-is-scope-creep` and pre-empts a Check 43 (H.14) CI failure. See §1.1 audit-vocabulary-gap note and §7.1 closed-disposition.

### §7.4 No new POQs introduced

The asymmetry in §7.2 and the audit-coverage gap in §7.1 are observations within the existing v11 boundary-cleanup scope, not new POQs. The audit-vocabulary-gap implication (future audits should include `RESEARCH-*`) is captured in §7.1 and is mitigated by H.14's Check 43 class-test design.

---

## §8 Files changed inventory

| Path | Change | Type |
|---|---|---|
| `project-template/docs/project/backlog/_rules.md` | modified | Category A — 8 cite-drops |
| `project-template/docs/project/backlog/_intro.md` | modified | Category A — 3 cite-drops |
| `project-template/docs/project/implementation-plan/_rules.md` | modified | Category A — 7 cite-drops |
| `project-template/docs/project/implementation-plan/_intro.md` | modified | Category A — 2 cite-drops |
| `project-template/docs/project/changelog/_rules.md` | modified | Category A — 6 cite-drops (5 audit-specified + 1 audit-gap RESEARCH-*) |
| `project-template/docs/project/changelog/_intro.md` | modified | Category B — 1 sibling-reference substitution (Shape B-1) |
| `project-template/docs/project/changelog/_format.md` | modified | Category B — 1 sibling-reference (Shape B-1) + 3 cite-drops (Shape B-2) + Category A — 1 audit-gap cite-drop (RESEARCH-*) |
| `test-fixtures/manifest.txt` | modified | RC9 manifest regen (3 v11-* row deltas) — left modified for Pack Chat to stage |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.md` | created | This file |

Total: **9 paths touched** (7 H.9 in-scope + 1 manifest + 1 IMPL-REPORT). No deletions, no renames.

---

## §9 Boundary discipline check (P-missed-7 pre-flight)

Per pack-coder boundary discipline pre-flight (P-missed-7 / `boundary-investigation` skill), the H.9 edits touch the project-side surface (`project-template/docs/project/` per-entry skeleton files) — they are CLIENT-installed via `scripts/init-project.sh` stages S1-S11.

**SSOT investigation for each project-side edit:** the per-entry contract is defined in the project-side skeleton files themselves (`_rules.md` + `_intro.md` + `_format.md` per stream). The fixes preserve the project-side SSOT (the rules stay; only the architect-doc provenance cites drop) — no edits IMPORT pack-only mechanisms into project-side files.

**No pack-only references added.** Verified per §3.4 boundary grep. The 1 sibling-reference substitution in `changelog/_intro.md:53` and the 1 in `changelog/_format.md:5` BOTH point at sibling client-installed files (`docs/project/changelog/_rules.md` § "Write authority" and § "Supporting files" respectively) — these resolve at client install.

**No new POQs surfaced.** The Cat B substitutions reuse existing project-side concepts (sibling `_rules.md`) without inventing new project-side mechanisms.

This pre-flight is clean — no boundary discipline stops triggered.

---

## §10 Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | Pre-flight checks: `git rev-parse HEAD` matches `c8d61ee` per caller context | PASS — `c8d61ee44d22990f34d6374d3726e6c88e3ca3a6` |
| 2 | Pre-flight checks: `git status` clean before edits | PASS — `working tree clean` at session start |
| 3 | All 30 Category A + B leaks closed per audit + plan spec, PLUS 2 audit-gap RESEARCH-* catches absorbed via Pack Chat scope-expand | PASS — 32/32 closed; §1 + §1.1 + §2 + §3.4 |
| 4 | Each Cat A: cite clause dropped, surrounding rule preserved | PASS — §2.1-§2.5 BEFORE/AFTER table (including the 1 audit-gap Cat A drop in §2.5 and the 1 in §2.7) |
| 5 | Each Cat B: cite substituted with sibling reference or descriptive prose | PASS — §2.6 + §2.7 + Shape B-1/B-2 rationale |
| 6 | No new leaks introduced (boundary grep clean) | PASS — §3.4 BOUNDARY OK |
| 7 | `python3 scripts/validate-pack.py` PASS | PASS — §3.1 all 42 checks clean |
| 8 | `bash test-fixtures/build.sh --all --clean` PASS | PASS — §3.2 all 6 fixtures rebuilt |
| 9 | `git diff --stat test-fixtures/manifest.txt` shows v11-surface drift | PASS — §3.3 3-row delta |
| 10 | Out-of-scope files NOT touched | PASS — §3.6 full diff stat confirms 7 H.9 + manifest only |
| 11 | Audit doc NOT modified | PASS — §6 (verified via diff stat absence) |
| 12 | No git state-changing operations | PASS — §6 |
| 13 | Trinity rule applies? | N/A — H.9 does not touch CLAUDE.md / AGENTS.md / GEMINI.md or pack-template trinity files |
| 14 | Filename uniqueness verified for any new file | PASS — IMPL-REPORT name follows pack convention `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.md`; basename unique under `maintenance-docs/v11-implementation/` |
| 15 | PREFLIGHT line emitted before IMPL-REPORT write | PASS — emitted prior to this Write |
| 16 | IMPL-REPORT chunked if >300 lines | PASS — single Write under 300-line threshold; no Edit-append needed |

All DoD items PASS.

---

**End of IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.**
