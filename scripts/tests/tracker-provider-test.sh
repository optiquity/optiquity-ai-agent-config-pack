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

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

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

FAKE_BIN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tracker-prov-fakebin.XXXXXX")"
trap 'rm -rf "$FAKE_BIN_DIR"' EXIT

cat > "$FAKE_BIN_DIR/gh" <<'FAKE_GH'
#!/usr/bin/env bash
# Fake `gh` for offline tracker-provider tests.
# Behavior driven by env vars:
#   FAKE_GH_STDOUT_FILE — path to file emitted to stdout (default: empty)
#   FAKE_GH_STDERR_FILE — path to file emitted to stderr (default: empty)
#   FAKE_GH_EXIT        — exit code (default: 0)
#   FAKE_GH_LOG         — append the invocation args to this file
#
# Multi-call dispatch (BD-111 — added for the addBlockedBy chain test):
#   FAKE_GH_DISPATCH_DIR — when set, the fake selects its stdout file
#                          by inspecting argv. Lookup precedence:
#                            1. $FAKE_GH_DISPATCH_DIR/api-graphql when
#                               the call is `api graphql ...`
#                            2. $FAKE_GH_DISPATCH_DIR/api-issue-N for
#                               `api /repos/.../issues/N` (numeric N)
#                            3. $FAKE_GH_DISPATCH_DIR/repo for
#                               `repo view ...`
#                            4. $FAKE_GH_DISPATCH_DIR/<verb> generic
#                               (e.g., `issue`, `search`)
#                          When the matched file does not exist, the
#                          fake falls through to FAKE_GH_STDOUT_FILE.
#                          Unchanged behavior when DISPATCH_DIR is
#                          unset; preserves backward compatibility.
if [[ -n "${FAKE_GH_LOG:-}" ]]; then
    printf '%s\n' "$*" >> "$FAKE_GH_LOG"
fi
# BD-204: when FAKE_GH_REPO_VIEW_FAIL is set, any `repo ...` call
# reproduces the non-clone-cwd failure of the real argument-less
# `gh repo view` (which does NOT honor GH_REPO — verified empirically
# 2026-06-10). The check runs AFTER logging so a regression that
# re-consults `gh repo view` is visible in FAKE_GH_LOG and fails the
# op (rc=1), exactly like the live rehearsal failure.
if [[ -n "${FAKE_GH_REPO_VIEW_FAIL:-}" && "${1:-}" == "repo" ]]; then
    echo "failed to run git: fatal: not a git repository (or any of the parent directories): .git" >&2
    exit 1
fi
# BD-204 close-reason vocabulary enforcement (C-8 live-flip defect):
# the REAL gh CLI accepts only {completed|not planned|duplicate} for
# `issue close --reason` — "not planned" takes a SPACE. Reject any
# other value with a nonzero exit, exactly like the real CLI, so
# provider-vocabulary drift (e.g. the interface token `not_planned`
# leaking through to the CLI) can never silently mock-pass again.
if [[ "${1:-}" == "issue" && "${2:-}" == "close" ]]; then
    _close_reason=""
    _prev_arg=""
    for _arg in "$@"; do
        if [[ "$_prev_arg" == "--reason" || "$_prev_arg" == "-r" ]]; then
            _close_reason="$_arg"
        fi
        _prev_arg="$_arg"
    done
    if [[ -n "$_close_reason" ]]; then
        case "$_close_reason" in
            completed|"not planned"|duplicate) ;;
            *)
                echo "fake-gh: invalid --reason '$_close_reason' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                exit 1
                ;;
        esac
    fi
fi
_fake_gh_select_stdout() {
    if [[ -z "${FAKE_GH_DISPATCH_DIR:-}" ]]; then
        printf '%s' "${FAKE_GH_STDOUT_FILE:-}"
        return
    fi
    local v1="${1:-}" v2="${2:-}" v3="${3:-}"
    # api graphql
    if [[ "$v1" == "api" && "$v2" == "graphql" ]]; then
        if [[ -f "$FAKE_GH_DISPATCH_DIR/api-graphql" ]]; then
            printf '%s' "$FAKE_GH_DISPATCH_DIR/api-graphql"
            return
        fi
    fi
    # api /repos/.../issues/N
    if [[ "$v1" == "api" && "$v2" == /repos/* ]]; then
        local n
        n=$(printf '%s' "$v2" | sed -E 's|.*/issues/([0-9]+).*|\1|')
        if [[ -n "$n" && -f "$FAKE_GH_DISPATCH_DIR/api-issue-$n" ]]; then
            printf '%s' "$FAKE_GH_DISPATCH_DIR/api-issue-$n"
            return
        fi
    fi
    # repo view ...
    if [[ "$v1" == "repo" ]]; then
        if [[ -f "$FAKE_GH_DISPATCH_DIR/repo" ]]; then
            printf '%s' "$FAKE_GH_DISPATCH_DIR/repo"
            return
        fi
    fi
    # generic verb fallback (issue, search, ...)
    if [[ -n "$v1" && -f "$FAKE_GH_DISPATCH_DIR/$v1" ]]; then
        printf '%s' "$FAKE_GH_DISPATCH_DIR/$v1"
        return
    fi
    printf '%s' "${FAKE_GH_STDOUT_FILE:-}"
}
_fake_gh_stdout="$(_fake_gh_select_stdout "$@")"
if [[ -n "$_fake_gh_stdout" && -f "$_fake_gh_stdout" ]]; then
    cat "$_fake_gh_stdout"
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

# BD-204: start from a known GH_REPO-unset state (see reset_fake_gh).
unset GH_REPO

# Source the library under test.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"

# Helper: reset fake gh vars between tests.
# GH_REPO is scrubbed too (BD-204): an ambient GH_REPO from the
# developer's shell — or one exported by a previous test — would flip
# _gh_owner_repo from the `gh repo view` fallback path (which the
# legacy 1.17/1.20 chain tests pin) to the GH_REPO-preferred path.
# No tracker.toml is in scope in this suite, so tracker_gh_repo_setup
# never re-exports it. FAKE_GH_REPO_VIEW_FAIL is the BD-204 fake-gh
# kill switch for `gh repo view`.
reset_fake_gh() {
    unset FAKE_GH_STDOUT_FILE FAKE_GH_STDERR_FILE FAKE_GH_EXIT FAKE_GH_LOG \
          FAKE_GH_DISPATCH_DIR FAKE_GH_REPO_VIEW_FAIL GH_REPO
}

# Helper: write content to a tmp file and echo path.
make_tmp_with() {
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/tracker-prov-test.XXXXXX")
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

# 1.1b BD-204 §3.3c/§3.3d: the GH backend DECLARES the body + pacing
# capabilities the migrator reads (provider_body_limit=65536, raw_text
# storage; min-write interval 1s + 500 writes/hour secondary cap).
assert_eq "1.1b capabilities body.limit=65536"           "65536"    "$(printf '%s' "$out" | jq -r '.body.limit')"
assert_eq "1.1b capabilities body.storage_format=raw_text" "raw_text" "$(printf '%s' "$out" | jq -r '.body.storage_format')"
assert_eq "1.1b capabilities rate_limits.min_write_interval_s=1" "1"  "$(printf '%s' "$out" | jq -r '.rate_limits.min_write_interval_s')"
assert_eq "1.1b capabilities rate_limits.writes_per_hour_max=500" "500" "$(printf '%s' "$out" | jq -r '.rate_limits.writes_per_hour_max')"

# 1.1c BD-204 §3.3c: the migrator reads the ACTIVE provider's body.limit (no
# hardcoded 65536). A smaller-limit raw_text mock triggers the composer's
# loud-fail at ITS OWN bound (tracker-agnostic, R-PROVIDER); the GH limit
# lets the same body pass. Drive the production composer + the stub backend.
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/per-entry/_lib.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/tracker-migrate-forward.sh"
source "$FIXTURES/stub-backend.sh"
_p11c_raw=$(printf '**BD-905 — provider-limit stress**\n'; for i in $(seq 1 40); do printf 'pad %s pad pad pad pad pad pad pad pad pad pad pad\n' "$i"; done)
# Small-limit mock: a 2100-byte body limit (margin 2048 → ~52-byte budget),
# so ANY real composed body (H2 + markers + blob) overflows; the GH backend
# (65536) lets the same body pass — proving the migrator reads the ACTIVE
# provider's limit, not a hardcoded 65536.
tracker_provider_stub_capabilities() { echo '{"backend_name":"stub","body":{"limit":2100,"storage_format":"raw_text"}}'; }
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=stub
p11c_err=$(tmf_compose_issue_body "BD-905" "x" "" "" "" "$_p11c_raw" 2>&1); p11c_rc=$?
assert_eq       "1.1c smaller-limit mock fails loud at its bound (rc=1)" "1" "$p11c_rc"
assert_contains "1.1c smaller-limit fail names entry"                    "$p11c_err" "size-budget: entry BD-905"
# Same body under the GH backend (65536 limit) passes.
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
p11c_ok=$(tmf_compose_issue_body "BD-905" "x" "" "" "" "$_p11c_raw" 2>&1); p11c_ok_rc=$?
assert_eq "1.1c same body passes under GH 65536 limit (rc=0)" "0" "$p11c_ok_rc"
unset -f tracker_provider_stub_capabilities 2>/dev/null || true

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

# 1.2b BD-204 C-8 defect 1 (stateReason casing): the LIVE gh read-back
# carries GraphQL-enum casing — verbatim live evidence (2026-06-11):
#   $ gh issue view 21 -R DShaneNYC/optiquity-ai-agent-config-pack \
#       --json number,state,stateReason
#   {"number":21,"state":"CLOSED","stateReason":"NOT_PLANNED"}
# The provider boundary (`_gh_normalize_issue`) must lowercase BOTH
# state AND state_reason to the canonical interface vocabulary; pre-fix
# stateReason passed through verbatim and every closed
# Deprecated/Cancelled issue decoded to Resolved on reverse.
reset_fake_gh
closed_np_fixture=$(make_tmp_with '{"number":21,"title":"BD-021: closed not-planned","body":"","state":"CLOSED","stateReason":"NOT_PLANNED","labels":[],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/21"}')
export FAKE_GH_STDOUT_FILE="$closed_np_fixture"
out=$(provider_get 21)
assert_eq "1.2b normalize: live state CLOSED → canonical closed" \
    "closed" "$(printf '%s' "$out" | jq -r '.state')"
assert_eq "1.2b normalize: live stateReason NOT_PLANNED → canonical not_planned" \
    "not_planned" "$(printf '%s' "$out" | jq -r '.state_reason')"
rm -f "$closed_np_fixture"

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
log=$(mktemp "${TMPDIR:-/tmp}/prov-log.XXXXXX"); export FAKE_GH_LOG="$log"
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

# 1.9b close — the interface reason `not_planned` TRANSLATES to the gh
# CLI vocabulary "not planned" (SPACE) at the invocation boundary
# (BD-204 C-8 live-flip defect: all five Deprecated/Cancelled closes
# failed 3x each because `not_planned` was passed through verbatim;
# the real CLI vocabulary is {completed|not planned|duplicate} per
# `gh issue close --help`). The interface — the reason arg and the
# returned state_reason — keeps `not_planned`. The fake gh above now
# REJECTS any non-CLI-vocabulary reason, so this leg fails loudly if
# the translation ever regresses.
reset_fake_gh
log=$(mktemp "${TMPDIR:-/tmp}/prov-close-log.XXXXXX"); export FAKE_GH_LOG="$log"
out=$(provider_close 42 not_planned)
rc19b=$?
assert_eq "1.9b close not_planned rc=0 (vocabulary-enforcing fake accepts the translated reason)" "0" "$rc19b"
assert_eq "1.9b close state_reason stays the interface token not_planned" "not_planned" "$(printf '%s' "$out" | jq -r '.state_reason')"
log_contents=$(cat "$log")
assert_contains "1.9b gh argv carries --reason not planned (SPACE — the CLI vocabulary)" \
    "$log_contents" "issue close 42 --reason not planned"
if printf '%s' "$log_contents" | grep -q -- "--reason not_planned"; then
    t_fail "1.9b interface token not_planned must NOT reach the gh CLI" "log: ${log_contents:0:200}"
else
    t_pass "1.9b interface token not_planned does not reach the gh CLI"
fi
rm -f "$log"
unset FAKE_GH_LOG

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

# 1.17 link — first-class GraphQL `addBlockedBy` for blocks/blocked-by
# (BD-111). Comment-marker path remains available via provider_comment()
# / provider_raw() for callers explicitly wanting the V3 §28 fallback.
#
# This test exercises the gh invocation chain. Owner/repo resolution
# goes through _gh_owner_repo (BD-204): GH_REPO is unset in this
# suite's default state (reset_fake_gh scrubs it), so the chain takes
# the documented FALLBACK path — `gh repo view` IS consulted here.
# The GH_REPO-preferred path (no `gh repo view` at all) is pinned by
# 1.17f/1.17g below.
#   1. gh repo view --json nameWithOwner --jq .nameWithOwner   → "owner/repo"
#   2. gh api /repos/owner/repo/issues/42 --jq .node_id        → "NODE_42"
#   3. gh api /repos/owner/repo/issues/99 --jq .node_id        → "NODE_99"
#   4. gh api graphql -f query=... -F issueId=... -F blockingIssueId=...
#      → addBlockedBy response fixture
# The dispatch-dir fake-gh mode (set FAKE_GH_DISPATCH_DIR) supplies
# different stdout per invocation by inspecting argv. The FAKE_GH_LOG
# captures every gh argv so we can assert the GraphQL mutation name +
# arg ordering.
reset_fake_gh
LINK_DISPATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/prov-link-dispatch.XXXXXX")
printf '%s' "optiquity/pack" > "$LINK_DISPATCH_DIR/repo"
printf '%s' "NODE_42"        > "$LINK_DISPATCH_DIR/api-issue-42"
printf '%s' "NODE_99"        > "$LINK_DISPATCH_DIR/api-issue-99"
cp "$FIXTURES/gh-add-blocked-by.json" "$LINK_DISPATCH_DIR/api-graphql"
export FAKE_GH_DISPATCH_DIR="$LINK_DISPATCH_DIR"
log=$(mktemp "${TMPDIR:-/tmp}/prov-link-log.XXXXXX"); export FAKE_GH_LOG="$log"

# 1.17a kind=blocked-by — id 42 is blocked by 99 →
#       addBlockedBy(issueId=NODE_42, blockingIssueId=NODE_99)
: > "$log"
out=$(provider_link 42 99 blocked-by)
assert_eq "1.17a link kind=blocked-by"  "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.17a link linked_to=99"     "99"         "$(printf '%s' "$out" | jq -r '.linked_to')"
log_contents=$(cat "$log")
assert_contains "1.17a invokes gh repo view (GH_REPO-unset fallback)" "$log_contents" "repo view"
assert_contains "1.17a resolves issue 42 node-id"      "$log_contents" "/repos/optiquity/pack/issues/42"
assert_contains "1.17a resolves issue 99 node-id"      "$log_contents" "/repos/optiquity/pack/issues/99"
assert_contains "1.17a invokes graphql addBlockedBy"   "$log_contents" "addBlockedBy"
assert_contains "1.17a issueId=NODE_42 (blocked-by)"   "$log_contents" "issueId=NODE_42"
assert_contains "1.17a blockingIssueId=NODE_99"        "$log_contents" "blockingIssueId=NODE_99"
# (PACK-REVIEW-BD-111 F7: a former positive `assert_contains
# "graphql"` line was removed from here — it was redundant with the
# `addBlockedBy` check above and the negative if/grep block below
# already covers the actual "does NOT comment on issue body" intent.)
# Negative: the legacy comment-marker path must NOT be taken.
if printf '%s' "$log_contents" | grep -q "issue comment"; then
    t_fail "1.17a should not invoke 'issue comment' for blocked-by" "log: ${log_contents:0:200}"
else
    t_pass "1.17a does not invoke legacy 'issue comment' for blocked-by"
fi

# 1.17b kind=blocks — operands invert: 42 blocks 99 →
#       addBlockedBy(issueId=NODE_99, blockingIssueId=NODE_42)
: > "$log"
out=$(provider_link 42 99 blocks)
assert_eq "1.17b link kind=blocks"  "blocks" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.17b link linked_to=99" "99"     "$(printf '%s' "$out" | jq -r '.linked_to')"
log_contents=$(cat "$log")
assert_contains "1.17b invokes graphql addBlockedBy" "$log_contents" "addBlockedBy"
assert_contains "1.17b issueId=NODE_99 (inverted)"   "$log_contents" "issueId=NODE_99"
assert_contains "1.17b blockingIssueId=NODE_42"      "$log_contents" "blockingIssueId=NODE_42"

# 1.17c EMU FORBIDDEN error path. PACK-REVIEW-BD-111 F6: this test
# does NOT specifically isolate the api-graphql step — `FAKE_GH_EXIT`
# is global, so the chain short-circuits at the FIRST gh call
# (`gh repo view`) with the EMU stderr. The typed error code is
# nonetheless correct (`_gh_classify_error` doesn't care which gh
# call produced the stderr; the FORBIDDEN substring routes via line
# 69 of tracker-provider-gh.sh to `auth-insufficient-scope`). This
# test asserts: when ANY gh call in the link chain fails with EMU
# FORBIDDEN stderr, the typed error must be `auth-insufficient-scope`.
# Per-step isolation (faulting only the api-graphql step) would
# require a dispatch-mode harness extension and is out of scope for
# the BD-111 fix-pass per F6 option (a).
reset_fake_gh
export FAKE_GH_DISPATCH_DIR="$LINK_DISPATCH_DIR"
emu_err_file=$(mktemp "${TMPDIR:-/tmp}/prov-link-emu.XXXXXX")
printf 'FORBIDDEN: Unauthorized; path: addBlockedBy\n' > "$emu_err_file"
export FAKE_GH_STDERR_FILE="$emu_err_file"
export FAKE_GH_EXIT=1
err=$(provider_link 42 99 blocked-by 2>&1 1>/dev/null) || true
assert_contains "1.17c link chain EMU FORBIDDEN → typed auth-insufficient-scope" "$err" "ERROR: auth-insufficient-scope"
rm -f "$emu_err_file"
unset FAKE_GH_DISPATCH_DIR FAKE_GH_STDERR_FILE FAKE_GH_EXIT

# 1.17d related — still comment-based fallback (no first-class API).
reset_fake_gh
out=$(provider_link 42 99 related)
assert_eq "1.17d link kind=related"  "related" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.17d link linked_to=99"  "99"      "$(printf '%s' "$out" | jq -r '.linked_to')"

# 1.17e duplicates — still comment-based fallback.
reset_fake_gh
out=$(provider_link 42 99 duplicates)
assert_eq "1.17e link kind=duplicates" "duplicates" "$(printf '%s' "$out" | jq -r '.kind')"

# 1.17f BD-204 (BD-129-class gap): GH_REPO-PREFERRED resolution.
# Argument-less `gh repo view` does NOT honor GH_REPO and dies from a
# non-clone cwd ("fatal: not a git repository") — both BD-204 live
# rehearsal runs failed at forward step-7 exactly here. With GH_REPO
# set, the link chain must succeed WITHOUT consulting `gh repo view`:
# FAKE_GH_REPO_VIEW_FAIL makes the fake reproduce the non-clone-cwd
# death, so any regression back to repo-view slug resolution fails
# this test loudly instead of passing via a friendly stub.
reset_fake_gh
export FAKE_GH_DISPATCH_DIR="$LINK_DISPATCH_DIR"
export FAKE_GH_REPO_VIEW_FAIL=1
export FAKE_GH_LOG="$log"
export GH_REPO="optiquity/pack"
: > "$log"
out=$(provider_link 42 99 blocked-by)
rc17f=$?
assert_eq "1.17f link succeeds via GH_REPO with repo-view dead (rc=0)" "0" "$rc17f"
assert_eq "1.17f link kind=blocked-by"  "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
log_contents=$(cat "$log")
if printf '%s' "$log_contents" | grep -q "repo view"; then
    t_fail "1.17f must not consult 'gh repo view' when GH_REPO is set" "log: ${log_contents:0:200}"
else
    t_pass "1.17f does not consult 'gh repo view' when GH_REPO is set"
fi
assert_contains "1.17f REST path uses GH_REPO slug"   "$log_contents" "/repos/optiquity/pack/issues/42"
assert_contains "1.17f graphql addBlockedBy fires"    "$log_contents" "addBlockedBy"

# 1.17g host-prefixed GH_REPO: tracker-config.sh's canonical export
# shape is `[HOST/]OWNER/REPO`; REST paths and owner/name splits need
# bare `OWNER/REPO`, so _gh_owner_repo strips the HOST/ prefix.
export GH_REPO="github.com/optiquity/pack"
: > "$log"
out=$(provider_link 42 99 blocked-by)
rc17g=$?
assert_eq "1.17g link succeeds via host-prefixed GH_REPO (rc=0)" "0" "$rc17g"
log_contents=$(cat "$log")
assert_contains "1.17g REST path uses bare OWNER/REPO (HOST/ stripped)" \
    "$log_contents" "/repos/optiquity/pack/issues/42"
if printf '%s' "$log_contents" | grep -q "/repos/github.com/"; then
    t_fail "1.17g HOST/ prefix must not leak into REST path" "log: ${log_contents:0:200}"
else
    t_pass "1.17g HOST/ prefix does not leak into REST path"
fi

# 1.17h degenerate GH_REPO shapes (BD-204 review F-4): the post-strip
# shape guard in _gh_owner_repo rejects >=3-slash and trailing-slash
# values with a typed validation error instead of passing a malformed
# slug through to the REST path. FAKE_GH_REPO_VIEW_FAIL stays exported
# from 1.17f, so any silent fallback to `gh repo view` would also fail
# loudly here.
export GH_REPO="a/b/c/d"
err=$(provider_link 42 99 blocked-by 2>&1 1>/dev/null)
rc17h=$?
assert_eq "1.17h link fails loud on degenerate GH_REPO=a/b/c/d (rc=1)" "1" "$rc17h"
assert_contains "1.17h typed validation error names the slug contract" \
    "$err" "not a [HOST/]OWNER/REPO slug"
export GH_REPO="optiquity/pack/"
err=$(provider_link 42 99 blocked-by 2>&1 1>/dev/null)
rc17h2=$?
assert_eq "1.17h link fails loud on trailing-slash GH_REPO (rc=1)" "1" "$rc17h2"
assert_contains "1.17h trailing-slash rejection is the typed validation error" \
    "$err" "not a [HOST/]OWNER/REPO slug"
unset GH_REPO FAKE_GH_REPO_VIEW_FAIL

# Cleanup 1.17 dispatch dir.
rm -rf "$LINK_DISPATCH_DIR"
rm -f "$log"
unset FAKE_GH_LOG

# 1.18 link — invalid kind
reset_fake_gh
err=$(provider_link 42 99 mystery 2>&1 1>/dev/null) || true
assert_contains "1.18 link bad-kind → validation" "$err" "unknown kind"

# 1.19 unlink — comment-based kinds (related|duplicates) rejected. Note
# that with BD-111's scope-extended unlink (2026-05-15), blocks and
# blocked-by are now first-class via removeBlockedBy and are tested in
# 1.20a-c below; the validation rejection now applies only to
# related|duplicates which still have no first-class GH API.
reset_fake_gh
err=$(provider_unlink 42 99 related 2>&1 1>/dev/null) || true
assert_contains "1.19 unlink related → validation (comment-based)" "$err" "comment-based"
reset_fake_gh
err=$(provider_unlink 42 99 duplicates 2>&1 1>/dev/null) || true
assert_contains "1.19 unlink duplicates → validation (comment-based)" "$err" "comment-based"

# 1.20 unlink — first-class GraphQL `removeBlockedBy` for blocks/blocked-by
# (BD-111 scope-extended 2026-05-15; symmetric pair of 1.17 addBlockedBy).
# Same dispatch-mode fake-gh harness as 1.17. As in 1.17, owner/repo
# resolution goes through _gh_owner_repo (BD-204) and GH_REPO is unset
# here, so step 1 below is the documented fallback; the GH_REPO-
# preferred path for unlink is pinned by 1.20d. Asserts the gh argv chain:
#   1. gh repo view --json nameWithOwner --jq .nameWithOwner   → "owner/repo"
#   2. gh api /repos/owner/repo/issues/42 --jq .node_id        → "NODE_42"
#   3. gh api /repos/owner/repo/issues/99 --jq .node_id        → "NODE_99"
#   4. gh api graphql -f query=... -F issueId=... -F blockingIssueId=...
#      → removeBlockedBy response fixture (gh-remove-blocked-by.json)
reset_fake_gh
UNLINK_DISPATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/prov-unlink-dispatch.XXXXXX")
printf '%s' "optiquity/pack" > "$UNLINK_DISPATCH_DIR/repo"
printf '%s' "NODE_42"        > "$UNLINK_DISPATCH_DIR/api-issue-42"
printf '%s' "NODE_99"        > "$UNLINK_DISPATCH_DIR/api-issue-99"
cp "$FIXTURES/gh-remove-blocked-by.json" "$UNLINK_DISPATCH_DIR/api-graphql"
export FAKE_GH_DISPATCH_DIR="$UNLINK_DISPATCH_DIR"
log=$(mktemp "${TMPDIR:-/tmp}/prov-unlink-log.XXXXXX"); export FAKE_GH_LOG="$log"

# 1.20a kind=blocked-by — id 42 no-longer blocked by 99 →
#       removeBlockedBy(issueId=NODE_42, blockingIssueId=NODE_99)
: > "$log"
out=$(provider_unlink 42 99 blocked-by)
assert_eq "1.20a unlink kind=blocked-by"     "blocked-by" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.20a unlink unlinked_from=99"    "99"         "$(printf '%s' "$out" | jq -r '.unlinked_from')"
log_contents=$(cat "$log")
assert_contains "1.20a invokes gh repo view (GH_REPO-unset fallback)" "$log_contents" "repo view"
assert_contains "1.20a resolves issue 42 node-id"        "$log_contents" "/repos/optiquity/pack/issues/42"
assert_contains "1.20a resolves issue 99 node-id"        "$log_contents" "/repos/optiquity/pack/issues/99"
assert_contains "1.20a invokes graphql removeBlockedBy"  "$log_contents" "removeBlockedBy"
assert_contains "1.20a issueId=NODE_42 (blocked-by)"     "$log_contents" "issueId=NODE_42"
assert_contains "1.20a blockingIssueId=NODE_99"          "$log_contents" "blockingIssueId=NODE_99"
# Negative: must NOT invoke addBlockedBy nor any comment-write path.
if printf '%s' "$log_contents" | grep -q "addBlockedBy"; then
    t_fail "1.20a should not invoke addBlockedBy on unlink" "log: ${log_contents:0:200}"
else
    t_pass "1.20a does not invoke addBlockedBy on unlink"
fi
if printf '%s' "$log_contents" | grep -q "issue comment"; then
    t_fail "1.20a should not invoke 'issue comment' on unlink" "log: ${log_contents:0:200}"
else
    t_pass "1.20a does not invoke legacy 'issue comment' on unlink"
fi

# 1.20b kind=blocks — operands invert: 42 no-longer blocks 99 →
#       removeBlockedBy(issueId=NODE_99, blockingIssueId=NODE_42)
: > "$log"
out=$(provider_unlink 42 99 blocks)
assert_eq "1.20b unlink kind=blocks"          "blocks" "$(printf '%s' "$out" | jq -r '.kind')"
assert_eq "1.20b unlink unlinked_from=99"     "99"     "$(printf '%s' "$out" | jq -r '.unlinked_from')"
log_contents=$(cat "$log")
assert_contains "1.20b invokes graphql removeBlockedBy" "$log_contents" "removeBlockedBy"
assert_contains "1.20b issueId=NODE_99 (inverted)"      "$log_contents" "issueId=NODE_99"
assert_contains "1.20b blockingIssueId=NODE_42"         "$log_contents" "blockingIssueId=NODE_42"

# 1.20c missing-edge / not-found error path. Same caveat as 1.17c
# (PACK-REVIEW-BD-111 F6): `FAKE_GH_EXIT` is global, so the chain
# short-circuits at the FIRST gh call in the unlink chain
# (`gh repo view`) with the 404 stderr. The typed error code is
# nonetheless correct (`_gh_classify_error` resolves "HTTP 404" to
# `not-found` regardless of which gh call produced it). This test
# asserts: when ANY gh call in the unlink chain fails with
# `HTTP 404 Not Found` stderr, the typed error must be `not-found`.
# Auth path covered transitively by Group 2 classifier sweep + 1.17c
# (FORBIDDEN form); cycle-detection N/A on remove.
reset_fake_gh
export FAKE_GH_DISPATCH_DIR="$UNLINK_DISPATCH_DIR"
nf_err_file=$(mktemp "${TMPDIR:-/tmp}/prov-unlink-nf.XXXXXX")
printf 'HTTP 404: Not Found\n' > "$nf_err_file"
export FAKE_GH_STDERR_FILE="$nf_err_file"
export FAKE_GH_EXIT=1
err=$(provider_unlink 42 99 blocked-by 2>&1 1>/dev/null) || true
assert_contains "1.20c unlink chain HTTP-404 → typed not-found" "$err" "ERROR: not-found"
rm -f "$nf_err_file"
unset FAKE_GH_DISPATCH_DIR FAKE_GH_STDERR_FILE FAKE_GH_EXIT

# 1.20d BD-204: unlink takes the GH_REPO-preferred path too — same
# contract as 1.17f, on the removeBlockedBy side. Repo-view dead;
# resolution must come from GH_REPO.
reset_fake_gh
export FAKE_GH_DISPATCH_DIR="$UNLINK_DISPATCH_DIR"
export FAKE_GH_REPO_VIEW_FAIL=1
export FAKE_GH_LOG="$log"
export GH_REPO="optiquity/pack"
: > "$log"
out=$(provider_unlink 42 99 blocked-by)
rc20d=$?
assert_eq "1.20d unlink succeeds via GH_REPO with repo-view dead (rc=0)" "0" "$rc20d"
log_contents=$(cat "$log")
if printf '%s' "$log_contents" | grep -q "repo view"; then
    t_fail "1.20d must not consult 'gh repo view' when GH_REPO is set" "log: ${log_contents:0:200}"
else
    t_pass "1.20d does not consult 'gh repo view' when GH_REPO is set"
fi
assert_contains "1.20d REST path uses GH_REPO slug"      "$log_contents" "/repos/optiquity/pack/issues/42"
assert_contains "1.20d graphql removeBlockedBy fires"    "$log_contents" "removeBlockedBy"
unset GH_REPO FAKE_GH_REPO_VIEW_FAIL

# Cleanup 1.20 dispatch dir.
rm -rf "$UNLINK_DISPATCH_DIR"
rm -f "$log"
unset FAKE_GH_LOG

# 1.21 sub_issue_create — existing_id path (no extension)
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
    t_pass "1.21 sub_issue_create returned parent/child JSON"
else
    # Accept structured error path
    if printf '%s' "$out" | grep -q "ERROR:"; then
        t_pass "1.21 sub_issue_create (extension-absent fallback) emitted typed error"
    else
        t_fail "1.21 sub_issue_create" "neither success nor typed-error: $out"
    fi
fi
rm -f "$empty_file"

# 1.21b BD-204: sub_issue_create (extension-absent GraphQL path)
# resolves owner/repo via GH_REPO with `gh repo view` dead — same
# contract as 1.17f for the addSubIssue chain. The extension cache is
# pinned to "no" so the GraphQL path (the only one that resolves a
# slug) is taken. The graphql response is discarded by the op, so any
# stub content works.
reset_fake_gh
_GH_SUB_ISSUE_EXT_CACHED="no"
SUB_DISPATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/prov-sub-dispatch.XXXXXX")
printf '%s' "NODE_100" > "$SUB_DISPATCH_DIR/api-issue-100"
printf '%s' "NODE_42"  > "$SUB_DISPATCH_DIR/api-issue-42"
printf '%s' "{}"       > "$SUB_DISPATCH_DIR/api-graphql"
export FAKE_GH_DISPATCH_DIR="$SUB_DISPATCH_DIR"
export FAKE_GH_REPO_VIEW_FAIL=1
export GH_REPO="optiquity/pack"
log=$(mktemp "${TMPDIR:-/tmp}/prov-sub-log.XXXXXX"); export FAKE_GH_LOG="$log"
out=$(provider_sub_issue_create 100 '{"existing_id":"42"}')
rc21b=$?
assert_eq "1.21b sub_issue_create succeeds via GH_REPO with repo-view dead (rc=0)" "0" "$rc21b"
assert_eq "1.21b parent_id=100" "100" "$(printf '%s' "$out" | jq -r '.parent_id')"
assert_eq "1.21b child_id=42"   "42"  "$(printf '%s' "$out" | jq -r '.child_id')"
log_contents=$(cat "$log")
if printf '%s' "$log_contents" | grep -q "repo view"; then
    t_fail "1.21b must not consult 'gh repo view' when GH_REPO is set" "log: ${log_contents:0:200}"
else
    t_pass "1.21b does not consult 'gh repo view' when GH_REPO is set"
fi
assert_contains "1.21b REST path uses GH_REPO slug" "$log_contents" "/repos/optiquity/pack/issues/100"
assert_contains "1.21b graphql addSubIssue fires"   "$log_contents" "addSubIssue"

# 1.21c BD-204: sub_issue_list's GraphQL owner/name SPLIT strips the
# HOST/ prefix from a host-prefixed GH_REPO (the canonical
# [HOST/]OWNER/REPO shape tracker-config.sh exports) — `owner` must
# never come out as the host segment.
export GH_REPO="github.com/optiquity/pack"
: > "$log"
out=$(provider_sub_issue_list 100)
rc21c=$?
assert_eq "1.21c sub_issue_list succeeds via host-prefixed GH_REPO (rc=0)" "0" "$rc21c"
log_contents=$(cat "$log")
assert_contains "1.21c graphql owner=optiquity (HOST/ stripped)" "$log_contents" "owner=optiquity"
assert_contains "1.21c graphql repo=pack"                        "$log_contents" "repo=pack"
if printf '%s' "$log_contents" | grep -q "owner=github.com"; then
    t_fail "1.21c HOST/ prefix must not leak into owner split" "log: ${log_contents:0:200}"
else
    t_pass "1.21c HOST/ prefix does not leak into owner split"
fi

# 1.21d BD-204: sub_issue_unlink (extension-absent removeSubIssue
# path) — fifth and last of the five former repo-view resolution
# sites — also resolves via GH_REPO with repo-view dead.
export GH_REPO="optiquity/pack"
: > "$log"
out=$(provider_sub_issue_unlink 100 42)
rc21d=$?
assert_eq "1.21d sub_issue_unlink succeeds via GH_REPO with repo-view dead (rc=0)" "0" "$rc21d"
log_contents=$(cat "$log")
if printf '%s' "$log_contents" | grep -q "repo view"; then
    t_fail "1.21d must not consult 'gh repo view' when GH_REPO is set" "log: ${log_contents:0:200}"
else
    t_pass "1.21d does not consult 'gh repo view' when GH_REPO is set"
fi
assert_contains "1.21d graphql removeSubIssue fires" "$log_contents" "removeSubIssue"

rm -rf "$SUB_DISPATCH_DIR"
rm -f "$log"
unset GH_REPO FAKE_GH_REPO_VIEW_FAIL FAKE_GH_LOG FAKE_GH_DISPATCH_DIR
unset _GH_SUB_ISSUE_EXT_CACHED

# 1.22 raw — graphql path requires body
reset_fake_gh
err=$(provider_raw POST graphql "" 2>&1 1>/dev/null) || true
assert_contains "1.22 raw graphql empty-body → validation" "$err" "graphql requires body"

# 1.23 raw — graphql with body succeeds
reset_fake_gh
out=$(provider_raw POST graphql 'query { viewer { login } }')
# Output is whatever the fake gh prints (empty here); just verify rc=0
assert_eq "1.23 raw graphql body accepted (rc=0)" "0" "$?"

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
# Group 4: Mode-3 pack edit path (tracker_edit_entry — BD-204 §2.3)
# ─────────────────────────────────────────────────────────────────
#
# The full-CRUD Update verb. Verifies that an entry edit dispatches
# provider_update (body/labels) and that a Status change crossing the
# open↔closed boundary ALSO dispatches provider_close (with the DP-3
# state_reason) or provider_reopen — while an update-only edit (or an
# open→open Status change) does NOT cross the boundary.
#
# We stub the provider_* write ops to log their argv into TED_CALLS
# (mirrors the Group-3 STUB_CALLS pattern) so we assert which ops fire
# without a live backend. We stub tracker_edit_mode + the config
# helpers so the path reaches the id-map lookup offline.

printf "\n=== Group 4: Mode-3 pack edit path (tracker_edit_entry) ===\n"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/tracker-edit.sh"

# Offline harness: a scratch repo with an id-map mapping BD-001 → 42.
TED_REPO="$(mktemp -d "${TMPDIR:-/tmp}/tracker-edit.XXXXXX")"
mkdir -p "$TED_REPO/.pack-tracker"
cat > "$TED_REPO/.pack-tracker/id-map.json" <<'EOF'
{ "BD-001": { "id": "42" } }
EOF

# Force tracker mode + a no-op config resolution so the path reaches
# the id-map lookup without a real tracker.toml.
tracker_edit_mode()             { echo "tracker"; }
tracker_config_auto_surface()   { echo "pack"; }
tracker_config_resolve_path()   { echo ""; }

# Stub the provider write ops: record op + key args, succeed.
# provider_update also records its payload ($2) into TED_UPDATE_PAYLOAD so
# the status:* label swap (which rides the update add_labels) is assertable.
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
provider_update() { TED_CALLS="$TED_CALLS|update:$1"; TED_UPDATE_PAYLOAD="$2"; return 0; }
provider_close()  { TED_CALLS="$TED_CALLS|close:$1:$2"; return 0; }
provider_reopen() { TED_CALLS="$TED_CALLS|reopen:$1"; return 0; }

# 4.1 body-only edit → provider_update fires, NO boundary cross.
# NB: call WITHOUT a command-substitution capture so the stubs' TED_CALLS
# mutations propagate to this (parent) shell; capture the return shape
# separately into a tmp file.
TED_CALLS=""
ted_out=$(mktemp "${TMPDIR:-/tmp}/tracker-edit-out.XXXXXX")
tracker_edit_entry "BD-001" '{"body":"new prose"}' "$TED_REPO" > "$ted_out"
assert_contains "4.1 body edit dispatches provider_update" "$TED_CALLS" "|update:42"
if [[ "$TED_CALLS" == *"|close:"* || "$TED_CALLS" == *"|reopen:"* ]]; then
    t_fail "4.1 body edit must NOT cross boundary" "calls=$TED_CALLS"
else
    t_pass "4.1 body-only edit does not cross open/closed boundary"
fi
assert_eq "4.1 returns updated=true" "true" "$(jq -r '.updated' "$ted_out")"
rm -f "$ted_out"

# 4.2 open→open Status change (Open→Deferred) → update only, no cross.
TED_CALLS=""
tracker_edit_entry "BD-001" '{"status":"Deferred","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.2 Open→Deferred dispatches provider_update" "$TED_CALLS" "|update:42"
if [[ "$TED_CALLS" == *"|close:"* || "$TED_CALLS" == *"|reopen:"* ]]; then
    t_fail "4.2 Open→Deferred must NOT cross boundary" "calls=$TED_CALLS"
else
    t_pass "4.2 Open→Deferred (both open) does not cross boundary"
fi

# 4.3 open→closed (Open→Resolved) → update + provider_close completed.
TED_CALLS=""
tracker_edit_entry "BD-001" '{"status":"Resolved","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.3 Open→Resolved dispatches provider_update" "$TED_CALLS" "|update:42"
assert_contains "4.3 Open→Resolved closes with completed" "$TED_CALLS" "|close:42:completed"

# 4.4 open→closed (Open→Cancelled) → provider_close not_planned (DP-3).
TED_CALLS=""
tracker_edit_entry "BD-001" '{"status":"Cancelled","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.4 Open→Cancelled closes with not_planned" "$TED_CALLS" "|close:42:not_planned"

# 4.4b BD-204 C-5 (carry-forward #2 — explicit Deprecated close-path
# assertion). open→closed (Open→Deprecated) → provider_close not_planned
# (DP-3, the Deprecated row) + the status:deprecated label rides the
# provider_update add_labels. Pre-C-5 the Deprecated close-with-reason
# path was covered only TRANSITIVELY by the Cancelled case (4.4); this
# pins the Deprecated row directly (both close with not_planned per DP-3,
# but the label disambiguates Deprecated from Cancelled on reverse decode).
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
tracker_edit_entry "BD-001" '{"status":"Deprecated","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.4b Open→Deprecated dispatches provider_update" "$TED_CALLS" "|update:42"
assert_contains "4.4b Open→Deprecated closes with not_planned (DP-3 Deprecated row)" \
    "$TED_CALLS" "|close:42:not_planned"
assert_contains "4.4b Open→Deprecated adds status:deprecated label" \
    "$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -c '.add_labels // []')" '"status:deprecated"'

# 4.5 closed→open (Resolved→Open) → update + provider_reopen.
TED_CALLS=""
tracker_edit_entry "BD-001" '{"status":"Open","old_status":"Resolved"}' "$TED_REPO" >/dev/null
assert_contains "4.5 Resolved→Open dispatches provider_update" "$TED_CALLS" "|update:42"
assert_contains "4.5 Resolved→Open reopens" "$TED_CALLS" "|reopen:42"
if [[ "$TED_CALLS" == *"|close:"* ]]; then
    t_fail "4.5 reopen path must NOT also close" "calls=$TED_CALLS"
else
    t_pass "4.5 reopen path does not also close"
fi

# 4.7 BD-204 §3.3a (i): a CONTENT-bearing edit RECOMPOSES the body via the
# C-4.5 composer so the provider_update payload carries BOTH the H2 sections
# AND the pack-entry-body-gz64 blob — regenerated from the SAME entry object,
# atomically (the producer keeps the two views in sync). The status:* label
# swap still rides the same single payload.
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
ted_raw_body=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Open\nFile/Symbol: scripts/foo.sh\nDescription: Implements foo, now improved.\n'
ted_patch=$(jq -n --arg rb "$ted_raw_body" \
    '{description:"Implements foo, now improved.", file_symbol:"scripts/foo.sh", raw_body:$rb}')
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null
assert_contains "4.7 content edit dispatches provider_update" "$TED_CALLS" "|update:42"
ted_body=$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -r '.body // ""')
assert_contains "4.7 recomposed payload carries the gz64 blob" "$ted_body" "pack-entry-body-gz64:"
assert_contains "4.7 recomposed payload carries the ## Description H2" "$ted_body" "## Description"
assert_contains "4.7 recomposed payload carries the edited H2 value" "$ted_body" "Implements foo, now improved."
assert_contains "4.7 recomposed payload carries the ## File / Symbol H2" "$ted_body" "## File / Symbol"
# 4.7b SYNC PROOF: the gz64 blob in the recomposed payload decodes to a raw_body
# whose blob-projected H2 AGREES with the payload's H2 (blob ↔ H2 in sync). Re-
# run the blob's raw_body through the reverse comparator against the payload body
# itself: a synced pair MATCHES (rc=0). Source the reverse lib for the check.
if ! declare -f _tmr_check_blob_h2_divergence >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/scripts/lib/tracker-migrate-reverse.sh"
fi
ted_blob_payload=$(printf '%s' "$ted_body" \
    | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
ted_decoded=$(printf '%s' "$ted_blob_payload" | python3 -c '
import sys, base64, gzip, io
d=sys.stdin.read().strip()
raw=base64.b64decode(d, validate=True)
sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(raw)).read())
sys.stdout.buffer.write(b"X")')
ted_decoded="${ted_decoded%X}"
ted_sync_rc=0
_tmr_check_blob_h2_divergence "$ted_decoded" "$ted_body" 42 BD-001 0 >/dev/null 2>&1 || ted_sync_rc=1
assert_eq "4.7b recomposed blob ↔ H2 agree after provider_update (no divergence)" "0" "$ted_sync_rc"

# 4.7c BD-204 C-8 maiden-run regression (edit-verb projection defect): a
# RAW-BODY-ONLY patch (no description / context / resolution / file_symbol
# in the patch — the `pack tracker edit --raw-body-file` shape) MUST derive
# the H2 projection fields by PARSING the raw_body, never compose hollow
# H2s. Pre-fix, this exact shape composed an empty `## Description` (and no
# other H2s) while the blob carried the full body; the reverse comparator
# then (correctly) flagged `(Description,Resolution,File / Symbol)`
# divergence on every subsequent materialization. PINNED red-green: the
# comparator-CLEAN assert below FAILS on the pre-fix tracker-edit.sh.
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
ted_raw_body=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Open\nFile/Symbol: scripts/foo.sh\nDescription: Raw-body-only edit description.\nContext: Maiden-run C-8 shape.\nResolution: 2026-06-10 — verified via comparator.\n'
ted_patch=$(jq -n --arg rb "$ted_raw_body" '{raw_body:$rb}')
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null
assert_contains "4.7c raw-body-only edit dispatches provider_update" "$TED_CALLS" "|update:42"
ted_body=$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -r '.body // ""')
assert_contains "4.7c raw-body-only edit derives the Description H2 from raw_body" \
    "$ted_body" "Raw-body-only edit description."
assert_contains "4.7c raw-body-only edit derives the File / Symbol H2 from raw_body" \
    "$ted_body" "scripts/foo.sh"
assert_contains "4.7c raw-body-only edit derives the Context H2 from raw_body" \
    "$ted_body" "Maiden-run C-8 shape."
assert_contains "4.7c raw-body-only edit derives the Resolution H2 from raw_body" \
    "$ted_body" "verified via comparator."
# The REAL body comparator is the oracle: decode the payload's gz64 blob and
# run `_tmr_check_blob_h2_divergence` against the payload body itself — a
# correctly-derived projection is CLEAN (rc=0); the pre-fix hollow
# projection DIVERGES (rc=1).
ted_blob_payload=$(printf '%s' "$ted_body" \
    | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
ted_decoded=$(printf '%s' "$ted_blob_payload" | python3 -c '
import sys, base64, gzip, io
d=sys.stdin.read().strip()
raw=base64.b64decode(d, validate=True)
sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(raw)).read())
sys.stdout.buffer.write(b"X")')
ted_decoded="${ted_decoded%X}"
ted_sync_rc=0
_tmr_check_blob_h2_divergence "$ted_decoded" "$ted_body" 42 BD-001 0 >/dev/null 2>&1 || ted_sync_rc=1
assert_eq "4.7c raw-body-only edit: blob ↔ H2 comparator CLEAN (pre-fix shape diverged)" "0" "$ted_sync_rc"

# 4.7d PRECEDENCE (C-8 fix contract): a MIXED patch (raw_body + explicit
# description) — the explicitly-provided field OVERRIDES the parsed value;
# fields ABSENT from the patch still derive from raw_body. (When a caller
# supplies an explicit value that disagrees with raw_body, the blob stays
# the verbatim truth and the comparator's job is to flag exactly that
# divergence — this leg asserts only the precedence contract.)
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
ted_patch=$(jq -n --arg rb "$ted_raw_body" \
    '{raw_body:$rb, description:"Explicit override description."}')
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null
ted_body=$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -r '.body // ""')
assert_contains "4.7d mixed patch: explicit description wins over parsed" \
    "$ted_body" "Explicit override description."
if [[ "$ted_body" == *"Raw-body-only edit description."* ]]; then
    t_fail "4.7d mixed patch: parsed description must NOT appear in the H2" \
        "body carries the parsed value alongside the explicit one"
else
    t_pass "4.7d mixed patch: parsed description does not appear in the H2"
fi
assert_contains "4.7d mixed patch: absent context still derives from raw_body" \
    "$ted_body" "Maiden-run C-8 shape."
assert_contains "4.7d mixed patch: absent resolution still derives from raw_body" \
    "$ted_body" "verified via comparator."

# 4.7e n/a NORMALIZATION SYMMETRY (review F4): an explicit literal-`n/a`
# resolution passes through the SAME bare-`n/a` placeholder normalization
# the forward parser applies to a `Resolved: n/a` line (one seam, no
# divergence-by-override) — trimmed + case-insensitive, exactly like the
# parser's `res.strip().lower() == "n/a"`. Pre-fix, the explicit value
# overrode the parser-normalized EMPTY with a phantom `## Resolution` H2 —
# a GUARANTEED comparator divergence even though the input textually
# AGREED with the raw_body's `Resolved: n/a`.
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
ted_raw_body_na=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Open\nDescription: n/a normalization leg.\nResolved: n/a\n'
ted_patch=$(jq -n --arg rb "$ted_raw_body_na" '{raw_body:$rb, resolution:" N/A "}')
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null
ted_body=$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -r '.body // ""')
if [[ "$ted_body" == *"## Resolution"* ]]; then
    t_fail "4.7e explicit literal-n/a resolution emits NO Resolution H2" \
        "body carries a phantom ## Resolution H2"
else
    t_pass "4.7e explicit literal-n/a resolution emits NO Resolution H2"
fi
# The REAL comparator agrees: blob (Resolved: n/a → parses empty) ↔ H2
# (no Resolution section) are CLEAN — pre-fix this shape DIVERGED.
ted_blob_payload=$(printf '%s' "$ted_body" \
    | sed -nE 's/.*<!-- pack-entry-body-gz64:[[:space:]]*([A-Za-z0-9+/=]+)[[:space:]]*-->.*/\1/p' | head -1)
ted_decoded=$(printf '%s' "$ted_blob_payload" | python3 -c '
import sys, base64, gzip, io
d=sys.stdin.read().strip()
raw=base64.b64decode(d, validate=True)
sys.stdout.buffer.write(gzip.GzipFile(fileobj=io.BytesIO(raw)).read())
sys.stdout.buffer.write(b"X")')
ted_decoded="${ted_decoded%X}"
ted_sync_rc=0
_tmr_check_blob_h2_divergence "$ted_decoded" "$ted_body" 42 BD-001 0 >/dev/null 2>&1 || ted_sync_rc=1
assert_eq "4.7e explicit literal-n/a: blob ↔ H2 comparator CLEAN (pre-fix diverged)" "0" "$ted_sync_rc"

# 4.7f RAW-BODY ID-MATCH GUARD (review F2): a raw_body headed by a
# DIFFERENT entry ID than the edit target refuses with a typed validation
# error BEFORE any provider op — the same id-match gate cmd_new_entry
# enforces on the same grammar. Pre-guard, this shape dispatched rc=0 and
# stored a blob whose verbatim span claimed the WRONG id (invisible to the
# H2 comparator, which compares field values, not ids; the corruption
# surfaced only at the next tree materialization). NB: call WITHOUT a
# command-substitution capture so the stubs' TED_CALLS mutations would
# propagate if a provider op (wrongly) fired; stderr goes to a tmp file.
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
ted_raw_wrong=$'**BD-002 — A different entry**\nType: TODO(version)\nStatus: Open\nDescription: Wrong-id span.\n'
ted_patch=$(jq -n --arg rb "$ted_raw_wrong" '{raw_body:$rb}')
ted_err_out=$(mktemp "${TMPDIR:-/tmp}/tracker-edit-err.XXXXXX")
rc47f=0
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null 2>"$ted_err_out" || rc47f=1
err=$(cat "$ted_err_out"); rm -f "$ted_err_out"
assert_eq "4.7f wrong-id raw_body → rc!=0" "1" "$rc47f"
assert_contains "4.7f wrong-id raw_body → typed validation error" "$err" "ERROR: validation"
assert_contains "4.7f error names both ids" \
    "$err" "BD-001 does not match the raw_body's bold-header ID BD-002"
if [[ -n "$TED_CALLS" ]]; then
    t_fail "4.7f wrong-id raw_body dispatches NO provider op" "calls=$TED_CALLS"
else
    t_pass "4.7f wrong-id raw_body dispatches NO provider op"
fi

# 4.7g RAW-BODY SINGLE-ENTRY GUARD (review F2): a raw_body parsing to
# MORE than one entry span refuses (derivation reads `.[0]` but the blob
# would carry BOTH spans verbatim into the next tree materialization).
TED_CALLS=""
ted_raw_multi=$'**BD-001 — Add foo to bar**\nType: TODO(version)\nStatus: Open\nDescription: First span.\n\n---\n\n**BD-002 — Second span**\nType: TODO(version)\nStatus: Open\nDescription: Second span.\n'
ted_patch=$(jq -n --arg rb "$ted_raw_multi" '{raw_body:$rb}')
ted_err_out=$(mktemp "${TMPDIR:-/tmp}/tracker-edit-err.XXXXXX")
rc47g=0
tracker_edit_entry "BD-001" "$ted_patch" "$TED_REPO" >/dev/null 2>"$ted_err_out" || rc47g=1
err=$(cat "$ted_err_out"); rm -f "$ted_err_out"
assert_eq "4.7g multi-entry raw_body → rc!=0" "1" "$rc47g"
assert_contains "4.7g multi-entry raw_body → typed validation error" "$err" "ERROR: validation"
assert_contains "4.7g error names the parsed count" "$err" "exactly ONE entry span (parsed 2)"
if [[ -n "$TED_CALLS" ]]; then
    t_fail "4.7g multi-entry raw_body dispatches NO provider op" "calls=$TED_CALLS"
else
    t_pass "4.7g multi-entry raw_body dispatches NO provider op"
fi

# 4.7h PROJECTION-ONLY GUARD (review F1 / POQ-1): a projection-only patch
# (content fields, NO raw_body — e.g. the canonical resolve flow
# `--status Resolved --resolution ...`) against an issue whose CURRENT
# body carries a pack-entry-body-gz64 blob REFUSES fail-loud with a typed
# validation error BEFORE any provider write. Pre-guard, this shape
# recomposed a BLOB-LESS body and provider_update REPLACED the issue body,
# silently destroying the verbatim-span SSOT (silent: both reverse
# comparators skip blob-less issues). Stub provider_get to serve a
# blob-carrying current body; the fake's write state (TED_CALLS /
# TED_UPDATE_PAYLOAD) proves the issue body is left UNCHANGED.
ted_cur_body_47h='pre-existing issue body
<!-- pack-id: BD-001 -->
<!-- pack-entry-body-gz64: SGVsbG8= -->'
# NB: the lib invokes provider_get inside a command substitution (a
# subshell), so the stub logs to a FILE — a shell-variable mutation would
# not propagate back to this (parent) shell.
TED_GET_LOG="$TED_REPO/provider-get-calls.log"
: > "$TED_GET_LOG"
provider_get() {
    printf 'get:%s\n' "$1" >> "$TED_GET_LOG"
    jq -n --arg b "$ted_cur_body_47h" '{id: "42", body: $b, state: "open"}'
}
TED_CALLS=""
TED_UPDATE_PAYLOAD="__UNTOUCHED__"
ted_err_out=$(mktemp "${TMPDIR:-/tmp}/tracker-edit-err.XXXXXX")
rc47h=0
tracker_edit_entry "BD-001" \
    '{"status":"Resolved","old_status":"Open","resolution":"2026-06-12 — done."}' \
    "$TED_REPO" >/dev/null 2>"$ted_err_out" || rc47h=1
err=$(cat "$ted_err_out"); rm -f "$ted_err_out"
assert_eq "4.7h projection-only patch on blob-carrying issue → rc!=0" "1" "$rc47h"
assert_contains "4.7h refusal is a typed validation error" "$err" "ERROR: validation"
assert_contains "4.7h refusal names the blob constraint" "$err" "pack-entry-body-gz64"
assert_contains "4.7h refusal is actionable (--raw-body-file)" "$err" "--raw-body-file"
assert_contains "4.7h guard read the current body via provider_get" \
    "$(cat "$TED_GET_LOG")" "get:42"
if [[ -n "$TED_CALLS" ]]; then
    t_fail "4.7h refused edit dispatches NO provider write (issue body unchanged)" \
        "calls=$TED_CALLS"
else
    t_pass "4.7h refused edit dispatches NO provider write (issue body unchanged)"
fi
assert_eq "4.7h update payload untouched (no body write reached the fake)" \
    "__UNTOUCHED__" "$TED_UPDATE_PAYLOAD"

# 4.7i STATUS/LABEL-ONLY PATCHES KEEP WORKING (review F1, non-regression
# pin): a patch with NO content fields never enters the recompose branch —
# it neither reads the current body (no provider_get) nor recomposes it
# (update payload carries NO body key), so the blob-carrying issue body is
# untouched by construction and the status flip still dispatches.
# provider_get stays stubbed from 4.7h: the leg proves the guard does NOT
# consult it on this shape.
: > "$TED_GET_LOG"
TED_CALLS=""
TED_UPDATE_PAYLOAD=""
tracker_edit_entry "BD-001" '{"status":"Deferred","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.7i status-only patch on blob-carrying issue still updates" \
    "$TED_CALLS" "|update:42"
assert_eq "4.7i status-only patch never reads the body (no recompose, no guard)" \
    "" "$(cat "$TED_GET_LOG")"
assert_eq "4.7i status-only update payload carries NO body key (blob untouched)" \
    "false" "$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq 'has("body")')"

# 4.8 unmapped pack-id → typed not-found error (no provider op).
TED_CALLS=""
err=$(tracker_edit_entry "BD-999" '{"body":"x"}' "$TED_REPO" 2>&1 1>/dev/null) || true
assert_contains "4.8 unmapped id → not-found error" "$err" "ERROR: not-found"
if [[ -n "$TED_CALLS" ]]; then
    t_fail "4.8 unmapped id must dispatch no provider op" "calls=$TED_CALLS"
else
    t_pass "4.8 unmapped id dispatches no provider op"
fi

# 4.9 BD-204 Mode-3 ops contract §2 (plan leg 6): tracker_edit_entry
# stamps migration.last_tracker_write on SUCCESS — and NOT on failure
# (the stamp runs only after the FULL mutation sequence, update + any
# boundary cross). Re-point the stubbed config resolution at a REAL
# local tracker.toml so `tracker_edit_stamp_last_write` has a target.
TED_CFG="$TED_REPO/tracker.toml"
_ted_write_cfg() {
    cat > "$TED_CFG" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/fixture-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
}
_ted_write_cfg
eval "tracker_config_resolve_path() { echo '$TED_CFG'; }"

# 4.9a success → stamped.
TED_CALLS=""
tracker_edit_entry "BD-001" '{"status":"Deferred","old_status":"Open"}' "$TED_REPO" >/dev/null
if grep -q 'last_tracker_write = "' "$TED_CFG"; then
    t_pass "4.9a successful edit stamps last_tracker_write"
else
    t_fail "4.9a successful edit stamps last_tracker_write" "key absent"
fi

# 4.9b provider_update failure → rc!=0, NO stamp.
_ted_write_cfg
provider_update() { TED_CALLS="$TED_CALLS|update:$1"; return 1; }
rc49b=0
tracker_edit_entry "BD-001" '{"status":"Deferred","old_status":"Open"}' "$TED_REPO" >/dev/null 2>&1 || rc49b=1
assert_eq "4.9b failed update → rc!=0" "1" "$rc49b"
if grep -q 'last_tracker_write = "' "$TED_CFG"; then
    t_fail "4.9b failed update does NOT stamp last_tracker_write" "key present"
else
    t_pass "4.9b failed update does NOT stamp last_tracker_write"
fi

# 4.9c update succeeds but the boundary cross fails → rc!=0, NO stamp
# (the stamp requires the FULL sequence — update + close — to succeed).
_ted_write_cfg
provider_update() { TED_CALLS="$TED_CALLS|update:$1"; TED_UPDATE_PAYLOAD="$2"; return 0; }
provider_close()  { TED_CALLS="$TED_CALLS|close:$1:$2"; return 1; }
rc49c=0
tracker_edit_entry "BD-001" '{"status":"Resolved","old_status":"Open"}' "$TED_REPO" >/dev/null 2>&1 || rc49c=1
assert_eq "4.9c failed boundary cross → rc!=0" "1" "$rc49c"
if grep -q 'last_tracker_write = "' "$TED_CFG"; then
    t_fail "4.9c failed boundary cross does NOT stamp last_tracker_write" "key present"
else
    t_pass "4.9c failed boundary cross does NOT stamp last_tracker_write"
fi
# Restore the all-success stubs.
provider_close()  { TED_CALLS="$TED_CALLS|close:$1:$2"; return 0; }

rm -rf "$TED_REPO"

# ─────────────────────────────────────────────────────────────────
# Group 5: BD-204 OQ-A verbs — `pack tracker edit` / `pack tracker
# new-entry` (PLAN-BD-204-MODE3-OPS-CONTRACT.md §5 leg 10)
# ─────────────────────────────────────────────────────────────────
#
# End-to-end via `bash scripts/pack-tracker.sh <verb>` (a fresh shell —
# the Group-4 function stubs do not apply) against a stateful fake gh:
# `issue create` captures the composed body/labels/title and returns a
# fixed issue URL; `issue view` serves the captured body back so the
# new-entry verb's finishing tree-rebuild materializes exactly what was
# created. All offline; zero live GitHub calls.

printf "\n=== Group 5: BD-204 OQ-A verbs (pack tracker edit / new-entry) ===\n"

PACK_TRACKER_SH="$REPO_ROOT/scripts/pack-tracker.sh"
G5_REPO=$(mktemp -d "${TMPDIR:-/tmp}/tracker-verbs.XXXXXX")
G5_STATE=$(mktemp -d "${TMPDIR:-/tmp}/tracker-verbs-state.XXXXXX")
mkdir -p "$G5_REPO/pack-ops" "$G5_REPO/.pack-tracker"
cat > "$G5_REPO/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/fixture-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
printf '{}\n' > "$G5_REPO/.pack-tracker/id-map.json"

G5_FAKE=$(mktemp -d "${TMPDIR:-/tmp}/tracker-verbs-fake.XXXXXX")
cat > "$G5_FAKE/gh" <<'FG5'
#!/usr/bin/env bash
STATE="__G5_STATE__"
printf '%s\n' "$*" >> "$STATE/gh.log"
case "$1 $2" in
    "issue create")
        # Kill switch (leg 5.7): force the create to fail like a real
        # backend error so the new-entry failure branch is exercised.
        if [[ -n "${G5_CREATE_FAIL:-}" ]]; then
            echo "fake-gh(G5): issue create forced failure (provider_create-failure leg)" >&2
            exit 1
        fi
        bf=""; lab=""; ttl=""
        args=("$@")
        for ((i=0; i<$#; i++)); do
            case "${args[$i]}" in
                --body-file) bf="${args[$((i+1))]}" ;;
                --label)     lab="${args[$((i+1))]}" ;;
                --title)     ttl="${args[$((i+1))]}" ;;
            esac
        done
        [[ -n "$bf" ]] && cp "$bf" "$STATE/created-body"
        printf '%s' "$lab" > "$STATE/created-labels"
        printf '%s' "$ttl" > "$STATE/created-title"
        echo "http://x/issues/77"
        ;;
    "issue list") echo '[]' ;;
    "issue view")
        python3 - "$STATE/created-body" "$STATE/created-labels" "$STATE/created-title" <<'PY'
import json, sys
body = open(sys.argv[1]).read()
labels = [l for l in open(sys.argv[2]).read().split(",") if l]
title = open(sys.argv[3]).read()
print(json.dumps({
    "number": 77, "title": title, "body": body,
    "state": "OPEN", "stateReason": None,
    "labels": [{"name": l} for l in labels],
    "assignees": [], "milestone": None,
    "createdAt": None, "updatedAt": None, "closedAt": None,
    "url": "http://x/issues/77",
}))
PY
        ;;
    "issue edit")
        bf=""
        args=("$@")
        for ((i=0; i<$#; i++)); do
            [[ "${args[$i]}" == "--body-file" ]] && bf="${args[$((i+1))]}"
        done
        [[ -n "$bf" ]] && cp "$bf" "$STATE/edited-body"
        ;;
    "issue close") ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG5
sed -i.bak "s|__G5_STATE__|$G5_STATE|" "$G5_FAKE/gh"
rm -f "$G5_FAKE/gh.bak"
chmod +x "$G5_FAKE/gh"

G5_BODY=$(mktemp "${TMPDIR:-/tmp}/tracker-verbs-body.XXXXXX")
cat > "$G5_BODY" <<'EOF'
**BD-002 — New tracked entry**
Type: TODO(version)
Status: Open
Description: Created via the new-entry verb.
EOF

G5_PATH_SAVED="$PATH"
export PATH="$G5_FAKE:$PATH"

# 5.1 new-entry happy path: compose + create + labels + id-map append +
# last_tracker_write stamp + tree materialization (+ _toc.md).
out51=$(bash "$PACK_TRACKER_SH" new-entry --id BD-002 --body-file "$G5_BODY" --repo-root "$G5_REPO" 2>&1)
rc51=$?
assert_eq       "5.1 new-entry rc=0"                          "0" "$rc51"
assert_contains "5.1 reports the created gh-id"               "$out51" "new-entry: created BD-002 (gh-id 77)"
assert_eq "5.1 created title is 'BD-NNN: <title>' form" \
    "BD-002: New tracked entry" "$(cat "$G5_STATE/created-title" 2>/dev/null)"
g5_labels=$(cat "$G5_STATE/created-labels" 2>/dev/null)
assert_contains "5.1 labels carry bd-entry (forward label map)"      "$g5_labels" "bd-entry"
assert_contains "5.1 labels carry status:open (forward label map)"   "$g5_labels" "status:open"
assert_contains "5.1 labels carry template:bd-v11.0"                 "$g5_labels" "template:bd-v11.0"
g5_created_body=$(cat "$G5_STATE/created-body" 2>/dev/null)
assert_contains "5.1 composed body carries the pack-id marker" "$g5_created_body" "<!-- pack-id: BD-002 -->"
assert_contains "5.1 composed body carries the gz64 blob"      "$g5_created_body" "pack-entry-body-gz64:"
assert_contains "5.1 composed body carries the H2 projection"  "$g5_created_body" "## Description"
assert_eq "5.1 id-map gains BD-002 → 77" "77" \
    "$(jq -r '.["BD-002"].id' "$G5_REPO/.pack-tracker/id-map.json")"
assert_contains "5.1 last_tracker_write stamped" \
    "$(cat "$G5_REPO/tracker.toml")" 'last_tracker_write = "'
[[ -f "$G5_REPO/backlog/BD-002.md" ]] \
    && t_pass "5.1 entry materialized in the tree (tree-rebuild finish)" \
    || t_fail "5.1 entry materialized in the tree (tree-rebuild finish)"
[[ -f "$G5_REPO/backlog/_toc.md" ]] \
    && t_pass "5.1 _toc.md regenerated" \
    || t_fail "5.1 _toc.md regenerated"
# Byte-faithful round-trip: tree file lines 2..EOF == the input span.
if cmp -s <(sed -n '2,$p' "$G5_REPO/backlog/BD-002.md") "$G5_BODY"; then
    t_pass "5.1 tree entry lines 2..EOF byte-equal to the input span"
else
    t_fail "5.1 tree entry lines 2..EOF byte-equal to the input span" \
        "got: $(sed -n '2,$p' "$G5_REPO/backlog/BD-002.md" | head -c 200)"
fi

# 5.2 duplicate-id refusal against the id-map.
out52=$(bash "$PACK_TRACKER_SH" new-entry --id BD-002 --body-file "$G5_BODY" --repo-root "$G5_REPO" 2>&1)
rc52=$?
[[ "$rc52" -ne 0 ]] \
    && t_pass "5.2 duplicate id → new-entry refuses (rc!=0)" \
    || t_fail "5.2 duplicate id → new-entry refuses (rc!=0)" "rc=$rc52"
assert_contains "5.2 refusal names the id-map"     "$out52" "already exists in the id-map"
assert_contains "5.2 refusal points at edit"       "$out52" "pack tracker edit"

# 5.3 --id shape validation (canonical, no letter suffix) + id/body
# mismatch refusal.
out53=$(bash "$PACK_TRACKER_SH" new-entry --id BD-2b --body-file "$G5_BODY" --repo-root "$G5_REPO" 2>&1)
rc53=$?
[[ "$rc53" -ne 0 ]] \
    && t_pass "5.3 malformed --id → refusal (rc!=0)" \
    || t_fail "5.3 malformed --id → refusal (rc!=0)" "rc=$rc53"
assert_contains "5.3 refusal names the canonical shape" "$out53" "^BD-[0-9]+\$"
out53b=$(bash "$PACK_TRACKER_SH" new-entry --id BD-003 --body-file "$G5_BODY" --repo-root "$G5_REPO" 2>&1)
rc53b=$?
[[ "$rc53b" -ne 0 ]] \
    && t_pass "5.3 --id vs body-header mismatch → refusal (rc!=0)" \
    || t_fail "5.3 --id vs body-header mismatch → refusal (rc!=0)" "rc=$rc53b"
assert_contains "5.3 mismatch refusal names both ids" "$out53b" "does not match"

# 5.4 edit verb: flag → patch-JSON mapping drives the lib path — a
# status flip dispatches `issue edit` (label swap) + `issue close`
# (DP-3 boundary cross), and stamps last_tracker_write.
: > "$G5_STATE/gh.log"
out54=$(bash "$PACK_TRACKER_SH" edit BD-002 --status Resolved --old-status Open --repo-root "$G5_REPO" 2>&1)
rc54=$?
assert_eq "5.4 edit rc=0" "0" "$rc54"
g5_log=$(cat "$G5_STATE/gh.log")
assert_contains "5.4 status flip dispatches issue edit 77"      "$g5_log" "issue edit 77"
assert_contains "5.4 label swap adds status:resolved"           "$g5_log" "status:resolved"
assert_contains "5.4 label swap removes status:open"            "$g5_log" "status:open"
assert_contains "5.4 boundary cross closes with completed"      "$g5_log" "issue close 77 --reason completed"
assert_contains "5.4 edit output reports updated=true"          "$out54" '"updated": true'

# 5.5 edit verb: content flags recompose blob + H2 via the lib's
# composer path (the --raw-body-file bytes reach the issue body).
: > "$G5_STATE/gh.log"
G5_BODY2=$(mktemp "${TMPDIR:-/tmp}/tracker-verbs-body2.XXXXXX")
cat > "$G5_BODY2" <<'EOF'
**BD-002 — New tracked entry**
Type: TODO(version)
Status: Resolved
Description: Edited via the edit verb.
EOF
out55=$(bash "$PACK_TRACKER_SH" edit BD-002 --description "Edited via the edit verb." --raw-body-file "$G5_BODY2" --repo-root "$G5_REPO" 2>&1)
rc55=$?
assert_eq "5.5 content edit rc=0" "0" "$rc55"
g5_edited=$(cat "$G5_STATE/edited-body" 2>/dev/null)
assert_contains "5.5 edited body carries the gz64 blob"        "$g5_edited" "pack-entry-body-gz64:"
assert_contains "5.5 edited body carries the new H2 value"     "$g5_edited" "Edited via the edit verb."

# 5.6 edit verb: empty patch refusal.
out56=$(bash "$PACK_TRACKER_SH" edit BD-002 --repo-root "$G5_REPO" 2>&1)
rc56=$?
[[ "$rc56" -ne 0 ]] \
    && t_pass "5.6 empty patch → edit refuses (rc!=0)" \
    || t_fail "5.6 empty patch → edit refuses (rc!=0)" "rc=$rc56"
assert_contains "5.6 refusal names empty patch" "$out56" "empty patch"

# 5.7 new-entry provider_create failure: the failure branch's stated
# invariant — typed partial-write, rc!=0, NO id-map entry written, NO
# last_tracker_write re-stamp, NO tree materialization (mapping-save +
# freshness stamp + the tree-rebuild finish are ordered strictly AFTER
# a successful create). G5_CREATE_FAIL drives the fake gh's failing
# `issue create` arm.
G5_BODY3=$(mktemp "${TMPDIR:-/tmp}/tracker-verbs-body3.XXXXXX")
cat > "$G5_BODY3" <<'EOF'
**BD-004 — Create-failure probe**
Type: TODO(version)
Status: Open
Description: Must never land; provider_create fails in this leg.
EOF
g5_idmap_before=$(cat "$G5_REPO/.pack-tracker/id-map.json")
g5_toml_before=$(cat "$G5_REPO/tracker.toml")
out57=$(G5_CREATE_FAIL=1 bash "$PACK_TRACKER_SH" new-entry --id BD-004 --body-file "$G5_BODY3" --repo-root "$G5_REPO" 2>&1)
rc57=$?
[[ "$rc57" -ne 0 ]] \
    && t_pass "5.7 create failure → new-entry rc!=0" \
    || t_fail "5.7 create failure → new-entry rc!=0" "rc=$rc57"
assert_contains "5.7 typed partial-write error surfaced"   "$out57" "ERROR: partial-write"
assert_contains "5.7 error states the no-id-map invariant" "$out57" "no id-map entry written"
assert_eq "5.7 id-map byte-unchanged (no BD-004 entry)" \
    "$g5_idmap_before" "$(cat "$G5_REPO/.pack-tracker/id-map.json")"
assert_eq "5.7 tracker.toml byte-unchanged (last_tracker_write NOT re-stamped)" \
    "$g5_toml_before" "$(cat "$G5_REPO/tracker.toml")"
[[ ! -f "$G5_REPO/backlog/BD-004.md" ]] \
    && t_pass "5.7 no tree file materialized (tree-rebuild path never runs)" \
    || t_fail "5.7 no tree file materialized (tree-rebuild path never runs)"

# 5.8 edit verb pack-surface gate: a client-shaped repo (docs/pack/
# marker, NO pack-ops/) auto-detects surface=client; `edit` is
# pack-surface-only at v11.0 and refuses naming BD-207 — the same
# fail-loud gate cmd_tree_rebuild / cmd_new_entry carry (reverse-suite
# leg 8.4 pins the tree-rebuild side of this gate).
G5_CLIENT=$(mktemp -d "${TMPDIR:-/tmp}/tracker-verbs-client.XXXXXX")
mkdir -p "$G5_CLIENT/docs/pack"
cat > "$G5_CLIENT/docs/pack/tracker.toml" <<'EOF'
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/fixture-repo"
[mode]
state = "tracker"
[id_namespace]
prefix = "TD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
out58=$(bash "$PACK_TRACKER_SH" edit BD-002 --status Resolved --repo-root "$G5_CLIENT" 2>&1)
rc58=$?
[[ "$rc58" -ne 0 ]] \
    && t_pass "5.8 client surface → edit refuses (rc!=0)" \
    || t_fail "5.8 client surface → edit refuses (rc!=0)" "rc=$rc58"
assert_contains "5.8 refusal names pack-surface-only" "$out58" "pack surface only at v11.0"
assert_contains "5.8 refusal names BD-207"            "$out58" "BD-207"

export PATH="$G5_PATH_SAVED"
rm -rf "$G5_REPO" "$G5_STATE" "$G5_FAKE" "$G5_BODY" "$G5_BODY2" "$G5_BODY3" "$G5_CLIENT"

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
