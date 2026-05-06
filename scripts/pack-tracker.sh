#!/usr/bin/env bash
# scripts/pack-tracker.sh — `pack tracker` verb dispatcher (V2 §22.1).
#
# Verb surface:
#   init                    Opt-in to tracker mode: write tracker.toml,
#                           validate auth, ensure templates+labels, run
#                           forward migration. (BD-066 — this commit.)
#   status                  One-screen view of tracker state (8 fields
#                           per V2 §22.1). (BD-066 — this commit.)
#   disable                 Reverse migration + flip mode to flat-file.
#                           (BD-067 — pending; placeholder.)
#   doctor                  Validate config + capabilities + mapping
#                           integrity + template freshness.
#                           (BD-067 — pending; placeholder.)
#   update-templates        Apply translation rules from older
#                           template_version to current.
#                           (BD-069 — pending; placeholder.)
#   mirror-rebuild          Rebuild flat-file mirror without re-running
#                           the full forward migration. Wraps
#                           `tracker-migrate.sh forward --mirror-only`.
#                           (BD-066 — this commit.)
#   enable-recommendations  Toggle proactive Layer-3 recommendations.
#                           (BD-073 — pending; placeholder.)
#
# Reference: ARCHITECTURE-V2.md §22.1.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-init.sh"

usage() {
    cat <<'EOF'
Usage: pack-tracker.sh <verb> [options]

Verbs:
  init [flags]
        Opt-in to tracker mode. Writes tracker.toml, validates auth,
        ensures issue templates + labels, runs forward migration.
        Required flags: --backend, --repo. See `init --help`.

  status [--repo-root PATH]
        Print tracker state (mode, backend, repo, mapping count,
        mirror freshness, template freshness, last-forward,
        last-reverse).

  mirror-rebuild [--repo-root PATH]
        Rebuild the flat-file mirror without re-running forward
        migration. Wraps `tracker-migrate.sh forward --mirror-only`.

  disable | doctor | update-templates | enable-recommendations
        Pending — surfaces a not-implemented validation error
        pointing at the BD that lands the verb.

Reference: ARCHITECTURE-V2.md §22.1.
EOF
}

# ─────────────────────────────────────────────────────────────────
# Verb: init
# ─────────────────────────────────────────────────────────────────

cmd_init() {
    tracker_init_run "$@"
}

# ─────────────────────────────────────────────────────────────────
# Verb: status
# ─────────────────────────────────────────────────────────────────

cmd_status() {
    local repo_root=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            -h|--help)   usage; return 0 ;;
            *)
                tracker_error_emit "validation" "status: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    tracker_migrate_status_report "$repo_root"
}

# ─────────────────────────────────────────────────────────────────
# Verb: mirror-rebuild
# ─────────────────────────────────────────────────────────────────

cmd_mirror_rebuild() {
    local repo_root=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            -h|--help)   usage; return 0 ;;
            *)
                tracker_error_emit "validation" "mirror-rebuild: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    tracker_migrate_forward_run "$repo_root" 0 0 1   # mirror_only=1
}

# ─────────────────────────────────────────────────────────────────
# Verbs pending in later BDs
# ─────────────────────────────────────────────────────────────────

cmd_disable() {
    tracker_error_emit "validation" \
        "disable: not implemented in this build (BD-067 — reverse migration + sidecar)"
    return 1
}

cmd_doctor() {
    tracker_error_emit "validation" \
        "doctor: not implemented in this build (BD-067 — mapping integrity + capability cache refresh)"
    return 1
}

cmd_update_templates() {
    tracker_error_emit "validation" \
        "update-templates: not implemented in this build (BD-069 — template_version dual carrier + translation rules)"
    return 1
}

cmd_enable_recommendations() {
    tracker_error_emit "validation" \
        "enable-recommendations: not implemented in this build (BD-073 — Layer-3 proactive recommendation toggle)"
    return 1
}

# ─────────────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────────────

main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi
    local verb="$1"
    shift
    case "$verb" in
        init)                    cmd_init "$@" ;;
        status)                  cmd_status "$@" ;;
        mirror-rebuild)          cmd_mirror_rebuild "$@" ;;
        disable)                 cmd_disable "$@" ;;
        doctor)                  cmd_doctor "$@" ;;
        update-templates)        cmd_update_templates "$@" ;;
        enable-recommendations)  cmd_enable_recommendations "$@" ;;
        -h|--help)               usage; exit 0 ;;
        *)
            tracker_error_emit "validation" "Unknown verb: '$verb'"
            usage
            exit 1
            ;;
    esac
}

main "$@"
