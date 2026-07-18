#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-86.sh — synthetic tests for Check 86
# (pack-ops/dashboard-approvals/ holds exactly three files — BD-224).
#
# Check 86 is the BD-224 /pack-dashboard git-hygiene guard (design §11.2 Check A):
# it caps the git-TRACKED pack-ops/dashboard-approvals/ set at EXACTLY
# {dashboard.html, dashboard-url.txt, dashboard-shell.html}. An EXTRA tracked file
# (registry creep) FAILs; a MISSING file (any strict subset of the trio tracked)
# FAILs — the missing-file teeth enforce the all-three-or-none first-commit
# atomicity (F12). At HEAD the dir is absent (0 tracked) so the guard SKIPs
# (lenient).
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s a throwaway repo in a /tmp REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob (Check 42 /
# BD-219). Per "Test infra is self-provisioned": every tracked-state case is built
# in a /tmp scratch git repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 86 symbol registration + count invariant
#   Group 1: Real-state-at-HEAD SKIP (the real tree has no tracked approvals dir)
#   Group 2: Synthetic SKIP/PASS/FAIL against a /tmp git repo (monkeypatch
#            REPO_ROOT):
#            - SKIP: no dashboard-approvals/ tracked → 0 failures (lenient)
#            - PASS: exactly {dashboard.html, dashboard-url.txt,
#                    dashboard-shell.html} tracked → 0
#            - FAIL: a 4th EXTRA tracked file → >=1 failure naming extra=
#            - FAIL: only two of three tracked (missing shell) → >=1 failure
#                    naming missing= (all-three-or-none atomicity)
#            - SKIP: REPO_ROOT at a NON-git dir (no git init) → git-unavailable
#                    → SKIP-lenient (the git-absent / non-worktree branch)
#   Group 3: End-to-end validate-pack.py --only-check 86 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-86.sh

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
# Group 0: Module import + Check 86 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 86 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_dashboard_approvals_file_cap'):
    print('FAIL_MISSING check_dashboard_approvals_file_cap'); sys.exit(1)
# Check 86 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's invariant — proves the count bump is
# consistent).
nums = [t[0] for t in mod._build_check_registry()]
if 86 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check86-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check86-import.out; then
    t_pass "validate-pack.py imports + Check 86 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 86 registration / count invariant failed" \
        "$(cat /tmp/vp-check86-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD SKIP (real tree has no tracked approvals dir)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD SKIP ===\n"

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
        mod.check_dashboard_approvals_file_cap()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 86 expected 0 failures, got {len(new)}: {cap}")
if "skipping (lenient)" not in cap:
    failures.append(f"real-state SKIP message missing 'skipping (lenient)': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 86 SKIPs (the real tree has no tracked dashboard-approvals/)" ;;
    *) t_fail "real-state Check 86 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo SKIP/PASS/FAIL tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo SKIP/PASS/FAIL tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 86's body lives in validate_checks.pack_ops_hygiene and
    resolves its git root via pack_ops_hygiene.REPO_ROOT (through _git_ls_files);
    a facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it (BD-256 W12
    wave-invariant technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

# Helper: `git init` a throwaway repo in a /tmp REPO_ROOT, TRACK the given
# pack-ops/dashboard-approvals/ file basenames, then run Check 86 against it by
# monkeypatching mod.REPO_ROOT. Returns (failures_count, captured_output). Never
# touches the real tree.
def run_check(approval_basenames):
    tmpdir = tempfile.mkdtemp(prefix="vp-check86-")
    root = pathlib.Path(tmpdir)
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    # A baseline tracked file so the index is non-empty either way.
    (root / "README.md").write_text("scratch\n")
    subprocess.run(["git", "add", "README.md"], cwd=root, check=True)

    if approval_basenames:
        adir = root / "pack-ops" / "dashboard-approvals"
        adir.mkdir(parents=True)
        for name in approval_basenames:
            (adir / name).write_text("x\n")
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_approvals_file_cap()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# Helper: create a NON-git /tmp REPO_ROOT (NO `git init`), then run Check 86
# against it by monkeypatching mod.REPO_ROOT. `git ls-files` from a non-git
# directory returns non-zero → `_git_ls_files` reports available=False → the check
# SKIPs (git-unavailable / non-worktree → lenient). Returns (failures_count,
# captured_output). Never touches the real tree.
def run_check_nongit():
    tmpdir = tempfile.mkdtemp(prefix="vp-check86-nongit-")
    root = pathlib.Path(tmpdir)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_approvals_file_cap()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: SKIP — no dashboard-approvals/ tracked → 0 failures + lenient skip.
fail_count, captured = run_check([])
if fail_count != 0:
    failures.append(f"T1 (SKIP — no approvals dir) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T1 SKIP message missing 'skipping (lenient)': {captured}")

# T2: PASS — exactly {dashboard.html, dashboard-url.txt, dashboard-shell.html}
# tracked → 0 failures.
fail_count, captured = run_check(["dashboard.html", "dashboard-url.txt", "dashboard-shell.html"])
if fail_count != 0:
    failures.append(f"T2 (PASS — exactly three files) expected 0 failures, got {fail_count}: {captured}")
if "three-file cap intact" not in captured:
    failures.append(f"T2 PASS message missing 'three-file cap intact': {captured}")
if "dashboard-shell.html" not in captured:
    failures.append(f"T2 PASS message must name the shell file (dashboard-shell.html): {captured}")

# T3: FAIL — a 4th EXTRA tracked file (all three valid names + a rogue) → >=1
# failure naming extra=.
fail_count, captured = run_check(["dashboard.html", "dashboard-url.txt", "dashboard-shell.html", "rogue.txt"])
if fail_count < 1:
    failures.append(f"T3 (FAIL — extra file) expected >=1 failure, got {fail_count}: {captured}")
if "extra=" not in captured or "rogue.txt" not in captured:
    failures.append(f"T3 FAIL must name the extra tracked path (extra=... rogue.txt): {captured}")

# T4: FAIL — only two of three tracked (missing dashboard-shell.html) → >=1
# failure naming missing= (all-three-or-none first-commit atomicity teeth).
fail_count, captured = run_check(["dashboard.html", "dashboard-url.txt"])
if fail_count < 1:
    failures.append(f"T4 (FAIL — missing shell) expected >=1 failure, got {fail_count}: {captured}")
if "missing=" not in captured or "dashboard-shell.html" not in captured:
    failures.append(f"T4 FAIL must name the missing member (missing=... dashboard-shell.html): {captured}")

# T5: SKIP — REPO_ROOT points at a NON-git directory (no `git init`) → git
# ls-files unavailable (not a git work tree) → SKIP-lenient. Exercises the
# `available=False` (git-absent / non-worktree) branch (design §11.2 stated
# SKIP-lenience invariant), which the git-init'd cases above never reach.
fail_count, captured = run_check_nongit()
if fail_count != 0:
    failures.append(f"T5 (SKIP — non-git dir) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T5 SKIP message missing 'skipping (lenient)': {captured}")
if "git ls-files unavailable" not in captured:
    failures.append(f"T5 SKIP must report git-unavailable (git absent / not a git work tree): {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic SKIP/PASS/FAIL tests (T1 SKIP empty; T2 PASS exactly-three; T3 FAIL 4th-extra; T4 FAIL missing-shell/all-three-or-none; T5 SKIP non-git dir)" ;;
    *) t_fail "Synthetic Check 86 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 86 > /tmp/vp-check86-e2e.out 2>&1; then
    if grep -q "Check 86: pack-ops/dashboard-approvals/ holds exactly three files" /tmp/vp-check86-e2e.out \
       && grep -q "skipping (lenient)" /tmp/vp-check86-e2e.out; then
        t_pass "validate-pack.py --only-check 86 exits 0; Check 86 runs and SKIPs lenient on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 86 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check86-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check86-e2e.out)"
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
