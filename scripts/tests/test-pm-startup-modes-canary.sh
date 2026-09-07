#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-pm-startup-modes-canary.sh — the /pm-startup Step 6(b)
# commit-gate canary (and /pm-refresh Step 2b's copy) can FAIL, and the Step
# 6(a) `modes effective:` classification is correct and cannot drift from the
# gate.
#
# The canary is a bash fence embedded in project-template/skills/pm-startup/
# SKILL.md (and pm-refresh/SKILL.md). It drives the SHIPPED client gate
# (project-template/scripts/pm-modes-commit-gate.py) through its MODES_GATE_*
# seams in three legs — a present config must DENY, an absent config must
# ALLOW, intervention_mode=none must ALLOW — then probes the live config for
# the gate's effective state. A canary that passes while unable to fail is
# worthless, so this test extracts the fence from the SHIPPED skill text, runs
# it VERBATIM in a mktemp client tree, and proves each leg flips under a gate
# mutation that breaks only that leg:
#   ok    the shipped gate                          -> PASS (…; live=INERT)
#   live  the shipped gate + a real full config      -> PASS (…; live=ACTIVE)
#   mut1  absent config folds to "full"             -> FAIL: absent-config FAILS to allow
#   mut2  the deny path never fires                 -> FAIL: present-config FAILS to deny
#   mut3  "none" promoted into the enforce set      -> FAIL: none FAILS to allow
# Every mutation asserts its anchor present-before / gone-after and that the
# mutant compiles, so a mutation that silently failed to apply voids nothing
# quietly.
#
# A second section covers Step 6(a) — the `modes effective:` line the operator
# actually reads. It is derived from the config FILE (not from the hook), so the
# 6(b) legs above cover none of it. The shipped (a) fence is extracted and run
# verbatim under absent / full / none / unrecognized / malformed configs, and
# its enforce-set literal is compared against the shipped gate's
# `_ENFORCE_MODES` so the two encodings of "which modes gate commits" cannot
# drift apart silently.
#
# Offline and deterministic: python3 + a throwaway git repo under
# mktemp; no network, no gh, no hardcoded absolute dev/home path.
#
# Usage:    bash scripts/tests/test-pm-startup-modes-canary.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PT="$PACK_ROOT/project-template"
GATE_OK="$PT/scripts/pm-modes-commit-gate.py"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-pm-canary.XXXXXX")"
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
assert_contains() { # label haystack needle
    if [[ "$2" == *"$3"* ]]; then pass "$1"; else fail "$1" "contains: $3" "$2"; fi
}

# Print the first ```bash fence that follows a marker line; exit 1 when the
# marker or fence is absent, so an empty snippet can never pass vacuously.
extract_fence() { # skill.md marker
    awk -v m="$2" '
        !found && index($0, m) { found = 1; next }
        found && !open && $0 ~ /^```bash[[:space:]]*$/ { open = 1; next }
        open && $0 ~ /^```[[:space:]]*$/ { done = 1; exit }
        open { print }
        END { exit (done ? 0 : 1) }' "$1"
}

# A minimal client tree: the three shipped hook bodies + the shipped settings
# that wire them, in a throwaway git repo (the canary derives ROOT from git and
# the live probe derives the config path from ROOT). No config is written
# unless a case asks for one.
mk_tree() { # name
    local d="$FIXTURE_BASE/$1"
    mkdir -p "$d/scripts" "$d/.claude" "$d/docs/project"
    git init -q "$d"
    cp "$PT/scripts/pm-modes-enforce.py" "$PT/scripts/pm-modes-commit-gate.py" \
       "$PT/scripts/pm-deletion-boundary.py" "$d/scripts/"
    cp "$PT/.claude/settings.json" "$d/.claude/settings.json"
    printf '%s' "$d"
}

# Copy the shipped gate, apply ONE perl substitution, and assert it applied:
# anchor count n -> n-1, marker 0 -> 1, bytes differ, still compiles.
mk_mutant() { # name perl-expr pre-anchor post-marker
    local dst="$FIXTURE_BASE/gate.$1.py" pre_b pre_a post_a
    cp "$GATE_OK" "$dst"
    pre_b=$(grep -c -F -- "$3" "$dst" | tr -d ' ')
    perl -0777 -pi -e "$2" "$dst"
    pre_a=$(grep -c -F -- "$3" "$dst" | tr -d ' ')
    post_a=$(grep -c -F -- "$4" "$dst" | tr -d ' ')
    if [[ "$pre_b" -ge 1 && "$pre_a" -eq $((pre_b - 1)) && "$post_a" -eq 1 ]] \
       && ! cmp -s "$GATE_OK" "$dst" && python3 -m py_compile "$dst" 2>/dev/null; then
        pass "mutant $1 applied (anchor $pre_b -> $pre_a, marker 0 -> $post_a, compiles)"
    else
        fail "mutant $1 did NOT apply as intended — its cases are void" \
            "anchor -1, marker +1, compiles" "anchor $pre_b -> $pre_a, marker $post_a"
    fi
}

run_canary() { # tree snippet
    ( cd "$1" && CLAUDECODE=1 bash "$2" 2>&1 )
}

echo "== mutants (built once against the shipped gate) =="
mk_mutant mut1 \
    's/(get\("intervention_mode"\)\n    except Exception:\n        return )None/${1}"full"  # MUTATED: absent folds to full/' \
    '        return None' 'MUTATED: absent folds to full'
mk_mutant mut2 \
    's/return _deny\(mode\)  # enforce-mode/return 0  # MUTATED: never deny/' \
    'return _deny(mode)' 'MUTATED: never deny'
mk_mutant mut3 \
    's/_ENFORCE_MODES = frozenset\(\{"full", "pre-coder", "ambiguity"\}\)/_ENFORCE_MODES = frozenset({"full", "pre-coder", "ambiguity", "none"})  # MUTATED: none gates/' \
    '_ENFORCE_MODES = frozenset({"full", "pre-coder", "ambiguity"})' 'MUTATED: none gates'

for skill in pm-startup pm-refresh; do
    SKILL_MD="$PT/skills/$skill/SKILL.md"
    case "$skill" in
        pm-startup) marker='(b) Hook-readiness canary' ;;
        *)          marker='Re-run the function canary' ;;
    esac
    SNIP="$FIXTURE_BASE/$skill.canary.sh"
    echo "== $skill =="
    if extract_fence "$SKILL_MD" "$marker" > "$SNIP" && [[ -s "$SNIP" ]] && bash -n "$SNIP" 2>/dev/null; then
        pass "$skill: canary fence extracted ($(wc -l < "$SNIP" | tr -d ' ') lines) and parses"
    else
        fail "$skill: canary fence missing or unparsable after marker '$marker'"
        continue
    fi

    T=$(mk_tree "$skill-ok")
    out=$(run_canary "$T" "$SNIP")
    assert_contains "$skill ok: wiring probe finds all three shipped hooks" "$out" "wired ("
    assert_contains "$skill ok: shipped gate passes all three legs, live=INERT (no config)" "$out" \
        "commit-gate self-test PASS (present-config denies, absent-config allows, none allows; live=INERT)"

    printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"full"}' > "$T/docs/project/pm-session-config.json"
    out=$(run_canary "$T" "$SNIP")
    assert_contains "$skill live: a real full config flips the live probe to ACTIVE" "$out" \
        "commit-gate self-test PASS (present-config denies, absent-config allows, none allows; live=ACTIVE)"
    rm -f "$T/docs/project/pm-session-config.json"

    for m in mut1 mut2 mut3; do
        case "$m" in
            mut1) leg="absent-config FAILS to allow" ;;
            mut2) leg="present-config FAILS to deny" ;;
            *)    leg="none FAILS to allow" ;;
        esac
        T=$(mk_tree "$skill-$m")
        cp "$FIXTURE_BASE/gate.$m.py" "$T/scripts/pm-modes-commit-gate.py"
        out=$(run_canary "$T" "$SNIP")
        assert_contains "$skill $m: canary reports commit-gate self-test FAIL" "$out" "commit-gate self-test FAIL"
        assert_contains "$skill $m: names the broken leg '$leg'" "$out" "$leg"
    done
done

# ── Step 6(a): the `modes effective:` classification ────────────────────
# 6(b) above proves the HOOK still fires. 6(a) is the line the operator reads —
# the gate's EFFECTIVE state on this clone — and it is derived from the config
# FILE, not from the hook, so nothing above covers it. Extract the shipped (a)
# fence and run it VERBATIM in a client tree under each config state, asserting
# the class it prints; then tie the fence's enforce-set literal to the shipped
# gate's `_ENFORCE_MODES`, the second encoding of the same fact. Without the tie
# a mode added to the gate leaves 6(a) printing INERT for a clone whose commits
# ARE gated, with every test still green.
echo "== pm-startup 6(a) modes-effective =="
A_MARK='(a) Echo the active modes'
SNIPA="$FIXTURE_BASE/pm-startup.a.sh"
A_MD="$PT/skills/pm-startup/SKILL.md"
if extract_fence "$A_MD" "$A_MARK" > "$SNIPA" && [[ -s "$SNIPA" ]] && bash -n "$SNIPA" 2>/dev/null; then
    pass "6(a): fence extracted ($(wc -l < "$SNIPA" | tr -d ' ') lines) and parses"
else
    fail "6(a): fence missing or unparsable after marker '$A_MARK'"
fi

TA=$(mk_tree pm-startup-a)
CFGA="$TA/docs/project/pm-session-config.json"
run_a() { ( cd "$TA" && bash "$SNIPA" 2>&1 ); }

rm -f "$CFGA"
out=$(run_a)
assert_contains "6(a) absent: INERT, names the absent config" "$out" \
    "modes effective: commit gate INERT (docs/project/pm-session-config.json is absent"
assert_contains "6(a) absent: the modes line still folds to the salience defaults" "$out" \
    "modes: review=itemized intervention=full isolation=read-write-only"

printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"full"}' > "$CFGA"
out=$(run_a)
assert_contains "6(a) full: ACTIVE, names the value and the file" "$out" \
    "modes effective: commit gate ACTIVE (intervention_mode=full read from docs/project/pm-session-config.json)"

printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"none"}' > "$CFGA"
out=$(run_a)
assert_contains "6(a) none: INERT by choice" "$out" \
    "modes effective: commit gate INERT by choice (intervention_mode=none authorizes auto-commit)"

printf '%s\n' '{"schema":"pm-session-config/1","intervention_mode":"not-a-mode"}' > "$CFGA"
out=$(run_a)
assert_contains "6(a) unrecognized: INERT, names the unrecognized value" "$out" \
    "modes effective: commit gate INERT (docs/project/pm-session-config.json is present but intervention_mode is missing or unrecognized"

printf '%s\n' '{ this is not json' > "$CFGA"
out=$(run_a)
assert_contains "6(a) malformed: INERT, names the unreadable file" "$out" \
    "modes effective: commit gate INERT (docs/project/pm-session-config.json is present but unreadable"
rm -f "$CFGA"

# Encoding tie: the (a) fence's enforce-set literal MUST equal the shipped
# gate's `_ENFORCE_MODES`. Both sides are asserted non-empty first, so a parse
# that matched nothing cannot report equality.
tie=$(python3 - "$SNIPA" "$GATE_OK" <<'PY'
import re, sys
fence = open(sys.argv[1], encoding="utf-8").read()
gate = open(sys.argv[2], encoding="utf-8").read()
mf = re.search(r"m\s+in\s+\(([^)]*)\)", fence)
mg = re.search(r"_ENFORCE_MODES\s*=\s*frozenset\(\s*\{([^}]*)\}\s*\)", gate)
f = set(re.findall(r'"([^"]+)"', mf.group(1))) if mf else set()
g = set(re.findall(r'"([^"]+)"', mg.group(1))) if mg else set()
print("FENCE=%s" % ("|".join(sorted(f)) or "<none>"))
print("GATE=%s" % ("|".join(sorted(g)) or "<none>"))
print("EQUAL=%s" % ("yes" if f and f == g else "no"))
PY
)
tie_fence=$(printf '%s\n' "$tie" | sed -n 's/^FENCE=//p')
tie_gate=$(printf '%s\n' "$tie" | sed -n 's/^GATE=//p')
tie_eq=$(printf '%s\n' "$tie" | sed -n 's/^EQUAL=//p')
[[ "$tie_fence" != "<none>" ]] \
    && pass "6(a) anchor: an enforce-set literal was parsed from the fence ($tie_fence)" \
    || fail "6(a) anchor: no enforce-set literal in the extracted (a) fence"
[[ "$tie_gate" != "<none>" ]] \
    && pass "6(a) anchor: _ENFORCE_MODES was parsed from the shipped gate ($tie_gate)" \
    || fail "6(a) anchor: no _ENFORCE_MODES in $GATE_OK"
if [[ "$tie_eq" == "yes" ]]; then
    pass "6(a): the fence's enforce-set equals the gate's _ENFORCE_MODES"
else
    fail "6(a): the fence's enforce-set has DRIFTED from the gate's _ENFORCE_MODES" \
        "equal sets" "fence=$tie_fence gate=$tie_gate"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
