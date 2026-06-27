#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-74.sh — synthetic fixture tests for
# BD-206 O12 Check 74 (project changelog conformance; the structured
# changelog conformance rule set, pack-side empty-template leg).
#
# Check 74 enforces the reconciled rule (design §3.4 / G-2/G-2b), parsed from
# the changelog `_rules.md` `## Entry structure` schema SSOT (never hard-coded):
#   (1) a NARRATIVE field is required for EVERY entry — `**Summary**:` OR
#       `**Scope**:` (narrative-fields); it is the sole required field;
#   (2) entry-max-lines cap (≤ 180; gold max 130);
#   (3) summary-max-words cap (≤ 250; gold max 243; reads Summary OR Scope).
# `Test count` and `Files` (any `**Files <verb>**:` label) are ADVISORY /
# admitted, not required.
# The shipped template is EMPTY (no entries), so the live leg validates the
# empty-state; the in-memory `_check_74_validate` matcher is exercised on
# synthetic entries here (the BITE teeth). The CLIENT-side populated leg lives
# in `project-template/scripts/validate-docs.sh` (--self-test).
#
# REGISTERED: Check 74 IS in CHECK_REGISTRY. Group 0 asserts the registration
# landed + the dynamic count-invariant holds (never a hardcoded literal).
#
# Test infra is self-provisioned (in-memory matcher calls + the live empty
# tree; no real stream mutated).
#
# Usage: bash scripts/tests/test-validate-pack-check-74.sh

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
# Group 0: Module import + Check 74 symbols + registered + count-invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 74 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_changelog_conformance', '_check_74_validate',
           '_check_74_self_check', '_check_74_caps',
           '_check_74_summary_words']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-73).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 74 is REGISTERED: 74 must be in the registry.
nums = [t[0] for t in mod._build_check_registry()]
if 74 not in nums:
    print('FAIL_74_NOT_REGISTERED — Check 74 must be in CHECK_REGISTRY')
    sys.exit(1)
print('OK')
" > /tmp/vp-check74-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check74-import.out; then
    t_pass "imports + Check 74 symbols present + count invariant holds (dynamic) + Check 74 REGISTERED (74 in registry)"
else
    t_fail "Check 74 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check74-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: in-memory reconciled matcher (the BITE teeth)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: in-memory reconciled matcher (BITE teeth) ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

schema = {
    "core-fields": "narrative",
    "narrative-fields": "Summary Scope",
    "advisory-fields": '"Test count" Files',
    "entry-max-lines": "180",
    "summary-max-words": "250",
}
code_ok = ("### 2026-04-20 — Phase 35 — Sample\n\n"
           "**Summary**: did the thing.\n"
           "**Test count**: 12 passing\n"
           "**Files modified (3)**: a.swift, b.swift, c.swift\n")
narrative_ok = ("### 2026-03-30 — v8 Migration — Pack\n\n"
                "**Summary**: narrative-only entry, no code changed.\n")
scope_ok = ("### 2026-03-27 — Phase 14 — Test Audit\n\n"
            "**Scope**: 24-item audit adding test coverage.\n")

def want(label, entries, expect_fail):
    got = bool(mod._check_74_validate(entries, schema))
    if got != expect_fail:
        failures.append("%s: expected %s got %s"
                        % (label, "FAIL" if expect_fail else "PASS",
                           "FAIL" if got else "PASS"))

# Code-bearing with Summary + advisory fields → PASS.
want("code-clean", {"a.md": code_ok}, False)
# Narrative-only (Summary, no advisory fields) → PASS.
want("narrative-only-clean", {"b.md": narrative_ok}, False)
# Scope-only narrative (no Summary, no advisory fields) → PASS.
want("scope-only-clean", {"s.md": scope_ok}, False)
# Empty tree → PASS.
want("empty", {}, False)
# Missing Files (Summary + Test) → PASS (Files advisory).
want("missing-files", {"c.md": "### 2026-04-20 — Phase 9 — X\n\n"
     "**Summary**: did it.\n**Test count**: 4 passing\n"}, False)
# Missing Test count (Summary + Files) → PASS (Test advisory).
want("missing-testcount", {"e.md": "### 2026-04-20 — Phase 9 — X\n\n"
     "**Summary**: did it.\n**Files modified**: a.swift\n"}, False)
# Missing narrative (Files + Test, no Summary/Scope) → FAIL (R1).
want("missing-summary", {"d.md": "### 2026-04-20 — Phase 9 — X\n\n"
     "**Files modified**: a.swift\n**Test count**: 4 passing\n"}, True)
# No narrative at all (prose only) → FAIL (R1).
want("no-narrative",
     {"f.md": "### 2026-03-30 — Migration — Y\n\nSome prose.\n"}, True)
# entry-max-lines violation → FAIL.
want("entry-too-long", {"g.md": code_ok + ("\nline\n" * 200)}, True)
# summary-max-words violation → FAIL.
want("summary-too-long", {"h.md": "### 2026-04-20 — Phase 9 — X\n\n"
     "**Summary**: " + ("word " * 260) + "\n"
     "**Test count**: 4 passing\n**Files modified**: a.swift\n"}, True)
# Scope narrative over the word cap → FAIL (R3 reads Scope now).
want("scope-over-words", {"k.md": "### 2026-03-27 — Phase 14 — Audit\n\n"
     "**Scope**: " + ("word " * 260) + "\n"}, True)
# Caps read FROM schema: a tighter schema cap bites the same entry.
# code_ok's Summary "did the thing." = 3 words; cap=2 (>) → FAIL.
tight = dict(schema); tight["summary-max-words"] = "2"
sw = bool(mod._check_74_validate({"j.md": code_ok}, tight))
if not sw:
    failures.append("schema-driven-cap: tight summary-max-words=2 should FAIL")
# And cap=3 (== words, not >) → PASS (boundary: cap is a strict >).
sw3 = bool(mod._check_74_validate(
    {"j.md": code_ok}, dict(schema, **{"summary-max-words": "3"})))
if sw3:
    failures.append("schema-driven-cap: summary-max-words=3 (==) should PASS")

# The built-in self-check itself must report zero failures (matcher has teeth).
sc = mod._check_74_self_check()
if sc:
    failures.append("self-check reported failures: %s" % sc)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "in-memory matcher: code/narrative-only/scope-only/empty PASS; missing-files + missing-testcount PASS (advisory); missing-summary/no-narrative + over-cap + scope-over-words FAIL; schema-driven cap bites; built-in self-check has teeth" ;;
    *) t_fail "Check 74 in-memory reconciled matcher tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: live-tree in-process body invocation (the shipped EMPTY template)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: live-tree in-process body invocation (empty template) ===\n"

python3 -c "
import sys, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_project_changelog_conformance()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'conformance holds' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
" > /tmp/vp-check74-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check74-live.out; then
    t_pass "Check 74 body runs clean on the live (empty) changelog template + self-check has teeth"
else
    t_fail "Check 74 body found a violation on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check74-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

rm -f /tmp/vp-check74-import.out /tmp/vp-check74-live.out

if (( FAIL == 0 )); then
    printf "\n\033[32mAll Check 74 tests passed.\033[0m\n"
    exit 0
fi
printf "\n\033[31mSome Check 74 tests failed.\033[0m\n"
exit 1
