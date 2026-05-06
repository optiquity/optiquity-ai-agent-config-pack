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
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-translations.sh"

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
# pack-id is shaped correctly, (d) mirror freshness vs last-forward
# timestamp, (e) template freshness — form-level template_version
# vs translation manifest's latest target, (f) issue-template dir
# presence. Reports OK / WARN / INFO per check; each WARN line
# names a recovery verb (V3 §27.1 Layer 2). Returns 0 if zero
# warnings.
#
# Capability re-probing is deferred to a future BD (capability cache
# refresh requires `provider_capabilities` re-fetch + diff).
tracker_doctor_run() {
    local repo_root="$1"
    local cfg_path mapping_file surface
    if ! surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null); then
        surface="pack"
    fi
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root")
    mapping_file="$repo_root/.pack-tracker/id-map.json"

    local n_warn=0
    echo "doctor: $repo_root"

    # (a) tracker.toml
    if [[ -f "$cfg_path" ]]; then
        if tracker_schema_version_check "$cfg_path" >/dev/null 2>&1; then
            echo "  [OK]   tracker.toml schema_version supported"
        else
            echo "  [WARN] tracker.toml schema_version unsupported  → Run: pack tracker init"
            n_warn=$((n_warn + 1))
        fi
    else
        echo "  [WARN] tracker.toml absent at $cfg_path  → Run: pack tracker init"
        n_warn=$((n_warn + 1))
    fi

    # (b) mapping file shape
    if [[ -f "$mapping_file" ]]; then
        if jq -e 'type == "object"' "$mapping_file" >/dev/null 2>&1; then
            local n
            n=$(jq 'length' "$mapping_file")
            echo "  [OK]   mapping file is valid JSON ($n entries)"
        else
            echo "  [WARN] mapping file is malformed JSON  → Run: tracker-migrate.sh forward (regenerates mapping from tracker)"
            n_warn=$((n_warn + 1))
        fi

        # (c) per-entry pack-id shape
        local bad
        bad=$(jq -r 'keys[] | select(test("^(BD|TD)-[0-9]+$|^phase-[0-9]+(\\.[0-9]+)?$") | not)' \
            "$mapping_file" 2>/dev/null | head -n 5)
        if [[ -n "$bad" ]]; then
            echo "  [WARN] mapping has malformed pack-ids  → Run: tracker-migrate.sh forward (regenerates mapping)"
            printf '         %s\n' $bad
            n_warn=$((n_warn + 1))
        else
            echo "  [OK]   all mapping pack-ids are well-shaped"
        fi
    else
        echo "  [INFO] no mapping file (expected before first forward run)"
    fi

    # (d) mirror freshness — compare BACKLOG.md mtime against
    # tracker.toml [migration].last_forward_run if both present.
    if [[ -f "$repo_root/BACKLOG.md" ]]; then
        local first_line
        first_line=$(head -n 1 "$repo_root/BACKLOG.md")
        if [[ "$first_line" == "<!--" ]]; then
            local mirror_mtime last_forward
            # macOS BSD stat differs from GNU stat; use date -r as the
            # portable reader.
            mirror_mtime=$(date -r "$repo_root/BACKLOG.md" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
            if [[ -f "$cfg_path" ]]; then
                last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "")
            fi
            if [[ -n "$mirror_mtime" && -n "$last_forward" ]]; then
                if [[ "$mirror_mtime" > "$last_forward" || "$mirror_mtime" == "$last_forward" ]]; then
                    echo "  [OK]   BACKLOG.md mirror is current (mtime=$mirror_mtime, last_forward=$last_forward)"
                else
                    echo "  [WARN] BACKLOG.md mirror is older than last_forward_run  → Run: tracker-migrate.sh forward --mirror-only"
                    n_warn=$((n_warn + 1))
                fi
            else
                echo "  [OK]   BACKLOG.md has read-only mirror header"
            fi
        else
            echo "  [INFO] BACKLOG.md has no mirror header (flat-file mode or post-reverse state)"
        fi
    fi

    # (e) template-version freshness — compare form-level
    # template_version against the translation manifest's latest
    # target. At v11.0 the manifest is empty so the form's version
    # is current by definition; the check becomes meaningful when
    # v11.1+ ships transitions.
    local tmpl_dir manifest_path
    case "$surface" in
        pack)   tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
        client) tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
    esac
    manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
    if [[ -d "$tmpl_dir" ]]; then
        local n_yml
        n_yml=$(find "$tmpl_dir" -name '*.yml' | wc -l | tr -d ' ')
        echo "  [OK]   $tmpl_dir present ($n_yml templates)"

        # Form-level template_version comparison against manifest.
        # Use the BD-069 helpers if sourced; otherwise skip silently.
        if declare -f template_version_read_form >/dev/null 2>&1 \
           && declare -f template_translations_load >/dev/null 2>&1; then
            local form_wi form_in manifest_json n_transitions
            form_wi=$(template_version_read_form "$tmpl_dir/work-item.yml" 2>/dev/null || echo "(missing)")
            form_in=$(template_version_read_form "$tmpl_dir/inbound.yml"   2>/dev/null || echo "(missing)")
            if manifest_json=$(template_translations_load "$manifest_path" 2>/dev/null); then
                n_transitions=$(printf '%s' "$manifest_json" | jq 'length' 2>/dev/null || echo "0")
                if [[ "$n_transitions" -eq 0 ]]; then
                    echo "  [OK]   template-version freshness: work-item=$form_wi, inbound=$form_in, manifest=0 transitions (current)"
                else
                    # Find the latest target template_version in the manifest. If
                    # the form-level matches the latest target, current; else stale.
                    local latest_target
                    latest_target=$(printf '%s' "$manifest_json" | jq -r '[.[] | .to] | last // ""')
                    if [[ "$form_wi" == "$latest_target" || "$form_in" == "$latest_target" ]]; then
                        echo "  [OK]   template-version freshness: form matches manifest latest target ($latest_target)"
                    else
                        echo "  [WARN] template-version stale: form work-item=$form_wi inbound=$form_in vs manifest target=$latest_target  → Run: pack tracker update-templates --dry-run"
                        n_warn=$((n_warn + 1))
                    fi
                fi
            fi
        fi
    else
        echo "  [WARN] $tmpl_dir absent  → Run: pack tracker init"
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
