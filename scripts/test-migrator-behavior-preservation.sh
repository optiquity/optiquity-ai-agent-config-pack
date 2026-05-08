#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-behavior-preservation.sh — BD-119 C-5 harness.
#
# Behavior-preservation gate for the BD-119 framework refactor of
# `scripts/migrate-v10-to-v11.sh`. Per PLAN-BD-119.md §8 (the equivalence
# contract) and ARCHITECTURE-BD-119.md §10 (behavior-preservation
# rationale), this harness pins five axes across two independent runs of
# the migrator and asserts byte-equivalence (modulo two narrowly scoped
# redactions). It is the mandatory gate before C-6 cutover; without it,
# C-6's refactor of the monolith into a framework adapter cannot be
# proven equivalent to the pre-refactor monolith.
#
# Two runs are compared:
#
#   BASELINE — the pre-refactor monolith pinned at SHA d7b3f07. Sourced
#              from scripts/.bd119-pre-refactor-monolith.sh.snapshot
#              when present (gitignored, branch-local, see C-1 report
#              POQ-4); recovered via `git show d7b3f07:...` when absent.
#
#   ADAPTER  — whatever scripts/migrate-v10-to-v11.sh currently is on
#              this worktree. At C-5 (this commit) it is still the
#              same monolith, so equivalence is trivially true. At C-6
#              it will be the framework adapter (~120 lines) calling
#              `migrator_run`, and the harness must remain green.
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
#     fixture-name defaults to v10-realistic-ot. The named fixture must
#     exist under test-fixtures/<name>/ — re-build with
#     `bash test-fixtures/build.sh --name <name> --clean` if missing.
#
# Exit 0 on all five axes matching across all subtests; exit 1 otherwise
# with a per-axis breakdown. The summary line follows the convention
# established by sibling test scripts:
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

FIXTURE_NAME="${1:-v10-realistic-ot}"
FIXTURE_DIR="$PACK_ROOT/test-fixtures/$FIXTURE_NAME"

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
echo "  fixture:        $FIXTURE_DIR"
echo "  results dir:    $RESULTS_DIR"

# Materialize the fixture if absent. The fixture's own state is verified
# against test-fixtures/manifest.txt (the build script does this when
# --clean is passed). For the harness's purpose we only need the fixture
# tree to exist; manifest verification is the build script's concern.
if [[ ! -d "$FIXTURE_DIR" ]]; then
    echo "  fixture missing — building via test-fixtures/build.sh"
    bash "$PACK_ROOT/test-fixtures/build.sh" --name "$FIXTURE_NAME" --clean \
        >/dev/null 2>&1 \
        || die "fixture build failed; rerun manually: bash test-fixtures/build.sh --name $FIXTURE_NAME --clean"
fi
[[ -d "$FIXTURE_DIR" ]] || die "fixture still missing after build: $FIXTURE_DIR"

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
    local impl="$1" migrator="$2"
    local clone="$RESULTS_DIR/$impl.tree"
    rm -rf "$clone"
    mkdir -p "$clone"

    # Copy the fixture content. The fixture is itself a git repo (built
    # by test-fixtures/build.sh) so we can `cp -R` and the .git/
    # subtree comes along — needed because the migrator requires a
    # clean git working tree (S0 preflight).
    cp -R "$FIXTURE_DIR/." "$clone/"

    PACK="$PACK_ROOT" \
    bash "$migrator" "$clone" \
        > "$RESULTS_DIR/$impl.stdout" 2> "$RESULTS_DIR/$impl.stderr"
    local rc=$?
    printf '%d\n' "$rc" > "$RESULTS_DIR/$impl.exit"

    # File list: every regular file post-migration, excluding .git/ and
    # the .pack-migrate-* state + backup directories. PLAN §8.3 spells
    # this exclusion out verbatim: the state dir contains diagnostic
    # files (three-way diff side-files, dispositions.tsv, etc.) whose
    # content embeds tmp paths and run timestamps that vary between
    # any two invocations of the migrator — even of the *same* monolith.
    # report.md (also under the state dir) is checked separately by axis
    # A3 with redactions applied. Use LC_ALL=C sort for deterministic
    # ordering across BSD vs GNU find.
    (
        cd "$clone" && \
        find . -type f \
            \! -path './.git/*' \
            \! -path './.git' \
            \! -path './.pack-migrate-*/*' \
            \! -path './.pack-migrate-*' \
            -print 2>/dev/null \
            | LC_ALL=C sort > "$RESULTS_DIR/$impl.filelist"
    )

    # Tar archive of the post-migration tree (excluding .git/ + every
    # .pack-migrate-* dir) so axis A2 can `cmp` per-file content without
    # re-walking the filesystem twice. BSD + GNU tar both accept
    # --exclude. Pattern matches both .pack-migrate-v10-to-v11/ and
    # .pack-migrate-v10-to-v11-backup/ in one expression.
    tar -C "$clone" \
        --exclude='./.git' \
        --exclude='./.pack-migrate-*' \
        -cf "$RESULTS_DIR/$impl.tar" . 2>/dev/null

    return 0
}

# ── 1. Run BASELINE + ADAPTER ──────────────────────────────────────────────
echo "== running BASELINE (pre-refactor monolith) =="
_run_impl baseline "$BASELINE_FILE"
b_rc=$(cat "$RESULTS_DIR/baseline.exit")
echo "  exit=$b_rc"

echo "== running ADAPTER (current scripts/migrate-v10-to-v11.sh) =="
_run_impl adapter "$ADAPTER_FILE"
a_rc=$(cat "$RESULTS_DIR/adapter.exit")
echo "  exit=$a_rc"

# Both must exit 0 for axes A1..A4 to be meaningfully comparable. If
# both are non-zero AND identical, A5 still passes (negative-leg
# behavior preservation), but A1..A3 are not asserted because the tree
# may be in an undefined intermediate state. Document this and treat
# the case as a partial run.
both_succeeded=0
if [[ "$b_rc" = "0" && "$a_rc" = "0" ]]; then
    both_succeeded=1
fi

# ── A5. Exit code equality ─────────────────────────────────────────────────
echo "== A5 — exit code equality =="
if [[ "$b_rc" = "$a_rc" ]]; then
    pass "A5 exit codes match (baseline=$b_rc adapter=$a_rc)"
else
    fail "A5 exit codes differ" "baseline=$b_rc adapter=$a_rc"
fi

# ── A1. File list equality ─────────────────────────────────────────────────
echo "== A1 — file list equality =="
if [[ "$both_succeeded" = "1" ]]; then
    if diff -u "$RESULTS_DIR/baseline.filelist" \
              "$RESULTS_DIR/adapter.filelist" \
              > "$RESULTS_DIR/A1.diff" 2>&1; then
        pass "A1 file lists byte-identical"
    else
        fail "A1 file lists differ" \
            "see $RESULTS_DIR/A1.diff (BD119_KEEP_RESULTS=1 to retain)"
        head -40 "$RESULTS_DIR/A1.diff" >&2
    fi
else
    fail "A1 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A2. Per-file content equality ──────────────────────────────────────────
echo "== A2 — per-file content equality =="
if [[ "$both_succeeded" = "1" ]]; then
    a2_misses=0
    a2_first_miss=""
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        # The filelist already excludes .pack-migrate-* (where report.md
        # and the diagnostic three-way diffs live), so no per-file
        # carve-out is needed here. report.md is asserted separately by
        # axis A3 with the allowed redactions applied.
        # Use tar -xO (POSIX, BSD + GNU) to extract one file each side.
        # cmp is POSIX. Both are bash-3.2 safe.
        if ! cmp -s \
            <(tar -xOf "$RESULTS_DIR/baseline.tar" "$f" 2>/dev/null) \
            <(tar -xOf "$RESULTS_DIR/adapter.tar" "$f" 2>/dev/null)
        then
            a2_misses=$((a2_misses + 1))
            [[ -z "$a2_first_miss" ]] && a2_first_miss="$f"
        fi
    done < "$RESULTS_DIR/baseline.filelist"
    if [[ "$a2_misses" -eq 0 ]]; then
        pass "A2 per-file content byte-identical across all files"
    else
        fail "A2 $a2_misses file(s) differ" \
            "first divergence: $a2_first_miss"
    fi
else
    fail "A2 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A3. report.md equality (post-redaction) ────────────────────────────────
echo "== A3 — report.md equality (post-redaction) =="
if [[ "$both_succeeded" = "1" ]]; then
    b_report="$RESULTS_DIR/baseline.tree/.pack-migrate-v10-to-v11/report.md"
    a_report="$RESULTS_DIR/adapter.tree/.pack-migrate-v10-to-v11/report.md"
    if [[ ! -f "$b_report" || ! -f "$a_report" ]]; then
        fail "A3 report.md missing on at least one side" \
            "baseline=$([[ -f $b_report ]] && echo present || echo absent) adapter=$([[ -f $a_report ]] && echo present || echo absent)"
    else
        _redact "$b_report" "$RESULTS_DIR/baseline.report.redacted"
        _redact "$a_report" "$RESULTS_DIR/adapter.report.redacted"
        if cmp -s "$RESULTS_DIR/baseline.report.redacted" \
                  "$RESULTS_DIR/adapter.report.redacted"; then
            pass "A3 report.md byte-identical post-redaction"
        else
            diff -u "$RESULTS_DIR/baseline.report.redacted" \
                    "$RESULTS_DIR/adapter.report.redacted" \
                    > "$RESULTS_DIR/A3.diff" 2>&1
            fail "A3 report.md differs post-redaction" \
                "see $RESULTS_DIR/A3.diff"
            head -40 "$RESULTS_DIR/A3.diff" >&2
        fi
    fi
else
    fail "A3 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A4. Stdout equality (post-redaction) ───────────────────────────────────
echo "== A4 — stdout equality (post-redaction) =="
_redact "$RESULTS_DIR/baseline.stdout" "$RESULTS_DIR/baseline.stdout.redacted"
_redact "$RESULTS_DIR/adapter.stdout"  "$RESULTS_DIR/adapter.stdout.redacted"
if cmp -s "$RESULTS_DIR/baseline.stdout.redacted" \
          "$RESULTS_DIR/adapter.stdout.redacted"; then
    pass "A4 stdout byte-identical post-redaction"
else
    diff -u "$RESULTS_DIR/baseline.stdout.redacted" \
            "$RESULTS_DIR/adapter.stdout.redacted" \
            > "$RESULTS_DIR/A4.diff" 2>&1
    fail "A4 stdout differs post-redaction" \
        "see $RESULTS_DIR/A4.diff"
    head -40 "$RESULTS_DIR/A4.diff" >&2
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
