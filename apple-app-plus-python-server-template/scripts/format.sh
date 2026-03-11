#!/usr/bin/env bash
# format.sh — Format Swift (swift-format) and Python (ruff) source files.
# Install: brew install swift-format && uv add --dev ruff
# If a formatter is not installed, the script warns and continues.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

status=0

# Swift
if command -v swift-format >/dev/null 2>&1; then
  echo "[format] Running swift-format..."
  for dir in Sources Tests client/Sources client/Tests ios/Sources ios/Tests; do
    if [[ -d "$dir" ]]; then
      swift-format format --recursive --in-place "$dir" || status=$?
      echo "[format] Formatted: $dir/"
    fi
  done
else
  echo "[format] WARN: swift-format not found — skipping Swift formatting."
  echo "[format] Install: brew install swift-format"
fi

# Python
if command -v ruff >/dev/null 2>&1; then
  echo "[format] Running ruff format (server/)..."
  if [[ -d "server" ]]; then
    ruff format server/ || status=$?
    ruff check --fix server/ || status=$?
  fi
else
  echo "[format] WARN: ruff not found — skipping Python formatting."
  echo "[format] Install: uv add --dev ruff"
fi

exit "$status"
