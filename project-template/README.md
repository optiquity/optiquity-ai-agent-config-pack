# Project Template — AI Agent Config Pack v10

This directory is the unified project template. Copy it to start a new project:

```bash
cp -r /path/to/pack/project-template/. /path/to/your-project/
```

Then copy the supporting docs individually (they are not part of this template). METHODOLOGY.md lives under `docs/pack/` per V10-DESIGN.md Part 7 §7.6 (alongside other pack-distributed docs):

```bash
mkdir -p /path/to/your-project/docs/pack
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your-project/docs/pack/METHODOLOGY.md
```

See `QUICKSTART.md` in the pack root for the full setup procedure.

## What this template contains

| Category | Files | Notes |
|---|---|---|
| Agent files | `.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md` | 16 agents (8 core + auditor parent + 7 auditor subagents) |
| Skills | `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` | 30 skills per tool. Distributed from the pack's `project-template/skills/` at project creation by `init-project.sh` and committed to git. No `skills/` directory at the project root. |
| Scripts | `scripts/*.sh`, `agent-run.sh` | 15 scripts + launcher. See the Scripts table in CLAUDE.md. |
| Context files | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | One per tool. Fill in `[PLACEHOLDER]` sections per project type. |
| PM chat docs | `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md` | PM chat operational docs. PM-CHAT.md and PACK-FEEDBACK.md have `[PROJECT_NAME]` placeholders. |
| Config | `.claude/settings.json`, `.codex/config.toml`, `.mcp.json.example` | Tool-specific configuration. |
| Conditional | `proto/`, `pyproject.toml`, `pyrightconfig.json`, `server/` | Remove if project does not use gRPC/Python (see below). |

## Directory boundary rule

The pack has two directories that produce project files:

- **`project-template/`** (this directory) — everything here is copied as a
  whole via `cp -r`. These are structural files the project needs to function:
  agents, skills, scripts, config, context files, PM chat docs.

- **`supporting-docs/`** — docs copied individually during setup (METHODOLOGY.md
  to `docs/pack/`) or read from the pack without copying (QUICKSTART.md,
  DEPENDENCIES.md, CLI-PM-SETUP.md, etc.). These are process and reference docs.

If a file is part of the project's runtime agent infrastructure, it belongs in
`project-template/`. If it is a methodology or reference document, it belongs
in `supporting-docs/`.

## Conditional files — remove what you don't need

After copying the template, remove files that don't apply to your project:

| Project type | Remove |
|---|---|
| Swift-only (no Python, no gRPC) | `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/` |
| Swift + gRPC (no Python) | `pyproject.toml`, `pyrightconfig.json`, `server/` |
| Python-only (no Swift, no gRPC) | `proto/` (keep pyproject.toml and server/) |
| Python + gRPC | Nothing to remove |
| Swift + Python + gRPC (monorepo) | Nothing to remove |

## Skill distribution

The canonical skill library lives in the pack at `project-template/skills/`.
At project creation, `init-project.sh` distributes skills directly from the
pack to each tool's expected location:

- `<pack>/project-template/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md`
- `<pack>/project-template/skills/<name>/SKILL.md` → `.codex/skills/<name>/SKILL.md`
- `<pack>/project-template/skills/<name>/SKILL.md` → `.gemini/skills/<name>/SKILL.md`

The distributed files are committed to git. Teammates who clone the project
get skills via git — no pack access required after initial setup. There is
no `skills/` directory at the project root. To update skills after a pack
version upgrade, see the migration guide.
