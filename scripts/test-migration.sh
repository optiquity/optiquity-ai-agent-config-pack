#!/usr/bin/env bash
# scripts/test-migration.sh — end-to-end test runner for the v9.3 → v10
# migration script. Builds synthetic v9.3-shape projects from fixtures
# under maintenance-docs/test-fixtures/, runs scripts/migrate-v9-to-v10.sh
# against each, and asserts the disposition outcomes match expectations.
#
# This is the regression-protection harness for BD-059. Without it,
# changes to migrate-v9-to-v10.sh or its merge helpers can silently
# break customization preservation — exactly the defect that BD-059 was
# filed to fix.
#
# Usage:
#   scripts/test-migration.sh            # run all fixtures
#   scripts/test-migration.sh --quick    # run just the empty fixture
#                                        #   (CI fast path)
#   scripts/test-migration.sh --fixture migration-v9.3-customized
#                                        # run one named fixture
#
# Environment:
#   PACK   Pack repo path. Defaults to the script's parent directory.
#
# Exit codes:
#   0  all selected fixtures pass
#   1  argument or environment error
#   2  one or more fixtures failed

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACK="${PACK:-$PACK_DEFAULT}"

FIXTURES_DIR="$PACK/maintenance-docs/test-fixtures"
BUILD_FIXTURE="$FIXTURES_DIR/build-migration-fixture.sh"
MIGRATE="$PACK/scripts/migrate-v9-to-v10.sh"

QUICK=0
SELECTED=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick)   QUICK=1; shift ;;
        --fixture) SELECTED="$2"; shift 2 ;;
        --help|-h)
            grep '^#' "$0" | head -20
            exit 0
            ;;
        *)
            echo "error: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ ! -d "$FIXTURES_DIR" ]]; then
    echo "error: fixtures dir not found: $FIXTURES_DIR" >&2; exit 1
fi
if [[ ! -x "$BUILD_FIXTURE" ]]; then
    echo "error: build-migration-fixture.sh not executable: $BUILD_FIXTURE" >&2; exit 1
fi
if [[ ! -x "$MIGRATE" ]]; then
    echo "error: migrate-v9-to-v10.sh not executable: $MIGRATE" >&2; exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────────────

passes=0
fails=0
failed_fixtures=()

fail() {
    local fixture="$1" msg="$2"
    echo "  FAIL [$fixture]: $msg"
    fails=$((fails + 1))
    failed_fixtures+=("$fixture")
}
pass() { echo "  pass [$1]: $2"; passes=$((passes + 1)); }

assert_zero_count() {
    local fixture="$1" label="$2" expected="$3" actual="$4"
    if [[ "$expected" == "$actual" ]]; then
        pass "$fixture" "$label (count=$actual)"
    else
        fail "$fixture" "$label — expected $expected, got $actual"
    fi
}

assert_grep() {
    local fixture="$1" label="$2" pattern="$3" file="$4"
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        pass "$fixture" "$label"
    else
        fail "$fixture" "$label — pattern '$pattern' not found in $file"
    fi
}

assert_no_match() {
    local fixture="$1" label="$2" pattern="$3" file="$4"
    if ! grep -qE "$pattern" "$file" 2>/dev/null; then
        pass "$fixture" "$label"
    else
        fail "$fixture" "$label — pattern '$pattern' unexpectedly found in $file"
    fi
}

assert_file_exists() {
    local fixture="$1" label="$2" path="$3"
    if [[ -f "$path" ]]; then pass "$fixture" "$label"
    else fail "$fixture" "$label — missing: $path"
    fi
}

assert_file_absent() {
    local fixture="$1" label="$2" path="$3"
    if [[ ! -e "$path" ]]; then pass "$fixture" "$label"
    else fail "$fixture" "$label — unexpectedly present: $path"
    fi
}

# Run the migration script in a target dir and capture exit status. Inputs
# the developer-prompt for "Resume / Start fresh / Abort" decision in case
# of a partial-run state — we always answer "f" (start fresh) because the
# fixtures are pristine builds.
run_migration() {
    local target="$1"
    cd "$target"
    # Migration's S0 prompts on existing sentinels; provide "f" to start fresh.
    # Redirect outputs OUTSIDE the target tree — writing into the target
    # before S0 runs would dirty the working tree.
    local logdir="$target/../logs"
    mkdir -p "$logdir"
    PACK="$PACK" "$MIGRATE" <<< "f" > "$logdir/migration.stdout" 2> "$logdir/migration.stderr"
    return $?
}

# Returns 0 if `dispositions.tsv` row count matching disposition $2 is
# at LEAST $3.
count_dispositions() {
    local tsv="$1" disp="$2"
    awk -F'\t' -v d="$disp" 'NR>1 && $1 == d { c++ } END { print c+0 }' "$tsv"
}

# ── Per-fixture test runs ──────────────────────────────────────────────────

run_fixture_empty() {
    local fixture="migration-v9.3-empty"
    echo "── $fixture ──"
    local tmp; tmp=$(mktemp -d -t test-migration.XXXXXX)
    local target="$tmp/project"
    mkdir -p "$target"

    PACK="$PACK" "$BUILD_FIXTURE" "$FIXTURES_DIR/$fixture" "$target" \
        > "$tmp/build.log" 2>&1 || {
        fail "$fixture" "build-migration-fixture.sh failed"
        cat "$tmp/build.log"
        rm -rf "$tmp"
        return
    }

    cd "$target"
    git init -q
    git add -A
    git -c user.email=test@local -c user.name=Test commit -q -m "v9.3 baseline (fixture-built)"
    git checkout -q -b migration-v9-to-v10

    if run_migration "$target"; then
        pass "$fixture" "migration completed (exit 0)"
    else
        fail "$fixture" "migration exited non-zero"
        cat "$tmp/logs/migration.stderr" 2>/dev/null | head -20
        rm -rf "$tmp"
        return
    fi

    local report="$target/.pack-migration-backup/v9.3-to-v10.0/report.md"
    local tsv="$target/.pack-migration-backup/v9.3-to-v10.0/dispositions.tsv"

    assert_file_exists "$fixture" "report.md present" "$report"
    assert_file_exists "$fixture" "dispositions.tsv present" "$tsv"

    # No reconciliation rows (empty fixture has no project customization).
    local recon_count
    recon_count=$(count_dispositions "$tsv" "customization-detected-needs-reconciliation")
    assert_zero_count "$fixture" "no reconciliation rows" "0" "$recon_count"

    # No .v9-customized sidecars.
    local sidecar_count
    sidecar_count=$(find "$target" -name '*.v9-customized' \
        -not -path "*/.pack-migration-backup/*" \
        -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    assert_zero_count "$fixture" "no sidecars created" "0" "$sidecar_count"

    # Report contains "no reconciliations" indicator (text varies; check section is empty-ish).
    assert_grep "$fixture" "report disposition summary present" \
        "Disposition summary:.*reconciliations needed" "$report"

    # PROMPT-TEMPLATES.md retired (v10 design).
    assert_file_absent "$fixture" "PROMPT-TEMPLATES.md retired" "$target/docs/pack/PROMPT-TEMPLATES.md"

    # INSTALL-PROCEDURES.md installed (D5 file class).
    assert_file_exists "$fixture" "INSTALL-PROCEDURES.md installed" \
        "$target/docs/pack/INSTALL-PROCEDURES.md"

    # docs/pack/prompts/ directory exists with 10 per-agent files.
    local prompt_count
    prompt_count=$(find "$target/docs/pack/prompts" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    if (( prompt_count >= 10 )); then
        pass "$fixture" "docs/pack/prompts/ has ≥10 per-agent files"
    else
        fail "$fixture" "docs/pack/prompts/ has $prompt_count files (expected ≥10)"
    fi

    rm -rf "$tmp"
}

run_fixture_customized() {
    local fixture="migration-v9.3-customized"
    echo "── $fixture ──"
    local tmp; tmp=$(mktemp -d -t test-migration.XXXXXX)
    local target="$tmp/project"
    mkdir -p "$target"

    PACK="$PACK" "$BUILD_FIXTURE" "$FIXTURES_DIR/$fixture" "$target" \
        > "$tmp/build.log" 2>&1 || {
        fail "$fixture" "build-migration-fixture.sh failed"
        rm -rf "$tmp"
        return
    }

    cd "$target"
    git init -q
    git add -A
    git -c user.email=test@local -c user.name=Test commit -q -m "v9.3 baseline + fixture customizations"
    git checkout -q -b migration-v9-to-v10

    if run_migration "$target"; then
        pass "$fixture" "migration completed (exit 0)"
    else
        fail "$fixture" "migration exited non-zero"
        cat "$tmp/logs/migration.stderr" 2>/dev/null | head -20
        rm -rf "$tmp"
        return
    fi

    local report="$target/.pack-migration-backup/v9.3-to-v10.0/report.md"
    local tsv="$target/.pack-migration-backup/v9.3-to-v10.0/dispositions.tsv"

    # Trinity customizations should produce reconciliation sidecars.
    if [[ -f "$FIXTURES_DIR/$fixture/overlay/CLAUDE.md" ]]; then
        assert_file_exists "$fixture" "CLAUDE.md.v9-customized sidecar" \
            "$target/CLAUDE.md.v9-customized"
        # The sidecar should preserve the fixture marker from the overlay.
        assert_grep "$fixture" "CLAUDE.md.v9-customized preserves fixture marker" \
            "FIXTURE-MARKER-CLAUDE" "$target/CLAUDE.md.v9-customized"
    fi

    # Structured-config customizations should be merged or sidecared.
    if [[ -f "$FIXTURES_DIR/$fixture/overlay/.claude/settings.json" ]]; then
        # XCODE_SCHEME from overlay should survive in the merged file
        # (Pattern S key-merge preserves project edits).
        assert_grep "$fixture" "settings.json XCODE_SCHEME preserved" \
            "FIXTURE-SCHEME-MARKER" "$target/.claude/settings.json"
    fi

    # Project-only file should be preserved untouched.
    if [[ -f "$FIXTURES_DIR/$fixture/overlay/scripts/x-fixture.sh" ]]; then
        assert_file_exists "$fixture" "scripts/x-fixture.sh preserved" \
            "$target/scripts/x-fixture.sh"
    fi

    # Report should have at least one reconciliation row.
    local recon_count
    recon_count=$(count_dispositions "$tsv" "customization-detected-needs-reconciliation")
    if (( recon_count > 0 )); then
        pass "$fixture" "report has $recon_count reconciliation row(s)"
    else
        fail "$fixture" "report has 0 reconciliation rows (expected ≥1)"
    fi

    # Report's disposition summary line is present.
    assert_grep "$fixture" "report disposition summary present" \
        "Disposition summary:" "$report"

    # The structural-truthfulness invariant: "customization: none" must NOT appear in the report.
    assert_no_match "$fixture" "report does not falsely claim 'customization: none'" \
        "customization: none" "$report"

    rm -rf "$tmp"
}

run_fixture_marker_convention() {
    local fixture="migration-v9.3-marker-convention"
    echo "── $fixture ──"
    local tmp; tmp=$(mktemp -d -t test-migration.XXXXXX)
    local target="$tmp/project"
    mkdir -p "$target"

    PACK="$PACK" "$BUILD_FIXTURE" "$FIXTURES_DIR/$fixture" "$target" \
        > "$tmp/build.log" 2>&1 || {
        fail "$fixture" "build-migration-fixture.sh failed"
        rm -rf "$tmp"
        return
    }

    cd "$target"
    git init -q
    git add -A
    git -c user.email=test@local -c user.name=Test commit -q -m "v9.3 baseline + marker-convention overlay"
    git checkout -q -b migration-v9-to-v10

    if run_migration "$target"; then
        pass "$fixture" "migration completed (exit 0)"
    else
        fail "$fixture" "migration exited non-zero"
        rm -rf "$tmp"
        return
    fi

    # Marker-convention region should be preserved verbatim through the splice.
    if [[ -f "$FIXTURES_DIR/$fixture/overlay/docs/pack/PLATFORM-SKILLS.md" ]]; then
        assert_grep "$fixture" "PLATFORM-SKILLS.md preserves marker-convention row" \
            "FIXTURE-MARKER-CUSTOM-AGENT" "$target/docs/pack/PLATFORM-SKILLS.md"
    fi

    rm -rf "$tmp"
}

# ── Main dispatch ──────────────────────────────────────────────────────────

if [[ -n "$SELECTED" ]]; then
    case "$SELECTED" in
        migration-v9.3-empty)              run_fixture_empty ;;
        migration-v9.3-customized)         run_fixture_customized ;;
        migration-v9.3-marker-convention)  run_fixture_marker_convention ;;
        *) echo "error: unknown fixture: $SELECTED" >&2; exit 1 ;;
    esac
elif [[ "$QUICK" -eq 1 ]]; then
    run_fixture_empty
else
    run_fixture_empty
    run_fixture_customized
    run_fixture_marker_convention
fi

# ── Summary ────────────────────────────────────────────────────────────────

echo
echo "tests: $((passes + fails)) total, $passes passed, $fails failed"
if (( fails > 0 )); then
    echo "failed fixtures: ${failed_fixtures[*]}"
    exit 2
fi
exit 0
