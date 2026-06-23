#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-66.sh — synthetic fixture tests for
# BD-243 Check 66 (Gate 1b: operating-doc bullet-concision gate;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 1b).
#
# Check 66 caps per-rule / per-bullet CHARACTER length over the bullet surface
# (the pack + project trinity memory-section bullets + PACK-MEMORY-RATIONALE.md
# rule bullets). A bullet over _CHECK_66_BULLET_CHAR_CAP and NOT covered by a
# pack-ops/.bullet-concision-allowlist.txt record FAILs. VOLUME only — the cap
# is a character count; it asserts nothing about meaning.
#
# REGISTERED at CG-14: the check BODY + constant + allowlist plus the
# CHECK_REGISTRY entry are all live, so Check 66 IS in CHECK_REGISTRY (the count
# is 69). This test exercises Check 66's BODY by calling the function IN-PROCESS
# against (a) synthetic /tmp trees and (b) the live tree, and asserts that 66
# IS in the registry while the count invariant holds DYNAMICALLY (never a
# hardcoded literal). The Group-0 `66 in nums` assertion verifies the
# registration landed.
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real bullet-surface file is mutated. Cleanup runs on every exit
# path.
#
# Coverage:
#   Group 0: Module import + Check 66 symbols + dynamic count-invariant +
#            Check 66 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a file whose bullets are all under the cap PASSES
#            T2 an over-cap bullet covered by an allowlist snippet PASSES
#            T3 an over-cap bullet NOT allowlisted FAILS (the teeth)
#            T4 a bullet exactly at the cap PASSES (cap is exclusive: > cap)
#   Group 2: Live-tree in-process body invocation PASSES (the real bullet
#            surface is clean: 0 over-cap outside the allowlist) — exercised
#            via the in-process body call (Check 66's clean run over the live
#            tree is also covered by the full no-flag validate-pack now that it
#            is registered)
#
# Usage: bash scripts/tests/test-validate-pack-check-66.sh

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
#          Check 66 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 66 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_operating_doc_bullet_concision', '_check_66_load_allowlist',
            '_check_66_iter_bullets', '_CHECK_66_BULLET_CHAR_CAP',
            '_CHECK_66_BULLET_SURFACE']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 66 not in nums:
    print('FAIL_66_NOT_REGISTERED — CG-14 registers Check 66 in '
          'CHECK_REGISTRY (count 63 -> 69)');
    sys.exit(1)
print('OK')
" > /tmp/vp-check66-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check66-import.out; then
    t_pass "imports + Check 66 symbols present + count invariant holds (dynamic) + Check 66 REGISTERED (66 in registry)"
else
    t_fail "Check 66 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check66-import.out)"
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

def run_check_in_tree(doc_body, allowlist_text, cap):
    """Build a synthetic /tmp REPO_ROOT with ONE bullet-surface file, an
    optional allowlist, and a monkeypatched cap; run the body; restore;
    return (fails, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check66-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    (root / "SYNTH.md").write_text(doc_body)
    if allowlist_text:
        (root / "pack-ops" / ".bullet-concision-allowlist.txt").write_text(allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_surface = mod._CHECK_66_BULLET_SURFACE
    saved_cap = mod._CHECK_66_BULLET_CHAR_CAP
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    mod._CHECK_66_BULLET_SURFACE = (("SYNTH.md", "## memory"),)
    mod._CHECK_66_BULLET_CHAR_CAP = cap
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_bullet_concision()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod._CHECK_66_BULLET_SURFACE = saved_surface
        mod._CHECK_66_BULLET_CHAR_CAP = saved_cap
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

HEADER = "# SYNTH\n\n## memory\n\n"
SHORT = "- **short rule.** a short bullet under any cap.\n"
# A long bullet built from a known bolded name + filler past the cap.
LONG_NAME = "- **mega rule.** "
LONG = LONG_NAME + ("x" * 200) + "\n"   # ~218 chars

# T1: PASS — all bullets under the cap.
fc, cap_out = run_check_in_tree(HEADER + SHORT + SHORT, "", 100)
if fc != 0:
    failures.append("T1 (under-cap PASS) expected 0 failures, got %d: %s" % (fc, cap_out))
if "0 = clean" not in cap_out:
    failures.append("T1 (under-cap PASS) expected '0 = clean' OK message: %s" % cap_out)

# T2: PASS — an over-cap bullet covered by an allowlist snippet.
ALLOW = "doc: SYNTH.md\nsnippet: - **mega rule.**\nreason: irreducible (synthetic).\n"
fc, cap_out = run_check_in_tree(HEADER + SHORT + LONG, ALLOW, 100)
if fc != 0:
    failures.append("T2 (over-cap allowlisted PASS) expected 0 failures, got %d: %s" % (fc, cap_out))
if "1 over-cap KEEP" not in cap_out:
    failures.append("T2 (over-cap allowlisted PASS) expected '1 over-cap KEEP' in output: %s" % cap_out)

# T3: FAIL — an over-cap bullet NOT allowlisted (the teeth).
fc, cap_out = run_check_in_tree(HEADER + SHORT + LONG, "", 100)
if fc < 1:
    failures.append("T3 (over-cap FAIL) expected >=1 failure, got %d: %s" % (fc, cap_out))
if "Gate 1b bullet over the" not in cap_out:
    failures.append("T3 (over-cap FAIL) expected the Gate-1b FAIL message: %s" % cap_out)
if "mega rule" not in cap_out:
    failures.append("T3 (over-cap FAIL) expected the offending bullet in output: %s" % cap_out)

# T4: PASS — a bullet exactly AT the cap passes (cap is exclusive: > cap FAILs).
exact_body = HEADER + "- **e.** "  # bolded name "- **e.** " then pad to exact cap
# build a bullet whose collapsed length == cap
prefix = "- **e.** "
target_cap = 60
pad = "y" * (target_cap - len(prefix))
exact = prefix + pad + "\n"
fc, cap_out = run_check_in_tree(HEADER + exact, "", target_cap)
if fc != 0:
    failures.append("T4 (exactly-at-cap PASS) expected 0 failures, got %d: %s" % (fc, cap_out))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T4 (under-cap / over-cap-allowlisted / over-cap-FAIL / exactly-at-cap)" ;;
    *) t_fail "Synthetic-tree check_operating_doc_bullet_concision tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not --only-check 66)
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
    mod.check_operating_doc_bullet_concision()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_OVER_CAP')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if '0 = clean' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check66-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check66-live.out; then
    t_pass "Check 66 body runs clean on the live bullet surface (0 over-cap outside the allowlist)"
else
    t_fail "Check 66 body found an over-cap bullet on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check66-live.out)"
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
