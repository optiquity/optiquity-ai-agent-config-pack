# Batch 19c V1 Architect — Principle Check

**Context:** Mid-V1-review, the user articulated a foundational
principle about PM chat as integration layer with bird's-eye-view
obligation. User asked Pack Chat and V1 architect to answer 3
questions independently, then compare.

**Status:** Captured for V1-review gate and V2-architect input. V1
doc (`ARCHITECTURE-CLEANUP-BATCH-19C.md`) stays frozen as-is. This
doc is a sibling artifact; it will be input to V2.

**Date:** 2026-05-17.

**Agents involved:**
- V1 architect: agent ID `ab5006c2a8c5882eb` (sub-agent of Pack Chat;
  spawned with `pack-architect` subagent type; provided V1 doc + this
  principle-check answer via SendMessage).
- Pack Chat: this PM chat session (provided independent answer + the
  comparison surface).

---

## §1 — User's principle (verbatim)

> The PM chat is the Project Manager, thus PM, and therefore is
> obligated to have a bird's eye view of all workflows and processes.
> Agents may know about other agents, but they are not obligated to,
> while the PM chat is obligated to. This means, that the PM chat is
> obligated to give agents all the information, rules, guardrails,
> and structure they need to do their work effectively AND so it
> integrates smoothly with other agent work they may not know about.
> This is a fundamental principle.

## §2 — User's 3 questions

1. Is this principle captured anywhere?
2. Is this principle being universally applied and followed?
3. If not, why not? Is there a good reason (e.g., race condition)?

User added: "you answer this for me and b) you SendMessage to the
architect who wrote the doc... Then compare your responses. I want
to know what each of you thinks and if there is a divergence (and
where)."

---

## §3 — V1 architect's answer

(Delivered via SendMessage; architect was instructed to answer
independently without consulting Pack Chat's view.)

### Question 1 — Is this principle captured anywhere?

**Not as a unified rule. Fragmented across derived rules. The
"obligation" framing is absent.**

The principle decomposes into two halves:
- (a) The PM chat has a bird's-eye view of all workflows/processes;
  agents do not.
- (b) The PM chat is OBLIGATED to give agents the rules / guardrails
  / structure they need so their work integrates with adjacent
  agents' work they may not know about.

Half (a) is implicit-but-strong. Half (b) is implicit-and-weak.

**Where half (a) appears (implicit):**

- `supporting-docs/METHODOLOGY.md` lines 23–27 — "**Claude Chat is
  the brain. Claude Code CLI is the hands.** They are not
  interchangeable. Claude Chat holds context, makes decisions, and
  generates prompts." This is the bird's-eye-view framing without
  naming it.
- `project-template/docs/pack/PM-CHAT.md` lines 31–39 — Role
  section: "You are the persistent project manager... Generate all
  agent prompts... Receive and analyze all agent output... Approve
  architectural and planning decisions..." Names the PM chat as the
  single point of orchestration without naming the obligation.
- `project-template/CLAUDE.md` (and AGENTS / GEMINI) `## Project
  memory` — "PM chat does not architect" bullet (lines 362–368) —
  describes the PM-chat-vs-agent SPLIT but in the negative ("does
  not do") rather than the positive ("is obligated to give").

**Where half (b) appears (implicit + weak):**

- `supporting-docs/METHODOLOGY.md` Part 3 lines 256–260 "Session
  rules" — "Agents have no memory between sessions — every prompt
  must be self-contained." This is the technical CONSTRAINT that
  creates the obligation, but it stops short of naming the
  obligation.
- `supporting-docs/METHODOLOGY.md` Part 5 lines 605–654 "Prompt
  Authoring Principles" — names WHAT goes in a prompt (problem /
  goal / success criteria / context / constraints / files in scope
  / out of scope) but frames it as a prompt-quality rule, not a
  PM-chat-obligation rule.
- `project-template/docs/pack/PM-CHAT.md` lines 182–187 "No
  solutions in agent prompts" — names a prohibition (no solutions);
  the inverse obligation (must give all needed structure) is
  unstated.
- OT memory dump OT-T-7 (lines 156–171) — "re-read agent prompts
  every time" — close but it's about template completeness, not
  PM-chat-as-omniscient-orchestrator obligation.

**Where it's missing entirely:**

- No bullet in PM-CHAT.md `## Behavioral rules` (lines 176–263)
  titled anything like "Bird's-eye view obligation" or "Cross-agent
  integration obligation."
- No section in METHODOLOGY.md Part 1 "Tool Roles" stating the
  obligation as a principle.
- No mention in any trinity `## Project memory` section.
- No OT memory entry.

**Verdict:** The principle is the IMPLICIT DESIGN PREMISE behind
~30% of pack rules but is never named. It's the dark matter holding
the design together.

### Question 2 — Is it universally applied?

**Strongly honored at the per-rule level. Inconsistently honored at
the meta level. Two probable violations in my V1.**

**Where it's HONORED:**

- `project-template/docs/pack/PM-CHAT.md` `## Permission profiles`
  (lines 266–371) — each profile lists exactly what the PM chat
  must put INTO each prompt (REPORT FILE, triad, files-in-scope,
  chunking). This is the obligation operationalized per-profile.
- METHODOLOGY.md "Prompt Authoring Principles" (lines 603–886) —
  the entire section operationalizes half (b).
- METHODOLOGY.md Part 5 lines 410–420 "agent-run.sh" callout — PM
  chat manages the flag profile so agents don't need to know
  git-disallowlist details.
- OT-T-7 / §C.7 in V1 — re-read per-agent prompt file every time +
  verify REPORT FILE header (PM chat's obligation to deliver
  complete prompts).
- METHODOLOGY.md Workflow 4 architect-trigger procedure (lines
  510–533) — PM chat orchestrates the trigger check and constructs
  the architect prompt with full reviewer context; the architect
  doesn't need to know its trigger fired.

**Where it's VIOLATED or INCONSISTENTLY APPLIED:**

- **V1 §D.2 mirror pattern — YES, this is a soft violation.** §D.2
  says "both-audience rules → mirror across both surfaces with
  IDENTICAL wording." The principle would suggest: PM-chat-only
  surface (PM-CHAT.md) carries the rule; the PM chat injects
  relevant subsets into agent prompts on demand. Mirroring delegates
  the omniscience to the agent file (agent loads CLAUDE.md and sees
  the same rule the PM chat sees). That's not WRONG — it's
  redundant-but-safe — but it doesn't follow the principle. It
  follows a different principle: "defense in depth via duplication."
- **V1 §C.6 trinity STRENGTHEN — also a soft violation.** Adding
  `git checkout --` to the trinity destructive-ops list means every
  agent loads the rule. Under the principle, the PM chat should KNOW
  which agents are at risk for this verb (only `coder` and
  `repo-ops` realistically run git) and inject the rule into THOSE
  agent prompts. Trinity-wide propagation is the defense-in-depth
  fallback.
- `project-template/.claude/agents/*.md` Hard rules sections —
  every agent file repeats "No state-changing git operations"
  verbatim. Under the principle, the PM chat should hold this rule
  centrally; agents should be ignorant of it (the harness enforces
  it via `--disallowedTools`). The current design hardcodes the
  rule in 48 places (16 agents × 3 CLIs).
- METHODOLOGY.md Part 9 "Document Authoring Rules" table (line
  1384) — the table is duplicated in `project-template/AGENTS.md`
  lines 298–305 and elsewhere. Same pattern.

**Where it's INCONSISTENTLY applied:**

- Some rules live PM-CHAT.md-only (closeout sequence — proposed
  §C.4). Others mirror across PM-CHAT.md + agent files (no
  destructive ops). The choice between the two is currently ad hoc.

### Question 3 — Why not universal? + recommendation

**Why not universal:**

1. **Defense in depth.** Agents may receive incomplete prompts (PM
   chat bugs, user-edited prompts, sub-agent spawns bypassing PM
   chat). Hardcoded agent-file rules survive prompt corruption.
2. **Evolution.** Pack v9 → v10 → v11 grew rules incrementally;
   each new rule's author chose its home without a documented
   placement principle. V1 §D.2 / §F D-4 surface this gap.
3. **Cross-CLI parity inconsistency.** Codex and Gemini have
   different prompt-injection ergonomics; mirroring rules into
   agent files is cheaper than building per-CLI injection logic.

**No technical race condition. No hard constraint. Underdocumented
for cultural / evolutionary reasons.**

**Recommendation: YES, add as stated principle in V2.** Place in
METHODOLOGY.md Part 1 "Tool Roles" (after the "Separation rule" at
line 98) as a NEW sub-section "PM chat omniscience obligation."
Then REWRITE §D.2 placement rule to reference it (the
trinity-vs-PM-CHAT.md rule becomes a SUBSIDIARY of the omniscience
principle, with defense-in-depth as the documented exception).

**Surface as §F D-11 in V2 with this principle as the architect
recommendation.** The principle reframes ~12 of the §C placements
— most should move PM-CHAT.md-only with PM-chat-injection-into-
prompts as the delivery mechanism; the trinity STRENGTHEN (§C.6)
becomes the exception requiring defense-in-depth rationale.

---

## §4 — Pack Chat's answer

(Produced independently before the architect's response arrived.)

### Question 1 — captured anywhere?

Partially captured, fragmented across:
- pack-side memory `feedback_agent_prompt_rules.md` ("every agent
  prompt must include context, output file path, read-only flags,
  markdown-only, problem/goal/criteria, and CLI command")
- METHODOLOGY.md agent dispatch table
- OT memory `feedback_template_read_fully` (re-read prompts)
- V1 architect's §D.2 placement rule

Never stated as a unified principle. The "PM chat is OBLIGATED to
brief agents" framing is absent.

### Question 2 — universally applied?

Partially applied.

HONORED in:
- V1 architect prompt I wrote (full context, OT clarification
  embedded, full read list)
- §D.2 placement rule (where rules live)
- OT-T-7 promotion to §C.7 (re-read prompts)

VIOLATED in:
- §D.2's mirror pattern (duplicates content across surfaces rather
  than PM-chat-injects)
- No explicit "PM chat briefs agents with integration context"
  rule anywhere

### Question 3 — why not, and what to do?

Not a race condition or technical reason. Underdocumented for
cultural / evolutionary reasons. OT memories captured the SYMPTOMS
(re-read prompts, template_read_fully) but not the underlying
PRINCIPLE.

**Recommendation:** Add explicit principle bullet to PM-CHAT.md
`## Behavioral rules`.

---

## §5 — Comparison

### §5.1 Convergences (5 points)

1. **Not captured as a unified rule.** Both confirm fragmented and
   never named as foundational principle.
2. **§D.2 mirror pattern is a soft violation.** Both flag.
3. **No technical / race-condition reason.** Both confirm cultural
   / evolutionary, not constraint-driven.
4. **Should be made explicit.** Both recommend codification.
5. **OT memories capture symptoms, not the underlying principle.**
   Both note OT-T-7 is close but misses the broader obligation.

### §5.2 Divergences (6 points; architect sharper on most)

| # | Dimension | Pack Chat | Architect | Sharper |
|---|---|---|---|---|
| 1 | Decomposition | One principle | Splits into half-(a) view + half-(b) obligation; half-(a) implicit-strong, half-(b) implicit-weak | Architect |
| 2 | Citations | Few specific locations | Cites line numbers: METHODOLOGY.md 23–27, 256–260, 605–654; PM-CHAT.md 31–39, 182–187, 266–371; §D.2 / §C.6 / §C.7 of V1 | Architect |
| 3 | Why-not causes | "Cultural / evolutionary" | Three distinct causes: defense-in-depth (prompt-corruption resilience), evolution, cross-CLI parity ergonomics | Architect — surfaces real architectural tension |
| 4 | Additional violation examples | §D.2 only | Also: §C.6 trinity STRENGTHEN; 48 hardcoded sites (16 agents × 3 CLIs) for "no state-changing git ops"; METHODOLOGY Part 9 doc-rules table duplicated | Architect — broader and concrete |
| 5 | Placement recommendation | PM-CHAT.md `## Behavioral rules` | METHODOLOGY.md Part 1 "Tool Roles" as NEW sub-section "PM chat omniscience obligation" | Architect — Part 1 is the foundational framing layer |
| 6 | Cascade impact | "Add a bullet" — no cascade | Adopting principle REFRAMES ~12 §C placements: most → PM-CHAT.md + injection; trinity STRENGTHEN (§C.6) becomes documented defense-in-depth exception | Architect — saw the cascade Pack Chat missed |

### §5.3 Pack Chat's honest assessment

The architect's answer is materially better than Pack Chat's.
Specifically:

- **Defense-in-depth as a RATIONAL counter-principle (not a bug).**
  Pack Chat framed mirroring as "violation." Architect framed it as
  "a different principle: defense in depth via duplication." That's
  a real architectural tension: the omniscience principle says
  "minimal duplication, PM injects," while defense-in-depth says
  "duplicate everywhere so prompt corruption doesn't lose the rule."
  This needs to be CHOSEN, not silently picked.

- **Cross-CLI parity ergonomics as a technical constraint.**
  Architect noted Codex / Gemini have different prompt-injection
  ergonomics, so mirroring is cheaper than building per-CLI
  injection logic. Pack Chat missed this. It means the principle
  can't be fully applied without per-CLI engineering work.

- **METHODOLOGY.md Part 1 placement.** Pack Chat picked PM-CHAT.md
  because that's where the PM chat's rules live. Architect picked
  METHODOLOGY.md Part 1 "Tool Roles" because that's where the
  FOUNDATIONAL framing already lives (Claude Chat = brain, Claude
  Code CLI = hands). The principle is a foundational framing
  claim, so it belongs with the other foundational framing claims.
  Architect's placement is correct.

- **Cascade through §C.** Architect identified that adopting the
  principle would reframe ~12 of the §C placements in V1. That's
  actionable structural feedback. Pack Chat missed it.

---

## §6 — Proposed D-11 wording for V2 §F

> **D-11 — Adopt PM-chat omniscience as a stated foundational
> principle?**
>
> **Question:** Both halves — (a) PM chat has bird's-eye view of
> all workflows, (b) PM chat is OBLIGATED to brief agents with the
> rules / guardrails / integration context they need — are
> currently implicit but never named. Should V11 codify this as a
> stated principle in METHODOLOGY.md Part 1 "Tool Roles"?
>
> **Architect recommendation:** YES. Cascade: §D.2 rewrites as
> subsidiary; ~12 §C placements reframe (most → PM-CHAT.md +
> injection); two named exceptions (defense-in-depth, cross-CLI
> parity ergonomics) documented as legitimate placement choices.
>
> **Alternatives:**
>
> - **Alt-1 (architect recommendation): LAND the principle in
>   METHODOLOGY.md Part 1 + cascade through §D.2 and §C.**
>   Reframes the V2 doc structure; documents two exceptions.
> - **Alt-2: LAND principle but DON'T cascade through §C.** Keep
>   V1 §C placements as-is for this batch; cascade in a later
>   batch. Risk: principle and §C placements out of alignment.
> - **Alt-3: SKIP — leave principle implicit.** Cost: future
>   cleanup batches re-derive the rule each time; defense-in-depth
>   exception is undocumented.
>
> **Decision needed at:** V2 gate.

---

## §7 — Path forward (after user resolves D-11)

If D-11 = Alt-1 (architect recommendation):
1. V2 architect reads V1 + pack-docs-researcher output + this
   principle-check doc + user's D-1..D-11 dispositions.
2. V2 §D.2 placement rule rewrites: trinity-vs-PM-CHAT.md becomes
   subsidiary of omniscience principle.
3. V2 §C reviews each of 12 placements; most move to
   PM-CHAT.md-only with prompt-injection delivery; trinity
   STRENGTHEN (§C.6) keeps trinity placement with defense-in-depth
   rationale documented.
4. V2 §F D-4 recommendation updates to reference D-11.
5. V2 documents two named exceptions: (a) defense-in-depth for
   prompt-corruption resilience, (b) cross-CLI parity ergonomics
   until per-CLI injection logic exists.
6. Planner reads V2; produces ordered task list.
7. User reviews planner output; spawns pack-coder per task.

If D-11 = Alt-2 (land principle, defer cascade):
- V2 documents principle but keeps V1 §C placements as-is for
  Batch 19c.
- New BD inserted for §C cascade in a later batch.

If D-11 = Alt-3 (skip):
- V1 ships as-is. Principle remains implicit. Future re-derivation
  cost accepted.

---

## §8 — Cross-references

- V1 architect doc: `ARCHITECTURE-CLEANUP-BATCH-19C.md`
- V0 architect doc (DISCARDED): `ARCHITECTURE-CLEANUP-BATCH-19C-DISCARDED.md`
- OT memory dump: `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked Memories.txt`
- V1 §D.2 (placement rule, current): lines 1180–1280 of V1 doc
- V1 §F D-4 (placement rule as architecture principle): lines 1541–1591 of V1 doc
- METHODOLOGY.md Part 1 "Tool Roles" (proposed home for principle): `supporting-docs/METHODOLOGY.md` Part 1
