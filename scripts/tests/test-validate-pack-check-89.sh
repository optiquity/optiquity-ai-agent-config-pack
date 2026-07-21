#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-89.sh — synthetic tests for Check 89
# (HELP-FRAGMENT /pack-* command ↔ backing-skill parity — BD-224).
#
# Check 89 is the BD-224 bidirectional help↔skill parity gate (closing the
# advertised-but-unimplemented hole that let /pack-isolation-mode ship with no
# skill):
#   - FORWARD (help → skill): every backticked `/pack-<name>` slash row in
#     pack-ops/HELP-FRAGMENT-PACK.md must have a git-TRACKED skill at
#     <root>/skills/pack-<name>/SKILL.md in ALL THREE CLI roots
#     (.claude, .codex, .agents). Absence from ANY one root FAILs.
#   - REVERSE (skill → help): every git-TRACKED pack-*-named command skill must
#     be advertised as a `/pack-<name>` row (the reverse candidate set is
#     pack-*-named dirs only, which excludes non-command engine skills).
# git-TRACKED enumeration (git ls-files, 3 roots), O(rows), SKIP-lenient off a
# git work tree; a missing fragment FAILs.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s a throwaway repo in a /tmp REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob (Check 42 /
# BD-219). Per "Test infra is self-provisioned": every tracked-state case is built
# in a /tmp scratch git repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 89 symbol registration + DYNAMIC count invariant
#            (no hardcoded count literal — the count self-check done right).
#   Group 1: Real-state-at-HEAD PASS (the real 8-command fragment ↔ 8 backing
#            skills per root bijection holds).
#   Group 2: Synthetic /tmp git-repo cases (monkeypatch REPO_ROOT), synthetic
#            command name `pack-testonly` so the test never couples to the live 8:
#            - PASS: `/pack-testonly` row + skill in ALL 3 roots → 0 failures + OK
#            - FWD bite (partial-root): `/pack-testonly` + skill in only
#                    .claude/.codex → >=1 failure naming the missing .agents root
#            - FWD bite (total absence): `/pack-testonly` + NO skill anywhere →
#                    >=1 failure (the /pack-isolation-mode-shape defect)
#            - REV bite: skill in all 3 roots + NO `/pack-testonly` row → >=1
#                    failure naming the unadvertised skill
#            - False-positive guard: a `scripts/pack-testonly.sh` span (NOT a
#                    `/pack-` span) + NO skill → 0 failures (the anchored regex
#                    excludes the scripts/ span; locks /pack-td / /pack-tracker)
#            - Reverse engine-skill non-regression: a NON-pack-*-named
#                    render-engine skill in all 3 roots + no row → 0 failures
#                    (reverse candidate set is pack-*-named dirs only)
#            - SKIP: REPO_ROOT at a NON-git dir (no git init) → git-unavailable
#                    → SKIP-lenient
#            - Fragment-absent: git available but NO HELP-FRAGMENT-PACK.md → >=1
#                    failure (the FAIL-on-missing-fragment branch, distinct from
#                    the SKIP-lenient branch)
#   Group 3: End-to-end validate-pack.py --only-check 89 on HEAD.
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
# Group 0: Module import + Check 89 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 89 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_help_fragment_command_skill_parity'):
    print('FAIL_MISSING check_help_fragment_command_skill_parity'); sys.exit(1)
# Check 89 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's DYNAMIC invariant — proves the Check-89
# add + the count bump landed together). NO hardcoded count literal here.
nums = [t[0] for t in mod._build_check_registry()]
if 89 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > /tmp/vp-check89-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check89-import.out; then
    t_pass "validate-pack.py imports + Check 89 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 89 registration / count invariant failed" \
        "$(cat /tmp/vp-check89-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (the live 8↔8 bijection holds)
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
        mod.check_help_fragment_command_skill_parity()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

# SHOULD-1 guardrail: assert on the OK-message text (the SET is bijective), NOT
# on len(_PACK_SLASH_ROW_RE.findall(...)) (which is 10 raw, not 8 — the fragment
# duplicates /pack-help and /pack-startup).
if len(new) != 0:
    failures.append(f"real-state Check 89 expected 0 failures, got {len(new)}: {cap}")
if "bijective across all three CLI roots" not in cap:
    failures.append(f"real-state PASS message missing 'bijective across all three CLI roots': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 89 PASSes (the live /pack-* fragment ↔ backing-skill bijection holds)" ;;
    *) t_fail "real-state Check 89 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic /tmp git-repo cases (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic /tmp git-repo cases ===\n"

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
    submodule. Check 89's body lives in validate_checks.help_fragments and
    resolves its git root via help_fragments.REPO_ROOT (through
    _git_ls_files_multi and the fragment read); a facade-only patch would NOT
    bite. Setting it on every loaded validate_checks.* reaches the read wherever
    the body resolves it (BD-256 W12 wave-invariant technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


FRAG_REL = "pack-ops/HELP-FRAGMENT-PACK.md"
ROOTS = (".claude", ".codex", ".agents")

failures = []


def _run_body(root):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_help_fragment_command_skill_parity()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)


# Build a scratch git repo and run Check 89 against it. `frag_rows` is a list of
# COMPLETE backtick spans to embed in the fragment (each becomes a table row); a
# None value means DO NOT write the fragment at all (the fragment-absent case).
# `skills` maps a CLI root -> list of skill dir names to create + git-track at
# <root>/skills/<name>/SKILL.md. `do_git_init=False` skips git init entirely (the
# non-git SKIP-lenient case). Never touches the real tree.
def run_case(frag_rows, skills, do_git_init=True):
    tmpdir = tempfile.mkdtemp(prefix="vp-check89-")
    root = pathlib.Path(tmpdir)
    try:
        if do_git_init:
            subprocess.run(["git", "init", "-q"], cwd=root, check=True)
            subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=root, check=True)
            subprocess.run(["git", "config", "user.name", "t"], cwd=root, check=True)
            # A baseline tracked file so the index is non-empty either way.
            (root / "README.md").write_text("scratch\n")
            if frag_rows is not None:
                frag = root / FRAG_REL
                frag.parent.mkdir(parents=True, exist_ok=True)
                body = ["# scratch help fragment\n\n"]
                for span in frag_rows:
                    body.append(f"| {span} | test |\n")
                frag.write_text("".join(body))
            for r, names in skills.items():
                for name in names:
                    sk = root / r / "skills" / name / "SKILL.md"
                    sk.parent.mkdir(parents=True, exist_ok=True)
                    sk.write_text(f"---\nname: {name}\n---\nscratch skill body\n")
            subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


ALL3 = {r: ["pack-testonly"] for r in ROOTS}

# C1: PASS — `/pack-testonly` advertised + backed in all 3 roots → 0 failures + OK.
fc, cap = run_case(["`/pack-testonly`"], ALL3)
if fc != 0:
    failures.append(f"C1 (PASS — advertised + backed x3) expected 0 failures, got {fc}: {cap}")
if "bijective across all three CLI roots" not in cap:
    failures.append(f"C1 PASS message missing 'bijective across all three CLI roots': {cap}")

# C2: FWD bite (partial-root) — backed in .claude + .codex, OMIT .agents → >=1
# failure naming pack-testonly AND the missing .agents root.
fc, cap = run_case(["`/pack-testonly`"], {".claude": ["pack-testonly"], ".codex": ["pack-testonly"]})
if fc < 1:
    failures.append(f"C2 (FWD partial-root) expected >=1 failure, got {fc}: {cap}")
if "pack-testonly" not in cap or ".agents/skills/pack-testonly/" not in cap:
    failures.append(f"C2 FAIL must name pack-testonly + the missing '.agents/skills/pack-testonly/': {cap}")

# C3: FWD bite (total absence) — advertised but NO backing skill anywhere → >=1
# failure (the /pack-isolation-mode-shape defect this gate closes).
fc, cap = run_case(["`/pack-testonly`"], {})
if fc < 1:
    failures.append(f"C3 (FWD total absence) expected >=1 failure, got {fc}: {cap}")
if "pack-testonly" not in cap or "no backing" not in cap:
    failures.append(f"C3 FAIL must name pack-testonly + 'no backing': {cap}")

# C4: REV bite — skill in all 3 roots but NO `/pack-testonly` row → >=1 failure
# naming the unadvertised skill.
fc, cap = run_case([], ALL3)
if fc < 1:
    failures.append(f"C4 (REV bite) expected >=1 failure, got {fc}: {cap}")
if "pack-testonly" not in cap or "not advertised" not in cap:
    failures.append(f"C4 FAIL must name pack-testonly + 'not advertised': {cap}")

# C5: False-positive guard — a `scripts/pack-testonly.sh` span (NOT a `/pack-`
# span) + NO skill → 0 failures. The anchored regex excludes the scripts/ span,
# so `advertised` is empty; locks the /pack-td / /pack-tracker non-regression.
fc, cap = run_case(["`scripts/pack-testonly.sh`"], {})
if fc != 0:
    failures.append(f"C5 (scripts/ span false-positive guard) expected 0 failures, got {fc}: {cap}")

# C6: Reverse engine-skill non-regression — a NON-pack-*-named render-engine
# skill in all 3 roots + no row → 0 failures (reverse candidate set is
# pack-*-named dirs only; locks the dashboard-render engine-skill non-regression).
fc, cap = run_case([], {r: ["render-engine"] for r in ROOTS})
if fc != 0:
    failures.append(f"C6 (non-pack-* engine skill non-regression) expected 0 failures, got {fc}: {cap}")

# C7: SKIP-lenient — REPO_ROOT at a NON-git dir (no git init) → git ls-files
# unavailable → SKIP-lenient + 0 failures.
fc, cap = run_case(None, {}, do_git_init=False)
if fc != 0:
    failures.append(f"C7 (SKIP — non-git dir) expected 0 failures, got {fc}: {cap}")
if "skipping (lenient)" not in cap or "git ls-files unavailable" not in cap:
    failures.append(f"C7 SKIP must report 'git ls-files unavailable' + 'skipping (lenient)': {cap}")

# C8: Fragment-absent — git available but NO HELP-FRAGMENT-PACK.md → >=1 failure
# ('pack-root help fragment missing'). The FAIL-on-missing-fragment branch,
# distinct from the SKIP-lenient (non-git) branch above.
fc, cap = run_case(None, {})
if fc < 1:
    failures.append(f"C8 (fragment-absent) expected >=1 failure, got {fc}: {cap}")
if "pack-root help fragment missing" not in cap:
    failures.append(f"C8 FAIL must report 'pack-root help fragment missing': {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic cases (C1 PASS x3; C2 FWD partial-root; C3 FWD total absence; C4 REV bite; C5 scripts/ false-positive guard; C6 non-pack-* engine non-regression; C7 non-git SKIP; C8 fragment-absent FAIL)" ;;
    *) t_fail "Synthetic Check 89 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 89 > /tmp/vp-check89-e2e.out 2>&1; then
    if grep -q "Check 89: HELP-FRAGMENT" /tmp/vp-check89-e2e.out \
       && grep -q "bijective across all three CLI roots" /tmp/vp-check89-e2e.out; then
        t_pass "validate-pack.py --only-check 89 exits 0; Check 89 runs and reports the bijection clean on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 89 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check89-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
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
