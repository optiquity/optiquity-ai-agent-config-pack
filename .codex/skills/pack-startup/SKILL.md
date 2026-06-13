---
name: pack-startup
description: Pack chat startup and orientation. Run when starting fresh, resuming on a new machine, or after compaction. Reads current pack state from repo files and reports ready status. Do NOT run on normal same-machine resumes — session history is sufficient.
allowed-tools: Read, Bash, Grep
---

You are the CLI chat assistant for the Optiquity AI Agent Config Pack. Run this startup
sequence now and report the result. Do not ask questions — execute each step in order.

## Step 1 — Sync repo

```bash
git pull
```
Note what was fetched, or confirm "already up to date."

## Step 2 — Read core state files

Read the `/backlog/` per-entry tree (start with `/backlog/_toc.md` for
the index, then individual `/backlog/BD-NNN.md` entries as needed).

Read only the most recent release from the `/changelog/` per-entry tree
(`/changelog/_toc.md` lists releases newest-first; read the top entry).

Read the version table section from `README.md` — the table under
`## Version History` is sorted newest-first. The first data row is the
current version.

Read `pack-ops/PACK-CHAT.md` in full — this establishes your behavioral rules
for this session.

Pack streams under `/backlog/` and `/changelog/` are per-entry trees —
the SOLE source of truth and readable form of the committed state
(each with a generated `_toc.md` index; the committed repo is always
flat-file — a local tracker opt-in changes the write channel). Read
`/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream
contract before any per-entry edit. There is no
monolithic mirror — BD-203 deleted `pack-ops/BACKLOG.md` +
`pack-ops/CHANGELOG.md`.

## Step 3 — Check CI tooling

Check whether the GitHub MCP server is available by looking for GitHub-related
MCP tools (e.g., `list_workflow_runs`). This is a detection step — do not
fail if it is absent.

- If available: note "GitHub MCP server: available — CI status checks will
  be automatic after pushes."
- If not available: note "GitHub MCP server: not configured — after each
  push, I will remind you to check the Validate Pack workflow in the GitHub
  Actions tab. To enable direct CI checking, see the GitHub MCP server note
  in `pack-ops/PACK-CHAT.md`."

## Step 4 — Report current state

Read the current pack version from the first data row in the README version table
(the table is sorted newest-first).
Output a summary in exactly this format:

---
**Pack Chat Ready — Optiquity AI Agent Config Pack**

**Current version:** v[N.N] — [brief description from README]
**Open backlog items (BD):** [count of Status: Open + Status: Unblocked]
**Last BD number:** BD-NNN (or "none" if empty)
**Last commit:** [date] — [summary from git log -1 --oneline]
**CI tooling:** [GitHub MCP available / not configured — manual check needed]

**Awaiting instructions.**
---

<!--
Steps 5–7 are reserved. Step 7 is the V1 §10.2 tracker-mode triage
queue (provider.list filter=label:'needs-triage'); a later BD adds it
when tracker mode lands in pack-startup. Steps 5 and 6 are open for
future surface additions. The Step 8 numbering is fixed by V3 §28.1.9
to keep the recommendation check at the documented insertion point
regardless of when the intermediate steps land.
-->

## Step 8 — Inflection-point recommendation check (deferred)

The D-19 tracker opt-in recommendation is DEFERRED (BD-214): tracker
integration is deferred indefinitely and flat-file per-entry is the sole
supported mode, so this step surfaces nothing. The recommendation system
(`scripts/lib/recommendation.sh`) is retained dormant and test-covered
for a future resumption; the step number is reserved.
