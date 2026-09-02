# METHODOLOGY.md — AI-Assisted Project Development Methodology

Version: 2.1 (v11.0, May 2026)
Applies to: All projects using Claude Code CLI, Codex CLI, or Antigravity CLI with AI Agent Config Pack v11

> **Applicability note:** This document is platform-agnostic and applies to all project
> types (Apple, Python server, monorepo) and all three CLI tools (Claude Code, Codex,
> Antigravity). Agents that don't apply to your project type can be ignored. The PM chat
> selects agents and skills per project using `PLATFORM-SKILLS.md`.

> **Single source of truth:** One copy of this file lives at
> `supporting-docs/METHODOLOGY.md` in the pack repo. Copy it to your project
> root during setup (copied to project root by `init-project.sh`). Do not
> modify the pack's copy for project-specific needs — edit the project
> root copy instead and let it evolve with the project.

---

## Overview

This document is the reference guide for building software projects using Claude Code CLI
agents for execution and a Claude Chat project as the persistent project manager.

**The core principle: Claude Chat is the brain. Claude Code CLI is the hands.**
They are not interchangeable. Claude Chat holds context, makes decisions, and generates
prompts. CLI agents execute those prompts against the actual filesystem.

**For prompt templates** referenced throughout this document, see:
`docs/pack/prompts/<agent>.md` — one file per agent, one `## Variant:`
H2 per template (travels with `project-template/` at project setup).

**Desktop Commander note:** When Desktop Commander is available in the Claude desktop app,
the PM chat can write files and run git commands directly for small targeted doc changes
(STATUS.md updates, BACKLOG additions, CHANGELOG entries). For any larger change — or when
Desktop Commander is unavailable (web Claude, different machine) — the PM chat outputs the
file content and git commands for the human to run manually. The manual fallback must always
be available. After any file edit, the human syncs the GitHub connector before the next session
that depends on that content.

---

## Part 1 — Tool Roles

### Claude Chat Project (PM chat)

- Long-running project manager for the entire project lifetime
- Connected to GitHub repo via GitHub connector (read-only search)
- Generates all agent prompts — coder, reviewer, tester, docs-researcher
- Receives all agent output (pasted by developer) and analyzes it
- Makes all architectural and planning decisions

> **Four PM chat options:** The PM chat can run as a Claude Desktop app project
> (setup steps are in the pack repo at `<pack-clone>/supporting-docs/SETUP-NEW.md` Step 10,
> Option A), a resumable Claude Code CLI session (Step 10, Option B), a Codex
> CLI session (Step 10, Option C), or an Antigravity CLI session (Step 10, Option D).
> Daily CLI usage reference in `<pack-clone>/supporting-docs/CLI-PM-SETUP.md`.
> The methodology, rules, and procedures are identical in both modes. `PM-CHAT.md`
> in the project root provides startup instructions and is read by both modes —
> directly from disk by the CLI PM chat, and via the GitHub connector by the
> Desktop app PM chat.
- **Scope for direct file edits:** Small, targeted doc-only changes only:
  STATUS.md updates, BACKLOG additions, CHANGELOG entries, typo/stale-reference fixes.
  Never source code. Never sweeping multi-file changes without explaining and getting approval.
- Never writes code or calls specialist agents directly
- **Plan before executing — no exceptions.** For any change beyond a trivial doc edit,
  the PM chat must present a plan describing what will change and why, then wait for
  explicit user approval before executing anything. This applies to code files,
  documentation files, shell scripts, config files, and any other project files.
  Receiving a task description is not approval. Approval must be explicit.
- **Never bias architect agents with proposed solutions.** When routing a problem to an
  architect agent, describe the constraint or design problem only — do not propose a
  solution. The architect agent solves design problems. Any proposed architecture,
  pattern choice, or structural change must come from the agent, not the PM chat.
  See the **Prompt Authoring Principles** section for the full standard that applies
  to all agent types.

### Claude Code CLI (agents)

- Executes specific, scoped tasks in new sessions
- Full filesystem read/write access; runs builds, tests, git commands
- No persistent memory — each session starts fresh with full context in the prompt
- Receives complete instructions in the prompt; never relies on session history

> **Claude-only operating convention — Agent Teams stage
> lifecycle.** When the developer enables Claude Code's Agent
> Teams flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`),
> sub-agents spawned for a phase stage (architect → planner →
> coder → reviewer) stay alive within the stage; the PM chat
> uses SendMessage to send follow-up directives to the same
> sub-agent instance. After the stage's commit lands, close
> all stage sub-agents and respawn fresh for the next stage.
> Additionally, each coder commit should use a FRESH coder
> instance — never reuse a coder across commits, even within
> the same stage. This convention is Claude-Code-specific.
> Codex CLI and Antigravity CLI now ship
> their own inter-agent-messaging analogs (Codex's multi-agent messaging; Antigravity's
> inter-agent ID-addressing with idle auto-rewake), but these are newer, opt-in /
> partly-preview capabilities — so this Agent-Teams stage-lifecycle convention is
> documented for Claude Code only; on Codex / Antigravity, follow your CLI's own
> subagent guidance. Codex / Antigravity project teams: this convention
> does not apply to your CLI's runtime behavior.

### Xcode Coding Agent

- Built-in AI in Xcode 26.3 (chat panel)
- Best for in-editor questions, code completion context, and Xcode-specific guidance
- Reads machine-level CLAUDE.md from ~/Library/Developer/Xcode/CodingAssistant/
- New session for each task

### VS Code (Python projects)

- Used for Python server and monorepo projects
- Claude Code CLI operates from the project root in the terminal
- VS Code companion files in `vscode-companion-templates/` provide editor config

### Separation rule

Planning and decisions: Claude Chat only.
Execution and file changes: CLI agents only (or Desktop Commander for small doc edits).
Pasting results from CLI back to Claude Chat: developer only.

### PM chat omniscience obligation

The Separation rule above describes the WHAT — who does what
work. This sub-section describes the WHY — why the PM chat is
positioned as the brain.

The PM chat operates with a bird's-eye view of ALL workflows
and processes in the project: every agent's role and capability,
every methodology rule, every active phase, every standing
constraint, every cross-agent integration point. Agents,
by contrast, operate with a focused view of their assigned
task and the prompt context the PM chat provides — they may
know about other agents incidentally, but they are not
obligated to. The PM chat is.

This positioning creates an OBLIGATION: when constructing any
agent prompt, the PM chat must give the agent all the
information, rules, guardrails, and structure that agent needs
to do its work effectively AND to integrate cleanly with other
agent work it may not know about. This includes:

- Citing the project-side rules the agent must respect (from
  `docs/pack/PM-CHAT.md` § Behavioral rules, the project trinity
  § Project rules, and this methodology document).
- Naming the specific files the agent reads, writes, or must
  avoid (per the per-prompt File-in-scope / Out-of-scope lists
  in § Prompt Authoring Principles).
- Injecting per-agent prompt-template content the agent has no
  way to discover otherwise (REPORT FILE line, completion-
  report shape, chunked-Write instruction).
- Providing the integration context the agent needs to produce
  output that fits with upstream and downstream agent work
  (e.g., a coder receives the architect's relevant decisions;
  a reviewer receives the planner's task contract).

This obligation has two documented exceptions where duplication
across surfaces is the correct trade-off (see Part 9 § Rule
placement for the full taxonomy):

- **Defense-in-depth duplication for high-blast-radius rules.**
  When a rule is agent-affecting AND prompt-corruption risk is
  non-trivial (e.g., destructive git verbs that ALL agents must
  respect), the rule lives in the project trinity § Project rules
  in addition to wherever else it might be invoked.
  Trinity is read by every agent at session start regardless
  of prompt content; this is the strongest available delivery.
- **Cross-CLI parity ergonomics.** Where the pack ships content
  to all three CLI tools (Claude Code, Codex CLI, Antigravity CLI)
  and per-CLI prompt-injection logic does not yet exist, the
  shipped content may carry the rule directly to reduce
  per-CLI implementation overhead. This exception narrows as
  per-CLI injection mechanisms become available.

When in doubt, default to single-source authoritative + PM-chat
injection. Duplication requires a documented exception.

---

## Part 2 — Standard Project Documents

Every project should have all of these. Create them before writing any code.

<!-- DENY-LIST-CONTENT-START -->
| Document | Purpose | Who writes | Who updates |
|---|---|---|---|
| `ARCHITECTURE.md` | Architectural decisions, layer map, patterns, data models | Architect agent (kickoff) | Any phase that changes architecture |
| `docs/project/implementation-plan/` (per-entry `phase-N.md` tree + generated `_index.md`) | All phases with tasks, DoD, agent, risks — one `phase-N.md` per phase; `_index.md` is the generated serial order | PM chat + planner agent | Each phase adds a `phase-N.md` entry; never delete old phases |
| `docs/project/changelog/` (per-entry tree + generated `_toc.md`) | Permanent dated history of what was built — one `<ID>.md` per phase at phase completion plus one per release boundary; `_toc.md` is the generated readable index | PM chat | One entry per phase, after reviewer approval; coder proposes entry in completion report |
| `docs/project/backlog/` (per-entry tree + generated `_toc.md`) | Technical debt, deferred items, known gaps — one `<ID>.md` per item; `_toc.md` is the generated readable index | PM chat | Add/resolve; never delete items |
| `docs/project/groupings/` (per-entry tree + generated `_toc.md`) | Groupings of phases — pure-structure membership; one GRP-NNN.md per grouping; `_toc.md` is the generated readable index | PM chat | On grouping creation / membership change |
| `STATUS.md` | Current phase, phase table, groupings table, next actions — generated sections are `scripts/status-generate.sh` output; a marker-preserved hand section carries PM prose | PM chat or developer (hand section; generated sections regenerate only) | After every phase completion + per the regen trigger list in `docs/pack/PM-CHAT.md` § Groupings orchestration |
| `CLAUDE.md` | Project-specific rules for all CLI agents | PM chat | When new rules are established |
| `AGENTS.md` | Agent roster and routing table | PM chat | When agents are added or changed |
| `PACK-FEEDBACK.md` | Upstream feedback log to Pack Chat — observations, not solutions | PM chat | Continuously (append-only); delivered at workflow boundaries (Part 10) |
| `METHODOLOGY.md` | This file — project-agnostic methodology reference | Pack (v11) | When new standing decisions are made |
<!-- DENY-LIST-CONTENT-END -->

### Document hygiene rules (inviolable)

1. ARCHITECTURE.md and the per-entry implementation-plan tree (`docs/project/implementation-plan/`) are source of truth — they must reflect reality.
2. The changelog tree (`docs/project/changelog/`) is append-only — never edit old entries.
3. Backlog-tree (`docs/project/backlog/`) items are never deleted — mark resolved with a note.
4. STATUS.md is updated after every phase — stale status is worse than no status.
5. Agents must not modify `ARCHITECTURE.md` or the `docs/project/implementation-plan/`
   tree unless explicitly instructed in the prompt. `STATUS.md`, `PACK-FEEDBACK.md`,
   the per-entry backlog, changelog, and groupings trees, and all other root `.md`
   files are exclusively the PM chat's responsibility — no agent should write them,
   and no agent prompt should instruct them to. Include root `.md` file constraints in every coder prompt.
   `PACK-FEEDBACK.md` in particular is never written by any agent — it is the PM
   chat's feedback log to the upstream pack (see Part 10).
6. Every deferral comment (`// TODO(scope):`, `// KNOWN GAP(severity):`, `// VERIFY(source):`,
   or language-equivalent) must have a corresponding entry in the backlog tree
   (`docs/project/backlog/`). `TD-TBD` in any
   committed file is a defect — it means the PM chat has not yet processed the coder's
   deferred items report. See Part 7 for the full comment format and backlog procedures.

### RAG index hygiene

The PM chat's local-rag index (`mcp-local-rag`) holds embedding
chunks for files declared in the **RAG ingestion manifest** in
`docs/pack/PM-CHAT.md` § RAG ingestion manifest. The manifest is
authoritative: anything in the index but not in the manifest is an
**orphan**.

**Orphans are not benign.** A retired-path chunk that lingers in the
index is returned by future queries and cited as if it were current
content. The PM chat receives confidently-wrong retrievals — stale
guidance, dead paths, removed file references — with no signal that
the source is gone. This is worse than no RAG at all, because the
failure mode is invisible: the PM chat acts on retrieved chunks
without knowing they are orphans.

**The reconciliation procedure.** Every `/pm-startup` Step 4
reconciles the actual ingested set against the manifest:

- Orphans (in index, not in manifest) are auto-deleted via
  `local-rag.delete <path>`.
- Stale entries (manifest path whose source mtime exceeds the
  ingest date) are re-ingested.
- Missing entries (manifest path not in index) are ingested.
- The diff is reported in the startup summary
  (`RAG: N ingested, N stale, N orphans removed: [<paths>]`).

The procedure runs unconditionally on every startup — orphan removal
does not require user approval, since the manifest is the source of
truth and orphans are by definition outside it. See
`docs/pack/PM-CHAT.md` § RAG ingestion manifest for the per-project
manifest declaration. The same `list` / `delete` / `ingest` MCP
calls can be invoked manually outside `/pm-startup` (the
`CLI-PM-SETUP.md` companion doc covers MCP / RAG setup; copy it
alongside `METHODOLOGY.md` during install).

PM Chat reconciles the RAG manifest on every `/pm-startup` per Step
4 above and surfaces the result in the `RAG:` line of the startup
summary. No separate post-migration reconciliation procedure is
needed in v11+ — Step 4 is the single, always-on hygiene point.

**Triggers beyond `/pm-startup`.** Run reconciliation manually after
any of: pack version migration that retires or moves a file; manual
deletion or rename of a manifest-declared file; user observation of
stale or wrong-citation retrievals.


---

## Part 3 — Agent Roster

### When to use each agent

| Situation | Agent |
|---|---|
| Implementing a phase | `coder` |
| Reviewing code after implementation | `reviewer` |
| Architecture assessment, module boundaries, design decisions | `architect` |
| Mid-phase design correction (Trigger A or B met in Workflow 4) | `architect` |
| Planning what tests to write (see tester trigger below) | `tester` |
| Writing tests after planning | `coder` |
| Researching an external API before implementation | `docs-researcher` |
| Breaking down a complex phase (see planner trigger below) | `planner` |
| Proto3 schema design or review | `grpc-schema` |
| Full-codebase structural audit (see Part 6 cadence triggers) | `auditor` |
| Repo operations, branch-safe scripted edits, local automation | `repo-ops` |
| BACKLOG/STATUS updates, simple doc edits | standard CLI (no agent) or PM chat |
| BACKLOG item processing and comment updates | PM chat only (after user approval) |

### Reviewer vs. tester vs. auditor — when to use which

These three agents all touch code quality but serve different purposes at
different times. They are not interchangeable.

| Agent | Timing | Scope | Trigger | Output |
|---|---|---|---|---|
| `reviewer` | After every coder pass | One phase | Always — never skip | "Does this phase's code meet the plan?" |
| `tester` | Before complex implementation | One phase's test strategy | Conditional — see trigger below | "What tests should exist and how should they be structured?" |
| `auditor` | After substantial implementation (3+ phases) | Full codebase, all quality dimensions | Conditional — see Part 6 cadence triggers | "What systemic gaps exist across the whole codebase?" |

### Tester trigger rule

Invoke the `tester` agent *before* the coder when **any** of these is true:

1. The phase requires test infrastructure that is complex enough that leaving
   it to the coder's judgment risks getting it wrong — mocks, actors, async
   streams, UI test harness, gRPC test server setup.
2. The phase introduces a new testing pattern not yet established in the project
   (e.g., first UI test, first integration test, first gRPC handler test).
3. The PM chat is uncertain whether unit tests, integration tests, or UI tests
   are the right level of coverage for the phase.

If none of these apply, the coder writes tests as part of normal implementation
and the reviewer verifies them.

### Planner trigger rule

The planner check runs as part of Procedure 1 (phase gate check) in Part 7 —
before generating any coder prompt. Invoke the `planner` when **any** of these
is true:

1. The phase has more than ~5 tasks, or task dependencies within the phase are
   non-linear (one task must complete before another starts, and this is not
   already spelled out in the implementation plan).
2. The PM chat cannot map the implementation plan's phase description to
   discrete, independently verifiable tasks without ambiguity.
3. A coder has failed the same phase twice without meaningful progress and the
   cause appears to be task definition rather than architecture (an architecture
   cause triggers the architect via Workflow 4 instead).

### When NOT to use a CLI agent

- Planning and decision-making → PM chat
- Reviewing pasted agent output → PM chat
- Simple doc-only changes (STATUS, BACKLOG, typo fixes) → standard CLI or PM chat

### Session rules

- Each agent invocation is a new session. Never continue a coder session for a new phase.
- Reviewer sessions are always new. Never reuse a reviewer session for a second pass.
- Agents have no memory between sessions — every prompt must be self-contained.

### Rejected-alternative documentation rule (architect agent)

For any correctness-sensitive design decision — defined as a decision where choosing
the wrong pattern creates silent runtime failures, LSP violations, concurrency hazards,
or significant migration cost — the architect agent must:

1. Name every viable alternative that was considered
2. State why each alternative was rejected
3. State why the chosen approach is correct for this project's constraints

This documentation must appear in `ARCHITECTURE.md` at the decision site, not only in
a planning conversation. If an architect agent cannot name at least one rejected
alternative for a structural decision, that is a signal the decision space was not
fully evaluated.

This rule applies at project kickoff and at every mid-phase architect pass
(Trigger A, Trigger B from Workflow 4).

**Platform-specific prohibited patterns (architect agent):**
Certain platform-specific patterns are prohibited by default and require explicit
documented justification. These come from the loaded platform skills — for example,
`apple-architecture-core` prohibits type-erasure `.base` wrappers, contentless
`AsyncStream<Void>` fan-out, and ViewModels importing SwiftUI. The architect agent
must read the loaded skills and treat their prohibited-pattern lists as hard
constraints, not suggestions. If a prohibited pattern is chosen, document why the
recommended alternatives are insufficient for this specific case.

---

## Part 4 — Phase Structure

Each phase entry (`docs/project/implementation-plan/phase-N.md`) should follow this format:

```markdown
## Phase N — [Title]

**Goal**: One sentence describing what this phase delivers.
**Prerequisite**: Which prior phase must be complete.
> **Execution note**: (optional) deliberate deferral or ordering constraint.

### Tasks
#### N.1 — [Task title]
- **Problem / Goal / Success**: What is currently wrong, what the task must achieve,
  and what observable state confirms it is complete — describe outcomes and verifiable
  end states, not steps. Do not include implementation instructions.
- **Files created/modified**: list
- **Definition of done**: Measurable, verifiable criteria
- **Dependencies**: zero or more nested bullets, one per dependency. Each entry is
  either a phase epic (`phase-N`), a sibling or cross-phase task (`phase-N.M`), or
  a TD entry (`TD-NNN`). Trailing free-text after the ID is preserved as a
  human-readable annotation. Parser regex:
  `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+)(\s+(.*))?$`.
  Example:
  ```
  - **Dependencies**:
    - phase-3.1 (must complete schema before this task)
    - phase-7.4
    - TD-029
  ```

### Verification
Build/test command that proves the phase is complete.

### Agent
Which agent(s) to use for which tasks.

### Risks
| Risk | Severity | Mitigation |
```

`Target:` is optional; a release-cycle claim, when one exists, is set
per the impl-plan contract's `## Target semantics`.

When authoring a new phase entry, the PM chat asks two authoring
questions in the same step:

- The Workflow 7d membership ask — add the phase to an existing
  grouping, create a new grouping (Workflow 7), or leave it ungrouped
  (a deliberate "stays ungrouped" ruling records the phase in GRP-000).
- Whether the phase carries an optional `Target:` release-cycle claim
  (per the impl-plan contract's `## Target semantics`).

### Phase numbering rules

- Never renumber phases — phase numbers are referenced in code comments, CHANGELOG, and BACKLOG.
- To reorder execution, use execution notes (`> **Execution note**:`), not renumbering.
- Add a new phase as a new `phase-N.md` entry; the generated `_index.md` records its serial order.
- Fractional phases (2.1, 2.2) only during early architecture work — use whole numbers after that.

### Multi-part phases

When a planning agent recommends splitting a phase into sequential implementation
chunks, use **Part** as the term for each chunk — never "pass." "Pass" is a reserved
term for the coder/reviewer cycle counter within a single coder or fix-cycle prompt.

**In the `phase-N.md` entry:** Label each chunk as a sub-section within the phase:

```markdown
### Part 1 — [Subtitle]
...tasks, files, definition of done...

### Part 2 — [Subtitle]
...tasks, files, definition of done...
```

**Report headers for multi-part phases:** Append `, Part [M]` to the phase title
placeholder. The pass counter resets to 1 at the start of each new part.

| Report type | Header format |
|---|---|
| Coder (initial) | `Phase [N] — [Phase title], Part [M] — Coder Report, Pass 1` |
| Reviewer | `Phase [N] — [Phase title], Part [M] — Reviewer Report, Pass [N]` |
| Fix cycle coder | `Phase [N] — [Phase title], Part [M] — Fix Cycle Coder Report, Pass [N]` |

A single-part phase uses the existing header format unchanged — do not append `, Part 1`
when there is only one part. The `, Part [M]` label is only added when the phase has
been explicitly split into multiple sequential parts by a planning agent.

---

## Part 5 — Standard Workflows

> **Prompt templates** for each workflow step are in `docs/pack/prompts/<agent>.md`.
> Templates are starting points — the PM chat customizes each prompt based on project
> context, current phase, and recent review results.

### Workflow 1 — Starting a new project

1. Create GitHub repo, clone locally
2. Copy the unified template and supporting docs per QUICKSTART.md Steps 1–4:
   copy `project-template/` (which includes `docs/pack/prompts/`), copy
   `METHODOLOGY.md` from `supporting-docs/`, remove conditional files, fill
   in context file placeholders, run `./scripts/bootstrap.sh`
3. Create the per-entry stream trees (`docs/project/backlog/`, `docs/project/changelog/`, `docs/project/groupings/`) and seed `STATUS.md` with `bash scripts/status-generate.sh` (creates it with the generated sections and the hand-section placeholder)
4. Commit all template and doc files before writing any code
5. Set up the PM chat — setup steps are in the pack repo at
   `<pack-clone>/supporting-docs/SETUP-NEW.md` Step 10 (choose Claude Desktop,
   Claude Code CLI, Codex CLI, or Antigravity CLI)
6. Planning conversation with PM chat → establishes architecture, phase plan
7. PM chat generates: `ARCHITECTURE.md`, the per-entry implementation plan
   (`docs/project/implementation-plan/`); fills in
   remaining `[PLACEHOLDER]` sections in context files using `PLATFORM-SKILLS.md`;
   writes the **Active skills** line in the Skill loading section of `CLAUDE.md`,
   `AGENTS.md`, and `GEMINI.md` — listing the skills derived from
   `PLATFORM-SKILLS.md` for this project's type
8. If using Claude Desktop: sync GitHub connector
9. Generate `SETUP.md` and `AGENT_KICKOFF.md` using Templates 13 and 14
   (PM chat fills them in from the planning conversation)
10. Run architect agent with AGENT_KICKOFF.md to produce `ARCHITECTURE.md` stubs

### Workflow 2 — Per-phase execution (standard coder → reviewer cycle)

```
1. Claude Chat generates coder prompt for Phase N
2. Developer: cd /path/to/your-project && ./agent-run.sh claude --agent coder → paste prompt
3. Agent runs and reports completion
4. Developer: ./agent-run.sh claude --agent reviewer → paste reviewer prompt (generated by Claude Chat)
5. Developer pastes reviewer output into Claude Chat
6. Claude Chat analyzes:
   - ✅ ready to commit → developer commits and pushes
   - ❌ needs fixes → Claude Chat generates fix prompt → new coder session → repeat reviewer
7. Developer updates STATUS.md, syncs GitHub connector
```

> **agent-run.sh:** All agent invocations use `./agent-run.sh <cli> --agent <name>` rather than
> calling the CLI directly. The script automatically applies the correct flags per agent type:
> read-only agents (`architect`, `reviewer`, `planner`, `tester`, `docs-researcher`,
> `grpc-schema`, `auditor`, `auditor-architecture`, `auditor-code`, `auditor-docs`,
> `auditor-security`, `auditor-tests`, `auditor-ui`, `auditor-ops`) receive permission
> bypass and git write protection. Write agents (`coder`, `repo-ops`) pass through with
> default permissions. Direct CLI invocation still works for one-off use; the script ensures
> consistent flags across the team. Run `./agent-run.sh --help` for the full roster and
> per-CLI flag details.

> **Cycle invariant — reviewer always runs.** Step 4 (reviewer)
> runs after every step-3 coder report without exception. The PM
> chat must not propose skipping the reviewer for any reason —
> "small change," "comment-only," "tests pass," "coder confirmed
> correct," or "prior reviewer already approved" are all the
> conditions under which the reviewer is most needed. The reviewer
> exists precisely to catch what "tests pass" does not:
> architecture compliance, security posture, intent alignment.
> The only bypass is an unprompted user instruction to skip;
> PM chat never suggests it.

### Workflow 3 — Per-phase execution (with external API research)

For phases integrating external APIs or making architectural decisions:

```
1. docs-researcher agent reads official API docs (prompt from PM chat)
2. Developer pastes research report into PM chat
3. PM chat identifies discrepancies, generates a `phase-N.md` correction prompt
4. Developer runs correction in standard claude CLI, commits
5. (Optional) tester agent generates test specification → PM chat incorporates into coder prompt
6. Standard coder → reviewer cycle
```

### Workflow 4 — Fix cycle (when reviewer finds issues)

```
1. Developer pastes reviewer output into PM chat
2. PM chat applies triage protocol (see below) to every ❌ and ⚠️ finding
3. PM chat checks for architect trigger (see below) before generating any fix plan
4. If NO trigger: PM chat presents fix plan → developer approves → coder fix pass → reviewer (step 1)
5. If TRIGGER: PM chat identifies root cause → presents architect pass plan → developer approves
   → architect agent runs (read-only, proposes doc changes) → PM chat presents proposed changes
   → developer approves doc changes → PM chat applies them via Desktop Commander or manual
   → PM chat presents coder fix plan covering both reviewer issues and new arch direction
   → developer approves → coder fix pass → reviewer (step 1)
6. PM chat also checks for planner trigger (Trigger P-A / P-B / P-C; see
   "Planner trigger conditions (mid-phase)" below). If a planner trigger
   fires: PM chat surfaces the trigger and a candidate planner pass plan
   → developer approves → planner agent runs (`planner.md` Variant: standard)
   producing an updated `phase-N.md` task block
   → PM chat presents the proposed task-block change → developer approves
   → PM chat applies the change → PM chat presents coder fix plan against
   the revised task block → developer approves → coder fix pass → reviewer (step 1)
7. Items that pass the deferral test (see triage protocol): PM chat generates a backlog-tree
   addition (`docs/project/backlog/`) with explicit named blocker → developer runs in standard claude
```

> **Cycle termination.** The fix cycle terminates when the
> reviewer returns Verdict: Ready to commit AND no architect
> trigger fires per the Trigger A / Trigger B checks. A cycle
> that fails to terminate after 3 coder passes against the same
> phase ALWAYS triggers Trigger A and the architect pass — the
> architect either resolves the root cause (allowing the cycle
> to converge in the next coder pass) or escalates to the user
> for re-scoping. There is no infinite-cycle path; either
> reviewer-PASS terminates, or the architect pass terminates by
> re-scoping the work.

> **The PM chat does not execute fix passes directly.** After receiving reviewer output,
> the PM chat presents a plan and waits for approval before generating any agent prompt.
> The coder agent executes the fix; the PM chat does not.

> **Present proposed doc changes and wait for the user to read.**
> Show the user exactly what the architect proposes to change.
> The PM chat WAITS for the user to read the architect's full
> report before suggesting any follow-on step — do not auto-
> advance to the next step, do not auto-stage changes, do not
> propose "ready to commit" until the user has signaled they
> have read the report. Get explicit approval for each change
> before applying it.

#### PM chat triage protocol — reviewer findings

The reviewer's **"Ready to commit"** verdict means all ❌ items are resolved from the
reviewer's perspective. It is not the PM chat's bar. The PM chat evaluates every ❌ and
⚠️ finding independently before deciding whether to commit or fix further.

**The default is to fix. Deferral requires a named blocker.**

**Every ❌ item** must appear in the fix prompt. No exceptions and no investigation needed
— ❌ items are never deferred to BACKLOG.

**Every ⚠️ item** requires a blocker investigation before any deferral decision. Ask:

1. Is there a concrete, named external blocker? Valid examples:
   - An external system or API not yet accessible because integration is planned for a later phase
   - A design decision that requires a docs-researcher or architect agent run to resolve
   - A later phase entry (`docs/project/implementation-plan/phase-N.md`) explicitly designated for this work
2. Would fixing it require scope large enough to justify its own phase — one that would
   need its own docs-researcher or architect run?

If neither condition applies, the item goes into the fix prompt alongside the ❌ items.
"It is minor," "we can revisit it later," and "it is not blocking the build" are not
valid deferral reasons.

**When deferral is the correct decision:**
Create a BACKLOG entry with an explicit, named blocker. The blocker statement must be
specific enough that a future reader can determine when the blocker is no longer active.
Vague blockers ("needs more thought," "revisit later") are not acceptable. If the PM chat
cannot name the specific blocker, the item is not actually blocked — put it in the fix prompt.

**Fix prompts follow the coder fix-cycle pattern** (`coder.md` Variant: fix-cycle). Each entry describes what is wrong and what correct
behavior looks like — not how to fix it. No pseudocode, no implementation steps. This
applies regardless of how obvious the fix appears.

#### Architect trigger conditions

Check these after every reviewer pass. Either condition is sufficient to trigger an
architect pass before the next coder fix pass.

**Trigger A — Repeated coder runs without resolution:**
The coder agent has run 3 or more times since the phase started (or since the last
architect pass), AND the reviewer still identifies ❌ or ⚠️ issues.

**Trigger B — Regression or issue count increase:**
The reviewer report shows either:
- Any item that was previously ✅ is now ❌ or ⚠️ (regression), OR
- The number of new ❌/⚠️ issues introduced in this pass is greater than in the
  previous pass — whichever count is larger

> **Surface mechanical-looking trigger hits explicitly.** Even
> when the trigger is technically met but the remaining issue
> looks clearly mechanical (e.g., a missing test with no
> architectural ambiguity), the PM chat must surface the
> trigger check explicitly to the user, state its assessment of
> whether a true architectural problem exists, and get explicit
> approval before proceeding with or waiving the architect pass.
> Never silently skip the check.

> **Why this matters:** A coder running more than twice without clearing all issues,
> or a coder introducing more issues than it fixes, signals that the problem is
> architectural — the implementation plan or design is missing a constraint, has an
> ambiguity, or is actively working against the fix. More coder passes won't fix this;
> an architect pass that corrects the docs first will.

#### What the PM chat does when a trigger fires

1. **Identify root cause** — based on the pattern of reviewer findings, explain to the
   user what design issue is causing recurring failures. Be specific: name the missing
   rule, the ambiguous constraint, or the incorrect architectural assumption.
2. **Propose an architect pass** — describe what the architect agent will read and what
   doc changes are expected. Get explicit user approval before proceeding.
3. **Run the architect agent** — read-only pass using `architect.md` Variant: mid-phase. The agent reads
   `ARCHITECTURE.md`, the relevant `docs/project/implementation-plan/phase-N.md` entry, `CLAUDE.md`, `AGENTS.md`, and the
   specific reviewer findings. It proposes corrections to those docs as text output —
   it does not write files.
4. **Present proposed doc changes** — show the user exactly what the architect proposes
   to change. Get explicit approval for each change before applying it.
5. **Apply approved changes** — PM chat applies via Desktop Commander or outputs for
   manual application. Commit the doc changes before the coder fix pass.
6. **Generate coder fix pass** — using `coder.md` Variant: fix-cycle, incorporating both the reviewer's
   open issues and the new architectural direction. Present plan, get approval, then
   developer runs it.

> **CLAUDE.md and AGENTS.md changes:** The architect agent may propose changes to
> `CLAUDE.md` or `AGENTS.md` only if the root cause cannot be addressed by fixing
> `ARCHITECTURE.md` or the `docs/project/implementation-plan/` tree alone. These require an additional
> explicit user approval beyond the general architect pass approval.

#### Planner trigger conditions (mid-phase)

Sibling to the architect trigger conditions above, three
mid-phase planner triggers cover task-level revision needs:

- **Trigger P-A — Task-definition ambiguity surfaced by coder.**
  The coder's report names a task that "could not be completed
  as specified" because the task description is ambiguous — not
  missing data, not architectural issue, but a task-wording
  problem. PM chat surfaces the ambiguity to the user AND a
  candidate planner pass; user approves before the planner runs.
- **Trigger P-B — Architect output names "planning pass needed"
  as the follow-up.** When the architect pass concludes "the
  design is sound; the task breakdown needs revision," PM chat
  invokes the planner with the architect's output as input.
- **Trigger P-C — Task-ordering revision discovered mid-phase.**
  When coder mid-phase discovers that task B's preconditions
  require task A's output (and the original plan had them
  parallel or reversed), PM chat surfaces this to the user AND
  a candidate planner pass to re-sequence.

For each trigger, the planner pass produces an updated
`phase-N.md` task block; PM chat presents to
user for approval before re-running the coder.

**Planner-vs-architect demarcation:** A "task-definition
ambiguity" (P-A) is a planning problem — the task wording is
unclear about the contract or the deliverable. A "design
problem" is an architecture problem — the contract itself is
wrong or incomplete. If a coder reports both, run the architect
trigger first (architect resolves the design problem; planner
then re-shapes tasks under the corrected design). Never run
P-A in parallel with an architect trigger — sequencing matters.

### Workflow 4.5 — Large-phase development pipeline (size-tiered)

This is the project's one official, size-tiered standard for developing a
phase. It names a single development pipeline and a mechanical test for how
much of that pipeline a given phase must run. The pipeline consolidates and
orders pieces that already exist elsewhere in this methodology (the agent
roster and its triggers, the fix cycle, the audit checkpoints) plus the
execution-half worktree orchestration documented in `docs/pack/PM-CHAT.md`;
it adds the named adversarial-review spine and the up-front size tier.

#### The pipeline (full chain, in order)

1. **Researcher — first, before the first architect (ALWAYS for a large
   phase).** For a large phase the INTERNAL `docs-researcher` (the project
   codebase and docs inventory plus the blast-radius census across the phase's
   surfaces) ALWAYS runs first; the EXTERNAL `docs-researcher` (CLI, tool,
   framework, or API documentation verified against authoritative sources)
   runs per-need. For a small phase the researcher set is elective. In both
   sizes `docs-researcher` is the only role that may be reused for a
   reconciliation pass (it does factual inventory, not design).
2. **Architect** → the phase design, including the REQUIRED
   parallel/dependency map (which phase tasks run in parallel isolated
   worktrees versus serial) and the rejected-alternative documentation (the
   architect rule in Part 3). The architect refines the large/small
   classification for this phase (the PM chat makes the up-front call at the
   phase gate; see "Who classifies" below). The architect also runs the
   **cross-entry collision scan** (below) before the design closes.

   **Cross-entry collision scan (design-time).** After the researcher
   produces the phase's blast-radius set (the enumerated repo-relative
   surfaces the phase will touch — a researcher output for any
   reference-heavy structural change), the architect intersects THIS
   phase's blast-radius set against the `File/Symbol` surfaces of every
   OPEN TD and every other not-started/in-progress phase, and records the
   result (collision / none) with the surfaces compared. The scan keys on
   the STRUCTURED surface fields (repo-relative paths), not free-text
   prose, so at least one side of any pair is parseable. A shared surface
   is a "coordinate" signal, not a "forbidden" one: two entries may
   legitimately co-edit a file (sequencing handles it). Where a collision
   is found, the architect names the colliding entries and the shared
   surface so the PM chat can sequence them; an unresolved collision is a
   redirect signal at the design gate, before any coder runs.
3. **Adversarial architect review** — a fresh, clean-context `architect`
   instance that loads the `architecture-review` skill → PM-chat triage of
   the findings → reconciliation architect (a FRESH instance, only if the
   review returns NEEDS-REWORK); loop until READY. Governed by the
   Reconciliation-instance independence rule (a fresh instance, never the
   original author nor the adversary).
4. **User design review** — the design gate; present the proposed design and
   wait for the developer to read and approve.
5. **Planner** → the implementation-ready plan (the `phase-N.md`
   task block, or a multi-part phase split), including its OWN
   parallel/dependency map.
6. **Adversarial planner review** — a fresh `planner` instance that loads
   the `planning` skill → triage → reconciliation planner (FRESH, only if
   NEEDS-REWORK).
7. **User planner-to-coder gate** — the approval gate before any coder
   prompt.
8. **Parallel worktree coder waves** — scheduled off the parallel/dependency
   map: disjoint-file phase tasks run as concurrent `coder` agents, each
   commit's cycle in its own per-commit workspace (the PM-chat-created
   commit workspace); same-file tasks serialize. Each commit's
   bounded review/fix cycle (the Workflow 4 fix cycle above — the Trigger
   A/B architect and Trigger P-A/P-C planner mid-cycle escalations plus the
   cycle-termination invariant) runs inside its commit workspace; the patch
   is produced only after the review is clean; patches apply to the
   canonical tree sequentially (atomic per patch) with the conflict protocol
   (STOP and re-spawn fresh, never hand-merge). Superseded design and plan
   docs are deleted as the pipeline iterates; the audit set is preserved
   into the implementation-record area. The execution-half mechanics
   (worktree isolation, merge-back, parallel waves, the conflict protocol,
   report preservation, the live-workspace ask gate) live single-source in
   `docs/pack/PM-CHAT.md` — this stage references them rather than
   restating them.
9. **Optional post-implementation audit** (large phase, developer-elective)
   — the `auditor` parent and its read-only cluster subagents (Workflow 5 /
   Part 6), run after a large multi-task phase lands, to catch systemic gaps
   the per-commit reviewer does not.

For a large phase the two adversarial passes (stages 3 and 6) are MANDATORY —
they are the MINIMUM (at least two; additional architect or planner rounds are
added when larger gaps are found, the escalation detail in Part 3), never
elective. The reconciliation after each (stages 3 and 6) runs ONLY when that
adversarial pass returned NEEDS-REWORK — a logical consequence (no findings ⇒
nothing to reconcile), not a discretionary skip.

#### The size criterion (signals, then consequence)

Five phase-size signals, each a yes/no test against the phase plan or the
project tree (not a vibe):

- **P1 — launch / release-gate.** The phase is a release blocker for the
  current milestone, or the developer names it release-gating.
- **P2 — cross-surface.** The phase's edit-set spans two or more of: app or
  source modules; gRPC or proto schema; a public API or contract; build, CI,
  or deploy configuration; test infrastructure; architecture docs. (Measured
  from the phase plan's files-created/modified list.)
- **P3 — blast-radius.** The phase changes a contract, schema, or interface
  that three or more surfaces depend on — the load-bearing test. (A required
  `docs-researcher` blast-radius census is a tie-break hint that nudges a
  borderline call toward large, not a co-equal test.)
- **P4 — structural.** The phase introduces a new architectural pattern or
  boundary, a schema migration, a new external integration, or a new module
  or subsystem — not a localized change inside an existing module.
- **P5 — task-count / non-linear deps.** The phase has more than ~5 tasks,
  or non-linear intra-phase dependencies (the planner trigger threshold in
  "Planner trigger rule", reused here as a size signal).

The consequence: a phase is a **LARGE PHASE — the deterministic flow above,
both adversarial reviews mandatory** — if P1 (launch/release-gate) fires
alone, OR if two or more of the five signals fire. Otherwise the phase is a
**SMALL PHASE** and runs the **base flow** (optional researcher → architect
→ planner per the existing planner trigger → parallel coder waves with the
bounded review/fix cycle); there the two adversarial passes are elective (at
developer election). A single non-launch signal alone (for example, one new
pattern inside one module) does not make the phase large.
**Tie-break: when genuinely in doubt, treat the phase as LARGE** — the
rigor is the conservative error.

Why launch/release-gate stands alone: a release blocker is the one axis
where a missed adversarial pass ships into the release irrecoverably. Every
other signal alone is recoverable at base-flow rigor (the Trigger A/B
architect escalation and the cycle-termination invariant catch a mid-cycle
design failure). The mandatory-adversarial trigger is sized to the cost of
being wrong, not to the mere presence of a structural touch.

#### Who classifies the phase

The PM chat applies the size criterion at the PHASE GATE — the same place
the planner-trigger check already runs (Procedure 1) — using the five
mechanical yes/no signals. If an architect is spawned, it REFINES the
classification (it may surface a signal the up-front read missed, escalating
small → large; the tie-break-to-large rule governs ambiguity).

#### Complementarity with the existing triggers

The up-front size tier and the existing mid-cycle situational triggers (the
Trigger A/B architect, Trigger P-A/P-C planner, and tester triggers above)
COEXIST. The size tier classifies the phase up front; the mid-cycle triggers
still fire inside the cycle regardless of tier. The standard ADDS the
up-front tier — it does not replace the mid-cycle triggers.

### Workflow 5 — Full-codebase audit (auditor agent)

Full-codebase audits run the `auditor` parent agent, which spawns up to seven
read-only subagents (one per cluster) and consolidates their reports. See
the `audit-methodology` skill (loaded by the auditor) for cluster definitions,
file scopes, severity scale, pass/fail thresholds, and report format.

```
1. PM chat decides an audit is warranted (per Part 6 cadence triggers below)
2. PM chat determines which subagents to skip per audit-methodology rules 44–47:
   - Skip auditor-ui for server-only projects with no UI layer
   - Skip auditor-tests only for the first audit of a brand-new project
   - auditor-ops always runs
   - The other four clusters always run
3. PM chat generates the auditor invocation prompt using the auditor template
   in `docs/pack/prompts/auditor.md` (`## Variant: standard`), listing the
   skip set explicitly as prose
4. Developer runs the auditor:
   - Claude:      ./agent-run.sh claude --agent auditor
   - Codex:       ./agent-run.sh codex  --agent auditor
   - Antigravity: ./agent-run.sh agy    --agent auditor [--skip auditor-ui[,auditor-tests]]
5. Developer pastes the consolidated audit report into the PM chat
6. PM chat processes the report per Part 6 (BACKLOG intake rules below)
7. Standard coder → reviewer cycle for each fix prompt the audit generates
```

**Re-running a single subagent.** After fixing a Critical or Major finding,
the developer may re-run the owning subagent in isolation to verify the fix
without paying for a full audit (per `audit-methodology` rule 70):

```
./agent-run.sh claude  --agent auditor-security
./agent-run.sh codex   --agent auditor-security
./agent-run.sh agy     --agent auditor-security  (runs as a single default-mode session)
```

The single-subagent path is the same script entry point — no special flag.
The auditor parent is bypassed; the subagent reports directly.

### Workflow 6 — Adding a new feature to a stable project

```
1. PM chat: describe feature → discussion to scope and document it
2. PM chat generates updates to ARCHITECTURE.md and the per-entry implementation-plan tree (new `phase-N.md` entries)
3. Developer runs update prompts in standard claude, commits doc changes, syncs
4. Run Workflow 2 for each new phase
```

### Workflow 7 — Grouping creation and maintenance

Groupings are pure-structure membership lists over phases — one
GRP-NNN.md entry per grouping in the `docs/project/groupings/`
per-entry tree (contract: `docs/project/groupings/_rules.md`). A
grouping stores no status and no target; every display derives both at
read time from the member phases' `Status:` / `Target:` fields. Queries
run through `bash scripts/groupings.sh` (list / list-membership /
deps [--deferral] / order / shared-with); the dashboard regenerates
through `bash scripts/status-generate.sh`.

#### 7a — Derive groupings from the phase plan

```
1. PM chat reads the implementation-plan tree and drafts CANDIDATE
   groupings using docs/pack/prompts/grouping-from-phases.md
   (Variant: from-phases — carries the per-Kind recognition table)
2. User reviews the drafts — edits, merges, rejects; the user finalizes
   every candidate; nothing is auto-written
3. PM chat writes the approved GRP-NNN.md entries in the contract's
   closed serialization, then runs the 7c regeneration chain
```

#### 7b — Ingest an external grouping source

```
1. Developer pastes or attaches the external content — any format; the
   pack never parses external formats mechanically
2. PM chat translates: it asks clarifying questions where the source
   names a grouping without identifying member phases; task-level
   references roll up to their parent phases; duplicates collapse;
   the two-member minimum holds at the phase level after rollup
3. Draft GRP-NNN.md bodies in the closed serialization -> user approves
   -> PM chat writes the entries + runs the 7c regeneration chain
```

The prompt template is `docs/pack/prompts/grouping-from-external.md`
(Variant: from-external). Planning-session deliverables (narrative
PRDs, journey docs, feature inventories) and project-provided planning
docs arrive through this same path.

#### 7c — Membership change, dissolution, supersession

The regeneration chain after ANY grouping edit: edit the entry →
regenerate `_toc.md` → regenerate STATUS.md
(`bash scripts/status-generate.sh`) → re-check grouping-affinity
placement in the implementation-plan `_index.md` (ordering rules: the
impl-plan contract Ordering section + `docs/pack/PM-CHAT.md`
§ Groupings orchestration).

Dissolution = delete the entry file. Dropping below two members without
the exception field fails validation; nothing auto-edits membership.

**Supersession procedure** — runs in the same session that flips a
phase `Status:` to `superseded` (supersession is terminal per the
impl-plan contract); every edit lands with per-edit user approval:

```
1. Run bash scripts/groupings.sh list-membership phase-N — present
   every membership before touching anything
2. Surface the phase's outgoing dependency edges (deps --deferral
   carries the attribution) and OFFER re-pointing each dependent's
   Blockers / Dependencies / Prerequisite at the Superseded-By target
   — per-edit user approval
3. OFFER removing the phase's member rows; record every removed
   membership in the session's changelog entry (docs/project/changelog/)
4. Name the consequences before writing: removal to one member requires
   Single-member exception: (or dissolve); removal to zero dissolves
   (delete the file); declining either arm leaves the row in place — a
   legal steady state (the rollup excludes superseded members; s=N and
   the [N superseded] flag keep the row honest)
5. Judge on the POST-flip state. A grouping the flip itself completed
   (complete with s >= 1) is a finished snapshot — default to KEEPING
   its rows, so the snapshot's constitution stays visible
6. GRP-000 rows follow the same offer; removal is the recommended arm
   there (the ledger has no dissolution consequence, and its counts
   stay clean)
```

#### 7d — The phase-creation membership ask

When authoring a new `phase-N.md` (Part 4), ask exactly one membership
question: add the phase to an existing grouping, create a new grouping
(this workflow), or leave it ungrouped. A deliberate "stays ungrouped"
ruling records the phase as a member of GRP-000 — the reserved
declared-ungrouped ledger. GRP-000 is created on its first ruling,
never pre-created (absence means zero rulings). Skip the ask when the
phase is already a GRP-000 member — a declared ruling is never
re-asked. The same authoring step asks whether the phase carries an
optional `Target:` release-cycle claim (impl-plan contract `## Target
semantics`).

#### Derived status — the rollup every surface computes

Superseded members are excluded from the ACTIVE set; every other
member — including one whose `Status:` is unreadable — is active.
D = done actives; A = active count; percent = floor(100 × D / A); an
unreadable member never renders a clean fraction. The first matching
row wins:

| Member set | Derived status |
|---|---|
| no members at all | `unknown` |
| any member unreadable — dangling ref, part-typed file, missing / empty / out-of-enum `Status:` | `unknown` |
| every member superseded | `superseded` |
| every active member done | `complete` |
| some non-done actives, all of them deferred | `deferred` |
| a deferral alongside other unfinished active work | `blocked` |
| every non-done active member blocked | `blocked` |
| nothing done; every active member not-started or blocked | `not-started` |
| any other mix | `in-progress` |

Every machine rollup row carries four counters over the full member
set — b / d / s / u = blocked / deferred / superseded / unreadable
members. A display flag `[N <family>]` renders exactly when its counter
is positive, in the fixed order b, d, s, u. GRP-000 is exempt — the
ledger derives no status and no target.

A grouping's derived target is the maximum of its declaring members'
`Target:` claims on the contract's ordinal scale — the declarer set and
the poison rules live in `docs/project/groupings/_rules.md` `## Derived
status and target`. The target renders in the `list` Target column, the
`list-membership` detail-header suffix, and the STATUS.md groupings
table.

#### Scheduling guidance

- **Work-halt advisory.** When every grouping containing phase P
  derives `blocked` via deferral, P is scheduled only if the
  cross-grouping-unblock predicate holds — P has an outgoing dependency
  edge into a phase whose membership includes a healthy grouping — or
  the user directs otherwise; at that decision moment surface the
  cascade view (`bash scripts/groupings.sh deps --deferral`). A phase
  with any healthy membership is never advised against. Advisory only —
  no validator enforces scheduling.
- **Deferral flip.** On any deferral flip —
  a phase `Status:` newly set to `deferred` —
  the PM chat surfaces the cascade-computed affected set and
  immediately proposes the matching `_index.md` re-order (completable
  groupings' phases ahead of phases whose every membership is
  deferral-poisoned, wherever the declared dependency edges permit);
  the re-order lands on user approval.
- **Declared edges only.** The cascade and the unblock predicate read
  the declared dependency fields (`Blockers` / `Unblocks` /
  `Dependencies` / `Prerequisite`); a dependency stated only in prose
  is invisible to them.
- **Superseded silence.** Superseded phases are excluded from every
  ungrouped count (the pm-startup M and K counts, the STATUS.md pending
  cell); a deferral never silences a phase — that work is still owed.

STATUS.md regeneration triggers: the trigger list in
`docs/pack/PM-CHAT.md` § Groupings orchestration.

### Workflow → template cross-reference

Each workflow uses one or more pack-shipped prompt variants from
`docs/pack/prompts/` (one file per agent, one `## Variant:` H2 per
variant). The table below enumerates every pack variant a workflow
touches. Project-generated files that serve as prompts (notably
`AGENT_KICKOFF.md` for Workflow 1 step 10) are noted inline in the
relevant row. Customize every variant for the current project and
phase before pasting.

| Workflow | Prompts to use |
|---|---|
| Workflow 1 — New project | `pm-chat.md` Variant: kickoff (developer-pasted to start the PM chat); `pm-chat.md` Variant: generate-setup and `pm-chat.md` Variant: generate-agent-kickoff (PM-chat self-prompts that produce `SETUP.md` and `AGENT_KICKOFF.md`); architect agent invocation with `AGENT_KICKOFF.md` (step 10 — `AGENT_KICKOFF.md` is project-generated, not a pack variant) |
| Workflow 2 — Per-phase execution | `coder.md` Variant: standard; `reviewer.md` Variant: standard; `coder.md` Variant: fix-cycle (if reviewer finds issues) |
| Workflow 3 — External API research | `docs-researcher.md` Variant: standard; (optional) `tester.md` Variant: standard; then Workflow 2 prompts for the implementation cycle |
| Workflow 4 — Fix cycle | `coder.md` Variant: fix-cycle (main); `architect.md` Variant: mid-phase (when Trigger A or B fires); `planner.md` Variant: standard (when Trigger P-A, P-B, or P-C fires); `reviewer.md` Variant: standard (re-runs the cycle after each fix); `pm-chat.md` Variant: backlog-status-update (for items deferred to BACKLOG) |
| Workflow 5 — Full-codebase audit | `auditor.md` Variant: standard — a single auditor prompt that spawns the right subagents, replacing the legacy per-dimension audit prompts; `pm-chat.md` Variant: backlog-status-update (for BACKLOG intake from findings); Workflow 2 prompts for each fix prompt the audit generates |
| Workflow 6 — New feature | PM chat updates `ARCHITECTURE.md` and the `docs/project/implementation-plan/` tree directly (no pack variant); `pm-chat.md` Variant: backlog-status-update (if the feature adds BACKLOG entries); then Workflow 2 prompts for each new phase |
| Workflow 7 — Groupings | `grouping-from-phases.md` Variant: from-phases (7a); `grouping-from-external.md` Variant: from-external (7b); both are PM-chat-mediated drafting templates — the user finalizes every candidate before the PM chat writes an entry |

---

## Prompt Authoring Principles

These principles apply to every prompt the PM chat generates and to
every task entry written in a `phase-N.md` plan entry. They are not style
guidance. They govern what information belongs in a prompt and what
does not.

### About `docs/pack/prompts/`

The `docs/pack/prompts/` directory contains one file per agent. The PM
chat reads `<agent>.md` on demand, locates the requested variant by its
`## Variant: <slug>` heading, copies the body, and customizes it for
the task at hand.

These templates are starting points. The PM chat customizes phase
numbers, file names, scheme names, and verification commands per use;
sections that don't apply to the current phase are removed. Every
variant body follows the labeled-section convention defined in the
subsections below.

### The core rule: describe the problem, goal, and success criteria — not the solution

Every prompt must answer:

1. **Problem** — the root cause, described at the category level,
   not a single symptom. Include enough scope that the agent
   recognizes all instances within the files-in-scope list — but
   do not describe the solution.
2. **Goal** — what correct behavior looks like across the affected
   scope when the prompt is complete. Describe the outcome, not the
   steps.
3. **Success criteria** — the observable, verifiable state that
   confirms the goal is achieved. What can be checked to know the
   prompt's work is complete? At the `phase-N.md` task
   level this maps to the task's "Definition of done."

Plus the surrounding sections: Context, Required reading, Files in
scope, Constraints, Out of scope, Completion report.

A prompt must never contain:
- Pseudocode or implementation sketches
- Framework, pattern, or library choices (unless already mandated
  in ARCHITECTURE.md)
- Step-by-step "how to" instructions
- Proposed solutions that substitute for agent judgment

**Why this rule exists.** Prescriptive prompts bypass the agent's
ability to find the right approach from full filesystem context. The
PM chat has not read every file in the repo — the agent has. The PM
chat states what is wrong, what correct behavior looks like, and
what confirms the work is complete. The agent determines how to
achieve it.

### Mandatory section structure (canonical order)

Every prompt template variant — every `## Variant: <slug>` block in
every file under `docs/pack/prompts/` — uses bolded inline labels
in the following order:

1. **Role + agent identity** (one line; the variant heading + one-
   line italic descriptor satisfies this)
2. **Context:** state of the world this prompt fires in (include only what the agent cannot infer from reading ARCHITECTURE.md)
3. **Required reading:** documents and files the agent must read
   before starting; distinguish read-for-understanding vs. files in
   scope
4. **Problem:** as defined above
5. **Goal:** as defined above
6. **Success criteria:** as defined above
7. **Files in scope:** explicit list the agent may create or
   modify; the unplanned-file-modifications escape valve applies
8. **Constraints:** read-only / write rules, verification commands,
   deferral-comment rules, root-md prohibition where applicable
9. **Out of scope:** explicit list of what the prompt is **not**
   asking for, when relevant (omit if redundant with Constraints)
10. **Completion report:** what the agent returns, **always
    file-based** — see "File-based reporting" below

**Label format.** Bolded inline markdown labels —
`**Problem:**`, `**Goal:**`, `**Success criteria:**`, etc. — placed
at the start of the section content. H2 / H3 markdown headers are
not used at the section level: a multi-section prompt body
rendered as a forest of `##` headings is harder to scan and creates
a heading-level conflict with the variant's own `##` heading.

**Per-variant application.** The convention attaches to each
`## Variant: <slug>` block, not to the file as a whole. Different
variants of the same agent are distinct prompts and may differ in
Constraints, Files in scope, and Completion-report shape, but all
contain the triad and follow the canonical order.

**One triad per prompt — not per task.** A prompt with multiple
tasks (e.g., a coder phase with three implementation tasks; a fix-
cycle with five reviewer findings) lists the tasks under **Goal**.
Per-task **Definition of done** survives inside the task list as
task-scope detail; it does not replace the prompt-level **Success
criteria**.

**Single documented exception.** `pm-chat.md` Variant: kickoff is a
context handoff to the PM chat, not an agent-task prompt. It carries
a `**Convention exception:**` callout immediately after its italic
descriptor and does not follow the labeled-section convention. Every
other variant in `docs/pack/prompts/` follows it.

### Format requirements vs. solutions

No agent's prompt may contain solutions. The triad is mandatory
for every agent without exception.

"Format requirements" — output structure, parse-able shape,
citation discipline, severity scales, verdict-line conventions —
are a separate, narrower category. They are communication
standards, not solutions. Format requirements may be added to
specific agent prompts **alongside** the triad; they never replace
or omit it.

The distinguishing rule:

> Format requirements describe **how the output is structured** and
> **how findings are communicated**. Solutions describe **how the
> agent should achieve the goal**.

Format requirements appear in the prompt under **Constraints**
(when they govern behavior — read-only, report-only, no-code,
verification command) or under **Completion report** (when they
govern output shape — header line, ordered sections, ✅/❌/⚠️
markers, citation discipline). They never appear inside **Goal**
or **Success criteria**.

| Agent | Format requirements (allowed) | Solutions (forbidden) |
|---|---|---|
| `architect` | Required-reading list; proposed-change block format. | Pattern names; structural direction; library or framework choices. |
| `auditor` | Skip rules; per-subagent platform-skill loadout; severity scale; cluster order; ownership-precedence dedup; executive-summary structure. All forwarded from `audit-methodology`. | Telling the auditor what to find or hide; pre-judging severity. |
| `coder` | Files in scope; verification commands; completion-report shape (Unplanned-file-modifications, Deferred-items sections); per-task DOD format. | Pseudocode; pattern names; algorithm sketches; step-by-step "how to." |
| `docs-researcher` | URLs; specific claims; ✅/⚠️ block format; citation discipline. | Telling the researcher what to conclude; proposing a fix to a discrepancy. |
| `planner` | Report-header format; per-task field shape; dependency-edge format. | Prescribing the breakdown itself ("Phase N has these tasks: …"). |
| `repo-ops` / mechanical claude | Exact operations and command sequences (the entire purpose of the agent). | N/A — but the prompt cannot ask `repo-ops` to **design** anything; only to apply a fully-specified operation. |
| `reviewer` | Eight review dimensions; ✅/❌/⚠️ markers; Pass-summary block; Verdict line; verification command. | Adjusting the reviewer's judgment; pre-categorizing severity; instructing what to overlook. |
| `tester` | Per-component output block; priority-summary format; report-only constraint. | Test pattern or framework choice; mock vs. stub direction; pre-ordered test plan. |
| `pm-chat` (self-prompt) | When generating a prompt for any other agent, the PM chat may specify the same format requirements that agent's row allows. When generating its own self-prompts (BACKLOG entries, STATUS anchors, SETUP.md, AGENT_KICKOFF.md), the PM chat may specify the target file's schema and section structure. | Inheriting the target agent's solution-forbidden list — a PM-chat-authored coder prompt may not contain pseudocode or pattern names, a PM-chat-authored architect prompt may not contain proposed solutions or pattern names, etc. The PM chat is bound by every constraint that applies to the agent it is prompting. |

> **Update this table when any agent is added or changed.**

**Architect prompts — stronger restriction.** Never include a proposed
solution, pattern name, or structural approach in a prompt to an
architect agent. A proposed solution in an architect prompt is not a
suggestion — it anchors the agent. Describe the constraint violation
or design problem only. The architect diagnoses and proposes.

### Format-vs-solutions: worked examples

The format-vs-solutions distinction is easier to read in the abstract
than to apply under time pressure. The examples below show the most
common leakage shapes observed in PM-chat-generated coder prompts
(paraphrased from real cases). For each: the **Negative** line shows
what NOT to write; the **Positive** line shows the format/constraint
version; the **Why** line names the leakage category.

**Example 1 — testability technique**
- **Negative:** *"The size limit must be injectable as a parameter so tests can drive rotation with small payloads."*
- **Positive:** *"Rotation behavior must be testable with payloads small enough to trigger rotation in unit tests."*
- **Why:** The negative names a testability mechanism (parameter injection). The positive states the testability requirement; the coder chooses among parameter injection, an overridable static, a test-seam protocol, or another approach.

**Example 2 — API or framework name**
- **Negative:** *"Declare the panel scene via `WindowGroup` or `Window`, whichever is consistent with how the existing app declares scenes."*
- **Positive:** *"The panel must be a separate scene matching the scene-declaration convention already used in the app."*
- **Why:** The negative names specific platform APIs. The positive names the constraint (separate scene; convention-matching) and lets the coder read the existing app to choose.

**Example 3 — architectural-shape invention**
- **Negative:** *"`StateProvider` is a protocol that returns a `StateSnapshot` value type; the snapshot has nested value types covering [list]."*
- **Positive:** *"The panel content sections required: [list of sections from the plan]. The state-source design is the coder's choice."*
- **Why:** The negative invents a protocol-plus-snapshot-plus-nested-value-types composition pattern that did not appear in the implementation plan. The plan required panel content sections; the data-supply architecture is a coder decision.

**Example 4 — timing or lifecycle prescription**
- **Negative:** *"Poll the data source on a 1 Hz timer; suspend the timer when the window is not visible."*
- **Positive:** *"Panel data must reflect current state without measurable user-visible lag, and must not consume resources when the panel is hidden."*
- **Why:** The negative names a polling rate and a lifecycle mechanism. The positive names the observable requirements (freshness, idle behavior); the coder chooses polling vs. observation, rate, and visibility hook.

**Example 5 — Files-in-scope is NOT solution leakage (clarifying)**
- **This is scope, not solution:** For example: *"Files in scope: `Data/Logging/FileLogSink.swift` (new), `Data/Logging/LogRotation.swift` (new)."* Paths come from the implementation plan and enforce existing layer discipline (logging belongs in `Data/`). They are location guardrails.
- **This crosses into solution:** *"Use `FileManager.default.url(for:in:)` to resolve the log directory."* This names an API choice the coder should make.
- **Why:** Files-in-scope lists relay scope from the architect / planner / plan. They tell the coder where the work lives and where it does not. They do not specify how the work is done. API and data-structure choices made *inside* those files are the coder's.

The per-agent table in the previous subsection enumerates which format requirements are allowed for each agent. When in doubt: ask the self-check question 2 below — "Am I describing what needs to be true, or how to do it?"

### File-based reporting

Every prompt's **Completion report** section names a file the
agent's output is written to. Two sub-cases:

- **Sub-case A — agent produces a report.** A `REPORT FILE: <path>`
  line names a markdown file the agent writes its report to (e.g.,
  reviewer pass-N report, coder phase-N completion report,
  architect mid-phase analysis, docs-researcher verification, planner
  breakdown, tester strategy, auditor consolidated report). The PM
  chat reads the file back; the agent does not copy-paste output
  into chat.
- **Sub-case B — PM-chat self-prompt produces a target-file edit.**
  When the PM chat runs a self-prompt that edits or creates a
  project file (a `docs/project/backlog/` entry, STATUS.md, SETUP.md,
  AGENT_KICKOFF.md), the artifact **is** the target file edit. No
  separate report file is required. The Completion-report section
  names the target file and the change summary.

Both sub-cases satisfy this rule. A prompt that asks an agent to
"output the report" or "return the result to the developer" without
naming a file is a defect.

### Multi-part phase report headers

When a phase is split into sequential implementation chunks, use **Part [M]**
(not "pass") appended to the phase title in all report headers. Pass numbers
reset to 1 for each new part. Single-part phases use the existing header
format — do not append `, Part 1`. Example:
`Phase 12 — Auth Flows, Part 2 — Reviewer Report, Pass 1`

This applies to every agent's completion report regardless of which file in
`docs/pack/prompts/` the prompt came from.

### On scoping the problem statement

The problem should be scoped to its root cause, not to a specific file or line.
If the problem is "URLComponents construction can silently fail," say that — not
"line 47 of ServiceX.swift." Root-cause framing lets the agent recognize every
instance within the files-in-scope list.

The files-in-scope list does the bounding, not the problem statement.
Keep the problem statement complete; keep the files list tight.

If it is genuinely unknown how many files are affected, say so and instruct the
agent to audit the listed files only, then report any out-of-scope instances found
for a follow-up decision. Do not expand the files list speculatively — that is
scope inflation.

### On scoping the files-in-scope list

The files-in-scope list is the primary boundary on what the agent may
modify. If the agent discovers the same problem in a file not on this
list, it should report it rather than fix it — unless the unlisted
file is a direct dependency required for the listed tasks to compile
or function (e.g., a type that must expose a new accessor for the
phase to work). In that case the agent may make a small, focused
change and must disclose it in the **"Unplanned file modifications"**
section of the completion report.

The data-dependency-trace requirement (see PM chat self-check item 3
below) ensures this escape valve is invoked rarely — incomplete file
lists are the most common reason agents hit it.

### When generating prompts from `phase-N.md` task entries

If a task entry contains prescriptive implementation instructions rather than a
problem/goal/success-criteria description, reframe it before including it in the prompt —
extract what is wrong, what correct behavior looks like, and what confirms the task
is complete. Discard the how. Do not forward implementation instructions verbatim.
This applies to coder, architect, and planner prompts. For agents where prescriptive
content is permitted as **format** (per the Format requirements vs. solutions table
above), forward plan content as written.

### PM chat self-check before generating any prompt

Before writing a prompt:

1. **Triad check.** Does the prompt body contain bolded labeled
   `**Problem:**`, `**Goal:**`, and `**Success criteria:**`
   sections? If not, add them before sending. (The single exception
   is the `pm-chat.md` kickoff variant, which carries the
   `**Convention exception:**` callout.)
2. **Solution check.** Ask: *"Am I describing what needs to be
   true, or how to do it?"* If the answer is "how to do it,"
   rewrite as "what needs to be true." Format requirements (output
   shape) are not solutions and are not affected by this check.
3. **Data-dependency trace — required before finalizing any coder or fix-cycle file list:**
   For each data field or behavior the phase requires, ask: *"Which existing type holds
   or produces that data, and does that type need a new method or property to expose it?"*
   If yes, add that type's file to the files-in-scope list before sending the prompt.
   An incomplete file list is the single most common cause of coder workarounds: the
   agent is forced to either invent an architecturally wrong solution or silently touch
   a file it was not told about.
4. **REPORT FILE check.** Does the **Completion report** section
   name a file the agent's output goes to (sub-case A) or the
   target file the PM chat will edit (sub-case B)? If neither, add
   one before sending.

---

## Part 6 — Audit Checkpoints

Audits run the `auditor` agent, which spawns up to seven read-only subagents
covering distinct quality dimensions and consolidates their reports. The
authoritative cluster definitions, file scopes, severity scale, pass/fail
thresholds, and report format live in the `audit-methodology` skill — read
that skill for the canonical rules.

### Cadence — when to run a full audit

The auditor is **retrospective and periodic**, not per-phase or per-PR.
A full audit costs 7–8 subagent invocations (one per non-skipped cluster
plus the parent consolidation), so it must be invoked deliberately.

Run a full audit when **any one** of these triggers fires:

| Trigger | Notes |
|---|---|
| End of a major phase group (3 or more phases completed since the last audit) | Most common trigger |
| Before starting major new feature work | Audit the foundation before extending it |
| Before a release build | Required — pass-with-issues at minimum, no Criticals |
| After a significant refactor that touched multiple layers | Catches regressions in coupling and layer discipline |
| When ARCHITECTURE.md and code feel out of sync | `auditor-docs` will flag drift |
| Test count drops unexpectedly | `auditor-tests` will identify which coverage was lost |

**Do not** run a full audit in the first three phases of a new project — there
is not enough code to produce useful findings and the noise-to-signal ratio
is high (per `audit-methodology` rule 5).

### Audit subagents (7 clusters)

Each cluster has its own subagent with its own scope, file boundaries, and
skill set. The parent auditor coordinates them and consolidates a single
report. Clusters are summarized below in the canonical consolidation order
(`audit-methodology` rule 53: security → architecture → tests → ops → code
→ ui → docs). Full definitions live in `audit-methodology` rules 15–21.

| Subagent | Scope summary | Skip rule |
|---|---|---|
| `auditor-security` | Credentials, injection, deserialization, log safety, supply chain (CVEs, licenses) | Always runs |
| `auditor-architecture` | Layer boundaries, SOLID, LSP, observability infrastructure | Always runs |
| `auditor-tests` | Coverage, determinism, edge cases, mocked-vs-real boundaries | Skip only on first audit of a brand-new project with no test suite |
| `auditor-ops` | Deployment readiness, configuration management, observability wiring | Always runs |
| `auditor-code` | Idioms, dead code, performance, concurrency, systemic error handling | Always runs |
| `auditor-ui` | UI/UX compliance only — view thickness, accessibility, incomplete states | Skip for server-only projects with no UI layer |
| `auditor-docs` | Documentation drift detection (does docs match code?) | Always runs |

### Post-audit BACKLOG intake (PM chat procedure)

After the developer pastes the consolidated audit report into the PM chat,
the PM chat processes it as follows:

```
1. Read the executive summary first — verdict, totals, top 3 issues, skipped subagents
2. For each Critical finding:
   - Generate a fix prompt and route to coder via Workflow 4 immediately
   - Critical findings block release per audit-methodology rule 13
3. For each Major finding:
   - Create a BACKLOG entry per Part 7 procedures, marked Status: Open
   - Use Type: KNOWN GAP(functional) unless the finding is structural
   - Blocker: name the audit cluster and severity for traceability
   - Major findings do NOT block release (rule 12) but must be tracked
4. For Minor and Info findings:
   - Create ONE consolidated BACKLOG entry summarizing them as "Audit
     observations YYYY-MM-DD" — do not create one entry per Minor finding
   - Reference the audit report by date for the full list
5. For findings annotated with `(also detected by: <other-clusters>)`:
   - Process the surviving entry only — the duplicate has already been
     removed during parent consolidation per rules 33–39
6. Run the standard phase-gate procedure (Part 7 Procedure 1) at the
   start of the next phase, which will pick up newly Open audit entries
```

### Direct developer invocation

Developers may invoke the auditor directly without the PM chat in the loop.
This is most common when verifying a single fix:

```
# Full audit
./agent-run.sh claude --agent auditor
./agent-run.sh codex  --agent auditor
./agent-run.sh agy    --agent auditor [--skip auditor-ui[,auditor-tests]]

# Single subagent (verify a fix without paying for the full audit)
./agent-run.sh <cli> --agent auditor-security
./agent-run.sh <cli> --agent auditor-code
# ...etc, any of the seven subagents
```

When a developer invokes the auditor directly, the resulting report is
returned to the terminal. To process its findings into the BACKLOG, paste
the report into the PM chat and follow the post-audit BACKLOG intake
procedure above.

**Auditor template lives in `docs/pack/prompts/auditor.md` (`## Variant:
standard`).** The PM chat uses it as a starting point and customizes the
skip rules and project-specific scope notes per project.


---

## Part 7 — BACKLOG and TODO Management

This part defines the full system for tracking deferred work, known gaps, and items
requiring verification. The PM chat owns this system. Agents receive explicit instructions
in their prompts — they do not figure out BACKLOG logic themselves.

> **Sub-procedure heading style varies by procedure.** Procedure 5 uses
> `#### Procedure 5.N` (each sub-procedure is itself a standalone procedure).
> Procedure 6 uses `#### 6.N` (numbered steps within one procedure).
> Procedure 7 uses `#### 7.N` with `##### 7.N.M` for sub-Forms (numbered steps
> + nested Form sub-sections). Each procedure's local convention is intentional
> and reflects the procedure's own structure; do not normalize across procedures.

### Comment format

Three typed deferral comment formats are recognized. All others are invalid.

**Swift / Objective-C / C / C++:**
```swift
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(severity): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```

**Python:**
```python
# TODO(scope): TD-TBD — Short title
# KNOWN GAP(severity): TD-TBD — Short title
# VERIFY(source): TD-TBD — Short title
```

**Valid scope values for TODO:** `phase-N` (deferred to a named phase), `dependency`
(blocked on another item), `feature` (blocked on a feature decision), `perf`
(optimization deferred until profiling shows need), `version` (deferred to a pack version)

**Valid severity values for KNOWN GAP:**
- `critical` — must eventually be addressed without exception; the system is not complete without it
- `functional` — should be addressed; feature is incomplete or incorrect in a meaningful way
- `polish` — may be skipped based on judgment; improves experience but does not affect correctness

**Source values for VERIFY:** name the external source (e.g. `weather-api`, `apple-docs`, `stripe-api`)

**The TD-TBD sentinel:** The coder always writes `TD-TBD` in deferral comments — never a
real number. The PM chat replaces `TD-TBD` with a real `TD-NNN` when the BACKLOG entry is
created after user approval. Any `TD-TBD` in committed code is a defect.

**What is NOT a valid deferral:** Work that could be completed within the current phase
scope is not a TODO — it is an incomplete task. The reviewer flags it as an implementation
plan compliance failure (reviewer checklist item 4). The fix is a coder fix pass,
not a BACKLOG entry.

### Deferral scan scope

Every deferral scan in this Part runs against **project-owned files only**. The
pack-shipped surfaces — `docs/pack/`, the per-CLI skill and agent trees
(`.claude/`, `.codex/`, `.agents/`, `.agents-plugin/`), the capability pool, and
the trinity context files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) — DOCUMENT the
deferral convention, so they contain `TD-TBD` and the typed comment markers by
design. They are not project work and are never a defect.

An unscoped whole-tree scan reports dozens of pack-owned hits the project cannot
action. Define the scope once per session and use it for every scan below:

```bash
SCAN_SCOPE='--include=*.swift --include=*.py --include=*.md --exclude-dir=.git --exclude-dir=pack --exclude-dir=.claude --exclude-dir=.codex --exclude-dir=.agents --exclude-dir=.agents-plugin --exclude-dir=pack-capability-pool --exclude=CLAUDE.md --exclude=AGENTS.md --exclude=GEMINI.md'
```

`docs/project/` stays IN scope — project per-entry files are project work.

This is the same scope the `/pm-startup` Step 5 sentinel check applies. The two
are one contract: if either changes, change both.

### BACKLOG item format

```
**TD-NNN — [Short title]**
Type: TODO(scope) | KNOWN GAP(critical|functional|polish) | VERIFY(source)
Status: Open | Unblocked | Resolved | Cancelled | Deprecated
Blockers:
  - [Named specific dependency — phase N, phase N.M (v11.0 additive), TD-NNN, or external condition]
  - [Additional blocker if any — all must resolve before item is actionable]
Unblocks: [TD-NNN, TD-NNN, ...] or None
  ← informational only; PM chat derives actionability from Blockers, never from this field
File/Symbol: `path/to/file` — `SymbolName`  ← optional; symbol name not line number; n/a if none
Description: [What the work is and why it was deferred]
Context: [What was known at deferral time — constraints, observed behavior, partial
          information. Descriptive only. Do not propose a solution.]
Resolution: [date, one of: completed | cancelled | deprecated, brief note]
  ← filled in when status moves to Resolved, Cancelled, or Deprecated; never deleted
```

**Status transitions:**
- Open → Unblocked: all Blockers resolved
- Unblocked → Resolved: work confirmed complete by reviewer
- Open or Unblocked → Cancelled: deliberate decision not to do the work; the gap
  may still exist but has been accepted
- Open or Unblocked → Deprecated: item no longer applicable because something else
  changed — feature removed, architecture evolved, external dependency disappeared

Active statuses: Open, Unblocked — these are the only items requiring attention.
Inactive statuses: Resolved, Cancelled, Deprecated — no further action required.
Items are never deleted. Items with no blockers start as Unblocked.

**TD counter:** The PM chat tracks the next available TD number. At the start of every
session, read the backlog tree (`docs/project/backlog/`), find the highest existing TD number, set counter to that value + 1.
Increment by 1 for each approved item. Report the updated counter at session end.

### Procedure 1 — Phase gate check (runs before every phase prompt)

No phase prompt is generated until this check is complete.

```
1. Read the backlog tree (`docs/project/backlog/`) in full
2. For every Open item, check each Blocker:
   - Phase N blocker: has that phase been committed and marked ✅ in STATUS.md?
   - Phase N.M blocker (v11.0 additive): read the `✅` marker on the
     `#### N.M` heading in the per-entry tree. (Flat-file per-entry is the
     sole supported mode.)
   - Phase task A blocked by phase task B (Dependencies field):
     same resolution as Phase N.M — read the target task's status; mode-agnostic.
   - TD-NNN blocker: does that item have Status: Resolved?
   - External condition: has the condition been met? (use judgment; flag for user if uncertain)
   If ALL blockers resolved → set Status: Unblocked
   (When all blockers resolve, the TD becomes Unblocked — see the resolution-path
   decision logic later in this Part for the promotion paths.)
   The PM chat reports newly-unblocked items to the user
   proactively at every phase gate — the user should not need
   to ask. ("TD-NNN is now unblocked by Phase N completion.")
3. For every Unblocked item:
   - Determine resolution path using the decision logic below
   - Present list to user with proposed path for each item
   - Wait for explicit approval before incorporating into any phase prompt
4. Run TD-TBD grep check (project-owned files only — see "Deferral scan scope"):
   grep -rn "TD-TBD" . $SCAN_SCOPE
   Any result is a defect — report to user and resolve before proceeding
5. Run orphan audit (Procedure 3)
6. Skill gap check:
   Read the Active skills line from the Skill loading section of CLAUDE.md.
   Read the upcoming phase's tasks from its `docs/project/implementation-plan/phase-N.md` entry.
   Scan the task descriptions for technology references not covered by the
   active skills (e.g., Python imports in a Swift-only skill set, proto files
   without grpc-patterns, C interop without c-language).
   If a gap is found:
     a. If a matching skill exists in the pack (check PLATFORM-SKILLS.md):
        flag to user — "Phase N references [technology] but [skill] is not
        in active skills. Add it?"
     b. If no matching skill exists in the pack:
        flag to user AND record in PACK-FEEDBACK.md — "Phase N references
        [technology] but no matching skill exists in the pack."
        Developer decides: create a custom project-level skill, wait for
        a pack update, or proceed without.
   If user approves adding a skill: update the project description and the
   Active skills line in CLAUDE.md, AGENTS.md, and GEMINI.md. Commit.
```

**Resolution path decision logic** (supersedes the v10 three-outcome shape).
(See Procedure 1 step 2 above for the "blockers resolved" gate-check semantics
including the v11.0 phase-N.M and phase-task A-blocked-by-B forms.)
```
Is the work small (≤ ~30 minutes inline; no significant scope expansion;
user available to do it) AND no blockers?
  → Yes: direct close
         (resolve the TD in place via its `Status:` / `Resolved:`
          lines; no new entity; lifecycle unchanged)
  → No: Does the work span multiple tasks, warrant its own phase
        (architectural surface; multi-day; distinct concern), OR is
        there a cluster of related TDs in the same area?
      → Yes: Path 1 — promote to a new phase epic
             (write a new phase epic entry at L1; the phase entry
              body notes it derives from the TD; the closed TD's
              `Resolved:` line cross-refs the new phase epic; PM Chat
              invokes architect by default)
      → No: Path 2 — promote to a new phase task under existing phase
             (write a new phase task at L2 child of the phase-N epic;
              the task body notes it derives from the TD; the closed
              TD's `Resolved:` line cross-refs the new phase task; for
              each `Dependencies` bullet entry on the new task, PM Chat
              records a cross-entity `blocked-by` edge in the flat-file
              entry bodies)
```
PM Chat advises per heuristic (Description length, File/Symbol
scope, Type signal, related-TD cluster). The user can confirm or override
via `change-to-path-1` / `change-to-path-2` / `change-to-direct-close`.
Bias toward resolving now.

**Path 3 is forbidden** (supersedes the v10 fold-into-existing-task shape). The
v10 "fold into existing task body via inline `(from TD-NNN)` marker"
shape is rejected; where that case would
have applied, the user edits the absorbing task body manually via PM
Chat (outside the promotion mechanism) and resolves the TD via direct
close, OR uses Path 2 with a `Dependencies` bullet pointing at the
absorbing task to express ordering without merging entities. There is
no fold-into-an-existing-task outcome.

### Procedure 2 — Post-session processing (after every coder completion report)

```
1. Read the "Deferred items" section of the coder's completion report
2. If section is empty or "None": confirm no TD-TBD grep hits in modified files; proceed
3. For each reported item, present to user:
   Type, severity/scope/source, description, blocker, context
4. Wait for user decision per item: approve | modify | reject
5. If approved or modified:
   - Assign next available TD number from counter
   - Write BACKLOG entry using the format above
   - Replace TD-TBD with TD-NNN in the source file comment
   - Increment TD counter
6. If rejected:
   - Remove the deferral comment from the source file entirely
   - No BACKLOG entry created
7. Confirm no TD-TBD remains in any file touched this session
```

### Procedure 3 — Orphan audit (runs at every phase gate, step 5)

```
   (All scans below are project-owned only — see "Deferral scan scope".)
1. Grep for all typed deferral comments:
   Swift/C/C++/ObjC: grep -rn "// TODO(\|// KNOWN GAP(\|// VERIFY(" . $SCAN_SCOPE
   Python:            grep -rn "# TODO(\|# KNOWN GAP(\|# VERIFY(" . $SCAN_SCOPE
2. Grep for unprocessed items (always a defect if found in committed code):
   grep -rn "TD-TBD" . $SCAN_SCOPE
3. For each TD-NNN found in comments:
   - Confirm a corresponding BACKLOG entry exists with that number
   - Confirm Type, severity/scope, and short title match between comment and BACKLOG entry
   - Flag any mismatch
4. For each Open or Unblocked BACKLOG entry with a File/Symbol:
   - Confirm the deferral comment exists in that file at that symbol
   - Flag any missing comment
5. Report all findings; resolve before proceeding to next phase prompt
```

### Procedure 4 — Resolution procedure (when item is Unblocked and approved)

```
1. Determine resolution path (from gate check approval)
2. Generate appropriate prompt:
   - Addendum task: add to current phase prompt as additional numbered task
   - Separate pass: standalone coder prompt for this item only
   - Cleanup phase: accumulate multiple items into a dedicated phase with its own
     `phase-N.md` entry and reviewer pass
3. When coder completes the work:
   - Reviewer confirms work is done (reviewer checklist item 4 — implementation plan compliance)
   - Reviewer confirms deferral comment has been removed from code
   - PM chat marks Status: Resolved with phase, date, brief note
   - PM chat removes the comment if coder did not
4. Run disposition scan based on how this item was closed:
   - Resolved (completed): check all Open items whose Blockers list names this
     TD-NNN; set those to Unblocked if all their other blockers are also resolved
   - Cancelled or Deprecated: check all Open items whose Blockers list names this
     TD-NNN; flag each one for user review — do not automatically set to Unblocked.
     The dependency chain is broken in a way that requires human judgment: the
     downstream item may need a new blocker, revised scope, or cancellation itself
```

> **Closeout-sequence rule.** Procedure 4 step 3 ("PM chat marks
> Status: Resolved") and step 4 ("Run disposition scan") MUST
> be preceded by the closeout sequence defined in PM-CHAT.md
> `## Behavioral rules` ("Closeout sequence — present, wait,
> then write."): trigger check → present content → wait for
> approval → write → show commit message → wait for approval →
> commit. Never write closeout files before presenting their
> content and receiving approval.

### Procedure 5 — Custom agent and skill workflow

*Relocated to [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md). See that file for Procedure 5 and its sub-procedures (5.1–5.6).*

### Procedure 5-C — Customization reconciliation after v9.3 → v10 migration

*Lives in [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md). Triggered by `*.v9-customized` sidecars after migration; absorbs the former Procedure 5-R as sub-procedure 5-C.1.*

### Procedure 5-R — Prompt reconciliation after v9.3 → v10 migration

*Folded into Procedure 5-C.1 in [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md). The legacy `_v9-backup.md` filename is supported in 5-C.1 for pre-C7 v10.0 installs.*

### Procedure 5-S — Post-migration housekeeping

*Relocated to [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md). Triggered by `.pack-migration-backup/v9.3-to-v10.0/postrun-pending`.*

### Procedure 6 — Activating a supported capability

Triggered when either:

- The developer pastes the end-of-run prompt emitted by
  `scripts/activate-capability.sh`.
- The developer asks the PM chat to "add Python" / "add iOS" / similar
  and the PM chat (per its PM-CHAT.md **Capability addition**
  behavioral rule) first instructs them to run
  `scripts/activate-capability.sh --add <dimension>:<value>` before
  resuming.

`scripts/activate-capability.sh` is a self-contained project script: it
re-materializes the conditional files for the requested capability from
the tracked `pack-capability-pool/` directory into the live tree and
emits a PM-chat prompt. No external clone is needed — the pool travels
with the project. Procedure 6 is the PM-chat-side companion to that
script: it updates the trinity files' `**Active skills:**` line and
`[PLACEHOLDER]` sections for the newly-active dimension and drives
Form-I follow-ups for any machine-level tools that still need to be
installed.

Gates: **G6-drafts** (trinity drafts reviewed before any markdown
write), **G6-install** (install commands surfaced for missing tools
reviewed before any `brew install` / `uv add` / equivalent runs), and
**G6-commit** (git add list + commit message before committing).

| Step | Action | Gate |
|---|---|---|
| **6.1** | Read the `activate-capability.sh` prompt — either pasted into the session or read from `.pack-activate-capability-prompt.md` at the project root (written by the script's final stage; the file is gitignored local state). The prompt names the activated `--add <dimension>:<value>` capabilities, lists the files re-materialized from `pack-capability-pool/`, and reports the current vs. target `**Active skills:**` line. | — |
| **6.2** | Read the newly-activated `SKILL.md` files from `.claude/skills/<name>/SKILL.md` (skills are already on disk from the initial pack install). Extract the content relevant to each trinity `[PLACEHOLDER]` section. | — |
| **6.3** | Draft updates to the trinity files: update the `**Active skills:**` line; fill `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]` as applicable for the newly-added dimension. Present drafts side-by-side for all three trinity files (TRIO) — byte-identical content in every section the trinity rule covers. | **G6-drafts** — developer confirms trinity drafts before any write |
| **6.4** | If the project now qualifies for a PLATFORM-SKILLS.md dimension row that was not previously selected (e.g., project gains an iOS row after adding iOS to a macOS-only selection), surface the dimension row for explicit acknowledgement. Informational — PLATFORM-SKILLS.md rows describe the pack's matrix, not the project's selection, so typically no edit is needed. | — |
| **6.5** | Identify any machine-level tools the newly-activated dimension needs (from the dimension's `SKILL.md` content read in 6.2 and `INSTALL-PROCEDURES.md`). For each such tool not already present, render a **Form I** in the shape of `INSTALL-PROCEDURES.md § 7.2.3` (Command / Purpose / Side effects / Skip impact). Default each Form I to `skip`; the developer replies `yes` per tool to authorize. Already-present tools require no Form I. Tools the developer skips are recorded in the chat — Procedure 6 does not modify any project doc to record skips. | **G6-install** — developer confirms each install before it runs |
| **6.6** | Run the Procedure 5.5 detection scan once drafts are applied — verify no `x-` files were touched; verify PLATFORM-SKILLS.md `## Custom agents` / `## Custom skills` project-owned regions are unchanged. | — |
| **6.7** | Present `git add` list and commit message (`feat: project — add <dimension>:<value> capability`); developer approves per CLAUDE.md pack rule (same gate as Procedure 5 G-commit). | **G6-commit** |

The trinity edits are always TRIO (trinity rule): the same content is
spliced into `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` in one commit.

**Artifacts modified:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (TRIO —
`**Active skills:**` line + applicable `[PLACEHOLDER]` sections).

**Artifacts never touched by Procedure 6:** any `x-` agent / skill /
prompt file; any `SKILL.md` (already on disk); `STATUS.md`;
`ARCHITECTURE.md`; the per-entry backlog, implementation-plan,
changelog, and groupings trees under `docs/project/`; PLATFORM-SKILLS.md
`## Custom agents` and `## Custom skills` project-owned regions.

**Symmetry with Procedure 7 (kickoff).** Step 6.5's per-tool Form I
mirrors INSTALL-PROCEDURES.md § 7.2.3 (kickoff swift-format install)
and § 7.3.1 / 7.3.2 (kickoff gRPC tooling). The same idempotency rules
apply: an already-present tool reports a single-line `note: <tool>
already installed — skipping` and does not render a Form I. Tool
discovery is PM-chat-side in step 6.5 (read from the activated
dimension's `SKILL.md` and `INSTALL-PROCEDURES.md`), so no
G6-discovery gate is needed — the PM chat surveys the needed tools
as part of drafting and gates only the install at G6-install.

### Procedure 7 — Kickoff auto-discovery and install-check

*Relocated to [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md). Triggered by the kickoff variant prompt on shell-capable surfaces; auto-discovers Apple Xcode scheme/destination, swift-format install state, gRPC tooling state, Python tooling state, and Xcode CodingAssistant companion-files state.*

### Cancelling or deprecating a BACKLOG item

Tell the PM chat in conversation: "Cancel TD-NNN" or "Deprecate TD-NNN — [brief reason]."
This is a deliberate human decision and always requires explicit instruction.

When you instruct the PM chat to cancel or deprecate an item, it will:
1. Set Status to Cancelled or Deprecated
2. Add Resolution field: [date, cancelled|deprecated, your rationale]
3. If a deferral comment exists in source code for this item, remove it
4. Run the disposition scan: find all Open or Unblocked items whose Blockers list
   names this TD-NNN; present each to you for a decision — do not automatically
   unblock any of them. Each downstream item may need a new blocker stated,
   a revised scope, or cancellation itself
5. Wait for your decision on each downstream item before proceeding

### Agent BACKLOG write permissions

| Agent | May do | May not do |
|---|---|---|
| `coder` | Write TD-TBD deferral comments in code; report deferred items in completion report | Write to the backlog tree (`docs/project/backlog/`); resolve or modify existing entries |
| `reviewer` | Read only | Write anything |
| `docs-researcher` | Read only | Write anything |
| `repo-ops` | Read only | Write anything |
| PM chat | Write and update the backlog tree (`docs/project/backlog/`) after user approval; replace TD-TBD with TD-NNN or remove rejected comments in source files | Any other source code changes |

> **PM chat comment edit carve-out:** The PM chat may edit source files solely to add,
> modify, or remove deferral comments (`// TODO(`, `// KNOWN GAP(`, `// VERIFY(`, and
> Python equivalents). This is the only permitted source file edit by the PM chat.


---

## Part 8 — Warning Signs

Stop and reassess when you see these patterns.

### In the reviewer cycle

- **Same issue category across 3+ cycles.** Coder is not reading the feedback. PM chat
  should regenerate the fix prompt with more explicit, step-by-step instructions.
- **Reviewer ✅ but test count decreased.** Coder deleted tests to make the build pass.
  Never acceptable. Investigate before committing.
- **Architecture violations appear in later phases.** CLAUDE.md rules are not clear enough.
  Update them and re-run the reviewer.

### In documentation

- **ARCHITECTURE.md and code describe different patterns.** Either the architecture changed
  without updating the doc, or the coder drifted. Run a docs audit immediately.
- **Changelog-tree entry doesn't match git diff.** The PM chat may have applied the
  coder's proposed entry before the phase was complete, or the proposed entry was not
  updated to reflect late changes. Always verify changelog entries (`docs/project/changelog/`) against `git diff`
  before committing.

### In agent behavior

- **Agent modifies files it was told not to touch — without disclosing it.** Stop the
  session. Do not commit. Review what changed. Re-run with more explicit scope constraints.
  If the change appears in the completion report's **"Unplanned file modifications"**
  section, evaluate it through the reviewer's checklist item 8 before deciding whether
  to accept or reject it — disclosed changes are not automatic violations.
- **Agent invents API methods or framework capabilities.** Hallucinating. Verify every
  new API call against official documentation before committing.
- **Agent defers in-scope work unprompted.** Add the deferred items explicitly to the
  next prompt.

### In planning

- **A phase keeps cycling without reaching ✅.** Scope is too large. Split it. Finish
  the clean parts; add problem areas to BACKLOG.
- **Feature inventory reveals built features don't work as expected.** Testing was
  insufficient. Run a test coverage audit before adding new features.
- **BACKLOG grows faster than it shrinks across multiple phases.** Architecture or
  design decisions are generating systemic debt. Run an LSP audit.

---

## Part 9 — Document Authoring Rules

### What agents can and cannot modify

| Document | Coder | Reviewer | PM chat | Notes |
|---|---|---|---|---|
| `ARCHITECTURE.md` | Only if task explicitly says so | Never | Approves changes | Source of truth |
| `docs/project/implementation-plan/` (per-entry tree) | Only if task explicitly says so | Never | Authors and approves | Never delete phases; one `phase-N.md` per phase |
| `docs/project/changelog/` (per-entry tree) | No — proposes entry in report only | Never | Yes — after reviewer approval | One `<ID>.md` per phase |
| `docs/project/backlog/` (per-entry tree) | Never — reports only | Never — reports only | Yes — after user approval | Never delete items |
| `STATUS.md` | Never | Never | Yes — after phase completion | Update after every phase |
| `CLAUDE.md` / `AGENTS.md` | Never | Never | Authors changes | CLI agents read, don't write |
| Production source files | Yes | Never | Never | Core job |
| `PACK-FEEDBACK.md` | Never | Never | Append entries; deliver batches | See Part 10; agents never write |
| Deferral comments in source | Writes TD-TBD only | Never | Replaces TD-TBD with TD-NNN or removes | See Part 7 |

> **/tmp reports are ephemeral.** When an agent prompt specifies
> a `REPORT FILE:` path under `/tmp/...` (typically used for
> docs-researcher reports, architect mid-phase reports, or any
> report the developer does not want committed to the repo),
> treat the file as ephemeral: it is safe to share externally
> (for upstream debugging via PACK-FEEDBACK.md per Part 10),
> nothing to revert if discarded, and never to be committed.
> Reports intended for the repo are written under `docs/project/`
> per the standard prompt templates.

### Desktop Commander scope for PM chat

The PM chat may use Desktop Commander for:
- Updating STATUS.md after a phase completes
- Adding items to the backlog tree (`docs/project/backlog/`) (after user approval)
- Appending changelog-tree entries (`docs/project/changelog/`)
- Fixing typos or stale references in doc files
- Adding, modifying, or removing deferral comments in source files (TD-TBD → TD-NNN,
  or removing rejected comments) — this is the only permitted source file edit

The PM chat must NOT use Desktop Commander for:
- Writing or modifying any source code
- Sweeping multi-file changes without explaining and getting explicit approval
- Modifying ARCHITECTURE.md or the `docs/project/implementation-plan/` tree without approval

When Desktop Commander is unavailable, the PM chat outputs file content and
git commands for the human to run manually. Both paths must always be available.

### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md

This placement rule is SUBSIDIARY to the PM chat omniscience
obligation (Part 1 — Tool Roles). The default is single-source
authoritative with PM-chat injection-into-agent-prompts as the
delivery mechanism; duplication across surfaces is the EXCEPTION
documented below.

New rules added during pack maintenance fall into one of three
categories based on audience:

- **PM-chat orchestration rules** (workflow ordering, when to
  spawn which agent, closeout sequence, prompt-generation
  discipline) → `docs/pack/PM-CHAT.md` § Behavioral rules
  (authoritative). The PM chat injects relevant subsets into
  agent prompts at prompt-construction time per the omniscience
  principle's briefing obligation. Agents do NOT independently
  carry these rules.
- **Agent-affecting rules** (no destructive operations, trinity
  rule, agent file authority, file scope) → trinity `CLAUDE.md`
  / `AGENTS.md` / `GEMINI.md` § Project rules (authoritative
  for agents). These rules apply to every agent invocation
  regardless of whether the PM chat is in the loop.
- **Both-audience rules requiring duplication** → trinity
  § Project rules + PM-CHAT.md § Behavioral rules. Use this
  duplication pattern ONLY when the rule meets one of the
  documented defense-in-depth conditions in Part 1 — Tool Roles
  (prompt-corruption resilience for high-risk rules; cross-CLI
  parity ergonomics until per-CLI injection logic exists).
  Otherwise, single-source authoritative placement applies.

This placement rule guides cleanup batches and pack-version
upgrades; it does not retroactively renumber existing rules.
Where a pre-existing duplicated rule still satisfies the
defense-in-depth conditions, leave it; where it does not,
consolidate it to a single source.


---

## Part 10 — Pack Feedback Loop

<!-- DENY-LIST-CONTENT-START -->
The PM chat is the only entity that observes the AI Agent Config Pack
running on real production work. The Pack Chat (the upstream maintainer
of the pack) has no visibility into how the pack behaves outside the
pack repo. The PM chat's responsibility is to observe, record, and
report back.
<!-- DENY-LIST-CONTENT-END -->

### What to observe

Four categories, logged continuously in `PACK-FEEDBACK.md`:

1. **Workflow execution** — did each workflow (1–6) run as documented?
2. **Prompt generation** — were templates sufficient, or did they need heavy customization?
3. **Agent performance** — per-agent, per-run: did it follow scope, use the right format, hallucinate, drift? Aggregate into patterns over time.
4. **User friction** — where did the human get confused, ask the same thing twice, or encounter behavior that didn't match docs?

### Reporting cadence

- **Default:** deliver feedback batches at workflow-complete boundaries only (end of phase, fix cycle, audit cycle, feature). Never mid-phase.
- **Emergency:** escalate immediately if something blocks the project or indicates a broken pack defect. See PACK-FEEDBACK.md `## Emergency Escalation`.
<!-- DENY-LIST-CONTENT-START -->
- **Question-driven:** the Pack Chat seeds open questions in PACK-FEEDBACK.md `## Pack Chat Open Questions`. The PM chat observes during normal work and answers at workflow boundaries when data is sufficient.
<!-- DENY-LIST-CONTENT-END -->

### Workflow-boundary check (explicit trigger)

At every workflow-complete boundary, **before** saying "ready for next phase," the PM chat must:

<!-- DENY-LIST-CONTENT-START -->
1. Review all Pack Chat Open Questions in PACK-FEEDBACK.md.
2. For each question with Status: Not Ready — assess whether observations from this phase provide enough data to transition to Ready. If so, transition it and tell the user.
3. For each question with Status: Ready — generate the delivery prompt and present it to the user for forwarding to Pack Chat.
<!-- DENY-LIST-CONTENT-END -->
4. Briefly report the status of all open questions to the user (even if nothing changed), so the user has visibility.

### The running doc

`PACK-FEEDBACK.md` lives at `docs/pack/PACK-FEEDBACK.md` in the project
(post-relocation), with the backlog tree (`docs/project/backlog/`) and
`STATUS.md` (project root) alongside it. PM-chat-owned, append-only. Agents never write to it.
The template ships with the pack.

**All operational instructions** — the status state machine, delivery
mechanics, scope boundaries, permissions, and what NOT to put in the
doc — live inside `PACK-FEEDBACK.md` itself in the `## How to use this
doc` section. Read that section when working with the doc. This Part
(Part 10) is the overview; PACK-FEEDBACK.md is the operational
reference.


---

## Appendix — New Project Checklist

### Day 1 — Setup
- [ ] Create GitHub repo; clone locally
- [ ] Planning conversation → ARCHITECTURE.md, the per-entry implementation plan (`docs/project/implementation-plan/`), CLAUDE.md, AGENTS.md
- [ ] Run `"$PACK/scripts/init-project.sh" .` from the project root.
      The script previews every operation, asks for explicit
      confirmation, and on `y` executes eleven stages (S0..S10) that
      copy template files, distribute skills, set permissions, run
      bootstrap, and emit the PM chat kickoff prompt. The full
      procedure is documented in the pack repo at
      `<pack-clone>/supporting-docs/SETUP-NEW.md` Step 3.
- [ ] Create the per-entry stream trees (`docs/project/backlog/`, `docs/project/changelog/`, `docs/project/groupings/`) and seed `STATUS.md` with `bash scripts/status-generate.sh`
- [ ] **Choose PM chat mode** — Option A (Claude Desktop app, see
      `SETUP-NEW.md` Step 10 Option A), Option B (Claude Code CLI,
      Step 10 Option B), Option C (Codex CLI, Step 10 Option C), or
      Option D (Antigravity CLI, Step 10 Option D)
- [ ] Commit all docs. If using Desktop app: sync GitHub connector.

### Before each phase
- [ ] Re-read the **Prompt Authoring Principles** section before generating any prompt
      for this phase — refresh the non-prescriptive authoring standard
- [ ] Run phase gate check (Part 7 Procedure 1): read the backlog tree (`docs/project/backlog/`) for newly unblocked
      items, run TD-TBD grep, run orphan audit, run skill gap check — resolve all
      findings before proceeding
- [ ] Sync GitHub connector in PM chat
- [ ] Confirm STATUS.md shows correct current phase
- [ ] Confirm prior phase ✅ and build/tests green
- [ ] Ask PM chat for the coder prompt (or docs-researcher prompt if API research needed first)

### After each phase
- [ ] Reviewer cycle complete (✅ verdict)
- [ ] Commit and push
- [ ] Update STATUS.md: mark phase ✅, update current phase, update test count in metrics
- [ ] Sync GitHub connector
- [ ] Confirm PM chat can see updated docs via project knowledge search
- [ ] **Log any pack feedback observations** (Part 10) — per-agent performance,
      workflow/prompt issues, user friction. Append to `PACK-FEEDBACK.md`. If the
      phase completes a full workflow cycle, generate a feedback batch for Pack
      Chat delivery.

---

*Version 2.1 — AI Agent Config Pack v11.0, May 2026*
*Source: Claude-Assisted Project Methodology Guide v1 (pack-archived design source)*
*Update this file when new standing decisions are made. Bump the version number.*
