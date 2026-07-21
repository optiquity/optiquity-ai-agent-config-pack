#!/usr/bin/env python3
# pack-internal: true  (pack-ops isolation_mode PreToolUse[Agent] deny-hook body; never ships to clients, in no install map)
#
# scripts/hooks/modes-enforce.py — Layer-1 isolation_mode enforcement hook.
#
# A Claude Code PreToolUse hook (matcher `Agent`) that re-reads the active
# isolation_mode from pack-ops/session-config.json at the instant of every
# sub-agent spawn, maps subagent_type -> RW/RO agent class, and DENIES a spawn
# whose `isolation` parameter contradicts a must-isolate mode. It enforces
# INTENT (the correct spawn parameter), never OUTCOME (whether isolation
# actually took effect — that stays the agent's runtime pwd/HEAD self-detect).
#
# FAIL-OPEN discipline: any uncertainty (config absent/unreadable/malformed, git
# unavailable, JSON parse error, unknown agent class) -> ALLOW (print nothing,
# exit 0). The body NEVER exits 2 (exit 2 = blocking); an internal error
# degrades to today's honor-system, never to a wedged session.
#
# MUST-ISOLATE-ONLY direction: it denies only an UNDER-isolated spawn (one that
# should isolate but does not); it NEVER denies an over-isolated spawn, so it
# stays compatible with an all-isolated posture.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): a PACK-OPS
# tool — it NEVER ships to clients and is NOT in any install map. The
# orchestrator wires it into the gitignored per-clone .claude/settings.local.json
# with scripts/install-modes-hook.sh (that installer mutates the live settings
# file, so the orchestrator runs it with user approval — never a coder/sub-agent).

import json
import os
import subprocess
import sys

# Agent-class map (subagent_type -> class). RW = read-write (mutates the tree);
# a fix-coder is a pack-coder instance. RO = read-only.
_RW_CLASSES = frozenset({"pack-coder"})
_RO_CLASSES = frozenset({
    "pack-reviewer",
    "pack-architect",
    "pack-planner",
    "pack-docs-researcher",
})

_DEFAULT_MODE = "read-write-only"


def _resolve_mode(cwd):
    """Return the active isolation_mode string, folding ANY failure to the
    family default (read-write-only). Mirrors OPERATING-MODES.md "Reading the
    config": empty root / non-git cwd / absent / malformed / unreadable -> the
    default."""
    try:
        proc = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
        )
    except Exception:
        return _DEFAULT_MODE
    root = proc.stdout.strip()
    if not root:
        return _DEFAULT_MODE
    cfg = os.path.join(root, "pack-ops", "session-config.json")
    try:
        with open(cfg) as fh:
            mode = json.load(fh).get("isolation_mode", _DEFAULT_MODE)
    except Exception:
        return _DEFAULT_MODE
    return mode if isinstance(mode, str) else _DEFAULT_MODE


def _classify(subagent_type):
    """Map a subagent_type to RW / RO / UNKNOWN."""
    if subagent_type in _RW_CLASSES:
        return "RW"
    if subagent_type in _RO_CLASSES:
        return "RO"
    return "UNKNOWN"


def _must_isolate(mode, cls):
    """True iff a spawn of class `cls` is REQUIRED to isolate under `mode`.
    Only the two valid must-isolate directions bite; any other mode value
    requires nothing (fail-open, since only these two modes are valid)."""
    if mode == "full":
        return cls in ("RW", "RO")
    if mode == "read-write-only":
        return cls == "RW"
    return False


def main():
    # Parse the hook payload. An unparseable payload -> allow (fail-open).
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    try:
        # Belt-and-suspenders: the matcher already scopes to Agent.
        if data.get("tool_name") != "Agent":
            return 0

        tool_input = data.get("tool_input") or {}
        cwd = data.get("cwd") or os.getcwd()
        mode = _resolve_mode(cwd)

        cls = _classify(tool_input.get("subagent_type"))
        if cls == "UNKNOWN":
            return 0  # unknown class -> allow (fail-open)

        iso_present = tool_input.get("isolation") == "worktree"
        if _must_isolate(mode, cls) and not iso_present:
            reason = (
                '{cls} spawn under isolation_mode={mode} must set '
                'isolation:"worktree"; re-spawn with the isolation parameter'
            ).format(cls=cls, mode=mode)
            out = {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
            # Compact separators — the spike-proven schema + the /pack-startup
            # canary + the unit test all match the space-free substring
            # `"permissionDecision":"deny"`.
            sys.stdout.write(json.dumps(out, separators=(",", ":")))
        # Every non-deny path prints nothing.
        return 0
    except Exception:
        # Any internal error -> allow (NEVER exit 2 — fail-open).
        return 0


if __name__ == "__main__":
    sys.exit(main())
