#!/usr/bin/env bash
# scripts/tests/test-tracker-promote-path2.sh — Path 2 promotion
# orchestration tests (BD-107; V3.3 §3.4 + §3.5; consumes BD-108
# tracker_links_create_blocked_by for dependency-edge creation).
#
# Coverage groups:
#   1. Phase task M-allocator
#       1.1 next_phase_task_M for sparse phase → 1
#       1.2 next_phase_task_M for phase with N tasks → N+1
#       1.3 next_phase_task_M rejects phase-N.M target
#       1.4 phase_task_M_in_use detects existing M
#       1.5 phase_task_M_in_use returns false for free M
#   2. Pure formatter — phase-task block composition
#       2.1 produces #### N.M — title
#       2.2 four METHODOLOGY § Part 4 bullets emitted
#       2.3 Dependencies bullet uses TD blockers when present
#       2.4 empty blockers → "(none)" placeholder
#   3. Path 2 forward orchestration (flat-file mode)
#       3.1 inserts #### N.M at end of phase N's ### Tasks zone
#       3.2 preserves ### Verification / ### Agent / ### Risks
#       3.3 result JSON shape (td_id, target, mode=flat-file,
#           promoted-to:phase-N.M)
#       3.4 idempotency: requested M in use → typed error
#   4. Path 2 forward orchestration (tracker mode via stub)
#       4.1 mode=tracker; provider_create called
#       4.2 sub_issue_create called to parent under phase-N epic
#       4.3 dependency edges created via tracker_links_create_blocked_by
#           for each Dependencies bullet entry on the source TD
#       4.4 close called for TD with status:resolved + promoted-to label
#   5. Path 2 reverse / round-trip
#       5.1 reverse_path2 reads BACKLOG TD with phase-N.M Resolution
#       5.2 SHA-256 round-trip identity on a Path 2 fixture
#       5.3 dependency annotation preserved through emitter (BD-106 §5.3)
#   6. BD-108 dependency-edge integration
#       6.1 phase task ↔ phase task edge written to cycle-graph store
#       6.2 phase task ↔ TD edge written
#   7. Verb dispatcher integration (pack-td.sh promote --to=phase-N.M)
#       7.1 dispatcher routes to tracker_promote_path2
#       7.2 dispatcher rejects extra positional args
#
# Usage: bash scripts/tests/test-tracker-promote-path2.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-promote"
PROV_FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-provider"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }

# Source the libs in dependency order.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-cycle-check.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-links.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-phase-task.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-promote.sh"
# Stub backend for tracker-mode tests.
# shellcheck disable=SC1091
source "$PROV_FIXTURES/stub-backend.sh"
# Override _stub_record to also write to a side-channel file (so we
# can inspect the call log after subshell-isolated orchestrator calls).
_stub_record() {
    STUB_CALLS="$STUB_CALLS|$*"
    if [[ -n "${STUB_LOG_FILE:-}" ]]; then
        printf '|%s\n' "$*" >> "$STUB_LOG_FILE"
    fi
}

SCRATCH=$(mktemp -d -t tpr2.XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

mk_worktree() {
    local name="$1"
    local d="$SCRATCH/$name"
    mkdir -p "$d"
    cp "$FIXTURES/BACKLOG.md"             "$d/BACKLOG.md"
    cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$d/IMPLEMENTATION-PLAN.md"
    echo "$d"
}

mk_tracker_worktree() {
    local name="$1"
    local d
    d=$(mk_worktree "$name")
    mkdir -p "$d/.pack-tracker"
    cp "$FIXTURES/id-map.json" "$d/.pack-tracker/id-map.json"
    echo "$d"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: phase task M-allocator
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: phase task M-allocator ===\n"

# Fixture has phase-3 with tasks 3.1, 3.2 → next_M = 3
wt=$(mk_worktree "g1")
assert_eq "1.1 sparse-phase next_M (no plan or no phase) = 1" \
    "1" "$(tracker_promote_next_phase_task_M "/no/such/dir" "phase-9")"
assert_eq "1.2 phase-3 next_M = 3 (existing 3.1, 3.2)" \
    "3" "$(tracker_promote_next_phase_task_M "$wt" "phase-3")"
assert_eq "1.2 phase-9 next_M = 1 (phase doesn't exist in plan)" \
    "1" "$(tracker_promote_next_phase_task_M "$wt" "phase-9")"

# 1.3 reject phase-N.M
if tracker_promote_next_phase_task_M "$wt" "phase-3.5" 2>/dev/null; then
    t_fail "1.3 next_phase_task_M rejects phase-N.M" "expected rc=1; got rc=0"
else
    t_pass "1.3 next_phase_task_M rejects phase-N.M"
fi

# 1.4 / 1.5
if tracker_promote_phase_task_M_in_use "$wt" "phase-3.1" 2>/dev/null; then
    t_pass "1.4 phase_task_M_in_use detects existing 3.1"
else
    t_fail "1.4 phase_task_M_in_use detects existing 3.1" "expected rc=0"
fi
if tracker_promote_phase_task_M_in_use "$wt" "phase-3.99" 2>/dev/null; then
    t_fail "1.5 phase_task_M_in_use returns false for free M" "expected rc=1"
else
    t_pass "1.5 phase_task_M_in_use returns false for free M"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: pure formatter — phase-task block composition
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: pure formatter — phase-task block composition ===\n"

td_with_blockers='{"pack_id":"TD-040","title":"Schema bootstrap helper","type":"TODO(version)","status":"Open","blockers":["TD-029","phase-3.1"],"unblocks":[],"file_symbol":"`scripts/lib/tracker-schema.sh`","description":"Common schema-loader helper.","context":"","resolution":""}'
td_no_blockers='{"pack_id":"TD-031","title":"Streaming sidecar","type":"TODO(version)","status":"Open","blockers":[],"unblocks":[],"file_symbol":"","description":"Switch to streaming.","context":"","resolution":""}'

block=$(tracker_promote_compose_phase_task_block "$td_with_blockers" 3 4)
assert_contains "2.1 block opens with #### 3.4" "$block" "#### 3.4 — Schema bootstrap helper"
assert_contains "2.2 has Problem / Goal / Success bullet" "$block" "Problem / Goal / Success"
assert_contains "2.2 has Files created/modified bullet"   "$block" "Files created/modified"
assert_contains "2.2 has Definition of done bullet"       "$block" "Definition of done"
assert_contains "2.2 has Dependencies bullet"             "$block" "Dependencies"
assert_contains "2.3 Dependencies includes TD-029"        "$block" "TD-029"
assert_contains "2.3 Dependencies includes phase-3.1"     "$block" "phase-3.1"

block_no_deps=$(tracker_promote_compose_phase_task_block "$td_no_blockers" 7 1)
assert_contains "2.4 empty blockers → (none) placeholder" "$block_no_deps" "(none)"

# ─────────────────────────────────────────────────────────────────
# Group 3: Path 2 forward orchestration (flat-file mode)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Path 2 forward orchestration (flat-file mode) ===\n"

wt2=$(mk_worktree "g3-flat")
result=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt2" "" "" 1 2>/dev/null)
plan2="$wt2/IMPLEMENTATION-PLAN.md"

# 3.1 #### 3.4 inserted into phase 3's Tasks zone
if grep -qE '^#### 3\.4 — Schema bootstrap helper$' "$plan2"; then
    t_pass "3.1 #### 3.4 inserted into IMPLEMENTATION-PLAN.md"
else
    t_fail "3.1 #### 3.4 inserted into IMPLEMENTATION-PLAN.md" "$(grep -E '^####' "$plan2")"
fi

# 3.2 surrounding sections preserved
if grep -q '^### Verification' "$plan2" && grep -q '^### Agent' "$plan2" && grep -q '^### Risks' "$plan2"; then
    t_pass "3.2 surrounding ### Verification / Agent / Risks preserved"
else
    t_fail "3.2 surrounding ### Verification / Agent / Risks preserved"
fi

# 3.2 also: the new 3.4 task is positioned BEFORE ### Verification
# (i.e. inside the ### Tasks zone, not appended at the bottom).
new_task_line=$(grep -nE '^#### 3\.4 ' "$plan2" | head -1 | cut -d: -f1)
verif_line=$(grep -nE '^### Verification' "$plan2" | head -1 | cut -d: -f1)
if [[ -n "$new_task_line" && -n "$verif_line" && "$new_task_line" -lt "$verif_line" ]]; then
    t_pass "3.2 #### 3.4 inserted BEFORE ### Verification (inside Tasks zone)"
else
    t_fail "3.2 #### 3.4 inserted BEFORE ### Verification (inside Tasks zone)" \
        "task line=$new_task_line, verif line=$verif_line"
fi

# 3.3 result JSON shape
assert_eq "3.3 result td_id"   "TD-040"      "$(printf '%s' "$result" | jq -r '.td_id')"
assert_eq "3.3 result target"  "phase-3.4"   "$(printf '%s' "$result" | jq -r '.target')"
assert_eq "3.3 result mode"    "flat-file"   "$(printf '%s' "$result" | jq -r '.mode')"
assert_eq "3.3 result promoted_to" "promoted-to:phase-3.4" "$(printf '%s' "$result" | jq -r '.promoted_to')"

# 3.4 idempotency: requested M in use → typed error
err=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt2" "" "" 1 2>&1) || true
assert_contains "3.4 requested M in use → typed error" "$err" "ERROR: validation"
assert_contains "3.4 typed error names call-out 6"     "$err" "call-out 6"

# Also: requesting an existing M from the seed plan (phase-3.1) is
# rejected.
wt2b=$(mk_worktree "g3-flat-b")
err=$(tracker_promote_path2 "TD-040" "phase-3.1" "$wt2b" "" "" 1 2>&1) || true
assert_contains "3.4 phase-3.1 already exists → typed error" "$err" "already exists"

# ─────────────────────────────────────────────────────────────────
# Group 4: Path 2 forward orchestration (tracker mode via stub)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Path 2 forward orchestration (tracker mode) ===\n"

wt3=$(mk_tracker_worktree "g4-tracker")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
G4_STUB_LOG="$SCRATCH/g4-stub.log"
: > "$G4_STUB_LOG"
export STUB_LOG_FILE="$G4_STUB_LOG"
ID_MAP=$(cat "$wt3/.pack-tracker/id-map.json")
STORE="$wt3/.pack-tracker/links-graph.json"
result4=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt3" "$ID_MAP" "$STORE" 0 2>/dev/null)
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE STUB_LOG_FILE

# 4.1 mode=tracker; provider_create called
assert_eq "4.1 mode=tracker" "tracker" "$(printf '%s' "$result4" | jq -r '.mode')"
create_lines=$(grep -cE '^\|create' "$G4_STUB_LOG" 2>/dev/null || echo 0)
if [[ "$create_lines" -ge 1 ]]; then
    t_pass "4.1 provider_create called for phase task"
else
    t_fail "4.1 provider_create called for phase task" "no |create line"
fi

# 4.2 sub_issue_create called to parent under phase-N epic
if grep -qE '^\|sub_issue_create ' "$G4_STUB_LOG"; then
    t_pass "4.2 sub_issue_create called to parent under phase-N epic"
else
    t_fail "4.2 sub_issue_create called to parent under phase-N epic" \
        "$(cat "$G4_STUB_LOG" | head -20)"
fi

# 4.3 dependency edges created — TD-040 has blockers TD-029 + phase-3.1.
# tracker_links_create_blocked_by goes through provider_link.
link_lines=$(grep -cE '^\|link ' "$G4_STUB_LOG" 2>/dev/null || echo 0)
if [[ "$link_lines" -ge 2 ]]; then
    t_pass "4.3 ≥2 provider_link calls (TD-029 + phase-3.1 deps)"
else
    t_fail "4.3 ≥2 provider_link calls (TD-029 + phase-3.1 deps)" "got $link_lines"
fi

# Result includes dependency_edges array
edge_count=$(printf '%s' "$result4" | jq '.dependency_edges | length')
if [[ "$edge_count" -ge 2 ]]; then
    t_pass "4.3 result.dependency_edges has ≥2 entries"
else
    t_fail "4.3 result.dependency_edges has ≥2 entries" "got $edge_count: $(printf '%s' "$result4" | jq -c '.dependency_edges')"
fi

# 4.4 TD close + promoted-to label
close_line=$(grep -E '^\|close ' "$G4_STUB_LOG" | head -1 || true)
if [[ "$close_line" == *" 1040 "* ]] || [[ "$close_line" == *" 1040" ]]; then
    t_pass "4.4 close called for TD-040 (gh-id 1040)"
else
    t_fail "4.4 close called for TD-040 (gh-id 1040)" "close line: $close_line"
fi
set_labels_line=$(grep -E '^\|set_labels 1040 ' "$G4_STUB_LOG" | head -1 || true)
assert_contains "4.4 set_labels names promoted-to:phase-3.4" "$set_labels_line" "promoted-to:phase-3.4"
assert_contains "4.4 set_labels names status:resolved"        "$set_labels_line" "status:resolved"

# 4.5 BATCH-17 F2 (cross-BD review): provider_update called for TD-040
# body Resolution sync. Stub records can be multi-line; pull full log.
g4_log_full=$(cat "$G4_STUB_LOG")
if [[ "$g4_log_full" == *"|update 1040 "* ]]; then
    t_pass "4.5 F2: provider_update called for TD-040 body Resolution sync"
else
    t_fail "4.5 F2: provider_update called for TD-040 body Resolution sync" \
        "no |update 1040 line; BATCH-17 F2 fix not wired"
fi
if [[ "$g4_log_full" == *"completed, promoted to phase-3.4"* ]]; then
    t_pass "4.5 F2: update body names canonical Resolution shape (phase-3.4)"
else
    t_fail "4.5 F2: update body names canonical Resolution shape (phase-3.4)" \
        "update payload tail: $(printf '%s' "$g4_log_full" | tail -30)"
fi
if [[ "$g4_log_full" == *"## Resolution"* ]]; then
    t_pass "4.5 F2: update body has ## Resolution section heading"
else
    t_fail "4.5 F2: update body has ## Resolution section heading" \
        "update payload tail: $(printf '%s' "$g4_log_full" | tail -30)"
fi

# 4.6 BATCH-17 F3 (cross-BD review): id-map.json on disk has the new
# phase-3.4 entry. Without this, a subsequent --to=phase-3.5 promote
# referencing phase-3.4 in Dependencies would fail at link-orchestrator
# resolution.
disk_map="$wt3/.pack-tracker/id-map.json"
if [[ -f "$disk_map" ]] && jq -e --arg k "phase-3.4" 'has($k)' "$disk_map" >/dev/null 2>&1; then
    t_pass "4.6 F3: id-map.json on disk has new phase-3.4 entry"
    new_id=$(jq -r --arg k "phase-3.4" '.[$k].id' "$disk_map")
    assert_eq "4.6 F3: phase-3.4 id matches stub create rc (99)" "99" "$new_id"
else
    t_fail "4.6 F3: id-map.json on disk has new phase-3.4 entry" \
        "$(cat "$disk_map" 2>/dev/null)"
fi

# 4.7 BATCH-17 F3 (cross-BD review): second-run regression — promote
# TD-029 to phase-3.5 in tracker mode and verify the second run's
# in-memory id-map (loaded from disk) sees the previous phase-3.4
# from disk. Reading id-map from disk (pack-td.sh:165 pattern) is
# the production codepath; the test simulates that.
wt3b=$(mk_tracker_worktree "g4-7-second-run")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
G4B_STUB_LOG="$SCRATCH/g4-7-stub.log"
: > "$G4B_STUB_LOG"
export STUB_LOG_FILE="$G4B_STUB_LOG"
ID_MAP_3B=$(cat "$wt3b/.pack-tracker/id-map.json")
STORE_3B="$wt3b/.pack-tracker/links-graph.json"
# First run: TD-040 → phase-3.4. F3 should save phase-3.4 to disk.
tracker_promote_path2 "TD-040" "phase-3.4" "$wt3b" "$ID_MAP_3B" "$STORE_3B" 0 >/dev/null 2>&1
# Now re-read id-map from disk (simulates the next pack-td invocation).
ID_MAP_3B_AFTER=$(cat "$wt3b/.pack-tracker/id-map.json")
if printf '%s' "$ID_MAP_3B_AFTER" | jq -e 'has("phase-3.4")' >/dev/null 2>&1; then
    t_pass "4.7 F3: second-run reads phase-3.4 from disk id-map"
else
    t_fail "4.7 F3: second-run reads phase-3.4 from disk id-map" \
        "id-map after first run: $(printf '%s' "$ID_MAP_3B_AFTER" | jq -c .)"
fi
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE STUB_LOG_FILE

# ─────────────────────────────────────────────────────────────────
# Group 5: Path 2 reverse / round-trip
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Path 2 reverse / round-trip ===\n"

wt5=$(mk_worktree "g5-reverse")
python3 - "$wt5/BACKLOG.md" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace(
    'Resolution: n/a',
    'Resolution: [2026-05-14, completed, promoted to phase-3.4]',
    1,
)
with open(path, 'w') as f:
    f.write(text)
PYEOF
reverse=$(tracker_promote_reverse_path2 "phase-3.4" "$wt5" 2>/dev/null)
assert_eq "5.1 reverse phase = phase-3.4" "phase-3.4" "$(printf '%s' "$reverse" | jq -r '.phase')"
# The first TD entry (TD-031) gets the patched Resolution.
assert_contains "5.1 reverse derived_from named" "$(printf '%s' "$reverse" | jq -r '.derived_from')" "TD-"
assert_contains "5.1 reverse resolution names phase-3.4" "$(printf '%s' "$reverse" | jq -r '.resolution')" "phase-3.4"

# 5.2 SHA-256 round-trip identity
wt6=$(mk_worktree "g5-roundtrip")
backlog_before=$(shasum -a 256 "$wt6/BACKLOG.md" | cut -d' ' -f1)
plan_before=$(shasum -a 256 "$wt6/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)

tracker_promote_path2 "TD-040" "phase-3.4" "$wt6" "" "" 1 >/dev/null 2>&1

# Apply Resolution patch (PM Chat owns the BACKLOG mutation; library
# returns the patch text via .resolution_text in the result).
python3 - "$wt6/BACKLOG.md" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
# TD-040 stanza has Resolution: n/a — replace with promoted form.
# Use a precise replacement to avoid touching TD-031/029 stanzas.
old_block = '''**TD-040 — Schema bootstrap helper**
Type: TODO(version)
Status: Open
Blockers:
  - TD-029
  - phase-3.1
Unblocks: None
File/Symbol: `scripts/lib/tracker-schema.sh`
Description: Common schema-loader helper to deduplicate the four call sites.
Context: Repeated boilerplate noticed in BD-106/108 land.
Resolution: n/a'''
new_block = '''**TD-040 — Schema bootstrap helper**
Type: TODO(version)
Status: Resolved
Blockers:
  - TD-029
  - phase-3.1
Unblocks: None
File/Symbol: `scripts/lib/tracker-schema.sh`
Description: Common schema-loader helper to deduplicate the four call sites.
Context: Repeated boilerplate noticed in BD-106/108 land.
Resolution: [2026-05-14, completed, promoted to phase-3.4]'''
text = text.replace(old_block, new_block, 1)
with open(path, 'w') as f:
    f.write(text)
PYEOF

backlog_after=$(shasum -a 256 "$wt6/BACKLOG.md" | cut -d' ' -f1)
plan_after=$(shasum -a 256 "$wt6/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)

# Idempotent replay: second forward refused; SHAs stable.
err=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt6" "" "" 1 2>&1) || true
backlog_replay=$(shasum -a 256 "$wt6/BACKLOG.md" | cut -d' ' -f1)
plan_replay=$(shasum -a 256 "$wt6/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)
assert_eq "5.2 BACKLOG SHA stable across replay (round-trip safety)" \
    "$backlog_after" "$backlog_replay"
assert_eq "5.2 IMPLEMENTATION-PLAN SHA stable across replay" \
    "$plan_after" "$plan_replay"
if [[ "$plan_before" != "$plan_after" ]]; then
    t_pass "5.2 IMPLEMENTATION-PLAN mutated by first forward run"
else
    t_fail "5.2 IMPLEMENTATION-PLAN mutated by first forward run" \
        "expected SHA change after Path 2 forward; got identity"
fi

# 5.3 dependency annotation preserved (BD-106 §5.3 round-trip contract).
# Parse the post-promotion plan with tracker_phase_task_parse and
# verify the new 3.4 task carries TD-029 + phase-3.1 in its dependencies
# array.
parsed5=$(tracker_phase_task_parse "$wt6/IMPLEMENTATION-PLAN.md" 2>/dev/null)
deps_targets=$(printf '%s' "$parsed5" | jq -r '[.phases[] | select(.phase_number == "3") | .tasks[] | select(.task_number == "4") | .dependencies[]?.target] | join(",")')
assert_contains "5.3 phase-3.4 dep includes TD-029"    "$deps_targets" "TD-029"
assert_contains "5.3 phase-3.4 dep includes phase-3.1" "$deps_targets" "phase-3.1"

# ─────────────────────────────────────────────────────────────────
# Group 6: BD-108 dependency-edge integration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: BD-108 dependency-edge integration ===\n"

wt7=$(mk_tracker_worktree "g6-deps")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
G6_STUB_LOG="$SCRATCH/g6-stub.log"
: > "$G6_STUB_LOG"
export STUB_LOG_FILE="$G6_STUB_LOG"
ID_MAP=$(cat "$wt7/.pack-tracker/id-map.json")
STORE7="$wt7/.pack-tracker/links-graph.json"
tracker_promote_path2 "TD-040" "phase-3.4" "$wt7" "$ID_MAP" "$STORE7" 0 >/dev/null 2>&1
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE STUB_LOG_FILE

# 6.1/6.2 cycle-graph store has the new edges
if [[ -f "$STORE7" ]]; then
    edges=$(jq -c '.edges' "$STORE7")
    assert_contains "6.1 store edge: source=phase-3.4"     "$edges" '"source":"phase-3.4"'
    assert_contains "6.1 store edge: target=phase-3.1"     "$edges" '"target":"phase-3.1"'
    assert_contains "6.2 store edge: target=TD-029"        "$edges" '"target":"TD-029"'
else
    t_fail "6.1/6.2 cycle-graph store created" "no file at $STORE7"
fi

# ─────────────────────────────────────────────────────────────────
# Group 7: verb dispatcher integration (pack-td.sh promote phase-N.M)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 7: verb dispatcher integration ===\n"

DISPATCHER="$REPO_ROOT/scripts/pack-td.sh"

wt8=$(mk_worktree "g7-dispatcher")
out=$("$DISPATCHER" promote --to=phase-3.4 TD-040 --repo-root "$wt8" --flat-file-only 2>/dev/null)
assert_eq "7.1 dispatcher result td_id"      "TD-040"     "$(printf '%s' "$out" | jq -r '.td_id')"
assert_eq "7.1 dispatcher result target"     "phase-3.4"  "$(printf '%s' "$out" | jq -r '.target')"
assert_eq "7.1 dispatcher result mode"       "flat-file"  "$(printf '%s' "$out" | jq -r '.mode')"
assert_eq "7.1 dispatcher result promoted_to" "promoted-to:phase-3.4" "$(printf '%s' "$out" | jq -r '.promoted_to')"

# 7.2 extra positional rejected
err=$("$DISPATCHER" promote --to=phase-3.4 TD-040 EXTRA 2>&1) || true
assert_contains "7.2 extra positional rejected" "$err" "ERROR: validation"

# 7.3 F7 (BD-107 review): failure-path coverage for Path 2. Override
# tracker_provider_stub_create to fail, then assert Path 2 surfaces
# the failure as a typed partial-write error (not a silent success).
wt_f7=$(mk_tracker_worktree "g7-f7-failure")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
_F7_ORIG_STUB_CREATE=$(declare -f tracker_provider_stub_create)
tracker_provider_stub_create() { return 1; }
ID_MAP_F7=$(cat "$wt_f7/.pack-tracker/id-map.json")
STORE_F7="$wt_f7/.pack-tracker/links-graph.json"
err_f7=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt_f7" "$ID_MAP_F7" "$STORE_F7" 0 2>&1) || true
eval "$_F7_ORIG_STUB_CREATE"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
assert_contains "7.3 F7: provider_create failure → typed partial-write error" "$err_f7" "partial-write"
assert_contains "7.3 F7: failure-path message names provider_create" "$err_f7" "provider_create"
# F9 rollback: the plan-file mutation must be reverted (no #### 3.4
# heading after the failure).
plan_after_failure=$(grep -cE '^#### 3\.4 ' "$wt_f7/IMPLEMENTATION-PLAN.md" 2>/dev/null || true)
plan_after_failure="${plan_after_failure:-0}"
if [[ "$plan_after_failure" -eq 0 ]]; then
    t_pass "7.3 F9: plan-file rollback after provider_create failure"
else
    t_fail "7.3 F9: plan-file rollback after provider_create failure" \
        "expected no #### 3.4 heading; got grep count=$plan_after_failure"
fi

# 7.4 F3 (BD-107 review): set_labels failure on TD close surfaces as
# typed partial-write (the phase task was created OK; only the TD-side
# label-set failed). The new phase task should remain in the plan
# (no rollback for post-create failures — see F9 design note).
wt_f7b=$(mk_tracker_worktree "g7-f7-set-labels")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
_F7_ORIG_STUB_SET_LABELS=$(declare -f tracker_provider_stub_set_labels)
tracker_provider_stub_set_labels() { return 1; }
ID_MAP_F7B=$(cat "$wt_f7b/.pack-tracker/id-map.json")
STORE_F7B="$wt_f7b/.pack-tracker/links-graph.json"
err_f7b=$(tracker_promote_path2 "TD-040" "phase-3.4" "$wt_f7b" "$ID_MAP_F7B" "$STORE_F7B" 0 2>&1) || true
eval "$_F7_ORIG_STUB_SET_LABELS"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
assert_contains "7.4 F3: provider_set_labels failure → typed partial-write" "$err_f7b" "partial-write"
assert_contains "7.4 F3: failure-path message names set_labels" "$err_f7b" "provider_set_labels"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
exit "$FAIL"
