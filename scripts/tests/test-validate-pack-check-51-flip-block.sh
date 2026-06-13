#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-51-flip-block.sh — dedicated
# test for BD-214 Check 51 (tracker-deferral flip-block guard).
#
# This C1 commit ships Check 51 legs 1, 2, and 4 ONLY (legs 3/5 land in
# later commits with their fix-recipes). This test asserts EXACTLY legs
# 1/2/4 — PASS on the well-formed C1 tree, and FAIL when any of the three
# legs' conditions is broken in a synthetic tree.
#
# Legs asserted here:
#   leg 1 — clamp marker present in tracker-config.sh
#   leg 2 — verb gates present (init + enable-recommendations + forward arm)
#   leg 4 — entry-content artifact grep-zero (line-anchored) over the
#           backlog/ + changelog/ per-entry trees
#
# Coverage:
#   Group 0: module import + Check 51 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS — clamp + gates present, entry trees clean
#            T2 FAIL — clamp marker removed (leg 1)
#            T3 FAIL — cmd_init gate removed (leg 2)
#            T4 FAIL — forward-arm gate removed (leg 2)
#            T5 FAIL — a line-anchored entry artifact present (leg 4)
#            T6 PASS — a MID-LINE artifact (prose example) does NOT trip
#                      leg 4 (the `^` anchor excludes it; empty allowlist)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 51 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-51-flip-block.sh

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
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 51 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_tracker_deferral_flip_block']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check51-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check51-import.out; then
    t_pass "validate-pack.py imports + Check 51 symbol registered"
else
    t_fail "validate-pack.py import or Check 51 symbol registration failed" \
        "$(cat /tmp/vp-check51-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests (legs 1/2/4) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

GOOD_CLAMP = (
    "#!/usr/bin/env bash\n"
    "tracker_mode() {\n"
    "    # BD-214 deferral clamp (2026-06-12).\n"
    '    if [[ "\${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then\n'
    '        echo "flat-file"; return 0\n'
    "    fi\n"
    '    echo "flat-file"\n'
    "}\n"
)
GOOD_PACK_TRACKER = (
    "#!/usr/bin/env bash\n"
    "_tracker_deferral_gate() {\n"
    '    if [[ "\${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then\n'
    "        return 1\n"
    "    fi\n"
    "    return 0\n"
    "}\n"
    "cmd_init() {\n"
    "    _tracker_deferral_gate || return 1\n"
    '    echo init\n'
    "}\n"
    "cmd_enable_recommendations() {\n"
    "    _tracker_deferral_gate || return 1\n"
    '    echo enable\n'
    "}\n"
)
GOOD_TRACKER_MIGRATE = (
    "#!/usr/bin/env bash\n"
    "cmd_forward() {\n"
    '    if [[ "\${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then\n'
    "        return 1\n"
    "    fi\n"
    '    echo forward\n'
    "}\n"
    "cmd_reverse() {\n"
    '    echo reverse\n'
    "}\n"
)

def build_tree(root, *, clamp=GOOD_CLAMP, pack_tracker=GOOD_PACK_TRACKER,
               tracker_migrate=GOOD_TRACKER_MIGRATE, backlog_entry=None):
    root = pathlib.Path(root)
    (root / "scripts" / "lib").mkdir(parents=True, exist_ok=True)
    (root / "scripts" / "lib" / "tracker-config.sh").write_text(clamp)
    (root / "scripts" / "pack-tracker.sh").write_text(pack_tracker)
    (root / "scripts" / "tracker-migrate.sh").write_text(tracker_migrate)
    (root / "backlog").mkdir(parents=True, exist_ok=True)
    (root / "changelog").mkdir(parents=True, exist_ok=True)
    (root / "backlog" / "BD-001.md").write_text(
        backlog_entry if backlog_entry is not None
        else "# BD-001\nStatus: Open\nClean entry, no tracker artifacts.\n"
    )

def run(build_kwargs):
    tmpdir = tempfile.mkdtemp(prefix="vp-check51-")
    root = pathlib.Path(tmpdir)
    build_tree(root, **build_kwargs)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_tracker_deferral_flip_block()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

# T1: PASS — clamp + gates present, trees clean.
fc, cap = run(dict())
if fc != 0:
    failures.append(f"T1 (all legs PASS) expected 0 failures, got {fc}: {cap}")

# T2: FAIL — clamp marker removed (leg 1).
fc, cap = run(dict(clamp="#!/usr/bin/env bash\ntracker_mode() { echo flat-file; }\n"))
if fc < 1 or "leg 1" not in cap:
    failures.append(f"T2 (leg 1 FAIL) expected leg-1 failure, got {fc}: {cap}")

# T3: FAIL — cmd_init gate removed (leg 2).
bad_pt = (
    "#!/usr/bin/env bash\n"
    "_tracker_deferral_gate() { return 0; }\n"
    "cmd_init() {\n    echo init\n}\n"
    "cmd_enable_recommendations() {\n    _tracker_deferral_gate || return 1\n    echo enable\n}\n"
)
fc, cap = run(dict(pack_tracker=bad_pt))
if fc < 1 or "leg 2" not in cap or "cmd_init" not in cap:
    failures.append(f"T3 (leg 2 cmd_init FAIL) expected cmd_init leg-2 failure, got {fc}: {cap}")

# T4: FAIL — forward-arm gate removed (leg 2).
bad_tm = (
    "#!/usr/bin/env bash\n"
    "cmd_forward() {\n    echo forward\n}\n"
    "cmd_reverse() {\n    echo reverse\n}\n"
)
fc, cap = run(dict(tracker_migrate=bad_tm))
if fc < 1 or "leg 2" not in cap or "cmd_forward" not in cap:
    failures.append(f"T4 (leg 2 forward FAIL) expected forward leg-2 failure, got {fc}: {cap}")

# T5: FAIL — a LINE-ANCHORED entry artifact present (leg 4).
bad_entry = "# BD-001\n<!-- pack-id: BD-001 -->\nbody\n"
fc, cap = run(dict(backlog_entry=bad_entry))
if fc < 1 or "leg 4" not in cap:
    failures.append(f"T5 (leg 4 FAIL) expected leg-4 failure, got {fc}: {cap}")

# T6: PASS — a MID-LINE artifact (prose example) must NOT trip leg 4.
midline_entry = "# BD-001\nThe marker \`<!-- pack-id: ... -->\` is mid-line prose here.\n"
fc, cap = run(dict(backlog_entry=midline_entry))
if fc != 0:
    failures.append(f"T6 (mid-line artifact must NOT trip leg 4) expected 0 failures, got {fc}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T6 (legs 1/2/4 PASS + injected FAILs + mid-line exclusion)" ;;
    *) t_fail "End-to-end check_tracker_deferral_flip_block tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check51-e2e.out 2>&1; then
    if grep -q "Check 51: BD-214 tracker-deferral flip-block guard (legs 1/2/4)" /tmp/vp-check51-e2e.out \
       && grep -q "Check 51 — BD-214 flip-block guard:" /tmp/vp-check51-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 51 runs and reports legs 1/2/4 clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 51 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check51-e2e.out)"
    fi
else
    if grep -q "Check 51: BD-214 tracker-deferral flip-block guard" /tmp/vp-check51-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 51 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check51-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 51 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check51-e2e.out)"
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
