#!/usr/bin/env bash
# validate.sh — Wrapper that detects project languages and proto schemas via
# marker files and invokes the appropriate validate-<lang>.sh scripts.
#
# Current languages: Swift, Python
# Current protocols: Proto3 (via validate-proto.sh)
# Extension pattern: see "Adding a new language" section below.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# ============================================================
# Adding support for a new language or schema
# ============================================================
#
# To add a new language:
#
# 1. Create the language-specific script: scripts/validate-<lang>.sh
#    following the same pattern as validate-swift.sh / validate-python.sh.
#
# 2. Add a marker detection function below:
#      has_<lang>() { [ -f <marker-file> ]; }
#
# 3. Add a conditional call in the main body.
#
# To add a new schema type (e.g., OpenAPI):
#
# 1. Create scripts/validate-<schema>.sh
# 2. Add a marker detection (e.g., has_openapi() { [ -d openapi ]; })
# 3. Add a conditional call.
# ============================================================

has_swift() { [[ -f Package.swift ]] || find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; }
has_python() { [[ -f pyproject.toml ]]; }
has_proto() { [[ -d proto ]]; }

EXIT_CODE=0
RAN_SOMETHING=0

# Always run (language-independent): operating-doc enforcement gate.
RAN_SOMETHING=1
echo "[validate] running validate-docs.sh (operating-doc enforcement)"
"$SCRIPT_DIR/validate-docs.sh" || EXIT_CODE=1

# Always run (language-independent): pack-shipped immutable-file integrity.
echo "[validate] running verify-immutable.sh (pack-shipped immutable-file integrity)"
"$SCRIPT_DIR/verify-immutable.sh" || EXIT_CODE=1

if has_swift; then
  RAN_SOMETHING=1
  echo "[validate] Swift detected — running validate-swift.sh"
  "$SCRIPT_DIR/validate-swift.sh" || EXIT_CODE=1
fi

if has_python; then
  RAN_SOMETHING=1
  echo "[validate] Python detected — running validate-python.sh"
  "$SCRIPT_DIR/validate-python.sh" || EXIT_CODE=1
fi

if has_proto; then
  RAN_SOMETHING=1
  echo "[validate] proto/ detected — running validate-proto.sh"
  "$SCRIPT_DIR/validate-proto.sh" || EXIT_CODE=1
fi

if [[ "$RAN_SOMETHING" -eq 0 ]]; then
  echo "[validate] No project type detected. Looked for: Package.swift, *.xcodeproj, *.xcworkspace, pyproject.toml, proto/"
  echo "[validate] If this is a new project type, add detection to scripts/validate.sh (see extension pattern comment)."
  exit 1
fi

exit "$EXIT_CODE"
