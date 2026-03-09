#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


if command -v uv >/dev/null 2>&1; then
  uv run ruff format .
else
  ruff format .
fi
