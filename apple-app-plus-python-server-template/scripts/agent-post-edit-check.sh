#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

echo "[agent-post-edit-check] repo root: $ROOT_DIR"

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[agent-post-edit-check] swift package detected - running swift build"
  swift build || status=$?
fi

if command -v xcodebuild >/dev/null 2>&1; then
  if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
    if [[ -n "${XCODE_SCHEME:-}" ]]; then
      echo "[agent-post-edit-check] Xcode project detected - running xcodebuild build"
      xcodebuild build -scheme "$XCODE_SCHEME" -quiet >/dev/null 2>&1 || status=$?
    else
      echo "[agent-post-edit-check] ⚠️  XCODE_SCHEME is not set — xcodebuild build check skipped."
      echo "[agent-post-edit-check]    Set XCODE_SCHEME in scripts/validate.sh for full build verification."
      xcodebuild -list >/dev/null || status=$?
    fi
  fi
fi


exit "$status"
