#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-docs-client-deferred-shipped-docs.sh —
# client-gate DEFERRED-axis parity over the two shipped operating docs.
#
# BD-250 re-classified supporting-docs/METHODOLOGY.md +
# supporting-docs/INSTALL-PROCEDURES.md REFERENCE→OPERATING and extended the
# pack-side guards (validate-pack Check 65/67) to them. Those two files INSTALL
# into a client project's docs/pack/ (scripts/init-project.sh install map), so
# the client operating-doc gate (project-template/scripts/validate-docs.sh, its
# DEFERRED axis) must also clear their shipped content via the client allowlist
# (project-template/scripts/.docs-gate-allowlist.txt). This test machine-pins
# that parity: the REAL shipped bytes + the REAL client gate + the REAL client
# allowlist must agree (0 deferred-axis violation outside the allowlist), and
# the gate must still BITE an uncovered deferred-feature line.
#
# This is BD-250 option 2C: a per-check TEST exercising the REAL shipped files;
# it adds NO production check and NO CHECK_REGISTRY count bump. Pattern mirrors
# scripts/tests/test-validate-pack-check-67.sh (self-provisioned /tmp tree;
# cleanup on every exit path; PASS/FAIL counters; non-zero exit on any failure).
#
# Usage:    bash scripts/tests/test-validate-docs-client-deferred-shipped-docs.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# The REAL shipped sources + the REAL client gate + the REAL client allowlist.
SRC_METH="$PACK_ROOT/supporting-docs/METHODOLOGY.md"
SRC_INST="$PACK_ROOT/supporting-docs/INSTALL-PROCEDURES.md"
GATE="$PACK_ROOT/project-template/scripts/validate-docs.sh"
ALLOWLIST="$PACK_ROOT/project-template/scripts/.docs-gate-allowlist.txt"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-vdocs-client-deferred.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    %s\n' "$2"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

# Guard: the inputs must exist (a misconfigured tree should fail loud, not
# silently pass).
for f in "$SRC_METH" "$SRC_INST" "$GATE" "$ALLOWLIST"; do
    if [[ ! -f "$f" ]]; then
        fail "required input present" "missing: $f"
    fi
done

# stage_tree <root> — stage the installed client layout: the 2 shipped docs at
# docs/pack/<name> (exactly as the install map copies them) + the client gate +
# the client allowlist under scripts/. validate-docs.sh resolves ALLOWLIST from
# its own SCRIPT_DIR and ROOT_DIR from its parent, so staging both under
# <root>/scripts/ and running the gate gates the docs/pack/*.md IN set.
stage_tree() {
    local root="$1"
    mkdir -p "$root/docs/pack" "$root/scripts"
    cp "$SRC_METH" "$root/docs/pack/METHODOLOGY.md"
    cp "$SRC_INST" "$root/docs/pack/INSTALL-PROCEDURES.md"
    cp "$GATE" "$root/scripts/validate-docs.sh"
    cp "$ALLOWLIST" "$root/scripts/.docs-gate-allowlist.txt"
    chmod +x "$root/scripts/validate-docs.sh"
}

# deferred_hits <gate-output> — count the [deferred]-axis violation lines only.
# BD-250's surface is the DEFERRED axis over the 2 shipped docs; this test is
# SCOPED to that axis. The other axes (history / bloat / dangling) + the
# conformance leg are NOT in scope here: an isolated 2-file synthetic tree
# legitimately trips DANGLING (refs to sibling docs/scripts present only in a
# full install), so a whole-rc assertion would be brittle and out-of-scope.
# Those axes are covered by their own gates (validate-docs --self-test, the
# pack-side dangling/conformance checks).
deferred_hits() {
    printf '%s\n' "$1" | grep -c '\[deferred\]'
}

echo "== client DEFERRED-axis parity over the shipped operating docs =="

# ── PASS leg: the REAL shipped content has 0 DEFERRED-axis hit outside the
#    allowlist (the client allowlist exactly covers the 11 shipped KEEPs) ─────
PASS_ROOT="$FIXTURE_BASE/pass"
stage_tree "$PASS_ROOT"
pass_out="$(bash "$PASS_ROOT/scripts/validate-docs.sh" 2>&1)"
pass_def="$(deferred_hits "$pass_out")"
if [[ "$pass_def" -eq 0 ]]; then
    pass "shipped METHODOLOGY + INSTALL-PROCEDURES: 0 deferred-axis violation outside the client allowlist (the 11 KEEPs are exactly covered)"
else
    fail "shipped docs should have 0 deferred-axis violation outside the allowlist" \
        "got $pass_def deferred hit(s): $(printf '%s' "$pass_out" | grep '\[deferred\]' | head -5)"
fi

# ── FAIL leg (the teeth): an uncovered deferred-feature line produces a
#    [deferred] violation (the gate still bites the BD-250 axis) ──────────────
FAIL_ROOT="$FIXTURE_BASE/fail"
stage_tree "$FAIL_ROOT"
# Append a synthetic, uncovered deferred-feature advertisement to one staged doc.
printf '\nThe widget skill is deferred to a future release.\n' \
    >> "$FAIL_ROOT/docs/pack/METHODOLOGY.md"
fail_out="$(bash "$FAIL_ROOT/scripts/validate-docs.sh" 2>&1)"
fail_def="$(deferred_hits "$fail_out")"
if [[ "$fail_def" -ge 1 ]] \
   && printf '%s' "$fail_out" | grep -q 'widget skill is deferred'; then
    pass "an uncovered deferred-feature line produces a [deferred] violation (the gate still bites the BD-250 axis)"
else
    fail "injected uncovered deferred line should produce a [deferred] violation" \
        "got $fail_def deferred hit(s); out: $(printf '%s' "$fail_out" | grep '\[deferred\]' | head -5)"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
