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
#   T5 apply-sandbox (BD-291) — fixture-mode acceptance + mutation bites:
#     T5.a  --apply-sandbox against the fixture exits 0; report carries
#           per-stream accounting PASS verdicts and a set-equality-GREEN
#           validate-docs delta (declared == measured, nonzero).
#     T5.b  (m4) a post-hook mutates ONE recorded synthesis line in a
#           migrated entry → exit 8; RECORDED-BUT-ABSENT and FABRICATED
#           both named (the §5.1(b) reduced-mode leg bites both ways).
#     T5.c  (m5) a post-hook introduces an UNDECLARED validator failure
#           AND satisfies a DECLARED manual-fill item → exit 8; the
#           validate-docs delta names the UNDECLARED and UNDELIVERED
#           members (the §5.1(d) set-equality bites both ways).
#
# Usage:
#     bash scripts/test-dry-run-migration.sh
#
# Exit 0 on all-pass; 1 otherwise. Prints a summary line:
#     === Results: <P> passed, <F> failed ===

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/tests/fixture-dependent/ → pack root is three levels up (BD-219
# location-based fixture cohesion). The dry-run-migration.sh harness stays at
# scripts/ (not moved), so reach it two levels up.
PACK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HARNESS="$SCRIPT_DIR/../../dry-run-migration.sh"
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
    t1_report="$(mktemp "${TMPDIR:-/tmp}/bd114-t1-report.XXXXXX")"
    t1_log="$(mktemp "${TMPDIR:-/tmp}/bd114-t1-log.XXXXXX")"
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
t2_log="$(mktemp "${TMPDIR:-/tmp}/bd114-t2-log.XXXXXX")"
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
t3_log="$(mktemp "${TMPDIR:-/tmp}/bd114-t3-log.XXXXXX")"
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
t4_log="$(mktemp "${TMPDIR:-/tmp}/bd114-t4-log.XXXXXX")"
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

# ── T5: --apply-sandbox fixture-mode acceptance + mutation bites (BD-291) ──
#
# Each case runs the FULL pipeline (dry-run + apply + auto-resume +
# verification battery) against the built fixture — 3 migrator runs
# total, bounded by the fixture's size, confined to the fixture-owning
# shard.

printf 'T5 — --apply-sandbox against %s\n' "$FIXTURE"
if [[ ! -d "$FIXTURE" ]]; then
    t_fail "T5 fixture missing: $FIXTURE (run test-fixtures/build.sh --name v10-realistic-ot --clean)"
else
    # ── T5.a: fixture-mode acceptance ──
    t5a_report="$(mktemp "${TMPDIR:-/tmp}/bd291-t5a-report.XXXXXX")"
    t5a_log="$(mktemp "${TMPDIR:-/tmp}/bd291-t5a-log.XXXXXX")"
    rc=0
    bash "$HARNESS" "$FIXTURE" --apply-sandbox --report-out "$t5a_report" \
        > "$t5a_log" 2>&1 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        t_pass "T5.a exit code = 0"
    else
        t_fail "T5.a exit code = $rc (expected 0); log: $t5a_log"
    fi
    if [[ "$(grep -c '	PASS	per-entry accounting: PASS' "$t5a_report" 2>/dev/null)" -eq 3 ]]; then
        t_pass "T5.a report: 3 per-stream accounting PASS verdicts"
    else
        t_fail "T5.a report: expected 3 accounting PASS verdicts; see $t5a_report"
    fi
    if grep -q '^set-equality: GREEN$' "$t5a_report" 2>/dev/null; then
        t_pass "T5.a report: validate-docs set-equality GREEN"
    else
        t_fail "T5.a report: set-equality not GREEN; see $t5a_report"
    fi
    t5a_declared="$(sed -n 's/^declared manual-fill rows: //p' "$t5a_report" 2>/dev/null | head -1)"
    t5a_measured="$(sed -n 's/^measured conformance rows: //p' "$t5a_report" 2>/dev/null | head -1)"
    if [[ -n "$t5a_declared" && "$t5a_declared" -gt 0 \
          && "$t5a_declared" -eq "${t5a_measured:-0}" ]]; then
        t_pass "T5.a declared == measured, nonzero ($t5a_declared)"
    else
        t_fail "T5.a declared/measured mismatch or zero (declared=$t5a_declared measured=$t5a_measured); see $t5a_report"
    fi
    rm -f "$t5a_report" "$t5a_log"

    # ── T5.b (m4): mutated recorded-synthesis line → both-direction (b) bite ──
    t5b_hook="$(mktemp "${TMPDIR:-/tmp}/bd291-t5b-hook.XXXXXX")"
    cat > "$t5b_hook" <<'HOOK'
#!/usr/bin/env bash
set -u
clone="$1"
f="$clone/docs/project/backlog/TD-101.md"
sed -i.bak 's/^- \*\*Entry-Type\*\*: td$/- **Entry-Type**: td-mutated/' "$f"
rm -f "$f.bak"
HOOK
    chmod +x "$t5b_hook"
    t5b_report="$(mktemp "${TMPDIR:-/tmp}/bd291-t5b-report.XXXXXX")"
    t5b_log="$(mktemp "${TMPDIR:-/tmp}/bd291-t5b-log.XXXXXX")"
    rc=0
    DRY_APPLY_SANDBOX_POST_HOOK="$t5b_hook" \
        bash "$HARNESS" "$FIXTURE" --apply-sandbox --report-out "$t5b_report" \
        > "$t5b_log" 2>&1 || rc=$?
    if [[ "$rc" -eq 8 ]]; then
        t_pass "T5.b exit code = 8 (DRY_EXIT_SANDBOX_VERIFY)"
    else
        t_fail "T5.b exit code = $rc (expected 8); log: $t5b_log"
    fi
    if grep -q 'RECORDED-BUT-ABSENT: TD-101.md' "$t5b_report" 2>/dev/null \
       && grep -q 'FABRICATED: TD-101.md' "$t5b_report" 2>/dev/null; then
        t_pass "T5.b RECORDED-BUT-ABSENT + FABRICATED both named (both-direction bite)"
    else
        t_fail "T5.b both-direction accounting failure not named; see $t5b_report"
    fi
    rm -f "$t5b_hook" "$t5b_report" "$t5b_log"

    # ── T5.c (m5): UNDECLARED + UNDELIVERED → both-direction (d) bite ──
    t5c_hook="$(mktemp "${TMPDIR:-/tmp}/bd291-t5c-hook.XXXXXX")"
    cat > "$t5c_hook" <<'HOOK'
#!/usr/bin/env bash
set -u
clone="$1"
# UNDECLARED: remove a Context: line (a validator failure TRIAGE did not
# declare). UNDELIVERED: satisfy a declared manual-fill item (valid
# Status: on phase-1) so its declared row has no measured failure.
f="$clone/docs/project/backlog/TD-102.md"
sed -i.bak '/^Context:/d' "$f"
rm -f "$f.bak"
printf 'Status: not-started\n' >> "$clone/docs/project/implementation-plan/phase-1.md"
HOOK
    chmod +x "$t5c_hook"
    t5c_report="$(mktemp "${TMPDIR:-/tmp}/bd291-t5c-report.XXXXXX")"
    t5c_log="$(mktemp "${TMPDIR:-/tmp}/bd291-t5c-log.XXXXXX")"
    rc=0
    DRY_APPLY_SANDBOX_POST_HOOK="$t5c_hook" \
        bash "$HARNESS" "$FIXTURE" --apply-sandbox --report-out "$t5c_report" \
        > "$t5c_log" 2>&1 || rc=$?
    if [[ "$rc" -eq 8 ]]; then
        t_pass "T5.c exit code = 8 (DRY_EXIT_SANDBOX_VERIFY)"
    else
        t_fail "T5.c exit code = $rc (expected 8); log: $t5c_log"
    fi
    if grep -q '^set-equality: RED$' "$t5c_report" 2>/dev/null \
       && grep -q 'UNDECLARED: backlog/TD-102.md' "$t5c_report" 2>/dev/null \
       && grep -q 'UNDELIVERED: implementation-plan/phase-1.md	missing-status' "$t5c_report" 2>/dev/null; then
        t_pass "T5.c delta names UNDECLARED + UNDELIVERED members (both-direction bite)"
    else
        t_fail "T5.c asymmetric members not named in delta; see $t5c_report"
    fi
    rm -f "$t5c_hook" "$t5c_report" "$t5c_log"
fi

# ── Summary ────────────────────────────────────────────────────────────────

printf '\n=== Results: %d passed, %d failed ===\n' "$PASS_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
    exit 1
fi
exit 0
