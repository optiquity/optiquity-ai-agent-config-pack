#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-88.sh — synthetic tests for Check 88
# (build-script + render shell {spec-sha, structure-sha} dual fingerprint —
# BD-224 OPTION-2 reconciled render-cache).
#
# Check 88 is the render-cache DUAL-fingerprint / three-way sync-guard
# (ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md §4 + §6.1). The committed
# build-script scripts/dashboard-build.py AND the runtime render shell
# pack-ops/dashboard-approvals/dashboard-shell.html each stamp a provenance line
# with TWO fingerprints: `spec-sha` (= git hash-object of the tracked build-spec
# pack-ops/DASHBOARD-SPEC-PACK.md — the LOGIC contract) and `structure-sha` (a
# sha256 fold of the FORMAT contract — the two per-entry `_rules.md` blob ids + the
# session-state schema token + repr(_SESSION_STATE_REQUIRED_KEYS)). The guard
# re-derives BOTH live and asserts three-way equality:
#   * SCRIPT-arm (ALWAYS-ON): the committed script is always tracked → HARD guard.
#   * SHELL-arm (SKIP-lenient): the shell is untracked until the first render.
#   * PAIRING-arm (both tracked): script.{spec,structure}-sha == shell's pair.
# declare-verify-backing: a declared fingerprint whose spec/format contract cannot
# be hashed is an absence-of-backing FAIL. Off a git work tree / with neither the
# script nor the shell tracked → SKIP-lenient.
#
# This test is NOT fixture-dependent (it never reads test-fixtures/<NAME> — it
# `git init`s throwaway repos in /tmp REPO_ROOTs). It lives under scripts/tests/
# and auto-wires into CI via the disk glob (Check 42 / BD-219). Per "Test infra is
# self-provisioned": every case is built in a /tmp scratch git repo; the REAL tree
# is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 88 registration + count invariant (==86)
#   Group 1: Real-state-at-HEAD — the committed script is tracked, so the SCRIPT-arm
#            runs (always-on) and must be in sync (0 failures); the shell is absent
#            so the SHELL/pairing arms SKIP
#   Group 2: Synthetic /tmp git-repo PASS/FAIL/SKIP (monkeypatch REPO_ROOT):
#            - PASS: correct script, no shell → script-arm in sync
#            - FAIL: script stale spec-sha → spec-sha mismatch
#            - FAIL: script stale structure-sha → structure-sha mismatch
#            - PASS: correct script + correct shell → pairing in sync
#            - FAIL: correct script + divergent shell → shell spec-sha mismatch +
#                    a DIVERGENT pairing fingerprint
#            - FAIL: script with NO spec-sha comment → missing provenance comment
#            - FAIL: script + spec-sha but the spec is absent → no load-bearing backing
#            - FAIL: script + spec-sha but NO structure-sha comment → missing
#                    structure-sha provenance comment
#            - SKIP: neither script nor shell tracked → lenient
#            - SKIP: REPO_ROOT at a NON-git dir → git-unavailable lenient
#   Group 3: End-to-end validate-pack.py --only-check 88 on HEAD
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
# Group 0: Module import + Check 88 registration + count invariant
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
# computed registry length AND that count must be 86 (Check 59's invariant —
# proves the Check-89 add + the 85->86 count bump landed together with the Check-88
# dual-fingerprint extension, which adds NO net-new registry entry).
nums = [t[0] for t in mod._build_check_registry()]
if 88 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
if mod.CHECK_REGISTRY_EXPECTED_COUNT != 86:
    print('FAIL_COUNT_NOT_86', mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
print('OK')
" > /tmp/vp-check88-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check88-import.out; then
    t_pass "validate-pack.py imports + Check 88 symbol registered + count invariant holds (==86)"
else
    t_fail "validate-pack.py import / Check 88 registration / count invariant failed" \
        "$(cat /tmp/vp-check88-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD — SCRIPT-arm runs (always-on) + in sync
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD SCRIPT-arm in sync ===\n"

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

# The committed build-script scripts/dashboard-build.py is tracked at HEAD, so the
# always-on SCRIPT-arm runs; its embedded {spec-sha, structure-sha} must equal the
# freshly re-derived live pair (0 failures). The render shell is absent at HEAD, so
# the SHELL/pairing arms SKIP. A failure here means the committed script's
# provenance line drifted from the live spec/format contract (re-stamp it).
if len(new) != 0:
    failures.append(f"real-state Check 88 expected 0 failures, got {len(new)}: {cap}")
if "in sync" not in cap:
    failures.append(f"real-state must report the script-arm 'in sync': {cap}")
if "script-arm" not in cap:
    failures.append(f"real-state must run the always-on 'script-arm': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 88 runs the always-on script-arm and is in sync" ;;
    *) t_fail "real-state Check 88 failed (the committed script's {spec-sha, structure-sha} must match the live spec + format contract — re-stamp scripts/dashboard-build.py if drifted)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/FAIL/SKIP tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/FAIL/SKIP tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib, hashlib, json
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# The required-keys tuple whose repr() the structure-sha fold uses — re-exported by
# the facade from validate_checks.core (listed in core's __all__).
REQUIRED_KEYS = mod._SESSION_STATE_REQUIRED_KEYS

SPEC_REL = "pack-ops/DASHBOARD-SPEC-PACK.md"
SCRIPT_REL = "scripts/dashboard-build.py"
SHELL_REL = "pack-ops/dashboard-approvals/dashboard-shell.html"
BACKLOG_RULES = "backlog/_rules.md"
CHANGELOG_RULES = "changelog/_rules.md"
SESSION_STATE = "pack-ops/session-state.json"


def _patch_root(root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 88's body lives in validate_checks.pack_ops_hygiene and
    resolves its git root via pack_ops_hygiene.REPO_ROOT (through _git_ls_files /
    _git_hash_object / _structure_sha / the reads); a facade-only patch would NOT
    bite (BD-256 W12 wave-invariant technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _init_repo(root):
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)


def _gho(root, rel):
    return subprocess.run(["git", "hash-object", rel], cwd=root,
                          capture_output=True, text=True, check=True).stdout.strip()


def _write_contract_inputs(root, with_spec=True):
    """Write the structure-sha fold inputs (+ the spec, unless with_spec=False)."""
    (root / "pack-ops").mkdir(parents=True, exist_ok=True)
    (root / "backlog").mkdir(exist_ok=True)
    (root / "changelog").mkdir(exist_ok=True)
    if with_spec:
        (root / SPEC_REL).write_text("# Build spec\n\nR2: fresh state every build.\n")
    (root / BACKLOG_RULES).write_text("# backlog rules\n")
    (root / CHANGELOG_RULES).write_text("# changelog rules\n")
    (root / SESSION_STATE).write_text(json.dumps({"schema": "pack-session-state/1"}))


def _live_pair(root, with_spec=True):
    """Compute the live {spec-sha, structure-sha} the way Check 88 does."""
    spec_sha = _gho(root, SPEC_REL) if with_spec else None
    parts = [_gho(root, BACKLOG_RULES), _gho(root, CHANGELOG_RULES),
             "pack-session-state/1", repr(REQUIRED_KEYS)]
    struct = hashlib.sha256("".join(p + "\n" for p in parts).encode("utf-8")).hexdigest()
    return spec_sha, struct


def _prov(spec_sha, struct_sha):
    line = "# pack-dashboard build script · spec: " + SPEC_REL
    if spec_sha is not None:
        line += " · spec-sha: " + spec_sha
    if struct_sha is not None:
        line += " · structure-sha: " + struct_sha
    return line


def _write_script(root, spec_sha, struct_sha):
    (root / "scripts").mkdir(exist_ok=True)
    (root / SCRIPT_REL).write_text(
        "#!/usr/bin/env python3\n" + _prov(spec_sha, struct_sha) + "\n\"\"\"x\"\"\"\n")


def _write_shell(root, spec_sha, struct_sha):
    (root / "pack-ops/dashboard-approvals").mkdir(parents=True, exist_ok=True)
    line = "<!-- pack-dashboard shell · spec: " + SPEC_REL
    if spec_sha is not None:
        line += " · spec-sha: " + spec_sha
    if struct_sha is not None:
        line += " · structure-sha: " + struct_sha
    line += " -->"
    (root / SHELL_REL).write_text(line + "\n<!DOCTYPE html><html><body>shell</body></html>\n")


def _run_body(root):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_approvals_spec_shell_sync()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)


def build_and_run(fn):
    """`fn(root)` writes the fixture; then `git add -A` + run Check 88."""
    tmp = tempfile.mkdtemp(prefix="vp-check88-")
    root = pathlib.Path(tmp)
    try:
        _init_repo(root)
        fn(root)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


failures = []

# T1: PASS — correct script, no shell → script-arm in sync.
def t1(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    spec, struct = _live_pair(root)
    _write_script(root, spec, struct)
n, cap = build_and_run(t1)
if n != 0:
    failures.append(f"T1 (correct script) expected 0 failures, got {n}: {cap}")
if "in sync" not in cap or "script-arm" not in cap:
    failures.append(f"T1 must report the script-arm 'in sync': {cap}")

# T2: FAIL — script stale spec-sha → spec-sha mismatch.
def t2(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    _, struct = _live_pair(root)
    _write_script(root, "0" * 40, struct)
n, cap = build_and_run(t2)
if n < 1 or "spec-sha mismatch" not in cap:
    failures.append(f"T2 (stale spec-sha) expected a spec-sha mismatch, got {n}: {cap}")

# T2b: FAIL — script stale structure-sha → structure-sha mismatch.
def t2b(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    spec, _ = _live_pair(root)
    _write_script(root, spec, "0" * 64)
n, cap = build_and_run(t2b)
if n < 1 or "structure-sha mismatch" not in cap:
    failures.append(f"T2b (stale structure-sha) expected a structure-sha mismatch, got {n}: {cap}")

# T3: PASS — correct script + correct shell → pairing in sync.
def t3(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    spec, struct = _live_pair(root)
    _write_script(root, spec, struct)
    _write_shell(root, spec, struct)
n, cap = build_and_run(t3)
if n != 0:
    failures.append(f"T3 (correct script+shell) expected 0 failures, got {n}: {cap}")
if "pairing-arm" not in cap or "in sync" not in cap:
    failures.append(f"T3 must report the pairing-arm 'in sync': {cap}")

# T4: FAIL — correct script + divergent shell → shell spec-sha mismatch + DIVERGENT pair.
def t4(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    spec, struct = _live_pair(root)
    _write_script(root, spec, struct)
    _write_shell(root, "b" * 40, struct)  # shell's spec-sha diverges
n, cap = build_and_run(t4)
if n < 1 or "spec-sha mismatch" not in cap:
    failures.append(f"T4 (divergent shell) expected a shell spec-sha mismatch, got {n}: {cap}")
if "DIVERGENT" not in cap:
    failures.append(f"T4 must report the DIVERGENT pairing fingerprint: {cap}")

# T5: FAIL — script with NO spec-sha comment → missing provenance comment.
def t5(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    _, struct = _live_pair(root)
    _write_script(root, None, struct)  # no spec-sha token
n, cap = build_and_run(t5)
if n < 1 or "provenance comment" not in cap:
    failures.append(f"T5 (no spec-sha comment) expected a missing 'provenance comment', got {n}: {cap}")

# T6: FAIL — script + spec-sha but the spec is absent → no load-bearing backing.
def t6(root):
    _write_contract_inputs(root, with_spec=False)  # NO spec on disk
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    _, struct = _live_pair(root, with_spec=False)
    _write_script(root, "a" * 40, struct)  # declares a spec-sha with no backing
n, cap = build_and_run(t6)
if n < 1 or "no load-bearing backing" not in cap:
    failures.append(f"T6 (spec absent) expected 'no load-bearing backing', got {n}: {cap}")

# T7: FAIL — script + spec-sha but NO structure-sha comment → missing structure-sha.
def t7(root):
    _write_contract_inputs(root)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    spec, _ = _live_pair(root)
    _write_script(root, spec, None)  # no structure-sha token
n, cap = build_and_run(t7)
if n < 1 or "structure-sha" not in cap or "provenance comment" not in cap:
    failures.append(f"T7 (no structure-sha comment) expected a missing structure-sha provenance comment, got {n}: {cap}")

# T8: SKIP — neither script nor shell tracked (spec present only) → lenient.
def t8(root):
    _write_contract_inputs(root)  # spec + contract inputs, but no script/shell
n, cap = build_and_run(t8)
if n != 0:
    failures.append(f"T8 (neither tracked) expected 0 failures, got {n}: {cap}")
if "neither" not in cap or "skipping (lenient)" not in cap:
    failures.append(f"T8 must SKIP 'neither ... skipping (lenient)': {cap}")

# T9: SKIP — REPO_ROOT at a NON-git dir (no `git init`) → git-unavailable lenient.
def run_check_nongit():
    tmp = tempfile.mkdtemp(prefix="vp-check88-nongit-")
    root = pathlib.Path(tmp)
    try:
        return _run_body(root)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
n, cap = run_check_nongit()
if n != 0:
    failures.append(f"T9 (non-git dir) expected 0 failures, got {n}: {cap}")
if "git ls-files unavailable" not in cap or "skipping (lenient)" not in cap:
    failures.append(f"T9 must SKIP git-unavailable lenient: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL/SKIP tests (T1 script in sync; T2/T2b stale spec/structure; T3 pairing in sync; T4 divergent shell; T5 no spec-sha; T6 spec absent; T7 no structure-sha; T8 neither tracked; T9 non-git dir)" ;;
    *) t_fail "Synthetic Check 88 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 88 > /tmp/vp-check88-e2e.out 2>&1; then
    if grep -q "Check 88: scripts/dashboard-build.py" /tmp/vp-check88-e2e.out \
       && grep -q "in sync" /tmp/vp-check88-e2e.out; then
        t_pass "validate-pack.py --only-check 88 exits 0; Check 88 runs the script-arm and is in sync on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 88 in-sync output not detected" \
            "Tail: $(tail -10 /tmp/vp-check88-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD (--only-check 88) — the committed script's {spec-sha, structure-sha} must match the live spec + format contract" \
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
