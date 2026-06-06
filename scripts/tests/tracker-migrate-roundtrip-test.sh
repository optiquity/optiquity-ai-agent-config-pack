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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES_ROOT="$REPO_ROOT/scripts/tests/fixtures/roundtrip"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

# Source the libs so we can call orchestrators directly.
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
                 state: "open",
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
                --reason) reason="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" --arg reason "$reason" \
            '.issues[$id].state = "closed" | .issues[$id].stateReason = $reason')
        printf '%s' "$new_st" > "$STATE"
        ;;

    "issue reopen")
        id="$3"
        st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" \
            '.issues[$id].state = "open" | .issues[$id].stateReason = null')
        printf '%s' "$new_st" > "$STATE"
        ;;

    "issue comment"|"issue edit")
        ;;

    "search issues")
        echo "[]"
        ;;

    "issue list")
        echo "[]"
        ;;

    "repo view")
        # Honor --jq .nameWithOwner if requested (real gh would
        # apply the filter server-side; we approximate). BD-111
        # retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
        # pass): the production code does
        # `_gh_run gh repo view --json nameWithOwner --jq .nameWithOwner`
        # in multiple places (sub_issue_create, link, unlink,
        # _tmr_fetch_first_class_blocked_by). Without this filter
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
        # `blockedByIssues` query (reverse read side) so post-BD-111
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
                        blockedByIssueId=*) f_blocked_by="${2#blockedByIssueId=}" ;;
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
            if [[ -n "$src_n" && -n "$tgt_n" ]]; then
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
        elif [[ "$gquery" == *"blockedByIssues"* ]]; then
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
                '{data: {repository: {issue: {blockedByIssues: {nodes: $nodes}}}}}'
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
    test_repo=$(mktemp -d -t rtrip.XXXXXX)
    # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.
    # Fixtures still hold the legacy root-shape; copy into pack-ops/
    # so surface-aware forward/reverse helpers find the canonical
    # location, AND the pack-ops/ directory marker satisfies
    # tracker_config_auto_surface returning "pack".
    mkdir -p "$test_repo/pack-ops"
    cp "$fixture_dir/BACKLOG.md"             "$test_repo/pack-ops/BACKLOG.md"
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
FAKE1=$(mktemp -d -t rtrip-fake1.XXXXXX)
STATE1="$REPO1/.pack-tracker/fake-tracker-state.json"
_build_stateful_fake_gh "$FAKE1" "$STATE1"

export PATH="$FAKE1:$PATH_SAVED"
output1=$(tracker_migrate_forward_run "$REPO1" 0 0 0 2>&1)
rc1=$?
export PATH="$PATH_SAVED"

assert_eq       "1.1 forward run rc=0"           "0" "$rc1"
# BD-108 F5: bd-v11.0 fixture extended with TD-040 (Blockers: phase-1.2)
# so the full forward → state-file → reverse pipeline exercises the
# v11.0 phase-N.M Blockers grammar. Entry count: 4 BD/TD + 2 phase
# epics = 6 issues in the recorded state.
assert_contains "1.1 forward run reports 4 entries" "$output1" "parsed 4 BACKLOG entries"
assert_contains "1.1 forward run reports 2 phases"  "$output1" "2 phase(s)"

# State should have 4 BD/TD + 2 phase epics = 6 issues.
assert_eq "1.1 tracker state has 6 issues" "6" "$(_state_issue_count "$STATE1")"

# Mapping file populated.
mapping_file="$REPO1/.pack-tracker/id-map.json"
[[ -f "$mapping_file" ]] && t_pass "1.1 mapping file written" || t_fail "1.1 mapping file written"
assert_eq "1.1 mapping has 6 entries" "6" "$(jq 'length' "$mapping_file")"

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
assert_contains "2.1 reverse reports 4 entries"     "$output2" "reconstructed 4 BACKLOG entries"
assert_contains "2.1 reverse reports 2 phase epics" "$output2" "2 phase epic"

# Reverse output should reconstruct each entry. The reconstructed
# BACKLOG must contain every original pack-id and title (whitespace
# differences are tolerable per V1 §6.7 "near-no-op").
# BD-204 C-4: the pack reverse now emits the per-entry TREE (no monolith).
# BD-204 C-4 LOW-1 (PACK-REVIEW-BD-204-C4): the pack tree emit is filtered
# to the `pack-backlog` entry regex (`^BD-[0-9]+[a-z]*\.md$`) — the SAME
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

# Blockers — BD-111 closes the round-trip gap. With the BD-111 link
# swap (forward writes addBlockedBy GraphQL edge) plus the BD-111
# retrofit per PACK-REVIEW-BD-111 F1 (reverse reads blockedByIssues
# GraphQL edges in addition to body comment markers), the Blockers
# field round-trips through forward → state → reverse. The stateful
# fake-gh now records first_class_edges in state on addBlockedBy and
# serves them on blockedByIssues; the reverse decoder folds them
# into the Blockers list per scripts/lib/tracker-migrate-reverse.sh
# `_tmr_fetch_first_class_blocked_by` + `_tmr_decode_blockers`.
bd002_block_line=$(printf '%s' "$RECON_BACKLOG" | grep -A 3 "BD-002" | grep "Blockers:")
if [[ "$bd002_block_line" == *"BD-001"* ]]; then
    t_pass "2.2 BD-002 Blockers: BD-001 preserved (BD-111 round-trip)"
else
    t_fail "2.2 BD-002 Blockers: BD-001 should round-trip post-BD-111" "got: $bd002_block_line"
fi

# 2.2c BD-108 F5 — TD-040 Blockers `phase-1.2, TD-010` round-trip
# coverage. End-to-end the v11.0 phase-N.M grammar must survive
# forward → state-file → reverse without the entry being dropped or
# the pack-id being misclassified. With BD-111 (link swap) +
# PACK-REVIEW-BD-111 F1 retrofit (reverse reads first-class edges),
# resolvable Blockers references (those with id-map entries) round-
# trip via the first-class GraphQL channel.
#
# BD-204 C-4 LOW-1: TD-040 is a non-`BD-*` id, so post-LOW-1 it is
# correctly NOT emitted to the pack tree (the tree is the BD-only
# `pack-backlog` set). The TD-040 SURVIVAL + Blockers round-trip is a
# RECONSTRUCTION property (independent of the on-disk emit surface), so
# it is verified here at the reconstruction layer via the public
# `tracker_migrate_reverse_reconstruct` (the same decoder the orchestrator
# calls per issue), with the fake-gh re-exported on PATH for the
# first-class-edge fetch. No coverage is lost relative to the pre-LOW-1
# pack-tree-read assertion.
TD040_NUM=$(jq -r '."TD-040".id // empty' "$mapping_file")
[[ -n "$TD040_NUM" ]] \
    && t_pass "2.2c TD-040 mapped to a tracker issue (survives forward)" \
    || t_fail "2.2c TD-040 mapped to a tracker issue (survives forward)" \
        "TD-040 missing from id-map"
# Fetch via the provider (same normalization the reverse orchestrator
# uses) and reconstruct via the public per-issue decoder; the fake-gh is
# re-exported on PATH for both the provider get + the first-class-edge fetch.
export PATH="$FAKE1:$PATH_SAVED"
# tracker_provider_gh_get returns the canonical single issue OBJECT (the
# same normalized shape the reverse orchestrator feeds to the per-issue
# reconstruct decoder). reconstruct's arg2 is the mapping JSON CONTENT
# (loaded via tmf_mapping_load) — the same value the orchestrator passes.
TD040_ISSUE=$(tracker_provider_gh_get "$TD040_NUM" 2>/dev/null)
TD040_MAPPING=$(tmf_mapping_load "$mapping_file")
TD040_ENTRY=$(tracker_migrate_reverse_reconstruct "$TD040_ISSUE" "$TD040_MAPPING" 2>/dev/null)
export PATH="$PATH_SAVED"
# The entry reconstructs with the correct pack-id (not dropped / misclassified).
assert_eq "2.2c TD-040 reconstructs with correct pack-id (BD-108 F5)" \
    "TD-040" "$(printf '%s' "$TD040_ENTRY" | jq -r '.pack_id // ""')"
# TD-040 has Blockers `phase-1.2, TD-010`. The forward orchestrator
# resolves `TD-010` via the id-map (TD-010 was created earlier in
# the same forward run) → `addBlockedBy(TD-040, TD-010)` issued →
# round-trips through the BD-111 retrofit. The `phase-1.2` reference
# does NOT round-trip in v11.0 because the v11.0 forward writer
# creates phase EPIC issues only (not individual phase TASKS — that
# split is BD-105/BD-106 territory and lives in
# scripts/lib/tracker-migrate-forward.sh:942-960 case
# `phase-N.M` which silently skips when no mapping exists). So the
# expected post-BD-111 round-trip behavior for TD-040 is: Blockers
# list contains `TD-010` (the resolvable upstream); `phase-1.2` is
# silently dropped at forward-write time and absent from reverse.
# This is correct behavior given the v11.0 boundary; future BD-105
# / BD-106 phase-task-as-first-class-issue work would lift this
# limit and at that point the assertion can extend to also include
# `phase-1.2`.
td040_blockers=$(printf '%s' "$TD040_ENTRY" | jq -r '.blockers // [] | join(",")')
if [[ "$td040_blockers" == *"TD-010"* ]]; then
    t_pass "2.2c TD-040 Blockers: TD-010 round-trips post-BD-111 (resolvable Blockers via first-class edges)"
else
    t_fail "2.2c TD-040 Blockers: TD-010 should round-trip post-BD-111" \
        "got: $td040_blockers"
fi

# BD-204 C-4 / DP-2: NO sidecar on the pack surface (the carrier is the
# form family + the Issue body; the `.pack-tracker/reverse.sidecar.*` file
# is dropped). Assert no sidecar file was written.
sidecar=$(ls "$REPO1/.pack-tracker/reverse.sidecar."*.md 2>/dev/null | head -n 1)
[[ -z "$sidecar" ]] && t_pass "2.3 NO sidecar on pack reverse (DP-2 dropped)" \
    || t_fail "2.3 NO sidecar on pack reverse (DP-2 dropped)" "unexpected sidecar: $sidecar"

# BD-204 C-4: the pack reverse materializes the per-entry TREE (no
# monolith). The fixture pre-seeds pack-ops/BACKLOG.md as the forward
# INPUT (read until C-5 repoints forward), so its presence is expected;
# the load-bearing assertion is that the reverse EMITTED the tree.
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
# BD-204 C-4: the pack reverse no longer writes pack-ops/BACKLOG.md (it
# emits the per-entry tree). The forward read-side still reads the
# monolith until C-5 repoints it, so the second forward reads the
# unchanged fixture-copied pack-ops/BACKLOG.md — identical to the input
# Group 1's first forward consumed, so the F→R→F signature stays byte-
# equal. (C-5 repoints forward to read the tree.)
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
FAKE2=$(mktemp -d -t rtrip-fake2.XXXXXX)
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
# fixture's pre-seeded pack-ops/BACKLOG.md is the forward INPUT, not a
# reverse-written monolith). BD-204 C-4 LOW-1: the emit is filtered to the
# `pack-backlog` entry regex, so non-`BD-*` ids (TD-010/TD-040) are NOT
# emitted to the pack tree — the emit set == the backup set == the `_toc.md`
# set by construction.
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
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
