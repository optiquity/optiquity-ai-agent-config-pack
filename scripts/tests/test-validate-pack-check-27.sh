#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-27.sh — dedicated test for
# Check 27 (agent canonical-phrase compliance, v10.1) — BD-236 C5.
#
# Check 27 (`check_agent_canonical_phrases`, in
# scripts/lib/validate_checks/agents_skills.py) asserts that every
# project-template roster agent definition file carries the canonical
# permission-profile phrases that codify its profile. It scans THREE agent
# surfaces — .claude/agents/*.md, .codex/agents/*.toml, and the Antigravity
# client plugin bundle .agents-plugin/optiquity-agents/agents/*.md — and for
# each non-`x-` agent stem it requires:
#   - ALL of COMMON_CANONICAL_PHRASES (the 9 profile-agnostic phrases), plus
#   - the PROFILE_PHRASES for that agent's profile (read-only / write-scoped
#     / write-script), determined by `_agent_profile(stem)`.
# A file missing any required phrase FAILs, naming the phrase(s); a file with
# every required phrase present OKs.
#
# This test LOCKS IN Check 27's CURRENT presence contract (it changes NO check
# body). It proves the guard PASSes on a synthetic tree whose agent defs carry
# the full phrase set for their profile, and FAILs when a canonical phrase (or
# a profile phrase) is dropped from one surface — all in a synthetic tree (the
# real tree is never mutated). The COMMON + PROFILE phrase sets are READ FROM
# the module at runtime (mod.COMMON_CANONICAL_PHRASES / mod.PROFILE_PHRASES),
# so the test tracks the check's own SSOT rather than a hardcoded copy.
#
# Because Check 27 reads MODULE-LEVEL derived directory constants
# (CLAUDE_AGENTS_DIR / CODEX_AGENTS_DIR / OPTIQUITY_BUNDLE_AGENTS_DIR /
# SKILLS_DIR — computed at import from REPO_ROOT), the synthetic-tree harness
# patches those constants ON the agents_skills module directly (a REPO_ROOT-only
# patch would NOT redirect the already-computed dir globs). This differs from
# the Check 55/57 harness, whose bodies re-read REPO_ROOT dynamically; the
# PASS/FAIL harness helpers, shims, and exit conventions otherwise mirror
# scripts/tests/test-validate-pack-check-55.sh and
# scripts/tests/test-validate-pack-check-57.sh.
#
# Coverage:
#   Group 0: module import + Check 27 symbol registration
#            (check_agent_canonical_phrases + COMMON_CANONICAL_PHRASES +
#             PROFILE_PHRASES + _agent_profile + the three agent-dir constants)
#   Group 1: synthetic-tree end-to-end:
#            T1 PASS — three surfaces × {reviewer(RO), coder(scoped),
#                      repo-ops(script)} all carrying the full COMMON + profile
#                      phrase set → 0 failures
#            T2 FAIL — one COMMON canonical phrase dropped from one file →
#                      FAIL naming "missing canonical phrase" + the phrase
#            T3 FAIL — one PROFILE phrase dropped from a write-scoped file →
#                      FAIL naming "missing canonical phrase" + the phrase
#            T4 PASS — an x-<name> custom agent is ignored (out of scope): a
#                      phraseless x- def alongside the well-formed defs → still
#                      0 failures
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 27 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-27.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/vp-check27.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

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
printf "\n=== Group 0: Module import + Check 27 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_agent_canonical_phrases',
    'COMMON_CANONICAL_PHRASES',
    'PROFILE_PHRASES',
    '_agent_profile',
    'CLAUDE_AGENTS_DIR',
    'CODEX_AGENTS_DIR',
    'OPTIQUITY_BUNDLE_AGENTS_DIR',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
# COMMON_CANONICAL_PHRASES is documented as 'the 9' in the module + the C5
# prompt — assert the count so a silent add/drop is caught here.
if len(mod.COMMON_CANONICAL_PHRASES) != 9:
    print('FAIL_COMMON_COUNT ' + str(len(mod.COMMON_CANONICAL_PHRASES)))
    sys.exit(1)
if set(mod.PROFILE_PHRASES) != {'read-only', 'write-scoped', 'write-script'}:
    print('FAIL_PROFILE_KEYS ' + repr(sorted(mod.PROFILE_PHRASES)))
    sys.exit(1)
print('OK')
" > "$SCRATCH/import.out" 2>&1

if grep -q "^OK$" "$SCRATCH/import.out"; then
    t_pass "validate-pack.py imports + Check 27 symbols registered (COMMON=9, 3 profiles)"
else
    t_fail "validate-pack.py import or Check 27 symbol registration failed" \
        "$(cat "$SCRATCH/import.out")"
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

# Check 27's body lives in validate_checks.agents_skills and reads that
# module's derived dir constants; the facade re-exports the function but the
# body resolves its globals in agents_skills. Grab that module to patch the
# constants where the body reads them.
ASK = sys.modules['validate_checks.agents_skills']

failures = []

COMMON = list(mod.COMMON_CANONICAL_PHRASES)
PROFILE = {k: list(v) for k, v in mod.PROFILE_PHRASES.items()}

# Recognized stems, one per profile (drives _agent_profile classification).
AGENTS = {
    "reviewer": "read-only",
    "coder": "write-scoped",
    "repo-ops": "write-script",
}
# The three surfaces the check walks: (dir-key, relative-dir, glob-ext).
SURFACES = [
    ("claude", ("project-template", ".claude", "agents"), "md"),
    ("codex", ("project-template", ".codex", "agents"), "toml"),
    ("bundle", ("project-template", ".agents-plugin", "optiquity-agents", "agents"), "md"),
]


def agent_body(profile, drop=None):
    """A well-formed agent def: every COMMON phrase + every phrase for the
    given profile, each on its own line. drop (a phrase string) is omitted
    to model a missing-phrase FAIL. Check 27 keys on substring presence only,
    so the .toml surface need not be valid TOML for this check.
    (No backticks in this heredoc body: an unquoted heredoc would command-
    substitute them, as the Check-55/57 harnesses note.)"""
    phrases = list(COMMON) + list(PROFILE[profile])
    lines = ["# Synthetic agent definition (Check 27 fixture)", ""]
    for p in phrases:
        if drop is not None and p == drop:
            continue
        lines.append(p)
    lines.append("")
    lines.append("Body prose follows the profile declaration above.")
    return "\n".join(lines) + "\n"


def build_tree(root, *, overrides=None, extra_files=None):
    """overrides: {(dir-key, agent): body_text}. extra_files:
    {(dir-key, stem): body_text} for additional files (e.g. an x- custom
    agent). Every surface dir is created so the check never reports a
    'directory missing' failure."""
    overrides = overrides or {}
    extra_files = extra_files or {}
    root = pathlib.Path(root)
    for key, rel, ext in SURFACES:
        d = root.joinpath(*rel)
        d.mkdir(parents=True, exist_ok=True)
        for agent, profile in AGENTS.items():
            body = overrides.get((key, agent), agent_body(profile))
            (d / f"{agent}.{ext}").write_text(body)
        for (fkey, stem), body in extra_files.items():
            if fkey == key:
                (d / f"{stem}.{ext}").write_text(body)


def run(*, overrides=None, extra_files=None):
    tmpdir = tempfile.mkdtemp(prefix="vp-check27-")
    root = pathlib.Path(tmpdir)
    build_tree(root, overrides=overrides, extra_files=extra_files)
    # Save + patch the derived dir constants (and REPO_ROOT for relative_to)
    # on the agents_skills module where the body reads them.
    saved = {n: getattr(ASK, n) for n in (
        "REPO_ROOT", "CLAUDE_AGENTS_DIR", "CODEX_AGENTS_DIR",
        "OPTIQUITY_BUNDLE_AGENTS_DIR", "SKILLS_DIR")}
    saved_failures = list(mod.failures)
    mod.failures.clear()
    ASK.REPO_ROOT = root
    ASK.CLAUDE_AGENTS_DIR = root / "project-template" / ".claude" / "agents"
    ASK.CODEX_AGENTS_DIR = root / "project-template" / ".codex" / "agents"
    ASK.OPTIQUITY_BUNDLE_AGENTS_DIR = (
        root / "project-template" / ".agents-plugin" / "optiquity-agents" / "agents")
    # Point SKILLS_DIR at a non-existent path so the Skills-to-load extension
    # (which reads SKILLS_DIR + PLATFORM-SKILLS.md) is a no-op on the fixture.
    ASK.SKILLS_DIR = root / "project-template" / "skills"
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            ASK.check_agent_canonical_phrases()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        for k, v in saved.items():
            setattr(ASK, k, v)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap


# T1: PASS — every surface × every agent carries the full COMMON + profile set.
n, cap = run()
if n != 0:
    failures.append(f"T1 (all phrases present) expected 0 failures, got {n}: {cap}")

# T2: FAIL — drop one COMMON canonical phrase from one file. Choose a phrase
# that is not a substring of any other required phrase.
DROP_COMMON = "Trinity rule"
if DROP_COMMON not in COMMON:
    failures.append(f"T2 setup: {DROP_COMMON!r} not in COMMON_CANONICAL_PHRASES {COMMON}")
else:
    bad = agent_body("read-only", drop=DROP_COMMON)
    n, cap = run(overrides={("claude", "reviewer"): bad})
    if n < 1 or "missing canonical phrase" not in cap or DROP_COMMON not in cap:
        failures.append(
            f"T2 (dropped COMMON phrase {DROP_COMMON!r}) expected a missing-phrase "
            f"FAIL naming it, got {n}: {cap}")

# T3: FAIL — drop one PROFILE phrase from a write-scoped file.
DROP_PROFILE = "Files in scope"
if DROP_PROFILE not in PROFILE["write-scoped"]:
    failures.append(f"T3 setup: {DROP_PROFILE!r} not in PROFILE_PHRASES['write-scoped']")
else:
    bad = agent_body("write-scoped", drop=DROP_PROFILE)
    n, cap = run(overrides={("codex", "coder"): bad})
    if n < 1 or "missing canonical phrase" not in cap or DROP_PROFILE not in cap:
        failures.append(
            f"T3 (dropped PROFILE phrase {DROP_PROFILE!r}) expected a missing-phrase "
            f"FAIL naming it, got {n}: {cap}")

# T4: PASS — a custom x-<name> agent is out of scope: a deliberately phraseless
# x- def alongside the well-formed defs must NOT fail (the check skips x-*).
n, cap = run(extra_files={
    ("claude", "x-custom"): "no canonical phrases here at all\n",
    ("codex", "x-custom"): "no canonical phrases here at all\n",
    ("bundle", "x-custom"): "no canonical phrases here at all\n",
})
if n != 0:
    failures.append(f"T4 (x-* custom agent ignored) expected 0 failures, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T4 (full-phrase-set PASS + dropped-COMMON-phrase FAIL + dropped-PROFILE-phrase FAIL + x-* custom-agent ignored)" ;;
    *) t_fail "End-to-end check_agent_canonical_phrases tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 27 > "$SCRATCH/e2e.out" 2>&1; then
    if grep -q "Check 27: Agent canonical-phrase compliance" "$SCRATCH/e2e.out" \
       && grep -q "canonical phrases present" "$SCRATCH/e2e.out"; then
        t_pass "validate-pack.py exits 0; Check 27 runs and reports canonical phrases present at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 27 clean-output not detected" \
            "Tail: $(tail -10 "$SCRATCH/e2e.out")"
    fi
else
    if grep -q "Check 27: Agent canonical-phrase compliance" "$SCRATCH/e2e.out"; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 27 ran but found a violation)" \
            "Tail: $(tail -40 "$SCRATCH/e2e.out")"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 27 did not run)" \
            "Tail: $(tail -40 "$SCRATCH/e2e.out")"
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
