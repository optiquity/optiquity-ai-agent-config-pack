#!/usr/bin/env bash
# scripts/tests/test-validate-pack-checks-36-37-38.sh — synthetic
# fixture tests for BD-175 boundary-prevention CI checks.
#
# These are unit-style fixture tests that exercise the per-check
# detection logic without needing real git history or real
# project-template edits. Each test stages a synthetic input,
# invokes the corresponding check function, and asserts FAIL or
# PASS as expected per Architect C §12 measurable-tests table.
#
# Usage: bash scripts/tests/test-validate-pack-checks-36-37-38.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/scripts/tests/fixtures/boundary-checks"
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
# Group 0: validate-pack.py imports cleanly + the new check
# functions are reachable.
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + check-function registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_commit_scope_honesty',
    'check_project_side_deny_list',
    'check_pack_only_file_siting',
    '_subject_has_keyword',
    '_is_pack_only_path',
    '_is_project_side_path',
    '_is_pm_only_permitted',
    '_context_has_anchor',
    '_read_boundary_exempt_root',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-import-check.out 2>&1

if grep -q "^OK$" /tmp/vp-import-check.out; then
    t_pass "validate-pack.py imports + Check 36/37/38 functions registered"
else
    t_fail "validate-pack.py import or check-function registration failed" \
        "$(cat /tmp/vp-import-check.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Check 36 keyword detection + scope rules
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: Check 36 subject-keyword + scope-rule unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Helper: assert match / no-match
def assert_match(subject, keywords, expected, label):
    actual = mod._subject_has_keyword(subject, keywords)
    if actual != expected:
        failures.append(f"{label}: subject={subject!r} expected={expected} actual={actual}")

# T1: pack-only keyword detected
assert_match("feat: pack-only — internal cleanup", mod._SCOPE_KEYWORDS_PACK_ONLY, True, "T1")
# T2: project-only keyword detected
assert_match("feat: project-only — coder.md update", mod._SCOPE_KEYWORDS_PROJECT_ONLY, True, "T2")
# T3: PM-only keyword detected (both forms)
assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3a")
assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3b")
# T4: no keyword — implicit scope (all return False)
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T4a")
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PROJECT_ONLY, False, "T4b")
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PM_ONLY, False, "T4c")
# T5: keyword embedded in a larger word should NOT match (boundary anchor)
assert_match("feat: pack-only-ish thing", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T5 (embedded)")

# Scope-rule tests: PM-only PERMITTED-PATHS
# T6: project-template trinity IS PM-only-permitted (B1 cascade fix)
def assert_pm(path, expected, label):
    actual = mod._is_pm_only_permitted(path)
    if actual != expected:
        failures.append(f"{label}: path={path!r} expected={expected} actual={actual}")

assert_pm("project-template/CLAUDE.md", True, "T6a")
assert_pm("project-template/AGENTS.md", True, "T6b")
assert_pm("project-template/GEMINI.md", True, "T6c")
assert_pm("pack-ops/BACKLOG.md", True, "T6d")
assert_pm("pack-ops/CHANGELOG.md", True, "T6e")
assert_pm("pack-ops/PACK-CHAT.md", True, "T6f")
assert_pm("pack-ops/PACK-AGENTS.md", True, "T6g")
assert_pm("README.md", True, "T6h")
assert_pm("CLAUDE.md", True, "T6i")  # pack-root trinity
# T7: supporting-docs is NOT PM-only-permitted (the V2-shape fixture)
assert_pm("supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md", False, "T7a")
assert_pm("project-template/docs/pack/PM-CHAT.md", False, "T7b")  # docs/pack, not trinity
assert_pm("scripts/init-project.sh", False, "T7c")
# T8: per-entry tree directories are PM-only-permitted
assert_pm("backlog/BD-175.md", True, "T8a")
assert_pm("changelog/v11.0.md", True, "T8b")
assert_pm("project-template/docs/project/backlog/_rules.md", True, "T8c")

# Scope-rule tests: project-side vs pack-only path classification
def assert_pside(path, expected, label):
    actual = mod._is_project_side_path(path)
    if actual != expected:
        failures.append(f"{label}: path={path!r} expected_proj={expected} actual={actual}")

# T9: project-template/ is project-side
assert_pside("project-template/CLAUDE.md", True, "T9a")
assert_pside("project-template/skills/review/SKILL.md", True, "T9b")
# T10: supporting-docs/ is project-side
assert_pside("supporting-docs/METHODOLOGY.md", True, "T10")
# T11: pack-ops/, scripts/, maintenance-docs/ are pack-only
assert_pside("pack-ops/BACKLOG.md", False, "T11a")
assert_pside("scripts/foo.sh", False, "T11b")
assert_pside("maintenance-docs/v11-implementation/PLAN.md", False, "T11c")
assert_pside("CLAUDE.md", False, "T11d")  # pack-root trinity is pack-only-by-location

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 36 keyword detection + scope-rule unit tests" ;;
    *) t_fail "Check 36 keyword/scope-rule unit tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Check 37 deny-list + anchor-phrase context detection
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Check 37 deny-list + anchor-phrase unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def check_anchor(lines, lineno, expected, label):
    actual = mod._context_has_anchor(lines, lineno)
    if actual != expected:
        failures.append(f"{label}: lineno={lineno} expected={expected} actual={actual}")

# T1: feedback anchor in same line
check_anchor(["The PM chat sends feedback to Pack Chat."], 1, True, "T1 feedback same-line")
# T2: feedback anchor in N+1 line
check_anchor(
    ["Pack Chat reviews the report.", "It then delivers feedback."],
    1, True, "T2 feedback next-line"
)
# T3: no anchor at all
check_anchor(["This file references PACK-AGENTS.md."], 1, False, "T3 no anchor")
# T4: pack-vs-project disambiguation anchor (BD-175 extension)
check_anchor(
    ["See tracker.toml.pack-example in the pack repo, or tracker.toml.example at client."],
    1, True, "T4 in-the-pack-repo anchor"
)
# T5: pack-repo hyphenated anchor
check_anchor(["The pack-repo PACK-AGENTS.md lists pack agents."], 1, True, "T5 pack-repo anchor")
# T6: escalation anchor
check_anchor(["Pack Chat handles escalation paths."], 1, True, "T6 escalation anchor")
# T7: anchor in line+2 (within window)
check_anchor(
    ["Reference PACK-AGENTS.md.", "", "Used in feedback context."],
    1, True, "T7 anchor at +2"
)
# T8: anchor at line-2 (within window)
check_anchor(
    ["This is feedback context.", "", "Mentions PACK-AGENTS.md."],
    3, True, "T8 anchor at -2"
)
# T9: anchor at line+3 (OUTSIDE window of 2)
check_anchor(
    ["Reference PACK-AGENTS.md.", "", "", "Now in feedback context."],
    1, False, "T9 anchor at +3 outside window"
)

# T10: pack-* agent name with anchor passes
check_anchor(["pack-architect spawn protocol — see feedback flow"], 1, True, "T10")
# T11: capitalized Pack Chat without anchor fails
check_anchor(["The Pack Chat orchestrator routes work."], 1, False, "T11 Pack Chat no anchor")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 37 anchor-phrase detection unit tests" ;;
    *) t_fail "Check 37 anchor-phrase detection tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Check 38 exemption-list + signal-counting
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Check 38 exemption-list + signal-count unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: exemption list is 1-entry (only tracker.toml.pack-example)
exempt = mod._read_boundary_exempt_root()
if len(exempt) != 1:
    failures.append(f"T1: expected 1-entry exempt list per Override 1+5, got {len(exempt)}: {sorted(exempt)}")
if "tracker.toml.pack-example" not in exempt:
    failures.append(f"T1: expected tracker.toml.pack-example in exempt list, got {sorted(exempt)}")

# T2: BACKLOG.md must NOT be in exempt list (Override 5 — must MOVE, did MOVE to pack-ops/)
if "BACKLOG.md" in exempt:
    failures.append("T2: BACKLOG.md must not be in exempt list per Override 5")
if "CHANGELOG.md" in exempt:
    failures.append("T2: CHANGELOG.md must not be in exempt list per Override 5")

# T3: threshold sanity
if mod._CHECK_38_SIGNAL_THRESHOLD < 1:
    failures.append(f"T3: threshold must be ≥ 1, got {mod._CHECK_38_SIGNAL_THRESHOLD}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Check 38 exemption-list + threshold unit tests" ;;
    *) t_fail "Check 38 exemption-list tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: End-to-end fixture (validate-pack.py exits 0 on HEAD)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-e2e.out 2>&1; then
    t_pass "validate-pack.py exits 0 with all checks including 36/37/38 on HEAD"
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail of output: $(tail -40 /tmp/vp-e2e.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 5: Synthetic in-tree fixtures (Check 37 negative + positive)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Synthetic fixture sanity tests ===\n"

# These tests exercise the check_project_side_deny_list grep logic
# against the fixture files committed to scripts/tests/fixtures/
# boundary-checks/. The fixtures are static (not in project-template/
# so they don't pollute the real check); we invoke the helper
# functions directly.

python3 <<EOF
import sys, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

fixtures_dir = pathlib.Path('$FIXTURES_DIR')
if not fixtures_dir.is_dir():
    print(f"SKIP fixtures dir missing: {fixtures_dir}")
    sys.exit(0)

# Each fixture file's expected hits per deny-list category:
expectations = {
    'fail_bare_pack_agents_ref.md':       {'min_hits': 1, 'expect_clean': False},
    'fail_pack_ops_prefix.md':             {'min_hits': 1, 'expect_clean': False},
    'fail_pack_agent_name.md':             {'min_hits': 1, 'expect_clean': False},
    'fail_capitalized_pack_chat.md':       {'min_hits': 1, 'expect_clean': False},
    'pass_feedback_legit.md':              {'min_hits': 0, 'expect_clean': True},
    'pass_pack_repo_disambiguation.md':    {'min_hits': 0, 'expect_clean': True},
    'pass_no_pack_refs.md':                {'min_hits': 0, 'expect_clean': True},
}

# Re-implement the per-file check (extracted from check_project_side_deny_list).
def count_unanchored_hits(text: str) -> int:
    import re
    lines = text.splitlines()
    hits = 0
    for lineno, line in enumerate(lines, start=1):
        # filename matches
        for fname, _ in mod._DENY_LIST_FILENAMES:
            if fname in line and not mod._context_has_anchor(lines, lineno):
                hits += 1
        # path-prefix matches
        for prefix, _ in mod._DENY_LIST_PATH_PREFIXES:
            if prefix in line and not mod._context_has_anchor(lines, lineno):
                hits += 1
        # agent names
        for agent in mod._DENY_LIST_AGENT_NAMES:
            if re.search(r"\b" + re.escape(agent) + r"\b", line) and not mod._context_has_anchor(lines, lineno):
                hits += 1
        # capitalized Pack Chat
        if mod._DENY_LIST_ROLE_NAME in line and not mod._context_has_anchor(lines, lineno):
            hits += 1
    return hits

for fixture_name, exp in expectations.items():
    fpath = fixtures_dir / fixture_name
    if not fpath.is_file():
        failures.append(f"missing fixture: {fixture_name}")
        continue
    text = fpath.read_text()
    hits = count_unanchored_hits(text)
    if exp['expect_clean']:
        if hits != 0:
            failures.append(f"{fixture_name}: expected 0 unanchored hits, got {hits}")
    else:
        if hits < exp['min_hits']:
            failures.append(f"{fixture_name}: expected ≥{exp['min_hits']} unanchored hits, got {hits}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic fixture Check 37 sanity tests" ;;
    *) t_fail "Synthetic fixture Check 37 sanity tests failed" ;;
esac

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
