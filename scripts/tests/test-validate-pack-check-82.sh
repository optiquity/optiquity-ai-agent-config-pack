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
#            T5 PASS+WARN — one open BD names a placeholder-SEGMENT path
#                           (`project-template/skills/<command>/SKILL.md`) and
#                           another names the literal directory prefix
#                           (`project-template/skills/`) ⇒ a WARN naming the
#                           shared `project-template/skills/` prefix + both BDs,
#                           exit 0 (the BD-257<->BD-037 placeholder blind spot
#                           the placeholder-segment terminator closes)
#   Group 2: end-to-end validate-pack.py exit-status on HEAD, shape-only +
#            live-state-INDEPENDENT: Check 82 runs in the battery, exit 0;
#            IF any shared-surface WARN is present it matches the canonical
#            shape and the OK-summary count agrees. NO specific live BD pair
#            is asserted and NO collision is required to exist (the live
#            open-BD collision set legitimately converges to zero as BDs
#            resolve; the mechanism-bite is proven synthetically in Group 1)
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


def _patch_attr(mod, name, value):
    """Set attribute \`name\` on the facade alias AND every loaded
    validate_checks.* submodule (BD-256 W8 wave-invariant). Check 82's body
    (check_cross_bd_surface_advisory → _check_81_iter_open_bds) reads REPO_ROOT
    from whatever module it lives in (the facade pre-move; cross_bd post-move),
    so a facade-only \`mod.REPO_ROOT = v\` does NOT reach cross_bd's binding —
    set it on every loaded validate_checks.* module that carries it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


def _patch_root(mod, root):
    """REPO_ROOT specialization of _patch_attr (BD-256 W8 wave-invariant).
    \`root\` is a pathlib.Path."""
    _patch_attr(mod, "REPO_ROOT", root)

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
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cross_bd_surface_advisory()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
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

# T5: two open BDs where ONE names a placeholder-SEGMENT path
# (project-template/skills/<command>/SKILL.md) and the OTHER names the literal
# directory prefix (project-template/skills/) ⇒ a WARN on the shared
# project-template/skills/ prefix + both BDs, exit 0. This is the BD-257<->BD-037
# blind spot the placeholder-segment terminator closes: the OLD grammar
# truncated the placeholder span at the angle-bracket marker (which is outside
# the path char-class, so the span never reached its closing backtick) and the whole
# span tokenized to nothing -- the overlap on the literal directory prefix was
# invisible to the collision scan. The NEW terminator (?<=/)(?=<) extracts the
# literal directory prefix up to the placeholder segment, so the placeholder
# path and the literal-dir path now collide on project-template/skills/.
PLACEHOLDER_PATH = f"{BT}project-template/skills/<command>/SKILL.md{BT}"
LITERAL_DIR_PATH = f"{BT}project-template/skills/{BT}"
fc, cap = run([
    ("BD-920", "Open", f"{PLACEHOLDER_PATH}, {BT}scripts/only-920.py{BT}"),
    ("BD-921", "Open", f"{LITERAL_DIR_PATH}, {BT}scripts/only-921.py{BT}"),
])
if fc != 0:
    failures.append(f"T5 expected 0 failures (advisory NEVER fails), got {fc}: {cap}")
elif "WARN" not in cap or "project-template/skills/" not in cap \
        or "BD-920" not in cap or "BD-921" not in cap:
    failures.append(f"T5 expected a WARN naming the shared project-template/skills/ prefix + both BDs (placeholder-segment path must tokenize its literal directory prefix), got: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T5 (WARN-on-shared-surface bite naming surface+pair; no-overlap clean; 3-BD overlap; bare single-segment DIRECTORY collision; placeholder-SEGMENT path collides on its literal directory prefix; advisory NEVER fails)" ;;
    *) t_fail "End-to-end check_cross_bd_surface_advisory tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD (shape-only;
# live-state-INDEPENDENT — asserts NO specific BD pair, requires NO collision)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD (shape-only) ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 82 > /tmp/vp-check82-e2e.out 2>&1; then
    if grep -q "Check 82: cross-BD shared-edit-surface advisory" /tmp/vp-check82-e2e.out \
       && grep -q "Check 82 — cross-BD surface advisory" /tmp/vp-check82-e2e.out; then
        # Shape-only WARN assertions (live-state-INDEPENDENT): the live tree's
        # open-BD collision set legitimately converges to zero as BDs resolve,
        # so this leg asserts NO specific BD pair and requires NO collision to
        # exist. What it DOES assert: (a) IF any shared-surface WARN is
        # present, every such line carries the canonical shape (backticked
        # surface + "is claimed by N open BDs:" + >=2 BD-NNN IDs); (b) the
        # OK-summary WARNed-surface count equals the emitted WARN line count.
        # The mechanism-bite (a WARN naming the surface + the BD set) is
        # proven live-state-independently on the Group 1 synthetic tree
        # (T1/T3/T4) — never against the live backlog.
        WARN_TOTAL=$(grep -c '^WARN: shared edit surface ' /tmp/vp-check82-e2e.out || true)
        WARN_SHAPED=$(grep -Ec '^WARN: shared edit surface `[^`]+` is claimed by [0-9]+ open BDs: BD-[0-9]+(, BD-[0-9]+)+ — coordinate/sequence these ' /tmp/vp-check82-e2e.out || true)
        if [[ "$WARN_TOTAL" -ne "$WARN_SHAPED" ]]; then
            t_fail "Check 82 ran + exits 0 but $((WARN_TOTAL - WARN_SHAPED)) of $WARN_TOTAL shared-surface WARN line(s) deviate from the canonical shape" \
                "Lines: $(grep '^WARN: shared edit surface' /tmp/vp-check82-e2e.out | head -5)"
        elif ! grep -q "cross-BD surface advisory: $WARN_TOTAL shared surface(s) WARNed" /tmp/vp-check82-e2e.out; then
            t_fail "Check 82 OK-summary count disagrees with the $WARN_TOTAL emitted shared-surface WARN line(s)" \
                "Summary: $(grep 'Check 82 — cross-BD surface advisory' /tmp/vp-check82-e2e.out)"
        else
            t_pass "validate-pack.py exits 0; Check 82 runs; $WARN_TOTAL shared-surface WARN line(s), all canonical-shape, OK-summary count consistent (zero collisions is a legitimate pass)"
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
