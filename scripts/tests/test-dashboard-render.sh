#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-dashboard-render.sh - the complete-floor test for the
# committed pack-frontier dashboard renderer (scripts/dashboard-render.py).
#
# Proves the renderer's `verify` DATA floor BITES on every droppable component
# (the M2 complete tamper matrix - one NON-VACUOUS row per floor assertion:
# T-A1..A9 session layer, T-B1..B9 backed sections, T-C1..C4 parse/encoding
# invariants, the render-token smoke, plus the T-GOOD positive completeness
# row), asserts the 4 render gaps, and checks determinism. Authority:
# ARCH-DESIGN-RECONCILED.md (bd224-recon) SS3-4 + PLAN-RECONCILED.md
# (bd224-planrecon) SS5.
#
# Fixture (S1): a `git init`'d `mktemp -d` mini repo-root (NOT ~/Developer/_tmp;
# the scratch-dir convention governs the orchestrator's untracked work, not
# where a CI-executed test scaffolds). Committed-CLEAN so the renderer's live
# git read degrades to a deterministic idle `inflight`; POPULATED (SHOULD-2)
# with real committed `feat: BD-NNN` landing history + a non-empty
# in_flight_agents + populated prose/list sources so no tamper row is vacuous.
#
# Usage:    bash scripts/tests/test-dashboard-render.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RENDER="$PACK_ROOT/scripts/dashboard-render.py"

FIXTURE_BASE="$(mktemp -d -t test-dashboard-render.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

# Belt-and-suspenders: never let git walk up out of the fixture into an
# enclosing worktree (which would find a dirty tree and break determinism).
export GIT_CEILING_DIRECTORIES="$FIXTURE_BASE"

REPO="$FIXTURE_BASE/repo"
APPROVALS="$REPO/pack-ops/dashboard-approvals"
DASH="$APPROVALS/dashboard.html"
SHELL_F="$APPROVALS/dashboard-shell.html"
GOOD="$FIXTURE_BASE/dashboard.good.html"
TAMPER="$FIXTURE_BASE/tamper.py"

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

run_verify() { python3 "$RENDER" verify --repo-root "$REPO" >/dev/null 2>&1; }
probe() { python3 "$TAMPER" probe "$DASH" "$1"; }

# ── Fixture scaffolding ────────────────────────────────────────────────────
mkdir -p "$REPO/backlog" "$REPO/changelog" "$REPO/pack-ops"

cat > "$REPO/backlog/_rules.md" <<'EOF'
# Backlog rules (fixture)

Status vocabulary:

- `Open` - active / not yet started.
- `Unblocked` - a pending-decision state.
- `Deferred` - deliberately postponed.
- `Resolved` - entry is closed.
- `Deprecated` - superseded.
- `Cancelled` - abandoned.
EOF

# BD-901: Open + active (in active prose) + a committed feat landing. Its body
# carries a literal </script> and an em-dash to exercise gap-1 escaping +
# gap-3 ASCII-safety.
cat > "$REPO/backlog/BD-901.md" <<'EOF'
**BD-901 — durable dashboard renderer**

Type: umbrella
Status: Open
Description: The committed renderer authors the presentation as versioned
source and refuses to emit a board that fails its own complete floor. A prose
sample </script> is embedded here to exercise the injection escaping path with
an em-dash — and more substantive words follow for source anchoring stability.
Blockers: none
Unblocks: BD-902
EOF

cat > "$REPO/backlog/BD-902.md" <<'EOF'
**BD-902 — complete floor test**

Type: task
Status: Open
Description: A committed test proves the renderer verify floor bites on each
droppable data component through a one-non-vacuous-row-per-assertion tamper
matrix and a cheap render-token smoke that catches a wholesale dropped route.
Blockers: BD-901
Unblocks: none
EOF

cat > "$REPO/backlog/BD-903.md" <<'EOF'
**BD-903 — deferred lane sample**

Type: task
Status: Deferred
Description: A deferred backlog entry that remains non-terminal so it lands in
the full-tier expansion set while never appearing as an active or resolved item
for the purpose of exercising status-bucket counting in the fixture board.
Blockers: none
Unblocks: none
EOF

cat > "$REPO/backlog/BD-904.md" <<'EOF'
**BD-904 — resolved sample newest**

Type: task
Status: Resolved
Resolved: 2026-07-12 landed via the seed commit
Description: A resolved backlog entry that falls inside the newest-ten resolved
window so it is promoted to the full tier and must carry a source-anchored body
distinct from a bare title echo for the conformance floor to accept it.
Blockers: none
Unblocks: none
EOF

cat > "$REPO/backlog/BD-905.md" <<'EOF'
**BD-905 — resolved sample older**

Type: task
Status: Resolved
Resolved: 2026-07-05 landed earlier in the cycle
Description: A second resolved backlog entry inside the newest-ten window that
provides a distinct populated body so the full-tier source-anchored heuristic
has more than one resolved record to validate against during verification.
Blockers: none
Unblocks: none
EOF

# session-state.json: ALL 9 session-layer sources populated (prose forms) +
# a NON-EMPTY in_flight_agents (SHOULD-2, so T-A3 is non-vacuous).
cat > "$REPO/pack-ops/session-state.json" <<'EOF'
{
  "schema": "pack-session-state/1",
  "boundary_commit": "abc1234",
  "active": ["BD-901 renderer implementation in progress (coder authoring)"],
  "in_flight_agents": ["coder-bd901-render - implementing the renderer (running)"],
  "queue": ["BD-902", "BD-903", "BD-905"],
  "parallelization": "serial - BD-901 renderer then the complete-floor test",
  "wave": "Wave 1: renderer + complete-floor test co-land in one commit",
  "cycle_position": "BD-901: coder implementing (pre-review)",
  "pending_decisions": [
    "Confirm the artifact-variant mechanism (derive-on-fly, no file)",
    "Approve the Commit-1 renderer + floor test",
    "Sequence BD-902 immediately after BD-901"
  ]
}
EOF

# changelog: Scope-A DORMANT (excluded), Scope-B shipped (included), plus the
# two NON-FEATURE bold markers (Audit artifacts / Carried over) that the N3
# rule must EXCLUDE from the shipped tick list.
cat > "$REPO/changelog/v11.md" <<'EOF'
# v11 changelog (fixture)

## v11 - 2026-07-20

**Scope A - deferred lane (DEFERRED / DORMANT in v11.0):**

- BD-800 dormant scope-A item that MUST be excluded from the shipped list
- BD-801 another dormant scope-A item that MUST be excluded

**Scope B - v11 version cut + ride-alongs:**

- BD-901 durable dashboard renderer shipped in v11.0
- BD-902 complete-floor test shipped in v11.0

**Audit artifacts (release evidence):**

- docs/audit-901.md non-feature evidence path that MUST be excluded

**Carried over to future work (v11-Active BDs Open at v11.0 cut):**

- BD-999 carried-over item that MUST be excluded from the shipped list
EOF

cat > "$REPO/changelog/v10.md" <<'EOF'
# v10 changelog (fixture)

## v10 - 2026-06-01

**Scope - v10 baseline:**

- BD-700 the v10 baseline item shipped
EOF

cat > "$REPO/CLAUDE.md" <<'EOF'
# CLAUDE.md (fixture)

## Pack memory

### Workflow

- **Agents never commit** - no agent runs a state-changing git verb at any
  point; only the orchestrator stages and commits with user approval.
  `[roles: universal] [rationale: agents-never-commit]`
- **Bounded review cycle** - each coder run is followed by a bounded review and
  fix cycle capped per commit before escalation to an architect diagnosis.
  `[rationale: bounded-review-fix-cycle]`

### Repo conventions

- **Fail loud on migration** - on an SSOT migration delete the old source so
  dangling references break loudly and get fixed rather than rotting silently.
  `[rationale: fail-loud-delete-old-source]`
EOF

cat > "$REPO/pack-ops/PACK-AGENTS.md" <<'EOF'
# PACK-AGENTS (fixture)

| Agent | Class | Role | Permissions |
|---|---|---|---|
| `pack-architect` | RO | Architecture and design decisions | Read-only |
| `pack-coder` | RW | Implementation execution per an approved plan | never commits |
| `pack-reviewer` | RO | Change review and CI alignment | Read-only |
EOF

cat > "$REPO/pack-ops/HELP-FRAGMENT-PACK.md" <<'EOF'
# Pack verb reference (fixture)

## Pack commands

| Verb | What it does |
|---|---|
| `/pack-startup` | Bootstrap a session. |
| `/pack-dashboard` | Render and publish the pack frontier dashboard. |
| `pack help` | Print this fragment. |
EOF

cat > "$REPO/pack-ops/DASHBOARD-SPEC-PACK.md" <<'EOF'
# Dashboard spec (fixture)

Minimal spec body for spec-sha provenance in the fixture render.
EOF

cat > "$REPO/README.md" <<'EOF'
# Fixture README

| Version | Date | Notes |
|---|---|---|
| v11.0 (work) | 2026-07-20 | fixture version row |
EOF

# git init + a single committed feat landing carrying a BD-NNN token so
# `git log` yields real landing history (SHOULD-2, T-B3 non-vacuous). Then the
# tree is left CLEAN so `inflight` reads idle (S1 determinism).
git -C "$REPO" init -q -b main
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name test
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "feat: BD-901 - durable dashboard renderer fixture seed"

# ── tamper/probe helper (test infra; self-cleaned) ─────────────────────────
cat > "$TAMPER" <<'PY'
#!/usr/bin/env python3
"""Test helper: surgically probe/tamper a produced dashboard.html for the
complete-floor tamper matrix. mode = probe|baseline|apply."""
import sys, json, re

mode, path, kind = sys.argv[1], sys.argv[2], sys.argv[3]
raw = open(path, encoding="utf-8").read()
RE = re.compile(r'(<script type="application/json" id="state">)(.*?)(</script>)', re.S)


def load_state():
    m = RE.search(raw)
    return m, json.loads(m.group(2))


def dump_state(m, st):
    txt = json.dumps(st, sort_keys=True, ensure_ascii=True,
                     separators=(",", ":")).replace("<", "\\u003c")
    return raw[:m.start(2)] + txt + raw[m.end(2):]


def v11(st):
    for c in st.get("changelog", []):
        if c.get("version") == "v11":
            return c
    return None


NONFEATURE = ("audit-901", "BD-999", "BD-800", "BD-801", "Audit artifacts", "Carried over")
STATE_KINDS = {"A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9",
               "B1", "B2", "B2F", "B3", "B4", "B5", "B6", "B7", "B8", "B9",
               "B11", "B12", "C2", "C4"}

if mode == "probe":
    _, st = load_state()
    if kind == "sentinel_count":
        print(raw.count("__PACK_DASHBOARD_STATE__"))
    elif kind == "escaped_breakout":
        # gap-1 positive: the body's </script> is ESCAPED (no raw breakout).
        m = RE.search(raw)
        body = m.group(2)
        print("yes" if ("\\u003c/script" in body and "</script" not in body.lower()) else "no")
    elif kind == "open_count":
        print(st["counts"]["open"])
    elif kind == "bucket_sum_eq_total":
        c = st["counts"]
        s = sum(c.get(k, 0) for k in ("open", "unblocked", "deferred",
                                      "resolved", "deprecated", "cancelled"))
        print("yes" if s == c.get("total") else "no")
    elif kind == "v11_items":
        c = v11(st)
        print(len(c["items"]) if c else 0)
    elif kind == "v11_nonfeature_leak":
        c = v11(st)
        items = " ".join(c["items"]) if c else ""
        print("yes" if any(n in items for n in NONFEATURE) else "no")
    elif kind == "session9":
        pp = st.get("parallelization", {})
        n = 0
        n += 1 if st.get("boundary") else 0
        n += 1 if st.get("active") else 0
        n += 1 if (st.get("inFlightAgentsRaw") and st.get("agentsRunning")) else 0
        n += 1 if st.get("queue") else 0
        n += 1 if pp.get("mode") not in (None, "idle") else 0
        n += 1 if st.get("wave") else 0
        n += 1 if st.get("cyclePosition") else 0
        n += 1 if st.get("pendingDecisions") else 0
        n += 1 if st.get("motion") else 0
        print(n)
    elif kind == "resolved_dates":
        # resolved_date is EMITTED on Resolved records (BD-904/905), ABSENT on
        # non-resolved (BD-901 Open+active, BD-903 Deferred). BD-904 (lower num)
        # carries the NEWER date than BD-905 (higher num) - the exact num/date
        # inversion the recency comparator must resolve date-desc.
        b = st.get("bds", {})
        def rd(bid):
            r = b.get(bid, {})
            return r["resolved_date"] if "resolved_date" in r else "<absent>"
        print("904=%s 905=%s 901=%s 903=%s"
              % (rd("BD-904"), rd("BD-905"), rd("BD-901"), rd("BD-903")))
    elif kind == "backed":
        full = sum(1 for r in st.get("bds", {}).values() if r.get("tier") == "full")
        print("bds=%d full=%d rules=%d changelog=%d agents=%d help=%d plans=%d" % (
            len(st.get("bds", {})), full, len(st.get("rules", [])),
            len(st.get("changelog", [])), len(st.get("agents", [])),
            len(st.get("help", {}).get("commands", [])), len(st.get("plans", {}))))
    else:
        print("UNKNOWN_PROBE")
    sys.exit(0)

if mode == "baseline":
    if kind in STATE_KINDS:
        _, st = load_state()
        pp = st.get("parallelization", {})
        c11 = v11(st)
        ok = {
            "A1": bool(st.get("boundary")),
            "A2": bool(st.get("active")),
            "A3": bool(st.get("inFlightAgentsRaw")) and bool(st.get("agentsRunning")),
            "A4": bool(st.get("queue")),
            "A5": pp.get("mode") not in (None, "idle"),
            "A6": bool(st.get("wave")),
            "A7": bool(st.get("cyclePosition")),
            "A8": bool(st.get("pendingDecisions")),
            "A9": bool(st.get("motion")),
            "B1": len(st.get("bds", {})) > 0,
            "B2": any(r.get("tier") == "full" for r in st.get("bds", {}).values()),
            "B2F": any(r.get("tier") == "full" for r in st.get("bds", {}).values()),
            "B3": len(st.get("plans", {})) > 0,
            "B4": len(st.get("rules", [])) > 0,
            "B5": bool(c11 and c11.get("items")),
            "B6": len(st.get("agents", [])) > 0,
            "B7": bool(st.get("metrics")),
            "B8": bool(st.get("help", {}).get("commands")),
            "B9": isinstance(st.get("inflight"), dict),
            "B11": bool(st.get("version")),
            "B12": any(r.get("status") == "done" and "resolved_date" in r
                       for r in st.get("bds", {}).values()),
            "C2": bool(st.get("counts")),
            "C4": bool(c11 and c11.get("items")),
        }[kind]
    else:
        ok = {
            "C1": "\\u003c/script" in raw,   # escaped breakout present in good build
            "C3": len(raw) > 0,
            "SMOKE": "function pRules" in raw,
        }[kind]
    sys.exit(0 if ok else 1)

# mode == apply
if kind in STATE_KINDS:
    m, st = load_state()
    if kind == "A1":
        st["boundary"] = ""
    elif kind == "A2":
        st["active"] = []
    elif kind == "A3":
        st["inFlightAgentsRaw"] = []
        st["agentsRunning"] = []
    elif kind == "A4":
        st["queue"] = []
    elif kind == "A5":
        st["parallelization"] = {"mode": "serial then the floor test wave", "note": ""}
    elif kind == "A6":
        st["wave"] = ""
    elif kind == "A7":
        st["cyclePosition"] = ""
    elif kind == "A8":
        st["pendingDecisions"] = []
    elif kind == "A9":
        st["motion"] = []
    elif kind == "B1":
        k = sorted(st["bds"])[0]
        del st["bds"][k]
    elif kind == "B2":
        for k, r in st["bds"].items():
            if r.get("tier") == "full":
                r["body"] = r["title"]
                break
    elif kind == "B2F":
        # NIT-1: flip one tier:full -> minimal WITHOUT dropping the record, so
        # the |E_full| set-equality sub-assertion (not the B1 drop) is what bites.
        for k, r in st["bds"].items():
            if r.get("tier") == "full":
                r["tier"] = "minimal"
                break
    elif kind == "B3":
        for k in list(st["plans"]):
            del st["plans"][k]
    elif kind == "B4":
        st["rules"] = [{"i": i} for i in range(len(st["rules"]))]
    elif kind == "B5":
        c = v11(st)
        if c is not None:
            c["items"] = []
    elif kind == "B6":
        st["agents"] = st["agents"][:-1]
    elif kind == "B7":
        st["metrics"]["resolved"] = st["metrics"]["resolved"] + 1
    elif kind == "B8":
        st["help"] = {"commands": []}
    elif kind == "B9":
        del st["inflight"]
    elif kind == "B11":
        # SHOULD-1: null the README-backed version -> the B11 version floor bites.
        st["version"] = None
    elif kind == "B12":
        # Drop resolved_date from one Resolved record (sorted keys -> BD-904, the
        # newest-dated) -> the B12 recency-sort-key floor bites.
        for k in sorted(st["bds"]):
            r = st["bds"][k]
            if r.get("status") == "done" and "resolved_date" in r:
                del r["resolved_date"]
                break
    elif kind == "C2":
        st["counts"]["open"] = st["counts"]["open"] - 1
    elif kind == "C4":
        c = v11(st)
        if c is not None:
            c["items"] = list(c["items"]) + [
                "Audit artifacts leak - non-feature path docs/audit-901.md"]
    out = dump_state(m, st)
else:
    if kind == "C1":
        out = raw.replace("\\u003c", "<")          # unescape -> </script breakout
    elif kind == "C3":
        out = raw + "\u00e9"              # append a non-ASCII byte (gap-3 tamper)
    elif kind == "SMOKE":
        out = raw.replace("function pRules", "function pZZZ", 1)
open(path, "w", encoding="utf-8").write(out)
PY

# ── Build the good board ───────────────────────────────────────────────────
echo "== build + positive completeness (T-GOOD) =="
python3 "$RENDER" build --repo-root "$REPO" >/dev/null 2>&1
build_rc=$?
assert_eq "build exits 0 on the populated fixture" "0" "$build_rc"
[[ -f "$DASH" ]] && pass "build wrote dashboard.html" || fail "build wrote dashboard.html"
[[ -f "$SHELL_F" ]] && pass "build wrote dashboard-shell.html" || fail "build wrote dashboard-shell.html"
# OI-P2=(c): NO artifact-variant / body-content file is emitted.
[[ ! -f "$APPROVALS/dashboard-artifact.html" ]] \
    && pass "no artifact-variant file emitted (OI-P2=(c) derive-on-fly)" \
    || fail "an artifact-variant file was emitted (OI-P2=(c) forbids it)"
cp "$DASH" "$GOOD"

run_verify; good_rc=$?
assert_eq "verify PASSES (exit 0) on the good board" "0" "$good_rc"
assert_eq "T-GOOD all 9 session-layer fields populated" "9" "$(probe session9)"
echo "  info: backed sections -> $(probe backed)"
assert_eq "T-GOOD bds total-accountability (5 fixture BDs)" \
    "bds=5 full=5 rules=3 changelog=2 agents=3 help=3 plans=1" "$(probe backed)"
# resolved_date emit (data plumbing): present on Resolved records with the
# committed date, ABSENT on non-resolved. BD-904 (lower num) carries the NEWER
# date than BD-905 (higher num) - the num/date inversion the recency comparators
# resolve date-desc (mirrors the real BD-224 case).
assert_eq "T-GOOD resolved_date emitted on Resolved (904 newer than 905), absent on non-resolved" \
    "904=2026-07-12 905=2026-07-05 901=<absent> 903=<absent>" "$(probe resolved_dates)"

# ── The 4 render gaps (positive) ───────────────────────────────────────────
echo "== the 4 render gaps (positive) =="
nonascii=$(LC_ALL=C grep -c '[^ -~	]' "$DASH")
assert_eq "gap 3: zero non-ASCII bytes in dashboard.html" "0" "$nonascii"
assert_eq "gap 1: JS sentinel survives injection (count 1)" "1" "$(probe sentinel_count)"
assert_eq "gap 1: body </script> escaped, no state breakout" "yes" "$(probe escaped_breakout)"
assert_eq "gap 2: active-but-Open BD-901 counted under Open (open=2)" "2" "$(probe open_count)"
assert_eq "gap 2: status buckets sum == total (no double-count)" "yes" "$(probe bucket_sum_eq_total)"
v11n=$(probe v11_items)
[[ "$v11n" -gt 0 ]] && pass "gap 4: v11 changelog panel items>0 ($v11n)" \
    || fail "gap 4: v11 changelog panel items>0" ">0" "$v11n"
assert_eq "gap 4/N3: v11 shipped list excludes non-feature markers" "no" "$(probe v11_nonfeature_leak)"

# ── The COMPLETE tamper matrix (Level 2: verify BITES on each assertion) ────
# Each row restores the pristine board, asserts the tamper target's BASELINE is
# non-empty (a row whose baseline is empty proves nothing - SHOULD-2), applies
# the mutation, and asserts verify EXITS NON-ZERO.
echo "== complete tamper matrix (one non-vacuous row per floor assertion) =="
tamper_row() {
    local kind="$1" label="$2"
    cp "$GOOD" "$DASH"
    if ! python3 "$TAMPER" baseline "$DASH" "$kind" >/dev/null 2>&1; then
        fail "$label [VACUOUS: tamper target baseline is empty]"
        return
    fi
    python3 "$TAMPER" apply "$DASH" "$kind"
    run_verify; local rc=$?
    if [[ $rc -ne 0 ]]; then pass "$label (verify exits $rc)"
    else fail "$label (verify PASSED on tampered board - floor does not bite)"; fi
}

tamper_row A1 "T-A1 boundary dropped -> verify FAIL"
tamper_row A2 "T-A2 active[] emptied (OPTION-2's exact bug) -> verify FAIL"
tamper_row A3 "T-A3 in_flight agents dropped -> verify FAIL"
tamper_row A4 "T-A4 queue emptied -> verify FAIL"
tamper_row A5 "T-A5 parallelization raw-blob-as-mode -> verify FAIL"
tamper_row A6 "T-A6 wave emptied -> verify FAIL"
tamper_row A7 "T-A7 cyclePosition emptied -> verify FAIL"
tamper_row A8 "T-A8 pendingDecisions emptied -> verify FAIL"
tamper_row A9 "T-A9 motion != active ++ (queue - active) -> verify FAIL"
tamper_row B1 "T-B1 a tracked BD dropped from bds -> verify FAIL"
tamper_row B2 "T-B2 a tier:full body replaced by a title echo -> verify FAIL"
tamper_row B2F "T-B2F a tier:full record flipped to minimal (kept) -> verify FAIL"
tamper_row B3 "T-B3 a BD with git-log landings absent from plans -> verify FAIL"
tamper_row B4 "T-B4 rules emitted as index stubs -> verify FAIL"
tamper_row B5 "T-B5 v11 changelog panel emptied -> verify FAIL"
tamper_row B6 "T-B6 agents count != roster -> verify FAIL"
tamper_row B7 "T-B7 metrics mis-tallied -> verify FAIL"
tamper_row B8 "T-B8 help emptied despite a live source -> verify FAIL"
tamper_row B9 "T-B9 inflight{} structure absent -> verify FAIL"
tamper_row B11 "T-B11 README-backed version nulled -> verify FAIL"
tamper_row B12 "T-B12 resolved_date dropped from a Resolved record -> verify FAIL"
tamper_row C1 "T-C1 </script breakout (unescaped) -> verify FAIL"
tamper_row C2 "T-C2 status-token counts mutated -> verify FAIL"
tamper_row C3 "T-C3 non-ASCII byte injected -> verify FAIL"
tamper_row C4 "T-C4 non-feature marker leaked into v11 list -> verify FAIL"
tamper_row SMOKE "T-SMOKE a render function wholesale-dropped -> verify FAIL"

# ── SHOULD-2a: T-C1 fails-closed CLEANLY (clean shortfall, NOT a traceback) ─
# The C1 (</script) breakout must fail-closed with the designed shortfall(s) on
# stderr - never an uncaught JSONDecodeError traceback. Capture stderr with the
# board tampered and assert: non-zero rc, NO "Traceback", the clean parse
# shortfall, AND the designed C1 breakout assertion (raw-span scan) both fire.
echo "== T-C1 clean fail-closed (no Python traceback) =="
cp "$GOOD" "$DASH"
python3 "$TAMPER" apply "$DASH" C1
c1_err="$(python3 "$RENDER" verify --repo-root "$REPO" 2>&1 >/dev/null)"
c1_rc=$?
[[ $c1_rc -ne 0 ]] && pass "T-C1 verify exits non-zero (fail-closed)" \
    || fail "T-C1 verify exits non-zero (fail-closed)"
if printf '%s\n' "$c1_err" | grep -q "Traceback"; then
    fail "T-C1 fails-closed cleanly (no Python traceback)" "no Traceback" "traceback present"
else pass "T-C1 fails-closed cleanly (no Python traceback)"; fi
if printf '%s\n' "$c1_err" | grep -q "state element JSON not parseable"; then
    pass "T-C1 emits the clean 'state element JSON not parseable' shortfall"
else fail "T-C1 emits the clean 'state element JSON not parseable' shortfall"; fi
if printf '%s\n' "$c1_err" | grep -q "breakout"; then
    pass "T-C1 fires the designed C1 breakout assertion (raw-span scan)"
else fail "T-C1 fires the designed C1 breakout assertion (raw-span scan)"; fi

# ── NIT-2: S2 atomic build fail-closed (a verify-failing build writes NOTHING) ─
# Fault-inject a forced verify shortfall into do_build (via monkeypatch) and
# assert the atomic build leaves NO dashboard.html, NO shell, and NO temp
# leftover - Level-2 coverage of the S2 atomic guarantee.
echo "== S2 atomic build fail-closed (verify-failing build leaves no board) =="
rm -rf "$APPROVALS"
cat > "$FIXTURE_BASE/faultbuild.py" <<'PY'
#!/usr/bin/env python3
"""S2 fault-injection harness (NIT-2): monkeypatch verify_floor to force a
shortfall, then call do_build and exit with its return code. Proves the atomic
build fails-closed - a verify-failing build leaves NO board / shell / temp."""
import importlib.util
import sys

render_path, repo = sys.argv[1], sys.argv[2]
modspec = importlib.util.spec_from_file_location("dashrender", render_path)
mod = importlib.util.module_from_spec(modspec)
modspec.loader.exec_module(mod)
mod.verify_floor = lambda *a, **k: ["FORCED verify failure (S2 fault injection)"]
sys.exit(mod.do_build(repo, mod.SPEC_REL_DEFAULT))
PY
python3 "$FIXTURE_BASE/faultbuild.py" "$RENDER" "$REPO" >/dev/null 2>&1
s2_rc=$?
[[ $s2_rc -ne 0 ]] && pass "S2 fault-injected build returns non-zero (fail-closed)" \
    || fail "S2 fault-injected build returns non-zero (fail-closed)"
[[ ! -f "$DASH" ]] && pass "S2 no dashboard.html on a verify-failing build" \
    || fail "S2 no dashboard.html on a verify-failing build"
[[ ! -f "$SHELL_F" ]] && pass "S2 no dashboard-shell.html on a verify-failing build" \
    || fail "S2 no dashboard-shell.html on a verify-failing build"
s2_tmp=$(find "$APPROVALS" -name '.dashboard-*.tmp' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "S2 no temp leftover (.dashboard-*.tmp)" "0" "$s2_tmp"
# Restore a clean board for the determinism section that follows.
python3 "$RENDER" build --repo-root "$REPO" >/dev/null 2>&1

# ── Determinism (design SS4.5) ─────────────────────────────────────────────
# The tamper matrix left dashboard.html mutated; rebuild a CLEAN baseline first.
echo "== determinism =="
python3 "$RENDER" build --repo-root "$REPO" >/dev/null 2>&1
cp "$SHELL_F" "$FIXTURE_BASE/shell1.html"
cp "$DASH" "$FIXTURE_BASE/dash1.html"
python3 "$RENDER" build --repo-root "$REPO" >/dev/null 2>&1
if cmp -s "$FIXTURE_BASE/shell1.html" "$SHELL_F"; then
    pass "two builds -> byte-identical shell (reuse)"
else fail "two builds -> byte-identical shell (reuse)"; fi
if cmp -s "$FIXTURE_BASE/dash1.html" "$DASH"; then
    pass "two builds -> byte-identical dashboard.html (idle inflight)"
else fail "two builds -> byte-identical dashboard.html (idle inflight)"; fi
rm -f "$SHELL_F"
python3 "$RENDER" build --repo-root "$REPO" >/dev/null 2>&1
if cmp -s "$FIXTURE_BASE/shell1.html" "$SHELL_F"; then
    pass "regenerated shell byte-identical to the first (deterministic author)"
else fail "regenerated shell byte-identical to the first (deterministic author)"; fi

# ── Render-token smoke (M1, positive; string-presence, NO JS engine) ───────
echo "== render-token smoke (positive) =="
smoke_missing=0
for t in landing frontier grand-plan archive methodology rules deps changelog metrics help; do
    grep -q "data-r=\"$t\"" "$SHELL_F" || { echo "    missing nav token: $t"; smoke_missing=$((smoke_missing + 1)); }
done
for fn in pLanding pFrontier pGrand pBD pArchive pMethodology pRules pDeps pChangelog pMetrics pHelp; do
    grep -q "function $fn" "$SHELL_F" || { echo "    missing render fn: $fn"; smoke_missing=$((smoke_missing + 1)); }
done
grep -q "getElementById('state')" "$SHELL_F" || { echo "    missing boot"; smoke_missing=$((smoke_missing + 1)); }
grep -q "replace(/\[&<>" "$SHELL_F" || { echo "    missing escape helper"; smoke_missing=$((smoke_missing + 1)); }
assert_eq "shell carries all 10 nav + 11 p* tokens + boot + escape helper" "0" "$smoke_missing"
# Resolved-comparator smoke (OI-4): the two resolved surfaces (recentResolved +
# the pArchive Resolved group) sort by resolved_date (date-desc), not pure
# num-desc. Expect exactly 2 occurrences of the localeCompare comparator token.
rescmp=$(grep -Fo "localeCompare(a.resolved_date" "$SHELL_F" | wc -l | tr -d ' ')
assert_eq "shell resolved comparators reference resolved_date (recentResolved + pArchive)" "2" "$rescmp"

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
