---
name: pack-startup
description: Pack chat startup and orientation. Run when starting fresh, resuming on a new machine, or after compaction. Reads current pack state from repo files and reports ready status. Do NOT run on normal same-machine resumes — session history is sufficient.
allowed-tools: Read, Bash, Grep
---

You are the CLI chat assistant for the DHS AI Agent Config Pack. Run this startup
sequence now and report the result. Do not ask questions — execute each step in order.

## Step 1 — Sync repo

```bash
git pull
```
Note what was fetched, or confirm "already up to date."

## Step 2 — Read core state files

Read `BACKLOG.md` in full.

Read only the most recent dated entry from `CHANGELOG.md`.

Read the version table section from `README.md` — the table under
`## Version History` is sorted newest-first. The first data row is the
current version.

Read `PACK-CHAT.md` in full — this establishes your behavioral rules
for this session.

## Step 3 — Check CI tooling

Check whether the GitHub MCP server is available by looking for GitHub-related
MCP tools (e.g., `list_workflow_runs`). This is a detection step — do not
fail if it is absent.

- If available: note "GitHub MCP server: available — CI status checks will
  be automatic after pushes."
- If not available: note "GitHub MCP server: not configured — after each
  push, I will remind you to check the Validate Pack workflow in the GitHub
  Actions tab. To enable direct CI checking, see the GitHub MCP server note
  in PACK-CHAT.md."

## Step 4 — Report current state

Read the current pack version from the first data row in the README version table
(the table is sorted newest-first).
Output a summary in exactly this format:

---
**Pack Chat Ready — DHS AI Agent Config Pack**

**Current version:** v[N.N] — [brief description from README]
**Open backlog items (BD):** [count of Status: Open + Status: Unblocked]
**Last BD number:** BD-NNN (or "none" if empty)
**Last commit:** [date] — [summary from git log -1 --oneline]
**CI tooling:** [GitHub MCP available / not configured — manual check needed]

**Awaiting instructions.**
---
