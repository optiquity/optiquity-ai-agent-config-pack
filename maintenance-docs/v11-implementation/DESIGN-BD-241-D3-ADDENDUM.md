# DESIGN-BD-241-D3-ADDENDUM — Reconciliation-instance independence (codification across C=both: BD-241 surfaces now + BD-238/239 handoff)

**Agent:** pack-architect (READ-ONLY, FRESH/INDEPENDENT D3 pass — empty context;
neither the BD-241 original author nor its adversarial reviewer). · **Date:** 2026-06-20
**Tree/HEAD (verified at runtime):** MAIN checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`,
HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` (`git rev-parse HEAD`), clean tree
(`git status --short` empty).
**EXTENDS (does NOT supersede, does NOT re-open):**
`/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-RECONCILED.md` (the settled BD-241 design —
its 6 verified-correct decisions, its two new rules `spawn-unique-naming` /
`spawn-registry-find`, its propagation tables, and its rule-10 map are TREATED AS FIXED
INPUTS here, not re-decided).
**Scope (user direction 2026-06-20):** codify ONE new rule —
**Reconciliation-instance independence** — across **C = BOTH**: (a) the pipeline-standard
homes (BD-238 pack-side / BD-239 project-side) — HANDOFF SPEC; and (b) BD-241 (the
agent-REUSE angle, carrying the user-`SendMessage` carve-out) — DESIGNED NOW because
BD-241 is implemented this cycle. The rule applies to ALL agent roles EXCEPT
`docs-researcher`, with TWO carve-outs (USER OVERRIDE / ARCHITECT CHALLENGE).

**User-confirmed VERBATIM rule (the design input, not re-litigated):**
> **Reconciliation-instance independence.** A reconciliation pass uses a FRESH instance
> — never the original author (contaminated/design-biased) nor the adversarial reviewer
> (biased to its own findings). APPLIES to all agent roles — architect, planner, coder,
> reviewer, auditor, repo-ops, and all others — EXCEPT `docs-researcher`, which may be
> re-engaged/reused (factual-inventory work; accumulated context helps; no design bias).
> TWO exceptions: (1) USER OVERRIDE — the user explicitly asks for a `SendMessage` to an
> existing agent (the BD-241 carve-out); (2) ARCHITECT CHALLENGE — a good, evidence- and
> logic-based reason, per case.

> **Method note (graph-first, G2 fallback applied).** I queried the injected graph FIRST
> (the orchestrator-supplied absolute `--graph` path, NOT my own toplevel) for the
> reconciliation/fresh-instance/agent-reuse rule surfaces; it returned only
> tracker-fixture + `test-compare-agent-trinity.sh` provenance nodes (the rule concept is
> not a graph node — identical G2 result to both prior BD-241 passes). Per the G2 fallback
> I re-measured EVERY load-bearing surface with grep/Read against HEAD `af73ffb`. The
> graph indexes headings/code, not memory-rule bodies; grep/Read is the correct primary
> tool for a rule-corpus BD. Proof + the graph-query-ran row are in §8 (Rules-Applied).

---

## 0. Where this addendum sits relative to the settled BD-241 design (NO re-opening)

The reconciled design (RECONCILED §2.2 / §3) adds TWO rules:
- **Bullet A — `spawn-unique-naming`** (trinity ×3, `### Agent invocation rules`).
- **Bullet B — `spawn-registry-find`** (Claude-only, `### Sub-agent behavior (Claude-only)`).

This addendum adds a **THIRD** rule — **Bullet C — `reconciliation-instance-independence`**
— that is ORTHOGONAL to A and B in subject (A = how to NAME a spawn; B = how to FIND a
warm spawn; C = WHEN you may reuse a found/warm spawn vs must spawn fresh). C does NOT
touch A's or B's text, slugs, placement, rationale sections, or carve-outs. It RIDES the
same already-planned BD-241 propagation surfaces (trinity `### Agent invocation rules` ×3
+ PACK-MEMORY-RATIONALE.md + project PM-CHAT.md + project trinity), adding exactly one
more tagged bullet + one more rationale section + the matching audience-correct project
surfaces. Everything the reconciled design settled stays settled.

**Why C is BD-241's natural home (not a new BD).** BD-241's own entry (`backlog/BD-241.md`
L8, L11, L16) makes "KEEP `fresh-agent-default` UNCHANGED; this BD fixes HOW-to-find, not
WHEN-to-reengage" a load-bearing constraint, and L11 names
`reference_sendmessage_uuid_addressing` + `feedback_fresh_agent_default_no_sendmessage` as
the rules to RECONCILE. C is precisely the WHEN-to-reengage refinement for the
reconciliation-pass case — it is the missing companion to BD-241's HOW-to-find mechanism.
The user-`SendMessage` carve-out is explicitly "the BD-241 carve-out" (user's words), so
C's carve-out text lives where BD-241's discoverability mechanism lives. Codifying C in
BD-241's same cycle is in-scope, not scope creep: it closes the WHEN half of the same
discoverability/reuse story BD-241 opens.

---

## 1. The canonical rule text (Bullet C) — reinforces fresh-agent-default, is NOT a contradiction

### 1.1 Placement decision (measure-then-bound, options + recommendation)

**Measured facts driving placement:**
- C applies to ALL agent roles on ALL CLIs (architect/planner/coder/reviewer/auditor/
  repo-ops/tester/grpc-schema across Claude / Codex / Antigravity) — it is a CROSS-CLI
  rule, NOT a Claude-only mechanism. (Evidence: the verbatim rule enumerates the full
  cross-CLI roster; carve-out (1) names `SendMessage` only as ONE platform's instance of
  "ask for an existing agent", audience-correct elsewhere.)
- The reconciled design (RECONCILED §2, claim #6) established that `### Agent invocation
  rules` is the trinity-parity home that ALREADY houses tagged universal corpus rules
  (`preflight-stop-means-stop`, `enumerate-rules-inline`, `rules-applied-verification-
  block`, `empirical-evidence-blocks`, `ci-guard-measure-then-bound`) and is mirrored ×3
  (CLAUDE L242 / AGENTS L244 / GEMINI L211).
- C is conceptually adjacent to the existing `### Agent invocation rules` independence
  family: "No prior reviews to pack-reviewer" (L269-271), "No solutions in agent prompts"
  (L265-268), "Researcher-first pipeline" (L272-279). C is the same independence
  principle applied to the reconciliation step.

| # | Option | Pros | Cons | Verdict |
|---|---|---|---|---|
| a | Bullet C in `### Agent invocation rules` ×3 trinity, tagged `[roles: universal] [rationale: reconciliation-instance-independence]` | cross-CLI parity (matches the rule's actual scope); precedented tagged-universal home; sits beside the independence-family rules; ONE slug, one bijection identity; same surfaces BD-241 already edits | adds a 3rd tagged bullet to the same H3 BD-241/238/240 all touch (serialization, not collision — §5) | **RECOMMENDED** |
| b | Bullet C in `### Sub-agent behavior (Claude-only)` (CLAUDE.md only) | co-locates with the BD-241 registry mechanism (Bullet B) | WRONG SCOPE — C is cross-CLI; Claude-only placement would orphan Codex/Antigravity readers (the exact MAJOR-1 mistake the reconciled design corrected); the SendMessage carve-out is ONE CLI's instance, not the rule's home | rejected |
| c | Fold C into the existing `fresh-agent-default` out-of-repo memory only (no trinity rule) | no trinity edit | trinity is the SSOT (trinity-wins); `fresh-agent-default` is NOT in trinity as its own tagged rule — it lives as the subordination clause inside "Agent-team stage lifecycle" + an out-of-repo memory; an out-of-repo-only rule is not durably enforced + not visible to a fresh agent reading trinity | rejected |

**RECOMMENDATION: Option (a).** C is a cross-CLI independence rule; `### Agent invocation
rules` ×3 is its measured-correct home — exactly parallel to the reconciled design's
Bullet A placement reasoning, and for the same reason.

### 1.2 Bullet C — exact drop-in text (CLAUDE.md form; audience-correct ×3 per cross-cli-reference-normalization)

Insert as a new bullet in `### Agent invocation rules` (CLAUDE.md / AGENTS.md / GEMINI.md),
after "No prior reviews to pack-reviewer" (its nearest independence-family sibling) — the
exact insertion point is the coder's measure-then-place, but the independence cluster is
the semantic home. CLAUDE.md form:

> - **Reconciliation-instance independence.** A reconciliation pass (the round that
>   resolves an adversarial review's findings before the work advances) uses a FRESH,
>   independent instance — NEVER the original author (contaminated + design-biased toward
>   its own design) NOR the adversarial reviewer (biased toward its own findings). This
>   applies to EVERY agent role — architect, planner, coder, reviewer, auditor, repo-ops,
>   tester, grpc-schema, and any other — with ONE exception: `docs-researcher`, which MAY
>   be re-engaged/reused (its work is factual inventory, accumulated context helps, and it
>   carries no design bias). Two carve-outs override the fresh-instance default: (1) **user
>   override** — the user EXPLICITLY asks to re-engage an existing agent (in Claude Code
>   via `SendMessage` to that instance — the BD-241 discoverability mechanism then
>   re-finds it; on Codex / Antigravity via the platform's re-engage path); and (2)
>   **architect challenge** — a good, evidence- and logic-based reason argued per case (not
>   a blanket exemption). This rule REINFORCES `fresh-agent-default` (it is that
>   independence principle applied to the reconciliation step) and SUBORDINATES the
>   Agent-team "SendMessage for follow-ups" convenience: a reconciliation pass is a fresh
>   spawn unless a carve-out fires. `[roles: universal]
>   [rationale: reconciliation-instance-independence]`

**AGENTS.md form** substitutes carve-out (1)'s CLI clause: "in Codex via the platform's
agent re-engage / `resume_agent` path (where its multi-agent messaging is enabled)". The
**GEMINI.md form** substitutes: "on Antigravity via the platform's known-ID re-engage /
idle-rewake path". The rule body, the role roster, the docs-researcher exemption, the
architect-challenge carve-out, and the fresh-agent-default reinforcement are IDENTICAL
across all three; only carve-out (1)'s per-CLI re-engage reference differs
(cross-cli-reference-normalization — audience-correct, NOT a byte-copy).

**Load-bearing clauses (do NOT trim — coder keeps verbatim):**
1. "NEVER the original author ... NOR the adversarial reviewer" — names BOTH forbidden
   reuse sources; dropping either re-opens the contamination the rule closes.
2. "EXCEPT `docs-researcher` ... no design bias" — the sole role exemption; its rationale
   (factual inventory) must travel with it.
3. "This rule REINFORCES `fresh-agent-default`" — the subordination/reinforcement framing
   is what makes C compatible (not contradictory) with the existing rules (§4).

---

## 2. BD-241 codification (designed NOW) — the agent-reuse angle, full propagation

C is the agent-REUSE angle the user designated for BD-241. Below is the complete
edit set, integrated with the reconciled design's surfaces WITHOUT re-opening them.
The reconciled design's surfaces are listed in RECONCILED §9.1/§9.2; C ADDS the rows
marked **C-Pn / C-PRn** below — it edits NONE of the reconciled design's existing rows.

### 2.1 PACK-SIDE surfaces (additive to RECONCILED §9.1)

| # | Surface | Edit | Gate | Required? |
|---|---|---|---|---|
| **C-P1** | `CLAUDE.md` `### Agent invocation rules` + `AGENTS.md` L244 + `GEMINI.md` L211 (×3) | ADD Bullet C (§1.2), audience-correct per CLI, `[roles: universal] [rationale: reconciliation-instance-independence]` | Check 18 (parity ×3); Check 45 (needs C-P2) | **YES** |
| **C-P2** | `pack-ops/PACK-MEMORY-RATIONALE.md` — new `## reconciliation-instance-independence` | bare-slug heading + rationale (Why / How / Rejected — §2.3) | Check 45 bijection | **YES** |
| — | `pack-ops/.spawn-rule-manifest.txt` | **NO RECORD** — C is GREENFIELD (no pre-existing PACK-AGENTS.md/PACK-CHAT.md restatement to collapse; verified §6 claim G); the manifest is for COLLAPSED restatements only (same logic the reconciled design applied to DROP P5). Check 45 bijection already gives C teeth. | — | NO |
| — | `pack-ops/PACK-CHAT.md` | **NO required edit** — the reconciled design's §6.2 MINOR-3 carve-out note (Claude-only ×3-exempt) is about Bullet B; C is ×3 trinity and follows step-1 as written. An OPTIONAL one-line pointer in PACK-CHAT.md's spawn-mechanics section MAY be added but is NOT required (anti-restate measure-bound applies if added — §6.1 of the reconciled design governs). Recommend SKIP (trinity is SSOT). | Check 46 anti-restate (if added) | OPTIONAL (skip) |
| **C-P3** | out-of-repo memory `feedback_fresh_agent_default_no_sendmessage.md` | REFINE (Pack-Chat upkeep; NOT a tree file): add a cross-ref line "the reconciliation-pass case is codified as trinity `[rationale: reconciliation-instance-independence]` — a fresh instance for the reconciliation round; carve-outs = user override / architect challenge; `docs-researcher` exempt." trinity-wins. | Pack-Chat upkeep | YES (memory hygiene) |
| **C-P4** | out-of-repo memory `MEMORY.md` index | ADD/UPDATE a one-line pointer under "Design discipline" (or "Workflow / coordination"): "Reconciliation-instance independence — fresh instance for the reconciliation pass; never the author/reviewer; docs-researcher exempt; user-override + architect-challenge carve-outs." | Pack-Chat upkeep | YES |
| — | `reference_sendmessage_uuid_addressing.md` | **NO EDIT REQUIRED for C** (the reconciled design's P6 already refines it for the registry/precedence; C's user-override carve-out is satisfied by that refinement — the SendMessage path is how the user-override re-engages). Optional one-line note that SendMessage-reuse is the user-override path for reconciliation. | Pack-Chat upkeep | OPTIONAL |

**Pack-side commit scope:** C-P1/C-P2 are pack-ops (`CLAUDE/AGENTS/GEMINI.md` +
`PACK-MEMORY-RATIONALE.md`). They are `pack-only`-clean (no `project-template/` or
`supporting-docs/` in C's pack-side rows). C-PR1/C-PR2 below are project-template (product)
— so if C lands together with its project surfaces in one commit, that commit is NOT
`pack-only` (Check 36). See §5 for the commit-grouping recommendation.

### 2.2 PROJECT-SIDE surfaces (additive to RECONCILED §9.2)

C is a UNIVERSAL collaboration rule that "applies project-wide regardless of agent role"
— which is EXACTLY the stated charter of the project trinity `## Project memory` section
(measured: `project-template/CLAUDE.md` L351-359 "this section carries only the universal
collaboration rules that apply project-wide regardless of agent role"). This is the KEY
distinction from the reconciled design's BD-241 mechanism: the reconciled design (RECONCILED
§9.2, claim #17) correctly held the project trinity NO-EDIT because the registry MECHANISM is
Claude-only runtime detail — wrong audience for a universal-rules section. C is the OPPOSITE:
it IS a universal collaboration rule, so it BELONGS in the project trinity `## Project memory`.

| # | Surface | Edit | Required? |
|---|---|---|---|
| **C-PR1** | `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` (×3 — CLAUDE L349 / AGENTS L326 / GEMINI L346) | ADD a project-audience bullet: the reconciliation pass uses a FRESH instance — never the original author nor the adversarial reviewer; applies to every project agent role (architect/planner/coder/reviewer/auditor[+specialized]/repo-ops/tester/grpc-schema) EXCEPT `docs-researcher` (factual inventory — reuse OK); carve-outs = developer override (explicit ask to re-engage an existing agent) + architect challenge (per-case, evidence-based). Trinity-parity ×3, audience-correct per CLI for the re-engage clause. | **YES** (universal collaboration rule, project-wide) |
| **C-PR2** | `project-template/docs/pack/PM-CHAT.md` § "In-session agent spawning" (L454+) / near the merge-back re-engage (L533-541) | ADD a CLI-agnostic prose line in the spawn section: "A reconciliation pass (resolving an adversarial review before the work advances) is a FRESH spawn — never the original author or the adversarial reviewer — for every agent except `docs-researcher`. Re-engage an existing agent only on the developer's explicit ask or a per-case architect-challenge reason." Precedent: the existing CLI-agnostic "Spawn in the background" (L506-510) + the fresh-spawn merge-back prose (L533-541). | **YES** (project orchestrator runtime SSOT) |
| — | `supporting-docs/METHODOLOGY.md` (SHIPPED) | **NO REQUIRED edit for C in BD-241.** METHODOLOGY is the SHIPPED methodology doc; the reconciliation-PIPELINE narrative (where C's pipeline-structure facet lives) is owned by BD-239 (project-side pipeline standard), which targets METHODOLOGY.md as a home (BD-239 entry L26). C's BD-241 codification is the AGENT-REUSE rule (trinity + PM-CHAT); the PIPELINE-STRUCTURE facet ("the reconciliation STEP uses a fresh instance") is the §3 handoff to BD-238/239. Adding pipeline narrative to METHODOLOGY now would pre-empt BD-239. RECOMMEND: leave METHODOLOGY for BD-239 (separation of the rule-facet from the pipeline-facet). | NO (BD-239 owns the METHODOLOGY pipeline facet) |
| — | `project-template/docs/pack/METHODOLOGY.md` | **DOES NOT EXIST as a project-template source** (RECONCILED §9.2 verified; the shipped copy comes from `supporting-docs/METHODOLOGY.md`). No edit. | NO |

**Project-side fixture-input note:** C-PR2 edits `project-template/docs/pack/PM-CHAT.md` (a
fixture INPUT). Per the manifest-regen memory + RECONCILED §8 (Check 62): `scripts/
manifest-sync.sh` reconciles at PUSH, NOT per-commit. The coder does NOT regen; flag for
the orchestrator's push step. C-PR1 (project trinity) is also mirrored in test-fixtures —
same push-time treatment. (C does NOT touch `supporting-docs/METHODOLOGY.md`, so it adds NO
new fixture-input surface beyond the project trinity + PM-CHAT the reconciled design's
PR1/PR2 already flag.)

### 2.3 C-P2 — the rationale section (`## reconciliation-instance-independence`)

Bare-slug heading (Check 45 regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$` — RECONCILED claim #12);
lowercase kebab, nothing after the slug. Body shape (Why / How / Rejected):

- **Why:** a reconciliation pass exists to resolve an adversarial review's findings
  cleanly. The original author is contaminated/design-biased toward its own design (it will
  defend it); the adversarial reviewer is biased toward its own findings (it will over-fix
  to vindicate them). A FRESH instance reading both the design AND the review as inputs is
  the only party with no stake in either — the same independence rationale as
  `fresh-agent-default`, "No prior reviews to pack-reviewer", and the per-commit
  fresh-coder rule, applied to the reconciliation step specifically.
- **How:** the reconciliation pass spawns a NEW instance of the relevant discipline
  (a fresh architect to reconcile an architect design; a fresh planner for a plan; etc.),
  handed the design + the adversarial review as SUBJECTS to reconcile. `docs-researcher` is
  exempt (factual-inventory work; accumulated context helps; no design bias). Carve-out (1):
  the user explicitly asks to re-engage an existing agent (Claude `SendMessage`, found via
  the BD-241 registry; Codex/Antigravity per-platform re-engage). Carve-out (2): an
  architect-challenge per-case evidence/logic argument.
- **Rejected:** (i) reuse the original author "because it has the context" — that context
  IS the contamination. (ii) reuse the adversarial reviewer "because it knows the findings"
  — that knowledge IS the bias. (iii) a blanket "any agent may be reused if the user says
  so once" — the carve-out is per-instance/explicit, not standing. (iv) exempt MORE roles
  than `docs-researcher` — only factual-inventory work qualifies for the no-design-bias
  exemption.

---

## 3. BD-238 / BD-239 handoff spec (the pipeline-STRUCTURE facet — spec only, NOT designed now)

C has two facets. BD-241 codifies the **agent-REUSE rule** (the standing rule: a
reconciliation pass uses a fresh instance — §2). BD-238/239 codify the
**pipeline-STRUCTURE** (the size-tiered large-BD / large-phase pipeline, in which the
reconciliation round is a STEP). The handoff below tells BD-238/239 exactly what to carry
so the pipeline STEP references C rather than re-deriving or contradicting it.

**Measured gap that makes this handoff necessary (claim H, §6):** BD-238 step 3 says
"reconciliation architect — only if the review returns NEEDS-REWORK" and BD-239 step 3/6
say the same for architect+planner — but NEITHER entry yet states WHO the reconciliation
instance is (fresh? the author? the reviewer?). C fills exactly that unspecified slot.

### 3.1 What BD-238 (pack-side) MUST carry
- In the pipeline's step-3 ("Adversarial architect review → [reconciliation architect]")
  and step-6 ("Adversarial planner review → [reconciliation planner]"), state that the
  **reconciliation instance is FRESH** per trinity `[rationale: reconciliation-instance-
  independence]` — cross-reference, do NOT restate the rule body (anti-restate / Check 46b;
  the safe form is a short pointer "the reconciliation round uses a fresh instance — see
  trinity `## Pack memory` `[rationale: reconciliation-instance-independence]`").
- The pipeline doc names `docs-researcher` as the reuse-exempt role at the optional
  researcher step (step 1) — consistent with C's exemption.
- The pipeline's reconciliation step inherits C's two carve-outs by reference (user
  override / architect challenge) — no separate carve-out vocabulary in the pipeline doc.
- BD-238's own rule-10 map + propagation already touch trinity `## Pack memory` +
  PACK-MEMORY-RATIONALE.md; if BD-241 lands C FIRST, BD-238 only ADDS the cross-reference
  pointer (no new slug). If BD-238 were to land before C, BD-238 must NOT author the C rule
  itself (that is BD-241's) — it references the planned slug. Sequencing is the user's;
  §5 records the same-file serialization either way.

### 3.2 What BD-239 (project-side) MUST carry
- The SAME cross-reference, project-audience: the project-side pipeline's reconciliation
  step (BD-239 steps 3/6) uses a FRESH instance per the project trinity `## Project memory`
  reconciliation-independence bullet (C-PR1) + PM-CHAT.md prose (C-PR2) — project
  vocabulary only (phases / phase tasks / the project agent roster), NO pack work-item
  refs (BD-239 ships to clients).
- `docs-researcher` named as the reuse-exempt role at the project pipeline's researcher
  step — consistent with C-PR1.
- METHODOLOGY.md (SHIPPED) is BD-239's home for the pipeline narrative; THAT is where the
  pipeline-structure facet's prose ("the reconciliation step uses a fresh instance, per the
  project trinity reconciliation-independence rule") lands — which is why §2.2 leaves
  METHODOLOGY for BD-239 (separation of the rule-facet from the pipeline-facet; no
  duplication, no pre-emption).
- BD-239 depends on BD-238 (entry L6); both depend on C's slug existing if they cross-ref
  it. Recommended order: BD-241 (C) → BD-238 → BD-239, so the cross-refs resolve. If the
  user sequences BD-238/239 before BD-241, they reference the PLANNED slug and the coder
  RE-VERIFIES at impl that C has landed (a `RE-VERIFY at impl` marker per the adversarial-
  planner memory).

### 3.3 The facet split is the separation-of-concerns line (explicit)
- **Rule facet (standing imperative, WHO):** BD-241 → trinity `[rationale: reconciliation-
  instance-independence]` (pack) + project trinity `## Project memory` (project).
- **Pipeline facet (the STEP that USES the rule, WHERE in the flow):** BD-238 (pack
  pipeline standard) + BD-239 (project pipeline standard / METHODOLOGY).
- The pipeline docs CROSS-REFERENCE the rule; they do NOT re-author it. This keeps ONE SSOT
  for the rule (trinity-wins) and avoids the anti-restate / drift trap.

---

## 4. COMPATIBILITY ANALYSIS (the user-mandated, non-negotiable deliverable)

Census method: graph-first (G2 fallback → grep/Read), then every related rule checked
against C for REINFORCE / CLARIFY / EXPAND vs CONTRADICTION. Census command + the full
enumerated rule set are in §6 (claim A). **Verdict up front: C REINFORCES every related
rule; ZERO genuine contradictions found.** Two near-edges are CLARIFIED below (they look
like tension but are not). Detail per rule:

| # | Existing rule (surface) | C's relationship | Evidence | Contradiction? |
|---|---|---|---|---|
| 1 | **`feedback_fresh_agent_default_no_sendmessage`** (out-of-repo memory + trinity "Agent-team stage lifecycle" subordination) | **REINFORCE + EXPAND (narrow).** fresh-agent-default already says "every agent task defaults to a FRESH spawn; messaging an existing agent is the EXCEPTION needing explicit user decision." C is that exact principle SPECIALIZED to the reconciliation pass, and it ADDS one structural detail the general rule does not name: the reconciliation instance must be neither the AUTHOR nor the REVIEWER (the general rule only says "fresh by default"). C's carve-out (1) "user explicitly asks for a SendMessage" is IDENTICAL to fresh-agent-default's "unless the user EXPLICITLY decides to send a message to the same agent." | memory body: "default is a NEW agent unless we discuss and I explicitly decide to send a message to the same agent"; "Why: an agent that has already processed context is biased and contaminated by it" — C's author/reviewer contamination is the SAME rationale. | **NO** — C is a faithful specialization; carve-out (1) is verbatim-aligned. |
| 2 | **`reference_sendmessage_uuid_addressing`** (out-of-repo memory) | **CLARIFY (no conflict).** This reference says SendMessage `to` accepts UUIDs and you CAN re-engage a non-named spawn. C does not forbid SendMessage — it scopes WHEN reuse is allowed (carve-out 1: the user asks). The reference is the MECHANISM (how to address a reused agent); C is the POLICY (when reuse is permitted). They compose: when carve-out (1) fires, the reference (+ BD-241 registry) is how you re-find/address. | reference body: "Still PREFER spawning agents WITH a name ... UUID-addressing works"; C: "the user EXPLICITLY asks to re-engage ... the BD-241 discoverability mechanism then re-finds it." | **NO** — mechanism vs policy; they compose. |
| 3 | **Trinity "Agent-team stage lifecycle + per-commit fresh-coder"** (CLAUDE.md L402-417, Claude-only) | **REINFORCE + CLARIFY.** This rule says (a) stage sub-agents stay alive within a stage and Pack Chat uses SendMessage for follow-ups — BUT it ALSO already says "each pack-coder commit gets a FRESH coder instance — never reuse a coder across commits" and "Per-BD review/fix cycle = fresh coder for the implementation, fresh coder for the fix." C is consistent: a reconciliation pass is a NEW pass (like a fresh fix-coder), so it gets a fresh instance. The "SendMessage for follow-ups WITHIN a stage" convenience is SUBORDINATE (fresh-agent-default already subordinates it; C inherits that subordination for the reconciliation case). | L410-413 "each pack-coder commit gets a FRESH coder instance ... fresh coder for the implementation, fresh coder for the fix"; C's text: "SUBORDINATES the Agent-team 'SendMessage for follow-ups' convenience." | **NO** — C aligns with the rule's OWN fresh-per-pass clauses; only the within-stage-SendMessage convenience is subordinated, which fresh-agent-default already does. |
| 4 | **Trinity rule-4 SANCTIONED SendMessage** ("Pack Chat SendMessage-s the most-recent read-write agent to produce the post-review-clean `git diff` patch", CLAUDE.md L368-370 + L405-408) | **CLARIFY (DISJOINT — no overlap, near-edge resolved).** This is a SendMessage to REUSE a warm agent for the PATCH-EMIT step (a mechanical `git diff`, not a reconciliation). C governs the RECONCILIATION pass (resolving review findings). They are different steps: patch-emit is NOT a reconciliation pass, so C does not touch it; the rule-4 reuse stays sanctioned. C's text scopes itself to "a reconciliation pass (the round that resolves an adversarial review's findings)" — explicitly NOT patch-emit. | C scoping clause: "(the round that resolves an adversarial review's findings before the work advances)"; rule-4: "produce its `git diff` patch only after the review is clean" (mechanical, post-review). | **NO** — disjoint steps; C's scoping clause prevents any overlap. This is the most important near-edge and it is cleanly disjoint. |
| 5 | **`feedback_adversarial_architect_review_on_major_gap`** (out-of-repo memory) | **REINFORCE + COMPLETE.** This rule mandates an ADVERSARIAL review by a FRESH architect (no shared context) and says "the adversarial architect's OUTPUT is itself reviewed by the user before the planner spawns." It establishes the fresh-ADVERSARIAL-reviewer leg. C establishes the fresh-RECONCILIATION leg (the round AFTER the review). Together they make BOTH the review AND the reconciliation fresh — closing the loop the memory opens. The memory's exemplar (BD-200) and C's principle share the contamination rationale exactly. | memory: "adversarial review by a FRESH architect (no shared context with the first)"; "rubber-stamp agreement is a FAILED adversarial review." C extends fresh-instance to the reconciliation step the memory does not name. | **NO** — C completes the chain (fresh review → fresh reconciliation). |
| 6 | **`feedback_adversarial_planner_review_major_plans`** (out-of-repo memory) | **REINFORCE + COMPLETE.** Same as #5 for plans. The memory: "The adversarial reviewer is a FRESH, INDEPENDENT agent of the SAME discipline (a second pack-planner)" + "Then Pack Chat RECONCILES the two passes." It names a RECONCILE step but assigns it to Pack Chat, NOT to a fresh planner. C SHARPENS this: a SUBSTANTIVE reconciliation pass (one that re-authors the plan, not a Pack-Chat merge of two text outputs) uses a FRESH planner instance — see the CLARIFY note below. | memory: "Pack Chat RECONCILES the two passes and surfaces the reconciled plan"; C: a reconciliation PASS (an agent re-authoring) is fresh. | **NO genuine conflict** — but a CLARIFY is warranted (below). |
| 7 | **Trinity "Researcher-first pipeline" + "docs-researcher exempt" usage** (CLAUDE.md L272-279; this addendum's exemption) | **REINFORCE.** The pipeline runs `pack-docs-researcher` FIRST and the existing pattern already re-engages a docs-researcher across passes (the BD-206 worked example in BD-241 provenance re-engaged a docs-researcher). C's docs-researcher exemption is consistent with that established reuse-of-researcher practice and gives it a rule. | BD-241 provenance: "re-engaging the BD-206 docs-researcher"; C: docs-researcher "may be re-engaged/reused (factual-inventory work)." | **NO** — C codifies existing researcher-reuse practice. |
| 8 | **Trinity "No prior reviews to pack-reviewer"** (CLAUDE.md L269-271) | **REINFORCE (same independence family).** That rule keeps a fresh CODE review unbiased by a prior review. C keeps a fresh RECONCILIATION unbiased by the author/reviewer. Same principle, adjacent step; placing C beside it (§1.1 option a) makes the family explicit. | L271 "Including a prior review biases the new review." | **NO** — same family, complementary. |
| 9 | **Trinity "Sub-agent isolation" (RW reuses the SAME worktree; fresh fix-coder reuses worktree)** (CLAUDE.md L350-390, Claude-only) | **CLARIFY (orthogonal — fresh-INSTANCE vs reused-WORKTREE).** This rule says a fresh fix-coder REUSES the same WORKTREE (a filesystem checkout), NEVER a new worktree per fix-coder. That is about the WORKTREE artifact, NOT the agent INSTANCE: the rule ALREADY pairs "fresh fix-coder" (instance) with "reused worktree" (filesystem). C governs the INSTANCE (must be fresh for a reconciliation pass); it says NOTHING about the worktree. A fresh reconciliation instance can (and for a coder-discipline reconciliation, should) run IN the commit's existing worktree. No conflict — C is instance-axis, isolation is worktree-axis. | L351-357 "every subsequent read-write agent in that commit's cycle — fix-coders included — REUSES that same worktree, NEVER a new one"; the fix-coder is FRESH (per the lifecycle rule) but REUSES the worktree. | **NO** — orthogonal axes; C never contradicts worktree reuse. This is the fresh-INSTANCE-vs-reused-WORKTREE distinction the prompt flagged. |
| 10 | **BD-241 reconciled design `spawn-registry-find` + `fresh-agent-default`-unchanged** (RECONCILED §3.2 / decision 4) | **REINFORCE + COMPOSE.** The reconciled design's Bullet B says "Consult the registry ONLY after the `fresh-agent-default` gate authorizes a re-engage" and KEEPS fresh-agent-default unchanged. C is the WHEN-to-reengage rule that the registry's "after the gate authorizes" clause points to: C says the reconciliation case authorizes reuse ONLY via carve-out. So C and Bullet B compose — Bullet B is HOW to find a warm agent once authorized; C (for the reconciliation case) is WHEN that authorization exists. | RECONCILED §3.2 "Consult the registry ONLY after the `fresh-agent-default` gate authorizes a re-engage — this fixes HOW-to-find, not WHEN-to-reengage." | **NO** — C supplies the WHEN that Bullet B explicitly defers to. |
| 11 | **`architect-doc-reality-reconciliation`** (trinity CLAUDE.md L602-608) | **CLARIFY (DISJOINT — different sense of "reconciliation").** This rule is about reconciling an architect DOC with the REALIZED code (docstring + addendum + IMPL-REPORT cross-refs). It is NOT an agent-reuse rule and uses "reconciliation" in a documentation sense. C uses "reconciliation" in the pipeline-pass sense. No overlap. (Flagged only because it shares the word "reconciliation" — a fresh agent should not conflate them.) | L602-603 "When a BD realizes a design anticipated in an architect doc, ship the reconciliation chain" (doc↔code). | **NO** — homonym, disjoint domains. |

### 4.1 The ONE CLARIFY worth surfacing to Pack Chat + the user (rule #6, near-edge)
The adversarial-planner memory says "Pack Chat RECONCILES the two passes." Read literally,
that assigns reconciliation to PACK CHAT (the orchestrator), while C says a reconciliation
PASS uses a FRESH AGENT INSTANCE. These are NOT contradictory once the two senses of
"reconcile" are separated:
- **Pack-Chat reconciliation (lightweight):** Pack Chat reading two text outputs and
  surfacing a merged view to the user is orchestration/triage — NOT an agent pass. C does
  not govern this (Pack Chat is not a spawned agent). The reconciled BD-241 design itself
  was produced by a FRESH architect (RECONCILED L3 "FRESH/RECONCILIATION pass — neither
  original author nor adversarial reviewer") — i.e., the SUBSTANTIVE reconciliation already
  uses a fresh instance in practice.
- **Substantive reconciliation (an agent re-authoring the design/plan):** when
  reconciliation requires re-authoring (re-running the architect/planner to produce a
  reconciled artifact, as DESIGN-BD-241-RECONCILED.md was), C governs: it MUST be a fresh
  instance.

**Recommended resolution (for Pack Chat + user, NOT a silent change):** when C lands,
Pack Chat should read the adversarial-planner memory's "Pack Chat RECONCILES" as the
LIGHTWEIGHT-merge sense, and any SUBSTANTIVE re-authoring reconciliation as the C-governed
fresh-instance sense. This is a CLARIFICATION, not a contradiction — both memories survive,
and the reconciled BD-241 design is itself the worked example (a fresh architect did the
substantive reconciliation). Surface this to the user as the single compatibility note;
optionally the adversarial-planner memory gets a one-line cross-ref to C (Pack-Chat upkeep,
not a tree edit). **No tree-rule conflict exists** — this is a memory-prose clarification.

---

## 5. Propagation + rule-10 impact (no NEW collision beyond the existing BD-238/240/241 serialization)

### 5.1 Propagation surfaces for C (count)
Per the PACK-CHAT.md rule-change propagation procedure (L495-509), C touches:
- **Pack tree-file surfaces (2):** C-P1 (trinity ×3 corpus — counts as ONE propagation
  step across 3 files) + C-P2 (PACK-MEMORY-RATIONALE.md rationale section). NO manifest
  record (greenfield), NO required PACK-CHAT.md reference.
- **Pack out-of-repo (2, Pack-Chat upkeep):** C-P3 (`feedback_fresh_agent_default…`
  cross-ref) + C-P4 (`MEMORY.md` index pointer). [`reference_sendmessage_uuid_addressing`
  optional — not counted as required.]
- **Project tree-file surfaces (2):** C-PR1 (project trinity ×3 `## Project memory`) +
  C-PR2 (PM-CHAT.md prose).
- **NOT touched by C:** `supporting-docs/METHODOLOGY.md` (BD-239 owns the pipeline facet);
  `pack-ops/.spawn-rule-manifest.txt` (greenfield); `pack-ops/PACK-CHAT.md` propagation
  doc (no carve-out note needed — C is ×3, not Claude-only).

**Total REQUIRED surfaces for C = 6** (4 tree-file edits across pack + project: trinity-pack
×3 = 1 step, RATIONALE = 1, project-trinity ×3 = 1 step, PM-CHAT = 1; plus 2 out-of-repo
memory upkeep). Counting individual FILES: 3 pack-trinity + 1 RATIONALE + 3 project-trinity
+ 1 PM-CHAT = **8 tree files**, + 2 out-of-repo memory files.

### 5.2 rule-10 — same-file serialization, NO new collision
C edits the SAME shared files the reconciled design + BD-238/BD-240 already serialize on:
`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory` + `pack-ops/PACK-MEMORY-RATIONALE.md`.

| File | BD-238 | BD-240 | BD-241 (RECONCILED A/B) | BD-241 (C, this addendum) | Schedule |
|---|---|---|---|---|---|
| `CLAUDE.md` `## Pack memory` (`### Agent invocation rules`) | YES | YES | YES (Bullet A, P3) | YES (Bullet C) | **SERIALIZE** |
| `AGENTS.md` / `GEMINI.md` `## Pack memory` (×3) | YES | YES | YES (Bullet A ×3) | YES (Bullet C ×3) | **SERIALIZE** |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | YES | YES | YES (P2a/P2b/P4) | YES (C-P2) | **SERIALIZE** |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` | no (BD-239 does) | no | NO (RECONCILED claim #17) | YES (C-PR1) | new — C is the only BD-241 editor here; serialize vs BD-239 |
| `project-template/docs/pack/PM-CHAT.md` | no | maybe | YES (PR1/PR2) | YES (C-PR2) | **SERIALIZE within BD-241** (C-PR2 + reconciled PR1/PR2 same file) |

**Consequence (rule 10):** C introduces NO NEW collision class. It edits files already in
BD-241's own same-commit set (trinity + RATIONALE + PM-CHAT) AND already in the cross-BD
BD-238/240/241 serialization. C's only NEW surface is the project trinity `## Project
memory` (C-PR1) — which BD-239 will also touch, so C-PR1 SERIALIZES with BD-239 (same-file).
Since BD-239 runs AFTER BD-238 (and likely after BD-241), the natural order
BD-241(incl. C) → BD-238 → BD-239 keeps every shared-file edit serial with no concurrent
worktree wave on these files. **Intra-BD-241:** C rides the reconciled design's existing
serial structure — C's pack-side edits (C-P1/C-P2) co-locate with the reconciled design's
commit-1 (the rule + pack corrections); C's project-side edits (C-PR1/C-PR2) co-locate with
the reconciled design's commit-2 (the product-side surfaces). NO new wave, NO new
parallelism — C is absorbed into the reconciled design's existing 2-commit (or 1
neutral-commit) structure.

### 5.3 Commit-scope (Check 36) — same reality as the reconciled design
C-PR1 (`project-template/`) makes any commit carrying C's project surfaces NOT `pack-only`
(Check 36 denies `project-template/` under `pack-only`). This is IDENTICAL to the reconciled
design's §1.1/§9.3 finding (its PR1/PR2 + P3b already broke `pack-only` framing). C adds NO
NEW scope tension: if the reconciled design's commit-2 (product-side) carries C-PR1/C-PR2,
that commit is already non-`pack-only`. C's PURE-pack rows (C-P1/C-P2) can ride the
reconciled design's `pack-only` commit-1 cleanly. RECOMMENDATION: follow the reconciled
design's recommended SPLIT — C-P1/C-P2 → the `pack-only` rule commit; C-PR1/C-PR2 → the
product-side commit (no scope keyword, or split further). No new commit needed for C alone.

---

## 6. validate-pack green — verification (Checks 18/45/46) for Bullet C

Baseline measured at HEAD `af73ffb` (§7 claim B): `PASSED — all checks clean`;
Check 45 = **23↔23**; Check 46 = boundary 11 / spawn 7 / anti-restate 0 (49 candidates);
Check 18 green (pack-root + project-template). Bijection arithmetic note: the reconciled
design takes the baseline 23↔23 to **25↔25** (its 2 new slugs). C adds ONE more slug →
**26↔26** if C lands in the same commit-set as the reconciled design; or 24↔24 over baseline
if C lands alone. The coder confirms the live count post-edit (do not hard-code 26).

| Check | Risk from C | How C keeps it green |
|---|---|---|
| **Check 18** (trinity H2 parity, per-location, per-H2) | new H2/H3 mismatch | NO new heading. Bullet C is a BULLET inside the EXISTING `### Agent invocation rules` H3 (an H3 under the `## Pack memory` H2), present in all three trinity files (CLAUDE L242 / AGENTS L244 / GEMINI L211). Adding a bullet ×3 changes NO H2 structure → parity preserved. Same clearance as the reconciled design's G-2. C-PR1 adds a bullet inside the EXISTING project trinity `## Project memory` H2 (×3) — also no H2-structure change; project-template Check 18 stays green. |
| **Check 45** (rule↔rationale bijection) | orphan slug | C-P1 adds corpus slug `reconciliation-instance-independence` (×3, but Check 45 scans CLAUDE.md as the corpus representative — RECONCILED claim #12) + C-P2 adds the matching `## reconciliation-instance-independence` rationale section, IN THE SAME COMMIT → set-equality holds (+1 corpus / +1 rationale). Bare-slug heading per the Check 45 regex (`^##\s+([a-z0-9][a-z0-9-]*)\s*$`). Verified greenfield (§7 claim C: 0 existing slug). |
| **Check 46** (manifest + anti-restate) | new slug without manifest record; verbatim restatement | NO manifest record added (C is greenfield — nothing to collapse; §7 claim G) → reference-resolution leg untouched (still 7 spawn records). Anti-restate: C adds NO new reference surface that restates C's body; C's bullet body becomes a NEW candidate (~+1 candidate) but appears NOWHERE in the 6 scanned spawn-relevant surfaces → 0 restate hits. (If the optional PACK-CHAT.md pointer were added, the coder MEASURES the 120-char leading-window non-overlap per RECONCILED §6.1 — recommended SKIP.) |
| **Check 62** (push-time manifest) | changed fixture input | C-PR1 (project trinity) + C-PR2 (PM-CHAT.md) are fixture INPUTS (mirrored in `test-fixtures/**`). `scripts/manifest-sync.sh` reconciles at PUSH (NOT per-commit, per the manifest memory); the coder does NOT regen. C adds NO fixture-input surface beyond the project trinity + PM-CHAT the reconciled design's PR1/PR2 already flag. Flag for the orchestrator's push step. |
| **Check 36** (commit-scope keyword) | mis-claimed `pack-only` | C-PR1/C-PR2 touch `project-template/` → a commit carrying them MUST NOT be `pack-only`. Same as RECONCILED §8 / §5.3 here. |
| **`[roles:]` controlled vocab** | invalid role tag | C uses `[roles: universal]` — verified in the in-use vocabulary set (`[roles: universal]` is one of the 6 existing forms; §7 claim F). |

**measure-then-bound — NO new CHECK designed for C.** C is a discipline rule about agent
INSTANCE selection at spawn time; there is NO committed-tree state a validator could scan to
enforce "this reconciliation pass used a fresh instance" (an empty matching set — forbidden
by `ci-guard-design-measure-then-bound`). Enforcement is the corpus rule (discipline) +
Pack Chat's rules-in-force block at spawn time, reusing Checks 18/45/46. CI runtime-
compounding cost (×~155) UNCHANGED (no new check).

**Pre-commit verification the coder runs:** after C-P1 + C-P2, run
`python3 scripts/validate-pack.py` and confirm Check 45 reports the new bijection count
(+1 over whatever the BD-241-reconciled commit-set left it at), Check 46 still
0 restate / 7 spawn records, Check 18 green (pack-root + project-template). After C-PR1,
re-confirm project-template Check 18 parity ×3.

---

## 7. Empirical-Evidence Block (every state-claim + every compatibility verdict)

| # | State-claim / verdict | Command | Output (verbatim/measured) | HEAD/date | Conclusion |
|---|---|---|---|---|---|
| A | Graph returns no rule-body node for the reconciliation/fresh-instance concept (G2 fallback justified) | `graphify query "reconciliation pass fresh instance agent reuse" --graph .../graphify-out/graph.json --backend claude-cli --budget 1500` | 21 nodes, all `test-compare-agent-trinity.sh` + tracker-fixture `IMPLEMENTATION-PLAN.md` provenance; ZERO rule-body / memory nodes | af73ffb / 2026-06-20 | SUPPORTED — concept not a graph node → G2 → grep/Read primary |
| B | validate-pack baseline GREEN; Check 45 = 23↔23; Check 46 = 7 spawn / 0 restate / 49 candidates; Check 18 green ×2 | `python3 scripts/validate-pack.py` | "Check 45 — 23 corpus … 23 rationale … bijection holds"; "Check 46 … spawn manifest: 7 rule(s) … anti-restate: 0 … 49 candidate bodies … >= 60 chars"; "PASSED — all checks clean"; Check 18 [project-template] + [pack-root] both printed | af73ffb / 2026-06-20 | SUPPORTED (targets: +1 slug → 24↔24 alone or 26↔26 with reconciled; 7 records unchanged; ~50 candidates / 0 restate) |
| C | C is GREENFIELD — no existing reconciliation-instance rule or slug on any surface | `grep -rniE "reconciliation.instance\|reconciliation pass.*fresh\|fresh.*reconciliation\|reconcile.*fresh instance" CLAUDE.md AGENTS.md GEMINI.md pack-ops/*.md project-template/{CLAUDE,AGENTS,GEMINI}.md project-template/docs/pack/PM-CHAT.md supporting-docs/METHODOLOGY.md`; `grep -rn "reconciliation-instance" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md` | both EMPTY (0 hits) | af73ffb / 2026-06-20 | SUPPORTED — nothing to collapse; new slug is unused |
| D | `### Agent invocation rules` exists ×3 trinity + houses tagged universal rules (Bullet C's home) | `grep -n "### Agent invocation rules\|### Sub-agent behavior" CLAUDE.md`; Read CLAUDE.md L242-347 | CLAUDE.md:242 `### Agent invocation rules`; :348 `### Sub-agent behavior (Claude-only)`; 5 tagged universal rules in the H3 (preflight-stop-means-stop, enumerate-rules-inline, rules-applied-verification-block, empirical-evidence-blocks, ci-guard-measure-then-bound) | af73ffb / 2026-06-20 | SUPPORTED (placement option a; reinforces RECONCILED claim #6) |
| E | Project trinity `## Project memory` is the home for UNIVERSAL collaboration rules (C-PR1's correct home; contrast RECONCILED claim #17's mechanism exclusion) | Read `project-template/CLAUDE.md` L349-409; `grep -n "## Project memory" project-template/{CLAUDE,AGENTS,GEMINI}.md` | L351-359 "this section carries only the universal collaboration rules that apply project-wide regardless of agent role"; bullets: Trinity rule, No-destructive-git, PM-chat-does-not-architect, Project SSOT-first; CLAUDE:349 / AGENTS:326 / GEMINI:346 | af73ffb / 2026-06-20 | SUPPORTED — C IS a universal collaboration rule → BELONGS (unlike the Claude-only mechanism, which did NOT) |
| F | `[roles: universal]` is a valid in-use tag | `grep -ohE "\[roles:[^]]*\]" CLAUDE.md \| sort -u` | `[roles: architect coder]` / `[roles: architect planner]` / `[roles: architect]` / `[roles: coder]` / `[roles: reviewer coder]` / `[roles: universal]` | af73ffb / 2026-06-20 | SUPPORTED — `[roles: universal]` valid |
| G | The spawn-rule manifest is for COLLAPSED restatements; C has none → NO manifest record (matches RECONCILED DROP-P5 logic) | `grep -rniE "reconciliation.instance\|reconciliation pass" pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md`; manifest header (RECONCILED claim #11, re-cited) | 0 hits in PACK-CHAT/PACK-AGENTS (no restatement exists to collapse) | af73ffb / 2026-06-20 | SUPPORTED — greenfield → no record (Check 46 untouched) |
| H | BD-238/239 name a "reconciliation architect/planner" STEP but do NOT specify the instance is fresh (the gap C fills) | Read `backlog/BD-238.md` L19/L22; `backlog/BD-239.md` L18/L21 | BD-238 L19 "[reconciliation architect — only if the review returns NEEDS-REWORK]"; L22 "[reconciliation planner — only if NEEDS-REWORK]"; BD-239 L18/L21 same — neither states WHO the instance is | af73ffb / 2026-06-20 | SUPPORTED — handoff spec (§3) fills the unspecified slot |
| I | fresh-agent-default's carve-out matches C's carve-out (1) verbatim-aligned (compatibility verdict #1) | Read `feedback_fresh_agent_default_no_sendmessage.md` | "default is a NEW agent unless we discuss and I explicitly decide to send a message to the same agent as before"; "Why: an agent that has already processed context is biased and contaminated by it" | 2026-06-10 (memory) / read 2026-06-20 | SUPPORTED — REINFORCE+EXPAND, no contradiction |
| J | The "Agent-team stage lifecycle" rule ALREADY mandates fresh-per-pass coders (C aligns; verdict #3) | Read CLAUDE.md L402-417 | L410-413 "each pack-coder commit gets a FRESH coder instance — never reuse a coder across commits … Per-BD review/fix cycle = fresh coder for the implementation, fresh coder for the fix" | af73ffb / 2026-06-20 | SUPPORTED — C consistent with the rule's own fresh-per-pass clauses |
| K | The rule-4 SANCTIONED SendMessage is for PATCH-EMIT, not reconciliation (verdict #4, disjoint) | Read CLAUDE.md L368-370 + L405-408 | L368-370 "SendMessage-s the most-recent read-write agent to produce it (`git diff > <handoff>/changes.patch`)"; L405-408 "the sanctioned rule-4 post-review-clean patch step" | af73ffb / 2026-06-20 | SUPPORTED — disjoint from C's reconciliation scope; no conflict |
| L | The "Sub-agent isolation" rule pairs FRESH fix-coder (instance) with REUSED worktree (filesystem) → orthogonal to C (verdict #9) | Read CLAUDE.md L350-390 | L351-357 "every subsequent read-write agent in that commit's cycle — fix-coders included — REUSES that same worktree, NEVER a new one for a fix-coder"; the fix-coder is fresh per L412-413 | af73ffb / 2026-06-20 | SUPPORTED — instance-axis (C) vs worktree-axis (isolation); orthogonal |
| M | The adversarial-planner memory assigns "reconcile" to Pack Chat (the §4.1 CLARIFY near-edge) | Read `feedback_adversarial_planner_review_major_plans.md` | "Then Pack Chat RECONCILES the two passes and surfaces the reconciled plan … to the user" | 2026-06-15 (memory) / read 2026-06-20 | SUPPORTED — lightweight-merge sense (Pack Chat) vs substantive-reauthor sense (C); CLARIFY, not conflict |
| N | The reconciled BD-241 design is itself a FRESH-instance reconciliation (worked example of C) | Read `DESIGN-BD-241-RECONCILED.md` L3 | "pack-architect (READ-ONLY, FRESH/RECONCILIATION pass — neither original author nor adversarial reviewer)" | 2026-06-20 | SUPPORTED — C codifies the practice already in use |
| O | `architect-doc-reality-reconciliation` is a doc↔code rule (homonym, disjoint — verdict #11) | `grep -n "architect-doc-reality-reconciliation\|reconciliation chain" CLAUDE.md` | L602-608 "When a BD realizes a design anticipated in an architect doc, ship the reconciliation chain" (docstring/addendum/IMPL-REPORT) | af73ffb / 2026-06-20 | SUPPORTED — different sense of "reconciliation"; no overlap |
| P | C-PR1 home exists ×3; project roster matches the user's enumerated set | `grep -n "## Project memory" project-template/{CLAUDE,AGENTS,GEMINI}.md`; Read PM-CHAT.md L47-68 | project trinity L349/326/346; roster: architect, auditor[+6 specialized], coder, docs-researcher, grpc-schema, planner, repo-ops, reviewer, tester | af73ffb / 2026-06-20 | SUPPORTED — roster = user's set; docs-researcher present (the exempt role) |

---

## 8. Open questions for the user (design gate — additive to RECONCILED §11; do NOT re-open §11's four)

1. **C placement (§1.1):** Bullet C in `### Agent invocation rules` ×3 trinity
   `[rationale: reconciliation-instance-independence]` (RECOMMENDED — cross-CLI parity,
   precedented home, beside the independence family) vs the Claude-only sub-section
   (rejected — wrong scope). Confirm option (a).
2. **C-PR1 project trinity edit (§2.2):** ADD C to project trinity `## Project memory` ×3
   (RECOMMENDED — C is a universal collaboration rule, the section's exact charter) vs
   PM-CHAT-only. [Contrast RECONCILED claim #17: the BD-241 MECHANISM correctly stayed OUT
   of the project trinity; C correctly goes IN — different rule classes.]
3. **METHODOLOGY deferral to BD-239 (§2.2 / §3.2):** leave the pipeline-narrative facet of C
   for BD-239's METHODOLOGY edit (RECOMMENDED — facet separation, no pre-emption) vs add a
   pipeline line to METHODOLOGY now. [If now, the commit reaches `supporting-docs/` — same
   Check-36 reality as RECONCILED P3b.]
4. **The §4.1 compatibility CLARIFY (adversarial-planner "Pack Chat RECONCILES"):** accept
   the two-sense reading (lightweight Pack-Chat merge vs substantive fresh-instance
   reconciliation) with an OPTIONAL one-line cross-ref added to that out-of-repo memory
   (RECOMMENDED) vs leave the memory untouched. [Memory-prose only; NO tree-rule conflict.]
5. **Sequencing (§3.2 / §5.2):** BD-241(incl. C) → BD-238 → BD-239 (RECOMMENDED — cross-refs
   resolve forward) vs the user's own order with `RE-VERIFY at impl` markers if BD-238/239
   run before C.

---

## 9. Plan-ready summary (for the planner, after the user gate — additive to RECONCILED §14)

1. **ONE new corpus rule (Bullet C)**, tagged + bijection-paired: `reconciliation-instance-
   independence` in `### Agent invocation rules` ×3 trinity (C-P1) + a bare-slug
   `## reconciliation-instance-independence` rationale section (C-P2) → Check 45 +1/+1.
2. **TWO project-side edits:** C-PR1 (project trinity `## Project memory` ×3 — C is a
   universal collaboration rule) + C-PR2 (PM-CHAT.md spawn-section CLI-agnostic prose).
3. **NO manifest record** (greenfield — nothing to collapse; matches RECONCILED DROP-P5).
   **NO required PACK-CHAT.md reference** (C is ×3, not Claude-only; the RECONCILED §6.2
   carve-out note is about Bullet B, not C). Optional PACK-CHAT pointer — recommend SKIP.
4. **TWO out-of-repo memory refines** (Pack-Chat upkeep): C-P3 (`feedback_fresh_agent_
   default…` cross-ref to C) + C-P4 (`MEMORY.md` index pointer). Optional: a one-line
   cross-ref on `feedback_adversarial_planner_review_major_plans` (§4.1).
5. **BD-238/239 handoff (§3):** the pipeline-STRUCTURE facet — both BDs' reconciliation
   STEP CROSS-REFERENCES C's slug (do not restate — anti-restate); name `docs-researcher`
   exempt at the researcher step; inherit C's two carve-outs by reference; BD-239's
   METHODOLOGY carries the project-audience pipeline prose. Recommended order BD-241 →
   BD-238 → BD-239.
6. **Commit scope:** C's pure-pack rows (C-P1/C-P2) ride a `pack-only` commit; C-PR1/C-PR2
   ride the product-side commit (NOT `pack-only`, Check 36). C adds NO new commit — it is
   absorbed into the reconciled design's existing split (or single neutral commit).
7. **rule-10:** C introduces NO new collision. It edits files already serialized
   (trinity + RATIONALE + PM-CHAT within BD-241; cross-BD with BD-238/240). C's only new
   surface (project trinity `## Project memory`) serializes with BD-239. No new wave.
8. **validate-pack green:** Check 18 (no new H2; bullet in existing H3 ×3 — pack + project),
   Check 45 (+1 slug / +1 rationale, same commit, bare-slug heading), Check 46 (no manifest
   record, 0 restate), Check 62 (push-time, project trinity + PM-CHAT fixture inputs),
   Check 36 (project surfaces → not `pack-only`). NO new check designed (no scannable
   committed state — measure-then-bound empty matching set).
9. **Does NOT re-open BD-241's settled decisions:** the 6 verified-correct decisions, the
   `spawn-unique-naming` / `spawn-registry-find` rules, the reconciled propagation tables,
   and the reconciled rule-10 map are FIXED inputs. C is purely ADDITIVE.

**Compatibility verdict (the deliverable, one line):** C REINFORCES every related rule
(fresh-agent-default, the adversarial-architect/planner memories, the per-commit
fresh-coder rule, "No prior reviews to pack-reviewer", the BD-241 reconciled
`spawn-registry-find`/`fresh-agent-default`-unchanged), CLARIFIES three near-edges
(the rule-4 patch-emit SendMessage is disjoint; the Sub-agent-isolation worktree-reuse is
orthogonal to instance-freshness; `architect-doc-reality-reconciliation` is a homonym),
and EXPANDS fresh-agent-default narrowly (it names the author-AND-reviewer exclusion for the
reconciliation case). The ONE surfaced near-edge worth the user's eye is §4.1 (the
adversarial-planner memory's "Pack Chat RECONCILES" — resolved as a two-sense
clarification, NO tree-rule conflict). **ZERO genuine contradictions.**

---

## 10. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | §7 — 16 state-claims/verdicts (A–P), each with command + verbatim/measured output + HEAD `af73ffb`/2026-06-20 (or memory-file date) + conclusion; incl. every compatibility verdict (I/J/K/L/M/O) backed by a quoted memory/trinity line. | COMPLIANT |
| ci-guard-design-measure-then-bound | §6 measured the live baseline (23↔23 / 7 / 49 / Check 18 ×2) and the greenfield grep (§7 claim C = 0 hits) BEFORE bounding; NO new validator designed (an instance-selection discipline has NO scannable committed-tree state — an empty matching set, forbidden by the rule); the compatibility census is grep/graph-derived (§7 claim A + §4), not hand-listed. | COMPLIANT |
| no-solutions-inherited / reach-own-conclusion | §1.1 placement options a/b/c + recommendation; §8 five user-gate questions each with a recommendation + rationale; §2.2 C-PR1 home reasoned from the section charter; reached my own placement (option a) independently. | COMPLIANT |
| pattern-matching-out-of-context-antipattern | Adopted the `### Agent invocation rules` ×3 placement ONLY after property-fit evidence (C is cross-CLI + universal + sits in the independence family — §7 claim D/E); explicitly REJECTED the Claude-only placement (option b) as a property mismatch (C is not Claude-only). | COMPLIANT |
| separate-pack-ops-from-product | §2 keeps the line explicit: C's RULE (pack-ops trinity + RATIONALE) vs C's PROJECT deliverable (project trinity + PM-CHAT) vs the pipeline facet (BD-238 pack-ops / BD-239 product METHODOLOGY); §3.3 names the facet-split as the separation line; §5.3 flags Check-36 (project surfaces ⇒ not `pack-only`). | COMPLIANT |
| cross-cli-reference-normalization | §1.2 Bullet C ×3 substitutes carve-out (1)'s per-CLI re-engage reference (Claude `SendMessage` / Codex `resume_agent` / Antigravity known-ID rewake) — audience-correct, NOT a byte-copy; C-PR1/C-PR2 likewise per-CLI for the re-engage clause; rule body/roster/exemption identical across all three. | COMPLIANT |
| graph-first-context | Ran `graphify query "reconciliation pass fresh instance agent reuse" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` FIRST (the INJECTED absolute path, NOT my own toplevel) → 21 nodes, all test-script/tracker-fixture provenance, ZERO rule-body nodes (§7 claim A) → G2 fallback to grep/Read for every load-bearing surface. | COMPLIANT |
| skill-agent-maintenance-mechanical | No agent-definition (`.claude/agents/*.md` / `.codex/agents/*.toml` / plugin bundle) files touched; no `x-` contract change. C is a corpus-rule + docs edit only; verified no agent def in the blast radius. | N/A: no agent-def edit in scope |
| rule-10 parallelization map | §5.2 dedicated table: C edits files already serialized (trinity + RATIONALE within BD-241; cross-BD BD-238/240/241); C's only new surface (project trinity) serializes with BD-239; NO new collision/wave introduced. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Only read-only git: `git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`, `git status --short`. ZERO state-changing verbs. Sole filesystem write = this doc at `/tmp/pack-handoff-bd241-arch/DESIGN-BD-241-D3-ADDENDUM.md` (chunked heredoc appends). No destructive op. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, COMPLIANT/N-A terminal; includes the graph-query-ran row (graph-first-context, above) with the exact command + the provenance-only result that triggered G2. No empty-evidence rows. | COMPLIANT |

---

*End DESIGN-BD-241-D3-ADDENDUM. Read-only architect D3 pass; no patch produced; sole write
is this doc. EXTENDS (does not supersede) DESIGN-BD-241-RECONCILED.md — its settled
decisions, two rules, propagation tables, and rule-10 map are FIXED inputs, NOT re-opened.
Codifies ONE new rule — `reconciliation-instance-independence` — across C=both: BD-241
surfaces designed NOW (Bullet C trinity ×3 + rationale + project trinity + PM-CHAT, with the
docs-researcher exemption + user-override + architect-challenge carve-outs) and the
BD-238/239 pipeline-structure facet spec'd as a cross-reference handoff. Compatibility:
REINFORCE across the board, three CLARIFY near-edges, one narrow EXPAND of
fresh-agent-default, ZERO genuine contradictions (the §4.1 near-edge is a memory-prose
two-sense clarification). validate-pack stays green (Checks 18/45/46/62/36); no new check.
Plan-ready after the §8 user gate.*
