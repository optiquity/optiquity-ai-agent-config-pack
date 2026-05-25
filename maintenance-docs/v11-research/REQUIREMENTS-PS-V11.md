# REQUIREMENTS-PS-V11.md

**Purpose:** Formal requirements distillation for the Product Specialist (PS) feature. Synthesizes user-intent (INTAKE), landscape research (RESEARCH), and architect-oriented OT-pattern synthesis (PLANNING-PROCESS-INSIGHTS) into a single artifact that the future v11.x+ PS architect reads first.

**Sponsoring BD:** BD-191 — Product Specialist (PS) requirements + v11.0/v11.1+ scope decision (see `pack-ops/BACKLOG.md`).

**Date authored:** 2026-05-24.

**Status:** PRELIMINARY across every disposition, scope verdict, capability shape, and open architect decision. This entire doc is signal to the architect — not a locked design. Architect WILL challenge each preliminary position based on detailed tactical information; user retains final authority. Tiered challenge bar per pack memory `feedback_preliminary_triage_architect_challenge`:
- **LOW** — PS-internal decisions; architect explores freely and may enhance, accept, reject, or replace.
- **HIGH** — Boundary-with-existing-pack decisions (locked pack mechanisms, entry-type semantics, cross-feature contracts with groupings BD-186 / BD-189); architect must investigate thoroughly and cannot arbitrarily change boundary out of scope.

**Companion docs (read alongside this one):**
- `maintenance-docs/v11-research/INTAKE-PS-V11.md` — user-intent audit trail; verbatim user framing + Q1-Q10 + naming decision + research approval + §7 quality-mitigation intuition + §7.5 interview flow dynamics + §8 capability list + §8 Walkthrough results + §9 19-goal index. Source-of-truth for user verbatim quotes.
- `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` — PS landscape research; 985 lines; 7 categories + cross-cat synthesis + §9 pack-relevance observations + §9.5 defensible methodology positions. Source-of-truth for landscape facts.
- `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` — pack-architect OT-pattern synthesis; §3 transferable patterns + §4 failure modes + §5 groupings amendments + §6 PS capability recommendations + §7 architect investigation areas + §8 challenge questions. Source-of-truth for OT-evidence-grounded recommendations.
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` — companion v11.1+ feature; PS docs feed groupings via existing #7 from-external ingest.
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` — groupings architect handoff; cross-feature context. A forthcoming `HANDOFF-PS-ARCHITECT.md` (per BD-191 File/Symbol) will be the v11.x+ PS architect's direct entry point.

**Companion-doc reading discipline:** This requirements doc DISTILLS; it does not duplicate. Where a section references a companion doc by section number, the reader should consult the companion for verbatim content. Distillation is one-way: this doc does not get retroactively re-synced when a companion is edited; the canonical source remains the companion.

---

## §1 — Purpose, audience, framing

### §1.1 — Purpose

This doc captures the formal requirements for the Product Specialist (PS) feature in one place. The capability set is preliminary; each capability has a problem, goals, success criteria, disposition, scope verdict, rationale, cross-references, and an architect-challenge bar. The doc enables the v11.x+ PS architect to start design work without reconstructing requirements from multiple upstream sources.

### §1.2 — Audience

**Primary audience:** The v11.x+ PS architect. They read this doc FIRST, then consult INTAKE / RESEARCH / PLANNING-PROCESS-INSIGHTS as deeper context. The architect produces a design doc (e.g., `ARCHITECTURE-PS-V11.x.md`) that decides the locked design.

**Downstream consumers:**
- **v11.x+ PS planner** — reads architect output + this requirements doc; produces implementation plan.
- **v11.x+ PS coder(s)** — read planner output; implement per planner sequencing.
- **v11.x+ PS reviewer(s)** — read this requirements doc + architect doc + planner doc to scope review.

**Indirect audience:** Pack Chat (for sidecar BD-191 triage close-out + downstream BD opens); user (for review + acceptance + final authority on architect challenges).

### §1.3 — Framing

**CLIENT-SIDE ONLY.** PS is a CLIENT-SIDE feature only. It affects `project-template/` surface and the developer's product work; it is NEVER applied to pack-self development workflow. The existing PM Chat (project manager) continues to orchestrate pack-self work. This is a locked user-stated boundary (INTAKE §1; BD-191 description "Critical scope boundary"; goal 1).

**Naming decision (LOCKED 2026-05-24):** "Product Specialist" (PS) over "Product Manager" (PM), Lead Product Manager (LPM), or full TPM rename. Avoids collision with existing PM Chat terminology; "Specialist" semantically fits episodic-expertise contribution better than "Manager." See INTAKE §3 for full naming-decision verbatim record.

**Preliminary status (doc-level disclaimer):** Every disposition, scope verdict, capability shape, success criterion, architect bar, and open architect decision in this doc is **Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`. Architect WILL challenge each preliminary position based on detailed tactical information. User retains final authority over architect challenges. Architect may enhance, accept, reject, or replace any preliminary position based on evidence and logic. Tiered challenge bar applies per capability (LOW for PS-internal; HIGH for boundary-with-existing-pack).

**Cross-references to upstream sources:**
- INTAKE-PS-V11.md (audit-trail; user-intent verbatim)
- RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md (landscape facts; quality bar)
- PLANNING-PROCESS-INSIGHTS-FROM-OT.md (OT-evidence-grounded recommendations)
- BD-191 entry in `pack-ops/BACKLOG.md` (SC1-SC13; pipeline; out-of-scope list)

---

## §2 — Design principles (consolidated reference index of 19 user-stated goals)

This section is a NAVIGATION INDEX into the 19 user-stated goals captured verbatim in `INTAKE-PS-V11.md §9`. Full statements are NOT duplicated here; the companion doc remains source-of-truth. Each row gives the goal title and source-location cell so a reader can navigate to the verbatim content.

**Audit-trail discipline:** This is a reference table only. If a goal statement disagrees between this table and INTAKE §9, INTAKE WINS. This index does not rewrite intent; it provides navigation.

| Goal # | Title | INTAKE source location |
|---|---|---|
| 1 | CLIENT-SIDE ONLY boundary (project work, never pack-self) | INTAKE §9.1 row 1; full source INTAKE §1 first paragraph + BD-191 description "Critical scope boundary" |
| 2 | Two equal first-class modes: from-scratch + existing-PRD-ingest-with-gap-fill | INTAKE §9.1 row 2; full source INTAKE §2 Q3 + Q7 + BD-191 SC7 |
| 3 | Structured interview, not random walk | INTAKE §9.1 row 3; full source INTAKE §7.1 + BD-191 SC10(a) |
| 4 | Elicit product success inputs (definition, scope, MVP shape, future versions, resource constraints, competitive position) | INTAKE §9.1 row 4; full source INTAKE §1 (a) + §2 Q2 + Q4 |
| 5 | Episodic-usage / light footprint (init + milestone spikes + on-demand) | INTAKE §9.1 row 5; full source INTAKE §1 (g) + §2 Q2 + BD-191 description "Position" + walkthrough refinement 2026-05-24 covers BOTH new-project AND existing-project-adopting-pack as project-init |
| 6 | Multiple deliverables with appropriate shapes (full PRD with MVP line; journeys; ambient/shared/foundational grouping inputs; mapping docs; working docs not exec summaries) | INTAKE §9.1 row 6; full source INTAKE §1 (c)(d)(e)(f) + §2 Q4 + §8 capabilities #8/#9/#10 |
| 7 | Audience-aware deliverables — pack IS the audience; differentiator vs open-ended PM tools | INTAKE §9.1 row 7; full source INTAKE §7.2 + §8 capability #12 + BD-191 SC10(b) + walkthrough reinforcement 2026-05-24 PACK-PRIMARY first / human-readable SECONDARY via Goal 19 / not either-or |
| 8 | Smooth pack integration without forced dependency (zero dependency of groupings on PS; PS never produces GRP-NNN.md; feeds groupings via #7 from-external ingest) | INTAKE §9.1 row 8; full source INTAKE §2 Q5 + Q6 + BD-191 description "Cross-feature relationship with groupings" + BD-191 SC6 |
| 9 | Research orchestration with quality discipline (wide net + high quality bar; full citations + logical reasoning + evidence; multi-stage invocation) | INTAKE §9.1 row 9; full source INTAKE §1 (b) + §3 research-scope paragraph + §8 capability #11 |
| 10 | Quality-mitigation tactical (not just strategic) principles; "complete" criteria for interview; counters "AI PRDs without facilitation = decorative artifacts" failure mode | INTAKE §9.1 row 10; full source INTAKE §7 (full section, extended by §7.5 interview flow dynamics 2026-05-24) + §8 capabilities #6/#7 + BD-191 SC10 |
| 11 | Defensible methodology positioning (Continuous Discovery + OST / Mom Test / Lean Canvas or PR-FAQ / RICE or Value-Effort / common-denominator PRD / North Star + OKRs / JTBD-Christensen / Cagan vocabulary); per-project override path; methodology-as-explicit-position itself a pack differentiator | INTAKE §9.1 row 11; full source RESEARCH §9.5 + INTAKE §5 research-output headlines + §8 capability #5 + BD-191 SC8 |
| 12 | PRD-to-code traceability — pack uniquely positioned (BD/phase/grouping/IMPL-REPORT primitives thread); features → BDs → commits / PRs; PS deliverables reference pack primitives by ID | INTAKE §9.1 row 12; full source RESEARCH §9.2 + INTAKE §8 capability #14 |
| 13 | Wave 2 only (content-gen in PM workflows); Wave 3 (autonomous agentic PM) vapor OUT of scope; pack adds value above "paste into Claude" baseline | INTAKE §9.1 row 13; full source RESEARCH §9.4 + INTAKE §8 capability #17 + BD-191 SC9 |
| 14 | Architecture: PM Chat does interview; agent does heads-down doc work; sub-agent split is architect-decided; pack pattern agents don't interview users | INTAKE §9.1 row 14; full source INTAKE §1 (bullets 1-3) + §2 Q8 + §8 capability #1 |
| 15 | Simple lifecycle: PRD edits in place; addenda / follow-on docs; tracked via existing pack primitives (phases for pre-scheduled; backlog for emergent); no new lifecycle states | INTAKE §9.1 row 15; full source INTAKE §2 Q9 + §8 capability #16 |
| 16 | Scope-discipline meta-criterion — added workflows/features must move toward better organization/processes/design/implementation, not just be additive | INTAKE §9.2 (full statement); cross-cutting across all SCs |
| 17 | Priorities as first-class cross-cutting driver — elicit, document, propagate, scope-test across all PS outputs; multi-axis (product/market fit; competitive necessity vs advantage; technical constraints; resource constraints; scope decisions; cost/speed/quality/features/journeys; user-named axes) | INTAKE §9.3 (full statement); BACKLOG-side BD-191 SC11 |
| 18 | PS-to-pack-entry-type boundary principle — PS produces context-rich, audience-aware inputs; pack ENTRY-TYPE workflows build canonical artifacts; PS DOES NOT create canonical pack entry-type artifacts directly | INTAKE §9.4 (full statement); BACKLOG-side BD-191 SC12 |
| 19 | Human-readable PRD rendering for user verification — pack-primary remains canonical; complementary generator produces human-targeted PRD doc optimized for visual verification | INTAKE §9.5 (full statement); BACKLOG-side BD-191 SC13; implementing capability Cap N8 |

**Cross-cutting principles** (not bound to a specific capability; apply to every triage decision and every architect design decision):
- Goal 1 (CLIENT-SIDE ONLY)
- Goal 5 (episodic / light footprint)
- Goal 7 (pack-as-audience; pack-primary canonical)
- Goal 13 (Wave 2 only; Wave 3 OUT)
- Goal 16 (scope-discipline meta-criterion)
- Goal 17 (priorities as first-class cross-cutting driver)
- Goal 18 (PS-to-pack-entry-type boundary)

**Methodology-position defensible defaults** (Goal 11; from RESEARCH §9.5):

| Area | Defensible default |
|---|---|
| Discovery framework | Continuous Discovery (Torres) / Opportunity-Solution Tree |
| Hypothesis articulation | Lean Canvas (one-page) OR PR/FAQ (narrative) |
| Prioritization | RICE or Value/Effort (default); Kano (delight) |
| Interview style | Mom Test + past-behavior focus |
| PRD shape | Common-denominator 8 sections (RESEARCH §4.8) |
| Outcomes | North Star + OKRs |
| Persona vs JTBD | Pick ONE; JTBD-Christensen is trend |
| Vocabulary | Cagan (problems-to-solve, outcomes-over-outputs) |

The methodology defaults are SHIPPED as defensible defaults with a per-project override path. Architect-decides exact override mechanism + escape valves.

---

## §3 — User-stated constraints

User-stated constraints surfaced during BD-191 sidecar discussion 2026-05-24. These are LOCKED constraints (not preliminary at this level — they are direction-from-user) that bound architect design freedom. Architect challenges to these constraints require user-discussion-and-approval per pack memory `feedback_user_prescriptive_authority`.

### §3.1 — C1: CLIENT-SIDE ONLY

PS affects `project-template/` surface only. PS NEVER applies to pack-self development workflow. The pack repo's own PM Chat continues to orchestrate pack-self development.

**Source:** INTAKE §1 first paragraph (verbatim user); BD-191 description "Critical scope boundary"; Goal 1.

**Implication for architect:** PS deliverables ship in `project-template/`; pack-side pack-self workflow stays untouched. No PS agent / skill / doc invocation paths reach into the pack-ops or pack-development surface.

### §3.2 — C2: Two equal first-class modes

PS supports BOTH modes equally and as first-class:
- **Mode 1 (from-scratch):** Interview + research + write deliverables from a blank-slate user starting point.
- **Mode 2 (existing-PRD ingest + gap-fill):** Read user-supplied PRD + identify pack-integration gaps + interview to fill + restructure to pack-compatible deliverable shapes.

**Source:** INTAKE §2 Q3 + Q7 (verbatim user); BD-191 SC7; Goal 2.

**Implication for architect:** Both modes use the SAME structured interview approach (per Goal 3). Mode-2's reading-existing-PRD step is the audit-of-existing-content; it surfaces gaps per the same structure that Mode 1 elicits via fresh interview.

### §3.3 — C3: Episodic / light footprint

PS is invoked episodically:
- Heavy at project init (big product-planning effort)
- Spikes at milestones (explicit: version releases; implicit: feature work nearing end of planned scope)
- On-demand
- No chronic between-spike overhead

Walkthrough refinement 2026-05-24: "project init" covers BOTH new-project AND existing-project-adopting-pack cases; light-footprint applies to both.

**Source:** INTAKE §1 (g) (verbatim user); §2 Q2; BD-191 description "Position"; Goal 5; INTAKE §8 walkthrough notes (Cap #3 row).

**Implication for architect:** PS installation ships availability not adoption. No background processes. No always-on agents. Invocation is user-driven (verb / chat directive) or milestone-triggered.

### §3.4 — C4: Smooth pack integration without forced dependency

ZERO HARD DEPENDENCY between PS and groupings (BD-186 / BD-189) in either direction:
- Groupings stand alone per BD-186; PS is an OPTIONAL upstream feeder
- PS produces PRDs / journey docs / mapping docs / feature inventories that feed groupings via the existing #7 from-external ingest workflow
- PS NEVER produces `GRP-NNN.md` files directly — that's groupings/coder scope

**Source:** INTAKE §2 Q5 + Q6 (verbatim user); BD-191 description "Cross-feature relationship with groupings"; BD-191 SC6; Goal 8.

**Implication for architect:** PS integration with groupings flows through groupings Capability #7 (from-external ingest). PS architect must not propose direct PS-writes-to-grouping-tree designs. PS-side cross-references to groupings IDs (`GRP-NNN`) are reference-only.

### §3.5 — C5: Methodology defaults shipped (defensible-defaults positioning)

PS ships defensible methodology defaults per RESEARCH §9.5 (Continuous Discovery + OST; Mom Test; Lean Canvas or PR/FAQ; RICE or Value/Effort; common-denominator PRD; North Star + OKRs; JTBD-Christensen; Cagan vocabulary). Per-project override path supported. Methodology-as-explicit-position is itself a pack differentiator per RESEARCH §9.2.

**Source:** INTAKE §5 research-output headlines; RESEARCH §9.5; INTAKE §8 capability #5; BD-191 SC8; Goal 11.

**Implication for architect:** Architect picks the override mechanism, but cannot ship methodology-neutral (Goal 11 + RESEARCH §9.2 underserved-gap-analysis). Architect must take a position.

### §3.6 — C6: Wave 3 vapor excluded

Wave 3 (autonomous agentic PM) is OUT OF SCOPE. PS is Wave 2 (content-gen in PM workflows). Pack adds value above "I'll just paste this into Claude" via project-context awareness + integration + methodology positioning.

**Source:** RESEARCH §9.4; INTAKE §8 capability #17; BD-191 SC9; Goal 13.

**Implication for architect:** No "PS agent autonomously runs the product roadmap"; no "PS agent automatically interviews users without a human in the loop"; no agentic-PM features that automate PM judgment. PS scaffolds + facilitates + audits + renders; PS does not replace the PM (or PS-user) role.

### §3.7 — C7: PS-to-pack-entry-type boundary

PS workflows produce context-rich, audience-aware INPUTS. Pack ENTRY-TYPE workflows (phases / groupings primarily; backlog only as track-without-schedule edge case) build canonical artifacts. PS does NOT create canonical pack entry-type artifacts directly. PS workflows are INFORMED BY each relevant pack entry-type's data-structure requirements.

**Pack data-structure context** (per pack memory `reference_pack_entry_type_semantics`):
- **Phases** — top-level scheduled implementation units; initial creation never produces phase parts (split into two phases if too big at creation).
- **Tasks** — components of phases; flat-file inline OR tracker work-items.
- **Groupings** — collections of phases (only); phase parts and tasks cannot be grouping members.
- **Phase parts** — evolution artifact; PS does NOT need to know about phase parts.

**Source:** INTAKE §9.4 (Goal 18 full statement); BD-191 SC12; Goal 18.

**Implication for architect:** HIGH architect bar applies — boundary touches locked pack entry-type architecture per `reference_pack_entry_type_semantics`; architect cannot arbitrarily change boundary out of scope; must investigate thoroughly. Groupings-side conversion responsibility lands in REQUIREMENTS-GROUPINGS-V11.md Capability #7 SC7.8 (already approved 2026-05-24).

---

## §4 — Capability list (21 preliminary capabilities)

**Source:** INTAKE §8 Walkthrough results table is the authoritative source for capability ID / name / disposition / scope verdict / walkthrough notes. Each entry below distills the walkthrough row into a structured capability spec.

**Cluster summary:**

| Cluster | Caps in cluster | Cluster count |
|---|---|---|
| Foundation | #1, #2, #3, N1 | 4 |
| Interview process | #4, #5, #6, #7, N3 | 5 |
| Deliverable outputs | N4, N5, N6, #11, N2, N8 | 6 |
| Pack integration | #12, #13, #14 | 3 |
| Workflow + lifecycle | #15, #16 | 2 |
| Scope boundary | #17 | 1 |
| **Total** | | **21** |

**Per-capability entry shape:**
- Capability ID + name
- Problem (gap / need addressed)
- Goals (what the capability achieves; cross-references relevant user-stated goals)
- Success Criteria (preliminary; numbered SCN.1 / SCN.2 / ...)
- Disposition (KEEP per all 21)
- Scope verdict (v11.x per all 21)
- Rationale (citing goals + INTAKE source + research)
- Cross-references
- Architect bar (LOW or HIGH)
- Preliminary disclaimer

### Cluster 1 — Foundation (4 capabilities)

#### Capability #1 — PS feature core shape + scope boundaries

**Problem:** PS shape (agent / skill / hybrid) is not pre-decided. User explicitly identified shape as architect-decided (Goal 14; INTAKE §2 Q8). The boundary principle "PM Chat does interviewing; agent does heads-down doc work" must be preserved while sub-agent topology stays open.

**Goals:**
- Preserve the boundary principle: PM Chat interviews; agent (or skill / hybrid) writes deliverables (Goal 14)
- Honor CLIENT-SIDE ONLY scope (Goal 1; §3.1 C1)
- Optional-but-highly-recommended posture (INTAKE §2 Q3; Goal 2 mode-2 path)
- Defer agent topology to architect (Goal 14; §3.4 C4 noting integration must work regardless of topology)

**Success Criteria:**
- SC1.1 Architect produces a locked decision on agent / skill / hybrid topology with rationale tied to the boundary principle.
- SC1.2 The locked topology preserves the "PM Chat interviews; agent writes" boundary; agents do NOT interview users.
- SC1.3 CLIENT-SIDE ONLY constraint is enforced structurally (not just documented) — e.g., PS verbs and skills live under `project-template/` and are not invokable from pack-self workflows.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 14 (architecture: PM Chat interviews; agent authors); Goal 1 (CLIENT-SIDE ONLY); Goal 2 (mode-2 path needs optional-but-recommended); INTAKE §1 framing (verbatim user); INTAKE §2 Q8 (architect-decides); INTAKE §8 walkthrough notes (Cap #1 row): "Boundary principle (PM-chat does Q&A + agent does heads-down) LOCKED; agent topology architect-decides."

**Cross-references:** Caps N1 (directory structure architect-decides), #4 (structured interview), #15 (workflow + doc integration); Goals 1, 2, 14; RESEARCH §9.4 (Wave 2 boundary); INTAKE §2 Q8.

**Architect bar:** LOW (PS-internal agent topology decision)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #2 — Two operational modes (from-scratch + existing-PRD ingest)

**Problem:** Users adopting PS arrive from two starting points. Some start from blank-slate ideation (Mode 1). Some have an existing PRD or product doc they want pack-integrated (Mode 2). Both must be FIRST-CLASS and equally supported.

**Goals:**
- Mode 1 (from-scratch): interview + research + write deliverables (Goal 2; §3.2 C2)
- Mode 2 (existing-PRD ingest + gap-fill): read existing PRD + identify pack-integration gaps + interview to fill + restructure (Goal 2; §3.2 C2)
- Both modes use the SAME structured interview approach (Goal 3; §7.1 INTAKE)
- Mode 2 reads existing content as audit-of-content; gaps surfaced via the same structured sections that Mode 1 elicits

**Success Criteria:**
- SC2.1 PS workflow supports Mode 1 entry: interview-from-scratch produces full deliverable set.
- SC2.2 PS workflow supports Mode 2 entry: existing-PRD ingest + gap-identification produces full deliverable set, where "gaps" are the sections the structured interview would have elicited.
- SC2.3 Both modes converge to the same deliverable set (N4 / N5 / N6 / mapping / per-architect any additional shapes); not separate output trees for separate modes.
- SC2.4 Mode-2 ingest is robust to varied input formats (markdown PRD, notion-export, Word doc, etc.); architect picks the input-format strategy.

**Disposition:** KEEP

**Scope verdict:** v11.x (both modes)

**Rationale:** Goal 2 user-direction (INTAKE §2 Q3 + Q7); §3.2 C2; INTAKE §8 walkthrough notes (Cap #2 row): "User direction: both first-class (Goal 2)"; BD-191 SC7.

**Cross-references:** Caps #4 (structured interview — shared by both modes), #11 (research orchestration — both modes invoke), N3 (PRD template — Mode 2 audits existing PRD against template); Goals 2, 3; INTAKE §2 Q3 + Q7; BD-191 SC7.

**Architect bar:** LOW (PS-internal mode mechanics)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #3 — Invocation model (episodic / light footprint)

**Problem:** PS is heavy at project init but episodic thereafter (milestone spikes + on-demand). A continuously-running PS surface is wrong — it would impose chronic overhead on a feature that only spikes. The invocation model must support init + spikes + on-demand without imposing background-process tax.

**Goals:**
- Heavy at project init (big product-planning effort) (Goal 5; INTAKE §1 (g))
- Spike at milestones — explicit (version releases) + implicit (feature work nearing end of planned scope) (Goal 5; INTAKE §2 Q2)
- On-demand invocation (user-driven) (Goal 5)
- Light footprint between spikes (no chronic overhead) (Goal 5; §3.3 C3)
- Covers BOTH new-project AND existing-project-adopting-pack as "project init" cases (walkthrough refinement 2026-05-24)

**Success Criteria:**
- SC3.1 PS install ships availability not adoption (project gets PS verbs / agents / skills installed but no work happens until user invokes).
- SC3.2 Invocation paths cover: (a) project init (new + existing-adopting); (b) milestone trigger; (c) on-demand verb.
- SC3.3 Between invocations PS has zero background process / always-on agent / scheduled job overhead.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 5 (episodic / light footprint); §3.3 C3; INTAKE §1 (g) (verbatim user "doesn't have a heavy footprint during implementation since it will be needed mostly in the beginning and then episodically as the product evolves over its lifecycle"); INTAKE §8 walkthrough notes (Cap #3 row): "Goal 5 (episodic / light footprint); covers new + existing-adopting both as 'project init'."

**Cross-references:** Caps #1 (core shape — invocation model depends on shape), #15 (workflow integration — invocation paths plumbed through pack workflows), #16 (lifecycle — PRD edits trigger spike); Goal 5; INTAKE §1 (g); INTAKE §2 Q2.

**Architect bar:** LOW (PS-internal invocation mechanics; trigger heuristics architect-decides)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N1 — PS deliverable directory structure (architect-decides)

**Problem:** PS deliverables (PRD + journeys + feature inventory + mapping + audit specs + others) need a discoverable home in `project-template/`. The per-stream-tree contract (`_rules.md` + `_intro.md` + `_toc.md` + per-deliverable files) is one candidate pattern from existing pack mechanisms (backlog / implementation-plan / changelog / groupings). But PS-specific properties may or may not fit that contract — pattern-matching out of context is an anti-pattern per pack memory `feedback_pattern_matching_out_of_context_antipattern`.

**Goals:**
- PS deliverables have a discoverable, navigable home (Goal 6; Goal 8 smooth integration)
- Directory structure is decided based on PS-specific properties, stated goals, and technical constraints — NOT pattern-matched from an adjacent pack mechanism without property-fit verification
- Whatever structure is chosen must integrate with pack workflows (Cap #15) and groupings #7 from-external ingest (Cap #13)

**Success Criteria:**
- SC N1.1 Architect investigates per-stream-tree contract fit AND alternative structures (flat directory; per-mode subdirectory; per-doc-type subdirectory; etc.) before locking.
- SC N1.2 Locked structure rationale cites PS-specific properties (episodic; multi-deliverable; varied input shapes; human-and-pack dual audience) that drive the fit decision.
- SC N1.3 Locked structure integrates with #15 workflow + doc integration paths AND #13 groupings #7 from-external ingest.
- SC N1.4 If per-stream-tree contract IS adopted, architect must satisfy the pack mechanism's existing rules (`_rules.md` per-stream rules from existing per-entry trees) without modifying the contract itself (HIGH bar — contract is locked pack mechanism).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 6 (deliverable shapes); Goal 8 (smooth integration); pack memory `feedback_pattern_matching_out_of_context_antipattern` (pattern-fit verification required); INTAKE §8 walkthrough notes (Cap N1 row): "REVISED from per-stream-tree: architect-decides structure based on PS-specific properties + stated goals + technical constraints. Pattern-matching out of context is anti-pattern per pack memory; architect must verify property-fit before adopting any pattern"; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 (originally recommended per-stream-tree; walkthrough refined to architect-decides).

**Cross-references:** Caps N4 / N5 / N6 / N2 / N8 (these deliverables live in whatever structure is chosen); Cap #13 (groupings ingest path must work with the chosen structure); Cap #15 (workflow integration); Goal 6; pack memory `feedback_pattern_matching_out_of_context_antipattern`; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1.

**Architect bar:** LOW for the directory-structure choice itself (PS-internal); **HIGH if architect adopts the per-stream-tree contract** (locked pack mechanism per `/backlog/_rules.md` / `/changelog/_rules.md` / groupings-designed pattern; cannot modify contract).

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

### Cluster 2 — Interview process (5 capabilities)

#### Capability #4 — Structured interview process

**Problem:** Random-walk interviews produce decorative PRDs (RESEARCH §9.1). The interview MUST have structured sections that need answers; problems/goals/SC framing per section; gap-identification across categories (market research / ideation / creativity / scope definition / resource constraints / priorities / constraints). Flow must accommodate non-linear human thought (§7.5).

**Goals:**
- NOT a random walk of questions; structured sections with explicit problems/goals/SC framing per section (Goal 3; §7.1 INTAKE)
- Same structured approach for Mode 1 and Mode 2 (Goal 3; Cap #2)
- Gap-identification across categories: market research, ideation, creativity, scope definition, resource constraints, priorities (Goal 3; §7.1 + Goal 17 priorities-as-first-class)
- Flow dynamics support non-linear thought patterns (strategic → tactical AND tactical → strategic; multi-entry starting points; relationship retention; coverage reconciliation; engaging onboarding) (Goal 3 refined; §7.5 INTAKE)
- Interview must produce inputs yielding genuinely high-quality products with real user benefits — not just pack-ingestible artifacts (Goal 7 + Goal 10; §7.5 quality target)

**Success Criteria:**
- SC4.1 Interview has named structural sections (architect-decides exact section set; cf. §6 8-item completeness bar as starting evidence).
- SC4.2 Each section carries problem / goal / SC framing for the elicitation focus.
- SC4.3 Mode-1 and Mode-2 use the same structural sections (gaps in Mode-2 surface as unanswered sections of the same structure).
- SC4.4 Flow accommodates non-linear progression: user can enter at any section; ideas evolve across sections; relationships across ideas are retained; coverage is reconciled before completion (§6 completeness bar gates).
- SC4.5 Opening framing invites the user in (not "give me a list of X"); architect designs the onboarding shape.
- SC4.6 Relationships across deliverables (N4 PRD relates to N5 journeys relates to N6 feature inventory) survive any flow-dynamics restructuring (§7.5 relationship retention).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 3 (interview structure); Goal 10 (quality-mitigation); Goal 7 (pack-as-audience drives interview content); §7 + §7.5 INTAKE; INTAKE §8 walkthrough notes (Cap #4 row): "Flow dynamics per new §7.5 (non-linear thought patterns supported; relationship retention; coverage reconciliation; engaging onboarding)"; BD-191 SC10(a).

**Cross-references:** Caps #5 (methodology positioning informs question framing), #6 (completeness bar — reconciliation target), #7 (quality-mitigation principles), N3 (PRD template — informs section structure), #11 (research orchestration — research signals inform section emphasis); Goals 3, 7, 10, 17 (priorities elicitation is part of structure); INTAKE §7 + §7.5; RESEARCH §5 interview frameworks (Mom Test discipline) + §9.1 (decorative-artifact failure mode); BD-191 SC10(a).

**Architect bar:** LOW (PS-internal interview design)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #5 — Methodology positioning (defensible defaults + override path)

**Problem:** Methodology-neutral PM tools force users to pick a framework with no guidance — a problem that contributes to muddled output per RESEARCH §8.4 (orthodoxy splits). Methodology-as-explicit-position is a pack differentiator per RESEARCH §9.2.

**Goals:**
- Ship defensible defaults per RESEARCH §9.5 (Continuous Discovery + OST; Mom Test; Lean Canvas or PR/FAQ; RICE or Value/Effort; common-denominator PRD; North Star + OKRs; JTBD-Christensen; Cagan vocabulary) (Goal 11; §3.5 C5)
- Provide per-project override path (architect picks override mechanism)
- Take a position — DO NOT ship methodology-neutral (Goal 11; RESEARCH §9.2)

**Success Criteria:**
- SC5.1 Each methodology area listed in RESEARCH §9.5 carries a shipped default in PS (or an architect-locked alternative with rationale).
- SC5.2 Per-project override mechanism exists (architect picks mechanism — config file, `_rules.md`-style, interactive override, etc.).
- SC5.3 Documentation explains WHY each default is chosen (citing RESEARCH §9.5 and any architect refinements).
- SC5.4 Persona-vs-JTBD position is explicit (Goal 11 + RESEARCH §9.5; pick one).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 11 (defensible methodology positioning); §3.5 C5; RESEARCH §9.5 (full defensible default table); RESEARCH §9.2 (methodology-as-explicit-position underserved gap); INTAKE §8 walkthrough notes (Cap #5 row): "Defensible defaults per RESEARCH §9.5"; BD-191 SC8.

**Cross-references:** Caps #4 (methodology shapes interview question style), N3 (PRD template embeds methodology shape — common-denominator sections), N4 / N5 / N6 (deliverable shapes inherit methodology defaults); Goal 11; RESEARCH §9.5 + §9.2; BD-191 SC8.

**Architect bar:** LOW (PS-internal methodology choices; per-project override mechanism is architect-internal)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #6 — Interview "complete" criteria (8-item completeness bar)

**Problem:** Without explicit "complete" criteria, the interview either drags forever (user fatigue; quality decay) or ends prematurely (missing critical input the PRD needs). The bar must be evidence-based AND architect-tunable.

**Goals:**
- Define when the interview can reasonably end vs continue (Goal 10)
- 8-item completeness bar (per walkthrough refinement; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 seven-item bar PLUS new Item 8 — Priorities elicited per Goal 17)
- Architect can modify the 8-item bar BUT must defend changes with evidence and logic (walkthrough decision)

**8-item completeness bar (preliminary):**
1. Vision and pillars elicited (analog: OT Phase A v3 §1-§2)
2. Anti-pillars elicited with reasoning (analog: OT Phase A v3 §3; differentiator vs commercial PRD templates per RESEARCH §9.2)
3. Audience staged with explicit out-of-scope (analog: OT Phase A v3 §4)
4. MVP-scope clusters identified at the M-cluster-equivalent level (analog: OT Phase A v3 §5)
5. NFRs elicited (analog: OT Phase A v3 §6)
6. Architectural seams MVP commits to identified (analog: OT Phase A v3 §7; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.7)
7. Conditional-inclusion items captured with explicit triggers (analog: OT Phase A v3 §5 table; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2; no "we'll see" entries)
8. **Priorities elicited (multi-axis per Goal 17)** — product/market fit; competitive necessity vs competitive advantage; technical constraints; resource constraints (time/money/team-size/expertise); scope decisions (MVP vs Phase 2 vs Phase N; in/out/conditional); cost/speed/quality/feature-sets/user-journeys (per INTAKE §1 (a)); user-named axes

**Success Criteria:**
- SC6.1 PS provides an explicit completeness check mechanism (architect picks: user-confirmation; mechanical check; both).
- SC6.2 Each of the 8 items has a check rule (presence, structure, non-empty, etc.); architect designs check rules.
- SC6.3 Architect-modified bar (additions / removals / refinements) cites evidence + logic per walkthrough decision.
- SC6.4 Item 8 (priorities) follows Goal 17 multi-axis structure with user-named-axes support.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 10 (quality-mitigation); Goal 17 (priorities as first-class); §7.5 (coverage reconciliation); PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 (7-item bar) + walkthrough refinement adding Item 8; INTAKE §8 walkthrough notes (Cap #6 row): "REFINED: original 7-item bar PLUS new 8th item — Priorities elicited (multi-axis per Goal 17). Architect can modify 8-item bar BUT must defend changes with evidence and logic"; BD-191 SC10 + SC11.

**Cross-references:** Caps #4 (structured interview gates by these items), #7 (quality-mitigation), N3 (PRD template structures these items), N4 (PRD synthesizes these items); Goals 10, 17; §7.5 coverage reconciliation; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4; BD-191 SC10 + SC11.

**Architect bar:** LOW (PS-internal completeness mechanism; architect may modify bar with evidence)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #7 — Quality-mitigation tactical principles

**Problem:** RESEARCH §9.1 surfaces multiple AI-PM-tool failure modes (decorative PRDs without facilitation; AI methodology selection muddled; persona without grounding; customer-interview replacement). These are real risks for any AI-assisted PM tool. PS must define TACTICAL (not just strategic) principles that mitigate them — concrete enough to drive design.

**Goals:**
- Tactical (not just strategic) guiding principles for quality (Goal 10; §7 INTAKE)
- Address both halves: (a) interview-structure quality (per Cap #4) and (b) audience-aware deliverables (per Cap #12) (Goal 10; §7 INTAKE)
- Mitigate RESEARCH §9.1 failure modes directly (decorative-PRD; muddled-methodology; persona-without-grounding; interview-replacement)
- Refined by §7.5 interview flow dynamics requirements (Goal 3 refined; §7.5)
- Cap N8 (human-readable rendering) explicitly addresses pack-only-output-creates-user-frustration failure mode (Goal 19)

**Success Criteria:**
- SC7.1 Tactical principles documented for interview structure (cross-references Cap #4 + §7.1 + §7.5).
- SC7.2 Tactical principles documented for audience-aware deliverables (cross-references Cap #12 + §7.2 INTAKE).
- SC7.3 Each RESEARCH §9.1 failure mode has a documented PS mitigation OR a documented rationale for non-mitigation (with architect bar HIGH for non-mitigation choices).
- SC7.4 Mitigation principles are concrete enough to drive design decisions (NOT just "do high quality work"); architect makes the principles operational.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 10 (quality-mitigation tactical principles); §7 + §7.5 INTAKE (full statements); RESEARCH §9.1 (failure modes); INTAKE §8 walkthrough notes (Cap #7 row): "Refined per new §7.5"; BD-191 SC10.

**Cross-references:** Caps #4 (interview structure quality), #6 (completeness bar quality), #12 (audience-aware deliverables quality), N2 (audit pass quality), N8 (human-readable rendering quality); Goals 7, 10, 19; §7 + §7.5 INTAKE; RESEARCH §9.1; BD-191 SC10.

**Architect bar:** LOW (PS-internal quality principles)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N3 — PRD template anti-pillars + conditional-inclusion sections

**Problem:** Commercial PRD templates focus on Goals + Non-Goals but rarely have Pillars / Anti-pillars / Conditional-inclusions with explicit triggers. OT evidence shows that anti-pillars-with-reasoning and conditional-inclusion-with-triggers prevent scope drift better than negative-list "Never" sections (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2). PS PRD template should ship these structural sections.

**Goals:**
- PRD template includes Pillars + Anti-pillars + Conditional-inclusions + Architectural commitments + Seams sections (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2 + §3.7)
- Conditional-inclusions require explicit triggers (NO "we'll see" entries)
- Anti-pillars carry reasoning (not just a flat "Never" list)
- Template differentiator vs commercial PRD templates (RESEARCH §9.2 underserved gap; methodology-as-explicit-position)

**Success Criteria:**
- SC N3.1 PS PRD template ships with these structural sections: Pillars / Anti-pillars (with reasoning) / Conditional-inclusions (with explicit triggers) / Architectural commitments / Seams.
- SC N3.2 Template explicitly disallows "we'll see" conditional-inclusion entries (architect picks enforcement: documented rule + audit-check OR mechanical check).
- SC N3.3 Anti-pillar entries require reasoning text (architect picks enforcement).
- SC N3.4 Template informs Cap #4 interview structure (interview elicits the inputs needed to populate template sections).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2 + §3.7 + §6.1; RESEARCH §9.2 (methodology-as-explicit-position differentiator); INTAKE §8 walkthrough notes (Cap N3 row): "Pillars / anti-pillars / conditional-inclusions / architectural-commitments sections; differentiator vs commercial PRD templates"; Goal 11 (defensible methodology positioning).

**Cross-references:** Caps #4 (interview elicits template inputs), #6 (completeness bar items align with template sections), N4 (narrative PRD authoring uses this template), N2 (audit pass verifies template-section presence); Goal 11; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2 + §3.7 + §6.1; RESEARCH §9.2.

**Architect bar:** LOW (PS-internal template design)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

### Cluster 3 — Deliverable outputs (6 capabilities)

#### Capability N4 — Narrative PRD authoring (pack-primary canonical)

**Problem:** Users + downstream consumers need a single narrative artifact that synthesizes vision + audience + pillars + anti-pillars + conditional-inclusions + MVP scope + post-MVP scope + architectural seams. The narrative artifact is the canonical PS PRD — opinionated about WHAT and WHEN; silent about HOW.

**Goals:**
- One narrative PRD per project (Goal 6; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §6.2)
- Synthesizes inputs from interview (Cap #4) + research (Cap #11) + audit (Cap N2) + template (Cap N3)
- Audience: humans (engineers, investors, re-review)
- PACK-PRIMARY canonical source-of-truth (Goal 7 audience-priority)
- Human-readable rendering is SECONDARY via Cap N8 generator (Goal 19); not either-or; pack-primary remains canonical

**Success Criteria:**
- SC N4.1 PS produces a single narrative PRD per project (Mode 1 + Mode 2 converge to same artifact shape).
- SC N4.2 PRD follows common-denominator 8 sections per RESEARCH §4.8 + §9.3 (vision; audience; product surfaces; requirements; NFRs; out-of-scope; roadmap; goals + non-goals).
- SC N4.3 PRD includes Pillars / Anti-pillars / Conditional-inclusions / Architectural commitments / Seams structural sections per Cap N3.
- SC N4.4 PRD section ordering follows OT Phase E.1 evidence (vision → audience → product surfaces → requirements → NFRs → out-of-scope → roadmap) OR architect-locked alternative with rationale.
- SC N4.5 PRD opinionated about WHAT and WHEN; silent about HOW (no solution leakage per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.1 no-solutions-discipline).
- SC N4.6 PRD references journeys (N5) by ID and feature inventory rows (N6) by `feature_id` (relationship retention per §7.5 INTAKE).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 6 (deliverable shapes; PRD with MVP line); Goal 7 (pack-as-audience; pack-primary canonical); Goal 19 (human-readable rendering is secondary via N8); Goal 11 (methodology-positioning; common-denominator PRD shape); PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §3.7 + §6.2 + §7.2 (narrative PRD template design); RESEARCH §4.8 (common-denominator sections); INTAKE §8 walkthrough notes (Cap N4 row): "PACK-PRIMARY (Goal 7 audience-priority); human-readable rendering generated via Cap N8 (Goal 19); pack-primary source-of-truth unchanged."

**Cross-references:** Caps N3 (template informs shape), N5 (journeys cross-reference), N6 (feature inventory cross-reference), N2 (audit pass), N8 (human-readable rendering); Goals 6, 7, 11, 19; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §3.7 + §6.2 + §7.2; RESEARCH §4.8 + §9.3; INTAKE §8.

**Architect bar:** LOW (PS-internal deliverable shape; cross-references to N5 / N6 / N8 require architect to lock the relationship retention mechanism — also LOW since all internal to PS)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N5 — Structured user-journey docs

**Problem:** User journeys need a structured shape that downstream pack workflows (groupings of Kind `user-journey`; phases that implement journey steps) can consume. OT Phase B.1 evidence shows mode-classification (Building / Discovery / Recovery / Setup) is OT-specific; the pack-target may need different modes.

**Goals:**
- One structured journey doc per major user journey (Goal 6; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §6.2)
- Mode-classified per architect-decided mode scheme (NOT OT's Building/Discovery/Recovery/Setup — that's OT-specific)
- Per-journey header carries: goal + trigger + frequency + stage + success criteria + anti-goal (OT Phase B.1 pattern)
- Cross-references to N4 (PRD) and N6 (feature inventory rows)
- Optional per project type (only for products with user-facing flows)

**Success Criteria:**
- SC N5.1 PS produces one structured journey doc per major journey identified during interview.
- SC N5.2 Journey doc carries header: goal / mode (per architect-decided scheme) / trigger / frequency / stage / success criteria / anti-goal.
- SC N5.3 Journey steps are numbered + carry `[F-NEW]`-equivalent feature-touchpoint markers cross-referencing N6 feature inventory rows.
- SC N5.4 Phase 2/3 journeys carry seam references (architectural commitment markers per N3 + N4).
- SC N5.5 Architect picks mode-classification scheme based on pack-target audience (not OT-specific Building/Discovery/Recovery/Setup); rationale documented.
- SC N5.6 Journey doc is optional — products without user-facing flows do not need journey docs.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 6 (deliverable shapes; journeys); PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §6.2 + §7.2 (journey template design); INTAKE §8 walkthrough notes (Cap N5 row): "Mode-classification scheme for pack-target audience architect-decided (OT's Building/Discovery/Recovery/Setup is OT-specific; pack-target may need different modes)"; INTAKE §1 (d) (verbatim user "user journeys, ambient or shared feature groups, foundational groupings").

**Cross-references:** Caps N4 (PRD references journeys), N6 (feature inventory cross-reference), N2 (audit pass — journey-mode-classified + success-criteria + anti-goal); Cap #13 (groupings integration — journeys feed groupings of Kind `user-journey`); Goal 6; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §6.2 + §7.2; INTAKE §1 (d).

**Architect bar:** LOW (PS-internal journey shape + mode-classification scheme)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N6 — Structured feature inventory + mapping

**Problem:** Feature lists in narrative PRDs are hard to ingest mechanically. A structured, machine-parseable feature inventory (per-feature `feature_id` + cluster + problem + goals + success_criteria + dependencies + seam_refs + cross-references to journeys / seams / pack primitives) enables groupings #7 from-external ingest and PRD-to-code traceability. Mapping is PART of N6 (combined per §6 D restructuring).

**Goals:**
- Machine-parseable structured feature inventory (Goal 6; Goal 12 PRD-to-code traceability)
- Per-feature row carries essential schema: `feature_id` + name + description + problem + goals + success_criteria (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §7.4)
- Likely essential: `dependencies` + `status` (MVP/post-MVP) + `cluster`
- Domain-specific extension fields: `seam_refs:` + `journey_consumers` + `shared_with` + `external_research_needed` + `existing_code` + `architect_notes` + `design_notes` (per-project extensible per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §7.4)
- Mapping IS part of N6 — each row carries pack-primitive cross-references (BD-NNN / phase-N / GRP-NNN by ID; reference-only)
- Feeds groupings via #7 from-external ingest (Cap #13)

**Success Criteria:**
- SC N6.1 PS produces one structured feature inventory per project (machine-parseable; architect picks format — YAML / JSON / TOML / etc.).
- SC N6.2 Essential fields (`feature_id` + name + description + problem + goals + success_criteria) ship in core schema.
- SC N6.3 Extension fields supported per-project via `_rules.md` (or equivalent per architect's directory structure decision per N1) declaration.
- SC N6.4 `seam_refs:` field present per N3 + N4 architectural-commitment cross-reference need.
- SC N6.5 Each feature row carries cross-references to journeys (N5) + pack primitives by ID (reference-only).
- SC N6.6 No-solutions-discipline grep pass per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.1 (audit by Cap N2).
- SC N6.7 Cycle detection on `dependencies` graph (per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §4.2; audit by Cap N2).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 6 (deliverable shapes; feature list + mapping); Goal 12 (PRD-to-code traceability); PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.3 + §3.4 + §3.5 + §6.2 + §7.4 (feature inventory + mapping design + core/extension schema); INTAKE §8 walkthrough notes (Cap N6 row): "Schema fields essential / extension split per architect-doc §7.4; `seam_refs:` field per §5.5 reinforcement"; INTAKE §1 (e) (verbatim user "mapping docs that include references that enable mappings from work items and features to tasks, phases, and groupings").

**Cross-references:** Caps N4 (PRD references feature inventory rows), N5 (journeys reference features), N2 (audit pass — no-solutions + cycle-detection + seam-coverage), N8 (human-readable rendering uses N6 as source); Cap #13 (groupings #7 from-external ingest target); Cap #14 (PRD-to-code traceability); Goals 6, 12; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.1 + §3.3 + §3.4 + §3.5 + §6.2 + §7.4; INTAKE §1 (e).

**Architect bar:** LOW for schema design (PS-internal); **HIGH for cross-feature references to pack primitives** (Goal 18 PS-to-pack-entry-type boundary; cannot create canonical entry-type artifacts; reference-only is the bound)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #11 — Research orchestration

**Problem:** PS needs to invoke external research (competitive analysis; market evidence; tool research; methodology evidence) at multiple potential points in the workflow. Whether this is one capability or several, whether it splits into initial-discovery + per-feature, whether it's a sub-agent or skill or hybrid — these are architect-decided shape choices (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3: explicit don't-prescribe).

**Goals:**
- Spawn `docs-researcher` for competitive / market / tool research (Goal 9; INTAKE §1 (b))
- Wide net + high quality bar (proven / widely-acknowledged / highly-recommended) (Goal 9)
- Full citations + logical reasoning + evidence (Goal 9)
- Multi-stage invocation (initial discovery at project init; per-feature `external_research_needed` cases at PRD authoring; per-architect-question research at design time)
- PS assembles outputs from multiple sources (interview + research + existing PRD per Mode 2) into coherent deliverables

**Success Criteria:**
- SC11.1 PS workflow includes at least one research-orchestration mechanism (architect picks shape — split / single / sub-decomposition / skill / hybrid).
- SC11.2 Research outputs carry full citations + dates + logical reasoning + evidence (Goal 9 quality bar).
- SC11.3 Per-feature `external_research_needed` cases (when surfaced during interview) trigger per-feature research invocations.
- SC11.4 PS deliverables (N4 / N5 / N6) cite research outputs by reference.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 9 (research orchestration); INTAKE §1 (b) (verbatim user "spawn the doc-researcher agent to do external research"); INTAKE §3 (research-scope paragraph); INTAKE §8 walkthrough notes (Cap #11 row): "Shape architect-decides per §6 E3 (don't prescribe split vs single vs sub-decomposition vs skill-form)"; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3 (explicit don't-prescribe); RESEARCH §10 (research-methodology source quality).

**Cross-references:** Caps #4 (interview surfaces research questions), N4 / N5 / N6 (deliverables cite research), N2 (audit pass — citation presence check); Goal 9; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3 + §7 architect-investigation-areas; INTAKE §1 (b) + §3.

**Architect bar:** LOW (PS-internal research orchestration shape; explicit don't-prescribe — architect has maximum freedom per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N2 — Mechanical audit pass for PS deliverables

**Problem:** PS deliverables are produced by AI-assisted workflows. Without mechanical audits, decorative-PRD failure modes (RESEARCH §9.1) cannot be caught. Each deliverable type benefits from a defined audit-check spec — mechanical where possible; user-judgment items flagged.

**Goals:**
- Each deliverable type has a defined audit-check spec (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.8 + §6.1)
- Mechanical where possible (sub-agent or skill or validate-pack extension — architect picks)
- User-judgment items flagged (not silent)
- Audit specs (preliminary):
  - **PRD audit (N4):** anti-pillars present; conditional-inclusion present with explicit triggers; outcomes-over-outputs vocab check; Goals + Non-Goals paired; architectural-commitments section present
  - **Journey audit (N5):** mode-classified; success-criteria present; anti-goal present
  - **Feature inventory audit (N6):** every feature has problem + goals + success_criteria; no-solutions-discipline grep pass with PS-PRD-relevant violation patterns; cycle detection on `dependencies` graph; seam-coverage check
  - **Mapping audit (within N6):** every feature maps to ≥1 pack primitive (reference-only)

**Success Criteria:**
- SC N2.1 PS ships audit specs for each deliverable type (N4 / N5 / N6 + mapping-portion).
- SC N2.2 Audit invocation mechanism (sub-agent / skill / validate-pack extension) is architect-decided + locked.
- SC N2.3 Mechanical-vs-user-judgment items flagged in each spec.
- SC N2.4 Audit findings surface to user before PS workflow declares "complete."

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 10 (quality-mitigation tactical principles); RESEARCH §9.1 (decorative-PRD failure mode mitigation); PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.8 + §6.1 (audit-pass design); INTAKE §8 walkthrough notes (Cap N2 row): "PRD audit / journey audit / feature-list audit / mapping-doc audit; mechanical where possible; user-judgment items flagged."

**Cross-references:** Caps N4 / N5 / N6 (deliverables audited), N3 (PRD template — audit checks template-section presence), #6 (completeness bar — audit may include bar items), #7 (quality-mitigation — audit IS a quality-mitigation mechanism); Goal 10; RESEARCH §9.1; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.1 + §3.8 + §6.1.

**Architect bar:** LOW (PS-internal audit mechanism)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability N8 — Human-readable PRD rendering generator

**Problem:** PS pack-primary deliverables (N4 + N5 + N6) are optimized for pack ingestion (Goal 7). Users reviewing PS output get docs aimed at the config pack — cannot visually verify accuracy of PS-captured content. Real user-experience failure mode: frustration leads to abandonment of PS feature entirely. A complementary human-readable rendering generator reads pack-primary sources and produces a human-targeted PRD document optimized for visual verification.

**Goals:**
- Pack-primary remains canonical (Goal 7 priority unchanged)
- Human-readable rendering is SECONDARY artifact derived from pack-primary (Goal 19)
- Not either-or; both can exist
- Output: human-readable PRD doc for visual verification only; NOT pack-ingested
- Generator reads pack-primary sources (N4 + N5 + N6 + any architect-defined cross-PS-doc source set) and produces a human-targeted rendering

**Success Criteria:**
- SC N8.1 PS ships a human-readable rendering generator (mechanism: skill / sub-agent / external tool / pack-adjacent script — architect picks).
- SC N8.2 Output format (markdown / HTML / PDF / other) is architect-decided.
- SC N8.3 Section ordering and human-comprehension emphasis is architect-decided.
- SC N8.4 Structured content (feature inventory rows) is rendered (architect picks: prose / tables / both).
- SC N8.5 Trigger semantics (on-demand verb vs auto-generate on milestone) is architect-decided.
- SC N8.6 Output is clearly marked "not pack-ingested; secondary rendering for human verification only."
- SC N8.7 Architect may produce one PRD or multiple (e.g., executive summary + detailed PRD).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 19 (human-readable PRD rendering for user verification — full statement in INTAKE §9.5); user-experience failure mode without it (INTAKE §9.5 + INTAKE §8 walkthrough notes Cap N8 row); BD-191 SC13; pack-primary canonical preserved per Goal 7.

**Cross-references:** Caps N4 / N5 / N6 (pack-primary sources); Cap #7 (quality-mitigation — N8 addresses pack-only-output user-frustration failure mode); Goals 7, 19; INTAKE §9.5 + §8 walkthrough Cap N8 row; BD-191 SC13.

**Architect bar:** LOW (rendering mechanism + format + trigger semantics are PS-internal architect choices)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

### Cluster 4 — Pack integration (3 capabilities)

#### Capability #12 — Audience-aware deliverable shapes

**Problem:** Other PM tools cannot constrain deliverable shapes by audience because their audience is unknown. PS knows the pack as audience (workflows / docs / scripts / tracker / groupings / phases / tasks / backlog entries). This is a competitive advantage per RESEARCH §9.2 + INTAKE §7.2. Without explicit audience-awareness, PS deliverables drift toward open-ended PM-tool conventions and lose the pack-integration value.

**Goals:**
- PS knows the pack as audience (Goal 7; §7.2 INTAKE)
- Deliverables CONSTRAINED by pack-integration knowledge — narrower / more-specific than open-ended PM tools (Goal 7)
- Pack-data-structure knowledge informs deliverable design (Goal 18; §3.7 C7)
- Methodology-defaults knowledge informs deliverable methodology (Goal 11; §3.5 C5)
- PACK-PRIMARY priority is FIRST (Goal 7); human-readable rendering is SECONDARY via Cap N8 (Goal 19); not either-or

**Success Criteria:**
- SC12.1 Each deliverable type (N4 / N5 / N6) is designed with explicit pack-audience constraints (sections; fields; cross-references) — not open-ended PM-tool conventions.
- SC12.2 Deliverable shapes are informed by pack data-structure context (phases / tasks / groupings / phase-parts per Goal 18 §3.7 C7).
- SC12.3 Deliverable shapes are informed by methodology defaults (per Goal 11 + Cap #5).
- SC12.4 Audience-priority is documented: pack-primary canonical (Goal 7); human-readable rendering via Cap N8 (Goal 19); not either-or.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 7 (audience-aware deliverables); Goal 18 (PS-to-pack-entry-type boundary informs deliverable shape); §7.2 INTAKE (verbatim user); RESEARCH §9.2 (underserved-gap; pack-integration value); INTAKE §8 walkthrough notes (Cap #12 row): "Pack-data-structure knowledge HIGH-bar (locked pack state per `reference_pack_entry_type_semantics`); methodology-defaults knowledge LOW-bar"; BD-191 SC10(b).

**Cross-references:** Caps N4 / N5 / N6 (deliverables constrained by audience), N8 (human-readable rendering — secondary), #5 (methodology defaults), #13 (groupings integration — downstream consumption pattern), #14 (PRD-to-code traceability — pack primitives audience); Goals 7, 11, 18, 19; §7.2 INTAKE; RESEARCH §9.2; BD-191 SC10(b).

**Architect bar:** LOW for methodology-defaults-knowledge component (PS-internal); **HIGH for pack-data-structure-knowledge component** (locked pack state per `reference_pack_entry_type_semantics`; architect cannot arbitrarily change pack entry-type semantics)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #13 — Cross-feature integration with groupings (BD-186 / BD-189)

**Problem:** PS docs (N4 PRD + N5 journeys + N6 feature inventory + mapping) feed groupings (GRP-NNN). The groupings #7 from-external ingest workflow handles this. PS must integrate via this existing workflow — ZERO hard dependency in either direction (§3.4 C4). PS NEVER produces `GRP-NNN.md` files directly.

**Goals:**
- ZERO hard dependency in either direction (Goal 8; §3.4 C4)
- PS feeds groupings via existing #7 from-external ingest workflow (Goal 8; INTAKE §2 Q6)
- PS NEVER produces `GRP-NNN.md` files directly (Goal 8 + Goal 18; INTAKE §2 Q6 "out of scope")
- HANDOFF-V11.1-ARCHITECT.md may receive PS-awareness amendment (BD-191 description)

**Success Criteria:**
- SC13.1 PS deliverables (N4 / N5 / N6) are shaped such that groupings #7 from-external ingest can consume them without forcing PS-specific paths into groupings workflow.
- SC13.2 PS workflow never writes to `project-template/docs/project/groupings/` (or wherever groupings tree lands per groupings architect).
- SC13.3 PS deliverables cross-reference groupings IDs (`GRP-NNN`) reference-only — never canonical.
- SC13.4 Architect investigates whether HANDOFF-V11.1-ARCHITECT.md needs PS-awareness amendment; surfaces proposed amendment if so.
- SC13.5 Architect investigates Capability #7 from-external ingest details with groupings architect (cross-feature coordination); does NOT modify groupings architecture out of scope (HIGH bar).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 8 (smooth pack integration; zero forced dependency); Goal 18 (PS-to-pack-entry-type boundary; PS does not create canonical pack entry-type artifacts); §3.4 C4; INTAKE §2 Q5 + Q6 (verbatim user); BD-191 description "Cross-feature relationship with groupings" + SC6 + SC12; INTAKE §8 walkthrough notes (Cap #13 row): "Cross-feature integration with BD-186/BD-189 groupings work; PS feeds via existing #7 from-external ingest"; REQUIREMENTS-GROUPINGS-V11.md Capability #7 SC7.8 (groupings-side conversion responsibility).

**Cross-references:** Caps N4 / N5 / N6 (deliverables feeding groupings #7), #12 (audience-aware deliverable shapes), #14 (PRD-to-code traceability — groupings IDs referenced); Goals 8, 18; §3.4 C4; INTAKE §2 Q5 + Q6; BD-191 SC6 + SC12; REQUIREMENTS-GROUPINGS-V11.md Capability #7 SC7.8.

**Architect bar:** **HIGH** — cross-feature integration with locked groupings architecture (BD-186 Resolved; BD-189 implementation umbrella). Architect cannot arbitrarily change groupings #7 from-external ingest workflow; must investigate thoroughly + coordinate with groupings architect (downstream BD).

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #14 — PRD-to-code traceability

**Problem:** PRD-to-code traceability is thin in commercial PM tools (RESEARCH §8.6 + §9.2). Pack is uniquely positioned — BD-NNN / phase-N / GRP-NNN / IMPL-REPORT primitives can thread a traceability path. PS deliverables that reference pack primitives by ID enable features → BDs → commits / PRs threading.

**Goals:**
- Features in N6 feature inventory carry cross-references to pack primitives by ID (Goal 12)
- Traceability is mostly REFERENCE — pack-side primitives carry canonical state; PS docs cite them (Goal 18; §3.7 C7)
- Pack-uniquely-positioned advantage per RESEARCH §9.2 (underserved gap)
- Pack's existing BD / phase / grouping / IMPL-REPORT primitives carry the threading

**Success Criteria:**
- SC14.1 N6 feature inventory schema supports cross-references to pack primitives by ID (`BD-NNN` / `phase-N` / `GRP-NNN`).
- SC14.2 PS deliverable workflow updates cross-references when pack-side primitives are created (mechanism architect-decides; may be manual / verb-driven / automated).
- SC14.3 Traceability direction: PS deliverables REFERENCE pack primitives; pack primitives may reference PS deliverables (architect-decides cross-direction; not required).
- SC14.4 Cross-references are reference-only — PS does NOT create canonical pack-side primitives (Goal 18 boundary).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 12 (PRD-to-code traceability — pack uniquely positioned); Goal 18 (boundary — PS references; pack-side creates); RESEARCH §9.2 (underserved-gap; pack-differentiator); INTAKE §8 walkthrough notes (Cap #14 row): "Pack-differentiator per RESEARCH §9.2; features → BD-NNN/phase-N/GRP-NNN references → commits/PRs"; BD-191 SC12.

**Cross-references:** Caps N6 (feature inventory schema with cross-references), #13 (groupings IDs referenced); Caps N4 / N5 (PRD + journeys reference features by ID); Goals 12, 18; RESEARCH §9.2; BD-191 SC12.

**Architect bar:** LOW for PS-side reference mechanism; **HIGH for pack-side primitive creation-and-update workflows** (locked pack architecture; cannot change BD / phase / grouping / IMPL-REPORT creation paths)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

### Cluster 5 — Workflow + lifecycle (2 capabilities)

#### Capability #15 — Workflow + doc integration (scope expanded)

**Problem:** PS must integrate with all pack workflows / docs / scripts / tools that touch the developer's product work. Originally scoped to METHODOLOGY.md / PM-CHAT.md / Trinity / OPTIONAL-FEATURES.md / agent + skill files / HELP-FRAGMENT-TRACKER. Walkthrough expanded scope to ALSO include QUICKSTART.md + `scripts/init-project.sh` + existing-project-adopting-pack workflow + architect-discovery for ALL unnamed integration points (any unnamed touchpoints surfaced during architect's survey).

**Goals:**
- Integrate with named pack docs/scripts (METHODOLOGY.md / PM-CHAT.md / Trinity / OPTIONAL-FEATURES.md / agent + skill files / HELP-FRAGMENT-TRACKER)
- Integrate with QUICKSTART.md (PS shows up in quickstart path for new projects)
- Integrate with `scripts/init-project.sh` (PS install + invocation paths)
- Integrate with existing-project-adopting-pack workflow (Mode 2 + Goal 5 walkthrough refinement)
- Architect-discovery for all unnamed integration points (survey ALL pack docs/scripts/workflows; surface integration points not just from the named subset)
- Per-CLI parity (Check 27) for any agent / skill file additions

**Success Criteria:**
- SC15.1 PS integration points exhaustively surveyed by architect (architect-discovery for unnamed points beyond the named subset).
- SC15.2 Named integration surfaces have documented PS workflow / wording / invocation paths (METHODOLOGY.md / PM-CHAT.md / Trinity / OPTIONAL-FEATURES.md / agent + skill files / HELP-FRAGMENT-TRACKER / QUICKSTART.md / `scripts/init-project.sh`).
- SC15.3 Existing-project-adopting-pack workflow has documented PS Mode-2 path (PS reads existing product docs; identifies pack-integration gaps; interview to fill).
- SC15.4 New agent / skill file additions satisfy per-CLI parity (Check 27).
- SC15.5 Trinity rule honored: any changes to project-template/CLAUDE.md / AGENTS.md / GEMINI.md propagate in parallel (default).
- SC15.6 PS HELP-FRAGMENT entries follow pack help-system conventions.

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 14 (architecture: PM Chat interviews); Goal 8 (smooth pack integration); INTAKE §8 walkthrough notes (Cap #15 row): "SCOPE EXPANDED: original surfaces ... PLUS QUICKSTART.md + `scripts/init-project.sh` + existing-project-adopting-pack workflow + architect-discovery for all unnamed integration points. Architect surveys ALL pack docs/scripts/workflows for integration points; surfaces all of them, not just the named subset"; INTAKE §1 user framing (verbatim user "All of this must integrate smoothly into the pack").

**Cross-references:** Caps #1 (core shape — drives agent/skill integration), #2 (two modes — Mode 2 needs existing-project path), #3 (invocation model — invocation paths plumb through workflows); Goals 8, 14; INTAKE §8 walkthrough notes Cap #15 row.

**Architect bar:** LOW for PS-side integration content (workflows / wording / invocation); **HIGH for changes to locked pack docs/scripts/workflows** (cannot modify METHODOLOGY.md / PM-CHAT.md / Trinity / etc. structure out of scope; must propose changes through Pack Chat with user approval per pack memory `feedback_pack_chat_does_no_fixes` and `feedback_user_prescriptive_authority`)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

#### Capability #16 — PRD lifecycle management

**Problem:** PS deliverables (PRD + journeys + feature inventory) evolve over project lifetime. Without explicit lifecycle, edits create stale-copy / version-drift / lost-context problems. The simplest lifecycle (edits in place; addenda for scope additions; major scope changes tracked via existing pack primitives) is the user-stated direction (Goal 15).

**Goals:**
- Edits in place for PRD revisions (Goal 15; INTAKE §2 Q9)
- Addenda / follow-on docs for scope additions (Goal 15)
- Major scope changes tracked via existing pack primitives (phases for pre-scheduled; backlog for emergent) (Goal 15)
- NO new lifecycle states (Goal 15)
- Pack-existing primitives carry the tracking; PS does not invent parallel lifecycle

**Success Criteria:**
- SC16.1 PS workflow supports in-place PRD edits (architect picks mechanism — direct edit / verb-driven / both).
- SC16.2 Scope-addition workflow supports addenda or follow-on docs (architect picks shape; consistent with N1 directory structure).
- SC16.3 Major-scope-change workflow routes to existing pack primitives (phases / backlog) — does NOT create new PS-side lifecycle states.
- SC16.4 PRD lifecycle integrates with Cap #14 (cross-references update when pack primitives change).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 15 (simple lifecycle); INTAKE §2 Q9 (verbatim user "Keep it simple. If there are edits, the PRD can be edited. If there is additional scope, new addendum or follow-on docs can be added. This work can be tracked as phases or backlog entries"); INTAKE §8 walkthrough notes (Cap #16 row): "Edits in place; addenda for scope additions; tracked via existing pack primitives (phases / backlog)."

**Cross-references:** Caps N4 / N5 / N6 (deliverables edited), N1 (directory structure supports addenda), #14 (cross-reference updates on lifecycle changes), #3 (milestone-spike invocation triggers lifecycle events); Goal 15; INTAKE §2 Q9.

**Architect bar:** LOW (PS-internal lifecycle mechanism)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

### Cluster 6 — Scope boundary (1 capability)

#### Capability #17 — Wave 3 exclusion + minimal validation surface

**Problem:** Wave 3 (autonomous agentic PM) is vapor per RESEARCH §9.4. Pack's credibility requires explicit Wave-3 exclusion. PS is Wave 2 (content-gen in PM workflows) — credible territory. Pack adds value above "I'll just paste this into Claude" via project-context awareness + integration + methodology positioning. Validation surface must be MINIMAL — PS-produced docs are user-facing reference material, not pack-validated entry types like backlog / phase.

**Goals:**
- Wave 3 OUT OF SCOPE (Goal 13; §3.6 C6)
- PS is Wave 2 (credible territory) (Goal 13)
- Pack adds value above "paste into Claude" baseline (Goal 13; RESEARCH §9.4)
- Validation surface MINIMAL (architect-decides per-deliverable validation specifics)
- Per-deliverable audience-primary classification (human / pack / dual) architect-decides

**Success Criteria:**
- SC17.1 PS architecture documents Wave 3 (autonomous agentic PM) as OUT OF SCOPE explicitly.
- SC17.2 PS workflow does NOT include agentic-PM features that automate PM judgment (architect-decides specific lines — what does PS scaffold vs facilitate vs audit vs render vs decide).
- SC17.3 PS docs include validation surface (architect picks: validate-pack extensions; sub-agent audit; skill-based check; none).
- SC17.4 Validation surface is MINIMAL — PS docs are user-facing reference material; not pack-validated entry-type artifacts.
- SC17.5 Per-deliverable audience-primary classification is documented (human-primary / pack-primary / dual).

**Disposition:** KEEP

**Scope verdict:** v11.x

**Rationale:** Goal 13 (Wave 2 only; Wave 3 vapor OUT); §3.6 C6; RESEARCH §9.4 (Wave taxonomy); INTAKE §8 walkthrough notes (Cap #17 row): "Wave 3 (autonomous agentic PM) OUT locked per Goal 13; validation specifics architect-decided per-deliverable; per-deliverable audience-primary classification (human / pack / dual) architect-decided"; BD-191 SC9.

**Cross-references:** Caps N2 (audit pass — minimal validation surface); Caps N4 / N5 / N6 / N8 (per-deliverable audience-primary classification); Goal 13; §3.6 C6; RESEARCH §9.4; BD-191 SC9.

**Architect bar:** LOW (PS-internal scope-boundary mechanism; validation surface design)

**Preliminary; subject to architect challenge at PS design pass** per pack memory `feedback_preliminary_triage_architect_challenge`.

---

## §5 — Cross-feature integration with groupings (BD-186 / BD-189)

### §5.1 — Cross-feature relationship summary

Groupings (BD-186 Resolved; BD-189 implementation umbrella) is the only v11.x+ feature with explicit PS cross-feature integration. The relationship has these locked properties:

- **ZERO HARD DEPENDENCY in either direction** (§3.4 C4; Goal 8; INTAKE §2 Q5 + Q6; BD-191 description "Cross-feature relationship with groupings")
- **PS feeds groupings via existing #7 from-external ingest workflow** (Goal 8); the from-external ingest is groupings Capability #7 in REQUIREMENTS-GROUPINGS-V11.md
- **PS NEVER produces `GRP-NNN.md` files directly** (Goal 8 + Goal 18; INTAKE §2 Q6 "out of scope")
- **Groupings stand alone per BD-186** (no PS dependency); PS is OPTIONAL upstream feeder
- **HANDOFF-V11.1-ARCHITECT.md may receive PS-awareness amendment** during PS architect's work (BD-191 description; PS architect surfaces if needed)

### §5.2 — Integration mechanism (preliminary)

PS deliverables flow into groupings via the from-external ingest workflow:

1. PS produces N4 (PRD) + N5 (journey docs) + N6 (feature inventory + mapping) per their per-cluster shape decisions
2. Groupings #7 from-external ingest reads PS deliverables AND non-PS inputs (project-provided docs; varied formats per groupings architect)
3. Groupings #7 produces `GRP-NNN.md` entries based on its own Capability #7 SC7.x success criteria + Capability #7 SC7.8 (PS-to-groupings conversion responsibility, user-approved 2026-05-24)
4. PS-side cross-references update reference-only to point to created `GRP-NNN` IDs (Cap #14 PRD-to-code traceability)

### §5.3 — Architectural-knowledge propagation (Goal 18 mechanism)

Architectural seams + NFRs + anti-pillars + conditional-inclusions live in PS deliverables (PRD N4 + feature inventory N6 + Cap N3 PRD template) and propagate to pack entry-type workflows via the conversion mechanism (groupings #7 + phases). PS-side structural surfaces are the canonical home; pack entry-type workflows derive what they need from PS sources during conversion. Architectural knowledge IS NOT dropped just because it is not represented as a field on every pack entry-type schema (Goal 18 INTAKE §9.4 statement).

### §5.4 — Architect bar (HIGH)

The cross-feature integration with groupings carries a HIGH architect bar:
- Groupings architecture is locked (BD-186 Resolved; BD-189 implementation umbrella). PS architect cannot arbitrarily change groupings #7 from-external ingest workflow.
- Goal 18 boundary (PS does not create canonical pack entry-type artifacts) is HIGH-bar per `reference_pack_entry_type_semantics`.
- PS architect must coordinate with the groupings architect (downstream BD-189 phase) for any proposed amendments to HANDOFF-V11.1-ARCHITECT.md or to REQUIREMENTS-GROUPINGS-V11.md.

### §5.5 — Out-of-scope (for PS architect)

- Modifying REQUIREMENTS-GROUPINGS-V11.md Capability #7 (SC7.8 lands the conversion responsibility on the groupings side; PS architect can SURFACE proposed amendments but not author them)
- Modifying HANDOFF-V11.1-ARCHITECT.md (PS architect can propose updates but Pack Chat / groupings team writes them)
- Producing `GRP-NNN.md` files directly (PS NEVER does this)
- Replacing groupings #7 from-external ingest with a PS-direct path (the from-external ingest IS the integration path)

---

## §6 — Tactical guiding principles for interview

### §6.1 — Reference to companion source sections

Tactical guiding principles for the interview are detailed in INTAKE §7.1 (interview structure intuition) and INTAKE §7.5 (interview flow dynamics). Full statements are in those companion sections; this §6 references and surfaces architect-decided specifics without duplicating verbatim content.

**Companion §7.1 (interview structure intuition; user-stated 2026-05-24):**
- Clear problems / goals / success criteria tied to BOTH product-definition goals AND smooth pack integration
- Structured sections that need answers — NOT free-form chat
- Gap-identification across categories (market research / ideation / creativity / scope / resources / priorities / constraints)
- Mode-1 and Mode-2 use the SAME structured approach

**Companion §7.5 (interview flow dynamics; user-stated 2026-05-24):**
- Quality target beyond pack ingestion: interview must produce genuinely high-quality products
- Research role: signaling (informs what to elicit; not replacing elicitation)
- Flow flexibility: non-linear thought patterns; strategic ↔ tactical bidirectional; multi-entry starting points
- Relationship retention across deliverables (N4 PRD ↔ N5 journeys ↔ N6 feature inventory)
- Coverage reconciliation against §6.x completeness bar (Cap #6 8-item bar)
- Onboarding / presentation: user is INVITED into the conversation, not forced through predetermined section order

### §6.2 — Architect-decided specifics

**Interview structure design (Cap #4):** Architect decides:
- The exact named structural sections
- Section ordering (or section-orderless model accommodating non-linear flow)
- Per-section problem / goal / SC framing
- Gap-identification process per category (mechanical vs interactive)

**Flow accommodation mechanism (Cap #4 + §7.5):** Architect decides:
- How non-linear entry points are supported (UI affordance; verb-driven; conversation-driven)
- How strategic ↔ tactical bidirectional flow is captured
- How relationships across deliverables are retained mechanically (cross-reference fields; graph; both)

**Relationship retention (Caps N4 / N5 / N6 + §7.5):** Architect decides:
- The cross-reference mechanism in N4 ↔ N5 ↔ N6
- How combined ideas during interview preserve relationships in final deliverables
- Whether splitting / reconstruction operations are supported (architect picks scope)

**Coverage reconciliation (Cap #6):** Architect decides:
- The reconciliation mechanism (interactive review; mechanical check; both)
- How surfaced gaps trigger additional elicitation / research
- The "orphan ideas" detection mechanism

**Engaging onboarding shape (§7.5):** Architect decides:
- The opening framing (architect-locked default; per-project customizable)
- Multi-entry-point welcome design
- How the user is INVITED in (not "give me a list of X")

### §6.3 — Architect-investigation cross-references

Per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §7 (recommendations for downstream PS architect):
- §7.1 (Interview structure design) — OT Phase A v3 §1-§7 as structural template
- §7.2 (Deliverable template design) — OT Phase A / B.1 / C / E.1 as templates
- §7.3 (Methodology positioning) — RESEARCH §9.5 + architect explicit choices
- §7.4 (Per-feature schema design) — Cap N6 essential / extension split
- §7.5 (Two-pass architect protocol) — anticipate v1 → review → v2 iteration

---

## §7 — Completeness criteria (8-item bar; architect-can-modify-with-evidence)

The interview completeness bar (Cap #6) is the gate between "PS interview can reasonably end" and "PS interview continues." The bar is OT-evidence-based starting set; architect can modify with evidence and logic per walkthrough decision.

**8-item bar (preliminary):**

| # | Item | Source / analog |
|---|---|---|
| 1 | Vision and pillars elicited | OT Phase A v3 §1-§2; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 |
| 2 | Anti-pillars elicited with reasoning | OT Phase A v3 §3; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2 + §6.4 |
| 3 | Audience staged with explicit out-of-scope | OT Phase A v3 §4; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 |
| 4 | MVP-scope clusters identified at the M-cluster-equivalent level | OT Phase A v3 §5; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 |
| 5 | NFRs elicited | OT Phase A v3 §6; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 |
| 6 | Architectural seams MVP commits to identified | OT Phase A v3 §7; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.7 + §6.4 |
| 7 | Conditional-inclusion items captured with explicit triggers (no "we'll see") | OT Phase A v3 §5 table; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §3.2 + §6.4 |
| **8** | **Priorities elicited (multi-axis per Goal 17)** — product/market fit; competitive necessity vs competitive advantage; technical constraints; resource constraints (time/money/team-size/expertise); scope decisions (MVP vs Phase 2 vs Phase N; in/out/conditional); cost/speed/quality/feature-sets/user-journeys; user-named axes | Walkthrough refinement 2026-05-24; Goal 17 (INTAKE §9.3) |

**Architect-modification rule:** Architect can modify the 8-item bar (additions, removals, refinements) BUT must defend changes with evidence and logic per walkthrough decision. The 8-item set is NOT a hard contract — it is OT-evidence-grounded preliminary signal.

**Item 8 (Priorities) is non-negotiable as a category** (Goal 17 is a locked first-class cross-cutting driver per INTAKE §9.3); the exact axis list within Item 8 is architect-modifiable with evidence (Goal 17 lists multi-axis; user-named axes are supported).

**Completeness check mechanism:** Architect decides — user-confirmation; mechanical check; both. The mechanism feeds Cap #6 SC6.1.

---

## §8 — Audience priority + human-readable rendering

### §8.1 — Pack-primary canonical (Goal 7)

PS deliverables are PACK-PRIMARY canonical (Goal 7). The pack is the audience; deliverables are constrained by pack-integration knowledge; pack-primary deliverables are the source-of-truth.

**Pack-primary canonical deliverables:** Caps N4 (narrative PRD) + N5 (structured journey docs) + N6 (structured feature inventory + mapping) + architect-defined additional shapes.

**Audience-priority is unambiguous:** Pack-primary is FIRST. Human-readable rendering is SECONDARY. Pack-primary deliverables are NEVER demoted to make human-readable rendering "the real PRD."

### §8.2 — Human-readable rendering (Goal 19 + Cap N8)

PS produces a complementary human-readable PRD rendering via Cap N8 (Goal 19). This rendering is:

- **SECONDARY** to pack-primary canonical
- **DERIVED** from pack-primary sources (N4 + N5 + N6 + any architect-defined cross-PS-doc source set)
- **NOT pack-ingested** — secondary artifact for visual verification only
- **Architect-decided** in mechanism (skill / sub-agent / external tool / pack-adjacent script), output format (markdown / HTML / PDF / other), section structure, trigger semantics

### §8.3 — Not either-or; both can exist

Pack-primary and human-readable can coexist:
- Pack-primary serves pack workflows (groupings #7 from-external ingest; feature → BD → commit traceability; mechanical audits)
- Human-readable serves the user (visual verification of PS-captured content; review accuracy; build user trust in PS feature)

Both are PS outputs. Priority between them is unambiguous (pack-primary first); the existence of one does not negate the other.

### §8.4 — Failure mode addressed by N8

Without human-readable rendering, users reviewing PS output get docs aimed at the config pack:
- Cannot visually verify accuracy of PS-captured content
- Frustration leads to abandonment of PS feature entirely
- PS becomes a black-box producing pack-targeted content the user cannot easily review

Cap N8 addresses this failure mode by providing a human-targeted PRD rendering for visual verification.

### §8.5 — Per-deliverable audience-primary classification (architect-decided per Cap #17)

Architect decides per-deliverable audience-primary classification:
- N4 narrative PRD: human-readable? pack-primary? dual?
- N5 structured journey docs: pack-primary (structured); audience for human review architect-decides
- N6 structured feature inventory: pack-primary (machine-parseable); human review via Cap N8 rendering
- N8 human-readable rendering: human-primary (by definition)

The classification table is part of Cap #17 SC17.5 (per-deliverable audience-primary classification documented).

---

## §9 — Wave 3 boundary

### §9.1 — Wave 3 OUT OF SCOPE statement

Wave 3 (autonomous agentic PM) is OUT OF SCOPE for PS. This is a locked user-stated constraint (Goal 13; §3.6 C6; BD-191 SC9; RESEARCH §9.4).

**Wave 3 examples (NOT PS):**
- PS agent autonomously runs the product roadmap (no human in the loop)
- PS agent automatically interviews users without a human-PM-driven invocation
- PS agent makes PM judgment decisions independently (prioritization; scope cut; methodology selection)
- PS agent autonomously updates product strategy based on monitored metrics

**Wave 2 (PS scope):**
- Content-gen in PM workflows (scaffolds; facilitates; audits; renders)
- AI-assisted interview structuring (architect designs structure; LLM helps elicit + synthesize)
- Methodology defaults shipped with override path (architect picks position; user can override)
- Cross-references to pack primitives (mechanical; reference-only)

### §9.2 — Structural enforcement via PM-Chat mediation (Goal 14)

Per Goal 14 (architecture: PM Chat interviews; agent does heads-down doc work; agents do NOT interview users):
- PM Chat is the user-facing interview surface
- Agent (architect-decided shape per Cap #1) does heads-down doc authoring
- Agents do NOT interview users (locked pack pattern; Goal 14)

This boundary IS the structural enforcement against Wave 3 vapor. An autonomous PS agent that interviewed users would violate Goal 14. PM-Chat-mediation is the architecture lock that prevents the violation.

### §9.3 — Minimal validation surface (Cap #17 SC17.3 + SC17.4)

PS-produced docs are user-facing reference material — NOT pack-validated entry types like backlog / phase. Validation surface is MINIMAL.

**Per-deliverable validation specifics architect-decided:** Architect picks validation mechanism per deliverable type — validate-pack extensions; sub-agent audit; skill-based check; none. Minimum bar is the audit-pass per Cap N2 (mechanical where possible; user-judgment items flagged).

**HIGH bar consideration:** Architect cannot expand PS validation surface to cover pack-validated entry types (Goal 18 boundary). PS-side audits validate PS deliverables; pack-side validations validate pack entry-types. The boundary is preserved.

### §9.4 — Pack adds value above "paste into Claude" baseline (Goal 13)

PS must demonstrate visible value above the user baseline of "I'll just paste my PRD into Claude." The pack's value-add is:
- Project-context awareness (PS knows the pack architecture; the developer's project state; the pack workflows)
- Integration (PS deliverables feed groupings via #7 from-external ingest; cross-reference pack primitives; thread PRD-to-code traceability)
- Methodology positioning (defensible defaults per RESEARCH §9.5; per-project override path; methodology-as-explicit-position differentiator)

Architect investigates "visible value above baseline" as part of PS design pass (RESEARCH §9.4).

---

## §10 — Open architect decisions (consolidated)

This section consolidates EVERY architect-decided point surfaced across all capabilities into one numbered list. Each entry cross-references where it surfaced. Architect uses this list as a working checklist of design decisions to lock during the PS architect pass.

**Status:** PRELIMINARY per pack memory `feedback_preliminary_triage_architect_challenge`. Architect may identify additional decisions during deeper investigation; the list is starting set, not exhaustive.

1. **Agent / skill / hybrid topology (Cap #1 SC1.1, SC1.2; Goal 14)** — Architect picks the PS agent vs skill vs hybrid shape; preserves PM-Chat-interviews / agent-writes boundary; sub-agent split (per-deliverable or per-stage) architect-decided.

2. **CLIENT-SIDE-ONLY structural enforcement (Cap #1 SC1.3; Goal 1; §3.1 C1)** — Architect picks mechanism by which PS verbs / skills are structurally prevented from invoking pack-self workflows (file location; verb naming; check; etc.).

3. **PS deliverable directory structure (Cap N1; pack memory `feedback_pattern_matching_out_of_context_antipattern`)** — Architect investigates per-stream-tree contract fit AND alternative structures; locks rationale based on PS-specific properties (NOT pattern-match from adjacent pack mechanism).

4. **Per-stream-tree contract adoption (Cap N1 SC N1.4; if architect chooses this path)** — If per-stream-tree adopted, architect must satisfy `_rules.md` per-stream rules without modifying the locked pack mechanism contract (HIGH bar).

5. **Mode-2 ingest input-format strategy (Cap #2 SC2.4)** — Architect picks how Mode-2 robust-to-varied-input-formats works (markdown / notion-export / Word doc / etc.).

6. **Invocation trigger heuristics (Cap #3 SC3.2)** — Architect picks the heuristics for "milestone trigger" (explicit version-release detection; implicit "feature work nearing end of planned scope" detection).

7. **Interview structural sections + ordering (Cap #4 SC4.1, SC4.2)** — Architect picks the exact named sections; section ordering OR orderless model; per-section problem/goal/SC framing.

8. **Interview flow-dynamics mechanism (Cap #4 SC4.4, SC4.5; §6.2 + §7.5)** — Architect picks how non-linear entry points are supported; strategic ↔ tactical bidirectional capture; relationship retention; coverage reconciliation; engaging onboarding shape.

9. **Methodology defaults locking + override mechanism (Cap #5 SC5.1, SC5.2; Goal 11; §3.5 C5)** — Architect locks defaults per RESEARCH §9.5 (or alternative with rationale); picks per-project override mechanism.

10. **Persona-vs-JTBD position lock (Cap #5 SC5.4; RESEARCH §9.5)** — Architect picks position (JTBD-Christensen per RESEARCH §9.5 trend, OR persona per OT precedent, OR alternative with rationale).

11. **Completeness bar modification (Cap #6 SC6.3)** — Architect may modify the 8-item bar with evidence + logic; lists modifications + rationale.

12. **Completeness check mechanism (Cap #6 SC6.1)** — Architect picks user-confirmation / mechanical check / both.

13. **PRD template section structure (Cap N3 SC N3.1)** — Architect locks the structural sections (Pillars / Anti-pillars / Conditional-inclusions / Architectural commitments / Seams) + enforcement (documented rule / audit-check / mechanical).

14. **N4 PRD section ordering (Cap N4 SC N4.4)** — Architect picks ordering (OT Phase E.1 evidence OR alternative with rationale).

15. **N5 journey mode-classification scheme (Cap N5 SC N5.5)** — Architect picks mode scheme for pack-target audience (NOT OT-specific Building/Discovery/Recovery/Setup).

16. **N6 feature inventory schema fields (Cap N6 SC N6.1, SC N6.2, SC N6.3)** — Architect picks format (YAML / JSON / TOML / etc.); essential fields list; extension fields mechanism (per-project `_rules.md` or equivalent).

17. **Research orchestration shape (Cap #11 SC11.1; PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3)** — Architect picks shape (split into initial-discovery + per-feature; single capability with internal sub-decomposition; sub-agent vs skill vs hybrid). Explicit don't-prescribe gives architect maximum freedom.

18. **Audit invocation mechanism (Cap N2 SC N2.2)** — Architect picks sub-agent / skill / validate-pack extension.

19. **N8 human-readable rendering mechanism + format + trigger semantics (Cap N8 SC N8.1, SC N8.2, SC N8.5; Goal 19)** — Architect picks rendering mechanism (skill / sub-agent / external tool / pack-adjacent script); output format (markdown / HTML / PDF / other); trigger semantics (on-demand vs auto-generate on milestone); section structure; how structured content (feature inventory rows) is rendered (prose / tables / both).

20. **Audience-aware deliverable shape locking (Cap #12 SC12.1, SC12.2, SC12.3)** — Architect locks the audience-aware design per deliverable; reconciles pack-data-structure-knowledge (HIGH bar) and methodology-defaults-knowledge (LOW bar).

21. **Cross-feature integration discovery with groupings architect (Cap #13 SC13.4, SC13.5)** — Architect investigates whether HANDOFF-V11.1-ARCHITECT.md needs PS-awareness amendment; coordinates with groupings architect; surfaces proposed amendments (does NOT modify groupings architecture out of scope — HIGH bar).

22. **PRD-to-code traceability update mechanism (Cap #14 SC14.2, SC14.3)** — Architect picks how cross-references update when pack-side primitives are created (manual / verb-driven / automated); picks cross-direction (PS-references-pack only OR bidirectional).

23. **Workflow + doc integration unnamed-point survey (Cap #15 SC15.1)** — Architect surveys ALL pack docs/scripts/workflows for integration points; surfaces all of them (not just the named subset: METHODOLOGY.md / PM-CHAT.md / Trinity / OPTIONAL-FEATURES.md / agent + skill files / HELP-FRAGMENT-TRACKER / QUICKSTART.md / `scripts/init-project.sh`); proposes amendments through Pack Chat with user approval for any locked-doc changes.

24. **Existing-project-adopting-pack workflow (Cap #15 SC15.3)** — Architect documents PS Mode-2 path for existing-project adoption (reads existing product docs; identifies pack-integration gaps; interview to fill).

25. **PRD lifecycle edit mechanism (Cap #16 SC16.1)** — Architect picks edit mechanism (direct edit / verb-driven / both).

26. **Scope-addition addenda shape (Cap #16 SC16.2)** — Architect picks shape consistent with N1 directory structure.

27. **Wave 3 boundary line specifics (Cap #17 SC17.2; §9.1)** — Architect picks the specific lines — what does PS scaffold vs facilitate vs audit vs render vs decide? Lines distinguish Wave 2 (PS) from Wave 3 (OUT).

28. **Validation surface specifics per deliverable (Cap #17 SC17.3, SC17.4; §9.3)** — Architect picks validation mechanism per deliverable type (validate-pack extensions; sub-agent audit; skill-based check; none).

29. **Per-deliverable audience-primary classification (Cap #17 SC17.5; §8.5)** — Architect documents per-deliverable classification (human-primary / pack-primary / dual).

30. **PS-architect post-design HANDOFF-PS-ARCHITECT.md authoring (BD-191 File/Symbol)** — Pack Chat (with user approval) authors HANDOFF-PS-ARCHITECT.md after this BD's REQUIREMENTS-PS-V11.md lands and user reviews; architect may rename with version anchor at write time once scheduling is settled.

**Architect-investigation cross-reference:** PLANNING-PROCESS-INSIGHTS-FROM-OT.md §8.2 lists 7 OT-derived challenge questions for the v11.x+ PS architect; this §10 list incorporates them (especially Q1 / Q2 / Q3 / Q4 / Q5 / Q6 / Q7 — agent topology, feature schema, no-solutions grep regex, work-item-level boundary, PS-to-groupings protocol, audit mechanism, completeness detection) and expands per the walkthrough refinements.

---

## §11 — Forward pointer / next steps

### §11.1 — Architect entry point

The v11.x+ PS architect reads `REQUIREMENTS-PS-V11.md` (this doc) as PRIMARY INPUT. Reading order:

1. **REQUIREMENTS-PS-V11.md (this doc)** — formal requirements distillation; per-capability problem / goals / SC / disposition / scope / rationale / cross-references / architect-bar
2. **INTAKE-PS-V11.md** — verbatim user-intent audit trail (consulted for verbatim quotes; relationship retention across deliverables; §7 + §7.5 quality-mitigation + flow-dynamics intuition; §9 19 goals full statements)
3. **RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md** — landscape facts (consulted for §9 pack-relevance observations; §9.5 defensible methodology positions; sources + dates)
4. **PLANNING-PROCESS-INSIGHTS-FROM-OT.md** — OT-pattern synthesis (consulted for §3 transferable patterns; §4 failure modes; §7 architect investigation areas; §8 challenge questions)
5. **REQUIREMENTS-GROUPINGS-V11.md** — companion v11.1+ feature (consulted for Capability #7 from-external ingest details; §5 cross-feature integration)
6. **HANDOFF-V11.1-ARCHITECT.md** — groupings architect handoff (consulted for cross-feature context; may receive PS-awareness amendment during PS architect's work)

### §11.2 — Forthcoming HANDOFF-PS-ARCHITECT.md

Per BD-191 File/Symbol, a forthcoming `HANDOFF-PS-ARCHITECT.md` (Pack Chat authors after this BD's requirements doc lands and user reviews) is the v11.x+ PS architect's direct entry point. Architect may rename with a version anchor (e.g., `HANDOFF-V11.1-PS-ARCHITECT.md` or `HANDOFF-V11.2-PS-ARCHITECT.md`) at write time once scheduling is settled.

### §11.3 — Downstream BDs

Downstream BD-NNNs open as the architect identifies implementation phases. Examples (preliminary; architect decides actual phasing):

- BD-NNN — PS architecture design (architect produces ARCHITECTURE-PS-V11.x.md; locks all 30 open architect decisions in §10; reads REQUIREMENTS-PS-V11.md as primary input)
- BD-NNN — PS implementation plan (planner produces PLAN-PS-V11.x.md; sequences architect-locked decisions into commits)
- BD-NNN(...) — PS implementation phases per planner sequencing (coders implement; reviewers review per pack patterns)
- Cross-feature BD-NNN — coordination with groupings architect if HANDOFF-V11.1-ARCHITECT.md amendment surfaces

### §11.4 — Architect-challenge discipline reminder

Per pack memory `feedback_preliminary_triage_architect_challenge`:

- Every disposition + scope verdict + capability shape + open architect decision in this doc is **PRELIMINARY**
- Architect WILL challenge each preliminary position based on detailed tactical information
- User retains final authority over architect challenges (per pack memory `feedback_user_prescriptive_authority`)
- Tiered challenge bar: LOW (PS-internal) vs HIGH (boundary-with-existing-pack)
- Architect may enhance, accept, reject, or replace any preliminary position based on evidence and logic

The architect-challenge discipline applies to this ENTIRE doc — not just per-capability dispositions.

### §11.5 — BD-191 close-out

After this REQUIREMENTS-PS-V11.md lands and user reviews + approves, BD-191 closes (Status flip to Resolved). Pack Chat then:
- Authors HANDOFF-PS-ARCHITECT.md (with user approval)
- Updates HANDOFF-V11.1-ARCHITECT.md PS-awareness amendment if surfaced during this BD's work (Pack Chat / groupings team writes; PS architect surfaces)
- Opens downstream BDs as architect identifies implementation phases (via standard Pack Chat triage)

---

End of REQUIREMENTS-PS-V11.md.
