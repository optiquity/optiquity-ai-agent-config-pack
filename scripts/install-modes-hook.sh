#!/usr/bin/env bash
# pack-internal: true  (pack-ops modes-enforcement hook installer; not a user-facing verb, in no install map)
#
# scripts/install-modes-hook.sh — heal / opt-out / status helper for the pack
# PreToolUse hooks:
#   - isolation         : PreToolUse[Agent] -> scripts/hooks/modes-enforce.py
#   - commit-gate       : PreToolUse[Bash]  -> scripts/hooks/modes-commit-gate.py
#   - deletion-boundary : PreToolUse[Bash]  -> scripts/hooks/deletion-boundary.py
#
# The PRIMARY wiring is the tracked pack-root .claude/settings.json (applied
# natively at session start — no install step, nothing to rot). This script is
# the SECONDARY heal / local-override / status convenience:
#
#   (default)     deep-merge BOTH hook entries into this clone's gitignored,
#                 user-owned .claude/settings.local.json — a heal stopgap (e.g. a
#                 dev who removed the committed file or wants a local override).
#                 Idempotent (a byte-equal entry set is a no-op). Preserves every
#                 existing key (permissions, other hooks/events).
#   --uninstall   remove BOTH modes entries from settings.local.json ONLY.
#   --dedup       remove from settings.local.json ONLY the modes entries that are
#                 ALSO wired in the committed .claude/settings.json (true
#                 duplicates) — the ONE-TIME migration for a clone that installed
#                 the isolation hook locally BEFORE the committed settings.json
#                 landed (that local Agent entry now double-fires). A local-only
#                 override (a hook the committed file does NOT wire) is preserved.
#   --status      report the MERGED wiring reality per hook across the committed
#                 .claude/settings.json AND the local settings.local.json:
#                   isolation: <committed+local|committed|local|none>
#                   commit-gate: <committed+local|committed|local|none>
#                   deletion-boundary: <committed+local|committed|local|none>
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): a PACK-OPS
# tool — it NEVER ships to clients and is NOT in any install map. It is NOT a
# three-way key-merge like scripts/merge-json.py (that is a BASE/OURS/THEIRS
# migrator merge — the wrong shape for a single-entry add/replace/remove against
# a user-owned local file).
#
# State note: install/--uninstall/--dedup MUTATE the live
# .claude/settings.local.json, so the ORCHESTRATOR runs them with user approval —
# never a coder or any sub-agent (per "agents-never-commit" / "per-action-
# approval"). --status is read-only.
#
# Test seams:
#   MODES_HOOK_SETTINGS_FILE  — override the LOCAL settings path (merge /
#                               idempotency / uninstall / dedup against a scratch
#                               file, never the real .claude/).
#   MODES_HOOK_COMMITTED_FILE  — override the COMMITTED settings path (drive
#                               --status / --dedup against a scratch committed
#                               file). Production leaves both unset.
set -euo pipefail

MODE="install"
case "${1:-}" in
  "")           MODE="install" ;;
  --uninstall)  MODE="uninstall" ;;
  --dedup)      MODE="dedup" ;;
  --status)     MODE="status" ;;
  -h|--help)    echo "usage: install-modes-hook.sh [--uninstall|--dedup|--status]"; exit 0 ;;
  *)            echo "install-modes-hook.sh: unknown argument: $1" >&2
                echo "usage: install-modes-hook.sh [--uninstall|--dedup|--status]" >&2
                exit 2 ;;
esac

# Resolve the LOCAL settings file (seam MODES_HOOK_SETTINGS_FILE) and the
# COMMITTED settings file (seam MODES_HOOK_COMMITTED_FILE).
if [ -n "${MODES_HOOK_SETTINGS_FILE:-}" ]; then
  SETTINGS="$MODES_HOOK_SETTINGS_FILE"
  COMMITTED="${MODES_HOOK_COMMITTED_FILE:-}"
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$ROOT" ]; then
    echo "install-modes-hook.sh: not inside a git work tree" >&2
    exit 1
  fi
  SETTINGS="$ROOT/.claude/settings.local.json"
  COMMITTED="${MODES_HOOK_COMMITTED_FILE:-$ROOT/.claude/settings.json}"
fi

if [ "$MODE" = "install" ]; then
  mkdir -p "$(dirname "$SETTINGS")"
fi

MHOOK_MODE="$MODE" MHOOK_SETTINGS="$SETTINGS" MHOOK_COMMITTED="$COMMITTED" python3 - <<'PY'
import json
import os
import sys

mode = os.environ["MHOOK_MODE"]
settings_path = os.environ["MHOOK_SETTINGS"]
committed_path = os.environ.get("MHOOK_COMMITTED", "")

# The hooks this installer manages: (name, matcher, marker, command). The
# command uses the literal $CLAUDE_PROJECT_DIR so the wired path resolves
# regardless of session cwd; every body is executable (python3 shebang). The
# marker (a path substring) makes detection form-agnostic if a live CLI needs
# the `python3 <path>` form. Each tuple emits ONE PreToolUse array element
# (desired_entry); merge/uninstall/dedup/status are data-driven over this table.
HOOKS = [
    ("isolation",         "Agent", "scripts/hooks/modes-enforce.py",
     "$CLAUDE_PROJECT_DIR/scripts/hooks/modes-enforce.py"),
    ("commit-gate",       "Bash",  "scripts/hooks/modes-commit-gate.py",
     "$CLAUDE_PROJECT_DIR/scripts/hooks/modes-commit-gate.py"),
    ("deletion-boundary", "Bash",  "scripts/hooks/deletion-boundary.py",
     "$CLAUDE_PROJECT_DIR/scripts/hooks/deletion-boundary.py"),
]


def is_ours(entry, matcher, marker):
    if not isinstance(entry, dict) or entry.get("matcher") != matcher:
        return False
    for h in entry.get("hooks", []) or []:
        if isinstance(h, dict) and str(h.get("command", "")).endswith(marker):
            return True
    return False


def find_ours(pretool, matcher, marker):
    return next(
        (i for i, e in enumerate(pretool) if is_ours(e, matcher, marker)), -1
    )


def desired_entry(matcher, command):
    return {"matcher": matcher, "hooks": [{"type": "command", "command": command}]}


def pretool_list(data):
    """The actual PreToolUse list (mutable) if present, else a fresh [] (a no-op
    to mutate — correct for uninstall/dedup when nothing is wired)."""
    hooks = data.get("hooks")
    if isinstance(hooks, dict) and isinstance(hooks.get("PreToolUse"), list):
        return hooks["PreToolUse"]
    return []


def ensure_pretool(data):
    if not isinstance(data.get("hooks"), dict):
        data["hooks"] = {}
    if not isinstance(data["hooks"].get("PreToolUse"), list):
        data["hooks"]["PreToolUse"] = []
    return data["hooks"]["PreToolUse"]


def cleanup_empty(data):
    hooks = data.get("hooks")
    if isinstance(hooks, dict):
        pt = hooks.get("PreToolUse")
        if isinstance(pt, list) and not pt:
            hooks.pop("PreToolUse", None)
        if not hooks:
            data.pop("hooks", None)


def read_local():
    """Parse the LOCAL settings file. Absent -> {}. Malformed -> status folds to
    {} (lenient, never errors); a MUTATING mode refuses to write and exits 1
    (never discard the user's content)."""
    data = {}
    if os.path.exists(settings_path):
        try:
            raw = open(settings_path).read()
        except OSError:
            raw = ""
        if raw.strip():
            try:
                data = json.loads(raw)
            except ValueError:
                if mode == "status":
                    return {}
                sys.stderr.write(
                    "install-modes-hook.sh: %s is not valid JSON; refusing to write\n"
                    % settings_path
                )
                sys.exit(1)
    if not isinstance(data, dict):
        if mode == "status":
            return {}
        sys.stderr.write(
            "install-modes-hook.sh: %s is not valid JSON; refusing to write\n"
            % settings_path
        )
        sys.exit(1)
    return data


def read_committed():
    """Parse the COMMITTED settings file — always LENIENT (read-only for
    --status/--dedup; absent/malformed -> {})."""
    data = {}
    if committed_path and os.path.exists(committed_path):
        try:
            raw = open(committed_path).read()
        except OSError:
            raw = ""
        if raw.strip():
            try:
                data = json.loads(raw)
            except ValueError:
                return {}
    return data if isinstance(data, dict) else {}


def write_local(data):
    with open(settings_path, "w") as fh:
        fh.write(json.dumps(data, indent=2) + "\n")


# ── --status: report the MERGED per-hook reality (committed + local). ──
if mode == "status":
    local_pt = pretool_list(read_local())
    committed_pt = pretool_list(read_committed())
    for name, matcher, marker, _cmd in HOOKS:
        in_local = any(is_ours(e, matcher, marker) for e in local_pt)
        in_committed = any(is_ours(e, matcher, marker) for e in committed_pt)
        if in_committed and in_local:
            state = "committed+local"
        elif in_committed:
            state = "committed"
        elif in_local:
            state = "local"
        else:
            state = "none"
        print("%s: %s" % (name, state))
    sys.exit(0)

data = read_local()

# ── --uninstall: remove BOTH modes entries from the LOCAL file. ──
if mode == "uninstall":
    pt = pretool_list(data)
    removed = False
    for _name, matcher, marker, _cmd in HOOKS:
        idx = find_ours(pt, matcher, marker)
        while idx >= 0:
            del pt[idx]
            removed = True
            idx = find_ours(pt, matcher, marker)
    if not removed:
        print("not-installed")
        sys.exit(0)
    cleanup_empty(data)
    write_local(data)
    print("uninstalled")
    sys.exit(0)

# ── --dedup: remove ONLY the LOCAL entries also wired in the COMMITTED file. ──
if mode == "dedup":
    committed_pt = pretool_list(read_committed())
    pt = pretool_list(data)
    removed = False
    for _name, matcher, marker, _cmd in HOOKS:
        if not any(is_ours(e, matcher, marker) for e in committed_pt):
            continue  # not a duplicate; preserve a local-only override
        idx = find_ours(pt, matcher, marker)
        while idx >= 0:
            del pt[idx]
            removed = True
            idx = find_ours(pt, matcher, marker)
    if not removed:
        print("no-duplicates")
        sys.exit(0)
    cleanup_empty(data)
    write_local(data)
    print("deduplicated")
    sys.exit(0)

# ── install: deep-merge BOTH hook entries (heal stopgap). Idempotent. ──
changed = False
for _name, matcher, marker, command in HOOKS:
    pt = ensure_pretool(data)
    idx = find_ours(pt, matcher, marker)
    if idx >= 0:
        entry = pt[idx]
        current = any(
            isinstance(h, dict) and h.get("command") == command
            for h in entry.get("hooks", []) or []
        )
        if current:
            continue
        pt[idx] = desired_entry(matcher, command)  # stale -> replace in place
        changed = True
    else:
        pt.append(desired_entry(matcher, command))
        changed = True

if not changed:
    print("already current")
    sys.exit(0)

write_local(data)
print("installed")
sys.exit(0)
PY
