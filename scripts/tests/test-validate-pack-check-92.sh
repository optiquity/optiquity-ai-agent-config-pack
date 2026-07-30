#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-92.sh — synthetic tests for Check 92
# (no non-portable `mktemp -t <prefix>XXXXXX` / `--tmpdir` / `-p` invocation — BD-276).
#
# Check 92 is the BD-276 regression guard: a cheap O(lines) `git ls-files '*.sh'`
# scan that FAILs loud on any REAL invocation (command position, non-comment) in a
# git-TRACKED pack-side shell script of EITHER non-portable class, so the classes
# swept in BD-276 cannot regress:
#   CLASS 1 — `mktemp [-d] -t <prefix>XXXXXX`, INCLUDING the bundled getopt clusters
#             `-dt` / `-qt` / `-dqt`. The BSD `-t` form treats the argument as a
#             PREFIX and appends its own random suffix, leaving a literal XXXXXX in
#             the temp path on macOS. Portable fix: the full-path template
#             `mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"`.
#   CLASS 2 — GNU-only tmpdir specifiers: `mktemp … --tmpdir` / `--tmpdir=DIR` AND
#             its short synonym `mktemp … -p <dir>` (BSD/macOS lacks both and errors
#             out). Flagged on flag-presence alone (no X-run required).
#
# invocation-vs-mention (declare-verify-backing): the guard BITES a real invocation
# AND SPARES a mention. Mentions are (a) `#`-comment lines (stripped, quote-aware)
# and (b) `.md` docs (outside the `*.sh` candidate set). The guard is pack-side
# scoped — the `project-template/` prefix is EXCLUDED (project-side is the client
# CI's concern).
#
# SELF-REFERENCE NOTE: this test file is itself a git-tracked pack-side `*.sh`, so
# Check 92 scans it in the real battery. Every scratch buggy/portable string is
# therefore ASSEMBLED AT RUNTIME (the `X`-run is interpolated) so this file's
# literal bytes never carry a `<prefix>X{3,}` token in command position — the test
# never trips the guard it exercises.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s throwaway repos in /tmp REPO_ROOTs). It lives under
# scripts/tests/ and auto-wires into CI via the disk glob (Check 42 / BD-219). Per
# "Test infra is self-provisioned": every case is built in a /tmp scratch git repo;
# the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 92 symbol registration + count invariant (89)
#   Group 1: Real-state-at-HEAD PASS (the real tree has zero real invocations)
#   Group 2: Synthetic PASS/BITE/SPARE against /tmp git repos (monkeypatch REPO_ROOT):
#            - T1 PASS  : only a PORTABLE mktemp .sh → 0 failures + clean message
#            - T2 BITE  : a REAL `-t` invocation in scripts/foo.sh → >=1 failure
#                         naming the file + remediation
#            - T2b BITE : embedded mid-token quoted-var `-t` form (build.sh:986 shape)
#            - T2c BITE : bundled getopt clusters `-dt` / `-qt` / `-dqt` (F1)
#            - T2d BITE : GNU-only `--tmpdir` / `--tmpdir=DIR` (class 2)
#            - T2e BITE : GNU short synonym `-p DIR` / `-d -p DIR` (class 2)
#            - T2f SPARE : portable `mktemp -d …; mkdir -p …` (the `;` ends the
#                         mktemp command — `-p` belongs to mkdir, not mktemp)
#            - T3 SPARE : buggy pattern ONLY in a `#`-comment line → 0 failures
#            - T4 SPARE : buggy pattern in a tracked `.md` doc → 0 failures (docs
#                         are outside the `*.sh` set)
#            - T5 SPARE : buggy invocation under project-template/ → 0 failures
#                         (pack-side scope exclusion)
#            - T6 SKIP  : REPO_ROOT at a NON-git dir → git-unavailable → SKIP-lenient
#   Group 3: End-to-end validate-pack.py --only-check 92 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-92.sh
# Exit 0 on all pass; exit 1 on any failure.

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
# Group 0: Module import + Check 92 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 92 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_mktemp_t_portability'):
    print('FAIL_MISSING check_mktemp_t_portability'); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 92 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
if mod.CHECK_REGISTRY_EXPECTED_COUNT != 89:
    print('FAIL_COUNT_NOT_89'); sys.exit(1)
print('OK')
" > /tmp/vp-check92-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check92-import.out; then
    t_pass "validate-pack.py imports + Check 92 registered + count invariant holds (89)"
else
    t_fail "validate-pack.py import / Check 92 registration / count invariant failed" \
        "$(cat /tmp/vp-check92-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real tree has zero real invocations post-sweep)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

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
        mod.check_mktemp_t_portability()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 92 expected 0 failures, got {len(new)}: {cap}")
if "no non-portable" not in cap:
    failures.append(f"real-state PASS message missing clean marker: {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 92 PASSes (the real tree has zero real invocations post-sweep)" ;;
    *) t_fail "real-state Check 92 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests ===\n"

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
    submodule. Check 92's body lives in validate_checks.mktemp_portability and
    resolves its git root via mktemp_portability.REPO_ROOT (through
    _git_ls_sh_files); a facade-only patch would NOT bite."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root

# Assemble the buggy / portable command strings AT RUNTIME so this test file's
# literal bytes never carry a `<prefix>X{3,}` token in command position.
XRUN = "X" * 6
BUGGY = 'tmp="$(mktemp -d -t bd276-scratch.' + XRUN + ')"'
BUGGY_NO_D = 'log=$(mktemp -t bd276-log.' + XRUN + ')'
# Embedded mid-token quoted-variable form (the build.sh:986 shape that a naive
# `[^"]*X{3,}` matcher MISSES); the guard must still BITE it.
BUGGY_EMBEDDED_Q = 'sb=$(mktemp -d -t bd276-contract-"$persona".' + XRUN + ')'
# Bundled getopt clusters ending in `t` (BSD honours them identically → literal
# XXXXXX). A bare `\s+-t\s+` matcher would EVADE these (F1).
BUGGY_BUNDLED_DT = 'd=$(mktemp -dt bd276-bundled.' + XRUN + ')'
BUGGY_BUNDLED_QT = 'f=$(mktemp -qt bd276-quiet.' + XRUN + ')'
BUGGY_BUNDLED_DQT = 'd=$(mktemp -dqt bd276-both.' + XRUN + ')'
# GNU-only `--tmpdir` long option (BSD errors out); a SECOND non-portable class,
# flagged on flag-presence alone — no X-run required (F4). The `--tmpdir` flag is
# assembled at RUNTIME (split) so this test file's literal bytes never carry a
# `mktemp … --tmpdir` command-position token — the class-2 matcher needs no X-run,
# so the X-interpolation self-reference guard would not protect this string.
TMPDIRFLAG = "--tmp" + "dir"
BUGGY_TMPDIR = 'd=$(mktemp ' + TMPDIRFLAG + ' bd276-gnu.' + XRUN + ')'
BUGGY_TMPDIR_EQ = 'd=$(mktemp -d ' + TMPDIRFLAG + '=/var/tmp bd276-gnu.' + XRUN + ')'
# GNU short synonym `-p DIR` (same class as --tmpdir; BSD errors out). Also
# assembled at RUNTIME (split flag) so the test file's literal bytes carry no
# `mktemp … -p` command-position token (this class needs no X-run either).
PDASH = "-" + "p"
BUGGY_P = 'd=$(mktemp ' + PDASH + ' /var/tmp bd276pdir.' + XRUN + ')'
BUGGY_P_D = 'd=$(mktemp -d ' + PDASH + ' /tmp bd276pd.' + XRUN + ')'
PORTABLE = 'tmp="$(mktemp -d "${TMPDIR:-/tmp}/bd276-scratch.' + XRUN + '")"'
# A `#`-comment line MENTIONING the buggy form (must be SPARED).
COMMENT_MENTION = '# portability: never mktemp -d -t prefix.' + XRUN + ' (BSD leaves it literal)'
# A trailing-comment MENTION on an otherwise-inert line (must be SPARED).
TRAILING_MENTION = 'echo ok   # e.g. mktemp -t prefix.' + XRUN
# A `.md` doc code fence containing the buggy form (must be SPARED — not a `*.sh`).
DOC_MENTION = "```\n" + BUGGY + "\n```\n"

SH_HEADER = "#!/usr/bin/env bash\nset -u\n"

failures = []

def run_check(files):
    """git init a /tmp repo, write+track `files` (relpath -> content), run Check 92
    against it via monkeypatched REPO_ROOT. Returns (failures_count, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check92-")
    root = pathlib.Path(tmpdir)
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    (root / "README.md").write_text("scratch\n")
    for rel, content in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_mktemp_t_portability()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

def run_check_nongit():
    tmpdir = tempfile.mkdtemp(prefix="vp-check92-nongit-")
    root = pathlib.Path(tmpdir)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_mktemp_t_portability()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — only a PORTABLE mktemp .sh → 0 failures + clean message.
fc, cap = run_check({"scripts/ok.sh": SH_HEADER + PORTABLE + "\n"})
if fc != 0:
    failures.append(f"T1 (PASS — portable) expected 0 failures, got {fc}: {cap}")
if "no non-portable" not in cap:
    failures.append(f"T1 PASS message missing clean marker: {cap}")

# T2: BITE — a REAL buggy invocation in scripts/foo.sh → >=1 failure naming the
# file + remediation. Two flavours (`-d -t` and bare `-t`).
fc, cap = run_check({"scripts/foo.sh": SH_HEADER + BUGGY + "\n" + BUGGY_NO_D + "\n"})
if fc < 1:
    failures.append(f"T2 (BITE — buggy invocation) expected >=1 failure, got {fc}: {cap}")
if "scripts/foo.sh" not in cap:
    failures.append(f"T2 BITE must name the offending file scripts/foo.sh: {cap}")
if "TMPDIR" not in cap:
    failures.append(f"T2 BITE must carry the portable-form remediation: {cap}")

# T2b: BITE — the embedded mid-token quoted-variable form (build.sh:986 shape) is
# caught by the broadened two-step matcher (a naive `[^"]*X{3,}` would MISS it).
fc, cap = run_check({"scripts/embq.sh": SH_HEADER + BUGGY_EMBEDDED_Q + "\n"})
if fc < 1:
    failures.append(f"T2b (BITE — embedded quoted-var) expected >=1 failure, got {fc}: {cap}")
if "scripts/embq.sh" not in cap:
    failures.append(f"T2b BITE must name scripts/embq.sh: {cap}")

# T2c: BITE — bundled getopt clusters ending in `t` (-dt / -qt / -dqt). A bare
# `\s+-t\s+` matcher evades these; the `-[a-zA-Z]*t` bearer catches them (F1).
fc, cap = run_check({
    "scripts/bundled.sh": SH_HEADER + BUGGY_BUNDLED_DT + "\n" + BUGGY_BUNDLED_QT + "\n" + BUGGY_BUNDLED_DQT + "\n"
})
if fc < 1:
    failures.append(f"T2c (BITE — bundled -dt/-qt/-dqt) expected >=1 failure, got {fc}: {cap}")
if "scripts/bundled.sh" not in cap:
    failures.append(f"T2c BITE must name scripts/bundled.sh: {cap}")

# T2d: BITE — the GNU-only `--tmpdir` long option (2nd non-portable class, F4),
# both bare and `=DIR` forms; no X-run required for this class.
fc, cap = run_check({
    "scripts/gnu.sh": SH_HEADER + BUGGY_TMPDIR + "\n" + BUGGY_TMPDIR_EQ + "\n"
})
if fc < 1:
    failures.append(f"T2d (BITE — --tmpdir) expected >=1 failure, got {fc}: {cap}")
if "scripts/gnu.sh" not in cap:
    failures.append(f"T2d BITE must name scripts/gnu.sh: {cap}")
if "--tmpdir" not in cap:
    failures.append(f"T2d fail message must name the --tmpdir class: {cap}")

# T2e: BITE — the GNU short synonym `-p DIR` (same class as --tmpdir, F-p follow-up),
# bare and `-d -p` forms; no X-run required.
fc, cap = run_check({
    "scripts/pflag.sh": SH_HEADER + BUGGY_P + "\n" + BUGGY_P_D + "\n"
})
if fc < 1:
    failures.append(f"T2e (BITE — -p DIR) expected >=1 failure, got {fc}: {cap}")
if "scripts/pflag.sh" not in cap:
    failures.append(f"T2e BITE must name scripts/pflag.sh: {cap}")

# T2f: SPARE — a portable `mktemp -d "$dir/x.XXXXXX"` FOLLOWED by an unrelated
# `mkdir -p …` (after `;`) must NOT be flagged: the `;` ends the mktemp command
# before the `-p`, so the guard's token run stops. (Regression guard for the
# tracker-init-test.sh:137 shape.)
PORTABLE_THEN_MKDIRP = 'd=$(mktemp -d "${TMPDIR:-/tmp}/x.' + XRUN + '"); mkdir -p "$d/sub"'
fc, cap = run_check({"scripts/mixed.sh": SH_HEADER + PORTABLE_THEN_MKDIRP + "\n"})
if fc != 0:
    failures.append(f"T2f (SPARE — portable mktemp; mkdir -p) expected 0 failures, got {fc}: {cap}")

# T3: SPARE — buggy pattern ONLY in a `#`-comment line (full-line AND trailing) →
# 0 failures (the invocation-vs-mention discipline).
fc, cap = run_check({
    "scripts/comment.sh": SH_HEADER + COMMENT_MENTION + "\n" + TRAILING_MENTION + "\n" + PORTABLE + "\n"
})
if fc != 0:
    failures.append(f"T3 (SPARE — comment mention) expected 0 failures, got {fc}: {cap}")
if "no non-portable" not in cap:
    failures.append(f"T3 SPARE message missing clean marker: {cap}")

# T4: SPARE — buggy form in a tracked `.md` doc → 0 failures (docs are outside the
# `*.sh` candidate set).
fc, cap = run_check({"docs/GUIDE.md": DOC_MENTION})
if fc != 0:
    failures.append(f"T4 (SPARE — .md doc) expected 0 failures, got {fc}: {cap}")

# T5: SPARE — buggy invocation under project-template/ → 0 failures (pack-side
# scope exclusion). A BITE here would prove the exclusion is not wired.
fc, cap = run_check({"project-template/agent-run.sh": SH_HEADER + BUGGY + "\n"})
if fc != 0:
    failures.append(f"T5 (SPARE — project-template scope exclusion) expected 0 failures, got {fc}: {cap}")

# T5b: control — the SAME buggy line at a pack-side path (scripts/) DOES bite, so
# T5's 0-failures is the exclusion working, not the matcher failing.
fc, cap = run_check({"scripts/agent-run.sh": SH_HEADER + BUGGY + "\n"})
if fc < 1:
    failures.append(f"T5b (control — same line pack-side) expected >=1 failure, got {fc}: {cap}")

# T6: SKIP — REPO_ROOT at a NON-git directory → git ls-files unavailable → SKIP.
fc, cap = run_check_nongit()
if fc != 0:
    failures.append(f"T6 (SKIP — non-git dir) expected 0 failures, got {fc}: {cap}")
if "skipping (lenient)" not in cap:
    failures.append(f"T6 SKIP message missing 'skipping (lenient)': {cap}")
if "git ls-files unavailable" not in cap:
    failures.append(f"T6 SKIP must report git-unavailable: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic tests (T1 portable PASS; T2 buggy BITE names file+remediation; T2b embedded quoted-var BITE; T2c bundled -dt/-qt/-dqt BITE; T2d --tmpdir BITE; T2e -p DIR BITE; T2f portable-mktemp-then-mkdir-p SPARE; T3 comment SPARE; T4 .md-doc SPARE; T5 project-template SPARE + T5b pack-side control BITE; T6 non-git SKIP)" ;;
    *) t_fail "Synthetic Check 92 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 92 > /tmp/vp-check92-e2e.out 2>&1; then
    if grep -q "Check 92: no non-portable" /tmp/vp-check92-e2e.out \
       && grep -q "no non-portable" /tmp/vp-check92-e2e.out; then
        t_pass "validate-pack.py --only-check 92 exits 0; Check 92 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 92 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check92-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check92-e2e.out)"
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
