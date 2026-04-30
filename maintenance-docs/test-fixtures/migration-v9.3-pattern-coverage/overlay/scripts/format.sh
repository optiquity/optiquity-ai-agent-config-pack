#!/usr/bin/env bash
# FIXTURE-MARKER-S2: project-specific source paths
FIXTURE_SOURCE_PATHS="src lib tests"
# format.sh — Wrapper that detects project languages via marker files and
# invokes the appropriate format-<lang>.sh scripts.
#
# Current languages: Swift, Python
# Extension pattern: see "Adding a new language" section below.
#
# Note: format.sh is manual-only — not wired into the automatic post-edit hook.
# Run it explicitly before committing or ask repo-ops to run it.
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
# 1. Create the language-specific script: scripts/format-<lang>.sh
#    following the same pattern as format-swift.sh / format-python.sh.
#
# 2. Add a marker detection function below:
#      has_<lang>() { [ -f <marker-file> ]; }
#
# 3. Add a conditional call in the main body:
#      if has_<lang>; then
#          "$SCRIPT_DIR/format-<lang>.sh" || EXIT_CODE=1
#      fi
#
# Example: To add Kotlin with ktfmt:
#   - Create scripts/format-kotlin.sh that runs ktfmt or ktlint
#   - Add:  has_kotlin() { [ -f build.gradle.kts ] || [ -f settings.gradle.kts ]; }
#   - Add the conditional call
# ============================================================

has_swift() { [[ -f Package.swift ]] || find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; }
has_python() { [[ -f pyproject.toml ]]; }

EXIT_CODE=0
RAN_SOMETHING=0

if has_swift; then
  RAN_SOMETHING=1
  echo "[format] Swift detected — running format-swift.sh"
  "$SCRIPT_DIR/format-swift.sh" || EXIT_CODE=1
fi

if has_python; then
  RAN_SOMETHING=1
  echo "[format] Python detected — running format-python.sh"
  "$SCRIPT_DIR/format-python.sh" || EXIT_CODE=1
fi

if [[ "$RAN_SOMETHING" -eq 0 ]]; then
  echo "[format] No formattable project type detected. Looked for: Package.swift, *.xcodeproj, *.xcworkspace, pyproject.toml"
  echo "[format] If this is a new project type, add detection to scripts/format.sh (see extension pattern comment)."
  exit 0
fi

exit "$EXIT_CODE"
