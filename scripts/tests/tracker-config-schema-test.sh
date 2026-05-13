#!/usr/bin/env bash
# scripts/tests/tracker-config-schema-test.sh — fixture suite for
# validate-pack.py Check 29 (`check_tracker_config`, BD-078).
#
# Strategy: spawn an isolated REPO_ROOT under /tmp containing only the
# files Check 29 reads (tracker.toml.pack-example +
# project-template/tracker.toml.project-example) plus a one-shot
# Python harness that imports validate-pack.py's Check 29 entrypoint
# and invokes it against the fixture root. We exercise:
#
#   1. Well-formed pack-example + client-example   → PASS
#   2. Bad schema_version on pack-example          → FAIL on that key
#   3. Unknown backend.name on client-example      → FAIL on that key
#   4. Wrong id_namespace.prefix on client-example → FAIL on that key
#   5. Mode value not in the supported set         → FAIL on mode.state
#   6. cli_acceleration.prefer not in supported set → FAIL on that key
#   7. Missing [mirror] table                      → FAIL on mirror
#   8. Missing migration.mapping_file              → FAIL on that key
#   9. TOML parse error                            → FAIL on parse
#
# Usage: bash scripts/tests/tracker-config-schema-test.sh
#
# Bash 3.2 compatible (macOS default). BSD utils (mktemp -d, sed, cp).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

# Run Check 29 against an arbitrary REPO_ROOT directory. Emits
# combined stdout+stderr for caller to grep on. Exit code reflects
# whether `failures` accumulated inside check_tracker_config.
run_check29_at() {
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

# Re-point the module's REPO_ROOT at the fixture and clear failures.
mod.REPO_ROOT = fixture
mod.failures = []
mod.check_tracker_config()
print("---FAILURES---")
for f in mod.failures:
    print(f)
sys.exit(0 if not mod.failures else 1)
PYEOF
}

# Build a fresh fixture directory containing both example files.
# Caller provides a body for each via the FIXTURE_PACK / FIXTURE_CLIENT
# vars before calling. Returns the fixture root path on stdout.
build_fixture() {
    local pack_body="$1"
    local client_body="$2"
    local d
    d=$(mktemp -d -t tracker-cfg-fix.XXXXXX)
    mkdir -p "$d/project-template"
    printf '%s\n' "$pack_body"   > "$d/tracker.toml.pack-example"
    printf '%s\n' "$client_body" > "$d/project-template/tracker.toml.project-example"
    echo "$d"
}

export REAL_REPO_ROOT="$REPO_ROOT"

# Canonical good bodies (modeled on the live example files; minimum
# set of keys Check 29 inspects).
read -r -d '' GOOD_PACK <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "DShaneNYC/optiquity-ai-agent-config-pack"

[mode]
state = "flat-file"

[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
location_status    = "STATUS.md"
location_changelog = "CHANGELOG.md"
regenerate_on_write = true

[id_namespace]
prefix = "BD"

[cli_acceleration]
prefer = "gh"

[migration]
forward_complete = false
reverse_available = false
mapping_file = ".pack-tracker/id-map.json"
TOML

read -r -d '' GOOD_CLIENT <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "your-org/your-project"

[mode]
state = "flat-file"

[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
location_status    = "STATUS.md"
location_changelog = "CHANGELOG.md"
regenerate_on_write = true

[id_namespace]
prefix = "TD"

[cli_acceleration]
prefer = "gh"

[migration]
forward_complete = false
reverse_available = false
mapping_file = ".pack-tracker/id-map.json"
TOML

# ── Test 1: Both well-formed → PASS ─────────────────────────────────
printf "\n=== Test 1: well-formed pack + client ===\n"
fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "1.1 well-formed → exit 0"
else t_fail "1.1 well-formed → exit 0" "rc=$rc out=${out:0:300}"; fi
rm -rf "$fix"

# ── Test 2: Bad schema_version on pack ──────────────────────────────
printf "\n=== Test 2: bad schema_version on pack ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed 's/schema_version = 1/schema_version = 99/')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "2.1 bad schema_version → exit nonzero"
else t_fail "2.1 bad schema_version → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "schema_version: expected 1, got 99"; then
    t_pass "2.2 message names key + expected vs actual"
else
    t_fail "2.2 message names key + expected vs actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 3: Unknown backend.name on client ──────────────────────────
printf "\n=== Test 3: unknown backend.name on client ===\n"
bad=$(printf '%s\n' "$GOOD_CLIENT" | sed 's/name = "github"/name = "trello"/')
fix=$(build_fixture "$GOOD_PACK" "$bad")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "3.1 unknown backend → exit nonzero"
else t_fail "3.1 unknown backend → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "backend.name:.*got 'trello'"; then
    t_pass "3.2 message names backend.name + actual value"
else
    t_fail "3.2 message names backend.name + actual value" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 4: Wrong id_namespace.prefix on client (BD instead of TD) ──
printf "\n=== Test 4: wrong id_namespace.prefix on client ===\n"
bad=$(printf '%s\n' "$GOOD_CLIENT" | sed 's/prefix = "TD"/prefix = "BD"/')
fix=$(build_fixture "$GOOD_PACK" "$bad")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "4.1 wrong prefix → exit nonzero"
else t_fail "4.1 wrong prefix → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "id_namespace.prefix: expected 'TD' for this surface, got 'BD'"; then
    t_pass "4.2 message names key + expected vs actual"
else
    t_fail "4.2 message names key + expected vs actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 5: mode.state outside supported set ────────────────────────
printf "\n=== Test 5: bad mode.state ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed 's/state = "flat-file"/state = "hybrid"/')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "5.1 bad mode → exit nonzero"
else t_fail "5.1 bad mode → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "mode.state: expected.*got 'hybrid'"; then
    t_pass "5.2 message names mode.state + actual"
else
    t_fail "5.2 message names mode.state + actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 6: cli_acceleration.prefer outside set ─────────────────────
printf "\n=== Test 6: bad cli_acceleration.prefer ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed 's/prefer = "gh"/prefer = "wishful"/')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "6.1 bad prefer → exit nonzero"
else t_fail "6.1 bad prefer → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "cli_acceleration.prefer:.*got 'wishful'"; then
    t_pass "6.2 message names key + actual"
else
    t_fail "6.2 message names key + actual" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 7: Missing [mirror] table ──────────────────────────────────
printf "\n=== Test 7: missing [mirror] table ===\n"
# Strip the entire [mirror] block (table header + 5 keys).
bad=$(printf '%s\n' "$GOOD_PACK" | awk '
  /^\[mirror\]$/ { skip=1; next }
  skip && /^\[/ { skip=0 }
  !skip { print }
')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "7.1 missing mirror → exit nonzero"
else t_fail "7.1 missing mirror → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "missing required key: mirror"; then
    t_pass "7.2 message names mirror as missing"
else
    t_fail "7.2 message names mirror as missing" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 8: Missing migration.mapping_file ──────────────────────────
printf "\n=== Test 8: missing migration.mapping_file ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed '/mapping_file/d')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "8.1 missing mapping_file → exit nonzero"
else t_fail "8.1 missing mapping_file → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "missing required key: migration.mapping_file"; then
    t_pass "8.2 message names migration.mapping_file as missing"
else
    t_fail "8.2 message names migration.mapping_file as missing" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 9: TOML parse error ────────────────────────────────────────
printf "\n=== Test 9: TOML parse error ===\n"
bad="schema_version = oops not toml ["
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "9.1 parse error → exit nonzero"
else t_fail "9.1 parse error → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "TOML parse error"; then
    t_pass "9.2 message identifies parse error"
else
    t_fail "9.2 message identifies parse error" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Summary ─────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
