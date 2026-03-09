#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"


echo "[bootstrap] repo root: $ROOT_DIR"

if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[bootstrap] resolving Swift package dependencies"
  swift package resolve
fi

if command -v xcodebuild >/dev/null 2>&1; then
  if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
    echo "[bootstrap] Xcode project detected. Open the project in Xcode to finish signing and simulator setup if needed."
  fi
fi


if [[ -f "pyproject.toml" ]]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[bootstrap] syncing Python environment with uv"
    uv sync --all-extras
  else
    echo "[bootstrap] uv is not installed. Install uv or create a virtual environment manually."
  fi
fi
