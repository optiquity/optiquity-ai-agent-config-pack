#!/usr/bin/env bash
# scripts/pack-tracker.sh — `pack tracker` verb dispatcher (V2 §22.1).
#
# Verb surface:
#   init                    Opt-in to tracker mode: write tracker.toml,
#                           validate auth, ensure templates+labels, run
#                           forward migration.
#   status                  One-screen view of tracker state (8 fields
#                           per V2 §22.1).
#   disable                 Reverse migration + flip mode to flat-file.
#   doctor                  Validate config + capabilities + mapping
#                           integrity + template freshness.
#   update-templates        Apply translation rules from older
#                           template_version to current.
#   mirror-rebuild          Rebuild flat-file mirror without re-running
#                           the full forward migration. Wraps
#                           `tracker-migrate.sh forward --mirror-only`.
#   enable-recommendations  Toggle proactive Layer-3 recommendations.
#                           (Stubbed at v11.0; body lands in BD-073.)
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
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-init.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-translations.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-doctor.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/recommendation.sh"

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

  doctor [--repo-root PATH]
        Validate tracker.toml, mapping integrity, mirror freshness,
        template freshness, and capability cache (refreshes the
        cache as a side effect).

  disable [--repo-root PATH] [--include-comments] [--force]
        Reverse migration + flip mode to flat-file. --force overrides
        the race-detection and silent-data-loss guards.

  update-templates [--repo-root PATH] [--dry-run | --apply]
                   [--scope all|bd|td|inbound] [--manifest PATH]
        Apply translation rules from older template_version to the
        current pack version.

  enable-recommendations [--repo-root PATH] [--surface pack|client]
        Clear persistent_refusal so the recommendation system
        re-evaluates inflection-point signals at next session start.

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
    local repo_root="" include_comments=0 force=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)         repo_root="$2"; shift 2 ;;
            --include-comments)  include_comments=1; shift ;;
            --force)             force=1; shift ;;
            -h|--help)           usage; return 0 ;;
            *)
                tracker_error_emit "validation" "disable: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    # disable = reverse + flip mode.state to flat-file.
    # BD-132 Part 2 + 3: --force overrides race-detection refusal AND
    # silent-skip refusal. Without --force, disable refuses to run when
    # init's close ops are still propagating (race) or when any issue
    # fails to reconstruct (silent-data-loss guard).
    tracker_migrate_reverse_run "$repo_root" 0 1 "$include_comments" "$force"
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

cmd_update_templates() {
    local repo_root="" dry_run=0 apply=0 scope="all" manifest=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)  repo_root="$2"; shift 2 ;;
            --dry-run)    dry_run=1; shift ;;
            --apply)      apply=1; shift ;;
            --scope)      scope="$2"; shift 2 ;;
            --manifest)   manifest="$2"; shift 2 ;;
            -h|--help)    usage; return 0 ;;
            *)
                tracker_error_emit "validation" "update-templates: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "update-templates: --repo-root is not a directory: $repo_root"
        return 1
    fi

    case "$scope" in
        all|bd|td|inbound) ;;
        *)
            tracker_error_emit "validation" \
                "update-templates: --scope must be one of: all, bd, td, inbound (got '$scope')"
            return 1
            ;;
    esac

    # Resolve manifest path. Default: production manifest under
    # templates-archive/. Override via --manifest (used by tests).
    if [[ -z "$manifest" ]]; then
        manifest="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
    fi

    template_update_run "$repo_root" "$dry_run" "$apply" "$scope" "$manifest"
}

# template_update_run <repo-root> <dry-run> <apply> <scope> <manifest-path>
# V2 §19.2 5-step `pack tracker update-templates` implementation:
#   1. Read pack version (current template versions from
#      .github/ISSUE_TEMPLATE/).
#   2. Read tracker entries (via mapping file at v11.0; future:
#      provider_list with template:* label filter).
#   3. Compute upgrade plan per stale entry using the translation
#      manifest.
#   4. Show plan; prompt for approval unless --apply or --dry-run.
#   5. Apply rules to body + label set; write audit comment.
template_update_run() {
    local repo_root="$1"
    local dry_run="$2"
    local apply="$3"
    local scope="$4"
    local manifest_path="$5"

    # Resolve config (auto-detect surface; pack fallback for diagnostics).
    local cfg_path surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1

    # Step 1: read current pack template versions. v11.0 ships a
    # single live version per entry-type; the body comment in the
    # live forms.yml is the authoritative reading. For v11.0 the
    # current version is "bd-v11.0" / "td-v11.0" / "inbound-v11.0";
    # we read it from .github/ISSUE_TEMPLATE/ rather than hard-code.
    local live_template_dir
    case "$surface" in
        pack)   live_template_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
        client) live_template_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
    esac
    if [[ ! -d "$live_template_dir" ]]; then
        tracker_error_emit "validation" \
            "update-templates: live issue templates dir not found at $live_template_dir"
        return 1
    fi

    # Read the live work-item.yml + inbound.yml HTML-comment markers
    # to determine current versions. (v11.0: work-item-v11.0 and
    # inbound-v11.0 are the form-level versions; entry-specific
    # versions like bd-v11.0 are written by chat triage.)
    local current_work_item current_inbound
    current_work_item=$(template_version_read_form "$live_template_dir/work-item.yml")
    current_inbound=$(template_version_read_form "$live_template_dir/inbound.yml")

    # Step 2: read tracker entries. v11.0 uses the mapping file as
    # the entry index (future: provider_list with label filter, when
    # a real tracker is wired and the mapping is no longer the
    # exclusive source of truth).
    local mapping_file mapping
    mapping_file="$repo_root/.pack-tracker/id-map.json"
    if [[ ! -f "$mapping_file" ]]; then
        cat <<EOF
update-templates: no mapping file at $mapping_file
  Nothing to upgrade — this command operates on tracker entries
  registered in id-map.json. Run \`pack tracker init\` and a
  forward migration first.
EOF
        return 0
    fi
    mapping=$(cat "$mapping_file")

    # Step 3: load translation manifest + compute upgrade plan.
    local manifest_json
    if ! manifest_json=$(template_translations_load "$manifest_path"); then
        return 1
    fi

    if [[ "$manifest_json" == "[]" ]]; then
        cat <<EOF
update-templates: no upgrades available
  Translation manifest at $manifest_path is empty.
  At v11.0 no template-version transitions exist yet; this command
  becomes meaningful when v11.1+ ships with field changes.
EOF
        return 0
    fi

    cat <<EOF
update-templates: plan
  surface:    $surface
  scope:      $scope
  manifest:   $manifest_path
  current:    work-item=$current_work_item, inbound=$current_inbound
  transitions in manifest:
EOF
    printf '%s' "$manifest_json" | jq -r '.[] | "    - " + .from + " → " + .to'

    if [[ "$dry_run" == "1" ]]; then
        cat <<EOF

update-templates: --dry-run set; stopping after plan summary.
  At v11.0 the per-entry upgrade-plan walk is a structural readiness
  step. When real translation chains exist (v11.1+), this section
  will name each entry whose template_version is stale and the
  rule chain that will be applied.
EOF
        return 0
    fi

    if [[ "$apply" != "1" ]]; then
        cat <<EOF

update-templates: --apply not set; stopping before mutation.
  Re-run with --apply to write the changes, or --dry-run to keep
  the plan-only behavior explicit.
EOF
        return 0
    fi

    # Step 5: apply path. At v11.0 there are no real transitions so
    # apply is a no-op; the structural readiness for v11.1+ means
    # this branch is exercised by the test suite via a synthetic
    # manifest. Production v11.0 reaches here only via --apply on an
    # empty plan, which is harmless.
    cat <<EOF

update-templates: --apply set; no transitions to apply at v11.0.
  When v11.1+ ships, this branch walks the plan computed above and
  applies translation rules to body + labels per V2 §19.3.
EOF
}

# template_version_read_form is defined in scripts/lib/template-version.sh
# (BD-069 + Finding #12 ride-along). Local _template_update_read_form_version
# alias removed; callers use template_version_read_form directly.

# cmd_enable_recommendations [--repo-root <path>] [--surface pack|client]
#
# Per V3 §28.1.6 / D-19: clears persistent_refusal in
# .pack-tracker/recommendation-state.json so the recommendation
# system re-evaluates at the next session start. Also increments
# user_re_enable_count (informational; not used in v11 decisions
# per V3 §28.1.4).
#
# Surface auto-detected from PACK-CHAT.md (pack) or docs/pack/
# (client) presence; --surface overrides.
cmd_enable_recommendations() {
    local repo_root="" surface=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            --surface)   surface="$2";   shift 2 ;;
            -h|--help)
                cat <<'EOF'
Usage: pack-tracker.sh enable-recommendations [--repo-root <path>] [--surface pack|client]

Re-enables proactive tracker-mode recommendations after a prior
"don't ask again." The next session start re-evaluates signals;
if any threshold has been crossed, the recommendation prompt fires.

Reference: ARCHITECTURE-V3.md §28.1.6, §28.1.9.
EOF
                return 0
                ;;
            *)
                tracker_error_emit "validation" \
                    "enable-recommendations: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ -z "$surface" ]]; then
        if ! surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null); then
            surface="pack"
        fi
    fi
    if [[ "$surface" != "pack" && "$surface" != "client" ]]; then
        tracker_error_emit "validation" \
            "enable-recommendations: surface must be pack|client; got '$surface'"
        return 1
    fi

    local state_path="$repo_root/.pack-tracker/recommendation-state.json"
    # Load state (default if absent or corrupted) so
    # set_persistent_refusal has well-formed input.
    recommendation_state_load "$state_path" "$surface" >/dev/null
    recommendation_set_persistent_refusal "$state_path" "false"

    local count
    count=$(jq -r '.user_re_enable_count // 0' "$state_path")
    cat <<EOF
enable-recommendations: persistent_refusal cleared.
  surface: $surface
  state:   $state_path
  user_re_enable_count: $count
Next session evaluates fresh; recommendation may fire if signals
cross thresholds.
EOF
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
