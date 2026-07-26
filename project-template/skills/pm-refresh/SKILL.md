---
name: pm-refresh
description: Reload the project's live rules and PM-session state to the front of context without syncing or clearing history. Run mid-session after a long stretch or a context compaction to re-warm the operating rules — NOT a fresh startup (no git pull, no history reset).
allowed-tools: Read, Bash, Grep
---

Re-read the project's live operating context to the FRONT of context. Do NOT run
`git pull`, do NOT clear session history, and do NOT re-run the full startup
report. This is a lightweight in-session re-warm, distinct from `/pm-startup`
(which syncs, starts fresh, and prints the full readiness report). This skill is
report-only: it writes no file, no config, and no settings.

## Step 1 — Re-read the rule SSOT

Re-read, in this order, so the current rules sit at the front of context:

- The trinity `## Project rules` section of `CLAUDE.md` (plus `AGENTS.md` /
  `GEMINI.md` when a rule you rely on is trinity-mirrored).
- `docs/pack/PM-CHAT.md` — the PM chat's behavioral rules.
- `docs/pack/METHODOLOGY.md` — the methodology SSOT.
- `docs/project/backlog/_rules.md`, `docs/project/implementation-plan/_rules.md`,
  and `docs/project/changelog/_rules.md` — the per-entry write contracts.

## Step 2 — Re-read live session state + config

- `docs/project/pm-session-state.json` — the committed live-session snapshot
  (active work, in-flight agents, queue order, cycle position, boundary commit).
- The active operating modes from the per-clone PM session config, read per
  `docs/pack/PM-OPERATING-MODES.md` § "Reading the config" (current-worktree path;
  missing / malformed / unreachable fold to the family defaults). This re-warm is
  a convenience, not the authority — the on-disk config stays the authority,
  re-read at each point of use.

## Step 2b — Re-verify + offer-to-heal the modes hooks (Claude-only; report-only)

Re-warm the active mode behaviors and confirm both Claude-only enforcement hooks
still fire. This step NEVER fails, blocks, or writes settings; on a fault it
REPORTS and OFFERS to heal (a settings/body fix is a user action — never a git
verb, never a silent settings mutation).

1. Re-echo the three active modes' behavior text from
   `docs/pack/PM-OPERATING-MODES.md` (the values read in Step 2), putting the live
   mode semantics back at the front of context. Note the per-CLI enforcement
   split: `review_mode` is cross-CLI salience only (no hook); `intervention_mode`
   is cross-CLI salience with a Claude-only commit-approval hook; `isolation_mode`
   is Claude-only enforcement. On Codex and Antigravity the modes are honored by
   salience — the PM chat applies the recorded value — but no hook backstops them.
2. Re-run the function canary for BOTH hooks and confirm the committed wiring —
   the commit-gate canary drives the body through its `MODES_GATE_*` scratch
   seams, touching NO live config or token:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ "${CLAUDECODE:-}" = "1" ]; then
  ISO="$ROOT/scripts/pm-modes-enforce.py"
  GATE="$ROOT/scripts/pm-modes-commit-gate.py"
  SETTINGS="$ROOT/.claude/settings.json"
  if [ ! -f "$ISO" ] || [ ! -f "$GATE" ]; then
    echo "modes re-heal: hook body absent (feature not built in this clone)"
  else
    if [ -f "$SETTINGS" ] && grep -q 'pm-modes-enforce.py' "$SETTINGS" && grep -q 'pm-modes-commit-gate.py' "$SETTINGS"; then
      wired="wired"
    else
      wired="wiring MISSING — restore .claude/settings.json"
    fi
    ic='{"tool_name":"Agent","cwd":"'"$ROOT"'","tool_input":{"subagent_type":"coder","name":"pm-refresh-iso-canary"}}'
    ip="$(printf '%s' "$ic" | python3 "$ISO" 2>/dev/null)"
    case "$ip" in *'"permissionDecision":"deny"'*) iso="isolation self-test PASS" ;; *) iso="isolation self-test FAIL — inspect scripts/" ;; esac
    cfg="$(mktemp)"; printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"full"}' > "$cfg"
    gc='{"tool_name":"Bash","cwd":"'"$ROOT"'","tool_input":{"command":"git commit -m canary"}}'
    gp="$(printf '%s' "$gc" | MODES_GATE_CONFIG_FILE="$cfg" MODES_GATE_TOKEN_FILE="$cfg.no-token" python3 "$GATE" 2>/dev/null)"
    rm -f "$cfg"
    case "$gp" in *'"permissionDecision":"deny"'*) gate="commit-gate self-test PASS" ;; *) gate="commit-gate self-test FAIL — inspect scripts/" ;; esac
    echo "modes re-heal: $wired ($iso, $gate) — Claude-only"
  fi
else
  echo "modes re-heal: n/a (non-Claude CLI — isolation_mode and the commit-gate hook are Claude-only)"
fi
```

3. On a fault, REPORT + OFFER (never auto-mutate): a canary FAIL means a broken
   tracked hook body — the true fix is a git-level restore, a user action; report
   it, do not run a git verb. Wiring MISSING means the tracked `.claude/settings.json`
   was edited away — report it and point to restoring that file (a user action).
   Green = note it on the Step-3 confirm line.

## Step 3 — Confirm

Report ONE line, e.g. `Reloaded: rules + session-state + modes (review=<r>,
intervention=<i>, isolation=<s>); modes hooks: <the Step-2b re-heal result>.` Do
not restart the session and do not re-sync.
