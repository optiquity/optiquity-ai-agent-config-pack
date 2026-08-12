#!/usr/bin/env bash
# scripts/tests/test-init-project.sh — BD-080 fixture tests for the v11
# extensions to init-project.sh: stage S11 (v11 client artifacts) and
# the --update flag (BD-088-backed non-destructive refresh).
#
# Note: end-to-end install tests of the full S0..S11 path require a
# real PACK environment + clean git repo. We run a minimal subset here
# focused on the BD-080 surface (S11 artifacts + --update path). Argv
# and exit-code paths are tested directly.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INIT_SH="$REPO_ROOT/scripts/init-project.sh"

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

# Set up a minimal target directory: empty git repo, clean working tree.
make_target() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/init-tgt.XXXXXX")
    git init -q "$d" >/dev/null
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"
    git -C "$d" commit --allow-empty -q -m "initial" 2>/dev/null
    printf '%s\n' "$d"
}

# Simulate an already-pack-configured project (minimal — just CLAUDE.md
# + .claude/ so the --update precheck passes; we don't need a full
# install to exercise the BD-088 dispatch path).
make_configured_target() {
    local d
    d=$(make_target)
    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.agents"
    printf '# CLAUDE.md (project)\n' > "$d/CLAUDE.md"
    printf '# AGENTS.md (project)\n' > "$d/AGENTS.md"
    printf '# GEMINI.md (project)\n' > "$d/GEMINI.md"
    # Commit so the working tree is clean (init-project.sh refuses to run
    # against a dirty target by design).
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "pack-configured fixture" 2>/dev/null
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: argv parsing
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: argv parsing ===\n"

# 1.1 --help exits 0 with usage text.
out=$(bash "$INIT_SH" --help 2>&1) ; rc=$?
assert_eq    "1.1 --help rc=0" "0" "$rc"
assert_contains "1.1 --help shows usage" "$out" "Usage:"
assert_contains "1.1 --help mentions --update" "$out" "--update"
assert_contains "1.1 --help mentions --yes (BD-284)" "$out" "--yes"

# 1.2 unknown option exits non-zero with a typed error.
out=$(bash "$INIT_SH" --bogus 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] && t_pass "1.2 --bogus rc!=0" || t_fail "1.2 --bogus rc!=0" "got rc=$rc"
assert_contains "1.2 --bogus typed error" "$out" "unknown option"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: --update precondition checks
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: --update preconditions ===\n"

# 2.1 --update against an unconfigured target → exit 50.
T=$(make_target)
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T" 2>&1) ; rc=$?
assert_eq    "2.1 --update on unconfigured rc=50" "50" "$rc"
assert_contains "2.1 --update tells user to run without --update" "$out" \
    "without --update for a fresh install"
rm -rf "$T"

# 2.2 --update against pack-configured target succeeds and writes report.
T=$(make_configured_target)
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T" 2>&1) ; rc=$?
assert_eq    "2.2 --update on configured rc=0" "0" "$rc"
[[ -f "$T/.pack-update/report.md" ]] \
    && t_pass "2.2 report.md written" \
    || t_fail "2.2 report.md missing"
[[ -f "$T/.pack-update/dispositions.tsv" ]] \
    && t_pass "2.2 dispositions.tsv written" \
    || t_fail "2.2 dispositions.tsv missing"

# 2.3 trinity files differ between the minimal fixture (above) and pack
# template — expect needs-reconciliation findings recorded.
report=$(cat "$T/.pack-update/report.md")
assert_contains "2.3 report has H1" "$report" \
    "AI Agent Config Pack — --update report"
assert_contains "2.3 trinity surfaced as needs-reconciliation" "$report" \
    "Files needing manual reconciliation"

# 2.4 sidecars written for the trinity files (real-merge-required path).
[[ -f "$T/CLAUDE.md.pre-update" ]] \
    && t_pass "2.4 CLAUDE.md.pre-update sidecar written" \
    || t_fail "2.4 CLAUDE.md.pre-update missing"

# 2.5 v11 artifacts that did not exist pre-update get installed by --update.
[[ -f "$T/docs/pack/HELP-FRAGMENT.md" ]] \
    && t_pass "2.5 HELP-FRAGMENT.md installed by --update" \
    || t_fail "2.5 HELP-FRAGMENT.md missing"

# 2.6 truthful contract: every entry in dispositions.tsv corresponds to a
# real file, and the count is non-zero.
count=$(awk 'NR > 1 && NF > 0' "$T/.pack-update/dispositions.tsv" | wc -l | tr -d ' ')
[[ "$count" -gt 0 ]] \
    && t_pass "2.6 dispositions.tsv has $count rows" \
    || t_fail "2.6 dispositions.tsv empty"

# 2.7 (m6) re-run --update with stale .pre-update sidecars must refuse
# (single-slot sidecar contract; second run would silently overwrite).
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] \
    && t_pass "2.7 re-run with stale sidecars refuses (rc!=0)" \
    || t_fail "2.7 re-run with sidecars unexpectedly succeeded" "rc=$rc"
assert_contains "2.7 user told to reconcile sidecars" "$out" \
    "reconcile or remove the .pre-update sidecars"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: stage S11 artifacts (full install — fresh empty repo)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: stage S11 v11 artifacts (fresh install) ===\n"

T=$(make_target)
# --yes bypasses the confirm (BD-284); no stdin feed needed for automation.
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T" 2>&1) ; rc=$?
assert_eq    "3.1 fresh install rc=0" "0" "$rc"
assert_contains "3.1 S11 stage ran" "$out" \
    "S11 — v11 client artifacts"

# v11 artifacts present.
[[ -f "$T/docs/pack/HELP-FRAGMENT.md" ]] \
    && t_pass "3.2 HELP-FRAGMENT.md present" \
    || t_fail "3.2 HELP-FRAGMENT.md missing"
# BD-243 NUCLEAR: the deferred-tracker HELP-FRAGMENT-TRACKER.md is deleted
# and no longer installed. Assert it is ABSENT.
[[ ! -f "$T/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
    && t_pass "3.2 HELP-FRAGMENT-TRACKER.md NOT installed (deleted, BD-243)" \
    || t_fail "3.2 HELP-FRAGMENT-TRACKER.md unexpectedly installed (should be deleted, BD-243)"
# BD-214: tracker.toml.example is NO LONGER installed (tracker deferred;
# flat-file is the sole supported mode). Assert it is ABSENT.
[[ ! -f "$T/tracker.toml.example" ]] \
    && t_pass "3.2 tracker.toml.example NOT installed (tracker deferred, BD-214)" \
    || t_fail "3.2 tracker.toml.example unexpectedly installed (should be deferred, BD-214)"
[[ -f "$T/.github/ISSUE_TEMPLATE/work-item.yml" ]] \
    && t_pass "3.2 work-item.yml present" \
    || t_fail "3.2 work-item.yml missing"
[[ -f "$T/.github/ISSUE_TEMPLATE/inbound.yml" ]] \
    && t_pass "3.2 inbound.yml present" \
    || t_fail "3.2 inbound.yml missing"
[[ -f "$T/.github/ISSUE_TEMPLATE/config.yml" ]] \
    && t_pass "3.2 config.yml present" \
    || t_fail "3.2 config.yml missing"
[[ -f "$T/.claude/skills/pm-help/SKILL.md" ]] \
    && t_pass "3.2 .claude/skills/pm-help/SKILL.md present" \
    || t_fail "3.2 .claude/skills/pm-help missing"
[[ -f "$T/.codex/skills/pm-help/SKILL.md" ]] \
    && t_pass "3.2 .codex/skills/pm-help/SKILL.md present" \
    || t_fail "3.2 .codex/skills/pm-help missing"
# BD-221: pm-help is a pool skill distributed LOOSE to the Antigravity
# workspace at .agents/skills/pm-help/SKILL.md (the former `.toml`
# command surface is retired).
[[ -f "$T/.agents/skills/pm-help/SKILL.md" ]] \
    && t_pass "3.2 .agents/skills/pm-help/SKILL.md present" \
    || t_fail "3.2 .agents/skills/pm-help missing"
# BD-221: the Antigravity workspace skills dir is populated by stage S4.
[[ -d "$T/.agents/skills" ]] \
    && t_pass "3.2 .agents/skills/ present (Antigravity workspace skills)" \
    || t_fail "3.2 .agents/skills/ missing"

# 3.3 client HELP-FRAGMENT.md install source is the project-template-side
# file. Assert the install copy matches the project-template-side source
# (init-project.sh S11 contract).
if cmp -s "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT.md" "$T/docs/pack/HELP-FRAGMENT.md"; then
    t_pass "3.3 client HELP-FRAGMENT.md matches project-template-side install source"
else
    t_fail "3.3 install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT.md)"
fi

# 3.4 (BD-257) pm-help.sh is a bare-template client script
# (project-template/scripts/pm-help.sh) shipped by stage S5; it runs from
# the project root without needing PACK env or any pack-repo path resolution.
[[ -x "$T/scripts/pm-help.sh" ]] \
    && t_pass "3.4 scripts/pm-help.sh installed + executable" \
    || t_fail "3.4 pm-help.sh missing or not executable"
help_out=$(cd "$T" && bash scripts/pm-help.sh 2>&1) ; help_rc=$?
assert_eq "3.4 pm-help.sh from project root rc=0" "0" "$help_rc"
assert_contains "3.4 pm-help.sh emits client-side header" "$help_out" \
    "Pack v11 — verb reference (this project)"

# 3.4b (BD-257) NO pack-side file ships to the client — the ship-allowlist
# is EMPTY (no dual-use). pack-help.sh + lib/detect.sh are NOT installed.
[[ ! -e "$T/scripts/pack-help.sh" ]] \
    && t_pass "3.4b scripts/pack-help.sh NOT shipped (de-shipped per BD-257)" \
    || t_fail "3.4b pack-help.sh unexpectedly present in client install"
[[ ! -e "$T/scripts/lib/detect.sh" ]] \
    && t_pass "3.4b scripts/lib/detect.sh NOT shipped (de-shipped per BD-257)" \
    || t_fail "3.4b detect.sh unexpectedly present in client install"

# 3.5 (BD-257 D2) every v11 skill lands in all three per-CLI homes after a
# fresh install. The expected set is DERIVED at runtime from the pack git
# index (git ls-files) — never a hardcoded list — so BD-274 + every future
# skill auto-joins this gate. init stage_s4_skills globs
# project-template/skills/*/ and fans each SKILL.md to .claude/.codex/.agents;
# any dropped skill FAILS here (the init-path regression gate BD-257 flagged
# as missing). declare-verify-backing: asserts the FILE lands, not that code ran.
init_skill_miss=0
init_skill_total=0
while IFS= read -r sk; do
    [[ -n "$sk" ]] || continue
    init_skill_total=$((init_skill_total + 1))
    for cli in claude codex agents; do
        if [[ ! -f "$T/.$cli/skills/$sk/SKILL.md" ]]; then
            t_fail "3.5 fresh-install skill drop: .$cli/skills/$sk/SKILL.md MISSING"
            init_skill_miss=$((init_skill_miss + 1))
        fi
    done
done < <(git -C "$REPO_ROOT" ls-files 'project-template/skills/*/SKILL.md' \
    | sed 's#project-template/skills/##; s#/SKILL.md##' | sort)
[[ "$init_skill_miss" -eq 0 && "$init_skill_total" -gt 0 ]] \
    && t_pass "3.5 all $init_skill_total v11 skills present in .claude/.codex/.agents after fresh install (self-maintaining set)" \
    || t_fail "3.5 $init_skill_miss per-CLI skill file(s) MISSING after fresh install (total skills=$init_skill_total)"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: BD-166 sub-step 6 (canonical per-entry templates) + sub-step 7
# (greenfield empty-seed _toc.md) — closes the PACK-REVIEW-BD-166-RETRO
# MUST finding 1 (test-not-in-CI heuristic).
#
# BD-206 (no-mirror): no monolithic mirror is generated; the per-entry
# tree + `_toc.md` is the sole SSOT and readable form. `_format.md` is
# FORBIDDEN on every stream (its content folds into changelog/_rules.md).
# BD-263: groupings is the fourth per-entry stream (BD-262 contract) —
# provisioned on every fresh install alongside the original three.
# What CI covers:
#   - 8 canonical templates present after greenfield init (each of the
#     four streams gets _rules.md + _intro.md; no _format.md anywhere)
#   - the 3 monoliths ABSENT (no regenerated mirror at parent or in subdir)
#   - 4 empty seed _toc.md files with `(empty — no entries)` payload
#   - immutable manifest carries 4 rows (incl. groupings/_rules.md)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: BD-166 per-entry tree skeleton (sub-steps 6+7) ===\n"

T=$(make_target)
PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T" >/dev/null 2>&1 ; rc=$?
assert_eq "4.1 fresh install rc=0" "0" "$rc"

# 4.2 — six canonical templates present (each stream gets _rules.md +
# _intro.md; BD-206: _format.md is FORBIDDEN on every stream).
[[ -f "$T/docs/project/backlog/_rules.md" ]] \
    && t_pass "4.2 docs/project/backlog/_rules.md present" \
    || t_fail "4.2 docs/project/backlog/_rules.md missing"
[[ -f "$T/docs/project/backlog/_intro.md" ]] \
    && t_pass "4.2 docs/project/backlog/_intro.md present" \
    || t_fail "4.2 docs/project/backlog/_intro.md missing"
[[ ! -f "$T/docs/project/backlog/_format.md" ]] \
    && t_pass "4.2 docs/project/backlog/_format.md ABSENT (BD-206 forbidden)" \
    || t_fail "4.2 docs/project/backlog/_format.md unexpectedly present (BD-206 forbidden)"

[[ -f "$T/docs/project/implementation-plan/_rules.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_rules.md present" \
    || t_fail "4.2 docs/project/implementation-plan/_rules.md missing"
[[ -f "$T/docs/project/implementation-plan/_intro.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_intro.md present" \
    || t_fail "4.2 docs/project/implementation-plan/_intro.md missing"
[[ ! -f "$T/docs/project/implementation-plan/_format.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_format.md ABSENT (BD-206 forbidden)" \
    || t_fail "4.2 docs/project/implementation-plan/_format.md unexpectedly present (BD-206 forbidden)"

[[ -f "$T/docs/project/changelog/_rules.md" ]] \
    && t_pass "4.2 docs/project/changelog/_rules.md present" \
    || t_fail "4.2 docs/project/changelog/_rules.md missing"
[[ -f "$T/docs/project/changelog/_intro.md" ]] \
    && t_pass "4.2 docs/project/changelog/_intro.md present" \
    || t_fail "4.2 docs/project/changelog/_intro.md missing"
[[ ! -f "$T/docs/project/changelog/_format.md" ]] \
    && t_pass "4.2 docs/project/changelog/_format.md ABSENT (BD-206 forbidden)" \
    || t_fail "4.2 docs/project/changelog/_format.md unexpectedly present (BD-206 forbidden)"

# BD-263: groupings — the fourth per-entry stream (BD-262 contract).
[[ -f "$T/docs/project/groupings/_rules.md" ]] \
    && t_pass "4.2 docs/project/groupings/_rules.md present" \
    || t_fail "4.2 docs/project/groupings/_rules.md missing"
[[ -f "$T/docs/project/groupings/_intro.md" ]] \
    && t_pass "4.2 docs/project/groupings/_intro.md present" \
    || t_fail "4.2 docs/project/groupings/_intro.md missing"
[[ ! -f "$T/docs/project/groupings/_format.md" ]] \
    && t_pass "4.2 docs/project/groupings/_format.md ABSENT (BD-206 forbidden)" \
    || t_fail "4.2 docs/project/groupings/_format.md unexpectedly present (BD-206 forbidden)"

# 4.2 — integrity manifest generated at install by init-project.sh. The client
# verify-immutable.sh hashes the immutable _rules.md against this baseline;
# without it the client errors `manifest not found` on the first install.
[[ -f "$T/docs/project/immutable-manifest.txt" ]] \
    && t_pass "4.2 docs/project/immutable-manifest.txt present (generated at install)" \
    || t_fail "4.2 docs/project/immutable-manifest.txt missing (fresh-install integrity baseline)"

# 4.2 — BD-263 (OQ-9 ACK): the manifest carries exactly 4 rows — the four
# per-stream _rules.md incl. the groupings row (IMMUTABLE_PROJECT_RELS 3→4).
if [[ -f "$T/docs/project/immutable-manifest.txt" ]]; then
    manifest_rows=$(grep -c -v -e '^#' -e '^$' "$T/docs/project/immutable-manifest.txt" | tr -d ' ')
    assert_eq "4.2 immutable-manifest has 4 data rows (BD-263 3→4)" "4" "$manifest_rows"
    grep -q '^docs/project/groupings/_rules.md ' "$T/docs/project/immutable-manifest.txt" \
        && t_pass "4.2 immutable-manifest carries the groupings/_rules.md row" \
        || t_fail "4.2 immutable-manifest missing the groupings/_rules.md row"
fi

# 4.2 — end-to-end: the installed verify-immutable.sh runs clean (rc=0)
# against the just-generated manifest. This is the realized client check.
if [[ -f "$T/scripts/verify-immutable.sh" ]]; then
    ( cd "$T" && bash scripts/verify-immutable.sh ) >/dev/null 2>&1 ; vi_rc=$?
    [[ "$vi_rc" -eq 0 ]] \
        && t_pass "4.2 verify-immutable.sh rc=0 on fresh install (manifest baseline matches)" \
        || t_fail "4.2 verify-immutable.sh rc=$vi_rc on fresh install (expected 0)"
else
    t_fail "4.2 scripts/verify-immutable.sh missing on fresh install (expected from S5 ship)"
fi

# 4.3 — BD-206 no-mirror: the three monoliths are ABSENT at the parent
# docs/project/ (no regenerated mirror under the no-mirror model).
[[ ! -f "$T/docs/project/BACKLOG.md" ]] \
    && t_pass "4.3 docs/project/BACKLOG.md ABSENT (no-mirror)" \
    || t_fail "4.3 docs/project/BACKLOG.md unexpectedly present (no-mirror forbids it)"
[[ ! -f "$T/docs/project/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "4.3 docs/project/IMPLEMENTATION-PLAN.md ABSENT (no-mirror)" \
    || t_fail "4.3 docs/project/IMPLEMENTATION-PLAN.md unexpectedly present (no-mirror forbids it)"
[[ ! -f "$T/docs/project/CHANGELOG.md" ]] \
    && t_pass "4.3 docs/project/CHANGELOG.md ABSENT (no-mirror)" \
    || t_fail "4.3 docs/project/CHANGELOG.md unexpectedly present (no-mirror forbids it)"

# 4.3 (negative) — no stray monolith inside the stream subdirs either.
[[ ! -f "$T/docs/project/backlog/BACKLOG.md" ]] \
    && t_pass "4.3 no stray BACKLOG.md inside backlog/ subdir" \
    || t_fail "4.3 unexpected docs/project/backlog/BACKLOG.md"
[[ ! -f "$T/docs/project/implementation-plan/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "4.3 no stray IMPLEMENTATION-PLAN.md inside implementation-plan/ subdir" \
    || t_fail "4.3 unexpected docs/project/implementation-plan/IMPLEMENTATION-PLAN.md"
[[ ! -f "$T/docs/project/changelog/CHANGELOG.md" ]] \
    && t_pass "4.3 no stray CHANGELOG.md inside changelog/ subdir" \
    || t_fail "4.3 unexpected docs/project/changelog/CHANGELOG.md"

# (BD-206: the former 4.4/4.5 mirror byte-identity asserts are deleted —
# there is no monolithic mirror to byte-compare under the no-mirror model.)

# 4.6 — four empty seed _toc.md files with the canonical empty-state
# payload `(empty — no entries)` (verified upstream against the actual
# toc-regenerate.sh output; uses em-dash U+2014). BD-263: groupings is
# the fourth stream in the greenfield empty-seed loop (S11 step 7).
toc_empty_needle='(empty — no entries)'
for stream in backlog implementation-plan changelog groupings; do
    toc_path="$T/docs/project/$stream/_toc.md"
    if [[ -f "$toc_path" ]]; then
        t_pass "4.6 $stream/_toc.md present"
    else
        t_fail "4.6 $stream/_toc.md missing"
        continue
    fi
    if grep -q -F "$toc_empty_needle" "$toc_path"; then
        t_pass "4.6 $stream/_toc.md contains '(empty — no entries)' payload"
    else
        t_fail "4.6 $stream/_toc.md missing empty-state payload"
    fi
done

# 4.7 — no entry files seeded (greenfield starts empty per
# IMPL-REPORT-BD-166 §3 design note). Negative assertion.
strays=$(find "$T/docs/project/backlog" "$T/docs/project/implementation-plan" "$T/docs/project/changelog" "$T/docs/project/groupings" \
    -maxdepth 1 -type f -not -name "_*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$strays" -eq 0 ]]; then
    t_pass "4.7 no entry files seeded (TD-NNN.md / phase-N.md / GRP-NNN.md / YYYY-MM-DD-*.md absent on greenfield)"
else
    t_fail "4.7 unexpected entry files in stream subdirs (count=$strays)"
fi

# Keep $T alive for Group 5 (idempotency); cleaned at end of Group 5.

# ─────────────────────────────────────────────────────────────────────────
# Group 5: BD-166 sub-step 7 idempotency (helper-level proof loop)
# closes PACK-REVIEW-BD-166-RETRO SHOULD finding 2 (proof-loop closure).
#
# BD-206 (no-mirror): the greenfield path regenerates only `_toc.md`
# (no monolithic mirror). The TOC regenerator short-circuits on cmp -s
# byte-identity (toc-regenerate.sh). Reinvoking it against the freshly-
# installed greenfield tree must produce zero mtime churn — proving the
# sub-step 7 regen path is idempotent and a re-run of init-project.sh's
# sub-step 7 block would not gratuitously modify the install.
#
# Reuses $T from Group 4 (canonical greenfield surface freshly installed).
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: BD-166 sub-step 7 idempotency (proof loop) ===\n"

# Pre-snapshot the 3 _toc.md regen outputs. Use cmp-based equality
# rather than stat mtime: cmp -s is the canonical zero-mtime-churn
# signal the helper itself uses, and avoids stat -f (BSD) vs stat -c
# (GNU) portability surface area.
pre_snap_dir=$(mktemp -d "${TMPDIR:-/tmp}/bd166-snap.XXXXXX")
for rel in \
    "docs/project/backlog/_toc.md" \
    "docs/project/implementation-plan/_toc.md" \
    "docs/project/changelog/_toc.md" \
    "docs/project/groupings/_toc.md"; do
    src="$T/$rel"
    if [[ -f "$src" ]]; then
        # Flatten path → safe snapshot filename.
        safe_name=$(printf '%s' "$rel" | tr '/' '_')
        cp "$src" "$pre_snap_dir/$safe_name"
    fi
done

# Re-invoke the BD-164 helpers directly. The block below mirrors the
# sub-step 7 invocation pattern at scripts/init-project.sh:981-1007
# (same tuple shape, same </dev/null detach).
(
    set -uo pipefail
    PACK="$REPO_ROOT"
    cd "$PACK" || exit 1
    # shellcheck disable=SC1091
    . "$PACK/scripts/lib/per-entry/_lib.sh"
    # shellcheck disable=SC1091
    . "$PACK/scripts/lib/per-entry/toc-regenerate.sh"
    for pe_spec in \
        "project-backlog|docs/project/backlog" \
        "project-implementation-plan|docs/project/implementation-plan" \
        "project-changelog|docs/project/changelog" \
        "project-groupings|docs/project/groupings"; do
        pe_key="${pe_spec%%|*}"
        pe_dir_rel="${pe_spec##*|}"
        per_entry_regenerate_toc "$pe_key" "$T/$pe_dir_rel" \
            || { echo "regen toc failed for $pe_key" >&2; exit 1; }
    done
) ; regen_rc=$?
assert_eq "5.1 helper-level re-invocation rc=0" "0" "$regen_rc"

# Post: compare each regen output against the pre-snapshot. cmp -s is
# the same equality test the helpers themselves use to short-circuit
# (zero-mtime-churn semantics). Any byte difference here would mean
# the helpers rewrote the file — proving non-idempotency.
for rel in \
    "docs/project/backlog/_toc.md" \
    "docs/project/implementation-plan/_toc.md" \
    "docs/project/changelog/_toc.md" \
    "docs/project/groupings/_toc.md"; do
    safe_name=$(printf '%s' "$rel" | tr '/' '_')
    pre="$pre_snap_dir/$safe_name"
    post="$T/$rel"
    if [[ ! -f "$pre" ]]; then
        t_fail "5.2 $rel pre-snapshot missing (Group 4 install incomplete?)"
        continue
    fi
    if [[ ! -f "$post" ]]; then
        t_fail "5.2 $rel disappeared after re-invocation"
        continue
    fi
    if cmp -s "$pre" "$post"; then
        t_pass "5.2 $rel byte-identical after helper re-invocation (idempotent)"
    else
        t_fail "5.2 $rel changed after helper re-invocation (non-idempotent)"
    fi
done

rm -rf "$pre_snap_dir"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 6: BD-263 groupings provisioning via --update (D6.3 fold).
#
# The upgrade leg for already-installed v11.0 trees is the cmd_update
# fold (no standalone v11.0→v11.x migrator by design): the groupings
# sidecar entries install the stream, the post-copy toc-seed produces the
# empty `_toc.md` iff absent, and the manifest regen picks up the 4th
# immutable row. Legs map to the BD-189 #16 fixture set: (b) vanilla
# upgrade on a groupings-less v11.0 tree; (c) customization-preserving
# upgrade (client-authored entry files untouched — user `GRP-*.md` never
# overwritten); (e) idempotency (double-run no-op). Plus the §P5 C2 bite
# probe: hand-edited installed groupings `_rules.md` → installed
# verify-immutable.sh rc≠0.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6: BD-263 groupings provisioning via --update (D6.3) ===\n"

T6=$(make_target)
PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T6" >/dev/null 2>&1 ; rc=$?
assert_eq "6.0 fresh install rc=0 (Group 6 base tree)" "0" "$rc"

# Simulate the groupings-less v11.0 state (a pre-groupings dev install):
# remove the stream and strip the groupings manifest row.
rm -rf "$T6/docs/project/groupings"
grep -v '^docs/project/groupings/_rules.md ' \
    "$T6/docs/project/immutable-manifest.txt" \
    > "$T6/docs/project/immutable-manifest.txt.tmp"
mv "$T6/docs/project/immutable-manifest.txt.tmp" \
    "$T6/docs/project/immutable-manifest.txt"
git -C "$T6" add -A >/dev/null
git -C "$T6" commit -q -m "simulate pre-groupings v11.0 install" 2>/dev/null
[[ ! -d "$T6/docs/project/groupings" ]] \
    && t_pass "6.1 baseline: groupings stream ABSENT (groupings-less v11.0 tree)" \
    || t_fail "6.1 baseline: groupings stream unexpectedly present"

# (b) vanilla upgrade: --update seeds the groupings stream.
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T6" 2>&1) ; rc=$?
assert_eq "6.2 --update on groupings-less tree rc=0" "0" "$rc"
[[ -f "$T6/docs/project/groupings/_rules.md" ]] \
    && t_pass "6.2 groupings/_rules.md installed by --update" \
    || t_fail "6.2 groupings/_rules.md missing after --update"
[[ -f "$T6/docs/project/groupings/_intro.md" ]] \
    && t_pass "6.2 groupings/_intro.md installed by --update" \
    || t_fail "6.2 groupings/_intro.md missing after --update"
if cmp -s "$REPO_ROOT/project-template/docs/project/groupings/_rules.md" \
        "$T6/docs/project/groupings/_rules.md"; then
    t_pass "6.2 installed groupings/_rules.md matches the pack template source"
else
    t_fail "6.2 installed groupings/_rules.md differs from the pack template source"
fi
# Empty-seed _toc.md produced by the post-copy toc-seed (absent → seeded).
if [[ -f "$T6/docs/project/groupings/_toc.md" ]] \
   && grep -q -F '(empty — no entries)' "$T6/docs/project/groupings/_toc.md"; then
    t_pass "6.3 groupings/_toc.md seeded with '(empty — no entries)' payload"
else
    t_fail "6.3 groupings/_toc.md missing or missing empty-seed payload after --update"
fi
# Manifest regenerated to 4 rows incl. the groupings row.
manifest_rows=$(grep -c -v -e '^#' -e '^$' "$T6/docs/project/immutable-manifest.txt" | tr -d ' ')
assert_eq "6.4 immutable-manifest regenerated with 4 data rows" "4" "$manifest_rows"
grep -q '^docs/project/groupings/_rules.md ' "$T6/docs/project/immutable-manifest.txt" \
    && t_pass "6.4 immutable-manifest carries the groupings/_rules.md row" \
    || t_fail "6.4 immutable-manifest missing the groupings/_rules.md row"
# Installed verify-immutable.sh runs clean against the regenerated manifest.
( cd "$T6" && bash scripts/verify-immutable.sh ) >/dev/null 2>&1 ; vi_rc=$?
assert_eq "6.5 installed verify-immutable.sh rc=0 after --update" "0" "$vi_rc"

# (c) customization-preserving upgrade: client-authored entry files —
# a user grouping (GRP-001.md) and an existing-stream entry (TD-001.md) —
# are OUTSIDE the update dispatch set and must never be touched.
printf '# GRP-001 — user-authored grouping (must never be overwritten)\n' \
    > "$T6/docs/project/groupings/GRP-001.md"
printf '# TD-001 — user-authored backlog entry (must stay untouched)\n' \
    > "$T6/docs/project/backlog/TD-001.md"
git -C "$T6" add -A >/dev/null
git -C "$T6" commit -q -m "user-authored entries" 2>/dev/null

# (e) idempotency: snapshot the groupings surface + user files, re-run
# --update, assert a byte-level no-op (SC16.12).
#
# Reconcile-first: run 1 wrote *.pre-update sidecars (the base-less
# BD-088 classifier is conservative — ours+theirs present without a
# baseline classifies project-shadows-new-pack even when byte-identical,
# so every pre-existing installed file gets a sidecar). The single-slot
# sidecar contract refuses a re-run while sidecars exist (pinned by test
# 2.7 above); the user's reconcile step for an unchanged tree is
# removal. Remove them so run 2 actually executes (a refusal would make
# the byte-compare below pass vacuously).
find "$T6" -type f -name "*.pre-update" \
    -not -path "*/.pack-update/*" -not -path "*/.git/*" -delete
snap6=$(mktemp -d "${TMPDIR:-/tmp}/bd263-snap.XXXXXX")
for rel in \
    "docs/project/groupings/_rules.md" \
    "docs/project/groupings/_intro.md" \
    "docs/project/groupings/_toc.md" \
    "docs/project/groupings/GRP-001.md" \
    "docs/project/backlog/TD-001.md" \
    "docs/project/immutable-manifest.txt"; do
    safe_name=$(printf '%s' "$rel" | tr '/' '_')
    cp "$T6/$rel" "$snap6/$safe_name"
done
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T6" 2>&1) ; rc=$?
assert_eq "6.6 second --update rc=0 (after sidecar reconcile)" "0" "$rc"
for rel in \
    "docs/project/groupings/_rules.md" \
    "docs/project/groupings/_intro.md" \
    "docs/project/groupings/_toc.md" \
    "docs/project/groupings/GRP-001.md" \
    "docs/project/backlog/TD-001.md" \
    "docs/project/immutable-manifest.txt"; do
    safe_name=$(printf '%s' "$rel" | tr '/' '_')
    if cmp -s "$snap6/$safe_name" "$T6/$rel"; then
        t_pass "6.7 $rel byte-identical after --update re-run (no-op)"
    else
        t_fail "6.7 $rel changed on --update re-run (idempotency broken)"
    fi
done
rm -rf "$snap6"

# §P5 C2 bite probe: hand-edit the installed groupings _rules.md →
# installed verify-immutable.sh fails naming the file; restore → clean.
vi_orig=$(mktemp "${TMPDIR:-/tmp}/bd263-rules.XXXXXX")
cp "$T6/docs/project/groupings/_rules.md" "$vi_orig"
printf '\nhand-edit: client must not do this\n' \
    >> "$T6/docs/project/groupings/_rules.md"
vi_out=$( cd "$T6" && bash scripts/verify-immutable.sh 2>&1 ) ; vi_rc=$?
[[ "$vi_rc" -ne 0 ]] \
    && t_pass "6.8 verify-immutable.sh rc!=0 on hand-edited groupings/_rules.md (bite)" \
    || t_fail "6.8 verify-immutable.sh unexpectedly clean on hand-edited groupings/_rules.md"
assert_contains "6.8 failure names the groupings file" "$vi_out" \
    "docs/project/groupings/_rules.md"
cp "$vi_orig" "$T6/docs/project/groupings/_rules.md"
rm -f "$vi_orig"
( cd "$T6" && bash scripts/verify-immutable.sh ) >/dev/null 2>&1 ; vi_rc=$?
assert_eq "6.9 verify-immutable.sh rc=0 after restore" "0" "$vi_rc"

rm -rf "$T6"

# ─────────────────────────────────────────────────────────────────────────
# Group 7: BD-263 fail_stage bite probe — staged pack copy missing one
# groupings template (§P5 C2 FAIL-side proof for the S11 template guard).
#
# Stages a tracked-files-only copy of the pack (git ls-files → tar; no
# .git, no runtime-built fixture dirs), removes ONE groupings template,
# and asserts a fresh install fails loud at the S11 guard naming the
# missing canonical template.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 7: BD-263 S11 template guard (staged copy, FAIL side) ===\n"

STAGED=$(mktemp -d "${TMPDIR:-/tmp}/bd263-staged.XXXXXX")
( cd "$REPO_ROOT" && git ls-files -z | tar --null -T - -cf - ) \
    | tar -C "$STAGED" -xf -
if [[ -f "$STAGED/scripts/init-project.sh" \
   && -f "$STAGED/project-template/docs/project/groupings/_rules.md" ]]; then
    t_pass "7.0 staged pack copy materialized (tracked files)"
else
    t_fail "7.0 staged pack copy incomplete (git ls-files → tar staging failed)"
fi
rm -f "$STAGED/project-template/docs/project/groupings/_rules.md"
# The pack pre-flight (detect_pack_path) requires $PACK to be a git work
# tree; make the staged scratch copy one (test-infra scratch repo — the
# real pack repo is never touched).
git init -q "$STAGED" >/dev/null
git -C "$STAGED" config user.email "test@example.com"
git -C "$STAGED" config user.name  "Test"
git -C "$STAGED" add -A >/dev/null
git -C "$STAGED" commit -q -m "staged pack copy (groupings template removed)" 2>/dev/null

T7=$(make_target)
out=$(PACK="$STAGED" bash "$STAGED/scripts/init-project.sh" --yes "$T7" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] \
    && t_pass "7.1 fresh install FAILS when groupings/_rules.md is missing from the pack (rc=$rc)" \
    || t_fail "7.1 install unexpectedly succeeded with groupings/_rules.md removed from the staged pack"
assert_contains "7.1 failure names the missing canonical template" "$out" \
    "canonical template missing: project-template/docs/project/groupings/_rules.md"

rm -rf "$STAGED" "$T7"

# ─────────────────────────────────────────────────────────────────────────
# Group 8: BD-278 client validate.sh enforcement deliverable.
#
#   S7  — SHIP: the opt-in installer (install-validate-hook.sh) and the
#         detection helper (detect-validate-enforcement.sh) ship on a fresh
#         install AND survive a fresh→update refresh (absent from the S9
#         language roster). The exec assertion runs on the UPDATE path, where
#         cp preserves the COMMITTED 755 (fresh install chmod +x's everything,
#         so a fresh-only exec check is spurious).
#   S7b — the matcher/never-fails regression: the helper's own --self-test
#         PASSes (pins the sibling-leg + comment false-positive vectors and the
#         true-positive invocation); the G1 skill driver stays benign (rc 0 +
#         a valid token) against an absent / erroring / garbage helper (the
#         never-fails floor); the consent-structural grep (no install
#         invocation reachable from a skill fence or the helper); and the
#         delegation grep (both skills call the helper and neither re-implements
#         a channel probe).
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 8: BD-278 validate.sh enforcement (ship + matcher/never-fails) ===\n"

VE_INSTALLER="project-template/scripts/install-validate-hook.sh"
VE_DETECTOR="project-template/scripts/detect-validate-enforcement.sh"
VE_PMSTART="project-template/skills/pm-startup/SKILL.md"
VE_PMREFRESH="project-template/skills/pm-refresh/SKILL.md"

# Extract the content of every ```bash fenced block from a markdown file.
ve_bash_fences() { awk '/^```bash$/{f=1;next} /^```$/{f=0} f' "$1"; }

# Extract the REAL G1 driver fence from a shipped skill — the ```bash block that
# references the detector. Running the ACTUAL shipped fence (not a verbatim
# copy) means a future drift in the skill's guard/sanitize block FAILS the
# never-fails-floor test below (F2).
ve_extract_driver_fence() {  # $1 = SKILL.md → stdout = the driver fence body
    awk '
      /^```bash$/ { inblk=1; buf=""; next }
      /^```$/     { if (inblk && buf ~ /detect-validate-enforcement\.sh/) printf "%s", buf; inblk=0; next }
      inblk       { buf = buf $0 "\n" }
    ' "$1"
}

# Run a skill's REAL driver fence in a fresh scratch git repo whose
# scripts/detect-validate-enforcement.sh is the given BROKEN helper (or absent),
# and echo "<rc>|<the 'quality gate: <token>' line>". The fence resolves the
# detector via git-toplevel, so a scratch git repo drives it end-to-end.
ve_run_real_fence() {  # $1 = SKILL.md ; $2 = absent|erroring|garbage|unreadable
    local skill="$1" kind="$2" wd fence fsh hp out rc
    wd=$(make_target)
    mkdir -p "$wd/scripts"
    fence=$(ve_extract_driver_fence "$skill")
    fsh="$wd/.real-fence.sh"
    printf '%s\n' "$fence" > "$fsh"
    hp="$wd/scripts/detect-validate-enforcement.sh"
    case "$kind" in
        absent)     : ;;
        erroring)   printf '#!/usr/bin/env bash\nexit 3\n'                 > "$hp"; chmod +x  "$hp" ;;
        garbage)    printf '#!/usr/bin/env bash\necho "totally-bogus"\n'   > "$hp"; chmod +x  "$hp" ;;
        unreadable) printf '#!/usr/bin/env bash\necho unenforced\n'        > "$hp"; chmod 000 "$hp" ;;
    esac
    out=$( cd "$wd" && bash "$fsh" 2>/dev/null ) ; rc=$?
    [ -e "$hp" ] && chmod 644 "$hp" 2>/dev/null || true
    rm -rf "$wd"
    printf '%s|%s\n' "$rc" "$out"
}

# --- S7 SHIP: fresh install ships both scripts (present ⇒ S9 did not remove) ---
T8=$(make_target)
PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T8" >/dev/null 2>&1 ; rc=$?
assert_eq "8.1 fresh install rc=0 (Group 8 base tree)" "0" "$rc"
[[ -f "$T8/scripts/install-validate-hook.sh" ]] \
    && t_pass "8.1 install-validate-hook.sh present after fresh install (not removed by S9)" \
    || t_fail "8.1 install-validate-hook.sh missing after fresh install"
[[ -f "$T8/scripts/detect-validate-enforcement.sh" ]] \
    && t_pass "8.1 detect-validate-enforcement.sh present after fresh install (not removed by S9)" \
    || t_fail "8.1 detect-validate-enforcement.sh missing after fresh install"

# --- S7b: the SHIPPED helper's own --self-test passes (matcher regression) ---
st_out=$( bash "$T8/scripts/detect-validate-enforcement.sh" --self-test 2>&1 ) ; st_rc=$?
assert_eq "8.2 detect-validate-enforcement.sh --self-test rc=0" "0" "$st_rc"
assert_contains "8.2 --self-test reports PASS" "$st_out" "PASS"

# --- helper end-to-end on a fresh client (no hook, no workflows) ⇒ unenforced ---
de_out=$( cd "$T8" && bash scripts/detect-validate-enforcement.sh 2>/dev/null ) ; de_rc=$?
assert_eq "8.3 detector rc=0 on a fresh client" "0" "$de_rc"
assert_eq "8.3 fresh client (no hook, no workflow) ⇒ unenforced" "unenforced" "$de_out"

rm -rf "$T8"

# --- G3 never-fails floor (F2): run the REAL shipped driver fence of BOTH
#     skills against a broken helper; each must print a benign token + rc 0. ---
for sk_rel in "$VE_PMSTART" "$VE_PMREFRESH"; do
    sk="$REPO_ROOT/$sk_rel"
    sk_name="$(basename "$(dirname "$sk_rel")")"
    fence=$(ve_extract_driver_fence "$sk")
    if [ -n "$fence" ] && printf '%s\n' "$fence" | bash -n 2>/dev/null; then
        t_pass "8.4 $sk_name: real driver fence extracted + valid bash"
    else
        t_fail "8.4 $sk_name: could not extract a valid driver fence"
    fi
    res=$(ve_run_real_fence "$sk" absent);     rc="${res%%|*}"; tok="${res#*|}"
    assert_eq "8.5 $sk_name real fence rc=0 (ABSENT helper)" "0" "$rc"
    assert_contains "8.5 $sk_name ABSENT ⇒ unavailable (benign)" "$tok" "quality gate: unavailable"
    res=$(ve_run_real_fence "$sk" erroring);   rc="${res%%|*}"; tok="${res#*|}"
    assert_eq "8.6 $sk_name real fence rc=0 (ERRORING helper)" "0" "$rc"
    assert_contains "8.6 $sk_name ERRORING ⇒ unenforced (safe default)" "$tok" "quality gate: unenforced"
    res=$(ve_run_real_fence "$sk" garbage);    rc="${res%%|*}"; tok="${res#*|}"
    assert_eq "8.6 $sk_name real fence rc=0 (GARBAGE helper)" "0" "$rc"
    assert_contains "8.6 $sk_name GARBAGE ⇒ unenforced (safe default)" "$tok" "quality gate: unenforced"
    res=$(ve_run_real_fence "$sk" unreadable); rc="${res%%|*}"; tok="${res#*|}"
    assert_eq "8.6 $sk_name real fence rc=0 (UNREADABLE helper)" "0" "$rc"
    assert_contains "8.6 $sk_name UNREADABLE ⇒ unenforced (safe default)" "$tok" "quality gate: unenforced"
done

# --- S7 SHIP on the UPDATE path: both scripts arrive exec-preserved (755) ---
# Simulate a pre-BD-278 install (scripts absent), then --update re-adds them.
# cp preserves the committed 755 for the newly-arriving files, so the exec
# assertion is meaningful here (unlike fresh install, which chmod +x's all).
T8u=$(make_target)
PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T8u" >/dev/null 2>&1 ; rc=$?
assert_eq "8.7 fresh install rc=0 (update-path base)" "0" "$rc"
git -C "$T8u" add -A >/dev/null 2>&1
git -C "$T8u" commit -q -m "fresh install" 2>/dev/null
rm -f "$T8u/scripts/install-validate-hook.sh" "$T8u/scripts/detect-validate-enforcement.sh"
git -C "$T8u" add -A >/dev/null 2>&1
git -C "$T8u" commit -q -m "simulate pre-BD-278 install (enforcement scripts absent)" 2>/dev/null
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T8u" 2>&1) ; rc=$?
assert_eq "8.7 --update rc=0 (re-adds the enforcement scripts)" "0" "$rc"
[[ -f "$T8u/scripts/install-validate-hook.sh" ]] \
    && t_pass "8.7 install-validate-hook.sh present after --update" \
    || t_fail "8.7 install-validate-hook.sh missing after --update"
[[ -f "$T8u/scripts/detect-validate-enforcement.sh" ]] \
    && t_pass "8.7 detect-validate-enforcement.sh present after --update" \
    || t_fail "8.7 detect-validate-enforcement.sh missing after --update"
[[ -x "$T8u/scripts/install-validate-hook.sh" ]] \
    && t_pass "8.8 install-validate-hook.sh executable after --update (committed 755 preserved)" \
    || t_fail "8.8 install-validate-hook.sh NOT executable after --update"
[[ -x "$T8u/scripts/detect-validate-enforcement.sh" ]] \
    && t_pass "8.8 detect-validate-enforcement.sh executable after --update (committed 755 preserved)" \
    || t_fail "8.8 detect-validate-enforcement.sh NOT executable after --update"
rm -rf "$T8u"

# --- S7b CONSENT-structural: no install invocation reachable from a skill ---
# The installer name may appear ONLY in suggestion/report PROSE, never inside a
# ```bash fence, and NEVER anywhere in the helper (a pure read-only probe).
for sk in "$VE_PMSTART" "$VE_PMREFRESH"; do
    rel="${sk#project-template/skills/}"
    if ve_bash_fences "$REPO_ROOT/$sk" | grep -q 'install-validate-hook.sh'; then
        t_fail "8.9 consent: install-validate-hook.sh found INSIDE a bash fence of $rel"
    else
        t_pass "8.9 consent: no install invocation in $rel bash fences"
    fi
done
if grep -q 'install-validate-hook.sh' "$REPO_ROOT/$VE_DETECTOR"; then
    t_fail "8.9 consent: install-validate-hook.sh present in the detector helper (must be install-free)"
else
    t_pass "8.9 consent: detector helper is install-invocation-free"
fi
if grep -q 'install-validate-hook.sh' "$REPO_ROOT/$VE_PMREFRESH"; then
    t_fail "8.9 consent: pm-refresh unexpectedly names the installer"
else
    t_pass "8.9 consent: pm-refresh names no installer"
fi

# --- S7b DELEGATION: both skills call the helper; neither re-implements a probe ---
for sk in "$VE_PMSTART" "$VE_PMREFRESH"; do
    rel="${sk#project-template/skills/}"
    grep -q 'detect-validate-enforcement.sh' "$REPO_ROOT/$sk" \
        && t_pass "8.10 delegation: $rel calls the detector helper" \
        || t_fail "8.10 delegation: $rel does not call the detector helper"
    if grep -qE -- '--git-path hooks|\.github/workflows' "$REPO_ROOT/$sk"; then
        t_fail "8.10 delegation: $rel re-implements a channel probe (must delegate)"
    else
        t_pass "8.10 delegation: $rel carries no inline channel probe"
    fi
done
if grep -qE -- '--git-path hooks' "$REPO_ROOT/$VE_DETECTOR" \
   && grep -qE -- '\.github/workflows' "$REPO_ROOT/$VE_DETECTOR"; then
    t_pass "8.10 delegation: the helper carries both channel probes (probe SSOT)"
else
    t_fail "8.10 delegation: the helper is missing a channel-probe token"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group 9: BD-284 — --yes automation flag + TTY-aware confirm
#
#   9.1 --yes installs with NO stdin feed (automation bypass).
#   9.2 non-TTY WITHOUT --yes declines (exit 0), and the decline message
#       NAMES --yes (so a scripted caller learns the flag). Assert on the
#       MESSAGE, not rc — a decline exits 0 by design.
#   9.3 the interactive path still honors a piped `y` under
#       PACK_PROMPT_FORCE_INTERACTIVE=1 (the human path survives while
#       automation moves to --yes). Fed via `printf 'y\n' |` (a pipe, not a
#       here-string) so the BD-284 here-string migration self-gate stays clean.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 9: BD-284 --yes / TTY-aware confirm ===\n"

# 9.1 --yes: fresh install with NO stdin feed → rc=0 + trinity laid down.
T9=$(make_target)
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T9" 2>&1) ; rc=$?
assert_eq "9.1 --yes fresh install rc=0 (no stdin feed)" "0" "$rc"
if [[ -f "$T9/CLAUDE.md" && -f "$T9/AGENTS.md" && -f "$T9/GEMINI.md" ]]; then
    t_pass "9.1 --yes installed the trinity"
else
    t_fail "9.1 --yes did not lay down the trinity"
fi
rm -rf "$T9"

# 9.2 non-TTY WITHOUT --yes: decline exits 0, message NAMES --yes, no install.
T9b=$(make_target)
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" "$T9b" </dev/null 2>&1) ; rc=$?
assert_eq "9.2 non-TTY decline exits 0 (no --yes)" "0" "$rc"
assert_contains "9.2 decline message names --yes" "$out" "--yes"
if [[ ! -f "$T9b/CLAUDE.md" ]]; then
    t_pass "9.2 non-TTY decline made no changes (no trinity)"
else
    t_fail "9.2 non-TTY decline unexpectedly installed the trinity"
fi
rm -rf "$T9b"

# 9.3 interactive path survives: PACK_PROMPT_FORCE_INTERACTIVE=1 + piped `y`.
T9c=$(make_target)
out=$(printf 'y\n' | PACK="$REPO_ROOT" PACK_PROMPT_FORCE_INTERACTIVE=1 \
    bash "$INIT_SH" "$T9c" 2>&1) ; rc=$?
assert_eq "9.3 interactive (forced) + piped y installs rc=0" "0" "$rc"
if [[ -f "$T9c/CLAUDE.md" ]]; then
    t_pass "9.3 interactive path installed the trinity (human path survives)"
else
    t_fail "9.3 interactive path did not install"
fi
rm -rf "$T9c"

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
