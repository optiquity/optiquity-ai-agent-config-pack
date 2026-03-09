#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


echo "[bootstrap] repo root: $ROOT_DIR"

if ! command -v uv >/dev/null 2>&1; then
  echo "[bootstrap] uv is not installed. Install uv first."
  exit 1
fi

uv sync --all-extras

echo "[bootstrap] environment ready"
