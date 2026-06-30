#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-81.sh — dedicated test for
# BD-255 Part C Check 81 (structured File/Symbol prereq for active-design
# BDs; TWO-MODE).
#
# Check 81 (design §3.3 C-i; DECISION C2-a — the in-design trigger is the
# committed session-state `active[]` list, NOT a new backlog Status token):
#   - FAIL leg: every open backlog/BD-*.md whose BD-ID is in session-state
#     `active[]` MUST carry a STRUCTURED `File/Symbol` field (≥1 backtick
#     repo-relative path token + no bare/TBD placeholder). A bare/TBD or
#     missing field for an active BD FAILs.
#   - WARN leg (advisory, NEVER fail — the Check-48 warn idiom): every OTHER
#     active-state open BD with a bare/TBD/missing File/Symbol WARNs.
#   - SKIP-lenient: an absent/unparseable session-state.json yields an empty
#     active[] set (no FAIL leg), so the check degrades to WARN-only.
#
# This test proves the guard BITES in a synthetic backlog tree + synthetic
# session-state (the real tree is never mutated): an active BD with a bare-TBD
# field FAILs; a non-active BD with a bare-TBD field WARNs + exit 0; an active
# BD with a structured field PASSes.
#
# Coverage:
#   Group 0: module import + Check 81 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 FAIL — active BD (in active[]) with a bare "TBD" File/Symbol
#            T2 PASS+WARN — a NON-active BD with a bare-TBD File/Symbol WARNs,
#                           no failure (exit 0)
#            T3 PASS — an active BD with a STRUCTURED File/Symbol path list
#            T4 FAIL — active BD with a "candidate surfaces" placeholder that
#                      ALSO names a concrete path (placeholder still FAILs —
#                      the F4 reject-list)
#            T5 PASS — absent session-state.json ⇒ empty active[] ⇒ a bare-TBD
#                      BD only WARNs (SKIP-lenient, no FAIL)
#            T6 FAIL — active BD with NO File/Symbol field at all (missing)
#            T7 PASS — active BD whose File/Symbol is a BARE single-segment
#                      DIRECTORY token (`project-template/`) is recognized as
#                      structured (the trailing-slash dir case) ⇒ no FAIL
#            T8 PASS — a NON-active BD with a bare single-segment directory
#                      token is structured ⇒ NOT WARNed, exit 0
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 81 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-81.sh

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
printf "\n=== Group 0: Module import + Check 81 symbol registration ===\n"

python3 -c "
import sys
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_open_bd_structured_surface_field',
            '_check_81_iter_open_bds',
            '_check_81_field_is_structured',
            '_check_81_active_bd_ids']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check81-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check81-import.out; then
    t_pass "validate-pack.py imports + Check 81 symbol registered"
else
    t_fail "validate-pack.py import or Check 81 symbol registration failed" \
        "$(cat /tmp/vp-check81-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (FAIL-leg bite + WARN-leg + PASS)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, json
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant). check_open_bd_structured_surface_field
    is a DUAL-READ check: it reaches REPO_ROOT via the moved core seam
    (_check_81_active_bd_ids -> _session_state_load reads core.REPO_ROOT) AND
    via _check_81_iter_open_bds (REPO_ROOT / 'backlog'). Setting it on every
    loaded validate_checks.* covers BOTH bindings — a facade-only OR
    single-owning-module patch would miss one."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []
BT = chr(96)  # literal backtick

def bd_entry(bd_id, title, status, file_symbol):
    """A minimal synthetic per-entry BD file body. file_symbol=None omits
    the File/Symbol field entirely."""
    lines = [
        f"<!-- per-entry source: /backlog/{bd_id}.md -->",
        f"**{bd_id} — {title}**",
        "Type: feat — synthetic test entry.",
        f"Status: {status}",
    ]
    if file_symbol is not None:
        lines.append(f"File/Symbol: {file_symbol}")
    lines.append("Description:")
    lines.append("  synthetic body.")
    return "\n".join(lines) + "\n"

def session_state(active_bd_ids):
    return json.dumps({
        "schema": "pack-session-state/1",
        "boundary_commit": "abc1234",
        "checkpoint": "2026-06-29T00:00:00Z",
        "active": [{"bd": b, "sub_step": "x"} for b in active_bd_ids],
        "in_flight_agents": [],
        "queue": [],
        "parallelization": "serial",
        "wave": "w",
        "pending_decisions": [],
        "cycle_position": None,
    })

def build_tree(root, entries, active_ids, write_session=True):
    """entries: list of (bd_id, status, file_symbol)."""
    root = pathlib.Path(root)
    (root / "backlog").mkdir(parents=True, exist_ok=True)
    for bd_id, status, fs in entries:
        (root / "backlog" / f"{bd_id}.md").write_text(
            bd_entry(bd_id, f"{bd_id} synthetic", status, fs))
    if write_session:
        (root / "pack-ops").mkdir(parents=True, exist_ok=True)
        (root / "pack-ops" / "session-state.json").write_text(
            session_state(active_ids))

def run(entries, active_ids, write_session=True):
    tmpdir = tempfile.mkdtemp(prefix="vp-check81-")
    root = pathlib.Path(tmpdir)
    build_tree(root, entries, active_ids, write_session)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_open_bd_structured_surface_field()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

STRUCTURED = f"{BT}scripts/validate-pack.py{BT}, {BT}pack-ops/PACK-AGENTS.md{BT}"
BARE_TBD = "TBD by architect."
CANDIDATE = f"candidate surfaces: {BT}scripts/foo.py{BT}"
# A BARE single-segment DIRECTORY token (trailing slash, no second segment,
# no dot-extension) -- the S1 gap the regex used to drop. This is a genuinely
# structured repo-relative surface, so it must classify as structured.
DIR_ONLY = f"{BT}project-template/{BT}, {BT}backlog/{BT}"

# T1: FAIL — an ACTIVE BD with a bare "TBD" File/Symbol FAILs the FAIL leg.
fc, cap = run([("BD-901", "Open", BARE_TBD)], ["BD-901"])
if fc < 1 or "BD-901" not in cap or "active design" not in cap:
    failures.append(f"T1 (active BD bare-TBD) expected FAIL, got {fc}: {cap}")

# T2: PASS+WARN — a NON-active BD with a bare-TBD field WARNs, no failure.
fc, cap = run([("BD-902", "Open", BARE_TBD)], [])  # active[] empty
if fc != 0 or "WARN" not in cap or "BD-902" not in cap:
    failures.append(f"T2 (non-active bare-TBD WARN) expected 0 fail + WARN, got {fc}: {cap}")

# T3: PASS — an ACTIVE BD with a STRUCTURED File/Symbol path list passes.
fc, cap = run([("BD-903", "Open", STRUCTURED)], ["BD-903"])
if fc != 0:
    failures.append(f"T3 (active structured) expected 0 failures, got {fc}: {cap}")

# T4: FAIL — an ACTIVE BD whose field has a "candidate surfaces" placeholder
# AND a concrete path still FAILs (the placeholder reject-list, F4).
fc, cap = run([("BD-904", "Open", CANDIDATE)], ["BD-904"])
if fc < 1 or "BD-904" not in cap:
    failures.append(f"T4 (active placeholder+path) expected FAIL, got {fc}: {cap}")

# T5: PASS — absent session-state.json ⇒ empty active[] ⇒ SKIP-lenient: a
# bare-TBD BD only WARNs, no FAIL.
fc, cap = run([("BD-905", "Open", BARE_TBD)], [], write_session=False)
if fc != 0 or "WARN" not in cap:
    failures.append(f"T5 (no session-state ⇒ WARN-only) expected 0 fail + WARN, got {fc}: {cap}")

# T6: FAIL — an ACTIVE BD with NO File/Symbol field at all (missing) FAILs.
fc, cap = run([("BD-906", "Open", None)], ["BD-906"])
if fc < 1 or "BD-906" not in cap or "missing" not in cap:
    failures.append(f"T6 (active missing field) expected FAIL naming 'missing', got {fc}: {cap}")

# T7: PASS — an ACTIVE BD whose File/Symbol is a BARE single-segment DIRECTORY
# token (project-template/ — see DIR_ONLY) is recognized as structured (the S1
# trailing-slash dir case) ⇒ no FAIL leg fires. This is the dir-token coverage
# that hid the matcher under-match: a bare single-segment dir used to be
# dropped, which would have false-FAILed an active dir-only BD.
fc, cap = run([("BD-907", "Open", DIR_ONLY)], ["BD-907"])
if fc != 0:
    failures.append(f"T7 (active bare-dir token) expected 0 failures (dir is structured), got {fc}: {cap}")

# T8: PASS — a NON-active BD with a bare single-segment directory token is
# structured ⇒ NOT WARNed (the WARN leg only fires on bare/TBD/missing), exit 0.
fc, cap = run([("BD-908", "Open", DIR_ONLY)], [])  # active[] empty
if fc != 0 or "BD-908" in cap:
    failures.append(f"T8 (non-active bare-dir token) expected 0 fail + NO WARN (structured), got {fc}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T8 (FAIL-leg bite on active bare-TBD/placeholder/missing + WARN-leg on non-active + PASS on active structured incl. bare single-segment DIRECTORY token + SKIP-lenient on absent session-state)" ;;
    *) t_fail "End-to-end check_open_bd_structured_surface_field tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 81 > /tmp/vp-check81-e2e.out 2>&1; then
    if grep -q "Check 81: structured File/Symbol prereq for active-design BDs" /tmp/vp-check81-e2e.out \
       && grep -q "Check 81 — every active-design BD" /tmp/vp-check81-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 81 runs and reports active-design structured-field clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 81 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check81-e2e.out)"
    fi
else
    if grep -q "Check 81: structured File/Symbol prereq for active-design BDs" /tmp/vp-check81-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 81 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check81-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 81 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check81-e2e.out)"
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
