#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-47.sh — per-check tests for Check 47
# (sanctioned pack-side-shipped freeze — EMPTY invariant).
#
# Focus: the ship-source set Check 47 tests is the UNION of BOTH install-map
# blocks. Checking only the explicit block would leave a FAMILY row free to
# ship pack-side files — one row, a whole directory, no diagnostic.
#
# Every leg that guards a contract is paired with the mutation that must
# break it; a leg passing on both the good and the bad input is not a guard.
#
# Usage: bash scripts/tests/test-validate-pack-check-47.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | head -8 | sed 's/^/       /'
    return 0
}

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 47 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_sanctioned_pack_side_shipped',
    '_SANCTIONED_PACK_SIDE_SHIPPED',
    '_parse_client_installed_files',
    '_parse_client_installed_globs',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check47-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check47-import.out; then
    t_pass "validate-pack.py imports + Check 47 symbols registered"
else
    t_fail "Check 47 symbol registration failed" "$(cat /tmp/vp-check47-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: union-set fixtures + the pack-side-glob-source bite ===\n"

python3 <<EOF
import sys, io, contextlib, tempfile, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Patch REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule — the check body reads boundary_refs.REPO_ROOT, so a
    facade-only patch would NOT bite."""
    mod.REPO_ROOT = root
    for _n, _m in list(sys.modules.items()):
        if _n == "validate_checks" or _n.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []


def run_check(explicit_rows, glob_rows, extant_paths=()):
    """Run Check 47 against a synthetic root carrying the given map.

    The synthetic root has no migrate-v10-to-v11.sh, so install path 2 is
    lenient-skipped and every failure counted here is the install-map leg's.
    """
    root = pathlib.Path(tempfile.mkdtemp(prefix="vp-check47-"))
    (root / "scripts").mkdir()
    for ep in extant_paths:
        t = root / ep
        t.parent.mkdir(parents=True, exist_ok=True)
        t.write_text("# stub\n")
    lines = ["#!/usr/bin/env bash", "# _CLIENT_INSTALLED_FILES_START"]
    lines += ["#   " + r for r in explicit_rows]
    lines += ["# _CLIENT_INSTALLED_FILES_END", "#",
              "# _CLIENT_INSTALLED_GLOBS_START"]
    lines += ["#   " + r for r in glob_rows]
    lines.append("# _CLIENT_INSTALLED_GLOBS_END")
    (root / "scripts" / "init-project.sh").write_text("\n".join(lines) + "\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_sanctioned_pack_side_shipped()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return n, cap


PT_ROW = "project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S7,cmd_update,migrate]  [class:trinity]"
SD_ROW = "supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6,cmd_update,migrate]  [class:generic]"
CLEAN_GLOB = "project-template/scripts/*  ->  scripts/*  [stage:S5,cmd_update,migrate]  [class:pack-script]"
PACKSIDE_GLOB = "scripts/lib/*.sh  ->  scripts/lib/*.sh  [stage:S5,cmd_update,migrate]  [class:pack-script]"
PACKSIDE_ROW = "scripts/pack-help.sh  ->  scripts/pack-help.sh  [stage:S5,cmd_update,migrate]  [class:pack-script]"

# T1: PASS — every source in BOTH blocks is under an admitted prefix
#     (project-template/ or supporting-docs/), so the pack-side subset is
#     empty and equals the frozen empty constant.
n, cap = run_check([PT_ROW, SD_ROW], [CLEAN_GLOB])
if n != 0:
    failures.append(f"T1 (clean union) expected 0 failures, got {n}: {cap}")
if "0 entr(ies)" not in cap:
    failures.append(f"T1 must report the empty frozen set: {cap}")

# T2: BITE — a pack-side source declared as a FAMILY row. Before the union
#     the glob block was invisible here, so this row shipped scripts/lib/
#     to every client with no diagnostic at all.
n, cap = run_check([PT_ROW, SD_ROW], [CLEAN_GLOB, PACKSIDE_GLOB])
if n < 1:
    failures.append(
        f"T2 (pack-side GLOB source) expected >=1 failure — the union is not "
        f"load-bearing: {cap}")
if "scripts/lib/*.sh" not in cap:
    failures.append(f"T2 FAIL must name the offending family pattern: {cap}")
if "NOT in _SANCTIONED_PACK_SIDE_SHIPPED" not in cap:
    failures.append(f"T2 FAIL must carry the unsanctioned-entry message: {cap}")
# Naming the pattern is not enough: a maintainer follows the message to a
# block. A GLOB-block offender must send them to the GLOB block, and must
# NOT send them to the explicit block, where the row does not exist.
if "GLOB block" not in cap:
    failures.append(f"T2 FAIL must name the GLOB block as the offender's home: {cap}")
if "EXPLICIT block" in cap:
    failures.append(
        f"T2 FAIL must NOT name the EXPLICIT block — no explicit row offends: {cap}")

# T3: discrimination — the SAME map minus that one family row PASSES. T2 and
#     T3 differ by exactly one row, so T2's failure is attributable to it.
n, cap = run_check([PT_ROW, SD_ROW], [CLEAN_GLOB])
if n != 0:
    failures.append(f"T3 (row removed) expected 0 failures, got {n}: {cap}")

# T4: the explicit-block leg still bites (no regression from the union).
n, cap = run_check([PT_ROW, PACKSIDE_ROW], [CLEAN_GLOB])
if n < 1:
    failures.append(f"T4 (pack-side EXPLICIT source) expected >=1 failure: {cap}")
if "scripts/pack-help.sh" not in cap:
    failures.append(f"T4 FAIL must name the offending explicit source: {cap}")
# Opposite polarity to T2: T2 and T4 together prove the block name TRACKS the
# offender's origin rather than being a constant string.
if "EXPLICIT block" not in cap:
    failures.append(f"T4 FAIL must name the EXPLICIT block: {cap}")
if "GLOB block" in cap:
    failures.append(
        f"T4 FAIL must NOT name the GLOB block — no family row offends: {cap}")

# T4b: BOTH blocks offend at once — each offender is reported under its OWN
#      block, so the partition is not a first-match-wins shortcut.
n, cap = run_check([PT_ROW, PACKSIDE_ROW], [CLEAN_GLOB, PACKSIDE_GLOB])
if n < 1:
    failures.append(f"T4b (both blocks offend) expected >=1 failure: {cap}")
if "EXPLICIT block" not in cap or "GLOB block" not in cap:
    failures.append(f"T4b FAIL must name BOTH blocks: {cap}")
if "scripts/pack-help.sh" not in cap or "scripts/lib/*.sh" not in cap:
    failures.append(f"T4b FAIL must name BOTH offenders: {cap}")

# T5: both admitted prefixes are honoured on the GLOB side too — a family
#     row sourced from supporting-docs/ is a client deliverable, not a
#     pack-side ship.
n, cap = run_check([PT_ROW], ["supporting-docs/*.md  ->  docs/pack/*.md  [stage:S6,cmd_update,migrate]  [class:generic]"])
if n != 0:
    failures.append(f"T5 (supporting-docs family source) expected 0 failures, got {n}: {cap}")

# T6: the frozen constant is EMPTY and the check hard-fails a non-empty one
#     regardless of map state (the empty floor is a machine invariant).
if tuple(mod._SANCTIONED_PACK_SIDE_SHIPPED) != ():
    failures.append(
        f"T6 _SANCTIONED_PACK_SIDE_SHIPPED must be EMPTY: "
        f"{sorted(mod._SANCTIONED_PACK_SIDE_SHIPPED)}")

saved_const = mod._SANCTIONED_PACK_SIDE_SHIPPED
for _n, _m in list(sys.modules.items()):
    if _n == "validate_checks" or _n.startswith("validate_checks."):
        if hasattr(_m, "_SANCTIONED_PACK_SIDE_SHIPPED"):
            _m._SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/lib/detect.sh",)
mod._SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/lib/detect.sh",)
try:
    n, cap = run_check([PT_ROW], [CLEAN_GLOB])
finally:
    for _n, _m in list(sys.modules.items()):
        if _n == "validate_checks" or _n.startswith("validate_checks."):
            if hasattr(_m, "_SANCTIONED_PACK_SIDE_SHIPPED"):
                _m._SANCTIONED_PACK_SIDE_SHIPPED = saved_const
    mod._SANCTIONED_PACK_SIDE_SHIPPED = saved_const
if n < 1:
    failures.append(f"T6b a non-empty frozen constant must hard-FAIL: {cap}")
if "must be EMPTY" not in cap:
    failures.append(f"T6b FAIL must carry the empty-invariant message: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "union-set fixtures T1-T6b (clean union / pack-side-glob bite + discrimination / explicit leg / prefix handling / empty-invariant)" ;;
    *) t_fail "Check 47 union-set tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: live-tree non-regression ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 47 > /tmp/vp-check47-e2e.out 2>&1; then
    if grep -q "install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED (0 entr(ies)): \[\]" /tmp/vp-check47-e2e.out; then
        t_pass "live tree: pack-side subset of BOTH map blocks is empty (0 entr(ies): [])"
    else
        t_fail "live tree: expected the empty set-equality line" \
            "$(tail -10 /tmp/vp-check47-e2e.out)"
    fi
else
    t_fail "validate-pack.py --only-check 47 exits non-zero" \
        "$(tail -20 /tmp/vp-check47-e2e.out)"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n  FAIL: %d\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
