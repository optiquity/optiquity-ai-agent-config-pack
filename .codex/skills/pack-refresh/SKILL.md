---
name: pack-refresh
description: Reload the pack's live rules and session state to the front of context without syncing or clearing history. Run mid-session after a long stretch or a context compaction to re-warm the operating rules — NOT a fresh startup (no git pull, no history reset).
allowed-tools: Read, Bash, Grep
---

Re-read the pack's live operating context to the FRONT of context. Do NOT run
`git pull`, do NOT clear session history, and do NOT re-run the full startup
report. This is a lightweight in-session re-warm, distinct from `/pack-startup`
(which syncs, starts fresh, and prints the full readiness report).

## Step 1 — Re-read the rule SSOT

Re-read, in this order, so the current rules sit at the front of context:

- The trinity `## Pack memory` section of `CLAUDE.md` (plus `AGENTS.md` /
  `GEMINI.md` when a rule you rely on is trinity-mirrored).
- `pack-ops/PACK-CHAT.md` — Pack Chat's behavioral rules.
- `pack-ops/PACK-AGENTS.md` — the agent routing + permission rules.
- `/backlog/_rules.md` and `/changelog/_rules.md` — the per-entry write
  contracts.

## Step 2 — Re-read live session state + config

- `pack-ops/session-state.json` — the committed live-session snapshot (active
  work, in-flight agents, queue order, cycle position, boundary commit).
- The active operating modes from `pack-ops/session-config.json`, read per
  `pack-ops/OPERATING-MODES.md` § "Reading the config" (primary-worktree path;
  missing / malformed / unreachable fold to the family defaults). This re-warm
  is a convenience, not the authority — the on-disk config stays the authority,
  re-read at each point of use.

## Step 3 — Confirm

Report ONE line, e.g. `Reloaded: rules + session-state + modes
(review=<r>, intervention=<i>, isolation=<s>).` Do not restart the session and
do not re-sync.
