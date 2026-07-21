#!/usr/bin/env bash
# pack-internal: true  (pack-ops isolation_mode enforcement hook installer; not a user-facing verb, in no install map)
#
# scripts/install-modes-hook.sh — idempotent JSON deep-merge installer for the
# isolation_mode PreToolUse[Agent] deny-hook (scripts/hooks/modes-enforce.py).
#
# Wires the tracked hook body into this clone's gitignored, user-owned
# .claude/settings.local.json by DEEP-MERGING a single PreToolUse[Agent] entry,
# preserving every existing key (permissions, other hooks/events). Re-runnable
# (a byte-equal entry is a no-op). --uninstall removes ONLY this hook; --status
# reports whether it is wired.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): a PACK-OPS
# tool — it NEVER ships to clients and is NOT in any install map. It is NOT a
# three-way key-merge like scripts/merge-json.py (that is a BASE/OURS/THEIRS
# migrator merge — the wrong shape for a single-entry add/replace/remove against
# a user-owned local file).
#
# State note: this MUTATES the live .claude/settings.local.json, so the
# ORCHESTRATOR runs it with user approval — never a coder or any sub-agent
# (per "agents-never-commit" / "per-action-approval").
#
# Test seam: MODES_HOOK_SETTINGS_FILE overrides the target settings path so the
# unit test drives merge / idempotency / uninstall against a scratch file
# without touching the real .claude/. Production leaves it unset.
set -euo pipefail

MODE="install"
case "${1:-}" in
  "")           MODE="install" ;;
  --uninstall)  MODE="uninstall" ;;
  --status)     MODE="status" ;;
  -h|--help)    echo "usage: install-modes-hook.sh [--uninstall|--status]"; exit 0 ;;
  *)            echo "install-modes-hook.sh: unknown argument: $1" >&2
                echo "usage: install-modes-hook.sh [--uninstall|--status]" >&2
                exit 2 ;;
esac

# Resolve the target settings file (test seam: MODES_HOOK_SETTINGS_FILE).
if [ -n "${MODES_HOOK_SETTINGS_FILE:-}" ]; then
  SETTINGS="$MODES_HOOK_SETTINGS_FILE"
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$ROOT" ]; then
    echo "install-modes-hook.sh: not inside a git work tree" >&2
    exit 1
  fi
  SETTINGS="$ROOT/.claude/settings.local.json"
fi

# The command uses the literal $CLAUDE_PROJECT_DIR so the wired path resolves
# regardless of session cwd; the body is executable (python3 shebang), so the
# direct path runs. --status/--uninstall key on the modes-enforce.py substring,
# so detection is form-agnostic if a live CLI needs the `python3 <path>` form.
COMMAND='$CLAUDE_PROJECT_DIR/scripts/hooks/modes-enforce.py'

if [ "$MODE" = "install" ]; then
  mkdir -p "$(dirname "$SETTINGS")"
fi

MHOOK_MODE="$MODE" MHOOK_SETTINGS="$SETTINGS" MHOOK_COMMAND="$COMMAND" python3 - <<'PY'
import json
import os
import sys

mode = os.environ["MHOOK_MODE"]
settings_path = os.environ["MHOOK_SETTINGS"]
command = os.environ["MHOOK_COMMAND"]

MARKER = "scripts/hooks/modes-enforce.py"


def _malformed():
    """Malformed/absent-shape handling: --status folds to not-installed
    (exit 0, never errors); install/uninstall refuse to write and exit
    non-zero (never discard the user's content)."""
    if mode == "status":
        print("not-installed")
        sys.exit(0)
    sys.stderr.write(
        "install-modes-hook.sh: %s is not valid JSON; refusing to write\n"
        % settings_path
    )
    sys.exit(1)


def is_ours(entry):
    if not isinstance(entry, dict) or entry.get("matcher") != "Agent":
        return False
    for h in entry.get("hooks", []) or []:
        if isinstance(h, dict) and str(h.get("command", "")).endswith(MARKER):
            return True
    return False


def desired_entry():
    return {
        "matcher": "Agent",
        "hooks": [{"type": "command", "command": command}],
    }


# ── Read (absent -> {}; malformed -> per-mode handling). ──
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
            _malformed()
if not isinstance(data, dict):
    _malformed()

# Locate our PreToolUse[Agent] entry, if any.
hooks = data.get("hooks")
pretool = hooks["PreToolUse"] if (
    isinstance(hooks, dict) and isinstance(hooks.get("PreToolUse"), list)
) else []
ours_idx = next((i for i, e in enumerate(pretool) if is_ours(e)), -1)

if mode == "status":
    print("installed" if ours_idx >= 0 else "not-installed")
    sys.exit(0)

if mode == "uninstall":
    if ours_idx < 0:
        print("not-installed")
        sys.exit(0)
    del pretool[ours_idx]
    if not pretool:
        hooks.pop("PreToolUse", None)
    if isinstance(hooks, dict) and not hooks:
        data.pop("hooks", None)
    with open(settings_path, "w") as fh:
        fh.write(json.dumps(data, indent=2) + "\n")
    print("uninstalled")
    sys.exit(0)

# mode == install
if ours_idx >= 0:
    entry = pretool[ours_idx]
    current = any(
        isinstance(h, dict) and h.get("command") == command
        for h in entry.get("hooks", []) or []
    )
    if current:
        print("already current")
        sys.exit(0)
    pretool[ours_idx] = desired_entry()  # stale -> replace in place
else:
    if not isinstance(data.get("hooks"), dict):
        data["hooks"] = {}
    if not isinstance(data["hooks"].get("PreToolUse"), list):
        data["hooks"]["PreToolUse"] = []
    data["hooks"]["PreToolUse"].append(desired_entry())

with open(settings_path, "w") as fh:
    fh.write(json.dumps(data, indent=2) + "\n")
print("installed")
sys.exit(0)
PY
