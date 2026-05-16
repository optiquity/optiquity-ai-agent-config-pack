#!/usr/bin/env bash
# scripts/tests/test-v11-realistic-ot.sh — Batch 19 broad-fix SHOULD-2:
# integration test that consumes the built `test-fixtures/v11-realistic-ot/`
# fixture and asserts the BD-160/170 + BD-164 + BD-168 end-to-end chain
# stays in-sync against a realistic post-decompose v11 surface.
#
# Background:
#   The v11-realistic-ot fixture is built by `test-fixtures/build.sh`,
#   which runs the BD-164 per-entry helpers (decompose + regenerate-mirror
#   + regenerate-TOC) against C4-written project-side monolithic mirrors
#   and asserts a byte-identical round-trip at build time
#   (`build.sh:539` cmp -s check). The build-time round-trip catches
#   helper regressions that BREAK the byte-identity invariant — but a
#   bug that makes the regenerated mirror byte-identical for the WRONG
#   reason (e.g., both sides emit the same wrong shape) would no-op-pass
#   build.sh's check.
#
#   This runner is the post-build consumer: it walks the built fixture
#   and re-asserts the integration boundary from outside build.sh's
#   own round-trip helper. Three assertion families:
#
#     A. Per-entry trees materialize with the expected supporting files
#        + at least the entries C4 wrote.
#     B. Regenerated mirrors are byte-identical to a fresh regeneration
#        run against the on-disk per-entry tree (round-trip from the
#        outside).
#     C. validate-pack.py Check 32/33/34 run cleanly when invoked in
#        this environment. NOTE: validate-pack.py's REPO_ROOT is
#        derived from `__file__` not cwd, so it always validates the
#        PACK itself (where pack-side per-entry trees don't exist yet
#        until BD-102 dog-food per integration parent §10.5). The
#        expected behavior is therefore SKIP for Check 32/33/34 with
#        the "pre-BD-102 dog-food pack-self" message. We assert that
#        SKIP wording AND exit-0, which is the load-bearing CI signal
#        for the pack-side scope.
#
# Wired in CI by validate-pack.yml AFTER the "build test fixtures" +
# "fixture manifest verify" steps and BEFORE the migrator/per-entry
# tests (so a regression in build.sh's round-trip helper surfaces
# before the downstream consumer suites attribute the failure
# elsewhere).
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO
# `&>`, NO GNU-only flags.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_NAME="v11-realistic-ot"
FIXTURE_DIR="$REPO_ROOT/test-fixtures/$FIXTURE_NAME"
PE_LIB_DIR="$REPO_ROOT/scripts/lib/per-entry"
VALIDATOR="$REPO_ROOT/scripts/validate-pack.py"

PASSED=0
FAILED=0

t_pass() { printf "  \033[32mPASS\033[0m %s\n" "$1"; PASSED=$((PASSED + 1)); }
t_fail() {
    printf "  \033[31mFAIL\033[0m %s\n" "$1" >&2
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2" >&2
    FAILED=$((FAILED + 1))
}

assert_eq() {
    # $1=label $2=expected $3=actual
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_file() {
    # $1=label $2=path
    if [[ -f "$2" ]]; then t_pass "$1"
    else t_fail "$1" "missing file: $2"; fi
}

assert_dir() {
    # $1=label $2=path
    if [[ -d "$2" ]]; then t_pass "$1"
    else t_fail "$1" "missing dir: $2"; fi
}

assert_contains() {
    # $1=label $2=haystack $3=needle
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

assert_byte_identical() {
    # $1=label $2=path A $3=path B
    if cmp -s "$2" "$3"; then t_pass "$1"
    else
        t_fail "$1" "files differ: $2 vs $3"
        diff "$2" "$3" 2>&1 | head -20 | sed 's/^/         /' >&2 || true
    fi
}

# ── Precondition: fixture must exist + be a built git repo ────────────────
#
# Mirrors the `require_fixture` pattern from scripts/test-migrator-skills.sh
# (BD-163). Fails fast with the exact build command when the gitignored
# fixture directory is missing or unbuilt.
require_fixture() {
    local name="$1"
    local fx="$REPO_ROOT/test-fixtures/$name"
    if [[ ! -d "$fx" || ! -f "$fx/.git/HEAD" ]]; then
        printf 'ERROR: %s requires test-fixtures/%s/ but it does not exist or is not a built fixture.\n' \
            "$(basename "${BASH_SOURCE[0]}")" "$name" >&2
        printf '       Build it with: bash test-fixtures/build.sh --name %s\n' "$name" >&2
        printf '       (or build all fixtures: bash test-fixtures/build.sh --all --clean)\n' >&2
        exit 3
    fi
}

require_fixture "$FIXTURE_NAME"

# Scratch dir for fresh-regeneration comparisons.
SCRATCH=$(mktemp -d -t v11-realistic-ot-test.XXXXXX)
trap 'rm -rf "$SCRATCH"' EXIT INT TERM

# Source the BD-164 helpers (same load order as init-project.sh, the
# v10→v11 migrator decompose adapter, and build.sh). Re-sourcing is a
# no-op via each helper's internal `type` guard.
# shellcheck disable=SC1091
. "$PE_LIB_DIR/_lib.sh"
# shellcheck disable=SC1091
. "$PE_LIB_DIR/decompose.sh"
# shellcheck disable=SC1091
. "$PE_LIB_DIR/mirror-generate.sh"
# shellcheck disable=SC1091
. "$PE_LIB_DIR/toc-regenerate.sh"

# ─────────────────────────────────────────────────────────────────────────
# Group A — Per-entry trees materialize with expected supporting files
# ─────────────────────────────────────────────────────────────────────────
#
# The fixture's three project-side streams (backlog, implementation-plan,
# changelog) each ship `_rules.md` + `_intro.md` + `_toc.md`. The
# changelog stream additionally ships `_format.md` per integration
# parent §3.2 + §9.7 (changelog-only). Project-side trees do NOT carry
# `_v8-resolved-archive.md` — that's pack-/backlog/ scope per §11.2.
#
# Backlog has entries (5 TD-NNN files per BD-170 IMPL-REPORT C4 spec);
# implementation-plan + changelog ship as supporting-files-only because
# C4 did not seed entries for those streams.

echo
echo "=== Group A: per-entry trees materialize ==="

PE_BACKLOG="$FIXTURE_DIR/docs/project/backlog"
PE_PLAN="$FIXTURE_DIR/docs/project/implementation-plan"
PE_CHANGELOG="$FIXTURE_DIR/docs/project/changelog"

assert_dir   "A.1  backlog/ dir present"                   "$PE_BACKLOG"
assert_file  "A.2  backlog/_rules.md present"              "$PE_BACKLOG/_rules.md"
assert_file  "A.3  backlog/_intro.md present"              "$PE_BACKLOG/_intro.md"
assert_file  "A.4  backlog/_toc.md present"                "$PE_BACKLOG/_toc.md"

assert_dir   "A.5  implementation-plan/ dir present"       "$PE_PLAN"
assert_file  "A.6  implementation-plan/_rules.md present"  "$PE_PLAN/_rules.md"
assert_file  "A.7  implementation-plan/_intro.md present"  "$PE_PLAN/_intro.md"
assert_file  "A.8  implementation-plan/_toc.md present"    "$PE_PLAN/_toc.md"

assert_dir   "A.9  changelog/ dir present"                 "$PE_CHANGELOG"
assert_file  "A.10 changelog/_rules.md present"            "$PE_CHANGELOG/_rules.md"
assert_file  "A.11 changelog/_intro.md present"            "$PE_CHANGELOG/_intro.md"
assert_file  "A.12 changelog/_toc.md present"              "$PE_CHANGELOG/_toc.md"
assert_file  "A.13 changelog/_format.md present"           "$PE_CHANGELOG/_format.md"

# Project-side streams must NOT carry _v8-resolved-archive.md (pack-
# /backlog/ scope only per integration parent §11.2 + §2.6).
if [[ ! -f "$PE_BACKLOG/_v8-resolved-archive.md" ]]; then
    t_pass "A.14 backlog/_v8-resolved-archive.md absent (pack /backlog/ only)"
else
    t_fail "A.14 backlog/_v8-resolved-archive.md absent (pack /backlog/ only)" \
        "found at $PE_BACKLOG/_v8-resolved-archive.md — project-side leak"
fi

# Implementation-plan must NOT carry _format.md (changelog-only).
if [[ ! -f "$PE_PLAN/_format.md" ]]; then
    t_pass "A.15 implementation-plan/_format.md absent (changelog-only)"
else
    t_fail "A.15 implementation-plan/_format.md absent (changelog-only)" \
        "found at $PE_PLAN/_format.md — implementation-plan stream leak"
fi

# Backlog stream has TD-NNN entries (BD-170 IMPL-REPORT C4 wrote 5).
# Count TD-NNN.md files — at least 1 expected. We assert ">= 1" rather
# than "exactly 5" so the assertion is drift-resilient if C4 grows.
TD_COUNT=$(find "$PE_BACKLOG" -maxdepth 1 -type f -name 'TD-[0-9]*.md' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$TD_COUNT" -ge 1 ]]; then
    t_pass "A.16 backlog/ has >= 1 TD-NNN entry (found $TD_COUNT)"
else
    t_fail "A.16 backlog/ has >= 1 TD-NNN entry (found $TD_COUNT)" \
        "C4 step in build.sh should write TD-NNN entries"
fi

# Spot-check the first TD-NNN file has the Layer 2 back-pointer at line 1
# (Addendum #2 §2: HTML-comment line-1 only, no body field). Pick the
# first sorted TD-NNN.md for stability.
FIRST_TD=$(find "$PE_BACKLOG" -maxdepth 1 -type f -name 'TD-[0-9]*.md' 2>/dev/null | sort | head -1)
if [[ -n "$FIRST_TD" ]]; then
    FIRST_LINE=$(head -1 "$FIRST_TD")
    case "$FIRST_LINE" in
        "<!-- per-entry source: docs/project/backlog/"*"; contract: docs/project/backlog/_rules.md -->")
            t_pass "A.17 first TD entry has Layer 2 back-pointer at line 1"
            ;;
        *)
            t_fail "A.17 first TD entry has Layer 2 back-pointer at line 1" \
                "got: '$FIRST_LINE'"
            ;;
    esac
fi

# ─────────────────────────────────────────────────────────────────────────
# Group B — Regenerated mirrors byte-identical to fresh regeneration
# ─────────────────────────────────────────────────────────────────────────
#
# For each of the three project-side streams, copy the on-disk mirror
# aside, then run the BD-164 mirror generator against the on-disk per-
# entry tree with output redirected to a scratch path. The scratch
# mirror MUST be byte-identical to the saved on-disk mirror — this is
# the integration-boundary verification mirroring the BD-164 round-trip
# pattern used by build.sh:539 and by test-per-entry.sh Group 1.
#
# PE_FORCE_OVERWRITE_MIRROR=1 because we're running against a freshly-
# built fixture where the on-disk mirror is, by construction, in sync
# (build.sh's round-trip check already passed); we just need to bypass
# the divergence-prompt path so the helper runs non-interactively.

echo
echo "=== Group B: regenerated mirrors byte-identical to fresh regen ==="

for spec in \
    "project-backlog|docs/project/BACKLOG.md|docs/project/backlog|B.1|B.2" \
    "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan|B.3|B.4" \
    "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog|B.5|B.6"; do
    stream_key="${spec%%|*}"
    rest="${spec#*|}"
    mirror_rel="${rest%%|*}"
    rest="${rest#*|}"
    stream_dir_rel="${rest%%|*}"
    rest="${rest#*|}"
    label_present="${rest%%|*}"
    label_match="${rest##*|}"

    mirror_path="$FIXTURE_DIR/$mirror_rel"
    stream_dir="$FIXTURE_DIR/$stream_dir_rel"

    # B.N — on-disk mirror present (pre-flight; build.sh would have died
    # earlier if it weren't).
    if [[ -f "$mirror_path" ]]; then
        t_pass "$label_present $stream_key on-disk mirror present at $mirror_rel"
    else
        t_fail "$label_present $stream_key on-disk mirror present at $mirror_rel" \
            "missing: $mirror_path"
        continue
    fi

    # Snapshot the on-disk mirror. The helper writes to <mirror_path>
    # (the actual on-disk location), so we save the original first and
    # restore after the comparison to leave the fixture untouched.
    snap="$SCRATCH/${stream_key}.mirror.snap"
    cp "$mirror_path" "$snap"

    # Regenerate in place (PE_FORCE_OVERWRITE=1 bypasses divergence
    # routing; the on-disk mirror is, by construction, in sync). Run
    # under a subshell so the env-var doesn't leak between iterations.
    (
        export PE_FORCE_OVERWRITE_MIRROR=1
        per_entry_regenerate_mirror "$stream_key" "$stream_dir" "$mirror_path" </dev/null
    )
    regen_rc=$?

    if [[ "$regen_rc" -ne 0 ]]; then
        t_fail "$label_match $stream_key regen rc=0 (got $regen_rc)" \
            "per_entry_regenerate_mirror returned non-zero"
        # Restore the snapshot before continuing.
        cp "$snap" "$mirror_path"
        continue
    fi

    assert_byte_identical "$label_match $stream_key regenerated mirror byte-identical to on-disk" \
        "$snap" "$mirror_path"

    # Restore the snapshot — leave the fixture untouched for any
    # downstream test step that reads the fixture.
    cp "$snap" "$mirror_path"
done

# ─────────────────────────────────────────────────────────────────────────
# Group C — validate-pack.py Check 32/33/34 behave correctly given the
#           pack-side scope (per integration parent §10.6) when run in
#           this CI environment
# ─────────────────────────────────────────────────────────────────────────
#
# validate-pack.py computes REPO_ROOT from `__file__` (line 171), not
# from cwd. So whether invoked from the fixture or from the pack root,
# it always validates the pack itself. Pack-side per-entry trees
# (`backlog/`, `changelog/` at pack-repo root) don't materialize until
# Batch 23 (BD-102) dog-food per integration parent §10.5. Expected
# behavior right now: Check 32/33/34 print OK + SKIP message naming
# "pre-BD-102 dog-food pack-self" and the validator exits 0.
#
# The assertions: (a) exit code 0, (b) Check 32 OK lines reference
# pack-side `backlog/` + `changelog/` with the SKIP message, (c) Check
# 33 same shape, (d) Check 34 reports "no per-entry trees present".
# These are the load-bearing CI signals that the pack-side scope is
# honored and the SKIP-message wording stays in sync with the renumber-
# cascade canonical anchor (BD-102).
#
# Note on scope: this group verifies the validator's CI behavior given
# the current pack-side absence of per-entry trees. When pack-self
# dog-food lands at Batch 23, Check 32/33/34 will start asserting
# byte-identical mirror regeneration against the materialized
# pack-side trees, and this test group will need its expectations
# revisited.

echo
echo "=== Group C: validate-pack.py Check 32/33/34 pack-side SKIP behavior ==="

VALIDATOR_OUT="$SCRATCH/validate-pack.out"
VALIDATOR_RC=0
python3 "$VALIDATOR" >"$VALIDATOR_OUT" 2>&1 || VALIDATOR_RC=$?

assert_eq "C.1 validate-pack.py exits 0" "0" "$VALIDATOR_RC"

VALIDATOR_TEXT=$(cat "$VALIDATOR_OUT")

# Check 32 banner present and SKIP messages reference both pack-side
# streams with the durable "pre-BD-102 dog-food pack-self" anchor.
assert_contains "C.2 Check 32 banner present" "$VALIDATOR_TEXT" \
    "── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──"
assert_contains "C.3 Check 32 backlog/ SKIP wording (BD-102 anchor)" "$VALIDATOR_TEXT" \
    "backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self"
assert_contains "C.4 Check 32 changelog/ SKIP wording (BD-102 anchor)" "$VALIDATOR_TEXT" \
    "changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self"

# Check 33 banner + same SKIP wording.
assert_contains "C.5 Check 33 banner present" "$VALIDATOR_TEXT" \
    "── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──"
assert_contains "C.6 Check 33 backlog/ SKIP wording (BD-102 anchor)" "$VALIDATOR_TEXT" \
    "backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self"
assert_contains "C.7 Check 33 changelog/ SKIP wording (BD-102 anchor)" "$VALIDATOR_TEXT" \
    "changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self"

# Check 34 banner + the "no per-entry trees present" SKIP wording.
assert_contains "C.8 Check 34 banner present" "$VALIDATOR_TEXT" \
    "── Check 34: cross-reference integrity (BD-168) ──"
assert_contains "C.9 Check 34 SKIP wording" "$VALIDATOR_TEXT" \
    "no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self"

# Verify the OK-message anchor never reverts to the pre-BD-168-retro-fix
# "pre-Batch-22" or "pre-Batch-23" wording (regression guard for the
# BD-168 retro-fix S3 sweep + BD-165 broad-fix MUST-1 parallel sweep
# in decompose.sh — both anchor on the durable BD-102 label).
if ! printf '%s' "$VALIDATOR_TEXT" | grep -q "pre-Batch-2[23]"; then
    t_pass "C.10 no stale 'pre-Batch-22' or 'pre-Batch-23' wording (BD-102 anchor honored)"
else
    t_fail "C.10 no stale 'pre-Batch-22' or 'pre-Batch-23' wording (BD-102 anchor honored)" \
        "validator output contains stale Batch-NN wording"
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────

echo
echo "=== Summary ==="
echo "PASS: $PASSED"
echo "FAIL: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo
    echo "All v11-realistic-ot integration tests PASSED ($PASSED/$PASSED)."
    exit 0
else
    echo
    echo "v11-realistic-ot integration tests FAILED ($FAILED/$((PASSED + FAILED)))."
    exit 1
fi
