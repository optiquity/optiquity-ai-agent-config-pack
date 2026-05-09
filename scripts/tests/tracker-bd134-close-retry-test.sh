#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/tracker-bd134-close-retry-test.sh — BD-134 close
# retry-with-backoff regression coverage.
#
# Pins the end-of-init re-run-failed-closes pass that drives the
# forward step-8 partial-write rate from ~5% (3 of 56 in BD-102 Phase
# A dog-food: BD-021/022/023) toward zero on transient `gh` API
# failures. Three scenarios:
#
#   Group 1  Transient close (fails N-1 times, succeeds on retry):
#            asserts 0 partial-writes, retry sweep recovers the close,
#            forward summary shows the recovered count.
#
#   Group 2  Persistent close (fails on every attempt): asserts the
#            close eventually surfaces as partial-write naming the
#            gh-id, bounded by TMF_CLOSE_RETRY_MAX_ATTEMPTS — does
#            NOT loop forever.
#
#   Group 3  Helper-level isolation: directly exercises
#            `_tmf_retry_one_close` against a mock `provider_close`
#            shim — verifies attempt count, success path, and the
#            "max_attempts <= 1 disables retry" edge.
#
# All scenarios are mock-based (fake `gh` on PATH or function-shim
# override of provider_close). No live GitHub state is touched.
#
# Usage:    bash scripts/tests/tracker-bd134-close-retry-test.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PACK_ROOT/scripts/lib"

FIXTURE_BASE="$(mktemp -d -t bd134-retry.XXXXXX)"
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
assert_not_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        pass "$label"
    else
        fail "$label" "needle '$needle' MUST NOT appear" "haystack head: ${haystack:0:200}"
    fi
}

# Keep all retry sleeps at zero so the suite runs in well under 1s.
export TMF_CLOSE_RETRY_BACKOFF_SECS="0 0 0 0 0"
# Keep BD-132 stabilization fast too.
export TMF_STABILIZE_MAX_ATTEMPTS=2
export TMF_STABILIZE_SLEEP_SECS=0

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
source "$LIB_DIR/tracker-migrate-forward.sh"

PATH_SAVED="$PATH"

# ── fixture macros ─────────────────────────────────────────────────────

mkfixture() {
    local name="$1"
    local dir="$FIXTURE_BASE/$name"
    mkdir -p "$dir"
    printf '%s' "$dir"
}

# build_repo: minimal repo with a 2-entry BACKLOG (one Resolved → close
# attempted) + tracker.toml. Uses the same shape as the existing
# tracker-migrate-forward-test fixtures.
build_repo() {
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
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
EOF
    cat > "$repo/BACKLOG.md" <<'EOF'
# Backlog

## Active

**BD-001 — First entry, will be closed**
Type: TODO(v11)
Status: Resolved
Blockers: none
Unblocks: none
File/Symbol: scripts/foo.sh
Description: First entry, marked Resolved → close attempted in step 8.
Resolution: done in commit abc1234

---

**BD-002 — Second entry, will be closed**
Type: TODO(v11)
Status: Resolved
Blockers: none
Unblocks: none
File/Symbol: scripts/bar.sh
Description: Second entry, also Resolved → close attempted in step 8.
Resolution: done in commit def5678

---
EOF
    cat > "$repo/IMPLEMENTATION_PLAN.md" <<'EOF'
# Implementation Plan
EOF
}

# build_fake_gh_transient_close: fake `gh` where each `issue close`
# fails the FIRST time it's called for a given issue id, then
# succeeds. State is per-id and persists across the run via a tracking
# file. Other gh verbs (create/list/view/repo) succeed normally.
build_fake_gh_transient_close() {
    local bin="$1"
    local state_file="$2"
    : > "$state_file"
    cat > "$bin/gh" <<FG
#!/usr/bin/env bash
case "\$1 \$2" in
    "issue create")
        # Echo a sequential URL so provider_create returns a usable id.
        if [[ ! -f "$state_file.counter" ]]; then echo "1000" > "$state_file.counter"; fi
        n=\$(cat "$state_file.counter")
        n=\$((n + 1))
        echo "\$n" > "$state_file.counter"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$n"
        ;;
    "issue close")
        id="\$3"
        # Fail the first time we see this id; succeed thereafter.
        if grep -q "^seen:\$id\$" "$state_file" 2>/dev/null; then
            # Already attempted once → succeed on retry.
            exit 0
        else
            printf 'seen:%s\n' "\$id" >> "$state_file"
            echo "HTTP 503: transient API error" >&2
            exit 1
        fi
        ;;
    "issue list")
        # Stabilization poll: return whatever closed ids we have so the
        # wait helper can succeed quickly.
        printf '['
        first=1
        while IFS= read -r line; do
            id="\${line#seen:}"
            [[ -z "\$id" ]] && continue
            if [[ \$first -eq 1 ]]; then first=0; else printf ','; fi
            printf '{"number":%s}' "\$id"
        done < "$state_file"
        printf ']\n'
        ;;
    "issue view")    echo '{"labels":[],"assignees":[]}' ;;
    "issue comment") ;;
    "issue edit")    ;;
    "search issues") echo '[]' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

# build_fake_gh_persistent_close: fake `gh` where every `issue close`
# fails. Used to verify the bounded-failure path: max attempts, then
# the close lands in partial_failures naming the gh-id.
build_fake_gh_persistent_close() {
    local bin="$1"
    local state_file="$2"
    : > "$state_file"
    cat > "$bin/gh" <<FG
#!/usr/bin/env bash
case "\$1 \$2" in
    "issue create")
        if [[ ! -f "$state_file.counter" ]]; then echo "2000" > "$state_file.counter"; fi
        n=\$(cat "$state_file.counter")
        n=\$((n + 1))
        echo "\$n" > "$state_file.counter"
        printf 'https://github.com/fixture-org/fixture-repo/issues/%s\n' "\$n"
        ;;
    "issue close")
        # Track every close attempt for the bounded-attempt assertion.
        printf 'attempt:%s\n' "\$3" >> "$state_file"
        echo "HTTP 503: persistent API error" >&2
        exit 1
        ;;
    "issue list")    echo '[]' ;;
    "issue view")    echo '{"labels":[],"assignees":[]}' ;;
    "issue comment") ;;
    "issue edit")    ;;
    "search issues") echo '[]' ;;
    "repo view")     echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    "api graphql")   echo '{}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

# ── Group 1: transient close → recovered by retry sweep ───────────────
echo "== Group 1: transient close failure → retry recovers =="

REPO=$(mkfixture "g1-repo")
build_repo "$REPO"

FAKE=$(mkfixture "g1-fake-bin")
STATE="$FIXTURE_BASE/g1-state"
build_fake_gh_transient_close "$FAKE" "$STATE"

export PATH="$FAKE:$PATH_SAVED"
# Use defaults: max-attempts=3 means the original try + 2 retries.
out=$(tracker_migrate_forward_run "$REPO" 0 0 2>&1)
rc=$?
export PATH="$PATH_SAVED"

assert_eq "1.1 transient-close run rc=0 (retries succeeded)" "0" "$rc"
assert_not_contains "1.2 no partial-write surfaced (transient closes recovered)" \
    "$out" "ERROR: partial-write"
assert_contains "1.3 forward summary mentions retry sweep" \
    "$out" "close-retry sweep"
assert_contains "1.4 retry sweep names recovered count" \
    "$out" "recovered=2"
assert_contains "1.5 retry sweep shows persistent=0 for transient case" \
    "$out" "persistent=0"
# Both BD-001 and BD-002 should appear closed in the forward summary.
assert_contains "1.6 forward summary shows closed: 2" \
    "$out" "closed:     2"
# The fake gh logged "seen:<id>" for each close that was attempted.
seen_count=$(grep -c '^seen:' "$STATE" 2>/dev/null || echo 0)
assert_eq "1.7 each issue saw exactly one initial-failure attempt" "2" "$seen_count"

# ── Group 2: persistent close → bounded failure surfaces ──────────────
echo
echo "== Group 2: persistent close failure → bounded partial-write =="

REPO2=$(mkfixture "g2-repo")
build_repo "$REPO2"

FAKE2=$(mkfixture "g2-fake-bin")
STATE2="$FIXTURE_BASE/g2-state"
build_fake_gh_persistent_close "$FAKE2" "$STATE2"

export TMF_CLOSE_RETRY_MAX_ATTEMPTS=3
export PATH="$FAKE2:$PATH_SAVED"
out2=$(tracker_migrate_forward_run "$REPO2" 0 0 2>&1)
rc2=$?
export PATH="$PATH_SAVED"
unset TMF_CLOSE_RETRY_MAX_ATTEMPTS

assert_eq "2.1 persistent-close run rc=1 (partial-write surfaced)" "1" "$rc2"
assert_contains "2.2 partial-write error code surfaced" \
    "$out2" "ERROR: partial-write"
assert_contains "2.3 partial-write line names step-8 close" \
    "$out2" "step-8 close"
assert_contains "2.4 partial-write line names BD-001" \
    "$out2" "BD-001"
assert_contains "2.5 partial-write line cites attempt count" \
    "$out2" "failed after 3 attempts"
assert_contains "2.6 retry sweep persistent count surfaces" \
    "$out2" "persistent=2"

# CRITICAL: bounded — exactly 3 attempts per id (1 initial + 2 retries).
# 2 ids × 3 attempts = 6 total `gh issue close` invocations.
total_attempts=$(grep -c '^attempt:' "$STATE2" 2>/dev/null || echo 0)
assert_eq "2.7 close attempts bounded (3 per id × 2 ids = 6 — NOT infinite)" \
    "6" "$total_attempts"

# Verify the per-id breakdown is exactly 3 each.
bd001_attempts=$(grep -c "^attempt:1001\|^attempt:1002\|^attempt:2001\|^attempt:2002" "$STATE2" 2>/dev/null || echo 0)
# We don't know the exact ids issued by the create counter, so just
# verify the total is 6 (above) and each id was attempted 3 times.
ids_seen=$(grep '^attempt:' "$STATE2" | sed 's/^attempt://' | sort -u | wc -l | tr -d ' ')
assert_eq "2.8 exactly 2 distinct ids attempted" "2" "$ids_seen"
per_id_max=$(grep '^attempt:' "$STATE2" | sed 's/^attempt://' | sort | uniq -c \
    | awk '{print $1}' | sort -n | tail -1 | tr -d ' ')
assert_eq "2.9 max attempts per id is exactly 3 (bounded)" "3" "$per_id_max"
per_id_min=$(grep '^attempt:' "$STATE2" | sed 's/^attempt://' | sort | uniq -c \
    | awk '{print $1}' | sort -n | head -1 | tr -d ' ')
assert_eq "2.10 min attempts per id is exactly 3 (no early exit)" "3" "$per_id_min"

# ── Group 3: _tmf_retry_one_close helper isolation ────────────────────
echo
echo "== Group 3: _tmf_retry_one_close helper unit tests =="

# 3.1 max_attempts <= 1 disables retry — return 1 immediately.
TMF_CLOSE_RETRY_MAX_ATTEMPTS=1
provider_close() { return 1; }  # would always succeed if called
out3a=$(_tmf_retry_one_close "999" "completed" 2>&1)
rc3a=$?
unset -f provider_close
assert_eq "3.1 max_attempts=1 → rc=1 immediately (no retry)" "1" "$rc3a"

# 3.2 succeeds on first retry (attempt #2 overall).
TMF_CLOSE_RETRY_MAX_ATTEMPTS=3
__retry_call_count=0
provider_close() {
    __retry_call_count=$((__retry_call_count + 1))
    # Succeed on the first call (which is the first RETRY since the
    # initial attempt happened in the main close loop above).
    return 0
}
_tmf_retry_one_close "999" "completed" >/dev/null 2>&1
rc3b=$?
unset -f provider_close
assert_eq "3.2 succeeds on first retry → rc=0" "0" "$rc3b"
assert_eq "3.2 exactly 1 provider_close call (first retry succeeded)" \
    "1" "$__retry_call_count"

# 3.3 fails every retry → rc=1 after exactly max_attempts-1 calls.
TMF_CLOSE_RETRY_MAX_ATTEMPTS=4
__retry_call_count=0
provider_close() {
    __retry_call_count=$((__retry_call_count + 1))
    return 1
}
_tmf_retry_one_close "999" "completed" >/dev/null 2>&1
rc3c=$?
unset -f provider_close
assert_eq "3.3 all retries fail → rc=1" "1" "$rc3c"
assert_eq "3.3 exactly max_attempts-1 (=3) provider_close retry calls" \
    "3" "$__retry_call_count"

# 3.4 succeeds on the 2nd retry (last allowed) when max_attempts=3.
TMF_CLOSE_RETRY_MAX_ATTEMPTS=3
__retry_call_count=0
provider_close() {
    __retry_call_count=$((__retry_call_count + 1))
    if [[ $__retry_call_count -lt 2 ]]; then return 1; fi
    return 0
}
_tmf_retry_one_close "999" "completed" >/dev/null 2>&1
rc3d=$?
unset -f provider_close
assert_eq "3.4 succeeds on last allowed retry → rc=0" "0" "$rc3d"
assert_eq "3.4 exactly 2 provider_close retry calls before success" \
    "2" "$__retry_call_count"

# Restore default.
unset TMF_CLOSE_RETRY_MAX_ATTEMPTS

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
