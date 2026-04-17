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
#
# Agent invocation notes:
# Only Claude Code has a native --agent flag. This script translates
# --agent transparently for the other two CLIs:
#
# Codex CLI: no --agent flag. Agents are registered in .codex/config.toml
#   and .codex/agents/*.toml. The script activates the agent by passing
#   its role instruction as the session prompt.
#
# Gemini CLI: no --agent flag. Agent definitions live in .gemini/agents/
#   as .md files with YAML frontmatter (native subagents). The script
#   translates to @agent-name syntax:
#   Interactive (no -p): launches gemini -i "@agent-name".
#   Headless (-p): prepends @agent-name to the -p prompt value.
#
# For the Gemini auditor, subagents cannot call other subagents, so this
# script provides external orchestration. See audit-methodology rules 56–60.

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
    auditor-ops
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
    auditor-ops
)

# Auditor subagents (in execution order for Gemini external orchestration).
# Order matches `audit-methodology` rule 53 cluster order, except auditor-ops
# is placed after auditor-tests so deployment/config issues come before pure
# code/ui findings in the consolidation pass.
AUDITOR_SUBAGENTS=(
    auditor-security
    auditor-architecture
    auditor-tests
    auditor-ops
    auditor-code
    auditor-ui
    auditor-docs
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
# --sandbox workspace-write: allows builds and tests that need disk writes
#   (Xcode DerivedData, /tmp, build caches). .git is automatically protected
#   as read-only by Codex's sandbox — git commit/push fail at OS level.
#   Source files are technically writable, but read-only agents are
#   instructed not to modify them (same trust model as Claude Code's
#   reviewer, which can write but doesn't).
# -a never: never pause to ask for command approval, so build tools
#   and linters run without interruption.
CODEX_READONLY_FLAGS=(
    "--sandbox" "workspace-write"
    "-a" "never"
)

# Flags for read-only agents on the gemini CLI.
# No --approval-mode flag: use Gemini default mode (per-command approval).
# Plan Mode (--approval-mode=plan) is read-only and blocks all command
# execution — xcodebuild, swift test, scripts — which breaks reviewer and
# tester workflows. Default mode allows build/test tools to run while
# prompting for approval before each command. Read-only agents are instructed
# not to modify source files (same trust model as Claude Code reviewer).
GEMINI_READONLY_FLAGS=()

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

Agent roster (16):
  architect, coder, reviewer, planner, tester, docs-researcher,
  grpc-schema, repo-ops, auditor, auditor-architecture, auditor-code,
  auditor-docs, auditor-security, auditor-tests, auditor-ui, auditor-ops

Read-only agents — automatically receive CLI-appropriate flags:
  claude: --permission-mode bypassPermissions
          --disallowedTools Bash(git commit:*) Bash(git push:*)
  codex:  --sandbox workspace-write  (.git protected read-only by sandbox)
          -a never
  gemini: default mode  (per-command approval; plan mode blocks builds)

  Agents: architect, reviewer, planner, tester, docs-researcher, grpc-schema,
          auditor, auditor-architecture, auditor-code, auditor-docs,
          auditor-security, auditor-tests, auditor-ui, auditor-ops

Write agents — run with default or auto-approve permissions:
  claude: default permissions
  codex:  default (workspace-write sandbox)
  gemini: --approval-mode=yolo

  Agents: coder, repo-ops

Auditor orchestration (per audit-methodology rules 56–60):
  claude: Uses its native Task tool to spawn subagents in-process via parallel
          Task calls in a single message. Pass skip rules as prose in the
          invocation prompt (e.g., "Skip auditor-ui and auditor-tests").
  codex:  Uses max_depth=2 in .codex/config.toml to spawn registered subagents
          by name. Pass skip rules as prose in the invocation prompt.
  gemini: External orchestration by this script (Gemini subagents cannot call
          other subagents). Activates each non-skipped subagent via
          @agent-name in its own Gemini session, captures reports, then
          invokes the auditor parent with all reports as input.
          Use --skip to exclude subagents (e.g., --skip auditor-ui for
          server-only projects, --skip auditor-tests for brand-new projects).
          auditor-ops never accepts a skip — every project deploys somewhere.

Skip rule defaults (per audit-methodology rules 44–47):
  - auditor-ui      skip when project has no UI layer
  - auditor-tests   skip only on first audit of a brand-new project
  - auditor-ops     never skipped
  - all four others always run

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
# Gemini auditor orchestration (external)
# ---------------------------------------------------------------------------
#
# Gemini CLI subagents cannot call other subagents. This script provides
# external orchestration: each auditor subagent runs in its own Gemini
# session in default mode (per-command approval), activated via @agent-name. The subagent's
# agent file (.gemini/agents/<name>.md) provides its system prompt, scope,
# and skill loading instructions. The -p prompt adds project-specific
# context (PLATFORM-SKILLS.md, audit-methodology rules).
#
# Reports are captured to per-subagent files in a temp directory. The parent
# consolidation prompt is passed via stdin (not -p) to avoid ARG_MAX limits.

run_gemini_auditor() {
    local skip_list="$1"
    shift
    local extra_args=("$@")

    # Reject skips for auditor-ops (rule 46).
    if [[ ",${skip_list}," == *",auditor-ops,"* ]]; then
        die "auditor-ops cannot be skipped (audit-methodology rule 46 — every project deploys somewhere)"
    fi

    # Parse skip list into an array
    local skip_array=()
    if [[ -n "$skip_list" ]]; then
        IFS=',' read -ra skip_array <<< "$skip_list"
    fi

    local tmpdir
    tmpdir="$(mktemp -d -t gemini-auditor-XXXXXX)"
    trap 'rm -rf "$tmpdir"' EXIT

    echo "[auditor] Starting Gemini auditor orchestration"
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
        local report_file="$tmpdir/${sub}.report"

        # Per-subagent prompt: the agent file (.gemini/agents/<sub>.md)
        # provides the system prompt with scope, skills, and output format.
        # This prompt adds project-specific context and activates the agent
        # via @agent-name syntax.
        local prompt
        prompt="@${sub} Run your audit cluster for this project.

Your agent file defines your scope, skills to load, and output format.
Additionally:
1. Read PLATFORM-SKILLS.md to determine which platform skills to load
   for this project's type.
2. Read the audit-methodology skill in full (rules 15–51).
3. Compute your file scope per audit-methodology rules 25–32.
4. Produce your cluster report per rules 48–51.

If you find nothing, emit the report header plus 'No findings in this
cluster.' so the parent confirms you ran."

        if gemini "${GEMINI_READONLY_FLAGS[@]}" -p "$prompt" > "$report_file" 2>&1; then
            ran_subagents+=("$sub")
            echo "[auditor]   report captured: $report_file"
        else
            echo "[auditor]   WARN: $sub failed — report may be incomplete"
            ran_subagents+=("$sub")
        fi
    done

    # Build the parent consolidation prompt as a file (not an inline arg)
    # so it can grow without hitting ARG_MAX (~256KB on macOS).
    echo "[auditor] Running auditor parent for consolidation"
    local parent_prompt_file="$tmpdir/parent.prompt"
    {
        echo "@auditor You are the auditor parent. Your agent file defines your coordination rules."
        echo ""
        echo "You have received the following subagent reports. Produce a"
        echo "consolidated audit report per the audit-methodology skill (rules"
        echo "48–55):"
        echo ""
        echo "1. Executive summary: total findings per severity, top 3 issues"
        echo "   (highest severity first; tie-break by cluster order from rule"
        echo "   38), pass/fail verdict per rules 11–13, and any subagents that"
        echo "   were skipped with the reason."
        echo "2. Append all subagent reports in cluster order (rule 53):"
        echo "   security → architecture → tests → ops → code → ui → docs."
        echo "3. Resolve duplicates per ownership precedence rules 33–39."
        echo "   When attributing a finding to one cluster, annotate the"
        echo "   surviving entry with '(also detected by: <other-clusters>)'"
        echo "   and remove the duplicate. Apply severity reconciliation per"
        echo "   rule 39 — higher severity always wins."
        echo "4. Append a '## Next steps' section listing Critical and Major"
        echo "   findings in priority order, cross-referencing the PM chat's"
        echo "   BACKLOG processing workflow."
        echo ""
        if [[ "${#skipped_subagents[@]}" -gt 0 ]]; then
            echo "Skipped subagents: ${skipped_subagents[*]}"
        else
            echo "Skipped subagents: none"
        fi
        echo ""
        for sub in "${ran_subagents[@]+"${ran_subagents[@]}"}"; do
            echo "=== ${sub} report ==="
            cat "$tmpdir/${sub}.report"
            echo ""
        done
    } > "$parent_prompt_file"

    # Pass the prompt via stdin to avoid ARG_MAX limits on -p.
    gemini "${GEMINI_READONLY_FLAGS[@]}" "${extra_args[@]+"${extra_args[@]}"}" < "$parent_prompt_file"
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

# Special case: gemini auditor uses external orchestration
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

if [[ "$CLI" == "gemini" ]]; then
    # Gemini CLI has no --agent flag. Always launch interactive (-i).
    # If -p/--prompt is in the args, treat its value as activation context
    # (not a task to execute) — strip -p and include the value in the
    # activation message. The actual task prompt is always pasted by the
    # user after the agent acknowledges.
    other_args=()
    user_context=""
    prompt_next=false
    for arg in "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"; do
        if $prompt_next; then
            user_context="$arg"
            prompt_next=false
        elif [[ "$arg" == "-p" || "$arg" == "--prompt" ]]; then
            prompt_next=true
        else
            other_args+=("$arg")
        fi
    done
    activation_msg="@${AGENT} You are now active as the ${AGENT} agent. Load your agent definition from .gemini/agents/${AGENT}.md."
    if [[ -n "$user_context" ]]; then
        activation_msg="${activation_msg} Initial context: ${user_context}."
    fi
    activation_msg="${activation_msg} Do not begin any work — acknowledge your role and wait for me to paste the task prompt."
    exec gemini "${EXTRA[@]+"${EXTRA[@]}"}" "${other_args[@]+"${other_args[@]}"}" -i "$activation_msg"
elif [[ "$CLI" == "codex" ]]; then
    # Codex CLI has no --agent flag. Always launch interactive.
    # Any positional arg is treated as activation context (not a task to
    # execute) and included in the activation message. The actual task
    # prompt is always pasted by the user after the agent acknowledges.
    codex_opts=()
    user_context=""
    skip_next=false
    for arg in "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"; do
        if $skip_next; then
            codex_opts+=("$arg")
            skip_next=false
        elif [[ "$arg" == -* ]]; then
            codex_opts+=("$arg")
            # Flags that consume a following value
            case "$arg" in
                -c|--config|-m|--model|-s|--sandbox|-a|--ask-for-approval|-p|--profile|-C|--cd|-i|--image|-o|--output-last-message|--output-schema|--color|--local-provider|--remote|--add-dir)
                    skip_next=true ;;
            esac
        else
            user_context="$arg"
        fi
    done
    activation_msg="You are the ${AGENT} agent. Read your role definition from .codex/agents/${AGENT}.toml and follow those instructions."
    if [[ -n "$user_context" ]]; then
        activation_msg="${activation_msg} Initial context: ${user_context}."
    fi
    activation_msg="${activation_msg} Do not begin any work — acknowledge your role and wait for me to paste the task prompt."
    exec codex "${EXTRA[@]}" "${codex_opts[@]+"${codex_opts[@]}"}" "$activation_msg"
else
    # Claude Code has native --agent support
    if [[ "${#EXTRA[@]}" -gt 0 ]]; then
        exec claude --agent "$AGENT" "${EXTRA[@]}" "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"
    else
        exec claude --agent "$AGENT" "${FILTERED_ARGS[@]+"${FILTERED_ARGS[@]}"}"
    fi
fi
