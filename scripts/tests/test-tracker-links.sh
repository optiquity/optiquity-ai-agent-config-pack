#!/usr/bin/env bash
# scripts/tests/test-tracker-links.sh — uniform cross-entity dependency
# orchestration coverage (BD-108; V3.3 §5.1 / §5.2 / §5.5 / §5.6).
#
# Coverage groups:
#   1. Pair-type validation (V3.3 §5.1 — six entity-pair types)
#       1.1 phase-N + phase-N         (TD ↔ phase epic permutation)
#       1.2 phase-N.M + phase-N.M     (phase task ↔ phase task same/cross)
#       1.3 TD-NNN + TD-NNN
#       1.4 TD-NNN + BD-NNN
#       1.5 TD-NNN + phase-N
#       1.6 TD-NNN + phase-N.M
#       1.7 malformed shape rejected (typed validation error)
#   2. Link creation — happy paths (one per entity-pair type)
#       2.1 TD-NNN  blocked-by  phase-N
#       2.2 TD-NNN  blocked-by  phase-N.M
#       2.3 phase-N.M blocked-by phase-N.M (same phase)
#       2.4 phase-N.M blocked-by phase-N.M (cross phase)
#       2.5 TD-NNN  blocked-by  TD-NNN
#       2.6 TD-NNN  blocked-by  BD-NNN
#   3. Sidecar V3.3 §6.R compliance
#       3.1 cycle-graph store records the new edge after success
#       3.2 store_add is idempotent — re-creating the same edge is a no-op
#       3.3 annotation passes through the success JSON verbatim
#   4. Round-trip identity (V3.3 §5.3 byte-identity contract)
#       4.1 BACKLOG.md fixture with Blockers `phase-N.M`: SHA-256 stable
#           through tmf_parse_backlog → _tmr_emit_backlog
#       4.2 IMPLEMENTATION-PLAN fixture with Dependencies bullets:
#           SHA-256 stable through tracker_phase_task_parse → emit
#       4.3 phase-task Dependencies annotation preserved through round-trip
#   5. Failure modes (V3.3 §5.6 / V1 §9 typed-error contract)
#       5.1 missing source pack-id → typed validation error
#       5.2 missing target pack-id → typed validation error
#       5.3 source pack-id absent from id-map → typed not-found error
#       5.4 target pack-id absent from id-map → typed not-found error
#       5.5 cycle would form (2-cycle) → typed validation error
#                                        + names `pack tracker doctor`
#
# Usage: bash scripts/tests/test-tracker-links.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-links"
PROV_FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-provider"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

# Source the libs in dependency order (mirrors the pattern in
# test-tracker-phase-task.sh + tracker-provider-test.sh).
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-cycle-check.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-links.sh"
# Source the stub backend used by tracker-provider-test.sh; same shape.
# shellcheck disable=SC1091
source "$PROV_FIXTURES/stub-backend.sh"
# Route provider_link to the stub so we can exercise tracker-links
# end-to-end offline.
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub

ID_MAP=$(cat "$FIXTURES/id-map.json")

# Per-test scratch dir for cycle-graph stores (each test gets a fresh
# store so we don't carry state between assertions).
SCRATCH=$(mktemp -d -t tlk.XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

mk_store() {
    local name="$1"
    local p="$SCRATCH/$name.json"
    : > "$p"
    rm -f "$p"
    echo "$p"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: pair-type validation (V3.3 §5.1)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: pair-type validation (V3.3 §5.1) ===\n"

if tracker_links_validate_pair_type "phase-3"   "phase-7"   2>/dev/null; then t_pass "1.1 phase-N + phase-N"; else t_fail "1.1 phase-N + phase-N"; fi
if tracker_links_validate_pair_type "phase-3.1" "phase-3.2" 2>/dev/null; then t_pass "1.2 phase-N.M + phase-N.M same phase"; else t_fail "1.2 phase-N.M + phase-N.M same phase"; fi
if tracker_links_validate_pair_type "phase-3.4" "phase-7.1" 2>/dev/null; then t_pass "1.2 phase-N.M + phase-N.M cross phase"; else t_fail "1.2 phase-N.M + phase-N.M cross phase"; fi
if tracker_links_validate_pair_type "TD-029"    "TD-031"    2>/dev/null; then t_pass "1.3 TD-NNN + TD-NNN"; else t_fail "1.3 TD-NNN + TD-NNN"; fi
if tracker_links_validate_pair_type "TD-029"    "BD-108"    2>/dev/null; then t_pass "1.4 TD-NNN + BD-NNN"; else t_fail "1.4 TD-NNN + BD-NNN"; fi
if tracker_links_validate_pair_type "TD-031"    "phase-3"   2>/dev/null; then t_pass "1.5 TD-NNN + phase-N"; else t_fail "1.5 TD-NNN + phase-N"; fi
if tracker_links_validate_pair_type "TD-031"    "phase-3.2" 2>/dev/null; then t_pass "1.6 TD-NNN + phase-N.M"; else t_fail "1.6 TD-NNN + phase-N.M"; fi

# 1.7 malformed shape rejected
if tracker_links_validate_pair_type "TD-031"    "garbage"   2>/dev/null; then
    t_fail "1.7 malformed target rejected" "expected rc=1; got rc=0"
else
    t_pass "1.7 malformed target rejected"
fi
if tracker_links_validate_pair_type "phase-3.4.5" "TD-031"  2>/dev/null; then
    t_fail "1.7 phase-N.M.K rejected (3-component is not legal)" "expected rc=1; got rc=0"
else
    t_pass "1.7 phase-N.M.K rejected (3-component is not legal)"
fi
if tracker_links_validate_pair_type ""           "TD-031"  2>/dev/null; then
    t_fail "1.7 empty source rejected" "expected rc=1; got rc=0"
else
    t_pass "1.7 empty source rejected"
fi

err=$(tracker_links_validate_pair_type "TD-031" "garbage" 2>&1) || true
assert_contains "1.7 typed validation error block emitted" "$err" "ERROR: validation"
assert_contains "1.7 typed error mentions expected shapes"  "$err" "phase-N.M"

# ─────────────────────────────────────────────────────────────────
# Group 2: link creation — happy paths (one per V3.3 §5.1 pair type)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: link creation — happy paths ===\n"

# 2.1 TD ↔ phase epic
store=$(mk_store "g2-1")
out=$(tracker_links_create_blocked_by "TD-031" "phase-3" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.1 TD blocked-by phase-N kind"   "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "2.1 TD blocked-by phase-N source" "TD-031"     "$(printf '%s' "$out" | jq -r '.source_pack_id')"
assert_eq "2.1 TD blocked-by phase-N target" "phase-3"    "$(printf '%s' "$out" | jq -r '.target_pack_id')"

# 2.2 TD ↔ phase task
store=$(mk_store "g2-2")
out=$(tracker_links_create_blocked_by "TD-031" "phase-3.2" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.2 TD blocked-by phase-N.M target id" "3002" "$(printf '%s' "$out" | jq -r '.target_tracker_id')"

# 2.3 phase task ↔ phase task (same phase)
store=$(mk_store "g2-3")
out=$(tracker_links_create_blocked_by "phase-3.2" "phase-3.1" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.3 phase-N.M same-phase source id" "3002" "$(printf '%s' "$out" | jq -r '.source_tracker_id')"
assert_eq "2.3 phase-N.M same-phase target id" "3001" "$(printf '%s' "$out" | jq -r '.target_tracker_id')"

# 2.4 phase task ↔ phase task (cross phase)
store=$(mk_store "g2-4")
out=$(tracker_links_create_blocked_by "phase-7.1" "phase-3.4" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.4 phase-N.M cross-phase source id" "7001" "$(printf '%s' "$out" | jq -r '.source_tracker_id')"
assert_eq "2.4 phase-N.M cross-phase target id" "3004" "$(printf '%s' "$out" | jq -r '.target_tracker_id')"

# 2.5 TD ↔ TD (existing v10 case; unchanged)
store=$(mk_store "g2-5")
out=$(tracker_links_create_blocked_by "TD-031" "TD-029" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.5 TD blocked-by TD source id" "1031" "$(printf '%s' "$out" | jq -r '.source_tracker_id')"
assert_eq "2.5 TD blocked-by TD target id" "1029" "$(printf '%s' "$out" | jq -r '.target_tracker_id')"

# 2.6 TD ↔ BD (cross-namespace)
store=$(mk_store "g2-6")
out=$(tracker_links_create_blocked_by "TD-031" "BD-108" "$ID_MAP" "$store" "" 2>&1)
assert_eq "2.6 TD blocked-by BD target id" "2108" "$(printf '%s' "$out" | jq -r '.target_tracker_id')"

# ─────────────────────────────────────────────────────────────────
# Group 3: sidecar V3.3 §6.R compliance
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: cycle-graph store + V3.3 §6.R compliance ===\n"

# 3.1 cycle-graph store records the new edge after success
store=$(mk_store "g3-1")
tracker_links_create_blocked_by "TD-031" "phase-3.2" "$ID_MAP" "$store" "" >/dev/null 2>&1
edges=$(jq -c '.edges' "$store")
assert_contains "3.1 store edge: source=TD-031"   "$edges" '"source":"TD-031"'
assert_contains "3.1 store edge: target=phase-3.2" "$edges" '"target":"phase-3.2"'
assert_contains "3.1 store edge: kind=blocked-by"  "$edges" '"kind":"blocked-by"'

# 3.2 store_add is idempotent
tracker_links_create_blocked_by "TD-031" "phase-3.2" "$ID_MAP" "$store" "" >/dev/null 2>&1
edge_count=$(jq '.edges | length' "$store")
assert_eq "3.2 idempotent store_add (still 1 edge)" "1" "$edge_count"

# 3.3 annotation passes through verbatim (V3.3 §5.3 / §6.R)
store=$(mk_store "g3-3")
out=$(tracker_links_create_blocked_by "phase-3.1" "phase-3.2" "$ID_MAP" "$store" \
    "(must complete schema first)" 2>&1)
assert_eq "3.3 annotation captured in success JSON" \
    "(must complete schema first)" "$(printf '%s' "$out" | jq -r '.annotation')"

# Empty annotation → empty string in success JSON
store=$(mk_store "g3-3b")
out=$(tracker_links_create_blocked_by "phase-3.1" "phase-3.2" "$ID_MAP" "$store" "" 2>&1)
assert_eq "3.3 empty annotation → empty string" "" "$(printf '%s' "$out" | jq -r '.annotation')"

# ─────────────────────────────────────────────────────────────────
# Group 4: round-trip identity (V3.3 §5.3 byte-identity)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: round-trip identity (V3.3 §5.3) ===\n"

# Source the migration libs lazily for the round-trip check (they
# pull a lot of helpers we don't need elsewhere in this file).
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-header-snapshot.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-phase-task.sh"

# 4.1 BACKLOG fixture round-trip — Blockers `phase-N.M, TD-029`.
# Forward parse → reverse emit produces byte-identical text.
src1="$FIXTURES/BACKLOG-phase-task-blockers.md"
parsed1=$(tmf_parse_backlog "$src1")
out1=$(mktemp -t tlk-backlog-rt.XXXXXX)
_tmr_emit_backlog "$parsed1" "fixture-org/fixture-repo" "$out1"
src1_sha=$(shasum -a 256 "$src1"  | awk '{print $1}')
out1_sha=$(shasum -a 256 "$out1"  | awk '{print $1}')
assert_eq "4.1 BACKLOG round-trip SHA-256 identical" "$src1_sha" "$out1_sha"
# Also check the parsed Blockers list contains phase-3.2.
parsed1_blockers=$(printf '%s' "$parsed1" | jq -c '.[0].blockers')
assert_eq "4.1 parsed Blockers list" '["phase-3.2","TD-029"]' "$parsed1_blockers"
rm -f "$out1"

# 4.2 IMPLEMENTATION-PLAN fixture round-trip — Dependencies bullets.
# Parse → emit produces byte-identical text.
src2="$FIXTURES/IMPLEMENTATION-PLAN-deps.md"
parsed2=$(tracker_phase_task_parse "$src2" 2>/dev/null)
emitted2=$(tracker_phase_task_emit "$parsed2")
out2=$(mktemp -t tlk-plan-rt.XXXXXX)
printf '%s\n' "$emitted2" > "$out2"
src2_sha=$(shasum -a 256 "$src2" | awk '{print $1}')
out2_sha=$(shasum -a 256 "$out2" | awk '{print $1}')
assert_eq "4.2 IMPLEMENTATION-PLAN round-trip SHA-256 identical" "$src2_sha" "$out2_sha"
rm -f "$out2"

# 4.3 annotation preserved through round-trip
deps_target=$(printf '%s' "$parsed2" | jq -r '.phases[0].tasks[0].dependencies[0].target')
deps_ann=$(printf    '%s' "$parsed2" | jq -r '.phases[0].tasks[0].dependencies[0].annotation')
assert_eq "4.3 phase-task dep[0].target" "phase-3.2" "$deps_target"
assert_eq "4.3 phase-task dep[0].annotation preserved" \
    "(must complete migration scaffold first)" "$deps_ann"

# ─────────────────────────────────────────────────────────────────
# Group 5: failure modes (V3.3 §5.6 / V1 §9)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: failure modes (V3.3 §5.6 / V1 §9) ===\n"

# 5.1 missing source
store=$(mk_store "g5-1")
err=$(tracker_links_create_blocked_by "" "phase-3.2" "$ID_MAP" "$store" 2>&1) || true
assert_contains "5.1 missing source → typed validation error" "$err" "ERROR: validation"

# 5.2 missing target
err=$(tracker_links_create_blocked_by "TD-031" "" "$ID_MAP" "$store" 2>&1) || true
assert_contains "5.2 missing target → typed validation error" "$err" "ERROR: validation"

# 5.3 source absent from id-map
err=$(tracker_links_create_blocked_by "TD-999" "phase-3.2" "$ID_MAP" "$store" 2>&1) || true
assert_contains "5.3 source absent from id-map → typed not-found" "$err" "ERROR: not-found"
assert_contains "5.3 not-found error names forward-migration verb" "$err" "pack tracker forward"

# 5.4 target absent from id-map
err=$(tracker_links_create_blocked_by "TD-031" "phase-9.9" "$ID_MAP" "$store" 2>&1) || true
assert_contains "5.4 target absent from id-map → typed not-found" "$err" "ERROR: not-found"

# 5.5 cycle would form (2-cycle) → typed validation error + names verb
store=$(mk_store "g5-5")
# Seed: TD-031 blocked-by phase-3.2.
tracker_links_create_blocked_by "TD-031" "phase-3.2" "$ID_MAP" "$store" "" >/dev/null 2>&1
# Propose: phase-3.2 blocked-by TD-031 → cycle.
err=$(tracker_links_create_blocked_by "phase-3.2" "TD-031" "$ID_MAP" "$store" "" 2>&1) || true
assert_contains "5.5 cycle refused with typed validation error" "$err" "ERROR: validation"
assert_contains "5.5 cycle error names 'pack tracker doctor' verb" "$err" "pack tracker doctor"

# Confirm rc=1 on cycle refusal
if tracker_links_create_blocked_by "phase-3.2" "TD-031" "$ID_MAP" "$store" "" >/dev/null 2>&1; then
    t_fail "5.5 cycle refusal rc=1" "expected rc=1; got rc=0"
else
    t_pass "5.5 cycle refusal rc=1"
fi

# Verify NO new edge persisted on cycle refusal (the store should
# still have 1 edge: the seed edge from above).
edges_after=$(jq '.edges | length' "$store")
assert_eq "5.5 cycle refusal does not persist edge" "1" "$edges_after"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
