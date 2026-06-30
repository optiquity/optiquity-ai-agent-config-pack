#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-42.sh — synthetic fixture tests
# for Check 42 (CI test-wiring allowlist is valid + bounded).
#
# BD-184 introduced Check 42 (a disk test with no CI invocation FAILs).
# BD-219 C3 generalized it to full set-equality over a STATIC matrix. The
# BD-219 dynamic-autoregen redesign RE-SCOPES Check 42: the CI `tests` matrix
# is now disk-derived at run time (the `plan` job's `--emit-matrix`), so
# `wired_set == disk_KEEP_set` by construction and the old equality is a
# tautology with no failure mode. Check 42's surviving charge is:
#
#   (1) Allowlist VALIDITY (measure-then-bound): every allowlist entry
#       (a) EXISTS on disk and (b) matches the disk-glob shape
#       (scripts/test*.sh OR scripts/tests/*.sh OR
#        scripts/tests/fixture-dependent/*.sh).
#   (2) PARTITIONABILITY: the disk KEEP set (disk glob − allowlist) is
#       NON-EMPTY (an empty KEEP = the allowlist swallowed everything).
#
# The disk glob enumerates three EXPLICIT non-recursive dirs (the inert
# scripts/tests/fixtures/ data tree is never swept in). Check 42 no longer
# reads the workflow yml. This test is updated in lock-step
# (enumerate-encoding-surfaces).
#
# Mirrors the test-validate-pack-check-41.sh harness pattern: each test
# stages a synthetic REPO_ROOT with controlled scripts/ + scripts/tests/ +
# scripts/tests/fixture-dependent/ + allowlist content, invokes Check 42
# against the tmp tree, and asserts PASS / FAIL as expected.
#
# Coverage:
#   Group 0: Module import + Check 42 symbol registration
#   Group 1: Real-state-at-HEAD PASS verification (self-referential closure)
#   Group 2: Synthetic PASS/FAIL tests covering:
#            - PASS path (valid allowlist: exists + glob-shaped; KEEP non-empty)
#            - PASS path (empty allowlist)
#            - FAIL path: stale allowlist entry (path not on disk)
#            - FAIL path: malformed allowlist entry (not glob-shaped)
#            - FAIL path: multiple invalid allowlist entries surfaced together
#            - FAIL path: empty KEEP (allowlist swallowed every test)
#            - PASS path: a fixture-dependent/ test counts toward the disk set
#            - Lenient skip when no test scripts present
#   Group 3: End-to-end validate-pack.py exit-status on HEAD; Check 42
#            output detected with the re-scoped message.
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
import os, sys, pathlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Enumerate the real FULL disk test set (BD-219 redesign scope):
# scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh.
scripts_dir = pathlib.Path(REPO_ROOT_PY) / "scripts"
tests_dir = scripts_dir / "tests"
fxdep_dir = tests_dir / "fixture-dependent"
disk = set()
for p in scripts_dir.glob("test*.sh"):
    disk.add("scripts/" + p.name)
for p in tests_dir.glob("*.sh"):
    disk.add("scripts/tests/" + p.name)
for p in fxdep_dir.glob("*.sh"):
    disk.add("scripts/tests/fixture-dependent/" + p.name)

# Sanity: real state should have many test scripts today (>=60).
if len(disk) < 60:
    failures.append(f"real disk test set has only {len(disk)} scripts (expected >=60)")

# Sanity: Check 42's own test must be present (self-referential closure).
if "scripts/tests/test-validate-pack-check-42.sh" not in disk:
    failures.append("scripts/tests/test-validate-pack-check-42.sh not present on disk — self-referential closure broken")

# Guard: the inert scripts/tests/fixtures/ data tree must NOT be wired.
leaked = sorted(p for p in disk if "/tests/fixtures/" in p)
if leaked:
    failures.append(f"inert data-dir files wrongly in disk set: {leaked}")

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
if "allowlist is valid + bounded" not in captured:
    failures.append(f"real-state Check 42 PASS message missing 'allowlist is valid + bounded': {captured}")
if "disk-derived at run time" not in captured:
    failures.append(f"real-state Check 42 PASS message missing 'disk-derived at run time': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 42 PASSes (allowlist valid + bounded; KEEP partitionable; no data-dir leak)" ;;
    *) t_fail "real-state Check 42 verification failed" ;;
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

# Helper: build a synthetic REPO_ROOT with controlled scripts/test*.sh +
# scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh files and a
# controlled scripts/ci-test-wiring-allowlist.txt. Returns
# (failures_count, captured_output) from a Check 42 invocation against the
# tmp tree. The re-scoped Check 42 (BD-219 redesign) charges:
#     allowlist VALIDITY (exist + glob-shaped) + KEEP PARTITIONABILITY
# Check 42 no longer reads the workflow yml.
#
# `root_scripts`:  base filenames to stage under scripts/      (test*.sh).
# `tests_scripts`: base filenames to stage under scripts/tests/.
# `fxdep_scripts`: base filenames to stage under
#                  scripts/tests/fixture-dependent/.
# `allowlist`:     repo-relative paths to write into the allowlist file.
# `extra_files`:   repo-relative paths (any location) to create on disk WITHOUT
#                  them being test scripts — used to stage a path that EXISTS but
#                  is not glob-shaped (e.g. scripts/lib/x.sh), so the malformed-
#                  shape FAIL fires WITHOUT the stale FAIL.
# `omit_all_tests`: when True, create NO test scripts at all (lenient skip).
def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W14 wave-invariant). Check 42's body now lives in
    validate_checks.singletons and reads singletons.REPO_ROOT; a facade-only
    patch would NOT bite. Setting it on every loaded validate_checks.* reaches
    the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == 'validate_checks' or _name.startswith('validate_checks.'):
            if hasattr(_m, 'REPO_ROOT'):
                _m.REPO_ROOT = root


def run_check(root_scripts=None, tests_scripts=None, fxdep_scripts=None,
              allowlist=None, extra_files=None, omit_all_tests=False):
    root_scripts = root_scripts or []
    tests_scripts = tests_scripts or []
    fxdep_scripts = fxdep_scripts or []
    allowlist = allowlist or []
    extra_files = extra_files or []
    tmpdir = tempfile.mkdtemp(prefix="vp-check42-")
    root = pathlib.Path(tmpdir)

    scripts_dir = root / "scripts"
    scripts_dir.mkdir(parents=True)
    if not omit_all_tests:
        for name in root_scripts:
            (scripts_dir / name).write_text("#!/usr/bin/env bash\n# stub\nexit 0\n")
        tests_dir = scripts_dir / "tests"
        tests_dir.mkdir(parents=True)
        for name in tests_scripts:
            (tests_dir / name).write_text("#!/usr/bin/env bash\n# stub\nexit 0\n")
        if fxdep_scripts:
            fxdep_dir = tests_dir / "fixture-dependent"
            fxdep_dir.mkdir(parents=True)
            for name in fxdep_scripts:
                (fxdep_dir / name).write_text("#!/usr/bin/env bash\n# stub\nexit 0\n")
    for rel in extra_files:
        target = root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("#!/usr/bin/env bash\n# non-test stub\nexit 0\n")

    # Always write the allowlist file (possibly empty header only).
    al_lines = ["# synthetic allowlist"]
    for p in allowlist:
        al_lines.append(p)
    (scripts_dir / "ci-test-wiring-allowlist.txt").write_text("\n".join(al_lines) + "\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_ci_workflow_wires_per_check_tests()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS path — valid allowlist (entry exists on disk + glob-shaped),
# KEEP non-empty. Canonical good state.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=[
        "test-validate-pack-check-16.sh",
        "tracker-bd204-lossless-roundtrip-test.sh",
    ],
    allowlist=["scripts/tests/tracker-bd204-lossless-roundtrip-test.sh"],
)
if fail_count != 0:
    failures.append(f"T1 (PASS — valid allowlist) expected 0 failures, got {fail_count}: {captured}")
if "allowlist is valid + bounded" not in captured:
    failures.append(f"T1 PASS message missing 'allowlist is valid + bounded': {captured}")
if "3 test script(s) on disk" not in captured:
    failures.append(f"T1 PASS message missing '3 test script(s) on disk' count: {captured}")
if "1 allowlisted" not in captured:
    failures.append(f"T1 PASS message missing '1 allowlisted' count: {captured}")
if "2 KEEP" not in captured:
    failures.append(f"T1 PASS message missing '2 KEEP' count: {captured}")

# T2: PASS path — EMPTY allowlist (every test is KEEP). Valid + partitionable.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["test-validate-pack-check-16.sh"],
    allowlist=[],
)
if fail_count != 0:
    failures.append(f"T2 (PASS — empty allowlist) expected 0 failures, got {fail_count}: {captured}")
if "0 allowlisted" not in captured:
    failures.append(f"T2 PASS message missing '0 allowlisted': {captured}")

# T3: FAIL path — STALE allowlist entry (path not on disk).
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["test-validate-pack-check-16.sh"],
    allowlist=["scripts/tests/test-deleted-long-ago.sh"],
)
if fail_count != 1:
    failures.append(f"T3 (FAIL — stale allowlist) expected 1 failure, got {fail_count}: {captured}")
if "scripts/tests/test-deleted-long-ago.sh" not in captured:
    failures.append(f"T3 FAIL message must name the stale path: {captured}")
if "DOES NOT EXIST on disk" not in captured:
    failures.append(f"T3 FAIL message must say 'DOES NOT EXIST on disk': {captured}")

# T4: FAIL path — MALFORMED allowlist entry that EXISTS on disk but is not
# glob-shaped (scripts/lib/x.sh — the disk glob can never produce it). Staging
# it via extra_files means the stale FAIL does NOT fire, isolating the shape FAIL.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["test-validate-pack-check-16.sh"],
    extra_files=["scripts/lib/not-a-test.sh"],
    allowlist=["scripts/lib/not-a-test.sh"],
)
if fail_count != 1:
    failures.append(f"T4 (FAIL — malformed allowlist) expected 1 failure, got {fail_count}: {captured}")
if "scripts/lib/not-a-test.sh" not in captured:
    failures.append(f"T4 FAIL message must name the malformed path: {captured}")
if "does NOT match the disk-glob shape" not in captured:
    failures.append(f"T4 FAIL message must say 'does NOT match the disk-glob shape': {captured}")

# T5: FAIL path — MULTIPLE invalid allowlist entries surfaced together: one
# stale (not on disk) + one malformed (exists but wrong shape). Check 42 must
# surface BOTH (exactly 2 failures).
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["test-validate-pack-check-16.sh"],
    extra_files=["scripts/lib/wrong-shape.sh"],   # exists but wrong shape
    allowlist=[
        "scripts/tests/test-gone.sh",        # stale (not on disk)
        "scripts/lib/wrong-shape.sh",        # malformed (wrong dir, exists)
    ],
)
if fail_count != 2:
    failures.append(f"T5 (FAIL — 2 invalid allowlist) expected 2 failures, got {fail_count}: {captured}")
for needle in ("scripts/tests/test-gone.sh", "scripts/lib/wrong-shape.sh"):
    if needle not in captured:
        failures.append(f"T5 FAIL must name both invalid paths; missing {needle}: {captured}")

# T6: FAIL path — EMPTY KEEP (the allowlist swallowed every disk test).
fail_count, captured = run_check(
    tests_scripts=["test-validate-pack-check-16.sh"],
    allowlist=["scripts/tests/test-validate-pack-check-16.sh"],
)
if fail_count != 1:
    failures.append(f"T6 (FAIL — empty KEEP) expected 1 failure, got {fail_count}: {captured}")
if "disk KEEP set is EMPTY" not in captured:
    failures.append(f"T6 FAIL message must say 'disk KEEP set is EMPTY': {captured}")

# T7: PASS path — a scripts/tests/fixture-dependent/ test counts toward the
# disk set (the BD-219 redesign three-dir glob); a valid allowlist entry
# pointing at it is glob-shaped + exists. KEEP non-empty (the other tests).
fail_count, captured = run_check(
    tests_scripts=["test-validate-pack-check-16.sh"],
    fxdep_scripts=["test-some-fixture-test.sh"],
    allowlist=["scripts/tests/fixture-dependent/test-some-fixture-test.sh"],
)
if fail_count != 0:
    failures.append(f"T7 (PASS — fixture-dependent dir glob + valid allowlist) expected 0 failures, got {fail_count}: {captured}")
if "2 test script(s) on disk" not in captured:
    failures.append(f"T7 PASS message must count the fixture-dependent/ test (2 on disk): {captured}")

# T8: SKIP path — no test scripts at all (lenient mode).
fail_count, captured = run_check(omit_all_tests=True)
if fail_count != 0:
    failures.append(f"T8 (SKIP — no test scripts) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T8 SKIP message must say 'skipping (lenient)': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T8: valid/empty allowlist PASS, stale + malformed + multi-invalid + empty-KEEP FAIL, fixture-dependent dir, lenient skip)" ;;
    *) t_fail "Synthetic Check 42 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 42 > /tmp/vp-check42-e2e.out 2>&1; then
    if grep -q "Check 42: CI test-wiring allowlist is valid + bounded" /tmp/vp-check42-e2e.out \
       && grep -qE "Check 42 — [0-9]+ test script\(s\) on disk" /tmp/vp-check42-e2e.out \
       && grep -q "allowlist is valid + bounded" /tmp/vp-check42-e2e.out; then
        t_pass "validate-pack.py --only-check 42 exits 0; re-scoped Check 42 runs and reports clean"
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
