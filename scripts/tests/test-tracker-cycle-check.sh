#!/usr/bin/env bash
# scripts/tests/test-tracker-cycle-check.sh — link-creation-time cycle
# detection coverage (BD-108; V3.3 §5.5 + IPLAN-ADDENDUM-4 §6.Q).
#
# Coverage groups:
#   1. K-value resolver
#       1.1 default K = 10 when no tracker.toml present
#       1.2 reads [graph] cycle_check_k from tracker.toml
#       1.3 falls back to default on missing/malformed value
#   2. Cycle detection — happy paths
#       2.1 empty store → safe
#       2.2 single forward edge, no reverse → safe
#       2.3 unrelated edges in store → safe
#   3. Cycle detection — refusal paths
#       3.1 self-loop refused immediately (1-cycle)
#       3.2 2-cycle: A→B exists, propose B→A → refused
#       3.3 3-cycle: A→B→C exists, propose C→A → refused
#   4. K-boundary behavior (per BD-108 IMPLEMENTATION-REPORT call-out 3)
#       4.1 K-cycle at exactly K=10: chain length 10, propose closing → refused
#       4.2 K+1 chain at default K=10 returns SAFE
#           (cycle is OUT OF SCOPE of detection at default K; documented
#           per V3.3 §5.5 — bounded-search semantic)
#       4.3 K override (K=20) catches the K+1 cycle from 4.2
#   5. Failure modes (V3.3 §5.6 / V1 §9 typed-error contract)
#       5.1 missing required arg → typed validation error
#       5.2 malformed JSON store → typed schema-reshape error;
#           refusal is fail-closed (rc=1)
#       5.3 typed-error block names `pack tracker doctor`
#
# Usage: bash scripts/tests/test-tracker-cycle-check.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
# Cycle-check tests build small graph stores at runtime — these are
# not committed reference fixtures, so we write them to a per-run
# scratch dir instead of $REPO_ROOT/scripts/tests/fixtures/...
# (which is reserved for committed reference content).
FIXTURES=$(mktemp -d -t tcc-fix.XXXXXX)
trap 'rm -rf "$FIXTURES"' EXIT

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

# Source the libs.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-cycle-check.sh"
# BATCH-17 F10: Group 6 below tests caller-side fail-closed semantics
# at the tracker_links_create_blocked_by orchestrator (rc=2 → rc=1
# coercion). Source the orchestrator + a stub provider for the
# orchestrator's provider_link call.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-links.sh"
# Stub provider_link so the orchestrator's step 4 does not actually
# hit a backend during this offline test (we only need to verify
# that cycle-check rc=2 still surfaces as orchestrator rc=1 —
# i.e. the link is refused before provider_link is called).
provider_link() { return 0; }

# Helper: write a store JSON file from a list of "src,tgt" pairs.
write_store() {
    local path="$1"
    shift
    local edges="["
    local first=1
    for pair in "$@"; do
        local src="${pair%%,*}"
        local tgt="${pair##*,}"
        if [[ $first -eq 1 ]]; then
            first=0
        else
            edges+=","
        fi
        edges+='{"source":"'"$src"'","target":"'"$tgt"'","kind":"blocked-by"}'
    done
    edges+="]"
    printf '{"edges":%s}\n' "$edges" > "$path"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: K-value resolver
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: K-value resolver ===\n"

# 1.1 default K when no tracker.toml present
empty_dir=$(mktemp -d -t tcc-empty.XXXXXX)
k=$(tracker_cycle_check_get_k "$empty_dir")
assert_eq "1.1 default K = 10 when no tracker.toml" "10" "$k"
rm -rf "$empty_dir"

# 1.2 reads [graph] cycle_check_k from tracker.toml
cfg_dir=$(mktemp -d -t tcc-cfg.XXXXXX)
cat > "$cfg_dir/tracker.toml" <<'EOF'
schema_version = 1

[backend]
name = "stub"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"

[graph]
cycle_check_k = 25
EOF
k=$(tracker_cycle_check_get_k "$cfg_dir")
assert_eq "1.2 reads tracker.toml [graph] cycle_check_k = 25" "25" "$k"

# 1.3 fallback to default on absent key
cat > "$cfg_dir/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "stub"
repo = "fixture-org/fixture-repo"
EOF
k=$(tracker_cycle_check_get_k "$cfg_dir")
assert_eq "1.3 fallback to default 10 when [graph] absent" "10" "$k"

rm -rf "$cfg_dir"

# ─────────────────────────────────────────────────────────────────
# Group 2: cycle detection — happy paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: cycle detection — happy paths ===\n"

# 2.1 empty store → safe
store="$FIXTURES/store-empty.json"
write_store "$store"
if tracker_cycle_check_would_form_cycle "TD-031" "phase-3.2" "$store" 10; then
    t_pass "2.1 empty store → safe (rc=0)"
else
    t_fail "2.1 empty store → safe (rc=0)" "expected rc=0"
fi

# 2.2 single forward edge — no reverse cycle path
store="$FIXTURES/store-single.json"
write_store "$store" "TD-031,TD-029"
if tracker_cycle_check_would_form_cycle "phase-3.2" "phase-3.1" "$store" 10; then
    t_pass "2.2 unrelated forward edge → safe"
else
    t_fail "2.2 unrelated forward edge → safe" "expected rc=0"
fi

# 2.3 unrelated edges
store="$FIXTURES/store-unrelated.json"
write_store "$store" "TD-031,TD-029" "BD-110,BD-108" "phase-3.1,phase-3.2"
if tracker_cycle_check_would_form_cycle "TD-040" "phase-7.1" "$store" 10; then
    t_pass "2.3 unrelated edges in store → safe"
else
    t_fail "2.3 unrelated edges in store → safe" "expected rc=0"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: cycle detection — refusal paths
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: cycle detection — refusal paths ===\n"

# 3.1 self-loop refused immediately (1-cycle)
store="$FIXTURES/store-empty.json"
write_store "$store"
if tracker_cycle_check_would_form_cycle "TD-031" "TD-031" "$store" 10 2>/dev/null; then
    t_fail "3.1 self-loop refused (1-cycle)" "expected rc=1; got rc=0"
else
    t_pass "3.1 self-loop refused (1-cycle)"
fi

# 3.2 2-cycle: A→B exists, propose B→A → refused
store="$FIXTURES/store-2cycle.json"
write_store "$store" "TD-031,phase-3.2"
# Existing: TD-031 blocked-by phase-3.2.
# Proposed: phase-3.2 blocked-by TD-031.
# Walking from TD-031 (the proposed target) we find phase-3.2 in 1 hop —
# but the proposed source is phase-3.2, so cycle is detected.
if tracker_cycle_check_would_form_cycle "phase-3.2" "TD-031" "$store" 10 2>/dev/null; then
    t_fail "3.2 2-cycle: A→B exists, propose B→A → refused" "expected rc=1; got rc=0"
else
    t_pass "3.2 2-cycle: A→B exists, propose B→A → refused"
fi

# 3.3 3-cycle: A→B→C exists, propose C→A → refused
store="$FIXTURES/store-3cycle.json"
write_store "$store" "TD-031,TD-040" "TD-040,TD-029"
# Walking from TD-031 along blocked-by: TD-031 → TD-040 → TD-029 (2 hops).
# Propose TD-029 blocked-by TD-031 — walking from TD-031 reaches TD-029
# in 2 hops. Source = TD-029. Cycle detected.
if tracker_cycle_check_would_form_cycle "TD-029" "TD-031" "$store" 10 2>/dev/null; then
    t_fail "3.3 3-cycle: A→B→C exists, propose C→A → refused" "expected rc=1; got rc=0"
else
    t_pass "3.3 3-cycle: A→B→C exists, propose C→A → refused"
fi

# ─────────────────────────────────────────────────────────────────
# Group 4: K-boundary behavior
#
# Per BD-108 IMPLEMENTATION-REPORT call-out 3 (V3.3 §5.5 bounded-search
# semantic): cycle detection walks K hops from the proposed target.
# A cycle whose closure depth is ≤ K is detected; a cycle whose closure
# depth is > K is OUT OF SCOPE (not a bug). This group tests both
# boundaries and the `cycle_check_k` override.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: K-boundary behavior ===\n"

# Build a chain of length 10: A→B→C→D→E→F→G→H→I→J.
# Walking from A finds J at hop 9. Propose J→A: walk from A reaches J
# at hop 9 (within K=10) — detected.
store="$FIXTURES/store-chain10.json"
write_store "$store" \
    "TD-001,TD-002" "TD-002,TD-003" "TD-003,TD-004" "TD-004,TD-005" \
    "TD-005,TD-006" "TD-006,TD-007" "TD-007,TD-008" "TD-008,TD-009" \
    "TD-009,TD-010"
# Proposed: TD-010 blocked-by TD-001. From TD-001 walk forward —
# at hop 9 we find TD-010. Source=TD-010 ⇒ cycle detected.
if tracker_cycle_check_would_form_cycle "TD-010" "TD-001" "$store" 10 2>/dev/null; then
    t_fail "4.1 K-cycle at hop 9 (within K=10) → refused" "expected rc=1; got rc=0"
else
    t_pass "4.1 K-cycle at hop 9 (within K=10) → refused"
fi

# Build a chain of length 12: cycle would close at hop 11. K=10 ⇒
# OUT OF SCOPE (returns SAFE). This is documented bounded-search
# behavior per V3.3 §5.5, NOT a bug.
store="$FIXTURES/store-chain12.json"
write_store "$store" \
    "TD-001,TD-002" "TD-002,TD-003" "TD-003,TD-004" "TD-004,TD-005" \
    "TD-005,TD-006" "TD-006,TD-007" "TD-007,TD-008" "TD-008,TD-009" \
    "TD-009,TD-010" "TD-010,TD-011" "TD-011,TD-012"
# Proposed: TD-012 blocked-by TD-001. From TD-001 walk forward — at
# hop 11 we'd find TD-012, but K=10 stops at hop 10. Returns SAFE
# (rc=0). NOTE: this is the documented K-boundary behavior, not a
# bug. To detect this cycle, raise `tracker.toml [graph] cycle_check_k`.
if tracker_cycle_check_would_form_cycle "TD-012" "TD-001" "$store" 10 2>/dev/null; then
    t_pass "4.2 chain longer than K=10 returns SAFE (bounded-search; not a bug)"
else
    t_fail "4.2 chain longer than K=10 returns SAFE (bounded-search; not a bug)" \
        "expected rc=0; cycle is OUT OF SCOPE of K=10 search"
fi

# 4.3 K override (K=20) catches the K+1 cycle from 4.2
if tracker_cycle_check_would_form_cycle "TD-012" "TD-001" "$store" 20 2>/dev/null; then
    t_fail "4.3 K=20 override catches the longer cycle" "expected rc=1; got rc=0"
else
    t_pass "4.3 K=20 override catches the longer cycle (K override works)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 5: failure modes
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: failure modes ===\n"

# 5.1 missing required arg → typed validation error
err=$(tracker_cycle_check_would_form_cycle "" "phase-3.2" "$FIXTURES/store-empty.json" 2>&1) || true
assert_contains "5.1 missing src → typed validation error" "$err" "ERROR: validation"

err=$(tracker_cycle_check_would_form_cycle "phase-3.1" "" "$FIXTURES/store-empty.json" 2>&1) || true
assert_contains "5.1 missing tgt → typed validation error" "$err" "ERROR: validation"

err=$(tracker_cycle_check_would_form_cycle "phase-3.1" "phase-3.2" "" 2>&1) || true
assert_contains "5.1 missing store_path → typed validation error" "$err" "ERROR: validation"

# 5.2 malformed JSON store → typed schema-reshape error; rc=1 (fail-closed)
malformed="$FIXTURES/store-malformed.json"
printf 'not valid JSON' > "$malformed"
err=$(tracker_cycle_check_would_form_cycle "phase-3.1" "phase-3.2" "$malformed" 10 2>&1) || true
assert_contains "5.2 malformed store → typed schema-reshape error" "$err" "ERROR: schema-reshape"

if tracker_cycle_check_would_form_cycle "phase-3.1" "phase-3.2" "$malformed" 10 2>/dev/null; then
    t_fail "5.2 malformed store → fail-closed (rc=1)" "expected rc=1; got rc=0"
else
    t_pass "5.2 malformed store → fail-closed (rc=1)"
fi

# 5.3 typed-error block names `pack tracker doctor` (V3.3 §5.6 verb naming)
store="$FIXTURES/store-2cycle.json"
write_store "$store" "TD-031,phase-3.2"
err=$(tracker_cycle_check_would_form_cycle "phase-3.2" "TD-031" "$store" 10 2>&1) || true
assert_contains "5.3 cycle error names 'pack tracker doctor' verb" "$err" "pack tracker doctor"

# 5.4 BD-204 C-8 defect 2: the refusal names the FULL cycle path (both
# IDs + every intermediate hop), not just the cycle length — the bare
# length message left the live BD-094/BD-095 mutual-block failure
# unactionable. 2-cycle: src -> tgt -> src.
assert_contains "5.4 2-cycle refusal names the cycle path (BD-204 C-8)" \
    "$err" "cycle path: phase-3.2 -> TD-031 -> phase-3.2"
# 3-cycle: the intermediate hop appears in the path.
store_p3="$FIXTURES/store-3cycle-path.json"
write_store "$store_p3" "TD-031,TD-040" "TD-040,TD-029"
err=$(tracker_cycle_check_would_form_cycle "TD-029" "TD-031" "$store_p3" 10 2>&1) || true
assert_contains "5.4 3-cycle refusal names the full path incl. intermediate hop" \
    "$err" "cycle path: TD-029 -> TD-031 -> TD-040 -> TD-029"

# Also verify the schema-reshape path names the same verb.
err=$(tracker_cycle_check_would_form_cycle "phase-3.1" "phase-3.2" "$malformed" 10 2>&1) || true
assert_contains "5.3 schema-reshape error names 'pack tracker doctor' verb" "$err" "pack tracker doctor"

# Self-loop's typed error names `pack tracker doctor` (V3.3 §5.6
# cycle-class failure verb) — same verb as the BFS cycle path so the
# two cycle-refusal sites stay consistent for the same class of
# failure. BD-108 review F2 fix.
err=$(tracker_cycle_check_would_form_cycle "TD-031" "TD-031" "$FIXTURES/store-empty.json" 10 2>&1) || true
assert_contains "5.3 self-loop emits typed error block" "$err" "ERROR: validation"
assert_contains "5.3 self-loop names a next-step verb" "$err" "→ Run:"
assert_contains "5.3 self-loop names 'pack tracker doctor' verb (BD-108 F2)" \
    "$err" "pack tracker doctor"

# ─────────────────────────────────────────────────────────────────
# Group 6: BATCH-17 F10 — rc=2 vs rc=1 disambiguation
#
# Per the cross-BD review: callers and tests CAN now distinguish
# "would-cycle" (python rc=2) from "traversal/schema error" (python
# rc=1) without parsing stderr text. The function bubbles up the
# python rc directly instead of collapsing to caller-visible rc=1.
# Both still fail-closed at the higher orchestrator level; the
# distinction is for diagnostic / test-harness use.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: F10 rc=2 vs rc=1 disambiguation ===\n"

# 6.1 cycle case → distinct rc=2.
store="$FIXTURES/store-2cycle.json"
write_store "$store" "TD-031,phase-3.2"
tracker_cycle_check_would_form_cycle "phase-3.2" "TD-031" "$store" 10 2>/dev/null
rc_cycle=$?
assert_eq "6.1 F10: cycle case bubbles python rc=2 (distinct from traversal error)" \
    "2" "$rc_cycle"

# 6.2 traversal/schema error case → distinct rc=1.
malformed="$FIXTURES/store-malformed-f10.json"
printf 'not valid JSON' > "$malformed"
tracker_cycle_check_would_form_cycle "phase-3.1" "phase-3.2" "$malformed" 10 2>/dev/null
rc_traversal=$?
assert_eq "6.2 F10: traversal/schema error bubbles python rc=1 (distinct from cycle)" \
    "1" "$rc_traversal"

# 6.3 safe case still returns rc=0.
store_safe="$FIXTURES/store-empty-f10.json"
printf '%s\n' '{"edges":[]}' > "$store_safe"
tracker_cycle_check_would_form_cycle "phase-3.2" "phase-3.1" "$store_safe" 10 2>/dev/null
rc_safe=$?
assert_eq "6.3 F10: safe case returns rc=0 (unchanged)" "0" "$rc_safe"

# 6.4 caller-side: tracker_links_create_blocked_by must still fail-closed
# on BOTH rc=1 AND rc=2 (the orchestrator uses `if !` to coerce non-zero
# to failure). The test checks the orchestrator's behavior is preserved.
# (Cycle case — rc=2 propagates.)
fixtures_id_map=$(jq -n '{
    "TD-031": {"id": "1031"},
    "phase-3.2": {"id": "3002"}
}')
if tracker_links_create_blocked_by "phase-3.2" "TD-031" "$fixtures_id_map" "$store" "" >/dev/null 2>&1; then
    t_fail "6.4 F10: orchestrator still fails-closed on cycle (rc=2 propagates as rc=1)" \
        "expected rc=1 from orchestrator; got rc=0"
else
    t_pass "6.4 F10: orchestrator still fails-closed on cycle (rc=2 → rc=1 at orchestrator)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
