# scripts/lib/three-way.sh — four-case three-way classifier for migration text files.
#
# Sourced by migrate-v9-to-v10.sh (and any future migration script) to decide
# what to do with a project file the migration is about to touch. The classifier
# answers a single question per file: "given the v9.3 pack baseline (BASE), the
# project file pre-migration (OURS), and the v10 pack template (THEIRS), which
# of four dispositions applies?"
#
# Every function is read-only with respect to all three input files — no writes,
# no merges, no copies. Callers act on the classification.
#
# Do NOT add a shebang — this file is sourced, not executed.
#
# Reference: V10-MIGRATION-FIX-DESIGN.md Part 3.1.
#
# ENTRY: three_way_classify
#   Usage:
#     source "$PACK/scripts/lib/three-way.sh"
#     classification=$(three_way_classify "$base" "$ours" "$theirs")
#
#   Arguments are absolute paths to three files. BASE and THEIRS may also be
#   the absent-token "" (empty string) when the file does not exist on that
#   side; OURS may be "" when the project does not have the file.
#
#   Stdout: one of the classification tokens defined below.
#   Exit code: 0 always (callers dispatch on the token, not exit status).
#
# Classification tokens (canonical four-case set, BASE/OURS/THEIRS all present):
#   unchanged-pack              base == ours and base == theirs (no-op)
#   pack-update-applied         base == ours and base != theirs (adopt v10)
#   merged-with-customization   base != ours and base == theirs (keep project)
#   real-merge-required         base != ours and base != theirs (sidecar)
#
# Auxiliary tokens for non-canonical cases (one or more inputs absent):
#   new-file-in-pack            base absent, ours absent, theirs present
#                               (copy v10 file to project)
#   project-only-file           base absent, ours present, theirs absent
#                               (preserve project file, never touch)
#   project-shadows-new-pack    base absent, ours present, theirs present
#                               (improperly-added pre-existing file; classify
#                               by ours-vs-theirs and let caller route to
#                               Procedure 5.4 if they differ)
#   removed-by-pack-clean       base present, ours == base, theirs absent
#                               (pack retired the file; project never edited;
#                               safe to remove)
#   removed-by-pack-customized  base present, ours != base, theirs absent
#                               (pack retired the file; project edited it;
#                               sidecar to preserve the customization)
#   removed-everywhere          base present, ours absent, theirs absent
#                               (already gone on both sides; no-op)
#   project-deleted-pack-kept   base present, ours absent, theirs present
#                               (project intentionally removed a file pack
#                               still ships; caller decides whether to
#                               restore from theirs or honor the deletion)
#   no-inputs                   all three absent (caller error; exit 1)

three_way_classify() {
    local base="$1"
    local ours="$2"
    local theirs="$3"

    local has_base=0 has_ours=0 has_theirs=0
    [[ -n "$base"   && -e "$base"   ]] && has_base=1
    [[ -n "$ours"   && -e "$ours"   ]] && has_ours=1
    [[ -n "$theirs" && -e "$theirs" ]] && has_theirs=1

    # All three present: canonical four-case.
    if [[ $has_base -eq 1 && $has_ours -eq 1 && $has_theirs -eq 1 ]]; then
        local base_eq_ours=0 base_eq_theirs=0
        cmp -s "$base" "$ours"   && base_eq_ours=1
        cmp -s "$base" "$theirs" && base_eq_theirs=1

        if [[ $base_eq_ours -eq 1 && $base_eq_theirs -eq 1 ]]; then
            echo "unchanged-pack"
        elif [[ $base_eq_ours -eq 1 && $base_eq_theirs -eq 0 ]]; then
            echo "pack-update-applied"
        elif [[ $base_eq_ours -eq 0 && $base_eq_theirs -eq 1 ]]; then
            echo "merged-with-customization"
        else
            echo "real-merge-required"
        fi
        return 0
    fi

    # New file in v10: pack adds a file the v9.3 baseline didn't have and
    # the project doesn't have either.
    if [[ $has_base -eq 0 && $has_ours -eq 0 && $has_theirs -eq 1 ]]; then
        echo "new-file-in-pack"
        return 0
    fi

    # Project-only file: lives in the project but not in any pack version.
    if [[ $has_base -eq 0 && $has_ours -eq 1 && $has_theirs -eq 0 ]]; then
        echo "project-only-file"
        return 0
    fi

    # Project shadows a new pack file (pre-existing or improperly added).
    if [[ $has_base -eq 0 && $has_ours -eq 1 && $has_theirs -eq 1 ]]; then
        echo "project-shadows-new-pack"
        return 0
    fi

    # File removed in v10. Project may or may not have customized it.
    if [[ $has_base -eq 1 && $has_theirs -eq 0 ]]; then
        if [[ $has_ours -eq 0 ]]; then
            echo "removed-everywhere"
        elif cmp -s "$base" "$ours"; then
            echo "removed-by-pack-clean"
        else
            echo "removed-by-pack-customized"
        fi
        return 0
    fi

    # Project deleted a file the pack still ships in v10.
    if [[ $has_base -eq 1 && $has_ours -eq 0 && $has_theirs -eq 1 ]]; then
        echo "project-deleted-pack-kept"
        return 0
    fi

    # No inputs: caller error.
    echo "no-inputs"
    return 1
}

# ENTRY: three_way_dispatch
#   Convenience helper that prints both the classification token AND a
#   human-readable one-line summary of the inputs, suitable for logging.
#
#   Usage:
#     three_way_dispatch /path/base /path/ours /path/theirs file-label
#
#   Stdout (one line):
#     <classification>\t<file-label>\tbase=<flag> ours=<flag> theirs=<flag>
#
#   where each <flag> is "yes" or "no" indicating presence.

three_way_dispatch() {
    local base="$1" ours="$2" theirs="$3" label="${4:-<unlabeled>}"
    local classification
    classification=$(three_way_classify "$base" "$ours" "$theirs")

    local b=no o=no t=no
    [[ -n "$base"   && -e "$base"   ]] && b=yes
    [[ -n "$ours"   && -e "$ours"   ]] && o=yes
    [[ -n "$theirs" && -e "$theirs" ]] && t=yes

    printf '%s\t%s\tbase=%s ours=%s theirs=%s\n' "$classification" "$label" "$b" "$o" "$t"
}
