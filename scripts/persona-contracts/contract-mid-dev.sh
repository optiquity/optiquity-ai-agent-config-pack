#!/usr/bin/env bash
# scripts/persona-contracts/contract-mid-dev.sh — BD-116 mid-dev persona
# contract.
#
# Persona: a developer with an in-progress Swift+Python+gRPC project (a
# real codebase mid-development with prior git history) runs init-project
# to add the AI Agent Config Pack on top. The contract asserts:
#   1. Every user-domain file from the BD-115 `existing-project-mid-dev`
#      fixture is byte-identical post-install (sha256 unchanged). The
#      pack must NOT clobber user code, tests, build manifests, or
#      project README beyond the documented .gitignore append.
#   2. .gitignore is preserved verbatim at the top (pack additions append
#      below — verified by checking the original content remains as a
#      prefix of the post-install file).
#   3. Pack files now exist at expected locations (trinity, .claude/.codex/
#      .gemini/ directories, scripts/, agent-run.sh, docs/pack/).
#   4. No `.pack-template` sidecars created for files the user did not
#      previously own (pack-only files install cleanly via plain `cp`;
#      the existing-classifier sidecar is reserved for genuine collisions).
#
# Note on --update vs default flow: BD-116's BACKLOG entry literally says
# `init-project.sh --update on the BD-115 fixture`, but `--update` exits
# with EXIT_UPDATE_NOT_CONFIGURED (50) on a project that is not yet
# pack-configured (the BD-115 fixture has zero pack files by design). The
# persona BD-115 actually models is "pack added on top of in-progress
# project," which is the DEFAULT init flow against an `existing-source`
# classification. We therefore drive the default init flow here. Documented
# in IMPLEMENTATION-REPORT-BD-116.md as a deliberate spec deviation, with
# the corresponding POQ raised.
#
# Reference: BACKLOG.md BD-116, BD-115, BD-088.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SH="$PACK_ROOT/test-fixtures/build.sh"
INIT_SH="$PACK_ROOT/scripts/init-project.sh"

PASSED=0
FAILED=0

t_pass() { printf '  PASS %s\n' "$1"; PASSED=$((PASSED + 1)); }
t_fail() {
    printf '  FAIL %s' "$1" >&2
    [[ -n "${2:-}" ]] && printf ' — %s' "$2" >&2
    printf '\n' >&2
    FAILED=$((FAILED + 1))
}

# Cross-platform sha256: use shasum on macOS / BSD, sha256sum on Linux.
_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

# ── Sandbox ────────────────────────────────────────────────────────────────

SANDBOX="$(bash "$BUILD_SH" --for-contract mid-dev)" \
    || { printf 'error: failed to materialize mid-dev sandbox\n' >&2; exit 2; }
trap '[[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

printf '── BD-116 mid-dev contract ──\n'
printf '  sandbox:  %s\n' "$SANDBOX"
printf '  pack:     %s\n' "$PACK_ROOT"

# ── Snapshot user-domain files BEFORE init ────────────────────────────────
#
# Derive the user-domain file list directly from the sandbox (i.e., from
# the BD-115 fixture's contents). Anything that exists pre-install is by
# definition user-domain. We exclude:
#   - .git/ — repository metadata, not relevant to install correctness.
#   - .gitignore — pack stage S8 documents an append; we verify the
#     original content remains as a prefix below, not byte-equality.
#
# This makes the contract auto-evolve: if the BD-115 fixture grows new
# user files, they're picked up automatically.

PRE_SNAPSHOT="$(mktemp -t pack-contract-mid-dev-pre.XXXXXX)"
trap '[[ -f "${PRE_SNAPSHOT:-}" ]] && rm -f "$PRE_SNAPSHOT"; [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT

while IFS= read -r f; do
    rel="${f#"$SANDBOX/"}"
    [[ "$rel" == .git/* ]] && continue
    [[ "$rel" == ".gitignore" ]] && continue
    sha=$(_sha256 "$f")
    printf '%s  %s\n' "$sha" "$rel"
done < <(find "$SANDBOX" -type f) > "$PRE_SNAPSHOT"

pre_count=$(wc -l < "$PRE_SNAPSHOT" | tr -d ' ')
printf '  user-domain files snapshotted: %s\n' "$pre_count"

# Snapshot the pre-install .gitignore so we can verify pack append-only.
PRE_GITIGNORE=""
if [[ -f "$SANDBOX/.gitignore" ]]; then
    PRE_GITIGNORE="$(mktemp -t pack-contract-gitignore.XXXXXX)"
    cp "$SANDBOX/.gitignore" "$PRE_GITIGNORE"
    trap '[[ -f "${PRE_SNAPSHOT:-}" ]] && rm -f "$PRE_SNAPSHOT"; [[ -f "${PRE_GITIGNORE:-}" ]] && rm -f "$PRE_GITIGNORE"; [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"' EXIT
fi

# ── Drive init-project.sh ──────────────────────────────────────────────────

if ! PACK="$PACK_ROOT" bash "$INIT_SH" "$SANDBOX" >/dev/null 2>&1 <<<"y"; then
    printf 'error: init-project.sh exited non-zero on mid-dev sandbox\n' >&2
    exit 3
fi

# ── Assertion 1: user-domain files unchanged (sha256 preserved) ───────────

mismatch=0
while IFS= read -r line; do
    sha="${line%%  *}"
    rel="${line#*  }"
    target="$SANDBOX/$rel"
    if [[ ! -f "$target" ]]; then
        t_fail "user file ${rel} REMOVED by install"
        mismatch=$((mismatch + 1))
        continue
    fi
    actual=$(_sha256 "$target")
    if [[ "$actual" == "$sha" ]]; then
        t_pass "user file ${rel} unchanged (sha256 preserved)"
    else
        t_fail "user file ${rel} MUTATED" "pre=$sha post=$actual"
        mismatch=$((mismatch + 1))
    fi
done < "$PRE_SNAPSHOT"

if [[ "$mismatch" -eq 0 ]]; then
    t_pass "all $pre_count user-domain files preserved verbatim"
fi

# ── Assertion 2: .gitignore preserved as prefix (append-only merge) ───────

if [[ -n "$PRE_GITIGNORE" && -f "$SANDBOX/.gitignore" ]]; then
    pre_lines=$(wc -l < "$PRE_GITIGNORE" | tr -d ' ')
    if head -n "$pre_lines" "$SANDBOX/.gitignore" | cmp -s - "$PRE_GITIGNORE"; then
        t_pass ".gitignore: original ${pre_lines} lines preserved verbatim at top"
    else
        t_fail ".gitignore: original content not preserved as prefix"
    fi
    # Pack additions header should follow.
    if grep -q "AI Agent Config Pack additions" "$SANDBOX/.gitignore"; then
        t_pass ".gitignore: pack-additions section appended"
    else
        t_fail ".gitignore: pack-additions header missing after append"
    fi
fi

# ── Assertion 3: pack landed correctly (presence checks) ──────────────────

# Trinity present.
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    if [[ -f "$SANDBOX/$f" ]]; then
        t_pass "pack ${f} installed"
    else
        t_fail "pack ${f} MISSING"
    fi
done
# Per-CLI directories.
for tool in claude codex gemini; do
    if [[ -d "$SANDBOX/.${tool}/agents" ]]; then
        t_pass ".${tool}/agents/ created"
    else
        t_fail ".${tool}/agents/ MISSING"
    fi
    if [[ -d "$SANDBOX/.${tool}/skills" ]]; then
        t_pass ".${tool}/skills/ created"
    else
        t_fail ".${tool}/skills/ MISSING"
    fi
done
# Scripts + agent-run.
if [[ -x "$SANDBOX/agent-run.sh" ]]; then
    t_pass "agent-run.sh installed and executable"
else
    t_fail "agent-run.sh missing or not executable"
fi
if [[ -d "$SANDBOX/scripts" ]]; then
    t_pass "scripts/ created"
else
    t_fail "scripts/ MISSING"
fi
# docs/pack present.
if [[ -d "$SANDBOX/docs/pack" ]]; then
    t_pass "docs/pack/ created"
else
    t_fail "docs/pack/ MISSING"
fi

# ── Assertion 4: no spurious .pack-template sidecars ──────────────────────
#
# The existing-classifier sidecar fires only on a genuine ours-vs-theirs
# divergence. The BD-115 fixture has only README.md as a potential
# collision (it has both a user README and the pack does NOT ship a
# README at the same path — pack ships docs/pack/* but no top-level
# README.md). So we expect zero `.pack-template` sidecars in a clean run.
sidecars=$(find "$SANDBOX" -type f -name "*.pack-template" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$sidecars" -eq 0 ]]; then
    t_pass "no spurious .pack-template sidecars"
else
    t_fail ".pack-template sidecars found" "count=$sidecars"
    find "$SANDBOX" -type f -name "*.pack-template" -not -path "*/.git/*" 2>/dev/null | sed 's/^/    /' >&2
fi

# ── Results ────────────────────────────────────────────────────────────────

printf '\n=== mid-dev contract: %d passed, %d failed ===\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
exit 0
