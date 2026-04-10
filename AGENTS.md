# AGENTS.md — AI Agent Config Pack (Pack Repo)

Context file for Codex CLI agents working on this repo. Loaded automatically
at the start of every Codex session. Keep this file accurate — it governs how
Codex operates on the pack repo.

This file is NOT a template and is NOT copied to coding projects.

---

## What this repo is

The DHS AI Agent Config Pack provides versioned Claude Code, Codex, and Gemini
CLI agent configuration files for Swift / Python / gRPC projects. It ships
template directories, agent files, skills, scripts, and supporting documentation.

Key files to read before working on the pack:
- `README.md` — version history and repo layout
- `BACKLOG.md` — open BD-NNN items
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
- Bare major tag always floats to the latest minor

**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first

**What agents may modify:**
- Any file in template directories when the task explicitly requires it
- Files in supporting-docs/ when the task explicitly requires it
- CHANGELOG.md only at version boundaries with explicit instruction
- Scripts in template directories

**What agents must never modify without explicit instruction:**
- BACKLOG.md (PM chat only, after user approval)
- README.md version table (PM chat only)
- PACK-CHAT.md (PM chat operating instructions)
- CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md (PM chat only)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and confirm staged files before committing.
