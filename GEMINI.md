# GEMINI.md — AI Agent Config Pack (Pack Repo)

Context file for Gemini CLI working on this repo. Loaded automatically at session start.
Keep this file concise — it is loaded into every prompt.

## Quick reference

- **Pack commands:** run `pack help` for the full verb list, or `/pack-help` in your CLI.
- **Recommended first action:** run `pack-startup` (or your CLI's equivalent).

---

## Repo identity

Optiquity AI Agent Config Pack: versioned Claude Code, Codex, and Gemini CLI agent
configuration files for Swift / Python / gRPC projects. Ships template directories,
agent files, skills, scripts, and supporting documentation.

Key docs: `README.md` (version table), `BACKLOG.md` (BD-NNN items),
`CHANGELOG.md` (version history), `PACK-CHAT.md` (PM chat rules),
`PACK-AGENTS.md` (agent routing for pack work).

---

## Conventions

**Commit format:** `feat: vN — BD-NNN description` | `fix: description` | `docs: description`
Where N is the current major version — read from README.md version table before committing.

**Versioning:** Minor tags (vN.M, vN.M+1) for incremental changes. Major tags for
breaking changes or large additions. Bare major tag always floats to latest minor.
Tag move sequence: delete local + remote, recreate, push.

**BD numbering:** Always read BACKLOG.md to find the highest existing BD number,
then increment by 1. Never assign a BD number from memory.

**What agents may modify:**
- Template files, supporting-docs/, maintenance-docs/: when task explicitly requires
- CHANGELOG.md: only at version boundaries with explicit instruction
- Scripts in template directories

**What agents must never modify without explicit instruction:**
- BACKLOG.md: PM chat only, after user approval
- README.md version table: PM chat only
- PACK-CHAT.md / CLAUDE.md / AGENTS.md / PACK-AGENTS.md / GEMINI.md: PM chat only

**Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md:**
When modifying `project-template/CLAUDE.md`, make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit.
Same project rules in all three. Only exception: provably tool-specific changes.
This rule also applies to the pack-repo copies of these three files.

**CI validation:** The `Validate Pack` GitHub Actions workflow runs on every push.
If it fails, fix before proceeding. Never skip or disable the workflow.

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and show staged files before committing.

---

## Gemini CLI operating notes

Use `/chat save <tag>` to save session state before ending a session.
Use `save_memory` to persist cross-session facts to ~/.gemini/GEMINI.md.
Read-only agents (pack-reviewer, pack-docs-researcher) run in default mode — per-command approval. Do not use Plan Mode (`--approval-mode=plan`); it blocks all command execution. Invoke pack agents directly (`gemini` then `@pack-reviewer`) — the pack repo does not have agent-run.sh.
Native file write tools replace Desktop Commander — both achieve the same result.
Session files are local; sync state between machines via project docs (committed to repo).
