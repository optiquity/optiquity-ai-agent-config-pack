# Python server template

This template is intended for Python server repositories used from the terminal, VS Code, and the Claude or Codex apps.

## Recommended toolchain

- Python 3.12+
- uv
- pytest
- pyright
- ruff

## Quick start

```bash
./scripts/bootstrap.sh
./scripts/validate.sh
```

## Important files

- `CLAUDE.md` - Claude project instructions
- `AGENTS.md` - Codex project instructions
- `.claude/` - Claude project config, agents, and skills
- `.codex/` - Codex project config, agents, and skills
- `pyproject.toml` - Python project config and dev tools
- `pyrightconfig.json` - static typing config
- `scripts/` - bootstrap, format, test, and validate entry points
