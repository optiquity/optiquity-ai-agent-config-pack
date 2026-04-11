#!/usr/bin/env bash
# format-python.sh — Format Python source files using ruff.
# Install: uv add --dev ruff (or pip install ruff)
# If ruff is not installed, this script warns and exits 0.
# Called by scripts/format.sh when pyproject.toml is detected. Safe to run directly.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

if command -v ruff >/dev/null 2>&1; then
  echo "[format-python] Running ruff format..."
  ruff format . || status=$?
  echo "[format-python] Running ruff check --fix..."
  ruff check --fix . || status=$?
else
  echo "[format-python] WARN: ruff not found — skipping Python formatting."
  echo "[format-python] Install: uv add --dev ruff"
  echo "[format-python] Exiting 0 so the build is not blocked."
fi

exit "$status"
