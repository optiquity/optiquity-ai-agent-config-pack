#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-97.sh — synthetic tests for Check 97
# (install-map axis symmetry: every row carries BOTH `cmd_update` and
# `migrate`).
#
# The `--update` path dispatches the install map's `cmd_update` axis and the
# vN→vN+1 migrator dispatches its `migrate` axis; a row on one axis only is a
# declared install that one path silently never delivers or never refreshes
# (the agent launcher shipped stale through every migration this way). Check 97
# asserts every explicit + family row carries both tokens, FAILs on zero rows
# (never vacuous), and has NO allowlist.
#
# invocation-vs-mention (declare-verify-backing): the guard BITES a row missing
# `migrate`, a row missing `cmd_update`, and a map that yields no rows; it
# SPARES a map whose every row carries both, and the real tree at HEAD.
#
# This test is NOT fixture-dependent (it writes a synthetic scripts/init-project.sh
# into a /tmp REPO_ROOT and monkeypatches the module's REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob. Per "Test infra
# is self-provisioned": the REAL scripts/init-project.sh is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 97 symbol registration + DYNAMIC count invariant
#   Group 1: Real-state-at-HEAD PASS (every real row carries both tokens)
#   Group 2: Synthetic PASS/BITE against a /tmp REPO_ROOT:
#            - T1 PASS : explicit + family rows all carry both tokens → 0 failures
#            - T2 BITE : an explicit row lacks `migrate` → ≥1 failure naming it
#            - T3 BITE : a family row lacks `cmd_update` → ≥1 failure naming it
#            - T4 BITE : markers present but ZERO parseable rows → ≥1 failure
#            - T5 BITE : a row on NEITHER axis → failure says NEITHER
#            - T6 SPARE: the T2 row with the token added back → 0 failures
#            - T7 BITE : one SOURCE on two explicit rows, the one-axis row
#                        FIRST → failure naming that row's destination (a
#                        source-keyed dict keeps only the last row and passes)
#            - T8 SPARE: one SOURCE on two explicit rows, both both-axis →
#                        0 failures and BOTH rows counted
#   Group 3: End-to-end validate-pack.py --only-check 97 on HEAD (rc 0)
#
# Usage: bash scripts/tests/test-validate-pack-check-97.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
export REPO_ROOT VALIDATE

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/vp-check97.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 97 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 97 symbol registration ===\n"

python3 - > "$SCRATCH/import.out" 2>&1 <<'PY'
import os, sys
REPO_ROOT = os.environ['REPO_ROOT']; VALIDATE = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
for name in ('check_install_map_axis_symmetry', '_CHECK_97_AXES',
             '_parse_client_installed_file_rows', '_parse_client_installed_globs'):
    if not hasattr(mod, name):
        print('FAIL_MISSING ' + name); sys.exit(1)
if tuple(mod._CHECK_97_AXES) != ('cmd_update', 'migrate'):
    print('FAIL_AXES ' + repr(mod._CHECK_97_AXES)); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 97 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
# DYNAMIC count invariant (Check 59's): the registry add + the count bump
# landed together. No hardcoded literal here.
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
PY
if grep -q "^OK$" "$SCRATCH/import.out"; then
    t_pass "validate-pack.py imports + Check 97 registered + DYNAMIC count invariant holds"
else
    t_fail "validate-pack.py import / Check 97 registration / count invariant failed" \
        "$(cat "$SCRATCH/import.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

python3 - > "$SCRATCH/real.out" 2>&1 <<'PY'
import os, sys, io, contextlib
REPO_ROOT = os.environ['REPO_ROOT']; VALIDATE = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.failures.clear()
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    mod.check_install_map_axis_symmetry()
n = len(mod.failures)
print('FAILURES', n)
print(buf.getvalue())
PY
if grep -q "^FAILURES 0$" "$SCRATCH/real.out" && grep -q "no one-axis row" "$SCRATCH/real.out"; then
    t_pass "real tree at HEAD: every install-map row carries both cmd_update and migrate"
else
    t_fail "real tree at HEAD: Check 97 reported failures or an unexpected message" \
        "$(cat "$SCRATCH/real.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic PASS / BITE against a /tmp REPO_ROOT
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic PASS/BITE (monkeypatched REPO_ROOT) ===\n"

SCRATCH="$SCRATCH" python3 - > "$SCRATCH/synth.out" 2>&1 <<'PY'
import os, sys, io, contextlib
from pathlib import Path
REPO_ROOT = os.environ['REPO_ROOT']; VALIDATE = os.environ['VALIDATE']
SCRATCH = Path(os.environ['SCRATCH'])
sys.path.insert(0, REPO_ROOT + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
br = sys.modules['validate_checks.boundary_refs']

GOOD_EXPLICIT = "#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update,migrate]  [class:generic]\n"
GOOD_FAMILY   = "#   project-template/skills/*/SKILL.md  ->  .{claude,codex,agents}/skills/*/SKILL.md  [stage:S4,cmd_update,migrate]  [class:generic]\n"

def make_root(name, explicit_rows, family_rows):
    root = SCRATCH / name
    (root / "scripts").mkdir(parents=True, exist_ok=True)
    body = ("#!/usr/bin/env bash\n"
            "# _CLIENT_INSTALLED_FILES_START\n" + explicit_rows +
            "# _CLIENT_INSTALLED_FILES_END\n#\n"
            "# _CLIENT_INSTALLED_GLOBS_START\n" + family_rows +
            "# _CLIENT_INSTALLED_GLOBS_END\nmain() { :; }\n")
    (root / "scripts" / "init-project.sh").write_text(body)
    return root

def run(root):
    saved = br.REPO_ROOT
    br.REPO_ROOT = root
    mod.failures.clear()
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_install_map_axis_symmetry()
    finally:
        br.REPO_ROOT = saved
    return len(mod.failures), " ".join(mod.failures) + " " + buf.getvalue()

failures = []

# T1 PASS: both tokens on every row.
n, cap = run(make_root("t1", GOOD_EXPLICIT, GOOD_FAMILY))
if n != 0 or "1 explicit + 1 family" not in cap:
    failures.append(f"T1 (all rows carry both) expected 0 failures + count message, got {n}: {cap}")

# T2 BITE: explicit row lacks migrate (the launcher defect shape).
bad = "#   project-template/agent-run.sh  ->  agent-run.sh  [stage:S5,cmd_update]  [class:pack-script]\n"
n, cap = run(make_root("t2", GOOD_EXPLICIT + bad, GOOD_FAMILY))
if n < 1 or "project-template/agent-run.sh" not in cap or "lacks `migrate`" not in cap or "cmd_update axis only" not in cap:
    failures.append(f"T2 (explicit row lacks migrate) expected FAIL naming the row + missing token, got {n}: {cap}")

# T3 BITE: family row lacks cmd_update.
badfam = "#   project-template/bundle/*  ->  bundle/*  [stage:S2,migrate]  [class:self]\n"
n, cap = run(make_root("t3", GOOD_EXPLICIT, GOOD_FAMILY + badfam))
if n < 1 or "project-template/bundle/*" not in cap or "lacks `cmd_update`" not in cap or "family" not in cap:
    failures.append(f"T3 (family row lacks cmd_update) expected FAIL naming the family row, got {n}: {cap}")

# T4 BITE: markers present, zero parseable rows (absence-of-backing).
n, cap = run(make_root("t4", "#   (no rows here)\n", "#   (none)\n"))
if n < 1 or "ZERO rows" not in cap:
    failures.append(f"T4 (zero rows) expected FAIL, got {n}: {cap}")

# T5 BITE: a row on NEITHER axis.
neither = "#   project-template/x.md  ->  x.md  [stage:S6]  [class:generic]\n"
n, cap = run(make_root("t5", GOOD_EXPLICIT + neither, GOOD_FAMILY))
if n < 1 or "NEITHER axis" not in cap or "project-template/x.md" not in cap:
    failures.append(f"T5 (neither axis) expected FAIL saying NEITHER, got {n}: {cap}")

# T6 SPARE: the T2 shape with the token added back passes (the fix shape).
fixed = "#   project-template/agent-run.sh  ->  agent-run.sh  [stage:S5,cmd_update,migrate]  [class:pack-script]\n"
n, cap = run(make_root("t6", GOOD_EXPLICIT + fixed, GOOD_FAMILY))
if n != 0 or "2 explicit + 1 family" not in cap:
    failures.append(f"T6 (launcher row fixed) expected 0 failures, got {n}: {cap}")

# T7 BITE: one SOURCE declared to two destinations, the one-axis row FIRST.
# A source-keyed dict keeps only the LAST row and would pass this map; the
# check must judge every row, and name the offending row by its destination.
dup_first = ("#   project-template/.mcp.json.example  ->  .mcp.json  [stage:S3,cmd_update]  [class:claude-mcp-example]\n"
             "#   project-template/.mcp.json.example  ->  .mcp.json.example  [stage:S3,cmd_update,migrate]  [class:claude-mcp-example]\n")
n, cap = run(make_root("t7", dup_first, GOOD_FAMILY))
if n != 1 or "project-template/.mcp.json.example -> .mcp.json —" not in cap or "lacks `migrate`" not in cap:
    failures.append(f"T7 (duplicate source, one-axis row first) expected exactly 1 failure naming `-> .mcp.json`, got {n}: {cap}")

# T8 SPARE: the same duplicate source with BOTH rows on both axes passes, and
# both rows are counted (2 explicit), not collapsed to one.
dup_ok = ("#   project-template/.mcp.json.example  ->  .mcp.json  [stage:S3,cmd_update,migrate]  [class:claude-mcp-example]\n"
          "#   project-template/.mcp.json.example  ->  .mcp.json.example  [stage:S3,cmd_update,migrate]  [class:claude-mcp-example]\n")
n, cap = run(make_root("t8", dup_ok, GOOD_FAMILY))
if n != 0 or "2 explicit + 1 family" not in cap:
    failures.append(f"T8 (duplicate source, both rows both-axis) expected 0 failures + '2 explicit', got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
PY
if grep -q "^OK$" "$SCRATCH/synth.out"; then
    t_pass "synthetic T1 PASS / T2-T5 + T7 BITE / T6 + T8 SPARE all behaved"
else
    t_fail "synthetic PASS/BITE cases failed" "$(cat "$SCRATCH/synth.out")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end --only-check 97 on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: validate-pack.py --only-check 97 on HEAD ===\n"

if (cd "$REPO_ROOT" && python3 "$VALIDATE" --only-check 97 > "$SCRATCH/e2e.out" 2>&1); then
    t_pass "validate-pack.py --only-check 97 exits 0 on HEAD"
else
    t_fail "validate-pack.py --only-check 97 exited non-zero on HEAD" "$(tail -20 "$SCRATCH/e2e.out")"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Results: %d passed, %d failed ===\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
