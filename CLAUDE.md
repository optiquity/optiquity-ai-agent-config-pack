# CLAUDE.md — AI Agent Config Pack (Pack Repo)

This file is read by Claude Code CLI agents working on the pack repo itself.
It is NOT a template and is NOT copied to coding projects.

---

## What this repo is

The DHS AI Agent Config Pack provides
versioned Claude Code, Codex, and Gemini CLI agent configuration files for
Swift / Python / gRPC projects. It ships template directories, agent files,
skills, scripts, and supporting documentation.

---

## Repo structure

See `README.md` — the Repository Layout section is the authoritative reference.
Do not rely on any hardcoded directory listing here; the structure changes between
major versions.

Key files to read before working on the pack:
- `README.md` — version history and layout
- `BACKLOG.md` — open BD-NNN items
- `PACK-CHAT.md` — PM chat operating rules

---

## Rules for agents working on this repo

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
- Bare major tag always floats to the latest minor (e.g. v8 → v8.6, then → v8.7)
- Tag move sequence: delete local + remote, recreate, push

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
- This file (CLAUDE.md)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and show staged files before committing.
