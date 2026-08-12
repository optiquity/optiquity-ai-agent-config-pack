#!/usr/bin/env bash
# pack-internal: true
# scripts/pack-tracker.sh — `pack tracker` verb dispatcher (V2 §22.1).
#
# Tracker mode is deferred indefinitely (BD-214); flat-file per-entry is
# the sole supported mode. This dispatcher is retained dormant and
# test-covered, but is NOT advertised in `pack help` — hence
# `pack-internal: true`.
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
#                           CLIENT surface only — the pack surface fails
#                           loud and names `tree-rebuild` (BD-204).
#   tree-rebuild            BD-204 Mode-3 ops contract §2: reverse-driven,
#                           NO-flip, TREE-ONLY materialization of the
#                           /backlog per-entry tree (+ `_toc.md`) from
#                           tracker state. Pack surface only at v11.0.
#   edit                    BD-204 OQ-A: thin flag-parsing wrapper over
#                           `tracker_edit_entry` (scripts/lib/tracker-edit.sh)
#                           — the Mode-3 entry-edit write channel.
#   new-entry               BD-204 OQ-A: create a NEW tracked entry in
#                           Mode 3 — compose via `tmf_compose_issue_body`,
#                           `provider_create`, id-map append, freshness
#                           stamp, then the tree-rebuild path.
#   enable-recommendations  Toggle proactive Layer-3 recommendations.
#                           (Stubbed at v11.0; body lands in BD-073.)
#
# Reference: ARCHITECTURE-V2.md §22.1;
#            ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md §2/§3 (+ its
#            AMENDMENT-2 §B8 D2 — the local-opt-in model).

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
source "$LIB_DIR/prompt.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-init.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-version.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/template-translations.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-doctor.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-edit.sh"
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
        CLIENT surface only: the pack surface has no mirror (BD-203)
        and fails loud — run `tree-rebuild` there instead.

  tree-rebuild [--repo-root PATH] [--force]
        Regenerate the /backlog per-entry tree (+ _toc.md) from
        tracker state — one-way (tracker → tree, always), no mode
        flip, tree-only (no STATUS.md / IMPLEMENTATION-PLAN.md
        deposit). Hand-edits to tree files are OVERWRITTEN WITHOUT
        DETECTION. --force = blob-wins override for the divergence
        and status-coherence comparators. Tracker mode + pack
        surface only at v11.0 (client trees: BD-207).

  edit <pack-id> [--status S] [--old-status S] [--title T]
       [--description D] [--context C] [--resolution R]
       [--file-symbol F] [--raw-body-file PATH] [--body-file PATH]
       [--add-label L]... [--remove-label L]... [--repo-root PATH]
        Mode-3 entry edit: applies the patch against the tracker
        SSOT via tracker_edit_entry (blob + H2 recomposed atomically;
        status flips cross the open/closed boundary per DP-3). Run
        `tree-rebuild` afterward to materialize the tree.

  new-entry --id BD-NNN --body-file PATH [--repo-root PATH]
        Mode-3 entry create: --body-file carries the VERBATIM entry
        span (the `**BD-NNN — Title**` bold-header line + every
        field/prose line, exactly as a per-entry file's lines 2..EOF).
        Composes the Issue body (gz64 blob + H2 projection), creates
        the Issue, appends the id-map, stamps last_tracker_write,
        then runs the tree-rebuild path so the entry materializes.

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

# BD-214 deferral gate (2026-06-12): tracker mode is deferred
# indefinitely; flat-file per-entry is the SOLE supported mode. The gate
# refuses the flip verbs with a typed error unless the TEST-ONLY seam
# PACK_TRACKER_DEFERRAL_OVERRIDE=1 is set (keeps the dormant tracker code
# testable; never set it live). Recorded in BD-214 / BD-204.
_tracker_deferral_gate() {
    if [[ "${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then
        tracker_error_emit "not-implemented" \
            "tracker support is deferred indefinitely (no release version)." \
            "Flat-file per-entry is the sole supported mode." \
            "Recorded in BD-214 / BD-204."
        return 1
    fi
    return 0
}

cmd_init() {
    _tracker_deferral_gate || return 1
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
# Verb: tree-rebuild (BD-204 Mode-3 ops contract §2)
# ─────────────────────────────────────────────────────────────────

# cmd_tree_rebuild [--repo-root PATH] [--force]
#
# The routine Mode-3 tree refresh: reverse-driven, NO mode flip,
# TREE-ONLY emission (the `tree_only` arm of
# `tracker_migrate_reverse_run` in scripts/lib/tracker-migrate-reverse.sh
# — `_toc.md` regen inherited by construction via `_tmr_emit_pack_tree`).
# One-way write (tracker → tree, always): hand-edits to /backlog files
# are overwritten WITHOUT detection. Gates (fail loud):
#   - pack surface only at v11.0 — the client tree materialization is
#     BD-207 scope;
#   - tracker mode only (`tracker_mode` == "tracker", which requires
#     mode.state="tracker" AND migration.forward_complete=true) — in
#     flat-file mode the tree IS the SSOT; nothing to rebuild from.
# --force = blob-wins override for the divergence comparator
# (`_tmr_check_blob_h2_divergence`) AND the status-coherence comparator
# (`_tmr_check_status_coherence`), matching their shared semantics.
# Design: ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md §2 (+ AMENDMENT-2
# §B8 D2-1).
cmd_tree_rebuild() {
    local repo_root="" force=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            --force)     force=1; shift ;;
            -h|--help)   usage; return 0 ;;
            *)
                tracker_error_emit "validation" "tree-rebuild: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "tree-rebuild: --repo-root is not a directory: $repo_root"
        return 1
    fi

    local surface cfg_path mode
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    if [[ "$surface" != "pack" ]]; then
        tracker_error_emit "validation" \
            "tree-rebuild: pack surface only at v11.0 (detected surface=$surface) — the client per-entry tree materialization is BD-207 scope; clients keep \`pack tracker mirror-rebuild\` until then"
        return 1
    fi
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1
    mode=$(tracker_mode "$cfg_path")
    if [[ "$mode" != "tracker" ]]; then
        tracker_error_emit "validation" \
            "tree-rebuild: not in tracker mode (mode=$mode) — the per-entry tree is the SSOT in flat-file mode; nothing to rebuild from"
        return 1
    fi

    # Engine: reverse run with dry_run=0, flip=0, comments=0, the
    # caller's force, tree_only=1.
    tracker_migrate_reverse_run "$repo_root" 0 0 0 "$force" 1
}

# ─────────────────────────────────────────────────────────────────
# Verbs: edit + new-entry (BD-204 OQ-A — Mode-3 write channel)
# ─────────────────────────────────────────────────────────────────

# cmd_edit <pack-id> [flags]
#
# Thin flag-parsing wrapper over `tracker_edit_entry`
# (scripts/lib/tracker-edit.sh): each flag maps 1:1 onto the patch-JSON
# keys that function already documents (description / context /
# resolution / file_symbol / raw_body / body / title / status /
# old_status / add_labels / remove_labels). No mutation logic lives
# here; the lib owns the blob+H2 recompose, the DP-3 boundary cross,
# and the last_tracker_write stamp. File-valued flags
# (--raw-body-file / --body-file) read with a trailing-newline sentinel
# so verbatim bytes reach the composer intact. Gate: pack surface only
# at v11.0 (the same fail-loud gate cmd_tree_rebuild / cmd_new_entry
# carry — client edits are BD-207 scope); the tracker-mode gate stays
# in tracker_edit_entry itself (defense-in-depth — flat-file misuse
# fails loud in the lib).
cmd_edit() {
    local pack_id="" repo_root=""
    local f_status="" f_old_status="" f_title=""
    local f_description="" f_context="" f_resolution="" f_file_symbol=""
    local f_raw_body_file="" f_body_file=""
    local add_labels_json='[]' remove_labels_json='[]'
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)     repo_root="$2"; shift 2 ;;
            --id)            pack_id="$2"; shift 2 ;;
            --status)        f_status="$2"; shift 2 ;;
            --old-status)    f_old_status="$2"; shift 2 ;;
            --title)         f_title="$2"; shift 2 ;;
            --description)   f_description="$2"; shift 2 ;;
            --context)       f_context="$2"; shift 2 ;;
            --resolution)    f_resolution="$2"; shift 2 ;;
            --file-symbol)   f_file_symbol="$2"; shift 2 ;;
            --raw-body-file) f_raw_body_file="$2"; shift 2 ;;
            --body-file)     f_body_file="$2"; shift 2 ;;
            --add-label)
                add_labels_json=$(printf '%s' "$add_labels_json" | jq -c --arg l "$2" '. + [$l]')
                shift 2 ;;
            --remove-label)
                remove_labels_json=$(printf '%s' "$remove_labels_json" | jq -c --arg l "$2" '. + [$l]')
                shift 2 ;;
            -h|--help)       usage; return 0 ;;
            -*)
                tracker_error_emit "validation" "edit: unknown option '$1'"
                return 1
                ;;
            *)
                if [[ -z "$pack_id" ]]; then
                    pack_id="$1"; shift
                else
                    tracker_error_emit "validation" "edit: unexpected argument '$1'"
                    return 1
                fi
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ -z "$pack_id" ]]; then
        tracker_error_emit "validation" "edit: pack-id required (positional or --id)"
        return 1
    fi

    # Gate: pack surface only (mirrors cmd_tree_rebuild / cmd_new_entry).
    # The tracker-mode gate stays in tracker_edit_entry (defense-in-depth).
    local surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    if [[ "$surface" != "pack" ]]; then
        tracker_error_emit "validation" \
            "edit: pack surface only at v11.0 (detected surface=$surface) — client edits are BD-207 scope"
        return 1
    fi

    local raw_body="" body=""
    if [[ -n "$f_raw_body_file" ]]; then
        if [[ ! -f "$f_raw_body_file" ]]; then
            tracker_error_emit "validation" "edit: --raw-body-file not found: $f_raw_body_file"
            return 1
        fi
        # Sentinel guard: preserve the file's exact trailing newline
        # through command substitution (the blob must carry it).
        raw_body=$(cat "$f_raw_body_file"; printf X); raw_body="${raw_body%X}"
    fi
    if [[ -n "$f_body_file" ]]; then
        if [[ ! -f "$f_body_file" ]]; then
            tracker_error_emit "validation" "edit: --body-file not found: $f_body_file"
            return 1
        fi
        body=$(cat "$f_body_file"; printf X); body="${body%X}"
    fi

    # Build the patch: only non-empty keys ride (tracker_edit_entry
    # treats absent and empty identically).
    local patch
    patch=$(jq -n \
        --arg status      "$f_status" \
        --arg old_status  "$f_old_status" \
        --arg title       "$f_title" \
        --arg description "$f_description" \
        --arg context     "$f_context" \
        --arg resolution  "$f_resolution" \
        --arg file_symbol "$f_file_symbol" \
        --arg raw_body    "$raw_body" \
        --arg body        "$body" \
        --argjson al "$add_labels_json" \
        --argjson rl "$remove_labels_json" \
        '{}
         + (if $status      != "" then {status: $status}           else {} end)
         + (if $old_status  != "" then {old_status: $old_status}   else {} end)
         + (if $title       != "" then {title: $title}             else {} end)
         + (if $description != "" then {description: $description} else {} end)
         + (if $context     != "" then {context: $context}         else {} end)
         + (if $resolution  != "" then {resolution: $resolution}   else {} end)
         + (if $file_symbol != "" then {file_symbol: $file_symbol} else {} end)
         + (if $raw_body    != "" then {raw_body: $raw_body}       else {} end)
         + (if $body        != "" then {body: $body}               else {} end)
         + (if ($al | length) > 0 then {add_labels: $al}           else {} end)
         + (if ($rl | length) > 0 then {remove_labels: $rl}        else {} end)')
    if [[ "$patch" == "{}" ]]; then
        tracker_error_emit "validation" "edit: empty patch — pass at least one of --status/--title/--description/--context/--resolution/--file-symbol/--raw-body-file/--body-file/--add-label/--remove-label"
        return 1
    fi

    tracker_edit_entry "$pack_id" "$patch" "$repo_root"
}

# cmd_new_entry --id BD-NNN --body-file PATH [--repo-root PATH]
#
# Mode-3 create path (BD-204 OQ-A; architecture §0 recommendation
# approved by user ruling 1). NO new codec and NO raw `gh`:
#   1. gates — tracker mode + pack surface (fail loud; client creates
#      are BD-207 scope); --id shape `^BD-[0-9]+$` (canonical per
#      BD-211 — no letter suffix); duplicate-id refusal against the
#      id-map.
#   2. parse the --body-file verbatim entry span through the REAL
#      forward parser (`_tmf_parse_backlog_file` in
#      scripts/lib/tracker-migrate-forward.sh) — the projection fields
#      + raw_body come from the same grammar the migration uses.
#   3. compose via `tmf_compose_issue_body` (gz64 blob + H2 projection,
#      size-budget gate intact); labels via `_tmf_labels_for_entry`
#      (the existing forward label map); `provider_create`.
#   4. id-map append (`tmf_mapping_set` + `tmf_mapping_save`);
#      `tracker_edit_stamp_last_write` (scripts/lib/tracker-edit.sh).
#   5. finish with the tree-rebuild path so the entry materializes in
#      /backlog and `_toc.md` regenerates (DP-4 by construction).
cmd_new_entry() {
    local repo_root="" pack_id="" body_file=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root) repo_root="$2"; shift 2 ;;
            --id)        pack_id="$2"; shift 2 ;;
            --body-file) body_file="$2"; shift 2 ;;
            -h|--help)   usage; return 0 ;;
            *)
                tracker_error_emit "validation" "new-entry: unknown option '$1'"
                return 1
                ;;
        esac
    done
    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "new-entry: --repo-root is not a directory: $repo_root"
        return 1
    fi

    # Gate: --id shape (canonical pack-backlog ID per BD-211 — integer
    # only, no letter suffix).
    if [[ ! "$pack_id" =~ ^BD-[0-9]+$ ]]; then
        tracker_error_emit "validation" \
            "new-entry: --id must match ^BD-[0-9]+\$ (canonical pack-backlog ID, no letter suffix); got '${pack_id:-<empty>}'"
        return 1
    fi
    if [[ -z "$body_file" || ! -f "$body_file" ]]; then
        tracker_error_emit "validation" \
            "new-entry: --body-file required (the verbatim entry span: bold-header line + field/prose lines); got '${body_file:-<empty>}'"
        return 1
    fi

    # Gates: pack surface + tracker mode (mirrors cmd_tree_rebuild).
    local surface cfg_path mode
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    if [[ "$surface" != "pack" ]]; then
        tracker_error_emit "validation" \
            "new-entry: pack surface only at v11.0 (detected surface=$surface) — client creates are BD-207 scope"
        return 1
    fi
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1
    mode=$(tracker_mode "$cfg_path")
    if [[ "$mode" != "tracker" ]]; then
        tracker_error_emit "validation" \
            "new-entry: not in tracker mode (mode=$mode) — in flat-file mode author the per-entry file directly per /backlog/_rules.md"
        return 1
    fi
    export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    # Gate: duplicate-id refusal against the id-map.
    local mapping_file mapping
    mapping_file=$(_tmf_mapping_file "$repo_root")
    mapping=$(tmf_mapping_load "$mapping_file")
    if printf '%s' "$mapping" | jq -e --arg k "$pack_id" 'has($k)' >/dev/null 2>&1; then
        tracker_error_emit "validation" \
            "new-entry: $pack_id already exists in the id-map ($mapping_file) — use \`pack tracker edit\` to change an existing entry"
        return 1
    fi

    # Parse the verbatim entry span through the REAL forward parser.
    local entries n_parsed entry parsed_id
    entries=$(_tmf_parse_backlog_file "$body_file") || return 1
    n_parsed=$(printf '%s' "$entries" | jq 'length')
    if [[ "$n_parsed" != "1" ]]; then
        tracker_error_emit "validation" \
            "new-entry: --body-file must contain exactly ONE entry span (parsed $n_parsed) — first line must be the \`**$pack_id — <Title>**\` bold header"
        return 1
    fi
    entry=$(printf '%s' "$entries" | jq -c '.[0]')
    parsed_id=$(printf '%s' "$entry" | jq -r '.pack_id')
    if [[ "$parsed_id" != "$pack_id" ]]; then
        tracker_error_emit "validation" \
            "new-entry: --id $pack_id does not match the body's bold-header ID $parsed_id"
        return 1
    fi

    # Compose (the SINGLE real codec; fail-loud size-budget gate inside)
    # + labels via the existing forward label map.
    local title description context resolution file_symbol raw_body body labels_json
    title="$pack_id: $(printf '%s' "$entry" | jq -r '.title')"
    description=$(printf '%s' "$entry" | jq -r '.description // ""')
    context=$(printf '%s'     "$entry" | jq -r '.context // ""')
    resolution=$(printf '%s'  "$entry" | jq -r '.resolution // ""')
    file_symbol=$(printf '%s' "$entry" | jq -r '.file_symbol // ""')
    # Trailing-newline guard (matches the forward create call-site idiom).
    raw_body=$(printf '%s' "$entry" | jq -j '.raw_body // ""'; printf X)
    raw_body="${raw_body%X}"
    body=$(tmf_compose_issue_body "$pack_id" "$description" "$context" \
        "$resolution" "$file_symbol" "$raw_body") || return 1
    labels_json=$(_tmf_labels_for_entry "$entry")

    local payload result gh_id url
    payload=$(jq -n --arg t "$title" --arg b "$body" --argjson l "$labels_json" \
        '{title: $t, body: $b, labels: $l}')
    if ! result=$(provider_create "$payload"); then
        tracker_error_emit "partial-write" \
            "new-entry: provider_create failed for $pack_id (no id-map entry written; re-run after addressing the backend failure)"
        return 1
    fi
    gh_id=$(printf '%s' "$result" | jq -r '.id')
    url=$(printf '%s'   "$result" | jq -r '.url // ""')

    # id-map append + freshness stamp.
    mapping=$(tmf_mapping_set "$mapping" "$pack_id" "$gh_id" "$url")
    tmf_mapping_save "$mapping_file" "$mapping"
    tracker_edit_stamp_last_write "$cfg_path"

    echo "new-entry: created $pack_id (gh-id $gh_id); rebuilding the tree"

    # Materialize: the tree-rebuild path (entry file + _toc.md regen).
    tracker_migrate_reverse_run "$repo_root" 0 0 0 0 1
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
# Surface auto-detected from pack-ops/ directory (pack) or docs/pack/
# (client) presence per BD-175 reorg; --surface overrides.
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
    # BD-214 deferral gate: enable-recommendations re-arms the D-19 tracker
    # recommendation seam — refuse while tracker mode is deferred.
    _tracker_deferral_gate || return 1
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
        tree-rebuild)            cmd_tree_rebuild "$@" ;;
        edit)                    cmd_edit "$@" ;;
        new-entry)               cmd_new_entry "$@" ;;
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
