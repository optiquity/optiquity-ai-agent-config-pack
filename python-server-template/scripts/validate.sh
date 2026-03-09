#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

if [[ ! -f "pyproject.toml" ]]; then
  echo "[validate] pyproject.toml not found"
  exit 1
fi

if command -v uv >/dev/null 2>&1; then
  echo "[validate] running uv sync --all-extras"
  uv sync --all-extras || status=$?
  echo "[validate] running uv run ruff check ."
  uv run ruff check . || status=$?
  echo "[validate] running uv run pyright"
  uv run pyright || status=$?
  echo "[validate] running uv run pytest"
  uv run pytest || status=$?
else
  for cmd in ruff pyright pytest; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[validate] missing required command: $cmd"
      status=1
    fi
  done
  if command -v ruff >/dev/null 2>&1; then ruff check . || status=$?; fi
  if command -v pyright >/dev/null 2>&1; then pyright || status=$?; fi
  if command -v pytest >/dev/null 2>&1; then pytest || status=$?; fi
fi

# Proto schema validation
if [[ -d "proto" ]] && command -v buf >/dev/null 2>&1; then
  echo "[validate] running buf lint"
  buf lint proto/ || status=$?
  echo "[validate] buf lint complete"
elif [[ -d "proto" ]]; then
  echo "[validate] WARNING: proto/ directory found but buf is not installed. Skipping buf lint."
  echo "[validate] Install buf: https://buf.build/docs/installation"
fi

exit "$status"
