#!/usr/bin/env bash
# scripts/tests/tracker-migrate-roundtrip-test.sh — V1 §6.7 round-trip
# safety + V1 §6.6.1 multi-template-version readiness (BD-068).
#
# Round-trip property under test:
#   forward → reverse → forward should be a no-op or near-no-op.
#
# Specifically, V1 §6.7 guarantees:
#   - Zero diff (whitespace-tolerant) on v10 grammar after a F→R cycle
#     against the fixture's original BACKLOG.md.
#   - Byte-equivalent on tracker side after a F→R→F cycle (the
#     create-call sequence after the second forward matches the
#     create-call sequence after the first forward, modulo timestamps).
#
# Multi-template-version readiness (V1 §6.6.1):
#   - The fixture tree under fixtures/roundtrip/ contains one
#     directory per shipped template-version (bd-v11.0 today;
#     bd-v11.1 + bd-v11.2 are stubs awaiting future minors).
#   - The test iterates over every bd-v11.x/ directory; ones with
#     a BACKLOG.md fixture are exercised, ones with only a README
#     are skipped (with a logged note).
#
# Implementation: a stateful fake gh maintains a JSON tracker-state
# file across invocations. Forward records into state; reverse reads
# from state. The state file is the offline equivalent of a real
# tracker — sufficient for round-trip property testing.
#
# Usage: bash scripts/tests/tracker-migrate-roundtrip-test.sh

set -u

# BD-214 deferral clamp: tracker mode is deferred indefinitely; flat-file is
# the sole supported mode. This TEST-ONLY seam keeps the dormant tracker
# code exercised under the clamp (never set it in a live run).
export PACK_TRACKER_DEFERRAL_OVERRIDE=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES_ROOT="$REPO_ROOT/scripts/tests/fixtures/roundtrip"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }

# BD-205 (OI-3 / D9): shared exact-whole-line matcher for count assertions.
# Substring assert_contains is prefix-vulnerable ("closed:     1" matches
# "closed:     12"); assert_contains_line requires a whole-line match so a
# wrong count FAILS. Dispatches to this file's t_pass/t_fail reporters.
# shellcheck source=scripts/tests/lib/assert-line-eq.sh
source "$REPO_ROOT/scripts/tests/lib/assert-line-eq.sh"

# BD-204 C-8 SHOULD-1: the bd-v11.0 fixture now carries a closed-status
# entry (BD-004, Status: Cancelled), so every forward run executes the
# step-8 close loop + the BD-132 close-stabilization poll. Zero the
# poll's sleep (documented test seam in tracker-migrate-forward.sh) to
# keep runs fast; set before the libs are sourced so the lib's
# source-time default-assignment (${TMF_STABILIZE_SLEEP_SECS:-2}) keeps
# the override — the variable stays mutable after sourcing (the poll
# reads it at call time), so this placement is convention, not a hard
# requirement.
TMF_STABILIZE_SLEEP_SECS=0

# Source the libs so we can call orchestrators directly.
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/_lib.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/decompose.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

PATH_SAVED="$PATH"

# ─────────────────────────────────────────────────────────────────
# Stateful fake gh
# ─────────────────────────────────────────────────────────────────

# Build a fake gh script that maintains state across invocations.
# State file format:
#   {
#     "next_id": 100,
#     "issues": {
#       "<id>": { "number": <id>, "title": "...", "body": "...",
#                 "state": "open"|"closed", "labels": [...], ... }
#     },
#     "create_log": [ "<title> | <labels>" ... ]   (sequence trace)
#   }
_build_stateful_fake_gh() {
    local bin_dir="$1"
    local state_file="$2"
    # Use a quoted heredoc for the script body (no shell expansion);
    # substitute STATE_FILE_PATH via sed afterward to avoid escape
    # hell. URL format matches the production sed regex
    # `s|.*/issues/([0-9]+).*|\1|`.
    cat > "$bin_dir/gh" <<'FAKEGH'
#!/usr/bin/env bash
# Stateful fake gh — round-trip test infra (BD-068).
STATE="@@STATE@@"

# Ensure state file exists.
if [[ ! -f "$STATE" ]]; then
    printf '%s\n' '{"next_id": 100, "issues": {}, "create_log": []}' > "$STATE"
fi

case "$1 $2" in
    "issue create")
        title=""; body=""; labels="[]"; body_file=""
        shift 2
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --title)      title="$2"; shift 2 ;;
                --body-file)  body_file="$2"; shift 2 ;;
                --label)      labels=$(jq -nc --arg s "$2" '$s | split(",")'); shift 2 ;;
                --assignee|--milestone) shift 2 ;;
                *) shift ;;
            esac
        done
        [[ -n "$body_file" && -f "$body_file" ]] && body=$(cat "$body_file")

        st=$(cat "$STATE")
        new_id=$(printf '%s' "$st" | jq -r .next_id)
        new_st=$(printf '%s' "$st" | jq -c \
            --arg id "$new_id" \
            --arg title "$title" \
            --arg body "$body" \
            --argjson labels "$labels" \
            '.next_id = (.next_id | tonumber + 1)
             | .issues[$id] = {
                 number: ($id | tonumber),
                 title: $title,
                 body: $body,
                 state: "OPEN",
                 stateReason: null,
                 labels: $labels | map({name: .}),
                 assignees: [],
                 milestone: null,
                 createdAt: null,
                 updatedAt: null,
                 closedAt: null,
                 url: ("https://github.com/fixture-org/roundtrip-v11.0/issues/" + $id)
               }
             | .create_log += [($title + " | " + ($labels | join(",")))]')
        printf '%s' "$new_st" > "$STATE"
        # URL must match the production sed regex .*/issues/([0-9]+).*
        echo "https://github.com/fixture-org/roundtrip-v11.0/issues/$new_id"
        ;;

    "issue view")
        id="$3"
        shift 3
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --json) shift 2 ;;
                --jq)   shift 2 ;;
                *)      shift ;;
            esac
        done
        cat "$STATE" | jq -c --arg id "$id" '.issues[$id]'
        ;;

    "issue close")
        id="$3"
        reason="completed"
        shift 3
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --reason|-r) reason="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — "not planned" takes a
        # SPACE. Nonzero exit otherwise, exactly like the real CLI, so
        # the interface token not_planned can never silently mock-pass.
        # BD-204 C-8 defect 1 (stateReason casing): the live gh
        # READ-BACK carries GraphQL-enum casing, not the CLI input form
        # (live evidence 2026-06-11: `gh issue view 21 ... --json
        # number,state,stateReason` → {"state":"CLOSED","stateReason":
        # "NOT_PLANNED"}). Store the read-back shape so the production
        # normalizer (`_gh_normalize_issue` lowercasing) is GENUINELY
        # exercised — a mock storing/serving a lowercase reason would
        # mask a normalization regression.
        case "$reason" in
            completed) readback_reason="COMPLETED" ;;
            "not planned") readback_reason="NOT_PLANNED" ;;
            duplicate) readback_reason="DUPLICATE" ;;
            *)
                echo "fake-gh: invalid --reason '$reason' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                exit 1
                ;;
        esac
        st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" --arg reason "$readback_reason" \
            '.issues[$id].state = "CLOSED" | .issues[$id].stateReason = $reason')
        printf '%s' "$new_st" > "$STATE"
        ;;

    "issue reopen")
        id="$3"
        st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" \
            '.issues[$id].state = "OPEN" | .issues[$id].stateReason = null')
        printf '%s' "$new_st" > "$STATE"
        ;;

    "issue comment")
        ;;

    "issue edit")
        # BD-204 run-3 (Defect C mock leg): apply body + label edits to
        # state so the REAL provider_update path (gh issue edit
        # --body-file/--add-label/--remove-label) is exercisable in the
        # post-CRUD round-trip (Group 6). Previously a no-op.
        id="$3"
        ed_body_file=""; ed_add_labels=""; ed_remove_labels=""
        shift 3
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --body-file)    ed_body_file="$2"; shift 2 ;;
                --add-label)    ed_add_labels="$2"; shift 2 ;;
                --remove-label) ed_remove_labels="$2"; shift 2 ;;
                --title|--add-assignee|--remove-assignee|--milestone) shift 2 ;;
                *) shift ;;
            esac
        done
        st=$(cat "$STATE")
        new_st="$st"
        if [[ -n "$ed_body_file" && -f "$ed_body_file" ]]; then
            ed_body=$(cat "$ed_body_file")
            new_st=$(printf '%s' "$new_st" | jq -c --arg id "$id" --arg b "$ed_body" \
                '.issues[$id].body = $b')
        fi
        if [[ -n "$ed_add_labels" ]]; then
            new_st=$(printf '%s' "$new_st" | jq -c --arg id "$id" --arg l "$ed_add_labels" \
                '.issues[$id].labels = ((.issues[$id].labels + ($l | split(",") | map({name: .}))) | unique_by(.name))')
        fi
        if [[ -n "$ed_remove_labels" ]]; then
            new_st=$(printf '%s' "$new_st" | jq -c --arg id "$id" --arg l "$ed_remove_labels" \
                '.issues[$id].labels = (.issues[$id].labels | map(select(.name as $n | (($l | split(",")) | index($n)) | not)))')
        fi
        printf '%s' "$new_st" > "$STATE"
        ;;

    "search issues")
        echo "[]"
        ;;

    "issue list")
        # BD-204 C-8 SHOULD-1: serve from state (was a canned []). The
        # fixture now carries a closed-status entry (BD-004 Cancelled),
        # so forward's BD-132 close-stabilization poll (`issue list
        # --label X --state closed`) must see the close reflected; a
        # canned [] would poll to the attempt ceiling and fail the run
        # as a partial-write. Filters honored: --label (single value),
        # --state (open|closed|all; state is stored in the read-back
        # casing OPEN/CLOSED). Output: a JSON array, as the real
        # `gh issue list --json` returns.
        li_label=""; li_state="open"
        shift 2
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --label) li_label="$2"; shift 2 ;;
                --state) li_state="$2"; shift 2 ;;
                --json|--limit|--milestone|--search) shift 2 ;;
                *) shift ;;
            esac
        done
        jq -c --arg label "$li_label" --arg state "$li_state" \
            '[.issues[]
              | select(($state == "all") or ((.state // "") == ($state | ascii_upcase)))
              | select(($label == "") or (any((.labels // [])[]; .name == $label)))]' \
            "$STATE"
        ;;

    "repo view")
        # Honor --jq .nameWithOwner if requested (real gh would
        # apply the filter server-side; we approximate). BD-111
        # retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
        # pass); resolution description updated for BD-204: production
        # resolves the OWNER/REPO slug via the `_gh_owner_repo` helper
        # in scripts/lib/tracker-provider-gh.sh (callers:
        # tracker_provider_gh_link / tracker_provider_gh_unlink /
        # tracker_provider_gh_sub_issue_create /
        # tracker_provider_gh_sub_issue_list /
        # tracker_provider_gh_sub_issue_unlink), which PREFERS
        # ${GH_REPO} (stripping an optional HOST/ prefix, with a
        # post-strip shape guard) and
        # runs `_gh_run gh repo view --json nameWithOwner --jq
        # .nameWithOwner` ONLY as the GH_REPO-unset fallback;
        # _tmr_fetch_first_class_blocked_by in
        # scripts/lib/tracker-migrate-reverse.sh mirrors the same
        # GH_REPO-preferred order inline. This arm therefore serves
        # the GH_REPO-unset fallback path. Without the --jq filter
        # the JSON object string would propagate into URL paths.
        rv_jq=""
        for ((i=1; i<=$#; i++)); do
            if [[ "${!i}" == "--jq" ]]; then
                j=$((i+1))
                rv_jq="${!j}"
                break
            fi
        done
        if [[ "$rv_jq" == ".nameWithOwner" ]]; then
            echo "fixture-org/roundtrip-v11.0"
        else
            echo '{"nameWithOwner":"fixture-org/roundtrip-v11.0"}'
        fi
        ;;

    "api graphql")
        # BD-111 retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
        # pass 2026-05-15): the round-trip fake-gh now handles the
        # `addBlockedBy` mutation (forward write side) and the
        # `blockedBy` query (reverse read side) so post-BD-111
        # forward writes round-trip through reverse correctly.
        #
        # Arg parse: walk argv looking for -f query=... and -F key=val.
        gquery=""
        f_issue_id=""
        f_blocked_by=""
        f_owner=""
        f_repo=""
        f_number=""
        shift 2
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -f) case "$2" in
                        query=*) gquery="${2#query=}" ;;
                    esac
                    shift 2 ;;
                -F) case "$2" in
                        issueId=*)          f_issue_id="${2#issueId=}" ;;
                        blockingIssueId=*)  f_blocked_by="${2#blockingIssueId=}" ;;
                        owner=*)            f_owner="${2#owner=}" ;;
                        repo=*)             f_repo="${2#repo=}" ;;
                        number=*)           f_number="${2#number=}" ;;
                    esac
                    shift 2 ;;
                --jq) shift 2 ;;
                *)    shift   ;;
            esac
        done
        # Recognize addBlockedBy mutation → record edge.
        if [[ "$gquery" == *"addBlockedBy"* ]]; then
            # node-ids are NODE_<N> (synthesized below in api /repos/...).
            src_n="${f_issue_id#NODE_}"
            tgt_n="${f_blocked_by#NODE_}"
            # BD-204 run-3 (Defect B mock leg): DUPLICATE-EDGE SENTINEL.
            # Live GH's addBlockedBy is NOT idempotent — re-attempting an
            # EXISTING edge fails (rehearsal run-3 evidence: every forward
            # re-run failed `step-7 link blocked-by`). Mirror that here so
            # the Group-6 re-run leg has TEETH: production must
            # read-before-write (Issue.blockedBy query) and SKIP the
            # mutation; a regression that re-attempts it trips this exit 1.
            # NOTE: the error text below is a STAND-IN (no live duplicate-
            # edge error text was captured); production code must NEVER
            # classify on it.
            if [[ -n "$src_n" && -n "$tgt_n" ]]; then
                dup=$(jq -r --arg src "$src_n" --arg tgt "$tgt_n" \
                    '[.first_class_edges // [] | .[] | select(.issue == ($src | tonumber) and .blocked_by == ($tgt | tonumber))] | length' \
                    "$STATE")
                if [[ "$dup" -gt 0 ]]; then
                    echo "GraphQL: duplicate blocked-by edge (fake-gh sentinel; addBlockedBy is not idempotent on live GH)" >&2
                    exit 1
                fi
                st=$(cat "$STATE")
                new_st=$(printf '%s' "$st" | jq -c \
                    --arg src "$src_n" --arg tgt "$tgt_n" \
                    '.first_class_edges = ((.first_class_edges // []) + [{issue: ($src | tonumber), blocked_by: ($tgt | tonumber)}])')
                printf '%s' "$new_st" > "$STATE"
            fi
            echo '{"data":{"addBlockedBy":{"issue":{"number":0}}}}'
        elif [[ "$gquery" == *"removeBlockedBy"* ]]; then
            src_n="${f_issue_id#NODE_}"
            tgt_n="${f_blocked_by#NODE_}"
            if [[ -n "$src_n" && -n "$tgt_n" ]]; then
                st=$(cat "$STATE")
                new_st=$(printf '%s' "$st" | jq -c \
                    --arg src "$src_n" --arg tgt "$tgt_n" \
                    '.first_class_edges = ((.first_class_edges // []) | map(select(.issue != ($src | tonumber) or .blocked_by != ($tgt | tonumber))))')
                printf '%s' "$new_st" > "$STATE"
            fi
            echo '{"data":{"removeBlockedBy":{"issue":{"number":0}}}}'
        elif [[ "$gquery" == *"blockedBy(first"* ]]; then
            # Reverse read: query embeds owner/name/number directly via
            # shell interpolation (per _tmr_fetch_first_class_blocked_by).
            # Extract the issue number from the query string.
            issue_n=$(printf '%s' "$gquery" | sed -nE 's/.*issue\(number:[[:space:]]*([0-9]+)\).*/\1/p')
            if [[ -n "$issue_n" ]]; then
                edges=$(jq -c --arg n "$issue_n" \
                    '[.first_class_edges // [] | .[] | select(.issue == ($n | tonumber)) | {number: .blocked_by}]' \
                    "$STATE")
            else
                edges='[]'
            fi
            jq -nc --argjson nodes "$edges" \
                '{data: {repository: {issue: {blockedBy: {nodes: $nodes}}}}}'
        else
            echo "{}"
        fi
        ;;

    "api /"*)
        # Recognize node-id resolution: gh api /repos/<o>/<r>/issues/N
        # --jq .node_id. The BD-111 link writer + reverse decoder both
        # need this. Synthesize NODE_<N> as the node-id so the
        # downstream addBlockedBy mutation can recover the issue number.
        # (The case pattern matches `$1 $2` with $1=api and $2 starts
        # with `/`. `api graphql` is matched by an earlier branch.)
        path="$2"
        if [[ "$path" == /repos/*/issues/* ]]; then
            # `sed -n ... /p` is required: -n suppresses default
            # output; the trailing /p prints the substitution result
            # only when the match succeeds. Without /p the s|...|...|
            # produces no output.
            n=$(printf '%s' "$path" | sed -nE 's|.*/issues/([0-9]+).*|\1|p')
            if [[ -n "$n" ]]; then
                # Real `gh ... --jq .node_id` returns the bare string
                # (jq -r style). Mirror that to keep _gh_run callers
                # happy.
                printf 'NODE_%s' "$n"
            fi
        fi
        ;;

    "extension list")
        echo ""
        ;;

    *)
        ;;
esac
exit 0
FAKEGH
    sed -i.bak "s|@@STATE@@|$state_file|g" "$bin_dir/gh"
    rm -f "$bin_dir/gh.bak"
    chmod +x "$bin_dir/gh"
}

# Helper: extract the create_log from the state file as a sorted
# canonical string for byte-equivalent comparison.
_state_create_signature() {
    local state_file="$1"
    jq -c '.create_log | sort' "$state_file"
}

# Helper: count entries in a state file.
_state_issue_count() {
    local state_file="$1"
    jq '.issues | length' "$state_file"
}

# Helper: clone a fixture into a fresh test repo. Adds .pack-tracker/
# directory.
_setup_test_repo() {
    local fixture_dir="$1"
    local test_repo
    test_repo=$(mktemp -d "${TMPDIR:-/tmp}/rtrip.XXXXXX")
    # BD-204 C-5 (C2a): the pack-surface forward read-side now enumerates
    # the per-entry TREE under `/backlog/` (the no-monolith SSOT), pairing
    # with C-4's tree EMIT on reverse for a monolith-free round-trip. Seed
    # the BD-only tree from the fixture monolith via per_entry_decompose
    # (the `pack-backlog` regex filters to BD-* — TD-* is the project
    # namespace, never in the pack backlog). The `pack-ops/` directory
    # marker is still created so tracker_config_auto_surface returns
    # "pack"; under the no-monolith model NO `pack-ops/BACKLOG.md` is
    # written (fail-loud — there is no monolith to read).
    mkdir -p "$test_repo/pack-ops"
    mkdir -p "$test_repo/backlog"
    # Filter the mixed fixture monolith to its BD-* entries FIRST, then
    # decompose — decompose appends non-matching (TD-*) blocks to the
    # preceding BD file, so a clean BD-only tree requires the pre-filter.
    local _bd_only
    _bd_only=$(mktemp "${TMPDIR:-/tmp}/rtrip-bdonly.XXXXXX")
    python3 - "$fixture_dir/BACKLOG.md" > "$_bd_only" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
blocks = re.split(r'\n---\n', text)
out = [b.strip() for b in blocks if re.search(r'^\*\*BD-\d{3}', b.strip(), re.M)]
sys.stdout.write('\n\n---\n\n'.join(out) + '\n\n---\n')
PY
    per_entry_decompose "pack-backlog" "$_bd_only" "$test_repo/backlog" >/dev/null
    rm -f "$_bd_only"
    cp "$fixture_dir/IMPLEMENTATION-PLAN.md" "$test_repo/IMPLEMENTATION-PLAN.md"
    cp "$fixture_dir/tracker.toml"           "$test_repo/tracker.toml"
    mkdir -p "$test_repo/.pack-tracker"
    echo "$test_repo"
}

# ─────────────────────────────────────────────────────────────────
# Group 1: forward records expected tracker state
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: forward → tracker state ===\n"

FIXTURE_V11_0="$FIXTURES_ROOT/bd-v11.0"
[[ -f "$FIXTURE_V11_0/BACKLOG.md" ]] || { echo "FATAL: bd-v11.0 fixture missing"; exit 2; }

REPO1=$(_setup_test_repo "$FIXTURE_V11_0")
FAKE1=$(mktemp -d "${TMPDIR:-/tmp}/rtrip-fake1.XXXXXX")
STATE1="$REPO1/.pack-tracker/fake-tracker-state.json"
_build_stateful_fake_gh "$FAKE1" "$STATE1"

export PATH="$FAKE1:$PATH_SAVED"
output1=$(tracker_migrate_forward_run "$REPO1" 0 0 0 2>&1)
rc1=$?
export PATH="$PATH_SAVED"

assert_eq       "1.1 forward run rc=0"           "0" "$rc1"
# BD-204 C-5 (C2a): the pack-surface forward read-side now enumerates the
# BD-only per-entry TREE (the no-monolith SSOT). The bd-v11.0 fixture's
# BD-* set is {BD-001, BD-002, BD-003, BD-004} (TD-010/TD-040 are the
# project namespace, never in the pack backlog), so the pack forward parses
# 4 entries. BD-003 (BD-204 §3.3) carries top-level drop-set fields
# (Target/Scope/Problem/Position/References/Out of scope) + a multi-paragraph
# prose block + NO Blockers — the field-faithful-carrier stress case.
# BD-004 (BD-204 C-8 SHOULD-1) is the closed-status carrier (Status:
# Cancelled): forward CLOSES it through the production close path
# (interface token not_planned → gh CLI "not planned"); the fake gh stores
# the live read-back shape (CLOSED/NOT_PLANNED); 1.2 + 2.2e pin the
# close→read-back→normalize→decode chain end-to-end.
# Entry count: 4 BD + 2 phase epics = 6 issues in the recorded state.
# (TD decode/reconstruct survival is covered at the decode-unit layer in
# tracker-migrate-reverse-test.sh Group 1/2 + the 2.2c decode test below,
# which no longer depends on a TD forward-creation that the BD-only pack
# round-trip does not perform.)
assert_contains "1.1 forward run reports 4 entries" "$output1" "parsed 4 BACKLOG entries"
assert_contains "1.1 forward run reports 2 phases"  "$output1" "2 phase(s)"

# State should have 4 BD + 2 phase epics = 6 issues.
assert_eq "1.1 tracker state has 6 issues" "6" "$(_state_issue_count "$STATE1")"

# Mapping file populated.
mapping_file="$REPO1/.pack-tracker/id-map.json"
[[ -f "$mapping_file" ]] && t_pass "1.1 mapping file written" || t_fail "1.1 mapping file written"
assert_eq "1.1 mapping has 6 entries" "6" "$(jq 'length' "$mapping_file")"

# 1.2 BD-204 C-8 SHOULD-1 — the fake-gh `issue close` handler is now
# exercised by a CI-run leg: forward's step-8 close loop closed BD-004
# (Status: Cancelled → reason not_planned → gh CLI "not planned"); the
# handler validates the real CLI vocabulary (a regressed token would
# exit 1 and fail the rc=0 assert above as a partial-write) and stores
# the LIVE READ-BACK shape. Assert the stored shape carries the
# GraphQL-enum casing — uppercase NOT_PLANNED is exactly what the
# production normalize→decode chain must handle (pinned in 2.2e).
assert_contains_line "1.2 forward closed 1 entry (BD-004 Cancelled)" "$output1" "closed:     1"
assert_contains "1.2 close-stabilization ran and completed"     "$output1" "close-stabilization OK"
bd004_stored=$(jq -c '[.issues[] | select((.title // "") | startswith("BD-004:"))] | .[0] // {}' "$STATE1")
assert_eq "1.2 BD-004 stored state is read-back CLOSED" \
    "CLOSED" "$(printf '%s' "$bd004_stored" | jq -r '.state // ""')"
assert_eq "1.2 BD-004 stored stateReason is read-back enum NOT_PLANNED" \
    "NOT_PLANNED" "$(printf '%s' "$bd004_stored" | jq -r '.stateReason // ""')"

# ─────────────────────────────────────────────────────────────────
# Group 2: reverse against recorded state reconstructs flat files
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: reverse against recorded state ===\n"

# Capture the original BACKLOG body (without mirror header — fixture
# starts plain) for the diff comparison after reverse.
ORIG_BACKLOG=$(cat "$FIXTURE_V11_0/BACKLOG.md")

# Run reverse against the same repo (same state file is in place via
# the fake-gh's STATE env reference, baked into the script).
export PATH="$FAKE1:$PATH_SAVED"
output2=$(tracker_migrate_reverse_run "$REPO1" 0 0 0 2>&1)
rc2=$?
export PATH="$PATH_SAVED"

assert_eq       "2.1 reverse rc=0" "0" "$rc2"
# BD-204 C-5: the BD-only pack round-trip reconstructs 4 BD entries.
assert_contains "2.1 reverse reports 4 entries"     "$output2" "reconstructed 4 BACKLOG entries"
assert_contains "2.1 reverse reports 2 phase epics" "$output2" "2 phase epic"

# Reverse output should reconstruct each entry. The reconstructed
# BACKLOG must contain every original pack-id and title (whitespace
# differences are tolerable per V1 §6.7 "near-no-op").
# BD-204 C-4: the pack reverse now emits the per-entry TREE (no monolith).
# BD-204 C-4 LOW-1 (PACK-REVIEW-BD-204-C4): the pack tree emit is filtered
# to the `pack-backlog` entry regex (`^BD-[0-9]+\.md$`, canonical per
# BD-211 — simplified from the former `^BD-[0-9]+[a-z]*\.md$`) — the SAME
# single source the backup set + `_toc.md` regen use — so the emit set ==
# the backup set == the `_toc.md` set by construction. On this MIXED fixture
# (BD-001/BD-002 + TD-010/TD-040) only the `BD-*` ids are written to the pack
# tree; the `TD-*` ids are not pack-backlog entries and are skipped on disk.
# Entry SURVIVAL through forward → state → reverse (incl. TD-010/TD-040) is
# proven by the reconstruction-count assertion above ("reconstructed 4
# BACKLOG entries") and the TD-040 Blockers round-trip is verified at the
# reconstruction layer in 2.2c below.
RECON_BACKLOG=$(cat "$REPO1"/backlog/BD-*.md 2>/dev/null)
for needle in "BD-001" "BD-002" \
              "Add foo to bar" "Refactor bar after foo lands" \
              "scripts/foo.sh" "scripts/bar.sh"; do
    assert_contains "2.2 reverse output preserves '$needle'" "$RECON_BACKLOG" "$needle"
done
# LOW-1 negative assertions: non-`BD-*` reconstructed ids are NOT emitted to
# the pack tree (the emit set is provably the BD-only `pack-backlog` set).
for td in "TD-010" "TD-040"; do
    [[ ! -f "$REPO1/backlog/$td.md" ]] \
        && t_pass "2.2 $td NOT emitted to pack tree (emit==backup==toc set)" \
        || t_fail "2.2 $td NOT emitted to pack tree (emit==backup==toc set)"
done

# Status preserved: BD-001 Open, BD-002 Unblocked, TD-010 Open.
for line in "Status: Open" "Status: Unblocked"; do
    assert_contains "2.2 status line preserved: $line" "$RECON_BACKLOG" "$line"
done

# 2.2d BD-204 §3.3 — the field-faithful carrier round-trips BD-003's
# top-level drop-set fields + multi-paragraph prose BYTE-FOR-BYTE. The
# reconstructed BD-003.md (lines 2..EOF, back-pointer stripped) must equal
# the source fixture entry's lines 2..EOF exactly. This leg has TEETH: the
# pre-fix emit dropped Target/Scope/Problem/Position/References/Out-of-scope
# and re-projected a lossy fixed-order body (it would diff non-empty here).
src_bd003=$(python3 - "$FIXTURE_V11_0/BACKLOG.md" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for block in re.split(r'\n---\n', text):
    b = block.strip('\n')
    if b.startswith('**BD-003 '):
        sys.stdout.write(b + "\n")
        break
PY
)
if [[ -f "$REPO1/backlog/BD-003.md" ]]; then
    recon_bd003=$(sed -n '2,$p' "$REPO1/backlog/BD-003.md")
    if [[ "$recon_bd003" == "$src_bd003" ]]; then
        t_pass "2.2d BD-003 drop-set + prose round-trips BYTE-FOR-BYTE (field-faithful carrier)"
    else
        t_fail "2.2d BD-003 round-trips BYTE-FOR-BYTE" "$(diff <(printf '%s\n' "$src_bd003") <(printf '%s\n' "$recon_bd003") | head -12)"
    fi
    # Drop-set fields each present verbatim (defense-in-depth on the byte leg).
    for f in "Target: v11.0" "Scope: Exercise the field-faithful" "Problem: The pre-fix" "Position: after BD-002" "References: BD-204" "Out of scope: anything BD-207"; do
        assert_contains "2.2d BD-003 carries drop-set field '$f'" "$recon_bd003" "$f"
    done
    # No-Blockers entry: NO injected Blockers/Unblocks/Resolved lines.
    assert_not_contains "2.2d BD-003 no injected 'Blockers: None'" "$recon_bd003" "Blockers: None"
    assert_not_contains "2.2d BD-003 no injected 'Resolved: n/a'"  "$recon_bd003" "Resolved: n/a"
else
    t_fail "2.2d BD-003 reconstructed to pack tree" "BD-003.md missing"
fi

# 2.2e BD-204 C-8 SHOULD-1 — closed-status (Cancelled) e2e decode. The
# forward close path stored the live read-back shape (asserted in 1.2);
# fetch BD-004 through the production provider boundary
# (`tracker_provider_gh_get` → `_gh_normalize_issue` lowercasing) and
# decode through the public per-issue decoder the reverse orchestrator
# calls. The uppercase NOT_PLANNED must normalize to not_planned and
# decode to Cancelled — pre-C-8 this chain yielded Resolved (the
# lossy class this leg pins against regression).
map_rt=$(tmf_mapping_load "$mapping_file")
bd004_gh_id=$(tmf_mapping_get "$map_rt" "BD-004")
[[ -n "$bd004_gh_id" ]] \
    && t_pass "2.2e BD-004 present in id-map" \
    || t_fail "2.2e BD-004 present in id-map"
export PATH="$FAKE1:$PATH_SAVED"
BD004_ISSUE=$(tracker_provider_gh_get "$bd004_gh_id" 2>/dev/null)
BD004_ENTRY=$(tracker_migrate_reverse_reconstruct "$BD004_ISSUE" "$map_rt" 2>/dev/null)
export PATH="$PATH_SAVED"
assert_eq "2.2e BD-004 read-back normalizes to state=closed" \
    "closed" "$(printf '%s' "$BD004_ISSUE" | jq -r '.state // ""')"
assert_eq "2.2e BD-004 read-back normalizes to state_reason=not_planned" \
    "not_planned" "$(printf '%s' "$BD004_ISSUE" | jq -r '.state_reason // ""')"
assert_eq "2.2e BD-004 decodes to Cancelled (normalize→decode, BD-204 C-8)" \
    "Cancelled" "$(printf '%s' "$BD004_ENTRY" | jq -r '.status // ""')"
# Orchestrator-path survival: the reverse run (2.1) reconstructed the
# closed entry to the tree with its blob bytes intact.
grep -q '^Status: Cancelled$' "$REPO1/backlog/BD-004.md" 2>/dev/null \
    && t_pass "2.2e BD-004 reconstructed to tree with Status: Cancelled" \
    || t_fail "2.2e BD-004 reconstructed to tree with Status: Cancelled"

# Blockers — BD-111 closes the round-trip gap. With the BD-111 link
# swap (forward writes addBlockedBy GraphQL edge) plus the BD-111
# retrofit per PACK-REVIEW-BD-111 F1 (reverse reads blockedBy
# GraphQL edges in addition to body comment markers), the Blockers
# field round-trips through forward → state → reverse. The stateful
# fake-gh now records first_class_edges in state on addBlockedBy and
# serves them on blockedBy; the reverse decoder folds them
# into the Blockers list per scripts/lib/tracker-migrate-reverse.sh
# `_tmr_fetch_first_class_blocked_by` + `_tmr_decode_blockers`.
bd002_block_line=$(printf '%s' "$RECON_BACKLOG" | grep -A 3 "BD-002" | grep "Blockers:")
if [[ "$bd002_block_line" == *"BD-001"* ]]; then
    t_pass "2.2 BD-002 Blockers: BD-001 preserved (BD-111 round-trip)"
else
    t_fail "2.2 BD-002 Blockers: BD-001 should round-trip post-BD-111" "got: $bd002_block_line"
fi

# 2.2c BD-108 F5 — TD-040 Blockers `TD-010` reconstruct + first-class-edge
# round-trip coverage, at the DECODE layer.
#
# BD-204 C-5 (C2a): the pack-surface forward read-side is now BD-only (the
# pack backlog has no TD entries — TD is the project namespace), so the
# pack round-trip never FORWARD-creates a TD issue. The TD reconstruct +
# resolvable-Blockers round-trip property is therefore exercised here by
# INJECTING a TD-040 issue (+ its TD-010 upstream + the first-class
# blocked-by edge) directly into the fake-tracker STATE, then running the
# SAME public per-issue decoder the reverse orchestrator calls
# (`tracker_migrate_reverse_reconstruct`). This preserves the EXACT decode
# property (pack-id reconstruct + first-class Blockers fold via
# `_tmr_fetch_first_class_blocked_by`) without depending on a TD
# forward-creation the BD-only pack path does not perform. (The pure
# decode-unit coverage also lives in tracker-migrate-reverse-test.sh
# Group 1/2.)
TD010_NUM=991
TD040_NUM=992
# Inject TD-010 (the resolvable upstream) + TD-040 (with its body marker
# + status:open label) + the first-class blocked-by edge TD-040 → TD-010.
injected=$(jq -c \
    --arg t10 "$TD010_NUM" --arg t40 "$TD040_NUM" \
    '.issues[$t10] = {
        number: ($t10|tonumber), title: "TD-010: Document quux",
        body: "<!-- pack-id: TD-010 -->\n<!-- template_version: td-v11.0 -->",
        state: "open", stateReason: null,
        labels: [{name:"td-entry"},{name:"status:open"}],
        assignees: [], milestone: null, createdAt: null, updatedAt: null,
        closedAt: null,
        url: ("https://github.com/fixture-org/roundtrip-v11.0/issues/" + $t10)
     }
     | .issues[$t40] = {
        number: ($t40|tonumber), title: "TD-040: Cross-phase TD",
        body: "<!-- pack-id: TD-040 -->\n<!-- template_version: td-v11.0 -->",
        state: "open", stateReason: null,
        labels: [{name:"td-entry"},{name:"status:open"}],
        assignees: [], milestone: null, createdAt: null, updatedAt: null,
        closedAt: null,
        url: ("https://github.com/fixture-org/roundtrip-v11.0/issues/" + $t40)
     }
     | .first_class_edges = ((.first_class_edges // []) + [{issue: ($t40|tonumber), blocked_by: ($t10|tonumber)}])' \
    "$STATE1")
printf '%s' "$injected" > "$STATE1"
# Mapping carries both TD ids so the decoder resolves the first-class edge
# back to the TD-010 pack-id.
TD040_MAPPING=$(tmf_mapping_load "$mapping_file")
TD040_MAPPING=$(tmf_mapping_set "$TD040_MAPPING" "TD-010" "$TD010_NUM" "http://x/$TD010_NUM")
TD040_MAPPING=$(tmf_mapping_set "$TD040_MAPPING" "TD-040" "$TD040_NUM" "http://x/$TD040_NUM")
# Fetch via the provider (same normalization the reverse orchestrator uses)
# and reconstruct via the public per-issue decoder; the fake-gh is
# re-exported on PATH for both the provider get + the first-class-edge fetch.
export PATH="$FAKE1:$PATH_SAVED"
TD040_ISSUE=$(tracker_provider_gh_get "$TD040_NUM" 2>/dev/null)
TD040_ENTRY=$(tracker_migrate_reverse_reconstruct "$TD040_ISSUE" "$TD040_MAPPING" 2>/dev/null)
export PATH="$PATH_SAVED"
[[ -n "$TD040_ISSUE" ]] \
    && t_pass "2.2c TD-040 issue present in tracker state (decode-layer injection)" \
    || t_fail "2.2c TD-040 issue present in tracker state (decode-layer injection)"
# The entry reconstructs with the correct pack-id (not dropped / misclassified).
assert_eq "2.2c TD-040 reconstructs with correct pack-id (BD-108 F5)" \
    "TD-040" "$(printf '%s' "$TD040_ENTRY" | jq -r '.pack_id // ""')"
# The first-class blocked-by edge folds TD-010 into the reconstructed
# Blockers list (the BD-111 first-class-edge channel).
td040_blockers=$(printf '%s' "$TD040_ENTRY" | jq -r '.blockers // [] | join(",")')
if [[ "$td040_blockers" == *"TD-010"* ]]; then
    t_pass "2.2c TD-040 Blockers: TD-010 folds via first-class edge (BD-111 channel)"
else
    t_fail "2.2c TD-040 Blockers: TD-010 should fold via first-class edge" \
        "got: $td040_blockers"
fi

# BD-204 C-4 / DP-2: NO sidecar on the pack surface (the carrier is the
# form family + the Issue body; the `.pack-tracker/reverse.sidecar.*` file
# is dropped). Assert no sidecar file was written.
sidecar=$(ls "$REPO1/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
[[ -z "$sidecar" ]] && t_pass "2.3 NO sidecar on pack reverse (DP-2 dropped)" \
    || t_fail "2.3 NO sidecar on pack reverse (DP-2 dropped)" "unexpected sidecar: $sidecar"

# BD-204 C-4/C-5: the pack reverse materializes the per-entry TREE (no
# monolith), and the pack forward READ the per-entry tree as input (C-5) —
# the round-trip is monolith-free on BOTH directions. Assert NO
# `pack-ops/BACKLOG.md` monolith exists at any point (fail-loud), and that
# the reverse EMITTED the tree.
[[ ! -f "$REPO1/pack-ops/BACKLOG.md" ]] \
    && t_pass "2.3 NO pack-ops/BACKLOG.md monolith (monolith-free round-trip)" \
    || t_fail "2.3 NO pack-ops/BACKLOG.md monolith (monolith-free round-trip)" \
        "unexpected monolith present"
[[ -f "$REPO1/backlog/BD-001.md" && -f "$REPO1/backlog/_toc.md" ]] \
    && t_pass "2.3 per-entry tree + _toc.md emitted" \
    || t_fail "2.3 per-entry tree + _toc.md emitted"

# BD-204 C-4: each tree entry's line 1 is the per-entry back-pointer
# (not a mirror header). Verify on BD-001.
[[ "$(head -n 1 "$REPO1/backlog/BD-001.md")" == "<!-- per-entry source: /backlog/BD-001.md;"* ]] \
    && t_pass "2.3 tree entry line-1 is the per-entry back-pointer" \
    || t_fail "2.3 tree entry line-1 is the per-entry back-pointer"

# ─────────────────────────────────────────────────────────────────
# Group 3: F→R→F produces byte-equivalent tracker state
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: F→R→F byte-equivalent on tracker side ===\n"

# Capture first-forward signature.
SIG_BEFORE=$(_state_create_signature "$STATE1")

# Set up a fresh state file but preserve the flat input. Wipe mapping
# + state so the second forward starts fresh.
# BD-204 C-5 (C2a): the pack forward now reads the per-entry TREE (the
# no-monolith SSOT). The first reverse (Group 2) re-emitted the SAME
# BD-only tree under `/backlog/`, so the second forward reads that
# regenerated tree — equivalent to the input Group 1's first forward
# consumed, so the F→R→F create signature stays byte-equal. (Both the
# forward READ and the reverse EMIT are now monolith-free, pairing C-5
# with C-4.) NOTE: the 2.2c decode-layer test above injected two TD
# issues into $STATE1; we wipe $STATE1 here so the second forward starts
# from a clean tracker state.
rm -f "$REPO1/.pack-tracker/id-map.json"
rm -f "$STATE1"

# Re-run forward against the same flat input. Re-uses the same fake
# gh + state file path; fake gh re-initializes state on first call.
export PATH="$FAKE1:$PATH_SAVED"
output3=$(tracker_migrate_forward_run "$REPO1" 0 0 0 2>&1)
rc3=$?
export PATH="$PATH_SAVED"

assert_eq       "3.1 second forward rc=0"   "0" "$rc3"
assert_eq       "3.1 second forward state has 6 issues" "6" "$(_state_issue_count "$STATE1")"

# Compare create-call signatures — these capture "<title> | <labels>"
# for every create. Byte-equal means tracker side is round-trip stable
# (V1 §6.7 "byte-equivalent on tracker side").
SIG_AFTER=$(_state_create_signature "$STATE1")
assert_eq "3.1 F→R→F tracker signature byte-equal" "$SIG_BEFORE" "$SIG_AFTER"

rm -rf "$REPO1" "$FAKE1"

# ─────────────────────────────────────────────────────────────────
# Group 4: BD-204 C-4 / DP-2 — NO sidecar on the pack surface
# ─────────────────────────────────────────────────────────────────
#
# Pre-C-4 this group asserted the reverse sidecar carried an
# extra_fields block per entry. Per DP-2 (user 2026-06-06) the
# `.pack-tracker/reverse.sidecar.*` file is DROPPED on the pack surface
# — the carrier is the form family + the Issue body (the in-body
# pack-extra-fields block renders INLINE into the tree). This group now
# proves the pack reverse writes NO sidecar and materializes the tree.

printf "\n=== Group 4: BD-204 NO sidecar on pack reverse (DP-2) ===\n"

REPO2=$(_setup_test_repo "$FIXTURE_V11_0")
FAKE2=$(mktemp -d "${TMPDIR:-/tmp}/rtrip-fake2.XXXXXX")
STATE2="$REPO2/.pack-tracker/fake-tracker-state.json"
_build_stateful_fake_gh "$FAKE2" "$STATE2"

export PATH="$FAKE2:$PATH_SAVED"
tracker_migrate_forward_run "$REPO2" 0 0 0 >/dev/null 2>&1
tracker_migrate_reverse_run "$REPO2" 0 0 0 >/dev/null 2>&1
export PATH="$PATH_SAVED"

# No sidecar file written on the pack surface.
sidecar2=$(ls "$REPO2/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
[[ -z "$sidecar2" ]] && t_pass "4.1 NO sidecar on pack reverse (DP-2 dropped)" \
    || t_fail "4.1 NO sidecar on pack reverse (DP-2 dropped)" "unexpected sidecar: $sidecar2"

# The per-entry tree carries every `pack-backlog` (BD-only) entry (the
# forward INPUT is the per-entry tree itself — C-5 — not a monolith).
# BD-204 C-4 LOW-1: the emit is filtered to the `pack-backlog` entry regex,
# so non-`BD-*` ids (TD-010/TD-040) are NOT emitted to the pack tree — the
# emit set == the backup set == the `_toc.md` set by construction.
tree_all=$(cat "$REPO2"/backlog/BD-*.md 2>/dev/null)
for needle in "BD-001" "BD-002"; do
    assert_contains "4.1 tree carries $needle entry" "$tree_all" "$needle"
done
for td in "TD-010" "TD-040"; do
    [[ ! -f "$REPO2/backlog/$td.md" ]] \
        && t_pass "4.1 $td NOT emitted to pack tree (emit==backup==toc set)" \
        || t_fail "4.1 $td NOT emitted to pack tree (emit==backup==toc set)"
done
[[ -f "$REPO2/backlog/_toc.md" ]] \
    && t_pass "4.1 _toc.md regenerated (DP-4)" \
    || t_fail "4.1 _toc.md regenerated (DP-4)"

rm -rf "$REPO2" "$FAKE2"

# ─────────────────────────────────────────────────────────────────
# Group 5: multi-template-version readiness
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: multi-template-version readiness (V1 §6.6.1) ===\n"

# Iterate over every bd-v11.x/ directory; live ones (have a
# BACKLOG.md) are skipped here (already exercised in Groups 1-4);
# stub ones (only README.md) are noted.
for dir in "$FIXTURES_ROOT"/bd-v11.*; do
    name=$(basename "$dir")
    if [[ -f "$dir/BACKLOG.md" ]]; then
        t_pass "5.1 $name is a live fixture"
    elif [[ -f "$dir/README.md" ]]; then
        # Stub directory; verify the README documents stub status.
        readme_content=$(cat "$dir/README.md")
        if [[ "$readme_content" == *"stub"* ]]; then
            t_pass "5.1 $name is a stub directory (README documents stub status)"
        else
            t_fail "5.1 $name README does not document stub status"
        fi
    else
        t_fail "5.1 $name has neither fixture nor README"
    fi
done

# Verify the three expected directories exist.
for v in bd-v11.0 bd-v11.1 bd-v11.2; do
    [[ -d "$FIXTURES_ROOT/$v" ]] && t_pass "5.2 $v directory exists" \
        || t_fail "5.2 $v directory exists"
done

# ─────────────────────────────────────────────────────────────────
# Group 6: BD-204 rehearsal run-3 — forward RE-RUN link idempotency
# (Defect B) + post-CRUD reverse with n/a-resolution projection
# symmetry (Defect C). Reproduces the live oracle's repeated-cycle +
# interleaved-CRUD topologies that run 3 failed:
#   - Defect B: forward re-run re-attempted `addBlockedBy` for an
#     existing edge → partial-write rc=1 (live GH is not idempotent).
#     The fake-gh addBlockedBy arm carries a DUPLICATE-EDGE SENTINEL
#     (exit 1 on an existing edge), so these legs FAIL if production
#     ever re-attempts the mutation instead of read-skipping.
#   - Defect C: a blob-consistent status-flip update (description +
#     raw_body recompose; the entry's `Resolved: n/a` projects EMPTY)
#     made the next reverse flag a phantom `(Resolution)` divergence
#     and abort — cascading BD-908-missing / count / status failures.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: BD-204 run-3 re-run idempotency + post-CRUD reverse (Defects B + C) ===\n"

REPO6=$(_setup_test_repo "$FIXTURE_V11_0")
FAKE6=$(mktemp -d "${TMPDIR:-/tmp}/rtrip-fake6.XXXXXX")
STATE6="$REPO6/.pack-tracker/fake-tracker-state.json"
_build_stateful_fake_gh "$FAKE6" "$STATE6"

# Forward run 1 — creates the issues + the BD-002 blocked-by BD-001 edge.
export PATH="$FAKE6:$PATH_SAVED"
out6a=$(tracker_migrate_forward_run "$REPO6" 0 0 0 2>&1); rc6a=$?
export PATH="$PATH_SAVED"
assert_eq "6.1 forward 1 rc=0" "0" "$rc6a"
edges_after_1=$(jq '.first_class_edges // [] | length' "$STATE6")
[[ "$edges_after_1" -ge 1 ]] \
    && t_pass "6.1 forward 1 created >=1 first-class blocked-by edge (got $edges_after_1)" \
    || t_fail "6.1 forward 1 created >=1 first-class blocked-by edge" "got $edges_after_1"

# 6.2 Defect B — forward RE-RUN with tracker state + id-map INTACT (the
# run-3 repeated-cycle topology; Group 3 above wipes both, so this leg is
# the only mock coverage of the re-link path). Must be a clean skip-all
# run: rc=0, no creates, NO step-7 partial-write, edge set unchanged.
export PATH="$FAKE6:$PATH_SAVED"
out6b=$(tracker_migrate_forward_run "$REPO6" 0 0 0 2>&1); rc6b=$?
export PATH="$PATH_SAVED"
assert_eq           "6.2 forward RE-RUN rc=0 (no step-7 partial-write — Defect B)" "0" "$rc6b"
assert_contains_line "6.2 re-run created NOTHING (idempotent)" "$out6b" "created:    0"
assert_not_contains "6.2 re-run has NO step-7 link failure" "$out6b" "step-7 link blocked-by"
assert_not_contains "6.2 re-run has NO partial-write error" "$out6b" "partial-write"
edges_after_2=$(jq '.first_class_edges // [] | length' "$STATE6")
assert_eq "6.2 edge set unchanged after re-run (no duplicate edge)" \
    "$edges_after_1" "$edges_after_2"

# 6.3 Defect C — interleaved CRUD, then reverse (the run-3 cycle-3
# topology). (a) provider_create a NEW BD-009 mid-cycle (the BD-908
# analog) + register it in the id-map exactly as the forward loop does.
export _TRACKER_PROVIDER_CONFIG_PATH="$REPO6/tracker.toml"
bd9_raw=$'**BD-009 — Interleaved-CRUD create**\nType: TODO(version)\nStatus: Open\nBlockers: None\nUnblocks: None\nDescription: created mid-cycle; must appear after the next reverse.\nResolved: n/a\n'
bd9_body=$(tmf_compose_issue_body "BD-009" "created mid-cycle; must appear after the next reverse." "" "" "" "$bd9_raw")
bd9_payload=$(jq -n --arg t "BD-009: Interleaved-CRUD create" --arg b "$bd9_body" \
    '{title: $t, body: $b, labels: ["bd-entry", "template:bd-v11.0", "status:open"]}')
export PATH="$FAKE6:$PATH_SAVED"
bd9_result=$(provider_create "$bd9_payload"); bd9_rc=$?
export PATH="$PATH_SAVED"
assert_eq "6.3 provider_create BD-009 rc=0" "0" "$bd9_rc"
bd9_id=$(printf '%s' "$bd9_result" | jq -r '.id')
map6=$(tmf_mapping_load "$REPO6/.pack-tracker/id-map.json")
map6=$(tmf_mapping_set "$map6" "BD-009" "$bd9_id" "")
tmf_mapping_save "$REPO6/.pack-tracker/id-map.json" "$map6"

# (b) Blob-consistent status-flip update BD-002 Unblocked → Deferred via
# the REAL provider_update, with the SAME recompose call shape the live
# oracle used: parsed description (+ this entry's File/Symbol) + the
# flipped raw_body; resolution stays EMPTY because the entry is
# unresolved (`Resolved: n/a`) — the exact Defect-C case.
bd2_tmp=$(mktemp "${TMPDIR:-/tmp}/rtrip-bd2.XXXXXX")
pe_strip_backpointer_stdin < "$REPO6/backlog/BD-002.md" \
    | sed 's/^Status: Unblocked$/Status: Deferred/' > "$bd2_tmp"
bd2_raw=$(cat "$bd2_tmp"; printf X); bd2_raw="${bd2_raw%X}"
bd2_parsed=$(_tmf_parse_backlog_file "$bd2_tmp")
rm -f "$bd2_tmp"
bd2_desc=$(printf '%s' "$bd2_parsed" | jq -r '.[0].description // ""')
bd2_fs=$(printf   '%s' "$bd2_parsed" | jq -r '.[0].file_symbol // ""')
bd2_body=$(tmf_compose_issue_body "BD-002" "$bd2_desc" "" "" "$bd2_fs" "$bd2_raw")
bd2_update=$(jq -n --arg b "$bd2_body" \
    '{body: $b, add_labels: ["status:deferred"], remove_labels: ["status:unblocked"]}')
bd2_gh_id=$(tmf_mapping_get "$map6" "BD-002")
export PATH="$FAKE6:$PATH_SAVED"
provider_update "$bd2_gh_id" "$bd2_update" >/dev/null 2>&1; up_rc=$?
export PATH="$PATH_SAVED"
assert_eq "6.3 provider_update BD-002 rc=0 (blob + H2 + label in one write)" "0" "$up_rc"

# (c) Reverse (cycle 3, post-CRUD): pre-fix this aborted with the phantom
# `(Resolution)` divergence on the flipped entry; post-fix it completes
# and the three cascade failures clear (BD-009 appears, count, status).
export PATH="$FAKE6:$PATH_SAVED"
out6c=$(tracker_migrate_reverse_run "$REPO6" 0 0 0 2>&1); rc6c=$?
export PATH="$PATH_SAVED"
assert_eq           "6.3 post-CRUD reverse rc=0 (NO phantom Resolution divergence — Defect C)" "0" "$rc6c"
assert_not_contains "6.3 reverse output has NO divergence error" "$out6c" "divergence:"
if [[ -f "$REPO6/backlog/BD-009.md" ]]; then
    bd9_recon=$(pe_strip_backpointer_stdin < "$REPO6/backlog/BD-009.md"; printf X); bd9_recon="${bd9_recon%X}"
    assert_eq "6.3 BD-009 appears byte-verbatim (cascade clears)" "$bd9_raw" "$bd9_recon"
else
    t_fail "6.3 BD-009 appears byte-verbatim (cascade clears)" "BD-009.md missing from the reconstructed tree"
fi
grep -q '^Status: Deferred$' "$REPO6/backlog/BD-002.md" \
    && t_pass "6.3 BD-002 status round-trips as Deferred (cascade clears)" \
    || t_fail "6.3 BD-002 status round-trips as Deferred (cascade clears)"
bd2_recon=$(pe_strip_backpointer_stdin < "$REPO6/backlog/BD-002.md"; printf X); bd2_recon="${bd2_recon%X}"
assert_eq "6.3 BD-002 flipped entry byte-verbatim from the blob" "$bd2_raw" "$bd2_recon"
count6=$(ls "$REPO6/backlog" | grep -Ec '^BD-[0-9]+\.md$')
assert_eq "6.3 count oracle after create (cascade clears)" "5" "$count6"

# (d) Re-forward (cycle 3, post-CRUD): skip-all + the SAME blocked-by
# re-link must read-skip again (Defect B against the 5-entry tree).
export PATH="$FAKE6:$PATH_SAVED"
out6d=$(tracker_migrate_forward_run "$REPO6" 0 0 0 2>&1); rc6d=$?
export PATH="$PATH_SAVED"
assert_eq           "6.4 post-CRUD re-forward rc=0 (Defect B)" "0" "$rc6d"
assert_contains_line "6.4 re-forward created NOTHING (state already on the tracker)" "$out6d" "created:    0"
assert_contains_line "6.4 re-forward sees all 5 entries" "$out6d" "entries:    5"
assert_not_contains "6.4 re-forward has NO step-7 link failure" "$out6d" "step-7 link blocked-by"

rm -rf "$REPO6" "$FAKE6"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
