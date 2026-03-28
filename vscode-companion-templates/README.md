# VS Code Companion Templates

Machine-level VS Code configuration for Python server and monorepo projects.

## What's here

```
.vscode/
├── settings.json       Python/Ruff/Pyright editor settings and format-on-save
├── extensions.json     Recommended extensions for Python + gRPC development
└── tasks.json          Task definitions wired to project scripts
```

## Installation

Copy `.vscode/` into your project root:

```bash
cp -r /path/to/pack/vscode-companion-templates/.vscode /path/to/your/project/.vscode
```

These files are safe to commit — they contain no secrets or machine-specific paths.
If you prefer them local-only, add `.vscode/` to your project `.gitignore`.

## Scope

These files are intended for:
- `python-server-template` projects
- `apple-app-plus-python-server-template` (monorepo) projects — Python side only

They are **not** needed for `apple-app-template` projects (Xcode-only).

## Notes

- `settings.json` assumes `ruff` and `pyright` are installed in the project virtualenv
  or globally via `uv`. Adjust `python.defaultInterpreterPath` if your venv is elsewhere.
- `tasks.json` tasks call `./scripts/*.sh` — the scripts must exist and be executable.
- Extensions in `extensions.json` are recommendations only; VS Code will prompt to install.
