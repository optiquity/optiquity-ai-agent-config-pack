#!/usr/bin/env bash
# validate-shell.sh — shell-portability lint. Called by scripts/validate.sh.
#
# Flags shell scripts that use non-portable `mktemp` forms that work on GNU
# (Linux) but break on BSD (macOS), so a project runs identically on both.
# Three non-portable classes are caught:
#
#   1. `mktemp [-d] -t <prefix>XXXXXX` — BSD treats the `-t` argument as a
#      PREFIX and appends its own random suffix, leaving a literal XXXXXX in
#      the path on macOS. Includes the bundled getopt clusters (-dt / -qt /
#      -dqt — any single-dash cluster ending in `t`).
#   2. `mktemp ... --tmpdir` / `--tmpdir=DIR` — a GNU-only long option; BSD
#      mktemp lacks it and errors out.
#   3. `mktemp ... -p <dir>` — the GNU-only short synonym for --tmpdir; BSD
#      mktemp lacks it too.
#
# Portable form (works on both BSD and GNU):
#   mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"
# Both expand a trailing X-run inside a full-path template; keep `-d` when a
# directory is wanted, and fold any --tmpdir / -p directory into the template
# path.
#
# Candidate set: git-TRACKED `*.sh` files (never a filesystem walk). Off a git
# work tree the lint SKIPs cleanly (exit 0) — a fresh checkout is not a
# failure. Shell `#` comments — whole-line AND trailing — are stripped
# quote-aware before matching, so a script may MENTION a non-portable form in
# a comment without tripping the lint, while a real invocation that carries a
# trailing comment still trips (only the comment is removed). A `#` inside a
# quoted string, or in ${#var} / $#, is never treated as a comment.
#
# Usage:
#   validate-shell.sh             lint every tracked *.sh in the project
#   validate-shell.sh --self-test run the built-in synthetic checks
#
# Self-contained bash (no python, no external lint tool) so it stays cheap on
# every validate.sh run. Safe to run directly.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# The bare command token is held in a variable so no pattern-definition line
# carries it next to a flag — this lint is itself a tracked `*.sh`, so it
# scans its own source, and building the patterns from ${_mk} keeps it from
# flagging itself.
_mk='mktemp'
# A word boundary before the command token (so foomktemp / x-mktemp are not
# matches). ERE has no look-behind, so a preceding non-word char stands in.
_wb='(^|[^[:alnum:]_-])'

# Class 1 — `-t <prefix>XXXXXX` (incl. bundled -dt / -qt / -dqt): a single-dash
# cluster ending in `t`, followed by an argument carrying an X-run of 3+.
_CLASS1_RE="${_wb}${_mk}([[:space:]]+-[A-Za-z]+)*[[:space:]]+-[A-Za-z]*t[[:space:]]+[^[:space:];|&]*X{3,}"
# Class 2 — the GNU-only long option --tmpdir / --tmpdir=DIR.
_CLASS2_RE="${_wb}${_mk}[^;|&]*--tmpdir([^[:alnum:]_]|\$)"
# Class 3 — the GNU-only short synonym -p <dir>: a single-dash cluster ending
# in `p`. The [^;|&] token run stops at a command terminator, so a portable
# `mktemp -d "\$d/x.XXXXXX"; mkdir -p foo` never trips on the later mkdir -p.
_CLASS3_RE="${_wb}${_mk}([[:space:]]+-[A-Za-z]+)*[[:space:]]+-[A-Za-z]*p([^[:alnum:]_]|\$)"

# The remedy line, printed on a failure. Single-quoted so it prints verbatim.
_REMEDY='mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"'

HIT_COUNT=0
STRIPPED=""

err() { printf 'validate-shell: %s\n' "$*" >&2; }

# Strip any shell comment (whole-line or trailing) from a line, quote-aware,
# into the STRIPPED global (no subshell — kept O(chars) with no per-line fork).
# A comment begins at the first `#` that is at line start OR preceded by a
# blank AND is outside single/double quotes — so a `#` inside a quoted string,
# or in ${#var} / $# / ${var#pat} (preceded by { / $ / a word char, never a
# blank), is NEVER taken as a comment marker (no false-negative on a real
# invocation next to such a construct). Command substitution "$(...)" is not a
# comment, so foo="$(mktemp ...)" is kept. Lines with no `#` short-circuit.
_strip_comment() {
    STRIPPED="$1"
    case $1 in *'#'*) ;; *) return 0 ;; esac
    local line="$1" n=${#1} i c prev in_s=0 in_d=0
    for (( i = 0; i < n; i++ )); do
        c="${line:i:1}"
        if [[ $c == "'" && $in_d -eq 0 ]]; then
            in_s=$((1 - in_s))
        elif [[ $c == '"' && $in_s -eq 0 ]]; then
            in_d=$((1 - in_d))
        elif [[ $c == '#' && $in_s -eq 0 && $in_d -eq 0 ]]; then
            if [[ $i -eq 0 ]]; then
                STRIPPED=""
                return 0
            fi
            prev="${line:i-1:1}"
            if [[ $prev == [[:blank:]] ]]; then
                STRIPPED="${line:0:i}"
                return 0
            fi
        fi
    done
}

# Does one source line (comment already stripped) carry a non-portable mktemp
# invocation?  0 = yes.
_line_flags() {
    local line="$1"
    if [[ $line =~ $_CLASS1_RE ]] || [[ $line =~ $_CLASS2_RE ]] || [[ $line =~ $_CLASS3_RE ]]; then
        return 0
    fi
    return 1
}

# Scan a stream of lines from stdin, labeling hits "<label>:<lineno>". Each line
# has its `#` comment stripped (quote-aware) BEFORE matching, so mentions in a
# whole-line or trailing comment are spared (mention-vs-invocation). Increments
# HIT_COUNT and prints each hit. Shared by the file lint and the --self-test.
_scan_stream() {
    local label="$1" lineno=0 line
    while IFS= read -r line || [ -n "$line" ]; do
        lineno=$((lineno + 1))
        _strip_comment "$line"
        if _line_flags "$STRIPPED"; then
            err "$label:$lineno: non-portable mktemp — ${line#"${line%%[![:space:]]*}"}"
            HIT_COUNT=$((HIT_COUNT + 1))
        fi
    done
}

run_scan() {
    if ! command -v git >/dev/null 2>&1; then
        echo "[validate-shell] git not found — skipping shell-portability lint (lenient)."
        return 0
    fi
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "[validate-shell] not a git work tree — skipping shell-portability lint (lenient)."
        return 0
    fi

    local files file
    files="$(git ls-files '*.sh')"

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$file" ] || continue
        _scan_stream "$file" < "$file"
    done <<EOF
$files
EOF

    if [ "$HIT_COUNT" -gt 0 ]; then
        err "FAIL — $HIT_COUNT non-portable mktemp invocation(s) found."
        err "These forms work on GNU (Linux) but break on BSD (macOS): the -t"
        err "prefix form leaves a literal XXXXXX in the path on macOS, and"
        err "--tmpdir / -p do not exist in BSD mktemp. Rewrite each to the"
        err "portable full-path template (keep -d for a directory; fold any"
        err "--tmpdir / -p directory into the template path):"
        err "  $_REMEDY"
        return 1
    fi

    echo "[validate-shell] OK — no non-portable mktemp invocations in tracked *.sh."
    return 0
}

run_selftest() {
    local fails=0 xrun d t dt qt dqt p tmpdir_flag bite comment_line
    # Assemble the synthetic buggy forms at RUNTIME so this file's own bytes
    # never carry a non-portable literal on a non-comment line.
    xrun="$(printf 'X%.0s' 1 2 3 4 5 6)"          # -> XXXXXX
    d='-d'; t='-t'; dt='-dt'; qt='-qt'; dqt='-dqt'; p='-p'
    tmpdir_flag='--tmpdir'

    # Route every case through the REAL scan path: strip the comment first,
    # then match (so trailing-comment behavior is genuinely exercised).
    _full_flags() { _strip_comment "$1"; _line_flags "$STRIPPED"; }
    assert_bite() {
        local desc="$1" line="$2"
        if _full_flags "$line"; then
            echo "[validate-shell --self-test] ok BITE  $desc"
        else
            echo "[validate-shell --self-test] FAIL (expected BITE) $desc: $line"
            fails=$((fails + 1))
        fi
    }
    assert_spare() {
        local desc="$1" line="$2"
        if _full_flags "$line"; then
            echo "[validate-shell --self-test] FAIL (expected SPARE) $desc: $line"
            fails=$((fails + 1))
        else
            echo "[validate-shell --self-test] ok SPARE $desc"
        fi
    }
    assert_strip_keeps() {  # the comment-strip must NOT alter this line
        local desc="$1" line="$2"
        _strip_comment "$line"
        if [ "$STRIPPED" = "$line" ]; then
            echo "[validate-shell --self-test] ok KEEP  $desc"
        else
            echo "[validate-shell --self-test] FAIL (strip truncated) $desc: '$line' -> '$STRIPPED'"
            fails=$((fails + 1))
        fi
    }

    # Class 1 — -t and the bundled getopt clusters.
    assert_bite "class1 -t"   "$_mk $d $t agy-auditor.$xrun"
    assert_bite "class1 -dt"  "$_mk $dt agy.$xrun"
    assert_bite "class1 -qt"  "$_mk $qt agy.$xrun"
    assert_bite "class1 -dqt" "$_mk $dqt agy.$xrun"
    # Class 2 — --tmpdir and --tmpdir=DIR.
    assert_bite "class2 --tmpdir=DIR" "$_mk ${tmpdir_flag}=/x foo.$xrun"
    assert_bite "class2 --tmpdir DIR" "$_mk $d $tmpdir_flag /x"
    # Class 3 — -p <dir>.
    assert_bite "class3 -p"   "$_mk $p /some/dir"
    # Portable forms are spared.
    assert_spare "portable dir"  "$_mk $d \"\${TMPDIR:-/tmp}/agy-auditor.$xrun\""
    assert_spare "portable file" "$_mk \"\${TMPDIR:-/tmp}/foo.$xrun\""

    # A MENTION in a TRAILING comment is spared (only the comment is stripped).
    assert_spare "trailing-comment mention" "realcmd=1   # $_mk $t bar.$xrun"
    # A REAL invocation that happens to carry a trailing comment STILL bites
    # (the comment is stripped, the real call remains).
    assert_bite "real call + trailing comment" "d=\$($_mk $t x.$xrun)   # note"
    # A `#` INSIDE a quoted string is NOT a comment — the strip must not
    # truncate there (else a following real call would be missed).
    assert_strip_keeps "in-quote # kept" 'msg="tag #1"'
    assert_strip_keeps "\${#var} kept"   'n=${#items[@]}'
    assert_bite "real call after in-quote #" "log=\"see #9\"; d=\$($_mk $t w.$xrun)"

    # A full-line `#` comment naming a buggy form must be SPARED by the scan.
    HIT_COUNT=0
    comment_line="# example only: $_mk $d $t foo.$xrun"
    _scan_stream "selftest-comment" <<EOF
$comment_line
EOF
    if [ "$HIT_COUNT" -eq 0 ]; then
        echo "[validate-shell --self-test] ok SPARE comment mention skipped"
    else
        echo "[validate-shell --self-test] FAIL (expected SPARE) comment mention"
        fails=$((fails + 1))
    fi

    if [ "$fails" -gt 0 ]; then
        echo "[validate-shell --self-test] FAIL — $fails case(s) wrong."
        return 1
    fi
    echo "[validate-shell --self-test] PASS — all 3 portability classes bite (real invocations bite even with a trailing comment); portable forms, whole-line + trailing comment mentions, and in-quote '#' are spared/kept."
    return 0
}

case "${1:-}" in
    --self-test)
        run_selftest
        ;;
    "")
        run_scan
        ;;
    *)
        err "unknown argument '$1' (usage: validate-shell.sh [--self-test])"
        exit 2
        ;;
esac
