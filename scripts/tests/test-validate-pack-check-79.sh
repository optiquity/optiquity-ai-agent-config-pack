#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-79.sh — synthetic fixture tests for
# BD-252 Check 79 (session-state snapshot no-history grammar;
# DESIGN-RECONCILED.md §4 + PLAN.md §2 C2; the bespoke anti-accretion check).
#
# Check 79 PERMITS the snapshot's legitimate STATE (bare BD-\d+ tags, exactly 1
# date only in `checkpoint`, exactly 1 SHA only in `boundary_commit`) and
# FORBIDS ACCRETION (a 2nd date, a 2nd SHA, an off-field SHA, the narration set,
# size over the byte cap). measure-then-bound (ci-guard-measure-then-bound):
# this test proves BOTH legs —
#   (a) PASS on a clean idle snapshot (the seed shape), AND
#   (b) FAIL on an accretion fixture mirroring the real stale CLI-memory
#       carry-over (stacked SHAs + multiple dates + a LESSONS line + carry note)
# — so the check is proven to catch the real failure while permitting legit
# BD-tag content.
# SKIP-lenient when the snapshot is ABSENT or unparseable (Check 77 owns parse).
#
# Test infra is self-provisioned; no real shipped file is mutated. Cleanup runs
# on every exit.
#
# Coverage:
#   Group 0: Module import + Check 79 symbols + dynamic count-invariant +
#            Check 79 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1  clean idle snapshot PASSES (1 date, 1 SHA, N bare BD-tags, no
#                narration, under cap)
#            T2  ACCRETION carry-over fixture FAILS (the decisive proof:
#                stacked SHAs + multiple dates + LESSONS + carry note) — and
#                fails on MULTIPLE independent grounds
#            T3  a 2nd date alone FAILS
#            T4  a 2nd / off-field SHA alone FAILS
#            T5  a narration line (carried-from) alone FAILS
#            T6  size over the byte cap FAILS (anti-growth BACKSTOP)
#            T7  bare BD-tags are PERMITTED (a queue of many BD-tags PASSES)
#            T8  ABSENT snapshot → lenient SKIP
#            T9  per-bd narration bites the ORIGINAL value (dead-pattern
#                regression: "per BD-42" FAILS; a bare "BD-42" still PASSES)
#
# Usage: bash scripts/tests/test-validate-pack-check-79.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

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
# Group 0: Module import + symbols + dynamic count-invariant + REGISTERED
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 79 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_session_state_grammar', '_SESSION_STATE_FILE',
           '_SESSION_STATE_NARRATION_PATTERNS', '_SESSION_STATE_BYTE_CAP',
           '_SESSION_STATE_BD_TAG_RE', '_session_state_iter_string_values']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# the byte cap is a positive int (the anti-growth backstop).
if not isinstance(mod._SESSION_STATE_BYTE_CAP, int) or mod._SESSION_STATE_BYTE_CAP < 1:
    print('FAIL_CAP', mod._SESSION_STATE_BYTE_CAP); sys.exit(1)
# the narration set is non-empty and includes the carry-over's vectors.
names = [n for n, _ in mod._SESSION_STATE_NARRATION_PATTERNS]
for need in ('lessons-marker', 'carry-over', 'bd-past-action'):
    if need not in names:
        print('FAIL_NARRATION_MISSING', need, names); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
nums = [t[0] for t in mod._build_check_registry()]
if 79 not in nums:
    print('FAIL_79_NOT_REGISTERED'); sys.exit(1)
print('OK')
" > /tmp/vp-check79-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check79-import.out; then
    t_pass "imports + Check 79 symbols present + byte cap positive + narration set covers lessons/carry-over/bd-past-action + count invariant holds (dynamic) + Check 79 REGISTERED"
else
    t_fail "Check 79 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check79-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Synthetic-tree end-to-end (in-process body invocation)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Synthetic-tree end-to-end (in-process body) ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, json
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant). check_session_state_grammar reaches
    REPO_ROOT via the moved core seam (_session_state_load reads
    core.REPO_ROOT), so a facade-only patch would NOT bite. Setting it on every
    loaded validate_checks.* reaches the read wherever it resolves."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []
SNAP_REL = "pack-ops/session-state.json"

def clean_snapshot():
    """A clean idle snapshot (the seed shape): 1 date in checkpoint, 1 SHA in
       boundary_commit, many bare BD-tags in queue (PERMITTED), no narration."""
    return {
        "schema": "pack-session-state/1",
        "boundary_commit": "2e899db",
        "checkpoint": "2026-06-29T00:00:00Z",
        "active": [],
        "in_flight_agents": [],
        "queue": ["BD-252", "BD-219", "BD-222", "BD-245", "BD-224",
                  "BD-210", "BD-205", "BD-093"],
        "parallelization": "serial",
        "wave": None,
        "pending_decisions": [],
        "cycle_position": None,
    }

def build_tree(*, data=None, raw=None, include=True):
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check79-"))
    if include:
        p = tmpdir / SNAP_REL
        p.parent.mkdir(parents=True, exist_ok=True)
        if raw is not None:
            p.write_bytes(raw)
        else:
            if data is None:
                data = clean_snapshot()
            p.write_text(json.dumps(data, indent=2) + "\n")
    return tmpdir

def run_in_tree(tmpdir):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, tmpdir)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_session_state_grammar()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — clean idle snapshot (1 date, 1 SHA, N bare BD-tags, no narration).
fc, cap = run_in_tree(build_tree())
if fc != 0:
    failures.append("T1 (clean PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "no-history grammar OK" not in cap:
    failures.append("T1 (clean PASS) expected the clean grammar message: %s" % cap)

# T2: FAIL — the ACCRETION carry-over fixture (the decisive proof). Mirrors the
#     real stale CLI-memory carry-over: stacked commit SHAs, multiple dated
#     notes, a LESSONS block, a carry note. Stuffed into snapshot string values
#     (e.g. a notes blob + extra dated keys) — exactly the append-stacking
#     the snapshot must STRUCTURALLY refuse.
accretion = clean_snapshot()
accretion["notes"] = (
    "CARRY-OVER (2026-06-28): BD-246 landed RED at b6c5ecc; "
    "fixed 68842a6; then 143ee7d. LESSONS (keep): carried from the prior "
    "session — stage-then-validate. UPDATE-2 2026-06-27: queue reorder."
)
fc, cap = run_in_tree(build_tree(data=accretion))
if fc < 1:
    failures.append("T2 (ACCRETION carry-over FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
# decisive: it must fail on MULTIPLE independent grounds (date + SHA + narration).
grounds = 0
if "date(s)" in cap or "OUTSIDE" in cap:
    grounds += 1
if "SHA(s)" in cap or "appears OUTSIDE" in cap:
    grounds += 1
if "history/narration pattern" in cap:
    grounds += 1
if grounds < 2:
    failures.append("T2 (ACCRETION FAIL) expected >=2 independent FAIL grounds (date/SHA/narration), got %d: %s" % (grounds, cap))
if "ACCRETION" not in cap:
    failures.append("T2 (ACCRETION FAIL) expected the ACCRETION label: %s" % cap)

# T3: FAIL — a 2nd date alone (in a non-checkpoint value).
d = clean_snapshot(); d["active"] = ["BD-219 paused 2026-06-30"]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T3 (2nd-date FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "date" not in cap:
    failures.append("T3 (2nd-date FAIL) expected a date-accretion message: %s" % cap)

# T4: FAIL — an off-field SHA alone (a SHA outside boundary_commit).
d = clean_snapshot(); d["active"] = ["BD-219 at commit deadbeef1"]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T4 (off-field-SHA FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "SHA" not in cap:
    failures.append("T4 (off-field-SHA FAIL) expected a SHA-accretion message: %s" % cap)

# T5: FAIL — a narration line alone (carried-from), no extra date/SHA.
d = clean_snapshot(); d["pending_decisions"] = ["carried from the prior session"]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T5 (narration FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "history/narration pattern" not in cap:
    failures.append("T5 (narration FAIL) expected the narration message: %s" % cap)

# T6: FAIL — size over the byte cap (anti-growth BACKSTOP). Pad a value with
#     no dates/SHAs/narration so ONLY the cap fires.
d = clean_snapshot(); d["queue"] = ["BD-%03d" % i for i in range(1, 600)]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T6 (over-cap FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "ANTI-GROWTH BACKSTOP" not in cap:
    failures.append("T6 (over-cap FAIL) expected the anti-growth backstop message: %s" % cap)

# T7: PASS — bare BD-tags are PERMITTED (a queue of many bare BD-tags, under cap).
d = clean_snapshot(); d["queue"] = ["BD-%d" % i for i in range(100, 130)]
fc, cap = run_in_tree(build_tree(data=d))
if fc != 0:
    failures.append("T7 (bare-BD-tags PERMITTED) expected 0 failures, got %d: %s" % (fc, cap))
if "no-history grammar OK" not in cap:
    failures.append("T7 (bare-BD-tags PERMITTED) expected the clean grammar message: %s" % cap)

# T8: lenient SKIP — absent snapshot.
fc, cap = run_in_tree(build_tree(include=False))
if fc != 0:
    failures.append("T8 (absent SKIP) expected 0 failures, got %d: %s" % (fc, cap))
if "absent — skipping (lenient" not in cap:
    failures.append("T8 (absent SKIP) expected the lenient-skip message: %s" % cap)

# T9: per-bd narration bites the ORIGINAL value (dead-pattern regression guard).
#     A strip-order bug once ran the per-bd pattern against the BD-tag-STRIPPED
#     value ("per BD"), so it could never match — dead code. A "per BD-42"
#     narration must FAIL (T9a); a bare "BD-42" value must still PASS (T9b) —
#     the strip protects the bare tag while per-bd scans the original.
d = clean_snapshot(); d["pending_decisions"] = ["queued per BD-42 as agreed"]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T9a (per-bd narration FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "history/narration pattern" not in cap:
    failures.append("T9a (per-bd narration FAIL) expected the narration message: %s" % cap)
d = clean_snapshot(); d["active"] = ["BD-42"]
fc, cap = run_in_tree(build_tree(data=d))
if fc != 0:
    failures.append("T9b (bare-BD-tag PERMITTED) expected 0 failures, got %d: %s" % (fc, cap))
if "no-history grammar OK" not in cap:
    failures.append("T9b (bare-BD-tag PERMITTED) expected the clean grammar message: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T9 (clean-PASS / ACCRETION-carry-over-FAIL[>=2 grounds] / 2nd-date-FAIL / off-field-SHA-FAIL / narration-FAIL / over-cap-FAIL / bare-BD-tags-PERMITTED / absent-SKIP / per-bd-bites-original+bare-tag-PERMITTED)" ;;
    *) t_fail "Synthetic-tree check_session_state_grammar tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: The accretion FAIL, captured + shown (the decisive proof artifact)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: ACCRETION carry-over FAIL — captured proof ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, json
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant; check_session_state_grammar reaches
    REPO_ROOT via the moved core seam _session_state_load)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


SNAP_REL = "pack-ops/session-state.json"
tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check79-proof-"))
p = tmpdir / SNAP_REL; p.parent.mkdir(parents=True, exist_ok=True)
data = {
    "schema": "pack-session-state/1", "boundary_commit": "2e899db",
    "checkpoint": "2026-06-29T00:00:00Z", "active": [], "in_flight_agents": [],
    "queue": ["BD-252"], "parallelization": "serial", "wave": None,
    "pending_decisions": [], "cycle_position": None,
    "notes": ("CARRY-OVER (2026-06-28): BD-246 landed RED at b6c5ecc; "
              "fixed 68842a6; then 143ee7d. LESSONS (keep): carried from the "
              "prior session. UPDATE-2 2026-06-27: queue reorder."),
}
p.write_text(json.dumps(data, indent=2) + "\n")
saved_root = mod.REPO_ROOT; saved_failures = list(mod.failures)
mod.failures.clear(); _patch_root(mod, tmpdir)
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_session_state_grammar()
    fails = list(mod.failures); cap = buf.getvalue()
finally:
    _patch_root(mod, saved_root); mod.failures.clear()
    mod.failures.extend(saved_failures); shutil.rmtree(tmpdir, ignore_errors=True)
print("CAPTURED FAIL OUTPUT (the carry-over-shaped accretion the check refuses):")
for line in cap.splitlines():
    if line.startswith("FAIL:"):
        print("  " + line)
print("TOTAL FAIL LINES: %d" % len(fails))
sys.exit(0 if len(fails) >= 1 else 1)
EOF
case $? in
    0) t_pass "ACCRETION carry-over fixture produces a captured, multi-ground FAIL (printed above) — the decisive measure-then-bound proof" ;;
    *) t_fail "ACCRETION carry-over fixture did not FAIL (effectiveness loss)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    echo "=== Results: $PASS passed, $FAIL failed ==="
    exit 1
fi
