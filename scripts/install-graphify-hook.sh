#!/usr/bin/env bash
# pack-internal: true  (pack-ops graph-refresh hook installer; not a user-facing verb)
# scripts/install-graphify-hook.sh — one-time, per-clone installer for the
# Graphify pre-push background graph-refresh hook (BD-237).
#
# Copies scripts/hooks/graphify-pre-push.sh into this clone's shared common git
# hooks dir as `pre-push`, makes it executable, and is idempotent (a byte-equal
# install is a no-op). The hook BODY is tracked in the repo; only the per-clone
# INSTALLED copy under .git/hooks is non-versioned, so this installer wires the
# tracked body into the local hooks dir.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): this is a
# PACK-OPS tool — it NEVER ships to clients and is NOT in any install map. The
# Graphify graph is pack-development-only (gitignored, never shipped).
#
# State note: this is a `cp`+`chmod` (NOT a git verb), but it mutates the live
# .git/hooks dir, so the ORCHESTRATOR runs it with user approval — never a coder
# or any sub-agent (per "agents-never-commit" / "per-action-approval").
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/hooks/graphify-pre-push.sh"
DEST="$(git rev-parse --git-path hooks)/pre-push"

if [ ! -f "$SRC" ]; then
  echo "graphify pre-push hook: source not found at $SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST"; then
  echo "graphify pre-push hook: already current at $DEST"
  exit 0
fi

cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "graphify pre-push hook: installed at $DEST"
