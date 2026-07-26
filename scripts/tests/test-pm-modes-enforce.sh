#!/usr/bin/env bash
# test-pm-modes-enforce.sh — CLIENT isolation_mode enforcement hook canary.
#
# The pack copy (scripts/hooks/modes-enforce.py) is exercised by
# test-modes-enforce.sh, but the SHIPPED CLIENT copy
# (project-template/scripts/pm-modes-enforce.py) had NO dedicated behavioral
# test — its CLIENT-SPECIFIC surface was un-regression-guarded:
#   - the client agent-class map: _RW_CLASSES = {coder, repo-ops} (un-prefixed;
#     the pack copy uses {pack-coder}), and the exact 14-member _RO_CLASSES
#     (architect, planner, reviewer, tester, docs-researcher, grpc-schema, and
#     the base `auditor` + the seven `auditor-*` cluster members);
#   - the client config path docs/project/pm-session-config.json (the pack copy
#     reads pack-ops/session-config.json).
# This canary drives the CLIENT hook body and PROVES that client-specific matrix.
# It BITES: it PASSES against the correct client hook and FAILS if the client
# class map or the client config path is broken (verified by negative
# perturbation).
#
# Modeled on test-modes-enforce.sh (Group A: the hook-body decision matrix +
# fail-open cases — the body must ALWAYS exit 0, NEVER exit 2). There is no
# client installer to test (the client wires the hook via .claude/settings.json
# directly), so there is no installer group.
#
# CI-wired simply by existing on disk (the disk-glob CI matrix). Offline +
# deterministic: it only pipes JSON to python3 and drives scratch git roots. No
# network, no gh, no hardcoded absolute path.
#
# The client hook has NO config-path test seam; it derives the config path from
# `git -C <cwd> rev-parse --show-toplevel` + docs/project/pm-session-config.json.
# So the active mode is driven by the payload `cwd`:
#   - a NON-git scratch dir  -> the body folds to the read-write-only default;
#   - a git-init'd scratch dir carrying docs/project/pm-session-config.json with
#     {isolation_mode:"full"} -> full.
# Each `git init` targets a throwaway scratch dir under $TMPDIR (legitimate test
# infra, NEVER a git verb on the pack repo).
#
# NOTE: set -u only (NOT set -e) so a case whose body prints a deny (still exit
# 0) does not abort the harness.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BODY="$REPO_ROOT/project-template/scripts/pm-modes-enforce.py"

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

# ── Scratch dirs controlling the resolved mode (CLIENT config path). ──
NONGIT="$WORK/nongit"                 # non-git -> folds to read-write-only default
mkdir -p "$NONGIT"

FULLDIR="$WORK/full"                  # git-init'd + isolation_mode=full at CLIENT path
mkdir -p "$FULLDIR/docs/project"
printf '%s\n' '{"schema":"pm-session-config/1","isolation_mode":"full"}' \
  > "$FULLDIR/docs/project/pm-session-config.json"
( cd "$FULLDIR" && git init -q >/dev/null 2>&1 )

ABSENTCFG="$WORK/absentcfg"           # git root, NO config -> folds to default
mkdir -p "$ABSENTCFG"
( cd "$ABSENTCFG" && git init -q >/dev/null 2>&1 )

MALCFG="$WORK/malcfg"                 # git root, malformed config -> folds to default
mkdir -p "$MALCFG/docs/project"
printf '%s\n' 'not json {{{' > "$MALCFG/docs/project/pm-session-config.json"
( cd "$MALCFG" && git init -q >/dev/null 2>&1 )

echo "── Group A: CLIENT hook-body decision matrix ──"

# read-write-only (via non-git cwd fold): the CLIENT RW classes {coder, repo-ops}
# must isolate; RO unconstrained. `coder`/`repo-ops` are UN-PREFIXED — proving the
# client map, not the pack {pack-coder} map.
assert_deny  "rw-only: RW coder omit-iso -> DENY"        "$(payload "$NONGIT" coder 0)"
assert_deny  "rw-only: RW repo-ops omit-iso -> DENY"     "$(payload "$NONGIT" repo-ops 0)"
assert_allow "rw-only: RW coder with-iso -> allow"       "$(payload "$NONGIT" coder 1)"
assert_allow "rw-only: RW repo-ops with-iso -> allow"    "$(payload "$NONGIT" repo-ops 1)"
assert_allow "rw-only: RO reviewer omit-iso -> allow"    "$(payload "$NONGIT" reviewer 0)"
assert_allow "rw-only: RO auditor omit-iso -> allow"     "$(payload "$NONGIT" auditor 0)"

# full (config at the CLIENT path): BOTH RW and RO must isolate. Every DENY here
# is ALSO a config-path canary — it can only resolve to `full` if the hook read
# docs/project/pm-session-config.json; a wrong path folds to rw-only and RO would
# ALLOW.
assert_deny  "full: RW coder omit-iso -> DENY"           "$(payload "$FULLDIR" coder 0)"
assert_deny  "full: RW repo-ops omit-iso -> DENY"        "$(payload "$FULLDIR" repo-ops 0)"
assert_deny  "full: RO auditor omit-iso -> DENY"         "$(payload "$FULLDIR" auditor 0)"
assert_deny  "full: RO auditor-security omit-iso -> DENY" "$(payload "$FULLDIR" auditor-security 0)"
assert_deny  "full: RO architect omit-iso -> DENY"       "$(payload "$FULLDIR" architect 0)"
assert_allow "full: RW coder with-iso -> allow"          "$(payload "$FULLDIR" coder 1)"
assert_allow "full: RO auditor with-iso -> allow"        "$(payload "$FULLDIR" auditor 1)"

# tool_name != Agent -> allow regardless.
assert_allow "non-Agent tool (Bash) -> allow"            "$(payload "$FULLDIR" coder 0 Bash)"

# UNKNOWN class -> allow (fail-open), even under full omit-iso.
assert_allow "full: UNKNOWN class omit-iso -> allow"     "$(payload "$FULLDIR" general-purpose 0)"
# The PACK agent name is UNKNOWN client-side (the client map is un-prefixed) ->
# allow. A copy-paste of the pack {pack-coder} map would DENY here.
assert_allow "full: pack-coder (pack name) UNKNOWN client-side -> allow" "$(payload "$FULLDIR" pack-coder 0)"

echo "── Group A: fail-open cases (allow + exit 0, NEVER exit 2) ──"

# Malformed stdin JSON -> allow.
assert_allow "malformed stdin JSON -> allow"             'not json at all {{{'
# Non-git cwd resolution does not crash (folds to default; iso present -> allow).
assert_allow "non-git cwd resolves gracefully"           "$(payload "$NONGIT" general-purpose 0)"
# Git root with ABSENT config folds to the rw-only default: RW omit-iso DENIES
# (proving the absent-config -> default-fold direction), RO omit-iso allows.
assert_deny  "git root, absent config: RW omit-iso -> DENY (default-fold)" "$(payload "$ABSENTCFG" coder 0)"
assert_allow "git root, absent config: RO omit-iso -> allow"              "$(payload "$ABSENTCFG" reviewer 0)"
assert_allow "git root, absent config: RW with-iso -> allow"              "$(payload "$ABSENTCFG" coder 1)"
# Git root with MALFORMED config folds to default without crashing (RW denies).
assert_deny  "git root, malformed config: RW omit-iso -> DENY (default-fold)" "$(payload "$MALCFG" coder 0)"
# Missing tool_input -> unknown class -> allow.
assert_allow "missing tool_input -> allow"               '{"tool_name":"Agent","cwd":"'"$NONGIT"'"}'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
