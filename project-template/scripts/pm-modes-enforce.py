#!/usr/bin/env python3
#
# scripts/pm-modes-enforce.py — client isolation_mode enforcement hook.
#
# A Claude Code PreToolUse hook (matcher `Agent`) that re-reads the active
# isolation_mode from docs/project/pm-session-config.json at the instant of
# every sub-agent spawn, maps subagent_type -> read-write / read-only agent
# class, and DENIES an UNDER-isolated spawn — one a must-isolate mode requires
# to isolate but whose `isolation:"worktree"` parameter is absent. It enforces
# INTENT (the correct spawn parameter), never OUTCOME (whether isolation actually
# took effect — that stays the agent's runtime pwd/HEAD self-detect).
#
# FAIL-OPEN discipline: the genuine allow (print nothing, exit 0) cases are a
# non-Agent tool, an unparseable payload, an unknown agent class, and any
# internal error. A config that is absent/unreadable/malformed (or git
# unavailable) is NOT a blanket allow: _resolve_mode folds it to the DEFAULT mode
# (read-write-only) and the spawn is then enforced per that mode, so an
# under-isolated RW spawn DENIES under the must-isolate default. The body NEVER
# exits 2 (exit 2 = blocking); an internal error degrades to the honor-system
# default, never to a wedged session.
#
# MUST-ISOLATE-ONLY direction: it denies only an UNDER-isolated spawn (one that
# should isolate but does not); it NEVER denies an over-isolated spawn, so it
# stays compatible with an all-isolated posture.
#
# Scope bound: this hook governs ONLY the in-session Agent-tool spawn path. The
# shipped agent-run.sh launcher isolates per its own flags and is NOT reached by
# this config or hook (see docs/pack/PM-OPERATING-MODES.md).
#
# Dependency direction: a client-side hook — it is read only by the client
# .claude/settings.json (which wires it by name, `pm-modes-enforce.py`) and
# depends on no other file. It is a self-contained client copy; it shares no
# code with any pack-repo hook. The wiring is named here by basename only:
# settings.json is the sole source of truth for the invocation form, so this
# comment cannot go stale when that form changes.

import json
import os
import subprocess
import sys

# Agent-class map (subagent_type -> class). Client agent names are un-prefixed.
# RW = read-write (mutates the tree): coder (covers coder + fix-coder) and
# repo-ops (scripted writes). RO = read-only: the 14 report-only agents (the
# BASE `auditor` is distinct from the seven `auditor-*` cluster members — a glob
# would misclassify).
_RW_CLASSES = frozenset({"coder", "repo-ops"})
_RO_CLASSES = frozenset({
    "architect",
    "planner",
    "reviewer",
    "tester",
    "docs-researcher",
    "grpc-schema",
    "auditor",
    "auditor-architecture",
    "auditor-code",
    "auditor-docs",
    "auditor-ops",
    "auditor-security",
    "auditor-tests",
    "auditor-ui",
})

_DEFAULT_MODE = "read-write-only"


def _resolve_mode(cwd):
    """Return the active isolation_mode string, folding ANY failure to the
    family default (read-write-only). Mirrors PM-OPERATING-MODES.md "Reading the
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
    cfg = os.path.join(root, "docs", "project", "pm-session-config.json")
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
            # Compact separators so the space-free substring
            # `"permissionDecision":"deny"` is literally present for any
            # canary/grep that matches it.
            sys.stdout.write(json.dumps(out, separators=(",", ":")))
        # Every non-deny path prints nothing.
        return 0
    except Exception:
        # Any internal error -> allow (NEVER exit 2 — fail-open).
        return 0


if __name__ == "__main__":
    sys.exit(main())
