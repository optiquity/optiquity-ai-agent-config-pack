#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-42.sh — synthetic fixture tests
# for BD-184 Check 42 (CI workflow wires all per-check test files).
#
# Check 42 closes the "missing test wiring" gap class that surfaced 5
# times across the BD-175 emergency batch (BD-179 FIX-1: 3 tests;
# BD-183 FIX-1: 1 test; BD-183 FIX-2: 1 test) — each caught by reviewer
# attention, now caught mechanically.
#
# Mirrors the test-validate-pack-check-41.sh harness pattern: each test
# stages a synthetic REPO_ROOT with controlled scripts/tests/ + workflow
# yml content, invokes Check 42 against the tmp tree, and asserts PASS
# / FAIL as expected.
#
# Coverage:
#   Group 0: Module import + Check 42 symbol registration
#   Group 1: Real-state-at-HEAD PASS verification (self-referential
#            closure: check-42 test + check-42 wiring present together)
#   Group 2: Synthetic PASS/FAIL tests covering:
#            - PASS path (every disk test has a wiring line)
#            - FAIL path: single-form (`check-NN.sh`) unwired
#            - FAIL path: bundled-form (`checks-NN-NN-NN.sh`) unwired
#            - FAIL path: multiple unwired tests of mixed naming forms
#            - PASS path: extra workflow invocations without disk file
#              (reverse-direction not gated; documented in Check 42
#              docstring)
#            - Lenient skip when scripts/tests/ absent
#            - Lenient skip when .github/workflows/validate-pack.yml absent
#            - Naming-form coverage: glob and grep BOTH catch `check-`
#              AND `checks-` shapes
#   Group 3: End-to-end validate-pack.py exit-status on HEAD; Check 42
#            output detected with correct counts.
#
# Usage: bash scripts/tests/test-validate-pack-check-42.sh

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
# Group 0: Module import + Check 42 symbol registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 42 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_ci_workflow_wires_per_check_tests']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check42-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check42-import.out; then
    t_pass "validate-pack.py imports + Check 42 symbol registered"
else
    t_fail "validate-pack.py import or Check 42 symbol registration failed" \
        "$(cat /tmp/vp-check42-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS verification (self-referential)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS verification ===\n"

# Use a quoted heredoc (`<<'EOF'`) so bash performs ZERO substitution on
# the Python body. Inject REPO_ROOT and VALIDATE paths via environment
# variables.
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, re, pathlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Enumerate real disk tests under scripts/tests/test-validate-pack-check*.sh.
tests_dir = pathlib.Path(REPO_ROOT_PY) / "scripts" / "tests"
disk_tests = sorted(p.name for p in tests_dir.glob("test-validate-pack-check*.sh"))

# Sanity: real state should have >=8 test files today (the BD-184 commit
# adds the 9th; pre-BD-184 commits had 8). After BD-184 lands, expect
# >=9. The lower bound 8 is generous and forward-compatible.
if len(disk_tests) < 8:
    failures.append(f"real scripts/tests/ has only {len(disk_tests)} per-check test files (expected >=8)")

# Spot-check: both naming forms (check- single AND checks- bundled)
# must be present on disk at HEAD.
has_single_form = any("check-" in name and "checks-" not in name for name in disk_tests)
has_bundled_form = any("checks-" in name for name in disk_tests)
if not has_single_form:
    failures.append(f"real scripts/tests/ has no `check-NN.sh` single-form test (expected at least one; got {disk_tests})")
if not has_bundled_form:
    failures.append(f"real scripts/tests/ has no `checks-NN-NN-NN.sh` bundled-form test (expected at least one; got {disk_tests})")

# Sanity: BD-184's own test must be present on disk (the self-
# referential closure requires it).
if "test-validate-pack-check-42.sh" not in disk_tests:
    failures.append("test-validate-pack-check-42.sh not present on disk — BD-184 self-referential closure broken (this test should have been created by the BD-184 implementation)")

# Now invoke Check 42 against real REPO_ROOT and assert PASS.
import io, contextlib
saved_failures = list(mod.failures)
mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_ci_workflow_wires_per_check_tests()
    new_failures = list(mod.failures)
    captured = buf.getvalue()
finally:
    mod.failures.clear()
    mod.failures.extend(saved_failures)

if len(new_failures) != 0:
    failures.append(f"real-state Check 42 PASS expected 0 failures, got {len(new_failures)}: {captured}")
if "zero unwired tests" not in captured:
    failures.append(f"real-state Check 42 PASS message missing 'zero unwired tests': {captured}")
if "CI workflow wiring is complete" not in captured:
    failures.append(f"real-state Check 42 PASS message missing closure phrase: {captured}")

# Self-referential closure check: at HEAD post-BD-184, check-42 itself
# must appear in the workflow yml.
workflow_path = pathlib.Path(REPO_ROOT_PY) / ".github" / "workflows" / "validate-pack.yml"
workflow_text = workflow_path.read_text()
if "bash scripts/tests/test-validate-pack-check-42.sh" not in workflow_text:
    failures.append("test-validate-pack-check-42.sh has no `bash scripts/tests/...` wiring in .github/workflows/validate-pack.yml — BD-184 self-referential closure broken (this test wiring should have been added by the BD-184 implementation)")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 42 PASSes + self-referential closure holds (test-42 file + wiring both present)" ;;
    *) t_fail "real-state Check 42 / self-referential closure check failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic REPO_ROOT PASS/FAIL tests
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic REPO_ROOT PASS/FAIL tests ===\n"

# Use a quoted heredoc to defend against backtick command-substitution
# in assertion strings.
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Helper: build a synthetic REPO_ROOT with controlled
# scripts/tests/test-validate-pack-check*.sh files + a controlled
# .github/workflows/validate-pack.yml. Returns (failures_count,
# captured_output) from a Check 42 invocation against the tmp root.
#
# `test_filenames`: list of base filenames to stage under scripts/tests/.
# `wired_filenames`: list of base filenames whose `bash scripts/tests/<f>`
#   lines are present in the synthetic workflow yml.
# `omit_workflow`: when True, do not create the workflow yml file (lenient
#   skip test).
# `omit_tests_dir`: when True, do not create scripts/tests/ (lenient
#   skip test).
def run_check(test_filenames, wired_filenames,
              omit_workflow=False, omit_tests_dir=False):
    tmpdir = tempfile.mkdtemp(prefix="vp-check42-")
    root = pathlib.Path(tmpdir)

    if not omit_tests_dir:
        tests_dir = root / "scripts" / "tests"
        tests_dir.mkdir(parents=True)
        for name in test_filenames:
            (tests_dir / name).write_text("#!/usr/bin/env bash\n# stub\nexit 0\n")

    if not omit_workflow:
        workflow_dir = root / ".github" / "workflows"
        workflow_dir.mkdir(parents=True)
        # Build a minimal yml. The check looks for
        # `bash scripts/tests/<filename>` substrings; full yml syntax is
        # NOT required (the check uses a regex, not a yml parser).
        lines = [
            "name: Validate Pack (synthetic)",
            "on: push",
            "jobs:",
            "  tests:",
            "    runs-on: ubuntu-latest",
            "    steps:",
        ]
        for name in wired_filenames:
            lines.append(f"      - name: synthetic step for {name}")
            lines.append(f"        if: always()")
            lines.append(f"        run: bash scripts/tests/{name}")
        (workflow_dir / "validate-pack.yml").write_text("\n".join(lines) + "\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_ci_workflow_wires_per_check_tests()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS path — every disk test has a wiring line; both single + bundled
# naming forms present. Verifies the glob/grep correctness for the canonical
# good state.
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-42.sh",
        "test-validate-pack-checks-32-33-34.sh",
    ],
    wired_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-42.sh",
        "test-validate-pack-checks-32-33-34.sh",
    ],
)
if fail_count != 0:
    failures.append(f"T1 (PASS — all wired, mixed naming forms) expected 0 failures, got {fail_count}: {captured}")
if "zero unwired tests" not in captured:
    failures.append(f"T1 PASS message missing 'zero unwired tests': {captured}")
if "3 per-check test file" not in captured:
    failures.append(f"T1 PASS message missing '3 per-check test file' count: {captured}")
if "3 workflow invocation" not in captured:
    failures.append(f"T1 PASS message missing '3 workflow invocation' count: {captured}")

# T2: FAIL path — single-form test (`check-NN.sh`) unwired. Verifies the
# check catches the BD-179 FIX-1 / BD-183 FIX-1 / BD-183 FIX-2 gap class
# for the single-check naming form.
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-42.sh",
    ],
    wired_filenames=[
        "test-validate-pack-check-16.sh",
        # check-42 wiring omitted intentionally
    ],
)
if fail_count != 1:
    failures.append(f"T2 (FAIL — single-form check-42 unwired) expected 1 failure, got {fail_count}: {captured}")
if "test-validate-pack-check-42.sh" not in captured:
    failures.append(f"T2 FAIL message must name the unwired filename test-validate-pack-check-42.sh: {captured}")
if "per-check test file exists on disk but has NO corresponding" not in captured:
    failures.append(f"T2 FAIL message must include the canonical 'exists on disk but has NO corresponding' phrasing: {captured}")
if "validate-pack.yml" not in captured:
    failures.append(f"T2 FAIL message must reference .github/workflows/validate-pack.yml: {captured}")

# T3: FAIL path — bundled-form test (`checks-NN-NN-NN.sh`) unwired.
# Verifies the check catches the gap class for the BUNDLED naming form
# (BD-179 FIX-1 wired `test-validate-pack-checks-36-37-38.sh`, the only
# bundled-form occurrence to date).
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-checks-36-37-38.sh",
    ],
    wired_filenames=[
        "test-validate-pack-check-16.sh",
        # checks-36-37-38 wiring omitted intentionally
    ],
)
if fail_count != 1:
    failures.append(f"T3 (FAIL — bundled-form checks-36-37-38 unwired) expected 1 failure, got {fail_count}: {captured}")
if "test-validate-pack-checks-36-37-38.sh" not in captured:
    failures.append(f"T3 FAIL message must name the unwired bundled filename test-validate-pack-checks-36-37-38.sh: {captured}")

# T4: FAIL path — MULTIPLE unwired tests of mixed naming forms.
# Empirical precedent: BD-179 FIX-1 wired 3 unwired tests in one fix
# commit (1 bundled + 2 single). Check 42 must surface ALL unwired
# filenames, not just the first.
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-39.sh",
        "test-validate-pack-check-40.sh",
        "test-validate-pack-checks-36-37-38.sh",
    ],
    wired_filenames=[
        "test-validate-pack-check-16.sh",
        # 3 unwired: check-39, check-40, checks-36-37-38
    ],
)
if fail_count != 3:
    failures.append(f"T4 (FAIL — 3 unwired mixed forms) expected 3 failures, got {fail_count}: {captured}")
for missing in ("test-validate-pack-check-39.sh",
                "test-validate-pack-check-40.sh",
                "test-validate-pack-checks-36-37-38.sh"):
    if missing not in captured:
        failures.append(f"T4 FAIL message must name all unwired filenames; missing {missing}: {captured}")

# T5: PASS path — extra workflow invocations WITHOUT a disk file are
# tolerated (reverse-direction is NOT gated per Check 42 docstring).
# Documents the intentional asymmetry: a stale workflow line pointing at
# a deleted test would fail CI loudly at runtime, so there's no silent-
# pass risk. The check is one-directional (disk → workflow).
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-check-16.sh",
    ],
    wired_filenames=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-99.sh",  # phantom — no disk file
    ],
)
if fail_count != 0:
    failures.append(f"T5 (PASS — extra workflow invocation without disk file) expected 0 failures, got {fail_count}: {captured}")
if "zero unwired tests" not in captured:
    failures.append(f"T5 PASS message missing 'zero unwired tests': {captured}")

# T6: SKIP path — scripts/tests/ absent (lenient mode). Check 42 must
# skip with a notice; no failure.
fail_count, captured = run_check(
    test_filenames=[],
    wired_filenames=[],
    omit_tests_dir=True,
)
if fail_count != 0:
    failures.append(f"T6 (SKIP — scripts/tests/ absent) expected 0 failures, got {fail_count}: {captured}")
if "scripts/tests/ absent" not in captured:
    failures.append(f"T6 SKIP message must say 'scripts/tests/ absent': {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T6 SKIP message must say 'skipping (lenient)': {captured}")

# T7: SKIP path — .github/workflows/validate-pack.yml absent (lenient
# mode). Check 42 must skip with a notice; no failure.
fail_count, captured = run_check(
    test_filenames=["test-validate-pack-check-16.sh"],
    wired_filenames=[],
    omit_workflow=True,
)
if fail_count != 0:
    failures.append(f"T7 (SKIP — workflow yml absent) expected 0 failures, got {fail_count}: {captured}")
if ".github/workflows/validate-pack.yml absent" not in captured:
    failures.append(f"T7 SKIP message must reference workflow yml absence: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T7 SKIP message must say 'skipping (lenient)': {captured}")

# T8: regression guard — verify the glob `test-validate-pack-check*.sh`
# (no trailing dash) catches BOTH `check-NN.sh` AND `checks-NN-NN-NN.sh`
# shapes. Build a synth tree with only the bundled-form test, wire ONLY
# the single-form, and assert FAIL on the bundled form — this proves the
# disk-enumeration step DOES see the bundled file. (If the glob had been
# `test-validate-pack-check-*.sh` with the dash, the bundled file would
# be invisible to the disk-walk and T8 would silently PASS — wrong
# answer.)
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-checks-32-33-34.sh",  # bundled-only on disk
    ],
    wired_filenames=[
        # nothing wired
    ],
)
if fail_count != 1:
    failures.append(f"T8 (regression guard: glob catches bundled form) expected 1 failure, got {fail_count}: {captured}")
if "test-validate-pack-checks-32-33-34.sh" not in captured:
    failures.append(f"T8 regression guard must name the bundled-form filename: {captured}")

# T9: regression guard — verify the workflow grep
# `bash scripts/tests/test-validate-pack-check[^\s]+\.sh` catches BOTH
# naming forms in the workflow yml. Build a synth tree where the disk
# test is bundled-form AND the workflow ALSO has the bundled-form
# wiring; assert PASS (no false-positive FAIL from the grep missing the
# bundled-form workflow line).
fail_count, captured = run_check(
    test_filenames=[
        "test-validate-pack-checks-32-33-34.sh",
    ],
    wired_filenames=[
        "test-validate-pack-checks-32-33-34.sh",
    ],
)
if fail_count != 0:
    failures.append(f"T9 (regression guard: workflow grep catches bundled form) expected 0 failures, got {fail_count}: {captured}")
if "zero unwired tests" not in captured:
    failures.append(f"T9 PASS message missing 'zero unwired tests': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T9 covering single + bundled naming forms, multi-unwired surfacing, lenient skips, and glob/grep regression guards)" ;;
    *) t_fail "Synthetic Check 42 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 42 > /tmp/vp-check42-e2e.out 2>&1; then
    if grep -q "Check 42: CI workflow wires all per-check test files" /tmp/vp-check42-e2e.out \
       && grep -qE "Check 42 — [0-9]+ per-check test file" /tmp/vp-check42-e2e.out \
       && grep -q "CI workflow wiring is complete" /tmp/vp-check42-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 42 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 42 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check42-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check42-e2e.out)"
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
