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
# BD-204 C-4 RETIREMENT (pack surface):
#   The header-snapshot is RETIRED on the PACK reverse path (DP-5): the
#   pack reverse now emits the per-entry TREE (no `# BACKLOG` monolith),
#   and `_intro.md` is a pack-authored static file (untouched by reverse)
#   — so there is no monolith preamble for the pack reverse to capture /
#   re-apply. The former Groups 2-4 (pack-surface reverse-path header
#   preservation in pack-ops/BACKLOG.md) are therefore REMOVED. The
#   `tracker-header-snapshot.sh` module is DORMANT, not deleted (it still
#   serves the client `else` branch — BD-207), so its direct module-API
#   unit tests (Group 1) are KEPT.
#
# Test groups (post-BD-204-C-4):
#   1. Direct module API — tracker_header_snapshot_capture /
#      tracker_header_snapshot_apply behaviors in isolation (the module
#      stays dormant-valid; these unit tests are retained).

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
# Groups 2-4 RETIRED (BD-204 C-4 / DP-5).
# ─────────────────────────────────────────────────────────────────
#
# The former Groups 2 (reverse-only header preservation), 3 (init→disable
# round-trip), and 4 (multi-cycle stability) exercised the PACK-surface
# reverse-path header-snapshot integration on pack-ops/BACKLOG.md. Under
# BD-204 the pack reverse emits the per-entry TREE (no monolith) and does
# NOT call tracker_header_snapshot_capture / _apply on the pack surface
# (DP-5) — `_intro.md` is a pack-authored static file untouched by reverse.
# Those integration assertions therefore have no pack-surface target and
# are removed. The tracker-header-snapshot.sh module remains DORMANT (it
# still serves the client `else` branch — BD-207); its direct module-API
# unit tests are kept above (Group 1).

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
