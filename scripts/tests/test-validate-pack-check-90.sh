#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-90.sh — synthetic tests for Check 90
# (CLIENT HELP-FRAGMENT /pm-* command ↔ backing-skill parity — BD-257).
#
# Check 90 is the CLIENT analog of Check 89 (which gates the pack /pack-* rows).
# It keeps the client `/pm-<name>` rows bijective with the client command skills:
#   - FORWARD (help → skill): every backticked `/pm-<name>` slash row in
#     project-template/docs/pack/HELP-FRAGMENT.md must have a git-TRACKED skill at
#     project-template/skills/pm-<name>/SKILL.md.
#   - REVERSE (skill → help): every git-TRACKED pm-*-named command skill must be
#     advertised as a `/pm-<name>` row (the reverse candidate set is pm-*-named
#     dirs only — the pathspec excludes the ~35 non-command pooled skills sharing
#     the root).
# SINGLE template root (client skills live in ONE tree, unlike Check 89's three
# CLI roots) — so there is no per-root partition / partial-root leg. git-TRACKED
# enumeration (git ls-files, one pathspec), O(rows), SKIP-lenient off a git work
# tree; a missing fragment FAILs.
#
# This test is NOT fixture-dependent (it never reads a built test-fixtures/<NAME>
# directory — it `git init`s a throwaway repo in a $TMPDIR REPO_ROOT). It lives
# under scripts/tests/ and auto-wires into CI via the disk glob (Check 42 /
# BD-219). Per "Test infra is self-provisioned": every tracked-state case is built
# in a scratch git repo; the REAL tree is NEVER mutated.
#
# Coverage:
#   Group 0: Module import + Check 90 symbol registration + DYNAMIC count invariant
#            (no hardcoded count literal — the count self-check done right).
#   Group 1: Real-state-at-HEAD PASS (the real 10-command fragment ↔ 10 backing
#            skills bijection holds).
#   Group 2: Synthetic scratch git-repo cases (monkeypatch REPO_ROOT), synthetic
#            command name `pm-testonly` so the test never couples to the live 10:
#            - PASS: `/pm-testonly` row + skill → 0 failures + OK
#            - FWD bite (total absence): `/pm-testonly` row + NO skill → >=1
#                    failure (the advertised-but-unimplemented defect this closes)
#            - REV bite: skill + NO `/pm-testonly` row → >=1 failure naming the
#                    unadvertised skill
#            - False-positive guard: a `scripts/pm-testonly.sh` span (NOT a
#                    `/pm-` span) + NO skill → 0 failures (the anchored regex
#                    excludes the scripts/ span; locks /pm-help's scripts/ ref)
#            - Reverse non-pm-* non-regression: a NON-pm-*-named pooled skill in
#                    the root + no row → 0 failures (reverse candidate set is
#                    pm-*-named dirs only — the pathspec excludes it)
#            - SKIP: REPO_ROOT at a NON-git dir (no git init) → git-unavailable
#                    → SKIP-lenient
#            - Fragment-absent: git available but NO HELP-FRAGMENT.md → >=1
#                    failure (the FAIL-on-missing-fragment branch, distinct from
#                    the SKIP-lenient branch)
#   Group 3: End-to-end validate-pack.py --only-check 90 on HEAD.
#
# Usage: bash scripts/tests/test-validate-pack-check-90.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

# Scratch capture files (respect $TMPDIR; cleaned up on exit).
IMPORT_OUT="$(mktemp "${TMPDIR:-/tmp}/vp-check90-import.XXXXXX")"
E2E_OUT="$(mktemp "${TMPDIR:-/tmp}/vp-check90-e2e.XXXXXX")"
cleanup() { rm -f "$IMPORT_OUT" "$E2E_OUT"; }
trap cleanup EXIT

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + Check 90 symbol registration + count invariant
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 90 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not hasattr(mod, 'check_help_fragment_command_skill_parity_client'):
    print('FAIL_MISSING check_help_fragment_command_skill_parity_client'); sys.exit(1)
# Check 90 must be registered AND the expected-count constant must equal the
# computed registry length (Check 59's DYNAMIC invariant — proves the Check-90
# add + the count bump landed together). NO hardcoded count literal here.
nums = [t[0] for t in mod._build_check_registry()]
if 90 not in nums:
    print('FAIL_NOT_REGISTERED'); sys.exit(1)
if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:
    print('FAIL_COUNT_MISMATCH'); sys.exit(1)
print('OK')
" > "$IMPORT_OUT" 2>&1

if grep -q "^OK$" "$IMPORT_OUT"; then
    t_pass "validate-pack.py imports + Check 90 symbol registered + count invariant holds"
else
    t_fail "validate-pack.py import / Check 90 registration / count invariant failed" \
        "$(cat "$IMPORT_OUT")"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Real-state-at-HEAD PASS (the live /pm-* fragment ↔ skill bijection)
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
        mod.check_help_fragment_command_skill_parity_client()
    new = list(mod.failures); cap = buf.getvalue()
finally:
    mod.failures.clear(); mod.failures.extend(saved)

# Assert on the OK-message text (the SET is bijective), NOT on
# len(_PM_SLASH_ROW_RE.findall(...)) (which carries a duplicate — /pm-help
# appears twice in the fragment).
if len(new) != 0:
    failures.append(f"real-state Check 90 expected 0 failures, got {len(new)}: {cap}")
if "backing command skills bijective" not in cap:
    failures.append(f"real-state PASS message missing 'backing command skills bijective': {cap}")

if failures:
    print("FAILURES"); [print(" ", f) for f in failures]; sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "real-state-at-HEAD Check 90 PASSes (the live /pm-* fragment ↔ backing-skill bijection holds)" ;;
    *) t_fail "real-state Check 90 failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic scratch git-repo cases (monkeypatch REPO_ROOT)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic scratch git-repo cases ===\n"

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
    submodule. Check 90's body lives in validate_checks.help_fragments and
    resolves its git root via help_fragments.REPO_ROOT (through
    _git_ls_files_multi and the fragment read); a facade-only patch would NOT
    bite. Setting it on every loaded validate_checks.* reaches the read wherever
    the body resolves it (BD-256 W12 wave-invariant technique)."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


FRAG_REL = "project-template/docs/pack/HELP-FRAGMENT.md"
SKILL_ROOT = "project-template/skills"

failures = []


def _run_body(root):
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_help_fragment_command_skill_parity_client()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (len(new_failures), captured)


# Build a scratch git repo and run Check 90 against it. `frag_rows` is a list of
# COMPLETE backtick spans to embed in the fragment (each becomes a table row); a
# None value means DO NOT write the fragment at all (the fragment-absent case).
# `skills` is a list of skill dir names to create + git-track at
# <SKILL_ROOT>/<name>/SKILL.md. `do_git_init=False` skips git init entirely (the
# non-git SKIP-lenient case). Never touches the real tree.
def run_case(frag_rows, skills, do_git_init=True):
    tmpdir = tempfile.mkdtemp(prefix="vp-check90-")
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
            for name in skills:
                sk = root / SKILL_ROOT / name / "SKILL.md"
                sk.parent.mkdir(parents=True, exist_ok=True)
                sk.write_text(f"---\nname: {name}\n---\nscratch skill body\n")
            subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        return _run_body(root)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# C1: PASS — `/pm-testonly` advertised + backed → 0 failures + OK.
fc, cap = run_case(["`/pm-testonly`"], ["pm-testonly"])
if fc != 0:
    failures.append(f"C1 (PASS — advertised + backed) expected 0 failures, got {fc}: {cap}")
if "backing command skills bijective" not in cap:
    failures.append(f"C1 PASS message missing 'backing command skills bijective': {cap}")

# C2: FWD bite (total absence) — advertised but NO backing skill → >=1 failure
# (the advertised-but-unimplemented defect this gate closes).
fc, cap = run_case(["`/pm-testonly`"], [])
if fc < 1:
    failures.append(f"C2 (FWD total absence) expected >=1 failure, got {fc}: {cap}")
if "pm-testonly" not in cap or "no backing" not in cap:
    failures.append(f"C2 FAIL must name pm-testonly + 'no backing': {cap}")

# C3: REV bite — skill exists but NO `/pm-testonly` row → >=1 failure naming the
# unadvertised skill.
fc, cap = run_case([], ["pm-testonly"])
if fc < 1:
    failures.append(f"C3 (REV bite) expected >=1 failure, got {fc}: {cap}")
if "pm-testonly" not in cap or "not advertised" not in cap:
    failures.append(f"C3 FAIL must name pm-testonly + 'not advertised': {cap}")

# C4: False-positive guard — a `scripts/pm-testonly.sh` span (NOT a `/pm-` span)
# + NO skill → 0 failures. The anchored regex excludes the scripts/ span, so
# `advertised` is empty; locks the /pm-help scripts/ ref non-regression.
fc, cap = run_case(["`scripts/pm-testonly.sh`"], [])
if fc != 0:
    failures.append(f"C4 (scripts/ span false-positive guard) expected 0 failures, got {fc}: {cap}")

# C5: Reverse non-pm-* non-regression — a NON-pm-*-named pooled skill in the root
# + no row → 0 failures (reverse candidate set is pm-*-named dirs only; the
# pathspec excludes it — locks the non-command pooled-skill non-regression).
fc, cap = run_case([], ["swift-concurrency-patterns"])
if fc != 0:
    failures.append(f"C5 (non-pm-* pooled skill non-regression) expected 0 failures, got {fc}: {cap}")

# C6: SKIP-lenient — REPO_ROOT at a NON-git dir (no git init) → git ls-files
# unavailable → SKIP-lenient + 0 failures.
fc, cap = run_case(None, [], do_git_init=False)
if fc != 0:
    failures.append(f"C6 (SKIP — non-git dir) expected 0 failures, got {fc}: {cap}")
if "skipping (lenient)" not in cap or "git ls-files unavailable" not in cap:
    failures.append(f"C6 SKIP must report 'git ls-files unavailable' + 'skipping (lenient)': {cap}")

# C7: Fragment-absent — git available but NO HELP-FRAGMENT.md → >=1 failure
# ('client help fragment missing'). The FAIL-on-missing-fragment branch,
# distinct from the SKIP-lenient (non-git) branch above.
fc, cap = run_case(None, [])
if fc < 1:
    failures.append(f"C7 (fragment-absent) expected >=1 failure, got {fc}: {cap}")
if "client help fragment missing" not in cap:
    failures.append(f"C7 FAIL must report 'client help fragment missing': {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic cases (C1 PASS; C2 FWD total absence; C3 REV bite; C4 scripts/ false-positive guard; C5 non-pm-* pooled non-regression; C6 non-git SKIP; C7 fragment-absent FAIL)" ;;
    *) t_fail "Synthetic Check 90 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 90 > "$E2E_OUT" 2>&1; then
    if grep -q "Check 90: client HELP-FRAGMENT" "$E2E_OUT" \
       && grep -q "backing command skills bijective" "$E2E_OUT"; then
        t_pass "validate-pack.py --only-check 90 exits 0; Check 90 runs and reports the bijection clean on HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 90 output not detected" \
            "Tail: $(tail -10 "$E2E_OUT")"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 "$E2E_OUT")"
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
