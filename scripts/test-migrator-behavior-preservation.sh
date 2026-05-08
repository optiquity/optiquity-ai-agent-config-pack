#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-behavior-preservation.sh — BD-119 C-5 harness.
#
# Behavior-preservation gate for the BD-119 framework refactor of
# `scripts/migrate-v10-to-v11.sh`. Per PLAN-BD-119.md §8 (the equivalence
# contract) and ARCHITECTURE-BD-119.md §10 (behavior-preservation
# rationale), this harness pins five axes across two independent runs of
# the migrator and asserts byte-equivalence (modulo two narrowly scoped
# redactions).
#
# Two runs are compared:
#
#   BASELINE — the pre-refactor monolith pinned at SHA d7b3f07. Sourced
#              from scripts/.bd119-pre-refactor-monolith.sh.snapshot
#              when present (gitignored, branch-local, see C-1 report
#              POQ-4); recovered via `git show d7b3f07:...` when absent.
#
#   ADAPTER  — whatever scripts/migrate-v10-to-v11.sh currently is on
#              this worktree.
#
# Coverage (PLAN §8.4 — 15 assertions total):
#
#   • 2 fixtures × 5 axes = 10 axis assertions across both v10 fixtures
#     in a single invocation (v10-realistic-ot and v10-minimal).
#   • 5 negative-leg tests asserting BASELINE and ADAPTER produce
#     identical numeric exit codes for each documented failure path:
#       N1 — EXIT_PACK_INVALID    (10): PACK env var unset
#       N2 — EXIT_NOT_GIT         (11): target is not a git repo
#       N3 — EXIT_DIRTY           (12): target has uncommitted changes
#       N4 — EXIT_NOT_BASELINE    (13): target is not at v10
#       N5 — EXIT_BASELINE_MISSING(14): required baseline tag missing
#
# Equivalence axes (PLAN §8.2):
#
#   A1 — file list:    set of files written/touched in the post-migration
#                      tree, byte-identical (excludes .git/).
#   A2 — file content: every output file byte-identical (post-redaction
#                      not applied — file content is checked raw via cmp).
#   A3 — report.md:    .pack-migrate-v10-to-v11/report.md content,
#                      byte-identical post-redaction.
#   A4 — stdout:       runtime stdout, byte-identical post-redaction.
#   A5 — exit code:    numeric exit code from the migrator.
#
# Allowed redactions (and ONLY these — PLAN §13.3 forbids broader
# redactions):
#   - ISO-8601 timestamps:   [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z?
#   - Epoch-seconds:         10-digit integers used as timestamps
#   - Tmp paths:             /tmp/*, /var/folders/*, $TMPDIR/*
#
# Per PLAN §13.3, the harness MUST NOT support any of:
#   - allow-listing diverging files
#   - additional redaction regexes
#   - continue-on-error in CI
#   - tagging v11.0 with the harness red
#
# Usage:
#     bash scripts/test-migrator-behavior-preservation.sh [fixture-name]
#
#     fixture-name (optional) restricts the axis sweep to a single
#     fixture name (e.g. v10-realistic-ot or v10-minimal). When omitted,
#     the harness iterates over BOTH v10 fixtures plus the 5 negative
#     legs for the full 15-assertion run. Named fixtures must exist
#     under test-fixtures/<name>/ — re-build via
#     `bash test-fixtures/build.sh --name <name> --clean` if missing.
#
# Exit 0 when all assertions pass; exit 1 otherwise with a per-axis
# breakdown. Summary line:
#
#     === Results: <P> passed, <F> failed ===

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── POQ-4 snapshot reference ───────────────────────────────────────────────
# The pre-refactor monolith canonical SHA. d7b3f07 is the worktree base
# at which the BD-119 work began; this is the byte snapshot the harness
# diffs against. PLAN POQ-4 mandates this SHA as the canonical reference
# and specifies the recovery path when the gitignored snapshot file is
# absent on the working tree.
readonly BD119_PRE_REFACTOR_SHA="d7b3f07"
readonly SNAPSHOT_FILE="$PACK_ROOT/scripts/.bd119-pre-refactor-monolith.sh.snapshot"

# Default v10 fixture set per PLAN §8.4. When the user passes a fixture
# name as $1 we restrict to that fixture (back-compat for one-shot runs).
DEFAULT_FIXTURES=(v10-realistic-ot v10-minimal)
if (( $# >= 1 )) && [[ -n "${1:-}" ]]; then
    FIXTURES=("$1")
    RUN_NEGATIVES=0
else
    FIXTURES=("${DEFAULT_FIXTURES[@]}")
    RUN_NEGATIVES=1
fi

RESULTS_DIR="$(mktemp -d -t bd119-results.XXXXXX)"
KEEP_RESULTS="${BD119_KEEP_RESULTS:-0}"
trap '_cleanup' EXIT

_cleanup() {
    if [[ "$KEEP_RESULTS" = "1" ]]; then
        printf 'BD119_KEEP_RESULTS=1: results retained at %s\n' \
            "$RESULTS_DIR" >&2
    else
        rm -rf "$RESULTS_DIR"
    fi
}

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    detail: %s\n' "$2"
    fails=$((fails + 1))
}

die()  { printf 'error: %s\n' "$1" >&2; exit 1; }

# ── 0. Pre-flight ──────────────────────────────────────────────────────────
echo "== pre-flight =="

if [[ ! -d "$PACK_ROOT/project-template" ]]; then
    die "PACK_ROOT does not look like the pack repo: $PACK_ROOT"
fi

if [[ ! -f "$PACK_ROOT/scripts/migrate-v10-to-v11.sh" ]]; then
    die "missing scripts/migrate-v10-to-v11.sh under $PACK_ROOT"
fi

# Materialize the BASELINE migrator. Prefer the on-disk gitignored
# snapshot (faster + offline-safe). Fall back to git-show at the pinned
# pre-refactor SHA per PLAN POQ-4. If neither is reachable, fail loud.
BASELINE_FILE="$RESULTS_DIR/baseline.sh"

if [[ -f "$SNAPSHOT_FILE" ]]; then
    cp "$SNAPSHOT_FILE" "$BASELINE_FILE"
    echo "  baseline source: $SNAPSHOT_FILE (POQ-4 snapshot file)"
elif git -C "$PACK_ROOT" cat-file -e \
        "$BD119_PRE_REFACTOR_SHA:scripts/migrate-v10-to-v11.sh" 2>/dev/null
then
    git -C "$PACK_ROOT" show \
        "$BD119_PRE_REFACTOR_SHA:scripts/migrate-v10-to-v11.sh" \
        > "$BASELINE_FILE" \
        || die "git show failed at $BD119_PRE_REFACTOR_SHA"
    echo "  baseline source: git show $BD119_PRE_REFACTOR_SHA (POQ-4 fallback)"
else
    die "cannot recover BASELINE: neither snapshot file ($SNAPSHOT_FILE)
        nor SHA $BD119_PRE_REFACTOR_SHA reachable from $PACK_ROOT"
fi
chmod +x "$BASELINE_FILE"

ADAPTER_FILE="$PACK_ROOT/scripts/migrate-v10-to-v11.sh"
echo "  adapter source: $ADAPTER_FILE"
echo "  fixtures:       ${FIXTURES[*]}"
echo "  results dir:    $RESULTS_DIR"

# ── Helpers ────────────────────────────────────────────────────────────────

# Redact the only nondeterministic sources allowed by PLAN §8.2:
#   - ISO-8601 timestamps (with optional Z and fractional seconds)
#   - 10-digit epoch-seconds (only when bracketed by non-digits, to avoid
#     eating arbitrary 10-digit content elsewhere)
#   - Tmp paths under /tmp/, /var/folders/, and $TMPDIR (BSD mktemp on
#     macOS lands under /var/folders; Linux mktemp under /tmp; harness
#     itself may use $TMPDIR if set)
#
# No other redactions are permitted (PLAN §13.3). All sed -E patterns are
# bash-3.2 + BSD/GNU portable; no -i (BSD vs GNU divergent).
_redact() {
    local in="$1" out="$2"
    local tmpdir_pat
    tmpdir_pat=""
    if [[ -n "${TMPDIR:-}" ]]; then
        # Strip trailing slash for stable matching, escape for sed.
        local td="${TMPDIR%/}"
        tmpdir_pat=$(printf '%s' "$td" | sed -e 's/[][\.*^$/]/\\&/g')
    fi
    local sed_args=(
        -E
        -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+(\.[0-9]+)?Z?#<TS>#g'
        -e 's#(^|[^0-9])[0-9]{10}([^0-9]|$)#\1<EPOCH>\2#g'
        -e 's#/tmp/[^ "'"'"']*#<TMP>#g'
        -e 's#/var/folders/[^ "'"'"']*#<TMP>#g'
    )
    if [[ -n "$tmpdir_pat" ]]; then
        sed_args+=(-e "s#${tmpdir_pat}/[^ \"']*#<TMP>#g")
    fi
    sed "${sed_args[@]}" < "$in" > "$out"
}

# Run one impl (BASELINE or ADAPTER) against one /tmp clone of the
# fixture. Captures stdout, stderr, exit, post-tree filelist, and the
# tree itself (tar). Excludes .git/ from filelist + tar (per PLAN §8.2
# A1 rule and to keep the harness independent of git-internal flux).
_run_impl() {
    local impl="$1" migrator="$2" fixture_dir="$3" result_prefix="$4"
    local clone="$RESULTS_DIR/${result_prefix}.${impl}.tree"
    rm -rf "$clone"
    mkdir -p "$clone"

    # Copy the fixture content. The fixture is itself a git repo (built
    # by test-fixtures/build.sh) so we can `cp -R` and the .git/
    # subtree comes along — needed because the migrator requires a
    # clean git working tree (S0 preflight).
    cp -R "$fixture_dir/." "$clone/"

    PACK="$PACK_ROOT" \
    bash "$migrator" "$clone" \
        > "$RESULTS_DIR/${result_prefix}.${impl}.stdout" \
        2> "$RESULTS_DIR/${result_prefix}.${impl}.stderr"
    local rc=$?
    printf '%d\n' "$rc" > "$RESULTS_DIR/${result_prefix}.${impl}.exit"

    # File list: every regular file post-migration, excluding .git/ and
    # the .pack-migrate-* state + backup directories. PLAN §8.3 spells
    # this exclusion out verbatim.
    (
        cd "$clone" && \
        find . -type f \
            \! -path './.git/*' \
            \! -path './.git' \
            \! -path './.pack-migrate-*/*' \
            \! -path './.pack-migrate-*' \
            -print 2>/dev/null \
            | LC_ALL=C sort > "$RESULTS_DIR/${result_prefix}.${impl}.filelist"
    )

    tar -C "$clone" \
        --exclude='./.git' \
        --exclude='./.pack-migrate-*' \
        -cf "$RESULTS_DIR/${result_prefix}.${impl}.tar" . 2>/dev/null

    return 0
}

# ── Per-fixture axis sweep (5 axes) ────────────────────────────────────────
_sweep_fixture() {
    local fixture_name="$1"
    local fixture_dir="$PACK_ROOT/test-fixtures/$fixture_name"
    local prefix="fix-$fixture_name"

    echo
    echo "############################################################"
    echo "## fixture: $fixture_name"
    echo "############################################################"

    # Materialize the fixture if absent. Fixture-internal byte-determinism
    # is the build script's concern; we only require the tree to exist.
    if [[ ! -d "$fixture_dir" ]]; then
        echo "  fixture missing — building via test-fixtures/build.sh"
        bash "$PACK_ROOT/test-fixtures/build.sh" \
            --name "$fixture_name" --clean \
            >/dev/null 2>&1 \
            || die "fixture build failed: $fixture_name"
    fi
    [[ -d "$fixture_dir" ]] \
        || die "fixture still missing after build: $fixture_dir"

    echo "== running BASELINE (pre-refactor monolith) =="
    _run_impl baseline "$BASELINE_FILE" "$fixture_dir" "$prefix"
    local b_rc; b_rc=$(cat "$RESULTS_DIR/${prefix}.baseline.exit")
    echo "  exit=$b_rc"

    echo "== running ADAPTER (current scripts/migrate-v10-to-v11.sh) =="
    _run_impl adapter "$ADAPTER_FILE" "$fixture_dir" "$prefix"
    local a_rc; a_rc=$(cat "$RESULTS_DIR/${prefix}.adapter.exit")
    echo "  exit=$a_rc"

    local both_succeeded=0
    if [[ "$b_rc" = "0" && "$a_rc" = "0" ]]; then
        both_succeeded=1
    fi

    # ── A5 ────────────────────────────────────────────────────────────────
    echo "== [$fixture_name] A5 — exit code equality =="
    if [[ "$b_rc" = "$a_rc" ]]; then
        pass "[$fixture_name] A5 exit codes match (baseline=$b_rc adapter=$a_rc)"
    else
        fail "[$fixture_name] A5 exit codes differ" "baseline=$b_rc adapter=$a_rc"
    fi

    # ── A1 ────────────────────────────────────────────────────────────────
    echo "== [$fixture_name] A1 — file list equality =="
    if [[ "$both_succeeded" = "1" ]]; then
        if diff -u "$RESULTS_DIR/${prefix}.baseline.filelist" \
                  "$RESULTS_DIR/${prefix}.adapter.filelist" \
                  > "$RESULTS_DIR/${prefix}.A1.diff" 2>&1; then
            pass "[$fixture_name] A1 file lists byte-identical"
        else
            fail "[$fixture_name] A1 file lists differ" \
                "see $RESULTS_DIR/${prefix}.A1.diff"
            head -40 "$RESULTS_DIR/${prefix}.A1.diff" >&2
        fi
    else
        fail "[$fixture_name] A1 skipped — at least one impl failed" \
            "baseline=$b_rc adapter=$a_rc"
    fi

    # ── A2 ────────────────────────────────────────────────────────────────
    echo "== [$fixture_name] A2 — per-file content equality =="
    if [[ "$both_succeeded" = "1" ]]; then
        local a2_misses=0 a2_first_miss="" f
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            if ! cmp -s \
                <(tar -xOf "$RESULTS_DIR/${prefix}.baseline.tar" "$f" 2>/dev/null) \
                <(tar -xOf "$RESULTS_DIR/${prefix}.adapter.tar" "$f" 2>/dev/null)
            then
                a2_misses=$((a2_misses + 1))
                [[ -z "$a2_first_miss" ]] && a2_first_miss="$f"
            fi
        done < "$RESULTS_DIR/${prefix}.baseline.filelist"
        if [[ "$a2_misses" -eq 0 ]]; then
            pass "[$fixture_name] A2 per-file content byte-identical"
        else
            fail "[$fixture_name] A2 $a2_misses file(s) differ" \
                "first divergence: $a2_first_miss"
        fi
    else
        fail "[$fixture_name] A2 skipped — at least one impl failed" \
            "baseline=$b_rc adapter=$a_rc"
    fi

    # ── A3 ────────────────────────────────────────────────────────────────
    echo "== [$fixture_name] A3 — report.md equality (post-redaction) =="
    if [[ "$both_succeeded" = "1" ]]; then
        local b_report="$RESULTS_DIR/${prefix}.baseline.tree/.pack-migrate-v10-to-v11/report.md"
        local a_report="$RESULTS_DIR/${prefix}.adapter.tree/.pack-migrate-v10-to-v11/report.md"
        if [[ ! -f "$b_report" || ! -f "$a_report" ]]; then
            fail "[$fixture_name] A3 report.md missing on at least one side" \
                "baseline=$([[ -f $b_report ]] && echo present || echo absent) adapter=$([[ -f $a_report ]] && echo present || echo absent)"
        else
            _redact "$b_report" "$RESULTS_DIR/${prefix}.baseline.report.redacted"
            _redact "$a_report" "$RESULTS_DIR/${prefix}.adapter.report.redacted"
            if cmp -s "$RESULTS_DIR/${prefix}.baseline.report.redacted" \
                      "$RESULTS_DIR/${prefix}.adapter.report.redacted"; then
                pass "[$fixture_name] A3 report.md byte-identical post-redaction"
            else
                diff -u "$RESULTS_DIR/${prefix}.baseline.report.redacted" \
                        "$RESULTS_DIR/${prefix}.adapter.report.redacted" \
                        > "$RESULTS_DIR/${prefix}.A3.diff" 2>&1
                fail "[$fixture_name] A3 report.md differs post-redaction" \
                    "see $RESULTS_DIR/${prefix}.A3.diff"
                head -40 "$RESULTS_DIR/${prefix}.A3.diff" >&2
            fi
        fi
    else
        fail "[$fixture_name] A3 skipped — at least one impl failed" \
            "baseline=$b_rc adapter=$a_rc"
    fi

    # ── A4 ────────────────────────────────────────────────────────────────
    echo "== [$fixture_name] A4 — stdout equality (post-redaction) =="
    _redact "$RESULTS_DIR/${prefix}.baseline.stdout" \
        "$RESULTS_DIR/${prefix}.baseline.stdout.redacted"
    _redact "$RESULTS_DIR/${prefix}.adapter.stdout" \
        "$RESULTS_DIR/${prefix}.adapter.stdout.redacted"
    if cmp -s "$RESULTS_DIR/${prefix}.baseline.stdout.redacted" \
              "$RESULTS_DIR/${prefix}.adapter.stdout.redacted"; then
        pass "[$fixture_name] A4 stdout byte-identical post-redaction"
    else
        diff -u "$RESULTS_DIR/${prefix}.baseline.stdout.redacted" \
                "$RESULTS_DIR/${prefix}.adapter.stdout.redacted" \
                > "$RESULTS_DIR/${prefix}.A4.diff" 2>&1
        fail "[$fixture_name] A4 stdout differs post-redaction" \
            "see $RESULTS_DIR/${prefix}.A4.diff"
        head -40 "$RESULTS_DIR/${prefix}.A4.diff" >&2
    fi
}

# ── Negative-leg tests (5) ────────────────────────────────────────────────
# Each negative leg sets up a deliberately-broken target and asserts
# BASELINE and ADAPTER produce identical numeric exit codes. PLAN §8.4
# named these five exit codes as the load-bearing failure paths.
#
# Helper: invoke a migrator, capture rc (stdout/stderr suppressed —
# we only assert exit-code parity; PLAN §8.2 axis A5 semantics).
_neg_invoke() {
    local migrator="$1" target="$2" pack_val="$3" v10_tag_val="$4"
    local env_args=()
    [[ -n "$pack_val"     ]] && env_args+=("PACK=$pack_val")
    [[ -n "$v10_tag_val"  ]] && env_args+=("V10_TAG=$v10_tag_val")

    if (( ${#env_args[@]} > 0 )); then
        env -i HOME="$HOME" PATH="$PATH" "${env_args[@]}" \
            bash "$migrator" "$target" >/dev/null 2>&1
    else
        env -i HOME="$HOME" PATH="$PATH" \
            bash "$migrator" "$target" >/dev/null 2>&1
    fi
    return $?
}

# Build a minimal v10-shaped target git repo with clean working tree
# (matches the make_v10_target helper in the BD-085 test suite).
_neg_make_v10_target() {
    local d
    d=$(mktemp -d -t bd119-neg-v10.XXXXXX)
    git init -q "$d"
    git -C "$d" config user.email "harness@example.com"
    git -C "$d" config user.name  "Harness"
    mkdir -p "$d/.claude" "$d/docs/pack" "$d/.codex" "$d/.gemini"
    git -C "$PACK_ROOT" show v10:project-template/CLAUDE.md \
        > "$d/CLAUDE.md" 2>/dev/null
    git -C "$PACK_ROOT" show v10:project-template/AGENTS.md \
        > "$d/AGENTS.md" 2>/dev/null
    git -C "$PACK_ROOT" show v10:project-template/GEMINI.md \
        > "$d/GEMINI.md" 2>/dev/null
    git -C "$d" add -A >/dev/null
    git -C "$d" commit -q -m "v10 initial state" 2>/dev/null
    printf '%s\n' "$d"
}

_run_negative() {
    local label="$1" pack_val="$2" v10_tag_val="$3" target="$4" expected_rc="$5"

    local b_rc a_rc
    _neg_invoke "$BASELINE_FILE" "$target" "$pack_val" "$v10_tag_val"
    b_rc=$?
    _neg_invoke "$ADAPTER_FILE"  "$target" "$pack_val" "$v10_tag_val"
    a_rc=$?

    if [[ "$b_rc" = "$a_rc" ]]; then
        if [[ "$b_rc" = "$expected_rc" ]]; then
            pass "[neg] $label baseline=adapter=$b_rc (expected $expected_rc)"
        else
            # Parity holds but neither matches the documented code.
            # Behavior is preserved (the harness's job) but the shared
            # exit code is unexpected — fail loud so the maintainer
            # knows the documented contract drifted.
            fail "[neg] $label baseline=adapter=$b_rc but expected $expected_rc"
        fi
    else
        fail "[neg] $label exit codes differ" \
            "baseline=$b_rc adapter=$a_rc (expected $expected_rc)"
    fi
}

_run_negatives() {
    echo
    echo "############################################################"
    echo "## negative-leg tests (5 — exit-code parity)"
    echo "############################################################"

    # N1 — EXIT_PACK_INVALID (10): PACK env var unset.
    local n1_target
    n1_target=$(mktemp -d -t bd119-neg-pack.XXXXXX)
    _run_negative "N1 EXIT_PACK_INVALID (PACK unset)" "" "" "$n1_target" 10
    rm -rf "$n1_target"

    # N2 — EXIT_NOT_GIT (11): target is not a git repo.
    local n2_target
    n2_target=$(mktemp -d -t bd119-neg-nogit.XXXXXX)
    _run_negative "N2 EXIT_NOT_GIT (target not a git repo)" \
        "$PACK_ROOT" "" "$n2_target" 11
    rm -rf "$n2_target"

    # N3 — EXIT_DIRTY (12): target has uncommitted changes.
    local n3_target
    n3_target=$(_neg_make_v10_target)
    echo "uncommitted" > "$n3_target/dirty.txt"
    _run_negative "N3 EXIT_DIRTY (uncommitted changes)" \
        "$PACK_ROOT" "" "$n3_target" 12
    rm -rf "$n3_target"

    # N4 — EXIT_NOT_BASELINE (13): target is not at v10. We use a bare
    # git repo with one empty commit and no trinity files; the migrator
    # cannot match it as a v10 baseline.
    local n4_target
    n4_target=$(mktemp -d -t bd119-neg-notv10.XXXXXX)
    git init -q "$n4_target"
    git -C "$n4_target" config user.email "harness@example.com"
    git -C "$n4_target" config user.name  "Harness"
    git -C "$n4_target" commit --allow-empty -q -m "init" 2>/dev/null
    _run_negative "N4 EXIT_NOT_BASELINE (target not at v10)" \
        "$PACK_ROOT" "" "$n4_target" 13
    rm -rf "$n4_target"

    # N5 — EXIT_BASELINE_MISSING (14): override V10_TAG to a tag the
    # pack repo does not have, so the baseline lookup fails.
    local n5_target
    n5_target=$(_neg_make_v10_target)
    _run_negative "N5 EXIT_BASELINE_MISSING (v10 tag missing)" \
        "$PACK_ROOT" "v999-nonexistent-harness" "$n5_target" 14
    rm -rf "$n5_target"
}

# ── Main loop ──────────────────────────────────────────────────────────────
for fx in "${FIXTURES[@]}"; do
    _sweep_fixture "$fx"
done

if [[ "$RUN_NEGATIVES" = "1" ]]; then
    _run_negatives
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
