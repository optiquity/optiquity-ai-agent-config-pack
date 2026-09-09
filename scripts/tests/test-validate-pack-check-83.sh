#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-83.sh — synthetic tests for Check 83
# (wired-test CI-environment fragility guard, BD-222).
#
# Check 83 statically scans every CI-WIRED test script for four
# CI-environment-fragile bug classes that took a sharded CI run red:
#   (a) a HARDCODED absolute dev/home path (a /Users or /home root, homebrew, or
#       a var-folders temp dir) that exists on the dev box but not on the runner,
#   (b) a direct un-shimmed live-gh call (real gh without a fake-gh-on-PATH shim),
#   (c) the double-zero failure-masking idiom (a counting grep whose non-match is
#       swallowed by a trailing echo-zero on the OR arm),
#   (d) a shell-active construct (a backtick or a dollar-paren) inside an
#       UNQUOTED heredoc body — the BD-294 class. An unquoted delimiter makes the
#       whole body shell-expanded, so what reads as inert payload is a command
#       substitution the shell EXECUTES. bash 5 (the CI runner) aborts the
#       command and reds the group; bash 3.2 (macOS) substitutes empty and exits
#       0, so a dev box goes GREEN on the very defect that reds CI, and `bash -n`
#       sees neither (a heredoc body is not parsed until expansion).
#
# NOTE: this header (and every comment / heredoc line below) deliberately AVOIDS
# writing any of the four bad patterns CONTIGUOUSLY — legs (a) and (c) scan ALL
# lines (comments included), so a contiguous literal here would flag THIS file;
# leg (d) additionally scans every shell-EXPANDED payload (an unquoted heredoc
# body and a double-quoted `python3 -c` body), which includes Group 0 below.
# The BITE payloads are assembled from fragments at runtime (see Group 2).
# Candidate set = raw three-glob (scripts/test*.sh + scripts/tests/*.sh +
# scripts/tests/fixture-dependent/*.sh) MINUS scripts/ci-test-wiring-allowlist.txt
# (a faithful Check-42 mirror).
#
# SELF-GUARD DISCIPLINE (MANDATORY): this file is NOT a ci-test-wiring-allowlist
# member, so the instant Check 83 lands it scans THIS file's own source. Every
# BITE below is therefore ASSEMBLED FROM FRAGMENTS at runtime (the bad
# byte-sequence split across string concatenation) so NO contiguous bad pattern
# ever appears in this file's executable / heredoc / comment lines. Verified by
# Group 4 (the self-guard assertion: Check 83 over the post-landing wired set
# does NOT flag this file).
#
# Coverage:
#   Group 0: Module import + Check 83 symbol registration + registry/count lock-step
#   Group 1: Real-state-at-HEAD PASS (census 0/0/0 over the allowlist-subtracted set)
#   Group 2: The BITEs — each leg FAILs on its assembled /tmp fixture
#   Group 2b: The shim NEGATIVE control — a shimmed direct-gh fixture PASSes leg (b)
#   Group 2d-2h: leg (d) negative controls — a QUOTED heredoc, the opt-out
#             pragma, a diff3 marker in a string, and a SINGLE-quoted `-c`
#             body are all inert and must NOT fire
#   Group 3: The load-bearing subtraction — one-file delta + raw-glob would-FAIL
#   Group 4: Self-guard — Check 83 over HEAD does not flag THIS test file
#   Group 5: End-to-end validate-pack.py --only-check 83 on HEAD
#
# Usage: bash scripts/tests/test-validate-pack-check-83.sh

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
# Group 0: Module import + Check 83 symbol registration + lock-step
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 83 registration + registry/count lock-step ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
sys.path.insert(0, '$REPO_ROOT/scripts/lib')
import importlib.util
# Standalone-import gate (the V0 leg): the module imports with no NameError.
import validate_checks.wired_test_fragility  # noqa: F401
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_wired_test_ci_fragility', 'LEG_A', 'HOME_ABS', 'GH_EXEC', 'SHIM', 'LEG_C',
            'LEG_D_OPEN', 'LEG_D_ACTIVE', 'LEG_D_PRAGMA', 'LEG_D_DASHC']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
import validate_checks.core as core
reg = mod._build_check_registry()
nums = [t[0] for t in reg if isinstance(t[0], int)]
if 83 not in nums:
    print('FAIL_NO_83 max=%s' % max(nums)); sys.exit(1)
if len(reg) != core.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT len=%d const=%d' % (len(reg), core.CHECK_REGISTRY_EXPECTED_COUNT)); sys.exit(1)
print('OK')
" > /tmp/vp-check83-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check83-import.out; then
    t_pass "module imports standalone; Check 83 + leg symbols registered; registry len == CHECK_REGISTRY_EXPECTED_COUNT (Check 59 lock-step)"
else
    t_fail "module import / Check 83 registration / registry-count lock-step failed" \
        "$(cat /tmp/vp-check83-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (census 0/0/0 over the wired set)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS (census 0/0/0) ===\n"

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
        mod.check_wired_test_ci_fragility()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 83 expected 0 failures, got {len(new)}: {cap}")
if "no CI-environment-fragile idiom" not in cap:
    failures.append(f"real-state PASS message missing 'no CI-environment-fragile idiom': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 83 PASSes (0/0/0 census over the CI-wired set)" ;;
    *) t_fail "real-state Check 83 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: The BITEs — each leg FAILs on its assembled /tmp fixture
# Group 2b: The shim NEGATIVE control
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2 + 2b: BITE fixtures (each leg FAILs) + shim negative control ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 wave-invariant). Check 83's body lives in
    validate_checks.wired_test_fragility and reads that module's REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root

# ── The BITE payloads: each bad byte-sequence is ASSEMBLED FROM FRAGMENTS so no
# contiguous bad pattern appears in THIS file's own source (the self-guard). The
# fixtures written to /tmp carry the real, contiguous bad bytes.
# leg (a): a hardcoded dev path.
BAD_A = "echo " + "/Us" + "ers/foo/x"
# leg (b): an un-shimmed live-gh call (gh as a command word).
BAD_B = "gh" + " label create foo --force"
# leg (c): the double-zero idiom.
BAD_C = "x=$(grep " + "-c bar f " + "|| ec" + "ho 0)"
# A fake-gh shim installer (assembled) for the 2b negative control.
SHIM_INSTALL = "prin" + "tf '#!/bin/sh\\n' > " + '"$BIN/' + "gh" + '"'
# leg (d) BD-294: a shell-active construct inside an UNQUOTED heredoc. BT and
# SUB are built from chr()/concat so this file never carries the contiguous
# bytes (the self-guard discipline above), and HD_OPEN/HD_END keep the
# heredoc-operator token out of this file's literal source too.
BT = chr(96)                       # backtick
SUB = "$" + "("                    # dollar-paren
HD_OPEN = "<" + "<EOF"             # UNQUOTED heredoc operator
HD_OPEN_Q = "<" + "<'EOF'"         # QUOTED heredoc operator (inert body)
PRAGMA = "# ci-fragility: allow-" + "shell-active-heredoc"
# The exact BD-294 shape: a backticked HTML snippet in a Python comment.
BAD_D = ("python3 " + HD_OPEN + "\n"
         "# a re-introduced " + BT + "<!-- HOW TO USE THIS TEMPLATE -->" + BT + " block\n"
         "print('x')\n"
         "EOF")
# Same bytes, QUOTED delimiter — inert, must NOT fire (2d control).
OK_D_QUOTED = ("python3 " + HD_OPEN_Q + "\n"
               "# a " + BT + "<!-- HOW TO USE THIS TEMPLATE -->" + BT + " mention\n"
               "print('x')\n"
               "EOF")
# An intentional substitution carrying the opt-out pragma (2e control).
OK_D_PRAGMA = ("read -r A " + HD_OPEN + "  " + PRAGMA + "\n"
               + SUB + "printf x)\n"
               "EOF")
# A diff3 conflict marker in a string is NOT a heredoc operator (2f control).
OK_D_DIFF3 = ('assert_contains "m" "$d" "' + "<" * 7 + ' your customization"')
# The SECOND shell-expanded payload shape: a DOUBLE-quoted `python3 -c "…"`
# body. BD-294 found a REAL instance of the class here that a heredoc-only
# guard misses (test-validate-pack-check-92.sh was executing a backticked
# `!= 89` out of a Python comment on every run).
DQ = chr(34)
BAD_D_DASHC = ("python3 -c " + DQ + "\n"
               "# a hardcoded " + BT + "!= 89" + BT + " note\n"
               "print('x')\n"
               + DQ)
# Same bytes under a SINGLE-quoted -c body — inert, must NOT fire (2h control).
OK_D_DASHC_SQ = ("python3 -c '\n"
                 "# a hardcoded " + BT + "!= 89" + BT + " note\n"
                 "print(1)\n"
                 "'")

def run_check(files):
    """files: dict {basename: body} staged under scripts/tests/ in a tmp tree
    (no ci-test-wiring-allowlist.txt, so the candidate = the raw synthetic glob).
    Returns (failures_count, captured_output) from a Check 83 invocation."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check83-")
    root = pathlib.Path(tmpdir)
    tests_dir = root / "scripts" / "tests"
    tests_dir.mkdir(parents=True)
    for name, body in files.items():
        (tests_dir / name).write_text(body)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_wired_test_ci_fragility()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

PLAIN = "#!/usr/bin/env bash\n# clean test\nexit 0\n"
failures = []

# BITE (a): a fixture with a hardcoded dev path FAILs leg (a).
n, cap = run_check({"test-bad-a.sh": "#!/usr/bin/env bash\n" + BAD_A + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n < 1 or "leg (a)" not in cap:
    failures.append(f"BITE (a) expected >=1 failure naming leg (a), got {n}: {cap}")

# BITE (b): a fixture with an un-shimmed live-gh call FAILs leg (b).
n, cap = run_check({"test-bad-b.sh": "#!/usr/bin/env bash\n" + BAD_B + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n != 1 or "leg (b)" not in cap:
    failures.append(f"BITE (b) expected exactly 1 leg-(b) failure, got {n}: {cap}")

# BITE (c): a fixture with the double-zero idiom FAILs leg (c).
n, cap = run_check({"test-bad-c.sh": "#!/usr/bin/env bash\n" + BAD_C + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n < 1 or "leg (c)" not in cap:
    failures.append(f"BITE (c) expected >=1 failure naming leg (c), got {n}: {cap}")

# 2b: shim NEGATIVE control — direct-gh AND a fake-gh shim installer PASSes leg (b).
shimmed_body = ("#!/usr/bin/env bash\n"
                'BIN="$PWD/fakebin"\n'
                + SHIM_INSTALL + "\n"
                + BAD_B + "\n"
                "exit 0\n")
n, cap = run_check({"test-shimmed.sh": shimmed_body, "test-clean.sh": PLAIN})
if n != 0:
    failures.append(f"2b shim negative control expected 0 failures (shimmed direct-gh), got {n}: {cap}")

# 2c: comment-only gh does NOT fire leg (b) (the strip helper suppresses it).
comment_gh = "#!/usr/bin/env bash\n# example: " + BAD_B + "\nexit 0\n"
n, cap = run_check({"test-comment-gh.sh": comment_gh, "test-clean.sh": PLAIN})
if n != 0:
    failures.append(f"2c comment-only gh expected 0 failures (strip helper), got {n}: {cap}")

# ── Leg (d), BD-294. The guard must fail in BOTH directions: fire on a
# shell-active construct in an UNQUOTED heredoc, stay silent on every inert
# shape. This class is INVISIBLE on macOS (bash 3.2 substitutes empty and
# exits 0 where bash 5 aborts the command) and invisible to `bash -n`, so
# these assertions are the only thing that reds it on a dev box.
def _leg_d_fired(cap):
    """True iff a FAIL line names leg (d). The OK summary also names the
    legs, so a bare substring test over the whole capture is ambiguous."""
    return any("leg (d)" in ln for ln in cap.splitlines()
               if ln.strip().startswith("FAIL"))

# BITE (d): a backtick inside an UNQUOTED heredoc FAILs leg (d).
n, cap = run_check({"test-bad-d.sh": "#!/usr/bin/env bash\n" + BAD_D + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n < 1 or not _leg_d_fired(cap):
    failures.append(f"BITE (d) expected >=1 failure naming leg (d), got {n}: {cap}")

# 2d: the SAME bytes under a QUOTED delimiter are inert — must NOT fire.
n, cap = run_check({"test-quoted-d.sh": "#!/usr/bin/env bash\n" + OK_D_QUOTED + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n != 0 or _leg_d_fired(cap):
    failures.append(f"2d quoted-delimiter control expected 0 leg-(d) failures, got {n}: {cap}")

# 2e: the opt-out pragma on the opening line exempts an intentional substitution.
n, cap = run_check({"test-pragma-d.sh": "#!/usr/bin/env bash\n" + OK_D_PRAGMA + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n != 0 or _leg_d_fired(cap):
    failures.append(f"2e pragma control expected 0 leg-(d) failures, got {n}: {cap}")

# 2f: a diff3 conflict marker in a string is NOT a heredoc operator. This is a
# REGRESSION control: the census's first parser matched a `<< word` out of
# "<<<<<<< your customization" and then swallowed 1136 lines as a heredoc body.
n, cap = run_check({"test-diff3-d.sh": "#!/usr/bin/env bash\n" + OK_D_DIFF3
                                       + "\necho " + BT + "date" + BT + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n != 0 or _leg_d_fired(cap):
    failures.append(f"2f diff3-marker control expected 0 leg-(d) failures, got {n}: {cap}")

# 2g: leg (d) second shape — a backtick inside a DOUBLE-quoted `python3 -c "…"`
# body FAILs. A double-quoted shell string is expanded just like an unquoted
# heredoc; this is the shape the BD-294 census caught in test-92.
n, cap = run_check({"test-bad-dashc.sh": "#!/usr/bin/env bash\n" + BAD_D_DASHC + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n < 1 or not _leg_d_fired(cap):
    failures.append(f"2g -c double-quoted BITE expected >=1 leg-(d) failure, got {n}: {cap}")
if "python3 -c" not in cap:
    failures.append(f"2g failure message does not name the -c shape: {cap}")

# 2h: the SAME bytes in a SINGLE-quoted -c body are inert — must NOT fire.
n, cap = run_check({"test-sq-dashc.sh": "#!/usr/bin/env bash\n" + OK_D_DASHC_SQ + "\nexit 0\n",
                    "test-clean.sh": PLAIN})
if n != 0 or _leg_d_fired(cap):
    failures.append(f"2h single-quoted -c control expected 0 leg-(d) failures, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "BITE 5/5 (legs a/b/c/d heredoc + d -c FAIL on assembled fixtures) + shim/comment-gh no-FP + leg-(d) quoted/pragma/diff3/single-quoted negative controls" ;;
    *) t_fail "BITE / shim-control / leg-(d) control tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: The load-bearing subtraction (one-file delta + raw would-FAIL)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: The load-bearing allowlist subtraction ===\n"

REPO_ROOT="$REPO_ROOT" python3 <<'EOF'
import os, sys, re, pathlib
REPO_ROOT = pathlib.Path(os.environ['REPO_ROOT'])
sys.path.insert(0, str(REPO_ROOT / "scripts" / "lib"))
import validate_checks.wired_test_fragility as m

scripts_dir = REPO_ROOT / "scripts"
tests_dir = scripts_dir / "tests"
fxdep_dir = tests_dir / "fixture-dependent"
raw = set()
for p in scripts_dir.glob("test*.sh"):
    raw.add(f"scripts/{p.name}")
if tests_dir.is_dir():
    for p in tests_dir.glob("*.sh"):
        raw.add(f"scripts/tests/{p.name}")
if fxdep_dir.is_dir():
    for p in fxdep_dir.glob("*.sh"):
        raw.add(f"scripts/tests/fixture-dependent/{p.name}")

allow = set()
alp = scripts_dir / "ci-test-wiring-allowlist.txt"
if alp.is_file():
    for r in alp.read_text().splitlines():
        line = r.strip()
        if not line or line.startswith("#"):
            continue
        allow.add(line.split()[0])
keep = raw - allow
delta = raw - keep

failures = []
# The subtraction removes exactly the allowlist member(s).
if delta != allow:
    failures.append(f"delta {sorted(delta)} != allowlist {sorted(allow)}")
if len(delta) != len(allow):
    failures.append(f"|delta| {len(delta)} != |allowlist| {len(allow)}")

# The raw glob WOULD fail leg (b) somewhere (proves subtraction is load-bearing):
# at least one removed file must carry a direct un-shimmed gh (else the
# subtraction is a no-op for the census and the test is not testing anything).
def leg_b_fails(rel):
    text = (REPO_ROOT / rel).read_text(errors="replace")
    lines = text.splitlines()
    stripped = [m._strip_comments_strings(ln) for ln in lines]
    direct = any(m.GH_EXEC.search(s) for s in stripped)
    shimmed = any(m.SHIM.search(ln) for ln in lines)
    return direct and not shimmed

removed_that_bite = [rel for rel in sorted(delta) if leg_b_fails(rel)]
if not removed_that_bite:
    failures.append("no removed (allowlisted) file trips leg (b) — subtraction "
                    "not proven load-bearing")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK delta==allowlist, load-bearing removed files:", removed_that_bite)
EOF
case $? in
    0) t_pass "candidate = raw − allowlist; delta == allowlist (one file); a removed file trips leg (b) → subtraction load-bearing" ;;
    *) t_fail "load-bearing-subtraction assertions failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: Self-guard — Check 83 over HEAD does not flag THIS file
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: Self-guard (this test file is clean under Check 83) ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# This test file's OWN basename — Check 83 scans it (not allowlisted). Assert its
# path never appears in any failure line.
me = "test-validate-pack-check-83.sh"
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_wired_test_ci_fragility()
    cap = buf.getvalue()
    new = list(mod.failures)
finally:
    mod.failures.clear(); mod.failures.extend(saved)

flagged = [f for f in new if me in f]
if flagged:
    print("FAILURES"); [print(" ", f) for f in flagged]; sys.exit(1)
if me in cap and "leg (" in cap:
    print("FAILURES"); print("  this file appears in a leg failure line:", cap); sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "self-guard clean: Check 83 does not flag this test file (assembled-fragment discipline holds)" ;;
    *) t_fail "self-guard FAILED — this test file trips Check 83 (a contiguous bad pattern leaked into its source)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: End-to-end validate-pack.py --only-check 83 on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 83 > /tmp/vp-check83-e2e.out 2>&1; then
    if grep -q "Check 83: wired-test CI-environment fragility guard" /tmp/vp-check83-e2e.out \
       && grep -q "no CI-environment-fragile idiom" /tmp/vp-check83-e2e.out; then
        t_pass "validate-pack.py --only-check 83 exits 0; Check 83 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 83 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check83-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check83-e2e.out)"
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
