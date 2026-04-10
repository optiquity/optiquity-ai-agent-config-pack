# GEMINI.md — AI Agent Config Pack (Pack Repo)

Context file for Gemini CLI working on this repo. Loaded automatically at session start.
Keep this file concise — it is loaded into every prompt.

---

## Repo identity

DHS AI Agent Config Pack: versioned Claude Code, Codex, and Gemini CLI agent
configuration files for Swift / Python / gRPC projects. Ships template directories,
agent files, skills, scripts, and supporting documentation.

Key docs: `README.md` (version table), `BACKLOG.md` (BD-NNN items),
`CHANGELOG.md` (version history), `PACK-CHAT.md` (PM chat rules),
`supporting-docs/METHODOLOGY.md` (project methodology reference).

---

## Conventions

**Commit format:** `feat: vN — BD-NNN description` | `fix: description` | `docs: description`
Where N is the current major version — read from README.md version table before committing.

**Versioning:** Minor tags (vN.M, vN.M+1) for incremental changes. Major tags for
breaking changes or large additions. Bare major tag always floats to latest minor.

**BD numbering:** Always read BACKLOG.md to find the highest existing BD number,
then increment by 1. Never assign a BD number from memory.

**File write restrictions:**
- BACKLOG.md: PM chat only, after user approval
- README.md version table: PM chat only
- PACK-CHAT.md / CLAUDE.md / AGENTS.md / PACK-AGENTS.md / GEMINI.md: PM chat only
- Template files and supporting-docs: may modify when task explicitly requires

**No commit or push without explicit user approval.**

---

## Gemini CLI operating notes

Use `/chat save <tag>` to save session state before ending a session.
Use `save_memory` to persist cross-session facts to ~/.gemini/GEMINI.md.
Use Plan Mode (read-only before any edits — current default behavior) for all read-only tasks (reviewer, docs-researcher).
Native file write tools replace Desktop Commander — both achieve the same result.
Session files are local; sync state between machines via project docs (committed to repo).
