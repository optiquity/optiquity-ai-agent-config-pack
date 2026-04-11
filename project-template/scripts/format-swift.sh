#!/usr/bin/env bash
# format-swift.sh — Format Swift source files using swift-format.
# Install: brew install swift-format
# If swift-format is not installed, this script warns and exits 0.
# Called by scripts/format.sh when Swift sources are detected. Safe to run directly.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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
  echo "[format-swift] Running swift-format..."

  if [[ -n "$SWIFT_SOURCE_DIRS" ]]; then
    for dir in $SWIFT_SOURCE_DIRS; do
      if [[ -d "$dir" ]]; then
        swift-format format --recursive --in-place "$dir" || status=$?
        echo "[format-swift] Formatted: $dir/"
      else
        echo "[format-swift] WARN: configured directory not found: $dir"
      fi
    done
  else
    for dir in Sources Tests; do
      if [[ -d "$dir" ]]; then
        swift-format format --recursive --in-place "$dir" || status=$?
        echo "[format-swift] Formatted: $dir/"
      fi
    done

    if [[ ! -d "Sources" && ! -d "Tests" ]]; then
      find . -name "*.swift" \
        ! -path "./.build/*" \
        ! -path "./DerivedData/*" \
        ! -path "./generated/*" \
        -print0 | xargs -0 swift-format format --in-place || status=$?
      echo "[format-swift] Formatted all Swift files (fallback — set SWIFT_SOURCE_DIRS to be explicit)"
    fi
  fi
else
  echo "[format-swift] WARN: swift-format not found — skipping Swift formatting."
  echo "[format-swift] Install: brew install swift-format"
  echo "[format-swift] Exiting 0 so the build is not blocked."
fi

exit "$status"
