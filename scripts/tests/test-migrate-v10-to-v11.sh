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
    local d cli
    d=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-tgt.XXXXXX")
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

    # BD-257 D2 (OI-2): seed ONE pre-existing v10 skill (c-language — shared
    # by v10 and v11) into all three per-CLI homes so the migrate fixture
    # exercises the deletion-honoring case: a v10 skill the client KEEPS must
    # survive the migration untouched (iff-absent additive; asserted at 2.8),
    # and a DIFFERENT shared v10 skill the client DELETED (never seeded) must
    # NOT be re-added by the net-new glob-diff fan-out (asserted at 2.9 —
    # guards Option-b glob-DIFF vs a regress to Option-a glob-ALL).
    for cli in .claude .codex .agents; do
        mkdir -p "$d/$cli/skills/c-language"
        git -C "$REPO_ROOT" show "${V10_TAG:-v10}:project-template/skills/c-language/SKILL.md" \
            > "$d/$cli/skills/c-language/SKILL.md" 2>/dev/null
    done

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
T=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-nopack.XXXXXX")
out=$(unset PACK; bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
assert_eq "1.3 missing PACK rc=10" "10" "$rc"
rm -rf "$T"

# 1.4 not a git repo exits 11.
T=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-nogit.XXXXXX")
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
T=$(mktemp -d "${TMPDIR:-/tmp}/migrate10-bare.XXXXXX")
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
# BD-243 NUCLEAR: the v10→v11 migrator NO LONGER copies the deferred-tracker
# HELP-FRAGMENT-TRACKER.md (deleted). Assert ABSENT.
[[ ! -f "$T/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
    && t_pass "2.4 HELP-FRAGMENT-TRACKER.md NOT installed (deleted, BD-243)" \
    || t_fail "2.4 HELP-FRAGMENT-TRACKER.md unexpectedly installed (should be deleted, BD-243)"
# BD-214: the v10→v11 migrator NO LONGER installs tracker.toml.example
# (tracker deferred; flat-file is the sole supported mode). Assert ABSENT.
[[ ! -f "$T/tracker.toml.example" ]] \
    && t_pass "2.4 tracker.toml.example NOT installed (tracker deferred, BD-214)" \
    || t_fail "2.4 tracker.toml.example unexpectedly installed (should be deferred, BD-214)"
[[ -f "$T/.github/ISSUE_TEMPLATE/work-item.yml" ]] \
    && t_pass "2.4 issue forms installed" \
    || t_fail "2.4 issue forms missing"
# BD-257: the client help skill is /pm-help (renamed from pack-help); the
# migrator fans it out LOOSE to each CLI's skills dir.
[[ -f "$T/.claude/skills/pm-help/SKILL.md" ]] \
    && t_pass "2.4 .claude pm-help skill installed" \
    || t_fail "2.4 .claude pm-help missing"
[[ -f "$T/.codex/skills/pm-help/SKILL.md" ]] \
    && t_pass "2.4 .codex pm-help skill installed" \
    || t_fail "2.4 .codex pm-help missing"
[[ -f "$T/.agents/skills/pm-help/SKILL.md" ]] \
    && t_pass "2.4 .agents pm-help skill installed (Antigravity loose)" \
    || t_fail "2.4 .agents pm-help missing"
# BD-257 no-dual-use: the de-shipped pack-side pack-help skill must NOT be
# fanned out to the client under its old name.
[[ ! -f "$T/.claude/skills/pack-help/SKILL.md" ]] \
    && t_pass "2.4 .claude pack-help skill NOT installed (renamed to pm-help, BD-257)" \
    || t_fail "2.4 .claude pack-help unexpectedly installed (should be pm-help, BD-257)"
# BD-221: the v10→v11 migrator additively installs the Antigravity agent
# plugin bundle (.agents-plugin/optiquity-agents/ —
# _v10_to_v11_install_v11_artifacts). Pin a known bundle agent + plugin.json
# against regression (symmetry with the pack-help-skill assertions above).
[[ -f "$T/.agents-plugin/optiquity-agents/agents/coder.md" ]] \
    && t_pass "2.4 .agents-plugin bundle agent (coder.md) installed (Antigravity bundle)" \
    || t_fail "2.4 .agents-plugin bundle agent coder.md missing"
[[ -f "$T/.agents-plugin/optiquity-agents/plugin.json" ]] \
    && t_pass "2.4 .agents-plugin/optiquity-agents/plugin.json installed" \
    || t_fail "2.4 .agents-plugin/optiquity-agents/plugin.json missing"

# migrate-v10-to-v11.sh S5 install source for the client help fragment is
# the project-template-side file. Test asserts the install copy matches
# the project-template-side source (migrator S5 contract).
if cmp -s "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT.md" "$T/docs/pack/HELP-FRAGMENT.md"; then
    t_pass "2.5 HELP-FRAGMENT.md matches project-template-side install source"
else
    t_fail "2.5 install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT.md)"
fi

# 2.5b (BD-257 no-dual-use) the client's OWN help runner scripts/pm-help.sh
# ships via the project-template/scripts directory sweep; the de-shipped
# pack-side pack-help.sh + lib/detect.sh are NOT copied into the client
# (empty ship-allowlist; dependency-direction-placement conjunct (c)).
[[ -x "$T/scripts/pm-help.sh" ]] \
    && t_pass "2.5b scripts/pm-help.sh installed + executable (sweep)" \
    || t_fail "2.5b pm-help.sh missing or not executable"
[[ ! -f "$T/scripts/pack-help.sh" ]] \
    && t_pass "2.5b scripts/pack-help.sh NOT installed (de-shipped, BD-257)" \
    || t_fail "2.5b pack-help.sh unexpectedly installed (should be de-shipped, BD-257)"
[[ ! -f "$T/scripts/lib/detect.sh" ]] \
    && t_pass "2.5b scripts/lib/detect.sh NOT installed (de-shipped, BD-257)" \
    || t_fail "2.5b detect.sh unexpectedly installed (should be de-shipped, BD-257)"
help_out=$(cd "$T" && bash scripts/pm-help.sh 2>&1) ; help_rc=$?
assert_eq "2.5b pm-help.sh from project root rc=0" "0" "$help_rc"
assert_contains "2.5b pm-help.sh emits client-side header" "$help_out" \
    "Pack v11 — verb reference (this project)"

# 2.5c (BD-263): the v10→v11 migrator installs the groupings per-entry
# stream skeleton (fourth stream in the BD-167 skeleton loop) AND seeds
# the empty groupings `_toc.md` (the F10 fold — the decompose sub-op
# covers the three v10-monolith streams only; v10 has no groupings
# monolith, so without the seed the stream's sole readable index would
# be missing on the migrator path).
[[ -f "$T/docs/project/groupings/_rules.md" ]] \
    && t_pass "2.5c groupings/_rules.md installed by migrator skeleton loop" \
    || t_fail "2.5c groupings/_rules.md missing after migration"
[[ -f "$T/docs/project/groupings/_intro.md" ]] \
    && t_pass "2.5c groupings/_intro.md installed by migrator skeleton loop" \
    || t_fail "2.5c groupings/_intro.md missing after migration"
if cmp -s "$REPO_ROOT/project-template/docs/project/groupings/_rules.md" \
        "$T/docs/project/groupings/_rules.md"; then
    t_pass "2.5c installed groupings/_rules.md matches the pack template source"
else
    t_fail "2.5c installed groupings/_rules.md differs from the pack template source"
fi
if [[ -f "$T/docs/project/groupings/_toc.md" ]] \
   && grep -q -F '(empty — no entries)' "$T/docs/project/groupings/_toc.md"; then
    t_pass "2.5c groupings/_toc.md seeded with '(empty — no entries)' payload (F10 fold)"
else
    t_fail "2.5c groupings/_toc.md missing or missing empty-seed payload after migration"
fi
# Manifest regenerated with the 4th immutable row; the shipped
# verify-immutable.sh runs clean against the migrated tree.
[[ -f "$T/docs/project/immutable-manifest.txt" ]] \
    && grep -q '^docs/project/groupings/_rules.md ' "$T/docs/project/immutable-manifest.txt" \
    && t_pass "2.5c immutable-manifest carries the groupings/_rules.md row (4-row set)" \
    || t_fail "2.5c immutable-manifest missing the groupings/_rules.md row"
mig_manifest_rows=$(grep -c -v -e '^#' -e '^$' "$T/docs/project/immutable-manifest.txt" 2>/dev/null | tr -d ' ')
assert_eq "2.5c immutable-manifest has 4 data rows (BD-263 3→4)" "4" "$mig_manifest_rows"
( cd "$T" && bash scripts/verify-immutable.sh ) >/dev/null 2>&1 ; mig_vi_rc=$?
assert_eq "2.5c installed verify-immutable.sh rc=0 on migrated tree" "0" "$mig_vi_rc"

# Truthful report content.
report=$(cat "$T/.pack-migrate-v10-to-v11/report.md")
assert_contains "2.6 report has H1" "$report" \
    "v10 → v11 migration customization report"
[[ "$report" == *"Total files processed:"* ]] \
    && t_pass "2.6 report has totals line" \
    || t_fail "2.6 report missing totals"

# 2.7 (BD-257 D2) every NET-NEW-since-v10 skill lands in all three per-CLI
# homes after the migration. Self-maintaining expected set: net-new =
# (v11 git index) minus (v10 tag), via `comm -13` — never a hardcoded list.
# This is the migrate-path regression gate: RED against the pre-D1 migrator
# (its hardcoded 6-skill loop dropped 9 net-new skills → 27 missing files)
# and GREEN after D1. declare-verify-backing: asserts the FILE lands.
migrate_netnew_miss=0
migrate_netnew_total=0
while IFS= read -r sk; do
    [[ -n "$sk" ]] || continue
    migrate_netnew_total=$((migrate_netnew_total + 1))
    for cli in claude codex agents; do
        if [[ ! -f "$T/.$cli/skills/$sk/SKILL.md" ]]; then
            t_fail "2.7 net-new drop: .$cli/skills/$sk/SKILL.md MISSING"
            migrate_netnew_miss=$((migrate_netnew_miss + 1))
        fi
    done
done < <(comm -13 \
    <(git -C "$REPO_ROOT" ls-tree -r --name-only "${V10_TAG:-v10}" -- project-template/skills/ \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL.md$#\1#p' | sort -u) \
    <(git -C "$REPO_ROOT" ls-files 'project-template/skills/*/SKILL.md' \
        | sed 's#project-template/skills/##; s#/SKILL.md##' | sort))
[[ "$migrate_netnew_miss" -eq 0 && "$migrate_netnew_total" -gt 0 ]] \
    && t_pass "2.7 all $migrate_netnew_total net-new-since-v10 skills present in .claude/.codex/.agents after migration (self-maintaining set)" \
    || t_fail "2.7 $migrate_netnew_miss per-CLI net-new skill file(s) MISSING after migration (net-new total=$migrate_netnew_total)"

# 2.8 (BD-257 D2 / OI-2) the seeded v10 skill the client KEPT (c-language)
# survives the migration byte-identical in all three homes — the net-new
# gate skips it (it existed at v10) and iff-absent never clobbers it.
kept_ok=1
for cli in claude codex agents; do
    [[ -f "$T/.$cli/skills/c-language/SKILL.md" ]] || kept_ok=0
done
if [[ "$kept_ok" -eq 1 ]] \
   && cmp -s <(git -C "$REPO_ROOT" show "${V10_TAG:-v10}:project-template/skills/c-language/SKILL.md") \
             "$T/.claude/skills/c-language/SKILL.md"; then
    t_pass "2.8 kept v10 skill (c-language) preserved byte-identical in all 3 homes (iff-absent additive)"
else
    t_fail "2.8 kept v10 skill (c-language) altered or missing after migration"
fi

# 2.9 (BD-257 D2 / OI-2) a DIFFERENT shared v10∩v11 skill the client DELETED
# (never seeded → absent) is NOT re-added by the migration: the net-new gate
# skips it because it existed at the v10 baseline. Under an Option-a glob-ALL
# fan-out this skill WOULD be re-added (a v11 skill, absent → add); Option-b
# glob-DIFF honors the client deletion (project-deleted-pack-kept semantic).
# The probe skill is derived at runtime (first shared v10∩v11 skill that is
# not the seeded c-language), keeping the guard self-maintaining.
deleted_skill=$(comm -12 \
    <(git -C "$REPO_ROOT" ls-tree -r --name-only "${V10_TAG:-v10}" -- project-template/skills/ \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL.md$#\1#p' | sort -u) \
    <(git -C "$REPO_ROOT" ls-files 'project-template/skills/*/SKILL.md' \
        | sed 's#project-template/skills/##; s#/SKILL.md##' | sort) \
    | grep -v -x 'c-language' | head -1)
if [[ -z "$deleted_skill" ]]; then
    t_fail "2.9 no shared v10∩v11 probe skill found (fixture derivation failed)"
else
    del_ok=1
    for cli in claude codex agents; do
        [[ -e "$T/.$cli/skills/$deleted_skill" ]] && del_ok=0
    done
    [[ "$del_ok" -eq 1 ]] \
        && t_pass "2.9 migrate honors client-deleted v10 skill: '$deleted_skill' (shared v10∩v11, unseeded) NOT re-added (glob-DIFF)" \
        || t_fail "2.9 migrate wrongly re-added client-deleted v10 skill '$deleted_skill' (glob-ALL regression)"
fi

# 2.10 (BD-136 POQ-1 no-sidecar LOCK — the previously-missed migrator encoding
# surface, per the POQ-1 arch doc §4.3 item 1 + §4.4). A NORMAL non-customized
# v10→v11 trinity migration (base==ours for all three; every
# `## [CONDITIONAL]` section is the untouched v10 default) MUST adopt the pack
# canonical via the BASE-aware M1 markerless fallback → pack-update-applied →
# NO trinity `.v10-customized` sidecar, NO
# customization-detected-needs-reconciliation disposition, and therefore NO
# BD-095 pause. The full manifest install completes (HELP-FRAGMENT / skills /
# groupings — asserted at 2.4 / 2.5c / 2.7 above, which only run BECAUSE no
# pause fired). declare-verify-backing: this lock is RED against a BASE-BLIND
# M1 (the original C1 defect fired on ANY `[CONDITIONAL]` heading in OURS →
# spurious sidecar → the BD-095 pause → the POQ-1 halt) and GREEN under the
# shipped BASE-aware M1 (marker-preserve.sh `_mp_conditional_needs_reconciliation`
# stays silent when base==ours). It would have caught the original halt.
[[ ! -f "$T/CLAUDE.md.v10-customized" \
   && ! -f "$T/AGENTS.md.v10-customized" \
   && ! -f "$T/GEMINI.md.v10-customized" ]] \
    && t_pass "2.10 no trinity .v10-customized sidecar on the non-customized path (POQ-1 lock)" \
    || t_fail "2.10 spurious trinity sidecar on the non-customized path (BASE-blind M1 regression)"
[[ ! -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused" ]] \
    && t_pass "2.10 no BD-095 pause on the non-customized path (install completed, POQ-1 lock)" \
    || t_fail "2.10 spurious BD-095 pause on the non-customized path (BASE-blind M1 regression)"
# Positive lock: every trinity row resolves to the clean adopt — ZERO carry the
# needs-reconciliation disposition.
trinity_needs_recon=$(awk -F'\t' \
    '$2=="trinity" && $1=="customization-detected-needs-reconciliation"{n++} END{print n+0}' \
    "$T/.pack-migrate-v10-to-v11/dispositions.tsv")
assert_eq "2.10 zero trinity needs-reconciliation dispositions (clean pack adopt)" \
    "0" "$trinity_needs_recon"

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
# Group 2c: BD-136 POQ-1 reserved case — a CUSTOMIZED [CONDITIONAL] body still
# fails loud (sidecar + L-9 keep-vs-delete note) and hits the intentional
# BD-095 pause (the human-reconciliation flow the user chose to KEEP).
# ─────────────────────────────────────────────────────────────────────────
#
# The BASE-aware M1 (marker-preserve.sh `_mp_conditional_needs_reconciliation`,
# POQ-1 fix) stays SILENT on the non-customized path (Group 2 / 2.10 lock) but
# MUST still FIRE when a client CUSTOMIZED the body under a `## [CONDITIONAL] X`
# heading (base != ours for that optional section). This is the reserved
# genuine-reconciliation case: THEIRS→dest, full OURS→`.v10-customized` sidecar
# (no silent loss — BD-136 L-8), the L-9 keep-vs-delete disposition note, and
# the BD-095 pause-before-S4 halts the install until `--resume`.
# declare-verify-backing: the suite previously had NO migrator-level test for
# this reserved case; this group is the end-to-end proof it survives the POQ-1
# refinement (a complement to the 2.10 no-sidecar lock).

printf "\n=== Group 2c: BD-136 POQ-1 customized [CONDITIONAL] body → sidecar + pause ===\n"

T=$(make_v10_target)
# Customize the body under the FIRST `## [CONDITIONAL] X` heading in CLAUDE.md
# (insert a unique line immediately after the heading, INSIDE that section
# body). The heading text is discovered at runtime (never hard-coded) so the
# fixture stays valid if the v10 canonical's optional-section titles drift.
# awk insertion is onetrueawk/gawk/mawk safe (no gensub / interval expressions).
cond_custom_line="POQ1-CONDITIONAL-CUSTOM-$$-project-edited-optional-section-body"
awk -v cust="$cond_custom_line" '
  BEGIN{ done=0 }
  { print }
  (!done && ($0 ~ /^## / || $0 ~ /^### /) && $0 ~ /\[CONDITIONAL\]/) { print cust; done=1 }
' "$T/CLAUDE.md" > "$T/CLAUDE.md.poq1tmp" && mv "$T/CLAUDE.md.poq1tmp" "$T/CLAUDE.md"
# Guard against a vacuous pass: confirm the fixture actually injected the edit
# (i.e. the v10 CLAUDE.md carried a [CONDITIONAL] heading to customize).
grep -q "$cond_custom_line" "$T/CLAUDE.md" \
    && t_pass "2c.0 fixture customized a [CONDITIONAL] section body in CLAUDE.md" \
    || t_fail "2c.0 fixture failed to inject a [CONDITIONAL] customization (no [CONDITIONAL] heading?)"
git -C "$T" add -A >/dev/null
git -C "$T" commit -q -m "customize [CONDITIONAL] body" 2>/dev/null

out=$(PACK="$REPO_ROOT" bash "$MIGRATE_SH" "$T" 2>&1) ; rc=$?
# The BD-095 pause is a CLEAN pause (exit 0), not a hard error.
assert_eq "2c.1 migration rc=0 (clean BD-095 pause)" "0" "$rc"

# (a) the trinity .v10-customized sidecar exists AND preserves the client's
#     customized body byte-for-byte (no silent loss — L-8).
[[ -f "$T/CLAUDE.md.v10-customized" ]] \
    && t_pass "2c.2 CLAUDE.md.v10-customized sidecar written" \
    || t_fail "2c.2 CLAUDE.md.v10-customized sidecar missing"
grep -q "$cond_custom_line" "$T/CLAUDE.md.v10-customized" 2>/dev/null \
    && t_pass "2c.3 sidecar preserves the customized [CONDITIONAL] body (no silent loss, L-8)" \
    || t_fail "2c.3 sidecar dropped the customized [CONDITIONAL] body"

# (b)+(c) dispositions.tsv records needs-reconciliation for the trinity AND
#     carries the L-9 [CONDITIONAL] keep-vs-delete message in the notes column.
cond_row=$(awk -F'\t' '$2=="trinity" && $3=="CLAUDE.md"{print}' \
    "$T/.pack-migrate-v10-to-v11/dispositions.tsv")
assert_contains "2c.4 trinity disposition is customization-detected-needs-reconciliation" \
    "$cond_row" "customization-detected-needs-reconciliation"
assert_contains "2c.5 disposition note carries the L-9 [CONDITIONAL] keep-vs-delete message" \
    "$cond_row" "heading whose body you customized"

# (d) the BD-095 pause-before-S4 fired.
[[ -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused" ]] \
    && t_pass "2c.6 BD-095 stage-S3.paused sentinel present (intentional pause fired)" \
    || t_fail "2c.6 BD-095 pause did not fire on the customized [CONDITIONAL] body"
# The pause halts BEFORE the S4/S5 install (load-bearing: it gates the unrelated
# install until the human reconciles) — HELP-FRAGMENT is not yet installed.
[[ ! -f "$T/docs/pack/HELP-FRAGMENT.md" ]] \
    && t_pass "2c.7 install paused before S4/S5 (HELP-FRAGMENT not yet installed)" \
    || t_fail "2c.7 install ran past the BD-095 pause (pause not load-bearing)"

# BD-282 C5: the pause reads as a calm "Migration paused — requires attention"
# with the three consequence-labelled options + copy-paste per-sidecar commands,
# and NEVER the old "migration failed" wording. These assertions read `$out`
# from the `2>&1` capture at the TOP of Group 2c (the combined stdout+stderr) —
# do NOT drop that redirect or the framework trap's stderr pause-note (and the
# say-emitted block) stop being visible to the test.
assert_contains "2c.8 pause header reads 'Migration paused'" \
    "$out" "Migration paused"
assert_contains "2c.9 pause header reads 'requires attention'" \
    "$out" "requires attention"
assert_contains "2c.10 option 1 labelled 'Accept the pack'" \
    "$out" "Accept the pack"
assert_contains "2c.11 option 2 labelled 'Keep your customization'" \
    "$out" "Keep your customization"
# BD-287 (§2.1): the trinity option-3 prose now points at the section-aware
# resolve-merge-conflicts skill (or a hand-fold per the pre-reconcile guide),
# replacing the old class-blind "Merge by hand" label.
assert_contains "2c.12 option 3 folds via the resolve-merge-conflicts skill (section-aware)" \
    "$out" "resolve-merge-conflicts skill"
assert_contains "2c.12b option 3 also offers a hand-fold per the pre-reconcile guide" \
    "$out" "pre-reconcile guide"
assert_contains "2c.13 emits a per-sidecar keep-yours command (mv '...')" \
    "$out" "mv '"
assert_contains "2c.14 emits a per-sidecar merge command (touch '...'.resolved)" \
    "$out" ".resolved"
assert_contains "2c.15 emits the --resume command to finish" \
    "$out" "--resume"
[[ "$out" != *"migration failed"* ]] \
    && t_pass "2c.16 pause is NOT worded as a failure (no 'migration failed')" \
    || t_fail "2c.16 pause leaked the old 'migration failed' wording"

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
co_out=$(mktemp "${TMPDIR:-/tmp}/mig-co-out.XXXXXX")
co_err=$(mktemp "${TMPDIR:-/tmp}/mig-co-err.XXXXXX")
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
# Group 6: BD-221 corrected agent-migration model — lift Gemini x- customs
# INTO the Antigravity bundle, then retire `.gemini/` to a backup holding
# dir (move-not-delete).
# ─────────────────────────────────────────────────────────────────────────
#
# A client-customized departing `.gemini/` tree (x- custom agent +
# project-edited config with no Antigravity target) must be handled in two
# steps, in order:
#   1. `_v10_to_v11_lift_gemini_customs_to_bundle` copies each x- custom
#      INTO `.agents-plugin/optiquity-agents/agents/` (it becomes a live
#      Antigravity agent — frozen model #2/#3).
#   2. `_v10_to_v11_retire_gemini` MOVES the whole departing `.gemini/` tree
#      to a root-level `gemini-retired-docs/` holding dir as a BACKUP,
#      NEVER deleting it.
#
# This unit exercises BOTH helpers directly (sourcing the migrator under the
# source-guard) in the SAME production order, so the "custom landed in the
# bundle" assertion runs against a state where the lift actually happened
# (C-1 reconciliation: a bundle-custom assertion against the retire helper
# in isolation would fail — the lift is a SEPARATE step that must run
# first). It is independent of the full-migration Phase-A validate-pack gate.

printf "\n=== Group 6: BD-221 lift-into-bundle + gemini-retired-docs backup ===\n"

G6=$(mktemp -d "${TMPDIR:-/tmp}/mig-retire.XXXXXX")
G6T="$G6/proj"
# Customized departing .gemini tree: an x- custom agent, a project-edited
# env, and a legacy command. None has a v11 Antigravity target. Pre-create
# the Antigravity bundle agents dir (laid down by the install step in a real
# migration; the lift target must exist) with the 16 pack agents seeded.
mkdir -p "$G6T/.gemini/agents" "$G6T/.gemini/commands"
mkdir -p "$G6T/.agents-plugin/optiquity-agents/agents"
echo "x-custom agent body" > "$G6T/.gemini/agents/x-ot-domain.md"
echo "AGENT_CAPABILITIES=swift,python" > "$G6T/.gemini/.env"
echo "[meta]" > "$G6T/.gemini/commands/pack-help.toml"
# Seed one pre-existing pack bundle agent (so the lift's non-clobber +
# the bundle landscape is realistic — the lift only touches x- customs).
echo "pack coder body" > "$G6T/.agents-plugin/optiquity-agents/agents/coder.md"

# Run lift THEN retire in a subshell that sources the migrator (source-guard
# skips the executable dispatch) and sets the minimal runtime state the
# helpers need. Production order: lift first, retire second.
(
    export PACK="$REPO_ROOT"
    # shellcheck disable=SC1090
    source "$MIGRATE_SH"
    _MIGRATOR_TARGET="$G6T"
    _v10_to_v11_lift_gemini_customs_to_bundle
    _v10_to_v11_retire_gemini
) >/dev/null 2>&1

# (a) the x- custom was LIFTED into the Antigravity bundle (live agent).
[[ -f "$G6T/.agents-plugin/optiquity-agents/agents/x-ot-domain.md" ]] \
    && t_pass "6.1 x- custom lifted into Antigravity bundle (.agents-plugin/optiquity-agents/agents/)" \
    || t_fail "6.1 x- custom NOT lifted into the Antigravity bundle"
# (a-ii) the lift did NOT clobber the pre-existing pack bundle agent.
if [[ -f "$G6T/.agents-plugin/optiquity-agents/agents/coder.md" ]] && \
   grep -q "pack coder body" \
        "$G6T/.agents-plugin/optiquity-agents/agents/coder.md"; then
    t_pass "6.2 lift left the pre-existing pack bundle agent untouched"
else
    t_fail "6.2 lift clobbered the pre-existing pack bundle agent"
fi
# (b) holding dir created + populated (the BACKUP copy).
[[ -d "$G6T/gemini-retired-docs" ]] \
    && t_pass "6.3 gemini-retired-docs/ backup holding dir created" \
    || t_fail "6.3 gemini-retired-docs/ not created"
[[ -f "$G6T/gemini-retired-docs/.gemini/agents/x-ot-domain.md" ]] \
    && t_pass "6.4 customized x- agent backed up in holding dir" \
    || t_fail "6.4 customized x- agent NOT backed up"
[[ -f "$G6T/gemini-retired-docs/.gemini/.env" ]] \
    && t_pass "6.5 project-edited .env backed up in holding dir" \
    || t_fail "6.5 project-edited .env NOT backed up"
# (c) never-delete: content faithful.
if [[ -f "$G6T/gemini-retired-docs/.gemini/.env" ]] && \
   grep -q "AGENT_CAPABILITIES=swift,python" \
        "$G6T/gemini-retired-docs/.gemini/.env"; then
    t_pass "6.6 retired .env content faithful (never-delete guarantee)"
else
    t_fail "6.6 retired .env content lost"
fi
# (d) original departing .gemini removed from its original location (moved,
#     not copied) — but the content survives in the holding dir (above).
[[ ! -d "$G6T/.gemini" ]] \
    && t_pass "6.7 original .gemini/ relocated (no stray legacy tree)" \
    || t_fail "6.7 original .gemini/ still present after retirement"

# Idempotency: a second lift+retire run with NO .gemini present is a clean
# no-op (the lift finds the custom already in the bundle; the retire finds
# no .gemini/).
(
    export PACK="$REPO_ROOT"
    # shellcheck disable=SC1090
    source "$MIGRATE_SH"
    _MIGRATOR_TARGET="$G6T"
    _v10_to_v11_lift_gemini_customs_to_bundle
    _v10_to_v11_retire_gemini
) >/dev/null 2>&1
g6_rc=$?
[[ "$g6_rc" -eq 0 ]] \
    && t_pass "6.8 idempotent no-op when no .gemini present (rc=0)" \
    || t_fail "6.8 second run not a clean no-op (rc=$g6_rc)"
# Idempotent lift did not duplicate or corrupt the bundle custom.
if [[ -f "$G6T/.agents-plugin/optiquity-agents/agents/x-ot-domain.md" ]] && \
   grep -q "x-custom agent body" \
        "$G6T/.agents-plugin/optiquity-agents/agents/x-ot-domain.md"; then
    t_pass "6.9 idempotent: bundle custom intact after second run"
else
    t_fail "6.9 idempotent: bundle custom corrupted/lost after second run"
fi

rm -rf "$G6"

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
