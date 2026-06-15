#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-55.sh — dedicated test for
# BD-197 Check 55 (project RW/RO two-class consistency, Guard-B project).
#
# Check 55 asserts SET-EQUALITY across the THREE project legs:
#   {PM-CHAT `## Permission profiles` Read-only rows}
#     ↔ {project-template/agent-run.sh READONLY_AGENTS array}
#     ↔ {per-agent-file PROSE mandate headers}
# and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
# agents × 3 CLIs. It BINDS TO THE PROSE HEADER, NEVER `tools:` (project RO
# agents like `reviewer`/`architect`/`auditor` carry `Write, Edit` yet are
# RO; the Gemini files carry NO `tools:` field at all). This test proves the
# guard PASSes on the well-formed tree and FAILs on injected mismatches in
# each of the three legs, in a synthetic tree (the real tree is never
# mutated).
#
# Coverage:
#   Group 0: module import + Check 55 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS — PM-CHAT (14 RO + 2 RW) + READONLY_AGENTS (14) +
#                      48 headers all consistent
#            T2 FAIL — PM-CHAT leg: an RO row flipped to Write-capable
#                      (PM-CHAT RO set ≠ expected)
#            T3 FAIL — READONLY_AGENTS leg: an RO agent dropped from the
#                      array (array RO set ≠ expected)
#            T4 FAIL — header leg: a `coder` (RW) header flipped to RO
#                      (header ≠ expected class)
#            T5 FAIL — an RO agent's prose header stripped (unclassified)
#            T6 PASS — proves the guard binds to the PROSE header, NOT
#                      `tools:`: an RO agent given a write-capable
#                      `tools:` line but keeping its RO header stays RO
#            T7 PASS — proves the guard works when the agent file has NO
#                      `tools:` field at all (the Gemini case): RO header
#                      alone classifies it RO
#            T8 FAIL — READONLY_AGENTS lists a stray unknown agent token
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 55 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-55.sh

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
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 55 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_project_rw_ro_two_class']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check55-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check55-import.out; then
    t_pass "validate-pack.py imports + Check 55 symbol registered"
else
    t_fail "validate-pack.py import or Check 55 symbol registration failed" \
        "$(cat /tmp/vp-check55-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

BT = chr(96)  # literal backtick (avoids heredoc escaping pitfalls)
RO_HDR = mod._CHECK_55_RO_HEADER             # **Read-only.**
RW_SCOPED = mod._CHECK_55_RW_HEADERS[0]      # **Write-capable (scoped).**
RW_SCRIPT = mod._CHECK_55_RW_HEADERS[1]      # **Write-capable (script).**
AGENTS = list(mod._CHECK_55_PROJECT_AGENTS)
RW = set(mod._CHECK_55_RW_AGENTS)            # {coder, repo-ops}
RO_AGENTS = [a for a in AGENTS if a not in RW]

# Default header class per agent (the well-formed tree).
def default_headers():
    d = {a: RO_HDR for a in RO_AGENTS}
    d["coder"] = RW_SCOPED
    d["repo-ops"] = RW_SCRIPT
    return d

# A well-formed PM-CHAT profile table: 14 RO + coder (scoped) + repo-ops (script).
def pm_chat_text(ro_override=None):
    ro_set = set(RO_AGENTS)
    if ro_override is not None:
        ro_set = ro_override
    rows = ["# PM-CHAT.md\n", "## Permission profiles\n",
            "### Profile assignment\n",
            "| Agent | Profile |", "|---|---|"]
    for a in AGENTS:
        if a == "coder":
            prof = "Write-capable (scoped)"
        elif a == "repo-ops":
            prof = "Write-capable (script)"
        elif a in ro_set:
            prof = "Read-only"
        else:
            prof = "Write-capable (scoped)"
        rows.append("| " + BT + a + BT + " | " + prof + " |")
    return "\n".join(rows) + "\n"

# A well-formed agent-run.sh READONLY_AGENTS array (the 14 RO agents).
def agent_run_text(ro_list=None, extra_token=None):
    items = ro_list if ro_list is not None else list(RO_AGENTS)
    body = "READONLY_AGENTS=(\n"
    for a in items:
        body += f"    {a}\n"
    if extra_token:
        body += f"    {extra_token}\n"
    body += ")\n"
    return "#!/usr/bin/env bash\n" + body

# Per-agent body. tools_line optional (the Gemini files have none).
def agent_body(header, tools_line=None):
    out = ""
    if tools_line is not None:
        out += "tools: " + tools_line + "\n"
    out += "You are a project agent.\n\n" + header + " mandate prose.\n"
    return out

def build_tree(root, *, pm_text=None, run_text=None, headers=None,
               drop_header_for=None, extra_tools_for=None, no_tools=False):
    root = pathlib.Path(root)
    (root / "project-template" / "docs" / "pack").mkdir(parents=True, exist_ok=True)
    (root / "project-template" / "docs" / "pack" / "PM-CHAT.md").write_text(
        pm_text if pm_text is not None else pm_chat_text())
    (root / "project-template").mkdir(parents=True, exist_ok=True)
    (root / "project-template" / "agent-run.sh").write_text(
        run_text if run_text is not None else agent_run_text())
    hdrs = default_headers()
    if headers:
        hdrs.update(headers)
    for d, ext in mod._CHECK_55_AGENT_DIRS:
        (root / d).mkdir(parents=True, exist_ok=True)
        for a in AGENTS:
            hdr = hdrs[a]
            # Default: a benign read-only tools line (mirrors real claude/codex).
            tools = None if no_tools else "Read, Grep, Glob, Bash"
            if extra_tools_for and a == extra_tools_for:
                tools = "Read, Grep, Glob, Bash, Write, Edit, MultiEdit"
            if drop_header_for and a == drop_header_for:
                # Strip the recognized header -> unclassified.
                body = agent_body("(no recognized header)", tools)
                body = body.replace("(no recognized header) mandate prose.",
                                    "no recognized mandate header here")
            else:
                body = agent_body(hdr, tools)
            (root / d / f"{a}.{ext}").write_text(body)

def run(build_kwargs):
    tmpdir = tempfile.mkdtemp(prefix="vp-check55-")
    root = pathlib.Path(tmpdir)
    build_tree(root, **build_kwargs)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_rw_ro_two_class()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

# T1: PASS — all three legs consistent (14 RO + 2 RW; 48 headers).
fc, cap = run(dict())
if fc != 0:
    failures.append(f"T1 (all consistent PASS) expected 0 failures, got {fc}: {cap}")

# T2: FAIL — PM-CHAT leg: drop an RO agent from the RO set (its row becomes
# Write-capable) -> PM-CHAT RO set != expected.
bad_ro = set(RO_AGENTS) - {"reviewer"}
fc, cap = run(dict(pm_text=pm_chat_text(ro_override=bad_ro)))
if fc < 1 or "PM-CHAT" not in cap or "Read-only rows" not in cap:
    failures.append(f"T2 (PM-CHAT RO row flipped) expected PM-CHAT-leg failure, got {fc}: {cap}")

# T3: FAIL — READONLY_AGENTS leg: drop an RO agent from the array.
short_run = [a for a in RO_AGENTS if a != "planner"]
fc, cap = run(dict(run_text=agent_run_text(ro_list=short_run)))
if fc < 1 or "READONLY_AGENTS" not in cap:
    failures.append(f"T3 (READONLY_AGENTS dropped) expected array-leg failure, got {fc}: {cap}")

# T4: FAIL — header leg: flip coder (RW) header to RO.
fc, cap = run(dict(headers={"coder": RO_HDR}))
if fc < 1 or "MISMATCH" not in cap or "coder" not in cap:
    failures.append(f"T4 (coder header RW->RO mismatch) expected mismatch, got {fc}: {cap}")

# T5: FAIL — strip an RO agent's prose header (unclassified).
fc, cap = run(dict(drop_header_for="auditor"))
if fc < 1 or "no single recognized prose mandate header" not in cap:
    failures.append(f"T5 (stripped header) expected unclassified failure, got {fc}: {cap}")

# T6: PASS — binds to PROSE header NOT tools:. Give the RO reviewer a
# write-capable tools line; with its RO header intact it stays RO -> 0 fails.
fc, cap = run(dict(extra_tools_for="reviewer"))
if fc != 0:
    failures.append(f"T6 (RO-despite-write-tools binds to prose header) expected 0 failures, got {fc}: {cap}")

# T7: PASS — the Gemini case: agent files with NO tools: field at all. The RO
# header alone classifies them RO; the guard never needs tools:.
fc, cap = run(dict(no_tools=True))
if fc != 0:
    failures.append(f"T7 (no tools: field at all, Gemini case) expected 0 failures, got {fc}: {cap}")

# T8: FAIL — READONLY_AGENTS lists a stray unknown agent token.
fc, cap = run(dict(run_text=agent_run_text(extra_token="x-bogus")))
if fc < 1 or "unknown agent" not in cap:
    failures.append(f"T8 (stray array token) expected stray-token failure, got {fc}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T8 (three-leg consistency PASS + injected per-leg mismatches + binds-to-prose-header-not-tools + no-tools-field case)" ;;
    *) t_fail "End-to-end check_project_rw_ro_two_class tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 55 > /tmp/vp-check55-e2e.out 2>&1; then
    if grep -q "Check 55: BD-197 project RW/RO two-class consistency" /tmp/vp-check55-e2e.out \
       && grep -q "Check 55 — project RW/RO two-class set-equality holds" /tmp/vp-check55-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 55 runs and reports set-equality clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 55 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check55-e2e.out)"
    fi
else
    if grep -q "Check 55: BD-197 project RW/RO two-class consistency" /tmp/vp-check55-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 55 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check55-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 55 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check55-e2e.out)"
    fi
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
