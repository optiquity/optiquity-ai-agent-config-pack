#!/usr/bin/env bash
# scripts/tests/tracker-migrate-forward-test.sh — offline test suite
# for V1 §6.2 forward migration (BD-065).
#
# Three groups:
#   1. Parser correctness — fixture BACKLOG / IMPLEMENTATION-PLAN
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

# BD-134: keep test runtimes bounded — skip real backoff sleeps.
# The retry sweep is exercised in this suite (4.3 + Group 7) and in
# the dedicated tracker-bd134-close-retry-test.sh; both rely on env
# overrides to avoid 1s/2s/4s sleeps during CI.
export TMF_CLOSE_RETRY_BACKOFF_SECS="0 0 0"

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

phases=$(tmf_parse_implementation_plan "$FIXTURES/IMPLEMENTATION-PLAN.md")
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
# BD-132 F-7: track which issue numbers have been closed so the
# `issue list --state closed --label X` poll (Part 1 stabilization)
# returns a count that grows as `issue close` is called. This lets
# the close-stabilization helper see the closes propagate, which is
# what its label-scoped poll measures on a real repo.
CLOSED_IDS_FILE=$(mktemp -t tmf-closed.XXXXXX)
: > "$CLOSED_IDS_FILE"
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
    "issue close")
        # Track the closed id so the stabilization poll (BD-132 F-7)
        # can see it reflected in subsequent `issue list --state
        # closed --label …` calls. The id is the 3rd positional arg.
        printf '%s\n' "\$3" >> "$CLOSED_IDS_FILE"
        ;;
    "issue reopen"|"issue edit"|"issue comment")
        # No stdout needed for these — caller doesn't parse.
        ;;
    "search issues")
        # Default: empty result set (no marker found upstream).
        # Forces all entries down the create path.
        echo '[]'
        ;;
    "issue list")
        # BD-132 F-7: when the caller is the close-stabilization
        # poll (state=closed scoped to an entry-label), reflect the
        # tracked closed ids. For all other list calls (open
        # rosters, search, etc.) keep the legacy empty-array
        # response so the rest of the test suite is unaffected.
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_FILE") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
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
# BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.
TEST_REPO=$(mktemp -d -t tmf-repo.XXXXXX)
mkdir -p "$TEST_REPO/pack-ops"
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO/IMPLEMENTATION-PLAN.md"
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

# 3.5b BATCH-17 F1: step 7 / 7b now route through
# tracker_links_create_blocked_by, which persists every successful
# blocked-by edge to the cycle-graph store at
# .pack-tracker/links-graph.json. BD-002 has `Blockers: BD-001, phase-1`
# in the fixture. The phase-1 token routes to the v10 sub-issue-parent
# arm (NOT a blocked-by edge), so only BD-001 lands in the store as a
# blocked-by edge. Without F1, the store would not exist at all on
# initial migration.
store_path="$TEST_REPO/.pack-tracker/links-graph.json"
if [[ -f "$store_path" ]]; then
    t_pass "3.5b F1: cycle-graph store created at $store_path"
    n_edges=$(jq '.edges | length' "$store_path" 2>/dev/null || echo 0)
    if [[ "$n_edges" -ge 1 ]]; then
        t_pass "3.5b F1: cycle-graph store has ≥1 blocked-by edge (BD-002 → BD-001)"
    else
        t_fail "3.5b F1: cycle-graph store has ≥1 blocked-by edge (BD-002 → BD-001)" \
            "n_edges=$n_edges"
    fi
    # BD-002 → BD-001 edge present?
    if jq -e '.edges[] | select(.source == "BD-002" and .target == "BD-001" and .kind == "blocked-by")' \
        "$store_path" >/dev/null 2>&1; then
        t_pass "3.5b F1: cycle-graph store has BD-002 blocked-by BD-001 edge"
    else
        t_fail "3.5b F1: cycle-graph store has BD-002 blocked-by BD-001 edge" \
            "edges: $(jq -c '.edges' "$store_path" 2>/dev/null)"
    fi
else
    t_fail "3.5b F1: cycle-graph store created at $store_path" \
        "missing (was forward migration's blocked-by orchestrator wired?)"
fi

# 3.6 BACKLOG.md mirror header was added in place.
first_line=$(head -n 1 "$TEST_REPO/pack-ops/BACKLOG.md")
assert_eq "3.6 BACKLOG mirror header line 1" "<!--" "$first_line"
assert_contains "3.6 BACKLOG mirror header text" \
    "$(head -n 5 "$TEST_REPO/pack-ops/BACKLOG.md" | tr '\n' ' ')" "read-only mirror"

# 3.7 tracker.toml updated with last_forward_run.
assert_contains "3.7 tracker.toml has last_forward_run" \
    "$(cat "$TEST_REPO/tracker.toml")" "last_forward_run = \""

# 3.7b forward run flips migration.forward_complete = false → true
# per V1 §3.2 D-5; the fixture starts at false (mirroring `init` output)
# so this assertion proves the production code path emits the flip.
assert_contains "3.7b tracker.toml flips forward_complete=true" \
    "$(cat "$TEST_REPO/tracker.toml")" "forward_complete = true"

# 3.7c integration: tracker_mode resolves to "tracker" after a successful
# init→forward sequence (V1 §3.2 detection). Closes Finding #1 + #10
# from PACK-REVIEW-CUMULATIVE-V11: every prior fixture hard-coded
# forward_complete = true, so no test exercised the production flip.
mode_after=$(tracker_mode "$TEST_REPO/tracker.toml")
assert_eq "3.7c tracker_mode resolves to tracker" "tracker" "$mode_after"

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
mkdir -p "$TEST_REPO2/pack-ops"
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO2/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO2/IMPLEMENTATION-PLAN.md"
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
mkdir -p "$TEST_REPO3/pack-ops"
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO3/pack-ops/BACKLOG.md"
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
mkdir -p "$TEST_REPO_PF/pack-ops"
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO_PF/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_PF/IMPLEMENTATION-PLAN.md"
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

# BD-131: a partial-CLOSE failure (creates all succeeded, closes
# failed) MUST still flip migration.forward_complete = true. The
# create surface is the strong signal for `tracker_mode()`; close
# failures are best-effort and surfaced via the partial-write typed
# error above. Treating partial closes as forward_incomplete would
# silently route downstream tooling to flat-file mode after an
# otherwise successful migration — defeating the opt-in.
assert_contains "4.3 BD-131 forward_complete=true after partial-close (creates clean)" \
    "$(cat "$TEST_REPO_PF/tracker.toml")" "forward_complete = true"

rm -rf "$FAKE_BIN_PF" "$GH_LOG_PF" "$ISSUE_COUNTER_PF" "$TEST_REPO_PF"

# 4.4 Body-marker recovery (Findings #1 + #8): fake gh that returns
# a search hit AND a matching body marker for BD-001 → BD-065 should
# treat the entry as recovered (registered in mapping, not re-created).
FAKE_BIN_REC=$(mktemp -d -t tmf-fakebin-rec.XXXXXX)
GH_LOG_REC=$(mktemp -t tmf-ghlog-rec.XXXXXX)
ISSUE_COUNTER_REC=$(mktemp -t tmf-counter-rec.XXXXXX)
# BD-132 F-7: track closed ids so the stabilization poll sees them.
CLOSED_IDS_REC=$(mktemp -t tmf-closed-rec.XXXXXX)
: > "$CLOSED_IDS_REC"
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
    "issue close")
        # BD-132 F-7: track the closed id for stabilization poll visibility.
        printf '%s\n' "$3" >> "@@CLOSED_IDS@@"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")    echo '[]' ;;
    "issue list")
        # BD-132 F-7: stabilization poll asks for state=closed,label=...
        want_closed=0
        for arg in "$@"; do
            [[ "$arg" == "closed" ]] && want_closed=1
        done
        if [[ "$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("@@CLOSED_IDS@@") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")       echo '{"labels":[], "assignees":[]}' ;;
    "repo view")        echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")      echo '{}' ;;
    "extension list")   echo "" ;;
    *)                  ;;
esac
exit 0
FAKEGH_REC
# Substitute placeholders to avoid heredoc-quoting headaches.
sed -i.bak \
    -e "s|@@GH_LOG@@|$GH_LOG_REC|g" \
    -e "s|@@COUNTER@@|$ISSUE_COUNTER_REC|g" \
    -e "s|@@CLOSED_IDS@@|$CLOSED_IDS_REC|g" \
    "$FAKE_BIN_REC/gh"
rm -f "$FAKE_BIN_REC/gh.bak"
chmod +x "$FAKE_BIN_REC/gh"

TEST_REPO_REC=$(mktemp -d -t tmf-repo-rec.XXXXXX)
mkdir -p "$TEST_REPO_REC/pack-ops"
cp "$FIXTURES/BACKLOG.md" "$TEST_REPO_REC/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_REC/IMPLEMENTATION-PLAN.md"
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

rm -rf "$FAKE_BIN_REC" "$GH_LOG_REC" "$ISSUE_COUNTER_REC" "$CLOSED_IDS_REC" "$TEST_REPO_REC"

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
mkdir -p "$TEST_REPO_MO/pack-ops"
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO_MO/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_MO/IMPLEMENTATION-PLAN.md"
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
first_line=$(head -n 1 "$TEST_REPO_MO/pack-ops/BACKLOG.md")
assert_eq "4.5 --mirror-only writes header line 1" "<!--" "$first_line"
# No mapping file or checkpoint file written.
[[ ! -f "$TEST_REPO_MO/.pack-tracker/id-map.json" ]] \
    && t_pass "4.5 --mirror-only writes no id-map.json" \
    || t_fail "4.5 --mirror-only writes no id-map.json"

rm -rf "$FAKE_BIN_MO" "$GH_LOG_MO" "$TEST_REPO_MO"

# 4.6 Checkpoint cadence integration test (PACK-REVIEW-BD065 Finding
# #6 closure). Lower TMF_CHECKPOINT_INTERVAL=2 against the 5-entry
# fixture: expect checkpoint writes after entries 2 and 4, and
# checkpoint cleared after the post-loop step 11.
FAKE_BIN_CP=$(mktemp -d -t tmf-fakebin-cp.XXXXXX)
GH_LOG_CP=$(mktemp -t tmf-ghlog-cp.XXXXXX)
ISSUE_COUNTER_CP=$(mktemp -t tmf-counter-cp.XXXXXX)
# BD-132 F-7: track closed ids so the stabilization poll sees them.
CLOSED_IDS_CP=$(mktemp -t tmf-closed-cp.XXXXXX)
: > "$CLOSED_IDS_CP"
echo "300" > "$ISSUE_COUNTER_CP"

cat > "$FAKE_BIN_CP/gh" <<FAKEGH_CP
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_CP"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_CP")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_CP"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        # BD-132 F-7: track closed id for stabilization poll.
        printf '%s\n' "\$3" >> "$CLOSED_IDS_CP"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues") echo '[]' ;;
    "issue list")
        # BD-132 F-7: state=closed poll → return tracked ids.
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_CP") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_CP
chmod +x "$FAKE_BIN_CP/gh"

TEST_REPO_CP=$(mktemp -d -t tmf-repo-cp.XXXXXX)
mkdir -p "$TEST_REPO_CP/pack-ops"
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO_CP/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_CP/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_CP/tracker.toml"

# Override the cadence and run forward. Re-source the lib because
# TMF_CHECKPOINT_INTERVAL is read at source-time when env-overridable.
export TMF_CHECKPOINT_INTERVAL=2
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

export PATH="$FAKE_BIN_CP:$PATH_SAVED"
output_cp=$(tracker_migrate_forward_run "$TEST_REPO_CP" 0 0 0 2>&1)
rc_cp=$?
export PATH="$PATH_SAVED"
unset TMF_CHECKPOINT_INTERVAL
# Re-source lib to restore default cadence for any later tests.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

assert_eq "4.6 forward with cadence=2 rc=0" "0" "$rc_cp"
# Checkpoint file is cleared at end-of-run (step 11), but mid-run
# writes were performed. The mapping file should reflect all 5
# entries + 2 phases.
mfile_cp="$TEST_REPO_CP/.pack-tracker/id-map.json"
[[ -f "$mfile_cp" ]] && t_pass "4.6 mapping file written" \
    || t_fail "4.6 mapping file written"
n_mapped_cp=$(jq 'length' "$mfile_cp")
assert_eq "4.6 mapping has 7 entries" "7" "$n_mapped_cp"
# Checkpoint should be cleared after success.
ckp_cp="$TEST_REPO_CP/.pack-tracker/forward.checkpoint.json"
[[ ! -f "$ckp_cp" ]] && t_pass "4.6 checkpoint cleared after success" \
    || t_fail "4.6 checkpoint cleared after success"

rm -rf "$FAKE_BIN_CP" "$GH_LOG_CP" "$ISSUE_COUNTER_CP" "$CLOSED_IDS_CP" "$TEST_REPO_CP"

# Cleanup of Group 3 globals.
rm -rf "$FAKE_BIN" "$GH_LOG" "$ISSUE_COUNTER_FILE" "$CLOSED_IDS_FILE" "$TEST_REPO" "$TEST_REPO2" "$TEST_REPO3"

# ─────────────────────────────────────────────────────────────────
# Group 5: BD-131 forward_complete write semantics
# ─────────────────────────────────────────────────────────────────
#
# BD-131 (D-4) — clean forward must flip
# `tracker.toml [migration].forward_complete = true` so V1 §3.2
# `tracker_mode()` resolves to "tracker". Partial-create failures
# must leave the flag at "false" so downstream tooling stays on
# flat-file until the operator re-runs init to complete the create
# surface.
#
# Group 4.3 already covers the partial-CLOSE path (creates clean,
# closes fail) — that one MUST flip to true (asserted above).
# Group 5 covers:
#   5.1 — direct writer round-trip with both "true" and "false"
#   5.2 — _tmf_verify_forward_complete read-back helper
#   5.3 — partial-CREATE failure → forward_complete stays "false"
#         (full integration: fake gh fails on the 4th `issue create`)

printf "\n=== Group 5: BD-131 forward_complete write semantics ===\n"

# 5.1 _tmf_update_tracker_toml round-trip.
TOML_RT=$(mktemp -d -t tmf-bd131-rt.XXXXXX)
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1

[backend]
name = "github"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
TOML

_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "true"
assert_contains "5.1 writer with 'true' flips forward_complete=true" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = true"
assert_contains "5.1 writer with 'true' adds last_forward_run" \
    "$(cat "$TOML_RT/tracker.toml")" "last_forward_run = \""

_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "false"
assert_contains "5.1 writer with 'false' sets forward_complete=false" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = false"

# 5.1b default arg is "true" (preserves pre-BD-131 behavior at any
# call site that omits the second arg).
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "x/y"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
TOML
_tmf_update_tracker_toml "$TOML_RT/tracker.toml"
assert_contains "5.1b writer omitted-arg defaults to 'true'" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = true"

# 5.1c writer rejects unexpected values (defensive — out-of-schema
# strings would break tracker_mode() resolution downstream).
cat > "$TOML_RT/tracker.toml" <<'TOML'
schema_version = 1
[migration]
forward_complete = false
TOML
err_5_1c=$(_tmf_update_tracker_toml "$TOML_RT/tracker.toml" "yes" 2>&1) || true
assert_contains "5.1c writer rejects unexpected value with stderr WARN" \
    "$err_5_1c" "refusing to write unexpected forward_complete value"
assert_contains "5.1c rejected write leaves forward_complete unchanged" \
    "$(cat "$TOML_RT/tracker.toml")" "forward_complete = false"

rm -rf "$TOML_RT"

# 5.2 _tmf_verify_forward_complete helper.
TOML_VF=$(mktemp -d -t tmf-bd131-vf.XXXXXX)
cat > "$TOML_VF/tracker.toml" <<'TOML'
schema_version = 1
[backend]
name = "github"
repo = "x/y"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
TOML
_tmf_verify_forward_complete "$TOML_VF/tracker.toml" "true"
assert_eq "5.2 verify match → rc=0" "0" "$?"

vf_err=$(_tmf_verify_forward_complete "$TOML_VF/tracker.toml" "false" 2>&1)
vf_rc=$?
assert_eq "5.2 verify mismatch → rc=1" "1" "$vf_rc"
assert_contains "5.2 verify mismatch emits stderr WARN" \
    "$vf_err" "read-back mismatch"

# 5.2b verify is a no-op (returns 0) when cfg is missing — it's a
# best-effort safety net, not a hard precondition.
_tmf_verify_forward_complete "/no/such/file.toml" "true"
assert_eq "5.2b verify on missing cfg → rc=0 (no-op)" "0" "$?"

rm -rf "$TOML_VF"

# 5.3 Partial-CREATE failure: fake gh fails on the 4th `issue
# create`. Forward should early-return rc=1 BEFORE step 11, so
# tracker.toml's forward_complete remains at the init-time "false".
# Per BD-131 semantics the create surface is the strong signal —
# a partial create means the mapping does not cover every entry,
# so downstream `tracker_mode()` MUST keep resolving to flat-file.
FAKE_BIN_C=$(mktemp -d -t tmf-fakebin-c.XXXXXX)
GH_LOG_C=$(mktemp -t tmf-ghlog-c.XXXXXX)
ISSUE_COUNTER_C=$(mktemp -t tmf-counter-c.XXXXXX)
echo "0" > "$ISSUE_COUNTER_C"

cat > "$FAKE_BIN_C/gh" <<FAKEGH_C
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_C"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_C")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_C"
        # Fail on the 4th create — the fixture has 5 entries, so at
        # least one entry will fail mid-loop, exercising the BD-131
        # creation_ok=0 branch via the tmf provider_create
        # early-return.
        if [[ "\$next" == "4" ]]; then
            echo "HTTP 422: validation failed" >&2
            exit 1
        fi
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")           ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")            echo '[]' ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_C
chmod +x "$FAKE_BIN_C/gh"

TEST_REPO_C=$(mktemp -d -t tmf-repo-c.XXXXXX)
mkdir -p "$TEST_REPO_C/pack-ops"
cp "$FIXTURES/BACKLOG.md"            "$TEST_REPO_C/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_C/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"          "$TEST_REPO_C/tracker.toml"

# Confirm the fixture starts at forward_complete = false (so a
# false flag at end-of-test is meaningful: it proves the writer
# did not flip on partial-create, NOT that the writer never ran).
assert_contains "5.3 fixture starts forward_complete=false" \
    "$(cat "$TEST_REPO_C/tracker.toml")" "forward_complete = false"

PATH_SAVED_C="$PATH"
export PATH="$FAKE_BIN_C:$PATH_SAVED_C"
output_c=$(tracker_migrate_forward_run "$TEST_REPO_C" 0 0 2>&1)
rc_c=$?
export PATH="$PATH_SAVED_C"

# Forward should fail with the propagated provider_create error
# (early-return at the create site — step 11 never runs).
assert_eq "5.3 partial-create run rc=1" "1" "$rc_c"

# Retro F5: confirm the orchestrator surfaces the propagated
# provider_create error rather than swallowing it. The fake gh emits
# "HTTP 422: validation failed" on the 4th create; mirror 4.3's
# output assertions so the captured stderr has at least one
# load-bearing pin.
assert_contains "5.3 partial-create run surfaces propagated provider_create error" \
    "$output_c" "validation failed"

# tracker.toml MUST still read forward_complete = false so
# tracker_mode() keeps resolving to flat-file (V1 §3.2). This is
# the BD-131 contract: partial creates MUST NOT silently route
# downstream tooling to tracker mode against an incomplete map.
assert_contains "5.3 BD-131 forward_complete stays 'false' on partial-create" \
    "$(cat "$TEST_REPO_C/tracker.toml")" "forward_complete = false"

# Mapping file SHOULD have the partial set (entries created before
# the failure) — Finding #7's per-create save invariant.
mfile_c="$TEST_REPO_C/.pack-tracker/id-map.json"
[[ -f "$mfile_c" ]] && t_pass "5.3 partial-create mapping persisted (resume seed)" \
    || t_fail "5.3 partial-create mapping persisted (resume seed)" "missing $mfile_c"

rm -rf "$FAKE_BIN_C" "$GH_LOG_C" "$ISSUE_COUNTER_C" "$TEST_REPO_C"

# 5.4 BD-131 retro F1 — resume-then-completes flips forward_complete
# to "true". The resume path is the documented recovery verb for the
# `forward_complete = false` state 5.3 introduced. This test pins down
# the orchestrator-level invariant end-to-end:
#
#   Phase 1 — partial-create run leaves the create surface incomplete:
#     - Override TMF_CHECKPOINT_INTERVAL=2 so a checkpoint is written
#       after the 2nd entry (the default 25 would never write because
#       the failure happens before idx % 25 == 0).
#     - Use a fake gh that fails on the 4th `issue create`.
#     - Assert rc=1 + forward_complete still "false" + checkpoint
#       file present (resume seed).
#
#   Phase 2 — resume run completes the surface:
#     - Re-use the same TEST_REPO so the partial mapping +
#       checkpoint carry forward.
#     - Swap to a fake gh that succeeds on every operation.
#     - Run `tracker_migrate_forward_run "$REPO" 0 1` (resume=1).
#     - Assert rc=0 (no partial-write) + forward_complete = "true"
#       on disk + last_forward_run line written + tracker_mode() now
#       resolves to "tracker".
#
# A future refactor that quietly regresses the resume path's
# interaction with `creation_ok` (e.g. resetting it to 0 inside the
# resume skip arm, or rebuilding completed_pack_ids from the mapping
# without re-driving step 11) would fail this test immediately.

FAKE_BIN_R1=$(mktemp -d -t tmf-fakebin-r1.XXXXXX)
GH_LOG_R1=$(mktemp -t tmf-ghlog-r1.XXXXXX)
ISSUE_COUNTER_R1=$(mktemp -t tmf-counter-r1.XXXXXX)
echo "0" > "$ISSUE_COUNTER_R1"

# Phase 1 fake gh: identical to 5.3's — fails on the 4th `issue
# create`. Splitting the fake into two binaries (R1 = fail-on-4th,
# R2 = always-succeed) makes the swap explicit between the partial
# run and the resume run.
cat > "$FAKE_BIN_R1/gh" <<FAKEGH_R1
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_R1"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_R1")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_R1"
        if [[ "\$next" == "4" ]]; then
            echo "HTTP 422: validation failed" >&2
            exit 1
        fi
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")           ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")            echo '[]' ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_R1
chmod +x "$FAKE_BIN_R1/gh"

TEST_REPO_R=$(mktemp -d -t tmf-repo-r.XXXXXX)
mkdir -p "$TEST_REPO_R/pack-ops"
cp "$FIXTURES/BACKLOG.md"             "$TEST_REPO_R/pack-ops/BACKLOG.md"
cp "$FIXTURES/IMPLEMENTATION-PLAN.md" "$TEST_REPO_R/IMPLEMENTATION-PLAN.md"
cp "$FIXTURES/tracker.toml"           "$TEST_REPO_R/tracker.toml"

# Override checkpoint cadence so phase 1 writes a checkpoint that
# phase 2's resume can consume. Re-source the lib because the
# constant is read at source-time.
export TMF_CHECKPOINT_INTERVAL=2
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

# ── Phase 1 — partial-create run ─────────────────────────────────
PATH_SAVED_R="$PATH"
export PATH="$FAKE_BIN_R1:$PATH_SAVED_R"
output_r1=$(tracker_migrate_forward_run "$TEST_REPO_R" 0 0 2>&1)
rc_r1=$?
export PATH="$PATH_SAVED_R"

assert_eq "5.4 phase-1 partial-create run rc=1" "1" "$rc_r1"
assert_contains "5.4 phase-1 forward_complete stays 'false'" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "forward_complete = false"
ckp_r="$TEST_REPO_R/.pack-tracker/forward.checkpoint.json"
[[ -f "$ckp_r" ]] && t_pass "5.4 phase-1 checkpoint persisted (resume seed)" \
    || t_fail "5.4 phase-1 checkpoint persisted (resume seed)" "missing $ckp_r"

# Sanity: tracker_mode() must resolve to flat-file at this point
# even though [mode].state = "tracker" (the fixture sets it). This
# is the V1 §3.2 / D-5 contract that BD-131 enforces.
mode_after_partial=$(tracker_mode "$TEST_REPO_R/tracker.toml")
assert_eq "5.4 phase-1 tracker_mode() → flat-file" "flat-file" "$mode_after_partial"

# ── Phase 2 — swap to all-success fake gh and resume ─────────────
FAKE_BIN_R2=$(mktemp -d -t tmf-fakebin-r2.XXXXXX)
GH_LOG_R2=$(mktemp -t tmf-ghlog-r2.XXXXXX)
ISSUE_COUNTER_R2=$(mktemp -t tmf-counter-r2.XXXXXX)
# BD-132 F-7: track closed ids so the stabilization poll sees them
# (the fixture has a Resolved entry, so step 8 closes will fire and
# step 8.5 will poll for state=closed).
CLOSED_IDS_R2=$(mktemp -t tmf-closed-r2.XXXXXX)
: > "$CLOSED_IDS_R2"
# Continue the gh-id sequence past where phase 1 stopped (3 entries
# created → next id is 4) so the resume's new creates do not collide
# with the partial mapping. Phase 1's 4th attempt failed; phase 2
# must satisfy entries 4 + 5 + 2 phase epics = 4 more creates.
echo "3" > "$ISSUE_COUNTER_R2"

cat > "$FAKE_BIN_R2/gh" <<FAKEGH_R2
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_R2"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_R2")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_R2"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close")
        printf '%s\n' "\$3" >> "$CLOSED_IDS_R2"
        ;;
    "issue reopen"|"issue edit"|"issue comment") ;;
    "search issues")         echo '[]' ;;
    "issue list")
        want_closed=0
        for arg in "\$@"; do
            [[ "\$arg" == "closed" ]] && want_closed=1
        done
        if [[ "\$want_closed" == "1" ]]; then
            python3 - <<PY
import json
ids = []
try:
    with open("$CLOSED_IDS_R2") as f:
        for line in f:
            line = line.strip()
            if line:
                ids.append(line)
except FileNotFoundError:
    pass
print(json.dumps([{"number": int(i)} for i in ids]))
PY
        else
            echo '[]'
        fi
        ;;
    "issue view")            echo '{"labels":[], "assignees":[]}' ;;
    "repo view")             echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")           echo '{}' ;;
    "extension list")        echo "" ;;
    *)                       ;;
esac
exit 0
FAKEGH_R2
chmod +x "$FAKE_BIN_R2/gh"

export PATH="$FAKE_BIN_R2:$PATH_SAVED_R"
output_r2=$(tracker_migrate_forward_run "$TEST_REPO_R" 0 1 2>&1)
rc_r2=$?
export PATH="$PATH_SAVED_R"

# Restore default checkpoint cadence for any later groups.
unset TMF_CHECKPOINT_INTERVAL
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"

# Resume must succeed end-to-end (no partial-write surface).
assert_eq "5.4 phase-2 resume run rc=0" "0" "$rc_r2"

# This is the load-bearing assertion: the orchestrator-level invariant
# (creation_ok=1 → step 11 writes "true") must hold across the
# resume → completes path. A future regression that flips
# creation_ok to 0 inside the resume skip arm — or rebuilds
# completed_pack_ids without driving step 11 — would fail here.
assert_contains "5.4 BD-131 phase-2 resume flips forward_complete to 'true'" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "forward_complete = true"

# last_forward_run must have been written by step 11 (the partial
# run never reached step 11, so the absence-then-presence flip is a
# clean signal that step 11 ran on resume).
assert_contains "5.4 phase-2 resume writes last_forward_run" \
    "$(cat "$TEST_REPO_R/tracker.toml")" "last_forward_run = \""

# Composition check: tracker_mode() now resolves to "tracker" — the
# user-visible recovery contract for BD-131.
mode_after_resume=$(tracker_mode "$TEST_REPO_R/tracker.toml")
assert_eq "5.4 phase-2 tracker_mode() → tracker" "tracker" "$mode_after_resume"

# Checkpoint must be cleared after the successful resume (V1 §6.2
# step 11 cleanup; PACK-REVIEW-BD065 Finding #6 + BD-132 F-4
# stabilization-conditional clear). With our all-success fake gh,
# stabilization succeeds → checkpoint cleared.
[[ ! -f "$ckp_r" ]] && t_pass "5.4 phase-2 checkpoint cleared after resume success" \
    || t_fail "5.4 phase-2 checkpoint cleared after resume success" "$ckp_r still present"

# Mapping must be complete: 5 entries + 2 phase epics = 7 ids.
mfile_r="$TEST_REPO_R/.pack-tracker/id-map.json"
n_mapped_r=$(jq 'length' "$mfile_r")
assert_eq "5.4 phase-2 mapping has 7 entries (5 BACKLOG + 2 phases)" \
    "7" "$n_mapped_r"

rm -rf "$FAKE_BIN_R1" "$GH_LOG_R1" "$ISSUE_COUNTER_R1" \
       "$FAKE_BIN_R2" "$GH_LOG_R2" "$ISSUE_COUNTER_R2" \
       "$CLOSED_IDS_R2" "$TEST_REPO_R"

# ─────────────────────────────────────────────────────────────────
# Group 6: BD-108 cross-entity link routing (review F3)
# ─────────────────────────────────────────────────────────────────
#
# BD-108 review F3 (per IMPLEMENTATION-REPORT-BD-108-FIX): the forward
# orchestrator gained two new BD-108 paths that were unit-tested in
# `test-tracker-links.sh` (orchestration layer) but not exercised
# end-to-end at the migrator level:
#
#   (a) step 6+7 case-statement routing — a BACKLOG entry with
#       `Blockers: phase-N.M` must route to `provider_link blocked-by`
#       (which routes to the first-class `addBlockedBy` GraphQL
#       mutation per BD-111), NOT to `provider_sub_issue_create` (the
#       v10 phase-N sub-issue parent path).
#   (b) new step 7b — when an IMPLEMENTATION-PLAN.md contains a
#       phase-task `Dependencies` bullet, the orchestrator parses it
#       via `tracker_phase_task_parse` and replays each dependency as
#       a `provider_link blocked-by` call.
#
# Both paths are exercised here against the same fake-gh + integration
# pattern Group 3 uses, but with a self-contained mini-fixture so the
# pre-existing entry counts (5 BD/TD + 2 phase) stay intact.

printf "\n=== Group 6: BD-108 cross-entity link routing (review F3) ===\n"

# Mini-fixture repo with one BACKLOG entry that has `Blockers:
# phase-3.2` and an IMPLEMENTATION-PLAN with a Dependencies bullet.
TEST_REPO_BD108=$(mktemp -d -t tmf-bd108.XXXXXX)
mkdir -p "$TEST_REPO_BD108/pack-ops"  # BD-175 pack-side marker
FAKE_BIN_BD108=$(mktemp -d -t tmf-fakebin-bd108.XXXXXX)
GH_LOG_BD108=$(mktemp -t tmf-ghlog-bd108.XXXXXX)
ISSUE_COUNTER_BD108=$(mktemp -t tmf-counter-bd108.XXXXXX)
echo "0" > "$ISSUE_COUNTER_BD108"

# Two BACKLOG entries:
#   - BD-501: blocked by phase-3.2 (the BD-108 routing target)
#   - BD-502: blocked by phase-3 (the v10 sub-issue-parent path; included
#     so the test can prove the case statement routes the two cases
#     differently against the SAME fake-gh log).
# Three phases (1, 2, 3) so the id-map carries phase-3 for the
# sub-issue-parent path. phase-3.2 is NOT created at v11.0 (phase-task
# creation is a future BD; documented limitation 10.2 of the BD-108
# IMPLEMENTATION-REPORT) — so the phase-3.2 Blocker reaches the case
# statement but tmf_mapping_get returns empty, surfacing the routing
# decision via the partial_failures path.
cat > "$TEST_REPO_BD108/pack-ops/BACKLOG.md" <<'BACKLOG'
# BACKLOG

**BD-501 — Phase-task blocker entry (BD-108 routing target)**
Type: TODO(version)
Status: Open
Blockers: phase-3.2
Unblocks: None
File/Symbol: scripts/foo.sh
Description: BD-108 F3 routing fixture.
Resolved: n/a

---

**BD-502 — Phase-epic blocker entry (v10 sub-issue parent path)**
Type: TODO(version)
Status: Open
Blockers: phase-3
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Counterpoint to BD-501 — proves case statement
  routes phase-N differently than phase-N.M.
Resolved: n/a

---
BACKLOG

cat > "$TEST_REPO_BD108/IMPLEMENTATION-PLAN.md" <<'PLAN'
# IMPLEMENTATION PLAN

## Phases

### Phase 1 — Foundations

Lay the foundations.

### Phase 2 — Polish

Polish for v1.

### Phase 3 — Cross-entity dependencies

Phase epic for BD-065 (V3.3 §6.4): the H3 form is what the BD-065
forward parser recognizes for phase-epic creation.

## Phase 3 — Cross-entity dependencies

The H2 form is what the BD-106 phase-task parser recognizes as the
phase context for `#### N.M — Title` task headings below.

### Tasks
#### 3.1 — Schema bootstrap
- **Problem / Goal / Success**: define the initial schema.
- **Files created/modified**: schemas/v11.json
- **Definition of done**: schema-validate PASS.
- **Dependencies**:
  - phase-3.2 (must complete migration scaffold first)
  - TD-029
PLAN

cat > "$TEST_REPO_BD108/tracker.toml" <<'TOML'
schema_version = 1

[backend]
name = "stub"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
TOML

# Reuse the same fake-gh shape as Group 3 — captures every call to
# the log file. F3-specific assertions inspect the log for the
# routing-decision fingerprints.
cat > "$FAKE_BIN_BD108/gh" <<FAKEGH_BD108
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$GH_LOG_BD108"
case "\$1 \$2" in
    "issue create")
        counter=\$(cat "$ISSUE_COUNTER_BD108")
        next=\$((counter + 1))
        echo "\$next" > "$ISSUE_COUNTER_BD108"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$next"
        ;;
    "issue close"|"issue reopen"|"issue edit"|"issue comment") ;;
    "search issues") echo '[]' ;;
    "issue list")    echo '[]' ;;
    "issue view")    echo '{"labels":[], "assignees":[]}' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    "extension list") echo "" ;;
    *)               ;;
esac
exit 0
FAKEGH_BD108
chmod +x "$FAKE_BIN_BD108/gh"

# Ensure the github backend is selected (the mini-fixture's tracker.toml
# uses the "stub" backend, but we need the gh backend so the fake gh
# captures the routing fingerprint).
export _TRACKER_PROVIDER_BACKEND_OVERRIDE="github"

PATH_SAVED_BD108="$PATH"
export PATH="$FAKE_BIN_BD108:$PATH_SAVED_BD108"
output_bd108=$(tracker_migrate_forward_run "$TEST_REPO_BD108" 0 0 2>&1)
rc_bd108=$?
export PATH="$PATH_SAVED_BD108"

# rc=1 is the expected outcome here because the v11.0 fixture
# deliberately exercises step 7b's "phase-task source not in id-map"
# branch (phase-task creation is a future BD per BD-108 §10.2),
# which surfaces as a partial-write — see assertion 6.3 below.
# A clean rc=0 would mean step 7b silently swallowed the gap, which
# is the regression F10 fixed.
assert_eq "6.1 BD-108 mini-fixture forward rc=1 (partial-write expected)" "1" "$rc_bd108"
assert_contains "6.1 partial-write surfaces ERROR: partial-write" \
    "$output_bd108" "ERROR: partial-write"

# (F3-a) The phase-3.2 Blocker on BD-501 must reach the case statement.
# Because phase-3.2 is not in the id-map (no phase-task creation at
# v11.0), tmf_mapping_get returns empty — the case-statement arm
# proceeds without invoking provider_link. The routing decision is
# observable via the partial_failures log: the phase-N.M arm does NOT
# emit a "step-6 sub_issue_create: BD-501 -> phase-3.2" entry (which
# would indicate the v10 path was taken). Instead, the new
# phase-N.M arm runs and produces no log line for the missing target
# (silent skip — distinct from sub_issue_create's failure log).
#
# We assert the absence of the v10-path failure marker for BD-501 →
# phase-3.2. If the BD-108 case-statement reorder were reverted, the
# v10 phase-N arm would catch phase-3.2 and write
# "step-6 sub_issue_create: BD-501 -> phase-3.2" to partial_failures
# (which surfaces in the run output via the typed partial-write
# error block).
if [[ "$output_bd108" != *"step-6 sub_issue_create: BD-501 -> phase-3.2"* ]]; then
    t_pass "6.2 phase-3.2 Blocker NOT routed to sub_issue_create (BD-108 F3a)"
else
    t_fail "6.2 phase-3.2 Blocker NOT routed to sub_issue_create (BD-108 F3a)" \
        "v10 phase-N arm caught phase-3.2 — case-statement order regression"
fi

# (F3-b) Step 7b runs when IMPLEMENTATION-PLAN.md has a Dependencies
# bullet. Because phase-3.1 (the task carrying the Dependencies bullet)
# is NOT in the id-map at v11.0, the source-not-in-id-map branch fires.
# The marker line in partial_failures is "step-7b phase-task source
# not in id-map: phase-3.1". This proves step 7b's parser ran and the
# replay loop attempted resolution — the BD-108 IMPLEMENTATION-REPORT
# documented this as the v11.0 limitation (10.2).
assert_contains "6.3 step 7b runs and surfaces phase-task source gap (BD-108 F3b)" \
    "$output_bd108" "step-7b phase-task source not in id-map: phase-3.1"

# (F3-cleanup) The v10 path for phase-3 (BD-502) MUST still fire
# sub_issue_create — proves the case-statement reorder did not
# regress the existing v10 routing.
n_sub_issue_calls=$(grep -c "issue edit\|sub-issue\|/sub_issues" "$GH_LOG_BD108" 2>/dev/null || true)
# The github backend uses `gh api graphql` (or REST sub-issue
# endpoint) for sub-issue create — depending on the backend version.
# Either way, BD-502's phase-3 Blocker should route to a sub-issue
# create attempt against phase-3's gh id; the fake gh's log captures
# the api graphql call. We rely on the integration log having at
# least one api-graphql or sub-issue invocation as proxy for the
# v10 path firing for BD-502 → phase-3.
n_api_graphql=$(grep -c "^api graphql" "$GH_LOG_BD108" 2>/dev/null || true)
[[ "$n_api_graphql" -ge 1 ]] && t_pass "6.4 v10 phase-N Blocker still routes via api graphql (sub-issue path intact)" \
    || t_fail "6.4 v10 phase-N Blocker still routes via api graphql (sub-issue path intact)" \
       "expected ≥1 api-graphql call for BD-502 → phase-3 sub-issue; got $n_api_graphql"

unset _TRACKER_PROVIDER_BACKEND_OVERRIDE
rm -rf "$FAKE_BIN_BD108" "$GH_LOG_BD108" "$ISSUE_COUNTER_BD108" "$TEST_REPO_BD108"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
