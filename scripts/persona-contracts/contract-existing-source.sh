#!/usr/bin/env bash
# pack-internal: true  (CI persona contract; not a user-facing verb)
# scripts/persona-contracts/contract-existing-source.sh — BD-285 C1
# existing-source collision-sidecar persona contract.
#
# Persona: a developer with an in-progress project that ALREADY OWNS a
# non-trinity file the pack also ships (a committed, executable
# `scripts/test.sh` whose content differs from the pack's shipped
# `project-template/scripts/test.sh`) runs init-project.sh to add the AI
# Agent Config Pack on top. The fixture classifies as `existing-source`
# (a Package.swift language marker, no trinity, no AI-config dirs), so
# stage S5 routes every `project-template/scripts/*` file through
# existing_classifier_copy().
#
# This contract closes GAP-1 (BD-285): the reachable
#   existing_classifier_copy -> three_way_classify "" ours theirs
#   -> project-shadows-new-pack -> `${dst}.pack-template`
# branch (scripts/init-project.sh) had NO positive test coverage. On a
# genuine collision the branch must:
#   - leave the user's file LIVE and byte-identical to its pre-install
#     content (BD-285 FOLD F-1: a fresh install NEVER overwrites the user
#     file on a non-trinity collision), and
#   - copy the pack version to `<dst>.pack-template` so the developer can
#     reconcile manually.
#
# Assertions:
#   1. init-project.sh exits 0 on the existing-source sandbox.
#   2. The collision sidecar `scripts/test.sh.pack-template` IS created.
#   3. The sidecar is byte-identical to the pack's shipped
#      `project-template/scripts/test.sh` (it parks the PACK version).
#   4. The user's `scripts/test.sh` is byte-identical to its pre-install
#      snapshot (F-1: never overwritten) and stays executable (stage S5's
#      `chmod +x scripts/*.sh` is a no-op against the already-executable
#      user file).
#   5. The user's `scripts/test.sh` remains DISTINCT from the pack's
#      version (defense-in-depth: the user file was preserved, not
#      clobbered-then-sidecar'd).
#   6. Exactly ONE `.pack-template` sidecar exists tree-wide — the fixture
#      ships no other pack-shipped path, so a clean install surfaces the
#      single genuine collision and no spurious sidecars.
#
# Assertion 2 is the load-bearing bite: it goes RED if the sidecar is
# absent (the exact regression GAP-1 leaves uncovered).
#
# Reference: BACKLOG.md BD-285 (C1 / GAP-1 / FOLD F-1), BD-116 (persona
# contract framework), BD-059 (existing_classifier_copy).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_SH="$PACK_ROOT/test-fixtures/build.sh"
INIT_SH="$PACK_ROOT/scripts/init-project.sh"
PACK_TEST_SH="$PACK_ROOT/project-template/scripts/test.sh"

PASSED=0
FAILED=0

t_pass() { printf '  PASS %s\n' "$1"; PASSED=$((PASSED + 1)); }
t_fail() {
    printf '  FAIL %s' "$1" >&2
    [[ -n "${2:-}" ]] && printf ' — %s' "$2" >&2
    printf '\n' >&2
    FAILED=$((FAILED + 1))
}

# ── Cleanup (single named trap, set once before resource creation) ────────
#
# Reads current values of SANDBOX / PRE_SNAPSHOT at trap-fire time, so
# partial-creation paths are handled naturally (anything still empty at
# fire time is skipped).

PRE_SNAPSHOT=""

_cleanup() {
    [[ -n "${PRE_SNAPSHOT:-}" && -f "$PRE_SNAPSHOT" ]] && rm -f "$PRE_SNAPSHOT"
    [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"
    return 0
}
trap _cleanup EXIT

# ── Preconditions ──────────────────────────────────────────────────────────
#
# The contract's whole premise is that the pack ships a scripts/test.sh
# that collides with the fixture's. If the pack ever stops shipping it the
# collision path is untestable — fail loud rather than silently pass.

if [[ ! -f "$PACK_TEST_SH" ]]; then
    printf 'error: pack no longer ships project-template/scripts/test.sh; ' >&2
    printf 'the collision fixture must be re-pointed at a still-shipped file\n' >&2
    exit 2
fi

# ── Sandbox ────────────────────────────────────────────────────────────────

SANDBOX="$(bash "$BUILD_SH" --for-contract existing-collision)" \
    || { printf 'error: failed to materialize existing-collision sandbox\n' >&2; exit 2; }

printf '── BD-285 existing-source collision contract ──\n'
printf '  sandbox:  %s\n' "$SANDBOX"
printf '  pack:     %s\n' "$PACK_ROOT"

# ── Snapshot the colliding user file BEFORE init ──────────────────────────
#
# The fixture OWNS scripts/test.sh (committed executable, distinct content).
# We snapshot its exact pre-install bytes so Assertion 4 can prove the pack
# left it byte-identical.

if [[ ! -f "$SANDBOX/scripts/test.sh" ]]; then
    printf 'error: fixture is missing the colliding scripts/test.sh\n' >&2
    exit 2
fi
PRE_SNAPSHOT="$(mktemp "${TMPDIR:-/tmp}/pack-contract-existing-source-pre.XXXXXX")"
cp "$SANDBOX/scripts/test.sh" "$PRE_SNAPSHOT"

# Sanity: the fixture file must differ from the pack file, else the
# classifier no-ops (identical content) and there is nothing to test.
if cmp -s "$PRE_SNAPSHOT" "$PACK_TEST_SH"; then
    printf 'error: fixture scripts/test.sh is byte-identical to the pack version; ' >&2
    printf 'the collision branch would never fire (fixture drift?)\n' >&2
    exit 2
fi

# ── Drive init-project.sh ──────────────────────────────────────────────────

if ! PACK="$PACK_ROOT" bash "$INIT_SH" --yes "$SANDBOX" >/dev/null 2>&1; then
    printf 'error: init-project.sh exited non-zero on existing-collision sandbox\n' >&2
    exit 3
fi
t_pass "init-project.sh exited 0 on existing-source collision sandbox"

# ── Assertion 2: the collision sidecar IS created (the load-bearing bite) ──

SIDECAR="$SANDBOX/scripts/test.sh.pack-template"
if [[ -f "$SIDECAR" ]]; then
    t_pass "collision sidecar scripts/test.sh.pack-template created"
else
    t_fail "collision sidecar scripts/test.sh.pack-template MISSING" \
        "existing_classifier_copy project-shadows-new-pack branch did not fire"
fi

# ── Assertion 3: the sidecar parks the PACK version ───────────────────────

if [[ -f "$SIDECAR" ]]; then
    if cmp -s "$SIDECAR" "$PACK_TEST_SH"; then
        t_pass "sidecar is byte-identical to the pack's project-template/scripts/test.sh"
    else
        t_fail "sidecar content does NOT match the pack's scripts/test.sh"
    fi
fi

# ── Assertion 4: the user's file is preserved byte-identical + executable ──

USER_FILE="$SANDBOX/scripts/test.sh"
if [[ -f "$USER_FILE" ]]; then
    if cmp -s "$USER_FILE" "$PRE_SNAPSHOT"; then
        t_pass "user scripts/test.sh byte-identical to pre-install snapshot (F-1)"
    else
        t_fail "user scripts/test.sh MUTATED by install (F-1 violated)"
    fi
    if [[ -x "$USER_FILE" ]]; then
        t_pass "user scripts/test.sh still executable (S5 chmod is a no-op)"
    else
        t_fail "user scripts/test.sh lost its executable bit"
    fi
else
    t_fail "user scripts/test.sh REMOVED by install"
fi

# ── Assertion 5: user file remains distinct from the pack version ─────────

if [[ -f "$USER_FILE" ]]; then
    if cmp -s "$USER_FILE" "$PACK_TEST_SH"; then
        t_fail "user scripts/test.sh was clobbered with the pack version"
    else
        t_pass "user scripts/test.sh remains distinct from the pack version"
    fi
fi

# ── Assertion 6: exactly one .pack-template sidecar tree-wide ─────────────
#
# The fixture ships no other pack-shipped path (no trinity, no docs/pack,
# no agent-run.sh), so a clean install surfaces the single genuine
# collision and nothing spurious. Scoped to the (tiny) sandbox tree.

sidecars=$(find "$SANDBOX" -type f -name "*.pack-template" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$sidecars" -eq 1 ]]; then
    t_pass "exactly one .pack-template sidecar (the scripts/test.sh collision)"
else
    t_fail ".pack-template sidecar count unexpected" "expected=1 actual=$sidecars"
    find "$SANDBOX" -type f -name "*.pack-template" -not -path "*/.git/*" 2>/dev/null | sed 's/^/    /' >&2
fi

# ── Results ────────────────────────────────────────────────────────────────

printf '\n=== existing-source collision contract: %d passed, %d failed ===\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
exit 0
