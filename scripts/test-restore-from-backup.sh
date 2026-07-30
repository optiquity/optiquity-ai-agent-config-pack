#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-restore-from-backup.sh — unit tests for restore-from-backup.sh
# and the three-way classifier in scripts/lib/three-way.sh.
#
# Builds synthetic backup-directory and three-way-input fixtures under a
# temp dir, runs the helpers, asserts expected output, and exits 0 on
# all-pass / 1 on any failure. Read-only with respect to the pack repo;
# all fixtures live under a temporary directory cleaned up on exit.
#
# Usage:    bash scripts/test-restore-from-backup.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/three-way.sh
source "$SCRIPT_DIR/lib/three-way.sh"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-restore.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}

assert_file_exists() {
    local label="$1" path="$2"
    if [[ -f "$path" ]]; then pass "$label"
    else fail "$label" "exists: $path" "missing"
    fi
}

assert_file_absent() {
    local label="$1" path="$2"
    if [[ ! -e "$path" ]]; then pass "$label"
    else fail "$label" "absent: $path" "present"
    fi
}

# ── three_way_classify tests ────────────────────────────────────────────────

echo "── three_way_classify (canonical four-case) ──"

mkdir -p "$FIXTURE_BASE/tw"
TW="$FIXTURE_BASE/tw"

# Three identical files.
echo "alpha" > "$TW/identical-base"
echo "alpha" > "$TW/identical-ours"
echo "alpha" > "$TW/identical-theirs"
assert_eq "all-equal -> unchanged-pack" "unchanged-pack" \
    "$(three_way_classify "$TW/identical-base" "$TW/identical-ours" "$TW/identical-theirs")"

# base == ours, theirs differs.
echo "alpha" > "$TW/u-base"
echo "alpha" > "$TW/u-ours"
echo "beta" > "$TW/u-theirs"
assert_eq "base==ours, theirs differs -> pack-update-applied" "pack-update-applied" \
    "$(three_way_classify "$TW/u-base" "$TW/u-ours" "$TW/u-theirs")"

# base == theirs, ours differs.
echo "alpha" > "$TW/m-base"
echo "alpha-customized" > "$TW/m-ours"
echo "alpha" > "$TW/m-theirs"
assert_eq "base==theirs, ours differs -> merged-with-customization" "merged-with-customization" \
    "$(three_way_classify "$TW/m-base" "$TW/m-ours" "$TW/m-theirs")"

# All three differ.
echo "alpha" > "$TW/r-base"
echo "alpha-customized" > "$TW/r-ours"
echo "beta" > "$TW/r-theirs"
assert_eq "all differ -> real-merge-required" "real-merge-required" \
    "$(three_way_classify "$TW/r-base" "$TW/r-ours" "$TW/r-theirs")"

# ── three_way_classify auxiliary tokens ─────────────────────────────────────

echo "── three_way_classify (auxiliary cases) ──"

# new-file-in-pack: only theirs exists.
echo "fresh" > "$TW/new-theirs"
assert_eq "only theirs -> new-file-in-pack" "new-file-in-pack" \
    "$(three_way_classify "" "" "$TW/new-theirs")"

# project-only-file: only ours exists.
echo "proj" > "$TW/proj-ours"
assert_eq "only ours -> project-only-file" "project-only-file" \
    "$(three_way_classify "" "$TW/proj-ours" "")"

# project-shadows-new-pack: ours and theirs but no base.
echo "proj" > "$TW/shadow-ours"
echo "pack" > "$TW/shadow-theirs"
assert_eq "ours+theirs no base -> project-shadows-new-pack" "project-shadows-new-pack" \
    "$(three_way_classify "" "$TW/shadow-ours" "$TW/shadow-theirs")"

# removed-by-pack-clean: base+ours match, theirs absent.
echo "x" > "$TW/rmclean-base"
echo "x" > "$TW/rmclean-ours"
assert_eq "base==ours, no theirs -> removed-by-pack-clean" "removed-by-pack-clean" \
    "$(three_way_classify "$TW/rmclean-base" "$TW/rmclean-ours" "")"

# removed-by-pack-customized: base+ours differ, theirs absent.
echo "x" > "$TW/rmcust-base"
echo "x-edited" > "$TW/rmcust-ours"
assert_eq "base!=ours, no theirs -> removed-by-pack-customized" "removed-by-pack-customized" \
    "$(three_way_classify "$TW/rmcust-base" "$TW/rmcust-ours" "")"

# removed-everywhere: only base exists.
echo "x" > "$TW/everywhere-base"
assert_eq "only base -> removed-everywhere" "removed-everywhere" \
    "$(three_way_classify "$TW/everywhere-base" "" "")"

# project-deleted-pack-kept: base+theirs but no ours.
echo "x" > "$TW/del-base"
echo "x" > "$TW/del-theirs"
assert_eq "base+theirs no ours -> project-deleted-pack-kept" "project-deleted-pack-kept" \
    "$(three_way_classify "$TW/del-base" "" "$TW/del-theirs")"

# no-inputs: error case.
out=$(three_way_classify "" "" "" 2>&1 || true)
assert_eq "no inputs -> no-inputs" "no-inputs" "$out"

# ── three_way_dispatch tests ────────────────────────────────────────────────

echo "── three_way_dispatch ──"

dispatch_out=$(three_way_dispatch "$TW/identical-base" "$TW/identical-ours" "$TW/identical-theirs" "CLAUDE.md")
expected_dispatch=$'unchanged-pack\tCLAUDE.md\tbase=yes ours=yes theirs=yes'
assert_eq "dispatch all-equal" "$expected_dispatch" "$dispatch_out"

dispatch_out=$(three_way_dispatch "" "$TW/proj-ours" "" "x-custom.md")
expected_dispatch=$'project-only-file\tx-custom.md\tbase=no ours=yes theirs=no'
assert_eq "dispatch project-only" "$expected_dispatch" "$dispatch_out"

# ── restore-from-backup.sh tests ────────────────────────────────────────────

echo "── restore-from-backup.sh ──"

# Build a synthetic backup directory mirroring the real flat layout.
SRC="$FIXTURE_BASE/synthetic-backup"
mkdir -p "$SRC"
mkdir -p "$SRC/.claude/agents" "$SRC/.codex/agents" \
         "$SRC/.agents-plugin/optiquity-agents/agents"
mkdir -p "$SRC/docs/pack" "$SRC/scripts"

# Trinity at root.
echo "claude trinity" > "$SRC/CLAUDE.md"
echo "agents trinity" > "$SRC/AGENTS.md"
echo "gemini trinity" > "$SRC/GEMINI.md"
# Configs at root.
echo "settings" > "$SRC/.claude/settings.json"
echo "agent files" > "$SRC/.claude/agents/coder.md"
# Agent runner at root.
echo "agent-run" > "$SRC/agent-run.sh"
# .mcp at root.
echo "mcp example" > "$SRC/.mcp.json.example"
# docs/pack/ legitimately nested in backup.
echo "pm-chat content" > "$SRC/docs/pack/PM-CHAT.md"
echo "methodology content" > "$SRC/docs/pack/METHODOLOGY.md"
# Flattened docs-pack-* at root.
echo "platform skills content" > "$SRC/docs-pack-PLATFORM-SKILLS.md"
echo "prompt templates content" > "$SRC/docs-pack-PROMPT-TEMPLATES.md"
# scripts/ nested.
echo "bootstrap" > "$SRC/scripts/bootstrap.sh"
# Migration metadata that must NOT land in target.
echo "report" > "$SRC/report.md"
echo "customization: none" > "$SRC/status.txt"
touch "$SRC/postrun-pending"
touch "$SRC/stage-S0.done" "$SRC/stage-S5.done"

DST="$FIXTURE_BASE/restored"

# Run the restore.
"$SCRIPT_DIR/restore-from-backup.sh" "$SRC" "$DST" >/dev/null

# Assertions on the restored tree.
assert_file_exists "trinity at root: CLAUDE.md"   "$DST/CLAUDE.md"
assert_file_exists "trinity at root: AGENTS.md"   "$DST/AGENTS.md"
assert_file_exists "trinity at root: GEMINI.md"   "$DST/GEMINI.md"
assert_file_exists ".claude/settings.json"        "$DST/.claude/settings.json"
assert_file_exists ".claude/agents/coder.md"      "$DST/.claude/agents/coder.md"
assert_file_exists "agent-run.sh"                  "$DST/agent-run.sh"
assert_file_exists ".mcp.json.example"             "$DST/.mcp.json.example"
assert_file_exists "docs/pack/PM-CHAT.md (nested)" "$DST/docs/pack/PM-CHAT.md"
assert_file_exists "docs/pack/METHODOLOGY.md (nested)" "$DST/docs/pack/METHODOLOGY.md"
# Inversion checks: flat docs-pack-* lands in docs/pack/.
assert_file_exists "docs/pack/PLATFORM-SKILLS.md (inverted)"   "$DST/docs/pack/PLATFORM-SKILLS.md"
assert_file_exists "docs/pack/PROMPT-TEMPLATES.md (inverted)"  "$DST/docs/pack/PROMPT-TEMPLATES.md"
assert_file_absent "flat docs-pack-PLATFORM-SKILLS.md not at root"  "$DST/docs-pack-PLATFORM-SKILLS.md"
assert_file_exists "scripts/bootstrap.sh"          "$DST/scripts/bootstrap.sh"
# Migration metadata must NOT be restored.
assert_file_absent "migration metadata: report.md"      "$DST/report.md"
assert_file_absent "migration metadata: status.txt"     "$DST/status.txt"
assert_file_absent "migration metadata: postrun-pending" "$DST/postrun-pending"
assert_file_absent "migration metadata: stage-S0.done"  "$DST/stage-S0.done"
assert_file_absent "migration metadata: stage-S5.done"  "$DST/stage-S5.done"

# Content survived the round-trip.
content=$(cat "$DST/CLAUDE.md")
assert_eq "trinity content preserved" "claude trinity" "$content"
content=$(cat "$DST/docs/pack/PLATFORM-SKILLS.md")
assert_eq "inverted content preserved" "platform skills content" "$content"

# --dry-run mode does not write.
DST2="$FIXTURE_BASE/restored-dryrun"
"$SCRIPT_DIR/restore-from-backup.sh" --dry-run "$SRC" "$DST2" >/dev/null
if [[ ! -d "$DST2" ]] || [[ -z "$(ls -A "$DST2" 2>/dev/null)" ]]; then
    pass "--dry-run leaves target empty"
else
    fail "--dry-run leaves target empty" "empty target" "non-empty"
fi

# Non-empty target refusal.
DST3="$FIXTURE_BASE/non-empty-target"
mkdir -p "$DST3"
echo "preexisting" > "$DST3/something"
if "$SCRIPT_DIR/restore-from-backup.sh" "$SRC" "$DST3" >/dev/null 2>&1; then
    fail "refuse non-empty target" "exit 2" "exit 0"
else
    rc=$?
    assert_eq "refuse non-empty target" "2" "$rc"
fi

# ── Summary ────────────────────────────────────────────────────────────────

echo
echo "tests: $((passes + fails)) total, $passes passed, $fails failed"
[[ $fails -eq 0 ]] && exit 0 || exit 1
