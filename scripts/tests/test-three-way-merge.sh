#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-three-way-merge.sh — BD-287 unit tests for the deterministic
# 3-way merge primitive scripts/lib/three-way-merge.sh (tw_merge_file).
#
# Pins the load-bearing rc 0/1/2 contract AND the OUT content it produces:
#   C-1 CLEAN (rc 0): OURS edits one line, THEIRS edits a DIFFERENT line ->
#       rc 0, OUT carries BOTH edits, ZERO of the four diff3 tokens.
#   C-2 MARKERS (rc 1): OURS and THEIRS edit the SAME line -> rc 1, OUT carries
#       all four diff3 tokens with all three caller labels (OI-9), OURS label at
#       the TOP / BASE label in the MIDDLE / THEIRS label at the BOTTOM (OI-8).
#   C-3 rc 2 no-base (BASE empty string): rc 2, no merge attempted, OUT untouched.
#   C-4 rc 2 no-base (BASE path absent):  rc 2, OUT untouched.
#   C-5 rc 2 error (OURS input missing):  rc 2, OUT untouched.
#   C-6 rc 2 error (THEIRS input missing): rc 2, OUT untouched.
#   C-7 rc 2 no-base (BASE present+readable but ZERO-BYTE content): the I3 guard
#       rejects an empty-content (non-real) base; rc 2, no merge, OUT untouched.
#
# Labels are exercised with the generic public-safe strings the migrator passes
# (no target-app vocabulary): "your customization" / "v10 baseline" /
# "pack v11 update".
#
# Usage:    bash scripts/tests/test-three-way-merge.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# BD-276: portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`,
# which leaves a literal XXXXXX on BSD).
WORK="$(mktemp -d "${TMPDIR:-/tmp}/bd287-twmerge.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

passes=0
fails=0
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
assert_eq() { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }
# assert file $2 contains a line matching ERE $3
assert_grep() {
    if grep -qE -- "$3" "$2"; then pass "$1"
    else fail "$1" "match /$3/ in $2"; fi
}
# assert file $2 does NOT contain a line matching ERE $3
assert_no_grep() {
    if grep -qE -- "$3" "$2"; then fail "$1" "no match /$3/ in $2"
    else pass "$1"; fi
}
# assert first line matching $3 precedes first line matching $4 in file $2
assert_order() {
    local label="$1" file="$2" first="$3" second="$4" lf ls
    lf=$(grep -nE -- "$first" "$file" | head -1 | cut -d: -f1)
    ls=$(grep -nE -- "$second" "$file" | head -1 | cut -d: -f1)
    if [[ -n "$lf" && -n "$ls" && "$lf" -lt "$ls" ]]; then pass "$label"
    else fail "$label" "'$first' (line ${lf:-none}) before '$second' (line ${ls:-none})"; fi
}

# shellcheck disable=SC1091
source "$LIB_DIR/three-way-merge.sh"

if ! declare -F tw_merge_file >/dev/null 2>&1; then
    echo "FATAL: tw_merge_file not sourced from three-way-merge.sh"
    exit 1
fi

# The generic public-safe caller labels (OI-9).
L_OURS="your customization"
L_BASE="v10 baseline"
L_THEIRS="pack v11 update"

# Four diff3 tokens (7 repeats each). ERE-escaped for grep -E.
TOK_OPEN='^<<<<<<<'
TOK_BASE='^\|\|\|\|\|\|\|'
TOK_SEP='^======='
TOK_CLOSE='^>>>>>>>'

# --- Shared BASE (10 lines) --------------------------------------------------
BASE="$WORK/base.txt"
printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\n' > "$BASE"

# =============================================================================
# C-1 CLEAN (rc 0): different-line edits union with zero markers
# =============================================================================
echo "C-1 clean different-line merge (rc 0):"
OURS1="$WORK/c1-ours.txt"
THEIRS1="$WORK/c1-theirs.txt"
OUT1="$WORK/c1-out.txt"
printf 'l1\nl2\nOURS3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\n'   > "$OURS1"   # edits line 3
printf 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nTHEIRS9\nl10\n' > "$THEIRS1" # edits line 9
tw_merge_file "$BASE" "$OURS1" "$THEIRS1" "$OUT1" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-1 rc == 0 (clean)" "0" "$rc"
if [[ -f "$OUT1" ]]; then
    assert_grep    "C-1 OUT carries OURS edit"        "$OUT1" '^OURS3$'
    assert_grep    "C-1 OUT carries THEIRS edit"      "$OUT1" '^THEIRS9$'
    assert_no_grep "C-1 OUT has no open token"        "$OUT1" "$TOK_OPEN"
    assert_no_grep "C-1 OUT has no base token"        "$OUT1" "$TOK_BASE"
    assert_no_grep "C-1 OUT has no separator token"   "$OUT1" "$TOK_SEP"
    assert_no_grep "C-1 OUT has no close token"       "$OUT1" "$TOK_CLOSE"
else
    fail "C-1 OUT written" "OUT file exists"
fi

# =============================================================================
# C-2 MARKERS (rc 1): same-line overlap -> diff3 markers with all three labels
# =============================================================================
echo "C-2 same-line conflict merge (rc 1):"
OURS2="$WORK/c2-ours.txt"
THEIRS2="$WORK/c2-theirs.txt"
OUT2="$WORK/c2-out.txt"
printf 'l1\nl2\nOURS3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\n'   > "$OURS2"   # edits line 3
printf 'l1\nl2\nTHEIRS3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\n' > "$THEIRS2" # edits line 3
tw_merge_file "$BASE" "$OURS2" "$THEIRS2" "$OUT2" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-2 rc == 1 (markers)" "1" "$rc"
if [[ -f "$OUT2" ]]; then
    assert_grep  "C-2 OUT has open token"       "$OUT2" "$TOK_OPEN"
    assert_grep  "C-2 OUT has base token"       "$OUT2" "$TOK_BASE"
    assert_grep  "C-2 OUT has separator token"  "$OUT2" "$TOK_SEP"
    assert_grep  "C-2 OUT has close token"      "$OUT2" "$TOK_CLOSE"
    # all three caller labels rendered (OI-9)
    assert_grep  "C-2 OURS label on open marker"   "$OUT2" '^<<<<<<< your customization$'
    assert_grep  "C-2 BASE label on base marker"   "$OUT2" '^\|\|\|\|\|\|\| v10 baseline$'
    assert_grep  "C-2 THEIRS label on close marker" "$OUT2" '^>>>>>>> pack v11 update$'
    # ordering OI-8: OURS (current) top, BASE middle, THEIRS (other) bottom
    assert_order "C-2 OURS label before BASE label"   "$OUT2" '^<<<<<<< your customization$' '^\|\|\|\|\|\|\| v10 baseline$'
    assert_order "C-2 BASE label before THEIRS label" "$OUT2" '^\|\|\|\|\|\|\| v10 baseline$' '^>>>>>>> pack v11 update$'
    # both conflicting bodies present
    assert_grep  "C-2 OUT carries OURS body"    "$OUT2" '^OURS3$'
    assert_grep  "C-2 OUT carries THEIRS body"  "$OUT2" '^THEIRS3$'
else
    fail "C-2 OUT written" "OUT file exists"
fi

# =============================================================================
# C-3 rc 2 no-base (BASE empty string): no merge attempted, OUT untouched
# =============================================================================
echo "C-3 rc 2 no-base (empty BASE):"
OUT3="$WORK/c3-out.txt"   # deliberately does NOT pre-exist
tw_merge_file "" "$OURS1" "$THEIRS1" "$OUT3" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-3 rc == 2 (no base)" "2" "$rc"
if [[ -e "$OUT3" ]]; then
    fail "C-3 OUT untouched" "OUT not created on rc 2"
else
    pass "C-3 OUT untouched (no partial write)"
fi

# =============================================================================
# C-4 rc 2 no-base (BASE path absent): OUT untouched (pre-existing sentinel kept)
# =============================================================================
echo "C-4 rc 2 no-base (absent BASE path):"
OUT4="$WORK/c4-out.txt"
printf 'SENTINEL-KEEP\n' > "$OUT4"   # pre-existing OUT must survive rc 2
tw_merge_file "$WORK/does-not-exist-base.txt" "$OURS1" "$THEIRS1" "$OUT4" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-4 rc == 2 (absent base path)" "2" "$rc"
assert_eq "C-4 pre-existing OUT unchanged" "SENTINEL-KEEP" "$(cat "$OUT4")"

# =============================================================================
# C-5 rc 2 error (OURS input missing): OUT untouched
# =============================================================================
echo "C-5 rc 2 error (missing OURS):"
OUT5="$WORK/c5-out.txt"   # does NOT pre-exist
tw_merge_file "$BASE" "$WORK/does-not-exist-ours.txt" "$THEIRS1" "$OUT5" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-5 rc == 2 (missing OURS)" "2" "$rc"
if [[ -e "$OUT5" ]]; then
    fail "C-5 OUT untouched" "OUT not created on rc 2"
else
    pass "C-5 OUT untouched (no partial write)"
fi

# =============================================================================
# C-6 rc 2 error (THEIRS input missing): OUT untouched
# =============================================================================
echo "C-6 rc 2 error (missing THEIRS):"
OUT6="$WORK/c6-out.txt"   # does NOT pre-exist
tw_merge_file "$BASE" "$OURS1" "$WORK/does-not-exist-theirs.txt" "$OUT6" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-6 rc == 2 (missing THEIRS)" "2" "$rc"
if [[ -e "$OUT6" ]]; then
    fail "C-6 OUT untouched" "OUT not created on rc 2"
else
    pass "C-6 OUT untouched (no partial write)"
fi

# =============================================================================
# C-7 rc 2 no-base (BASE present+readable but ZERO-BYTE content): the I3 guard
# rejects an empty-CONTENT base (a non-real base with no v10 content) BEFORE the
# merge, so no 2-way pseudo merge occurs and OUT is untouched.
# =============================================================================
echo "C-7 rc 2 no-base (zero-byte BASE content):"
EMPTYBASE="$WORK/c7-empty-base.txt"
: > "$EMPTYBASE"          # present + readable, but zero bytes (no real v10 content)
OUT7="$WORK/c7-out.txt"   # does NOT pre-exist
tw_merge_file "$EMPTYBASE" "$OURS1" "$THEIRS1" "$OUT7" "$L_OURS" "$L_BASE" "$L_THEIRS"
rc=$?
assert_eq "C-7 rc == 2 (zero-byte base)" "2" "$rc"
if [[ -e "$OUT7" ]]; then
    fail "C-7 OUT untouched" "OUT not created on rc 2"
else
    pass "C-7 OUT untouched (no partial write)"
fi

# --- summary -----------------------------------------------------------------
echo
echo "----------------------------------------"
echo "test-three-way-merge.sh: $passes passed, $fails failed"
if [[ "$fails" -gt 0 ]]; then
    exit 1
fi
echo "ALL PASS"
exit 0
