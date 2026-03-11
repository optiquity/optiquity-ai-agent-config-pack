#!/usr/bin/env bash
# format.sh — Format Python source files using ruff.
# Install: uv add --dev ruff  (or pip install ruff)
# If ruff is not installed, this script warns and exits 0.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

status=0

if command -v ruff >/dev/null 2>&1; then
  echo "[format] Running ruff format..."
  ruff format . || status=$?
  echo "[format] Running ruff check --fix..."
  ruff check --fix . || status=$?
else
  echo "[format] WARN: ruff not found — skipping Python formatting."
  echo "[format] Install: uv add --dev ruff"
fi

exit "$status"
