#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[test] running swift test"
  swift test || status=$?
fi

if command -v xcodebuild >/dev/null 2>&1; then
  PROJECT=$(find . -maxdepth 2 -name "*.xcodeproj" | head -n 1 || true)
  WORKSPACE=$(find . -maxdepth 2 -name "*.xcworkspace" | head -n 1 || true)
  if [[ -n "$WORKSPACE" || -n "$PROJECT" ]]; then
    echo "[test] Xcode project detected. Add scheme-specific xcodebuild test commands once the repo has stable scheme names."
  fi
fi


exit "$status"
