# scripts/lib/prompt.sh — shared interactive-prompt helpers for pack scripts.
#
# Extracted (BD-284) from the tracker-init interactive idiom so BOTH
# init-project.sh (the fresh-install confirm) and the migrator interactive
# mode (BD-283) share ONE TTY-aware prompt/UX skin. This file provides only the
# prompt/UX layer — it shares no reconciliation-engine logic across consumers.
#
# Do NOT add a shebang — this file is sourced, not executed.
#
# Sourcing convention: sourced from the ENTRY POINTS (init-project.sh,
# pack-tracker.sh, and the tracker-init test harness) BEFORE any lib that calls
# these functions. A lib that consumes them (e.g. tracker-init.sh) does not
# self-source this file; it relies on the entry point having sourced it first,
# exactly as it relies on tracker-errors.sh being pre-sourced.
#
# Test seam: PACK_PROMPT_FORCE_INTERACTIVE=1 forces the interactive branch even
# when stdin is not a TTY, so tests can pipe answers on stdin and still exercise
# the prompt path. Never set it in a live run.
#
# ── Return-code vs echo classification (call-site discipline under `set -e`) ──
#
#   Function                                    Kind         set -e call rule
#   ------------------------------------------  -----------  ---------------------
#   prompt_should_interact <off> [<on>]         RETURN-CODE  call in a conditional
#   prompt_read <label> [<default>]             ECHO (rc 0)  x=$(prompt_read ...)
#   prompt_confirm <question> [<default:y|n>]   RETURN-CODE  call in a conditional
#   prompt_choice <question> <csv> [<default>]  RETURN-CODE  capture in `if …;then`
#
#   THREE decision functions (should_interact / confirm / choice) return STATUS
#   and MUST be called in a conditional context under `set -e` (a bare call
#   aborts the script on the "no"/EOF branch). ONE input function (prompt_read)
#   always returns 0, so `x=$(prompt_read …)` is always safe to capture bare.
#
# S1 — sanctioned read-guard duplication in prompt_choice: the read-guard is
# duplicated in prompt_choice (rather than shared behind a `$()` helper) because
# command substitution COLLAPSES the inner command's exit status to that of the
# last command in the substitution (the printf), destroying the EOF-vs-empty
# signal prompt_choice must distinguish (EOF -> return non-zero; empty ->
# default / re-prompt). A shared `_read_line()` ending in `printf` returns 0 on
# both EOF and a real line, so `val=$(_read_line)` could never tell them apart —
# a signal-loss problem, not an errexit-masking problem. Correctness beats DRY;
# this is the one sanctioned duplication.

# Double-source guard: a no-op after the first source in a given process.
[[ -n "${_PACK_PROMPT_SH:-}" ]] && return 0
_PACK_PROMPT_SH=1

# prompt_should_interact <force_off> [<force_on>]
#   RETURN-CODE: 0 = interact (prompt), 1 = do NOT interact (use defaults).
#   Precedence: force_off ("1") wins; then force_on ("1"); then the
#   PACK_PROMPT_FORCE_INTERACTIVE=1 test seam; then a TTY-stdin auto-detect.
#   Call in a conditional under `set -e`.
prompt_should_interact() {
    local force_off="${1:-0}" force_on="${2:-0}"
    [[ "$force_off" == "1" ]] && return 1
    [[ "$force_on"  == "1" ]] && return 0
    [[ "${PACK_PROMPT_FORCE_INTERACTIVE:-0}" == "1" ]] && return 0
    [[ -t 0 ]] && return 0
    return 1
}

# prompt_read <label> [<default>]
#   ECHO: prints the answer (or <default> on empty input / EOF) to stdout and
#   ALWAYS returns 0 — safe to capture bare: x=$(prompt_read …). The prompt
#   label is emitted to stderr so it never pollutes the captured stdout. Read
#   from stdin (not /dev/tty) so tests can pipe answers; in real interactive use
#   stdin IS the TTY, so the same code path works.
prompt_read() {
    local label="$1" default_val="${2:-}" prompt_str answer
    if [[ -n "$default_val" ]]; then prompt_str="$label [$default_val]: "
    else prompt_str="$label: "; fi
    printf '%s' "$prompt_str" >&2
    if ! IFS= read -r answer; then printf '%s' "$default_val"; return 0; fi
    [[ -z "$answer" ]] && answer="$default_val"
    printf '%s' "$answer"
}

# prompt_confirm <question> [<default:y|n>]
#   RETURN-CODE: 0 = yes, 1 = no. The default (on empty input OR EOF) is
#   <default> (default "n"). Delegates the read to prompt_read — for a confirm,
#   EOF and empty both map to the default, so delegation is correct here (unlike
#   prompt_choice, which must distinguish them). Call in a conditional under
#   `set -e`.
prompt_confirm() {
    local question="$1" default_yn="${2:-n}" hint ans
    if [[ "$default_yn" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
    ans=$(prompt_read "$question $hint" "")
    ans=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
    [[ -z "$ans" ]] && ans="$default_yn"
    case "$ans" in y|yes) return 0 ;; *) return 1 ;; esac
}

# prompt_choice <question> <allowed_csv> [<default_token>]
#   Echoes the CANONICAL chosen token on stdout and returns 0 on a selection
#   (a valid entered token, or <default_token> on empty input when a default is
#   given). Returns NON-ZERO with NO output on EOF/closed-stdin ("no selection")
#   — the caller MUST branch on the return and map EOF to its OWN safe token
#   (never a lib-guessed token). Re-prompts on an out-of-set token, and on empty
#   input when no default is set. Case-insensitive match.
#   RETURN-CODE FUNCTION: call only in a conditional context under `set -e`.
prompt_choice() {
    local question="$1" allowed_csv="$2" default_token="${3:-}"
    local -a allowed
    IFS=',' read -r -a allowed <<< "$allowed_csv"   # no glob / word-split hazard
    local ans lc t
    while true; do
        printf '%s ' "$question" >&2
        if ! IFS= read -r ans; then
            return 1                                 # EOF -> no selection, no echo
        fi
        if [[ -z "$ans" ]]; then
            if [[ -n "$default_token" ]]; then printf '%s' "$default_token"; return 0; fi
            continue                                 # no default -> re-prompt
        fi
        lc=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
        for t in "${allowed[@]}"; do
            if [[ "$lc" == "$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')" ]]; then
                printf '%s' "$t"; return 0           # echo the CANONICAL token, not lc
            fi
        done
        printf 'Please choose one of: %s\n' "$allowed_csv" >&2
    done
}
