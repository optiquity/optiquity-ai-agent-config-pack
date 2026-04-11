#!/usr/bin/env bash
# agent-run.sh — Launch a Claude Code, Codex, or Gemini agent with appropriate flags.
#
# Usage:
#   ./agent-run.sh <cli> --agent <name> [additional args...]
#   ./agent-run.sh gemini --agent auditor [--skip auditor-ui,auditor-tests] [-p "<prompt>"]
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
    architect
    reviewer
    planner
    tester
    docs-researcher
    grpc-schema
    auditor
    auditor-architecture
    auditor-code
    auditor-docs
    auditor-security
    auditor-tests
    auditor-ui
)

# All recognized agents. Extend this list when adding new agents.
KNOWN_AGENTS=(
    architect
    coder
    reviewer
    planner
    tester
    docs-researcher
    grpc-schema
    repo-ops
    auditor
    auditor-architecture
    auditor-code
    auditor-docs
    auditor-security
    auditor-tests
    auditor-ui
)

# Auditor subagents (in execution order for Gemini Option X orchestration).
AUDITOR_SUBAGENTS=(
    auditor-architecture
    auditor-code
    auditor-tests
    auditor-docs
    auditor-security
    auditor-ui
)

KNOWN_CLIS=(claude codex gemini)

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

# Flags for read-only agents on the gemini CLI.
# --approval-mode=plan: activates Gemini Plan Mode (read-only tool calls).
# See https://geminicli.com/docs/cli/plan-mode/
GEMINI_READONLY_FLAGS=(
    "--approval-mode=plan"
)

# Flags for write agents on the gemini CLI.
# --approval-mode=yolo: auto-approves tool calls for unattended automation.
# Equivalent to --yolo.
GEMINI_WRITE_FLAGS=(
    "--approval-mode=yolo"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
    cat <<'EOF'
Usage:
  ./agent-run.sh <cli> --agent <name> [additional args...]
  ./agent-run.sh --help

Arguments:
  <cli>           CLI to use: claude | codex | gemini
  --agent <name>  Agent to run (required)
  --skip <list>   (gemini auditor only) Comma-separated list of subagents to skip
                  Example: --skip auditor-ui,auditor-tests
  [args...]       Additional arguments passed through to the CLI unchanged

Agent roster (15):
  architect, coder, reviewer, planner, tester, docs-researcher,
  grpc-schema, repo-ops, auditor, auditor-architecture, auditor-code,
  auditor-docs, auditor-security, auditor-tests, auditor-ui

Read-only agents — automatically receive CLI-appropriate flags:
  claude: --permission-mode bypassPermissions
          --disallowedTools Bash(git commit:*) Bash(git push:*)
  codex:  --sandbox read-only  (OS-level; implicitly blocks all writes)
          -a never
  gemini: --approval-mode=plan  (Plan Mode — read-only)

  Agents: architect, reviewer, planner, tester, docs-researcher, grpc-schema,
          auditor, auditor-architecture, auditor-code, auditor-docs,
          auditor-security, auditor-tests, auditor-ui

Write agents — run with default or auto-approve permissions:
  claude: default permissions
  codex:  default (workspace-write sandbox)
  gemini: --approval-mode=yolo

  Agents: coder, repo-ops

Auditor orchestration:
  claude: Uses its native Task tool to spawn subagents in-process.
  codex:  Uses max_depth=2 in config.toml to spawn subagents.
  gemini: External orchestration by this script. Runs each subagent in a
          fresh session sequentially, captures reports, then invokes the
          auditor parent session with all reports as input.
          Use --skip to exclude subagents (e.g., --skip auditor-ui for
          server-only projects, --skip auditor-tests for brand-new projects).

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
# Gemini auditor orchestration (Option X — external)
# ---------------------------------------------------------------------------

run_gemini_auditor() {
    local skip_list="$1"
    shift
    local extra_args=("$@")

    # Parse skip list into an array
    local skip_array=()
    if [[ -n "$skip_list" ]]; then
        IFS=',' read -ra skip_array <<< "$skip_list"
    fi

    local tmpdir
    tmpdir="$(mktemp -d -t gemini-auditor-XXXXXX)"
    trap 'rm -rf "$tmpdir"' EXIT

    echo "[auditor] Starting Gemini auditor orchestration (Option X)"
    echo "[auditor] Temp directory: $tmpdir"

    local ran_subagents=()
    local skipped_subagents=()

    for sub in "${AUDITOR_SUBAGENTS[@]}"; do
        if is_in_array "$sub" "${skip_array[@]+"${skip_array[@]}"}"; then
            echo "[auditor] Skipping $sub (per --skip flag)"
            skipped_subagents+=("$sub")
            continue
        fi

        echo "[auditor] Running subagent: $sub"
        local prompt="You are acting as the ${sub} role as defined in GEMINI.md. Load the skills specified by the PM chat for this task. Produce a cluster report using the format from the audit-methodology skill."
        local report_file="$tmpdir/${sub}.report"

        if gemini "${GEMINI_READONLY_FLAGS[@]}" -p "$prompt" > "$report_file" 2>&1; then
            ran_subagents+=("$sub")
            echo "[auditor]   report captured: $report_file"
        else
            echo "[auditor]   WARN: $sub failed — report may be incomplete"
            ran_subagents+=("$sub")
        fi
    done

    # Build the parent consolidation prompt with all subagent reports embedded
    echo "[auditor] Running auditor parent for consolidation"
    local parent_prompt
    parent_prompt="You are acting as the auditor parent role as defined in GEMINI.md. You have received the following subagent reports. Produce a consolidated audit report per the audit-methodology skill: executive summary (total findings by severity, top 3 issues, overall assessment), then append all subagent reports in cluster order. Note any skipped subagents and the reason. Resolve any finding that appears in more than one report.

Skipped subagents: ${skipped_subagents[*]:-none}
"
    for sub in "${ran_subagents[@]+"${ran_subagents[@]}"}"; do
        parent_prompt+="
=== ${sub} report ===
$(cat "$tmpdir/${sub}.report")

"
    done

    gemini "${GEMINI_READONLY_FLAGS[@]}" -p "$parent_prompt" "${extra_args[@]+"${extra_args[@]}"}"
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

# Scan remaining args for --agent and --skip values.
AGENT=""
SKIP_LIST=""
FILTERED_ARGS=()
prev=""
i=0
argv=("$@")
while [[ $i -lt ${#argv[@]} ]]; do
    arg="${argv[$i]}"
    if [[ "$arg" == "--agent" ]]; then
        i=$((i + 1))
        [[ $i -lt ${#argv[@]} ]] || die "--agent requires a value."
        AGENT="${argv[$i]}"
        i=$((i + 1))
        continue
    fi
    if [[ "$arg" == "--skip" ]]; then
        i=$((i + 1))
        [[ $i -lt ${#argv[@]} ]] || die "--skip requires a value."
        SKIP_LIST="${argv[$i]}"
        i=$((i + 1))
        continue
    fi
    FILTERED_ARGS+=("$arg")
    i=$((i + 1))
done

[[ -n "$AGENT" ]] \
    || die "--agent <name> is required."

is_in_array "$AGENT" "${KNOWN_AGENTS[@]}" \
    || die "unknown agent '$AGENT'. Known agents: ${KNOWN_AGENTS[*]}"

# --skip is only meaningful for gemini auditor
if [[ -n "$SKIP_LIST" ]]; then
    if [[ "$CLI" != "gemini" ]] || [[ "$AGENT" != "auditor" ]]; then
        die "--skip is only valid for 'gemini --agent auditor'"
    fi
fi

# ---------------------------------------------------------------------------
# Build extra flags and launch
# ---------------------------------------------------------------------------

# Special case: gemini auditor uses external orchestration (Option X)
if [[ "$CLI" == "gemini" ]] && [[ "$AGENT" == "auditor" ]]; then
    run_gemini_auditor "$SKIP_LIST" "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"
    exit $?
fi

EXTRA=()
if is_in_array "$AGENT" "${READONLY_AGENTS[@]}"; then
    case "$CLI" in
        claude) EXTRA=("${CLAUDE_READONLY_FLAGS[@]}") ;;
        codex)  EXTRA=("${CODEX_READONLY_FLAGS[@]}") ;;
        gemini) EXTRA=("${GEMINI_READONLY_FLAGS[@]}") ;;
    esac
else
    # Write agents
    case "$CLI" in
        gemini) EXTRA=("${GEMINI_WRITE_FLAGS[@]}") ;;
        # claude and codex use default permissions for write agents
    esac
fi

if [[ "${#EXTRA[@]}" -gt 0 ]]; then
    exec "$CLI" "${EXTRA[@]}" "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"
else
    exec "$CLI" "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"
fi
