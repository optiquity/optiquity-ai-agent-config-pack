#!/usr/bin/env bash
# test.sh — Wrapper that detects project languages via marker files and
# invokes the appropriate test-<lang>.sh scripts.
#
# Current languages: Swift, Python
# Extension pattern: see "Adding a new language" section below.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# ============================================================
# Adding support for a new language
# ============================================================
#
# To add a new language to this wrapper:
#
# 1. Create the language-specific script: scripts/test-<lang>.sh
#    following the same pattern as test-swift.sh / test-python.sh.
#
# 2. Add a marker detection function below.
#
# 3. Add a conditional call in the main body.
# ============================================================

has_swift() { [[ -f Package.swift ]] || find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; }
has_python() { [[ -f pyproject.toml ]]; }

EXIT_CODE=0
RAN_SOMETHING=0

if has_swift; then
  RAN_SOMETHING=1
  echo "[test] Swift detected — running test-swift.sh"
  "$SCRIPT_DIR/test-swift.sh" || EXIT_CODE=1
fi

if has_python; then
  RAN_SOMETHING=1
  echo "[test] Python detected — running test-python.sh"
  "$SCRIPT_DIR/test-python.sh" || EXIT_CODE=1
fi

if [[ "$RAN_SOMETHING" -eq 0 ]]; then
  echo "[test] No testable project type detected. Looked for: Package.swift, *.xcodeproj, *.xcworkspace, pyproject.toml"
  exit 1
fi

exit "$EXIT_CODE"
