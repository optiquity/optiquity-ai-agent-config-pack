# scripts/lib/per-entry/mirror-generate.sh — regenerate the canonical
# monolithic mirror file from a per-entry tree (BD-164).
#
# Public API:
#   per_entry_regenerate_mirror <stream_key> <stream_dir> <mirror_path>
#       Regenerate the mirror at <mirror_path> from the per-entry
#       tree under <stream_dir>. Concatenation order per sidecar
#       parent §2.7 + addendum §3.6:
#           [_intro.md content]
#           [entry files in sort order — back-pointer stripped]
#           [_v8-resolved-archive.md content]   (pack-backlog ONLY)
#           [_format.md content]                (project-changelog ONLY)
#       Deterministic + idempotent. Reads `_rules.md` at runtime ONLY
#       for the supporting-file basename list (per integration parent
#       §7.5); unknown basenames are SKIP.
#
#       If the on-disk mirror already exists and differs from what the
#       generator would produce (divergence), behavior depends on
#       context:
#           - Interactive (TTY on stdin AND stdout): prompt user to
#             confirm overwrite; abort on rejection (Addendum #1 §5.3).
#           - Non-interactive: emit divergence warning to stderr and
#             return non-zero exit (BD-095-mode wiring in 19c
#             interprets the exit code per Addendum #2 §4).
#       The PE_FORCE_OVERWRITE_MIRROR env var, if set to "1", bypasses
#       both paths and proceeds with the overwrite (this is the seam
#       used by 19c's `--force-overwrite-mirror` flag wiring).
#
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §6.2 (mirror generator contract — deterministic + idempotent)
#     §2.7 (concatenation order — restated in integration parent)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §4.2 (Layer 2 strip discipline — back-pointer stripped at emit)
#     §7.5 (`_rules.md` runtime-read scope split)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md
#     §5.3 (interactive vs non-interactive divergence routing)
#     §5.2 (Layer 1 — DO NOT EDIT preamble in _intro.md, sourced verbatim)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
#     §2 (back-pointer stripped at mirror emit; preserves byte-additive
#         grammar invariant)
#     §4 (non-interactive divergence routing → non-zero exit)
#
# Bash 3.2 + macOS BSD utility compatible.
#
# Do NOT add a shebang — this file is sourced, not executed.

if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Internal: build the new mirror content into a temp file
# ─────────────────────────────────────────────────────────────────
#
# Arguments:
#   $1 = stream key
#   $2 = stream directory
#   $3 = output temp file path
#
# Concatenation order:
#   [_intro.md content (verbatim)]
#   <blank line gap if _intro.md present>
#   [entry files in lexical sort order, with back-pointer stripped,
#    separated by `\n---\n\n` per sidecar §2.7 inter-entry separator
#    convention observed in current BACKLOG.md]
#   [trailing supporting files in admitted order: _v8-resolved-archive.md
#    (pack-backlog), _format.md (project-changelog) — preceded by
#    `\n---\n\n`]
#
# Note: the inter-entry `---` separator IS observed in current
# pack BACKLOG.md (every entry is followed by `---` per the 2026-05
# observed shape; verified by `grep -c '^---$' BACKLOG.md`); the
# decompose helper strips this trailing separator and the mirror
# generator re-emits it. This preserves byte-identity round-trip.
pe__mirror_build_temp() {
    local key="$1"
    local stream_dir="$2"
    local out_tmp="$3"

    : >"$out_tmp"

    # Effective supporting-file list: known ∩ admitted (per §7.5).
    local effective
    effective=$(pe_supporting_files_effective "$key" "$stream_dir")

    # Helper: is <name> in the effective list?
    pe__effective_contains() {
        local needle="$1"
        case " $effective " in
            *" $needle "*) return 0 ;;
            *) return 1 ;;
        esac
    }

    # Tracks whether we have emitted any section yet (intro / entries /
    # trailing supporting file). Used to insert the `\n---\n\n` inter-
    # section separator before each NEW section after the first.
    local section_emitted=0

    # 1. Emit _intro.md if admitted + present (verbatim).
    if pe__effective_contains "_intro.md" && [[ -f "$stream_dir/_intro.md" ]]; then
        cat "$stream_dir/_intro.md" >>"$out_tmp"
        # Normalize to exactly one trailing newline.
        pe__normalize_trailing_blank "$out_tmp"
        section_emitted=1
    fi

    # 2. Emit entry files in deterministic order, back-pointer stripped,
    # joined with `\n---\n\n` separator (the observed BACKLOG.md
    # inter-entry pattern). The same separator precedes the FIRST entry
    # if any prior section (intro) was already emitted.
    local entries
    entries=$(pe_list_entry_files "$key" "$stream_dir")
    if [[ -n "$entries" ]]; then
        local first_entry=1
        local f
        while IFS= read -r f; do
            [[ -n "$f" ]] || continue
            if [[ $first_entry -eq 1 ]]; then
                first_entry=0
                if [[ $section_emitted -eq 1 ]]; then
                    # Inter-section separator (intro → entries).
                    printf '\n---\n\n' >>"$out_tmp"
                fi
            else
                # Inter-entry separator.
                printf '\n---\n\n' >>"$out_tmp"
            fi
            # Emit the entry file with back-pointer stripped.
            pe_strip_backpointer_stdin <"$f" >>"$out_tmp"
        done <<EOF
$entries
EOF
        # Normalize trailing whitespace before any trailing supporting
        # files emit.
        pe__normalize_trailing_blank "$out_tmp"
        section_emitted=1
    fi

    # 3. Trailing supporting files in admitted order.
    # Pack-backlog: _v8-resolved-archive.md (frozen-historical block).
    if [[ "$key" == "pack-backlog" ]] && pe__effective_contains "_v8-resolved-archive.md" \
       && [[ -f "$stream_dir/_v8-resolved-archive.md" ]]; then
        if [[ $section_emitted -eq 1 ]]; then
            printf '\n---\n\n' >>"$out_tmp"
        fi
        cat "$stream_dir/_v8-resolved-archive.md" >>"$out_tmp"
        pe__normalize_trailing_blank "$out_tmp"
        section_emitted=1
    fi

    # Project-changelog: _format.md (Format Rules block).
    if [[ "$key" == "project-changelog" ]] && pe__effective_contains "_format.md" \
       && [[ -f "$stream_dir/_format.md" ]]; then
        if [[ $section_emitted -eq 1 ]]; then
            printf '\n---\n\n' >>"$out_tmp"
        fi
        cat "$stream_dir/_format.md" >>"$out_tmp"
        pe__normalize_trailing_blank "$out_tmp"
        section_emitted=1
    fi
}

# Normalize: ensure file ends with EXACTLY one newline (no trailing
# blank lines accumulated across concatenations).
# $1 = file path
pe__normalize_trailing_blank() {
    local path="$1"
    [[ -f "$path" ]] || return 0
    # Use python3 for portable in-place trailing-whitespace trim
    # (BSD sed in-place is awkward and bash 3.2 has no readarray).
    python3 - "$path" <<'PYEOF'
import sys
p = sys.argv[1]
with open(p, "r", encoding="utf-8", newline="") as f:
    data = f.read()
data = data.rstrip("\n") + "\n"
with open(p, "w", encoding="utf-8", newline="") as f:
    f.write(data)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

per_entry_regenerate_mirror() {
    local key="$1"
    local stream_dir="$2"
    local mirror_path="$3"

    [[ -n "$key" ]] || pe_die "per_entry_regenerate_mirror: stream key required"
    [[ -n "$stream_dir" ]] || pe_die "per_entry_regenerate_mirror: stream dir required"
    [[ -n "$mirror_path" ]] || pe_die "per_entry_regenerate_mirror: mirror path required"

    pe_entry_regex_for_stream "$key" >/dev/null || \
        pe_die "per_entry_regenerate_mirror: unknown stream key: $key"

    [[ -d "$stream_dir" ]] || pe_die "per_entry_regenerate_mirror: stream dir not found: $stream_dir"

    # Build the new mirror content into a temp file.
    local mirror_dir new_tmp
    mirror_dir=$(dirname "$mirror_path")
    [[ -d "$mirror_dir" ]] || pe_die "per_entry_regenerate_mirror: mirror dir not found: $mirror_dir"
    new_tmp=$(mktemp "$mirror_dir/.per-entry-mirror.XXXXXX") || \
        pe_die "per_entry_regenerate_mirror: mktemp failed"

    # Set up cleanup trap.
    # shellcheck disable=SC2064
    trap "rm -f '$new_tmp'" EXIT

    pe__mirror_build_temp "$key" "$stream_dir" "$new_tmp"

    # Divergence check: compare new content to on-disk mirror.
    # If on-disk mirror absent: write directly (no divergence question).
    # If present and byte-identical to new: idempotent no-op (touch
    # prevented to avoid mtime churn).
    # If present and differs: divergence path.
    if [[ ! -f "$mirror_path" ]]; then
        # No prior mirror — write fresh.
        mv "$new_tmp" "$mirror_path"
        trap - EXIT
        return 0
    fi

    if cmp -s "$new_tmp" "$mirror_path"; then
        # Byte-identical — no-op. Clean up temp.
        rm -f "$new_tmp"
        trap - EXIT
        return 0
    fi

    # Divergence detected.
    if [[ "${PE_FORCE_OVERWRITE_MIRROR:-0}" == "1" ]]; then
        # Force path: overwrite + warn (audit-trail per Addendum #2 §4.5).
        pe_warn "PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at $mirror_path"
        mv "$new_tmp" "$mirror_path"
        trap - EXIT
        return 0
    fi

    if pe_is_interactive; then
        # Interactive: prompt user (Addendum #1 §5.3).
        printf 'WARNING: %s has been hand-edited since the last regeneration.\n' "$mirror_path" >&2
        printf '         Regeneration would overwrite the hand-edits.\n' >&2
        printf '         Overwrite? [y/N] ' >&2
        local reply
        read -r reply
        case "$reply" in
            [Yy]|[Yy][Ee][Ss])
                mv "$new_tmp" "$mirror_path"
                trap - EXIT
                return 0
                ;;
            *)
                pe_warn "aborted; on-disk mirror at $mirror_path unchanged"
                rm -f "$new_tmp"
                trap - EXIT
                return 1
                ;;
        esac
    fi

    # Non-interactive divergence path: warn + non-zero exit. The 19c
    # BD-095-mode wiring interprets the exit code (per Addendum #2 §4):
    # in --apply / --resume mode this blocks; in --dry-run mode the
    # caller handles the report.
    printf 'WARNING: per-entry regenerator detected divergence at: %s\n' "$mirror_path" >&2
    printf '         per-entry tree under %s would produce different content.\n' "$stream_dir" >&2
    printf '         Pass --force-overwrite-mirror (or set PE_FORCE_OVERWRITE_MIRROR=1) to overwrite.\n' >&2
    rm -f "$new_tmp"
    trap - EXIT
    return 2
}
