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

<!-- AMENDED by Phase 3 fix-pass (S1) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 S1 -->
**Override 6 cascade (S1 fix-pass).** Per `AUDIT-USER-CURATION.md` Override 6, the V4 RELOCATE destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (NOT `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` as Architect B's §4.1 originally proposed). The operative property for this framework's cascade-subsumption logic is "pack-only directory" (which `pack-ops/` satisfies); the specific directory name does not change the cascade. Sections below name `pack-ops/` explicitly wherever the V4 destination is cited.

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

<!-- AMENDED by Phase 3 fix-pass (S1) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 S1 -->
**Rationale.** The file is pack-internal methodology by content, by audience, and by install-path (it does not install to clients). Its current location in `supporting-docs/` is a categorical mistake driven by the location-default contamination pathway described in audit §F-1 (pack maintainers writing pack-internal docs default to `supporting-docs/` because the directory name does not signal "this is project-installed content"). The fix is to move the file to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per `AUDIT-USER-CURATION.md` Override 6, which corrects Architect B's §4.1 `maintenance-docs/` proposal). After relocation, every reference in the file (Pack Chat, pack-architect, pack-reviewer, pack memory, ARCHITECTURE-V*.md, maintenance-docs paths) becomes LEGITIMATE pack-internal cross-reference rather than contamination.

This is the SAME decision-shape that subsumes all 11 §D AMBIGUOUS-pending-§F references in this file (see §4 below): once the file moves to a pack-only directory, all 11 refs are LEGITIMATE by construction.

**Dependency on Architect B (RESOLVED by Override 6, S1 fix-pass).** Architect B owns the target home for relocated pack-only docs that currently live in `supporting-docs/`. Architect B's §4.1 originally proposed `maintenance-docs/`; `AUDIT-USER-CURATION.md` Override 6 rejects that and specifies `pack-ops/`. The destination is therefore `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. The original conditional fallbacks (F-1 path A reclassifies `supporting-docs/` as pack-only — collapse to JUSTIFY; F-1 path B splits `supporting-docs/`; F-1 path C carves out a new pack-only directory) are no longer operative: Override 6 picks the destination directly. The cascade-subsumption logic is unchanged — `pack-ops/` is a pack-only directory and satisfies the operative property.

**Implementation hint.** Phase 5 coder:
1. Destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per `AUDIT-USER-CURATION.md` Override 6 (S1 fix-pass).
2. Read Phase 4 planner's relocation order (V4 likely moves with V2 absorbed into it, and CONCEPTUAL-REVIEW-METHODOLOGY's path-reference set).
3. Use `git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` to preserve file history.
4. Update path references to the file (E-5 + §F-1 noted that internal cross-refs use `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` or bare-filename patterns; full grep after move; retarget all to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`).
5. Do NOT edit the file's content during the move — content was already correct for pack-internal audience; only location was wrong.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6 (S1 fix-pass — supersedes the earlier "Architect B picks" framing); (b) the RELOCATE landed at that path (not `maintenance-docs/`); (c) the file's content is preserved exactly (including the +2 lines from `aaa61b3` per V2); (d) the path-reference update list is comprehensive (every reference to the old `supporting-docs/` path is updated to `pack-ops/` in the same commit, per E-5); (e) the file's existing cross-refs (Pack Chat, pack-architect, pack-reviewer, pack memory, maintenance-docs paths) become LEGITIMATE at the new location and need no further edit.

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

<!-- AMENDED by Phase 3 fix-pass (B1) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 B1 -->
### V10 — TYPE-1 LOW: 8ba0164 BD-167b PM-only-edits (NO ACTION — initial framing wrong)

**Audit summary (as written, now corrected below):** Commit `8ba0164` subject says "BD-167b per-entry split PM-only edits". The audit framed this as a procedural violation on the premise that "project-template trinity is NOT PM-only" — i.e., that Pack Chat directly editing those files exceeded its permission scope.

**Original framing was empirically wrong (B1 fix-pass).** Verified at HEAD:
- `CLAUDE.md:336-338` (pack memory § "What Pack Chat CAN edit directly") explicitly lists "PM-only files (BACKLOG.md / CHANGELOG.md / README version table / PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root / `project-template/` trinity)" as Pack-Chat-direct-edit surfaces.
- `PACK-AGENTS.md:148` (PM-only Files list) names `CLAUDE.md / AGENTS.md / GEMINI.md (root and `project-template/`)` — project-template trinity is explicitly PM-only.

`8ba0164` was therefore correctly scoped: BD-167b's per-entry-split PM-only edits to project-template trinity were a legitimate use of Pack Chat's direct-edit permission, not a misrepresentation. There is no procedural violation.

**Cross-reference grep result (B1 fix-pass verification).** Grepping `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` for references to pack-only paths surfaces exactly two distinct cross-reference patterns at HEAD:
1. `PACK-AGENTS.md` at CLAUDE.md:366 / AGENTS.md:343 / GEMINI.md:356 — already covered by V1 + T5-A REPLACE (TASK-T1).
2. `maintenance-docs/` (TOOL-COMPARISON.md pointer) at CLAUDE.md:397 / AGENTS.md:374 / GEMINI.md:387 — already covered by V8 REVERT (TASK-T1).

Both reference families are within TASK-T1 scope and require no additional V10-derived re-litigation. There are no other pack-only path references in project-template trinity at HEAD.

**Decision: NO ACTION.**

**Rationale.** The original premise (project-template trinity is not PM-only) is contradicted by `CLAUDE.md:336-338` and `PACK-AGENTS.md:148`. With the premise removed, there is no procedural violation to remediate. The content-level cross-references that V10 was contemplating as a per-hunk audit are already in scope of V1 + T5-A + V8 (TASK-T1); no additional hunks remain. V10 yields zero new edits and zero new tasks.

**Implementation hint.** None. V10 has no Phase 5 task. Phase 4 planner does not schedule V10.

**Architect C cascade (B1 fix-pass).** Architect C's M1a (memory rule), M1b (commit message rule), and M5a (Check 36 PM-only keyword) reference V10 in their "PM-only-claim scope-linter" worked example. Architect C fix-pass must drop V10 as the worked example and reframe the PM-only keyword permitted-paths to match the actual `PACK-AGENTS.md:148` list (which permits project-template trinity edits under a `PM-only` commit-message claim). A real PM-only-violation worked example exists at V2's `aaa61b3` (which DID touch outside the PM-only list by editing `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`); C-fix may substitute V2 or a synthetic test fixture.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) the V10 entry above no longer claims a procedural violation; (b) the `CLAUDE.md:336-338` and `PACK-AGENTS.md:148` citations are accurate; (c) the cross-reference grep result is reproducible; (d) the Architect C cascade is surfaced; (e) §6.3 (V10 line), §6.4 (manifest-regen note), §6.5 (signal-pattern handoff), and OQ-6 are all updated consistent with NO-ACTION.

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

<!-- AMENDED by Phase 3 fix-pass (S2) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 S2 -->
**D8.6 — `supporting-docs/MERGE-STRATEGY.md:465` "`OPTIONAL-FEATURES.md` — tracker opt-in walkthrough"**

Same audience analysis as V5 (MERGE-STRATEGY is project-side audience by content but currently not installed).

**D8.7 — `supporting-docs/DEPENDENCIES.md:162` "See `OPTIONAL-FEATURES.md` § 'Tracker integration (v11)' for the full"**

DEPENDENCIES.md is project-side install-reference content (verified — file head names "all tools required or optionally used by the AI Agent Config Pack"). Audience: project users running bootstrap. Not currently installed to clients.

**Decision for both D8.6 and D8.7: REPLACE per SPLIT-confirmed path (Override 8, S2 fix-pass).**

`AUDIT-USER-CURATION.md` Override 8 confirms B's S2 SPLIT design: pack-root `OPTIONAL-FEATURES.md` moves to `pack-ops/OPTIONAL-FEATURES.md` (pack-side) AND a new `project-template/docs/pack/OPTIONAL-FEATURES.md` is CREATED with project-side-audience content (not byte-identical mirror; "one for pack. one for projects. There may be something common to both and maybe some individual to both"). `init-project.sh` gains a stage to install the project-side file to client `docs/pack/OPTIONAL-FEATURES.md`. The pre-amendment terminology distinction (A used "DUAL-INSTALL"; B used "SPLIT") collapses under Override 8 to SPLIT — the operative end-state is two independently-curated files per audience.

The conditional decision tree in the pre-amendment text (three F-5-conditional sub-paths for D8.6 — JUSTIFY/REPLACE/REVERT — and the parallel framing for D8.7) is no longer operative; F-5 is resolved as SPLIT per Override 8.

**Implementation hint.** For both D8.6 and D8.7: REPLACE the bare `OPTIONAL-FEATURES.md` reference with `docs/pack/OPTIONAL-FEATURES.md` (the path that resolves at client repos once SPLIT lands). Both source files (`supporting-docs/MERGE-STRATEGY.md`, `supporting-docs/DEPENDENCIES.md`) remain pack-side per their own re-litigation (V5 PRIMARY pack-only, plus DEPENDENCIES.md unchanged); the reference pattern they update to (`docs/pack/OPTIONAL-FEATURES.md`) assumes the project-side install lands. Pack-side commits SPLIT in TASK-T8 first; per-file ref updates follow.

**Reviewer independence-check.** Phase 3 reviewer verifies: (a) D8.6 and D8.7 both use `docs/pack/OPTIONAL-FEATURES.md` post-SPLIT; (b) the pack-side and project-side `OPTIONAL-FEATURES.md` files exist post-S2 (one at `pack-ops/`, one at `project-template/docs/pack/`); (c) per Override 8, no byte-identity gate is applied between the two files (Phase 3 reviewer does NOT flag content drift as a finding — separate curation is intentional); (d) `init-project.sh` installs the project-template copy to client `docs/pack/`.

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

<!-- AMENDED by Phase 3 fix-pass (S2) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 S2 -->
### A4 — `project-template/.gemini/commands/pack-help.toml:12` "docs/pack/OPTIONAL-FEATURES.md."

**Verdict: LEGITIMATE post-SPLIT (Override 8, S2 fix-pass).**

**Reasoning.** Project-side file (installed to client `.gemini/commands/`). References `docs/pack/OPTIONAL-FEATURES.md` as if installed at client. Currently broken at HEAD; per Override 8 SPLIT, the reference will resolve once `project-template/docs/pack/OPTIONAL-FEATURES.md` exists and is installed to clients. The 5 similar references (A4, A5, A6, A7, A8 below) are the §D-8 installed-path-mismatch pattern; SPLIT resolves the cluster.

**Decision: NO EDIT (LEGITIMATE post-SPLIT).** Per Override 8, F-5 resolves SPLIT. The pre-amendment conditional decision tree (DEPENDS ON F-5 RESOLUTION with three sub-paths) is no longer operative; the REVERT fallback paths are dropped.

**Implementation hint.** No A4 edit. The reference becomes resolvable when TASK-T8 ships the project-side `OPTIONAL-FEATURES.md` and `init-project.sh` installs it.

**Reviewer independence-check.** Phase 3 reviewer verifies (a) no edit to `project-template/.gemini/commands/pack-help.toml:12`; (b) `project-template/docs/pack/OPTIONAL-FEATURES.md` exists post-TASK-T8; (c) `init-project.sh` installs it to client `docs/pack/`.

---

### A5 — `project-template/.claude/skills/pack-help/SKILL.md:15` "`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`"

**Verdict: same as A4 (LEGITIMATE post-SPLIT per Override 8, S2 fix-pass).**

**Decision: same as A4 — NO EDIT (LEGITIMATE post-SPLIT).** Per Override 8, F-5 resolves SPLIT; reference resolves once TASK-T8 lands. Fallback REVERT paths dropped.

---

### A6 — `project-template/.codex/skills/pack-help/SKILL.md:15` "Same path ref"

**Verdict: same as A4 (LEGITIMATE post-SPLIT per Override 8, S2 fix-pass).**

**Decision: same as A4 — NO EDIT (LEGITIMATE post-SPLIT).** Per Override 8, F-5 resolves SPLIT; reference resolves once TASK-T8 lands. Fallback REVERT paths dropped.

---

### A7 — `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` "See ... and `OPTIONAL-FEATURES.md` for full setup."

**Verdict: same as A4 — LEGITIMATE post-SPLIT (Override 8, S2 fix-pass). Bare filename resolves relative to the file's directory (`project-template/docs/pack/`) where `OPTIONAL-FEATURES.md` will exist after TASK-T8.**

**Decision: same as A4 — NO EDIT (LEGITIMATE post-SPLIT).** Per Override 8, F-5 resolves SPLIT; reference resolves once TASK-T8 lands. Fallback REVERT paths dropped.

---

### A8 — `project-template/docs/pack/HELP-FRAGMENT.md:6` and `:33` "`docs/pack/OPTIONAL-FEATURES.md`"

**Verdict: same as A4 (LEGITIMATE post-SPLIT per Override 8, S2 fix-pass).**

**Decision: same as A4 — NO EDIT (LEGITIMATE post-SPLIT).** Per Override 8, F-5 resolves SPLIT; both references resolve once TASK-T8 lands. Two sites in same file; both NO EDIT. Fallback REVERT paths dropped.

---

### §4 totals reconciliation

- A1: SUBSUMED by V5
- A2: NEW DECISION (REPLACE METHODOLOGY.md:1509)
- A3: SUBSUMED by V6.a
- A4-A8: NEW DECISION cluster (5 OPTIONAL-FEATURES references) → all LEGITIMATE post-SPLIT (Override 8, S2 fix-pass — supersedes the original "DEPENDS ON F-5" framing and drops the alternate REVERT paths).

**§4 total: 8 AMBIGUOUS-other. 2 SUBSUMED; 6 NEW DECISIONS (1 standalone METHODOLOGY edit + 5 OPTIONAL-FEATURES cluster).** All 8 have designed verdicts.

**Aggregate dependency on Architect B for §4 (RESOLVED by Override 8, S2 fix-pass):** A4-A8 (5 hits) original F-5 dependency is resolved — F-5 = SPLIT per Override 8; all 5 references become LEGITIMATE post-SPLIT.

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

<!-- AMENDED by Phase 3 fix-pass (S1) — see PACK-REVIEW-PHASE-2-DESIGNS.md §1 S1 -->
**Conditional fallback paths (RESOLVED by Override 6, S1 fix-pass).** `AUDIT-USER-CURATION.md` Override 6 specifies the destination as `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. The original three F-1-conditional fallbacks (path A: reclassify `supporting-docs/` as pack-internal — V4 collapses to JUSTIFY; path B: split `supporting-docs/`; path C: re-write for project-side audience) are no longer operative. The relocation lands at `pack-ops/`; all 11 references become LEGITIMATE pack-internal cross-references at that destination by construction. The pre-amendment text recorded the "re-write for project-side audience" path as strongly-recommended-against (the file is unambiguously pack-internal methodology; no project-side equivalent exists for "Pack Chat" orchestrator, pack-architect, pack-reviewer, pack memory, or ARCHITECTURE-V*.md); that argument is preserved by Override 6's direct destination call.

**Decision: SUBSUMED by V4 (RELOCATE to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6).** No per-reference standalone tasks. All 11 references resolve as LEGITIMATE post-V4.

**Phase 3 reviewer reconciliation note (post-S1 fix-pass).** Phase 3 reviewer verifies V4 + §5 destination matches `pack-ops/` per Override 6 (not `maintenance-docs/`, not any of the original F-1 fallbacks). No BLOCKER escalation path remains for this finding — the destination is user-authorized.

**§5 total: 11 AMBIGUOUS-pending-§F. All 11 SUBSUMED by V4 RELOCATE to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6.** Designed actions exist for all 11.

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
- **TASK-T8 (OPTIONAL-FEATURES SPLIT — confirmed per Override 8, S2 fix-pass):** SPLIT the pack-root `OPTIONAL-FEATURES.md` into pack-side (`pack-ops/OPTIONAL-FEATURES.md`) + project-side (NEW `project-template/docs/pack/OPTIONAL-FEATURES.md`, content tailored per audience — not byte-identical). Install plumbing in `init-project.sh` ships the project-side file to client `docs/pack/`. Per-file ref updates: D8.7 (DEPENDENCIES.md `:162`) + D8.6 (MERGE-STRATEGY `:465`) — REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`. A4-A8 (5 project-side refs) need no edit (LEGITIMATE post-SPLIT). May need a separate task for the install plumbing (init-project.sh edit) followed by the D8.6/D8.7 ref updates; A4-A8 verify-only.

### 6.2 Sequencing constraints

- TASK-T7 (RELOCATE) and TASK-T5 (MERGE-STRATEGY edit) both depend on Architect B's F-1 resolution. T7 needs the target directory; T5 needs the install decision. Both must wait on Architect B's design.
- TASK-T8 (OPTIONAL-FEATURES) is the SPLIT-confirmed implementation per Override 8 (S2 fix-pass). No further F-5 resolution needed; Architect B's S2 commit design plus Override 8 fully specify TASK-T8.
- TASK-T1 / T2 / T3 / T4 / T6 do not depend on Architect B and can sequence first if the planner wants early wins.
- TASK-T1 should ship BEFORE any further trinity edits in unrelated BDs (so the v11 trinity reflects the corrected guidance for any new project that installs during v11.0).

### 6.3 Pure-cascade findings (no standalone task)

- V2: subsumed by V4 task content preservation.
- V9: subsumed by V5/V6/V7 (no standalone fix).
- V10: NO ACTION (per B1 fix-pass — initial framing wrong; project-template trinity IS PM-only per `CLAUDE.md:336-338` + `PACK-AGENTS.md:148`; `8ba0164` was correctly scoped; all relevant cross-references are within TASK-T1 scope).
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

V10: no manifest-regen trigger — NO ACTION per B1 fix-pass.

TASK-T4 (MIGRATION-v10-to-v11.md), TASK-T5 (MERGE-STRATEGY.md), TASK-T6 (METHODOLOGY.md): all live in `supporting-docs/` — do NOT trigger manifest regen per RC9 base-case rule (`supporting-docs/` is not v11-surface for the manifest).

### 6.5 Out-of-scope items surfaced for Architect C handoff

- V2 commit-message-signal-pattern ("supporting-docs/ is not v11-surface per RC9 rule" appeared in commit message; commit happened anyway).
- V9 mixed-scope-declaration heuristic (V10 dropped per B1 fix-pass — original framing wrong; the corresponding signal pattern lives at V2 `aaa61b3` which actually touched outside the PM-only list).
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

**OQ-1 (RESOLVED by Override 6, S1 fix-pass).** V4 RELOCATE destination is `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per `AUDIT-USER-CURATION.md` Override 6. Architect B's §4.1 `maintenance-docs/` proposal is superseded; the three original F-1-conditional paths (reclassify-supporting-docs / split / re-write-for-project-side) are no longer operative. RELOCATE proceeds to `pack-ops/`; cascade-subsumption holds; all 11 §5 ambiguous-pending-§F refs become LEGITIMATE at the new location.

**OQ-2.** Architect B's MERGE-STRATEGY install decision. V5 (and cascades A1, D7.1, D8.6) splits PRIMARY (pack-only) vs ALTERNATIVE (install to clients). This framework recommends PRIMARY (audience header amendment) because the file's current install state (not copied) is consistent with the PRIMARY framing and the file's pack-internal references are tractable under PRIMARY without per-line REPLACE work. ALTERNATIVE is feasible but more work. Defer to Architect B.

**OQ-3 (RESOLVED by Override 8, S2 fix-pass).** F-5 resolves SPLIT per `AUDIT-USER-CURATION.md` Override 8. SPLIT design: pack-root `OPTIONAL-FEATURES.md` moves to `pack-ops/OPTIONAL-FEATURES.md`; new `project-template/docs/pack/OPTIONAL-FEATURES.md` is created with project-side-audience content (not byte-identical mirror); `init-project.sh` installs the project-side file to client `docs/pack/`. All 7 §C/§D references resolve cleanly: D8.6 + D8.7 REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`; A4-A8 NO EDIT (LEGITIMATE post-SPLIT). The pre-amendment fallback REVERT paths (which would have damaged project-side UX) are dropped.

**OQ-4.** F-4 QUICKSTART.md audience split. This framework did not design F-4 because QUICKSTART.md does not surface in the §C / §D contamination findings — it is a structural anti-pattern flagged in §F but not yielding per-finding decisions for Architect A. Phase 3 reviewer verifies that Architect B addresses F-4 and that no §A-related QUICKSTART decision was missed by this framework.

**OQ-5.** T5-A removal scope. This framework recommends collapsing T5-A (inline enumeration removal) into the V1 + V8 trinity edit (TASK-T1). If Architect C's prevention design recommends a different trinity structure (e.g., a structured "pack agent roster" section ONLY in PM-CHAT.md and NEVER any agent enumeration in trinity), TASK-T1's prose may need to align with Architect C's pattern. Phase 3 reviewer verifies the alignment.

**OQ-6 (RESOLVED by B1 fix-pass).** V10 collapses to NO ACTION (see §2 V10 amended entry and §10 Phase 3 fix-pass amendments). The original VERIFY-THEN-DECIDE framing was based on an empirically wrong premise (`project-template/` trinity IS PM-only per `CLAUDE.md:336-338` + `PACK-AGENTS.md:148`). No hunk-audit task is generated; Phase 4 planner does not schedule V10; Phase 5 coder spawns nothing against V10. The only residual concern (the two cross-reference families surfacing at project-template trinity) are within TASK-T1 scope already (V1 + T5-A + V8).

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

## §10 — Phase 3 fix-pass amendments (B1 + S1 + S2)

This section summarizes the in-place amendments made to this framework on 2026-05-19 in response to Phase 3 reviewer findings B1 (BLOCKER), S1 (SHOULD), and S2 (SHOULD) from `PACK-REVIEW-PHASE-2-DESIGNS.md`. Original section bodies are amended with `<!-- AMENDED by Phase 3 fix-pass ... -->` HTML comments immediately above each amended block to aid future archaeology.

### §10.1 — B1 amendments (BLOCKER — V10 collapses to NO ACTION)

**Reviewer finding (`PACK-REVIEW-PHASE-2-DESIGNS.md` §1 B1):** Architect A's V10 framing claimed `8ba0164` (BD-167b) was a misrepresented-scope violation on the premise that "project-template trinity is NOT PM-only". That premise is empirically wrong: `CLAUDE.md:336-338` and `PACK-AGENTS.md:148` both explicitly name `project-template/` trinity as PM-only (Pack-Chat-direct-editable). V10 should collapse to NO ACTION, and Architect C's cascade (M1a/M1b/M5a PM-only-keyword definition) must reframe accordingly.

**Cross-reference grep (B1 verification).** Running `grep -nE '(PACK-AGENTS|PACK-CHAT|HELP-FRAGMENT-PACK|maintenance-docs|supporting-docs|MERGE-STRATEGY|MIGRATION-v10-to-v11|TOOL-COMPARISON|CONCEPTUAL-REVIEW-METHODOLOGY|pack-architect|pack-planner|pack-coder|pack-reviewer|pack-docs-researcher|pack-startup|pack-help\.sh|HELP-FRAGMENT-TRACKER|OPTIONAL-FEATURES\.md|RESEARCH-NON-APPLE-UI-SKILLS|ARCHITECTURE-V|ARCHITECTURE-SKILL|validate-pack\.py)' project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` at HEAD `8014186` surfaces exactly two distinct cross-reference families:

1. `PACK-AGENTS.md` at `project-template/CLAUDE.md:366` / `project-template/AGENTS.md:343` / `project-template/GEMINI.md:356` — already covered by V1 + T5-A REPLACE (TASK-T1).
2. `maintenance-docs/` (TOOL-COMPARISON.md pointer) at `project-template/CLAUDE.md:397` / `project-template/AGENTS.md:374` / `project-template/GEMINI.md:387` — already covered by V8 REVERT (TASK-T1).

No third reference family exists. Both families are subsumed by TASK-T1. Therefore the "re-litigate V10 with corrected list" path proposed in B1's fix-shape (b) yields zero new findings — V10 collapses to NO ACTION per fix-shape (a).

**Sections amended:**
- **§2 V10 entry** (formerly "TYPE-1 MEDIUM: 8ba0164 BD-167b PM-only-edits misrepresented scope") rewritten as "TYPE-1 LOW: 8ba0164 BD-167b PM-only-edits (NO ACTION — initial framing wrong)". New body cites `CLAUDE.md:336-338` and `PACK-AGENTS.md:148`; documents the grep result; collapses decision to NO ACTION; adds explicit Architect C cascade for the M1a/M1b/M5a PM-only-keyword definition.
- **§6.3 V10 cascade line** updated from "VERIFY task — per-hunk audit" to "NO ACTION (per B1 fix-pass — initial framing wrong)".
- **§6.4 V10 manifest-regen line** updated from "triggers regen only if it yields project-template edits" to "no manifest-regen trigger — NO ACTION per B1 fix-pass".
- **§6.5 V9/V10 mixed-scope-declaration heuristic line** updated to drop V10 (V9 retained); the corresponding signal pattern is documented as living at V2 (`aaa61b3` actually touched outside the PM-only list).
- **OQ-6** updated to "(RESOLVED by B1 fix-pass)" — explicitly notes V10 yields zero hunk-audit edits and zero scheduled planner tasks.

**Architect C cascade surfaced.** The amended V10 entry includes an explicit "Architect C cascade (B1 fix-pass)" paragraph instructing Architect C fix-pass to (a) drop V10 as the worked example for the M1a/M1b/M5a PM-only-keyword definition, and (b) reframe the PM-only keyword permitted-paths regex to match the actual `PACK-AGENTS.md:148` list (which permits `project-template/` trinity edits under a `PM-only` commit-message claim). A real PM-only-violation worked example exists at V2 (`aaa61b3` which DID touch outside the PM-only list by editing `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`); Architect C may substitute V2 or a synthetic test fixture.

### §10.2 — S1 amendments (SHOULD — V4 destination per Override 6)

**Reviewer finding (`PACK-REVIEW-PHASE-2-DESIGNS.md` §1 S1):** Architect A's V4 RELOCATE framework named "pack-only directory designated by Architect B" generically; Architect B's §4.1 chose `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`; `AUDIT-USER-CURATION.md` Override 6 rejects that and specifies `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. A's cascade-subsumption logic survives Override 6 (operative property is "pack-only directory"; `pack-ops/` satisfies); A's specific phrasing should name the actual destination.

**Sections amended:**
- **§0 reading guide** — added Override 6 cascade paragraph naming `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` as the V4 destination; clarified that the original F-1 conditional-decision framing is no longer operative.
- **§2 V4 Rationale** — replaced generic "pack-only directory designated by Architect B" with explicit `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` per Override 6; cited Override 6 explicitly.
- **§2 V4 Dependency on Architect B** — rewritten as "(RESOLVED by Override 6, S1 fix-pass)"; the three original F-1-conditional fallbacks (path A reclassify-supporting-docs / path B split / path C carve-new-dir) are documented as no-longer-operative; destination is `pack-ops/`.
- **§2 V4 Implementation hint** — step 1 now names destination explicitly; step 3 names the full `git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` command; step 4 names `pack-ops/` as the retarget path.
- **§2 V4 Reviewer independence-check** — verifies destination is `pack-ops/` (not `maintenance-docs/`); supersedes the earlier "Architect B picks" framing.
- **§5 conditional fallback block** — rewritten to "(RESOLVED by Override 6, S1 fix-pass)"; the three original F-1-conditional fallback paths are documented as no-longer-operative; the §5 11-ref cluster all subsumed by V4 RELOCATE to `pack-ops/`; Phase 3 reviewer reconciliation note simplified (no BLOCKER escalation path remains — destination is user-authorized).
- **OQ-1** updated to "(RESOLVED by Override 6, S1 fix-pass)" — names `pack-ops/` destination explicitly; cascade-subsumption logic preserved.

**Cascade-subsumption preserved.** The §5 11-ref cluster (all references inside `CONCEPTUAL-REVIEW-METHODOLOGY.md` to pack-only paths/agents/orchestrator) all become LEGITIMATE post-RELOCATE to `pack-ops/`. The operative property is "pack-only directory" — `pack-ops/` satisfies; the original logic does not change.

### §10.3 — S2 amendments (SHOULD — D8.6/D8.7 + A4-A8 collapse to SPLIT per Override 8)

**Reviewer finding (`PACK-REVIEW-PHASE-2-DESIGNS.md` §1 S2):** Architect A's framing in §3.5 D8.6/D8.7 + §4 A4-A8 cluster recommended DUAL-INSTALL with FALLBACK paths (REVERT all 5 if Architect B picks keep-pack-only or relocate-to-pack-only-dir). Architect B's framing recommended SPLIT. `AUDIT-USER-CURATION.md` Override 8 confirmed SPLIT explicitly. A's framework should collapse the conditional D8.6/D8.7 + A4-A8 framings to the SPLIT-confirmed path; FALLBACK REVERT paths drop.

**Terminology reconciliation.** A's decision-category vocabulary (§1) defines DUAL-INSTALL (install a copy to project-side AND keep pack-side source) and SPLIT (cleave a single audience-mixed file into two files, one per audience) as distinct categories. Override 8 ("one for pack. one for projects. There may be something common to both and maybe some individual to both") and B's S2 design ("project-side content tailored to project audience — not byte-identical copy") both correspond to A's SPLIT category, not DUAL-INSTALL. The amendments below adopt SPLIT as the operative term.

**Sections amended:**
- **§3.5 D8.6 + D8.7 block** — collapsed three-path conditional decision tree for D8.6 (JUSTIFY/REPLACE/REVERT depending on V5 + F-5 combinations) and parallel framing for D8.7 to a single decision: REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`. Cited Override 8 explicitly. Pre-amendment "Recommended path: DUAL-INSTALL" and "Implementation hint" prose rewritten for SPLIT. Reviewer independence-check now notes "no byte-identity gate" between the two files (Override 8).
- **§4 A4** entry — collapsed to "LEGITIMATE post-SPLIT"; "DEPENDS ON F-5 RESOLUTION" framing dropped; alternate REVERT paths dropped; NO EDIT decision per Override 8.
- **§4 A5 / A6 / A7 / A8** entries — same SPLIT-confirmed collapse; each is now "same as A4 — NO EDIT (LEGITIMATE post-SPLIT)" with explicit Override 8 citation.
- **§4 totals reconciliation** — A4-A8 line updated from "all become LEGITIMATE under recommended DUAL-INSTALL path; alternate paths REVERT all 5" to "all LEGITIMATE post-SPLIT (Override 8, S2 fix-pass — supersedes the original 'DEPENDS ON F-5' framing and drops the alternate REVERT paths)".
- **§4 aggregate dependency line** — updated from "depend on F-5 resolution... defers the call to Architect B" to "(RESOLVED by Override 8, S2 fix-pass)... F-5 = SPLIT per Override 8".
- **§6.1 TASK-T8** — updated from "OPTIONAL-FEATURES DUAL-INSTALL — if Architect B chooses" to "OPTIONAL-FEATURES SPLIT — confirmed per Override 8"; explicit reference to `pack-ops/OPTIONAL-FEATURES.md` (pack-side) + new `project-template/docs/pack/OPTIONAL-FEATURES.md` (project-side, tailored content per audience); A4-A8 verify-only (no edits) noted.
- **§6.2 sequencing constraints** — TASK-T8 line updated from "depends on Architect B's F-5 resolution" to "is the SPLIT-confirmed implementation per Override 8".
- **OQ-3** updated to "(RESOLVED by Override 8, S2 fix-pass)" — names the SPLIT design explicitly; resolves all 7 references (D8.6 + D8.7 REPLACE; A4-A8 NO EDIT); fallback REVERT paths dropped.

### §10.4 — Unaffected sections (intact)

The following sections are explicitly unaffected by the B1/S1/S2 fix-pass and remain as originally designed:
- §1 boundary articulation reduced to operational test
- §2 V1, V2, V3, V5, V6 (V6.a/V6.b/V6.c), V7, V8, V9, V11, V12, T5-A, T5-B (all unaffected)
- §3.1 (D-1), §3.2 (D-4), §3.3 (D-5), §3.4 (D-7) cascade tables (all unaffected — only §3.5 D-8 amended per S2)
- §4 A1, A2, A3 (all unaffected — only A4-A8 amended per S2)
- §6.1 TASK-T1 through TASK-T7 (all unaffected — only TASK-T8 amended per S2)
- §6.4 manifest regeneration triggers (only the V10 sub-line amended per B1; rest unchanged)
- §6.5 out-of-scope items for Architect C handoff (only the V9/V10 line amended per B1)
- §7 Phase 3 reviewer master checklist (unaffected — the checklist remains valid for the amended framework)
- §8 OQ-2, OQ-4, OQ-5 (unaffected — only OQ-1, OQ-3, OQ-6 amended)
- §9 success criteria self-check (unaffected — the framework continues to meet all 9 success criteria post-amendment)

### §10.5 — Cross-doc cascade concerns (informational, not blocking)

This fix-pass is in-scope for Architect A only. The following cross-doc cascades are surfaced for Pack Chat / Architect B fix-pass / Architect C fix-pass triage but are NOT amended here:

1. **Architect C cascade (BLOCKER B1 ripple).** Architect C's M1a (memory rule), M1b (commit message rule), M5a (Check 36 PM-only keyword permitted-paths regex), and §10.2 worked example all need to drop V10 as the worked example and reframe the PM-only keyword to match `PACK-AGENTS.md:148`. Reviewer's MUST-S6 also surfaces this. Out of scope for this fix-pass; flagged for Architect C fix-pass.
2. **Architect B fix-pass cascade (S1 ripple).** Architect B's §4.1 chose `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` as the F-1 destination. Override 6 corrects to `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Architect B fix-pass (or B-fix extension) should update B's §4.1 to honor Override 6 — Reviewer's Concern 5 row for Override 6 surfaces this as needing B fix-pass attention. Out of scope for this fix-pass; flagged for Architect B fix-pass.
3. **Architect B fix-pass cascade (S2 ripple — none required).** Architect B's S2 commit design already aligns with Override 8 SPLIT — no B-side amendment needed for S2 itself. (B's separate fix-pass concerns are MUST-M3 QUICKSTART per Override 7 and SHOULD-S3 OPTIONAL-FEATURES content-split sketch — both out of scope for this Architect A fix-pass.)

---

## End of framework
