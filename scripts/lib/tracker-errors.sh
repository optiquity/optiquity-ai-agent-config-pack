# scripts/lib/tracker-errors.sh — central typed-error formatter for
# tracker-mode operations.
#
# Sourced by every tracker-mode lib script (tracker-provider.sh,
# tracker-provider-gh.sh, tracker-config.sh, and the migration
# scripts that ship in BD-065 / BD-067).
#
# Implements:
#   - V1 §2.5: 10 typed error codes (network-unreachable,
#     rate-limit-primary, rate-limit-secondary, auth-missing,
#     auth-expired, auth-insufficient-scope, not-found, validation,
#     schema-reshape, partial-write).
#   - V1 §9: per-code user-facing message shape — caller passes the
#     contextual lines per V1 §9.x; the formatter wraps them in the
#     canonical ERROR/MESSAGE prefix and appends the next-step verb.
#   - V3 §27.1 Layer 2: every error message ends with one
#     unambiguous "→ Run: <verb>" line.
#
# Per D-7 (no silent retry): every failure emits a typed code and a
# diagnostic; callers do NOT retry from inside this lib. The user
# decides whether to re-invoke after addressing the diagnostic.
#
# Output format (caller writes to stderr via tracker_error_emit, or
# stdout via tracker_error_format for testing / log capture):
#
#   ERROR: <code>
#   MESSAGE: <one-line backend message>            (if message arg passed)
#   <extra context lines passed verbatim>          (zero or more)
#   → Run: <verb-from-table>
#
# The first two lines preserve the format that BD-060/BD-061 callers
# already emit (ERROR: <code> / MESSAGE: <message>) — backward
# compatible with existing tests.
#
# Reference: ARCHITECTURE.md §2.5, §9.1–§9.7;
#            ARCHITECTURE-V3.md §27.1.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

# tracker_error_emit <code> [<message>] [<extra-line>...]
# Emits the formatted error block to stderr and returns 1 so that
# callers can chain `func || return 1` without extra checks.
tracker_error_emit() {
    tracker_error_format "$@" >&2
    return 1
}

# tracker_error_format <code> [<message>] [<extra-line>...]
# Same shape as tracker_error_emit but emits to stdout. Used by tests
# and by callers that want to re-route the formatted block (e.g. into
# a log file).
tracker_error_format() {
    local code="${1:-validation}"
    local message=""
    if [[ $# -ge 2 ]]; then
        message="$2"
    fi

    # Skip past code + message; remaining args are verbatim context lines.
    if [[ $# -ge 2 ]]; then
        shift 2
    elif [[ $# -ge 1 ]]; then
        shift 1
    fi

    echo "ERROR: $code"
    if [[ -n "$message" ]]; then
        echo "MESSAGE: $message"
    fi
    while [[ $# -gt 0 ]]; do
        echo "$1"
        shift
    done
    echo "→ Run: $(_tracker_error_verb "$code")"
}

# tracker_error_codes — emit the 10 supported codes, one per line.
# Used by tests + documentation generators.
tracker_error_codes() {
    cat <<'EOF'
network-unreachable
rate-limit-primary
rate-limit-secondary
auth-missing
auth-expired
auth-insufficient-scope
not-found
validation
schema-reshape
partial-write
not-implemented
EOF
}

# ─────────────────────────────────────────────────────────────────
# Verb table (V1 §9 + V3 §27.1 Layer 2)
# ─────────────────────────────────────────────────────────────────

_tracker_error_verb() {
    # One unambiguous verb per code per V3 §27.1 Layer 2. Verbs match
    # V1 §9.x's intended next-step framing without parenthetical
    # alternatives or follow-on hints. Caller-supplied context lines
    # (passed as additional args to tracker_error_format) carry any
    # qualifying detail.
    case "$1" in
        network-unreachable)        echo "gh api rate_limit" ;;            # V1 §9.1: confirm connectivity
        rate-limit-primary|rate-limit-secondary)
                                    echo "wait for the reset window, then re-run" ;;  # V1 §9.2
        auth-missing|auth-expired)  echo "gh auth login" ;;                 # V1 §9.3
        auth-insufficient-scope)    echo "gh auth refresh -s <scope>" ;;    # V1 §9.4
        not-found)                  echo "verify the issue id and re-run" ;;
        validation)                 echo "review the backend message above" ;;
        schema-reshape)             echo "pack tracker doctor" ;;           # V1 §9.5
        partial-write)              echo "see resume options above" ;;     # V1 §9.6
        not-implemented)            echo "pack tracker doctor" ;;          # surfaces which BD lands the verb
        *)                          echo "review the message above" ;;
    esac
}
