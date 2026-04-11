#!/usr/bin/env bash
# bootstrap-swift.sh — Resolve Swift Package Manager dependencies and verify
# Xcode availability. Called by scripts/bootstrap.sh when Package.swift or an
# Xcode project is detected. Safe to run directly for Swift-only work.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[bootstrap-swift] repo root: $ROOT_DIR"

if ! command -v swift >/dev/null 2>&1; then
  echo "[bootstrap-swift] ERROR: swift is not installed or not on PATH."
  echo "[bootstrap-swift] Install Xcode or the Swift toolchain from https://www.swift.org/download/"
  exit 1
fi

echo "[bootstrap-swift] swift version: $(swift --version | head -1)"

if [[ -f "Package.swift" ]]; then
  echo "[bootstrap-swift] Package.swift found — resolving SPM dependencies"
  swift package resolve
fi

if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
  if command -v xcodebuild >/dev/null 2>&1; then
    echo "[bootstrap-swift] Xcode project detected — open it in Xcode to complete setup"
    echo "[bootstrap-swift] Then set XCODE_SCHEME and XCODE_DESTINATION in scripts/validate-swift.sh and scripts/test-swift.sh"
  else
    echo "[bootstrap-swift] WARNING: Xcode project detected but xcodebuild not found. Install Xcode."
  fi
fi

echo "[bootstrap-swift] Swift environment ready"
