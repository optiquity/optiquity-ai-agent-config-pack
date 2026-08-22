#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-65.sh — synthetic fixture
# tests for BD-243 Check 65 (operating-doc no-history gate;
# DESIGN-BD-243-FINAL.md §E + ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md
# the MOVE addendum).
#
# These tests exercise the operating-doc no-history gate — history-pattern
# count 0 OUTSIDE the pack-ops/.operating-doc-history-allowlist.txt
# allowlist (the teeth) — without mutating any real operating doc. Each
# test stages a synthetic operating-doc tree + a synthetic allowlist inside
# a tmp REPO_ROOT, monkeypatches the IN scope (_CHECK_65_OPERATING_DOCS) to
# the synthetic doc, invokes Check 65 against the tmp tree, and asserts
# PASS / FAIL as expected. Check 65 is ACTIVATED over the auto-discovered
# operating-doc IN set (BD-243 CG-14-prep-a repoint, model B) — these fixture
# tests verify the check FUNCTION in isolation by substituting a synthetic doc
# for the live IN set, so they pass regardless of the live tree's content.
# Cleanup runs on every exit path.
#
# Coverage:
#   Group 0: Module import + Check 65 symbol registration
#   Group 1: Synthetic-tree end-to-end —
#            T1 clean tree (no history pattern) PASSES
#            T2 injected date hit OUTSIDE allowlist FAILS (the teeth;
#               MOVED from the Check-44 test)
#            T3 injected SHA hit OUTSIDE allowlist FAILS (the teeth;
#               MOVED from the Check-44 test)
#            T4 allowlisted KEEP occurrences (K1 doc-ref, K9 date example)
#               snippet-covered PASS
#            T5 allowlist sized to KEEP-only — a DIFFERENT history hit on an
#               allowlisted doc still FAILS (allowlist is not a blanket;
#               MOVED-intent from the Check-44 test's T5)
#            T6 missing allowlist file => empty allowlist => every history
#               hit FAILS (fail-loud)
#            T7 R2 incident-regex tightening (BD-243 CG-14-prep-a): the
#               whole-word r"\bincident\b" pattern — T7a "incidents" /
#               "coincidental" do NOT match (clean); T7b standalone "incident"
#               DOES match (FAIL)
#   Group 2: End-to-end validate-pack.py exit-status on HEAD (Check 65 runs
#            over the auto-discovered operating-doc IN set; clean => exit 0)
#
# Usage: bash scripts/tests/test-validate-pack-check-65.sh

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

printf "\n=== Group 0: Module import + Check 65 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_operating_doc_no_history', '_check_65_load_allowlist',
            '_CHECK_65_FORBIDDEN_PATTERNS', '_CHECK_65_OPERATING_DOCS']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check65-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check65-import.out; then
    t_pass "validate-pack.py imports + Check 65 symbols registered"
else
    t_fail "validate-pack.py import or Check 65 symbol registration failed" \
        "$(cat /tmp/vp-check65-import.out)"
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

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W2
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.boundary_refs; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


failures = []

# The synthetic operating-doc IN set — ONE doc.
SYNTH_DOC = "pack-ops/SYNTH-OPERATING.md"

def run_check_with_synthetic(doc_body, allowlist_text):
    """Run check_operating_doc_no_history against a synthetic tree.

    doc_body:        full text of the synthetic operating doc.
    allowlist_text:  full text of a synthetic allowlist
                     (empty string => no allowlist file written => empty).

    Returns (failures_count, pass_msg_present, captured).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check65-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    (root / SYNTH_DOC).write_text(doc_body)
    if allowlist_text:
        (root / "pack-ops" / ".operating-doc-history-allowlist.txt").write_text(
            allowlist_text)

    saved_root = mod.REPO_ROOT
    saved_scope = mod._CHECK_65_OPERATING_DOCS
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    # Monkeypatch the IN scope to the single synthetic doc, substituting it for
    # the live auto-discovered IN set so the check FUNCTION is exercised in
    # isolation via this fixture (saved/restored around the call).
    _patch_attr(mod, "_CHECK_65_OPERATING_DOCS", (SYNTH_DOC,))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_operating_doc_no_history()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_65_OPERATING_DOCS", saved_scope)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    pass_msg = "0 = clean" in captured
    return (len(new_failures), pass_msg, captured)

# An allowlist admitting a K1-style live doc-ref AND a K9-style date example
# by snippet (content-anchored, not line-number-anchored).
ALLOWLIST_KEEP = (
    "doc: %s\n"
    "pattern: bd-tag\n"
    "snippet: ARCHITECTURE-BD-119.md\n"
    "reason: live doc cross-ref (synthetic K2).\n"
    "\n"
    "doc: %s\n"
    "pattern: date\n"
    "snippet: 2026-04-20\n"
    "reason: changelog filename date FORMAT example (synthetic K9).\n"
) % (SYNTH_DOC, SYNTH_DOC)

# T1: PASS — clean tree, no history pattern at all.
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "A forward-only operating doc with no history or audit-trail text.\n"
    "It issues imperatives without provenance, dates, or SHAs.\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc != 0:
    failures.append("T1 (clean tree PASS) expected 0 failures, got %d: %s" % (fc, cap))
if not pm:
    failures.append("T1 (clean tree PASS) expected the '0 = clean' OK message: %s" % cap)

# T2: FAIL — injected date hit OUTSIDE the allowlist (MOVED from Check-44).
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "This rule was locked on 2026-05-30 during the recovery.\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc < 1:
    failures.append("T2 (injected date FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "OUTSIDE the allowlist" not in cap:
    failures.append("T2 (injected date FAIL) expected 'OUTSIDE the allowlist' in output: %s" % cap)
if "2026-05-30" not in cap:
    failures.append("T2 (injected date FAIL) expected the offending line snippet in output: %s" % cap)

# T3: FAIL — injected SHA hit OUTSIDE the allowlist (MOVED from Check-44).
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "The rule was introduced in commit deadbeef1234 (a SHA).\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc < 1:
    failures.append("T3 (injected SHA FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "deadbeef1234" not in cap:
    failures.append("T3 (injected SHA FAIL) expected the SHA hit in output: %s" % cap)

# T4: PASS — allowlisted KEEP occurrences (a doc-ref line + a date-example
#     line), each snippet-covered, admitted and not failed.
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "See ARCHITECTURE-BD-119.md for the migrator framework.\n"
    "Changelog files are named like 2026-04-20-phase-35.md.\n"
)
fc, pm, cap = run_check_with_synthetic(body, ALLOWLIST_KEEP)
if fc != 0:
    failures.append("T4 (allowlisted KEEP PASS) expected 0 failures, got %d: %s" % (fc, cap))
if not pm:
    failures.append("T4 (allowlisted KEEP PASS) expected the '0 = clean' OK message: %s" % cap)
if "2 allowlisted" not in cap:
    failures.append("T4 (allowlisted KEEP PASS) expected '2 allowlisted' occurrence count: %s" % cap)

# T5: FAIL — allowlist sized to KEEP-only is NOT a blanket: a DIFFERENT
#     history hit (a non-allowlisted date) on the same allowlisted doc still
#     FAILS (MOVED-intent from the Check-44 T5).
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "See ARCHITECTURE-BD-119.md for the migrator framework.\n"
    "But this incident on 2026-05-17 is provenance and must FAIL.\n"
)
fc, pm, cap = run_check_with_synthetic(body, ALLOWLIST_KEEP)
if fc < 1:
    failures.append("T5 (KEEP-only allowlist not a blanket FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "2026-05-17" not in cap:
    failures.append("T5 (KEEP-only allowlist not a blanket FAIL) expected the non-allowlisted hit in output: %s" % cap)

# T6: FAIL — missing allowlist file => empty allowlist => the otherwise-KEEP
#     doc-ref line now FAILS (fail-loud, matches Check 44).
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "See ARCHITECTURE-BD-119.md for the migrator framework.\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc < 1:
    failures.append("T6 (missing allowlist fail-loud) expected >=1 failure, got %d: %s" % (fc, cap))

# T7: R2 incident-regex tightening (BD-243 CG-14-prep-a). The forbidden
#     pattern is r"\bincident\b" (whole word), NOT a bare substring. The
#     substring forms "incidents" / "coincidental" must NOT trip the gate
#     (they are not history-narrative), while a STANDALONE "incident" still
#     DOES. T7a = the two false-positive forms PASS clean; T7b = a standalone
#     "incident" FAILS.
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "We surface individual incidents in the feedback channel, which is not\n"
    "coincidental — both are routine forward-looking workflow prose.\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc != 0:
    failures.append("T7a (incidents/coincidental do NOT match \\bincident\\b) expected 0 failures, got %d: %s" % (fc, cap))
if not pm:
    failures.append("T7a (incidents/coincidental clean) expected the '0 = clean' OK message: %s" % cap)

body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "The audit incident is provenance narration and must FAIL the gate.\n"
)
fc, pm, cap = run_check_with_synthetic(body, "")
if fc < 1:
    failures.append("T7b (standalone 'incident' DOES match \\bincident\\b) expected >=1 failure, got %d: %s" % (fc, cap))
if "incident" not in cap:
    failures.append("T7b (standalone 'incident' FAIL) expected the offending line in output: %s" % cap)

# T8: DEAD-RECORD ADVISORY (declare-verify-backing). The allowlist header
#     claims it is "sized to the KEEP set EXACTLY"; nothing verified that a
#     record still matches anything, so a record whose exempted line was
#     edited or deleted sat there invisibly. Check 65 now reports per-record
#     backing. T8a: a live record is counted LIVE and no WARN fires.
#     T8b: a record whose snippet matches NOTHING is reported dead, WARNs,
#     and — critically — does NOT change the failure count (ADVISORY ONLY,
#     so a legitimately un-triggered record can never red CI).
body = (
    "# SYNTH-OPERATING.md\n"
    "\n"
    "See ARCHITECTURE-BD-119.md for the migrator framework.\n"
)
ALLOWLIST_ONE = (
    "doc: %s\n"
    "pattern: bd-tag\n"
    "snippet: ARCHITECTURE-BD-119.md\n"
    "reason: live doc cross-ref (synthetic K2).\n"
) % SYNTH_DOC

fc, pm, cap = run_check_with_synthetic(body, ALLOWLIST_ONE)
if "1 live" not in cap:
    failures.append("T8a expected '1 live' record in the backing summary: %s" % cap)
if "0 dead" not in cap:
    failures.append("T8a expected '0 dead' records for a fully-live allowlist: %s" % cap)
if "matched NO line" in cap:
    failures.append("T8a a live allowlist must emit no dead-record WARN: %s" % cap)

ALLOWLIST_WITH_DEAD = ALLOWLIST_ONE + (
    "\n"
    "doc: %s\n"
    "pattern: bd-tag\n"
    "snippet: ZZZ-MATCHES-NOTHING-ZZZ\n"
    "reason: synthetic DEAD record (must be reported, must not fail).\n"
) % SYNTH_DOC
fc, pm, cap = run_check_with_synthetic(body, ALLOWLIST_WITH_DEAD)
if "matched NO line" not in cap:
    failures.append("T8b expected the dead-record WARN: %s" % cap)
if "ZZZ-MATCHES-NOTHING-ZZZ" not in cap:
    failures.append("T8b dead-record WARN must name the dead snippet: %s" % cap)
if "1 dead" not in cap:
    failures.append("T8b expected '1 dead' in the backing summary: %s" % cap)
if fc != 0:
    failures.append("T8b ADVISORY ONLY — a dead record must not add a failure, got %d: %s" % (fc, cap))
if not pm:
    failures.append("T8b a dead record must not break the '0 = clean' PASS: %s" % cap)

# T9: a record naming a doc OUTSIDE the scanned IN set can never fire, and is
#     reported separately — also advisory, never a gate.
ALLOWLIST_UNSCANNED = ALLOWLIST_ONE + (
    "\n"
    "doc: pack-ops/NO-SUCH-OPERATING-DOC.md\n"
    "pattern: bd-tag\n"
    "snippet: ZZZ-UNSCANNED-ZZZ\n"
    "reason: synthetic record on a doc outside the IN set.\n"
)
fc, pm, cap = run_check_with_synthetic(body, ALLOWLIST_UNSCANNED)
if "outside the scanned operating-doc IN set" not in cap:
    failures.append("T9 expected the unscanned-doc WARN: %s" % cap)
if "1 on unscanned docs" not in cap:
    failures.append("T9 expected '1 on unscanned docs' in the backing summary: %s" % cap)
if fc != 0:
    failures.append("T9 ADVISORY ONLY — an unscanned-doc record must not add a failure, got %d: %s" % (fc, cap))

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T7 (clean / date-FAIL / SHA-FAIL / allowlisted-KEEP / KEEP-only-not-blanket / fail-loud / R2 incident whole-word)" ;;
    *) t_fail "End-to-end check_operating_doc_no_history tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 65 > /tmp/vp-check65-e2e.out 2>&1; then
    if grep -q "Check 65: operating-doc no-history gate" /tmp/vp-check65-e2e.out \
       && grep -q "Check 65 — .* operating doc(s) scanned" /tmp/vp-check65-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 65 runs clean over the live operating-doc IN set at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 65 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check65-e2e.out)"
    fi
else
    if grep -q "Check 65: operating-doc no-history gate" /tmp/vp-check65-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 65 ran but found a history pattern outside the allowlist)" \
            "Tail: $(tail -40 /tmp/vp-check65-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 65 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check65-e2e.out)"
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
