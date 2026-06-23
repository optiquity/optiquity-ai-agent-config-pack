#!/usr/bin/env bash
# agent-post-edit-check.sh — Language-aware post-edit validation hook.
# Runs automatically via Claude Code PostToolUse hook and Codex post_edit_command.
# Never call manually.
#
# Detects the edited file's language (via extension) and runs only the
# appropriate validation. If no file extension is available (e.g., the hook
# passes no argument), falls back to detecting project type via marker files.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

echo "[agent-post-edit-check] repo root: $ROOT_DIR"

# The first argument, if provided, is the edited file path. The hook may
# pass this via $CLAUDE_TOOL_INPUT_FILE or similar; we accept it as $1.
EDITED_FILE="${1:-${CLAUDE_TOOL_INPUT_FILE:-}}"

run_swift_check() {
  if [[ -f "Package.swift" ]] && command -v swift >/dev/null 2>&1; then
    echo "[agent-post-edit-check] Swift package detected — running swift build"
    swift build || status=$?
  fi

  if command -v xcodebuild >/dev/null 2>&1; then
    if find . -maxdepth 2 \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) | grep -q .; then
      # Load XCODE_SCHEME from env var first, then fall back to the value
      # baked into scripts/validate-swift.sh so both stay in sync.
      local scheme="${XCODE_SCHEME:-}"
      if [[ -z "$scheme" ]] && [[ -f "$ROOT_DIR/scripts/validate-swift.sh" ]]; then
        scheme=$(awk -F'"' '/^XCODE_SCHEME=/{print $2; exit}' "$ROOT_DIR/scripts/validate-swift.sh" 2>/dev/null || true)
      fi

      if [[ -n "$scheme" ]]; then
        echo "[agent-post-edit-check] Xcode project detected — running xcodebuild build (scheme: $scheme)"
        xcodebuild build -scheme "$scheme" -quiet >/dev/null 2>&1 || status=$?
      else
        echo "[agent-post-edit-check] ⚠️  XCODE_SCHEME is not set — xcodebuild build check skipped."
        echo "[agent-post-edit-check]    Set XCODE_SCHEME in scripts/validate-swift.sh for full build verification."
      fi
    fi
  fi
}

run_python_check() {
  if [[ -f "pyproject.toml" ]]; then
    if command -v uv >/dev/null 2>&1; then
      echo "[agent-post-edit-check] running uv run ruff check ."
      uv run ruff check . || status=$?
    elif command -v ruff >/dev/null 2>&1; then
      echo "[agent-post-edit-check] running ruff check ."
      ruff check . || status=$?
    else
      echo "[agent-post-edit-check] ruff is not installed"
      status=1
    fi
  fi
}

run_proto_check() {
  if [[ -d "proto" ]] && command -v buf >/dev/null 2>&1; then
    echo "[agent-post-edit-check] running buf lint on proto/"
    buf lint proto/ || status=$?
  fi
}

# If we know the edited file extension, run only the relevant check.
if [[ -n "$EDITED_FILE" ]]; then
  case "$EDITED_FILE" in
    *.swift)
      run_swift_check
      ;;
    *.py)
      run_python_check
      ;;
    *.proto)
      run_proto_check
      ;;
    *.md)
      echo "[agent-post-edit-check] markdown edit ($EDITED_FILE) — running validate-docs.sh on it"
      "$ROOT_DIR/scripts/validate-docs.sh" "$EDITED_FILE" || status=$?
      ;;
    *.txt|*.json|*.yaml|*.yml|*.toml)
      echo "[agent-post-edit-check] non-code file ($EDITED_FILE) — skipping build/lint"
      ;;
    *)
      # Unknown extension — fall back to detecting project type
      echo "[agent-post-edit-check] unknown file type for $EDITED_FILE — running all detected checks"
      run_swift_check
      run_python_check
      run_proto_check
      ;;
  esac
else
  # No file info — run all detected project checks
  echo "[agent-post-edit-check] no file path provided — running all detected checks"
  run_swift_check
  run_python_check
  run_proto_check
fi

exit "$status"
