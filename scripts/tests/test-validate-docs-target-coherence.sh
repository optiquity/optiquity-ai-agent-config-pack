#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-target-coherence.sh —
# gate-side byte-assert goldens for the BD-261 target-coherence gate
# (project-template/scripts/validate-docs.sh, the conformance-axis target
# legs): the FAIL-line bytes (both classes, witness-chain form), the
# suppression pins made byte-real (ABSENCE asserts), and the pair
# semantics (poison never silences a provable conflict).
#
# Pattern: the landed output-assert family
# (scripts/tests/test-validate-docs-client-deferred-shipped-docs.sh) —
# stage a mktemp client tree with the REAL shipped gate + allowlist +
# impl-plan _rules.md contract, run the REAL gate, FILTER the output to
# the asserted line families, and compare against golden line sets
# derived from the ONE normative table below. Never whole-output
# equality: an isolated fixture tree legitimately trips out-of-scope
# axes (e.g. dangling refs to docs present only in a full install).
#
# Asserted line families:
#   F1  the `[conformance] target conflict` family — presence, ABSENCE,
#       and exact bytes (declared/bound tokens + the witness chain), for
#       EVERY geometry;
#   F2  for CYCLIC geometries only: the `dependency cycle` FAIL + the
#       `hard-dependency violated` lines the geometry's PINNED _index.md
#       order produces (>= 1 such line exists for any listing order of a
#       cyclic edge set);
#   plus per-geometry side asserts (the poison source's own enum/status
#   FAIL present; ES asserts ZERO Status-FAIL lines — the Status leg
#   tolerates a present-but-empty value by construction).
#
# At the BD-189 fold, C1 EXTENDS this same script with the
# grp_implied_target_map row-set golden derived from the same normative
# table (the gate golden is never re-authored).
#
# Usage:    bash scripts/tests/test-validate-docs-target-coherence.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# The REAL shipped gate + client allowlist + impl-plan stream contract.
GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"
RULES="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"

FIXTURE_BASE="$(mktemp -d -t test-vdocs-target-coherence.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | sed 's/^/    /'
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

# Input guards: the inputs must exist AND the shipped contract must carry
# the `target-enum:` schema line (the coherence gate's run-condition keys
# on it — a missing line would turn every leg below into a silent no-op).
for f in "$GATE" "$ALLOWLIST" "$RULES"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done
if ! grep -q '^- target-enum: ' "$RULES"; then
    fail "shipped _rules.md declares target-enum" \
        "no '- target-enum: ' schema line in $RULES"
fi
if [[ $fails -gt 0 ]]; then
    echo "=== Results: $passes passed, $fails failed ==="
    exit 1
fi

# ── Builders ────────────────────────────────────────────────────────────
# stage_tree <root> — the installed-client layout slice this gate leg
# reads: the impl-plan stream (with the REAL shipped _rules.md) + the
# gate + the allowlist under scripts/ (the gate resolves ROOT_DIR from
# its parent and the allowlist from its own dir).
stage_tree() {
    local root="$1"
    mkdir -p "$root/docs/project/implementation-plan" "$root/scripts"
    cp "$RULES" "$root/docs/project/implementation-plan/_rules.md"
    cp "$GATE" "$root/scripts/validate-docs.sh"
    cp "$ALLOWLIST" "$root/scripts/.docs-gate-allowlist.txt"
    chmod +x "$root/scripts/validate-docs.sh"
}

# write_phase <root> <num> <status> <target|-> <blockers> <unblocks>
# A conforming phase-epic (all schema epic fields); target '-' = absent;
# target '' = present-but-empty; status '' = present-but-empty.
write_phase() {
    local root="$1" num="$2" status="$3" target="$4"
    local blockers="$5" unblocks="$6"
    {
        printf '<!-- back -->\n## Phase %s — G%s\n\n' "$num" "$num"
        printf -- '- **Entry-Type**: phase-epic\n'
        printf -- '- **ID**: phase-%s\n' "$num"
        printf -- '- **Status**: %s\n' "$status"
        printf -- '- **Blockers**: %s\n' "$blockers"
        printf -- '- **Unblocks**: %s\n' "$unblocks"
        printf -- '- **Goal**: g\n'
        printf -- '- **Prerequisite**: none\n'
        if [[ "$target" != "-" ]]; then
            printf -- '- **Target**: %s\n' "$target"
        fi
    } > "$root/docs/project/implementation-plan/phase-${num}.md"
}

# write_index <root> <num>... — the PINNED `_index.md` listing order
# (cyclic geometries derive their F2 hard-dependency golden from it).
write_index() {
    local root="$1"; shift
    {
        printf '# Index — ordering — project-implementation-plan\n\n'
        printf '## Serial order\n\n'
        local n
        for n in "$@"; do
            printf -- '- [phase-%s](./phase-%s.md) — G%s\n' "$n" "$n" "$n"
        done
    } > "$root/docs/project/implementation-plan/_index.md"
}

run_gate() { bash "$1/scripts/validate-docs.sh" 2>&1; }

# Family filters (strip the printer's leading '  - ' so goldens carry the
# raw fail-line bytes).
conflict_family() {
    printf '%s\n' "$1" | grep -F '[conformance] target conflict' \
        | sed 's/^  - //'
}
cycle_family() {
    printf '%s\n' "$1" \
        | grep -E 'hard-dependency violated|dependency cycle — no valid' \
        | sed 's/^  - //'
}

# assert_lines <label> <got> <want> — order-insensitive line-SET equality
# (byte-exact per line; blank lines dropped).
assert_lines() {
    local label="$1" got="$2" want="$3" d
    d="$(diff \
        <(printf '%s\n' "$got" | sed '/^$/d' | sort) \
        <(printf '%s\n' "$want" | sed '/^$/d' | sort) 2>&1)" || true
    if [[ -z "$d" ]]; then
        pass "$label"
    else
        fail "$label" "$d"
    fi
}

# ── THE NORMATIVE TABLE ─────────────────────────────────────────────────
# One table; every golden below derives from it. Enum ordinals (shipped
# contract declaration order): current(0) < next-release(1) <
# next-minor(2) < next-major(3) < future-unassigned(4).
#
# geo   | phases: num(status, target)                  | edges (a->b = a-must-precede-b) | index    | F1 conflict golden                          | F2 cycle golden
# ------+-----------------------------------------------+---------------------------------+----------+---------------------------------------------+----------------
# SB    | 1(ns,next-major) 2(ns,v9.9!) 3(ns,current)    | 1->2 1->3                       | 1 2 3    | 1: bound current via 3 (direct)             | none
# SC    | 1(ns,next-major) 2(ns,-) 3(ns,-)              | 1->2 1->4 2->3 3->2 3->5        | 1 2 3 4 5| 1: bound next-minor via 4 (direct; the      | 3-before-2 + cycle
#       | 4(ns,next-minor) 5(ns,current)                |   (live cycle {2,3})            |          |   through-cycle atom at 5 is NOT provable)  |
# CYCW  | 1(ns,next-major) 2(ns,-) 3(ns,current)        | 1->2 2->3 3->2 (atom in cycle)  | 1 2 3    | NONE (bound rides an intra-SCC edge)        | 3-before-2 + cycle
# SN    | 1(ns,next-major) 2(ns,next-minor) 3(ns,v9.9!) | 1->2 2->3                       | 1 2 3    | 1: bound next-minor via 2 (direct);         | none
#       |                                               |                                 |          |   node 2 SILENT (its own bound unprovable)  |
# SD    | 1(ns,-) 2(ns,-) 3(done,-)                     | 1->2 2->3 3->2 (done-broken)    | 1 2 3    | NONE                                        | 3-before-2 + cycle
# SD2   | 1(ns,next-major) 2(ns,-) 3(done,-)            | 1->2 2->3 3->2 2->4             | 1 2 3 4  | 1: bound current via 2 -> 4 (TRANSITIVE —   | 3-before-2 + cycle
#       | 4(ns,current)                                 |   (done-broken cycle)           |          |   the absorbing cut; no spurious suppression)|
# GS    | 1(ns,next-major) 2(wip!,current)              | 1->2 1->3                       | 1 2 3    | 1: bound next-release via 3 (the garbled-   | none
#       | 3(ns,next-release)                            |                                 |          |   status atom neither radiates nor conduits)|
# ES    | 1(ns,next-major) 2(EMPTY-status,current)      | 1->2 1->3                       | 1 2 3    | 1: bound next-release via 3; PLUS zero      | none
#       | 3(ns,next-release)                            |                                 |          |   Status-FAIL lines (empty tolerated)       |
# SE    | 1(ns,next-major) 2(ns,next-minor) 3(ns,-)     | 1->2 1->3 3->4                  | 1 2 3 4  | 1: bound current via 3 -> 4 (arg-min picks  | none
#       | 4(ns,current)                                 |                                 |          |   the TRANSITIVE branch over the direct atom)|
# JCT   | 1(ns,next-minor) 2(ns,next-release)           | 1->2 1->3                       | 1 2 3    | 1: bound next-release via 2 (junction MIN,  | none
#       | 3(ns,next-major)                              |                                 |          |   not max)                                  |
# EQ    | 1(ns,current) 2(ns,current)                   | 1->2                            | 1 2      | NONE (equal bound is no conflict)           | none
# DT    | 1(def,next-major) 2(ns,current) 3(def,-)      | 1->2 3->4                       | 1 2 3 4  | 1: bound current via 2 (deferred declarer   | none
#       | 4(ns,current)                                 |                                 |          |   FAILS; untargeted deferred 3 emits NOTHING)|
# FU    | 1(ns,next-major) 2(ns,future-unassigned)      | 1->2 2->3                       | 1 2 3    | 1: bound current via 2 -> 3 (fu transmits); | none
#       | 3(ns,current)                                 |                                 |          |   2: bound current via 3 (fu self-conflicts)|
# RESCH | synthetic reordered enum 'next-major current';| 1->2                            | 1 2      | 1: declared current exceeds bound next-major| none
#       | 1(ns,current) 2(ns,next-major)                |                                 |          |   via 2 (declaration order IS the scale);   |
#       |                                               |                                 |          |   PLUS zero target-enum FAIL lines          |
#
# (ns = not-started, def = deferred, ! = the geometry's poison source.)

RD="docs/project/implementation-plan"
REM_HEAD="The per-entry stream must conform to the no-mirror flat-file"

conflict_line() {
    # conflict_line <phase> <declared> <bound> <via-chain>
    printf '%s/phase-%s.md [conformance] target conflict — declared %s exceeds provable dependency bound %s (via %s, declared %s)' \
        "$RD" "$1" "$2" "$3" "$4" "$3"
}
CYC_32="$RD/_index.md [conformance] hard-dependency violated: phase-3 must precede phase-2 but _index.md lists phase-2 first"
CYC_LINE="$RD/_index.md [conformance] dependency cycle — no valid topological order exists"
CYC_BOTH="$CYC_32
$CYC_LINE"

echo "== BD-261 target-coherence gate goldens (family-filtered) =="

# ── SB — adjacent poison fires the clean conflict (pair semantics) ──────
R="$FIXTURE_BASE/sb"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none "phase-2 phase-3"
write_phase "$R" 2 not-started v9.9 phase-1 none
write_phase "$R" 3 not-started current phase-1 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "SB F1: clean-branch conflict fires beside the adjacent poison" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major current phase-3)"
assert_lines "SB F2: no cycle-family lines" "$(cycle_family "$out")" ""
if printf '%s\n' "$out" | grep -q "Target 'v9.9' not in target-enum"; then
    pass "SB side: the poison source carries its own enum FAIL"
else
    fail "SB side: expected the phase-2 Target enum FAIL alongside the conflict" \
        "$out"
fi

# ── SC — live cycle: off-cycle provable fires; through-cycle atom silent ─
R="$FIXTURE_BASE/sc"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none "phase-2 phase-4"
write_phase "$R" 2 not-started - phase-1 phase-3
write_phase "$R" 3 not-started - phase-2 "phase-2 phase-5"
write_phase "$R" 4 not-started next-minor phase-1 none
write_phase "$R" 5 not-started current phase-3 none
write_index "$R" 1 2 3 4 5
out="$(run_gate "$R")"
assert_lines "SC F1: off-cycle bound (next-minor via phase-4) — the tighter through-cycle atom (current at phase-5) is NOT provable" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major next-minor phase-4)"
assert_lines "SC F2: pinned-order hard-dep line + the cycle FAIL" \
    "$(cycle_family "$out")" "$CYC_BOTH"

# ── CYCW — atom inside the cycle: no provable bound, no conflict ────────
R="$FIXTURE_BASE/cycw"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none phase-2
write_phase "$R" 2 not-started - phase-1 phase-3
write_phase "$R" 3 not-started current phase-2 phase-2
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "CYCW F1: NO conflict — the bound would ride an intra-SCC edge" \
    "$(conflict_family "$out")" ""
assert_lines "CYCW F2: pinned-order hard-dep line + the cycle FAIL" \
    "$(cycle_family "$out")" "$CYC_BOTH"

# ── SN — the dependent's own bound: its atom binds upstream while its own
#         conflict check stays silent (unprovable past the poison) ───────
R="$FIXTURE_BASE/sn"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none phase-2
write_phase "$R" 2 not-started next-minor phase-1 phase-3
write_phase "$R" 3 not-started v9.9 phase-2 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "SN F1: phase-1 bound by phase-2's atom; phase-2 itself SILENT" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major next-minor phase-2)"
assert_lines "SN F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── SD — done-broken cycle: structural cycle FAIL, zero targets, no
#         conflict lines (the absorbing node breaks the LIVE cycle) ──────
R="$FIXTURE_BASE/sd"; stage_tree "$R"
write_phase "$R" 1 not-started - none phase-2
write_phase "$R" 2 not-started - phase-1 phase-3
write_phase "$R" 3 done - phase-2 phase-2
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "SD F1: no conflict lines (nothing declared)" \
    "$(conflict_family "$out")" ""
assert_lines "SD F2: the STATUS-BLIND structural cycle still FAILs" \
    "$(cycle_family "$out")" "$CYC_BOTH"

# ── SD2 — done-broken cycle with a live downstream atom: the absorbing
#          cut leaves the live bound sound — no spurious suppression ─────
R="$FIXTURE_BASE/sd2"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none phase-2
write_phase "$R" 2 not-started - phase-1 "phase-3 phase-4"
write_phase "$R" 3 done - phase-2 phase-2
write_phase "$R" 4 not-started current phase-2 none
write_index "$R" 1 2 3 4
out="$(run_gate "$R")"
assert_lines "SD2 F1: the TRANSITIVE conflict fires through the done-broken cycle region (chain form)" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major current "phase-2 → phase-4")"
assert_lines "SD2 F2: the structural cycle FAIL rides alongside" \
    "$(cycle_family "$out")" "$CYC_BOTH"

# ── GS — garbled Status: unified poison frame (atom + conduit excluded);
#         the clean-branch conflict still fires ──────────────────────────
R="$FIXTURE_BASE/gs"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none "phase-2 phase-3"
write_phase "$R" 2 wip current phase-1 none
write_phase "$R" 3 not-started next-release phase-1 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "GS F1: bound next-release via the clean branch (the garbled-status atom 'current' did NOT radiate)" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major next-release phase-3)"
assert_lines "GS F2: no cycle-family lines" "$(cycle_family "$out")" ""
if printf '%s\n' "$out" | grep -q "Status 'wip' not in status-enum"; then
    pass "GS side: the poison source carries its own Status enum FAIL"
else
    fail "GS side: expected the phase-2 Status enum FAIL alongside the conflict" \
        "$out"
fi

# ── ES — present-but-EMPTY Status: validation-green on the Status leg by
#         construction (the honest carve-out), yet excluded from the
#         provable bound; the sibling clean-branch conflict fires ────────
R="$FIXTURE_BASE/es"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none "phase-2 phase-3"
write_phase "$R" 2 "" current phase-1 none
write_phase "$R" 3 not-started next-release phase-1 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "ES F1: bound next-release via the clean branch (the empty-status conduit suppressed)" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major next-release phase-3)"
assert_lines "ES F2: no cycle-family lines" "$(cycle_family "$out")" ""
es_status_fails="$(printf '%s\n' "$out" \
    | grep -c "Status '\|field 'Status'")" || true
if [[ "$es_status_fails" -eq 0 ]]; then
    pass "ES side: ZERO Status-FAIL lines (present-but-empty is tolerated by the Status leg)"
else
    fail "ES side: expected zero Status-FAIL lines for the empty-Status phase" \
        "$(printf '%s\n' "$out" | grep "Status '\|field 'Status'")"
fi

# ── SE — mixed dependents: the arg-min witness picks the TRANSITIVE
#         branch (bound current via 3 -> 4 beats the direct atom at 2) ───
R="$FIXTURE_BASE/se"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none "phase-2 phase-3"
write_phase "$R" 2 not-started next-minor phase-1 none
write_phase "$R" 3 not-started - phase-1 phase-4
write_phase "$R" 4 not-started current phase-3 none
write_index "$R" 1 2 3 4
out="$(run_gate "$R")"
assert_lines "SE F1: transitive class via the arg-min witness chain" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major current "phase-3 → phase-4")"
assert_lines "SE F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── JCT — junction: the bound is the MIN over dependents, not the max ───
R="$FIXTURE_BASE/jct"; stage_tree "$R"
write_phase "$R" 1 not-started next-minor none "phase-2 phase-3"
write_phase "$R" 2 not-started next-release phase-1 none
write_phase "$R" 3 not-started next-major phase-1 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
assert_lines "JCT F1: min-aggregation (bound next-release via phase-2)" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-minor next-release phase-2)"
assert_lines "JCT F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── EQ — equal bound: declared == provable bound is NO conflict ─────────
R="$FIXTURE_BASE/eq"; stage_tree "$R"
write_phase "$R" 1 not-started current none phase-2
write_phase "$R" 2 not-started current phase-1 none
write_index "$R" 1 2
out="$(run_gate "$R")"
assert_lines "EQ F1: no conflict lines (strict > predicate)" \
    "$(conflict_family "$out")" ""
assert_lines "EQ F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── DT — deferred tension: a deferred declarer with a LATE claim FAILs;
#         an untargeted deferred blocker emits NOTHING (advisory-only) ───
R="$FIXTURE_BASE/dt"; stage_tree "$R"
write_phase "$R" 1 deferred next-major none phase-2
write_phase "$R" 2 not-started current phase-1 none
write_phase "$R" 3 deferred - none phase-4
write_phase "$R" 4 not-started current phase-3 none
write_index "$R" 1 2 3 4
out="$(run_gate "$R")"
assert_lines "DT F1: exactly the deferred-declarer conflict (deferred is non-absorbing); the untargeted deferred blocker stays silent" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 next-major current phase-2)"
assert_lines "DT F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── FU — future-unassigned drag + transmit: fu contributes no bound but
#         TRANSMITS one, and self-conflicts as a declarer ────────────────
R="$FIXTURE_BASE/fu"; stage_tree "$R"
write_phase "$R" 1 not-started next-major none phase-2
write_phase "$R" 2 not-started future-unassigned phase-1 phase-3
write_phase "$R" 3 not-started current phase-2 none
write_index "$R" 1 2 3
out="$(run_gate "$R")"
FU_WANT="$(conflict_line 1 next-major current "phase-2 → phase-3")
$(conflict_line 2 future-unassigned current phase-3)"
assert_lines "FU F1: both conflicts — transitive through fu (transmit) + the fu declarer's own (drag)" \
    "$(conflict_family "$out")" "$FU_WANT"
assert_lines "FU F2: no cycle-family lines" "$(cycle_family "$out")" ""

# ── RESCH — schema-driven scale: a REORDERED synthetic target-enum
#            ('next-major current') flips the ordinals; the leg accepts
#            the tokens and the conflict follows DECLARATION order ───────
R="$FIXTURE_BASE/resch"; stage_tree "$R"
rules_f="$R/docs/project/implementation-plan/_rules.md"
sed 's|^- target-enum: .*|- target-enum: next-major current|' \
    "$rules_f" > "$rules_f.tmp" && mv "$rules_f.tmp" "$rules_f"
if grep -q '^- target-enum: next-major current$' "$rules_f"; then
    pass "RESCH stage: synthetic reordered enum in place"
else
    fail "RESCH stage: the target-enum rewrite did not take" \
        "$(grep '^- target-enum' "$rules_f")"
fi
write_phase "$R" 1 not-started current none phase-2
write_phase "$R" 2 not-started next-major phase-1 none
write_index "$R" 1 2
out="$(run_gate "$R")"
assert_lines "RESCH F1: declaration order IS the scale (declared current exceeds bound next-major under the reordered enum)" \
    "$(conflict_family "$out")" \
    "$(conflict_line 1 current next-major phase-2)"
resch_enum_fails="$(printf '%s\n' "$out" \
    | grep -c "not in target-enum")" || true
if [[ "$resch_enum_fails" -eq 0 ]]; then
    pass "RESCH side: both tokens ACCEPTED under the synthetic enum (schema-driven parse, no hardcoded scale)"
else
    fail "RESCH side: expected zero target-enum FAILs under the synthetic enum" \
        "$(printf '%s\n' "$out" | grep 'not in target-enum')"
fi

# ── Remediation suffix: the conflict FAIL carries the shared conformance
#    remediation on its indented follow-on line (the family shape) ───────
if printf '%s\n' "$out" | grep -q "    $REM_HEAD"; then
    pass "remediation: the conflict FAIL carries the indented conformance remediation"
else
    fail "remediation: expected the indented REMEDIATION_CONFORMANCE line after the conflict FAIL" \
        "$out"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
