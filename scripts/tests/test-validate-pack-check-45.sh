#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-45.sh — synthetic fixture
# tests for BD-196 (C3) Check 45 (pack-memory rule↔rationale
# bijection; ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2).
#
# These tests exercise the set-equality bijection between the corpus
# `## Pack memory` `[rationale: slug]` set (CLAUDE.md representative)
# and the `## <slug>` heading set in pack-ops/PACK-MEMORY-RATIONALE.md,
# without mutating any real CLAUDE.md / pack-ops file. Each end-to-end
# test stages a synthetic CLAUDE.md + PACK-MEMORY-RATIONALE.md inside a
# tmp REPO_ROOT, invokes Check 45 against the tmp tree, and asserts
# PASS / FAIL as expected. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 45 symbol registration
#   Group 1: Synthetic-tree end-to-end (PASS + injected-FAIL cases)
#   Group 2: End-to-end validate-pack.py exit-status on HEAD (18==18)
#
# Usage: bash scripts/tests/test-validate-pack-check-45.sh

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
# Group 0: Module import + new symbol reachable
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 45 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_pack_memory_rationale_bijection']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check45-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check45-import.out; then
    t_pass "validate-pack.py imports + Check 45 symbol registered"
else
    t_fail "validate-pack.py import or Check 45 symbol registration failed" \
        "$(cat /tmp/vp-check45-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: End-to-end synthetic-tree tests (PASS + injected fails) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_with_synthetic(claude_md: str, rationale_md: str) -> tuple:
    """Run check_pack_memory_rationale_bijection against a synthetic tree.

    claude_md: full text of a synthetic CLAUDE.md (must include a
               `## Pack memory` H2 section bounding the [rationale:] tags).
    rationale_md: full text of a synthetic pack-ops/PACK-MEMORY-RATIONALE.md.

    Returns (failures_count, pass_msg_present, captured_output).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check45-")
    root = pathlib.Path(tmpdir)
    (root / "CLAUDE.md").write_text(claude_md)
    (root / "pack-ops").mkdir()
    (root / "pack-ops" / "PACK-MEMORY-RATIONALE.md").write_text(rationale_md)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_pack_memory_rationale_bijection()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    pass_msg = "bijection holds" in captured
    return (len(new_failures), pass_msg, captured)

# Shared synthetic corpus header — the `## Pack memory` section bounds
# the [rationale:] scan; a [rationale:] in a DIFFERENT section must be
# ignored (T4 below relies on this).
CORPUS_HEADER = (
    "# CLAUDE.md — synthetic\n"
    "\n"
    "## Rules for agents working on this repo\n"
    "Some rule with a stray [rationale: not-counted] outside Pack memory.\n"
    "\n"
    "## Pack memory (project-local learnings)\n"
)
CORPUS_TAIL = (
    "\n"
    "## Project goals (synthetic)\n"
    "More prose with [rationale: also-not-counted].\n"
)

# T1: PASS — balanced 2==2 bijection.
claude = CORPUS_HEADER + (
    "- **Rule one.** Imperative one. [rationale: rule-one]\n"
    "- **Rule two.** Imperative two. [rationale: rule-two]\n"
) + CORPUS_TAIL
rationale = (
    "# PACK-MEMORY-RATIONALE.md — synthetic\n"
    "\n"
    "## rule-one\n"
    "Why one.\n"
    "\n"
    "## rule-two\n"
    "Why two.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(claude, rationale)
if fail_count != 0:
    failures.append(f"T1 (balanced 2==2 PASS) expected 0 failures, got {fail_count}: {captured}")
if not pass_msg:
    failures.append(f"T1 (balanced 2==2 PASS) expected bijection-holds OK message: {captured}")

# T2: FAIL — orphan corpus slug (a [rationale:] with no `## slug` heading).
claude = CORPUS_HEADER + (
    "- **Rule one.** Imperative one. [rationale: rule-one]\n"
    "- **Rule two.** Imperative two. [rationale: rule-two]\n"
    "- **Rule three.** Imperative three. [rationale: rule-three-orphan]\n"
) + CORPUS_TAIL
rationale = (
    "# PACK-MEMORY-RATIONALE.md — synthetic\n"
    "\n"
    "## rule-one\n"
    "Why one.\n"
    "\n"
    "## rule-two\n"
    "Why two.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(claude, rationale)
if fail_count < 1:
    failures.append(
        f"T2 (orphan corpus slug FAIL) expected >=1 failure, got {fail_count}: {captured}"
    )
if "rule-three-orphan" not in captured:
    failures.append(
        f"T2 (orphan corpus slug FAIL) expected the orphan slug named in output: {captured}"
    )

# T3: FAIL — orphan rationale heading (a `## slug` with no corpus [rationale:]).
claude = CORPUS_HEADER + (
    "- **Rule one.** Imperative one. [rationale: rule-one]\n"
    "- **Rule two.** Imperative two. [rationale: rule-two]\n"
) + CORPUS_TAIL
rationale = (
    "# PACK-MEMORY-RATIONALE.md — synthetic\n"
    "\n"
    "## rule-one\n"
    "Why one.\n"
    "\n"
    "## rule-two\n"
    "Why two.\n"
    "\n"
    "## rule-three-orphan\n"
    "Why orphan (no live corpus pointer).\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(claude, rationale)
if fail_count < 1:
    failures.append(
        f"T3 (orphan rationale heading FAIL) expected >=1 failure, got {fail_count}: {captured}"
    )
if "rule-three-orphan" not in captured:
    failures.append(
        f"T3 (orphan rationale heading FAIL) expected the orphan heading named in output: {captured}"
    )

# T4: PASS — section-scoping: stray [rationale:] tags OUTSIDE the
#     `## Pack memory` section (in CORPUS_HEADER + CORPUS_TAIL) must be
#     excluded from the set, so the in-section 1==1 stays balanced.
claude = CORPUS_HEADER + (
    "- **Only rule.** Imperative. [rationale: only-rule]\n"
) + CORPUS_TAIL
rationale = (
    "# PACK-MEMORY-RATIONALE.md — synthetic\n"
    "\n"
    "## only-rule\n"
    "Why only.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(claude, rationale)
if fail_count != 0:
    failures.append(
        f"T4 (section-scoping PASS — out-of-section tags ignored) expected 0 failures, "
        f"got {fail_count}: {captured}"
    )

# T5: FAIL — BOTH directions orphaned simultaneously (defensive: two
#     distinct FAILs emitted).
claude = CORPUS_HEADER + (
    "- **Rule one.** Imperative one. [rationale: rule-one]\n"
    "- **Rule x.** Imperative x. [rationale: corpus-only]\n"
) + CORPUS_TAIL
rationale = (
    "# PACK-MEMORY-RATIONALE.md — synthetic\n"
    "\n"
    "## rule-one\n"
    "Why one.\n"
    "\n"
    "## rationale-only\n"
    "Why rationale-only (no live corpus pointer).\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(claude, rationale)
if fail_count < 2:
    failures.append(
        f"T5 (both-direction orphans FAIL) expected >=2 failures, got {fail_count}: {captured}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T5 (PASS / orphan-corpus / orphan-rationale / section-scope / both)" ;;
    *) t_fail "End-to-end check_pack_memory_rationale_bijection tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: End-to-end validate-pack.py exit-status on HEAD (18==18)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check45-e2e.out 2>&1; then
    if grep -q "Check 45: pack-memory rule↔rationale bijection" /tmp/vp-check45-e2e.out \
       && grep -q "Check 45 — .* corpus .* pointer(s); .* rationale .* section(s); sets are equal" /tmp/vp-check45-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 45 runs and reports the bijection holds at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 45 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check45-e2e.out)"
    fi
else
    # validate-pack.py exit non-zero may indicate Check 45 caught a real
    # bijection drift at HEAD; verify Check 45 ran (header present)
    # before declaring fail.
    if grep -q "Check 45: pack-memory rule↔rationale bijection" /tmp/vp-check45-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 45 ran but found a bijection orphan)" \
            "Tail: $(tail -40 /tmp/vp-check45-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 45 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check45-e2e.out)"
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
