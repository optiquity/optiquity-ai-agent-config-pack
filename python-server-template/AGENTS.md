# AGENTS.md

This repository is a terminal-first Python server repository.
Both Codex and Claude may perform planning, implementation, testing, review, debugging, repo operations, and documentation work here.
No work category is exclusive to one tool.

## Default workflow

1. Inspect the current repository state.
2. Read the closest relevant docs and config files before making non-trivial changes.
3. Prefer minimal, reversible edits.
4. Run the repo scripts in `scripts/` for formatting, tests, and validation.
5. Report what was verified, what was not verified, and any gaps.

## Python defaults

- Prefer `uv` for environment and dependency management.
- Prefer `ruff check` and `ruff format`.
- Prefer `pyright` for static analysis.
- Prefer `pytest` for tests.
- Keep code cross-platform.
- Keep shell scripts POSIX-friendly where practical. If Windows-specific automation is needed later, add PowerShell equivalents.

## Safety and correctness

- Do not read `.env`, `.env.*`, or `secrets/` unless explicitly required.
- Do not rewrite lockfiles or dependency constraints casually.
- Do not add networked services or background daemons without documenting the reason.
- Do not state that an external API or framework supports a feature unless that support was verified.
