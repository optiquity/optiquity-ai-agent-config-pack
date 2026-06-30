#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-64.sh — synthetic tests for Check 64
# (no dangling MCP/config .example deliverable refs — BD-231).
#
# Check 64 is the BD-231 referential-integrity gate (DESIGN-BD-231 §4): for the
# MCP/config `.example` family — `.mcp.json.example` (Claude),
# `.agents/mcp_config.json.example` (Antigravity), `.codex/config.toml.example`
# (Codex) — every cite on the DELIVERABLE surface (pack-root README.md layout
# block, project-template/**, supporting-docs/**) MUST resolve to an existing
# file under project-template/. A cite whose target is absent is a dangling
# reference -> FAIL. This closes the Check-43 leading-dot-dotfile blind spot
# (Check 43's bare-ref regex requires `[A-Za-z]` first, so a leading-dot
# `.mcp.json.example` token is never matched).
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it builds a throwaway deliverable tree in a /tmp REPO_ROOT). It
# lives under scripts/tests/ and auto-wires into CI via the disk glob
# (ci-shard-plan.py parse_wired_tests() / validate-pack Check 42 / Check 60).
# Per "Test infra is self-provisioned": every PASS/FAIL case is built in a /tmp
# scratch tree; the REAL project-template/ tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 64 symbol registration + count invariant.
#   Group 1: Real-state-at-HEAD PASS (the real tree has the .example file, so
#            every deliverable cite resolves).
#   Group 2: Synthetic PASS/FAIL against a /tmp REPO_ROOT (monkeypatch
#            mod.REPO_ROOT):
#            - PASS: a deliverable doc cites `.mcp.json.example` AND the target
#              exists under project-template/ -> 0 failures.
#            - FAIL (the load-bearing case): the SAME deliverable doc cites
#              `.mcp.json.example` but the target is ABSENT -> >=1 failure naming
#              the file:line + the dangling token + remediation. Proves the gate
#              is NOT a false-green.
#   Group 3: End-to-end validate-pack.py --only-check 64 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-64.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 64 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 64 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_dangling_example_deliverable_refs'):
    print('FAIL_MISSING check_dangling_example_deliverable_refs'); sys.exit(1)
# Check 64 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's invariant — proves the count is
# consistent with the registered set; the constant tracks every check add).
# The count is asserted DYNAMICALLY against CHECK_REGISTRY_EXPECTED_COUNT (never
# a hardcoded literal — a literal breaks on every check addition, e.g. BD-206
# Check 73 bumped the count 70 -> 71; the dynamic form tracks the constant).
nums = [t[0] for t in mod._build_check_registry()]
if 64 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH got', len(mod._build_check_registry()),
          'expected', mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
print('OK')
" > /tmp/vp-check64-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check64-import.out; then
    t_pass "validate-pack.py imports + Check 64 symbol registered + count invariant holds (dynamic == CHECK_REGISTRY_EXPECTED_COUNT)"
else
    t_fail "validate-pack.py import / Check 64 registration / count invariant failed" \
        "$(cat /tmp/vp-check64-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real tree has the .example file)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_dangling_example_deliverable_refs()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 64 expected 0 failures, got {len(new)}: {cap}")
if "every cite resolves" not in cap:
    failures.append(f"real-state PASS message missing 'every cite resolves': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 64 PASSes (the real tree has .mcp.json.example; every cite resolves)" ;;
    *) t_fail "real-state Check 64 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp REPO_ROOT PASS/FAIL tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp REPO_ROOT PASS/FAIL tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W12 wave-invariant). Check 64's body now lives in
    validate_checks.examples and resolves every walked path via
    examples.REPO_ROOT; a facade-only patch would NOT bite. Setting it on every
    loaded validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

# Helper: build a throwaway deliverable tree in a /tmp REPO_ROOT. A
# supporting-docs/ doc ALWAYS cites `.mcp.json.example`; the example target is
# created under project-template/ ONLY when `target_present` is True. Then run
# Check 64 against it by monkeypatching mod.REPO_ROOT (the check resolves every
# walked path via REPO_ROOT). Returns (failures_count, captured_output). Never
# touches the real tree.
def run_check(target_present):
    tmpdir = tempfile.mkdtemp(prefix="vp-check64-")
    root = pathlib.Path(tmpdir)
    # A deliverable doc that CITES the Claude MCP example (the dangling-prone
    # cite). Lives under supporting-docs/ (an INCLUDE tree).
    (root / "supporting-docs").mkdir(parents=True)
    (root / "supporting-docs" / "SETUP.md").write_text(
        "# Setup\n\nCopy the template:\n\n    cp .mcp.json.example .mcp.json\n"
    )
    # The project-template/ tree always exists; the cited target is present
    # ONLY in the PASS case.
    (root / "project-template").mkdir(parents=True)
    if target_present:
        (root / "project-template" / ".mcp.json.example").write_text("{}\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dangling_example_deliverable_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — the cited `.mcp.json.example` target EXISTS -> 0 failures.
fail_count, captured = run_check(target_present=True)
if fail_count != 0:
    failures.append(f"T1 (PASS — target present) expected 0 failures, got {fail_count}: {captured}")
if "every cite resolves" not in captured:
    failures.append(f"T1 PASS message missing 'every cite resolves': {captured}")

# T2: FAIL (load-bearing) — the SAME doc cites `.mcp.json.example` but the
# target is ABSENT -> >=1 failure naming file:line + token + remediation.
# This proves Check 64 is NOT a false-green: a dangling deliverable ref FAILS
# the gate.
fail_count, captured = run_check(target_present=False)
if fail_count < 1:
    failures.append(f"T2 (FAIL — target absent) expected >=1 failure, got {fail_count}: {captured}")
if "supporting-docs/SETUP.md:" not in captured:
    failures.append(f"T2 FAIL must name the citing file:line (supporting-docs/SETUP.md:N): {captured}")
if ".mcp.json.example" not in captured:
    failures.append(f"T2 FAIL must name the dangling token .mcp.json.example: {captured}")
if "does NOT exist" not in captured:
    failures.append(f"T2 FAIL must say the target does NOT exist: {captured}")
if "restore" not in captured or "drop the cite" not in captured:
    failures.append(f"T2 FAIL must carry the restore-or-drop remediation: {captured}")

# T3: EXCLUDE bound — a dangling cite in an EXCLUDE-prefixed surface (history /
# pack-only / fixtures) must NOT trip the gate (it is out of the deliverable
# scope). Build a backlog/ doc citing the absent example; expect 0 failures.
def run_check_excluded():
    tmpdir = tempfile.mkdtemp(prefix="vp-check64-ex-")
    root = pathlib.Path(tmpdir)
    (root / "project-template").mkdir(parents=True)   # target ABSENT
    (root / "backlog").mkdir(parents=True)
    (root / "backlog" / "BD-001.md").write_text("Historical: see .mcp.json.example\n")
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dangling_example_deliverable_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

ex_count, ex_cap = run_check_excluded()
if ex_count != 0:
    failures.append(f"T3 (EXCLUDE bound — backlog/ cite) expected 0 failures, got {ex_count}: {ex_cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic tests (T1: target present PASS; T2: target absent FAILs naming file:line+token+remediation; T3: EXCLUDE-prefixed cite does not trip)" ;;
    *) t_fail "Synthetic Check 64 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 64 > /tmp/vp-check64-e2e.out 2>&1; then
    if grep -q "Check 64: no dangling MCP/config .example deliverable refs" /tmp/vp-check64-e2e.out \
       && grep -q "every cite resolves" /tmp/vp-check64-e2e.out; then
        t_pass "validate-pack.py --only-check 64 exits 0; Check 64 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 64 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check64-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check64-e2e.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
