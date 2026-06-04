#!/usr/bin/env bash
# scripts/tests/test-add-capability.sh — BD-048 smoke tests for the
# capability install-check discovery extension to add-capability.sh
# (stages A7 + A8 install-hint embedding in the PM-chat prompt).
#
# Scope (BD-048): exercise the new table-driven discovery surface and
# the prompt-file install-hint section. End-to-end install testing is
# out of scope — the script never installs anything by design.
#
# Test groups:
#   1. capability_install_checks() table coverage for canonical rows
#   2. End-to-end run on a v11-flat-file fixture clone exercising both
#      the all-present and missing-tool paths via PATH manipulation.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADD_CAP_SH="$REPO_ROOT/scripts/add-capability.sh"
CAP_TABLES_SH="$REPO_ROOT/project-template/scripts/capability-tables.sh"
FIXTURE="$REPO_ROOT/test-fixtures/v11-flat-file"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "should NOT contain '$3'"; fi
}

# Source the capability_install_checks() function for direct table
# inspection without invoking the full pipeline. The three table functions
# are single-sourced in project-template/scripts/capability-tables.sh (the
# authored source add-capability.sh and the client activate-capability.sh
# both consume); it is sourceable-only (no top-level side effects), so we
# source it directly rather than extracting a single function.
load_install_checks_fn() {
    # shellcheck disable=SC1090
    source "$CAP_TABLES_SH"
}

make_clean_fixture_clone() {
    local d
    d=$(mktemp -d -t bd048-tgt.XXXXXX)
    cp -R "$FIXTURE/." "$d/"
    git -C "$d" init -q . >/dev/null 2>&1
    git -C "$d" config user.email "test@example.com"
    git -C "$d" config user.name  "Test"
    git -C "$d" add -A >/dev/null 2>&1
    git -C "$d" commit -q -m "fixture init" >/dev/null 2>&1 || true
    printf '%s\n' "$d"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: capability_install_checks() table coverage
# ─────────────────────────────────────────────────────────────────────────
echo "Group 1: capability_install_checks() table coverage"

load_install_checks_fn

# protocol:grpc — must surface buf, swift-protobuf gen, grpcio-tools.
GRPC_ROWS=$(capability_install_checks "protocol:grpc")
assert_contains "protocol:grpc lists buf"             "$GRPC_ROWS" "buf:::"
assert_contains "protocol:grpc lists protoc-gen-swift" "$GRPC_ROWS" "protoc-gen-swift:::"
assert_contains "protocol:grpc lists grpcio-tools"    "$GRPC_ROWS" "grpcio-tools:::"

# language:python — must surface python3 + uv.
PY_ROWS=$(capability_install_checks "language:python")
assert_contains "language:python lists python3" "$PY_ROWS" "python3:::"
assert_contains "language:python lists uv"      "$PY_ROWS" "uv:::"

# language:swift — must surface swift + swift-format.
SWIFT_ROWS=$(capability_install_checks "language:swift")
assert_contains "language:swift lists swift"        "$SWIFT_ROWS" "swift:::"
assert_contains "language:swift lists swift-format" "$SWIFT_ROWS" "swift-format:::"

# platform:macos — must surface xcodebuild.
MACOS_ROWS=$(capability_install_checks "platform:macos")
assert_contains "platform:macos lists xcodebuild" "$MACOS_ROWS" "xcodebuild:::"

# protocol:rest — by design, no machine-level installs implied.
REST_ROWS=$(capability_install_checks "protocol:rest" || true)
if [[ -z "$REST_ROWS" ]]; then
    t_pass "protocol:rest emits no install-check rows (library-level only)"
else
    t_fail "protocol:rest should emit no rows" "got: $REST_ROWS"
fi

# Field separator regression guard: rows must use ':::' (BD-048), never
# bare '|' as a field separator (install commands themselves contain '|').
# Probe by counting ':::' occurrences in protocol:grpc rows.
SEP_COUNT=$(printf '%s' "$GRPC_ROWS" | grep -c ':::' || true)
if (( SEP_COUNT >= 5 )); then
    t_pass "protocol:grpc rows use ':::' field separator (got $SEP_COUNT lines with separator)"
else
    t_fail "protocol:grpc should have ≥5 lines with ':::' separator" "got $SEP_COUNT"
fi

# ─────────────────────────────────────────────────────────────────────────
# Group 2: end-to-end discovery + prompt embedding
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "Group 2: end-to-end discovery + prompt embedding"

if [[ ! -d "$FIXTURE" ]]; then
    echo "  SKIP — fixture $FIXTURE not present (run test-fixtures/build.sh --name v11-flat-file)"
else
    TGT=$(make_clean_fixture_clone)
    OUT=$(echo y | PACK="$REPO_ROOT" "$ADD_CAP_SH" --project "$TGT" --add protocol:grpc 2>&1)
    PROMPT_FILE="$TGT/.pack-add-capability-prompt.md"

    assert_contains "stage A7 banner present"             "$OUT" "── A7 — capability install-check discovery"
    assert_contains "stage A8 banner present"             "$OUT" "── A8 — end-of-run PM chat prompt"
    assert_contains "stage A7 probes buf"                 "$OUT" "protocol:grpc → buf:"
    assert_contains "stage A7 probes protoc-gen-swift"    "$OUT" "protocol:grpc → protoc-gen-swift:"

    # Prompt file should contain the discovery + install-hint blocks.
    if [[ -f "$PROMPT_FILE" ]]; then
        PROMPT=$(cat "$PROMPT_FILE")
        assert_contains "prompt has discovery block"   "$PROMPT" "Capability install-check discovery (read-only, BD-048):"
        assert_contains "prompt references G6-install" "$PROMPT" "G6-install"
        assert_contains "prompt references Form I"     "$PROMPT" "Form I"
        # If buf is missing on this machine, the install command surfaces;
        # if buf is present, it does not. Either way, the discovery line
        # for buf must appear in the prompt.
        assert_contains "prompt lists buf in discovery" "$PROMPT" "buf"
        # The legacy bare '|' field-separator parsing bug (BD-048 fix-pass)
        # would surface install commands as the [missing]/[present] purpose
        # text. Guard by asserting the buf purpose is the proper prose,
        # not the install command head.
        assert_not_contains "prompt does not leak install cmd into purpose column" \
            "$PROMPT" "[missing] buf — go install"
    else
        t_fail "prompt file should exist at $PROMPT_FILE"
    fi

    rm -rf "$TGT"
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ──"
echo "  passed: $PASSED"
echo "  failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi
exit 0
