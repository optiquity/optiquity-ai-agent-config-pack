# INTAKE-GROUPINGS-V11.md

**Purpose:** Captures user-intent discussion that led to BD-186 (groupings requirements + v11.0/v11.1 scope decision), opened 2026-05-21 and resolved 2026-05-23. Retroactive intake doc created 2026-05-24 from chat history for audit-trail completeness.

**Date authored:** 2026-05-24 (sidecar session "v11-dev-sidecar"; retroactive from BD-186 work 2026-05-21..2026-05-23).
**Fidelity:** **FAITHFUL SUMMARY — NOT VERBATIM.** Key user statements quoted where high confidence; smaller back-and-forth, exact ordering, and some wording paraphrased from chat memory. **User should review for accuracy before treating as audit-grade record.**
**Companion docs (all committed):**
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (primary requirements artifact; 908+ lines; canonical for design decisions and locked constraints)
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (constraint enumeration baseline)
- `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` (original brainstorm)
- `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` (Pass-1 + Pass-2 per-backend research)
- `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md` (research methodology)
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (entry-point doc for v11.1 architect)

**Reading order:**
1. §1 sidecar setup context — what the session was for
2. §2 design principles (user-stated) — the 5+2 authoritative principles
3. §3 user-stated constraints C1-C7 — discussion context for each
4. §4 major design moments — load-bearing decisions during triage
5. §5 process rules established — meta-decisions about how the work runs
6. §6 BD landscape evolution — BD-186 open → close + BD-187/188/189 opens
7. §7 research commissioning — Pass-1 + Pass-2 + scope evolution
8. §8 forward pointer — where the work continues

**Conflict resolution:** If this intake doc conflicts with REQUIREMENTS-GROUPINGS-V11.md, the REQUIREMENTS doc wins. The intake is audit-trail; the REQUIREMENTS doc is the canonical design output. Per user direction 2026-05-24, "my only concern is really just conflicts, not gaps."

---

## §1 — Sidecar session setup (BD-186 context)

The BD-186 sidecar session opened 2026-05-21 as a Pack Chat sidecar to the main v11-dev chat. Initial framing from session-start brief:

- Pack v11.0 supports flat-file mode (default) and GitHub Issues tracker mode (opt-in via tracker.toml)
- A v11.1 discussion doc (`V11.1-DISCUSSION-GITHUB-PROJECTS.md`) proposed GitHub Projects integration for groupings
- Groupings = the layer above individual backlog/task items (epics, milestones, themes, sprints, phase-parts, etc.)

### User's framing quote at sidecar setup

> the tracker is not simply a database but it should help is keeping track of state, whatever that means to the project in the repo.

### User's session goals

1. Triage the touch-point inventory (`TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`; 910 lines; untriaged at session start) with the user
2. Reach a scope decision on which groupings work lands in v11.0 versus v11.1+, applying the 5 design principles
3. For v11.0 absorption: identify whether items fold into an existing v11.0 batch or require new BDs
4. For v11.1+ items: ensure documented on a live forward-pointing surface

### Success criteria (from sidecar brief)

- Every break-point (7), major-revision flag (3), and open observation (14) in the inventory has a documented disposition with rationale referencing the design principles
- New BDs required for v11.0 absorption listed with proposed numbers (read BACKLOG live; reservation lists from other chats NOT authoritative)
- Items remaining in v11.1+ documented on a live forward-pointing surface
- Scope-decision artifact written to a single new file in `maintenance-docs/v11-research/`

---

## §2 — Design principles (user-stated)

Five core principles were stated at sidecar setup; two additional considerations were established during BD-186 triage.

### Core 5 (user-stated 2026-05-21)

1. **Purpose-driven.** Design decisions are purpose-driven — based on what should be possible. Usage data is informative for HOW to implement and where friction exists, but does not determine WHETHER a capability is included. Empirical absence-when-disabled carries no signal.

2. **First-class entity.** Groupings are a first-class entity in the pack, equivalent in status to backlog items, implementation-plan entries, and changelog entries.

3. **Reversibility.** Anything stored in a tracker has a flat-file equivalent and round-trips without information loss. No tracker-only state.

4. **Tracker portability.** Tracker-specific implementations sit behind a tracker-agnostic abstraction (per the BD-060 TrackerProvider pattern), so developers on Linear / Jira / Redmine / etc. can plug in their equivalent backend.

5. **Compatibility.** Groupings integrate with the existing v11 design — phases, tasks, backlog items, and project management workflows already designed in v11. Minor modifications to existing surfaces are acceptable; major revisions require user discussion.

### Additional considerations established during triage

6. **External-tool accommodation (C6 — see §3).** Pack accommodates predetermined groupings from external tools (Notion, Productboard, ProductPlan, Linear specs, Confluence, etc.) via PM-Chat-mediated translation. Pack does NOT parse external formats with bespoke parsers.

7. **Graceful tracker degradation (C7 — see §3).** Capable trackers (GH Projects v2, Linear) MUST NOT be downgraded to lowest-common-denominator behavior. Incapable trackers have documented mitigations or "not supported" declarations.

### Framing note

C6 and C7 are recorded as principle ELABORATIONS rather than separate principles in the REQUIREMENTS-GROUPINGS-V11.md §1. C7 absorbs into principle #4 (portability); C6 lives as a top-level consideration. The architect is free to reframe if a different structure works better downstream.

---

## §3 — User-stated constraints C1-C7

The constraints emerged over the early days of the BD-186 sidecar session. Each is faithfully summarized below with reasoning the user provided.

### C1 — Phases-only membership

**Statement:** Only phases can be members of a grouping. Phase parts (`phase-N.Part-M` per BD-185), tasks (`phase-N.M`), and backlog entries (TD-NNN, BD-NNN) are NEVER members.

**User-provided reasoning:** Phase parts and tasks are never orphaned — they're always under a phase. Backlog entries must be scheduled into phases before they're up for implementation. Including any of these as grouping members creates ambiguity about ownership and lifecycle.

### C2 — Minimum 2 members per grouping

**Statement:** A grouping must have at least 2 member phases.

**User-provided reasoning:** A single-member grouping is degenerate (the phase IS the grouping). Single-member groupings should require explicit exception declaration with rationale. Dissolution workflow when membership drops below 2.

### C3 — Per-entry-tree pattern imitation with explicit differences

**Statement:** The bi-directionality of `implementation-plan/` and `backlog/` directories, the structure of files in those directories, and the integration into workflows are patterns to investigate and imitate. Groupings will differ in many ways — differences are documented explicitly.

**User-provided reasoning:** Pack already has established patterns for per-entry trees. Imitate where applicable; differentiate where the entity model differs (e.g., groupings have no Open/Resolved lifecycle states; declarative classification + member list vs. issue-style fields + description).

### C4 — Phase→grouping migration capability

**Statement:** Existing projects with phases (no groupings yet) need a way to identify candidate groupings from their phase set. NEW capability area beyond V11.1-DISCUSSION's enumeration. Lightweight pack-character mechanisms preferred.

**User-provided reasoning:** Projects don't start with groupings. Adoption requires a path from "phases only" to "phases + groupings" without re-authoring phases. Pack character is "lightweight script + PM-Chat orchestration," not heavyweight standalone analyzers.

### C5 — Grouping recognition characteristics + tooling

**Statement:** Characteristics or tools to recognize groupings from phase content OR from PRDs. Extensible Kind enumeration (not fixed).

**User-provided reasoning:** Each project's groupings reflect their own product context. Pack-shipped Kind enum should be defaults, not constraints. Recognition tooling should be heuristic-assisted (PM Chat reads phases + applies characteristics), not deterministic NLP parsers.

### C6 — External-tool accommodation

**Statement:** Some projects author user journeys / PRDs / groupings in external tools (Notion, Productboard, etc.). The pack should accommodate predetermined groupings — accepting external-tool content via PM-Chat-mediated translation when needed, and supporting the case where external content names groupings without identifying member phases (reconciliation workflow with PM/developer).

**User-provided reasoning:** Locking developers into pack-only authoring drives them away. Pack should provide an ingress path for external content. Pack does NOT parse external formats with bespoke parsers (per V11.1 §11); user-format-agnostic posture is preserved.

### C7 — Graceful tracker degradation

**Statement:** Trackers vary enormously in grouping primitive support. Capable trackers (GH Projects v2, Linear) MUST NOT be downgraded to LCD. Incapable trackers (Forgejo Milestone-only, Jira epic-exclusive-parentage) MUST have documented mitigations or "not supported" declarations.

**User-provided reasoning:** Multi-backend support shouldn't punish the best backends. Per-backend capability flags + emulation strategies + graceful degradation. (Confirmed via Pass-1 + Pass-2 research that this is the right framing.)

---

## §4 — Major design moments during triage

Significant decisions during the per-capability walkthrough. Faithful summaries — not all back-and-forth preserved.

### Phase-part definition confirmed (early in session)

User explicitly told Pack Chat to ASK rather than guess about phase-part definition. Pack Chat surfaced its BD-185-derived understanding: phase parts are `phase-N.Part-M` sequenced sub-units of a phase, each carrying its own task set, with execution ordering between parts. BD-185 hadn't run through architect yet, so the formal grammar was pending. User confirmed this working form was accurate. Used throughout BD-186 triage.

### Filename convention correction (slug → GRP-NNN)

During #5 (Per-entry tree + supporting files), Pack Chat initially recommended slug-only filenames (e.g., `auth-and-identity.md`) per V11.1-DISCUSSION §10's example. User pushed back: GRP-NNN ID-prefix pattern is correct (matches BD-NNN / TD-NNN / phase-N convention). Pack Chat acknowledged the error — had anchored on V11.1 §10 slug example without weighting the broader pack pattern. The number doesn't imply order; it's a stable opaque handle. **Filename convention locked: `GRP-NNN.md` (3-digit zero-padded; matches existing pack ID-prefix patterns).**

### Default-accept rule established (2026-05-22)

After approving multiple Pack Chat recommendations explicitly, user explicitly established the rule:

> Unless I state otherwise, I accept your recommendations.

Pack Chat absorbed this as **default-accept mode**: agent makes clear evidence-based recommendations; proceeds unless user redirects. Reserve explicit asks for genuinely ambiguous calls. Per-action commit approval still required per existing `feedback-no-destructive-without-approval` rule.

### User-prescriptive-authority rule established (2026-05-22)

User clarified that the "no solutions in agent prompts" rule (pack memory) applies to AGENTS, not to the user themselves:

> You are not the architect, but I AM an architect, lead, and decision maker, so if I want to be prescriptive and provide solutions, that doesn't break your rules since I approved them.

Pack Chat absorbed this: user retains architect/lead/decision-maker authority. Approved decisions become architect-level constraints the downstream architect must respect. Three layers in requirements artifacts going forward:
- Problem / goal / success criteria → architect bounds
- User-approved design decisions → constraints the architect must respect
- Architect-level surfaces → architect designs within constraints

### #10 dual-SSOT rejection (Bi-directional sync)

Pack Chat over-designed #10 with a "split-authority" model (pack-authoritative for structure; tracker-authoritative-via-sidecar for tracker-only fields). User pushed back: this creates dual SSOTs (pack repo + sidecar) with field-level allocation rules, which is brittle and violates principle #3 reversibility.

Pack Chat acknowledged the error; #10 was re-done at requirements-only level (problem/goal/SC) with all design decisions deferred to the architect. The brittle cascade was explicitly rejected and documented in the artifact.

### #14 STATUS.md major revision (user-driven, 2026-05-23)

User pushed back on Pack Chat's initial #14 design (STATUS.md unchanged in fields; disclaimer extension only). The user redesigned: STATUS.md becomes the unified human-readable dashboard with phase table + groupings table + cross-links + mode-aware rendering. GROUPINGS.md mirror DROPPED (deviation from existing per-entry-tree pattern; STATUS.md absorbs the convenience-reading role).

User explicitly acknowledged the complexity cost:

- Approximately 5-10x complexity increase in STATUS.md generator (cross-tree read + reverse-lookup + mode-aware rendering + intra-doc anchors)
- User approved with awareness: "This is for human use and UX"

Pack Chat propagated the impact through #5 (no mirror), #12 (workflow integration adjusted), #13 (Check 32 mirror-in-sync NOT extended for groupings), #16 (install/upgrade scripting doesn't install GROUPINGS.md).

### #17 re-do for over-design

Pack Chat initially over-designed #17 (degenerate-state handling) with specific sub-decisions about STATUS.md empty-rendering, tracker-init behavior, etc. User pushed back: these are design choices an architect needs full cross-stream context to make. Pack Chat re-stated #17 at requirements-only level with all design choices deferred to architect.

### Per-BD-NNN inline review acknowledgment

User noted that the existing pack memory `feedback_review_fix_one_cycle` covers per-BD inline review pattern. During cross-reference verification (task C of the post-CI-green wrap polish), Pack Chat caught that a separate `feedback_per_bd_inline_review` reference in the REQUIREMENTS-GROUPINGS-V11.md was invented — no such memory file exists. Fix applied; the `feedback_review_fix_one_cycle` reference annotated to clarify it covers the per-BD pattern.

---

## §5 — Process rules established

Beyond design decisions, several process / meta rules emerged during the work and were saved to pack memory at session end:

### `feedback_groupings_design_principles.md`

5 core principles (purpose-driven, first-class entity, reversibility, tracker portability, compatibility) + C6 external-tool accommodation + C7 graceful tracker degradation. Authoritative for any v11.1+ groupings work and adjacent feature work.

### `feedback_user_prescriptive_authority.md`

Default-accept + user-as-architect-prescriptive rules established 2026-05-23. Pack Chat makes evidence-based recommendations + proceeds unless redirected; user retains decision-making authority; approved decisions become architect constraints; commit-time approval gate still applies.

### Triage workflow protocol

Pack Chat followed `feedback_triage_workflow_protocol` (pre-existing memory): read all related docs first; present full context + options + evidence-based recommendations; one item at a time; self-check before presenting (don't ask user what source material already answers).

### Default sub-agent run_in_background

Per pre-existing memory `feedback_spawn_agents_in_background`, all sub-agent spawns in BD-186 work used `run_in_background: true` (researcher passes Pass-1 and Pass-2). User has auto-mode on; background agent execution doesn't block chat.

### SendMessage UUID worked across spawn boundary

For Pass-2 research, Pack Chat used SendMessage with UUID to the already-completed Pass-1 agent. Runtime reported: "Agent had no active task; resumed from transcript in the background with your message." This confirmed pack memory `reference_sendmessage_uuid_addressing` — UUID-based SendMessage works even on completed agents.

---

## §6 — BD landscape evolution

Chronological summary of BD opens during BD-186 sidecar work:

### BD-186 open (2026-05-21, commit `79464ac`)

Requirements-gathering BD with sidecar artifact target. Position: parallel to Batch 19d (BD-185), independent.

### BD-187 open (2026-05-21, commit `cbbce43`)

Parking-lot for "Standalone entry-type instruction doc for external-tool consumption." User raised the broader "instruction doc for all entry types" idea during early triage. Pack Chat surfaced this as deserving its own BD anchor per `feedback_deferred_work_tracking` (live forward-pointing surface rule). User approved opening as parking-lot.

### BD-187 Blockers refinement (2026-05-22, commit `e10a4d0`)

Pack Chat identified that the original BD-187 Blockers conflated AUTHORING blocker with v11.1 IMPLEMENTATION. Refined: authoring blocker = BD-186 close; scheduling judgment = recommend post-v11.1 ship (but technically authorable any time after BD-186 closes).

### BD-188 open (2026-05-22, commit `ad79bf0`)

Parking-lot for "Phase-Iteration sprint view (V11.1 §13 Y-6 optional capability deferred from v11.1 groupings scope)." Surfaced during #15 (Optional/advanced capabilities) triage. User approved opening as parking-lot.

### BD-186 close + REQUIREMENTS-GROUPINGS-V11.md (2026-05-23, commit `5e66836`)

908-line requirements artifact landed. BD-186 status: Open → Resolved. Memory saved (`feedback_groupings_design_principles.md` + `feedback_user_prescriptive_authority.md`).

### REQUIREMENTS-GROUPINGS-V11 amendments (2026-05-23, commit `f22f800`)

Pack Chat artifact review found two minor issues: misleading attribution of C6/C7-as-elaborations framing decision; stale BD-186 "Open → flips to Resolved on this artifact landing" status text. Both fixed in small `fix:` commit.

### Tracker primitives research Pass-1 + Pass-2 (2026-05-23, commit `bfa3a33`)

User approved "C + D" pre-wrap polish: light artifact review + per-backend tracker primitives research. Pack-docs-researcher spawned in background. Pass-1 covered 6 backends; Pass-2 added Tier 1 (Azure DevOps / YouTrack / Asana / ClickUp) + Tier 2 brief survey (10 trackers) + Tier 3 sunset footnote (Pivotal Tracker, Phabricator upstream, Bitbucket Issues — Bitbucket Issues sunset 2026-08-20 surfaced as time-sensitive).

### Handoff doc + xref fix + EXTERNAL-RESEARCH staleness note (2026-05-23, commit `ebdbade`)

Pre-wrap polish bundle: `HANDOFF-V11.1-ARCHITECT.md` written (155 lines; entry-point for future v11.1 architect); cross-reference verification of REQUIREMENTS-GROUPINGS-V11.md (1 fix applied — invented memory ref `feedback_per_bd_inline_review` → replaced with annotated `feedback_review_fix_one_cycle`); EXTERNAL-RESEARCH.md got a staleness header note redirecting readers to the newer research doc.

### BD-189 open (2026-05-23, commit `c9d6dba`)

User asked: is there a BD anchor for the future v11.1+ groupings core implementation? Pack Chat identified the gap (BD-186 Resolved cannot serve as live anchor; BD-187 + BD-188 cover ADJACENT future work, not core). Opened BD-189 as the umbrella parking-lot anchor for v11.1+ implementation per `feedback_deferred_work_tracking`.

### Sidecar wrap (after `c9d6dba`)

CI green; BD-186 sidecar fully wrapped. v11.1 architect handoff package ready in repo.

---

## §7 — Research commissioning (Pass-1 + Pass-2)

### Pass-1 commissioning rationale (2026-05-23)

After BD-186 close, user asked what could be done before v11.0 ships. Pack Chat proposed options A-E; user approved C + D (light artifact review + per-backend tracker primitives research).

Research scope: 6 backends (GH Projects v2 / Linear / Jira Cloud / Redmine / GitLab / Forgejo/Gitea) in full V1-V10 sub-section structure. Primary-source citations required. Read-only on pack source; output to `RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`.

### Pass-1 headline findings

- GH single-select cap is 50, not 25 (V2 inventory stale)
- Linear Initiatives primitive missing from V2 inventory
- Jira deprecations with hard deadlines (sprint REST removing 2026-11-01; points-based rate limits active since 2026-03-02)
- Redmine has NO native webhooks (V2 didn't flag)
- Redmine Issue Category is single-valued (V2 was wrong about multi-valued)
- GitLab Epic REST already removed; GraphQL planned removal at GitLab 19.0
- Forgejo has sharpest capability gap + API-side writes don't emit webhooks
- Multi-grouping-per-item is GH-native + Linear-near-native; others need emulation

### Pass-2 commissioning rationale (2026-05-23)

User requested second pass: Tier 1 (Azure DevOps / YouTrack / Asana / ClickUp) in full structure; Tier 2 (10 long-tail trackers) brief survey; Tier 3 (Pivotal Tracker) sunset footnote; §7 matrix refactor to 0-5 graded comparison with column-group split.

SendMessage via UUID worked to resume the (completed) agent for Pass-2. Researcher returned with deliverables grown from 878 → 1762 lines (research doc) and 166 → 390 lines (IMPL-REPORT).

### Pass-2 headline findings

- Bitbucket Issues sunset 2026-08-20 (within v11.1 window — exclude entirely)
- Pivotal Tracker already decommissioned 2025-04-30
- Asana + ClickUp join GH + Linear as native multi-grouping (4 backends not 2)
- 5 of 10 graded backends have single-valued primary primitive — emulation is the MAJORITY concern
- Azure DevOps + ClickUp introduce hierarchical-path primitives
- YouTrack sprint-across-projects is unique
- Forgejo + ClickUp Free-tier rate limits are tightest

---

## §8 — Forward pointer

The BD-186 work concluded with these durable forward-pointing surfaces:

1. **`maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md`** — single-page entry point for future v11.1 architect; reading order; design principles recap; open architect-level surfaces; critical time-sensitive items.

2. **`maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md`** — primary input; 17 capabilities with problem/goal/SC + user-approved design decisions + architect-level surfaces + cross-references.

3. **`maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`** — verified per-backend facts (Pass-1 + Pass-2; 10 backends graded; gotchas + deprecations).

4. **BD-189** — live forward-pointing anchor for v11.1+ groupings core implementation umbrella. Live BD per `feedback_deferred_work_tracking`.

5. **BD-187** (parking-lot) — entry-type instruction doc for external-tool consumption; adjacent future work; scheduling recommend post-v11.1 ship.

6. **BD-188** (parking-lot) — Phase-Iteration sprint view; V11.1 §13 Y-6 optional capability; scheduling deferred until v11.1+ groupings ship + observed sprint-view demand.

7. **`feedback_groupings_design_principles.md`** + **`feedback_user_prescriptive_authority.md`** — pack memory cache entries; authoritative session content.

The v11.1+ groupings architect reads the HANDOFF doc as their entry point and proceeds from there. This intake doc is supplementary audit-trail material; the REQUIREMENTS doc remains canonical for design.

---

## Conflict resolution reminder

Per user direction 2026-05-24, this intake doc is concerned with conflicts, not gaps. If any statement here contradicts `REQUIREMENTS-GROUPINGS-V11.md` or other committed BD-186 artifacts, the committed artifacts win. This doc is faithful summary; the artifacts are canonical.

---

End of INTAKE-GROUPINGS-V11.md.
