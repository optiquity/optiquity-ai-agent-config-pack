#!/usr/bin/env bash
# test.sh — Run the test suite.
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

if command -v xcodebuild >/dev/null 2>&1; then
  if [[ -n "$XCODE_SCHEME" && -n "$XCODE_DESTINATION" ]]; then
    echo "[test] xcodebuild test: $XCODE_SCHEME"
    xcodebuild test       -scheme "$XCODE_SCHEME"       -destination "$XCODE_DESTINATION"       -quiet || status=$?
  else
    if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
      echo "[test] ⚠️  XCODE_SCHEME is not set — xcodebuild steps skipped."
      echo "[test]    Edit scripts/test.sh and set XCODE_SCHEME and XCODE_DESTINATION to enable xcodebuild testing."
    fi
  fi
fi

exit "$status"
