<!--
SOURCE MATERIAL — DO NOT USE DIRECTLY IN PROJECTS

This is the raw Methodology Guide v1 as produced during the target project (2026).
It contains project-specific content (the target project's phases, broker APIs, macOS trading app
details) mixed with universal methodology patterns.

Purpose: Historical record and source material for v8 deliverables:
  - supporting-docs/METHODOLOGY.md  (BD-008) — generalized universal workflows
  - supporting-docs/PROMPT-TEMPLATES.md  (BD-009) — extracted and generalized prompt templates

Do not copy this file into project repos. Do not reference it from CLAUDE.md or AGENTS.md.
The generalized versions above are the intended deliverables.

Extracted from: the target project's PM chat session, 2026
Pack version: v8 (March 2026)
-->

# Claude-Assisted Project Methodology Guide

Version: 1.0
Based on: the target project (Phases 0–25, 2026)
Applies to: Native iOS/macOS/Swift projects built with Claude Code CLI + Claude Chat

---

## Overview

This guide documents a proven methodology for building software projects using Claude
Code CLI agents for execution and a Claude Chat project as the persistent project
manager. It covers project setup, documentation structure, agent workflows, prompt
patterns, and decision rules that apply across projects.

The core principle: **Claude Chat is the brain, Claude Code CLI is the hands.**
They are not interchangeable. The chat holds context, makes decisions, and generates
prompts. The CLI executes those prompts against the actual filesystem.

---

## Part 1 — Tool Roles

### Claude Chat Project
- Long-running project manager workspace
- Holds decisions, context, and history across the entire project lifetime
- Connected to the GitHub repo via the GitHub connector (read-only)
- Reads project markdown files via project knowledge search
- Generates all agent prompts
- Receives all agent output (pasted by developer)
- Makes all architectural and planning decisions
- Never writes code directly

### Claude Code CLI
- Executes specific, scoped tasks
- Full filesystem access — reads every file in the repo
- Runs builds, tests, git commands
- Creates and modifies files
- No persistent memory between sessions — each session starts fresh
- Receives complete context in the prompt (cannot rely on memory)

### Rule: Never conflate the two
The CLI cannot replace the chat for planning. The chat cannot replace the CLI for
execution. Prompts generated in chat are pasted into CLI sessions. Results from CLI
sessions are pasted back into chat for review and next-step generation.

---

## Part 2 — Project Documentation Structure

Create these files at project start. Every project should have all of them.

### Required files — repo root

| File | Purpose | Who writes it | Who updates it |
|---|---|---|---|
| `ARCHITECTURE.md` | All architectural decisions, layer rules, patterns, data models | Claude chat (architect phase) | Any phase that changes architecture |
| `IMPLEMENTATION_PLAN.md` | All phases with tasks, agents, DoD, risks | Claude chat | Each phase adds entries; never delete old phases |
| `CHANGELOG.md` | Permanent dated history of what was built | Coder agent | One entry per phase, at phase completion |
| `BACKLOG.md` | Technical debt, deferred items, known gaps | Reviewer agent findings | Added during reviews; marked resolved when fixed |
| `STATUS.md` | Current phase, phase table, next actions, key metrics | Claude chat | After every phase completion |
| `CLAUDE.md` | Project-specific rules for all CLI agents | Claude chat | When new rules are established |
| `AGENTS.md` | Agent roster and routing table | Claude chat | When agents are added or changed |

### Rules for all documentation files

1. **ARCHITECTURE.md and IMPLEMENTATION_PLAN.md are source of truth** — agents read
   these before every task. They must always reflect reality, not aspirations.
2. **CHANGELOG.md is append-only** — never edit old entries. Add new ones only.
3. **BACKLOG.md items are never deleted** — mark as resolved with a note instead.
4. **STATUS.md is updated after every phase** — stale status is worse than no status.
5. **Agents must not modify ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, or BACKLOG.md**
   unless explicitly instructed. Include this constraint in every coder prompt.
6. **CHANGELOG.md is updated by the coder agent at the end of each phase** — not
   during, and not by any other agent.

---

## Part 3 — Agent Roster

### Standard agents

| Agent | Invocation | Purpose | Tools |
|---|---|---|---|
| `coder` | `claude --agent coder` | All implementation tasks | Read, Write, Edit, Bash |
| `reviewer` | `claude --agent reviewer` | Code review, architecture audit, LSP audit | Read, Grep, Glob, Bash |
| `tester` | `claude --agent tester` | Test planning, coverage audits | Read, Grep, Glob, Bash |
| `docs-researcher` | `claude --agent docs-researcher` | API research, documentation audits | Read, Grep, Glob, Bash, WebSearch |
| `planner` | `claude --agent planner` | Task breakdown, risk analysis | Read, Grep, Glob |

`claude` (no agent flag) — for targeted doc-only changes: BACKLOG updates, STATUS updates,
simple file creation where no build verification is needed.

### When NOT to use an agent
- Simple doc-only changes: use standard `claude`
- Planning and decision-making: use Claude Chat, not any CLI agent
- Reviewing pasted agent output: use Claude Chat, not any CLI agent

---

## Part 4 — Phase Structure

```markdown
## Phase N — [Title]
**Goal**: One sentence.
**Prerequisite**: Which prior phase must be complete.
> **Execution note**: (optional) Any deliberate deferral or ordering constraint.

### Tasks
#### N.1 — [Task title]
- **What**: Specific implementation instructions
- **Files created/modified**: list
- **Definition of done**: Measurable, verifiable completion criteria

### Verification
### Agent
### Risks
```

Phase numbering rules: Never renumber. Insert new phases at end. Fractional phases
(2.1, 2.2) only during early architecture work.

---

## Part 5 — Standard Workflows

### Workflow 1 — Starting a new project
1. Create GitHub repo
2. Create Claude Chat project, connect GitHub repo
3. Planning conversation → ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CLAUDE.md, AGENTS.md
4. Create STATUS.md and BACKLOG.md (initially sparse)
5. Commit all docs before writing any code
6. Sync GitHub connector in Claude Chat project

### Workflow 2 — Per-phase execution (standard)
```
1. Claude Chat generates coder prompt for Phase N
2. Developer: cd ~/Developer/[project] && claude --agent coder → pastes prompt
3. Agent runs, reports completion
4. Developer: claude --agent reviewer → pastes reviewer prompt
5. Developer pastes reviewer output into Claude Chat
6. If ✅: commit and push. If ❌: Claude Chat generates fix prompt → new coder session
7. Repeat reviewer until clean ✅
8. Developer updates STATUS.md, syncs GitHub connector
```

### Workflow 3 — Per-phase execution (with research)
```
1. docs-researcher reads official API docs
2. Developer pastes research report into Claude Chat
3. Claude Chat identifies discrepancies, generates correction prompt
4. Developer runs correction in standard claude CLI, commits
5. (Optional) tester generates test plan → Claude Chat incorporates into coder prompt
6. Standard coder → reviewer cycle
```

### Workflow 4 — Fix cycle (when reviewer finds issues)
```
1. Developer pastes reviewer output into Claude Chat
2. Claude Chat categorizes: ❌ blockers vs ⚠️ minors
3. For ❌: Claude Chat generates targeted fix prompt → new coder session
4. Run reviewer again (new session). Repeat until ✅
5. For ⚠️ not fixed immediately: Claude Chat generates BACKLOG.md addition prompt
```

### Workflow 5 — Global audit phases
```
1. Audit agent (tester or reviewer) reads entire codebase
   — discovers components via Glob, does NOT rely on pre-specified list
2. Developer pastes full audit report into Claude Chat
3. Claude Chat analyzes, categorizes ALL findings
4. Claude Chat generates comprehensive fix prompt (not just top 10 — ALL actionable items)
5. Items needing live sandbox or design decision: added to BACKLOG.md
6. Standard coder → reviewer cycle for fixes
```

---

## Part 6 — Prompt Templates

See `supporting-docs/PROMPT-TEMPLATES.md` for the generalized, reusable versions
of all prompt templates. The templates below are the target project's original versions
included here for historical context.

### Coder prompt structure
```
1. READ INSTRUCTIONS — files to read in full
2. SCOPE CONSTRAINT — what not to touch
3. TASKS — numbered, one per item
4. VERIFICATION — build/test command to run
5. COMPLETION REPORT — files modified, test count, CHANGELOG update if phase end
```

### Reviewer prompt structure
```
1. READ INSTRUCTIONS — ARCHITECTURE.md, CHANGELOG.md, CLAUDE.md, IMPLEMENTATION_PLAN.md Phase N
2. REVIEW CRITERIA — architecture compliance, Swift 6 concurrency, anti-patterns,
   implementation plan compliance, test coverage, build warnings
3. OUTPUT — ✅/❌/⚠️ per finding. Verdict: Ready to commit OR Needs fixes
```

### Tester prompt structure
```
1. READ ALL files via Glob — build own inventory, do NOT use pre-specified list
2. AUDIT — per component: what's tested, what's not, related BACKLOG items, priority
3. PRIORITY SUMMARY — top gaps ranked by bug-catching likelihood
4. CONSTRAINT — report only, no code
```

### Docs-researcher prompt structure
```
1. READ — relevant ARCHITECTURE.md sections, IMPLEMENTATION_PLAN.md Phase N
2. VERIFY — specific claims against official docs (URLs provided)
3. OUTPUT — ✅ CONFIRMED vs ⚠️ DISCREPANCY with evidence and source URLs
```

---

## Part 7 — Document Maintenance Rules

| Document | Coder can modify | Reviewer can modify | Notes |
|---|---|---|---|
| `ARCHITECTURE.md` | Only if task explicitly requires | Never | Claude Chat approves all changes |
| `IMPLEMENTATION_PLAN.md` | Only if task explicitly requires | Never | Claude Chat approves all changes |
| `CHANGELOG.md` | Yes — at phase end only | Never | One entry per phase |
| `BACKLOG.md` | Yes — add/resolve items | Yes — add findings | Never delete items |
| `STATUS.md` | Yes — after phase completion | Never | Developer updates manually |
| `CLAUDE.md` | Never | Never | Claude Chat only |

### The TODO/BACKLOG contract

Every `// TODO:`, `// KNOWN GAP:`, or `// MANUAL VERIFICATION REQUIRED` comment
added to code **must** have a corresponding BACKLOG.md entry in the same commit.
Comments without BACKLOG entries are invisible to agents and will be forgotten.

---

## Part 8 — Agent Config Pack

### CLAUDE.md minimum required sections
1. Project overview — platform, Swift version
2. Layer rules — what each layer can import, what cannot cross boundaries
3. Forbidden patterns — explicit list
4. Required patterns — explicit list
5. Swift coding rules
6. LSP rules
7. Security rules
8. Agent routing table
9. Platform notes — Xcode version, API availability guards

---

## Part 9 — Decision Log (Standing Rules)

### Project management
- Do not renumber phases. Use execution notes to reorder instead.
- Markdown files over issue trackers for solo work.
- Feature inventory (Phase 13 equivalent) deferred until after stabilization phases.
- Claude Chat is the project manager, not an execution tool.

### Documentation
- docs-researcher before coder for external API integrations.
- tester before coder for phases with complex test infrastructure.
- The tester agent must discover components itself via Glob — never pre-specify a list.
- Documentation audit before README.

### Code quality
- LSP audit is a required phase, not optional.
- All TODO/KNOWN GAP comments must have BACKLOG entries in the same commit.
- Zero Swift compiler warnings is a hard requirement.
- Force unwraps forbidden in production except compile-time-proven constants.

### Testing
- Mock infrastructure before test suites.
- Pipeline integration tests are mandatory DoD for every broker/API integration phase.
- Test count is a metric — track in STATUS.md and CHANGELOG.md.

### Agents
- Each agent invocation is a new session. Never continue a coder session for a new phase.
- Reviewer sessions are always new.
- Say "continue" explicitly between tasks in long sessions. Build check after each task.

---

## Part 10 — Warning Signs

### Reviewer cycle
- Same issue category across 3+ cycles → regenerate fix prompt with more explicit instructions
- Reviewer ✅ but test count decreased → coder deleted tests. Never acceptable.
- Architecture violations in Phase 10+ → CLAUDE.md rules not clear enough. Update and re-run.

### Documentation
- ARCHITECTURE.md and code describe different patterns → run docs audit immediately
- CHANGELOG.md entry doesn't match git diff → verify before committing

### Agent behavior
- Agent modifies files it was told not to touch → stop, don't commit, re-run with scope constraints
- Agent invents API methods → hallucinating. Verify against official docs before committing.
- Agent says "I'll handle that in a follow-up" → deferring in-scope work. Add explicitly to next prompt.

### Planning
- Phase keeps cycling without ✅ → scope too large. Split it.
- Feature inventory reveals built features don't work → test coverage insufficient. Audit first.

---

## Part 11 — New Project Checklist

### Day 1 — Setup
- [ ] Create GitHub repo, create Claude Chat project, connect repo via GitHub connector
- [ ] Architecture conversation → ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, CLAUDE.md, AGENTS.md
- [ ] Create BACKLOG.md, STATUS.md, CHANGELOG.md (empty with structure)
- [ ] Create .claude/agents/ directory
- [ ] Commit all docs, sync GitHub connector

### Before each phase
- [ ] Sync GitHub connector in Claude Chat
- [ ] Confirm STATUS.md shows correct current phase
- [ ] Confirm prior phase ✅ and tests green

### After each phase
- [ ] Reviewer cycle complete (✅ verdict)
- [ ] Commit and push
- [ ] Update STATUS.md (phase ✅, current phase, test count)
- [ ] Sync GitHub connector in Claude Chat

---

## Part 12 — Reusing This Methodology

1. Use Part 11 (New Project Checklist) when starting a new project
2. Extract rules from Part 8 into that project's CLAUDE.md
3. Use prompt templates from Part 6 as starting points — customize per project
4. Apply phase structure from Part 4
5. Keep standing decisions from Part 9 — they apply to all projects

---

## Appendix A — File Templates

### STATUS.md template
```markdown
# [Project Name] — Project Status
Last updated: [date]
## Current Phase
**Phase N — [Title]** ([not started / in progress])
## Phase Completion
| Phase | Title | Status |
|---|---|---|
| 0 | [Title] | ✅ Complete |
| 1 | [Title] | ⬜ Not started |
## Key Metrics
- **Test count**: N passing, 0 failing
- **Build warnings**: 0
- **Target platform**: [platform]
## Next Actions
1. [Next phase]
```

### BACKLOG.md template
```markdown
# [Project Name] — Backlog
## Phase N — [Title]
**TD-001 — [Short title]**
File: `[path]`
[Description]
Action: [Fix]
```

### CHANGELOG.md template
```markdown
# [Project Name] — Change Log
## Phase N — [Title]
**Date**: [YYYY-MM-DD]
**Summary**: [One paragraph]
**Files created**: [list]
**Files modified**: [list]
**Test count**: [N] tests, all passing
**Build warnings**: 0
```

---

*This document was generated from the target project (2026) and represents
the distilled methodology from 25 phases of development. Update it when new standing
decisions are made.*
