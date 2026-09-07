#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-pack-startup-modes-canary.sh — the /pack-startup Step 6
# commit-gate canary (and /pack-refresh Step 2b's copy) can FAIL.
#
# The pack-side twin of test-pm-startup-modes-canary.sh (mirror-but-customize;
# a SEPARATE body — the project test proves the CLIENT fences against the
# shipped client gate, this one proves the PACK fences against the pack's own
# gate). The canary is a bash fence embedded in .claude/skills/pack-startup/
# SKILL.md (and pack-refresh/SKILL.md), mirrored byte-identically under
# .codex/skills/ and .agents/skills/. It drives the PACK gate
# (scripts/hooks/modes-commit-gate.py) through its MODES_GATE_* seams in three
# legs — a present config must DENY, an absent config must ALLOW,
# intervention_mode=none must ALLOW — then probes the live
# pack-ops/session-config.json for the gate's effective state. A canary that
# passes while unable to fail is worthless, so this test extracts the fence
# from the pack skill text, runs it VERBATIM in a mktemp pack-shaped tree, and
# proves each leg flips under a gate mutation that breaks only that leg:
#   ok    the pack gate                             -> PASS (…; live=INERT)
#   live  the pack gate + a real full config         -> PASS (…; live=ACTIVE)
#   mut1  absent config folds to "full"             -> FAIL: absent-config FAILS to allow
#   mut2  the deny path never fires                 -> FAIL: present-config FAILS to deny
#   mut3  "none" promoted into the enforce set      -> FAIL: none FAILS to allow
# and asserts the three trees' fences are byte-identical to each other, so a
# fix landed in one tree cannot ship green while the other two stay blind.
# Every mutation asserts its anchor present-before / gone-after and that the
# mutant compiles, so a mutation that silently failed to apply voids nothing
# quietly. Offline and deterministic: python3 + a throwaway git repo under
# mktemp; no network, no gh, no hardcoded absolute dev/home path.
#
# Usage:    bash scripts/tests/test-pack-startup-modes-canary.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS="$PACK_ROOT/scripts/hooks"
GATE_OK="$HOOKS/modes-commit-gate.py"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-pack-canary.XXXXXX")"
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

# A minimal pack-shaped tree: the three pack hook bodies + the tracked
# pack-root settings that wire them, in a throwaway git repo (the canary
# derives ROOT from git and the live probe derives pack-ops/session-config.json
# from ROOT). No config is written unless a case asks for one.
mk_tree() { # name
    local d="$FIXTURE_BASE/$1"
    mkdir -p "$d/scripts/hooks" "$d/.claude" "$d/pack-ops"
    git init -q "$d"
    cp "$HOOKS/modes-enforce.py" "$HOOKS/modes-commit-gate.py" \
       "$HOOKS/deletion-boundary.py" "$d/scripts/hooks/"
    cp "$PACK_ROOT/.claude/settings.json" "$d/.claude/settings.json"
    printf '%s' "$d"
}

# Copy the pack gate, apply ONE perl substitution, and assert it applied:
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

echo "== mutants (built once against the pack gate) =="
mk_mutant mut1 \
    's/(get\("intervention_mode"\)\n    except Exception:\n        return )None/${1}"full"  # MUTATED: absent folds to full/' \
    '        return None' 'MUTATED: absent folds to full'
mk_mutant mut2 \
    's/return _deny\(mode\)  # enforce-mode/return 0  # MUTATED: never deny/' \
    'return _deny(mode)' 'MUTATED: never deny'
mk_mutant mut3 \
    's/_ENFORCE_MODES = frozenset\(\{"full", "pre-coder", "ambiguity"\}\)/_ENFORCE_MODES = frozenset({"full", "pre-coder", "ambiguity", "none"})  # MUTATED: none gates/' \
    '_ENFORCE_MODES = frozenset({"full", "pre-coder", "ambiguity"})' 'MUTATED: none gates'

for skill in pack-startup pack-refresh; do
    case "$skill" in
        pack-startup) marker='commit-gate canary drives the body'; prefix='modes enforce:'; suffix='— inspect' ;;
        *)            marker='Re-run the function canary';         prefix='modes re-heal:'; suffix='— inspect scripts/hooks/' ;;
    esac
    echo "== $skill =="
    # Extract the fence from each of the three trees; the .claude copy is the
    # one driven below, and the other two must be byte-identical to it.
    extracted=1
    for tree in .claude .codex .agents; do
        SKILL_MD="$PACK_ROOT/$tree/skills/$skill/SKILL.md"
        SNIP_T="$FIXTURE_BASE/$skill.${tree#.}.canary.sh"
        if extract_fence "$SKILL_MD" "$marker" > "$SNIP_T" && [[ -s "$SNIP_T" ]] && bash -n "$SNIP_T" 2>/dev/null; then
            pass "$skill $tree: canary fence extracted ($(wc -l < "$SNIP_T" | tr -d ' ') lines) and parses"
        else
            fail "$skill $tree: canary fence missing or unparsable after marker '$marker'"
            extracted=0
        fi
    done
    [[ "$extracted" -eq 1 ]] || continue
    SNIP="$FIXTURE_BASE/$skill.claude.canary.sh"
    for tree in .codex .agents; do
        if cmp -s "$SNIP" "$FIXTURE_BASE/$skill.${tree#.}.canary.sh"; then
            pass "$skill: $tree fence is byte-identical to the .claude fence"
        else
            fail "$skill: $tree fence DIFFERS from the .claude fence (three-tree drift)"
        fi
    done

    T=$(mk_tree "$skill-ok")
    out=$(run_canary "$T" "$SNIP")
    assert_contains "$skill ok: wiring probe finds all three pack hooks" "$out" "$prefix wired ("
    assert_contains "$skill ok: pack gate passes all three legs, live=INERT (no config)" "$out" \
        "commit-gate self-test PASS (present-config denies, absent-config allows, none allows; live=INERT)"

    printf '%s\n' '{"schema":"pack-session-config/1","intervention_mode":"full"}' > "$T/pack-ops/session-config.json"
    out=$(run_canary "$T" "$SNIP")
    assert_contains "$skill live: a real full config flips the live probe to ACTIVE" "$out" \
        "commit-gate self-test PASS (present-config denies, absent-config allows, none allows; live=ACTIVE)"
    rm -f "$T/pack-ops/session-config.json"

    for m in mut1 mut2 mut3; do
        case "$m" in
            mut1) leg="absent-config FAILS to allow" ;;
            mut2) leg="present-config FAILS to deny" ;;
            *)    leg="none FAILS to allow" ;;
        esac
        T=$(mk_tree "$skill-$m")
        cp "$FIXTURE_BASE/gate.$m.py" "$T/scripts/hooks/modes-commit-gate.py"
        out=$(run_canary "$T" "$SNIP")
        assert_contains "$skill $m: canary reports commit-gate self-test FAIL" "$out" "commit-gate self-test FAIL"
        assert_contains "$skill $m: names the broken leg '$leg'" "$out" "$leg"
        assert_contains "$skill $m: carries the pack remediation suffix '$suffix'" "$out" ") $suffix"
    done
done

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
