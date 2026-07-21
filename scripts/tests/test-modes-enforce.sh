#!/usr/bin/env bash
# test-modes-enforce.sh — unit test for the isolation_mode enforcement feature.
#
#   Group A: the scripts/hooks/modes-enforce.py hook-body decision matrix +
#            fail-open cases (the body must ALWAYS exit 0, NEVER exit 2).
#   Group B: the scripts/install-modes-hook.sh JSON deep-merge / idempotency /
#            uninstall (via the MODES_HOOK_SETTINGS_FILE scratch-file seam).
#
# CI-wired simply by existing on disk (the disk-glob CI matrix). Offline +
# deterministic: it only pipes JSON to python3 and drives the installer against
# a scratch settings file. No network, no gh, no hardcoded absolute path.
#
# Group A drives the active isolation_mode via the payload `cwd`:
#   - a NON-git scratch dir  -> the body folds to the read-write-only default;
#   - a git-init'd scratch dir carrying pack-ops/session-config.json -> full.
# The single `git init` targets a throwaway scratch dir under $TMPDIR
# (legitimate test infra, NEVER a git verb on the pack repo).
#
# NOTE: set -u only (NOT set -e) so a deliberately-failing sub-command (the
# refuse-on-malformed install) does not abort the harness.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BODY="$REPO_ROOT/scripts/hooks/modes-enforce.py"
INSTALLER="$REPO_ROOT/scripts/install-modes-hook.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

# ── Payload builder: cwd, subagent_type, iso(0/1), tool_name(default Agent). An
# empty subagent_type omits the field (tests the missing-class path).
payload() {
  cwd="$1"; st="$2"; iso="$3"; tn="${4:-Agent}"
  ti=""
  if [ -n "$st" ]; then ti="\"subagent_type\":\"$st\""; fi
  if [ "$iso" = "1" ]; then
    if [ -n "$ti" ]; then ti="$ti,"; fi
    ti="$ti\"isolation\":\"worktree\""
  fi
  printf '{"tool_name":"%s","cwd":"%s","tool_input":{%s}}' "$tn" "$cwd" "$ti"
}

run_body() { # $1 = raw stdin payload
  HOOK_OUT="$(printf '%s' "$1" | python3 "$BODY" 2>/dev/null)"
  HOOK_RC=$?
}

assert_deny() { # $1 = name, $2 = payload
  run_body "$2"
  if [ "$HOOK_RC" -ne 0 ]; then
    fail "$1 (exit $HOOK_RC, expected 0 — body must never exit non-zero)"
  elif printf '%s' "$HOOK_OUT" | grep -q '"permissionDecision":"deny"'; then
    pass "$1"
  else
    fail "$1 (expected deny, got: ${HOOK_OUT:-<empty>})"
  fi
}

assert_allow() { # $1 = name, $2 = payload
  run_body "$2"
  if [ "$HOOK_RC" -ne 0 ]; then
    fail "$1 (exit $HOOK_RC, expected 0 — body must never exit non-zero)"
  elif printf '%s' "$HOOK_OUT" | grep -q '"permissionDecision":"deny"'; then
    fail "$1 (expected allow, got deny)"
  else
    pass "$1"
  fi
}

# ── Scratch dirs controlling the resolved mode. ──
NONGIT="$WORK/nongit"                 # non-git -> folds to read-write-only default
mkdir -p "$NONGIT"

FULLDIR="$WORK/full"                  # git-init'd + isolation_mode=full
mkdir -p "$FULLDIR/pack-ops"
printf '%s\n' '{"schema":"pack-session-config/1","isolation_mode":"full"}' \
  > "$FULLDIR/pack-ops/session-config.json"
( cd "$FULLDIR" && git init -q >/dev/null 2>&1 )

ABSENTCFG="$WORK/absentcfg"           # git root, NO config -> folds to default
mkdir -p "$ABSENTCFG"
( cd "$ABSENTCFG" && git init -q >/dev/null 2>&1 )

MALCFG="$WORK/malcfg"                 # git root, malformed config -> folds to default
mkdir -p "$MALCFG/pack-ops"
printf '%s\n' 'not json {{{' > "$MALCFG/pack-ops/session-config.json"
( cd "$MALCFG" && git init -q >/dev/null 2>&1 )

echo "── Group A: hook-body decision matrix ──"

# read-write-only (via non-git cwd fold): RW must isolate; RO unconstrained.
assert_deny  "read-write-only: RW omit-iso -> DENY"   "$(payload "$NONGIT" pack-coder 0)"
assert_allow "read-write-only: RW with-iso -> allow"  "$(payload "$NONGIT" pack-coder 1)"
assert_allow "read-write-only: RO omit-iso -> allow"  "$(payload "$NONGIT" pack-reviewer 0)"
assert_allow "read-write-only: RO with-iso -> allow"  "$(payload "$NONGIT" pack-reviewer 1)"

# full: BOTH RW and RO must isolate.
assert_deny  "full: RW omit-iso -> DENY"              "$(payload "$FULLDIR" pack-coder 0)"
assert_deny  "full: RO omit-iso -> DENY"              "$(payload "$FULLDIR" pack-planner 0)"
assert_allow "full: RW with-iso -> allow"             "$(payload "$FULLDIR" pack-coder 1)"
assert_allow "full: RO with-iso -> allow"             "$(payload "$FULLDIR" pack-architect 1)"

# tool_name != Agent -> allow regardless.
assert_allow "non-Agent tool (Bash) -> allow"         "$(payload "$FULLDIR" pack-coder 0 Bash)"

# UNKNOWN class -> allow (fail-open), even under full omit-iso.
assert_allow "full: UNKNOWN class omit-iso -> allow"  "$(payload "$FULLDIR" general-purpose 0)"

echo "── Group A: fail-open cases (allow + exit 0, NEVER exit 2) ──"

# Malformed stdin JSON -> allow.
assert_allow "malformed stdin JSON -> allow"          'not json at all {{{'
# Non-git cwd resolution does not crash (folds to default; iso present -> allow).
assert_allow "non-git cwd resolves gracefully"        "$(payload "$NONGIT" general-purpose 0)"
# Git root with ABSENT config folds to default without crashing.
assert_allow "git root, absent config -> graceful"    "$(payload "$ABSENTCFG" pack-coder 1)"
# Git root with MALFORMED config folds to default without crashing.
assert_allow "git root, malformed config -> graceful" "$(payload "$MALCFG" pack-coder 1)"
# Missing tool_input -> unknown class -> allow.
assert_allow "missing tool_input -> allow"            '{"tool_name":"Agent","cwd":"'"$NONGIT"'"}'

echo "── Group B: installer JSON deep-merge / idempotency / uninstall ──"

SCRATCH="$WORK/settings.local.json"
printf '%s\n' '{"permissions":{"allow":["WebFetch(domain:claude.ai)"]}}' > "$SCRATCH"

has_modes() { # -> yes|no : is our PreToolUse[Agent] modes entry present in $1?
  python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
pt = d.get("hooks", {}).get("PreToolUse", [])
found = any(
    isinstance(e, dict) and e.get("matcher") == "Agent"
    and any(str(h.get("command", "")).endswith("scripts/hooks/modes-enforce.py")
            for h in e.get("hooks", []) or [])
    for e in pt
)
print("yes" if found else "no")
PY
}

has_perm() { # -> yes|no : is the seeded permissions.allow entry still present in $1?
  python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
allow = d.get("permissions", {}).get("allow", [])
print("yes" if "WebFetch(domain:claude.ai)" in allow else "no")
PY
}

# install -> deep-merges, preserves permissions.allow (does NOT clobber).
out="$(MODES_HOOK_SETTINGS_FILE="$SCRATCH" bash "$INSTALLER" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'installed'; then
  pass "install prints installed (rc 0)"
else
  fail "install prints installed (rc $rc, out: $out)"
fi
[ "$(has_modes "$SCRATCH")" = "yes" ] && pass "install added the modes entry" \
  || fail "install added the modes entry"
[ "$(has_perm "$SCRATCH")" = "yes" ] && pass "install preserved permissions.allow (merge, not clobber)" \
  || fail "install preserved permissions.allow (merge, not clobber)"

# re-run install -> already current + file byte-unchanged (idempotent).
cp "$SCRATCH" "$WORK/after-install.json"
out="$(MODES_HOOK_SETTINGS_FILE="$SCRATCH" bash "$INSTALLER" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'already current'; then
  pass "re-run install prints already current (rc 0)"
else
  fail "re-run install prints already current (rc $rc, out: $out)"
fi
cmp -s "$SCRATCH" "$WORK/after-install.json" \
  && pass "re-run install left the file byte-unchanged (idempotent)" \
  || fail "re-run install left the file byte-unchanged (idempotent)"

# --status -> installed.
st="$(MODES_HOOK_SETTINGS_FILE="$SCRATCH" bash "$INSTALLER" --status 2>/dev/null)"
[ "$st" = "installed" ] && pass "--status reports installed" \
  || fail "--status reports installed (got: $st)"

# --uninstall -> modes entry gone, permissions intact.
MODES_HOOK_SETTINGS_FILE="$SCRATCH" bash "$INSTALLER" --uninstall >/dev/null 2>&1
[ "$(has_modes "$SCRATCH")" = "no" ] && pass "--uninstall removed the modes entry" \
  || fail "--uninstall removed the modes entry"
[ "$(has_perm "$SCRATCH")" = "yes" ] && pass "--uninstall left permissions.allow intact" \
  || fail "--uninstall left permissions.allow intact"

# re-run --uninstall -> no-op (not-installed).
out="$(MODES_HOOK_SETTINGS_FILE="$SCRATCH" bash "$INSTALLER" --uninstall 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'not-installed'; then
  pass "re-run --uninstall is a no-op (not-installed)"
else
  fail "re-run --uninstall is a no-op (rc $rc, out: $out)"
fi

# --status on a malformed settings file -> not-installed, exit 0.
MAL="$WORK/mal-settings.json"
printf '%s\n' 'not json {{{' > "$MAL"
st="$(MODES_HOOK_SETTINGS_FILE="$MAL" bash "$INSTALLER" --status 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$st" = "not-installed" ]; then
  pass "--status on malformed settings -> not-installed (rc 0)"
else
  fail "--status on malformed settings -> not-installed (rc $rc, got: $st)"
fi

# install on a malformed settings file -> non-zero exit AND file byte-unchanged.
cp "$MAL" "$WORK/mal-before.json"
MODES_HOOK_SETTINGS_FILE="$MAL" bash "$INSTALLER" >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "install on malformed settings refuses (non-zero exit)"
else
  fail "install on malformed settings refuses (got rc 0)"
fi
cmp -s "$MAL" "$WORK/mal-before.json" \
  && pass "install on malformed settings left the file byte-unchanged (no discard)" \
  || fail "install on malformed settings left the file byte-unchanged (no discard)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
