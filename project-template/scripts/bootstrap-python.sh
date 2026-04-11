#!/usr/bin/env bash
# bootstrap-python.sh — Sync Python dependencies via uv and verify buf availability
# for proto workflows. Called by scripts/bootstrap.sh when pyproject.toml is
# detected. Safe to run directly for Python-only work.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[bootstrap-python] repo root: $ROOT_DIR"

if ! command -v uv >/dev/null 2>&1; then
  echo "[bootstrap-python] ERROR: uv is not installed."
  echo "[bootstrap-python] Install uv: https://docs.astral.sh/uv/"
  exit 1
fi

echo "[bootstrap-python] uv version: $(uv --version)"

uv sync --all-extras

if command -v buf >/dev/null 2>&1; then
  echo "[bootstrap-python] buf found: $(buf --version)"
else
  echo "[bootstrap-python] WARNING: buf is not installed."
  echo "[bootstrap-python] Install buf for proto schema validation: https://buf.build/docs/installation"
  echo "[bootstrap-python] buf is required for: buf lint, buf breaking, and proto code generation."
fi

echo "[bootstrap-python] Python environment ready"
