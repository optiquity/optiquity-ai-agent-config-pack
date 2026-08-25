#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-53.sh — dedicated test for
# BD-197 Check 53 (worktree-isolation prohibition flip-block, Guard-A).
#
# Check 53 asserts the REMOVED worktree-isolation prohibition prose
# (`no worktree isolation` / `Do not pass ...isolation...worktree`) AND the
# RETIRED isolated-agent placement-contract prose (the "then cd to the
# target tree" ritual / the literal `cd-REUSE` convention — Guard 1 per
# maintenance-docs/v11-implementation/ARCHITECTURE-BD-290.md §6) do NOT
# reappear in any ACTIVE pack surface. The matcher keys on the retired
# SIGNATURES only — NEVER the legitimate setting keys
# `baseRef`/`bgIsolation` (design §11.5 G-1/G-2). Allowlist (measure-then-
# bound) = the two process/history doc dirs (`maintenance-docs/archive/`,
# `maintenance-docs/v11-implementation/`) + the two record-stream trees
# (`backlog/`, `changelog/` — entry bodies quote retired text when recording
# removals) PLUS the NARROW self-exception (validator self-skip by name +
# ONLY the single check-53 test file).
#
# This test proves the guard PASSes on the well-formed tree and FAILs on an
# injected prohibition in an active surface (in a synthetic /tmp tree — it
# NEVER mutates the real tree), and proves the allowlist + self-skip behave
# exactly (narrow: a DIFFERENT scripts/tests file is NOT allowlisted).
#
# The synthetic tree is a THROWAWAY GIT REPO (`git init` + `git add -A` in
# /tmp), because Check 53 draws its candidate set from git-TRACKED files
# (`git ls-files`) per `ci-guard-measure-then-bound` — a raw filesystem walk
# would descend into live sub-agent worktrees under `.claude/worktrees/`.
# Untracked fixtures would make the check lenient-SKIP and the negative legs
# would pass vacuously. Same idiom as test-validate-pack-check-63.sh.
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
#            A3  FAIL — retired placement phrase, plain form (then cd to the
#                       target tree), FAIL text names pattern + file
#            A3b FAIL — the cd-s variant of the placement phrase
#            A4  FAIL — the literal cd-REUSE, FAIL text names pattern + file
#                (A3/A3b/A4 each carry a MUTATION leg: re-run with the
#                 pre-extension 2-pattern tuple must NOT fail — the FAIL text
#                 appears ONLY when the new pattern is live)
#            B3  PASS — the placement phrase in the backlog/ record stream
#            B4  PASS — cd-REUSE in the changelog/ record stream
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 53 clean)
#   Group 3: the two lenient-SKIP branches (git absent / not a work tree),
#            each pinned with a fixture that carries retired prose from BOTH
#            families (prohibition + placement-contract)
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
import sys, tempfile, pathlib, shutil, io, contextlib, subprocess
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
import validate_checks.discipline_parity as dp

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

def run(build):
    """build(root) populates a synthetic tree; return (n_failures, output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check53-")
    root = pathlib.Path(tmpdir)
    build(root)
    # Check 53's candidate set is the git-TRACKED file list, so the synthetic
    # tree must be a REAL throwaway git repo with the fixtures ADDED to the
    # index. Without this the check lenient-SKIPs off a non-git /tmp dir and
    # the negative legs (A/A2/E) would silently lose their teeth. Same
    # throwaway-scratch-repo idiom as
    # scripts/tests/test-validate-pack-check-63.sh. Never touches the real
    # tree. NOTE: this heredoc is UNQUOTED, so backticks would be command-
    # substituted by bash -- keep this block backtick-free.
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_worktree_isolation_prohibition_flip_block()
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

def run_with_patterns(build, patterns):
    """run(), but with the module-level pattern tuple temporarily replaced
    (the MUTATION leg: proving a FAIL comes from a specific pattern by
    re-running WITHOUT it). The check body resolves the tuple from the
    discipline_parity module globals, so patch it there."""
    saved = dp._CHECK_53_PROHIBITION_PATTERNS
    dp._CHECK_53_PROHIBITION_PATTERNS = tuple(patterns)
    try:
        return run(build)
    finally:
        dp._CHECK_53_PROHIBITION_PATTERNS = saved

# Mutation-leg precondition: the tuple's first two members are the original
# BD-197 prohibition patterns and the last two are the retired
# placement-contract patterns, so the [:2] slice below IS the pre-extension
# matcher set.
_srcs = tuple(p.pattern for p in dp._CHECK_53_PROHIBITION_PATTERNS)
if (len(_srcs) != 4
        or _srcs[0] != "no worktree isolation"
        or not _srcs[1].startswith("Do not pass")
        or "to the target tree" not in _srcs[2]
        or _srcs[3] != "cd-REUSE"):
    print("FAILURES")
    print("  pattern-tuple shape unexpected (mutation legs cannot anchor):",
          _srcs)
    sys.exit(1)
PRE_EXTENSION_PATTERNS = dp._CHECK_53_PROHIBITION_PATTERNS[:2]

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

# A3: retired placement phrase, PLAIN form, in an active surface -> FAIL,
# and the FAIL text must name the matched pattern + the file.
def bA3(root): w(root, "pack-ops/Y.md",
                 "spawn the reviewer in place, then cd to the target tree.\n")
n, cap = run(bA3)
if n < 1 or "Y.md" not in cap or "then .?cd.?(-s it)? to the target tree" not in cap:
    failures.append(f"A3 (retired placement phrase, plain form) expected FAIL naming pattern+file, got {n}: {cap}")
# A3-MUTATION: with the pre-extension 2-pattern tuple the same fixture must
# NOT produce the FAIL text -- the bite comes from the NEW pattern only.
n, cap = run_with_patterns(bA3, PRE_EXTENSION_PATTERNS)
if n != 0:
    failures.append(f"A3-mut (pre-extension patterns, same fixture) expected PASS, got {n}: {cap}")

# A3b: the cd-s variant of the placement phrase -> FAIL (same pattern).
def bA3b(root): w(root, "pack-ops/Y2.md",
                  "spawns RO in place, then \`cd\`-s it to the target tree.\n")
n, cap = run(bA3b)
if n < 1 or "Y2.md" not in cap or "then .?cd.?(-s it)? to the target tree" not in cap:
    failures.append(f"A3b (placement phrase, cd-s variant) expected FAIL naming pattern+file, got {n}: {cap}")
n, cap = run_with_patterns(bA3b, PRE_EXTENSION_PATTERNS)
if n != 0:
    failures.append(f"A3b-mut (pre-extension patterns, same fixture) expected PASS, got {n}: {cap}")

# A4: the literal cd-REUSE in an active surface -> FAIL, FAIL text names
# the matched pattern + the file.
def bA4(root): w(root, "pack-ops/Z.md",
                 "every later RW agent does a cd-REUSE of that tree.\n")
n, cap = run(bA4)
if n < 1 or "Z.md" not in cap or "matched pattern: cd-REUSE" not in cap:
    failures.append(f"A4 (literal cd-REUSE) expected FAIL naming pattern+file, got {n}: {cap}")
n, cap = run_with_patterns(bA4, PRE_EXTENSION_PATTERNS)
if n != 0:
    failures.append(f"A4-mut (pre-extension patterns, same fixture) expected PASS, got {n}: {cap}")

# B3: the SAME placement phrase in the backlog/ record stream -> PASS
# (record-stream allowlist prefix).
def bB3(root): w(root, "backlog/BD-123.md",
                 "the defective ritual read: then cd to the target tree.\n")
n, cap = run(bB3)
if n != 0:
    failures.append(f"B3 (backlog/ record stream allowlisted) expected PASS, got {n}: {cap}")

# B4: the literal cd-REUSE in the changelog/ record stream -> PASS
# (covers the second new allowlist prefix).
def bB4(root): w(root, "changelog/v11.md",
                 "removed the cd-REUSE convention from the coder defs.\n")
n, cap = run(bB4)
if n != 0:
    failures.append(f"B4 (changelog/ record stream allowlisted) expected PASS, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests A/A2/B/B2/C/D/E/F + A3/A3b/A4 (mutation-proven placement-pattern bites) + B3/B4 (record-stream allowlist)" ;;
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
# Group 3: the two lenient-SKIP branches, pinned
#   3a  git binary absent            -> "git not available"
#   3b  REPO_ROOT not a git work tree -> "not a git work tree"
# Both fixtures CARRY retired prose from BOTH families (the prohibition
# prose AND the retired placement-contract phrase) in an active surface, so
# a non-lenient implementation would FAIL them -- the pass can only come
# from the SKIP branch, which is what makes this a real pin rather than a
# vacuous green. Mirrors Group 3 of test-validate-pack-check-69.sh.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: git-unavailable / not-a-work-tree -> lenient SKIP ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
import validate_checks.discipline_parity as dp


def _patch_root(mod, root):
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


class _NoGit:
    """Stands in for the module's subprocess binding: every run() raises
    FileNotFoundError, simulating an absent git binary."""
    @staticmethod
    def run(*a, **k):
        raise FileNotFoundError("git")


def run_lenient(stub_git_missing):
    # A /tmp REPO_ROOT that is deliberately NOT a git work tree, carrying the
    # prohibition prose in an ACTIVE surface (pack-ops). If the SKIP branch
    # ever stops firing, this FAILs loudly instead of passing vacuously.
    tmpdir = tempfile.mkdtemp(prefix="vp-check53-lenient-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir(parents=True, exist_ok=True)
    (root / "pack-ops" / "SOME-RULE.md").write_text(
        "Spawn all sub-agents with no worktree isolation, "
        "then cd to the target tree.\n")
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    saved_sub = dp.subprocess
    mod.failures.clear()
    _patch_root(mod, root)
    if stub_git_missing:
        dp.subprocess = _NoGit
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_worktree_isolation_prohibition_flip_block()
        return len(mod.failures), buf.getvalue()
    finally:
        dp.subprocess = saved_sub
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)


failures = []

n, cap = run_lenient(stub_git_missing=True)
if n != 0:
    failures.append("3a (git binary absent) expected lenient SKIP, got %d failure(s): %s" % (n, cap))
if "git not available" not in cap:
    failures.append("3a expected the git-not-available lenient message, got: %s" % cap)

n, cap = run_lenient(stub_git_missing=False)
if n != 0:
    failures.append("3b (not a git work tree) expected lenient SKIP, got %d failure(s): %s" % (n, cap))
if "not a git work tree" not in cap:
    failures.append("3b expected the not-a-work-tree lenient message, got: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "lenient-SKIP branches pinned (3a git absent + 3b non-work-tree; both fixtures carry retired prose from both families)" ;;
    *) t_fail "Check 53 lenient-SKIP branch tests failed (see Python output)" ;;
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
