---
name: pack-status
description: Show a quick pack status snapshot — repo state, live session frontier, current backlog item, and the next queued items. Run for a fast orientation without a full startup. Reads state files directly; no sync, no history reset.
allowed-tools: Read, Bash, Grep
---

Report a concise status snapshot from live state files. Do NOT sync, spawn
agents, or clear history.

## Step 1 — Repo state

```bash
git status -s
git log -1 --oneline
```

Summarize: clean or dirty (with the short list) and the last commit.

## Step 2 — Session frontier

Read `pack-ops/session-state.json` — the committed live-session snapshot. Note
the active backlog item (BD) and its sub-step, the in-flight agents, the queue
order, the parallelization mode, the in-commit review/fix-cycle position, and
the boundary commit. If the file is absent, report `no live session — clean
start`.

## Step 3 — Version + next queued

- Read the current version from the first data row of the `README.md`
  `## Version History` table (sorted newest-first).
- Read `/backlog/_toc.md` for the next few queued items.

## Step 4 — Report

Output a compact block:

- **Repo:** clean / dirty (short list); last commit `<summary>`.
- **Session:** active BD + sub-step; cycle position; boundary commit; or
  `no live session`.
- **Version:** the current version row.
- **Next queued:** the next few backlog items.
