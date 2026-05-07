#!/usr/bin/env bash
# scripts/tests/test-migrate-v10-to-v11.sh — BD-085 fixture tests for
# the v10 → v11 migration script.
#
# These tests exercise the migrator end-to-end against a synthetic
# v10-state target. The pack repo is reused as $PACK so the v10 tag
# extracts genuine v10 baseline content via `git show v10:...`.

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

# Build a minimal v10-shaped target directory: trinity files + .claude/
# sufficient to pass migrator pre-flight. Working tree is clean (committed).
make_v10_target() {
    local d
    d=$(mktemp -d -t migrate10-tgt.XXXXXX)
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"

    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.gemini"
    # Use the actual v10 tag content for trinity so the BASE/OURS/THEIRS
    # 4-case hits unchanged-pack or merged-with-customization (avoids
    # spurious needs-reconciliation in the no-customization fixture).
    git -C "$REPO_ROOT" show v10:project-template/CLAUDE.md > "$d/CLAUDE.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/AGENTS.md > "$d/AGENTS.md" 2>/dev/null
    git -C "$REPO_ROOT" show v10:project-template/GEMINI.md > "$d/GEMINI.md" 2>/dev/null

    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state" 2>/dev/null
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: pre-flight checks
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: pre-flight ===\n"

# 1.1 --help exits 0.
out=$(bash "$MIGRATE_SH" --help 2>&1) ; rc=$?
assert_eq "1.1 --help rc=0" "0" "$rc"
assert_contains "1.1 --help shows usage" "$out" "Usage:"

# 1.2 unknown option exits with typed error.
out=$(bash "$MIGRATE_SH" --bogus 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "1.2 --bogus rc!=0" || t_fail "1.2 --bogus rc!=0"
assert_contains "1.2 --bogus typed error" "$out" "unknown option"

# 1.3 missing PACK exits 10.
T=$(mktemp -d -t migrate10-nopack.XXXXXX)
out=$(unset PACK; bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.3 missing PACK rc=10" "10" "$rc"
rm -rf "$T"

# 1.4 not a git repo exits 11.
T=$(mktemp -d -t migrate10-nogit.XXXXXX)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.4 not-a-git-repo rc=11" "11" "$rc"
rm -rf "$T"

# 1.5 dirty working tree exits 12.
T=$(make_v10_target)
echo "uncommitted" > "$T/dirty.txt"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.5 dirty tree rc=12" "12" "$rc"
rm -rf "$T"

# 1.6 not pack-configured exits 13.
T=$(mktemp -d -t migrate10-bare.XXXXXX)
git init -q "$T" >/dev/null
git -C "$T" config user.email "t@e"; git -C "$T" config user.name "t"
git -C "$T" commit --allow-empty -q -m "init" 2>/dev/null
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.6 not-v10 rc=13" "13" "$rc"
rm -rf "$T"

# 1.7 missing v10 tag exits 14 (override via env).
T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" V10_TAG="v999-nonexistent" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.7 missing baseline tag rc=14" "14" "$rc"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: end-to-end migration
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: end-to-end migration ===\n"

T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "2.1 migration rc=0" "0" "$rc"
assert_contains "2.1 S0 ran" "$out" "S0 — pre-flight"
assert_contains "2.1 S6 ran" "$out" "S6 — render truthful migration report"

# Backup written.
[[ -d "$T/.pack-migrate-v10-to-v11-backup" ]] \
    && t_pass "2.2 backup directory present" \
    || t_fail "2.2 backup directory missing"
[[ -f "$T/.pack-migrate-v10-to-v11-backup/CLAUDE.md" ]] \
    && t_pass "2.2 backup contains CLAUDE.md" \
    || t_fail "2.2 backup CLAUDE.md missing"

# State + report.
[[ -f "$T/.pack-migrate-v10-to-v11/dispositions.tsv" ]] \
    && t_pass "2.3 dispositions.tsv written" \
    || t_fail "2.3 dispositions.tsv missing"
[[ -f "$T/.pack-migrate-v10-to-v11/report.md" ]] \
    && t_pass "2.3 report.md written" \
    || t_fail "2.3 report.md missing"

# v11 artifacts installed.
[[ -f "$T/docs/pack/HELP-FRAGMENT.md" ]] \
    && t_pass "2.4 HELP-FRAGMENT.md installed" \
    || t_fail "2.4 HELP-FRAGMENT.md missing"
[[ -f "$T/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
    && t_pass "2.4 HELP-FRAGMENT-TRACKER.md installed" \
    || t_fail "2.4 HELP-FRAGMENT-TRACKER.md missing"
[[ -f "$T/tracker.toml.example" ]] \
    && t_pass "2.4 tracker.toml.example installed" \
    || t_fail "2.4 tracker.toml.example missing"
[[ -f "$T/.github/ISSUE_TEMPLATE/work-item.yml" ]] \
    && t_pass "2.4 issue forms installed" \
    || t_fail "2.4 issue forms missing"
[[ -f "$T/.claude/skills/pack-help/SKILL.md" ]] \
    && t_pass "2.4 .claude pack-help skill installed" \
    || t_fail "2.4 .claude pack-help missing"
[[ -f "$T/.codex/skills/pack-help/SKILL.md" ]] \
    && t_pass "2.4 .codex pack-help skill installed" \
    || t_fail "2.4 .codex pack-help missing"
[[ -f "$T/.gemini/commands/pack-help.toml" ]] \
    && t_pass "2.4 .gemini pack-help command installed" \
    || t_fail "2.4 .gemini pack-help missing"

# DELTA L1: client tracker fragment byte-identical to pack root.
if cmp -s "$REPO_ROOT/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "2.5 HELP-FRAGMENT-TRACKER.md byte-identical to pack root (DELTA L1)"
else
    t_fail "2.5 byte-identity violated"
fi

# Truthful report content.
report=$(cat "$T/.pack-migrate-v10-to-v11/report.md")
assert_contains "2.6 report has H1" "$report" \
    "v10 → v11 migration customization report"
[[ "$report" == *"Total files processed:"* ]] \
    && t_pass "2.6 report has totals line" \
    || t_fail "2.6 report missing totals"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: BD-042 relocation of legacy root-level docs
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: BD-042 relocation ===\n"

T=$(make_v10_target)
# Inject legacy root-level doc that should relocate.
echo "# legacy METHODOLOGY" > "$T/METHODOLOGY.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "legacy root doc" 2>/dev/null

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "3.1 migration with legacy doc rc=0" "0" "$rc"

# After migration: METHODOLOGY.md must NOT be at root (relocated or sidecar).
[[ ! -f "$T/METHODOLOGY.md" ]] \
    && t_pass "3.1 legacy METHODOLOGY.md removed from root" \
    || t_fail "3.1 legacy METHODOLOGY.md still at root"
# Either relocated to docs/pack/ or sidecar with .relocated-from-root.
if [[ -f "$T/docs/pack/METHODOLOGY.md" \
   || -f "$T/METHODOLOGY.md.relocated-from-root" ]]; then
    t_pass "3.1 legacy file relocated"
else
    t_fail "3.1 legacy file disappeared (no relocation)"
fi

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: customization preserved on real-merge case
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: customization preservation ===\n"

T=$(make_v10_target)
# Inject a project customization in CLAUDE.md (project edited from v10
# baseline). The current pack template will likely also differ from v10
# (v11 trinity addenda when BD-081 lands; even now, pack version is v11).
# Hence: real-merge-required → sidecar.
printf '\n## Project customization line\n' >> "$T/CLAUDE.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "project customization" 2>/dev/null

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "4.1 migration with project customization rc=0" "0" "$rc"

# Sidecar OR merged-with-customization (depending on whether pack template
# matches v10): in both cases project content must be retrievable from
# either dest or sidecar. Assert at least one of the two paths preserves
# the customization line.
preserved=0
[[ -f "$T/CLAUDE.md" ]] && grep -q "Project customization line" "$T/CLAUDE.md" && preserved=1
[[ -f "$T/CLAUDE.md.v10-customized" ]] && grep -q "Project customization line" "$T/CLAUDE.md.v10-customized" && preserved=1
[[ "$preserved" -eq 1 ]] \
    && t_pass "4.1 project customization preserved (in dest or sidecar)" \
    || t_fail "4.1 customization lost"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
fi
exit 1
