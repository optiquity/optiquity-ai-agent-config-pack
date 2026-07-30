#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-status-generate.sh — the status-generate.sh
# dashboard-generator battery: create-if-absent seeding, regen
# determinism, hand-section preservation, the --check bite/ignore/SKIP
# arms, marker-less REFUSE + wrap-adopt, marker-integrity failure
# (incl. the interleaved-pair disjointness arm: individually
# well-formed pairs whose ranges overlap fail typed on THAT pass), the
# blocked-renders-blocked golden, the pinned class-1b header golden
# (% complete AND Target), the class-1a three-state Groupings cell with
# the superseded-orphan nudge-silence arm (deferred orphans stay
# pending), the class-1a Target column, the flat-file title-link cell
# (GitHub anchor grammar), the frontier fresh-session + snapshot-render
# arms (snapshot is SOURCE only), and the rollup parity probe: class-1b
# rendered values == values derived from grp_rollup_map on the SAME
# fixture tree (both consumers read the one shared lib), plus its
# PRESENCE-KEYED cross-consumer half (S6b): `groupings.sh list -q`
# machine rows == the class-1b cells when
# project-template/scripts/groupings.sh exists and is executable;
# explicit SKIP line naming that condition otherwise.
#
# Fixtures are mktemp-local, shaped like an installed client tree
# (scripts/ + docs/project/ + docs/pack/); nothing ships.
#
# Usage:    bash scripts/tests/test-status-generate.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GEN="$PACK_ROOT/project-template/scripts/status-generate.sh"
LIB="$PACK_ROOT/project-template/scripts/groupings-lib.sh"
VALIDATE="$PACK_ROOT/project-template/scripts/validate.sh"
IPRULES="$PACK_ROOT/project-template/docs/project/implementation-plan/_rules.md"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-status-generate.XXXXXX")"
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

assert_rc() {
    # assert_rc <label> <want-rc> <got-rc>
    if [[ "$2" -eq "$3" ]]; then pass "$1"
    else fail "$1" "want rc=$2, got rc=$3"; fi
}

assert_contains() {
    # assert_contains <label> <haystack-file-or-string mode=F|S> <needle>
    local hay
    if [[ "$2" == "F" ]]; then hay="$(cat "$3")"; else hay="$3"; fi
    if [[ "$hay" == *"$4"* ]]; then pass "$1"
    else fail "$1" "missing: $4"; fi
}

assert_not_contains() {
    local hay
    if [[ "$2" == "F" ]]; then hay="$(cat "$3")"; else hay="$3"; fi
    if [[ "$hay" != *"$4"* ]]; then pass "$1"
    else fail "$1" "unexpectedly present: $4"; fi
}

for f in "$GEN" "$LIB" "$VALIDATE" "$IPRULES"; do
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

# ── Builders (installed-client-tree shape) ──────────────────────────────
# stage_tree <dir> — a client-shaped tree with the shipped scripts +
# contract; PM-CHAT.md heading per the pm-startup Step-6 precedent.
stage_tree() {
    mkdir -p "$1/scripts" "$1/docs/project/implementation-plan" \
        "$1/docs/project/groupings" "$1/docs/pack"
    cp "$GEN" "$LIB" "$1/scripts/"
    cp "$IPRULES" "$1/docs/project/implementation-plan/_rules.md"
    printf '# FixtureProj — PM Chat Instructions\n' > "$1/docs/pack/PM-CHAT.md"
}

# write_epic <dir> <num> <status> <target|->
write_epic() {
    local dir="$1" num="$2" status="$3" target="$4"
    {
        printf '<!-- back -->\n## Phase %s — G%s\n\n' "$num" "$num"
        printf -- '- **Entry-Type**: phase-epic\n'
        printf -- '- **ID**: phase-%s\n' "$num"
        printf -- '- **Status**: %s\n' "$status"
        printf -- '- **Blockers**: none\n'
        printf -- '- **Unblocks**: none\n'
        printf -- '- **Goal**: g\n'
        printf -- '- **Prerequisite**: none\n'
        if [[ "$target" != "-" ]]; then
            printf -- '- **Target**: %s\n' "$target"
        fi
    } > "$dir/docs/project/implementation-plan/phase-${num}.md"
}

# write_part <dir> <num> — a phase-part file (Entry-Type only; no 1a row).
write_part() {
    printf '<!-- back -->\n### Phase-%s.Part-a — part\n\n- **Entry-Type**: phase-part\n' \
        "$2" > "$1/docs/project/implementation-plan/phase-${2}.md"
}

# write_grp <dir> <NNN> <kind> <members-value>
write_grp() {
    local dir="$1" nnn="$2" kind="$3" members="$4"
    {
        printf '<!-- per-entry source: docs/project/groupings/GRP-%s.md; contract: docs/project/groupings/_rules.md -->\n' "$nnn"
        printf '**GRP-%s — T%s**\n' "$nnn" "$nnn"
        printf 'Entry-Type: grouping\n'
        printf 'Kind: %s\n' "$kind"
        if [[ -n "$members" ]]; then
            printf 'Member-phases: %s\n' "$members"
        else
            printf 'Member-phases:\n'
        fi
    } > "$dir/docs/project/groupings/GRP-${nnn}.md"
}

write_snapshot() {
    printf '{"schema":"pm-session-state/1","boundary_commit":"abc1234","checkpoint":"2026-07-05T00:00:00Z","active":"phase-4 @ implement","in_flight_agents":[],"queue":["phase-3","phase-6"],"parallelization":"serial","wave":"-","pending_decisions":[],"cycle_position":"idle"}' \
        > "$1/docs/project/pm-session-state.json"
}

# The MAIN fixture tree (one tree drives the goldens + the parity probe):
#   phase-1 done  Target current   in GRP-001
#   phase-2 superseded             in GRP-001   -> {done,superseded} rollup
#   phase-3 blocked                in GRP-002   -> blocked-renders-blocked
#   phase-4 in-progress next-minor in GRP-002   -> mixed rollup + tgt max
#   phase-5 superseded ORPHAN                   -> S-4 nudge-silence cell
#   phase-6 deferred  ORPHAN                    -> stays pending (em-dash)
#   phase-7 not-started            in GRP-000   -> none (declared)
#   phase-8 phase-part file                     -> NO class-1a row
T1="$FIXTURE_BASE/t1"
stage_tree "$T1"
write_epic "$T1" 1 done current
write_epic "$T1" 2 superseded -
write_epic "$T1" 3 blocked -
write_epic "$T1" 4 in-progress next-minor
write_epic "$T1" 5 superseded -
write_epic "$T1" 6 deferred -
write_epic "$T1" 7 not-started -
write_part "$T1" 8
write_grp "$T1" 000 unassigned "phase-7"
write_grp "$T1" 001 user-journey "phase-1, phase-2"
write_grp "$T1" 002 foundational-batch "phase-3, phase-4"
write_snapshot "$T1"
T1OUT="$T1/docs/project/STATUS.md"

echo "== status-generate.sh dashboard-generator battery =="

# ── S1: --check SKIPs before the file exists ────────────────────────────
echo "-- S1: --check SKIP-lenient arms (absent) --"
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S1.1 --check on absent STATUS.md exits 0 (SKIP)" 0 "$rc"
assert_contains "S1.2 SKIP notice names the absent file" S "$CHK_OUT" "SKIP"

# ── S2: create-if-absent seeds class 3 ──────────────────────────────────
echo "-- S2: create-if-absent --"
GEN_OUT="$(bash "$T1/scripts/status-generate.sh" 2>&1)"; rc=$?
assert_rc "S2.1 first run exits 0" 0 "$rc"
if [[ -f "$T1OUT" ]]; then pass "S2.2 STATUS.md created"
else fail "S2.2 STATUS.md created"; fi
assert_eq "S2.3 line 1 is the never-SSOT disclaimer (per-entry trees + generator named)" \
    "yes" "$(head -1 "$T1OUT" | grep -q 'Working snapshot — never source of truth.*status-generate.sh.*per-entry trees' && echo yes || echo no)"
assert_contains "S2.4 hand section seeded with the placeholder" F "$T1OUT" \
    "(PM judgment — next actions, risks, notes)"
assert_contains "S2.5 title line carries the PM-CHAT project name" F "$T1OUT" \
    "# STATUS — FixtureProj"
for m in "STATUS-GEN:BEGIN phases" "STATUS-GEN:END phases" \
         "STATUS-GEN:BEGIN groupings" "STATUS-GEN:END groupings" \
         "STATUS-GEN:BEGIN frontier" "STATUS-GEN:END frontier" \
         "STATUS-HAND:BEGIN" "STATUS-HAND:END"; do
    assert_eq "S2.6 marker present exactly once: $m" \
        "1" "$(grep -c -- "$m" "$T1OUT")"
done

# ── S3: regen ×2 byte-identical ─────────────────────────────────────────
echo "-- S3: regen determinism --"
cp "$T1OUT" "$FIXTURE_BASE/t1-first.md"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1; rc=$?
assert_rc "S3.1 second run exits 0" 0 "$rc"
if cmp -s "$FIXTURE_BASE/t1-first.md" "$T1OUT"; then
    pass "S3.2 regen x2 on an unchanged tree is byte-identical"
else
    fail "S3.2 regen x2 on an unchanged tree is byte-identical" \
        "$(diff "$FIXTURE_BASE/t1-first.md" "$T1OUT" | head -10)"
fi

# ── S4: class-1a goldens (Status field-sourced; Target; three-state cell;
#        title links; part exclusion) ───────────────────────────────────
echo "-- S4: class-1a goldens --"
assert_contains "S4.1 blocked-renders-blocked (the emoji-invisible state made visible)" F "$T1OUT" \
    "| phase-3 | [G3](implementation-plan/phase-3.md#phase-3--g3) | blocked | — | [GRP-002](groupings/GRP-002.md) |"
assert_contains "S4.2 title-link cell (BD-105 flat scope; anchor grammar: em-dash leaves --)" F "$T1OUT" \
    "| phase-1 | [G1](implementation-plan/phase-1.md#phase-1--g1) | done | current | [GRP-001](groupings/GRP-001.md) |"
assert_contains "S4.3 Target column renders the phase's own field" F "$T1OUT" \
    "| phase-4 | [G4](implementation-plan/phase-4.md#phase-4--g4) | in-progress | next-minor | [GRP-002](groupings/GRP-002.md) |"
assert_contains "S4.4 superseded ORPHAN is nudge-silenced (S-4: never the pending ask)" F "$T1OUT" \
    "| phase-5 | [G5](implementation-plan/phase-5.md#phase-5--g5) | superseded | — | none (superseded) |"
assert_contains "S4.5 deferred ORPHAN stays listed as pending (deferred work is still owed)" F "$T1OUT" \
    "| phase-6 | [G6](implementation-plan/phase-6.md#phase-6--g6) | deferred | — | — |"
assert_contains "S4.6 GRP-000 member renders the settled none (declared) state" F "$T1OUT" \
    "| phase-7 | [G7](implementation-plan/phase-7.md#phase-7--g7) | not-started | — | none (declared) |"
assert_eq "S4.7 part-typed phase-8 gets NO class-1a row (epic-only map)" \
    "0" "$(grep -c '^| phase-8 ' "$T1OUT")"
assert_contains "S4.8 class-1a header carries the Target column" F "$T1OUT" \
    "| Phase | Title | Status | Target | Groupings |"

# ── S5: class-1b goldens (pinned header; B-prime + flags; target) ──────
echo "-- S5: class-1b goldens --"
assert_contains "S5.1 class-1b header pinned (carries % complete AND Target)" F "$T1OUT" \
    "| Grouping | Kind | Status | % complete | Target | Member phases |"
assert_contains "S5.2 superseded member renders per B-prime + flags ({done,superseded} -> complete 1/1 100% [1 superseded])" F "$T1OUT" \
    "| [GRP-001](groupings/GRP-001.md) | user-journey | complete [1 superseded] | 1/1 (100%) | — | [phase-1](implementation-plan/phase-1.md), [phase-2](implementation-plan/phase-2.md) |"
assert_contains "S5.3 mixed grouping row ({blocked,in-progress} -> in-progress 0/2 [1 blocked]; tgt max next-minor)" F "$T1OUT" \
    "| [GRP-002](groupings/GRP-002.md) | foundational-batch | in-progress [1 blocked] | 0/2 (0%) | next-minor | [phase-3](implementation-plan/phase-3.md), [phase-4](implementation-plan/phase-4.md) |"
assert_eq "S5.4 GRP-000 has NO class-1b row (REAL set only)" \
    "0" "$(grep -c 'GRP-000' "$T1OUT")"

# ── S6: rollup parity probe (class-1b values == grp_rollup_map values,
#        ONE fixture tree, both via the shared lib; S6b carries the
#        cross-consumer `groupings.sh list -q` half, presence-keyed) ──
echo "-- S6: rollup parity probe --"
ROLL="$(grp_rollup_map "$T1/docs/project/groupings" "$T1/docs/project/implementation-plan")"
while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    # shellcheck disable=SC2086
    set -- $row
    gid="$1"; derived="$2"; frac="$3"; pct="$4"
    b="${5#b=}"; d="${6#d=}"; s="${7#s=}"; u="${8#u=}"; tgt="${9#tgt=}"
    flags="$(grp_render_flags "$b" "$d" "$s" "$u")"
    rpct="$(grp_render_pct "$pct")"
    want_status="$derived"
    [[ -n "$flags" ]] && want_status="$derived $flags"
    want_tgt="$tgt"
    [[ "$tgt" == "-" ]] && want_tgt="—"
    cell_line="$(grep "^| \[$gid\]" "$T1OUT")"
    got_status="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $3}')"
    got_pct="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $4}')"
    got_tgt="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $5}')"
    assert_eq "S6.1 $gid Status cell == lib derived+flags" "$want_status" "$got_status"
    assert_eq "S6.2 $gid %-complete cell == lib fraction+rendered pct" "$frac $rpct" "$got_pct"
    assert_eq "S6.3 $gid Target cell == lib tgt token" "$want_tgt" "$got_tgt"
done <<PARITYEOF
$ROLL
PARITYEOF

# ── S6b: the cross-consumer parity half — `groupings.sh list -q` rows
#         (the §T-2 machine grammar verbatim) == the class-1b cells on
#         the SAME T1 tree. PRESENCE-KEYED: runs when the groupings CLI
#         ships beside the lib; explicit SKIP otherwise ────────────────
echo "-- S6b: cross-consumer CLI parity (presence-keyed) --"
CLI_SRC="$PACK_ROOT/project-template/scripts/groupings.sh"
if [[ -f "$CLI_SRC" && -x "$CLI_SRC" ]]; then
    cp "$CLI_SRC" "$T1/scripts/"
    CLIQ="$(bash "$T1/scripts/groupings.sh" list -q 2>&1)"; rc=$?
    assert_rc "S6b.1 list -q exits 0 on the parity fixture tree" 0 "$rc"
    assert_eq "S6b.2 list -q machine-row count == grp_rollup_map row count (REAL set)" \
        "$(printf '%s\n' "$ROLL" | grep -c '^GRP-')" \
        "$(printf '%s\n' "$CLIQ" | grep -c '^GRP-')"
    while IFS= read -r row; do
        case "$row" in GRP-*) ;; *) continue ;; esac
        # shellcheck disable=SC2086
        set -- $row
        gid="$1"; derived="$2"; frac="$3"; pct="$4"
        b="${5#b=}"; d="${6#d=}"; s="${7#s=}"; u="${8#u=}"; tgt="${9#tgt=}"
        flags="$(grp_render_flags "$b" "$d" "$s" "$u")"
        rpct="$(grp_render_pct "$pct")"
        want_status="$derived"
        [[ -n "$flags" ]] && want_status="$derived $flags"
        want_tgt="$tgt"
        [[ "$tgt" == "-" ]] && want_tgt="—"
        cell_line="$(grep "^| \[$gid\]" "$T1OUT")"
        got_status="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $3}')"
        got_pct="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $4}')"
        got_tgt="$(printf '%s' "$cell_line" | awk -F' \\| ' '{print $5}')"
        assert_eq "S6b.3 $gid CLI Status values == class-1b Status cell" \
            "$want_status" "$got_status"
        assert_eq "S6b.4 $gid CLI fraction+pct == class-1b %-complete cell" \
            "$frac $rpct" "$got_pct"
        assert_eq "S6b.5 $gid CLI tgt == class-1b Target cell" \
            "$want_tgt" "$got_tgt"
    done <<CLIQEOF
$CLIQ
CLIQEOF
else
    echo "  SKIP: S6b cross-consumer CLI parity — project-template/scripts/groupings.sh absent or not executable (the BD-265 groupings CLI); the leg self-activates when it lands"
fi

# ── S7: hand-section preservation ───────────────────────────────────────
echo "-- S7: hand-section preservation --"
sed 's/(PM judgment — next actions, risks, notes)/MY HAND NOTES v1 — do not lose/' \
    "$T1OUT" > "$FIXTURE_BASE/tmp.md" && mv "$FIXTURE_BASE/tmp.md" "$T1OUT"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1; rc=$?
assert_rc "S7.1 regen over an edited hand section exits 0" 0 "$rc"
assert_contains "S7.2 hand-authored bytes preserved across regen" F "$T1OUT" \
    "MY HAND NOTES v1 — do not lose"
assert_not_contains "S7.3 seed placeholder not re-imposed" F "$T1OUT" \
    "(PM judgment — next actions, risks, notes)"
cp "$T1OUT" "$FIXTURE_BASE/t1-hand.md"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1
if cmp -s "$FIXTURE_BASE/t1-hand.md" "$T1OUT"; then
    pass "S7.4 hand section byte-preserved x2 regens"
else
    fail "S7.4 hand section byte-preserved x2 regens"
fi

# ── S8: --check bite / ignore arms ──────────────────────────────────────
echo "-- S8: --check class-1 bite + class-2 ignore --"
bash "$T1/scripts/status-generate.sh" --check >/dev/null 2>&1; rc=$?
assert_rc "S8.1 --check clean after regen exits 0" 0 "$rc"
sed 's/| phase-1 | \[G1\](implementation-plan\/phase-1.md#phase-1--g1) | done |/| phase-1 | [G1](implementation-plan\/phase-1.md#phase-1--g1) | in-progress |/' \
    "$T1OUT" > "$FIXTURE_BASE/tmp.md" && mv "$FIXTURE_BASE/tmp.md" "$T1OUT"
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S8.2 --check BITES on class-1a cell drift" 1 "$rc"
assert_contains "S8.3 drift message names the phases section" S "$CHK_OUT" \
    "class-1 drift in section(s): phases"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1
bash "$T1/scripts/status-generate.sh" --check >/dev/null 2>&1; rc=$?
assert_rc "S8.4 regen restores --check to clean" 0 "$rc"
sed 's/- \*\*Boundary commit:\*\* abc1234/- **Boundary commit:** zzz9999/' \
    "$T1OUT" > "$FIXTURE_BASE/tmp.md" && mv "$FIXTURE_BASE/tmp.md" "$T1OUT"
bash "$T1/scripts/status-generate.sh" --check >/dev/null 2>&1; rc=$?
assert_rc "S8.5 --check IGNORES class-2 frontier content drift" 0 "$rc"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1

# ── S9: marker integrity FAILs (both modes) ─────────────────────────────
echo "-- S9: marker-integrity FAIL arms --"
grep -v 'STATUS-GEN:END phases' "$T1OUT" > "$FIXTURE_BASE/tmp.md" \
    && mv "$FIXTURE_BASE/tmp.md" "$T1OUT"
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S9.1 --check FAILs on a broken marker pair" 1 "$rc"
assert_contains "S9.2 integrity message is typed + names the section" S "$CHK_OUT" \
    "ERROR(marker-integrity): STATUS-GEN phases"
GEN_ERR="$(bash "$T1/scripts/status-generate.sh" 2>&1)"; rc=$?
assert_rc "S9.3 default regen FAILs on a broken marker pair (no silent repair)" 1 "$rc"
assert_contains "S9.4 default-mode integrity message typed" S "$GEN_ERR" \
    "ERROR(marker-integrity)"
# The interleave construct: two individually well-formed GEN pairs
# INTERLEAVED by hand — each passes the per-pair check (one BEGIN, one
# END, BEGIN < END) but the ranges overlap; the disjointness assert
# must fail typed on THAT pass (never an rc-0 corrupting splice).
printf '%s\n' \
    '<!-- STATUS-GEN:BEGIN phases -->' \
    '<!-- STATUS-GEN:BEGIN groupings -->' \
    '<!-- STATUS-GEN:END phases -->' \
    '<!-- STATUS-GEN:END groupings -->' \
    '<!-- STATUS-GEN:BEGIN frontier -->' \
    '<!-- STATUS-GEN:END frontier -->' \
    '<!-- STATUS-HAND:BEGIN -->' \
    'hand bytes survive the refusal' \
    '<!-- STATUS-HAND:END -->' > "$T1OUT"
cp "$T1OUT" "$FIXTURE_BASE/interleave-before.md"
GEN_ERR="$(bash "$T1/scripts/status-generate.sh" 2>&1)"; rc=$?
assert_rc "S9.5 regen FAILs interleaved (individually well-formed) GEN pairs on THAT pass" 1 "$rc"
assert_contains "S9.6 interleave failure typed + names both pairs" S "$GEN_ERR" \
    "ERROR(marker-integrity): STATUS-GEN phases and STATUS-GEN groupings marker pairs interleave"
if cmp -s "$FIXTURE_BASE/interleave-before.md" "$T1OUT"; then
    pass "S9.7 refused pass leaves the file byte-untouched (no rc-0 corrupting splice)"
else
    fail "S9.7 refused pass leaves the file byte-untouched (no rc-0 corrupting splice)" \
        "$(diff "$FIXTURE_BASE/interleave-before.md" "$T1OUT" | head -10)"
fi
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S9.8 --check FAILs the interleaved construct too" 1 "$rc"

# ── S10: marker-less REFUSE (default) / SKIP (--check) / wrap-adopt ────
echo "-- S10: marker-less REFUSE + SKIP + wrap-adopt --"
printf 'legacy hand-authored status content\n' > "$T1OUT"
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S10.1 --check SKIPs a marker-less file (exit 0)" 0 "$rc"
assert_contains "S10.2 marker-less SKIP notice" S "$CHK_OUT" "SKIP"
GEN_ERR="$(bash "$T1/scripts/status-generate.sh" 2>&1)"; rc=$?
assert_rc "S10.3 default regen REFUSES a marker-less file" 1 "$rc"
assert_contains "S10.4 refusal is typed" S "$GEN_ERR" "ERROR(marker-less)"
assert_contains "S10.5 refusal carries the wrap instruction" S "$GEN_ERR" \
    "STATUS-HAND:BEGIN"
assert_contains "S10.6 legacy content untouched by the refusal" F "$T1OUT" \
    "legacy hand-authored status content"
printf '<!-- STATUS-HAND:BEGIN -->\nlegacy hand-authored status content\n<!-- STATUS-HAND:END -->\n' \
    > "$T1OUT"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1; rc=$?
assert_rc "S10.7 wrap-adopt run exits 0" 0 "$rc"
assert_contains "S10.8 adopted file preserves the wrapped hand content" F "$T1OUT" \
    "legacy hand-authored status content"
assert_contains "S10.9 adopted file gained the generated sections" F "$T1OUT" \
    "STATUS-GEN:BEGIN phases"
printf '<!-- STATUS-HAND:BEGIN -->\nwrapped\n<!-- STATUS-HAND:END -->\nstray content outside the pair\n' \
    > "$T1OUT"
GEN_ERR="$(bash "$T1/scripts/status-generate.sh" 2>&1)"; rc=$?
assert_rc "S10.10 adopt REFUSES non-whitespace content outside the pair" 1 "$rc"
bash "$T1/scripts/status-generate.sh" --check >/dev/null 2>&1 || true
printf '<!-- STATUS-HAND:BEGIN -->\nwrapped\n<!-- STATUS-HAND:END -->\n' > "$T1OUT"
CHK_OUT="$(bash "$T1/scripts/status-generate.sh" --check 2>&1)"; rc=$?
assert_rc "S10.11 --check FAILs a hand-only file (generated sections owed)" 1 "$rc"
rm -f "$T1OUT"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1   # restore for later legs

# ── S11: frontier arms (snapshot is SOURCE only) ────────────────────────
echo "-- S11: frontier arms --"
assert_contains "S11.1 frontier renders the snapshot fields" F "$T1OUT" \
    "- **Boundary commit:** abc1234"
assert_contains "S11.2 frontier renders the mode" F "$T1OUT" \
    "- **Mode:** serial"
cp "$T1/docs/project/pm-session-state.json" "$FIXTURE_BASE/snap-before.json"
bash "$T1/scripts/status-generate.sh" >/dev/null 2>&1
if cmp -s "$FIXTURE_BASE/snap-before.json" "$T1/docs/project/pm-session-state.json"; then
    pass "S11.3 snapshot is SOURCE only (bytes untouched by regen)"
else
    fail "S11.3 snapshot is SOURCE only (bytes untouched by regen)"
fi
T2="$FIXTURE_BASE/t2"
stage_tree "$T2"
write_epic "$T2" 1 in-progress -
bash "$T2/scripts/status-generate.sh" >/dev/null 2>&1; rc=$?
assert_rc "S11.4 absent-snapshot tree generates cleanly" 0 "$rc"
assert_contains "S11.5 absent snapshot renders the fresh-session line" F \
    "$T2/docs/project/STATUS.md" "no resume frontier — fresh session"

# ── S12: empty groupings tree ───────────────────────────────────────────
echo "-- S12: empty groupings tree --"
assert_contains "S12.1 empty REAL set renders the no-groupings row" F \
    "$T2/docs/project/STATUS.md" "| (no groupings declared) | — | — | — | — | — |"
assert_contains "S12.2 unruled orphan renders the pending ask" F \
    "$T2/docs/project/STATUS.md" \
    "| phase-1 | [G1](implementation-plan/phase-1.md#phase-1--g1) | in-progress | — | — |"

# ── S13: validate.sh wiring (Check 70 surfaces untouched) ───────────────
echo "-- S13: validate.sh wiring --"
assert_contains "S13.1 validate.sh wires status-generate.sh --check" F "$VALIDATE" \
    '"$SCRIPT_DIR/status-generate.sh" --check || EXIT_CODE=1'
assert_contains "S13.2 validate-docs.sh wiring untouched (Check 70 leg)" F "$VALIDATE" \
    '"$SCRIPT_DIR/validate-docs.sh" || EXIT_CODE=1'
assert_contains "S13.3 verify-immutable.sh wiring untouched" F "$VALIDATE" \
    '"$SCRIPT_DIR/verify-immutable.sh" || EXIT_CODE=1'
assert_eq "S13.4 wiring appears exactly once" \
    "1" "$(grep -c 'status-generate.sh" --check' "$VALIDATE")"

echo ""
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] || exit 1
exit 0
