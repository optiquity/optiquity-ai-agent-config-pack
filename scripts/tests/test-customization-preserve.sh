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
assert_eq "1.6 .codex/config.toml"  "codex-config" \
    "$(customization_classify .codex/config.toml)"
assert_eq "1.7 .codex/config.toml.example"  "codex-config-example" \
    "$(customization_classify .codex/config.toml.example)"
assert_eq "1.8 .gemini/.env"  "gemini-env" \
    "$(customization_classify .gemini/.env)"
assert_eq "1.9 docs/pack/PM-CHAT.md"  "pm-chat" \
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

# ─────────────────────────────────────────────────────────────────────────
# Group 2: text-strategy dispositions
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 2: text-strategy 4-case ===\n"

setup_state() {
    rm -rf "$1"
    customization_preserve_init "$1" ".pre-update"
}

T2=$(mktemp -d -t cp-text.XXXXXX)
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

# 2.4 real-merge-required: both edited; sidecar.
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
assert_eq "2.4 action"      "sidecar"   "$(tsv_col 4 "$last")"
assert_eq "2.4 dest = theirs"  "v2"      "$(cat "$T2/dest.md")"
assert_eq "2.4 sidecar = ours" "v1-mine" "$(cat "$T2/dest.md.pre-update")"
[[ -f "$state/diffs/doc.md.three-way.diff" ]] \
    && t_pass "2.4 three-way diff written" \
    || t_fail "2.4 three-way diff written"

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

rm -rf "$T2"

# ─────────────────────────────────────────────────────────────────────────
# Group 3: structured config (JSON allowlist via merge-json.py)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 3: structured config (JSON) ===\n"

T3=$(mktemp -d -t cp-json.XXXXXX)
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

# ─────────────────────────────────────────────────────────────────────────
# Group 4: structured config (TOML — OT model_providers removal case)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 4: structured config (TOML) ===\n"

T4=$(mktemp -d -t cp-toml.XXXXXX)
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
# Group 5: gemini-env (KEY=VALUE preservation)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 5: gemini-env preservation ===\n"

T5=$(mktemp -d -t cp-env.XXXXXX)
state="$T5/state"
setup_state "$state"

cat > "$T5/ours.env" <<'EOF'
AGENT_CAPABILITIES=swift,python
PROJECT_VAR=keep-me
EOF
cat > "$T5/theirs.env" <<'EOF'
AGENT_CAPABILITIES=swift
NEW_PACK_VAR=v11-default
EOF
cp "$T5/ours.env" "$T5/dest.env"
customization_preserve "" "$T5/ours.env" "$T5/theirs.env" \
    ".gemini/.env" "$T5/dest.env" gemini-env >/dev/null
merged=$(cat "$T5/dest.env")
# Project value of AGENT_CAPABILITIES wins.
assert_contains "5.1 AGENT_CAPABILITIES preserves project value" "$merged" "swift,python"
assert_contains "5.1 PROJECT_VAR preserved" "$merged" "PROJECT_VAR=keep-me"
# Pack-new key adopted.
assert_contains "5.1 NEW_PACK_VAR adopted"  "$merged" "NEW_PACK_VAR=v11-default"
# M1: project-shadows-new-pack (no base + both present + differ) now
# routes through the merge branch and records needs-reconciliation with
# sidecar (so the conflict is visible in the report).
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "5.1 disposition = needs-reconciliation" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"
[[ -f "$T5/dest.env.pre-update" ]] \
    && t_pass "5.1 sidecar written" \
    || t_fail "5.1 sidecar missing"

# 5.2 M2 + M3: dup-keys + leading whitespace. Use BASE + OURS edited from
# BASE + THEIRS edited from BASE so we hit real-merge-required.
setup_state "$state"
cat > "$T5/base2.env" <<'EOF'
A=base
B=base
EOF
# OURS has a duplicate KEY (later wins by env-file convention) and a
# leading-whitespace KEY=. Both must round-trip correctly.
cat > "$T5/ours2.env" <<'EOF'
A=1
A=2
  B=indented
PROJECT_ONLY=keep
EOF
cat > "$T5/theirs2.env" <<'EOF'
A=pack-new
B=pack-new
NEW_PACK_VAR=adopted
EOF
cp "$T5/ours2.env" "$T5/dest2.env"
customization_preserve "$T5/base2.env" "$T5/ours2.env" "$T5/theirs2.env" \
    ".gemini/.env" "$T5/dest2.env" gemini-env >/dev/null
merged=$(cat "$T5/dest2.env")
# M2: duplicate A= must NOT be doubled in output.
a_count=$(printf '%s\n' "$merged" | grep -c '^A=' || true)
assert_eq "5.2 dup-key A= appears once" "1" "$a_count"
# M2: last-wins semantics — ours value of A is "A=2" (last in ours).
assert_contains "5.2 dup-key last-wins (A=2)" "$merged" "A=2"
# M3: leading-whitespace B=indented must survive (project value wins,
# leading whitespace acceptably stripped).
assert_contains "5.2 leading-whitespace B preserved" "$merged" "B=indented"
# PROJECT_ONLY preserved.
assert_contains "5.2 project-only key preserved" "$merged" "PROJECT_ONLY=keep"
# Pack-new key adopted.
assert_contains "5.2 NEW_PACK_VAR adopted"      "$merged" "NEW_PACK_VAR=adopted"
last=$(tail -1 "$state/dispositions.tsv")
assert_eq "5.2 disposition = needs-reconciliation" \
    "customization-detected-needs-reconciliation" "$(tsv_col 1 "$last")"

rm -rf "$T5"

# ─────────────────────────────────────────────────────────────────────────
# Group 6: custom-agent + custom-script preserved untouched
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6: custom-agent / custom-script preservation ===\n"

T6=$(mktemp -d -t cp-x.XXXXXX)
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

rm -rf "$T6"

# ─────────────────────────────────────────────────────────────────────────
# Group 6b: B1 init guard (caller contract — _CP_PACK_ROOT must be set)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 6b: init guard for _CP_PACK_ROOT (B1) ===\n"

# Subshell so unsetting _CP_PACK_ROOT doesn't leak into later tests.
T6B=$(mktemp -d -t cp-init.XXXXXX)
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
# Group 7: truthful report (BD-059 contract)
# ─────────────────────────────────────────────────────────────────────────

printf "\n=== Group 7: truthful report ===\n"

T7=$(mktemp -d -t cp-rep.XXXXXX)
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
