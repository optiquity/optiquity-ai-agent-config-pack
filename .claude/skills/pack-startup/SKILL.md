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

Read the version table section from `README.md` — the rows under
`## Version History` up to and including the most recent entry.

## Step 3 — Report current state

Read the current pack version from the most recent row in the README version table.
Output a summary in exactly this format:

---
**Pack Chat Ready — DHS AI Agent Config Pack**

**Current version:** v[N.N] — [brief description from README]
**Open backlog items (BD):** [count of Status: Open + Status: Unblocked]
**Last BD number:** BD-NNN (or "none" if empty)
**Last commit:** [date] — [summary from git log -1 --oneline]

**Awaiting instructions.**
---
