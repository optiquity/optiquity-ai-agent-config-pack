#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-23.sh — synthetic fixture tests for
# Check 23 (help-fragment completeness vs scripts/ executables; BD-082) and
# its BD-205 (OI-1 / D8a) persona-contracts leg.
#
# Check 23 asserts every top-level executable script in scripts/ is either
# listed in pack-ops/HELP-FRAGMENT-PACK.md or marked `# pack-internal: true`.
# BD-205 extends the SAME rule one level down to scripts/persona-contracts/ so
# the 3 contracts' `# pack-internal: true` markers (BD-116 F5) actually BITE —
# they were INERT before (declared but never verified) because the top-level
# iterdir() never descended. This test proves:
#   - the markers PASS when present (declare-verify-backing: present ⇒ exempt);
#   - the markers BITE the ABSENCE case (a contract with NO marker + NOT in the
#     fragment FAILS);
#   - the persona leg is git-TRACKED-sourced and SKIPs leniently when git is
#     unavailable / the dir is not a git work tree.
#
# Test infra is self-provisioned: every leg builds a throwaway /tmp repo
# (git init + commit) as the monkeypatched REPO_ROOT — no real repo touched.
# Cleanup runs on every exit.
#
# Coverage:
#   Group 0: Module import + Check 23 symbols + dynamic count-invariant +
#            Check 23 REGISTERED
#   Group 1: Synthetic git-repo end-to-end (in-process body invocation) —
#            T1  3 contracts all marked pack-internal → PASS (3 flagged)
#            T2  one contract MISSING the marker (not in fragment) → FAIL
#                (the absence-case BITE — declare-verify-backing)
#            T3  a contract LISTED in the fragment (no marker) → PASS
#                (the in-fragment exemption branch, same as top-level)
#   Group 2: Non-git env → persona leg lenient SKIP (an unmarked contract does
#            NOT fail when git is unavailable — ci-guard-measure-then-bound)
#
# Usage: bash scripts/tests/test-validate-pack-check-23.sh
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

printf "\n=== Group 0: Module import + Check 23 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_help_fragment_completeness', '_is_pack_internal',
           '_HELP_FRAGMENT_PACK', '_PACK_INTERNAL_RE']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# _git_ls_files_multi is the git-tracked enumeration helper the BD-205 persona
# leg reuses. It is underscore-prefixed (NOT re-exported via import *), so it
# is asserted on the OWNING module, not the facade.
import validate_checks.help_fragments as hf
if not hasattr(hf, '_git_ls_files_multi'):
    print('FAIL_MISSING _git_ls_files_multi'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 23 not in nums:
    print('FAIL_23_NOT_REGISTERED'); sys.exit(1)
print('OK')
" > /tmp/vp-check23-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check23-import.out; then
    t_pass "imports + Check 23 symbols present (incl. _git_ls_files_multi on the owning module) + count invariant holds (dynamic) + Check 23 REGISTERED"
else
    t_fail "Check 23 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check23-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic git-repo end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic git-repo end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, subprocess
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant). Check 23 lives in
    validate_checks.help_fragments and reaches REPO_ROOT via the moved core
    seam (REPO_ROOT / "scripts", REPO_ROOT / _HELP_FRAGMENT_PACK) AND via
    _git_ls_files_multi's cwd=REPO_ROOT git probe — both read the
    help_fragments module global, which this patch covers."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []
FRAG_REL = "pack-ops/HELP-FRAGMENT-PACK.md"
PC_REL = "scripts/persona-contracts"


def git(repo, *args):
    return subprocess.run(["git", *args], cwd=repo, capture_output=True,
                          text=True)


def new_repo():
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check23-"))
    git(tmpdir, "init", "-q")
    git(tmpdir, "config", "user.email", "t@t.t")
    git(tmpdir, "config", "user.name", "t")
    git(tmpdir, "config", "commit.gpgsign", "false")
    return tmpdir


def write_fragment(repo, extra=""):
    p = repo / FRAG_REL
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text("# HELP-FRAGMENT-PACK\n\n" + extra + "\n")


def write_contract(repo, name, marked=True):
    p = repo / PC_REL / name
    p.parent.mkdir(parents=True, exist_ok=True)
    body = "#!/usr/bin/env bash\n"
    if marked:
        body += "# pack-internal: true  (CI persona contract; not a verb)\n"
    body += "echo contract\n"
    p.write_text(body)


def commit_all(repo):
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "fixture")


def run_in_tree(repo):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, repo)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_help_fragment_completeness()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)


cleanup = []
try:
    # T1: 3 contracts, all marked pack-internal → PASS, all 3 flagged internal.
    repo = new_repo(); cleanup.append(repo)
    write_fragment(repo)
    for n in ("contract-greenfield.sh", "contract-mid-dev.sh",
              "contract-migration.sh"):
        write_contract(repo, n, marked=True)
    commit_all(repo)
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T1 (all-marked PASS) expected 0 failures, got %d: %s" % (fc, cap))
    if "(3 marked pack-internal)" not in cap:
        failures.append("T1 (all-marked PASS) expected all 3 contracts counted internal: %s" % cap)

    # T2: one contract MISSING the marker (and NOT in the fragment) → FAIL.
    # The absence-case BITE (declare-verify-backing): drop a marker → Check 23
    # fails naming the contract's tracked path.
    repo = new_repo(); cleanup.append(repo)
    write_fragment(repo)
    write_contract(repo, "contract-greenfield.sh", marked=True)
    write_contract(repo, "contract-mid-dev.sh", marked=False)   # marker STRIPPED
    write_contract(repo, "contract-migration.sh", marked=True)
    commit_all(repo)
    fc, cap = run_in_tree(repo)
    if fc < 1:
        failures.append("T2 (missing-marker FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
    if "scripts/persona-contracts/contract-mid-dev.sh" not in cap:
        failures.append("T2 (missing-marker FAIL) expected the unmarked contract path named: %s" % cap)
    if "missing from HELP-FRAGMENT-PACK.md" not in cap:
        failures.append("T2 (missing-marker FAIL) expected the completeness FAIL header: %s" % cap)

    # T3: an unmarked contract that IS listed in the fragment by name → PASS
    # (the in-fragment exemption branch — same semantics as the top-level scan).
    repo = new_repo(); cleanup.append(repo)
    write_fragment(repo, extra="See \`contract-greenfield.sh\` for the greenfield contract.")
    write_contract(repo, "contract-greenfield.sh", marked=False)  # no marker, but listed
    commit_all(repo)
    fc, cap = run_in_tree(repo)
    if fc != 0:
        failures.append("T3 (listed-in-fragment PASS) expected 0 failures, got %d: %s" % (fc, cap))
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
    0) t_pass "Synthetic git-repo body tests T1-T3 (all-marked-PASS / missing-marker-FAIL-BITE / listed-in-fragment-PASS)" ;;
    *) t_fail "Synthetic git-repo check_help_fragment_completeness tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Non-git env → persona leg lenient SKIP
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Non-git env → persona leg lenient SKIP ===\n"

# A bare /tmp dir (NOT a git work tree) carrying a fragment + an UNMARKED
# contract. `git ls-files` fails (not a work tree) → the persona leg SKIPs
# leniently → the unmarked contract does NOT fail (ci-guard-measure-then-bound:
# SKIP when git is unavailable rather than hard-fail a non-git environment).
G2_OUT="$(python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check23-nongit-"))
frag = tmpdir / "pack-ops" / "HELP-FRAGMENT-PACK.md"
frag.parent.mkdir(parents=True, exist_ok=True)
frag.write_text("# HELP-FRAGMENT-PACK\n")
c = tmpdir / "scripts" / "persona-contracts" / "contract-greenfield.sh"
c.parent.mkdir(parents=True, exist_ok=True)
c.write_text("#!/usr/bin/env bash\necho contract\n")  # UNMARKED, not in fragment
saved_root = mod.REPO_ROOT; saved_failures = list(mod.failures)
mod.failures.clear(); _patch_root(mod, tmpdir)
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_help_fragment_completeness()
    fc = len(mod.failures); cap = buf.getvalue()
finally:
    _patch_root(mod, saved_root); mod.failures.clear()
    mod.failures.extend(saved_failures); shutil.rmtree(tmpdir, ignore_errors=True)
print("PASS" if (fc == 0 and "marked pack-internal" in cap) else ("FAIL " + cap))
EOF
)"
if [[ "$G2_OUT" == PASS* ]]; then
    t_pass "Non-git env (bare /tmp REPO_ROOT) → persona leg lenient SKIP (an unmarked contract does NOT hard-fail a non-git environment)"
else
    t_fail "Non-git env persona leg did not lenient-SKIP" "$G2_OUT"
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
