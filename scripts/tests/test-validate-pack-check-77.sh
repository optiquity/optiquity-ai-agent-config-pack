#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-validate-pack-check-77.sh — synthetic fixture tests for
# BD-252 Check 77 (session-state snapshot structural well-formedness;
# DESIGN-RECONCILED.md §4 + PLAN.md §0/§2 C2).
#
# Check 77 json.load-s `pack-ops/session-state.json` and asserts:
#   - the required P1-P9 key set (sized EXACTLY to the seed schema)
#   - `boundary_commit` matches ^[0-9a-f]{7,40}$
#   - `checkpoint` is ISO-8601
# SKIP-lenient when the snapshot is ABSENT (it ships in a LATER commit — until
# then this leg SKIPs, never fails).
#
# This test exercises Check 77's BODY IN-PROCESS against synthetic /tmp
# REPO_ROOT trees (the monkeypatch seam: save/restore mod.REPO_ROOT +
# mod.failures) and asserts that 77 IS in the registry while the count invariant
# holds DYNAMICALLY (never a hardcoded literal). Test infra is self-provisioned;
# no real shipped file is mutated. Cleanup runs on every exit.
#
# Coverage:
#   Group 0: Module import + Check 77 symbols + dynamic count-invariant +
#            Check 77 REGISTERED
#   Group 1: Synthetic-tree end-to-end (in-process body invocation) —
#            T1  complete valid snapshot PASSES
#            T2  missing required key FAILS
#            T3  malformed boundary_commit (not 7-40 hex) FAILS
#            T4  non-ISO checkpoint FAILS
#            T5  invalid JSON (parse error) FAILS
#            T6  ABSENT snapshot → lenient SKIP
#            T7  non-object top-level JSON FAILS
#
# Usage: bash scripts/tests/test-validate-pack-check-77.sh
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

printf "\n=== Group 0: Module import + Check 77 symbols + registered ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_session_state_struct', '_SESSION_STATE_FILE',
           '_SESSION_STATE_REQUIRED_KEYS', '_SESSION_STATE_SHA_KEY',
           '_SESSION_STATE_DATE_KEY', '_session_state_load']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing)); sys.exit(1)
# the required-key set is sized to the P1-P9 seed schema (10 keys: schema +
# boundary_commit + checkpoint + active + in_flight_agents + queue +
# parallelization + wave + pending_decisions + cycle_position).
if len(mod._SESSION_STATE_REQUIRED_KEYS) != 10:
    print('FAIL_KEYSET_SIZE', mod._SESSION_STATE_REQUIRED_KEYS); sys.exit(1)
for k in ('schema', 'boundary_commit', 'checkpoint', 'queue', 'cycle_position'):
    if k not in mod._SESSION_STATE_REQUIRED_KEYS:
        print('FAIL_KEY_MISSING', k); sys.exit(1)
# DYNAMIC count invariant — never a hardcoded literal.
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(mod._build_check_registry()),
          mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
# Check 77 is REGISTERED.
nums = [t[0] for t in mod._build_check_registry()]
if 77 not in nums:
    print('FAIL_77_NOT_REGISTERED'); sys.exit(1)
print('OK')
" > /tmp/vp-check77-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check77-import.out; then
    t_pass "imports + Check 77 symbols present + required-key set is 10 (P1-P9 seed schema) + count invariant holds (dynamic) + Check 77 REGISTERED"
else
    t_fail "Check 77 import / symbol / count / registered-state check failed" \
        "$(cat /tmp/vp-check77-import.out)"
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
    submodule (BD-256 W1 wave-invariant). check_session_state_struct reads
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
    """A valid P1-P9 snapshot (the seed shape)."""
    return {
        "schema": "pack-session-state/1",
        "boundary_commit": "2e899db",
        "checkpoint": "2026-06-29T00:00:00Z",
        "active": [],
        "in_flight_agents": [],
        "queue": ["BD-252", "BD-219", "BD-222"],
        "parallelization": "serial",
        "wave": None,
        "pending_decisions": [],
        "cycle_position": None,
    }

def build_tree(*, data=None, raw=None, include=True):
    """Build a synthetic /tmp REPO_ROOT carrying (or omitting) the snapshot.
       data: a dict serialized to JSON; raw: literal bytes (for malformed JSON);
       include=False: omit the file (absent-SKIP leg)."""
    tmpdir = pathlib.Path(tempfile.mkdtemp(prefix="vp-check77-"))
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
            mod.check_session_state_struct()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — complete valid snapshot.
fc, cap = run_in_tree(build_tree())
if fc != 0:
    failures.append("T1 (valid PASS) expected 0 failures, got %d: %s" % (fc, cap))
if "valid JSON; required P1-P9 keys present" not in cap:
    failures.append("T1 (valid PASS) expected the clean message: %s" % cap)

# T2: FAIL — a missing required key (drop the queue key).
d = clean_snapshot(); del d["queue"]
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T2 (missing-key FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "missing required key" not in cap or "queue" not in cap:
    failures.append("T2 (missing-key FAIL) expected the missing-key message naming queue: %s" % cap)

# T3: FAIL — malformed boundary_commit (not 7-40 hex).
d = clean_snapshot(); d["boundary_commit"] = "NOTAHEXSHA"
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T3 (bad-sha FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "boundary_commit" not in cap or "hex commit SHA" not in cap:
    failures.append("T3 (bad-sha FAIL) expected the boundary_commit hex message: %s" % cap)

# T4: FAIL — non-ISO checkpoint.
d = clean_snapshot(); d["checkpoint"] = "yesterday afternoon"
fc, cap = run_in_tree(build_tree(data=d))
if fc < 1:
    failures.append("T4 (bad-date FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "checkpoint" not in cap or "ISO-8601" not in cap:
    failures.append("T4 (bad-date FAIL) expected the checkpoint ISO-8601 message: %s" % cap)

# T5: FAIL — invalid JSON (parse error).
fc, cap = run_in_tree(build_tree(raw=b"{ this is not json "))
if fc < 1:
    failures.append("T5 (parse FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "INVALID JSON" not in cap:
    failures.append("T5 (parse FAIL) expected the INVALID JSON message: %s" % cap)

# T6: lenient SKIP — absent snapshot.
fc, cap = run_in_tree(build_tree(include=False))
if fc != 0:
    failures.append("T6 (absent SKIP) expected 0 failures, got %d: %s" % (fc, cap))
if "absent — skipping (lenient" not in cap:
    failures.append("T6 (absent SKIP) expected the lenient-skip message: %s" % cap)

# T7: FAIL — non-object top-level JSON (a JSON array).
fc, cap = run_in_tree(build_tree(raw=b'["not", "an", "object"]'))
if fc < 1:
    failures.append("T7 (non-object FAIL) expected >=1 failure, got %d: %s" % (fc, cap))
if "must be an OBJECT" not in cap:
    failures.append("T7 (non-object FAIL) expected the must-be-OBJECT message: %s" % cap)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic-tree body tests T1-T7 (valid-PASS / missing-key-FAIL / bad-sha-FAIL / bad-date-FAIL / parse-FAIL / absent-SKIP / non-object-FAIL)" ;;
    *) t_fail "Synthetic-tree check_session_state_struct tests failed (see Python output)" ;;
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
