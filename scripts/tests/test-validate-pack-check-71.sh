#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-71.sh — synthetic fixture tests for
# BD-243 Check 71 (pack-root skill-mirror byte-identity;
# DESIGN-BD-243-SKILL-MIRROR-UNIFICATION.md §5.3).
#
# Check 71 compares the BYTES of each pack skill's `.codex/skills/<s>/SKILL.md`
# and `.agents/skills/<s>/SKILL.md` against the canonical
# `.claude/skills/<s>/SKILL.md`. THE TEETH: any byte-difference (or a missing /
# extra mirror file) FAILs. NO allowlist — byte-identity is absolute. The
# canonical is `.claude/skills` (index 0 of _CHECK_71_SKILL_MIRROR_DIRS). The
# property is byte-identity because pack SKILLS share ONE format across all 3
# CLIs (the WRONG property for agents — 3 formats — which use Check 11/56).
#
# REGISTERED at CG-14: the check BODY + constant plus the CHECK_REGISTRY entry
# are all live, so Check 71 IS in CHECK_REGISTRY (the count is 69). This test
# exercises Check 71's BODY by calling the function IN-PROCESS against
# (a) synthetic /tmp trees and (b) the live tree, and asserts that 71 IS in the
# registry while the count invariant holds DYNAMICALLY (never a hardcoded
# literal). The Group-0 `71 in nums` assertion verifies the registration landed.
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real skill mirror is mutated. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 71 symbols + canonical[0]==.claude/skills +
#            dynamic count-invariant + Check 71 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1 three byte-identical mirrors PASS
#            T2 a mirror byte-DIFFERS from the canonical → FAIL (the byte-differ
#               injected-FAIL teeth)
#            T3 a MISSING mirror file → FAIL
#            T4 an EXTRA orphan mirror skill (canonical lacks it) → FAIL
#            T5 a WHOLLY-ABSENT mirror tree → lenient SKIP (init artifact)
#   Group 2: Live-tree in-process body invocation PASSES (CB-04 unified the 3
#            pack-root skill mirrors byte-identical) — exercised via the
#            in-process body call (Check 71's clean live-tree run is also
#            covered by the full no-flag validate-pack now that it is registered)
#
# Usage: bash scripts/tests/test-validate-pack-check-71.sh

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
# Group 0: Module import + symbols + canonical + dynamic count-invariant +
#          Check 71 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 71 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_pack_skill_mirror_identity', '_CHECK_71_SKILL_MIRROR_DIRS']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# canonical is .claude/skills at index 0; the 2 mirrors follow.
dirs = mod._CHECK_71_SKILL_MIRROR_DIRS
if dirs[0] != '.claude/skills' or len(dirs) != 3:
    print('FAIL_DIRS', dirs); sys.exit(1)
if tuple(dirs) != ('.claude/skills', '.codex/skills', '.agents/skills'):
    print('FAIL_DIRS_VALUE', dirs); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-62/63).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 71 is REGISTERED at CG-14: 71 must be in the registry (count 69).
nums = [t[0] for t in mod._build_check_registry()]
if 71 not in nums:
    print('FAIL_71_NOT_REGISTERED — CG-14 registers Check 71 in '
          'CHECK_REGISTRY (count 63 -> 69)');
    sys.exit(1)
print('OK')
" > /tmp/vp-check71-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check71-import.out; then
    t_pass "imports + Check 71 symbols present + canonical[0]==.claude/skills + count invariant holds (dynamic) + Check 71 REGISTERED (71 in registry)"
else
    t_fail "Check 71 import / symbol / dirs / count / registered-state check failed" \
        "$(cat /tmp/vp-check71-import.out)"
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
    submodule (BD-256 W2 wave-invariant). check_pack_skill_mirror_identity now
    lives in validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT;
    a facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

CANON, CODEX, AGENTS = ".claude/skills", ".codex/skills", ".agents/skills"

def run_check_in_tree(skills, drop_trees=(), mutate=None):
    """Build a synthetic /tmp REPO_ROOT with the 3 skill-mirror trees, write
    each skill's SKILL.md byte-identical across all 3 mirrors (the canonical
    content), then apply optional perturbations:
      drop_trees: a tuple of mirror dir rels to NOT create (lenient-absent leg);
      mutate(root): a callback run after the identical write to inject a
                    byte-differ / missing file / orphan skill.
    Runs check_pack_skill_mirror_identity, restores, returns (fails, captured).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check71-")
    root = pathlib.Path(tmpdir)
    trees = [CANON, CODEX, AGENTS]
    for tree in trees:
        if tree in drop_trees:
            continue
        for name, body in skills.items():
            d = root / tree / name
            d.mkdir(parents=True)
            (d / "SKILL.md").write_text(body)
    if mutate is not None:
        mutate(root)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_pack_skill_mirror_identity()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

SKILLS = {
    "alpha": "# alpha skill\n\nbody bytes.\n",
    "beta": "# beta skill\n\nother body.\n",
}

# T1: PASS — all 3 mirrors byte-identical for every skill.
fc, cap = run_check_in_tree(SKILLS)
if fc != 0:
    failures.append("T1 (byte-identical PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "0 divergent (complete)" not in cap:
    failures.append("T1 (byte-identical PASS) expected the clean message: %s" % cap)

# T2: FAIL (the byte-differ injected-FAIL teeth) — mutate one mirror file so it
#     byte-DIFFERS from the canonical, then assert FAIL; the harness restores
#     the tree by tearing down the whole /tmp dir.
def mutate_byte_differ(root):
    (root / CODEX / "beta" / "SKILL.md").write_text("# beta skill\n\nTAMPERED body.\n")
fc, cap = run_check_in_tree(SKILLS, mutate=mutate_byte_differ)
if fc < 1:
    failures.append("T2 (byte-differ FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "byte-DIVERGES from" not in cap:
    failures.append("T2 (byte-differ FAIL) expected the byte-divergence FAIL message: %s" % cap)
if ".codex/skills/beta/SKILL.md" not in cap:
    failures.append("T2 (byte-differ FAIL) expected the divergent mirror path in output: %s" % cap)

# T3: FAIL — a MISSING mirror file (canonical has it; a mirror lacks it).
def mutate_missing(root):
    (root / AGENTS / "alpha" / "SKILL.md").unlink()
fc, cap = run_check_in_tree(SKILLS, mutate=mutate_missing)
if fc < 1:
    failures.append("T3 (missing-mirror FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "MISSING mirror file" not in cap:
    failures.append("T3 (missing-mirror FAIL) expected the missing-file FAIL message: %s" % cap)

# T4: FAIL — an EXTRA orphan mirror skill the canonical lacks.
def mutate_orphan(root):
    d = root / CODEX / "gamma"
    d.mkdir(parents=True)
    (d / "SKILL.md").write_text("# orphan skill not in canonical\n")
fc, cap = run_check_in_tree(SKILLS, mutate=mutate_orphan)
if fc < 1:
    failures.append("T4 (orphan-skill FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "EXTRA mirror skill" not in cap:
    failures.append("T4 (orphan-skill FAIL) expected the extra-skill FAIL message: %s" % cap)

# T5: lenient SKIP — a WHOLLY-ABSENT mirror tree (.agents/skills not created).
#     The present mirror (.codex) is still identical, so the result is CLEAN
#     with a lenient-skip note (not a failure).
fc, cap = run_check_in_tree(SKILLS, drop_trees=(AGENTS,))
if fc != 0:
    failures.append("T5 (absent-mirror-tree lenient SKIP) expected 0 failures, got %d: %s" % (fc, cap))
if "tree absent — skipping that mirror (lenient" not in cap:
    failures.append("T5 (absent-mirror-tree lenient SKIP) expected the lenient-skip message: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T5 (byte-identical-PASS / byte-differ-FAIL / missing-mirror-FAIL / orphan-skill-FAIL / absent-tree-lenient-SKIP)" ;;
    *) t_fail "Synthetic-tree check_pack_skill_mirror_identity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (via the body call, not
#          --only-check 71)
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
    mod.check_pack_skill_mirror_identity()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_DIVERGENT')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if '0 divergent (complete)' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check71-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check71-live.out; then
    t_pass "Check 71 body runs clean on the live tree (CB-04 unified the 3 pack-root skill mirrors byte-identical)"
else
    t_fail "Check 71 body found a divergent mirror on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check71-live.out)"
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
