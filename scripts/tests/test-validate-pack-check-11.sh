#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-11.sh — dedicated test for
# Check 11 (project agent trinity-rule symmetry, INFORMATIONAL) — BD-236 C5.
#
# Check 11 (`check_pack_agent_trinity`, in
# scripts/lib/validate_checks/singletons.py) runs
# scripts/compare-agent-trinity.py --all --pack REPO_ROOT --summary-only over
# the three project agent surfaces (.claude/agents/*.md, .codex/agents/*.toml,
# and the Antigravity plugin bundle .agents-plugin/optiquity-agents/agents/*.md)
# and reports the count of agents whose body content diverges across the three.
# Its defining contract is that it is INFORMATIONAL: whatever the divergence
# count, it emits an OK line and NEVER appends to `failures` (never blocks CI).
# Hard-failure enforcement would need a trinity-asymmetry-by-design marker the
# pack does not yet have.
#
# This test LOCKS IN that informational-never-fails contract (it changes NO
# check body). It runs Check 11 against a SYNTHETIC tree (the real tree is never
# used, so the check's landing position — e.g. BD-236 C4 — can never flip an
# assertion): it proves that even when the synthetic project defs DIVERGE across
# the three CLI legs, Check 11 reports the divergence yet returns a NON-failing
# status (0 failures). A symmetric-tree case is also covered. Deliberately, NO
# assertion is made against the real tree's divergence count — only the
# informational-never-fails behavior and (at e2e) that Check 11 runs and does
# not block CI on HEAD.
#
# The synthetic-tree harness mirrors scripts/tests/test-validate-pack-check-55.sh
# and scripts/tests/test-validate-pack-check-57.sh (same _patch_root helper —
# Check 11's body re-reads REPO_ROOT dynamically — plus the same PASS/FAIL
# harness helpers, shims, and exit conventions). The real compare-agent-trinity.py
# is copied into the synthetic scripts/ dir so Check 11's `REPO_ROOT/scripts/
# compare-agent-trinity.py` resolves; the comparator itself is pure-stdlib.
#
# Coverage:
#   Group 0: module import + Check 11 symbol registration
#            (check_pack_agent_trinity)
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS-symmetric — one agent identical across all three legs →
#                      comparator reports 0 divergent → Check 11 OKs
#                      "all trinity-symmetric", 0 failures
#            T2 divergent-but-informational — one leg's body differs → comparator
#                      reports >=1 divergent → Check 11 REPORTS the divergence
#                      (INFO + "informational; not a failure") yet returns
#                      0 failures (never blocks CI). This is the informational
#                      contract; the assertion is count-free.
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 11 runs,
#            does not block CI; header present, exit 0 — no count asserted)
#
# Usage: bash scripts/tests/test-validate-pack-check-11.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/vp-check11.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

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
printf "\n=== Group 0: Module import + Check 11 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_pack_agent_trinity']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > "$SCRATCH/import.out" 2>&1

if grep -q "^OK$" "$SCRATCH/import.out"; then
    t_pass "validate-pack.py imports + Check 11 symbol registered"
else
    t_fail "validate-pack.py import or Check 11 symbol registration failed" \
        "$(cat "$SCRATCH/import.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (symmetric PASS + divergent-informational)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 11's body lives in validate_checks.singletons and reads
    singletons.REPO_ROOT dynamically; setting REPO_ROOT on every loaded
    validate_checks.* module reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root

# The real comparator (pure stdlib) — copied into each synthetic tree's
# scripts/ dir so Check 11's REPO_ROOT/scripts/compare-agent-trinity.py exists.
REAL_COMPARATOR = pathlib.Path(mod.REPO_ROOT) / "scripts" / "compare-agent-trinity.py"

failures = []


def md_agent(name, body):
    # Markdown agent with YAML frontmatter (Claude + Antigravity-bundle form).
    return ("---\nname: " + name + "\ndescription: synthetic " + name
            + "\n---\n\n" + body + "\n")


def toml_agent(name, body):
    # Codex TOML agent; body lives in developer_instructions.
    return 'name = "' + name + '"\ndeveloper_instructions = "' + body + '"\n'


def build_tree(root, diverge):
    """Build a minimal synthetic pack tree with agent 'foo' present in all
    three legs. When diverge is True the Codex leg body differs so the
    comparator reports >=1 divergent; otherwise all three legs are identical
    (0 divergent)."""
    root = pathlib.Path(root)
    (root / "scripts").mkdir(parents=True, exist_ok=True)
    shutil.copy(str(REAL_COMPARATOR),
                str(root / "scripts" / "compare-agent-trinity.py"))
    claude = root / "project-template" / ".claude" / "agents"
    codex = root / "project-template" / ".codex" / "agents"
    bundle = (root / "project-template" / ".agents-plugin"
              / "optiquity-agents" / "agents")
    for d in (claude, codex, bundle):
        d.mkdir(parents=True, exist_ok=True)
    shared = "Shared trinity body text for the foo agent."
    codex_body = ("Divergent trinity body text for the foo agent."
                  if diverge else shared)
    (claude / "foo.md").write_text(md_agent("foo", shared))
    (bundle / "foo.md").write_text(md_agent("foo", shared))
    (codex / "foo.toml").write_text(toml_agent("foo", codex_body))


def run(diverge):
    tmpdir = tempfile.mkdtemp(prefix="vp-check11-")
    root = pathlib.Path(tmpdir)
    build_tree(root, diverge)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_pack_agent_trinity()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap


# T1: PASS-symmetric — identical bodies across the three legs → 0 divergent →
# Check 11 OKs "all trinity-symmetric" with 0 failures.
n, cap = run(diverge=False)
if n != 0:
    failures.append(f"T1 (symmetric tree) expected 0 failures, got {n}: {cap}")
if "all trinity-symmetric" not in cap:
    failures.append(f"T1 (symmetric tree) expected 'all trinity-symmetric' in output: {cap}")

# T2: divergent-but-informational — the Codex leg diverges → comparator reports
# >=1 divergent → Check 11 REPORTS the divergence (INFO + "informational; not a
# failure") but returns 0 failures. This is the informational-never-fails
# contract. Count-free: we assert the divergent-branch fired and 0 failures, NOT
# a specific count.
n, cap = run(diverge=True)
if n != 0:
    failures.append(
        f"T2 (divergent tree) informational contract VIOLATED — expected 0 "
        f"failures (never blocks CI) even with divergence, got {n}: {cap}")
if "divergent" not in cap:
    failures.append(
        f"T2 (divergent tree) expected the divergent branch to fire (the word "
        f"'divergent' in Check 11 output), got: {cap}")
if "informational; not a failure" not in cap:
    failures.append(
        f"T2 (divergent tree) expected 'informational; not a failure' in output "
        f"(the never-fails OK line), got: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T2 (symmetric PASS + divergent-but-informational: reports divergence, 0 failures, never blocks CI)" ;;
    *) t_fail "End-to-end check_pack_agent_trinity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
# Check 11 is informational — it must run and NOT block CI on HEAD regardless
# of the real tree's divergence count. Assert the header appears and exit is 0;
# deliberately NO count assertion (so C4's landing position can never flip it).
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 11 > "$SCRATCH/e2e.out" 2>&1; then
    if grep -q "Check 11: Project agent trinity-rule symmetry" "$SCRATCH/e2e.out"; then
        t_pass "validate-pack.py exits 0; Check 11 runs and does not block CI at HEAD (informational)"
    else
        t_fail "validate-pack.py exits 0 but Check 11 header not detected" \
            "Tail: $(tail -10 "$SCRATCH/e2e.out")"
    fi
else
    if grep -q "Check 11: Project agent trinity-rule symmetry" "$SCRATCH/e2e.out"; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 11 ran but a check FAILED — Check 11 must be informational)" \
            "Tail: $(tail -40 "$SCRATCH/e2e.out")"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 11 did not run)" \
            "Tail: $(tail -40 "$SCRATCH/e2e.out")"
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
