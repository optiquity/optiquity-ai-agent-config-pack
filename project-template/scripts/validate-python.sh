#!/usr/bin/env bash
# validate-python.sh — Lint, type-check, and test the Python side of the project.
# Called by scripts/validate.sh when pyproject.toml is detected.
# Safe to run directly for Python-only work.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

if [[ ! -f "pyproject.toml" ]]; then
  echo "[validate-python] pyproject.toml not found"
  exit 1
fi

if command -v uv >/dev/null 2>&1; then
  echo "[validate-python] running uv sync --all-extras"
  uv sync --all-extras || status=$?
  echo "[validate-python] running uv run ruff check ."
  uv run ruff check . || status=$?
  echo "[validate-python] running uv run pyright"
  uv run pyright || status=$?
  echo "[validate-python] running uv run pytest"
  uv run pytest || status=$?
else
  echo "[validate-python] uv not found — falling back to bare commands"
  for cmd in ruff pyright pytest; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[validate-python] missing required command: $cmd"
      status=1
    fi
  done
  if command -v ruff >/dev/null 2>&1; then ruff check . || status=$?; fi
  if command -v pyright >/dev/null 2>&1; then pyright || status=$?; fi
  if command -v pytest >/dev/null 2>&1; then pytest || status=$?; fi
fi

exit "$status"
