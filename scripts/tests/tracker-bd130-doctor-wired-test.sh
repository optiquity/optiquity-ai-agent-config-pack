#!/usr/bin/env bash
# scripts/tests/tracker-bd130-doctor-wired-test.sh — BD-130 wiring
# regression guard.
#
# BD-067 wired the `doctor` verb in scripts/pack-tracker.sh but did
# NOT source the lib that defines `tracker_doctor_run`. Empirically:
#
#     $ bash scripts/pack-tracker.sh doctor
#     scripts/pack-tracker.sh: line 165: tracker_doctor_run: \
#         command not found
#
# BD-130 fix: extracted the function body to
# scripts/lib/tracker-doctor.sh and added it to the source list of
# both scripts/pack-tracker.sh and scripts/tracker-migrate.sh.
#
# This test asserts:
#   1. `pack-tracker.sh doctor` against a scratch dir DOES NOT emit
#      "command not found".
#   2. `tracker-migrate.sh doctor` (legacy entry) ALSO does not.
#   3. The doctor output starts with the doctor-emitted banner
#      ("doctor: <repo>") rather than a shell error.
#   4. `scripts/lib/tracker-doctor.sh` exists and defines
#      `tracker_doctor_run` (so future refactors can't silently
#      remove the relocation).
#
# Usage: bash scripts/tests/tracker-bd130-doctor-wired-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACK_TRACKER="$REPO_ROOT/scripts/pack-tracker.sh"
TRACKER_MIGRATE="$REPO_ROOT/scripts/tracker-migrate.sh"
DOCTOR_LIB="$REPO_ROOT/scripts/lib/tracker-doctor.sh"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  pass: %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  FAIL: %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "        %s\n" "$2"
}

assert_no_match() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        t_fail "$label" "unexpected substring '$needle' in output"
    else
        t_pass "$label"
    fi
}

assert_match() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        t_pass "$label"
    else
        t_fail "$label" "expected substring '$needle' missing from output"
    fi
}

# Scratch dir — empty, so doctor will emit warnings but should NOT
# emit "command not found" or any shell error before the banner.
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "=== Group 1: scripts/lib/tracker-doctor.sh exists ==="
if [[ -f "$DOCTOR_LIB" ]]; then
    t_pass "1.1 lib file present at scripts/lib/tracker-doctor.sh"
else
    t_fail "1.1 lib file missing at $DOCTOR_LIB"
fi

if grep -q '^tracker_doctor_run()' "$DOCTOR_LIB" 2>/dev/null; then
    t_pass "1.2 lib defines tracker_doctor_run()"
else
    t_fail "1.2 lib does not define tracker_doctor_run()"
fi

echo "=== Group 2: pack-tracker.sh doctor wires the function ==="
out_pack=$(bash "$PACK_TRACKER" doctor --repo-root "$SCRATCH" 2>&1)
rc_pack=$?
assert_no_match "2.1 no 'command not found' in pack-tracker.sh doctor output" \
    "command not found" "$out_pack"
assert_match "2.2 pack-tracker.sh doctor emits 'doctor:' banner" \
    "doctor: $SCRATCH" "$out_pack"
# rc may be 0 or 1 depending on warnings; we only require that the
# doctor body executed (banner present, no shell error).

echo "=== Group 3: tracker-migrate.sh doctor wires the function ==="
out_migrate=$(bash "$TRACKER_MIGRATE" doctor --repo-root "$SCRATCH" 2>&1)
rc_migrate=$?
assert_no_match "3.1 no 'command not found' in tracker-migrate.sh doctor output" \
    "command not found" "$out_migrate"
assert_match "3.2 tracker-migrate.sh doctor emits 'doctor:' banner" \
    "doctor: $SCRATCH" "$out_migrate"

echo "=== Group 4: both dispatchers source tracker-doctor.sh ==="
if grep -q 'source "\$LIB_DIR/tracker-doctor.sh"' "$PACK_TRACKER"; then
    t_pass "4.1 pack-tracker.sh sources lib/tracker-doctor.sh"
else
    t_fail "4.1 pack-tracker.sh does NOT source lib/tracker-doctor.sh"
fi
if grep -q 'source "\$LIB_DIR/tracker-doctor.sh"' "$TRACKER_MIGRATE"; then
    t_pass "4.2 tracker-migrate.sh sources lib/tracker-doctor.sh"
else
    t_fail "4.2 tracker-migrate.sh does NOT source lib/tracker-doctor.sh"
fi

echo
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
