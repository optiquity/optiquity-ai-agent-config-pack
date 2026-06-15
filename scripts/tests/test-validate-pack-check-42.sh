#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-42.sh — synthetic fixture tests
# for Check 42 (CI workflow wires every CI-eligible test).
#
# BD-184 introduced Check 42 over the per-check test subset. BD-219 C3
# GENERALIZED it to FULL set-equality over the whole CI-eligible test set:
#     disk_KEEP_set == wired_set
# where disk_KEEP_set = {scripts/test*.sh + scripts/tests/*.sh} − allowlist
# and allowlist = scripts/ci-test-wiring-allowlist.txt (the measure-then-bound
# STRIP set). BD-219 C2 RE-ANCHORED the wired-set source: it is now the
# `scripts/...sh` tokens harvested from the `tests`-job static
# `matrix.include[].scripts` strings (the sharded matrix is the wired-set SSOT
# — no more `run: bash` test runners). The synthetic ymls below build that
# include shape. This test is updated in lock-step (enumerate-encoding-surfaces).
#
# Check 42 closes the "missing test wiring" gap class that surfaced 5
# times across the BD-175 emergency batch (BD-179 FIX-1: 3 tests;
# BD-183 FIX-1: 1 test; BD-183 FIX-2: 1 test) — each caught by reviewer
# attention, now caught mechanically — and (BD-219) extends it to ALL
# test scripts on disk, not just the per-check subset.
#
# Mirrors the test-validate-pack-check-41.sh harness pattern: each test
# stages a synthetic REPO_ROOT with controlled scripts/ + scripts/tests/ +
# allowlist + workflow yml content, invokes Check 42 against the tmp tree,
# and asserts PASS / FAIL as expected.
#
# Coverage:
#   Group 0: Module import + Check 42 symbol registration
#   Group 1: Real-state-at-HEAD PASS verification (self-referential
#            closure: check-42 test + check-42 wiring present together)
#   Group 2: Synthetic PASS/FAIL tests covering:
#            - PASS path (every disk KEEP test has a wiring line)
#            - FAIL path: a tests/ KEEP script unwired
#            - FAIL path: a scripts-root KEEP script unwired
#            - FAIL path: multiple unwired KEEP scripts across both dirs
#            - PASS path: allowlisted (STRIP) script unwired (no failure)
#            - FAIL path: allowlist staleness (allowlisted-but-now-wired)
#            - Lenient skip when no test scripts present
#            - Lenient skip when .github/workflows/validate-pack.yml absent
#   Group 3: End-to-end validate-pack.py exit-status on HEAD; Check 42
#            output detected with the generalized message.
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

# Enumerate the real FULL disk test set (BD-219 generalized scope):
# scripts/test*.sh + scripts/tests/*.sh.
scripts_dir = pathlib.Path(REPO_ROOT_PY) / "scripts"
tests_dir = scripts_dir / "tests"
disk = set()
for p in scripts_dir.glob("test*.sh"):
    disk.add("scripts/" + p.name)
for p in tests_dir.glob("*.sh"):
    disk.add("scripts/tests/" + p.name)

# Sanity: real state should have many test scripts today (>=60).
if len(disk) < 60:
    failures.append(f"real disk test set has only {len(disk)} scripts (expected >=60)")

# Sanity: BD-184's own test must be present (self-referential closure).
if "scripts/tests/test-validate-pack-check-42.sh" not in disk:
    failures.append("scripts/tests/test-validate-pack-check-42.sh not present on disk — self-referential closure broken")

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
if "disk_KEEP_set == wired_set" not in captured:
    failures.append(f"real-state Check 42 PASS message missing 'disk_KEEP_set == wired_set': {captured}")
if "CI workflow wiring is complete" not in captured:
    failures.append(f"real-state Check 42 PASS message missing closure phrase: {captured}")

# Self-referential closure check: at HEAD check-42 itself must appear in the
# workflow yml as a token inside a `tests`-job matrix.include[].scripts string
# (BD-219 C2: the static shard matrix is the wired-set source — there is no
# `run: bash` test runner any more).
workflow_path = pathlib.Path(REPO_ROOT_PY) / ".github" / "workflows" / "validate-pack.yml"
workflow_text = workflow_path.read_text()
if "scripts/tests/test-validate-pack-check-42.sh" not in workflow_text:
    failures.append("test-validate-pack-check-42.sh has no entry in any tests-job matrix.include[].scripts string in validate-pack.yml — self-referential closure broken")

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

# Helper: build a synthetic REPO_ROOT with controlled scripts/test*.sh +
# scripts/tests/*.sh files, a controlled scripts/ci-test-wiring-allowlist.txt,
# and a controlled .github/workflows/validate-pack.yml. Returns
# (failures_count, captured_output) from a Check 42 invocation against the
# tmp tree. Mirrors the GENERALIZED Check 42 invariant (BD-219 C3):
#     disk_KEEP_set == wired_set   (disk_KEEP_set = disk − allowlist)
#
# `root_scripts`:  base filenames to stage under scripts/      (test*.sh).
# `tests_scripts`: base filenames to stage under scripts/tests/.
# `wired`:         repo-relative paths placed into the synthetic workflow yml's
#                  `tests`-job `matrix.include[].scripts` strings (BD-219 C2:
#                  Check 42 harvests scripts/...sh tokens from those values —
#                  there are no more `run: bash` test runners).
# `allowlist`:     repo-relative paths to write into the allowlist file.
# `omit_workflow`: when True, do not create the workflow yml (lenient skip).
# `omit_all_tests`: when True, create NO test scripts at all (lenient skip).
def run_check(root_scripts=None, tests_scripts=None, wired=None,
              allowlist=None, omit_workflow=False, omit_all_tests=False):
    root_scripts = root_scripts or []
    tests_scripts = tests_scripts or []
    wired = wired or []
    allowlist = allowlist or []
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

    # Always write the allowlist file (possibly empty header only).
    al_lines = ["# synthetic allowlist"]
    for p in allowlist:
        al_lines.append(p)
    (scripts_dir / "ci-test-wiring-allowlist.txt").write_text("\n".join(al_lines) + "\n")

    if not omit_workflow:
        workflow_dir = root / ".github" / "workflows"
        workflow_dir.mkdir(parents=True)
        # BD-219 C2: Check 42 harvests scripts/...sh tokens from the `tests`-job
        # `matrix.include[].scripts` strings. Build a static include array
        # (2 shards, the wired paths split between them) so the parser exercises
        # the multi-shard union path. Full yml syntax is NOT required (the
        # parser is a line scan over `scripts:` values, not a yaml parser), but
        # the include shape mirrors the real workflow.
        lines = [
            "name: Validate Pack (synthetic)",
            "on: push",
            "jobs:",
            "  tests:",
            "    runs-on: ubuntu-latest",
            "    strategy:",
            "      fail-fast: false",
            "      matrix:",
            "        include:",
        ]
        # Split wired paths into two shards (round-robin) to exercise the
        # union-across-shards extraction. Empty shard → empty scripts string
        # (the union is still correct).
        shard_a = [p for i, p in enumerate(wired) if i % 2 == 0]
        shard_b = [p for i, p in enumerate(wired) if i % 2 == 1]
        lines.append("          - shard: 1")
        lines.append('            scripts: "' + " ".join(shard_a) + '"')
        lines.append("          - shard: 2")
        lines.append('            scripts: "' + " ".join(shard_b) + '"')
        lines.append("    steps:")
        lines.append("      - name: run shard ${{ matrix.shard }}")
        lines.append("        if: always()")
        lines.append("        run: |")
        lines.append("          rc=0")
        lines.append("          for t in ${{ matrix.scripts }}; do bash \"$t\" || rc=1; done")
        lines.append("          exit $rc")
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

# T1: PASS path — every disk KEEP test (scripts/ root AND scripts/tests/)
# has a wiring line; allowlist empty. Canonical good state.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-checks-32-33-34.sh",
    ],
    wired=[
        "scripts/test-detect.sh",
        "scripts/tests/test-validate-pack-check-16.sh",
        "scripts/tests/test-validate-pack-checks-32-33-34.sh",
    ],
)
if fail_count != 0:
    failures.append(f"T1 (PASS — all wired) expected 0 failures, got {fail_count}: {captured}")
if "disk_KEEP_set == wired_set" not in captured:
    failures.append(f"T1 PASS message missing 'disk_KEEP_set == wired_set': {captured}")
if "3 test script(s) on disk" not in captured:
    failures.append(f"T1 PASS message missing '3 test script(s) on disk' count: {captured}")
if "3 wired in workflow" not in captured:
    failures.append(f"T1 PASS message missing '3 wired in workflow' count: {captured}")

# T2: FAIL path — a scripts/tests/ KEEP script unwired.
fail_count, captured = run_check(
    tests_scripts=[
        "test-validate-pack-check-16.sh",
        "test-validate-pack-check-42.sh",
    ],
    wired=[
        "scripts/tests/test-validate-pack-check-16.sh",
        # check-42 wiring omitted intentionally
    ],
)
if fail_count != 1:
    failures.append(f"T2 (FAIL — tests/ KEEP unwired) expected 1 failure, got {fail_count}: {captured}")
if "scripts/tests/test-validate-pack-check-42.sh" not in captured:
    failures.append(f"T2 FAIL message must name the unwired path scripts/tests/test-validate-pack-check-42.sh: {captured}")
if "exists on disk but has NO" not in captured:
    failures.append(f"T2 FAIL message must include the canonical 'exists on disk but has NO' phrasing: {captured}")
if "validate-pack.yml" not in captured:
    failures.append(f"T2 FAIL message must reference .github/workflows/validate-pack.yml: {captured}")

# T3: FAIL path — a scripts/ ROOT KEEP script unwired (the generalized
# scope: BD-219 added scripts-root test*.sh to the disk set).
fail_count, captured = run_check(
    root_scripts=[
        "test-detect.sh",
        "test-compare-agent-trinity.sh",
    ],
    wired=[
        "scripts/test-detect.sh",
        # test-compare-agent-trinity wiring omitted intentionally
    ],
)
if fail_count != 1:
    failures.append(f"T3 (FAIL — scripts-root KEEP unwired) expected 1 failure, got {fail_count}: {captured}")
if "scripts/test-compare-agent-trinity.sh" not in captured:
    failures.append(f"T3 FAIL message must name the unwired scripts-root path: {captured}")

# T4: FAIL path — MULTIPLE unwired KEEP scripts across both dirs. Check 42
# must surface ALL unwired paths, not just the first.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh", "test-restore-from-backup.sh"],
    tests_scripts=[
        "test-validate-pack-check-39.sh",
        "test-validate-pack-checks-36-37-38.sh",
    ],
    wired=[
        "scripts/test-detect.sh",
        # 3 unwired: test-restore-from-backup, check-39, checks-36-37-38
    ],
)
if fail_count != 3:
    failures.append(f"T4 (FAIL — 3 unwired KEEP) expected 3 failures, got {fail_count}: {captured}")
for missing in ("scripts/test-restore-from-backup.sh",
                "scripts/tests/test-validate-pack-check-39.sh",
                "scripts/tests/test-validate-pack-checks-36-37-38.sh"):
    if missing not in captured:
        failures.append(f"T4 FAIL message must name all unwired paths; missing {missing}: {captured}")

# T5: PASS path — an allowlisted (STRIP) script is unwired → NO failure
# (the measure-then-bound exemption). Verifies the allowlist subtraction.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["tracker-bd204-lossless-roundtrip-test.sh"],
    wired=["scripts/test-detect.sh"],
    allowlist=["scripts/tests/tracker-bd204-lossless-roundtrip-test.sh"],
)
if fail_count != 0:
    failures.append(f"T5 (PASS — allowlisted STRIP unwired) expected 0 failures, got {fail_count}: {captured}")
if "1 allowlisted (intentionally-OUT)" not in captured:
    failures.append(f"T5 PASS message missing '1 allowlisted (intentionally-OUT)': {captured}")

# T6: FAIL path — allowlist STALENESS: an allowlisted script is ALSO wired
# (someone wired it without removing its allowlist line). BD-219 C3 new
# failure mode.
fail_count, captured = run_check(
    root_scripts=["test-detect.sh"],
    tests_scripts=["tracker-bd204-lossless-roundtrip-test.sh"],
    wired=[
        "scripts/test-detect.sh",
        "scripts/tests/tracker-bd204-lossless-roundtrip-test.sh",
    ],
    allowlist=["scripts/tests/tracker-bd204-lossless-roundtrip-test.sh"],
)
if fail_count != 1:
    failures.append(f"T6 (FAIL — allowlist staleness) expected 1 failure, got {fail_count}: {captured}")
if "Allowlist staleness" not in captured:
    failures.append(f"T6 FAIL message must say 'Allowlist staleness': {captured}")
if "tracker-bd204-lossless-roundtrip-test.sh" not in captured:
    failures.append(f"T6 FAIL message must name the stale-allowlisted path: {captured}")

# T7: SKIP path — no test scripts at all (lenient mode).
fail_count, captured = run_check(omit_all_tests=True)
if fail_count != 0:
    failures.append(f"T7 (SKIP — no test scripts) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T7 SKIP message must say 'skipping (lenient)': {captured}")

# T8: SKIP path — .github/workflows/validate-pack.yml absent (lenient mode).
fail_count, captured = run_check(
    tests_scripts=["test-validate-pack-check-16.sh"],
    omit_workflow=True,
)
if fail_count != 0:
    failures.append(f"T8 (SKIP — workflow yml absent) expected 0 failures, got {fail_count}: {captured}")
if ".github/workflows/validate-pack.yml absent" not in captured:
    failures.append(f"T8 SKIP message must reference workflow yml absence: {captured}")
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
    0) t_pass "Synthetic PASS/FAIL tests (T1-T8: KEEP wiring across both dirs, multi-unwired surfacing, allowlist exemption + staleness, lenient skips)" ;;
    *) t_fail "Synthetic Check 42 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 42 > /tmp/vp-check42-e2e.out 2>&1; then
    if grep -q "Check 42: CI workflow wires every CI-eligible test" /tmp/vp-check42-e2e.out \
       && grep -qE "Check 42 — [0-9]+ test script\(s\) on disk" /tmp/vp-check42-e2e.out \
       && grep -q "CI workflow wiring is complete" /tmp/vp-check42-e2e.out; then
        t_pass "validate-pack.py --only-check 42 exits 0; Check 42 runs and reports clean"
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
