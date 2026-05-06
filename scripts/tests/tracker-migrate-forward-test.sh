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
body=$(tmf_compose_issue_body "BD-001" "desc text" "ctx text" "" "")
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
body_td=$(tmf_compose_issue_body "TD-010" "td desc" "" "" "")
assert_contains "2.5 td body has td-v11.0 marker" "$body_td" "<!-- template_version: td-v11.0 -->"
# Resolution section appears when resolution is non-empty
body_res=$(tmf_compose_issue_body "BD-003" "d" "" "fixed in abc" "")
assert_contains "2.5 body has Resolution section" "$body_res" "## Resolution"
assert_contains "2.5 body has resolution text"    "$body_res" "fixed in abc"
# File/Symbol section (Finding #3 fix) appears when non-empty
body_fs=$(tmf_compose_issue_body "BD-001" "d" "" "" "scripts/foo.sh")
assert_contains "2.5 body has File / Symbol section"   "$body_fs" "## File / Symbol"
assert_contains "2.5 body has file_symbol value"       "$body_fs" "scripts/foo.sh"
# File/Symbol omitted when empty
body_no_fs=$(tmf_compose_issue_body "BD-001" "d" "" "" "")
if printf '%s' "$body_no_fs" | grep -q "^## File / Symbol"; then
    t_fail "2.5 body File/Symbol absent when empty" "section unexpectedly present"
else
    t_pass "2.5 body File/Symbol absent when empty"
fi

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

# 3.10 status subcommand reports the V2 §22.1 8-field surface.
status_out=$(tracker_migrate_status_report "$TEST_REPO" 2>&1)
assert_contains "3.10 status reports tracker mode"        "$status_out" "tracker mode:"
assert_contains "3.10 status reports backend"             "$status_out" "backend:"
assert_contains "3.10 status reports repo"                "$status_out" "repo:"
assert_contains "3.10 status reports mapping count"       "$status_out" "mapping count:"
assert_contains "3.10 status reports mapping freshness"   "$status_out" "mapping freshness:"
assert_contains "3.10 status reports mirror freshness"    "$status_out" "mirror freshness:"
assert_contains "3.10 status reports template freshness"  "$status_out" "template freshness:"
assert_contains "3.10 status reports last forward run"    "$status_out" "last forward run:"
assert_contains "3.10 status reports last reverse run"    "$status_out" "last reverse run:"

# 3.11 missing tracker.toml: forward fails with typed error.
TEST_REPO3=$(mktemp -d -t tmf-repo-noconf.XXXXXX)
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO3/BACKLOG.md"
err=$(tracker_migrate_forward_run "$TEST_REPO3" 0 0 2>&1) || true
assert_contains "3.11 missing tracker.toml → validation" "$err" "ERROR: validation"
assert_contains "3.11 error mentions pack tracker init" "$err" "pack tracker init"

# ─────────────────────────────────────────────────────────────────
# Group 4: review-fix verifications
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: review-fix verifications ===\n"

# 4.1 Mirror-header idempotency (Finding #2): three consecutive runs
# of _tmf_regen_mirror against a clean-body fixture produce byte-equal
# files modulo the "Last regenerated" timestamp line.
mtmp=$(mktemp -t tmf-mirror-idem.XXXXXX)
printf 'Some BACKLOG body content.\nLine two.\n' > "$mtmp"
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap1=$(grep -v "Last regenerated:" "$mtmp")
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap2=$(grep -v "Last regenerated:" "$mtmp")
_tmf_regen_mirror "$mtmp" "test-org/test-repo"
snap3=$(grep -v "Last regenerated:" "$mtmp")
assert_eq "4.1 mirror regen run-2 ≡ run-1 (modulo timestamp)" "$snap1" "$snap2"
assert_eq "4.1 mirror regen run-3 ≡ run-1 (modulo timestamp)" "$snap1" "$snap3"
# Body content survives all three runs.
assert_contains "4.1 body line preserved across runs" "$snap1" "Some BACKLOG body content."
rm -f "$mtmp"

# 4.2 File/Symbol round-trip (Finding #3): an entry with File/Symbol
# set ships through to the issue body. Use the parser+composer chain
# directly (the fixture BACKLOG.md has File/Symbol on every entry).
entries_for_fs=$(tmf_parse_backlog "$FIXTURES/BACKLOG.md")
entry_bd1=$(printf '%s' "$entries_for_fs" | jq -c '.[0]')
fs_value=$(printf '%s' "$entry_bd1" | jq -r '.file_symbol')
assert_eq "4.2 parser captures file_symbol BD-001" "scripts/foo.sh" "$fs_value"
desc_bd1=$(printf '%s' "$entry_bd1" | jq -r '.description')
ctx_bd1=$(printf  '%s' "$entry_bd1" | jq -r '.context')
res_bd1=$(printf  '%s' "$entry_bd1" | jq -r '.resolution')
body_bd1=$(tmf_compose_issue_body "BD-001" "$desc_bd1" "$ctx_bd1" "$res_bd1" "$fs_value")
assert_contains "4.2 composed body has File / Symbol heading" "$body_bd1" "## File / Symbol"
assert_contains "4.2 composed body has scripts/foo.sh"        "$body_bd1" "scripts/foo.sh"

# 4.3 Partial-write surfacing (Finding #5): fake gh that fails on
# `issue close` produces an end-of-run partial-write typed error.
FAKE_BIN_PF=$(mktemp -d -t tmf-fakebin-pf.XXXXXX)
GH_LOG_PF=$(mktemp -t tmf-ghlog-pf.XXXXXX)
ISSUE_COUNTER_PF=$(mktemp -t tmf-counter-pf.XXXXXX)
echo "200" > "$ISSUE_COUNTER_PF"

cat > "$FAKE_BIN_PF/gh" <<FAKEGH_PF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_PF"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_PF")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_PF"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        echo "HTTP 422: cannot close issue" >&2
        exit 1
        ;;
    "issue comment")          ;;
    "issue edit")             ;;
    "search issues")          echo '[]' ;;
    "issue list")             echo '[]' ;;
    "issue view")             echo '{"labels":[], "assignees":[]}' ;;
    "repo view")              echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")            echo '{}' ;;
    "extension list")         echo "" ;;
    *)                        ;;
esac
exit 0
FAKEGH_PF
chmod +x "$FAKE_BIN_PF/gh"

# Run forward with fake-gh that fails on close. Expect rc=1 + partial-write.
TEST_REPO_PF=$(mktemp -d -t tmf-repo-pf.XXXXXX)
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO_PF/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION_PLAN.md" "$TEST_REPO_PF/IMPLEMENTATION_PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO_PF/tracker.toml"

PATH_SAVED="$PATH"
export PATH="$FAKE_BIN_PF:$PATH_SAVED"
# `|| true` would mask the non-zero rc we are testing for. Without it
# and without `set -e`, the assignment's rc propagates to $?.
output_pf=$(tracker_migrate_forward_run "$TEST_REPO_PF" 0 0 2>&1)
rc_pf=$?
export PATH="$PATH_SAVED"

assert_eq "4.3 partial-failure run rc=1"             "1" "$rc_pf"
assert_contains "4.3 surfaces ERROR: partial-write"  "$output_pf" "ERROR: partial-write"
assert_contains "4.3 partial-write names step-8 close" "$output_pf" "step-8 close"
assert_contains "4.3 partial-write next-step verb"   "$output_pf" "→ Run: see resume options"

# Mapping file IS persisted even on partial failure (Finding #7 fix).
mfile_pf="$TEST_REPO_PF/.pack-tracker/id-map.json"
[[ -f "$mfile_pf" ]] && t_pass "4.3 mapping persisted on partial failure" \
    || t_fail "4.3 mapping persisted on partial failure" "missing $mfile_pf"

rm -rf "$FAKE_BIN_PF" "$GH_LOG_PF" "$ISSUE_COUNTER_PF" "$TEST_REPO_PF"

# 4.4 Body-marker recovery (Findings #1 + #8): fake gh that returns
# a search hit AND a matching body marker for BD-001 → BD-065 should
# treat the entry as recovered (registered in mapping, not re-created).
FAKE_BIN_REC=$(mktemp -d -t tmf-fakebin-rec.XXXXXX)
GH_LOG_REC=$(mktemp -t tmf-ghlog-rec.XXXXXX)
ISSUE_COUNTER_REC=$(mktemp -t tmf-counter-rec.XXXXXX)
echo "300" > "$ISSUE_COUNTER_REC"

cat > "$FAKE_BIN_REC/gh" <<'FAKEGH_REC'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "@@GH_LOG@@"

# Special-case BD-001 recovery: search returns a hit, view returns
# matching body marker. Match on substring of "$*" so quote-fragility
# in case patterns is avoided.
all="$*"
case "$all" in
    *"search issues"*"BD-001:"*)
        # Raw `gh search issues --json ...` shape: an array of objects.
        # Provider's normalizer wraps it into the {items, next_cursor} envelope.
        echo '[{"number":555,"title":"BD-001: Add foo","url":"https://github.com/fixture-org/fixture-repo/issues/555","state":"OPEN","labels":[]}]'
        exit 0
        ;;
    *"issue view 555"*)
        # Raw `gh issue view 555 --json ...` shape (flat object).
        # Body contains the matching pack-id marker → recovery succeeds.
        printf '%s\n' '{"number":555,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n<!-- template_version: bd-v11.0 -->","state":"OPEN","stateReason":null,"labels":[],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"https://github.com/fixture-org/fixture-repo/issues/555"}'
        exit 0
        ;;
esac

case "$1 $2" in
    "issue create")
        counter=$(cat "@@COUNTER@@")
        next=$((counter + 1))
        echo "$next" > "@@COUNTER@@"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "$next"
        ;;
    "issue close"|"issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")    echo '[]' ;;
    "issue list")       echo '[]' ;;
    "issue view")       echo '{"labels":[], "assignees":[]}' ;;
    "repo view")        echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")      echo '{}' ;;
    "extension list")   echo "" ;;
    *)                  ;;
esac
exit 0
FAKEGH_REC
# Substitute placeholders to avoid heredoc-quoting headaches.
sed -i.bak -e "s|@@GH_LOG@@|$GH_LOG_REC|g" -e "s|@@COUNTER@@|$ISSUE_COUNTER_REC|g" "$FAKE_BIN_REC/gh"
rm -f "$FAKE_BIN_REC/gh.bak"
chmod +x "$FAKE_BIN_REC/gh"

TEST_REPO_REC=$(mktemp -d -t tmf-repo-rec.XXXXXX)
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO_REC/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION_PLAN.md" "$TEST_REPO_REC/IMPLEMENTATION_PLAN.md"
cp "$FIXTURES/tracker.toml" "$TEST_REPO_REC/tracker.toml"

export PATH="$FAKE_BIN_REC:$PATH_SAVED"
output_rec=$(tracker_migrate_forward_run "$TEST_REPO_REC" 0 0 2>&1)
rc_rec=$?
export PATH="$PATH_SAVED"

assert_eq "4.4 recovery run rc=0" "0" "$rc_rec"
# Mapping should have BD-001 with id=555 (recovered, not freshly created).
mfile_rec="$TEST_REPO_REC/.pack-tracker/id-map.json"
[[ -f "$mfile_rec" ]] || t_fail "4.4 mapping file written" "missing"
bd1_id=$(jq -r '.["BD-001"].id' "$mfile_rec")
assert_eq "4.4 BD-001 mapped to recovered id 555 (not a new create)" "555" "$bd1_id"
# Output reports recovered counter.
assert_contains "4.4 output reports recovered" "$output_rec" "recovered:"

rm -rf "$FAKE_BIN_REC" "$GH_LOG_REC" "$ISSUE_COUNTER_REC" "$TEST_REPO_REC"

# 4.5 --mirror-only flag (BD-065 review fix #10): runs only step 10
# (mirror regen). No issue creates, no provider calls touching the
# tracker. Used by `pack tracker mirror-rebuild` to refresh the
# mirror header timestamp without re-running forward.
GH_LOG_MO=$(mktemp -t tmf-ghlog-mo.XXXXXX)
FAKE_BIN_MO=$(mktemp -d -t tmf-fakebin-mo.XXXXXX)
cat > "$FAKE_BIN_MO/gh" <<FAKE_GH_MO
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_MO"
exit 0
FAKE_GH_MO
chmod +x "$FAKE_BIN_MO/gh"

TEST_REPO_MO=$(mktemp -d -t tmf-repo-mo.XXXXXX)
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO_MO/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION_PLAN.md" "$TEST_REPO_MO/IMPLEMENTATION_PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_MO/tracker.toml"

export PATH="$FAKE_BIN_MO:$PATH_SAVED"
output_mo=$(tracker_migrate_forward_run "$TEST_REPO_MO" 0 0 1 2>&1)
rc_mo=$?
export PATH="$PATH_SAVED"

assert_eq "4.5 --mirror-only rc=0" "0" "$rc_mo"
assert_contains "4.5 --mirror-only reports refresh" "$output_mo" "mirror header refreshed"
# Zero gh calls: no issue create, no search, no view.
n_gh_calls=$(wc -l < "$GH_LOG_MO" | tr -d ' ')
assert_eq "4.5 --mirror-only invokes 0 gh calls" "0" "$n_gh_calls"
# Mirror header is now present in BACKLOG.md.
first_line=$(head -n 1 "$TEST_REPO_MO/BACKLOG.md")
assert_eq "4.5 --mirror-only writes header line 1" "<!--" "$first_line"
# No mapping file or checkpoint file written.
[[ ! -f "$TEST_REPO_MO/.pack-tracker/id-map.json" ]] \
    && t_pass "4.5 --mirror-only writes no id-map.json" \
    || t_fail "4.5 --mirror-only writes no id-map.json"

rm -rf "$FAKE_BIN_MO" "$GH_LOG_MO" "$TEST_REPO_MO"

# Cleanup of Group 3 globals.
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
