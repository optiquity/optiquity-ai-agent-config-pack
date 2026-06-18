#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-62.sh — synthetic fixture tests for
# Check 62 (test-fixtures/manifest.txt is structurally well-formed).
#
# BD-228 push-time-manifest method backstop. Check 62 is a CHEAP structural
# screen on the committed manifest — NOT the SHA-correctness authority (that
# stays CI's `test-fixtures/build.sh --verify`). It catches a truncated /
# garbled / wrong-row-count / wrong-name / non-hex manifest INSTANTLY in the
# always-run validate job, before the expensive rebuild runs.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it writes synthetic manifest.txt + build.sh files into a /tmp
# REPO_ROOT). It lives under scripts/tests/ and auto-wires via the disk glob.
# Per "Test infra is self-provisioned": every malformed/well-formed manifest is
# built in a /tmp scratch tree; the REAL test-fixtures/manifest.txt is NEVER
# mutated.
#
# Coverage:
#   Group 0: Module import + Check 62 symbol registration
#   Group 1: Real-state-at-HEAD PASS (the real manifest is well-formed)
#   Group 2: Synthetic PASS/FAIL tests against a /tmp REPO_ROOT:
#            - PASS: a well-formed 6-row manifest (names == FIXTURE_NAMES, 40-hex)
#            - FAIL: wrong row count (5 rows)
#            - FAIL: a garbage / non-hex SHA
#            - FAIL: a wrong fixture name
#            - FAIL: a missing manifest file (FIXTURE_NAMES present)
#            - SKIP: build.sh has no FIXTURE_NAMES (no signal → lenient skip)
#   Group 3: End-to-end validate-pack.py --only-check 62 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-62.sh

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
# Group 0: Module import + Check 62 symbol registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 62 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_manifest_structural', '_load_fixture_names']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
# Check 62 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's invariant).
nums = [t[0] for t in mod._build_check_registry()]
if 62 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check62-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check62-import.out; then
    t_pass "validate-pack.py imports + Check 62 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 62 registration / count invariant failed" \
        "$(cat /tmp/vp-check62-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real manifest is well-formed)
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
        mod.check_manifest_structural()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 62 expected 0 failures, got {len(new)}: {cap}")
if "structurally well-formed" not in cap:
    failures.append(f"real-state PASS message missing 'structurally well-formed': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 62 PASSes (the committed manifest is well-formed)" ;;
    *) t_fail "real-state Check 62 failed" ;;
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

failures = []

# A 40-char lowercase hex token for synthetic rows.
SHA = "0123456789abcdef0123456789abcdef01234567"

# Helper: build a synthetic REPO_ROOT with a build.sh carrying a FIXTURE_NAMES
# array and a manifest.txt with `manifest_body` (or no manifest at all when
# manifest_body is None). Returns (failures_count, captured_output) from a
# Check 62 invocation against the tmp tree. Never touches the real tree/manifest.
#
# `omit_fixture_names`: when True, write a build.sh WITHOUT a FIXTURE_NAMES
#                       array (lenient SKIP signal).
def run_check(manifest_body, omit_fixture_names=False):
    tmpdir = tempfile.mkdtemp(prefix="vp-check62-")
    root = pathlib.Path(tmpdir)
    tf_dir = root / "test-fixtures"
    tf_dir.mkdir(parents=True)

    if omit_fixture_names:
        (tf_dir / "build.sh").write_text("#!/usr/bin/env bash\n# no FIXTURE_NAMES here\nexit 0\n")
    else:
        (tf_dir / "build.sh").write_text(
            '#!/usr/bin/env bash\n'
            'readonly FIXTURE_NAMES=(\n'
            '    "alpha"\n'
            '    "beta"\n'
            '    "gamma"\n'
            ')\n'
        )

    if manifest_body is not None:
        (tf_dir / "manifest.txt").write_text(manifest_body)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_manifest_structural()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

HEADER = (
    "# manifest header comment\n"
    "# do not hand-edit\n"
    "#\n"
)
WELLFORMED = HEADER + (
    f"alpha  {SHA}\n"
    f"beta  {SHA}\n"
    f"gamma  {SHA}\n"
)

# T1: PASS — a well-formed 3-row manifest (names == FIXTURE_NAMES, 40-hex SHAs).
fail_count, captured = run_check(WELLFORMED)
if fail_count != 0:
    failures.append(f"T1 (PASS — well-formed) expected 0 failures, got {fail_count}: {captured}")
if "structurally well-formed" not in captured:
    failures.append(f"T1 PASS message missing 'structurally well-formed': {captured}")

# T2: FAIL — wrong row count (2 rows, missing gamma).
fail_count, captured = run_check(HEADER + f"alpha  {SHA}\nbeta  {SHA}\n")
if fail_count < 1:
    failures.append(f"T2 (FAIL — wrong row count) expected >=1 failure, got {fail_count}: {captured}")
if "data row" not in captured and "do not match build.sh" not in captured:
    failures.append(f"T2 FAIL must report a row-count or name-set mismatch: {captured}")

# T3: FAIL — a garbage / non-hex SHA on one row.
fail_count, captured = run_check(HEADER + (
    f"alpha  {SHA}\n"
    "beta  NOT-A-VALID-SHA\n"
    f"gamma  {SHA}\n"
))
if fail_count < 1:
    failures.append(f"T3 (FAIL — non-hex SHA) expected >=1 failure, got {fail_count}: {captured}")
if "40-character lowercase hex" not in captured:
    failures.append(f"T3 FAIL must report the non-hex SHA: {captured}")

# T4: FAIL — a wrong fixture name (delta is not in FIXTURE_NAMES).
fail_count, captured = run_check(HEADER + (
    f"alpha  {SHA}\n"
    f"beta  {SHA}\n"
    f"delta  {SHA}\n"
))
if fail_count < 1:
    failures.append(f"T4 (FAIL — wrong name) expected >=1 failure, got {fail_count}: {captured}")
if "do not match build.sh" not in captured:
    failures.append(f"T4 FAIL must report the name-set mismatch: {captured}")

# T5: FAIL — manifest file missing entirely (FIXTURE_NAMES present).
fail_count, captured = run_check(None)
if fail_count < 1:
    failures.append(f"T5 (FAIL — missing manifest) expected >=1 failure, got {fail_count}: {captured}")
if "MISSING" not in captured:
    failures.append(f"T5 FAIL must report the missing manifest: {captured}")

# T6: SKIP — build.sh has no FIXTURE_NAMES (no signal → lenient skip).
fail_count, captured = run_check(WELLFORMED, omit_fixture_names=True)
if fail_count != 0:
    failures.append(f"T6 (SKIP — no FIXTURE_NAMES) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T6 SKIP message must say 'skipping (lenient)': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T6: well-formed PASS, wrong-count/non-hex/wrong-name/missing FAIL, lenient skip)" ;;
    *) t_fail "Synthetic Check 62 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 62 > /tmp/vp-check62-e2e.out 2>&1; then
    if grep -q "Check 62: test-fixtures/manifest.txt is structurally well-formed" /tmp/vp-check62-e2e.out \
       && grep -q "structurally well-formed:" /tmp/vp-check62-e2e.out; then
        t_pass "validate-pack.py --only-check 62 exits 0; Check 62 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 62 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check62-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check62-e2e.out)"
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
