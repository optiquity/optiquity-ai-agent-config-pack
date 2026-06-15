#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-53.sh — dedicated test for
# BD-197 Check 53 (worktree-isolation prohibition flip-block, Guard-A).
#
# Check 53 asserts the REMOVED worktree-isolation prohibition prose
# (`no worktree isolation` / `Do not pass ...isolation...worktree`) does
# NOT reappear in any ACTIVE pack surface. The matcher keys on the
# prohibition SIGNATURE only — NEVER the legitimate setting keys
# `baseRef`/`bgIsolation` (design §11.5 G-1/G-2). Allowlist (measure-then-
# bound) = the two process/history doc dirs (`maintenance-docs/archive/`,
# `maintenance-docs/v11-implementation/`) PLUS the NARROW self-exception
# (validator self-skip by name + ONLY the single check-53 test file).
#
# This test proves the guard PASSes on the well-formed tree and FAILs on an
# injected prohibition in an active surface (in a synthetic /tmp tree — it
# NEVER mutates the real tree), and proves the allowlist + self-skip behave
# exactly (narrow: a DIFFERENT scripts/tests file is NOT allowlisted).
#
# Coverage:
#   Group 0: module import + Check 53 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            A  FAIL — injected prohibition in an active surface (pack-ops doc)
#            A2 FAIL — the second matcher branch (Do not pass ...worktree)
#            B  PASS — same string in an allowlisted v11-implementation dir
#            B2 PASS — same string in the allowlisted archive dir
#            C  PASS — validator self-skip (a file named validate-pack.py)
#            D  PASS — the single check-53 test allowlisted by exact path
#            E  FAIL — NARROW: a DIFFERENT scripts/tests file is NOT allowed
#            F  PASS — baseRef/bgIsolation keys do NOT trip the matcher
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 53 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-53.sh

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
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 53 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_worktree_isolation_prohibition_flip_block',
    '_check_53_is_allowlisted',
    '_CHECK_53_PROHIBITION_PATTERNS',
    '_CHECK_53_ALLOWLIST_DIR_PREFIXES',
    '_CHECK_53_SELF_TEST_ALLOWLIST',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check53-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check53-import.out; then
    t_pass "validate-pack.py imports + Check 53 symbols registered"
else
    t_fail "validate-pack.py import or Check 53 symbol registration failed" \
        "$(cat /tmp/vp-check53-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run(build):
    """build(root) populates a synthetic tree; return (n_failures, output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check53-")
    root = pathlib.Path(tmpdir)
    build(root)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_worktree_isolation_prohibition_flip_block()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

def w(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)

# A: injected prohibition in an ACTIVE surface (pack-ops doc) -> FAIL
def bA(root): w(root, "pack-ops/SOME-RULE.md",
                "Spawn all sub-agents with no worktree isolation.\n")
n, cap = run(bA)
if n < 1 or "SOME-RULE.md" not in cap:
    failures.append(f"A (injected prohibition, active surface) expected FAIL, got {n}: {cap}")

# A2: the second matcher branch (Do not pass ...isolation...worktree) -> FAIL
def bA2(root): w(root, "pack-ops/X.md",
                 'Do not pass \`isolation:"worktree"\` to the Agent tool.\n')
n, cap = run(bA2)
if n < 1 or "X.md" not in cap:
    failures.append(f"A2 (second matcher branch) expected FAIL, got {n}: {cap}")

# B: same string in an ALLOWLISTED v11-implementation dir -> PASS
def bB(root): w(root, "maintenance-docs/v11-implementation/DESIGN.md",
                "documents the removed 'no worktree isolation' rule.\n")
n, cap = run(bB)
if n != 0:
    failures.append(f"B (allowlisted v11-implementation dir) expected PASS, got {n}: {cap}")

# B2: same string in the allowlisted archive dir -> PASS
def bB2(root): w(root, "maintenance-docs/archive/OLD.md",
                 "no worktree isolation (historical record)\n")
n, cap = run(bB2)
if n != 0:
    failures.append(f"B2 (allowlisted archive dir) expected PASS, got {n}: {cap}")

# C: validator self-skip — a file NAMED validate-pack.py with the regex -> PASS
def bC(root): w(root, "scripts/validate-pack.py",
                're.compile(r"no worktree isolation")\n')
n, cap = run(bC)
if n != 0:
    failures.append(f"C (validator self-skip) expected PASS, got {n}: {cap}")

# D: the single check-53 test allowlisted by EXACT path -> PASS
def bD(root): w(root, "scripts/tests/test-validate-pack-check-53.sh",
                "# asserts 'no worktree isolation'\n")
n, cap = run(bD)
if n != 0:
    failures.append(f"D (single check-53 test allowlisted) expected PASS, got {n}: {cap}")

# E: NARROW — a DIFFERENT scripts/tests file with the prohibition -> FAIL
def bE(root): w(root, "scripts/tests/some-other-test.sh",
                "# 'no worktree isolation' smuggled here\n")
n, cap = run(bE)
if n < 1 or "some-other-test.sh" not in cap:
    failures.append(f"E (NARROW: other scripts/tests file not allowlisted) expected FAIL, got {n}: {cap}")

# F: baseRef/bgIsolation keys do NOT trip the matcher (G-1/G-2) -> PASS
def bF(root): w(root, "pack-ops/FEAT.md",
                "Set worktree.baseRef:head; bgIsolation is the background gate.\n")
n, cap = run(bF)
if n != 0:
    failures.append(f"F (baseRef/bgIsolation keys do NOT trip matcher) expected PASS, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests A/A2/B/B2/C/D/E/F (injected-prohibition catch + allowlist + narrow self-exception + key-not-tripped)" ;;
    *) t_fail "End-to-end check_worktree_isolation_prohibition_flip_block tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 53 > /tmp/vp-check53-e2e.out 2>&1; then
    if grep -q "Check 53: BD-197 worktree-isolation prohibition flip-block" /tmp/vp-check53-e2e.out \
       && grep -q "Check 53 (Guard-A) — worktree-isolation prohibition stays removed" /tmp/vp-check53-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 53 runs and reports prohibition-stays-removed clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 53 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check53-e2e.out)"
    fi
else
    if grep -q "Check 53: BD-197 worktree-isolation prohibition flip-block" /tmp/vp-check53-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 53 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check53-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 53 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check53-e2e.out)"
    fi
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
