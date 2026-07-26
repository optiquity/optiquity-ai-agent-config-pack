#!/usr/bin/env bash
# test-pm-modes-commit-gate.sh — CLIENT intervention_mode commit-gate canary.
#
# The pack copy (scripts/hooks/modes-commit-gate.py) is exercised by
# test-modes-commit-gate.sh; the SHIPPED CLIENT copy
# (project-template/scripts/pm-modes-commit-gate.py) had no dedicated behavioral
# test. This proportionate canary drives the CLIENT gate body and PROVES:
#   - the decision matrix + fail-open discipline (body ALWAYS exit 0, NEVER
#     exit 2) + the token lifecycle, driven through the MODES_GATE_* seams; and
#   - the CLIENT-SPECIFIC derive paths (NO seam): the config path
#     docs/project/pm-session-config.json and the token path
#     docs/project/.pm-commit-approval-token (the pack copy uses
#     pack-ops/session-config.json + pack-ops/.commit-approval-token).
# It BITES: the derive-path cases resolve `full` + the absent/fresh token ONLY if
# the gate reads the CLIENT paths; a wrong path folds to allow-inert and the
# DENY flips (verified by negative perturbation).
#
# Modeled on test-modes-commit-gate.sh. CI-wired simply by existing on disk (the
# disk-glob CI matrix). Offline + deterministic: it only pipes JSON to python3
# and reads/writes scratch files under a mktemp dir. No network, no gh, no
# hardcoded absolute dev/home path.
#
# Seams (mirror the pack gate): MODES_GATE_CONFIG_FILE / MODES_GATE_TOKEN_FILE /
# MODES_GATE_NOW. The derive-path group leaves the CONFIG/TOKEN seams UNSET so the
# body derives both from `git -C <cwd> rev-parse --show-toplevel` — that is what
# exercises the CLIENT path constants.
#
# NOTE: set -u only (NOT set -e) so a body that emits a deny (still exit 0) does
# not abort the harness. The single `git init` targets a throwaway scratch dir
# under $TMPDIR (legitimate test infra, NEVER a git verb on the pack repo).
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BODY="$REPO_ROOT/project-template/scripts/pm-modes-commit-gate.py"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

NOW=1000000000            # fixed clock for deterministic freshness checks
FRESH=$((NOW - 10))       # within the 120s TTL
STALE=$((NOW - 999))      # well past the 120s TTL

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

# ── Payload builder: JSON-safe via python (escapes embedded quotes/specials).
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
  printf '{"schema":"pm-session-config/1","intervention_mode":"%s"}\n' "$1" > "$2"
}
write_token() { # $1 = approved_at epoch, $2 = path
  printf '{"approved_at": %s}\n' "$1" > "$2"
}

# ── Scratch config files (seam-driven group). ──
CFG_FULL="$WORK/cfg-full.json";         write_cfg full      "$CFG_FULL"
CFG_NONE="$WORK/cfg-none.json";         write_cfg none      "$CFG_NONE"
CFG_PRECODER="$WORK/cfg-precoder.json"; write_cfg pre-coder "$CFG_PRECODER"
CFG_AMB="$WORK/cfg-amb.json";           write_cfg ambiguity "$CFG_AMB"
CFG_UNKNOWN="$WORK/cfg-unknown.json";   write_cfg weird     "$CFG_UNKNOWN"
CFG_MAL="$WORK/cfg-mal.json";           printf 'not json {{{\n' > "$CFG_MAL"
CFG_ABSENT="$WORK/cfg-absent.json"      # deliberately never created

TOKEN="$WORK/token.json"                # created/removed per test
CWD="$WORK"                             # a real dir (config driven by seam)

COMMIT='git commit -m "msg"'            # the canonical commit command

# The seams must be present WHEN THE BODY RUNS (run_gate). These helpers bind
# {cfg, token, NOW} for the body invocation.
gate_env_deny() { # $1 name, $2 cfg, $3 token, $4 cmd
  MODES_GATE_CONFIG_FILE="$2" MODES_GATE_TOKEN_FILE="$3" MODES_GATE_NOW="$NOW" \
    assert_deny "$1" "$(payload Bash "$CWD" "$4")"
}
gate_env_allow() { # $1 name, $2 cfg, $3 token, $4 cmd, [$5 tool_name]
  MODES_GATE_CONFIG_FILE="$2" MODES_GATE_TOKEN_FILE="$3" MODES_GATE_NOW="$NOW" \
    assert_allow "$1" "$(payload "${5:-Bash}" "$CWD" "$4")"
}

echo "── Group A: decision matrix (enforce modes require a fresh token) ──"

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
# A commit VARIANT (global option) still denies under full + no token.
gate_env_deny "full: 'git -C /w commit' -> DENY" "$CFG_FULL" "$TOKEN" 'git -C /w commit -m z'

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

echo "── Group C: CLIENT derive paths (NO seam — proves the client path constants) ──"

# A git-init'd scratch root carrying the CLIENT config path. With NO CONFIG/TOKEN
# seam, the body derives BOTH from `git rev-parse --show-toplevel`:
#   config -> <root>/docs/project/pm-session-config.json
#   token  -> <root>/docs/project/.pm-commit-approval-token
DERIVE="$WORK/derive"
mkdir -p "$DERIVE/docs/project"
write_cfg full "$DERIVE/docs/project/pm-session-config.json"
( cd "$DERIVE" && git init -q >/dev/null 2>&1 )
DTOKEN="$DERIVE/docs/project/.pm-commit-approval-token"

# full config at the CLIENT path + absent token at the CLIENT token path -> DENY.
# This can only DENY if the body read intervention_mode=full from
# docs/project/pm-session-config.json AND derived the absent token at
# docs/project/.pm-commit-approval-token. A wrong config path -> allow-inert.
rm -f "$DTOKEN"
run_gate "$(payload Bash "$DERIVE" "$COMMIT")"
if [ "$GATE_RC" -eq 0 ] && printf '%s' "$GATE_OUT" | grep -q '"permissionDecision":"deny"'; then
  pass "derive: full at docs/project/pm-session-config.json + absent token -> DENY (client config+token path)"
else
  fail "derive: full config + absent token -> DENY (rc $GATE_RC, out: ${GATE_OUT:-<empty>})"
fi

# fresh token at the CLIENT token path -> ALLOW + consume (proves the token path).
write_token "$FRESH" "$DTOKEN"
MODES_GATE_NOW="$NOW" run_gate "$(payload Bash "$DERIVE" "$COMMIT")"
if [ "$GATE_RC" -eq 0 ] && ! printf '%s' "$GATE_OUT" | grep -q '"permissionDecision":"deny"'; then
  pass "derive: fresh token at docs/project/.pm-commit-approval-token -> allow (client token path)"
else
  fail "derive: fresh client token -> allow (rc $GATE_RC, out: ${GATE_OUT:-<empty>})"
fi
[ ! -f "$DTOKEN" ] && pass "derive: fresh-token allow CONSUMES the client token (single-use)" \
  || fail "derive: fresh-token allow CONSUMES the client token (single-use)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
