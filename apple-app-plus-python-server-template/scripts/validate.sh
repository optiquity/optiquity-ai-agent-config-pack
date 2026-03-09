#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

# Swift / Xcode validation
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

# Python server validation
if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[validate] running uv run ruff check ."
    uv run ruff check . || status=$?
    echo "[validate] running uv run pyright"
    uv run pyright || status=$?
    echo "[validate] running uv run pytest"
    uv run pytest || status=$?
  fi
fi

# Proto schema validation
if [[ -d "proto" ]] && command -v buf >/dev/null 2>&1; then
  echo "[validate] running buf lint"
  buf lint proto/ || status=$?
elif [[ -d "proto" ]]; then
  echo "[validate] WARNING: proto/ found but buf is not installed. Skipping buf lint."
fi

exit "$status"
