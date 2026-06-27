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
#   1.  Well-formed pack-example + client-example  → PASS
#   2.  Bad schema_version on pack-example         → FAIL on that key
#   3.  Unknown backend.name on client-example     → FAIL on that key
#   4.  Wrong id_namespace.prefix on client-example → FAIL on that key
#   5.  Mode value not in the supported set        → FAIL on mode.state
#   6.  cli_acceleration.prefer not in supported set → FAIL on that key
#   7.  No [mirror] table on CLIENT example         → PASS
#       (BD-206: no surface keeps a monolith mirror — [mirror] is
#       optional on BOTH surfaces; mirror_required=False everywhere)
#   8.  Missing migration.mapping_file             → FAIL on that key
#   9.  TOML parse error                           → FAIL on parse
#   10. schema_version = true (bool-as-int trap)   → FAIL on bool (F3)
#   11. backend.repo missing                       → FAIL on missing key (F4)
#   12. backend.repo empty string                  → FAIL on empty (F4)
#   13. Live tracker.toml with stale mirror        → FAIL on staleness (F1)
#   14. Live tracker.toml flat-file mode           → soft-pass (F1)
#   15. Live tracker-mode toml, no [mirror]        → soft-pass (BD-204)
#   16. Live tracker + declared-but-missing mirror → FAIL (BD-204)
#   17. Pack example WITH [mirror] missing a key   → FAIL (BD-204:
#       optional-when-absent, but validated when present)
#
# Usage: bash scripts/tests/tracker-config-schema-test.sh
#
# Bash 3.2 compatible (macOS default). BSD utils (mktemp -d, sed, cp).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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
# set of keys Check 29 inspects). GOOD_PACK carries NO [mirror] table
# (BD-204: the live pack example omits it post-BD-203 — Test 1 passing
# with this body pins that Check 29 accepts the no-[mirror] pack shape).
read -r -d '' GOOD_PACK <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "DShaneNYC/optiquity-ai-agent-config-pack"

[mode]
state = "flat-file"

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

# ── Test 7: No [mirror] table on the CLIENT example → PASS (BD-206) ──
# BD-206: no surface keeps a monolith mirror (the per-entry tree +
# `_toc.md` is the sole SSOT). The client example, like the pack
# example, omits [mirror] — Check 29 must accept the no-[mirror] shape
# on BOTH surfaces (mirror_required=False everywhere). GOOD_CLIENT now
# carries no [mirror] block, so this pins the no-mirror client PASS.
printf "\n=== Test 7: no [mirror] table on client example → PASS ===\n"
fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "7.1 no [mirror] on client → exit 0 (no-mirror PASS)"
else t_fail "7.1 no [mirror] on client → exit 0 (no-mirror PASS)" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "missing required key: mirror"; then
    t_fail "7.2 Check 29 must NOT require [mirror] on the client example" "out=${out:0:400}"
else
    t_pass "7.2 Check 29 does not require [mirror] on the client example"
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

# ── Test 10: schema_version = true (bool-is-int Python trap, F3) ────
printf "\n=== Test 10: schema_version = true (bool-as-int defense) ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed 's/schema_version = 1/schema_version = true/')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "10.1 schema_version=true → exit nonzero"
else t_fail "10.1 schema_version=true → exit nonzero" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "schema_version: expected int, got bool"; then
    t_pass "10.2 message identifies expected int, got bool"
else
    t_fail "10.2 message identifies expected int, got bool" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 11: backend.repo missing (F4) ──────────────────────────────
printf "\n=== Test 11: missing backend.repo (load-bearing for gh CLI) ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed '/^repo = /d')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "11.1 missing backend.repo → exit nonzero"
else t_fail "11.1 missing backend.repo → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "missing required key: backend.repo"; then
    t_pass "11.2 message names backend.repo as missing"
else
    t_fail "11.2 message names backend.repo as missing" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 12: backend.repo empty string (F4) ─────────────────────────
printf "\n=== Test 12: empty backend.repo ===\n"
bad=$(printf '%s\n' "$GOOD_PACK" | sed 's|^repo = .*|repo = ""|')
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "12.1 empty backend.repo → exit nonzero"
else t_fail "12.1 empty backend.repo → exit nonzero" "rc=$rc"; fi
if echo "$out" | grep -q "backend.repo: empty string"; then
    t_pass "12.2 message identifies empty backend.repo"
else
    t_fail "12.2 message identifies empty backend.repo" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 13: Live tracker.toml with stale mirror (F1) ───────────────
# Build a fixture root with a live tracker.toml at the root (not just
# the example file) declaring tracker mode + completed forward
# migration with last_forward_run = 2026-05-15T12:00:00Z. Drop a
# BACKLOG.md mirror with a Last regenerated header at an older
# timestamp. Check 29 must surface staleness.
printf "\n=== Test 13: live tracker.toml + stale mirror ===\n"
read -r -d '' LIVE_TRACKER_ON <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "DShaneNYC/optiquity-ai-agent-config-pack"

[mode]
state = "tracker"
opted_in_at = "2026-05-15T12:00:00Z"

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
forward_complete = true
reverse_available = false
last_forward_run = "2026-05-15T12:00:00Z"
mapping_file = ".pack-tracker/id-map.json"
TOML

# Older timestamp than last_forward_run — must trip staleness.
read -r -d '' STALE_MIRROR <<'MIRROR' || true
<!--
  This file is a read-only mirror generated from the tracker.
  Tracker: github / DShaneNYC/optiquity-ai-agent-config-pack
  Last regenerated: 2026-05-01T08:00:00Z
  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.
-->

# BACKLOG (mirror)

stale body
MIRROR

# Fresh timestamp >= last_forward_run — must NOT trip staleness.
read -r -d '' FRESH_MIRROR <<'MIRROR' || true
<!--
  This file is a read-only mirror generated from the tracker.
  Tracker: github / DShaneNYC/optiquity-ai-agent-config-pack
  Last regenerated: 2026-05-15T13:00:00Z
  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.
-->

# STATUS (mirror)

fresh body
MIRROR

fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
# Plant a live tracker.toml + mirror files into the fixture root.
printf '%s\n' "$LIVE_TRACKER_ON"  > "$fix/tracker.toml"
printf '%s\n' "$STALE_MIRROR"     > "$fix/BACKLOG.md"
printf '%s\n' "$FRESH_MIRROR"     > "$fix/STATUS.md"
printf '%s\n' "$FRESH_MIRROR"     > "$fix/CHANGELOG.md"
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "13.1 stale BACKLOG mirror → exit nonzero"
else t_fail "13.1 stale BACKLOG mirror → exit nonzero" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "BACKLOG.md.*Last regenerated.*older than"; then
    t_pass "13.2 message names stale mirror + older-than wording"
else
    t_fail "13.2 message names stale mirror + older-than wording" "out=${out:0:600}"
fi
# Fresh mirrors should NOT appear in failure messages.
if echo "$out" | grep -q "STATUS.md.*older than"; then
    t_fail "13.3 fresh STATUS mirror should not be flagged stale" "out=${out:0:400}"
else
    t_pass "13.3 fresh STATUS mirror not flagged"
fi
rm -rf "$fix"

# ── Test 14: Live tracker.toml in flat-file mode → soft-pass (F1) ──
printf "\n=== Test 14: live tracker.toml flat-file → staleness N/A ===\n"
read -r -d '' LIVE_TRACKER_OFF <<'TOML' || true
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

fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
printf '%s\n' "$LIVE_TRACKER_OFF" > "$fix/tracker.toml"
# Even with NO mirror files at all, flat-file must soft-pass.
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "14.1 flat-file live tracker.toml → exit 0"
else t_fail "14.1 flat-file live tracker.toml → exit 0" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "mirror-staleness check N/A"; then
    t_pass "14.2 staleness leg reports N/A for flat-file mode"
else
    t_fail "14.2 staleness leg reports N/A for flat-file mode" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 15: Live tracker-mode tracker.toml, NO [mirror] → N/A (BD-204) ──
# The Mode-3 pack live config: mode='tracker', forward_complete=true,
# NO [mirror] table at all. Check 29′ must soft-pass (no-mirror surface).
printf "\n=== Test 15: live tracker.toml no-mirror → staleness N/A ===\n"
read -r -d '' LIVE_TRACKER_NOMIRROR <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "DShaneNYC/optiquity-ai-agent-config-pack"

[mode]
state = "tracker"
opted_in_at = "2026-05-15T12:00:00Z"

[id_namespace]
prefix = "BD"

[cli_acceleration]
prefer = "gh"

[migration]
forward_complete = true
reverse_available = false
last_forward_run = "2026-05-15T12:00:00Z"
mapping_file = ".pack-tracker/id-map.json"
TOML

fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
printf '%s\n' "$LIVE_TRACKER_NOMIRROR" > "$fix/tracker.toml"
# No mirror files at all — no-mirror surface must soft-pass.
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "15.1 no-mirror live tracker.toml → exit 0"
else t_fail "15.1 no-mirror live tracker.toml → exit 0" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "no-mirror surface, mirror-staleness check N/A"; then
    t_pass "15.2 staleness leg reports N/A for no-mirror surface"
else
    t_fail "15.2 staleness leg reports N/A for no-mirror surface" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 16: Live tracker + [mirror] enabled=true + missing file → FAIL ──
# Negative case — guard must NOT over-admit: a config that DECLARES a
# mirror (enabled=true) but is missing the mirror file still FAILs.
printf "\n=== Test 16: live tracker.toml claims mirror but missing → FAIL ===\n"
read -r -d '' LIVE_TRACKER_CLAIMS_MIRROR <<'TOML' || true
schema_version = 1

[backend]
name = "github"
repo = "DShaneNYC/optiquity-ai-agent-config-pack"

[mode]
state = "tracker"
opted_in_at = "2026-05-15T12:00:00Z"

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
forward_complete = true
reverse_available = false
last_forward_run = "2026-05-15T12:00:00Z"
mapping_file = ".pack-tracker/id-map.json"
TOML

fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
printf '%s\n' "$LIVE_TRACKER_CLAIMS_MIRROR" > "$fix/tracker.toml"
# Deliberately plant NO mirror files — the declared mirror is missing.
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "16.1 claims-mirror-but-missing → exit nonzero"
else t_fail "16.1 claims-mirror-but-missing → exit nonzero" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "BACKLOG.md.*does not exist on disk"; then
    t_pass "16.2 message names missing mirror file (guard did not over-admit)"
else
    t_fail "16.2 message names missing mirror file (guard did not over-admit)" "out=${out:0:600}"
fi
rm -rf "$fix"

# ── Test 17: Pack example WITH [mirror] but missing a key → FAIL ────
# BD-204 negative case — [mirror] is OPTIONAL on the pack example, but
# when the table IS present its keys are still validated (the schema
# branch must not widen into ignoring a malformed table).
printf "\n=== Test 17: pack example with malformed [mirror] ===\n"
read -r -d '' PACK_BAD_MIRROR <<'TOML' || true
[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
regenerate_on_write = true
TOML
bad="$GOOD_PACK

$PACK_BAD_MIRROR"
fix=$(build_fixture "$bad" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "17.1 present-but-malformed mirror on pack → exit nonzero"
else t_fail "17.1 present-but-malformed mirror on pack → exit nonzero" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "pack-example — missing required key: mirror.location_status"; then
    t_pass "17.2 message names the missing mirror key on the pack example"
else
    t_fail "17.2 message names the missing mirror key on the pack example" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Test 18: Check 29″ — never-tracked tracker.toml (BD-204) ────────
# The local-opt-in model's CI realization: a git-TRACKED root
# tracker.toml FAILs; an untracked one (and a non-git fixture root)
# soft-passes. Per ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2
# §B7 / D2-5. Scratch git repos are self-provisioned + cleaned up.
printf "\n=== Test 18: Check 29-doubleprime never-tracked tracker.toml ===\n"

# 18a: non-git fixture root (every prior test's shape) → soft-pass
# (already implicitly proven by Tests 1–17 exiting per their schema
# expectations; pin the OK banner explicitly here).
fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
out=$(run_check29_at "$fix" 2>&1); rc=$?
if echo "$out" | grep -q "not git-tracked at the pack root"; then
    t_pass "18a.1 non-git fixture root → 29″ soft-pass banner"
else
    t_fail "18a.1 non-git fixture root → 29″ soft-pass banner" "out=${out:0:400}"
fi
rm -rf "$fix"

# 18b: git repo with an UNTRACKED tracker.toml → soft-pass.
fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
git -C "$fix" init -q -b main
git -C "$fix" config user.email test@example.com
git -C "$fix" config user.name test
printf '%s\n' "$GOOD_PACK" > "$fix/tracker.toml"   # untracked live file
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -eq 0 ]]; then t_pass "18b.1 untracked live tracker.toml → exit 0"
else t_fail "18b.1 untracked live tracker.toml → exit 0" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "not git-tracked at the pack root"; then
    t_pass "18b.2 untracked live tracker.toml → 29″ OK banner"
else
    t_fail "18b.2 untracked live tracker.toml → 29″ OK banner" "out=${out:0:400}"
fi
rm -rf "$fix"

# 18c: git repo with a COMMITTED tracker.toml → FAIL naming the
# local-opt-in contract + the untrack recovery.
fix=$(build_fixture "$GOOD_PACK" "$GOOD_CLIENT")
git -C "$fix" init -q -b main
git -C "$fix" config user.email test@example.com
git -C "$fix" config user.name test
printf '%s\n' "$GOOD_PACK" > "$fix/tracker.toml"
git -C "$fix" add tracker.toml
git -C "$fix" commit -qm "fixture: tracked tracker.toml"
out=$(run_check29_at "$fix" 2>&1); rc=$?
if [[ $rc -ne 0 ]]; then t_pass "18c.1 TRACKED tracker.toml → exit nonzero"
else t_fail "18c.1 TRACKED tracker.toml → exit nonzero" "rc=$rc out=${out:0:400}"; fi
if echo "$out" | grep -q "tracker.toml is git-TRACKED at the pack root"; then
    t_pass "18c.2 FAIL names the tracked state"
else
    t_fail "18c.2 FAIL names the tracked state" "out=${out:0:400}"
fi
if echo "$out" | grep -q "git rm --cached tracker.toml"; then
    t_pass "18c.3 FAIL names the untrack recovery"
else
    t_fail "18c.3 FAIL names the untrack recovery" "out=${out:0:400}"
fi
rm -rf "$fix"

# ── Summary ─────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "PASS: %d\n" "$PASS"
printf "FAIL: %d\n" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
