#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-detect.sh — unit tests for scripts/lib/detect.sh
#
# Runs each detect_* function against fixture git repos / filesystem
# trees with known state and asserts the expected stdout. Read-only
# with respect to the pack repo; all fixtures live under a temporary
# directory cleaned up on exit.
#
# Usage:    bash scripts/test-detect.sh
# Exit 0 on all pass; exit 1 on any failure.
#
# Phase 4 deliverable per V10-IMPLEMENTATION-PLAN line 45 (B5
# obligation) and V10-PHASE-4-PLAN.md C-V10-14.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"

FIXTURE_BASE="$(mktemp -d -t test-detect.XXXXXX)"
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

mkfixture() {
    local name="$1"
    local dir="$FIXTURE_BASE/$name"
    mkdir -p "$dir"
    printf '%s' "$dir"
}

mkgitrepo() {
    local dir
    dir=$(mkfixture "$1")
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
    printf '%s' "$dir"
}

# ── detect_clean_working_tree ──────────────────────────────────────────
echo "== detect_clean_working_tree =="
fx=$(mkfixture clean-not-git)
assert_eq "non-git dir → dirty (early-return guard)" \
    "working-tree: dirty" "$(detect_clean_working_tree "$fx")"

fx=$(mkgitrepo clean-empty-git)
assert_eq "empty git repo (no untracked) → clean" \
    "working-tree: clean" "$(detect_clean_working_tree "$fx")"

fx=$(mkgitrepo clean-with-untracked)
touch "$fx/untracked-file.txt"
assert_eq "git repo with untracked file → dirty" \
    "working-tree: dirty" "$(detect_clean_working_tree "$fx")"

# ── detect_git_repo ────────────────────────────────────────────────────
echo "== detect_git_repo =="
fx=$(mkfixture git-no)
assert_eq "non-git dir → no" \
    "git-repo: no" "$(detect_git_repo "$fx")"

fx=$(mkgitrepo git-yes)
assert_eq "git-init'd dir → yes" \
    "git-repo: yes" "$(detect_git_repo "$fx")"

# ── detect_pack_path ───────────────────────────────────────────────────
echo "== detect_pack_path =="
assert_eq "missing path → missing" \
    "pack-path: missing" "$(detect_pack_path "$FIXTURE_BASE/does-not-exist")"

fx=$(mkfixture pack-not-a-repo)
assert_eq "exists but not a git repo → not-a-repo" \
    "pack-path: not-a-repo" "$(detect_pack_path "$fx")"

fx=$(mkgitrepo pack-no-project-template)
assert_eq "git repo without project-template/ → not-a-repo" \
    "pack-path: not-a-repo" "$(detect_pack_path "$fx")"

fx=$(mkgitrepo pack-valid)
mkdir -p "$fx/project-template"
assert_eq "git repo with project-template/ → valid" \
    "pack-path: valid" "$(detect_pack_path "$fx")"

# Smoke: real pack should be valid (we're inside one)
assert_eq "real pack root → valid" \
    "pack-path: valid" "$(detect_pack_path "$PACK_ROOT")"

# ── detect_pack_version ────────────────────────────────────────────────
echo "== detect_pack_version =="
fx=$(mkgitrepo pack-version-tag)
git -C "$fx" commit --allow-empty -q -m "init"
git -C "$fx" tag v9.9
assert_eq "HEAD at exact tag v9.9 → v9.9" \
    "pack-version: v9.9" "$(detect_pack_version "$fx")"

fx=$(mkgitrepo pack-version-branch)
git -C "$fx" checkout -q -b feature-branch
git -C "$fx" commit --allow-empty -q -m "init"
assert_eq "branch HEAD with no tag → branch name" \
    "pack-version: feature-branch" "$(detect_pack_version "$fx")"

fx=$(mkgitrepo pack-version-detached)
git -C "$fx" commit --allow-empty -q -m "first"
sha=$(git -C "$fx" rev-parse HEAD)
git -C "$fx" commit --allow-empty -q -m "second"
git -C "$fx" checkout -q "$sha"
assert_eq "detached HEAD with no tag → unknown" \
    "pack-version: unknown" "$(detect_pack_version "$fx")"

# ── detect_ai_config ───────────────────────────────────────────────────
echo "== detect_ai_config =="
fx=$(mkfixture ai-empty)
assert_eq "no markers → (none)" \
    "ai-config-markers: (none)" "$(detect_ai_config "$fx")"

fx=$(mkfixture ai-claude-only)
mkdir -p "$fx/.claude"
touch "$fx/CLAUDE.md"
assert_eq ".claude/ + CLAUDE.md → both listed" \
    "ai-config-markers: .claude/,CLAUDE.md" "$(detect_ai_config "$fx")"

fx=$(mkfixture ai-all-six)
mkdir -p "$fx/.claude" "$fx/.codex" "$fx/.gemini"
touch "$fx/CLAUDE.md" "$fx/AGENTS.md" "$fx/GEMINI.md"
assert_eq "all six markers → comma-joined in scan order" \
    "ai-config-markers: .claude/,.codex/,.gemini/,CLAUDE.md,AGENTS.md,GEMINI.md" \
    "$(detect_ai_config "$fx")"

# ── detect_x_files ─────────────────────────────────────────────────────
echo "== detect_x_files =="
fx=$(mkfixture x-empty)
assert_eq "no scan dirs → (none)" \
    "x-files: (none)" "$(detect_x_files "$fx")"

fx=$(mkfixture x-empty-with-dirs)
mkdir -p "$fx/.claude/agents" "$fx/docs/pack/prompts"
touch "$fx/.claude/agents/coder.md" "$fx/docs/pack/prompts/coder.md"
assert_eq "scan dirs present but no x- entries → (none)" \
    "x-files: (none)" "$(detect_x_files "$fx")"

fx=$(mkfixture x-one-agent)
mkdir -p "$fx/.claude/agents"
touch "$fx/.claude/agents/x-custom.md"
assert_eq "one x- agent → one match" \
    "x-files: .claude/agents/x-custom.md" "$(detect_x_files "$fx")"

fx=$(mkfixture x-multiple-locations)
mkdir -p "$fx/.claude/agents" "$fx/.codex/agents" "$fx/docs/pack/prompts"
touch "$fx/.claude/agents/x-alpha.md"
touch "$fx/.codex/agents/x-beta.toml"
touch "$fx/docs/pack/prompts/x-gamma.md"
expected="x-files: .claude/agents/x-alpha.md
x-files: .codex/agents/x-beta.toml
x-files: docs/pack/prompts/x-gamma.md"
assert_eq "x- entries in three scan locations → three matches in scan order" \
    "$expected" "$(detect_x_files "$fx")"

# ── detect_improperly_added_files ──────────────────────────────────────
echo "== detect_improperly_added_files =="
# Requires PACK pointing at a real pack repo with project-template/ rosters.
export PACK="$PACK_ROOT"

fx=$(mkfixture improperly-empty)
assert_eq "empty target (no scan dirs) → (none)" \
    "improperly-added: (none)" "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-only-roster)
mkdir -p "$fx/.claude/agents" "$fx/.claude/skills/swift-best-practices"
touch "$fx/.claude/agents/coder.md"   # in roster
touch "$fx/.claude/skills/swift-best-practices/SKILL.md"  # name in roster
assert_eq "target with only roster files → (none)" \
    "improperly-added: (none)" "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-x-prefix-skipped)
mkdir -p "$fx/.claude/agents"
touch "$fx/.claude/agents/x-anything.md"
touch "$fx/.claude/agents/coder.md"
assert_eq "x- prefixed entries are skipped (legitimate per Procedure 5)" \
    "improperly-added: (none)" "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-non-roster-agent)
mkdir -p "$fx/.claude/agents"
touch "$fx/.claude/agents/randomname.md"
assert_eq "non-roster agent (no x- prefix) → flagged" \
    "improperly-added: .claude/agents/randomname.md" \
    "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-non-roster-skill)
mkdir -p "$fx/.claude/skills/not-a-real-skill"
touch "$fx/.claude/skills/not-a-real-skill/SKILL.md"
assert_eq "non-roster skill dir → flagged" \
    "improperly-added: .claude/skills/not-a-real-skill" \
    "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-prompts-allowed)
mkdir -p "$fx/docs/pack/prompts"
touch "$fx/docs/pack/prompts/coder.md"          # in roster
touch "$fx/docs/pack/prompts/pm-chat.md"        # reserved
touch "$fx/docs/pack/prompts/x-custom.md"       # x- prefix
assert_eq "prompts dir with all-allowed entries → (none)" \
    "improperly-added: (none)" "$(detect_improperly_added_files "$fx")"

fx=$(mkfixture improperly-prompts-stranger)
mkdir -p "$fx/docs/pack/prompts"
touch "$fx/docs/pack/prompts/some-other.md"
assert_eq "prompts dir with non-roster non-x file → flagged" \
    "improperly-added: docs/pack/prompts/some-other.md" \
    "$(detect_improperly_added_files "$fx")"

# Negative-path test for missing PACK
unset PACK
fx=$(mkfixture improperly-no-pack)
expected="improperly-added: (error — PACK not set or pack invalid)"
assert_eq "PACK unset → error sentinel; non-zero exit" \
    "$expected" "$(detect_improperly_added_files "$fx" 2>/dev/null)"
export PACK="$PACK_ROOT"  # restore for any later tests

# ── detect_installed_capabilities ──────────────────────────────────────
echo "== detect_installed_capabilities =="
fx=$(mkfixture caps-no-claude)
assert_eq "no CLAUDE.md → (no CLAUDE.md)" \
    "capabilities: (no CLAUDE.md)" "$(detect_installed_capabilities "$fx")"

fx=$(mkfixture caps-no-skills-line)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
Some content but no Active skills line.
EOF
assert_eq "CLAUDE.md without Active-skills line → (no Active skills line)" \
    "capabilities: (no Active skills line)" "$(detect_installed_capabilities "$fx")"

fx=$(mkfixture caps-placeholder)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** [PM chat will populate this line during kickoff]
EOF
assert_eq "Active-skills line still a placeholder → (placeholder)" \
    "capabilities: (placeholder)" "$(detect_installed_capabilities "$fx")"

fx=$(mkfixture caps-mapped-skills)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** swift-best-practices, ios-architecture, grpc-patterns
EOF
assert_eq "Active-skills with three mappable skills → three caps, sorted" \
    "capabilities: language:swift, platform:ios, protocol:grpc" \
    "$(detect_installed_capabilities "$fx")"

fx=$(mkfixture caps-only-unmapped)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** architecture-review, audit-methodology, planning
EOF
assert_eq "Active-skills with only architectural / agnostic skills → (none)" \
    "capabilities: (none)" "$(detect_installed_capabilities "$fx")"

fx=$(mkfixture caps-with-backticks)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** `python-best-practices`, `deployment-python`
EOF
assert_eq "Active-skills with backticks → stripped + mapped correctly" \
    "capabilities: language:python, role:python-server" \
    "$(detect_installed_capabilities "$fx")"

# ── detect_target_pack_version (BD-119) ───────────────────────────────
echo "== detect_target_pack_version =="

fx=$(mkfixture tgtver-empty)
assert_eq "empty dir → unknown" \
    "unknown" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-tracker-toml-v11)
cat > "$fx/tracker.toml" <<'EOF'
[pack]
version = "v11"

[mode]
state = "tracker"
EOF
assert_eq "tracker.toml [pack].version=v11 → v11 (signal 1)" \
    "v11" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-tracker-toml-no-pack-version)
cat > "$fx/tracker.toml" <<'EOF'
[mode]
state = "flat-file"
EOF
mkdir -p "$fx/.claude"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
Body content here.
EOF
# v10 with tracker.toml but without [pack].version: cascade falls through to v10.
assert_eq "tracker.toml without [pack].version + v10 shape → v10" \
    "v10" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-trinity-fingerprint)
mkdir -p "$fx/.claude"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
- run `pack help` for the full verb list, or `/pack-help` in your CLI.
EOF
assert_eq "trinity addenda fingerprint → v11 (signal 2)" \
    "v11" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-surface-marker)
mkdir -p "$fx/.claude/skills/pack-help" "$fx/.claude"
echo "# SKILL.md" > "$fx/.claude/skills/pack-help/SKILL.md"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
no fingerprint here.
EOF
assert_eq "v11 surface marker (.claude/skills/pack-help) → v11 (signal 3)" \
    "v11" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-v10-shape)
mkdir -p "$fx/.claude" "$fx/docs/pack"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
v10 shape, no v11 fingerprint.
EOF
echo "# PROMPT-TEMPLATES.md" > "$fx/docs/pack/PROMPT-TEMPLATES.md"
assert_eq "v10 shape (PROMPT-TEMPLATES + no v11 markers) → v10 (signal 4)" \
    "v10" "$(detect_target_pack_version "$fx")"

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
