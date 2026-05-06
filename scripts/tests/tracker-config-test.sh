#!/usr/bin/env bash
# scripts/tests/tracker-config-test.sh — offline test suite for
# tracker-config.sh (BD-061).
#
# Three groups:
#   1. Path resolution + reader — resolve_path, read, get
#   2. tracker_mode V1 §3.2 detection — 4 input cases
#   3. Schema-version + dispatcher integration — schema_version_check
#      and the tracker-provider.sh resolver consulting tracker.toml
#
# Usage: bash scripts/tests/tracker-config-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures/tracker-config"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq() {
    if [[ "$2" == "$3" ]]; then t_pass "$1"
    else t_fail "$1" "expected='$2' actual='$3'"; fi
}

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "needle='$3' missing from: ${2:0:200}"; fi
}

# Source the library under test.
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"

# ─────────────────────────────────────────────────────────────────
# Group 1: path resolution + reader
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: path resolution + reader ===\n"

# 1.1 resolve_path: pack
out=$(tracker_config_resolve_path pack /repo)
assert_eq "1.1 resolve_path pack → /repo/tracker.toml" "/repo/tracker.toml" "$out"

# 1.2 resolve_path: client
out=$(tracker_config_resolve_path client /proj)
assert_eq "1.2 resolve_path client → /proj/docs/pack/tracker.toml" "/proj/docs/pack/tracker.toml" "$out"

# 1.3 resolve_path: unknown surface → validation error
err=$(tracker_config_resolve_path desktop /home 2>&1 1>/dev/null) || true
assert_contains "1.3 resolve_path bad-surface → validation" "$err" "ERROR: validation"

# 1.4 read: missing file → not-found
err=$(tracker_config_read "/no/such/tracker.toml" 2>&1 1>/dev/null) || true
assert_contains "1.4 read missing-file → not-found"  "$err" "ERROR: not-found"

# 1.5 read: tracker-mode fixture → JSON dotted-key map
out=$(tracker_config_read "$FIXTURES/tracker-mode.toml")
assert_eq "1.5 read tracker-mode schema_version"     "1"        "$(printf '%s' "$out" | jq -r '.schema_version')"
assert_eq "1.5 read tracker-mode backend.name"       "github"   "$(printf '%s' "$out" | jq -r '."backend.name"')"
assert_eq "1.5 read tracker-mode mode.state"         "tracker"  "$(printf '%s' "$out" | jq -r '."mode.state"')"
assert_eq "1.5 read tracker-mode migration.forward"  "true"     "$(printf '%s' "$out" | jq -r '."migration.forward_complete"')"
assert_eq "1.5 read tracker-mode id_namespace.prefix" "BD"      "$(printf '%s' "$out" | jq -r '."id_namespace.prefix"')"
assert_eq "1.5 read tracker-mode mirror.enabled"     "true"     "$(printf '%s' "$out" | jq -r '."mirror.enabled"')"

# 1.6 read: malformed → validation
err=$(tracker_config_read "$FIXTURES/malformed.toml" 2>&1 1>/dev/null) || true
assert_contains "1.6 read malformed → validation" "$err" "ERROR: validation"

# 1.7 get: dotted-key
val=$(tracker_config_get "$FIXTURES/tracker-mode.toml" "backend.repo")
assert_eq "1.7 get backend.repo" "Optiquity-Inc/optiquity-ai-agent-config-pack" "$val"

# 1.8 get: missing key → rc=1
if tracker_config_get "$FIXTURES/tracker-mode.toml" "no.such.key" >/dev/null 2>&1; then
    t_fail "1.8 get missing-key" "expected rc=1, got rc=0"
else
    t_pass "1.8 get missing-key → rc=1"
fi

# 1.9 convenience getters
assert_eq "1.9 tracker_backend_name" "github"   "$(tracker_backend_name "$FIXTURES/tracker-mode.toml")"
assert_eq "1.9 tracker_repo_slug"    "Optiquity-Inc/optiquity-ai-agent-config-pack" "$(tracker_repo_slug "$FIXTURES/tracker-mode.toml")"
assert_eq "1.9 tracker_id_prefix"    "BD"       "$(tracker_id_prefix "$FIXTURES/tracker-mode.toml")"

# 1.10 read tolerates inline comments
inline_tmp=$(mktemp -t tcfg-inline.XXXXXX)
cat > "$inline_tmp" <<'EOF'
schema_version = 1  # this is the schema version
[backend]
name = "github"  # backend name
repo = "x/y"
[mode]
state = "tracker"
[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
EOF
out=$(tracker_config_read "$inline_tmp")
assert_eq "1.10 read with inline comments — schema_version=1" "1" "$(printf '%s' "$out" | jq -r '.schema_version')"
assert_eq "1.10 read with inline comments — backend.name=github" "github" "$(printf '%s' "$out" | jq -r '."backend.name"')"
rm -f "$inline_tmp"

# ─────────────────────────────────────────────────────────────────
# Group 2: tracker_mode (V1 §3.2)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: tracker_mode V1 §3.2 ===\n"

# 2.1 no file → flat-file
assert_eq "2.1 no file → flat-file"            "flat-file" "$(tracker_mode "/no/such/path")"
# 2.2 mode.state = "flat-file" → flat-file
assert_eq "2.2 state=flat-file → flat-file"    "flat-file" "$(tracker_mode "$FIXTURES/flat-file-mode.toml")"
# 2.3 mode.state = "tracker" but forward_complete = false → flat-file
assert_eq "2.3 not-yet-migrated → flat-file"   "flat-file" "$(tracker_mode "$FIXTURES/not-yet-migrated.toml")"
# 2.4 mode.state = "tracker" + forward_complete = true → tracker
assert_eq "2.4 fully-migrated → tracker"        "tracker"   "$(tracker_mode "$FIXTURES/tracker-mode.toml")"
# 2.5 malformed → flat-file (permissive fallback per V1 §3.2)
assert_eq "2.5 malformed → flat-file"           "flat-file" "$(tracker_mode "$FIXTURES/malformed.toml")"

# ─────────────────────────────────────────────────────────────────
# Group 3: schema_version + dispatcher integration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: schema_version + dispatcher integration ===\n"

# 3.1 schema_version_check OK
if tracker_schema_version_check "$FIXTURES/tracker-mode.toml" 2>/dev/null; then
    t_pass "3.1 schema_version_check pass on schema_version=1"
else
    t_fail "3.1 schema_version_check pass on schema_version=1" "rc=1 unexpectedly"
fi

# 3.2 schema_version_check fail on wrong version
err=$(tracker_schema_version_check "$FIXTURES/wrong-schema.toml" 2>&1 1>/dev/null) || true
assert_contains "3.2 schema_version_check on schema_version=99 → validation" "$err" "ERROR: validation"
assert_contains "3.2 schema_version_check error names actual version"        "$err" "schema_version=99"

# 3.3 schema_version_check fail when key missing
no_ver_tmp=$(mktemp -t tcfg-noschema.XXXXXX)
printf 'name = "x"\n' > "$no_ver_tmp"
err=$(tracker_schema_version_check "$no_ver_tmp" 2>&1 1>/dev/null) || true
assert_contains "3.3 schema_version_check missing key → validation" "$err" "missing required key"
rm -f "$no_ver_tmp"

# 3.4 dispatcher integration: when tracker-config.sh is sourced AND
# _TRACKER_PROVIDER_CONFIG_PATH points at a file with backend.name="stub",
# tracker-provider's _tracker_provider_backend() returns "stub".

# Build a minimal stub-routing tracker.toml
stub_toml=$(mktemp -t tcfg-stub.XXXXXX)
cat > "$stub_toml" <<'EOF'
schema_version = 1
[backend]
name = "stub"
repo = "x/y"
[mode]
state = "flat-file"
[id_namespace]
prefix = "BD"
[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
EOF

# Source tracker-provider.sh now (after tracker-config.sh).
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"

# Without the env var: should fall back to "github".
unset _TRACKER_PROVIDER_BACKEND_OVERRIDE _TRACKER_PROVIDER_CONFIG_PATH
got=$(_tracker_provider_backend)
assert_eq "3.4a no env var → github (default)" "github" "$got"

# With the env var: should consult tracker-config and route to "stub".
export _TRACKER_PROVIDER_CONFIG_PATH="$stub_toml"
got=$(_tracker_provider_backend)
assert_eq "3.4b _TRACKER_PROVIDER_CONFIG_PATH set → backend.name=stub" "stub" "$got"

# Override still wins absolutely.
export _TRACKER_PROVIDER_BACKEND_OVERRIDE=mars
got=$(_tracker_provider_backend)
assert_eq "3.4c override wins absolutely" "mars" "$got"

unset _TRACKER_PROVIDER_BACKEND_OVERRIDE _TRACKER_PROVIDER_CONFIG_PATH
rm -f "$stub_toml"

# 3.5 dispatcher integration: missing config path → silently falls back to github
export _TRACKER_PROVIDER_CONFIG_PATH="/no/such/tracker.toml"
got=$(_tracker_provider_backend)
assert_eq "3.5 missing config file → github fallback" "github" "$got"
unset _TRACKER_PROVIDER_CONFIG_PATH

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────

printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
printf "All tests passed.\n"
exit 0
