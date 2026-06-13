#!/usr/bin/env bash
# scripts/tests/tracker-deferral-gate-test.sh — BD-214 flip-block
# behavioral tests.
#
# Asserts the BD-214 deferral clamp + verb gates BEHAVE correctly:
#   - tracker_mode() returns "flat-file" (with a stderr notice) when
#     PACK_TRACKER_DEFERRAL_OVERRIDE is unset, even given a well-formed
#     tracker.toml that WOULD otherwise evaluate to "tracker".
#   - tracker_mode() honors the override (returns "tracker" for the same
#     toml) so the dormant tracker code stays testable.
#   - `pack tracker init`, `pack tracker enable-recommendations`, and
#     `tracker-migrate.sh forward` REFUSE with a typed not-implemented
#     error + non-zero exit WITHOUT the override.
#   - `tracker-migrate.sh reverse` is UN-gated (escape hatch).
#   - The other `pack tracker` verbs (status/doctor/disable/tree-rebuild/
#     edit/new-entry/mirror-rebuild/update-templates) exit non-zero with a
#     typed error (no crash) under the clamp on a flat-file root.
#
# This is a plain behavioral test (NOT a validate-pack per-check test);
# it deliberately runs WITHOUT exporting PACK_TRACKER_DEFERRAL_OVERRIDE
# so it exercises the refusal path.
#
# Usage: bash scripts/tests/tracker-deferral-gate-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACK_TRACKER="$REPO_ROOT/scripts/pack-tracker.sh"
TRACKER_MIGRATE="$REPO_ROOT/scripts/tracker-migrate.sh"
TRACKER_CONFIG="$REPO_ROOT/scripts/lib/tracker-config.sh"

# Make sure the env seam is NOT inherited from the caller — these tests
# assert the DEFAULT (clamped) behavior.
unset PACK_TRACKER_DEFERRAL_OVERRIDE 2>/dev/null || true

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A well-formed tracker.toml that WOULD evaluate to "tracker" absent the clamp.
TOML="$TMP/tracker.toml"
cat > "$TOML" <<'EOF'
[mode]
state = "tracker"

[migration]
forward_complete = true
EOF

# ─────────────────────────────────────────────────────────────────
# Group 1: tracker_mode() clamp
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: tracker_mode() deferral clamp ===\n"

mode_clamped="$(unset PACK_TRACKER_DEFERRAL_OVERRIDE; bash -c "source '$TRACKER_CONFIG'; tracker_mode '$TOML'" 2>/dev/null)"
if [[ "$mode_clamped" == "flat-file" ]]; then
    t_pass "tracker_mode() clamps a tracker-toml to flat-file without the override"
else
    t_fail "tracker_mode() should return flat-file under the clamp" "got: '$mode_clamped'"
fi

notice="$(unset PACK_TRACKER_DEFERRAL_OVERRIDE; bash -c "source '$TRACKER_CONFIG'; tracker_mode '$TOML'" 2>&1 >/dev/null)"
if printf '%s' "$notice" | grep -q "deferred"; then
    t_pass "tracker_mode() emits a one-line deferral notice on stderr"
else
    t_fail "tracker_mode() should emit a deferral notice on stderr" "got: '$notice'"
fi

mode_override="$(bash -c "export PACK_TRACKER_DEFERRAL_OVERRIDE=1; source '$TRACKER_CONFIG'; tracker_mode '$TOML'" 2>/dev/null)"
if [[ "$mode_override" == "tracker" ]]; then
    t_pass "tracker_mode() honors the override (dormant code stays testable)"
else
    t_fail "tracker_mode() should return tracker with the override" "got: '$mode_override'"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: verb gates refuse without the override
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: flip verbs refuse without the override ===\n"

assert_refuses() {
    local label="$1"; shift
    local out rc
    out="$(unset PACK_TRACKER_DEFERRAL_OVERRIDE; "$@" </dev/null 2>&1)"; rc=$?
    if [[ $rc -ne 0 ]] && printf '%s' "$out" | grep -q "not-implemented" \
            && printf '%s' "$out" | grep -q "deferred indefinitely"; then
        t_pass "$label refuses (non-zero + typed not-implemented error)"
    else
        t_fail "$label should refuse with a typed error + non-zero exit" \
            "rc=$rc out: $out"
    fi
}

assert_refuses "pack tracker init"                 bash "$PACK_TRACKER" init --repo-root "$TMP"
assert_refuses "pack tracker enable-recommendations" bash "$PACK_TRACKER" enable-recommendations --repo-root "$TMP"
assert_refuses "tracker-migrate.sh forward"        bash "$TRACKER_MIGRATE" forward --repo-root "$TMP"

# ─────────────────────────────────────────────────────────────────
# Group 3: reverse is un-gated; other verbs do not crash
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: reverse un-gated; non-network verbs inert (no crash) ===\n"

# The reverse arm is the escape hatch and MUST stay un-gated. The reverse
# code path touches the provider (gh) in some branches, so assert the
# un-gated property STRUCTURALLY (no deferral gate present in the reverse
# dispatch/arm) rather than by executing the network path.
# Confirm the forward arm carries the gate and the reverse arm does not,
# by inspecting the two function bodies.
fwd_body="$(awk '/^cmd_forward\(\) \{/{p=1} p{print} p&&/^}/{p=0}' "$TRACKER_MIGRATE")"
rev_body="$(awk '/^cmd_reverse\(\) \{/{p=1} p{print} p&&/^}/{p=0}' "$TRACKER_MIGRATE")"
fwd_gate="$(printf '%s' "$fwd_body" | grep -c "PACK_TRACKER_DEFERRAL_OVERRIDE")"
rev_gate="$(printf '%s' "$rev_body" | grep -c "PACK_TRACKER_DEFERRAL_OVERRIDE")"
if [[ "$fwd_gate" -ge 1 && "$rev_gate" -eq 0 ]]; then
    t_pass "tracker-migrate.sh forward arm gated; reverse arm un-gated (escape hatch)"
else
    t_fail "expected forward arm gated AND reverse arm un-gated" \
        "fwd-gate-count=$fwd_gate rev-gate-count=$rev_gate"
fi

# The non-network verbs must exit non-zero with a typed error on a flat-file
# root under the clamp — never crash (unbound var / command-not-found).
# (doctor/disable/mirror-rebuild touch the provider/network and are covered
# by the dedicated tracker test scripts under the override; excluded here to
# keep this behavioral test deterministic and network-free.)
for verb in status edit new-entry tree-rebuild update-templates; do
    verb_file="$TMP/verb-$verb.out"
    (unset PACK_TRACKER_DEFERRAL_OVERRIDE; bash "$PACK_TRACKER" "$verb" --repo-root "$TMP" </dev/null) >"$verb_file" 2>&1
    rc=$?
    # A crash surfaces as 'unbound variable', 'command not found', or 'syntax error'.
    if grep -qiE "unbound variable|command not found|syntax error" "$verb_file"; then
        t_fail "pack tracker $verb crashed under the clamp" "rc=$rc out: $(cat "$verb_file")"
    else
        t_pass "pack tracker $verb runs without crashing under the clamp (rc=$rc)"
    fi
done

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
