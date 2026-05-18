# ARCHITECTURE — Batch 19b strategic principles (V2-architect synthesis)

**Author:** pack-architect (V2 synthesis — separate from the 19c-stream architect; no inheritance from any 19c V1 architect doc, principle-check, or V0-DISCARDED doc)
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `3d8cc8b`)
**Inputs read (this pass):**
- `maintenance-docs/v11-implementation/RESEARCH-BATCH-19B-STRATEGIC-RULES.md` (V1 researcher; treated as ONE input, not the baseline)
- 19b commit set: `667d2dd`, `ef9e5c7`, `a9b7c74`, `7e4fdcc`, `3558525`, `4760649`, `aaa61b3`, `efd9a32`, `30a1bc3`, `3d8cc8b`
- Archived 19b workflow artifacts (`ARCHITECTURE-CLEANUP-BATCH-19B-V2.md`, `PLAN-CLEANUP-BATCH-19B.md`, `PACK-REVIEW-CLEANUP-BATCH-19B-broad.md`)
- Pack-root operating docs at HEAD: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `PACK-CHAT.md`, `PACK-AGENTS.md`
- Tier-1.5 memory cache: `MEMORY.md` + sampled feedback files
- Project-side: `project-template/{CLAUDE,AGENTS,GEMINI}.md`, `project-template/docs/pack/PM-CHAT.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md` (relevant sections)
- OT counterparts (READ-ONLY): `/Users/david/Developer/OptiquityTrader/{CLAUDE,AGENTS,docs/pack/METHODOLOGY}.md`; `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked Memories.txt`
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §B (rewritten in `4760649`)

**Inputs deliberately NOT read (per prompt out-of-scope):**
- `ARCHITECTURE-CLEANUP-BATCH-19C.md` (V1 architect for the 19c-stream)
- `ARCHITECTURE-CLEANUP-BATCH-19C-DISCARDED.md` (V0)
- `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md` (V1 principle-check)

**Scope discipline.** This pass is research-grade synthesis only. NO design recommendations, NO fixes proposed, NO "we should change X" language. Identification, classification, hierarchy. The single exception is recording the explicit-vs-implicit flag and dominance map for each principle; those are descriptive, not prescriptive.

**Output contract.** §1 names the load-bearing principles. §2 reclassifies the V1 researcher's rules as corollaries (or names where one of the researcher's "rules" was already a corollary masquerading as a principle). §3 names principles the researcher missed. §4 re-judges the researcher's 10 conflicts independently. §5 maps dominance/constraint relationships. §6 surfaces framing divergence from the researcher's §A/§B/§C/§D structure.

---

## §1 — Load-bearing strategic principles (7 total)

Seven principles emerge as load-bearing across pack-side and project-side. The researcher's 26 rules decompose against these 7; many are corollaries (mapped in §2). The 7 are NOT split into pack-side/project-side sets because most of them govern BOTH surfaces — the split-by-surface frame is what produced the researcher's 26-rule wide net.

For each principle: name, statement, evidence (file paths + commit SHAs), explicit-or-implicit (independent judgment), and an enumeration of the corollaries it generates (further detail in §2).

### P1 — Authority by construction over discipline by convention

**Statement.** When the pack must guarantee an invariant, prefer mechanisms that make violation structurally impossible over rules that depend on actor discipline. When a pure-discipline rule is unavoidable, attach an automatic check that fails loudly at the point of drift. Discipline-only rules without a loud-failure check are an anti-pattern.

**Flag.** IMPLICIT — never named as a single principle in any source doc, but the dominant design driver in Batch 19b. The V1 researcher flagged this as A.4 ("Authority by construction over discipline by convention") with the correct evidence but treated it as one rule among 10 rather than as the design-level principle that organizes the others. This pass elevates it to P1 because the V2 architect's actual structural moves (collapsing Tier 2 to Tier 1.5 pointer-only; RC9 CI gate; PREFLIGHT line shape; per-entry tree as SSOT with regenerated mirrors) are all instances.

**Evidence.**

- V2 architect doc (`maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §A.1, §D.2): "A pointer-only Tier 1.5 file makes 'trinity and memory disagree' impossible by construction." The collapse from a 3-tier model (where Tier 2 would mirror trinity in tool-native memory caches) to a 2-tier model (trinity + pointer-only Tier 1.5) is justified explicitly as preferring construction-time impossibility over runtime discipline.
- RC9 manifest-regen rule (trinity `### Repo conventions`, e.g., `AGENTS.md:404-445`): the bullet IS a discipline rule ("regenerate the manifest on every v11-surface commit"), but the rule ends with "The manifest diff after rebuild is the canonical authority — the trigger globs are a screen for WHEN to run the rebuild" — i.e., the structural CI gate (`fixture manifest verify`, BD-115) is what actually enforces the invariant; the discipline rule is a hint about when to run the rebuild. The CI gate fails loudly when discipline lapses.
- PREFLIGHT line shape (trinity `### Agent invocation rules` AI7, `CLAUDE.md:236-275` and parallels): "Pack Chat treats this line as the trust signal that the report-write is starting from a complete-and-green state." The orchestrator does not have to trust the coder's self-narrative; the structural artifact (one-line text in a fixed format BEFORE the IMPL-REPORT write) IS the trust signal. Compare to a hypothetical "coder MUST verify everything before reporting" pure-discipline rule that would be unenforceable.
- Per-entry trees vs mirrors trinity bullet (`AGENTS.md:326-341`): "the per-entry tree IS source of truth"; "the monolithic `BACKLOG.md` ... are regenerated mirrors — read-stable but never source of truth." The structural choice (per-entry files written by humans; monolithic file regenerated by tooling) makes "monolithic-mirror-drifts-from-per-entry-source" impossible by construction — the mirror is overwritten on every regen.
- PM-only files list (`PACK-AGENTS.md:142-148`): the structural enforcement is the `commit-discipline` skill section 4, which makes the list a hard-stop for agents. The discipline rule (Pack Chat handles PM-only edits) becomes structurally enforced via agent-permission rejection.
- `feedback_pack_chat_does_no_fixes.md` (Tier-1.5 memory pointer): "NO threshold exception — there is no 'small enough to skip the coder' carve-out." The absence of a carve-out IS the structural mechanism — no rule says "Pack Chat may apply the fix if it's small"; the rule's shape forbids the discretionary judgment.

**Corollaries generated** (cross-reference §2 for the researcher-rule mapping):

- Trinity = SSOT (P3) is dependent on AbC: trinity wins because the rule's shape makes it impossible for anything else to be authoritative.
- Tier-1.5 pointer-only Claude memory (researcher's §A.1 evidence) is the structural enforcement of P3 on the Claude-cache surface.
- "Per-action approval extends to sub-agents" (researcher's A.6 evidence) — sub-agents inherit by construction (they cannot run state-changing git verbs; the agent permission profile is the structural mechanism).
- "Agents never commit" (trinity `### Workflow`) — structural, not discipline: agents are prohibited by their `commit-discipline` skill and by their agent-permission profile.
- RC9 manifest-regen pattern.
- PREFLIGHT line shape.

### P2 — Honest platform scoping (ship the strongest rule each platform actually supports)

**Statement.** When a CLI platform genuinely lacks a feature, the pack does NOT invent a non-canonical surface to fake parity. It documents the platform limit and ships the strongest rule each platform actually supports. Tool-equivalence (B.9 in researcher's catalog) is a corollary: "all 3 tools can execute any phase" only where the capability genuinely exists; the trinity rule's three permitted variant classes (UNIVERSAL / TOOL-SPECIFIC / TOOL-ONLY) are the structural expression of platform-honesty.

**Flag.** EXPLICIT — named in V2 architect doc §A.1 and §C.4. Also named in researcher's A.3, but the researcher treated it as ONE rule rather than the principle that DOMINATES the trinity rule (P3 = trinity-as-SSOT) and explains the three trinity variant classes.

**Evidence.**

- V2 architect doc (`maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §A.1): "Codex memories are (a) opt-in, (b) not available in EEA/UK/CH, (c) opaque generated state per official guidance ('don't rely on editing them by hand'), and (d) have no documented MEMORY.md-style index file. Gemini has no separate per-project memory cache at all. Designing a Tier 2 for those CLIs would require either (i) shipping a non-canonical convention that contradicts the upstream tool's docs, or (ii) treating 'trinity is the cache' as the Codex/Gemini story." The rejection of Tier 2 is on platform-honesty grounds.
- AI7 PREFLIGHT + STOP-MEANS-STOP trinity bullet (`CLAUDE.md:236-275` and parallels): PREFLIGHT half is "platform-neutral, REQUIRED for all CLIs"; STOP-MEANS-STOP CONTENT half is required for all CLIs; STOP-MEANS-STOP ENFORCEMENT is per-CLI conditional with explicit notes (Claude: SendMessage + SECURITY WARNING classifier; Codex: `/agent` slash command or natural language, reliability caveats per research §2.6; Gemini: natural language or `Ctrl+C`, reliability caveats per research §3.6). The same bullet body honestly documents each platform's actual enforcement capability.
- AGENTS.md `### Pack Chat scope` "What Pack Chat CAN edit directly" sub-list (`AGENTS.md:288-293`): "Per V2 §D, Codex has no pack-shipped per-project memory cache (Codex memories are opt-in + regionally restricted + opaque generated state per official guidance; the pack does NOT ship a Codex memory file). Pack rules reach Codex via this `AGENTS.md` trinity surface only — there is no Codex-side memory-file edit surface analogous to the Claude memory cache." GEMINI.md carries the parallel Gemini-side text.
- Sub-agent behavior (Claude-only) sub-section (CLAUDE.md only, with Trinity exemption note `CLAUDE.md:310-314`): "this sub-section concerns Claude Code's Agent tool, `run_in_background` parameter, and Agent Teams / SendMessage features — none of which have equivalents in Codex CLI or Gemini CLI per research §2.5 / §2.7 / §3.5 / §3.7." Whole sub-section is omitted from AGENTS.md and GEMINI.md by structural choice — there is no rule to mirror because the underlying capability does not exist.
- Project-side parallel: `project-template/CLAUDE.md:37-41` "Capability policy" and `project-template/CLAUDE.md:372-373` Phase routing intro: "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase. The defaults below identify the better system for each phase." Tool-equivalence as default; per-task overrides admitted.
- Trinity rule itself (`CLAUDE.md:80-86` and parallels): "These three files must express the same project rules. The only exception is a change that is provably tool-specific." The "provably tool-specific" qualifier IS P2: the exception is admissible only when grounded in genuine platform-capability difference.

**Corollaries generated.**

- Trinity rule's three variant classes (UNIVERSAL / TOOL-SPECIFIC / TOOL-ONLY) — see V2 §3 and the PACK-REVIEW-broad §3 trinity-parity audit table.
- "Claude-Code-only" sub-section markers throughout trinity (Sub-agent behavior, the memory-cache pointer in the W5 trailer, the per-CLI sub-bullets in AI7).
- Tool-equivalence policy (B.9 in researcher's catalog) — defaults can be overridden when task characteristics favor a different tool.
- Trinity-rule-exception HTML comment convention (`project-template/GEMINI.md:400-404`) — the marker is the structural record of an honestly-justified divergence.

### P3 — Single source of truth with regenerable mirrors

**Statement.** Every pack rule lives in exactly one authoritative location. Mirror surfaces (Tier-1.5 cache, monolithic `BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md`, STATUS.md, prose summaries in operating docs) are derivable from the source and lose on disagreement BY CONSTRUCTION (per P1) — not by manual reconciliation. SSOT applies to rules (trinity), methodology (METHODOLOGY.md), and entry content (per-entry tree in flat-file mode; tracker in tracker mode). The SSOT surface varies by domain; the principle is uniform.

**Flag.** EXPLICIT — named in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:211` ("**Single source of truth** for content / rules / config — Trinity files; HELP-FRAGMENT pack-root vs project-template; spec sections vs implementation comments"); named in `supporting-docs/METHODOLOGY.md:11-17` for METHODOLOGY itself; named in trinity `### Repo conventions` "Per-entry trees vs mirrors — mode-dependent source of truth" bullet.

**Evidence.**

- Pack-side rules: trinity `## Pack memory` is SSOT; memory pointer files carry verbatim footer "If this pointer disagrees with trinity, TRINITY WINS" (`feedback_pack_chat_does_no_fixes.md:19-20`); Tier-1.5 cache MEMORY.md leads with "Trinity is the single source of truth; this file is a Claude-Code convenience cache."
- Project methodology: METHODOLOGY.md (`supporting-docs/METHODOLOGY.md:11-17`): "One copy of this file lives at `supporting-docs/METHODOLOGY.md` in the AI Agent Config Pack ... Do not modify the pack's copy for project-specific needs — edit the project root copy instead." OT preserves the install pattern (`/Users/david/Developer/OptiquityTrader/docs/pack/METHODOLOGY.md` byte-identical-front-matter).
- Entry content: trinity `### Repo conventions` "Per-entry trees vs mirrors" bullet (`AGENTS.md:326-341`). Flat-file mode: per-entry tree IS SSOT, monolithic mirror regenerated. Tracker mode: tracker (GH Issues) IS SSOT, both per-entry tree AND monolithic mirror regenerated. Convenience views (STATUS.md) carry "never source of truth" disclaimer; if they drift, the SSOT wins.
- Agent operating rules: B.14 (researcher's catalog) = "Agent file is authoritative; PM-CHAT.md per-profile guidance is the PM-chat-facing mirror." `project-template/docs/pack/PM-CHAT.md:266-278`: "The agent file is authoritative; this section is the PM-chat-facing reinforcement. When constructing a prompt, your job is to align with what the agent's file already says, not to restate or override it." Same structure as the trinity-vs-memory-pointer SSOT pattern, applied to agent-rules.
- Empirical confirmation: PACK-REVIEW-broad §1 verdict line — "trinity parity is honored under §3 per-CLI variant semantics" — and §3 table — UNIVERSAL bullets match byte-identical; TOOL-SPECIFIC bullets express the same substantive rule with per-CLI machinery. The substantive-rule preservation IS the SSOT-with-regenerable-mirror pattern at work for trinity.

**Corollaries generated.**

- Trinity-first cross-CLI parity (A.2/B.3 in researcher's catalog) — the trinity is the SSOT-for-rules surface; parity is the consequence.
- METHODOLOGY-as-SSOT (B.1).
- Per-entry trees vs mirrors (mode-dependent SSOT).
- Agent file = authoritative (B.14).
- Document hygiene rules (B.6) — ARCHITECTURE / IMPLEMENTATION-PLAN as SSOT for design / plan; CHANGELOG append-only; agents-must-not-modify-without-instruction.
- PACK-FEEDBACK as PM-chat-owned SSOT (B.12).
- "BACKLOG.md has no Resolved section" (`AGENTS.md:342-344`) — entries resolve in place because the per-entry file IS the source; moving to a separate section would create a second authoritative location.

### P4 — Actor-and-gate orchestration (every rule names WHO does the work and WHO approves)

**Statement.** Pack rules name the actor performing each action (Pack Chat, fix-coder, pack-architect, pack-planner, pack-coder, pack-reviewer, pack-docs-researcher, the user) AND the gate-point where work passes from one actor to the next. A rule about WHAT to do is incomplete without a rule about WHO does it and WHO approves it. The set of project-side mirrors (PM chat / coder / reviewer / architect / planner / tester / docs-researcher / auditor / grpc-schema / repo-ops) follows the same pattern. Orchestration is the load-bearing layer that makes "review/fix cycle," "triage discussion," "commit approval," and "pipeline" semantically distinct things — without explicit actor-and-gate, each becomes a debatable judgment call.

**Flag.** EXPLICIT — named in trinity `### Pack Chat scope` sub-section (created in `667d2dd`) which is ENTIRELY rules about WHO does work, not WHAT work. Named in V2 architect doc §A.6 ("rules about WHO does work, not WHAT work"). Named in EXECUTION-PLAN §B (rewritten in `4760649`) which made WHO-performs-each-step the dominant structure. Researcher's A.5 saw the principle but didn't surface how foundational it is (most of the researcher's other "rules" are corollaries of P4 + P3 + P1).

**Evidence.**

- Trinity `### Pack Chat scope` sub-section (created in `667d2dd`, lines `AGENTS.md:267-322` and parallels): three rules, all WHO-rules.
  - PCS1 "Pack Chat does NO fixes" — actor sequence (spawn pack-reviewer → read report → triage findings → present triage to user → spawn fix-coder → read IMPL-REPORT → stage + commit with user approval); no threshold exception.
  - PCS2 "Commit-approval requests include next-steps plan" — actor (Pack Chat) AND gate (the approval message MUST surface the planned next steps so the user can redirect BEFORE work happens).
  - PCS3 "Pack-architect spawn protocol" — actor and gate (pack-architect spawn requires explicit user approval; pack-planner / pack-coder / pack-reviewer / pack-docs-researcher follow standard Pack Chat triage).
- EXECUTION-PLAN §B (`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:331-381`, rewritten in `4760649`): every step names the actor.
  - Step 1: "Pack Chat does not propose deferral"
  - Step 2: "Pack Chat reports findings to the user ... presents a fix-vs-skip triage per finding ... waits for triage approval"
  - Step 2 (cont.): "Pack Chat does NOT apply the fixes itself — a fix-coder agent does"
  - Step 5: "Pack Chat surfaces the finding AND its candidacy for a new BD to the user — but does NOT open the BD"
  - Step 5 (cont.): "Pack Chat must not pre-frame 'should we open a BD?' as a default choice"
- Trinity `### Workflow` "Agents never commit" (`AGENTS.md:112-117`): "No agent — including `pack-coder` — may run `git add`, `git commit`, `git push`, `git tag`, or any state-changing git verb ... Only Pack Chat may stage and commit, and only with explicit user approval."
- Trinity `### Workflow` "Pack Chat does not architect" (`AGENTS.md:118-121`): "Architecture, planning, implementation, and review work goes to `pack-architect` / `pack-planner` / `pack-coder` / `pack-reviewer` directly."
- Trinity `### Agent invocation rules` "Researcher-first pipeline" (`AGENTS.md:215-222`): explicit actor pipeline `pack-docs-researcher` → `pack-architect` → `pack-planner` → `pack-coder`; "Architect runs AFTER researcher, not before, not skipped."
- Trinity `### Agent invocation rules` "Planner output → user review → coder spawn" (`AGENTS.md:223-229`): "Pack-planner output is NEVER auto-approved into a pack-coder spawn. Pack Chat surfaces the plan to the user for thorough review ... and waits for explicit approval before spawning pack-coder."
- PACK-CHAT.md "Stop after every reviewer pass for triage discussion" (`PACK-CHAT.md:63-71`): "After every pack-reviewer run, Pack Chat STOPS, surfaces the findings (severity-grouped) to the user, and waits for triage approval — even if the reviewer verdict is fully clean."
- Project-side parallels: METHODOLOGY.md Part 1 (Tool Roles), Part 9 (Document Authoring Rules table — Coder / Reviewer / PM chat columns), Part 7 "Agent BACKLOG write permissions" table. Every project-side principle from B.4 / B.6 / B.12 / B.13 / B.14 has the WHO-and-gate structure.
- METHODOLOGY.md `### Document hygiene rules (inviolable)` rule 5 (`supporting-docs/METHODOLOGY.md:128-134`): "Agents must not modify `ARCHITECTURE.md` or `IMPLEMENTATION-PLAN.md` unless explicitly instructed in the prompt. `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, and all other root `.md` files are exclusively the PM chat's responsibility." Actor-explicit document hygiene.

**Corollaries generated.**

- "Plan before executing" (B.4) — the gate before any execution.
- "PM/Pack chat does not architect" (cross-side, C.10) — actor boundary.
- "Pack Chat does no fixes" (researcher's A.5 evidence) — actor boundary.
- "Agents never commit" — actor boundary at the commit gate.
- "User retains hard-stop authority" (A.6 / C.6) — gate-level user-veto across all planned actions.
- "Per-BD review/fix runs INLINE" (W12 trinity bullet) — actor sequence within a multi-BD batch.
- "Triage all reviewer findings; default fix-all" (W11 trinity) — gate between reviewer and fix-coder.
- "No solutions in agent prompts" (researcher's B.5) — prompt-content constraint that protects the actor-boundary (agent decides the solution; PM chat decides the problem).
- "Agent prompt requirements" / "REPORT FILE" (B.13) — prompt-shape contract that names the deliverable handoff.
- "Stop after every reviewer pass for triage discussion" — explicit gate before triage.

### P5 — Empirical anchoring (every rule cites its incident; no rules from first-principles reasoning)

**Statement.** Rules are codified only when grounded in observable evidence: a prior incident, a `file:line` defect, a CI run, a BACKLOG entry, a test failure, or a commit SHA. Reasoning-from-first-principles rules without evidence are not surfaced. The codified rule preserves the empirical anchor in its body so future readers can recognize drift and so a future reviewer can verify the rule's necessity. This is a meta-principle about how rules are MADE, not what the rules say.

**Flag.** EXPLICIT — named as rule 5 of `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:133` "Rat-hole limits": "**Empirical anchoring required.** Every finding cites observable evidence (`file:line`, test failure, CI run, BACKLOG entry, prior commit). Reasoning-from-first-principles findings without evidence are not surfaced." This is reviewer-specific in the source, but Batch 19b extends the discipline to RULES — the new trinity bullets carry incident citations in their bodies.

**Evidence.**

- RC9 manifest-regen bullet (trinity `### Repo conventions`, `AGENTS.md:404-445`): the bullet body names the 2026-05-17 incident, the recovery commit (`ef9e5c7`), the cumulative drift sources (3 commit SHAs: `cf67a96`, `62f9eec`, `479fef5`), the last-clean baseline (`a57dd04`), the failure mode (CI `fixture manifest verify` step failed alone while all 40+ functional steps passed), and the canonical fix command. The bullet is ~40 lines because the empirical anchor IS half the rule body.
- AI7 PREFLIGHT + STOP-MEANS-STOP bullet (`CLAUDE.md:236-275`): "Worked-example anchor: `feedback-pack-coder-preflight-pattern` memory pointer; original incident BD-169 19g-pack, 2026-05-16." The incident anchor is named-by-doc.
- Trinity `### Repo conventions` "Architect-doc-vs-reality reconciliation" (`AGENTS.md:393-403`): "Worked example: BD-119 §9.2 addendum in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` names BD-160 as the first realized consumer; the consumer carries the matching docstring; the BD-160 IMPL-REPORT links both."
- Trinity `### Repo conventions` "Filename uniqueness heuristic" (`AGENTS.md:382-392`): "Worked example: BD-135 renamed the colliding `tracker.toml.example` pair."
- PACK-CHAT.md "Direct opinion, not validation" (`PACK-CHAT.md:93-104`): cites the user's verbatim 2026-05-16 directive ("Don't just be complementary. Base your analysis on evidence and logic. Tell me what you think.") as the incident anchor.
- PACK-CHAT.md "Real fixes only — no green-the-test band-aids" (`PACK-CHAT.md:81-92`): names six concrete forbidden patterns (assertion deletion, commenting out a failing test, catching-and-ignoring exceptions, changing test expectations to match buggy output, adding a sleep to mask a race condition, etc.) — each is itself an empirical category derived from observed cases.
- CONCEPTUAL-REVIEW-METHODOLOGY.md throughout — §"CI-step interrogation heuristic" (Batch 21c, 2026-05-15 BD-118 incident); §"Convention/naming docs review checklist" (BD-122 retro); §"Empirical validation requirement" (Batch 21c per-BD-AND-per-batch validation across 13 BDs); §"File/Symbol scope from authoritative sources" (BD-112 retro). The methodology doc itself is exclusively empirically anchored.

**Corollaries generated.**

- "Rules without incident anchors are not codified" — meta-rule (this is P5 in its dual form).
- Worked-example anchor convention in trinity bullets.
- "Reservation lists are NOT authoritative" (PC-9 trinity strengthening, `AGENTS.md:69-72`) — drift caught empirically (Pack Chat assigning BD numbers from outdated reservations); the rule strengthens the existing BD-numbering rule by codifying the empirical lesson.
- "Defending deferral rigorously requires (a) SIZE, (b) BLOCKED, or (c) LOGICAL FIT" (W8 trinity bullet) — each criterion is empirically derived from observed bad deferrals.

### P6 — Fix-now-default with structural friction against deferral

**Statement.** The default for any surfaced finding (review, audit, in-flight discovery, user observation) is FIX-IN-THE-CURRENT-SESSION. Deferral is admissible only when rigorously justified (size / blocked / logical fit) AND surfaced to the user for explicit discussion-and-approval. Deferral is not a neutral scheduling decision — it is tech debt and scope creep. Defaults invert when the cost of carrying a deferral exceeds the cost of fixing now. Sub-rules layer structural friction at multiple gates (triage default = FIX; NITs that defer become tracked tech debt; new-BD-opens require user approval; "defer to v11.1+" is forbidden by default during v11.0 development). The principle's load-bearing form is the INVERSION of the default: fix-now is the rule, defer is the exception.

**Flag.** EXPLICIT — named in trinity `### Workflow` "Deferral IS scope creep" bullet (`AGENTS.md:158-170`); named in EXECUTION-PLAN §B (rewritten in `4760649`) which made "FIX-NOW by default" the explicit step 1 of the audit / review-fix protocol; named in trinity `### Workflow` "No deferral to v11.1+ without explicit user direction" (`AGENTS.md:147-157`); named in trinity `### Workflow` "Triage all reviewer findings; default fix-all" (`AGENTS.md:187-195`).

**Evidence.**

- Trinity `### Workflow` "Deferral IS scope creep" (`AGENTS.md:158-170`): "Deferring unblocked work to a later BD or batch is tech debt and scope creep. Punted items lose context, multiply, require archaeology in future sessions. Defending deferral rigorously requires (a) SIZE ... (b) BLOCKED ... (c) LOGICAL FIT. ... Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open additionally requires user-discussion-and-approval."
- EXECUTION-PLAN §B step 1 (`EXECUTION-PLAN-V11.0.md:333-335`): "Every audit/review pass that produces findings is FIX-NOW by default in the current session. Pack Chat does not propose deferral."
- Trinity `### Workflow` "No deferral to v11.1+ without explicit user direction" (`AGENTS.md:147-157`): "Pack Chat must NEVER propose 'defer to v11.1' as a default option in user-facing framings. Architect / reviewer / coder defer-recommendations are SCOPING signals ... not AUTHORITY signals — re-scope to land in v11.0 and surface the blast-radius to the user."
- Trinity `### Workflow` "Triage all reviewer findings; default fix-all" (`AGENTS.md:187-195`): "The default for all severities is FIX. NITs that are deferred (with user-discussion-and-approval per OQ-1 EXECUTION-PLAN §B) become tracked tech debt — never 'noted in the report and dropped.'"
- Trinity `### Workflow` "Deferred work needs a tracked anchor" (`AGENTS.md:139-146`): the corollary that even authorized deferrals must land on a live forward-pointing surface; "Archived reports are NOT acceptable anchors."
- PACK-CHAT.md "Scope-extension test for in-flight work" (`PACK-CHAT.md:122-132`): symmetric-pair / same-feature-surface items extend the current BD via SendMessage rather than opening a new BD. This is fix-now-by-default applied to the SCOPE-extension case.

**Corollaries generated.**

- "No deferral to v11.1+" (V11-4 / researcher A.9 evidence).
- "Triage default fix-all" (W11 / researcher A.9 evidence).
- "Deferred work needs a tracked anchor" (W6 / researcher's PC-8).
- "Scope-extension test" (PACK-CHAT.md / researcher V11-7).
- "No new BDs without user-discussion-and-approval" (EXECUTION-PLAN §B step 5).
- "Reviewer findings → fix-coder, never 'noted and dropped'" — direct corollary of fix-now default applied at the triage gate.

### P7 — Boundary separation by structural firewall

**Statement.** Boundaries between conceptually distinct surfaces are enforced structurally (different directories, different filename prefixes, different markers, different lifecycle gates) — not stylistically by convention alone. The pack uses at least seven structural firewalls: (a) pack ops files vs pack product files (different directory trees); (b) `x-` prefix vs pack-roster files (different filename namespace within shared directories); (c) per-entry tree vs monolithic mirror (different file shapes within the same domain); (d) PM-only files vs agent-editable files (different agent-permission profiles); (e) maintenance-docs/ workflow artifacts vs maintenance-docs/archive/v<N>/ (different directories with sweep-at-version-ship); (f) CONDITIONAL markers and BEGIN/END project-owned markers within shared files (different in-file regions with migration-classifier preservation); (g) trinity ops files at pack root vs `project-template/` trinity (different repo-side scope despite identical filenames). Each firewall is enforceable by scripts, CI, or agent-permission profiles — not just by reader discipline.

**Flag.** EXPLICIT (multiple instances) — pack ops vs pack product is named in trinity `### Repo conventions` `AGENTS.md:345-348` and PACK-CHAT.md `PACK-CHAT.md:137-144`; `x-` prefix convention in `supporting-docs/INSTALL-PROCEDURES.md:29-80`; PM-only files in `PACK-AGENTS.md:142-148`; per-entry tree vs mirror in trinity `### Repo conventions` `AGENTS.md:326-341`. The underlying PRINCIPLE (structural firewall as the design choice for any boundary) is IMPLICIT — derivable from the consistent application across all seven instances but not named as a single principle anywhere read.

**Evidence.**

- Pack ops vs pack product (`AGENTS.md:345-348`): "Pack ops files (CLAUDE.md, AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.) are NEVER mixed into pack product files (`project-template/`, `supporting-docs/`). Same applies in reverse." Same rule in PACK-CHAT.md `PACK-CHAT.md:137-144`. Same rule operationalized in RC9: v11-surface = `project-template/` or `scripts/`; pack ops at pack root and `maintenance-docs/` are NOT v11-surface and trigger no manifest regen. The CI gate enforces the boundary.
- `x-` prefix as project-supplied marker (`supporting-docs/INSTALL-PROCEDURES.md:29-80`): "Pack-controlled deletions skip `x-*`. Pack-controlled overwrites skip `x-*`. Pack-roster filenames never start with `x-`." Three structural guarantees, each enforced by pack scripts (`init-project.sh`, the active migrator, `add-capability.sh`).
- PM-only files list (`PACK-AGENTS.md:142-148`): structural enforcement via `commit-discipline` skill section 4. Agents that get a prompt without explicit caller-scoping of a PM-only file return a POQ instead of editing — the structural mechanism is the agent's permission profile + skill check, not actor discipline.
- Per-entry tree vs mirror (`AGENTS.md:326-341`): the structural boundary is the file-shape itself. Per-entry files are written by humans (Pack Chat / PM Chat); monolithic mirrors are produced by regenerators. Mode-dependent SSOT: flat-file mode = per-entry tree; tracker mode = tracker; convenience views always carry "never source of truth" disclaimer.
- Workflow artifacts vs archive (`AGENTS.md:353-370`): pattern enumeration (`ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`, `PACK-REVIEW-*.md`, `AUDIT-*.md`, `RESEARCH-*.md`, `*-DISCOVERY.md`, `CLEANUP-INPUTS-*.md`, and the retro-suffix variants) — exempted from "no new top-level doc" structural signal DURING active development; SWEEP to `maintenance-docs/archive/vN/` at version ship as the final pre-tag step (Pattern B). The lifecycle gate is the structural firewall.
- CONDITIONAL markers + BEGIN/END project-owned markers (`project-template/CLAUDE.md:55-95` and `:421-426`; `project-template/docs/pack/PM-CHAT.md:763-786`): in-file region markers. The init script and migrator preserve project-owned regions across version bumps; CONDITIONAL sections are removed for non-applicable project shapes. OT carries the realized markers (`/Users/david/Developer/OptiquityTrader/CLAUDE.md:45` carries a v9.3 → v10 "renamed-from" comment). Researcher's B.16 saw this as "Conditional pack files removed/preserved per project shape (implicit)" — this pass elevates it to one instance of P7.
- Trinity files at pack-root vs project-template (researcher's C.8 evidence): "This rule also applies to the pack-repo copies of these three files" (`CLAUDE.md:84-86`). Same filenames, different scope. Structural disambiguation is the path: pack-root `CLAUDE.md` is pack-ops; `project-template/CLAUDE.md` is pack-product.
- Filename uniqueness heuristic (trinity `### Repo conventions`, `AGENTS.md:382-392`): for ambiguous filename collisions in prose references, the rule says prefer unique names; structurally-required collisions (trinity files, per-skill `SKILL.md`, byte-identical mirrors per CI Check 24, ecosystem-fixed names) are exempt and require disambiguating prose context. This is the FALLBACK rule for the boundary cases where the structural firewall is unavoidable.

**Corollaries generated.**

- "Pack-ops vs pack-product separation" (A.10 in researcher's catalog).
- "x- prefix as structural firewall" (B.10 / C.9).
- "PM-only files off-limits to agents" (B.6 enforcement, agent permission rules).
- "Per-entry trees vs mirrors" (trinity Repo conventions).
- "BACKLOG.md has no Resolved section" — derivative of per-entry SSOT (no separate authoritative section needed).
- "Pack-roster vs custom `x-*`" guarantees in INSTALL-PROCEDURES.md.
- Workflow-artifact archive sweep at version ship (Pattern B).
- CONDITIONAL marker and project-owned region preservation across migrations (researcher's B.16, here re-classified as a P7 instance, not a standalone principle).
- "PACK-FEEDBACK.md is PM-chat-only; agents never write" (B.12).
- "STATUS.md never source of truth" disclaimer convention.

---

## §2 — Researcher's rules reclassified as corollaries

The V1 researcher's 10 pack-side rules (§A) + 16 project-side rules (§B) = 26 rules. This pass reclassifies most as corollaries of the 7 principles in §1. Two of the researcher's "rules" are reclassified differently (one is correct-as-named-but-not-a-principle; one is the meta-principle that the researcher missed by treating it as a peer).

For each researcher rule: name → dominant principle(s) → rationale → independent explicit/implicit flag.

### Pack-side (§A in researcher)

| Researcher rule | Dominant principle(s) | Rationale | Researcher flag | My flag |
|---|---|---|---|---|
| A.1 — Single source of truth per rule | P3 (with P1 as the structural mechanism) | The "single source of truth" rule is named explicitly in CONCEPTUAL-REVIEW-METHODOLOGY §211 and is the canonical statement of P3 applied to pack rules. The researcher correctly named it but treated it as one rule of 10; here it is the load-bearing principle (P3) with the trinity surface as one of its instances. | EXPLICIT | EXPLICIT |
| A.2 — Trinity-first cross-CLI parity | P3 (SSOT) + P2 (platform-honesty) | Trinity-as-SSOT is P3. The three permitted variant classes (UNIVERSAL / TOOL-SPECIFIC / TOOL-ONLY) are P2 in action. Researcher conflated them into one rule; this pass separates the SSOT design choice (P3) from the platform-honesty constraint (P2) that limits how parity is enforced. | EXPLICIT | EXPLICIT (corollary of P3 + P2) |
| A.3 — Cross-CLI scope honesty | P2 directly | This IS P2 in its named form. Researcher had it right; this pass elevates it to a load-bearing principle rather than a peer rule. | EXPLICIT | EXPLICIT (P2 itself) |
| A.4 — Authority by construction over discipline by convention | P1 directly | This IS P1 in its named form. Researcher had it right; this pass elevates it to THE load-bearing principle (P1) — it is the design-level move that organizes the other principles' enforcement mechanisms. | IMPLICIT | EXPLICIT-in-effect (the V2 architect doc names it at §A.1, §D.2 as the rationale for collapsing Tier 2 to Tier 1.5 pointer-only). Treat as EXPLICIT going forward; researcher's IMPLICIT flag is too weak. |
| A.5 — Roles as orchestration boundaries | P4 directly | This IS P4 in its named form. Researcher had it right; this pass elevates it to a load-bearing principle. | EXPLICIT | EXPLICIT (P4 itself) |
| A.6 — User retains hard-stop authority | P4 (the user is one of the orchestration actors with veto authority) | The "user can stop or redirect any planned action" rule is a P4 corollary that names the user as an actor with hard-stop authority at every gate. The PCS2 "Commit-approval requests include next-steps plan" rule makes the gate visible. | EXPLICIT | EXPLICIT (corollary of P4) |
| A.7 — Empirical anchoring | P5 directly | This IS P5 in its named form. Researcher had it right (citing CONCEPTUAL-REVIEW-METHODOLOGY rule 5); this pass elevates it to a meta-principle about how rules are made. | EXPLICIT | EXPLICIT (P5 itself) |
| A.8 — Mechanical-vs-structural change taxonomy | P4 (orchestration gate) + P5 (empirical anchoring of structural change) | The mechanical / structural taxonomy is a P4 gate: structural change triggers a multi-stage pipeline (architect → planner → coder → reviewer); mechanical change goes straight to coder. Cross-references P5 in that the structural-vs-mechanical decision is itself empirically anchored to file-count + scope-line thresholds in the maintainability architect doc. | EXPLICIT | EXPLICIT (corollary of P4) |
| A.9 — "Deferral is scope creep" inverts the default | P6 directly | This IS P6 in its named form. Researcher had it right; this pass elevates it to a load-bearing principle (P6) — fix-now default + structural friction against deferral. | EXPLICIT | EXPLICIT (P6 itself) |
| A.10 — Pack ops / pack product separation | P7 (structural firewall) | One instance of P7 — pack ops vs pack product is the most-cited firewall, but it's one of seven. Researcher treated it as a peer rule. | EXPLICIT | EXPLICIT (corollary of P7) |

### Project-side (§B in researcher)

| Researcher rule | Dominant principle(s) | Rationale | Researcher flag | My flag |
|---|---|---|---|---|
| B.1 — METHODOLOGY.md is the single source of truth | P3 (SSOT applied to project methodology) | METHODOLOGY.md-as-SSOT is one domain-instance of P3, parallel to trinity-as-SSOT for pack rules. The install-time copy pattern (pack → project) is the regenerable mirror. | EXPLICIT | EXPLICIT (corollary of P3) |
| B.2 — Project trinity carries universal collaboration rules; agent definitions carry agent-scope rules | P3 (SSOT — agent file is authoritative) + P4 (actor-and-gate boundaries) | This is two principles fused. (a) Agent file = authoritative is P3 applied to per-agent operating rules. (b) Project trinity carries universal collaboration rules — the universal layer — is P4 made explicit at the project level. | EXPLICIT | EXPLICIT (corollary of P3 + P4) |
| B.3 — Trinity-first cross-CLI parity (project-side) | P3 + P2 | Parallel to researcher's A.2 with the project-template trinity as the surface. Same dual relationship: trinity = SSOT (P3); variant classes admitted only where genuinely tool-specific (P2). | EXPLICIT | EXPLICIT (corollary of P3 + P2) |
| B.4 — Plan-then-execute, never execute-then-plan | P4 (orchestration gate before any execution) | The plan-then-execute rule IS the gate-point at the beginning of any work; it's the universal P4 corollary applied at the highest level. | EXPLICIT | EXPLICIT (corollary of P4) |
| B.5 — No-solutions-in-prompts | P4 (actor-boundary: agent decides solution, PM chat decides problem) | The "no solutions" rule protects the actor boundary in the prompt-content layer. It is the negative form of the triad principle (Problem / Goal / Success criteria) that defines the prompt-construction contract. Combined, P4-prompt-form = triad-IS-the-contract + no-solutions = enforce-the-actor-boundary. | EXPLICIT | EXPLICIT (corollary of P4) |
| B.6 — Document hygiene as inviolable rules | P3 (SSOT) + P4 (actor-scope: agents must not modify ARCHITECTURE.md, etc.) | Document hygiene is P3 applied to per-doc SSOT (ARCHITECTURE.md, IMPLEMENTATION-PLAN.md as SSOT for design / plan; CHANGELOG append-only as a non-rewriting SSOT) + P4 applied at the actor-and-gate layer (agents must not modify; PM chat is exclusively responsible). | EXPLICIT | EXPLICIT (corollary of P3 + P4) |
| B.7 — Typed deferral comments and the TD-TBD sentinel | P5 (empirical: typed format is anchored to forbidden plain-English patterns) + P1 (TD-TBD is a structural sentinel — a real TD number in committed code is a defect by structural definition) | The TD-TBD sentinel is P1: the rule makes "real TD number in committed code without PM-chat processing" structurally impossible to ship — the sentinel pattern is detected, the typed comment format prevents the contributor from inventing a plausible-looking unprocessed comment. The plain-English prohibition is P5 — empirical drift caught and forbidden. | EXPLICIT | EXPLICIT (corollary of P1 + P5) |
| B.8 — Reviewer must be source-truth-independent of prior reviewer reports | P4 (actor-boundary: reviewer is independent) | Reviewer-independence-from-prior-reviews is a P4 corollary protecting the bias surface. The reviewer's actor scope is to find new findings independent of prior framings; reading prior reviews collapses the independence. | EXPLICIT | EXPLICIT (corollary of P4) |
| B.9 — Tool-equivalence as design intent | P2 (platform-honesty) | "All three tools can execute any phase" is the positive statement that complements P2's negative ("don't fake parity where the platform doesn't support it"). The defaults are quality-optimization choices, not capability claims; overrides are admitted per task. | EXPLICIT | EXPLICIT (corollary of P2) |
| B.10 — `x-` prefix as structural firewall | P7 directly | This is one of the SEVEN named instances of P7 (structural firewall). Researcher treated it as a peer rule; this pass classes it as a P7 corollary. | EXPLICIT | EXPLICIT (corollary of P7) |
| B.11 — Detection-scan-at-every-startup-and-phase-gate | P4 (gate-point) + P7 (firewall enforcement at scan time) | The detection scan is P4 (gate before every prompt or commit) operationalizing P7 (the `x-` firewall must be checked at every gate so improperly-added files don't get into pack-controlled directories under pack-roster filenames). | EXPLICIT | EXPLICIT (corollary of P4 + P7) |
| B.12 — Pack feedback loop | P4 (actor-boundary: PM chat owns observation; agents never write feedback) + P3 (PACK-FEEDBACK.md is SSOT for upstream feedback) + observation/recording separation (this is a related principle the researcher missed — see §3) | The PM chat's observation role + workflow-boundary delivery cadence + "record observations, not solutions" is a P4 corollary + a missing principle (P-missed-1 in §3: observation/recording separation from solution/decision). | EXPLICIT | EXPLICIT (corollary of P3 + P4 + P-missed-1 from §3) |
| B.13 — File-based reporting | P4 (gate-point: every prompt's deliverable is the report file) | "Every prompt names a REPORT FILE" is a P4 enforcement at the prompt-shape level. The artifact at the path is the handoff; inline replies are not the deliverable. The two sub-cases (agent produces report; PM-chat self-prompt edits target file) preserve the structural contract under both report-vs-target-edit shapes. | EXPLICIT | EXPLICIT (corollary of P4) |
| B.14 — Agent-file-is-authoritative; PM-CHAT.md is PM-chat-facing mirror | P3 (SSOT applied to agent-operating-rules) | Agent file = authoritative is one domain-instance of P3, parallel to trinity-as-SSOT for pack-rules and METHODOLOGY-as-SSOT for project-methodology. PM-CHAT.md mirror = regenerable view that loses on disagreement. | EXPLICIT | EXPLICIT (corollary of P3) |
| B.15 — RAG manifest hygiene: orphans are not benign | P3 (manifest = SSOT; index is mirror) + P1 (orphans auto-deleted = structural enforcement, not "remember to clean") | The RAG manifest is the SSOT (P3); the local-rag index is the mirror. Orphans (in index but not in manifest) are auto-deleted on every `/pm-startup`, not flagged for manual cleanup — P1 in action. "Worse than no RAG at all" because the failure mode is invisible: this is the meta-rationale for P1 in this domain. | EXPLICIT | EXPLICIT (corollary of P3 + P1) |
| B.16 — Conditional pack files removed/preserved per project shape | P7 (in-file region firewall via CONDITIONAL + BEGIN/END project-owned markers) | The researcher flagged this as IMPLICIT-because-no-single-principle-named. This pass reclassifies it as one of the seven P7 firewall instances (in-file region markers preserved across version bumps; init/migration normalize). The principle (P7) IS named once the structural-firewall pattern is recognized as the common form across the seven instances. | IMPLICIT | EXPLICIT in the source as a convention; IMPLICIT as the underlying principle (the convention is instance of P7). Net: corollary of P7. |

### Summary of reclassification

- **Researcher's A.1, A.5, A.7, A.9** correspond directly to the principles named here (P3 / P4 / P5 / P6). Naming is consistent; this pass treats them as load-bearing principles rather than peers in a flat list.
- **Researcher's A.3, A.4** correspond directly to P2 and P1 — researcher had the principle named correctly but treated as one rule of 10 rather than as design-level.
- **Researcher's A.10, B.10, B.16** are three of the seven P7 firewall instances. Treating them as separate rules in a flat list obscures the underlying pattern.
- **Researcher's B.1, B.6 (partial), B.14, B.15** are P3 domain-instances (METHODOLOGY-SSOT, document-hygiene-SSOT, agent-file-authoritative, RAG-manifest-SSOT).
- **Researcher's B.2, B.4, B.5, B.6 (partial), B.8, B.11, B.12, B.13** are P4 corollaries at various levels (universal-collaboration-rule layer, plan-then-execute gate, prompt-content rules, document-hygiene actor scope, reviewer-independence, scan gate, feedback ownership, report-file deliverable).
- **Researcher's A.2, A.6, A.8, B.3, B.7, B.9, B.16** are corollaries of P1+P2+P3+P4 in various combinations (and one of P7 in the B.16 case).

The 26 → 7 reduction is approximate-3.7× compression. The corollary expansion preserves the researcher's evidence (each researcher rule's evidence rolls up under the dominant principle) but removes the artificial pack-side / project-side split and the inflation that treated principle-and-corollary as peers.

### Where the reclassification is contested

Two researcher rules need care:

- **A.4 (Authority by construction).** Researcher flagged IMPLICIT. The V2 architect doc names it explicitly at §A.1 + §D.2 as the rationale for the Tier 2 → Tier 1.5 collapse. This pass reclassifies as EXPLICIT-in-V2-architect-doc + IMPLICIT-in-trinity-and-operating-docs. The principle is named in design rationale but not surfaced as a single load-bearing rule in the trinity bullets that codify its consequences. Net: P1 is named where it matters most (the design doc), corollaries are implemented in trinity, the principle-rule-text is missing only from the trinity bullet bodies.
- **B.16 (Conditional files).** Researcher flagged IMPLICIT for the underlying principle. This pass agrees with IMPLICIT for the principle (P7-as-design-pattern is not named as a single principle anywhere) but EXPLICIT for the convention instances (CONDITIONAL markers, BEGIN/END project-owned markers, x- prefix, per-entry vs mirror are all named conventions).

---

## §3 — Strategic principles the researcher missed

Six principles surfaced in this pass that the V1 researcher's 26-rule net did not catch. The misses cluster around two patterns: (a) principles named in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Design best practices" that the researcher did not survey systematically, and (b) implicit meta-principles derivable from the design moves but not surfaced as named rules.

### P-missed-1 — Observation/recording separation from solution/decision

**Statement.** Across multiple surfaces, the pack separates the role of OBSERVING-and-RECORDING from the role of DECIDING-the-solution. The reviewer FINDS, Pack Chat TRIAGES, the fix-coder FIXES, the user APPROVES. The auditor REPORTS; Pack Chat decides what to do with the report. The docs-researcher VERIFIES against external sources; the architect uses the research to design. PM-CHAT.md feedback loop: "Record observations, not solutions — the Pack Chat decides what to do with them." This is a load-bearing actor-layer principle that the researcher noted in passing (B.12 evidence) but did not extract as a principle.

**Flag.** EXPLICIT in METHODOLOGY.md Part 10 ("Record observations, not solutions"); EXPLICIT in researcher-evidence for B.8 (reviewer-independence-from-prior-reviews); IMPLICIT as the cross-cutting principle that organizes pack-architect / pack-planner / pack-coder / pack-reviewer / pack-docs-researcher / PM-chat / fix-coder role decomposition.

**Evidence.**

- `supporting-docs/METHODOLOGY.md:1426-1432` Part 10 "What to observe" — four categories of OBSERVATIONS the PM chat records continuously in PACK-FEEDBACK.md.
- `supporting-docs/METHODOLOGY.md:1457-1461` Part 10 "The running doc" — "Record observations, not solutions — the Pack Chat decides what to do with them."
- Trinity `### Workflow` "Triage all reviewer findings; default fix-all" (`AGENTS.md:187-195`): reviewer SURFACES findings; Pack Chat TRIAGES (with user); fix-coder FIXES. Three actors with three distinct roles — the reviewer does not propose fixes (per `feedback_no_prior_reviews_to_reviewer` and the reviewer's read-only scope); Pack Chat does not propose findings (the reviewer's surfacing is the trigger); fix-coder does not triage (the triage decision is upstream).
- CONCEPTUAL-REVIEW-METHODOLOGY.md §"When to tag `ARCH`" (lines 71-84): the reviewer tags `ARCH` severity when fix would re-architect across multiple concepts — but "Does NOT propose a fix — fixes for `ARCH` findings come from a separate architect pass." Observation-vs-fix separation made explicit at the severity level.
- AI-rules `### Agent invocation rules` "No solutions in agent prompts" (`AGENTS.md:208-211`): the prompt-content rule that protects this separation. PM chat / Pack Chat describes problem / goal / success criteria; the agent decides the solution.
- "Researcher-first pipeline" (`AGENTS.md:215-222`): the docs-researcher VERIFIES; the architect uses the verified facts to DESIGN. Two distinct roles.

**Why researcher missed it.** The principle is named in Part 10 of METHODOLOGY (Pack Feedback Loop context, deep in the doc — likely surveyed but not flagged as the cross-cutting pattern). The researcher's B.12 evidence cites the "Record observations, not solutions" line but treats it as one feature of the feedback loop rule rather than the load-bearing actor-layer principle that organizes the entire agent / Pack Chat / user decomposition.

### P-missed-2 — Bidirectionality and round-trip safety

**Statement.** Forward operations must have reverse operations such that forward → reverse → forward is a no-op (byte-identical or whitespace-tolerant). The principle applies across migrations (v9.3 → v10 → v11), per-entry decomposition (mono → per-entry → mono), tracker forward/reverse (flat-file → GH Issues → flat-file), customization preservation (template → custom-merge → template-update → re-merge), and reflected in the V11 architecture's "tracker forward migration must have a reverse that produces byte-identical (or whitespace-tolerant) flat-file." Named EXPLICITLY in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:212` as design principle #2 with V1 §6.0 as the cited source.

**Flag.** EXPLICIT.

**Evidence.**

- CONCEPTUAL-REVIEW-METHODOLOGY.md:212 (table row #2): "**Bidirectionality / round-trip safety** — forward → reverse → forward is no-op | V1 §6.0; every tracker forward must have a reverse that produces byte-identical (or whitespace-tolerant) flat-file."
- Per-entry decomposition (V11): mono BACKLOG.md → per-entry tree → regenerated mono BACKLOG.md is round-trip safe by construction (mono is always derived).
- Customization preservation (BD-136 / `scripts/lib/customization-preserve.sh`): pack template overlay must preserve project marker-pair regions byte-identical across version bumps. Round-trip safety against version bumps is the structural goal.
- OT migration round-trip (Batch 23 dog-food + BD-171 scratch-GH-repo migration): forward migration v10 → v11; reverse via `pack tracker reset` (BD-103 verb); customization regions preserved across both directions.
- Three-way diff (BD-112): customization-preserve uses a three-way merge model (base / theirs / ours) that depends on the round-trip safety of the underlying file format.

**Why researcher missed it.** The principle is named in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:212` (research scope included this file) but the researcher's wide-net frame focused on rules-at-doc-level rather than design-principles-at-architecture-level. The principle has no single trinity bullet or PACK-CHAT.md rule because it operates at a deeper architectural layer.

### P-missed-3 — Composition over special cases

**Statement.** Prefer a uniform mechanism extended through composition (open-string family of values, additive grammar extensions, namespace prefixes) over special-cased operations per use case. Named EXPLICITLY in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:214` as design principle #4 ("Composition over special cases — uniform mechanism for many uses | V1 §5.3 `link.kind` open-string family; avoid new ops per use case").

**Flag.** EXPLICIT.

**Evidence.**

- CONCEPTUAL-REVIEW-METHODOLOGY.md:214 (table row #4).
- V1 §5.3 `link.kind` open-string family — one verb (`provider.link`), parameterized by the `link.kind` value; new link types (blocks/blocked-by/derived-from/promoted-to) admitted by adding values, not by adding new verbs.
- `x-` prefix convention (B.10 in researcher's catalog, P7 instance in §1): one prefix rule applies uniformly to ALL pack-controlled directories that may host project-added files. The mechanism is uniform; the use cases are many (custom agents, custom skills, custom scripts, custom prompts, custom skill-internal files).
- Workflow-artifact pattern family (`AGENTS.md:359-365`): one shared pattern (`<TYPE>-*.md` with naming conventions) admits architect / planner / coder / reviewer / auditor / research / discovery / cleanup-inputs output types. Adding a new output type doesn't require new workflow rules — it admits a new entry in the pattern enumeration.
- Per-entry-tree-rules (`<stream>/_rules.md` files): one rules pattern applies uniformly to backlog / changelog / implementation-plan streams. Adding a new stream means adding a new `_rules.md` with the same shape.
- Tracker mode vs flat-file mode (P3 evidence): one rule structure (per-entry tree as SSOT; monolithic as mirror) with two implementations (mode-dependent resolver).

**Why researcher missed it.** Same as P-missed-2: named in design principles table but not surfaced through the rules-at-doc-level frame.

### P-missed-4 — Mode-agnostic operational logic

**Statement.** Flat-file mode and tracker mode share the same operational logic; only the resolver (the layer that reads/writes the underlying store) differs. Named EXPLICITLY in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:215` as design principle #5 ("Mode-agnostic operational logic — flat-file and tracker mode share the same logic; only the resolver differs | V1 §8.5 / D-6 trinity Document-locations resolver").

**Flag.** EXPLICIT.

**Evidence.**

- CONCEPTUAL-REVIEW-METHODOLOGY.md:215 (table row #5).
- Trinity `### Repo conventions` "Per-entry trees vs mirrors — mode-dependent source of truth" bullet (`AGENTS.md:326-341`): the mode affects WHICH location is SSOT (per-entry tree in flat-file; tracker in tracker mode), but the entry-content rules, the lifecycle states admitted, the supporting-file basenames admitted, the write-authority pointer — all stay the same per `<stream>/_rules.md`.
- Pack tracker init + customization-preserve (V11 architecture): the customization markers + merger logic is the same in flat-file and tracker modes; only the location of the entry content differs.
- V1 §8.5 / D-6 trinity Document-locations resolver: the resolver IS the seam where mode-dependence is isolated; the rest of the operational logic is mode-agnostic.

**Why researcher missed it.** Same as P-missed-2 / P-missed-3: design-principles-table content was in scope but not surfaced as principles via the rules-at-doc-level frame.

### P-missed-5 — Idempotency for orchestration verbs

**Statement.** Re-running an orchestration verb on already-applied state is a no-op or replay-safe. Named EXPLICITLY in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:216` as design principle #6 ("Idempotency for orchestration verbs — re-running on already-applied state is no-op or replay-safe | V1 §6.4 checkpoint; `pack tracker init`, `pack td promote`").

**Flag.** EXPLICIT.

**Evidence.**

- CONCEPTUAL-REVIEW-METHODOLOGY.md:216 (table row #6).
- `pack tracker init` — re-running on an already-initialized project is no-op or surfaces the existing state without overwriting.
- `pack td promote` — re-running on a promoted TD is no-op or replay-safe.
- RC9 manifest-regen `--all --clean` — rebuilding all six fixtures is deterministic; running it on an already-clean manifest produces no diff. The CI `fixture manifest verify` step depends on this idempotency to be a stable gate.
- `init-project.sh` previews every operation and asks for explicit confirmation — idempotency is one input to the safety of the re-run pattern.

**Why researcher missed it.** Same pattern as P-missed-2/3/4.

### P-missed-6 — Stability of code references: symbols not line numbers

**Statement.** Code references in documentation, deferral comments, architect docs, and reports cite the SYMBOL name, not the line number. Line numbers drift with every edit; symbol names are stable. Named EXPLICITLY in `project-template/CLAUDE.md:325-326` ("When citing a code location in a report, use the symbol name not the line number. Line numbers drift with every edit; symbol names are stable."); named in trinity `### Repo conventions` "Architect-doc-vs-reality reconciliation" (`AGENTS.md:393-403`) which makes "file + symbol; never line numbers" the explicit reconciliation chain.

**Flag.** EXPLICIT.

**Evidence.**

- `project-template/CLAUDE.md:325-326` (and AGENTS.md / GEMINI.md parallels): the explicit project-side rule.
- Trinity `### Repo conventions` "Architect-doc-vs-reality reconciliation" (`AGENTS.md:393-403`): pack-side application — "in-code docstring naming the realized consumer (file + symbol; never line numbers — line numbers drift)."
- CONCEPTUAL-REVIEW-METHODOLOGY.md §"File/Symbol scope from authoritative sources, not prose recall" (lines 232-242): reviewer's BD scope anchor MUST source File/Symbol from BD's BACKLOG entry + `git show --stat` for the BD's commit — never from prose recollection. Empirically anchored: BD-112 retro trial cited wrong file from prose, surfaced as methodology friction.
- BD-156 / BD-157 / BD-158 recent batch commits (last few git log entries): "tighten BD-156/157/158 File/Symbol wording" — File/Symbol stability is an active maintenance discipline at HEAD.

**Why researcher missed it.** Researcher's B.7 (typed deferral comments) cited line 326 in passing but treated the line-number-stability principle as a parenthetical to the deferral rules rather than a principle in its own right. The pattern also crosses pack-side and project-side surfaces, which the §A/§B split frame didn't surface.

### Summary — what the researcher missed

The researcher's 26-rule net surfaced 1 pack-side IMPLICIT rule (A.4) + 1 project-side IMPLICIT rule (B.16). This pass adds 6 principles, of which 4 are EXPLICIT in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Design best practices" (P-missed-2/3/4/5) and 1 is EXPLICIT in `project-template/CLAUDE.md` (P-missed-6). One is IMPLICIT as a cross-cutting principle but EXPLICIT in its per-surface instances (P-missed-1).

The common cause of the misses: the researcher's wide net of rules-at-doc-level missed principles named in the design-principles table of `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:209-218` (7 universal principles, of which 5 are essentially absent from the researcher's catalog — only principle #1 SSOT was captured). The researcher's prompt named CONCEPTUAL-REVIEW-METHODOLOGY.md as a survey target but the §A/§B/§C/§D structure didn't have a place to land "design principles that span pack-side and project-side."

---

## §4 — Conflict re-judgment

Independent re-judgment of the V1 researcher's 10 conflicts (D.1 through D.10). For each: independent verdict and rationale, with new categories admitted where they discriminate better than INTENTIONAL-BY-DESIGN vs UNRESOLVED-DRIFT. Two new categories surfaced in this pass: (a) **STALE-UNCHANGED-BULLET** — when a promote-and-restructure batch leaves an existing bullet unchanged whose wording is now contradicted by the new bullets landing in the same restructure; (b) **VERSION-SKEW** — when client-installed projects carry older trinity text than the current pack ships, which is a structural property of the pack-installed-version model and not a defect of the trinity rule.

Three conflicts the researcher missed are added at the bottom of this section as D.11 / D.12 / D.13.

### D.1 — Trinity W3 "One review/fix cycle per batch" vs W12 "Per-BD review/fix INLINE"

**Researcher's framing.** "intra-pack-side." Two bullets coexist in the same `### Workflow` sub-section and describe different review cadences for the same review/fix flow. "The 'once per batch' wording remained" after the W12 bullet landed.

**Independent re-judgment.** **STALE-UNCHANGED-BULLET.** The W3 bullet was preserved verbatim from pre-Batch-19b in the trinity restructure. The W12 bullet ("Per-BD review/fix runs INLINE, before next BD's coder spawns") landed in the same commit (`667d2dd`) as a NEW bullet. The two bullets read contradictorily if interpreted literally: W3 says "Run pack-reviewer ONCE per batch"; W12 says "each BD's review/fix runs INLINE" AND "End-of-batch reviewer runs once on the full batch" — i.e., MORE than once for multi-BD batches. The PACK-REVIEW-broad §2 N2 finding (and the prior researcher's evidence) flag the same drift.

The new category STALE-UNCHANGED-BULLET applies when:
1. A multi-bullet restructure lands NEW bullets that contradict EXISTING bullets in the same section.
2. The existing bullet's wording was not audited for staleness against the new bullets.
3. The trinity-parity-audit on the restructure commit passed (because the existing bullet was already byte-identical across CLI files) but the cross-bullet semantic check did not occur.

This is distinct from INTENTIONAL-BY-DESIGN (the planner chose to preserve the existing bullet without flagging the dissonance) and distinct from UNRESOLVED-DRIFT (the bullets aren't drifting from each other across commits — they're contradictory at the same commit). It's a process gap in the restructure, not a substantive rule conflict. The substantive rule (W12) supersedes (W3) but the OBSOLETE sentence in W3 remains in the working file.

### D.2 — Trinity AI7 PREFLIGHT scope vs PACK-AGENTS.md cross-reference

**Researcher's framing.** "intra-pack-side, minor." Not a direct contradiction; PACK-AGENTS.md states the obligation in absolute terms with a cross-reference to trinity that provides the per-CLI nuance.

**Independent re-judgment.** **NOT A CONFLICT — cross-reference dependency made explicit.** PACK-AGENTS.md line 207-210 explicitly cedes authority to the trinity bullet: "Authoritative full text for both halves of the pattern (including cross-CLI scope notes for Codex / Gemini): trinity `## Pack memory` `### Agent invocation rules` 'Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern' bullet." This IS the P3 (SSOT) pattern in action — trinity bullet is authoritative; PACK-AGENTS.md bullet is the routing surface that points to it. A reader who reads PACK-AGENTS.md alone might infer SendMessage-style enforcement applies to all CLIs, but that's a documentation density tradeoff, not a rule conflict — the cross-reference exists specifically to resolve it.

The PACK-REVIEW-broad did not flag this as a defect either. Researcher correctly classified as "potential" and "candidate site for clarification" rather than active conflict.

### D.3 — Trinity "What Pack Chat CAN edit directly" Codex/Gemini variant vs no-Tier-1.5-for-Codex/Gemini

**Researcher's framing.** "intra-pack-side, by-design divergence the broad reviewer flagged as a planner-classification mismatch." The substantive rule is the same across CLIs; the divergence is the planner's UNIVERSAL classification not anticipating UNIVERSAL-with-tool-specific-trailer.

**Independent re-judgment.** **INTENTIONAL-BY-DESIGN under P2 + classification gap.** The substantive divergence (memory-cache item present in CLAUDE.md; Codex/Gemini sub-bullets explain platform absence per V2 §D) is P2 in action — honest platform-scoping. The classification gap (planner's UNIVERSAL table didn't anticipate UNIVERSAL-with-tool-specific-trailer) is a planner-doc-vs-implementation cosmetic mismatch that the PACK-REVIEW-broad F1 finding caught as SHOULD-severity (not MUST).

A potentially useful refinement to the classification taxonomy: UNIVERSAL admits three sub-forms — (a) byte-identical universal, (b) substantive-rule-universal with per-CLI tool name variant (W5 "Per-action approval extends to sub-agents" has "Claude Code Pack Chat" / "Codex CLI Pack Chat" / "Gemini CLI Pack Chat" variants), (c) UNIVERSAL-with-Claude-only-trailer (W5 has a memory-pointer trailer in CLAUDE.md only). The current taxonomy collapses (b) and (c) into "TOOL-SPECIFIC" or treats them as UNIVERSAL-with-undeclared-variance.

This is observation, not redesign — the substantive rule preservation across all 3 CLI files is verified by PACK-REVIEW-broad §3.

### D.4 — Project-template AGENTS.md / CLAUDE.md include agent enumeration; GEMINI.md drops it

**Researcher's framing.** "intra-project-side, minor." Trinity bullet supposed to be byte-identical per §B.3; CLAUDE.md and AGENTS.md carry the full enumeration; GEMINI.md drops it. "Substantive rule is the same; trinity-parity wording diverges."

**Independent re-judgment.** **UNRESOLVED-DRIFT** with a partial INTENTIONAL-BY-DESIGN component. The GEMINI.md tightening pattern (per V2 §A.5 challenge note: "Gemini's GEMINI.md has a 'Keep this file concise' header") is documented as a Gemini-side stylistic preference. The trinity rule's "asymmetry requires justification as provably tool-specific" qualifier (P2) admits provable-tool-specific exceptions. "Gemini prefers conciseness" is a style preference, not a tool-specific capability difference — so the divergence does NOT satisfy P2's qualifier as the rule is written.

The GEMINI.md's `## Agent roster` section IS marked with a Trinity-rule-exception HTML comment (`project-template/GEMINI.md:400-404`); the agent-enumeration drop in the "PM chat does not architect" bullet is NOT marked. So this is "convention exists for marking exceptions; convention not applied here." UNRESOLVED-DRIFT — the convention's application is incomplete; either the exception should be marked or the enumeration should be restored.

This pass agrees with the researcher's classification at the substantive level but elevates the verdict from "minor" to UNRESOLVED-DRIFT (because the marker convention is documented and applied elsewhere; not applying it here is a known-pattern gap).

### D.5 — Project-template trinity has PACK-AGENTS.md cross-ref; OT trinity does not

**Researcher's framing.** "intra-project-side, minor." Drift across pack versions, not a rule conflict per se. Project-template trinity (v11-dev) has been updated; OT trinity (installed at v10.0) carries older form.

**Independent re-judgment.** **VERSION-SKEW — not a defect of the trinity rule, but a structural consequence of the pack-vs-installed-project model.** OT's trinity carries the v10.0-current text; the v11-dev pack's project-template trinity carries the v11.0-in-development text. Until a forward migration runs (v10 → v11), the OT trinity will continue to carry the older form. This is the EXPECTED behavior under P3 (SSOT applied to METHODOLOGY) + the install-time copy pattern: the pack ships the current text; the project carries the version it was installed at; migration brings the project up to date.

This is a new category. The pack-vs-installed-project model creates four observable states:
1. **Match** — project trinity matches pack trinity at the version the project is at.
2. **Forward-skew** — pack trinity is at v11; project trinity is at v10. EXPECTED until migration runs.
3. **Sideways-skew** — project trinity has been hand-edited to diverge from the pack's install-time text. Customization-preserve handles this via marker pairs.
4. **Backward-skew** — project trinity is at a HIGHER version than the pack. Should not occur in practice; would indicate operator error or git revert.

D.5 is state #2 (forward-skew); not a defect of the trinity rule, not a defect of the customization-preserve mechanism. This pass elevates the verdict from "minor drift" to "VERSION-SKEW (expected; resolves at migration)" — the conflict surfaces a property of the pack model that is load-bearing but not named anywhere as a single principle. (This connects to P-missed-2 bidirectionality: migration should be round-trip safe across version skew.)

### D.6 — Project-template trinity references PACK-AGENTS.md; OT does not have PACK-AGENTS.md

**Researcher's framing.** "intra-project-side / cross-version." If the cross-reference is to a client-project file, OT doesn't have it. If to the pack-side file, the reference is from client to pack and may not resolve.

**Independent re-judgment.** **AMBIGUOUS CROSS-REFERENCE** — a real ambiguity that depends on the intended target. This is distinct from D.5 VERSION-SKEW because it surfaces a question about the cross-reference target that is not version-dependent: even if OT migrated to v11, would `PACK-AGENTS.md` be present in the project? Per `PACK-AGENTS.md` itself (`PACK-AGENTS.md:1-2`) it is a pack-repo file describing pack-development agents; per `INSTALL-PROCEDURES.md`, `PACK-AGENTS.md` is NOT in the install-set for client projects.

So the project-template trinity's reference to `PACK-AGENTS.md` for "the full roster" is a cross-repo reference (client trinity → pack repo's PACK-AGENTS.md) that the client project may not be able to read at session start (the pack repo may not be present on the client developer's machine, or may be at a different path). This is a forward-pointing-reference question, similar to PACK-AGENTS.md's own forward-pointing note about `/backlog/` / `/changelog/` directories that don't exist until Batch 23.

**AMBIGUOUS CROSS-REFERENCE** is a new category: a documented reference whose target may not be present in the reading context. Pack-side `PACK-AGENTS.md` forward-pointing notes for `/backlog/` and `/changelog/` are by-design (they resolve at Batch 23). Project-side `PACK-AGENTS.md` reference is by-design but the resolution semantics are not documented anywhere this pass found.

### D.7 — METHODOLOGY hierarchy of who-writes-BACKLOG vs coder.md hard rules

**Researcher's framing.** "intra-project-side, by-design but worth surfacing." METHODOLOGY says coder "May not"; coder agent file carves out an exception.

**Independent re-judgment.** **NOT A CONFLICT — agent-file-is-authoritative (B.14 / P3) in action.** METHODOLOGY's table is a summary, not authority. The agent file is authoritative per the explicit rule at `project-template/docs/pack/PM-CHAT.md:266-278` ("The agent file is authoritative; this section is the PM-chat-facing reinforcement"). The coder agent file's "unless the caller's prompt explicitly lists those files in 'Files in scope'" carve-out IS the authoritative rule; METHODOLOGY's "May not" is a summary that omits the carve-out for table-density.

The researcher correctly noted this is "not strictly contradictory" but treated it as worth surfacing. This pass classifies as NOT A CONFLICT but DOCUMENTATION-DENSITY-TRADEOFF — the METHODOLOGY table is dense and omits the per-row carve-out detail; the PM chat self-prompt that constructs a coder prompt must read the agent file (per PM-CHAT.md) to get the full rule. This is the SSOT-with-mirror pattern (P3) applied: METHODOLOGY table = mirror; agent file = SSOT.

### D.8 — Pack-side "Pack Chat does NO fixes / no threshold exception" vs project-side METHODOLOGY's PM-chat-may-edit-deferral-comments carve-out

**Researcher's framing.** "cross-side, terminology-divergence." Technically not a conflict because pack-side and project-side are different actors in different repos; but the headline rules read as opposed.

**Independent re-judgment.** **NOT A CONFLICT — different actors in different scopes.** Pack Chat (pack repo) and PM Chat (client project) are different actors. The pack-side "NO threshold exception" applies to Pack Chat's review/fix cycle on the pack repo. The project-side carve-out applies to PM Chat's deferral-comment edits in a client project. The scopes are non-overlapping; the actors are non-overlapping. Headlines read as opposed only when ripped from context.

The structural firewall (P7) instances applied here:
- Pack ops vs pack product (different surfaces with different rule sets).
- Pack Chat vs PM Chat (different actor roles for different repos).
- Review/fix cycle vs deferral-comment edit (different scopes).

The researcher correctly noted the substantive scope distinguishes them. This pass classifies as NOT A CONFLICT and notes that the apparent rule-shape divergence is a P7 firewall consequence (boundaries clearly separated).

### D.9 — Trinity-exception convention is established but not consistently applied

**Researcher's framing.** "intra-project-side, structural." `project-template/GEMINI.md` `## Agent roster` section uses a Trinity-rule-exception HTML comment; the D.4 bullet divergence does not.

**Independent re-judgment.** **UNRESOLVED-DRIFT (convention-application gap).** Same root as D.4 — the Trinity-rule-exception marker convention is documented and applied at the Agent-roster section but not at the agent-enumeration-drop in the "PM chat does not architect" bullet. Either the divergence at the bullet is undocumented (defect under the trinity rule) or it's intentional and not marked (process gap in the convention's application).

The convention is itself a P7 firewall instance (markers in shared files declare intentional region-level divergence). The application gap is structural-firewall-with-incomplete-enforcement: the firewall is named, but its enforcement at every exception site is not yet a process discipline. Compare to RC9 manifest-regen where the discipline is paired with a CI gate; the trinity-exception marker has no equivalent automated check (a hypothetical "every divergent trinity bullet must have a Trinity-rule-exception comment" check is not currently implemented).

### D.10 — No conflict between pack-side and OT-side trinity on "PM chat does not architect"

**Researcher's framing.** "cross-side, EXPLICIT no-conflict." Same rule applied to two distinct actors (Pack Chat on pack repo; PM Chat on client project).

**Independent re-judgment.** **AGREE — NOT A CONFLICT.** The cross-application pattern is documented at `CLAUDE.md:84-86` ("This rule also applies to the pack-repo copies of these three files"). The Pack Chat / PM Chat actor distinction (P7 firewall + P4 actor-and-gate) supports the parallel application without conflict.

Useful as evidence that researcher correctly identified the cross-application pattern; here it's the parallel of D.8 — different actors, different scopes, same rule shape, no conflict.

### Conflicts the researcher missed (D.11 / D.12 / D.13)

#### D.11 — RC9 trinity bullet "v11-surface" definition vs the v11-surface inclusion-test surface

**Citations.**
- RC9 trinity bullet (`AGENTS.md:404-445`): "v11-surface = files under `project-template/` or `scripts/`. Any commit whose diff includes a file under either directory MUST also regenerate `test-fixtures/manifest.txt`."
- Trinity `### Repo conventions` "Separate pack ops from pack product" (`AGENTS.md:345-348`): pack-ops files include "PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc." and ARE NEVER mixed into pack product files (`project-template/`, `supporting-docs/`).

**Nature of (potential) drift.** The RC9 definition of v11-surface excludes `supporting-docs/` and pack-root ops files. But `supporting-docs/` is part of pack-product (per the trinity `### Repo conventions` separation rule — pack-product is `project-template/` AND `supporting-docs/`). So an edit to `supporting-docs/METHODOLOGY.md` would NOT trigger manifest regen by RC9's definition — even though METHODOLOGY.md is copied to client projects at install time (`init-project.sh` Step 3 per the methodology callout at `supporting-docs/METHODOLOGY.md:11-17`).

The RC9 inclusion test is narrow (project-template + scripts only); the pack-product surface is wider (project-template + supporting-docs). The narrowness may be intentional (METHODOLOGY.md edits aren't fixture-rebuild-affecting per the manifest.txt's content), or it may be an unrecognized gap. The PACK-REVIEW-broad §5 RC9 self-consistency audit confirms `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` edit (commit `aaa61b3`) was correctly excluded from manifest regen — so the narrowness is empirically by-design for the manifest pattern.

**Independent classification.** **INTENTIONAL-BY-DESIGN (narrowness is correct for the manifest pattern; the broader pack-product surface is separately addressed by other gates), but DOCUMENTATION-DENSITY-GAP** — the RC9 bullet's "v11-surface = files under `project-template/` or `scripts/`" wording doesn't surface why supporting-docs/ is excluded, leaving a reader who knows the broader pack-product definition to wonder. The rule is correct; the rationale is not in the rule body.

#### D.12 — "Skill and agent maintenance is mechanical by default" workflow-artifact list vs the running practice of producing `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md` files

**Citations.**
- Trinity `### Repo conventions` "Skill and agent maintenance is mechanical by default" (`AGENTS.md:353-370`): workflow-artifact pattern enumeration: `ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`, `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`, `PACK-REVIEW-*.md`, `PACK-REVIEW-*-RETRO.md`, `AUDIT-*.md`, `RESEARCH-*.md`, `*-DISCOVERY.md`, `CLEANUP-INPUTS-*.md`.
- Batch 19b empirical output: `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md`, `-19b-2-RC9.md`, `-19b-2.md`, `-19b-3.md`, `-19b-4.md`, `-19b-5.md`, `-19b-6.md` (7 files per the broad-review §6 archive completeness audit).

**Nature of (potential) drift.** The workflow-artifact pattern `IMPLEMENTATION-REPORT-*.md` admits `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-N.md` — but the filename composition `IMPLEMENTATION-REPORT-<BATCH-CODE>-<SUB-BATCH-CODE>.md` is not itself documented in the pattern. The same applies to `PACK-REVIEW-CLEANUP-BATCH-19B-19b-N.md` and `PACK-REVIEW-CLEANUP-BATCH-19B-broad.md` (the latter following a different sub-pattern: `<TYPE>-<BATCH-CODE>-broad.md`).

The pattern enumeration in the workflow-artifact list specifies the prefix family (the `*-*.md` glob) but not the inner structure. This is admissive: any filename matching the glob is admitted under "Pattern B" (sweep to archive at version ship). The empirical filenames demonstrate that sub-batch and broad-review variants are not in the enumeration explicitly but are admissible. The narrow pattern (just `IMPLEMENTATION-REPORT-*.md`) admits the empirical filenames; no semantic conflict.

**Independent classification.** **NOT A CONFLICT** but **COMPOSITION-OVER-SPECIAL-CASES IN ACTION (P-missed-3 evidence).** The workflow-artifact pattern is one uniform mechanism that admits arbitrary sub-batch / variant structure without enumerating each. This is the P-missed-3 principle (Composition over special cases) at work — the rule does not need a new pattern per sub-batch shape.

This is included as D.12 because it surfaces a question a reader might ask ("are these new filenames valid under the workflow-artifact pattern?") but the answer is YES under P-missed-3. Not a conflict; a documentation density question.

#### D.13 — Pack-root vs `project-template/` trinity rule scope ambiguity

**Citations.**
- `CLAUDE.md:80-86` (pack-root): "When modifying `project-template/CLAUDE.md`, always make the parallel edit in `project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit. ... This rule also applies to the pack-repo copies of these three files."
- `project-template/CLAUDE.md:354-357`: "When modifying `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` at the project root, the same change applies to all three in the same set of edits."

**Nature of (potential) drift.** Two trinity rules. The pack-root rule is FRAMED as applying to `project-template/` files first, then cross-applying to pack-root files via the "This rule also applies" clause. The project-template rule applies to `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "at the project root" — i.e., at the client project's root after install. Both rules cover the same trinity surface for the project-template files but the cross-application to pack-repo is documented at the pack-repo trinity, while the cross-application to the project root is the natural-extension of the project-template rule.

The researcher noted this overlap in C.8 ("This is a single cross-surface rule expressed as one origin (project-template trinity) plus a cross-application bullet"). This pass adds: the cross-application's framing creates a small ambiguity — when a pack maintainer edits pack-root `CLAUDE.md`, the rule "This rule also applies to the pack-repo copies of these three files" is in pack-root `CLAUDE.md`, but the BODY of the rule references `project-template/` files. A reader who reads only pack-root `CLAUDE.md:80-86` needs to substitute "pack-root" for "project-template/" mentally; the rule does not state this substitution explicitly.

**Independent classification.** **NOT A CONFLICT** but **DOCUMENTATION-DENSITY-GAP** — the cross-application clause is correct; the substitution semantics are not surfaced in the pack-root version of the rule. This is similar to D.11: the rule is right; the rationale and substitution semantics aren't in the rule body.

### Summary — conflict re-judgment categories

| Researcher D# | Researcher framing | Independent verdict | New category? |
|---|---|---|---|
| D.1 | intra-pack-side | STALE-UNCHANGED-BULLET | YES — new category |
| D.2 | intra-pack-side, minor | NOT A CONFLICT (P3 cross-reference) | no |
| D.3 | intra-pack-side, by-design | INTENTIONAL-BY-DESIGN under P2 + classification gap | no |
| D.4 | intra-project-side, minor | UNRESOLVED-DRIFT (convention-application gap) | no |
| D.5 | intra-project-side, cross-version | VERSION-SKEW (expected; resolves at migration) | YES — new category |
| D.6 | intra-project-side, cross-version | AMBIGUOUS CROSS-REFERENCE | YES — new category |
| D.7 | intra-project-side, by-design | NOT A CONFLICT (agent-file-authoritative / P3) | no |
| D.8 | cross-side, terminology-divergence | NOT A CONFLICT (different actors / P4 + P7) | no |
| D.9 | intra-project-side, structural | UNRESOLVED-DRIFT (convention-application gap; same root as D.4) | no |
| D.10 | cross-side, no-conflict | AGREE — NOT A CONFLICT | no |
| D.11 (new) | n/a | INTENTIONAL-BY-DESIGN + DOCUMENTATION-DENSITY-GAP | one new sub-category |
| D.12 (new) | n/a | NOT A CONFLICT (P-missed-3 in action) | no |
| D.13 (new) | n/a | NOT A CONFLICT + DOCUMENTATION-DENSITY-GAP | no |

Three new categories surfaced: STALE-UNCHANGED-BULLET, VERSION-SKEW, AMBIGUOUS CROSS-REFERENCE. Two of the researcher's conflicts (D.4, D.9) are reclassified to UNRESOLVED-DRIFT with the convention-application-gap variant. The categories DOCUMENTATION-DENSITY-GAP and DOCUMENTATION-DENSITY-TRADEOFF are sub-categories of NOT A CONFLICT.

The dominant pattern: most of the researcher's "conflicts" are not rule conflicts; they are cross-reference dependencies, actor-scope distinctions, documentation-density tradeoffs, or convention-application gaps. The only true intra-trinity-bullet contradiction is D.1 (STALE-UNCHANGED-BULLET, which the PACK-REVIEW-broad's N2 NIT independently caught).

---

## §5 — Principle hierarchy (dominance and constraint map)

The 7 load-bearing principles + 6 missed principles are not a flat list. They have dominance and constraint relationships that organize the rule space. This section names the relationships explicitly using three relation types:

- **X dominates Y** (X is the goal; Y is one of X's means / instances / corollaries)
- **X constrains Y** (Y operates under a limit imposed by X; without X, Y would over-reach)
- **X and Y are co-equal addressing different surfaces** (independent peers; not derivable from each other)

The map is presented as a layered diagram (text-only) below, followed by per-edge rationale.

### 5.1 — Hierarchy diagram (text)

```
                        ╭─────────────────────────────────────╮
                        │  P5 — Empirical anchoring (META)    │
                        │  (rules are made only when grounded │
                        │   in observed evidence; this is the │
                        │   meta-principle that constrains    │
                        │   what gets codified)               │
                        ╰──────────────┬──────────────────────╯
                                       │ constrains rule-codification
                                       ▼
       ╭─────────────────────────────────────────────────────────────╮
       │  P1 — Authority by construction over discipline by         │
       │  convention (DESIGN-LEVEL — the dominant design move        │
       │  organizing how every other principle gets enforced)       │
       ╰──────────────┬──────────────────────────────────────────────╯
                      │ dominates enforcement of
                      ▼
   ╭──────────────────────────────────────────────────────────────────╮
   │  P3 — Single source of truth (with regenerable mirrors)         │
   │  • Trinity SSOT for pack rules                                  │
   │  • METHODOLOGY SSOT for project methodology                     │
   │  • Per-entry tree SSOT for entry content (mode-dependent)       │
   │  • Agent file SSOT for agent-operating-rules                    │
   │  • ARCHITECTURE / IMPLEMENTATION-PLAN SSOT for design/plan      │
   │  • PACK-FEEDBACK SSOT for upstream feedback                     │
   │  • Manifest SSOT for RAG ingestion                              │
   ╰──────────────┬───────────────────────────────────────────────────╯
                  │ constrained by
                  ▼
       ╭────────────────────────────────────────────────╮     ╭─────────────────────────────╮
       │  P2 — Honest platform scoping                  │     │  P-missed-2 — Bidirectionality │
       │  (don't fake parity where the platform        │     │  / round-trip safety        │
       │   genuinely lacks the feature)                │     │  (architecture-level;       │
       │  Constrains: trinity rule's three variant     │     │   forward = reverse for     │
       │  classes (UNIVERSAL / TOOL-SPECIFIC / TOOL-   │     │   migrations + per-entry    │
       │  ONLY); tool-equivalence as default not       │     │   decompose / recompose)    │
       │  universal capability claim                   │     ╰──────────────┬──────────────╯
       ╰────────────────────────────────────────────────╯                    │
                                                                              │
   ╭──────────────────────────────────────────────────────────────────╮      │
   │  P4 — Actor-and-gate orchestration                              │      │
   │  (every rule names WHO does the work and WHO approves;          │      │
   │   gate-points are explicit between actor handoffs)              │      │
   │                                                                 │      │
   │  Actor decomposition pack-side:                                 │      │
   │    user, Pack Chat, pack-architect, pack-planner,               │      │
   │    pack-coder, pack-reviewer, pack-docs-researcher, fix-coder   │      │
   │                                                                 │      │
   │  Actor decomposition project-side:                              │      │
   │    user, PM Chat, architect, planner, coder, reviewer, tester,  │      │
   │    docs-researcher, auditor (+ variants), grpc-schema, repo-ops │      │
   │                                                                 │      │
   │  Dominates (corollaries):                                       │      │
   │    plan-before-execute (P4 gate); Pack/PM Chat does not         │      │
   │    architect (actor boundary); Pack Chat does no fixes (actor   │      │
   │    boundary); agents never commit (actor boundary at commit     │      │
   │    gate); user retains hard-stop authority (gate); per-BD       │      │
   │    review/fix INLINE (sequence); triage all reviewer findings   │      │
   │    (gate); no solutions in prompts (prompt-content rule         │      │
   │    protecting actor boundary); REPORT FILE in every prompt      │      │
   │    (handoff format); stop after reviewer pass for triage        │      │
   │    discussion (gate)                                            │      │
   ╰────────────────────────┬─────────────────────────────────────────╯      │
                            │ relates to                                     │
                            │                                                │
                            ▼                                                ▼
   ╭──────────────────────────────────────────────────────────────────╮     ╭─────────────────────────────╮
   │  P-missed-1 — Observation/recording separation from              │     │  P-missed-3, 4, 5            │
   │  solution/decision (cross-cutting actor-layer principle:         │     │  (Composition over special   │
   │  reviewer finds, Pack Chat triages, fix-coder fixes, user        │     │  cases; mode-agnostic        │
   │  approves; docs-researcher verifies, architect designs;          │     │  operational logic;          │
   │  auditor reports, Pack Chat decides)                             │     │  idempotency for             │
   ╰──────────────────────────────────────────────────────────────────╯     │  orchestration verbs)        │
                                                                              │  (architecture-level peers   │
   ╭──────────────────────────────────────────────────────────────────╮     │  of P-missed-2;              │
   │  P6 — Fix-now-default with structural friction against deferral │     │  independent surfaces)       │
   │  (default for surfaced findings is FIX-IN-CURRENT-SESSION;      │     ╰─────────────────────────────╯
   │   deferral requires user-discussion-and-approval per OQ-1)      │
   │                                                                 │
   │  Dominates: No deferral to v11.1+; Triage default fix-all;      │
   │  Deferred work needs tracked anchor; Scope-extension test;      │
   │  No new BDs without user approval                               │
   ╰──────────────────────────────────────────────────────────────────╯

   ╭──────────────────────────────────────────────────────────────────╮
   │  P7 — Boundary separation by structural firewall               │
   │  (boundaries are enforced structurally — different directories, │
   │   filename prefixes, markers, lifecycle gates — not stylistically │
   │   by convention alone)                                          │
   │                                                                 │
   │  Seven instances:                                               │
   │    (a) pack ops vs pack product (directories)                  │
   │    (b) `x-` prefix (filename namespace)                        │
   │    (c) per-entry tree vs monolithic mirror (file shape)        │
   │    (d) PM-only files (agent permission profile)                │
   │    (e) workflow-artifact archive sweep (lifecycle gate)        │
   │    (f) CONDITIONAL + BEGIN/END project-owned markers (region)  │
   │    (g) trinity pack-root vs project-template (path-disambig)   │
   ╰──────────────────────────────────────────────────────────────────╯

   ╭──────────────────────────────────────────────────────────────────╮
   │  P-missed-6 — Stability of code references                      │
   │  (cite symbols, not line numbers; file + symbol in deferral     │
   │   comments, architect-doc-vs-reality reconciliation, reviewer   │
   │   BD scope anchors)                                             │
   ╰──────────────────────────────────────────────────────────────────╯
```

### 5.2 — Per-edge rationale

**P5 dominates P1, P2, P3, P4, P6, P7 (meta-level constraint on rule-codification).** P5 is the meta-principle about how rules are made: every rule must cite observable evidence; reasoning-from-first-principles without evidence is not surfaced. This constrains ALL other principles at the codification layer — none of the seven load-bearing principles in §1 was codified into trinity without an incident anchor (RC9 = 2026-05-17 CI failure; AI7 PREFLIGHT = BD-169 19g-pack incident; architect-doc-vs-reality reconciliation = BD-119 § 9.2 worked example; filename uniqueness = BD-135; etc.). The meta-principle is not derivable from any individual rule; the rules are constrained by it.

**P1 dominates P3 enforcement.** P3 (SSOT) is the goal; P1 (Authority by construction) is the dominant means by which P3 is enforced. The V2 architect doc's Tier 2 → Tier 1.5 collapse is the clearest evidence: the Tier 2 design would have been a P3 SSOT with discipline-based mirror maintenance; the Tier 1.5 collapse makes the SSOT-preservation structural (pointer-only file shape; no body text possible) — P1 enforcing P3. Same pattern at per-entry trees (P3 SSOT) vs regenerated monolithic mirrors (P1 — mirror is overwritten on every regen, so drift is impossible by construction).

**P1 dominates P7 enforcement too.** The seven P7 firewall instances are P1 in action at the boundary layer: each firewall is a structural mechanism (directory separation, filename prefix, marker, agent permission profile) that enforces the boundary by construction rather than by reader discipline. Pack scripts skip `x-*` per the convention; PM-only files are rejected at the commit-discipline skill layer; archive sweep happens at version ship as the final pre-tag step (lifecycle gate).

**P2 constrains P3 (trinity-as-SSOT).** P3 says trinity is the SSOT for pack rules; P2 constrains this with the three variant classes — UNIVERSAL (byte-identical SSOT for all CLIs); TOOL-SPECIFIC (substantive rule SSOT with per-CLI machinery variant); TOOL-ONLY (SSOT exists for one CLI only because the underlying capability is platform-exclusive). Without P2, P3 would over-reach: it would require byte-identical trinity even for rules that can't reasonably apply to every CLI.

**P-missed-2 (Bidirectionality) is co-equal with P3, not dominated.** Bidirectionality is an architecture-level property about HOW the SSOT and its mirrors relate (forward + reverse round-trip safe). P3 is about WHICH location is authoritative; P-missed-2 is about whether the forward/reverse operations preserve the SSOT across migrations. They're peer architecture-level principles addressing different surfaces.

**P4 dominates many corollaries.** The corollary list in §2 is large because P4 is the rule-shape principle that organizes the agent / Pack Chat / user actor decomposition. Plan-before-execute is P4-at-the-start-of-work; Pack Chat does no fixes is P4-at-the-fix-gate; agents-never-commit is P4-at-the-commit-gate; user-retains-hard-stop is P4-at-every-gate.

**P-missed-1 (Observation/recording separation) is dominated by P4 + parallel to it.** P-missed-1 is an actor-layer principle ABOUT what each actor's role is (observe vs decide vs fix vs approve). It's a P4 corollary in the sense that it operates within the actor-and-gate frame, but it's load-bearing enough to be its own principle: it organizes the asymmetric responsibilities of the reviewer (find), Pack Chat (triage), fix-coder (fix), user (approve) — and the analogous splits for docs-researcher (verify) / architect (design), auditor (report) / Pack Chat (decide). Without P-missed-1, the actor boundaries would be present but the roles would be undifferentiated.

**P6 (Fix-now-default) is constrained by P4 (user retains hard-stop authority).** P6 says default is fix-now; P4 says the user can stop or redirect any planned action. Together: the fix-now default operates within the user's hard-stop authority; the structural friction against deferral does not override user-approved deferrals.

**P7 is co-equal with P3, addressing different surfaces.** P3 is about WHERE rules / content live (one authoritative location); P7 is about HOW conceptually distinct surfaces are kept separate (structural firewalls). The two are complementary: P3 says "trinity is THE place for pack rules" (one location); P7 says "pack-ops files vs pack-product files vs maintenance-docs vs maintenance-docs/archive are kept structurally separate" (different locations for different concept-classes). Together they answer "what goes where" without ambiguity.

**P-missed-3 (Composition over special cases) is co-equal with P-missed-2, addressing different surfaces.** Composition is an architecture-level design preference (uniform mechanism + parameter values; open-string family; additive grammar extensions). It's not dominated by P3 or P4 or P7 — it operates at the schema-design layer (link.kind, x-prefix, per-entry-tree-rules pattern, workflow-artifact pattern). It influences how the firewalls (P7) and the gates (P4) are SHAPED, but it's a peer principle.

**P-missed-4 (Mode-agnostic operational logic) is co-equal with P-missed-2 and P-missed-3 at the architecture layer.** Same reasoning: architecture-level design preference about how flat-file mode and tracker mode share operational logic; only the resolver differs. Influences the design of P3-applied-to-per-entry-trees but is not derivable from P3.

**P-missed-5 (Idempotency for orchestration verbs) is co-equal at the verb-design layer.** Architecture-level design preference about how orchestration verbs (`pack tracker init`, `pack td promote`, `init-project.sh`, manifest rebuild) behave when re-run. Influences the design of P1-applied-to-orchestration but is not derivable from P1.

**P-missed-6 (Symbols not line numbers) is parallel to P-missed-2/3/4/5 at the code-reference layer.** Architecture-level design preference about the stability of code references. Influences the typed deferral comment format (B.7), the architect-doc-vs-reality reconciliation pattern, the reviewer's BD scope anchor source-of-truth rule. Not dominated by another principle.

### 5.3 — The layered model summarized

Three layers organize the principle space:

1. **Meta layer (1 principle).** P5 — empirical anchoring constrains rule-codification.
2. **Design-organization layer (1 principle, dominant).** P1 — Authority by construction over discipline by convention dominates how the other principles get enforced.
3. **Substantive principles (12 principles).** Six on the surface-decomposition + actor-and-gate side (P3 / P2 / P4 / P6 / P7 / P-missed-1) + six on the architecture-design side (P-missed-2 / 3 / 4 / 5 / 6 and one more design-pattern preference observable in code-reference rules).

This is the architect-grade decomposition: 1 meta + 1 dominant design move + 12 substantive principles. Not a flat list of 26.

---

## §6 — Meta-notes on the researcher's framing

The V1 researcher's pass produced 26 rules across 4 sections (§A pack-side, §B project-side, §C overlaps, §D conflicts) and was characterized in the prompt to this pass as "USEFUL but ARCHITECT-SHALLOW." This section names where the researcher's framing is right, where this pass would have framed differently, and where the 26-rule wide net was useful versus noisy.

### 6.1 — Where the researcher's structure is right

- **The §C overlap section IS a valuable pattern.** Researcher's §C correctly surfaced that pack-side and project-side rules often express the SAME substantive rule at different scopes. C.1 (SSOT), C.2 (trinity-first), C.10 (PM/Pack chat does not architect) are the strongest examples. This pass kept the parallel-application observation in the §5 hierarchy (e.g., P3 has both pack-side and project-side instances) and in the §2 reclassification (researcher's A.X often pairs with researcher's B.X under one principle).
- **The empirical evidence per rule is high quality.** Researcher cited specific file paths, line ranges, commit SHAs, and archived doc sections. The evidence base supports re-classification without re-derivation; this pass relied on the researcher's evidence trail for many of the 26 → 7 + 6 reclassifications.
- **The IMPLICIT-vs-EXPLICIT flag is the right axis.** Researcher's two-flag taxonomy (one input among others) correctly recognizes that some principles are surfaced as named rules while others operate as patterns across multiple rules. This pass extends the taxonomy with a third state: EXPLICIT-IN-DESIGN-DOC-but-IMPLICIT-IN-OPERATING-DOCS (used for P1 — named in V2 architect doc § A.1 + § D.2 but not as a single load-bearing bullet in trinity).
- **D.10's explicit "no-conflict" declaration is valuable methodology.** Calling out where the absence of a conflict is itself an architectural property prevents over-claiming. This pass agrees and adds D.7, D.8, D.12 to the NOT-A-CONFLICT category with rationale (rather than just leaving them out of the conflict list).

### 6.2 — Where this pass would have framed differently

- **The §A pack-side / §B project-side split is misleading.** Most principles span both surfaces; the split produced researcher's 26-rule inflation because each principle got at least one pack-side rule AND at least one project-side rule (often more than one of each). §C tried to repair this by surfacing overlaps but treated overlap as the exception. This pass treats cross-surface application as the DEFAULT and explicitly splits only where the principle is genuinely pack-only or project-only (very few such cases — the trinity-pack-root vs project-template scoping is the main one, captured under P7 as a firewall instance not as a principle split).
- **The §D conflict list is dominated by non-conflicts.** Of the researcher's 10 conflicts, 6 are NOT-A-CONFLICT under independent re-judgment (D.2, D.5, D.6, D.7, D.8, D.10). Only D.1 is a true intra-trinity-bullet contradiction; D.3 is intentional-by-design with a classification gap; D.4 and D.9 are convention-application gaps; D.5 is VERSION-SKEW (expected behavior, not a defect). The conflict frame imposed pattern-matching pressure ("find 10 conflicts") that produced false-positive conflicts where the underlying structure is just SSOT-with-mirror, agent-file-is-authoritative, or actor-scope distinction. A leaner conflict list (3 real items: D.1 + D.4 + D.9, all of which the PACK-REVIEW-broad's NITs caught) would be more accurate.
- **The "26 rules" count was wide-net by design but produced corollary inflation.** The wide net surfaced evidence breadth but also produced rule-and-corollary-as-peers structure. The §1 winnow to 7 + 6 = 13 principles is the architect-grade compression. The remaining 13 (the principle count) is still high for "architect-grade synthesis" — a stricter pass could compress P-missed-3 + P-missed-4 + P-missed-5 into a single "architecture-level design preferences" cluster, dropping the count to ~10. This pass preferred separate principles where each is named EXPLICITLY in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:209-218`; the table-based source is the boundary.
- **The IMPLICIT-EXPLICIT flag undercounted IMPLICIT principles.** Researcher flagged only A.4 (pack-side) and B.16 (project-side) as IMPLICIT (2 of 26). This pass surfaces P-missed-1 (Observation/recording separation) as IMPLICIT-cross-cutting (named in B.12 evidence but not extracted as the cross-cutting principle organizing actor decomposition) and elevates P1 from researcher's IMPLICIT to EXPLICIT-in-design-doc + IMPLICIT-in-trinity. The likely cause of researcher under-counting IMPLICIT: the §A/§B per-surface frame doesn't have a place to land "principle that organizes multiple per-surface rules but is named at the design layer rather than the rule layer."
- **Calling out P5 (Empirical anchoring) as a META-principle was missed.** Researcher flagged A.7 as "EXPLICIT (per CONCEPTUAL-REVIEW-METHODOLOGY) and reinforced by the batch's own pattern" — correctly recognizing it as a meta-rule about how rules are made. But the researcher did not make P5 the constraint on the other 9 pack-side rules' codification. This pass elevates P5 to the META layer in §5's hierarchy diagram — it's the principle that explains why the other principles' codifications all carry incident citations.

### 6.3 — Where the 26-rule wide net was useful vs noisy

**Useful (where the wide net surfaced evidence that an architect-grade pass needs):**

- **Per-rule evidence trail.** Every researcher rule has file paths + commit SHAs + section/line citations. Reclassification can rely on this trail without re-surveying.
- **Cross-surface parity catches.** §C surfaced where pack-side and project-side rules are parallel — useful for noting that P3 / P4 / P7 have both pack-side and project-side instances. Without §C, the cross-application pattern would need to be re-derived.
- **Conflict candidates.** Even when most §D conflicts re-judge as NOT-A-CONFLICT, the candidates surface real questions about cross-reference dependencies, agent-scope distinctions, and convention-application gaps. The architect pass uses them as starting points for the more careful re-judgment in §4.
- **Coverage breadth.** §A 10 + §B 16 = 26 rules is enough to ensure no major surface was missed in the pack-side / project-side overview. A narrower net might have missed B.7 (typed deferral comments) or B.15 (RAG manifest hygiene), both of which carry useful evidence for P-missed-6 and P3+P1 respectively.

**Noisy (where the wide net produced false structure):**

- **Researcher rules as peers.** Treating A.1 (SSOT — load-bearing) as a peer of A.10 (pack ops vs pack product separation — a P7 firewall instance) flattens the principle space. The §1 winnow corrects this.
- **§C overlaps as a separate section.** Treating "same rule on both sides" as a separate observation hides the principle-level point (the principle is one; the surfaces are two). This pass folds overlaps into the principle-level corollary expansion.
- **§D conflict inflation.** Pattern-matching pressure to find 10 conflicts produced 6 NOT-A-CONFLICT entries. A more careful pass would have found fewer, real conflicts.
- **Pack-side / project-side as the top-level split.** The split is convenient for survey but obscures the principles that span both. §1 / §5 of this pass merge the surfaces and surface the principles cross-cuttingly.

### 6.4 — Net assessment

The researcher's pass is useful as a baseline evidence collection and as a sanity check on cross-surface parity. As an architect-grade synthesis, the 4-section frame imposes a worldview (pack-side / project-side / overlaps / conflicts) that an architect pass would reorganize around principle dominance and constraint relationships. This pass's seven + six principles (with the 1 meta + 1 dominant design move layering in §5) is the architect-grade decomposition the prompt asked for. Researcher's evidence base is the load-bearing input; researcher's structure is one input among others (per the anti-bias protocol).

The dominant misses (P1 elevated from IMPLICIT to dominant; P-missed-1 / 2 / 3 / 4 / 5 / 6 surfaced as new) all come from the researcher's structural frame not having a natural place to land "design-level principles that organize multiple per-surface rules" or "architecture-level design preferences named in the design-principles table." Both are foreseeable consequences of the §A/§B/§C/§D frame; both are correctable by the principle-centric frame this pass uses.

---

*End of ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md*
