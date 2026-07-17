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
flat-file). Read
`/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream
contract before any per-entry edit. There is no monolithic mirror.

Read `pack-ops/session-state.json` — the committed live-session snapshot.
If absent: no live session in progress. If present: note the active BD(s)
and per-BD sub-step, the in-flight agents to re-spawn, the queue order,
the parallelization mode, the pending decisions, the in-commit
review/fix-cycle position, and the boundary commit SHA. Report these on
the Step-4 `**Resume:**` line and surface the re-spawn list so the
in-flight agents can be re-launched from the boundary commit.

## Step 3 — Check CI tooling

Check whether the recommended GitHub MCP server is available by looking for
GitHub-related MCP tools (e.g., `get_me`). This is a detection step — do not
fail if it is absent. CI workflow status is read via `gh run list` after each
push regardless of MCP; the server adds direct workflow-run status checks
when its `actions` toolset is enabled.

- If available: note "GitHub MCP server: available — GitHub queries run
  directly; with the `actions` toolset, CI status read directly."
- If not available: note "GitHub MCP server: not configured — CI status still
  checked via `gh run list` after each push. To enable direct CI checking, see
  the GitHub MCP server note in `pack-ops/PACK-CHAT.md`."

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
**CI tooling:** [GitHub MCP available / not configured — CI via `gh run list`]
**Graph:** [the Step-5 readiness line — e.g. `fresh | pre-push hook: installed`, or `STALE — built at <sha8>, HEAD <sha8> | pre-push hook: NOT installed — run scripts/install-graphify-hook.sh`, or `not built (optional pack-dev accelerator)`]
**Resume:** [from `pack-ops/session-state.json` — `no live session — clean start` if absent/idle, else `active: BD-NNN @ <sub-step>; in-flight: <agents to re-spawn>; queue: <order>; mode: <serial|parallel>; pending: <decisions>; cycle: <position>; boundary <sha8> (= HEAD | N behind)`]

**Awaiting instructions.**
---

## Step 5 — Graph freshness + hook-install readiness (LOCAL, never fails startup)

Compute the readiness line reported on the Step-4 `**Graph:**` line. This is a
LOCAL check only — no CI gate, no committed artifact; it NEVER fails the
session (it reports STALE / NOT installed; it does not error out).

```bash
ROOT="$(git rev-parse --show-toplevel)"
GRAPH="$ROOT/graphify-out/graph.json"
HOOK="$(git rev-parse --git-path hooks)/pre-push"
if [ ! -f "$GRAPH" ]; then
  echo "graph: not built (graphify is an optional pack-dev accelerator)"
else
  # built_at_commit is the LAST JSON field — a bounded tail recovers it O(1).
  built="$(tail -c 200 "$GRAPH" | grep -o '"built_at_commit": *"[0-9a-f]*"' | grep -o '[0-9a-f]\{7,\}')"
  head="$(git -C "$ROOT" rev-parse HEAD)"
  if [ -n "$built" ] && [ "$built" = "$head" ]; then
    fresh="graph: fresh"
  else
    fresh="graph: STALE — built at ${built:-unknown}, HEAD ${head} (run: git push, or bash scripts/install-graphify-hook.sh then push)"
  fi
  if [ -f "$HOOK" ]; then
    echo "$fresh | pre-push hook: installed"
  else
    echo "$fresh | pre-push hook: NOT installed — run scripts/install-graphify-hook.sh"
  fi
fi
```

Report the resulting one line on the Step-4 `**Graph:**` line. (You MAY use
`python3 -c "import json; print(json.load(open('$GRAPH'))['built_at_commit'])"`
instead of the `tail`+`grep` if it is more robust on your platform — note the
OUTER double quotes so the shell expands `$GRAPH` and the INNER single quotes
stay literal Python; both are O(1)-cheap for a once-per-startup read.) Honors
the "no CI gate, no committed sentinel" constraint: the freshness criterion
(`built_at_commit` vs HEAD) lives on this LOCAL human-facing surface, not in CI.
