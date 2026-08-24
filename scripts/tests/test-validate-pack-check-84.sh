#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-84.sh — synthetic fixture tests for
# the BD-189 groupings validation pack-side legs:
#   - Check 84 (project groupings contract schema specifics): the Check-74
#     analog. Asserts the shipped groupings `_rules.md` `## Entry schema`
#     SPECIFICS — entry-type / core-fields / kind-enum (exactly 10 unique
#     lowercase-kebab slugs incl. `unassigned`) / exception-field /
#     member-ref-pattern phase-N / min-members 2 / field-order /
#     reserved-id GRP-000 — PLUS the schema↔lib CROSS-AGREEMENT line (the
#     shipped groupings-lib.sh `RESERVED_ID` constant carries the
#     schema-declared reserved ID; a missing lib file or missing line
#     FAILs — absence-of-backing).
#   - The Check 72 groupings extension legs (same BD, same validator
#     family): the groupings stream tuple + the forbidden `GROUPINGS.md`
#     monolith. Functional bites are staged against a temp copy of the
#     shipped template (stray entry / monolith / missing `_intro.md`).
#
# REGISTERED: Check 84 IS in CHECK_REGISTRY. Group 0 asserts the
# registration landed + the dynamic count-invariant holds (never a
# hardcoded literal) — a registry mismatch FAILS here.
#
# Test infra is self-provisioned (in-memory matcher calls + a mktemp copy
# of the shipped template; no real stream mutated).
#
# Usage: bash scripts/tests/test-validate-pack-check-84.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/vp-check84.XXXXXX")"
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
# Group 0: Module import + Check 84 symbols + registered + count-invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 84 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_groupings_contract', '_check_84_validate',
           '_check_84_self_check', '_check_84_tokens',
           '_CHECK_84_GROUPINGS_RULES', '_CHECK_84_GROUPINGS_LIB',
           '_CHECK_84_LIB_RESERVED_RE']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal (matches check-74).
# A drifted CHECK_REGISTRY_EXPECTED_COUNT (registry mismatch) FAILS here.
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 84 is REGISTERED: 84 must be in the registry.
nums = [t[0] for t in mod._build_check_registry()]
if 84 not in nums:
    print('FAIL_84_NOT_REGISTERED — Check 84 must be in CHECK_REGISTRY')
    sys.exit(1)
print('OK')
" > "$SCRATCH/import.out" 2>&1

if grep -q "^OK$" "$SCRATCH/import.out"; then
    t_pass "imports + Check 84 symbols present + count invariant holds (dynamic) + Check 84 REGISTERED (84 in registry)"
else
    t_fail "Check 84 import / symbol / count / registered-state check failed" \
        "$(cat "$SCRATCH/import.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: in-memory schema-specifics matcher (the BITE teeth)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: in-memory schema-specifics matcher (BITE teeth) ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

good_schema = {
    "entry-type": "grouping",
    "core-fields": "ID Kind Member-phases",
    "kind-enum": ("user-journey ambient-feature foundational-batch "
                  "refactor-cluster release-package shared-feature "
                  "architectural-pattern tech-debt-removal bug-fix "
                  "unassigned"),
    "optional-fields": '"Single-member exception" Doc-links Comment',
    "exception-field": '"Single-member exception"',
    "member-ref-pattern": "phase-N",
    "min-members": "2",
    "field-order": ('Entry-Type Kind Member-phases '
                    '"Single-member exception" Doc-links Comment'),
    "reserved-id": "GRP-000",
}
good_lib = 'x\nRESERVED_ID = "GRP-000"\ny\n'

def want(label, schema, lib_text, expect_fail, needle=None):
    got = mod._check_84_validate(schema, lib_text)
    if bool(got) != expect_fail:
        failures.append("%s: expected %s got %s (%r)"
                        % (label, "FAIL" if expect_fail else "PASS",
                           "FAIL" if got else "PASS", got))
    elif needle is not None and not any(needle in g for g in got):
        failures.append("%s: no failure line carries %r (got %r)"
                        % (label, needle, got))

def mutated(**kv):
    s = dict(good_schema)
    for k, v in kv.items():
        if v is None:
            s.pop(k, None)
        else:
            s[k] = v
    return s

# Conforming schema + agreeing lib → PASS.
want("conforming", good_schema, good_lib, False)
# 9-slug enum (unassigned dropped) → FAIL (count + unassigned).
want("nine-slug-enum", mutated(
    **{"kind-enum": good_schema["kind-enum"].replace(" unassigned", "")}),
    good_lib, True, "exactly 10 slugs")
# Missing reserved-id → FAIL.
want("missing-reserved-id", mutated(**{"reserved-id": None}), good_lib,
     True, "reserved-id must be 'GRP-000'")
# min-members: 3 → FAIL.
want("min-members-3", mutated(**{"min-members": "3"}), good_lib, True,
     "min-members must be '2'")
# Missing field-order → FAIL.
want("missing-field-order", mutated(**{"field-order": None}), good_lib,
     True, "field-order must be declared")
# Duplicate slug (count preserved) → FAIL.
want("dup-slug", mutated(
    **{"kind-enum": good_schema["kind-enum"].replace(
        "unassigned", "bug-fix")}), good_lib, True, "duplicate slugs")
# Non-kebab slug → FAIL.
want("non-kebab-slug", mutated(
    **{"kind-enum": good_schema["kind-enum"].replace(
        "unassigned", "Bad_Slug")}), good_lib, True, "not lowercase-kebab")
# Wrong member-ref-pattern → FAIL.
want("wrong-member-ref", mutated(
    **{"member-ref-pattern": "phase-N.Part-x"}), good_lib, True,
    "member-ref-pattern must be 'phase-N'")
# Wrong entry-type → FAIL.
want("wrong-entry-type", mutated(**{"entry-type": "td"}), good_lib, True,
     "entry-type must be 'grouping'")
# Missing exception-field → FAIL.
want("missing-exception-field", mutated(**{"exception-field": None}),
     good_lib, True, "exception-field must be declared")
# field-order missing the exception field → FAIL.
want("field-order-missing-exception", mutated(
    **{"field-order": "Entry-Type Kind Member-phases Doc-links Comment"}),
    good_lib, True, "field-order must carry")
# CROSS-AGREEMENT: schema GRP-000 vs lib GRP-111 → FAIL.
want("lib-disagreement", good_schema, 'RESERVED_ID = "GRP-111"\n', True,
     "cross-agreement broken")
# CROSS-AGREEMENT: lib line ABSENT (absence-of-backing) → FAIL.
want("lib-line-absent", good_schema, "no constant here\n", True,
     "no lib backing")
# CROSS-AGREEMENT: lib file missing entirely → FAIL.
want("lib-file-missing", good_schema, None, True,
     "no lib to agree with")

# The built-in self-check itself must report zero failures.
sc = mod._check_84_self_check()
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
    0) t_pass "in-memory matcher: conforming PASS; 9-slug/missing-reserved-id/min-members-3/missing-field-order/dup-slug/non-kebab/wrong-ref/wrong-type/missing-exception FAIL; cross-agreement bites (disagreement + absent line + absent lib); built-in self-check has teeth" ;;
    *) t_fail "Check 84 in-memory schema-specifics matcher tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: live-tree in-process body invocation (the shipped contract)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: live-tree in-process body invocation (shipped contract) ===\n"

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
    mod.check_project_groupings_contract()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:200])
    sys.exit(1)
if 'schema specifics hold' not in cap:
    print('FAIL_NO_CLEAN_MSG', cap); sys.exit(1)
print('OK')
" > "$SCRATCH/live.out" 2>&1

if grep -q "^OK$" "$SCRATCH/live.out"; then
    t_pass "Check 84 body runs clean on the shipped groupings contract + lib (cross-agreement live) + self-check has teeth"
else
    t_fail "Check 84 body found a violation on the live tree OR no clean message" \
        "$(tail -20 "$SCRATCH/live.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: Check 72 groupings extension legs (constants + staged bites)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Check 72 groupings legs (tuple + GROUPINGS.md + bites) ===\n"

python3 <<EOF
import shutil, sys, io, contextlib, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
import validate_checks.discipline_parity as dp

failures = []

# Constants: the groupings tuple + the forbidden monolith landed.
if ("groupings", "## Entry schema", ()) not in dp._CHECK_72_STREAMS:
    failures.append("_CHECK_72_STREAMS lacks the groupings tuple")
if "GROUPINGS.md" not in dp._CHECK_72_FORBIDDEN_MONOLITHS:
    failures.append("_CHECK_72_FORBIDDEN_MONOLITHS lacks GROUPINGS.md")

# Functional bites: stage a temp copy of the SHIPPED template, patch
# dp.REPO_ROOT at it, inject one violation per case, run the Check 72
# body in-process, and assert the named failure line.
real = pathlib.Path('$REPO_ROOT') / 'project-template' / 'docs' / 'project'
scratch = pathlib.Path('$SCRATCH')

def run_72(mutate, label, needles):
    td = scratch / ('c72-' + label)
    dest = td / 'project-template' / 'docs' / 'project'
    shutil.copytree(real, dest)
    mutate(dest)
    saved_root = dp.REPO_ROOT
    saved_fails = list(mod.failures)
    mod.failures.clear()
    dp.REPO_ROOT = td
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            mod.check_project_template_empty_shape()
        got = list(mod.failures)
    finally:
        dp.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_fails)
    if needles is None:
        if got:
            failures.append("%s: expected clean, got %r" % (label, got))
    else:
        for needle in needles:
            if not any(needle in g for g in got):
                failures.append("%s: no failure line carries %r (got %r)"
                                % (label, needle, got))

# Clean staged copy of the shipped template → clean.
run_72(lambda d: None, "clean", None)
# Stray GRP-001.md in the (empty) shipped groupings template → FAIL.
run_72(lambda d: (d / 'groupings' / 'GRP-001.md').write_text('x\n'),
       "stray-entry",
       ["groupings/GRP-001.md", "unexpected non-sidecar file"])
# GROUPINGS.md monolith at docs/project → FAIL.
run_72(lambda d: (d / 'GROUPINGS.md').write_text('# mono\n'),
       "monolith", ["GROUPINGS.md", "FORBIDDEN project monolith"])
# Missing groupings/_intro.md → FAIL.
run_72(lambda d: (d / 'groupings' / '_intro.md').unlink(),
       "missing-intro", ["groupings/_intro.md", "required sidecar missing"])
# Gutted groupings schema block → FAIL (well-formedness leg covers the
# new stream).
def gut(d):
    p = d / 'groupings' / '_rules.md'
    p.write_text(p.read_text().replace('## Entry schema', '## Gutted'))
run_72(gut, "gutted-schema",
       ["groupings/_rules.md", "missing or empty schema block"])

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 72 groupings legs: tuple + GROUPINGS.md constants landed; staged bites fire (stray GRP-001.md / GROUPINGS.md monolith / missing _intro.md / gutted schema); clean staged template passes" ;;
    *) t_fail "Check 72 groupings-leg tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll Check 84 (+ Check 72 groupings-leg) tests passed.\033[0m\n"
    exit 0
fi
printf "\n\033[31mSome Check 84 tests failed.\033[0m\n"
exit 1
