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

# 2.5b (BD-097 audit B-1) pack-help.sh + lib/detect.sh installed by
# migrator S5; pack-help.sh runs from project root without external deps.
[[ -x "$T/scripts/pack-help.sh" ]] \
    && t_pass "2.5b scripts/pack-help.sh installed + executable" \
    || t_fail "2.5b pack-help.sh missing or not executable"
[[ -f "$T/scripts/lib/detect.sh" ]] \
    && t_pass "2.5b scripts/lib/detect.sh installed" \
    || t_fail "2.5b detect.sh missing"
help_out=$(cd "$T" && bash scripts/pack-help.sh 2>&1) ; help_rc=$?
assert_eq "2.5b pack-help.sh from project root rc=0" "0" "$help_rc"
assert_contains "2.5b pack-help.sh emits client-side header" "$help_out" \
    "Pack v11 — verb reference (this project)"

# Truthful report content.
report=$(cat "$T/.pack-migrate-v10-to-v11/report.md")
assert_contains "2.6 report has H1" "$report" \
    "v10 → v11 migration customization report"
[[ "$report" == *"Total files processed:"* ]] \
    && t_pass "2.6 report has totals line" \
    || t_fail "2.6 report missing totals"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 2b: backup completeness (M1 — gitignored files)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2b: backup includes gitignored files (M1) ===\n"

T=$(make_v10_target)
# Simulate a gitignored .gemini/.env with project-set content.
# .gemini/.env.example is committable; .env is not (.gitignore blocks).
mkdir -p "$T/.gemini"
echo ".env" > "$T/.gitignore"
git -C "$T" add .gitignore >/dev/null
git -C "$T" commit -q -m "ignore .env" 2>/dev/null
echo "AGENT_CAPABILITIES=swift,python" > "$T/.gemini/.env"
# Confirm .env is gitignored (working tree still "clean" by porcelain).
[[ -z "$(git -C "$T" status --porcelain)" ]] \
    && t_pass "2b.0 gitignored .env leaves working tree clean per porcelain" \
    || t_fail "2b.0 .env is not gitignored as expected"

PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" >/dev/null 2>&1 ; rc=$?
assert_eq "2b.1 migration rc=0 with gitignored .env" "0" "$rc"

# Backup must include .gemini/.env (M1 fix — backup the working tree, not
# just HEAD).
[[ -f "$T/.pack-migrate-v10-to-v11-backup/.gemini/.env" ]] \
    && t_pass "2b.2 gitignored .gemini/.env captured in backup" \
    || t_fail "2b.2 backup elided gitignored .gemini/.env (M1 regression)"
# Backup contents match.
if [[ -f "$T/.pack-migrate-v10-to-v11-backup/.gemini/.env" ]] && \
   grep -q "AGENT_CAPABILITIES=swift,python" \
        "$T/.pack-migrate-v10-to-v11-backup/.gemini/.env"; then
    t_pass "2b.3 backup of gitignored file preserves content"
else
    t_fail "2b.3 backup content mismatch"
fi

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
# Group 5: BD-104 IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md rename
# ─────────────────────────────────────────────────────────────────────────
#
# Spec: maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-3.md:235.
# Asserts the four BD-104 migrator branches surfaced by the BD-104 audit
# (AUDIT-BD-104.md, F-1):
#   5.1 happy path — tracked source, dest absent → `git mv` succeeds, dest
#       has source's content, source absent post-rename
#   5.2 source-absent no-op — info line emitted, exit 0, downstream
#       artifacts (S5) still installed
#   5.3 untracked-source `mv` fallback — `git mv` errors with the
#       documented sentinel substring, migrator falls back to plain `mv`
#       and emits "renamed (untracked)" info
#   5.4 collision typed-error contract — both names present, migrator
#       emits ERROR/MESSAGE/→ Run lines per
#       scripts/lib/tracker-errors.sh:25-31 and exits non-zero via
#       fail_stage S4 (rc=24)

printf "\n=== Group 5: BD-104 rename (BD-139 fix-follow) ===\n"

# 5.1 happy path: source committed, dest absent → git mv succeeds.
T=$(make_v10_target)
echo "# project IMPLEMENTATION_PLAN content" > "$T/IMPLEMENTATION_PLAN.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "v10 IMPLEMENTATION_PLAN.md" 2>/dev/null
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
happy_ok=1
[[ "$rc" -ne 0 ]] && happy_ok=0
[[ -f "$T/IMPLEMENTATION-PLAN.md" ]] || happy_ok=0
[[ -f "$T/IMPLEMENTATION_PLAN.md" ]] && happy_ok=0
grep -q "project IMPLEMENTATION_PLAN content" "$T/IMPLEMENTATION-PLAN.md" 2>/dev/null \
    || happy_ok=0
[[ "$out" == *"S4a (rename)"* ]] || happy_ok=0
[[ "$happy_ok" -eq 1 ]] \
    && t_pass "5.1 BD-104 rename happy path: git mv succeeded, content preserved, sub-banner emitted" \
    || t_fail "5.1 BD-104 rename happy path failed (rc=$rc)"
rm -rf "$T"

# 5.2 source absent: info "nothing to rename", exit 0, S5 artifacts still
# install (proves downstream stages run after the no-op).
T=$(make_v10_target)
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
noop_ok=1
[[ "$rc" -ne 0 ]] && noop_ok=0
[[ "$out" == *"nothing to rename"* ]] || noop_ok=0
[[ -f "$T/docs/pack/HELP-FRAGMENT.md" ]] || noop_ok=0
[[ "$noop_ok" -eq 1 ]] \
    && t_pass "5.2 BD-104 source-absent no-op: info emitted, downstream S5 ran" \
    || t_fail "5.2 BD-104 source-absent no-op failed (rc=$rc)"
rm -rf "$T"

# 5.3 untracked-source mv fallback: source exists in working tree but is
# gitignored (not tracked) → `git mv` errors with the documented sentinel
# substring → migrator falls back to plain `mv`. Tests the BD-104 fallback
# branch + the BD-139 F-4 stderr-surfacing info line.
T=$(make_v10_target)
echo "IMPLEMENTATION_PLAN.md" > "$T/.gitignore"
git -C "$T" add .gitignore >/dev/null
git -C "$T" commit -q -m "ignore IMPLEMENTATION_PLAN.md" 2>/dev/null
echo "# untracked plan content" > "$T/IMPLEMENTATION_PLAN.md"
# Confirm working tree clean per porcelain (gitignored counts as untracked-ignored).
[[ -z "$(git -C "$T" status --porcelain)" ]] || t_fail "5.3 setup: gitignore not effective"
out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
fallback_ok=1
[[ "$rc" -ne 0 ]] && fallback_ok=0
[[ -f "$T/IMPLEMENTATION-PLAN.md" ]] || fallback_ok=0
[[ -f "$T/IMPLEMENTATION_PLAN.md" ]] && fallback_ok=0
grep -q "untracked plan content" "$T/IMPLEMENTATION-PLAN.md" 2>/dev/null \
    || fallback_ok=0
[[ "$out" == *"renamed (untracked)"* ]] || fallback_ok=0
# BD-139 F-4: the captured git-mv stderr must be surfaced when the
# fallback branch fires. Match the prefix; the actual git message text
# varies by git version.
[[ "$out" == *"git mv hint"* ]] || fallback_ok=0
[[ "$fallback_ok" -eq 1 ]] \
    && t_pass "5.3 BD-104 untracked-source mv fallback: 'renamed (untracked)' + 'git mv hint' both emitted" \
    || t_fail "5.3 BD-104 untracked fallback failed (rc=$rc)"
rm -rf "$T"

# 5.4 collision: both old and new names present at start. Migrator must
# emit the BD-070 / tracker-errors.sh:25-31 typed-error block to stderr
# and exit via fail_stage S4 (rc=24).
T=$(make_v10_target)
echo "# old name content" > "$T/IMPLEMENTATION_PLAN.md"
echo "# new name content" > "$T/IMPLEMENTATION-PLAN.md"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "both names present" 2>/dev/null
# Capture stdout+stderr separately so we can assert ERROR block went to stderr.
co_out=$(mktemp -t mig-co-out.XXXXXX)
co_err=$(mktemp -t mig-co-err.XXXXXX)
PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" >"$co_out" 2>"$co_err" ; rc=$?
err_content=$(cat "$co_err")
collision_ok=1
# Stage S4 fail_stage exit code is 24 (20 + 4) per migrator-core.sh:80-90.
[[ "$rc" -ne 24 ]] && collision_ok=0
# Typed-error contract per scripts/lib/tracker-errors.sh:25-31:
#   ERROR: <code>
#   MESSAGE: <one-line backend message>
#   <extra context>
#   → Run: <verb>
[[ "$err_content" == *"ERROR: migration-rename-collision"* ]] || collision_ok=0
[[ "$err_content" == *"MESSAGE:"* ]]                          || collision_ok=0
[[ "$err_content" == *"→ Run:"* ]]                            || collision_ok=0
# fail_stage prefix on stderr.
[[ "$err_content" == *"stage S4 failed"* ]] || collision_ok=0
# Both files still present (migrator did not destructively touch either).
[[ -f "$T/IMPLEMENTATION_PLAN.md" ]] || collision_ok=0
[[ -f "$T/IMPLEMENTATION-PLAN.md" ]] || collision_ok=0
[[ "$collision_ok" -eq 1 ]] \
    && t_pass "5.4 BD-104 migration-rename-collision: typed-error contract + fail_stage S4 (rc=24)" \
    || t_fail "5.4 BD-104 collision contract failed (rc=$rc)"
rm -f "$co_out" "$co_err"
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
