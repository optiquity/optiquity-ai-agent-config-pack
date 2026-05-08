#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-dry-run-migration.sh — BD-114 self-tests.
#
# Verifies scripts/dry-run-migration.sh against:
#   T1 happy-path  — synthetic fixture (test-fixtures/v10-realistic-ot)
#                    exits 0, --report-out file is written, work dir is
#                    cleaned afterwards.
#   T2 missing-arg — invoked with no args, exits with usage code (2).
#   T3 bad-path    — invoked with a non-existent local path, exits with
#                    acquisition code (4).
#   T4 tmp-refused — invoked with `--tmp-dir` outside /tmp / $TMPDIR,
#                    exits with read-only-refused code (5).
#
# Usage:
#     bash scripts/test-dry-run-migration.sh
#
# Exit 0 on all-pass; 1 otherwise. Prints a summary line:
#     === Results: <P> passed, <F> failed ===

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HARNESS="$SCRIPT_DIR/dry-run-migration.sh"
FIXTURE="$PACK_ROOT/test-fixtures/v10-realistic-ot"

PASS_COUNT=0
FAIL_COUNT=0

t_pass() { printf '  PASS — %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
t_fail() { printf '  FAIL — %s\n' "$1" >&2; FAIL_COUNT=$((FAIL_COUNT + 1)); }

[[ -x "$HARNESS" ]] \
    || { printf 'FATAL: harness not executable: %s\n' "$HARNESS" >&2; exit 1; }

# ── T1: happy path ─────────────────────────────────────────────────────────

printf 'T1 — happy path against %s\n' "$FIXTURE"
if [[ ! -d "$FIXTURE" ]]; then
    t_fail "T1 fixture missing: $FIXTURE (run test-fixtures/build.sh --name v10-realistic-ot --clean)"
else
    t1_report="$(mktemp -t bd114-t1-report.XXXXXX)"
    t1_log="$(mktemp -t bd114-t1-log.XXXXXX)"
    rc=0
    bash "$HARNESS" "$FIXTURE" --report-out "$t1_report" \
        > "$t1_log" 2>&1 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        t_pass "T1.a exit code = 0"
    else
        t_fail "T1.a exit code = $rc (expected 0); log: $t1_log"
    fi
    if [[ -s "$t1_report" ]]; then
        t_pass "T1.b --report-out written and non-empty"
    else
        t_fail "T1.b --report-out empty or missing: $t1_report"
    fi
    # Confirm the report mentions a v10-detected path + a non-empty diff.
    if grep -q 'Detected version:.*v10' "$t1_report" 2>/dev/null \
       && grep -q 'Diff (file list)' "$t1_report" 2>/dev/null; then
        t_pass "T1.c report content sane (v10 detected, diff section present)"
    else
        t_fail "T1.c report content missing expected sections; see $t1_report"
    fi
    # Confirm the work dir was cleaned. The log line "Work dir (cleaned)"
    # in the report names the path; it should not exist anymore.
    work_line=$(grep -m1 'Work dir (cleaned)' "$t1_report" 2>/dev/null \
                | sed 's/.*`\(.*\)`.*/\1/')
    if [[ -n "$work_line" && ! -d "$work_line" ]]; then
        t_pass "T1.d work dir cleaned: $work_line"
    elif [[ -z "$work_line" ]]; then
        t_fail "T1.d could not find work-dir line in report"
    else
        t_fail "T1.d work dir still present after run: $work_line"
    fi
    rm -f "$t1_report" "$t1_log"
fi

# ── T2: missing arg ────────────────────────────────────────────────────────

printf 'T2 — missing required arg\n'
t2_log="$(mktemp -t bd114-t2-log.XXXXXX)"
rc=0
bash "$HARNESS" > "$t2_log" 2>&1 || rc=$?
if [[ "$rc" -eq 2 ]]; then
    t_pass "T2 exit code = 2 (DRY_EXIT_USAGE)"
else
    t_fail "T2 exit code = $rc (expected 2); log: $t2_log"
fi
rm -f "$t2_log"

# ── T3: bad local path ─────────────────────────────────────────────────────

printf 'T3 — non-existent local path\n'
t3_log="$(mktemp -t bd114-t3-log.XXXXXX)"
rc=0
bash "$HARNESS" /this/path/does/not/exist-bd114-test \
    > "$t3_log" 2>&1 || rc=$?
if [[ "$rc" -eq 4 ]]; then
    t_pass "T3 exit code = 4 (DRY_EXIT_ACQUIRE)"
else
    t_fail "T3 exit code = $rc (expected 4); log: $t3_log"
fi
rm -f "$t3_log"

# ── T4: --tmp-dir outside /tmp / $TMPDIR ───────────────────────────────────

printf 'T4 — --tmp-dir outside /tmp / $TMPDIR\n'
# Place a refused-tmp-base under PACK_ROOT itself; that is definitely not
# under /tmp or $TMPDIR. The harness must refuse before any clone happens.
t4_bad_tmp="$PACK_ROOT/.bd114-test-refused-tmp-$$"
mkdir -p "$t4_bad_tmp"
t4_log="$(mktemp -t bd114-t4-log.XXXXXX)"
rc=0
bash "$HARNESS" "$FIXTURE" --tmp-dir "$t4_bad_tmp" \
    > "$t4_log" 2>&1 || rc=$?
if [[ "$rc" -eq 5 ]]; then
    t_pass "T4 exit code = 5 (DRY_EXIT_READONLY_REFUSED)"
else
    t_fail "T4 exit code = $rc (expected 5); log: $t4_log"
fi
rm -rf "$t4_bad_tmp"
rm -f "$t4_log"

# ── Summary ────────────────────────────────────────────────────────────────

printf '\n=== Results: %d passed, %d failed ===\n' "$PASS_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
    exit 1
fi
exit 0
