#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-44.sh — synthetic fixture
# tests for BD-196 (C10) Check 44 (M4 durable-doc concision gate;
# ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 M4 + §7).
#
# These tests exercise the M4 concision gate — forbidden-pattern count
# 0 OUTSIDE the pack-ops/.concision-allowlist.txt allowlist (the teeth)
# + per-doc advisory length — without mutating any real pack-ops doc.
# Each end-to-end test stages a synthetic durable-doc tree + a synthetic
# allowlist inside a tmp REPO_ROOT, monkeypatches the M4 doc-class to the
# synthetic doc, invokes Check 44 against the tmp tree, and asserts
# PASS / FAIL as expected. Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 44 symbol registration
#   Group 1: Synthetic-tree end-to-end —
#            T1 clean tree (no forbidden pattern) PASSES
#            T2 injected STRIP hit OUTSIDE allowlist FAILS (the teeth)
#            T3 allowlisted occurrence (snippet-covered) PASSES
#            T4 over-ceiling doc emits ADVISORY but does NOT fail (soft)
#            T5 allowlist sized to KEEP-only — a DIFFERENT forbidden hit
#               on the same doc still FAILS (allowlist is not a blanket)
#   Group 2: End-to-end validate-pack.py exit-status on HEAD (Check 44
#            runs clean: 0 forbidden outside allowlist)
#
# Usage: bash scripts/tests/test-validate-pack-check-44.sh

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

printf "\n=== Group 0: Module import + Check 44 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_durable_doc_concision', '_check_44_load_allowlist',
            '_CHECK_44_FORBIDDEN_PATTERNS', '_CHECK_44_DURABLE_DOCS']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check44-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check44-import.out; then
    t_pass "validate-pack.py imports + Check 44 symbols registered"
else
    t_fail "validate-pack.py import or Check 44 symbol registration failed" \
        "$(cat /tmp/vp-check44-import.out)"
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

# The synthetic M4 doc class — ONE doc with a generous advisory ceiling
# (so length never confounds the forbidden-pattern teeth tests) plus a
# tight-ceiling variant used by the advisory test.
SYNTH_DOC = "pack-ops/SYNTH-DURABLE.md"

def run_check_with_synthetic(doc_body: str, allowlist_text: str,
                             advisory_ceiling: int = 10000) -> tuple:
    """Run check_durable_doc_concision against a synthetic tree.

    doc_body:        full text of the synthetic durable doc.
    allowlist_text:  full text of a synthetic .concision-allowlist.txt
                     (empty string => no allowlist file written).
    advisory_ceiling: per-doc advisory ceiling for the synthetic doc.

    Returns (failures_count, pass_msg_present, advisory_present, captured).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check44-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    (root / SYNTH_DOC).write_text(doc_body)
    if allowlist_text:
        (root / "pack-ops" / ".concision-allowlist.txt").write_text(allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_docs = mod._CHECK_44_DURABLE_DOCS
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    # Monkeypatch the M4 doc class to the single synthetic doc.
    mod._CHECK_44_DURABLE_DOCS = ((SYNTH_DOC, advisory_ceiling),)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_durable_doc_concision()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod._CHECK_44_DURABLE_DOCS = saved_docs
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    pass_msg = "0 = clean" in captured
    advisory = "ADVISORY:" in captured
    return (len(new_failures), pass_msg, advisory, captured)

# An allowlist record admitting one operational 'will' occurrence by snippet.
ALLOWLIST_WILL = (
    "doc: %s\n"
    "pattern: will\n"
    "snippet: the migrator will route the script\n"
    "reason: operational behavioral will (synthetic).\n"
) % SYNTH_DOC

# T1: PASS — clean tree, no forbidden pattern at all.
body = (
    "# SYNTH-DURABLE.md\n"
    "\n"
    "A forward-only rule doc with no report-only artifacts.\n"
    "It states imperatives without dates, SHAs, or temporal promises.\n"
)
fc, pm, adv, cap = run_check_with_synthetic(body, "")
if fc != 0:
    failures.append(f"T1 (clean tree PASS) expected 0 failures, got {fc}: {cap}")
if not pm:
    failures.append(f"T1 (clean tree PASS) expected the '0 = clean' OK message: {cap}")

# T2: FAIL — injected STRIP hit (a date) OUTSIDE the allowlist.
body = (
    "# SYNTH-DURABLE.md\n"
    "\n"
    "This rule was locked on 2026-05-30 during the recovery.\n"
)
fc, pm, adv, cap = run_check_with_synthetic(body, "")
if fc < 1:
    failures.append(f"T2 (injected date STRIP FAIL) expected >=1 failure, got {fc}: {cap}")
if "OUTSIDE the allowlist" not in cap:
    failures.append(f"T2 (injected date STRIP FAIL) expected 'OUTSIDE the allowlist' in output: {cap}")
if "2026-05-30" not in cap:
    failures.append(f"T2 (injected date STRIP FAIL) expected the offending line snippet in output: {cap}")

# T3: PASS — an allowlisted operational 'will' occurrence (snippet-covered).
body = (
    "# SYNTH-DURABLE.md\n"
    "\n"
    "When a project adds a script the migrator will route the script\n"
    "through the three-way text dispatch.\n"
)
fc, pm, adv, cap = run_check_with_synthetic(body, ALLOWLIST_WILL)
if fc != 0:
    failures.append(f"T3 (allowlisted will PASS) expected 0 failures, got {fc}: {cap}")
if not pm:
    failures.append(f"T3 (allowlisted will PASS) expected the '0 = clean' OK message: {cap}")
if "1 allowlisted" not in cap:
    failures.append(f"T3 (allowlisted will PASS) expected '1 allowlisted' occurrence count: {cap}")

# T4: ADVISORY (soft) — doc exceeds a tight per-doc ceiling but carries NO
#     forbidden pattern: emits an ADVISORY notice and does NOT fail.
body = "# SYNTH-DURABLE.md\n" + ("clean prose line\n" * 20)
fc, pm, adv, cap = run_check_with_synthetic(body, "", advisory_ceiling=5)
if fc != 0:
    failures.append(f"T4 (over-ceiling ADVISORY soft) expected 0 failures, got {fc}: {cap}")
if not adv:
    failures.append(f"T4 (over-ceiling ADVISORY soft) expected an 'ADVISORY:' notice: {cap}")

# T5: FAIL — allowlist sized to KEEP-only is NOT a blanket: a DIFFERENT
#     forbidden hit (a SHA) on the same doc, not covered by the 'will'
#     snippet, still FAILS.
body = (
    "# SYNTH-DURABLE.md\n"
    "\n"
    "When a project adds a script the migrator will route the script\n"
    "through dispatch. Introduced in commit deadbeef1234 (a SHA).\n"
)
fc, pm, adv, cap = run_check_with_synthetic(body, ALLOWLIST_WILL)
if fc < 1:
    failures.append(f"T5 (KEEP-only allowlist not a blanket FAIL) expected >=1 failure, got {fc}: {cap}")
if "deadbeef1234" not in cap:
    failures.append(f"T5 (KEEP-only allowlist not a blanket FAIL) expected the SHA hit in output: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T5 (clean / injected-STRIP / allowlisted / advisory-soft / KEEP-only-not-blanket)" ;;
    *) t_fail "End-to-end check_durable_doc_concision tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 44 > /tmp/vp-check44-e2e.out 2>&1; then
    if grep -q "Check 44: M4 durable-doc concision gate" /tmp/vp-check44-e2e.out \
       && grep -q "Check 44 — .* durable doc(s) scanned; 0 forbidden pattern(s) outside the allowlist" /tmp/vp-check44-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 44 runs clean (0 forbidden outside allowlist) at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 44 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check44-e2e.out)"
    fi
else
    # Non-zero exit may indicate Check 44 caught a real M4 violation at HEAD;
    # verify Check 44 ran (header present) before declaring fail.
    if grep -q "Check 44: M4 durable-doc concision gate" /tmp/vp-check44-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 44 ran but found a forbidden pattern outside the allowlist)" \
            "Tail: $(tail -40 /tmp/vp-check44-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 44 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check44-e2e.out)"
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
