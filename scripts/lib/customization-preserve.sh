# scripts/lib/customization-preserve.sh — per-file customization-preservation
# orchestrator for v11 migration paths (BD-088, fixes BD-059).
#
# Sourced by `migrate-v10-to-v11.sh` (BD-085) and by `init-project.sh --update`
# (BD-080) so all v11 migration paths share one customization-preservation
# contract. Do NOT add a shebang — this file is sourced.
#
# Contract:
#   Given BASE (previous pack baseline), OURS (project current), THEIRS
#   (new pack template), and a destination path, dispatch to the per-class
#   preservation rule, write the result, and record a structured finding.
#   Every file is accounted for. The caller renders a truthful report from
#   the recorded findings via `customization-report.sh`.
#
# Public API:
#   customization_preserve_init STATE_DIR [SIDECAR_SUFFIX]
#       Reset state. STATE_DIR is created; dispositions.tsv + diffs/ live
#       inside. SIDECAR_SUFFIX defaults to ".pre-update".
#   customization_classify REL_PATH
#       Echo one of: trinity, claude-settings, claude-mcp-example,
#       codex-config, codex-config-example, gemini-env, pm-chat,
#       custom-agent, pack-agent, custom-script, pack-script, generic.
#   customization_preserve BASE OURS THEIRS REL DEST [CLASS]
#       Apply the rule for CLASS (auto-detected from REL if omitted).
#       Writes DEST. Records a finding via record_disposition.
#       Echoes the disposition token to stdout.
#   customization_findings_count
#       Echo the number of recorded findings.
#   customization_findings_tsv_path
#       Echo the path to the dispositions TSV.
#
# Disposition tokens (canonical 6 per V10-MIGRATION-FIX-DESIGN.md Part 3.11
# plus v11 additions):
#   unchanged-pack
#   pack-update-applied
#   merged-with-customization
#   customization-detected-needs-reconciliation
#   removed-by-design
#   project-only-file
#   project-deleted-pack-kept
#   removed-everywhere
#
# Action verbs recorded alongside (for the truthful report):
#   none, copied, merged, sidecar, removed, preserved
#
# Globals (set by customization_preserve_init):
#   _CP_STATE_DIR             — state directory (must be writable)
#   _CP_SIDECAR_SUFFIX        — sidecar suffix, e.g. ".pre-update"
#   _CP_DISPOSITIONS_FILE     — STATE_DIR/dispositions.tsv
#   _CP_DIFFS_DIR             — STATE_DIR/diffs/
#   _CP_FINDINGS_COUNT        — count of recorded findings

# Assume the caller has already sourced lib/three-way.sh (provides
# three_way_classify). Validate at first call instead of sourcing here so
# callers control source order.

_cp_require_three_way() {
    if ! declare -F three_way_classify >/dev/null 2>&1; then
        printf 'error: customization-preserve.sh requires three-way.sh to be sourced first\n' >&2
        return 1
    fi
}

# ── Init ──────────────────────────────────────────────────────────────────

customization_preserve_init() {
    local state_dir="$1"
    local sidecar_suffix="${2:-.pre-update}"
    if [[ -z "$state_dir" ]]; then
        printf 'error: customization_preserve_init: STATE_DIR required\n' >&2
        return 1
    fi
    _cp_require_three_way || return 1
    mkdir -p "$state_dir/diffs"
    _CP_STATE_DIR="$state_dir"
    _CP_SIDECAR_SUFFIX="$sidecar_suffix"
    _CP_DISPOSITIONS_FILE="$state_dir/dispositions.tsv"
    _CP_DIFFS_DIR="$state_dir/diffs"
    _CP_FINDINGS_COUNT=0
    printf '# disposition\tclass\trel_path\taction\tsidecar\tdiff\tnotes\n' \
        > "$_CP_DISPOSITIONS_FILE"
}

customization_findings_count() {
    printf '%s\n' "${_CP_FINDINGS_COUNT:-0}"
}

customization_findings_tsv_path() {
    printf '%s\n' "${_CP_DISPOSITIONS_FILE:-}"
}

# ── Classification ────────────────────────────────────────────────────────
#
# Maps a project-relative path to a file class. Class drives the
# preservation strategy. Order matters: more specific patterns first.

customization_classify() {
    local rel="$1"
    case "$rel" in
        # Trinity files (project root only)
        CLAUDE.md|AGENTS.md|GEMINI.md)
            printf 'trinity\n' ;;
        # Structured configs
        .claude/settings.json|.claude/settings.json.example)
            printf 'claude-settings\n' ;;
        .mcp.json.example|.mcp.json)
            printf 'claude-mcp-example\n' ;;
        .codex/config.toml.example)
            printf 'codex-config-example\n' ;;
        .codex/config.toml|.codex/requirements.toml)
            printf 'codex-config\n' ;;
        .gemini/.env|.gemini/.env.example)
            printf 'gemini-env\n' ;;
        # PM-CHAT (post-relocation and legacy paths)
        docs/pack/PM-CHAT.md|project-template/docs/pack/PM-CHAT.md|PM-CHAT.md|project-template/PM-CHAT.md)
            printf 'pm-chat\n' ;;
        # Per-CLI agents
        .claude/agents/x-*|.codex/agents/x-*|.gemini/agents/x-*)
            printf 'custom-agent\n' ;;
        .claude/agents/*.md|.codex/agents/*.md|.gemini/agents/*.md)
            printf 'pack-agent\n' ;;
        # Scripts: caller passes class explicitly when known (pack-script vs
        # custom-script depends on whether the file was shipped by the pack).
        # Default: treat as generic until the caller overrides. Callers that
        # know the pack-shipped script list pass class=pack-script directly.
        scripts/*)
            printf 'pack-script\n' ;;
        *)
            printf 'generic\n' ;;
    esac
}

# ── Disposition recording ─────────────────────────────────────────────────

_cp_record() {
    local disp="$1" class="$2" rel="$3" action="$4"
    local sidecar="${5:--}" diff="${6:--}" notes="${7:--}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$disp" "$class" "$rel" "$action" "$sidecar" "$diff" "$notes" \
        >> "$_CP_DISPOSITIONS_FILE"
    _CP_FINDINGS_COUNT=$((_CP_FINDINGS_COUNT + 1))
}

# Map the 12 classifier tokens to the 8 canonical disposition tokens.
_cp_disposition_for() {
    case "$1" in
        unchanged-pack)                        printf 'unchanged-pack\n' ;;
        pack-update-applied|new-file-in-pack)  printf 'pack-update-applied\n' ;;
        merged-with-customization)             printf 'merged-with-customization\n' ;;
        real-merge-required|project-shadows-new-pack)
            printf 'customization-detected-needs-reconciliation\n' ;;
        removed-by-pack-clean|removed-by-pack-customized)
            printf 'removed-by-design\n' ;;
        project-only-file)                     printf 'project-only-file\n' ;;
        project-deleted-pack-kept)             printf 'project-deleted-pack-kept\n' ;;
        removed-everywhere)                    printf 'removed-everywhere\n' ;;
        *)                                     printf '%s\n' "$1" ;;
    esac
}

# Write a structured three-way diff. Echo the path written.
_cp_write_diff() {
    local base="$1" ours="$2" theirs="$3" rel="$4"
    local flat="${rel//\//-}"
    flat="${flat#.}"
    local out="$_CP_DIFFS_DIR/${flat}.three-way.diff"
    {
        echo "# Three-way diff for $rel"
        echo "# BASE   = previous pack baseline"
        echo "# OURS   = project pre-update"
        echo "# THEIRS = new pack template"
        echo
        echo "## BASE → OURS (project edits since baseline)"
        echo
        if [[ -n "$base" && -f "$base" && -n "$ours" && -f "$ours" ]]; then
            diff -u "$base" "$ours" || true
        else
            echo "(one or both inputs absent: base=${base:-<none>} ours=${ours:-<none>})"
        fi
        echo
        echo "## BASE → THEIRS (pack edits across baseline)"
        echo
        if [[ -n "$base" && -f "$base" && -n "$theirs" && -f "$theirs" ]]; then
            diff -u "$base" "$theirs" || true
        else
            echo "(one or both inputs absent: base=${base:-<none>} theirs=${theirs:-<none>})"
        fi
    } > "$out"
    printf '%s\n' "$out"
}

# ── Per-class preservation strategies ─────────────────────────────────────
#
# Each strategy is a private function: _cp_strategy_<class>. All take the
# same signature: BASE OURS THEIRS REL DEST. All return 0; they record one
# disposition entry. Strategies own writing DEST and any sidecar files.

# Strategy: 3-way text dispatch (used by trinity, pack-agent, pack-script,
# pm-chat fallback, generic). Mirrors migrate-v9-to-v10.sh dispatch_text_file
# but with the v11 sidecar suffix.
_cp_strategy_text() {
    local class="$1" base="$2" ours="$3" theirs="$4" rel="$5" dest="$6"
    local classification disp
    classification=$(three_way_classify "$base" "$ours" "$theirs")
    disp=$(_cp_disposition_for "$classification")

    case "$classification" in
        unchanged-pack)
            _cp_record "$disp" "$class" "$rel" "none" "-" "-" "-"
            ;;
        pack-update-applied|new-file-in-pack)
            mkdir -p "$(dirname "$dest")"
            cp "$theirs" "$dest"
            _cp_record "$disp" "$class" "$rel" "copied" "-" "-" "-"
            ;;
        merged-with-customization)
            _cp_record "$disp" "$class" "$rel" "preserved" "-" "-" "kept project edits"
            ;;
        real-merge-required|project-shadows-new-pack)
            mkdir -p "$(dirname "$dest")"
            local sidecar="${dest}${_CP_SIDECAR_SUFFIX}"
            local diff_path
            # CRITICAL ORDERING: write diff + sidecar BEFORE overwriting
            # dest. When dest == ours (in-place), `cp theirs dest` would
            # overwrite ours; reversing preserves ours for diff/sidecar.
            diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
            cp "$ours" "$sidecar"
            cp "$theirs" "$dest"
            _cp_record "$disp" "$class" "$rel" "sidecar" "$sidecar" "$diff_path" "-"
            ;;
        removed-by-pack-clean)
            [[ -f "$dest" ]] && rm "$dest"
            _cp_record "$disp" "$class" "$rel" "removed" "-" "-" "pack retired (no project edits)"
            ;;
        removed-by-pack-customized)
            local sidecar="${dest}${_CP_SIDECAR_SUFFIX}"
            cp "$ours" "$sidecar"
            [[ -f "$dest" ]] && rm "$dest"
            _cp_record "$disp" "$class" "$rel" "removed" "$sidecar" "-" \
                "pack retired; project edits preserved in sidecar"
            ;;
        project-only-file)
            _cp_record "$disp" "$class" "$rel" "preserved" "-" "-" "project-only"
            ;;
        project-deleted-pack-kept)
            _cp_record "$disp" "$class" "$rel" "none" "-" "-" \
                "honoring project deletion (pack still ships)"
            ;;
        removed-everywhere)
            # Silent no-op recorded for completeness (truthful report).
            _cp_record "$disp" "$class" "$rel" "none" "-" "-" "-"
            ;;
        *)
            _cp_record "unknown-classification" "$class" "$rel" "none" "-" "-" \
                "classification=$classification"
            ;;
    esac
}

# Strategy: structured-config dispatch (JSON / TOML). Mirrors
# migrate-v9-to-v10.sh dispatch_structured_config.
_cp_strategy_structured() {
    local class="$1" base="$2" ours="$3" theirs="$4" rel="$5" dest="$6" fmt="$7"
    local classification disp
    classification=$(three_way_classify "$base" "$ours" "$theirs")
    disp=$(_cp_disposition_for "$classification")

    case "$classification" in
        unchanged-pack)
            _cp_record "$disp" "$class" "$rel" "none" "-" "-" "-"
            return 0
            ;;
        merged-with-customization)
            _cp_record "$disp" "$class" "$rel" "preserved" "-" "-" \
                "no pack update; project edits kept"
            return 0
            ;;
        pack-update-applied|new-file-in-pack)
            mkdir -p "$(dirname "$dest")"
            cp "$theirs" "$dest"
            _cp_record "$disp" "$class" "$rel" "copied" "-" "-" "-"
            return 0
            ;;
        real-merge-required|project-shadows-new-pack)
            local helper
            case "$fmt" in
                json) helper="${_CP_PACK_ROOT:?_CP_PACK_ROOT must be set}/scripts/merge-json.py" ;;
                toml) helper="${_CP_PACK_ROOT:?_CP_PACK_ROOT must be set}/scripts/merge-toml.py" ;;
                *)
                    _cp_strategy_text "$class" "$base" "$ours" "$theirs" "$rel" "$dest"
                    return 0
                    ;;
            esac
            mkdir -p "$(dirname "$dest")" "$_CP_DIFFS_DIR"
            local flat="${rel//\//-}"
            local stderr_log="$_CP_DIFFS_DIR/${flat#.}.merge-warnings.log"
            local merged_tmp
            merged_tmp=$(mktemp)
            local rc=0
            python3 "$helper" "${base:-}" "$ours" "$theirs" --output "$merged_tmp" \
                2> "$stderr_log" || rc=$?
            local diff_path
            diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")

            local sidecar="${dest}${_CP_SIDECAR_SUFFIX}"
            case "$rc" in
                0)
                    cp "$merged_tmp" "$dest"
                    _cp_record "merged-with-customization" "$class" "$rel" "merged" \
                        "-" "$diff_path" "structured key-level merge clean"
                    rm -f "$stderr_log"
                    ;;
                2)
                    cp "$ours" "$sidecar"
                    cp "$merged_tmp" "$dest"
                    _cp_record "customization-detected-needs-reconciliation" "$class" \
                        "$rel" "merged" "$sidecar" "$diff_path" \
                        "structured merge with reconciliation warnings (see $stderr_log)"
                    ;;
                *)
                    cp "$ours" "$sidecar"
                    cp "$theirs" "$dest"
                    _cp_record "customization-detected-needs-reconciliation" "$class" \
                        "$rel" "sidecar" "$sidecar" "$diff_path" \
                        "structured merge errored (rc=$rc); fell back to sidecar (see $stderr_log)"
                    ;;
            esac
            rm -f "$merged_tmp"
            return 0
            ;;
        removed-by-pack-clean|removed-by-pack-customized|removed-everywhere|project-deleted-pack-kept|project-only-file)
            _cp_strategy_text "$class" "$base" "$ours" "$theirs" "$rel" "$dest"
            return 0
            ;;
        *)
            _cp_record "unknown-classification" "$class" "$rel" "none" "-" "-" \
                "classification=$classification"
            return 0
            ;;
    esac
}

# Strategy: gemini-env (KEY=VALUE line preservation). Per BD-088, preserve
# AGENT_CAPABILITIES and any project-set keys; adopt new pack-shipped keys.
# Algorithm: union of keys; on conflict, project wins (per BD-059 lesson).
_cp_strategy_gemini_env() {
    local class="$1" base="$2" ours="$3" theirs="$4" rel="$5" dest="$6"
    if [[ ! -e "$ours" && -e "$theirs" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$theirs" "$dest"
        _cp_record "pack-update-applied" "$class" "$rel" "copied" "-" "-" "new pack file"
        return 0
    fi
    if [[ -e "$ours" && ! -e "$theirs" ]]; then
        _cp_record "project-only-file" "$class" "$rel" "preserved" "-" "-" \
            "project-only env file"
        return 0
    fi
    if [[ ! -e "$ours" && ! -e "$theirs" ]]; then
        _cp_record "removed-everywhere" "$class" "$rel" "none" "-" "-" "-"
        return 0
    fi
    if cmp -s "$ours" "$theirs"; then
        _cp_record "unchanged-pack" "$class" "$rel" "none" "-" "-" "-"
        return 0
    fi
    # Both present and differ: union with ours-wins-on-conflict.
    local merged_tmp
    merged_tmp=$(mktemp)
    awk -v ours_file="$ours" '
        BEGIN {
            while ((getline line < ours_file) > 0) {
                if (line ~ /^[[:space:]]*(#|$)/) { ours_lines[++on] = line; continue }
                if (match(line, /^[A-Za-z_][A-Za-z0-9_]*=/)) {
                    key = substr(line, 1, RLENGTH - 1)
                    ours_kv[key] = line
                    ours_order[++ok] = key
                } else { ours_lines[++on] = line }
            }
            close(ours_file)
        }
        # Now iterate THEIRS (current input) to add pack-only keys.
        /^[[:space:]]*(#|$)/ { next }
        match($0, /^[A-Za-z_][A-Za-z0-9_]*=/) {
            key = substr($0, 1, RLENGTH - 1)
            if (!(key in ours_kv)) {
                pack_only_kv[key] = $0
                pack_only_order[++po] = key
            }
        }
        END {
            # Print ours preserved order first, then pack-only additions.
            for (i = 1; i <= ok; i++) print ours_kv[ours_order[i]]
            if (po > 0) {
                print ""
                print "# Added by v11 pack update"
                for (i = 1; i <= po; i++) print pack_only_kv[pack_only_order[i]]
            }
        }
    ' "$theirs" > "$merged_tmp"

    mkdir -p "$(dirname "$dest")"
    if cmp -s "$ours" "$merged_tmp"; then
        # Ours already has all pack keys (or pack added nothing new).
        _cp_record "merged-with-customization" "$class" "$rel" "preserved" \
            "-" "-" "no pack additions; project edits kept"
    else
        cp "$merged_tmp" "$dest"
        local diff_path
        diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
        _cp_record "merged-with-customization" "$class" "$rel" "merged" \
            "-" "$diff_path" "env-file key-union; project values preserved"
    fi
    rm -f "$merged_tmp"
}

# ── Public dispatch ───────────────────────────────────────────────────────

customization_preserve() {
    local base="$1" ours="$2" theirs="$3" rel="$4" dest="$5"
    local class="${6:-}"
    [[ -z "$class" ]] && class=$(customization_classify "$rel")

    case "$class" in
        trinity|pack-agent|pack-script|pm-chat|generic)
            _cp_strategy_text "$class" "$base" "$ours" "$theirs" "$rel" "$dest"
            ;;
        custom-agent|custom-script)
            # Project-owned: never overwrite. If it exists in OURS, preserve.
            if [[ -e "$ours" ]]; then
                _cp_record "project-only-file" "$class" "$rel" "preserved" "-" "-" \
                    "project-owned (${class})"
            else
                _cp_record "removed-everywhere" "$class" "$rel" "none" "-" "-" "-"
            fi
            ;;
        claude-settings|claude-mcp-example)
            _cp_strategy_structured "$class" "$base" "$ours" "$theirs" "$rel" "$dest" json
            ;;
        codex-config|codex-config-example)
            _cp_strategy_structured "$class" "$base" "$ours" "$theirs" "$rel" "$dest" toml
            ;;
        gemini-env)
            _cp_strategy_gemini_env "$class" "$base" "$ours" "$theirs" "$rel" "$dest"
            ;;
        *)
            # Unknown class: fall back to generic 3-way text.
            _cp_strategy_text "generic" "$base" "$ours" "$theirs" "$rel" "$dest"
            ;;
    esac
}
