# RESEARCH — Batch 19c G-item verifications (G-1..G-9)

**Purpose:** Verify the V1 architect's §B categorizations and §C/§D
placement claims for ARCHITECTURE-CLEANUP-BATCH-19C.md. Each G item
is a specific factual verification — existence or absence of a rule
in pack source, or external-CLI semantics. The V2 architect uses
these verdicts to confirm or adjust placements.

**Scope.** Read-only research. Verdicts + citations + one-sentence
architect-implication notes per the prompt; no design or
recommendation language.

**Cross-referenced research artifacts** (consulted but did not
re-derive their conclusions):
- `maintenance-docs/v11-implementation/RESEARCH-BATCH-19B-STRATEGIC-RULES.md`
- `maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md`

Neither contains G-style Y/N verdicts; both informed the framing
but every verdict below comes from fresh verification.

---

## G-1 — Claude Code `isolation: "worktree"` issue applies to client project sub-agent spawns

**Verdict:** YES — the same default-branch-checkout mechanism applies
universally to any sub-agent spawn with `isolation: "worktree"`, on
any branch in any clone (not specific to the pack repo's v11-dev/main
split).

**Evidence:**

- Claude Code Worktrees docs — official behavior:
  https://code.claude.com/docs/en/worktrees says "Worktrees branch
  from your repository's default branch, `origin/HEAD`, so they start
  from a clean tree matching the remote. If no remote is configured
  or the fetch fails, the worktree falls back to your current local
  HEAD." The default-branch behavior is the documented behavior, not
  a bug; the surprise is that it ignores the launching session's
  current branch.
- Issue #50850 — `anthropics/claude-code` — "Worktree subagents branch
  from `origin/main` rather than current HEAD — intentional?":
  https://github.com/anthropics/claude-code/issues/50850 — confirms
  that when a sub-agent is dispatched with `isolation: "worktree"`,
  the new worktree branch is created from `origin/main`, not the
  branch currently checked out in the launching session. The reporter
  observed "16 days and 426 commits behind what the outer session
  sees" with no signal to the outer session that the views differ.
- Issue #41680 — "`--worktree` creates worktree from `origin/HEAD`
  instead of current branch":
  https://github.com/anthropics/claude-code/issues/41680 — same
  mechanism observed at the CLI flag level (independent of the Agent
  tool isolation parameter), confirming the behavior is at the
  worktree-creation layer, not specific to Agent-tool plumbing.
- Issue #43535 — "`isolation: "worktree"` creates worktrees from
  wrong commit when base branch is not `main`":
  https://github.com/anthropics/claude-code/issues/43535 — reproduces
  on any non-`main` base branch, confirming the issue is not
  pack-repo-specific.
- Workaround / setting — the Claude Code Worktrees docs and issue
  #50850 reference a `worktree.baseRef = "head"` setting that, when
  set, makes new worktrees use local HEAD instead of `origin/HEAD`.
  This setting exists at the project level, not the agent level —
  so the rule is "set baseRef appropriately" project-wide, not a
  per-agent guard.
- Pack-side memory pointer (cross-reference, not authority):
  `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_worktree_isolation_broken_from_v11_clone.md`
  — empirically established by the pack repo for its v11-dev/main
  split. The web evidence above shows the mechanism is general.

**Architect implication:** Confirms §F D-1's open question and the
proposed `### Sub-agent behavior (Claude-only)` sub-section in
`project-template/CLAUDE.md` `## Project memory` is grounded in a
real, documented Claude Code behavior — a client project on any
feature branch (not just `v11-dev`-style branch splits) will hit the
same stale-checkout issue unless `worktree.baseRef = "head"` is set
or no-isolation sequential agents are used.

---

## G-2 — Codex CLI and Gemini CLI agent-team stage-lifecycle analog

**Verdict:** Both CLIs have spawn / cap / close mechanisms; NEITHER
has a true "keep-alive across phase, close at commit" analog to
Claude Code Agent Teams + SendMessage. Codex is closer (long-lived
threads exist via `/agent` and `close_agent`); Gemini is the
furthest (subagents are one-shot consolidated returns). Pack-shipped
`project-template/agent-run.sh` does NOT manage lifecycle on either
CLI — every invocation is a fresh `exec`-launched process.

**Per-CLI summary:**

| Aspect | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Spawn API | Agent tool with `isolation` / `subagent_type` | `spawn_agent` + `wait_agent` + `close_agent` model tools | `@<subagent-name>` syntax injected by main agent |
| Concurrency cap | (n/a — implicit) | `agents.max_threads` (default 6, configurable) | (n/a — implicit; parallel by default) |
| Per-invocation lifecycle | Sub-agent persists within Agent Teams stage; SendMessage to follow up | "Each spawn creates a thread"; lives until `close_agent` or process exit | Subagent runs ONE task, returns ONE consolidated response, terminates |
| Parent → child follow-up messaging | SendMessage (Agent Teams flag) | `/agent` interactive switch + steer / stop natural-language | None — subagent is one-shot per delegation |
| Cross-invocation persistence in `codex exec` / `gemini @` | n/a | `codex exec` "starts a fresh process with a new AgentRegistry for each invocation" (#19475 / docs) | `exec gemini ... -i "@agent..."` always launches fresh; each subagent uses a separate context loop, results merge back into main context |
| Process lifecycle in pack-shipped `agent-run.sh` | `exec claude --agent <name>` per call | `exec codex` per call | `exec gemini -i "@<agent>"` per call |
| "Keep-alive across phase, close at commit" analog | Yes (Agent Teams + SendMessage; pack-side rule) | Partial — long-lived threads exist in persistent CLI/REPL sessions; can be steered/closed via `/agent`; NO peer-messaging | NO — subagents are one-shot delegated tools; no parent-controlled keep-alive across multiple parent turns |

**Evidence — agent-run.sh (pack-shipped script behavior):**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/agent-run.sh:443` —
  `exec gemini "${EXTRA[@]+"${EXTRA[@]}"}" "${other_args[@]+"${other_args[@]}"}" -i "$activation_msg"`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/agent-run.sh:472` —
  `exec codex "${EXTRA[@]}" "${codex_opts[@]+"${codex_opts[@]}"}" "$activation_msg"`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/agent-run.sh:476-478` —
  `exec claude --agent "$AGENT" ...` — fresh Claude Code process per call
- All three branches use `exec`; the launching shell is replaced with
  the CLI process; no script-side persistence layer.

**Evidence — Codex CLI:**

- Codex Subagents docs: https://developers.openai.com/codex/subagents
  — describes `spawn_agent` / `wait_agent` / `close_agent` model
  tool surface; subagents live as threads inside the parent session.
- Issue #18335 — `openai/codex` "Agent spawn slots leak across turns
  in persistent sessions": https://github.com/openai/codex/issues/18335
  — confirms "In persistent session modes (app-server transport,
  interactive CLI REPL), the `AgentRegistry.total_count` used to
  enforce `agent_max_threads` is only decremented when `close_agent`
  is explicitly called." Threads outlive the spawning turn unless
  the model emits `close_agent`.
- Issue #19475 — `codex exec` Windows rollout issue:
  https://github.com/openai/codex/issues/19475 — confirms `codex exec`
  "starts a fresh process with a new AgentRegistry for each
  invocation, and each invocation starts a fresh OS process."
- Issue #12462 (referenced in pack-root CLAUDE.md `### Sub-agent
  behavior` and Batch 19b research) — confirms NO peer-messaging
  equivalent (no SendMessage); parent control is `/agent` natural-
  language or stop-command.
- Issue #11965 — "`Allow for >6 Subagents: Make MAX_THREADS
  Configurable in CONFIG`": https://github.com/openai/codex/issues/11965
  — confirms `agents.max_threads` is the configurable concurrent-
  thread cap.
- Issue #12844 — "Main thread kills subagents too eagerly":
  https://github.com/openai/codex/issues/12844 — confirms the parent
  thread retains some lifecycle authority over child threads.

**Evidence — Gemini CLI:**

- Subagents docs: https://geminicli.com/docs/core/subagents/ and
  https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md
  — confirm subagent runs a single task with its own isolated context
  window and tool set, returns "a single response back to the main
  agent" (consolidated). Subagent's intermediate steps do not enter
  the main agent's history.
- Subagents blog post (Google Developers):
  https://developers.googleblog.com/subagents-have-arrived-in-gemini-cli/
  — "Each subagent operates within its own separate context window,
  custom system instructions, and curated set of tools" with results
  consolidated back to main.
- Session Management deepwiki:
  https://deepwiki.com/google-gemini/gemini-cli/3.9-rewind-and-session-management
  — subagent sessions are stored as sub-directories named after
  `parentSessionId`, but the subagent is not a long-lived peer the
  parent can re-target; each `@<agent>` invocation is a fresh task
  delegation.
- Subagents tutorial:
  https://www.aimadetools.com/blog/gemini-cli-subagents-guide/ —
  confirms parallel invocation via multiple `@agent-name` calls;
  results merge back into main context once each completes (one-shot
  per call).

**Architect implication:** Confirms a true "keep-alive across phase
+ close at commit" rule cannot be ported to Codex / Gemini under
existing CLI semantics — Codex's thread model is closest but lacks
peer-messaging, Gemini is one-shot per delegation. The Trinity
exemption framing in pack-root CLAUDE.md (Agent Teams = Claude-Code-
specific) extends naturally to the project-template trinity if §F
D-1 lands the rule there.

---

## G-3 — Architect-trigger surface-even-mechanical rule absent from pack source

**Verdict:** N — the "even when the trigger looks mechanical, surface
the check explicitly" extension is NOT present in pack source.
Confirms the §B PARTIALLY GAP-FILL categorization and §C.2 placement.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 489-509 (Workflow 4 architect trigger conditions): Defines
  Trigger A and Trigger B precisely. The "Why this matters" callout
  at lines 504-508 explains the rationale ("A coder running more
  than twice without clearing all issues, or a coder introducing
  more issues than it fixes, signals that the problem is
  architectural") but contains NO instruction to surface the trigger
  check when the issue "looks mechanical." It treats the trigger as
  binary (fires or doesn't).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 510-533 (What the PM chat does when a trigger fires):
  Defines a 6-step procedure starting with "Identify root cause."
  This procedure assumes the trigger has fired — no preceding
  "surface-the-check-even-if-mechanical" sub-step before identifying
  the root cause.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  lines 201-202 (Fix cycle rules bullet): "Follow Workflow 4 in
  METHODOLOGY.md, including the architect trigger conditions
  (Trigger A and B)." Points at METHODOLOGY.md — adds no extra
  guidance about surfacing mechanical-looking triggers.
- Trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) `## Project
  memory` sections (`CLAUDE.md:343`, `AGENTS.md:320`, `GEMINI.md:338`)
  — carry trinity rule, no-destructive-ops, PM-chat-does-not-
  architect. No architect-trigger-surface language at all.
- Prompt files (`project-template/docs/pack/prompts/`) — no file
  contains "trigger" surface-or-waive language; trigger discipline
  is methodology-side, not prompt-side.
- Grep `silent|surface|mechanical` against METHODOLOGY.md returned
  zero hits in the architect-trigger context (only matches at lines
  879, 1132, 1301 are unrelated to triggers).

**Architect implication:** Confirms the §C.2 STRENGTHEN placement
in METHODOLOGY.md Workflow 4 (between Trigger B and the "Why this
matters" callout) lands as new content; no existing rule covers the
surface-even-mechanical extension.

---

## G-4 — "PM chat never edits source files" rule absent from PM-CHAT.md as a behavioral rule

**Verdict:** Y (partially) — the rule is PRESENT IMPLICITLY in
METHODOLOGY.md Part 9 (table at line 1384 says "Production source
files: PM chat: Never") and in PM-CHAT.md `## Behavioral rules`
line 203-205 ("Never write to source code files for any other
reason"). It is NOT present as a dedicated standalone bullet
explicitly titled "PM chat never edits source files." The negative
prohibition is buried at the end of a write-permissions bullet.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  lines 203-205 (Source file edits bullet): "You may write to
  BACKLOG.md, STATUS.md, and deferral comments in source files —
  but only after explicit user approval. **Never write to source
  code files for any other reason.**" — The negative is present as
  the trailing sentence of a positive-permissions bullet. It IS a
  rule, just not a prominently-headlined behavioral rule.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  full `## Behavioral rules` (lines 176-263) — no other bullet
  addresses source-file edits; no "PM chat never edits production
  source files" stand-alone bullet exists.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  `## Permission profiles` (lines 266-371) — describes per-agent
  permission profiles (read-only / write-capable scoped / write-
  capable script), but does not address the PM chat's own write
  scope. The profiles are FOR agents, not the PM chat.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 1384-1394 (Part 9 "What agents can and cannot modify"
  table): "Production source files | Yes [Coder] | Never [Reviewer]
  | Never [PM chat] | Core job" — the prohibition exists in the
  table cell, BURIED in a wider doc-authoring matrix.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 1396-1409 (Part 9 "Desktop Commander scope for PM chat"):
  "The PM chat must NOT use Desktop Commander for: Writing or
  modifying any source code" — present, but specific to Desktop
  Commander tool surface; doesn't generalize to all PM-chat write
  surfaces (e.g., direct Claude Code Edit / Write tools).
- Trinity files `## Project memory` sections (CLAUDE.md / AGENTS.md /
  GEMINI.md) — NO source-file-prohibition rule. Only the
  no-destructive-ops bullet and the trinity rule and the
  PM-chat-does-not-architect bullet appear.
- The OT-T-6 "never use `git checkout --` on coder work" nuance
  cited in §B for OT-T-6 — verified NOT present anywhere
  (`grep -in "checkout" PM-CHAT.md METHODOLOGY.md` returns no
  relevant hits in this context).

**Architect implication:** §C.6's NEW dedicated bullet in PM-CHAT.md
`## Behavioral rules` and the trinity STRENGTHEN (adding `git
checkout --` to the destructive-ops named list) both land as net-new
explicit content; the existing trailing-sentence form is too weak
to function as a standalone behavioral rule per OT's incident
pattern.

---

## G-5 — "Re-read per-agent prompt file every time" rule absent from PM-CHAT.md

**Verdict:** Y — the rule IS present in concept-form for the
PRINCIPLES doc (METHODOLOGY.md Prompt Authoring Principles) but is
NOT present for the per-agent prompt FILE. Confirms §C.7 placement.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  line 188-189 ("Follow Prompt Authoring Principles" bullet):
  "Before generating any prompt, re-read the Prompt Authoring
  Principles section of METHODOLOGY.md." — Targets the PRINCIPLES
  section in METHODOLOGY.md, not the per-agent prompt file under
  `docs/pack/prompts/<agent>.md`.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  full `## Behavioral rules` (lines 176-263) — no other bullet
  references re-reading per-agent prompt files. The "Agent report
  file" bullet (line 242-247) names the REPORT FILE convention but
  does not say the PM chat must re-read the prompt file template.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 603-886 (Prompt Authoring Principles), especially the "PM
  chat self-check before generating any prompt" sub-section at
  lines 861-885 — defines 4 self-checks (Triad / Solution /
  Data-dependency trace / REPORT FILE check). NONE of them says
  "re-read the per-agent prompt file." The Triad check could be
  satisfied by memory; the prompt-file re-read would be a 5th item.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 610-622 ("About docs/pack/prompts/" sub-section): "The PM
  chat reads `<agent>.md` on demand, locates the requested variant
  by its `## Variant: <slug>` heading, copies the body, and
  customizes it for the task at hand." — Describes the workflow but
  says "reads on demand," NOT "re-reads every time without
  exception."
- Prompt files themselves (`project-template/docs/pack/prompts/*.md`)
  — no file contains "PM chat must re-read" language.
- Re-read references in PM-CHAT.md (`grep -in re-read`): only
  matches at lines 105 (negative — "is current and re-reading the
  files is redundant"), 188 (Prompt Authoring Principles re-read),
  595 (compaction handling — re-read state files), 613 (RAG),
  667 (compression). None target per-agent prompt files.

**Architect implication:** Confirms §C.7's NEW bullet placement
adjacent to the existing "Follow Prompt Authoring Principles" bullet
is not duplicative — the existing bullet targets the principles
section, the new bullet targets per-agent prompt files. Two distinct
re-read disciplines.

---

## G-6 — Closeout-sequence rule absent from PM-CHAT.md / METHODOLOGY.md

**Verdict:** Y — the 5-step closeout sequence (trigger check →
present → wait → write → commit-message-approval → commit) is NOT
present as a single ordered rule anywhere in pack source. Individual
components exist scattered across PM-CHAT.md and METHODOLOGY.md, but
no bullet enforces the ORDERED SEQUENCE. Confirms §C.4 placement.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  full `## Behavioral rules` (lines 176-263) — no closeout-sequence
  bullet. Closest fragments:
  - Line 180-181 ("Plan before executing"): "present a plan and wait
    for explicit approval before doing anything." Generic plan-
    before-execute; not closeout-specific; not 5-step.
  - Line 203-205 ("Source file edits"): "only after explicit user
    approval" — covers WRITE permission, NOT the present-wait-write
    sequence ordering.
  - Line 451-453 (METHODOLOGY.md, callout in Workflow 4 area, also
    referenced): "the PM chat presents a plan and waits for
    approval before generating any agent prompt." Plan-before-spawn,
    not closeout sequence.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 1198-1219 (Part 7 Procedure 4 "Resolution procedure"):
  Steps are (1) determine resolution path, (2) generate prompt,
  (3) reviewer + PM chat marks Status: Resolved, (4) disposition
  scan. The procedure assumes a coder completion already happened
  and addresses follow-on resolution mechanics; it does NOT cover
  the present-wait-write closeout sequence between reviewer-PASS
  and BACKLOG/CHANGELOG/STATUS writes.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 1382-1413 (Part 9 Document Authoring Rules + Desktop
  Commander scope) — defines WHO can write WHAT, NOT the WHEN /
  ORDER of present-wait-write.
- Pack-side analog (`PACK-CHAT.md` `## Behavioral rules`) — also
  does NOT codify the 5-step ordered sequence as a single rule;
  pack-side codifies "commit-approval requests include next-steps
  plan" (in pack-root CLAUDE.md `## Pack memory` § Pack Chat scope)
  which is the present-wait part but not the full 5-step ordered
  shape. Pack-side guidance is consistent with §C.4's design but
  does not preempt it.
- `grep -in "closeout|present.*before|present.*content|before
  writing"` against METHODOLOGY.md returned hits at lines 108
  ("create them before writing any code" — unrelated), 384 (unrelated
  doc-commit instruction), 452 (plan-before-spawn — Workflow 4),
  863 (prompt self-check), 1264 / 1266 (Procedure 6 G6-drafts /
  G6-install gate language — relevant procedural pattern but
  Procedure 6 specific, not closeout-sequence).

**Architect implication:** Confirms §C.4's NEW bullet placement is
not duplicative; the closeout sequence as an ordered 5-step rule
is genuinely absent. The Procedure 6 G6-drafts / G6-install / G6-
commit gate pattern (METHODOLOGY.md:1264-1268) is the closest
existing analog and could inform §C.4 wording style.

---

## G-7 — Mid-phase planner triggers (P-A / P-B / P-C) absent from pack source

**Verdict:** Y — mid-phase planner triggers are NOT codified anywhere
in pack source. The Planner trigger rule at METHODOLOGY.md
lines 236-248 covers PHASE-DESIGN-TIME (Procedure 1 phase-gate-time)
exclusively. The mid-phase planner mechanism does not exist.
Confirms §D.4 placement.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 235-248 (Part 3 "Planner trigger rule"): "The planner check
  runs as part of Procedure 1 (phase gate check) in Part 7 — before
  generating any coder prompt." Three trigger conditions follow:
  (1) phase has >5 tasks or non-linear dependencies, (2) PM chat
  cannot map phase description to discrete tasks, (3) coder failed
  twice without progress due to task definition (not architecture).
  All three fire at phase-gate-time (BEFORE any coder prompt for
  the phase), not mid-phase.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  lines 435-533 (Workflow 4 Fix cycle): The Workflow 4 mechanism is
  reviewer → triage → architect-trigger-check → coder fix-pass
  ORBITING the architect (not the planner). There is no analogous
  "planner trigger" check after the reviewer fires. The third
  trigger condition in the Planner trigger rule (lines 246-248)
  mentions "a coder has failed the same phase twice without
  meaningful progress and the cause appears to be task definition
  rather than architecture" — but this trigger is defined inside
  the phase-design-time Procedure 1 framing, not as a Workflow 4
  fix-cycle option. Workflow 4 always invokes the architect (line
  442-446, 517-518), never the planner.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/agents/planner.md`
  (lines 1-89) — defines the planner role as a one-shot read-only
  pass with REPORT FILE output. No mid-phase variant; no triggers
  enumerated; the agent file is invocation-agnostic and orchestration-
  agnostic.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/prompts/planner.md`
  (lines 1-56) — Single variant `standard`. No mid-phase variant.
  The "Context" line says "Phase [N] is too complex to send to the
  coder without an ordered task breakdown" — frames the planner as
  PHASE-DESIGN-TIME context only.
- `grep -in "mid-phase|mid-pipeline|planner"` against METHODOLOGY.md
  — Planner references at lines 113, 202, 237, 238, 597 (Workflow 4
  agent table — lists `planner.md Variant: standard` only — no mid-
  phase entry), 737, 783, 795, 857. None describe a mid-phase
  planner trigger or sub-section.
- Pack-side `PACK-CHAT.md` / pack-root CLAUDE.md — no mid-phase
  planner pattern (orthogonal — pack-side uses architect + reviewer
  cycles, not phased coder work).

**Architect implication:** Confirms §D.4's three triggers (P-A / P-B /
P-C) land as a NEW sub-section to METHODOLOGY.md Workflow 4. The
sibling positioning to the architect-trigger sub-section is correct
because both fire mid-phase post-reviewer; the existing planner
trigger rule fires at phase-gate-time and stays where it is.

---

## G-8 — Project-template skills already document OT-promotion candidate content

**Verdict:** N (no significant overlap) — the four skills checked
(planning, architecture-review, review, pm-startup) do NOT carry any
§C / §D OT-promotion rule content. They are scoped to methodology /
checklist guidance within each skill's narrow domain; cycle-discipline
and PM-chat-orchestration rules live in METHODOLOGY.md / PM-CHAT.md /
trinity, not in skills. Confirms §C / §D placements do not duplicate
existing skill content.

**Per-skill summary:**

| Skill | Path | What it covers | Overlap with §C / §D items |
|---|---|---|---|
| `planning` | `project-template/skills/planning/SKILL.md` (lines 1-33) | Scoping, task breakdown, dependency / risk identification, verification strategy. Single-shot methodology for the planner agent's own work. | NONE. No PM-chat-side rules; no triggers; no closeout sequence; no mid-phase variant. The planner agent's pass is self-contained; orchestration rules live in METHODOLOGY.md Part 3 (lines 235-248) and Workflow 4. |
| `architecture-review` | `project-template/skills/architecture-review/SKILL.md` (lines 1-81) | Layer discipline, state ownership, abstraction quality, capabilities pattern, navigation, dependencies. Methodology for the architect agent's review work. | NONE. No architect-trigger-surface rule (G-3 scope); no mid-phase escalation rule (G-7 scope); no PM-chat closeout sequence (G-6 scope). |
| `review` | `project-template/skills/review/SKILL.md` (lines 1-29) | Reviewer priorities (correctness / security / regressions / concurrency / architecture compliance), examination checklist, finding-format rules. | NONE. No "always reviewer after coder" rule (the §C.1 OT-T-1 placement); no PM-chat-side triggers. The skill defines how the REVIEWER does its job, not when the PM chat invokes it. |
| `pm-startup` | `project-template/skills/pm-startup/SKILL.md` (lines 1-261) | 8-step startup sequence (post-migration sweep, git pull, read core state, RAG reconcile, TD-TBD check, state report, tracker recommendation). Scoped to startup-time orientation only. | NONE on §C items. PARTIAL on §D.1 (per-project Claude memory cache): the skill is the natural Tool-specific:Claude-Code-CLI sibling, but does NOT currently reference any `~/.claude/projects/<slug>/memory/` directory or per-project pointer-index pattern. Confirms G-9 verdict too. |

**Evidence — additional verification:**

- All four skills follow the same shape: brief frontmatter, numbered
  methodology / checklist items. None contains "PM chat" instructions
  (skills are agent-loaded, not PM-chat-loaded — except `pm-startup`
  which IS a PM-chat skill and was checked closely).
- `pm-startup/SKILL.md` Step 2 (lines 66-94) reads BACKLOG / STATUS /
  PM-CHAT.md / PLATFORM-SKILLS.md / CHANGELOG / IMPLEMENTATION-PLAN /
  METHODOLOGY.md — no reference to `~/.claude/projects/` or per-
  project memory cache.
- Skills cover the agent's WORK methodology; trinity / PM-CHAT.md /
  METHODOLOGY.md cover the PM-chat ORCHESTRATION. §C / §D items are
  orchestration-side, hence no overlap.

**Architect implication:** All §C / §D placements stand without
deduplication or skill-redirection. §D.4 (mid-phase planner triggers)
specifically does NOT belong in the `planning` skill — the skill is
agent-loaded methodology; triggers are PM-chat orchestration and
belong in METHODOLOGY.md Workflow 4 as proposed.

---

## G-9 — Per-project Claude memory cache tooling already shipped in pack

**Verdict:** N — the pack ships NO per-project Claude memory cache
tooling. No script auto-creates a `~/.claude/projects/<slug>/memory/`
directory; no skill references the path; no SETUP doc instructs the
developer to create it. Confirms §D.1 architect recommendation
("ship convention but NOT auto-tooling") because there is currently
neither.

**Evidence:**

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh`
  (58925 bytes, 11-stage installer) — `grep -in "memory\|~/.claude"`
  returned ZERO hits. No memory-cache bootstrap step exists.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/add-capability.sh`
  (37916 bytes, capability addition workflow) — `grep -in
  "memory\|~/.claude"` returned ZERO hits. No memory-cache extension.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/`
  recursive grep `grep -l "memory" scripts/*.sh scripts/lib/*.sh
  scripts/tests/*.sh` returned only 8 hits, all in tracker /
  migration / test scripts where "memory" refers to in-memory data
  structures or test fixture wording — NONE relate to the per-project
  Claude memory cache directory pattern. Confirmed via second pass
  with `grep -l "~/.claude/projects\|claude/projects"` against the
  same set → zero hits.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md`
  full read (261 lines) — no reference to `~/.claude/projects/<slug>/
  memory/` or per-project pointer index. Step 2 reads project state
  files; no memory-cache initialization.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/SETUP-NEW.md`
  — `grep -in "memory\|~/.claude\|cache"` returned ONE hit at line
  449: "`.buf/` — buf CLI cache." Unrelated to Claude memory cache.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/`
  recursive grep for `~/.claude/projects\|claude/projects\|per-project
  memory` returned ZERO hits.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  `## Tool-specific: Claude Code CLI` section (line 552 onwards,
  read through line 596) — covers session management, startup
  procedure, file access (mcp-local-rag mention), compaction handling.
  NO per-project memory cache section; the section is the natural
  home for §D.1's documentation but currently has none.

**Architect implication:** Confirms §D.1 lands as ALL-NEW content
(both the convention and any tooling decision). Pack-shipped
behavior today is "nothing" — Alt-1 (no per-project Claude memory
documentation) is the current state; the proposed (b) sub-decision
"do NOT ship a script that auto-creates a per-project memory cache"
matches current behavior; only (a) the documentation addition is
the net-new surface.

---

## End of report
