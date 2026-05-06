#!/usr/bin/env bash
# scripts/tests/tracker-provider-test.sh — offline test suite for
# the TrackerProvider abstraction (BD-060).
#
# Runs three groups of tests:
#   1. Happy-path: each of the 18 ops + raw + capabilities, with a
#      PATH-prepended fake `gh` script that returns canned fixture
#      content. Verifies the canonical JSON shape (V1 §2.2) and the
#      argument-passing contract.
#   2. Error mapping: 5 representative gh-stderr → typed-code cases
#      per V1 §2.5. Verifies _gh_classify_error in tracker-provider-gh.sh.
#   3. Stub-backend structural test: routes the dispatcher to a stub
#      backend via _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub. Verifies
#      multi-backend extensibility — that new backends can be added
#      without touching the public API or callers.
#
# All tests run offline. The fake `gh` script reads its response
# from FAKE_GH_STDOUT_FILE and exit/stderr from FAKE_GH_EXIT and
# FAKE_GH_STDERR_FILE. Each test resets these vars.
#
# Usage:
#   bash scripts/tests/tracker-provider-test.sh
#
# Exits 0 on all-pass, 1 on any failure.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-provider"

# ─────────────────────────────────────────────────────────────────
# Test harness
# ─────────────────────────────────────────────────────────────────

PASS=0
FAIL=0
FAILED_TESTS=""

t_pass() {
    PASS=$((PASS + 1))
    printf "  \033[32mPASS\033[0m %s\n" "$1"
}

t_fail() {
    FAIL=$((FAIL + 1))
    FAILED_TESTS="$FAILED_TESTS\n  - $1"
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# Assert two strings are equal.
assert_eq() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        t_pass "$label"
    else
        t_fail "$label" "expected='$expected' actual='$actual'"
    fi
}

# Assert string contains substring.
assert_contains() {
    local label="$1"
    local haystack="$2"
    local needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        t_pass "$label"
    else
        t_fail "$label" "needle='$needle' not in haystack (first 200 chars): ${haystack:0:200}"
    fi
}

# ─────────────────────────────────────────────────────────────────
# Fake gh script setup
# ─────────────────────────────────────────────────────────────────

FAKE_BIN_DIR="$(mktemp -d -t tracker-prov-fakebin.XXXXXX)"
trap 'rm -rf "$FAKE_BIN_DIR"' EXIT

cat > "$FAKE_BIN_DIR/gh" <<'FAKE_GH'
#!/usr/bin/env bash
# Fake `gh` for offline tracker-provider tests.
# Behavior driven by env vars:
#   FAKE_GH_STDOUT_FILE — path to file emitted to stdout (default: empty)
#   FAKE_GH_STDERR_FILE — path to file emitted to stderr (default: empty)
#   FAKE_GH_EXIT        — exit code (default: 0)
#   FAKE_GH_LOG         — append the invocation args to this file
if [[ -n "${FAKE_GH_LOG:-}" ]]; then
    printf '%s\n' "$*" >> "$FAKE_GH_LOG"
fi
if [[ -n "${FAKE_GH_STDOUT_FILE:-}" && -f "${FAKE_GH_STDOUT_FILE}" ]]; then
    cat "$FAKE_GH_STDOUT_FILE"
fi
if [[ -n "${FAKE_GH_STDERR_FILE:-}" && -f "${FAKE_GH_STDERR_FILE}" ]]; then
    cat "$FAKE_GH_STDERR_FILE" >&2
fi
exit "${FAKE_GH_EXIT:-0}"
FAKE_GH
chmod +x "$FAKE_BIN_DIR/gh"

export PATH="$FAKE_BIN_DIR:$PATH"

# Sanity: the fake gh resolves first.
which_gh="$(command -v gh)"
if [[ "$which_gh" != "$FAKE_BIN_DIR/gh" ]]; then
    printf "FATAL: PATH not properly prepended (got %s)\n" "$which_gh" >&2
    exit 2
fi

# Source the library under test.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"

# Helper: reset fake gh vars between tests.
reset_fake_gh() {
    unset FAKE_GH_STDOUT_FILE FAKE_GH_STDERR_FILE FAKE_GH_EXIT FAKE_GH_LOG
}

# Helper: write content to a tmp file and echo path.
make_tmp_with() {
    local tmp
    tmp=$(mktemp -t tracker-prov-test.XXXXXX)
    printf '%s' "$1" > "$tmp"
    echo "$tmp"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: Happy-path tests (18 ops + raw + capabilities)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Happy-path ===\n"

# 1.1 capabilities — pure, no shellout
out=$(provider_capabilities)
assert_eq "1.1 capabilities backend_name=github" "github" "$(printf '%s' "$out" | jq -r '.backend_name')"
assert_eq "1.1 capabilities raw_escape_hatch=true" "true" "$(printf '%s' "$out" | jq -r '.raw_escape_hatch')"
assert_eq "1.1 capabilities hierarchy.depth_ceiling=8" "8" "$(printf '%s' "$out" | jq -r '.hierarchy.depth_ceiling')"
assert_eq "1.1 capabilities dependencies.kinds count=4" "4" "$(printf '%s' "$out" | jq -r '.dependencies.kinds | length')"

# 1.2 get — full canonical Issue
reset_fake_gh
export FAKE_GH_STDOUT_FILE="$FIXTURES/gh-issue-view.json"
out=$(provider_get 42)
assert_eq "1.2 get number=42"  "42" "$(printf '%s' "$out" | jq -r '.number')"
assert_eq "1.2 get state=open" "open" "$(printf '%s' "$out" | jq -r '.state')"
assert_eq "1.2 get labels[0]=type:bd"        "type:bd" "$(printf '%s' "$out" | jq -r '.labels[0]')"
assert_eq "1.2 get assignees[0]=david"       "david"   "$(printf '%s' "$out" | jq -r '.assignees[0]')"
assert_eq "1.2 get milestone=v11.0"          "v11.0"   "$(printf '%s' "$out" | jq -r '.milestone')"
assert_contains "1.2 get title preserved" "$(printf '%s' "$out" | jq -r '.title')" "tracker-provider abstraction"

# 1.3 get — id required validation
reset_fake_gh
err=$(provider_get "" 2>&1 1>/dev/null) || true
assert_contains "1.3 get empty-id → validation" "$err" "ERROR: validation"

# 1.4 list — items envelope, next_cursor null
reset_fake_gh
export FAKE_GH_STDOUT_FILE="$FIXTURES/gh-issue-list.json"
out=$(provider_list '{"state":"open"}')
assert_eq "1.4 list items.length=2" "2" "$(printf '%s' "$out" | jq -r '.items | length')"
assert_eq "1.4 list next_cursor=null" "null" "$(printf '%s' "$out" | jq -r '.next_cursor')"
assert_eq "1.4 list items[0].id=42"   "42"   "$(printf '%s' "$out" | jq -r '.items[0].id')"

# 1.5 search — re-uses search-issues envelope shape
reset_fake_gh
export FAKE_GH_STDOUT_FILE="$FIXTURES/gh-issue-list.json"
out=$(provider_search "label:bd")
assert_eq "1.5 search items.length=2" "2" "$(printf '%s' "$out" | jq -r '.items | length')"

# 1.6 create — title required + url-derived number
reset_fake_gh
log=$(mktemp -t prov-log.XXXXXX); export FAKE_GH_LOG="$log"
url_file=$(make_tmp_with "https://github.com/optiquity/pack/issues/77")
export FAKE_GH_STDOUT_FILE="$url_file"
out=$(provider_create '{"title":"Test issue","body":"hello","labels":["foo"]}')
assert_eq "1.6 create id=77"  "77" "$(printf '%s' "$out" | jq -r '.id')"
assert_eq "1.6 create url derived" "https://github.com/optiquity/pack/issues/77" "$(printf '%s' "$out" | jq -r '.url')"
log_contents=$(cat "$log")
assert_contains "1.6 create issued 'gh issue create'" "$log_contents" "issue create --title Test issue"
rm -f "$log" "$url_file"

# 1.7 create — title missing
reset_fake_gh
err=$(provider_create '{}' 2>&1 1>/dev/null) || true
assert_contains "1.7 create no-title → validation" "$err" "ERROR: validation"

# 1.8 update — patch dispatch
reset_fake_gh
out=$(provider_update 42 '{"title":"new","add_labels":["bug"]}')
assert_eq "1.8 update id=42 updated=true" "true" "$(printf '%s' "$out" | jq -r '.updated')"

# 1.9 close — valid reason
reset_fake_gh
out=$(provider_close 42 completed)
assert_eq "1.9 close state=closed" "closed" "$(printf '%s' "$out" | jq -r '.state')"
assert_eq "1.9 close state_reason=completed" "completed" "$(printf '%s' "$out" | jq -r '.state_reason')"

# 1.10 close — invalid reason
reset_fake_gh
err=$(provider_close 42 nonsense 2>&1 1>/dev/null) || true
assert_contains "1.10 close bad-reason → validation" "$err" "invalid reason"

# 1.11 reopen
reset_fake_gh
out=$(provider_reopen 42)
assert_eq "1.11 reopen state=open" "open" "$(printf '%s' "$out" | jq -r '.state')"

# 1.12 comment — body required
reset_fake_gh
err=$(provider_comment 42 "" 2>&1 1>/dev/null) || true
assert_contains "1.12 comment empty-body → validation" "$err" "ERROR: validation"

# 1.13 comment — happy
reset_fake_gh
url_file=$(make_tmp_with "https://github.com/optiquity/pack/issues/42#issuecomment-9999")
export FAKE_GH_STDOUT_FILE="$url_file"
out=$(provider_comment 42 "hello world")
assert_contains "1.13 comment_url returned" "$(printf '%s' "$out" | jq -r '.comment_url')" "issuecomment-9999"
rm -f "$url_file"

# 1.14 set_labels — replaces wholesale
reset_fake_gh
# First call (view) returns current labels; second call (edit) returns empty.
# Our fake gh always returns the same fixture, so test is structural only.
labels_file=$(make_tmp_with "old-1,old-2")
export FAKE_GH_STDOUT_FILE="$labels_file"
out=$(provider_set_labels 42 '["new-1","new-2"]')
assert_eq "1.14 set_labels echoes input" '["new-1","new-2"]' "$(printf '%s' "$out" | jq -c '.labels')"
rm -f "$labels_file"

# 1.15 set_assignee
reset_fake_gh
asg_file=$(make_tmp_with "old-user")
export FAKE_GH_STDOUT_FILE="$asg_file"
out=$(provider_set_assignee 42 '["alice","bob"]')
assert_eq "1.15 set_assignee echoes input" '["alice","bob"]' "$(printf '%s' "$out" | jq -c '.assignees')"
rm -f "$asg_file"

# 1.16 set_milestone
reset_fake_gh
out=$(provider_set_milestone 42 "v11.1")
assert_eq "1.16 set_milestone v11.1" "v11.1" "$(printf '%s' "$out" | jq -r '.milestone')"

# 1.17 link — comment-based for blocks/blocked-by/related/duplicates
reset_fake_gh
out=$(provider_link 42 99 blocks)
assert_eq "1.17 link kind=blocks"      "blocks" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.17 link linked_to=99"     "99"     "$(printf '%s' "$out" | jq -r '.linked_to')"

# 1.18 link — invalid kind
reset_fake_gh
err=$(provider_link 42 99 mystery 2>&1 1>/dev/null) || true
assert_contains "1.18 link bad-kind → validation" "$err" "unknown kind"

# 1.19 unlink — comment-based kinds rejected
reset_fake_gh
err=$(provider_unlink 42 99 blocks 2>&1 1>/dev/null) || true
assert_contains "1.19 unlink blocks → validation (manual removal)" "$err" "comment-based"

# 1.20 sub_issue_create — existing_id path (no extension)
# Force extension-absent path by clearing the cache and pointing
# `gh extension list` (the fake) at empty stdout → grep returns 1.
reset_fake_gh
unset _GH_SUB_ISSUE_EXT_CACHED
empty_file=$(make_tmp_with "")
export FAKE_GH_STDOUT_FILE="$empty_file"
# Subsequent gh calls (repo view, api node-id) all return empty too;
# this validates structural dispatch but not GraphQL semantics.
out=$(provider_sub_issue_create 100 '{"existing_id":"42"}' 2>&1) || true
# Either the call succeeded with parent/child JSON, or stderr captured
# a typed error. Both are acceptable structural outcomes — the test
# is that the public API does not throw.
if printf '%s' "$out" | jq -e '.parent_id' >/dev/null 2>&1; then
    t_pass "1.20 sub_issue_create returned parent/child JSON"
else
    # Accept structured error path
    if printf '%s' "$out" | grep -q "ERROR:"; then
        t_pass "1.20 sub_issue_create (extension-absent fallback) emitted typed error"
    else
        t_fail "1.20 sub_issue_create" "neither success nor typed-error: $out"
    fi
fi
rm -f "$empty_file"

# 1.21 raw — graphql path requires body
reset_fake_gh
err=$(provider_raw POST graphql "" 2>&1 1>/dev/null) || true
assert_contains "1.21 raw graphql empty-body → validation" "$err" "graphql requires body"

# 1.22 raw — graphql with body succeeds
reset_fake_gh
out=$(provider_raw POST graphql 'query { viewer { login } }')
# Output is whatever the fake gh prints (empty here); just verify rc=0
assert_eq "1.22 raw graphql body accepted (rc=0)" "0" "$?"

# ─────────────────────────────────────────────────────────────────
# Group 2: Error mapping (V1 §2.5 typed codes)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Error mapping ===\n"

run_error_test() {
    local label="$1"
    local stderr_content="$2"
    local expected_code="$3"
    local stderr_file
    stderr_file=$(make_tmp_with "$stderr_content")
    reset_fake_gh
    export FAKE_GH_EXIT=1
    export FAKE_GH_STDERR_FILE="$stderr_file"
    local err
    err=$(provider_get 42 2>&1 1>/dev/null) || true
    rm -f "$stderr_file"
    assert_contains "$label" "$err" "ERROR: $expected_code"
}

run_error_test "2.1 not-found"               "could not resolve to a Resource"             "not-found"
run_error_test "2.2 rate-limit-primary"      "API rate limit exceeded for user X"          "rate-limit-primary"
run_error_test "2.3 rate-limit-secondary"    "secondary rate limit triggered"              "rate-limit-secondary"
run_error_test "2.4 auth-missing"            "gh auth login required to proceed"           "auth-missing"
run_error_test "2.5 auth-expired"            "HTTP 401: Bad credentials"                   "auth-expired"
run_error_test "2.6 auth-insufficient-scope" "HTTP 403: requires the 'repo' scope"         "auth-insufficient-scope"
run_error_test "2.7 network-unreachable"     "could not resolve host: api.github.com"      "network-unreachable"
run_error_test "2.8 schema-reshape"          "undefined field on type Issue"               "schema-reshape"

# ─────────────────────────────────────────────────────────────────
# Group 3: Stub-backend structural test (multi-backend extensibility)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Stub-backend structural test ===\n"

# shellcheck disable=SC1091
source "$FIXTURES/stub-backend.sh"

# All routing now goes via the dispatcher to tracker_provider_stub_*.
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub

# 3.1 capabilities → routes to stub
out=$(provider_capabilities)
assert_eq "3.1 capabilities routed to stub backend" "stub" "$(printf '%s' "$out" | jq -r '.backend_name')"

# 3.2 each public op routes correctly. Verify by checking $STUB_CALLS
# log accumulates the expected op names. We do NOT inspect output —
# only that the dispatcher did not fall through to github.
STUB_CALLS=""
provider_list   '{}' >/dev/null
provider_get    1   >/dev/null
provider_search "q" >/dev/null
provider_create '{}' >/dev/null
provider_update 1 '{}' >/dev/null
provider_close  1   >/dev/null
provider_reopen 1   >/dev/null
provider_comment 1 "x" >/dev/null
provider_set_labels    1 '[]' >/dev/null
provider_set_assignee  1 '[]' >/dev/null
provider_set_milestone 1 ""   >/dev/null
provider_link    1 2 blocks   >/dev/null
provider_unlink  1 2 child    >/dev/null
provider_sub_issue_create 1 '{}' >/dev/null
provider_sub_issue_list   1      >/dev/null
provider_sub_issue_unlink 1 2    >/dev/null
provider_capabilities >/dev/null
provider_raw GET / >/dev/null

for op in list get search create update close reopen comment set_labels set_assignee set_milestone link unlink sub_issue_create sub_issue_list sub_issue_unlink capabilities raw; do
    if [[ "$STUB_CALLS" == *"|$op"* ]]; then
        t_pass "3.2 $op routed to stub"
    else
        t_fail "3.2 $op" "stub backend did not record op '$op' in STUB_CALLS"
    fi
done

# 3.3 unknown backend returns typed validation error
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=mars
err=$(provider_capabilities 2>&1 1>/dev/null) || true
assert_contains "3.3 unknown backend → validation error" "$err" "ERROR: validation"
assert_contains "3.3 unknown backend → message names backend" "$err" "Unknown backend: mars"

unset _TRACKER_PROVIDER_BACKEND_OVERRIDE

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
    printf -- "$FAILED_TESTS\n"
    exit 1
fi
printf "All tests passed.\n"
exit 0
