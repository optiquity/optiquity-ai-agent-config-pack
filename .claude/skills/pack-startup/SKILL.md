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
**Modes enforce:** [the Step-6 readiness line — e.g. `wired (isolation self-test PASS, commit-gate self-test PASS, deletion-boundary self-test PASS) — Claude-only`, or `wired (isolation self-test PASS, commit-gate self-test PASS, deletion-boundary self-test FAIL — inspect) — Claude-only`, or `wiring MISSING — restore .claude/settings.json`, or `n/a (non-Claude CLI)`]
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

## Step 6 — Modes-enforce hook readiness (Claude-only; LOCAL, never fails startup)

Compute the line reported on the Step-4 `**Modes enforce:**` line. LOCAL only —
no CI gate, no committed sentinel; it NEVER fails the session (reports absent /
wiring MISSING / self-test FAIL; it does not error). Both hooks are auto-wired by
the tracked pack-root `.claude/settings.json`, so this step VERIFIES rather than
installs: a WIRING probe (grep the tracked `.claude/settings.json` for all three
hook bodies — deterministic, O(1)) plus a FUNCTION canary per body (a dry-run payload
piped into the hook — the did-it-actually-fire signal). Branched at runtime on
`CLAUDECODE` (the text is byte-identical across the three mirrors; only the
runtime output differs by CLI). The commit-gate canary drives the body through
its `MODES_GATE_*` scratch seams and the deletion-boundary canary through its
`DELBOUND_*` seams (a synthetic registry + synthetic temp root), so both touch NO
live config, token, or filesystem.

```bash
ROOT="$(git rev-parse --show-toplevel)"
if [ "${CLAUDECODE:-}" = "1" ]; then
  ISO="$ROOT/scripts/hooks/modes-enforce.py"
  GATE="$ROOT/scripts/hooks/modes-commit-gate.py"
  DEL="$ROOT/scripts/hooks/deletion-boundary.py"
  SETTINGS="$ROOT/.claude/settings.json"
  if [ ! -f "$ISO" ] || [ ! -f "$GATE" ] || [ ! -f "$DEL" ]; then
    echo "modes enforce: hook body absent (feature not built in this clone)"
  else
    if [ -f "$SETTINGS" ] && grep -q 'modes-enforce.py' "$SETTINGS" && grep -q 'modes-commit-gate.py' "$SETTINGS" && grep -q 'deletion-boundary.py' "$SETTINGS"; then
      wired="wired"
    else
      wired="wiring MISSING — restore .claude/settings.json"
    fi
    ic='{"tool_name":"Agent","cwd":"'"$ROOT"'","tool_input":{"subagent_type":"pack-coder","name":"pack-startup-iso-canary"}}'
    ip="$(printf '%s' "$ic" | python3 "$ISO" 2>/dev/null)"
    case "$ip" in *'"permissionDecision":"deny"'*) iso="isolation self-test PASS" ;; *) iso="isolation self-test FAIL — inspect" ;; esac
    cfg="$(mktemp)"; printf '%s\n' '{"schema":"pack-session-config/1","intervention_mode":"full"}' > "$cfg"
    gc='{"tool_name":"Bash","cwd":"'"$ROOT"'","tool_input":{"command":"git commit -m canary"}}'
    gp="$(printf '%s' "$gc" | MODES_GATE_CONFIG_FILE="$cfg" MODES_GATE_TOKEN_FILE="$cfg.no-token" python3 "$GATE" 2>/dev/null)"
    rm -f "$cfg"
    case "$gp" in *'"permissionDecision":"deny"'*) gate="commit-gate self-test PASS" ;; *) gate="commit-gate self-test FAIL — inspect" ;; esac
    dreg="$(mktemp)"; downed="/delbound-canary-owned"
    printf '%s\n' '{"agent_id":"delbound-canary","owned_dir":"'"$downed"'"}' > "$dreg"
    dc='{"tool_name":"Bash","agent_id":"delbound-canary","cwd":"'"$downed"'","tool_input":{"command":"rm -rf /delbound-canary-root/bd257-*"}}'
    dp="$(printf '%s' "$dc" | DELBOUND_REGISTRY_FILE="$dreg" DELBOUND_TEMP_ROOTS="/delbound-canary-tmp" python3 "$DEL" 2>/dev/null)"
    ac='{"tool_name":"Bash","agent_id":"delbound-canary","cwd":"'"$downed"'","tool_input":{"command":"rm -rf '"$downed"'/scratch && rm -rf /delbound-canary-tmp/x && rm -rf \"$WORK\""}}'
    ap="$(printf '%s' "$ac" | DELBOUND_REGISTRY_FILE="$dreg" DELBOUND_TEMP_ROOTS="/delbound-canary-tmp" python3 "$DEL" 2>/dev/null)"
    rm -f "$dreg"
    del="deletion-boundary self-test FAIL — inspect"
    case "$dp" in *'"permissionDecision":"deny"'*) case "$ap" in *'"permissionDecision":"deny"'*) : ;; *) del="deletion-boundary self-test PASS" ;; esac ;; esac
    if [ "$wired" = "wired" ]; then
      echo "modes enforce: wired ($iso, $gate, $del) — Claude-only"
    else
      echo "modes enforce: $wired ($iso, $gate, $del) — Claude-only"
    fi
  fi
else
  echo "modes enforce: n/a (non-Claude CLI — isolation_mode + hooks are Claude-only; modes honored by orchestrator discipline)"
fi
```

Report the resulting one line on the Step-4 `**Modes enforce:**` line. If wiring
is MISSING, restore the tracked `.claude/settings.json`; a local heal stopgap is
`bash scripts/install-modes-hook.sh` (and `--dedup` drops a now-duplicate local
entry once the committed file is present).
