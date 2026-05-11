#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11-dry-run.sh — BD-095 two-phase
# workflow tests for `scripts/migrate-v10-to-v11.sh`.
#
# Verifies the new --dry-run / --apply / --resume modes:
#   1.  --dry-run produces report + dispositions.tsv + fingerprint.
#   2.  --dry-run writes NO project files (working tree clean post-run).
#   3.  --apply succeeds when fresh dry-run output exists.
#   4.  --apply fails clearly when no dry-run output exists.
#   5.  --apply fails when dry-run output is older than 24h.
#   6.  --apply fails when working-tree fingerprint changed since dry-run.
#   7.  --resume succeeds after `.resolved` flag-file (§6.H signal a).
#   8.  --resume succeeds after extension removal (§6.H signal b).
#   9.  --resume fails if no in-progress migration exists.
#  10.  --resume cannot rewind (forward-only — refuses if S4..S6 done).
#  11.  Bare invocation (no flag) auto-runs dry-run + applies (BD-095
#       backwards-compat).
#
# These are NEW behaviors. The pre-existing `test-migrate-v10-to-v11.sh`
# remains the regression guard for the framework end-to-end.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATE_SH="$REPO_ROOT/scripts/migrate-v10-to-v11.sh"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }
assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' got='$3'"; fi
}
assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}

# Shared fixture: minimal v10-shaped target.
make_v10_target() {
    local d
    d=$(mktemp -d -t migrate10-bd095.XXXXXX)
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"
    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.gemini"
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state" 2>/dev/null
    printf '%s\n' "$d"
}

# Snapshot of the working-tree state — return a single string we can
# diff against post-run to detect mutation.
snapshot_tree() {
    local d="$1"
    ( cd "$d" && find . -type f \
        -not -path './.git/*' \
        -not -path './.pack-migrate-*/*' \
        | sort \
        | xargs -I{} shasum -a 256 {} 2>/dev/null \
        | sort )
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: --dry-run produces artifacts but does not mutate
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: --dry-run artifacts + no mutation ===\n"

T=$(make_v10_target)
SNAP_BEFORE=$(snapshot_tree "$T")
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" 2>&1) ; rc=$?
assert_eq "1.1 --dry-run rc=0" "0" "$rc"

[[ -f "$T/.pack-migrate-v10-to-v11/report.md" ]] \
    && t_pass "1.2 --dry-run wrote report.md" \
    || t_fail "1.2 --dry-run report.md missing"
[[ -f "$T/.pack-migrate-v10-to-v11/dispositions.tsv" ]] \
    && t_pass "1.3 --dry-run wrote dispositions.tsv" \
    || t_fail "1.3 --dry-run dispositions.tsv missing"
[[ -f "$T/.pack-migrate-v10-to-v11/dry-run.fingerprint" ]] \
    && t_pass "1.4 --dry-run wrote fingerprint" \
    || t_fail "1.4 --dry-run fingerprint missing"

# Fingerprint schema sanity.
fp_content=$(cat "$T/.pack-migrate-v10-to-v11/dry-run.fingerprint" 2>/dev/null)
assert_contains "1.5 fingerprint has schema=1"     "$fp_content" "schema=1"
assert_contains "1.5 fingerprint has to_version"   "$fp_content" "to_version=v11"
assert_contains "1.5 fingerprint has epoch"        "$fp_content" "epoch="
assert_contains "1.5 fingerprint has target_sha"   "$fp_content" "target_sha256="
assert_contains "1.5 fingerprint has target_files" "$fp_content" "target_files="

# Working tree mutation check.
SNAP_AFTER=$(snapshot_tree "$T")
if [[ "$SNAP_BEFORE" == "$SNAP_AFTER" ]]; then
    t_pass "1.6 --dry-run did not mutate any project files"
else
    t_fail "1.6 --dry-run mutated project files"
fi

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: --apply success path with fresh dry-run
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: --apply with fresh dry-run ===\n"

T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1 ; rc=$?
assert_eq "2.0 setup --dry-run rc=0" "0" "$rc"

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
assert_eq "2.1 --apply rc=0 (fresh fingerprint)" "0" "$rc"
assert_contains "2.2 --apply ran preflight"   "$out" "S0 — pre-flight"
assert_contains "2.3 --apply ran S6"          "$out" "S6 — render truthful migration report"

# Apply should produce sentinels.
[[ -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S0.done" ]] \
    && t_pass "2.4 stage-S0.done sentinel" \
    || t_fail "2.4 stage-S0.done missing"
[[ -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S6.done" ]] \
    && t_pass "2.5 stage-S6.done sentinel" \
    || t_fail "2.5 stage-S6.done missing"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: --apply fails when no fresh dry-run
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: --apply freshness gate ===\n"

# 3.1 No dry-run output at all.
T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "3.1 --apply rc!=0 (no fingerprint)" \
                 || t_fail "3.1 --apply succeeded without fingerprint"
assert_contains "3.1 --apply error names fingerprint" "$out" \
    "fresh --dry-run report"
assert_contains "3.1 --apply error proposes --dry-run" "$out" \
    "--dry-run"
rm -rf "$T"

# 3.2 Stale dry-run (fingerprint older than 24h).
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
# Backdate fingerprint epoch by 25h (90000s).
fp="$T/.pack-migrate-v10-to-v11/dry-run.fingerprint"
old_epoch=$(grep '^epoch=' "$fp" | cut -d= -f2)
new_epoch=$(( old_epoch - 90000 ))
sed_tmp=$(mktemp)
awk -v ne="$new_epoch" -F= '
    /^epoch=/ { print "epoch=" ne; next }
    { print }
' "$fp" > "$sed_tmp"
mv "$sed_tmp" "$fp"

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "3.2 --apply rc!=0 (stale fingerprint >24h)" \
                 || t_fail "3.2 --apply succeeded with stale fingerprint"
assert_contains "3.2 --apply error names freshness window" "$out" \
    "24h freshness"
rm -rf "$T"

# 3.3 Working-tree drift since dry-run (fingerprint sha mismatch).
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
# Mutate the customization surface — append to CLAUDE.md.
echo "# drift after dry-run" >> "$T/CLAUDE.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "drift" 2>/dev/null

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "3.3 --apply rc!=0 (fingerprint drift)" \
                 || t_fail "3.3 --apply succeeded after drift"
assert_contains "3.3 --apply error names fingerprint mismatch" "$out" \
    "working-tree fingerprint changed"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: --resume happy paths (both signals)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: --resume conflict resolution signals ===\n"

# Helper: run dry-run + apply where apply pauses with sidecars present.
# We force a pause by injecting a customization that triggers the
# real-merge-required path → needs-reconciliation → sidecar.
prepare_paused() {
    local d
    d=$(make_v10_target)
    printf '\n## Project customization line\n' >> "$d/CLAUDE.md"
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "project customization" 2>/dev/null
    PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$d" >/dev/null 2>&1
    # Apply pauses at S3 with conflicts. Exit code 0 (clean pause).
    PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply "$d" >/dev/null 2>&1
    printf '%s\n' "$d"
}

# 4.1 --resume after `.resolved` flag-file signal.
T=$(prepare_paused)
paused="$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
if [[ ! -s "$paused" ]]; then
    t_fail "4.0 prepare_paused did not produce conflicts"
else
    t_pass "4.0 prepare_paused produced sidecars to reconcile"
    # Mark each sidecar resolved via the flag-file signal.
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        touch "${s}.resolved"
    done < "$paused"
    out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
    assert_eq "4.1 --resume rc=0 (.resolved signal)" "0" "$rc"
    assert_contains "4.1 --resume completed S6" "$out" "S6 — render"
    [[ -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S6.done" ]] \
        && t_pass "4.1 stage-S6.done after --resume" \
        || t_fail "4.1 stage-S6.done missing after --resume"
fi
rm -rf "$T"

# 4.2 --resume after extension-removal signal.
T=$(prepare_paused)
paused="$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
if [[ ! -s "$paused" ]]; then
    t_fail "4.2 prepare_paused did not produce conflicts"
else
    # Mark each sidecar resolved by removing it (rename the file
    # back to its bare name; or simply remove the sidecar — both are
    # "extension removed" from the perspective of the BD-095 contract).
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        rm -f "$s"
    done < "$paused"
    out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
    assert_eq "4.2 --resume rc=0 (extension-removed signal)" "0" "$rc"
    assert_contains "4.2 --resume completed S6" "$out" "S6 — render"
fi
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 5: --resume failure paths
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: --resume guards ===\n"

# 5.1 No in-progress migration → error.
T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "5.1 --resume rc!=0 (no migration)" \
                 || t_fail "5.1 --resume succeeded without prior migration"
assert_contains "5.1 --resume error names state-dir" "$out" \
    "in-progress migration"
rm -rf "$T"

# 5.2 --resume cannot rewind: a completed --apply (no conflicts) leaves
# stage-S6.done; --resume must refuse.
T=$(make_v10_target)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --dry-run "$T" >/dev/null 2>&1
PACK="$REPO_ROOT" bash "$MIGRATE_SH" --apply   "$T" >/dev/null 2>&1
# After a no-conflict apply, stage-S3.paused does NOT exist (no
# pause); the resume guard should fire on missing paused-sentinel.
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "5.2 --resume rc!=0 (no pause to resume)" \
                 || t_fail "5.2 --resume succeeded with no pause"
rm -rf "$T"

# 5.3 Forward-only: synthesize a state where S4.done already exists
# alongside S3.paused (inconsistent state); --resume must refuse to
# rewind.
T=$(prepare_paused)
mkdir -p "$T/.pack-migrate-v10-to-v11/sentinels"
touch "$T/.pack-migrate-v10-to-v11/sentinels/stage-S4.done"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "5.3 --resume rc!=0 (forward-only guard)" \
                 || t_fail "5.3 --resume succeeded past forward-only guard"
assert_contains "5.3 --resume error names forward-only" "$out" \
    "forward-only"
rm -rf "$T"

# 5.4 Unresolved sidecars present → refuse with actionable message.
T=$(prepare_paused)
paused="$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused"
if [[ -s "$paused" ]]; then
    out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" --resume "$T" 2>&1) ; rc=$?
    [[ "$rc" -ne 0 ]] && t_pass "5.4 --resume rc!=0 (unresolved sidecars)" \
                     || t_fail "5.4 --resume succeeded with unresolved sidecars"
    assert_contains "5.4 --resume names unresolved count" "$out" \
        "unresolved"
fi
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 6: bare-invocation backwards-compat
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6: bare-invocation backwards-compat ===\n"

T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "6.1 bare invocation rc=0" "0" "$rc"
assert_contains "6.1 auto-runs --dry-run first" "$out" \
    "no fresh dry-run found"
assert_contains "6.1 proceeds to --apply"        "$out" \
    "proceeding to --apply"
[[ -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S6.done" ]] \
    && t_pass "6.2 bare invocation completes through S6" \
    || t_fail "6.2 stage-S6.done missing after bare invocation"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All BD-095 tests passed."
    exit 0
fi
exit 1
