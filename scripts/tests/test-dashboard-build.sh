#!/usr/bin/env bash
# scripts/tests/test-dashboard-build.sh — unit tests for scripts/dashboard-build.py
# (the sanctioned committed build/verify script for /pack-dashboard — BD-224
# OPTION-2 reconciled model, OI-P2 user-approved unit test).
#
# Exercises BOTH modes against SELF-PROVISIONED /tmp fixtures (never the real
# tree, per "Test infra is self-provisioned"):
#
#   Group 0: module imports; `build` + `verify` modes are exposed.
#   Group 1: a CONFORMANT fixture — build then verify → exit 0 (PASS).
#   Group 2: DEGRADED #state mutations (render-side) → verify HARD-FAILs:
#            - a tier:"full" record with a SHORT body (< 40 normalized chars)
#            - a MISSING E_full member (a full member flipped to tier:"minimal")
#            - a SPOOF title-echo body (body == title)
#            - a DROPPED BD (a live BD removed from #state.bds → total-accountability)
#   Group 3: class-(c) fail-closed mutations (tree-side, verified against the
#            previously-built render):
#            - a NEW Status value (Blocked, absent from _rules.md vocab) →
#              vocab-closure fail-closed
#            - an UNPARSEABLE Status (Status: line stripped) → parse-coverage
#              fail-closed
#            - a structure-sha mutation (backlog/_rules.md edited post-build) →
#              structure-sha fail-closed
#   Group 4: (git-guarded) the committed-history PLANS FLOOR bites — a BD with a
#            real feat landing dropped from #state.plans → verify HARD-FAILs.
#
# This test is auto-wired into CI via the Check-42 disk glob (scripts/tests/*.sh);
# it needs no allowlist entry. Model shape: scripts/tests/test-validate-pack-check-88.sh.
#
# Usage: bash scripts/tests/test-dashboard-build.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/dashboard-build.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + both modes exposed
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: module import + build/verify modes ===\n"

SCRIPT="$SCRIPT" python3 - <<'EOF' > /tmp/dbuild-import.out 2>&1
import os, sys, importlib.util
S = os.environ["SCRIPT"]
spec = importlib.util.spec_from_file_location("db", S)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
for sym in ("do_build", "do_verify", "compute_e_full", "compute_structure_sha",
            "source_anchored_ok", "parse_vocab", "parse_backlog"):
    if not hasattr(mod, sym):
        print("FAIL_MISSING", sym); sys.exit(1)
# argparse exposes exactly the two modes
import argparse
try:
    mod.main(["bogus-mode"])
    print("FAIL_ACCEPTED_BOGUS_MODE"); sys.exit(1)
except SystemExit:
    pass
print("OK")
EOF
if grep -q "^OK$" /tmp/dbuild-import.out; then
    t_pass "dashboard-build.py imports; do_build/do_verify present; modes bounded"
else
    t_fail "import / mode check failed" "$(cat /tmp/dbuild-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Groups 1-3: conformant PASS + degraded/class-(c) FAILs (self-provisioned)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Groups 1-3: conformant PASS + degraded/class-(c) FAILs ===\n"

if ! command -v git > /dev/null 2>&1; then
    t_pass "git absent — Groups 1-3 SKIPPED (backlog enumeration is git-tracked; lenient)"
else
SCRIPT="$SCRIPT" python3 - <<'EOF'
import os, sys, json, re, shutil, tempfile, subprocess, pathlib

SCRIPT = os.environ["SCRIPT"]
STATE_RE = re.compile(r'(<script[^>]*id="state"[^>]*>)(.*?)(</script>)', re.S)
failures = []


def run_mode(mode, root):
    r = subprocess.run(
        [sys.executable, SCRIPT, mode, "--repo-root", str(root)],
        capture_output=True, text=True,
    )
    return r.returncode, (r.stdout + r.stderr)


def write(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")


def make_fixture(root):
    # backlog/_rules.md — the vocab SSOT (six canonical lifecycle states).
    write(root, "backlog/_rules.md",
          "# Stream contract\n\n"
          "## Lifecycle states admitted\n\n"
          "- `Open` — active / not yet started.\n"
          "- `Unblocked` — a pending-decision state between Open and Deferred.\n"
          "- `Deferred` — deliberately postponed.\n"
          "- `Resolved` — closed; carries a `Resolved:` line.\n"
          "- `Deprecated` — superseded.\n"
          "- `Cancelled` — abandoned.\n\n"
          "## Supporting files\n\n- `_rules.md`\n")

    def bd(num, title, status, desc, resolved=None):
        body = (
            f"<!-- per-entry source: /backlog/BD-{num}.md; contract: /backlog/_rules.md -->\n"
            f"**BD-{num} — {title}**\n"
            f"Type: feat\n"
            f"Status: {status}\n"
            f"Blockers: none\n"
            f"Unblocks: downstream work\n"
            f"Description: {desc}\n"
        )
        if resolved:
            body += f"Resolved: {resolved} — shipped and verified green.\n"
        write(root, f"backlog/BD-{num}.md", body)

    # Non-terminal (all full): Open / Deferred / Unblocked.
    bd("101", "Widget alignment engine for the frontier board", "Open",
       "The widget alignment engine recomputes column offsets for every frontier "
       "row so the board stays visually coherent across breakpoints, reading the "
       "live layout constants and applying a deterministic packing pass that never "
       "depends on the wall clock.")
    bd("102", "Archive filter debounce and keyboard routing", "Deferred",
       "The archive filter debounce coalesces keystrokes and routes keyboard focus "
       "through the hash router so a 271-item board filters live without a reflow "
       "storm or a dropped anchor, preserving the deep-link contract.")
    bd("103", "Boundary freshness chip ancestor-within-N logic", "Unblocked",
       "The boundary freshness chip computes ancestor-within-N reachability over "
       "bookkeeping-only commits so a clean idle repo still reads fresh, degrading "
       "to a defined idle form when the live git read is unavailable.")

    # Twelve Resolved with increasing dates → newest-10 = BD-203..BD-212.
    for i in range(1, 13):
        num = f"2{i:02d}"
        bd(num, f"Resolved deliverable number {i} for the archive index",
           "Resolved",
           f"Resolved deliverable {i} sweeps stale archive entries and rebuilds the "
           f"compact index number {i} so old renders never leak into a fresh build; "
           f"the pass is idempotent and reproducible from committed state alone.",
           resolved=f"2026-05-{i:02d}")

    write(root, "changelog/_rules.md", "# Changelog contract\n\n## Entry structure\n")
    write(root, "changelog/v1.md", "# v1\n\n- shipped the seed.\n")
    write(root, "changelog/v2.md", "# v2\n\n- shipped more.\n")

    write(root, "pack-ops/session-state.json", json.dumps({
        "schema": "pack-session-state/1",
        "boundary_commit": "abc1234",
        "checkpoint": "2026-07-19T00:00:00Z",
        "active": ["BD-101 widget alignment engine in flight; next the debounce."],
        "in_flight_agents": [],
        "queue": ["BD-102", "BD-103"],
        "parallelization": "none — single track.",
        "wave": "implementation.",
        "pending_decisions": [],
        "cycle_position": "coding.",
    }, indent=2))

    write(root, "pack-ops/DASHBOARD-SPEC-PACK.md",
          "# Build spec (fixture)\n\nR2: fresh state every build.\n")

    # A minimal core.py carrying only the required-keys tuple (structure-sha input).
    write(root, "scripts/lib/validate_checks/core.py",
          "_SESSION_STATE_REQUIRED_KEYS = (\n"
          "    'schema', 'boundary_commit', 'checkpoint', 'active',\n"
          "    'in_flight_agents', 'queue', 'parallelization', 'wave',\n"
          "    'pending_decisions', 'cycle_position',\n"
          ")\n")

    write(root, "CLAUDE.md",
          "# CLAUDE.md\n\n## Pack memory\n\n"
          "- **First rule.** body.\n"
          "- **Second rule.** body.\n"
          "- **Third rule.** body.\n\n"
          "## Next section\n\ntail.\n")
    write(root, "pack-ops/HELP-FRAGMENT-PACK.md", "- `/pack-help` — the help.\n")
    write(root, "README.md", "# Pack\n\n| v11.0 | current |\n")


def read_state(root):
    html = (root / "pack-ops/dashboard-approvals/dashboard.html").read_text(encoding="utf-8")
    m = STATE_RE.search(html)
    return html, m, json.loads(m.group(2))


def write_state(root, html, m, state):
    txt = json.dumps(state, sort_keys=True, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")
    new_html = html[:m.start(2)] + txt + html[m.end(2):]
    (root / "pack-ops/dashboard-approvals/dashboard.html").write_text(new_html, encoding="utf-8")


def fresh_built():
    d = pathlib.Path(tempfile.mkdtemp(prefix="dbuild-"))
    make_fixture(d)
    # The backlog enumeration reads the git-TRACKED set (`git ls-files backlog/`),
    # so the fixture must be a committed git work tree — build/verify fail-closed
    # OFF a work tree (no raw-FS fallback). The Group 2/3 mutations below edit
    # TRACKED files in place, so the committed enumeration keeps returning them.
    def git(*a):
        return subprocess.run(["git", *a], cwd=d, capture_output=True, text=True)
    git("init", "-q")
    git("config", "user.email", "t@t.t")
    git("config", "user.name", "t")
    git("add", "-A")
    git("commit", "-q", "-m", "fixture: seed backlog tree")
    rc, out = run_mode("build", d)
    if rc != 0:
        failures.append(f"setup build failed (rc={rc}): {out}")
    return d


def expect_verify_fail(label, mutate, want_substr=None):
    d = fresh_built()
    try:
        mutate(d)
        rc, out = run_mode("verify", d)
        if rc == 0:
            failures.append(f"{label}: verify unexpectedly PASSED (rc=0): {out}")
        elif want_substr and want_substr not in out:
            failures.append(f"{label}: verify FAILed but missing '{want_substr}': {out}")
    finally:
        shutil.rmtree(d, ignore_errors=True)


def a_full_id(state):
    return sorted(k for k, v in state["bds"].items() if v.get("tier") == "full")[0]


# ── Group 1: conformant build + verify PASS ──────────────────────────────────
d = fresh_built()
try:
    rc, out = run_mode("verify", d)
    if rc != 0:
        failures.append(f"G1 conformant verify expected rc=0, got {rc}: {out}")
    if "verify: PASS" not in out:
        failures.append(f"G1 conformant verify missing 'verify: PASS': {out}")
    # sanity: |E_full| == 13 (3 non-terminal + 10 newest resolved) with tier:full
    _, _, st = read_state(d)
    full = [k for k, v in st["bds"].items() if v.get("tier") == "full"]
    if len(full) != 13:
        failures.append(f"G1 expected 13 tier:full, got {len(full)}: {sorted(full)}")
finally:
    shutil.rmtree(d, ignore_errors=True)


# ── Group 2: degraded #state mutations (render-side) → FAIL ──────────────────
def mut_short_body(d):
    html, m, st = read_state(d)
    st["bds"][a_full_id(st)]["body"] = "TBD"
    write_state(d, html, m, st)


def mut_missing_full(d):
    html, m, st = read_state(d)
    st["bds"][a_full_id(st)]["tier"] = "minimal"
    write_state(d, html, m, st)


def mut_title_echo(d):
    html, m, st = read_state(d)
    fid = a_full_id(st)
    st["bds"][fid]["body"] = st["bds"][fid]["title"]
    write_state(d, html, m, st)


def mut_dropped_bd(d):
    html, m, st = read_state(d)
    # Drop a Resolved-minimal BD that IS in the live tree → accountability fail.
    del st["bds"]["BD-201"]
    write_state(d, html, m, st)


expect_verify_fail("G2 short body", mut_short_body, "source-anchored")
expect_verify_fail("G2 missing E_full member", mut_missing_full, "E_full floor")
expect_verify_fail("G2 title-echo body", mut_title_echo, "title echo")
expect_verify_fail("G2 dropped BD", mut_dropped_bd, "dropped")


# ── Group 3: class-(c) fail-closed mutations (tree-side) → FAIL ───────────────
def mut_new_status(d):
    # Flip an existing BD to a Status absent from the _rules.md vocab.
    p = d / "backlog/BD-101.md"
    p.write_text(p.read_text().replace("Status: Open", "Status: Blocked"), encoding="utf-8")


def mut_unparseable_status(d):
    p = d / "backlog/BD-102.md"
    p.write_text(re.sub(r"^Status:.*$", "", p.read_text(), flags=re.M), encoding="utf-8")


def mut_structure_sha(d):
    p = d / "backlog/_rules.md"
    p.write_text(p.read_text() + "\n<!-- format-contract drift -->\n", encoding="utf-8")


expect_verify_fail("G3 new Status value", mut_new_status, "vocab")
expect_verify_fail("G3 unparseable Status", mut_unparseable_status, "parse-coverage")
expect_verify_fail("G3 structure-sha drift", mut_structure_sha, "structure-sha mismatch")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "conformant PASS (|E_full|=13); degraded #state FAILs (short body / missing member / title-echo / dropped BD); class-(c) FAILs (new-status vocab-closure / unparseable-status parse-coverage / structure-sha drift)" ;;
    *) t_fail "conformant/degraded/class-(c) cases failed (see Python output above)" ;;
esac
fi

# ─────────────────────────────────────────────────────────────────
# Group 4: (git-guarded) committed-history plans floor bites
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: committed-history plans floor (git-guarded) ===\n"

if ! command -v git > /dev/null 2>&1; then
    t_pass "git absent — plans-floor git case SKIPPED (lenient)"
else
SCRIPT="$SCRIPT" python3 - <<'EOF'
import os, sys, json, re, shutil, tempfile, subprocess, pathlib
SCRIPT = os.environ["SCRIPT"]
STATE_RE = re.compile(r'(<script[^>]*id="state"[^>]*>)(.*?)(</script>)', re.S)
failures = []

# Re-provision a fixture identical to the Groups 1-3 one, but as a git repo with a
# feat commit for BD-101 so `git log --grep=BD-101` yields a real landing.
d = pathlib.Path(tempfile.mkdtemp(prefix="dbuild-git-"))
try:
    def write(rel, text):
        p = d / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(text, encoding="utf-8")
    write("backlog/_rules.md",
          "# c\n\n## Lifecycle states admitted\n\n"
          "- `Open` — a.\n- `Unblocked` — b.\n- `Deferred` — c.\n"
          "- `Resolved` — d.\n- `Deprecated` — e.\n- `Cancelled` — f.\n\n## Supporting files\n")
    write("backlog/BD-101.md",
          "<!-- x -->\n**BD-101 — Widget alignment engine for the frontier board**\n"
          "Type: feat\nStatus: Open\nBlockers: none\nUnblocks: work\n"
          "Description: The widget alignment engine recomputes column offsets for "
          "every frontier row so the board stays visually coherent across "
          "breakpoints using a deterministic packing pass.\n")
    write("changelog/_rules.md", "# c\n")
    write("changelog/v1.md", "# v1\n")
    write("pack-ops/session-state.json", json.dumps({
        "schema": "pack-session-state/1", "boundary_commit": "abc1234",
        "checkpoint": "2026-07-19T00:00:00Z",
        "active": ["BD-101 widget alignment engine in flight."],
        "in_flight_agents": [], "queue": [], "parallelization": "none.",
        "wave": "impl.", "pending_decisions": [], "cycle_position": "coding.",
    }, indent=2))
    write("pack-ops/DASHBOARD-SPEC-PACK.md", "# spec\n\nR2.\n")
    write("scripts/lib/validate_checks/core.py",
          "_SESSION_STATE_REQUIRED_KEYS = ('schema','boundary_commit','checkpoint',"
          "'active','in_flight_agents','queue','parallelization','wave',"
          "'pending_decisions','cycle_position')\n")
    write("CLAUDE.md", "# c\n\n## Pack memory\n\n- **R.** b.\n\n## Next\n")
    write("pack-ops/HELP-FRAGMENT-PACK.md", "- `/pack-help` — help.\n")
    write("README.md", "# Pack v11.0\n")

    def git(*args):
        return subprocess.run(["git", *args], cwd=d, capture_output=True, text=True)
    git("init", "-q")
    git("config", "user.email", "t@t.t")
    git("config", "user.name", "t")
    git("add", "-A")
    git("commit", "-q", "-m", "feat: BD-101 widget alignment engine")

    rc = subprocess.run([sys.executable, SCRIPT, "build", "--repo-root", str(d)],
                        capture_output=True, text=True)
    if rc.returncode != 0:
        failures.append(f"git-fixture build failed: {rc.stdout}{rc.stderr}")
    html = (d / "pack-ops/dashboard-approvals/dashboard.html").read_text(encoding="utf-8")
    m = STATE_RE.search(html)
    st = json.loads(m.group(2))
    if "BD-101" not in st.get("plans", {}):
        failures.append(f"build did not floor BD-101 into plans despite its feat landing: {sorted(st.get('plans',{}))}")

    # baseline: verify PASSes with BD-101 in plans
    v0 = subprocess.run([sys.executable, SCRIPT, "verify", "--repo-root", str(d)],
                        capture_output=True, text=True)
    if v0.returncode != 0:
        failures.append(f"git-fixture baseline verify expected PASS: {v0.stdout}{v0.stderr}")

    # mutate: drop BD-101 from plans → plans floor must bite
    st["plans"].pop("BD-101", None)
    txt = json.dumps(st, sort_keys=True, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")
    (d / "pack-ops/dashboard-approvals/dashboard.html").write_text(
        html[:m.start(2)] + txt + html[m.end(2):], encoding="utf-8")
    v1 = subprocess.run([sys.executable, SCRIPT, "verify", "--repo-root", str(d)],
                        capture_output=True, text=True)
    if v1.returncode == 0:
        failures.append(f"plans-floor drop unexpectedly PASSED: {v1.stdout}{v1.stderr}")
    elif "plans floor" not in (v1.stdout + v1.stderr):
        failures.append(f"plans-floor FAIL missing 'plans floor': {v1.stdout}{v1.stderr}")
finally:
    shutil.rmtree(d, ignore_errors=True)

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
    case $? in
        0) t_pass "git plans floor: build floors a BD with a feat landing into plans{}; dropping it HARD-FAILs verify" ;;
        *) t_fail "git plans-floor case failed (see Python output above)" ;;
    esac
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"

if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
