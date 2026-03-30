#!/usr/bin/env bash
# format.sh — Format Swift source files using swift-format.
# Install: brew install swift-format
# If swift-format is not installed, this script warns and exits 0.
# Run manually before committing, or invoke via: claude --agent repo-ops "run format.sh"
# Not wired into the PostToolUse hook — format once pre-commit rather than after every individual edit.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

# ── Swift source directories ────────────────────────────────────────────────
# Set this to a space-separated list of directories to format.
# Leave empty to use the automatic fallback (see below).
#
# Two common layouts:
#   SPM layout:            Sources Tests
#   Xcode-generated layout: MyApp MyAppTests
#
# If SWIFT_SOURCE_DIRS is empty, the script tries Sources/ and Tests/ first.
# If neither exists, it falls back to finding all .swift files in the repo.
# Set this explicitly to avoid ambiguity on existing projects.
SWIFT_SOURCE_DIRS=""

status=0

if command -v swift-format >/dev/null 2>&1; then
  echo "[format] Running swift-format..."

  if [[ -n "$SWIFT_SOURCE_DIRS" ]]; then
    # Use explicitly configured directories
    for dir in $SWIFT_SOURCE_DIRS; do
      if [[ -d "$dir" ]]; then
        swift-format format --recursive --in-place "$dir" || status=$?
        echo "[format] Formatted: $dir/"
      else
        echo "[format] WARN: configured directory not found: $dir"
      fi
    done
  else
    # Auto-detect: try SPM layout first
    for dir in Sources Tests; do
      if [[ -d "$dir" ]]; then
        swift-format format --recursive --in-place "$dir" || status=$?
        echo "[format] Formatted: $dir/"
      fi
    done

    # Fallback: no Sources/ or Tests/ — find all .swift files
    if [[ ! -d "Sources" && ! -d "Tests" ]]; then
      find . -name "*.swift" \
        ! -path "./.build/*" \
        ! -path "./DerivedData/*" \
        ! -path "./generated/*" \
        -print0 | xargs -0 swift-format format --in-place || status=$?
      echo "[format] Formatted all Swift files (fallback — set SWIFT_SOURCE_DIRS to be explicit)"
    fi
  fi
else
  echo "[format] WARN: swift-format not found — skipping Swift formatting."
  echo "[format] Install: brew install swift-format"
  echo "[format] Exiting 0 so the build is not blocked."
fi

exit "$status"
