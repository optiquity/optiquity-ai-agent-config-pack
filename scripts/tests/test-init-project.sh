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
    d=$(mktemp -d -t init-tgt.XXXXXX)
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
[[ -f "$T/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
    && t_pass "2.5 HELP-FRAGMENT-TRACKER.md installed by --update" \
    || t_fail "2.5 HELP-FRAGMENT-TRACKER.md missing"

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
# yes-pipe to consume confirmation prompt; init-project asks "Proceed? (y/N)".
out=$(PACK="$REPO_ROOT" bash "$INIT_SH" "$T" <<<"y" 2>&1) ; rc=$?
assert_eq    "3.1 fresh install rc=0" "0" "$rc"
assert_contains "3.1 S11 stage ran" "$out" \
    "S11 — v11 client artifacts"

# v11 artifacts present.
[[ -f "$T/docs/pack/HELP-FRAGMENT.md" ]] \
    && t_pass "3.2 HELP-FRAGMENT.md present" \
    || t_fail "3.2 HELP-FRAGMENT.md missing"
[[ -f "$T/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
    && t_pass "3.2 HELP-FRAGMENT-TRACKER.md present" \
    || t_fail "3.2 HELP-FRAGMENT-TRACKER.md missing"
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
[[ -f "$T/.claude/skills/pack-help/SKILL.md" ]] \
    && t_pass "3.2 .claude/skills/pack-help/SKILL.md present" \
    || t_fail "3.2 .claude/skills/pack-help missing"
[[ -f "$T/.codex/skills/pack-help/SKILL.md" ]] \
    && t_pass "3.2 .codex/skills/pack-help/SKILL.md present" \
    || t_fail "3.2 .codex/skills/pack-help missing"
# BD-221: pack-help is a pool skill distributed LOOSE to the Antigravity
# workspace at .agents/skills/pack-help/SKILL.md (the former `.toml`
# command surface is retired).
[[ -f "$T/.agents/skills/pack-help/SKILL.md" ]] \
    && t_pass "3.2 .agents/skills/pack-help/SKILL.md present" \
    || t_fail "3.2 .agents/skills/pack-help missing"
# BD-221: the Antigravity workspace skills dir is populated by stage S4.
[[ -d "$T/.agents/skills" ]] \
    && t_pass "3.2 .agents/skills/ present (Antigravity workspace skills)" \
    || t_fail "3.2 .agents/skills/ missing"

# BD-193 F4/F5 + BD-194: client HELP-FRAGMENT-TRACKER.md install source is the
# project-template-side file (separate-artifact, separate-audience per pack memory
# feedback_pack_project_separation_of_concerns). The pack-side
# pack-ops/HELP-FRAGMENT-TRACKER.md is a SEPARATE artifact with a SEPARATE
# audience and is NOT the install source. Test asserts the install copy matches
# the project-template-side source (init-project.sh S11 contract per BD-193 F4/F5).
if cmp -s "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" "$T/docs/pack/HELP-FRAGMENT-TRACKER.md"; then
    t_pass "3.3 client HELP-FRAGMENT-TRACKER.md matches project-template-side install source (BD-193 F4/F5)"
else
    t_fail "3.3 install-source mismatch (expected: project-template/docs/pack/HELP-FRAGMENT-TRACKER.md)"
fi

# 3.4 (BD-097 audit B-1) pack-help.sh + lib/detect.sh installed in client,
# and `bash scripts/pack-help.sh` runs from the project root without
# needing PACK env or any pack-repo path resolution.
[[ -x "$T/scripts/pack-help.sh" ]] \
    && t_pass "3.4 scripts/pack-help.sh installed + executable" \
    || t_fail "3.4 pack-help.sh missing or not executable"
[[ -f "$T/scripts/lib/detect.sh" ]] \
    && t_pass "3.4 scripts/lib/detect.sh installed" \
    || t_fail "3.4 detect.sh missing"
help_out=$(cd "$T" && bash scripts/pack-help.sh 2>&1) ; help_rc=$?
assert_eq "3.4 pack-help.sh from project root rc=0" "0" "$help_rc"
assert_contains "3.4 pack-help.sh emits client-side header" "$help_out" \
    "Pack v11 — verb reference (this project)"

rm -rf "$T"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: BD-166 sub-step 6 (canonical per-entry templates) + sub-step 7
# (greenfield empty mirrors + empty seed _toc.md) — closes the
# PACK-REVIEW-BD-166-RETRO MUST finding 1 (test-not-in-CI heuristic).
#
# Per PACK-REVIEW-BD-166-RETRO §3 (what should be covered by CI):
#   - 7 canonical templates present after greenfield init (project-side
#     asymmetry: changelog has _format.md; backlog + implementation-plan
#     do not)
#   - 3 regenerated mirrors at parent docs/project/ (NOT inside the
#     stream subdirs)
#   - mirror byte-identity claim for backlog + implementation-plan
#     (cmp == 0 against _intro.md)
#   - changelog mirror shape: _intro.md + \n---\n\n + _format.md (per
#     scripts/lib/per-entry/mirror-generate.sh:159-167)
#   - 3 empty seed _toc.md files with `(empty — no entries)` payload
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: BD-166 per-entry tree skeleton (sub-steps 6+7) ===\n"

T=$(make_target)
PACK="$REPO_ROOT" bash "$INIT_SH" "$T" <<<"y" >/dev/null 2>&1 ; rc=$?
assert_eq "4.1 fresh install rc=0" "0" "$rc"

# 4.2 — seven canonical templates present (project-side asymmetry:
# changelog HAS _format.md; backlog + implementation-plan do NOT).
[[ -f "$T/docs/project/backlog/_rules.md" ]] \
    && t_pass "4.2 docs/project/backlog/_rules.md present" \
    || t_fail "4.2 docs/project/backlog/_rules.md missing"
[[ -f "$T/docs/project/backlog/_intro.md" ]] \
    && t_pass "4.2 docs/project/backlog/_intro.md present" \
    || t_fail "4.2 docs/project/backlog/_intro.md missing"
[[ ! -f "$T/docs/project/backlog/_format.md" ]] \
    && t_pass "4.2 docs/project/backlog/_format.md ABSENT (project-side asymmetry)" \
    || t_fail "4.2 docs/project/backlog/_format.md unexpectedly present (asymmetry violated)"

[[ -f "$T/docs/project/implementation-plan/_rules.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_rules.md present" \
    || t_fail "4.2 docs/project/implementation-plan/_rules.md missing"
[[ -f "$T/docs/project/implementation-plan/_intro.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_intro.md present" \
    || t_fail "4.2 docs/project/implementation-plan/_intro.md missing"
[[ ! -f "$T/docs/project/implementation-plan/_format.md" ]] \
    && t_pass "4.2 docs/project/implementation-plan/_format.md ABSENT (project-side asymmetry)" \
    || t_fail "4.2 docs/project/implementation-plan/_format.md unexpectedly present (asymmetry violated)"

[[ -f "$T/docs/project/changelog/_rules.md" ]] \
    && t_pass "4.2 docs/project/changelog/_rules.md present" \
    || t_fail "4.2 docs/project/changelog/_rules.md missing"
[[ -f "$T/docs/project/changelog/_intro.md" ]] \
    && t_pass "4.2 docs/project/changelog/_intro.md present" \
    || t_fail "4.2 docs/project/changelog/_intro.md missing"
[[ -f "$T/docs/project/changelog/_format.md" ]] \
    && t_pass "4.2 docs/project/changelog/_format.md present (project-side asymmetry)" \
    || t_fail "4.2 docs/project/changelog/_format.md missing (project-side asymmetry violated)"

# 4.3 — three regenerated mirrors at parent docs/project/ (NOT inside
# the stream subdirs; SHOULD finding 1's geographic-correctness claim).
[[ -f "$T/docs/project/BACKLOG.md" ]] \
    && t_pass "4.3 docs/project/BACKLOG.md mirror present at parent" \
    || t_fail "4.3 docs/project/BACKLOG.md missing"
[[ -f "$T/docs/project/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "4.3 docs/project/IMPLEMENTATION-PLAN.md mirror present at parent" \
    || t_fail "4.3 docs/project/IMPLEMENTATION-PLAN.md missing"
[[ -f "$T/docs/project/CHANGELOG.md" ]] \
    && t_pass "4.3 docs/project/CHANGELOG.md mirror present at parent" \
    || t_fail "4.3 docs/project/CHANGELOG.md missing"

# 4.3 (negative) — mirrors do NOT live inside the stream subdirs.
[[ ! -f "$T/docs/project/backlog/BACKLOG.md" ]] \
    && t_pass "4.3 no stray BACKLOG.md inside backlog/ subdir" \
    || t_fail "4.3 unexpected docs/project/backlog/BACKLOG.md"
[[ ! -f "$T/docs/project/implementation-plan/IMPLEMENTATION-PLAN.md" ]] \
    && t_pass "4.3 no stray IMPLEMENTATION-PLAN.md inside implementation-plan/ subdir" \
    || t_fail "4.3 unexpected docs/project/implementation-plan/IMPLEMENTATION-PLAN.md"
[[ ! -f "$T/docs/project/changelog/CHANGELOG.md" ]] \
    && t_pass "4.3 no stray CHANGELOG.md inside changelog/ subdir" \
    || t_fail "4.3 unexpected docs/project/changelog/CHANGELOG.md"

# 4.4 — mirror byte-identity claim for backlog + implementation-plan
# (empty streams; mirror == _intro.md verbatim per mirror-generate.sh
# "no prior mirror → fresh write" + intro-only emit). Changelog has the
# _intro + separator + _format shape — separate assertion at 4.5.
if cmp -s "$T/docs/project/BACKLOG.md" "$T/docs/project/backlog/_intro.md"; then
    t_pass "4.4 BACKLOG.md byte-identical to backlog/_intro.md (empty-stream mirror shape)"
else
    t_fail "4.4 BACKLOG.md NOT byte-identical to backlog/_intro.md"
fi
if cmp -s "$T/docs/project/IMPLEMENTATION-PLAN.md" "$T/docs/project/implementation-plan/_intro.md"; then
    t_pass "4.4 IMPLEMENTATION-PLAN.md byte-identical to implementation-plan/_intro.md (empty-stream mirror shape)"
else
    t_fail "4.4 IMPLEMENTATION-PLAN.md NOT byte-identical to implementation-plan/_intro.md"
fi

# 4.5 — changelog mirror shape: _intro.md content, then \n---\n\n
# separator, then _format.md content (project-changelog is the one
# project stream with _format.md asymmetry per mirror-generate.sh).
# Verify by reconstructing the expected file via concat + cmp.
expected_changelog=$(mktemp -t bd166-ch-expect.XXXXXX)
cat "$T/docs/project/changelog/_intro.md" > "$expected_changelog"
# pe__normalize_trailing_blank guarantees exactly-one-trailing-newline,
# then the inter-section separator is `\n---\n\n`. We mirror that here.
python3 - "$expected_changelog" "$T/docs/project/changelog/_format.md" <<'PYEOF'
import sys
expect_path = sys.argv[1]
fmt_path = sys.argv[2]
with open(expect_path, "r", encoding="utf-8", newline="") as f:
    data = f.read()
# Normalize trailing-newline-to-exactly-one (mirrors pe__normalize_trailing_blank).
data = data.rstrip("\n") + "\n"
# Inter-section separator per mirror-generate.sh:152/163.
data += "\n---\n\n"
with open(fmt_path, "r", encoding="utf-8", newline="") as f:
    data += f.read()
data = data.rstrip("\n") + "\n"
with open(expect_path, "w", encoding="utf-8", newline="") as f:
    f.write(data)
PYEOF
if cmp -s "$T/docs/project/CHANGELOG.md" "$expected_changelog"; then
    t_pass "4.5 CHANGELOG.md == _intro.md + '\\n---\\n\\n' + _format.md (project-changelog shape)"
else
    t_fail "4.5 CHANGELOG.md shape mismatch (expected _intro + separator + _format)"
fi
rm -f "$expected_changelog"

# 4.6 — three empty seed _toc.md files with the canonical empty-state
# payload `(empty — no entries)` (verified upstream against the actual
# toc-regenerate.sh output; uses em-dash U+2014).
toc_empty_needle='(empty — no entries)'
for stream in backlog implementation-plan changelog; do
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
strays=$(find "$T/docs/project/backlog" "$T/docs/project/implementation-plan" "$T/docs/project/changelog" \
    -maxdepth 1 -type f -not -name "_*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$strays" -eq 0 ]]; then
    t_pass "4.7 no entry files seeded (TD-NNN.md / phase-N.md / YYYY-MM-DD-*.md absent on greenfield)"
else
    t_fail "4.7 unexpected entry files in stream subdirs (count=$strays)"
fi

# Keep $T alive for Group 5 (idempotency); cleaned at end of Group 5.

# ─────────────────────────────────────────────────────────────────────────
# Group 5: BD-166 sub-step 7 idempotency (helper-level proof loop)
# closes PACK-REVIEW-BD-166-RETRO SHOULD finding 2 (proof-loop closure).
#
# The mirror + TOC regenerators both short-circuit on cmp -s byte-
# identity (mirror-generate.sh:233-237, toc-regenerate.sh:285-289).
# Reinvoking them against the freshly-installed greenfield tree must
# produce zero mtime churn — proving the sub-step 7 regen path is
# idempotent and a re-run of init-project.sh's sub-step 7 block would
# not gratuitously modify the install.
#
# Reuses $T from Group 4 (canonical greenfield surface freshly installed).
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: BD-166 sub-step 7 idempotency (proof loop) ===\n"

# Pre-snapshot mtimes for the 6 regen outputs (3 mirrors + 3 TOCs).
# Use cmp-based equality rather than stat mtime: cmp -s is the
# canonical zero-mtime-churn signal the helpers themselves use, and
# avoids stat -f (BSD) vs stat -c (GNU) portability surface area.
pre_snap_dir=$(mktemp -d -t bd166-snap.XXXXXX)
for rel in \
    "docs/project/BACKLOG.md" \
    "docs/project/IMPLEMENTATION-PLAN.md" \
    "docs/project/CHANGELOG.md" \
    "docs/project/backlog/_toc.md" \
    "docs/project/implementation-plan/_toc.md" \
    "docs/project/changelog/_toc.md"; do
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
    . "$PACK/scripts/lib/per-entry/mirror-generate.sh"
    # shellcheck disable=SC1091
    . "$PACK/scripts/lib/per-entry/toc-regenerate.sh"
    for pe_spec in \
        "project-backlog|docs/project/BACKLOG.md|docs/project/backlog" \
        "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan" \
        "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog"; do
        pe_key="${pe_spec%%|*}"
        pe_rest="${pe_spec#*|}"
        pe_mirror_rel="${pe_rest%%|*}"
        pe_dir_rel="${pe_rest##*|}"
        per_entry_regenerate_mirror "$pe_key" "$T/$pe_dir_rel" "$T/$pe_mirror_rel" </dev/null \
            || { echo "regen mirror failed for $pe_key" >&2; exit 1; }
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
    "docs/project/BACKLOG.md" \
    "docs/project/IMPLEMENTATION-PLAN.md" \
    "docs/project/CHANGELOG.md" \
    "docs/project/backlog/_toc.md" \
    "docs/project/implementation-plan/_toc.md" \
    "docs/project/changelog/_toc.md"; do
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
