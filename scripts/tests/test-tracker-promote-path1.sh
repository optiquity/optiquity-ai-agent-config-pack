#!/usr/bin/env bash
# scripts/tests/test-tracker-promote-path1.sh — Path 1 promotion
# orchestration tests (BD-107; V3.3 §3.3 + §3.5).
#
# Coverage groups:
#   1. Verb classification + validation
#       1.1 _tpr_classify_target("phase-7") → "path1"
#       1.2 _tpr_classify_target("phase-7.4") → "path2"
#       1.3 invalid TD shape rejected
#       1.4 invalid target shape rejected (phase-7.4.5; folded-into; empty)
#   2. Pure formatter — phase section composition
#       2.1 produces ## Phase N — title
#       2.2 produces ### Tasks / ### Verification / ### Agent / ### Risks
#       2.3 references TD id in promoted-from comment
#       2.4 honours TD File/Symbol when present
#   3. Path 1 forward orchestration (flat-file mode)
#       3.1 appends ## Phase N to IMPLEMENTATION-PLAN.md
#       3.2 emits result JSON with td_id, target, mode=flat-file
#       3.3 derived-from / promoted-to labels named in result
#       3.4 idempotency: re-run refuses with typed error
#   4. Path 1 forward orchestration (tracker mode via stub)
#       4.1 mode=tracker when id-map.json present
#       4.2 provider_create called with phase-epic + derived-from labels
#       4.3 TD provider_close called with state_reason=completed
#   5. Path 1 reverse / round-trip
#       5.1 reverse_path1 reads BACKLOG TD with phase-N in Resolution
#       5.2 SHA-256 round-trip identity on a Path 1 fixture
#   6. Label invariants (V3.3 §3.5; mirrors BD-106 §5)
#       6.1 derived-from label written to phase epic (Path 1)
#       6.2 promoted-to:phase-N label written to closed TD
#       6.3 NO folded-into: label anywhere in result
#       6.4 NO tracker_labels_folded_into helper exists (Path 3 forbidden)
#   7. Verb dispatcher integration (pack-td.sh promote --to=phase-N)
#       7.1 dispatcher routes to tracker_promote_path1
#       7.2 dispatcher rejects --fold-into with typed error
#       7.3 dispatcher --help prints verb manifest
#   8. PM-CHAT.md content sanity
#       8.1 PM-CHAT.md has TD resolution orchestration section
#       8.2 section names architect-default for Path 1
#
# Usage: bash scripts/tests/test-tracker-promote-path1.sh

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

# Source the libs in dependency order. Mirrors test-tracker-phase-task.sh.
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

# Test-local stub override: write all calls to a side-channel file so
# we can inspect them after a subshell-isolated orchestrator call. The
# default stub-backend.sh writes to a global $STUB_CALLS variable,
# which is lost across subshells. We override _stub_record (the only
# write site) to additionally append to STUB_LOG_FILE when set.
_stub_record() {
    STUB_CALLS="$STUB_CALLS|$*"
    if [[ -n "${STUB_LOG_FILE:-}" ]]; then
        printf '|%s\n' "$*" >> "$STUB_LOG_FILE"
    fi
}

SCRATCH=$(mktemp -d -t tpr1.XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT

# Helper: build a fresh worktree fixture for a single test.
mk_worktree() {
    local name="$1"
    local d="$SCRATCH/$name"
    mkdir -p "$d"
    cp "$FIXTURES/BACKLOG.md"             "$d/BACKLOG.md"
    cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$d/IMPLEMENTATION-PLAN.md"
    echo "$d"
}

# Helper: build a fresh worktree fixture in tracker mode (id-map present).
mk_tracker_worktree() {
    local name="$1"
    local d
    d=$(mk_worktree "$name")
    mkdir -p "$d/.pack-tracker"
    cp "$FIXTURES/id-map.json" "$d/.pack-tracker/id-map.json"
    echo "$d"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: verb classification + validation
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: verb classification + validation ===\n"

assert_eq "1.1 phase-7 → path1" "path1" "$(_tpr_classify_target phase-7)"
assert_eq "1.1 phase-103 → path1" "path1" "$(_tpr_classify_target phase-103)"
assert_eq "1.2 phase-7.4 → path2" "path2" "$(_tpr_classify_target phase-7.4)"
assert_eq "1.2 phase-3.42 → path2" "path2" "$(_tpr_classify_target phase-3.42)"

# 1.3 invalid TD shape
if _tpr_validate_td_id "BD-029" 2>/dev/null; then
    t_fail "1.3 _tpr_validate_td_id rejects BD-NNN" "expected rc=1; got rc=0"
else
    t_pass "1.3 _tpr_validate_td_id rejects BD-NNN"
fi
if _tpr_validate_td_id "" 2>/dev/null; then
    t_fail "1.3 _tpr_validate_td_id rejects empty" "expected rc=1; got rc=0"
else
    t_pass "1.3 _tpr_validate_td_id rejects empty"
fi
if _tpr_validate_td_id "TD-031" 2>/dev/null; then
    t_pass "1.3 _tpr_validate_td_id accepts TD-031"
else
    t_fail "1.3 _tpr_validate_td_id accepts TD-031" "expected rc=0; got rc=1"
fi

# 1.4 invalid target shapes
if _tpr_classify_target "phase-7.4.5" 2>/dev/null; then
    t_fail "1.4 phase-N.M.K rejected" "expected rc=1; got rc=0"
else
    t_pass "1.4 phase-N.M.K rejected (3-component is not legal)"
fi
err=$(_tpr_classify_target "" 2>&1) || true
assert_contains "1.4 empty target → typed validation error" "$err" "ERROR: validation"

err=$(_tpr_classify_target "garbage" 2>&1) || true
assert_contains "1.4 garbage target → typed validation error" "$err" "ERROR: validation"
assert_contains "1.4 typed error mentions Path 3 forbidden" "$err" "Path 3 is forbidden"

# ─────────────────────────────────────────────────────────────────
# Group 2: pure formatter — phase section composition
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: pure formatter — phase section composition ===\n"

td_json='{"pack_id":"TD-031","title":"Streaming sidecar","type":"TODO(version)","status":"Open","blockers":[],"unblocks":[],"file_symbol":"`scripts/lib/tracker-sidecar.sh` — `tracker_sidecar_emit`","description":"Switch to streaming mode.","context":"Observed during dog-food.","resolution":""}'
section=$(tracker_promote_compose_phase_section "$td_json" "phase-7")

assert_contains "2.1 section opens with ## Phase 7"   "$section" "## Phase 7 — Streaming sidecar"
assert_contains "2.2 section has ### Tasks"           "$section" "### Tasks"
assert_contains "2.2 section has ### Verification"    "$section" "### Verification"
assert_contains "2.2 section has ### Agent"           "$section" "### Agent"
assert_contains "2.2 section has ### Risks"           "$section" "### Risks"
assert_contains "2.3 names TD id in promoted-from"    "$section" "TD-031"
assert_contains "2.4 emits TD File/Symbol"            "$section" "tracker_sidecar_emit"

# ─────────────────────────────────────────────────────────────────
# Group 3: Path 1 forward orchestration (flat-file mode)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Path 1 forward orchestration (flat-file mode) ===\n"

wt=$(mk_worktree "g3-flat")
result=$(tracker_promote_path1 "TD-031" "phase-7" "$wt" 1 2>/dev/null)

# 3.1 plan file extended
plan="$wt/IMPLEMENTATION-PLAN.md"
if grep -qE '^## Phase 7 ' "$plan"; then
    t_pass "3.1 ## Phase 7 appended to IMPLEMENTATION-PLAN.md"
else
    t_fail "3.1 ## Phase 7 appended to IMPLEMENTATION-PLAN.md" "$(tail -20 "$plan")"
fi

# 3.2 result JSON shape
assert_eq "3.2 result td_id" "TD-031" "$(printf '%s' "$result" | jq -r '.td_id')"
assert_eq "3.2 result target" "phase-7" "$(printf '%s' "$result" | jq -r '.target')"
assert_eq "3.2 result mode" "flat-file" "$(printf '%s' "$result" | jq -r '.mode')"

# 3.3 labels named (not yet applied in flat-file mode but the label set
# is part of the contract)
labels=$(printf '%s' "$result" | jq -r '.labels_created | join(",")')
assert_contains "3.3 derived-from:TD-031 in labels"  "$labels" "derived-from:TD-031"
assert_contains "3.3 phase-epic in labels"           "$labels" "phase-epic"
assert_contains "3.3 phase-7 label in labels"        "$labels" "phase-7"
assert_contains "3.3 template:phase-epic-v11.0"      "$labels" "template:phase-epic-v11.0"
assert_eq "3.3 promoted-to:phase-7" "promoted-to:phase-7" "$(printf '%s' "$result" | jq -r '.promoted_to')"

# 3.4 idempotency: TD has Resolution naming phase-7 + plan has the
# block → re-run refuses. We simulate the post-promotion BACKLOG state
# by appending Resolution text to the TD entry in the worktree's
# BACKLOG.md.
python3 - "$wt/BACKLOG.md" "phase-7" <<'PYEOF'
import sys
path, target = sys.argv[1], sys.argv[2]
with open(path) as f:
    text = f.read()
# Append Resolution to TD-031 stanza.
text = text.replace(
    '**TD-031 — Refactor sidecar emitter for streaming**',
    '**TD-031 — Refactor sidecar emitter for streaming**'
)
text = text.replace(
    'Resolution: n/a',
    f'Resolution: [2026-05-14, completed, promoted to {target}]',
    1,
)
with open(path, 'w') as f:
    f.write(text)
PYEOF
err=$(tracker_promote_path1 "TD-031" "phase-7" "$wt" 1 2>&1) || true
assert_contains "3.4 idempotency: refuses duplicate run" "$err" "already promoted"

# 3.5 F2 (BD-107 review): the idempotency match must NOT false-positive
# across phase-number prefixes. A TD whose Resolution names phase-72
# must NOT block a fresh --to=phase-7 invocation, even when the plan
# already carries both `## Phase 7` and `## Phase 72` headings (after
# we synthesize them).
wt_f2=$(mk_worktree "g3-f2-prefix")
# Append a `## Phase 72` heading to the plan AND set TD-031's Resolution
# to name phase-72 (simulating prior promotion).
cat >> "$wt_f2/IMPLEMENTATION-PLAN.md" <<'EOF'

## Phase 72 — Prefix-collision lock fixture

### Tasks
#### 72.1 — placeholder
EOF
python3 - "$wt_f2/BACKLOG.md" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace(
    'Resolution: n/a',
    'Resolution: [2026-05-14, completed, promoted to phase-72]',
    1,
)
with open(path, 'w') as f:
    f.write(text)
PYEOF
# Now invoking --to=phase-7 must NOT trip the idempotency guard. The
# guard requires BOTH the canonical `to phase-7]` Resolution shape AND
# a `## Phase 7` heading in the plan; the seed plan already has
# `## Phase 3` only, no `## Phase 7`. So a fresh --to=phase-7 should
# succeed and append the new ## Phase 7 heading.
result_f2=$(tracker_promote_path1 "TD-031" "phase-7" "$wt_f2" 1 2>/dev/null) || true
plan_after_f2_count=$(grep -cE '^## Phase 7 ' "$wt_f2/IMPLEMENTATION-PLAN.md" || echo 0)
if [[ "$plan_after_f2_count" -ge 1 ]]; then
    t_pass "3.5 F2: phase-72 Resolution does NOT false-positive --to=phase-7"
else
    t_fail "3.5 F2: phase-72 Resolution does NOT false-positive --to=phase-7" \
        "expected ## Phase 7 heading after run; got grep count=$plan_after_f2_count"
fi
# And the result JSON should be well-formed (target=phase-7).
if [[ -n "$result_f2" ]]; then
    actual_target=$(printf '%s' "$result_f2" | jq -r '.target' 2>/dev/null || echo "")
    assert_eq "3.5 F2: result target=phase-7 (not blocked by phase-72)" "phase-7" "$actual_target"
fi

# ─────────────────────────────────────────────────────────────────
# Group 4: Path 1 forward orchestration (tracker mode via stub)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Path 1 forward orchestration (tracker mode) ===\n"

wt2=$(mk_tracker_worktree "g4-tracker")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
G4_STUB_LOG="$SCRATCH/g4-stub-calls.log"
: > "$G4_STUB_LOG"
export STUB_LOG_FILE="$G4_STUB_LOG"
result2=$(tracker_promote_path1 "TD-031" "phase-7" "$wt2" 0 2>/dev/null)
STUB_CALLS=$(cat "$G4_STUB_LOG")
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE STUB_LOG_FILE

# 4.1 mode flips to tracker
assert_eq "4.1 mode=tracker when id-map.json present" "tracker" "$(printf '%s' "$result2" | jq -r '.mode')"

# 4.2 provider_create called (stub records "create" with the payload)
assert_contains "4.2 provider_create called"          "$STUB_CALLS" "|create"
assert_contains "4.2 phase-epic label in payload"     "$STUB_CALLS" "phase-epic"
assert_contains "4.2 derived-from:TD-031 in payload"  "$STUB_CALLS" "derived-from:TD-031"

# 4.3 close called for TD (state_reason=completed). The stub log
# records each call on its own `|<op>|<args>` line; we grep specific
# close-record lines so newline-laden create payloads above don't
# accidentally satisfy the assertion via substring match.
close_line=$(grep -E '^\|close ' "$G4_STUB_LOG" 2>/dev/null || true)
if [[ -n "$close_line" ]]; then
    t_pass "4.3 provider_close called for TD"
else
    t_fail "4.3 provider_close called for TD" "no |close line in stub log"
fi
if [[ "$close_line" == *" 1031 "* ]] || [[ "$close_line" == *" 1031" ]]; then
    t_pass "4.3 close target = TD gh-id 1031"
else
    t_fail "4.3 close target = TD gh-id 1031" "close line: $close_line"
fi
if [[ "$close_line" == *"completed"* ]]; then
    t_pass "4.3 close state_reason = completed"
else
    t_fail "4.3 close state_reason = completed" "close line: $close_line"
fi

# tracker_id captured
trk_id=$(printf '%s' "$result2" | jq -r '.tracker_id')
assert_eq "4.3 tracker_id recorded (stub returns 99)" "99" "$trk_id"

# 4.4 BATCH-17 F2 (cross-BD review): provider_update called on the TD
# issue with body containing the canonical Resolution text. Without
# this, `pack tracker disable` reverse migration regenerates BACKLOG
# with empty Resolution for the promoted TD. The stub records each
# call as `|<op> <args...>` on potentially-multiline output (the body
# patch JSON has embedded newlines), so we pull the entire log file
# content rather than grepping a single line.
g4_log_full=$(cat "$G4_STUB_LOG")
if [[ "$g4_log_full" == *"|update 1031 "* ]]; then
    t_pass "4.4 F2: provider_update called for TD body Resolution sync (gh-id 1031)"
else
    t_fail "4.4 F2: provider_update called for TD body Resolution sync (gh-id 1031)" \
        "no |update 1031 line in stub log; BATCH-17 F2 fix not wired"
fi
# Update should have body containing the canonical Resolution token
# `[YYYY-MM-DD, completed, promoted to phase-7]`. The stub records the
# raw args; the body is JSON-encoded inside the patch arg.
if [[ "$g4_log_full" == *"completed, promoted to phase-7"* ]]; then
    t_pass "4.4 F2: update body names canonical Resolution shape"
else
    t_fail "4.4 F2: update body names canonical Resolution shape" \
        "update_payload tail: $(printf '%s' "$g4_log_full" | tail -50)"
fi
if [[ "$g4_log_full" == *"## Resolution"* ]]; then
    t_pass "4.4 F2: update body has ## Resolution section heading"
else
    t_fail "4.4 F2: update body has ## Resolution section heading" \
        "update_payload tail: $(printf '%s' "$g4_log_full" | tail -50)"
fi

# 4.5 BATCH-17 F3 (cross-BD review): id-map.json saved to disk after
# provider_create. Without this, subsequent promote / link calls
# cannot resolve the new phase-N entity.
disk_map="$wt2/.pack-tracker/id-map.json"
if [[ -f "$disk_map" ]] && jq -e --arg k "phase-7" 'has($k)' "$disk_map" >/dev/null 2>&1; then
    t_pass "4.5 F3: id-map.json on disk has new phase-7 entry"
    new_id=$(jq -r --arg k "phase-7" '.[$k].id' "$disk_map")
    assert_eq "4.5 F3: phase-7 id matches stub create rc" "99" "$new_id"
else
    t_fail "4.5 F3: id-map.json on disk has new phase-7 entry" \
        "$(cat "$disk_map" 2>/dev/null)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 5: Path 1 reverse / round-trip
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Path 1 reverse / round-trip ===\n"

# Set up a worktree where TD-031's BACKLOG entry already names phase-7
# in its Resolution (post-promotion state).
wt3=$(mk_worktree "g5-reverse")
python3 - "$wt3/BACKLOG.md" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace(
    'Resolution: n/a',
    'Resolution: [2026-05-14, completed, promoted to phase-7]',
    1,
)
with open(path, 'w') as f:
    f.write(text)
PYEOF

reverse=$(tracker_promote_reverse_path1 "phase-7" "$wt3" 2>/dev/null)
assert_eq "5.1 reverse phase = phase-7" "phase-7" "$(printf '%s' "$reverse" | jq -r '.phase')"
assert_eq "5.1 reverse derived_from = TD-031" "TD-031" "$(printf '%s' "$reverse" | jq -r '.derived_from')"
assert_contains "5.1 reverse resolution names phase-7" "$(printf '%s' "$reverse" | jq -r '.resolution')" "phase-7"

# 5.2 SHA-256 round-trip identity. Build a known starting state, run
# Path 1 forward, then assert the BACKLOG sha is stable across a
# second forward (which must be refused by idempotency — verifying
# round-trip-safety).
wt4=$(mk_worktree "g5-roundtrip")
sha_before=$(shasum -a 256 "$wt4/BACKLOG.md" | cut -d' ' -f1)
plan_before=$(shasum -a 256 "$wt4/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)

# First forward run.
tracker_promote_path1 "TD-031" "phase-7" "$wt4" 1 >/dev/null 2>&1

# Capture post-state. PM Chat would write Resolution to BACKLOG; the
# library returns the patch text (via .resolution_text in the result),
# leaving BACKLOG mutation to PM Chat. We simulate the patch here.
python3 - "$wt4/BACKLOG.md" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
text = text.replace(
    'Resolution: n/a',
    'Resolution: [2026-05-14, completed, promoted to phase-7]',
    1,
)
with open(path, 'w') as f:
    f.write(text)
PYEOF

# Second forward run is refused by idempotency — round-trip safety:
# replay yields no additional plan or backlog mutation.
sha_after=$(shasum -a 256 "$wt4/BACKLOG.md" | cut -d' ' -f1)
plan_after=$(shasum -a 256 "$wt4/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)
err=$(tracker_promote_path1 "TD-031" "phase-7" "$wt4" 1 2>&1) || true
sha_replay=$(shasum -a 256 "$wt4/BACKLOG.md" | cut -d' ' -f1)
plan_replay=$(shasum -a 256 "$wt4/IMPLEMENTATION-PLAN.md" | cut -d' ' -f1)
assert_eq "5.2 BACKLOG SHA stable across replay (round-trip safety)" \
    "$sha_after" "$sha_replay"
assert_eq "5.2 IMPLEMENTATION-PLAN SHA stable across replay" \
    "$plan_after" "$plan_replay"
# And the SHA actually changed between before and after the first run.
if [[ "$plan_before" != "$plan_after" ]]; then
    t_pass "5.2 IMPLEMENTATION-PLAN mutated by first forward run"
else
    t_fail "5.2 IMPLEMENTATION-PLAN mutated by first forward run" \
        "expected SHA change after Path 1 forward; got identity"
fi

# ─────────────────────────────────────────────────────────────────
# Group 6: label invariants (V3.3 §3.5)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: label invariants (V3.3 §3.5) ===\n"

# 6.1/6.2 labels named in result (already verified in 3.3); re-assert.
labels=$(printf '%s' "$result" | jq -r '.labels_created | join(",")')
assert_contains "6.1 derived-from on phase epic" "$labels" "derived-from:TD-031"
assert_eq "6.2 promoted-to on closed TD" "promoted-to:phase-7" "$(printf '%s' "$result" | jq -r '.promoted_to')"

# 6.3 NO folded-into anywhere in the result JSON
result_str="$result $result2"
assert_not_contains "6.3 NO folded-into in Path 1 result" "$result_str" "folded-into"
assert_not_contains "6.3 NO folded-into in plan content"  "$(cat "$wt/IMPLEMENTATION-PLAN.md")" "folded-into"

# 6.4 NO tracker_labels_folded_into helper exists
if declare -f tracker_labels_folded_into >/dev/null 2>&1; then
    t_fail "6.4 NO folded-into helper (Path 3 forbidden)" \
        "tracker_labels_folded_into is defined; V3.3 §3 line 27 forbids this"
else
    t_pass "6.4 NO folded-into helper (Path 3 forbidden per V3.3 §3 line 27)"
fi

# Source-corpus grep for folded-into in the new orchestrator. The
# library may legitimately mention "folded-into" in comments that
# document the prohibition; we only assert the absence of any function
# definition or label constructor.
if grep -qE '^[[:space:]]*tracker_labels_folded_into[[:space:]]*\(' \
    "$LIB_DIR/tracker-promote.sh"; then
    t_fail "6.4 grep: no folded-into constructor in tracker-promote.sh"
else
    t_pass "6.4 grep: no folded-into constructor in tracker-promote.sh"
fi

# ─────────────────────────────────────────────────────────────────
# Group 7: verb dispatcher integration (pack-td.sh)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 7: verb dispatcher integration (pack-td.sh) ===\n"

DISPATCHER="$REPO_ROOT/scripts/pack-td.sh"

# 7.1 promote --to=phase-N routes to Path 1
wt5=$(mk_worktree "g7-dispatcher")
out=$("$DISPATCHER" promote --to=phase-7 TD-031 --repo-root "$wt5" --flat-file-only 2>/dev/null)
assert_eq "7.1 dispatcher result td_id"   "TD-031"  "$(printf '%s' "$out" | jq -r '.td_id')"
assert_eq "7.1 dispatcher result target"  "phase-7" "$(printf '%s' "$out" | jq -r '.target')"
assert_eq "7.1 dispatcher result mode"    "flat-file" "$(printf '%s' "$out" | jq -r '.mode')"

# 7.2 dispatcher rejects --fold-into with typed error
err=$("$DISPATCHER" promote --fold-into=phase-3.2 TD-031 2>&1) || true
assert_contains "7.2 --fold-into rejected" "$err" "ERROR: validation"
assert_contains "7.2 --fold-into error names Path 3 forbidden" "$err" "Path 3 forbidden"

# 7.3 --help prints the verb manifest
help_out=$("$DISPATCHER" --help 2>&1)
assert_contains "7.3 --help names Path 1" "$help_out" "Path 1"
assert_contains "7.3 --help names Path 2" "$help_out" "Path 2"
assert_contains "7.3 --help names V3.3 §7.3" "$help_out" "V3.3 §7.3"

# Also: promote without --to fails clearly.
err=$("$DISPATCHER" promote TD-031 2>&1) || true
assert_contains "7.3 promote without --to → typed error" "$err" "ERROR: validation"

# 7.4 F1 (BD-107 review): value-less flag invocations must not crash
# with bash-internal "unbound variable" diagnostics — they must emit
# the canonical typed-error shape so downstream tools (PM Chat error
# renderer, CI harness) can parse them.
err=$("$DISPATCHER" promote --to 2>&1) || true
assert_contains "7.4 F1: --to without value → typed error" "$err" "ERROR: validation"
assert_contains "7.4 F1: --to error names requires a value" "$err" "requires a value"
assert_not_contains "7.4 F1: --to bash-internal unbound-variable not surfaced" "$err" "unbound variable"

err=$("$DISPATCHER" promote --to=phase-7 TD-031 --repo-root 2>&1) || true
assert_contains "7.4 F1: --repo-root without value → typed error" "$err" "ERROR: validation"
assert_not_contains "7.4 F1: --repo-root no bash-internal unbound" "$err" "unbound variable"

err=$("$DISPATCHER" promote --to=phase-7.4 TD-040 --store-path 2>&1) || true
assert_contains "7.4 F1: --store-path without value → typed error" "$err" "ERROR: validation"
assert_not_contains "7.4 F1: --store-path no bash-internal unbound" "$err" "unbound variable"

err=$("$DISPATCHER" resolve TD-031 --note 2>&1) || true
assert_contains "7.4 F1: resolve --note without value → typed error" "$err" "ERROR: validation"
assert_not_contains "7.4 F1: resolve --note no bash-internal unbound" "$err" "unbound variable"

# 7.5 F7 (BD-107 review): failure-path coverage. Override the stub
# tracker_provider_stub_create to fail (return rc=1 with no JSON
# output), then assert the orchestrator surfaces the failure as a
# typed partial-write error (not a silent success).
wt_f7=$(mk_tracker_worktree "g7-f7-failure")
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
# Save original and override.
_F7_ORIG_STUB_CREATE=$(declare -f tracker_provider_stub_create)
tracker_provider_stub_create() { return 1; }
err_f7=$(tracker_promote_path1 "TD-031" "phase-7" "$wt_f7" 0 2>&1) || true
# Restore stub.
eval "$_F7_ORIG_STUB_CREATE"
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
assert_contains "7.5 F7: provider_create failure → typed partial-write error" "$err_f7" "partial-write"
assert_contains "7.5 F7: failure-path message names provider_create" "$err_f7" "provider_create"
# F9 rollback: the plan-file mutation must be reverted (no `## Phase 7`
# heading after the failure).
plan_after_failure=$(grep -cE '^## Phase 7 ' "$wt_f7/IMPLEMENTATION-PLAN.md" 2>/dev/null || true)
plan_after_failure="${plan_after_failure:-0}"
if [[ "$plan_after_failure" -eq 0 ]]; then
    t_pass "7.5 F9: plan-file rollback after provider_create failure"
else
    t_fail "7.5 F9: plan-file rollback after provider_create failure" \
        "expected no ## Phase 7 heading; got grep count=$plan_after_failure"
fi

# ─────────────────────────────────────────────────────────────────
# Group 8: PM-CHAT.md + METHODOLOGY.md content sanity
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 8: PM-CHAT.md + METHODOLOGY.md content sanity ===\n"

pm_chat="$REPO_ROOT/project-template/docs/pack/PM-CHAT.md"
if grep -q "TD resolution orchestration" "$pm_chat"; then
    t_pass "8.1 PM-CHAT.md has TD resolution orchestration section"
else
    t_fail "8.1 PM-CHAT.md has TD resolution orchestration section"
fi
if grep -q "architect by default" "$pm_chat"; then
    t_pass "8.2 PM-CHAT.md names architect-default for Path 1"
else
    t_fail "8.2 PM-CHAT.md names architect-default for Path 1"
fi

method="$REPO_ROOT/supporting-docs/METHODOLOGY.md"
# Note (BD-204 C-4.6 F-4): the former `grep -q "V3.3 §3"` assertion was
# REMOVED. That internal `ARCHITECTURE-V3.3-DELTA §3` citation was stripped
# off the client-facing METHODOLOGY.md by BD-195/BD-200 (internal-ref cleanup
# on client surfaces). The promotion-paths SUBSTANCE remains — Path 3 is
# still forbidden (asserted below) and the Path 1/2/direct-close decision
# logic is intact — so the fix is test-only: drop the stale citation grep,
# keep the substance assertion. METHODOLOGY.md is NOT edited.
if grep -q "Path 3 is forbidden\|Path 3 forbidden" "$method"; then
    t_pass "8.3 METHODOLOGY.md names Path 3 forbidden"
else
    t_fail "8.3 METHODOLOGY.md names Path 3 forbidden"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
exit "$FAIL"
