# INTAKE-PS-V11.md

**Purpose:** Captures the user-intent discussion that led to BD-191 open. Verbatim user messages preserved where available; my (Pack Chat) responses summarized to focus on the user-intent capture. Serves as the audit-trail anchor for downstream architect / planner work on the Product Specialist (PS) v11.1+ feature.

**Date authored:** 2026-05-24 (sidecar session "v11-dev-sidecar").
**Fidelity:** **High-fidelity verbatim** for user messages (recent chat history; ~10 user messages preserved). Pack Chat responses paraphrased / summarized.
**Companion docs:**
- `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (PS landscape research; committed 2026-05-24 in `17682c7`)
- `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (research methodology)
- (Forthcoming) `maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md` — distillation of this intake + research into formal requirements

**Editorial note (added 2026-05-24, post-renumbering):** Throughout this doc, the canonical BD reference for the Product Specialist feature is **BD-191**. Some verbatim user quotes preserved below reference "BD-191" — that was the working assumption during the original discussion. Main chat's parallel work claimed BD-191 first (audit-vocabulary-gap sweep; Batch 19c); PS work renumbered to BD-191 per pack memory `reference_pack_backlog_structure` BD-NNN numbering rule ("always read the live BACKLOG before assigning"). Renumbering applied to Pack Chat's prose; verbatim user quotes preserved as-is for audit fidelity. Already-committed commit messages referencing "BD-191" or "Pre-BD-191" (`17682c7`, `df64afc`, `a6423c3`) are historical record and not rewritten.

---

## §1 — User's initial PS feature framing (verbatim)

User-issued 2026-05-24 in the v11-dev-sidecar session:

> One of the gaps in the pack is truly optional but can help a lot. This is for client project facing work ONLY. Not pack self-work. That boundary must be clear and respected. Here is the general ask: I would like a Product Manager agent with associated skills or at least a Product Manager skill that the PM chat can use. I don't know what the right shape is so that is part of this process.
>
> How it could affect the config pack project area:
>
> 1. If there is a new agent, it would have to be added in all the right dirs and all the documents that refer to agents and workflows need to be updated so that the PM chat knows about it and calls it correctly.
> 2. If it is only a skill, the PM chat would do the work using the skill, but there would still be doc changes so workflows and processes are clear.
> 3. It may be a hybrid where the PM chat does some of the work (such as Q&A) with a specialized skill or doc with rules AND an agent with special skills does more heads down work for writing PRDs and other docs.
> 4. Essentially, I want the Product Manager to do the following:
>
>    a) Interview the user/devloper to understand what the product is, what the scope is, key features, shape of MVP or v1 of the product, shape of future versions or full versions. The user would also indicate what their priorities are across various areas, like cost, speed, quality, feature sets, user journeys, or anything.
>
>    b) It would spawn the doc-researcher agent to do external research for areas that are unclear or need confirmation, such as: competitive analysis (product and market fit), availability of tools and components that would aid, enhance, or accelerate development, or any other research relevant to the product
>
>    c) It would be able to write a full PRD with a clear line for what the MVP looks like, or just the MVP PRD
>
>    d) It would be able to write the docs, or include supporting docs, in a way that is compatible with how the config pack clients need to translate the work into a plan that the config pack needs: user journeys, ambient or shared feature groups, foundational groupings, or others.
>
>    e) This would inlclude mapping docs that include references that enable mappings from work items and features to tasks, phases, and groupings. This would also include a proper structure that the config pack already recognizes even if not all the fields are knows at the start.
>
>    f) While the inputs are varied and unstructured, they can be used to create well organized product docs (PRDs, technical requirements, product research) which can then be further honed into structured docs the pack can turn into executable plans that meet the developer's vision.
>
>    g) All of this must integrate smoothly into the pack. It should also be somethingt that doesn't have a heavy footprint during implementation since it will be needed mostly in the beginning and then episodically as the product evolves over its lifecycle. That is, there will be a big prodcuct planning effort in the beginning with spikes over time, but not consistently.
>
> Tell me what you think of this first. Then ask me questions so we can discus how to make a plan to make a detailed plan for this work. The goal here is NOT to build this feature. Like groupings, we need to create the support docs and even an execution plan (and a BD entry) so that a different session can execute it at the right time. We won't know yet, but ideally there will be no impact on the grouping planning we just did. It will just integrate smoothly becuase integration points have been planned properly. However, if we find that is not the case, as we go along, we can propose modifcations to the groupings work to make integration more elegant. Neither of these has been truly designed and implemented yet, so now is the time to make changes if it makes things better. They are not fully locked.

### Key intent extracted

- **CLIENT-SIDE ONLY** boundary explicitly stated; pack-self excluded
- Shape (agent / skill / hybrid) is TBD — part of the planning process
- Episodic-usage pattern: heavy at start, spikes during evolution, idle otherwise
- "Plan for a plan" mode: not building the feature; producing inputs for a future session to execute
- Cross-feature awareness with groupings is expected; integration points should be planned

---

## §2 — Q&A intake

### Pack Chat initial response (summarized)

Pack Chat's response to the framing:

- Acknowledged the feature direction
- Surfaced cross-feature integration with groupings (zero forced amendments to BD-186 artifact)
- Listed 10 questions in 5 tiers:
  - **Tier 1 (Scope):** Q1 naming, Q2 trigger/when invoked, Q3 optional-vs-default
  - **Tier 2 (Output set):** Q4 canonical output docs, Q5 mapping doc shape
  - **Tier 3 (Integration with groupings):** Q6 PM output → grouping creation, Q7 existing PRD ingest
  - **Tier 4 (Workflow):** Q8 PM agent vs PM chat orchestration, Q9 persistence/evolution
  - **Tier 5 (Pack scope):** Q10 implementation footprint / v11.1 vs v11.2

### User's verbatim Q1-Q10 answers

User-issued 2026-05-24 in response to the 10 questions:

#### Q1 — Naming

> This is tough. The industry calls this role PM for Product Manager. The config pack uses PM for Project (or Program) manager. The right thing to do would be to rename the existing PM in the config pack to TPM for Technical Project (or Program) Manager. This would affect doc file names, references in docs to other doc files, references to the PM Chat as an entity (into TPM Chat), memories, and potentially more. Is this worth it? Probably. Is there a more elegant solution where the PM designation in use today isn't changed but we can still use product-manager too? Possibly. We need to talk more about this.

#### Q2 — When invoked

> All. This is project dependent. I see this as something that enhances the product feature set in an organized and intentional way rather than just randomly expanding scope as implementation is done. It should be done when implementation hits explicit (e.g. version releases) or implicit (e.g. the feature work is nearing the end of what has already been planned) milestones.

#### Q3 — Optional vs default

> It should be optional but highly recommended. The user/developer might have their own process and PRDs, so there should be a mode where the product manager can take existing docs, find gaps that the config pack needs answers to in order to make integration smoother, and start the process there. Not just starting from scratch. Both should be supported.

#### Q4 — Canonical output docs

> The goal is to get everything necessary to make a complete, confident, and intentional integration into the config pack for design and execution to begin. So, as mentioned before, this is an effort to force the user to think through what the product does, what its competitive advantage is, what the priorities are, and what the larger milestones (e.g. MVP, full versions) are. This is not just high level executive summary. These are working docs that can be use to be broken down into groupings, like user journeys and foundational work, then into into individual features. Those can then be structured and used to be ingested into the config pack for real implementation.

#### Q5 — Mapping doc shape

> Probably free text. Ideally there is a boundary so that if the user declines to use the product manager tools, they can still create groupings the way the groupings work was expecting. There should be zero dependency of groupings on the product manager. But if the product manager work is used, it should make it much easier to make groupings. Once the groupings are ingested, the product manager docs are just references and not working docs, per se.

#### Q6 — PM agent output → grouping creation

> (a) definitely cleaner separation. BUT the product manager has the benefit of knowing how the docs will be used later so it should intentionally make that easier. If, for example, there is a preferred input format or structure that groupings can use for ingestion, that can be used, but the product manager should NEVER make GRP-NNN.md files itself. That is out of scope.

#### Q7 — Existing PRD ingest

> PM agent's first job include reading it + restructuring it into pack-compatible form but can do interviews or Q&A to fill gaps, like understand MVP shape or other priorities, or restructure in new docs as needed.

#### Q8 — Architecture (PM agent vs PM chat)

> The config pack pattern is that agents can be spawned and do heads down work because the either have all the docs needed to do the work or can do it themselves, They do not interview the user. This feels more like: PM chat does the interviewing and creates a doc for use by an agent. The agent then can take inputs from different sources (docs-researcher, PM chat interview, pre-written PRD, or other sources) and makes their own docs. The interesting thing here is that they may need several passes, one for each kind of doc: PRD, user journeys, feature list, mappings, so does each doc need its own skill or is this more like the auditor agent that can spawn multiple different specialized auditor sub-agents. In this case would a general product-manager agent spawn specialized product-manager-doc sub-agents? An architect should decide. Not us.

#### Q9 — Persistence

> Keep it simple. If there are edits, the PRD can be edited. If there is additional scope, new addendum or follow-on docs can be added. This work can be tracked as phases or backlog entries since one is pre-schedules and the other (backlog) is not, in the project's world.

#### Q10 — Implementation footprint / sequencing

> I think it's important for each feature (groupings and product manager) to know about the other to a certain extent, but that may just be in a planning phase like this. If planned correctly, the groupings work, done first, will anticipate the product manager work that comes later making integration easier. Whether the product manager work is v11.1 or v11.2 is not important. You point that the work should be isolated is. And I agree with that. First groupings (informed by knowing about the later work) and then product manager.

### Pack Chat's clarification ask (closing the Q1 thread)

After absorbing Q1-Q10, Pack Chat surfaced the naming question (Q1) as the load-bearing decision to settle before any artifact files were named. Three concrete options were presented:

- **Option A:** Full TPM rename of the existing project-manager surface (substantial cost: ~200-500 references across BACKLOG / METHODOLOGY / trinity / memory files / skill renames)
- **Option B:** Keep PM-CHAT.md filenames; use distinct FULL NAMES with prose discipline (lowest cost; documentation discipline forever)
- **Option C:** Hybrid — preserve existing filenames; introduce "Product Manager" as canonical full name; AVOID "PM" alone in NEW content; existing references stay until natural revision

Pack Chat's recommended: **Option C.**

---

## §3 — Naming decision (verbatim)

User-issued 2026-05-24 in response to the three options:

> (i) For the naming question (Q1), I propose an option D: Add a prefix: Lead Product Manager (LPM), or even cleaner, Product Specialist (PS). The latter is both tighter and a much better separation. I'm not sure. What do you think? Also, I would like to add a preliminary pack-docs-researcher pass to search for GitHub repos, blogs, articles, professional products (free or paid) that do this (or at least the product design component). I want to cast a wide net but have a high standard for things that are proven, widely acknowledged as high quality, or highly recommended. This will provide valuable insight into how this can be done and what it should contain, with the understanding that pack integration as a first class goal is a nuance that other products can't easily provide. This is both competitive analysis, feature identification, methods and processes, and should contain full links and citations as well as clear logical reasoning and evidence. This can come before or after 2, drafting BD-190, in your list and may actually change the list once we have the data.

### Pack Chat's recommendation (summarized)

Pack Chat recommended **Product Specialist (PS) over Lead Product Manager (LPM):**

- Zero collision with "PM" abbreviation (vs LPM which still reads PM-flavored)
- Semantic fit: "Specialist" matches episodic-expertise pattern better than "Lead Manager" (ongoing senior role connotation)
- Clean conceptual distinction from project manager (different role families: "Specialist" vs "Manager")
- Future readability of pack docs (PS and PM unmistakable; LPM and PM cognitively close)

### User confirmation (verbatim)

User-issued 2026-05-24:

> Product Specialist (PS) confirmed. Research spawn confirmed.

**Naming decision LOCKED: Product Specialist (PS).**

---

## §4 — Research scope + approval

### Pack Chat's proposed research scope (summarized)

Pack Chat proposed a comprehensive landscape research pass commissioned via pack-docs-researcher in background. Scope covered 7 categories:

1. Open-source PM / product-discovery tools (GitHub repos)
2. Professional products (paid + free) — Productboard, ProductPlan, Aha!, Roadmunk, Notion templates, Coda, Linear product features, Asana, Figma, ClickUp, monday.com
3. Methodologies + frameworks (JTBD, RICE, Story Mapping, Impact Mapping, Lean Canvas, BMC, OST, OKRs, Continuous Discovery, North Star, etc.)
4. PRD templates + structures (5+ canonical templates; universal vs optional vs controversial sections)
5. Interview / customer-discovery frameworks (Mom Test, Steve Blank's customer development, JTBD interviewing)
6. AI/LLM-assisted product tooling (state of the art 2025-2026)
7. Dev-tool integration patterns (Jira / GH / Linear product workflow integration)

Quality filter: wide net for discovery, high standard for inclusion. Primary-source citations throughout. Publication / last-updated dates where available.

### User research approval (verbatim)

User-issued 2026-05-24 (combined with naming decision above):

> Product Specialist (PS) confirmed. Research spawn confirmed.

### Research execution

Pack Chat spawned pack-docs-researcher in background (agent UUID: `a5671860f1770cb5f`). Research completed ~13 minutes later with two output files:

- `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (985 lines; 7 categories + cross-cat synthesis + pack-relevance + sources)
- `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (183 lines; methodology + sources + open questions + SC mapping)

Both committed pack-only at `17682c7` on 2026-05-24.

---

## §5 — Research output headlines (key §9 findings surfaced to user)

Pack Chat surfaced the §9 (Pack-relevance observations) findings to the user, since §9 is the most direct input to PS feature requirements gathering:

### §9.1 — Hard things to be careful of

- AI-generated PRDs are mostly mediocre; value comes from team conversation, not artifact quality. PRD generators without facilitation produce decorative docs.
- AI-generated personas without research grounding are doubly suspect.
- AI picking methodology is muddled (orthodoxy splits: Ulwick vs Christensen JTBD; persona vs JTBD; user-stories vs Linear-Method issues).
- AI can scaffold interviews but cannot replace them (Mom Test + Continuous Discovery emphasize human listening).
- Two-way tracker sync from a CLI tool sets a high integration bar.

### §9.2 — Underserved gaps (pack opportunity)

- Solo / micro-team product thinking is under-served by commercial PM tools — exactly the pack's audience.
- PRD-to-code traceability is thin in commercial tools; pack has BD/phase/grouping/IMPL-REPORT primitives that could thread it.
- Methodology-as-explicit-position — commercial tools are methodology-neutral; pack can take opinionated stances.
- Conversation scaffolding > artifact generation — pack's CLI-agent shape suits this.
- Discovery-output integration with existing pack primitives — OST opportunities → backlog phases; assumption tests → BD entries.

### §9.3 — Familiar patterns to adopt

8 common-denominator PRD sections; Goals + Non-Goals paired; hypothesis-driven framing; outcomes-over-outputs vocabulary; Mom Test interview discipline; multiple roadmap views; integration with existing backlog/tracker.

### §9.4 — LLM-PM tooling boundary

- Wave 2 (content gen in PM workflows): genuinely useful; pack can credibly operate here
- Wave 3 (autonomous agentic PM): largely vapor; high-cost / low-credibility
- Competition: "I'll just paste this into Claude" — pack must show visible value above that baseline

### §9.5 — Defensible methodology positions

| Area | Default the landscape supports |
|---|---|
| Discovery framework | Continuous Discovery (Torres) / Opportunity-Solution Tree |
| Hypothesis articulation | Lean Canvas (one-page) or PR/FAQ (narrative) |
| Prioritization | RICE or Value/Effort (default); Kano (delight) |
| Interview style | Mom Test + past-behavior focus |
| PRD shape | Common-denominator sections |
| Outcomes | North Star + OKRs |
| Persona vs JTBD | Pick ONE; JTBD-Christensen is the trend |
| Vocabulary | Cagan (problems-to-solve, outcomes-over-outputs) |

### User reaction to research (verbatim)

User-issued 2026-05-24 after seeing the research headlines:

> proceed

Acknowledged commit of research deliverables and authorization to proceed to BD-191 drafting.

---

## §6 — BD-191 entry approval ask + this intake doc creation

Pack Chat surfaced BD-191 entry draft text on 2026-05-24, structured to mirror BD-186 (the groupings requirements-gathering BD) with:

- Type: feat — surfaced 2026-05-24 from sidecar Pack Chat session
- Status: Open
- Blockers: None — independent of v11.0 work
- Cross-feature relationship with groupings (BD-186 / BD-189) — ZERO hard dependency
- 8 Success Criteria covering capability triage / pack-relevance observation incorporation / cross-feature integration
- Pipeline: Pack Chat sidecar → REQUIREMENTS-PS-V11.md → user review → BD-191 Resolved → downstream cycles

### User intake-doc gap question (verbatim)

User-issued 2026-05-24 before approving the BD-191 entry:

> Before I approve, tell me: What doc is all the discussion and Q&A about the PS that we have done so fare captured. I I don't see it in the BD-190 text. Where is it and is it referenced in the BD-190 text?

### Pack Chat's honest answer

Pack Chat acknowledged the gap: the Q&A discussion was NOT captured in any doc; existed only in chat history. The BD-186 work had the same gap (distilled into REQUIREMENTS-GROUPINGS-V11.md §1 and §2 but full discussion not preserved as a separate doc). Pack Chat proposed creating INTAKE-PS-V11.md (this doc) before BD-191 opens, and offered to retroactively create INTAKE-GROUPINGS-V11.md for BD-186.

### User decision (verbatim)

User-issued 2026-05-24:

> faithful summary works, both in parallel. I'll review the doc after and tell you if it needs changes. Since there are other docs that were created and are noted in BD-186, my only concern is really just conflicts, not gaps. Proceed.

Pack Chat created both intake docs in parallel. This doc captures the BD-191 (PS) intake at high-fidelity verbatim; INTAKE-GROUPINGS-V11.md captures the BD-186 (groupings) intake at faithful-summary fidelity.

---

## §7 — Quality-mitigation intuition + tactical guiding principles (user-stated 2026-05-24; needs investigation during BD-191 triage)

**Context:** During the BD-191 entry approval ask, user surfaced an intuition about quality mitigation for the PS feature. Captured here near-verbatim for downstream investigation. **NOT a locked decision — flagged for investigation during BD-191 capability triage.** The eventual `REQUIREMENTS-PS-V11.md` will distill investigation outcomes into formal design principles + constraints.

The intuition directly addresses two §9.1 quality-pitfall findings from `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md`:
- "AI-generated PRDs without facilitation = decorative artifacts"
- "AI picking methodology = muddled (orthodoxy splits real)"

### User-stated quote (verbatim 2026-05-24)

> Before I approve, you mentioned that a major issue for tools with agents in this space was the low quality. We don't need to litigate that here, but I think that there are two clear areas that could help improve quality and mitigate this issue. This is just intuition, so I'm not certain: a) The interview process needs clear problems to solve, goals, and success criteria that are related to both product definition goals, but also smooth integration into the config pack. My sense is that bad PRDs are usually produced because people don't really know what they want and the AI doesn't either. But the AI has to write something and make it look official. The interview process can highlight where there are gaps in the content needed to provide real structure, even if the gaps are market research, idiation, or creativity related. This is why the inclusion of market and competitive analysis is important. Other reasons, even if the product idea is complete, might be that the scope isn't well defined and constrained to something buildable and deliverable give resource constraints and priorities. So knowing priorities, resource constraints, and other scope related information should be part of the interview. The interview can't just be a random walk of questions, rather it must have clear sections that need answers. If a preliminary PRD is provided and doesn't provide all the scope and strucure, the interview can help fill in the gaps. And b) the interview process, in this structure, must be well informed by the fact that it needs to create deliverables, docs that touch various areas and some that even have specific structures, that can integrate smoothly with the workflows, docs, scripts, and tools (even tracker) that the config pack uses. This could narrow and specify the scope considerably. Other product manager tools are probably open ended since the creators of those tool may not know how and where the output will be used and who its audience is. We do.
>
> This is just my intuition, bit this needs to be captured, probably in a new or existing section of `INTAKE-PS-V11.md` or somewhere else. I want it captured so it isn't forgotten (not just in a memory file, but in a real doc), but I also want the idea that this needs to be investigated further is also included. Either way, defining real tactical (not just high level strategic) guiding principles and deliverable requirements will help structure what the interview needs to consist of and what "complete" means when it's done.

### §7.1 — Intuition (a): Interview structure

The interview process MUST NOT be a random walk of questions. It must have:

- **Clear problems / goals / success criteria** tied to BOTH:
  - Product definition goals (what the product does, scope, MVP shape, differentiation)
  - Smooth integration into the config pack (downstream pack workflow compatibility)
- **Structured sections that need answers** — not free-form chat
- **Gap identification across categories** when content is incomplete:
  - Market research / competitive analysis (relevant to docs-researcher invocation)
  - Ideation (when product idea is incomplete)
  - Creativity (when scope needs broadening or pivoting)
  - Scope definition + constraints (what's buildable given resources)
  - Priorities (cost / speed / quality / feature sets / user journeys; user-named in framing message §1)
  - Resource constraints
- **Mode-1 (from-scratch) and Mode-2 (existing-PRD-ingest) use the SAME structured approach** to surface gaps; Mode 2 reads existing PRD and identifies which sections lack required content. The structure is the audit, regardless of where input comes from.

User reasoning quoted verbatim above: "bad PRDs are usually produced because people don't really know what they want and the AI doesn't either. But the AI has to write something and make it look official. The interview process can highlight where there are gaps in the content needed to provide real structure."

### §7.2 — Intuition (b): Audience-aware deliverables

The PS deliverables must be informed by knowing the audience — which is the pack itself (workflows, docs, scripts, tracker, groupings, phases, tasks, backlog entries, etc.). Unlike other PM tools where the audience is unknown:

- PS scope is **NARROWED** by knowing the downstream audience
- Deliverable shapes are **MORE SPECIFIC** because integration targets are known
- Interview content is **CONSTRAINED** by what the pack needs to ingest
- This is a **competitive advantage** the pack has over open-ended PM tools

User reasoning quoted verbatim above: "Other product manager tools are probably open ended since the creators of those tool may not know how and where the output will be used and who its audience is. We do."

### §7.3 — Meta-direction (what to investigate during BD-191 triage)

The user's intent: capture this intuition + investigate during triage. Not pre-decide.

Investigation targets during BD-191 triage:

1. **Define tactical (not just strategic) guiding principles** for:
   - Interview structure: the sections; the order; the gap-identification process per category; the question shapes that elicit useful answers vs. decorative ones
   - Deliverable shapes: each output doc (PRD / journey docs / feature list / mapping doc); what fields/sections are required; what's optional; how each maps to pack primitives (groupings / phases / tasks / backlog entries)
2. **Define "complete" criteria** for the interview process — when can the interview reasonably end? What's the boundary between "enough to start work" and "everything answered"?
3. **Investigate quality mitigation patterns** from §9.1 + §9.2 landscape findings:
   - Conversation-scaffolding-vs-artifact-generation balance (per §9.2 underserved gap)
   - Methodology-position selection (defensible defaults per §9.5 vs neutral; per-project override path)
   - LLM Wave 2 capability boundary vs Wave 3 vapor (per §9.4)
4. **Cross-reference** with §9.5 defensible methodology positions to ensure the interview structure aligns with industry-defensible patterns (Continuous Discovery / OST for discovery framework; Mom Test for interview style; etc.)

### §7.4 — Status

**INTUITION-STAGE ONLY.** Not locked. Investigation during BD-191 triage produces:
- Tactical guiding principles → `REQUIREMENTS-PS-V11.md` design principles section
- "Complete" criteria → `REQUIREMENTS-PS-V11.md` capability section (likely a dedicated capability for interview-completion check)
- Quality-mitigation pattern selection → `REQUIREMENTS-PS-V11.md` scope/boundary section
- Possibly: new capabilities identified during investigation (gap-identification verb, deliverable-shape templates, etc.)

If investigation surfaces that the intuition is incorrect or needs refinement, the BD-191 triage records the refinement; **this §7 stays as the ORIGINAL user intent for audit purposes** (audit-trail discipline; intake docs don't get retroactively rewritten with conclusions).

---

## §8 — Candidate capability list (Pack-Chat-drafted; awaiting architect review + user approval)

**Status:** DRAFT, surfaced 2026-05-24 prior to per-capability triage walkthrough. Captured here as audit-trail anchor for the pre-architect-review state. Awaiting:
- pack-architect review pass (`maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` — forthcoming; synthesis of OT feature-brainstorm-1 planning patterns into pack-applicable lessons)
- User review for shape (anything missing / merge / split / drop / re-cluster)
- Per-capability triage walkthrough (one at a time, default-accept mode, BD-186 pattern)

**Source materials:** §1 user framing (bullets a-g) + §2 Q1-Q10 verbatim answers + §7 quality-mitigation intuition + `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §9 (pack-relevance observations + §9.5 defensible methodology positions) + `INTAKE-GROUPINGS-V11.md` cross-feature context.

**Note on revisions:** The architect review pass MAY surface restructuring (capability merges, splits, additions, drops) based on OT planning-process patterns. If significant restructuring lands, this section is updated explicitly. Smaller adjustments handled per-capability during triage. Final locked capability set lives in `REQUIREMENTS-PS-V11.md` (downstream output of BD-191).

### Foundation (3)

1. **PS feature core shape + scope boundaries.** Agent / skill / hybrid (architect-decided per Q8); CLIENT-SIDE ONLY constraint (project-template/ surface; never pack-self per user direction 2026-05-24); optional + highly-recommended posture per Q3; install ships availability not adoption.
2. **Two operational modes.** Mode 1 from-scratch authoring (interview → write); Mode 2 existing-PRD ingest + gap-fill (read → identify pack-integration gaps → interview to fill → restructure if needed). Both modes use same structured interview approach per §7.1.
3. **Invocation model.** Episodic — project init (big planning effort) + milestone spikes (explicit: version releases; implicit: feature work nearing end of planned scope) + on-demand. Per Q2. Light footprint between spikes; no chronic overhead.

### Interview process (4)

4. **Structured interview process.** Clear sections (NOT a random walk); each section has problems/goals/SC framing; gap-identification across market research / ideation / creativity / scope definition / resource constraints / priorities / constraints. Both modes use same structure. Per §7.1.
5. **Methodology positioning.** Pack ships defensible defaults per RESEARCH §9.5 (Continuous Discovery + OST for discovery; Mom Test + past-behavior focus for interviews; Lean Canvas or PR/FAQ for hypothesis; RICE or Value/Effort for prioritization; common-denominator PRD sections; North Star + OKRs for outcomes; JTBD-Christensen for persona-vs-JTBD; Cagan vocabulary). Per-project override path supported. Methodology-as-explicit-position is a pack differentiator per §9.2.
6. **Interview "complete" criteria.** Defines when the interview can reasonably end vs continue. Boundary between "enough to start work" and "everything answered." SC10 investigation target.
7. **Quality-mitigation tactical principles.** Per §7 — (a) interview structure (per #4) + (b) audience-aware deliverables (per #12). Tactical (not just strategic) principles. Investigation per SC10 directly mitigates RESEARCH §9.1 hard-things-to-be-careful findings.

### Deliverable outputs (4)

8. **PRD authoring.** MVP-line demarcation (or MVP-only PRD); common-denominator 8 sections per RESEARCH §9.3 / §4; Goals + Non-Goals paired; outcomes-over-outputs vocabulary; hypothesis-driven framing where applicable. Per user Q4 ("not just high level executive summary; working docs").
9. **User journey doc generation.** Optional per project type (only for products with user-facing flows). Distinct from but feeds groupings of Kind `user-journey`. Per user (d) framing.
10. **Feature list + mapping doc generation.** Feature list breaks PRD into discrete user-facing capabilities. Mapping doc (free-text per Q5) bridges PS output → pack primitives (groupings / phases / tasks / backlog entries). Mapping doc is REFERENCE once groupings are ingested (Q5: "just references and not working docs, per se").
11. **Research orchestration.** Spawn `docs-researcher` for competitive analysis / market research / tool research (per user (b)). PS assembles outputs from multiple sources (interview + research + existing PRD per Q7) into coherent docs.

### Pack integration (3)

12. **Audience-aware deliverable shapes.** PS knows the pack as audience (workflows / docs / scripts / tracker / groupings / phases / tasks / backlog entries). Deliverables CONSTRAINED by pack-integration knowledge — narrower / more-specific than open-ended PM tools. Pack-differentiator per §7.2 + RESEARCH §9.2.
13. **Cross-feature integration with groupings (BD-186 / BD-189).** PS docs feed groupings via existing #7 from-external ingest workflow. ZERO hard dependency in either direction (per user Q5). PS NEVER produces `GRP-NNN.md` files directly (per user Q6 "out of scope"). HANDOFF-V11.1-ARCHITECT.md may receive PS-awareness amendment during this BD's work.
14. **PRD-to-code traceability.** Pack uniquely positioned per RESEARCH §9.2. Features → BDs → commits / PRs. PS deliverables reference pack primitives by ID. Traceability is mostly REFERENCE — pack-side primitives carry the canonical state; PS docs cite them.

### Workflow + lifecycle (2)

15. **Workflow + doc integration.** METHODOLOGY.md procedures for PS workflows (project-init invocation; milestone-trigger invocation; existing-PRD-ingest mode). PM-CHAT.md orchestration text (PM Chat does interviewing per Q8; agent does heads-down doc work). Trinity Document locations updates. OPTIONAL-FEATURES.md section. Agent / skill file updates per per-CLI parity (Check 27). Mirror of BD-186 #12 capability shape, scoped to PS.
16. **PRD lifecycle management.** Edits in place (Q9). Addenda / follow-on docs for scope additions (Q9). Major scope changes tracked as phases or backlog entries (Q9: "this work can be tracked as phases or backlog entries since one is pre-scheduled and the other (backlog) is not"). No new lifecycle states needed; pack-existing primitives carry the tracking.

### Scope boundary (1)

17. **Wave 3 vapor exclusion + minimal validation surface.** Wave 3 (autonomous agentic PM) explicitly OUT OF SCOPE per RESEARCH §9.4. PS is Wave 2 (content-gen in PM workflows) — credible territory; pack adds value above "paste into Claude" via project-context awareness + integration + methodology positioning. Validation surface MINIMAL — PS-produced docs are user-facing reference material, not pack-validated entry types like backlog/phase. Architect decides extent of any validate-pack checks for PS docs.

### Cluster summary

| Cluster | Count | Cross-cutters |
|---|---|---|
| Foundation | 3 | n/a |
| Interview process | 4 | #4 ↔ #7 (interview structure ↔ quality-mitigation); #6 cross-cuts SC10 |
| Deliverable outputs | 4 | #9 + #10 feed #13 (groupings integration) |
| Pack integration | 3 | #12 cross-cuts #4-#11 (all interview + deliverables affected by audience-awareness); #13 + #14 feed downstream pack work |
| Workflow + lifecycle | 2 | #15 references all of #4-#14 |
| Scope boundary | 1 | #17 boundary applies to all |

**17 capabilities total** — coincidentally matches BD-186's 17-capability count.

---

## §9 — Forward pointer

This intake doc serves as input to BD-191 (opened in BACKLOG.md at commit `32e78d2`; BD-191 entry text references INTAKE-PS-V11.md in INPUTS, with §7 investigation captured as SC10).

REQUIREMENTS-PS-V11.md (downstream, produced during the BD-191 sidecar triage) will distill this intake doc + research findings into formal:

- Design principles (drawn from §9 pack-relevance observations + user-stated intent in §1 + investigated §7 tactical principles)
- User-stated constraints (analogous to BD-186's C1-C7, drawn from Q1-Q10 + framing + §7 intuition outcomes)
- Capability list (informed by §1 user goals + §9.2 underserved gaps + §9.3 familiar patterns + §9.5 methodology positions + §7 interview-structure investigation)
- Per-capability disposition + scope verdict
- Cross-feature integration notes with groupings (BD-186 / BD-189)
- Interview-completion "complete" criteria (per §7.3)

The intake doc itself remains the verbatim audit-trail of user intent; the requirements doc carries the distilled, decision-locked content.

---

End of INTAKE-PS-V11.md.
