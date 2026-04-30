#!/usr/bin/env bash
# build-migration-fixture.sh — reconstruct a v9.3-shape project tree at
# $TARGET from the pack repo's v9.3 tag, then overlay fixture-specific
# customizations from $FIXTURE_DIR/overlay/.
#
# Used by scripts/test-migration.sh to build self-contained migration
# fixtures without snapshotting the entire v9.3 baseline (~100 files)
# into the pack repo. The fixture only stores the *delta* from baseline.
#
# Usage:
#   PACK=/path/to/pack \
#     ./build-migration-fixture.sh <fixture-dir> <target-project-dir>
#
# Arguments:
#   <fixture-dir>          Path to a fixture directory under
#                          maintenance-docs/test-fixtures/. Must contain
#                          (optional) overlay/ directory.
#   <target-project-dir>   Empty directory where the v9.3 project shape
#                          will be built. Created if missing; must be empty.
#
# Exit codes:
#   0  success
#   1  argument error or PACK invalid
#   2  target directory not empty

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <fixture-dir> <target-project-dir>" >&2
    exit 1
fi

FIXTURE_DIR="$1"
TARGET="$2"

if [[ -z "${PACK:-}" ]]; then
    echo "error: PACK env var required" >&2
    exit 1
fi
if [[ ! -d "$PACK" ]]; then
    echo "error: PACK does not exist: $PACK" >&2
    exit 1
fi
if ! git -C "$PACK" rev-parse v9.3 >/dev/null 2>&1; then
    echo "error: v9.3 tag not resolvable in $PACK" >&2
    exit 1
fi
if [[ ! -d "$FIXTURE_DIR" ]]; then
    echo "error: fixture dir not found: $FIXTURE_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET"
if [[ -n "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
    echo "error: target directory not empty: $TARGET" >&2
    exit 2
fi

TARGET_ABS="$(cd "$TARGET" && pwd)"

# ── 1. Reconstruct v9.3 baseline from project-template/ at v9.3 ──
#
# At v9.3 the project shape comes from project-template/ in two ways:
#
#   - Files at project-template/<path> map directly to <path> in the
#     project tree (e.g., project-template/CLAUDE.md → CLAUDE.md,
#     project-template/.claude/agents/coder.md → .claude/agents/coder.md).
#
#   - project-template/skills/<skill>/SKILL.md is distributed at install
#     time to .claude/skills/<skill>/, .codex/skills/<skill>/, and
#     .gemini/skills/<skill>/SKILL.md (three copies per skill).
#
# Plus supporting-docs/METHODOLOGY.md → docs/pack/METHODOLOGY.md
# (canonical project-side location).
# Plus supporting-docs/PROMPT-TEMPLATES.md → docs/pack/PROMPT-TEMPLATES.md
# (the v9.3 monolith retired by v10).

cd "$PACK"

# Direct file mappings from project-template/.
git ls-tree -r v9.3 --name-only project-template/ | while read -r path; do
    rel="${path#project-template/}"
    [[ -z "$rel" ]] && continue
    # Skip skills/ — those are distributed separately below.
    [[ "$rel" == skills/* ]] && continue
    target_path="$TARGET_ABS/$rel"
    mkdir -p "$(dirname "$target_path")"
    if ! git show "v9.3:$path" > "$target_path" 2>/dev/null; then
        rm -f "$target_path"
    fi
done

# Distribute project-template/skills/<skill>/SKILL.md to the three tool dirs.
git ls-tree -r v9.3 --name-only project-template/skills/ | grep '/SKILL\.md$' | while read -r path; do
    skill_name="$(basename "$(dirname "$path")")"
    for tool in claude codex gemini; do
        target_path="$TARGET_ABS/.${tool}/skills/${skill_name}/SKILL.md"
        mkdir -p "$(dirname "$target_path")"
        git show "v9.3:$path" > "$target_path" 2>/dev/null || rm -f "$target_path"
    done
done

# METHODOLOGY.md to docs/pack/.
mkdir -p "$TARGET_ABS/docs/pack"
if git show v9.3:supporting-docs/METHODOLOGY.md > "$TARGET_ABS/docs/pack/METHODOLOGY.md" 2>/dev/null; then
    :
else
    rm -f "$TARGET_ABS/docs/pack/METHODOLOGY.md"
fi

# PROMPT-TEMPLATES.md to docs/pack/.
if git show v9.3:supporting-docs/PROMPT-TEMPLATES.md > "$TARGET_ABS/docs/pack/PROMPT-TEMPLATES.md" 2>/dev/null; then
    :
else
    rm -f "$TARGET_ABS/docs/pack/PROMPT-TEMPLATES.md"
fi

# ── 2. Apply fixture overlays on top ──
#
# Each fixture directory may have an overlay/ subdirectory whose contents
# are copied verbatim into the target tree, replacing files at the same
# path. This is how a fixture expresses customization without
# duplicating the entire v9.3 baseline.

if [[ -d "$FIXTURE_DIR/overlay" ]]; then
    cd "$FIXTURE_DIR/overlay"
    find . -type f -print0 | while IFS= read -r -d '' f; do
        rel="${f#./}"
        target_path="$TARGET_ABS/$rel"
        mkdir -p "$(dirname "$target_path")"
        cp "$FIXTURE_DIR/overlay/$rel" "$target_path"
    done
fi

# Ensure scripts are executable.
chmod +x "$TARGET_ABS/scripts"/*.sh 2>/dev/null || true
chmod +x "$TARGET_ABS/agent-run.sh" 2>/dev/null || true
