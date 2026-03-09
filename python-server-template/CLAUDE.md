# CLAUDE.md

This repository is a Python server repository intended for terminal-first workflows in Claude Code, Codex CLI, VS Code, and the standalone Claude and Codex apps.

## Scope

Both Claude and Codex may perform all major work categories in this repository:
- planning
- architecture
- implementation
- refactoring
- debugging
- testing
- review
- dependency review
- repository operations
- documentation

No task category is reserved exclusively for one tool.
Default preferences are only preferences.

## Platform and runtime goals

- Server code must run on macOS, Linux, and Windows unless a file or dependency explicitly documents a platform-specific exception.
- Prefer Python 3.12+ unless a project constraint requires otherwise.
- Prefer `uv` for Python runtime and dependency management.
- Prefer `pytest` for tests.
- Prefer `ruff` for linting and formatting.
- Prefer `pyright` for static type checking.

## Engineering defaults

- Correctness first.
- Prefer simple, explicit APIs.
- Prefer immutable data where practical.
- Treat global mutable state as a code smell unless required by framework boundaries.
- Validate inputs at I/O boundaries.
- Keep side effects near the edge of the system.
- Do not claim library or API behavior without verifying it against current official documentation when possible.

## Dependency policy

- Add new dependencies only with a short justification.
- Prefer mature packages with active documentation.
- Pin or constrain versions deliberately.
- Prefer cross-platform libraries and tools.
- Avoid dependencies that force a single editor, IDE, shell, or hosting platform unless required.

## Layout expectations

Common directories in this repo may include:
- `src/` or package directories for app code
- `tests/` for automated tests
- `scripts/` for repo automation
- `docs/` for architecture notes, ADRs, or API references

## Validation rules

Before claiming work is done, run the strongest applicable checks that are available locally.
The validation scripts in `scripts/` are the default entry points:
- `./scripts/bootstrap.sh`
- `./scripts/format.sh`
- `./scripts/test.sh`
- `./scripts/validate.sh`

If a tool is not installed, say that explicitly instead of pretending validation passed.
