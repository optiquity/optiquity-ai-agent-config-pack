#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-groupings-lib.sh — the BD-262 groupings-lib.sh
# API-freeze battery: these goldens ARE the library contract the
# downstream groupings consumers build against (row grammars, derived
# status per the counter frame, derived target per the declarer set,
# typed errors, the reserved GRP-000 split, the implied-bound display
# map, the cascade, the nudge counts, the render helpers).
#
# Also the BASH twin-parser leg for the SHIPPED groupings stream
# contract: the `## Entry schema` block of
# project-template/docs/project/groupings/_rules.md is parsed here with
# the same `- key: tokens` H2-block grammar the landed bash tools use
# (target-sweep.sh / _lib.sh pe_supporting_files_admitted), and its
# pinned keys are asserted — including the reserved-id cross-agreement
# line (the lib's hardcoded refusal fires on the ID the schema
# declares) and the target-enum declaration-order freeze (lib-ordinal
# == contract declaration order, asserted behaviorally on adjacent
# token pairs).
#
# Fixture pins: every fixture phase entry carries an explicit
# Entry-Type; statuses are always present-or-deliberately-shaped. One
# lib-only fixture (G7) carries a single present-but-empty `Status:`
# entry BECAUSE the B-prime poison rows require an unreadable input;
# no gate assertion rides on it; gate-asserted fixtures carry none.
# Fixtures are mktemp-local; nothing ships.
#
# Usage:    bash scripts/tests/test-groupings-lib.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

LIB="$PACK_ROOT/project-template/scripts/groupings-lib.sh"
GRULES="$PACK_ROOT/project-template/docs/project/groupings/_rules.md"
IPRULES="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"
GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-groupings-lib.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | sed 's/^/    /'
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

assert_eq() {
    # assert_eq <label> <want> <got>
    if [[ "$2" == "$3" ]]; then pass "$1"
    else fail "$1" "want: $2
 got: $3"; fi
}

assert_lines() {
    # assert_lines <label> <got> <want> — ORDERED byte equality over the
    # full output block (the row grammars are order-pinned).
    local d
    d="$(diff <(printf '%s\n' "$3") <(printf '%s\n' "$2") 2>&1)" || true
    if [[ -z "$d" ]]; then pass "$1"
    else fail "$1" "$d"; fi
}

assert_err() {
    # assert_err <label> <rc> <stderr> <code-substring>
    if [[ "$2" -ne 0 && "$3" == *"groupings-lib: ERROR($4):"* ]]; then
        pass "$1"
    else
        fail "$1" "rc=$2 stderr=$3 (wanted ERROR($4))"
    fi
}

for f in "$LIB" "$GRULES" "$IPRULES" "$GATE" "$ALLOWLIST"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done
if [[ $fails -gt 0 ]]; then
    echo "=== Results: $passes passed, $fails failed ==="
    exit 1
fi

# shellcheck disable=SC1090
. "$LIB"

# ── Builders ────────────────────────────────────────────────────────────
# write_epic <dir> <num> <status> <target|-> <blockers> <unblocks>
#            [dependencies] [prerequisite]
# A conforming phase-epic (all schema epic fields; bullet-bold labels).
write_epic() {
    local dir="$1" num="$2" status="$3" target="$4"
    local blockers="$5" unblocks="$6" deps="${7:-none}" prereq="${8:-none}"
    {
        printf '<!-- back -->\n## Phase %s — G%s\n\n' "$num" "$num"
        printf -- '- **Entry-Type**: phase-epic\n'
        printf -- '- **ID**: phase-%s\n' "$num"
        printf -- '- **Status**: %s\n' "$status"
        printf -- '- **Blockers**: %s\n' "$blockers"
        printf -- '- **Unblocks**: %s\n' "$unblocks"
        if [[ "$deps" != "none" ]]; then
            printf -- '- **Dependencies**: %s\n' "$deps"
        fi
        printf -- '- **Goal**: g\n'
        printf -- '- **Prerequisite**: %s\n' "$prereq"
        if [[ "$target" != "-" ]]; then
            printf -- '- **Target**: %s\n' "$target"
        fi
    } > "$dir/phase-${num}.md"
}

# write_part <dir> <num> — a lightweight phase-part file (Entry-Type only).
write_part() {
    printf '<!-- back -->\n### Phase-%s.Part-a — part\n\n- **Entry-Type**: phase-part\n' \
        "$2" > "$1/phase-${2}.md"
}

# write_grp <dir> <NNN> <kind> <title> <members-value> [exception]
# The closed D-grammar serialization (plain Field: value lines).
write_grp() {
    local dir="$1" nnn="$2" kind="$3" title="$4" members="$5" exc="${6:-}"
    {
        printf '<!-- per-entry source: docs/project/groupings/GRP-%s.md; contract: docs/project/groupings/_rules.md -->\n' "$nnn"
        printf '**GRP-%s — %s**\n' "$nnn" "$title"
        printf 'Entry-Type: grouping\n'
        printf 'Kind: %s\n' "$kind"
        if [[ -n "$members" ]]; then
            printf 'Member-phases: %s\n' "$members"
        else
            printf 'Member-phases:\n'
        fi
        if [[ -n "$exc" ]]; then
            printf 'Single-member exception: %s\n' "$exc"
        fi
    } > "$dir/GRP-${nnn}.md"
}

# stage_impl <dir> — an impl-plan dir carrying the REAL shipped contract.
stage_impl() {
    mkdir -p "$1"
    cp "$IPRULES" "$1/_rules.md"
}

# schema_key <key> — the BASH twin-parse of the SHIPPED groupings
# contract's `## Entry schema` block (the `- key: tokens` H2 grammar the
# landed bash tools speak).
schema_key() {
    awk -v want="$1" '
        /^## Entry schema/ { insec = 1; next }
        /^## /             { insec = 0 }
        insec && /^- /     {
            line = $0
            sub(/^- /, "", line)
            idx = index(line, ":")
            if (idx > 0) {
                key = substr(line, 1, idx - 1)
                val = substr(line, idx + 1)
                gsub(/^[ \t]+|[ \t]+$/, "", key)
                gsub(/^[ \t]+|[ \t]+$/, "", val)
                if (key == want) { print val; exit }
            }
        }
    ' "$GRULES"
}

echo "== BD-262 groupings-lib.sh API-freeze battery =="

# ── G1: sourceable-only + the frozen public API surface ────────────────
echo "-- G1: sourcing + API surface --"
if bash --norc -c ". '$LIB'" 2>/dev/null; then
    pass "G1.1 lib sources cleanly under bash --norc (no top-level side effects)"
else
    fail "G1.1 lib sources cleanly under bash --norc"
fi
API_FNS="grp_scan grp_real grp_reverse_lookup grp_reverse_map grp_deps \
grp_order grp_shared_with grp_phase_status_map grp_phase_target_map \
grp_implied_target_map grp_rollup_map grp_rollup grp_cascade \
grp_nudge_counts grp_render_flags grp_render_pct"
for fn in $API_FNS; do
    if [[ "$(type -t "$fn")" == "function" ]]; then
        pass "G1.2 API function defined: $fn"
    else
        fail "G1.2 API function defined: $fn"
    fi
done
if head -c 2000 "$LIB" | grep -q '^# pack-internal: true'; then
    pass "G1.3 lib carries the pack-internal marker (internal helper, no help row)"
else
    fail "G1.3 lib carries the pack-internal marker"
fi

# ── G2: the shipped contract's schema block (BASH twin-parser leg) ──────
echo "-- G2: shipped _rules.md schema block parses under the bash twin grammar --"
assert_eq "G2.1 entry-type" "grouping" "$(schema_key entry-type)"
assert_eq "G2.2 core-fields" "ID Kind Member-phases" "$(schema_key core-fields)"
assert_eq "G2.3 kind-enum (the fixed 10, unassigned last)" \
    "user-journey ambient-feature foundational-batch refactor-cluster release-package shared-feature architectural-pattern tech-debt-removal bug-fix unassigned" \
    "$(schema_key kind-enum)"
assert_eq "G2.4 kind-enum token count is exactly 10" \
    "10" "$(schema_key kind-enum | wc -w | tr -d ' ')"
assert_eq "G2.5 optional-fields" \
    '"Single-member exception" Doc-links Comment' "$(schema_key optional-fields)"
assert_eq "G2.6 exception-field" \
    '"Single-member exception"' "$(schema_key exception-field)"
assert_eq "G2.7 member-ref-pattern" "phase-N" "$(schema_key member-ref-pattern)"
assert_eq "G2.8 min-members" "2" "$(schema_key min-members)"
assert_eq "G2.9 field-order" \
    'Entry-Type Kind Member-phases "Single-member exception" Doc-links Comment' \
    "$(schema_key field-order)"
assert_eq "G2.10 reserved-id" "GRP-000" "$(schema_key reserved-id)"

# ── G3: reserved-ID cross-agreement (schema key <-> hardcoded refusal) ──
echo "-- G3: reserved-ID cross-agreement --"
R3="$FIXTURE_BASE/g3"; mkdir -p "$R3/g"; stage_impl "$R3/ip"
RES_ID="$(schema_key reserved-id)"
write_grp "$R3/g" "${RES_ID#GRP-}" unassigned "Ungrouped (declared)" "phase-1"
err="$( { grp_rollup "$R3/g" "$R3/ip" "$RES_ID" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G3.1 grp_rollup refuses the SCHEMA-declared reserved ID (target-blind refusal)" \
    "$rc" "$err" "reserved"
err="$( { grp_shared_with "$R3/g" "$RES_ID" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G3.2 grp_shared_with refuses the schema-declared reserved ID" \
    "$rc" "$err" "reserved"

# ── G4: grp_scan / grp_real — records, regex kill/admit, typed errors ───
echo "-- G4: scan records + entry-regex + typed errors --"
R4="$FIXTURE_BASE/g4"; mkdir -p "$R4/g"
write_grp "$R4/g" 000 unassigned "Ungrouped (declared)" "phase-7"
write_grp "$R4/g" 001 user-journey "Auth flows" "phase-1, phase-2"
write_grp "$R4/g" 002 shared-feature "Rescue" "phase-6" "single survivor"
write_grp "$R4/g" 1000 refactor-cluster "Big split" "phase-1, phase-6"
write_grp "$R4/g" 0000 bug-fix "Masquerade" "phase-1"   # regex-killed
SCAN_WANT="$(printf 'GRP-000\tunassigned\treserved\tphase-7\tUngrouped (declared)\nGRP-001\tuser-journey\treal\tphase-1,phase-2\tAuth flows\nGRP-002\tshared-feature\treal\tphase-6\tRescue\nGRP-1000\trefactor-cluster\treal\tphase-1,phase-6\tBig split')"
assert_lines "G4.1 grp_scan rows (TAB grammar; GRP-0000 regex-killed; GRP-1000 admitted; reserved flag)" \
    "$(grp_scan "$R4/g")" "$SCAN_WANT"
REAL_WANT="$(printf 'GRP-001\tuser-journey\treal\tphase-1,phase-2\tAuth flows\nGRP-002\tshared-feature\treal\tphase-6\tRescue\nGRP-1000\trefactor-cluster\treal\tphase-1,phase-6\tBig split')"
assert_lines "G4.2 grp_real excludes the reserved record" \
    "$(grp_real "$R4/g")" "$REAL_WANT"
R4E="$FIXTURE_BASE/g4-empty"; mkdir -p "$R4E"
out="$(grp_scan "$R4E")"; rc=$?
if [[ $rc -eq 0 && -z "$out" ]]; then
    pass "G4.3 empty groupings tree: empty output, exit 0"
else
    fail "G4.3 empty groupings tree: empty output, exit 0" "rc=$rc out=$out"
fi
err="$( { grp_scan "$FIXTURE_BASE/does-not-exist" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G4.4 missing groupings dir -> ERROR(no-tree)" "$rc" "$err" "no-tree"
R4M="$FIXTURE_BASE/g4-malformed"; mkdir -p "$R4M"
printf '<!-- bp -->\n**GRP-001 — Broken**\nEntry-Type: grouping\nKind: bug-fix\n' \
    > "$R4M/GRP-001.md"   # no Member-phases line
err="$( { grp_scan "$R4M" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G4.5 malformed entry (no Member-phases) -> ERROR(parse)" "$rc" "$err" "parse"
if [[ "$err" == *"GRP-001.md"* ]]; then
    pass "G4.6 the parse error names the offending file"
else
    fail "G4.6 the parse error names the offending file" "$err"
fi
R4M2="$FIXTURE_BASE/g4-badtoken"; mkdir -p "$R4M2"
write_grp "$R4M2" 001 bug-fix "Bad member" "phase-1, phase-2.Part-a"
err="$( { grp_scan "$R4M2" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G4.7 a part-ref member token (phase-2.Part-a) -> ERROR(parse) (closed phase-N grammar)" \
    "$rc" "$err" "parse"

# ── G5: B-prime derived-status golden set (row-for-row, flag bytes) ─────
echo "-- G5: derived-status rollup goldens (the ruled table, machine rows) --"
R5="$FIXTURE_BASE/g5"; mkdir -p "$R5/g"; stage_impl "$R5/ip"
write_epic "$R5/ip" 1  done        - none none
write_epic "$R5/ip" 2  deferred    - none none
write_epic "$R5/ip" 3  in-progress - none none
write_epic "$R5/ip" 4  not-started - none none
write_epic "$R5/ip" 5  blocked     - none none
write_epic "$R5/ip" 6  superseded  - none none
write_epic "$R5/ip" 7  done        - none none
write_part "$R5/ip" 8
write_epic "$R5/ip" 10 deferred    - none none
write_epic "$R5/ip" 11 superseded  - none none
# phase-9 deliberately ABSENT (the dangling-member geometry).
write_grp "$R5/g" 001 user-journey "DD"    "phase-1, phase-2"
write_grp "$R5/g" 002 user-journey "DDI"   "phase-1, phase-2, phase-3"
write_grp "$R5/g" 003 user-journey "ID"    "phase-2, phase-3"
write_grp "$R5/g" 004 user-journey "DefDef" "phase-2, phase-10"
write_grp "$R5/g" 005 user-journey "NsDef" "phase-2, phase-4"
write_grp "$R5/g" 006 user-journey "DoneB" "phase-1, phase-5"
write_grp "$R5/g" 007 user-journey "DoneS" "phase-1, phase-6"
write_grp "$R5/g" 008 user-journey "DDS"   "phase-1, phase-6, phase-7"
write_grp "$R5/g" 009 user-journey "Dangle" "phase-1, phase-9"
write_grp "$R5/g" 010 user-journey "PartM" "phase-1, phase-8"
write_grp "$R5/g" 011 user-journey "NsB"   "phase-4, phase-5"
write_grp "$R5/g" 012 user-journey "SupSup" "phase-6, phase-11"
write_grp "$R5/g" 013 user-journey "EmptyS" ""
write_grp "$R5/g" 014 user-journey "Mix"   "phase-1, phase-3, phase-4"
ROLLUP_WANT="GRP-001 deferred 1/2 50 b=0 d=1 s=0 u=0 tgt=- t=0
GRP-002 blocked 1/3 33 b=0 d=1 s=0 u=0 tgt=- t=0
GRP-003 blocked 0/2 0 b=0 d=1 s=0 u=0 tgt=- t=0
GRP-004 deferred 0/2 0 b=0 d=2 s=0 u=0 tgt=- t=0
GRP-005 blocked 0/2 0 b=0 d=1 s=0 u=0 tgt=- t=0
GRP-006 blocked 1/2 50 b=1 d=0 s=0 u=0 tgt=- t=0
GRP-007 complete 1/1 100 b=0 d=0 s=1 u=0 tgt=- t=0
GRP-008 complete 2/2 100 b=0 d=0 s=1 u=0 tgt=- t=0
GRP-009 unknown 1/2 - b=0 d=0 s=0 u=1 tgt=- t=0
GRP-010 unknown 1/2 - b=0 d=0 s=0 u=1 tgt=- t=0
GRP-011 not-started 0/2 0 b=1 d=0 s=0 u=0 tgt=- t=0
GRP-012 superseded 0/0 - b=0 d=0 s=2 u=0 tgt=- t=0
GRP-013 unknown 0/0 - b=0 d=0 s=0 u=0 tgt=- t=0
GRP-014 in-progress 1/3 33 b=0 d=0 s=0 u=0 tgt=- t=0"
assert_lines "G5.1 the derived-status table row-for-row (counters always emitted; u>0 and 0/0 never render a clean fraction; S-empty -> unknown; part-member == dangling class)" \
    "$(grp_rollup_map "$R5/g" "$R5/ip")" "$ROLLUP_WANT"
assert_lines "G5.2 grp_rollup single accessor row == its map row" \
    "$(grp_rollup "$R5/g" "$R5/ip" GRP-001)" \
    "GRP-001 deferred 1/2 50 b=0 d=1 s=0 u=0 tgt=- t=0"
err="$( { grp_rollup "$R5/g" "$R5/ip" GRP-099 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G5.3 unknown grouping -> ERROR(unknown-id)" "$rc" "$err" "unknown-id"
err="$( { grp_rollup "$R5/g" "$R5/ip" GRP-1 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G5.4 malformed GRP argument -> ERROR(bad-ref)" "$rc" "$err" "bad-ref"

# ── G6: derived-target golden set (the declarer-set + poison pins) ──────
echo "-- G6: derived-target goldens --"
R6="$FIXTURE_BASE/g6"; mkdir -p "$R6/g"; stage_impl "$R6/ip"
write_epic "$R6/ip" 1  not-started current           none none
write_epic "$R6/ip" 2  not-started next-major        none none
write_epic "$R6/ip" 3  done        next-major        none none
write_epic "$R6/ip" 4  not-started v9.9              none none
write_epic "$R6/ip" 5  deferred    next-major        none none
write_epic "$R6/ip" 6  in-progress current           none none
write_epic "$R6/ip" 7  superseded  next-major        none none
write_epic "$R6/ip" 8  not-started -                 none none
write_epic "$R6/ip" 9  done        current           none none
write_epic "$R6/ip" 10 done        v8.old            none none
write_epic "$R6/ip" 11 not-started future-unassigned none none
write_epic "$R6/ip" 12 done        -                 none none
write_epic "$R6/ip" 13 done        current           none none
write_epic "$R6/ip" 14 not-started next-release      none none
write_epic "$R6/ip" 15 not-started next-minor        none none
write_grp "$R6/g" 001 user-journey "Mixed"        "phase-1, phase-2"
write_grp "$R6/g" 002 user-journey "FuDrag"       "phase-1, phase-11"
write_grp "$R6/g" 003 user-journey "ZeroTarget"   "phase-8, phase-12"
write_grp "$R6/g" 004 user-journey "IllegalLive"  "phase-1, phase-4"
write_grp "$R6/g" 005 user-journey "IllegalDone"  "phase-1, phase-10"
write_grp "$R6/g" 006 user-journey "DefLoose"     "phase-5, phase-6"
write_grp "$R6/g" 007 user-journey "DoneLoose"    "phase-1, phase-3"
write_grp "$R6/g" 008 user-journey "SupLoose"     "phase-1, phase-7"
write_grp "$R6/g" 009 user-journey "AllDone"      "phase-9, phase-13"
write_grp "$R6/g" 010 user-journey "PairRelease"  "phase-1, phase-14"
write_grp "$R6/g" 011 user-journey "PairMajor"    "phase-2, phase-15"
write_grp "$R6/g" 012 user-journey "PairMinor"    "phase-14, phase-15"
TGT_WANT="GRP-001 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=next-major t=2
GRP-002 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=future-unassigned t=2
GRP-003 in-progress 1/2 50 b=0 d=0 s=0 u=0 tgt=- t=0
GRP-004 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=unknown t=1
GRP-005 in-progress 1/2 50 b=0 d=0 s=0 u=0 tgt=unknown t=1
GRP-006 blocked 0/2 0 b=0 d=1 s=0 u=0 tgt=next-major t=2
GRP-007 in-progress 1/2 50 b=0 d=0 s=0 u=0 tgt=current t=1
GRP-008 not-started 0/1 0 b=0 d=0 s=1 u=0 tgt=current t=1
GRP-009 complete 2/2 100 b=0 d=0 s=0 u=0 tgt=- t=0
GRP-010 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=next-release t=2
GRP-011 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=next-major t=2
GRP-012 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=next-minor t=2"
assert_lines "G6.1 the derived-target goldens: mixed max / fu drag / zero-target rows carry tgt=- t=0 / present-illegal poison incl. ILLEGAL-ON-DONE-MEMBER / deferred target dominates / done+superseded loose targets excluded from the max / all-done -> tgt=- t=0 beside complete / adjacent-pair dominance (lib-ordinal == contract declaration order)" \
    "$(grp_rollup_map "$R6/g" "$R6/ip")" "$TGT_WANT"
assert_lines "G6.2 grp_phase_target_map: STATUS-BLIND pure parse (illegal->unknown, absent->-)" \
    "$(grp_phase_target_map "$R6/ip" | sed -n '1,4p;8,10p')" \
    "phase-1 current
phase-2 next-major
phase-3 next-major
phase-4 unknown
phase-8 -
phase-9 current
phase-10 unknown"

# ── G7: cross-parser Status fixture (lib grammar == the shipped gate) ───
echo "-- G7: cross-parser Status fixture --"
R7="$FIXTURE_BASE/g7"; stage_impl "$R7/docs/project/implementation-plan"
mkdir -p "$R7/scripts"
cp "$GATE" "$R7/scripts/validate-docs.sh"
cp "$ALLOWLIST" "$R7/scripts/.docs-gate-allowlist.txt"
chmod +x "$R7/scripts/validate-docs.sh"
IP7="$R7/docs/project/implementation-plan"
write_epic "$IP7" 1 done - none none
# plain-label form (the gate grammar admits bold / plain / bullet).
printf '<!-- back -->\n## Phase 2 — G2\n\nEntry-Type: phase-epic\nID: phase-2\nStatus: in-progress\nBlockers: none\nUnblocks: none\nGoal: g\nPrerequisite: none\n' \
    > "$IP7/phase-2.md"
# bullet-plain form.
printf '<!-- back -->\n## Phase 3 — G3\n\n- Entry-Type: phase-epic\n- ID: phase-3\n- Status: blocked\n- Blockers: none\n- Unblocks: none\n- Goal: g\n- Prerequisite: none\n' \
    > "$IP7/phase-3.md"
write_epic "$IP7" 4 wip - none none
write_epic "$IP7" 5 "" - none none
# phase-6: Status field ABSENT entirely.
printf '<!-- back -->\n## Phase 6 — G6\n\n- **Entry-Type**: phase-epic\n- **ID**: phase-6\n- **Blockers**: none\n- **Unblocks**: none\n- **Goal**: g\n- **Prerequisite**: none\n' \
    > "$IP7/phase-6.md"
assert_lines "G7.1 lib status map: three label forms parse; out-of-enum / empty / missing -> unknown" \
    "$(grp_phase_status_map "$IP7")" \
    "phase-1 done
phase-2 in-progress
phase-3 blocked
phase-4 unknown
phase-5 unknown
phase-6 unknown"
gate_out="$(bash "$R7/scripts/validate-docs.sh" 2>&1)" || true
if printf '%s\n' "$gate_out" | grep -q "phase-4.md \[conformance\] Status 'wip' not in status-enum"; then
    pass "G7.2 gate agreement: the out-of-enum value the lib maps to unknown is the gate's enum FAIL"
else
    fail "G7.2 gate agreement: expected the phase-4 Status enum FAIL" "$gate_out"
fi
if printf '%s\n' "$gate_out" | grep -E "phase-[123]\.md .*Status '" >/dev/null; then
    fail "G7.3 gate agreement: legal statuses (all three label forms) must carry NO Status enum FAIL" \
        "$(printf '%s\n' "$gate_out" | grep -E "phase-[123]\.md .*Status '")"
else
    pass "G7.3 gate agreement: legal statuses (all three label forms) carry no Status enum FAIL"
fi
if printf '%s\n' "$gate_out" | grep -q "phase-6.md \[conformance\] phase-epic missing field 'Status'"; then
    pass "G7.4 gate agreement: the missing-field case the lib maps to unknown is the gate's missing-field FAIL"
else
    fail "G7.4 gate agreement: expected the phase-6 missing-Status FAIL" "$gate_out"
fi

# ── G8: the implied-bound display map (via=- pins; self-clause) ─────────
echo "-- G8: implied-target display map --"
R8="$FIXTURE_BASE/g8"; stage_impl "$R8/ip"
write_epic "$R8/ip" 1 not-started next-major none phase-2
write_epic "$R8/ip" 2 not-started - phase-1 "phase-3 phase-4"
write_epic "$R8/ip" 3 done - phase-2 phase-2
write_epic "$R8/ip" 4 not-started current phase-2 none
write_epic "$R8/ip" 6 wip - none none
assert_lines "G8.1 implied map: bounds flow through the done-broken cycle (absorbing cut); via = the arg-min direct witness; receivers-with-no-bound and absorbing phases render '- -'; an unreadable-status phase renders 'unknown -' (via=- whenever impl is not a token)" \
    "$(grp_implied_target_map "$R8/ip")" \
    "phase-1 current phase-2
phase-2 current phase-4
phase-3 - -
phase-4 - -
phase-6 unknown -"
R8B="$FIXTURE_BASE/g8b"; stage_impl "$R8B/ip"
write_epic "$R8B/ip" 1 not-started next-major none "phase-2 phase-3"
write_epic "$R8B/ip" 2 not-started v9.9 phase-1 none
write_epic "$R8B/ip" 3 not-started current phase-1 none
assert_lines "G8.2 implied map: adjacent poison — upstream displays unknown (the display never asserts a bound a garble could void); the poison source itself renders '- -'" \
    "$(grp_implied_target_map "$R8B/ip")" \
    "phase-1 unknown -
phase-2 - -
phase-3 - -"

# ── G9: cascade + deps agreement + order + reverse + shared + counts ────
echo "-- G9: cascade / deps / order / reverse / counts --"
R9="$FIXTURE_BASE/g9"; mkdir -p "$R9/g"; stage_impl "$R9/ip"
write_epic "$R9/ip" 1  deferred    - none phase-2
write_epic "$R9/ip" 2  not-started - phase-1 "phase-3, phase-4"
write_epic "$R9/ip" 3  not-started - none none "phase-2"
write_epic "$R9/ip" 4  not-started - none none "" "phase-3 and phase-2"
write_epic "$R9/ip" 5  superseded  - none phase-6
write_epic "$R9/ip" 6  done        - none none
write_epic "$R9/ip" 7  not-started - none none
write_epic "$R9/ip" 8  not-started - none phase-9
write_epic "$R9/ip" 9  not-started - none phase-8
write_epic "$R9/ip" 10 not-started - none none
write_grp "$R9/g" 000 unassigned "Ungrouped (declared)" "phase-7"
write_grp "$R9/g" 001 foundational-batch "Base" "phase-1, phase-2"
write_grp "$R9/g" 002 user-journey "Flow" "phase-3, phase-4"
write_grp "$R9/g" 003 shared-feature "Rescue" "phase-6" "single survivor"
write_grp "$R9/g" 004 refactor-cluster "TwinA" "phase-8"
write_grp "$R9/g" 005 refactor-cluster "TwinB" "phase-9"
write_grp "$R9/g" 006 release-package "Overlap" "phase-2, phase-3"
CASCADE_WANT="source phase-1 status=deferred groups=GRP-001
source phase-5 status=superseded groups=-
poisoned phase-2 via=phase-1 groups=GRP-001,GRP-006
poisoned phase-3 via=phase-2 groups=GRP-002,GRP-006
poisoned phase-4 via=phase-2,phase-3 groups=GRP-002
poisoned phase-6 via=phase-5 groups=GRP-003"
assert_lines "G9.1 cascade: deferred+superseded sources; forward closure over the four-field grammar (comma / space / 'and' separators); per-phase edge attribution; grouping annotation" \
    "$(grp_cascade "$R9/g" "$R9/ip")" "$CASCADE_WANT"
DEPS_WANT="GRP-001 GRP-002
GRP-001 GRP-006
GRP-004 GRP-005
GRP-005 GRP-004
GRP-006 GRP-002"
assert_lines "G9.2 grp_deps: derived inter-grouping edges (REAL set; intra-grouping edges never emit)" \
    "$(grp_deps "$R9/g" "$R9/ip")" "$DEPS_WANT"
# The cascade-vs-grp_deps agreement line: the SAME phase edge (2->3)
# that derives the GRP-001->GRP-006/GRP-006->GRP-002 dep rows is the
# edge the cascade walked to poison phase-3 via phase-2 — one edge-parse
# point, two consumers, identical reading.
if printf '%s\n' "$CASCADE_WANT" | grep -q 'poisoned phase-3 via=phase-2' \
   && printf '%s\n' "$DEPS_WANT" | grep -q 'GRP-006 GRP-002'; then
    pass "G9.3 cascade-vs-grp_deps agreement: both readers consumed the identical phase-2->phase-3 edge"
else
    fail "G9.3 cascade-vs-grp_deps agreement fixture is self-inconsistent"
fi
order_got="$(grp_order "$R9/g" "$R9/ip")"
if printf '%s\n' "$order_got" | grep -q '^interleaved: GRP-004 GRP-005$'; then
    pass "G9.4 grp_order: mutually-dependent groupings print as ONE interleaved cluster"
else
    fail "G9.4 grp_order: expected the interleaved GRP-004/GRP-005 cluster" "$order_got"
fi
n1="$(printf '%s\n' "$order_got" | grep -n '^GRP-001$' | cut -d: -f1)"
n2="$(printf '%s\n' "$order_got" | grep -n '^GRP-002$' | cut -d: -f1)"
n6="$(printf '%s\n' "$order_got" | grep -n '^GRP-006$' | cut -d: -f1)"
if [[ -n "$n1" && -n "$n2" && -n "$n6" && "$n1" -lt "$n6" && "$n6" -lt "$n2" ]]; then
    pass "G9.5 grp_order: topological (GRP-001 before GRP-006 before GRP-002); ties alphabetical"
else
    fail "G9.5 grp_order: topological order violated" "$order_got"
fi
assert_lines "G9.6 grp_reverse_map rows (memberships CSV ascending; GRP-000 included)" \
    "$(grp_reverse_map "$R9/g")" \
    "phase-1 GRP-001
phase-2 GRP-001,GRP-006
phase-3 GRP-002,GRP-006
phase-4 GRP-002
phase-6 GRP-003
phase-7 GRP-000
phase-8 GRP-004
phase-9 GRP-005"
assert_lines "G9.7 grp_reverse_lookup phase-2" \
    "$(grp_reverse_lookup "$R9/g" phase-2)" \
    "GRP-001
GRP-006"
err="$( { grp_reverse_lookup "$R9/g" "TD-1" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G9.8 malformed phase argument -> ERROR(bad-ref)" "$rc" "$err" "bad-ref"
assert_lines "G9.9 grp_shared_with GRP-001 (shares phase-2 with GRP-006)" \
    "$(grp_shared_with "$R9/g" GRP-001)" "GRP-006"
err="$( { grp_shared_with "$R9/g" GRP-099 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G9.10 grp_shared_with unknown grouping -> ERROR(unknown-id)" "$rc" "$err" "unknown-id"
assert_eq "G9.11 grp_nudge_counts: N real; M = living epics in nothing (superseded orphan excluded); K = living GRP-000 members" \
    "N=6 M=1 K=1" "$(grp_nudge_counts "$R9/g" "$R9/ip")"
map_out="$(grp_rollup_map "$R9/g" "$R9/ip")"; rc=$?
if [[ $rc -eq 0 && -n "$map_out" && "$map_out" != *"GRP-000"* ]]; then
    pass "G9.12 grp_rollup_map: NO row for reserved GRP-000 (present with members; reserved-set exclusion)"
else
    fail "G9.12 grp_rollup_map: NO row for reserved GRP-000 (present with members; reserved-set exclusion)" \
        "rc=$rc
$map_out"
fi

# ── G10: render helpers (the single display implementation) ─────────────
echo "-- G10: render helpers --"
assert_eq "G10.1 flags: fixed order b, d, s, u; render iff counter > 0" \
    "[1 blocked] [2 deferred] [1 superseded] [3 unreadable]" \
    "$(grp_render_flags 1 2 1 3)"
assert_eq "G10.2 flags: single family" "[1 deferred]" "$(grp_render_flags 0 1 0 0)"
assert_eq "G10.3 flags: all-zero renders empty" "" "$(grp_render_flags 0 0 0 0)"
assert_eq "G10.4 pct: numeric renders (NN%)" "(50%)" "$(grp_render_pct 50)"
assert_eq "G10.5 pct: '-' renders the em-dash" "—" "$(grp_render_pct -)"

# ── G11: the target-vocabulary contract (order freeze + fail-loud) ──────
echo "-- G11: target-enum contract --"
if grep -q '^- target-enum: current next-release next-minor next-major future-unassigned$' "$IPRULES"; then
    pass "G11.1 shipped contract target-enum declaration order == the frozen ordinal scale"
else
    fail "G11.1 shipped contract target-enum declaration order changed" \
        "$(grep '^- target-enum' "$IPRULES")"
fi
R11="$FIXTURE_BASE/g11"; mkdir -p "$R11/ip"
printf '# Stream contract — project-implementation-plan\n\n## Entry schema\n\n- entry-types: phase-epic phase-part\n' > "$R11/ip/_rules.md"
write_epic "$R11/ip" 1 not-started current none none
err="$( { grp_phase_target_map "$R11/ip" 1>/dev/null; } 2>&1 )"; rc=$?
assert_err "G11.2 a contract without target-enum -> ERROR(parse) (fail-loud, no silent vocabulary)" \
    "$rc" "$err" "parse"

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
