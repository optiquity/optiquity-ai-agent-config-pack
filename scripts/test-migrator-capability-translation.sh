#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-capability-translation.sh — BD-144 golden-snapshot
# tests for the v10→v11 migrator capability-token translation stage
# (S5c) introduced in scripts/migrate-v10-to-v11.sh.
#
# Builds a synthetic v10-shaped fixture in $TMPDIR with:
#   - CLAUDE.md / AGENTS.md / GEMINI.md whose first body line is
#     `capabilities: language:python, role:python-server, role:apple-app`
#   - the minimal v10 surface markers required for
#     detect_target_pack_version() to classify it as v10 (so the
#     migrator's preflight does not refuse the run).
#
# After invoking the BD-144 stage helper directly (so the test does not
# depend on a fully-prepared v10-realistic-ot fixture or the BD-095
# dry-run dance), asserts:
#   T1.a — each trinity file's `capabilities:` line contains all four
#          tokens (language:python, role:python-server,
#          deployment:linux-container, deployment:apple) in order-tolerant
#          form.
#   T1.b — neither legacy `role:apple-app` token survives anywhere on
#          the line.
#   T1.c — the advisory file at
#          $STATE_DIR/capability-rename.advisory exists and lists six
#          line-touches (3 trinity files × 2 edits each).
#   T2   — re-running the stage on the already-translated fixture is
#          a no-op (idempotency): no new advisory entries appear, no
#          file content changes.
#
# Usage:    bash scripts/test-migrator-capability-translation.sh
# Exit 0 on all pass; exit 1 on any failure.
#
# Per BD-144 spec / PLAN-SKILL-DIMENSIONS.md §7.1 step 9.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d -t test-bd144-translate.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { printf '  pass: %s\n' "$1"; passes=$((passes + 1)); }
fail() {
    printf '  FAIL: %s\n' "$1" >&2
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2" >&2
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3" >&2
    fails=$((fails + 1))
}

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}

# ── Fixture ────────────────────────────────────────────────────────────────

TARGET="$FIXTURE_BASE/project"
mkdir -p "$TARGET" "$TARGET/.claude" "$TARGET/docs/pack"
# Minimal v10 surface marker for detect_target_pack_version (signal 4).
echo "# PROMPT-TEMPLATES.md" > "$TARGET/docs/pack/PROMPT-TEMPLATES.md"

# Trinity files. Each has a `capabilities:` line containing both legacy
# tokens. The line is the first body line so the test asserts cleanly
# without grepping through prose.
for tf in CLAUDE.md AGENTS.md GEMINI.md; do
    cat > "$TARGET/$tf" <<'EOF'
# Trinity file (synthetic v10 fixture for BD-144 test)
capabilities: language:python, role:python-server, role:apple-app

Body content placeholder.
EOF
done

# Migrator state dir — the helper writes the advisory under this path.
STATE_DIR="$TARGET/.pack-migrate-v10-to-v11"
mkdir -p "$STATE_DIR"

# ── Drive the stage helper directly ────────────────────────────────────────
#
# Sourcing the migrator script as-is would trigger its mode-dispatch logic.
# Instead we emulate the framework's contract: source migrator-core for
# the say/info/fail_stage helpers, set the two _MIGRATOR_* vars the
# helper reads, and invoke just the new translation function. This is
# the same pattern the BD-035 S5b helper would be tested under and keeps
# the test focused on the BD-144 translation behavior alone.

export PACK="$PACK_ROOT"
# Adapter contract for migrator-core preflight (only the variables the
# helper actually reads at runtime are needed for this isolation test).
MIGRATOR_FROM_VERSION="v10"
MIGRATOR_TO_VERSION="v11"
MIGRATOR_BASELINE_TAG="v10"
MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"

# shellcheck source=lib/migrator-core.sh disable=SC1091
. "$PACK_ROOT/scripts/lib/migrator-core.sh"

# Source the adapter — it defines _v10_to_v11_translate_capability_tokens().
# Sourcing executes the BD-095 mode dispatch at the bottom of the file
# only if invoked as a script; sourcing without args lands in the
# `case "$_mode" in ... "")` arm which calls migrate_v10_to_v11_apply_run.
# To avoid that, we invoke a sub-shell trick: parse only the helper
# function definition by extracting a small region with sed and eval'ing
# it. Cleaner: source under conditions that make the dispatch a no-op.
#
# We choose the cleanest path: copy the helper function out of the file
# via awk into a temp script, source that, and call. This isolates the
# unit-under-test from the dispatch machinery without touching the
# adapter's structure.
HELPER_TMP="$(mktemp -t bd144-helper.XXXXXX.sh)"
awk '
    /^_v10_to_v11_translate_capability_tokens\(\) \{/ { capture = 1 }
    capture { print }
    capture && /^\}/ { capture = 0 }
' "$PACK_ROOT/scripts/migrate-v10-to-v11.sh" > "$HELPER_TMP"

# Sanity-check the extraction grabbed the function.
if ! grep -q '^_v10_to_v11_translate_capability_tokens()' "$HELPER_TMP"; then
    printf 'FATAL: could not extract translation helper from migrate-v10-to-v11.sh\n' >&2
    rm -f "$HELPER_TMP"
    exit 2
fi
# shellcheck source=/dev/null
. "$HELPER_TMP"
rm -f "$HELPER_TMP"

# Set the framework-state vars the helper reads.
_MIGRATOR_TARGET="$TARGET"
_MIGRATOR_STATE_DIR="$STATE_DIR"

# ── T1: first run translates ─────────────────────────────────────────────

echo "== T1: first run translates capability tokens =="
_v10_to_v11_translate_capability_tokens >/dev/null

ADVISORY="$STATE_DIR/capability-rename.advisory"

# T1.a — every trinity capabilities line contains the four expected tokens
for tf in CLAUDE.md AGENTS.md GEMINI.md; do
    line=$(grep -m1 '^capabilities:' "$TARGET/$tf" || true)
    has_python=0; has_pyserver=0; has_lxc=0; has_apple_d5=0
    [[ "$line" == *"language:python"* ]]            && has_python=1
    [[ "$line" == *"role:python-server"* ]]         && has_pyserver=1
    [[ "$line" == *"deployment:linux-container"* ]] && has_lxc=1
    [[ "$line" == *"deployment:apple"* ]]           && has_apple_d5=1
    if (( has_python == 1 && has_pyserver == 1 \
       && has_lxc == 1    && has_apple_d5 == 1 )); then
        pass "T1.a $tf — capabilities line contains all four expected tokens (order-tolerant)"
    else
        fail "T1.a $tf — missing token(s)" \
             "language:python ∧ role:python-server ∧ deployment:linux-container ∧ deployment:apple" \
             "$line"
    fi
done

# T1.b — no surviving legacy `role:apple-app` token on the capabilities line
for tf in CLAUDE.md AGENTS.md GEMINI.md; do
    line=$(grep -m1 '^capabilities:' "$TARGET/$tf" || true)
    # Token-boundary anchored match (mirror of the helper's apple_pat).
    if printf '%s' "$line" | grep -qE '(^|[^A-Za-z0-9_:-])role:apple-app($|[^A-Za-z0-9_:-])'; then
        fail "T1.b $tf — legacy role:apple-app token still present" \
             "(no role:apple-app)" "$line"
    else
        pass "T1.b $tf — legacy role:apple-app token gone"
    fi
done

# T1.c — advisory file exists and records exactly 6 line-touches
if [[ -f "$ADVISORY" ]]; then
    pass "T1.c advisory file written: $ADVISORY"
    # Every recorded touch starts with `<file>:<line>: ` followed by a
    # `kind` keyword (rename | append). Count those header lines.
    touch_count=$(grep -cE '^[A-Za-z][A-Za-z.]*:[0-9]+: (rename|append)$' "$ADVISORY" || true)
    assert_eq "T1.c advisory records 6 line-touches (3 files × 2 edits)" \
        "6" "$touch_count"
else
    fail "T1.c advisory file missing" "$ADVISORY exists" "(absent)"
fi

# Capture state for the idempotency check.
ADVISORY_AFTER_T1=$(cat "$ADVISORY" 2>/dev/null)
declare -a TRINITY_AFTER_T1
TRINITY_AFTER_T1[0]=$(cat "$TARGET/CLAUDE.md")
TRINITY_AFTER_T1[1]=$(cat "$TARGET/AGENTS.md")
TRINITY_AFTER_T1[2]=$(cat "$TARGET/GEMINI.md")

# ── T2: re-run is a no-op (idempotency) ─────────────────────────────────

echo "== T2: re-run is a no-op (idempotency) =="

# Pre-truncate the advisory so the helper rewrites it from scratch on
# any new touch. This makes the idempotency check unambiguous: if the
# helper records anything, the advisory will be non-empty.
rm -f "$ADVISORY"

_v10_to_v11_translate_capability_tokens >/dev/null

# T2.a — advisory is NOT recreated (no new touches)
if [[ -f "$ADVISORY" ]]; then
    fail "T2.a re-run wrote a new advisory (not idempotent)" \
         "advisory absent" \
         "advisory present with $(wc -l <"$ADVISORY" | tr -d '[:space:]') lines"
else
    pass "T2.a advisory not recreated — re-run produced zero new touches"
fi

# T2.b — trinity files unchanged byte-for-byte
i=0
for tf in CLAUDE.md AGENTS.md GEMINI.md; do
    actual=$(cat "$TARGET/$tf")
    if [[ "$actual" == "${TRINITY_AFTER_T1[$i]}" ]]; then
        pass "T2.b $tf unchanged after re-run"
    else
        fail "T2.b $tf changed after re-run" \
             "(byte-identical to T1 post-state)" "(diverged)"
    fi
    i=$((i + 1))
done

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
