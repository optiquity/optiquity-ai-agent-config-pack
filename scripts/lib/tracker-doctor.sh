# scripts/lib/tracker-doctor.sh — `pack tracker doctor` health check
# (BD-067 wiring fix; BD-130).
#
# Validates: (a) tracker.toml is readable + schema_version OK,
# (b) mapping file is well-formed JSON, (c) every mapping entry's
# pack-id is shaped correctly, (d) mirror freshness vs last-forward
# timestamp, (e) template freshness — form-level template_version
# vs translation manifest's latest target, (f) issue-template dir
# presence, (g) capability cache refresh — re-probe the backend's
# provider_capabilities and diff against the cached snapshot at
# .pack-tracker/capabilities.json (V2 §22.1 doctor sub-surface).
# Reports OK / WARN / INFO per check; each WARN line names a
# recovery verb (V3 §27.1 Layer 2). Returns 0 if zero warnings.
#
# Sourced by both `scripts/pack-tracker.sh` (the user-facing
# `pack tracker doctor` verb) and `scripts/tracker-migrate.sh`
# (the legacy `tracker-migrate.sh doctor` subcommand). Both
# dispatchers already source the dependencies this function needs
# (tracker-config, tracker-provider*, template-version,
# template-translations) so this lib has no `source` lines of its
# own.
#
# Public API:
#   - tracker_doctor_run <repo-root>
#       Top-level health check. Returns rc=0 when zero warnings,
#       rc=1 when any [WARN] is emitted.
#
# Reference: ARCHITECTURE.md §6.1; ARCHITECTURE-V2.md §22.1;
#            ARCHITECTURE-V3.md §27.1.
#
# Do NOT add a shebang — this file is sourced, not executed.

# tracker_doctor_run <repo-root>
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

    # (g) capability cache refresh (V2 §22.1 doctor sub-surface).
    # Re-probe provider_capabilities; diff against the cached snapshot
    # at .pack-tracker/capabilities.json. A diff signals schema-reshape
    # (V1 §9.5 / §2.7.4) — the backend's surface has changed, e.g. a
    # gh CLI extension that altered hierarchy depth, or a swap of the
    # pack to a backend with a different declaration. The cache is
    # always (re-)written on doctor completion, so doctor is itself
    # the refresh verb.
    if [[ -f "$cfg_path" ]]; then
        export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"
        local caps_now caps_cached caps_file
        caps_file="$repo_root/.pack-tracker/capabilities.json"
        if caps_now=$(provider_capabilities 2>/dev/null); then
            caps_now=$(printf '%s' "$caps_now" | jq -cS . 2>/dev/null) || caps_now=""
        else
            caps_now=""
        fi
        if [[ -n "$caps_now" ]]; then
            if [[ -f "$caps_file" ]]; then
                caps_cached=$(jq -cS . "$caps_file" 2>/dev/null || echo "")
                if [[ "$caps_now" == "$caps_cached" ]]; then
                    echo "  [OK]   capability cache current (no schema-reshape)"
                else
                    echo "  [WARN] capability cache differs from re-probe (schema-reshape)  → Run: pack tracker doctor"
                    n_warn=$((n_warn + 1))
                fi
            else
                echo "  [INFO] capability cache absent; populating $caps_file"
            fi
            mkdir -p "$repo_root/.pack-tracker"
            printf '%s\n' "$caps_now" > "$caps_file"
        else
            echo "  [INFO] provider_capabilities unavailable; skipping cache refresh"
        fi
    fi

    if [[ "$n_warn" -gt 0 ]]; then
        echo "doctor: completed with $n_warn warning(s)"
        return 1
    fi
    echo "doctor: clean"
    return 0
}
