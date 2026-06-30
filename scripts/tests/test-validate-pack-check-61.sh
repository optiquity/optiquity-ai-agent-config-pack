#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-61.sh — synthetic fixture tests for
# Check 61 (fixture-dependent tests live under scripts/tests/fixture-dependent/).
#
# BD-219 dynamic-autoregen redesign backstop. Fixture cohesion is LOCATION-based:
# a test that depends on a BUILT fixture (test-fixtures/<NAME>/, a gitignored
# build artifact) MUST live under scripts/tests/fixture-dependent/, so the
# partitioner pins it into the single fixture-building shard. Check 61 catches a
# fixture-dependent test saved in the WRONG directory: a KEEP test whose body
# references a test-fixtures/<NAME> path (NAME ∈ build.sh FIXTURE_NAMES) but is
# NOT under fixture-dependent/ → FAIL with a "move it" remediation.
#
# This test file itself is NOT fixture-dependent (it references no built
# fixture); it lives under scripts/tests/ and auto-wires via the disk glob —
# incidentally proving zero-touch case (a) (a new test runs without any manual
# wiring step).
#
# Coverage:
#   Group 0: Module import + Check 61 symbol registration
#   Group 1: Real-state-at-HEAD PASS (zero misplaced fixture tests)
#   Group 2: Synthetic PASS/FAIL tests:
#            - FAIL: a fixture-referencing test in scripts/tests/ (misplaced)
#            - PASS: the SAME test under fixture-dependent/ (correctly placed)
#            - PASS: a non-fixture test anywhere (no FIXTURE_NAMES reference)
#            - PASS: a benign mention of test-fixtures/manifest.txt (not a
#                    FIXTURE_NAMES fixture → no false positive)
#            - Lenient SKIP when build.sh FIXTURE_NAMES is absent
#   Group 3: End-to-end validate-pack.py --only-check 61 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-61.sh

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
# Group 0: Module import + Check 61 symbol registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 61 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_fixture_dependent_location', '_load_fixture_names']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check61-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check61-import.out; then
    t_pass "validate-pack.py imports + Check 61 symbol registered"
else
    t_fail "validate-pack.py import or Check 61 symbol registration failed" \
        "$(cat /tmp/vp-check61-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (zero misplaced fixture tests)
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
        mod.check_fixture_dependent_location()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 61 expected 0 failures, got {len(new)}: {cap}")
if "zero misplaced fixture tests" not in cap:
    failures.append(f"real-state PASS message missing 'zero misplaced fixture tests': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 61 PASSes (every fixture-referencing KEEP test is under fixture-dependent/)" ;;
    *) t_fail "real-state Check 61 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic REPO_ROOT PASS/FAIL tests
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic REPO_ROOT PASS/FAIL tests ===\n"

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
    submodule (BD-256 W11 wave-invariant). Check 61's body now lives in
    validate_checks.fixtures and reads fixtures.REPO_ROOT; a facade-only patch
    would NOT bite. Setting it on every loaded validate_checks.* reaches the
    read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

# Helper: build a synthetic REPO_ROOT with a build.sh carrying a FIXTURE_NAMES
# array, controlled test scripts, and an allowlist. Returns (failures_count,
# captured_output) from a Check 61 invocation against the tmp tree.
#
# `tests_files`: dict {basename: body} staged under scripts/tests/.
# `fxdep_files`: dict {basename: body} staged under
#                scripts/tests/fixture-dependent/.
# `omit_fixture_names`: when True, write a build.sh WITHOUT a FIXTURE_NAMES
#                       array (lenient SKIP).
def run_check(tests_files=None, fxdep_files=None, omit_fixture_names=False):
    tests_files = tests_files or {}
    fxdep_files = fxdep_files or {}
    tmpdir = tempfile.mkdtemp(prefix="vp-check61-")
    root = pathlib.Path(tmpdir)

    scripts_dir = root / "scripts"
    tests_dir = scripts_dir / "tests"
    tests_dir.mkdir(parents=True)
    for name, body in tests_files.items():
        (tests_dir / name).write_text(body)
    if fxdep_files:
        fxdep_dir = tests_dir / "fixture-dependent"
        fxdep_dir.mkdir(parents=True)
        for name, body in fxdep_files.items():
            (fxdep_dir / name).write_text(body)

    (scripts_dir / "ci-test-wiring-allowlist.txt").write_text("# synthetic\n")

    tf_dir = root / "test-fixtures"
    tf_dir.mkdir(parents=True)
    if omit_fixture_names:
        (tf_dir / "build.sh").write_text("#!/usr/bin/env bash\n# no FIXTURE_NAMES here\nexit 0\n")
    else:
        (tf_dir / "build.sh").write_text(
            '#!/usr/bin/env bash\n'
            'readonly FIXTURE_NAMES=(\n'
            '    "v10-realistic-ot"\n'
            '    "v11-flat-file"\n'
            ')\n'
        )

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_fixture_dependent_location()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# Build the fixture-reference path from pieces at runtime so the literal
# `test-fixtures/<FIXTURE_NAME>` token NEVER appears verbatim in THIS file's
# source — otherwise Check 61's own real-tree scan (Group 1 / Group 3) would
# flag this encoding test as a misplaced fixture test (a self-reference false
# positive). The synthetic stub written into the tmp tree DOES carry the literal.
_TF = "test-" + "fixtures"
FIXTURE_BODY = (
    "#!/usr/bin/env bash\n"
    "# reads a built fixture\n"
    'FIXTURE="$REPO_ROOT/' + _TF + '/v11-flat-file"\n'
    "exit 0\n"
)
PLAIN_BODY = "#!/usr/bin/env bash\n# no fixture reference\nexit 0\n"

# T1: FAIL — a fixture-referencing test sits in scripts/tests/ (misplaced).
fail_count, captured = run_check(
    tests_files={"test-misplaced-fx.sh": FIXTURE_BODY,
                 "test-plain.sh": PLAIN_BODY},
)
if fail_count != 1:
    failures.append(f"T1 (FAIL — misplaced fixture test) expected 1 failure, got {fail_count}: {captured}")
if "scripts/tests/test-misplaced-fx.sh" not in captured:
    failures.append(f"T1 FAIL must name the misplaced path: {captured}")
if "move it to" not in captured:
    failures.append(f"T1 FAIL must give the 'move it to ...' remediation: {captured}")

# T2: PASS — the SAME fixture-referencing test under fixture-dependent/.
fail_count, captured = run_check(
    tests_files={"test-plain.sh": PLAIN_BODY},
    fxdep_files={"test-correctly-placed-fx.sh": FIXTURE_BODY},
)
if fail_count != 0:
    failures.append(f"T2 (PASS — correctly placed) expected 0 failures, got {fail_count}: {captured}")
if "zero misplaced fixture tests" not in captured:
    failures.append(f"T2 PASS message missing 'zero misplaced fixture tests': {captured}")

# T3: PASS — a non-fixture test anywhere (no FIXTURE_NAMES reference).
fail_count, captured = run_check(
    tests_files={"test-plain-a.sh": PLAIN_BODY, "test-plain-b.sh": PLAIN_BODY},
)
if fail_count != 0:
    failures.append(f"T3 (PASS — no fixture refs) expected 0 failures, got {fail_count}: {captured}")

# T4: PASS — a benign mention of test-fixtures/manifest.txt (NOT a
# FIXTURE_NAMES fixture → no false positive).
fail_count, captured = run_check(
    tests_files={"test-manifest-mention.sh":
                 "#!/usr/bin/env bash\n# touches test-fixtures/manifest.txt\nexit 0\n"},
)
if fail_count != 0:
    failures.append(f"T4 (PASS — manifest.txt mention, no FP) expected 0 failures, got {fail_count}: {captured}")

# T5: SKIP — build.sh has no FIXTURE_NAMES (no signal → lenient skip).
fail_count, captured = run_check(
    tests_files={"test-misplaced-fx.sh": FIXTURE_BODY},
    omit_fixture_names=True,
)
if fail_count != 0:
    failures.append(f"T5 (SKIP — no FIXTURE_NAMES) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T5 SKIP message must say 'skipping (lenient)': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T5: misplaced FAIL, correctly-placed PASS, non-fixture PASS, manifest.txt no-FP, lenient skip)" ;;
    *) t_fail "Synthetic Check 61 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 61 > /tmp/vp-check61-e2e.out 2>&1; then
    if grep -q "Check 61: fixture-dependent tests live under fixture-dependent/" /tmp/vp-check61-e2e.out \
       && grep -q "zero misplaced fixture tests" /tmp/vp-check61-e2e.out; then
        t_pass "validate-pack.py --only-check 61 exits 0; Check 61 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 61 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check61-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check61-e2e.out)"
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
