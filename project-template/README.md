# AI Agent Config Pack — Installed Files (v11)

This project has the AI Agent Config Pack installed. The pack provides the
Claude Code, Codex, and Antigravity CLI agent configuration that drives planning,
architecture, implementation, review, and testing in this repo.

Start with `pm-startup` (or your CLI's equivalent). For the full operating
model, read `docs/pack/METHODOLOGY.md`.

## What the pack installs

| Category | Location | Notes |
|---|---|---|
| Agent files | `.claude/agents/*.md`, `.codex/agents/*.toml`, `.agents-plugin/optiquity-agents/agents/*.md` | 16 agents (8 core + auditor parent + 7 auditor subagents) |
| Skills | `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, `.agents/skills/<name>/SKILL.md` | One copy per tool, committed to git. Custom skills use the `x-` prefix. |
| Scripts | `scripts/*.sh`, `agent-run.sh` | Build, test, and validation scripts plus the agent launcher. See the Scripts table in `CLAUDE.md`. |
| Context files | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | One per tool, at the project root. Fill in `[PLACEHOLDER]` sections per project type. |
| PM chat docs | `docs/pack/PM-CHAT.md`, `docs/pack/PLATFORM-SKILLS.md`, `docs/pack/PACK-FEEDBACK.md` | PM chat operational docs. |
| Pack docs | `docs/pack/METHODOLOGY.md`, `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/prompts/` | Methodology and reference docs. |
| Config | `.claude/settings.json`, `.codex/config.toml`, `.codex/config.toml.example`, `.mcp.json.example`, `.agents/mcp_config.json.example` | Tool-specific configuration. |
| Conditional | `proto/`, `pyproject.toml`, `pyrightconfig.json`, `server/` | Present only for projects that use gRPC / Python. |
