# scripts/lib/tracker-doctor.sh — `pack tracker doctor` health check
# (BD-067 wiring fix; BD-130).
#
# Validates: (a) tracker.toml is readable + schema_version OK,
# (b) mapping file is well-formed JSON, (c) every mapping entry's
# pack-id is shaped correctly, (d) mirror freshness vs last-forward
# timestamp, (e) template-version freshness — form-level
# template_version vs translation manifest's latest target,
# (f) issue-template dir presence, (g) capability cache refresh —
# re-probe the backend's provider_capabilities and diff against
# the cached snapshot at .pack-tracker/capabilities.json
# (V2 §22.1 doctor sub-surface). Reports OK / WARN / INFO per
# check; each WARN line names a recovery verb from the user-facing
# `pack tracker` surface (V3 §27.1 Layer 2). Returns 0 if zero
# warnings.
#
# Sourced by both `scripts/pack-tracker.sh` (the user-facing
# `pack tracker doctor` verb) and `scripts/tracker-migrate.sh`
# (the legacy `tracker-migrate.sh doctor` subcommand). Both
# dispatchers already source the dependencies this function needs
# (tracker-config, tracker-provider*, template-version,
# template-translations) so this lib has no `source` lines of its
# own. The defensive `declare -f` probe at the top of
# `tracker_doctor_run` enforces that calling-convention contract:
# any future caller that sources this lib without first sourcing
# the dependencies gets a clear `ERROR: missing dependency` line
# rather than the bare `command not found` failure that BD-130 was
# created to fix.
#
# Public API:
#   - tracker_doctor_run <repo-root>
#       Top-level health check. Returns rc=0 when zero warnings,
#       rc=1 when any [WARN] is emitted, rc=2 when a calling-
#       convention dependency is missing (defensive probe failure).
#
# Reference: ARCHITECTURE.md §6.1; ARCHITECTURE-V2.md §22.1;
#            ARCHITECTURE-V3.md §27.1.
#
# Do NOT add a shebang — this file is sourced, not executed.

# tracker_doctor_run <repo-root>
tracker_doctor_run() {
    local repo_root="$1"

    # Defensive dependency probe (M-4). The lib body calls into
    # functions defined by tracker-config.sh, tracker-provider*.sh,
    # template-version.sh, and template-translations.sh. Both shipped
    # callers (scripts/pack-tracker.sh, scripts/tracker-migrate.sh)
    # source those libs before this one, but a future caller (test
    # harness, new dispatcher) could violate that calling convention
    # and re-trigger the BD-130 BLOCKER failure mode under a different
    # symbol name. The probe converts the silent `command not found`
    # into an actionable error.
    local _dep
    for _dep in tracker_config_resolve_path tracker_config_auto_surface \
                tracker_schema_version_check tracker_config_get \
                provider_capabilities; do
        if ! declare -f "$_dep" >/dev/null 2>&1; then
            echo "ERROR: tracker-doctor: missing dependency: $_dep" >&2
            echo "MESSAGE: source tracker-config.sh, tracker-provider*.sh, template-version.sh, template-translations.sh before tracker-doctor.sh" >&2
            return 2
        fi
    done

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
            echo "  [WARN] mapping file is malformed JSON  → Run: pack tracker init"
            n_warn=$((n_warn + 1))
        fi

        # (c) per-entry pack-id shape
        local bad
        bad=$(jq -r 'keys[] | select(test("^(BD|TD)-[0-9]+$|^phase-[0-9]+(\\.[0-9]+)?$") | not)' \
            "$mapping_file" 2>/dev/null | head -n 5)
        if [[ -n "$bad" ]]; then
            echo "  [WARN] mapping has malformed pack-ids  → Run: pack tracker init"
            printf '         %s\n' $bad
            n_warn=$((n_warn + 1))
        else
            echo "  [OK]   all mapping pack-ids are well-shaped"
        fi
    else
        echo "  [INFO] no mapping file (expected before first forward run)"
    fi

    # (d) mirror / tree-regen freshness.
    #
    # BD-204 C-6 (C7b REPOINT): the pack monolith `pack-ops/BACKLOG.md`
    # is DELETED (BD-203 no-mirror SSOT). On the PACK surface the
    # per-entry tree under `/backlog/` IS the SSOT (flat-file mode) /
    # the regenerated mirror of tracker state (tracker mode); the
    # "mirror header / mtime" freshness concept maps to the tree's
    # regen-state via the generated `_toc.md` index (DP-4 regen cadence
    # marker). The PROJECT surface (`*)` branch) is UNTOUCHED (BD-207
    # owns the client tree repoint): clients still ship the
    # docs/project/BACKLOG.md monolith mirror.
    case "$surface" in
        pack)
            # Pack-surface: check the per-entry tree's regen index
            # (`/backlog/_toc.md`) mtime against last_forward_run. The
            # `_toc.md` is regenerated whenever the tree changes, so it
            # is the no-mirror analogue of the old monolith-header mtime.
            local toc_path
            toc_path="$repo_root/backlog/_toc.md"
            if [[ -f "$toc_path" ]]; then
                local toc_mtime last_forward
                # macOS BSD stat differs from GNU stat; use date -r as
                # the portable reader.
                toc_mtime=$(date -r "$toc_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
                if [[ -f "$cfg_path" ]]; then
                    last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "")
                fi
                if [[ -n "$toc_mtime" && -n "$last_forward" ]]; then
                    if [[ "$toc_mtime" > "$last_forward" || "$toc_mtime" == "$last_forward" ]]; then
                        echo "  [OK]   /backlog tree regen index is current (_toc.md mtime=$toc_mtime, last_forward=$last_forward)"
                    else
                        echo "  [WARN] /backlog tree regen index is older than last_forward_run  → Run: pack tracker init --forward"
                        n_warn=$((n_warn + 1))
                    fi
                else
                    echo "  [OK]   /backlog per-entry tree present (_toc.md index)"
                fi
            else
                echo "  [INFO] /backlog/_toc.md absent (flat-file pre-regen or scratch tree)"
            fi
            ;;
        *)
            local backlog_path=""
            if [[ -f "$repo_root/docs/project/BACKLOG.md" ]]; then
                backlog_path="$repo_root/docs/project/BACKLOG.md"
            elif [[ -f "$repo_root/BACKLOG.md" ]]; then
                backlog_path="$repo_root/BACKLOG.md"
            fi
            if [[ -n "$backlog_path" && -f "$backlog_path" ]]; then
                local first_line
                first_line=$(head -n 1 "$backlog_path")
                if [[ "$first_line" == "<!--" ]]; then
                    local mirror_mtime last_forward
                    # macOS BSD stat differs from GNU stat; use date -r as the
                    # portable reader.
                    mirror_mtime=$(date -r "$backlog_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
                    if [[ -f "$cfg_path" ]]; then
                        last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "")
                    fi
                    if [[ -n "$mirror_mtime" && -n "$last_forward" ]]; then
                        if [[ "$mirror_mtime" > "$last_forward" || "$mirror_mtime" == "$last_forward" ]]; then
                            echo "  [OK]   BACKLOG.md mirror is current (mtime=$mirror_mtime, last_forward=$last_forward)"
                        else
                            echo "  [WARN] BACKLOG.md mirror is older than last_forward_run  → Run: pack tracker mirror-rebuild"
                            n_warn=$((n_warn + 1))
                        fi
                    else
                        echo "  [OK]   BACKLOG.md has read-only mirror header"
                    fi
                else
                    echo "  [INFO] BACKLOG.md has no mirror header (flat-file mode or post-reverse state)"
                fi
            fi
            ;;
    esac

    # (f) issue-template dir presence. Both the `pack` and `client`
    # surfaces resolve to the same `.github/ISSUE_TEMPLATE` location
    # — client templates live alongside the client repo's own
    # `.github/` tree, not under `docs/pack/`.
    local tmpl_dir manifest_path
    tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE"
    # Resolve the translation manifest path per-surface. Pack repo
    # ships the manifest under maintenance-docs/v11-research/; in
    # client projects the manifest sits in .pack-tracker/ if and
    # when forward propagates one. v11.0 ships an empty manifest
    # under both surfaces so the freshness check is informational
    # until v11.1+ adds real transitions.
    case "$surface" in
        pack)
            manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
            ;;
        client)
            manifest_path="$repo_root/.pack-tracker/translations.yaml"
            ;;
        *)
            manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
            ;;
    esac
    if [[ -d "$tmpl_dir" ]]; then
        local n_yml
        n_yml=$(find "$tmpl_dir" -name '*.yml' | wc -l | tr -d ' ')
        echo "  [OK]   $tmpl_dir present ($n_yml templates)"

        # (e) template-version freshness — compare form-level
        # template_version against the translation manifest's latest
        # target. At v11.0 the manifest is empty so the form's
        # version is current by definition; the check becomes
        # meaningful when v11.1+ ships transitions. Use the BD-069
        # helpers if sourced; otherwise skip silently.
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
            else
                echo "  [INFO] template-version freshness: manifest absent at $manifest_path (skipped)"
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
                    # Demoted from WARN to INFO (N-1): the cache is
                    # auto-healed in this same invocation by the
                    # unconditional rewrite below, so a subsequent
                    # doctor run would emit [OK]. WARN-and-rc=1 here
                    # falsely failed CI/PM scripts gating on
                    # `pack tracker doctor` exit code despite there
                    # being no remaining user task. The schema-reshape
                    # signal is preserved in the message text so
                    # operators can still notice it in the report.
                    echo "  [INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)"
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
