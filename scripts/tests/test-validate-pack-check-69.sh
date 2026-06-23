#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-69.sh — synthetic fixture tests for
# BD-243 Check 69 (Gate 4: operating-doc scope-completeness meta-check;
# DESIGN-BD-243-DURABLE-GATES.md §3 Gate 4 + §5).
#
# Check 69 walks the operating-doc-only trees and asserts every file is
# (i) family-globbed, (ii) EXEMPT, or (iii) on the frozen OUT-OF-FAMILY list —
# so a NEW operating doc cannot silently escape the content gates. It reads NO
# file bodies (path enumeration + set arithmetic).
#
# AUTHORED-UNREGISTERED at CG-14-prep-a: the check BODY + constants ship now,
# but Check 69 is NOT in CHECK_REGISTRY (the count stays 63); CG-14 registers
# it. Because `--only-check` resolves the selector against CHECK_REGISTRY,
# `--only-check 69` CANNOT reach an unregistered check (it returns a LOUD
# "unknown selector" FAIL). So — unlike the registered checks' tests — this
# test exercises Check 69's BODY by calling the function IN-PROCESS against
# (a) synthetic /tmp trees and (b) the live tree, and asserts that 69 is NOT
# yet in the registry while the count invariant holds DYNAMICALLY (never a
# hardcoded literal). CG-14 will flip the `69 not in nums` assertion to the
# positive form when it registers the check.
#
# Test infra is self-provisioned: every synthetic tree is built under a /tmp
# REPO_ROOT; no real operating-doc tree is mutated. Cleanup runs on every exit
# path.
#
# Coverage:
#   Group 0: Module import + Check 69 symbols + dynamic count-invariant +
#            Check 69 NOT yet registered (authored-unregistered; count == the
#            DYNAMIC CHECK_REGISTRY_EXPECTED_COUNT, no literal)
#   Group 1: Synthetic-tree end-to-end (in-process body invocation; each
#            synthetic tree is git-init-ed + its files staged because the scan
#            is git-TRACKED-only) —
#            T1 a tree whose only file is family-globbed PASSES (complete)
#            T2 an EXEMPT file (_intro.md) is covered, not failed
#            T3 an OUT-OF-FAMILY data file is covered, not failed
#            T4 an UNCOVERED stray doc FAILS (the teeth)
#            T5 JUNK-INJECTION ROBUSTNESS (DESIGN-BD-243-CHECK69-ENV-
#               ROBUSTNESS.md §4.2 — the executable guard): T5a an untracked
#               gitignored `.DS_Store` injected under a scanned tree → STAYS
#               CLEAN; T5b an untracked editor temp → STAYS CLEAN; T5c the SAME
#               stray file but TRACKED → still FAILS (control: the check is not
#               blind; T5a/b pass because the junk is UNTRACKED, not blind).
#   Group 2: Live-tree in-process body invocation PASSES (the real tree is
#            complete) — NOT `--only-check 69` (unregistered)
#   Group 3: git-unavailable / not-a-work-tree → lenient SKIP (the tracked-only
#            scan never hard-fails on a non-git environment; mirrors Check 63)
#
# Usage: bash scripts/tests/test-validate-pack-check-69.sh

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
#          Check 69 authored-UNREGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 69 symbols + authored-unregistered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_operating_doc_scope_completeness',
            '_CHECK_OPERATING_DOC_FAMILIES', '_CHECK_OPERATING_DOC_EXEMPT',
            '_CHECK_OPERATING_DOC_OUT_OF_FAMILY',
            '_CHECK_OPERATING_DOC_SCANNED_TREES',
            '_operating_doc_families', '_iter_operating_docs',
            '_operating_doc_is_exempt']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-62/63).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 69 is AUTHORED-UNREGISTERED at CG-14-prep-a: 69 must NOT be in the
# registry yet (count stays 63). CG-14 flips this to '69 in nums'.
nums = [t[0] for t in mod._build_check_registry()]
if 69 in nums:
    print('FAIL_69_REGISTERED_TOO_EARLY — CG-14-prep-a keeps Check 69 '
          'authored-unregistered (count stays 63); registration is CG-14');
    sys.exit(1)
print('OK')
" > /tmp/vp-check69-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check69-import.out; then
    t_pass "imports + Check 69 symbols present + count invariant holds (dynamic) + Check 69 authored-UNREGISTERED (69 not in registry)"
else
    t_fail "Check 69 import / symbol / count / unregistered-state check failed" \
        "$(cat /tmp/vp-check69-import.out)"
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

import subprocess

def _git_init_and_add(root):
    """Make the synthetic /tmp tree a git repo and TRACK its built files.

    Check 69 scans the git-TRACKED set (git ls-files) — not a raw rglob — so a
    synthetic tree MUST be a git work tree with its operating-doc files staged,
    or the check lenient-SKIPs (git ls-files non-zero). Junk files the test
    injects are deliberately NOT added (they stay untracked), which is exactly
    how the tracked-only scan ignores gitignored OS junk."""
    env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
           "HOME": str(root), "PATH": __import__("os").environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=env, check=True)

def run_check_in_tree(builder, scanned_trees, families, exempt, out_of_family,
                      post_add=None):
    """Build a synthetic /tmp REPO_ROOT, git-init + track its files, monkeypatch
    the Gate-4 surfaces, run check_operating_doc_scope_completeness, restore,
    return (fails, captured). post_add (optional) runs AFTER 'git add' so a
    test can inject UNtracked junk that the tracked-only scan must ignore."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check69-")
    root = pathlib.Path(tmpdir)
    builder(root)
    _git_init_and_add(root)
    if post_add is not None:
        post_add(root)

    saved_root = mod.REPO_ROOT
    saved_trees = mod._CHECK_OPERATING_DOC_SCANNED_TREES
    saved_fams = mod._CHECK_OPERATING_DOC_FAMILIES
    saved_exempt = mod._CHECK_OPERATING_DOC_EXEMPT
    saved_oof = mod._CHECK_OPERATING_DOC_OUT_OF_FAMILY
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    mod._CHECK_OPERATING_DOC_SCANNED_TREES = scanned_trees
    mod._CHECK_OPERATING_DOC_FAMILIES = families
    mod._CHECK_OPERATING_DOC_EXEMPT = exempt
    mod._CHECK_OPERATING_DOC_OUT_OF_FAMILY = out_of_family
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_scope_completeness()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod._CHECK_OPERATING_DOC_SCANNED_TREES = saved_trees
        mod._CHECK_OPERATING_DOC_FAMILIES = saved_fams
        mod._CHECK_OPERATING_DOC_EXEMPT = saved_exempt
        mod._CHECK_OPERATING_DOC_OUT_OF_FAMILY = saved_oof
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# A synthetic scope: ONE tree "docs", one family glob "docs/*_rules.md"
# (deliberately NARROW so an _intro.md is NOT family-globbed and falls through
# to the EXEMPT check — mirroring the real project stream-meta family
# "*/_rules.md" beside an EXEMPT "_intro.md"), EXEMPT "_intro.md",
# OUT-OF-FAMILY "docs/data.txt".
TREES = ("docs",)
FAMS = ("docs/*_rules.md",)
EXEMPT = ("_intro.md",)

# T1: PASS — the tree's only file is family-globbed (complete).
def b1(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# a family-globbed operating doc\n")
fc, cap = run_check_in_tree(b1, TREES, FAMS, EXEMPT, ())
if fc != 0:
    failures.append("T1 (family-globbed PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "0 uncovered" not in cap:
    failures.append("T1 (family-globbed PASS) expected '0 uncovered' OK message: %s" % cap)

# T2: PASS — an EXEMPT file (_intro.md), NOT caught by the narrow family glob,
#     falls through to the EXEMPT check and is covered, not failed.
def b2(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# family\n")
    (root / "docs" / "_intro.md").write_text("# human orientation\n")
fc, cap = run_check_in_tree(b2, TREES, FAMS, EXEMPT, ())
if fc != 0:
    failures.append("T2 (EXEMPT covered PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "1 EXEMPT" not in cap:
    failures.append("T2 (EXEMPT covered) expected '1 EXEMPT' in output: %s" % cap)

# T3: PASS — an OUT-OF-FAMILY data file is covered, not failed.
def b3(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# family\n")
    (root / "docs" / "data.txt").write_text("not an operating doc\n")
fc, cap = run_check_in_tree(b3, TREES, FAMS, EXEMPT, ("docs/data.txt",))
if fc != 0:
    failures.append("T3 (OUT-OF-FAMILY covered PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "1 out-of-family" not in cap:
    failures.append("T3 (OUT-OF-FAMILY covered) expected '1 out-of-family' in output: %s" % cap)

# T4: FAIL — an UNCOVERED stray doc (not family / EXEMPT / out-of-family) FAILS.
def b4(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# family\n")
    (root / "docs" / "STRAY.txt").write_text("an uncovered stray file\n")
fc, cap = run_check_in_tree(b4, TREES, FAMS, EXEMPT, ())
if fc < 1:
    failures.append("T4 (uncovered stray FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "NEITHER family-globbed NOR EXEMPT NOR" not in cap:
    failures.append("T4 (uncovered stray FAIL) expected the remediation message in output: %s" % cap)
if "docs/STRAY.txt" not in cap:
    failures.append("T4 (uncovered stray FAIL) expected the offending path in output: %s" % cap)

# ── JUNK-INJECTION ROBUSTNESS (DESIGN-BD-243-CHECK69-ENV-ROBUSTNESS.md §4.2) ──
# The single highest-leverage prevention: assert robustness, do NOT inherit it
# from a clean env. The tracked-only scan must IGNORE an UNTRACKED/gitignored
# junk file under a scanned tree. T5 builds the SAME complete tree as T1
# (family-globbed only — should be CLEAN), then injects an UNtracked .DS_Store
# (and a .gitignore ignoring it) AFTER git add, and asserts Check 69 STAYS
# CLEAN. Under the OLD raw-rglob scan this would FAIL (the junk is an uncovered
# stray); under tracked-only it is invisible. This Group is Check 69's executable
# guard against the green-CI / red-local env trap.

# T5a: a gitignored .DS_Store injected AFTER git add (untracked) — Check 69
#      must stay CLEAN (the junk is never in the tracked set).
def b5(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# a family-globbed operating doc\n")
def inject_dsstore(root):
    (root / ".gitignore").write_text(".DS_Store\n")  # untracked too (added after git add)
    (root / "docs" / ".DS_Store").write_bytes(b"\x00\x01junk")  # binary OS junk, untracked
fc, cap = run_check_in_tree(b5, TREES, FAMS, EXEMPT, (), post_add=inject_dsstore)
if fc != 0:
    failures.append("T5a (junk-injection robustness) expected 0 failures with an UNtracked .DS_Store injected, got %d: %s" % (fc, cap))
if "0 uncovered" not in cap:
    failures.append("T5a (junk-injection robustness) expected '0 uncovered' (clean) with junk present: %s" % cap)
if ".DS_Store" in cap:
    failures.append("T5a (junk-injection robustness) the untracked .DS_Store leaked into the scan output (tracked-only scan must never see it): %s" % cap)

# T5b: an untracked editor temp file (STRAY.txt~) injected AFTER git add —
#      ALSO must be ignored (the guard is not .DS_Store-specific; it is the
#      tracked-only property that excludes ALL untracked junk).
def inject_tmp(root):
    (root / "docs" / "STRAY.txt~").write_text("editor temp, untracked\n")
fc, cap = run_check_in_tree(b5, TREES, FAMS, EXEMPT, (), post_add=inject_tmp)
if fc != 0:
    failures.append("T5b (junk-injection: untracked editor temp) expected 0 failures, got %d: %s" % (fc, cap))
if "0 uncovered" not in cap:
    failures.append("T5b (junk-injection: untracked editor temp) expected '0 uncovered' (clean): %s" % cap)

# T5c (CONTROL): the SAME stray file, but TRACKED (git add-ed), MUST still FAIL —
#      proving T5a/T5b pass because the junk is UNTRACKED, not because the check
#      went blind. A tracked uncovered file is a real completeness violation.
def b5c(root):
    (root / "docs").mkdir()
    (root / "docs" / "stream_rules.md").write_text("# family\n")
    (root / "docs" / "STRAY.txt").write_text("a TRACKED uncovered stray file\n")
fc, cap = run_check_in_tree(b5c, TREES, FAMS, EXEMPT, ())  # no post_add → STRAY is tracked
if fc < 1:
    failures.append("T5c (CONTROL: TRACKED uncovered stray) expected >=1 failure (the check is not blind), got %d: %s" % (fc, cap))
if "docs/STRAY.txt" not in cap:
    failures.append("T5c (CONTROL) expected the tracked stray path in the FAIL output: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T5 (family-globbed / EXEMPT / OUT-OF-FAMILY / uncovered-stray-FAIL / junk-injection robustness T5a-c)" ;;
    *) t_fail "Synthetic-tree check_operating_doc_scope_completeness tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Live-tree in-process body invocation (NOT --only-check 69,
#          which is unreachable while Check 69 is unregistered)
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
    mod.check_operating_doc_scope_completeness()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE_INCOMPLETE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if '0 uncovered' not in cap or 'complete' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check69-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check69-live.out; then
    t_pass "Check 69 body runs clean on the live tree (every operating-doc-tree file covered; 0 uncovered)"
else
    t_fail "Check 69 body found uncovered file(s) on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check69-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: git-unavailable / not-a-work-tree → lenient SKIP
#          (the tracked-only scan never hard-fails on a non-git env)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: git-unavailable / not-a-work-tree → lenient SKIP ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# A /tmp REPO_ROOT that is NOT a git work tree (no git init). The tracked-only
# scan's git ls-files returns non-zero → lenient SKIP, never a FAIL.
tmpdir = tempfile.mkdtemp(prefix="vp-check69-nogit-")
root = pathlib.Path(tmpdir)
(root / "docs").mkdir()
(root / "docs" / "STRAY.txt").write_text("uncovered, but no git → lenient skip\n")

saved_root = mod.REPO_ROOT
saved_trees = mod._CHECK_OPERATING_DOC_SCANNED_TREES
saved_failures = list(mod.failures); mod.failures.clear()
mod.REPO_ROOT = root
mod._CHECK_OPERATING_DOC_SCANNED_TREES = ("docs",)
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_operating_doc_scope_completeness()
    fails = list(mod.failures)
    cap = buf.getvalue()
finally:
    mod.REPO_ROOT = saved_root
    mod._CHECK_OPERATING_DOC_SCANNED_TREES = saved_trees
    mod.failures.clear(); mod.failures.extend(saved_failures)
    shutil.rmtree(tmpdir, ignore_errors=True)

if fails:
    print("FAIL_NOT_LENIENT — git-unavailable env produced a failure:", fails); sys.exit(1)
if "lenient" not in cap:
    print("FAIL_NO_LENIENT_MSG — expected a lenient-skip message:", cap); sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "git-unavailable / not-a-work-tree → lenient SKIP (no hard-fail; mirrors Check 63)" ;;
    *) t_fail "Check 69 lenient-mode (git-unavailable) test failed (see Python output)" ;;
esac

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
