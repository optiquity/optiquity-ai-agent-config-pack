#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/fixture-dependent/test-customization-preserve-bd136.sh —
# BD-136 Commit C9: the FIXTURE / Check-91 integration legs of the trinity
# marker-section preservation suite. The pure-merger legs (M-1..M-7,
# M-13..M-19 + fence S2 + legacy) live in the plain
# scripts/tests/test-marker-preserve-bd136.sh (committed at C1); the
# Check-91 validator legs (V-1..V-8) live in
# scripts/tests/test-validate-pack-check-91.sh (C5). This file carries only
# the legs that HARD-need built fixtures / Check 91 / the full migrator, so
# it is auto-pinned into the fixture-dependent CI shard by its location.
#
# Legs (BD-136 spec M-8/M-9/M-10/M-11/M-12 + the ratified OI-A assertion):
#
#   M-8   OT-derived golden CLEAN round-trip. Feeds the committed real-world
#         golden test-fixtures/v11-trinity-marker-prepped/ (all three trinity
#         files) through the FINAL hardened marker-aware merger and proves the
#         OT customizations round-trip CLEANLY: disposition
#         merged-with-customization, NO `.pre-update` sidecar, every project
#         marker region preserved byte-identical, the renamed-from overrides
#         suppress their canonical counterparts (no duplicate H2), and no
#         `[CONDITIONAL]` leaks. Under BD-136 C9b the fixture's one preamble
#         project-owned marker (a repository-overview intro with no enclosing
#         H2/H3 — a placement the merger's BLOCKER-2 / L-8 gate rejects) was
#         relocated to a valid `### Repository overview` H3 at the head of the
#         `## Project addenda` seed, so the golden now conforms to the shipped
#         Shape A / Shape B rules. THEIRS is a drift-free "new pack canonical"
#         stand-in synthesized from OURS (see the leg's inline construction
#         note) so the frozen fixture never conflicts on live-pack drift.
#   M-9   `renamed-from` override, BASE-aware (L-10 / O-9): a renamed-from
#         naming a live canonical suppresses it (merged); a renamed-from with
#         no canonical match soft-classifies by BASE — retirement (BASE had
#         it) is a benign no-op, typo (BASE lacked it) is a hard conflict,
#         BASE-absent is a conservative conflict naming the retirement
#         possibility.
#   M-10  `## Project addenda` seed-slot exception: a seed Shape A body with
#         N=5 project H3 subsections passes Check 91 AND the merger preserves
#         the body byte-identical (merged-with-customization, no sidecar);
#         a NON-addenda Shape A pair containing an H3 fails loud in BOTH the
#         merger (needs-reconciliation) and Check 91 (the exception is
#         narrowly scoped to `## Project addenda`).
#   M-11  fresh-init flow (SETUP-NEW.md path): a v11-flat-file-derived
#         project customized per BD-136 (seed H3 + Shape A body extension +
#         Shape B project-original section) preserves every customization
#         byte-identical across `init-project.sh --update`, zero manual
#         reconciliation.
#   M-12  existing-project-adoption flow (SETUP-EXISTING.md path): an
#         existing-project-mid-dev-derived project that had the pack freshly
#         installed and then a pack section overridden via a same-H2-name
#         Shape B wrap preserves the override across `init --update` and
#         suppresses the pack copy (no duplicate H2).
#   OI-A  a NORMAL (uncustomized) v10→v11 migration's migrated trinity is
#         `[CONDITIONAL]`-free — now that C4 retired the literal in the pack
#         trinity, the migrator adopts THEIRS's already-retired canonical.
#         (The assertion the C1b no-sidecar lock deliberately deferred.)
#
# Portability (BD-276): scratch trees use the portable full-template form
# `mktemp -d "${TMPDIR:-/tmp}/<prefix>.XXXXXX"` — never `mktemp -d -t
# prefix.XXXXXX`, which leaves a literal XXXXXX on BSD/macOS.
#
# Usage:    bash scripts/tests/fixture-dependent/test-customization-preserve-bd136.sh
# Exit 0 on all pass; exit 1 on any failure; exit 3 on a missing built fixture.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/tests/fixture-dependent/ → pack root is three levels up (BD-219
# location-based fixture cohesion).
PACK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="$PACK_ROOT"
LIB_DIR="$PACK_ROOT/scripts/lib"
INIT_SH="$PACK_ROOT/scripts/init-project.sh"
MIGRATE_SH="$PACK_ROOT/scripts/migrate-v10-to-v11.sh"
GOLDEN_FX="$PACK_ROOT/test-fixtures/v11-trinity-marker-prepped"

# ── BD-163 fixture-precondition helper ─────────────────────────────────────
# A built fixture is a git repo (build.sh inits one), so `.git/HEAD` is the
# canonical built-fixture marker. Fail fast with the exact build command.
require_fixture() {
    local name="${1:?require_fixture: missing <name>}"
    local fx="$PACK_ROOT/test-fixtures/$name"
    if [[ ! -d "$fx" || ! -f "$fx/.git/HEAD" ]]; then
        printf 'ERROR: %s requires test-fixtures/%s/ but it does not exist or is not a built fixture.\n' \
            "$(basename "${BASH_SOURCE[1]:-$0}")" "$name" >&2
        printf '       Build it with: bash test-fixtures/build.sh --name %s\n' "$name" >&2
        printf '       (or build all fixtures: bash test-fixtures/build.sh --all --clean)\n' >&2
        exit 3
    fi
}

# BD-276 portable full-template mktemp.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/bd136-c9.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

passes=0
fails=0
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1" >&2
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2" >&2
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3" >&2
    fails=$((fails + 1))
}
assert_eq()       { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then pass "$1"; else fail "$1" "contains '$3'" "$2"; fi; }
assert_absent()   { if [[ "$2" != *"$3"* ]]; then pass "$1"; else fail "$1" "absent '$3'" "$2"; fi; }
file_present()    { [[ -f "$1" ]] && echo yes || echo no; }

# ── Merger harness (sources the same libs init --update / the migrator use) ─
# shellcheck disable=SC1091
source "$LIB_DIR/three-way.sh"
export _CP_PACK_ROOT="$PACK_ROOT"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-preserve.sh"
if ! declare -F marker_preserve_trinity >/dev/null 2>&1; then
    echo "FATAL: marker_preserve_trinity not sourced (customization-preserve.sh must source marker-preserve.sh)" >&2
    exit 2
fi

STATE="$WORK/state"
newstate() { rm -rf "$STATE"; customization_preserve_init "$STATE" ".pre-update" >/dev/null; }
last_col()  { tail -1 "$STATE/dispositions.tsv" | awk -F'\t' -v c="$1" '{print $c}'; }
last_disp() { last_col 1; }
last_notes(){ last_col 7; }
NEEDS="customization-detected-needs-reconciliation"

# Count Check 91 (trinity_markers) failures against a trinity dir. Echoes an
# integer. Uses the SAME validator entry the pack registers as Check 91.
check91_fail_count() {
    REPO_ROOT="$REPO_ROOT" TRIN="$1" python3 - <<'PY'
import os, sys, io, contextlib, pathlib
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "scripts", "lib"))
from validate_checks import trinity_markers as tm
from validate_checks import core
saved = list(core.failures); core.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        tm.check_trinity_marker_wellformed(pathlib.Path(os.environ["TRIN"]), "scratch")
    n = len(core.failures)
finally:
    core.failures.clear(); core.failures.extend(saved)
print(n)
PY
}

# Write $2 as all three trinity files under a fresh dir; echo the dir.
mk_trinity_dir() {
    local d; d="$(mktemp -d "$WORK/trin.XXXXXX")"
    printf '%s' "$2" > "$d/CLAUDE.md"
    printf '%s' "$2" > "$d/AGENTS.md"
    printf '%s' "$2" > "$d/GEMINI.md"
    printf '%s\n' "$d"
}

# ═══════════════════════════════════════════════════════════════════════════
echo "== M-8: OT golden fixture CLEAN round-trip (test-fixtures/v11-trinity-marker-prepped) =="
# ═══════════════════════════════════════════════════════════════════════════
# The committed real-world golden. It is NOT a build.sh fixture (a frozen
# snapshot), so assert the files directly rather than via require_fixture.
#
# THEIRS = a drift-free "new pack canonical" stand-in synthesized from OURS so
# it tracks the frozen fixture (the LIVE pack trinity has drifted since the
# 2026-05-10 capture and would spuriously conflict on out-of-marker pack body).
# Construction (m8_build_theirs): strip each Shape A project block IN PLACE
# (keep the pack heading + out-of-marker body); REPLACE each whole-section
# Shape B block with a `## ` pack stub section — using the renamed-from OLD
# canonical name(s) where the region carries them (so the project override
# SUPPRESSES its canonical counterpart, proving the fixture's stated
# no-duplicate-H2 assertion) else the owned heading. Replacing (not dropping)
# whole-section Shape B blocks preserves the adjacent pack sections' boundaries
# so every OURS pack section reconciles cleanly under Regime B (BASE="").
m8_build_theirs() {   # $1=ours  $2=out-theirs
    local manifest; manifest="$(_mp_regions "$1")"
    M8_MANIFEST="$manifest" python3 - "$1" "$2" <<'PY'
import os, sys, re
ours = open(sys.argv[1]).read().split("\n")
by_begin = {}
for row in os.environ["M8_MANIFEST"].split("\n"):
    if not row.startswith("REGION"):
        continue
    _, shape, head, b, e, beginraw = row.split("\t", 5)
    rf = re.findall(r'"([^"]*)"', beginraw) if "renamed-from" in beginraw else []
    by_begin[int(b)] = (shape, head, int(e), rf)
def stub(h):
    return [h, "", "Pack canonical body for %s (drift-free stand-in)." % h.lstrip("# ").strip(), ""]
res, i, n = [], 1, len(ours)
while i <= n:
    if i in by_begin:
        shape, head, e, rf = by_begin[i]
        if shape == "B":                       # Shape A: drop inner block (pass)
            for name in (rf if rf else [head]):
                res.extend(stub(name))
        i = e + 1
    else:
        res.append(ours[i-1]); i += 1
open(sys.argv[2], "w").write("\n".join(res))
PY
}

# Count OURS marker regions whose EXACT byte block is NOT present in DEST — the
# rigorous "byte-identical project content" gate (the graft re-emits each region
# verbatim via _mp_lines, so a clean round-trip preserves every region). 0 = all.
m8_regions_missing() {   # $1=ours  $2=dest
    local manifest; manifest="$(_mp_regions "$1")"
    M8_MANIFEST="$manifest" python3 - "$1" "$2" <<'PY'
import os, sys
ours = open(sys.argv[1]).read().split("\n")
dest = open(sys.argv[2]).read()
missing = 0
for row in os.environ["M8_MANIFEST"].split("\n"):
    if not row.startswith("REGION"):
        continue
    _, shape, head, b, e, beginraw = row.split("\t", 5)
    block = "\n".join(ours[int(b)-1:int(e)])
    if block not in dest:
        missing += 1
print(missing)
PY
}

if [[ ! -f "$GOLDEN_FX/CLAUDE.md" ]]; then
    fail "M-8 golden fixture present ($GOLDEN_FX/CLAUDE.md)"
else
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        newstate
        m8_build_theirs "$GOLDEN_FX/$f" "$WORK/m8-theirs-$f"
        cp "$GOLDEN_FX/$f" "$WORK/m8-dest-$f"
        customization_preserve "" "$GOLDEN_FX/$f" "$WORK/m8-theirs-$f" \
            "$f" "$WORK/m8-dest-$f" trinity >/dev/null
        # The re-prepped golden has every marker legally hosted → CLEAN merge.
        assert_eq "M-8 [$f] clean round-trip -> merged-with-customization" \
            "merged-with-customization" "$(last_disp)"
        assert_eq "M-8 [$f] writes NO sidecar (zero manual reconciliation)" \
            "no" "$(file_present "$WORK/m8-dest-$f.pre-update")"
        assert_eq "M-8 [$f] no [CONDITIONAL] leaks into the merged canonical" \
            "0" "$(grep -c 'CONDITIONAL' "$WORK/m8-dest-$f")"
        # Every project marker region survives BYTE-IDENTICAL in DEST.
        assert_eq "M-8 [$f] all project marker regions preserved byte-identical in DEST" \
            "0" "$(m8_regions_missing "$GOLDEN_FX/$f" "$WORK/m8-dest-$f")"
        # renamed-from override suppresses its canonical counterpart (no dup H2).
        assert_eq "M-8 [$f] renamed override heading present exactly once" \
            "1" "$(grep -c '^## Xcode 26.4 platform features' "$WORK/m8-dest-$f")"
        assert_eq "M-8 [$f] old canonical heading fully suppressed (no duplicate H2)" \
            "0" "$(grep -c '^## iOS 26 / Xcode 26.3 platform features' "$WORK/m8-dest-$f")"
    done
    # The relocated preamble intro (now a Project-addenda H3) survives verbatim.
    assert_contains "M-8 relocated repository-overview intro preserved (CLAUDE)" \
        "$(cat "$WORK/m8-dest-CLAUDE.md")" "algorithmic trading prototype"
    assert_contains "M-8 relocated intro is a '### Repository overview' H3 (CLAUDE)" \
        "$(cat "$WORK/m8-dest-CLAUDE.md")" "### Repository overview"
    # The renamed-from override annotations (2 per file) are grafted verbatim.
    assert_eq "M-8 renamed-from annotations preserved in the merged CLAUDE trinity" \
        "2" "$(grep -c 'renamed-from' "$WORK/m8-dest-CLAUDE.md")"
fi

# ═══════════════════════════════════════════════════════════════════════════
echo "== M-9: renamed-from override, BASE-aware soft-classify (L-10 / O-9) =="
# ═══════════════════════════════════════════════════════════════════════════
# M-9a positive: renamed-from names a LIVE canonical → suppress it (merged).
newstate
cat > "$WORK/m9a-ours.md" <<'MD'
<!-- BEGIN project-owned: renamed-from "## Old Canonical" -->
## Project Renamed
PROJ-BODY-M9A
<!-- END project-owned -->
MD
cat > "$WORK/m9a-theirs.md" <<'MD'
## Old Canonical
pack old body
## Keep
pack keep
MD
cp "$WORK/m9a-ours.md" "$WORK/m9a-dest.md"
customization_preserve "" "$WORK/m9a-ours.md" "$WORK/m9a-theirs.md" \
    "CLAUDE.md" "$WORK/m9a-dest.md" trinity >/dev/null
m9a=$(cat "$WORK/m9a-dest.md")
assert_eq "M-9a renamed-from override -> merged-with-customization" \
    "merged-with-customization" "$(last_disp)"
assert_contains "M-9a project override body byte-identical"        "$m9a" "PROJ-BODY-M9A"
assert_absent  "M-9a suppressed pack canonical body gone"          "$m9a" "pack old body"
assert_contains "M-9a non-overridden pack section kept"            "$m9a" "pack keep"

# M-9b negative BASE-ABSENT: renamed-from names a non-existent canonical,
# base="" → conservative conflict naming the retirement possibility (O-9).
newstate
cat > "$WORK/m9b-ours.md" <<'MD'
<!-- BEGIN project-owned: renamed-from "## Ghost Section" -->
## Project Renamed
body
<!-- END project-owned -->
## Keep
pack keep
MD
cat > "$WORK/m9b-theirs.md" <<'MD'
## Keep
pack keep
MD
cp "$WORK/m9b-ours.md" "$WORK/m9b-dest.md"
customization_preserve "" "$WORK/m9b-ours.md" "$WORK/m9b-theirs.md" \
    "CLAUDE.md" "$WORK/m9b-dest.md" trinity >/dev/null
assert_eq "M-9b BASE-absent renamed-from-no-match -> needs-reconciliation" \
    "$NEEDS" "$(last_disp)"
assert_contains "M-9b message names the RETIRED-or-MISTYPED ambiguity (BASE-absent)" \
    "$(last_notes)" "RETIRED"

# M-9c negative BASE-PRESENT typo: BASE lacks the ghost → hard typo conflict.
newstate
cat > "$WORK/m9c-base.md" <<'MD'
## Keep
pack keep
MD
cat > "$WORK/m9c-ours.md" <<'MD'
<!-- BEGIN project-owned: renamed-from "## Ghost Section" -->
## Project Renamed
body
<!-- END project-owned -->
## Keep
pack keep
MD
cat > "$WORK/m9c-theirs.md" <<'MD'
## Keep
pack keep
MD
cp "$WORK/m9c-ours.md" "$WORK/m9c-dest.md"
customization_preserve "$WORK/m9c-base.md" "$WORK/m9c-ours.md" "$WORK/m9c-theirs.md" \
    "CLAUDE.md" "$WORK/m9c-dest.md" trinity >/dev/null
assert_eq "M-9c BASE-present typo (absent from BOTH) -> needs-reconciliation" \
    "$NEEDS" "$(last_disp)"
assert_contains "M-9c message names the likely typo (L-10)" \
    "$(last_notes)" "likely a typo"

# M-9d retirement no-op: BASE HAD the ghost, THEIRS dropped it → benign merge.
newstate
cat > "$WORK/m9d-base.md" <<'MD'
## Ghost Section
v10 body
## Keep
pack keep
MD
cat > "$WORK/m9d-ours.md" <<'MD'
<!-- BEGIN project-owned: renamed-from "## Ghost Section" -->
## Project Renamed
RETAINED-BODY-M9D
<!-- END project-owned -->
## Keep
pack keep
MD
cat > "$WORK/m9d-theirs.md" <<'MD'
## Keep
pack keep
MD
cp "$WORK/m9d-ours.md" "$WORK/m9d-dest.md"
customization_preserve "$WORK/m9d-base.md" "$WORK/m9d-ours.md" "$WORK/m9d-theirs.md" \
    "CLAUDE.md" "$WORK/m9d-dest.md" trinity >/dev/null
assert_eq "M-9d retirement (BASE had it, THEIRS dropped it) -> merged (benign no-op)" \
    "merged-with-customization" "$(last_disp)"
assert_contains "M-9d project body preserved byte-identical" \
    "$(cat "$WORK/m9d-dest.md")" "RETAINED-BODY-M9D"

# ═══════════════════════════════════════════════════════════════════════════
echo "== M-10: Project addenda seed-slot exception (merger + Check 91) =="
# ═══════════════════════════════════════════════════════════════════════════
# POSITIVE — `## Project addenda` Shape A body with N=5 project H3 subsections.
M10_SEED_H3='## Project addenda

<!-- Project addenda go here. This heading is pack-owned. -->
<!-- BEGIN project-owned -->
### Sub one
body one
### Sub two
body two
### Sub three
body three
### Sub four
body four
### Sub five
body five
<!-- END project-owned -->
'
# (a) Check 91 passes on the seed-slot H3 trinity.
m10p_dir="$(mk_trinity_dir CLAUDE "$M10_SEED_H3")"
assert_eq "M-10 Check 91 PASSES on the seed-slot H3 trinity (0 failures)" \
    "0" "$(check91_fail_count "$m10p_dir")"
# (b) the merger preserves the entire seed body byte-identical.
newstate
printf '%s' "$M10_SEED_H3" > "$WORK/m10p-ours.md"
cat > "$WORK/m10p-theirs.md" <<'MD'
## Project addenda

<!-- Project addenda go here. This heading is pack-owned. -->
<!-- BEGIN project-owned -->
<!-- END project-owned -->
MD
cp "$WORK/m10p-ours.md" "$WORK/m10p-dest.md"
customization_preserve "" "$WORK/m10p-ours.md" "$WORK/m10p-theirs.md" \
    "CLAUDE.md" "$WORK/m10p-dest.md" trinity >/dev/null
assert_eq "M-10 positive merger -> merged-with-customization" \
    "merged-with-customization" "$(last_disp)"
assert_eq "M-10 all 5 project H3 subsections preserved byte-identical in DEST" \
    "5" "$(grep -c '^### Sub ' "$WORK/m10p-dest.md")"
assert_eq "M-10 positive writes NO sidecar (clean, zero reconciliation)" \
    "no" "$(file_present "$WORK/m10p-dest.md.pre-update")"

# NEGATIVE — a NON-addenda Shape A pair containing an H3 fails loud in BOTH
# the merger and Check 91 (the exception is narrowly scoped to Project addenda).
M10_BAD='## Regular Section
pack body
<!-- BEGIN project-owned -->
body first
### Sneaky H3
<!-- END project-owned -->

## Project addenda

<!-- Project addenda go here. -->
<!-- BEGIN project-owned -->
<!-- END project-owned -->
'
m10n_dir="$(mk_trinity_dir CLAUDE "$M10_BAD")"
n_bad="$(check91_fail_count "$m10n_dir")"
assert_eq "M-10 negative: Check 91 FAILS on a non-addenda Shape A H3 (>=1 failure)" \
    "yes" "$([[ "$n_bad" -ge 1 ]] && echo yes || echo no)"
newstate
printf '%s' "$M10_BAD" > "$WORK/m10n-ours.md"
cat > "$WORK/m10n-theirs.md" <<'MD'
## Regular Section
pack body
## Project addenda

<!-- Project addenda go here. -->
<!-- BEGIN project-owned -->
<!-- END project-owned -->
MD
cp "$WORK/m10n-ours.md" "$WORK/m10n-dest.md"
customization_preserve "" "$WORK/m10n-ours.md" "$WORK/m10n-theirs.md" \
    "CLAUDE.md" "$WORK/m10n-dest.md" trinity >/dev/null
assert_eq "M-10 negative merger fails loud -> needs-reconciliation" \
    "$NEEDS" "$(last_disp)"
assert_contains "M-10 negative names the heading-inside-Shape-A defect" \
    "$(last_notes)" "heading inside a Shape A region"

# ═══════════════════════════════════════════════════════════════════════════
echo "== M-11: fresh-init (v11-flat-file) + customize + init --update preserves =="
# ═══════════════════════════════════════════════════════════════════════════
require_fixture "v11-flat-file"
m11="$WORK/m11/proj"
mkdir -p "$WORK/m11"
cp -R "$PACK_ROOT/test-fixtures/v11-flat-file" "$m11"
rm -rf "$m11/.git"
git init -q "$m11"; git -C "$m11" config user.email t@e; git -C "$m11" config user.name t
git -C "$m11" add -A >/dev/null; git -C "$m11" commit -q -m base 2>/dev/null

# Customize CLAUDE.md per BD-136 in SUPPORTED placements (pack body untouched):
#   (1) fill the seed pair with an H3 addendum;
#   (2) a Shape A body extension INSIDE a real pack section;
#   (3) a Shape B project-original section placed BEFORE `## Project addenda`.
M11="$m11" python3 - <<'PY'
import os
p = os.path.join(os.environ["M11"], "CLAUDE.md")
s = open(p).read()
s = s.replace(
    "<!-- BEGIN project-owned -->\n<!-- END project-owned -->",
    "<!-- BEGIN project-owned -->\n### My addendum\nPROJ-ADDENDUM-M11\n<!-- END project-owned -->", 1)
lines = s.split("\n")
addenda = next(i for i, l in enumerate(lines) if l.startswith("## Project addenda"))
lines[addenda:addenda] = ["<!-- BEGIN project-owned -->", "## My Project Notes",
                          "SHAPE-B-M11", "<!-- END project-owned -->"]
h2 = [i for i, l in enumerate(lines) if l.startswith("## ")]
ins = h2[2]                      # end of the 2nd pack section body (strictly in-section)
lines[ins:ins] = ["<!-- BEGIN project-owned -->", "SHAPE-A-EXT-M11", "<!-- END project-owned -->"]
open(p, "w").write("\n".join(lines))
PY
git -C "$m11" add -A >/dev/null; git -C "$m11" commit -q -m customize 2>/dev/null

PACK="$PACK_ROOT" bash "$INIT_SH" --update "$m11" > "$WORK/m11-update.log" 2>&1
m11rc=$?
assert_eq "M-11 init --update exits 0" "0" "$m11rc"
m11disp=$(awk -F'\t' '$2=="trinity" && $3=="CLAUDE.md"{print $1}' \
    "$m11/.pack-update/dispositions.tsv" 2>/dev/null)
assert_eq "M-11 customized CLAUDE.md -> merged-with-customization (clean)" \
    "merged-with-customization" "$m11disp"
m11c="$(cat "$m11/CLAUDE.md")"
assert_contains "M-11 seed H3 addendum preserved"          "$m11c" "PROJ-ADDENDUM-M11"
assert_contains "M-11 Shape A body extension preserved"    "$m11c" "SHAPE-A-EXT-M11"
assert_contains "M-11 Shape B project section preserved"   "$m11c" "SHAPE-B-M11"
assert_contains "M-11 seed H3 heading preserved"           "$m11c" "### My addendum"
assert_eq "M-11 no sidecar (zero manual reconciliation)" \
    "no" "$(file_present "$m11/CLAUDE.md.pre-update")"

# ═══════════════════════════════════════════════════════════════════════════
echo "== M-12: existing-project adoption + Shape B override + init --update =="
# ═══════════════════════════════════════════════════════════════════════════
require_fixture "existing-project-mid-dev"
m12="$WORK/m12/proj"
mkdir -p "$WORK/m12"
cp -R "$PACK_ROOT/test-fixtures/existing-project-mid-dev" "$m12"
rm -rf "$m12/.git"
git init -q "$m12"; git -C "$m12" config user.email t@e; git -C "$m12" config user.name t
git -C "$m12" add -A >/dev/null; git -C "$m12" commit -q -m base 2>/dev/null
# Adoption: fresh pack install into the existing project (creates the trinity).
PACK="$PACK_ROOT" bash "$INIT_SH" "$m12" <<<"y" > "$WORK/m12-install.log" 2>&1
m12irc=$?
assert_eq "M-12 fresh pack install (adoption) exits 0" "0" "$m12irc"
assert_eq "M-12 trinity installed" "yes" "$(file_present "$m12/CLAUDE.md")"
git -C "$m12" add -A >/dev/null; git -C "$m12" commit -q -m installed 2>/dev/null

# The PM chat overrides a pack section via a same-H2-name Shape B wrap.
M12_OVR=$(grep -m2 '^## ' "$m12/CLAUDE.md" | tail -1)
M12="$m12" M12_OVR="$M12_OVR" python3 - <<'PY'
import os
p = os.path.join(os.environ["M12"], "CLAUDE.md")
ovr = os.environ["M12_OVR"]
lines = open(p).read().split("\n")
i = next(k for k, l in enumerate(lines) if l.strip() == ovr)
j = i + 1
while j < len(lines) and not lines[j].startswith("## "):
    j += 1
lines[i:j] = ["<!-- BEGIN project-owned -->", ovr, "OVERRIDE-BODY-M12", "<!-- END project-owned -->"]
open(p, "w").write("\n".join(lines))
PY
git -C "$m12" add -A >/dev/null; git -C "$m12" commit -q -m override 2>/dev/null

PACK="$PACK_ROOT" bash "$INIT_SH" --update "$m12" > "$WORK/m12-update.log" 2>&1
m12rc=$?
assert_eq "M-12 init --update exits 0" "0" "$m12rc"
m12disp=$(awk -F'\t' '$2=="trinity" && $3=="CLAUDE.md"{print $1}' \
    "$m12/.pack-update/dispositions.tsv" 2>/dev/null)
assert_eq "M-12 overridden CLAUDE.md -> merged-with-customization (clean)" \
    "merged-with-customization" "$m12disp"
m12c="$(cat "$m12/CLAUDE.md")"
assert_contains "M-12 Shape B override body preserved" "$m12c" "OVERRIDE-BODY-M12"
assert_eq "M-12 override heading appears exactly once (pack copy suppressed, no dup H2)" \
    "1" "$(grep -cF "$M12_OVR" "$m12/CLAUDE.md")"
assert_eq "M-12 no sidecar (override respected cleanly)" \
    "no" "$(file_present "$m12/CLAUDE.md.pre-update")"

# ═══════════════════════════════════════════════════════════════════════════
echo "== OI-A: a normal v10->v11 migration's migrated trinity is [CONDITIONAL]-free =="
# ═══════════════════════════════════════════════════════════════════════════
# Build a v10-shaped target from the actual v10 tag (base==ours: an untouched
# v10 default). After C4 retired the literal in the pack trinity, the migrator
# adopts THEIRS's already-retired canonical → the migrated tree is
# `[CONDITIONAL]`-free. This is the migrated-tree absence assertion the C1b
# no-sidecar lock deferred to C9 (per arch §4.3/§5.2).
#
# NB (maintainer): the full migrator's Gate 2 runs `validate-pack.py` against
# the pack, so this leg REQUIRES the pack's validate battery to be green (the
# CI fixture shard restores the committed test-fixtures/manifest.txt before the
# run-loop, keeping Check 62 green). A migration exit 31 (EXIT_GATE_FAILED)
# here means validate-pack itself is red — fix that first.
if ! git -C "$PACK_ROOT" rev-parse -q --verify refs/tags/v10 >/dev/null 2>&1; then
    fail "OI-A requires the v10 git tag (baseline canonical) — not found"
else
    oia="$(mktemp -d "$WORK/oia.XXXXXX")/proj"
    mkdir -p "$oia"
    git init -q "$oia"; git -C "$oia" config user.email t@e; git -C "$oia" config user.name t
    mkdir -p "$oia/.claude" "$oia/docs/pack" "$oia/.codex" "$oia/.gemini"
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        git -C "$PACK_ROOT" show "v10:project-template/$f" > "$oia/$f" 2>/dev/null
    done
    for cli in .claude .codex .agents; do
        mkdir -p "$oia/$cli/skills/c-language"
        git -C "$PACK_ROOT" show "v10:project-template/skills/c-language/SKILL.md" \
            > "$oia/$cli/skills/c-language/SKILL.md" 2>/dev/null
    done
    git -C "$oia" add -A >/dev/null; git -C "$oia" commit -q -m "v10 initial state" 2>/dev/null

    # Pre-condition: the v10 baseline trinity actually carries the literal, so
    # the absence assertion is load-bearing (declare-verify-backing).
    pre_cond=$(grep -c 'CONDITIONAL' "$oia/CLAUDE.md")
    assert_eq "OI-A pre-condition: v10 baseline trinity carries [CONDITIONAL]" \
        "yes" "$([[ "$pre_cond" -ge 1 ]] && echo yes || echo no)"

    PACK="$PACK_ROOT" bash "$MIGRATE_SH" "$oia" > "$WORK/oia-migrate.log" 2>&1
    oiarc=$?
    assert_eq "OI-A v10->v11 migration exits 0" "0" "$oiarc"
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        assert_eq "OI-A migrated $f is [CONDITIONAL]-free (C4 retirement adopted)" \
            "0" "$(grep -c 'CONDITIONAL' "$oia/$f")"
    done
    oia_disp=$(awk -F'\t' '$2=="trinity" && $3=="CLAUDE.md"{print $1}' \
        "$oia/.pack-migrate-v10-to-v11/dispositions.tsv" 2>/dev/null)
    assert_absent "OI-A normal (uncustomized) migration did NOT sidecar the trinity" \
        "$oia_disp" "$NEEDS"
fi

# ═══════════════════════════════════════════════════════════════════════════
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
