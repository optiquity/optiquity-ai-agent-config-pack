#!/usr/bin/env bash
# scripts/tests/test-customization-preserve.sh — BD-088 fixture tests.
#
# Covers the customization-preserve.sh + customization-report.sh public API
# against synthetic v10-state projects with realistic customization shapes
# (modeled on the OT post-migration audit per BD-059 context).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

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

# Extract a tab-separated column from a TSV row.
#   $1: 1-based column index, $2: tsv row.
tsv_col() {
    printf '%s' "$2" | awk -F '\t' -v c="$1" '{print $c}'
}

# shellcheck disable=SC1091
source "$LIB_DIR/three-way.sh"
# Required by structured-config strategy AND by init guard (B1).
export _CP_PACK_ROOT="$REPO_ROOT"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-preserve.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/customization-report.sh"

# ─────────────────────────────────────────────────────────────────────────
# Group 1: customization_classify
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 1: customization_classify ===\n"

assert_eq "1.1 trinity CLAUDE.md"  "trinity" "$(customization_classify CLAUDE.md)"
assert_eq "1.2 trinity AGENTS.md"  "trinity" "$(customization_classify AGENTS.md)"
assert_eq "1.3 trinity GEMINI.md"  "trinity" "$(customization_classify GEMINI.md)"
assert_eq "1.4 .claude/settings.json"  "claude-settings" \
    "$(customization_classify .claude/settings.json)"
assert_eq "1.5 .mcp.json.example"  "claude-mcp-example" \
    "$(customization_classify .mcp.json.example)"
assert_eq "1.5b .agents/mcp_config.json.example → mcp-config-json" \
    "mcp-config-json" \
    "$(customization_classify .agents/mcp_config.json.example)"
assert_eq "1.5c .agents/mcp_config.json → mcp-config-json" \
    "mcp-config-json" \
    "$(customization_classify .agents/mcp_config.json)"
assert_eq "1.6 .codex/config.toml"  "codex-config" \
    "$(customization_classify .codex/config.toml)"
assert_eq "1.7 .codex/config.toml.example"  "codex-config-example" \
    "$(customization_classify .codex/config.toml.example)"
assert_eq "1.8 docs/pack/PM-CHAT.md"  "pm-chat" \
    "$(customization_classify docs/pack/PM-CHAT.md)"
assert_eq "1.10 .claude/agents/x-foo.md"  "custom-agent" \
    "$(customization_classify .claude/agents/x-foo.md)"
assert_eq "1.11 .claude/agents/pack-reviewer.md"  "pack-agent" \
    "$(customization_classify .claude/agents/pack-reviewer.md)"
assert_eq "1.12 .codex/agents/x-bar.md"  "custom-agent" \
    "$(customization_classify .codex/agents/x-bar.md)"
assert_eq "1.13 scripts/foo.sh"  "pack-script" \
    "$(customization_classify scripts/foo.sh)"
assert_eq "1.14 unknown"  "generic" \
    "$(customization_classify some/random/path.md)"
# BD-221 corrected agent-migration model: the Antigravity plugin bundle is
# classified through the SAME custom-agent / pack-agent classes the loose
# dirs use (x- prefix wins over the general *.md leg). The `*` after
# .agents-plugin/ matches the plugin namespace dir without hard-coding it.
assert_eq "1.15 .agents-plugin/optiquity-agents/agents/x-foo.md → custom-agent" \
    "custom-agent" \
    "$(customization_classify .agents-plugin/optiquity-agents/agents/x-foo.md)"
assert_eq "1.16 .agents-plugin/optiquity-agents/agents/coder.md → pack-agent" \
    "pack-agent" \
    "$(customization_classify .agents-plugin/optiquity-agents/agents/coder.md)"
# Robust to a different plugin namespace dir (not hard-coded to optiquity).
assert_eq "1.17 .agents-plugin/other-ns/agents/x-bar.md → custom-agent" \
    "custom-agent" \
    "$(customization_classify .agents-plugin/other-ns/agents/x-bar.md)"
# Bundle meta files (plugin.json, not under agents/) fall to generic.
assert_eq "1.18 .agents-plugin/optiquity-agents/plugin.json → generic" \
    "generic" \
    "$(customization_classify .agents-plugin/optiquity-agents/plugin.json)"

# ─────────────────────────────────────────────────────────────────────────
# Group 2: text-strategy dispositions
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: text-strategy 4-case ===\n"

setup_state() {
    rm -rf "$1"
    customization_preserve_init "$1" ".pre-update"
}

T2=$(mktemp -d "${TMPDIR:-/tmp}/cp-text.XXXXXX")
state="$T2/state"

# 2.1 unchanged-pack: base==ours==theirs.
setup_state "$state"
echo "same" > "$T2/base.md"
echo "same" > "$T2/ours.md"
echo "same" > "$T2/theirs.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.1 disposition" "unchanged-pack" "$(tsv_col 1 "$last")"
assert_eq "2.1 action"      "none"           "$(tsv_col 4 "$last")"

# 2.2 pack-update-applied: base==ours, theirs differs.
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1" > "$T2/ours.md"
echo "v2" > "$T2/theirs.md"
echo "v1" > "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.2 disposition" "pack-update-applied" "$(tsv_col 1 "$last")"
assert_eq "2.2 action"      "copied"              "$(tsv_col 4 "$last")"
assert_eq "2.2 dest written" "v2" "$(cat "$T2/dest.md")"

# 2.3 merged-with-customization: project edited, pack didn't.
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1-mine" > "$T2/ours.md"
echo "v1" > "$T2/theirs.md"
echo "v1-mine" > "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.3 disposition" "merged-with-customization" "$(tsv_col 1 "$last")"
assert_eq "2.3 action"      "preserved"                 "$(tsv_col 4 "$last")"
assert_eq "2.3 dest preserved" "v1-mine" "$(cat "$T2/dest.md")"

# 2.4 (BD-287 PROSE class, SAME-LINE overlap → rc1 markers). generic + a real
# BASE where the SAME single line differs on both sides → tw_merge_file emits a
# --diff3 conflict hunk (rc1). The prose arm KEEPS the sidecar and records
# action `merged` under the UNCHANGED needs-reconciliation disposition (OI-7 —
# no new token); DEST holds the marked merge.
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1-mine" > "$T2/ours.md"
echo "v2" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4 disposition" "customization-detected-needs-reconciliation" \
    "$(tsv_col 1 "$last")"
assert_eq "2.4 action (prose same-line → merged)" "merged" "$(tsv_col 4 "$last")"
dest24=$(cat "$T2/dest.md")
assert_contains "2.4 dest carries diff3 markers (ours label)" "$dest24" "<<<<<<< your customization"
assert_contains "2.4 dest carries diff3 base label"           "$dest24" "||||||| v10 baseline"
assert_contains "2.4 dest carries diff3 theirs label"         "$dest24" ">>>>>>> pack v11 update"
assert_contains "2.4 dest keeps ours side of the hunk"        "$dest24" "v1-mine"
assert_contains "2.4 dest keeps theirs side of the hunk"      "$dest24" "v2"
assert_eq "2.4 sidecar = ours (KEPT on rc1)" "v1-mine" "$(cat "$T2/dest.md.pre-update")"
# BD-112: diff name uses the collision-safe flat helper.
expected_diff_24="$state/diffs/$(_cp_flat_name "doc.md").three-way.diff"
[[ -f "$expected_diff_24" ]] \
    && t_pass "2.4 three-way diff written ($expected_diff_24)" \
    || t_fail "2.4 three-way diff written" "expected $expected_diff_24"

# 2.4b (BD-287 PROSE class, DIFFERENT-LINE → rc0 clean, F2 DROP sidecar).
# generic + a real BASE where the pack and project edit DIFFERENT lines →
# tw_merge_file produces a clean union (rc0, ZERO markers). The clean merge
# records `merged-with-customization`/action `merged`, writes BOTH edits into
# DEST, and leaves NO `.v10-customized` sidecar (F2 — the pre-migration backup
# covers OURS; Gate 2 stays clean).
setup_state "$state"
rm -f "$T2/dest.md.pre-update"   # clear the sidecar a prior rc1 case left
printf '%s\n' L1 L2 L3 L4 L5 L6 > "$T2/base.md"
printf '%s\n' L1 L2-PROJECT-EDIT L3 L4 L5 L6 > "$T2/ours.md"
printf '%s\n' L1 L2 L3 L4 L5-PACK-EDIT L6 > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4b disposition (clean prose merge)" "merged-with-customization" \
    "$(tsv_col 1 "$last")"
assert_eq "2.4b action = merged" "merged" "$(tsv_col 4 "$last")"
assert_eq "2.4b sidecar column dash (F2 clean-drops-sidecar)" "-" "$(tsv_col 5 "$last")"
dest24b=$(cat "$T2/dest.md")
assert_contains "2.4b dest carries the PROJECT edit" "$dest24b" "L2-PROJECT-EDIT"
assert_contains "2.4b dest carries the PACK edit"    "$dest24b" "L5-PACK-EDIT"
[[ ! -f "$T2/dest.md.pre-update" ]] \
    && t_pass "2.4b NO sidecar on clean prose merge (F2)" \
    || t_fail "2.4b unexpected sidecar written on clean prose merge"
# A clean merge leaves ZERO diff3 markers in DEST.
if grep -qE '^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)' "$T2/dest.md"; then
    t_fail "2.4b clean merge unexpectedly left diff3 markers"
else
    t_pass "2.4b clean merge left ZERO diff3 markers"
fi

# 2.4c (BD-287 PROSE class, NO REAL BASE → rc2 fallback to bare sidecar). A
# generic real-merge with an ABSENT base is `project-shadows-new-pack`;
# tw_merge_file's REAL-BASE-only guard (I3) returns rc2, so the arm falls back
# to TODAY's bare sidecar body (THEIRS→DEST, OURS→sidecar, action `sidecar`).
setup_state "$state"
printf '%s\n' "ours only line" > "$T2/ours.md"
printf '%s\n' "pack v11 line"  > "$T2/theirs.md"
rm -f "$T2/dest.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4c disposition (no-base fallback)" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"
assert_eq "2.4c action = sidecar (rc2 bare-sidecar fallback)" "sidecar" "$(tsv_col 4 "$last")"
assert_eq "2.4c dest = theirs"  "pack v11 line"  "$(cat "$T2/dest.md")"
assert_eq "2.4c sidecar = ours" "ours only line" "$(cat "$T2/dest.md.pre-update")"

# 2.4d (BD-287 F8 DEST four-token RE-SCAN). A clean rc0 union that nonetheless
# leaves a residual --diff3 token in the content is DEMOTED to the markers-
# present branch (keep sidecar, action `merged`, needs-reconciliation). Here
# OURS embeds a literal `=======` line the merge carries through cleanly (rc0);
# the re-scan catches it and demotes.
setup_state "$state"
printf '%s\n' "top pack" "one" "two" "three" "bottom pack" > "$T2/base.md"
printf '%s\n' "top pack" "one" "two" "=======" "three" "bottom pack" > "$T2/ours.md"
printf '%s\n' "top PACK-NEW" "one" "two" "three" "bottom pack" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
# Prove the raw 3-way primitive is a CLEAN rc0 (well-separated edits) that
# nonetheless carries a residual token — so the demotion below is genuinely the
# F8 re-scan, not a plain rc1 conflict.
tw_merge_file "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" "$T2/raw24d.out" \
    "your customization" "v10 baseline" "pack v11 update" && raw_rc=0 || raw_rc=$?
assert_eq "2.4d raw tw_merge_file is CLEAN rc0 (F8 precondition)" "0" "$raw_rc"
if grep -qE '^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)' "$T2/raw24d.out"; then
    t_pass "2.4d raw rc0 output carries a residual diff3 token (F8 trigger)"
else
    t_fail "2.4d raw rc0 output has no token — fixture does not exercise F8"
fi
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4d F8 demote: disposition stays needs-reconciliation" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"
assert_eq "2.4d F8 demote: action = merged" "merged" "$(tsv_col 4 "$last")"
assert_eq "2.4d F8 demote: sidecar KEPT (not dropped)" \
    "$T2/dest.md.pre-update" "$(tsv_col 5 "$last")"
[[ -f "$T2/dest.md.pre-update" ]] \
    && t_pass "2.4d F8 demote: sidecar file present on disk" \
    || t_fail "2.4d F8 demote: sidecar missing"

# 2.4e IDENTITY RULE (BD-293 T-P0-bite). OURS and THEIRS byte-identical with an
# ABSENT base is `unchanged-pack`, not `project-shadows-new-pack`: the project
# file already carries the pack's content, so there is nothing to reconcile.
# This is the property that makes `--update` idempotent — an unmodified
# installed file must be distinguishable from a customized one. The end-to-end
# leg pins the consequence that matters: a no-op action and ZERO sidecar bytes
# written to disk.
setup_state "$state"
printf '%s\n' "identical pack line" > "$T2/ours.md"
printf '%s\n' "identical pack line" > "$T2/theirs.md"
rm -f "$T2/dest.md" "$T2/dest.md.pre-update"
cp "$T2/ours.md" "$T2/dest.md"
assert_eq "2.4e classify: base absent + ours==theirs -> unchanged-pack" \
    "unchanged-pack" \
    "$(three_way_classify "" "$T2/ours.md" "$T2/theirs.md")"
customization_preserve "" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4e disposition" "unchanged-pack" "$(tsv_col 1 "$last")"
assert_eq "2.4e action = none" "none" "$(tsv_col 4 "$last")"
assert_eq "2.4e sidecar column dash" "-" "$(tsv_col 5 "$last")"
[[ ! -e "$T2/dest.md.pre-update" ]] \
    && t_pass "2.4e ZERO sidecar on disk for a byte-identical file" \
    || t_fail "2.4e unexpected sidecar written for a byte-identical file"

# 2.4f IDENTITY RULE, OPPOSITE DIRECTION (BD-293 T-P0-opposite). The identity
# rule must NOT swallow genuine client work: a generic-class file whose OURS
# DIVERGES from THEIRS with an absent base still records
# `customization-detected-needs-reconciliation` AND still produces both
# preservation artifacts. All three columns are asserted — the token alone
# would not catch a regression that recorded the right disposition while
# dropping the sidecar or the diff.
setup_state "$state"
printf '%s\n' "my hand-written customization" > "$T2/ours.md"
printf '%s\n' "pack v11 line"                 > "$T2/theirs.md"
rm -f "$T2/dest.md" "$T2/dest.md.pre-update"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "" "$T2/ours.md" "$T2/theirs.md" \
    "doc.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.4f disposition (divergent ours is still reconciled)" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"
sidecar_col_24f=$(tsv_col 5 "$last")
diff_col_24f=$(tsv_col 6 "$last")
[[ "$sidecar_col_24f" != "-" && -n "$sidecar_col_24f" ]] \
    && t_pass "2.4f sidecar column is a real path (not '-')" \
    || t_fail "2.4f sidecar column is '-'" "got='$sidecar_col_24f'"
[[ "$diff_col_24f" != "-" && -n "$diff_col_24f" ]] \
    && t_pass "2.4f diff column is a real path (not '-')" \
    || t_fail "2.4f diff column is '-'" "got='$diff_col_24f'"
[[ -f "$sidecar_col_24f" ]] \
    && t_pass "2.4f sidecar file exists on disk" \
    || t_fail "2.4f sidecar file missing" "path='$sidecar_col_24f'"
[[ -f "$diff_col_24f" ]] \
    && t_pass "2.4f diff file exists on disk" \
    || t_fail "2.4f diff file missing" "path='$diff_col_24f'"
assert_eq "2.4f sidecar preserves the client customization" \
    "my hand-written customization" "$(cat "$sidecar_col_24f")"

# 2.5 new-file-in-pack: base + ours absent, theirs present → copy.
setup_state "$state"
echo "new" > "$T2/theirs.md"
rm -f "$T2/dest.md"
customization_preserve "" "" "$T2/theirs.md" \
    "newfile.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.5 disposition" "pack-update-applied" "$(tsv_col 1 "$last")"
assert_eq "2.5 action"      "copied"              "$(tsv_col 4 "$last")"
assert_eq "2.5 dest written" "new" "$(cat "$T2/dest.md")"

# 2.6 project-only: base + theirs absent, ours present → preserved.
setup_state "$state"
echo "mine" > "$T2/ours.md"
customization_preserve "" "$T2/ours.md" "" \
    "private.md" "$T2/ours.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.6 disposition" "project-only-file" "$(tsv_col 1 "$last")"
assert_eq "2.6 action"      "preserved"         "$(tsv_col 4 "$last")"

# 2.7 removed-by-pack-clean: pack retired; project unchanged.
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1" > "$T2/ours.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "" \
    "old.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.7 disposition" "removed-by-design" "$(tsv_col 1 "$last")"
assert_eq "2.7 action"      "removed"           "$(tsv_col 4 "$last")"
[[ ! -f "$T2/dest.md" ]] && t_pass "2.7 dest removed" || t_fail "2.7 dest still present"

# 2.8 removed-by-pack-customized: pack retired; project edited → sidecar.
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1-mine" > "$T2/ours.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "" \
    "old.md" "$T2/dest.md" generic >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.8 disposition" "removed-by-design" "$(tsv_col 1 "$last")"
assert_eq "2.8 action"      "removed"           "$(tsv_col 4 "$last")"
[[ -f "$T2/dest.md.pre-update" ]] \
    && t_pass "2.8 sidecar preserved customizations" \
    || t_fail "2.8 sidecar missing"

# 2.9 trinity class explicitly routes through text dispatch (m4).
setup_state "$state"
echo "v1" > "$T2/base.md"
echo "v1-mine" > "$T2/ours.md"
echo "v2" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "CLAUDE.md" "$T2/dest.md" >/dev/null  # no explicit class → auto-classify
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2.9 trinity auto-classified" "trinity"      "$(tsv_col 2 "$last")"
assert_eq "2.9 trinity → needs-reconciliation" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"

# ─────────────────────────────────────────────────────────────────────────
# Group 2b: BD-287 class gate boundary (F1) + trinity BASE-stash
# ─────────────────────────────────────────────────────────────────────────
#
# The prose auto-merge is SCOPED to generic/pm-chat. pack-script, pack-agent,
# and the markerless-trinity fallback MUST keep TODAY's bare sidecar (no
# line-merge — executables/agents are behaviourally unsafe to union; the trinity
# is section-sensitive, F6). The same-line real-merge inputs (base=v1,
# ours=v1-mine, theirs=v2) that produce rc1 MARKERS for a prose class must
# instead produce a bare `sidecar` action for these classes.

printf "\n=== Group 2b: BD-287 class gate boundary + trinity BASE-stash ===\n"

# 2b.1 pack-script → bare sidecar (NOT line-merged).
setup_state "$state"
rm -f "$T2/dest.md.v10-base"   # clear any stash a prior trinity case left
echo "v1" > "$T2/base.md"; echo "v1-mine" > "$T2/ours.md"; echo "v2" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "scripts/foo.sh" "$T2/dest.md" pack-script >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2b.1 pack-script disposition" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"
assert_eq "2b.1 pack-script action = sidecar (NOT merged)" "sidecar" "$(tsv_col 4 "$last")"
assert_eq "2b.1 pack-script dest = theirs (no markers)" "v2" "$(cat "$T2/dest.md")"
[[ ! -f "$T2/dest.md.v10-base" ]] \
    && t_pass "2b.1 pack-script writes NO .v10-base stash" \
    || t_fail "2b.1 unexpected .v10-base stash for pack-script"

# 2b.2 pack-agent → bare sidecar (NOT line-merged).
setup_state "$state"
echo "v1" > "$T2/base.md"; echo "v1-mine" > "$T2/ours.md"; echo "v2" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    ".claude/agents/pack-reviewer.md" "$T2/dest.md" pack-agent >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2b.2 pack-agent action = sidecar (NOT merged)" "sidecar" "$(tsv_col 4 "$last")"
assert_eq "2b.2 pack-agent dest = theirs (no markers)" "v2" "$(cat "$T2/dest.md")"

# 2b.3 markerless-trinity fallback → bare sidecar (F6) AND writes .v10-base
# stash (real base present). Drive via the trinity class with markerless OURS so
# marker_preserve_trinity delegates to the _cp_strategy_text "trinity" arm.
setup_state "$state"
rm -f "$T2/dest.md.v10-base"
echo "v1" > "$T2/base.md"; echo "v1-mine" > "$T2/ours.md"; echo "v2" > "$T2/theirs.md"
cp "$T2/ours.md" "$T2/dest.md"
customization_preserve "$T2/base.md" "$T2/ours.md" "$T2/theirs.md" \
    "CLAUDE.md" "$T2/dest.md" trinity >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "2b.3 trinity fallback action = sidecar (F6, no line-merge)" "sidecar" "$(tsv_col 4 "$last")"
assert_eq "2b.3 trinity fallback dest = theirs" "v2" "$(cat "$T2/dest.md")"
assert_eq "2b.3 trinity fallback stash = base" "v1" "$(cat "$T2/dest.md.v10-base")"
# The .v10-base name must NOT collide with the *.v10-customized orphan glob.
case "$T2/dest.md.v10-base" in
    *.v10-customized) t_fail "2b.3 .v10-base matches the *.v10-customized glob (collision)" ;;
    *)                t_pass "2b.3 .v10-base does NOT match *.v10-customized (Gate-2 invisible)" ;;
esac

# 2b.4 _cp_stash_trinity_base helper — writes for a REAL base, no-ops otherwise.
setup_state "$state"
echo "the v10 base" > "$T2/hb.base"
rm -f "$T2/hbdest.md.v10-base"
_cp_stash_trinity_base "$T2/hb.base" "$T2/hbdest.md"
assert_eq "2b.4 helper writes .v10-base for a real base" \
    "the v10 base" "$(cat "$T2/hbdest.md.v10-base" 2>/dev/null)"
# BASE absent (empty string) → no stash.
rm -f "$T2/hbabs.md.v10-base"
_cp_stash_trinity_base "" "$T2/hbabs.md"
[[ ! -f "$T2/hbabs.md.v10-base" ]] \
    && t_pass "2b.4 helper no-ops on absent BASE (empty string)" \
    || t_fail "2b.4 helper wrote a stash for an absent BASE"
# BASE zero-byte (not a real base per I3) → no stash.
: > "$T2/hbempty.base"
rm -f "$T2/hbempty-dest.md.v10-base"
_cp_stash_trinity_base "$T2/hbempty.base" "$T2/hbempty-dest.md"
[[ ! -f "$T2/hbempty-dest.md.v10-base" ]] \
    && t_pass "2b.4 helper no-ops on a zero-byte BASE (not a real base, I3)" \
    || t_fail "2b.4 helper wrote a stash for a zero-byte BASE"

rm -rf "$T2"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: structured config (JSON allowlist via merge-json.py)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: structured config (JSON) ===\n"

T3=$(mktemp -d "${TMPDIR:-/tmp}/cp-json.XXXXXX")
state="$T3/state"
setup_state "$state"

# OT-shaped fixture: project preserves XCODE_SCHEME + custom permissions.
cat > "$T3/base.json" <<'EOF'
{ "permissions": { "allow": ["base-perm"] } }
EOF
cat > "$T3/ours.json" <<'EOF'
{ "permissions": { "allow": ["base-perm", "project-perm"] }, "env": { "XCODE_SCHEME": "MyApp" } }
EOF
cat > "$T3/theirs.json" <<'EOF'
{ "permissions": { "allow": ["base-perm", "pack-new-perm"] } }
EOF
cp "$T3/ours.json" "$T3/dest.json"
customization_preserve "$T3/base.json" "$T3/ours.json" "$T3/theirs.json" \
    ".claude/settings.json" "$T3/dest.json" claude-settings >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
# We expect a successful key-level merge: project keys preserved, pack-new-perm added.
assert_contains "3.1 disposition recorded" "$last" "merged"
merged=$(cat "$T3/dest.json")
assert_contains "3.1 XCODE_SCHEME preserved" "$merged" "MyApp"
assert_contains "3.1 project-perm preserved" "$merged" "project-perm"
assert_contains "3.1 pack-new-perm added"    "$merged" "pack-new-perm"

rm -rf "$T3"

# ── 3.2 (BD-273-OWNERSHIP-ISOLATION-AS-BUILT.md §6 "Wiring"): pack adds a NEW PreToolUse[Bash] hook as its
#    OWN array ELEMENT (the client deletion-boundary element). The
#    claude-settings structured merge (merge-json.py `merge_list`, which keys
#    array elements by whole-element JSON) must: ADOPT the new element
#    (added_by_pack), PRESERVE a project-customized commit-gate element (its own
#    `ours` key), PRESERVE a project's OWN separate hook element + permission,
#    and produce NO duplicate commit-gate. This is the load-bearing merge-safety
#    property behind wiring the client deletion-boundary hook as a SEPARATE
#    element rather than appending its command INTO the commit-gate element
#    (per BD-273-OWNERSHIP-ISOLATION-AS-BUILT.md §6 "Wiring").
T3B=$(mktemp -d "${TMPDIR:-/tmp}/cp-json-hook.XXXXXX")
state="$T3B/state"
setup_state "$state"

# BASE: pack baseline PreToolUse = [Agent+enforce, Bash+commit-gate]; no
# deletion-boundary element yet; stock single permission.
cat > "$T3B/base.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(base-perm)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-enforce.py" } ] },
      { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-commit-gate.py" } ] }
    ]
  }
}
EOF
# OURS: project CUSTOMIZED the commit-gate element (extra project command
# INSIDE it) + added its OWN Write-matcher hook element + a project permission.
cat > "$T3B/ours.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(base-perm)", "Bash(project-perm)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-enforce.py" } ] },
      { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-commit-gate.py" }, { "type": "command", "command": "./scripts/x-project-gate.sh" } ] },
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "./scripts/x-project-write-hook.sh" } ] }
    ]
  }
}
EOF
# THEIRS: pack v11 adds the deletion-boundary hook as its OWN Bash-matcher
# array element (BD-273-OWNERSHIP-ISOLATION-AS-BUILT.md §6 "Wiring") alongside the stock two.
cat > "$T3B/theirs.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(base-perm)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-enforce.py" } ] },
      { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-commit-gate.py" } ] },
      { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-deletion-boundary.py" } ] }
    ]
  }
}
EOF
cp "$T3B/ours.json" "$T3B/dest.json"
customization_preserve "$T3B/base.json" "$T3B/ours.json" "$T3B/theirs.json" \
    ".claude/settings.json" "$T3B/dest.json" claude-settings >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
# real-merge-required (both sides changed) → structured key-level merge.
assert_contains "3.2 disposition recorded (merged)" "$last" "merged"
merged=$(cat "$T3B/dest.json")
# New pack hook ELEMENT adopted (added_by_pack).
assert_contains "3.2 deletion-boundary element adopted" "$merged" "pm-deletion-boundary.py"
# Project-customized commit-gate element preserved (its extra command survives).
assert_contains "3.2 project commit-gate customization preserved" "$merged" "x-project-gate.sh"
# Project's OWN separate hook element preserved.
assert_contains "3.2 project own hook element preserved" "$merged" "x-project-write-hook.sh"
# Project permission preserved.
assert_contains "3.2 project permission preserved" "$merged" "project-perm"
# NO duplicate: exactly ONE commit-gate occurrence (the customized element;
# the base plain element was superseded by the project's own edit).
cg_count=$(grep -c 'pm-modes-commit-gate.py' "$T3B/dest.json")
assert_eq "3.2 no duplicate commit-gate (exactly 1)" "1" "$cg_count"
# And exactly ONE deletion-boundary occurrence.
db_count=$(grep -c 'pm-deletion-boundary.py' "$T3B/dest.json")
assert_eq "3.2 deletion-boundary appears exactly once" "1" "$db_count"

# ── 3.3 BITE (declare-verify-backing; BD-273-OWNERSHIP-ISOLATION-AS-BUILT.md §6 "Wiring"): prove the 3.2 no-duplicate
#    assertion actually DISTINGUISHES the correct separate-element wiring from
#    the broken "append the deletion-boundary command INTO the commit-gate
#    element" wiring. This negative control runs through the IDENTICAL
#    production dispatch as 3.2 (customization_preserve … claude-settings →
#    real-merge-required → merge-json.py), differing ONLY in the THEIRS fixture:
#    the broken THEIRS keys as a DIFFERENT whole-element vs the project's
#    customized commit-gate element, so BOTH survive the merge → commit-gate is
#    DUPLICATED (count 2). Were 3.2's no-dupe check not biting, this broken
#    wiring would slip through the SAME code path undetected.
cat > "$T3B/theirs-bad.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(base-perm)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-enforce.py" } ] },
      { "matcher": "Bash",  "hooks": [ { "type": "command", "command": "python3 ./scripts/pm-modes-commit-gate.py" }, { "type": "command", "command": "python3 ./scripts/pm-deletion-boundary.py" } ] }
    ]
  }
}
EOF
# Fresh dest — does NOT touch 3.2's already-asserted $T3B/dest.json. Same base +
# ours as 3.2; only the theirs fixture differs, so any count divergence is
# attributable solely to the broken wiring, not the dispatch path.
cp "$T3B/ours.json" "$T3B/dest-bad.json"
customization_preserve "$T3B/base.json" "$T3B/ours.json" "$T3B/theirs-bad.json" \
    ".claude/settings.json" "$T3B/dest-bad.json" claude-settings >/dev/null
cg_bad=$(grep -c 'pm-modes-commit-gate.py' "$T3B/dest-bad.json")
assert_eq "3.3 BITE: broken append-into wiring DUPLICATES commit-gate (count 2)" \
    "2" "$cg_bad"

rm -rf "$T3B"

# ─────────────────────────────────────────────────────────────────────────
# Group 4: structured config (TOML — OT model_providers removal case)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: structured config (TOML) ===\n"

T4=$(mktemp -d "${TMPDIR:-/tmp}/cp-toml.XXXXXX")
state="$T4/state"
setup_state "$state"

# OT case: project removed [model_providers.ollama]; pack still ships it.
cat > "$T4/base.toml" <<'EOF'
[model_providers.openai]
key = "x"

[model_providers.ollama]
key = "y"
EOF
cat > "$T4/ours.toml" <<'EOF'
[model_providers.openai]
key = "x"
EOF
cat > "$T4/theirs.toml" <<'EOF'
[model_providers.openai]
key = "x"

[model_providers.ollama]
key = "y"

[model_providers.lmstudio]
key = "z"
EOF
cp "$T4/ours.toml" "$T4/dest.toml"
customization_preserve "$T4/base.toml" "$T4/ours.toml" "$T4/theirs.toml" \
    ".codex/config.toml" "$T4/dest.toml" codex-config >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_contains "4.1 disposition recorded" "$last" "merged"
merged=$(cat "$T4/dest.toml")
# Project intentionally removed ollama; honored.
[[ "$merged" != *"ollama"* ]] \
    && t_pass "4.1 ollama removal honored" \
    || t_fail "4.1 ollama still present" "merged='$merged'"
# lmstudio is pack-new (not in BASE) → adopted.
assert_contains "4.1 lmstudio adopted" "$merged" "lmstudio"

rm -rf "$T4"

# ─────────────────────────────────────────────────────────────────────────
# Group 5: legacy `.gemini/` custom-agent classification (legacy-READ
# carve-out ii) — a departing v10 client's `.gemini/agents/x-*` custom
# agent is still classified so the migrator can preserve it. The
# `gemini-env` strategy was removed in v11 (BD-221, decision b: no
# shipped env/permissions file); its dedicated scenario is retired.
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: legacy .gemini custom-agent classify (carve-out ii) ===\n"

assert_eq "5.1 .gemini/agents/x-mine.md → custom-agent (legacy-READ)" \
    "custom-agent" "$(customization_classify .gemini/agents/x-mine.md)"
assert_eq "5.2 .gemini/agents/pack-coder.md → pack-agent (legacy-READ)" \
    "pack-agent" "$(customization_classify .gemini/agents/pack-coder.md)"
# `.gemini/.env` no longer has a dedicated class (gemini-env removed);
# it falls back to the generic 3-way text strategy.
assert_eq "5.3 .gemini/.env → generic (gemini-env retired)" \
    "generic" "$(customization_classify .gemini/.env)"

# ─────────────────────────────────────────────────────────────────────────
# Group 6: custom-agent + custom-script preserved untouched
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6: custom-agent / custom-script preservation ===\n"

T6=$(mktemp -d "${TMPDIR:-/tmp}/cp-x.XXXXXX")
state="$T6/state"
setup_state "$state"

mkdir -p "$T6/proj/.claude/agents"
echo "x-agent body" > "$T6/proj/.claude/agents/x-mine.md"
customization_preserve "" "$T6/proj/.claude/agents/x-mine.md" "" \
    ".claude/agents/x-mine.md" "$T6/proj/.claude/agents/x-mine.md" custom-agent >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_contains "6.1 custom-agent → project-only-file" "$last" "project-only-file"
assert_contains "6.1 action=preserved" "$last" "preserved"
[[ -f "$T6/proj/.claude/agents/x-mine.md" ]] \
    && t_pass "6.1 custom agent untouched" \
    || t_fail "6.1 custom agent missing"

mkdir -p "$T6/proj/scripts"
echo "echo project script" > "$T6/proj/scripts/x-tool.sh"
customization_preserve "" "$T6/proj/scripts/x-tool.sh" "" \
    "scripts/x-tool.sh" "$T6/proj/scripts/x-tool.sh" custom-script >/dev/null
last=$(tail -1 "$state/dispositions.tsv")
assert_contains "6.2 custom-script → project-only-file" "$last" "project-only-file"

# 6.3 BD-221: a bundle x- custom agent SELF-CLASSIFIES to custom-agent and
# is PRESERVED (never overwritten) on a pack event — proving the new
# classifier leg routes the bundle through the custom-agent branch even
# without a forced class.
mkdir -p "$T6/proj/.agents-plugin/optiquity-agents/agents"
echo "client x-custom body" \
    > "$T6/proj/.agents-plugin/optiquity-agents/agents/x-mine.md"
customization_preserve "" \
    "$T6/proj/.agents-plugin/optiquity-agents/agents/x-mine.md" "" \
    ".agents-plugin/optiquity-agents/agents/x-mine.md" \
    "$T6/proj/.agents-plugin/optiquity-agents/agents/x-mine.md" >/dev/null  # no forced class → self-classify
last=$(tail -1 "$state/dispositions.tsv")
assert_contains "6.3 bundle x- custom → project-only-file (self-classified)" \
    "$last" "project-only-file"
assert_eq "6.3 bundle x- custom class = custom-agent" \
    "custom-agent" "$(tsv_col 2 "$last")"
if [[ -f "$T6/proj/.agents-plugin/optiquity-agents/agents/x-mine.md" ]] && \
   grep -q "client x-custom body" \
        "$T6/proj/.agents-plugin/optiquity-agents/agents/x-mine.md"; then
    t_pass "6.3 bundle x- custom preserved untouched"
else
    t_fail "6.3 bundle x- custom modified/lost"
fi

# 6.4 BD-221: a bundle PACK agent SELF-CLASSIFIES to pack-agent. Base "" +
# ours present + theirs differs → project-shadows-new-pack on the net-new
# bundle surface (ours is present, so NOT new-file-in-pack, which requires
# ours absent; and ours differs from theirs, so NOT the identity rule's
# unchanged-pack). The project-shadows-new-pack leg routes through the
# conservative sidecar gate:
# dest receives theirs (the v11 pack content) and ours is preserved in a
# .pre-update sidecar; the recorded canonical disposition is
# customization-detected-needs-reconciliation.
echo "v11 pack coder body" > "$T6/theirs-coder.md"
echo "stale v10 client coder body" \
    > "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md"
# Assert the raw classify result directly (dispositions.tsv col 1 records the
# mapped canonical token, not the classifier token).
assert_eq "6.4 classify = project-shadows-new-pack" \
    "project-shadows-new-pack" \
    "$(three_way_classify "" \
        "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md" \
        "$T6/theirs-coder.md")"
customization_preserve "" \
    "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md" \
    "$T6/theirs-coder.md" \
    ".agents-plugin/optiquity-agents/agents/coder.md" \
    "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md" >/dev/null  # no forced class → self-classify
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "6.4 bundle pack agent class = pack-agent" \
    "pack-agent" "$(tsv_col 2 "$last")"
assert_eq "6.4 bundle pack agent replaced with v11 content" \
    "v11 pack coder body" \
    "$(cat "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md")"

rm -rf "$T6"

# ─────────────────────────────────────────────────────────────────────────
# Group 6b: B1 init guard (caller contract — _CP_PACK_ROOT must be set)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6b: init guard for _CP_PACK_ROOT (B1) ===\n"

# Subshell so unsetting _CP_PACK_ROOT doesn't leak into later tests.
T6B=$(mktemp -d "${TMPDIR:-/tmp}/cp-init.XXXXXX")
init_rc=$(
    bash -c '
        SCRIPT_DIR="'"$LIB_DIR"'"
        # shellcheck source=/dev/null
        source "$SCRIPT_DIR/three-way.sh"
        # shellcheck source=/dev/null
        source "$SCRIPT_DIR/customization-preserve.sh"
        unset _CP_PACK_ROOT
        customization_preserve_init "'"$T6B"'/state" 2>/dev/null
        echo "rc=$?"
    '
)
assert_eq "6b.1 init without _CP_PACK_ROOT fails (rc=1)" "rc=1" "$init_rc"
rm -rf "$T6B"

# ─────────────────────────────────────────────────────────────────────────
# Group 6c: BD-112 — collision-safe flat naming for per-file artifacts
# ─────────────────────────────────────────────────────────────────────────
#
# Two distinct rels that collide under the legacy scheme
# (`${rel//\//-}` then strip leading `.`) must now produce distinct
# work-directory artifact names. Concrete pair from BD-112:
#   .claude/agents/foo.md   ←→ legacy → claude-agents-foo.md
#   claude/agents/foo.md    ←→ legacy → claude-agents-foo.md   (collision)
#
# Strategy coverage note (per PACK-REVIEW-BD-112 F3, 2026-05-15 retro):
# 6c covers helper-level (6c.1-6c.3) + end-to-end via the text strategy
# (6c.4). The structured strategy also writes three-way diffs via the
# same `_cp_write_diff` helper, so it inherits the BD-112 fix
# automatically — explicit end-to-end coverage would close the matrix
# but is not load-bearing because the collision-safety property lives in
# the shared helper. Adding a 6c.5 (structured) end-to-end witness is
# acceptable follow-up if a future audit demands strategy-by-strategy
# coverage.

printf "\n=== Group 6c: BD-112 collision-safe flat naming ===\n"

# 6c.1 helper-level: distinct names for the two BD-112-described rels.
flat_a=$(_cp_flat_name ".claude/agents/foo.md")
flat_b=$(_cp_flat_name "claude/agents/foo.md")
[[ "$flat_a" != "$flat_b" ]] \
    && t_pass "6c.1 helper distinguishes .claude/agents/foo.md vs claude/agents/foo.md ($flat_a vs $flat_b)" \
    || t_fail "6c.1 helper produced identical flat names" "both='$flat_a'"

# 6c.2 helper-level: deterministic — same rel → same name across calls.
flat_a2=$(_cp_flat_name ".claude/agents/foo.md")
assert_eq "6c.2 deterministic (same input → same output)" "$flat_a" "$flat_a2"

# 6c.3 helper-level: another collision pair using basename-shared paths.
flat_c=$(_cp_flat_name "scripts/lib/three-way.sh")
flat_d=$(_cp_flat_name "tests/lib/three-way.sh")
[[ "$flat_c" != "$flat_d" ]] \
    && t_pass "6c.3 helper distinguishes scripts/lib vs tests/lib (same basename)" \
    || t_fail "6c.3 helper produced identical flat names" "both='$flat_c'"

# 6c.4 end-to-end: drive _cp_write_diff via the text strategy for the
# collision pair and confirm two distinct diff files land on disk.
T6C=$(mktemp -d "${TMPDIR:-/tmp}/cp-collide.XXXXXX")
state="$T6C/state"
setup_state "$state"

# Both rels are real-merge-required so they trigger _cp_write_diff.
mk_pair() {
    local tag="$1"
    echo "v1"      > "$T6C/${tag}.base"
    echo "v1-mine" > "$T6C/${tag}.ours"
    echo "v2"      > "$T6C/${tag}.theirs"
    cp "$T6C/${tag}.ours" "$T6C/${tag}.dest"
}
mk_pair "a"
mk_pair "b"

customization_preserve "$T6C/a.base" "$T6C/a.ours" "$T6C/a.theirs" \
    ".claude/agents/foo.md" "$T6C/a.dest" generic >/dev/null
customization_preserve "$T6C/b.base" "$T6C/b.ours" "$T6C/b.theirs" \
    "claude/agents/foo.md" "$T6C/b.dest" generic >/dev/null

diff_a="$state/diffs/$(_cp_flat_name ".claude/agents/foo.md").three-way.diff"
diff_b="$state/diffs/$(_cp_flat_name "claude/agents/foo.md").three-way.diff"

[[ "$diff_a" != "$diff_b" ]] \
    && t_pass "6c.4 expected diff paths differ" \
    || t_fail "6c.4 expected diff paths identical" "both='$diff_a'"

[[ -f "$diff_a" && -f "$diff_b" ]] \
    && t_pass "6c.4 both diff files exist on disk" \
    || t_fail "6c.4 a or b diff missing" "a=$([[ -f $diff_a ]] && echo yes || echo no) b=$([[ -f $diff_b ]] && echo yes || echo no)"

# Confirm content matches the per-rel header (no overwrite happened).
grep -q '^# Three-way diff for \.claude/agents/foo\.md$' "$diff_a" \
    && t_pass "6c.4 diff_a header names .claude/agents/foo.md" \
    || t_fail "6c.4 diff_a header wrong"
grep -q '^# Three-way diff for claude/agents/foo\.md$' "$diff_b" \
    && t_pass "6c.4 diff_b header names claude/agents/foo.md" \
    || t_fail "6c.4 diff_b header wrong"

rm -rf "$T6C"

# ─────────────────────────────────────────────────────────────────────────
# Group 7: truthful report (BD-059 contract)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 7: truthful report ===\n"

T7=$(mktemp -d "${TMPDIR:-/tmp}/cp-rep.XXXXXX")
state="$T7/state"
setup_state "$state"

# Build a small dispositions set covering several outcomes.
echo "v1" > "$T7/base.md"; echo "v1" > "$T7/ours.md"; echo "v2" > "$T7/theirs.md"
cp "$T7/ours.md" "$T7/dest1.md"
customization_preserve "$T7/base.md" "$T7/ours.md" "$T7/theirs.md" \
    "doc1.md" "$T7/dest1.md" generic >/dev/null

echo "v1" > "$T7/base2.md"; echo "v1-mine" > "$T7/ours2.md"; echo "v2" > "$T7/theirs2.md"
cp "$T7/ours2.md" "$T7/dest2.md"
customization_preserve "$T7/base2.md" "$T7/ours2.md" "$T7/theirs2.md" \
    "doc2.md" "$T7/dest2.md" generic >/dev/null

mkdir -p "$T7/proj/.claude/agents"
echo "x" > "$T7/proj/.claude/agents/x-mine.md"
customization_preserve "" "$T7/proj/.claude/agents/x-mine.md" "" \
    ".claude/agents/x-mine.md" "$T7/proj/.claude/agents/x-mine.md" custom-agent >/dev/null

count=$(customization_findings_count)
assert_eq "7.1 findings count = 3" "3" "$count"

# Render report.
customization_report "$state/dispositions.tsv" "$T7/report.md" \
    "v10 → v11 customization report"
report=$(cat "$T7/report.md")
assert_contains "7.2 H1 title"            "$report" "v10 → v11 customization report"
assert_contains "7.2 total stated"        "$report" "Total files processed: **3**"
assert_contains "7.2 doc1 in updated"     "$report" "doc1.md"
assert_contains "7.2 doc2 in needs-reconciliation" "$report" "doc2.md"
assert_contains "7.2 x-mine in project-only"      "$report" "x-mine.md"
# BD-059 truthfulness contract: every finding appears.
for rel in doc1.md doc2.md x-mine.md; do
    if [[ "$report" == *"$rel"* ]]; then
        t_pass "7.3 truthful: $rel in report"
    else
        t_fail "7.3 truthful: $rel missing"
    fi
done

rm -rf "$T7"

# ─────────────────────────────────────────────────────────────────────────
# Group 8: BD-096 — directory-based synthetic fixtures
# ─────────────────────────────────────────────────────────────────────────
#
# Each fixture under scripts/tests/fixtures/customization-preserve/<name>/
# carries:
#   manifest.tsv     — rel_path, class, expected_disposition, notes
#   assertions.tsv   — (optional) rel_path, side (dest|sidecar), substring
#   base/<rel>       — BASE file (omitted for absent-on-base scenarios)
#   ours/<rel>       — OURS file (omitted for absent-on-ours scenarios)
#   theirs/<rel>     — THEIRS file (omitted for absent-on-theirs scenarios)
#
# The runner stages each fixture under a temp project root, calls
# customization_preserve for every manifest row, asserts the recorded
# disposition + class match, and verifies any assertions.tsv content
# checks against dest / sidecar files. End-to-end coverage proving the
# library handles the documented customization-shape space (BD-096).

printf "\n=== Group 8: BD-096 directory-based fixtures ===\n"

FIXTURES_DIR="$REPO_ROOT/scripts/tests/fixtures/customization-preserve"

# Run one fixture end-to-end. Args: fixture_name.
run_fixture() {
    local fname="$1"
    local fdir="$FIXTURES_DIR/$fname"
    local manifest="$fdir/manifest.tsv"
    local assertions="$fdir/assertions.tsv"

    if [[ ! -f "$manifest" ]]; then
        t_fail "8.$fname manifest.tsv missing" "expected $manifest"
        return
    fi

    local work
    work=$(mktemp -d "${TMPDIR:-/tmp}/cp-$fname.XXXXXX")
    local proj="$work/proj"
    local state="$work/state"
    mkdir -p "$proj"

    # Seed proj with OURS — mirrors how a real migration sees the
    # project current state on disk before the algorithm touches it.
    if [[ -d "$fdir/ours" ]]; then
        # BSD `cp -R src/. dest/` copies contents incl. dotfiles.
        cp -R "$fdir/ours/." "$proj/"
    fi

    customization_preserve_init "$state" ".pre-update"

    local row rel klass expected notes
    local base_path ours_path theirs_path dest_path
    local actual_disp actual_class
    # Manifest rows are 4 tab-separated fields:
    #   rel_path  class  expected_disposition  notes
    # `notes` is read for column-position discipline only — the runner
    # does not assert on it (per README "Manifest format" §). F-6: a
    # field-count guard below catches malformed rows (3 or 5+ fields).
    while IFS=$'\t' read -r rel klass expected notes; do
        # Skip header / empty / comment rows.
        case "$rel" in
            \#*|"") continue ;;
        esac

        # F-6: field-count guard. Required columns 1-3 must be non-empty;
        # `notes` (col 4) may be empty but its variable must exist.
        if [[ -z "$rel" || -z "$klass" || -z "$expected" ]]; then
            t_fail "8.$fname manifest row malformed" \
                "expected 4 tab-separated fields, got rel='$rel' class='$klass' expected='$expected'"
            continue
        fi

        base_path=""
        ours_path=""
        theirs_path=""
        [[ -f "$fdir/base/$rel" ]]   && base_path="$fdir/base/$rel"
        [[ -f "$fdir/ours/$rel" ]]   && ours_path="$fdir/ours/$rel"
        [[ -f "$fdir/theirs/$rel" ]] && theirs_path="$fdir/theirs/$rel"

        # dest_path lives under proj/ at the same rel; ensure parent dir.
        dest_path="$proj/$rel"
        mkdir -p "$(dirname "$dest_path")"

        # If class is "auto", let the algorithm classify; pass empty.
        local class_arg="$klass"
        [[ "$klass" == "auto" ]] && class_arg=""

        if ! customization_preserve "$base_path" "$ours_path" "$theirs_path" \
                "$rel" "$dest_path" "$class_arg" >/dev/null 2>&1; then
            t_fail "8.$fname/$rel customization_preserve call failed"
            continue
        fi

        # Find the row this call recorded — it's the most-recent row
        # whose rel matches. Scan from the end for safety.
        local recorded
        recorded=$(awk -F '\t' -v r="$rel" '
            $3 == r { line = $0 }
            END { print line }
        ' "$state/dispositions.tsv")
        if [[ -z "$recorded" ]]; then
            t_fail "8.$fname/$rel no disposition recorded for rel"
            continue
        fi
        actual_disp=$(tsv_col 1 "$recorded")
        actual_class=$(tsv_col 2 "$recorded")
        assert_eq "8.$fname/$rel disposition" "$expected" "$actual_disp"
        # When manifest pinned a class explicitly (not auto), check it round-trips.
        if [[ "$klass" != "auto" ]]; then
            assert_eq "8.$fname/$rel class"   "$klass"    "$actual_class"
        fi
    done < "$manifest"

    # Assertions: substring checks against dest or sidecar files.
    # Assertion rows are 4 tab-separated fields:
    #   rel_path  side(dest|sidecar)  required_substring  notes
    # `notes` is read for column-position discipline only — the runner
    # does not assert on it. F-2: a leading `!` on the substring inverts
    # the assertion (must NOT contain). F-6: field-count guard catches
    # malformed rows.
    if [[ -f "$assertions" ]]; then
        local a_rel a_side a_sub a_notes target
        local invert sub_actual
        while IFS=$'\t' read -r a_rel a_side a_sub a_notes; do
            case "$a_rel" in
                \#*|"") continue ;;
            esac
            # F-6: field-count guard for assertion rows.
            if [[ -z "$a_rel" || -z "$a_side" || -z "$a_sub" ]]; then
                t_fail "8.$fname assertion row malformed" \
                    "expected 4 tab-separated fields, got rel='$a_rel' side='$a_side' sub='$a_sub'"
                continue
            fi
            case "$a_side" in
                dest)    target="$proj/$a_rel" ;;
                sidecar) target="$proj/$a_rel.pre-update" ;;
                *)
                    t_fail "8.$fname/$a_rel unknown assertion side='$a_side'"
                    continue
                    ;;
            esac
            if [[ ! -f "$target" ]]; then
                t_fail "8.$fname/$a_rel ($a_side) target missing" "expected $target"
                continue
            fi
            local content
            content=$(cat "$target")
            # F-2: leading `!` inverts the assertion (must NOT contain).
            invert=0
            sub_actual="$a_sub"
            if [[ "${a_sub:0:1}" == "!" ]]; then
                invert=1
                sub_actual="${a_sub:1}"
            fi
            if [[ "$invert" -eq 1 ]]; then
                if [[ "$content" != *"$sub_actual"* ]]; then
                    t_pass "8.$fname/$a_rel ($a_side) does NOT contain '$sub_actual'"
                else
                    t_fail "8.$fname/$a_rel ($a_side) does NOT contain '$sub_actual'" \
                        "found unexpected substring"
                fi
            else
                assert_contains "8.$fname/$a_rel ($a_side) contains '$sub_actual'" \
                    "$content" "$sub_actual"
            fi
        done < "$assertions"
    fi

    # Render the truthful report and confirm every manifest rel appears.
    customization_report "$state/dispositions.tsv" "$state/report.md" \
        "BD-096 fixture: $fname" >/dev/null
    local report
    report=$(cat "$state/report.md")
    while IFS=$'\t' read -r rel klass expected notes; do
        case "$rel" in
            \#*|"") continue ;;
        esac
        if [[ "$report" == *"$rel"* ]]; then
            t_pass "8.$fname/$rel in truthful report"
        else
            t_fail "8.$fname/$rel missing from truthful report"
        fi
    done < "$manifest"

    rm -rf "$work"
}

# F-7: auto-discover fixture directories under FIXTURES_DIR. Sorted via
# `LC_ALL=C ... | sort` for deterministic ordering across machines (so
# pass/fail diffability holds across macOS / Linux CI). New fixtures
# dropped into FIXTURES_DIR/ are picked up automatically — no runner
# edit required, fulfilling the README "How to add a fixture" claim.
for fixture_path in $(LC_ALL=C ls -d "$FIXTURES_DIR"/*/ 2>/dev/null | sort); do
    [[ -d "$fixture_path" ]] || continue
    fixture=$(basename "$fixture_path")
    printf "\n--- 8.%s ---\n" "$fixture"
    run_fixture "$fixture"
done

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
