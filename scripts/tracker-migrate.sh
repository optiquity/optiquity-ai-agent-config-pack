#!/usr/bin/env bash
# scripts/tracker-migrate.sh — tracker-mode migration verbs.
#
# Subcommand surface (V1 §6.1):
#   forward   flat-file → tracker
#   reverse   tracker → flat-file
#   status    report mapping freshness
#   doctor    validate config + mapping integrity + template freshness
#             + capability cache
#
# Both forward and reverse are idempotent. Forward runs at opt-in;
# reverse runs on opt-out, on demand for backups, or as the final
# step before a pack upgrade that would break the integration.
#
# Reference: ARCHITECTURE.md §6.1, §6.2, §6.4.

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
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-translations.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-doctor.sh"

usage() {
    cat <<'EOF'
Usage: tracker-migrate.sh <subcommand> [options]

Subcommands:
  forward [--repo-root PATH] [--dry-run] [--resume] [--mirror-only]
        Migrate flat-file BACKLOG.md / IMPLEMENTATION-PLAN.md content
        to the tracker. Idempotent: re-runs skip existing entries.
        --repo-root    Path to the repo to migrate (default: CWD).
        --dry-run      Print what would be done; create no issues.
        --resume       Resume from .pack-tracker/forward.checkpoint.json.
        --mirror-only  Skip every step except step 10 (mirror regen).
                       Used by `pack tracker mirror-rebuild` to refresh
                       the mirror header timestamp without touching the
                       tracker. Mapping is left untouched.

  status [--repo-root PATH]
        Report mapping file freshness, mode, and migration timestamps.

  reverse [--repo-root PATH] [--dry-run] [--disable] [--include-comments]
        Reverse-migrate tracker entries back into BACKLOG.md /
        IMPLEMENTATION-PLAN.md. --disable also flips mode to
        flat-file. Idempotent on re-run.

  doctor [--repo-root PATH]
        Validate tracker.toml, mapping integrity, mirror freshness,
        template freshness, and capability cache (refreshes the
        cache as a side effect).

Reference: ARCHITECTURE.md §6.1.
EOF
}

# ─────────────────────────────────────────────────────────────────
# Subcommand: forward
# ─────────────────────────────────────────────────────────────────

cmd_forward() {
    local repo_root="" dry_run=0 resume=0 mirror_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)   repo_root="$2"; shift 2 ;;
            --dry-run)     dry_run=1; shift ;;
            --resume)      resume=1; shift ;;
            --mirror-only) mirror_only=1; shift ;;
            -h|--help)     usage; return 0 ;;
            *)
                tracker_error_emit "validation" "forward: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"

    tracker_migrate_forward_run "$repo_root" "$dry_run" "$resume" "$mirror_only"
}

# ─────────────────────────────────────────────────────────────────
# Subcommand: status
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
# Subcommand: reverse / doctor
# ─────────────────────────────────────────────────────────────────

cmd_reverse() {
    local repo_root="" dry_run=0 flip_mode=0 include_comments=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)         repo_root="$2"; shift 2 ;;
            --dry-run)           dry_run=1; shift ;;
            --disable)           flip_mode=1; shift ;;
            --include-comments)  include_comments=1; shift ;;
            -h|--help)           usage; return 0 ;;
            *)
                tracker_error_emit "validation" "reverse: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    tracker_migrate_reverse_run "$repo_root" "$dry_run" "$flip_mode" "$include_comments"
}

cmd_doctor() {
    local repo_root=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            -h|--help)   usage; return 0 ;;
            *)
                tracker_error_emit "validation" "doctor: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "doctor: --repo-root is not a directory: $repo_root"
        return 1
    fi
    tracker_doctor_run "$repo_root"
}

# tracker_doctor_run is defined in scripts/lib/tracker-doctor.sh
# (sourced above). Both this script and scripts/pack-tracker.sh
# call it; BD-130 extracted the body to the shared lib so the
# `pack tracker doctor` verb stops emitting "command not found".

# ─────────────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────────────

main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi
    local subcommand="$1"
    shift
    case "$subcommand" in
        forward) cmd_forward "$@" ;;
        status)  cmd_status "$@" ;;
        reverse) cmd_reverse "$@" ;;
        doctor)  cmd_doctor "$@" ;;
        -h|--help) usage; exit 0 ;;
        *)
            tracker_error_emit "validation" "Unknown subcommand: '$subcommand'"
            usage
            exit 1
            ;;
    esac
}

main "$@"
