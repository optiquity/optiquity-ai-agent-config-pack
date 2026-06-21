#!/usr/bin/env bash
# scripts/tests/pack-help-test.sh — BD-075 pack-help.sh + surface-detection
# tests. Covers detect_pack_surface (V3 §28.2.3) and pack-help.sh's
# single-fragment emit. BD-243 NUCLEAR: the deferred-tracker fragment is
# deleted and `pack help` no longer advertises tracker mode — these tests
# assert the tracker section is ABSENT on both surfaces and the live
# `pack td` rows are PRESENT.

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

# shellcheck disable=SC1091
source "$LIB_DIR/detect.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: detect_pack_surface (V3 §28.2.3)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: detect_pack_surface ===\n"

# 1.1 pack repo: BD-203 A14b — the canonical pack signal is the
# `/backlog/` per-entry tree carrying `BD-NNN.md` entry files (the
# no-mirror SSOT). The pack-surface branch of detect_pack_surface is
# repointed to the tree; include a second canonical entry (BD-211: no
# letter suffix) to exercise the detection regex.
TR_PACK=$(mktemp -d -t ph-pack.XXXXXX)
mkdir -p "$TR_PACK/backlog"
cat > "$TR_PACK/backlog/BD-001.md" <<'EOF'
<!-- per-entry source: /backlog/BD-001.md; contract: /backlog/_rules.md -->
**BD-001 — A**
Status: Open
EOF
cat > "$TR_PACK/backlog/BD-900.md" <<'EOF'
<!-- per-entry source: /backlog/BD-900.md; contract: /backlog/_rules.md -->
**BD-900 — Canonical entry**
Status: Resolved
EOF
assert_eq "1.1 pack repo (/backlog/ tree) → pack-surface: pack" \
    "pack-surface: pack" "$(detect_pack_surface "$TR_PACK")"
rm -rf "$TR_PACK"

# 1.2 client repo: docs/project/BACKLOG.md with TD-NNN entries.
TR_CLI=$(mktemp -d -t ph-cli.XXXXXX)
mkdir -p "$TR_CLI/docs/project"
cat > "$TR_CLI/docs/project/BACKLOG.md" <<'EOF'
**TD-001 — A**
Status: Open
EOF
assert_eq "1.2 client repo (docs/project/) → pack-surface: client" \
    "pack-surface: client" "$(detect_pack_surface "$TR_CLI")"
rm -rf "$TR_CLI"

# 1.3 client repo with BACKLOG.md at root (legacy v9 layout).
TR_LEG=$(mktemp -d -t ph-leg.XXXXXX)
cat > "$TR_LEG/BACKLOG.md" <<'EOF'
**TD-001 — A**
Status: Open
EOF
assert_eq "1.3 client repo (root BACKLOG.md, TD entries) → client" \
    "pack-surface: client" "$(detect_pack_surface "$TR_LEG")"
rm -rf "$TR_LEG"

# 1.4 ambiguous: both BD- and TD- entries in the same BACKLOG.
TR_AMB=$(mktemp -d -t ph-amb.XXXXXX)
cat > "$TR_AMB/BACKLOG.md" <<'EOF'
**BD-001 — A**
Status: Open

**TD-002 — B**
Status: Open
EOF
assert_eq "1.4 mixed BD + TD → ambiguous" \
    "pack-surface: ambiguous" "$(detect_pack_surface "$TR_AMB")"
rm -rf "$TR_AMB"

# 1.5 ambiguous: no BACKLOG.md at all.
TR_NB=$(mktemp -d -t ph-nb.XXXXXX)
assert_eq "1.5 no BACKLOG.md → ambiguous" \
    "pack-surface: ambiguous" "$(detect_pack_surface "$TR_NB")"
rm -rf "$TR_NB"

# ─────────────────────────────────────────────────────────────────
# Group 2: pack-help.sh end-to-end
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: pack-help.sh end-to-end ===\n"

# 2.1 pack repo (use the actual pack-repo root): output contains the
# pack-side header + pack commands, the live `pack td` rows, and NO
# deferred-tracker advertising (BD-243 NUCLEAR).
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$REPO_ROOT" 2>/dev/null)
[[ "$output" == *"# Pack v11 — verb reference (pack repo)"* ]] \
    && t_pass "2.1 pack-side header present" \
    || t_fail "2.1 pack-side header" "got: ${output:0:200}"
[[ "$output" == *"## Pack commands"* ]] \
    && t_pass "2.1 pack commands section present" \
    || t_fail "2.1 pack commands section"
# 2.1 tracker advertising ABSENT (deferred fragment deleted).
[[ "$output" != *"Tracker commands"* && "$output" != *"pack tracker"* ]] \
    && t_pass "2.1 tracker advertising absent (pack surface)" \
    || t_fail "2.1 tracker advertising leaked" "got: ${output:0:400}"
# 2.1 live `pack td` rows present (relocated into HELP-FRAGMENT-PACK).
[[ "$output" == *"pack td promote"* && "$output" == *"pack td resolve"* ]] \
    && t_pass "2.1 pack td rows present" \
    || t_fail "2.1 pack td rows missing"
# 2.1 no leftover sibling-include placeholder line.
[[ "$output" != *"[Included from"* ]] \
    && t_pass "2.1 no include-placeholder leak" \
    || t_fail "2.1 include placeholder still present"

# 2.2 client surface from a fixture tree. BD-243 NUCLEAR: only
# HELP-FRAGMENT.md ships now (the deferred-tracker fragment is deleted).
# Assert the client header + client-only verb are present, tracker
# advertising is absent, and the live `pack td` rows are present.
TR_CLI2=$(mktemp -d -t ph-cli2.XXXXXX)
mkdir -p "$TR_CLI2/docs/project" "$TR_CLI2/docs/pack"
cat > "$TR_CLI2/docs/project/BACKLOG.md" <<'EOF'
**TD-001 — A**
Status: Open
EOF
cp "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT.md" "$TR_CLI2/docs/pack/"
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_CLI2" 2>/dev/null)
[[ "$output" == *"# Pack v11 — verb reference (this project)"* ]] \
    && t_pass "2.2 client-side header present" \
    || t_fail "2.2 client-side header" "got: ${output:0:200}"
[[ "$output" != *"Tracker commands"* && "$output" != *"pack tracker"* ]] \
    && t_pass "2.2 tracker advertising absent (client surface)" \
    || t_fail "2.2 tracker advertising leaked" "got: ${output:0:400}"
[[ "$output" == *"pack td promote"* && "$output" == *"pack td resolve"* ]] \
    && t_pass "2.2 client pack td rows present" \
    || t_fail "2.2 client pack td rows missing"
[[ "$output" == *"agent-run.sh"* ]] \
    && t_pass "2.2 client-only verb (agent-run) listed" \
    || t_fail "2.2 client-only verb"
# 2.2.a no leftover sibling-include placeholder line.
[[ "$output" != *"[Included from"* ]] \
    && t_pass "2.2.a no include-placeholder leak in client output" \
    || t_fail "2.2.a include placeholder still present"
rm -rf "$TR_CLI2"

# 2.2.c source-of-truth client fragment: render pack-help.sh against
# project-template/docs/pack/ (the in-tree source the install pipeline
# copies verbatim). No tracker advertising; no include-placeholder leak.
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" \
              --root "$REPO_ROOT/project-template" --surface client 2>/dev/null)
[[ "$output" != *"Tracker commands"* && "$output" != *"pack tracker"* \
   && "$output" != *"[Included from"* ]] \
    && t_pass "2.2.c no tracker advertising / placeholder on source-of-truth client fragment" \
    || t_fail "2.2.c tracker advertising or placeholder leaked on client fragment"

# 2.2.d pack-side source-of-truth: same assertion on the pack surface.
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$REPO_ROOT" --surface pack 2>/dev/null)
[[ "$output" != *"Tracker commands"* && "$output" != *"pack tracker"* \
   && "$output" != *"[Included from"* ]] \
    && t_pass "2.2.d no tracker advertising / placeholder on pack-side fragment" \
    || t_fail "2.2.d tracker advertising or placeholder leaked on pack-side fragment"

# 2.3 explicit --surface override on a tree without BACKLOG.md.
# BD-175: pack-side fragments live at pack-ops/ — mirror the canonical
# layout in the fixture so pack-help.sh's pack-ops-first resolution
# fires the post-reorg code path.
TR_OV=$(mktemp -d -t ph-ov.XXXXXX)
mkdir -p "$TR_OV/pack-ops"
cp "$REPO_ROOT/pack-ops/HELP-FRAGMENT-PACK.md" "$TR_OV/pack-ops/"
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_OV" --surface pack 2>/dev/null)
[[ "$output" == *"# Pack v11 — verb reference (pack repo)"* ]] \
    && t_pass "2.3 --surface pack override prints pack fragment" \
    || t_fail "2.3 --surface override" "got: ${output:0:200}"
rm -rf "$TR_OV"

# 2.4 ambiguous tree (no BACKLOG.md at all): exit non-zero with helpful stderr.
TR_NONE=$(mktemp -d -t ph-none.XXXXXX)
err=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_NONE" 2>&1 >/dev/null) || true
rc=$?
[[ "$err" == *"no HELP-FRAGMENT-*.md found"* ]] \
    && t_pass "2.4 missing fragments → helpful stderr" \
    || t_fail "2.4 missing fragments stderr" "got: $err"
rm -rf "$TR_NONE"

# 2.5 fragment is emitted verbatim (single-fragment cat; BD-243 NUCLEAR
# removed the sibling-include inlining path).
TR_VER=$(mktemp -d -t ph-ver.XXXXXX)
cat > "$TR_VER/HELP-FRAGMENT-PACK.md" <<'EOF'
# header
FRAGMENT-CONTENT-MARKER
# footer
EOF
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_VER" --surface pack 2>/dev/null)
[[ "$output" == *"# header"*"FRAGMENT-CONTENT-MARKER"*"# footer"* ]] \
    && t_pass "2.5 fragment emitted verbatim (order preserved)" \
    || t_fail "2.5 fragment emit order" "got: $output"
rm -rf "$TR_VER"

# 2.6 unknown flag → non-zero + usage on stderr.
err=$(bash "$REPO_ROOT/scripts/pack-help.sh" --bogus 2>&1 >/dev/null) || true
[[ "$err" == *"unknown option '--bogus'"* ]] \
    && t_pass "2.6 unknown flag → typed error" \
    || t_fail "2.6 unknown flag" "got: $err"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASSED"
printf "Failed: %d\n" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
fi
exit 1
