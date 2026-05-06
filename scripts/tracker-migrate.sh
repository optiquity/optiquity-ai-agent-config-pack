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
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

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
    tracker_doctor_run "$repo_root"
}

# tracker_doctor_run <repo-root>
# Validates: (a) tracker.toml is readable + schema_version OK,
# (b) mapping file is well-formed JSON, (c) every mapping entry's
# pack-id is shaped correctly, (d) mirror freshness, (e) template
# freshness. Reports OK/WARN per check; returns 0 if all OK.
# Capability re-probing is deferred to a future BD.
tracker_doctor_run() {
    local repo_root="$1"
    local cfg_path mapping_file
    cfg_path=$(tracker_config_resolve_path pack "$repo_root")
    mapping_file="$repo_root/.pack-tracker/id-map.json"

    local n_warn=0
    echo "doctor: $repo_root"

    # (a) tracker.toml
    if [[ -f "$cfg_path" ]]; then
        if tracker_schema_version_check "$cfg_path" >/dev/null 2>&1; then
            echo "  [OK]   tracker.toml schema_version supported"
        else
            echo "  [WARN] tracker.toml schema_version unsupported"
            n_warn=$((n_warn + 1))
        fi
    else
        echo "  [WARN] tracker.toml absent at $cfg_path"
        n_warn=$((n_warn + 1))
    fi

    # (b) mapping file shape
    if [[ -f "$mapping_file" ]]; then
        if jq -e 'type == "object"' "$mapping_file" >/dev/null 2>&1; then
            local n
            n=$(jq 'length' "$mapping_file")
            echo "  [OK]   mapping file is valid JSON ($n entries)"
        else
            echo "  [WARN] mapping file is malformed JSON"
            n_warn=$((n_warn + 1))
        fi

        # (c) per-entry pack-id shape
        local bad
        bad=$(jq -r 'keys[] | select(test("^(BD|TD)-[0-9]+$|^phase-[0-9]+(\\.[0-9]+)?$") | not)' \
            "$mapping_file" 2>/dev/null | head -n 5)
        if [[ -n "$bad" ]]; then
            echo "  [WARN] mapping has malformed pack-ids:"
            printf '         %s\n' $bad
            n_warn=$((n_warn + 1))
        else
            echo "  [OK]   all mapping pack-ids are well-shaped"
        fi
    else
        echo "  [INFO] no mapping file (expected before first forward run)"
    fi

    # (d) mirror freshness
    if [[ -f "$repo_root/BACKLOG.md" ]]; then
        local first_line
        first_line=$(head -n 1 "$repo_root/BACKLOG.md")
        if [[ "$first_line" == "<!--" ]]; then
            echo "  [OK]   BACKLOG.md has read-only mirror header"
        else
            echo "  [INFO] BACKLOG.md has no mirror header (flat-file mode or post-reverse state)"
        fi
    fi

    # (e) template freshness
    if [[ -d "$repo_root/.github/ISSUE_TEMPLATE" ]]; then
        local n_yml
        n_yml=$(find "$repo_root/.github/ISSUE_TEMPLATE" -name '*.yml' | wc -l | tr -d ' ')
        echo "  [OK]   .github/ISSUE_TEMPLATE present ($n_yml templates)"
    else
        echo "  [WARN] .github/ISSUE_TEMPLATE absent (run \`pack tracker init\`)"
        n_warn=$((n_warn + 1))
    fi

    if [[ "$n_warn" -gt 0 ]]; then
        echo "doctor: completed with $n_warn warning(s)"
        return 1
    fi
    echo "doctor: clean"
    return 0
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
