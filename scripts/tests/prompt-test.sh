#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/prompt-test.sh — unit tests for scripts/lib/prompt.sh.
#
# Pins the 4-function contract of the shared interactive-prompt helper
# (BD-284): prompt_should_interact (precedence truth table), prompt_read
# (empty/EOF -> default, always rc 0), prompt_confirm (y/n/empty/EOF), and
# prompt_choice (canonical-token echo, re-prompt on invalid/empty-no-default,
# and the declare-verify-backing EOF safety: EOF -> non-zero AND no echo, so the
# lib can never synthesize a clobbering menu action on a closed stdin). See
# RECONCILED-BD284.md §2/§3. The EOF-safety case matters NOW, before BD-283 /
# BD-285 build consumers on top of prompt_choice.
#
# Usage:    bash scripts/tests/prompt-test.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/prompt.sh
source "$REPO_ROOT/scripts/lib/prompt.sh"

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then pass "$label"
    else fail "$label" "$expected" "$actual"; fi
}

# ── prompt_should_interact — precedence truth table ─────────────────────────
echo "== prompt_should_interact =="
prompt_should_interact 1 0; rc=$?
assert_eq "force_off=1 -> do-not-interact (rc 1)" "1" "$rc"
prompt_should_interact 0 1; rc=$?
assert_eq "force_on=1 -> interact (rc 0)" "0" "$rc"
prompt_should_interact 1 1; rc=$?
assert_eq "force_off beats force_on (rc 1)" "1" "$rc"
PACK_PROMPT_FORCE_INTERACTIVE=1 prompt_should_interact 0 0; rc=$?
assert_eq "env seam PACK_PROMPT_FORCE_INTERACTIVE=1 -> interact (rc 0)" "0" "$rc"
prompt_should_interact 0 0 </dev/null; rc=$?
assert_eq "no override + non-TTY stdin -> do-not-interact (rc 1)" "1" "$rc"

# ── prompt_read — empty/EOF -> default, value passthrough, always rc 0 ───────
echo "== prompt_read =="
got=$(printf '\n' | prompt_read "Label" "def" 2>/dev/null); rc=$?
assert_eq "empty input -> default" "def" "$got"
assert_eq "empty input -> rc 0" "0" "$rc"
got=$(prompt_read "Label" "def" </dev/null 2>/dev/null); rc=$?
assert_eq "EOF -> default" "def" "$got"
assert_eq "EOF -> rc 0" "0" "$rc"
got=$(printf 'val\n' | prompt_read "Label" "def" 2>/dev/null)
assert_eq "typed value passes through" "val" "$got"
got=$(printf 'val\n' | prompt_read "Label" 2>/dev/null)
assert_eq "typed value with no default" "val" "$got"

# ── prompt_confirm — y / n / empty->default / EOF->default ──────────────────
echo "== prompt_confirm =="
printf 'y\n'   | prompt_confirm "Q?"      >/dev/null 2>&1; assert_eq "y -> yes (rc 0)"            "0" "$?"
printf 'yes\n' | prompt_confirm "Q?"      >/dev/null 2>&1; assert_eq "yes -> yes (rc 0)"          "0" "$?"
printf 'n\n'   | prompt_confirm "Q?" "y"  >/dev/null 2>&1; assert_eq "n (default y) -> no (rc 1)" "1" "$?"
printf '\n'    | prompt_confirm "Q?" "y"  >/dev/null 2>&1; assert_eq "empty -> default y (rc 0)"  "0" "$?"
printf '\n'    | prompt_confirm "Q?" "n"  >/dev/null 2>&1; assert_eq "empty -> default n (rc 1)"  "1" "$?"
prompt_confirm "Q?" "y" </dev/null        >/dev/null 2>&1; assert_eq "EOF -> default y (rc 0)"    "0" "$?"
prompt_confirm "Q?" "n" </dev/null        >/dev/null 2>&1; assert_eq "EOF -> default n (rc 1)"    "1" "$?"

# ── prompt_choice — canonical echo, re-prompt, and EOF safety ───────────────
echo "== prompt_choice =="
got=$(printf 'r\n'   | prompt_choice "Q" "k,r,m" "k" 2>/dev/null)
assert_eq "valid token echoed" "r" "$got"
got=$(printf 'R\n'   | prompt_choice "Q" "k,r,m" "k" 2>/dev/null)
assert_eq "case-insensitive match echoes CANONICAL token (R -> r)" "r" "$got"
got=$(printf '\n'    | prompt_choice "Q" "k,r,m" "k" 2>/dev/null)
assert_eq "empty input + default -> default token" "k" "$got"
got=$(printf 'x\nk\n' | prompt_choice "Q" "k,r,m" "k" 2>/dev/null)
assert_eq "out-of-set token re-prompts, then accepts a valid one" "k" "$got"
got=$(printf '\nk\n'  | prompt_choice "Q" "k,r,m" 2>/dev/null)
assert_eq "empty input + NO default re-prompts, then accepts" "k" "$got"
got=$(printf 's\n'   | prompt_choice "Q" "1,2,3,s,q" "q" 2>/dev/null)
assert_eq "BD-283-shape menu echoes 's'" "s" "$got"

# declare-verify-backing — closed stdin => prompt_choice returns non-zero AND
# emits NO token, so the lib can NEVER synthesize a clobbering menu action. The
# `if out=$(...)` conditional is itself the return-code-under-set-e discipline.
if out=$(prompt_choice "Pick" "k,r,m" "k" </dev/null 2>/dev/null); then
    fail "prompt_choice EOF must return NON-ZERO (safety by construction)"
else
    if [[ -z "$out" ]]; then
        pass "prompt_choice EOF returns non-zero AND emits no token (cannot synthesize an action)"
    else
        fail "prompt_choice EOF must emit NO token" "" "$out"
    fi
fi

# ── Double-source guard — a second source is a harmless no-op ───────────────
echo "== double-source guard =="
# shellcheck source=../lib/prompt.sh
source "$REPO_ROOT/scripts/lib/prompt.sh"
assert_eq "second source keeps prompt_read defined" "function" "$(type -t prompt_read)"
assert_eq "double-source sentinel set" "1" "${_PACK_PROMPT_SH:-unset}"

# ── Summary ─────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
