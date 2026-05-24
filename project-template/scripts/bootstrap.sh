#!/usr/bin/env bash
# bootstrap.sh — Wrapper that detects project languages via marker files and
# invokes the appropriate bootstrap-<lang>.sh scripts.
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
# 1. Create the language-specific script: scripts/bootstrap-<lang>.sh
#    following the same pattern as bootstrap-swift.sh / bootstrap-python.sh.
#
# 2. Add a marker detection function below:
#      has_<lang>() { [ -f <marker-file> ]; }
#
# 3. Add a conditional call in the main body:
#      if has_<lang>; then
#          "$SCRIPT_DIR/bootstrap-<lang>.sh" || EXIT_CODE=1
#      fi
#
# 4. Update the "no project detected" error message below to mention
#    the new language.
#
# Example: To add Kotlin:
#   - Create scripts/bootstrap-kotlin.sh using gradle or similar
#   - Add:  has_kotlin() { [ -f build.gradle.kts ] || [ -f settings.gradle.kts ]; }
#   - Add the conditional call
# ============================================================

has_swift() { [[ -f Package.swift ]] || find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; }
has_python() { [[ -f pyproject.toml ]]; }
has_proto() { [[ -d proto ]]; }

EXIT_CODE=0
RAN_SOMETHING=0

# Skills are distributed at project creation time from the pack's
# project-template/skills/ directory directly into .claude/skills/,
# .codex/skills/, and .gemini/skills/ by `init-project.sh` (see
# in the pack repo: supporting-docs/SETUP-NEW.md Step 3).
# Once committed to git they do not need to be redistributed here.
# To update skills after a pack version upgrade, see the migration guide.

if has_swift; then
  RAN_SOMETHING=1
  echo "[bootstrap] Swift detected — running bootstrap-swift.sh"
  "$SCRIPT_DIR/bootstrap-swift.sh" || EXIT_CODE=1
fi

if has_python; then
  RAN_SOMETHING=1
  echo "[bootstrap] Python detected — running bootstrap-python.sh"
  "$SCRIPT_DIR/bootstrap-python.sh" || EXIT_CODE=1
fi

# Proto-only repos (shared schema) don't have a language bootstrap but still
# need buf available for validation and generation. Verify buf is installed.
if has_proto && [[ "$RAN_SOMETHING" -eq 0 ]]; then
  RAN_SOMETHING=1
  echo "[bootstrap] proto/ detected with no language project — verifying buf availability"
  if command -v buf >/dev/null 2>&1; then
    echo "[bootstrap] buf found: $(buf --version)"
  else
    echo "[bootstrap] ERROR: buf is not installed but proto/ exists."
    echo "[bootstrap] Install buf: https://buf.build/docs/installation"
    EXIT_CODE=1
  fi
fi

if [[ "$RAN_SOMETHING" -eq 0 ]]; then
  echo "[bootstrap] No project type detected. Looked for: Package.swift, *.xcodeproj, *.xcworkspace, pyproject.toml, proto/"
  echo "[bootstrap] If this is a new project type, add detection to scripts/bootstrap.sh (see extension pattern comment)."
  exit 1
fi

exit "$EXIT_CODE"
