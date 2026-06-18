#!/usr/bin/env bash
# pack-internal: true  (push-time build/release tool; not a user-facing verb)
# scripts/manifest-sync.sh — push-time fixture-manifest regeneration method.
#
# BD-228 (design maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
# §2). Run by the orchestrator immediately BEFORE `git push`, after all commits
# for the push are landed locally. It regenerates test-fixtures/manifest.txt
# EXACTLY ONCE iff a fixture input changed in the commits about to be pushed, and
# is a complete no-op otherwise. Commit-count-agnostic: a 1-commit and a
# 20-commit push are screened by the same union-diff set test.
#
# This tool NEVER stages, commits, or pushes (CLAUDE.md "agents-never-commit" —
# tools do not commit; only the orchestrator commits, with user approval). It
# regenerates the manifest file on disk and reports via the exit-code contract +
# a stdout token; the orchestrator decides how to land any change.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): pack-internal
# build/release tool. NEVER a runtime dependency of a project deliverable; no
# client surface invokes it; it does NOT ship (absent from the install-map and
# from _SANCTIONED_PACK_SIDE_SHIPPED).
#
# Exit-code contract (design §2.7), consumed by the orchestrator:
#   0   → no action needed:
#           MANIFEST-SKIP  (no fixture input changed; build.sh NOT run)
#           MANIFEST-NOOP  (an input changed, but the rebuilt manifest is identical)
#   10  → MANIFEST-CHANGED: the regenerated manifest differs; the orchestrator
#         must commit it before push.
#   1   → error (build.sh failed, or the git range is hard-unresolvable).
#
# Stdout tokens (one per run): MANIFEST-SKIP / MANIFEST-NOOP / MANIFEST-CHANGED
# (errors print to stderr).
#
# Usage:
#   bash scripts/manifest-sync.sh            # screen the unpushed range, regen iff needed
#   PACK_MANIFEST_RANGE="A..B" bash scripts/manifest-sync.sh   # override the range (tests)
#
# Idempotent: re-running on a current tree yields MANIFEST-NOOP/MANIFEST-SKIP +
# exit 0 (the rebuild is deterministic — design §2.6).

set -u

# ── Exit codes ──────────────────────────────────────────────────────────────
readonly EXIT_OK=0
readonly EXIT_CHANGED=10
readonly EXIT_ERR=1

# ── Locate repo + load the input predicate (single SoT) ─────────────────────
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$THIS_DIR/.." && pwd)"
BUILD_SH="$REPO_ROOT/test-fixtures/build.sh"
MANIFEST="$REPO_ROOT/test-fixtures/manifest.txt"
INPUTS_LIB="$THIS_DIR/lib/manifest-inputs.sh"

say()  { printf '%s\n' "$*"; }
warn() { printf 'manifest-sync: warning: %s\n' "$*" >&2; }
err()  { printf 'manifest-sync: error: %s\n' "$*" >&2; }

if [[ ! -f "$INPUTS_LIB" ]]; then
    err "input predicate SoT not found: $INPUTS_LIB"
    exit "$EXIT_ERR"
fi
# shellcheck source=scripts/lib/manifest-inputs.sh
. "$INPUTS_LIB"

# ── Resolve the unpushed range (design §2.3) ────────────────────────────────
# Prefer an explicit override (used by the self-provisioned test). Otherwise:
#   @{upstream}..HEAD   — commits not yet on the tracking remote (primary)
#   origin/<branch>..HEAD — if no upstream is configured
#   HEAD               — tip-only screen + warn (no remote ref resolvable)
_resolve_push_range() {
    if [[ -n "${PACK_MANIFEST_RANGE:-}" ]]; then
        printf '%s\n' "$PACK_MANIFEST_RANGE"
        return 0
    fi
    if git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' \
            >/dev/null 2>&1; then
        printf '%s\n' "@{upstream}..HEAD"
        return 0
    fi
    local branch
    branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ -n "$branch" && "$branch" != "HEAD" ]] \
            && git -C "$REPO_ROOT" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
        printf '%s\n' "origin/$branch..HEAD"
        return 0
    fi
    warn "no upstream/origin ref resolvable; screening HEAD tip only (push may under-scope)"
    printf '%s\n' "HEAD"
    return 0
}

# ── Determine whether any fixture input changed over the range ──────────────
# Union diff of changed paths over the range, then the SoT membership test.
# Commit-count-agnostic: one set test over the union, not a per-commit loop.
_fixture_inputs_changed() {
    local range="$1" changed path
    # For a tip-only "HEAD" pseudo-range, diff HEAD against its first parent so a
    # single unpushed tip commit is still screened; if HEAD has no parent, fall
    # back to listing the tree (treat all tracked paths as candidates).
    if [[ "$range" == "HEAD" ]]; then
        if git -C "$REPO_ROOT" rev-parse --verify -q "HEAD~1" >/dev/null 2>&1; then
            changed="$(git -C "$REPO_ROOT" diff --name-only "HEAD~1..HEAD" 2>/dev/null || true)"
        else
            changed="$(git -C "$REPO_ROOT" ls-files 2>/dev/null || true)"
        fi
    else
        changed="$(git -C "$REPO_ROOT" diff --name-only "$range" 2>/dev/null || true)"
    fi
    # Empty diff → no inputs changed.
    [[ -n "$changed" ]] || return 1
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        if manifest_path_is_input "$path"; then
            return 0
        fi
    done <<EOF
$changed
EOF
    return 1
}

# ── Regenerate the manifest ONCE, report whether it changed on disk ─────────
# Returns: 0 = manifest unchanged after rebuild (NOOP); 10 = manifest changed
# (CHANGED); 1 = build.sh failed.
_regen_manifest() {
    if [[ ! -f "$BUILD_SH" ]]; then
        err "fixture builder not found: $BUILD_SH"
        return "$EXIT_ERR"
    fi
    say "manifest-sync: fixture input changed — rebuilding fixtures once (build.sh --all --clean)"
    if ! bash "$BUILD_SH" --all --clean >&2; then
        err "build.sh --all --clean failed"
        return "$EXIT_ERR"
    fi
    # Did the committed manifest change on disk?
    if git -C "$REPO_ROOT" diff --quiet -- "test-fixtures/manifest.txt" 2>/dev/null; then
        return "$EXIT_OK"      # unchanged → NOOP
    fi
    return "$EXIT_CHANGED"     # changed → orchestrator must commit it
}

main() {
    local range rc
    range="$(_resolve_push_range)"

    if ! _fixture_inputs_changed "$range"; then
        say "MANIFEST-SKIP: no fixture-input changed in $range"
        exit "$EXIT_OK"
    fi

    _regen_manifest
    rc=$?
    case "$rc" in
        "$EXIT_OK")
            say "MANIFEST-NOOP: input changed but $MANIFEST is unchanged after rebuild"
            exit "$EXIT_OK"
            ;;
        "$EXIT_CHANGED")
            say "MANIFEST-CHANGED: test-fixtures/manifest.txt"
            exit "$EXIT_CHANGED"
            ;;
        *)
            exit "$EXIT_ERR"
            ;;
    esac
}

main "$@"
