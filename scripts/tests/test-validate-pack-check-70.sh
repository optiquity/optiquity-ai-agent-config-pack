#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-70.sh — synthetic fixture tests for
# BD-243 Check 70 (parity: shipped client doc-gate structural parity;
# DESIGN-BD-243-CLIENT-GATE.md §C.3 + PLAN-BD-243-FINAL-V4.md §3.3).
#
# Check 70 asserts the SHIPPED client operating-doc enforcement gate
# `project-template/scripts/validate-docs.sh` (a) EXISTS, (b) is executable,
# (c) declares all 4 axis-markers (`# AXIS: history|deferred|bloat|dangling`),
# and (d) is wired into the shipped `validate.sh` + `agent-post-edit-check.sh`.
# STRUCTURAL parity only (presence / executable / axis-coverage / wiring), NOT
# behavioral. It is a PACK check that READS the project-template deliverable to
# police it (the legitimate dependency direction).
#
# REGISTERED at CG-14: the check BODY + constants plus the CHECK_REGISTRY entry
# are all live, so Check 70 IS in CHECK_REGISTRY (the count is 69). This test
# exercises Check 70's BODY by calling the function IN-PROCESS against
# (a) synthetic /tmp trees and (b) the live tree, and asserts that 70 IS in the
# registry while the count invariant holds DYNAMICALLY (never a hardcoded
# literal). The Group-0 `70 in nums` assertion verifies the registration landed.
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real client gate is mutated. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 70 symbols + dynamic count-invariant +
#            Check 70 REGISTERED (count == the DYNAMIC
#            CHECK_REGISTRY_EXPECTED_COUNT, no literal)
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 a complete gate (executable + 4 axes + wired ×2) PASSES
#            T2 a gate MISSING an axis-marker FAILS (the injected-FAIL teeth)
#            T3 a NON-executable gate FAILS
#            T4 a gate NOT wired into a host FAILS
#            T5 a WHOLLY-ABSENT gate file → lenient SKIP (init artifact)
#   Group 2: Live-tree in-process body invocation PASSES (CG-CLIENT's real gate
#            exists + executable + 4 axes + wired) — exercised via the
#            in-process body call (Check 70's clean live-tree run is also
#            covered by the full no-flag validate-pack now that it is registered)
#
# Usage: bash scripts/tests/test-validate-pack-check-70.sh

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
#          Check 70 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 70 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_client_doc_gate_parity', '_CHECK_70_CLIENT_GATE',
            '_CHECK_70_AXIS_MARKERS', '_CHECK_70_WIRING_FILES']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# 4 axis-markers exactly (the 4 client axes).
if len(mod._CHECK_70_AXIS_MARKERS) != 4:
    print('FAIL_AXIS_COUNT', mod._CHECK_70_AXIS_MARKERS); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-62/63).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 70 is REGISTERED at CG-14: 70 must be in the registry (count 69).
nums = [t[0] for t in mod._build_check_registry()]
if 70 not in nums:
    print('FAIL_70_NOT_REGISTERED — CG-14 registers Check 70 in '
          'CHECK_REGISTRY (count 63 -> 69)');
    sys.exit(1)
print('OK')
" > /tmp/vp-check70-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check70-import.out; then
    t_pass "imports + Check 70 symbols present + 4 axis-markers + count invariant holds (dynamic) + Check 70 REGISTERED (70 in registry)"
else
    t_fail "Check 70 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check70-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic-tree end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, os, stat
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# A complete synthetic gate carrying all 4 axis-markers + the two wiring hosts
# referencing the gate by basename. The synthetic scope mirrors the real
# constants (validate-docs.sh + validate.sh + agent-post-edit-check.sh) so the
# body's existence/executable/axis/wiring legs all exercise.
GATE_REL = "project-template/scripts/validate-docs.sh"
WIRING = ("project-template/scripts/validate.sh",
          "project-template/scripts/agent-post-edit-check.sh")
ALL_AXES = "# AXIS: history\n# AXIS: deferred\n# AXIS: bloat\n# AXIS: dangling\n"

def run_check_in_tree(gate_body, executable, wiring_bodies):
    """Build a synthetic /tmp REPO_ROOT with a validate-docs.sh gate (optional)
    + the two wiring hosts, run check_client_doc_gate_parity, restore, return
    (fails, captured). gate_body=None omits the gate file (lenient-absent leg);
    executable toggles the gate's +x bit; wiring_bodies maps the wiring rel ->
    its content (omit a key to drop that host)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check70-")
    root = pathlib.Path(tmpdir)
    (root / "project-template" / "scripts").mkdir(parents=True)
    gate_path = root / GATE_REL
    if gate_body is not None:
        gate_path.write_text(gate_body)
        if executable:
            os.chmod(gate_path, os.stat(gate_path).st_mode | stat.S_IXUSR
                     | stat.S_IXGRP | stat.S_IXOTH)
        else:
            os.chmod(gate_path, 0o644)
    for rel, body in wiring_bodies.items():
        (root / rel).write_text(body)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_client_doc_gate_parity()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

WIRED_OK = {w: "run validate-docs.sh here\n" for w in WIRING}

# T1: PASS — a complete gate (executable + 4 axes + wired ×2).
fc, cap = run_check_in_tree("#!/usr/bin/env bash\n" + ALL_AXES, True, WIRED_OK)
if fc != 0:
    failures.append("T1 (complete gate PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "structural parity complete" not in cap:
    failures.append("T1 (complete gate PASS) expected the clean parity message: %s" % cap)

# T2: FAIL (the injected-FAIL teeth) — a gate MISSING an axis-marker.
missing_axis = "#!/usr/bin/env bash\n# AXIS: history\n# AXIS: deferred\n# AXIS: bloat\n"
fc, cap = run_check_in_tree(missing_axis, True, WIRED_OK)
if fc < 1:
    failures.append("T2 (missing-axis FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "missing axis-marker" not in cap:
    failures.append("T2 (missing-axis FAIL) expected the missing-axis FAIL message: %s" % cap)
if "# AXIS: dangling" not in cap:
    failures.append("T2 (missing-axis FAIL) expected the dropped axis named in output: %s" % cap)

# T3: FAIL — a non-executable gate (present + axes + wired but not +x).
fc, cap = run_check_in_tree("#!/usr/bin/env bash\n" + ALL_AXES, False, WIRED_OK)
if fc < 1:
    failures.append("T3 (non-executable FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "NOT executable" not in cap:
    failures.append("T3 (non-executable FAIL) expected the not-executable FAIL message: %s" % cap)

# T4: FAIL — a gate NOT wired into agent-post-edit-check.sh (the host exists but
#     does not reference the gate basename).
wiring_unwired = {WIRING[0]: "run validate-docs.sh here\n",
                  WIRING[1]: "# this host does not mention the gate\n"}
fc, cap = run_check_in_tree("#!/usr/bin/env bash\n" + ALL_AXES, True, wiring_unwired)
if fc < 1:
    failures.append("T4 (not-wired FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "NOT wired into this host" not in cap:
    failures.append("T4 (not-wired FAIL) expected the not-wired FAIL message: %s" % cap)
if "agent-post-edit-check.sh" not in cap:
    failures.append("T4 (not-wired FAIL) expected the unwired host named in output: %s" % cap)

# T5: lenient SKIP — a WHOLLY-ABSENT gate file (init artifact), no failure.
fc, cap = run_check_in_tree(None, True, WIRED_OK)
if fc != 0:
    failures.append("T5 (absent-gate lenient SKIP) expected 0 failures, got %d: %s" % (fc, cap))
if "absent — skipping (lenient" not in cap:
    failures.append("T5 (absent-gate lenient SKIP) expected the lenient-skip message: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T5 (complete-PASS / missing-axis-FAIL / non-executable-FAIL / not-wired-FAIL / absent-lenient-SKIP)" ;;
    *) t_fail "Synthetic-tree check_client_doc_gate_parity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not
#          --only-check 70)
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
    mod.check_client_doc_gate_parity()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_PARITY')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'structural parity complete' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check70-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check70-live.out; then
    t_pass "Check 70 body runs clean on the live tree (CG-CLIENT's validate-docs.sh exists + executable + 4 axes + wired)"
else
    t_fail "Check 70 body found a parity gap on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check70-live.out)"
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
