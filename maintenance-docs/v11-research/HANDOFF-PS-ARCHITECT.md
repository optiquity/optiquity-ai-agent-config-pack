# HANDOFF — v11.x+ Product Specialist (PS) architect

**Purpose:** Single-page entry-point for the future v11.x+ architect picking up the Product Specialist (PS) feature. Points you at the artifact set, frames the reading order, names what is locked vs what is yours to design, and reminds you of the discipline rules you must follow during the architect pass. Read THIS doc first; then the artifacts in the order below.

**Authored by:** Pack Chat (BD-191 sidecar wrap, 2026-05-24), per BD-191 File/Symbol forward-pointer.

**Source BD:** BD-191 — Product Specialist (PS) requirements + v11.0/v11.1+ scope decision (see `pack-ops/BACKLOG.md`).

**Audience:** The v11.x+ PS architect (you). Downstream planner / coder / reviewer consume your output, not this doc.

**Status:** PRELIMINARY across every framing in this doc. Per pack memory `feedback_preliminary_triage_architect_challenge`, every disposition / scope verdict / capability shape / open architect decision surfaced in this BD's requirements artifact is preliminary — you WILL challenge each preliminary position based on detailed tactical information. User retains final authority over architect challenges per pack memory `feedback_user_prescriptive_authority`. Tiered challenge bar applies per surface:

- **LOW** — PS-internal decisions; you explore freely and may enhance, accept, reject, or replace.
- **HIGH** — Boundary-with-existing-pack decisions (locked pack mechanisms; entry-type semantics; cross-feature contracts with groupings BD-186 / BD-189); you must investigate thoroughly and cannot arbitrarily change boundary out of scope.

---

## §1 — Purpose, audience, status

This handoff exists because `REQUIREMENTS-PS-V11.md` is 1195 lines. You should not land on it cold. Read this doc to anchor the discipline framing, locked constraints, open architect surfaces, and reading order BEFORE you open the requirements doc. Your job in the architect pass is to:

- Read the artifact set in the order in §2
- Respect the locked constraints in §3
- Lock the 30 open architect decisions enumerated at `REQUIREMENTS-PS-V11.md` §10 (and any additional decisions you identify)
- Survey ALL pack docs / scripts / workflows for unnamed integration points (§5)
- Produce `ARCHITECTURE-PS-V11.x.md` as your output (§10)

This doc is NAVIGATION + FRAMING — it does not duplicate content from the artifacts. When this doc and a referenced artifact disagree, the artifact wins (this doc is a starting-map, not the territory).

**Doc-level disclaimer (repeated for emphasis):** Preliminary; subject to architect challenge per pack memory `feedback_preliminary_triage_architect_challenge`. The locked constraints in §3 are LOCKED by user direction, not preliminary at that level (challenges to locked constraints require user-discussion-and-approval per `feedback_user_prescriptive_authority`). Everything else (open decisions; preliminary capability shapes; preliminary SCs; preliminary dispositions) is yours to challenge.

---

## §2 — Reading order

Read in this sequence; each step builds on the prior. Total prerequisite reading: ~90-120 minutes.

1. **THIS doc** — orientation; ~5 min. You are here.
2. **`maintenance-docs/v11-research/REQUIREMENTS-PS-V11.md`** — PRIMARY INPUT; ~30-40 min. Formal requirements distillation. 21 capabilities (Foundation / Interview / Deliverables / Pack-integration / Workflow / Scope-boundary clusters); per-capability problem / goals / SC / disposition / scope-verdict / rationale / cross-references / architect-bar; §3 constraints C1-C7; §5 cross-feature integration with groupings; §10 consolidated list of 30 open architect decisions. **READ IN FULL.** Use §10 as your working checklist during the architect pass.
3. **`maintenance-docs/v11-research/INTAKE-PS-V11.md`** — user-intent audit trail; ~15-20 min. Verbatim user framing + Q1-Q10 + naming decision + research approval + §7 quality-mitigation intuition + §7.5 interview flow dynamics + §8 capability list with walkthrough results + §9 19-goal index. Consult for verbatim user quotes when a `REQUIREMENTS-PS-V11.md` cross-reference points here. SOURCE-OF-TRUTH for user verbatim.
4. **`maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md`** — landscape facts; ~20-30 min. 985 lines; 7 categories (OSS PM tools / professional products / methodologies + frameworks / PRD templates / interview frameworks / AI-LLM tooling / dev-tool integration); §9 pack-relevance observations; §9.5 defensible methodology positions. Consult for the methodology-defaults defensibility argument (Goal 11; §3.5 C5) and Wave-3-vapor exclusion grounding (Goal 13; §9.4). SOURCE-OF-TRUTH for landscape facts and methodology positions.
5. **`maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md`** — pack-architect OT-pattern synthesis; ~15-20 min. §3 transferable patterns; §4 failure modes; §6 PS capability recommendations; §7 architect investigation areas; §8 challenge questions for the downstream architect (you). SOURCE-OF-TRUTH for OT-evidence-grounded recommendations. §7 and §8 are highest signal for you — they enumerate explicit investigation questions and challenge questions for your pass.
6. **`maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md`** — companion v11.1+ feature; ~10-15 min. Read §1 (design principles), §3 (constraints), §4 Capability #7 (from-external ingest — including SC7.8 PS-to-groupings conversion responsibility). The PS feature feeds groupings via this Capability #7 path; you must understand the contract.
7. **`maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md`** — groupings architect handoff; ~5-10 min. Cross-feature context. Your architect pass MAY surface a PS-awareness amendment to this doc (you propose; Pack Chat / groupings team writes; see §7 below).
8. **`maintenance-docs/v11-research/IMPLEMENTATION-REPORT-*.md` files** (7 IMPL-REPORTs; optional reference; ~15-20 min total if consulted) — coder/architect self-reports per the artifacts above. Consult for methodology rationale, open questions surfaced during authoring, and verification evidence. Most relevant for architect-pass: `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §5 (7 open questions including "Productboard AI / Aha! AI / Linear Agent feature parity ... should be revalidated before any design decisions"); `IMPLEMENTATION-REPORT-PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §4 (architect-specific open questions including validate-pack cycle-detection precondition verification per SC13.22).

**Skip-or-defer:** Other docs in `maintenance-docs/v11-research/` (research audits, prior architect drafts, per-entry split research) are not load-bearing for the PS architect pass. Consult them if a `REQUIREMENTS-PS-V11.md` cross-reference points to them; otherwise skip. IMPL-REPORTs in reading order step 8 are optional reference (consult when their content is most relevant to your specific design question), not load-bearing for the full pass.

---

## §3 — Locked decisions (user-stated; HIGH bar to challenge)

These are LOCKED constraints from user direction. You may not silently change them. If you believe a locked constraint should change, surface it to Pack Chat with evidence and propose a user discussion per `feedback_user_prescriptive_authority`. Until user-approved, you respect them.

For the categorical relationship between Constraints C1-C7, Cross-cutting principles, and Locked goals (the three labels you'll see across REQUIREMENTS and HANDOFF), see `REQUIREMENTS-PS-V11.md §3` opening preamble (user-approved 2026-05-25 per audit triage).

**Constraints C1-C7 (from `REQUIREMENTS-PS-V11.md` §3):**

- **C1 — CLIENT-SIDE ONLY** (§3.1; Goal 1; BD-191 description "Critical scope boundary"). PS affects `project-template/` surface only. PS NEVER applies to pack-self workflow. The pack repo's PM Chat continues to orchestrate pack-self development. Your architect output ships in `project-template/`; pack-side pack-self workflow stays untouched.
- **C2 — Two equal first-class modes** (§3.2; Goal 2; BD-191 SC7). Mode 1 (from-scratch) and Mode 2 (existing-PRD ingest + gap-fill) are both first-class. Both use the SAME structured interview approach.
- **C3 — Episodic / light footprint** (§3.3; Goal 5; BD-191 description "Position"). PS is invoked at project init, milestone spikes, on-demand. No background processes; no always-on agents; no chronic between-spike overhead.
- **C4 — Smooth pack integration without forced dependency** (§3.4; Goal 8; BD-191 SC6). ZERO HARD DEPENDENCY between PS and groupings in either direction. PS feeds groupings via existing #7 from-external ingest. PS NEVER produces `GRP-NNN.md` files directly.
- **C5 — Methodology defaults shipped** (§3.5; Goal 11; BD-191 SC8). PS ships defensible methodology defaults per `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §9.5. Per-project override path supported. You pick override mechanism but cannot ship methodology-neutral.
- **C6 — Wave 3 vapor excluded** (§3.6; Goal 13; BD-191 SC9). Wave 3 (autonomous agentic PM) is OUT. PS is Wave 2 (content-gen in PM workflows). No "PS agent autonomously runs the product roadmap."
- **C7 — PS-to-pack-entry-type boundary** (§3.7; Goal 18; BD-191 SC12). PS produces context-rich, audience-aware INPUTS. Pack ENTRY-TYPE workflows (phases / groupings primarily; backlog only as track-without-schedule edge case) build canonical artifacts. PS does NOT create canonical pack entry-type artifacts directly. HIGH bar — boundary touches locked pack entry-type architecture per `reference_pack_entry_type_semantics`.

**Locked user-stated goals (from `REQUIREMENTS-PS-V11.md` §2; full statements at `INTAKE-PS-V11.md` §9):**

- **Goal 1** (CLIENT-SIDE ONLY) — anchors C1.
- **Goal 2** (two equal first-class modes) — anchors C2.
- **Goal 5** (episodic / light footprint) — anchors C3.
- **Goal 7** (audience-aware; pack-primary canonical) — pack-primary FIRST; human-readable rendering is SECONDARY (see `REQUIREMENTS-PS-V11.md` §8).
- **Goal 8** (smooth pack integration; zero forced dependency) — anchors C4.
- **Goal 11** (defensible methodology positioning) — anchors C5; defaults locked per RESEARCH §9.5.
- **Goal 13** (Wave 2 only; Wave 3 OUT) — anchors C6.
- **Goal 14** (PM-Chat-interviews / agent-writes architecture; agents do NOT interview users) — structural enforcement against Wave 3.
- **Goal 16** (scope-discipline meta-criterion) — added workflows must move toward better organization / process / design / implementation, not just be additive.
- **Goal 17** (priorities as first-class cross-cutting driver; multi-axis) — non-negotiable as a category for completeness bar (Cap #6 SC item 8).
- **Goal 18** (PS-to-pack-entry-type boundary) — anchors C7; HIGH bar.

**Methodology defensible defaults (LOCKED per RESEARCH §9.5).** The canonical defaults table is in `REQUIREMENTS-PS-V11.md` §2 (methodology defensible-defaults table) + §3.5 (C5 constraint statement). The SHAPE is LOCKED (pack ships defensible defaults — not methodology-neutral); the specific VALUES within the defaults table are architect-decided at LOW bar per Cap #5 (architect may swap specific defaults if evidence + logic warrant; per-project override mechanism is yours to design — Decision #9 in §10). This reconciles with BD-191 SC8's "NOT prescribed; defensible defaults" framing: the values are NOT prescribed (architect picks within the locked shape); the shape that pack ships defaults at all IS LOCKED.

---

## §4 — Open architect-level surfaces

The full enumeration is at `REQUIREMENTS-PS-V11.md` §10 — 30 numbered architect decisions, each cross-referencing the capability + SC where it surfaced. Use §10 as your working checklist during the architect pass.

**Use the §10 list as a checklist:** for each numbered decision, your architecture output must either lock the design or document a deferral (with anchor + rationale). Deferrals are scope creep per `feedback_deferral_is_scope_creep` (cached in pack memory); use the size / blocked / logical-fit defense if you defer.

**You may identify additional decisions during deeper investigation.** The §10 list is STARTING SET, not exhaustive. If you surface a decision the requirements doc missed, lock it in your architecture output and note the gap in your IMPL-REPORT for Pack Chat to fold back into requirements (post-architect-pass, via Pack Chat triage).

**Architect-bar reminder per decision:** Each §10 entry carries an implicit bar. PS-internal decisions (e.g., interview structure; section ordering; per-deliverable shape) are LOW bar — you have wide latitude. Boundary decisions (e.g., #21 cross-feature with groupings; #2 CLIENT-SIDE-ONLY structural enforcement; #4 per-stream-tree contract adoption against pack mechanism) are HIGH bar — investigate thoroughly; coordinate with adjacent architects (groupings); cannot arbitrarily change boundary out of scope.

---

## §5 — Architect-discovery framing

Cap #15 SC15.1 names architect-discovery responsibility: **you survey ALL pack docs / scripts / workflows for PS integration points, not just the named subset.**

**Named subset (starting set; from `REQUIREMENTS-PS-V11.md` Cap #15 SC15.2):**
- `METHODOLOGY.md` (under `supporting-docs/` or `project-template/docs/pack/`)
- `PM-CHAT.md` (under `project-template/docs/pack/`)
- Trinity files (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)
- `OPTIONAL-FEATURES.md`
- Agent + skill files (`project-template/.claude/agents/*` / `project-template/skills/*`)
- `HELP-FRAGMENT-TRACKER.md`
- `QUICKSTART.md`
- `scripts/init-project.sh`

**Your job (Cap #15 SC15.1):** survey beyond this list. Look at ALL pack docs, scripts, and workflows. Identify unnamed integration points where PS workflow / wording / invocation belongs. Surface ALL of them in your architecture output (not just the named subset).

**Amendment protocol for locked docs:** If your survey surfaces a need to amend a LOCKED doc (e.g., `METHODOLOGY.md`; trinity files; `HANDOFF-V11.1-ARCHITECT.md`), you DO NOT edit directly. Surface the proposed amendment to Pack Chat with rationale; Pack Chat seeks user approval per `feedback_user_prescriptive_authority`; the amendment lands as a separate commit by Pack Chat or the appropriate downstream coder. You stay in your architecture pass; you do not cross into PM-only file edits.

**Don't pattern-match.** Per pack memory `feedback_pattern_matching_out_of_context_antipattern`, do NOT adopt the per-stream-tree contract (`_rules.md` + `_intro.md` + `_toc.md` + per-deliverable files) for PS deliverables just because backlog / implementation-plan / changelog / groupings use it. Investigate PS-specific properties first; lock the structure based on PS properties (not adjacent-mechanism pattern). See Decision #3 in `REQUIREMENTS-PS-V11.md` §10.

---

## §6 — Tiered challenge bar reminder

Per pack memory `feedback_preliminary_triage_architect_challenge`, you apply a tiered challenge bar to every preliminary position. The bar is non-uniform:

- **LOW bar (PS-internal):** You explore freely. Enhance / accept / reject / replace based on evidence and logic. Example: interview structural sections + ordering (Decision #7) — you decide named sections, ordering or orderless model, per-section framing without coordinating with other features.
- **HIGH bar (boundary-with-existing-pack):** You investigate thoroughly. Coordinate with adjacent architects. Cannot arbitrarily change boundary out of scope. Example: PS-to-groupings cross-feature integration (Decision #21) — you investigate whether `HANDOFF-V11.1-ARCHITECT.md` needs a PS-awareness amendment; you surface the proposed amendment through Pack Chat; you do NOT modify groupings architecture out of scope.

**Worked LOW vs HIGH examples in `REQUIREMENTS-PS-V11.md`:**
- LOW — Caps #2 (two modes) / #4 / #5 / #6 / #7 / #16 (PRD lifecycle) / N3 / N4 / N5 / N6 / N8 (interview structure; methodology positioning; completeness bar mechanism; tactical principles; PRD template; deliverable shapes; journey schema; feature inventory schema; human-readable rendering); Cap #1's agent topology decision (SC1.1 / SC1.2)
- HIGH — Cap #1's CLIENT-SIDE-ONLY structural enforcement (sub-decision SC1.3 — touches locked pack mechanism); Caps #13 / #15 / N1 (cross-feature integration with groupings; workflow + doc integration unnamed-point survey; PS deliverable directory structure pattern-match guard)

**Apply the bar before each design decision.** If a decision touches a locked pack mechanism (entry-type semantics; trinity rules; pack-ops PM-only files; existing locked architecture from BD-186 groupings or earlier locked v11 design), it is HIGH bar — pause and investigate before deciding. If it stays within PS-internal surfaces (PS deliverable shapes; PS interview structure; PS skill / agent design; PS audit mechanism), it is LOW bar — decide freely.

---

## §7 — Cross-feature context (groupings BD-186 / BD-189)

Groupings (BD-186 Resolved 2026-05-23; BD-189 implementation umbrella) is the only v11.x+ feature with explicit PS cross-feature integration. The relationship has these locked properties (see `REQUIREMENTS-PS-V11.md` §5):

- **ZERO HARD DEPENDENCY** in either direction.
- **PS feeds groupings via existing #7 from-external ingest workflow** per Goal 8. The from-external ingest is groupings Capability #7 in `REQUIREMENTS-GROUPINGS-V11.md`; you read that capability's SC list (especially SC7.8 — the PS-to-groupings conversion responsibility, user-approved 2026-05-24 on the groupings side).
- **PS NEVER produces `GRP-NNN.md` files directly** per Goal 8 + Goal 18.
- **Groupings stand alone per BD-186**; PS is OPTIONAL upstream feeder.
- **`HANDOFF-V11.1-ARCHITECT.md` may receive a PS-awareness amendment** during your architect pass (BD-191 description; if your survey surfaces a need, you propose; Pack Chat / groupings team writes).

**Read these companion docs for cross-feature context:**
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` §1 (design principles) + §3 (constraints) + §4 Capability #7 (from-external ingest including SC7.8).
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (groupings architect entry point; your cross-feature peer doc).

**Coordination protocol for PS-awareness amendments to groupings architecture:**

1. You surface the proposed amendment (rationale + cross-reference to your architecture decision driving the proposal) in your architecture output AND to Pack Chat.
2. Pack Chat triages and seeks user approval per `feedback_user_prescriptive_authority`.
3. If approved, Pack Chat (with groupings team coordination) writes the amendment as a separate commit.
4. You do NOT modify groupings architecture out of scope (HIGH bar per `REQUIREMENTS-PS-V11.md` §5.4).

**Decision #21 in `REQUIREMENTS-PS-V11.md` §10** is your specific architect-pass surface for cross-feature discovery — investigate whether `HANDOFF-V11.1-ARCHITECT.md` needs PS-awareness; surface findings; do not author the amendment yourself.

---

## §8 — Out-of-scope for the architect pass

**This is the ARCHITECT-PASS out-of-scope list — distinct from BD-191's REQUIREMENTS-pass out-of-scope** (BD-191's out-of-scope list excluded architecture itself; you are now in the architecture pass, so the out-of-scope shifts).

**Out-of-scope for your architect pass:**

- **Wave 3 design.** Autonomous agentic PM is OUT per C6 / Goal 13. Do not design "PS agent autonomously runs the product roadmap" or any feature that violates Goal 14 (PM-Chat-interviews / agent-writes boundary).
- **Pack-self application of PS.** PS is CLIENT-SIDE ONLY per C1 / Goal 1. Do not extend PS to govern pack-self development workflow. The pack repo's PM Chat continues to orchestrate pack-self.
- **Arbitrary mid-design changes to locked pack mechanisms.** Locked pack entry-type semantics (`reference_pack_entry_type_semantics`), per-stream-tree contracts, trinity rules, pack-ops PM-only file boundaries — these are HIGH bar. Investigate thoroughly; surface proposed amendments through Pack Chat; do not edit out of scope.
- **Modifying groupings architecture out of scope.** Cross-feature integration discovery is in scope (Decision #21); modifying `REQUIREMENTS-GROUPINGS-V11.md` Capability #7 or `HANDOFF-V11.1-ARCHITECT.md` directly is OUT. Surface proposed amendments through Pack Chat (§7).
- **Implementation planning.** Your output is `ARCHITECTURE-PS-V11.x.md` — the locked design. Implementation commit sequencing belongs to the downstream PS planner pass per `feedback_planner_user_review_before_coder`.
- **Implementation itself.** Coder work happens after planner output and user review.
- **Opening downstream BDs.** Pack Chat opens downstream BDs based on your planner-output sequencing, with user approval per `feedback_deferral_is_scope_creep` / OQ-1 EXECUTION-PLAN §B step 5. You don't open BDs from your architect pass directly.
- **Editing this HANDOFF.** This doc is INPUT to you, not output. If you find a gap, surface it to Pack Chat; do not edit `HANDOFF-PS-ARCHITECT.md` from your architect pass.
- **Editing `REQUIREMENTS-PS-V11.md`.** Same as above — it is INPUT. If your investigation surfaces gaps in requirements, surface them to Pack Chat; corrections happen via Pack Chat triage as a separate commit.

---

## §9 — Discipline pointers (pack memory rules you must follow)

Pack memory rules govern your architect pass. Read each rule before relying on its name; the canonical statements are in `CLAUDE.md` `## Pack memory` (pack-repo trinity).

- **`feedback_preliminary_triage_architect_challenge`** — Every preliminary position in `REQUIREMENTS-PS-V11.md` is yours to challenge with evidence and logic; tiered bar (LOW vs HIGH); user retains final authority on challenges.
- **`feedback_user_prescriptive_authority`** — User retains decision authority; you produce evidence-based recommendations; the user approves or redirects. Locked-constraint challenges go through user discussion + approval.
- **`feedback_pattern_matching_out_of_context_antipattern`** — Do not adopt patterns from adjacent pack mechanisms (per-stream-tree contract; agent-skill split; verb-naming pattern) without verifying property-fit for PS specifically. Investigate PS properties first; adopt patterns only when property-fit is shown.
- **`reference_pack_entry_type_semantics`** — Phases / Tasks / Groupings / Phase parts pack data-structure semantics are LOCKED. PS workflows are INFORMED BY these semantics; PS does NOT create canonical pack entry-type artifacts directly (C7 / Goal 18 boundary).
- **`feedback_no_solutions_in_agent_prompts`** — If you spawn sub-agents during architect investigation (e.g., research / discovery passes), their prompts contain problem / goal / success criteria only — never proposed solutions. This rule applies to YOU when authoring agent prompts as part of your architect pass.
- **`feedback_pack_chat_does_not_architect`** — Pack Chat does not architect. Pack Chat's role around your pass is: spawn you; read your output; triage findings; seek user approval; open downstream BDs. Pack Chat does NOT edit your architecture output or pre-architect the design.
- **`feedback_planner_user_review_before_coder`** — Your output is NOT auto-approved into coder spawn. After your architecture lands and the user reviews, the planner pass produces PLAN-PS-V11.x.md; the planner pass also goes through user review before coder spawn. Your architecture is one stage in the pipeline; the user has cheap-redirect windows at architect-out and planner-out gates.
- **`feedback_deferral_is_scope_creep`** — If you defer a decision in your architecture output, the deferral needs SIZE / BLOCKED / LOGICAL-FIT defense + a tracked anchor (live BD or live TODO with TD-TBD). Archived reports are not acceptable anchors. Default is decide-now.
- **`feedback_review_fix_one_cycle`** — Downstream review cycle is one review + one fix per BD; you author your architecture to be reviewable in that cycle (clear locks; clear rationale; clear cross-references).
- **`feedback_groupings_design_principles`** — Groupings (BD-186) 5-core + C6 + C7 design principles are LOCKED and authoritative at `REQUIREMENTS-GROUPINGS-V11.md` §1. Your cross-feature integration discovery (§7) respects these principles.

---

## §10 — Forward pointer for architect outputs

**Your output:** `ARCHITECTURE-PS-V11.x.md` (you may anchor a version into the filename — e.g., `ARCHITECTURE-PS-V11.1.md` — once scheduling is settled).

**What your architecture output must contain:**

- A locked design for each of the 30 open architect decisions in `REQUIREMENTS-PS-V11.md` §10 (or a tracked deferral with anchor + rationale per `feedback_deferral_is_scope_creep`).
- Per-decision rationale citing evidence + logic + cross-references.
- Resolution of LOW vs HIGH bar per decision (you tag each decision with its bar; HIGH-bar decisions carry investigation summary).
- Cross-feature integration design with groupings (Decision #21; §7 coordination protocol).
- Architect-discovery survey results (Cap #15 SC15.1; §5; named subset PLUS unnamed integration points you surfaced).
- Per-deliverable audience-primary classification table (Decision #29; per Cap #17 SC17.5).
- Wave 2 / Wave 3 boundary line specifics (Decision #27; per Cap #17 SC17.2).
- Proposed amendments (if any) surfaced to Pack Chat — clearly tagged as proposed-not-landed; do NOT edit locked docs directly.

**Pipeline forward (per `REQUIREMENTS-PS-V11.md` §11.3 + `feedback_planner_user_review_before_coder`):**

1. **Architect pass (you)** — produce `ARCHITECTURE-PS-V11.x.md`. Lock the 30 decisions in §10 or document tracked deferrals.
2. **User review of architect output** — per `feedback_planner_user_review_before_coder`; user-cheap-redirect window before planner spawn.
3. **Planner pass** — separate downstream BD; planner produces `PLAN-PS-V11.x.md` with BD breakdown + sequencing + verification strategy.
4. **User review of planner output** — per `feedback_planner_user_review_before_coder`; user-cheap-redirect window before coder spawn.
5. **Coder cycles** — per-BD implementation with reviewer cycles per `feedback_review_fix_one_cycle`.
6. **End-of-batch reviewer + BD status flips** — final per pack patterns.

**Downstream BDs (preliminary; planner decides actual phasing):** Examples in `REQUIREMENTS-PS-V11.md` §11.3:
- BD-NNN — PS architecture design (this stage; you produce `ARCHITECTURE-PS-V11.x.md`)
- BD-NNN — PS implementation plan (planner produces `PLAN-PS-V11.x.md`)
- BD-NNN(...) — PS implementation phases per planner sequencing
- Cross-feature BD-NNN — coordination with groupings architect if `HANDOFF-V11.1-ARCHITECT.md` amendment surfaces

**Pack Chat orchestrates downstream BD opens** with user approval per `feedback_deferral_is_scope_creep` / OQ-1 EXECUTION-PLAN §B step 5. You do not open BDs directly from your architect pass.

**Cross-reference to BD-191 close-out:** Per `REQUIREMENTS-PS-V11.md` §11.5, after `REQUIREMENTS-PS-V11.md` lands and user reviews + approves, BD-191 closes (Status flip to Resolved); Pack Chat then authors this `HANDOFF-PS-ARCHITECT.md` (you are reading the result), updates `HANDOFF-V11.1-ARCHITECT.md` PS-awareness amendment if surfaced, and opens downstream BDs as architect identifies implementation phases (via standard Pack Chat triage).

---

End of HANDOFF-PS-ARCHITECT.md.
