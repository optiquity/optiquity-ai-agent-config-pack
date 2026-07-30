#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-compare-agent-trinity.sh — unit tests for compare-agent-trinity.py.
#
# Builds synthetic three-tool agent file trios under a temp pack-shape
# directory and asserts the comparator's exit codes and report content
# for each scenario:
#   - All three identical → PASS (exit 0)
#   - Backtick-only divergence → PASS in default (lenient) mode, DIVERGENT in --strict
#   - Substantive body divergence → DIVERGENT (exit 2)
#   - Whitespace-only divergence → PASS (whitespace normalized)
#   - Missing tool variant → error (exit 1)
#   - --all mode summary
#
# Usage: bash scripts/test-compare-agent-trinity.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPARE="$SCRIPT_DIR/compare-agent-trinity.py"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-compare-trinity.XXXXXX")"
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

# Build a minimal pack-shape directory under $FIXTURE_BASE/<scenario>/project-template/
# The third leg is the Antigravity client plugin bundle roster
# `.agents-plugin/optiquity-agents/agents/` (BD-221: Antigravity ships agents
# as a plugin BUNDLE, not a loose per-CLI dir).
mkpack() {
    local scenario="$1"
    local d="$FIXTURE_BASE/$scenario/project-template"
    mkdir -p "$d/.claude/agents" "$d/.codex/agents" \
             "$d/.agents-plugin/optiquity-agents/agents"
    echo "$FIXTURE_BASE/$scenario"
}

write_claude_agent() {
    local pack="$1" name="$2" body="$3"
    cat > "$pack/project-template/.claude/agents/$name.md" <<EOF
---
name: $name
description: Test agent for $name
tools: Read, Grep, Glob, Bash
---

$body
EOF
}

write_codex_agent() {
    local pack="$1" name="$2" body="$3"
    cat > "$pack/project-template/.codex/agents/$name.toml" <<EOF
name = "$name"
description = "Test agent for $name"
model = "gpt-5"
developer_instructions = """
$body
"""
EOF
}

# Third-leg writer: the Antigravity client plugin-bundle agent
# (BD-221). Markdown with YAML frontmatter, same as the Claude leg;
# the Antigravity bundle templates pin no model string (a forward-looking
# `#27305` model hedge), so the synthetic fixtures here omit the model
# field entirely — the comparator ignores tool-specific frontmatter
# (model, etc.) per "What is NOT compared".
write_agents_agent() {
    local pack="$1" name="$2" body="$3"
    cat > "$pack/project-template/.agents-plugin/optiquity-agents/agents/$name.md" <<EOF
---
name: $name
description: Test agent for $name
---

$body
EOF
}

# ── Test 1: identical bodies → PASS ────────────────────────────────────────

echo "── identical bodies ──"
pack=$(mkpack "identical")
body=$(cat <<'BODY'
You are the test agent.

Responsibilities:
- Do the thing.
- Do the other thing.
BODY
)
write_claude_agent "$pack" "test1" "$body"
write_codex_agent "$pack" "test1" "$body"
write_agents_agent "$pack" "test1" "$body"
out=$(python3 "$COMPARE" test1 --pack "$pack" 2>&1); rc=$?
assert_eq "identical → exit 0" "0" "$rc"
case "$out" in
    *"PASS"*) pass "identical → PASS report" ;;
    *) fail "identical → PASS report" "PASS" "$out" ;;
esac

# ── Test 2: backtick-only divergence → lenient PASS, strict DIVERGENT ──────

echo "── backtick-only divergence ──"
pack=$(mkpack "backtick")
body_with_ticks=$(cat <<'BODY'
You are the test agent.

Load the `repo-ops` skill for git workflow guidance.
BODY
)
body_without_ticks=$(cat <<'BODY'
You are the test agent.

Load the repo-ops skill for git workflow guidance.
BODY
)
write_claude_agent "$pack" "test2" "$body_with_ticks"
write_codex_agent "$pack" "test2" "$body_without_ticks"
write_agents_agent "$pack" "test2" "$body_with_ticks"

python3 "$COMPARE" test2 --pack "$pack" >/dev/null 2>&1; rc=$?
assert_eq "backtick-only (lenient default) → exit 0" "0" "$rc"

python3 "$COMPARE" test2 --pack "$pack" --strict >/dev/null 2>&1; rc=$?
assert_eq "backtick-only (--strict) → exit 2" "2" "$rc"

# ── Test 3: substantive body divergence → DIVERGENT ────────────────────────

echo "── substantive body divergence ──"
pack=$(mkpack "diverged")
write_claude_agent "$pack" "test3" "First version with feature A and rule X."
write_codex_agent "$pack" "test3" "Different version without rule X."
write_agents_agent "$pack" "test3" "First version with feature A and rule X."
python3 "$COMPARE" test3 --pack "$pack" >/dev/null 2>&1; rc=$?
assert_eq "substantive divergence → exit 2" "2" "$rc"

# ── Test 4: whitespace-only divergence → PASS ──────────────────────────────

echo "── whitespace-only divergence ──"
pack=$(mkpack "whitespace")
body_a=$(printf 'Line one.\nLine two.\n\nLine three.\n')
body_b=$(printf 'Line one.    Line two.   Line three.\n')
write_claude_agent "$pack" "test4" "$body_a"
write_codex_agent "$pack" "test4" "$body_b"
write_agents_agent "$pack" "test4" "$body_a"
python3 "$COMPARE" test4 --pack "$pack" >/dev/null 2>&1; rc=$?
assert_eq "whitespace-only divergence → exit 0" "0" "$rc"

# ── Test 5: missing tool variant → error ───────────────────────────────────

echo "── missing tool variant ──"
pack=$(mkpack "missing")
body="Test body."
write_claude_agent "$pack" "test5" "$body"
write_codex_agent "$pack" "test5" "$body"
# (no Antigravity bundle variant)
python3 "$COMPARE" test5 --pack "$pack" >/dev/null 2>&1; rc=$?
assert_eq "missing tool variant → exit 1" "1" "$rc"

# ── Test 6: --all mode summary count ──────────────────────────────────────

echo "── --all mode ──"
pack=$(mkpack "all-mode")
write_claude_agent "$pack" "agent_a" "Same body."
write_codex_agent "$pack" "agent_a" "Same body."
write_agents_agent "$pack" "agent_a" "Same body."

write_claude_agent "$pack" "agent_b" "Body A."
write_codex_agent "$pack" "agent_b" "Body B."
write_agents_agent "$pack" "agent_b" "Body A."

out=$(python3 "$COMPARE" --all --pack "$pack" --summary-only 2>&1); rc=$?
assert_eq "--all with one divergent → exit 2" "2" "$rc"
case "$out" in
    *"2 agents checked; 1 divergent"*) pass "--all summary count" ;;
    *) fail "--all summary count" "2 checked; 1 divergent" "$out" ;;
esac

# ── Test 7: name field mismatch → DIVERGENT ───────────────────────────────

echo "── name field mismatch ──"
pack=$(mkpack "name-mismatch")
write_claude_agent "$pack" "test7" "Same body."
write_agents_agent "$pack" "test7" "Same body."
# Codex with a different name field in TOML
cat > "$pack/project-template/.codex/agents/test7.toml" <<'EOF'
name = "wrong-name"
description = "Test"
model = "gpt-5"
developer_instructions = """
Same body.
"""
EOF
python3 "$COMPARE" test7 --pack "$pack" >/dev/null 2>&1; rc=$?
assert_eq "name field mismatch → exit 2" "2" "$rc"

# ── Summary ────────────────────────────────────────────────────────────────

echo
echo "tests: $((passes + fails)) total, $passes passed, $fails failed"
[[ $fails -eq 0 ]] && exit 0 || exit 1
