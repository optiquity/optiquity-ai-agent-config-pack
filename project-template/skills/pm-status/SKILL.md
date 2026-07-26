---
name: pm-status
description: Show a quick project status snapshot — repo state, live PM-session frontier, active operating modes, current backlog (TD items + phase), and the next queued items. Run for a fast orientation without a full startup. Reads state files directly; no sync, no history reset.
allowed-tools: Read, Bash, Grep
---

Report a concise status snapshot from live state files. Do NOT sync, spawn
agents, write any file, or clear history — this skill only reads.

## Step 1 — Repo state

```bash
git status -s
git log -1 --oneline
```

Summarize: clean or dirty (with the short list) and the last commit.

## Step 2 — Session frontier

Read `docs/project/pm-session-state.json` — the committed live-session snapshot.
Note the active work item and its sub-step, the in-flight agents to re-spawn,
the queue order, the parallelization mode, the review/fix-cycle position, and the
boundary commit. If the file is absent, report `no live session — fresh session`.

## Step 3 — Active operating modes

Read the three modes from the per-clone PM session config, folding an absent /
malformed / unreachable config to the family defaults (`itemized` / `full` /
`read-write-only`) per `docs/pack/PM-OPERATING-MODES.md` § "Reading the config".
This is a read only — never write the config here.

```bash
cfg="$(git rev-parse --show-toplevel 2>/dev/null)/docs/project/pm-session-config.json"
rm=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("review_mode","itemized"))' "$cfg" 2>/dev/null || echo itemized)
im=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("intervention_mode","full"))' "$cfg" 2>/dev/null || echo full)
sm=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("isolation_mode","read-write-only"))' "$cfg" 2>/dev/null || echo read-write-only)
echo "modes: review=$rm intervention=$im isolation=$sm"
```

## Step 4 — Version + backlog

- Read the project version from the version header line of `docs/pack/METHODOLOGY.md`
  (a runtime-installed file; if absent, report `version: not installed`).
- List the `docs/project/backlog/` tree and read its generated `_toc.md` index for
  the open TD count and the next few queued items; if the tree is not provisioned
  yet, report `backlog: not provisioned`.
- List the `docs/project/implementation-plan/` tree (or read `STATUS.md`) for the
  current phase; if absent, report `phase: not provisioned`.

## Step 5 — Report

Output a compact block:

- **Repo:** clean / dirty (short list); last commit `<summary>`.
- **Session:** active work + sub-step; cycle position; boundary commit; or
  `no live session`.
- **Modes:** review=`<r>`, intervention=`<i>`, isolation=`<s>` (defaults if unset;
  isolation is Claude-only enforcement).
- **Version:** the project version, or `not installed`.
- **Backlog:** open TD count; current phase.
- **Next queued:** the next few backlog items, or `not provisioned`.
