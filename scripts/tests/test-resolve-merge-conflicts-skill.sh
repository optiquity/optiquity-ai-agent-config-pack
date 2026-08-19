#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-resolve-merge-conflicts-skill.sh — BD-287 Wave E
# acceptance demo for the `resolve-merge-conflicts` skill's Case-2 trinity fold.
#
# DETERMINISTIC, NO live-LLM (ARCHITECTURE-BD287-FINAL.md OI-F4): this test does
# NOT invoke an AI. It SIMULATES the mechanical contract the skill's SKILL.md
# specifies and proves the §2.4 ZERO-LOSS GATE BITES:
#   G-1  a hand-authored CORRECT wrapped fold PASSES the composite gate
#        (round-trip merged-with-customization + completeness + four-token).
#   G-2  a fold with a DUPLICATE `##` heading is REJECTED (engine sidecars).
#   G-3  a fold that DROPPED the customization (empty marker region) is
#        REJECTED by the completeness leg (round-trip alone would pass it).
#   G-4  a fold with a residual `[CONDITIONAL]` heading is REJECTED (L-9 hoist).
#   G-5  a fold with a residual conflict marker is REJECTED (four-token leg).
#   R-1  the §2.1 routing awk selects the trinity row (Case 2) + prose
#        action-`merged` rows (Case 1) and EXCLUDES pack-script/pack-agent.
#   S-1  the migrator's trinity sidecar path writes the `<dest>.v10-base` stash;
#        the skill's BASE derivation (`${sidecar%.v10-customized}.v10-base`)
#        reads it. `_cp_stash_trinity_base` is a no-op when BASE is absent (I3).
#
# The gate reuses the pack's OWN tested marker engine (marker_preserve_trinity)
# as the verifier — the same code the skill runs against `$PACK` at client time
# (declare-verify-backing: the test proves the load-bearing gate bites).
#
# Usage:    bash scripts/tests/test-resolve-merge-conflicts-skill.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FX="$REPO_ROOT/scripts/tests/fixtures/resolve-merge-conflicts"
SKILL_MD="$REPO_ROOT/project-template/skills/resolve-merge-conflicts/SKILL.md"

# Portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`).
FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/bd287-skill.XXXXXX")"
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
assert_eq()      { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }
assert_pass()    { if [[ "$2" -eq 0 ]]; then pass "$1"; else fail "$1" "gate PASS (0)" "gate rc=$2"; fi; }
assert_reject()  { if [[ "$2" -ne 0 ]]; then pass "$1"; else fail "$1" "gate REJECT (non-0)" "gate rc=0"; fi; }

# shellcheck disable=SC1091
source "$LIB_DIR/three-way.sh"
export _CP_PACK_ROOT="$REPO_ROOT"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-preserve.sh"   # sources marker-preserve.sh + three-way-merge.sh

if ! declare -F marker_preserve_trinity >/dev/null 2>&1; then
    echo "FATAL: marker_preserve_trinity not sourced"; exit 1
fi

FOUR_TOKEN_RE='^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)'

# Extract the lines strictly INSIDE project-owned marker regions of a file.
marker_region_lines() {
    awk '
        /<!-- BEGIN project-owned/ { f=1; next }
        /<!-- END project-owned -->/ { f=0; next }
        f { print }
    ' "$1"
}

# The §2.4 COMPOSITE zero-loss gate the SKILL.md specifies, mechanically:
#   PRIMARY   — round-trip marker_preserve_trinity "" FOLDED THEIRS => disposition
#               must be `merged-with-customization`.
#   SUPPLEMENT— every `diff BASE OURS` added line present in FOLDED marker regions.
#   SUPPLEMENT— FOLDED carries zero of the four --diff3 tokens.
# Returns 0 iff every leg passes; non-0 on the first failing leg.
zero_loss_gate() {
    local base="$1" ours="$2" theirs="$3" folded="$4"
    local gate_dir disp regions added line
    gate_dir="$(mktemp -d "$FIXTURE_BASE/gate.XXXXXX")"
    customization_preserve_init "$gate_dir" ".v10-customized" >/dev/null

    # PRIMARY — round-trip (BASE="" => Regime B body-adoption + all gates).
    marker_preserve_trinity "" "$folded" "$theirs" "CLAUDE.md" "$gate_dir/throwaway" >/dev/null 2>&1
    disp="$(tail -1 "$gate_dir/dispositions.tsv" | awk -F'\t' '{print $1}')"
    [[ "$disp" == "merged-with-customization" ]] || return 1

    # SUPPLEMENT — four-token (a marker left inside a project region).
    if grep -qE "$FOUR_TOKEN_RE" "$folded"; then return 3; fi

    # SUPPLEMENT — completeness: every added line inside a marker region.
    regions="$(marker_region_lines "$folded")"
    added="$(diff "$base" "$ours" | grep '^> ' | cut -c3-)"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        printf '%s\n' "$regions" | grep -qxF "$line" || return 2
    done <<EOF
$added
EOF
    return 0
}

# ─────────────────────────────────────────────────────────────────────────
echo "== fixture sanity =="
# ─────────────────────────────────────────────────────────────────────────
for f in base.md ours.md theirs.md folded-correct.md; do
    if [[ -f "$FX/$f" ]]; then pass "fixture present: $f"; else fail "fixture present: $f"; fi
done
if [[ -f "$SKILL_MD" ]]; then pass "SKILL.md present"; else fail "SKILL.md present"; fi

# ─────────────────────────────────────────────────────────────────────────
echo "== G-1: correct fold PASSES the composite zero-loss gate =="
# ─────────────────────────────────────────────────────────────────────────
zero_loss_gate "$FX/base.md" "$FX/ours.md" "$FX/theirs.md" "$FX/folded-correct.md"
assert_pass "G-1 correct wrapped fold accepted (merged-with-customization + complete + zero markers)" $?

# Prove the PRIMARY leg alone reaches merged-with-customization (round-trip).
newg="$(mktemp -d "$FIXTURE_BASE/rt.XXXXXX")"
customization_preserve_init "$newg" ".v10-customized" >/dev/null
marker_preserve_trinity "" "$FX/folded-correct.md" "$FX/theirs.md" "CLAUDE.md" "$newg/throwaway" >/dev/null 2>&1
assert_eq "G-1 round-trip disposition is merged-with-customization" \
    "merged-with-customization" \
    "$(tail -1 "$newg/dispositions.tsv" | awk -F'\t' '{print $1}')"

# ─────────────────────────────────────────────────────────────────────────
echo "== G-2: duplicate '##' heading REJECTED (engine sidecars) =="
# ─────────────────────────────────────────────────────────────────────────
DUP="$FIXTURE_BASE/folded-dup.md"
cat > "$DUP" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
PROJECT-CUSTOM-RULE
<!-- END project-owned -->
## Archive
legacy v11
## Archive
legacy v11
## Telemetry
telemetry v11
MD
zero_loss_gate "$FX/base.md" "$FX/ours.md" "$FX/theirs.md" "$DUP"
assert_reject "G-2 duplicate-heading fold rejected" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-3: dropped customization REJECTED by the completeness leg =="
# ─────────────────────────────────────────────────────────────────────────
DROP="$FIXTURE_BASE/folded-drop.md"
cat > "$DROP" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
<!-- END project-owned -->
## Archive
legacy v11
## Telemetry
telemetry v11
MD
# The round-trip PASSES this structurally-valid file; the completeness leg is
# what must catch the dropped customization.
dropg="$(mktemp -d "$FIXTURE_BASE/dropg.XXXXXX")"
customization_preserve_init "$dropg" ".v10-customized" >/dev/null
marker_preserve_trinity "" "$DROP" "$FX/theirs.md" "CLAUDE.md" "$dropg/throwaway" >/dev/null 2>&1
assert_eq "G-3 round-trip ALONE would accept the degenerate fold (why completeness is needed)" \
    "merged-with-customization" \
    "$(tail -1 "$dropg/dispositions.tsv" | awk -F'\t' '{print $1}')"
zero_loss_gate "$FX/base.md" "$FX/ours.md" "$FX/theirs.md" "$DROP"
assert_reject "G-3 dropped-customization fold rejected by composite gate" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-4: residual [CONDITIONAL] heading REJECTED (L-9 hoist) =="
# ─────────────────────────────────────────────────────────────────────────
COND="$FIXTURE_BASE/folded-cond.md"
cat > "$COND" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
PROJECT-CUSTOM-RULE
<!-- END project-owned -->
## [CONDITIONAL] Archive
legacy v11
## Telemetry
telemetry v11
MD
zero_loss_gate "$FX/base.md" "$FX/ours.md" "$FX/theirs.md" "$COND"
assert_reject "G-4 residual-[CONDITIONAL] fold rejected" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-5: residual conflict marker REJECTED (four-token leg) =="
# ─────────────────────────────────────────────────────────────────────────
MARK="$FIXTURE_BASE/folded-marker.md"
cat > "$MARK" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
PROJECT-CUSTOM-RULE
=======
<!-- END project-owned -->
## Archive
legacy v11
## Telemetry
telemetry v11
MD
zero_loss_gate "$FX/base.md" "$FX/ours.md" "$FX/theirs.md" "$MARK"
assert_reject "G-5 residual-conflict-marker fold rejected" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== R-1: the §2.1 routing awk selects the right rows =="
# ─────────────────────────────────────────────────────────────────────────
TSV="$FIXTURE_BASE/dispositions.tsv"
NEEDS="customization-detected-needs-reconciliation"
{
    printf '# disposition\tclass\trel\taction\tsidecar\tdiff\tnotes\n'
    printf '%s\ttrinity\tCLAUDE.md\tsidecar\tCLAUDE.md.v10-customized\t-\t-\n'   "$NEEDS"
    printf '%s\tgeneric\tdocs/x.md\tmerged\tdocs/x.md.v10-customized\t-\t-\n'    "$NEEDS"
    printf '%s\tpm-chat\tdocs/pack/PM-CHAT.md\tmerged\tdocs/pack/PM-CHAT.md.v10-customized\t-\t-\n' "$NEEDS"
    printf '%s\tpack-script\tscripts/x.sh\tsidecar\tscripts/x.sh.v10-customized\t-\t-\n' "$NEEDS"
    printf '%s\tpack-agent\t.claude/agents/y.md\tsidecar\t.y.v10-customized\t-\t-\n'     "$NEEDS"
    printf 'merged-with-customization\tgeneric\tdocs/clean.md\tmerged\t-\t-\t-\n'
} > "$TSV"

in_scope="$(awk -F'\t' '
    $1=="customization-detected-needs-reconciliation" &&
    ($2=="trinity" || ($4=="merged" && ($2=="generic" || $2=="pm-chat"))) { print $3 }
' "$TSV" | sort | tr '\n' ',' )"
assert_eq "R-1 in-scope rows = trinity + prose-merged (Case 1 + Case 2), sorted" \
    "CLAUDE.md,docs/pack/PM-CHAT.md,docs/x.md," "$in_scope"

out_scope="$(awk -F'\t' '
    $1=="customization-detected-needs-reconciliation" && $4=="sidecar" &&
    ($2=="pack-script" || $2=="pack-agent") { print $3 }
' "$TSV" | sort | tr '\n' ',' )"
assert_eq "R-1 out-of-scope rows = pack-script + pack-agent only" \
    ".claude/agents/y.md,scripts/x.sh," "$out_scope"

# The clean `merged-with-customization` row (already resolved) is NOT in scope.
clean_hit="$(awk -F'\t' '$1=="merged-with-customization" && $2=="trinity"{print}' "$TSV")"
assert_eq "R-1 already-clean rows excluded (no trinity clean row selected)" "" "$clean_hit"

# ─────────────────────────────────────────────────────────────────────────
echo "== S-1: trinity sidecar path stashes .v10-base; skill BASE derivation reads it =="
# ─────────────────────────────────────────────────────────────────────────
sdir="$FIXTURE_BASE/stash"; mkdir -p "$sdir"
sstate="$FIXTURE_BASE/stash-state"; rm -rf "$sstate"
customization_preserve_init "$sstate" ".v10-customized" >/dev/null
# markerless trinity, project-edited body + pack-changed body => real-merge =>
# bare sidecar + BASE stash (F6 keeps the sidecar; §2.2 writes .v10-base).
printf '## A\nabody v10\n' > "$sdir/base.md"
printf '## A\nabody v10\nPROJ-EDIT\n' > "$sdir/ours.md"
printf '## A\nabody v11\n' > "$sdir/theirs.md"
cp "$sdir/ours.md" "$sdir/CLAUDE.md"
customization_preserve "$sdir/base.md" "$sdir/ours.md" "$sdir/theirs.md" \
    "CLAUDE.md" "$sdir/CLAUDE.md" trinity >/dev/null 2>&1
if [[ -f "$sdir/CLAUDE.md.v10-customized" ]]; then
    pass "S-1 trinity sidecar written (.v10-customized)"
else
    fail "S-1 trinity sidecar written (.v10-customized)"
fi
if [[ -f "$sdir/CLAUDE.md.v10-base" ]]; then
    pass "S-1 .v10-base stash written next to sidecar"
else
    fail "S-1 .v10-base stash written next to sidecar"
fi
# The .v10-base name does NOT match the *.v10-customized orphan glob.
case "$sdir/CLAUDE.md.v10-base" in
    *.v10-customized) fail "S-1 .v10-base invisible to *.v10-customized glob" ;;
    *) pass "S-1 .v10-base invisible to *.v10-customized orphan glob" ;;
esac
# Skill BASE derivation: sidecar -> DEST -> BASE, all local files.
sidecar_col="$sdir/CLAUDE.md.v10-customized"
dest_derived="${sidecar_col%.v10-customized}"
base_derived="${dest_derived}.v10-base"
assert_eq "S-1 skill derives BASE = <live>.v10-base from the sidecar column" \
    "$sdir/CLAUDE.md.v10-base" "$base_derived"
if [[ -r "$base_derived" ]]; then pass "S-1 derived BASE is readable"; else fail "S-1 derived BASE is readable"; fi
assert_eq "S-1 stashed BASE is byte-identical to the v10 base input" \
    "$(cat "$sdir/base.md")" "$(cat "$base_derived")"

# Negative: BASE absent (--update path, I3) => no stash written.
nobase="$FIXTURE_BASE/nobase.md"; printf '## A\nx\n' > "$nobase"
rm -f "${nobase}.v10-base"
_cp_stash_trinity_base "" "$nobase" >/dev/null 2>&1
if [[ ! -f "${nobase}.v10-base" ]]; then
    pass "S-1 BASE-absent call writes NO stash (I3)"
else
    fail "S-1 BASE-absent call writes NO stash (I3)"
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
