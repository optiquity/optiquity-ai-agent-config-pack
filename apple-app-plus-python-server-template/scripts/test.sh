#!/usr/bin/env bash
# test.sh — Run tests for Swift client and Python server.
#
# ── Xcode setup (do this on first project creation) ───────────────────────
XCODE_SCHEME=""           # ← fill in after first Xcode target is created
XCODE_DESTINATION=""      # ← e.g. "platform=iOS Simulator,name=iPhone 16,OS=latest"
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[test] swift test"
  swift test || status=$?
fi

if command -v xcodebuild >/dev/null 2>&1 && [[ -n "$XCODE_SCHEME" && -n "$XCODE_DESTINATION" ]]; then
  xcodebuild test -scheme "$XCODE_SCHEME" -destination "$XCODE_DESTINATION" -quiet || status=$?
fi

if command -v pytest >/dev/null 2>&1 && [[ -d "server" ]]; then
  echo "[test] pytest (server/)"
  pytest server/ || status=$?
elif command -v uv >/dev/null 2>&1 && [[ -d "server" ]]; then
  echo "[test] uv run pytest (server/)"
  uv run pytest server/ || status=$?
fi

exit "$status"
