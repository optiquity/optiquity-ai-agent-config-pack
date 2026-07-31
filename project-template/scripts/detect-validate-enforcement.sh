#!/usr/bin/env bash
# detect-validate-enforcement.sh — report whether the project's validate.sh
# quality gate is actually ENFORCED before code leaves the machine.
#
# It probes two enforcement channels, read-only, and prints EXACTLY ONE
# verdict token to stdout:
#
#   enforced (ci-workflow)   a .github/workflows/*.yml|*.yaml step runs it
#   enforced (git-hook)      a local pre-push or pre-commit hook body runs it
#   unenforced               neither channel positively runs it
#
# Detection is a BEST-EFFORT LOCAL HEURISTIC. It covers only GitHub Actions
# workflows and the local hook bodies; it does not see other CI systems or
# wrapper targets (a Makefile / npm script / pre-commit multiplexer that calls
# validate.sh). A miss reports "unenforced" — usually the low-cost direction (a
# redundant suggestion the developer declines). That bias toward "unenforced" is
# NOT absolute, though: matching is line-level, so an unquoted executable-form
# mention in a NON-EXECUTED position (a heredoc body, an unquoted echo argument,
# a dead branch, an unused assignment) can still be reported "enforced" — the
# known upper boundary of this best-effort heuristic.
#
# NEVER-FAILS FLOOR: the detection path ALWAYS exits 0 and ALWAYS emits exactly
# one of the three tokens above, defaulting to "unenforced" on ANY internal
# uncertainty, non-git tree, or unreadable input. Every probe is guarded and
# tolerant. (set -u only; NOT set -e — an internal probe returning non-zero
# must not abort the script.)
#
# Matcher: per candidate line, the shell `#` comment (whole-line AND trailing)
# is stripped quote-aware FIRST; the line is then tokenized (honoring quotes) and
# a hit requires a FIXED-STRING `validate.sh` PATH token (the escaped-dot
# equivalent — never an unescaped-dot regex, which also matches the sibling
# validate-shell.sh) that is BOUND to an executor: either immediately after
# `bash`/`sh`, or at command position as an unquoted `…/validate.sh` path. Mere
# CO-PRESENCE of a validate.sh token and an executor on the line is NOT a hit
# (e.g. `bash other.sh || echo "run validate.sh"`), nor is a mention that
# survives only inside a comment.
#
# Usage:
#   detect-validate-enforcement.sh             print the verdict token
#   detect-validate-enforcement.sh --self-test run the built-in synthetic checks
#
# Self-contained bash (no external tool), portable, and temp-file-free. Safe to
# run directly.
set -u

# Quote-aware comment strip (whole-line or trailing) into the STRIPPED global
# (no subshell). A comment begins at the first `#` that is at line start OR
# preceded by a blank AND is outside single/double quotes — so a `#` inside a
# quoted string, or in ${#var} / $#, is NEVER taken as a comment marker. Lines
# with no `#` short-circuit.
STRIPPED=""
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

# Tokenize a (comment-stripped) line into whitespace-separated WORD tokens,
# honoring single/double quotes so a quoted string stays ONE token (its inner
# spaces do not split). Populates the globals _TOKENS[] + _NTOK. O(chars), no
# fork. Command operators are NOT split off char-by-char; a space-separated
# operator (`||`, `&&`, `|`, `;`, `(`) lands as its own token, which is all the
# command-position tracking below needs (glued operators degrade to a safe
# no-hit — SAFE BIAS).
_TOKENS=()
_NTOK=0
_tokenize() {
    _TOKENS=(); _NTOK=0
    local line="$1" n=${#1} i=0 c cur="" have=0 in_s=0 in_d=0
    while [ "$i" -lt "$n" ]; do
        c="${line:i:1}"
        if [ "$in_s" -eq 1 ]; then
            cur="$cur$c"; have=1
            [ "$c" = "'" ] && in_s=0
        elif [ "$in_d" -eq 1 ]; then
            cur="$cur$c"; have=1
            [ "$c" = '"' ] && in_d=0
        elif [ "$c" = "'" ]; then
            in_s=1; cur="$cur$c"; have=1
        elif [ "$c" = '"' ]; then
            in_d=1; cur="$cur$c"; have=1
        elif [[ $c == [[:space:]] ]]; then
            if [ "$have" -eq 1 ]; then _TOKENS[$_NTOK]="$cur"; _NTOK=$((_NTOK + 1)); cur=""; have=0; fi
        else
            cur="$cur$c"; have=1
        fi
        i=$((i + 1))
    done
    [ "$have" -eq 1 ] && { _TOKENS[$_NTOK]="$cur"; _NTOK=$((_NTOK + 1)); }
    return 0
}

# Does one source line carry a validate.sh invocation BOUND to an executor, for
# the given channel?  0 = yes.  A validate.sh-bearing PATH token counts ONLY in
# EXECUTED position — either (a) IMMEDIATELY after an executor `bash`/`sh` (as
# its script argument; a QUOTED token bites ONLY here), or (b) at COMMAND
# position (line start, after a `;`/`|`/`&`/`(`/`{` separator token, or —
# workflow only — after a `run:` key) AND itself an UNQUOTED path form
# `…/validate.sh`. It is NOT a hit when validate.sh is merely an argument to a
# non-executor (echo/printf/a message string) or sits after an unrelated
# command — mere CO-PRESENCE of a validate.sh token and an executor on the line
# is not enough. The comment is stripped FIRST; the fixed-string test (case glob
# `*validate.sh*`, `.` literal) never matches the sibling validate-shell.sh.
# SAFE BIAS (best-effort, NOT absolute): position-tracking is line-level, so a
# token in a clearly non-executed position usually does not hit (a
# false-negative just re-suggests). It is not a guarantee, though — an unquoted
# executable-form mention in a non-executed position (a heredoc body, an
# unquoted echo argument, a dead branch, an unused assignment) can still hit,
# the known upper boundary of this heuristic.
_line_is_invocation() {
    local channel="$2" s tok unq idx
    local cmd_pos=1 prev_exec=0
    _strip_comment "$1"
    s="$STRIPPED"
    # Fast reject: no validate.sh token anywhere on the stripped line.
    case "$s" in *validate.sh*) ;; *) return 1 ;; esac
    _tokenize "$s"
    idx=0
    while [ "$idx" -lt "$_NTOK" ]; do
        tok="${_TOKENS[$idx]}"
        # If this token bears the validate.sh token, test executed-position.
        case "$tok" in
            *validate.sh*)
                # unq = token, quote chars removed, up to 2 trailing shell
                # metachars peeled (so `validate.sh)` / `validate.sh;` still
                # read as a path). Single-char peels never cut into a mid-path
                # `)` of a `$(…)` command substitution.
                unq="${tok//\"/}"; unq="${unq//\'/}"
                unq="${unq%[);|&]}"; unq="${unq%[);|&]}"
                case "$unq" in
                    *validate.sh)
                        # (a) executor-bound: previous token was bash/sh and
                        #     this token is its path argument ending validate.sh.
                        if [ "$prev_exec" -eq 1 ]; then return 0; fi
                        # (b) command-position UNQUOTED path form (has a `/`).
                        if [ "$cmd_pos" -eq 1 ]; then
                            case "$tok" in
                                *\"*|*\'*) : ;;             # quoted ⇒ (a)-only
                                */validate.sh) return 0 ;;  # an executable path
                            esac
                        fi
                        ;;
                esac
                ;;
        esac
        # Advance command-position / prev-executor state for the NEXT token.
        case "$tok" in
            ';'|'|'|'||'|'&'|'&&'|'('|')'|'{'|'}')
                cmd_pos=1; prev_exec=0 ;;
            *)
                if [ "$channel" = "workflow" ] && [ "$tok" = "run:" ]; then
                    cmd_pos=1; prev_exec=0
                else
                    case "$tok" in
                        bash|sh) prev_exec=1 ;;
                        *)       prev_exec=0 ;;
                    esac
                    cmd_pos=0
                fi ;;
        esac
        idx=$((idx + 1))
    done
    return 1
}

# Scan a file's lines for an invocation of the given channel. 0 = a hit found.
_scan_file() {
    local file="$1" channel="$2" line
    [ -f "$file" ] && [ -r "$file" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        if _line_is_invocation "$line" "$channel"; then
            return 0
        fi
    done < "$file"
    return 1
}

# CI channel: dir-existence-guarded, scoped to .github/workflows ONLY (never a
# recursive .github/ walk). Absent dir ⇒ channel unenforced, no error.
_detect_ci() {
    [ -d .github/workflows ] || return 1
    local f
    for f in .github/workflows/*.yml .github/workflows/*.yaml; do
        [ -f "$f" ] || continue
        if _scan_file "$f" workflow; then
            return 0
        fi
    done
    return 1
}

# Hook channel: resolve the effective hooks dir and inspect the CONTENT of both
# pre-push and pre-commit (content, not existence — an immutable pre-commit may
# run a different check, so existence alone would false-enforce).
_detect_hook() {
    local hd hook
    hd="$(git rev-parse --git-path hooks 2>/dev/null || true)"
    [ -n "$hd" ] || return 1
    for hook in "$hd/pre-push" "$hd/pre-commit"; do
        if _scan_file "$hook" hook; then
            return 0
        fi
    done
    return 1
}

# Detection path — ALWAYS emits exactly one token and returns 0.
_run_detect() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$root" ]; then
        cd "$root" 2>/dev/null || true
    fi
    if _detect_ci 2>/dev/null; then
        printf '%s\n' 'enforced (ci-workflow)'
        return 0
    fi
    if _detect_hook 2>/dev/null; then
        printf '%s\n' 'enforced (git-hook)'
        return 0
    fi
    printf '%s\n' 'unenforced'
    return 0
}

# --self-test — synthetic vectors run through the REAL matcher. Buggy/mention
# forms are assembled at RUNTIME (from $V / $ex) so this file's own bytes carry
# no raw `bash …/validate.sh` invocation line, and the detector never
# false-detects its own source. This is the ONE mode allowed to exit non-zero.
_run_selftest() {
    local fails=0 V ex ng out rc
    V='validate.sh'            # the real gate token
    ex='validate-shell.sh'     # the sibling leg — must never match

    _assert_hit() {   # desc, channel, line  → expect an invocation (enforced)
        if _line_is_invocation "$3" "$2"; then
            echo "[detect-validate-enforcement --self-test] ok HIT   $1"
        else
            echo "[detect-validate-enforcement --self-test] FAIL (expected HIT) $1: $3"
            fails=$((fails + 1))
        fi
    }
    _assert_miss() {  # desc, channel, line  → expect NO invocation (unenforced)
        if _line_is_invocation "$3" "$2"; then
            echo "[detect-validate-enforcement --self-test] FAIL (expected MISS) $1: $3"
            fails=$((fails + 1))
        else
            echo "[detect-validate-enforcement --self-test] ok MISS  $1"
        fi
    }

    # Sibling-leg vectors: an invocation of the sibling validate-shell.sh must
    # NOT match (fixed-string discriminator).
    _assert_miss "workflow runs only the sibling leg" workflow "      - run: bash scripts/$ex"
    _assert_miss "hook runs only the sibling leg"      hook     "bash \"\$ROOT/scripts/$ex\""
    # Comment-only mentions (whole-line AND trailing) are spared.
    _assert_miss "whole-line comment mention (hook)"      hook     "# we deliberately do NOT run scripts/$V here"
    _assert_miss "trailing-comment mention (hook)"        hook     "realcmd=1   # bash scripts/$V"
    _assert_miss "whole-line comment mention (workflow)"  workflow "      # - run: bash scripts/$V"
    _assert_miss "trailing-comment mention (workflow)"    workflow "      - run: true   # see scripts/$V"
    # CO-PRESENCE false-positives (FE1/FE2): a validate.sh token and an executor
    # are both present but the token is NOT in executed position — must be SPARED.
    # FE1 — bash runs another script; validate.sh is only text in an echo arg.
    _assert_miss "FE1 co-presence: executor runs another script" hook     "bash ./run-checks.sh || echo \"run $V to see details\""
    # FE2 — echo (not an executor) merely mentions validate.sh under run:.
    _assert_miss "FE2 co-presence: run: echo mentions the path"  workflow "      - run: echo \"later we will add $V\""
    # True positives: real EXECUTED invocations bite (even with a trailing comment).
    _assert_hit "hook bash + quoted path"                 hook     "bash \"\$ROOT/scripts/$V\""
    _assert_hit "hook bash + quoted path + trailing comment" hook  "bash \"\$ROOT/scripts/$V\"   # quality gate"
    _assert_hit "hook bash + bare path"                   hook     "bash scripts/$V"
    _assert_hit "hook bash + bare name (run: | own line)" hook     "bash $V"
    _assert_hit "hook ./ exec form"                       hook     "./scripts/$V"
    _assert_hit "workflow run: bash invocation"           workflow "      - run: bash scripts/$V"

    # KNOWN BOUNDARY (within scope, accepted): matching is line-level with no
    # full parse, so an unquoted executable-form mention of the gate in a
    # NON-EXECUTED position still reports "enforced" — e.g. a heredoc body that
    # only PRINTS a "run the gate" instruction, an unquoted echo argument, a
    # dead `if false; then … fi` branch, or an unused command-position
    # assignment (`VAR=scripts/validate.sh`). No vector pins that residual as
    # "expected"; it is noted here so a future tightening of the matcher is a
    # deliberate, noticed change rather than a silent one.

    # Non-git channel: the detection path in a non-git cwd yields unenforced,
    # rc 0 (probe robustness — the never-fails floor). `/` is reliably non-git.
    out="$( cd / 2>/dev/null && _run_detect 2>/dev/null )" ; rc=$?
    if [ "$out" = "unenforced" ] && [ "$rc" -eq 0 ]; then
        echo "[detect-validate-enforcement --self-test] ok MISS  non-git cwd → unenforced rc 0"
    else
        echo "[detect-validate-enforcement --self-test] FAIL (expected unenforced rc0) non-git cwd: got '$out' rc=$rc"
        fails=$((fails + 1))
    fi

    if [ "$fails" -gt 0 ]; then
        echo "[detect-validate-enforcement --self-test] FAIL — $fails case(s) wrong."
        return 1
    fi
    echo "[detect-validate-enforcement --self-test] PASS — sibling-leg + comment (whole-line & trailing) + co-presence (FE1/FE2) spared; executor-bound bash/./ + run: invocations bite; non-git → unenforced."
    return 0
}

case "${1:-}" in
    --self-test)
        _run_selftest
        exit $?
        ;;
    "")
        _run_detect
        exit 0
        ;;
    *)
        # Unknown argument — never error the caller; default to the safe token.
        printf '%s\n' 'unenforced'
        exit 0
        ;;
esac
