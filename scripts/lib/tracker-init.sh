# scripts/lib/tracker-init.sh — `pack tracker init` orchestrator
# (BD-066).
#
# Implements V1 §6.1 wrapper steps 1–4:
#   1. Generate `tracker.toml` from the parsed flag set. (Interactive
#      dialogue per V1 §6.1 step 1 lands as a fast-follow commit.)
#   2. Validate auth (`gh auth status`) per V1 §7.3 + D-10.
#   3. Ensure issue templates exist (BD-063 ships the live templates;
#      this step verifies they are present in the working copy).
#   4. Ensure the canonical label set (BD-066's tracker-labels.sh).
#   5. Run forward migration (BD-065's tracker-migrate.sh forward).
#
# v11.0 contract: flag-driven only. The fast-follow commit replaces
# the missing-flag validation error with a prompt loop that asks the
# user for backend / repo / id-prefix / surface and then synthesizes
# the same internal flag set.
#
# Public API:
#   - tracker_init_run [<flags>...]
#       Top-level orchestrator. Parses flags, runs steps 1–5, prints
#       per-step status. Returns rc=0 on full success, rc=1 with a
#       typed error on any step failure.
#
# Reference: ARCHITECTURE.md §6.1, §7.3, §3.1; ARCHITECTURE-V2.md §22.1.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Public: tracker_init_run
# ─────────────────────────────────────────────────────────────────

tracker_init_run() {
    local repo_root="" backend="" repo="" id_prefix="" surface=""
    local no_forward=0 dry_run=0 no_labels=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)   repo_root="$2";  shift 2 ;;
            --backend)     backend="$2";    shift 2 ;;
            --repo)        repo="$2";       shift 2 ;;
            --id-prefix)   id_prefix="$2";  shift 2 ;;
            --surface)     surface="$2";    shift 2 ;;
            --no-forward)  no_forward=1;    shift ;;
            --no-labels)   no_labels=1;     shift ;;
            --dry-run)     dry_run=1;       shift ;;
            -h|--help)
                _tracker_init_usage
                return 0
                ;;
            *)
                tracker_error_emit "validation" "init: unknown option '$1'"
                return 1
                ;;
        esac
    done

    [[ -z "$repo_root" ]] && repo_root="$(pwd)"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "init: --repo-root is not a directory: $repo_root"
        return 1
    fi

    # Auto-detect surface if not provided. Pack root has PACK-CHAT.md;
    # client root has docs/pack/.
    if [[ -z "$surface" ]]; then
        if [[ -f "$repo_root/PACK-CHAT.md" ]]; then
            surface="pack"
        elif [[ -d "$repo_root/docs/pack" ]]; then
            surface="client"
        else
            tracker_error_emit "validation" \
                "init: cannot auto-detect surface; pass --surface pack|client"
            return 1
        fi
    fi

    # Default id_prefix per surface.
    if [[ -z "$id_prefix" ]]; then
        case "$surface" in
            pack)   id_prefix="BD" ;;
            client) id_prefix="TD" ;;
        esac
    fi

    # Required flags.
    if [[ -z "$backend" ]]; then
        tracker_error_emit "validation" \
            "init: --backend is required (only 'github' supported at v11.0). Re-run with --help for the full flag list."
        return 1
    fi
    if [[ -z "$repo" ]]; then
        tracker_error_emit "validation" \
            "init: --repo is required (org/name slug, e.g. Optiquity-Inc/optiquity-ai-agent-config-pack)"
        return 1
    fi
    if [[ "$backend" != "github" ]]; then
        tracker_error_emit "validation" \
            "init: backend '$backend' not supported at v11.0 (only 'github')"
        return 1
    fi

    local cfg_path
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1

    cat <<EOF
init: tracker config plan
  surface:    $surface
  repo-root:  $repo_root
  config:     $cfg_path
  backend:    $backend
  repo:       $repo
  id-prefix:  $id_prefix
  forward:    $([[ "$no_forward" == "1" ]] && echo "skipped" || echo "yes")
  dry-run:    $([[ "$dry_run" == "1" ]] && echo "yes" || echo "no")
EOF

    if [[ "$dry_run" == "1" ]]; then
        echo "init: --dry-run set; stopping after plan summary"
        return 0
    fi

    # Step 1: write tracker.toml.
    if ! _tracker_init_write_config "$cfg_path" "$backend" "$repo" "$id_prefix"; then
        return 1
    fi
    echo "init: tracker.toml written at $cfg_path"

    # Step 2: validate auth (V1 §7.3 + D-10).
    if ! _tracker_init_validate_auth; then
        return 1
    fi
    echo "init: gh auth status OK"

    # Step 3: verify issue templates exist (BD-063 ships them; init
    # only confirms they are present in the working copy).
    if ! _tracker_init_verify_templates "$repo_root" "$surface"; then
        return 1
    fi
    echo "init: issue templates present"

    # Step 4: ensure label set (BD-066's tracker-labels.sh).
    if [[ "$no_labels" == "1" ]]; then
        echo "init: --no-labels set; skipping label ensure step"
    else
        # Tell the dispatcher to use this surface's tracker.toml so
        # tracker-labels.sh's gh calls hit the right repo (the gh CLI
        # itself uses the local working repo's git remote unless
        # overridden via --repo; v11.0 init runs in the working repo).
        export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"
        if ! tracker_labels_ensure; then
            return 1
        fi
    fi

    # Step 5: forward migration.
    if [[ "$no_forward" == "1" ]]; then
        echo "init: --no-forward set; skipping forward migration"
        return 0
    fi
    if ! tracker_migrate_forward_run "$repo_root" 0 0 0; then
        return 1
    fi

    cat <<EOF

init: complete.
  $surface mode is now: tracker
  Run \`pack tracker status\` to see the new state.
  Run \`pack tracker disable\` to revert (BD-067 — pending).
EOF
}

# ─────────────────────────────────────────────────────────────────
# Private helpers
# ─────────────────────────────────────────────────────────────────

_tracker_init_usage() {
    cat <<'EOF'
Usage: pack-tracker.sh init [flags]

Required:
  --backend NAME         Tracker backend (only 'github' at v11.0).
  --repo SLUG            Repository slug (e.g. org-name/repo-name).

Optional:
  --repo-root PATH       Working-copy root (default: CWD).
  --id-prefix PREFIX     ID namespace (default: BD for pack root,
                         TD for client root).
  --surface MODE         pack | client. Auto-detected from
                         PACK-CHAT.md or docs/pack/ presence.
  --no-forward           Write config + ensure labels but skip the
                         forward migration step.
  --no-labels            Skip label ensure step (tests / dry-run only).
  --dry-run              Print the plan without writing anything.

Example (pack root):
  scripts/pack-tracker.sh init \
      --backend github \
      --repo Optiquity-Inc/optiquity-ai-agent-config-pack

Reference: ARCHITECTURE.md §6.1.
EOF
}

# Write a tracker.toml from a parsed flag set (V1 §3.1).
# Idempotent: re-running init re-writes the file; opted_in_at is
# preserved if the file already exists in tracker mode.
_tracker_init_write_config() {
    local path="$1" backend="$2" repo="$3" id_prefix="$4"
    local dir
    dir=$(dirname "$path")
    mkdir -p "$dir"

    local now_iso opted_in_at opted_in_by
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    opted_in_at="$now_iso"
    opted_in_by=$(git config user.email 2>/dev/null || echo "unknown")

    # If a tracker-mode toml already exists, preserve its opted_in_at.
    if [[ -f "$path" ]]; then
        local prior
        prior=$(tracker_config_get "$path" "mode.opted_in_at" 2>/dev/null || echo "")
        if [[ -n "$prior" ]]; then
            opted_in_at="$prior"
        fi
        local prior_by
        prior_by=$(tracker_config_get "$path" "mode.opted_in_by" 2>/dev/null || echo "")
        if [[ -n "$prior_by" ]]; then
            opted_in_by="$prior_by"
        fi
    fi

    cat > "$path" <<EOF
# tracker.toml — written by \`pack tracker init\` on $now_iso
schema_version = 1

[backend]
name = "$backend"
repo = "$repo"

[mode]
state = "tracker"
opted_in_at = "$opted_in_at"
opted_in_by = "$opted_in_by"

[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
location_status    = "STATUS.md"
location_changelog = "CHANGELOG.md"
regenerate_on_write = true

[id_namespace]
prefix = "$id_prefix"

[cli_acceleration]
prefer = "gh"

[migration]
forward_complete = false
reverse_available = false
mapping_file = ".pack-tracker/id-map.json"
EOF
}

# Validate gh auth status. Surfaces auth-missing typed error if the
# user is not logged in.
_tracker_init_validate_auth() {
    local out
    if ! out=$(gh auth status 2>&1); then
        tracker_error_emit "auth-missing" \
            "init: gh CLI is not authenticated against any host" \
            "$(printf '%s\n' "$out" | head -5)"
        return 1
    fi
    if ! printf '%s' "$out" | grep -qE "Logged in to (github.com|github\.[a-zA-Z0-9.-]+)"; then
        tracker_error_emit "auth-missing" \
            "init: gh auth status did not report a logged-in host" \
            "$(printf '%s\n' "$out" | head -5)"
        return 1
    fi
    return 0
}

# Verify the issue templates BD-063 ships are present in the working
# copy. The actual content check is done by validate-pack.py
# (check_issue_template_forms); init just confirms presence.
_tracker_init_verify_templates() {
    local repo_root="$1" surface="$2"
    local tmpl_dir
    case "$surface" in
        pack)
            tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE"
            ;;
        client)
            tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE"
            ;;
    esac
    for f in work-item.yml inbound.yml config.yml; do
        if [[ ! -f "$tmpl_dir/$f" ]]; then
            tracker_error_emit "not-found" \
                "init: issue template missing at $tmpl_dir/$f (run \`pack tracker init\` from a working copy that has BD-063's forms in place)"
            return 1
        fi
    done
}
