#!/usr/bin/env bash
# scripts/tests/tracker-migrate-forward-test.sh — offline test suite
# for V1 §6.2 forward migration (BD-065).
#
# Three groups:
#   1. Parser correctness — fixture BACKLOG / IMPLEMENTATION_PLAN
#      parse to expected JSON shapes.
#   2. Helpers — mapping load/save, checkpoint write/read/clear,
#      issue-body composer, label set, mirror header.
#   3. Integration — end-to-end forward run against a temp repo with
#      a PATH-prepended fake `gh` that captures every gh invocation.
#      Asserts: right number of `issue create` calls; right title/body
#      shapes; mapping file populated correctly; second run is
#      idempotent (zero new creates).
#
# Usage: bash scripts/tests/tracker-migrate-forward-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-migrate"

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

# Source all libs the same way tracker-migrate.sh does.
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

# ─────────────────────────────────────────────────────────────────
# Group 1: parser correctness
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: parser correctness ===\n"

entries=$(tmf_parse_backlog "$FIXTURES/BACKLOG.md")
assert_eq "1.1 BACKLOG parses 5 entries" "5"        "$(printf '%s' "$entries" | jq 'length')"
assert_eq "1.1 entry[0].pack_id"          "BD-001"  "$(printf '%s' "$entries" | jq -r '.[0].pack_id')"
assert_eq "1.1 entry[0].status"           "Open"    "$(printf '%s' "$entries" | jq -r '.[0].status')"
assert_eq "1.1 entry[0].file_symbol"      "scripts/foo.sh" "$(printf '%s' "$entries" | jq -r '.[0].file_symbol')"
assert_contains "1.1 entry[0].description multi-line" \
    "$(printf '%s' "$entries" | jq -r '.[0].description')" "Multi-line continuation"
assert_eq "1.1 entry[1].blockers count=2" "2"      "$(printf '%s' "$entries" | jq '.[1].blockers | length')"
assert_eq "1.1 entry[1].blockers[0]"      "BD-001" "$(printf '%s' "$entries" | jq -r '.[1].blockers[0]')"
assert_eq "1.1 entry[1].blockers[1]"      "phase-1" "$(printf '%s' "$entries" | jq -r '.[1].blockers[1]')"
assert_eq "1.1 entry[2].status"           "Resolved" "$(printf '%s' "$entries" | jq -r '.[2].status')"
assert_contains "1.1 entry[2].resolution captures commit" \
    "$(printf '%s' "$entries" | jq -r '.[2].resolution')" "abc1234"
assert_eq "1.1 entry[3].pack_id"          "TD-010"  "$(printf '%s' "$entries" | jq -r '.[3].pack_id')"
assert_eq "1.1 entry[4].status"           "Cancelled" "$(printf '%s' "$entries" | jq -r '.[4].status')"

phases=$(tmf_parse_implementation_plan "$FIXTURES/IMPLEMENTATION_PLAN.md")
assert_eq "1.2 plan parses 2 phases" "2" "$(printf '%s' "$phases" | jq 'length')"
assert_eq "1.2 phase[0].number"      "1" "$(printf '%s' "$phases" | jq -r '.[0].phase_number')"
assert_eq "1.2 phase[0].title"       "Foundations" "$(printf '%s' "$phases" | jq -r '.[0].title')"
assert_eq "1.2 phase[1].number"      "2" "$(printf '%s' "$phases" | jq -r '.[1].phase_number')"

# Empty / missing inputs surface typed errors.
err=$(tmf_parse_backlog "/no/such/BACKLOG.md" 2>&1 1>/dev/null) || true
assert_contains "1.3 missing BACKLOG → not-found" "$err" "ERROR: not-found"

# ─────────────────────────────────────────────────────────────────
# Group 2: helpers
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: helpers ===\n"

# 2.1 mapping load on missing file → empty object
tmpdir=$(mktemp -d -t tmf-test-helpers.XXXXXX)
m=$(tmf_mapping_load "$tmpdir/nope.json")
assert_eq "2.1 load missing → {}" "{}" "$(printf '%s' "$m" | jq -c .)"

# 2.2 set + get round-trip
m=$(tmf_mapping_set "$m" "BD-001" "42" "https://example/42")
m=$(tmf_mapping_set "$m" "TD-010" "99" "https://example/99")
assert_eq "2.2 mapping_get BD-001" "42" "$(tmf_mapping_get "$m" "BD-001")"
assert_eq "2.2 mapping_get TD-010" "99" "$(tmf_mapping_get "$m" "TD-010")"
if tmf_mapping_get "$m" "BD-999" >/dev/null 2>&1; then
    t_fail "2.2 missing key rc=1" "got rc=0"
else
    t_pass "2.2 missing key rc=1"
fi

# 2.3 save + reload round-trip
mfile="$tmpdir/id-map.json"
tmf_mapping_save "$mfile" "$m"
loaded=$(tmf_mapping_load "$mfile")
assert_eq "2.3 save/load round-trip BD-001 id" "42" "$(tmf_mapping_get "$loaded" "BD-001")"

# 2.4 checkpoint write + load + clear
ckp="$tmpdir/forward.checkpoint.json"
state=$(jq -n '{last_step: "step-4", completed_pack_ids: ["BD-001","BD-002"], timestamp: "2026-05-06T00:00:00Z"}')
tmf_checkpoint_write "$ckp" "$state"
loaded_ckp=$(tmf_checkpoint_load "$ckp")
assert_eq "2.4 checkpoint last_step"   "step-4" "$(printf '%s' "$loaded_ckp" | jq -r '.last_step')"
assert_eq "2.4 checkpoint completed_count" "2"  "$(printf '%s' "$loaded_ckp" | jq '.completed_pack_ids | length')"
tmf_checkpoint_clear "$ckp"
[[ ! -f "$ckp" ]] && t_pass "2.4 checkpoint cleared" || t_fail "2.4 checkpoint cleared"

# 2.5 issue-body composer
body=$(tmf_compose_issue_body "BD-001" "desc text" "ctx text" "")
assert_contains "2.5 body has pack-id marker"          "$body" "<!-- pack-id: BD-001 -->"
assert_contains "2.5 body has bd-v11.0 template_version" "$body" "<!-- template_version: bd-v11.0 -->"
assert_contains "2.5 body has pack-version: v11"       "$body" "<!-- pack-version: v11 -->"
assert_contains "2.5 body has Description section"     "$body" "## Description"
assert_contains "2.5 body has description text"        "$body" "desc text"
assert_contains "2.5 body has Context section"         "$body" "## Context"
if printf '%s' "$body" | grep -q "^## Resolution"; then
    t_fail "2.5 body Resolution absent when empty" "Resolution section unexpectedly present"
else
    t_pass "2.5 body Resolution absent when empty"
fi
# TD entries get td-v11.0 template_version
body_td=$(tmf_compose_issue_body "TD-010" "td desc" "" "")
assert_contains "2.5 td body has td-v11.0 marker" "$body_td" "<!-- template_version: td-v11.0 -->"
# Resolution section appears when resolution is non-empty
body_res=$(tmf_compose_issue_body "BD-003" "d" "" "fixed in abc")
assert_contains "2.5 body has Resolution section" "$body_res" "## Resolution"
assert_contains "2.5 body has resolution text"    "$body_res" "fixed in abc"

# 2.6 label set composer
labels_open=$(_tmf_labels_for_entry '{"pack_id":"BD-001","status":"Open"}')
assert_eq "2.6 labels Open count=3"          "3"            "$(printf '%s' "$labels_open" | jq 'length')"
assert_contains "2.6 labels has bd-entry"    "$labels_open" '"bd-entry"'
assert_contains "2.6 labels has template:bd" "$labels_open" '"template:bd-v11.0"'
assert_contains "2.6 labels has status:open" "$labels_open" '"status:open"'
labels_resolved=$(_tmf_labels_for_entry '{"pack_id":"TD-010","status":"Resolved"}')
assert_contains "2.6 td-entry label"           "$labels_resolved" '"td-entry"'
assert_contains "2.6 status:resolved"          "$labels_resolved" '"status:resolved"'

# 2.7 mirror header
header=$(tmf_mirror_header "test-org/test-repo")
assert_contains "2.7 header opens with comment"     "$header" "<!--"
assert_contains "2.7 header names tracker mode"     "$header" "read-only mirror"
assert_contains "2.7 header includes backend slug"  "$header" "test-org/test-repo"
assert_contains "2.7 header has ISO timestamp"      "$header" "Last regenerated"
assert_contains "2.7 header closes comment"         "$header" "-->"

rm -rf "$tmpdir"

# ─────────────────────────────────────────────────────────────────
# Group 3: integration (PATH-prepended fake gh)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: integration with fake gh ===\n"

# Set up a fake-gh bin dir + log file. The fake gh records each
# invocation and can be programmed via env vars to return canned
# stdout for `gh issue list` / `gh issue create` etc.
FAKE_BIN=$(mktemp -d -t tmf-fakebin.XXXXXX)
GH_LOG=$(mktemp -t tmf-ghlog.XXXXXX)
ISSUE_COUNTER_FILE=$(mktemp -t tmf-counter.XXXXXX)
echo "100" > "$ISSUE_COUNTER_FILE"

cat > "$FAKE_BIN/gh" <<FAKEGH
#!/usr/bin/env bash
# Fake gh for tracker-migrate-forward tests. Captures every invocation
# in \$FAKE_GH_LOG. Returns canned content per subcommand.
printf '%s\n' "\$*" >> "$GH_LOG"

case "\$1 \$2" in
    "issue create")
        # Increment counter and emit the synthesized URL.
        counter=\$(cat "$ISSUE_COUNTER_FILE")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_FILE"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close"|"issue reopen"|"issue edit"|"issue comment")
        # No stdout needed for these — caller doesn't parse.
        ;;
    "search issues")
        # Default: empty result set (no marker found upstream).
        # Forces all entries down the create path.
        echo '[]'
        ;;
    "issue list")
        echo '[]'
        ;;
    "issue view")
        # Return labels-empty / assignees-empty payload.
        echo '{"labels":[], "assignees":[]}'
        ;;
    "repo view")
        echo '{"nameWithOwner":"fixture-org/fixture-repo"}'
        ;;
    "api graphql")
        echo '{}'
        ;;
    "extension list")
        echo ""
        ;;
    *)
        # Unhandled — return success with empty stdout.
        ;;
esac
exit 0
FAKEGH
chmod +x "$FAKE_BIN/gh"
export PATH="$FAKE_BIN:$PATH"

if [[ "$(command -v gh)" != "$FAKE_BIN/gh" ]]; then
    printf "FATAL: PATH not properly prepended (got %s)\n" "$(command -v gh)" >&2
    exit 2
fi

# Build a temp repo seeded from the fixtures.
TEST_REPO=$(mktemp -d -t tmf-repo.XXXXXX)
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION_PLAN.md" "$TEST_REPO/IMPLEMENTATION_PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO/tracker.toml"

# Override the dispatcher to keep pointing at github (the stub fixture
# tracker.toml has backend.name=stub, but we want the gh backend for
# this test since we have a PATH-mocked gh).
export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"

# 3.1 first run creates issues.
output=$(tracker_migrate_forward_run "$TEST_REPO" 0 0 2>&1)
rc=$?
assert_eq "3.1 first run rc=0" "0" "$rc"
assert_contains "3.1 reports 5 entries"  "$output" "parsed 5 BACKLOG entries"
assert_contains "3.1 reports 2 phases"   "$output" "2 phase(s)"
assert_contains "3.1 reports complete"   "$output" "forward: complete"

# 3.2 fake gh log captured `issue create` per entry + per phase.
n_creates=$(grep -c "^issue create " "$GH_LOG" || true)
# 5 BACKLOG entries + 2 phase epics = 7 creates expected.
assert_eq "3.2 issue create called 7 times (5 entries + 2 phases)" "7" "$n_creates"

# 3.3 fake gh log captured at least 1 `issue close` (BD-003 Resolved + TD-011 Cancelled).
n_closes=$(grep -c "^issue close " "$GH_LOG" || true)
[[ "$n_closes" -ge 2 ]] && t_pass "3.3 issue close called for resolved/cancelled entries (count=$n_closes)" \
    || t_fail "3.3 issue close" "expected ≥2, got $n_closes"

# 3.4 mapping file written.
mfile="$TEST_REPO/.pack-tracker/id-map.json"
[[ -f "$mfile" ]] && t_pass "3.4 mapping file written" \
    || t_fail "3.4 mapping file written" "missing $mfile"
n_mapped=$(jq 'length' "$mfile")
# 5 BACKLOG entries + 2 phases = 7 mapping entries.
assert_eq "3.4 mapping has 7 entries" "7" "$n_mapped"

# 3.5 mapping has the expected pack ids.
for pid in BD-001 BD-002 BD-003 TD-010 TD-011 phase-1 phase-2; do
    if jq -e --arg k "$pid" 'has($k)' "$mfile" >/dev/null; then
        t_pass "3.5 mapping has $pid"
    else
        t_fail "3.5 mapping has $pid" "missing"
    fi
done

# 3.6 BACKLOG.md mirror header was added in place.
first_line=$(head -n 1 "$TEST_REPO/BACKLOG.md")
assert_eq "3.6 BACKLOG mirror header line 1" "<!--" "$first_line"
assert_contains "3.6 BACKLOG mirror header text" \
    "$(head -n 5 "$TEST_REPO/BACKLOG.md" | tr '\n' ' ')" "read-only mirror"

# 3.7 tracker.toml updated with last_forward_run.
assert_contains "3.7 tracker.toml has last_forward_run" \
    "$(cat "$TEST_REPO/tracker.toml")" "last_forward_run = \""

# 3.8 idempotency: second run produces 0 new creates.
> "$GH_LOG"
output2=$(tracker_migrate_forward_run "$TEST_REPO" 0 0 2>&1)
rc2=$?
assert_eq "3.8 second run rc=0" "0" "$rc2"
n_creates_2=$(grep -c "^issue create " "$GH_LOG" || true)
assert_eq "3.8 second run: 0 new creates" "0" "$n_creates_2"
# Mapping file count unchanged.
n_mapped_2=$(jq 'length' "$mfile")
assert_eq "3.8 mapping count unchanged" "$n_mapped" "$n_mapped_2"

# 3.9 dry-run mode: parser runs, no creates.
> "$GH_LOG"
TEST_REPO2=$(mktemp -d -t tmf-repo-dry.XXXXXX)
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO2/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION_PLAN.md" "$TEST_REPO2/IMPLEMENTATION_PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO2/tracker.toml"
output3=$(tracker_migrate_forward_run "$TEST_REPO2" 1 0 2>&1)
rc3=$?
assert_eq "3.9 dry-run rc=0"           "0" "$rc3"
assert_contains "3.9 dry-run prints summary" "$output3" "parsed 5 BACKLOG entries"
assert_contains "3.9 dry-run stops after parse" "$output3" "stopping after parse"
n_creates_3=$(grep -c "^issue create " "$GH_LOG" || true)
assert_eq "3.9 dry-run: 0 creates" "0" "$n_creates_3"
[[ ! -d "$TEST_REPO2/.pack-tracker" ]] && t_pass "3.9 dry-run: no .pack-tracker dir created" \
    || t_fail "3.9 dry-run: no .pack-tracker dir created"

# 3.10 status subcommand reports mode + mapping freshness.
status_out=$(tracker_migrate_status_report "$TEST_REPO" 2>&1)
assert_contains "3.10 status reports mapping file"  "$status_out" "mapping file:"
assert_contains "3.10 status reports last forward"  "$status_out" "last forward run:"

# 3.11 missing tracker.toml: forward fails with typed error.
TEST_REPO3=$(mktemp -d -t tmf-repo-noconf.XXXXXX)
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO3/BACKLOG.md"
err=$(tracker_migrate_forward_run "$TEST_REPO3" 0 0 2>&1) || true
assert_contains "3.11 missing tracker.toml → validation" "$err" "ERROR: validation"
assert_contains "3.11 error mentions pack tracker init" "$err" "pack tracker init"

# Cleanup.
rm -rf "$FAKE_BIN" "$GH_LOG" "$ISSUE_COUNTER_FILE" "$TEST_REPO" "$TEST_REPO2" "$TEST_REPO3"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
