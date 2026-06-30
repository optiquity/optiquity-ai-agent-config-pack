#!/usr/bin/env bash
# scripts/tests/test-validate-pack-checks-58-59-60.sh — BD-219 C3 tests for
# the three CI-runtime-optimization upkeep guards:
#   Check 58 — the authoritative `validate` job carries NO `--only-check`.
#   Check 59 — CHECK_REGISTRY completeness (the moved wiring proof).
#   Check 60 — CI shard partition covers the wired set (validate-pack mirror).
#
# Each check is exercised both GREEN (real state at HEAD passes) and RED
# (a controlled violation FAILs), via the module-import harness (the per-
# check tests' canonical pattern: importlib spec_from_file_location does NOT
# run main() because of the `if __name__ == "__main__"` guard).
#
# Usage: bash scripts/tests/test-validate-pack-checks-58-59-60.sh

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
# Group 0: Module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + symbols ===\n"
python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
need = [
    'check_validate_job_carries_no_only_check',
    'check_check_registry_completeness',
    'check_ci_shard_coverage',
    '_build_check_registry',
    'CHECK_REGISTRY_EXPECTED_COUNT',
]
missing = [n for n in need if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
print('OK')
" > /tmp/vp-585960-import.out 2>&1
if grep -q '^OK$' /tmp/vp-585960-import.out; then
    t_pass "validate-pack.py imports + Check 58/59/60 symbols registered"
else
    t_fail "import/symbol registration failed" "$(cat /tmp/vp-585960-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Check 58 — validate job carries no --only-check
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: Check 58 (validate job no --only-check) ===\n"
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
failures = []

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W14 wave-invariant). Check 58's body now lives in
    validate_checks.singletons and reads singletons.REPO_ROOT; a facade-only
    patch would NOT bite. Reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == 'validate_checks' or _name.startswith('validate_checks.'):
            if hasattr(_m, 'REPO_ROOT'):
                _m.REPO_ROOT = root

def run58(root):
    saved_root, saved_f = mod.REPO_ROOT, list(mod.failures)
    mod.failures.clear(); _patch_root(mod, pathlib.Path(root))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_validate_job_carries_no_only_check()
        n = len(mod.failures); cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root); mod.failures.clear(); mod.failures.extend(saved_f)
    return n, cap

def make_yml(root, invocation):
    d = pathlib.Path(root) / ".github" / "workflows"; d.mkdir(parents=True)
    (d / "validate-pack.yml").write_text(
        "jobs:\n  validate:\n    steps:\n      - run: " + invocation + "\n")

# GREEN: clean invocation.
t = tempfile.mkdtemp(prefix="vp58-")
make_yml(t, "python3 scripts/validate-pack.py")
n, cap = run58(t); shutil.rmtree(t, ignore_errors=True)
if n != 0:
    failures.append(f"GREEN expected 0 failures, got {n}: {cap}")
if "no `--only-check`" not in cap:
    failures.append(f"GREEN message missing 'no --only-check': {cap}")

# RED: --only-check on the full run.
t = tempfile.mkdtemp(prefix="vp58-")
make_yml(t, "python3 scripts/validate-pack.py --only-check 1")
n, cap = run58(t); shutil.rmtree(t, ignore_errors=True)
if n != 1:
    failures.append(f"RED expected 1 failure, got {n}: {cap}")
if "carries `--only-check`" not in cap:
    failures.append(f"RED message missing 'carries --only-check': {cap}")

# Real state at HEAD: GREEN.
n, cap = run58(os.environ['REPO_ROOT'])
if n != 0:
    failures.append(f"real-HEAD expected 0 failures, got {n}: {cap}")

if failures:
    print("FAILURES")
    [print(" ", f) for f in failures]
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 58 GREEN (clean + real-HEAD) and RED (--only-check on full run)" ;;
    *) t_fail "Check 58 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Check 59 — CHECK_REGISTRY completeness
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: Check 59 (CHECK_REGISTRY completeness) ===\n"
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
failures = []

def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W14
    wave-invariant). Check 59's body now lives in validate_checks.singletons
    and reads its own `from .core`-bound CHECK_REGISTRY_EXPECTED_COUNT; a
    facade-only patch would NOT bite. This reaches the owning module's binding
    wherever the body resolves it (singletons + core both carry it)."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == 'validate_checks' or _name.startswith('validate_checks.'):
            if hasattr(_m, name):
                setattr(_m, name, value)

def run59():
    saved_f = list(mod.failures); mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_check_registry_completeness()
        n = len(mod.failures); cap = buf.getvalue()
    finally:
        mod.failures.clear(); mod.failures.extend(saved_f)
    return n, cap

# Real expected count must equal the actual registry length (anti-drift).
actual = len(mod._build_check_registry())
if actual != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    failures.append(f"CHECK_REGISTRY_EXPECTED_COUNT ({mod.CHECK_REGISTRY_EXPECTED_COUNT}) != actual registry length ({actual})")

# GREEN: real count.
n, cap = run59()
if n != 0:
    failures.append(f"GREEN expected 0 failures, got {n}: {cap}")
if "== CHECK_REGISTRY_EXPECTED_COUNT" not in cap:
    failures.append(f"GREEN message missing count-match phrase: {cap}")

# RED: mutate the expected count → mismatch.
saved = mod.CHECK_REGISTRY_EXPECTED_COUNT
_patch_attr(mod, 'CHECK_REGISTRY_EXPECTED_COUNT', saved + 7)
n, cap = run59()
_patch_attr(mod, 'CHECK_REGISTRY_EXPECTED_COUNT', saved)
if n != 1:
    failures.append(f"RED (count mismatch) expected 1 failure, got {n}: {cap}")
if "without updating the expected-count" not in cap:
    failures.append(f"RED message missing bookkeeping guidance: {cap}")

if failures:
    print("FAILURES")
    [print(" ", f) for f in failures]
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 59 GREEN (real count, structural integrity) and RED (count mismatch)" ;;
    *) t_fail "Check 59 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Check 60 — CI shard coverage mirror
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: Check 60 (CI shard coverage mirror) ===\n"
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
failures = []

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W14 wave-invariant). Check 60's body now lives in
    validate_checks.singletons and reads singletons.REPO_ROOT; a facade-only
    patch would NOT bite. Reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == 'validate_checks' or _name.startswith('validate_checks.'):
            if hasattr(_m, 'REPO_ROOT'):
                _m.REPO_ROOT = root

def run60(root):
    saved_root, saved_f = mod.REPO_ROOT, list(mod.failures)
    mod.failures.clear(); _patch_root(mod, pathlib.Path(root))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_ci_shard_coverage()
        n = len(mod.failures); cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root); mod.failures.clear(); mod.failures.extend(saved_f)
    return n, cap

# GREEN: real state (the real ci-shard-plan.py --assert-coverage passes).
n, cap = run60(os.environ['REPO_ROOT'])
if n != 0:
    failures.append(f"GREEN (real-HEAD) expected 0 failures, got {n}: {cap}")
if "--assert-coverage passed" not in cap:
    failures.append(f"GREEN message missing '--assert-coverage passed': {cap}")

# RED: a scratch root whose ci-shard-plan.py stub exits non-zero.
t = tempfile.mkdtemp(prefix="vp60-")
libd = pathlib.Path(t) / "scripts" / "lib"; libd.mkdir(parents=True)
(libd / "ci-shard-plan.py").write_text(
    "import sys\n"
    "sys.stderr.write('ci-shard-plan --assert-coverage FAILED:\\n  - wired KEEP test(s) in NO shard: scripts/foo.sh\\n')\n"
    "sys.exit(1)\n")
n, cap = run60(t); shutil.rmtree(t, ignore_errors=True)
if n != 1:
    failures.append(f"RED (coverage break) expected 1 failure, got {n}: {cap}")
if "--assert-coverage FAILED" not in cap:
    failures.append(f"RED message missing '--assert-coverage FAILED': {cap}")

# SKIP: a scratch root with no ci-shard-plan.py → lenient skip.
t = tempfile.mkdtemp(prefix="vp60-")
n, cap = run60(t); shutil.rmtree(t, ignore_errors=True)
if n != 0:
    failures.append(f"SKIP (module absent) expected 0 failures, got {n}: {cap}")
if "absent — skipping (lenient)" not in cap:
    failures.append(f"SKIP message missing lenient phrasing: {cap}")

if failures:
    print("FAILURES")
    [print(" ", f) for f in failures]
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 60 GREEN (real-HEAD), RED (coverage break), SKIP (module absent)" ;;
    *) t_fail "Check 60 tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: End-to-end --only-check exit status for 58/59/60
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: e2e --only-check 58/59/60 ===\n"
for nn in 58 59 60; do
    if python3 "$VALIDATE" --only-check "$nn" > "/tmp/vp-c$nn-e2e.out" 2>&1; then
        if grep -qE "Check $nn:" "/tmp/vp-c$nn-e2e.out"; then
            t_pass "validate-pack.py --only-check $nn exits 0 and runs Check $nn"
        else
            t_fail "Check $nn banner not detected" "$(tail -5 /tmp/vp-c$nn-e2e.out)"
        fi
    else
        t_fail "validate-pack.py --only-check $nn exits non-zero" "$(tail -10 /tmp/vp-c$nn-e2e.out)"
    fi
done

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"; exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"; exit 1
fi
