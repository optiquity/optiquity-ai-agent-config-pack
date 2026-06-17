#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-56.sh — dedicated test for
# BD-197 Check 56 (destructive-git-verb enumeration parity, Guard-C).
#
# Check 56 asserts the §5.1 denylist's canonical verb set + the catch-all
# principle phrase (`including but not limited to`) appear in every surface
# that enumerates the agents-never-commit ban (trinity ×3,
# PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder ×3 = 10 surfaces).
# Standalone per decision 8 (folding into an existing parity check over-
# complicates). Sized to the measured-consistent verb set.
#
# This test proves the guard PASSes when all 10 surfaces carry the full set
# and FAILs when a verb is dropped from one surface OR the principle phrase
# is missing OR a surface is absent — all in a synthetic /tmp tree (it NEVER
# mutates the real tree).
#
# Coverage:
#   Group 0: module import + Check 56 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            T1 PASS — all 10 surfaces carry every verb + the principle phrase
#            T2 FAIL — one surface drops a verb (e.g. `worktree`)
#            T3 FAIL — one surface drops the principle phrase
#            T4 FAIL — one surface absent
#            T5 PASS — a benign substring is NOT a false verb match
#                      (word-boundary: `command`/`stream` ≠ `am`-class)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 56 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-56.sh

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
printf "\n=== Group 0: Module import + Check 56 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_destructive_git_verb_parity',
    '_check_56_verb_present',
    '_CHECK_56_VERB_PARITY_SURFACES',
    '_CHECK_56_CANONICAL_VERBS',
    '_CHECK_56_PRINCIPLE_PHRASE',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check56-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check56-import.out; then
    t_pass "validate-pack.py imports + Check 56 symbols registered"
else
    t_fail "validate-pack.py import or Check 56 symbol registration failed" \
        "$(cat /tmp/vp-check56-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

VERBS = list(mod._CHECK_56_CANONICAL_VERBS)
PHRASE = mod._CHECK_56_PRINCIPLE_PHRASE
SURFACES = list(mod._CHECK_56_VERB_PARITY_SURFACES)

def full_body(verbs=None, include_phrase=True, extra=""):
    """A well-formed surface body: every canonical verb as a git-verb token
    plus the catch-all principle phrase."""
    vs = VERBS if verbs is None else verbs
    lines = ["You are an agent. The denied set:"]
    lines += [f"- git {v}" for v in vs]
    if include_phrase:
        lines.append(f"read-only verbs only; {PHRASE} the enumerated denylist.")
    if extra:
        lines.append(extra)
    return "\n".join(lines) + "\n"

def run(overrides=None, drop_surface=None):
    """overrides: {surface: body_text}; drop_surface: a surface to OMIT."""
    overrides = overrides or {}
    tmpdir = tempfile.mkdtemp(prefix="vp-check56-")
    root = pathlib.Path(tmpdir)
    for s in SURFACES:
        if s == drop_surface:
            continue
        p = root / s
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(overrides.get(s, full_body()))
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_destructive_git_verb_parity()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

# T1: PASS — all 10 surfaces carry every verb + the principle phrase.
n, cap = run()
if n != 0:
    failures.append(f"T1 (all consistent) expected PASS, got {n}: {cap}")

# T2: FAIL — one surface drops a verb (worktree).
short = [v for v in VERBS if v != "worktree"]
n, cap = run(overrides={"CLAUDE.md": full_body(verbs=short)})
if n < 1 or "worktree" not in cap or "CLAUDE.md" not in cap:
    failures.append(f"T2 (dropped verb) expected FAIL naming worktree+CLAUDE.md, got {n}: {cap}")

# T3: FAIL — one surface drops the principle phrase.
n, cap = run(overrides={".claude/agents/pack-coder.md": full_body(include_phrase=False)})
if n < 1 or "principle phrase" not in cap:
    failures.append(f"T3 (dropped principle phrase) expected FAIL, got {n}: {cap}")

# T4: FAIL — one surface absent.
n, cap = run(drop_surface=".agents-plugin/pack-agents/agents/pack-coder.md")
if n < 1 or "not found" not in cap:
    failures.append(f"T4 (absent surface) expected FAIL, got {n}: {cap}")

# T5: PASS — word-boundary safety: a benign substring containing a verb-like
# fragment must NOT false-match. Add prose with 'command'/'stream'/'pullback'
# to a well-formed surface; it still carries every real verb so it PASSes.
n, cap = run(overrides={"AGENTS.md": full_body(
    extra="This command streams a pullback; restoreth nothing.")})
if n != 0:
    failures.append(f"T5 (word-boundary safety) expected PASS, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T5 (parity PASS + dropped-verb/dropped-phrase/absent-surface FAIL + word-boundary safety)" ;;
    *) t_fail "End-to-end check_destructive_git_verb_parity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 56 > /tmp/vp-check56-e2e.out 2>&1; then
    if grep -q "Check 56: BD-197 destructive-git-verb enumeration parity" /tmp/vp-check56-e2e.out \
       && grep -q "Check 56 (Guard-C) — destructive-git-verb enumeration parity holds" /tmp/vp-check56-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 56 runs and reports verb-parity clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 56 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check56-e2e.out)"
    fi
else
    if grep -q "Check 56: BD-197 destructive-git-verb enumeration parity" /tmp/vp-check56-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 56 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check56-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 56 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check56-e2e.out)"
    fi
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
