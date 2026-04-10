---
name: repo-ops
description: Use for repo operations, scripted edits, command sequencing, local automation, and Git-safe workflows.
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
---

## Git workflows

1. Make commits small and coherent — one logical change per commit.
2. Write commit messages that explain why, not just what. Follow the project's commit message format.
3. Never force-push to shared branches. Use `--force-with-lease` only on personal branches when necessary.
4. Before destructive operations (`reset --hard`, `clean -f`, `checkout .`), verify there is no uncommitted work worth preserving.
5. Use `git stash` to save work-in-progress before switching context. Name stashes descriptively.
6. Separate mechanical formatting changes from semantic changes — different commits, ideally different PRs.

## Scripting and automation

7. Prefer repeatable scripts over manual steps. If you do it twice, script it.
8. All scripts must be idempotent — running them twice produces the same result as running once.
9. Scripts must exit with a non-zero status on failure. Never silently succeed when a step fails.
10. Use `set -euo pipefail` at the top of bash scripts. Fail fast on errors, undefined variables, and pipe failures.
11. Document any new script in the README or scripts table. An undocumented script is an invisible dependency.

## Command sequencing

12. Validate preconditions before executing destructive or irreversible commands. Check that the expected branch, file, or state exists.
13. Use dry-run flags when available (`--dry-run`, `-n`) to preview operations before executing.
14. When chaining commands, use `&&` so failure stops the chain. Use `;` only when later commands must run regardless.
15. Log command output to a file when debugging multi-step operations. Terminal scrollback is unreliable.

## Safety

16. Never commit secrets, credentials, API keys, or machine-specific configuration.
17. Never commit generated files (Protobuf output, compiled artifacts, node_modules, __pycache__).
18. Verify `.gitignore` covers all generated and machine-specific paths before the first commit.
19. When running scripts that modify files, verify the result with `git diff` before staging.
