#!/usr/bin/env bash
# agent-run.sh — Launch a Claude Code or Codex agent with appropriate flags.
#
# Usage:
#   ./agent-run.sh <cli> --agent <name> [additional args...]
#   ./agent-run.sh --help
#
# Place this file in the project root. Modify the configuration section
# to customize agents or flags for this project. Direct CLI invocation
# still works for one-off use; use this script for ongoing consistency.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — edit to customize for this project
# ---------------------------------------------------------------------------

# Agents that produce reports and never write source files.
# These receive read-only permission flags appropriate to each CLI.
READONLY_AGENTS=(
    reviewer
    planner
    python-architect
    docs-researcher
    grpc-schema
)

# Flags for read-only agents on the claude CLI.
# --permission-mode bypassPermissions: removes tool-use confirmation prompts
#   so compilers and linters run without interruption. Safe here because
#   Edit/Write tools are excluded at the agent-definition level.
# --disallowedTools: blocks git commit and push regardless of permission mode.
CLAUDE_READONLY_FLAGS=(
    "--permission-mode" "bypassPermissions"
    "--disallowedTools" "Bash(git commit:*)" "Bash(git push:*)"
)

# Flags for read-only agents on the codex CLI.
# --sandbox read-only: OS-level enforcement — no disk writes at all,
#   which implicitly blocks git commit, git push, and any file edits.
# -a never: never pause to ask for command approval, so build tools
#   and linters run without interruption.
CODEX_READONLY_FLAGS=(
    "--sandbox" "read-only"
    "-a" "never"
)

# All recognized agents. Extend this list when adding new agents.
KNOWN_AGENTS=(
    reviewer
    planner
    python-architect
    docs-researcher
    grpc-schema
    coder
    tester
    repo-ops
)

KNOWN_CLIS=(claude codex)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
    cat <<'EOF'
Usage:
  ./agent-run.sh <cli> --agent <name> [additional args...]
  ./agent-run.sh --help

Arguments:
  <cli>           CLI to use: claude | codex
  --agent <name>  Agent to run (required)
  [args...]       Additional arguments passed through to the CLI unchanged

Read-only agents — automatically receive CLI-appropriate flags:
  claude: --permission-mode bypassPermissions
          --disallowedTools Bash(git commit:*) Bash(git push:*)
  codex:  --sandbox read-only  (OS-level; implicitly blocks all writes)
          -a never

  Agents: reviewer, planner, python-architect,
          docs-researcher, grpc-schema

Write agents — run with default permissions:
  Agents: coder, tester, repo-ops

Direct CLI invocation still works for one-off use. Use this script for
ongoing work to ensure consistent flags across the team.

To add agents or adjust flags, edit the configuration section at the
top of this file.
EOF
}

is_in_array() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

die() {
    echo "error: $*" >&2
    echo "Run ./agent-run.sh --help for usage." >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    print_usage
    exit 0
fi

CLI="$1"; shift

is_in_array "$CLI" "${KNOWN_CLIS[@]}" \
    || die "unknown CLI '$CLI'. Supported: ${KNOWN_CLIS[*]}"

command -v "$CLI" &>/dev/null \
    || die "'$CLI' is not installed or not on PATH."

[[ $# -gt 0 ]] \
    || die "--agent <name> is required."

# Scan remaining args for --agent value. The full args list passes through
# unchanged so any flags the caller added are preserved.
AGENT=""
prev=""
for arg in "$@"; do
    if [[ "$prev" == "--agent" ]]; then
        AGENT="$arg"
        break
    fi
    prev="$arg"
done

[[ -n "$AGENT" ]] \
    || die "--agent <name> is required."

is_in_array "$AGENT" "${KNOWN_AGENTS[@]}" \
    || die "unknown agent '$AGENT'. Known agents: ${KNOWN_AGENTS[*]}"

# ---------------------------------------------------------------------------
# Build extra flags and launch
# ---------------------------------------------------------------------------

EXTRA=()
if is_in_array "$AGENT" "${READONLY_AGENTS[@]}"; then
    if [[ "$CLI" == "claude" ]]; then
        EXTRA=("${CLAUDE_READONLY_FLAGS[@]}")
    elif [[ "$CLI" == "codex" ]]; then
        EXTRA=("${CODEX_READONLY_FLAGS[@]}")
    fi
fi

if [[ "${#EXTRA[@]}" -gt 0 ]]; then
    exec "$CLI" "${EXTRA[@]}" "$@"
else
    exec "$CLI" "$@"
fi
