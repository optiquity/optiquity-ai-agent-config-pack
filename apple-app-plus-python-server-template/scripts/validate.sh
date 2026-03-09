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


if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[validate] running uv sync --all-extras"
    uv sync --all-extras || status=$?
    echo "[validate] running uv run ruff check ."
    uv run ruff check . || status=$?
    echo "[validate] running uv run pyright"
    uv run pyright || status=$?
    echo "[validate] running uv run pytest"
    uv run pytest || status=$?
  else
    for cmd in ruff pyright pytest; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[validate] missing required command: $cmd"
        status=1
      fi
    done
    if command -v ruff >/dev/null 2>&1; then ruff check . || status=$?; fi
    if command -v pyright >/dev/null 2>&1; then pyright || status=$?; fi
    if command -v pytest >/dev/null 2>&1; then pytest || status=$?; fi
  fi
fi

exit "$status"
