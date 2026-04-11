#!/usr/bin/env bash
# test-python.sh — Run the Python test suite via pytest.
# Called by scripts/test.sh when pyproject.toml is detected.
# Safe to run directly for Python-only work.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "pyproject.toml" ]]; then
  echo "[test-python] pyproject.toml not found"
  exit 1
fi

if command -v uv >/dev/null 2>&1; then
  echo "[test-python] uv run pytest"
  uv run pytest
else
  echo "[test-python] uv not found — falling back to bare pytest"
  pytest
fi
