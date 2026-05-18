# ARCHITECTURE — Re-litigation framework (BD-175 Phase 2 / Architect A)

**Owner:** pack-architect A (read-only on repo state; no implementation)
**BD:** BD-175 (CODE RED emergency batch)
**Phase:** 2 (DESIGN — per-finding decisions; no implementation)
**Date:** 2026-05-18
**Branch:** v11-dev
**Input audit:** `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` (Phase 1)
**Input curation:** `AUDIT-USER-CURATION.md` (user overrides; wins where it disagrees with audit)
**Boundary foundation:** AUDIT-USER-CURATION.md §5 (user-stated boundary articulation)

---

## §0 — Reading guide

This document is one of three Phase 2 architect deliverables. Its scope is the **content** of each finding (revert / replace / justify) and the **rationale** anchored in the user's boundary articulation. It deliberately does NOT design:

- New pack-only directory homes for relocated files (Architect B's domain).
- CI checks, agent-prompt guardrails, reviewer-protocol amendments (Architect C's domain).
- Refinements to the boundary definition itself (Architect B applies the user's articulation into a formal definition; this doc treats the user's articulation as the ruler).

Where this document recommends an action that REQUIRES a target home (e.g., "relocate X to a pack-only directory"), it specifies the action shape without naming the directory; Architect B picks the home and the Phase 4 planner reconciles.

Where this document depends on Architect B's resolution of audit §F-1 (the `supporting-docs/` classification — specifically whether `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` is reclassified into a pack-only directory), it presents conditional decisions: PRIMARY-IF (Architect B reclassifies) and FALLBACK-IF (Architect B keeps it in `supporting-docs/`). Phase 3 reviewer reconciles the dependency.

---

## §1 — Boundary articulation reduced to operational test

The user's verbatim articulation (AUDIT-USER-CURATION.md §5):

> Files in `project-template/` are for projects and will be in the project dirs. Not necessarily root dirs. They are the product of the config pack. They are not (a) configs used by tools governing the config pack to do its work or (b) config pack operational docs used by the pack to do its work.

Operational test applied per-finding in this framework:

1. **Audience.** Who will read this file when it sits at its installed location (client project, or pack repo)? A project user (developer / project PM chat actor)? Or a pack maintainer (Pack Chat / pack-* agents / pack-coder / pack-architect / pack-reviewer)?
2. **Install path.** Does `init-project.sh` (or any client-install operation) copy this file to a client repo? If yes → project-side surface. If no → pack-only surface.
3. **Reference resolvability.** When the file references another path (e.g., `PACK-AGENTS.md`, `maintenance-docs/...`), does that path exist at the file's installed location? If the file ships to clients and the reference points to a path that exists only at the pack repo, the reference is unresolvable — therefore contamination.
4. **SSOT cascade.** Does the project-side surface have its own SSOT for the information being referenced (e.g., agent roster lives at `project-template/docs/pack/PM-CHAT.md:47 ## Pack agent roster`)? If yes → the project-side reference MUST cite the project-side SSOT, not the pack-side equivalent.

A finding is **CONTAMINATION** when test 1-2 places the file project-side AND test 3-4 reveals an unresolvable or wrong-SSOT reference. A finding is **LEGITIMATE** when the reference is the inter-surface communication mechanism (e.g., `PACK-FEEDBACK.md` documenting the feedback flow TO Pack Chat — cross-surface communication is correct here).

A finding is **MIS-LOCATED CONTENT** when test 1-2 places the file pack-side by audience but it currently lives in a project-side directory (the §F-1 problem: `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` is pack-only content lodged in a project-product directory).

Decision categories used throughout this framework:

- **REVERT** — Remove the contaminating text; restore prior project-side state (where prior state was clean) or remove entirely (where the contaminating reference was never necessary).
- **REPLACE** — Substitute the pack-only reference with the correct project-side SSOT reference. The file remains project-side and continues to serve project audience, but its target SSOT changes.
- **RELOCATE** — Move the file (with its content) to a pack-only directory designated by Architect B. References to it elsewhere update lockstep. (Used only when the content itself is pack-only and the current location is wrong.)
- **JUSTIFY** — Keep the reference as-is because the content is genuinely cross-boundary correct (the audit verdict was wrong, or the reference is legitimate inter-surface communication).
- **DUAL-INSTALL** — Install a copy of the content to project-side AND keep the pack-side source, with appropriate per-surface adaptations (used for content needed at both surfaces, e.g., `OPTIONAL-FEATURES.md` if both pack maintainers and project users need the same walkthrough).
- **SPLIT** — Cleave a single audience-mixed file into two files, one per audience (used for unavoidably-mixed files where neither audience can lose access).

Phase 5 coder reads the decision category + implementation hint and executes.

---

## §2 — §C boundary violations (13 findings)

Each finding from audit §C gets a designed decision below. Severities are reproduced from the audit for context; the framework does not re-grade severity.

### V1 — TYPE-2 pack-bias contamination in project-template trinity (HIGH)

**Audit summary:** Commit `240867d` (2026-05-09) F-7 added `PACK-AGENTS.md` reference into project-template trinity (`project-template/CLAUDE.md:366`, `project-template/AGENTS.md:343`, `project-template/GEMINI.md:356`). Project-side SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md:47 ## Pack agent roster`, and PM-CHAT.md:239 already instructs PM chats to "treat any reference implying a different roster as stale and report it as pack feedback." F-7 introduced exactly the kind of reference that PM-CHAT.md tells PM chats to flag.

**Operational test result:**
- Audience: project-side PM chats (the prose is "PM chat does not architect" — instruction to project actors).
- Install path: trinity files ship to every client repo via `init-project.sh`.
- Reference resolvability: `PACK-AGENTS.md` does not exist at client repos (it lives at pack root only).
- SSOT cascade: project-side SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md:47`.

**Decision: REPLACE.**

**Rationale.** The boundary test fails on three of four axes. The project-side trinity is project-product (clients read it); the referenced file is pack-only and unresolvable at client repos; a project-side SSOT exists. The contamination is not just a broken link — the project-side SSOT (PM-CHAT.md:239) ALREADY instructs PM chats to flag references implying a different roster as stale. F-7's reference is itself a stale-roster-implying reference and triggers the very protection PM-CHAT.md installed. Replace the pack-side ref with the project-side SSOT ref.

**Implementation hint.** In all three trinity files (`project-template/CLAUDE.md:366`, `project-template/AGENTS.md:343`, `project-template/GEMINI.md:356`), replace the parenthetical:

- BEFORE (representative — trinity wording varies slightly): "…the corresponding agent (architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops) — `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster."
- AFTER: "…the corresponding agent. The full pack agent roster is at `docs/pack/PM-CHAT.md` § Pack agent roster — that section is the project-side SSOT; do not infer the roster from any other source."

The trinity rule applies — same edit in all three files in the same commit. Per pack memory, the inline enumeration (`architect / planner / coder / ...`) is itself the T5-A anti-pattern (see V13 below) and should also be removed in this edit; the prose collapses to "the corresponding agent" with the SSOT pointer doing the enumeration work.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) all three trinity files updated symmetrically; (b) no remaining `PACK-AGENTS.md` reference in `project-template/`; (c) the inline enumeration is removed (T5-A coupling); (d) the new SSOT pointer is the bare path `docs/pack/PM-CHAT.md` (resolvable from a client repo root), not a qualified pack-side path.

---

### V2 — TYPE-1 project-side modification during pack-only batch (MEDIUM)

**Audit summary:** Commit `aaa61b3` (2026-05-17, Batch 19b) modified `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (+2 lines at lines 113-114) during a batch the user stated was PACK-ONLY scope. `supporting-docs/` is pack-product per trinity rule. Commit message acknowledged "Manifest regen: NOT NEEDED — supporting-docs/ is not v11-surface per RC9 rule" — the author knew this was outside v11-surface but proceeded.

**Operational test result:**
- The edit itself ADDED pack-internal methodology content (Batch 21c empirical re-confirmation language) to a file whose content is also pack-internal methodology.
- Per §1, this is a content-vs-location mismatch (V4 territory), not a content-vs-audience mismatch. The CONTENT addition is congruent with the file's actual nature; the SCOPE violation is procedural (pack-only-batch-touched-project-side-dir).
- The procedural violation cannot be retroactively fixed by reverting the content — the content is correct for the file even if the file is mis-located.

**Decision: JUSTIFY-CONTENT-PLUS-CASCADE-TO-V4.**

**Rationale.** The +2 lines added by `aaa61b3` are pack-internal methodology language (Batch 21c empirical confirmation of the "test-not-in-CI" heuristic). They belong with the file's existing pack-internal content. The procedural-scope finding is real but the content is correct. The fix to V2 is therefore not a content revert; it is the V4 fix (relocating the entire CONCEPTUAL-REVIEW-METHODOLOGY.md to a pack-only directory). Once V4 ships, the V2 procedural finding becomes archaeology: future pack-only batches that touch the file's NEW pack-only location will be in-scope by construction.

For audit completeness, this framework also notes that the V2 commit message's acknowledgement "supporting-docs/ is not v11-surface per RC9 rule" was a real-time signal that the scope was wrong; Architect C should consider this signal-pattern when designing the "pack-only-batch scope linter" (Architect C domain — not designed here).

**Implementation hint.** No standalone V2 fix. The V4 fix subsumes V2 (the file moves; the content stays). The Phase 5 coder for V4 receives explicit cross-reference to V2 in the planner's task list.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) V2 is documented as "subsumed by V4" — no separate fix task in the planner; (b) the +2-line content from `aaa61b3` is preserved at the new location after V4 relocation; (c) the procedural-scope concern is noted in the Architect C handoff as a signal-pattern for the scope linter design.

---

### V3 — TYPE-4 contamination in project-template/docs/pack/PLATFORM-SKILLS.md (HIGH)

**Audit summary:** `project-template/docs/pack/PLATFORM-SKILLS.md:251` reads "selection. See `PACK-AGENTS.md` in the pack repo for their use." Project-side file installed to client repos referencing pack-only file at pack repo root. Plus `:572` has "(`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" pointer.

**Operational test result:**
- Audience: project-side PM chats (PLATFORM-SKILLS.md is consumed during prompt generation by every PM chat).
- Install path: ships to client repos.
- Reference resolvability: both `PACK-AGENTS.md` and `maintenance-docs/...` are pack-only and unresolvable at clients.
- SSOT cascade: project-side SSOT for the agent roster is `docs/pack/PM-CHAT.md:47` (same as V1). For SKILL-DIMENSIONS architectural rationale, there is no project-side SSOT — the content is genuinely pack-internal design history; project users do not need to read it.

**Decision: REPLACE (for :251 ref) + REVERT (for :572 ref).**

**Rationale.** Two distinct contamination patterns in one file:
- L251 (`PACK-AGENTS.md` ref): same shape as V1. Project users do not need to know about pack-side agents; the project-side roster lives at PM-CHAT.md. REPLACE the parenthetical to point to PM-CHAT.md.
- L572 (`maintenance-docs/.../ARCHITECTURE-SKILL-DIMENSIONS.md` ref): pack-internal architecture history. Project users do not need the rationale link. The information that matters to the project user (which skills load when) is already in PLATFORM-SKILLS.md itself. REVERT — drop the parenthetical or reduce to "(see pack documentation for rationale)" with no pack-side path.

**Implementation hint.**

- L251: BEFORE: "selection. See `PACK-AGENTS.md` in the pack repo for their use."
  AFTER: "selection. See `docs/pack/PM-CHAT.md` § Pack agent roster for the canonical project-side agent list."
- L572: BEFORE: "(`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" + the surrounding rationale parenthetical.
  AFTER: drop the entire parenthetical pointer. If the surrounding prose needs a context anchor, replace with "(see pack documentation if you need the design rationale)" — generic, no path.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) L251 ref replaced with project-side path; (b) L572 ref dropped (or reduced to non-path generic); (c) no other `PACK-AGENTS.md` or `maintenance-docs/...` refs remain in PLATFORM-SKILLS.md (full grep on file before signing off); (d) no broken anchor inside PLATFORM-SKILLS.md prose after the deletions.

---

### V4 — TYPE-4 contamination cluster in supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md (HIGH)

**Audit summary:** Whole-doc pack-only methodology mis-classified as project-side by location. 6 specific contamination sites listed in audit (lines 38, 185, 225, 227, 231, 253). The file's review dimension (d) treats pack-only files (CLAUDE.md, PACK-CHAT.md, pack memory MEMORY.md, ARCHITECTURE-V*.md) as the rule corpus; references pack-only agents (`pack-architect`, `pack-reviewer`); references "Pack Chat" as the orchestrator. Audience: unambiguously pack-internal.

**Operational test result:**
- Audience: pack-internal (the entire content is pack-methodology; it references pack-only architecture history, pack-only agents, pack-only orchestration, pack memory).
- Install path: NOT installed by `init-project.sh` (verified — only `METHODOLOGY.md` and `INSTALL-PROCEDURES.md` are copied from `supporting-docs/` to `project-template/docs/pack/`).
- Reference resolvability: at the file's CURRENT location (`supporting-docs/`), all its pack-side refs resolve because they live in the same pack repo. The problem is the file's location signals "project-product" (per trinity rule classification of `supporting-docs/`) while its content is pack-only.
- SSOT cascade: not relevant — the file IS a pack-only SSOT mis-located.

**Decision: RELOCATE.**

**Rationale.** The file is pack-internal methodology by content, by audience, and by install-path (it does not install to clients). Its current location in `supporting-docs/` is a categorical mistake driven by the location-default contamination pathway described in audit §F-1 (pack maintainers writing pack-internal docs default to `supporting-docs/` because the directory name does not signal "this is project-installed content"). The fix is to move the file to a pack-only directory designated by Architect B. After relocation, every reference in the file (Pack Chat, pack-architect, pack-reviewer, pack memory, ARCHITECTURE-V*.md, maintenance-docs paths) becomes LEGITIMATE pack-internal cross-reference rather than contamination.

This is the SAME decision-shape that subsumes all 11 §D AMBIGUOUS-pending-§F references in this file (see §4 below): once the file moves to a pack-only directory, all 11 refs are LEGITIMATE by construction.

**Dependency on Architect B.** Architect B owns the target home for relocated pack-only docs that currently live in `supporting-docs/`. This framework names the action ("RELOCATE to pack-only directory designated by Architect B") without specifying the target path. If Architect B reclassifies `supporting-docs/` itself as pack-only (per F-1 resolution path A), the file may stay in place with its content unchanged — in that case V4 becomes JUSTIFY (the location is correct after F-1 resolves; the content was already correct). If Architect B splits `supporting-docs/` into project-product and pack-product directories (F-1 resolution path B), the file moves to the pack-product half. If Architect B preserves `supporting-docs/` as project-product and carves out a new pack-internal docs directory (F-1 resolution path C), the file moves there.

**Implementation hint.** Phase 5 coder:
1. Read Architect B's directory architecture decision.
2. Read Phase 4 planner's relocation order (V4 likely moves with V2 absorbed into it, and CONCEPTUAL-REVIEW-METHODOLOGY's path-reference set).
3. Use `git mv` to preserve file history.
4. Update path references to the file (E-5 + §F-1 noted that internal cross-refs use `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` or bare-filename patterns; full grep after move).
5. Do NOT edit the file's content during the move — content was already correct for pack-internal audience; only location was wrong.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) Architect B's design names a target home (this framework does not); (b) the RELOCATE decision is consistent with the F-1 resolution path Architect B chose; (c) the file's content is preserved exactly (including the +2 lines from `aaa61b3` per V2); (d) the path-reference update list is comprehensive (every reference to the old path is updated to the new path in the same commit, per E-5); (e) the file's existing cross-refs (Pack Chat, pack-architect, pack-reviewer, pack memory, maintenance-docs paths) become LEGITIMATE at the new location and need no further edit.

---

### V5 — TYPE-4 contamination in supporting-docs/MERGE-STRATEGY.md (MEDIUM)

**Audit summary:** `:189` "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)." `:472` "`HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips" — pack-only file + pack-only script referenced from project-side. Audit calls this audience-mixed; ambiguity is the underlying issue per §F-1.

**Operational test result:**
- Audience: MERGE-STRATEGY.md self-describes (head L1-L13) as "the user-readable matrix of those rules — what each class does, what kind of customization it preserves, and what to do when the migrator reports a file as needing manual reconciliation." The "user" here is the project user running `migrate-v10-to-v11.sh` or `init-project.sh --update`. Project-side audience.
- Install path: NOT installed by `init-project.sh` (verified — only METHODOLOGY.md and INSTALL-PROCEDURES.md are copied from supporting-docs/). So either the file SHOULD be installed (and currently isn't), or the project user is expected to read it from the pack repo during a migration.
- Reference resolvability: at HEAD, the file lives only in the pack repo, so `pack-architect.md` and `pack-reviewer.md` and `HELP-FRAGMENT-PACK.md` and `validate-pack.py` all resolve. Project user reads from pack repo → references are fine. Project user reads from a client-installed copy (if Architect B decides to install it) → references break.

**Decision: SPLIT-OR-CLARIFY (depends on F-1 + install decision).**

**Rationale.** This file is genuinely audience-mixed in a way that the user's boundary articulation cannot disambiguate without an install-path decision:
- The CONTENT serves project users (per-file class matrix for the migrator).
- The current INSTALL-PATH treats it as pack-internal (not copied to clients).
- The pack-only REFERENCES (`:189`, `:472`) are correct ONLY if the file is pack-internal — they break if the file ships to clients.

The decision splits along Architect B's call on whether MERGE-STRATEGY.md should ship to clients:

- **PRIMARY (recommended): JUSTIFY** with explicit audience header amendment. Architect B keeps MERGE-STRATEGY.md pack-only (not installed). The file's audience-mixed description gets a header amendment: "This document is pack-internal reference for pack maintainers running the migrator. Project users encounter the per-class disposition tokens via `report.md` produced by the migrator; they do not read this file directly." The pack-only refs at `:189` and `:472` become unambiguously LEGITIMATE under this framing.
- **ALTERNATIVE (if Architect B chooses to install it): REPLACE.** Both refs replaced:
  - `:189`: "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)." → "Pack-shipped agent files in the pack repo's `.claude/agents/` and `.codex/agents/` (these are pack-internal; the migrator handles them automatically)."
  - `:472`: "`HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips" → describe the skipped class abstractly (e.g., "pack-only utility files that the migrator does not reconcile per-file") without naming pack-only paths.

**Implementation hint.** Phase 5 coder receives the Architect B install-decision via the planner. If PRIMARY (no install): add the audience header amendment to MERGE-STRATEGY.md L1-L20 area; leave `:189` and `:472` as-is (they are LEGITIMATE post-header-amendment). If ALTERNATIVE (install): apply the BEFORE→AFTER replacements above; verify both new strings render cleanly when the file is read at a client repo.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) the Architect B install-decision for MERGE-STRATEGY.md is documented (this framework does not pre-commit); (b) the V5 fix matches the install-decision; (c) if PRIMARY chosen, the audience header amendment is explicit enough that future pack maintainers do not re-classify the file by ambient confusion; (d) if ALTERNATIVE chosen, no remaining pack-only path references survive in MERGE-STRATEGY.md (full grep on file).

---

### V6 — TYPE-4 references in supporting-docs/MIGRATION-v10-to-v11.md (LOW for :35, MEDIUM for others)

**Audit summary:** Multiple sites:
- `:35`: "`HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`" — pack-only file referenced with "in pack repo" qualifier (LOW).
- `:516`: "Run a Pack Chat session: `/pm-startup` should now report v11" — confusing terminology (MEDIUM).
- `:123`, `:194`, `:225`: "Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" — project-side migration guide pointing into pack-only maintenance-docs (MEDIUM).

**Operational test result:**
- Audience: project user doing v10→v11 migration (verified — file head reads "This guide is the authoritative narrative for upgrading an existing v10-pack-configured project to v11. Two phases…"). Project-side.
- Install path: NOT installed by `init-project.sh` per file enumeration (verified). However, scripts/init-project.sh and migrate-v10-to-v11.sh reference this file by `supporting-docs/MIGRATION-v10-to-v11.md` path in their advisory output (line 1271 of init-project.sh), and validate-pack.py errors reference it. Project users follow the file from the pack repo, then run the migration on their client repo. So: read from pack repo, executed against client repo. Audience-resolvable only at pack repo (cross-surface guide).
- Reference resolvability: the pack-side refs (`HELP-FRAGMENT-PACK.md`, `maintenance-docs/...`) resolve at the file's reading location (pack repo). The `docs/pack/HELP-FRAGMENT.md` ref at :35 is the project-side path that will exist post-migration. The reader is expected to know which path they're at when each reference fires.

**Decision per-site:**

**V6.a (`:35` — LOW). JUSTIFY.** The qualifier "(pack repo)" already disambiguates. The file is read at the pack repo (where the qualifier resolves correctly) and tells the user that `HELP-FRAGMENT-PACK.md` lives there while `docs/pack/HELP-FRAGMENT.md` will exist at the user's client repo after migration. The dual-path pattern is the inter-surface communication this guide must perform. Keep as-is, optionally tighten with one-line clarification (e.g., "you'll read `HELP-FRAGMENT-PACK.md` from the pack repo before running the migrator; afterwards your client repo will have `docs/pack/HELP-FRAGMENT.md`").

**V6.b (`:516` — MEDIUM). REPLACE.** "Run a Pack Chat session" is wrong terminology. "Pack Chat" is the pack-repo orchestrator (operates on the pack repo); project users running the migration on their client repo open a "PM Chat" session (project-repo orchestrator). The terminology contamination misleads the user about which chat-mode to start.

- BEFORE: "Run a Pack Chat session: `/pm-startup` should now report v11 as the active pack version…"
- AFTER: "Open a PM Chat session in your client project: `/pm-startup` should now report v11 as the active pack version…"

**V6.c (`:123`, `:194`, `:225` — MEDIUM). REVERT each.** Each reads "Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §N.M, …". The architectural rationale these refs cite is pack-internal design history; the project user doing migration does not need to read it. The narrative around each ref (the surrounding sentence) ALREADY explains the behavioral consequence for the user; the pack-side citation adds nothing the user can act on. Drop the leading "Per `maintenance-docs/...` §N.M, " from each — the sentence stands without it. If a generic anchor is wanted for the curious, replace with "(documented in pack design history)" — no path.

**Implementation hint.**

- L35: tighten phrasing or leave; LOW priority.
- L516: replace "Pack Chat session" → "PM Chat session in your client project" (or equivalent).
- L123, L194, L225: drop the leading "Per `maintenance-docs/...` §..., " prefix from each sentence. Sentences continue to make sense without the prefix (verified — the prose around each ref describes the behavior in terms the user can act on).

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) `:516` no longer says "Pack Chat" in the project-user-facing instruction; (b) `:123`, `:194`, `:225` no longer cite pack-only paths; (c) no remaining `maintenance-docs/` references in MIGRATION-v10-to-v11.md (full grep on file); (d) `:35` either kept with tightened phrasing or replaced with cleaner dual-path explanation; (e) the file's narrative still makes sense end-to-end after the edits (sample-read the file's three modified sections in context).

---

### V7 — TYPE-4 in project-template/skills/audit-methodology/SKILL.md (MEDIUM)

**Audit summary:** `:51` and `:106` both reference `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` — project-side skill (installed to client repos via `init-project.sh` skill-tree copy) referencing pack-only maintenance-docs path.

**Operational test result:**
- Audience: project-side agents (auditor agents at the client repo consume audit-methodology SKILL).
- Install path: `project-template/skills/audit-methodology/SKILL.md` IS the canonical source-of-truth for the SKILL; `init-project.sh` merges from `project-template/skills/` into the client repo's per-CLI skill trees. Installed to clients.
- Reference resolvability: `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` does not exist at client repos.
- SSOT cascade: not relevant — the references are inline "see also" forward-pointers to a pack-internal research doc. The behavioral content the SKILL needs (Apple-centric detection markers + "non-Apple UI deferred to a future version") is already in the SKILL body.

**Decision: REVERT both refs.**

**Rationale.** Same shape as V3.b (the L572 PLATFORM-SKILLS.md case): pack-internal research history that adds no actionable information for project-side agents reading the SKILL at a client repo. The SKILL's existing prose already says "deferred to a future version (currently planned post-v11.0)" — that is enough for the project-side auditor. Drop the pack-side path reference; keep the deferral language.

**Implementation hint.**

- L51: BEFORE: "…currently planned post-v11.0 — see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`):"
  AFTER: "…currently planned post-v11.0):"
- L106: BEFORE: "…currently planned post-v11.0 — see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` for the in-flight design); once those skills land, this detection list extends to include their markers."
  AFTER: "…currently planned post-v11.0); once those skills land, this detection list extends to include their markers."

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) both `RESEARCH-NON-APPLE-UI-SKILLS.md` references removed from `project-template/skills/audit-methodology/SKILL.md`; (b) the surrounding prose still reads cleanly; (c) no other `maintenance-docs/` references in `project-template/skills/`-tree (full grep across all 35 skill subdirs).

---

### V8 — TYPE-4 in project-template trinity (TOOL-COMPARISON pointer) (MEDIUM)

**Audit summary:** `project-template/CLAUDE.md:397`, `project-template/AGENTS.md:374`, `project-template/GEMINI.md:387` all end with "*For deeper agent-by-agent comparison (e.g., when to use auditor vs. reviewer vs. docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*" Audit calls this MEDIUM (qualified with "in the pack's" but still expects client PM chats to fetch from pack repo). Confirmed pre-v11 origin: introduced by commit `5035328` (v9-dev, 2026-04-12); persisted into v11 by virtue of being present at HEAD.

**Operational test result:**
- Audience: project-side PM chats (trinity is project-product).
- Install path: trinity ships to clients.
- Reference resolvability: `TOOL-COMPARISON.md` lives at `maintenance-docs/TOOL-COMPARISON.md` (verified) and does not exist at client repos.
- SSOT cascade: the trinity's preceding table (phase routing — quality-optimized defaults) is the SSOT for tool routing at the project surface. The pointer is "for deeper comparison" — supplementary content; nothing in the project-side workflow strictly requires it.

**Decision: REVERT.**

**Rationale.** The qualifier "in the pack's" makes the misdirection slightly less harmful than V1 (the user knows it's not local), but the pointer still asks a client PM chat to fetch a pack-only doc to do its work. Project PM chats should not need to read pack-internal architectural reasoning to operate. The preceding routing table is the actionable SSOT; the pointer adds nothing the project user can act on without leaving their repo. Drop the pointer entirely (do not REPLACE — there is no project-side equivalent of TOOL-COMPARISON.md, and a project-side equivalent is not warranted because the routing-table itself is the project-side SSOT).

**Implementation hint.** In all three trinity files, delete the italicized paragraph (line numbers may shift after V1 edit; identify by content match):

- DELETE: "*For deeper agent-by-agent comparison (e.g., when to use auditor vs. reviewer vs. docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*"

Trinity rule — delete in all three files in the same commit. Sequence note: V8 + V1 both edit the trinity; planner should combine them into a single trinity-edit commit to avoid two consecutive trinity touches (and to single-shot the manifest regen + trinity parity check).

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) all three trinity files have the italicized paragraph removed; (b) trinity rule applied (all three changed in the same commit); (c) no remaining `TOOL-COMPARISON.md` references in `project-template/` (full grep); (d) the preceding routing-table section reads cleanly without the deleted paragraph; (e) if V1 and V8 are combined per planner sequence, both V1 and V8 verifications pass on the same combined diff.

---

### V9 — TYPE-1 LOW: cf67a96 BD-169 pack-product wording updates

**Audit summary:** Commit `cf67a96` modified 7+ project-side files alongside 2 pack-side files. Subject self-describes "pack-product wording updates" — implying project-side touches are IN SCOPE. Audit calls this LOW (subject was honest about mixed scope) but flagged for content audit (whether each project-side edit independently made sense for project-side audience).

**Operational test result:**
- Audit did not find specific contamination content in the project-side files modified by this commit (V9 is a SCOPE flag, not a CONTENT flag).
- The CONTENT contaminations in `cf67a96`-affected files (`project-template/skills/audit-methodology/SKILL.md` per V7; `supporting-docs/MERGE-STRATEGY.md` per V5; `supporting-docs/MIGRATION-v10-to-v11.md` per V6) are caught by V5/V6/V7 directly.

**Decision: JUSTIFY (content) + CASCADE to V5/V6/V7 (procedural).**

**Rationale.** The commit's mixed scope was honestly declared; no scope-deception finding. The content concerns surface elsewhere (V5/V6/V7) and are designed there. V9 itself requires no standalone fix. Architect C may use the V9 pattern as a signal-design input ("commits that touch multiple audience-surfaces should fire a scope-check; declared-mixed-scope is fine, undeclared-mixed-scope is the problem") — that is Architect C's domain, not designed here.

**Implementation hint.** No standalone V9 fix.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) V9 is documented as cascading to V5/V6/V7; (b) no separate V9 task in the planner; (c) the V9 commit's content edits are individually re-validated under V5/V6/V7 verification.

---

### V10 — TYPE-1 MEDIUM: 8ba0164 BD-167b PM-only-edits misrepresented scope

**Audit summary:** Commit `8ba0164` subject says "BD-167b per-entry split PM-only edits". "PM-only" in pack memory means files Pack Chat may edit directly. Per memory, project-template trinity is NOT PM-only. Yet `8ba0164` edited `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`. Misrepresentation of scope; project-template trinity edits should have gone through fix-coder per pack memory rule.

**Operational test result:**
- Procedural violation (Pack Chat directly edited files outside its permission scope).
- CONTENT examination: the BD-167b project-template trinity edits were per-entry-split-related (Key files section + Document locations). Need to verify whether the content edits are correct for project-side audience independent of the procedural violation.

**Decision: VERIFY-THEN-JUSTIFY-OR-REPLACE.**

**Rationale.** The procedural violation cannot be undone (the commit is in history; reverting would lose legitimate per-entry-split content). The fix is forward-looking: (a) audit the trinity content from BD-167b for any project-side audience mismatch; (b) if mismatch found, REPLACE per V1/V8 pattern; (c) if no mismatch, JUSTIFY (content is correct even though the edit path was wrong). Architect C should use V10 as a signal-pattern for the "PM-only-claim scope-linter" design (Architect C domain, not here).

**Implementation hint.** Phase 5 task: read commit `8ba0164` diff for `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, classify each hunk:
- If hunk content is correct for project-side audience → no edit needed (JUSTIFY).
- If hunk content references pack-only paths or pack-only mechanisms in a way V1/V3/V8 would flag → apply REPLACE per the matching V pattern.

This is a per-hunk audit, not a blanket revert.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) every hunk of `8ba0164` project-template trinity diff is classified (JUSTIFY or REPLACE); (b) any REPLACE applied matches the V1/V3/V8 patterns; (c) no project-side audience mismatch survives in the trinity after the audit; (d) Architect C's prevention design references V10 as a signal-pattern source.

---

### V11 — LOW completeness note (`30a1bc3` broad batch review/fix Batch 19b)

**Audit summary:** Subject "fix: v11 — broad batch review/fix (Batch 19b)". Touched only pack-only files. No violation — listed for completeness.

**Decision: NO ACTION.**

**Rationale.** Audit confirmed clean. No re-litigation needed.

**Reviewer independence-check.** Phase 3 reviewer verifies: V11 has no task in the planner.

---

### V12 — LOW completeness note (`479fef5` Batch 19 broad review/fix)

**Audit summary:** Subject "fix: v11 — Batch 19 broad review/fix". Touched pack-only files. No project-template touches. No violation.

**Decision: NO ACTION.**

**Rationale.** Audit confirmed clean. No re-litigation needed.

**Reviewer independence-check.** Phase 3 reviewer verifies: V12 has no task in the planner.

---

### T5-A — HIGH heuristic: Project trinity copied pack agent-list rule

**Audit summary:** The trinity contains a static enumeration of agent roles (architect / planner / coder / ... / repo-ops). Project-side SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md:47`. Trinity-level static enumeration creates two sources of truth and a stale-pointer risk; V1 made this worse. Independent project-design rationale would say: "let PM-CHAT.md own the roster; don't enumerate it inline in trinity."

**Operational test result:**
- The enumeration is a duplicate of PM-CHAT.md's SSOT.
- It is statically embedded in trinity (three files) and so drifts independently if PM-CHAT.md changes (which DID happen — the trinity enumeration today omits the auditor-* variants that PM-CHAT.md correctly lists).
- The enumeration is the substrate that V1 contamination grew on (the F-7 fix-follow grew a `PACK-AGENTS.md` ref out of the enumeration because the enumeration looked incomplete and the fixer reached for the pack-side roster).

**Decision: REVERT (remove the inline enumeration) — coupled to V1's REPLACE.**

**Rationale.** The enumeration is the structural defect; V1 is the surface contamination growth on top. Removing the enumeration and replacing with a single pointer to PM-CHAT.md (per V1's REPLACE) closes both findings. The trinity's prose collapses from "(architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops) — `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster" to "the corresponding agent. The full pack agent roster is at `docs/pack/PM-CHAT.md` § Pack agent roster — that section is the project-side SSOT; do not infer the roster from any other source." This is the V1 + T5-A combined edit.

**Implementation hint.** Same edit as V1 (which already specified removing the inline enumeration as part of the V1 REPLACE). V1 and T5-A ship in the same hunk in each trinity file. Phase 5 coder receives V1 and T5-A as a single task; planner does not split them.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) the V1 reviewer-check covers T5-A (V1 acceptance requires the enumeration removal); (b) no separate T5-A task in the planner — the planner explicitly notes T5-A as part of V1.

---

### T5-B — MEDIUM heuristic: supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md mirrors PACK-CHAT/MEMORY structure

**Audit summary:** Doc's review dimensions (a-f) and "Pack rule adherence" (dimension d) reference pack-only files (CLAUDE.md, PACK-CHAT.md, pack memory MEMORY.md). If project-side, dimension (d) would reference project-side equivalents. Structural mirror without project-design rationale; suggests doc was written for pack-internal use and dropped into supporting-docs by location-default.

**Operational test result:**
- Same root cause as V4 (file is pack-only content in a project-side directory).
- T5-B is the META-heuristic showing T4-V4 is not just a few stray references but a structural mismatch.

**Decision: SUBSUMED BY V4 (RELOCATE).**

**Rationale.** Once the file moves to a pack-only directory per V4, every dimension and reference becomes LEGITIMATE pack-internal cross-reference. T5-B is descriptively correct (the file mirrors pack-internal structure) but the corrective action is the same as V4. No standalone T5-B task.

**Implementation hint.** No standalone T5-B fix. The V4 RELOCATE absorbs T5-B.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) T5-B has no separate task; (b) the V4 verification's "content preserved exactly" covers T5-B (the mirrored structure stays — only the location changes, which makes the mirror legitimate).

---

## §3 — §D confirmed CONTAMINATION references (17 hits)

Per audit §D-9 aggregation: 4 (D-1) + 1 (D-4) + 9 (D-5) + 1 (D-7) + 2 (D-8) = 17 confirmed CONTAMINATION references concentrated in 6 files. Each hit gets a designed action below. Many are subsumed by §C V-decisions above; this section names the cascade explicitly.

### §3.1 — D-1 (4 hits, PACK-AGENTS.md refs)

| Hit | Site | Cascade |
|---|---|---|
| D1.1 | `project-template/CLAUDE.md:366` | Subsumed by V1 + T5-A REPLACE |
| D1.2 | `project-template/AGENTS.md:343` | Subsumed by V1 + T5-A REPLACE (trinity parallel) |
| D1.3 | `project-template/GEMINI.md:356` | Subsumed by V1 + T5-A REPLACE (trinity parallel) |
| D1.4 | `project-template/docs/pack/PLATFORM-SKILLS.md:251` | Subsumed by V3 REPLACE |

**Decision for all 4: SUBSUMED — no standalone tasks.** Phase 5 planner notes the cascade in the V1 and V3 task descriptions.

---

### §3.2 — D-4 (1 hit, "Pack Chat" terminology contamination)

| Hit | Site | Cascade |
|---|---|---|
| D4.1 | `supporting-docs/MIGRATION-v10-to-v11.md:516` | Subsumed by V6.b REPLACE |

**Decision: SUBSUMED.**

---

### §3.3 — D-5 (9 hits, maintenance-docs/ refs from project-side)

| Hit | Site | Decision | Cascade |
|---|---|---|---|
| D5.1 | `project-template/CLAUDE.md:397` | REVERT | Subsumed by V8 |
| D5.2 | `project-template/AGENTS.md:374` | REVERT | Subsumed by V8 (trinity parallel) |
| D5.3 | `project-template/GEMINI.md:387` | REVERT | Subsumed by V8 (trinity parallel) |
| D5.4 | `project-template/docs/pack/PLATFORM-SKILLS.md:572` | REVERT | Subsumed by V3 (L572 sub-decision) |
| D5.5 | `project-template/skills/audit-methodology/SKILL.md:51` | REVERT | Subsumed by V7 |
| D5.6 | `project-template/skills/audit-methodology/SKILL.md:106` | REVERT | Subsumed by V7 |
| D5.7 | `supporting-docs/MIGRATION-v10-to-v11.md:123` | REVERT | Subsumed by V6.c |
| D5.8 | `supporting-docs/MIGRATION-v10-to-v11.md:194` | REVERT | Subsumed by V6.c |
| D5.9 | `supporting-docs/MIGRATION-v10-to-v11.md:225` | REVERT | Subsumed by V6.c |

**Decision for all 9: SUBSUMED — no standalone tasks.** Phase 5 planner notes the V3/V6/V7/V8 cascade.

---

### §3.4 — D-7 (1 hit, HELP-FRAGMENT-PACK.md ref from project-side)

| Hit | Site | Cascade |
|---|---|---|
| D7.1 | `supporting-docs/MERGE-STRATEGY.md:472` | Subsumed by V5 (whichever variant Architect B chooses) |

**Decision: SUBSUMED.**

---

### §3.5 — D-8 (2 confirmed CONTAMINATION hits — OPTIONAL-FEATURES from project-side)

| Hit | Site | Cascade |
|---|---|---|
| D8.6 | `supporting-docs/MERGE-STRATEGY.md:465` | Decision below (NEW) |
| D8.7 | `supporting-docs/DEPENDENCIES.md:162` | Decision below (NEW) |

These are not subsumed by §C V-decisions. Designed standalone:

**D8.6 — `supporting-docs/MERGE-STRATEGY.md:465` "`OPTIONAL-FEATURES.md` — tracker opt-in walkthrough"**

Same audience analysis as V5 (MERGE-STRATEGY is project-side audience by content but currently not installed). Decision splits on Architect B's MERGE-STRATEGY install decision AND Architect B's OPTIONAL-FEATURES placement decision (F-5):
- **If MERGE-STRATEGY stays pack-only (V5 PRIMARY) AND OPTIONAL-FEATURES stays at pack root or moves to pack-only directory:** JUSTIFY (pack-only doc referencing pack-only doc).
- **If MERGE-STRATEGY ships to clients (V5 ALTERNATIVE) AND OPTIONAL-FEATURES is installed to client `docs/pack/`:** REPLACE — change `OPTIONAL-FEATURES.md` to `docs/pack/OPTIONAL-FEATURES.md`.
- **If MERGE-STRATEGY ships to clients but OPTIONAL-FEATURES does not:** REVERT — drop the line (project user at client repo cannot follow this pointer).

**D8.7 — `supporting-docs/DEPENDENCIES.md:162` "See `OPTIONAL-FEATURES.md` § 'Tracker integration (v11)' for the full"**

DEPENDENCIES.md is project-side install-reference content (verified — file head names "all tools required or optionally used by the AI Agent Config Pack"). Audience: project users running bootstrap. Not currently installed to clients. Same multi-axis dependency as D8.6.

Both D8.6 and D8.7 depend on Architect B's F-5 resolution (the OPTIONAL-FEATURES install-path question). This framework recommends:

**Recommended path for both D8.6 and D8.7: DUAL-INSTALL OPTIONAL-FEATURES.md.** Install OPTIONAL-FEATURES.md to `project-template/docs/pack/OPTIONAL-FEATURES.md` (so client repos have it) AND keep the pack-root copy (so pack maintainers can read it without leaving the pack repo). Then REPLACE both D8.6 and D8.7 references with `docs/pack/OPTIONAL-FEATURES.md` (which resolves at client repos). This recommendation derives from the audit's §D-8 observation that ~5 project-side files ALREADY reference `docs/pack/OPTIONAL-FEATURES.md` as if the file existed there — they fail today; DUAL-INSTALL makes them succeed. (The 5 other §D-8 references resolve under §4 AMBIGUOUS-other.)

**Implementation hint.** For DUAL-INSTALL path: Architect B picks the canonical SSOT (pack root or project-template); Phase 5 coder copies/syncs to the other surface; init-project.sh updated to install the project-template copy to client `docs/pack/` (likely already in S6 loop pattern that handles METHODOLOGY.md and INSTALL-PROCEDURES.md). For D8.6/D8.7 specifically: update the references to `docs/pack/OPTIONAL-FEATURES.md` (path that resolves at client repos).

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) Architect B's F-5 resolution is documented; (b) D8.6 and D8.7 fixes match the F-5 resolution; (c) under the DUAL-INSTALL path, the project-template copy of OPTIONAL-FEATURES.md is byte-identical to the pack-root copy (or carries an explicit divergence contract); (d) init-project.sh updated to install the project-template copy.

---

### §3 totals reconciliation

- D-1: 4 hits → 4 SUBSUMED (V1 + T5-A or V3)
- D-4: 1 hit → 1 SUBSUMED (V6.b)
- D-5: 9 hits → 9 SUBSUMED (V3, V6.c, V7, V8)
- D-7: 1 hit → 1 SUBSUMED (V5)
- D-8: 2 hits → 2 NEW DECISIONS (D8.6, D8.7 — both depend on Architect B F-5)

**§3 total: 17 confirmed CONTAMINATION references. 15 subsumed; 2 new standalone decisions.** All 17 have designed actions.

---

## §4 — §D AMBIGUOUS-other references (8 hits)

These hits the audit could not classify CONTAMINATION-or-LEGITIMATE without further judgment. Per-finding verdict below.

### A1 — `supporting-docs/MERGE-STRATEGY.md:189` "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)"

**Verdict: AMBIGUOUS → CONTAMINATION-OR-LEGITIMATE depending on Architect B's MERGE-STRATEGY install decision.**

**Reasoning.** Same shape as V5 (this hit is V5's `:189` site, audit §D-3). Cascade to V5 — no standalone decision needed. If V5 PRIMARY (pack-only), this becomes LEGITIMATE under the audience header amendment. If V5 ALTERNATIVE (install to clients), this becomes CONTAMINATION and is REPLACED per V5 ALTERNATIVE.

**Decision: SUBSUMED by V5.**

---

### A2 — `supporting-docs/METHODOLOGY.md:1509` "*Source: maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*"

**Verdict: CONTAMINATION (mild).**

**Reasoning.** METHODOLOGY.md IS installed to clients (per `init-project.sh:565-570`). The reference is a historical attribution citing a pack-internal `maintenance-docs/origins/` path. At a client repo, the path is unresolvable. The attribution itself is correct (it's the source material origin) but the path is wrong for the file's installed location.

**Decision: REPLACE-OR-REVERT.**

The attribution is a "source material" note (italicized, citation-style). Two options:
- REPLACE: drop the path, keep the document name. E.g., "*Source: Claude-Assisted Project Methodology Guide v1 (pack-archived design source)*."
- REVERT: drop the entire italicized attribution.

**Recommended: REPLACE.** Attribution is valuable historical context; removing it loses provenance. Keeping the path is wrong because it breaks at clients.

**Implementation hint.** Edit METHODOLOGY.md:1509 to remove the `maintenance-docs/origins/` path; keep the descriptive name.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) no `maintenance-docs/` paths remain in METHODOLOGY.md (full grep); (b) attribution remains in some form (history preserved); (c) the file reads cleanly at client repos.

---

### A3 — `supporting-docs/MIGRATION-v10-to-v11.md:35` "`HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`"

**Verdict: LEGITIMATE (qualified-dual-path is the right pattern for migration guides).**

**Decision: SUBSUMED by V6.a (JUSTIFY, optionally tighten phrasing).**

---

### A4 — `project-template/.gemini/commands/pack-help.toml:12` "docs/pack/OPTIONAL-FEATURES.md."

**Verdict: CONTAMINATION (today) → LEGITIMATE (under DUAL-INSTALL of OPTIONAL-FEATURES per F-5).**

**Reasoning.** Project-side file (installed to client `.gemini/commands/`). References `docs/pack/OPTIONAL-FEATURES.md` as if installed at client. Currently broken — no `OPTIONAL-FEATURES.md` exists under `project-template/docs/pack/`. The 5 similar references (A4, A5, A6, A7, A8 below) are the §D-8 installed-path-mismatch pattern.

**Decision: DEPENDS ON F-5 RESOLUTION.**

- If F-5 resolves DUAL-INSTALL (per D8.6/D8.7 recommendation): LEGITIMATE — no edit needed (the reference will resolve once `docs/pack/OPTIONAL-FEATURES.md` exists at clients).
- If F-5 resolves keep-at-pack-root-only: REVERT — drop the reference (client can't resolve it).
- If F-5 resolves relocate-to-pack-only-dir: REVERT — drop the reference (client can't resolve it).

**Recommended: DUAL-INSTALL (per D8.6 reasoning).** Makes A4-A8 all LEGITIMATE without per-file edits.

**Implementation hint.** Under DUAL-INSTALL path: no edit to A4. Under other paths: drop the reference (or replace with generic pack-side qualifier — but qualifier-style is worse UX for project users).

**Reviewer independence-check.** Phase 3 reviewer verifies F-5 cascade matches the chosen path for A4-A8 consistently.

---

### A5 — `project-template/.claude/skills/pack-help/SKILL.md:15` "`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`"

**Verdict: same as A4.**

**Decision: same as A4 — DEPENDS ON F-5 RESOLUTION; recommended DUAL-INSTALL → LEGITIMATE.**

---

### A6 — `project-template/.codex/skills/pack-help/SKILL.md:15` "Same path ref"

**Verdict: same as A4.**

**Decision: same as A4 — DEPENDS ON F-5 RESOLUTION; recommended DUAL-INSTALL → LEGITIMATE.**

---

### A7 — `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` "See ... and `OPTIONAL-FEATURES.md` for full setup."

**Verdict: same as A4 (bare filename instead of qualified path, but same resolvability question).**

**Decision: same as A4 — DEPENDS ON F-5 RESOLUTION; recommended DUAL-INSTALL → LEGITIMATE.** Under DUAL-INSTALL, the bare filename resolves relative to the file's directory (`project-template/docs/pack/`) where `OPTIONAL-FEATURES.md` will exist.

---

### A8 — `project-template/docs/pack/HELP-FRAGMENT.md:6` and `:33` "`docs/pack/OPTIONAL-FEATURES.md`"

**Verdict: same as A4.**

**Decision: same as A4 — DEPENDS ON F-5 RESOLUTION; recommended DUAL-INSTALL → LEGITIMATE.** Note: two sites in same file; both resolve under DUAL-INSTALL with no edits.

---

### §4 totals reconciliation

- A1: SUBSUMED by V5
- A2: NEW DECISION (REPLACE METHODOLOGY.md:1509)
- A3: SUBSUMED by V6.a
- A4-A8: NEW DECISION cluster (5 OPTIONAL-FEATURES references) → all become LEGITIMATE under recommended DUAL-INSTALL path; alternate paths REVERT all 5.

**§4 total: 8 AMBIGUOUS-other. 2 SUBSUMED; 6 NEW DECISIONS (1 standalone METHODOLOGY edit + 5 OPTIONAL-FEATURES cluster).** All 8 have designed verdicts.

**Aggregate dependency on Architect B for §4:** A4-A8 (5 hits) depend on F-5 resolution. This framework recommends DUAL-INSTALL but defers the call to Architect B.

---

## §5 — §D AMBIGUOUS-pending-§F references (11 hits)

All 11 hits cluster in a single file: `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Per audit §D-2 + §D-3 + §D-4 + §D-5 + §D-9, the 11 hits are:

| # | Site | Audit category |
|---|---|---|
| F1.1 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:38` | D-2 (`PACK-CHAT.md` ref) |
| F1.2 | `:185` | D-2 (`PACK-CHAT.md` ref) |
| F1.3 | `:225` | D-3 (`pack-architect` ref) |
| F1.4 | `:227` | D-3 (`pack-reviewer` ref) |
| F1.5 | `:231` | D-4 ("Pack Chat" orchestrator ref) |
| F1.6 | `:253` | D-4 ("Pack Chat" orchestrator ref) |
| F1.7 | `:268` | D-5 (`maintenance-docs/v{N}-implementation/` path ref) |
| F1.8 | `:281` | D-5 (`maintenance-docs/v{N}-implementation/` path ref) |
| F1.9 | `:293` | D-5 (`maintenance-docs/v{N}-implementation/` path ref) |
| F1.10 | `:38` Architecture refs (`ARCHITECTURE-V*.md` family) | D-2 ("Reference: ... `ARCHITECTURE-V*.md` family") |
| F1.11 | `:38` MEMORY refs (`pack memory MEMORY.md`) | D-2 ("Reference: ... pack memory `MEMORY.md` index + linked feedback files") |

**Single resolution path for all 11: SUBSUMED by V4 RELOCATE.**

**Reasoning.** Per §1 operational test applied to the file:
- Audience: pack-internal (entire content is pack methodology; references pack-only architecture history, pack-only agents, pack-only orchestration, pack memory).
- Install path: NOT installed to clients (verified).
- The file's location in `supporting-docs/` is the categorical mistake (per V4 decision).
- Once the file moves to a pack-only directory (per V4 RELOCATE), all 11 references become LEGITIMATE pack-internal cross-references by construction.

**Conditional fallback if Architect B's F-1 resolution KEEPS the file in `supporting-docs/`:**

If, despite the operational test, Architect B chooses to keep CONCEPTUAL-REVIEW-METHODOLOGY.md in `supporting-docs/` (e.g., by reclassifying `supporting-docs/` itself as pack-internal — F-1 resolution path A — or by some other rationale), all 11 references remain in place AS-IS and become LEGITIMATE under the reclassification.

In this case, V4 RELOCATE collapses to V4 JUSTIFY (the location is reclassified-correct; the content was already correct). The 11 references become LEGITIMATE without any per-file edit.

**Conditional fallback if Architect B's F-1 resolution KEEPS supporting-docs/ as project-product AND CONCEPTUAL-REVIEW-METHODOLOGY.md is RE-WRITTEN for project-side audience instead of relocated:**

This is the worst-case path — it would convert all 11 references from AMBIGUOUS to HIGH-priority CONTAMINATION requiring per-ref REPLACE or REVERT. This framework strongly recommends against this path because:
- The file is unambiguously pack-internal methodology by content;
- There is no project-side equivalent of the "Pack Chat" orchestrator, "pack-architect", "pack-reviewer", "pack memory MEMORY.md", or pack-internal "ARCHITECTURE-V*.md" architecture history;
- Re-writing the entire file for project-side audience would lose the methodology content (no equivalent target audience exists at the project side);
- The audit's T5-B finding (structural mirror of pack-internal patterns) is the same evidence base — re-writing for project side would require inventing project-side equivalents that do not exist.

If Architect B nonetheless chooses this path, this framework defers and recommends a SPLIT: relocate the methodology content to pack-only and leave a project-side stub at `supporting-docs/` describing project-side conceptual-review patterns (if/when they exist). The stub design is outside this framework's scope.

**Decision: SUBSUMED by V4 (under PRIMARY V4 RELOCATE) OR SUBSUMED by V4-collapsed-to-JUSTIFY (under F-1 path A).** Either way, no per-reference standalone tasks. The 11 references all resolve as LEGITIMATE post-V4.

**Phase 3 reviewer reconciliation note.** This framework's §5 decision IS the dependency on Architect B's F-1 resolution. Phase 3 reviewer:
- Reads Architect B's F-1 resolution.
- Verifies V4 + §5 path matches the F-1 resolution.
- If F-1 resolves on a path this framework strongly recommends against (the "re-write for project-side audience" path), the reviewer surfaces the conflict as a BLOCKER finding back to Pack Chat for user reconciliation. This framework's recommendation is non-binding; only the user can override.

**§5 total: 11 AMBIGUOUS-pending-§F. All 11 SUBSUMED by V4 under any F-1 resolution path.** Designed actions exist for all 11 regardless of F-1 outcome.

---

## §6 — Cascade and sequencing summary (for Phase 4 planner)

This framework does NOT plan implementation sequencing (Phase 4 planner's domain), but the design has the following cascade constraints that the planner must honor:

### 6.1 Combined tasks (must ship together)

- **TASK-T1 (trinity edit):** V1 + T5-A + V8 together. All three findings edit the same trinity files (`project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md`). Single commit; trinity rule applies; manifest regeneration triggers per RC9.
- **TASK-T2 (PLATFORM-SKILLS edit):** V3.a (L251 REPLACE) + V3.b (L572 REVERT) together. Same file; single commit.
- **TASK-T3 (audit-methodology SKILL edit):** V7 (L51 + L106 REVERT). Same file; single commit.
- **TASK-T4 (MIGRATION-v10-to-v11 edit):** V6.a (L35 tighten) + V6.b (L516 REPLACE) + V6.c (L123 + L194 + L225 REVERT) together. Same file; single commit. Also covers D5.7/D5.8/D5.9 and D4.1.
- **TASK-T5 (MERGE-STRATEGY edit):** V5 (audience header amendment OR per-ref replacement). Includes A1 (`:189`) and D7.1 (`:472`) and D8.6 (`:465`).
- **TASK-T6 (METHODOLOGY edit):** A2 (`:1509` historical attribution REPLACE).
- **TASK-T7 (CONCEPTUAL-REVIEW-METHODOLOGY RELOCATE):** V4 + V2-cascade + T5-B + §5 11-ref cluster. Single relocate operation; content preserved; all 11 ambiguous-pending-§F refs become LEGITIMATE by construction.
- **TASK-T8 (OPTIONAL-FEATURES DUAL-INSTALL — if Architect B chooses):** D8.7 (DEPENDENCIES.md `:162`) + D8.6 (MERGE-STRATEGY `:465`) + A4-A8 (5 project-side refs) + the install plumbing. May need a separate task for the install plumbing (init-project.sh edit) followed by the per-file ref updates.

### 6.2 Sequencing constraints

- TASK-T7 (RELOCATE) and TASK-T5 (MERGE-STRATEGY edit) both depend on Architect B's F-1 resolution. T7 needs the target directory; T5 needs the install decision. Both must wait on Architect B's design.
- TASK-T8 (OPTIONAL-FEATURES) depends on Architect B's F-5 resolution.
- TASK-T1 / T2 / T3 / T4 / T6 do not depend on Architect B and can sequence first if the planner wants early wins.
- TASK-T1 should ship BEFORE any further trinity edits in unrelated BDs (so the v11 trinity reflects the corrected guidance for any new project that installs during v11.0).

### 6.3 Pure-cascade findings (no standalone task)

- V2: subsumed by V4 task content preservation.
- V9: subsumed by V5/V6/V7 (no standalone fix).
- V10: VERIFY task — per-hunk audit of `8ba0164` against project-template trinity; may yield zero edits if all hunks are JUSTIFY; may yield 1-N edits if any hunks need REPLACE.
- V11, V12: NO ACTION (audit confirmed clean).
- T5-A: subsumed by V1.
- T5-B: subsumed by V4.

### 6.4 Manifest regeneration triggers (per pack memory RC9)

The following tasks touch `project-template/` or `scripts/` and trigger manifest regeneration:

- TASK-T1 (project-template/CLAUDE.md + AGENTS.md + GEMINI.md): triggers regen.
- TASK-T2 (project-template/docs/pack/PLATFORM-SKILLS.md): triggers regen.
- TASK-T3 (project-template/skills/audit-methodology/SKILL.md): triggers regen.
- TASK-T7 (CONCEPTUAL-REVIEW-METHODOLOGY relocation): depends on target — if target is under `project-template/`, triggers; if under another pack-only dir, may or may not trigger (Architect B's directory choice determines).
- TASK-T8 (init-project.sh edit if chosen): triggers regen.

V10's VERIFY task triggers regen only if it yields project-template edits.

TASK-T4 (MIGRATION-v10-to-v11.md), TASK-T5 (MERGE-STRATEGY.md), TASK-T6 (METHODOLOGY.md): all live in `supporting-docs/` — do NOT trigger manifest regen per RC9 base-case rule (`supporting-docs/` is not v11-surface for the manifest).

### 6.5 Out-of-scope items surfaced for Architect C handoff

- V2 commit-message-signal-pattern ("supporting-docs/ is not v11-surface per RC9 rule" appeared in commit message; commit happened anyway).
- V9 / V10 mixed-scope-declaration heuristic.
- T5-A inline-enumeration anti-pattern (structural defect in trinity prose conventions).
- §F-1 location-default contamination pathway (pack maintainers writing pack-internal docs default to supporting-docs/).
- F-5 installed-path-vs-source-path discrepancy detection (5+ files reference a path that doesn't exist).

These are signal-design inputs for Architect C; not designed here.

---

## §7 — Phase 3 reviewer master checklist

Verification this framework's decisions are correctly applied requires the reviewer to perform the following checks. Cross-references to per-finding reviewer notes above.

1. **§C V-findings (13 total) — all have designed decisions.** Verify each V-finding has either (a) a designed REVERT / REPLACE / RELOCATE / JUSTIFY / DUAL-INSTALL / SPLIT action with implementation hint, or (b) a documented SUBSUMED-BY cascade to another V or TASK.
2. **§D confirmed CONTAMINATION (17 hits) — all have designed actions.** Verify 15 SUBSUMED + 2 NEW DECISIONS (D8.6 + D8.7) are addressed.
3. **§D AMBIGUOUS-other (8 hits) — all have designed verdicts.** Verify 2 SUBSUMED + 6 NEW DECISIONS (A2 standalone + A4-A8 cluster) are addressed.
4. **§D AMBIGUOUS-pending-§F (11 hits) — all subsumed by V4 RELOCATE.** Verify the framework's §5 cascade matches Architect B's F-1 resolution; surface conflicts as BLOCKER findings if the F-1 path is the "re-write for project-side audience" one.
5. **Cross-architect dependencies** — verify the framework's calls on Architect B's F-1, F-4 (QUICKSTART), F-5 (OPTIONAL-FEATURES install) match Architect B's actual design output.
6. **Cross-architect non-overlap** — verify the framework does NOT design (a) directory architecture, (b) CI checks, (c) agent-prompt guardrails, (d) reviewer-protocol amendments. Any encroachment into Architect B or C domain is a BLOCKER finding.
7. **No boundary extension** — verify the framework treats the user's §5 boundary articulation as the ruler; does NOT invent additional rules. Edge cases surface as open questions for reviewer escalation, not as silent extensions.
8. **Implementation-hint concreteness** — verify each REVERT / REPLACE provides enough specificity (file + line context + before/after when applicable) that Phase 5 coder can execute mechanically without re-interpreting the design.
9. **Phase 4 planner constraints** — verify §6 cascade and sequencing are noted clearly enough that planner does not need to re-derive them.
10. **Per-finding reviewer-check rows** — verify every "Reviewer independence-check" row in §2-§5 names a concrete artifact the reviewer can inspect (file:line range; full grep on file; trinity parity check; etc.).

---

## §8 — Open questions for reviewer escalation

The framework has these residual open questions surfaced for Phase 3 reviewer to reconcile (NOT for the framework to resolve unilaterally):

**OQ-1.** Architect B's F-1 resolution path. This framework's V4 RELOCATE assumes Architect B chooses a path where CONCEPTUAL-REVIEW-METHODOLOGY.md ends up in a pack-only directory. If Architect B instead reclassifies `supporting-docs/` wholesale as pack-internal (collapsing F-1 differently), V4 becomes JUSTIFY. If Architect B chooses a third path (re-write for project-side audience), the framework recommends against and asks Phase 3 reviewer to surface as BLOCKER. The framework's strong recommendation is RELOCATE.

**OQ-2.** Architect B's MERGE-STRATEGY install decision. V5 (and cascades A1, D7.1, D8.6) splits PRIMARY (pack-only) vs ALTERNATIVE (install to clients). This framework recommends PRIMARY (audience header amendment) because the file's current install state (not copied) is consistent with the PRIMARY framing and the file's pack-internal references are tractable under PRIMARY without per-line REPLACE work. ALTERNATIVE is feasible but more work. Defer to Architect B.

**OQ-3.** Architect B's F-5 resolution path. This framework's recommended DUAL-INSTALL of OPTIONAL-FEATURES.md resolves 7 references (D8.6, D8.7, A4, A5, A6, A7, A8) cleanly. If Architect B chooses keep-pack-only or relocate-to-pack-only-dir paths, the 7 references all require REVERT, which damages the project-side feedback fragment UX (the references currently surface tracker-mode setup to project users; reverting loses that UX surface). Defer to Architect B but note the UX cost of non-DUAL-INSTALL paths.

**OQ-4.** F-4 QUICKSTART.md audience split. This framework did not design F-4 because QUICKSTART.md does not surface in the §C / §D contamination findings — it is a structural anti-pattern flagged in §F but not yielding per-finding decisions for Architect A. Phase 3 reviewer verifies that Architect B addresses F-4 and that no §A-related QUICKSTART decision was missed by this framework.

**OQ-5.** T5-A removal scope. This framework recommends collapsing T5-A (inline enumeration removal) into the V1 + V8 trinity edit (TASK-T1). If Architect C's prevention design recommends a different trinity structure (e.g., a structured "pack agent roster" section ONLY in PM-CHAT.md and NEVER any agent enumeration in trinity), TASK-T1's prose may need to align with Architect C's pattern. Phase 3 reviewer verifies the alignment.

**OQ-6.** V10 hunk-audit yield. This framework's V10 decision is a VERIFY-THEN-DECIDE: per-hunk audit of `8ba0164` may yield zero or many REPLACE edits. The framework cannot enumerate the hunks without doing the audit work (which would conflate Architect A's design role with Phase 5 implementation). Phase 4 planner schedules the hunk audit; Phase 5 coder performs it; Phase 3 reviewer pre-approves the per-hunk decision criteria (V1/V3/V8 patterns).

---

## §9 — Success criteria self-check

Per the prompt's success criteria:

1. **All 13 §C boundary violations have designed decisions with rationale.** Yes. §2 covers V1-V12 + T5-A + T5-B (13 distinct findings as per audit §C; V11/V12 are NO-ACTION completeness rows but still designed; T5-A/T5-B are cascaded but designed).
2. **All 17 confirmed CONTAMINATION references have designed actions.** Yes. §3 covers all 17 via 15 SUBSUMED + 2 NEW DECISIONS.
3. **All 8 AMBIGUOUS-other references have CONTAMINATION-or-LEGITIMATE verdicts with reasoning.** Yes. §4 covers all 8.
4. **All 11 AMBIGUOUS-pending-§F references have conditional decisions or explicit deferral.** Yes. §5 SUBSUMES all 11 by V4 RELOCATE; conditional fallback paths designed for any Architect B F-1 resolution.
5. **Rationale per finding is anchored in the user's boundary articulation.** Yes. §1 reduces the articulation to an operational test; every per-finding decision applies that test.
6. **Decisions are concrete enough for Phase 5 coder to execute mechanically.** Yes. Each decision has an "Implementation hint" naming files, lines, BEFORE/AFTER, and (where relevant) cross-task constraints.
7. **Phase 3 reviewer can verify each decision independently.** Yes. Each decision has a "Reviewer independence-check" naming concrete artifacts to inspect.
8. **Output is markdown only.** Yes.
9. **PREFLIGHT line emitted before final Write.** Yes (above).

---

## End of framework
