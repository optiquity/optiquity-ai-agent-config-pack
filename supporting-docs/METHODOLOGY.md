# METHODOLOGY.md — AI-Assisted Project Development Methodology

Version: 1.0 (v8, March 2026)
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
`supporting-docs/PROMPT-TEMPLATES.md` (in the pack) or uploaded to this Claude project.

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
- **Scope for direct file edits:** Small, targeted doc-only changes only:
  STATUS.md updates, BACKLOG additions, CHANGELOG entries, typo/stale-reference fixes.
  Never source code. Never sweeping multi-file changes without explaining and getting approval.
- Never writes code or calls specialist agents directly

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
| `CHANGELOG.md` | Permanent dated history of what was built | Coder agent | One entry per phase, at phase completion only |
| `BACKLOG.md` | Technical debt, deferred items, known gaps | PM chat or reviewer findings | Add/resolve; never delete items |
| `STATUS.md` | Current phase, phase table, next actions, key metrics | PM chat or developer | After every phase completion |
| `CLAUDE.md` | Project-specific rules for all CLI agents | PM chat | When new rules are established |
| `AGENTS.md` | Agent roster and routing table | PM chat | When agents are added or changed |
| `METHODOLOGY.md` | This file — project-agnostic methodology reference | Pack (v8) | When new standing decisions are made |

### Document hygiene rules (inviolable)

1. ARCHITECTURE.md and IMPLEMENTATION_PLAN.md are source of truth — they must reflect reality.
2. CHANGELOG.md is append-only — never edit old entries.
3. BACKLOG.md items are never deleted — mark resolved with a note.
4. STATUS.md is updated after every phase — stale status is worse than no status.
5. Agents must not modify ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, or BACKLOG.md
   unless explicitly instructed in the prompt. Include this constraint in every coder prompt.
6. Every // TODO:, // KNOWN GAP:, or similar code comment must have a BACKLOG entry
   added in the same commit. Comments without tracking entries will be forgotten.


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
| Breaking down a complex phase | `planner` (optional) |
| Proto3 schema design or review | `grpc-schema` |
| BACKLOG/STATUS updates, simple doc edits | standard `claude` (no agent) |

### When NOT to use a CLI agent

- Planning and decision-making → Claude Chat
- Reviewing pasted agent output → Claude Chat
- Simple doc-only changes (STATUS, BACKLOG, typo fixes) → standard `claude` or PM chat via Desktop Commander

### Session rules

- Each agent invocation is a new session. Never continue a coder session for a new phase.
- Reviewer sessions are always new. Never reuse a reviewer session for a second pass.
- Agents have no memory between sessions — every prompt must be self-contained.


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
- **What**: Specific implementation instructions
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
6. Create app's Claude project, upload `METHODOLOGY.md` and `PROMPT-TEMPLATES.md`
   to project knowledge
7. Run bootstrap: `./scripts/bootstrap.sh`
8. Commit all docs before writing any code
9. Sync GitHub connector in Claude Chat project
10. Generate `AGENT_KICKOFF.md` from `AGENT_KICKOFF_TEMPLATE.md` (PM chat fills it in)
11. Run architect agent with AGENT_KICKOFF.md to produce `ARCHITECTURE.md` and stubs

### Workflow 2 — Per-phase execution (standard coder → reviewer cycle)

```
1. Claude Chat generates coder prompt for Phase N
2. Developer: cd ~/Developer/[project] && claude --agent coder → paste prompt
3. Agent runs and reports completion
4. Developer: claude --agent reviewer → paste reviewer prompt (generated by Claude Chat)
5. Developer pastes reviewer output into Claude Chat
6. Claude Chat analyzes:
   - ✅ ready to commit → developer commits and pushes
   - ❌ needs fixes → Claude Chat generates fix prompt → new coder session → repeat reviewer
7. Developer updates STATUS.md, syncs GitHub connector
```

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
3. For ❌: PM chat generates targeted fix prompt → new coder session
4. Developer runs reviewer again (new session)
5. Repeat until ✅
6. For ⚠️ not being fixed immediately:
   PM chat generates BACKLOG.md addition prompt → developer runs in standard claude
```

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
| Workflow 4 — Fix cycle | Template 4 (fix cycle) |
| Workflow 5 — Global audit | Template 9 (test coverage), Template 10 (docs audit), Template 11 (LSP audit), Template 12 (UI audit) |
| Workflow 6 — New feature | Template 8 (BACKLOG/STATUS update), then Workflow 2 templates |

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

## Part 7 — Warning Signs

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
- **CHANGELOG.md entry doesn't match git diff.** Coder wrote the entry before finishing.
  Always verify CHANGELOG entries against `git diff` before committing.

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

## Part 8 — Document Authoring Rules

### What agents can and cannot modify

| Document | Coder | Reviewer | PM chat | Notes |
|---|---|---|---|---|
| `ARCHITECTURE.md` | Only if task explicitly says so | Never | Approves changes | Source of truth |
| `IMPLEMENTATION_PLAN.md` | Only if task explicitly says so | Never | Authors and approves | Never delete phases |
| `CHANGELOG.md` | Yes — end of phase only | Never | Never | One entry per phase |
| `BACKLOG.md` | Yes — add/resolve | Yes — add findings | Yes (small edits) | Never delete items |
| `STATUS.md` | Yes — after phase completion | Never | Yes (small edits) | Update after every phase |
| `CLAUDE.md` / `AGENTS.md` | Never | Never | Authors changes | CLI agents read, don't write |
| Production source files | Yes | Never | Never | Core job |

### Desktop Commander scope for PM chat

The PM chat may use Desktop Commander for:
- Updating STATUS.md after a phase completes
- Adding items to BACKLOG.md
- Appending CHANGELOG entries
- Fixing typos or stale references in doc files

The PM chat must NOT use Desktop Commander for:
- Writing or modifying any source code
- Sweeping multi-file changes without explaining and getting explicit approval
- Modifying ARCHITECTURE.md or IMPLEMENTATION_PLAN.md without approval

When Desktop Commander is unavailable, the PM chat outputs file content and
git commands for the human to run manually. Both paths must always be available.


---

## Appendix — New Project Checklist

### Day 1 — Setup
- [ ] Create GitHub repo, create Claude Chat project, connect repo via GitHub connector
- [ ] Planning conversation → ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CLAUDE.md, AGENTS.md
- [ ] Copy METHODOLOGY.md from pack template to project root
- [ ] Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)
- [ ] Create .claude/agents/ directory with agent files from pack template
- [ ] Run `./scripts/bootstrap.sh`
- [ ] Create app's Claude project, upload METHODOLOGY.md + PROMPT-TEMPLATES.md to project knowledge
- [ ] Commit all docs. Sync GitHub connector.

### Before each phase
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

*Version 1.0 — AI Agent Config Pack v8, March 2026*
*Source: supporting-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*
*Update this file when new standing decisions are made. Bump the version number.*
