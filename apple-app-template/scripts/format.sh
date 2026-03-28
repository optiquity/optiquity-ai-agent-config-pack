#!/usr/bin/env bash
# format.sh — Format Swift source files using swift-format.
# Install: brew install swift-format
# If swift-format is not installed, this script warns and exits 0.
# Run manually before committing, or invoke via: claude --agent repo-ops "run format.sh"
# Not wired into the PostToolUse hook — format once pre-commit rather than after every individual edit.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

status=0

if command -v swift-format >/dev/null 2>&1; then
  echo "[format] Running swift-format..."

  # Format standard SPM source directories. Adjust if your layout differs.
  for dir in Sources Tests; do
    if [[ -d "$dir" ]]; then
      swift-format format --recursive --in-place "$dir" || status=$?
      echo "[format] Formatted: $dir/"
    fi
  done

  # Fallback: no Sources/ or Tests/ but Package.swift exists
  if [[ ! -d "Sources" && ! -d "Tests" && -f "Package.swift" ]]; then
    find . -name "*.swift"       ! -path "./.build/*"       ! -path "./DerivedData/*"       ! -path "./generated/*"       -print0 | xargs -0 swift-format format --in-place || status=$?
    echo "[format] Formatted all Swift files (fallback path)"
  fi
else
  echo "[format] WARN: swift-format not found — skipping Swift formatting."
  echo "[format] Install: brew install swift-format"
  echo "[format] Exiting 0 so the post-edit hook does not block the agent."
fi

exit "$status"
