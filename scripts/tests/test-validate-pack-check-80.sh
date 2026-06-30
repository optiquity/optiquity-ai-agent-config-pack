#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-80.sh — synthetic fixture tests for
# BD-255 Part A Check 80 (the generic doc↔constant twin-bijection +
# completeness leg; DESIGN-RECONCILED.md §3.1 Layer 3).
#
# Check 80 enforces, for each enrolled _DOC_CONSTANT_TWINS row:
#   - "bijection" rows: the doc-region SET equals the constant SET (the
#     Check-45/52 set-equality idiom) — LOCKS the A1 collapse + guards the
#     tracker backend twin.
#   - "recorded" rows: the constant SYMBOL RESOLVES (prose floors; the bespoke
#     check keeps its one-way guard).
# PLUS the Check-59-style COMPLETENESS LEG: len(_DOC_CONSTANT_TWINS) ==
# _DOC_CONSTANT_TWINS_EXPECTED_COUNT AND every registered symbol resolves.
#
# This test exercises Check 80's BODY in-process against the live tree (clean
# PASS) and against monkeypatched module state for the BITES:
#   BITE 1 (bijection): a synthetic doc→constant divergence on a bijection row
#           (a path in the PACK-AGENTS region not in the constant) → FAILS.
#   BITE 2 (completeness): remove a registry row WITHOUT the count bump → the
#           completeness leg FAILS.
#   BITE 3 (symbol-resolve): register a non-resolving symbol → FAILS.
#   BITE 4 (graceful KeyError): delete the A1 SECONDARY constant
#           (_PACK_CHAT_ONLY_PERMITTED_PREFIXES, read by the const-set builder
#           but NOT a directly-named row symbol the completeness leg covers) →
#           the bijection leg FAILS gracefully (a clean fail() naming the
#           missing symbol), NOT a Python traceback (the broadened try/except).
#
# Test infra is self-provisioned: every bite monkeypatches module attributes or
# builds a /tmp tree; no real surface is mutated. State is restored on every
# path.
#
# Coverage:
#   Group 0: Module import + Check 80 symbols + dynamic count-invariant +
#            Check 80 REGISTERED (80 in registry; count == EXPECTED)
#   Group 1: Live-tree in-process body invocation PASSES (the real twins are
#            in bijection / resolve)
#   Group 2: The BITES (bijection / completeness / symbol-resolve /
#            graceful-KeyError)
#
# Usage: bash scripts/tests/test-validate-pack-check-80.sh

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
# Group 0: Module import + symbols + dynamic count-invariant +
#          Check 80 REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 80 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_doc_constant_twin_bijection', '_DOC_CONSTANT_TWINS',
           '_DOC_CONSTANT_TWINS_EXPECTED_COUNT', '_doc_constant_twin_doc_set',
           '_doc_constant_twin_const_set']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 80 not in nums:
    print('FAIL_80_NOT_REGISTERED'); sys.exit(1)
if len(mod._DOC_CONSTANT_TWINS) != mod._DOC_CONSTANT_TWINS_EXPECTED_COUNT:
    print('FAIL_TWIN_COUNT_MISMATCH', len(mod._DOC_CONSTANT_TWINS),
          mod._DOC_CONSTANT_TWINS_EXPECTED_COUNT); sys.exit(1)
print('OK')
" > /tmp/vp-check80-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check80-import.out; then
    t_pass "imports + Check 80 symbols present + count invariants hold (dynamic) + Check 80 REGISTERED (80 in registry)"
else
    t_fail "Check 80 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check80-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Live-tree in-process body invocation PASSES
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Live-tree in-process body invocation ===\n"

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
    mod.check_doc_constant_twin_bijection()
fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
cap = buf.getvalue()
if fails:
    print('FAIL_LIVE')
    for f in fails: print(' ', f[:240])
    sys.exit(1)
if 'bijection row(s) hold set-equality' not in cap:
    print('FAIL_NO_OK_MSG', cap); sys.exit(1)
print('OK')
print(cap.strip())
" > /tmp/vp-check80-live.out 2>&1

if grep -q "^OK$" /tmp/vp-check80-live.out; then
    t_pass "Check 80 body runs clean on the live tree (A1 + tracker bijections hold; recorded residuals resolve; completeness leg passes)"
else
    t_fail "Check 80 body found drift on the live tree OR no clean message" \
        "$(tail -20 /tmp/vp-check80-live.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 2: The three BITES (bijection / completeness / symbol-resolve)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: BITE tests (bijection / completeness / symbol-resolve / graceful-KeyError) ===\n"

python3 <<EOF
import sys, io, contextlib, tempfile, pathlib, shutil
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []


def _patch_attr(mod, name, value):
    """Set attribute \`name\` on the facade alias AND every loaded
    validate_checks.* submodule (BD-256 W8 wave-invariant). Check 80's body +
    its by-name \`module_ns = globals()\` resolution read \`_DOC_CONSTANT_TWINS\` /
    \`_DOC_CONSTANT_TWINS_EXPECTED_COUNT\` / \`_PACK_CHAT_ONLY_PERMITTED_PREFIXES\`
    from whatever module the body lives in (the facade pre-move; cross_bd
    post-move). A facade-only \`mod.X = v\` does NOT reach cross_bd's binding, so
    set the value on every loaded validate_checks.* module that carries it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


def _patch_root(mod, root):
    """REPO_ROOT specialization of _patch_attr (BD-256 W8 wave-invariant).
    \`root\` is a pathlib.Path (Check 80's bijection extractor does
    \`REPO_ROOT / "x"\`)."""
    _patch_attr(mod, "REPO_ROOT", root)


def _del_attr(mod, name):
    """Delete attribute \`name\` from the facade alias AND every loaded
    validate_checks.* submodule that carries it (BD-256 W8). BITE 4 deletes the
    A1 SECONDARY constant (_PACK_CHAT_ONLY_PERMITTED_PREFIXES); Check 80's
    by-name lookup reads it from cross_bd's globals(), so the delete must reach
    cross_bd (not just the facade alias) for the graceful-KeyError leg to fire.
    Returns the list of (module, name, value) it removed so the caller can
    restore on EVERY submodule whose attribute vanished (a plain _patch_attr
    would skip them — its hasattr guard is False after the delete)."""
    removed = []
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                removed.append((_m, name, getattr(_m, name)))
                delattr(_m, name)
    if hasattr(mod, name):
        removed.append((mod, name, getattr(mod, name)))
        delattr(mod, name)
    return removed


def _restore_attr(removed):
    """Restore the (module, name, value) triples _del_attr removed (BD-256 W8)."""
    for _m, _n, _v in removed:
        setattr(_m, _n, _v)


def run_body():
    saved = list(mod.failures); mod.failures.clear()
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        mod.check_doc_constant_twin_bijection()
    fails = list(mod.failures); mod.failures.clear(); mod.failures.extend(saved)
    return fails, buf.getvalue()

# ── BITE 1: bijection-bite — a synthetic doc→constant divergence on the A1
# bijection row. Build a /tmp PACK-AGENTS.md whose GENERATED region carries an
# EXTRA path bullet not in the constant, point the A1 row at it, run the body.
tmpdir = tempfile.mkdtemp(prefix="vp-check80-")
root = pathlib.Path(tmpdir)
(root / "pack-ops").mkdir()
begin = mod._PACK_CHAT_ONLY_DOC_BEGIN
end = mod._PACK_CHAT_ONLY_DOC_END
# Render the real region then inject a bogus extra path bullet (drift).
region = mod.render_pack_chat_only_doc_section()
drifted = region.replace(
    end, "- \`bogus/extra-path.md\` (synthetic drift)\n\n" + end
)
(root / "pack-ops" / "PACK-AGENTS.md").write_text(
    "# synth\n\n" + drifted + "\n"
)
saved_root = mod.REPO_ROOT
saved_twins = mod._DOC_CONSTANT_TWINS
_patch_root(mod, root)
# A single bijection row pointing at the synthetic PACK-AGENTS.md; count-gate
# matched so the bijection leg (not the completeness leg) is the one that bites.
_patch_attr(mod, "_DOC_CONSTANT_TWINS", (
    (
        "A1 pack-chat-only permitted set",
        ("pack-ops/PACK-AGENTS.md",),
        "the GENERATED region",
        "_PACK_CHAT_ONLY_PERMITTED_PATHS",
        "bijection",
    ),
))
saved_expected = mod._DOC_CONSTANT_TWINS_EXPECTED_COUNT
_patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", 1)
try:
    fails, cap = run_body()
finally:
    _patch_root(mod, saved_root)
    _patch_attr(mod, "_DOC_CONSTANT_TWINS", saved_twins)
    _patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", saved_expected)
    shutil.rmtree(tmpdir, ignore_errors=True)
if not fails:
    failures.append("BITE 1 (bijection) expected a FAIL on the synthetic drift, got none: %s" % cap)
elif "bijection broken" not in cap or "bogus/extra-path.md" not in cap:
    failures.append("BITE 1 (bijection) expected the drift FAIL naming the bogus path: %s" % cap)

# ── BITE 2: completeness-bite — remove a row WITHOUT the count bump → the
# completeness leg FAILS.
saved_twins = mod._DOC_CONSTANT_TWINS
_patch_attr(mod, "_DOC_CONSTANT_TWINS", mod._DOC_CONSTANT_TWINS[:-1])  # drop one; count unchanged
try:
    fails, cap = run_body()
finally:
    _patch_attr(mod, "_DOC_CONSTANT_TWINS", saved_twins)
if not fails:
    failures.append("BITE 2 (completeness) expected a FAIL on count mismatch, got none: %s" % cap)
elif "_DOC_CONSTANT_TWINS_EXPECTED_COUNT" not in cap:
    failures.append("BITE 2 (completeness) expected the count-gate FAIL: %s" % cap)

# ── BITE 3: symbol-resolve-bite — register a non-resolving symbol (count
# matched) → the symbol-resolve leg FAILS.
saved_twins = mod._DOC_CONSTANT_TWINS
saved_expected = mod._DOC_CONSTANT_TWINS_EXPECTED_COUNT
_patch_attr(mod, "_DOC_CONSTANT_TWINS", (
    (
        "bogus row",
        ("CLAUDE.md",),
        "nowhere",
        "_THIS_SYMBOL_DOES_NOT_EXIST_XYZZY",
        "recorded",
    ),
))
_patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", 1)
try:
    fails, cap = run_body()
finally:
    _patch_attr(mod, "_DOC_CONSTANT_TWINS", saved_twins)
    _patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", saved_expected)
if not fails:
    failures.append("BITE 3 (symbol-resolve) expected a FAIL on the bogus symbol, got none: %s" % cap)
elif "_THIS_SYMBOL_DOES_NOT_EXIST_XYZZY" not in cap or "do NOT resolve" not in cap:
    failures.append("BITE 3 (symbol-resolve) expected the symbol-resolve FAIL naming the bogus symbol: %s" % cap)

# ── BITE 4: graceful-KeyError-bite — delete the A1 SECONDARY constant
# (_PACK_CHAT_ONLY_PERMITTED_PREFIXES). The const-set builder reads it directly
# for the A1 union, but it is NOT a directly-named row symbol, so the
# completeness leg does NOT cover it. With the broadened try/except the
# bijection leg must FAIL GRACEFULLY (a clean fail() naming the missing symbol),
# NEVER an uncaught traceback. Run the live A1 row count-gated to 1 so the
# bijection leg (not the completeness leg) is the one that hits the lookup.
saved_twins = mod._DOC_CONSTANT_TWINS
saved_expected = mod._DOC_CONSTANT_TWINS_EXPECTED_COUNT
# Keep ONLY the real A1 bijection row (live tree → bijection leg runs, reads
# the secondary constant from globals()).
a1_row = next(
    r for r in mod._DOC_CONSTANT_TWINS
    if r[3] == "_PACK_CHAT_ONLY_PERMITTED_PATHS" and r[4] == "bijection"
)
_patch_attr(mod, "_DOC_CONSTANT_TWINS", (a1_row,))
_patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", 1)
# Delete the secondary constant from the facade alias AND cross_bd (where Check
# 80's by-name lookup reads it from globals()) — a facade-only del would leave
# cross_bd.globals() intact, so the graceful-KeyError leg would not fire (W8:
# the const lives in core, re-exported into cross_bd; both copies must vanish).
removed_prefixes = _del_attr(mod, "_PACK_CHAT_ONLY_PERMITTED_PREFIXES")
crashed = False
try:
    fails, cap = run_body()
except Exception as exc:  # any uncaught exception == the guard CRASHED
    crashed = True
    cap = "UNCAUGHT %s: %s" % (type(exc).__name__, exc)
    fails = []
finally:
    _patch_attr(mod, "_DOC_CONSTANT_TWINS", saved_twins)
    _patch_attr(mod, "_DOC_CONSTANT_TWINS_EXPECTED_COUNT", saved_expected)
    _restore_attr(removed_prefixes)
if crashed:
    failures.append("BITE 4 (graceful KeyError) the guard CRASHED instead of failing gracefully: %s" % cap)
elif not fails:
    failures.append("BITE 4 (graceful KeyError) expected a graceful FAIL on the missing secondary constant, got none: %s" % cap)
elif "_PACK_CHAT_ONLY_PERMITTED_PREFIXES" not in cap:
    failures.append("BITE 4 (graceful KeyError) expected the graceful FAIL to name the missing constant: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "BITE tests B1-B4 (bijection drift / completeness count-gate / symbol-resolve / graceful-KeyError) all bite" ;;
    *) t_fail "Check 80 BITE tests failed (see Python output)" ;;
esac

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
