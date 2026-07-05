#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-groupings-cli.sh — the BD-265 groupings.sh query-CLI
# battery: golden outputs per verb (list / list-membership / deps /
# order / shared-with), the -q machine rows (library grammars verbatim
# — the thin-presentation-layer parity probe), the composed detail
# header with its target-suffix arms, the GRP-000 reserved split
# (count-only header; tail line; machine-row refusal surfaced
# verbatim), the typed-error goldens for all FIVE codes
# (unknown-id / bad-ref / no-tree / parse / reserved), and the
# `deps --deferral` cascade view (target annotation rows + the
# per-affected-grouping poisoned-max worked rows incl. the drop-9
# delta and the unknown arm + the untargeted-deferred-blocker tension
# row), the cross-parser drift-geometry leg (a variant-spacing
# `target-enum:` schema line: the CLI's poisoned-max must agree with a
# lib-derived expectation on the same tree — the twin-parser agreement
# test), the NBSP separator-class leg (an NBSP-bearing enum value: the
# lib splits on its runtime's separator-class whitespace; the CLI must
# agree), and the list join-integrity fail-loud probe (a staged lib
# override drops a REAL rollup row; the CLI must emit a typed parse
# error, never a silent row-drop at rc=0).
#
# Goldens are authored ONCE, derived-status-aware and target-aware from
# birth (the settled derivation table + declarer-set/poison pins the
# library froze in scripts/tests/test-groupings-lib.sh). Dependency
# edges in fixtures use the four-field grammar (Blockers / Dependencies
# / Prerequisite contribute prereq edges, Unblocks contributes
# dependent edges — the validate-docs.sh `_conf_index_edges` twin the
# library implements).
#
# Fixture pins: every fixture phase entry carries an explicit
# Entry-Type; fixtures are mktemp-local; nothing ships. Fixtures build
# the installed layout (docs/project/{groupings,implementation-plan}
# under a root) and drive the CLI via --root.
#
# Usage:    bash scripts/tests/test-groupings-cli.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLI="$PACK_ROOT/project-template/scripts/groupings.sh"
LIB="$PACK_ROOT/project-template/scripts/groupings-lib.sh"
IPRULES="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"

FIXTURE_BASE="$(mktemp -d -t test-groupings-cli.XXXXXX)"
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
    # full output block (row grammars and goldens are byte-pinned).
    local d
    d="$(diff <(printf '%s\n' "$3") <(printf '%s\n' "$2") 2>&1)" || true
    if [[ -z "$d" ]]; then pass "$1"
    else fail "$1" "$d"; fi
}

assert_cli_err() {
    # assert_cli_err <label> <rc> <stderr> <code> [<prefix>]
    # rc must be non-zero; stderr must carry ERROR(<code>): and, when a
    # prefix is given, start with it (groupings-lib: = surfaced
    # verbatim; groupings: = dispatch-level).
    local want_prefix="${5:-}"
    if [[ "$2" -ne 0 && "$3" == *"ERROR($4):"* ]]; then
        if [[ -n "$want_prefix" && "$3" != "$want_prefix"* ]]; then
            fail "$1" "rc=$2 stderr=$3 (wanted prefix '$want_prefix')"
        else
            pass "$1"
        fi
    else
        fail "$1" "rc=$2 stderr=$3 (wanted ERROR($4))"
    fi
}

for f in "$CLI" "$LIB" "$IPRULES"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done
if [[ $fails -gt 0 ]]; then
    echo "=== Results: $passes passed, $fails failed ==="
    exit 1
fi

# The library is sourced ONLY for the thin-layer parity probes (CLI -q
# bytes == direct library bytes); the CLI under test sources its own
# copy.
# shellcheck disable=SC1090
. "$LIB"

# ── Builders (the test-groupings-lib.sh forms, root-layout staged) ──────
# write_epic <dir> <num> <status> <target|-> <blockers> <unblocks>
#            [dependencies] [prerequisite]
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

# write_grp <dir> <NNN> <kind> <title> <members-value> [exception]
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

# stage_root <root> — the installed docs/project layout with the REAL
# shipped impl-plan contract (target-enum vocabulary source).
stage_root() {
    mkdir -p "$1/docs/project/groupings" "$1/docs/project/implementation-plan"
    cp "$IPRULES" "$1/docs/project/implementation-plan/_rules.md"
}

run_cli() {  # run_cli <root> <args...>; sets OUT, ERR, RC
    local root="$1"; shift
    local errf="$FIXTURE_BASE/stderr.$$"
    OUT="$(bash "$CLI" "$@" --root "$root" 2>"$errf")"
    RC=$?
    ERR="$(cat "$errf")"
    rm -f "$errf"
}

echo "== BD-265 groupings.sh query-CLI battery =="

# ── F1: the populated main fixture (status + target reach from birth) ──
F1="$FIXTURE_BASE/f1"; stage_root "$F1"
G1="$F1/docs/project/groupings"
I1="$F1/docs/project/implementation-plan"
write_epic "$I1" 1  done        -          none none
write_epic "$I1" 2  deferred    next-minor none none
write_epic "$I1" 3  in-progress -          none phase-4
write_epic "$I1" 4  not-started next-major none none
write_epic "$I1" 5  not-started v9.9       none none
write_epic "$I1" 6  superseded  -          none none
write_epic "$I1" 7  not-started -          none none
write_epic "$I1" 9  done        -          none none
write_epic "$I1" 11 not-started -          none phase-12
write_epic "$I1" 12 not-started -          none phase-11
write_epic "$I1" 13 done        -          none none
write_epic "$I1" 14 superseded  -          none none
write_grp "$G1" 000 unassigned        "Ungrouped (declared)" "phase-6, phase-9"
write_grp "$G1" 001 user-journey      "Auth epic" "phase-1, phase-2"
write_grp "$G1" 002 shared-feature    "Flow"      "phase-1, phase-3, phase-4"
write_grp "$G1" 003 refactor-cluster  "Poison"    "phase-4, phase-5"
write_grp "$G1" 004 tech-debt-removal "Bare"      "phase-1, phase-13"
write_grp "$G1" 005 refactor-cluster  "Solo A"    "phase-11" "pair pending"
write_grp "$G1" 006 refactor-cluster  "Solo B"    "phase-12" "pair pending"
write_grp "$G1" 007 bug-fix           "Dangle"    "phase-1, phase-99"
write_grp "$G1" 008 ambient-feature   "Overload"  "phase-2, phase-3"
write_grp "$G1" 009 release-package   "Sunset"    "phase-1, phase-14"

# ── C1: list (human rows: ID/Kind/status cluster/Target/Title/members;
#          GRP-000 excluded from rows; living-count tail line) ──────────
echo "-- C1: list --"
run_cli "$F1" list
assert_eq "C1.1 list exits 0" "0" "$RC"
assert_lines "C1.2 list golden: B-prime status clusters + flag bytes + bare-token Target column (incl. unknown poison + '-') + the GRP-000 living-count tail (superseded member excluded from K)" \
    "$OUT" \
    "GRP-001 — user-journey — deferred 1/2 (50%) [1 deferred] — next-minor — Auth epic — phase-1,phase-2
GRP-002 — shared-feature — in-progress 1/3 (33%) — next-major — Flow — phase-1,phase-3,phase-4
GRP-003 — refactor-cluster — not-started 0/2 (0%) — unknown — Poison — phase-4,phase-5
GRP-004 — tech-debt-removal — complete 2/2 (100%) — - — Bare — phase-1,phase-13
GRP-005 — refactor-cluster — not-started 0/1 (0%) — - — Solo A — phase-11
GRP-006 — refactor-cluster — not-started 0/1 (0%) — - — Solo B — phase-12
GRP-007 — bug-fix — unknown 1/2 — [1 unreadable] — - — Dangle — phase-1,phase-99
GRP-008 — ambient-feature — blocked 0/2 (0%) [1 deferred] — next-minor — Overload — phase-2,phase-3
GRP-009 — release-package — complete 1/1 (100%) [1 superseded] — - — Sunset — phase-1,phase-14
declared stays-ungrouped: 1"
run_cli "$F1" list -q
assert_eq "C1.3 list -q exits 0" "0" "$RC"
assert_lines "C1.4 list -q: the machine rollup rows verbatim (all fields always emitted; no GRP-000 row; no tail line)" \
    "$OUT" \
    "GRP-001 deferred 1/2 50 b=0 d=1 s=0 u=0 tgt=next-minor t=1
GRP-002 in-progress 1/3 33 b=0 d=0 s=0 u=0 tgt=next-major t=1
GRP-003 not-started 0/2 0 b=0 d=0 s=0 u=0 tgt=unknown t=1
GRP-004 complete 2/2 100 b=0 d=0 s=0 u=0 tgt=- t=0
GRP-005 not-started 0/1 0 b=0 d=0 s=0 u=0 tgt=- t=0
GRP-006 not-started 0/1 0 b=0 d=0 s=0 u=0 tgt=- t=0
GRP-007 unknown 1/2 - b=0 d=0 s=0 u=1 tgt=- t=0
GRP-008 blocked 0/2 0 b=0 d=1 s=0 u=0 tgt=next-minor t=1
GRP-009 complete 1/1 100 b=0 d=0 s=1 u=0 tgt=- t=0"
LIB_ROWS="$(grp_rollup_map "$G1" "$I1")"
assert_lines "C1.5 thin-layer parity: list -q bytes == grp_rollup_map bytes (no re-derivation)" \
    "$OUT" "$LIB_ROWS"

# ── C2: list-membership — phase arm ────────────────────────────────────
echo "-- C2: list-membership (phase arm) --"
run_cli "$F1" list-membership phase-1
assert_eq "C2.1 phase arm exits 0" "0" "$RC"
assert_lines "C2.2 phase-1 memberships ascending" "$OUT" \
    "GRP-001
GRP-002
GRP-004
GRP-007
GRP-009"
run_cli "$F1" list-membership phase-6
assert_lines "C2.3 a GRP-000 member's phase arm shows the ledger membership" \
    "$OUT" "GRP-000"
run_cli "$F1" list-membership phase-7
if [[ $RC -eq 0 && -z "$OUT" ]]; then
    pass "C2.4 ungrouped phase: empty result, exit 0"
else
    fail "C2.4 ungrouped phase: empty result, exit 0" "rc=$RC out=$OUT"
fi

# ── C3: list-membership — grouping arm (the composed detail header) ────
echo "-- C3: list-membership (grouping arm detail headers) --"
run_cli "$F1" list-membership GRP-001
assert_eq "C3.1 grouping arm exits 0" "0" "$RC"
assert_lines "C3.2 composed header NORMAL arm: Kind token + status cluster + '— <target> t=K/N' with N = A-D (done member shrinks N)" \
    "$OUT" \
    "GRP-001 — Auth epic — user-journey — deferred 1/2 (50%) [1 deferred] — next-minor t=1/1
phase-1
phase-2"
run_cli "$F1" list-membership GRP-003
assert_lines "C3.3 composed header POISON arm: '— unknown' bare (no t=K/N)" \
    "$OUT" \
    "GRP-003 — Poison — refactor-cluster — not-started 0/2 (0%) — unknown
phase-4
phase-5"
run_cli "$F1" list-membership GRP-004
assert_lines "C3.4 composed header ABSENT arm: no target suffix when tgt is '-'" \
    "$OUT" \
    "GRP-004 — Bare — tech-debt-removal — complete 2/2 (100%)
phase-1
phase-13"
run_cli "$F1" list-membership GRP-001 -q
assert_lines "C3.5 grouping arm -q: the machine rollup row verbatim + member tokens" \
    "$OUT" \
    "GRP-001 deferred 1/2 50 b=0 d=1 s=0 u=0 tgt=next-minor t=1
phase-1
phase-2"

# ── C4: the GRP-000 reserved split ──────────────────────────────────────
echo "-- C4: GRP-000 (count-only header; machine-row refusal verbatim) --"
run_cli "$F1" list-membership GRP-000
assert_eq "C4.1 GRP-000 human arm exits 0" "0" "$RC"
assert_lines "C4.2 GRP-000 count-only header (no derived status, no target) + member list" \
    "$OUT" \
    "GRP-000 — Ungrouped (declared) — declared stays-ungrouped: 1
phase-6
phase-9"
run_cli "$F1" list-membership GRP-000 -q
assert_cli_err "C4.3 GRP-000 -q: the library's reserved rollup refusal surfaced VERBATIM (groupings-lib: prefix)" \
    "$RC" "$ERR" "reserved" "groupings-lib:"

# ── C5: deps + order ────────────────────────────────────────────────────
echo "-- C5: deps / order --"
run_cli "$F1" deps
assert_eq "C5.1 deps exits 0" "0" "$RC"
assert_lines "C5.2 deps human rows (GRP-A -> GRP-B; GRP-000 never appears)" \
    "$OUT" \
    "GRP-002 -> GRP-003
GRP-005 -> GRP-006
GRP-006 -> GRP-005
GRP-008 -> GRP-002
GRP-008 -> GRP-003"
run_cli "$F1" deps -q
assert_lines "C5.3 deps -q: the library edge rows verbatim" \
    "$OUT" \
    "GRP-002 GRP-003
GRP-005 GRP-006
GRP-006 GRP-005
GRP-008 GRP-002
GRP-008 GRP-003"
run_cli "$F1" order
assert_eq "C5.4 order exits 0" "0" "$RC"
assert_lines "C5.5 order golden: topological (GRP-008 precedes GRP-002 precedes GRP-003), ties alphabetical, mutually-dependent pair as ONE interleaved cluster row" \
    "$OUT" \
    "GRP-001
GRP-004
interleaved: GRP-005 GRP-006
GRP-007
GRP-008
GRP-002
GRP-003
GRP-009"

# ── C6: shared-with ─────────────────────────────────────────────────────
echo "-- C6: shared-with --"
run_cli "$F1" shared-with GRP-001
assert_eq "C6.1 shared-with exits 0" "0" "$RC"
assert_lines "C6.2 shared-with GRP-001 (shares phase-1 and phase-2)" "$OUT" \
    "GRP-002
GRP-004
GRP-007
GRP-008
GRP-009"
run_cli "$F1" shared-with GRP-005
if [[ $RC -eq 0 && -z "$OUT" ]]; then
    pass "C6.3 no sharers: empty result, exit 0"
else
    fail "C6.3 no sharers: empty result, exit 0" "rc=$RC out=$OUT"
fi

# ── C7: the FIVE typed-error codes ──────────────────────────────────────
echo "-- C7: typed errors (all five codes) --"
run_cli "$F1" shared-with GRP-000
assert_cli_err "C7.1 reserved: shared-with GRP-000 as ARGUMENT refused (library line verbatim)" \
    "$RC" "$ERR" "reserved" "groupings-lib:"
run_cli "$F1" shared-with GRP-099
assert_cli_err "C7.2 unknown-id: shared-with on an absent grouping" \
    "$RC" "$ERR" "unknown-id" "groupings-lib:"
run_cli "$F1" list-membership GRP-099
assert_cli_err "C7.3 unknown-id: list-membership grouping arm (rollup accessor path)" \
    "$RC" "$ERR" "unknown-id" "groupings-lib:"
run_cli "$F1" shared-with GRP-1
assert_cli_err "C7.4 bad-ref: a malformed GRP reference (library shape check, verbatim)" \
    "$RC" "$ERR" "bad-ref" "groupings-lib:"
run_cli "$F1" list-membership TD-1
assert_cli_err "C7.5 bad-ref: a reference that is neither phase-N nor GRP-NNN (dispatch-level, groupings: prefix)" \
    "$RC" "$ERR" "bad-ref" "groupings:"
F_NOTREE="$FIXTURE_BASE/no-tree-root"; mkdir -p "$F_NOTREE"
run_cli "$F_NOTREE" list
assert_cli_err "C7.6 no-tree: missing groupings tree" \
    "$RC" "$ERR" "no-tree" "groupings-lib:"
F_PARSE="$FIXTURE_BASE/parse-root"; stage_root "$F_PARSE"
printf '<!-- bp -->\n**GRP-001 — Broken**\nEntry-Type: grouping\nKind: bug-fix\n' \
    > "$F_PARSE/docs/project/groupings/GRP-001.md"   # no Member-phases line
run_cli "$F_PARSE" list
assert_cli_err "C7.7 parse: a structurally unreadable grouping entry" \
    "$RC" "$ERR" "parse" "groupings-lib:"

# ── C8: empty-tree behaviors ────────────────────────────────────────────
echo "-- C8: empty tree --"
F_EMPTY="$FIXTURE_BASE/empty-root"; stage_root "$F_EMPTY"
for verb in list deps order; do
    run_cli "$F_EMPTY" "$verb"
    if [[ $RC -eq 0 && "$OUT" == "(no groupings)" ]]; then
        pass "C8.1 $verb on an empty tree: '(no groupings)', exit 0"
    else
        fail "C8.1 $verb on an empty tree: '(no groupings)', exit 0" "rc=$RC out=$OUT"
    fi
done
run_cli "$F_EMPTY" list -q
if [[ $RC -eq 0 && -z "$OUT" ]]; then
    pass "C8.2 list -q on an empty tree: zero rows, exit 0"
else
    fail "C8.2 list -q on an empty tree: zero rows, exit 0" "rc=$RC out=$OUT"
fi
for verb in deps order; do
    run_cli "$F_EMPTY" "$verb" -q
    if [[ $RC -eq 0 && -z "$OUT" ]]; then
        pass "C8.4 $verb -q on an empty tree: notice suppressed, zero rows, exit 0"
    else
        fail "C8.4 $verb -q on an empty tree: notice suppressed, zero rows, exit 0" "rc=$RC out=$OUT"
    fi
done
F_LEDGER="$FIXTURE_BASE/ledger-root"; stage_root "$F_LEDGER"
write_epic "$F_LEDGER/docs/project/implementation-plan" 1 not-started - none none
write_grp "$F_LEDGER/docs/project/groupings" 000 unassigned "Ungrouped (declared)" "phase-1"
run_cli "$F_LEDGER" list
assert_lines "C8.3 GRP-000-only tree: '(no groupings)' + the tail line (REAL-set split)" \
    "$OUT" \
    "(no groupings)
declared stays-ungrouped: 1"

# ── C9: deps --deferral (the cascade view) ──────────────────────────────
echo "-- C9: deps --deferral --"
F2="$FIXTURE_BASE/f2"; stage_root "$F2"
G2="$F2/docs/project/groupings"
I2="$F2/docs/project/implementation-plan"
write_epic "$I2" 2  deferred    -                 none phase-3
write_epic "$I2" 3  not-started next-minor        none none
write_epic "$I2" 5  done        next-major        none none
write_epic "$I2" 7  deferred    next-minor        none "phase-5 phase-9 phase-11"
write_epic "$I2" 9  in-progress future-unassigned none none
write_epic "$I2" 11 in-progress v9.9              none none
write_grp "$G2" 301 release-package "Drag"    "phase-5, phase-7, phase-9"
write_grp "$G2" 302 release-package "Delta"   "phase-5, phase-7"
write_grp "$G2" 303 user-journey    "Tension" "phase-2, phase-3"
write_grp "$G2" 304 bug-fix         "Bad"     "phase-7, phase-11"
run_cli "$F2" deps --deferral
assert_eq "C9.1 deps --deferral exits 0" "0" "$RC"
assert_lines "C9.2 cascade view golden: library source/poisoned rows verbatim; per-phase 'tgt= impl= via=' annotation rows incl. the TENSION row (untargeted deferred blocker phase-2 with an implied bound via phase-3); poisoned-max worked rows — GRP-301 future-unassigned drag, GRP-302 the drop-9 delta (next-minor), GRP-304 unknown on an illegal target; done member phase-5 never counts" \
    "$OUT" \
    "source phase-2 status=deferred groups=GRP-303
  tgt=- impl=next-minor via=phase-3
source phase-7 status=deferred groups=GRP-301,GRP-302,GRP-304
  tgt=next-minor impl=unknown via=-
poisoned phase-3 via=phase-2 groups=GRP-303
  tgt=next-minor impl=- via=-
poisoned phase-5 via=phase-7 groups=GRP-301,GRP-302
  tgt=next-major impl=- via=-
poisoned phase-9 via=phase-7 groups=GRP-301
  tgt=future-unassigned impl=- via=-
poisoned phase-11 via=phase-7 groups=GRP-304
  tgt=unknown impl=- via=-
grouping GRP-301 poisoned-max=future-unassigned
grouping GRP-302 poisoned-max=next-minor
grouping GRP-303 poisoned-max=next-minor
grouping GRP-304 poisoned-max=unknown"
run_cli "$F_EMPTY" deps --deferral
if [[ $RC -eq 0 && "$OUT" == "(no deferral cascade)" ]]; then
    pass "C9.3 no deferred/superseded sources: '(no deferral cascade)', exit 0"
else
    fail "C9.3 no deferred/superseded sources: '(no deferral cascade)', exit 0" "rc=$RC out=$OUT"
fi
run_cli "$F_EMPTY" deps --deferral -q
if [[ $RC -eq 0 && -z "$OUT" ]]; then
    pass "C9.4 -q suppresses the no-cascade notice"
else
    fail "C9.4 -q suppresses the no-cascade notice" "rc=$RC out=$OUT"
fi

# ── C10: usage errors + help ────────────────────────────────────────────
echo "-- C10: usage --"
run_cli "$F1"
assert_eq "C10.1 missing verb exits 2" "2" "$RC"
run_cli "$F1" frobnicate
assert_eq "C10.2 unknown verb exits 2" "2" "$RC"
run_cli "$F1" list extra-arg
assert_eq "C10.3 list with an extra argument exits 2" "2" "$RC"
run_cli "$F1" order --deferral
assert_eq "C10.4 --deferral outside deps exits 2" "2" "$RC"
run_cli "$F1" list-membership
assert_eq "C10.5 list-membership without a reference exits 2" "2" "$RC"
out="$(bash "$CLI" --help)"; rc=$?
if [[ $rc -eq 0 && "$out" == usage:* ]]; then
    pass "C10.6 --help prints usage, exit 0"
else
    fail "C10.6 --help prints usage, exit 0" "rc=$rc out=$out"
fi

# ── C11: cross-parser drift geometry (the twin-parser agreement leg) ────
# The lib's load_target_enum tolerates variant schema-line spacing
# (key-strip semantics). The CLI's read_enum must accept EXACTLY the
# same shapes — a CLI parser stricter than the lib's silently degrades
# poisoned-max= to '-' at rc=0 while the SAME output block carries
# correct lib-sourced tgt= annotations (internally inconsistent, the
# worst failure class). Fixture: a contract whose target-enum line uses
# two spaces after the dash + padded key/value; CUSTOM tokens prove
# call-time contract reading (no fallback vocabulary can produce them).
# Geometry pins the declarer set == the non-absorbing marked set, so
# the lib rollup's tgt= IS the lib-derived expectation for the CLI's
# poisoned-max= (cross-parser agreement, both directions biting).
echo "-- C11: target-enum drift geometry (CLI parser == lib parser) --"
F3="$FIXTURE_BASE/f3-drift"
mkdir -p "$F3/docs/project/groupings" "$F3/docs/project/implementation-plan"
G3="$F3/docs/project/groupings"
I3="$F3/docs/project/implementation-plan"
cat > "$I3/_rules.md" <<'EOF'
# fixture impl-plan contract (drift-geometry schema-line spacing)

## Entry schema

-  target-enum :   tin  silver   gold
- other-key: noise

## Target semantics

prose
EOF
write_epic "$I3" 1 deferred    tin  none phase-2
write_epic "$I3" 2 not-started gold none none
write_grp "$G3" 401 release-package "Drift" "phase-1, phase-2"
run_cli "$F3" deps --deferral
assert_eq "C11.1 deps --deferral on the drift tree exits 0" "0" "$RC"
case "$OUT" in
    *"tgt=tin "*) pass "C11.2 lib-sourced annotation parsed the variant-spaced enum (tgt=tin present in the block)" ;;
    *) fail "C11.2 lib-sourced annotation parsed the variant-spaced enum (tgt=tin present in the block)" "$OUT" ;;
esac
DRIFT_GOT="$(printf '%s\n' "$OUT" \
    | awk '$1 == "grouping" && $2 == "GRP-401" { sub(/^.*poisoned-max=/, ""); print; exit }')"
assert_eq "C11.3 CLI poisoned-max on the variant-spaced enum: max(tin, gold) = gold (declaration order IS the scale; never a silent '-')" \
    "gold" "$DRIFT_GOT"
LIB_TGT="$(grp_rollup "$G3" "$I3" GRP-401 \
    | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^tgt=/) { print substr($i, 5); exit } }')"
assert_eq "C11.4 twin-parser agreement: CLI poisoned-max == lib rollup tgt on the same tree (declarer set == marked set by construction)" \
    "$LIB_TGT" "$DRIFT_GOT"

# ── C12: list join-integrity fail-loud (staged REAL-set regression) ─────
# grp_rollup_map is REAL-set-complete by lib contract; a regression
# dropping a row must surface as a typed error — the pre-hardening
# silent `continue` hid the grouping at rc=0 (and the C1.5 parity probe
# cannot catch it: both sides missing the row stay byte-equal). Staged
# copy only; the shipped lib is never modified.
echo "-- C12: missing-rollup-row fail-loud --"
PROBE="$FIXTURE_BASE/s1-probe"
mkdir -p "$PROBE"
cp "$CLI" "$PROBE/groupings.sh"
cp "$LIB" "$PROBE/groupings-lib.sh"
cat >> "$PROBE/groupings-lib.sh" <<'EOF'

# TEST-ONLY override (staged copy): simulate a lib REAL-set regression —
# grp_rollup_map drops the GRP-001 row.
eval "orig_$(declare -f grp_rollup_map)"
grp_rollup_map() { orig_grp_rollup_map "$@" | grep -v '^GRP-001 '; }
EOF
S1_ERRF="$FIXTURE_BASE/s1.stderr"
S1_OUT="$(bash "$PROBE/groupings.sh" list --root "$F1" 2>"$S1_ERRF")"
S1_RC=$?
S1_ERR="$(cat "$S1_ERRF")"
rm -f "$S1_ERRF"
assert_cli_err "C12.1 a REAL grouping with no rollup row fails LOUD (typed parse error, dispatch prefix) — never a silent row-drop at rc=0" \
    "$S1_RC" "$S1_ERR" "parse" "groupings:"

# ── C13: NBSP-bearing enum value (the separator-class agreement leg) ────
# The lib's load_target_enum splits the enum value on its runtime's
# full whitespace set — NBSP (U+00A0) included (SEPARATOR class:
# CPython isspace AND not a splitlines boundary); it does NOT pass
# NBSP through as a value byte. Pre-fix the CLI kept
# `gamma<NBSP>omega` as ONE token, silently dropping the legal
# `gamma` from the poisoned-max scale (poisoned-max=alpha vs lib
# tgt=gamma at rc=0). Same geometry as C11: declarer set == the
# non-absorbing marked set, so the lib rollup's tgt= IS the
# lib-derived expectation for the CLI's poisoned-max= (cross-parser
# agreement, both directions biting).
echo "-- C13: NBSP-bearing enum value (separator-class agreement) --"
F4="$FIXTURE_BASE/f4-nbsp"
mkdir -p "$F4/docs/project/groupings" "$F4/docs/project/implementation-plan"
G4="$F4/docs/project/groupings"
I4="$F4/docs/project/implementation-plan"
{
    printf '# fixture impl-plan contract (NBSP inside the enum value)\n\n'
    printf '## Entry schema\n\n'
    printf -- '- target-enum: alpha gamma\302\240omega\n\n'
    printf '## Target semantics\n\nprose\n'
} > "$I4/_rules.md"
write_epic "$I4" 1 deferred    alpha none phase-2
write_epic "$I4" 2 not-started gamma none none
write_grp "$G4" 501 release-package "Nbsp" "phase-1, phase-2"
run_cli "$F4" deps --deferral
assert_eq "C13.1 deps --deferral on the NBSP tree exits 0" "0" "$RC"
NBSP_GOT="$(printf '%s\n' "$OUT" \
    | awk '$1 == "grouping" && $2 == "GRP-501" { sub(/^.*poisoned-max=/, ""); print; exit }')"
assert_eq "C13.2 CLI poisoned-max on the NBSP-split enum: gamma is legal (ordinal 1) and beats alpha — never a silent drop at rc=0" \
    "gamma" "$NBSP_GOT"
LIB_TGT4="$(grp_rollup "$G4" "$I4" GRP-501 \
    | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^tgt=/) { print substr($i, 5); exit } }')"
assert_eq "C13.3 twin-parser agreement on the NBSP tree: CLI poisoned-max == lib rollup tgt" \
    "$LIB_TGT4" "$NBSP_GOT"

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
