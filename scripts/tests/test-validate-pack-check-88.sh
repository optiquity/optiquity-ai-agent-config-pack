#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-88.sh — synthetic tests for Check 88
# (dashboard-shell.html spec-sha matches DASHBOARD-SPEC-PACK.md — BD-224).
#
# Check 88 is the BD-224 render-cache sync-guard (architecture §9): when the
# git-TRACKED render shell pack-ops/dashboard-approvals/dashboard-shell.html
# exists, it asserts the shell's embedded `spec-sha: <hex>` provenance comment
# matches `git hash-object` of the tracked build-spec
# pack-ops/DASHBOARD-SPEC-PACK.md (declare-verify-backing). A mismatch (the spec
# changed without a re-render → a committed stale shell) FAILs; an unhashable spec
# (a declared fingerprint with NO backing) FAILs. At HEAD the dir/shell is absent
# (0 tracked) so the guard SKIPs (lenient).
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s a throwaway repo in a /tmp REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob (Check 42 /
# BD-219). Per "Test infra is self-provisioned": every tracked-state case is built
# in a /tmp scratch git repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 88 symbol registration + count invariant
#   Group 1: Real-state-at-HEAD SKIP (the real tree has no tracked shell)
#   Group 2: Synthetic PASS/FAIL/SKIP against a /tmp git repo (monkeypatch
#            REPO_ROOT):
#            - PASS: shell present + matching spec-sha → 0 failures + "in sync"
#            - FAIL: shell present + mismatched spec-sha → >=1 failure ("spec-sha
#                    mismatch")
#            - FAIL: shell present but NO embedded spec-sha comment → >=1 failure
#                    ("provenance comment" — declared render shell, no fingerprint)
#            - FAIL: shell present + spec-sha comment but the spec is
#                    absent/unhashable → >=1 failure ("no load-bearing backing" —
#                    declared fingerprint, no backing)
#            - SKIP: spec present but NO approvals dir (shell untracked) → 0
#                    failures lenient
#            - SKIP: REPO_ROOT at a NON-git dir (no git init) → git-unavailable
#                    → SKIP-lenient (the git-absent / non-worktree branch)
#   Group 3: End-to-end validate-pack.py --only-check 88 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-88.sh

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
# Group 0: Module import + Check 88 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 88 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_dashboard_approvals_spec_shell_sync'):
    print('FAIL_MISSING check_dashboard_approvals_spec_shell_sync'); sys.exit(1)
# Check 88 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's invariant — proves the Check-88 add + the
# count bump landed together).
nums = [t[0] for t in mod._build_check_registry()]
if 88 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check88-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check88-import.out; then
    t_pass "validate-pack.py imports + Check 88 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 88 registration / count invariant failed" \
        "$(cat /tmp/vp-check88-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD SKIP (real tree has no tracked shell)
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
        mod.check_dashboard_approvals_spec_shell_sync()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 88 expected 0 failures, got {len(new)}: {cap}")
if "skipping (lenient)" not in cap:
    failures.append(f"real-state SKIP message missing 'skipping (lenient)': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 88 SKIPs (the real tree has no tracked dashboard-shell.html)" ;;
    *) t_fail "real-state Check 88 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/FAIL/SKIP tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/FAIL/SKIP tests ===\n"

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
    submodule. Check 88's body lives in validate_checks.pack_ops_hygiene and
    resolves its git root via pack_ops_hygiene.REPO_ROOT (through _git_ls_files,
    _git_hash_object, and the shell read); a facade-only patch would NOT bite.
    Setting it on every loaded validate_checks.* reaches the read wherever the body
    resolves it (BD-256 W12 wave-invariant technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


SPEC_REL = "pack-ops/DASHBOARD-SPEC-PACK.md"
SHELL_REL = "pack-ops/dashboard-approvals/dashboard-shell.html"

failures = []


def _init_repo(root):
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    # A baseline tracked file so the index is non-empty either way.
    (root / "README.md").write_text("scratch\n")
    subprocess.run(["git", "add", "README.md"], cwd=root, check=True)


def _write_spec(root):
    spec_path = root / SPEC_REL
    spec_path.parent.mkdir(parents=True, exist_ok=True)
    spec_path.write_text("# Build spec\n\nR2: fresh state every build.\n")


def _spec_sha(root):
    # git hash-object hashes the WORKING-TREE file content (tracked or not) — the
    # same call the check makes, so an embedded copy of this value matches.
    out = subprocess.run(
        ["git", "hash-object", SPEC_REL],
        cwd=root, capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def _write_shell(root, embedded_sha):
    shell_path = root / SHELL_REL
    shell_path.parent.mkdir(parents=True, exist_ok=True)
    shell_path.write_text(
        "<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md · "
        f"spec-sha: {embedded_sha} -->\n"
        "<!DOCTYPE html><html><head></head><body>shell</body></html>\n"
    )


def _run_body(root):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_approvals_spec_shell_sync()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)


# `git init` a throwaway repo, write the spec, and (when shell_sha_kind is not
# None) write a tracked shell embedding a "match" or "mismatch" spec-sha, then run
# Check 88 against it by monkeypatching mod.REPO_ROOT. Never touches the real tree.
def run_check(shell_sha_kind):
    tmpdir = tempfile.mkdtemp(prefix="vp-check88-")
    root = pathlib.Path(tmpdir)
    try:
        _init_repo(root)
        _write_spec(root)
        if shell_sha_kind is not None:
            real = _spec_sha(root)
            embedded = real if shell_sha_kind == "match" else ("0" * 40)
            _write_shell(root, embedded)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# Create a NON-git /tmp REPO_ROOT (NO `git init`) → `git ls-files` returns
# non-zero → `_git_ls_files` reports available=False → the check SKIPs
# (git-unavailable / non-worktree → lenient). Never touches the real tree.
def run_check_nongit():
    tmpdir = tempfile.mkdtemp(prefix="vp-check88-nongit-")
    root = pathlib.Path(tmpdir)
    try:
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# `git init` a throwaway repo, write the spec, and write a TRACKED shell that
# carries NO `spec-sha: <hex>` provenance comment → the check's `if not match`
# branch (a declared render shell with no build-spec fingerprint = a declared
# mapping with no backing) FAILs. The spec IS present, so the ONLY defect is the
# missing comment. Exercises the absence-of-backing branch T1..T4 never reach.
def run_check_no_comment():
    tmpdir = tempfile.mkdtemp(prefix="vp-check88-nocomment-")
    root = pathlib.Path(tmpdir)
    try:
        _init_repo(root)
        _write_spec(root)
        shell_path = root / SHELL_REL
        shell_path.parent.mkdir(parents=True, exist_ok=True)
        # A shell WITHOUT any `spec-sha: <hex>` comment — the provenance
        # fingerprint the guard needs to verify is simply absent.
        shell_path.write_text(
            "<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md -->\n"
            "<!DOCTYPE html><html><head></head><body>shell</body></html>\n"
        )
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# `git init` a throwaway repo, write a TRACKED shell embedding a well-formed
# 40-hex `spec-sha`, but NEVER write the backing spec → `git hash-object` of the
# spec fails → the check's `if not hashed_available` branch (a declared
# fingerprint with NO load-bearing backing) FAILs. Distinct from T2's drift
# (there the spec IS hashable but the embedded sha differs). Exercises the second
# absence-of-backing branch T1..T4 never reach.
def run_check_spec_absent():
    tmpdir = tempfile.mkdtemp(prefix="vp-check88-specabsent-")
    root = pathlib.Path(tmpdir)
    try:
        _init_repo(root)
        # Shell declares a syntactically valid spec-sha, but the backing spec is
        # never written, so the guard cannot hash it (absence of backing).
        _write_shell(root, "a" * 40)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# T1: PASS — shell present + matching spec-sha → 0 failures + "in sync".
fail_count, captured = run_check("match")
if fail_count != 0:
    failures.append(f"T1 (PASS — matching spec-sha) expected 0 failures, got {fail_count}: {captured}")
if "in sync" not in captured:
    failures.append(f"T1 PASS message missing 'in sync': {captured}")

# T2: FAIL — shell present + mismatched spec-sha → >=1 failure reporting the drift.
fail_count, captured = run_check("mismatch")
if fail_count < 1:
    failures.append(f"T2 (FAIL — mismatched spec-sha) expected >=1 failure, got {fail_count}: {captured}")
if "spec-sha mismatch" not in captured:
    failures.append(f"T2 FAIL must report 'spec-sha mismatch': {captured}")

# T3: SKIP — spec present but NO approvals dir (shell untracked) → 0 failures +
# "is not tracked" + lenient skip.
fail_count, captured = run_check(None)
if fail_count != 0:
    failures.append(f"T3 (SKIP — no shell) expected 0 failures, got {fail_count}: {captured}")
if "is not tracked" not in captured or "skipping (lenient)" not in captured:
    failures.append(f"T3 SKIP message missing 'is not tracked' + 'skipping (lenient)': {captured}")

# T4: SKIP — REPO_ROOT points at a NON-git directory (no `git init`) → git
# ls-files unavailable (not a git work tree) → SKIP-lenient. Exercises the
# `available=False` (git-absent / non-worktree) branch, which the git-init'd
# cases above never reach.
fail_count, captured = run_check_nongit()
if fail_count != 0:
    failures.append(f"T4 (SKIP — non-git dir) expected 0 failures, got {fail_count}: {captured}")
if "skipping (lenient)" not in captured:
    failures.append(f"T4 SKIP message missing 'skipping (lenient)': {captured}")
if "git ls-files unavailable" not in captured:
    failures.append(f"T4 SKIP must report git-unavailable (git absent / not a git work tree): {captured}")

# T5: FAIL (absence-of-backing #1) — shell present but NO embedded spec-sha
# comment → >=1 failure reporting the missing provenance fingerprint. Proves the
# `if not match` FAIL branch bites (a declared render shell with no backing).
fail_count, captured = run_check_no_comment()
if fail_count < 1:
    failures.append(f"T5 (FAIL — no spec-sha comment) expected >=1 failure, got {fail_count}: {captured}")
if "provenance comment" not in captured:
    failures.append(f"T5 FAIL must report the missing 'provenance comment': {captured}")

# T6: FAIL (absence-of-backing #2) — shell present + a well-formed spec-sha
# comment but the backing spec is absent/unhashable → >=1 failure reporting the
# fingerprint with no backing. Proves the `if not hashed_available` FAIL branch
# bites (a declared fingerprint with no load-bearing spec).
fail_count, captured = run_check_spec_absent()
if fail_count < 1:
    failures.append(f"T6 (FAIL — spec absent/unhashable) expected >=1 failure, got {fail_count}: {captured}")
if "no load-bearing backing" not in captured:
    failures.append(f"T6 FAIL must report 'no load-bearing backing': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL/SKIP tests (T1 PASS matching sha; T2 FAIL mismatch; T3 SKIP no-shell; T4 SKIP non-git dir; T5 FAIL no spec-sha comment; T6 FAIL spec absent/unhashable)" ;;
    *) t_fail "Synthetic Check 88 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 88 > /tmp/vp-check88-e2e.out 2>&1; then
    if grep -q "Check 88: pack-ops/dashboard-approvals/dashboard-shell.html spec-sha matches" /tmp/vp-check88-e2e.out \
       && grep -q "skipping (lenient)" /tmp/vp-check88-e2e.out; then
        t_pass "validate-pack.py --only-check 88 exits 0; Check 88 runs and SKIPs lenient on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 88 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check88-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check88-e2e.out)"
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
