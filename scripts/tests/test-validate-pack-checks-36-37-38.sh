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
    '_is_scope_neutral_generated',
    '_is_pack_chat_only_permitted',
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
# T3: pack-chat-only keyword detected; retired tokens NOT recognized
assert_match("docs: pack-chat-only — governance edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, True, "T3c")
assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3d: retired pm-only NOT recognized — Check 36 SKIPS, not reject")
assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3e: retired pack-memory-only NOT recognized")
# T4: no keyword — implicit scope (all return False)
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T4a")
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PROJECT_ONLY, False, "T4b")
assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T4c")
# T5: keyword embedded in a larger word should NOT match (boundary anchor)
assert_match("feat: pack-only-ish thing", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T5 (embedded)")
# T5b/T5c: pack-chat-only must NOT collide with pack-only (either direction)
assert_match("feat: vN — BD-209 rename (pack-chat-only)", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T5b: pack-only kw does NOT fire on a pack-chat-only subject")
assert_match("feat: thing (pack-only)", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5c: pack-chat-only kw does NOT fire on a pack-only subject")
# T5d: pack-chat-only embedded in a larger word should NOT match
assert_match("feat: pack-chat-only-ish thing", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5d: embedded")

# Scope-rule tests: pack-chat-only PERMITTED-PATHS
# T6: project-template trinity IS pack-chat-only-permitted (B1 cascade fix)
def assert_pm(path, expected, label):
    actual = mod._is_pack_chat_only_permitted(path)
    if actual != expected:
        failures.append(f"{label}: path={path!r} expected={expected} actual={actual}")

assert_pm("project-template/CLAUDE.md", True, "T6a")
assert_pm("project-template/AGENTS.md", True, "T6b")
assert_pm("project-template/GEMINI.md", True, "T6c")
# BD-203 Commit 2 (A13-INVERSE): `pack-ops/BACKLOG.md` +
# `pack-ops/CHANGELOG.md` are DELETED at BD-203 Commit 2 — the per-entry
# trees `/backlog/` + `/changelog/` are the sole SSOT under the no-mirror
# model. A `git rm`'d file cannot be a pack-chat-only-permitted PATH, so
# the two monoliths are NO LONGER permitted Files (the inverse of
# BD-209's transient A13 fold). The per-entry trees ARE permitted via the
# PREFIXES set (T6d2/T6e2).
assert_pm("pack-ops/BACKLOG.md", False, "T6d")
assert_pm("pack-ops/CHANGELOG.md", False, "T6e")
# T6d2/T6e2: the per-entry trees remain pack-chat-only-permitted via the
# `backlog/` + `changelog/` PREFIXES — the no-mirror SSOT surfaces.
assert_pm("backlog/BD-203.md", True, "T6d2")
assert_pm("changelog/v11.md", True, "T6e2")
assert_pm("pack-ops/PACK-CHAT.md", True, "T6f")
assert_pm("pack-ops/PACK-AGENTS.md", True, "T6g")
assert_pm("README.md", True, "T6h")
assert_pm("CLAUDE.md", True, "T6i")  # pack-root trinity
# T6j: BD-198 — PACK-MEMORY-RATIONALE.md IS pack-chat-only-permitted (rule↔rationale
#   bijection partner of trinity `## Pack memory`; edited only in lockstep with
#   rule changes). Positive case: a pack-chat-only commit touching the rationale doc
#   passes Check 36. Mirrors the PACK-AGENTS.md § "pack-chat-only files and
#   directories" Files-list SSOT.
assert_pm("pack-ops/PACK-MEMORY-RATIONALE.md", True, "T6j")
# T6l: BD-255 Part A (A1) — pack-ops/session-state.json IS pack-chat-only-permitted
#   (committed live-session snapshot, Pack-Chat-overwritten on every state
#   transition; the BD-252 overwrite protocol depends on Pack Chat writing it).
#   Positive case: a pack-chat-only commit touching session-state.json passes
#   Check 36. Mirrors the A1-COLLAPSE generated PACK-AGENTS.md § "pack-chat-only
#   files and directories" Files-list SSOT. T6j is the precedent for a positive
#   assertion when the constant gains a path.
assert_pm("pack-ops/session-state.json", True, "T6l")
# T6k: BD-198 negative control — a non-permitted pack-ops/ file is NOT
#   pack-chat-only-permitted, so a pack-chat-only commit touching it is still flagged as
#   an offender by Check 36. Confirms the rationale-doc addition is exact
#   (one path), not a broad pack-ops/ allowance.
assert_pm("pack-ops/NOT-PM.md", False, "T6k")
# T7: supporting-docs is NOT pack-chat-only-permitted (the V2-shape fixture)
assert_pm("supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md", False, "T7a")
assert_pm("project-template/docs/pack/PM-CHAT.md", False, "T7b")  # docs/pack, not trinity
assert_pm("scripts/init-project.sh", False, "T7c")
# T8: per-entry tree directories are pack-chat-only-permitted
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

# -----------------------------------------------------------------
# Check 36 scope-neutral generated-artifact carve-out (BD-197 C0;
# ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md section 17.6).
# NOTE: this Group-1 heredoc is UNQUOTED (<<EOF), so the shell expands
# the body — do NOT use backticks in this block (they would be parsed
# as command substitution). The regenerate-manifest-v11-surface rule
# FORCES the pack-side test-fixtures/manifest.txt into ANY commit that
# edits v11-surface content (incl. project-template/). Without the
# carve-out a project-only commit that stages the manifest fails
# Check 36. The carve-out exempts EXACTLY test-fixtures/manifest.txt
# (exact-string set-membership, NOT a test-fixtures/ prefix) from BOTH
# the pack-only and project-only offender tests, while EVERY other
# cross-surface path is still caught.
# -----------------------------------------------------------------

# Predicate-level controls (NC-1..NC-3): exact-string membership only.
def assert_neutral(path, expected, label):
    actual = mod._is_scope_neutral_generated(path)
    if actual != expected:
        failures.append(f"{label}: path={path!r} expected_neutral={expected} actual={actual}")

# NC-1: predicate admits the manifest.
assert_neutral("test-fixtures/manifest.txt", True, "NC-1")
# NC-2: predicate rejects a non-carved pack path.
assert_neutral("scripts/validate-pack.py", False, "NC-2")
# NC-3: predicate rejects sibling test-fixtures paths (no prefix widening) --
#   proves the carve-out is exact-string, NOT a test-fixtures/ prefix that
#   would wrongly exempt the static snapshot + the build.sh/README recipe.
assert_neutral("test-fixtures/v11-trinity-marker-prepped/CLAUDE.md", False, "NC-3a")
assert_neutral("test-fixtures/build.sh", False, "NC-3b")

# Offender-level controls (NC-4..NC-7): reproduce the two patched offender
# comprehensions exactly as they appear in check_commit_scope_honesty().
def project_only_offenders(paths):
    return [
        p for p in paths
        if not mod._is_project_side_path(p)
        and not mod._is_scope_neutral_generated(p)
    ]

def pack_only_offenders(paths):
    return [
        p for p in paths
        if mod._is_project_side_path(p)
        and not mod._is_scope_neutral_generated(p)
    ]

# NC-4: a project-only commit = project content + manifest PASSES (empty).
nc4 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md", "test-fixtures/manifest.txt"]
)
if nc4 != []:
    failures.append(f"NC-4: project-only [project content + manifest] expected [] got {nc4}")

# NC-5: a pack-only commit = pack content + manifest PASSES (empty).
nc5 = pack_only_offenders(
    ["pack-ops/PACK-CHAT.md", "test-fixtures/manifest.txt"]
)
if nc5 != []:
    failures.append(f"NC-5: pack-only [pack content + manifest] expected [] got {nc5}")

# NC-6: a REAL cross-surface offender STILL FAILS -- the guard is NOT
#   weakened. A project-only commit that also stages real pack source
#   (scripts/validate-pack.py) is still flagged; only the manifest is carved.
nc6 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md", "scripts/validate-pack.py",
     "test-fixtures/manifest.txt"]
)
if nc6 != ["scripts/validate-pack.py"]:
    failures.append(
        f"NC-6: project-only real cross-surface offender expected "
        f"['scripts/validate-pack.py'] got {nc6}"
    )

# NC-7 (not-weakened, exactness): the static snapshot is NOT carved -- a
#   project-only commit touching it STILL FAILS (proves NC-3 at the
#   offender level, not just the predicate level).
nc7 = project_only_offenders(
    ["project-template/docs/pack/PM-CHAT.md",
     "test-fixtures/v11-trinity-marker-prepped/CLAUDE.md",
     "test-fixtures/manifest.txt"]
)
if nc7 != ["test-fixtures/v11-trinity-marker-prepped/CLAUDE.md"]:
    failures.append(
        f"NC-7: project-only touching static snapshot expected "
        f"['test-fixtures/v11-trinity-marker-prepped/CLAUDE.md'] got {nc7}"
    )

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
# Group 6: Per-line fence (Guardrail 2 — BD-173 H.13)
# ─────────────────────────────────────────────────────────────────
#
# Exercises `_has_per_line_fence`, `_build_fence_skip_lineset`, and
# `_CHECK_37_PER_LINE_FENCE_FILES` per architect §2.6 spec. Each test
# stages a synthetic input string and asserts the helper output.

printf "\n=== Group 6: Per-line fence (Guardrail 2) unit tests ===\n"

python3 <<EOF
import sys, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Guardrail 2 helper symbols must exist on the module.
required = ['_has_per_line_fence', '_build_fence_skip_lineset',
            '_CHECK_37_PER_LINE_FENCE_FILES', '_FENCE_MARKER_START',
            '_FENCE_MARKER_END', '_line_is_fence_marker']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    failures.append(f"missing fence helpers: {missing}")

# The architect-spec constant must enumerate at least 11 entries
# (7 original + 4 dual-surface per H.12/H.13 reorder).
if hasattr(mod, '_CHECK_37_PER_LINE_FENCE_FILES'):
    n = len(mod._CHECK_37_PER_LINE_FENCE_FILES)
    if n < 11:
        failures.append(f"_CHECK_37_PER_LINE_FENCE_FILES has {n} entries; expected >=11")
    # Each entry must be a non-empty string.
    for entry in mod._CHECK_37_PER_LINE_FENCE_FILES:
        if not isinstance(entry, str) or not entry:
            failures.append(f"invalid fence-list entry: {entry!r}")
    # Each entry must use POSIX-form repo-relative path (no leading '/').
    for entry in mod._CHECK_37_PER_LINE_FENCE_FILES:
        if entry.startswith('/'):
            failures.append(f"fence-list entry not repo-relative: {entry!r}")

# G6.T1: File NOT on fence-allowlist — Check 37 normal path.
#   We verify _has_per_line_fence returns False for an unallowlisted file.
from pathlib import Path
if hasattr(mod, '_has_per_line_fence'):
    if mod._has_per_line_fence(Path("project-template/docs/pack/SOME-RANDOM.md")):
        failures.append("G6.T1: _has_per_line_fence True for unallowlisted file")

# G6.T2: File ON fence-allowlist — fence markers exempt enclosed lines.
text_g6t2 = '''before line outside
<!-- DENY-LIST-CONTENT-START -->
PACK-AGENTS.md mention inside fence
<!-- DENY-LIST-CONTENT-END -->
after line outside
'''
skip = mod._build_fence_skip_lineset(text_g6t2)
# Expect lines 3 in skip (interior of fence); 1, 2, 4, 5 NOT in skip.
if skip is None:
    failures.append("G6.T2: skip set is None (imbalance) — should be {3}")
elif skip != {3}:
    failures.append(f"G6.T2: skip set {skip} != expected {{3}}")

# G6.T3: File ON fence-allowlist, hits OUTSIDE fence still scanned.
text_g6t3 = '''PACK-AGENTS.md outside fence
<!-- DENY-LIST-CONTENT-START -->
PACK-AGENTS.md inside fence
<!-- DENY-LIST-CONTENT-END -->
'''
skip = mod._build_fence_skip_lineset(text_g6t3)
# Line 1 NOT in skip (outside-fence hit must still be scanned).
if skip is None:
    failures.append("G6.T3: skip set is None — should be {3}")
elif 1 in skip:
    failures.append(f"G6.T3: line 1 incorrectly in skip {skip}")

# G6.T4: START without matching END — imbalance.
text_g6t4 = '''<!-- DENY-LIST-CONTENT-START -->
content
(no END marker)
'''
skip = mod._build_fence_skip_lineset(text_g6t4)
if skip is not None:
    failures.append(f"G6.T4: expected None (imbalance); got {skip}")

# G6.T5: END without matching START — imbalance.
text_g6t5 = '''content
<!-- DENY-LIST-CONTENT-END -->
'''
skip = mod._build_fence_skip_lineset(text_g6t5)
if skip is not None:
    failures.append(f"G6.T5: expected None (imbalance); got {skip}")

# G6.T6: Multiple non-overlapping fences.
text_g6t6 = '''outside1
<!-- DENY-LIST-CONTENT-START -->
inside-fence-A
<!-- DENY-LIST-CONTENT-END -->
outside2
<!-- DENY-LIST-CONTENT-START -->
inside-fence-B
<!-- DENY-LIST-CONTENT-END -->
outside3
'''
skip = mod._build_fence_skip_lineset(text_g6t6)
# Lines 3 (inside-fence-A) and 7 (inside-fence-B) should be in skip.
if skip is None:
    failures.append("G6.T6: skip is None — should be {3, 7}")
elif skip != {3, 7}:
    failures.append(f"G6.T6: skip {skip} != expected {{3, 7}}")

# G6.T7: Empty fence (START immediately followed by END) — permitted.
text_g6t7 = '''before
<!-- DENY-LIST-CONTENT-START -->
<!-- DENY-LIST-CONTENT-END -->
after
'''
skip = mod._build_fence_skip_lineset(text_g6t7)
if skip is None:
    failures.append("G6.T7: empty fence rejected — should be permitted")
elif skip != set():
    failures.append(f"G6.T7: empty fence skip {skip} != expected empty set")

# G6.T8: Nested START — imbalance (no nesting support per §2.5).
text_g6t8 = '''<!-- DENY-LIST-CONTENT-START -->
inner1
<!-- DENY-LIST-CONTENT-START -->
inner2
<!-- DENY-LIST-CONTENT-END -->
<!-- DENY-LIST-CONTENT-END -->
'''
skip = mod._build_fence_skip_lineset(text_g6t8)
if skip is not None:
    failures.append(f"G6.T8: nested fence accepted; expected None imbalance: {skip}")

# G6.T9: Shell-comment-prefix fence syntax — `# <!-- DENY-LIST-CONTENT-START -->`.
#   The parser must recognize the shell-comment-prefixed form (per
#   architect §2.3 shell-script fence-marker note).
text_g6t9 = '''#!/usr/bin/env bash
echo "before"
# <!-- DENY-LIST-CONTENT-START -->
echo "pack-ops/foo inside fence"
# <!-- DENY-LIST-CONTENT-END -->
echo "after"
'''
skip = mod._build_fence_skip_lineset(text_g6t9)
if skip is None:
    failures.append("G6.T9: shell-comment-prefix fence rejected; should be accepted")
elif skip != {4}:
    failures.append(f"G6.T9: shell-comment-prefix skip {skip} != expected {{4}}")

# G6.T10: Indented fence markers (markdown bullets / shell function bodies).
text_g6t10 = '''top
  <!-- DENY-LIST-CONTENT-START -->
  bullet line with PACK-AGENTS.md
  <!-- DENY-LIST-CONTENT-END -->
end
'''
skip = mod._build_fence_skip_lineset(text_g6t10)
if skip is None:
    failures.append("G6.T10: indented fence rejected; should be accepted")
elif skip != {3}:
    failures.append(f"G6.T10: indented skip {skip} != expected {{3}}")

# G6.T11: End-to-end — run Check 37 via validate-pack.py on HEAD; PASS
#   verifies the 11-file fence integration is sound (no imbalances,
#   no false-positive failures from outside-fence prose).
import subprocess
result = subprocess.run(
    ['python3', '$REPO_ROOT/scripts/validate-pack.py', '--only-check', '37'],
    capture_output=True, text=True,
)
if result.returncode != 0:
    failures.append(
        f"G6.T11: validate-pack.py exit {result.returncode}; expected 0. "
        f"Tail: {result.stdout[-1000:]}"
    )

# G6.T12: Check 37 success message announces fenced-lines count.
if 'fenced LEGITIMATE-content line' not in result.stdout:
    failures.append("G6.T12: Check 37 success message missing fenced-lines announcement")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Group 6 — Guardrail 2 per-line fence unit tests" ;;
    *) t_fail "Group 6 — Guardrail 2 per-line fence unit tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 7: Check 37 scope expansion (Guardrail 3 — BD-173 H.12)
# ─────────────────────────────────────────────────────────────────
#
# Exercises `_iter_client_installed_files()` per architect §3.1 +
# §3.4. The helper returns the union of project-template/ (recursive)
# + the explicit non-project-template entries from
# `_CLIENT_INSTALLED_FILES` in scripts/init-project.sh. T1 verifies
# Check 37 walks scripts/lib/detect.sh (path-prefix detection at the
# walked file); T2 verifies anchor-phrase exemption survives at a
# non-project-template entry; T3 + T4 are unit-checks of the helper.

printf "\n=== Group 7: Check 37 scope expansion (Guardrail 3) unit tests ===\n"

python3 <<EOF
import sys, pathlib, tempfile, shutil
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Guardrail 3 helper symbol must exist on the module.
required = ['_iter_client_installed_files', '_iter_project_side_files',
            '_parse_client_installed_files']
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    failures.append(f"missing helpers: {missing}")

# G7.T1: Synthetic detection — Check 37 walks scripts/lib/detect.sh
#   (expanded scope) and would flag a maintenance-docs/ path-prefix
#   match in a non-fence line.
#
#   We can't easily synthesize this end-to-end without rewriting
#   detect.sh (out-of-scope and would break HEAD). Instead, we verify
#   that scripts/lib/detect.sh appears in the walked-files iterator
#   (the precondition for Check 37 detection on that surface).
from pathlib import Path
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_str = {str(p) for p in walked}
    if 'scripts/lib/detect.sh' not in walked_str:
        failures.append(
            "G7.T1: scripts/lib/detect.sh NOT in _iter_client_installed_files() — "
            "expanded scope is broken (path not walked)"
        )

# G7.T2: Anchor-phrase exemption still operates on non-project-template
#   entries. supporting-docs/METHODOLOGY.md contains legitimate
#   Pack-Chat references; the architect spec says these PASS via
#   anchor-phrase + per-line fence. We verify (a) the file is walked
#   (so it COULD be flagged), and (b) end-to-end Check 37 PASSES at
#   HEAD (the cross-cutting integration result).
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_str = {str(p) for p in walked}
    if 'supporting-docs/METHODOLOGY.md' not in walked_str:
        failures.append(
            "G7.T2: supporting-docs/METHODOLOGY.md NOT walked — "
            "expanded scope missing pedagogical surface"
        )

# G7.T3: Helper returns >= 4 explicit non-project-template entries
#   plus all project-template/ files. The 4 client-installed extras are:
#   supporting-docs/METHODOLOGY.md, supporting-docs/INSTALL-PROCEDURES.md,
#   scripts/pack-help.sh, scripts/lib/detect.sh.
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_str = {str(p) for p in walked}
    expected_extras = {
        'supporting-docs/METHODOLOGY.md',
        'supporting-docs/INSTALL-PROCEDURES.md',
        'scripts/pack-help.sh',
        'scripts/lib/detect.sh',
    }
    missing_extras = expected_extras - walked_str
    if missing_extras:
        failures.append(
            f"G7.T3: missing expected non-project-template extras: "
            f"{sorted(missing_extras)}"
        )
    # Sanity: also walks project-template/ files (at least the trinity).
    pt_trinity = {
        'project-template/CLAUDE.md',
        'project-template/AGENTS.md',
        'project-template/GEMINI.md',
    }
    missing_pt = pt_trinity - walked_str
    if missing_pt:
        failures.append(
            f"G7.T3: missing project-template/ trinity entries: "
            f"{sorted(missing_pt)}"
        )

# G7.T4: Helper deduplicates — no duplicate Path entries in the
#   returned list. Dedup is defensive (entries that appear under both
#   project-template/ and as a _CLIENT_INSTALLED_FILES non-project-
#   template entry would otherwise show up twice).
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_strs = [str(p) for p in walked]
    seen = set()
    duplicates = []
    for s in walked_strs:
        if s in seen:
            duplicates.append(s)
        seen.add(s)
    if duplicates:
        failures.append(f"G7.T4: duplicate entries in walked list: {duplicates}")

# G7.T5: Check 37's walk (_iter_project_side_files) is the
#   client-installed inventory PLUS the two companion-template dirs
#   (BD-196 C7 / plan §3 D1). The companion files appear in Check 37's
#   walk-set but MUST NOT appear in _iter_client_installed_files()
#   (that set feeds Check 41's install inventory + Check 43's walk,
#   which are deliberately unaffected — companion templates are NOT
#   auto-installed by init-project.sh). This asserts the extended
#   walk-set membership AND the deliberate separation in lock-step.
if hasattr(mod, '_iter_project_side_files') and hasattr(
        mod, '_iter_client_installed_files'):
    check37_walk = {str(p) for p in mod._iter_project_side_files()}
    installed = {str(p) for p in mod._iter_client_installed_files()}
    companion_expected = {
        'xcode-companion-templates/README.md',
        'xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md',
        'xcode-companion-templates/Codex/AGENTS.md',
        'vscode-companion-templates/README.md',
        'vscode-companion-templates/.vscode/settings.json',
    }
    # (a) companion files ARE in Check 37's walk-set (forward-protection).
    missing_companion = companion_expected - check37_walk
    if missing_companion:
        failures.append(
            f"G7.T5a: companion-template files NOT in Check 37 walk "
            f"(_iter_project_side_files): {sorted(missing_companion)}"
        )
    # (b) companion files are NOT in the client-installed inventory
    #     (Check 41/43 unaffected — separation preserved).
    leaked = companion_expected & installed
    if leaked:
        failures.append(
            f"G7.T5b: companion-template files leaked into "
            f"_iter_client_installed_files() (Check 41/43 install "
            f"inventory must stay companion-free): {sorted(leaked)}"
        )
    # (c) Check 37's walk-set strictly contains the install inventory
    #     (the companion dirs are an ADDITION, never a replacement).
    if not installed.issubset(check37_walk):
        failures.append(
            "G7.T5c: _iter_client_installed_files() is NOT a subset of "
            "_iter_project_side_files() — Check 37 walk no longer "
            "supersets the install inventory"
        )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Group 7 — Guardrail 3 scope expansion unit tests" ;;
    *) t_fail "Group 7 — Guardrail 3 scope expansion unit tests failed" ;;
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
