# IMPLEMENTATION-REPORT-BD-175-COMMIT-9A

**Commit:** 9a of BD-175 Phase 5
**Task:** TASK-T5 MERGE-STRATEGY V5 PRIMARY audience header (Path A split)
**Worktree HEAD (pre-edit):** `21c134443aab09d00895b410e6587ce8d37f615d`
**Worktree HEAD (post-edit):** `21c134443aab09d00895b410e6587ce8d37f615d` (no commit, per pack-coder contract)
**Branch:** `v11-dev`
**Parallel batch:** ALPHA-EXPANDED (6 sibling coders, disjoint file sets)

---

## §1 Summary

V5 PRIMARY audience header added to `pack-ops/MERGE-STRATEGY.md` per
ARCHITECTURE-RE-LITIGATION-FRAMEWORK §2 V5 PRIMARY + PLAN-BD-175-PHASE-5 §2.9a.

The header (5-line blockquote callout inserted between L1 title and L3
"When …" paragraph) designates the document as pack-internal reference for
pack maintainers running the migrator. Under this PRIMARY framing,
pre-existing references to `HELP-FRAGMENT-PACK.md` (was L472, now L479) and
pack-shipped agent files (was L189, now L196) become unambiguously
LEGITIMATE — they are pack-internal refs in a pack-internal doc at a
pack-only path (`pack-ops/`). No edits required at those anchors.

The bare `OPTIONAL-FEATURES.md` reference (was L465, now L472) is
UNCHANGED in this commit per the Path A split. Commit 9b (sequential,
AFTER Commit 10) will update that reference after Commit 10 creates the
project-side `OPTIONAL-FEATURES.md`.

**File scope:** EXACTLY 1 file — `pack-ops/MERGE-STRATEGY.md`.
**Manifest regen:** NOT required (pack-ops/ is not v11-surface per RC9).

---

## §2 Audience header BEFORE / AFTER

### BEFORE (L1-L4 pre-edit)

```
# MERGE-STRATEGY.md — per-file customization preservation contract

When `init-project.sh --update` (BD-080) or `migrate-v10-to-v11.sh` (BD-085)
refresh a project to a newer pack version, every file the migrator touches
```

### AFTER (L1-L11 post-edit)

```
# MERGE-STRATEGY.md — per-file customization preservation contract

> **Audience: pack-internal.** This document is pack-internal reference
> for pack maintainers running the migrator. Project users encounter
> the per-class disposition tokens via the `report.md` produced by the
> migrator; they do not read this file directly. References here to
> other pack-internal docs (e.g., `HELP-FRAGMENT-PACK.md`) and
> pack-shipped agent files are appropriate at this pack-only path.

When `init-project.sh --update` (BD-080) or `migrate-v10-to-v11.sh` (BD-085)
refresh a project to a newer pack version, every file the migrator touches
```

**Net insert:** +7 lines (5-line blockquote + 1 blank-line gap inside the
new block area + 1 blank line before "When …"). All downstream content
shifts +7 with no reflow.

**Wording rationale (A's intent preserved):**

- Names "pack-internal" explicitly as the audience designation.
- Identifies `report.md` (migrator output) as the user-facing surface —
  not this doc.
- Pre-emptively annotates the LEGITIMATE-under-PRIMARY anchors
  (`HELP-FRAGMENT-PACK.md`, pack-shipped agent files) so a reader
  encountering them at L196 / L479 is not confused by what would
  otherwise look like dangling internal refs.

---

## §3 L189 + L465 + L472 verification (pre-edit anchors)

Line numbers shifted +7 by audience-header insertion. Anchors verified
present + content unchanged at post-edit positions:

| Anchor (plan ref) | Pre-edit line | Post-edit line | Content | Disposition |
|---|---|---|---|---|
| A1 (pack-shipped agent files) | L189 | **L196** | `Pack-shipped agent files (e.g., 'pack-architect.md', 'pack-reviewer.md').` | UNCHANGED — LEGITIMATE under PRIMARY |
| D8.6 (OPTIONAL-FEATURES bare ref) | L465 | **L472** | `- 'OPTIONAL-FEATURES.md' — tracker opt-in walkthrough` | UNCHANGED — reserved for Commit 9b (Path A split) |
| D7.1 (HELP-FRAGMENT-PACK ref inside lib/ Note blockquote) | L472 | **L479** | `> 'HELP-FRAGMENT-PACK.md' and 'validate-pack.py' Check 22 skips` | UNCHANGED — LEGITIMATE under PRIMARY |

All three anchors confirmed present via `grep -n` (see §4 verification log).

---

## §4 Verification results

### V1 — Audience header present at top

Command: `head -25 pack-ops/MERGE-STRATEGY.md`

Result: PASS. Output shows title (L1), blank line (L2), 6-line blockquote
audience header (L3-L8), blank line (L9), and the "When `init-project.sh
--update`…" introductory paragraph starting at L10. Header wording matches
the AFTER block shown in §2.

### V2 — L465 OPTIONAL-FEATURES reference unchanged

Command: `grep -n "OPTIONAL-FEATURES" pack-ops/MERGE-STRATEGY.md`

Result: PASS. Single match at L472 (post-edit position; pre-edit L465 + 7
shift): `- OPTIONAL-FEATURES.md — tracker opt-in walkthrough`. Bare text
preserved; D8.6 update territory untouched per Path A.

### V3 — Spot-check L189 + L472 unchanged

Command: `grep -n "Pack-shipped agent files\|HELP-FRAGMENT-PACK" pack-ops/MERGE-STRATEGY.md`

Result: PASS. Three matches:
- L7 (inside the new audience header, anticipates the anchor)
- L196 (pre-edit L189 + 7): `Pack-shipped agent files (e.g., 'pack-architect.md', 'pack-reviewer.md').`
- L479 (pre-edit L472 + 7): `> 'HELP-FRAGMENT-PACK.md' and 'validate-pack.py' Check 22 skips`

Both pre-existing anchors content-identical to pre-edit; only the
header-introduced reference at L7 is new (expected per audience-header
content design).

### V4 — Manifest regen check

NOT applicable. `pack-ops/` is not under `project-template/` or
`scripts/`, so RC9 v11-surface trigger does not fire. No manifest
regeneration required.

### V5 — Out-of-scope drift check

In-scope file diff is the only change to `pack-ops/MERGE-STRATEGY.md`
from this coder. Other working-tree modifications visible in `git
status` (project-template/AGENTS.md, project-template/CLAUDE.md,
project-template/docs/pack/PLATFORM-SKILLS.md,
project-template/skills/audit-methodology/SKILL.md) belong to sibling
coders in the ALPHA-EXPANDED parallel batch — expected per the parallel-
batch disjoint-file-sets contract. This coder did not touch any of them.

---

## §5 Plan deviations

NONE. Edits track PLAN-BD-175-PHASE-5 §2.9a + ARCHITECTURE-RE-
LITIGATION-FRAMEWORK §2 V5 PRIMARY exactly:

- Path A split honored: audience header only; L465 D8.6 ref left untouched
  for Commit 9b (post-Commit 10).
- L189 A1 + L472 D7.1 anchors confirmed present and unchanged
  (LEGITIMATE under PRIMARY).
- File scope: 1 file (`pack-ops/MERGE-STRATEGY.md`) — matches plan.
- No manifest regen (pack-ops/ not v11-surface).
- No state-changing git verbs run; no out-of-scope edits.
- New POQs introduced: NONE.

---

## §6 PREFLIGHT line

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 21c134443aab09d00895b410e6587ce8d37f615d; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9A.md
```

---

## Files changed inventory

| Path | Change type | Lines added | Lines removed |
|---|---|---|---|
| `pack-ops/MERGE-STRATEGY.md` | modified | +7 | 0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9A.md` | new (report) | (this file) | — |

---

## Definition-of-Done checklist

- [PASS] Audience header inserted at top of `pack-ops/MERGE-STRATEGY.md` (5-line blockquote, A's intent preserved).
- [PASS] L465 D8.6 bare `OPTIONAL-FEATURES.md` ref UNCHANGED (Path A split honored; deferred to Commit 9b).
- [PASS] L189 A1 anchor (pack-shipped agent files) present + unchanged.
- [PASS] L472 D7.1 anchor (`HELP-FRAGMENT-PACK.md` in lib/ Note) present + unchanged.
- [PASS] No out-of-scope file edits (sibling-coder edits in `git status` are theirs, not this coder's).
- [PASS] No manifest regen (pack-ops/ not v11-surface per RC9).
- [PASS] No state-changing git verbs run.
- [PASS] Zero plan deviations.
- [PASS] Zero new POQs.
- [PASS] PREFLIGHT line emitted before IMPL-REPORT Write.
