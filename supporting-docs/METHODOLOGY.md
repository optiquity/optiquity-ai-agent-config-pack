# METHODOLOGY.md — AI-Assisted Project Development Methodology

Version: 1.0 (v8.8, April 2026)
Applies to: All projects using Claude Code CLI + Claude Chat + AI Agent Config Pack v8

> **Applicability note:** This document is platform-agnostic and applies to all project
> types (Apple, Python server, monorepo). Some agent references may not apply to every
> project: `apple-architect` is relevant only for Swift/Apple projects; `python-architect`
> is relevant only for Python server projects. Ignore agents that don't apply to your
> project type. If a project-specific version of this file becomes necessary, it can be
> created at that time.

> **Single source of truth:** One copy of this file lives at
> `supporting-docs/METHODOLOGY.md` in the AI Agent Config Pack. Copy it to your project
> root during setup (see QUICKSTART.md Step 3). Do not modify the pack's copy for
> project-specific needs — edit the project root copy instead and let it evolve with
> the project.

---

## Overview

This document is the reference guide for building software projects using Claude Code CLI
agents for execution and a Claude Chat project as the persistent project manager.

**The core principle: Claude Chat is the brain. Claude Code CLI is the hands.**
They are not interchangeable. Claude Chat holds context, makes decisions, and generates
prompts. CLI agents execute those prompts against the actual filesystem.

**For prompt templates** referenced throughout this document, see:
`PROMPT-TEMPLATES.md` in the project root (copied from the pack during setup).

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

> **Two PM chat options:** The PM chat can run as a Claude Desktop app project
> (setup — see QUICKSTART.md Step 11, Option A) or as a resumable Claude Code
> CLI session (non-blocking, native file/git access — setup in QUICKSTART.md
> Step 11, Option B; daily usage reference in `supporting-docs/CLI-PM-SETUP.md`).
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

---

## Part 2 — Standard Project Documents

Every project should have all of these. Create them before writing any code.

| Document | Purpose | Who writes | Who updates |
|---|---|---|---|
| `ARCHITECTURE.md` | Architectural decisions, layer map, patterns, data models | Architect agent (kickoff) | Any phase that changes architecture |
| `IMPLEMENTATION_PLAN.md` | All phases with tasks, DoD, agent, risks | PM chat + planner agent | Each phase adds entries; never delete old phases |
| `CHANGELOG.md` | Permanent dated history of what was built | PM chat | One entry per phase, after reviewer approval; coder proposes entry in completion report |
| `BACKLOG.md` | Technical debt, deferred items, known gaps | PM chat | Add/resolve; never delete items |
| `STATUS.md` | Current phase, phase table, next actions, key metrics | PM chat or developer | After every phase completion |
| `CLAUDE.md` | Project-specific rules for all CLI agents | PM chat | When new rules are established |
| `AGENTS.md` | Agent roster and routing table | PM chat | When agents are added or changed |
| `METHODOLOGY.md` | This file — project-agnostic methodology reference | Pack (v8) | When new standing decisions are made |

### Document hygiene rules (inviolable)

1. ARCHITECTURE.md and IMPLEMENTATION_PLAN.md are source of truth — they must reflect reality.
2. CHANGELOG.md is append-only — never edit old entries.
3. BACKLOG.md items are never deleted — mark resolved with a note.
4. STATUS.md is updated after every phase — stale status is worse than no status.
5. Agents must not modify `ARCHITECTURE.md` or `IMPLEMENTATION_PLAN.md` unless
   explicitly instructed in the prompt. `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`,
   and all other root `.md` files are exclusively the PM chat's responsibility — no
   agent should write them, and no agent prompt should instruct them to. Include root
   `.md` file constraints in every coder prompt.
6. Every deferral comment (`// TODO(scope):`, `// KNOWN GAP(severity):`, `// VERIFY(source):`,
   or language-equivalent) must have a corresponding BACKLOG.md entry. `TD-TBD` in any
   committed file is a defect — it means the PM chat has not yet processed the coder's
   deferred items report. See Part 7 for the full comment format and BACKLOG procedures.


---

## Part 3 — Agent Roster

### When to use each agent

| Situation | Agent |
|---|---|
| Implementing a phase | `coder` |
| Reviewing code after implementation | `reviewer` |
| Planning what tests to write | `tester` |
| Writing tests after planning | `coder` |
| Researching an external API before implementation | `docs-researcher` |
| Auditing documentation accuracy | `docs-researcher` |
| Apple platform architecture design | `apple-architect` |
| Python server architecture design | `python-architect` |
| Mid-phase design correction (Trigger A or B met in Workflow 4) | `apple-architect` or `python-architect` |
| Breaking down a complex phase | `planner` (optional) |
| Proto3 schema design or review | `grpc-schema` |
| BACKLOG/STATUS updates, simple doc edits | standard `claude` (no agent) |
| BACKLOG item processing and comment updates | PM chat only (after user approval) |

### When NOT to use a CLI agent

- Planning and decision-making → Claude Chat
- Reviewing pasted agent output → Claude Chat
- Simple doc-only changes (STATUS, BACKLOG, typo fixes) → standard `claude` or PM chat via Desktop Commander

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

**Apple-platform pattern selection rule (architect agent):**
For Swift/Apple projects, the following patterns are prohibited by default
and require explicit documented justification before the architect may choose them:

1. Type-erasure wrappers with `.base` accessor properties for heterogeneous
   domain collections. These are LSP violations. Use protocol elevation or
   exhaustive enums instead. If chosen anyway, document why protocol elevation
   and exhaustive enums are insufficient for this specific case.

2. `AsyncStream<Void>` or any contentless change notification broadcast to
   multiple independent subscribers. Use typed payload streams. If a contentless
   stream is chosen, document why payload typing is insufficient.

3. ViewModels that import SwiftUI or hold direct references to navigation
   coordinators. ViewModels must express navigation intent as observable output
   state. If direct navigator access is chosen, document why the intent-as-state
   pattern is insufficient.

These are not style preferences — they are structural correctness requirements
with documented failure modes on Apple platforms.

---

## Part 4 — Phase Structure

Every phase in IMPLEMENTATION_PLAN.md should follow this format:

```markdown
## Phase N — [Title]

**Goal**: One sentence describing what this phase delivers.
**Prerequisite**: Which prior phase must be complete.
> **Execution note**: (optional) deliberate deferral or ordering constraint.

### Tasks
#### N.1 — [Task title]
- **Problem/Goal**: What this task achieves and what is currently wrong or missing —
  describe the outcome, not the steps. Do not include implementation instructions.
- **Files created/modified**: list
- **Definition of done**: Measurable, verifiable criteria
- **Dependencies**: other tasks within this phase

### Verification
Build/test command that proves the phase is complete.

### Agent
Which agent(s) to use for which tasks.

### Risks
| Risk | Severity | Mitigation |
```

### Phase numbering rules

- Never renumber phases — phase numbers are referenced in code comments, CHANGELOG, and BACKLOG.
- To reorder execution, use execution notes (`> **Execution note**:`), not renumbering.
- Insert new phases at the end of the plan.
- Fractional phases (2.1, 2.2) only during early architecture work — use whole numbers after that.


---

## Part 5 — Standard Workflows

> **Prompt templates** for each workflow step are in `PROMPT-TEMPLATES.md`.
> Templates are starting points — the PM chat customizes each prompt based on project
> context, current phase, and recent review results.

### Workflow 1 — Starting a new project

1. Create GitHub repo
2. Create Claude Chat project, connect GitHub repo via GitHub connector
3. Planning conversation with PM chat → establishes architecture, phase plan, agent config
4. PM chat generates (or helps generate): `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`,
   `CLAUDE.md`, `AGENTS.md`, `METHODOLOGY.md` (copy from pack)
5. Create `STATUS.md` and `BACKLOG.md` (initially sparse)
6. Create app's Claude project, connect GitHub repo — `METHODOLOGY.md` and `PROMPT-TEMPLATES.md`
   are in the project repo and available via the GitHub connector after syncing
7. Run bootstrap: `./scripts/bootstrap.sh`
8. Commit all docs before writing any code
9. Sync GitHub connector in Claude Chat project
10. Generate `AGENT_KICKOFF.md` from `AGENT_KICKOFF_TEMPLATE.md` (PM chat fills it in)
11. Run architect agent with AGENT_KICKOFF.md to produce `ARCHITECTURE.md` and stubs

### Workflow 2 — Per-phase execution (standard coder → reviewer cycle)

```
1. Claude Chat generates coder prompt for Phase N
2. Developer: cd ~/Developer/[project] && ./agent-run.sh claude --agent coder → paste prompt
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
> read-only agents (`reviewer`, `planner`, `apple-architect`, `python-architect`,
> `docs-researcher`, `grpc-schema`) receive permission bypass (so compilers and linters run
> without interruption) and git write protection. Write agents (`coder`, `tester`, `repo-ops`)
> pass through with no extra flags. Direct CLI invocation still works for one-off use; the script
> ensures consistent flags across the team. Customize the configuration section at the top of
> `agent-run.sh` to add agents or adjust flags per project.

### Workflow 3 — Per-phase execution (with external API research)

For phases integrating external APIs or making architectural decisions:

```
1. docs-researcher agent reads official API docs (prompt from PM chat)
2. Developer pastes research report into PM chat
3. PM chat identifies discrepancies, generates IMPLEMENTATION_PLAN.md correction prompt
4. Developer runs correction in standard claude CLI, commits
5. (Optional) tester agent generates test specification → PM chat incorporates into coder prompt
6. Standard coder → reviewer cycle
```

### Workflow 4 — Fix cycle (when reviewer finds issues)

```
1. Developer pastes reviewer output into PM chat
2. PM chat categorizes: ❌ blockers vs ⚠️ minors
3. PM chat checks for architect trigger (see below) before generating any fix plan
4. If NO trigger: PM chat presents fix plan → developer approves → coder fix pass → reviewer (step 1)
5. If TRIGGER: PM chat identifies root cause → presents architect pass plan → developer approves
   → architect agent runs (read-only, proposes doc changes) → PM chat presents proposed changes
   → developer approves doc changes → PM chat applies them via Desktop Commander or manual
   → PM chat presents coder fix plan covering both reviewer issues and new arch direction
   → developer approves → coder fix pass → reviewer (step 1)
6. For ⚠️ not being fixed immediately:
   PM chat generates BACKLOG.md addition → developer runs in standard claude
```

> **The PM chat does not execute fix passes directly.** After receiving reviewer output,
> the PM chat presents a plan and waits for approval before generating any agent prompt.
> The coder agent executes the fix; the PM chat does not.

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
3. **Run the architect agent** — read-only pass using Template 4b. The agent reads
   `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `CLAUDE.md`, `AGENTS.md`, and the
   specific reviewer findings. It proposes corrections to those docs as text output —
   it does not write files.
4. **Present proposed doc changes** — show the user exactly what the architect proposes
   to change. Get explicit approval for each change before applying it.
5. **Apply approved changes** — PM chat applies via Desktop Commander or outputs for
   manual application. Commit the doc changes before the coder fix pass.
6. **Generate coder fix pass** — using Template 4, incorporating both the reviewer's
   open issues and the new architectural direction. Present plan, get approval, then
   developer runs it.

> **CLAUDE.md and AGENTS.md changes:** The architect agent may propose changes to
> `CLAUDE.md` or `AGENTS.md` only if the root cause cannot be addressed by fixing
> `ARCHITECTURE.md` or `IMPLEMENTATION_PLAN.md` alone. These require an additional
> explicit user approval beyond the general architect pass approval.

### Workflow 5 — Global audit phases

For test coverage audit, LSP audit, documentation audit, UI audit:

```
1. Audit agent reads entire codebase — discovers components via Glob (no pre-specified list)
2. Developer pastes full audit report into PM chat
3. PM chat analyzes, categorizes ALL findings (not just top 10)
4. PM chat generates comprehensive fix prompt covering all actionable items
5. Items requiring live sandbox or design decision → added to BACKLOG.md with prerequisite note
6. Standard coder → reviewer cycle for fixes
```

### Workflow 6 — Adding a new feature to a stable project

```
1. PM chat: describe feature → discussion to scope and document it
2. PM chat generates updates to ARCHITECTURE.md and IMPLEMENTATION_PLAN.md (new phases)
3. Developer runs update prompts in standard claude, commits doc changes, syncs
4. Run Workflow 2 for each new phase
```

### Workflow → template cross-reference

Each workflow has corresponding prompt templates in `PROMPT-TEMPLATES.md`. Use these
as starting points — customize for the current project and phase before pasting.

| Workflow | Templates to use |
|---|---|
| Workflow 1 — New project | Template 1 (PM chat kickoff), Template 13 (generate SETUP.md), Template 14 (generate AGENT_KICKOFF.md) |
| Workflow 2 — Per-phase execution | Template 2 (coder), Template 3 (reviewer), Template 4 (fix cycle) |
| Workflow 3 — External API research | Template 6 (docs-researcher), then Template 2 (coder) |
| Workflow 4 — Fix cycle | Template 4 (fix cycle coder prompt); Template 4b (mid-phase architect prompt, when triggered) |
| Workflow 5 — Global audit | Template 9 (test coverage), Template 10 (docs audit), Template 11 (LSP audit), Template 12 (UI audit) |
| Workflow 6 — New feature | Template 8 (BACKLOG/STATUS update), then Workflow 2 templates |

---

## Prompt Authoring Principles

These principles apply to every prompt the PM chat generates — coder, architect,
fix cycle, researcher, planner — and to every task entry written in IMPLEMENTATION_PLAN.md.
They are not style guidance. They govern what information belongs in a prompt and what does not.

### The core rule: describe the problem and goal, not the solution

Every prompt and every task entry must answer:

1. **Problem** — the root cause, described at the category level, not a single symptom.
   Include enough scope that the agent recognizes all instances within the files-in-scope
   list — but do not describe the solution.

2. **Goal** — what correct behavior looks like across the affected scope when the task
   is complete. Describe the outcome, not the steps.

3. **Context** — why this matters and how it connects to the larger system design.
   Include only what the agent cannot infer from reading ARCHITECTURE.md.

4. **Required reading** — documents and files the agent must read before starting.
   Distinguish: files to read for understanding (may extend beyond the change scope)
   vs. files in scope to modify.

5. **Files in scope** — explicit list of files the agent may create or modify.
   This is a hard boundary. If the agent discovers the same problem in a file not
   on this list, it must report it rather than fix it.

6. **Completion report** — what the agent must report when done: files modified,
   verification results, and any out-of-scope discoveries.

A prompt must never contain:
- Pseudocode or implementation sketches
- Framework, pattern, or library choices (unless already mandated in ARCHITECTURE.md)
- Step-by-step "how to" instructions
- Proposed solutions that substitute for agent judgment

**Why this rule exists:** Prescriptive prompts bypass the agent's ability to find
the right approach from full filesystem context. The PM chat has not read every file
in the repo — the agent has. The PM chat states what is wrong and what correct
behavior looks like. The agent determines how to achieve it.

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

### Exceptions — where prescriptive content is appropriate

| Agent | May prescribe | Must not prescribe |
|---|---|---|
| `reviewer` | Review criteria, output format, verification commands | Which issues to overlook or deprioritize |
| `docs-researcher` | Specific claims to verify, URLs to check, output format | How to resolve discrepancies found |
| `repo-ops` / standard `claude` | Exact file operations, BACKLOG/STATUS changes | N/A — mechanical operations are fully prescribed |
| `tester` | Audit scope, output format | Which test patterns or structures to use |
| `coder` | Files in scope, verification commands, completion report format | Implementation approach, patterns, pseudocode |
| `architect` | Problem statement and required reading only | All solutions — including pattern names and structural direction |
| `planner` | Which phase or scope to break down | How to break it down |

> **Update this table when any agent is added or changed in AGENTS.md.**

**Architect prompts — stronger restriction:**
Never include a proposed solution, pattern name, or structural approach in a prompt
to an architect agent. A proposed solution in an architect prompt is not a suggestion
— it anchors the agent. Describe the constraint violation or design problem only.
The architect diagnoses and proposes.

### When generating prompts from IMPLEMENTATION_PLAN.md task entries

If a task entry contains prescriptive implementation instructions rather than a
problem/goal description, reframe it before including it in the prompt — extract
what the task is trying to achieve and what correct behavior looks like, and discard
the how. Do not forward implementation instructions verbatim.
This applies to coder, architect, and planner prompts. For agents where prescriptive
content is permitted (see exceptions table above), forward plan content as written.

### PM chat self-check before generating any prompt

Before writing a prompt, ask: *"Am I describing what needs to be true, or how to do it?"*
If the answer is "how to do it," rewrite it as "what needs to be true."

---

## Part 6 — Audit Checkpoints

Audits are judgment calls, not a fixed schedule. The PM chat should proactively
recommend an audit when it detects these milestone triggers:

| Trigger | Recommended audit |
|---|---|
| End of a major implementation phase group | Test coverage audit + docs audit |
| Before live/external API testing begins | Test coverage audit, LSP audit |
| After a significant refactor | LSP audit, architecture audit |
| When ARCHITECTURE.md and code feel out of sync | Architecture/docs audit |
| When test count drops unexpectedly | Test coverage audit |
| After 3+ phases without a review pass | LSP audit |
| Before adding major new features | Full audit suite |

**For each audit type, prompt templates are in `PROMPT-TEMPLATES.md`.** The PM chat
uses those as starting points and customizes based on the project state.

### Audit types and what they check

**Test coverage audit** (tester agent, read-only)
Reads the entire codebase. For each component: what's tested, what's not, which BACKLOG
items have no test coverage, priority ranking.

**Documentation audit** (docs-researcher agent, read-only)
Reads all markdown files against actual code. Finds misalignments, stale descriptions,
wrong file paths, pseudocode drift, CHANGELOG entries that don't match files changed.

**Architecture / LSP audit** (reviewer agent, read-only)
Checks layer boundary violations, interface uniformity, Liskov Substitution compliance,
any concrete type leaking across layer boundaries.

**UI audit** (reviewer agent, read-only)
Reads View and ViewModel files. Checks view thickness, business logic placement,
missing accessibility, incomplete states, navigation correctness.


---

## Part 7 — BACKLOG and TODO Management

This part defines the full system for tracking deferred work, known gaps, and items
requiring verification. The PM chat owns this system. Agents receive explicit instructions
in their prompts — they do not figure out BACKLOG logic themselves.

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

**Source values for VERIFY:** name the external source (e.g. `schwab-api`, `apple-docs`, `stripe-api`)

**The TD-TBD sentinel:** The coder always writes `TD-TBD` in deferral comments — never a
real number. The PM chat replaces `TD-TBD` with a real `TD-NNN` when the BACKLOG entry is
created after user approval. Any `TD-TBD` in committed code is a defect.

**What is NOT a valid deferral:** Work that could be completed within the current phase
scope is not a TODO — it is an incomplete task. The reviewer flags it as an implementation
plan compliance failure (point 4 of the seven-point framework). The fix is a coder fix pass,
not a BACKLOG entry.

### BACKLOG item format

```
**TD-NNN — [Short title]**
Type: TODO(scope) | KNOWN GAP(critical|functional|polish) | VERIFY(source)
Status: Open | Unblocked | Resolved | Cancelled | Deprecated
Blockers:
  - [Named specific dependency — phase N, TD-NNN, or external condition]
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
session, read BACKLOG.md, find the highest existing TD number, set counter to that value + 1.
Increment by 1 for each approved item. Report the updated counter at session end.

### Procedure 1 — Phase gate check (runs before every phase prompt)

No phase prompt is generated until this check is complete.

```
1. Read BACKLOG.md in full
2. For every Open item, check each Blocker:
   - Phase N blocker: has that phase been committed and marked ✅ in STATUS.md?
   - TD-NNN blocker: does that item have Status: Resolved?
   - External condition: has the condition been met? (use judgment; flag for user if uncertain)
   If ALL blockers resolved → set Status: Unblocked
3. For every Unblocked item:
   - Determine resolution path using the decision logic below
   - Present list to user with proposed path for each item
   - Wait for explicit approval before incorporating into any phase prompt
4. Run TD-TBD grep check:
   Swift/C/C++/ObjC: grep -rn "TD-TBD" .
   Any result is a defect — report to user and resolve before proceeding
5. Run orphan audit (Procedure 3)
```

**Resolution path decision logic:**
```
Is the work small AND directly related to the upcoming phase's concerns?
  → Yes: addendum task within the current phase
  → No: Is the volume of unblocked items large, or do they span unrelated areas?
      → Yes: dedicated cleanup phase
      → No: separate pass of the current phase (same phase number, distinct prompt)
```
The PM chat presents its reasoning and the user may override. Bias toward resolving now.

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
1. Grep for all typed deferral comments:
   Swift/C/C++/ObjC: grep -rn "// TODO(\|// KNOWN GAP(\|// VERIFY(" .
   Python:            grep -rn "# TODO(\|# KNOWN GAP(\|# VERIFY(" .
2. Grep for unprocessed items (always a defect if found in committed code):
   grep -rn "TD-TBD" .
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
     IMPLEMENTATION_PLAN.md entry and reviewer pass
3. When coder completes the work:
   - Reviewer confirms work is done (point 4 — implementation plan compliance)
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
| `coder` | Write TD-TBD deferral comments in code; report deferred items in completion report | Write to BACKLOG.md; resolve or modify existing entries |
| `reviewer` | Read only | Write anything |
| `docs-researcher` | Read only | Write anything |
| `repo-ops` | Read only | Write anything |
| PM chat | Write and update BACKLOG.md after user approval; replace TD-TBD with TD-NNN or remove rejected comments in source files | Any other source code changes |

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
- **CHANGELOG.md entry doesn't match git diff.** The PM chat may have applied the
  coder's proposed entry before the phase was complete, or the proposed entry was not
  updated to reflect late changes. Always verify CHANGELOG entries against `git diff`
  before committing.

### In agent behavior

- **Agent modifies files it was told not to touch.** Stop the session. Do not commit.
  Review what changed. Re-run with more explicit scope constraints in the prompt.
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
| `IMPLEMENTATION_PLAN.md` | Only if task explicitly says so | Never | Authors and approves | Never delete phases |
| `CHANGELOG.md` | No — proposes entry in report only | Never | Yes — after reviewer approval | One entry per phase |
| `BACKLOG.md` | Never — reports only | Never — reports only | Yes — after user approval | Never delete items |
| `STATUS.md` | Never | Never | Yes — after phase completion | Update after every phase |
| `CLAUDE.md` / `AGENTS.md` | Never | Never | Authors changes | CLI agents read, don't write |
| Production source files | Yes | Never | Never | Core job |
| Deferral comments in source | Writes TD-TBD only | Never | Replaces TD-TBD with TD-NNN or removes | See Part 7 |

### Desktop Commander scope for PM chat

The PM chat may use Desktop Commander for:
- Updating STATUS.md after a phase completes
- Adding items to BACKLOG.md (after user approval)
- Appending CHANGELOG entries
- Fixing typos or stale references in doc files
- Adding, modifying, or removing deferral comments in source files (TD-TBD → TD-NNN,
  or removing rejected comments) — this is the only permitted source file edit

The PM chat must NOT use Desktop Commander for:
- Writing or modifying any source code
- Sweeping multi-file changes without explaining and getting explicit approval
- Modifying ARCHITECTURE.md or IMPLEMENTATION_PLAN.md without approval

When Desktop Commander is unavailable, the PM chat outputs file content and
git commands for the human to run manually. Both paths must always be available.


---

## Appendix — New Project Checklist

### Day 1 — Setup
- [ ] Create GitHub repo; clone locally
- [ ] Planning conversation → ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CLAUDE.md, AGENTS.md
- [ ] Copy template files from pack: `cp -r pack/[TEMPLATE]/. .` — then separately copy
      `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, and `PM-CHAT.md` from `supporting-docs/`
- [ ] Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)
- [ ] Run `./scripts/bootstrap.sh`
- [ ] **Choose PM chat mode** — Option A (Claude Desktop app project, see QUICKSTART.md
      Step 11, Option A) or Option B (CLI, see QUICKSTART.md Step 11, Option B)
- [ ] Commit all docs. If using Desktop app: sync GitHub connector.

### Before each phase
- [ ] Re-read the **Prompt Authoring Principles** section before generating any prompt
      for this phase — refresh the non-prescriptive authoring standard
- [ ] Run phase gate check (Part 7 Procedure 1): read BACKLOG.md for newly unblocked
      items, run TD-TBD grep, run orphan audit — resolve all findings before proceeding
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

---

*Version 1.0 — AI Agent Config Pack v8.8, April 2026*
*Source: supporting-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*
*Update this file when new standing decisions are made. Bump the version number.*
