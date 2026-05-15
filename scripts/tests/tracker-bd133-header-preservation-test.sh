#!/usr/bin/env bash
# scripts/tests/tracker-bd133-header-preservation-test.sh — BD-133 / D-6
# regression suite: BACKLOG.md header preamble must survive reverse
# migration (and any number of round-trips) byte-identical.
#
# Pre-fix behavior (BD-102 Phase A dog-food):
#   `pack tracker disable` reverse-emits BACKLOG.md from scratch with
#   `# BACKLOG\n` + entries. Every byte of preamble (the `# Backlog`
#   title, intro paragraph, `## How to use this file` section, type
#   conventions, etc.) is destroyed on every reverse cycle.
#
# Post-fix behavior:
#   On the first reverse, the existing BACKLOG.md preamble is
#   snapshotted into `.pack-tracker/backlog-header.snapshot`. The
#   reverse emitter writes entries-only, then the snapshot is
#   prepended back. Subsequent reverses re-use the same snapshot
#   (first-write-wins) so the preamble does not degrade across
#   multiple round-trips.
#
# Test groups:
#   1. Direct module API — tracker_header_snapshot_capture /
#      tracker_header_snapshot_apply behaviors in isolation.
#   2. Reverse-only round-trip — sentinel preamble survives one
#      reverse cycle (no init, mapping pre-seeded).
#   3. init→disable round-trip — full forward + reverse cycle via
#      the round-trip stateful fake gh; preamble survives.
#   4. Multi-cycle stability — N round-trips do not degrade the
#      preamble (no header-eating-itself).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()       { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains() { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }

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
source "$LIB_DIR/tracker-header-snapshot.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

PATH_SAVED="$PATH"

# ─────────────────────────────────────────────────────────────────
# Sentinel preamble used across all groups. Mirrors the shape of the
# real pack-repo BACKLOG.md preamble (title, paragraph, H2 section,
# `---` separator, blank line, then the first entry).
# ─────────────────────────────────────────────────────────────────

SENTINEL_PREAMBLE="# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.
Items use BD-NNN identifiers (Backlog Description).

## How to use this file

- Resolved entries flip Status: Open → Status: Resolved in place.
- See METHODOLOGY.md §988 for the v10 grammar reference.

---
"

# ─────────────────────────────────────────────────────────────────
# Group 1: direct module API
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: tracker-header-snapshot.sh module API ===\n"

# 1.1 capture: substantive preamble → snapshot file written.
TMP_REPO=$(mktemp -d -t bd133-1.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
cat > "$TMP_REPO/BACKLOG.md" <<EOF
${SENTINEL_PREAMBLE}
**BD-001 — first entry**
Type: TODO(version)
Status: Open
Description: x
EOF
tracker_header_snapshot_capture "$TMP_REPO"
[[ -f "$TMP_REPO/.pack-tracker/backlog-header.snapshot" ]] \
    && t_pass "1.1 snapshot file created on first capture" \
    || t_fail "1.1 snapshot file created on first capture"
snap_content=$(cat "$TMP_REPO/.pack-tracker/backlog-header.snapshot")
assert_contains "1.1 snapshot has title"      "$snap_content" "# Backlog"
assert_contains "1.1 snapshot has paragraph"  "$snap_content" "All planned improvements"
assert_contains "1.1 snapshot has H2 section" "$snap_content" "## How to use this file"
# Snapshot must NOT contain the first entry heading.
if [[ "$snap_content" == *"BD-001"* ]]; then
    t_fail "1.1 snapshot stops before first entry" "BD-001 leaked into snapshot"
else
    t_pass "1.1 snapshot stops before first entry"
fi
rm -rf "$TMP_REPO"

# 1.2 capture is first-write-wins: second call does not overwrite.
TMP_REPO=$(mktemp -d -t bd133-1b.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
cat > "$TMP_REPO/BACKLOG.md" <<EOF
# First version preamble

**BD-001 — x**
EOF
tracker_header_snapshot_capture "$TMP_REPO"
first_snap=$(cat "$TMP_REPO/.pack-tracker/backlog-header.snapshot")
# Now overwrite BACKLOG.md with a different preamble; capture again.
cat > "$TMP_REPO/BACKLOG.md" <<EOF
# DIFFERENT preamble — should not overwrite snapshot

**BD-001 — x**
EOF
tracker_header_snapshot_capture "$TMP_REPO"
second_snap=$(cat "$TMP_REPO/.pack-tracker/backlog-header.snapshot")
assert_eq "1.2 first-write-wins (second capture is no-op)" "$first_snap" "$second_snap"
rm -rf "$TMP_REPO"

# 1.3 trivial preamble (just `# BACKLOG`) → no snapshot written.
TMP_REPO=$(mktemp -d -t bd133-1c.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
cat > "$TMP_REPO/BACKLOG.md" <<'EOF'
# BACKLOG

**BD-001 — x**
EOF
tracker_header_snapshot_capture "$TMP_REPO"
[[ ! -f "$TMP_REPO/.pack-tracker/backlog-header.snapshot" ]] \
    && t_pass "1.3 trivial '# BACKLOG' preamble not snapshotted" \
    || t_fail "1.3 trivial '# BACKLOG' preamble not snapshotted" \
        "snapshot was written: $(cat "$TMP_REPO/.pack-tracker/backlog-header.snapshot")"
rm -rf "$TMP_REPO"

# 1.4 missing BACKLOG.md → no-op (no failure).
TMP_REPO=$(mktemp -d -t bd133-1d.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
tracker_header_snapshot_capture "$TMP_REPO"
rc=$?
assert_eq "1.4 missing BACKLOG.md → rc=0 (no-op)" "0" "$rc"
[[ ! -f "$TMP_REPO/.pack-tracker/backlog-header.snapshot" ]] \
    && t_pass "1.4 no snapshot file written when BACKLOG.md absent" \
    || t_fail "1.4 no snapshot file written when BACKLOG.md absent"
rm -rf "$TMP_REPO"

# 1.5 apply: snapshot replaces leading `# BACKLOG\n\n` and prepends.
TMP_REPO=$(mktemp -d -t bd133-1e.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
printf '%s' "$SENTINEL_PREAMBLE" > "$TMP_REPO/.pack-tracker/backlog-header.snapshot"
# Simulate _tmr_emit_backlog output — entries-only with bare title.
cat > "$TMP_REPO/BACKLOG.md" <<'EOF'
# BACKLOG

**BD-001 — first entry**
Type: TODO(version)
Status: Open
EOF
tracker_header_snapshot_apply "$TMP_REPO" "$TMP_REPO/BACKLOG.md"
applied=$(cat "$TMP_REPO/BACKLOG.md")
assert_contains "1.5 apply preserves snapshot title"      "$applied" "# Backlog"
assert_contains "1.5 apply preserves snapshot paragraph"  "$applied" "All planned improvements"
assert_contains "1.5 apply preserves H2 section"          "$applied" "## How to use this file"
assert_contains "1.5 apply preserves entries"             "$applied" "**BD-001 — first entry**"
# The entries-only `# BACKLOG` line must NOT appear after apply
# (it would be a duplicate title).
n_titles=$(printf '%s\n' "$applied" | grep -c -E '^# (BACKLOG|Backlog)$')
assert_eq "1.5 apply collapses to exactly one title line" "1" "$n_titles"
rm -rf "$TMP_REPO"

# 1.6 apply: missing snapshot → no-op (entries-only output unchanged).
TMP_REPO=$(mktemp -d -t bd133-1f.XXXXXX)
mkdir -p "$TMP_REPO/.pack-tracker"
cat > "$TMP_REPO/BACKLOG.md" <<'EOF'
# BACKLOG

**BD-001 — first entry**
EOF
before=$(cat "$TMP_REPO/BACKLOG.md")
tracker_header_snapshot_apply "$TMP_REPO" "$TMP_REPO/BACKLOG.md"
after=$(cat "$TMP_REPO/BACKLOG.md")
assert_eq "1.6 apply is no-op when snapshot absent" "$before" "$after"
rm -rf "$TMP_REPO"

# ─────────────────────────────────────────────────────────────────
# Group 2: reverse-only round-trip (mapping pre-seeded; no real
# forward call, so no BD-131-owned forward.sh path is exercised).
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: reverse-only header preservation ===\n"

# Build a fake gh that returns one canned BD-001 issue.
_build_fake_gh_g2() {
    local bin="$1"
    cat > "$bin/gh" <<'FG'
#!/usr/bin/env bash
label=""
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--label" ]]; then j=$((i+1)); label="${!j}"; break; fi
done
case "$1 $2" in
    "issue list")
        case "$label" in
            bd-entry)   echo '[{"number":42,"title":"BD-001: Add foo","state":"OPEN","labels":[{"name":"bd-entry"}],"assignees":[],"milestone":null,"url":"http://x/42"}]' ;;
            *)          echo '[]' ;;
        esac
        ;;
    "issue view")
        echo '{"number":42,"title":"BD-001: Add foo","body":"<!-- pack-id: BD-001 -->\n\n## Description\n\nx","state":"OPEN","stateReason":null,"labels":[{"name":"bd-entry"},{"name":"status:open"}],"assignees":[],"milestone":null,"createdAt":null,"updatedAt":null,"closedAt":null,"url":"http://x/42"}'
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/fixture-repo"}' ;;
    *) ;;
esac
exit 0
FG
    chmod +x "$bin/gh"
}

REPO=$(mktemp -d -t bd133-2.XXXXXX)
FAKE=$(mktemp -d -t bd133-2-fake.XXXXXX)
_build_fake_gh_g2 "$FAKE"

# Seed BACKLOG.md with the sentinel preamble + one entry. Seed the
# tracker.toml + mapping so reverse can run without a real forward.
cat > "$REPO/tracker.toml" <<EOF
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
mkdir -p "$REPO/.pack-tracker"
cat > "$REPO/.pack-tracker/id-map.json" <<'EOF'
{ "BD-001": {"id": "42", "url": "http://x/42"} }
EOF
cat > "$REPO/BACKLOG.md" <<EOF
${SENTINEL_PREAMBLE}
**BD-001 — Add foo**
Type: TODO(version)
Status: Open
Description: x
EOF

# Capture original preamble bytes for byte-equal comparison.
# Use a tmp file + `cmp -s` rather than `$(...)` capture: command
# substitution strips trailing newlines, so a file diff like
# `\n\n` vs `\n\n\n` would falsely compare equal as bash strings
# (review F2). `cmp -s` is byte-exact and rejects any trailing-
# newline drift, matching the BD-133 byte-identical contract.
WORK_G2=$(mktemp -d -t bd133-2-work.XXXXXX)
tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G2/orig.preamble"

# Run reverse (no flip; no force needed — mapping was just written
# but the test fixtures elsewhere bypass freshness via flip_mode=0).
export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_reverse_run "$REPO" 0 0 0 0 >/dev/null 2>&1
rc=$?
export PATH="$PATH_SAVED"

assert_eq "2.1 reverse rc=0" "0" "$rc"

# Snapshot file should now exist.
[[ -f "$REPO/.pack-tracker/backlog-header.snapshot" ]] \
    && t_pass "2.1 snapshot file created on first reverse" \
    || t_fail "2.1 snapshot file created on first reverse"

# Extract the post-reverse preamble and assert byte-equal via cmp -s.
tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G2/post.preamble"
if cmp -s "$WORK_G2/orig.preamble" "$WORK_G2/post.preamble"; then
    t_pass "2.2 post-reverse preamble byte-equal to original"
else
    t_fail "2.2 post-reverse preamble byte-equal to original" \
        "diff: orig=$(wc -c < "$WORK_G2/orig.preamble")b post=$(wc -c < "$WORK_G2/post.preamble")b"
fi

# The reconstructed BD-001 entry must still be present after the apply.
backlog_after=$(cat "$REPO/BACKLOG.md")
assert_contains "2.3 BD-001 entry present after apply" "$backlog_after" "**BD-001 — Add foo**"
assert_contains "2.3 user title preserved"   "$backlog_after" "# Backlog"
assert_contains "2.3 H2 section preserved"   "$backlog_after" "## How to use this file"

rm -rf "$REPO" "$FAKE" "$WORK_G2"

# ─────────────────────────────────────────────────────────────────
# Group 3: full forward → reverse round-trip via stateful fake gh.
# This exercises the same path the BD-102 Phase A dog-food caught.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: forward → reverse header preservation ===\n"

# Reuse the stateful fake-gh shape from the round-trip test (inlined
# here so this suite stands alone — no cross-test dependency).
_build_stateful_fake_gh_g3() {
    local bin_dir="$1"
    local state_file="$2"
    cat > "$bin_dir/gh" <<'FAKEGH'
#!/usr/bin/env bash
STATE="@@STATE@@"
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
            --arg id "$new_id" --arg title "$title" --arg body "$body" --argjson labels "$labels" \
            '.next_id = (.next_id | tonumber + 1)
             | .issues[$id] = {
                 number: ($id | tonumber), title: $title, body: $body,
                 state: "open", stateReason: null,
                 labels: $labels | map({name: .}),
                 assignees: [], milestone: null,
                 createdAt: null, updatedAt: null, closedAt: null,
                 url: ("https://github.com/fixture-org/bd133/issues/" + $id)
               }
             | .create_log += [($title + " | " + ($labels | join(",")))]')
        printf '%s' "$new_st" > "$STATE"
        echo "https://github.com/fixture-org/bd133/issues/$new_id"
        ;;
    "issue view")
        id="$3"; shift 3
        while [[ $# -gt 0 ]]; do
            case "$1" in --json) shift 2 ;; --jq) shift 2 ;; *) shift ;; esac
        done
        cat "$STATE" | jq -c --arg id "$id" '.issues[$id]'
        ;;
    "issue close")
        id="$3"; reason="completed"; shift 3
        while [[ $# -gt 0 ]]; do
            case "$1" in --reason) reason="$2"; shift 2 ;; *) shift ;; esac
        done
        st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" --arg reason "$reason" \
            '.issues[$id].state = "closed" | .issues[$id].stateReason = $reason')
        printf '%s' "$new_st" > "$STATE"
        ;;
    "issue reopen")
        id="$3"; st=$(cat "$STATE")
        new_st=$(printf '%s' "$st" | jq -c --arg id "$id" \
            '.issues[$id].state = "open" | .issues[$id].stateReason = null')
        printf '%s' "$new_st" > "$STATE"
        ;;
    "issue comment"|"issue edit") ;;
    "search issues") echo "[]" ;;
    "issue list")
        label=""
        for ((i=1; i<=$#; i++)); do
            if [[ "${!i}" == "--label" ]]; then j=$((i+1)); label="${!j}"; break; fi
        done
        st=$(cat "$STATE")
        printf '%s' "$st" | jq -c --arg label "$label" '
            [ .issues[] | select(.labels | map(.name) | index($label)) ]
            | map({number: .number, title: .title, state: .state,
                   labels: .labels, url: .url, id: (.number | tostring)})'
        ;;
    "repo view") echo '{"nameWithOwner":"fixture-org/bd133"}' ;;
    "api graphql") echo "{}" ;;
    "extension list") echo "" ;;
    *) ;;
esac
exit 0
FAKEGH
    sed -i.bak "s|@@STATE@@|$state_file|g" "$bin_dir/gh"
    rm -f "$bin_dir/gh.bak"
    chmod +x "$bin_dir/gh"
}

REPO=$(mktemp -d -t bd133-3.XXXXXX)
FAKE=$(mktemp -d -t bd133-3-fake.XXXXXX)
mkdir -p "$REPO/.pack-tracker"
STATE="$REPO/.pack-tracker/fake-state.json"
_build_stateful_fake_gh_g3 "$FAKE" "$STATE"

cat > "$REPO/tracker.toml" <<EOF
schema_version = 1
[backend]
name = "github"
repo = "fixture-org/bd133"
[mode]
state = "tracker"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
EOF
cat > "$REPO/IMPLEMENTATION-PLAN.md" <<'EOF'
# IMPLEMENTATION PLAN
EOF
cat > "$REPO/BACKLOG.md" <<EOF
${SENTINEL_PREAMBLE}
**BD-001 — Add foo**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: Add the foo to the bar.

---

**BD-002 — Refactor bar**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: Refactor.
EOF

# Capture pre-forward preamble bytes for byte-equal comparison.
# `cmp -s` against a tmp file (review F2) — see Group 2 for rationale.
WORK_G3=$(mktemp -d -t bd133-3-work.XXXXXX)
tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G3/orig.preamble"

# Forward (BD-131-owned forward.sh runs but we do NOT modify it).
export PATH="$FAKE:$PATH_SAVED"
tracker_migrate_forward_run "$REPO" 0 0 0 >/dev/null 2>&1
forward_rc=$?
# Reverse (with flip — `pack tracker disable` semantic). force=1 to
# bypass the BD-132 freshness window for this synchronous test.
tracker_migrate_reverse_run "$REPO" 0 1 0 1 >/dev/null 2>&1
reverse_rc=$?
export PATH="$PATH_SAVED"

assert_eq "3.1 forward rc=0" "0" "$forward_rc"
assert_eq "3.1 reverse rc=0" "0" "$reverse_rc"

# Snapshot file should exist.
[[ -f "$REPO/.pack-tracker/backlog-header.snapshot" ]] \
    && t_pass "3.2 snapshot file created during round-trip" \
    || t_fail "3.2 snapshot file created during round-trip"

# Preamble byte-equal via cmp -s.
tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G3/post.preamble"
if cmp -s "$WORK_G3/orig.preamble" "$WORK_G3/post.preamble"; then
    t_pass "3.3 init→disable preamble byte-equal to original"
else
    t_fail "3.3 init→disable preamble byte-equal to original" \
        "orig=$(wc -c < "$WORK_G3/orig.preamble")b post=$(wc -c < "$WORK_G3/post.preamble")b"
fi

# Entries also present.
backlog_after=$(cat "$REPO/BACKLOG.md")
assert_contains "3.4 BD-001 reconstructed" "$backlog_after" "**BD-001 — Add foo**"
assert_contains "3.4 BD-002 reconstructed" "$backlog_after" "**BD-002 — Refactor bar**"

rm -rf "$REPO" "$FAKE" "$WORK_G3"

# ─────────────────────────────────────────────────────────────────
# Group 4: multi-cycle stability — N reverses do not eat the header.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: multi-cycle stability ===\n"

REPO=$(mktemp -d -t bd133-4.XXXXXX)
FAKE=$(mktemp -d -t bd133-4-fake.XXXXXX)
_build_fake_gh_g2 "$FAKE"

cat > "$REPO/tracker.toml" <<EOF
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
mkdir -p "$REPO/.pack-tracker"
cat > "$REPO/.pack-tracker/id-map.json" <<'EOF'
{ "BD-001": {"id": "42", "url": "http://x/42"} }
EOF
cat > "$REPO/BACKLOG.md" <<EOF
${SENTINEL_PREAMBLE}
**BD-001 — Add foo**
Type: TODO(version)
Status: Open
EOF

# Capture original preamble bytes via tmp file + cmp -s (review F2);
# `$(...)` capture would mask trailing-newline drift across N cycles.
WORK_G4=$(mktemp -d -t bd133-4-work.XXXXXX)
tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G4/orig.preamble"

# Run reverse 5 times in a row.
export PATH="$FAKE:$PATH_SAVED"
for cycle in 1 2 3 4 5; do
    tracker_migrate_reverse_run "$REPO" 0 0 0 0 >/dev/null 2>&1
    cycle_rc=$?
    if [[ "$cycle_rc" != "0" ]]; then
        t_fail "4.1 reverse cycle $cycle rc=0" "rc=$cycle_rc"
    fi
done
export PATH="$PATH_SAVED"

tracker_header_snapshot_extract_preamble "$REPO/BACKLOG.md" > "$WORK_G4/post.preamble"
if cmp -s "$WORK_G4/orig.preamble" "$WORK_G4/post.preamble"; then
    t_pass "4.2 5 reverse cycles preserve preamble byte-equal"
else
    t_fail "4.2 5 reverse cycles preserve preamble byte-equal" \
        "orig=$(wc -c < "$WORK_G4/orig.preamble")b post=$(wc -c < "$WORK_G4/post.preamble")b"
fi

# Snapshot file is byte-identical to the original preamble (first-
# write-wins). Compare the two on-disk files directly via cmp -s
# (review F2: $()/cat would strip trailing newlines and mask drift).
if cmp -s "$REPO/.pack-tracker/backlog-header.snapshot" "$WORK_G4/orig.preamble"; then
    t_pass "4.3 snapshot equals original preamble (first-write-wins)"
else
    t_fail "4.3 snapshot equals original preamble (first-write-wins)" \
        "snap=$(wc -c < "$REPO/.pack-tracker/backlog-header.snapshot")b orig=$(wc -c < "$WORK_G4/orig.preamble")b"
fi

# Final BACKLOG.md still has exactly one title line (no duplication
# from repeated apply cycles).
n_titles=$(grep -c -E '^# (BACKLOG|Backlog)$' "$REPO/BACKLOG.md")
assert_eq "4.4 exactly one title line after N cycles" "1" "$n_titles"

rm -rf "$REPO" "$FAKE" "$WORK_G4"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
