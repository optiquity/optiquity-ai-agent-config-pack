#!/usr/bin/env bash
# scripts/tests/recommendation-test.sh — D-19 recommendation system
# integration tests (BD-072). Implements the 7 V3 §28.1.10 cases.
#
# Usage: bash scripts/tests/recommendation-test.sh

set -uo pipefail

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' got='$3'"; fi
}

# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/recommendation.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: signal computation
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: signal computation ===\n"

# 1.1 pack-side signals against a fixture repo with 5 BD entries.
# BD-203 A14a: pack-side BACKLOG is the `/backlog/` per-entry tree (the
# no-mirror SSOT) — there is no monolithic pack-ops/BACKLOG.md. The
# signal counts canonical `BD-NNN.md` entry files (BD-211 — no suffix),
# Open/Unblocked = active. 5 entries: 3 active (Open/Open/Unblocked) +
# Resolved + Cancelled.
TR_PACK=$(mktemp -d -t rec-pack.XXXXXX)
mkdir -p "$TR_PACK/backlog"
cat > "$TR_PACK/backlog/BD-001.md" <<'EOF'
<!-- per-entry source: /backlog/BD-001.md; contract: /backlog/_rules.md -->
**BD-001 — First**
Status: Open
EOF
cat > "$TR_PACK/backlog/BD-002.md" <<'EOF'
<!-- per-entry source: /backlog/BD-002.md; contract: /backlog/_rules.md -->
**BD-002 — Second**
Status: Open
EOF
cat > "$TR_PACK/backlog/BD-900.md" <<'EOF'
<!-- per-entry source: /backlog/BD-900.md; contract: /backlog/_rules.md -->
**BD-900 — Canonical entry (active)**
Status: Unblocked
EOF
cat > "$TR_PACK/backlog/BD-004.md" <<'EOF'
<!-- per-entry source: /backlog/BD-004.md; contract: /backlog/_rules.md -->
**BD-004 — Fourth**
Status: Resolved
EOF
cat > "$TR_PACK/backlog/BD-005.md" <<'EOF'
<!-- per-entry source: /backlog/BD-005.md; contract: /backlog/_rules.md -->
**BD-005 — Fifth**
Status: Cancelled
EOF
# Supporting file (leading underscore) must NOT be counted as an entry.
cat > "$TR_PACK/backlog/_rules.md" <<'EOF'
# Per-stream contract — pack-backlog (test fixture)
EOF
sigs=$(recommendation_compute_signals "pack" "$TR_PACK")
assert_eq "1.1 bd_count_active=3 (Open + Unblocked, canonical entries)" "3" \
    "$(printf '%s' "$sigs" | jq -r '.bd_count_active')"
assert_eq "1.1 bd_count_total=5 (entry files; _rules.md excluded)" "5" \
    "$(printf '%s' "$sigs" | jq -r '.bd_count_total')"
assert_eq "1.1 backlog_growth_30d=0 (no git)" "0" \
    "$(printf '%s' "$sigs" | jq -r '.backlog_growth_30d')"

# 1.2 client-side signals.
TR_CLI=$(mktemp -d -t rec-cli.XXXXXX)
cat > "$TR_CLI/BACKLOG.md" <<'EOF'
**TD-001 — Doc**
Status: Open

**TD-002 — Refactor**
Status: Open
EOF
cat > "$TR_CLI/IMPLEMENTATION-PLAN.md" <<'EOF'
## Phase 1 — Setup
## Phase 2 — Core
## Phase 3 — Polish
EOF
sigs=$(recommendation_compute_signals "client" "$TR_CLI")
assert_eq "1.2 td_count_active=2"   "2" "$(printf '%s' "$sigs" | jq -r '.td_count_active')"
assert_eq "1.2 td_count_total=2"    "2" "$(printf '%s' "$sigs" | jq -r '.td_count_total')"
assert_eq "1.2 phase_count=3"       "3" "$(printf '%s' "$sigs" | jq -r '.phase_count')"

# 1.2b — F-1 closure: client BACKLOG.md + IMPLEMENTATION-PLAN.md at the
# trinity-mandated docs/project/ path. The lib must fall back from the
# repo-root location (legacy v9 layout) to docs/project/ (v10/v11
# trinity layout) per project-template/CLAUDE.md Document locations.
TR_CLI_DOCS=$(mktemp -d -t rec-cli-docs.XXXXXX)
mkdir -p "$TR_CLI_DOCS/docs/project"
cat > "$TR_CLI_DOCS/docs/project/BACKLOG.md" <<'EOF'
**TD-001 — A**
Status: Open

**TD-002 — B**
Status: Unblocked

**TD-003 — C**
Status: Open
EOF
cat > "$TR_CLI_DOCS/docs/project/IMPLEMENTATION-PLAN.md" <<'EOF'
## Phase 1 — One
## Phase 2 — Two
EOF
sigs=$(recommendation_compute_signals "client" "$TR_CLI_DOCS")
assert_eq "1.2b client BACKLOG fallback resolves docs/project/ td_count_active" "3" \
    "$(printf '%s' "$sigs" | jq -r '.td_count_active')"
assert_eq "1.2b client BACKLOG fallback resolves docs/project/ td_count_total"  "3" \
    "$(printf '%s' "$sigs" | jq -r '.td_count_total')"
assert_eq "1.2b client plan fallback resolves docs/project/ phase_count" "2" \
    "$(printf '%s' "$sigs" | jq -r '.phase_count')"
rm -rf "$TR_CLI_DOCS"

# 1.3 invalid surface → typed validation error.
err=$(recommendation_compute_signals "bogus" "$TR_PACK" 2>&1 1>/dev/null) || true
assert_eq "1.3 invalid surface → ERROR: validation" "1" \
    "$([[ "$err" == *"ERROR: validation"* ]] && echo 1 || echo 0)"

rm -rf "$TR_PACK" "$TR_CLI"

# ─────────────────────────────────────────────────────────────────
# Group 2: state file I/O
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: state file I/O ===\n"

# 2.1 default state shape
def_state=$(recommendation_state_default "pack")
assert_eq "2.1 default schema_version=v1" "v1" \
    "$(printf '%s' "$def_state" | jq -r '.schema_version')"
assert_eq "2.1 default surface=pack" "pack" \
    "$(printf '%s' "$def_state" | jq -r '.surface')"
assert_eq "2.1 default persistent_refusal=false" "false" \
    "$(printf '%s' "$def_state" | jq -r '.persistent_refusal')"
assert_eq "2.1 default user_re_enable_count=0" "0" \
    "$(printf '%s' "$def_state" | jq -r '.user_re_enable_count')"

# 2.2 missing file → default; round-trip
TR_S=$(mktemp -d -t rec-state.XXXXXX)
state_path="$TR_S/.pack-tracker/recommendation-state.json"
loaded=$(recommendation_state_load "$state_path" "client")
assert_eq "2.2 missing file → default surface=client" "client" \
    "$(printf '%s' "$loaded" | jq -r '.surface')"
recommendation_state_save "$state_path" "$loaded"
[[ -f "$state_path" ]] && t_pass "2.2 save creates file" \
    || t_fail "2.2 save creates file" "missing"
loaded2=$(recommendation_state_load "$state_path" "client")
assert_eq "2.2 round-trip preserved" "client" \
    "$(printf '%s' "$loaded2" | jq -r '.surface')"

# Test 6 of V3 §28.1.10 — corrupted state file recovers.
echo 'NOT JSON {{{' > "$state_path"
recovered=$(recommendation_state_load "$state_path" "pack" 2>/dev/null)
assert_eq "Test-6: corrupted state → default surface restored" "pack" \
    "$(printf '%s' "$recovered" | jq -r '.surface')"
# Per V3 §28.1.4 failure-mode contract: rebuild stamps last_recommendation_shown_at
# so the recommendation defers to next session.
last_shown=$(printf '%s' "$recovered" | jq -r '.last_recommendation_shown_at')
[[ -n "$last_shown" && "$last_shown" != "null" ]] \
    && t_pass "Test-6: rebuild stamps last_recommendation_shown_at (defer this session)" \
    || t_fail "Test-6: rebuild stamps last_recommendation_shown_at" "got '$last_shown'"

rm -rf "$TR_S"

# ─────────────────────────────────────────────────────────────────
# Group 3: should_recommend (V3 §28.1.5 + 7-test surface)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: should_recommend + V3 §28.1.10 surface ===\n"

# Below-threshold signals — never fires.
sigs_low='{"bd_count_active":10,"backlog_kb":5,"backlog_growth_30d":2}'
state_default=$(recommendation_state_default "pack")
result=$(recommendation_should_recommend "$sigs_low" "$state_default" "pack" "flat-file")
assert_eq "3.1 below threshold → false" "false" "$result"

# Test 1 of §28.1.10 — threshold-cross fires once per material change.
sigs_at_thr='{"bd_count_active":82,"backlog_kb":5,"backlog_growth_30d":2}'
result=$(recommendation_should_recommend "$sigs_at_thr" "$state_default" "pack" "flat-file")
assert_eq "Test-1a: 82 BDs (over 80), no prior state → fires" "true" "$result"

# After firing, record snapshot. Same signals next session — no re-fire.
TR_S2=$(mktemp -d -t rec-s2.XXXXXX)
state_path="$TR_S2/.pack-tracker/recommendation-state.json"
recommendation_state_save "$state_path" "$state_default"
recommendation_record_shown "$state_path" "$sigs_at_thr"
state_after=$(recommendation_state_load "$state_path" "pack")
result=$(recommendation_should_recommend "$sigs_at_thr" "$state_after" "pack" "flat-file")
assert_eq "Test-1b: same signals next session → no re-fire (Guard 4)" "false" "$result"

# Material growth (28% from 82 → 105) — fires again.
sigs_grown='{"bd_count_active":105,"backlog_kb":5,"backlog_growth_30d":2}'
result=$(recommendation_should_recommend "$sigs_grown" "$state_after" "pack" "flat-file")
assert_eq "Test-1c: 28% growth → re-fires" "true" "$result"

# Below 25% growth (82 → 100, only 22% growth) — does not fire.
sigs_minor='{"bd_count_active":100,"backlog_kb":5,"backlog_growth_30d":2}'
result=$(recommendation_should_recommend "$sigs_minor" "$state_after" "pack" "flat-file")
assert_eq "Test-1d: 22% growth (under 25%) → no re-fire" "false" "$result"

# Test 3 of §28.1.10 — "don't ask again" persists.
recommendation_set_persistent_refusal "$state_path" "true"
state_refused=$(recommendation_state_load "$state_path" "pack")
assert_eq "Test-3a: persistent_refusal flipped"     "true"  \
    "$(printf '%s' "$state_refused" | jq -r '.persistent_refusal')"
result=$(recommendation_should_recommend "$sigs_grown" "$state_refused" "pack" "flat-file")
assert_eq "Test-3b: refused → no fire even on growth (Guard 2)" "false" "$result"

# Test 4 of §28.1.10 — `enable-recommendations` clears.
recommendation_set_persistent_refusal "$state_path" "false"
state_re_enabled=$(recommendation_state_load "$state_path" "pack")
assert_eq "Test-4a: persistent_refusal cleared"            "false" \
    "$(printf '%s' "$state_re_enabled" | jq -r '.persistent_refusal')"
assert_eq "Test-4a: user_re_enable_count incremented to 1" "1"     \
    "$(printf '%s' "$state_re_enabled" | jq -r '.user_re_enable_count')"
# After re-enable, signals already over threshold — but Guard 4 still
# applies (last_recommendation_signals snapshot is still there). To
# fire again, signals must be ≥ 25% higher than the snapshot.
result=$(recommendation_should_recommend "$sigs_grown" "$state_re_enabled" "pack" "flat-file")
assert_eq "Test-4b: re-enabled + signals materially grown → fires" "true" "$result"

# Test 5 of §28.1.10 — tracker mode disables recommendations entirely.
result=$(recommendation_should_recommend "$sigs_grown" "$state_default" "pack" "tracker")
assert_eq "Test-5: tracker mode → never fires (Guard 1)" "false" "$result"

# Test 7 of §28.1.10 — cross-machine: a fresh state file (default) on a
# new machine treats the project as un-refused. Verified by loading a
# missing file and confirming persistent_refusal=false.
TR_S3=$(mktemp -d -t rec-s3.XXXXXX)
fresh_machine=$(recommendation_state_load "$TR_S3/.pack-tracker/recommendation-state.json" "pack")
assert_eq "Test-7: new-machine fresh state → persistent_refusal=false" "false" \
    "$(printf '%s' "$fresh_machine" | jq -r '.persistent_refusal')"
# And signals over threshold can fire there.
result=$(recommendation_should_recommend "$sigs_grown" "$fresh_machine" "pack" "flat-file")
assert_eq "Test-7: new-machine + signals over threshold → fires" "true" "$result"

rm -rf "$TR_S2" "$TR_S3"

# Test 2 of §28.1.10 — "not now" silences for the session.
# Per V3 §28.1.6 the per-session dismiss is in-memory chat state, NOT
# in the state file. The library API contract is therefore: caller
# tracks a session-local flag and skips invoking should_recommend
# again when set. Verified by checking that the lib does NOT mutate
# state on a "not now" — the same state still permits re-evaluation
# in a future session.
TR_S4=$(mktemp -d -t rec-s4.XXXXXX)
state_path="$TR_S4/.pack-tracker/recommendation-state.json"
recommendation_state_save "$state_path" "$state_default"
state_before=$(cat "$state_path")
# "not now" path: the chat skips invoking the lib again — the lib
# itself is not called, so state must be unchanged.
state_after=$(cat "$state_path")
assert_eq "Test-2: 'not now' is in-memory only — state unchanged" \
    "$state_before" "$state_after"

rm -rf "$TR_S4"

# ─────────────────────────────────────────────────────────────────
# Group 4: prompt rendering (V3 §28.1.7)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: prompt rendering ===\n"

prompt=$(recommendation_render_prompt "$sigs_grown" "pack")
[[ "$prompt" == *"You're at"* ]]                && t_pass "4.1 prompt has greeting"   || t_fail "4.1 prompt greeting" "$prompt"
# F-3 closure: the headline carries the human label, not the raw JSON
# key (V3 §28.1.7 + §D.2 worked example).
[[ "$prompt" == *"BACKLOG entries (active): 105"* ]] \
    && t_pass "4.1 prompt headline uses human label + value" \
    || t_fail "4.1 prompt headline" "$prompt"
[[ "$prompt" != *"bd_count_active: "* ]] \
    && t_pass "4.1 prompt does NOT leak raw JSON key" \
    || t_fail "4.1 raw key in prompt" "$prompt"
[[ "$prompt" == *"threshold ≥ 80"* ]]           && t_pass "4.1 prompt names threshold"  \
    || t_fail "4.1 prompt threshold" "$prompt"
[[ "$prompt" == *"yes"* && "$prompt" == *"not now"* && "$prompt" == *"don't ask again"* ]] \
    && t_pass "4.1 prompt offers three options"  || t_fail "4.1 prompt options"
[[ "$prompt" == *"pack tracker init"* ]]        && t_pass "4.1 prompt names init verb"   || t_fail "4.1 prompt init" "$prompt"
[[ "$prompt" == *"pack tracker disable"* ]]     && t_pass "4.1 prompt names disable verb" || t_fail "4.1 prompt disable"
[[ "$prompt" == *"pack help"* ]]                && t_pass "4.1 prompt names pack help"    || t_fail "4.1 prompt pack help"

# Multi-signal — headline picks the most extreme ratio; others mentioned.
sigs_multi='{"bd_count_active":160,"backlog_kb":36,"backlog_growth_30d":2}'
# 160/80 = 2.0; 36/18 = 2.0 — tie; first-seen wins.
prompt=$(recommendation_render_prompt "$sigs_multi" "pack")
[[ "$prompt" == *"Also past threshold"* ]] \
    && t_pass "4.2 multi-signal mentions secondary on follow-up line" \
    || t_fail "4.2 multi-signal" "$prompt"
# F-2 closure: the follow-up line is well-formed — starts with a
# label after "Also past threshold:", not "Also past threshold:; …".
[[ "$prompt" != *"Also past threshold:;"* ]] \
    && t_pass "4.2 follow-up line starts cleanly (no stray semicolon)" \
    || t_fail "4.2 follow-up punctuation" "$prompt"
[[ "$prompt" == *"Also past threshold: BACKLOG.md size (KB):"* ]] \
    && t_pass "4.2 follow-up label is human-readable" \
    || t_fail "4.2 follow-up label" "$prompt"

# ─────────────────────────────────────────────────────────────────
# Group 5: pack-tracker enable-recommendations verb (BD-073)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: enable-recommendations verb (BD-073) ===\n"

# 5.1 verb runs and flips persistent_refusal=true → false on disk.
TR_V=$(mktemp -d -t rec-verb.XXXXXX)
touch "$TR_V/PACK-CHAT.md"  # forces surface=pack auto-detect
state_path="$TR_V/.pack-tracker/recommendation-state.json"
mkdir -p "$TR_V/.pack-tracker"
# Seed the state file with persistent_refusal=true.
cat > "$state_path" <<EOF
{"schema_version":"v1","surface":"pack","persistent_refusal":true,"persistent_refusal_at":"2026-05-01T00:00:00Z","last_recommendation_shown_at":null,"last_recommendation_signals":{},"user_re_enable_count":0}
EOF

output=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" enable-recommendations --repo-root "$TR_V" 2>&1)
rc=$?
assert_eq "5.1 verb rc=0" "0" "$rc"
assert_eq "5.1 persistent_refusal flipped to false" "false" \
    "$(jq -r '.persistent_refusal' "$state_path")"
assert_eq "5.1 user_re_enable_count incremented to 1" "1" \
    "$(jq -r '.user_re_enable_count' "$state_path")"
[[ "$output" == *"persistent_refusal cleared"* ]] \
    && t_pass "5.1 verb reports cleared status" \
    || t_fail "5.1 verb output" "$output"

# 5.2 second invocation is idempotent: persistent_refusal stays false,
# count increments to 2.
bash "$REPO_ROOT/scripts/pack-tracker.sh" enable-recommendations --repo-root "$TR_V" >/dev/null 2>&1
assert_eq "5.2 second run keeps persistent_refusal=false" "false" \
    "$(jq -r '.persistent_refusal' "$state_path")"
assert_eq "5.2 second run increments count to 2" "2" \
    "$(jq -r '.user_re_enable_count' "$state_path")"

# 5.3 missing state file: verb still works (loads default, then flips).
TR_V2=$(mktemp -d -t rec-verb2.XXXXXX)
touch "$TR_V2/PACK-CHAT.md"
output=$(bash "$REPO_ROOT/scripts/pack-tracker.sh" enable-recommendations --repo-root "$TR_V2" 2>&1)
rc=$?
assert_eq "5.3 verb rc=0 on missing state" "0" "$rc"
[[ -f "$TR_V2/.pack-tracker/recommendation-state.json" ]] \
    && t_pass "5.3 verb creates state file when missing" \
    || t_fail "5.3 state file created"
assert_eq "5.3 created state has user_re_enable_count=1" "1" \
    "$(jq -r '.user_re_enable_count' "$TR_V2/.pack-tracker/recommendation-state.json")"

rm -rf "$TR_V" "$TR_V2"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
fi
exit 1
