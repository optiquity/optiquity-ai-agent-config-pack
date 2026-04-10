# GEMINI.md

<!--
HOW TO USE THIS TEMPLATE

This is the Gemini CLI context file for your project. It is loaded automatically
by Gemini CLI at session start via the GEMINI.md hierarchy.

Fill in [PROJECT_NAME], [PLATFORM_TARGETS], and [TRANSPORT] during project setup.
Remove this comment block after filling in the placeholders.

This file is the Gemini CLI equivalent of CLAUDE.md. Both files should express
the same project rules — only tool-specific operating notes differ.
-->

---
*Copied from: project-template/GEMINI.md — AI Agent Config Pack v9*
*Fill in placeholders and remove this block.*
---

## Project identity

**[PROJECT_NAME]** targets [PLATFORM_TARGETS].
Transport: [TRANSPORT] (e.g., gRPC + Proto3 for first-party; REST for third-party).

## Capability policy

Gemini CLI may perform all major engineering tasks in this repository:
planning, architecture, implementation, refactoring, debugging, testing,
code review, dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform and stack defaults

<!--
Fill in the platform-specific defaults for your project. Examples:

For an iOS app:
- Target platforms: iOS, iPadOS, macOS.
- UI: SwiftUI first. UIKit interop only for platform gaps.
- Dependencies: Swift Package Manager.
- Concurrency: Swift 6 strict concurrency for new code.

For a Python server:
- Python 3.12+. uv for dependency management.
- ruff for linting. pyright strict for type checking.
- pytest + pytest-asyncio for tests.
-->

[PLATFORM_DEFAULTS — fill in per project type]

## Agent behavior

When acting in this repo:
- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, framework behavior, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.

## Skill loading

Agent prompts specify which skills to load. Skills are located in
`.gemini/skills/<name>/SKILL.md`. The PM chat selects skills based on
`PLATFORM-SKILLS.md` — the skill-selection matrix for this project.

## Phase routing — default agent assignments

All three tools (Claude Code, Codex, Gemini CLI) can execute any phase.
The defaults below identify the better system for each phase. Override
when task characteristics favor a different tool.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | architect | Multi-file context, extended reasoning |
| API and schema design | **Claude Code** | grpc-schema | Schema tools, buf integration |
| Planning / task breakdown | **Claude Code** | planner | Tiebreaker — all systems comparable |
| Dependency evaluation | **Claude Code** | docs-researcher | Web search, nuanced tradeoff analysis |
| Implementation | **Codex** | coder | Workspace-write sandbox, strong code generation |
| Code review | **Claude Code** | reviewer | Deep multi-file analysis, Bash diagnostics |
| Testing | **Codex** | tester | Pattern generation, approval flow for new files |
| Debugging | **Claude Code** | coder | Multi-step reasoning, Bash for live diagnostics |
| Refactoring | **Codex** | coder | Mechanical changes in workspace-write sandbox |
| Documentation | **Claude Code** | docs-researcher | Multi-file context aids consistency |
| Repo operations | **Codex** | repo-ops | Workspace-write sandbox, scripting strength |
| Local validation | **Codex** | repo-ops | Workspace-write sandbox; can execute scripts |

To invoke any agent: `./agent-run.sh <cli> --agent <name>` (see `./agent-run.sh --help`)

*This table reflects quality-optimized defaults. For cost-optimized routing
alternatives (e.g., using Gemini CLI Flash for reviewer, tester, and
docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*

## Gemini CLI operating notes

- **Session save:** Use `/chat save <tag>` before ending a session.
- **Session resume:** Use `/chat resume <tag>` to restore.
- **Context compression:** Use `/compress` when context grows large.
- **Cross-session memory:** Use `save_memory` to persist facts to `~/.gemini/GEMINI.md`.
- **Plan Mode:** Use Plan Mode (read-only) for all review and research tasks. This is the default behavior.
- **File writes:** Gemini CLI native file write tools. No Desktop Commander needed.
- **Checkpointing:** Automatic snapshots are available for recovery.
- **Session files are local.** Sync state between machines via project docs committed to the repo, not session files.

## Deferral comments and BACKLOG hygiene

Use the same typed deferral comment format as all other tools:

```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(severity): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```

Use the comment marker for the language you are writing (`//` for Swift/C/C++,
`#` for Python). Rules:
- Always write `TD-TBD` — never a real TD number.
- Report every deferral in the completion report.
- Do not write to BACKLOG.md, STATUS.md, CHANGELOG.md, or any .md in the project root.

## Build and repo hygiene

- Do not commit secrets, generated code, or machine-specific config.
- Prefer repo-local scripts over undocumented manual steps.
- At the end of every implementation phase, include a "Proposed CHANGELOG entry"
  in the completion report. Do not write to CHANGELOG.md directly.
