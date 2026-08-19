# scripts/lib/three-way-merge.sh — BD-287 deterministic 3-way text merge primitive.
#
# Sourced by the v10->v11 migrator's customization-preserve layer to REAL-merge a
# prose file that both the pack and the project changed since the v10 baseline,
# producing a single output that carries BOTH sides' edits with zero conflict
# markers when the edits do not overlap, and inline diff3 conflict markers when
# they do. It wraps the git merge-file builtin behind a small, stable rc contract
# so the caller can dispatch on 0/1/2 and fall back to today's sidecar on 2.
#
# Distinct from scripts/lib/three-way.sh (the read-only four-case CLASSIFIER,
# which decides WHAT to do with a file). This file DOES the merge. The two are
# complementary and independent; three-way.sh is UNCHANGED.
#
# Do NOT add a shebang — this file is sourced, not executed.
#
# ENTRY: tw_merge_file
#   Usage:
#     source "$PACK/scripts/lib/three-way-merge.sh"
#     tw_merge_file "$base" "$ours" "$theirs" "$out" \
#                   "$l_ours" "$l_base" "$l_theirs"
#     rc=$?
#
#   Arguments (all positional):
#     BASE     absolute path to the common ancestor (the v10 pack baseline).
#     OURS     absolute path to the "current" side (the project's file) — diff3
#              CURRENT; rendered at the TOP of a conflict hunk (<<<<<<<).
#     THEIRS   absolute path to the "other" side (the pack v11 template) — diff3
#              OTHER; rendered at the BOTTOM of a conflict hunk (>>>>>>>).
#     OUT      absolute path the merged result is written to. Written ONLY on a
#              clean merge (rc 0) or a marker merge (rc 1); left UNTOUCHED on rc 2.
#     L_OURS   conflict-marker label for OURS  (caller-supplied, generic).
#     L_BASE   conflict-marker label for BASE  (caller-supplied, generic; the
#              diff3 ancestor label, rendered in the MIDDLE, |||||||).
#     L_THEIRS conflict-marker label for THEIRS (caller-supplied, generic).
#
#   The labels are the CALLER's inputs — this primitive hardcodes NO vocabulary.
#   (The migrator passes generic public-safe strings, e.g. "your customization" /
#   "v10 baseline" / "pack v11 update".)
#
#   Return contract (the load-bearing 0/1/2 the caller dispatches on):
#     0  CLEAN  — merged with ZERO conflict markers; OUT written.
#     1  MARKERS — merged WITH diff3 conflict markers (a same-line overlap the
#                  merge could not resolve); OUT written, markers embedded.
#     2  UNUSABLE — the caller MUST fall back to today's sidecar. Covers:
#                     - a missing/unreadable OURS, THEIRS, or OUT-arg;
#                     - a NON-REAL base (BASE absent, empty-string, or zero-byte
#                       content) — the REAL-BASE-only guard (I3): return 2 WITHOUT
#                       attempting a merge, so a BASE-less path (e.g. --update)
#                       never gets a 2-way pseudo merge;
#                     - a git merge-file builtin failure (it exits negative, which
#                       the shell wraps to >=128).
#                  On rc 2 OUT is NEVER written (no partial output).
#
#   git merge-file's own exit is mapped as: 0 -> 0 (clean); 1..127 -> 1 (the
#   builtin returns the conflict count, truncated to 127); >=128 -> 2 (an error;
#   the documented negative return, wrapped by the shell).
#
#   Exit/stderr: the builtin's stderr is suppressed; the caller emits its own
#   user-facing messaging based on the rc.
#
# bash 3.2 / BSD-utils safe: no `local -n`, no `mapfile`, no `${var^^}`, no GNU-only
# flags. Uses a full-template mktemp (never `mktemp -t prefix.XXXXXX`, which leaves
# a literal XXXXXX on BSD).

tw_merge_file() {
    local base="${1:-}"
    local ours="${2:-}"
    local theirs="${3:-}"
    local out="${4:-}"
    local l_ours="${5:-}"
    local l_base="${6:-}"
    local l_theirs="${7:-}"

    # OUT-arg must be supplied (a merge with nowhere to land is unusable).
    [[ -z "$out" ]] && return 2

    # REAL-BASE-only guard (I3): BASE must be a present, readable, NON-EMPTY
    # regular file. Absent, empty-string, or zero-byte (empty-content) BASE ->
    # unusable; do NOT attempt a 2-way pseudo merge (a zero-byte ancestor makes
    # git merge-file emit whole-file markers — the exact pseudo merge I3 blocks).
    [[ -z "$base"   || ! -f "$base"   || ! -r "$base"   || ! -s "$base" ]] && return 2

    # OURS and THEIRS must exist and be readable regular files.
    [[ -z "$ours"   || ! -f "$ours"   || ! -r "$ours"   ]] && return 2
    [[ -z "$theirs" || ! -f "$theirs" || ! -r "$theirs" ]] && return 2

    local tmp rc
    tmp="$(mktemp "${TMPDIR:-/tmp}/tw-merge.XXXXXX")" || return 2

    # OURS is the diff3 CURRENT (top), BASE the ancestor (middle), THEIRS the
    # OTHER (bottom). Result to a temp so OUT is untouched on an error rc.
    git merge-file -p --diff3 \
        -L "$l_ours" -L "$l_base" -L "$l_theirs" \
        "$ours" "$base" "$theirs" > "$tmp" 2>/dev/null
    rc=$?

    if [[ "$rc" -eq 0 ]]; then
        if cp "$tmp" "$out" 2>/dev/null; then rc=0; else rc=2; fi
    elif [[ "$rc" -ge 1 && "$rc" -le 127 ]]; then
        if cp "$tmp" "$out" 2>/dev/null; then rc=1; else rc=2; fi
    else
        rc=2   # >=128: git merge-file signalled an error (negative, wrapped).
    fi

    rm -f "$tmp"
    return "$rc"
}
