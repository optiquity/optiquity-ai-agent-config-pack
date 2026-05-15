#!/usr/bin/env bash
# scripts/tests/test-tracker-phase-task.sh — phase-task entity model
# offline test suite (BD-106).
#
# Coverage groups:
#   1. Identifier + grammar helpers
#       1.1 tracker_phase_task_compose_pack_id round-trip
#       1.2 tracker_phase_task_dependency_re shape
#   2. Parser correctness — fixture parses to expected JSON
#       2.1 phase / task counts
#       2.2 sparse phase ([] tasks)
#       2.3 dependency entries: kind/target/annotation captured
#       2.4 cross-phase dependency captured (phase-7.1 → phase-3.4)
#       2.5 TD reference inside Dependencies bullet captured
#       2.6 missing-file → typed error
#   3. Emitter correctness — round-trip identity
#       3.1 parse → emit → diff = empty against ROUNDTRIP.md fixture
#       3.2 emitter produces deterministic output for same input
#   4. Sidecar phase_tasks block (V3.3 §4.3)
#       4.1 block contains phase_tasks: header
#       4.2 per-task dependency_edges with kind/target/annotation
#       4.3 sparse-phase emits empty tasks: {}
#       4.4 template_version = phase-task-v11.0 per V3.3 §6.5
#   5. Label family helpers (V3.3 §3.5)
#       5.1 tracker_labels_derived_from happy path
#       5.2 tracker_labels_derived_from rejects BD-NNN
#       5.3 tracker_labels_promoted_to phase-N happy path
#       5.4 tracker_labels_promoted_to phase-N.M happy path
#       5.5 tracker_labels_promoted_to rejects malformed input
#       5.6 NO tracker_labels_folded_into helper exists (Path 3 forbidden)
#   6. id-map handling (V3.2 §4.1 step 5e + V3.3 §4.1)
#       6.1 set + get phase task id like a normal entry
#       6.2 set_phase_task_order writes additive task_order field
#       6.3 get_phase_task_order returns the array
#       6.4 reverse-side _tmr_phase_task_order: explicit task_order honored
#       6.5 reverse-side fallback: ascending numeric scan when unset
#       6.6 mapping JSON round-trips through save+load with task_order
#
# Usage: bash scripts/tests/test-tracker-phase-task.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-phase-task"

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

assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' unexpectedly present in: ${2:0:200}"; fi
}

# Source the libs the same way tracker-migrate.sh does.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-phase-task.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: identifier + grammar helpers
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: identifier + grammar helpers ===\n"

assert_eq "1.1 compose phase-3.2"   "phase-3.2"  "$(tracker_phase_task_compose_pack_id 3 2)"
assert_eq "1.1 compose phase-12.7"  "phase-12.7" "$(tracker_phase_task_compose_pack_id 12 7)"

dep_re=$(tracker_phase_task_dependency_re)
assert_contains "1.2 regex names phase-N(.M)" "$dep_re" "phase-[0-9]+"
assert_contains "1.2 regex names TD-NNN"      "$dep_re" "TD-[0-9]+"
assert_contains "1.2 regex names BD-NNN"      "$dep_re" "BD-[0-9]+"

# Sanity: the regex matches a real Dependencies entry.
test_line='  - phase-3.1 (must complete schema first)'
if [[ "$test_line" =~ $dep_re ]]; then
    t_pass "1.2 regex matches sample Dependencies entry"
else
    t_fail "1.2 regex matches sample Dependencies entry" "no match against: $test_line"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: parser correctness
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: parser correctness ===\n"

parsed=$(tracker_phase_task_parse "$FIXTURES/IMPLEMENTATION-PLAN.md" 2>/dev/null)
assert_eq "2.1 fixture parses 3 phases"     "3" "$(printf '%s' "$parsed" | jq '.phases | length')"
assert_eq "2.1 phase[0].phase_number = 3"   "3" "$(printf '%s' "$parsed" | jq -r '.phases[0].phase_number')"
assert_eq "2.1 phase[0] has 3 tasks"        "3" "$(printf '%s' "$parsed" | jq '.phases[0].tasks | length')"
assert_eq "2.1 phase[0] task[0].pack_id"    "phase-3.1" "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].pack_id')"
assert_eq "2.1 phase[0] task[0].title"      "Schema bootstrap" "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].title')"

assert_eq "2.2 sparse phase[1].tasks empty" "0" "$(printf '%s' "$parsed" | jq '.phases[1].tasks | length')"
assert_eq "2.2 sparse phase[1].phase_number" "4" "$(printf '%s' "$parsed" | jq -r '.phases[1].phase_number')"

# 2.3 dependency entries
assert_eq "2.3 phase-3.1 has 2 deps" "2" \
    "$(printf '%s' "$parsed" | jq '.phases[0].tasks[0].dependencies | length')"
assert_eq "2.3 dep[0].kind"     "blocked-by" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].dependencies[0].kind')"
assert_eq "2.3 dep[0].target"   "phase-2.4"  \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].dependencies[0].target')"
assert_eq "2.3 dep[0].annotation captured (round-trip)" \
    "(must complete migration scaffold first)" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].dependencies[0].annotation')"
assert_eq "2.3 dep[1].target = TD-029" "TD-029" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].dependencies[1].target')"
assert_eq "2.3 dep[1].annotation empty" "" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[0].dependencies[1].annotation')"

# 2.4 cross-phase dependency
assert_eq "2.4 phase-7.1 dep[0].target = phase-3.4" "phase-3.4" \
    "$(printf '%s' "$parsed" | jq -r '.phases[2].tasks[0].dependencies[0].target')"

# 2.5 BD reference inside Dependencies (phase-3.3 has BD-108)
assert_eq "2.5 phase-3.3 dep[1].target = BD-108" "BD-108" \
    "$(printf '%s' "$parsed" | jq -r '.phases[0].tasks[2].dependencies[1].target')"

# 2.6 missing file
err=$(tracker_phase_task_parse "/no/such/IMPLEMENTATION-PLAN.md" 2>&1 1>/dev/null) || true
assert_contains "2.6 missing file → typed error" "$err" "ERROR: not-found"

# ─────────────────────────────────────────────────────────────────
# Group 3: emitter + round-trip identity
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: emitter + round-trip identity ===\n"

# Parse the round-trip fixture (which contains only the Phase + Tasks
# slice — no surrounding ### Verification / Agent / Risks subsections,
# because the emitter's scope is the `### Tasks` block grammar per
# V3.3 §4.2 + the architectural slice boundary documented in
# tracker-phase-task.sh).
roundtrip_parsed=$(tracker_phase_task_parse "$FIXTURES/ROUNDTRIP.md" 2>/dev/null)
emitted=$(tracker_phase_task_emit "$roundtrip_parsed")

# 3.1 byte-identical round-trip
tmp_emitted=$(mktemp -t tpt-emitted.XXXXXX)
printf '%s\n' "$emitted" > "$tmp_emitted"
if diff -q "$FIXTURES/ROUNDTRIP.md" "$tmp_emitted" >/dev/null 2>&1; then
    t_pass "3.1 round-trip identity (parse → emit → diff = empty)"
else
    t_fail "3.1 round-trip identity (parse → emit → diff = empty)" \
        "diff: $(diff "$FIXTURES/ROUNDTRIP.md" "$tmp_emitted" | head -20)"
fi
rm -f "$tmp_emitted"

# 3.2 deterministic emit
emitted_again=$(tracker_phase_task_emit "$roundtrip_parsed")
assert_eq "3.2 emit is deterministic" "$emitted" "$emitted_again"

# 3.3 broader-fixture: parsed-from-IMPLEMENTATION-PLAN re-emit, then
# re-parse, equals the original parse (semantic round-trip — surrounding
# prose isn't preserved by the emitter, but task content is). The
# parser takes a file path, so write the re-emitted text to a tempfile
# and re-parse it.
re_emitted=$(tracker_phase_task_emit "$parsed")
tmp_reemit=$(mktemp -t tpt-reemit.XXXXXX)
printf '%s\n' "$re_emitted" > "$tmp_reemit"
re_parsed=$(tracker_phase_task_parse "$tmp_reemit" 2>/dev/null)
rm -f "$tmp_reemit"
# Compare task pack_ids in order — semantic preservation.
orig_ids=$(printf '%s' "$parsed"   | jq -c '[.phases[].tasks[].pack_id]')
re_ids=$(printf   '%s' "$re_parsed" | jq -c '[.phases[].tasks[].pack_id]')
assert_eq "3.3 semantic round-trip preserves task pack_ids" "$orig_ids" "$re_ids"

# 3.4 dependency-edge preservation across the broader round-trip
orig_deps=$(printf '%s' "$parsed"   | jq -c '[.phases[].tasks[].dependencies[]?.target]')
re_deps=$(printf   '%s' "$re_parsed" | jq -c '[.phases[].tasks[].dependencies[]?.target]')
assert_eq "3.4 semantic round-trip preserves dependency targets" "$orig_deps" "$re_deps"

# ─────────────────────────────────────────────────────────────────
# Group 4: sidecar phase_tasks block (V3.3 §4.3)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: sidecar phase_tasks block ===\n"

block=$(tracker_sidecar_compose_phase_tasks_block "$parsed")

assert_contains "4.1 block has phase_tasks: header" "$block" "phase_tasks:"
assert_contains "4.1 block names phase-3"           "$block" "phase-3:"
assert_contains "4.1 block names phase-3.1 task"    "$block" "phase-3.1:"
assert_contains "4.1 block has task_order"          "$block" "task_order:"

assert_contains "4.2 dependency_edges block present" "$block" "dependency_edges:"
assert_contains "4.2 kind: blocked-by emitted"       "$block" "kind: blocked-by"
assert_contains "4.2 target: phase-2.4 emitted"      "$block" "target: phase-2.4"
assert_contains "4.2 annotation captured"            "$block" "annotation: (must complete migration scaffold first)"
assert_contains "4.2 empty annotation rendered ''"   "$block" 'annotation: ""'

# 4.3 sparse phase
assert_contains "4.3 sparse phase emits empty tasks: {}" "$block" "phase-4:"
# Find the phase-4 block and assert it has 'tasks: {}'.
phase4_block=$(printf '%s' "$block" | awk '/^  phase-4:/{flag=1;next} /^  phase-[0-9]+:/{flag=0} flag')
assert_contains "4.3 phase-4 has tasks: {}" "$phase4_block" "tasks: {}"

# 4.4 template_version
assert_contains "4.4 template_version = phase-task-v11.0" "$block" "template_version: phase-task-v11.0"
assert_contains "4.4 extra_fields: {} placeholder"        "$block" "extra_fields: {}"

# 4.5 parent_phase wiring
assert_contains "4.5 parent_phase: phase-3 emitted" "$block" "parent_phase: phase-3"
assert_contains "4.5 parent_phase: phase-7 emitted" "$block" "parent_phase: phase-7"

# ─────────────────────────────────────────────────────────────────
# Group 5: label family helpers (V3.3 §3.5)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: label family helpers ===\n"

assert_eq "5.1 derived-from happy path"  "derived-from:TD-029"     "$(tracker_labels_derived_from TD-029)"
if tracker_labels_derived_from BD-029 >/dev/null 2>&1; then
    t_fail "5.2 derived-from rejects BD-NNN" "expected rc=1; got rc=0"
else
    t_pass "5.2 derived-from rejects BD-NNN"
fi

assert_eq "5.3 promoted-to phase-N"   "promoted-to:phase-3"   "$(tracker_labels_promoted_to phase-3)"
assert_eq "5.4 promoted-to phase-N.M" "promoted-to:phase-3.5" "$(tracker_labels_promoted_to phase-3.5)"

if tracker_labels_promoted_to phase-3.5.7 >/dev/null 2>&1; then
    t_fail "5.5 promoted-to rejects malformed" "expected rc=1; got rc=0"
else
    t_pass "5.5 promoted-to rejects malformed (3-component id)"
fi
if tracker_labels_promoted_to TD-029 >/dev/null 2>&1; then
    t_fail "5.5 promoted-to rejects TD-NNN" "expected rc=1; got rc=0"
else
    t_pass "5.5 promoted-to rejects TD-NNN target"
fi

# 5.6 Path 3 forbidden — no folded-into constructor.
if declare -f tracker_labels_folded_into >/dev/null 2>&1; then
    t_fail "5.6 NO folded-into helper (Path 3 forbidden)" \
        "tracker_labels_folded_into is defined; V3.3 §3 line 27 forbids this"
else
    t_pass "5.6 NO folded-into helper (Path 3 forbidden per V3.3 §3 line 27)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 6: id-map handling (V3.2 §4.1 step 5e + V3.3 §4.1)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: id-map handling ===\n"

# 6.1 phase task IDs use existing top-level slot
m="{}"
m=$(tmf_mapping_set "$m" "phase-3" "401" "https://example/401")
m=$(tmf_mapping_set "$m" "phase-3.1" "402" "https://example/402")
m=$(tmf_mapping_set "$m" "phase-3.2" "403" "https://example/403")
assert_eq "6.1 mapping_get phase-3.1 → 402" "402" "$(tmf_mapping_get "$m" "phase-3.1")"
assert_eq "6.1 mapping_get phase-3.2 → 403" "403" "$(tmf_mapping_get "$m" "phase-3.2")"

# 6.2 set_phase_task_order is additive (preserves id + url)
m=$(tmf_mapping_set_phase_task_order "$m" "phase-3" "1,2")
assert_eq "6.2 phase-3 still has gh id"  "401" "$(printf '%s' "$m" | jq -r '."phase-3".id')"
assert_eq "6.2 phase-3 still has url"    "https://example/401" "$(printf '%s' "$m" | jq -r '."phase-3".url')"
assert_eq "6.2 phase-3.task_order added" "[\"1\",\"2\"]" "$(printf '%s' "$m" | jq -c '."phase-3".task_order')"

# 6.3 get_phase_task_order returns the array
order=$(tmf_mapping_get_phase_task_order "$m" "phase-3")
assert_eq "6.3 get_phase_task_order"   '["1","2"]' "$order"
empty=$(tmf_mapping_get_phase_task_order "$m" "phase-99")
assert_eq "6.3 missing phase → []"     "[]" "$empty"

# Reject bad phase-id
if tmf_mapping_set_phase_task_order "$m" "phase-3.1" "1" >/dev/null 2>&1; then
    t_fail "6.3 set_phase_task_order rejects phase-N.M id" "expected rc=1; got rc=0"
else
    t_pass "6.3 set_phase_task_order rejects phase-N.M id (only phase-N accepted)"
fi

# 6.4 reverse-side _tmr_phase_task_order: explicit honored
m2=$(tmf_mapping_set_phase_task_order "$m" "phase-3" "2,1")
assert_eq "6.4 reverse honors explicit task_order" '["2", "1"]' \
    "$(_tmr_phase_task_order "$m2" "phase-3")"

# 6.5 reverse-side fallback: ascending numeric scan
m3="{}"
m3=$(tmf_mapping_set "$m3" "phase-5.10" "510" "")
m3=$(tmf_mapping_set "$m3" "phase-5.2"  "502" "")
m3=$(tmf_mapping_set "$m3" "phase-5.1"  "501" "")
fallback=$(_tmr_phase_task_order "$m3" "phase-5")
assert_eq "6.5 fallback ascending numeric" '["1", "2", "10"]' "$fallback"

# 6.6 mapping JSON round-trips through save+load with task_order
tmpdir=$(mktemp -d -t tpt-mapping.XXXXXX)
mfile="$tmpdir/id-map.json"
tmf_mapping_save "$mfile" "$m"
loaded=$(tmf_mapping_load "$mfile")
assert_eq "6.6 save/load round-trip preserves task_order" \
    '["1","2"]' \
    "$(printf '%s' "$loaded" | jq -c '."phase-3".task_order')"
assert_eq "6.6 save/load round-trip preserves phase task gh id" \
    "402" \
    "$(tmf_mapping_get "$loaded" "phase-3.1")"
rm -rf "$tmpdir"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
