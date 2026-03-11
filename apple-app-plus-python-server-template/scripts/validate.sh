#!/usr/bin/env bash
# validate.sh — Build and test both Swift client and Python server.
#
# ── Xcode setup (do this on first project creation) ───────────────────────
XCODE_SCHEME=""           # ← fill in after first Xcode target is created
XCODE_DESTINATION=""      # ← e.g. "platform=iOS Simulator,name=iPhone 16,OS=latest"
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

# Swift / SPM
if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[validate] swift build"
  swift build || status=$?
  echo "[validate] swift test"
  swift test || status=$?
fi

# Xcode
if command -v xcodebuild >/dev/null 2>&1; then
  if [[ -n "$XCODE_SCHEME" && -n "$XCODE_DESTINATION" ]]; then
    echo "[validate] xcodebuild test: $XCODE_SCHEME"
    xcodebuild test \
      -scheme "$XCODE_SCHEME" \
      -destination "$XCODE_DESTINATION" \
      -quiet || status=$?
  else
    if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
      echo "[validate] WARN: Xcode project detected but XCODE_SCHEME / XCODE_DESTINATION not set."
      echo "[validate] Edit scripts/validate.sh to enable xcodebuild validation."
    fi
  fi
fi

# Python server
if command -v pytest >/dev/null 2>&1 && [[ -d "server" ]]; then
  echo "[validate] pytest (server/)"
  pytest server/ || status=$?
elif command -v uv >/dev/null 2>&1 && [[ -d "server" ]]; then
  echo "[validate] uv run pytest (server/)"
  uv run pytest server/ || status=$?
fi

exit "$status"
