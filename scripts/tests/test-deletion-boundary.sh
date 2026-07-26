#!/usr/bin/env bash
# test-deletion-boundary.sh — unit test for the sub-agent deletion-boundary hook
# body (scripts/hooks/deletion-boundary.py).
#
# Exercises the §4.5 decision matrix + the fail-open discipline (the body must
# ALWAYS exit 0, NEVER exit 2), driving a synthetic owned-dirs registry + a
# controlled OS-temp-root allowlist through the test seams:
#   DELBOUND_REGISTRY_FILE — the owned-dirs registry path (a scratch JSONL).
#   DELBOUND_TEMP_ROOTS    — the temp-root allowlist (colon-separated), pinned to
#                            a synthetic dir so the mktemp WORK's real /var/folders
#                            (or /tmp) parent does NOT accidentally make an
#                            out-of-owned target look temp-allowed.
#
# CI-wired simply by existing on disk (the disk-glob CI matrix). Offline +
# deterministic: it only pipes JSON to python3 and reads scratch files under a
# mktemp dir. No network, no gh, no hardcoded absolute dev/home path. It
# self-provisions + cleans up its own fixtures (all under $WORK).
#
# NOTE: set -u only (NOT set -e) so a body that emits a deny (still exit 0) does
# not abort the harness.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BODY="$REPO_ROOT/scripts/hooks/deletion-boundary.py"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

# ── Synthetic ownership world (all under $WORK; never a real path). ──
ROOT="$WORK/handoff"          # the shared per-machine handoff root
OWN="$ROOT/bd273-own"         # THIS agent's owned scratch dir
SIB="$ROOT/bd257-foo"         # a sibling agent's dir (the incident target class)
TEMPROOTS="$WORK/temp"        # the pinned OS-temp-root allowlist value
REPO="$WORK/repo"             # a stand-in worktree cwd (out-of-owned)
mkdir -p "$OWN/scratch" "$SIB" "$TEMPROOTS" "$REPO"

REG="$WORK/owned.jsonl"       # the owned-dirs registry: agent A -> $OWN
printf '{"agent_id":"A","owned_dir":"%s"}\n' "$OWN" > "$REG"

# ── Payload builder (JSON-safe via python). An empty agent_id / cwd OMITS the
# field (exercises the main-thread / cwd-absent paths). ──
payload() { # $1=tool_name $2=agent_id(empty=omit) $3=cwd(empty=omit) $4=command
  MP_TN="$1" MP_AID="$2" MP_CWD="$3" MP_CMD="$4" python3 -c '
import json, os
d = {"tool_name": os.environ["MP_TN"], "tool_input": {"command": os.environ["MP_CMD"]}}
aid = os.environ.get("MP_AID", "")
if aid:
    d["agent_id"] = aid
cwd = os.environ.get("MP_CWD", "")
if cwd:
    d["cwd"] = cwd
print(json.dumps(d))'
}

# Run the body with the STANDARD seams (registry $REG + temp roots $TEMPROOTS).
run_std() { # $1 = raw stdin payload
  OUT="$(printf '%s' "$1" | DELBOUND_REGISTRY_FILE="$REG" DELBOUND_TEMP_ROOTS="$TEMPROOTS" \
         python3 "$BODY" 2>/dev/null)"; RC=$?
}
# Run the body with an EXPLICIT registry override (for the registry-absent case).
run_reg() { # $1 = payload, $2 = registry-file
  OUT="$(printf '%s' "$1" | DELBOUND_REGISTRY_FILE="$2" DELBOUND_TEMP_ROOTS="$TEMPROOTS" \
         python3 "$BODY" 2>/dev/null)"; RC=$?
}

verdict() { # $1 = want(deny|allow), $2 = name  (reads OUT / RC)
  if [ "$RC" -ne 0 ]; then
    fail "$2 (exit $RC, expected 0 — body must never exit non-zero)"
    return
  fi
  if printf '%s' "$OUT" | grep -q '"permissionDecision":"deny"'; then got=deny; else got=allow; fi
  if [ "$got" = "$1" ]; then
    pass "$2"
  else
    fail "$2 (expected $1, got $got: ${OUT:-<empty>})"
  fi
}
assert_deny()  { run_std "$2"; verdict deny  "$1"; }
assert_allow() { run_std "$2"; verdict allow "$1"; }

echo "── Group A: deny the out-of-owned incident class (§4.5) ──"

# The incident payload: a subagent sweeping a sibling dir under the shared root.
assert_deny "incident: rm -rf <root>/bd257-* (out-of-owned)" \
  "$(payload Bash A "$REPO" "rm -rf $ROOT/bd257-*")"
# Env-assignment prefix must not hide the verb (MUST-1).
assert_deny "env-prefix: TMPDIR=/x rm -rf <root>/bd257-*" \
  "$(payload Bash A "$REPO" "TMPDIR=/x rm -rf $ROOT/bd257-*")"
# command / builtin / backslash prefix stripping (MUST-1).
assert_deny "prefix: command rm -rf <root>/bd257-*" \
  "$(payload Bash A "$REPO" "command rm -rf $ROOT/bd257-*")"
assert_deny "prefix: \\rm -rf <root>/bd257-*" \
  "$(payload Bash A "$REPO" "\\rm -rf $ROOT/bd257-*")"
# mv source-removal (MUST-1) — source out-of-owned, dest in temp.
assert_deny "mv source-removal: mv <root>/bd257-foo <temp>/trash" \
  "$(payload Bash A "$REPO" "mv $ROOT/bd257-foo $TEMPROOTS/trash")"
# find … -delete out-of-owned.
assert_deny "find <root>/bd257-foo -delete (out-of-owned)" \
  "$(payload Bash A "$REPO" "find $ROOT/bd257-foo -delete")"
# find … | xargs rm (MUST-1) — find-root out-of-owned.
assert_deny "find <root> -name 'bd257*' | xargs rm -rf" \
  "$(payload Bash A "$REPO" "find $ROOT/ -name 'bd257*' | xargs rm -rf")"
# one bash -c peek.
assert_deny "bash -c 'rm -rf <root>/bd257-*' (one -c peek)" \
  "$(payload Bash A "$REPO" "bash -c 'rm -rf $ROOT/bd257-*'")"
# git rm (also git-banned) — relative target resolves against the out-of-owned cwd.
assert_deny "git rm superseded.md (relative -> out-of-owned cwd)" \
  "$(payload Bash A "$REPO" "git rm superseded.md")"
# `..` normalize: a path that starts under the temp root but escapes it (SHOULD-2).
assert_deny "rm -rf <temp>/../handoff/bd257-x (escapes temp after normpath)" \
  "$(payload Bash A "$REPO" "rm -rf $TEMPROOTS/../handoff/bd257-x")"

echo "── Group B: allow in-owned + in-temp + unresolvable (fail-open) ──"

# Under the owned dir -> allow (in-dir scratch cleanup).
assert_allow "rm -rf <owned>/scratch/tmp123 (under owned)" \
  "$(payload Bash A "$REPO" "rm -rf $OWN/scratch/tmp123")"
# The owned dir's own report file -> allow (in-dir cleanup, SHOULD-1 rule-only).
assert_allow "rm -f <owned>/IMPL-REPORT.md (in-dir cleanup)" \
  "$(payload Bash A "$REPO" "rm -f $OWN/IMPL-REPORT.md")"
# Under a temp root -> allow (mktemp cleanup).
assert_allow "rm -rf <temp>/test.AAA (OS temp root)" \
  "$(payload Bash A "$REPO" "rm -rf $TEMPROOTS/test.AAA")"
# find under owned WITH -delete -> allow.
assert_allow "find <owned> -name '*.tmp' -delete (under owned)" \
  "$(payload Bash A "$REPO" "find $OWN -name '*.tmp' -delete")"
# Unresolvable variable target -> allow (the directly-typed harness idiom).
assert_allow 'rm -rf "$WORK" (unresolvable variable)' \
  "$(payload Bash A "$REPO" 'rm -rf "$WORK"')"
assert_allow 'rmdir "$LOCK" 2>/dev/null (variable + redirect)' \
  "$(payload Bash A "$REPO" 'rmdir "$LOCK" 2>/dev/null')"
# Quoted text that merely CONTAINS a delete verb -> allow (not a command).
assert_allow 'echo "rm -rf /" (quoted text, not a command)' \
  "$(payload Bash A "$REPO" 'echo "rm -rf /"')"
# A non-delete top-level command whose nested rm is invisible -> allow.
assert_allow "bash scripts/tests/test-modes-enforce.sh (nested rm unseen)" \
  "$(payload Bash A "$REPO" "bash scripts/tests/test-modes-enforce.sh")"

echo "── Group C: gating + registry fail-open branches ──"

# Main thread (no agent_id) -> allow even for an out-of-owned rm (orchestrator).
assert_allow "main-thread (no agent_id): rm -rf <root>/bd257-* -> allow" \
  "$(payload Bash "" "$REPO" "rm -rf $ROOT/bd257-*")"
# Registry MISS (unknown agent_id) -> fail-open allow.
assert_allow "registry miss (agent Z): rm -rf <root>/bd257-* -> allow" \
  "$(payload Bash Z "$REPO" "rm -rf $ROOT/bd257-*")"
# Registry ABSENT -> fail-open allow.
run_reg "$(payload Bash A "$REPO" "rm -rf $ROOT/bd257-*")" "$WORK/does-not-exist.jsonl"
verdict allow "registry absent -> allow (fail-open)"
# cwd ABSENT for a relative target -> fail-open allow (SHOULD-2).
assert_allow "cwd absent + relative target (git rm foo) -> allow" \
  "$(payload Bash A "" "git rm foo")"
# Non-Bash tool -> allow regardless (belt-and-suspenders).
assert_allow "non-Bash tool (Agent) -> allow" \
  "$(payload Agent A "$REPO" "rm -rf $ROOT/bd257-*")"

echo "── Group D: the body NEVER exits non-zero on ANY payload ──"

# Malformed stdin JSON -> allow + exit 0.
run_std 'not json at all {{{'
verdict allow "malformed stdin JSON -> allow (exit 0)"
# Empty stdin -> allow + exit 0.
run_std ''
verdict allow "empty stdin -> allow (exit 0)"
# Missing tool_input entirely -> empty command -> allow.
run_std "$(printf '{"tool_name":"Bash","agent_id":"A","cwd":"%s"}' "$REPO")"
verdict allow "missing tool_input -> allow"
# A deliberately weird payload (agent_id present, command a bare bracket) -> allow, exit 0.
run_std "$(payload Bash A "$REPO" '[')"
verdict allow "weird command ('[') -> allow (exit 0, no crash)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
