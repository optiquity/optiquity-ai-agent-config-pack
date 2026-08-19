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
#       mcp-config-json, codex-config, codex-config-example, pm-chat,
#       custom-agent, pack-agent, custom-script, pack-script, generic.
#       The custom-agent / pack-agent classes cover BOTH the loose per-CLI
#       agent dirs (.claude/.codex/.gemini/agents/) AND the Antigravity
#       plugin bundle (.agents-plugin/*/agents/) — see the classifier legs
#       below (BD-221 corrected agent-migration model).
#   customization_preserve BASE OURS THEIRS REL DEST [CLASS]
#       Apply the rule for CLASS (auto-detected from REL if omitted).
#       Writes DEST. Records a finding via record_disposition.
#       Echoes the disposition token to stdout.
#   customization_findings_count
#       Echo the number of recorded findings.
#   customization_findings_tsv_path
#       Echo the path to the dispositions TSV.
#
# Disposition tokens (per IMPLEMENTATION-PLAN.md §2.5 BD-088, mirroring the
# v10 disposition vocabulary established in V10-MIGRATION-FIX-DESIGN.md
# Part 3.11):
#   unchanged-pack
#   pack-update-applied
#   merged-with-customization
#   customization-detected-needs-reconciliation
#   removed-by-design
#   project-only-file
#   project-deleted-pack-kept
#   removed-everywhere
#   unknown-classification        (catch-all; should never appear in
#                                  normal use; surfaced under the report
#                                  renderer's "Unhandled dispositions"
#                                  section so defects are visible)
#   library-error                 (reserved for future use; same surfacing
#                                  contract as unknown-classification)
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

# Long-form disposition token used in 6+ places; declare once to avoid
# silent typos that would slip through validate-pack and the report
# renderer's section dispatcher.
: "${_CP_DISP_NEEDS_RECONCILIATION:=customization-detected-needs-reconciliation}"

# BD-136: the `trinity` class delegates to the marker-aware two-regime merge
# engine. Source the sibling here so every caller of customization-preserve.sh
# gets it; guarded so a caller that already sourced it is not re-sourced. The
# engine only DEFINES functions (marker_preserve_trinity + _mp_* helpers), so
# source order relative to the _cp_* definitions below does not matter —
# marker_preserve_trinity resolves _cp_record / _cp_write_diff / _cp_strategy_text
# at call time.
if ! declare -F marker_preserve_trinity >/dev/null 2>&1; then
    _cp_this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$_cp_this_dir/marker-preserve.sh" ]]; then
        # shellcheck disable=SC1091
        . "$_cp_this_dir/marker-preserve.sh"
    else
        # NIT-2: fail loud at SOURCE time naming the missing sibling, rather than
        # degrading to a `command not found` at first `trinity` dispatch. The two
        # files are committed siblings shipped together; this is purely defensive.
        printf 'error: customization-preserve.sh requires the sibling BD-136 trinity merge engine, but it was not found at %s\n' \
            "$_cp_this_dir/marker-preserve.sh" >&2
        unset _cp_this_dir
        return 1
    fi
    unset _cp_this_dir
fi

# BD-287: the prose real-merge arm (generic/pm-chat) delegates to the
# deterministic 3-way merge primitive `tw_merge_file` (git merge-file -p
# --diff3). Source the sibling here so every caller of customization-preserve.sh
# gets it; guarded so a caller that already sourced it is not re-sourced. It
# only DEFINES `tw_merge_file`, so source order relative to the _cp_* definitions
# below does not matter. Mirrors the marker-preserve.sh source guard above.
if ! declare -F tw_merge_file >/dev/null 2>&1; then
    _cp_this_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$_cp_this_dir/three-way-merge.sh" ]]; then
        # shellcheck disable=SC1091
        . "$_cp_this_dir/three-way-merge.sh"
    else
        printf 'error: customization-preserve.sh requires the sibling BD-287 3-way merge primitive, but it was not found at %s\n' \
            "$_cp_this_dir/three-way-merge.sh" >&2
        unset _cp_this_dir
        return 1
    fi
    unset _cp_this_dir
fi

_cp_require_three_way() {
    if ! declare -F three_way_classify >/dev/null 2>&1; then
        printf 'error: customization-preserve.sh requires three-way.sh to be sourced first\n' >&2
        return 1
    fi
}

# BD-112: collision-safe per-file artifact name in the work directory.
#
# The previous scheme — `${rel//\//-}` then strip a leading `.` — collapsed
# distinct rels to the same name (e.g. `.claude/agents/foo.md` and
# `claude/agents/foo.md` both became `claude-agents-foo.md`), so the second
# write silently overwrote the first's diff and the truthful-report
# contract was violated.
#
# New scheme: `<sanitized>__<hash6>` where:
#   sanitized = rel with "/" replaced by "__" (leading "." preserved
#               verbatim; no info discarded)
#   hash6     = first 6 hex chars of `shasum -a 1` over the full rel
#
# Properties:
#   - Deterministic: same rel → same name across runs / hosts.
#   - Collision-resistant: two distinct rels with the same basename produce
#     distinct hash6 suffixes (and usually distinct sanitized prefixes too).
#   - Human-readable for debugging: the sanitized prefix shows the path
#     shape; the hash is a stable suffix.
#   - macOS bash 3.2 + BSD utils compatible (shasum -a 1 is present on
#     macOS by default and on Linux via Perl's shasum).
#
# Echoes the sanitized stem on stdout. Callers append `.three-way.diff`,
# `.merge-warnings.log`, etc.
_cp_flat_name() {
    [[ -n "${1:-}" ]] || { printf 'error: _cp_flat_name: REL required\n' >&2; return 1; }
    local rel="$1"
    local sanitized="${rel//\//__}"
    local hash6
    hash6=$(printf '%s' "$rel" | shasum -a 1 | cut -c1-6)
    printf '%s__%s\n' "$sanitized" "$hash6"
}

# ── Init ──────────────────────────────────────────────────────────────────

customization_preserve_init() {
    local state_dir="$1"
    local sidecar_suffix="${2:-.pre-update}"
    if [[ -z "$state_dir" ]]; then
        printf 'error: customization_preserve_init: STATE_DIR required\n' >&2
        return 1
    fi
    if [[ -z "${_CP_PACK_ROOT:-}" ]]; then
        printf 'error: customization_preserve_init: _CP_PACK_ROOT must be set before init\n' >&2
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
        # Antigravity workspace MCP config — mcpServers-shaped JSON, routed
        # through the SAME structured JSON key-merge as the Claude MCP example
        # (CLI-neutral class name: the file is portable mcpServers JSON, not
        # Antigravity-proprietary). BD-231 §8 (replaces the prior `generic`
        # text-merge fallthrough). Both the live workspace file and its
        # committed .example sibling route here.
        .agents/mcp_config.json|.agents/mcp_config.json.example)
            printf 'mcp-config-json\n' ;;
        .codex/config.toml.example)
            printf 'codex-config-example\n' ;;
        .codex/config.toml|.codex/requirements.toml)
            printf 'codex-config\n' ;;
        # PM-CHAT (post-relocation and legacy paths)
        docs/pack/PM-CHAT.md|project-template/docs/pack/PM-CHAT.md|PM-CHAT.md|project-template/PM-CHAT.md)
            printf 'pm-chat\n' ;;
        # Per-CLI agents. The `.gemini/agents/` legs are a legacy-READ
        # carve-out (ii): the migrator must classify the departing v10
        # `.gemini` shape so it can relocate it (mirrors detect.sh).
        .claude/agents/x-*|.codex/agents/x-*|.gemini/agents/x-*)
            printf 'custom-agent\n' ;;
        .claude/agents/*.md|.codex/agents/*.md|.gemini/agents/*.md)
            printf 'pack-agent\n' ;;
        # Antigravity agent plugin BUNDLE (BD-221 corrected agent-migration
        # model). Route the bundle through the SAME custom-agent / pack-agent
        # classes the loose dirs use, so a bundle pack agent is
        # replace-if-different and a bundle x- custom agent is preserved on a
        # pack bump. The `*` after .agents-plugin/ matches the plugin
        # namespace dir (e.g. optiquity-agents) without hard-coding it.
        #
        # INVARIANT (BD-221 OQ-2): the bundle namespace dir is SHARED — it
        # holds both pack-owned agents and client-owned customs. They are
        # told apart purely by the `x-` filename prefix, which the `x-` leg
        # below tests FIRST. Pack agents are NEVER named `x-` (the `x-`
        # prefix is reserved for client customs by convention), so a pack
        # agent can never be mis-classified as custom, and a client custom
        # can never be mis-classified as pack — the customs are protected
        # from replace-if-different.
        .agents-plugin/*/agents/x-*)
            printf 'custom-agent\n' ;;
        .agents-plugin/*/agents/*.md)
            printf 'pack-agent\n' ;;
        # Scripts: default is `pack-script` (3-way text dispatch). Callers
        # that know a script is project-added should pass class=custom-script
        # explicitly to bypass classification (preserved untouched). The
        # default routes pack-shipped scripts through 3-way merge.
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

# BD-287: stash the v10 BASE blob as a fixed companion `<DEST>.v10-base` next to
# the trinity `.v10-customized` sidecar, at the moment the sidecar sink runs
# (BASE is live in hand there). This is the THIRD merge input the
# `resolve-merge-conflicts` skill's Case-2 fold needs at skill-run time — a
# LOCAL file with no git/tag/pack-clone dependency
# (ARCHITECTURE-BD287-FINAL.md §2.2, decision B). Written ONLY for a REAL base
# (present, regular, non-empty — the same real-base test tw_merge_file's I3
# guard applies), a no-op otherwise (the BASE-absent --update path per I3). The
# `.v10-base` name does NOT match the `*.v10-customized` orphan-sidecar glob
# (checkpoint.sh `checkpoint_check_no_orphan_sidecars`), so it is invisible to
# Gate 2. Callable from marker-preserve.sh at call time (resolved like
# _cp_record). Returns 0 unconditionally (a missing stash is not an error).
_cp_stash_trinity_base() {
    local base="$1" dest="$2"
    if [[ -n "$base" && -f "$base" && -s "$base" ]]; then
        cp "$base" "${dest}.v10-base"
    fi
    return 0
}

# Map the 12 classifier tokens to the 8 canonical disposition tokens.
_cp_disposition_for() {
    case "$1" in
        unchanged-pack)                        printf 'unchanged-pack\n' ;;
        pack-update-applied|new-file-in-pack)  printf 'pack-update-applied\n' ;;
        merged-with-customization)             printf 'merged-with-customization\n' ;;
        real-merge-required|project-shadows-new-pack)
            printf '%s\n' "$_CP_DISP_NEEDS_RECONCILIATION" ;;
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
    # BD-112: collision-safe flat name (was `${rel//\//-}` with leading-dot
    # strip — would collide e.g. `.claude/agents/foo.md` vs
    # `claude/agents/foo.md`).
    local flat
    flat=$(_cp_flat_name "$rel")
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
            local diff_path merge_tmp merge_rc
            # BD-287 CLASS GATE (F1 — prose-scoped auto-merge). Only PROSE
            # classes (generic/pm-chat) get a real 3-way line-merge; scripts,
            # agents, and the markerless-trinity fallback keep TODAY's bare
            # sidecar (a git merge-file line-union of bash/YAML is textually
            # lossless yet BEHAVIOURALLY wrong, and the trinity is section-
            # sensitive — F6). The `merged-with-customization`/`merged` note on
            # a clean prose merge, plus the F8 DEST re-scan, mirror the
            # structured clean arm (ARCHITECTURE-BD287-FINAL.md §1/§2).
            case "$class" in
                generic|pm-chat)
                    # Merge into a TEMP so OURS stays intact for the sidecar /
                    # diff regardless of dest==ours (in-place). tw_merge_file
                    # writes OUT only on rc0/rc1, leaves it untouched on rc2.
                    merge_tmp=$(mktemp "${TMPDIR:-/tmp}/cp-prose-merge.XXXXXX") || merge_tmp=""
                    if [[ -z "$merge_tmp" ]]; then
                        # mktemp failure: fall back to today's bare sidecar (never
                        # skip a disposition — the truthful-report contract).
                        diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
                        cp "$ours" "$sidecar"
                        cp "$theirs" "$dest"
                        _cp_record "$disp" "$class" "$rel" "sidecar" "$sidecar" "$diff_path" \
                            "prose merge temp unavailable; fell back to sidecar"
                        return 0
                    fi
                    # OI-R1: capture rc WITHOUT tripping a `set -e` caller —
                    # tw_merge_file returns non-zero on its normal rc1/rc2 paths.
                    if tw_merge_file "$base" "$ours" "$theirs" "$merge_tmp" \
                        "your customization" "v10 baseline" "pack v11 update"; then
                        merge_rc=0
                    else
                        merge_rc=$?
                    fi
                    # OURS is still intact here (merge went to $merge_tmp).
                    diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
                    case "$merge_rc" in
                        0)
                            # F8 re-scan: a clean rc0 may still carry a residual
                            # --diff3 token (e.g. a marker left inside content);
                            # if ANY of the four tokens survive, DEMOTE to the
                            # rc-1 (markers-present) branch — keep the sidecar.
                            if grep -qE '^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)' "$merge_tmp"; then
                                cp "$ours" "$sidecar"
                                cp "$merge_tmp" "$dest"
                                _cp_record "$disp" "$class" "$rel" "merged" \
                                    "$sidecar" "$diff_path" \
                                    "prose 3-way merge left conflict markers (same-line overlap); resolve via the resolve-merge-conflicts skill"
                            else
                                # F2: a clean merge leaves NO orphan sidecar —
                                # sidecar column dash, mirrors the structured
                                # clean arm; the pre-migration backup covers OURS.
                                cp "$merge_tmp" "$dest"
                                _cp_record "merged-with-customization" "$class" "$rel" "merged" \
                                    "-" "$diff_path" \
                                    "prose 3-way merge clean (both edits applied, zero markers)"
                            fi
                            ;;
                        1)
                            # rc1 markers: DEST holds the marked merge; KEEP the
                            # sidecar; record needs-reconciliation + action
                            # `merged` (OI-7 — NO new disposition token).
                            cp "$ours" "$sidecar"
                            cp "$merge_tmp" "$dest"
                            _cp_record "$disp" "$class" "$rel" "merged" \
                                "$sidecar" "$diff_path" \
                                "prose 3-way merge left conflict markers (same-line overlap); resolve via the resolve-merge-conflicts skill"
                            ;;
                        *)
                            # rc2 unusable (no real BASE per I3, or a merge-file
                            # error): fall back to TODAY's bare sidecar body
                            # (unchanged behaviour). DEST is untouched by
                            # tw_merge_file on rc2, so set it explicitly.
                            cp "$ours" "$sidecar"
                            cp "$theirs" "$dest"
                            _cp_record "$disp" "$class" "$rel" "sidecar" "$sidecar" "$diff_path" "-"
                            ;;
                    esac
                    rm -f "$merge_tmp"
                    ;;
                trinity)
                    # BD-287: the MARKERLESS-trinity fallback path
                    # (marker_preserve_trinity delegates a zero-token trinity
                    # here). Keep TODAY's bare sidecar body AND stash the v10
                    # BASE for the skill's Case-2 fold (§2.2). NO line-merge (F6).
                    # CRITICAL ORDERING: write diff + sidecar BEFORE overwriting
                    # dest (dest may == ours in-place).
                    diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
                    cp "$ours" "$sidecar"
                    cp "$theirs" "$dest"
                    _cp_stash_trinity_base "$base" "$dest"
                    _cp_record "$disp" "$class" "$rel" "sidecar" "$sidecar" "$diff_path" "-"
                    ;;
                *)
                    # pack-script / pack-agent (and any other non-prose class):
                    # TODAY's bare sidecar body, UNCHANGED — executables/agents are
                    # never line-merged (F1); the client hand-reapplies.
                    # CRITICAL ORDERING: write diff + sidecar BEFORE overwriting
                    # dest. When dest == ours (in-place), `cp theirs dest` would
                    # overwrite ours; reversing preserves ours for diff/sidecar.
                    diff_path=$(_cp_write_diff "$base" "$ours" "$theirs" "$rel")
                    cp "$ours" "$sidecar"
                    cp "$theirs" "$dest"
                    _cp_record "$disp" "$class" "$rel" "sidecar" "$sidecar" "$diff_path" "-"
                    ;;
            esac
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
                json) helper="${_CP_PACK_ROOT}/scripts/merge-json.py" ;;
                toml) helper="${_CP_PACK_ROOT}/scripts/merge-toml.py" ;;
                *)
                    _cp_strategy_text "$class" "$base" "$ours" "$theirs" "$rel" "$dest"
                    return 0
                    ;;
            esac
            mkdir -p "$(dirname "$dest")" "$_CP_DIFFS_DIR"
            # BD-112: collision-safe flat name (was `${rel//\//-}` with
            # leading-dot strip — same defect as in _cp_write_diff).
            local flat
            flat=$(_cp_flat_name "$rel")
            local stderr_log="$_CP_DIFFS_DIR/${flat}.merge-warnings.log"
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
                    _cp_record "$_CP_DISP_NEEDS_RECONCILIATION" "$class" \
                        "$rel" "merged" "$sidecar" "$diff_path" \
                        "structured merge with reconciliation warnings (see $stderr_log)"
                    ;;
                *)
                    cp "$ours" "$sidecar"
                    cp "$theirs" "$dest"
                    _cp_record "$_CP_DISP_NEEDS_RECONCILIATION" "$class" \
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

# ── Public dispatch ───────────────────────────────────────────────────────

customization_preserve() {
    local base="$1" ours="$2" theirs="$3" rel="$4" dest="$5"
    local class="${6:-}"
    [[ -z "$class" ]] && class=$(customization_classify "$rel")

    # Early-return on the all-three-absent case. three_way_classify
    # returns rc=1 with "no-inputs" stdout for this case; under a `set -e`
    # caller the rc=1 from a `$(...)` capture would abort the parent
    # script before any strategy can record. Record removed-everywhere
    # directly so the truthful-report contract is preserved without
    # propagating the rc=1 to the caller.
    if [[ ! -e "$base" && ! -e "$ours" && ! -e "$theirs" ]]; then
        _cp_record "removed-everywhere" "$class" "$rel" "none" "-" "-" "-"
        return 0
    fi

    case "$class" in
        trinity)
            # BD-136: trinity delegates to the marker-aware two-regime merge
            # engine (marker-preserve.sh). A markerless trinity falls back to
            # the legacy byte-unaware 3-way text path INSIDE that engine (so
            # legacy projects + Check 25 stay green). The signature is
            # unchanged — BASE was always the first positional.
            marker_preserve_trinity "$base" "$ours" "$theirs" "$rel" "$dest"
            ;;
        pack-agent|pack-script|pm-chat|generic)
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
        claude-settings|claude-mcp-example|mcp-config-json)
            _cp_strategy_structured "$class" "$base" "$ours" "$theirs" "$rel" "$dest" json
            ;;
        codex-config|codex-config-example)
            _cp_strategy_structured "$class" "$base" "$ours" "$theirs" "$rel" "$dest" toml
            ;;
        *)
            # Unknown class: fall back to generic 3-way text.
            _cp_strategy_text "generic" "$base" "$ours" "$theirs" "$rel" "$dest"
            ;;
    esac
}
