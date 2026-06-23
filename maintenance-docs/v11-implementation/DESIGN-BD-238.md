# DESIGN-BD-238 — PACK-SIDE large-BD development pipeline as one official, size-tiered standard

**Role:** pack-architect (RO). **BD:** BD-238 (LARGE; user-confirmed 2026-06-23). **Output:** this design doc only. **Next stage:** adversarial architect review → reconciliation → planner.

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `67078627327d70f30d89d0f8500eb6e91993cffd` (later than expected `6707862` ✓) |
| branch | `v11-dev` |
| `git status --short` | clean |
| graph | `graphify-out/graph.json` queried for DISCOVERY (returned only project-side PACK-FEEDBACK.md agent nodes → operating-doc rules are NOT graph-indexed → grep/Read used for VERIFICATION, G2 fallback) |
| writes | EXACTLY ONE: this design doc. No source edits. Read-only git only. |

---

## 1. Executive summary

BD-238 asks to promote the rigorous large-BD development flow — already run ad hoc (BD-237 end-to-end, BD-206 in flight) — into ONE official, size-tiered, in-repo standard. The flow's spine ALREADY exists in trinity `## Pack memory` as five separate rules (researcher-first / architect-spawn / planner-to-coder / reconciliation-instance-independence / bounded-review-fix-cycle) plus the CLAUDE-only worktree section (rule 10) and the PACK-CHAT.md merge-back lifecycle. The TWO genuine gaps BD-238 closes are:

1. **No chaining + no size-tiering rule.** There is no single rule that (a) names the full ordered chain as ONE standard, (b) declares the two adversarial reviews + reconciliation the MINIMUM for a LARGE BD and OPTIONAL for a SMALL BD, and (c) gives a concrete measure-then-bound large-vs-small criterion.
2. **Adversarial stages exist only out-of-repo + situationally.** "Adversarial architect/planner review" lives only in two out-of-repo Pack-Chat memories framed situationally ("on a major gap" / "major plans"), never as a documented standard tier.

The design adds **ONE new umbrella rule** (`large-bd-pipeline-standard`) to trinity `## Pack memory` `### Agent invocation rules`, REFERENCING (not re-authoring) the five existing pipeline rules, plus a consolidated **lifecycle reference section** in `pack-ops/PACK-CHAT.md` and a roster cross-reference note in `pack-ops/PACK-AGENTS.md`. The new rule carries a `[rationale: large-bd-pipeline-standard]` slug propagated through the full surface set (rationale bijection + spawn-rule manifest + reference surfaces). The two out-of-repo adversarial memories are reconciled to POINT AT the in-repo standard (trinity-wins). No existing rule is contradicted — the umbrella consolidates and orders them.

**No purpose-defeating gap found.** Two design decisions (umbrella-vs-retag; how to express the Claude-only worktree-wave step without a parity port) are resolved below with evidence, not deferred.

---

## 2. Re-baselined measure-then-bound (the state-drift flag, resolved)

BD-238 File/Symbol claims `grep -rln adversarial …` = NO matches at HEAD `62805a8`. **That baseline is STALE.** Re-measured at the live HEAD (Empirical-Evidence Block EB-1):

- "adversarial" NOW appears in trinity ×3 (`CLAUDE.md:271,273` / `AGENTS.md:261,263` / `GEMINI.md:234,236`) and `PACK-MEMORY-RATIONALE.md:661,663,672,679` — **ALL inside the existing `reconciliation-instance-independence` rule + its rationale**, never as a standalone "adversarial review standard."
- So the premise "adversarial is undocumented in-repo" is now **PARTIALLY satisfied**: the WORD entered via the reconciliation rule, but the adversarial review as a NAMED, SIZE-TIERED standard TIER is still absent. The gap BD-238 closes is intact; the edit-LOCATION set is unchanged.

**Bound (KEEP/STRIP):** every live "adversarial" occurrence is KEEP (legitimate — part of the reconciliation rule). There is NOTHING to STRIP. The new rule must therefore be written to COEXIST with the reconciliation rule (it references it, never duplicates the word's meaning). The measure-then-bound conclusion: the design adds occurrences (the new umbrella rule + rationale), it removes none.

---

## 3. The size-tiering criterion (concrete, measure-then-bound)

The pack uses **BDs** as its work unit. The large-vs-small criterion is a **disjunction of four objective signals — ANY one makes the BD LARGE** (measure-then-bound: each signal is a yes/no test against repo state or the BD entry, not a vibe):

| # | Signal | Concrete test (yes ⇒ LARGE) |
|---|---|---|
| L1 | **Launch-gate** | The BD's `Target:`/`Position:` marks it a launch blocker for the current major (or the user names it launch-gating). |
| L2 | **Cross-surface** | The BD's edit-set spans ≥2 of: trinity `## Pack memory` · `pack-ops/` operating docs · `scripts/`+validators · `project-template/` product · agent/skill definitions. (Measured from the BD's File/Symbol census, the way this very BD was measured.) |
| L3 | **Blast-radius** | The BD changes a rule/contract/validator that ≥3 surfaces ENCODE (per `enumerate-encoding-surfaces`), OR a researcher blast-radius census is required before design. |
| L4 | **Structural** | The BD adds/changes a convention, a CI check, a file-tree shape, a migration path, or a trinity rule (i.e. it is architect-first per the pack-architect-spawn-protocol). |

**SMALL BD** = none of L1–L4 fire (a self-contained, single-surface, non-structural change — e.g. a one-doc typo class, a single-validator nit, a bookkeeping flip).

**Tiering consequence:**
- **LARGE BD** ⇒ the FULL pipeline by default; the two adversarial reviews + their reconciliation rounds are the **MINIMUM** (not optional). Additional architect/planner rounds added when larger gaps surface.
- **SMALL BD** ⇒ the BASE flow (optional researcher → architect → planner → coder + the bounded review/fix cycle); the two adversarial passes + reconciliation are **OPTIONAL at user election**.

**Why a disjunction, not a score:** a single high-signal axis (a launch-gate, or a trinity-rule change) ALONE warrants the full rigor; an AND-gate or weighted score would let a launch-gate BD slip to the base flow if it scored low elsewhere. Disjunction is the conservative, audit-clear bound. **Tie-break:** when in doubt, treat as LARGE (the rigor is cheap insurance vs. a missed adversarial pass on a launch-gate change) — this mirrors the existing "when in doubt … it is MAJOR" disposition in the pack-chat-minor-edits-only rule.

**This BD is LARGE** by L2 (trinity + pack-ops + out-of-repo memories + manifest/rationale), L3 (changes the rationale bijection + spawn-rule manifest that ≥3 surfaces encode), and L4 (adds a trinity rule + a `[rationale:]` slug) — consistent with the user's 2026-06-23 confirmation.


---

## 4. The exact rule text (operating-doc style) + placement

### 4.1 The new umbrella rule — trinity `## Pack memory` `### Agent invocation rules`

**Placement (byte-identical ×3):** insert as a NEW bullet IMMEDIATELY AFTER the `Researcher-first pipeline for substantive content` rule and BEFORE `Planner output → user review → coder spawn`, so the chain reads in pipeline order (researcher-first → [new umbrella] → planner-to-coder). Exact anchor lines (EB-2):

| File | Insert after line | Before line |
|---|---|---|
| `CLAUDE.md` | L296 (end of Researcher-first rule) | L296 (`Planner output …`) |
| `AGENTS.md` | L285 | L285 (`Planner output …`) |
| `GEMINI.md` | L257 | L257 (`Planner output …`) |

**Rule text (the canonical body; identical ×3 — fits the Check-66 1300-char cap, see §7.3):**

```
- **Large-BD pipeline standard (size-tiered).** Pack-side BD development
  runs ONE official pipeline: optional researcher(s) (internal census and/or
  external docs verification, per-need) → architect → adversarial architect
  review → [reconciliation if NEEDS-REWORK] → user design review → planner →
  adversarial planner review → [reconciliation if NEEDS-REWORK] → user
  planner-to-coder gate → parallel worktree coder waves (off the rule-10 map;
  each commit's bounded review/fix cycle in its worktree; patches applied
  sequentially under the conflict protocol; superseded docs deleted; audit
  set preserved). A BD is LARGE if ANY of — launch-gate / cross-surface (≥2
  surface families) / blast-radius (≥3 encoding surfaces or a required
  census) / structural (convention, CI check, tree shape, migration, or
  trinity-rule change); else SMALL. LARGE ⇒ the two adversarial reviews +
  reconciliation are the MINIMUM (more rounds on larger gaps); SMALL ⇒ the
  base flow (researcher → architect → planner → coder + the bounded cycle)
  with the adversarial passes OPTIONAL at user election. When in doubt, LARGE.
  Each stage obeys its own `## Pack memory` rule.
  `[roles: universal] [rationale: large-bd-pipeline-standard]`
```

**Body length: 1203 chars (whitespace-collapsed, the Check-66 measure) — UNDER the 1300-char cap; no allowlist record needed (verified EB-5). Anti-restate-safe: 0 contiguous ≥60-char overlaps with any existing `## Pack memory` imperative body (verified EB-7).** The rule references each stage's own `## Pack memory` rule by category ("its own `## Pack memory` rule") rather than enumerating slugs inline — this keeps it terse AND avoids reproducing any existing rule body. The slug list (researcher-first chain / reconciliation-instance-independence / planner-to-coder / rule-10 / bounded-review-fix-cycle) lives in the rationale section + the no-conflict analysis (§8), not the bullet.

**Design notes on the wording:**
- It NAMES the chain and the tiering inline (the two genuine gaps) and DELEGATES each stage's detail to the existing rules by `[rationale:]` reference — no re-authoring (anti-restate safe; the body does not reproduce ≥60 contiguous chars of any existing rule's body).
- It carries ZERO history/provenance/dates (operating-docs-no-history-no-bloat). No "BD-237 ran it," no dated notes.
- The `[roles: universal]` tag + the `[rationale: large-bd-pipeline-standard]` slug satisfy the controlled-vocab + bijection gates.
- The Claude-only worktree-wave step is expressed GENERICALLY ("parallel worktree coder waves … off the rule-10 map") — this is byte-parity-safe across the trinity because it REFERENCES the rule-10 map (which is itself Claude-only and Trinity-exempt) rather than RESTATING the worktree mechanics. AGENTS/GEMINI readers follow the reference to their platform's equivalent; no parity port of the Claude-only Sub-agent-behavior section is forced. (See the Claude-only flag resolution §8.2.)

### 4.2 The consolidated lifecycle section — `pack-ops/PACK-CHAT.md`

The orchestrator lifecycle that the standard's step 8 needs ALREADY EXISTS in full at `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back (worktree isolation)" (L228–391): How-Pack-Chat-spawns, Merge-back, the Parallelization map (rule 10) prose (L343), the Conflict protocol (L361), Report preservation / audit-set (Constraint 3, L349). **Do NOT duplicate it.** Instead add a short consolidating ANCHOR at the TOP of that section (a 2–4 line pointer) that frames the whole section as "the execution half of the large-BD pipeline standard," with a one-line reference to the trinity rule:

**Placement:** insert a sub-paragraph immediately under the H2 `## In-session sub-agent spawn + merge-back (worktree isolation)` (after L228, before the existing intro paragraph at L230).

**Text:**
```
This section is the EXECUTION half of the large-BD pipeline standard
(trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`): it is
the orchestration the standard's step 8 (parallel worktree coder waves)
runs. The DESIGN half (researcher → architect → adversarial → reconciliation
→ planner → adversarial → user gates) is the trinity rule chain.
```

This is a one-line REFERENCE (no verbatim restatement of the canonical body), so it is anti-restate-safe (Check 46). It does NOT introduce new lifecycle content — the section already documents the merge-back, rule-10, conflict protocol, and audit-set preservation.

### 4.3 The roster cross-reference — `pack-ops/PACK-AGENTS.md`

`pack-ops/PACK-AGENTS.md` § "Pack agents" (the roster + Class column, L8–25) is where the pipeline stages route to agents. Add a single one-line pointer beneath the roster (or in its lead-in) naming the standard and its trinity home:

**Text (one line):**
```
The order these agents run in is the large-BD pipeline standard — see
trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`.
```

This is the spawn-rule manifest `references:` surface for the new slug (so Check 46 reference-resolution passes). Anti-restate-safe (a pointer, not the body).


---

## 5. The full propagation surface set (per the Keeping-…-current procedure)

The rule-change propagation procedure (`pack-ops/PACK-CHAT.md` L475–489, the 6-row table) governs the exact surfaces + order. The new `large-bd-pipeline-standard` slug touches these surfaces **in lock-step, in one commit** (order: corpus → rationale → references + spawn-rule manifest in the SAME commit; cache as upkeep):

| Order | Surface | Exact edit | Gating check |
|---|---|---|---|
| 1 | **Corpus ×3 trinity** — `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory` `### Agent invocation rules` | Insert the §4.1 umbrella bullet, byte-identical, after the Researcher-first rule (L296 / L285 / L257) | Check 18 H2-parity (structure only — see §8.2); Check 66 bullet-concision (1300-char cap); Check 45 bijection (CLAUDE.md slug must map) |
| 2 | **`pack-ops/PACK-MEMORY-RATIONALE.md`** | Add a `## large-bd-pipeline-standard` section (Why / How / Rejected alternative — model on the reconciliation-instance-independence entry, L659–683). Insert near the existing pipeline rationales (after `## reconciliation-instance-independence`, L683) | Check 45 bijection (slug-set equality vs CLAUDE.md); Check 66 (RATIONALE.md rule bullets capped too — keep each bullet ≤1300) |
| 3 | **`pack-ops/.spawn-rule-manifest.txt`** | Add a record: `slug: large-bd-pipeline-standard` / `canonical: ## Pack memory` / `corpus: ### Agent invocation rules — "Large-BD pipeline standard (size-tiered)"` / `references: PACK-AGENTS.md § "Pack agents" (pipeline order = the standard); PACK-CHAT.md § "In-session sub-agent spawn + merge-back" (execution half)` | Check 46 reference-resolution (every named reference surface exists + carries the `## Pack memory` pointer) |
| 4 | **Reference surfaces** — `pack-ops/PACK-AGENTS.md` (§4.3 one-liner) + `pack-ops/PACK-CHAT.md` (§4.2 anchor) | Add the two one-line references named in the manifest record | Check 46 reference-resolution + anti-restate (no ≥60-char verbatim body) |
| 5 | **Out-of-repo thin memory-cache pointer** | Pack-Chat upkeep: a new pointer line in the pack-side MEMORY.md index (or update the two adversarial-memory entries — see §6) | No validator (trinity-wins) |
| 6 | `test-fixtures/manifest.txt` | NOT a propagation step. Only if an agent/skill FIXTURE input changed (it does not here — no agent-def or skill body edited). Push-time `manifest-sync.sh` reconciles | CI `build.sh --verify` + Check 62 (push-time only) |

**Spawn-rule-manifest decision (Ambiguity #3, resolved): ONE new umbrella slug, NOT re-tagging the three untagged rules.** The three existing pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) carry NO `[rationale:]` tag today and are NOT in the manifest. Re-tagging them would (a) force three NEW bijection rows + three rationale sections for rules that already work untagged, (b) be scope creep beyond BD-238's ask (codify the CHAIN + tiering), and (c) risk anti-restate churn. The umbrella slug REFERENCES them by name in its body (§4.1) without requiring them to be tagged. **Bound:** exactly ONE new slug, ONE new rationale section, ONE new manifest record, two reference one-liners. This is the minimal propagation footprint that satisfies the acceptance criteria.

### 5.1 Surfaces explicitly NOT touched (with evidence)

Per `enumerate-encoding-surfaces`, the surfaces that do NOT encode the standard and stay untouched (avoiding false scope):

- **Pack agent defs** (`.claude/.codex/.agents-plugin pack-{architect,coder,docs-researcher,planner,reviewer}.md`) — grep-zero for pipeline-stage vocab (research B3; re-confirmed via the graph returning no operating-doc nodes). They document per-agent mandates, not the chain. An OPTIONAL one-line pointer is NOT added (it would create 5×3=15 parity-maintained edits for marginal value, and would need Check 52 re-verification). DECISION: do NOT touch agent defs.
- **Pack skills** (11 skills ×3 mirrors) — grep-zero for the chain/tiering (research B4). The 4 spawn-relevant skills (`commit-discipline`, `review`, `planning`, `implementation-report`) are anti-restate TARGETS (Check 46) — they must NOT receive the canonical body. DECISION: do NOT add the rule body to any skill. (If a future BD wants a `planning`-skill pointer, that is a separate, scoped change — not this BD.)
- **`pack-ops/DRY-RUN-MIGRATION.md` + `MERGE-STRATEGY.md`** — their "reconciliation" hits are the migrator file-merge state, NOT the pipeline (research B2 note, quoted). Out of blast radius. DECISION: do NOT touch.

---

## 6. Reconciling the two out-of-repo adversarial memories

The two out-of-repo Pack-Chat memories are reconcile-TARGETS (not repo edits; no validator gates them; trinity-wins on any conflict). Locations (research B6):
```
/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/
  feedback_adversarial_architect_review_on_major_gap.md
  feedback_adversarial_planner_review_major_plans.md
```

**Reconciliation (Pack-Chat memory upkeep, step 5 of §5):** edit each memory's body to OPEN with a one-line pointer to the in-repo standard and reframe its situational guidance as a SUBORDINATE detail of the standard's adversarial tier:

- `feedback_adversarial_architect_review_on_major_gap` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard` (trinity `## Pack memory`): the adversarial ARCHITECT review is the MINIMUM for a LARGE BD (not only 'on a major gap'). This memory adds the major-gap escalation detail. Trinity wins on any conflict."
- `feedback_adversarial_planner_review_major_plans` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard`: the adversarial PLANNER review is the MINIMUM for a LARGE BD. This memory adds the major-plan detail. Trinity wins."

**Why reconcile rather than delete:** the standard makes the adversarial passes the large-BD MINIMUM (broader than "situational"); the two memories carry useful ESCALATION detail (when to add MORE rounds on a major gap) that the terse trinity rule intentionally omits (operating-docs-no-history-no-bloat). Pointing them at the standard removes the contradiction (situational vs minimum) while preserving the detail in the reference layer. **Trinity-wins** is stated explicitly in each, so a fresh session that reads only the memory is redirected to the SSOT.

**Index pointer:** the pack-side MEMORY.md index entries for these two files get their one-line pointers updated to note the subordination (the index already lists them under "Design discipline").


---

## 7. Pack-root trinity parity-enforcement flag (resolved) + Check-66 fit

### 7.1 What enforces pack-root trinity `## Pack memory` parity (Flag 2, resolved)

The research census said Checks 16/18/19 are "template-only." That is **only half-right** — re-measured at the live HEAD (EB-3):

- **Check 16** (`## Project addenda` H2) IS pack-root-EXEMPT (short-circuits via `_CHECK_16_EXEMPT_SURFACES`; `validate-pack.py:1974`). Correct — it gates a client-reconciliation mechanism with no purpose at pack-root.
- **Check 18** (H2 structure parity) **RUNS at pack-root** (`validate-pack.py:11356`, `check_trinity_h2_parity[pack-root]`). BUT it compares ONLY `## ` heading LINES (`line.startswith("## ")`, `validate-pack.py:1637`) — it asserts the three files share the same H2 set/order, NOT that the `## Pack memory` BODY is byte-identical.
- **Check 19** (no body scaffolding) RUNS at pack-root but only forbids stray HTML comments.

**CONCLUSION — there is NO CI check that byte-compares the pack-root `## Pack memory` rule BODIES across CLAUDE/AGENTS/GEMINI.** Check 45 bijection uses CLAUDE.md as the SOLE representative corpus (`validate-pack.py:7359`); AGENTS/GEMINI slugs are not bijection-checked. Check 66 caps each file's bullets independently but does not cross-compare. **Pack-root trinity body parity is a DISCIPLINE (the trinity-rule), not an auto-caught CI invariant** — the SAME gap class flagged for BD-244's Check 66.

**Design consequence (parity-preservation):** because no CI catches a body-parity drift, the implementation MUST treat the ×3 insertion as a single atomic, byte-identical edit and the **planner must add an explicit parity-verification step**: after the three inserts, run a normalized diff of the new bullet across the three files (e.g. extract the bullet from each and `diff`) and a coder PREFLIGHT attestation that the three bodies are byte-identical. This is the measure-then-bound backstop for the un-gated invariant. (The adversarial architect should scrutinize whether a NEW CI check for pack-root `## Pack memory` body parity is in-scope for BD-238 — see §9 open-question-for-adversary; my recommendation is NO, it is a separate structural BD, but I flag it rather than silently omit.)

### 7.2 Check 18 H2-parity is satisfied automatically

The new rule is a BULLET inside the EXISTING `### Agent invocation rules` subsection under the EXISTING `## Pack memory` H2. It adds NO new `## ` heading. Therefore Check 18 (H2 set/order) is unaffected ×3. Verified: the insertion point is mid-section, not a new H2.

### 7.3 Check 66 bullet-concision fit (the BD-244 trap, pre-cleared)

Check 66 caps each top-level `- ` bullet (rule + 2-space continuation lines, whitespace-collapsed) at **1300 chars** (`_CHECK_66_BULLET_CHAR_CAP = 1300`, `validate-pack.py:7989`), over the surface `(CLAUDE.md, AGENTS.md, GEMINI.md @ ## Pack memory)` + `PACK-MEMORY-RATIONALE.md` (`validate-pack.py:7993`). The densest existing legitimate rule (reconciliation-instance-independence) measures 1260 chars (EB-4).

**The §4.1 rule body measured whitespace-collapsed (EB-5): 1203 chars — UNDER the 1300 cap.** No allowlist record needed. (A first draft measured 1493 chars / OVER cap; it was reduced to 1203 by dropping the inline slug enumeration into the rationale section — option (a), the preferred measure-then-bound path. EB-5 records both measurements.) If the adversarial review or the planner expands the wording past 1300, the options are (a) reduce (move detail to the rationale section — the preferred path), or (b) add a `.bullet-concision-allowlist.txt` record with a reviewer-verified reason. The design TARGETS option (a): the rule stays terse by delegating stage detail to the referenced rules + the rationale section.

**Continuation-line discipline:** the rule body uses 2-space-indented continuation lines (matching the existing bullets) so `_check_66_iter_bullets` joins it as ONE bullet. The PACK-MEMORY-RATIONALE.md `## large-bd-pipeline-standard` section must ALSO keep each of its bullets ≤1300 (it is on the Check-66 surface) — the Why/How/Rejected paragraphs are prose, not `- ` bullets, so they are not capped, but any `- ` sub-bullet inside must stay terse.

---

## 8. No-conflict analysis vs existing trinity rules

The umbrella standard CONSOLIDATES and ORDERS the existing rules; it must not CONTRADICT any. Per-rule analysis (each existing rule re-read at the live HEAD):

### 8.1 The five pipeline rules — REFERENCED, not overridden

| Existing rule | Relationship | Conflict? |
|---|---|---|
| **Researcher-first pipeline for substantive content** (CLAUDE.md L288–296) | The standard's optional-researcher step + base chain spine. The standard makes the researcher OPTIONAL-per-need (matching the rule's "When agent work depends on … external sources"). | NONE — the standard widens "researcher" to internal+external (the rule already covers external; internal census is the docs-researcher's other mode, used by this very BD). The standard does not weaken "architect runs AFTER researcher." |
| **Planner output → user review → coder spawn** (L296–306) | The standard's step 7 (user planner-to-coder gate). Cited verbatim by reference. | NONE — identical gate. |
| **Reconciliation-instance independence** (L270–287) | The standard's reconciliation rounds use a FRESH instance per round. The standard cites this rule as the round's governing rule. | NONE — the standard does not name WHO reconciles (that rule does: a fresh instance). No duplication of the fresh-instance mandate in the umbrella body (anti-restate-safe). |
| **Pack-architect spawn protocol** (L556–569) | The standard's architect-first framing + the multi-stage pipeline commitment. The protocol's "architect-spawn requires user approval" governs entry INTO the standard. | NONE — the standard is the pipeline the protocol already says an architect-spawn commits to. The protocol gates the START; the standard names the SHAPE. |
| **Pack Chat NO coder review; bounded reviewer/fix cycle** (L580–587) | The standard's step 8 per-commit cycle (≤2 review/fix pairs + 1 final). Cited by reference. | NONE — the standard runs this cycle INSIDE each worktree; the bound (2+1) is unchanged. |

### 8.2 The worktree rules incl. rule 10 — Claude-only, referenced not parity-ported (Flag/Ambiguity #4, resolved)

The worktree mechanics + **Parallelization map (rule 10)** live ONLY in `CLAUDE.md` `### Sub-agent behavior (Claude-only)` (L381–478) — grep-zero in AGENTS/GEMINI (research B1, re-confirmed EB-6). This section is **Trinity-exempt by documented design** (CLAUDE.md L468–478: "not mirrored in AGENTS.md / GEMINI.md because its rules are built against Claude Code's Agent-tool mechanism").

**Resolution:** the umbrella rule (which IS trinity-parity ×3) expresses step 8 GENERICALLY as "parallel worktree coder waves (scheduled off the rule-10 map …)". This phrase:
- Is byte-IDENTICAL across the three files (it references the rule-10 map; it does not restate the worktree mechanics).
- Does NOT force a parity port of the Claude-only section — a port would VIOLATE the documented Trinity-exemption.
- For AGENTS/GEMINI readers (Codex/Antigravity), "worktree coder waves" maps to their platform's native parallel-spawn (Codex `agents.max_threads`; Antigravity dynamic subagents — both documented in the Claude-only section's prose as platform-native). Their worktree story is a future pack version; the standard's SHAPE (parallel coder waves keyed off a dependency map) is platform-agnostic, the MECHANISM is not.

**No conflict:** the umbrella rule is parity-safe BECAUSE it references rather than restates the Claude-only mechanics. The PACK-CHAT.md anchor (§4.2) points at the merge-back section where the Claude-specific detail lives.

### 8.3 Conflict protocol + audit-set + report preservation — already in PACK-CHAT.md

The standard's "patches applied sequentially under the conflict protocol; superseded docs deleted; audit set preserved" maps 1:1 to PACK-CHAT.md § Conflict protocol (L361–390), Report preservation / Constraint 3 (L349–359). The umbrella rule references these via the §4.2 PACK-CHAT.md anchor. No new lifecycle content; no conflict.


---

## 9. My OWN rule-10 parallel/dependency map for the BD-238 implementation

Per rule 10, this design produces the parallel-vs-dependent map for the implementation commits. The propagation procedure mandates corpus → rationale → references + manifest **IN THE SAME COMMIT** (so the bijection + anti-restate checks never see a half-applied state, PACK-CHAT.md L488). That single atomicity constraint dominates the map:

### 9.1 The commits

| Commit | Scope | Same-file overlap | Parallel/serial |
|---|---|---|---|
| **C1** (the standard) | Corpus ×3 trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` §4.1) + `PACK-MEMORY-RATIONALE.md` (§5 row 2) + `.spawn-rule-manifest.txt` (row 3) + `PACK-AGENTS.md` reference (§4.3) + `PACK-CHAT.md` anchor (§4.2) | ALL on the Check-45/46 bijection+anti-restate critical set — must be atomic | **ONE serial commit.** Cannot be split (bijection/anti-restate would fail on a half-applied state). |
| **C2** (out-of-repo memory reconciliation) | The two Pack-Chat memory files + the MEMORY.md index pointers (§6) | Out-of-repo; no validator; disjoint from C1's tracked files | **Pack-Chat upkeep, AFTER C1 lands.** Not a coder commit (out-of-repo memory). Serial-after-C1 (it points at C1's slug). |
| **C3** (audit-set preservation) | Move this design + the adversarial review + reconciliation + planner + coder/reviewer reports from `/tmp` → `maintenance-docs/v11-implementation/` | Disjoint from C1 (different tree) | **Paired pack-only commit immediately after C1** (Constraint 3 / Report preservation, PACK-CHAT.md L349). |

### 9.2 Parallelization verdict

- **C1 is a SINGLE serial commit, NOT parallelizable.** The corpus-→-rationale-→-manifest-+-references atomicity (the propagation order's same-commit rule) forces one commit; the ×3 trinity edit is byte-identical so one coder does all three files (splitting risks parity drift, which no CI catches — §7.1). A single fresh `pack-coder` in one isolated worktree applies all of C1's edits.
- **No same-file collision** within C1 (each file edited once) and **no cross-commit same-file collision** (C1 = tracked operating docs; C2 = out-of-repo; C3 = `maintenance-docs/`). So the conflict protocol is not exercised — this is a serial single-coder effort, not a multi-wave one.
- **Sequence:** C1 (coder in worktree → bounded review/fix cycle → patch after review-clean → user-approved commit) → C3 (paired report commit) → C2 (Pack-Chat memory upkeep). C2 and C3 are independent of each other and both depend only on C1's slug existing.

**Conclusion: the BD-238 implementation is SERIAL (one coder commit + one paired report commit + out-of-repo upkeep), not a parallel-wave effort** — the atomicity constraint of the propagation procedure is the binding reason. The map exists (rule 10 satisfied) and its verdict is "no parallelization available; serialize."

---

## 10. Planner handoff — open design questions: NONE

A planner can turn this into a commit sequence with zero open design questions:
- **Exact rule text + placement:** §4.1 (rule body, verified 1203 chars, anti-restate-safe; insert after Researcher-first at CLAUDE.md L296 / AGENTS.md L285 / GEMINI.md L257) + §4.2 (PACK-CHAT.md anchor) + §4.3 (PACK-AGENTS.md one-liner).
- **Size-tiering criterion:** §3 (L1–L4 disjunction + tie-break-to-LARGE).
- **Propagation surface set:** §5 (6-row table, one umbrella slug, exact edits + gating checks) + §5.1 (surfaces NOT touched, with evidence).
- **Out-of-repo memory reconciliation:** §6 (prepend pointers, trinity-wins, preserve escalation detail).
- **Rule-10 map:** §9 (serial; one coder commit; no parallelization).
- **No-conflict analysis:** §8 (per-rule, all NONE; Claude-only worktree handled by generic reference).
- **Parity-enforcement gap:** §7.1 (no CI gates pack-root `## Pack memory` body parity → planner adds an explicit byte-parity verification step + coder PREFLIGHT attestation).
- **Check-66 fit:** §7.3 (1203 < 1300; no allowlist).

### 10.1 Flagged FOR the adversarial architect (not a gap — a scope question)

§7.1 surfaces that NO CI check byte-compares pack-root `## Pack memory` rule BODIES across the trinity (Check 18 = H2 headings only; Check 45 = CLAUDE.md-representative; Check 66 = per-file cap). My RECOMMENDATION: do NOT add a new pack-root body-parity CI check in BD-238 — it is a separate structural BD (it would re-baseline every existing pack-root `## Pack memory` rule for ×3 byte-identity, a much larger blast radius than BD-238's ask). BD-238 preserves parity by DISCIPLINE (atomic ×3 edit + planner verification step + coder PREFLIGHT). The adversary should challenge whether discipline is sufficient or whether a guard is in-scope. This is the ONE judgment call I am explicitly surfacing per `adversarial-architect-review-on-major-gap` rather than silently resolving.

---

## 11. Empirical-Evidence Blocks (every state-claim)

**EB-1 — "adversarial" re-baseline at live HEAD.**
- Command: `grep -rn "adversarial" CLAUDE.md AGENTS.md GEMINI.md pack-ops/*.md supporting-docs/*.md`
- Output (verbatim, key lines): `CLAUDE.md:271,273` / `AGENTS.md:261,263` / `GEMINI.md:234,236` (all "resolving an adversarial review's findings…" + "NOR the adversarial reviewer…") and `pack-ops/PACK-MEMORY-RATIONALE.md:661,663,672,679`. Zero matches in supporting-docs/*.md.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: every occurrence is part of the existing `reconciliation-instance-independence` rule + rationale. BD-238's stale baseline (`62805a8` = zero) no longer holds.
- Conclusion: SUPPORTED — the WORD exists in-repo (via the reconciliation rule) but NOT as a named size-tiered standard tier; the BD-238 gap is intact; nothing to STRIP; the new rule must coexist with (reference, not duplicate) the reconciliation rule.

**EB-2 — placement anchor lines for the umbrella rule.**
- Command: `grep -n "### Agent invocation rules|Researcher-first pipeline|Planner output" CLAUDE.md AGENTS.md GEMINI.md`
- Output: CLAUDE.md — Researcher-first L288–296, Planner output L296; AGENTS.md — Researcher-first L277, Planner output L285; GEMINI.md — Researcher-first L249, Planner output L257.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the insertion point (after Researcher-first, before Planner output) is mid-`### Agent invocation rules`, identical structure ×3.
- Conclusion: SUPPORTED — placement is byte-parity-feasible; adds no new H2 (Check 18 unaffected).

**EB-3 — pack-root trinity parity enforcement.**
- Command: read `scripts/validate-pack.py` check registry (L11344–11366) + `check_trinity_h2_parity` body (L1585–1644) + `check_pack_memory_rationale_bijection` (L7357–7402).
- Output (verbatim): registry has `(16, "…[pack-root]", lambda: check_trinity_addenda_h2(REPO_ROOT, "pack-root"))`, `(18, "…[pack-root]")`, `(19, "…[pack-root]")`. Check 16 short-circuits via `_CHECK_16_EXEMPT_SURFACES` (L1974 `surface exempt — Check 16 is template-only`). Check 18 collects `[line for line if line.startswith("## ")]` (L1634–1638) — H2 headings ONLY. Check 45 `corpus_path = REPO_ROOT / "CLAUDE.md"` (L7359) — CLAUDE.md sole corpus.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 16 is pack-root-exempt; Check 18 runs at pack-root but compares only H2 heading lines; Check 45 uses CLAUDE.md only. No check byte-compares the `## Pack memory` rule BODIES across the three pack-root files.
- Conclusion: SUPPORTED — pack-root `## Pack memory` body parity is DISCIPLINE-enforced, not an auto-caught CI invariant (the BD-244 Check-66 gap class). Resolves Flag 2.

**EB-4 — densest existing legitimate rule bullet length.**
- Command: Python re-implementation of `_check_66_iter_bullets` over `CLAUDE.md` `## Pack memory`.
- Output: reconciliation-instance-independence = 1260 chars; Researcher-first = 485; Planner output = 449; Pack-coder PREFLIGHT = 626; Pack-architect spawn = 737; bounded reviewer = 512; max over-all = Graph-first = 4275 (allowlisted).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the cap (1300) sits just above the densest legitimate rule (1260); over-cap rules (Graph-first 4275, sub-agent isolation, pack-chat-minor) are allowlisted.
- Conclusion: SUPPORTED — a new rule must measure ≤1300 or be allowlisted.

**EB-5 — proposed rule body length (TWO measurements).**
- Command: Python whitespace-collapse join of the proposed bullet lines (the Check-66 measure).
- Output: first draft = **1493 chars (OVER the 1300 cap)**; reduced draft (the §4.1 final, slug-enumeration moved to rationale) = **1203 chars (UNDER cap)**.
- HEAD/date: 2026-06-23.
- Interpretation: the initial wording failed Check 66; the reduction (drop inline slug list, compress phrasing) brings it under cap WITHOUT losing the chain + tiering content.
- Conclusion: SUPPORTED — the §4.1 final rule (1203 chars) passes Check 66 with no allowlist; the over-cap first draft is recorded to show the measure-then-bound reduction, not hidden.

**EB-6 — Claude-only worktree section grep-zero in AGENTS/GEMINI.**
- Command: `grep -rn "Sub-agent behavior (Claude-only)|Parallelization map (rule 10)" CLAUDE.md AGENTS.md GEMINI.md`
- Output: only `CLAUDE.md:381` (section) + `CLAUDE.md:416` (rule 10). Zero in AGENTS.md / GEMINI.md.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the worktree mechanics + rule 10 are Claude-only (Trinity-exempt per CLAUDE.md L468–478).
- Conclusion: SUPPORTED — the umbrella rule must reference (not restate/port) the worktree-wave step to stay byte-parity-safe ×3. Resolves Flag/Ambiguity #4.

**EB-7 — anti-restate self-check of the final rule body.**
- Command: Python scan — every ≥60-char window of each existing CLAUDE.md `## Pack memory` imperative body tested as a substring of the whitespace-normalized final rule body.
- Output: `anti-restate hits (>=60-char overlaps): 0`.
- HEAD/date: 2026-06-23.
- Interpretation: the final rule body reproduces no ≥60 contiguous chars of any existing rule body.
- Conclusion: SUPPORTED — Check 46 anti-restate will pass for the canonical rule; the reference one-liners (§4.2/§4.3) are pointers, also under 60 chars of body.

**EB-8 — README major version (audit destination).**
- Command: `grep -n "| v11" README.md`
- Output: top version row `| v11.0 | May 2026 | …`.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: current major = v11.
- Conclusion: SUPPORTED — the §9.1 C3 audit-set destination is `maintenance-docs/v11-implementation/`.

**EB-9 — BD-239 disjointness + starting-point-not-ceiling.**
- Command: read `backlog/BD-239.md` 2026-06-23 note (L32).
- Output (verbatim): "both BD-238 and BD-239 are LARGE BDs and BOTH run the FULL large-BD pipeline … BD-238 is a STARTING POINT, not an end goal or ceiling … the edit-sets are disjoint — pack self-operation surfaces vs project-side surfaces, researcher-confirmed 2026-06-23."
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: BD-238's pack-side edit set is disjoint from BD-239's project-side set; BD-239 reuses the SHAPE, not the wording.
- Conclusion: SUPPORTED — this design scopes strictly to pack-side surfaces; the project-side companion is BD-239's job (no project-template edits here).


---

## 12. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Only Write performed = `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238.md` (created the dir with `mkdir -p`). All git invocations read-only: `git rev-parse HEAD` → `67078627…`, `git status --short` → clean, `git ls-files`/`grep` only. No `add`/`commit`/`push`/`checkout`/any state-changing verb issued. | COMPLIANT |
| 2 | **no-solutions-beyond-the-premise** | The pipeline SHAPE + size-tiering INTENT are the user-approved BD-238 premise (quoted from BD-238 L16–28). I DERIVED only what BD-238 delegated to the architect: the rule WORDING (§4.1), the PLACEMENT (§4–5), the concrete size criterion (§3, L1–L4 disjunction), the consolidated-section design (§4.2–4.3), the umbrella-vs-retag decision (§5, evidence-based), and the parity-preservation design (§7.1). No new feature invented beyond the premise. The one judgment call (a new parity CI check) is SURFACED to the adversary (§10.1), not silently resolved. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §11 carries EB-1…EB-9: every state-claim (the re-baseline, placement anchors, parity enforcement, bullet lengths, the over-cap-then-reduced rule body, Claude-only grep-zero, anti-restate self-check, major version, BD-239 disjointness) backed by command + verbatim output + HEAD `67078627…` + interpretation + SUPPORTED conclusion. EB-5 records the FAILED first measurement (1493) honestly. | COMPLIANT |
| 4 | **operating-docs-no-history-no-bloat** | The §4.1 rule text carries ZERO history/provenance/dates ("no BD-237 ran it," no dated notes); it is terse + structured (1203 chars, verified UNDER the 1300 Check-66 cap, EB-5) — the BD-244 Check-66 trap was pre-cleared by reducing the first 1493-char draft. The §4.2/§4.3 references are one-liners. No deferred-feature mentions (the Claude-only worktree-wave is CURRENT, expressed as a live reference, §8.2). | COMPLIANT |
| 5 | **trinity-rule** | The rule is designed byte-identical ×3 (§4.1, placement EB-2). §7.1 resolves the parity-enforcement flag: no CI gates pack-root `## Pack memory` body parity (Check 18 = H2 headings only L1637; Check 45 = CLAUDE.md-representative L7359) → the design mandates an atomic ×3 edit + a planner byte-parity verification step + coder PREFLIGHT attestation (§7.1, §10). The Claude-only worktree section is NOT parity-ported (Trinity-exempt, EB-6). | COMPLIANT |
| 6 | **enumerate-encoding-surfaces** | §5 enumerates EVERY surface that encodes the standard (corpus ×3, rationale section, spawn-rule manifest, two reference one-liners) + EVERY gating check (45 bijection, 46 reference-resolution+anti-restate, 18 H2-parity, 66 bullet-cap, 36 commit-scope, 62 push-time). §5.1 enumerates surfaces NOT touched WITH evidence (agent defs grep-zero, skills grep-zero/anti-restate-targets, migrator-reconciliation false-positives). No asymmetric coverage. | COMPLIANT |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | The design lands wholly in v11.0 (BD-238 Target: v11.0, EB-8 major=v11). No work is deferred. The ONE thing NOT done in BD-238 (a new pack-root body-parity CI check) is justified with LOGICAL-FIT + SIZE evidence (separate structural BD; would re-baseline every existing pack-root rule — larger blast radius than BD-238's ask) and SURFACED to the adversary + user (§10.1), not silently dropped. | COMPLIANT |
| 8 | **adversarial-architect-review-on-major-gap** | Output feeds a fresh adversarial architect. No purpose-defeating gap found (the standard's spine exists; the two genuine gaps — chaining+tiering and out-of-repo-only adversarial framing — are closeable). The one judgment call (discipline-vs-CI-guard for pack-root parity) is explicitly flagged FOR the adversary (§10.1) rather than forced. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — rules 1–9, each with (a) name, (b) quoted evidence, (c) terminal conclusion (no AMBIGUOUS, no empty evidence). | COMPLIANT |

---

*End of DESIGN-BD-238. Read-only architect pass; one Write (this doc). Next: fresh adversarial architect review → reconciliation → planner.*
