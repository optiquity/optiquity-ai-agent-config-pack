#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-89.sh — synthetic tests for Check 89
# (the committed /pack-dashboard content floor — BD-224 OPTION-2 reconciled).
#
# Check 89 (check_dashboard_committed_floor) is the mechanical, agent-INDEPENDENT
# CI backstop for the render-cache (ARCHITECTURE-DASHBOARD-OPTION2-RECONCILED.md
# §3.4/§6.2): it re-derives E_full in its OWN module (dashboard_floor.py, sharing
# NO code with scripts/dashboard-build.py) and HARD-FLOORS the COMMITTED
# pack-ops/dashboard-approvals/dashboard.html `#state` — total accountability +
# parse-coverage, Status-vocabulary closure, the E_full full-set floor +
# source-anchored bodies, the committed-history plans floor, and the read-fresh
# section floors. DEEP-gated (PACK_VALIDATE_DEEP=1, mirroring Check 49): a ~0 ms
# SKIP on the light battery. SKIP-lenient off a git work tree / when no render is
# committed.
#
# This test is NOT fixture-dependent (it never reads test-fixtures/<NAME> — it
# `git init`s throwaway repos in /tmp REPO_ROOTs). It lives under scripts/tests/
# and auto-wires into CI via the disk glob (Check 42 / BD-219). Per "Test infra is
# self-provisioned": every case is built in a /tmp scratch git repo; the REAL tree
# is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 89 registration + count invariant (==86)
#   Group 1: Real-state-at-HEAD SKIP (no committed render): DEEP-gate SKIP without
#            PACK_VALIDATE_DEEP; render-absent SKIP with PACK_VALIDATE_DEEP=1
#   Group 2: Synthetic /tmp git-repo PASS/FAIL (monkeypatch REPO_ROOT, DEEP on):
#            - PASS: a conformant committed dashboard.html (|E_full| tier:full,
#                    source-anchored bodies, plans + section floors met)
#            - FAIL: 0 tier:full (the 0/54 incident shape) — E_full floor
#            - FAIL: a short/vacuous tier:full body — source-anchor
#            - FAIL: a dropped E_full member (an E_full id marked tier:minimal)
#            - FAIL: a blanked read-fresh section (rules[]=[])
#            - FAIL: a new Status value in the backlog (vocab-closure fail-closed)
#            - FAIL: a dropped BD (a live id absent from #state.bds) — accountability
#            - FAIL: an active BD with committed feat/fix landings absent from
#                    #state.plans — the plans floor
#   Group 3: End-to-end validate-pack.py --only-check 89 on HEAD (exit 0, SKIP)
#
# Usage: bash scripts/tests/test-validate-pack-check-89.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 89 registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 89 registration + count invariant ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_dashboard_committed_floor'):
    print('FAIL_MISSING check_dashboard_committed_floor'); sys.exit(1)
# Check 89 must be registered AND the expected-count constant must equal the
# computed registry length AND that count must be 86 (Check 59's invariant —
# proves the Check-89 add + the 85->86 count bump landed together).
reg = mod._build_check_registry()
nums = [t[0] for t in reg]
if 89 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(reg) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH', len(reg), mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
if mod.CHECK_REGISTRY_EXPECTED_COUNT != 86:
    print('FAIL_COUNT_NOT_86', mod.CHECK_REGISTRY_EXPECTED_COUNT); sys.exit(1)
print('OK')
" > /tmp/vp-check89-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check89-import.out; then
    t_pass "validate-pack.py imports + Check 89 registered + count invariant holds (==86)"
else
    t_fail "validate-pack.py import / Check 89 registration / count invariant failed" \
        "$(cat /tmp/vp-check89-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD SKIP (no committed render)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD SKIP (DEEP-gate + render-absent) ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def run(deep):
    saved = list(mod.failures); mod.failures.clear()
    prev = os.environ.get("PACK_VALIDATE_DEEP")
    if deep:
        os.environ["PACK_VALIDATE_DEEP"] = "1"
    else:
        os.environ.pop("PACK_VALIDATE_DEEP", None)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_committed_floor()
        new = list(mod.failures); cap = buf.getvalue()
    finally:
        mod.failures.clear(); mod.failures.extend(saved)
        if prev is None:
            os.environ.pop("PACK_VALIDATE_DEEP", None)
        else:
            os.environ["PACK_VALIDATE_DEEP"] = prev
    return len(new), cap

failures = []

# Without DEEP: the env-gate SKIPs before any tree read.
n, cap = run(deep=False)
if n != 0:
    failures.append(f"non-DEEP expected 0 failures, got {n}: {cap}")
if "set PACK_VALIDATE_DEEP=1" not in cap:
    failures.append(f"non-DEEP must SKIP at the DEEP env-gate: {cap}")

# With DEEP: the real tree has no committed render → render-absent SKIP-lenient.
n, cap = run(deep=True)
if n != 0:
    failures.append(f"DEEP real-state expected 0 failures, got {n}: {cap}")
if "is not tracked" not in cap or "skipping (lenient)" not in cap:
    failures.append(f"DEEP real-state must SKIP 'is not tracked' + 'skipping (lenient)': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD SKIPs (non-DEEP env-gate; DEEP render-absent lenient)" ;;
    *) t_fail "real-state Check 89 SKIP behaviour failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/FAIL tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/FAIL tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib, json
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def _patch_root(root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 89's body lives in validate_checks.dashboard_floor and
    resolves its git root via dashboard_floor.REPO_ROOT (through _git_ls_files /
    the tree reads); a facade-only patch would NOT bite (BD-256 W12 technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


def _descr(n):
    fixed = {
        1: "Alpha subsystem needs a durable retry queue so flaky regional uploads "
           "never silently drop payloads across zones.",
        2: "Beta pipeline requires idempotent checkpoints so a resumed run never "
           "double-writes downstream records under load.",
    }
    return fixed.get(
        n,
        f"Entry number {n} covers a distinct concern with ample prose to anchor a "
        f"real source body across the whole record without echoing the title.",
    )


def _run_body(root):
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(root)
    prev = os.environ.get("PACK_VALIDATE_DEEP")
    os.environ["PACK_VALIDATE_DEEP"] = "1"
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_dashboard_committed_floor()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        if prev is None:
            os.environ.pop("PACK_VALIDATE_DEEP", None)
        else:
            os.environ["PACK_VALIDATE_DEEP"] = prev
    return (len(new_failures), captured)


# Build a self-contained /tmp git repo: 14 BDs (BD-1/2 Open; BD-3..14 Resolved,
# dated), a vocab _rules.md, a 3-bullet CLAUDE.md ## Pack memory, 2 changelog
# files, a help fragment, a session-state, and a CONFORMANT committed
# dashboard.html #state — then apply the named `variant` mutation. Never touches
# the real tree. Returns (fail_count, captured_output).
def run_case(variant, extra_feat_commit=False):
    tmp = tempfile.mkdtemp(prefix="vp-check89-")
    root = pathlib.Path(tmp)
    try:
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
        subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
        (root / "backlog").mkdir()
        (root / "changelog").mkdir()
        (root / "pack-ops").mkdir()

        recs = {}
        for n in range(1, 15):
            status = "Open" if n <= 2 else "Resolved"
            lines = [f"**BD-{n} — Title of entry {n}**", "", "Type: task", "",
                     f"Status: {status}"]
            if status == "Resolved":
                lines.append(f"Resolved: 2026-01-{n:02d} landed")
            lines += ["", f"Description: {_descr(n)}", ""]
            text = "\n".join(lines)
            if variant == "new_status" and n == 1:
                text = text.replace("Status: Open", "Status: Blocked")
            (root / f"backlog/BD-{n}.md").write_text(text)
            recs[n] = status

        (root / "backlog/_rules.md").write_text(
            "# rules\n\n## Lifecycle states admitted\n\n"
            "- `Open` — active\n- `Unblocked` — ready\n- `Deferred` — later\n"
            "- `Resolved` — done\n- `Deprecated` — dead\n- `Cancelled` — dropped\n\n"
            "## Supporting files\n")
        (root / "changelog/_rules.md").write_text("changelog rules\n")
        (root / "CLAUDE.md").write_text(
            "# C\n\n## Pack memory\n\n- **Rule one.** body\n- **Rule two.** body\n"
            "- **Rule three.** body\n\n## Next\n")
        (root / "changelog/v1.md").write_text("v1\n")
        (root / "changelog/v2.md").write_text("v2\n")
        (root / "pack-ops/HELP-FRAGMENT-PACK.md").write_text("`/pack-help`\n")
        (root / "pack-ops/session-state.json").write_text(
            json.dumps({"schema": "pack-session-state/1", "active": ["working BD-1"]}))

        # Conformant #state (independent of Check 89's derivation — this is the
        # "build" side; Check 89 is the "verify" side; they must agree).
        non_term = {f"BD-{n}" for n in range(1, 15) if recs[n] in ("Open", "Unblocked", "Deferred")}
        resolved = sorted([n for n in range(1, 15) if recs[n] == "Resolved"],
                          key=lambda n: (f"2026-01-{n:02d}", n), reverse=True)
        newest = {f"BD-{n}" for n in resolved[:10]}
        e_full = non_term | newest

        bds = {}
        for n in range(1, 15):
            bid = f"BD-{n}"
            tier = "full" if bid in e_full else "minimal"
            rec = {"id": bid, "num": n, "title": f"Title of entry {n}",
                   "status": recs[n].lower(), "tier": tier, "snippet": _descr(n)[:50]}
            if tier == "full":
                rec["body"] = _descr(n)
            bds[bid] = rec

        state = {
            "metrics": {"resolved": 12, "total": 14, "pct": 86},
            "bds": bds, "plans": {},
            "rules": [{"i": i} for i in range(3)],
            "changelog": [{"i": i} for i in range(2)],
            "help": {"commands": ["pack-help"]},
        }

        if variant == "zero_full":
            for r in state["bds"].values():
                r["tier"] = "minimal"
                r.pop("body", None)
        elif variant == "short_body":
            state["bds"]["BD-1"]["body"] = "TBD"
        elif variant == "e_full_missing":
            state["bds"]["BD-2"]["tier"] = "minimal"
            state["bds"]["BD-2"].pop("body", None)
        elif variant == "blank_section":
            state["rules"] = []
        elif variant == "dropped_bd":
            del state["bds"]["BD-2"]

        state_txt = json.dumps(state, separators=(",", ":")).replace("<", "\\u003c")
        (root / "pack-ops/dashboard-approvals").mkdir()
        (root / "pack-ops/dashboard-approvals/dashboard.html").write_text(
            '<!DOCTYPE html>\n<html><body><main></main>\n'
            f'<script type="application/json" id="state">{state_txt}</script>\n'
            '</body></html>\n')

        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        subprocess.run(["git", "commit", "-q", "-m", "init fixture"], cwd=root, check=True)

        if extra_feat_commit:
            # A real feat/fix landing for the active BD-1 → git_landings(BD-1) is
            # non-empty; with plans={} the committed-history plans floor bites.
            p = root / "backlog/BD-1.md"
            p.write_text(p.read_text() + "\n<!-- touch -->\n")
            subprocess.run(["git", "commit", "-qam", "feat: v11 — BD-1 land the retry queue"],
                           cwd=root, check=True)

        return _run_body(root)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


failures = []

# T1: PASS — conformant render.
n, cap = run_case("conformant")
if n != 0:
    failures.append(f"T1 (PASS conformant) expected 0 failures, got {n}: {cap}")
if "floors satisfied" not in cap:
    failures.append(f"T1 PASS message missing 'floors satisfied': {cap}")

# T2: FAIL — 0 tier:full (the 0/54 incident shape) → E_full floor.
n, cap = run_case("zero_full")
if n < 1:
    failures.append(f"T2 (0 tier:full) expected >=1 failure, got {n}: {cap}")
if "E_full floor" not in cap:
    failures.append(f"T2 must report the 'E_full floor': {cap}")

# T3: FAIL — a short/vacuous tier:full body → source-anchor.
n, cap = run_case("short_body")
if n < 1:
    failures.append(f"T3 (short body) expected >=1 failure, got {n}: {cap}")
if "not source-anchored" not in cap:
    failures.append(f"T3 must report 'not source-anchored': {cap}")

# T4: FAIL — a dropped E_full member (E_full id marked tier:minimal).
n, cap = run_case("e_full_missing")
if n < 1:
    failures.append(f"T4 (dropped E_full member) expected >=1 failure, got {n}: {cap}")
if "E_full floor" not in cap:
    failures.append(f"T4 must report the 'E_full floor': {cap}")

# T5: FAIL — a blanked read-fresh section (rules[]=[]).
n, cap = run_case("blank_section")
if n < 1:
    failures.append(f"T5 (blank rules section) expected >=1 failure, got {n}: {cap}")
if "rules[] count" not in cap:
    failures.append(f"T5 must report the 'rules[] count' section floor: {cap}")

# T6: FAIL — a new Status value in the backlog (vocab-closure fail-closed).
n, cap = run_case("new_status")
if n < 1:
    failures.append(f"T6 (new Status value) expected >=1 failure, got {n}: {cap}")
if "fail-closed" not in cap:
    failures.append(f"T6 must fail-closed on the new Status value: {cap}")

# T7: FAIL — a dropped BD (a live id absent from #state.bds) → accountability.
n, cap = run_case("dropped_bd")
if n < 1:
    failures.append(f"T7 (dropped BD) expected >=1 failure, got {n}: {cap}")
if "dropped" not in cap:
    failures.append(f"T7 must report the dropped live BD (accountability): {cap}")

# T8: FAIL — an active BD with committed feat/fix landings absent from plans.
n, cap = run_case("conformant", extra_feat_commit=True)
if n < 1:
    failures.append(f"T8 (plans floor) expected >=1 failure, got {n}: {cap}")
if "plans floor" not in cap:
    failures.append(f"T8 must report the 'plans floor': {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1 conformant PASS; T2 0/full; T3 short body; T4 dropped E_full; T5 blank section; T6 new Status; T7 dropped BD; T8 plans floor)" ;;
    *) t_fail "Synthetic Check 89 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py --only-check 89 on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py --only-check 89 on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 89 > /tmp/vp-check89-e2e.out 2>&1; then
    if grep -q "SKIP: dashboard content-floor deep check" /tmp/vp-check89-e2e.out; then
        t_pass "validate-pack.py --only-check 89 exits 0; Check 89 runs and SKIPs (DEEP-gated) on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 89 DEEP-gate SKIP not detected" \
            "Tail: $(tail -10 /tmp/vp-check89-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD (--only-check 89)" \
        "Tail: $(tail -40 /tmp/vp-check89-e2e.out)"
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
