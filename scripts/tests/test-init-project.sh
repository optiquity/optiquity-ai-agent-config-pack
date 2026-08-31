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

# 2.8 the map PARSES but its `cmd_update` axis is EMPTY. The parser's
# non-empty floor guards each BLOCK; the stage-token filter runs after it, so
# a mistyped stage token yields rc 0 with ZERO rows and — without the
# call-site guard — an --update that exits 0 having refreshed not one file.
# The map root is SYNTHETIC (INSTALL_MAP_PACK); the real map is never mutated.
T=$(make_configured_target)
NOAXIS=$(mktemp -d "${TMPDIR:-/tmp}/init-noaxis.XXXXXX")
mkdir -p "$NOAXIS/scripts" "$NOAXIS/project-template/bundle"
printf 'x\n' > "$NOAXIS/project-template/bundle/one.md"
cat > "$NOAXIS/scripts/init-project.sh" <<'NOAXIS_MAP'
#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/bundle/one.md  ->  bundle/one.md  [stage:S6]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
NOAXIS_MAP

out=$(INSTALL_MAP_PACK="$NOAXIS" PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T" 2>&1) ; rc=$?
assert_eq "2.8 an empty cmd_update axis makes --update refuse" "51" "$rc"
assert_contains "2.8 diagnostic names the empty axis" "$out" \
    "install map declares no cmd_update rows"

# 2.9 DISCRIMINATION for 2.8: the SAME target with the REAL map dispatches
# normally, so 2.8 is not passing because --update refuses this target.
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --update "$T" 2>&1) ; rc=$?
assert_eq "2.9 the real map still dispatches (2.8 discriminates)" "0" "$rc"

# 2.10 the refusal in 2.8 must leave the client exactly as it found them. The
# dispatch set is resolved — and both its `die`s fire — before this function
# touches anything, which closes two failure modes at once:
#
#   * the prior ledger is copied to a `mktemp` (it must be, since the state dir
#     that holds it is cleared moments later), and `set -euo pipefail` means a
#     `die` between that copy and its `rm -f` never reaches the cleanup;
#   * `rm -rf "$state_dir"` destroys the ledger itself, so a refusal AFTER it
#     degrades the NEXT run's R1 rung as well — the cascade loses the baseline
#     it would otherwise have resolved from.
#
# TMPDIR is private to the run so the temp count is exact and no other test's
# temps are counted.
T2=$(make_configured_target)
mkdir -p "$T2/.pack-update"
printf 'docs/pack/FOO.md\tproject-template/docs/pack/FOO.md\tLEDGERSENTINEL\n' \
    > "$T2/.pack-update/ledger.tsv"
LEAKDIR=$(mktemp -d "${TMPDIR:-/tmp}/init-leak.XXXXXX")

# PRECONDITION: the ledger sits where the R1 READ loop looks and is non-empty.
# Without it nothing would be copied and the leg would pass vacuously.
[[ -s "$T2/.pack-update/ledger.tsv" ]] \
    && t_pass "2.10 precondition: a non-empty prior ledger is present" \
    || t_fail "2.10 precondition: no prior ledger, so nothing could leak"

out=$(TMPDIR="$LEAKDIR" INSTALL_MAP_PACK="$NOAXIS" PACK="$REPO_ROOT" \
    bash "$INIT_SH" --update "$T2" 2>&1) ; rc=$?
assert_eq "2.10 the empty-axis refusal still fires" "51" "$rc"
n_leaked=$(find "$LEAKDIR" -name 'cu-prior.*' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "2.10 the refusal leaves no cu-prior temp behind" "0" "$n_leaked"
grep -q 'LEDGERSENTINEL' "$T2/.pack-update/ledger.tsv" 2>/dev/null \
    && t_pass "2.10 the refusal leaves the prior ledger intact for the next run" \
    || t_fail "2.10 the refusal destroyed the prior ledger (R1 input for the next run)"
rm -rf "$LEAKDIR" "$T2"

# 2.11 a join that yields NOTHING must not empty the dispatch set. The R1 READ
# join is an `awk` two-file `NR == FNR` pass, whose one degenerate mode is a
# first file with ZERO records: every stdin record then satisfies `NR == FNR`,
# is consumed as a ledger row, and nothing is printed — with `awk` still
# exiting 0, so the rc test cannot see it. The loop reads the POST-join value,
# so adopting that result refreshes not one file. The pre-join non-empty guard
# cannot catch it: it runs upstream, on a set that was still populated.
#
# That state is unreachable through the front door: the R1 READ loop tests
# `-s`, which requires at least one byte and therefore at least one record.
# Relaxing that ONE test to `-e` in a COPY of the script is what lets this leg
# reach the join with an empty first file. The coupling being tested is exactly
# the fragile one: nothing but that `-s`, sixty lines earlier, stands between a
# future change in how the ledger is materialised and a silent no-op update.
T3=$(make_configured_target)
MUTDIR=$(mktemp -d "${TMPDIR:-/tmp}/init-mut.XXXXXX")
MUT="$MUTDIR/init-project.sh"
# The script sources its startup libraries from `$SCRIPT_DIR/lib`, so a copy
# needs that sibling to exist. Symlinked, not duplicated: the copy must differ
# from the original in the ONE relaxed test and nothing else.
ln -s "$REPO_ROOT/scripts/lib" "$MUTDIR/lib"
sed 's/\[\[ -s "\$_cu_prior" \]\]/[[ -e "$_cu_prior" ]]/' "$INIT_SH" > "$MUT"
if ! cmp -s "$MUT" "$INIT_SH" && grep -q '\[\[ -e "\$_cu_prior" \]\]' "$MUT"; then
    t_pass "2.11 precondition: the -s relaxation applied to the script copy"
else
    t_fail "2.11 precondition: the -s anchor drifted; this leg proves nothing"
fi

mkdir -p "$T3/.pack-update"
: > "$T3/.pack-update/ledger.tsv"
[[ -e "$T3/.pack-update/ledger.tsv" && ! -s "$T3/.pack-update/ledger.tsv" ]] \
    && t_pass "2.11 precondition: the prior ledger exists and is 0 bytes" \
    || t_fail "2.11 precondition: ledger is not the 0-byte case"

out=$(PACK="$REPO_ROOT" bash "$MUT" --update "$T3" 2>&1) ; rc=$?
assert_eq "2.11 the run completes" "0" "$rc"
rows=$(awk 'NR > 1 && NF > 0' "$T3/.pack-update/dispositions.tsv" 2>/dev/null | wc -l | tr -d ' ')
[[ "$rows" -gt 0 ]] \
    && t_pass "2.11 an empty join does not empty the dispatch set ($rows rows)" \
    || t_fail "2.11 the empty join emptied the dispatch set" "rows=$rows"

# DISCRIMINATION for 2.11: invert the guard's sense in a second copy, which
# reproduces the pre-guard behaviour for THIS input (an empty join is adopted).
# The same 0-byte ledger must then produce ZERO rows — that is what makes the
# leg above a guard rather than a leg that would pass either way.
#
# ROWS, not the exit code, is the assertion. An emptied dispatch set installs
# nothing, so the run does not necessarily reach exit 0 — measured, it fails
# further downstream at the immutable-manifest gate, whose diagnostic names a
# missing installed file and says nothing about the dispatch set. A run that
# ends in the wrong error is the same defect as one that ends silently.
MUTBAD="$MUTDIR/init-project-noguard.sh"
sed 's/\[\[ -n "\$joined" \]\]/[[ -z "$joined" ]]/' "$MUT" > "$MUTBAD"
if ! cmp -s "$MUTBAD" "$MUT" && grep -q '\[\[ -z "\$joined" \]\]' "$MUTBAD"; then
    t_pass "2.11 precondition: the guard inversion applied to the second copy"
else
    t_fail "2.11 precondition: the guard anchor drifted; discrimination is void"
fi
T4=$(make_configured_target)
mkdir -p "$T4/.pack-update"
: > "$T4/.pack-update/ledger.tsv"
out=$(PACK="$REPO_ROOT" bash "$MUTBAD" --update "$T4" 2>&1) ; rc=$?
rows_bad=$(awk 'NR > 1 && NF > 0' "$T4/.pack-update/dispositions.tsv" 2>/dev/null | wc -l | tr -d ' ')
[[ "$rows_bad" -eq 0 ]] \
    && t_pass "2.11 without the guard the same input refreshes nothing (rc=$rc, 0 rows)" \
    || t_fail "2.11 discrimination failed — the unguarded copy still dispatched" \
        "rc=$rc rows=$rows_bad"

rm -rf "$MUTDIR" "$T3" "$T4"

rm -rf "$T" "$NOAXIS"

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
# No reconcile step is needed between the two runs. An installed file that
# is byte-identical to the pack template classifies `unchanged-pack` (the
# identity rule in three-way.sh applies regardless of an absent baseline),
# so run 1 writes NO sidecars for an unchanged tree. That matters here
# beyond tidiness: the single-slot sidecar contract REFUSES a re-run while
# any *.pre-update sidecar survives (pinned by test 2.7 above), so a run
# that left sidecars behind would make run 2 a refusal and the byte-compare
# below would pass vacuously. Leg 6.6b asserts the zero-sidecar property
# directly rather than trusting it.
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
assert_eq "6.6 second --update rc=0 (no reconcile step between runs)" "0" "$rc"

# 6.6b IDEMPOTENCE (BD-293 T-IDEM). A second --update against an UNCHANGED
# pack must be a true no-op: zero sidecars on disk and zero reconciliation
# findings in the report. rc=0 above already proves run 1 left no sidecars
# (the stale-sidecar pre-check would have refused to start); these two
# assertions pin the property for run 2 as well. --update wipes and rewrites
# $TARGET/.pack-update on entry, so the TSV read here is run 2's own report.
sidecars6=$(find "$T6" -type f -name "*.pre-update" \
    -not -path "*/.pack-update/*" -not -path "*/.git/*" | wc -l | tr -d ' ')
assert_eq "6.6b zero *.pre-update sidecars after the unchanged-pack re-run" \
    "0" "$sidecars6"
disp_tsv6="$T6/.pack-update/dispositions.tsv"
if [[ -f "$disp_tsv6" ]]; then
    needs6=$(grep -c "needs-reconciliation" "$disp_tsv6" || true)
    assert_eq "6.6b zero needs-reconciliation rows in run-2 dispositions.tsv" \
        "0" "$needs6"
else
    t_fail "6.6b run-2 dispositions.tsv missing" "expected $disp_tsv6"
fi

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
# BD-285 C2 — helpers for the guided keep/replace/merge trinity branch tests.
# ─────────────────────────────────────────────────────────────────────────

# Commit whatever is staged in a target so its working tree is clean (init
# refuses a dirty target by design — the P0 commit-first gate).
commit_target() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m "fixture" 2>/dev/null; }

# ─────────────────────────────────────────────────────────────────────────
# Group 10: BD-285 detect_trinity_provenance (pack | handwritten | ambiguous)
# — unit tests against crafted fixture dirs (the helper is a pure read-only
# fs probe; no git / PACK needed). Covers the P1 config-shape guard + the
# F-6 work-item.yml drop.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 10: BD-285 detect_trinity_provenance ===\n"

# shellcheck disable=SC1091
. "$REPO_ROOT/scripts/lib/detect.sh"

tp_base=$(mktemp -d "${TMPDIR:-/tmp}/bd285-tp.XXXXXX")

mk_tp() { local n="$1"; local d="$tp_base/$n"; mkdir -p "$d"; printf '%s' "$d"; }

# lone handwritten CLAUDE.md → handwritten
d=$(mk_tp lone); printf 'hand\n' > "$d/CLAUDE.md"
assert_eq "10.1 lone handwritten CLAUDE.md ⇒ handwritten" "handwritten" "$(detect_trinity_provenance "$d")"

# no trinity file at all → ambiguous
d=$(mk_tp none); : > "$d/README.md"
assert_eq "10.2 no trinity file ⇒ ambiguous" "ambiguous" "$(detect_trinity_provenance "$d")"

# /pm-help fingerprint → pack
d=$(mk_tp pmhelp); printf 'stuff\nrun `/pm-help` for the full verb list\n' > "$d/CLAUDE.md"
assert_eq "10.3 /pm-help verb line ⇒ pack" "pack" "$(detect_trinity_provenance "$d")"

# project-owned marker pair → pack
d=$(mk_tp markers)
printf '# CLAUDE\n<!-- BEGIN project-owned: x -->\ncustom\n<!-- END project-owned: x -->\n' > "$d/CLAUDE.md"
assert_eq "10.4 BEGIN/END project-owned markers ⇒ pack" "pack" "$(detect_trinity_provenance "$d")"

# v11 surface file (pm-help SKILL.md) → pack
d=$(mk_tp v11surface); printf 'hand\n' > "$d/CLAUDE.md"
mkdir -p "$d/.claude/skills/pm-help"; : > "$d/.claude/skills/pm-help/SKILL.md"
assert_eq "10.5 v11 pm-help SKILL.md surface ⇒ pack" "pack" "$(detect_trinity_provenance "$d")"

# v10 marker-bearing shape (CLAUDE + .claude + docs/pack/METHODOLOGY.md) → pack
d=$(mk_tp v10shape); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.claude" "$d/docs/pack"; : > "$d/docs/pack/METHODOLOGY.md"
assert_eq "10.6 v10 marker-bearing shape ⇒ pack" "pack" "$(detect_trinity_provenance "$d")"

# P1 guard: populated foreign agent tree → ambiguous
d=$(mk_tp foreign); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.claude/agents"; printf 'x\n' > "$d/.claude/agents/some.md"
assert_eq "10.7 populated .claude/agents ⇒ ambiguous (P1 guard)" "ambiguous" "$(detect_trinity_provenance "$d")"

# bare dot-dir + lone structured config still reaches handwritten
d=$(mk_tp bare); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.claude"; printf '{}\n' > "$d/.claude/settings.json"
assert_eq "10.8 bare .claude/ + lone settings.json ⇒ handwritten" "handwritten" "$(detect_trinity_provenance "$d")"

# lone .agents/mcp_config.json (structured config, NOT an agent/skill tree) → handwritten
d=$(mk_tp mcp); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.agents"; printf '{}\n' > "$d/.agents/mcp_config.json"
assert_eq "10.9 lone .agents/mcp_config.json ⇒ handwritten (structured, not foreign tree)" "handwritten" "$(detect_trinity_provenance "$d")"

# F-6: a lone work-item.yml is NOT a pack signal → handwritten
d=$(mk_tp f6); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.github/ISSUE_TEMPLATE"; : > "$d/.github/ISSUE_TEMPLATE/work-item.yml"
assert_eq "10.10 F-6: lone work-item.yml is NOT a pack signal ⇒ handwritten" "handwritten" "$(detect_trinity_provenance "$d")"

# P1 guard (Finding-3): a populated v10-legacy .gemini/agents roster → ambiguous.
# v11 never writes .gemini/, but a populated .gemini/agents is a foreign agent
# roster (v10 Antigravity home; detect_ai_config carve-out ii) — it must STOP
# (route to the migrator), not classify as a bare handwritten starter.
d=$(mk_tp geminiagents); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.gemini/agents"; printf 'x\n' > "$d/.gemini/agents/x-custom.md"
assert_eq "10.11 populated .gemini/agents ⇒ ambiguous (P1 guard, legacy roster)" "ambiguous" "$(detect_trinity_provenance "$d")"

# A BARE .gemini/ dir (no agents/skills subtree) still reaches handwritten.
d=$(mk_tp geminibare); printf 'hand\n' > "$d/CLAUDE.md"; mkdir -p "$d/.gemini"
assert_eq "10.12 bare .gemini/ (no roster) ⇒ handwritten" "handwritten" "$(detect_trinity_provenance "$d")"

rm -rf "$tp_base"

# ─────────────────────────────────────────────────────────────────────────
# Group 11: BD-285 F1 never-lose order (SHOULD-4 — BOTH halves) for merge AND
# replace against a FULL-trinity starter with KNOWN distinctive bytes.
#   For m AND r: <f>.user-orig EXISTS and cmp-equals the pre-install snapshot
#   (NOT the pack template) AND the live <f> cmp-equals the pack template (the
#   overwrite happened). A backwards `cp pack "$f"; cp "$f" "$f.user-orig"`
#   makes <f>.user-orig == pack != snapshot → this group goes RED.
#   Plus N1: a pre-existing <f>.user-orig ⇒ fail_stage LOUD (no silent
#   overwrite).
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 11: BD-285 F1 never-lose order (merge + replace) ===\n"

for choice in merge replace; do
    T=$(make_target)
    printf 'CLAUDE handwritten distinctive %s 11111\n' "$choice" > "$T/CLAUDE.md"
    printf 'AGENTS handwritten distinctive %s 22222\n' "$choice" > "$T/AGENTS.md"
    printf 'GEMINI handwritten distinctive %s 33333\n' "$choice" > "$T/GEMINI.md"
    commit_target "$T"
    snap=$(mktemp -d "${TMPDIR:-/tmp}/bd285-snap.XXXXXX")
    cp "$T/CLAUDE.md" "$snap/CLAUDE.md"; cp "$T/AGENTS.md" "$snap/AGENTS.md"; cp "$T/GEMINI.md" "$snap/GEMINI.md"
    out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity="$choice" "$T" 2>&1) ; rc=$?
    assert_eq "11.$choice fresh guided install rc=0" "0" "$rc"
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        if [[ -f "$T/$f.user-orig" ]] && cmp -s "$T/$f.user-orig" "$snap/$f"; then
            t_pass "11.$choice $f.user-orig == pre-install snapshot (OURS captured, NOT the pack template)"
        else
            t_fail "11.$choice $f.user-orig missing or != snapshot (F1 order broken / backwards)"
        fi
        if cmp -s "$T/$f" "$REPO_ROOT/project-template/$f"; then
            t_pass "11.$choice live $f == pack template (overwrite happened — SHOULD-4)"
        else
            t_fail "11.$choice live $f != pack template (overwrite half missing)"
        fi
    done
    rm -rf "$snap" "$T"
done

# merge writes a merge-2way row per present trinity file + the skill hint;
# replace writes NO row and creates NO .pack-install-reconcile/ dir.
T=$(make_target)
printf 'C 1\n' > "$T/CLAUDE.md"; printf 'A 2\n' > "$T/AGENTS.md"; printf 'G 3\n' > "$T/GEMINI.md"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" 2>&1) ; rc=$?
assert_eq "11.row merge install rc=0" "0" "$rc"
rows=$(awk -F'\t' '$2=="trinity" && $4=="merge-2way"' "$T/.pack-install-reconcile/dispositions.tsv" 2>/dev/null | wc -l | tr -d ' ')
assert_eq "11.row merge writes 3 merge-2way trinity rows (all present)" "3" "$rows"
assert_contains "11.row merge prints the resolve-merge-conflicts hint" "$out" "resolve-merge-conflicts skill (Case 3"
rm -rf "$T"

T=$(make_target)
printf 'C 1\n' > "$T/CLAUDE.md"; printf 'A 2\n' > "$T/AGENTS.md"; printf 'G 3\n' > "$T/GEMINI.md"
commit_target "$T"
PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=replace "$T" >/dev/null 2>&1
[[ ! -d "$T/.pack-install-reconcile" ]] \
    && t_pass "11.replace writes NO .pack-install-reconcile/ dir (no merge row)" \
    || t_fail "11.replace unexpectedly created .pack-install-reconcile/"
[[ ! -e "$T/CLAUDE.md.pack-template" ]] \
    && t_pass "11.replace writes NO .pack-template (r is a live overwrite, not keep)" \
    || t_fail "11.replace unexpectedly wrote a .pack-template"
rm -rf "$T"

# N1 guard: a pre-existing <f>.user-orig ⇒ fail_stage LOUD.
T=$(make_target)
printf 'C hand\n' > "$T/CLAUDE.md"
printf 'stale pre-existing sidecar\n' > "$T/CLAUDE.md.user-orig"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] \
    && t_pass "11.N1 pre-existing .user-orig ⇒ non-zero (fail_stage LOUD, rc=$rc)" \
    || t_fail "11.N1 pre-existing .user-orig did NOT fail (silent overwrite risk)"
assert_contains "11.N1 fail message names the pre-existing sidecar" "$out" "pre-existing sidecar"
if grep -q 'stale pre-existing sidecar' "$T/CLAUDE.md.user-orig"; then
    t_pass "11.N1 pre-existing .user-orig left byte-untouched (no silent overwrite)"
else
    t_fail "11.N1 pre-existing .user-orig was overwritten"
fi
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 12: BD-285 BLOCKER-1 lone-CLAUDE.md absent-sibling (merge + replace).
# A committed fixture with ONLY CLAUDE.md (distinctive bytes), NO AGENTS.md /
# GEMINI.md, NO populated dot-dirs. Guided merge/replace must NOT crash under
# `set -euo pipefail`: exit 0; CLAUDE.md.user-orig == snapshot; live CLAUDE.md
# == pack; the absent siblings install fresh == pack with NO .user-orig; the
# dispositions.tsv (merge) carries a merge-2way row for CLAUDE.md ONLY.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 12: BD-285 BLOCKER-1 lone-CLAUDE.md absent siblings ===\n"

for choice in merge replace; do
    T=$(make_target)
    printf 'LONE CLAUDE distinctive %s 42424\n' "$choice" > "$T/CLAUDE.md"
    commit_target "$T"
    snap=$(mktemp "${TMPDIR:-/tmp}/bd285-lone.XXXXXX")
    cp "$T/CLAUDE.md" "$snap"
    out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity="$choice" "$T" 2>&1) ; rc=$?
    assert_eq "12.$choice lone-CLAUDE guided install exit 0 (no crash under set -euo pipefail)" "0" "$rc"
    if [[ -f "$T/CLAUDE.md.user-orig" ]] && cmp -s "$T/CLAUDE.md.user-orig" "$snap"; then
        t_pass "12.$choice CLAUDE.md.user-orig == snapshot"
    else
        t_fail "12.$choice CLAUDE.md.user-orig missing or != snapshot"
    fi
    cmp -s "$T/CLAUDE.md" "$REPO_ROOT/project-template/CLAUDE.md" \
        && t_pass "12.$choice live CLAUDE.md == pack template" \
        || t_fail "12.$choice live CLAUDE.md != pack template"
    for sib in AGENTS.md GEMINI.md; do
        if cmp -s "$T/$sib" "$REPO_ROOT/project-template/$sib" && [[ ! -e "$T/$sib.user-orig" ]]; then
            t_pass "12.$choice absent sibling $sib installed fresh == pack, NO .user-orig"
        else
            t_fail "12.$choice absent sibling $sib wrong (missing, != pack, or spurious .user-orig)"
        fi
    done
    if [[ "$choice" == "merge" ]]; then
        rows=$(awk -F'\t' '$2=="trinity" && $4=="merge-2way"' "$T/.pack-install-reconcile/dispositions.tsv" 2>/dev/null)
        n=$(printf '%s\n' "$rows" | grep -c . | tr -d ' ')
        assert_eq "12.merge exactly 1 merge-2way row (CLAUDE.md only)" "1" "$n"
        printf '%s\n' "$rows" | grep -q 'CLAUDE.md' \
            && t_pass "12.merge the sole merge-2way row is for CLAUDE.md" \
            || t_fail "12.merge merge-2way row not for CLAUDE.md"
        printf '%s\n' "$rows" | grep -qE 'AGENTS.md|GEMINI.md' \
            && t_fail "12.merge unexpected merge-2way row for a fresh-installed sibling" \
            || t_pass "12.merge no merge-2way row for a fresh-installed sibling"
    else
        [[ ! -d "$T/.pack-install-reconcile" ]] \
            && t_pass "12.replace no .pack-install-reconcile/ dir (r writes no row)" \
            || t_fail "12.replace unexpectedly created .pack-install-reconcile/"
    fi
    rm -f "$snap"; rm -rf "$T"
done

# ─────────────────────────────────────────────────────────────────────────
# Group 13: BD-285 P0 dirty die-message + P1 shape-guard + P2 --trinity /
# null-choice STOP.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 13: BD-285 P0 / P1 / P2 ===\n"

# P0: a dirty target (uncommitted starter trinity) hits EXIT_DIRTY (=12) and
# the die names the trinity/starter case + the one-step workaround.
T=$(make_target)
printf 'uncommitted starter\n' > "$T/CLAUDE.md"   # dirty (not committed)
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" 2>&1) ; rc=$?
assert_eq "13.P0 dirty target exit 12 (EXIT_DIRTY, gate unchanged)" "12" "$rc"
assert_contains "13.P0 die names the starter trinity case" "$out" "starter trinity"
assert_contains "13.P0 die names the one-step commit workaround" "$out" "git add -A && git commit"
rm -rf "$T"

# P1: trinity file + a bare dot-dir ⇒ guided (installs). A POPULATED foreign
# tree (.claude/agents non-empty) ⇒ STOP (exit 20), no v11 layered.
T=$(make_target)
printf 'hand\n' > "$T/CLAUDE.md"; mkdir -p "$T/.claude"   # bare dot-dir
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=keep "$T" 2>&1) ; rc=$?
assert_eq "13.P1 trinity + bare .claude/ ⇒ guided install rc=0" "0" "$rc"
[[ -d "$T/docs/pack" ]] \
    && t_pass "13.P1 guided install layered v11 (docs/pack present)" \
    || t_fail "13.P1 guided install did not layer v11"
rm -rf "$T"

T=$(make_target)
printf 'hand\n' > "$T/CLAUDE.md"; mkdir -p "$T/.claude/agents"; printf 'foreign\n' > "$T/.claude/agents/a.md"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" 2>&1) ; rc=$?
assert_eq "13.P1 populated foreign .claude/agents ⇒ STOP exit 20" "20" "$rc"
[[ ! -d "$T/docs/pack" ]] \
    && t_pass "13.P1 populated foreign tree ⇒ NO v11 layered" \
    || t_fail "13.P1 v11 was layered over a populated foreign tree"
assert_contains "13.P1 STOP names the foreign agent/skill tree" "$out" "POPULATED foreign agent/skill tree"
rm -rf "$T"

# P2: non-TTY --trinity=merge is HONORED (independent of prompt_should_interact).
T=$(make_target)
printf 'P2 distinctive\n' > "$T/CLAUDE.md"
commit_target "$T"
snap=$(mktemp "${TMPDIR:-/tmp}/bd285-p2.XXXXXX"); cp "$T/CLAUDE.md" "$snap"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" </dev/null 2>&1) ; rc=$?
assert_eq "13.P2 non-TTY --trinity=merge HONORED (rc=0, installs)" "0" "$rc"
cmp -s "$T/CLAUDE.md.user-orig" "$snap" \
    && t_pass "13.P2 non-TTY --trinity=merge captured OURS to .user-orig" \
    || t_fail "13.P2 non-TTY --trinity=merge did not honor the merge choice"
rm -f "$snap"; rm -rf "$T"

# P2/F5: --yes + non-TTY + NO --trinity ⇒ STOP with the trinity byte-untouched
# (never the bare cp path).
T=$(make_target)
printf 'DO NOT TOUCH ME 55555\n' > "$T/CLAUDE.md"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes "$T" </dev/null 2>&1) ; rc=$?
assert_eq "13.P2 --yes + non-TTY + no --trinity ⇒ STOP exit 20 (F5)" "20" "$rc"
if grep -q 'DO NOT TOUCH ME 55555' "$T/CLAUDE.md" && [[ ! -e "$T/CLAUDE.md.user-orig" && ! -e "$T/AGENTS.md" ]]; then
    t_pass "13.P2 STOP left the trinity byte-untouched (no bare cp, no sidecar, no sibling)"
else
    t_fail "13.P2 STOP mutated the trinity (bare cp / sidecar / sibling appeared)"
fi
rm -rf "$T"

# --trinity value validation.
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --trinity=bogus "$(make_target)" 2>&1) ; rc=$?
[[ "$rc" -ne 0 ]] \
    && t_pass "13.val --trinity=bogus rejected (rc=$rc)" \
    || t_fail "13.val --trinity=bogus accepted"
assert_contains "13.val --trinity=bogus typed error" "$out" "invalid --trinity value"

# ─────────────────────────────────────────────────────────────────────────
# Group 14: BD-285 P5 structured key-union + F6 parse-error fallback +
# interactive menu path. A handwritten-trinity existing-source target
# (pyproject.toml language marker) with pre-existing structured configs.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 14: BD-285 P5 structured key-union + F6 ===\n"

# Valid collisions across the driven-off-classifier set: settings.json (json),
# .agents/mcp_config.json (json), .codex/requirements.toml (toml),
# .codex/config.toml.example (.example sibling).
T=$(make_target)
mkdir -p "$T/.claude" "$T/.agents" "$T/.codex"
printf '[project]\nname = "x"\n' > "$T/pyproject.toml"
printf 'handwritten trinity\n' > "$T/CLAUDE.md"
printf '{"$schema":"MINE","env":{"XCODE_SCHEME":"MyScheme"},"myProjectKey":"keepme"}\n' > "$T/.claude/settings.json"
printf '{"mcpServers":{"myserver":{"command":"foo"}},"projOnly":"keepme2"}\n' > "$T/.agents/mcp_config.json"
printf '[session]\nrequire_plan_for_non_trivial_work = false\n[myproj]\nkey = 1\n' > "$T/.codex/requirements.toml"
printf '# example\n[myexample]\nk = 2\n' > "$T/.codex/config.toml.example"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=keep "$T" 2>&1) ; rc=$?
assert_eq "14.1 existing-source guided install rc=0" "0" "$rc"
# settings.json (json): OURS wins conflict, pack-only key added, project key kept.
grep -q '"myProjectKey"' "$T/.claude/settings.json" \
    && t_pass "14.1 settings.json: project-only key kept" || t_fail "14.1 settings.json project key dropped"
grep -q '"MINE"' "$T/.claude/settings.json" \
    && t_pass "14.1 settings.json: OURS wins the \$schema scalar conflict" || t_fail "14.1 settings.json OURS did not win"
grep -q '"permissions"' "$T/.claude/settings.json" \
    && t_pass "14.1 settings.json: pack-only key added" || t_fail "14.1 settings.json pack key not added"
[[ ! -e "$T/.claude/settings.json.pack-template" ]] \
    && t_pass "14.1 settings.json: merged in place (no .pack-template sidecar)" \
    || t_fail "14.1 settings.json wrote a .pack-template (should be a clean/warn merge)"
# .agents/mcp_config.json (json) — the driven-off-classifier coverage.
grep -q 'myserver' "$T/.agents/mcp_config.json" \
    && t_pass "14.2 mcp_config.json: project server kept" || t_fail "14.2 mcp_config.json project server dropped"
grep -q 'local-rag' "$T/.agents/mcp_config.json" \
    && t_pass "14.2 mcp_config.json: pack server added" || t_fail "14.2 mcp_config.json pack server not added"
# .codex/requirements.toml (toml) — the driven-off-classifier coverage.
grep -q 'require_plan_for_non_trivial_work = false' "$T/.codex/requirements.toml" \
    && t_pass "14.3 requirements.toml: OURS wins the scalar conflict" || t_fail "14.3 requirements.toml OURS did not win"
grep -q '\[myproj\]' "$T/.codex/requirements.toml" \
    && t_pass "14.3 requirements.toml: project section kept" || t_fail "14.3 requirements.toml project section dropped"
grep -q '\[policy\]' "$T/.codex/requirements.toml" \
    && t_pass "14.3 requirements.toml: pack section added" || t_fail "14.3 requirements.toml pack section not added"
# .example sibling routed through the key-union too.
grep -q '\[myexample\]' "$T/.codex/config.toml.example" \
    && t_pass "14.4 .example sibling: project section kept (routed through key-union)" \
    || t_fail "14.4 .example sibling project section dropped"
# no throwaway probe dir leaked into TMPDIR.
if ls -d "${TMPDIR:-/tmp}"/pack-s3-probe.* >/dev/null 2>&1; then
    t_fail "14.5 throwaway probe dir leaked into TMPDIR"
else
    t_pass "14.5 no throwaway probe dir leaked (SHOULD-2 lifecycle)"
fi
# keep-choice writes no persistent reconcile dir.
[[ ! -d "$T/.pack-install-reconcile" ]] \
    && t_pass "14.6 no .pack-install-reconcile/ dir (keep + structured merges, no trinity merge)" \
    || t_fail "14.6 unexpected .pack-install-reconcile/ dir on a no-trinity-merge install"
rm -rf "$T"

# F6: a MALFORMED existing settings.json falls back to user-live + .pack-template
# (NOT silent THEIRS-adoption).
T=$(make_target)
mkdir -p "$T/.claude"
printf '[project]\nname = "x"\n' > "$T/pyproject.toml"
printf 'handwritten\n' > "$T/CLAUDE.md"
printf '{ this is : not valid json \n' > "$T/.claude/settings.json"
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=keep "$T" 2>&1) ; rc=$?
assert_eq "14.7 F6 install rc=0 (parse-error path does not abort)" "0" "$rc"
grep -q 'not valid json' "$T/.claude/settings.json" \
    && t_pass "14.7 F6: user file stays LIVE (malformed, untouched)" \
    || t_fail "14.7 F6: user file was overwritten"
[[ -f "$T/.claude/settings.json.pack-template" ]] \
    && t_pass "14.7 F6: pack template preserved at .pack-template" \
    || t_fail "14.7 F6: no .pack-template written"
grep -q 'schemastore' "$T/.claude/settings.json" \
    && t_fail "14.7 F6: THEIRS silently adopted into the live file (must NOT happen)" \
    || t_pass "14.7 F6: NO silent THEIRS-adoption (live file is not the pack template)"
rm -rf "$T"

# Interactive menu path: PACK_PROMPT_FORCE_INTERACTIVE + piped `m` (choice) then
# `y` (confirm) installs via the guided merge branch (human path survives).
T=$(make_target)
printf 'INTERACTIVE distinctive 77777\n' > "$T/CLAUDE.md"
commit_target "$T"
snap=$(mktemp "${TMPDIR:-/tmp}/bd285-int.XXXXXX"); cp "$T/CLAUDE.md" "$snap"
out=$(printf 'm\ny\n' | PACK="$REPO_ROOT" PACK_PROMPT_FORCE_INTERACTIVE=1 \
    bash "$INIT_SH" "$T" 2>&1) ; rc=$?
assert_eq "14.8 interactive menu (m + confirm y) rc=0" "0" "$rc"
cmp -s "$T/CLAUDE.md.user-orig" "$snap" \
    && t_pass "14.8 interactive merge captured OURS to .user-orig" \
    || t_fail "14.8 interactive merge did not capture OURS"
cmp -s "$T/CLAUDE.md" "$REPO_ROOT/project-template/CLAUDE.md" \
    && t_pass "14.8 interactive merge overwrote live CLAUDE.md with the pack template" \
    || t_fail "14.8 interactive merge did not overwrite the live file"
rm -f "$snap"; rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 14 (Finding-1 regression): a GUIDED install on a handwritten-trinity
# target that reclassifies to new-empty (a lone user structured config, NO
# language marker) must PROTECT the user's config via the S3 structured
# key-union — NOT silently plain-cp-overwrite it. This is the missing
# coverage that let the new-*-reclassification silent-overwrite defect
# through: every other Group-14 test seeds pyproject.toml (existing-source),
# so the CLASS-gated S3 branch always took the protected path. Here there is
# NO language marker and NO README ⇒ classify_project_state_no_ai returns
# new-empty ⇒ pre-fix S3 fell to the plain-cp else-arm and destroyed the
# user's settings.json with no .user-orig / no .pack-template / no warning.
# ─────────────────────────────────────────────────────────────────────────
T=$(make_target)
mkdir -p "$T/.claude"
printf 'handwritten starter trinity\n' > "$T/CLAUDE.md"
# Distinctive user key + a user-owned $schema scalar to prove OURS-wins.
printf '{"$schema":"MINE","myProjectKey":"KEEP_ME_NEWSTAR_98765"}\n' > "$T/.claude/settings.json"
# NO pyproject.toml / Package.swift / package.json / README ⇒ new-empty class.
commit_target "$T"
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" --yes --trinity=merge "$T" 2>&1) ; rc=$?
assert_eq "14.9 new-* guided merge install rc=0" "0" "$rc"
# Fixture actually exercises the reclassification path (guards the test from
# silently drifting off the vulnerable branch if the classifier changes).
assert_contains "14.9 fixture reclassifies to new-empty (exercises the vulnerable S3 path)" \
    "$out" "Classification:  new-empty"
# THE load-bearing assertion — RED against the pre-fix CLASS-gated S3, GREEN
# after routing the guided branch through the protected s3_config_copy.
grep -q 'KEEP_ME_NEWSTAR_98765' "$T/.claude/settings.json" \
    && t_pass "14.9 new-* guided: user settings.json key PRESERVED (no silent overwrite)" \
    || t_fail "14.9 new-* guided: user settings.json key LOST (silent plain-cp overwrite)"
# $schema OURS-wins scalar conflict — proves a key-union merge, not a plain cp.
grep -q '"MINE"' "$T/.claude/settings.json" \
    && t_pass "14.9 new-* guided: OURS wins the \$schema scalar conflict (key-union merge)" \
    || t_fail "14.9 new-* guided: OURS did not win (pack \$schema clobbered the user's)"
# Merged in place — no sidecar (structured key-union fired, not the F6 fallback).
[[ ! -e "$T/.claude/settings.json.pack-template" ]] \
    && t_pass "14.9 new-* guided: merged in place (no .pack-template sidecar)" \
    || t_fail "14.9 new-* guided: wrote a .pack-template (structured key-union did not fire)"
rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 15: map-derived --update dispatch + the BASE cascade
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 15: map-derived dispatch + BASE cascade ===\n"

# A writable PACK copy, so a test can mutate a pack SOURCE without touching
# the real tree. `.git` is deliberately not copied — this checkout may be a
# worktree, whose `.git` is a gitfile pointing elsewhere — so the copy gets a
# fresh history instead. Everything is committed because family expansion
# draws its candidate set from `git ls-files`, and the provenance baseline
# anchor is re-pointed at that history: the real `v10` anchor does not exist
# in a fresh copy, and without a reachable anchor R4' would fire run-wide and
# the cascade under test would never run.
make_pack_copy() {
    local d e
    d=$(mktemp -d "${TMPDIR:-/tmp}/c6-pack.XXXXXX")
    for e in "$REPO_ROOT"/*; do
        cp -R "$e" "$d/" 2>/dev/null
    done
    for e in .gitignore .gitattributes; do
        if [[ -f "$REPO_ROOT/$e" ]]; then cp "$REPO_ROOT/$e" "$d/"; fi
    done
    git init -q "$d" >/dev/null 2>&1
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"
    git -C "$d" add -A >/dev/null 2>&1
    git -C "$d" commit -q -m "pack copy" >/dev/null 2>&1
    printf '%s\n' "$d"
}

# Count sidecars the way cmd_update's own stale-sidecar pre-check counts them.
count_sidecars() {
    find "$1" -type f -name '*.pre-update' \
        -not -path '*/.pack-update/*' -not -path '*/.git/*' 2>/dev/null \
        | wc -l | tr -d ' '
}

# Column $2 of the dispositions row whose rel_path (column 3) is $3.
disp_col() {
    awk -F '\t' -v c="$2" -v want="$3" '$3 == want { print $c; exit }' "$1"
}

PACKC=$(make_pack_copy)
export PACK_PROVENANCE_BASELINE_REF=HEAD

# ── T-IDEM + T-PROMPTS-REACH + T-SKILLS-REACH share one installed client ──
T=$(make_target)
PACK="$PACKC" bash "$INIT_SH" --yes "$T" >/dev/null 2>&1
assert_eq "15.0 fixture install rc=0" "0" "$?"
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" commit -q -m "installed" >/dev/null 2>&1

# 15.1 T-IDEM — two --update runs, with NO sidecar deletion between them.
PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.1 T-IDEM run 1 rc=0" "0" "$?"
DTSV="$T/.pack-update/dispositions.tsv"

# The dispatch set really is the WIDENED one: both families that no copy site
# reached before are present, and so is the dotfile a bare `*` would drop.
# Without these the idempotence claim would be measured at the old, narrower
# set and would prove nothing about the new one.
n_prompts=$(awk -F '\t' '$3 ~ /^docs\/pack\/prompts\//' "$DTSV" | wc -l | tr -d ' ')
n_skills=$(awk -F '\t' '$3 ~ /skills\/.*SKILL\.md$/' "$DTSV" | wc -l | tr -d ' ')
n_dotfile=$(awk -F '\t' '$3 == "scripts/.docs-gate-allowlist.txt"' "$DTSV" | wc -l | tr -d ' ')
[[ "$n_prompts" -gt 0 ]] \
    && t_pass "15.1 dispatch reaches docs/pack/prompts/ ($n_prompts rows)" \
    || t_fail "15.1 dispatch reaches docs/pack/prompts/" "0 rows"
[[ "$n_skills" -gt 0 ]] \
    && t_pass "15.1 dispatch reaches per-CLI skills ($n_skills rows)" \
    || t_fail "15.1 dispatch reaches per-CLI skills" "0 rows"
[[ "$n_dotfile" -eq 1 ]] \
    && t_pass "15.1 dispatch reaches the scripts/ dotfile (family glob keeps dotfiles)" \
    || t_fail "15.1 dispatch reaches the scripts/ dotfile" "got $n_dotfile rows"

PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.1 T-IDEM run 2 rc=0" "0" "$?"
assert_eq "15.1 T-IDEM run 2 leaves 0 sidecars on disk" "0" "$(count_sidecars "$T")"
nr=$(grep -c "needs-reconciliation" "$DTSV" 2>/dev/null || true)
assert_eq "15.1 T-IDEM run 2 records 0 needs-reconciliation" "0" "$nr"

# 15.2 T-PROMPTS-REACH / 15.3 T-SKILLS-REACH — mutate a pack prompt and a
# pool skill, then prove each mutation reaches the installed client. The map
# rows are the only thing that dispatches either family.
printf '\nC6_PROMPT_MUTATION_MARKER\n' \
    >> "$PACKC/project-template/docs/pack/prompts/coder.md"
printf '\nC6_SKILL_MUTATION_MARKER\n' \
    >> "$PACKC/project-template/skills/review/SKILL.md"
git -C "$PACKC" add -A >/dev/null 2>&1
git -C "$PACKC" commit -q -m "pack mutation" >/dev/null 2>&1

PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.2 --update after pack mutation rc=0" "0" "$?"

grep -q 'C6_PROMPT_MUTATION_MARKER' "$T/docs/pack/prompts/coder.md" 2>/dev/null \
    && t_pass "15.2 T-PROMPTS-REACH: prompt mutation reached the client" \
    || t_fail "15.2 T-PROMPTS-REACH: prompt mutation did NOT reach the client"

# This client has already run --update twice, so a ledger EXISTS and rung R1
# wins: BASE is the blob the previous run installed here, which is a more
# precise baseline than R2's. BASE == OURS still yields pack-update-applied
# with no sidecar; the notes column stays `-` because no R2 overwrite of
# client bytes happened. The notes column is what tells the two rungs apart.
assert_eq "15.2 R1 fired for the prompt (pack-update-applied)" \
    "pack-update-applied" "$(disp_col "$DTSV" 1 'docs/pack/prompts/coder.md')"
assert_eq "15.2 R1 wrote no sidecar for the prompt" \
    "-" "$(disp_col "$DTSV" 5 'docs/pack/prompts/coder.md')"
assert_eq "15.2 R1 (not R2) — notes carries no blob-recovery hint" \
    "-" "$(disp_col "$DTSV" 7 'docs/pack/prompts/coder.md')"

miss=0
for tool in claude codex agents; do
    grep -q 'C6_SKILL_MUTATION_MARKER' "$T/.$tool/skills/review/SKILL.md" 2>/dev/null \
        || miss=1
done
[[ "$miss" -eq 0 ]] \
    && t_pass "15.3 T-SKILLS-REACH: skill mutation reached ALL THREE per-CLI copies" \
    || t_fail "15.3 T-SKILLS-REACH: at least one per-CLI skill copy missed the mutation"
rm -rf "$T"

# 15.2b Rung R2 in isolation — a client with NO prior ledger, whose installed
# bytes ARE a blob the pack has held at that source path. R1 cannot fire, so
# R2 must: BASE becomes OURS itself, the file adopts THEIRS with no sidecar,
# and the OURS blob sha is recorded so the overwrite stays recoverable.
T=$(make_target)
PACK="$PACKC" bash "$INIT_SH" --yes "$T" >/dev/null 2>&1
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" commit -q -m "installed" >/dev/null 2>&1
# Self-check: this fixture only tests R2 if no ledger is reachable.
[[ ! -f "$T/.pack-update/ledger.tsv" && ! -f "$T/.pack-install-reconcile/ledger.tsv" ]] \
    && t_pass "15.2b fixture has no prior ledger (R1 cannot fire)" \
    || t_fail "15.2b fixture already has a ledger — this would test R1, not R2"

printf '\nC6_PROMPT_MUTATION_MARKER_2\n' \
    >> "$PACKC/project-template/docs/pack/prompts/coder.md"
git -C "$PACKC" add -A >/dev/null 2>&1
git -C "$PACKC" commit -q -m "pack mutation 2" >/dev/null 2>&1

PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.2b --update rc=0" "0" "$?"
DTSV="$T/.pack-update/dispositions.tsv"
assert_eq "15.2b R2 fired (pack-update-applied)" \
    "pack-update-applied" "$(disp_col "$DTSV" 1 'docs/pack/prompts/coder.md')"
assert_eq "15.2b R2 wrote no sidecar" \
    "-" "$(disp_col "$DTSV" 5 'docs/pack/prompts/coder.md')"
assert_contains "15.2b R2 recorded the OURS blob sha in notes" \
    "$(disp_col "$DTSV" 7 'docs/pack/prompts/coder.md')" "cat-file blob"
# The recorded sha must actually resolve to the client's pre-update bytes —
# that is the whole reason R2 is allowed to overwrite without a sidecar.
r2_sha=$(disp_col "$DTSV" 7 'docs/pack/prompts/coder.md' | awk '{print $NF}')
if git -C "$PACKC" cat-file blob "$r2_sha" 2>/dev/null \
     | grep -q 'C6_PROMPT_MUTATION_MARKER'; then
    t_pass "15.2b R2 sha resolves to the overwritten client bytes (recoverable)"
else
    t_fail "15.2b R2 sha does not resolve to the overwritten client bytes"
fi
grep -q 'C6_PROMPT_MUTATION_MARKER_2' "$T/docs/pack/prompts/coder.md" 2>/dev/null \
    && t_pass "15.2b R2 adopted the pack update" \
    || t_fail "15.2b R2 did not adopt the pack update"
rm -rf "$T"

# 15.4 T-R3-opposite — the probe cannot prove the client's bytes are
# pack-authored, so BASE stays EMPTY. The verdict MUST be
# needs-reconciliation with BOTH a sidecar and a diff. A cascade that resolved
# this rung to `merged-with-customization` would keep the client's stale file,
# adopt nothing, and write neither column.
T=$(make_target)
PACK="$PACKC" bash "$INIT_SH" --yes "$T" >/dev/null 2>&1
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" commit -q -m "installed" >/dev/null 2>&1

# A client edit whose bytes the pack has never held anywhere in its history.
printf '\nC6_CLIENT_LOCAL_EDIT_NEVER_IN_PACK_HISTORY\n' \
    >> "$T/docs/pack/METHODOLOGY.md"
# A pack edit on the same file, so OURS and THEIRS genuinely differ.
printf '\nC6_PACK_SIDE_EDIT\n' >> "$PACKC/supporting-docs/METHODOLOGY.md"
git -C "$PACKC" add -A >/dev/null 2>&1
git -C "$PACKC" commit -q -m "pack methodology edit" >/dev/null 2>&1

PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.4 --update rc=0" "0" "$?"
DTSV="$T/.pack-update/dispositions.tsv"
assert_eq "15.4 T-R3-opposite: token is needs-reconciliation (NOT merged-with-customization)" \
    "customization-detected-needs-reconciliation" \
    "$(disp_col "$DTSV" 1 'docs/pack/METHODOLOGY.md')"
sidecar_col=$(disp_col "$DTSV" 5 'docs/pack/METHODOLOGY.md')
diff_col=$(disp_col "$DTSV" 6 'docs/pack/METHODOLOGY.md')
[[ -n "$sidecar_col" && "$sidecar_col" != "-" ]] \
    && t_pass "15.4 T-R3-opposite: sidecar column is non-'-'" \
    || t_fail "15.4 T-R3-opposite: sidecar column is '-'" "got '$sidecar_col'"
[[ -n "$diff_col" && "$diff_col" != "-" ]] \
    && t_pass "15.4 T-R3-opposite: diff column is non-'-'" \
    || t_fail "15.4 T-R3-opposite: diff column is '-'" "got '$diff_col'"
grep -q 'C6_CLIENT_LOCAL_EDIT_NEVER_IN_PACK_HISTORY' \
    "$T/docs/pack/METHODOLOGY.md.pre-update" 2>/dev/null \
    && t_pass "15.4 T-R3-opposite: the client's bytes survive in the sidecar" \
    || t_fail "15.4 T-R3-opposite: the client's bytes are NOT in the sidecar"
rm -rf "$T"

# 15.5 T-CLASS-SCOPE — a structured config keeps EMPTY-BASE dispatch, so a
# client-edited file still goes through the key-union and still gains the
# pack's NEW keys.
#
# The scenario is built so a cascade wrongly widened to structured classes
# would FAIL it: run 1 leaves a ledger row holding the blob of the CURRENT
# pack file, and the client then edits that file. A widened cascade would
# resolve BASE from that ledger row, and because BASE == THEIRS the classifier
# answers `merged-with-customization`, which _cp_strategy_structured returns
# on BEFORE reaching the key-merge — so `pack_new_key` would never arrive.
# With the gate in place BASE stays empty and the key-union runs.
T=$(make_target)
REQ="$PACKC/project-template/.codex/requirements.toml"
REQ_ORIG=$(mktemp "${TMPDIR:-/tmp}/c6-req.XXXXXX")
cp "$REQ" "$REQ_ORIG"
PACK="$PACKC" bash "$INIT_SH" --yes "$T" >/dev/null 2>&1
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" commit -q -m "installed" >/dev/null 2>&1

# The pack ships a new key; run 1 adopts it AND records the ledger row.
printf '\n[c6_scope]\npack_new_key = "ARRIVED"\n' >> "$REQ"
git -C "$PACKC" add -A >/dev/null 2>&1
git -C "$PACKC" commit -q -m "pack toml key" >/dev/null 2>&1
PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.5 run 1 rc=0" "0" "$?"
[[ -f "$T/.pack-update/ledger.tsv" ]] \
    && t_pass "15.5 run 1 wrote the R1 ledger" \
    || t_fail "15.5 run 1 wrote the R1 ledger" "ledger.tsv missing"
grep -q '\.codex/requirements\.toml' "$T/.pack-update/ledger.tsv" 2>/dev/null \
    && t_pass "15.5 ledger holds a row for the structured config" \
    || t_fail "15.5 ledger holds a row for the structured config"

# The client rewrites the file: its OWN key, and no pack_new_key.
cp "$REQ_ORIG" "$T/.codex/requirements.toml"
printf '\n[c6_client]\nclient_key = "KEPT"\n' >> "$T/.codex/requirements.toml"
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" commit -q -m "client edit" >/dev/null 2>&1

PACK="$PACKC" bash "$INIT_SH" --update "$T" >/dev/null 2>&1
assert_eq "15.5 run 2 rc=0" "0" "$?"
grep -q 'pack_new_key' "$T/.codex/requirements.toml" \
    && t_pass "15.5 T-CLASS-SCOPE: the pack's NEW key arrived via the key-union" \
    || t_fail "15.5 T-CLASS-SCOPE: the pack's NEW key did NOT arrive (cascade leaked into a structured class)"
grep -q 'client_key' "$T/.codex/requirements.toml" \
    && t_pass "15.5 T-CLASS-SCOPE: the client's own key was kept" \
    || t_fail "15.5 T-CLASS-SCOPE: the client's own key was lost"
# A TOML round trip through a dict drops every comment unless they are
# re-attached, so the merged file must still carry them.
[[ "$(grep -c '^[[:space:]]*#' "$T/.codex/requirements.toml")" -gt 0 ]] \
    && t_pass "15.5 T-CLASS-SCOPE: comments survived the structured merge" \
    || t_fail "15.5 T-CLASS-SCOPE: the structured merge stripped every comment"
rm -f "$REQ_ORIG"
rm -rf "$T"
rm -rf "$PACKC"
unset PACK_PROVENANCE_BASELINE_REF

# 15.5b The structured merge above keys each comment block by the construct it
# precedes, and a construct is recognised by LINE SHAPE. A multi-line array
# holding bracketed elements is the shape that breaks a leading-`[` test: the
# element line looks like a table header, so the section moves to a table that
# does not exist and every later comment in the real table is keyed somewhere
# the merged output never mentions. Asserted directly against the merge helper,
# because the end-to-end leg above cannot reach the shape — no pack-shipped
# TOML nests an array today, and a client edit is what would introduce one.
MTD=$(mktemp -d "${TMPDIR:-/tmp}/init-mergetoml.XXXXXX")
cat > "$MTD/base.toml" <<'MT_EOF'
# file header

[t]
m = [
  [1, 2],
  [3, 4],
]
# comment above zz
zz = 5
MT_EOF
cp "$MTD/base.toml" "$MTD/ours.toml"
sed 's/^zz = 5$/zz = 5\nnewk = 9/' "$MTD/base.toml" > "$MTD/theirs.toml"
python3 "$REPO_ROOT/scripts/merge-toml.py" \
    "$MTD/base.toml" "$MTD/ours.toml" "$MTD/theirs.toml" > "$MTD/out.toml" 2>/dev/null
assert_eq "15.5b the nested-array merge succeeds" "0" "$?"
grep -q 'comment above zz' "$MTD/out.toml" \
    && t_pass "15.5b a comment after a nested multi-line array survives" \
    || t_fail "15.5b the comment after a nested array was dropped" "$(cat "$MTD/out.toml")"
# DISCRIMINATION: the header is keyed by a different mechanism (it precedes
# the first construct), so it would survive even with the section broken —
# and the merged value must still be the union, not just a comment carrier.
grep -q '^# file header' "$MTD/out.toml" \
    && t_pass "15.5b the file header survives (separate mechanism, still intact)" \
    || t_fail "15.5b the file header was dropped"
grep -q 'newk' "$MTD/out.toml" \
    && t_pass "15.5b the merge still unions the incoming key" \
    || t_fail "15.5b the incoming key was lost"
python3 -c "import sys,tomllib;tomllib.load(open(sys.argv[1],'rb'))" "$MTD/out.toml" 2>/dev/null \
    && t_pass "15.5b the merged output is still valid TOML" \
    || t_fail "15.5b the merged output no longer parses" "$(cat "$MTD/out.toml")"
rm -rf "$MTD"

# 15.6 T-ARMS — table-driven: every disposition arm's terminal DEST is one of
# {untouched OURS, THEIRS, a merge that preserved OURS in a sidecar}. This is
# the mechanical form of the idempotence proof — no arm may leave DEST holding
# content that is neither side and is recorded nowhere.
export _CP_PACK_ROOT="$REPO_ROOT"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/three-way.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/customization-preserve.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/customization-report.sh"

ARMS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/c6-arms.XXXXXX")
customization_preserve_init "$ARMS_DIR/state" ".pre-update" >/dev/null 2>&1

# arm|base|ours|theirs|expected DEST token|expected sidecar
#   a content field of `-` means that side is ABSENT.
arms_table="
unchanged-pack|B|X|X|OURS|no
pack-update-applied|B|B|T|THEIRS|no
merged-with-customization|B|O|B|OURS|no
real-merge-required|B|O|T|MERGED|any
project-shadows-new-pack|-|O|T|THEIRS|yes
new-file-in-pack|-|-|T|THEIRS|no
project-only-file|-|O|-|OURS|no
"

while IFS='|' read -r arm base_c ours_c theirs_c want_dest want_sc; do
    [[ -n "$arm" ]] || continue
    d="$ARMS_DIR/$arm"
    mkdir -p "$d"
    base=""; ours=""; theirs=""
    if [[ "$base_c"   != "-" ]]; then base="$d/base";     printf 'content-%s\n' "$base_c"   > "$base"; fi
    if [[ "$ours_c"   != "-" ]]; then ours="$d/ours";     printf 'content-%s\n' "$ours_c"   > "$ours"; fi
    if [[ "$theirs_c" != "-" ]]; then theirs="$d/theirs"; printf 'content-%s\n' "$theirs_c" > "$theirs"; fi
    dest="$d/dest"
    # DEST starts as OURS — an in-place refresh is how every real call site runs.
    ours_arg=""
    if [[ -n "$ours" ]]; then cp "$ours" "$dest"; ours_arg="$dest"; fi

    customization_preserve "$base" "$ours_arg" "$theirs" "arms/$arm.md" "$dest" generic >/dev/null 2>&1

    got="ABSENT"
    if [[ -f "$dest" ]]; then
        got="MERGED"
        if [[ -n "$ours"   ]] && cmp -s "$dest" "$ours";   then got="OURS";   fi
        if [[ -n "$theirs" ]] && cmp -s "$dest" "$theirs"; then got="THEIRS"; fi
    fi
    # In the identity arm OURS and THEIRS are byte-equal, so either token names
    # the same bytes; normalise before comparing.
    if [[ "$want_dest" == "OURS" && "$got" == "THEIRS" && "$ours_c" == "$theirs_c" ]]; then
        got="OURS"
    fi
    assert_eq "15.6 T-ARMS $arm: terminal DEST" "$want_dest" "$got"

    sc="no"
    [[ -f "$dest.pre-update" ]] && sc="yes"
    if [[ "$want_sc" != "any" ]]; then
        assert_eq "15.6 T-ARMS $arm: sidecar" "$want_sc" "$sc"
    fi
    # Union invariant: whenever DEST is neither side verbatim, OURS must stay
    # recoverable — from a sidecar, or at minimum from a recorded disposition.
    if [[ "$got" == "MERGED" && "$sc" == "no" && -n "$ours" ]]; then
        if grep -q "arms/$arm.md" "$ARMS_DIR/state/dispositions.tsv"; then
            t_pass "15.6 T-ARMS $arm: merge recorded a disposition"
        else
            t_fail "15.6 T-ARMS $arm: merged DEST with no sidecar AND no record"
        fi
    fi
done <<< "$arms_table"
rm -rf "$ARMS_DIR"

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
