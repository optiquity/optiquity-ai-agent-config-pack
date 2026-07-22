#!/usr/bin/env bash
# test-modes-commit-gate.sh — unit test for the intervention_mode commit-gate
# hook body (scripts/hooks/modes-commit-gate.py).
#
# Exercises the decision matrix + fail-open discipline (the body must ALWAYS
# exit 0, NEVER exit 2) + the token lifecycle (fresh->consume, stale->deny,
# single-use deletion) + the git-commit-only matcher, driving scratch
# config/token through the MODES_GATE_* test seams:
#   MODES_GATE_CONFIG_FILE — the session-config path (else derived from cwd).
#   MODES_GATE_TOKEN_FILE  — the approval-token path (else derived from cwd).
#   MODES_GATE_NOW         — a fixed "now" (epoch) for deterministic TTL tests.
#
# CI-wired simply by existing on disk (the disk-glob CI matrix). Offline +
# deterministic: it only pipes JSON to python3 and reads/writes scratch files
# under a mktemp dir. No network, no gh, no hardcoded absolute dev/home path.
#
# NOTE: set -u only (NOT set -e) so a body that emits a deny (still exit 0) or a
# deliberately-odd payload does not abort the harness.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BODY="$REPO_ROOT/scripts/hooks/modes-commit-gate.py"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

NOW=1000000000            # fixed clock for deterministic freshness checks
FRESH=$((NOW - 10))       # within the 120s TTL
STALE=$((NOW - 999))      # well past the 120s TTL

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

# ── Payload builder: JSON-safe via python (escapes embedded quotes/specials). An
# empty command ("") omits nothing — it exercises the not-a-commit path.
payload() { # $1 = tool_name, $2 = cwd, $3 = command
  MP_TN="$1" MP_CWD="$2" MP_CMD="$3" python3 -c '
import json, os
print(json.dumps({
    "tool_name": os.environ["MP_TN"],
    "cwd": os.environ["MP_CWD"],
    "tool_input": {"command": os.environ["MP_CMD"]},
}))'
}

run_gate() { # $1 = raw stdin payload  (env seams set by the caller prefix)
  GATE_OUT="$(printf '%s' "$1" | python3 "$BODY" 2>/dev/null)"
  GATE_RC=$?
}

assert_deny() { # $1 = name, $2 = payload
  run_gate "$2"
  if [ "$GATE_RC" -ne 0 ]; then
    fail "$1 (exit $GATE_RC, expected 0 — body must never exit non-zero)"
  elif printf '%s' "$GATE_OUT" | grep -q '"permissionDecision":"deny"'; then
    pass "$1"
  else
    fail "$1 (expected deny, got: ${GATE_OUT:-<empty>})"
  fi
}

assert_allow() { # $1 = name, $2 = payload
  run_gate "$2"
  if [ "$GATE_RC" -ne 0 ]; then
    fail "$1 (exit $GATE_RC, expected 0 — body must never exit non-zero)"
  elif printf '%s' "$GATE_OUT" | grep -q '"permissionDecision":"deny"'; then
    fail "$1 (expected allow, got deny)"
  else
    pass "$1"
  fi
}

write_cfg() { # $1 = intervention_mode value, $2 = path
  printf '{"schema":"pack-session-config/1","intervention_mode":"%s"}\n' "$1" > "$2"
}
write_token() { # $1 = approved_at epoch, $2 = path
  printf '{"approved_at": %s}\n' "$1" > "$2"
}

# ── Scratch config files (one per intervention_mode + malformed). ──
CFG_FULL="$WORK/cfg-full.json";         write_cfg full      "$CFG_FULL"
CFG_NONE="$WORK/cfg-none.json";         write_cfg none      "$CFG_NONE"
CFG_PRECODER="$WORK/cfg-precoder.json"; write_cfg pre-coder "$CFG_PRECODER"
CFG_AMB="$WORK/cfg-amb.json";           write_cfg ambiguity "$CFG_AMB"
CFG_UNKNOWN="$WORK/cfg-unknown.json";   write_cfg weird     "$CFG_UNKNOWN"
CFG_MAL="$WORK/cfg-mal.json";           printf 'not json {{{\n' > "$CFG_MAL"
CFG_ABSENT="$WORK/cfg-absent.json"      # deliberately never created

TOKEN="$WORK/token.json"                # created/removed per test
CWD="$WORK"                             # a real dir (config driven by seam)
NONGIT="$WORK/nongit"; mkdir -p "$NONGIT"  # for the derive-path fail-open case

COMMIT='git commit -m "msg"'            # the canonical commit command

echo "── Group A: decision matrix (enforce modes require a fresh token) ──"

# The seams must be present WHEN THE BODY RUNS (run_gate), not when the payload
# is built — so the seam prefix goes on the assert_* call, which invokes the
# body. These two helpers bind {cfg, token, NOW} for the body invocation.
gate_env_deny() { # $1 name, $2 cfg, $3 token, $4 cmd
  MODES_GATE_CONFIG_FILE="$2" MODES_GATE_TOKEN_FILE="$3" MODES_GATE_NOW="$NOW" \
    assert_deny "$1" "$(payload Bash "$CWD" "$4")"
}
gate_env_allow() { # $1 name, $2 cfg, $3 token, $4 cmd, [$5 tool_name]
  MODES_GATE_CONFIG_FILE="$2" MODES_GATE_TOKEN_FILE="$3" MODES_GATE_NOW="$NOW" \
    assert_allow "$1" "$(payload "${5:-Bash}" "$CWD" "$4")"
}

# full + ABSENT token -> DENY.
rm -f "$TOKEN"
gate_env_deny "full: git commit, absent token -> DENY" "$CFG_FULL" "$TOKEN" "$COMMIT"

# full + FRESH token -> ALLOW, and the token is CONSUMED (single-use).
write_token "$FRESH" "$TOKEN"
gate_env_allow "full: git commit, fresh token -> allow" "$CFG_FULL" "$TOKEN" "$COMMIT"
[ ! -f "$TOKEN" ] && pass "fresh-token allow CONSUMES the token (deleted)" \
  || fail "fresh-token allow CONSUMES the token (deleted)"

# full + STALE token -> DENY, and the token is NOT consumed.
write_token "$STALE" "$TOKEN"
gate_env_deny "full: git commit, stale token -> DENY (TTL expiry)" "$CFG_FULL" "$TOKEN" "$COMMIT"
[ -f "$TOKEN" ] && pass "stale-token deny leaves the token in place (not consumed)" \
  || fail "stale-token deny leaves the token in place (not consumed)"

# intervention=none -> ALLOW even with no token.
rm -f "$TOKEN"
gate_env_allow "none: git commit, no token -> allow" "$CFG_NONE" "$TOKEN" "$COMMIT"

# pre-coder + FRESH token -> ALLOW + consume.
write_token "$FRESH" "$TOKEN"
gate_env_allow "pre-coder: git commit, fresh token -> allow" "$CFG_PRECODER" "$TOKEN" "$COMMIT"
[ ! -f "$TOKEN" ] && pass "pre-coder fresh-token allow consumes the token" \
  || fail "pre-coder fresh-token allow consumes the token"

# ambiguity + no token -> DENY.
rm -f "$TOKEN"
gate_env_deny "ambiguity: git commit, no token -> DENY" "$CFG_AMB" "$TOKEN" "$COMMIT"

# unknown intervention value -> ALLOW (inert).
gate_env_allow "unknown mode value: git commit -> allow (inert)" "$CFG_UNKNOWN" "$TOKEN" "$COMMIT"

echo "── Group A: matcher scoping (only a real git commit is gated) ──"

# non-Bash tool -> ALLOW regardless (belt-and-suspenders; matcher already scopes).
rm -f "$TOKEN"
gate_env_allow "non-Bash tool (Agent) -> allow" "$CFG_FULL" "$TOKEN" "$COMMIT" Agent

# Bash but NOT a git commit -> ALLOW under full + no token.
gate_env_allow "full: 'git status' (not commit) -> allow" "$CFG_FULL" "$TOKEN" "git status"
gate_env_allow "full: 'ls -la' (not git) -> allow" "$CFG_FULL" "$TOKEN" "ls -la"

# 'git commit' as inner text of a quoted string -> ALLOW (not a real invocation).
gate_env_allow "full: echo \"git commit\" (quoted text) -> allow" "$CFG_FULL" "$TOKEN" 'echo "git commit here"'

# M-1 regression: a shell control operator (&&, ;, |) that appears LITERALLY
# inside a quoted argument must NOT expose a spurious `git commit` segment. These
# are NON-commits (git log/grep) whose quoted string merely contains an operator
# plus `git commit` text -> ALLOW (the splitter is quote-aware; a wrong deny here
# would violate the "ambiguous parse -> allow" fail-open direction).
gate_env_allow "M-1: git log --grep=\"&& git commit &&\" -> allow" "$CFG_FULL" "$TOKEN" 'git log --grep="&& git commit &&"'
gate_env_allow "M-1: git log --grep='; git commit' -> allow"        "$CFG_FULL" "$TOKEN" "git log --grep='; git commit'"
gate_env_allow "M-1: git log --grep=\"| git commit\" -> allow"      "$CFG_FULL" "$TOKEN" 'git log --grep="| git commit"'
# Guard against over-correction: a REAL chain AFTER a closing quote still denies.
gate_env_deny "M-1: git log --author=\"x\" && git commit -> DENY"   "$CFG_FULL" "$TOKEN" 'git log --author="x" && git commit -m z'

# Commit VARIANTS (global options, chaining, path args) -> DENY under full+no-token.
gate_env_deny "full: 'git -C /work/x commit' -> DENY"       "$CFG_FULL" "$TOKEN" 'git -C /work/x commit -m z'
gate_env_deny "full: 'cd /work/x && git commit' -> DENY"    "$CFG_FULL" "$TOKEN" 'cd /work/x && git commit -m z'
gate_env_deny "full: 'git -c user.email=a@b commit' -> DENY" "$CFG_FULL" "$TOKEN" 'git -c user.email=a@b commit -m z'
gate_env_deny "full: 'git commit --amend' -> DENY"          "$CFG_FULL" "$TOKEN" 'git commit --amend --no-edit'

echo "── Group B: fail-open (allow + exit 0, NEVER exit 2) ──"

# Malformed stdin JSON -> ALLOW.
assert_allow "malformed stdin JSON -> allow" 'not json at all {{{'

# Config ABSENT -> ALLOW (inert; a fresh clone with no modes config).
rm -f "$TOKEN"
gate_env_allow "config absent -> allow (inert)" "$CFG_ABSENT" "$TOKEN" "$COMMIT"

# Config MALFORMED -> ALLOW (inert).
gate_env_allow "config malformed -> allow (inert)" "$CFG_MAL" "$TOKEN" "$COMMIT"

# Token MALFORMED (garbage) under full -> ALLOW (fail-open: token-parse error).
printf 'not json {{{\n' > "$TOKEN"
gate_env_allow "malformed token -> allow (fail-open parse error)" "$CFG_FULL" "$TOKEN" "$COMMIT"

# Token present but no approved_at field -> ALLOW (fail-open: non-numeric).
printf '{}\n' > "$TOKEN"
gate_env_allow "token missing approved_at -> allow (fail-open)" "$CFG_FULL" "$TOKEN" "$COMMIT"

# Derive-path: NON-git cwd, NO config seam -> toplevel empty -> inert -> ALLOW.
run_gate "$(payload Bash "$NONGIT" "$COMMIT")"
if [ "$GATE_RC" -eq 0 ] && ! printf '%s' "$GATE_OUT" | grep -q '"permissionDecision":"deny"'; then
  pass "non-git cwd (derive path) -> allow (inert)"
else
  fail "non-git cwd (derive path) -> allow (rc $GATE_RC, out: ${GATE_OUT:-<empty>})"
fi

# Missing tool_input entirely -> empty command -> not a commit -> ALLOW.
assert_allow "missing tool_input -> allow" '{"tool_name":"Bash","cwd":"'"$CWD"'"}'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
