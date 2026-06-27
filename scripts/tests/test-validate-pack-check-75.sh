#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-75.sh — synthetic fixture tests for
# BD-206 O13 Check 75 (project impl-plan phase/part/task naming conformance; the
# §3.5 GRACEFUL naming guard, pack-side empty-template leg).
#
# Check 75 enforces the §3.5 GRACEFUL naming convention — a FORMAT check, NOT a
# structural migration. It codifies the EXISTING inline convention as two fixed
# template regexes applied to the Phase-prefixed headings inside each
# `phase-N.md` entry:
#   - any H3 `### Phase-…` MUST match `### Phase-N.Part-x — `;
#   - any H4 `#### Phase-…` MUST match `#### Phase-N.Part-x.Task-k — `.
# GRACEFUL: it FIRES ONLY on a Phase-prefixed heading that violates the
# template. Epic-task `#### N.M — ` anchors + inline parts that are well-formed
# are tolerated (no fire); parts are not required; no forced refactor; no stored
# execution-order marker. BD-185 (per-part-file migration + serializability) is
# OUT of scope.
# The shipped template is EMPTY (no entries), so the live leg validates the
# empty-state; the in-memory `_check_75_validate` matcher is exercised on
# synthetic entries here (the BITE teeth). The CLIENT-side populated leg lives
# in `project-template/scripts/validate-docs.sh` (--self-test).
#
# REGISTERED: Check 75 IS in CHECK_REGISTRY. Group 0 asserts the registration
# landed + the dynamic count-invariant holds (never a hardcoded literal).
#
# Test infra is self-provisioned (in-memory matcher calls + the live empty
# tree; no real stream mutated).
#
# Usage: bash scripts/tests/test-validate-pack-check-75.sh

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
# Group 0: Module import + Check 75 symbols + registered + count-invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 75 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_implplan_naming', '_check_75_validate',
           '_check_75_self_check', '_check_75_violations']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-74).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 75 is REGISTERED: 75 must be in the registry.
nums = [t[0] for t in mod._build_check_registry()]
if 75 not in nums:
    print('FAIL_75_NOT_REGISTERED — Check 75 must be in CHECK_REGISTRY')
    sys.exit(1)
print('OK')
" > /tmp/vp-check75-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check75-import.out; then
    t_pass "imports + Check 75 symbols present + count invariant holds (dynamic) + Check 75 REGISTERED (75 in registry)"
else
    t_fail "Check 75 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check75-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: in-memory graceful naming matcher (the BITE teeth)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: in-memory graceful naming matcher (BITE teeth) ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# The gold heading shapes (EE-2): well-formed parts + part-tasks + tolerated
# epic-task `#### N.M — ` anchors all conform.
conforming = ("<!-- back -->\n"
              "## Phase 3 — Sample epic\n\n"
              "- **Entry-Type**: phase-epic\n\n"
              "### Tasks\n\n"
              "#### 3.1 — An epic task (tolerated; not Phase-prefixed)\n"
              "#### 3.2 — Another epic task\n\n"
              "### Phase-3.Part-a — A well-formed part\n\n"
              "#### Phase-3.Part-a.Task-1 — A well-formed part task\n"
              "#### Phase-3.Part-a.Task-2 — Another part task\n\n"
              "### Phase-3.Part-b — A second part\n")
parts_free = ("<!-- back -->\n"
              "## Phase 4 — Parts-free epic\n\n"
              "- **Entry-Type**: phase-epic\n\n"
              "### Tasks\n\n"
              "#### 4.1 — Only epic tasks here\n")
lightweight = ("<!-- back -->\n"
               "## Phase 5 — Epic\n\n"
               "- **Entry-Type**: phase-part\n")

def want(label, entries, expect_fail):
    got = bool(mod._check_75_validate(entries))
    if got != expect_fail:
        failures.append("%s: expected %s got %s"
                        % (label, "FAIL" if expect_fail else "PASS",
                           "FAIL" if got else "PASS"))

# Well-formed parts/tasks + tolerated epic-task anchors → PASS.
want("conforming-clean", {"phase-3.md": conforming}, False)
# Parts-free epic (epic tasks only) → PASS (parts not required).
want("parts-free-clean", {"phase-4.md": parts_free}, False)
# Lightweight phase-part entry (Entry-Type only, no headings) → PASS.
want("lightweight-part-clean", {"phase-5.md": lightweight}, False)
# Empty tree → PASS.
want("empty", {}, False)
# Malformed part H3 (capital part letter) → FAIL.
want("bad-part-h3",
     {"phase-6.md": "## Phase 6 — Epic\n\n### Phase-6.Part-A — Capital\n"},
     True)
# Malformed part H3 (no em-dash separator) → FAIL.
want("bad-part-h3-nodash",
     {"phase-7.md": "## Phase 7 — Epic\n\n### Phase-7.Part-a No em-dash\n"},
     True)
# Malformed part-task H4 (non-numeric task index) → FAIL.
want("bad-part-task-h4",
     {"phase-8.md": "## Phase 8 — Epic\n\n### Phase-8.Part-a — OK\n\n"
      "#### Phase-8.Part-a.Task-x — Non-numeric index\n"},
     True)
# Malformed part-task H4 (missing em-dash) → FAIL.
want("bad-part-task-h4-nodash",
     {"phase-9.md": "## Phase 9 — Epic\n\n### Phase-9.Part-a — OK\n\n"
      "#### Phase-9.Part-a.Task-1 Missing em-dash\n"},
     True)
# GRACEFUL: an epic-task `#### N.M — ` anchor (NOT Phase-prefixed) never fires,
# even when no parts exist.
want("epic-task-tolerated",
     {"phase-10.md": "## Phase 10 — Epic\n\n### Tasks\n\n#### 10.3 — Task\n"},
     False)
# GRACEFUL: a bare `### Tasks` / `### Verification` body section (not
# Phase-prefixed) is tolerated.
want("body-section-tolerated",
     {"phase-11.md": "## Phase 11 — Epic\n\n### Tasks\n\n### Verification\n"},
     False)
# _check_75_violations returns the exact malformed heading line (for the
# message), and returns [] on a conforming body.
v = mod._check_75_violations("### Phase-2.Part-A — bad\n### Phase-2.Part-a — ok\n")
if v != ["### Phase-2.Part-A — bad"]:
    failures.append("violations-list: expected only the bad heading, got %r" % v)

# The built-in self-check itself must report zero failures (matcher has teeth).
sc = mod._check_75_self_check()
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
    0) t_pass "in-memory matcher: conforming/parts-free/lightweight/empty + tolerated epic-task + body-section PASS; malformed part-H3/part-task-H4 (capital/no-dash/non-numeric) FAIL; violations-list exact; built-in self-check has teeth" ;;
    *) t_fail "Check 75 in-memory graceful naming matcher tests failed (see Python output)" ;;
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
    mod.check_project_implplan_naming()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'naming conformance holds' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
" > /tmp/vp-check75-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check75-live.out; then
    t_pass "Check 75 body runs clean on the live (empty) impl-plan template + self-check has teeth"
else
    t_fail "Check 75 body found a violation on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check75-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

rm -f /tmp/vp-check75-import.out /tmp/vp-check75-live.out

if (( FAIL == 0 )); then
    printf "\n\033[32mAll Check 75 tests passed.\033[0m\n"
    exit 0
fi
printf "\n\033[31mSome Check 75 tests failed.\033[0m\n"
exit 1
