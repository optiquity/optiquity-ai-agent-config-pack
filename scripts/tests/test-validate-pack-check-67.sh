#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-67.sh — synthetic fixture tests for
# BD-243 Check 67 (Gate 2: operating-doc deferred-feature recall gate;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 2).
#
# Check 67 scans the operating-doc IN set (_iter_operating_docs) for deferred-
# feature markers (deferred / future version / coming soon / not-yet-created /
# once X lands|ships / roadmap / planned post / will ship / v11.1|v11.x /
# slated / expected to offer). A marker hit NOT cleared by a
# pack-ops/.operating-doc-deferred-feature-allowlist.txt record FAILs. A RECALL
# gate, not precision; the human adjudicates each hit.
#
# REGISTERED: the check BODY + patterns + allowlist plus the
# CHECK_REGISTRY entry are all live, so Check 67 IS in CHECK_REGISTRY. This test
# exercises Check 67's BODY IN-PROCESS against (a) synthetic
# /tmp trees and (b) the live tree, and asserts that 67 IS in the registry while
# the count invariant holds DYNAMICALLY (never a hardcoded literal).
#
# Test infra is self-provisioned (synthetic /tmp REPO_ROOT). Cleanup on every
# exit path.
#
# Coverage:
#   Group 0: Module import + Check 67 symbols + dynamic count-invariant +
#            Check 67 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a doc with no deferred marker PASSES
#            T2 a marker hit covered by an allowlist snippet PASSES
#            T3 a marker hit NOT allowlisted FAILS (the teeth)
#            T4 workflow prose ("not yet committed") does NOT match (bounded)
#   Group 2: Live-tree in-process body invocation PASSES (0 marker outside the
#            allowlist) — exercised via the in-process body call (Check 67's
#            clean live-tree run is also covered by the full no-flag
#            validate-pack now that it is registered)
#
# Usage: bash scripts/tests/test-validate-pack-check-67.sh

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
#          Check 67 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 67 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_operating_doc_no_deferred_feature', '_check_67_load_allowlist',
            '_CHECK_67_DEFERRED_PATTERNS', '_iter_operating_docs']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 67 not in nums:
    print('FAIL_67_NOT_REGISTERED — Check 67 must be in CHECK_REGISTRY');
    sys.exit(1)
print('OK')
" > /tmp/vp-check67-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check67-import.out; then
    t_pass "imports + Check 67 symbols present + count invariant holds (dynamic) + Check 67 REGISTERED (67 in registry)"
else
    t_fail "Check 67 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check67-import.out)"
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

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W2
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.boundary_refs; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

# A synthetic operating doc under a globbed family. We monkeypatch the families
# to a single narrow glob so the synthetic doc is the entire IN set.
SYNTH_DOC = "pack-ops/SYNTH-OPDOC.md"

def run_check_in_tree(doc_body, allowlist_text):
    tmpdir = tempfile.mkdtemp(prefix="vp-check67-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    (root / SYNTH_DOC).write_text(doc_body)
    if allowlist_text:
        (root / "pack-ops" / ".operating-doc-deferred-feature-allowlist.txt").write_text(allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_fams = mod._CHECK_OPERATING_DOC_FAMILIES
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    _patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", ("pack-ops/SYNTH-OPDOC.md",))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_no_deferred_feature()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_OPERATING_DOC_FAMILIES", saved_fams)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — no deferred marker.
fc, cap = run_check_in_tree("# SYNTH\n\nA forward-only operating doc.\n", "")
if fc != 0:
    failures.append("T1 (no marker PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "0 = clean" not in cap:
    failures.append("T1 (no marker PASS) expected '0 = clean' OK message: %s" % cap)

# T2: PASS — a marker hit cleared by an allowlist snippet.
body = "# SYNTH\n\nThe tracker integration is deferred until the API lands.\n"
ALLOW = "doc: %s\nsnippet: tracker integration is deferred\nreason: live workflow (synthetic).\n" % SYNTH_DOC
fc, cap = run_check_in_tree(body, ALLOW)
if fc != 0:
    failures.append("T2 (marker allowlisted PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "1 allowlisted" not in cap:
    failures.append("T2 (marker allowlisted PASS) expected '1 allowlisted' in output: %s" % cap)

# T3: FAIL — a marker hit NOT allowlisted (the teeth).
body = "# SYNTH\n\nThe android skill is deferred to a future version.\n"
fc, cap = run_check_in_tree(body, "")
if fc < 1:
    failures.append("T3 (marker FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "deferred-feature marker" not in cap:
    failures.append("T3 (marker FAIL) expected the deferred-feature FAIL message: %s" % cap)

# T4: PASS — bounded markers do NOT fire on ordinary workflow prose.
body = "# SYNTH\n\nThe change is not yet committed; review it as planned.\n"
fc, cap = run_check_in_tree(body, "")
if fc != 0:
    failures.append("T4 (bounded-marker no-false-positive) expected 0 failures on 'not yet committed'/'as planned', got %d: %s" % (fc, cap))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T4 (no-marker / allowlisted / marker-FAIL / bounded-no-false-positive)" ;;
    *) t_fail "Synthetic-tree check_operating_doc_no_deferred_feature tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not --only-check 67)
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
    mod.check_operating_doc_no_deferred_feature()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_MARKER_OUTSIDE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if '0 = clean' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check67-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check67-live.out; then
    t_pass "Check 67 body runs clean on the live tree (0 deferred-feature marker outside the allowlist)"
else
    t_fail "Check 67 body found a deferred-feature marker outside the allowlist on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check67-live.out)"
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
