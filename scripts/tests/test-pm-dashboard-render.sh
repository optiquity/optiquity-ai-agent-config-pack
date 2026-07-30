#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-pm-dashboard-render.sh - behavior + complete-floor test for
# the CLIENT project-frontier dashboard renderer
# (project-template/scripts/pm-dashboard-render.py).
#
# The client engine is the project-side (schema-retargeted) realization of the
# /pm-dashboard render contract - a SEPARATE surface from the pack engine
# (scripts/dashboard-render.py). This test is the client-CUSTOMIZED mirror of
# scripts/tests/test-dashboard-render.sh: it self-provisions a scratch CLIENT
# project fixture (mktemp -d; TD-* entries under docs/project/backlog/, the
# client path layout) and exercises the client engine end to end:
#   - build  -> RENDER OK (exit 0), writes dashboard.html + shell
#   - verify -> VERIFY OK (exit 0) on the good board (the complete DATA floor)
#   - recency ordering: resolved_date emitted on Resolved records (date-desc
#     DISTINCT from id/num-desc), tier on EVERY record
#   - atomic complete-or-loud-abort: a forced verify shortfall exits non-zero
#     and leaves NO board on disk (S2)
#   - SKIP-lenient off a git work tree (verify exits 0 on a non-git dir)
#
# Self-provisioning (mktemp), NOT dependent on any built test-fixtures/<NAME>,
# so it is a NORMAL test and belongs in scripts/tests/ (NOT
# scripts/tests/fixture-dependent/). The CI shard partitioner auto-discovers
# scripts/tests/*.sh (glob minus allowlist), so no explicit workflow wiring is
# needed. Cleans its mktemp fixtures on exit. Pure ASCII (engine ASCII style).
#
# Usage:    bash scripts/tests/test-pm-dashboard-render.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RENDER="$PACK_ROOT/project-template/scripts/pm-dashboard-render.py"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-pm-dashboard-render.XXXXXX")"
NONGIT_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-pm-dashboard-nongit.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE" "$NONGIT_BASE"' EXIT

# Belt-and-suspenders: never let git walk up out of the fixtures into an
# enclosing worktree (which would make the non-git SKIP case find a real repo).
export GIT_CEILING_DIRECTORIES="$FIXTURE_BASE:$NONGIT_BASE"

REPO="$FIXTURE_BASE/repo"
APPROVALS="$REPO/docs/project/dashboard-approvals"
DASH="$APPROVALS/dashboard.html"
SHELL_F="$APPROVALS/dashboard-shell.html"
PROBE="$FIXTURE_BASE/probe.py"
FAULT="$FIXTURE_BASE/faultbuild.py"

passes=0
fails=0
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then pass "$label"
    else fail "$label" "$expected" "$actual"; fi
}

# -- Fixture scaffolding (the CLIENT path layout) --------------------------
mkdir -p "$REPO/docs/project/backlog" "$REPO/docs/project/changelog" "$REPO/docs/pack"

cat > "$REPO/docs/project/backlog/_rules.md" <<'EOF'
# Backlog rules (fixture)

Status vocabulary:

- `Open` - active / not yet started.
- `Unblocked` - a pending-decision state.
- `Deferred` - deliberately postponed.
- `Resolved` - entry is closed.
- `Deprecated` - superseded.
- `Cancelled` - abandoned.
EOF

# TD-001: Open + active (named in session active prose) -> derived-active,
# tier:full, source-anchored body.
cat > "$REPO/docs/project/backlog/TD-001.md" <<'EOF'
**TD-001 - client dashboard renderer**

Type: task
Status: Open
Blockers: none
Unblocks: TD-002
Description: The client renderer authors the project-frontier presentation as
versioned source and refuses to emit a board that fails its own complete data
floor. This substantive body anchors the tier-full source heuristic with real
prose distinct from a bare title echo.
EOF

cat > "$REPO/docs/project/backlog/TD-002.md" <<'EOF'
**TD-002 - complete floor test**

Type: task
Status: Open
Blockers: TD-001
Unblocks: none
Description: A committed test proves the client renderer verify floor bites and
that build refuses to emit a hollow board, exercising build, verify, recency
ordering, atomic abort, and the skip-lenient path off a git work tree.
EOF

cat > "$REPO/docs/project/backlog/TD-003.md" <<'EOF'
**TD-003 - deferred lane sample**

Type: task
Status: Deferred
Blockers: none
Unblocks: none
Description: A deferred backlog entry that stays non-terminal so it lands in the
full-tier expansion set while never appearing as an active or resolved item, to
exercise status-bucket counting in the fixture board.
EOF

# TD-004: Resolved with the NEWER date but the LOWER num - the num/date
# inversion the recency comparator must resolve date-desc (mirrors real cases).
cat > "$REPO/docs/project/backlog/TD-004.md" <<'EOF'
**TD-004 - resolved sample newest**

Type: task
Status: Resolved
Resolution: 2026-07-12 landed via the seed commit
Blockers: none
Unblocks: none
Description: A resolved backlog entry inside the newest-ten resolved window so it
is promoted to the full tier and must carry a source-anchored body distinct from
a bare title echo for the conformance floor to accept it.
EOF

# TD-005: Resolved with the OLDER date but the HIGHER num.
cat > "$REPO/docs/project/backlog/TD-005.md" <<'EOF'
**TD-005 - resolved sample older**

Type: task
Status: Resolved
Resolution: 2026-07-05 landed earlier in the cycle
Blockers: none
Unblocks: none
Description: A second resolved backlog entry inside the newest-ten window that
provides a distinct populated body so the full-tier source-anchored heuristic has
more than one resolved record to validate during verification.
EOF

# TD-006: Deprecated + terminal + outside the resolved window -> tier:minimal,
# NO resolved_date. Demonstrates tier is present on every record while
# resolved_date is emitted ONLY on Resolved records.
cat > "$REPO/docs/project/backlog/TD-006.md" <<'EOF'
**TD-006 - deprecated minimal sample**

Type: task
Status: Deprecated
Blockers: none
Unblocks: none
Description: A deprecated backlog entry that is terminal and outside the resolved
window so it lands at the minimal tier, so the fixture carries both a minimal and
several full records for the tier-on-every-record assertion.
EOF

# session state: all 9 Group-A sources populated (prose forms) + a non-empty
# in_flight_agents so the session-layer floor is non-vacuous.
cat > "$REPO/docs/project/pm-session-state.json" <<'EOF'
{
  "schema": "pm-session-state/1",
  "boundary_commit": "abc1234",
  "active": ["TD-001 client renderer implementation in progress (coder authoring)"],
  "in_flight_agents": ["coder-td001-render - implementing the renderer (running)"],
  "queue": ["TD-002", "TD-003"],
  "parallelization": "serial - TD-001 renderer then the complete-floor test",
  "wave": "Wave 1: renderer + complete-floor test co-land in one commit",
  "cycle_position": "TD-001: coder implementing (pre-review)",
  "pending_decisions": [
    "Approve the client engine + complete-floor test",
    "Sequence TD-002 immediately after TD-001"
  ]
}
EOF

cat > "$REPO/docs/project/changelog/2026-07-20-v-cut.md" <<'EOF'
### 2026-07-20 - release - client v-cut ride-alongs

**Summary**: The client renderer and its complete-floor test land together.

- TD-001 client dashboard renderer shipped
- TD-004 resolved sample landed via the seed commit
EOF

cat > "$REPO/CLAUDE.md" <<'EOF'
# CLAUDE.md (fixture)

## Project rules

### Workflow

- **Agents never commit** - no agent runs a state-changing git verb; only the
  orchestrator stages and commits with approval. `[rationale: agents-never-commit]`

### Conventions

- **Fail loud on migration** - delete the old source on migration so dangling
  refs break loudly and get fixed. `[rationale: fail-loud-delete-old-source]`
EOF

cat > "$REPO/docs/pack/PM-CHAT.md" <<'EOF'
# PM-CHAT (fixture)

| Agent | Profile |
|---|---|
| `pm-architect` | Read-only |
| `pm-coder` | Write-capable per an approved plan |
| `pm-reviewer` | Read-only |
EOF

cat > "$REPO/docs/pack/HELP-FRAGMENT.md" <<'EOF'
# Help fragment (fixture)

| Verb | What it does |
|---|---|
| `/pm-startup` | Bootstrap a session. |
| `/pm-dashboard` | Render the project frontier board. |
| `pm help` | Print this fragment. |
EOF

cat > "$REPO/docs/pack/PM-DASHBOARD-SPEC.md" <<'EOF'
# PM dashboard spec (fixture)

Minimal spec body so `git hash-object` yields a spec-sha for the render.
EOF

cat > "$REPO/README.md" <<'EOF'
# Fixture README

| Version | Date | Notes |
|---|---|---|
| v11.0 (work) | 2026-07-20 | fixture version row |
EOF

# git init + a single committed feat landing carrying a TD-NNN token so
# `git log` yields real landing history (the plans floor is then non-vacuous).
git -C "$REPO" init -q -b main
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name test
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "feat: TD-004 - resolved sample seed for the client dashboard fixture"

# -- probe helper (reuses the engine's OWN state extractor; test infra) -----
cat > "$PROBE" <<'PY'
#!/usr/bin/env python3
"""Test helper: load the produced dashboard.html #state via the engine's own
extractor and print a requested projection for assertion."""
import importlib.util
import sys

render_path, html_path, kind = sys.argv[1], sys.argv[2], sys.argv[3]
spec = importlib.util.spec_from_file_location("pmrender", render_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
raw = open(html_path, encoding="utf-8").read()
st = mod.extract_produced_state(raw) or {}
tds = st.get("tds", {})


def rd(i):
    r = tds.get(i, {})
    return r["resolved_date"] if "resolved_date" in r else "<absent>"


if kind == "resolved_dates":
    print("004=%s 005=%s 001=%s 006=%s" % (rd("TD-004"), rd("TD-005"),
                                            rd("TD-001"), rd("TD-006")))
elif kind == "tier_all":
    missing = [i for i, r in tds.items()
               if not (isinstance(r, dict) and r.get("tier"))]
    print("missing=%d total=%d" % (len(missing), len(tds)))
elif kind == "tiers":
    print("004=%s 006=%s" % (tds.get("TD-004", {}).get("tier"),
                             tds.get("TD-006", {}).get("tier")))
elif kind == "date_order":
    res = [r for r in tds.values() if r.get("status") == "done"]
    res.sort(key=lambda r: ((r.get("resolved_date") or ""), r.get("num", 0)),
             reverse=True)
    print(",".join(r["id"] for r in res))
elif kind == "num_order":
    res = [r for r in tds.values() if r.get("status") == "done"]
    res.sort(key=lambda r: r.get("num", 0), reverse=True)
    print(",".join(r["id"] for r in res))
else:
    print("UNKNOWN_PROBE")
PY

# -- atomic-abort fault harness (test infra; self-cleaned) ------------------
cat > "$FAULT" <<'PY'
#!/usr/bin/env python3
"""Atomic-abort fault injection: monkeypatch verify_floor to force a shortfall,
then call do_build and exit with its return code. Proves the atomic build
fails-closed - a verify-failing build leaves NO board / shell / temp on disk."""
import importlib.util
import sys

render_path, repo = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("pmrender", render_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.verify_floor = lambda *a, **k: ["FORCED verify failure (atomic-abort fault injection)"]
sys.exit(mod.do_build(repo, mod.SPEC_REL_DEFAULT))
PY

# == build -> RENDER OK =====================================================
echo "== build (client engine) =="
build_out="$(python3 "$RENDER" build --repo-root "$REPO" 2>&1)"; build_rc=$?
assert_eq "build exits 0 on the populated client fixture" "0" "$build_rc"
printf '%s\n' "$build_out" | grep -q "RENDER OK" \
    && pass "build prints RENDER OK" || fail "build prints RENDER OK"
[[ -f "$DASH" ]] && pass "build wrote dashboard.html" || fail "build wrote dashboard.html"
[[ -f "$SHELL_F" ]] && pass "build wrote dashboard-shell.html" || fail "build wrote dashboard-shell.html"

# == verify -> VERIFY OK (the complete DATA floor) ==========================
echo "== verify (complete DATA floor) =="
verify_out="$(python3 "$RENDER" verify --repo-root "$REPO" 2>&1)"; verify_rc=$?
assert_eq "verify exits 0 on the good board" "0" "$verify_rc"
printf '%s\n' "$verify_out" | grep -q "VERIFY OK" \
    && pass "verify prints VERIFY OK - complete DATA floor clean" \
    || fail "verify prints VERIFY OK"

# == recency ordering + tier-on-every-record ================================
echo "== recency ordering (resolved_date date-desc, distinct from num-desc) =="
# resolved_date is emitted on Resolved records (TD-004/005) and ABSENT on
# non-resolved (TD-001 Open+active, TD-006 Deprecated). TD-004 (lower num)
# carries the NEWER date than TD-005 (higher num).
assert_eq "resolved_date emitted on Resolved (004 newer than 005), absent on non-resolved" \
    "004=2026-07-12 005=2026-07-05 001=<absent> 006=<absent>" \
    "$(python3 "$PROBE" "$RENDER" "$DASH" resolved_dates)"
assert_eq "tier present on EVERY record" "missing=0 total=6" \
    "$(python3 "$PROBE" "$RENDER" "$DASH" tier_all)"
assert_eq "tier distinguishes full (resolved-window 004) from minimal (deprecated 006)" \
    "004=full 006=minimal" "$(python3 "$PROBE" "$RENDER" "$DASH" tiers)"
date_order="$(python3 "$PROBE" "$RENDER" "$DASH" date_order)"
num_order="$(python3 "$PROBE" "$RENDER" "$DASH" num_order)"
assert_eq "resolved recency order is date-desc (004 before 005)" "TD-004,TD-005" "$date_order"
assert_eq "resolved num-desc order is the INVERSE (005 before 004)" "TD-005,TD-004" "$num_order"
if [[ "$date_order" != "$num_order" ]]; then
    pass "recency (date-desc) is DISTINCT from num-desc (the num/date inversion)"
else
    fail "recency (date-desc) must differ from num-desc"
fi
# The RENDER LAYER (not just the data) sorts by resolved_date: the two resolved
# surfaces (recentResolved + the pArchive Resolved group) carry the date-desc
# localeCompare comparator. Expect exactly 2 occurrences.
rescmp=$(grep -Fo "localeCompare(a.resolved_date" "$SHELL_F" | wc -l | tr -d ' ')
assert_eq "shell resolved comparators sort by resolved_date (recentResolved + pArchive)" \
    "2" "$rescmp"

# == atomic complete-or-loud-abort (a forced shortfall writes NO board) =====
echo "== atomic complete-or-loud-abort (verify-failing build leaves no board) =="
rm -rf "$APPROVALS"
fault_out="$(python3 "$FAULT" "$RENDER" "$REPO" 2>&1)"; fault_rc=$?
[[ $fault_rc -ne 0 ]] && pass "fault-injected build exits non-zero (fail-closed)" \
    || fail "fault-injected build exits non-zero (fail-closed)"
printf '%s\n' "$fault_out" | grep -q "BUILD ABORTED" \
    && pass "build prints the loud BUILD ABORTED shortfall" \
    || fail "build prints BUILD ABORTED"
[[ ! -f "$DASH" ]] && pass "no dashboard.html on a verify-failing build" \
    || fail "no dashboard.html on a verify-failing build"
[[ ! -f "$SHELL_F" ]] && pass "no dashboard-shell.html on a verify-failing build" \
    || fail "no dashboard-shell.html on a verify-failing build"
tmp_leftover=$(find "$APPROVALS" -name '.dashboard-*.tmp' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "no temp leftover (.dashboard-*.tmp)" "0" "$tmp_leftover"

# == SKIP-lenient off a git work tree =======================================
echo "== SKIP-lenient off a git work tree (verify exits 0 on a non-git dir) =="
nongit_out="$(python3 "$RENDER" verify --repo-root "$NONGIT_BASE" 2>&1)"; nongit_rc=$?
assert_eq "verify exits 0 off a git work tree (SKIP-lenient)" "0" "$nongit_rc"
printf '%s\n' "$nongit_out" | grep -q "VERIFY OK" \
    && pass "verify prints VERIFY OK off a git tree (lenient skip, no floor run)" \
    || fail "verify prints VERIFY OK off a git tree"

# == Summary ================================================================
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
