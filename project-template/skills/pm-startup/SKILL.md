---
name: pm-startup
description: PM chat startup and orientation. Run when starting fresh, resuming on a new machine, or after compaction. Reads current project state from repo files and reports ready status. Do NOT run on normal same-machine resumes — session history is sufficient.
allowed-tools: Read, Bash, Grep
---

You are the PM chat for this project. Run this startup sequence now and report
the result. Do not ask questions — execute each step in order.

## Step 1 — Sync repo

```bash
git pull
```
Note what was fetched, or confirm "already up to date."

## Step 2 — Read core state files

Read these files in full:
- `BACKLOG.md`
- `STATUS.md`
- `PM-CHAT.md`
- `PLATFORM-SKILLS.md`

Read only the most recent dated section from `CHANGELOG.md`.

Identify the current phase from STATUS.md, then read only that phase's section
from `IMPLEMENTATION_PLAN.md`.

Read the first 5 lines of `METHODOLOGY.md` to get the version number.

Use the Document locations section in the project context file to resolve file paths.

## Step 3 — Read active skills

Read the `## Skill loading` section of the project context file. Find the **Active skills:**
line and extract the skill list. If the line still contains the placeholder text
(square brackets), note that active skills have not been set yet — the PM chat
must populate this during kickoff.

## Step 4 — Check RAG ingest freshness

Run:
```bash
git log -1 --format="%H %cd" --date=short -- docs/pack/METHODOLOGY.md
```

If this file was modified since the last known RAG ingest, re-ingest it now
using the mcp-local-rag tool before any queries. If unsure of last ingest date,
re-ingest it.

## Step 5 — Check for TD-TBD sentinel

```bash
grep -rn "TD-TBD" . --include="*.swift" --include="*.py" --include="*.md" \
  --exclude-dir=".git" 2>/dev/null | head -20
```

Any result is a defect requiring immediate attention before proceeding.

## Step 6 — Report current state

Read the project name from the heading at the top of `PM-CHAT.md` — it will be
the first `#` heading (e.g., `# OptiquityTrader — PM Chat Instructions`).
Use that name in the output summary below.
Output a summary in exactly this format:

---
**PM Chat Ready — [project name from PM-CHAT.md]**

**Current phase:** Phase N — [title] ([not started / in progress / complete])
**Open BACKLOG items:** [count of Status: Open + Status: Unblocked]
**Last TD number:** TD-NNN (or "none yet" if BACKLOG is empty)
**TD-TBD check:** [Clean / N instances found — [files]]
**Last commit:** [date] — [commit summary from git log -1 --oneline]
**Pack version:** [read from the version header line in METHODOLOGY.md]
**Skills profile:** [project type from PLATFORM-SKILLS.md — e.g., "iOS Swift app" or "Python gRPC server"]
**Active skills:** [list from project context file, or "not set — populate during kickoff"]

**Awaiting instructions.**
---
