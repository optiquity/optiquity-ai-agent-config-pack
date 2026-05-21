# IMPLEMENTATION REPORT — Architecture Directory Reorganization B-fix EXTENSION

**Agent:** Architect B fix-pass-extension (BD-175 Phase 3 fix-pass)
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD at session open:** `8014186`
**Target doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`
**Source review:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md` — findings M3, S3, N2

## Scope confirmation

This extension addresses 3 of the 15 reviewer findings, specifically those triaged to "Architect B fix-pass extension":
- **M3 (MUST)** — combined with **Override 10** per AUDIT-USER-CURATION.md
- **S3 (SHOULD)** — combined with **Override 8** per AUDIT-USER-CURATION.md
- **N2 (NIT)** — count-agnostic verification phrasing

All amendments extend the existing B-fix doc IN PLACE; no new architecture doc was created. Original B-fix content (§1-§11) is untouched except for one line-level N2 edit at §10.4 step 1.

---

## §1 — M3 (MUST) — what I changed and how it satisfies reviewer fix shape + Override 7 + Override 10

### Reviewer fix shape (M3)

Per PACK-REVIEW-PHASE-2-DESIGNS.md M3 (lines 108-124):
- B-fix extension amends B-original §4.4 / §6.2 (drop S1) / §6.4 step 5 / §8 (drop project-side QUICKSTART entry) per Override 7
- Drop the `surfaces["project-template"]["docs"]` addition from `validate-pack.py` Check 22 (which B's §4.4 mentioned adding)
- Override 10 modifier: design wording-removal for the 4 help files (5 references total)

### What I added: B-fix-extended §12

A new top-level section `## §12 — Phase 3 fix-pass extension (M3 / Override 7 + Override 10)` was appended to B-fix. It contains:

- **§12 frontmatter:** Authority block citing Override 7 (QUICKSTART STAYS, no SPLIT) + Override 10 (REMOVE refs from 4 help files).
- **§12.1:** Amends B-original §4.4 — entirely REPLACES the SPLIT design with a KEEP-AT-ROOT resolution. Specifies: no SPLIT, no project-side QUICKSTART, no `init-project.sh` stage; pack-only refs unchanged; project-side refs designed in §12.4; `validate-pack.py:230` + `:1655` unchanged; `surfaces["project-template"]["docs"]` addition explicitly DROPPED.
- **§12.2:** Amends B-original §6.2 (SPLIT table) — DELETES the S1 row; preserves S2 row with conditional qualifier lifted per Override 8.
- **§12.3:** Amends B-original §6.4 step 5 — DELETES the S1 commit; collapses sequence by one commit; provides updated 4-commit sequence (Commits A-D) integrated with B-fix §7.1 Option A.
- **§12.4:** Designs the per-file wording-removal for the 4 help files (Override 10). See §1.b below for the detailed before/after wording.
- **§12.5:** Trinity rule compliance — the 3 CLI-parallel pack-help skill files (`.gemini/commands/pack-help.toml`, `.claude/.../SKILL.md`, `.codex/.../SKILL.md`) edited in lockstep; `HELP-FRAGMENT.md` joins the same commit for cohesion.
- **§12.6:** Amends B-original §8 (final-state directory tree) — DELETES the `QUICKSTART.md (NEW ...)` row from the `project-template/docs/pack/` block; lifts S2 conditional qualifier on the `OPTIONAL-FEATURES.md` row.
- **§12.7:** Net-effect summary for Phase 5 coder; Override 7 + Override 10 citations explicit.

### §1.a — How §12 satisfies M3

- B's §4.4 SPLIT design → replaced with KEEP-AT-ROOT (Override 7 cited).
- B's §6.2 S1 row → deleted (no SPLIT commit).
- B's §6.4 step 5 S1 commit → deleted (commit sequence collapses).
- B's §8 tree project-side QUICKSTART entry → deleted.
- `validate-pack.py` Check 22 `surfaces["project-template"]["docs"]` addition → explicitly DROPPED (§12.1).
- B-fix §6.6 line 1655 stays at `REPO_ROOT / "QUICKSTART.md"` (already confirmed unchanged in B-fix).

### §1.b — Override 10 wording-removal design (4 files, 5 references)

#### File 1 of 4 — `project-template/.gemini/commands/pack-help.toml` (1 reference, line 10)

**Before (lines 10-12 of the file):**

```
For full documentation, see docs/pack/QUICKSTART.md,
docs/pack/PM-CHAT.md, docs/pack/INSTALL-PROCEDURES.md, and
docs/pack/OPTIONAL-FEATURES.md.
```

**After:**

```
For full documentation, see docs/pack/PM-CHAT.md,
docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md.
```

**Edit:** Delete `docs/pack/QUICKSTART.md, ` from the start of the list; rewrap. List shortens from 4 items to 3.

#### File 2 of 4 — `project-template/.claude/skills/pack-help/SKILL.md` (1 reference, line 13)

**Before (lines 13-16 of the file):**

```
For full documentation, see `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, and
`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`
(LCD floor) prints the same content as this skill.
```

**After:**

```
For full documentation, see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
The shell verb `pack help` (LCD floor) prints the same content as this skill.
```

**Edit:** Delete the `` `docs/pack/QUICKSTART.md`, `` token; rewrap.

#### File 3 of 4 — `project-template/.codex/skills/pack-help/SKILL.md` (1 reference, line 13)

**Before:** Byte-identical to File 2.
**After:** Byte-identical to File 2 amended version.
**Edit:** Apply lockstep with File 2 per trinity rule (Claude + Codex parity for pack-help skill).

#### File 4 of 4 — `project-template/docs/pack/HELP-FRAGMENT.md` (2 references, lines 4 + 31)

**Reference 1 of 2 — front-matter sentence (lines 4-6):**

**Before:**

```
Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`,
`docs/pack/OPTIONAL-FEATURES.md`.
```

**After:**

```
Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.
```

**Reference 2 of 2 — See-also section (lines 31-33):**

**Before:**

```
## See also

`docs/pack/QUICKSTART.md`, `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md`, `docs/pack/PLATFORM-SKILLS.md`,
`docs/pack/OPTIONAL-FEATURES.md`, `docs/project/BACKLOG.md`.
```

**After:**

```
## See also

`docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`,
`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
`docs/project/BACKLOG.md`.
```

**Edit:** Delete the `` `docs/pack/QUICKSTART.md`, `` token from line 31; rewrap.

**Note:** The `docs/project/BACKLOG.md` reference on the final line is to the PROJECT-side BACKLOG (client repo's `docs/project/BACKLOG.md`), NOT the pack-side mirror that B-fix M9 moves. UNAFFECTED.

### §1.c — Trinity compliance

The three CLI-parallel files (Files 1-3 above: `.gemini/commands/pack-help.toml`, `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`) constitute a trinity for the pack-help skill. Per pack-memory trinity rule, all three edits land in the same commit. File 4 (`HELP-FRAGMENT.md`) is not trinity-parallel by name but lives in the same project-side help surface; it joins the same commit for cohesion per §12.5 of B-fix-extended.

---

## §2 — S3 (SHOULD) — content-split sketch I added and how it satisfies reviewer fix shape + Override 8

### Reviewer fix shape (S3)

Per PACK-REVIEW-PHASE-2-DESIGNS.md S3 (lines 185-198): "Extend B's §4.5 with a content-split sketch: which sections of current `OPTIONAL-FEATURES.md` stay pack-only vs ship as project-side feature catalog. 5-10 line outline is sufficient. Honor Override 8: not byte-identical mirror; tailored per audience."

### What I added: B-fix-extended §13

A new top-level section `## §13 — Phase 3 fix-pass extension (S3 OPTIONAL-FEATURES.md content-split sketch)` was appended. It contains:

- **§13 frontmatter:** Override 8 citation ("CONFIRMED SPLIT"; common-to-both content acceptable; per-audience tailoring).
- **§13.1:** Inventory of current `OPTIONAL-FEATURES.md` sections (6 sections: intro, Agent Teams, Codex placeholder, Gemini placeholder, Tracker integration, Adding new entries).
- **§13.2:** Audience analysis — pack-side audience (pack maintainers, Pack Chat, pack agents, pack contributors) vs project-side audience (project PM chats, project developers, project agents).
- **§13.3:** **The content-split sketch (the 5-10 line outline the reviewer asked for).** Section-by-section classification table with: section name | pack-side (`pack-ops/`) verdict | project-side (`project-template/docs/pack/`) verdict | audience-tailoring notes. Covers all 6 current sections plus tracker subsections (pack-surface vs project-surface vs MERGE-STRATEGY reference vs plumbing details).
- **§13.4:** Phase 5 coder guidance — 5 concrete steps for executing the S2 commit (git mv pack-side; create project-side file from template; init-project.sh install stage; 5 project-side reference resolution; no byte-identity contract).
- **§13.5:** TYPE-2 contamination avoidance — explicitly names what NOT to copy (pack-tracker plumbing details; pack-self surface mentions; unqualified `pack-ops/` path references). This is the "starting structure to avoid TYPE-2 contamination during the split itself" the reviewer asked for.
- **§13.6:** Override 8 citation explicit.

### §2.a — The 5-10 line content-split sketch (extracted)

Per the reviewer's "5-10 line outline is sufficient" criterion, the operative table at §13.3 provides 9 rows covering the section split decisions:

| Section | Pack-side | Project-side | Notes |
|---|---|---|---|
| Intro paragraphs | KEEP (pack-maintainer voice) | ADAPT (project-PM voice) | Common topic; different voice |
| Claude Code Agent Teams | KEEP FULL (pack-self use case) | ADAPT (project-side agent paths, project use cases) | Common topic; different paths |
| Codex CLI placeholder | KEEP | KEEP | Common-to-both stub |
| Gemini CLI placeholder | KEEP | KEEP | Common-to-both stub |
| Tracker integration — pack surface | KEEP FULL (pack-repo CWD, pack-side example, pack signals) | DROP pack-self-specific subsections | Pack-only mechanism |
| Tracker integration — project surface | (narrated; no duplicate how-to) | KEEP FULL (client CWD, client `tracker.toml.example`, project signals, client failure modes) | Project-only mechanism |
| Tracker — MERGE-STRATEGY reference | KEEP (`pack-ops/MERGE-STRATEGY.md`) | KEEP (same pointer with "in the pack repo" qualifier) | Pack-only mechanism doc |
| Pack-tracker plumbing (Check 22, STREAMS, per-entry contract) | KEEP | OMIT entirely | Pack-internal; TYPE-2 risk if copied |
| Adding new entries | KEEP | KEEP-OR-ADAPT (project shape contract) | Common shape contract |

### §2.b — How §13 satisfies S3

- 5-10 line outline → DELIVERED as 9-row classification table (slightly more than the ask, but within "sketch" scope; each row is one decision).
- Names which sections stay pack-only (plumbing details) → covered by row 8 (OMIT entirely from project-side).
- Names which sections ship as project-side feature catalog (tracker opt-in instructions for project PM chats) → covered by row 6 (project-surface tracker section KEEP FULL on project-side).
- Honors Override 8 (common-to-both OK; tailored per audience) → operationalized in classification: ADAPT rows (intro, Agent Teams) explicitly call out common-topic-different-voice; KEEP rows (placeholders) explicitly common-to-both.

---

## §3 — N2 (NIT) — line-level change

### Reviewer fix shape (N2)

Per PACK-REVIEW-PHASE-2-DESIGNS.md N2 (lines 269-275): "Replace 'all 33 checks pass' with 'all currently-enabled checks pass' — count-agnostic."

### What I changed

**Target line:** B-fix §10.4 step 1, line 536 of `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`.

**Before:**

```
1. `bash scripts/validate-pack.py` — all 33 checks pass. Check 3, Check 22, Check 24, Check 32, Check 35 all touch the relocated paths; any failure here means a constant was missed.
```

**After:**

```
1. `bash scripts/validate-pack.py` — all currently-enabled checks pass. Check 3, Check 22, Check 24, Check 32, Check 35 all touch the relocated paths; any failure here means a constant was missed.
```

**Edit:** In-place replacement of "all 33 checks pass" with "all currently-enabled checks pass". Check-name references (Check 3 / 22 / 24 / 32 / 35) preserved as stable identifiers (not check counts).

### How this satisfies N2

The phrasing is now count-agnostic. Whether validate-pack.py at Phase 5 execution time has 33 checks (pre-C-fix) or 36+ (post-C-fix landing first), the assertion holds without maintenance. A new `## §14 — Phase 3 fix-pass extension (N2 count-agnostic verification phrasing)` section was added documenting the change, its authority, and a cross-reference note confirming this is the only count-hardcoded location.

---

## §4 — Confirmation that existing B-fix content is untouched

**Verification method:** I diffed `head -565` of the post-extension file against the pre-extension backup at `/tmp/B-fix-pre-extension-backup.md`. The ONLY diff in the first 565 lines is the N2 line-level edit at line 536 (the inline N2 fix per §3 above). All other content of §1-§11 of B-fix is byte-identical to pre-extension.

**Specific verification:**
- B-fix §1-§9 untouched (line ranges 1-444).
- B-fix §10 (Phase 5 coder guidance) untouched EXCEPT §10.4 step 1 (line 536) which received the inline N2 fix.
- B-fix §11 (Summary) untouched (lines 553-565). This summary's closing paragraph ("M1-M8 + S1-S2 relocations") was written when S1 was still in scope; my §15 (final summary of the extension) explicitly notes this displacement.

**New content:** §12 (lines 570-836), §13 (lines 837-915), §14 (lines 916-930), §15 (lines 932-940). All extensions appended at the end; no interleaving with existing content.

**Final line count:** 940 lines (was 565 pre-extension). Net additions: 375 lines (~+66%).

**Section header sanity check:**

```
16:## §1 — Scope and non-scope
445:## §10 — Phase 5 coder guidance (concrete)
553:## §11 — Summary
570:## §12 — Phase 3 fix-pass extension (M3 / Override 7 + Override 10)
837:## §13 — Phase 3 fix-pass extension (S3 OPTIONAL-FEATURES.md content-split sketch)
916:## §14 — Phase 3 fix-pass extension (N2 count-agnostic verification phrasing)
932:## §15 — Summary of B-fix extension
```

Sequential numbering preserved; no duplicate §N. (The new sections were initially appended as §11-§14 which collided with the existing §11 Summary; renumbered to §12-§15 to preserve unique-N ordering.)

---

## §5 — Phase 5 coder readiness

Per the success criterion "Phase 5 coder reading B-fix-extended can apply changes mechanically without additional judgment":

- **M3:** §12.1-§12.6 enumerate each amendment to B-original by section reference, with explicit BEFORE/AFTER for table rows + tree blocks. §12.4 provides per-file mechanical edits for Override 10 with exact text before/after.
- **S3:** §13.3 provides the 9-row classification table; §13.4 provides 5 concrete steps; §13.5 provides the TYPE-2 anti-contamination contract. Coder still exercises content-creation judgment for the project-side ADAPT rows (Override 8 explicitly authorizes this — user said "judgment is OK"), but the starting structure prevents reflexive bad copying.
- **N2:** Already applied inline at §10.4 step 1; no further coder action needed for N2 itself.

---

## §6 — Cross-references for Pack Chat

- **Target doc (extended):** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`
- **Source review:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md` (M3 lines 108-124, S3 lines 185-198, N2 lines 269-275)
- **Authority docs:** `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` (Override 7 + Override 8 + Override 10)
- **B-original (referenced from amendments):** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (§4.4, §4.5, §6.2, §6.4 step 5, §8 tree block)
- **4 help files affected by Override 10:**
  - `project-template/.gemini/commands/pack-help.toml`
  - `project-template/.claude/skills/pack-help/SKILL.md`
  - `project-template/.codex/skills/pack-help/SKILL.md`
  - `project-template/docs/pack/HELP-FRAGMENT.md`
- **OPTIONAL-FEATURES.md (S3 source):** `OPTIONAL-FEATURES.md` (currently at pack root; will move to `pack-ops/OPTIONAL-FEATURES.md` per B's M3)
- **validate-pack.py Check 22 (M3 reference):** `scripts/validate-pack.py` lines 1650-1668

---

## §7 — End of report

All three triaged findings (M3, S3, N2) addressed per reviewer's recommended fix shape + user overrides 7, 8, 10. Existing B-fix content untouched except for the inline N2 line-level edit. Phase 5 coder can apply M3/Override 10/N2 mechanically; S3 requires content-creation per the classification table but with TYPE-2 contamination avoidance contract in place.

No new findings surfaced during the extension work. No additional architect work needed for this fix-pass scope.

PREFLIGHT: 3/3 findings addressed (M3 + Override 10 / S3 / N2); verification PASS (post-extension diff confirmed §1-§11 untouched except for inline N2 fix at line 536); HEAD `8014186`; about to Write IMPL-REPORT to `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-EXTENSION-REPORT.md`.
