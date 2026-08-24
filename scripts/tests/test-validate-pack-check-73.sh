#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-73.sh — synthetic fixture tests for
# BD-206 O11 Check 73 (project impl-plan `_index.md` consistency; the
# MANDATORY `_index.md` validation, pack-side empty-template leg).
#
# Check 73 enforces the TWO hard properties (DECISIONS-BD-206-RESTART.md G-3)
# against the shipped `project-template/docs/project/implementation-plan/`
# stream + a synthetic self-check that the matcher BITES:
#   (1) hard-dependency-order consistency — the `_index.md` serial order is a
#       VALID topological order of the rule-based deps (Blockers/Unblocks/
#       Dependencies/Prerequisite SSOT);
#   (2) per-entry↔`_index.md` membership sync — exact (no missing/extra),
#       analogous to the `_toc.md`-sync Check 33.
# The shipped template is EMPTY (no phase-*.md), so the live leg validates the
# empty-state; the in-memory `_check_73_validate` matcher is exercised on
# synthetic populated trees here (the BITE teeth). The CLIENT-side populated
# leg lives in `project-template/scripts/validate-docs.sh` (--self-test); the
# generator + shared validator in `scripts/lib/per-entry/index-generate.sh`
# (covered by `test-index-generate.sh`).
#
# REGISTERED: Check 73 IS in CHECK_REGISTRY. Group 0 asserts the
# registration landed + the dynamic count-invariant holds.
#
# Test infra is self-provisioned (in-memory matcher calls + the live empty
# tree; no real stream mutated).
#
# Usage: bash scripts/tests/test-validate-pack-check-73.sh

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
# Group 0: Module import + Check 73 symbols + registered + count-invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 73 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_index_consistency', '_check_73_validate',
           '_check_73_collect', '_check_73_toposort',
           '_check_73_parse_index_order', '_check_73_self_check']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-71).
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 73 is REGISTERED: 73 must be in the registry.
nums = [t[0] for t in mod._build_check_registry()]
if 73 not in nums:
    print('FAIL_73_NOT_REGISTERED — Check 73 must be in CHECK_REGISTRY')
    sys.exit(1)
print('OK')
" > /tmp/vp-check73-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check73-import.out; then
    t_pass "imports + Check 73 symbols present + count invariant holds (dynamic) + Check 73 REGISTERED (73 in registry)"
else
    t_fail "Check 73 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check73-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: in-memory two-property matcher (the BITE teeth)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: in-memory two-property matcher (BITE teeth) ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

p0 = "## Phase 0 — Bootstrap\n- **Blockers**: none\n- **Unblocks**: phase-1\n"
p1 = "## Phase 1 — Middle\n- **Blockers**: phase-0\n- **Unblocks**: phase-2\n"
p2 = "## Phase 2 — Final\n- **Blockers**: phase-1\n- **Unblocks**: none\n"
entries = {"0": p0, "1": p1, "2": p2}
good = ("## Serial order\n\n"
        "- [phase-0](./phase-0.md) — Bootstrap\n"
        "- [phase-1](./phase-1.md) — Middle\n"
        "- [phase-2](./phase-2.md) — Final\n")

def want(label, ents, idx, expect_fail):
    got = bool(mod._check_73_validate(ents, idx))
    if got != expect_fail:
        failures.append("%s: expected %s got %s"
                        % (label, "FAIL" if expect_fail else "PASS",
                           "FAIL" if got else "PASS"))

# Clean conforming tree → PASS.
want("clean", entries, good, False)
# Greenfield (no phases, no index) → PASS.
want("empty", {}, None, False)
# ORDER violation (reversed) → FAIL.
bad = ("## Serial order\n\n"
       "- [phase-2](./phase-2.md) — Final\n"
       "- [phase-1](./phase-1.md) — Middle\n"
       "- [phase-0](./phase-0.md) — Bootstrap\n")
want("order-violation", entries, bad, True)
# MEMBERSHIP missing (drop phase-2) → FAIL.
miss = ("## Serial order\n\n"
        "- [phase-0](./phase-0.md) — Bootstrap\n"
        "- [phase-1](./phase-1.md) — Middle\n")
want("membership-missing", entries, miss, True)
# MEMBERSHIP extra (ghost) → FAIL.
want("membership-extra", entries, good + "- [phase-9](./phase-9.md) — Ghost\n", True)
# MISSING index with phases present → FAIL.
want("missing-index", entries, None, True)
# Ghost in an empty tree → FAIL.
want("ghost-empty", {}, "## Serial order\n\n- [phase-3](./phase-3.md) — X\n", True)
# CYCLE → FAIL.
cyc = {"0": "## Phase 0 — A\n- **Blockers**: phase-1\n",
       "1": "## Phase 1 — B\n- **Blockers**: phase-0\n"}
cyc_idx = ("## Serial order\n\n"
           "- [phase-0](./phase-0.md) — A\n"
           "- [phase-1](./phase-1.md) — B\n")
want("cycle", cyc, cyc_idx, True)
# Judgment-free: two independent phases either order → PASS.
indep = {"3": "## Phase 3 — A\n- **Blockers**: none\n- **Unblocks**: none\n",
         "4": "## Phase 4 — B\n- **Blockers**: none\n- **Unblocks**: none\n"}
indep_idx = ("## Serial order\n\n"
             "- [phase-4](./phase-4.md) — B\n"
             "- [phase-3](./phase-3.md) — A\n")
want("judgment-free", indep, indep_idx, False)

# The built-in self-check itself must report zero failures (its matcher
# has teeth).
sc = mod._check_73_self_check()
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
    0) t_pass "in-memory matcher: clean/empty PASS; order/membership/missing/ghost/cycle FAIL; judgment-free PASS; built-in self-check has teeth" ;;
    *) t_fail "Check 73 in-memory two-property matcher tests failed (see Python output)" ;;
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
    mod.check_project_index_consistency()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'consistency holds' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
" > /tmp/vp-check73-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check73-live.out; then
    t_pass "Check 73 body runs clean on the live (empty) impl-plan template + self-check has teeth"
else
    t_fail "Check 73 body found a violation on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check73-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

rm -f /tmp/vp-check73-import.out /tmp/vp-check73-live.out

if (( FAIL == 0 )); then
    printf "\n\033[32mAll Check 73 tests passed.\033[0m\n"
    exit 0
fi
printf "\n\033[31mSome Check 73 tests failed.\033[0m\n"
exit 1
