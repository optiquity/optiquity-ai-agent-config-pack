#!/usr/bin/env bash
# scripts/tests/tracker-errors-test.sh — offline test suite for the
# typed-error formatter (BD-070).
#
# Three groups:
#   1. Per-code emit — for each of the 11 codes (10 from V1 §2.5 + the
#      pack-internal `not-implemented` code), assert
#      ERROR/MESSAGE prefix correct and "→ Run:" verb line present.
#   2. Format details — multi-line context passthrough; emit-vs-format
#      stdout/stderr routing; unknown code falls back gracefully;
#      no-message and message-only short forms.
#   3. Backward-compat — the format the BD-060 / BD-061 test suites
#      assert against (ERROR: <code> + MESSAGE: <message>) is still
#      the first 1-2 lines.
#
# Usage: bash scripts/tests/tracker-errors-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="$REPO_ROOT/scripts/lib/tracker-errors.sh"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

# shellcheck disable=SC1090
source "$LIB"

# ─────────────────────────────────────────────────────────────────
# Group 1: per-code emit (10 codes from V1 §2.5)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: per-code emit (11 codes; 10 V1 §2.5 + not-implemented) ===\n"

# Map each code → expected "→ Run:" verb fragment for substring check.
declare_verb() {
    case "$1" in
        network-unreachable)        echo "gh api rate_limit" ;;
        rate-limit-primary)         echo "wait for the reset window, then re-run" ;;
        rate-limit-secondary)       echo "wait for the reset window, then re-run" ;;
        auth-missing)               echo "gh auth login" ;;
        auth-expired)               echo "gh auth login" ;;
        auth-insufficient-scope)    echo "gh auth refresh -s <scope>" ;;
        not-found)                  echo "verify the issue id and re-run" ;;
        validation)                 echo "review the backend message above" ;;
        schema-reshape)             echo "pack tracker doctor" ;;
        partial-write)              echo "see resume options above" ;;
        not-implemented)            echo "pack tracker doctor" ;;
    esac
}

while IFS= read -r code; do
    out=$(tracker_error_format "$code" "test message for $code")
    # First line is ERROR: <code>.
    first_line=$(printf '%s' "$out" | sed -n '1p')
    assert_eq "1.$code first-line ERROR" "ERROR: $code" "$first_line"
    # MESSAGE: line present
    assert_contains "1.$code MESSAGE: line" "$out" "MESSAGE: test message for $code"
    # Verb line present and matches per-code expectation
    expected_verb=$(declare_verb "$code")
    assert_contains "1.$code verb line ('$expected_verb')" "$out" "→ Run: $expected_verb"
    # Verb is on the LAST line (Layer 2: every error ENDS with → Run:)
    last_line=$(printf '%s' "$out" | tail -n 1)
    assert_contains "1.$code verb line is last" "$last_line" "→ Run:"
done < <(tracker_error_codes)

# ─────────────────────────────────────────────────────────────────
# Group 2: format details
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: format details ===\n"

# 2.1 multi-line context passthrough (V1 §9 message shape: backend, mirror, etc.)
out=$(tracker_error_format network-unreachable "i/o timeout" \
    "Backend: github (org/repo)" \
    "Mirror at BACKLOG.md (last regenerated 2h ago);" \
    "the chat can read it for context but cannot write until reachable.")
assert_contains "2.1 context line 1 passthrough" "$out" "Backend: github (org/repo)"
assert_contains "2.1 context line 2 passthrough" "$out" "Mirror at BACKLOG.md"
assert_contains "2.1 context line 3 passthrough" "$out" "cannot write until reachable"
# Verb line is still last
last=$(printf '%s' "$out" | tail -n 1)
assert_contains "2.1 verb still last after extras" "$last" "→ Run:"

# 2.2 emit-vs-format stdout/stderr routing
err_only=$(tracker_error_emit not-found "issue 99 not found" 2>&1 1>/dev/null) || true
stdout_only=$(tracker_error_emit not-found "issue 99 not found" 2>/dev/null) || true
assert_contains "2.2 emit writes to stderr"  "$err_only"     "ERROR: not-found"
assert_eq       "2.2 emit writes nothing to stdout" "" "$stdout_only"

# 2.3 emit returns rc=1
if tracker_error_emit validation "test" 2>/dev/null; then
    t_fail "2.3 emit rc=1" "got rc=0 unexpectedly"
else
    t_pass "2.3 emit rc=1"
fi

# 2.4 unknown code falls back to a generic verb (does not crash)
out=$(tracker_error_format mystery-code "an unknown error")
assert_contains "2.4 unknown code first-line" "$out" "ERROR: mystery-code"
assert_contains "2.4 unknown code emits a verb line" "$out" "→ Run:"

# 2.5 no-message form (single-arg emit)
out=$(tracker_error_format auth-missing)
first_line=$(printf '%s' "$out" | sed -n '1p')
assert_eq       "2.5 no-message first line"          "ERROR: auth-missing" "$first_line"
# Should NOT have a MESSAGE: line
if printf '%s' "$out" | grep -q "^MESSAGE:"; then
    t_fail "2.5 no-message form has no MESSAGE: line" "MESSAGE: line unexpectedly present"
else
    t_pass "2.5 no-message form has no MESSAGE: line"
fi
assert_contains "2.5 no-message still has verb line" "$out" "→ Run: gh auth login"

# 2.6 codes() emits exactly 10 lines
n=$(tracker_error_codes | wc -l | tr -d ' ')
assert_eq "2.6 tracker_error_codes emits 11 codes" "11" "$n"

# ─────────────────────────────────────────────────────────────────
# Group 3: backward-compat (BD-060 / BD-061 test format preserved)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: backward-compat with BD-060/-061 format ===\n"

# BD-060 / BD-061 tests assert `ERROR: <code>` + `MESSAGE: <message>` substring.
# The new format preserves these as the first two lines.
out=$(tracker_error_format validation "create: title required")
line1=$(printf '%s' "$out" | sed -n '1p')
line2=$(printf '%s' "$out" | sed -n '2p')
assert_eq "3.1 line 1 unchanged"  "ERROR: validation"               "$line1"
assert_eq "3.2 line 2 unchanged"  "MESSAGE: create: title required" "$line2"

# 3.3 typed code lookup substring (the same test BD-060 uses)
err=$(tracker_error_emit network-unreachable "connection refused" 2>&1 1>/dev/null) || true
assert_contains "3.3 emit error stream contains 'ERROR: <code>'" "$err" "ERROR: network-unreachable"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
