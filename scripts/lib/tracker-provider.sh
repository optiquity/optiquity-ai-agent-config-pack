# scripts/lib/tracker-provider.sh — TrackerProvider abstraction (V1 §2)
#
# Sourced by migration scripts, agent-side reads, and pack-tracker
# subcommands. Provides the canonical tracker-mode read/write surface
# defined in V1 §2.1 (18 ops + raw escape hatch).
#
# Multi-backend by design (V1 §2 line 171: "smallest durable
# cross-tracker surface"). At v11.0 only the github backend ships;
# V1 §2.7 enumerates its hardcoded contract. New backends in future
# minors are added by:
#   1. Creating scripts/lib/tracker-provider-<name>.sh implementing
#      the 19 functions named tracker_provider_<name>_<op>():
#        list, get, search, create, update, close, reopen, comment,
#        set_labels, set_assignee, set_milestone,
#        link, unlink,
#        sub_issue_create, sub_issue_list, sub_issue_unlink,
#        capabilities, raw
#      (only sub_issue_* are conditional per the backend's
#      capability flags; the other 16 are required).
#   2. Adding a case to the dispatcher's switch in this file.
#   3. (Recommended) Adding a happy-path test in
#      scripts/tests/tracker-provider-test.sh that exercises the new
#      backend via the test seam below.
#
# Backend selection (in priority order):
#   1. _TRACKER_PROVIDER_BACKEND_OVERRIDE env var (test seam ONLY;
#      see scripts/tests/tracker-provider-test.sh stub-backend test).
#      NOT a user-facing knob.
#   2. tracker.toml [backend] name (BD-061; not read at v11.0 BD-060
#      land-time — pending BD-061 land).
#   3. Default: "github".
#
# Output convention:
#   - Read ops (list, get, search, sub_issue_list, capabilities) emit
#     JSON to stdout per V1 §2.2 / §2.3. list/search return
#     {items: [...], next_cursor: <string|null>} per V1 §2.6.
#   - Write ops emit a small JSON status object on success.
#   - All errors emit two lines to stderr via _tracker_provider_emit_error:
#       ERROR: <typed-code>
#       MESSAGE: <backend-specific-message>
#     and return non-zero. Typed codes per V1 §2.5.
#   - BD-070 will replace _tracker_provider_emit_error with a richer
#     scripts/lib/tracker-errors.sh helper. Until then, the inline
#     stub here is the only error surface.
#
# Reference: maintenance-docs/v11-research/ARCHITECTURE.md §2.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Backend selection
# ─────────────────────────────────────────────────────────────────

# Resolve the active backend name. Used by _tracker_provider_dispatch.
# Resolution order (V1 §3.2 + BD-061):
#   1. _TRACKER_PROVIDER_BACKEND_OVERRIDE env var (test seam; absolute).
#   2. tracker.toml backend.name when scripts/lib/tracker-config.sh is
#      sourced AND _TRACKER_PROVIDER_CONFIG_PATH points at an existing
#      file. Failures (missing key, parse error) fall through silently.
#   3. Default: "github".
_tracker_provider_backend() {
    if [[ -n "${_TRACKER_PROVIDER_BACKEND_OVERRIDE:-}" ]]; then
        echo "$_TRACKER_PROVIDER_BACKEND_OVERRIDE"
        return 0
    fi
    if declare -f tracker_backend_name >/dev/null 2>&1 && \
       [[ -n "${_TRACKER_PROVIDER_CONFIG_PATH:-}" ]] && \
       [[ -f "${_TRACKER_PROVIDER_CONFIG_PATH}" ]]; then
        local name
        if name=$(tracker_backend_name "$_TRACKER_PROVIDER_CONFIG_PATH" 2>/dev/null); then
            if [[ -n "$name" ]]; then
                echo "$name"
                return 0
            fi
        fi
    fi
    echo "github"
}

# Inline typed-error helper. Emits two stderr lines:
#   ERROR: <code>
#   MESSAGE: <message>
# BD-070 generalizes this into scripts/lib/tracker-errors.sh.
_tracker_provider_emit_error() {
    local code="$1"
    local message="${2:-}"
    echo "ERROR: $code" >&2
    if [[ -n "$message" ]]; then
        echo "MESSAGE: $message" >&2
    fi
}

# Internal dispatcher: call tracker_provider_<backend>_<op> with all
# remaining args. Emits "validation" typed error on unknown backend
# and returns non-zero.
#
# This is a real switch, not a direct call. The structure enforces
# multi-backend-readiness: adding a new backend requires adding a
# case here, not refactoring callers. The stub-backend test in
# scripts/tests/tracker-provider-test.sh verifies the dispatcher
# routes correctly to a non-github backend.
_tracker_provider_dispatch() {
    local op="$1"
    shift
    local backend
    backend=$(_tracker_provider_backend)
    case "$backend" in
        github)
            tracker_provider_gh_"$op" "$@"
            ;;
        stub)
            # Test-only stub backend; defined by stub-backend.sh in tests/.
            # Reaches this case only when _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub.
            tracker_provider_stub_"$op" "$@"
            ;;
        *)
            _tracker_provider_emit_error "validation" "Unknown backend: $backend"
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Public API: 18 ops + raw
# ─────────────────────────────────────────────────────────────────

provider_list()             { _tracker_provider_dispatch list "$@"; }
provider_get()              { _tracker_provider_dispatch get "$@"; }
provider_search()           { _tracker_provider_dispatch search "$@"; }
provider_create()           { _tracker_provider_dispatch create "$@"; }
provider_update()           { _tracker_provider_dispatch update "$@"; }
provider_close()            { _tracker_provider_dispatch close "$@"; }
provider_reopen()           { _tracker_provider_dispatch reopen "$@"; }
provider_comment()          { _tracker_provider_dispatch comment "$@"; }
provider_set_labels()       { _tracker_provider_dispatch set_labels "$@"; }
provider_set_assignee()     { _tracker_provider_dispatch set_assignee "$@"; }
provider_set_milestone()    { _tracker_provider_dispatch set_milestone "$@"; }
provider_link()             { _tracker_provider_dispatch link "$@"; }
provider_unlink()           { _tracker_provider_dispatch unlink "$@"; }
provider_sub_issue_create() { _tracker_provider_dispatch sub_issue_create "$@"; }
provider_sub_issue_list()   { _tracker_provider_dispatch sub_issue_list "$@"; }
provider_sub_issue_unlink() { _tracker_provider_dispatch sub_issue_unlink "$@"; }
provider_capabilities()     { _tracker_provider_dispatch capabilities "$@"; }
provider_raw()              { _tracker_provider_dispatch raw "$@"; }
