#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-93.sh — synthetic tests for Check 93
# (public-launch no-leak GUARD — the two-leg literal-name + domain-vocab enforcement
# backstop — BD-205).
#
# Check 93 is the BD-205 public-launch enforcement backstop: a git-ls-files scan that
# FAILs loud if the Wave-A/B scrub regresses. TWO legs:
#   LEG 1 — the target application's literal product name, TREE-WIDE: FAILs if the
#           literal appears in the CONTENT of ANY git-tracked file. Candidate set is
#           `git ls-files`; each file's BYTES are read with Python (NOT `git grep`).
#           Allowlist EMPTY (grep-zero).
#   LEG 2 — domain vocabulary + `OT` codename, CLIENT/PUBLIC surfaces only
#           (project-template/ + supporting-docs/ + .github/ + repo-root README +
#           pack-root trinity CLAUDE/AGENTS/GEMINI.md). Internal surfaces (backlog/
#           changelog/ maintenance-docs/ test-fixtures/) are NOT scanned by leg 2.
#           Allowlist: EXACTLY ONE (path -> token) mask — the `x-brokerage-api`
#           row NAME at project-template/docs/pack/PLATFORM-SKILLS.md (OI-S7 keep).
#
# declare-verify-backing: the guard BITES a re-introduced leak AND SPARES the
# legitimate keeps. This test proves both directions on scratch /tmp git repos.
#
# SELF-REFERENCE NOTE: this test file is itself a git-tracked file, so Check 93's
# leg 1 scans it in the real battery. Every scratch literal-name string is therefore
# ASSEMBLED AT RUNTIME (the two fragments are concatenated in-Python) so this file's
# literal bytes never carry the contiguous product-name token — the test never trips
# the guard it exercises. (Leg 2 does NOT scan scripts/, so the domain-vocab strings
# below — `TradingStrategy`, `brokerage`, bare `OT` — are safe as literal bytes.)
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s throwaway repos in /tmp REPO_ROOTs). It lives under
# scripts/tests/ and auto-wires into CI via the disk glob (Check 42 / BD-219). Per
# "Test infra is self-provisioned": every case is built in a /tmp scratch git repo;
# the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 93 symbol registration + DYNAMIC count invariant
#   Group 1: Real-state-at-HEAD PASS (the real tree has leg-1 0, leg-2 0-after-allowlist)
#   Group 2: Synthetic PASS/BITE/SPARE against /tmp git repos (monkeypatch REPO_ROOT):
#            - T1  PASS  : only benign client + non-client files → 0 failures + clean msg
#            - T2  BITE  : leg-1 literal on a NON-client path (notes/leak.txt) → LEG 1 fires
#            - T2b BITE  : leg-1 literal on an INTERNAL path (backlog/BD-999.md) → LEG 1
#                          fires (proves leg 1 is TREE-WIDE, not client-only)
#            - T3  BITE  : leg-2 domain vocab (TradingStrategy) on a client surface → LEG 2
#            - T4  BITE  : leg-2 bare `OT` codename on a client surface → LEG 2 (bare-OT)
#            - T5  SPARE : same vocab + bare OT on an INTERNAL surface (backlog/) → 0
#            - T6  SPARE : the allowlisted `x-brokerage-api` row on PLATFORM-SKILLS.md → 0
#            - T6b BITE  : PLATFORM-SKILLS.md with the allowlisted row PLUS a real
#                          TradingStrategy leak → LEG 2 counts EXACTLY 1 (token-precise
#                          mask: the keep is spared, the real leak bites)
#            - T6c BITE  : `x-brokerage-api` on a DIFFERENT client file (OTHER.md) →
#                          LEG 2 fires (allowlist is file-precise, not a broad exemption)
#            - T7  SPARE : `realistic-ot` / `Fake-OT` fixture names on a client surface →
#                          0 (word-boundary regex spares them, not just surface-exclusion)
#            - T8  SKIP  : REPO_ROOT at a NON-git dir → git-unavailable → SKIP-lenient
#   Group 3: End-to-end validate-pack.py --only-check 93 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-93.sh
# Exit 0 on all pass; exit 1 on any failure.

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
# Group 0: Module import + Check 93 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 93 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_no_target_app_leak'):
    print('FAIL_MISSING check_no_target_app_leak'); sys.exit(1)
# Check 93 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's DYNAMIC invariant — proves the Check-93
# add + the count bump landed together). NO hardcoded count literal here: the
# endorsed per-check-test pattern (see test-validate-pack-check-89.sh), because a
# hardcoded literal re-breaks on the NEXT check add.
nums = [t[0] for t in mod._build_check_registry()]
if 93 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check93-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check93-import.out; then
    t_pass "validate-pack.py imports + Check 93 registered + DYNAMIC count invariant holds"
else
    t_fail "validate-pack.py import / Check 93 registration / count invariant failed" \
        "$(cat /tmp/vp-check93-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (real tree: leg-1 0, leg-2 0-after-allowlist)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Real-state-at-HEAD PASS ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []
saved = list(mod.failures); mod.failures.clear()
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf):
        mod.check_no_target_app_leak()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

if len(new) != 0:
    failures.append(f"real-state Check 93 expected 0 failures, got {len(new)}: {cap}")
if "no target-app literal-name leak" not in cap:
    failures.append(f"real-state PASS message missing clean marker: {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 93 PASSes (leg-1 0 tree-wide, leg-2 0-after-the-one-allowlist)" ;;
    *) t_fail "real-state Check 93 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo PASS/BITE/SPARE tests ===\n"

REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib, shutil, subprocess, io, contextlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule. Check 93's body lives in validate_checks.no_leak and resolves its
    git root via no_leak.REPO_ROOT (through _git_ls_files); a facade-only patch
    would NOT bite."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root

# Assemble the literal product name AT RUNTIME from two fragments so this test
# file's literal bytes never carry the contiguous product-name token (leg 1 scans
# this tracked file in the real battery).
LIT = "Optiquity" + "Trader"
LEAK_LINE = 'ref = "' + LIT + '"'          # a line carrying the literal name

# leg-2 domain-vocab / bare-OT strings (safe as literal bytes here — leg 2 never
# scans scripts/).
VOCAB_LINE = "This defines a TradingStrategy for the demo."
BARE_OT_LINE = "The OT codename appears standalone here."
FIXTURE_NAMES_LINE = "Fixtures: realistic-ot and the Fake-OT variant are keeps."
# The allowlisted `x-brokerage-api` custom-skill row (OI-S7 keep) — the only vocab
# on the line is `brokerage` inside the reserved row name.
ALLOW_ROW = "| `x-brokerage-api` | external-service adapter patterns | Communication Protocols | reviewer |"

SKILLS_PATH = "project-template/docs/pack/PLATFORM-SKILLS.md"

failures = []

def run_check(files):
    """git init a /tmp repo, write+track `files` (relpath -> content), run Check 93
    against it via monkeypatched REPO_ROOT. Returns (failures_count, captured)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check93-")
    root = pathlib.Path(tmpdir)
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
    (root / "README.md").write_text("scratch\n")
    for rel, content in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_no_target_app_leak()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

def run_check_nongit():
    tmpdir = tempfile.mkdtemp(prefix="vp-check93-nongit-")
    root = pathlib.Path(tmpdir)
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_no_target_app_leak()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# T1: PASS — benign client + non-client files, no leak → 0 failures + clean message.
fc, cap = run_check({
    "notes/plain.txt": "nothing to see here\n",
    "project-template/ok.md": "A perfectly ordinary client doc.\n",
})
if fc != 0:
    failures.append(f"T1 (PASS — clean) expected 0 failures, got {fc}: {cap}")
if "no target-app literal-name leak" not in cap:
    failures.append(f"T1 PASS message missing clean marker: {cap}")

# T2: BITE — leg-1 literal on a NON-client path (notes/leak.txt). Leg 1 is tree-wide
# so a non-client file still bites.
fc, cap = run_check({"notes/leak.txt": LEAK_LINE + "\n"})
if fc < 1:
    failures.append(f"T2 (BITE — leg-1 non-client) expected >=1 failure, got {fc}: {cap}")
if "LEG 1" not in cap:
    failures.append(f"T2 BITE must be a LEG 1 finding: {cap}")
if "notes/leak.txt" not in cap:
    failures.append(f"T2 BITE must name notes/leak.txt: {cap}")

# T2b: BITE — leg-1 literal on an INTERNAL path (backlog/BD-999.md). Proves leg 1 is
# TREE-WIDE (internal surfaces are exempt from leg 2 but NOT from leg 1).
fc, cap = run_check({"backlog/BD-999.md": LEAK_LINE + "\n"})
if fc < 1:
    failures.append(f"T2b (BITE — leg-1 internal tree-wide) expected >=1 failure, got {fc}: {cap}")
if "LEG 1" not in cap:
    failures.append(f"T2b BITE must be a LEG 1 finding: {cap}")
if "backlog/BD-999.md" not in cap:
    failures.append(f"T2b BITE must name backlog/BD-999.md: {cap}")

# T3: BITE — leg-2 domain vocab (TradingStrategy) on a client surface.
fc, cap = run_check({"project-template/leaky.md": VOCAB_LINE + "\n"})
if fc < 1:
    failures.append(f"T3 (BITE — leg-2 vocab) expected >=1 failure, got {fc}: {cap}")
if "LEG 2" not in cap:
    failures.append(f"T3 BITE must be a LEG 2 finding: {cap}")
if "project-template/leaky.md" not in cap:
    failures.append(f"T3 BITE must name project-template/leaky.md: {cap}")

# T4: BITE — leg-2 bare `OT` codename on a client surface.
fc, cap = run_check({"supporting-docs/otref.md": BARE_OT_LINE + "\n"})
if fc < 1:
    failures.append(f"T4 (BITE — leg-2 bare-OT) expected >=1 failure, got {fc}: {cap}")
if "LEG 2" not in cap:
    failures.append(f"T4 BITE must be a LEG 2 finding: {cap}")
if "bare-OT" not in cap:
    failures.append(f"T4 BITE must name the bare-OT category: {cap}")

# T5: SPARE — the SAME vocab + bare OT on an INTERNAL surface (backlog/) → 0 failures
# (internal surfaces are not scanned by leg 2; no literal ⇒ leg 1 clean too).
fc, cap = run_check({"backlog/BD-888.md": VOCAB_LINE + "\n" + BARE_OT_LINE + "\n"})
if fc != 0:
    failures.append(f"T5 (SPARE — internal surface) expected 0 failures, got {fc}: {cap}")
if "no target-app literal-name leak" not in cap:
    failures.append(f"T5 SPARE message missing clean marker: {cap}")

# T6: SPARE — the allowlisted `x-brokerage-api` row on PLATFORM-SKILLS.md → 0 failures
# (the OI-S7 keep is masked).
fc, cap = run_check({SKILLS_PATH: ALLOW_ROW + "\n"})
if fc != 0:
    failures.append(f"T6 (SPARE — allowlisted x-brokerage-api row) expected 0 failures, got {fc}: {cap}")
if "no target-app literal-name leak" not in cap:
    failures.append(f"T6 SPARE message missing clean marker: {cap}")

# T6b: BITE — PLATFORM-SKILLS.md with the allowlisted row PLUS a REAL TradingStrategy
# leak. The mask is TOKEN-precise: the keep is spared, the real leak counts. LEG 2
# must report EXACTLY 1 leg-2 violation (the TradingStrategy line, not the row).
fc, cap = run_check({SKILLS_PATH: ALLOW_ROW + "\n" + VOCAB_LINE + "\n"})
if fc < 1:
    failures.append(f"T6b (BITE — token-precise mask) expected >=1 failure, got {fc}: {cap}")
if "LEG 2 — 1 target-domain" not in cap:
    failures.append(f"T6b must count EXACTLY 1 leg-2 leak (the keep masked, the real leak bit): {cap}")
if SKILLS_PATH not in cap:
    failures.append(f"T6b BITE must name {SKILLS_PATH}: {cap}")

# T6c: BITE — `x-brokerage-api` on a DIFFERENT client file (OTHER.md) → LEG 2 fires.
# The allowlist is keyed to PLATFORM-SKILLS.md only, NOT a broad `brokerage`
# exemption, so the same token bites elsewhere.
fc, cap = run_check({"project-template/docs/pack/OTHER.md": "See the x-brokerage-api adapter.\n"})
if fc < 1:
    failures.append(f"T6c (BITE — allowlist file-precise) expected >=1 failure, got {fc}: {cap}")
if "LEG 2" not in cap:
    failures.append(f"T6c BITE must be a LEG 2 finding: {cap}")

# T7: SPARE — `realistic-ot` / `Fake-OT` fixture names on a CLIENT surface → 0 failures.
# Proves the word-boundary regex spares them (a lowercase `-ot` and a hyphen-preceded
# `-OT` never match bare-OT), not merely that they live on an internal surface.
fc, cap = run_check({"project-template/names.md": FIXTURE_NAMES_LINE + "\n"})
if fc != 0:
    failures.append(f"T7 (SPARE — fixture names on client surface) expected 0 failures, got {fc}: {cap}")
if "no target-app literal-name leak" not in cap:
    failures.append(f"T7 SPARE message missing clean marker: {cap}")

# T8: SKIP — REPO_ROOT at a NON-git directory → git ls-files unavailable → SKIP.
fc, cap = run_check_nongit()
if fc != 0:
    failures.append(f"T8 (SKIP — non-git dir) expected 0 failures, got {fc}: {cap}")
if "skipping (lenient)" not in cap:
    failures.append(f"T8 SKIP message missing 'skipping (lenient)': {cap}")
if "git ls-files unavailable" not in cap:
    failures.append(f"T8 SKIP must report git-unavailable: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic tests (T1 clean PASS; T2 leg-1 non-client BITE; T2b leg-1 internal tree-wide BITE; T3 leg-2 vocab BITE; T4 leg-2 bare-OT BITE; T5 internal-surface SPARE; T6 allowlisted-row SPARE; T6b token-precise mask BITE=1; T6c allowlist file-precise BITE; T7 fixture-name SPARE on client surface; T8 non-git SKIP)" ;;
    *) t_fail "Synthetic Check 93 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 93 > /tmp/vp-check93-e2e.out 2>&1; then
    if grep -q "Check 93: no target-app" /tmp/vp-check93-e2e.out \
       && grep -q "no target-app literal-name leak" /tmp/vp-check93-e2e.out; then
        t_pass "validate-pack.py --only-check 93 exits 0; Check 93 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 93 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check93-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check93-e2e.out)"
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
