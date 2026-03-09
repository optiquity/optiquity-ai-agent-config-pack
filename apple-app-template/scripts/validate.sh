#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[validate] running swift build"
  swift build || status=$?
  echo "[validate] running swift test"
  swift test || status=$?
fi

if command -v xcodebuild >/dev/null 2>&1; then
  if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
    echo "[validate] Xcode project detected. No scheme-specific xcodebuild validate step is configured yet."
    echo "[validate] After project creation, add a repo-specific script with stable scheme and destination names."
  fi
fi


exit "$status"
