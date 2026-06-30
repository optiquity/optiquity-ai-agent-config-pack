#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-52.sh — dedicated test for
# BD-197 Check 52 (pack RW/RO two-class consistency, Guard-B).
#
# Check 52 asserts SET-EQUALITY between the PACK-AGENTS roster `Class`
# cells and the per-agent-file PROSE mandate headers, for the 5 pack
# agents × 3 CLIs. It BINDS TO THE PROSE HEADER, NEVER `tools:`
# (`pack-reviewer` carries `Write, Edit` yet is RO). This test proves
# the guard PASSes on the well-formed tree and FAILs on injected
# class mismatches / missing headers in a synthetic tree.
#
# Coverage:
#   Group 0: module import + Check 52 symbol registration
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS — roster + 15 headers consistent (1 RW + 4 RO)
#            T2 FAIL — roster pack-coder RW->RO (roster≠header mismatch)
#            T3 FAIL — a pack-coder header flipped RW->RO (header≠roster)
#            T4 FAIL — an RO agent's prose header stripped (unclassified)
#            T5 PASS — proves the guard binds to the PROSE header, NOT
#                      `tools:`: an RO agent file given write-capable
#                      `tools:`/sandbox but keeping its RO header stays RO
#            T6 FAIL — an agent missing a roster Class cell
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 52 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-52.sh

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
printf "\n=== Group 0: Module import + Check 52 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = ['check_pack_rw_ro_two_class']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check52-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check52-import.out; then
    t_pass "validate-pack.py imports + Check 52 symbol registered"
else
    t_fail "validate-pack.py import or Check 52 symbol registration failed" \
        "$(cat /tmp/vp-check52-import.out)"
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

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W3 wave-invariant). The check body now lives in
    validate_checks.discipline_parity and reads discipline_parity.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

RW_HDR = mod._CHECK_52_RW_HEADER  # **Source-write within scope.**
RO_HDR = mod._CHECK_52_RO_HEADER  # **Read-only.**

# A well-formed roster table: 1 RW (pack-coder) + 4 RO.
GOOD_ROSTER = (
    "# PACK-AGENTS.md\n\n"
    "## Pack agents\n\n"
    "| Agent | Class | Role | Mode |\n"
    "|---|---|---|---|\n"
    "| \`pack-architect\` | RO | Architecture | Read-only |\n"
    "| \`pack-planner\` | RO | Planning | Read-only |\n"
    "| \`pack-coder\` | RW | Implementation | Source-write |\n"
    "| \`pack-reviewer\` | RO | Review | Read-only |\n"
    "| \`pack-docs-researcher\` | RO | Docs | Read-only |\n"
)

# Per-agent body templates. The RO reviewer body deliberately carries a
# write-capable tools line to PROVE the guard ignores tools: and keys on
# the prose header.
def agent_body(header, tools_line=""):
    return (
        ("tools: " + tools_line + "\n" if tools_line else "")
        + "You are a pack agent.\n\n"
        + header + " mandate prose.\n"
    )

def build_tree(root, *, roster=GOOD_ROSTER, headers=None, drop_header_for=None,
               extra_tools_for=None):
    root = pathlib.Path(root)
    (root / "pack-ops").mkdir(parents=True, exist_ok=True)
    (root / "pack-ops" / "PACK-AGENTS.md").write_text(roster)
    # Default header class per agent.
    default = {
        "pack-architect": RO_HDR, "pack-planner": RO_HDR,
        "pack-coder": RW_HDR, "pack-reviewer": RO_HDR,
        "pack-docs-researcher": RO_HDR,
    }
    if headers:
        default.update(headers)
    for d, ext in mod._CHECK_52_AGENT_DIRS:
        (root / d).mkdir(parents=True, exist_ok=True)
        for a in mod._CHECK_52_PACK_AGENTS:
            hdr = default[a]
            tools = "Read, Grep, Glob, Bash"
            if extra_tools_for and a == extra_tools_for:
                tools = "Read, Grep, Glob, Bash, Write, Edit, MultiEdit"
            body = agent_body(hdr, tools)
            if drop_header_for and a == drop_header_for and \
               (not extra_tools_for or True):
                # Strip the recognized header (keep tools) -> unclassified.
                body = ("tools: " + tools + "\n"
                        "You are a pack agent.\n\n(no recognized header)\n")
            (root / d / f"{a}.{ext}").write_text(body)

def run(build_kwargs):
    tmpdir = tempfile.mkdtemp(prefix="vp-check52-")
    root = pathlib.Path(tmpdir)
    build_tree(root, **build_kwargs)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_pack_rw_ro_two_class()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return len(new_failures), captured

# T1: PASS — roster + 15 headers consistent.
fc, cap = run(dict())
if fc != 0:
    failures.append(f"T1 (all consistent PASS) expected 0 failures, got {fc}: {cap}")

# T2: FAIL — roster pack-coder RW->RO (roster != header).
bad_roster = GOOD_ROSTER.replace("| \`pack-coder\` | RW |",
                                 "| \`pack-coder\` | RO |", 1)
assert bad_roster != GOOD_ROSTER
fc, cap = run(dict(roster=bad_roster))
if fc < 1 or "MISMATCH" not in cap or "pack-coder" not in cap:
    failures.append(f"T2 (roster RW->RO mismatch) expected mismatch failure, got {fc}: {cap}")

# T3: FAIL — flip a pack-coder HEADER RW->RO (header != roster).
fc, cap = run(dict(headers={"pack-coder": RO_HDR}))
if fc < 1 or "MISMATCH" not in cap:
    failures.append(f"T3 (header RW->RO mismatch) expected mismatch failure, got {fc}: {cap}")

# T4: FAIL — strip an RO agent's prose header (unclassified).
fc, cap = run(dict(drop_header_for="pack-reviewer"))
if fc < 1 or "no single recognized prose mandate header" not in cap:
    failures.append(f"T4 (stripped header) expected unclassified failure, got {fc}: {cap}")

# T5: PASS — binds to PROSE header NOT tools:. Give the RO reviewer a
# write-capable tools line; with its RO header intact it stays RO -> 0 fails.
fc, cap = run(dict(extra_tools_for="pack-reviewer"))
if fc != 0:
    failures.append(f"T5 (RO-despite-write-tools binds to prose header) expected 0 failures, got {fc}: {cap}")

# T6: FAIL — an agent missing a roster Class cell.
missing_roster = GOOD_ROSTER.replace(
    "| \`pack-planner\` | RO | Planning | Read-only |\n",
    "| \`pack-planner\` | Planning | Read-only |\n", 1)
assert missing_roster != GOOD_ROSTER
fc, cap = run(dict(roster=missing_roster))
if fc < 1:
    failures.append(f"T6 (missing roster Class) expected a failure, got {fc}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T6 (consistency PASS + injected mismatches + binds-to-prose-header-not-tools)" ;;
    *) t_fail "End-to-end check_pack_rw_ro_two_class tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 52 > /tmp/vp-check52-e2e.out 2>&1; then
    if grep -q "Check 52: BD-197 pack RW/RO two-class consistency" /tmp/vp-check52-e2e.out \
       && grep -q "Check 52 — pack RW/RO two-class set-equality holds" /tmp/vp-check52-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 52 runs and reports set-equality clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 52 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check52-e2e.out)"
    fi
else
    if grep -q "Check 52: BD-197 pack RW/RO two-class consistency" /tmp/vp-check52-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 52 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check52-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 52 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check52-e2e.out)"
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
