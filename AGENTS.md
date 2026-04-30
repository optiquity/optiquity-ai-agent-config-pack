# AGENTS.md — AI Agent Config Pack (Pack Repo)

Context file for Codex CLI agents working on this repo. Loaded automatically
at the start of every Codex session. Keep this file accurate — it governs how
Codex operates on the pack repo.

This file is NOT a template and is NOT copied to coding projects.

---

## What this repo is

The Optiquity AI Agent Config Pack provides versioned Claude Code, Codex, and Gemini
CLI agent configuration files for Swift / Python / gRPC projects. It ships
template directories, agent files, skills, scripts, and supporting documentation.

Key files to read before working on the pack:
- `README.md` — version history and repo layout
- `BACKLOG.md` — open BD-NNN items
- `CHANGELOG.md` — version history details
- `PACK-CHAT.md` — PM chat operating rules
- `PACK-AGENTS.md` — agent routing table for pack development work

---

## Rules for Codex agents working on this repo

**Commit message format:**
```
feat: vN — BD-NNN short description
fix: brief description of what was corrected
docs: brief description of documentation change
```
Where N is the current major version (read from README.md version table).

**Versioning:**
- Minor versions (vN.0, vN.1, ...) for incremental changes
- Major versions for large additions or breaking changes
- Bare major tag always floats to the latest minor (e.g. v9 → v9.0, then → v9.1)
- Tag move sequence: delete local + remote, recreate, push

**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first

**What agents may modify:**
- Any file in template directories when the task explicitly requires it
- Files in supporting-docs/ or maintenance-docs/ when the task explicitly requires it
- CHANGELOG.md only at version boundaries with explicit instruction
- Scripts in template directories

**Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md:**
When modifying `project-template/CLAUDE.md`, always make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit.
These three files must express the same project rules. The only exception is a
change that is provably tool-specific (e.g., Codex TOML config syntax). Symmetry
is the default; asymmetry requires justification. This rule also applies to the
pack-repo copies of these three files.

**CI validation:** The `Validate Pack` GitHub Actions workflow runs on
every push. If it fails, fix before proceeding. Read the Actions log —
errors name the exact file and problem. Never skip or disable the workflow.

**What agents must never modify without explicit instruction:**
- BACKLOG.md (PM chat only, after user approval)
- README.md version table (PM chat only)
- PACK-CHAT.md (PM chat operating instructions)
- CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md (PM chat only)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and show staged files before committing.
