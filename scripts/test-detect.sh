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

# ── detect_pack_surface ────────────────────────────────────────────────
# BD-206 O5: the dual-use surface probe. The pack signal is a `/backlog/`
# per-entry tree (BD-NNN.md); the client signal is a
# `docs/project/backlog/` per-entry tree (TD-NNN.md), repointed off the
# pre-v11 monolith. Both per-entry probes live OUTSIDE the
# DENY-LIST-CONTENT markers; the legacy monolith probe stays inside as a
# pre-v11 fallback. (The end-to-end surface-routing suite lives in
# scripts/tests/pack-help-test.sh Group 1; this section unit-covers the
# new client-tree probe per the O5b deliverable.)
echo "== detect_pack_surface =="

fx=$(mkfixture surface-pack-tree)
mkdir -p "$fx/backlog"
printf '**BD-001 — A**\nStatus: Open\n' > "$fx/backlog/BD-001.md"
assert_eq "pack /backlog/ per-entry tree (BD-NNN.md) → pack" \
    "pack-surface: pack" "$(detect_pack_surface "$fx")"

fx=$(mkfixture surface-client-tree)
mkdir -p "$fx/docs/project/backlog"
printf '**TD-001 — A**\nStatus: Open\n' > "$fx/docs/project/backlog/TD-001.md"
printf '**TD-042 — B**\nStatus: Resolved\n' > "$fx/docs/project/backlog/TD-042.md"
assert_eq "client docs/project/backlog/ per-entry tree (TD-NNN.md) → client" \
    "pack-surface: client" "$(detect_pack_surface "$fx")"

# Legacy pre-v11 monolith fallback still resolves (mid-migration client).
fx=$(mkfixture surface-client-monolith-fallback)
mkdir -p "$fx/docs/project"
printf '**TD-001 — A**\nStatus: Open\n' > "$fx/docs/project/BACKLOG.md"
assert_eq "client docs/project/BACKLOG.md monolith (pre-v11 fallback) → client" \
    "pack-surface: client" "$(detect_pack_surface "$fx")"

# Client per-entry tree present but a non-matching basename (TD-abc.md)
# must NOT fire the probe (anchored `^TD-[0-9]+\.md$` regex).
fx=$(mkfixture surface-client-tree-nonmatch)
mkdir -p "$fx/docs/project/backlog"
printf '**TD-abc — A**\nStatus: Open\n' > "$fx/docs/project/backlog/TD-abc.md"
assert_eq "client backlog/ dir with non-TD-NNN file only → ambiguous (no signal)" \
    "pack-surface: ambiguous" "$(detect_pack_surface "$fx")"

# Both per-entry trees present → ambiguous (caller decides).
fx=$(mkfixture surface-both-trees)
mkdir -p "$fx/backlog" "$fx/docs/project/backlog"
printf '**BD-001 — A**\nStatus: Open\n' > "$fx/backlog/BD-001.md"
printf '**TD-001 — B**\nStatus: Open\n' > "$fx/docs/project/backlog/TD-001.md"
assert_eq "both per-entry trees (pack + client) → ambiguous" \
    "pack-surface: ambiguous" "$(detect_pack_surface "$fx")"

# Neither signal → ambiguous.
fx=$(mkfixture surface-neither)
assert_eq "no backlog tree / no monolith → ambiguous" \
    "pack-surface: ambiguous" "$(detect_pack_surface "$fx")"

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
mkdir -p "$fx/.claude" "$fx/.codex" "$fx/.agents"
touch "$fx/CLAUDE.md" "$fx/AGENTS.md" "$fx/GEMINI.md"
assert_eq "all six markers → comma-joined in scan order" \
    "ai-config-markers: .claude/,.codex/,.agents/,CLAUDE.md,AGENTS.md,GEMINI.md" \
    "$(detect_ai_config "$fx")"

# Legacy-READ carve-out (ii): a departing v10 `.gemini/` dir is still
# detected so the migrator can find + relocate it.
fx=$(mkfixture ai-legacy-gemini)
mkdir -p "$fx/.claude" "$fx/.gemini"
touch "$fx/CLAUDE.md" "$fx/GEMINI.md"
assert_eq "legacy .gemini/ still detected (carve-out ii)" \
    "ai-config-markers: .claude/,.gemini/,CLAUDE.md,GEMINI.md" \
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

# ── detect_antigravity_skills_layout (BD-221 existing-install / OQ-E) ──
echo "== detect_antigravity_skills_layout =="

fx=$(mkfixture agl-none)
assert_eq "no Antigravity skills layout → none" \
    "antigravity-skills-layout: none" "$(detect_antigravity_skills_layout "$fx")"

fx=$(mkfixture agl-loose)
mkdir -p "$fx/.agents/skills"
assert_eq "loose .agents/skills/ present → loose" \
    "antigravity-skills-layout: loose" "$(detect_antigravity_skills_layout "$fx")"

fx=$(mkfixture agl-bundled-own)
mkdir -p "$fx/.agents-plugin/optiquity-agents/skills"
assert_eq "pack's own optiquity-agents bundle skills → bundled" \
    "antigravity-skills-layout: bundled" "$(detect_antigravity_skills_layout "$fx")"

fx=$(mkfixture agl-bundled-foreign)
mkdir -p "$fx/.agents-plugin/some-other-plugin/skills"
assert_eq "foreign plugin bundled skills NOT respected → none" \
    "antigravity-skills-layout: none" "$(detect_antigravity_skills_layout "$fx")"

fx=$(mkfixture agl-both)
mkdir -p "$fx/.agents/skills" "$fx/.agents-plugin/optiquity-agents/skills"
assert_eq "BOTH loose + bundled → loose (deterministic tie-break)" \
    "antigravity-skills-layout: loose" "$(detect_antigravity_skills_layout "$fx")"

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
# BD-144 (v11.0 skill-dimensions reframe Batch 5): deployment-python now
# reciprocally maps to `deployment:linux-container` (D5), not the misclassified
# `role:python-server` (D3) of v10.x.
assert_eq "Active-skills with backticks → stripped + mapped correctly" \
    "capabilities: deployment:linux-container, language:python" \
    "$(detect_installed_capabilities "$fx")"

# BD-144: rename `role:apple-app` → `deployment:apple`. Verify the
# reciprocal mapping in detect_installed_capabilities() emits the new D5
# token, not the deprecated D3 token.
fx=$(mkfixture caps-deployment-apple)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** swift-best-practices, deployment-apple
EOF
assert_eq "deployment-apple → deployment:apple (D5, BD-144 rename)" \
    "capabilities: deployment:apple, language:swift" \
    "$(detect_installed_capabilities "$fx")"

# BD-144: deployment-python → deployment:linux-container without backticks
# (covers the path where add-capability.sh wrote the skill straight without
# Markdown formatting).
fx=$(mkfixture caps-deployment-linux-container)
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
**Active skills:** python-best-practices, deployment-python
EOF
assert_eq "deployment-python → deployment:linux-container (D5, BD-144 rename)" \
    "capabilities: deployment:linux-container, language:python" \
    "$(detect_installed_capabilities "$fx")"

# ── protobuf_marker_detected (BD-156) ─────────────────────────────────
echo "== protobuf_marker_detected =="

fx=$(mkfixture proto-marker-empty)
assert_eq "empty dir → no" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$fx")"

fx=$(mkfixture proto-marker-missing-target)
rm -rf "$fx"
assert_eq "non-existent target → no (tolerated, no stderr)" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$FIXTURE_BASE/never-existed")"

# Marker (a): a `.proto` file anywhere in the tree.
fx=$(mkfixture proto-marker-proto-file)
mkdir -p "$fx/proto/myorg/v1"
cat > "$fx/proto/myorg/v1/billing.proto" <<'EOF'
syntax = "proto3";
package myorg.v1;
message Invoice { string id = 1; }
EOF
assert_eq ".proto file present → yes (marker a)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Marker (a) excludes vendored trees — a .proto only inside
# node_modules/ should NOT trigger detection.
fx=$(mkfixture proto-marker-vendored-only)
mkdir -p "$fx/node_modules/some-pkg/proto"
echo 'syntax = "proto3";' > "$fx/node_modules/some-pkg/proto/x.proto"
assert_eq ".proto only in node_modules → no (vendored prune)" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$fx")"

# Marker (b): Python manifest lists `protobuf`.
fx=$(mkfixture proto-marker-pyproject)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = [
  "protobuf>=4.25",
  "grpcio>=1.60",
]
EOF
assert_eq "pyproject.toml lists protobuf → yes (marker b — Python)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Marker (b): requirements.txt lists `grpcio-tools`.
fx=$(mkfixture proto-marker-requirements-grpcio-tools)
cat > "$fx/requirements.txt" <<'EOF'
grpcio-tools==1.60.0
pytest
EOF
assert_eq "requirements.txt lists grpcio-tools → yes (marker b)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Marker (b): Swift Package.swift references SwiftProtobuf.
fx=$(mkfixture proto-marker-package-swift)
cat > "$fx/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf", from: "1.25.0"),
    ]
)
EOF
assert_eq "Package.swift references swift-protobuf → yes (marker b — Swift)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Marker (b): substring rejection — `protobuf-c-bindings` should NOT
# match `protobuf` (negated character class boundary).
fx=$(mkfixture proto-marker-substring-reject)
cat > "$fx/requirements.txt" <<'EOF'
protobuf-c-bindings==0.1
some-other-pkg==1.0
EOF
assert_eq "substring 'protobuf-c-bindings' alone → no (boundary reject)" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$fx")"

# Marker (b): generic — buf.yaml present.
fx=$(mkfixture proto-marker-buf-yaml)
cat > "$fx/buf.yaml" <<'EOF'
version: v2
modules:
  - path: proto
EOF
assert_eq "buf.yaml present → yes (generic buf-tooling marker)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Negative: dir with unrelated Python deps.
fx=$(mkfixture proto-marker-no-protobuf)
cat > "$fx/requirements.txt" <<'EOF'
requests==2.31
pytest==7.4
EOF
assert_eq "manifests without protobuf tooling → no" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$fx")"

# ── swiftdata_marker_detected (BD-157) ────────────────────────────────
echo "== swiftdata_marker_detected =="

fx=$(mkfixture sd-marker-empty)
assert_eq "empty dir → no" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

assert_eq "non-existent target → no (tolerated, no stderr)" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$FIXTURE_BASE/sd-never-existed")"

# Marker (a): a `.swift` file with `import SwiftData`.
fx=$(mkfixture sd-marker-import)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/Item.swift" <<'EOF'
import Foundation
import SwiftData

final class Item {
    var name: String = ""
}
EOF
assert_eq "import SwiftData present → yes (marker a)" \
    "swiftdata-marker: yes" "$(swiftdata_marker_detected "$fx")"

# Marker (b): a `.swift` file with `@Model` attribute.
fx=$(mkfixture sd-marker-at-model)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/User.swift" <<'EOF'
import Foundation
// SwiftData re-exported via a project umbrella; no direct import line.

@Model
final class User {
    var email: String = ""
}
EOF
assert_eq "@Model attribute present → yes (marker b)" \
    "swiftdata-marker: yes" "$(swiftdata_marker_detected "$fx")"

# Marker (b) with parameter form: `@Model(...)`.
fx=$(mkfixture sd-marker-at-model-paren)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/Order.swift" <<'EOF'
@Model(versionedSchema: V1.self)
final class Order {}
EOF
assert_eq "@Model(...) parameter form → yes (marker b boundary)" \
    "swiftdata-marker: yes" "$(swiftdata_marker_detected "$fx")"

# Marker (b) boundary reject: `@ModelAttribute` and `@Modeled` should NOT match.
fx=$(mkfixture sd-marker-lookalike-reject)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/Other.swift" <<'EOF'
import Foundation

@ModelAttribute
struct Other {}

@Modeled var x = 0
EOF
assert_eq "@ModelAttribute / @Modeled lookalikes alone → no (boundary reject)" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# Marker (a) excludes vendored / build trees.
fx=$(mkfixture sd-marker-vendored-only)
mkdir -p "$fx/.build/checkouts/foo/Sources"
cat > "$fx/.build/checkouts/foo/Sources/X.swift" <<'EOF'
import SwiftData
EOF
assert_eq "import SwiftData only inside .build/ → no (vendored prune)" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# Marker (c): Package.swift lists SwiftData explicitly.
fx=$(mkfixture sd-marker-package-swift)
cat > "$fx/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    dependencies: [
        .package(url: "https://example.com/SwiftDataKit", from: "1.0.0"),
    ]
)
EOF
# 'SwiftDataKit' does NOT match `SwiftData` (negated boundary class
# rejects substring extension by trailing alphanumeric — `K` after
# `SwiftData` is in the [A-Za-z0-9_.-] negation set).
assert_eq "Package.swift lists 'SwiftDataKit' only → no (substring reject)" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# Marker (c) positive: Package.swift lists SwiftData with a trailing word boundary.
fx=$(mkfixture sd-marker-package-swift-positive)
cat > "$fx/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    dependencies: [
        .package(url: "https://example.com/SwiftData-shim.git", from: "1.0.0"),
    ]
)
EOF
assert_eq "Package.swift lists 'SwiftData-shim' → no (boundary: trailing -shim is in name-chars)" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# A truly word-bounded SwiftData mention does match.
fx=$(mkfixture sd-marker-package-swift-bare)
cat > "$fx/Package.swift" <<'EOF'
// Comment: depends on SwiftData (bare reference for cross-compile shim).
import PackageDescription
let package = Package(name: "App")
EOF
assert_eq "Package.swift bare 'SwiftData' word → yes (marker c)" \
    "swiftdata-marker: yes" "$(swiftdata_marker_detected "$fx")"

# Negative: Apple project, .swift files but no SwiftData.
fx=$(mkfixture sd-marker-apple-no-swiftdata)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/View.swift" <<'EOF'
import SwiftUI

struct ContentView: View {
    var body: some View { Text("hi") }
}
EOF
assert_eq "Apple project without SwiftData → no" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# Negative: non-Apple project (no .swift files at all).
fx=$(mkfixture sd-marker-non-apple)
mkdir -p "$fx/src"
cat > "$fx/src/main.py" <<'EOF'
import SwiftData  # not a real Python module — just prose
EOF
assert_eq "non-Apple project (no .swift files) → no" \
    "swiftdata-marker: no" "$(swiftdata_marker_detected "$fx")"

# ── python_data_marker_detected (BD-141 + BD-035 audit fixes) ─────────
echo "== python_data_marker_detected =="

fx=$(mkfixture pyd-marker-empty)
assert_eq "empty dir → no" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

assert_eq "non-existent target → no (tolerated, no stderr)" \
    "python-data: no" "$(python_data_marker_detected "$FIXTURE_BASE/pyd-never-existed")"

# Marker (a): pyproject.toml lists sqlalchemy.
fx=$(mkfixture pyd-marker-sqlalchemy)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = ["sqlalchemy>=2.0", "alembic"]
EOF
assert_eq "pyproject.toml lists sqlalchemy → yes (marker a)" \
    "python-data: yes" "$(python_data_marker_detected "$fx")"

# Marker (b): >= 5 .py files outside tests/.
fx=$(mkfixture pyd-marker-five-files)
mkdir -p "$fx/src"
for n in 1 2 3 4 5; do touch "$fx/src/mod${n}.py"; done
assert_eq "5 non-test .py files → yes (marker b)" \
    "python-data: yes" "$(python_data_marker_detected "$fx")"

# Negative: 4 non-test .py files, no listed deps.
fx=$(mkfixture pyd-marker-four-files-stdlib-noop)
mkdir -p "$fx/src"
for n in 1 2 3 4; do echo "x = 1" > "$fx/src/mod${n}.py"; done
assert_eq "4 non-test .py files with no data imports → no" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

# F1: marker (c) — stdlib `import sqlite3` only (small CLI shape).
fx=$(mkfixture pyd-marker-stdlib-sqlite3)
mkdir -p "$fx/src"
cat > "$fx/src/store.py" <<'EOF'
import sqlite3

def init_db(path):
    return sqlite3.connect(path)
EOF
echo "x = 1" > "$fx/src/cli.py"
assert_eq "stdlib import sqlite3 only, 2 files → yes (F1: marker c)" \
    "python-data: yes" "$(python_data_marker_detected "$fx")"

# F1: marker (c) — stdlib `import csv` only (small ETL shape).
fx=$(mkfixture pyd-marker-stdlib-csv)
mkdir -p "$fx/src"
cat > "$fx/src/etl.py" <<'EOF'
import csv

def load(path):
    with open(path) as f:
        return list(csv.reader(f))
EOF
assert_eq "stdlib import csv only, 1 file → yes (F1: marker c)" \
    "python-data: yes" "$(python_data_marker_detected "$fx")"

# F1: marker (c) — both `import sqlite3` and `import csv`.
fx=$(mkfixture pyd-marker-stdlib-both)
mkdir -p "$fx/src"
cat > "$fx/src/a.py" <<'EOF'
import sqlite3
EOF
cat > "$fx/src/b.py" <<'EOF'
from csv import reader
EOF
assert_eq 'stdlib sqlite3 + csv (from-import form) → yes (F1: marker c)' \
    "python-data: yes" "$(python_data_marker_detected "$fx")"

# F1 boundary: prose mention in comment must NOT trigger marker (c).
fx=$(mkfixture pyd-marker-comment-prose)
mkdir -p "$fx/src"
cat > "$fx/src/notes.py" <<'EOF'
# We do not import sqlite3 here — see ARCHITECTURE.md.
# from csv import reader (refactored away)
x = 1
EOF
assert_eq "prose 'import sqlite3' in comment only → no (line-anchor reject)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

# F1 boundary: stdlib imports in test files must NOT trigger.
fx=$(mkfixture pyd-marker-stdlib-tests-only)
mkdir -p "$fx/tests"
cat > "$fx/tests/test_db.py" <<'EOF'
import sqlite3
def test_x(): pass
EOF
assert_eq "import sqlite3 only inside tests/ → no (test exclude)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

# F5: protobuf-only project must NOT trigger python-data.
# Previously `protobuf` and `grpc-tools` lived in the python-data
# marker package list and over-triggered. Post-F5 they belong
# exclusively to `protobuf_marker_detected()`.
fx=$(mkfixture pyd-marker-protobuf-only)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = ["protobuf>=4.25"]
EOF
assert_eq "pyproject.toml lists protobuf only → no (F5: not data)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

# F5: grpc-tools-only also should NOT trigger.
fx=$(mkfixture pyd-marker-grpc-tools-only)
cat > "$fx/requirements.txt" <<'EOF'
grpc-tools==1.60.0
EOF
assert_eq "requirements.txt lists grpc-tools only → no (F5: not data)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

# F5 cross-check: the same protobuf-only fixture SHOULD trigger
# protobuf_marker_detected — confirms ownership moved cleanly.
fx=$(mkfixture pyd-marker-f5-cross-check)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = ["protobuf>=4.25"]
EOF
assert_eq "F5 cross-check: protobuf-only fires protobuf-marker (not python-data)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# Boundary regression: substring rejection still works for data pkgs.
fx=$(mkfixture pyd-marker-substring-reject)
cat > "$fx/requirements.txt" <<'EOF'
numpyro==0.12
aioredis==2.0
EOF
assert_eq "substring 'numpyro'/'aioredis' alone → no (boundary reject)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"

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
- **Pack commands:** run `/pm-help` for the full verb list, or `bash scripts/pm-help.sh`.
EOF
assert_eq "trinity addenda fingerprint → v11 (signal 2)" \
    "v11" "$(detect_target_pack_version "$fx")"

fx=$(mkfixture tgtver-surface-marker)
mkdir -p "$fx/.claude/skills/pm-help" "$fx/.claude"
echo "# SKILL.md" > "$fx/.claude/skills/pm-help/SKILL.md"
cat > "$fx/CLAUDE.md" <<'EOF'
# CLAUDE.md
no fingerprint here.
EOF
assert_eq "v11 surface marker (.claude/skills/pm-help) → v11 (signal 3)" \
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

# ── python_observability_marker_detected (BD-162) ─────────────────────
echo "== python_observability_marker_detected =="

# T11: empty dir baseline.
fx=$(mkfixture pyobs-marker-empty)
assert_eq "empty dir → no" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# T12: non-existent target tolerated.
assert_eq "non-existent target → no (tolerated, no stderr)" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$FIXTURE_BASE/pyobs-never-existed")"

# T1: requirements.txt lists opentelemetry-api (manifest marker — primary OTel package).
fx=$(mkfixture pyobs-marker-otel-api-req)
cat > "$fx/requirements.txt" <<'EOF'
opentelemetry-api>=1.20
pytest
EOF
assert_eq "requirements.txt lists opentelemetry-api → yes (marker a — exact)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T2: pyproject.toml lists opentelemetry-instrumentation-grpc (prefix-match contrib package).
fx=$(mkfixture pyobs-marker-otel-instr-grpc)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = [
  "opentelemetry-instrumentation-grpc>=0.45b0",
]
EOF
assert_eq "pyproject.toml lists opentelemetry-instrumentation-grpc → yes (marker a — prefix)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T3: pyproject.toml lists prometheus_client.
fx=$(mkfixture pyobs-marker-prom-client)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = [
  "prometheus_client>=0.20",
]
EOF
assert_eq "pyproject.toml lists prometheus_client → yes (marker a — exact)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T4: requirements.txt lists structlog.
fx=$(mkfixture pyobs-marker-structlog-req)
cat > "$fx/requirements.txt" <<'EOF'
structlog==24.0
EOF
assert_eq "requirements.txt lists structlog → yes (marker a — exact)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T5: pyproject.toml lists python-json-logger.
fx=$(mkfixture pyobs-marker-json-logger)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = ["python-json-logger>=2.0"]
EOF
assert_eq "pyproject.toml lists python-json-logger → yes (marker a — exact)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T10: pyproject.toml lists opentelemetry-exporter-otlp-proto-grpc (prefix-match exporter).
fx=$(mkfixture pyobs-marker-otel-exporter)
cat > "$fx/pyproject.toml" <<'EOF'
[project]
dependencies = [
  "opentelemetry-exporter-otlp-proto-grpc>=1.20",
]
EOF
assert_eq "pyproject.toml lists opentelemetry-exporter-otlp-proto-grpc → yes (marker a — prefix)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T6: a .py file outside tests/ contains `import opentelemetry`.
fx=$(mkfixture pyobs-marker-import-otel)
mkdir -p "$fx/src"
cat > "$fx/src/app.py" <<'EOF'
import opentelemetry

def main():
    pass
EOF
assert_eq "import opentelemetry in .py file → yes (marker b — primary)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T7: a .py file with `from opentelemetry.trace import get_tracer` (dotted path).
fx=$(mkfixture pyobs-marker-from-otel-dotted)
mkdir -p "$fx/src"
cat > "$fx/src/tracing.py" <<'EOF'
from opentelemetry.trace import get_tracer

tracer = get_tracer(__name__)
EOF
assert_eq "from opentelemetry.trace import ... → yes (marker b — dotted path)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T8: a .py file with `import prometheus_client`.
fx=$(mkfixture pyobs-marker-import-prom)
mkdir -p "$fx/src"
cat > "$fx/src/metrics.py" <<'EOF'
import prometheus_client

counter = prometheus_client.Counter("requests_total", "Total requests")
EOF
assert_eq "import prometheus_client in .py file → yes (marker b)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T9: a .py file with `from structlog import get_logger`.
fx=$(mkfixture pyobs-marker-from-structlog)
mkdir -p "$fx/src"
cat > "$fx/src/logger.py" <<'EOF'
from structlog import get_logger

log = get_logger()
EOF
assert_eq "from structlog import get_logger → yes (marker b)" \
    "python-observability-marker: yes" "$(python_observability_marker_detected "$fx")"

# T13: pure Apple project — Swift sources, Package.swift, no Python observability deps.
fx=$(mkfixture pyobs-marker-apple-only)
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/App.swift" <<'EOF'
import SwiftUI

@main
struct App: SwiftUI.App {
    var body: some Scene { WindowGroup { Text("hi") } }
}
EOF
cat > "$fx/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "App")
EOF
assert_eq "pure Apple project (no Python observability) → no" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# T14: Python script with `requests` + `pytest` only — no observability deps,
# no observability imports.
fx=$(mkfixture pyobs-marker-py-no-obs)
mkdir -p "$fx/src"
cat > "$fx/requirements.txt" <<'EOF'
requests==2.31
pytest==7.4
EOF
cat > "$fx/src/main.py" <<'EOF'
import requests

def fetch(url):
    return requests.get(url).text
EOF
assert_eq "Python script with requests + pytest only → no" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# T15: substring rejection — `not-opentelemetry-clone` must NOT match
# `opentelemetry-api` (BD-141 negated-character-class boundary).
fx=$(mkfixture pyobs-marker-substring-reject)
cat > "$fx/requirements.txt" <<'EOF'
not-opentelemetry-clone==0.1
some-other-pkg==1.0
EOF
assert_eq "substring 'not-opentelemetry-clone' alone → no (boundary reject)" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# T16: prose mention in a comment must NOT trigger marker (b)
# (line-anchored grep rejects comments per BD-141 marker-c convention).
fx=$(mkfixture pyobs-marker-comment-prose)
mkdir -p "$fx/src"
cat > "$fx/src/notes.py" <<'EOF'
# we should add import opentelemetry someday
# from prometheus_client import Counter (refactored away)
x = 1
EOF
assert_eq "prose 'import opentelemetry' in comment only → no (line-anchor reject)" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# T17: vendored prune — a .py file under node_modules/some-pkg/ with
# `import opentelemetry` must NOT trigger detection.
fx=$(mkfixture pyobs-marker-vendored-only)
mkdir -p "$fx/node_modules/some-pkg"
cat > "$fx/node_modules/some-pkg/foo.py" <<'EOF'
import opentelemetry
EOF
assert_eq "import opentelemetry only in node_modules → no (vendored prune)" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"

# ── pack-capability-pool/ exclusion (BD-200) ──────────────────────────
# The BD-200 tracked pool ships marker-looking masters
# (proto/*.proto, pyproject.toml, server/**/*.py, *.swift) on EVERY
# installed project regardless of the project's actual languages.
# The four tree-scanning marker detectors MUST exclude the pool, else
# a Swift-only client mis-fires protobuf/python markers off its own
# pool. Fixture: a Swift-only tree whose ONLY proto/python content
# lives inside pack-capability-pool/.
fx=$(mkfixture pool-exclusion-swift-only)
# Live-tree Swift source (the genuine project language).
mkdir -p "$fx/Sources/App"
cat > "$fx/Sources/App/main.swift" <<'EOF'
import Foundation
print("hello")
EOF
# pack-capability-pool/ masters that WOULD mis-fire without the prune:
#   proto/*.proto + buf.yaml → protobuf marker (a)/(generic)
#   pyproject.toml (grpcio-testing) → protobuf marker (b)
#   server/**/*.py (>=5, plus an observability import) → python markers
mkdir -p "$fx/pack-capability-pool/proto/myorg/v1"
cat > "$fx/pack-capability-pool/proto/myorg/v1/svc.proto" <<'EOF'
syntax = "proto3";
package myorg.v1;
message Ping { string id = 1; }
EOF
cat > "$fx/pack-capability-pool/buf.yaml" <<'EOF'
version: v2
EOF
cat > "$fx/pack-capability-pool/pyproject.toml" <<'EOF'
[project]
dependencies = [
  "sqlalchemy>=2.0",
  "opentelemetry-api>=1.0",
]
EOF
mkdir -p "$fx/pack-capability-pool/server/app"
for n in 1 2 3 4 5 6; do
  printf 'import os\n' > "$fx/pack-capability-pool/server/app/mod${n}.py"
done
cat > "$fx/pack-capability-pool/server/app/obs.py" <<'EOF'
import opentelemetry
EOF

assert_eq "pool .proto/buf masters → protobuf marker NOT fired (pool prune)" \
    "protobuf-marker: no" "$(protobuf_marker_detected "$fx")"
assert_eq "pool pyproject + server/*.py masters → python-data NOT fired (pool prune)" \
    "python-data: no" "$(python_data_marker_detected "$fx")"
assert_eq "pool pyproject + obs import masters → python-observability NOT fired (pool prune)" \
    "python-observability-marker: no" "$(python_observability_marker_detected "$fx")"
# Control: the LIVE-tree Swift source is still detected (the prune
# removes only the pool, never live-tree markers).
mkdir -p "$fx/Sources/Model"
cat > "$fx/Sources/Model/Item.swift" <<'EOF'
import SwiftData
@Model final class Item { var id = 0 }
EOF
assert_eq "live-tree import SwiftData still detected (prune removes pool only)" \
    "swiftdata-marker: yes" "$(swiftdata_marker_detected "$fx")"

# Control: a REAL live-tree .proto (NOT in the pool) still fires — the
# exclusion narrows to the pool, it does not suppress genuine markers.
fx=$(mkfixture pool-exclusion-live-proto)
mkdir -p "$fx/proto/myorg/v1"
cat > "$fx/proto/myorg/v1/svc.proto" <<'EOF'
syntax = "proto3";
package myorg.v1;
message Ping { string id = 1; }
EOF
mkdir -p "$fx/pack-capability-pool/proto"
cat > "$fx/pack-capability-pool/proto/pooled.proto" <<'EOF'
syntax = "proto3";
EOF
assert_eq "live-tree .proto + pool both present → protobuf still fired (live marker wins)" \
    "protobuf-marker: yes" "$(protobuf_marker_detected "$fx")"

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
