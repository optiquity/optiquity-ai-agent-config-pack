# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)

Platform-agnostic agent routing for work on the pack repo itself.
Read by Claude Code, Codex, and Gemini when operating on this repo.

---

## When agents are used on the pack repo

Most pack changes are made directly by the PM chat (via Desktop Commander on
Claude Desktop, or native file write on Gemini CLI / Codex CLI). Agents are
used for specific targeted tasks:

| Situation | Agent | Notes |
|---|---|---|
| Verify capability claims against official docs | `docs-researcher` | Web search + report |
| Check consistency across template files | `reviewer` | Read-only; report only |
| Propagate a change across multiple template files | `coder` | Explicit file list required |
| Audit skill files for valid frontmatter and structure | `reviewer` | Read-only |
| Research a new platform or tool for pack support | `docs-researcher` | Analysis report |

Agents are **not** used for:
- Making architectural decisions about the pack (PM chat only)
- Writing to BACKLOG.md, CHANGELOG.md, README.md (PM chat only)
- Committing or pushing (developer only, after explicit approval)

---

## Agent behavior expectations

Every agent session on this repo:
1. Reads its tool-native context file before starting:
   Claude Code → CLAUDE.md · Codex → AGENTS.md · Gemini → GEMINI.md
   All three should also read PACK-AGENTS.md for the agent routing table.
2. Reads only the files explicitly listed in the prompt
3. Does not modify files not listed in the prompt
4. Reports what it did and confirms no unexpected changes

For `docs-researcher`: output a report only. No file writes.
For `reviewer`: output a report only. No file writes.
For `coder`: make exactly the changes listed. Report files modified.

---

## Key conventions to follow

- Commit format: `feat: vN — BD-NNN description` / `fix: description` (N = current major version)
- BD-NNN numbering: read BACKLOG.md to find next available number
- Skills live in `.claude/skills/` (Claude), `.codex/skills/` (Codex), `.gemini/skills/` (Gemini)
- Agent files: `.claude/agents/` (markdown), `.codex/agents/` (TOML), GEMINI.md sections
- Pack repo context files: CLAUDE.md (Claude), AGENTS.md (Codex), GEMINI.md (Gemini), PACK-AGENTS.md (routing table)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and confirm staged files before any commit.
