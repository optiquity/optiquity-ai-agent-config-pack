#!/usr/bin/env bash
# scripts/tests/pack-help-test.sh — BD-075 pack-help.sh + surface-detection
# tests. Covers detect_pack_surface (V3 §28.2.3) and pack-help.sh's
# fragment inlining (V3 §28.2.4 / DELTA L1).

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

# 1.1 pack repo: BACKLOG.md at root with BD-NNN entries.
TR_PACK=$(mktemp -d -t ph-pack.XXXXXX)
cat > "$TR_PACK/BACKLOG.md" <<'EOF'
**BD-001 — A**
Status: Open

**BD-002 — B**
Status: Open
EOF
assert_eq "1.1 pack repo → pack-surface: pack" \
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
# pack-side header, the tracker section (inlined), and the colloquial
# mappings table.
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$REPO_ROOT" 2>/dev/null)
[[ "$output" == *"# Pack v11 — verb reference (pack repo)"* ]] \
    && t_pass "2.1 pack-side header present" \
    || t_fail "2.1 pack-side header" "got: ${output:0:200}"
[[ "$output" == *"## Pack commands"* ]] \
    && t_pass "2.1 pack commands section present" \
    || t_fail "2.1 pack commands section"
[[ "$output" == *"# Tracker commands (v11+)"* ]] \
    && t_pass "2.1 tracker section inlined" \
    || t_fail "2.1 tracker section inlined"
[[ "$output" == *"set up the tracker"* ]] \
    && t_pass "2.1 colloquial mapping inlined" \
    || t_fail "2.1 colloquial mapping inlined"
# Placeholder line should NOT appear in output (it must have been replaced).
[[ "$output" != *"[Included from \`HELP-FRAGMENT-TRACKER.md\`"* ]] \
    && t_pass "2.1 placeholder line replaced" \
    || t_fail "2.1 placeholder line still present"

# 2.2 client surface from a fixture tree.
TR_CLI2=$(mktemp -d -t ph-cli2.XXXXXX)
mkdir -p "$TR_CLI2/docs/project" "$TR_CLI2/docs/pack"
cat > "$TR_CLI2/docs/project/BACKLOG.md" <<'EOF'
**TD-001 — A**
Status: Open
EOF
cp "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT.md" "$TR_CLI2/docs/pack/"
cp "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" "$TR_CLI2/docs/pack/"
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_CLI2" 2>/dev/null)
[[ "$output" == *"# Pack v11 — verb reference (this project)"* ]] \
    && t_pass "2.2 client-side header present" \
    || t_fail "2.2 client-side header" "got: ${output:0:200}"
[[ "$output" == *"# Tracker commands (v11+)"* ]] \
    && t_pass "2.2 client tracker section inlined" \
    || t_fail "2.2 client tracker section inlined"
[[ "$output" == *"agent-run.sh"* ]] \
    && t_pass "2.2 client-only verb (agent-run) listed" \
    || t_fail "2.2 client-only verb"
rm -rf "$TR_CLI2"

# 2.3 explicit --surface override on a tree without BACKLOG.md.
# BD-175: pack-side fragments live at pack-ops/ — mirror the canonical
# layout in the fixture so pack-help.sh's pack-ops-first resolution
# fires the post-reorg code path.
TR_OV=$(mktemp -d -t ph-ov.XXXXXX)
mkdir -p "$TR_OV/pack-ops"
cp "$REPO_ROOT/pack-ops/HELP-FRAGMENT-PACK.md" "$TR_OV/pack-ops/"
cp "$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md" "$TR_OV/pack-ops/"
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

# 2.5 fragment placeholder line is replaced verbatim by the tracker fragment.
TR_VER=$(mktemp -d -t ph-ver.XXXXXX)
cat > "$TR_VER/HELP-FRAGMENT-PACK.md" <<'EOF'
# header
[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]
# footer
EOF
cat > "$TR_VER/HELP-FRAGMENT-TRACKER.md" <<'EOF'
TRACKER-CONTENT-MARKER
EOF
output=$(bash "$REPO_ROOT/scripts/pack-help.sh" --root "$TR_VER" --surface pack 2>/dev/null)
[[ "$output" == *"# header"*"TRACKER-CONTENT-MARKER"*"# footer"* ]] \
    && t_pass "2.5 inline preserves surrounding lines + replaces placeholder" \
    || t_fail "2.5 inline order" "got: $output"
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
