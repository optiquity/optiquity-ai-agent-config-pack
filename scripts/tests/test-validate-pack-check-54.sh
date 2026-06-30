#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-54.sh — dedicated test for
# BD-197 Check 54 (OPTIONAL-FEATURES presence-check, Guard-A′).
#
# Check 54 is the POSITIVE inverse of Guard-A (Check 53): it asserts BOTH
# OPTIONAL-FEATURES surfaces (`pack-ops/OPTIONAL-FEATURES.md` from C5 +
# `project-template/docs/pack/OPTIONAL-FEATURES.md` from C8a) each mention the
# MANDATED three tokens — `baseRef`, `bgIsolation`, and the `permissions.deny`
# recipe token (user-approved 2026-06-14; BD-197 Note 14; design §13.1a /
# §11.5 gate (b)). This keeps the un-prohibited worktree-isolation feature +
# its in-session backstop recipe DOCUMENTED on both surfaces.
#
# This test proves the guard PASSes when all three tokens are present in BOTH
# files, and FAILs when ANY token is missing from EITHER file — exercised in a
# synthetic /tmp tree (it NEVER mutates the real tree). It also confirms the
# measure-then-bound sizing (exactly 3 tokens × 2 files; the prose `isolation`
# param is NOT folded in).
#
# Coverage:
#   Group 0: module import + Check 54 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            A  PASS — all 3 tokens present in BOTH files
#            B  FAIL — `permissions.deny` missing from the PACK file
#            C  FAIL — `permissions.deny` missing from the PROJECT file
#            D  FAIL — `baseRef` missing from the PACK file
#            E  FAIL — `bgIsolation` missing from the PROJECT file
#            F  FAIL — a surface file is absent entirely
#            G  PASS — token set is sized to exactly the 3 keys (a file with
#                      the 3 tokens but WITHOUT the prose `isolation` param
#                      still PASSes — the param is deliberately NOT asserted)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 54 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-54.sh

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
printf "\n=== Group 0: Module import + Check 54 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_optional_features_presence',
    '_CHECK_54_OPTIONAL_FEATURES_SURFACES',
    '_CHECK_54_REQUIRED_TOKENS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
# Assert the measure-then-bound sizing: exactly 3 tokens × 2 surfaces.
toks = tuple(mod._CHECK_54_REQUIRED_TOKENS)
surfs = tuple(mod._CHECK_54_OPTIONAL_FEATURES_SURFACES)
if toks != ('baseRef', 'bgIsolation', 'permissions.deny'):
    print('FAIL_TOKENS ' + repr(toks))
    sys.exit(1)
if surfs != ('pack-ops/OPTIONAL-FEATURES.md',
             'project-template/docs/pack/OPTIONAL-FEATURES.md'):
    print('FAIL_SURFACES ' + repr(surfs))
    sys.exit(1)
print('OK')
" > /tmp/vp-check54-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check54-import.out; then
    t_pass "validate-pack.py imports + Check 54 symbols registered + sized to 3 tokens × 2 surfaces"
else
    t_fail "validate-pack.py import / Check 54 symbol registration / sizing failed" \
        "$(cat /tmp/vp-check54-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + missing-token-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W3 wave-invariant). The check body now lives in
    validate_checks.discipline_parity and reads discipline_parity.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

PACK = "pack-ops/OPTIONAL-FEATURES.md"
PROJ = "project-template/docs/pack/OPTIONAL-FEATURES.md"

# Content carrying all 3 tokens (baseRef, bgIsolation, permissions.deny) plus
# the prose isolation param (which is deliberately NOT asserted by the guard).
ALL3 = (
    "Set worktree.baseRef to head. worktree.bgIsolation gates background "
    "sessions. The permissions.deny recipe is the in-session backstop. "
    'Pass isolation:"worktree" per spawn.\n'
)

def run(build):
    """build(root) populates a synthetic tree; return (n_failures, output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check54-")
    root = pathlib.Path(tmpdir)
    build(root)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_optional_features_presence()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

def w(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)

# A: all 3 tokens present in BOTH files -> PASS
def bA(root):
    w(root, PACK, ALL3)
    w(root, PROJ, ALL3)
n, cap = run(bA)
if n != 0:
    failures.append(f"A (all 3 tokens both files) expected PASS, got {n}: {cap}")

# B: permissions.deny missing from the PACK file -> FAIL (names the pack path + token)
def bB(root):
    w(root, PACK, "worktree.baseRef:head and worktree.bgIsolation only.\n")
    w(root, PROJ, ALL3)
n, cap = run(bB)
if n < 1 or PACK not in cap or "permissions.deny" not in cap:
    failures.append(f"B (permissions.deny missing from PACK) expected FAIL naming {PACK}+token, got {n}: {cap}")

# C: permissions.deny missing from the PROJECT file -> FAIL (names the project path)
def bC(root):
    w(root, PACK, ALL3)
    w(root, PROJ, "worktree.baseRef:head and worktree.bgIsolation only.\n")
n, cap = run(bC)
if n < 1 or PROJ not in cap or "permissions.deny" not in cap:
    failures.append(f"C (permissions.deny missing from PROJECT) expected FAIL naming {PROJ}+token, got {n}: {cap}")

# D: baseRef missing from the PACK file -> FAIL
def bD(root):
    w(root, PACK, "worktree.bgIsolation gate; the permissions.deny recipe.\n")
    w(root, PROJ, ALL3)
n, cap = run(bD)
if n < 1 or PACK not in cap or "baseRef" not in cap:
    failures.append(f"D (baseRef missing from PACK) expected FAIL naming {PACK}+baseRef, got {n}: {cap}")

# E: bgIsolation missing from the PROJECT file -> FAIL
def bE(root):
    w(root, PACK, ALL3)
    w(root, PROJ, "worktree.baseRef:head; the permissions.deny recipe.\n")
n, cap = run(bE)
if n < 1 or PROJ not in cap or "bgIsolation" not in cap:
    failures.append(f"E (bgIsolation missing from PROJECT) expected FAIL naming {PROJ}+bgIsolation, got {n}: {cap}")

# F: a surface file is absent entirely -> FAIL (not found)
def bF(root):
    w(root, PACK, ALL3)
    # PROJ deliberately not written
n, cap = run(bF)
if n < 1 or PROJ not in cap or "not" not in cap:
    failures.append(f"F (PROJECT surface absent) expected FAIL naming {PROJ}, got {n}: {cap}")

# G: measure-then-bound — a file with all 3 tokens but WITHOUT the prose
# isolation param still PASSes (the param is NOT folded into the bounded check).
def bG(root):
    no_param = (
        "worktree.baseRef head; worktree.bgIsolation background gate; "
        "the permissions.deny recipe is the backstop.\n"
    )
    w(root, PACK, no_param)
    w(root, PROJ, no_param)
n, cap = run(bG)
if n != 0:
    failures.append(f"G (3 tokens, no isolation param -> still PASS) expected PASS, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests A/B/C/D/E/F/G (presence PASS + missing-token catch in EITHER file + absent-surface FAIL + measure-then-bound sizing)" ;;
    *) t_fail "End-to-end check_optional_features_presence tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 54 > /tmp/vp-check54-e2e.out 2>&1; then
    if grep -q "Check 54: BD-197 OPTIONAL-FEATURES presence-check" /tmp/vp-check54-e2e.out \
       && grep -q "Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds" /tmp/vp-check54-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 54 runs and reports presence-holds clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 54 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check54-e2e.out)"
    fi
else
    if grep -q "Check 54: BD-197 OPTIONAL-FEATURES presence-check" /tmp/vp-check54-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 54 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check54-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 54 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check54-e2e.out)"
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
