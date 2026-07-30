#!/usr/bin/env bash
# scripts/tests/recommendation-state-schema-test.sh — fixture suite
# for validate-pack.py Check 30 (`check_recommendation_state_schema`,
# BD-079).
#
# Strategy: spawn an isolated REPO_ROOT under /tmp containing only
# `.pack-tracker/recommendation-state.json` (or omitting it entirely
# for the absent-file soft-pass case), then invoke Check 30 against
# the fixture root via a Python harness that imports the live
# validate-pack.py module.
#
# Coverage:
#   1. File absent                     → PASS (lazy-create soft-pass)
#   2. Well-formed v1 state            → PASS
#   3. JSON parse error                → FAIL (parse error message)
#   4. Top-level not a JSON object     → FAIL (top-level type)
#   5. Missing required field          → FAIL (names the missing field)
#   6. Wrong type for field            → FAIL (names the field + types)
#   7. schema_version != "v1"          → FAIL (names expected vs actual)
#   8. surface outside {pack,client}   → FAIL (names allowed values)
#   9. user_re_enable_count negative   → FAIL (≥ 0 message)
#  10. user_re_enable_count is bool    → FAIL (rejects bool-as-int)
#
# Usage: bash scripts/tests/recommendation-state-schema-test.sh
#
# Bash 3.2 compatible (macOS default).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

run_check30_at() {
    local fixture_root="$1"
    REPO_ROOT_OVERRIDE="$fixture_root" python3 - <<'PYEOF'
import os, sys, importlib.util
from pathlib import Path

fixture = Path(os.environ["REPO_ROOT_OVERRIDE"]).resolve()
real_repo = Path(os.environ["REAL_REPO_ROOT"]).resolve()
spec = importlib.util.spec_from_file_location(
    "validate_pack", str(real_repo / "scripts" / "validate-pack.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W1 wave-invariant). A check body reads REPO_ROOT from
    whatever module it lives in (the facade pre-move; a category module
    post-move) AND via the moved core seams (_session_state_load reads
    core.REPO_ROOT). Setting it on every loaded validate_checks.* reaches the
    read wherever it resolves. `root` is a pathlib.Path."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


_patch_root(mod, fixture)
mod.failures.clear()
mod.check_recommendation_state_schema()
print("---FAILURES---")
for f in mod.failures:
    print(f)
sys.exit(0 if not mod.failures else 1)
PYEOF
}

# Build a fresh fixture root, optionally with a state file body.
# If body is empty, the file is omitted entirely.
build_fixture() {
    local body="$1"
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/rec-state-fix.XXXXXX")
    if [[ -n "$body" ]]; then
        mkdir -p "$d/.pack-tracker"
        printf '%s\n' "$body" > "$d/.pack-tracker/recommendation-state.json"
    fi
    echo "$d"
}

export REAL_REPO_ROOT="$REPO_ROOT"

GOOD_STATE='{
  "schema_version": "v1",
  "surface": "pack",
  "persistent_refusal": false,
  "persistent_refusal_at": null,
  "last_recommendation_shown_at": null,
  "last_recommendation_signals": {},
  "user_re_enable_count": 0
}'

# ── Test 1: File absent → PASS ──────────────────────────────────────
printf "\n=== Test 1: file absent ===\n"
fix=$(build_fixture "")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "1.1 absent file → exit 0"
else t_fail "1.1 absent file → exit 0" "rc=$rc out=${out:0:300}"; fi
if echo "$out" | grep -q "lazy-create is by design"; then
    t_pass "1.2 message confirms lazy-create soft-pass"
else
    t_fail "1.2 message confirms lazy-create soft-pass" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 2: Well-formed → PASS ──────────────────────────────────────
printf "\n=== Test 2: well-formed v1 state ===\n"
fix=$(build_fixture "$GOOD_STATE")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "2.1 well-formed → exit 0"
else t_fail "2.1 well-formed → exit 0" "rc=$rc out=${out:0:400}"; fi
rm -rf "$fix"

# ── Test 3: JSON parse error ────────────────────────────────────────
printf "\n=== Test 3: JSON parse error ===\n"
fix=$(build_fixture "{not valid json")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "3.1 parse error → exit nonzero"
else t_fail "3.1 parse error → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "JSON parse error"; then
    t_pass "3.2 message identifies parse error"
else
    t_fail "3.2 message identifies parse error" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 4: Top-level not an object ─────────────────────────────────
printf "\n=== Test 4: top-level array ===\n"
fix=$(build_fixture "[1, 2, 3]")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "4.1 top-level array → exit nonzero"
else t_fail "4.1 top-level array → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "top-level JSON must be an object"; then
    t_pass "4.2 message names top-level type"
else
    t_fail "4.2 message names top-level type" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 5: Missing required field ──────────────────────────────────
printf "\n=== Test 5: missing surface field ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
del d["surface"]
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "5.1 missing field → exit nonzero"
else t_fail "5.1 missing field → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "missing required field: surface"; then
    t_pass "5.2 message names missing field"
else
    t_fail "5.2 message names missing field" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 6: Wrong type for field ────────────────────────────────────
printf "\n=== Test 6: persistent_refusal as string ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
d["persistent_refusal"] = "false"
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "6.1 wrong type → exit nonzero"
else t_fail "6.1 wrong type → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "field persistent_refusal:.*got str"; then
    t_pass "6.2 message names field + actual type"
else
    t_fail "6.2 message names field + actual type" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 7: schema_version != "v1" ──────────────────────────────────
printf "\n=== Test 7: schema_version drift ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
d["schema_version"] = "v2"
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "7.1 schema_version drift → exit nonzero"
else t_fail "7.1 schema_version drift → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "schema_version: expected 'v1', got 'v2'"; then
    t_pass "7.2 message names expected vs actual"
else
    t_fail "7.2 message names expected vs actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 8: surface outside {pack,client} ───────────────────────────
printf "\n=== Test 8: bad surface ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
d["surface"] = "desktop"
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "8.1 bad surface → exit nonzero"
else t_fail "8.1 bad surface → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "surface: expected.*got 'desktop'"; then
    t_pass "8.2 message names surface + actual"
else
    t_fail "8.2 message names surface + actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 9: user_re_enable_count negative ───────────────────────────
printf "\n=== Test 9: negative user_re_enable_count ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
d["user_re_enable_count"] = -3
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "9.1 negative count → exit nonzero"
else t_fail "9.1 negative count → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "user_re_enable_count: must be"; then
    t_pass "9.2 message names ≥ 0 constraint"
else
    t_fail "9.2 message names ≥ 0 constraint" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 10: user_re_enable_count is bool (rejected as int) ─────────
printf "\n=== Test 10: bool stored as user_re_enable_count ===\n"
bad=$(printf '%s' "$GOOD_STATE" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
d["user_re_enable_count"] = True
print(json.dumps(d))
')
fix=$(build_fixture "$bad")
out=$(run_check30_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "10.1 bool-as-int → exit nonzero"
else t_fail "10.1 bool-as-int → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "user_re_enable_count:.*got bool"; then
    t_pass "10.2 message names bool rejection"
else
    t_fail "10.2 message names bool rejection" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Summary ─────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
