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
    local no_forward=0 dry_run=0 no_labels=0 no_interactive=0 force=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-root)       repo_root="$2";  shift 2 ;;
            --backend)         backend="$2";    shift 2 ;;
            --repo)            repo="$2";       shift 2 ;;
            --id-prefix)       id_prefix="$2";  shift 2 ;;
            --surface)         surface="$2";    shift 2 ;;
            --no-forward)      no_forward=1;    shift ;;
            --no-labels)       no_labels=1;     shift ;;
            --dry-run)         dry_run=1;       shift ;;
            --no-interactive)  no_interactive=1; shift ;;
            --force)           force=1;         shift ;;
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

    # Prior-state safety rail (V1 §6.4 + PACK-REVIEW-CUMULATIVE-V11
    # Finding #8). Re-running `init` over an existing tracker state
    # will pick up the prior mapping and skip-recover entries against
    # whatever backend.repo the new init resolves — silently wrong if
    # the slug differs. Require explicit `--force` to proceed (or run
    # `pack tracker disable` first to clean state). The check is
    # gated by --dry-run to allow rehearsal.
    if [[ "$dry_run" != "1" && "$force" != "1" ]]; then
        local prior_map="$repo_root/.pack-tracker/id-map.json"
        if [[ -f "$prior_map" ]]; then
            tracker_error_emit "validation" \
                "init: prior tracker state found at $prior_map" \
                "Re-running init over existing state can silently rebind a stale mapping to" \
                "a different backend.repo. Run \`pack tracker disable\` to clean state, or" \
                "pass --force to acknowledge and proceed."
            return 1
        fi
    fi

    # Decide whether to prompt for missing inputs (shared prompt.sh helper):
    # interactive iff stdin is a TTY, overridable via --no-interactive
    # (CI / scripting) or the PACK_PROMPT_FORCE_INTERACTIVE=1 env seam (tests
    # that pipe stdin set it so the prompt path is exercised even on a pipe).
    local interactive
    if prompt_should_interact "$no_interactive" 0; then interactive=1; else interactive=0; fi

    # Auto-detect surface if not provided. Pack root has PACK-CHAT.md;
    # client root has docs/pack/.
    if [[ -z "$surface" ]]; then
        # BD-175: pack-side auto-detect uses pack-ops/ directory marker.
        if [[ -d "$repo_root/pack-ops" ]]; then
            surface="pack"
        elif [[ -d "$repo_root/docs/pack" ]]; then
            surface="client"
        elif [[ "$interactive" == "1" ]]; then
            surface=$(prompt_read "Surface (pack | client)" "")
            if [[ "$surface" != "pack" && "$surface" != "client" ]]; then
                tracker_error_emit "validation" \
                    "init: surface must be 'pack' or 'client'; got '$surface'"
                return 1
            fi
        else
            tracker_error_emit "validation" \
                "init: cannot auto-detect surface; pass --surface pack|client (or run interactively)"
            return 1
        fi
    fi

    # Default id_prefix per surface (auto-accepted in non-interactive
    # mode; offered as the default when prompting).
    local default_prefix
    case "$surface" in
        pack)   default_prefix="BD" ;;
        client) default_prefix="TD" ;;
        *)      default_prefix="" ;;
    esac
    if [[ -z "$id_prefix" ]]; then
        if [[ "$interactive" == "1" ]]; then
            id_prefix=$(prompt_read "ID prefix" "$default_prefix")
        else
            id_prefix="$default_prefix"
        fi
    fi

    # Backend prompt — github is the only supported value at v11.0,
    # so the prompt offers it as the default.
    if [[ -z "$backend" ]]; then
        if [[ "$interactive" == "1" ]]; then
            backend=$(prompt_read "Backend (github)" "github")
        else
            tracker_error_emit "validation" \
                "init: --backend is required (only 'github' supported at v11.0). Re-run with --help for the full flag list, or run interactively."
            return 1
        fi
    fi

    # Repo slug — no sensible default; required.
    if [[ -z "$repo" ]]; then
        if [[ "$interactive" == "1" ]]; then
            repo=$(prompt_read "Repo slug (org/name)" "")
            if [[ -z "$repo" ]]; then
                tracker_error_emit "validation" \
                    "init: repo slug is required (org/name, e.g. DShaneNYC/optiquity-ai-agent-config-pack)"
                return 1
            fi
        else
            tracker_error_emit "validation" \
                "init: --repo is required (org/name slug, e.g. DShaneNYC/optiquity-ai-agent-config-pack)"
            return 1
        fi
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

    # Step 1: write tracker.toml. Neither surface emits a [mirror]
    # table — no surface keeps a monolith mirror (the per-entry tree +
    # `_toc.md` is the sole SSOT and readable form).
    if ! _tracker_init_write_config "$cfg_path" "$backend" "$repo" "$id_prefix" "$surface"; then
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
  Run \`pack tracker disable\` to revert.
EOF
}

# ─────────────────────────────────────────────────────────────────
# Private helpers
# ─────────────────────────────────────────────────────────────────

_tracker_init_usage() {
    cat <<'EOF'
Usage: pack-tracker.sh init [flags]

When run interactively (stdin is a TTY) any required input that is
not provided as a flag is prompted for. Pass --no-interactive to
disable prompting (CI / scripting contexts).

Required (when --no-interactive or missing flags in TTY skipped):
  --backend NAME         Tracker backend (only 'github' at v11.0).
  --repo SLUG            Repository slug (e.g. org-name/repo-name).

Optional:
  --repo-root PATH       Working-copy root (default: CWD).
  --id-prefix PREFIX     ID namespace (default: BD for pack root,
                         TD for client root).
  --surface MODE         pack | client. Auto-detected from
                         PACK-CHAT.md or docs/pack/ presence;
                         prompted if neither marker exists.
  --no-forward           Write config + ensure labels but skip the
                         forward migration step.
  --no-labels            Skip label ensure step (tests / dry-run only).
  --dry-run              Print the plan without writing anything.
  --no-interactive       Disable prompting; require all inputs as
                         flags. Default in non-TTY contexts.
  --force                Bypass the prior-state safety rail (the
                         check that rejects re-init when
                         .pack-tracker/id-map.json already exists).
                         Use only when re-pointing init to the same
                         backend.repo intentionally.

Example (pack root, interactive):
  scripts/pack-tracker.sh init

Example (pack root, all-flags):
  scripts/pack-tracker.sh init \
      --backend github \
      --repo DShaneNYC/optiquity-ai-agent-config-pack \
      --no-interactive

Reference: ARCHITECTURE.md §6.1.
EOF
}

# (BD-284) The former `_tracker_init_prompt` helper was byte-identical to
# `prompt_read` in `scripts/lib/prompt.sh`; it has been deleted and its callers
# now delegate to the shared helper (sourced by the entry point before this
# lib). No shim is kept — there are no external callers.

# Write a tracker.toml from a parsed flag set (V1 §3.1).
# Idempotent: re-running init re-writes the file; opted_in_at is
# preserved if the file already exists in tracker mode.
#
# No [mirror] table on EITHER surface (BD-206, completing the BD-203/
# BD-204 no-monolith repoint): no surface keeps a monolith mirror — the
# per-entry trees (+ regenerated _toc.md) are the sole flat
# representation, and _toc.md regeneration is not a "mirror file" in the
# Check 29 sense. validate-pack.py's _check_mirror_staleness treats the
# absent table as a no-mirror surface (staleness N/A soft-pass). The
# `surface` arg is retained for other surface-conditional behavior.
_tracker_init_write_config() {
    local path="$1" backend="$2" repo="$3" id_prefix="$4" surface="$5"
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

    # No [mirror] table is emitted on any surface (see function
    # docstring): the config flows straight from [mode] to
    # [id_namespace]. `surface` is retained as a positional arg for
    # other surface-conditional behavior.
    : "$surface"

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
