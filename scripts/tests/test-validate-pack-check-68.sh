#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-68.sh — synthetic fixture tests for
# BD-243 Check 68 (Gate 3: dangling-reference gate;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 3).
#
# Check 68 extracts file/path references (backtick bare-ref, markdown
# hyperlink, and the NEW qualified-path backtick) from the operating-doc IN set
# + the deliverable surface, and FAILs on any reference whose target does not
# exist — a dead pointer. A ref resolves via direct path / basename index; an
# anchor-windowed ("archived"/"does not exist") ref is intentional non-
# existence (auto-cleared); else the pack-ops/.dangling-ref-allowlist.txt
# (token-keyed) must clear it.
#
# AUTHORED-UNREGISTERED at CG-14-prep-b: the check BODY + pattern + allowlist
# ship now, but Check 68 is NOT in CHECK_REGISTRY (the count stays 63); CG-14
# registers it. `--only-check 68` CANNOT reach an unregistered check, so this
# test exercises Check 68's BODY IN-PROCESS against (a) synthetic /tmp trees and
# (b) the live tree, and asserts that 68 is NOT yet in the registry while the
# count invariant holds DYNAMICALLY (never a hardcoded literal).
#
# Test infra is self-provisioned (synthetic /tmp REPO_ROOT). Cleanup on every
# exit path.
#
# Coverage:
#   Group 0: Module import + Check 68 symbols + dynamic count-invariant +
#            Check 68 NOT yet registered
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a ref that resolves (target exists) PASSES
#            T2 a dangling ref cleared by an anchor phrase ("archived") PASSES
#            T3 a dangling ref cleared by an allowlist token PASSES
#            T4 a dangling ref NOT cleared FAILS (the teeth)
#            T5 a qualified-path dangling ref NOT cleared FAILS (the new axis)
#   Group 2: Live-tree in-process body invocation PASSES (0 dangling outside
#            the allowlist; the dangling-ref fix landed) — NOT `--only-check 68`
#
# Usage: bash scripts/tests/test-validate-pack-check-68.sh

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
# Group 0: Module import + symbols + dynamic count-invariant +
#          Check 68 authored-UNREGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 68 symbols + authored-unregistered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_dangling_file_refs', '_check_68_load_allowlist',
            '_CHECK_68_QUALIFIED_PATH_PATTERN', '_CHECK_68_INCLUDE_TREES',
            '_CHECK_68_EXCLUDE_PREFIXES', '_build_basename_index',
            '_strip_code_blocks', '_CHECK_40_ANCHOR_PHRASES']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 68 in nums:
    print('FAIL_68_REGISTERED_TOO_EARLY — CG-14-prep-b keeps Check 68 '
          'authored-unregistered (count stays 63); registration is CG-14');
    sys.exit(1)
print('OK')
" > /tmp/vp-check68-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check68-import.out; then
    t_pass "imports + Check 68 symbols present + count invariant holds (dynamic) + Check 68 authored-UNREGISTERED (68 not in registry)"
else
    t_fail "Check 68 import / symbol / count / unregistered-state check failed" \
        "$(cat /tmp/vp-check68-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic-tree end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_in_tree(builder, allowlist_text):
    """Build a synthetic /tmp REPO_ROOT, monkeypatch the scope to ONE include
    tree 'docs' (and the operating-doc families to nothing), run the body,
    restore, return (fails, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check68-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    builder(root)
    if allowlist_text:
        (root / "pack-ops" / ".dangling-ref-allowlist.txt").write_text(allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_inc = mod._CHECK_68_INCLUDE_TREES
    saved_fams = mod._CHECK_OPERATING_DOC_FAMILIES
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    mod._CHECK_68_INCLUDE_TREES = ("docs",)
    mod._CHECK_OPERATING_DOC_FAMILIES = ()   # only the include tree is scope
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dangling_file_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod._CHECK_68_INCLUDE_TREES = saved_inc
        mod._CHECK_OPERATING_DOC_FAMILIES = saved_fams
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — a ref that resolves (the target file exists in the tree).
def b1(root):
    (root / "docs").mkdir()
    (root / "docs" / "real-target.md").write_text("the target exists\n")
    (root / "docs" / "citer.md").write_text("see \`real-target.md\` for details\n")
fc, cap = run_check_in_tree(b1, "")
if fc != 0:
    failures.append("T1 (resolving ref PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "complete" not in cap:
    failures.append("T1 (resolving ref PASS) expected the complete OK message: %s" % cap)

# T2: PASS — a dangling ref cleared by an anchor phrase ("archived").
def b2(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("from the now-archived \`OLD-DOC.md\` (removed)\n")
fc, cap = run_check_in_tree(b2, "")
if fc != 0:
    failures.append("T2 (anchor-cleared PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "anchor-cleared" not in cap:
    failures.append("T2 (anchor-cleared PASS) expected 'anchor-cleared' in output: %s" % cap)

# T3: PASS — a dangling ref cleared by an allowlist token.
def b3(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("the per-entry grammar is \`BD-NNN.md\`\n")
ALLOW = "token: BD-NNN.md\nreason: grammar placeholder (synthetic).\n"
fc, cap = run_check_in_tree(b3, ALLOW)
if fc != 0:
    failures.append("T3 (allowlisted-token PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "allowlisted" not in cap:
    failures.append("T3 (allowlisted-token PASS) expected 'allowlisted' in output: %s" % cap)

# T4: FAIL — a dangling bare ref NOT cleared (the teeth).
def b4(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("see \`MISSING-DOC.md\` for details\n")
fc, cap = run_check_in_tree(b4, "")
if fc < 1:
    failures.append("T4 (dangling bare FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "dangling reference" not in cap:
    failures.append("T4 (dangling bare FAIL) expected the dangling FAIL message: %s" % cap)
if "MISSING-DOC.md" not in cap:
    failures.append("T4 (dangling bare FAIL) expected the offending token in output: %s" % cap)

# T5: FAIL — a dangling QUALIFIED-path ref NOT cleared (the new axis: the
#     bare-ref pattern's /-exclusion would miss this; the qualified pattern
#     catches it).
def b5(root):
    (root / "docs").mkdir()
    (root / "docs" / "citer.md").write_text("removed \`pack-ops/GONE-DOC.md\` here\n")
fc, cap = run_check_in_tree(b5, "")
if fc < 1:
    failures.append("T5 (dangling qualified FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "pack-ops/GONE-DOC.md" not in cap:
    failures.append("T5 (dangling qualified FAIL) expected the qualified-path token in output: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T5 (resolving / anchor-cleared / allowlisted / dangling-bare-FAIL / dangling-qualified-FAIL)" ;;
    *) t_fail "Synthetic-tree check_dangling_file_refs tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (NOT --only-check 68)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Live-tree in-process body invocation ===\n"

python3 -c "
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_dangling_file_refs()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_DANGLING')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'complete' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check68-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check68-live.out; then
    t_pass "Check 68 body runs clean on the live tree (0 dangling ref outside the allowlist; the dangling-ref fix landed)"
else
    t_fail "Check 68 body found a dangling ref outside the allowlist on the live tree OR no clean message" \
        "$(tail -25 /tmp/vp-check68-live.out)"
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
