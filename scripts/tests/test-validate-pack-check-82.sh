#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-82.sh — dedicated test for
# BD-255 Part C Check 82 (cross-BD shared-edit-surface advisory; ADVISORY
# backstop).
#
# Check 82 (design §3.3 C-ii): parses every active-state open backlog/BD-*.md
# `File/Symbol` field for its backtick repo-relative path tokens, builds a
# surface→BDs map, and WARNs (advisory, NEVER fail() — the Check-48 precedent;
# two open BDs co-editing a surface is NORMAL, the signal is "coordinate," not
# "forbidden") when ≥2 open BDs name the SAME surface. The design-time
# blast-radius intersection scan is the load-bearing prevention; this is
# defense-in-depth.
#
# This test proves the advisory BITES (a WARN line naming the shared surface +
# the BD pair) and NEVER fails the gate, in a synthetic backlog tree (the real
# tree is never mutated).
#
# Coverage:
#   Group 0: module import + Check 82 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS+WARN — two open BDs sharing a surface ⇒ a WARN line naming
#                           the surface + both BDs, exit 0 (NEVER fail)
#            T2 PASS, no-overlap — distinct surfaces ⇒ no shared-surface WARN,
#                                  exit 0
#            T3 PASS+WARN — three open BDs share a surface ⇒ one WARN naming
#                           all three, exit 0
#            T4 PASS+WARN — two open BDs share a bare single-segment DIRECTORY
#                           surface (`project-template/`) ⇒ a WARN line naming
#                           the dir surface + both BDs, exit 0 (the S1 dir-
#                           collision case that the old regex was blind to)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD + the C2-PROOF
#            (the BD-245↔BD-253 collision on validate-docs.sh WARNs; exit 0)
#
# Usage: bash scripts/tests/test-validate-pack-check-82.sh

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
printf "\n=== Group 0: Module import + Check 82 symbol registration ===\n"

python3 -c "
import sys
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_cross_bd_surface_advisory', '_check_81_iter_open_bds']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check82-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check82-import.out; then
    t_pass "validate-pack.py imports + Check 82 symbol registered"
else
    t_fail "validate-pack.py import or Check 82 symbol registration failed" \
        "$(cat /tmp/vp-check82-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (WARN-on-shared-surface bite; exit 0)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []
BT = chr(96)  # literal backtick

def bd_entry(bd_id, status, file_symbol):
    lines = [
        f"<!-- per-entry source: /backlog/{bd_id}.md -->",
        f"**{bd_id} — {bd_id} synthetic**",
        "Type: feat — synthetic test entry.",
        f"Status: {status}",
        f"File/Symbol: {file_symbol}",
        "Description:",
        "  synthetic body.",
    ]
    return "\n".join(lines) + "\n"

def build_tree(root, entries):
    """entries: list of (bd_id, status, file_symbol)."""
    root = pathlib.Path(root)
    (root / "backlog").mkdir(parents=True, exist_ok=True)
    for bd_id, status, fs in entries:
        (root / "backlog" / f"{bd_id}.md").write_text(
            bd_entry(bd_id, status, fs))

def run(entries):
    tmpdir = tempfile.mkdtemp(prefix="vp-check82-")
    root = pathlib.Path(tmpdir)
    build_tree(root, entries)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cross_bd_surface_advisory()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

SHARED = f"{BT}scripts/shared-thing.py{BT}"
# A bare single-segment DIRECTORY surface (trailing slash, no dot-extension) --
# the S1 collision class the old regex was blind to (it dropped single-segment
# dir tokens, so a dir-only shared surface never entered the surface->BDs map).
SHARED_DIR = f"{BT}project-template/{BT}"

# T1: two open BDs sharing a surface ⇒ a WARN line, exit 0 (NEVER fail).
fc, cap = run([
    ("BD-911", "Open", f"{SHARED}, {BT}scripts/only-911.py{BT}"),
    ("BD-912", "Open", f"{SHARED}, {BT}scripts/only-912.py{BT}"),
])
if fc != 0:
    failures.append(f"T1 expected 0 failures (advisory NEVER fails), got {fc}: {cap}")
elif "WARN" not in cap or "scripts/shared-thing.py" not in cap \
        or "BD-911" not in cap or "BD-912" not in cap:
    failures.append(f"T1 expected a WARN naming the shared surface + both BDs, got: {cap}")

# T2: distinct surfaces ⇒ no shared-surface WARN, exit 0.
fc, cap = run([
    ("BD-913", "Open", f"{BT}scripts/a.py{BT}"),
    ("BD-914", "Open", f"{BT}scripts/b.py{BT}"),
])
if fc != 0:
    failures.append(f"T2 expected 0 failures, got {fc}: {cap}")
elif "shared edit surface" in cap:
    failures.append(f"T2 expected NO shared-surface WARN (distinct surfaces), got: {cap}")

# T3: three open BDs share a surface ⇒ one WARN naming all three, exit 0.
fc, cap = run([
    ("BD-915", "Open", SHARED),
    ("BD-916", "Open", SHARED),
    ("BD-917", "Open", SHARED),
])
if fc != 0:
    failures.append(f"T3 expected 0 failures, got {fc}: {cap}")
elif not ("BD-915" in cap and "BD-916" in cap and "BD-917" in cap
          and "3 open BDs" in cap):
    failures.append(f"T3 expected one WARN naming all three BDs, got: {cap}")

# T4: two open BDs share a bare single-segment DIRECTORY surface
# (project-template/ — see SHARED_DIR) ⇒ a WARN naming the dir surface + both
# BDs, exit 0. This is the S1 dir-collision class the old regex dropped
# (single-segment dir tokens never entered the surface->BDs map, so the
# overlap was invisible).
fc, cap = run([
    ("BD-918", "Open", f"{SHARED_DIR}, {BT}scripts/only-918.py{BT}"),
    ("BD-919", "Open", f"{SHARED_DIR}, {BT}scripts/only-919.py{BT}"),
])
if fc != 0:
    failures.append(f"T4 expected 0 failures (advisory NEVER fails), got {fc}: {cap}")
elif "WARN" not in cap or "project-template/" not in cap \
        or "BD-918" not in cap or "BD-919" not in cap:
    failures.append(f"T4 expected a WARN naming the shared DIRECTORY surface + both BDs, got: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T4 (WARN-on-shared-surface bite naming surface+pair; no-overlap clean; 3-BD overlap; bare single-segment DIRECTORY collision; advisory NEVER fails)" ;;
    *) t_fail "End-to-end check_cross_bd_surface_advisory tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD + C2-PROOF
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD (C2-PROOF) ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 82 > /tmp/vp-check82-e2e.out 2>&1; then
    if grep -q "Check 82: cross-BD shared-edit-surface advisory" /tmp/vp-check82-e2e.out \
       && grep -q "Check 82 — cross-BD surface advisory" /tmp/vp-check82-e2e.out; then
        # C2-PROOF: the BD-245↔BD-253 collision on validate-docs.sh WARNs.
        if grep -q "project-template/scripts/validate-docs.sh" /tmp/vp-check82-e2e.out \
           && grep "project-template/scripts/validate-docs.sh" /tmp/vp-check82-e2e.out | grep -q "BD-245" \
           && grep "project-template/scripts/validate-docs.sh" /tmp/vp-check82-e2e.out | grep -q "BD-253"; then
            t_pass "validate-pack.py exits 0; Check 82 runs + C2-PROOF: BD-245↔BD-253 collision on validate-docs.sh WARNs"
        else
            t_fail "Check 82 ran + exits 0 but the C2-PROOF (BD-245↔BD-253 on validate-docs.sh) WARN not detected" \
                "validate-docs.sh line: $(grep 'project-template/scripts/validate-docs.sh' /tmp/vp-check82-e2e.out)"
        fi
    else
        t_fail "validate-pack.py exits 0 but Check 82 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check82-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD (Check 82 advisory must NEVER fail)" \
        "Tail: $(tail -40 /tmp/vp-check82-e2e.out)"
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
