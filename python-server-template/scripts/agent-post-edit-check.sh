#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

echo "[agent-post-edit-check] repo root: $ROOT_DIR"

if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[agent-post-edit-check] running uv run ruff check ."
    uv run ruff check . || status=$?
  elif command -v ruff >/dev/null 2>&1; then
    echo "[agent-post-edit-check] running ruff check ."
    ruff check . || status=$?
  else
    echo "[agent-post-edit-check] ruff is not installed"
    status=1
  fi
fi

exit "$status"
