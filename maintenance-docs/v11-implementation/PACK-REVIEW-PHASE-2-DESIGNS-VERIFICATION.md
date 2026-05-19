# PACK REVIEW — BD-175 Phase 3 verification (post-fix re-verification)

**Reviewer:** pack-reviewer (Phase 3 fix-pass verification role)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 3 verification (after A / B-fix-extension / C / B-fix-v2 amendments)
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD at verification:** `8014186`
**Source of original findings:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md`
**Amended docs verified:**
- `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` (A's amended doc) + `ARCHITECTURE-RE-LITIGATION-FRAMEWORK-FIX-REPORT.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (B-original, retargeted in v2) + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` (B-fix + extension + v2) + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-EXTENSION-REPORT.md` + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-V2-AMENDMENT-REPORT.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` (C's amended doc) + `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-REPORT.md`
- `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` (Override authority)
- `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md` (N1 verification)

**Spot-checked source files (HEAD `8014186`):**
- `PACK-AGENTS.md:140-148` (PM-only Files list)
- `CLAUDE.md:330-343` (Pack Chat CAN edit directly)
- `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (B1 grep evidence)
- `project-template/.gemini/commands/pack-help.toml`, `.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`, `docs/pack/HELP-FRAGMENT.md` (Override 10 BEFORE strings)

---

## §0 — Executive summary

**Verdict counts:** 12 VERIFIED + 0 REMAINING + 0 NEW DEFECTS + 3 status-only (M1, N1, N3, N4 = no-fix-required confirmations).

| Finding | Severity | Actor | Verdict |
|---|---|---|---|
| B1 | BLOCKER | A fix + C cascade | VERIFIED |
| M2 | MUST | C fix | VERIFIED |
| M3 | MUST | B-fix extension | VERIFIED |
| M3 / Override 10 | MUST (cascade) | B-fix extension | VERIFIED |
| M4 | MUST | C fix | VERIFIED |
| S1 | SHOULD | A fix | VERIFIED |
| S2 | SHOULD | A fix | VERIFIED |
| S3 | SHOULD | B-fix extension | VERIFIED |
| S4 | SHOULD | C fix | VERIFIED |
| S5 | SHOULD | C fix | VERIFIED |
| S6 | SHOULD | C fix (B1 cascade) | VERIFIED |
| N2 | NIT | B-fix extension | VERIFIED |
| Override 6 cascade | (NEW finding) | B fix v2 | VERIFIED |
| M1 | MUST | Phase 4 planner | DEFERRED-TO-PLANNER (correctly carried by triage; not architect work) |
| N1 | NIT | Pack Chat | VERIFIED (HEAD `9863c06`) |
| N3 | NIT | (none) | VERIFIED no action |
| N4 | NIT | (none) | VERIFIED no action |

**Final go/no-go:** **GO.** Phase 4 planner may spawn.

The four architect fix-passes (A, B-fix extension, C, B-fix v2) collectively close every active reviewer finding from `PACK-REVIEW-PHASE-2-DESIGNS.md` plus the Override 6 cascade gap surfaced after the first fix-pass round. No new defects introduced. Cross-architect consistency verified — A's, B's, and C's amended docs name `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` consistently; A's V10 NO-ACTION decision and C's `PM-only`-keyword permitting project-template trinity align via the same `PACK-AGENTS.md:148` evidence; C's `pack-ops/` deny-list addition (M2) is symmetrically applied to both Check 37 (§8.2) and the boundary-investigation skill (§6) and the project-side mirror (§4.2 per S5); the C2-at-root exemption list is unambiguously 1-entry (per B-fix M4 ripple to C). The single MUST finding that is correctly deferred to Phase 4 planner (M1 — Option A enforcement for combined commit) is a planner constraint Pack Chat will surface at planner-spawn time per triage decision.

---

## §1 — Per-finding verdicts

### B1 (BLOCKER) — V10 framing wrong; project-template trinity IS PM-only

**Architect's amendment location:**
- A: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V10 (lines 297-322) + §6.3 V10 cascade-line (line 649) + §6.4 V10 manifest-regen line (line 664) + §6.5 V9/V10 heuristic line (line 671) + OQ-6 (line 711) + §10.1 fix-pass amendment summary (lines 735-753)
- C: `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §8.1 keyword-table PM-only row (line 482) + §8.1a NEW subsection (lines 505-569) + §10.2 worked example body (lines 748-777) + §16.3 fix-pass summary (lines 1000-1072)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **Empirical grep claim verified.** I reproduced A's B1 verification grep against `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` at HEAD `8014186`. Result matches A's claim exactly — only TWO cross-reference families: `PACK-AGENTS.md` at lines 366/343/356 (covered by V1 + T5-A REPLACE in TASK-T1) and `maintenance-docs/` TOOL-COMPARISON.md pointer at lines 397/374/387 (covered by V8 REVERT in TASK-T1). No third reference family exists. The "collapse V10 to NO-ACTION" branch is the correct branch (fix-shape (a)).

2. **Pack-memory citations verified.** `CLAUDE.md:336-338` explicitly names "`project-template/` trinity" in the PM-only list. `PACK-AGENTS.md:148` explicitly lists "`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root and `project-template/`)". Both verified at HEAD `8014186`.

3. **A's V10 entry collapses correctly.** §2 V10 now opens "TYPE-1 LOW: 8ba0164 BD-167b PM-only-edits (NO ACTION — initial framing wrong)" and the body cites both pack-memory locations and the grep result. Decision: NO ACTION. Implementation hint: "None. V10 has no Phase 5 task." All downstream cascade locations updated (§6.3, §6.4, §6.5, OQ-6).

4. **C's cascade fully applied.** §8.1 keyword-table PM-only row rewritten to explicitly PERMIT project-template trinity, with cross-reference to PACK-AGENTS.md:142-148 + §8.1a. §8.1a NEW subsection contains verbatim PACK-AGENTS.md:142-148 PM-only Files block + post-B path-substitution rules + canonical PERMITTED-PATHS regex. §10.2 worked example V10 body DROPPED with explicit rationale; replaced with V2 (`aaa61b3`) hypothetical-PM-only-keyword shape that would correctly fail Check 36 because `supporting-docs/` is NOT in the PM-only Files list. §8.1 measurable-tests updated: the original FAIL fixture on `project-template/CLAUDE.md` flipped to PASS (correct per actual list); new V2-shape FAIL fixture added for `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.

5. **"Caught V10" parenthetical DROPPED.** Verified — no remaining "caught V10" text in C's keyword definition; the parenthetical that incorrectly framed project-template trinity as a violation surface no longer appears.

---

### M2 (MUST) — add `pack-ops/` to Check 37 deny-list + M4 skill mirror

**Architect's amendment location:**
- C `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §8.2 Check 37 deny-list table (line 587) — new `pack-ops/` (path prefix) row
- C §6 M4 boundary-investigation skill text, step 4 Path-prefixes bullet (line 390) — `pack-ops/` added alongside `maintenance-docs/`, `scripts/`, `test-fixtures/`
- C §16.1 fix-pass summary (lines 930-956)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§8.2 deny-list table.** Line 587 of C's amended doc now contains a `pack-ops/` (path prefix) row placed directly after the `maintenance-docs/` row, with full enumeration of the relocated pack-ops files (BOUNDARY-DEFINITION, PACK-AGENTS, PACK-CHAT, BACKLOG, CHANGELOG, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, MERGE-STRATEGY, DRY-RUN-MIGRATION, .boundary-exempt-root.txt). Cell text notes "Symmetric with `maintenance-docs/` entry above." Fix-shape satisfied.

2. **§6 M4 skill mirror.** Line 390 of C's amended doc contains the path-prefixes bullet `"Path prefixes: `maintenance-docs/`, `pack-ops/` (pack-only top-level dir per Architect B; houses BOUNDARY-DEFINITION.md, PACK-AGENTS.md, PACK-CHAT.md, BACKLOG.md, CHANGELOG.md, etc. post B-fix M1-M5 + M9-M10 — none of which exist at client install), `scripts/` ..., `test-fixtures/`"`. The M4 skill methodology now lists `pack-ops/` as a deny-target. Fix-shape satisfied.

3. **Symmetric coverage.** Both surfaces the reviewer named (Check 37 deny-list AND M4 skill text) are updated; the wording is consistent across both ("pack-only top-level dir" framing + same enumerated file list).

---

### M3 (MUST) — drop B's S1 SPLIT per Override 7 + Check 22 surfaces dict cleanup

**Architect's amendment location:** B-fix `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §12 (lines 570-833) amending B-original at §4.4, §6.2 S1 row, §6.4 step 5, §8 tree

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§12.1 amends B-original §4.4.** B-fix §12.1 (line 580) provides the REPLACEMENT design for F-4: "**§4.4 F-4 resolution (B-fix-extended per Override 7): KEEP AT ROOT, NO SPLIT.**" Pack-only refs to `/QUICKSTART.md` UNCHANGED; project-side refs in 4 help files REMOVED per Override 10 (designed in §12.4); `init-project.sh` gains NO install stage. Override 7 explicitly cited.

2. **§12.1 drops `surfaces["project-template"]["docs"]` addition.** B-fix §12.1 (line 608) explicitly states: "The addition of `REPO_ROOT / "project-template" / "docs" / "pack" / "QUICKSTART.md"` that B's §4.4 mentioned is **DROPPED**. No project-side QUICKSTART.md exists, so no entry needs validating." `scripts/validate-pack.py:230` and `:1655` confirmed unchanged.

3. **§12.2 deletes S1 row from SPLIT table.** B-fix §12.2 (line 621) provides the updated SPLIT table containing S2 only; S1 row deleted. The S2 conditional-on-Architect-A qualifier is also lifted per Override 8 (B-fix-extended notes this cross-Override coordination explicitly).

4. **§12.3 deletes S1 commit from B-original §6.4 step 5.** B-fix §12.3 (line 631) explicitly DELETES step 5 ("Execute S1 (QUICKSTART.md split) as a third commit"). The updated 4-commit sequence is enumerated (Commit A through Commit D), with no S1 commit anywhere. Cross-reference to B-fix §7.1 Option A (M9/M10 folding) preserved.

5. **§12.6 deletes project-side QUICKSTART entry from §8 tree.** B-fix §12.6 (line 808) provides the amended `project-template/docs/pack/` tree block with the `QUICKSTART.md (NEW ...)` row DELETED; the `OPTIONAL-FEATURES.md` row's conditional qualifier is also lifted per Override 8.

6. **No remaining S1 instructions.** §12.7 net-effect summary explicitly states: "No S1 commit anywhere. ... No `validate-pack.py` Check 22 `surfaces["project-template"]["docs"]` addition. ... No `init-project.sh` install stage for project-side QUICKSTART.md." Override 7 citation explicit.

---

### M3 / Override 10 — Remove `docs/pack/QUICKSTART.md` refs from 4 help files

**Architect's amendment location:** B-fix §12.4 (lines 651-783) — per-file wording-removal design

**Verdict:** **VERIFIED.**

**Evidence:**
1. **All 4 files covered with BEFORE/AFTER.** §12.4 designs the wording-removal for all 4 affected files:
   - §12.4.1 `project-template/.gemini/commands/pack-help.toml` (1 ref, line 10)
   - §12.4.2 `project-template/.claude/skills/pack-help/SKILL.md` (1 ref, line 13)
   - §12.4.3 `project-template/.codex/skills/pack-help/SKILL.md` (1 ref, line 13)
   - §12.4.4 `project-template/docs/pack/HELP-FRAGMENT.md` (2 refs, lines 4 + 31)

2. **BEFORE strings match HEAD reality.** I spot-checked each file's current state at HEAD `8014964` (latest spot-check):
   - pack-help.toml lines 10-12: "For full documentation, see docs/pack/QUICKSTART.md, docs/pack/PM-CHAT.md, docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md." Matches §12.4.1 BEFORE block exactly.
   - .claude/.../SKILL.md lines 13-15: "For full documentation, see `docs/pack/QUICKSTART.md`, `docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`." Matches §12.4.2 BEFORE block exactly.
   - .codex/.../SKILL.md lines 13-15: byte-identical to Claude version. Matches §12.4.3.
   - HELP-FRAGMENT.md lines 4-6 (front-matter) + lines 31-33 (See-also): both blocks match §12.4.4 BEFORE strings exactly.

3. **AFTER strings preserve intended docs.** Each AFTER block:
   - Drops only the `docs/pack/QUICKSTART.md` token (with its trailing comma + space) — surgical deletion.
   - Preserves PM-CHAT.md, INSTALL-PROCEDURES.md, OPTIONAL-FEATURES.md (the 3 in-project docs the user explicitly endorsed as legitimate help-file references).
   - HELP-FRAGMENT.md "See also" section additionally preserves METHODOLOGY.md, PLATFORM-SKILLS.md, and `docs/project/BACKLOG.md` (the last is project-side, correctly identified by B-extension as UNAFFECTED by M9).

4. **Trinity rule honored for 3 CLI-parallel files.** §12.5 explicitly addresses trinity compliance: the three pack-help skill files (Files 1-3) form a trinity and land in lockstep in a single commit; HELP-FRAGMENT.md joins the same commit for cohesion. Post-edit symmetry confirmed: all three trinity files will reference the same 3 docs.

5. **Override 10 explicitly cited.** §12.4 frontmatter + §12.7 closing both cite "AUDIT-USER-CURATION.md §1 Override 10."

---

### M4 (MUST) — collapse 3-entry exemption list to 1-entry

**Architect's amendment location:**
- C `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §11 conditional-surfaces table (lines 786-794) — M5a / M5b / M5c rows annotated
- C §13 Order of land Step 11 (line 839) — "1-entry list per B-fix §4 + Overrides 1 + 5" annotation
- C §16.2 fix-pass summary (lines 958-998)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§11 M5a row updated.** Line 791 of C's amended doc reads: "**Post-B-fix:** PM-only paths regex is per §8.1a, sourcing from `PACK-AGENTS.md:142-148`. The B-fix C2-at-root exemption list (`pack-ops/.boundary-exempt-root.txt`) is a **1-entry list** (only `tracker.toml.pack-example` per AUDIT-USER-CURATION.md Override 1 + Override 5 collapsing the original 3-entry closed-set proposed in B's §2.1); Check 36 / Check 38 fixtures that depend on the allow-list count assert N=1, NOT N=3." The N=1 / NOT N=3 disambiguation is explicit, with both Override citations.

2. **§11 M5b row updated.** Line 792 of C's amended doc cross-references the M2 amendment: "Post-B + B-fix adds `pack-ops/` path-prefix per finding M2."

3. **§11 M5c row updated.** Line 793 of C's amended doc reads: "The 1-entry exemption list (above) governs which C2-at-root files Check 38 tolerates as exempt." Explicit cross-reference to the corrected count.

4. **§13 Order of land Step 11.** Line 839 of C's amended doc reads: "Consumes `pack-ops/.boundary-exempt-root.txt` (the 1-entry list per B-fix §4 + Overrides 1 + 5 — only `tracker.toml.pack-example`) as the allow-list for C2-at-root files; reject all other PACK × OPERATIONS files at root." Authority pointers explicit.

5. **No N=3 fixtures.** C's §12 test plan table for M5a/b/c does not encode N=3 anywhere — verified via grep on C's pre-fix and post-fix content. Per C-fix's §16.2 own admission, the pre-fix had 0 literal "3-entry" hits but 2 indirect dependencies via §11 + §13. Both now carry "N=1, NOT N=3" disambiguations. Phase 5 coder cannot land an N=3 assertion by accident.

---

### S1 (SHOULD) — V4 destination per Override 6

**Architect's amendment location:** A `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §0 reading guide (line 26-27) + §2 V4 Rationale (line 151) + §2 V4 Dependency on Architect B (line 155) + §2 V4 Implementation hint (lines 158-160) + §2 V4 Reviewer independence-check (line 164) + §5 conditional fallback block (lines 612-619) + OQ-1 (line 701) + §10.2 fix-pass amendment summary (lines 755-766)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§0 reading guide gains Override 6 cascade paragraph.** Lines 26-27 of A's amended doc add an HTML-comment-marked AMENDED block explicitly naming `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` as the V4 destination and noting the cascade-subsumption logic is preserved (operative property is "pack-only directory"; `pack-ops/` satisfies).

2. **§2 V4 Rationale names actual destination.** Line 151 of A's amended doc reads: "The fix is to move the file to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per `AUDIT-USER-CURATION.md` Override 6, which corrects Architect B's §4.1 `maintenance-docs/` proposal)." Override 6 cited explicitly.

3. **§2 V4 Dependency on Architect B marked RESOLVED.** Line 155 of A's amended doc reads: "**Dependency on Architect B (RESOLVED by Override 6, S1 fix-pass).**" The three original F-1-conditional fallbacks are explicitly marked "no longer operative."

4. **§2 V4 Implementation hint names destination + git mv command.** Lines 158-160 of A's amended doc include: step 1 "Destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per `AUDIT-USER-CURATION.md` Override 6 (S1 fix-pass)" + step 3 "Use `git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` to preserve file history" + step 4 "retarget all to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`."

5. **§5 cascade-subsumption preserved.** Line 613 of A's amended doc retains the cascade-subsumption logic: all 11 §5 ambiguous-pending-§F references become LEGITIMATE post-RELOCATE because the operative property ("pack-only directory") is preserved. The destination change does not change the cascade outcome.

6. **OQ-1 marked RESOLVED.** Line 701 of A's amended doc reads: "**OQ-1 (RESOLVED by Override 6, S1 fix-pass).**" with full destination naming.

---

### S2 (SHOULD) — D8.6/D8.7 + A4-A8 collapse to SPLIT per Override 8

**Architect's amendment location:** A `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §3.5 D8.6/D8.7 block (lines 451-468) + §4 A4-A8 (lines 526-571) + §4 totals (line 580) + §4 aggregate dependency (line 582) + §6.1 TASK-T8 (line 636) + §6.2 sequencing (line 641) + OQ-3 (line 705) + §10.3 fix-pass amendment summary (lines 770-784)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§3.5 D8.6/D8.7 collapsed.** Lines 451-468 of A's amended doc consolidate the prior three-path conditional decision tree (JUSTIFY/REPLACE/REVERT) into a single decision: "**REPLACE per SPLIT-confirmed path (Override 8, S2 fix-pass).**" The pre-amendment conditional-tree prose is replaced; Override 8 explicitly cited.

2. **§4 A4-A8 cluster all NO EDIT.** Lines 526-571 of A's amended doc carry HTML-comment-marked AMENDED blocks for each of A4, A5, A6, A7, A8. Each verdict reads "LEGITIMATE post-SPLIT (Override 8, S2 fix-pass)" with decision "NO EDIT." The DEPENDS ON F-5 framing is gone; alternate REVERT paths explicitly dropped.

3. **§4 totals updated.** Line 580 of A's amended doc reads: "A4-A8: NEW DECISION cluster (5 OPTIONAL-FEATURES references) → all LEGITIMATE post-SPLIT (Override 8, S2 fix-pass — supersedes the original 'DEPENDS ON F-5' framing and drops the alternate REVERT paths)."

4. **§4 aggregate dependency RESOLVED.** Line 582 of A's amended doc reads: "**Aggregate dependency on Architect B for §4 (RESOLVED by Override 8, S2 fix-pass):** A4-A8 (5 hits) original F-5 dependency is resolved — F-5 = SPLIT per Override 8; all 5 references become LEGITIMATE post-SPLIT."

5. **§6.1 TASK-T8 collapsed.** Line 636 of A's amended doc rewrites TASK-T8 from conditional "DUAL-INSTALL — if Architect B chooses" to unconditional "**OPTIONAL-FEATURES SPLIT — confirmed per Override 8.**" Pack-side at `pack-ops/`, project-side at `project-template/docs/pack/`; install plumbing in `init-project.sh` enumerated; D8.6/D8.7 REPLACE + A4-A8 verify-only.

6. **OQ-3 marked RESOLVED.** Line 705 of A's amended doc reads: "**OQ-3 (RESOLVED by Override 8, S2 fix-pass).**" with full SPLIT design naming.

7. **FALLBACK paths dropped explicitly.** Per §10.3 amendment summary, the pre-amendment fallback REVERT paths (which would have damaged project-side UX) are dropped at every amended block. Verified via grep — no remaining "alternate paths REVERT all 5" framing in A's amended doc.

---

### S3 (SHOULD) — OPTIONAL-FEATURES.md content-split sketch

**Architect's amendment location:** B-fix §13 (lines 837-913) — content-split sketch

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§13.1 section inventory.** Lines 848-857 of B-fix enumerate the 6 current top-level sections of `OPTIONAL-FEATURES.md` (intro, Agent Teams, Codex placeholder, Gemini placeholder, Tracker integration, Adding new entries) with line ranges per section. This is the pre-split baseline.

2. **§13.2 audience analysis.** Lines 860-870 of B-fix distinguish pack-side audience (pack maintainers, Pack Chat orchestrating pack-self workflows, pack agents, pack contributors) from project-side audience (project PM chats, project developers, project agents).

3. **§13.3 content-split sketch.** Lines 876-886 of B-fix provide the 9-row classification table the reviewer asked for (the "5-10 line outline" criterion — actually 9 decision rows, but each is one section + one verdict). Each row classifies a section as pack-side-only / project-side-only / common-to-both with audience-tailoring notes. Coverage:
   - Intro paragraphs (KEEP / ADAPT) — common-topic, different voice
   - Agent Teams (KEEP FULL / ADAPT) — common topic, different paths
   - Codex/Gemini placeholders (KEEP / KEEP) — common-to-both stubs
   - Tracker integration pack-surface (KEEP FULL / DROP)
   - Tracker integration project-surface (narrated / KEEP FULL)
   - Tracker MERGE-STRATEGY reference (KEEP / KEEP-with-qualifier)
   - Pack-tracker plumbing (KEEP / **OMIT entirely** — explicit TYPE-2 avoidance)
   - Adding new entries (KEEP / KEEP-OR-ADAPT)

4. **§13.4 Phase 5 coder guidance.** Lines 892-900 of B-fix provide 5 concrete coder steps: git mv pack-side, create project-side from template, init-project.sh install stage, 5 project-side reference resolution, no byte-identity contract.

5. **§13.5 TYPE-2 contamination avoidance.** Lines 902-908 of B-fix explicitly name what NOT to copy (pack-tracker plumbing details, pack-self surface mentions, unqualified pack-ops/ path references) — addressing the reviewer's specific concern that "without specificity, the coder will improvise" (the exact P-missed-7 anti-pattern this BD is fixing).

6. **§13.6 Override 8 citation.** Line 911 of B-fix explicitly cites "AUDIT-USER-CURATION.md §1 Override 8 ('CONFIRMED SPLIT')" and operationalizes the user's three sub-principles (separate files, common-to-both OK, per-audience tailoring) in the §13.3 / §13.4 / §13.5 design.

---

### S4 (SHOULD) — explicit Override 9 citation block

**Architect's amendment location:** C §4.1 NEW subsection (lines 130-184) + §16.4 fix-pass summary (lines 1074-1104)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§4.1 cites Override 9 verbatim.** Lines 132-148 of C's amended doc add a new §4.1 subsection. It contains a verbatim quote-block from Override 9: "Different audience means different wording is fine. Two audience-specific rules, not a mirror in the byte-identical-drift sense. Compatible with D-4 ('no mirrors as default') because the two rules are substantively different even though they share the principle." Authority pointer to "AUDIT-USER-CURATION.md §1 Override 9 (CONFIRMED)" explicit.

2. **§4.1 distinguishes within-trinity from cross-trinity parity.** Lines 154-172 of C's amended doc add an "Implication for Check 18 H2 parity" sub-block that:
   - Affirms WITHIN-trinity parity continues to apply (CLI-files-cross-CLI-parity at each trinity location).
   - REJECTS cross-trinity parity (pack-root trinity wording vs project-template trinity wording — those differ by design per Override 9).
   - Explicitly states: "Any future Check 18 extension or new check that would compare pack-root P-missed-7 text to project-template Project SSOT-first text is REJECTED by this design."

3. **§4.1 measurable consequence sub-block.** Lines 173-177 of C's amended doc state that M2's measurable test (Trinity Check 18 H2 parity fires when the bullet is missing from one trinity file) applies WITHIN each trinity location and does NOT fire on pack-side-vs-project-side wording differences.

4. **Phase 3 reviewer pointer included.** Lines 150-152 of C's amended doc quote Override 9's specific reviewer guidance: "no cross-trinity drift gate needed for this codification (different wording is intentional, not drift)."

5. **Cross-reference to S4 fix-pass.** Lines 179-184 of C's amended doc include the fix-pass anchor block citing the reviewer finding (PACK-REVIEW-PHASE-2-DESIGNS.md §1 S4, lines 201-216) with explanation of the gap closed.

---

### S5 (SHOULD) — `pack-ops/` path-prefix in §4.2 project-side mirror deny-list

**Architect's amendment location:** C §4.2 deny-list paragraph (lines 195-205) + §16.5 fix-pass summary (lines 1106-1131)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **§4.2 deny-list paragraph updated.** Lines 199-204 of C's amended doc now read: "Files at the pack repo (PACK-AGENTS.md, PACK-CHAT.md, pack-* agent prompts, pack-repo maintenance-docs/, pack-repo pack-ops/ — any file under pack-ops/, including BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc. post Architect B + B-fix) are NOT part of the project SSOT and must not be referenced from project files — the pack repo is not present at this client install." The `pack-ops/` path-prefix is named explicitly with full file enumeration.

2. **Symmetric with pack-side P-missed-7 expansion.** The phrasing matches the symmetric pack-side P-missed-7 expansion in §4 + §6/§8.2. Project-side trinity readers (project PM chat at client install) now see `pack-ops/` named explicitly as a deny-target.

3. **Path-prefix-equivalent phrasing.** "any file under pack-ops/" is path-prefix-equivalent and matches the grep contract used by Check 37 (M2 amendment). The semantic intent (deny any reference under `pack-ops/` because the dir doesn't exist at client install) is preserved.

---

### S6 (SHOULD) — PM-only keyword definition aligns with PACK-AGENTS.md:148

**Architect's amendment location:** C §8.1 keyword-table PM-only row (line 482) + §8.1a NEW subsection (lines 505-569) + §10.2 worked example body (lines 748-777) + §12 test plan (table M5a row reads through to §8.1's updated fixtures) + §16.3 fix-pass summary (lines 1000-1072)

**Verdict:** **VERIFIED.** (Cascade from B1 — same amendment package.)

**Evidence:**
1. **§8.1 keyword-table PM-only row.** Line 482 of C's amended doc reads: "Subject contains literal `PM-only` or `pack-memory-only` | Only Pack-Chat-direct-edit surfaces per `PACK-AGENTS.md:142-148` PM-only Files list — see §8.1a below for the verbatim list. Notably **PERMITS** edits to `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (project-template trinity IS PM-only per PACK-AGENTS.md:148 — "root and `project-template/`"). Updated per Phase 3 reviewer finding B1-cascade + S6." Project-template trinity is explicitly permitted; "caught V10" parenthetical is gone.

2. **§8.1a verbatim PACK-AGENTS.md list.** Lines 511-519 of C's amended doc paste the verbatim PACK-AGENTS.md:142-148 Files block. The canonical PERMITTED-PATHS regex at lines 538-542 enumerates all 11 paths: pack-ops/{BACKLOG, CHANGELOG, PACK-CHAT, PACK-AGENTS}.md + README.md + root trinity (3 files) + project-template trinity (3 files). The regex permits project-template trinity edits under a PM-only keyword by construction.

3. **§10.2 worked example V10 dropped.** Lines 748-759 of C's amended doc explicitly drop the V10 worked example with rationale: "Pre-fix worked example (V10) was INCORRECT and is dropped. ... commit `8ba0164` ... DID claim PM-only and DID touch project-template trinity — but project-template trinity IS PM-only per PACK-AGENTS.md:148 ... V10 collapses to NO-ACTION per Architect A fix-pass."

4. **§10.2 corrected V2 worked example.** Lines 761-773 of C's amended doc replace the V10 example with V2 (`aaa61b3`) in hypothetical PM-only-keyword shape: had the commit subject carried PM-only, the `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` edit would correctly fail Check 36 because supporting-docs is NOT in the PM-only Files list. This is the correct worked example for the keyword convention.

5. **§12 test plan compatibility.** §12 M5a row points to §8.1's measurable tests as canonical (no duplicative re-statement). §8.1's measurable-tests bullet list (lines 499-503) now contains the corrected fixtures: `PM-only` + `project-template/CLAUDE.md` → PASS (correct), plus new V2-shape `PM-only` + `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` → FAIL (correct because supporting-docs is project-side).

---

### N2 (NIT) — count-agnostic verification phrasing

**Architect's amendment location:** B-fix §10.4 step 1 (line 536) + B-fix §14 NEW subsection (lines 916-928)

**Verdict:** **VERIFIED.**

**Evidence:**
1. **In-place phrasing edit.** Line 536 of B-fix now reads: "`bash scripts/validate-pack.py` — all currently-enabled checks pass. Check 3, Check 22, Check 24, Check 32, Check 35 all touch the relocated paths; any failure here means a constant was missed." The "all 33 checks pass" phrasing has been replaced with the count-agnostic "all currently-enabled checks pass." Check-name references (stable identifiers) preserved.

2. **No other hardcoded counts.** Per B-fix §14 cross-reference verification: this is the only count-hardcoded location in B-fix; the surrounding text uses check-name references (Check 3, Check 22, etc. — stable identifiers, not drifting numbers). No further amendment needed.

---

### Override 6 cascade fix (NEW finding addressed by B fix-pass v2)

**Architect's amendment location:** B-original `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` lines 339 + 349 + 472 + 531 (4 edits) + B-fix `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` line 134 + line 646 (2 inline edits) + B-fix new §16 (lines 944-1015)

**Verdict:** **VERIFIED.**

**Evidence (per the 5 ref locations called out in the prompt):**

1. **B-original line 339 (V4 destination justification).** Verified retargeted. Current text reads: "`CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` **[Per Override 6 — destination is `pack-ops/`, NOT `maintenance-docs/`; see B-fix §16 for cascade explanation]**. The file is pack-internal methodology that informs pack-reviewer / pack-architect (PACK × OPERATIONS); ... `pack-ops/` is the home for pack operational docs ... CONCEPTUAL-REVIEW-METHODOLOGY belongs alongside them as a sibling pack-operations doc. The original `maintenance-docs/` proposal in this paragraph is superseded by Override 6." Override 6 cited inline.

2. **B-original line 349 ("Naming rationale" paragraph).** Verified retargeted. Current text reads: "**Naming rationale for CONCEPTUAL-REVIEW-METHODOLOGY destination — SUPERSEDED by Override 6:** [Per `AUDIT-USER-CURATION.md` Override 6 — destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. The original `maintenance-docs/` rationale (live-vs-textbook distinction, sibling-family argument) is REJECTED. ... The earlier live-vs-textbook framing is no longer operative; see B-fix §16 for the full cascade explanation.]" The DEFENDING paragraph for `maintenance-docs/` has been replaced with an explicit REJECTED + SUPERSEDED block.

3. **B-original line 472 (BOUNDARY-DEFINITION cross-reference list).** Verified retargeted. Current text reads: "`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (after F-1 move per Override 6) — add a pointer in dimension (d) Pack rule adherence so conceptual reviewers cite it." Override 6 cited inline.

4. **B-original line 531 (M6 row in §6.1 MOVES table).** Verified retargeted. Current text reads: "| M6 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6; see B-fix §16) | ~10 refs ... |" Destination cell updated; Override 6 cited inline.

5. **B-fix line 134 (M6 row in §5 commit table).** Verified retargeted. Current text reads: "| M6 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6; see §16 below) | ~10 refs (B's §6.1) |" Destination cell updated; cross-reference to §16 inline.

**Gap acknowledgment (line 646-area).** B-fix §11.3 step 3 (line 646) previously contained a self-flagged "wait, Override 6 places it at pack-ops/, not maintenance-docs/; that override is ... NOT amended in B-fix §11" acknowledgment. This is now REWRITTEN per v2 amendment: line 646 reads: "**Commit C (M6-M8):** `supporting-docs/` → `pack-ops/` for ALL THREE files (M6 `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/` per `AUDIT-USER-CURATION.md` Override 6 — this v2 amendment closes the cascade gap acknowledged in the pre-v2 wording of this step; see §16 below for the cascade detail; M7 `DRY-RUN-MIGRATION.md` → `pack-ops/`; M8 `MERGE-STRATEGY.md` → `pack-ops/`). All three MOVES land in the same commit; reference updates; manifest regen." The forward-pointing speculation is replaced with a closed-gap reference.

**New §N (16) summarizing v2 amendment.** Verified. B-fix gains a new §16 (lines 944-1015) with subsections §16.1 (Authority — Override 6 verbatim), §16.2 (Why this amendment exists), §16.3 (5 amended locations before/after summary), §16.4 (Sections NOT amended — §1-§15 stability statement), §16.5 (Net effect on Phase 5 coder), §16.6 (Cross-doc cascade closure stating A-side already handled, C-side no ripple needed).

**Final grep verification.** I ran `grep -n "maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY"` against both B-original and B-fix:
- B-original: 0 hits. All 4 stale refs retargeted to `pack-ops/`.
- B-fix: 5 hits, ALL inside §16 as historical "Before:" rows + the Override 6 verbatim quote (B-fix §16.1 quotes Override 6 which contains the original B claim verbatim). No stale OPERATIVE reference remains.

The cascade is closed. Phase 4 planner + Phase 5 coder + Phase 3 reviewer all see a consistent `pack-ops/` destination across every architect doc.

---

### Findings NOT addressed in this fix-pass batch — status confirmation

#### M1 (MUST) — planner constraint

**Verdict:** **DEFERRED-TO-PLANNER (correctly).**

**Evidence:** The reviewer triage explicitly named M1's actor as "Phase 4 planner" with the fix being "PLAN-* doc names the single combined commit explicitly with all 7 `git mv` + all script updates + manifest regen in one atomic landing; no per-MOVE commit splitting." This is NOT architect-fix-pass work; it is a constraint that Pack Chat carries forward into the Phase 4 planner spawn prompt. Per the prompt instructions ("Confirm the Phase 4 planner will receive this constraint"), this requires only confirmation that Pack Chat will surface to planner spawn. Pack Chat's prompt-build for the planner is the responsibility surface; the constraint is documented in PACK-REVIEW-PHASE-2-DESIGNS.md M1 (lines 69-83) and in this verification report — Pack Chat reading this report has the trace.

**Action item for Pack Chat:** When spawning Phase 4 pack-planner, include M1 as an explicit planner constraint: "enforce Option A combined M1-M5 + M9-M10 single commit per B-fix §7.1; reject Option B."

---

#### N1 (NIT) — orchestration plan filename housekeeping

**Verdict:** **VERIFIED COMMITTED (HEAD `9863c06` per prompt).**

**Evidence:** Spot-checked `ORCHESTRATION-PLAN-BD-175.md` for the Phase 3 output filename reference. Line 143 reads: "Output: `PACK-REVIEW-PHASE-2-DESIGNS.md` with BLOCKER/MUST/SHOULD/NIT findings." This matches the reviewer's prompt-specified output path and the actual file path. The previous `PACK-REVIEW-EMERGENCY-DESIGNS.md` mismatch is resolved.

---

#### N3 (NIT) — pre-v11 origin info

**Verdict:** **VERIFIED NO ACTION (informational only).**

**Evidence:** N3 in PACK-REVIEW-PHASE-2-DESIGNS.md was a NIT confirming A surfaces V8's pre-v11 origin commit (`5035328`) for completeness; no fix or action attaches. A's V8 entry (line 257 of amended doc) preserves the informational note. No amendment was required; none was made. Correct.

---

#### N4 (NIT) — v12 anchor decision DROP

**Verdict:** **VERIFIED NO ACTION (drop confirmed; no v12 BD anchor opened).**

**Evidence:** N4 was an optional v12 anchor consideration for the `project-template/docs/pack/` rename evaluation. Per the prompt, no action was authorized. No new BD anchor was opened; B-original §4.2 retains its "NO RENAME — structurally accepted" decision; no v12 deferred BD has been added to BACKLOG. Correct.

---

## §2 — Cross-doc consistency check

**Cross-doc consistency: VERIFIED.**

| Consistency check | Status |
|---|---|
| A's V10 NO-ACTION + C's PM-only-keyword permits project-template trinity (both cite PACK-AGENTS.md:148) | ALIGNED — A §2 V10 + §10.1 + C §8.1 + §8.1a + §10.2 + §16.3 all reference the same `PACK-AGENTS.md:142-148` PM-only Files list authority |
| A's V4 RELOCATE destination = `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` AND B's M6 destination = `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | ALIGNED — A §2 V4 + §5 + §10.2 + B-original §4.1 (post v2) + §6.1 M6 row + B-fix §5 + §16 all name `pack-ops/` as the destination |
| C's `pack-ops/` deny-list addition (M2) at §8.2 + §6 + §4.2 (S5) covers symmetric pack-side and project-side | ALIGNED — all three surfaces enumerate `pack-ops/` as a deny-target with full file enumeration |
| C's 1-entry exemption list (M4) + B-fix's 1-entry exemption list (§4) | ALIGNED — both name only `tracker.toml.pack-example` per Overrides 1 + 5 |
| Override 9 citation in C §4.1 (S4) + A's design (no cross-trinity drift expected) + B's design (no cross-trinity-parity addition) | ALIGNED — no architect introduces a cross-trinity parity gate; C explicitly REJECTS one |
| Override 8 SPLIT in A's TASK-T8 + B-fix §13 content-split sketch + B-fix §12.2 S2 row in SPLIT table | ALIGNED — all three name the `pack-ops/OPTIONAL-FEATURES.md` (pack-side) + `project-template/docs/pack/OPTIONAL-FEATURES.md` (project-side) split with init-project.sh install stage |
| Override 7 KEEP-AT-ROOT in B-fix §12 (M3 + Override 10) — no project-side QUICKSTART created | ALIGNED — B-fix §12 explicitly drops S1; A's design doesn't depend on project-side QUICKSTART (A's OQ-4 punts to B; B-fix-extended honors Override 7) |

**No new cross-doc stale references introduced by the amendments.** I spot-checked:
- All `pack-ops/` references in C cite either B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` or B-fix's `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` — both exist at the cited paths.
- All Override citations (Override 1, 5, 6, 7, 8, 9, 10) in the amended docs reference `AUDIT-USER-CURATION.md` § appropriate numbers — all exist at the cited paths.
- A's cross-reference to "B-fix §16" (in §0 + §2 V4 + §5 + §10.2 + §10.5) — §16 exists in B-fix at lines 944-1015. Verified.
- B-fix §16's cross-reference to "A-fix §10.2" — A's §10.2 exists at lines 755-768. Verified.
- C's cross-reference to "PACK-AGENTS.md:142-148" — line range 140-148 of PACK-AGENTS.md contains the PM-only Files block. Verified.

**No broken anchor links** in any amended cross-reference path. Pack-memory file references (`CLAUDE.md:336-338`) verified at HEAD `8014186`.

**One mild observation (informational, not a defect):** C's §8.2 deny-list row for `HELP-FRAGMENT-TRACKER.md` (line 584) is still marked "Architect-B-conditional — depends on byte-identity status post-B" but B's M2 design has already finalized the byte-identity contract (Check 24 byte-identity preserved between `pack-ops/HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`). This conditional note is mildly stale but does not cause incorrect behavior — Phase 5 coder updating Check 37 reads the current pack-ops/ entry (which includes HELP-FRAGMENT-TRACKER explicitly via §8.2's `pack-ops/` row) and applies the correct deny-list. The pre-existing standalone HELP-FRAGMENT-TRACKER row could be tightened in a future polish pass, but is NOT a finding requiring fix before Phase 4 planner spawn. Documenting as informational only.

---

## §3 — Final go/no-go

**GO.** Phase 4 planner may spawn.

All 12 active reviewer findings (1 BLOCKER + 4 MUST + 6 SHOULD + 1 NIT) and the post-first-fix Override 6 cascade gap are VERIFIED CLOSED across A's, B-fix's (with extension and v2), and C's amended docs. The 3 status-only findings (M1, N3, N4) are correctly handled (M1 deferred to planner spawn prompt as designed; N3, N4 no-action confirmed). N1 is committed.

No new defects introduced. Cross-architect consistency verified. The architect-design set Phase 4 planner reads is consistent: every Override is honored, every cross-reference resolves, every measurable test in C is aligned with the corrected PACK-AGENTS.md:148 PM-only definition, every commit-sequence step in B-fix matches the B-original layout post-v2 amendment.

**Action item Pack Chat must carry forward into Phase 4 planner spawn:** include M1 as a planner constraint (enforce Option A combined M1-M5 + M9-M10 single commit; reject Option B). This is the only carry-forward triage item from the reviewer's findings — no additional architect fix-pass is required before Phase 4.

---

## §4 — End of verification

Phase 3 verification complete. 12 VERIFIED + 0 REMAINING + 0 NEW DEFECTS. GO for Phase 4 planner.

The four architect fix-passes (A: B1 + S1 + S2; B-fix extension: M3 + Override 10 + S3 + N2; C: M2 + M4 + B1-cascade + S4 + S5 + S6; B-fix v2: Override 6 cascade) collectively close every active reviewer finding plus the post-first-fix Override 6 gap. No further architect work required for BD-175 Phase 3. Pack Chat reads this verification report, surfaces M1 to the user as the Phase 4 planner constraint, and spawns Phase 4 planner with the consistent architect-design set.
