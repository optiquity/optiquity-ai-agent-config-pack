#!/usr/bin/env bash
# scripts/tracker-migrate.sh — tracker-mode migration verbs.
#
# Subcommand surface (V1 §6.1):
#   forward   flat-file → tracker (BD-065 — this commit)
#   reverse   tracker → flat-file (BD-067 — pending)
#   status    report mapping freshness (BD-065 — this commit)
#   doctor    validate mapping integrity (BD-067 — pending)
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

usage() {
    cat <<'EOF'
Usage: tracker-migrate.sh <subcommand> [options]

Subcommands:
  forward [--repo-root PATH] [--dry-run] [--resume] [--mirror-only]
        Migrate flat-file BACKLOG.md / IMPLEMENTATION_PLAN.md content
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

  reverse [--repo-root PATH]
        BD-067 — not yet implemented in this build.

  doctor [--repo-root PATH]
        BD-067 — not yet implemented in this build.

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
# Subcommand: reverse / doctor (BD-067 placeholders)
# ─────────────────────────────────────────────────────────────────

cmd_reverse() {
    tracker_error_emit "validation" "reverse: not implemented in this build (BD-067 pending)"
    return 1
}

cmd_doctor() {
    tracker_error_emit "validation" "doctor: not implemented in this build (BD-067 pending)"
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
