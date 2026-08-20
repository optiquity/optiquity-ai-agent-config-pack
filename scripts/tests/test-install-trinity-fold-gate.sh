#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-install-trinity-fold-gate.sh — BD-285 Wave C
# Deterministic, NO live-LLM acceptance demo for the `resolve-merge-conflicts`
# skill's Case-3 INSTALL 2-way (no-BASE) trinity fold gate.
#
# DETERMINISTIC, NO live-LLM: this test does NOT invoke an AI. It hand-authors
# inline FOLDED / THEIRS / OURS fixtures in a tmp dir (NOT fixture-file
# dependent) and proves the Case-3 composite zero-loss gate BITES:
#   G-1  a hand-authored CORRECT 2-way fold PASSES the composite gate
#        (empty-BASE round-trip merged-with-customization + THEIRS-keyed
#        completeness + four-token).
#   G-2  a fold with a DUPLICATE `##` heading is REJECTED (engine sidecars).
#   G-3  a DEGENERATE fold (empty marker region — customization dropped) is
#        REJECTED by the completeness leg (round-trip ALONE would accept it).
#   G-4  a fold that DROPPED one distinctive line is REJECTED by the
#        completeness leg (round-trip ALONE would accept it).
#   G-5  a fold with a residual conflict marker is REJECTED.
#   L-1  the Case-3 locate awk (`$2=="trinity" && $4=="merge-2way"`) selects the
#        install merge-2way row and the Δ7/N2 Case-2 awk
#        (`$2=="trinity" && $4=="sidecar"`) does NOT — the two trinity cases
#        self-disambiguate even when both tables are read together.
#   P3-1 SURVIVAL: after a correct fold runs the Case-3 on-success block
#        (write fold to live, KEEP `.user-orig`), `<f>.user-orig` STILL EXISTS
#        and still equals the pre-install snapshot. (SHOULD-3: this proves THE
#        TEST'S simulation of the on-success block keeps the sidecar — a
#        regression-anchor for the intended KEEP-on-success divergence — NOT
#        the skill's AI-executed prose, whose no-removal invariant is enforced
#        by the Wave-E static Check.)
#
# The gate reuses the pack's OWN tested marker engine (marker_preserve_trinity)
# in its empty-BASE Regime B path — the same code the skill runs against `$PACK`
# at client time (declare-verify-backing: the test proves the load-bearing gate
# bites). This mirrors BD-287's Wave-E test-resolve-merge-conflicts-skill.sh.
#
# Usage:    bash scripts/tests/test-install-trinity-fold-gate.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
SKILL_MD="$REPO_ROOT/project-template/skills/resolve-merge-conflicts/SKILL.md"

# Portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`).
FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/bd285-c3.XXXXXX")"
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

# The Case-3 (install 2-way, NO BASE) composite zero-loss gate the SKILL.md
# specifies, mechanically:
#   PRIMARY    — round-trip marker_preserve_trinity "" FOLDED THEIRS (empty BASE
#                => Regime B body-adoption + all engine gates) => disposition
#                must be `merged-with-customization`.
#   SUPPLEMENT — four-token: FOLDED carries zero of the four --diff3 tokens.
#   SUPPLEMENT — THEIRS-keyed completeness: every OURS line byte-DISTINCT from
#                THEIRS (not present anywhere in THEIRS) must appear inside a
#                FOLDED marker region.  (No BASE to diff against — the pack v11
#                THEIRS is the reference.)
# Returns 0 iff every leg passes; non-0 on the first failing leg.
case3_zero_loss_gate() {
    local ours="$1" theirs="$2" folded="$3"
    local gate_dir disp regions line
    gate_dir="$(mktemp -d "$FIXTURE_BASE/gate.XXXXXX")"
    customization_preserve_init "$gate_dir" ".user-orig" >/dev/null

    # PRIMARY — empty-BASE round-trip (Regime B).
    marker_preserve_trinity "" "$folded" "$theirs" "CLAUDE.md" "$gate_dir/throwaway" >/dev/null 2>&1
    disp="$(tail -1 "$gate_dir/dispositions.tsv" | awk -F'\t' '{print $1}')"
    [[ "$disp" == "merged-with-customization" ]] || return 1

    # SUPPLEMENT — four-token (a marker left inside a project region).
    if grep -qE "$FOUR_TOKEN_RE" "$folded"; then return 3; fi

    # SUPPLEMENT — THEIRS-keyed completeness: every OURS line NOT in THEIRS must
    # live inside a FOLDED marker region.
    regions="$(marker_region_lines "$folded")"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        grep -qxF "$line" "$theirs" && continue            # coincides with pack → not distinctive
        printf '%s\n' "$regions" | grep -qxF "$line" || return 2
    done < "$ours"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────
echo "== fixtures (hand-authored inline; NO fixture-file dependency) =="
# ─────────────────────────────────────────────────────────────────────────
# THEIRS — the pack v11 trinity the installer just wrote live.
THEIRS="$FIXTURE_BASE/theirs.md"
printf '## Overview\noverview v11\n## Rules\nrule one v11\n## Telemetry\ntelemetry v11\n' > "$THEIRS"
# OURS — the user's pre-install trinity, stashed as <file>.user-orig. It adds a
# distinctive in-section line (MY-CUSTOM-RULE) and a whole project-owned section.
OURS="$FIXTURE_BASE/ours.md"
printf '## Overview\noverview v11\n## Rules\nrule one v11\nMY-CUSTOM-RULE\n## My Section\nmy body line\n' > "$OURS"
# FOLDED (correct) — THEIRS skeleton + OURS customizations wrapped in markers.
FOLD_OK="$FIXTURE_BASE/folded-correct.md"
cat > "$FOLD_OK" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
MY-CUSTOM-RULE
<!-- END project-owned -->
## Telemetry
telemetry v11
<!-- BEGIN project-owned -->
## My Section
my body line
<!-- END project-owned -->
MD
if [[ -f "$SKILL_MD" ]]; then pass "SKILL.md present"; else fail "SKILL.md present"; fi
# Anchor: the skill's Case-3 selector token matches the token this test drives.
if grep -q 'merge-2way' "$SKILL_MD"; then pass "SKILL.md references the merge-2way selector token"; else fail "SKILL.md references the merge-2way selector token"; fi
if grep -q '^## Case 3 — install 2-way trinity fold' "$SKILL_MD"; then pass "SKILL.md carries the Case 3 heading"; else fail "SKILL.md carries the Case 3 heading"; fi

# ─────────────────────────────────────────────────────────────────────────
echo "== G-1: correct 2-way fold PASSES the composite gate =="
# ─────────────────────────────────────────────────────────────────────────
case3_zero_loss_gate "$OURS" "$THEIRS" "$FOLD_OK"
assert_pass "G-1 correct wrapped fold accepted (merged-with-customization + complete + zero markers)" $?

# Prove the PRIMARY leg alone reaches merged-with-customization (empty-BASE round-trip).
newg="$(mktemp -d "$FIXTURE_BASE/rt.XXXXXX")"
customization_preserve_init "$newg" ".user-orig" >/dev/null
marker_preserve_trinity "" "$FOLD_OK" "$THEIRS" "CLAUDE.md" "$newg/throwaway" >/dev/null 2>&1
assert_eq "G-1 empty-BASE round-trip disposition is merged-with-customization" \
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
MY-CUSTOM-RULE
## My Section
my body line
<!-- END project-owned -->
## Telemetry
telemetry v11
## Telemetry
telemetry v11
MD
case3_zero_loss_gate "$OURS" "$THEIRS" "$DUP"
assert_reject "G-2 duplicate-heading fold rejected" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-3: degenerate (empty marker region) REJECTED by completeness =="
# ─────────────────────────────────────────────────────────────────────────
EMPTY="$FIXTURE_BASE/folded-empty.md"
cat > "$EMPTY" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
<!-- END project-owned -->
## Telemetry
telemetry v11
MD
# The round-trip PASSES this structurally-valid file; the completeness leg is
# what must catch the dropped customization.
emptyg="$(mktemp -d "$FIXTURE_BASE/emptyg.XXXXXX")"
customization_preserve_init "$emptyg" ".user-orig" >/dev/null
marker_preserve_trinity "" "$EMPTY" "$THEIRS" "CLAUDE.md" "$emptyg/throwaway" >/dev/null 2>&1
assert_eq "G-3 round-trip ALONE would accept the degenerate fold (why completeness is needed)" \
    "merged-with-customization" \
    "$(tail -1 "$emptyg/dispositions.tsv" | awk -F'\t' '{print $1}')"
case3_zero_loss_gate "$OURS" "$THEIRS" "$EMPTY"
assert_reject "G-3 degenerate-fold rejected by composite gate (completeness leg)" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-4: dropped distinctive line REJECTED by completeness =="
# ─────────────────────────────────────────────────────────────────────────
# Wraps the whole project section but DROPS the in-section MY-CUSTOM-RULE line.
DROP="$FIXTURE_BASE/folded-drop.md"
cat > "$DROP" <<'MD'
## Overview
overview v11
## Rules
rule one v11
## Telemetry
telemetry v11
<!-- BEGIN project-owned -->
## My Section
my body line
<!-- END project-owned -->
MD
dropg="$(mktemp -d "$FIXTURE_BASE/dropg.XXXXXX")"
customization_preserve_init "$dropg" ".user-orig" >/dev/null
marker_preserve_trinity "" "$DROP" "$THEIRS" "CLAUDE.md" "$dropg/throwaway" >/dev/null 2>&1
assert_eq "G-4 round-trip ALONE would accept the dropped-line fold (why completeness is needed)" \
    "merged-with-customization" \
    "$(tail -1 "$dropg/dispositions.tsv" | awk -F'\t' '{print $1}')"
case3_zero_loss_gate "$OURS" "$THEIRS" "$DROP"
assert_reject "G-4 dropped-distinctive-line fold rejected by composite gate (completeness leg)" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== G-5: residual conflict marker REJECTED =="
# ─────────────────────────────────────────────────────────────────────────
MARK="$FIXTURE_BASE/folded-marker.md"
cat > "$MARK" <<'MD'
## Overview
overview v11
## Rules
rule one v11
<!-- BEGIN project-owned -->
MY-CUSTOM-RULE
=======
## My Section
my body line
<!-- END project-owned -->
## Telemetry
telemetry v11
MD
case3_zero_loss_gate "$OURS" "$THEIRS" "$MARK"
assert_reject "G-5 residual-conflict-marker fold rejected" $?

# ─────────────────────────────────────────────────────────────────────────
echo "== L-1: Case-3 / Case-2 selectors self-disambiguate =="
# ─────────────────────────────────────────────────────────────────────────
TSV="$FIXTURE_BASE/dispositions.tsv"
NEEDS="customization-detected-needs-reconciliation"
{
    printf '# disposition\tclass\trel\taction\tsidecar\tdiff\tnotes\n'
    # A migration-table trinity sidecar row (Case 2).
    printf '%s\ttrinity\tCLAUDE.md\tsidecar\tCLAUDE.md.v10-customized\t-\t-\n' "$NEEDS"
    # An install-table trinity merge-2way row (Case 3).
    printf 'merged-with-customization\ttrinity\tAGENTS.md\tmerge-2way\tAGENTS.md.user-orig\t-\tinstall 2-way trinity fold (resolve-merge-conflicts Case 3)\n'
} > "$TSV"

case3_rows="$(awk -F'\t' '
    $2=="trinity" && $4=="merge-2way" { print $3 }
' "$TSV" | sort | tr '\n' ',')"
assert_eq "L-1 Case-3 selector picks the install merge-2way row ONLY" \
    "AGENTS.md," "$case3_rows"

case2_rows="$(awk -F'\t' '
    $1=="customization-detected-needs-reconciliation" &&
    (($2=="trinity" && $4=="sidecar") || ($4=="merged" && ($2=="generic" || $2=="pm-chat"))) { print $3 }
' "$TSV" | sort | tr '\n' ',')"
assert_eq "L-1 Δ7/N2 Case-2 selector picks the migration sidecar row ONLY (not merge-2way)" \
    "CLAUDE.md," "$case2_rows"

# Neither selector picks the other's row.
c3_picks_case2="$(awk -F'\t' '$2=="trinity" && $4=="merge-2way" && $3=="CLAUDE.md"{print}' "$TSV")"
assert_eq "L-1 Case-3 selector does NOT pick the migration sidecar row" "" "$c3_picks_case2"
c2_picks_case3="$(awk -F'\t' '$2=="trinity" && $4=="sidecar" && $3=="AGENTS.md"{print}' "$TSV")"
assert_eq "L-1 Case-2 selector does NOT pick the install merge-2way row" "" "$c2_picks_case3"

# ─────────────────────────────────────────────────────────────────────────
echo "== P3-1: SURVIVAL — Case-3 on-success KEEPS <f>.user-orig =="
# ─────────────────────────────────────────────────────────────────────────
# Simulate the install: a target with the pack v11 trinity live + the stashed
# .user-orig, plus a pristine pre-install snapshot for the byte-equality check.
TGT="$FIXTURE_BASE/target"; mkdir -p "$TGT"
cp "$THEIRS" "$TGT/CLAUDE.md"                 # live pack v11 (THEIRS)
cp "$OURS"   "$TGT/CLAUDE.md.user-orig"       # the .user-orig sidecar (OURS)
SNAP="$FIXTURE_BASE/pre-install-snapshot.md"
cp "$OURS"   "$SNAP"                          # pristine pre-install snapshot
# Gate uses a THEIRS temp captured BEFORE any edit (skill copies rel → THEIRS_tmp).
THEIRS_TMP="$FIXTURE_BASE/theirs-tmp.md"; cp "$TGT/CLAUDE.md" "$THEIRS_TMP"
case3_zero_loss_gate "$TGT/CLAUDE.md.user-orig" "$THEIRS_TMP" "$FOLD_OK"
assert_pass "P3-1 gate PASSES on the correct fold before on-success" $?
# On-success (Case 3): write the fold to the live file; KEEP .user-orig (do NOT remove).
cp "$FOLD_OK" "$TGT/CLAUDE.md"
# (Case 3 divergence: NO `rm` of CLAUDE.md.user-orig here — unlike Case 2.)
if [[ -f "$TGT/CLAUDE.md.user-orig" ]]; then
    pass "P3-1 <f>.user-orig STILL EXISTS after the on-success block"
else
    fail "P3-1 <f>.user-orig STILL EXISTS after the on-success block"
fi
if cmp -s "$TGT/CLAUDE.md.user-orig" "$SNAP"; then
    pass "P3-1 <f>.user-orig still byte-equals the pre-install snapshot"
else
    fail "P3-1 <f>.user-orig still byte-equals the pre-install snapshot"
fi
# And the live file now carries the fold (the folded bytes are live).
if cmp -s "$TGT/CLAUDE.md" "$FOLD_OK"; then
    pass "P3-1 live file carries the folded result after on-success"
else
    fail "P3-1 live file carries the folded result after on-success"
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
