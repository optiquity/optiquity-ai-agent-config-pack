#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-marker-preserve-bd136.sh — BD-136 trinity marker-aware
# merge engine (scripts/lib/marker-preserve.sh) pure-merger legs.
#
# Pins the two-regime BASE-preferred / degrade-SAFE graft:
#   M-1  Shape A round-trip (Regime A): in-marker byte-identical + out-of-marker
#        pack body adopted via 3-way.
#   M-2  Shape B round-trip: project-original + renamed-from + override, all
#        byte-identical; overridden pack section suppressed.
#   M-3  new canonical H2 lands between two project Shape B overrides (L-5).
#   M-4  new pack content atop a wrapped Shape A (Regime B) -> sidecar; project
#        content byte-identical (L-2).
#   M-5  same H2 in Shape A + Shape B -> fail loud (L-4/V-6).
#   M-6  unbalanced markers (orphan END) -> fail loud (L-6).
#   M-7  markered [CONDITIONAL] -> fail loud (L-9, Step-1 hoist reaches it).
#   M-13 (B1 guard, Regime B): out-of-marker Shape A project edit is NOT
#        silently lost -> needs-reconciliation + sidecar preserves it.
#   M-14 (M1 guard, BASE-AWARE — POQ-1 fix): 3 legs —
#        (a) BASE-absent [CONDITIONAL] -> M1 fires (fail loud; the original target:
#            client init --update anomaly / a regressed v11 trinity);
#        (b) BASE-present + CUSTOMIZED [CONDITIONAL] body (base != ours) -> M1 fires
#            -> sidecar + L-9 message (client edit preserved);
#        (c) BASE-present + NON-customized (base == ours) -> M1 SILENT -> the
#            markerless fallback adopts THEIRS's already-retired canonical
#            -> pack-update-applied, NO sidecar (the POQ-1 regression guard).
#   M-15 (M2 guard): a lone orphan BEGIN (1 token, 0 pairs) -> fail loud via
#        the L-6 gate (NOT swallowed by the zero-TOKEN fallback).
#   M-16 (B1 discriminate, Regime A): project-edited body -> sidecar (safety);
#        pack-edited body -> clean merged (value). Proves the 3-way DISCRIMINATES.
#   Fence S2: the MERGER-side fence classification of the shared fixture
#        scripts/tests/fixtures/marker-fence-grammar/ matches its committed
#        EXPECTED-TOKENS.tsv (the bash half of the two-parser cross-check).
#   Legacy: a markerless trinity still surfaces needs-reconciliation (Check 25
#        parity) and a benign markerless trinity stays unchanged-pack; a trinity
#        whose ONLY markers are fenced is treated as markerless (fence-aware M2).
#
# Fixture legs that need built fixtures / Check 91 (M-8/M-10/M-11/M-12 + the
# Python half of the fence cross-check) live in the C5/C9 suites — this file
# needs only marker-preserve.sh.
#
# Usage:    bash scripts/tests/test-marker-preserve-bd136.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FENCE_FX="$REPO_ROOT/scripts/tests/fixtures/marker-fence-grammar"

# BD-276: portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`,
# which leaves a literal XXXXXX on BSD).
FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/bd136-marker.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

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
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then pass "$1"; else fail "$1" "contains '$3'" "$2"; fi
}
assert_absent() {
    if [[ "$2" != *"$3"* ]]; then pass "$1"; else fail "$1" "absent '$3'" "$2"; fi
}
# assert $2 appears BEFORE $3 in file $1 (both present).
assert_order() {
    local label="$1" file="$2" first="$3" second="$4"
    local lf ls
    lf=$(grep -n -- "$first" "$file" | head -1 | cut -d: -f1)
    ls=$(grep -n -- "$second" "$file" | head -1 | cut -d: -f1)
    if [[ -n "$lf" && -n "$ls" && "$lf" -lt "$ls" ]]; then pass "$label"
    else fail "$label" "'$first' (line $lf) before '$second' (line $ls)"; fi
}

# shellcheck disable=SC1091
source "$LIB_DIR/three-way.sh"
export _CP_PACK_ROOT="$REPO_ROOT"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-preserve.sh"

if ! declare -F marker_preserve_trinity >/dev/null 2>&1; then
    echo "FATAL: marker_preserve_trinity not sourced (customization-preserve.sh must source marker-preserve.sh)"
    exit 1
fi

STATE="$FIXTURE_BASE/state"
newstate() { rm -rf "$STATE"; customization_preserve_init "$STATE" ".pre-update" >/dev/null; }
last_col() { tail -1 "$STATE/dispositions.tsv" | awk -F'\t' -v c="$1" '{print $c}'; }
last_disp()  { last_col 1; }
last_class() { last_col 2; }
last_notes() { last_col 7; }

# Run trinity merge; DEST is $FIXTURE_BASE/<name>/dest.md.
mk() { mkdir -p "$FIXTURE_BASE/$1"; }

NEEDS="customization-detected-needs-reconciliation"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-1: Shape A round-trip (Regime A) — 3 anchors =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m1
cat > "$FIXTURE_BASE/m1/base.md" <<'MD'
## Sec1
sec1 pack v1
## Sec2
sec2 pack v1
## Sec3
sec3 pack v1
MD
cat > "$FIXTURE_BASE/m1/ours.md" <<'MD'
## Sec1
sec1 pack v1
<!-- BEGIN project-owned -->
PROJ-ONE
<!-- END project-owned -->
## Sec2
sec2 pack v1
<!-- BEGIN project-owned -->
PROJ-TWO
<!-- END project-owned -->
## Sec3
sec3 pack v1
<!-- BEGIN project-owned -->
PROJ-THREE
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m1/theirs.md" <<'MD'
## Sec1
sec1 pack v2
## Sec2
sec2 pack v2
## Sec3
sec3 pack v2
MD
cp "$FIXTURE_BASE/m1/ours.md" "$FIXTURE_BASE/m1/dest.md"
customization_preserve "$FIXTURE_BASE/m1/base.md" "$FIXTURE_BASE/m1/ours.md" \
    "$FIXTURE_BASE/m1/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/m1/dest.md" trinity >/dev/null
d1=$(cat "$FIXTURE_BASE/m1/dest.md")
assert_eq "M-1 disposition merged-with-customization" "merged-with-customization" "$(last_disp)"
assert_contains "M-1 project region 1 byte-identical" "$d1" "PROJ-ONE"
assert_contains "M-1 project region 2 byte-identical" "$d1" "PROJ-TWO"
assert_contains "M-1 project region 3 byte-identical" "$d1" "PROJ-THREE"
assert_contains "M-1 out-of-marker pack body adopted (v2)" "$d1" "sec1 pack v2"
assert_absent  "M-1 old pack body dropped (v1 gone)"       "$d1" "sec1 pack v1"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-2: Shape B round-trip (original + renamed-from + override) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m2
cat > "$FIXTURE_BASE/m2/ours.md" <<'MD'
<!-- BEGIN project-owned -->
## My Original Notes
original body ONLYMINE
<!-- END project-owned -->
<!-- BEGIN project-owned: renamed-from "## Language-specific coding rules" -->
## Swift coding rules
swift body RENAMEDBODY
<!-- END project-owned -->
<!-- BEGIN project-owned -->
## Anti-patterns
override body OVERRIDEBODY
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m2/theirs.md" <<'MD'
## Language-specific coding rules
pack lang body
## Anti-patterns
pack anti body
## Other pack section
pack other keep
MD
cp "$FIXTURE_BASE/m2/ours.md" "$FIXTURE_BASE/m2/dest.md"
customization_preserve "" "$FIXTURE_BASE/m2/ours.md" "$FIXTURE_BASE/m2/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m2/dest.md" trinity >/dev/null
d2=$(cat "$FIXTURE_BASE/m2/dest.md")
assert_eq "M-2 disposition merged-with-customization" "merged-with-customization" "$(last_disp)"
assert_contains "M-2 project-original byte-identical"   "$d2" "ONLYMINE"
assert_contains "M-2 renamed-from body byte-identical"  "$d2" "RENAMEDBODY"
assert_contains "M-2 override body byte-identical"      "$d2" "OVERRIDEBODY"
assert_absent  "M-2 overridden pack lang body suppressed" "$d2" "pack lang body"
assert_absent  "M-2 overridden pack anti body suppressed" "$d2" "pack anti body"
assert_contains "M-2 non-overridden pack section kept"    "$d2" "pack other keep"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-3: new canonical H2 lands between two project Shape B (L-5) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m3
cat > "$FIXTURE_BASE/m3/ours.md" <<'MD'
<!-- BEGIN project-owned -->
## Xsec
my X body XBODY
<!-- END project-owned -->
<!-- BEGIN project-owned -->
## Zsec
my Z body ZBODY
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m3/theirs.md" <<'MD'
## Xsec
pack X body
## Ysec
pack Y NEW-SECTION
## Zsec
pack Z body
MD
cp "$FIXTURE_BASE/m3/ours.md" "$FIXTURE_BASE/m3/dest.md"
customization_preserve "" "$FIXTURE_BASE/m3/ours.md" "$FIXTURE_BASE/m3/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m3/dest.md" trinity >/dev/null
d3f="$FIXTURE_BASE/m3/dest.md"; d3=$(cat "$d3f")
assert_eq "M-3 disposition merged-with-customization" "merged-with-customization" "$(last_disp)"
assert_contains "M-3 new pack H2 present"       "$d3" "pack Y NEW-SECTION"
assert_contains "M-3 Shape B X byte-identical"  "$d3" "XBODY"
assert_contains "M-3 Shape B Z byte-identical"  "$d3" "ZBODY"
assert_order   "M-3 order X < Y"  "$d3f" "XBODY" "NEW-SECTION"
assert_order   "M-3 order Y < Z"  "$d3f" "NEW-SECTION" "ZBODY"
assert_absent  "M-3 overridden pack X body suppressed" "$d3" "pack X body"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-4: new pack content atop a wrapped Shape A (Regime B) -> sidecar =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m4
cat > "$FIXTURE_BASE/m4/ours.md" <<'MD'
## Sec
pack line
<!-- BEGIN project-owned -->
MINE-M4
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m4/theirs.md" <<'MD'
## Sec
NEW PACK BULLET
pack line
MD
cp "$FIXTURE_BASE/m4/ours.md" "$FIXTURE_BASE/m4/dest.md"
customization_preserve "" "$FIXTURE_BASE/m4/ours.md" "$FIXTURE_BASE/m4/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m4/dest.md" trinity >/dev/null
assert_eq "M-4 disposition needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-4 message names out-of-marker divergence" "$(last_notes)" "outside your markers"
assert_contains "M-4 project Shape A content byte-identical in sidecar" \
    "$(cat "$FIXTURE_BASE/m4/dest.md.pre-update")" "MINE-M4"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-5: same H2 in Shape A + Shape B -> fail loud (L-4/V-6) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m5
cat > "$FIXTURE_BASE/m5/ours.md" <<'MD'
## Dup
pack
<!-- BEGIN project-owned -->
shapeA add
<!-- END project-owned -->
<!-- BEGIN project-owned -->
## Dup
shapeB body
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m5/theirs.md" <<'MD'
## Dup
pack
MD
cp "$FIXTURE_BASE/m5/ours.md" "$FIXTURE_BASE/m5/dest.md"
customization_preserve "" "$FIXTURE_BASE/m5/ours.md" "$FIXTURE_BASE/m5/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m5/dest.md" trinity >/dev/null
assert_eq "M-5 disposition needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-5 message names the duplicate" "$(last_notes)" "duplicate H2/H3 name"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-6: unbalanced markers (orphan END) -> fail loud (L-6) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m6
cat > "$FIXTURE_BASE/m6/ours.md" <<'MD'
## Sec
pack
<!-- BEGIN project-owned -->
mine
<!-- END project-owned -->
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m6/theirs.md" <<'MD'
## Sec
pack
MD
cp "$FIXTURE_BASE/m6/ours.md" "$FIXTURE_BASE/m6/dest.md"
customization_preserve "" "$FIXTURE_BASE/m6/ours.md" "$FIXTURE_BASE/m6/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m6/dest.md" trinity >/dev/null
assert_eq "M-6 disposition needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-6 message names the orphan/imbalance" "$(last_notes)" "orphan END marker"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-7: markered [CONDITIONAL] -> fail loud (L-9, hoist reaches it) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m7
cat > "$FIXTURE_BASE/m7/ours.md" <<'MD'
## [CONDITIONAL] Legacy Foo
legacy body
<!-- BEGIN project-owned -->
mine
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m7/theirs.md" <<'MD'
## Foo
pack foo body
MD
cp "$FIXTURE_BASE/m7/ours.md" "$FIXTURE_BASE/m7/dest.md"
customization_preserve "" "$FIXTURE_BASE/m7/ours.md" "$FIXTURE_BASE/m7/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m7/dest.md" trinity >/dev/null
assert_eq "M-7 disposition needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-7 message names [CONDITIONAL]" "$(last_notes)" "[CONDITIONAL]"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-13 (B1 guard): out-of-marker Shape A edit NOT silently lost (Regime B) =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m13
cat > "$FIXTURE_BASE/m13/ours.md" <<'MD'
## Sec
pack line PROJECT-EDITED-OUTSIDE-M13
<!-- BEGIN project-owned -->
mine
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m13/theirs.md" <<'MD'
## Sec
pack line
MD
cp "$FIXTURE_BASE/m13/ours.md" "$FIXTURE_BASE/m13/dest.md"
customization_preserve "" "$FIXTURE_BASE/m13/ours.md" "$FIXTURE_BASE/m13/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m13/dest.md" trinity >/dev/null
assert_eq "M-13 disposition needs-reconciliation (not silent merge)" "$NEEDS" "$(last_disp)"
assert_contains "M-13 sidecar preserves the out-of-marker project edit" \
    "$(cat "$FIXTURE_BASE/m13/dest.md.pre-update")" "PROJECT-EDITED-OUTSIDE-M13"
# DEST is the new canonical (project edit preserved in the sidecar, never dropped).
assert_absent "M-13 DEST did NOT silently keep the project's out-of-marker edit" \
    "$(cat "$FIXTURE_BASE/m13/dest.md")" "PROJECT-EDITED-OUTSIDE-M13"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-14 (M1 guard, BASE-AWARE — POQ-1): 3 legs a/b/c =="
# ─────────────────────────────────────────────────────────────────────────
# M-14a — BASE ABSENT + markerless [CONDITIONAL] -> M1 FIRES (fail loud). The
# original M-14 target: a client init --update anomaly / a regressed v11 trinity.
newstate; mk m14a
cat > "$FIXTURE_BASE/m14a/ours.md" <<'MD'
## [CONDITIONAL] iOS platform features
some legacy body
MD
cat > "$FIXTURE_BASE/m14a/theirs.md" <<'MD'
## iOS platform features
pack body
MD
cp "$FIXTURE_BASE/m14a/ours.md" "$FIXTURE_BASE/m14a/dest.md"
customization_preserve "" "$FIXTURE_BASE/m14a/ours.md" "$FIXTURE_BASE/m14a/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m14a/dest.md" trinity >/dev/null
assert_eq "M-14a BASE-absent [CONDITIONAL] -> needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-14a message names [CONDITIONAL] (hoist fired, BASE-absent branch)" \
    "$(last_notes)" "[CONDITIONAL]"

# M-14b — BASE PRESENT + CUSTOMIZED [CONDITIONAL] body (base != ours) -> M1 FIRES.
# The reserved genuine keep/delete case: sidecar + L-9 message; client edit preserved.
newstate; mk m14b
cat > "$FIXTURE_BASE/m14b/base.md" <<'MD'
## [CONDITIONAL] iOS platform features
default v10 body
MD
cat > "$FIXTURE_BASE/m14b/ours.md" <<'MD'
## [CONDITIONAL] iOS platform features
default v10 body CLIENT-CUSTOMIZED-M14B
MD
cat > "$FIXTURE_BASE/m14b/theirs.md" <<'MD'
## iOS platform features
retired v11 body
MD
cp "$FIXTURE_BASE/m14b/ours.md" "$FIXTURE_BASE/m14b/dest.md"
customization_preserve "$FIXTURE_BASE/m14b/base.md" "$FIXTURE_BASE/m14b/ours.md" \
    "$FIXTURE_BASE/m14b/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/m14b/dest.md" trinity >/dev/null
assert_eq "M-14b customized [CONDITIONAL] body -> needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_contains "M-14b message names [CONDITIONAL] (L-9 keep/delete)" "$(last_notes)" "[CONDITIONAL]"
assert_contains "M-14b sidecar preserves the client customization (no silent loss)" \
    "$(cat "$FIXTURE_BASE/m14b/dest.md.pre-update")" "CLIENT-CUSTOMIZED-M14B"

# M-14c — BASE PRESENT + NON-customized (base == ours) -> M1 SILENT -> the
# markerless fallback resolves to pack-update-applied -> adopt THEIRS's already-
# retired canonical: NO sidecar, NO [CONDITIONAL] L-9 disposition. This is the
# POQ-1 regression guard (the spurious-sidecar/pause path).
newstate; mk m14c
cat > "$FIXTURE_BASE/m14c/base.md" <<'MD'
## [CONDITIONAL] iOS platform features
default v10 body
## Keep
pack keep
MD
cp "$FIXTURE_BASE/m14c/base.md" "$FIXTURE_BASE/m14c/ours.md"   # base == ours (untouched v10 default)
cat > "$FIXTURE_BASE/m14c/theirs.md" <<'MD'
## iOS platform features
retired v11 body ADOPTED-M14C
## Keep
pack keep
MD
cp "$FIXTURE_BASE/m14c/ours.md" "$FIXTURE_BASE/m14c/dest.md"
customization_preserve "$FIXTURE_BASE/m14c/base.md" "$FIXTURE_BASE/m14c/ours.md" \
    "$FIXTURE_BASE/m14c/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/m14c/dest.md" trinity >/dev/null
assert_eq "M-14c non-customized [CONDITIONAL] -> pack-update-applied (M1 SILENT)" \
    "pack-update-applied" "$(last_disp)"
assert_eq "M-14c NO sidecar written (no spurious needs-reconciliation)" \
    "no" "$([[ -f "$FIXTURE_BASE/m14c/dest.md.pre-update" ]] && echo yes || echo no)"
assert_contains "M-14c DEST adopted THEIRS's retired canonical" \
    "$(cat "$FIXTURE_BASE/m14c/dest.md")" "retired v11 body ADOPTED-M14C"
assert_absent "M-14c [CONDITIONAL] retired from DEST (delivered by adopting THEIRS)" \
    "$(cat "$FIXTURE_BASE/m14c/dest.md")" "[CONDITIONAL]"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-15 (M2 guard): lone orphan BEGIN (1 token) -> fail loud, NOT swallowed =="
# ─────────────────────────────────────────────────────────────────────────
newstate; mk m15
cat > "$FIXTURE_BASE/m15/ours.md" <<'MD'
## Sec
pack
<!-- BEGIN project-owned -->
mine (never closed)
MD
cat > "$FIXTURE_BASE/m15/theirs.md" <<'MD'
## Sec
pack
MD
# A single orphan BEGIN = 1 marker TOKEN, 0 PAIRS. A zero-PAIRS trigger would
# have swallowed it into the byte-unaware fallback; the zero-TOKEN trigger
# keeps it in the graft where the L-6 gate fails loud.
assert_eq "M-15 token count is 1 (not 0)" "1" "$(_mp_count_tokens "$FIXTURE_BASE/m15/ours.md")"
cp "$FIXTURE_BASE/m15/ours.md" "$FIXTURE_BASE/m15/dest.md"
customization_preserve "" "$FIXTURE_BASE/m15/ours.md" "$FIXTURE_BASE/m15/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m15/dest.md" trinity >/dev/null
assert_eq "M-15 disposition needs-reconciliation" "$NEEDS" "$(last_disp)"
# The L-6 gate message ('unclosed BEGIN') only the graft emits — proves the
# orphan was NOT swallowed by the fallback (which records no such note).
assert_contains "M-15 message from the L-6 gate (unclosed BEGIN)" \
    "$(last_notes)" "unclosed BEGIN marker"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-16 (B1 discriminate, Regime A): 3-way distinguishes project vs pack edit =="
# ─────────────────────────────────────────────────────────────────────────
# (i) project edited pack body outside marker, pack did NOT -> sidecar (safety).
newstate; mk m16i
cat > "$FIXTURE_BASE/m16i/base.md" <<'MD'
## Sec
pack body v1
MD
cat > "$FIXTURE_BASE/m16i/ours.md" <<'MD'
## Sec
pack body v1 PROJECT-TOUCHED
<!-- BEGIN project-owned -->
mine16i
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m16i/theirs.md" <<'MD'
## Sec
pack body v1
MD
cp "$FIXTURE_BASE/m16i/ours.md" "$FIXTURE_BASE/m16i/dest.md"
customization_preserve "$FIXTURE_BASE/m16i/base.md" "$FIXTURE_BASE/m16i/ours.md" \
    "$FIXTURE_BASE/m16i/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/m16i/dest.md" trinity >/dev/null
assert_eq "M-16(i) project-edited body -> needs-reconciliation (safety)" "$NEEDS" "$(last_disp)"

# (ii) pack edited pack body outside marker, project did NOT -> clean merge (value).
newstate; mk m16ii
cat > "$FIXTURE_BASE/m16ii/base.md" <<'MD'
## Sec
pack body v1
MD
cat > "$FIXTURE_BASE/m16ii/ours.md" <<'MD'
## Sec
pack body v1
<!-- BEGIN project-owned -->
mine16ii
<!-- END project-owned -->
MD
# theirs has NO project markers (pack canonical); body updated by pack.
cat > "$FIXTURE_BASE/m16ii/theirs.md" <<'MD'
## Sec
pack body v2-PACK-UPDATED
MD
cp "$FIXTURE_BASE/m16ii/ours.md" "$FIXTURE_BASE/m16ii/dest.md"
customization_preserve "$FIXTURE_BASE/m16ii/base.md" "$FIXTURE_BASE/m16ii/ours.md" \
    "$FIXTURE_BASE/m16ii/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/m16ii/dest.md" trinity >/dev/null
d16=$(cat "$FIXTURE_BASE/m16ii/dest.md")
assert_eq "M-16(ii) pack-edited body -> merged-with-customization (value)" \
    "merged-with-customization" "$(last_disp)"
assert_contains "M-16(ii) adopted the updated pack body" "$d16" "pack body v2-PACK-UPDATED"
assert_contains "M-16(ii) project marker region byte-identical" "$d16" "mine16ii"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-17 (BLOCKER-1a): marker-bearing THEIRS — UNCHANGED trinity, seed pair BOTH sides =="
# ─────────────────────────────────────────────────────────────────────────
# The pack ships an empty seed pair under `## Project addenda` (O-5/V-4). On
# init --update (base="", theirs = the SEEDED pack trinity), an UNCHANGED client
# trinity (ours == theirs, both carry the seed pair) MUST classify clean with NO
# sidecar — an asymmetric OURS-stripped-vs-THEIRS-unstripped compare would
# spuriously sidecar 100% of clients on every update.
newstate; mk m17
cat > "$FIXTURE_BASE/m17/theirs.md" <<'MD'
## Rules
pack rules body
## Project addenda

<!-- Project addenda go here. See docs/pack/PM-CHAT.md. -->
<!-- BEGIN project-owned -->
<!-- END project-owned -->
MD
cp "$FIXTURE_BASE/m17/theirs.md" "$FIXTURE_BASE/m17/ours.md"   # unchanged: ours == theirs
cp "$FIXTURE_BASE/m17/ours.md" "$FIXTURE_BASE/m17/dest.md"
customization_preserve "" "$FIXTURE_BASE/m17/ours.md" "$FIXTURE_BASE/m17/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m17/dest.md" trinity >/dev/null
assert_eq "M-17 unchanged seeded trinity -> unchanged-pack (clean)" "unchanged-pack" "$(last_disp)"
assert_eq "M-17 NO spurious sidecar on init --update" \
    "no" "$([[ -f "$FIXTURE_BASE/m17/dest.md.pre-update" ]] && echo yes || echo no)"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-18 (BLOCKER-1b): seed-with-content, pack body unchanged (Regime B) =="
# ─────────────────────────────────────────────────────────────────────────
# The client did exactly what the authoring docs say — wrapped an addendum in
# the shipped seed markers, pack body otherwise unchanged. Result MUST be a
# clean merge with the content preserved IN the markers in DEST, NO sidecar,
# and NO doubled marker pair (the empty seed pair must not be re-emitted).
newstate; mk m18
cat > "$FIXTURE_BASE/m18/theirs.md" <<'MD'
## Rules
pack rules body
## Project addenda

<!-- Project addenda go here. See docs/pack/PM-CHAT.md. -->
<!-- BEGIN project-owned -->
<!-- END project-owned -->
MD
cat > "$FIXTURE_BASE/m18/ours.md" <<'MD'
## Rules
pack rules body
## Project addenda

<!-- Project addenda go here. See docs/pack/PM-CHAT.md. -->
<!-- BEGIN project-owned -->
MY-PROJECT-ADDENDUM
<!-- END project-owned -->
MD
cp "$FIXTURE_BASE/m18/ours.md" "$FIXTURE_BASE/m18/dest.md"
customization_preserve "" "$FIXTURE_BASE/m18/ours.md" "$FIXTURE_BASE/m18/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m18/dest.md" trinity >/dev/null
d18=$(cat "$FIXTURE_BASE/m18/dest.md")
assert_eq "M-18 seed-with-content -> merged-with-customization (clean)" \
    "merged-with-customization" "$(last_disp)"
assert_eq "M-18 NO sidecar (marker content preserved in place)" \
    "no" "$([[ -f "$FIXTURE_BASE/m18/dest.md.pre-update" ]] && echo yes || echo no)"
assert_contains "M-18 client addendum preserved inside markers in DEST" "$d18" "MY-PROJECT-ADDENDUM"
assert_eq "M-18 exactly ONE seed pair in DEST (empty seed NOT doubled)" \
    "1" "$(grep -c 'BEGIN project-owned' "$FIXTURE_BASE/m18/dest.md")"

# ─────────────────────────────────────────────────────────────────────────
echo "== M-19 (BLOCKER-2): preamble / empty-host marker region -> FAIL LOUD (no silent loss) =="
# ─────────────────────────────────────────────────────────────────────────
# A project marker region ABOVE the first `## ` heading has no H2/H3 host — it
# is neither Shape A (needs a section) nor Shape B (needs an owned heading). It
# MUST fail loud (needs-reconciliation, content preserved in the sidecar), NEVER
# be silently dropped under a merged-with-customization disposition (L-8).
newstate; mk m19
cat > "$FIXTURE_BASE/m19/ours.md" <<'MD'
pack preamble line
<!-- BEGIN project-owned -->
MY-PREAMBLE-CONTENT-DO-NOT-LOSE
<!-- END project-owned -->
## Rules
pack rules body
MD
cat > "$FIXTURE_BASE/m19/theirs.md" <<'MD'
pack preamble line
## Rules
pack rules body
MD
cp "$FIXTURE_BASE/m19/ours.md" "$FIXTURE_BASE/m19/dest.md"
customization_preserve "" "$FIXTURE_BASE/m19/ours.md" "$FIXTURE_BASE/m19/theirs.md" \
    "CLAUDE.md" "$FIXTURE_BASE/m19/dest.md" trinity >/dev/null
assert_eq "M-19 preamble marker region -> needs-reconciliation (fail loud, NOT silent merge)" \
    "$NEEDS" "$(last_disp)"
assert_contains "M-19 message names the unsupported placement (no enclosing H2)" \
    "$(last_notes)" "no enclosing H2"
assert_contains "M-19 project content preserved in the sidecar (no silent loss)" \
    "$(cat "$FIXTURE_BASE/m19/dest.md.pre-update")" "MY-PREAMBLE-CONTENT-DO-NOT-LOSE"

# ─────────────────────────────────────────────────────────────────────────
echo "== Fence S2: merger-side classification of the shared fixture =="
# ─────────────────────────────────────────────────────────────────────────
if [[ -f "$FENCE_FX/EXPECTED-TOKENS.tsv" ]]; then
    while IFS=$'\t' read -r fname expected; do
        case "$fname" in ''|'#'*) continue ;; esac
        got=$(_mp_count_tokens "$FENCE_FX/$fname")
        assert_eq "Fence $fname real-token count == $expected" "$expected" "$got"
    done < "$FENCE_FX/EXPECTED-TOKENS.tsv"
else
    fail "Fence fixture EXPECTED-TOKENS.tsv present"
fi

# ─────────────────────────────────────────────────────────────────────────
echo "== Legacy: markerless + fenced-only trinity behavior =="
# ─────────────────────────────────────────────────────────────────────────
# A markerless project-edited trinity still surfaces needs-reconciliation
# (Check 25 parity — the no-marker fallback preserves legacy behavior).
newstate; mk leg
printf '%s\n' "## Sec" "pack v1" > "$FIXTURE_BASE/leg/base.md"
printf '%s\n' "## Sec" "pack v1 PROJECT" > "$FIXTURE_BASE/leg/ours.md"
printf '%s\n' "## Sec" "pack v2" > "$FIXTURE_BASE/leg/theirs.md"
cp "$FIXTURE_BASE/leg/ours.md" "$FIXTURE_BASE/leg/dest.md"
customization_preserve "$FIXTURE_BASE/leg/base.md" "$FIXTURE_BASE/leg/ours.md" \
    "$FIXTURE_BASE/leg/theirs.md" "CLAUDE.md" "$FIXTURE_BASE/leg/dest.md" trinity >/dev/null
assert_eq "Legacy markerless edited trinity -> needs-reconciliation" "$NEEDS" "$(last_disp)"
assert_eq "Legacy markerless keeps class=trinity" "trinity" "$(last_class)"

# A benign markerless trinity (base==ours==theirs) stays unchanged-pack — the
# fallback does NOT force every trinity to reconcile.
newstate; mk leg2
printf '%s\n' "## Sec" "same" > "$FIXTURE_BASE/leg2/f.md"
cp "$FIXTURE_BASE/leg2/f.md" "$FIXTURE_BASE/leg2/dest.md"
customization_preserve "$FIXTURE_BASE/leg2/f.md" "$FIXTURE_BASE/leg2/f.md" \
    "$FIXTURE_BASE/leg2/f.md" "CLAUDE.md" "$FIXTURE_BASE/leg2/dest.md" trinity >/dev/null
assert_eq "Legacy benign markerless trinity -> unchanged-pack" "unchanged-pack" "$(last_disp)"

# A trinity whose ONLY markers are inside a fence is treated as markerless
# (fence-aware M2 trigger): 0 real tokens -> fallback -> unchanged-pack here.
newstate; mk leg3
cat > "$FIXTURE_BASE/leg3/f.md" <<'MD'
## Sec
pack body
```
<!-- BEGIN project-owned -->
illustrative only
<!-- END project-owned -->
```
MD
assert_eq "Fenced-only markers -> 0 real tokens" "0" "$(_mp_count_tokens "$FIXTURE_BASE/leg3/f.md")"
cp "$FIXTURE_BASE/leg3/f.md" "$FIXTURE_BASE/leg3/dest.md"
customization_preserve "$FIXTURE_BASE/leg3/f.md" "$FIXTURE_BASE/leg3/f.md" \
    "$FIXTURE_BASE/leg3/f.md" "CLAUDE.md" "$FIXTURE_BASE/leg3/dest.md" trinity >/dev/null
assert_eq "Fenced-only markers routed through fallback -> unchanged-pack" \
    "unchanged-pack" "$(last_disp)"

# ─────────────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
