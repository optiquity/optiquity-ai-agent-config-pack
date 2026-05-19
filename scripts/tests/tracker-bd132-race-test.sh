#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/tracker-bd132-race-test.sh — BD-132 silent-data-loss
# regression coverage.
#
# Pins the three-part fix for the init→disable race that caused
# ~33% of BACKLOG entries to silently drop in the BD-102 Phase A
# dog-food (2026-05-08):
#
#   Part 1  Forward-side close stabilization wait
#           (_tmf_wait_for_close_stabilization in tracker-migrate-forward.sh).
#   Part 2  Reverse-side race detection
#           (forward.checkpoint.json freshness + mapping mtime check
#           in tracker_migrate_reverse_run when flip_mode=1).
#   Part 3  Reverse-loop silent-skip → loud-failure
#           (skipped_log accumulation + non-zero exit unless --force).
#
# All scenarios are mock-based (fake `gh` on PATH, fixture
# tracker.toml + id-map.json). No live GitHub state is touched.
#
# Usage:    bash scripts/tests/tracker-bd132-race-test.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PACK_ROOT/scripts/lib"

FIXTURE_BASE="$(mktemp -d -t bd132-race.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}
assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label" "needle '$needle'" "haystack head: ${haystack:0:200}"
    fi
}

# Source libs.
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

# ── fixture macros ─────────────────────────────────────────────────────

# mkfixture: create a sub-dir under FIXTURE_BASE; emit its absolute path.
mkfixture() {
    local name="$1"
    local dir="$FIXTURE_BASE/$name"
    mkdir -p "$dir"
    printf '%s' "$dir"
}

# build_test_repo: minimal tracker.toml + .pack-tracker/id-map.json
# with three mapped entries (BD-001, BD-002, TD-010). The fake gh
# below decides which of those issues are "readable" vs. "in flight."
build_test_repo() {
    local repo="$1"
    cat > "$repo/tracker.toml" <<EOF
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
    # BD-175: pack-side test fixture needs pack-ops/ for surface=pack auto-detect.
    mkdir -p "$repo/pack-ops" "$repo/.pack-tracker"
    cat > "$repo/.pack-tracker/id-map.json" <<EOF
{
  "BD-001": {"id": "42", "url": "http://x/42"},
  "BD-002": {"id": "43", "url": "http://x/43"},
  "TD-010": {"id": "55", "url": "http://x/55"}
}
EOF
}

# build_fake_gh_with_inflight: fake `gh` that returns four issues
# from `issue list --label bd-entry`. Simulates two distinct BD-102
# Phase A failure modes:
#
#   #43 → `gh issue view` itself errors (provider_get-fails path).
#         Body is unreadable because the close just finished and gh
#         hasn't propagated state yet.
#
#   #44 → `gh issue view` succeeds but returns a body with NO pack-id
#         marker AND #44 is NOT in the id-map (so the gh_id → pack_id
#         mapping fallback also fails). This is the F-3 coverage
#         case: it exercises the "pack-id not resolvable" silent-skip
#         path, which the BD-102 Phase A dog-food actually saw —
#         partial body update where pack-id marker lands later than
#         status fields. Without coverage here, a regression that
#         re-silenced this code path (tracker-migrate-reverse.sh
#         line ~739) would slip past the test suite.
build_fake_gh_with_inflight() {
    local bin="$1"
    cat > "$bin/gh" <<'FG'
#!/usr/bin/env bash
label=""
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--label" ]]; then
        j=$((i+1))
        label="${!j}"
        break
    fi
done
case "$1 $2" in
    "issue list")
        case "$label" in
            bd-entry)
                echo '[{"number":42,"title":"BD-001: Add foo","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/42"},{"number":43,"title":"BD-002: in-flight","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/43"},{"number":44,"title":"BD-?: body marker missing","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/44"}]'
                ;;
            td-entry)
                echo '[{"number":55,"title":"TD-010: Doc","state":"OPEN","labels":[{"name":"td-entry"}],"assignees":[],"milestone":null,"url":"http://x/55"}]'
                ;;
            phase-epic)
                echo '[]'
                ;;
            *)
                # state=closed (the stabilization poll) → return 0 closed.
                echo '[]'
                ;;
        esac
        ;;
    "issue view")
        case "$3" in
            42) echo '{"number":42,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nFoo","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}' ;;
            # Issue 43 simulates the eventual-consistency window: gh
            # itself returns an error (issue is mid-update from a just-
            # finished close call). This is one realistic BD-102 Phase
            # A failure mode — provider_get fails, the entry is
            # silently `continue`-d in pre-fix code.
            43) echo "API error: issue temporarily unreadable" >&2; exit 1 ;;
            # Issue 44 simulates the OTHER BD-102 Phase A failure mode
            # (F-3): provider_get succeeds with valid JSON, but the
            # body has NO pack-id marker (mid-write window). The id
            # is also absent from id-map.json, so the gh_id → pack_id
            # mapping fallback also fails. This must surface as
            # "pack-id not resolvable", not a silent drop.
            44) echo '{"number":44,"title":"BD-?: body marker missing","body":"## Description\n\nMid-update body lost the pack-id marker","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/44"}' ;;
            55) echo '{"number":55,"title":"TD-010: Doc","body":"<!-- pack-id: TD-010 -->\n\n## Description\n\nDoc","state":"OPEN","stateReason":null,"labels":[{"name":"td-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/55"}' ;;
            *)  echo '{}' ;;
        esac
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

# build_fake_gh_clean: fake `gh` where every issue resolves cleanly
# (no in-flight). Used by the race-detection test where we want to
# verify the BLOCK behavior — not the silent-skip behavior.
build_fake_gh_clean() {
    local bin="$1"
    cat > "$bin/gh" <<'FG'
#!/usr/bin/env bash
label=""
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--label" ]]; then
        j=$((i+1))
        label="${!j}"
        break
    fi
done
case "$1 $2" in
    "issue list")
        case "$label" in
            bd-entry) echo '[{"number":42,"title":"BD-001: Add foo","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/42"}]' ;;
            *)        echo '[]' ;;
        esac
        ;;
    "issue view")
        case "$3" in
            42) echo '{"number":42,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nFoo","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}' ;;
            *)  echo '{}' ;;
        esac
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

# ── Group 1: Part 3 — silent-skip → loud-failure ─────────────────────
echo "== Group 1: silent-skip → loud-failure =="

REPO=$(mkfixture "g1-repo")
build_test_repo "$REPO"
# Backdate the mapping file so race-detection (Part 2) does not fire;
# we want to isolate Part 3's silent-skip behavior in this group.
touch -t 202001010000 "$REPO/.pack-tracker/id-map.json"

# F-2: pre-seed BACKLOG.md with sentinel content so assertion 1.7
# tests something discriminating. Without this seed the previous
# assertion `[[ ! -f BACKLOG.md ]]` was trivially true: the fixture
# never wrote BACKLOG.md and the failure path wouldn't have either,
# so the assertion had no power to detect a regression that wrote
# half-data into BACKLOG.md. With a sentinel pre-seeded we assert
# the skip-guard refused BEFORE any rewrite touched the file.
G1_SENTINEL='SENTINEL-BD132-F2: pre-existing BACKLOG must not be overwritten when skip-guard fires.'
printf '%s\n' "$G1_SENTINEL" > "$REPO/pack-ops/BACKLOG.md"

FAKE=$(mkfixture "g1-fake-bin")
build_fake_gh_with_inflight "$FAKE"

export PATH="$FAKE:$PATH_SAVED"
out=$(tracker_migrate_reverse_run "$REPO" 0 1 0 0 2>&1)
rc=$?
export PATH="$PATH_SAVED"

assert_eq       "1.1 silent-skip path returns rc=1 (no force)"        "1" "$rc"
assert_contains "1.2 stderr names the skipped gh id (provider_get fail)" "$out" "gh #43"
# F-3: the second skip mode — provider_get succeeds but body lacks
# the pack-id marker AND id is not in id-map. The reverse loop
# must surface this as "pack-id not resolvable", not silently drop.
assert_contains "1.2b stderr names the body-marker-missing gh id (F-3)"  "$out" "gh #44"
assert_contains "1.2c stderr explains pack-id not resolvable (F-3)"      "$out" "pack-id not resolvable"
assert_contains "1.3 stderr names skip count"                        "$out" "2 issue(s) skipped"
assert_contains "1.4 partial-write error code surfaced"              "$out" "ERROR: partial-write"
assert_contains "1.5 message points at silent-data-loss guard"       "$out" "silent-data-loss guard"
assert_contains "1.6 message names BD-132 / D-5 origin"              "$out" "BD-132"

# 1.7 (F-2): verify the pre-seeded BACKLOG.md sentinel survived
# unchanged. The skip-guard must refuse BEFORE _tmr_emit_backlog
# rewrites the file. Reading the file content (not just existence)
# is the assertion that has discriminating power.
g1_backlog_after=$(cat "$REPO/pack-ops/BACKLOG.md" 2>/dev/null || echo "<MISSING>")
assert_eq "1.7 BACKLOG.md sentinel preserved when skip-guard fires" \
    "$G1_SENTINEL" "$g1_backlog_after"

# 1.8: verify mode NOT flipped (the guard runs before _tmr_update_tracker_toml).
mode_after=$(tracker_config_get "$REPO/tracker.toml" mode.state)
assert_eq "1.8 mode NOT flipped when skip-guard fires" "tracker" "$mode_after"

# ── Group 2: Part 3 — --force overrides skip guard ────────────────────
echo
echo "== Group 2: --force overrides skip guard =="

REPO2=$(mkfixture "g2-repo")
build_test_repo "$REPO2"
touch -t 202001010000 "$REPO2/.pack-tracker/id-map.json"

FAKE2=$(mkfixture "g2-fake-bin")
build_fake_gh_with_inflight "$FAKE2"

export PATH="$FAKE2:$PATH_SAVED"
# force=1: skip-guard converted to WARN-only; reverse proceeds with
# the partial set. (This is the "operator knows what they're doing"
# escape valve. The WARN still emits.)
out2=$(tracker_migrate_reverse_run "$REPO2" 0 1 0 1 2>&1)
rc2=$?
export PATH="$PATH_SAVED"

assert_eq       "2.1 --force returns rc=0 (proceeds despite skips)"   "0" "$rc2"
assert_contains "2.2 --force still emits WARN to stderr"             "$out2" "2 issue(s) skipped"
[[ -f "$REPO2/pack-ops/BACKLOG.md" ]] \
    && pass "2.3 --force writes (partial) BACKLOG.md" \
    || fail "2.3 --force writes (partial) BACKLOG.md" "file present" "missing"
mode_after2=$(tracker_config_get "$REPO2/tracker.toml" mode.state)
assert_eq "2.4 --force flips mode to flat-file" "flat-file" "$mode_after2"

# ── Group 3: Part 2 — race-detection refuses on fresh mapping ─────────
echo
echo "== Group 3: race-detection on fresh mapping file =="

REPO3=$(mkfixture "g3-repo")
build_test_repo "$REPO3"
# Mapping file mtime is "now" (just created) — under the freshness
# threshold (default 30s). Race-detection should refuse.

FAKE3=$(mkfixture "g3-fake-bin")
build_fake_gh_clean "$FAKE3"

export PATH="$FAKE3:$PATH_SAVED"
out3=$(tracker_migrate_reverse_run "$REPO3" 0 1 0 0 2>&1)
rc3=$?
export PATH="$PATH_SAVED"

assert_eq       "3.1 race-detection rc=1 on fresh mapping"            "1" "$rc3"
assert_contains "3.2 message names freshness threshold"              "$out3" "freshness threshold"
assert_contains "3.3 message warns about silent-data-loss"           "$out3" "silently drop entries"
assert_contains "3.4 validation error code surfaced"                 "$out3" "ERROR: validation"
# Mode must not have flipped (guard runs before _tmr_update_tracker_toml).
mode_after3=$(tracker_config_get "$REPO3/tracker.toml" mode.state)
assert_eq "3.5 mode NOT flipped when race-detection fires" "tracker" "$mode_after3"

# ── Group 4: Part 2 — race-detection refuses on checkpoint present ───
echo
echo "== Group 4: race-detection on checkpoint file present =="

REPO4=$(mkfixture "g4-repo")
build_test_repo "$REPO4"
# Backdate mapping to defeat the freshness check; isolate the
# checkpoint-file signal.
touch -t 202001010000 "$REPO4/.pack-tracker/id-map.json"
# Plant a forward checkpoint (simulates forward run mid-flight).
echo '{"last_step":"step-4","completed_pack_ids":[]}' \
    > "$REPO4/.pack-tracker/forward.checkpoint.json"

FAKE4=$(mkfixture "g4-fake-bin")
build_fake_gh_clean "$FAKE4"

export PATH="$FAKE4:$PATH_SAVED"
out4=$(tracker_migrate_reverse_run "$REPO4" 0 1 0 0 2>&1)
rc4=$?
export PATH="$PATH_SAVED"

assert_eq       "4.1 race-detection rc=1 on checkpoint present"       "1" "$rc4"
assert_contains "4.2 message names checkpoint file"                  "$out4" "forward checkpoint file present"
assert_contains "4.3 message proposes init --resume recovery"        "$out4" "pack tracker init --resume"

# ── Group 5: Part 2 — --force overrides race-detection ────────────────
echo
echo "== Group 5: --force overrides race-detection =="

REPO5=$(mkfixture "g5-repo")
build_test_repo "$REPO5"
# Fresh mapping — race-detection would refuse without --force.
FAKE5=$(mkfixture "g5-fake-bin")
build_fake_gh_clean "$FAKE5"

export PATH="$FAKE5:$PATH_SAVED"
out5=$(tracker_migrate_reverse_run "$REPO5" 0 1 0 1 2>&1)
rc5=$?
export PATH="$PATH_SAVED"

assert_eq "5.1 --force bypasses race-detection (rc=0)" "0" "$rc5"
mode_after5=$(tracker_config_get "$REPO5/tracker.toml" mode.state)
assert_eq "5.2 --force flips mode despite fresh mapping" "flat-file" "$mode_after5"

# ── Group 6: Part 2 — non-disable reverse not affected ───────────────
echo
echo "== Group 6: non-disable reverse not subject to race-detection =="

REPO6=$(mkfixture "g6-repo")
build_test_repo "$REPO6"
# Plant a fresh mapping AND a checkpoint — both race signals.
echo '{"last_step":"step-4","completed_pack_ids":[]}' \
    > "$REPO6/.pack-tracker/forward.checkpoint.json"

FAKE6=$(mkfixture "g6-fake-bin")
build_fake_gh_clean "$FAKE6"

# flip_mode=0: a plain `tracker-migrate.sh reverse` (NOT disable).
# The race-detection guard only applies when flip_mode=1, since plain
# reverse leaves mode=tracker — there's no irreversible commit to
# guard. (This separation matches V1 §6.5 / V2 §22.1: disable is the
# only verb that flips state.)
export PATH="$FAKE6:$PATH_SAVED"
out6=$(tracker_migrate_reverse_run "$REPO6" 0 0 0 0 2>&1)
rc6=$?
export PATH="$PATH_SAVED"

assert_eq "6.1 plain reverse (flip_mode=0) ignores race-detection" "0" "$rc6"

# ── Group 7: Part 1 — close-stabilization helper bounded behavior ────
echo
echo "== Group 7: Part 1 close-stabilization helper =="

# Override the bounded-poll knobs so this group runs in <1 second.
TMF_STABILIZE_MAX_ATTEMPTS=2
TMF_STABILIZE_SLEEP_SECS=0
export TMF_STABILIZE_MAX_ATTEMPTS TMF_STABILIZE_SLEEP_SECS

# 7.1: zero closes → no-op (fast return).
out7a=$(_tmf_wait_for_close_stabilization 0 2>&1)
rc7a=$?
assert_eq "7.1 zero closes → rc=0 (no-op)" "0" "$rc7a"
assert_eq "7.1 zero closes → no progress output" "" "$out7a"

# 7.2: stabilization with a fake gh that always returns the same
# closed count → first poll matches "prev_count=-1"? No: prev_count
# starts at -1 so first read sets it; second read matches → stable.
FAKE7=$(mkfixture "g7-fake-bin")
cat > "$FAKE7/gh" <<'FG'
#!/usr/bin/env bash
case "$1 $2" in
    "issue list")
        # Always: 5 closed issues.
        echo '[{"number":1},{"number":2},{"number":3},{"number":4},{"number":5}]'
        ;;
    *) ;;
esac
exit 0
FG
chmod +x "$FAKE7/gh"

# Need a fake config so provider_list resolves to gh backend.
REPO7=$(mkfixture "g7-repo")
build_test_repo "$REPO7"
export _TRACKER_PROVIDER_CONFIG_PATH="$REPO7/tracker.toml"

export PATH="$FAKE7:$PATH_SAVED"
out7b=$(_tmf_wait_for_close_stabilization 5 2>&1)
rc7b=$?
export PATH="$PATH_SAVED"
unset _TRACKER_PROVIDER_CONFIG_PATH

assert_eq       "7.2 stable count → rc=0"                            "0" "$rc7b"
assert_contains "7.2 stabilization message names final count"        "$out7b" "stable at 5"

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
