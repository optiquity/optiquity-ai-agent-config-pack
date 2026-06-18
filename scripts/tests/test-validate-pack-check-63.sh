#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-63.sh — synthetic tests for Check 63
# (graphify-out/ is never tracked — BD-225).
#
# Check 63 is the BD-225 git-hygiene guard: a CHEAP O(1) `git ls-files
# graphify-out/` screen that FAILs loud the moment any path under the Graphify
# knowledge-graph build artifact (per-clone, regenerated, gitignored) is
# tracked. It pairs with the C1 `.gitignore` entry (enforces what it declares).
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s a throwaway repo in a /tmp REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob (Check 42 /
# BD-219). Per "Test infra is self-provisioned": every tracked/untracked case is
# built in a /tmp scratch git repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 63 symbol registration + count invariant
#   Group 1: Real-state-at-HEAD PASS (the real tree has no tracked graphify-out/)
#   Group 2: Synthetic PASS/FAIL against a /tmp git repo (monkeypatch REPO_ROOT):
#            - PASS: no graphify-out/ directory → 0 failures
#            - FAIL: a tracked graphify-out/graph.json → >=1 failure naming it
#   Group 3: End-to-end validate-pack.py --only-check 63 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-63.sh

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
# Group 0: Module import + Check 63 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 63 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_graphify_out_never_tracked'):
    print('FAIL_MISSING check_graphify_out_never_tracked'); sys.exit(1)
# Check 63 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's invariant — proves the count bump is
# consistent).
nums = [t[0] for t in mod._build_check_registry()]
if 63 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check63-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check63-import.out; then
    t_pass "validate-pack.py imports + Check 63 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 63 registration / count invariant failed" \
        "$(cat /tmp/vp-check63-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real tree has no tracked graphify-out/)
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
        mod.check_graphify_out_never_tracked()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 63 expected 0 failures, got {len(new)}: {cap}")
if "is not tracked" not in cap:
    failures.append(f"real-state PASS message missing 'is not tracked': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 63 PASSes (the real tree has no tracked graphify-out/)" ;;
    *) t_fail "real-state Check 63 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/FAIL tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/FAIL tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Helper: `git init` a throwaway repo in a /tmp REPO_ROOT, optionally add a
# TRACKED graphify-out/graph.json, then run Check 63 against it by monkeypatching
# mod.REPO_ROOT (N-4 — the check resolves its git root via cwd=mod.REPO_ROOT).
# Returns (failures_count, captured_output). Never touches the real tree.
def run_check(track_graph_artifact):
    tmpdir = tempfile.mkdtemp(prefix="vp-check63-")
    root = pathlib.Path(tmpdir)
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    # Identity so `git add` works in a clean throwaway env.
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    # A baseline tracked file so the index is non-empty either way.
    (root / "README.md").write_text("scratch\n")
    subprocess.run(["git", "add", "README.md"], cwd=root, check=True)

    if track_graph_artifact:
        gdir = root / "graphify-out"
        gdir.mkdir()
        (gdir / "graph.json").write_text("{}\n")
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_graphify_out_never_tracked()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — no graphify-out/ directory tracked → 0 failures + "is not tracked".
fail_count, captured = run_check(track_graph_artifact=False)
if fail_count != 0:
    failures.append(f"T1 (PASS — no graphify-out/) expected 0 failures, got {fail_count}: {captured}")
if "is not tracked" not in captured:
    failures.append(f"T1 PASS message missing 'is not tracked': {captured}")

# T2: FAIL — a TRACKED graphify-out/graph.json → >=1 failure naming the path.
fail_count, captured = run_check(track_graph_artifact=True)
if fail_count < 1:
    failures.append(f"T2 (FAIL — tracked graphify-out/) expected >=1 failure, got {fail_count}: {captured}")
if "graphify-out/graph.json" not in captured:
    failures.append(f"T2 FAIL must name the tracked path graphify-out/graph.json: {captured}")
if "git rm -r --cached graphify-out/" not in captured:
    failures.append(f"T2 FAIL must carry the remediation: {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1: clean repo PASS; T2: tracked graphify-out/ FAILs naming the path + remediation)" ;;
    *) t_fail "Synthetic Check 63 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 63 > /tmp/vp-check63-e2e.out 2>&1; then
    if grep -q "Check 63: graphify-out/ is never tracked" /tmp/vp-check63-e2e.out \
       && grep -q "is not tracked" /tmp/vp-check63-e2e.out; then
        t_pass "validate-pack.py --only-check 63 exits 0; Check 63 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 63 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check63-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check63-e2e.out)"
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
