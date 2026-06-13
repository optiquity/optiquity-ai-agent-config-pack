#!/usr/bin/env bash
# scripts/pack-td.sh — `pack td` verb dispatcher (BD-107; V3.3 §7.3).
#
# Verb surface for the `pack td` namespace per the existing
# one-script-per-noun convention (scripts/pack-tracker.sh,
# scripts/pack-help.sh).
#
# Verbs:
#   promote --to=phase-N         Path 1 — promote TD to a new phase epic.
#   promote --to=phase-N.M       Path 2 — promote TD to a new phase task.
#   resolve <td-id>              Direct close — emit the v10-lifecycle
#                                resolution JSON (no promotion labels;
#                                no new entity per V3.3 §3.2). PM Chat
#                                applies the BACKLOG status flip.
#
# Three V3.3 §3.1 outcomes routed via two verbs:
#   - direct close → `pack td resolve <td-id>` (this dispatcher)
#   - Path 1       → `pack td promote --to=phase-N <td-id>`
#   - Path 2       → `pack td promote --to=phase-N.M <td-id>`
#
# The `--to` argument's grammar disambiguates Path 1 (`phase-N`) from
# Path 2 (`phase-N.M`). NO `--fold-into` flag (Path 3 forbidden per
# V3.3 §3 line 27 / V3.3 §1 supersession). NO third subcommand.
#
# Reference:
#   - ARCHITECTURE-V3.3-DELTA.md §3.1 (outcome table)
#   - ARCHITECTURE-V3.3-DELTA.md §7.3 (verb shape)
#   - scripts/lib/tracker-promote.sh (orchestrator library)
#
# Constraints:
#   - Bash 3.2 compatible.
#   - No state-changing git verbs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source the libs in dependency order. Mirror the pattern used by
# scripts/pack-tracker.sh — we deliberately source the full tracker
# library set so promote orchestration has access to provider
# operations and BACKLOG parsing helpers.
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
source "$LIB_DIR/tracker-cycle-check.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-links.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-phase-task.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-promote.sh"

usage() {
    cat <<'EOF'
Usage: pack-td.sh <verb> [options]

Verbs:
  promote --to=phase-N <td-id> [--repo-root PATH] [--flat-file-only]
                                [--apply-backlog-patch | --no-apply-backlog-patch]
        Path 1 — promote TD to a new phase epic. Appends the phase
        section to IMPLEMENTATION-PLAN.md (tracker mode is deferred —
        BD-214; flat-file is the supported mode), re-keys the TD to
        Resolved with Resolution naming the new phase.

  promote --to=phase-N.M <td-id> [--repo-root PATH] [--flat-file-only]
                                  [--apply-backlog-patch | --no-apply-backlog-patch]
        Path 2 — promote TD to a new phase task under phase N.
        Inserts the task block into phase N's ### Tasks zone of
        IMPLEMENTATION-PLAN.md (tracker mode is deferred — BD-214;
        flat-file is the supported mode); for each Dependencies
        bullet entry on the TD, the cross-entity dependency edge is
        recorded for the deferred tracker (BD-108).

  --apply-backlog-patch (default ON when invoked directly): print a
  BACKLOG patch advisory to stderr so the human-facing shell user
  can close the loop on the TD's BACKLOG entry. PM Chat passes
  --no-apply-backlog-patch when it intends to apply via its own
  editor (PM Chat owns BACKLOG.md mutation per workflow rule).

  resolve <td-id> [--note "<text>"]
        Direct close — emits the V3.3 §3.2 resolution JSON shape
        (no promotion labels; no new entity). PM Chat applies the
        BACKLOG status flip via the existing v10-lifecycle Procedure 4.

Verb shape per V3.3 §7.3:
  pack td promote --to=phase-N
  pack td promote --to=phase-N.M

NOTE: The `--to` value's grammar disambiguates Path 1 (phase-N) from
Path 2 (phase-N.M). NO `--fold-into` flag (Path 3 is forbidden per
V3.3 §3 line 27).

Reference: ARCHITECTURE-V3.3-DELTA.md §3 + §7.3.
EOF
}

# ─────────────────────────────────────────────────────────────────
# Verb: promote
# ─────────────────────────────────────────────────────────────────

cmd_promote() {
    local target="" td_id="" repo_root="" flat_only=0 store_path=""
    local apply_backlog_patch=1
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --to=*)             target="${1#--to=}"; shift ;;
            --to)
                # F1 (BD-107 review): guard against missing $2 to keep
                # the typed-error UX intact (default `set -u` would
                # otherwise crash with an internal-looking diagnostic).
                [[ $# -lt 2 ]] && { tracker_error_emit "validation" "promote: --to requires a value (e.g. phase-7 or phase-7.4)"; return 1; }
                target="$2"; shift 2 ;;
            --repo-root)
                # F1 (BD-107 review): guard against missing $2.
                [[ $# -lt 2 ]] && { tracker_error_emit "validation" "promote: --repo-root requires a path"; return 1; }
                repo_root="$2"; shift 2 ;;
            --flat-file-only)   flat_only=1; shift ;;
            --store-path)
                # F1 (BD-107 review): guard against missing $2.
                [[ $# -lt 2 ]] && { tracker_error_emit "validation" "promote: --store-path requires a path"; return 1; }
                store_path="$2"; shift 2 ;;
            --apply-backlog-patch)
                # F4 (BD-107 review): default ON for human-facing
                # dispatcher invocation; PM Chat passes
                # --no-apply-backlog-patch when it intends to apply
                # via its own editor. The library does not mutate
                # BACKLOG.md; the dispatcher honors this flag by
                # rendering a sed/awk recipe to stderr with the
                # patch text from the result JSON (advisory only at
                # v11.0; full apply is a future BD).
                apply_backlog_patch=1; shift ;;
            --no-apply-backlog-patch)
                apply_backlog_patch=0; shift ;;
            -h|--help)          usage; return 0 ;;
            --fold-into=*|--fold-into)
                tracker_error_emit "validation" \
                    "promote: --fold-into is not supported (Path 3 forbidden per V3.3 §3 line 27 / §1 supersession)"
                return 1
                ;;
            -*)
                tracker_error_emit "validation" "promote: unknown option '$1'"
                return 1
                ;;
            *)
                if [[ -z "$td_id" ]]; then
                    td_id="$1"
                else
                    tracker_error_emit "validation" \
                        "promote: extra positional argument '$1' (expected one TD id)"
                    return 1
                fi
                shift
                ;;
        esac
    done

    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ -z "$td_id" ]]; then
        tracker_error_emit "validation" \
            "promote: TD id required (e.g. pack td promote --to=phase-7 TD-031)"
        return 1
    fi
    if [[ -z "$target" ]]; then
        tracker_error_emit "validation" \
            "promote: --to=phase-N (Path 1) or --to=phase-N.M (Path 2) required"
        return 1
    fi

    # Disambiguate Path 1 vs Path 2 by the --to grammar.
    local path
    path=$(_tpr_classify_target "$target") || return 1

    # BD-129 retro-fix F2: export `_TRACKER_PROVIDER_CONFIG_PATH` so
    # the gh invocations inside `tracker_promote_path1` /
    # `tracker_promote_path2` (specifically the `_tracker_labels_create`
    # pre-create calls and any provider_create / provider_set_labels
    # routed through `_gh_run`) can resolve the configured backend.repo
    # via `tracker_gh_repo_setup` and skip git-remote resolution.
    # Mirrors the pattern in `tracker_init_run`
    # (scripts/lib/tracker-init.sh:216) and `tracker_doctor_run`
    # (scripts/lib/tracker-doctor.sh:168). Best-effort: missing
    # tracker.toml means flat-file mode, in which case the export is a
    # no-op (helper short-circuits when `_TRACKER_PROVIDER_CONFIG_PATH`
    # is unset OR the file is missing). Failure to resolve a surface is
    # also tolerated — flat-file mode does not need GH_REPO at all.
    if [[ "$flat_only" != "1" ]]; then
        local _td_surface _td_cfg_path
        if _td_surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) \
           && _td_cfg_path=$(tracker_config_resolve_path "$_td_surface" "$repo_root" 2>/dev/null) \
           && [[ -f "$_td_cfg_path" ]]; then
            export _TRACKER_PROVIDER_CONFIG_PATH="$_td_cfg_path"
        fi
        unset _td_surface _td_cfg_path
    fi

    # F4 (BD-107 review): capture the result so we can render the
    # BACKLOG patch advisory to stderr when invoked outside PM Chat.
    # The library deliberately does NOT mutate BACKLOG.md (PM Chat
    # owns that surface per workflow rule); a direct-shell user gets
    # an explicit advisory with the resolution-text patch so they can
    # close the loop.
    local promote_result rc=0
    case "$path" in
        path1)
            promote_result=$(tracker_promote_path1 "$td_id" "$target" "$repo_root" "$flat_only") || rc=$?
            ;;
        path2)
            # Path 2 needs id-map + cycle-store for tracker-mode
            # dependency-edge creation. In flat-file mode the args are
            # ignored. We resolve the conventional locations here so
            # the verb stays simple for the user.
            local id_map_json=""
            if [[ "$flat_only" != "1" ]] && [[ -f "$repo_root/.pack-tracker/id-map.json" ]]; then
                id_map_json=$(cat "$repo_root/.pack-tracker/id-map.json")
            fi
            if [[ -z "$store_path" ]]; then
                store_path="$repo_root/.pack-tracker/links-graph.json"
            fi
            promote_result=$(tracker_promote_path2 "$td_id" "$target" "$repo_root" \
                "$id_map_json" "$store_path" "$flat_only") || rc=$?
            ;;
        *)
            tracker_error_emit "validation" \
                "promote: internal error — _tpr_classify_target returned unexpected value '$path'"
            return 1
            ;;
    esac

    # Print the orchestrator's JSON result on stdout (always; preserves
    # the v11.0 result shape consumers expect).
    [[ -n "$promote_result" ]] && printf '%s\n' "$promote_result"

    # F4 (BD-107 review): when the user invoked the verb directly
    # (apply_backlog_patch=1, the default), surface a copy-pasteable
    # BACKLOG patch advisory to stderr so the human-facing path closes
    # the loop. PM Chat passes --no-apply-backlog-patch when it
    # intends to apply via its own editor.
    if [[ $rc -eq 0 ]] && [[ $apply_backlog_patch -eq 1 ]] && [[ -n "$promote_result" ]]; then
        local res_text
        res_text=$(printf '%s' "$promote_result" | jq -r '.resolution_text // ""')
        if [[ -n "$res_text" ]]; then
            cat >&2 <<EOF
─────────────────────────────────────────────────────────────────
BACKLOG patch (apply manually OR re-run via PM Chat which applies):
  Status: Open    → Status: Resolved
  Resolved: n/a   → Resolved: $res_text
For TD entry: $td_id
─────────────────────────────────────────────────────────────────
EOF
        fi
    fi

    return $rc
}

# ─────────────────────────────────────────────────────────────────
# Verb: resolve (direct close — V3.3 §3.2 wrapper)
# ─────────────────────────────────────────────────────────────────

cmd_resolve() {
    local td_id="" note=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --note)
                # F1 (BD-107 review): guard against missing $2.
                [[ $# -lt 2 ]] && { tracker_error_emit "validation" "resolve: --note requires a value"; return 1; }
                note="$2"; shift 2 ;;
            --note=*)       note="${1#--note=}"; shift ;;
            -h|--help)      usage; return 0 ;;
            -*)
                tracker_error_emit "validation" "resolve: unknown option '$1'"
                return 1
                ;;
            *)
                if [[ -z "$td_id" ]]; then
                    td_id="$1"
                else
                    tracker_error_emit "validation" \
                        "resolve: extra positional argument '$1' (expected one TD id)"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$td_id" ]]; then
        tracker_error_emit "validation" \
            "resolve: TD id required (e.g. pack td resolve TD-031)"
        return 1
    fi
    if [[ -n "$note" ]]; then
        tracker_promote_direct_close "$td_id" "$note"
    else
        tracker_promote_direct_close "$td_id"
    fi
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
        promote)            cmd_promote "$@" ;;
        resolve)            cmd_resolve "$@" ;;
        -h|--help|help)     usage; exit 0 ;;
        *)
            tracker_error_emit "validation" "Unknown verb: '$verb'"
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
