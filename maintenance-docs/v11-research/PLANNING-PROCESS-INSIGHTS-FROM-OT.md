# PLANNING-PROCESS-INSIGHTS-FROM-OT.md

**Authored by:** pack-architect (sidecar review pass for BD-191 + groupings BD-186/BD-189 amendment evaluation).
**Date:** 2026-05-24 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD baseline at authoring:** 3e15ea33.
**Read-only sources:**
- OT planning artifacts at `/Users/david/Developer/<target-project>/docs/reference/planning/feature-brainstorm-1/` (treated as REFERENCE; no writes)
- Pack-side groupings + PS context (paths cited inline)

**Audience:**
- Pack Chat (BD-191 PS triage; potential groupings BD-186/BD-189 amendment)
- v11.1+ groupings architect (downstream consumer; HANDOFF-V11.1-ARCHITECT.md addressee)
- v11.x+ PS architect (downstream consumer)

**Status:** Guidance — informative, not prescriptive. Recommendations are evidence-based; user retains authority to accept, reject, or modify.

---

## §1 — Purpose and scope

This document is a synthesis pass over the OT (the target project) `feature-brainstorm-1/` planning artifacts, distilling patterns that are (a) worth adopting in the pack's design of BD-191 (Product Specialist) and (b) worth considering as amendments to BD-186 (groupings requirements) / BD-189 (groupings implementation umbrella) BEFORE groupings architecture begins.

**What this doc is.** A pack-architect-level critique of OT's planning process as a case study. OT planned a product (the target app) using an ad-hoc sequence of CLI sessions producing 8 deliverables across Phases A → E.2 plus a process subdirectory. The pack is preparing to ship a feature (PS) whose entire purpose is to help client developers do exactly that kind of planning. OT is therefore both a worked example and a stress test of what the pack's PS feature must enable, constrain, and integrate with.

**What this doc is NOT.**
- Not a redesign of OT's planning (that work is locked and downstream of Implementation Phase 58 per OT's README).
- Not architecture for groupings or PS (that's the downstream architect agent's deliverable).
- Not a critique of OT itself as a product.
- Not a license to copy OT's process verbatim. OT's process is observably effective for a single product in a single domain by a single sole-developer audience; the pack must generalize across N projects, N domains, N developer skill levels, N tracker backends.

**Scope boundary discipline (per pack memory P-missed-7).** OT is a project-side artifact. Pack memory rules, pack-* agent names, pack-ops/, and maintenance-docs/ patterns do NOT belong in OT and do NOT govern OT. Equally important: the OT process is not authoritative for the pack. Where OT's discipline patterns are good, the pack adopts them; where they fit OT's specific shape but not the pack's, the pack diverges with reasoning. This doc explicitly applies the SSOT-investigation rule — every recommendation names the pack-side SSOT the change would affect, not "what OT does."

**Three threads run through this doc:**
1. **Transferable patterns** (§3) — OT process disciplines that the pack should adopt or steal.
2. **Failure modes** (§4) — OT patterns that the pack should NOT adopt, with the alternative pattern the pack should consider.
3. **Pack-side actions** (§5-§8) — specific proposals to amend groupings (BD-186 / BD-189), inform PS (BD-191), and direct downstream architect investigation.

---

## §2 — OT directory overview (orientation for downstream architects)

The OT `feature-brainstorm-1/` is laid out as 8 top-level deliverable docs plus 3 subdirectories. Reading order is sequential A → B.1 → B.2 → C → C.5 → D → E.1 → E.2; each phase consumes its predecessors.

**Top-level deliverables (the 8):**

| Phase | File | Role | Discipline characteristic |
|---|---|---|---|
| A | `PHASE-A-vision-and-anti-goals.md` (28KB) | Vision lock, three pillars, three anti-pillars, audience stages, M-cluster definitions (M1-M13), NFRs, conditional-inclusion table, deferred architectural questions | Anti-pillars + conditional-inclusion-with-explicit-triggers; vocabulary lock |
| B.1 | `PHASE-B1-mvp-user-journeys.md` (89KB) | MVP user journeys organized by mode (Building / Discovery / Recovery / Setup); ambient appendix | Mode classification; `[F-NEW]` feature-touchpoint markers; provisional-vocabulary discipline |
| B.2 | `PHASE-B2-post-mvp-user-journeys.md` (55KB) | Post-MVP journeys + 9 architectural seams MVP commits to | Architectural seams as forward-compatibility contract |
| C | `PHASE-C-master-feature-inventory.md` (774KB; 266 features) | YAML-blocks-in-Markdown canonical feature catalog | 17-field schema; no-solutions discipline; stable F-NNN/S-NNN/A-NNN IDs; 9-check audit pass |
| C.5 | `PHASE-C5-ai-roadmap.md` (59KB) | AI substrate roadmap mapping M11's 7 substrate elements to consumers | Domain-substrate-as-shared-infrastructure pattern; cross-phase consumer constraints flow back to MVP |
| D | `PHASE-D-capability-matrix-and-deps.md` (50KB) | NFR capability-surface-to-feature projection + formal dependency graph (foundation/core/polish layered) | Mechanical script-checked layering (cycles / orphans / depth / fan-out); graph computes sequencing |
| E.1 | `PHASE-E1-OT-PRD-v1.md` (97KB) | Narrative PRD for human reader (engineers / investors / re-review) | Narrative synthesis; opinionated about WHAT and WHEN; silent about HOW |
| E.2 | `PHASE-E2-OT-FEATURE-BACKLOG-v1.md` (3.0MB; 1,326 work items) | Machine-parseable backlog for PM-chat ingestion | Generic 7-value work_type enum; WI-NNNN IDs; dependency-wired |

**Subdirectories:**
- `process/` — orchestration scaffolding (PHASE-PLANNING-CLI-MASTER.md + 5 per-phase satellite CLI-instruction docs) + 2 tracking files (BACKLOG-PLANNING.md TDP-NNN + PLANNING-PENDING-AMENDMENTS.md PA-NNN)
- `generated/` — script outputs (CSV/XLSX/DOT/SVG)
- `external-feedback/` — ChatGPT + Gemini research inputs

**Identifier namespace (informative for §3 patterns).** OT uses **seven** independent identifier schemes across the planning sequence: M1-M13 (clusters), J-X-NN (journeys), Seam #N (seams), F-NNN / S-NNN / A-NNN (features/shared/ambient), PA-NNN (amendments), TDP-NNN (planning tech debt), WI-NNNN (work items). The pack today has: BD-NNN (backlog), TD-NNN (tech debt; project-side), phase-N / phase-N.M / phase-N.Part-M (implementation plan), CL-NNN (changelog entries), GRP-NNN (groupings, designed; not shipped). The discipline match is partial; cross-cutting patterns are highlighted in §3.4.

---

## §3 — Transferable patterns (recommended for adoption)

Patterns from OT's planning process that the pack should consider distilling. Each entry: brief description, OT source citation, applicability ratings to PS (BD-191) and to groupings (BD-186/189), and what specifically to adopt.

### §3.1 — The "no-solutions discipline" as a load-bearing prompt-construction rule

**Description.** OT's Global Rule G1 (`process/PHASE-PLANNING-CLI-MASTER.md:26-37`) forbids any planning-document field describing *what must be true* from prescribing *how the system achieves it*. Concretely: state names, enum cases, type names not in `existing_code`, file paths not in `existing_code`, data-structure shapes, UI affordances, algorithms or named patterns are forbidden in `description / problem / goals / success_criteria / architect_notes / design_notes`. The test, applied to every line: "Could a competent architect reading this field reasonably arrive at a different concrete design while still satisfying the field's intent? If only one design fits, revise." `existing_code` is the *only* field permitted to carry codebase specifics. The rule was applied through 9 audit-check rules in `PHASE-C-master-feature-inventory.md:151-164` and surfaced PA-001 through PA-007 as concrete violations corrected in v1.1-v2.A passes (`process/PLANNING-PENDING-AMENDMENTS.md`).

**OT source:** `process/PHASE-PLANNING-CLI-MASTER.md` Rule G1 (lines 26-37); `PHASE-C-master-feature-inventory.md` "No-solutions discipline" section (lines 113-136); `process/PLANNING-PENDING-AMENDMENTS.md` PA-001/PA-002/PA-003/PA-005/PA-006/PA-007 (worked failures + corrections).

**Applicability to PS (BD-191):** **HIGH.** PS's entire output is requirements-shaped: PRDs, user-journey docs, feature lists, mapping docs. Every one of those documents has the same "describe what must be true, not how" character. PS-produced PRDs that leak solutions are exactly the "decorative artifacts" failure mode flagged by `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §9.1.

**Applicability to groupings (BD-186/189):** **MEDIUM.** Groupings docs are short (5 required fields + optional PRD ref); the surface for "solution leakage" is small. But the PRD field per Capability #1 SC1.2 is free-text and a likely site for problems. The discipline is worth carrying as a per-stream `_rules.md` line for the grouping `Description` field.

**What to adopt:**
1. **PS feature requirements (BD-191).** Capability #4 (Structured interview process) gains an explicit "no-solutions discipline" sub-criterion: PS-produced PRD / journey / feature-list / mapping fields describing requirements may not prescribe states, enums, types, paths, data shapes, UI affordances, or algorithms. PS-produced `existing_code`-equivalent fields (i.e., "what already exists in the project codebase") MAY carry concrete codebase specifics. The interview must elicit content into the right field-kind, not the wrong one.
2. **PS deliverable templates (downstream architect surface).** Each template (PRD, user-journey doc, feature-list doc) carries a header note that names the no-solutions rule, plus a self-test sentence at the top of each prescribable section. Reviewer agent (or auditor) verifies the discipline before deliverable lands.
3. **Groupings `_rules.md` (BD-186 amendment candidate).** Add a one-line note to the groupings `_rules.md` template: "Grouping `Description` field describes what the grouping IS, not how phases must be implemented. State machines, code structure, and implementation patterns belong in member-phase docs." Negligible scope addition; closes a leak vector PS will create.

**Why this is better than the pack default of "just review for quality."** A general "this should be good" instruction is unverifiable. G1-style discipline is checkable line by line (the "could a competent architect arrive at a different design" test); when paired with auditor verification, it produces consistently architectable input regardless of who authored it.

### §3.2 — Anti-pillars + conditional-inclusion table with explicit triggers

**Description.** OT's Phase A v3 §3 lists three anti-pillars — explicit statements of what OT is NOT (each names an adjacent market segment or product shape the product deliberately does not serve). Phase A v3 §5 includes a conditional-inclusion table (lines 131-133) listing items that are OUT today, paired with the specific trigger that would move them IN. Each row names the gate — an out-of-scope capability plus the concrete condition that would admit it — e.g.: "<advanced-capability-A> — integration of an upstream provider whose API supports it. <advanced-capability-B> — the same upstream-integration gate. <team / multi-user capability> — a large strategic investor or paying enterprise customer requiring it. <marketplace capability> — a user base of several thousand active users *and* survey evidence of demand. ..." The table is what replaced an earlier "Never" list in v2.

**OT source:** `PHASE-A-vision-and-anti-goals.md` §3 (lines 47-59); §5 conditional-inclusion table (lines 131-133); Changelog v2 entry (lines 195-203) on the Never → conditional shift.

**Applicability to PS (BD-191):** **HIGH.** The PS interview produces a PRD which, by §9.3 RESEARCH common-denominator pattern, includes Goals + Non-Goals as a paired section. Conditional-inclusion-with-explicit-triggers is the more rigorous form of Non-Goals: it forces the user to articulate "what would change my mind" rather than just "what's out." This directly addresses the §9.1 RESEARCH finding that bad PRDs come from "people don't know what they want."

**Applicability to groupings (BD-186/189):** **LOW.** Groupings membership is explicit-by-design (Capability #2). Anti-pillars don't apply at the grouping-doc level. There's a faint parallel: the C7 graceful-tracker-degradation principle is implicitly an anti-pillar ("not LCD"), and the per-backend capability matrix is implicitly a conditional-inclusion table for tracker features. But this is decoration on existing structure, not an adoption.

**What to adopt:**
1. **PS deliverable template — PRD shape.** The PRD template includes three sibling sections:
   - **Pillars** (positive commitments — what the product IS)
   - **Anti-pillars** (deliberate exclusions — what the product is NOT, with reasoning, not just absence)
   - **Conditional inclusions** (items currently out, with the specific trigger that would change the verdict)
2. **PS interview structure (Capability #4).** Each interview section asks for the anti-pillar pair, not just the pillar. "What is the product NOT? What is the trigger that would make X in-scope?"
3. **PS audit checklist.** A PRD that contains no anti-pillars / no conditional inclusions has not done the work. Capability #6 "complete" criteria SHOULD include at minimum-one anti-pillar + at minimum-one conditional inclusion as a structural completeness bar.

**Why this is better than the pack default of "user lists Non-Goals."** "Non-Goals" without triggers ages into ambiguity ("did we change our minds?"). Conditional-inclusion with explicit triggers preserves the decision rationale across time and across team changes. OT's v2 changelog notes this was a deliberate change from a "Never" list precisely because Never is brittle.

### §3.3 — Two-document split: narrative human-PRD + machine-parseable backlog

**Description.** OT produces both `PHASE-E1-OT-PRD-v1.md` (97KB, narrative prose synthesizing all prior phases for human readers — engineers / investors / re-review) and `PHASE-E2-OT-FEATURE-BACKLOG-v1.md` (3.0MB, 1,326 YAML-blocks-in-Markdown work items for programmatic PM-chat ingestion). The two are deliberately separate because they serve different consumers with different reading needs: narrative for humans (story arc, positioning, opinion); structured for agents (schema-clean, dependency-wired, predictable per-item). Phase E.2's satellite (`process/PHASE-E2-CLI-INSTRUCTIONS.md:18-25`) explicitly notes: "A PRD-style narrative (Phase E.1) is wrong for this role; a feature inventory (Phase C) is too coarse — features are larger than work items."

**OT source:** `PHASE-E1-OT-PRD-v1.md` (whole doc); `PHASE-E2-OT-FEATURE-BACKLOG-v1.md` schema (lines 27-56 of `process/PHASE-E2-CLI-INSTRUCTIONS.md`); reading-order distinction in README.md lines 39-40.

**Applicability to PS (BD-191):** **HIGH.** This pattern resolves a tension in INTAKE-PS-V11.md §8 §1 "PRD authoring": is the PS PRD a narrative or a structured doc? The OT answer is: it's both, in two documents, with different audiences. PS should split its core deliverable into (a) narrative PRD for human re-reading + investor/eng onboarding + opinionated positioning; (b) structured "feature/work-item" backlog for downstream pack ingestion. They share underlying content; they don't share format.

**Applicability to groupings (BD-186/189):** **LOW.** Groupings are already structured-only (per Capability #5). No narrative form is needed because groupings are not consumed by humans for positioning — they're consumed for navigation.

**What to adopt:**
1. **PS deliverable set (Capability #1 + #8 amendment).** Split the PS canonical-output set so that "PRD" is a narrative artifact (with the anti-pillars / pillars / conditional inclusions per §3.2) AND there's a separate structured "feature list" or "feature inventory" artifact that the pack can ingest into groupings / phases / backlog with minimal translation. The current INTAKE-PS-V11.md §8 list has #8 PRD and #10 feature list + mapping; restructuring is recommended so the PRD is explicitly narrative and the feature list is explicitly structured. Mapping doc per §3.5 sits between them.
2. **PS audience-aware writing (Capability #12).** Each deliverable header carries explicit audience-naming (narrative PRD says "for engineers joining the project / re-review / investor"; structured feature list says "for pack ingestion / downstream architect / planner"). The PS interview asks the user "which audience(s) does this need to serve?" Audience-naming is a writing-discipline forcing function.

**Why this is better than a single combined PRD.** Single-doc PRDs end up serving neither audience well — the narrative prose dilutes machine-parseable structure; the structured tables interrupt the narrative arc. OT's discipline keeps each artifact tight to its consumer.

### §3.4 — Stable-identifier-namespace discipline + multi-namespace coordination

**Description.** OT uses seven independent identifier namespaces (M1-M13, J-X-NN, Seam #N, F-NNN, S-NNN, A-NNN, PA-NNN, TDP-NNN, WI-NNNN — see §2). Each namespace has a defined home (one doc owns assignments); IDs are sequential, stable, never re-used; numeric suffixes append, never renumber. The identifier reference table in README.md (lines 42-58) is the canonical map "this prefix → defined in that doc." Phase C feature schema (`PHASE-C-master-feature-inventory.md:50-87`) shows how IDs cross-reference (F-NNN's `dependencies` lists other F-NNN; `shared_with` lists S-NNN; `journey_consumers` lists J-X-NN; `seam_refs` lists Seam #N).

**OT source:** README.md identifier reference table (lines 42-58); per-namespace ID rules in each phase's CLI satellite; PA-008 (`PLANNING-PENDING-AMENDMENTS.md`) as a worked failure where one doc's content drifted from another doc's renumbering ("F-130-series" stale ref).

**Applicability to PS (BD-191):** **HIGH.** PS-produced docs will reference pack primitives (BD-NNN, phase-N, GRP-NNN, TD-NNN). They may also introduce PS-internal namespaces (PRD section IDs, user-journey IDs, feature-row IDs analogous to OT's F-NNN). The pack's existing identifier-namespace discipline (BD-NNN read-tree-then-increment per `pack-ops/PACK-AGENTS.md`) already matches OT's pattern; PS extends it.

**Applicability to groupings (BD-186/189):** **HIGH.** Capability #5 SC5.5 already states: "Numbering rule mirrors BD-NNN: read tree, increment highest; reservation lists from sidecar sessions are not authoritative." OT's worked example PA-008 (stale "F-130-series" reference) validates this rule. The pack's existing discipline + Capability #5 explicit codification is correct.

**What to adopt:**
1. **PS deliverable namespaces (downstream architect surface).** If PS introduces project-side feature IDs (analog to OT's F-NNN) and journey IDs (analog to OT's J-X-NN), the rule is: each namespace has one canonical home doc; assignments are read-tree-then-increment; IDs are stable across versions. The PS interview should ask: "do you already have an identifier convention? If yes, integrate; if no, use the pack default."
2. **Identifier reference table (PS PRD template).** Every PS-produced PRD includes an Identifier Reference table at the top (mirroring OT README.md:42-58) listing every namespace it uses and the doc that defines/owns it. This is a tiny addition that pays off massively for future readers — including the downstream agents that consume the PS output.
3. **Pack-side cross-reference: BD-191 architect surfaces project-side identifier-namespace discipline as a deliverable.** Capability #15 (Workflow + doc integration) gains an SC for "PS deliverables follow the pack's stable-identifier-namespace pattern; new namespaces (if any) declare their home doc in the deliverable header."

**Why this is better than letting projects roll their own.** OT's PA-008 incident — a Phase C feature row referenced "F-130-series <feature-family> journey features" because that was the v0 plan; the actual numbering placed Phase 2 features at F-162+, and the v0 reference wasn't updated when the numbering shifted — is a worked failure of cross-namespace drift. Without a canonical home doc per namespace, drift is invisible until grep-verification surfaces it.

### §3.5 — Bridge doc / "mapping" doc between requirements and execution

**Description.** OT's Phase E.2 is explicitly described as "the bridge between planning and implementation" (`process/PHASE-PLANNING-CLI-MASTER.md:157`). Each WI-NNNN work item carries: a `feature_id` reference back to Phase C, a `phase` layer assignment from Phase D, a `depends_on` list wiring it into the dependency graph, a `work_type` (research / design / implementation / review / audit / testing / ops — generic 7-value vocabulary), `entry_conditions`, `inputs`, `outputs`, `acceptance_criteria`. The PM chat reads the backlog programmatically and constructs agent prompts directly from the work-item fields. The work item is the unit of agent-prompt-ability.

**OT source:** `process/PHASE-E2-CLI-INSTRUCTIONS.md` work-item schema (lines 27-56); generic 7-value work_type discipline (line 113); "the backlog is the bridge between planning and implementation" (line 14).

**Applicability to PS (BD-191):** **HIGH.** Capability #10 in INTAKE-PS-V11.md §8 already names a "Mapping doc bridges PS output → pack primitives (groupings / phases / tasks / backlog entries)." OT's E.2 is the worked example of what this bridge looks like at scale. The user's Q5 direction was "free text" — that's the right starting position for v11.x PS (don't over-engineer) but the bridge function itself is correct and well-understood.

**Applicability to groupings (BD-186/189):** **MEDIUM.** Groupings are themselves a bridge (collection of phases pointing at a higher-level concept). The OT analog is M-cluster (M1-M13). OT's M-clusters are roughly groupings; OT's F-NNN are roughly phase-equivalent units; OT's WI-NNNN are work items below the phase. There's structural alignment worth noting: groupings can be the "user-journey" Kind (per Capability #4 default Kind set) where the journey is OT's J-X-NN equivalent.

**What to adopt:**
1. **PS Capability #10 (Feature list + mapping doc).** The mapping doc is **free-text BUT structured-by-section** — i.e., free prose, but with a section per pack primitive (groupings / phases / backlog) and explicit "Feature X → grouping GRP-NNN" / "Feature X → phase-N" cross-references. This honors the user's Q5 ("probably free text") while adopting OT's discipline that the bridge needs to be readable by the next agent in line.
2. **PS bridge-doc audit criterion (Capability #6 "complete" criteria).** The PS interview is not "complete" until the mapping doc cross-references every PRD feature to at least one pack primitive (or marks it explicitly "future-work / no current grouping").
3. **Cross-feature: groupings ingestion path (cross-ref to groupings Capability #7).** Capability #7 SC7.6 already names "External task-level references roll up to parent phases per C1 phases-only membership." OT validates this: WI-NNNN work items have `feature_id` pointing at F-NNN; F-NNN aggregates into M-cluster; M-cluster is groupings-equivalent. The pack's design here is correct.

**Why this is better than ad-hoc handoff.** Without a bridge doc, the next agent in line has to re-read all the upstream content and re-do the mapping work. OT's E.2 is what makes Implementation Phase 58 mechanical. Pack PS without the bridge would force groupings authorship to re-derive content the PS interview already elicited.

### §3.6 — Per-phase satellite instruction docs with stop-and-confirm gates

**Description.** OT's process directory contains `PHASE-PLANNING-CLI-MASTER.md` (orchestration entry, 187 lines) PLUS five per-phase satellite instruction docs (`PHASE-C-CLI-INSTRUCTIONS.md`, `PHASE-C5-CLI-INSTRUCTIONS.md`, `PHASE-D-CLI-INSTRUCTIONS.md`, `PHASE-E1-CLI-INSTRUCTIONS.md`, `PHASE-E2-CLI-INSTRUCTIONS.md`). Each satellite specifies: prerequisites (what prior phases must be committed), deliverables (exact file paths produced), order of execution (numbered steps), schema reference, discipline reminders, source materials, verification protocol, stop signal format. Rule G6 (`process/PHASE-PLANNING-CLI-MASTER.md:62-66`) makes stop-and-confirm between phases NORMATIVE: "After completing each phase's deliverables and verification, you stop. You do not begin the next phase until the user explicitly directs you to."

**OT source:** `process/PHASE-PLANNING-CLI-MASTER.md` Rule G6 (lines 62-66); five satellites in `process/` (each 12KB-49KB); Rule G7 verification before stop (lines 68-70).

**Applicability to PS (BD-191):** **HIGH.** PS work is multi-stage (interview → research → PRD draft → user-journey doc → feature list → mapping doc). Each stage benefits from user-confirm-before-next-stage. The pack already has this pattern at the architect-planner-coder level (per pack memory `feedback_planner_user_review_before_coder`). PS's internal stages should inherit it.

**Applicability to groupings (BD-186/189):** **MEDIUM.** The v11.1 groupings architect work is the architect / planner / coder pipeline (HANDOFF-V11.1-ARCHITECT.md §Pipeline-forward + REQUIREMENTS-GROUPINGS-V11.md §6) which already has the stop-and-confirm gate pattern via pack memory. The per-BD breakdown (likely BD-A through BD-K per REQUIREMENTS §5 "BD landscape") naturally introduces stop-confirm gates as each BD commits.

**What to adopt:**
1. **PS multi-stage workflow (Capability #15 amendment).** The PS workflow (downstream architect surface) defines explicit user-confirm checkpoints between major PS stages: (a) interview complete → user reviews interview summary; (b) PRD drafted → user reviews PRD; (c) journey docs drafted → user reviews journeys; (d) feature list + mapping drafted → user reviews mapping; (e) full set ready for groupings ingestion → user authorizes. Mirrors OT's "phase committed; user directs continue" pattern.
2. **PS satellite-doc analog.** Each PS stage's "what to ask / how to ask / what to produce / verification protocol" lives in a per-stage skill or methodology document, analogous to OT's per-phase satellite. This is concretely the question "do we have one big PS skill or several specialized PS skills?" (which the user's Q8 left to the architect). OT's pattern argues for several.

**Why this is better than one big PS skill.** OT's master + 5 satellites totals 174KB of process scaffolding. A single combined doc at that size is unmanageable; the satellite split keeps each stage's instructions focused. The pack's existing skill-file pattern (per `project-template/skills/`) already supports this split-by-stage; PS just needs to follow the convention.


### §3.7 — Architectural seams as forward-compatibility commitments

**Description.** OT's Phase B.2 v2 introduces "architectural seams" (Seam #1 through Seam #9) — explicit MVP architectural commitments designed so post-MVP features land additively rather than requiring rework. Examples (from `PHASE-D-capability-matrix-and-deps.md:41-44`): Seam #3 (a core domain-model schema designed for additive extension — admits new entity variants without migration); Seam #4 (per-content-type caching policy); Seam #7 (AI provider auth-model polymorphism — admits API-key + endpoint-URL + system-permission). Each seam is a load-bearing decision recorded BEFORE the post-MVP feature that depends on it is built. Phase C features carry `seam_refs` listing which seams they implement; Phase D coverage findings (§4) verify every seam has at least one Phase C feature carrying it forward.

**OT source:** `PHASE-A-vision-and-anti-goals.md` references seams in §6 NFRs; `PHASE-B2-post-mvp-user-journeys.md` defines Seam #1-#9; Phase C `seam_refs` field per `PHASE-C-master-feature-inventory.md:64-65`; Phase D §1 capability matrix cross-references seams (e.g., line 44 Seam #3).

**Applicability to PS (BD-191):** **HIGH.** PS will produce PRDs and journey docs that may name post-MVP features. Each post-MVP feature has an MVP architectural dependency — the seam. Without the seam concept, post-MVP features are either retro-fitted (expensive) or omitted (lost). The PS PRD template should explicitly distinguish "MVP requirements" from "post-MVP requirements" AND "MVP architectural seams that admit post-MVP additively."

**Applicability to groupings (BD-186/189):** **MEDIUM.** Groupings of Kind `architectural-pattern` (per Capability #4 default Kind set) naturally hold architectural seams. The seam is the grouping; the member phases are the MVP work that establishes the seam. Worth noting in BD-187 (entry-type instruction doc, currently parked) when it lands.

**What to adopt:**
1. **PS PRD template — three-section roadmap.** Each PRD includes "MVP / Phase 2 / Phase 3" (or "v1 / v2 / vN") plus "Architectural commitments MVP makes for forward compatibility." The latter is the seams list with one-sentence rationale per seam.
2. **PS interview structure.** During the PRD interview, after eliciting MVP and post-MVP features, the PS asks: "What architectural commitment does MVP need to make so that <post-MVP feature> can be added without rewriting <MVP subsystem>?" Forces the user to think forward-compatibility, not just immediate scope.
3. **Groupings Kind addition (potential BD-186 amendment — see §5).** Consider whether `architectural-seam` is distinct enough from `architectural-pattern` to warrant a separate Kind value. Current default 9-Kind set has `architectural-pattern`; OT's worked example shows seams are a specific sub-type with forward-compatibility purpose. Likely conclusion: the 9-Kind extensible enum (Capability #4) supports per-project extension; this is exactly the case for it. No amendment needed.

**Why this is better than "we'll figure it out when we get there."** OT's seam discipline is the reason Phase 2 / Phase 3 features in Phase C can be added with `dependencies` lists pointing at MVP `seam_refs` rather than rewriting MVP. Without seams, post-MVP work cascades back into MVP scope. The pack's PS feature should encourage this discipline directly.

### §3.8 — Self-audit pass with concrete check rules per phase

**Description.** Every OT phase ships with a verification protocol (Rule G7) and a concrete check list. Phase C ships 9 audit checks (`PHASE-C-master-feature-inventory.md:153-164`): orphan check, reverse-orphan, symmetry, journey-coverage, seam-coverage, field-consistency, .swift-extension, cross-cluster shared_with, no-solutions. Phase D ships 6 audit checks per its script (`process/PHASE-D-CLI-INSTRUCTIONS.md:124-132`): cycles, orphans, depth, fan-out/fan-in, cross-cluster edges, foundation/core/polish layering. Many checks are mechanical (script-runnable); some require human judgment (no-solutions). The amendments backlog (`process/PLANNING-PENDING-AMENDMENTS.md`) tracks audit-surfaced items per BD with explicit Resolved / Rejected dispositions.

**OT source:** Per-phase verification sections in each CLI satellite; Phase C audit pass (lines 153-164); Phase D script audit (`PHASE-D-CLI-INSTRUCTIONS.md:124-132`); worked examples in PA-013 / PA-014 / PA-016.

**Applicability to PS (BD-191):** **HIGH.** PS-produced docs have characteristic failure modes (per §9.1 RESEARCH): decorative PRDs, methodology-pick-without-rationale, untested personas, missing market evidence. Each is checkable. The PS deliverable set should ship with an audit-pass spec naming the concrete checks that verify quality.

**Applicability to groupings (BD-186/189):** **HIGH.** Capability #13 already designs validate-pack checks for groupings (SC13.1-SC13.21). OT validates the pattern. Worth comparing OT's audit-pass discipline (Phase C 9 checks + amendments tracking) against pack's existing validate-pack structure to ensure parity in coverage.

**What to adopt:**
1. **PS audit-pass deliverable (Capability #7 amendment or new capability).** The PS feature ships a per-deliverable audit-check spec: PRD audit (does it have anti-pillars / conditional inclusions / outcomes-over-outputs vocab / Goals+Non-Goals); user-journey audit (mode-classified, success-criteria stated, anti-goal stated); feature-list audit (every feature references a problem statement, success criteria stated, no-solutions discipline applied); mapping-doc audit (every PS feature maps to at least one pack primitive). Audit is mechanical where possible (skill or sub-agent runs the checks); user-judgment-required items are flagged.
2. **PS amendment tracker (potential PS-internal pattern).** OT's `PLANNING-PENDING-AMENDMENTS.md` tracks PA-NNN items across phases as a separate stream. PS may benefit from an analog — a tracked "PRD revision" stream where issues surfaced during downstream consumption (groupings authoring, architect work) flow back as amendments to the PS PRD rather than ad-hoc edits. Worth investigation during BD-191 triage; could be heavyweight overkill for a solo-developer use case.
3. **Groupings audit-pass parity check (no BD-186 amendment needed).** Capability #13 audit-check set (SC13.1-SC13.21) appears comprehensive against OT's pattern. No amendment recommended — but the groupings architect should cross-check against OT's 9-check list (`PHASE-C-master-feature-inventory.md:153-164`) during design to confirm no gap.

**Why this is better than "the reviewer catches it."** OT's amendments backlog records 16 PA-NNN items surfaced through self-audit; most were corrected before the next phase consumed the deliverable. A reviewer pass at end-of-phase catches some of these; per-phase mechanical audits catch the rest before they propagate.

---

## §4 — Failure modes (patterns to AVOID)

Patterns from OT's planning process that the pack should NOT adopt, with rationale and alternative.

### §4.1 — Mode-1 (state) ambiguity: tracker.toml-mode-style assumptions written into ad-hoc directory layouts

**Description.** OT's planning artifacts live at `docs/reference/planning/feature-brainstorm-1/` — a hand-chosen directory under `docs/reference/` with a `-1` suffix presumably anticipating future `-2`, `-3` rounds. There is no schema declaration of "this is a planning workspace"; no manifest; no `_rules.md` analog declaring per-stream contract; the README is informative narrative, not authoritative contract. Multiple ID namespaces (M, J, F, S, A, PA, TDP, WI) coexist without a single declared home for "if you add a new namespace, here's where you declare it." Future planning rounds (`feature-brainstorm-2`) would have to either (a) duplicate the directory structure ad hoc or (b) regularize this one retroactively. Per OT README.md §75-81, the subdirectory layout (process/ / generated/ / external-feedback/) is informative.

**OT source:** `feature-brainstorm-1/README.md` directory layout (lines 9-25); no `_rules.md` / no per-stream contract declaration; numbered-round assumption embedded in directory name.

**Why this is a failure mode for the pack.** The pack design (per BD-186 Capability #5 SC5.1 / Capability #5 "Differences from existing per-entry trees" table) explicitly uses `_rules.md` + `_intro.md` + `_toc.md` per-stream contract files. The pack's discipline is: the per-stream tree's rules are codified in the tree's supporting files, not in a hand-chosen README. The pack should NOT replicate OT's ad-hoc structure when designing PS deliverable locations or PS workspace conventions.

**Alternative the pack should consider:** PS-produced docs live in a per-stream tree following the pack's existing convention. The user's Q4 + Q5 + Q9 framing supports this: "These are working docs that can be use to be broken down into groupings..." A PS workspace at `project-template/docs/project/product/` (proposed name; architect decides) with `_rules.md` (declares: what docs live here, what their fields are, what audit checks apply), `_intro.md` (narrative orientation), `_toc.md` (auto-generated index), and per-deliverable files (`PRD-vN.md`, `JOURNEY-J-XXX.md`, `FEATURE-LIST-vN.md`, `MAPPING-vN.md`). Mirrors backlog / implementation-plan / changelog / groupings (designed) per-stream tree pattern.

**Recommendation for BD-191:** Capability #1 PS feature core shape adds an SC: "PS deliverables live in a per-stream tree at `project-template/docs/project/<name>/` following the pack's established per-stream-tree contract (mandatory `_rules.md` + `_intro.md` + `_toc.md` + per-entry files)." The architect chooses the directory name (`product/` or `ps/` or `requirements/` etc.) but the structural pattern is locked.

### §4.2 — Dependency-cycle landslide: graph cycles surfacing late, requiring cluster-wide rework

**Description.** OT's Phase D script (`process/PHASE-D-CLI-INSTRUCTIONS.md:124-132`) ran a cycle detector against Phase C's `dependencies` lists. Result (per PA-013): 7 dependency cycles, 60 of 196 MVP features unlayerable until cycles broken. The cycles were Phase C YAML drafting artifacts (mutual dependency declarations between feature pairs) — not real architectural problems, but they had to be detected and resolved through architect judgment before Phase D's layered graph could be trusted. The Phase D `mvp_priority` layering audit also surfaced 14 mismatches (PA-014) where a `foundation` feature depended on a `core` feature, requiring per-feature relabeling. The fixes required round 1 + round 2 + round 3 of Phase C inventory cleanup. Total recovery: significant; bounded by architect availability + the existence of the script.

**OT source:** `process/PLANNING-PENDING-AMENDMENTS.md` PA-013 (7 cycles, 60 unlayerable features) + PA-014 (14 layering mismatches) + PA-016 (3 questionable orphan features); `PHASE-D-capability-matrix-and-deps.md:140` ("Phase C cleanup broke the seven cycles surfaced at Phase D's script-output checkpoint").

**Why this is a failure mode for the pack.** OT had to ship the cycle detector AS PART OF Phase D to find these. The pack's PS feature, if it produces a feature list with dependencies (per §3.5 mapping-doc adoption), would inherit this risk. The failure mode isn't "cycles happen" (they will); it's "cycles surface at the WRONG stage — after major content has already been written assuming the graph is acyclic — requiring rework that propagates back through the content."

**Alternative the pack should consider:** PS deliverable audit (per §3.8) includes a cycle-detection check AS the feature list is being authored, not at the bridge-doc / mapping-doc stage. If PS produces a feature list with `depends_on` / `unblocks` cross-references between features, the audit pass walks the dependency graph at each feature-row commit and flags cycles immediately. The check is cheap (Tarjan SCC algorithm on a ≤266-node graph runs in milliseconds); the cost of waiting is high.

**Recommendation for BD-191:** Capability #11 (Research orchestration) or a new capability for "PS deliverable validation" should include: cycle detection + layering audit + orphan check for any PS-produced feature list. The audit can be a sub-agent (`pack-docs-researcher`-pattern auditor for PS) or skill-level mechanical check. Architect decides shape; this guidance flags the failure mode for explicit treatment.

**Recommendation for groupings (BD-186/189):** Capability #2 SC2.5 already states "Groupings have NO declared dependencies." This sidesteps the cycle failure mode entirely at the grouping level — but inter-grouping execution order is derived from member-phase Blockers/Unblocks (also SC2.5). The phase-level dependency graph is the cycle-vulnerable surface. Capability #13 SC13.4 catches dangling member references but does NOT explicitly catch member-phase dependency cycles. **Potential BD-186 amendment:** add SC13.X "Phase-level dependency cycle detection runs as part of validate-pack; cycles within a grouping's member-phase set fail validation with a typed error per BD-070." This is small-medium scope; it's the OT failure-mode lesson applied. See §5.

### §4.3 — Heroic single PM-chat session breaking under tool-induced corruption

**Description.** OT's `process/PHASE-PLANNING-CLI-MASTER.md:5` discloses: "Previous PM-chat sessions established Phase A v3 (Locked), Phase B.1 v3 (Draft), and Phase B.2 v2 (Draft). Phase C M1 features F-001 through F-012 were drafted but never cleanly committed due to tool-induced corruption. The remaining phases are pending. The PM chat that produced this document is being retired in favor of CLI for all subsequent planning work." Phase C's CLI satellite then has a special Step 2 ("M1 cluster — verbatim") that uses a `PHASE-C-CLI-RESUMPTION.md` file containing the M1 features as verbatim content to be copy-pasted character-for-character into the new doc — a recovery mechanism necessitated by the prior PM-chat failure.

**OT source:** `process/PHASE-PLANNING-CLI-MASTER.md` lines 5 + 176-184 ("On the resumption file from the previous PM chat"); `process/PHASE-C-CLI-INSTRUCTIONS.md` Step 2 (lines 122-135).

**Why this is a failure mode for the pack.** The OT pattern collapsed a long-running PM-chat into a single session attempting to produce 12+ features of 17-field YAML each. Hit a tool corruption, lost work, had to reconstruct from a resumption file. The pack's PM-chat session-bloat patterns (per `pack-ops/PACK-CHAT.md`) already have memory-rotation discipline, but PS sessions producing PRDs + journeys + feature lists could hit the same wall.

**Alternative the pack should consider:** PS work is structured as multiple short sessions, one per stage, each committing its deliverable before the next session starts. Mirrors the pack's existing per-batch / per-BD commit discipline. PS interview → commit; PRD draft → commit; journey doc → commit; feature list → commit; mapping doc → commit. Each session reads the prior committed deliverable; no in-memory chain. If a session corrupts, only the current stage is lost.

**Recommendation for BD-191:** Capability #3 (Invocation model) already has the right framing (episodic — project init + milestone spikes). Architect surface (downstream) should articulate the per-stage commit boundary explicitly: "Each PS stage produces one deliverable; the deliverable commits before the next stage begins; no PS stage produces multiple deliverables in one session." Aligns with §3.6 stop-and-confirm gates.

### §4.4 — Solution leakage discovered LATE in committed content

**Description.** OT's no-solutions discipline (§3.1) is robust as a rule, but PA-001 / PA-002 / PA-003 (`PLANNING-PENDING-AMENDMENTS.md`) record violations of the rule discovered DURING THE V1.1-V1.3 AUDIT PASS, not at authoring time. Each was a sentence misframing "Phase D may consolidate" (prescribing a phase-role) that survived the v1.0 author + v1.0 review + got caught only by v1.1 grep verification. These are small failures (single-sentence corrections), but the pattern — "audit catches what review didn't" — is a process gap. If the v1.1 audit had not been run, the violations would have shipped into Phase D's input, possibly compounding.

**OT source:** `PLANNING-PENDING-AMENDMENTS.md` PA-001 (lines 35-51), PA-002 (lines 53-68), PA-003 (lines 70-88).

**Why this is a failure mode for the pack.** PS will produce more text than groupings or backlog entries. More text = more places for solution leakage. The OT pattern shows that author-pass + reviewer-pass + audit-pass are not redundant — each catches a different class of failure. Pack reviewer agent (`project-template/.claude/agents/reviewer.md`) catches some; mechanical audit catches more.

**Alternative the pack should consider:** PS deliverable audit (per §3.8 recommendation 1) runs a no-solutions-discipline grep pass at audit time, catching the specific failure modes OT's PA-001/002/003 worked: any prescribed enum cases, type names, file paths, state names appearing in PRD / journey / feature-list fields where they shouldn't. The audit's grep regexes are seeded with OT's discovered violations (e.g., "may consolidate", ".notification(severity:" style enum-case leakage, "F-NNN-series" stale references).

**Recommendation for BD-191:** Capability #6 "complete" criteria amendment: "PS deliverables pass a mechanical no-solutions-discipline audit pass before the deliverable is declared complete. The audit's grep regex set is seeded with the OT-derived violation patterns + extended per-project as new patterns surface."

### §4.5 — Generic 7-value work_type enum collapses domain-specific work-shape variation

**Description.** OT's Phase E.2 commits to a 7-value `work_type` enumeration: `research | design | implementation | review | audit | testing | ops` (`process/PHASE-E2-CLI-INSTRUCTIONS.md:113`). The pack's per-BD work shape is more nuanced — pack BDs include architect / planner / coder / reviewer cycles that don't cleanly map to OT's enum. Pack memory `feedback_review_fix_one_cycle` describes "per-BD inline review + end-of-batch reviewer" which is a different cadence than "review work_type after implementation work_type." OT's generic enum works for OT because OT trusts the PM chat to apply its own agent-assignment rules (`PHASE-E2-CLI-INSTRUCTIONS.md:14-15`); the enum is a hint, not a contract.

**OT source:** `process/PHASE-E2-CLI-INSTRUCTIONS.md` work_type vocabulary (lines 36-38, 113, 139); `PHASE-E2-CLI-INSTRUCTIONS.md:14-15` ("Phase E.2 is not aware of which agents exist").

**Why this is a failure mode for pack adoption of the pattern.** If PS's mapping doc (per §3.5) uses OT's exact 7-value enum, it under-constrains the pack-side work routing. Pack-side work routing already has architect / planner / coder / reviewer / auditor / docs-researcher / pack-chat agent roles; PS-produced mapping should produce work items that route to specific pack agents, not generic types.

**Alternative the pack should consider:** PS mapping doc uses **pack-native work-type vocabulary** matching the pack's agent roster — `architect / planner / coder / reviewer / auditor / docs-researcher / pack-chat-triage`. This is per-project extensible (per principle 4 tracker-portability analog): clients with custom agents extend the enum in their project's `_rules.md`. The vocabulary lives in `project-template/docs/pack/PM-CHAT.md` File access strategy section (proposed; architect places).

**Recommendation for BD-191:** Capability #10 amendment: mapping doc work-type vocabulary is pack-native (matching `project-template/.claude/agents/` roster) and per-project extensible. Avoids OT's "PM chat applies its own rules" loose coupling — pack's PM chat reads work_type and dispatches deterministically.

### §4.6 — Hand-curated cross-reference indexes that drift from per-entry content

**Description.** OT's Phase C ships cross-reference indexes (`PHASE-C-master-feature-inventory.md:138-149`): feature_id → cluster, cluster → feature_ids, journey → feature_ids, seam → feature_ids, external_research_needed → feature_ids, existing OT code symbol → feature_ids. The indexes are "regenerated by the export script alongside the CSV/XLSX output" (line 149). This is the right pattern (per-entry tree is source of truth; indexes regenerate) — but the OT pattern relies on a Python script run on demand, not a CI-enforced trigger. If a Phase C author edits a feature row's `cluster` field and forgets to re-run the script, the index lies until next CSV regeneration. Pack-side parallel: `_toc.md` regeneration is run mechanically per BD-164 pattern; the pack's discipline here is stronger than OT's.

**OT source:** `PHASE-C-master-feature-inventory.md:138-149` cross-reference indexes (regenerated by script, not CI-enforced).

**Why this is a failure mode if uncritically adopted.** PS produces multiple deliverables that will likely have cross-references (PRD → features, features → groupings, features → phases, journeys → features). If the pack adopts hand-curated indexes without mechanical regeneration + validate-pack gate, drift is guaranteed.

**Alternative the pack should consider:** PS deliverable cross-references are auto-rendered by per-stream `_toc.md` (or analog) generators, and validate-pack catches drift via existing Check 33 (toc_in_sync) extended for the PS stream. Mirrors groupings Capability #13 SC13.10.

**Recommendation for BD-191:** Capability #13 (Cross-feature integration with groupings) gains an SC: "PS deliverable cross-references (PRD → features, features → groupings, etc.) are rendered via `_toc.md`-style generator with validate-pack drift detection. No hand-curated indexes." Aligns with groupings discipline.


## §5 — Cross-feature touch points + blast radius: proposed amendments to groupings (BD-186 / BD-189)

This section enumerates specific changes the OT lessons suggest for groupings, with full blast radius analysis. The user's direction is binding: "scope must be intentional with logical reasoning and evidence for what better is. Not just arbitrarily thinking that smaller or no change is better." Each amendment is evidence-based; small-no-amendment is the default ONLY where evidence points there.

**Critical context.** Per pack memory, BD-186 (REQUIREMENTS-GROUPINGS-V11.md) is the requirements lock for groupings. BD-189 is the implementation umbrella; downstream architect / planner / coder work has not yet started. THIS is the window. The architect is the consumer; HANDOFF-V11.1-ARCHITECT.md addresses them.

### §5.1 — AMENDMENT CANDIDATE 1: Add inter-grouping cycle detection to validation (per §4.2)

**Proposed change.** REQUIREMENTS-GROUPINGS-V11.md Capability #13 (Validation) adds an SC13.X: "Phase-level dependency cycle detection runs as part of validate-pack. Cycles within a grouping's member-phase set fail validation with a typed error per BD-070. Cycle detection runs across the union of member-phase dependency graphs (covers inter-grouping cycle implications)."

**Affected REQUIREMENTS-GROUPINGS-V11.md sections.**
- Capability #13 (Validation): add SC13.X cycle-detection criterion; add to "User-approved design decisions" sub-list (b) as a NEW check (currently has 2 new mandatory checks; this adds a 3rd).
- Capability #9 (Operational verbs): `pack groupings deps` and `pack groupings order` are already named as derived queries (SC9.8). The cycle detector is shared infrastructure with these verbs per SC9.9. Cross-reference SC9.9 to the new SC13.X.
- Capability #11 (Tracker capability matrix): no impact — cycles are at the phase-dependency graph level, tracker-agnostic.

**Blast radius (other artifacts).**
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §10 (validator footprint) — extends with cycle-detection coverage.
- HANDOFF-V11.1-ARCHITECT.md §"Open architect-level surfaces" — adds cycle-detection algorithm + persisted-vs-rebuild as architect choice (mirrors SC9.9 framing).
- `scripts/validate-pack.py` (downstream coder surface) — extends with new check function (mirrors existing Tarjan-style cycle pattern if any; otherwise minimal new infrastructure given graph is small).
- `test-fixtures/` — new negative-case fixture for "grouping with member-phase dependency cycle."
- `pack-ops/HELP-FRAGMENT-TRACKER.md` + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` — no edit (verbs already named).

**Evidence-based reasoning — why this is BETTER, not just safer.**
- OT's PA-013 worked example: 7 dependency cycles in Phase C surfaced at Phase D stage; 60 of 196 features unlayerable until cycles resolved; recovery required 3 rounds of cleanup. Without the script that detected cycles, OT might have shipped a Phase C with cycles to Phase E, compounding rework.
- The pack's phase dependency graph is the analog of OT's Phase C `dependencies` field. Phases have `Blockers:` / `Unblocks:` cross-references per existing per-stream contract. Cycle introduction at this level is not theoretical — it's a known failure mode.
- Capability #13 already commits to per-stream-contract validation; cycle detection is the natural extension. The cost is one check function + one negative fixture; the benefit is catching a known-bad state at validate-pack time rather than at downstream consumer time.
- Detection runs at the phase-dependency graph layer (uses existing Blockers/Unblocks data); does not require new schema or new contract surface. Pure derivation.

**Recommended adoption.** YES, with the caveat that the architect may discover the cycle-detection check already exists elsewhere in validate-pack (the phase per-stream contract may already have cycle detection). If so, the SC13.X just makes the existing check apply to the grouping membership context explicitly. If not, this is a new check; cost is small.

### §5.2 — AMENDMENT CANDIDATE 2: Architectural-seam Kind value (per §3.7)

**Proposed change.** Capability #4 default Kind set adds a 10th value: `architectural-seam` distinct from `architectural-pattern`. Reasoning: a seam is a forward-compatibility commitment (MVP work that admits post-MVP additively); a pattern is a design discipline (Repository, Factory, etc.) — same Kind today, different semantic content.

**Affected REQUIREMENTS-GROUPINGS-V11.md sections.**
- Capability #4 (Kind enumeration): default Kind set expands from 9 to 10 values.
- Capability #6 (Recognition characteristics): table adds row for `architectural-seam` with recognition signals (titles reference "seam", "forward-compatibility", "extensibility"; descriptions reference post-MVP feature dependencies on MVP work).

**Blast radius.**
- HANDOFF-V11.1-ARCHITECT.md §"Locked" — adjusts "9-Kind extensible enum" to "10-Kind extensible enum."
- BD-187 (canonical entry-type instruction doc, currently parked) — adds the new Kind when BD-187 lands.
- `project-template/docs/project/groupings/_rules.md` default content (downstream coder surface) — adds the new Kind value.
- Validate-pack — no new check; existing Kind-enum validation accepts the additional value.
- METHODOLOGY.md — no edit (PM-Chat prompt variants per Capability #12 reference Kind values generically).

**Evidence-based reasoning — why this is BETTER, not just safer.**
- OT's seam discipline is the load-bearing reason its Phase 2 / Phase 3 features can land additively (per `PHASE-A-vision-and-anti-goals.md` §6 NFR + §3.7 above). Seams are a distinct concept from patterns.
- Without a distinct Kind, projects that adopt the seam discipline (which OT validates as effective) have to classify seams under `architectural-pattern` and lose the semantic signal in cross-grouping queries (e.g., "list all groupings of Kind=architectural-seam" produces a different cohort than "list all groupings of Kind=architectural-pattern").
- The Kind enum IS extensible per Capability #4 — so projects can add this themselves. **Counter-argument:** that's a pack-shippable default. The pack ships 9 today; shipping 10 is a one-line change with no infrastructure cost; client projects gain the value without having to discover and replicate it. The marginal cost of shipping is near zero; the marginal value is non-zero.

**Recommended adoption.** YES if architect agrees seams are a distinct enough class to warrant separation. If architect concludes "patterns covers it; projects extend if needed," the no-change verdict is also defensible. The user-direction "scope must be intentional with logical reasoning" supports the YES verdict here: small change, clear semantic gain.

### §5.3 — AMENDMENT CANDIDATE 3: Anti-pillar / conditional-inclusion field in PRD reference (per §3.2)

**Proposed change.** Capability #1 (Grouping primitive core shape) keeps its current 5-required + 1-optional field set; NO grouping-doc field change. But Capability #7 (External ingest) SC7.7 ("PRD/journeys cross-references are recorded as optional free-text") gains a note: "When the PRD field references a PS-produced PRD doc, the PS PRD template is expected to contain anti-pillars + conditional-inclusion sections; PM-Chat external-ingest workflow should surface these during translation."

**Affected REQUIREMENTS-GROUPINGS-V11.md sections.** Capability #7 SC7.7 (minor wording addition); cross-reference to forthcoming PS work.

**Blast radius.** Minimal — this is a forward-reference note, not a structural change. BD-191 (PS) work will define the PRD template; this just hooks the groupings doc to consume it correctly.

**Evidence-based reasoning — why this is BETTER, not just safer.**
- OT's anti-pillars + conditional-inclusion-with-triggers pattern is high-value (§3.2). PS will produce these structures. Groupings ingesting PS PRD content should surface them rather than ignore them.
- The change is documentation-only; no schema impact.

**Recommended adoption.** YES — this is a tiny note that prevents the PS-groupings handoff from losing high-value content. Architect / PS architect should coordinate.

### §5.4 — AMENDMENT CANDIDATE 4 (REJECTED on evaluation): Add `mvp_priority` field to grouping doc

**Considered change.** OT's Phase C features carry `mvp_priority: foundation | core | polish | null`. Should groupings have an analog field?

**Evaluation.**
- Groupings already classify via Kind (Capability #4) — Kind is grouping-level identity per SC3.5 ("Kind is grouping-level identity; not derived from member-phase characteristics").
- `mvp_priority` is feature-level in OT (not cluster-level — M-clusters don't have mvp_priority). The analog at OT is the per-feature mvp_priority field, not the per-cluster field. The pack's analog is at the phase level (existing).
- Adding `mvp_priority` to GRP-NNN would conflict with SC2.5 ("Groupings have NO declared dependencies. Inter-grouping execution order is derived from phase Blockers/Unblocks").
- Member phases carry their own implicit ordering via Blockers/Unblocks; pulling a derived priority up to the grouping doc would be redundant.

**Verdict.** REJECTED. The pack's current design (groupings have no execution priority; derive from member phases) is correct AND consistent with OT's actual structure (M-clusters don't have mvp_priority either; F-NNN features do). The pack design here matches OT.

### §5.5 — AMENDMENT CANDIDATE 5 (REJECTED on evaluation): Add architectural-seams cross-reference field

**Considered change.** Should GRP-NNN have a `seam_refs:` field listing related seams (per OT Phase C pattern)?

**Evaluation.**
- OT's `seam_refs` is at the FEATURE level (F-NNN entries), not the cluster level. The pack analog is phase-level, not grouping-level.
- Groupings of Kind=architectural-seam (if §5.2 adopted) are seams themselves; cross-referencing other seams from a seam grouping doc creates a graph with no clear semantics.
- Free-text PRD field (Capability #1 SC1.2) already supports prose mention of related seams.

**Verdict.** REJECTED. No structural field needed; free-text prose covers it.

### §5.6 — AMENDMENT CANDIDATE 6: Empty-state architect-pass scope expansion (per §4.6 + cross-stream observation)

**Proposed change.** Capability #17 SC17.10 (Architect-pass-level parity verification) is already strong — "verify that empty-state handling is consistent across all per-entry streams; where parity gaps surface, open as SEPARATE BDs outside BD-186 scope." Recommended ENHANCEMENT: explicit cross-stream parity matrix as architect deliverable.

**Affected REQUIREMENTS-GROUPINGS-V11.md sections.** Capability #17 SC17.10 (refinement, not new SC).

**Blast radius.** Architect deliverable scope adjusted; no new fixture / no new validate-pack check (those land per the separate BDs SC17.10 already authorizes).

**Evidence-based reasoning — why this is BETTER.**
- OT's PA-016 (`PLANNING-PENDING-AMENDMENTS.md`) worked example: 3 "potentially questionable orphans" (F-122 / F-127 / F-145) surfaced at Phase D from inadequate cross-graph analysis at Phase C. Resolution required walking each feature against the inventory to determine actual consumer status. Pack-side analog: empty-state handling per stream may be inconsistent in ways that surface only at cross-stream comparison.
- The current SC17.10 lets the architect open separate BDs; the enhancement is asking the architect to PRODUCE the comparison matrix EXPLICITLY (rather than treating it as scratch work). The matrix is a small artifact (~20 cells: 4 streams × 5 empty-state aspects); shipping it as a deliverable creates audit-trail for the cross-stream design decisions.

**Recommended adoption.** YES — small refinement of architect-pass deliverable scope, no structural change to groupings design.

### §5.7 — Cross-feature integration concern: PS PRD field naming alignment

**Observation, not amendment.** Capability #1 SC1.2 names the optional field "Source PRD / journeys doc reference." When PS lands, it will produce PRDs at a specific location (per §4.1 alternative: `project-template/docs/project/<name>/`). The current free-text field accepts any reference, so no schema change is needed. Architect should note: if PS-produced PRDs become the dominant case, a more typed reference (`source_prd: <path-to-PS-doc>`) MAY become valuable, but that's v11.x or v12 work, not v11.1.

**No amendment recommended.** Just architect-awareness.

### §5.8 — Summary table: amendment dispositions

| # | Amendment | Scope | Disposition | Affected SC / new SC |
|---|---|---|---|---|
| 5.1 | Inter-grouping cycle detection | Small (1 check + 1 fixture) | **RECOMMENDED** | Capability #13 new SC13.X |
| 5.2 | `architectural-seam` Kind value | Minimal (1 line) | **RECOMMENDED** (low cost / clear value) | Capability #4 default Kind set 9→10 |
| 5.3 | PRD-field consumes PS anti-pillars | Documentation only | **RECOMMENDED** | Capability #7 SC7.7 wording note |
| 5.4 | `mvp_priority` field on groupings | n/a | **REJECTED** (redundant w/ SC2.5; not OT pattern at cluster level) | none |
| 5.5 | `seam_refs` field on groupings | n/a | **REJECTED** (free-text PRD covers it) | none |
| 5.6 | Empty-state cross-stream matrix as deliverable | Refinement | **RECOMMENDED** | Capability #17 SC17.10 refinement |
| 5.7 | Typed `source_prd:` field | (future) | **DEFERRED v11.x/v12** (just a forward observation) | none today |

**Total recommended amendments:** 4 (5.1, 5.2, 5.3, 5.6).  
**Total rejected after evidence-based evaluation:** 2 (5.4, 5.5).  
**Total deferred-future-observation:** 1 (5.7).  

All recommended amendments are SMALL — none requires reopening the BD-186 design decisions; all are additive or refinements. Pack Chat should surface these to user for triage before passing to the v11.1+ architect.


## §6 — Recommendations for BD-191 (PS feature requirements gathering)

Specific proposals to amend the 17-item candidate capability list in `INTAKE-PS-V11.md §8`, informed by the OT lessons in §3 + §4. Each proposal cites the OT pattern + evidence + the specific INTAKE-PS-V11.md §8 capability affected.

### §6.1 — Capability additions (recommended 3 new capabilities)

**New Capability #N1: PS deliverable per-stream tree structure.** Drawn from §4.1 alternative. PS deliverables live in `project-template/docs/project/<name>/` (architect picks `<name>`) following the pack's per-stream tree contract: `_rules.md` + `_intro.md` + `_toc.md` + per-deliverable files. NOT ad-hoc directory layout. SC: deliverables follow per-stream contract; validate-pack covers (extends existing per-stream checks Check 33/34); regen of `_toc.md` mechanical; trinity-rule trees (no parallel impact since PS docs are project-side, not pack-side).

**Status: REVISED 2026-05-24 per walkthrough decision (Sub-A revised to "architect-decides structure").** The original recommendation here (adopt per-stream-tree pattern for PS deliverables) was REVISED during the BD-191 capability walkthrough — see `INTAKE-PS-V11.md` §8 Walkthrough results Cap N1 row + pack memory `feedback_pattern_matching_out_of_context_antipattern`. Architect decides PS deliverable directory structure based on PS-specific properties + stated goals + technical constraints; per-stream-tree pattern is one candidate among others. Do NOT adopt per-stream-tree without property-fit verification. See REQUIREMENTS-PS-V11.md Cap N1 for the locked preliminary framing.

**New Capability #N2: PS deliverable mechanical audit pass.** Drawn from §3.8 + §4.4 + §4.6. Each PS deliverable has a defined audit-check spec. PRD audit: anti-pillars present; conditional-inclusion present; outcomes-over-outputs vocab check; Goals + Non-Goals paired. User-journey audit: mode-classified per OT Phase B.1 pattern; success-criteria stated; anti-goal stated. Feature-list audit: every feature has problem + goals + success_criteria; no-solutions-discipline grep pass with OT-seeded violation patterns; cycle detection on `depends_on` graph (per §4.2). Mapping-doc audit: every PS feature maps to at least one pack primitive. Audit is mechanical where possible (sub-agent or skill); user-judgment-required items are flagged.

**New Capability #N3: PS PRD template anti-pillars + conditional-inclusion sections.** Drawn from §3.2. The PRD template ships with explicit Pillars / Anti-pillars / Conditional-inclusions structural sections (not just Goals + Non-Goals). Conditional-inclusions require explicit triggers (no "we'll see" entries). Audit per Capability #N2 verifies presence.

### §6.2 — Capability merges / splits (recommended 2 restructurings)

**Merge: INTAKE-PS-V11.md §8 #8 (PRD authoring) + #9 (User journey doc generation) + #10 (Feature list + mapping doc generation) restructured into the OT-pattern Two-doc split (§3.3).**

Restructured shape:
- **Capability #N4: Narrative PRD authoring.** One narrative artifact synthesizing vision, audience, pillars, anti-pillars, conditional-inclusions, MVP scope, post-MVP scope, architectural seams (per §3.7). Audience: humans (engineers, investors, re-review). Opinionated about WHAT and WHEN; silent about HOW. Mirrors OT Phase E.1.
- **Capability #N5: Structured user-journey docs.** One per major user journey. Mode-classified per OT Phase B.1 pattern (Building / Discovery / Recovery / Setup). Each carries user goal + trigger + frequency + stage + success criteria + anti-goal. Phase 2/3 journeys carry seam references. Mirrors OT Phase B.1 / B.2.
- **Capability #N6: Structured feature inventory + mapping.** Machine-parseable structured artifact analogous to OT Phase E.2: each feature row carries `feature_id` + cluster + problem + goals + success_criteria + dependencies + cross-references to journeys / seams / pack primitives. The mapping doc IS the feature inventory + the per-feature pack-primitive cross-reference. Mirrors OT Phase C + Phase E.2 collapsed into one structured artifact (since PS doesn't need the planning-vs-implementation split OT used).

**Split:** INTAKE-PS-V11.md §8 #11 (Research orchestration) is currently single. OT's pattern (research is invoked at multiple phases — initial Phase A research feeding vision; per-feature `external_research_needed` at Phase C; per-architect-question deferred research at Phase A §7) suggests research orchestration has multiple invocation surfaces. Recommend splitting #11 into: **Capability #N7a: Initial product-discovery research** (competitive analysis + market evidence; feeds PRD vision and anti-pillars); **Capability #N7b: Per-feature research orchestration** (feature-level `external_research_needed` cases surfaced during PRD authoring; spawn `docs-researcher` per case).

**Status: REVISED 2026-05-24 per walkthrough decision (Sub-E E3 — "don't prescribe").** The original recommendation here (split #11 into N7a + N7b) was REJECTED at the walkthrough as a prescriptive split — see `INTAKE-PS-V11.md` §8 Walkthrough results Cap #11 row. Architect at PS design time decides research orchestration shape (split / single with sub-decomposition / skill-form / other). The walkthrough explicit don't-prescribe gives architect maximum design freedom; this §6.2 recommendation is INFORMATIVE only. See REQUIREMENTS-PS-V11.md Cap #11 for the locked preliminary framing.

### §6.3 — Capability additions, drops, and recluster

**Drop: None.** All 17 capabilities in INTAKE-PS-V11.md §8 are well-grounded.

**Reclustering proposal.** Current INTAKE-PS-V11.md §8 clusters: Foundation / Interview process / Deliverable outputs / Pack integration / Workflow + lifecycle / Scope boundary. With proposed additions and restructuring, the cluster set is:

| Cluster | Capabilities (renumbered) | Note |
|---|---|---|
| Foundation | #1 (core shape), #2 (two modes), #3 (invocation model), #N1 (per-stream tree) | +1 (per-stream tree) |
| Interview process | #4 (structured interview), #5 (methodology position), #6 (complete criteria with anti-pillar bar), #7 (quality-mitigation), #N3 (PRD template anti-pillars) | +1 (PRD template) |
| Deliverable outputs | #N4 (narrative PRD), #N5 (journey docs), #N6 (feature inventory + mapping), #N7a (initial research), #N7b (per-feature research), #N2 (audit pass) | restructured from 4 into 6 |
| Pack integration | #12 (audience-aware), #13 (groupings integration), #14 (traceability) | unchanged |
| Workflow + lifecycle | #15 (workflow + doc integration), #16 (PRD lifecycle) | unchanged |
| Scope boundary | #17 (Wave 3 vapor exclusion) | unchanged |

**Final count after amendments:** 21 capabilities (up from 17) — but the increase reflects the OT-pattern restructuring (one PRD capability becomes three: narrative + journey + structured) rather than scope creep. The actual deliverable count stays similar (was 4 deliverable types, becomes 4 deliverable types: PRD + journeys + feature inventory + mapping). The capability count increase is decomposition-clarity, not scope growth.

*Post-walkthrough composition note: the architect's pre-walkthrough estimate ("21 = +N7a/N7b split + N1/N2/N3 added") differs from the walkthrough-approved composition. The walkthrough did NOT split #11 (Sub-E E3 "don't prescribe") and DID add Cap N8 (human-readable PRD rendering generator per Goal 19) during Cluster 6. Final count is still 21 by coincidence: walkthrough preserved 1 capability where the architect proposed split (saves 1) and added 1 new capability (Cap N8). See `INTAKE-PS-V11.md` §8 Walkthrough results cluster summary for the post-walkthrough composition.*

### §6.4 — INTAKE-PS-V11.md §7 (quality-mitigation intuition) — direct addressing

The user's §7 intuition has two halves: (a) interview structure with clear sections per category vs. random walk; (b) audience-aware deliverables knowing the pack as audience. OT lessons confirm both:

- **§7.1 (interview structure):** Validated by OT's Phase A v3 structure — pillars / anti-pillars / audience / MVP-scope / conditional-inclusion / NFRs / deferred questions are 7 specific structural sections, not free-form. The PS interview should adopt this section structure plus the anti-pillar elicitation per §3.2.
- **§7.2 (audience-aware deliverables):** Validated by OT's E.1 (narrative for humans) vs. E.2 (structured for PM-chat) split per §3.3. PS knowing the pack as audience means producing artifacts the pack can ingest with minimal translation — exactly what OT's E.2 does for OT's PM chat. Capability #N6 (structured feature inventory + mapping) is the pack-equivalent of OT's E.2.

**Recommended Capability #6 (Interview "complete" criteria) amendment:** Add explicit completion criteria seeded from OT's Phase A v3 §1-§7 structure. The interview is "complete" when:
- Vision and pillars elicited (analog: Phase A §1-§2)
- Anti-pillars elicited with reasoning (analog: Phase A §3)
- Audience staged with explicit out-of-scope (analog: Phase A §4)
- MVP-scope clusters identified at the M-level (analog: Phase A §5)
- NFRs elicited (analog: Phase A §6)
- Architectural seams MVP commits to identified (analog: Phase A §7 deferred questions, but ANSWERED rather than deferred where possible)
- Conditional-inclusion items captured with triggers (analog: Phase A §5 table)

The above is a 7-item completeness bar. Capability #6 architect can refine; this is OT-evidence-based starting set.

**Status: EXTENDED 2026-05-24 per walkthrough decision (Sub-F approved; priorities Item 8 added).** The walkthrough extended this 7-item completeness bar to an 8-item bar by adding **Item 8 — Priorities elicited (multi-axis per Goal 17: product/market fit; competitive necessity vs advantage; technical constraints; resource constraints; scope decisions; cost/speed/quality/features/journeys; user-named axes)**. See `INTAKE-PS-V11.md` §8 Walkthrough results Cap #6 row + `REQUIREMENTS-PS-V11.md` §7 for the locked 8-item bar. Architect may modify the 8-item bar but must defend changes with evidence and logic.

---

## §7 — Recommendations for downstream PS architect

When the PS architect picks up REQUIREMENTS-PS-V11.md (forthcoming downstream of BD-191), they should investigate the following based on OT evidence.

### §7.1 — Interview structure design

The PS interview structure (Capability #4 in current INTAKE-PS-V11.md numbering) should investigate:
- **OT Phase A v3 §1-§7 as a structural template.** Read `PHASE-A-vision-and-anti-goals.md` end to end as a worked example of interview output. The interview's job is to produce a similar-shaped artifact.
- **Anti-pillar elicitation technique.** How does an interview get a user to articulate what they DON'T want? OT's pattern shows this is hard — Phase A v2 had a "Never" list; v3 reframed as conditional-inclusion-with-triggers because Never was brittle. The interview question pattern matters.
- **Audience-stage elicitation.** OT's Phase A v3 §4 lists 3 stages + explicit out-of-scope. Per `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §9.5, the "persona vs. JTBD" question is a methodology choice; OT effectively uses persona (Stage 1/2/3 are personas). The PS interview should explicitly choose its position here, not paper over it.
- **Seam elicitation (§3.7 + §6.1).** How does the interview surface architectural seams? OT's pattern: seams are documented in Phase B.2 (post-MVP journeys force the seam question). The PS interview may need a "Phase B.2 equivalent" elicitation stage AFTER MVP scope is locked.

### §7.2 — Deliverable template design

The PS deliverable templates should investigate:
- **OT Phase A v3 (vision) as PRD §1-§3 template.** Vision statement (1 sentence) + Three Pillars (each ~1 paragraph) + Three Anti-pillars (each ~1 paragraph) + Audience Staging + MVP cluster decomposition.
- **OT Phase B.1 v3 (journeys) as journey template.** Mode classification + per-journey header (goal / mode / trigger / frequency / stage / success / anti-goal) + numbered steps + `[F-NEW]` feature-touchpoint markers.
- **OT Phase C (feature inventory) as structured-feature-list template.** 17-field YAML schema. Note: 17 fields is OT-specific; the pack's structured-feature template may use a subset (10-12 fields suffice — see §7.4 below).
- **OT Phase E.1 (PRD) as narrative-synthesis template.** Section ordering (vision → audience → product surfaces → requirements → NFRs → out-of-scope → roadmap). Opinionated about WHAT and WHEN; silent about HOW.
- **OT Phase E.2 (work-items) MOSTLY NOT directly applicable to PS.** OT's E.2 produces 1,326 work items because OT is producing an OT-internal backlog. PS's analog is the structured feature list / mapping doc — not a full work-item backlog. The pack ingests the PS mapping into pack-side BD-NNN / phase-N / GRP-NNN; the pack DOES NOT need PS to produce 1,000+ work items per project.

### §7.3 — Methodology positioning

Per `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §9.5, the PS architect should investigate methodology positions:
- **Discovery framework:** OT's pattern is implicitly Continuous Discovery / Opportunity-Solution Tree (the structure of Phase A § + journeys + seams). The PS default should align with §9.5's recommendation (Continuous Discovery / OST).
- **Interview style:** OT's pattern is structured-by-section (§3.6 satellite docs are structured-interview-equivalents). Mom Test style + past-behavior focus from §9.5 is consistent.
- **PRD shape:** OT validates the §9.3 common-denominator 8 sections. PRD template should adopt.
- **Persona vs JTBD:** OT uses persona (Stage 1/2/3). §9.5 says JTBD-Christensen is the trend. Architect should make explicit choice; default JTBD per §9.5 is defensible; OT's persona is also defensible. Per pack memory `feedback_no_solutions_in_agent_prompts`, the architect picks.

### §7.4 — Per-feature schema design

OT's Phase C uses 17 fields per feature. Pack PS should investigate which fields generalize:
- **Essential (generalize):** `feature_id`, `name`, `description`, `problem`, `goals`, `success_criteria`. These are the no-solutions-discipline-bound contract fields per §3.1.
- **Likely essential:** `dependencies`, `status` (MVP/post-MVP), `cluster` (or grouping reference).
- **Domain-specific (may not generalize):** `mvp_priority` (foundation/core/polish — OT-specific layering), `journey_consumers`, `seam_refs`, `shared_with`, `external_research_needed`, `existing_code`, `architect_notes`, `design_notes`. These are useful but PS-domain-variable.

Recommend a **core schema** (essential fields) + **extension fields** (per-project `_rules.md` declares which extension fields apply). Matches groupings Capability #4 extensible-Kind pattern.

### §7.5 — Two-pass architect protocol

OT had multiple cleanup rounds for Phase C (Round 1 + Round 2 + Round 3 per PA-013/014/016). The PS architect should anticipate the same: ARCHITECT produces v1 → PLANNER produces v1 → audit (mechanical + reviewer) → architect produces v2 with fixes → planner v2 → ship. The pack's existing per-BD review/fix cycle handles this; PS architect should not assume one-shot success.

---

## §8 — Challenge questions for downstream architects

Open questions the OT lessons surface. The v11.1+ groupings architect should investigate the first cluster; the v11.x+ PS architect should investigate the second cluster.

### §8.1 — For the v11.1+ groupings architect

1. **Phase-level dependency cycle detection — does it already exist in validate-pack?** Capability #13 SC13.X (§5.1) assumes the check is new. Verify: does validate-pack already detect cycles in phase Blockers/Unblocks? If yes, SC13.X scopes to applying the existing check to the grouping membership context. If no, this is a net-new check with one new function in `scripts/validate-pack.py`.
2. **Is the `architectural-seam` Kind value distinct enough to warrant separation from `architectural-pattern`?** §5.2 recommends YES based on OT evidence. Architect should evaluate independently. If conclusion is "patterns covers it," no change.
3. **For Capability #17 cross-stream parity matrix — what's the right axis structure?** Streams (backlog / implementation-plan / changelog / groupings) × empty-state aspects (validate-pack pass / TOC generator / verb behavior / tracker projection / mirror behavior). The matrix is ~20 cells; produces an audit-trail. Architect chooses the dimensions.
4. **Should grouping audit pass include OT's PA-001/002/003 grep-pass for solution leakage in the Description field?** Capability #1 SC1.2 has free-text Description; solution leakage is possible. §3.1 + §4.4 evidence argues for a small mechanical grep at Capability #13 audit time. Architect decides.
5. **How does PS-produced grouping-equivalent content (M-cluster analogs) ingest into the pack's GRP-NNN tree?** Capability #7 from-external workflow handles this generically. But PS's mapping doc per §6.2 #N6 will likely have grouping suggestions inline — does that feed Capability #7 directly or through a new path? Architect investigates when PS lands; not v11.1 work.

### §8.2 — For the v11.x+ PS architect

1. **How many specialized PS skills vs one general PS agent (the user's Q8 question)?** OT's pattern (1 master + 5 satellites; §3.6) argues for split-by-stage. The pack's existing skill-file pattern supports this. Architect investigates the right split: by deliverable (PRD-skill / journeys-skill / feature-list-skill / mapping-skill) vs. by stage (interview-skill / research-skill / audit-skill) vs. hybrid.
2. **For Capability #N6 (structured feature inventory + mapping), what schema does the feature row carry?** Start with the core schema in §7.4. Architect refines based on PS-domain consideration. The schema must be small enough to be agent-promptable (each row standalone) but rich enough to feed pack primitives.
3. **What's the no-solutions-discipline grep regex set seeded for PS PRD audit?** §4.4 recommends seeding from OT's PA-001/002/003. Architect designs the seed set + per-project extensibility mechanism.
4. **Should PS produce work-item-level decomposition (OT Phase E.2 analog)?** §7.2 recommendation is NO — the pack ingests PS at feature-level into BD-NNN / phase-N / GRP-NNN. Architect verifies the boundary: PS stops at feature-level; pack-side groupings + backlog + implementation-plan take over.
5. **What's the PS-to-groupings handoff protocol concretely?** §5.3 amendment + Capability #13 (PS) groupings integration. PS's structured feature inventory feeds the groupings from-external workflow (Capability #7) — but at what granularity? Does PS produce candidate `GRP-NNN.md` content that PM-Chat reviews + writes? Or does PS produce a structured-list-of-candidate-groupings that PM-Chat translates? Architect picks the protocol shape.
6. **For Capability #N2 (deliverable audit pass), is the audit run by sub-agent or by skill?** OT's pattern is script-based audit (Phase C audit + Phase D audit script). Pack equivalent could be sub-agent or skill or validate-pack extension. Architect picks; this affects PS feature implementation scope.
7. **What's the "interview complete" detection mechanism?** §6.4 lists 7 OT-evidence-based items. But "complete" detection requires user-confirmation or mechanical check or both. Architect designs.

---

## §9 — Agent-selection rationale (informative)

This review pass was commissioned to pack-architect. The user asked for the rationale to inform future similar work.

### §9.1 — Why pack-architect was the right agent

The task carried characteristics that map to architect:
- **Cross-feature design analysis.** The work spans BD-186 (groupings, locked), BD-189 (groupings impl), BD-191 (PS, in-flight). Cross-feature blast-radius analysis IS architect work per `pack-ops/PACK-AGENTS.md` agent role definitions.
- **Recommending design amendments with evidence.** §5 amendments carry blast-radius + reasoning + evidence — this is architect-pass deliverable shape (analogous to ARCHITECTURE-*.md docs).
- **Producing guidance for downstream architects.** §7 and §8 are explicit hand-offs to the v11.1+ and v11.x+ architects. This is architect-to-architect handoff.
- **Boundary discipline application (P-missed-7).** OT is project-side reference; pack-side rules govern pack-side proposals. Architect-pass discipline includes SSOT investigation per `boundary-investigation` skill.
- **No-solutions discipline familiarity.** §3.1 recognizes G1; pack-architect operates under the same no-solutions discipline by mandate.

### §9.2 — Alternatives considered

**pack-docs-researcher.** Considered. Strengths: would have produced authoritative descriptive content about OT's process patterns. Weaknesses: would NOT have produced design recommendations or blast-radius analysis; researcher outputs are descriptive, not prescriptive. The user explicitly asked for "propose specific scope changes... informed by evidence" — that's not researcher output. **Verdict:** wrong fit for the deliverable.

**pack-reviewer.** Considered. Strengths: review-discipline includes evidence-based finding articulation (BLOCKER / MUST / SHOULD / NIT). Weaknesses: reviewer reviews artifacts that already exist (per pack memory). OT's planning is locked / read-only; pack groupings is requirements-locked. There's no in-flight artifact to review here — there's a cross-repo synthesis pass producing new guidance. **Verdict:** wrong fit (no artifact-under-review).

**pack-planner.** Considered. Strengths: planner produces ordered execution sequences. Weaknesses: the deliverable is not an ordered execution plan; it's a cross-feature analysis with conditional recommendations. **Verdict:** wrong fit.

**pack-coder.** Considered. Strengths: coder produces working-tree edits. Weaknesses: no implementation surface affected by this review — just two output docs. **Verdict:** wrong fit (could mechanically write the docs but couldn't do the architecture analysis).

**Pack Chat direct.** Considered. Per pack memory `feedback_pack_chat_does_not_architect` Pack Chat does not architect. **Verdict:** rule violation.

### §9.3 — Pros / cons of the architect-choice for this specific task

**Pros (worked well):**
- Cross-stream + cross-repo synthesis fits architect mental model
- Blast-radius + evidence-based reasoning is architect-natural
- Boundary-investigation skill loaded by all pack agents per `P-missed-7` applied automatically
- No-solutions discipline awareness shaped the §3.1 recommendation framing
- Skills loaded (architecture-review, planning, documentation, commit-discipline) all applied

**Cons / friction:**
- OT directory is large (~4.5MB; PHASE-C alone is 774KB; PHASE-E2 is 3.0MB). Skim discipline required. The task brief said SKIM Phase C / Phase E.2 — that was the right call; full read would have consumed disproportionate context without proportionate insight gain.
- Cross-repo work (OT read-only) requires explicit boundary verification at each step. The `git status` discipline + verifying only output paths are modified matters.
- Producing recommendations involves judgment calls (e.g., §5.2 "is architectural-seam distinct enough" is genuinely a judgment call; another architect might reasonably conclude differently). Where this occurred, I framed it as "architect may decide otherwise" rather than as a single-answer-prescription. This is consistent with the no-solutions-discipline-of-the-rule-itself.

### §9.4 — Recommendation for future similar work

For cross-feature cross-repo synthesis passes producing design recommendations: **pack-architect is the right agent.** Caveats: (1) confirm the user wants design recommendations (vs. descriptive synthesis — that's docs-researcher); (2) confirm the user wants blast-radius analysis (vs. just adoption-or-not — that's lighter, architect still fits); (3) confirm no in-flight artifact under review (if there is, reviewer + architect tandem may fit).

---

## §10 — Sources + dates

### OT planning artifacts consulted (READ-ONLY)

All paths under `/Users/david/Developer/<target-project>/docs/reference/planning/feature-brainstorm-1/`.

- `README.md` — full read; orientation + identifier reference table.
- `PHASE-A-vision-and-anti-goals.md` — full read; pillars + anti-pillars + audience + clusters + conditional-inclusion + NFRs + deferred questions.
- `PHASE-B1-mvp-user-journeys.md` — first 100 lines (journey-classification scheme + first journey); skim of remainder for journey-shape pattern.
- `PHASE-B2-post-mvp-user-journeys.md` — not directly read; inferred via Phase A and Phase D cross-references.
- `PHASE-C-master-feature-inventory.md` — first 200 lines (header + schema + discipline + audit-pass + first feature F-001); 774KB total; SKIM only per task brief.
- `PHASE-C5-ai-roadmap.md` — first 120 lines (substrate decomposition + first 4 substrate elements); skim of remainder.
- `PHASE-D-capability-matrix-and-deps.md` — first 200 lines (anchored-on + capability matrix §1.1-§1.9 + dependency-graph §2.1-§2.3 sample).
- `PHASE-E1-OT-PRD-v1.md` — first 100 lines (vision + audience + use cases + product surfaces sample); 97KB total.
- `PHASE-E2-OT-FEATURE-BACKLOG-v1.md` — not directly read; inferred via satellite (PHASE-E2-CLI-INSTRUCTIONS.md); 3.0MB total; SKIM only per task brief.
- `process/PHASE-PLANNING-CLI-MASTER.md` — full read; global rules G1-G9 + execution order + per-phase entry points.
- `process/BACKLOG-PLANNING.md` — full read; TDP-NNN scheme + 2 resolved entries.
- `process/PLANNING-PENDING-AMENDMENTS.md` — full read; PA-NNN scheme + 15 entries (Resolved + Rejected + 1 Open PA-012).
- `process/PHASE-C-CLI-INSTRUCTIONS.md` — first 200 lines (Phase C scope + execution order + schema + discipline + Step 1-3 sample).
- `process/PHASE-D-CLI-INSTRUCTIONS.md` — first 150 lines (Phase D scope + document structure + discipline + sources + script).
- `process/PHASE-E2-CLI-INSTRUCTIONS.md` — first 150 lines (Phase E.2 scope + structure + work-item schema + generation procedure).
- `process/PHASE-C5-CLI-INSTRUCTIONS.md` — not directly read; inferred via Phase C.5 deliverable.
- `process/PHASE-E1-CLI-INSTRUCTIONS.md` — not directly read; inferred via Phase E.1 deliverable.

**SKIPPED per task brief.**
- `external-feedback/` (ChatGPT + Gemini research inputs).
- `generated/` (script outputs).

### Pack-side artifacts consulted

All paths under `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/`.

- `CLAUDE.md` § "Pack memory" — full read; pack-rules + workflow + sub-agent + scope discipline.
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` — full read (909 lines); Capabilities #1-#17 + design principles + constraints C1-C7.
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` — full read; v11.1+ groupings architect orientation.
- `maintenance-docs/v11-research/INTAKE-PS-V11.md` — full read; §1-§9 verbatim user framing + Q&A + naming decision + research approval + §7 quality-mitigation intuition + §8 candidate 17-capability list.
- `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` — first 200 lines (purpose + scope + §1 open-source + §2 professional products); skim of remainder via INTAKE-PS-V11.md §5 + §9 surfacing.
- `pack-ops/BACKLOG.md` BD-186 / BD-187 / BD-188 / BD-189 / BD-191 — confirmed line locations via grep.

### Dates

- Authoring date: 2026-05-24 (US/Pacific).
- All OT planning artifacts dated April 2026 per file mtimes; OT plan locked per README disposition.
- All pack-side artifacts current as of HEAD `3e15ea33`.

---

End of PLANNING-PROCESS-INSIGHTS-FROM-OT.md.
