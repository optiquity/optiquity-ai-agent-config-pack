#!/usr/bin/env bash
# validate-swift.sh — Build and test the Swift side of the project.
# Called by scripts/validate.sh when Package.swift or an Xcode project is detected.
# Safe to run directly for Swift-only work.
#
# ── Xcode setup (do this on first project creation) ───────────────────────
# Replace the two variables below with your real scheme and simulator.
# Find your scheme name: xcodebuild -list
# Find simulator names:  xcrun simctl list devices available
#
# Example:
#   XCODE_SCHEME="MyApp"
#   XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
#
XCODE_SCHEME=""           # ← fill in after first Xcode target is created
XCODE_DESTINATION=""      # ← e.g. "platform=iOS Simulator,name=iPhone 16,OS=latest"
# ─────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

# SPM build and test (runs if Package.swift exists)
if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
  echo "[validate-swift] swift build"
  swift build || status=$?
  echo "[validate-swift] swift test"
  swift test || status=$?
fi

# Xcode build and test (runs only if scheme is configured above)
if command -v xcodebuild >/dev/null 2>&1; then
  if [[ -n "$XCODE_SCHEME" && -n "$XCODE_DESTINATION" ]]; then
    echo "[validate-swift] xcodebuild build-for-testing: $XCODE_SCHEME"
    xcodebuild build-for-testing \
      -scheme "$XCODE_SCHEME" \
      -destination "$XCODE_DESTINATION" \
      -quiet || status=$?
    echo "[validate-swift] xcodebuild test: $XCODE_SCHEME"
    xcodebuild test \
      -scheme "$XCODE_SCHEME" \
      -destination "$XCODE_DESTINATION" \
      -quiet || status=$?
  else
    if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
      echo "[validate-swift] ⚠️  XCODE_SCHEME is not set — xcodebuild steps skipped."
      echo "[validate-swift]    Edit scripts/validate-swift.sh and set XCODE_SCHEME and XCODE_DESTINATION to enable full validation."
    fi
  fi
fi

exit "$status"
