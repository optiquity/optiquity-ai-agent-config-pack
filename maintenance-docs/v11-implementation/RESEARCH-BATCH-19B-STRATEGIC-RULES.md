# RESEARCH — Batch 19b strategic-rules baseline (pre-V2-architect)

**Researcher:** pack-docs-researcher
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `3d8cc8b`)
**Scope:** Identify the STRATEGIC RULES (meta-principles about how the pack and project-side configuration systems should work) that drove Batch 19b pack-side work and that govern the project-side surface. Then find overlaps and conflicts.
**Out-of-scope (per prompt):** the 19c V1 architect doc and its sibling principle-check and V0-DISCARDED docs were NOT read.
**Independence:** this research is intended to form a baseline independent of the 19c V1 pass.

---

## What counts as "strategic" in this report

- **Strategic rule** = a META-principle about how rules / structure / orchestration should work. Example (user-supplied): "For every pack rule, there should be a single source of truth and no duplicates."
- **Operational rule** = a specific behavior. Example: "Spawn sub-agents in background."
- Operational rules implement strategic rules. The same operational rule may show up across many surfaces because of where the strategic rule directs it to live.
- Strategic rules may be EXPLICIT (named in a doc / memory as a principle) or IMPLICIT (derivable from a pattern of operational rules + the rationale captured in commit messages, archived architect docs, or memory file descriptions).
- This research only identifies. It does not redesign, recommend, or propose fixes.

---

## §A — Pack-side strategic rules from Batch 19b

Each rule names the strategic principle, gives a one-sentence statement, lists evidence (at least one of: explicit citation, pattern of operational rules, or commit hunk), and flags `EXPLICIT` or `IMPLICIT`.

### A.1 — Single source of truth per rule (explicit)

**Statement.** Every pack rule lives in exactly one authoritative location. Where mirror or pointer surfaces exist, they are derivable from the source and the source wins on disagreement by construction.

**Flag.** EXPLICIT — named as principle 1 of "Design best practices" in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:211`: "**Single source of truth** for content / rules / config — Trinity files; HELP-FRAGMENT pack-root vs project-template; spec sections vs implementation comments."

**Evidence (additional).**
- Trinity (pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory`) is the explicit single source of truth that Batch 19b consolidates onto. ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §A.1 (archived) names the design choice: "Trinity-first, single-tier-of-truth ... Tier 1.5 = Claude-Code memory cache (pure pointer file ... NO body text, NO contradictions possible by construction)."
- Per-entry trees vs mirrors trinity bullet (CLAUDE.md / AGENTS.md / GEMINI.md `### Repo conventions` "Per-entry trees vs mirrors — mode-dependent source of truth"): per-entry tree IS source of truth in flat-file mode; monolithic mirrors are regenerated. The principle is stated as an invariant: "If a convenience view drifts, the per-entry tree (Mode 2) or the tracker (Mode 3) wins."
- Memory pointer files (`~/.claude/projects/<slug>/memory/*.md`) carry a verbatim footer: "If this pointer disagrees with trinity, TRINITY WINS. Update this pointer file in the same commit as any trinity rule change." (sample: `feedback_pack_chat_does_no_fixes.md:19-20`).
- Tier-1.5 cache file MEMORY.md leads with: "Trinity is the single source of truth; this file is a Claude-Code convenience cache. If this index disagrees with trinity, TRINITY WINS."

**Where 19b enforces it.**
- Commit `667d2dd` (19b-1) restructured trinity `## Pack memory` and PROMOTED 11 rules out of Claude-only memory into trinity so they are sourced once.
- Commit `a9b7c74` (19b-2-RC9) added the manifest-regen rule as one byte-identical bullet across all three trinity files.
- Commit `3558525` (19b-3) added the PACK-AGENTS.md PREFLIGHT obligation explicitly as a CROSS-REFERENCE pointer back to trinity AI7 ("PACK-AGENTS.md does not re-state the full rule; it points at the canonical source." — commit `3558525` message).

### A.2 — Trinity-first cross-CLI parity (explicit)

**Statement.** Rules that apply across CLI tools live in the trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) with three permitted variant classes: UNIVERSAL (byte-identical), TOOL-SPECIFIC (different machinery, same substantive rule), and TOOL-ONLY (a per-CLI capability with no counterpart). All other arrangements are violations.

**Flag.** EXPLICIT.

**Evidence.**
- `CLAUDE.md` "Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md" section, lines 76-83: "These three files must express the same project rules. The only exception is a change that is provably tool-specific."
- Skill `commit-discipline` enforces the same rule at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/commit-discipline/SKILL.md:135-150` ("Symmetry is the default; asymmetry requires justification in the implementation report.").
- ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §3 (archived) names the three variant classes (UNIVERSAL / TOOL-SPECIFIC / CLAUDE-ONLY) and uses them as the planning unit for the restructure.
- Tier-1.5 memory entry `feedback_clarg_trinity.md` (referenced by MEMORY.md) carries the same rule with worded scope.

**Where 19b enforces it.**
- Trinity restructure (commit `667d2dd`): 25 universal bullets are byte-identical across the 3 files; 5 tool-specific bullets carry the same substantive rule with per-CLI wording; 4 Claude-only bullets (the entire `### Sub-agent behavior (Claude-only)` sub-section) are correctly omitted from AGENTS.md / GEMINI.md.
- PACK-REVIEW-CLEANUP-BATCH-19B-broad.md §3 (archived) is structured as a trinity-parity audit (per-sub-section diff classified against the planner's UNIVERSAL / TOOL-SPECIFIC / CLAUDE-ONLY taxonomy).

### A.3 — Cross-CLI scope honesty: ship the rule for what the platform supports, not what the pack wishes (explicit)

**Statement.** When a CLI platform genuinely lacks a feature (Codex has no SendMessage; Gemini has no per-project memory cache; only Claude has Tier-1.5), the pack does NOT invent a non-canonical surface to fake parity. It documents the platform limit and ships the strongest rule each platform actually supports.

**Flag.** EXPLICIT.

**Evidence.**
- ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §A.1 (archived) explicitly rejects "Tier 2 (tool-native memory caches)" as a design because (a) Codex memories are opt-in + regionally restricted + opaque per official guidance, (b) Gemini has no separate per-project memory cache. The architect's verdict: collapse to Tier-1.5-Claude-only; trinity is the ONLY surface Codex/Gemini see.
- ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §C.4 (archived): "Codex / Gemini pack-coder prompts get the PREFLIGHT requirement immediately; they get the STOP-MEANS-STOP preamble as CONTENT (the text is in the prompt) but cannot benefit from the SECURITY WARNING enforcement layer Claude has. That is an honest reflection of platform capability."
- Trinity AI7 bullet (CLAUDE.md / AGENTS.md / GEMINI.md `### Agent invocation rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern") encodes this honesty inside one bullet body — PREFLIGHT is platform-neutral; STOP-MEANS-STOP enforcement is conditional with explicit per-CLI notes (Claude: SendMessage; Codex: `/agent`; Gemini: `Ctrl+C`).

**Where 19b enforces it.**
- Commit `667d2dd` lands the AI7 hybrid bullet across all 3 trinity files.
- Pack ops `AGENTS.md:288-293` and `GEMINI.md` (its equivalent) name the Codex/Gemini-side limit explicitly: "Codex has no pack-shipped per-project memory cache (Codex memories are opt-in + regionally restricted + opaque generated state per official guidance; the pack does NOT ship a Codex memory file)."

### A.4 — Authority by construction over discipline by convention (implicit)

**Statement.** When the pack must guarantee an invariant, prefer mechanisms that make violation structurally impossible over rules that depend on actor discipline. When discipline is unavoidable, attach an automatic check that fails loudly.

**Flag.** IMPLICIT — derivable from a pattern across multiple 19b artifacts.

**Evidence.**
- Tier-1.5 memory files were reduced to pointer-only shape so the memory-vs-trinity disagreement is impossible by construction (ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §D.2 archived: "A pointer-only Tier 1.5 file makes 'trinity and memory disagree' impossible by construction.").
- RC9 manifest-regen rule (commit `a9b7c74`) is paired with a CI check (`fixture manifest verify`, BD-115) that fails loudly when an actor forgets; the trinity bullet itself sets actor discipline ("regenerate the manifest in the same commit") AND names the authority that supersedes it: "The manifest diff after rebuild is the canonical authority — the trigger globs are a screen for WHEN to run the rebuild." (trinity `### Repo conventions` RC9 bullet, e.g., `AGENTS.md:430-435`).
- "Pack-coder PREFLIGHT" requires the coder to emit a structured trust line BEFORE writing the IMPL-REPORT; the parent session can verify the line exists rather than trusting the coder's self-report (trinity AI7 bullet).
- "PM-only files" list (`PACK-AGENTS.md:142-148`) is enforced by `commit-discipline` skill section 4 ("PM-only file boundaries") AND by agent prompt rule "explicit caller scoping required" — discipline at the actor layer, but agents that get the prompt without scope return a POQ instead of editing.

**Pattern.** Where the pack added a rule in 19b, it preferred a structural enforcement (pointer-only file; CI manifest check; PREFLIGHT line shape; PM-only list) over a "remember to do X" rule alone. When a pure-discipline rule was added (e.g., "regenerate manifest on v11-surface commit"), the pack also wired an automated check that catches drift.

### A.5 — Roles as orchestration boundaries: who-does-the-work is part of the rule (explicit)

**Statement.** Pack rules name WHO performs each action (Pack Chat, fix-coder, pack-architect, pack-reviewer, pack-docs-researcher) and gate handoffs between roles with explicit triage / approval / report-file points. A rule about WHAT to do is incomplete without a rule about WHO does it and WHO approves it.

**Flag.** EXPLICIT.

**Evidence.**
- The trinity `### Pack Chat scope` sub-section (created in commit `667d2dd`) carries three orchestration-only rules — "Pack Chat does NO fixes" (PCS1), "Commit-approval requests include next-steps plan" (PCS2), "Pack-architect spawn protocol" (PCS3). All are about WHO performs which action. The first explicitly forbids Pack Chat from fixing review findings; the second mandates Pack Chat surface its planned next steps to the user; the third forbids Pack Chat from auto-spawning architect without user approval.
- ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §A.6 (archived) explicitly distinguishes the new `### Pack Chat scope` sub-section's content rule: "rules about WHO does work, not WHAT work."
- EXECUTION-PLAN §B (rewritten in commit `4760649`) names the actor for each step: "Pack Chat reports findings" (step 2), "Pack Chat surfaces the finding" (step 5), "Pack Chat must not pre-frame" (step 5). The rewrite shifted the rule's center of gravity from "what to do with audit findings" to "who decides what to do."
- PACK-CHAT.md "Stop after every reviewer pass for triage discussion" (lines 63-71, commit `7e4fdcc`): "Pack Chat STOPS, surfaces the findings (severity-grouped) to the user, and waits for triage approval — even if the reviewer verdict is fully clean." Names the actor, the gate, and the absoluteness.
- Trinity `### Agent invocation rules` (commit `667d2dd`): each new bullet (researcher-first pipeline, planner-output-to-user-review-before-coder-spawn, pack-coder PREFLIGHT) names the actor sequence and the gates.

**Where 19b enforces it.** Every 19b extension to trinity, PACK-CHAT.md, PACK-AGENTS.md, or EXECUTION-PLAN names the actor performing each step and (where applicable) the approver. The pattern is uniform across the batch.

### A.6 — User retains hard-stop authority on all state-changing operations (explicit)

**Statement.** The user can stop or redirect any planned state-changing action at any time, regardless of prior approval scope. Agents inherit this rule by construction; Pack Chat surfaces planned next-steps so the user can exercise the authority before work happens.

**Flag.** EXPLICIT.

**Evidence.**
- Trinity `### Workflow` "Per-action approval extends to sub-agents" bullet (CLAUDE.md `## Pack memory > ### Workflow`, e.g., `CLAUDE.md:134-143`): "The 'no state-changing operations without explicit per-action approval' rule applies to Claude Code Pack Chat AND every sub-agent it spawns. State-changing git verbs are forbidden to all agents per `PACK-AGENTS.md` § 'Agent permission rules'; destructive file operations (`rm -rf`, `git rm`, overwriting trusted files) require Pack Chat to ask the user even when the overall task is approved."
- Trinity `### Pack Chat scope` "Commit-approval requests include next-steps plan" bullet (PCS2): "Hard-stop authority (`feedback-no-destructive-without-approval`) attaches to the plan — the user can stop or redirect any planned step." Explicit anchor: the next-steps surfacing IS the user's window to exercise stop authority.
- `commit-discipline` skill section 3 ("Git-state-change ban (absolute)") forbids 14 state-changing git verbs for agents (`commit-discipline/SKILL.md:66-83`).
- Memory pointer `feedback_no_destructive_without_approval.md` (referenced from MEMORY.md): "any state-changing git verb (add/commit/push/mv/rm/tag/reset) or destructive file op requires explicit per-action approval; applies to Claude AND spawned sub-agents."

**Where 19b enforces it.**
- Commit `667d2dd` promoted the "Per-action approval extends to sub-agents" bullet into trinity (Workflow sub-section).
- Commit `667d2dd` created the `### Pack Chat scope` sub-section with the commit-approval-includes-next-steps-plan bullet that explicitly anchors hard-stop authority to each surfaced step.

### A.7 — Empirical anchoring: every rule names its incident (explicit / pattern)

**Statement.** New rules surface a worked example or incident from prior session work so the rule's necessity is provable and its future drift is recognizable. Rules without incident anchors are not codified.

**Flag.** EXPLICIT (per CONCEPTUAL-REVIEW-METHODOLOGY) and reinforced by the batch's own pattern.

**Evidence.**
- CONCEPTUAL-REVIEW-METHODOLOGY.md "Rat-hole limits" rule 5 (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:133`): "**Empirical anchoring required.** Every finding cites observable evidence (`file:line`, test failure, CI run, BACKLOG entry, prior commit). Reasoning-from-first-principles findings without evidence are not surfaced." Applies to review findings; the batch extends the same discipline to RULES.
- RC9 manifest-regen bullet (trinity `### Repo conventions`, e.g., `AGENTS.md:404-445`): names the 2026-05-17 incident, the recovery commit, the cumulative drift sources (3 commit SHAs), and the canonical fix. The bullet is roughly 40 lines of rule because the incident anchoring is part of the rule body.
- "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" trinity bullet names the worked-example anchor explicitly: "Worked-example anchor: `feedback-pack-coder-preflight-pattern` memory pointer; original incident BD-169 19g-pack, 2026-05-16."
- "Architect-doc-vs-reality reconciliation" bullet (trinity `### Repo conventions`): "Worked example: BD-119 §9.2 addendum in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` names BD-160 as the first realized consumer."
- "Filename uniqueness heuristic" bullet: "Worked example: BD-135 renamed the colliding `tracker.toml.example` pair."

**Pattern.** Every new trinity rule added in 19b carries an incident citation (or names a feedback memory file that carries one).

### A.8 — Mechanical-vs-structural change taxonomy (explicit)

**Statement.** Pack maintenance distinguishes "mechanical" change (pattern application, complete coverage, rule-strict) from "structural" change (rule changes, new dimensions, new conventions). Structural changes require architect-then-planner-then-coder; mechanical changes go straight to coder. The taxonomy gates the workflow.

**Flag.** EXPLICIT.

**Evidence.**
- Trinity `### Repo conventions` "Skill and agent maintenance is mechanical by default" bullet (e.g., `AGENTS.md:353-370`): "Maintenance is mechanical, complete, reviewed, and rule-strict. Structural change — including rule changes — requires architect-then-planner, never convenience. Mechanical changes preserve client `x-` skills/agents conforming to existing dimensions; breaking the `x-` contract escalates to structural and requires architect-pass migrator coverage."
- PACK-CHAT.md "No commit-staging beyond mechanical-edit threshold without architect justification" bullet (`PACK-CHAT.md:162-169`): "Pack Chat does not stage commits for batches whose footprint exceeds the mechanical-edit threshold ... without an architect-pass justification recorded in the BD."
- PACK-AGENTS.md "Skill and agent maintenance" bullet (`PACK-AGENTS.md:212-217`): same rule with threshold pointer.
- Trinity `### Pack Chat scope` "Pack-architect spawn protocol" bullet (PCS3): structural / rules-touching work requires architect-first; the architect-spawn itself requires user approval; mechanical work does not.

**Where 19b enforces it.** Batch 19b is itself a mechanical-by-default batch (rule consolidation; trinity restructure; cross-reference additions). The architect was spawned because the work touched rules (trinity `## Pack memory`), which is by definition structural per the rule above. The batch then applied mechanically via planner → coder.

### A.9 — "Deferral is scope creep" inverts the default (explicit)

**Statement.** The default for unblocked work is FIX-NOW in the current session. Deferring requires rigorous justification (size / blocked / fit) AND user-discussion-and-approval. Deferral is not a neutral scheduling decision — it is tech debt and scope creep.

**Flag.** EXPLICIT.

**Evidence.**
- Trinity `### Workflow` "Deferral IS scope creep" bullet (e.g., `AGENTS.md:158-170`): "Deferring unblocked work to a later BD or batch is tech debt and scope creep. Punted items lose context, multiply, require archaeology in future sessions."
- Trinity `### Workflow` "No deferral to v11.1+ without explicit user direction" bullet: "While v11.0 is unlaunched, ALL work surfaced during v11.0 development MUST land in v11.0 unless the user explicitly authorizes deferral."
- EXECUTION-PLAN §B step 5 (rewritten in commit `4760649`, `EXECUTION-PLAN-V11.0.md:352-362`): "New-BD-opens require user-discussion-and-approval. When a review/audit finding might warrant a new BD, Pack Chat surfaces the finding AND its candidacy for a new BD to the user — but does NOT open the BD. ... Pack Chat must not pre-frame 'should we open a BD?' as a default choice — the default remains fix-now."
- Trinity `### Workflow` "Triage all reviewer findings; default fix-all" bullet: "The default for all severities is FIX. NITs that are deferred ... become tracked tech debt — never 'noted in the report and dropped.'"

**Where 19b enforces it.** Commits `667d2dd` and `4760649` collectively codify this principle across trinity (Workflow + Pack Chat scope sub-sections) AND EXECUTION-PLAN §B. The batch is explicit about the rule's strategic shape: defaults invert when the cost of carrying a deferral exceeds the cost of fixing now.

### A.10 — Pack ops / pack product separation as a structural firewall (explicit)

**Statement.** The pack's own operational files (`PACK-CHAT.md`, `PACK-AGENTS.md`, trinity at pack root, `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `maintenance-docs/`) are NEVER mixed into files the pack ships to client projects (`project-template/`, `supporting-docs/`). The boundary is structural, not stylistic — agents and Pack Chat both enforce it.

**Flag.** EXPLICIT.

**Evidence.**
- Trinity `### Repo conventions` "Separate pack ops from pack product" bullet (e.g., `AGENTS.md:345-348`): "Pack ops files ... are NEVER mixed into pack product files (`project-template/`, `supporting-docs/`). Same applies in reverse."
- PACK-CHAT.md "Separation of pack operations and pack product" bullet (`PACK-CHAT.md:137-144`): explicit boundary rule with examples ("do not add product file references to operational key-file lists, do not add pack-maintenance workflows to project methodology").
- Tier-1.5 memory pointer `feedback_ops_product_separation.md` (referenced from MEMORY.md).
- RC9 manifest-regen bullet defines v11-surface narrowly as "files under `project-template/` or `scripts/`" — pack ops at pack root and `maintenance-docs/` are explicitly NOT v11-surface and trigger no manifest regen. The boundary is enforced at the CI gate.

**Where 19b enforces it.** Every 19b commit message includes a "Manifest regen for this commit: NOT NEEDED" footer (e.g., commit `7e4fdcc`, `3558525`, `4760649`, `aaa61b3`, `efd9a32`) with explicit justification per RC9 ("PACK-CHAT.md is at pack-root, not v11-surface"). The pattern operationalizes the separation as a binary check.

---

## §B — Project-side strategic rules

Each rule names the strategic principle, gives a one-sentence statement, lists evidence, and flags `EXPLICIT` or `IMPLICIT`. Sources are `project-template/` + `supporting-docs/` + OT counterparts (`/Users/david/Developer/OptiquityTrader`, READ-ONLY).

### B.1 — METHODOLOGY.md is the single source of truth for project methodology (explicit)

**Statement.** One copy of `METHODOLOGY.md` lives at `supporting-docs/METHODOLOGY.md` in the pack and is copied to each project's `docs/pack/METHODOLOGY.md` at install. Projects do NOT edit the pack's copy for project-specific needs; they edit the project copy.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:11-17` callout: "**Single source of truth:** One copy of this file lives at `supporting-docs/METHODOLOGY.md` in the AI Agent Config Pack. Copy it to your project root during setup ... Do not modify the pack's copy for project-specific needs — edit the project root copy instead and let it evolve with the project."
- OT instance present at `/Users/david/Developer/OptiquityTrader/docs/pack/METHODOLOGY.md` with byte-identical front matter ("Version: 2.1 (v10.0, April 2026)") — confirms the per-project copy pattern.
- PM-CHAT.md File access strategy table (`project-template/docs/pack/PM-CHAT.md:127`): METHODOLOGY.md accessed via "RAG query (Claude CLI) or direct read (other tools)" with comment "Large, stable" — confirms the doc is treated as a stable reference, not a working file.

### B.2 — Project trinity carries project-scope universal collaboration rules; agent definitions carry agent-scope rules (explicit)

**Statement.** Project root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Project memory` carries universal collaboration rules that apply project-wide regardless of agent role. Each agent's full operating rules (permission profile, output policy, hard rules) live in the agent's own definition file (`.claude/agents/<agent>.md`, etc.). The agent file is authoritative for what that agent may and must do; project memory is the universal layer.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/CLAUDE.md:343-352` `## Project memory`: "These rules govern every agent invocation in this project. Each agent's full operating rules (Permission profile, Output policy, Hard rules) live in its own definition file under `.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, and `.gemini/agents/<agent>.md`. The agent file is authoritative for what that agent may and must do; this section carries only the universal collaboration rules that apply project-wide regardless of agent role."
- Parallel byte-identical text at `project-template/AGENTS.md:320-329` and (paraphrased) `project-template/GEMINI.md:338-345`.
- Parallel byte-identical wording in OT trinity (`/Users/david/Developer/OptiquityTrader/CLAUDE.md:340-349` and `/Users/david/Developer/OptiquityTrader/AGENTS.md:325-334`).
- PM-CHAT.md "Permission profiles" section (`project-template/docs/pack/PM-CHAT.md:266-303`): explicitly defers to the agent file as authoritative — "The agent file is authoritative; this section is the PM-chat-facing reinforcement. When constructing a prompt, your job is to align with what the agent's file already says, not to restate or override it."

### B.3 — Trinity-first cross-CLI parity (explicit)

**Statement.** Project root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` express the same project rules; symmetry is the default; asymmetry requires justification as provably tool-specific.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/CLAUDE.md:354-357` `## Project memory` first bullet: "**Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` at the project root, the same change applies to all three in the same set of edits. Symmetry is the default; asymmetry requires justification as provably tool-specific."
- Parallel text at `project-template/AGENTS.md:331-334` and `project-template/GEMINI.md:347-349`.
- Project-template GEMINI.md exhibits one acknowledged asymmetry: an extra `## Agent roster` section (lines 400-420) for Gemini's filesystem-scan presentation aid, with an HTML comment flagging the exception: "Trinity-rule exception: this `## Agent roster` section is present in GEMINI.md only. Gemini CLI auto-discovers agents via filesystem scan ... CLAUDE.md and AGENTS.md rely on the phase-routing table above and tool-side discovery."
- OT trinity preserves the same rule and the same Trinity-rule-exception note (`/Users/david/Developer/OptiquityTrader/CLAUDE.md:351-354`).

### B.4 — Plan-then-execute, never execute-then-plan (explicit)

**Statement.** For any change beyond reading files, the PM chat (or any acting agent for non-trivial work) presents a plan describing what will change and why, then waits for explicit approval before doing anything. Receiving a task description is not approval.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:66-70` Part 1 PM chat description: "**Plan before executing — no exceptions.** For any change beyond a trivial doc edit, the PM chat must present a plan describing what will change and why, then wait for explicit user approval before executing anything. This applies to code files, documentation files, shell scripts, config files, and any other project files. Receiving a task description is not approval. Approval must be explicit."
- `project-template/docs/pack/PM-CHAT.md:180-181` Behavioral rules: "**Plan before executing.** For any change beyond reading files, present a plan and wait for explicit approval before doing anything."
- `project-template/CLAUDE.md:413` Agent behavior: "Plan first for non-trivial work."

### B.5 — No-solutions-in-prompts (the prompt describes problem / goal / success-criteria, not how) (explicit)

**Statement.** Every PM-authored agent prompt contains only Problem / Goal / Success criteria. No proposed solutions, no "pick one" options, no biased framing. Pseudocode, framework choices, and step-by-step "how-to" instructions are forbidden. The agent chooses how.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:623-654` "The core rule: describe the problem, goal, and success criteria — not the solution": full prose principle with per-agent enforcement table at lines 731-741.
- `supporting-docs/METHODOLOGY.md:71-76` Part 1 PM chat description: "**Never bias architect agents with proposed solutions.** When routing a problem to an architect agent, describe the constraint or design problem only — do not propose a solution."
- `project-template/docs/pack/PM-CHAT.md:182-187` Behavioral rules: "**No solutions in agent prompts.** Agent prompts contain only problem, goal, and success criteria. No proposed solutions, no 'pick one' options, no biased framing — for *any* agent."
- `supporting-docs/METHODOLOGY.md:861-880` PM chat self-check before generating any prompt — explicit pre-flight checklist embedding the rule.

### B.6 — Document hygiene as inviolable rules (explicit)

**Statement.** ARCHITECTURE.md and IMPLEMENTATION-PLAN.md are source of truth. CHANGELOG.md is append-only. BACKLOG.md items are never deleted. STATUS.md is updated after every phase. Agents must not modify ARCHITECTURE.md or IMPLEMENTATION-PLAN.md unless explicitly instructed; BACKLOG / CHANGELOG / STATUS / PACK-FEEDBACK and all other root .md files are exclusively the PM chat's responsibility.

**Flag.** EXPLICIT — named as "inviolable" in METHODOLOGY.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:122-138` `### Document hygiene rules (inviolable)` — six numbered rules.
- `project-template/CLAUDE.md:312-326` `## Deferral comments and BACKLOG hygiene` carries the agent-facing enforcement: "Do not write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, or any other `.md` file in the project root — these are exclusively the PM chat's responsibility."
- `supporting-docs/METHODOLOGY.md:1384-1394` Part 9 "Document Authoring Rules" table makes the same rule actor-explicit (Coder/Reviewer/PM chat columns).

### B.7 — Typed deferral comments and the TD-TBD sentinel (explicit)

**Statement.** Three typed comment formats are recognized for deferring work (`TODO(scope)`, `KNOWN GAP(severity)`, `VERIFY(source)`). All others are invalid. The coder always writes `TD-TBD` — never a real TD number — and reports each deferral in the completion report; the PM chat assigns the real number after user approval. Any `TD-TBD` in committed code is a defect.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:1003-1039` Part 7 "Comment format": full enumeration with valid scope / severity / source values and the TD-TBD sentinel rule.
- `project-template/CLAUDE.md:295-326` `## Deferral comments and BACKLOG hygiene`: per-project enforcement of the typed format including the explicit prohibition on plain-English deferrals ("Never use plain English deferral comments (`// Fix later`, `// Confirm this`, etc.). Use the typed format above or do not leave a comment.").
- OT preserves the same typed-deferral rule at `/Users/david/Developer/OptiquityTrader/CLAUDE.md:268-299`.
- Pack-side trinity bullet "Pack-repo code-comment deferrals" (`AGENTS.md:371-381`) explicitly cross-references the project-template typed format as canonical: "Cross-reference: the project-template section is canonical for the typed format; the pack-repo follows the same convention so pack-coder behavior is consistent across pack-repo and client-repo contexts."

### B.8 — Reviewer must be source-truth-independent of prior reviewer reports (explicit)

**Statement.** Reviewer prompts cite ARCHITECTURE / IMPLEMENTATION-PLAN docs only — never prior reviewer reports. A reviewer that reads prior reviews inherits their framings and produces confirmatory rather than independent output.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/docs/pack/PM-CHAT.md:248-252` Behavioral rules: "**No prior reviews to reviewer.** Reviewer prompts cite ARCHITECTURE / IMPLEMENTATION-PLAN docs only — never prior reviewer reports."
- Tier-1.5 memory `feedback_no_prior_reviews_to_reviewer.md` is the pack-side parallel, with the same rule and the bias-avoidance rationale.

### B.9 — Tool-equivalence as design intent (explicit)

**Statement.** All three CLI tools (Claude Code, Codex CLI, Gemini CLI) can execute any phase. The phase-routing tables identify the BETTER tool for each phase as a default, not the only tool. Overrides are permitted when task characteristics favor a different tool.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/CLAUDE.md:372-373` Phase routing intro: "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase. The defaults below identify the better system for each phase. Override when task characteristics favor a different tool."
- `project-template/CLAUDE.md:37-41` Capability policy: "Claude may perform all major engineering tasks in this repository: ... All are allowed. No task category is reserved exclusively for another tool. Default preference only."
- Parallel routing-table intros in `project-template/AGENTS.md:349-352` and `project-template/GEMINI.md:362-365`.
- OT preserves the rule and adds a project-specific override layer in a project-owned region (`/Users/david/Developer/OptiquityTrader/CLAUDE.md:391-394`).
- `supporting-docs/METHODOLOGY.md:7-9` Applicability note: "This document is platform-agnostic and applies to all project types (Apple, Python server, monorepo) and all three CLI tools (Claude Code, Codex, Gemini)."

### B.10 — `x-` prefix as the structural firewall for project-supplied vs pack-supplied files (explicit)

**Statement.** In pack-controlled directories that may legitimately host both pack-roster files and project-added files, the `x-` prefix marks project-added. Pack-supplied files never begin with `x-`. Pack scripts skip `x-*` when deleting or overwriting; pack-roster filenames will never collide with `x-*` in future releases.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/INSTALL-PROCEDURES.md:29-80` `## Project file conventions in pack-controlled directories`: full convention with the locations table and three explicit guarantees (deletion skips `x-*`, overwrites skip `x-*`, pack-roster filenames never start with `x-`).
- `project-template/CLAUDE.md:201-206` Skill loading: "Project-specific (custom) skills use the `x-` prefix and live alongside pack skills in `.claude/skills/x-<name>/`, `.codex/skills/x-<name>/`, and `.gemini/skills/x-<name>/`. Pack-supplied skills never begin with `x-`."
- `project-template/docs/pack/PM-CHAT.md:228-234` Behavioral rules "Custom files via Procedure 5 only" with explicit `x-` prefix requirement.
- `project-template/docs/pack/PM-CHAT.md:355-357` Reservation: "The `x-` prefix is reserved for custom agents, skills, and prompt files. The pack ships zero files beginning with `x-`; any `x-*` file in the project directories is custom."

### B.11 — Detection-scan-at-every-startup-and-phase-gate (explicit)

**Statement.** The PM chat scans seven detection directories at every startup and every phase gate and classifies every file as (a) pack-supplied, (b) registered custom (`x-` prefix), or (c) improperly-added. Improperly-added files are flagged for Procedure 5.4 adoption.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/docs/pack/PM-CHAT.md:235-241` Behavioral rules "Detection scan at every startup and every phase gate."
- `project-template/docs/pack/PM-CHAT.md:347-353` `## Custom agent and skill workflow > Detection and classification`: full classification rule.
- `supporting-docs/METHODOLOGY.md:1076-1120` Procedure 1 "Phase gate check" enumerates the scan as part of step 6 (skill gap check) with cross-reference to Procedure 5.5 detection scan in INSTALL-PROCEDURES.md.

### B.12 — Pack feedback loop: PM chat observes, records, delivers at workflow boundaries (explicit)

**Statement.** The PM chat is the only entity that observes the pack running on real production work. It owns `PACK-FEEDBACK.md` (append-only), logs observations continuously, and delivers feedback batches to the Pack Chat only at workflow-complete boundaries (never mid-phase) unless an emergency escalation fires. Record observations, not solutions.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:1417-1461` Part 10 "Pack Feedback Loop" — full operational rule with cadence ("Default: deliver feedback batches at workflow-complete boundaries only"), scope ("Record observations, not solutions — the Pack Chat decides what to do with them"), and ownership ("PM-chat-owned, append-only. Agents never write to it.").
- `project-template/docs/pack/PM-CHAT.md:221-227` Behavioral rules "Pack feedback loop" — short-form restatement.
- `project-template/CLAUDE.md:316-320` and OT counterpart name the agent-side prohibition: "Never write to `PACK-FEEDBACK.md` under any circumstance — it is the PM chat's upstream feedback log for the AI Agent Config Pack itself."

### B.13 — File-based reporting: every agent prompt names a report file (explicit)

**Statement.** Every agent prompt must include a `REPORT FILE: <path>` line. The agent's primary deliverable is the markdown report at that path; it is not inline text in the agent's reply. PM-chat self-prompts that edit a target file satisfy the rule by naming the target file.

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:787-808` Prompt Authoring Principles "File-based reporting" subsection — two sub-cases (A: agent produces report; B: PM-chat self-prompt edits target file) and the absoluteness ("A prompt that asks an agent to 'output the report' or 'return the result to the developer' without naming a file is a defect.").
- `project-template/docs/pack/PM-CHAT.md:242-247` Behavioral rules "Agent report file": "Every agent prompt must include a `REPORT FILE: <path>` line. The agent's primary deliverable is the markdown report at that path; it is not inline text in the agent's reply."
- Per-profile reinforcement in `project-template/docs/pack/PM-CHAT.md:304-336` (Read-only / Write-capable / Write-capable script profile prompt requirements all list REPORT FILE as the first requirement).
- `project-template/.claude/agents/coder.md:40-68` `## Output policy` enforces the rule from the agent side: "When the calling prompt specifies a `REPORT FILE:` path, your final action MUST be a Write (or chunked Edit sequence) at that exact path."

### B.14 — Agent-file-is-authoritative; PM-chat-facing reinforcement is a mirror (explicit)

**Statement.** For each agent, the agent definition file is the authoritative source for the agent's full operating rules (permission profile, output policy, hard rules). PM-CHAT.md's per-profile guidance tells the PM chat what to put INTO the prompt to align with what the agent already enforces — it is the PM-chat-facing mirror of the agent's own rules, not a duplicate authority.

**Flag.** EXPLICIT.

**Evidence.**
- `project-template/docs/pack/PM-CHAT.md:266-278` `## Permission profiles` intro: "The agent's own definition file (`.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, `.gemini/agents/<agent>.md`) is the authoritative source for the agent's full operating rules. The table and per-profile guidance below tell the PM chat what to put **into** the prompt to align with what the agent already enforces — they are the PM-chat-facing mirror of the agent's own rules. **The agent file is authoritative; this section is the PM-chat-facing reinforcement. When constructing a prompt, your job is to align with what the agent's file already says, not to restate or override it.**"
- Parallel rule in `project-template/CLAUDE.md:345-352` `## Project memory` intro: "Each agent's full operating rules (Permission profile, Output policy, Hard rules) live in its own definition file under `.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, and `.gemini/agents/<agent>.md`. The agent file is authoritative for what that agent may and must do."

### B.15 — RAG manifest hygiene: orphans are not benign (explicit)

**Statement.** The PM chat's local-rag index (`mcp-local-rag`) is reconciled against an explicit per-project RAG ingestion manifest on every startup. Orphans (in index but not in manifest) are auto-deleted, since orphans mislead retrievals with stale chunks — "worse than no RAG at all, because the failure mode is invisible."

**Flag.** EXPLICIT.

**Evidence.**
- `supporting-docs/METHODOLOGY.md:140-185` `### RAG index hygiene`: full rule including the explicit principle ("**Orphans are not benign.** A retired-path chunk that lingers in the index is returned by future queries and cited as if it were current content. The PM chat receives confidently-wrong retrievals — stale guidance, dead paths, removed file references — with no signal that the source is gone. This is worse than no RAG at all, because the failure mode is invisible.").
- `project-template/docs/pack/PM-CHAT.md:135-173` `### RAG ingestion manifest`: the per-project manifest declaration with discriminator rule (access-method column) for what joins the manifest.
- OT counterpart at `/Users/david/Developer/OptiquityTrader/docs/pack/PM-CHAT.md:108-145` preserves the same rule.

### B.16 — Conditional pack files removed/preserved per project shape (implicit)

**Statement.** Files in the pack template carry `[CONDITIONAL]` markers (e.g., `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features`, `## [CONDITIONAL] gRPC and Proto3 rules`); the init script and migrator remove sections that don't apply to the detected project shape, fill in `[PLATFORM_DEFAULTS]` / `[LANGUAGE_RULES]` / `[GRPC_RULES]` / `[PLATFORM_SECURITY]` / `[PLATFORM_TESTING]` / `[PLATFORM_ANTIPATTERNS]` placeholders from loaded skills, and preserve project-owned regions across version bumps.

**Flag.** IMPLICIT — the convention is named (CONDITIONAL marker, BEGIN project-owned / END project-owned markers) but the underlying principle ("the pack ships a superset; per-project material lives in marked regions; init/migration normalize") is not surfaced as a single named principle anywhere read.

**Evidence.**
- `project-template/CLAUDE.md:55-95` carries multiple `## [CONDITIONAL]` H2 sections (iOS 26, Architecture rules — platform-specific, Language-specific coding rules, gRPC and Proto3 rules) with explicit fill-in or remove instructions.
- `project-template/CLAUDE.md:421-426` `## Project addenda` HTML comment names the migration reconciliation workflow: "Project-original H2 sections that don't fit into pack-defined sections above land under this heading after a v9.3 → v10 migration. See docs/pack/INSTALL-PROCEDURES.md Procedure 5-C.2 step 2.b."
- OT `CLAUDE.md` shows the realized form: `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` markers wrap project-specific blocks, with one section explicitly noting a v9.3 → v10 rename ("renamed-from" comment at OT `CLAUDE.md:45`).
- `project-template/docs/pack/PM-CHAT.md:763-786` `## Additional project documents` is wrapped in `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` markers with the same migration-classifier preservation behavior.
- `supporting-docs/INSTALL-PROCEDURES.md:53-66` what-the-convention-guarantees list applies the same principle to `x-*` files in pack-controlled directories.

---

## §C — Overlaps between §A and §B

Each overlap names the strategic rule, gives the pack-side surface (§A reference) and project-side surface (§B reference), and flags WORDING-MATCHES, WORDING-DIVERGES (substantively equivalent but text differs), or SAME-RULE-NEW-SCOPE (the principle exists on both sides but governs different file sets).

### C.1 — Single source of truth (A.1 ↔ B.1)

- **Pack-side surface:** Trinity files at pack root are the single source of truth for pack rules; mirror surfaces (Tier-1.5 memory cache, regenerated `BACKLOG.md` / `CHANGELOG.md` mirrors) point at trinity and lose on disagreement. Explicit "Single source of truth" principle in `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:211`.
- **Project-side surface:** `METHODOLOGY.md` is the single source of truth for project methodology (one canonical copy at pack `supporting-docs/`; copied to project `docs/pack/` at install; do not edit the pack copy). Explicit "Single source of truth" callout in `supporting-docs/METHODOLOGY.md:11-17`.
- **Flag.** SAME-RULE-NEW-SCOPE. Both surfaces name the same principle but apply it to different file sets (trinity for pack-side rules; METHODOLOGY for project-side methodology). The principle is stated explicitly in both places and named the same way in the conceptual-review methodology.

### C.2 — Trinity-first cross-CLI parity (A.2 ↔ B.3)

- **Pack-side surface:** Pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` Trinity rule (`CLAUDE.md:76-86`) with 19b enforcement classifying bullets as UNIVERSAL / TOOL-SPECIFIC / TOOL-ONLY.
- **Project-side surface:** Project-template `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Project memory` "Trinity rule" bullet (`project-template/CLAUDE.md:354-357` and parallels), with the acknowledged GEMINI.md-only Agent roster exception.
- **Flag.** WORDING-MATCHES (core rule). The pack-side rule explicitly says "This rule also applies to the pack-repo copies of these three files" (`CLAUDE.md:84-86`) so the project-side rule is the original and the pack-side rule is the cross-application. The 19b classification taxonomy (UNIVERSAL / TOOL-SPECIFIC / CLAUDE-ONLY) is pack-side and is not mirrored verbatim to project-side text — but the SAME-RULE substantive equivalence holds.

### C.3 — Roles as orchestration boundaries / Plan-then-execute (A.5 ↔ B.4)

- **Pack-side surface:** Trinity `### Pack Chat scope` sub-section (commit `667d2dd`) carries WHO-does-WHAT-rules. PACK-CHAT.md "Plan before executing" (line 56-60). EXECUTION-PLAN §A.1 (`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:325`).
- **Project-side surface:** METHODOLOGY.md Part 1 PM chat description (`supporting-docs/METHODOLOGY.md:66-70`) "Plan before executing — no exceptions." PM-CHAT.md "Plan before executing" (line 180-181). `project-template/CLAUDE.md:413` Agent behavior "Plan first for non-trivial work."
- **Flag.** SAME-RULE-NEW-SCOPE. Both sides treat plan-then-execute as a universal collaboration rule. The pack-side version adds an explicit Pack-Chat-orchestration-boundaries layer (the new `### Pack Chat scope` sub-section) that does not have a project-side parallel — the project-side rule applies more diffusely across PM-chat and agent files.

### C.4 — No-solutions-in-prompts (implicit pack-side ↔ B.5 explicit project-side)

- **Pack-side surface:** Trinity `### Agent invocation rules` "No solutions in agent prompts" bullet (e.g., `AGENTS.md:208-211`): "Agent prompts contain only problem, goal, and success criteria. No proposed solutions, no 'pick one' options, no biased framing." Memory pointer `feedback_no_solutions_in_agent_prompts.md`.
- **Project-side surface:** METHODOLOGY.md "Prompt Authoring Principles" → "The core rule: describe the problem, goal, and success criteria — not the solution" (`supporting-docs/METHODOLOGY.md:623-654`) plus PM-CHAT.md Behavioral rules (`project-template/docs/pack/PM-CHAT.md:182-187`).
- **Flag.** WORDING-MATCHES (substantively). The pack-side trinity bullet states the rule as ≈3 lines; the project-side METHODOLOGY treatment is the full prose principle with worked examples and per-agent enforcement table. The text differs but the rule is the same. The project-side is the more developed surface (more enforcement detail); the pack-side is the more concise mirror for in-pack agent work.

### C.5 — Agent-file-is-authoritative (implicit pack-side ↔ B.14 explicit project-side)

- **Pack-side surface:** PACK-AGENTS.md `## Agent permission rules` (`PACK-AGENTS.md:109-217`) carries the agent permissions table and the "Source modifications are restricted by agent role" rule. Each pack agent's definition file (`.claude/agents/pack-*.md`, `.codex/agents/pack-*.toml`, `.gemini/agents/pack-*.md`) is the agent-specific authority. The pack-side does NOT carry an explicit "agent file is authoritative" statement at the same prominence as the project-side B.14 rule.
- **Project-side surface:** `project-template/CLAUDE.md:343-352` `## Project memory` intro AND `project-template/docs/pack/PM-CHAT.md:266-278` `## Permission profiles` intro both name "The agent file is authoritative" as a standing rule.
- **Flag.** WORDING-DIVERGES. The substantive structure (agent file = authoritative; project memory / PM-CHAT.md = universal mirror) is the same on both sides, but the project-side version names the principle explicitly and the pack-side version implements it without a named anchor. (The pack-side closest equivalent is the §A.2 trinity-first rule, which is a different scoping.)

### C.6 — User retains hard-stop authority (A.6 ↔ implicit project-side)

- **Pack-side surface:** Trinity `### Workflow` "Per-action approval extends to sub-agents" bullet; Trinity `### Pack Chat scope` "Commit-approval requests include next-steps plan" bullet (PCS2) explicitly anchors hard-stop to surfaced next steps. Memory pointer `feedback_no_destructive_without_approval.md`.
- **Project-side surface:** `project-template/CLAUDE.md:358-362` `## Project memory` "No destructive operations without explicit approval" bullet (and parallels in AGENTS.md / GEMINI.md). OT preserves the rule at `/Users/david/Developer/OptiquityTrader/CLAUDE.md:355-358`.
- **Flag.** WORDING-DIVERGES. The substantive rule is the same — both sides require explicit per-action approval for destructive operations. The pack-side adds two extensions absent from the project-side text: (a) explicit extension to sub-agents ("applies to Claude AND spawned sub-agents"), (b) the "commit-approval requests include next-steps plan" enforcement mechanism that ties hard-stop to a visible surfacing of the next planned step. The project-side carries only the bare destructive-op rule.

### C.7 — File-based reporting (implicit pack-side ↔ B.13 explicit project-side)

- **Pack-side surface:** Pack agent prompt rule (Trinity `### Agent invocation rules` "Agent prompt requirements" bullet, e.g., `AGENTS.md:203-207`): "Every agent prompt must include: context ... output file path, read-only flags where applicable, markdown-only directive for outputs, problem / goal / success criteria, and an instruction to chunk Write calls for outputs over ~300 lines." PACK-AGENTS.md "Every agent produces a report file" (`PACK-AGENTS.md:130-133`).
- **Project-side surface:** METHODOLOGY.md "File-based reporting" (`supporting-docs/METHODOLOGY.md:787-808`) with two sub-cases and the absoluteness clause. PM-CHAT.md "Agent report file" (`project-template/docs/pack/PM-CHAT.md:242-247`). Per-profile reinforcement in PM-CHAT.md (lines 304-336). Agent-file enforcement at `project-template/.claude/agents/coder.md:60-64`.
- **Flag.** WORDING-MATCHES (substantively). Both sides require a named report file in every agent prompt. The project-side adds explicit sub-case structure (A: agent report; B: PM-chat self-prompt naming target file) and an explicit "defect" classification for prompts that violate the rule. The pack-side states the requirement in line with the other prompt-content rules but does not carry the sub-case taxonomy.

### C.8 — Trinity rule applies to pack-root AND project-template (A.2 ↔ B.3 explicit overlap)

- **Pack-side surface:** Pack-root `CLAUDE.md:84-86` says: "This rule also applies to the pack-repo copies of these three files." (Where the "rule" is the Trinity rule established for `project-template/CLAUDE.md` / `project-template/AGENTS.md` / `project-template/GEMINI.md`.)
- **Project-side surface:** `project-template/CLAUDE.md:80-86` (and AGENTS.md / GEMINI.md parallels) state the Trinity rule for the project-template files: "When modifying `project-template/CLAUDE.md`, always make the parallel edit in `project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit."
- **Flag.** WORDING-MATCHES. This is a single cross-surface rule expressed as one origin (project-template trinity) plus a cross-application bullet (the pack-root rule applies the project-template rule to itself). No conflict; the rule is intentionally shared.

### C.9 — `x-` prefix as structural firewall (implicit pack-side ↔ B.10 explicit project-side)

- **Pack-side surface:** Trinity `### Repo conventions` "Skill and agent maintenance is mechanical by default" (`AGENTS.md:353-370`): "Mechanical changes preserve client `x-` skills/agents conforming to existing dimensions; breaking the `x-` contract escalates to structural and requires architect-pass migrator coverage."
- **Project-side surface:** `supporting-docs/INSTALL-PROCEDURES.md:29-80` `## Project file conventions in pack-controlled directories` full rule with locations table and three explicit guarantees. `project-template/CLAUDE.md:201-206` Skill loading. PM-CHAT.md "Custom files via Procedure 5 only" and "Reservation" rules.
- **Flag.** SAME-RULE-NEW-SCOPE. Project-side is the canonical statement of the `x-` convention; pack-side cross-references it as the contract pack-scripts must preserve. The principle (project-supplied vs pack-supplied files distinguished by prefix; pack scripts skip `x-*`) is consistent on both sides.

### C.10 — Plan / coder / reviewer agent-vs-PM-chat scope (A.5 ↔ B.2 / B.4)

- **Pack-side surface:** Trinity `### Workflow` "Pack Chat does not architect" bullet (e.g., `AGENTS.md:118-121`): "Architecture, planning, implementation, and review work goes to `pack-architect` / `pack-planner` / `pack-coder` / `pack-reviewer` directly."
- **Project-side surface:** `project-template/CLAUDE.md:362-368` `## Project memory` "PM chat does not architect" bullet. OT preserves the rule at `/Users/david/Developer/OptiquityTrader/CLAUDE.md:359-364`.
- **Flag.** WORDING-MATCHES. Same rule expressed in parallel: PM chat does NOT architect; architect/planner/coder/reviewer agents do. The pack-side version is the longer-developed surface (with the §A.5 orchestration boundaries elaborated through trinity `### Pack Chat scope`); the project-side version is the universal collaboration-rule layer.

---

## §D — Conflicts found anywhere in scope

Each conflict names the issue, cites both sides, and characterizes the contradiction. NO REDESIGN — identification only. Conflicts may be intra-pack-side, intra-project-side, or cross.

### D.1 — Trinity "One review/fix cycle per batch" bullet contradicts EXECUTION-PLAN §B step 5 (intra-pack-side)

**Citation A.** Pack-root trinity `### Workflow` "One review/fix cycle per batch" bullet (e.g., `AGENTS.md:122-126`):

> "Run `pack-reviewer` once per batch, fix once, move on. Do not propose a second review pass; the final audit is user-initiated. Fixes land in the current session. New-BD-opens follow the OQ-1 rule per EXECUTION-PLAN §B step 5 + W8 'Deferral IS scope creep' (size/blocked/fit + user-discussion-and-approval)."

**Citation B.** Trinity `### Workflow` "Per-BD review/fix runs INLINE, before next BD's coder spawns" bullet (e.g., `AGENTS.md:171-177`):

> "Multi-BD batches: each BD's review/fix runs inline (coder → reviewer → triage → fix-coder → commit → NEXT BD's coder). End-of-batch reviewer runs once on the full batch after all per-BD cycles complete."

**Nature of contradiction.** The two bullets coexist in the same `### Workflow` sub-section and describe different review cadences for the same review/fix flow. The first bullet says "Run pack-reviewer ONCE per batch"; the second bullet says "each BD's review/fix runs INLINE" AND "End-of-batch reviewer runs ONCE on the full batch after all per-BD cycles complete" — i.e., a per-BD reviewer pass AND a separate end-of-batch reviewer pass, which is more than once for multi-BD batches. The broad reviewer's N2 finding (`maintenance-docs/archive/v11/PACK-REVIEW-CLEANUP-BATCH-19B-broad.md` §2 N2, lines 50) flagged the same drift in the "Fixes land in the current session — never as a new BD" obsolete sentence of the same bullet, which the 30a1bc3 broad-fix commit fixed. The "once per batch" wording remained.

### D.2 — Trinity "Pack-coder PREFLIGHT" enforcement scope vs PACK-AGENTS.md cross-reference scope (intra-pack-side, minor)

**Citation A.** Trinity `### Agent invocation rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" bullet (e.g., `CLAUDE.md`-equivalent): the PREFLIGHT half is described as "platform-neutral, REQUIRED for all CLIs" — applies to every pack-coder spawn regardless of CLI.

**Citation B.** `PACK-AGENTS.md:189-210` "Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation" bullet:

> "Every pack-coder (or coder-style fix-coder) agent has two non-negotiable behavioral obligations: ... PREFLIGHT line BEFORE IMPL-REPORT. ..."

Then the cross-reference at lines 207-210:

> "Authoritative full text for both halves of the pattern (including cross-CLI scope notes for Codex / Gemini): trinity `## Pack memory` `### Agent invocation rules` 'Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern' bullet."

**Nature of (potential) contradiction.** Not a direct rule contradiction — both bullets state the obligation. The minor issue: PACK-AGENTS.md states the obligation as "every pack-coder agent" in absolute terms without per-CLI scoping inside the PACK-AGENTS.md text; the trinity bullet differentiates the STOP-MEANS-STOP enforcement (Claude-Code-only) from the PREFLIGHT content rule (platform-neutral). A reader who reads PACK-AGENTS.md alone might infer SendMessage-style enforcement applies to all CLIs. PACK-AGENTS.md anchors authority in the trinity bullet to resolve this — the cross-reference is the explicit dependency. So this is a "reader must follow the pointer to get the full rule" pattern, which the broad reviewer did not flag as a defect but is worth surfacing as a candidate site for clarification.

### D.3 — Trinity "What Pack Chat CAN edit directly" Codex/Gemini variant text vs no-Tier-1.5-for-Codex/Gemini rule (intra-pack-side, by-design divergence the broad reviewer flagged as a planner-classification mismatch)

**Citation A.** Trinity `### Pack Chat scope` "What Pack Chat CAN edit directly" sub-list. CLAUDE.md version (`CLAUDE.md` `## Pack memory > ### Pack Chat scope`) carries a memory-cache bullet: "Memory files (`~/.claude/projects/<slug>/memory/*.md`) — Pack Chat's own operating state, not pack work." AGENTS.md version (`AGENTS.md:281-296`) carries the parallel Codex-side text: "Per V2 §D, Codex has no pack-shipped per-project memory cache ... the pack does NOT ship a Codex memory file." GEMINI.md should carry the parallel Gemini-side text per the design.

**Citation B.** PACK-REVIEW-CLEANUP-BATCH-19B-broad.md §2 F1 finding (line 47, archived): planner classified the "Per-action approval extends to sub-agents" bullet as UNIVERSAL but actual implementation has a Claude-only memory-pointer trailer. The broad reviewer marked this as "DIVERGENT" against UNIVERSAL classification and flagged the trinity-parity audit at §3 line 69 as "DIVERGENT — see F1."

**Nature of (claimed) contradiction.** The broad reviewer flagged this as a planner-classification-vs-implementation cosmetic mismatch, not a substantive rule conflict. The actual rule (Per-action approval applies to Pack Chat AND sub-agents) is the same across all 3 trinity files. The "What Pack Chat CAN edit" sub-list legitimately diverges across CLIs because of the underlying §A.3 cross-CLI scope honesty principle (Codex/Gemini have no Tier-1.5 to edit, so the sub-list entry differs). So this is "intentional design under §A.3, but the planner's UNIVERSAL classification table did not anticipate it." Worth noting because it is a flagged divergence in the read scope, but the rule itself is internally consistent under the honesty principle.

### D.4 — Project-template AGENTS.md `## Project memory` "PM chat does not architect" omits `auditor` cross-reference text present in CLAUDE.md (intra-project-side, minor)

**Citation A.** `project-template/CLAUDE.md:362-368` "PM chat does not architect" bullet:

> "Architecture, planning, implementation, and review work goes to the corresponding agent (architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops) — `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster. The PM chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt construction — not the work the agents do."

**Citation B.** `project-template/AGENTS.md:339-345` "PM chat does not architect" bullet — same body, also names "auditor covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster."

**Citation C.** `project-template/GEMINI.md:354-358` "PM chat does not architect" bullet — body says "Architecture, planning, implementation, and review work goes to the corresponding agent (`auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster)." NO enumeration of agent names — only the parenthetical clarifier.

**Nature of contradiction.** The trinity bullet is supposed to be byte-identical across the three files per §B.3. CLAUDE.md and AGENTS.md carry the full agent enumeration ("architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops"); GEMINI.md drops the enumeration and only carries the parenthetical. Substantive rule is the same; trinity-parity wording diverges. Note: GEMINI.md asks readers to keep concise ("Keep this file concise" pattern referenced in archived ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §A.5), so the divergence may be intentional, but the trinity rule says "Symmetry is the default; asymmetry requires justification as provably tool-specific" — and "Gemini prefers conciseness" is a style preference, not a tool-specific capability difference. No `Trinity-rule exception:` comment is present at the divergent bullet to record the justification.

### D.5 — Project-template `## Project memory` does NOT reference `PACK-AGENTS.md` while GEMINI.md does (intra-project-side, minor)

**Citation A.** `project-template/CLAUDE.md:362-368` "PM chat does not architect" bullet names the agents but does NOT explicitly say "see PACK-AGENTS.md" — the auditor-cross-reference clause says "`auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster" but this is buried inside the agent enumeration.

**Citation B.** OT `CLAUDE.md:359-364` carries the rule WITHOUT the PACK-AGENTS.md reference: "Architecture, planning, implementation, and review work goes to the corresponding agent (architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops). The PM chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt construction — not the work the agents do." The "`auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster" cross-reference is absent. Same in OT `AGENTS.md:344-349`.

**Nature of contradiction.** Project-template trinity has been updated to include the PACK-AGENTS.md cross-reference; OT trinity (which was installed from a prior pack version, per "Version: 2.1 (v10.0, April 2026)" stamp at the top of OT METHODOLOGY.md) carries the older form without the cross-reference. This is drift across pack versions, not a rule conflict per se — but it surfaces the fact that the trinity rule (B.3) is enforced at modification time per the symmetry-is-default rule, but client projects installed at older versions carry older text until a migration runs. Worth noting as a structural conflict between "trinity rule = symmetry across 3 files" and "client projects installed at vN keep vN-version trinity until migrated to vN+1."

### D.6 — Project-template `## Project memory` agent list omits `PACK-AGENTS.md` filename presence vs OT `## Project memory` (intra-project-side / cross-version)

Same evidence as D.5. Cited separately because it is a different observable: in `project-template/`, the agent file enumeration includes a `PACK-AGENTS.md` cross-reference inside the bullet text; in OT, no PACK-AGENTS.md file exists at all (OT has only `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `docs/pack/METHODOLOGY.md` / `docs/pack/PM-CHAT.md` per the earlier find). The project-template trinity references a file (`PACK-AGENTS.md`) that does NOT ship to client projects per the file-access discovery in OT.

**Nature of contradiction.** If `PACK-AGENTS.md` cross-references in project-template trinity were intended to refer to a client-project file, that file is not present in OT (installed from prior pack version OR the file is not part of the v10 install set). If they were intended to refer to the pack-side `PACK-AGENTS.md`, the cross-reference is from client repo to pack repo and may not resolve. Worth surfacing as a forward-pointing-reference question that may or may not be a conflict depending on the intended target.

### D.7 — METHODOLOGY.md hierarchy of who-writes-BACKLOG vs `project-template/.claude/agents/coder.md` hard rules (intra-project-side, by-design but worth surfacing)

**Citation A.** `supporting-docs/METHODOLOGY.md:1318-1330` Part 7 "Agent BACKLOG write permissions" table:

> | `coder` | Write TD-TBD deferral comments in code; report deferred items in completion report | Write to BACKLOG.md; resolve or modify existing entries |

**Citation B.** `project-template/.claude/agents/coder.md:80-85` Hard rules:

> "**No PM-only file edits without explicit caller scoping.** Do not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, or any `.md` file at the project root unless the caller's prompt explicitly lists those files in 'Files in scope.'"

**Nature of (potential) contradiction.** METHODOLOGY.md says coder "May not" write to BACKLOG.md; coder agent file carves out an exception "unless the caller's prompt explicitly lists those files in 'Files in scope.'" The two are not strictly contradictory if METHODOLOGY's "May not" is read as the default and the agent file's exception is the carve-out. But the METHODOLOGY table is presented as the authoritative role-permission table without a "caller-scope exception" column. A reader who only reads METHODOLOGY would conclude coder can NEVER write BACKLOG.md; a reader who reads the agent file would conclude coder CAN write BACKLOG.md if scoped. Surface as a known divergence in the "what coders can do" rule between METHODOLOGY's table form and the agent file's explicit-caller-scope exception.

### D.8 — Pack-side "Pack Chat does NO fixes / no threshold exception" vs project-side METHODOLOGY's PM-chat-may-edit-deferral-comments carve-out (cross-side, terminology-divergence)

**Citation A.** Pack-side trinity `### Pack Chat scope` "Pack Chat does NO fixes" bullet (e.g., `AGENTS.md:269-279`):

> "Pack Chat's role in any review/fix cycle is exactly: spawn pack-reviewer (in background) → read review report → triage findings ... → spawn fix-coder (in background) ... Pack Chat does NOT use Edit / Write tools to apply review findings. NO threshold exception — there is no 'small enough to skip the coder' carve-out."

**Citation B.** Project-side METHODOLOGY.md Part 7 (`supporting-docs/METHODOLOGY.md:1328-1330`):

> "**PM chat comment edit carve-out:** The PM chat may edit source files solely to add, modify, or remove deferral comments (`// TODO(`, `// KNOWN GAP(`, `// VERIFY(`, and Python equivalents). This is the only permitted source file edit by the PM chat."

**Nature of contradiction.** Pack-side "Pack Chat does NO fixes" is absolute ("NO threshold exception"); project-side PM-CHAT has an explicit single carve-out for deferral comments. This is technically not a conflict because (a) Pack Chat operates on the pack repo; PM Chat operates on a client project; they are different actors in different repos with different rule sets, and (b) the pack-side rule's scope is "review/fix cycle" specifically (commit-discipline skill, agent-orchestration), while the project-side carve-out is "deferral comments specifically." But a reader looking at both rules in parallel could find the wording surface mismatched: pack-side says "NO threshold exception"; project-side has an exception. The two refer to different actors and different scopes, but the headline rules read as opposed when read without context. Worth surfacing as a rule-shape divergence even though the substantive scope distinguishes them.

### D.9 — Project-template trinity carries no "Trinity exemption" marker for sections that diverge (intra-project-side, structural)

**Citation A.** `project-template/GEMINI.md:400-404` Trinity-rule exception HTML comment for the `## Agent roster` section:

> `<!-- Trinity-rule exception: this `## Agent roster` section is present in GEMINI.md only. Gemini CLI auto-discovers agents via filesystem scan of `.gemini/agents/`; the explicit roster below is a presentation aid for the human reader of GEMINI.md. CLAUDE.md and AGENTS.md rely on the phase-routing table above and tool-side discovery and do NOT need a parallel section. -->`

**Citation B.** D.4 above (the "PM chat does not architect" bullet diverges between CLAUDE.md/AGENTS.md and GEMINI.md by dropping the agent-name enumeration in GEMINI.md). NO `Trinity-rule exception:` HTML comment is present at this divergent bullet to record the justification.

**Nature of contradiction.** Project-template trinity has a documented pattern for marking trinity divergences (HTML comment naming the section as exception and stating the tool-specific justification). The Agent-roster section uses it; the divergent bullet in D.4 does not. So the pattern is established but not consistently applied. Either D.4 is an undocumented divergence (defect under §B.3 trinity rule) or the divergence is intentional and not marked (process gap). Surface as a structural conflict between "trinity exception convention" and "actual GEMINI.md text where exceptions occur without markers."

### D.10 — No conflict found between pack-side and OT-side trinity carrying "PM chat does not architect" (cross-side, EXPLICIT no-conflict)

**Citation A.** Pack-side trinity `### Workflow` "Pack Chat does not architect" bullet (e.g., `AGENTS.md:118-121`).

**Citation B.** Project-template `## Project memory` "PM chat does not architect" bullet (`project-template/CLAUDE.md:362-368`).

**Citation C.** OT `## Project memory` "PM chat does not architect" bullet (`/Users/david/Developer/OptiquityTrader/CLAUDE.md:359-364`).

**Verdict.** No conflict — same rule applied to two distinct actors (Pack Chat on the pack repo; PM Chat on a client project). The pack-side rule is the cross-application of the project-side rule to the pack repo's own Pack Chat role. This is the design-by-overlap pattern noted in §C.10.

---

## Notes on coverage and method

- **Pack-side 19b commits read in full:** `667d2dd` (19b-1 trinity restructure), `ef9e5c7` (manifest regen recovery), `a9b7c74` (19b-2-RC9 manifest-regen rule), `7e4fdcc` (19b-2 PACK-CHAT extensions), `3558525` (19b-3 PACK-AGENTS PREFLIGHT), `4760649` (19b-4 EXECUTION-PLAN §B rewrite), `aaa61b3` (19b-5 CONCEPTUAL-REVIEW extension), `efd9a32` (19b-7 archive sweep), `30a1bc3` (broad batch fix), `3d8cc8b` (Batch 19b close PM commit). Commit messages read; diffs surveyed via `git show --stat`; full file content read at HEAD for trinity files / PACK-CHAT.md / PACK-AGENTS.md / EXECUTION-PLAN-V11.0.md §B / CONCEPTUAL-REVIEW-METHODOLOGY.md.
- **Pack-side 19b archived workflow artifacts surveyed:** `ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` (V2 architect doc — the design source for the batch); `CLEANUP-INPUTS-SESSION-RULES.md` (the input collection); `PACK-REVIEW-CLEANUP-BATCH-19B-broad.md` (the end-of-batch broad review). Other archived 19b artifacts (V1 architect doc, RC9 architect doc, planner doc, IMPL-REPORTs, per-commit reviewers) were available but not read in full; key content from them surfaced via commit messages and the broad reviewer's references.
- **Tier-1.5 memory cache surveyed:** MEMORY.md index read at full; one feedback file read in full as sample (`feedback_pack_chat_does_no_fixes.md`) to confirm the pointer-only shape per ARCHITECTURE-CLEANUP-BATCH-19B-V2.md §D.3.
- **Project-side surveyed:** project-template trinity (CLAUDE.md full; AGENTS.md §Project memory + Phase routing; GEMINI.md §Project memory + Agent roster + operating notes); project-template/docs/pack/PM-CHAT.md (full); supporting-docs/METHODOLOGY.md (Parts 1, 2, 7, 8, 9, 10 + Prompt Authoring Principles + Appendix); supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md (full); supporting-docs/INSTALL-PROCEDURES.md (headers + §Project file conventions); supporting-docs/SETUP-NEW.md (header); project-template/.claude/agents/coder.md (full as sample agent definition).
- **OT counterparts surveyed (READ-ONLY):** CLAUDE.md (full), AGENTS.md (§Project memory + agent enumeration regions), docs/pack/METHODOLOGY.md (header for version stamp), docs/pack/PM-CHAT.md (full).
- **Out of scope as required:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md`, `ARCHITECTURE-CLEANUP-BATCH-19C-DISCARDED.md`, and `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md` were NOT read.
- **No file modifications made.** This report is the only file written. No state-changing git verbs were run. OT repo was read-only.
