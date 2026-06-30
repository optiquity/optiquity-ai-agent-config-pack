#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-78.sh — synthetic fixture tests for
# BD-252 Check 78 (session-state snapshot boundary freshness;
# DESIGN-RECONCILED.md §4 + PLAN.md §2 C2; GATE DECISION 2 = advisory WARN).
#
# Check 78 reads `boundary_commit` and asserts it (a) resolves to a real commit
# AND (b) is ancestor-of-or-equal-to HEAD; when it lags HEAD by more than the
# advisory threshold it ADVISORY-WARNs (NOT a fail — GATE DECISION 2; N2: the
# WARN is EXPECTED as HEAD advances past a committed seed).
# SKIP-lenient when the snapshot is ABSENT, the boundary is absent/malformed
# (Check 77 owns that), or git is unavailable / not a work tree.
#
# Test infra is self-provisioned: every leg builds a throwaway /tmp git repo
# (git init + commits) as the monkeypatched REPO_ROOT — no real repo touched.
# Cleanup runs on every exit.
#
# Coverage:
#   Group 0: Module import + Check 78 symbols + dynamic count-invariant +
#            Check 78 REGISTERED
#   Group 1: Synthetic git-repo end-to-end (in-process body invocation) —
#            T1  boundary == HEAD PASSES (0 behind)
#            T2  boundary ancestor, behind <= threshold PASSES (no WARN)
#            T3  boundary ancestor, behind > threshold → ADVISORY WARN (no fail)
#            T4  unknown SHA (does not resolve) FAILS
#            T5  non-ancestor SHA (sibling branch) FAILS
#            T6  ABSENT snapshot → lenient SKIP
#            T7  malformed/absent boundary_commit → lenient SKIP (Check 77 owns)
#   Group 2: Non-git env → lenient SKIP (REPO_ROOT is a bare /tmp dir)
#
# Usage: bash scripts/tests/test-validate-pack-check-78.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

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
# Group 0: Module import + symbols + dynamic count-invariant + REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 78 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_session_state_fresh', '_SESSION_STATE_FILE',
           '_SESSION_STATE_SHA_KEY', '_SESSION_STATE_FRESH_WARN_THRESHOLD']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# advisory threshold is a small positive int.
if not isinstance(mod._SESSION_STATE_FRESH_WARN_THRESHOLD, int) or \
        mod._SESSION_STATE_FRESH_WARN_THRESHOLD < 1:
    print('FAIL_THRESHOLD', mod._SESSION_STATE_FRESH_WARN_THRESHOLD); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 78 not in nums:
    print('FAIL_78_NOT_REGISTERED'); sys.exit(1)
print('OK')
" > /tmp/vp-check78-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check78-import.out; then
    t_pass "imports + Check 78 symbols present + advisory threshold is a positive int + count invariant holds (dynamic) + Check 78 REGISTERED"
else
    t_fail "Check 78 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check78-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic git-repo end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic git-repo end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, json, subprocess
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant). check_session_state_fresh is a
    DUAL-READ check: it reaches REPO_ROOT via the moved core seam
    (_session_state_load reads core.REPO_ROOT) AND in-body (cwd=REPO_ROOT for
    the git probe). Setting it on every loaded validate_checks.* covers BOTH
    bindings — a facade-only OR single-owning-module patch would miss one."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []
SNAP_REL = "pack-ops/session-state.json"
THRESH = mod._SESSION_STATE_FRESH_WARN_THRESHOLD

def git(repo, *args):
    return subprocess.run(["git", *args], cwd=repo, capture_output=True,
                          text=True)

def new_repo(n_commits):
    """git init a throwaway repo with n_commits commits; return (path, [shas])."""
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check78-"))
    git(tmpdir, "init", "-q")
    git(tmpdir, "config", "user.email", "t@t.t")
    git(tmpdir, "config", "user.name", "t")
    git(tmpdir, "config", "commit.gpgsign", "false")
    shas = []
    for i in range(n_commits):
        (tmpdir / ("f%d.txt" % i)).write_text("c%d\n" % i)
        git(tmpdir, "add", "-A")
        git(tmpdir, "commit", "-q", "-m", "commit %d" % i)
        shas.append(git(tmpdir, "rev-parse", "HEAD").stdout.strip())
    return tmpdir, shas

def write_snapshot(repo, boundary):
    """Write a valid snapshot into repo with the given boundary SHA. None=omit;
       'BADSHA' sentinel = malformed (lenient leg)."""
    if boundary is None:
        return
    p = repo / SNAP_REL
    p.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "schema": "pack-session-state/1",
        "boundary_commit": boundary,
        "checkpoint": "2026-06-29T00:00:00Z",
        "active": [], "in_flight_agents": [], "queue": ["BD-252"],
        "parallelization": "serial", "wave": None,
        "pending_decisions": [], "cycle_position": None,
    }
    p.write_text(json.dumps(data, indent=2) + "\n")

def run_in_tree(repo):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, repo)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_session_state_fresh()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)

cleanup = []
try:
    # T1: boundary == HEAD → PASS, 0 behind.
    repo, shas = new_repo(1); cleanup.append(repo)
    write_snapshot(repo, shas[-1][:8])
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T1 (boundary==HEAD PASS) expected 0 failures, got %d: %s" % (fc, cap))
    if "resolves + is ancestor-of-HEAD (0 commit(s) behind" not in cap:
        failures.append("T1 (boundary==HEAD PASS) expected the 0-behind clean message: %s" % cap)

    # T2: boundary ancestor, behind <= threshold → PASS, no WARN.
    repo, shas = new_repo(THRESH + 1); cleanup.append(repo)  # HEAD - threshold
    write_snapshot(repo, shas[0][:8])  # 0th commit; behind == THRESH
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T2 (within-threshold PASS) expected 0 failures, got %d: %s" % (fc, cap))
    if "ADVISORY" in cap or "lags HEAD" in cap:
        failures.append("T2 (within-threshold PASS) unexpectedly WARNed: %s" % cap)
    if "ancestor-of-HEAD (%d commit(s) behind" % THRESH not in cap:
        failures.append("T2 (within-threshold PASS) expected %d-behind clean message: %s" % (THRESH, cap))

    # T3: boundary ancestor, behind > threshold → ADVISORY WARN (NO fail).
    repo, shas = new_repo(THRESH + 2); cleanup.append(repo)  # behind == THRESH+1
    write_snapshot(repo, shas[0][:8])
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T3 (advisory-WARN) expected 0 failures (WARN != fail), got %d: %s" % (fc, cap))
    if "ADVISORY ONLY" not in cap or "lags HEAD by %d" % (THRESH + 1) not in cap:
        failures.append("T3 (advisory-WARN) expected the ADVISORY-WARN message lagging %d: %s" % (THRESH + 1, cap))

    # T4: unknown SHA (does not resolve) → FAIL.
    repo, shas = new_repo(1); cleanup.append(repo)
    write_snapshot(repo, "deadbeef")  # 8-hex but not a real object
    fc, cap = run_in_tree(repo)
    if fc < 1:
        failures.append("T4 (unknown-SHA FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
    if "does NOT resolve to a commit" not in cap:
        failures.append("T4 (unknown-SHA FAIL) expected the no-resolve message: %s" % cap)

    # T5: non-ancestor SHA (a sibling branch commit) → FAIL.
    repo, shas = new_repo(2); cleanup.append(repo)
    # create a divergent commit on a new branch from the FIRST commit, then
    # return HEAD to the original tip; the divergent SHA is non-ancestor of HEAD.
    git(repo, "checkout", "-q", "-b", "side", shas[0])
    (repo / "side.txt").write_text("side\n")
    git(repo, "add", "-A"); git(repo, "commit", "-q", "-m", "side commit")
    side_sha = git(repo, "rev-parse", "HEAD").stdout.strip()
    git(repo, "checkout", "-q", shas[-1])  # detach back onto the main tip
    write_snapshot(repo, side_sha[:8])
    fc, cap = run_in_tree(repo)
    if fc < 1:
        failures.append("T5 (non-ancestor FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
    if "NOT an ancestor of HEAD" not in cap:
        failures.append("T5 (non-ancestor FAIL) expected the not-ancestor message: %s" % cap)

    # T6: ABSENT snapshot → lenient SKIP.
    repo, shas = new_repo(1); cleanup.append(repo)
    fc, cap = run_in_tree(repo)  # no snapshot written
    if fc != 0:
        failures.append("T6 (absent SKIP) expected 0 failures, got %d: %s" % (fc, cap))
    if "absent — skipping (lenient" not in cap:
        failures.append("T6 (absent SKIP) expected the lenient-skip message: %s" % cap)

    # T7: malformed boundary_commit → lenient SKIP (Check 77 owns the fail).
    repo, shas = new_repo(1); cleanup.append(repo)
    p = repo / SNAP_REL; p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({"boundary_commit": "NOTAHEX"}) + "\n")
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T7 (malformed-boundary SKIP) expected 0 failures, got %d: %s" % (fc, cap))
    if "skipping freshness (lenient" not in cap:
        failures.append("T7 (malformed-boundary SKIP) expected the lenient-skip message: %s" % cap)
finally:
    for d in cleanup:
        shutil.rmtree(d, ignore_errors=True)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic git-repo body tests T1-T7 (==HEAD-PASS / within-threshold-PASS / beyond-threshold-ADVISORY-WARN / unknown-SHA-FAIL / non-ancestor-FAIL / absent-SKIP / malformed-boundary-SKIP)" ;;
    *) t_fail "Synthetic git-repo check_session_state_fresh tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Non-git env → lenient SKIP
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Non-git env → lenient SKIP ===\n"

# A bare /tmp dir (NOT a git work tree) carrying a snapshot with a valid-shaped
# boundary → the git work-tree probe fails → lenient SKIP.
G2_OUT="$(python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, json
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant; check_session_state_fresh is a
    dual-read check — core seam + in-body cwd)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


SNAP_REL = "pack-ops/session-state.json"
tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check78-nongit2-"))
p = tmpdir / SNAP_REL; p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps({
    "schema": "pack-session-state/1", "boundary_commit": "2e899db",
    "checkpoint": "2026-06-29T00:00:00Z", "active": [], "in_flight_agents": [],
    "queue": ["BD-252"], "parallelization": "serial", "wave": None,
    "pending_decisions": [], "cycle_position": None}) + "\n")
saved_root = mod.REPO_ROOT; saved_failures = list(mod.failures)
mod.failures.clear(); _patch_root(mod, tmpdir)
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_session_state_fresh()
    fc = len(mod.failures); cap = buf.getvalue()
finally:
    _patch_root(mod, saved_root); mod.failures.clear()
    mod.failures.extend(saved_failures); shutil.rmtree(tmpdir, ignore_errors=True)
print("PASS" if (fc == 0 and "not a git work tree — skipping" in cap) else ("FAIL " + cap))
EOF
)"
if [[ "$G2_OUT" == PASS* ]]; then
    t_pass "Non-git env (bare /tmp REPO_ROOT) → lenient SKIP (never hard-fail a non-git environment)"
else
    t_fail "Non-git env did not lenient-SKIP" "$G2_OUT"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 1
fi
