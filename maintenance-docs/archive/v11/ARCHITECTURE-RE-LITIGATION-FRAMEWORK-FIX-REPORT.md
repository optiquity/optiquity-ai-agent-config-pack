# IMPLEMENTATION REPORT — ARCHITECTURE-RE-LITIGATION-FRAMEWORK Phase 3 fix-pass (B1 + S1 + S2)

**Actor:** pack-architect A (fix-pass role, fresh instance per Pack Chat)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 3 fix-pass (post-review amend)
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD at fix-pass start:** `8014186`
**Amended doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` (IN PLACE)
**Source of findings:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md` §1 B1 / S1 / S2

---

## §1 — Findings addressed

### B1 (BLOCKER) — V10 framing wrong; collapse to NO ACTION

**Reviewer concern:** Architect A's V10 entry framed `8ba0164` (BD-167b PM-only-edits) as a misrepresented-scope violation on the premise that "project-template trinity is NOT PM-only". That premise is empirically wrong: `CLAUDE.md:336-338` and `PACK-AGENTS.md:148` both explicitly list `project-template/` trinity as Pack-Chat-direct-editable PM-only surfaces. V10 should collapse to NO ACTION; Architect C's M1a/M1b/M5a cascade (PM-only keyword definition) must reframe accordingly.

**Cross-reference grep result (B1 verification — the critical empirical check).** I ran the explicit grep called for in the prompt to determine whether B1 fix-shape (a) (collapse to NO-ACTION) or (b) (re-litigate with corrected list) applies. The pattern covered all known pack-only path families (PACK-AGENTS, PACK-CHAT, HELP-FRAGMENT-PACK, maintenance-docs, supporting-docs, MERGE-STRATEGY, MIGRATION-v10-to-v11, TOOL-COMPARISON, CONCEPTUAL-REVIEW-METHODOLOGY, pack-architect/planner/coder/reviewer/docs-researcher, pack-startup, pack-help.sh, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES.md, RESEARCH-NON-APPLE-UI-SKILLS, ARCHITECTURE-V, ARCHITECTURE-SKILL, validate-pack.py).

Results at HEAD `8014186`:

```
project-template/CLAUDE.md
  366:  7 variant agents; see `PACK-AGENTS.md` for the full roster. The
  397:docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*

project-template/AGENTS.md
  343:  7 variant agents; see `PACK-AGENTS.md` for the full roster. The
  374:docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*

project-template/GEMINI.md
  356:  7 variant agents; see `PACK-AGENTS.md` for the full roster). The PM
  387:docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*
```

**Conclusion: only two distinct cross-reference families exist** in project-template trinity at HEAD:

1. `PACK-AGENTS.md` reference (lines 366 / 343 / 356) — already covered by V1 + T5-A REPLACE (TASK-T1).
2. `maintenance-docs/` TOOL-COMPARISON.md pointer (lines 397 / 374 / 387) — already covered by V8 REVERT (TASK-T1).

Both reference families are already within TASK-T1 scope. **There is no third reference family that would require V10-derived re-litigation.** Per the prompt's "If none → collapse V10 to NO-ACTION with explicit justification" branch, V10 collapses to NO ACTION.

**Sections amended (in the framework doc):**
- §2 V10 entry (lines 297-323 in the amended doc) — rewritten from "VERIFY-THEN-JUSTIFY-OR-REPLACE" to "NO ACTION", citing `CLAUDE.md:336-338` + `PACK-AGENTS.md:148`, embedding the grep result, and adding an explicit Architect C cascade paragraph instructing C-fix to drop V10 as the M1a/M1b/M5a worked example and reframe the PM-only keyword regex.
- §6.3 V10 cascade-line (around line 649) — "VERIFY task — per-hunk audit" replaced with "NO ACTION (per B1 fix-pass)".
- §6.4 V10 manifest-regen-line (around line 664) — replaced with "no manifest-regen trigger — NO ACTION per B1 fix-pass".
- §6.5 V9/V10 mixed-scope heuristic line (around line 671) — V10 dropped; V9 retained; V2 (`aaa61b3`) flagged as the actual real-pattern anchor.
- OQ-6 (around line 711) — relabeled "(RESOLVED by B1 fix-pass)"; documents zero hunk-audit-yield; no planner schedule; no coder spawn.

**Fix shape satisfied:** Yes — per fix-shape (a) "collapse V10 to NO-ACTION if no actual contamination exists". The reviewer's specific concern that V10 is "wrong about the cited cross-references" is resolved by acknowledging the empirically-correct premise and routing the two real cross-reference families through TASK-T1 where they already live.

### S1 (SHOULD) — V4 destination per Override 6

**Reviewer concern:** A's V4 RELOCATE framework named "pack-only directory designated by Architect B" generically; Architect B's §4.1 chose `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`; `AUDIT-USER-CURATION.md` Override 6 rejects that and specifies `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. A's cascade-subsumption logic survives Override 6 (operative property is "pack-only directory"; `pack-ops/` satisfies); A's phrasing should explicitly name the destination.

**Sections amended:**
- §0 reading guide (around line 26) — added an Override 6 cascade paragraph naming `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` as the V4 destination; clarified that the original F-1-conditional framing is no longer operative.
- §2 V4 Rationale (around line 151) — destination changed from generic "pack-only directory designated by Architect B" to explicit `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6.
- §2 V4 Dependency on Architect B (around line 155) — rewritten as "(RESOLVED by Override 6, S1 fix-pass)"; the three original F-1-conditional fallback paths (A reclassify-supporting-docs / B split / C carve-new-dir) explicitly marked no-longer-operative.
- §2 V4 Implementation hint (around line 158) — step 1 now names destination explicitly; step 3 names the full `git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` command; step 4 names `pack-ops/` as the retarget path.
- §2 V4 Reviewer independence-check (around line 164) — verifies destination is `pack-ops/`; supersedes "Architect B picks" framing.
- §5 conditional fallback block (around lines 612-619) — rewritten to "(RESOLVED by Override 6, S1 fix-pass)"; collapse to single decision (SUBSUMED by V4 RELOCATE to `pack-ops/`); reviewer reconciliation note simplified (no BLOCKER escalation path remains).
- OQ-1 (around line 701) — relabeled "(RESOLVED by Override 6, S1 fix-pass)"; names `pack-ops/` destination explicitly; cascade-subsumption preserved.

**Fix shape satisfied:** Yes — destination renamed to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6, cascade-subsumption logic preserved, §5 updated to name actual destination. The reviewer's S1 framing is fully honored.

### S2 (SHOULD) — D8.6/D8.7 + A4-A8 collapse to SPLIT per Override 8

**Reviewer concern:** A's framing in §3.5 D8.6/D8.7 + §4 A4-A8 cluster offered a multi-path conditional decision tree (DUAL-INSTALL recommended; FALLBACK paths REVERT all 5 if Architect B picks keep-pack-only or relocate-to-pack-only-dir). `AUDIT-USER-CURATION.md` Override 8 confirmed SPLIT explicitly. The conditional decision tree should collapse to SPLIT-confirmed; FALLBACK REVERT paths drop.

**Terminology reconciliation:** A's §1 vocabulary distinguishes DUAL-INSTALL (install copy; pack-side is canonical) from SPLIT (cleave audience-mixed file into two independently-curated files). Override 8 ("one for pack. one for projects... There may be something common to both and maybe some individual to both") and B's S2 design ("project-side content tailored... not byte-identical copy") both correspond to SPLIT, not DUAL-INSTALL. The amendments adopt SPLIT as the operative term and note this terminology reconciliation explicitly.

**Sections amended:**
- §3.5 D8.6 + D8.7 block (around lines 451-468) — three-path conditional decision tree for D8.6 (JUSTIFY/REPLACE/REVERT) and parallel framing for D8.7 collapsed to a single decision: REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`. Override 8 explicitly cited. Reviewer independence-check notes "no byte-identity gate" between pack-side and project-side files.
- §4 A4 (around lines 526-540) — collapsed to "LEGITIMATE post-SPLIT"; DEPENDS ON F-5 framing dropped; alternate REVERT paths dropped; NO EDIT decision per Override 8.
- §4 A5 / A6 / A7 / A8 (around lines 543-571) — same SPLIT-confirmed collapse; each now "same as A4 — NO EDIT (LEGITIMATE post-SPLIT)" with explicit Override 8 citation.
- §4 totals reconciliation A4-A8 line (around line 578) — updated to "all LEGITIMATE post-SPLIT (Override 8, S2 fix-pass — supersedes the original 'DEPENDS ON F-5' framing and drops the alternate REVERT paths)".
- §4 aggregate dependency line (around line 582) — relabeled "(RESOLVED by Override 8, S2 fix-pass)"; F-5 = SPLIT per Override 8.
- §6.1 TASK-T8 (around line 636) — updated from "OPTIONAL-FEATURES DUAL-INSTALL — if Architect B chooses" to "OPTIONAL-FEATURES SPLIT — confirmed per Override 8"; pack-side at `pack-ops/`, project-side at `project-template/docs/pack/`; install plumbing in `init-project.sh` ships project-side to client.
- §6.2 sequencing constraints (around line 641) — TASK-T8 F-5 dependency line updated to "SPLIT-confirmed implementation per Override 8".
- OQ-3 (around line 705) — relabeled "(RESOLVED by Override 8, S2 fix-pass)"; full SPLIT design + per-reference resolution path named; fallback REVERT paths explicitly dropped.

**Fix shape satisfied:** Yes — §3.5 D8.6/D8.7 + §4 A4-A8 cluster collapsed to SPLIT-confirmed path; FALLBACK paths dropped; Override 8 citation explicit at every amended block.

---

## §2 — Cross-doc cascade concerns (informational, not blocking)

The fix-pass is in-scope for Architect A only. The following cascades are surfaced for Pack Chat triage and other architects' fix-passes but are NOT amended here:

1. **Architect C cascade (BLOCKER B1 ripple).** Architect C's M1a (memory rule), M1b (commit message rule), M5a (Check 36 PM-only-keyword permitted-paths regex), and §10.2 worked example all need to drop V10 as the worked example and reframe the PM-only keyword to match `PACK-AGENTS.md:148`. The reviewer's MUST-S6 also flags this. Architect A fix-pass cannot edit Architect C's design doc; flagged for Architect C fix-pass.
2. **Architect B fix-pass cascade (S1 ripple).** Architect B's §4.1 chose `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Override 6 corrects to `pack-ops/`. Architect B fix-pass (or extension of existing `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`) should update B's §4.1 to honor Override 6. The reviewer's Concern 5 row for Override 6 surfaces this. Out of scope for this fix-pass; flagged for Architect B fix-pass.
3. **Architect B fix-pass cascade (S2 ripple — none required).** Architect B's S2 commit design already aligns with Override 8 SPLIT — no B-side amendment needed for S2 specifically. (B-fix-pass separately addresses MUST-M3 QUICKSTART per Override 7 and SHOULD-S3 OPTIONAL-FEATURES content-split sketch.)

These cross-doc concerns are documented in the amended framework's §10.5 "Cross-doc cascade concerns" subsection.

---

## §3 — Unaffected sections (intact)

The fix-pass left the following sections untouched (verified via section-by-section review of the amended doc):
- §1 boundary articulation reduced to operational test
- §2 V1, V2, V3, V5, V6 (V6.a/V6.b/V6.c), V7, V8, V9, V11, V12, T5-A, T5-B
- §3.1 (D-1), §3.2 (D-4), §3.3 (D-5), §3.4 (D-7) cascade tables
- §4 A1, A2, A3
- §6.1 TASK-T1 through TASK-T7
- §6.4 manifest regeneration triggers (only the V10 sub-line amended)
- §6.5 out-of-scope items for Architect C handoff (only V9/V10 line amended)
- §7 Phase 3 reviewer master checklist
- §8 OQ-2, OQ-4, OQ-5
- §9 success criteria self-check
- Cross-references to other architect docs (B's §4.1, B-fix, C's M1a/M1b/M5a/§10.2) preserved — none broken.

---

## §4 — Section structure after amendment

```
§0  Reading guide (S1-amended cascade note added)
§1  Boundary articulation reduced to operational test
§2  §C boundary violations (V1-V12 + T5-A/T5-B); V10 S1-amended NO-ACTION; V4 S1-amended pack-ops/
§3  §D confirmed CONTAMINATION references (17 hits); §3.5 D8.6/D8.7 S2-amended
§4  §D AMBIGUOUS-other references (8 hits); A4-A8 S2-amended
§5  §D AMBIGUOUS-pending-§F references (11 hits); S1-amended collapse to pack-ops/
§6  Cascade and sequencing summary; §6.1 TASK-T8 S2-amended; §6.3/§6.4/§6.5 V10 B1-amended
§7  Phase 3 reviewer master checklist (unaffected)
§8  Open questions; OQ-1 S1-amended, OQ-3 S2-amended, OQ-6 B1-amended
§9  Success criteria self-check (unaffected)
§10 Phase 3 fix-pass amendments (B1 + S1 + S2) — NEW
```

All amended sections carry a `<!-- AMENDED by Phase 3 fix-pass (B1/S1/S2) — see PACK-REVIEW-PHASE-2-DESIGNS.md ... -->` HTML comment immediately above the amended block.

---

## §5 — Success criteria verification

Per the prompt's success criteria:

1. **B1: V10 corrected.** Collapsed to NO-ACTION with explicit justification (`CLAUDE.md:336-338` + `PACK-AGENTS.md:148` citations); the grep verification documented; Architect C cascade surfaced. Reviewer's concern that V10 is "wrong about the cited cross-references" is resolved (the two real cross-reference families are within TASK-T1, no third family exists). PASS.
2. **S1: V4 destination = `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`.** Explicit at every amended V4 reference; Override 6 cited at each; cascade-subsumption logic preserved in §5. PASS.
3. **S2: §3.5 D8.6/D8.7 + §4 A4-A8 collapse to SPLIT-confirmed.** All conditional decision trees collapsed; FALLBACK REVERT paths dropped; Override 8 citation explicit at every amended block. PASS.
4. **Unaffected sections intact.** Verified per §3 above. PASS.
5. **Cross-references to other architect docs preserved.** Cross-references to B's §4.1, B-fix, C's M1a/M1b/M5a/§10.2 all preserved (B-cascade flagged in §10.5 of amended framework, but no broken links introduced). PASS.
6. **Fix-pass amendments section summarizes changes.** §10 in the amended framework summarizes B1/S1/S2 changes per finding ID, lists sections amended, and surfaces cross-doc cascade concerns. PASS.

---

## §6 — Tools used + approach

- Read all required context docs (ORCHESTRATION-PLAN-BD-175.md, AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md, AUDIT-USER-CURATION.md, ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md original, ARCHITECTURE-DIRECTORY-REORGANIZATION.md, ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md, PACK-REVIEW-PHASE-2-DESIGNS.md, PACK-AGENTS.md:142-148).
- Executed B1 verification grep against `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` to determine fix-shape branch (a vs b). Result: only V1+T5-A and V8 reference families exist; no third family; fix-shape (a) applies (collapse to NO-ACTION).
- Used surgical Python-driven `str.replace()` edits via Bash for amendment of the framework doc (preferred over Edit tool for multi-block surgical edits where verbatim-text matching with markdown special characters was needed). Each replacement asserted verbatim match of the old block before writing.
- Appended new §10 fix-pass amendments section via the same approach.
- Did NOT use Write to rewrite the whole file — Edit-equivalent surgical replacements preserved unaffected sections byte-identical.
- Followed PREFLIGHT + STOP-MEANS-STOP discipline (per pack-coder pattern, applied here for fix-pass too).

---

## §7 — PREFLIGHT

All in-scope amendments complete and verified at amended-doc HEAD `<work-tree, uncommitted>`. Grep verification reproducible. Cross-doc concerns surfaced without unauthorized cross-doc edits. About to Write this IMPL-REPORT to `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK-FIX-REPORT.md`.

---

## End of fix-pass report
