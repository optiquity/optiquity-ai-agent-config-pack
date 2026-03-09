#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


status=0

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[format] Swift package detected. No formatter is configured yet."
fi


if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[format] running uv run ruff format ."
    uv run ruff format . || status=$?
  elif command -v ruff >/dev/null 2>&1; then
    echo "[format] running ruff format ."
    ruff format . || status=$?
  else
    echo "[format] ruff is not installed"
    status=1
  fi
fi

exit "$status"
