# scripts/lib/migrator-skills.sh — BD-147 skill-rename / skill-split adapter
# for the BD-119 migrator framework family.
#
# Sibling library to `migrator-core.sh`, `migrator-stages.sh`, and
# `migrator-manifest.sh`. Per-version migrator adapters
# (`scripts/migrate-vN-to-vM.sh`) source this file and call
# `migrator_skill_rename` to perform client-side skill renames or splits
# without open-coding the per-line scan + disambiguation + advisory
# pattern that the v10→v11 BD-035 split helper proved out.
#
# Architecture: maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md §6.5
#               maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md §3.1 (sibling-lib pattern)
# Plan:         maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md §2 Batch 8 + §7.2
#
# Public API (frozen at BD-147 ship):
#   migrator_skill_rename <old-skill> <new-skill> [<advisory-path>]
#       Replace bare-token references to <old-skill> with <new-skill>
#       across a fixed list of project files. Optionally writes an
#       advisory file when ambiguous sites are found.
#
#       Required env (read, not declared):
#         _MIGRATOR_TARGET     — project root being migrated.
#         _MIGRATOR_STATE_DIR  — migrator state dir; default advisory location.
#         MIGRATOR_SKILLS_FILES (optional) — newline-separated list of
#           project-root-relative files to scan. Defaults to the four
#           files BD-035 covered: PLATFORM-SKILLS.md + the trinity.
#         MIGRATOR_SKILLS_SERVER_SIGNAL_PAT (optional) — extended-regex of
#           server-tier signals used by split-disambiguation. Used only
#           when caller has set MIGRATOR_SKILLS_SPLIT_TO_SERVER /
#           MIGRATOR_SKILLS_SPLIT_TO_DATA. Defaults to the BD-035 set:
#           grpc-patterns|deployment-python|Python server|python-server|
#           gRPC servicer|grpc\.aio|interceptor.
#         MIGRATOR_SKILLS_DATA_SIGNAL_PAT (optional) — extended-regex of
#           data-tier signals. Defaults to the BD-035 set:
#           repository|N\+1|Pydantic|data ?/ ?I/O|data and I/O|ML inference.
#         MIGRATOR_SKILLS_SPLIT_TO_SERVER (optional) — when set, the rename
#           is interpreted as a SPLIT: same-line presence of the server
#           token resolves to this name; signals trigger this name when
#           unambiguous. Mutually exclusive with the bare 2-arg rename.
#         MIGRATOR_SKILLS_SPLIT_TO_DATA (optional) — split-mode data half.
#         MIGRATOR_SKILLS_ADVISORY_INTRO (optional) — multi-line preamble
#           written at the top of the advisory when the first ambiguous
#           site is found. Defaults to a generic BD-147 preamble; the
#           v10→v11 caller supplies the BD-035 preamble for byte-equivalence.
#
#       In SIMPLE rename mode (no split-to-* env vars): every bare-token
#       hit on `<old-skill>` is rewritten to `<new-skill>` unconditionally.
#       Pre-existing post-rename tokens are left alone.
#
#       In SPLIT mode (caller sets MIGRATOR_SKILLS_SPLIT_TO_SERVER and
#       MIGRATOR_SKILLS_SPLIT_TO_DATA): the per-line disambiguation rules
#       from BD-035 S5b apply (lines 366-378 of the pre-extraction
#       migrate-v10-to-v11.sh):
#         R1. Line already contains <split-to-server> token  → rewrite
#             stale <old-skill> to <split-to-server>.
#         R2. Line already contains <split-to-data> token    → rewrite
#             stale <old-skill> to <split-to-data>.
#         R3. Line contains a server-signal AND no data-signal → rewrite
#             to <split-to-server>.
#         R4. Line contains a data-signal AND no server-signal → rewrite
#             to <split-to-data>.
#         R5. Otherwise → record an ambiguous-rename advisory entry;
#             leave the file untouched at this site.
#
#       <advisory-path> (optional 3rd positional arg) overrides the
#       default of `$_MIGRATOR_STATE_DIR/<old-skill>-rename.advisory`.
#
#       Output (stdout): per-file `info` lines for files scanned + a
#       summary `info` line for total rewrites + ambiguous count. Uses
#       the framework's `info` / `say` / `fail_stage` helpers (must be
#       sourced via migrator-core.sh first).
#
#   migrator_skill_split <old-skill> <new-server-skill> <new-data-skill> [<advisory-path>]
#       Forward-declared one-to-many split helper. Body is currently a
#       thin wrapper around `migrator_skill_rename` in split mode using
#       the BD-035 default signal patterns. Reserved for future
#       enhancement (additional split classes, more than two destination
#       skills); for v11.0 BD-035 only needs the bare rename API used in
#       split mode by v10→v11's S5b.
#
# macOS bash 3.2 + BSD utils only — no GNU-only flags, no associative
# arrays, no `&>`. The file is sourced (no shebang). All public-API
# function names are stable; internal helpers use the `_migrator_skills_`
# prefix so they cannot collide with adapter-internal names.

# ── Defaults ───────────────────────────────────────────────────────────────

# Default file list — matches the BD-035 S5b coverage. Newline-separated
# string; not an array, so callers can override via environment without
# having to re-quote bash array syntax. Project-root-relative paths.
_MIGRATOR_SKILLS_DEFAULT_FILES='docs/pack/PLATFORM-SKILLS.md
CLAUDE.md
AGENTS.md
GEMINI.md'

# Default disambiguation signal patterns — verbatim from BD-035 S5b.
_MIGRATOR_SKILLS_DEFAULT_SERVER_SIGNAL='grpc-patterns|deployment-python|Python server|python-server|gRPC servicer|grpc\.aio|interceptor'
_MIGRATOR_SKILLS_DEFAULT_DATA_SIGNAL='repository|N\+1|Pydantic|data ?/ ?I/O|data and I/O|ML inference'

# ── Internal helpers ───────────────────────────────────────────────────────

# Echo the default BD-035 advisory preamble. Keeps byte-for-byte parity
# with the pre-extraction inline helper output. The v10→v11 caller does
# NOT need to override this; the default IS the BD-035 preamble.
_migrator_skills_default_advisory_intro() {
    cat <<EOF
# python-architecture skill-rename advisory (split)
#
# The v10.x \`python-architecture\` skill was split in v11 into
# \`python-server-architecture\` and \`python-data-architecture\`.
# The migrator could not unambiguously rewrite the references
# below. Inspect each line and rename to the appropriate
# post-split skill name by hand.
#
# Format: <file>:<line>: <text>

EOF
}

# Echo a generic advisory preamble used when the caller is performing a
# non-BD-035 rename or split. Identifies the old/new tokens for the
# operator without baking in v10→v11-specific wording.
_migrator_skills_generic_advisory_intro() {
    local old="$1" new_server="$2" new_data="$3" new_simple="$4"
    if [[ -n "$new_simple" ]]; then
        cat <<EOF
# ${old} skill-rename advisory
#
# The \`${old}\` skill was renamed to \`${new_simple}\`.
# The migrator could not unambiguously rewrite the references
# below. Inspect each line and rename by hand.
#
# Format: <file>:<line>: <text>

EOF
    else
        cat <<EOF
# ${old} skill-rename advisory
#
# The \`${old}\` skill was split into \`${new_server}\` and
# \`${new_data}\`. The migrator could not unambiguously rewrite
# the references below. Inspect each line and rename to the
# appropriate post-split skill name by hand.
#
# Format: <file>:<line>: <text>

EOF
    fi
}

# Build the bare-token sed substitution that rewrites <old> to <new>
# on a single line, anchored to non-token-continuation boundaries so
# substring matches like `python-server-architecture` (which contains
# `python-architecture` as a substring) are not touched.
#
# Echoes the substitution program. Caller pipes a single line through
# `sed "$program"`.
_migrator_skills_build_sed_program() {
    local old="$1" new="$2"
    # Four anchored variants: (a) middle, (b) line-start, (c) line-end,
    # (d) whole-line. Verbatim shape of the BD-035 S5b sed program; only
    # the token names are parameterized.
    printf 's/\\([^-]\\)%s\\([^-]\\)/\\1%s\\2/g; s/^%s\\([^-]\\)/%s\\1/g; s/\\([^-]\\)%s$/\\1%s/g; s/^%s$/%s/g' \
        "$old" "$new" \
        "$old" "$new" \
        "$old" "$new" \
        "$old" "$new"
}

# ── Public API ─────────────────────────────────────────────────────────────

# migrator_skill_rename <old-skill> <new-skill> [<advisory-path>]
#
# Per-line scan of the file list (default or override) for bare-token
# references to <old-skill>. Rewrites in place when unambiguous (rules
# vary by mode — see header). Records ambiguous sites in an advisory.
#
# Mode is selected implicitly:
#   - SIMPLE rename: caller passes <new-skill> as positional arg 2 AND
#     does NOT export MIGRATOR_SKILLS_SPLIT_TO_SERVER / *_DATA. Every
#     bare-token hit rewrites unconditionally.
#   - SPLIT rename: caller exports MIGRATOR_SKILLS_SPLIT_TO_SERVER and
#     MIGRATOR_SKILLS_SPLIT_TO_DATA. Positional arg 2 is required by the
#     signature but ignored in split mode (callers should pass the
#     server name for documentation).
#
# Returns 0 on success. Calls fail_stage on I/O errors.
migrator_skill_rename() {
    local old="${1:-}"
    local new="${2:-}"
    local advisory="${3:-}"

    if [[ -z "$old" || -z "$new" ]]; then
        printf 'migrator_skill_rename: usage: migrator_skill_rename <old> <new> [<advisory-path>]\n' >&2
        return 2
    fi

    local split_to_server="${MIGRATOR_SKILLS_SPLIT_TO_SERVER:-}"
    local split_to_data="${MIGRATOR_SKILLS_SPLIT_TO_DATA:-}"
    local mode="simple"
    if [[ -n "$split_to_server" && -n "$split_to_data" ]]; then
        mode="split"
    elif [[ -n "$split_to_server" || -n "$split_to_data" ]]; then
        printf 'migrator_skill_rename: split mode requires BOTH MIGRATOR_SKILLS_SPLIT_TO_SERVER and MIGRATOR_SKILLS_SPLIT_TO_DATA\n' >&2
        return 2
    fi

    local target_root="${_MIGRATOR_TARGET:-}"
    local state_dir="${_MIGRATOR_STATE_DIR:-}"
    if [[ -z "$target_root" ]]; then
        printf 'migrator_skill_rename: _MIGRATOR_TARGET must be set by the framework\n' >&2
        return 2
    fi
    if [[ -z "$advisory" ]]; then
        if [[ -z "$state_dir" ]]; then
            printf 'migrator_skill_rename: _MIGRATOR_STATE_DIR must be set when no advisory path is supplied\n' >&2
            return 2
        fi
        advisory="$state_dir/${old}-rename.advisory"
    fi

    # File list: env override (newline-separated) or default.
    local files_str="${MIGRATOR_SKILLS_FILES:-$_MIGRATOR_SKILLS_DEFAULT_FILES}"

    # Signal patterns (split mode only).
    local server_sig="${MIGRATOR_SKILLS_SERVER_SIGNAL_PAT:-$_MIGRATOR_SKILLS_DEFAULT_SERVER_SIGNAL}"
    local data_sig="${MIGRATOR_SKILLS_DATA_SIGNAL_PAT:-$_MIGRATOR_SKILLS_DEFAULT_DATA_SIGNAL}"

    # Advisory preamble — caller-supplied or default. The BD-035
    # caller relies on the default-default (the BD-035 preamble) when
    # old=python-architecture; other callers get a generic preamble.
    local advisory_intro="${MIGRATOR_SKILLS_ADVISORY_INTRO:-}"

    local rewrites=0
    local ambiguous=0
    local rel f tmp linenum line

    local IFS_SAVED="$IFS"
    IFS='
'
    local files_arr
    # shellcheck disable=SC2206
    files_arr=( $files_str )
    IFS="$IFS_SAVED"

    for rel in "${files_arr[@]}"; do
        [[ -z "$rel" ]] && continue
        f="$target_root/$rel"
        [[ -f "$f" ]] || continue
        # Cheap fast path: skip if the file has no stale references at all.
        grep -q "\\b${old}\\b" "$f" || continue

        tmp=$(mktemp -t pack-skill-rename.XXXXXX) || {
            if declare -F fail_stage >/dev/null; then
                fail_stage S5 "migrator_skill_rename: mktemp failed for $rel"
            else
                printf 'migrator_skill_rename: mktemp failed for %s\n' "$rel" >&2
                return 1
            fi
        }
        linenum=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            linenum=$((linenum + 1))
            if [[ "$line" != *"${old}"* ]]; then
                printf '%s\n' "$line" >>"$tmp"
                continue
            fi
            # Exclude lines whose only `${old}` substring is part of a
            # longer hyphenated identifier (token-boundary check).
            if ! printf '%s' "$line" | grep -qE "(^|[^-])${old}([^-]|\$)"; then
                printf '%s\n' "$line" >>"$tmp"
                continue
            fi

            local new_token=""
            if [[ "$mode" == "simple" ]]; then
                new_token="$new"
            else
                # SPLIT mode — apply the BD-035 5-rule disambiguation.
                local has_server=0 has_data=0
                [[ "$line" == *"${split_to_server}"* ]] && has_server=1
                [[ "$line" == *"${split_to_data}"* ]] && has_data=1
                if (( has_server == 1 && has_data == 0 )); then
                    new_token="$split_to_server"
                elif (( has_data == 1 && has_server == 0 )); then
                    new_token="$split_to_data"
                else
                    local server_signal=0 data_signal=0
                    if printf '%s' "$line" | grep -qE "$server_sig"; then
                        server_signal=1
                    fi
                    if printf '%s' "$line" | grep -qE "$data_sig"; then
                        data_signal=1
                    fi
                    if (( server_signal == 1 && data_signal == 0 )); then
                        new_token="$split_to_server"
                    elif (( data_signal == 1 && server_signal == 0 )); then
                        new_token="$split_to_data"
                    fi
                fi
            fi

            if [[ -n "$new_token" ]]; then
                local sed_prog
                sed_prog=$(_migrator_skills_build_sed_program "$old" "$new_token")
                printf '%s\n' "$line" | sed "$sed_prog" >>"$tmp"
                rewrites=$((rewrites + 1))
            else
                # Ambiguous: keep the line, queue an advisory entry.
                printf '%s\n' "$line" >>"$tmp"
                if (( ambiguous == 0 )); then
                    if [[ -n "$advisory_intro" ]]; then
                        printf '%s' "$advisory_intro" >"$advisory"
                    elif [[ "$old" == "python-architecture" \
                         && "$mode" == "split" ]]; then
                        # BD-035 byte-equivalence path.
                        _migrator_skills_default_advisory_intro >"$advisory"
                    else
                        _migrator_skills_generic_advisory_intro \
                            "$old" "$split_to_server" "$split_to_data" \
                            "$([[ "$mode" == "simple" ]] && printf '%s' "$new")" \
                            >"$advisory"
                    fi
                fi
                printf '%s:%d: %s\n' "$rel" "$linenum" "$line" >>"$advisory"
                ambiguous=$((ambiguous + 1))
            fi
        done <"$f"

        if ! mv "$tmp" "$f"; then
            rm -f "$tmp"
            if declare -F fail_stage >/dev/null; then
                fail_stage S5 "migrator_skill_rename: failed to write rewritten $rel"
            else
                printf 'migrator_skill_rename: failed to write rewritten %s\n' "$rel" >&2
                return 1
            fi
        fi
        if declare -F info >/dev/null; then
            info "scanned $rel for ${old} rename"
        else
            printf '  scanned %s for %s rename\n' "$rel" "$old"
        fi
    done

    if declare -F info >/dev/null; then
        if (( rewrites > 0 )); then
            info "skill-rename: $rewrites unambiguous reference(s) rewritten in place"
        else
            info "skill-rename: no unambiguous references found to rewrite"
        fi
        if (( ambiguous > 0 )); then
            info "skill-rename: $ambiguous ambiguous reference(s) recorded in $advisory"
            info "review the advisory and rename by hand before treating the migration as complete"
        fi
    fi

    return 0
}

# migrator_skill_split <old-skill> <new-server-skill> <new-data-skill> [<advisory-path>]
#
# Forward-declared one-to-many split helper. v11.0 BD-035 calls
# `migrator_skill_rename` in split mode directly (see the v10→v11
# adapter S5b). This function exists so future migrators that need a
# more readable split call site, or that want to extend split semantics
# (additional destination skills, custom signal patterns), have a
# stable entry point.
#
# Body: thin wrapper around `migrator_skill_rename` in split mode using
# the BD-035 default signal patterns. Returns whatever the underlying
# call returns.
migrator_skill_split() {
    local old="${1:-}"
    local new_server="${2:-}"
    local new_data="${3:-}"
    local advisory="${4:-}"
    if [[ -z "$old" || -z "$new_server" || -z "$new_data" ]]; then
        printf 'migrator_skill_split: usage: migrator_skill_split <old> <new-server> <new-data> [<advisory-path>]\n' >&2
        return 2
    fi
    MIGRATOR_SKILLS_SPLIT_TO_SERVER="$new_server" \
    MIGRATOR_SKILLS_SPLIT_TO_DATA="$new_data" \
        migrator_skill_rename "$old" "$new_server" "$advisory"
}
