#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


echo "[bootstrap] repo root: $ROOT_DIR"

if ! command -v uv >/dev/null 2>&1; then
  echo "[bootstrap] uv is not installed. Install uv first: https://docs.astral.sh/uv/"
  exit 1
fi

uv sync --all-extras

if command -v buf >/dev/null 2>&1; then
  echo "[bootstrap] buf found: $(buf --version)"
else
  echo "[bootstrap] WARNING: buf is not installed. Install buf for proto schema validation: https://buf.build/docs/installation"
  echo "[bootstrap] buf is required for: buf lint, buf breaking, and proto code generation."
fi

echo "[bootstrap] environment ready"
