# pack-internal: true  (sourced test-support library; never run directly)
# scripts/tests/lib/assert-line-eq.sh — shared exact-whole-line assert helper.
#
# BD-205 (census OI-3 / D9, Note-21): the tracker migration/summary tests
# assert count fields with a substring needle, e.g.
#     assert_contains "..." "$output" "closed:     1"
# Substring matching is PREFIX-VULNERABLE: "closed:     1" is a substring of
# a line reading "closed:     12", so a WRONG count (12 when 1 was expected)
# passes falsely — a green false-positive, a correctness hole even in
# currently-dormant tracker code.
#
# assert_contains_line fixes this by matching a WHOLE LINE: it PASSes iff some
# line of the haystack, with leading/trailing whitespace trimmed, EXACTLY
# equals the (trimmed) needle. INTERNAL whitespace (the summary's column
# alignment) is preserved, so the existing needles carry over unchanged — only
# the matcher name changes at the call site. A prefix like "closed:     1" no
# longer matches a line "closed:     12": the assertion now FAILS on a wrong
# count.
#
# Drop-in for assert_contains (same 3-arg signature):
#     assert_contains_line "LABEL" "$haystack" "expected whole line (trimmed)"
#
# Companion matcher assert_contains_field (defined below) closes the same
# prefix-vulnerability class for INLINE numeric "key=value" count fields inside
# a compound line (e.g. "… recovered=2 persistent=0 …"), which the whole-line
# matcher structurally cannot reach. See its docstring for the boundary rules.
#
# Reporting-agnostic: dispatches to whichever pass/fail reporter the sourcing
# test already defines (t_pass/t_fail or pass/fail), falling back to a plain
# printf if neither exists — so the one helper serves tests using either
# convention without editing their reporters.
#
# Cheap (ci-check-runtime-compounding): a pure-bash line scan with inline
# parameter-expansion trims — no subprocess per call, no command substitution,
# no filesystem access. macOS bash 3.2 + BSD-utils compatible.

# _assert_line_report_pass LABEL
_assert_line_report_pass() {
    if declare -F t_pass >/dev/null 2>&1; then
        t_pass "$1"
    elif declare -F pass >/dev/null 2>&1; then
        pass "$1"
    else
        printf '  PASS %s\n' "$1"
    fi
}

# _assert_line_report_fail LABEL DETAIL
_assert_line_report_fail() {
    if declare -F t_fail >/dev/null 2>&1; then
        t_fail "$1" "$2"
    elif declare -F fail >/dev/null 2>&1; then
        fail "$1" "$2"
    else
        printf '  FAIL %s\n       %s\n' "$1" "$2"
    fi
}

# assert_contains_line LABEL HAYSTACK NEEDLE
#   PASS iff some whole line of HAYSTACK (leading/trailing whitespace trimmed)
#   equals NEEDLE (also trimmed). Rejects the substring/prefix false-positive
#   that assert_contains allows: needle "closed:     1" will NOT match a line
#   "closed:     12".
assert_contains_line() {
    local label="$1" haystack="$2" needle="$3"
    # Trim leading + trailing whitespace from the needle (internal ws kept).
    local want="$needle"
    want="${want#"${want%%[![:space:]]*}"}"
    want="${want%"${want##*[![:space:]]}"}"
    local line found=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim leading + trailing whitespace from the line (internal ws kept).
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ "$line" == "$want" ]]; then
            found=1
            break
        fi
    done <<< "$haystack"
    if [[ "$found" == 1 ]]; then
        _assert_line_report_pass "$label"
    else
        _assert_line_report_fail "$label" \
            "no whole line == '$want' (whole-line match; haystack head: ${haystack:0:200})"
    fi
}

# assert_contains_field LABEL HAYSTACK NEEDLE
#   Inline-token variant of assert_contains_line for a "key=value" count field
#   that appears WITHIN a compound line (e.g. the retry-sweep summary
#   "forward: close-retry sweep — recovered=2 persistent=0 (max-attempts=3)"),
#   where assert_contains_line's whole-line equality structurally can't reach.
#
#   NEEDLE is a "key=value" token whose value is a digit run (e.g. recovered=2).
#   PASS iff some line contains NEEDLE as a WHOLE token: the char BEFORE the key
#   is start-of-line or a non-word char (not [A-Za-z0-9_-]) AND the char AFTER
#   the value is end-of-line or a NON-DIGIT. This rejects the numeric-prefix
#   false-positive that assert_contains allows — needle "recovered=2" will NOT
#   match a line containing "recovered=20" — and the key-suffix false-positive
#   ("attempts=3" will NOT match "max-attempts=3"). Same reporting-agnostic
#   dispatch; pure-bash, no subprocess per call.
assert_contains_field() {
    local label="$1" haystack="$2" needle="$3"
    local line pre post lastp firstp found=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        local work="$line"
        while [[ "$work" == *"$needle"* ]]; do
            pre="${work%%"$needle"*}"
            post="${work#*"$needle"}"
            if [[ -z "$pre" ]]; then
                lastp=""            # start-of-line → a valid before-boundary
            else
                lastp="${pre: -1}"  # char immediately before the key
            fi
            firstp="${post:0:1}"    # char immediately after the value ("" at EOL)
            case "$lastp" in
                [A-Za-z0-9_-]) : ;;             # key is a suffix → not a whole token
                *)
                    case "$firstp" in
                        [0-9]) : ;;             # value continues → not a whole token
                        *) found=1 ;;
                    esac
                    ;;
            esac
            [[ "$found" == 1 ]] && break
            work="$post"                        # advance past this hit; look again
        done
        [[ "$found" == 1 ]] && break
    done <<< "$haystack"
    if [[ "$found" == 1 ]]; then
        _assert_line_report_pass "$label"
    else
        _assert_line_report_fail "$label" \
            "no whole token '$needle' (key=value; haystack head: ${haystack:0:200})"
    fi
}
