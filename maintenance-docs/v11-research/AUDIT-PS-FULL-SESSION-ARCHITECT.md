# AUDIT-PS-FULL-SESSION-ARCHITECT.md

**Authored by:** pack-architect (full-session audit pass for BD-191; design-coherence focus)
**Date:** 2026-05-24
**Branch:** v11-dev
**HEAD at audit start:** `5534beb7078a95347a604d586aa819334ef8b943`

**Purpose.** Cross-doc design-coherence audit of the 16 artifacts produced during the BD-191 (Product Specialist / PS) sidecar requirements-gathering session. This audit COMPLEMENTS the parallel pack-reviewer technical-discipline pass (per-stream-tree contract; cross-reference integrity; naming conventions; severity classification). Focus here is on errors / omissions / conflicts / confusion / conflicting parts at the artifact-cross-cutting design level.

**Discipline framing (per pack memory `feedback_preliminary_triage_architect_challenge`).** Every disposition / scope verdict / capability shape / open architect decision in the session docs is PRELIMINARY. The downstream v11.x+ PS architect will challenge each preliminary position. This audit is NOT a re-design pass; it is a coherence check. Preliminary positions that are evidence-based and internally consistent PASS this audit even if I would have designed differently.

**Discipline framing (per pack memory `feedback_user_prescriptive_authority`).** User-locked constraints (C1-C7; Goals 1/2/5/7/8/11/13/14/16/17/18) are LOCKED. Challenging locked constraints is OUT OF SCOPE for this audit.

---

## §1 — Read coverage

| Doc | Read mode | Notes |
|---|---|---|
| `pack-ops/BACKLOG.md` BD-191 entry (lines 2862-2962) | full read | SC1-SC13 + description + INPUTS + AUDIT-TRAIL + Position |
| `INTAKE-PS-V11.md` (724 lines) | full read | §1-§10; §7.5 flow dynamics; §8 capability list + Walkthrough results; §9 19-goal index |
| `REQUIREMENTS-PS-V11.md` (1196 lines) | full read | §1-§11; all 21 capabilities; §10 30 architect decisions |
| `HANDOFF-PS-ARCHITECT.md` (228 lines) | full read | §1-§10 |
| `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (985 lines) | targeted read | section TOC; §8-§10 in detail (synthesis + pack-relevance + sources); §1-§7 spot-checks for cited sub-sections |
| `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (638 lines) | full read | §1-§10; §3 patterns; §4 failure modes; §5 amendments; §6 PS recommendations; §7-§8 architect investigation areas/challenge questions |
| `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (183 lines) | full read | research methodology + sources + open questions |
| `IMPLEMENTATION-REPORT-PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (154 lines) | full read | architect methodology + SC mapping |
| `IMPLEMENTATION-REPORT-INTAKE-PS-V11-GOALS-INDEX.md` (192 lines) | full read | coder methodology + verification |
| `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` (235 lines) | full read | §5.1 amendment coder report |
| `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` (375 lines) | full read | §5.2/§5.3/§5.4/§5.6 + Goal 18 coder report |
| `IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` (270 lines) | full read | §7.5 + §8 Walkthrough results + Goal 19 coder report |
| `IMPLEMENTATION-REPORT-REQUIREMENTS-PS-V11.md` (481 lines) | full read | REQUIREMENTS-PS-V11.md authoring coder report |
| `IMPLEMENTATION-REPORT-HANDOFF-PS-ARCHITECT.md` (227 lines) | full read | HANDOFF authoring coder report |
| `REQUIREMENTS-GROUPINGS-V11.md` — touched portions | targeted read | §5 amendments via grep verification: Cap #1 mvp_priority REJECT (line 136); Cap #7 SC7.7 (line 358); Cap #7 SC7.8 NEW (line 359); Cap #9 SC9.9 (line 432); Cap #13 SC13.22 NEW (line 638); sub-list (b)+(d) (lines 642+644); Cap #17 SC17.10 refinement (line 839); cross-refs (lines 653-669) |
| `HANDOFF-V11.1-ARCHITECT.md` — touched portions | targeted read | §5.1 cycle-detection entry (line 53); §5.2 architectural-seam defer entry (line 54) |
| `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` — touched portion | targeted read | §10.2 cycle-detection coverage entry (line 853) |

**Reference materials consulted.** `CLAUDE.md` § "Pack memory"; pack memory files `feedback_preliminary_triage_architect_challenge`, `feedback_user_prescriptive_authority`, `feedback_pattern_matching_out_of_context_antipattern`, `reference_pack_entry_type_semantics`, `feedback_no_solutions_in_agent_prompts`, `feedback_pack_chat_does_not_architect`.

**Unable to read in full.** None. All 16 in-scope docs reached for the audit-coherence purpose. RESEARCH and REQUIREMENTS-GROUPINGS-V11.md were targeted-read (full content not load-bearing for THIS audit's focus; touched portions verified against full-doc structure via grep + cross-doc references).

---

## §2 — Methodology

**Read order.** INTAKE first (verbatim user intent + audit-trail) → REQUIREMENTS (distillation) → HANDOFF (architect entry point) → RESEARCH (landscape facts) → PLANNING-PROCESS-INSIGHTS (OT-pattern synthesis) → IMPL-REPORTs (per-doc coder/architect self-reports) → cross-feature touched portions in REQUIREMENTS-GROUPINGS / HANDOFF-V11.1 / TOUCH-POINT-INVENTORY. Read order intentionally moved from "what the user said" outward toward "what the architect-handoff promises" — coherence at each layer requires the prior layer to lock first.

**Audit-class buckets.**
- **Error** — factual incorrectness; cross-reference mismatch; stale claim that contradicts current state.
- **Omission** — required content missing per BD-191 SCs or per goal coverage.
- **Conflict** — same concept stated differently in two docs; contradiction.
- **Confusion** — ambiguous semantic framing; unclear ownership/discipline boundary.
- **Conflicting part** — internal contradiction within a single doc OR across docs of the same concept.

**Severity scale.**
- **BLOCKER** — must fix before BD-191 closes; misleads the downstream architect.
- **MUST** — high-confidence finding; should fix unless explicit rationale to skip.
- **SHOULD** — defensible finding; reasonable to defer to architect at design time but worth flagging.
- **NIT** — small finding; default-fix per `feedback_fix_all_review_findings` (cached in pack memory).
- **INFO** — observation; not actionable but worth noting.

**Out-of-scope per this audit.**
- Re-designing preliminary positions ("I would have done X differently") — that's the downstream architect's job per the preliminary discipline rule.
- Challenging user-locked constraints — those go through user discussion per `feedback_user_prescriptive_authority`.
- Technical-discipline checks the parallel pack-reviewer pass owns (per-stream-tree contract; severity classification methodology; cross-reference INTEGRITY at granular link level — I flag a few high-signal cross-ref errors I encountered but defer full sweep).

---

## §3 — BLOCKER findings

### B-1. INTAKE §9 preamble says "17 goals" / "17 entries" but the table contains 19 goals

**Class:** Error (stale claim conflicting with current content).
**File + location:** `INTAKE-PS-V11.md` line 540-541 ("17 user-stated goals driving the PS feature design. Goals 1-15 are cross-references ... Goals 16 and 17 surfaced ..."); §9.1 heading line 547 (`### §9.1 — Goal index (17 entries)`).
**Actual content:** §9.1 table at lines 549-569 contains 19 rows (Goals 1 through 19). Goals 18 (PS-to-pack-entry-type boundary) and 19 (Human-readable PRD rendering) were added AFTER the §9 introduction was authored, via two later IMPL passes (`IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` added Goal 18; `IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` added Goal 19). The preamble was not updated in either pass.
**Why BLOCKER.** The §9 section IS the canonical goals index. INTAKE is source-of-truth for verbatim user intent per `REQUIREMENTS-PS-V11.md §2` ("If a goal statement disagrees between this table and INTAKE §9, INTAKE WINS"). REQUIREMENTS and HANDOFF correctly cite "19 user-stated goals" / "§9 19-goal index" — the audit-trail SSOT now contradicts the consumers. An architect reading INTAKE first will see "17 goals" in the preamble and "Goals 1-19" in the table on the next page; this is exactly the failure mode the audit-trail discipline (`INTAKE wins if disagreement`) cannot resolve because the disagreement is INSIDE the audit trail.
**Recommended fix shape.** Mechanical text-update: replace `17 user-stated goals` with `19 user-stated goals` (line 540); replace `Goals 1-15 are cross-references to existing source in this doc (and adjacent docs); Goals 16 and 17 surfaced during BD-191 sidecar discussion on 2026-05-24 AFTER §1 through §8 were authored` with text that covers Goals 16/17/18/19 (line 541); replace `### §9.1 — Goal index (17 entries)` with `### §9.1 — Goal index (19 entries)` (line 547); add a line to "Source-coverage closure" (line 545) for Goals 18/19 if needed. No goal-row data change — the table is correct.

---

### B-2. INTAKE §9.6 preamble says "BD-191 SC1-SC11" but SCs go to SC13

**Class:** Error (stale claim conflicting with current state).
**File + location:** `INTAKE-PS-V11.md` line 678 (§9.6 preamble: "BD-191 SC1-SC11 capture process-level criteria for the requirements-gathering work").
**Actual content.** BD-191 entry in `pack-ops/BACKLOG.md` (lines 2918-2952) has SC1 through SC13. The §9.6 table (lines 680-700) correctly contains rows for Goal 18 → SC12 and Goal 19 → SC13; only the preamble is stale. SC12 was added during the Batch-2 PS amendments pass (per `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` SC15 + "Pack Chat to land SC12" footnote); SC13 was added during the Goal 19 walkthrough pass (per `IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` line 264 reference). The preamble line 678 was not updated.
**Why BLOCKER.** Same audit-trail-SSOT concern as B-1. A reader cross-referencing INTAKE §9.6 against the BACKLOG entry will see "SC1-SC11" claimed and "SC1-SC13" actual — and there is no way for the reader to know which is canonical without external verification.
**Recommended fix shape.** Mechanical text update: replace `BD-191 SC1-SC11 capture process-level criteria` with `BD-191 SC1-SC13 capture process-level criteria` (line 678).

---

### B-3. INTAKE §10 says REQUIREMENTS-PS-V11.md "will distill" — but the doc exists

**Class:** Error (forward-looking language that became stale after the consumer landed).
**File + location:** `INTAKE-PS-V11.md` lines 706-719 (§10 Forward pointer).
**Actual content.** Line 710 says: "REQUIREMENTS-PS-V11.md (downstream, produced during the BD-191 sidecar triage) **will distill** this intake doc + research findings into formal: ...". The doc is now 1196 lines and has shipped; "will distill" is stale. The bullet list at 712-717 also describes what REQUIREMENTS-PS-V11.md should contain in future-tense — that ALREADY happened.
**Why BLOCKER.** The §10 Forward pointer is the navigational hand-off from INTAKE to REQUIREMENTS. A first-time architect reader sees future-tense language and may infer that REQUIREMENTS-PS-V11.md is incomplete or pending. Per `HANDOFF-PS-ARCHITECT.md §2` reading order, INTAKE is step 3 — the architect reads INTAKE AFTER reading REQUIREMENTS-PS-V11.md, so the discrepancy is immediately visible.
**Recommended fix shape.** Replace future-tense ("will distill") with past-tense ("distills" / "captures") OR add a note "(REQUIREMENTS-PS-V11.md LANDED 2026-05-24; see § cross-reference)". The bullet list reads as a SPECIFICATION of what REQUIREMENTS should contain; rewording to descriptive ("contains: Design principles drawn from ...") would also work.

**Sub-finding B-3a.** Line 712 says `§9 pack-relevance observations` — this is AMBIGUOUS post-renumbering. Before the §9 goals index was added, "§9 pack-relevance observations" unambiguously referred to RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md §9 (which has the title "Pack-relevance observations"). After the INTAKE goals index was added at INTAKE §9, the reference is now collision-prone: INTAKE has its own §9 (user-stated goals), and `§9` could mean either RESEARCH §9 or INTAKE §9. Compounded by the fact that INTAKE §5 already has anchors named §9.1-§9.5 that paraphrase RESEARCH §9.1-§9.5 (see INTAKE lines 189-215). The audit-trail discipline note in INTAKE §5 already calls these "RESEARCH doc §9 / §9.1-§9.5" but §10's bare `§9` is ambiguous.
**Recommended fix shape.** Disambiguate `§9 pack-relevance observations` to `RESEARCH §9 pack-relevance observations`. Same for `§9.2 underserved gaps` / `§9.3 familiar patterns` / `§9.5 methodology positions` later in the same bullet list — these all resolve to RESEARCH (not INTAKE).


---

## §4 — MUST findings

### M-1. INTAKE has §9.x ANCHOR-COLLISION between §5 (research paraphrase) and §9 (goals index)

**Class:** Confusion (ambiguous structural anchor; multiple sections share `§9.x` numbering form).
**File + location:** `INTAKE-PS-V11.md` lines 189-215 (subsection anchors `### §9.1` through `### §9.5` nested under `## §5 — Research output headlines`) vs lines 547-676 (subsection anchors `### §9.1` through `### §9.6` nested under `## §9 — User-stated goals (consolidated index)`).
**Actual content.** Section §5 paraphrases RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md §9 findings and uses sub-anchors mirroring RESEARCH's structure (§9.1 Hard things, §9.2 Underserved gaps, ...). Section §9 is the user-stated goals index and ALSO uses §9.1 through §9.6 sub-anchors. A bare cross-reference like `INTAKE §9.2` (or `§9.5`) is ambiguous between the two anchor sets.
**Worked example of confusion.** B-3a above shows the failure mode for §10's bare `§9 pack-relevance observations` reference. The walkthrough IMPL-REPORT explicitly flagged this (`IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` line 85, 122, 183, 216 — "this is pre-existing doc structure"). The IMPL-REPORTs treated the collision as pre-existing and non-actionable; but with two new collision-sensitive references (`§9.4 Goal 18` and `§9.5 Goal 19`), the collision now risks downstream confusion.
**Why MUST.** The §9.x anchor collision is a known structural artifact. The audit-trail discipline tries to live with it via prose context (§5's anchors are nested under "Research output headlines"; §9's are under "User-stated goals"). The collision did not bite during BD-191 sidecar work because IMPL-REPORT verification queries used the line numbers, not the anchor names. But downstream architect / planner / reviewer / coder agents will use anchor-name cross-references (`§9.4` / `§9.5`) — not line numbers. The §5 anchors will trip them.
**Recommended fix shape.** Two plausible directions (architect/Pack-Chat triage decides):
- **(a) Rename INTAKE §5 sub-anchors.** Change `### §9.1 — Hard things to be careful of` to `### §5.1 — Hard things to be careful of` (and §9.2-§9.5 similarly), since these are nested under `## §5`. Pure rename; no content change. This is the more structurally-pure fix.
- **(b) Renumber INTAKE §9 sub-anchors.** Move the goals index out of `§9.x` namespace entirely (less elegant; the goals index naturally sub-anchors under §9 user-stated goals).
- The PARALLEL pack-reviewer pass may have a recommendation here per technical-discipline standards; architect/Pack-Chat triage may want to read that report alongside this one before locking the fix shape.

---

### M-2. REQUIREMENTS-PS-V11.md §2 introductory text says "19 user-stated goals" but body content references "19 goals" in section header only — internal-consistency check passes; cross-doc consistency with INTAKE is broken via B-1

**Class:** Conflicting part (cross-doc disagreement; B-1 root cause; surfaced here as the receiving-end consequence).
**File + location:** `REQUIREMENTS-PS-V11.md` line 57 (`## §2 — Design principles (consolidated reference index of 19 user-stated goals)`), line 59 ("This section is a NAVIGATION INDEX into the 19 user-stated goals captured verbatim in `INTAKE-PS-V11.md §9`. Full statements are NOT duplicated here; the companion doc remains source-of-truth.").
**Actual content.** REQUIREMENTS §2 says 19 goals; INTAKE §9 (the cited SSOT) preamble says 17. The TABLE in INTAKE §9.1 has 19 rows; the REQUIREMENTS §2 table has 19 rows. Source-of-truth claim is broken because of B-1: the SSOT preamble disagrees with both its own table and the consumer.
**Why MUST.** Once B-1 is fixed in INTAKE, this consistency restores. Surfaced separately because (a) it documents the audit-trail-SSOT chain failure mode (consumer is honest about citing SSOT; SSOT has stale preamble), (b) post-B-1-fix verification should re-check this cross-doc consistency.
**Recommended fix shape.** No edit to REQUIREMENTS-PS-V11.md (it is correct). After B-1 is applied to INTAKE, verify by reading both side-by-side that the "19" claim matches.

---

### M-3. HANDOFF-PS-ARCHITECT.md §3 lists locked goals but the count + ordering does not include all goals named in REQUIREMENTS §2's cross-cutting list

**Class:** Omission / cross-doc disagreement on which goals are "locked".
**File + location:** `HANDOFF-PS-ARCHITECT.md` lines 66-76 (§3 Locked user-stated goals list).
**Actual content.** HANDOFF §3 lists locked goals: 1, 2, 5, 7, 8, 11, 13, 14, 16, 17, 18. That's 11 goals. REQUIREMENTS §2 "Cross-cutting principles" lists: Goals 1, 5, 7, 13, 16, 17, 18 (7 goals). They are NOT the same set. Goals 2 (two modes) / 8 (smooth integration) / 11 (methodology defaults) / 14 (architecture) appear locked-but-not-cross-cutting in HANDOFF; REQUIREMENTS treats Goal 11 as locked via C5 and Goal 14 as anchoring §9.2 but doesn't classify them as "cross-cutting". The relationship isn't necessarily wrong — "locked" and "cross-cutting" are different categories — but the docs don't define the difference for the reader.
**Why MUST.** A downstream architect reading HANDOFF §3 first will see 11 locked goals. Reading REQUIREMENTS §2 next, they see 7 cross-cutting goals AND 19 total goals. Without a defined relationship (locked ⊃ cross-cutting? locked = constraints-anchoring? cross-cutting = applies-everywhere?), the reader has to reverse-engineer the semantic. The audit framing for architect challenge then becomes ambiguous: is the challenge bar HIGH for all 11 "locked" or only for the 7 "cross-cutting"?
**Recommended fix shape.** Add a definitional sentence to HANDOFF §3 OR REQUIREMENTS §2 distinguishing "locked" (user-prescribed; high bar to challenge) from "cross-cutting" (applies to every capability decision). The two categories partially overlap; clarifying which is which prevents the architect from inheriting an ambiguous bar.

---

### M-4. HANDOFF-PS-ARCHITECT.md §2 reading order omits the IMPL-REPORTs entirely

**Class:** Omission.
**File + location:** `HANDOFF-PS-ARCHITECT.md` lines 38-46 (§2 Reading order, 1-7 numbered).
**Actual content.** Reading order lists THIS doc → REQUIREMENTS → INTAKE → RESEARCH → PLANNING-PROCESS-INSIGHTS → REQUIREMENTS-GROUPINGS → HANDOFF-V11.1. The 7 IMPL-REPORTs (research IMPL-REPORT; planning-process IMPL-REPORT; 4 coder IMPL-REPORTs for INTAKE/grouping amendments/walkthrough updates/REQUIREMENTS authoring; HANDOFF authoring IMPL-REPORT) are not mentioned in §2. §2 says "Skip-or-defer: Other docs in `maintenance-docs/v11-research/` ... are not load-bearing for the PS architect pass."
**Why MUST.** The IMPL-REPORTs ARE the per-doc audit trail. They contain: methodology choices for each pass (e.g., the planning-process-insights IMPL-REPORT's §4 open questions has explicit `Phase-level cycle detection in validate-pack — does it already exist?` flag for the architect); SC mappings; PREFLIGHT line; chunked-Write rationale. The research IMPL-REPORT §5 has 7 explicit open questions for the architect ("Productboard AI / Aha! AI / Linear Agent feature parity ... evolving fast (2025-2026 quarterly releases) ... should be revalidated before any design decisions"). These are real architect-actionable items. Without explicit mention in HANDOFF §2 the architect is unlikely to read them. Even framing IMPL-REPORTs as optional reference would help; "skip-or-defer" actively discourages reading them.
**Recommended fix shape.** Add a bullet to HANDOFF §2 between the existing items or at the end: e.g., "8. (Optional reference) `IMPLEMENTATION-REPORT-*.md` files in `maintenance-docs/v11-research/` — coder/architect self-reports per the artifacts above; consult for methodology rationale, open questions surfaced during authoring, and verification evidence. Most relevant: research IMPL-REPORT §5 (7 open questions); planning-process IMPL-REPORT §4 (architect-specific open questions including validate-pack cycle-detection verification)."

---

### M-5. REQUIREMENTS §10 architect-decision list places HANDOFF authoring (Decision #30) inside the architect's checklist — but HANDOFF is already authored by Pack Chat

**Class:** Confusion (decision-ownership ambiguity; possibly cross-cutting category mismatch).
**File + location:** `REQUIREMENTS-PS-V11.md` lines 1142-1143 (Decision #30).
**Actual content.** Decision #30 reads: "**PS-architect post-design HANDOFF-PS-ARCHITECT.md authoring (BD-191 File/Symbol)** — Pack Chat (with user approval) authors HANDOFF-PS-ARCHITECT.md after this BD's REQUIREMENTS-PS-V11.md lands and user reviews; architect may rename with version anchor at write time once scheduling is settled."
**Why MUST.** Decision #30 is NOT an architect decision. The text itself says "Pack Chat (with user approval) authors HANDOFF-PS-ARCHITECT.md" — that's Pack-Chat / Pack-Chat orchestration scope. The architect cannot lock this decision because it's not theirs to make. Compounded fact: HANDOFF-PS-ARCHITECT.md ALREADY EXISTS (228 lines; see IMPL-REPORT-HANDOFF-PS-ARCHITECT.md). The architect-checklist would be "#30: review whether HANDOFF needs amendment after architect pass" which is a different decision shape entirely. HANDOFF §10 promises "30 numbered architect decisions in `REQUIREMENTS-PS-V11.md` §10 (or a tracked deferral)" but #30 cannot be locked by the architect; it has already been resolved by Pack Chat.
**Why MUST not BLOCKER.** The architect will quickly see that #30 is already done (HANDOFF exists). The error is misleading but not catastrophic; the architect's checklist still has 29 actionable decisions.
**Recommended fix shape.** Three options (architect/Pack-Chat triage decides):
- (a) Remove Decision #30 entirely (HANDOFF authored; not architect-decided). Renumber if needed — but renumbering breaks downstream references that already cite "30 decisions" (HANDOFF §2 line 39; HANDOFF §4 line 84; HANDOFF §10 line 197); leave count at 30 and re-purpose #30 as "Post-architect amendment review of HANDOFF-PS-ARCHITECT.md" (architect surveys HANDOFF for needed updates after design lands).
- (b) Rewrite Decision #30 as architect-actionable: "Decide whether HANDOFF-PS-ARCHITECT.md needs post-architecture amendment (rename to versioned form / propose addendum / etc.) and surface to Pack Chat" — keeps the slot, makes the decision architect-actionable.
- (c) Leave as INFO note (architect understands #30 is already resolved by Pack Chat; functional outcome same as removing). Counts stay 30; less elegant but lowest-friction.

---

### M-6. REQUIREMENTS §3 lists constraints C1-C7 but doesn't explicitly bind each to a goal it anchors — the cross-references exist but Goal 14 is referenced but never gets a "C-N" anchor

**Class:** Omission (asymmetric structural pattern; Goal 14 is locked-and-referenced but not constraint-anchored).
**File + location:** `REQUIREMENTS-PS-V11.md` §3 (lines 111-187); HANDOFF §3 (lines 64-76).
**Actual content.** REQUIREMENTS §3 has C1 (Goal 1) / C2 (Goal 2) / C3 (Goal 5) / C4 (Goal 8) / C5 (Goal 11) / C6 (Goal 13) / C7 (Goal 18). HANDOFF lists locked Goals 1, 2, 5, 7, 8, 11, 13, **14**, 16, 17, 18. Goal 7 (audience-aware) is referenced everywhere but isn't anchored to a C-N. Goal 14 (PM-Chat-interviews / agent-writes; pack pattern agents don't interview users) is repeatedly named "locked pack pattern" / "structural enforcement against Wave 3" — but there is NO C-N anchor for it. Goal 16 (scope-discipline meta-criterion) and Goal 17 (priorities first-class) are also locked but not C-N anchored.
**Why MUST.** The constraint-set is asymmetric. A natural reading is "if a goal is locked, it gets a C-N anchor; if no C-N, it's design principle not constraint." But Goal 14 IS locked per HANDOFF §3 explicit cross-reference. The asymmetry confuses the architect: are Goals 7 / 14 / 16 / 17 LOCKED (HANDOFF says yes) or DESIGN-PRINCIPLE only (REQUIREMENTS §3 doesn't C-anchor them)? Goal 14 in particular is the architectural enforcement layer against Wave 3 — making it a constraint-anchored item would clarify that the architect cannot challenge it as a PS-internal LOW-bar choice.
**Recommended fix shape.** Options (architect/Pack-Chat triage decides):
- (a) Add explicit C8 (Goal 14 architectural mediation) and possibly C9/C10/C11 for Goals 7/16/17 — restructures REQUIREMENTS §3 to fully cover the locked set.
- (b) Add a §3-preamble paragraph explaining the asymmetry: "Constraints C1-C7 are user-prescribed locks ANCHORED ON specific goals; Goals 7 / 14 / 16 / 17 are LOCKED but NOT constraint-anchored because they apply as cross-cutting design principles rather than scope-bounding constraints."
- (c) Reduce HANDOFF §3 "Locked goals" list to only the C-anchored ones (Goals 1/2/5/8/11/13/18) — symmetric but loses the explicit Goal 7/14/16/17 lock signal.

---

### M-7. PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 originally recommended per-stream-tree pattern for Cap N1; INTAKE §8 Walkthrough then REVERSED to "architect-decides structure"; REQUIREMENTS Cap N1 SC N1.4 keeps a "if architect adopts per-stream-tree, HIGH bar" cross-reference — but the source doc is stale relative to the walkthrough decision

**Class:** Conflicting part (source doc says A; downstream walkthrough overrides to B; source doc not updated).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §6.1 line 424 ("**New Capability #N1: PS deliverable per-stream tree structure.** Drawn from §4.1 alternative. PS deliverables live in `project-template/docs/project/<name>/` ... following the pack's per-stream tree contract: `_rules.md` + `_intro.md` + `_toc.md` + per-deliverable files. NOT ad-hoc directory layout."); `INTAKE-PS-V11.md` §8 Walkthrough results Cap N1 row (line 501) which OVERRIDES with "REVISED from per-stream-tree: architect-decides structure based on PS-specific properties + stated goals + technical constraints. Pattern-matching out of context is anti-pattern per pack memory `feedback_pattern_matching_out_of_context_antipattern`."
**Why MUST.** PLANNING-PROCESS-INSIGHTS-FROM-OT.md §4.1 explicitly says "Per-stream tree pattern" should be adopted. INTAKE §8 walkthrough decision reverses. REQUIREMENTS Cap N1 correctly captures the architect-decides framing AND lays a HIGH-bar trip wire if architect re-adopts per-stream-tree (SC N1.4). But the PLANNING-PROCESS-INSIGHTS-FROM-OT.md source doc still claims §6.1 N1 IS per-stream-tree. An architect reading PLANNING-PROCESS-INSIGHTS first will see the original recommendation; reading INTAKE/REQUIREMENTS second will see the reversal. Without explicit cross-reference, the architect doesn't know which is current.
**Why MUST not BLOCKER.** REQUIREMENTS Cap N1 + INTAKE §8 Walkthrough are explicit and properly authored. The risk is one-step: the architect reads PLANNING-PROCESS-INSIGHTS-FROM-OT.md uncritically without cross-checking. PLANNING-PROCESS-INSIGHTS-FROM-OT.md self-frames as "informative not prescriptive" per its §1 — that helps. HANDOFF §5 explicitly says "Don't pattern-match" and reminds the architect of `feedback_pattern_matching_out_of_context_antipattern`. The framing reduces the risk to MUST-not-BLOCKER.
**Recommended fix shape.** Two options:
- (a) Add a "Status: SUPERSEDED" or "Status: REVISED in walkthrough" note to PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 with cross-reference to INTAKE §8 Walkthrough Cap N1 row + pack memory `feedback_pattern_matching_out_of_context_antipattern`.
- (b) Leave PLANNING-PROCESS-INSIGHTS-FROM-OT.md as-is (it self-frames informative; preserves audit-trail of the architect's pre-walkthrough recommendation) but add a defensive note to INTAKE §8 Walkthrough Cap N1 row OR REQUIREMENTS Cap N1 Rationale making the supersedence explicit (already partially done; REQUIREMENTS Cap N1 says "PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 (originally recommended per-stream-tree; walkthrough refined to architect-decides)" line 322).
- The REQUIREMENTS Cap N1 cross-reference at line 322 already does (b). Whether to ALSO patch PLANNING-PROCESS-INSIGHTS-FROM-OT.md (per (a)) is a judgment call. Defensible to leave alone since the IMPL-REPORTs preserve the audit trail of the reversal; defensible to patch since the source doc misleads on first read.

---

### M-8. PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.2 recommends splitting #11 (research orchestration) into N7a + N7b; INTAKE §8 Walkthrough §6 sub-decision Sub-E REJECTS the split ("E3 — DON'T PRESCRIBE"); the source doc stays with the split recommendation

**Class:** Conflicting part (same shape as M-7; source doc not updated after walkthrough decision).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §6.2 line 439 (recommends "Capability #N7a: Initial product-discovery research" + "Capability #N7b: Per-feature research orchestration"); `INTAKE-PS-V11.md` §8 Sub-E line 456 ("Research orchestration shape (E3 — DON'T PRESCRIBE). Original Capability #11 (Research orchestration) stays as a single capability in the preliminary list with NO prescribed restructure.").
**Actual content.** PLANNING-PROCESS-INSIGHTS-FROM-OT.md proposes a split; the walkthrough explicitly rejects prescribing the split and leaves the shape to the architect. REQUIREMENTS Cap #11 captures the don't-prescribe stance.
**Why MUST.** Same pattern as M-7: architect reading PLANNING-PROCESS-INSIGHTS-FROM-OT.md first may think the split is recommended; the walkthrough leaves it open. REQUIREMENTS Cap #11 Rationale at line 602 partially mitigates ("Shape architect-decides per §6 E3 (don't prescribe split vs single vs sub-decomposition vs skill-form)") but the source doc is the FIRST thing the architect-investigation cross-reference at REQUIREMENTS line 604 sends them to. They'll arrive at PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 E3 — which IS the don't-prescribe text — but the §6.2 split-into-N7a+N7b is text on the same page that contradicts.
**Recommended fix shape.** Same options as M-7. Add SUPERSEDED note to PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.2 N7a/N7b paragraph; OR leave alone with REQUIREMENTS Cap #11 carrying the cross-reference.

---

### M-9. PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 proposes 7-item completeness bar; INTAKE §8 Walkthrough Cap #6 EXTENDS to 8-item bar (adding Priorities Item 8); REQUIREMENTS §7 ships the 8-item bar — but PLANNING-PROCESS-INSIGHTS-FROM-OT.md still says 7-item

**Class:** Conflicting part (same pattern as M-7/M-8; less consequential since the extension is additive, not a reversal).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §6.4 line 465-474 (7-item bar list).
**Actual content.** PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 lists 7 items (vision/pillars; anti-pillars; audience; MVP-scope clusters; NFRs; seams; conditional-inclusions). INTAKE §8 Walkthrough Cap #6 row (line 504) refines to 8-item bar adding "Priorities elicited (multi-axis per Goal 17)" as Item 8. REQUIREMENTS §7 ships the 8-item bar with Item 8 priorities (line 974).
**Why MUST.** The architect-investigation cross-reference at REQUIREMENTS Cap #6 cites PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 as starting evidence. The architect reads §6.4 first and sees 7 items; reads REQUIREMENTS §7 next and sees 8 items. Without explicit cross-reference noting the extension, the architect has to infer where the 8th came from.
**Why MUST not BLOCKER.** The 8th-item extension is additive and the cross-doc references in REQUIREMENTS Cap #6 + §7 are crisp ("PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 (7-item bar) + walkthrough refinement adding Item 8"). The architect will see this on first read.
**Recommended fix shape.** Add an inline note in PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.4 after the 7-item list: "*Extended to 8-item bar (adding Item 8 — Priorities elicited per Goal 17) per INTAKE §8 Walkthrough refinement, user-approved 2026-05-24.*"


---

## §5 — SHOULD findings

### S-1. REQUIREMENTS-PS-V11.md §10 Decision count vs HANDOFF's commitment to "30 decisions" is internally consistent but the consistency mask hides M-5

**Class:** Confusion (count-consistency masks a content issue).
**File + location:** `REQUIREMENTS-PS-V11.md` lines 1078-1144 (§10); `HANDOFF-PS-ARCHITECT.md` line 24 ("Lock the 30 open architect decisions enumerated at `REQUIREMENTS-PS-V11.md` §10"); HANDOFF line 39 ("§10 consolidated list of 30 open architect decisions").
**Actual content.** Both docs say 30; §10 has 30 numbered items. The count is consistent. M-5 reveals that one of the 30 (Decision #30) is not architect-actionable. SHOULD-finding here flags the COUNT-CONSISTENCY-DOESN'T-MEAN-CONTENT-CORRECTNESS pattern: future drift can produce 30 entries where one or more are non-actionable while the count claim still passes mechanical verification.
**Why SHOULD.** Not actionable independently of M-5; offered as INFO observation for triage.
**Recommended fix shape.** Resolved by M-5 fix.

---

### S-2. Capability cluster cluster-totals consistency between INTAKE §8 Walkthrough, REQUIREMENTS §4, and HANDOFF §2 — all agree on 21 — but PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 final-count table lacks Cap N8

**Class:** Conflicting part / stale (less consequential because the reclustering table is informative).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §6.3 lines 448-454 (cluster table); says total 21 in line 456 but the table itself has 17 (#1-#17 mapped with restructuring) + N1/N2/N3/N4/N5/N6/N7a/N7b = 8 from architect proposals (per §6.1+§6.2). N7a+N7b later overridden to "stay single Cap #11"; N8 added in walkthrough Cluster 6 (post-architect-pass). So PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 total of 21 is COINCIDENTALLY equal to the final walkthrough count, but the COMPOSITION differs (architect proposed N7a+N7b which would give 22; walkthrough kept #11 single + added N8 which lands at 21 differently).
**Why SHOULD.** PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 was written PRE-walkthrough. The "Final count after amendments: 21" is the architect's pre-walkthrough estimate, not the post-walkthrough actual. The composition has shifted but the count was preserved by coincidence (architect added 2 via N7-split; walkthrough preserved 1 (no split) and added 1 (N8)). A reader doing capability arithmetic from PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 will get a slightly different mental model from REQUIREMENTS §4.
**Why SHOULD not MUST.** REQUIREMENTS §4 is the canonical capability list per its own preamble. PLANNING-PROCESS-INSIGHTS-FROM-OT.md self-frames as informative. Risk is low. Surfacing for thoroughness.
**Recommended fix shape.** Add a footnote to PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 table: "*Post-walkthrough composition (per INTAKE §8 Walkthrough Cluster summary) differs slightly: #11 not split per Sub-E E3; Cap N8 added per Cluster 6 (Goal 19). Final count still 21.*"

---

### S-3. RESEARCH §6.11 Wave taxonomy (1/2/3) is paraphrased from trade-press; REQUIREMENTS §9 + INTAKE §9 (Goal 13) treats Wave 2 / Wave 3 as locked categories

**Class:** Confusion (foundational concept lacks named source).
**File + location:** `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §6.11 (lines 683-693); `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §3 Verification step 7 ("The 'Wave 1/2/3' framing in §6.11 is paraphrased from multiple trade-press sources; the specific phrasing ... is taken from the cited trade-press article. Honest framing: this is a popular framing, not a peer-reviewed taxonomy.").
**Actual content.** Wave 1 / Wave 2 / Wave 3 / Goal 13 (Wave 2 only; Wave 3 OUT) anchors C6 — a LOCKED user-stated constraint. The constraint relies on a trade-press taxonomy. RESEARCH itself is honest about the framing's non-peer-reviewed status, but the downstream consumers (INTAKE Goal 13; REQUIREMENTS C6; HANDOFF §3 + §8) lean on the taxonomy as if it were canonical.
**Why SHOULD.** The architect will challenge "Wave 3 OUT" at the design pass. C6 is user-locked, so the challenge bar is HIGH per `feedback_user_prescriptive_authority` (challenge requires user-discussion-and-approval). But the architect needs to understand that "Wave 3" is a taxonomy artifact, not an authoritative classification. A boundary like "PS scaffolds + facilitates + audits + renders; PS does not replace the PM role" (REQUIREMENTS §3.6 C6 implication) is more defensible than "Wave 3 OUT" because it names the actual mechanism, not the taxonomy.
**Recommended fix shape.** This may be downstream architect work — the architect's job to refine the "what does Wave 3 mean concretely" framing during design pass. Could be flagged here for awareness rather than fixed in the requirements artifacts; the IMPL-REPORT (research) already carries the honest framing.

---

### S-4. REQUIREMENTS Cap N5 SC N5.3 references "`[F-NEW]`-equivalent feature-touchpoint markers" — `[F-NEW]` is OT-specific notation

**Class:** Confusion (terminology imported from OT context without renaming).
**File + location:** `REQUIREMENTS-PS-V11.md` line 531 (Cap N5 SC N5.3: "Journey steps are numbered + carry `[F-NEW]`-equivalent feature-touchpoint markers cross-referencing N6 feature inventory rows.").
**Actual content.** `[F-NEW]` is OT Phase B.1's notation per PLANNING-PROCESS-INSIGHTS-FROM-OT.md §2 (OT directory overview, line 50: "Mode classification; `[F-NEW]` feature-touchpoint markers; provisional-vocabulary discipline"). The PS template is supposed to be pack-target (NOT OT-specific) per Cap N5 walkthrough notes (INTAKE §8 line 508: "Mode-classification scheme for pack-target audience architect-decided (OT's Building/Discovery/Recovery/Setup is OT-specific; pack-target may need different modes)"). Yet the SC retains the OT-specific notation.
**Why SHOULD.** The "`[F-NEW]`-equivalent" framing tries to abstract; "equivalent" signals that the architect should pick PS-appropriate notation. But a reader unfamiliar with OT won't know what `[F-NEW]` actually means without cross-referencing PLANNING-PROCESS-INSIGHTS-FROM-OT.md. Less elegant than naming the concept ("feature-touchpoint markers cross-referencing N6 feature inventory rows by `feature_id`") and dropping the OT artifact.
**Recommended fix shape.** Rewrite SC N5.3 to drop `[F-NEW]` reference. Example: "Journey steps are numbered + carry feature-touchpoint markers cross-referencing N6 feature inventory rows (architect picks marker notation; OT's `[F-NEW]` is an exemplar)."

---

### S-5. HANDOFF §3 (locked methodology defaults) duplicates content already in REQUIREMENTS §2 + §3.5

**Class:** Confusion (duplication risks drift if either copy is edited).
**File + location:** `HANDOFF-PS-ARCHITECT.md` line 78 ("Methodology defensible defaults (LOCKED per RESEARCH §9.5; `REQUIREMENTS-PS-V11.md` §2 + §3.5): Continuous Discovery (Torres) / Opportunity-Solution Tree; Mom Test + past-behavior focus; Lean Canvas OR PR/FAQ; RICE or Value/Effort (default), Kano (delight); common-denominator 8-section PRD; North Star + OKRs; JTBD-Christensen (over persona); Cagan vocabulary (problems-to-solve / outcomes-over-outputs). Defaults are LOCKED; per-project override mechanism is yours to design (Decision #9 in §10).").
**Actual content.** REQUIREMENTS §2 has a methodology-defaults table (lines 94-105). REQUIREMENTS §3.5 C5 also cites the defaults. HANDOFF §3 enumerates the same defaults. RESEARCH §9.5 is the actual canonical source.
**Why SHOULD.** HANDOFF self-frames as "navigation + framing — it does not duplicate content from the artifacts" (line 28). The methodology defaults paragraph IS a duplicate. Drift risk: if architect challenges a default during design pass and Pack Chat updates REQUIREMENTS, HANDOFF's copy may not update.
**Recommended fix shape.** Replace the in-line list in HANDOFF §3 with a pointer-only: "Methodology defensible defaults (LOCKED per RESEARCH §9.5; see REQUIREMENTS-PS-V11.md §2 + §3.5 for the canonical table)." Loses immediate readability; gains drift resistance.

---

### S-6. INTAKE §8 "Walkthrough results" subsection refers to "Goal 19" in the Cap N8 row + cross-references SC13, all before §9.5 (Goal 19 full statement) appears in the doc

**Class:** Confusion (forward reference within a doc; resolves on second read but jarring on first).
**File + location:** `INTAKE-PS-V11.md` §8 line 512 (Cap N8 row, mentions "Per Goal 19. BACKLOG-side capture at BD-191 SC13."); §9.5 Goal 19 statement (line 650).
**Actual content.** The Walkthrough results subsection at INTAKE §8 references "Goal 19" before §9.5 (where Goal 19 is defined) is reached. This is technically a forward reference; a first-time reader sees "Goal 19" in §8 line 512 without having read §9.5 yet.
**Why SHOULD.** Forward references aren't errors; they're stylistic. They work fine on second read. But the INTAKE doc's verbal flow is §1 → §2 → ... → §8 → §9 → §10; an architect reading sequentially encounters Goal 19 in §8 before §9. The compound nature of post-hoc additions (Goal 19 was authored after §8 was already long) made this forward reference; it can be improved with a brief sentence in §8 walkthrough flagging the forward jump.
**Recommended fix shape.** Add a one-line note in §8 Walkthrough results preamble: "Goal 19 (referenced in Cap N8 row below) is defined at §9.5 — full statement and rationale appear there."

---

### S-7. REQUIREMENTS §4 Cap entries follow a 9-field per-cap entry shape ("Capability ID + name; Problem; Goals; Success Criteria; Disposition; Scope verdict; Rationale; Cross-references; Architect bar; Preliminary disclaimer") — but the §4 preamble lists 8 fields not 9

**Class:** Error (preamble count mismatch with body).
**File + location:** `REQUIREMENTS-PS-V11.md` lines 206-216 ("Per-capability entry shape: ...").
**Actual content.** Preamble lists Capability ID + name; Problem; Goals; Success Criteria; Disposition; Scope verdict; Rationale; Cross-references; Architect bar; Preliminary disclaimer — 10 items in fact. But the body uses 9 (the "Capability ID + name" is in the heading, not a separate field). The disclaimer "Preliminary; subject to architect challenge..." is at the bottom of each entry but is structurally distinct from the 9 content fields. Let me re-count: the preamble bullet list has 10 items (lines 207-216); each capability body has ID-in-heading + Problem + Goals + Success Criteria + Disposition + Scope verdict + Rationale + Cross-references + Architect bar + Preliminary disclaimer = 10. Match.
**Why SHOULD (rather than no-finding).** The preamble bullet list at lines 206-216 is 10 items but the IMPLEMENTATION-REPORT-REQUIREMENTS-PS-V11.md §4 SC5 says "Each capability entry has all required fields" then lists 10 bullets in its check (lines 232-242). The mismatch is between my own counting in initial review (9 vs 10) — the SHOULD-finding is "the preamble doesn't say HOW MANY fields are required; readers count by hand". A small clarity improvement could prefix "Per-capability entry shape (10 fields):".
**Why SHOULD not NIT.** Verifiable claim that helps the architect and reviewer (who needs to confirm every cap entry is complete) — small but useful.
**Recommended fix shape.** Add "(10 fields)" or similar to the §4 preamble line 206 OR re-organize the bullet list to make the field count visually obvious. Minor.

---

### S-8. RESEARCH IMPL-REPORT §5 open questions include "Productboard AI / Aha! AI / Linear Agent feature parity ... evolving fast (2025-2026 quarterly releases) ... should be revalidated before any design decisions" — not surfaced in HANDOFF or REQUIREMENTS

**Class:** Omission (architect-actionable item buried in IMPL-REPORT).
**File + location:** `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §5 (lines 141-152).
**Actual content.** The research IMPL-REPORT explicitly flags 7 open questions for downstream architects; #3 says "Productboard AI / Aha! AI / Linear Agent feature parity ... should be revalidated before any design decisions; specific feature claims may already be stale by the next major release cycle." These are real architect-pass risks (the research is dated 2026-05-21 to 2026-05-24; the architect may pick up months later when the landscape has moved).
**Why SHOULD.** Linked to M-4 (HANDOFF doesn't reference IMPL-REPORTs in reading order). If M-4 is fixed (architect reads IMPL-REPORT), these get surfaced. If not, they don't.
**Recommended fix shape.** Resolved by M-4 fix. Alternatively: add a short "Open architect-investigation items from IMPL-REPORTs" subsection to HANDOFF §4 enumerating the high-signal items from research IMPL-REPORT §5 + planning-process IMPL-REPORT §4.

---

### S-9. PLANNING-PROCESS-INSIGHTS-FROM-OT.md §8.1 Q1 — "Phase-level dependency cycle detection — does it already exist in validate-pack?" — is flagged as architect-investigation but the §5.1 amendment to REQUIREMENTS-GROUPINGS-V11.md SC13.22 ASSUMES it doesn't exist (asks for "3rd new mandatory check")

**Class:** Confusion (architect-investigation precondition not resolved at amendment time).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §8.1 Q1 (line 528: "**Phase-level dependency cycle detection — does it already exist in validate-pack?** Capability #13 SC13.X (§5.1) assumes the check is new. Verify: does validate-pack already detect cycles in phase Blockers/Unblocks?"); `REQUIREMENTS-GROUPINGS-V11.md` line 642 ("3 new mandatory checks ... `check_grouping_phase_dependency_cycles` per SC13.22 / §5.1 amendment").
**Actual content.** The architect's investigation question Q1 should resolve BEFORE the amendment claims "new check". The amendment says NEW; the unanswered question says MAYBE-EXISTS. The IMPL-REPORT-GROUPINGS-AMENDMENT-5-1.md does NOT resolve Q1 either — it just applies the amendment as authored.
**Why SHOULD.** Real risk: if validate-pack already has phase-level cycle detection somewhere (it has graph-walking logic in BD-070 typed-error contract; likely related), the SC13.22 "new check" claim may be inaccurate or redundant. The groupings architect (v11.1+) will resolve this at design time.
**Recommended fix shape.** Either:
- (a) Adjust SC13.22 wording to be conditional: "Add cycle-detection check (or apply existing cycle detection in validate-pack to grouping-membership context — architect verifies which during design pass; absent existing infrastructure, this is a new mandatory check; if existing infrastructure is found, this scopes to apply-to-grouping-context only)."
- (b) Surface as explicit architect-investigation item in HANDOFF-V11.1-ARCHITECT.md (already done partially per HANDOFF-V11.1-ARCHITECT.md line 53 "algorithm choice (Tarjan SCC vs alternative ...)") — but the "does it already exist" question is not the algorithm-choice question; it's the new-vs-existing question.


---

## §6 — NIT findings

### N-1. INTAKE §9.6 mapping table only binds Goals 16/17/18/19 to BD-191 SCs as "added 2026-05-24" — Goals 1-15 in the table mostly say "Direct binding" without explicit date

**Class:** Confusion (asymmetric date annotation makes Goals 16-19 stand out as if newer-status than the others).
**File + location:** `INTAKE-PS-V11.md` §9.6 lines 682-700.
**Actual content.** Notes column for Goal 17 says "Direct binding (added 2026-05-24)"; Goal 18 says "Direct binding (added 2026-05-24); PS-side mechanism captured in BD-191 SC12"; Goal 19 says "Direct binding (added 2026-05-24); implementing capability Cap N8". The "added" date marks WHEN the GOAL itself was added to the doc. Goals 1-15 don't carry the same annotation because they were in §1-§8 from the start.
**Why NIT.** Mild reading-pattern artifact; doesn't actively mislead. The annotation is meaningful audit-trail (when the goal entered the index) but reads as if Goals 1-15 are pre-2026-05-24 while 16-19 are 2026-05-24 additions to the canonical-capture set.
**Recommended fix shape.** No edit required. INFO-level observation; if Pack-Chat triage decides to clean, harmonize all rows to either annotate dates or drop annotations.

---

### N-2. REQUIREMENTS §11.1 reading order says "INTAKE-PS-V11.md (consulted for ... §9 19 goals full statements)" — but only Goals 16/17/18/19 have full statements in INTAKE §9; Goals 1-15 are reference-only

**Class:** Error (mild; misrepresents what reader will find).
**File + location:** `REQUIREMENTS-PS-V11.md` line 1155.
**Actual content.** INTAKE §9 has 19 goal rows in the index table (§9.1). The "full statements" appear ONLY in §9.2 (Goal 16) / §9.3 (Goal 17) / §9.4 (Goal 18) / §9.5 (Goal 19) — that's 4 full statements. Goals 1-15 are "cross-references to existing source in this doc (and adjacent docs)" per INTAKE §9 preamble (which itself contains the B-1 stale "17" claim). Saying "§9 19 goals full statements" implies all 19 have full statements; only 4 do.
**Why NIT.** A pedantically accurate phrasing matters less here because the reader who lands on INTAKE §9 will quickly see the layout (index table + 4 full-statement sub-sections + mapping table). But the claim mis-frames the SSOT pattern.
**Recommended fix shape.** Reword to "INTAKE-PS-V11.md ... §9 19-goal index with Goals 16/17/18/19 full statements + Goals 1-15 cross-references." Minor.

---

### N-3. HANDOFF-PS-ARCHITECT.md §6 LOW vs HIGH worked examples don't include Cap #2 (two modes), Cap #14 (PRD-to-code traceability), or Cap #16 (PRD lifecycle)

**Class:** Omission (worked examples are not exhaustive; selective).
**File + location:** `HANDOFF-PS-ARCHITECT.md` lines 123-125.
**Actual content.** "LOW — Caps #4 / #5 / #6 / #7 / N3 / N4 / N5 / N6 / N8" — covers interview-cluster + deliverables-cluster but skips Cap #2, #14, #16 which are also LOW per REQUIREMENTS-PS-V11.md Architect bar tags. "HIGH — Caps #1 / #13 / #15 / N1" — covers most HIGH-bar caps but #1 is tagged "LOW (PS-internal agent topology decision)" in REQUIREMENTS line 243, not HIGH. The HANDOFF and REQUIREMENTS disagree on #1's bar.
**Why NIT.** Minor categorization inconsistency. HANDOFF examples are illustrative not exhaustive. The #1 LOW vs HIGH disagreement is real (REQUIREMENTS Cap #1 Architect bar line 243 says LOW; HANDOFF §6 example uses #1 as HIGH).
**Recommended fix shape.** Reconcile #1's bar. If LOW (PS-internal agent topology), remove from HANDOFF §6 HIGH examples. If HIGH (CLIENT-SIDE-ONLY structural enforcement is part of #1 per Cap #1 SC1.3), update REQUIREMENTS Cap #1 Architect bar.

---

### N-4. INTAKE §8 "17 capabilities total — coincidentally matches BD-186's 17-capability count" — now stale after walkthrough added Cap N8 / restructured to 21

**Class:** Confusion (stale comment about coincidence between PS and groupings cap counts).
**File + location:** `INTAKE-PS-V11.md` line 436.
**Actual content.** The original §8 had 17 capabilities; the walkthrough now puts it at 21. The line 436 "coincidentally matches BD-186's 17-capability count" is no longer true (PS has 21 caps; groupings still has 17). But this line is inside the ORIGINAL §8 cluster summary, which the IMPL-REPORTs explicitly preserve as audit-trail ("Original §8 capability list preserved unchanged for audit-trail"). So the stale line is actually a stable audit-trail artifact.
**Why NIT.** The audit-trail preservation pattern is legitimate but creates this drift. The stale claim is contained within the audit-trail and immediately followed by "Preliminary §6 sub-decision results" subsection (line 438+) which states the new count.
**Recommended fix shape.** Option A: append a single line after line 436 saying "(Updated post-walkthrough: 21 capabilities total; see Walkthrough results subsection below.)". Option B: leave as-is per audit-trail preservation.

---

### N-5. PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.3 says "Final count after amendments: 21 capabilities (up from 17) — but the increase reflects ... restructuring" — but the WALKTHROUGH composition differs from the §6.3 composition

**Class:** Confusion (count match by coincidence, not by composition match — surfaced separately from S-2 because §6.3 emphatic framing makes this read as authoritative).
**File + location:** `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` line 456.
**Why NIT (and what's the relation to S-2).** S-2 surfaces this same fact at SHOULD severity. NIT-version surfaces the textual emphasis ("Final count: 21") which a reader anchors on. The "final" claim is what makes it stand out.
**Recommended fix shape.** Same as S-2.

---

### N-6. RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md §6.13 ("Cross-CLI coding-agent landscape") is included in research but not referenced by any downstream PS artifact

**Class:** Omission (research content goes unused) OR INFO (was research-scope thoroughness).
**File + location:** `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` §6.13 (lines 700-712).
**Actual content.** §6.13 covers Claude Code / Codex CLI / Gemini CLI comparison — pack-adjacent reference. The research IMPL-REPORT §1.5 notes "Cross-CLI parity questions for the PS feature ... PS is project-template/ surface (per INTAKE-PS-V11.md §1 user direction); trinity rule applies. I did not investigate per-CLI parity implications of PS deliverables in depth — that's an architect surface."
**Why NIT.** Cross-CLI parity is real architect concern but not yet surfaced in REQUIREMENTS or HANDOFF. The research §6.13 content is reference-only at this stage; the architect will need it when designing per-CLI agent files for PS.
**Recommended fix shape.** Add a brief reference to per-CLI parity (Check 27 trinity rule) in REQUIREMENTS Cap #15 (workflow + doc integration) — already partially done at SC15.4 ("New agent / skill file additions satisfy per-CLI parity (Check 27)"). Minor: cross-reference §6.13 from Cap #15 rationale or footnote.

---

### N-7. Multiple IMPL-REPORTs note "Pack Chat to determine whether [BACKLOG.md edits are] in the same commit or a separate one" — uncertainty about commit grouping is not actionable architect content

**Class:** INFO (audit-trail of coder ambiguity).
**File + location:** Multiple IMPL-REPORTs.
**Why NIT.** Coder-side commit-grouping uncertainty is Pack Chat's concern. Not architect-actionable. Noted as INFO.

---

### N-8. HANDOFF-PS-ARCHITECT.md §10 "downstream BDs" list uses "BD-NNN" placeholder without naming a specific scheduling — fine for handoff doc but worth flagging

**Class:** INFO.
**File + location:** `HANDOFF-PS-ARCHITECT.md` lines 215-219.
**Why NIT.** Placeholder BD-NNN is correct (BDs open later via Pack Chat triage); not actionable.

---

## §7 — INFO observations

### I-1. The 16-doc audit-trail set demonstrates the audit-trail-distillation pattern at scale

INTAKE captures verbatim user intent + Pack-Chat triage; RESEARCH captures landscape facts; PLANNING-PROCESS-INSIGHTS captures architect-pattern synthesis; REQUIREMENTS distills all 3 into formal capability spec; HANDOFF wraps REQUIREMENTS with navigation + framing + discipline. The 7 IMPL-REPORTs preserve per-pass methodology + open questions + verification. Across these 16 artifacts, ~10000+ lines of structured content support a single feature requirement gathering — the BD-191 sidecar produced more material than most pack BDs of equivalent scope. The discipline pattern works: BLOCKER + MUST findings in this audit are all "small stale-text drift" issues, not "fundamental design contradictions" issues.

### I-2. The architect-challenge-discipline framing (`feedback_preliminary_triage_architect_challenge`) appears consistently across all 5 primary docs (INTAKE / REQUIREMENTS / HANDOFF / PLANNING-PROCESS-INSIGHTS / RESEARCH IMPL-REPORT)

The preliminary disclaimer is applied at: REQUIREMENTS §1 (doc-level) + every capability entry (22 occurrences); HANDOFF §1 (doc-level) + §3 + §6 + §11.4; INTAKE §8 Walkthrough results preamble + each new addition (§9.4 Goal 18 disclaimer; §9.5 Goal 19 disclaimer; §6 sub-decision results); PLANNING-PROCESS-INSIGHTS §1 (informative not prescriptive framing). The cross-doc consistency is high. Architect challenges to LOCKED constraints (C1-C7; user-locked goals) are explicitly gated on user-discussion-and-approval per `feedback_user_prescriptive_authority`. This is a healthy disciplinary structure.

### I-3. The tiered challenge bar (LOW vs HIGH) is applied consistently across REQUIREMENTS Cap entries and HANDOFF §3/§4/§6

LOW (PS-internal) vs HIGH (boundary-with-existing-pack) is consistent in semantics. Per-capability Architect-bar tags align with the HIGH/LOW categorization. The audit found one minor inconsistency (N-3 Cap #1 LOW vs HIGH) but the framework itself is sound.

### I-4. The PS-to-groupings cross-feature integration is the highest-coherence load-bearing element of the artifact set

Goal 18 / C7 / Cap #13 / BD-191 SC12 / REQUIREMENTS-GROUPINGS Cap #7 SC7.8 / HANDOFF §7 / §5 cross-feature integration — these 6+ surfaces all reference each other consistently. The IMPL-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md "Goal 18 cross-reference consistency check" at line 272 explicitly verifies the cross-reference set. The cross-feature contract is the design's strongest single design-coherence element.

### I-5. The `[F-NEW]` notation in REQUIREMENTS Cap N5 SC N5.3 (S-4) signals a small import-from-OT-without-rename pattern that the architect should de-couple

OT-specific notation in PS-spec docs is fine where the OT analog is named explicitly ("Mirrors OT Phase E.1" — fine). It is less fine where the notation is treated as a generic pack concept ("`[F-NEW]`-equivalent feature-touchpoint markers"). S-4 is the only instance I found; future architect should sweep PS templates for similar artifacts.

### I-6. RESEARCH §10.2 source URL list dates "live 2026-05-21 through 2026-05-24" (about 1 day pre-audit) — at architect design time, the architect should plan re-verification per RESEARCH IMPL-REPORT §5 open questions

This is downstream timing (architect picks up when scheduled). Surfacing as INFO observation per the parallel commentary at S-3 (Wave taxonomy freshness) and S-8 (Productboard AI / Aha! AI / Linear Agent feature parity freshness).

### I-7. The "BD-190 vs BD-191 renumbering" history (per BACKLOG.md "BD numbering history" note + INTAKE editorial note line 13) is preserved as audit-trail; the renumbering itself was clean

No audit finding required; the discipline pattern (read live BACKLOG before assigning BD-NNN) is preserved per pack memory `reference_pack_backlog_structure`.


---

## §8 — Cross-cutting observations

### O-1. Sequential-addition drift pattern

Goals 16 and 17 were added in one IMPL pass; Goal 18 was added in another; Goal 19 was added in a third. Each pass updated the table content correctly but did NOT consistently update the INTRODUCTORY claims (the preamble at §9 line 540-541 and §9.1 line 547 still say "17"). This is the source of B-1, B-2, B-3, and N-2 — all are different surface manifestations of the same root cause (preamble stale because later additions touched only table rows). The pattern signals an authoring discipline gap: when adding a goal/SC/capability, the contributor should sweep upstream references in the same pass.

### O-2. Source-doc-not-updated-when-walkthrough-overrides pattern

M-7 (N1 per-stream-tree), M-8 (#11 N7a+N7b split), M-9 (7-item bar extended to 8) — these are 3 instances of the same pattern: an architect doc (PLANNING-PROCESS-INSIGHTS-FROM-OT.md) made a recommendation; the walkthrough modified that recommendation; the source doc was not patched with a "SUPERSEDED" or "REVISED" note. The downstream REQUIREMENTS doc captures the post-walkthrough decision, so the practical risk is contained — but readers landing on the source doc first will see the original recommendation without seeing the override unless they cross-reference REQUIREMENTS. Defensible to leave the source doc as audit-trail; defensible to patch with override notes. Architect/Pack-Chat triage decides.

### O-3. Cross-cutting principle vs locked constraint distinction is implicit, not explicit

M-3 / M-6 surface that "locked goals" (HANDOFF §3) and "cross-cutting principles" (REQUIREMENTS §2) and "user-stated constraints C1-C7" (REQUIREMENTS §3) are three categorical labels with partial overlap. A reader has to infer the relationships. This is the design's most-confusion-prone surface — explicit definitions of each category would materially help downstream architect navigation.

### O-4. Audit-trail preservation discipline creates expected staleness

INTAKE §8 original 17-capability list is preserved unchanged ("Original §8 capability list preserved unchanged for audit-trail" — INTAKE line 442); the Walkthrough results subsection then OVERRIDES. This is a healthy audit-trail pattern — the original signals what was on the table before; the walkthrough signals what was approved. NIT-finding N-4 names this; the pattern itself is correct. Worth surfacing as a cross-cutting observation: where the audit-trail discipline says "preserve original," downstream consumers must read the override sections (Walkthrough results; §6 sub-decision results) to get current state.

### O-5. Forward references and dated annotations cluster around Goals 16-19

INTAKE §9.6 mapping table rows for Goals 17/18/19 carry "(added 2026-05-24)" annotations (N-1); INTAKE §8 Walkthrough Cap N8 references Goal 19 before §9.5 defines it (S-6); REQUIREMENTS §10 Decision #30 is HANDOFF-authoring already-done by Pack Chat (M-5); HANDOFF §3 lists Goal 14 locked-but-not-C-anchored (M-6). The cluster of small-staleness findings around late-added Goals 16-19 is the strongest signal that the late-addition discipline could be tightened.

### O-6. The IMPL-REPORTs are the strongest single-doc-class for design-coherence audit

Every IMPL-REPORT carries: methodology + sources + verification commands + SC mapping + open questions + boundary discipline check + DoD checklist + PREFLIGHT confirmation. These metadata-rich docs make the audit possible — without them I would have had to reconstruct the authoring sequence from git log + cross-doc reference walks. The IMPL-REPORT discipline is load-bearing for audits like this; M-4 (HANDOFF doesn't reference IMPL-REPORTs in reading order) is the highest-impact MUST-finding because the IMPL-REPORTs would otherwise go unread.

### O-7. The Wave 2 / Wave 3 boundary anchors a user-locked constraint but rests on trade-press taxonomy

S-3 surfaces the foundational concern: C6 "Wave 3 OUT" is anchored to RESEARCH §6.11 trade-press paraphrase. The research IMPL-REPORT honestly notes this. The architect can stress-test the constraint by rewriting C6 in mechanism-terms (what PS does vs what PS doesn't), not taxonomy-terms (Wave 2 vs Wave 3). This is downstream architect work, not a fix for THIS audit cycle.

---

## §9 — Next steps for Pack Chat

### Recommended triage ordering

**Priority 1 — BLOCKER fixes (B-1 / B-2 / B-3).** All three are mechanical text updates to `INTAKE-PS-V11.md`. Fix-coder agent should batch these into a single fix commit (small scope; clean diff). After fix, re-verify the goal-count claim across all 4 primary docs (INTAKE / REQUIREMENTS / HANDOFF / PLANNING-PROCESS-INSIGHTS) is consistent at "19".

**Priority 2 — MUST findings requiring user discussion.** M-3 / M-6 (locked-goals vs cross-cutting-principles definitional clarity) are design-meta decisions. Pack Chat should surface to user for definitional preference before fix-coder spawns. M-1 (§9.x anchor collision) has two plausible fix shapes; user decides which. M-7 / M-8 / M-9 (source-doc-supersedence patches) are stylistic — user may decide to patch PLANNING-PROCESS-INSIGHTS-FROM-OT.md OR rely on REQUIREMENTS' cross-references.

**Priority 3 — MUST findings with single clear fix shape.** M-2 (auto-resolved by B-1 fix; verification step). M-4 (add IMPL-REPORTs to HANDOFF §2 reading order). M-5 (rewrite REQUIREMENTS §10 Decision #30 to architect-actionable scope).

**Priority 4 — SHOULD findings.** S-1 / S-2 / S-3 / S-4 / S-5 / S-6 / S-7 / S-8 / S-9. Default fix-all per `feedback_fix_all_review_findings`; user discussion only for SHOULDs Pack Chat triage flags as needing input.

**Priority 5 — NIT findings.** N-1 through N-8. Default fix-all; small mechanical changes; one fix-coder commit can batch.

### Triage-gate prompts

Before spawning fix-coder, Pack Chat should surface to user:
- B-1 / B-2 / B-3 fix-shape confirmation (mechanical text updates; show user the proposed text changes).
- M-1 fix-direction choice (rename §5 sub-anchors vs renumber §9 sub-anchors).
- M-3 / M-6 definitional approach (add §3-preamble explaining categories vs restructure constraint list).
- M-5 Decision #30 disposition (remove vs rewrite vs leave as INFO).
- M-7 / M-8 / M-9 source-doc-patch decisions.

### Parallel-reviewer reconciliation

The parallel pack-reviewer pass (running concurrently) covers technical-discipline compliance. Pack Chat should read both reports side-by-side. Likely-overlap findings: cross-reference integrity (this audit's B-1 / B-2 / B-3 may overlap with reviewer's cross-ref checks); severity classification methodology; per-stream-tree contract (this audit's M-1 §9.x anchor collision may overlap with reviewer's anchor-uniqueness checks). Where overlap exists, pick the more thorough framing; do not double-count.

### Post-fix verification

After all approved fixes land, re-run the audit-coverage spot checks:
- INTAKE §9 + §9.1 preambles say "19 goals" / "19 entries" (B-1)
- INTAKE §9.6 preamble says "SC1-SC13" (B-2)
- INTAKE §10 uses past-tense for REQUIREMENTS-PS-V11.md (B-3)
- HANDOFF §2 references IMPL-REPORTs in reading order (M-4)
- REQUIREMENTS §10 Decision #30 is architect-actionable or removed (M-5)
- (Optional) PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6.1 / §6.2 / §6.4 carry supersedence notes (M-7 / M-8 / M-9)

### BD-191 close-out readiness

After Priority 1-3 fixes land, BD-191 is ready to flip to Resolved per `feedback_implicit_status_flip` (per `REQUIREMENTS-PS-V11.md §11.5` close-out protocol). Priority 4-5 findings can defer to post-close-out if user triage explicitly authorizes (per `feedback_no_deferral_without_user_direction`); else they land in the same commit batch.

---

End of AUDIT-PS-FULL-SESSION-ARCHITECT.md.
