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
    echo "[agent-post-edit-check] Xcode project or workspace detected - listing schemes"
    xcodebuild -list >/dev/null || status=$?
  fi
fi


if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[agent-post-edit-check] python project detected - running uv run ruff check ."
    uv run ruff check . || status=$?
  elif command -v ruff >/dev/null 2>&1; then
    echo "[agent-post-edit-check] python project detected - running ruff check ."
    ruff check . || status=$?
  fi
fi

exit "$status"
