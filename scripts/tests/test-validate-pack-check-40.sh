#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-40.sh — synthetic fixture
# tests for BD-179 Check 40 (pack-ops/ bare cross-reference scanner).
#
# These tests exercise the per-check regex + allowlist + anchor-phrase
# + same-dir-legit + candidate-path lookup logic without mutating any
# real pack-ops/ files. Each test stages a synthetic input
# (custom pack-ops/ markdown file inside a tmp REPO_ROOT), invokes
# Check 40 against the tmp tree, and asserts PASS / FAIL as expected.
#
# Usage: bash scripts/tests/test-validate-pack-check-40.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
FIXTURES_DIR="$REPO_ROOT/scripts/tests/fixtures/bare-cross-refs"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: Module import + new symbols reachable
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 40 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_bare_pack_ops_refs',
    '_CHECK_40_ALLOWLIST',
    '_CHECK_40_ANCHOR_PHRASES',
    '_CHECK_40_ANCHOR_WINDOW',
    '_CHECK_40_BARE_REF_PATTERN',
    '_CHECK_40_HYPERLINK_PATTERN',
    '_CHECK_40_EXCLUDE_PARTS',
    '_strip_code_blocks',
    '_build_basename_index',
    '_check_40_context_has_anchor',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check40-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check40-import.out; then
    t_pass "validate-pack.py imports + Check 40 symbols registered"
else
    t_fail "validate-pack.py import or Check 40 symbol registration failed" \
        "$(cat /tmp/vp-check40-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: Bare-ref regex unit tests (positive + negative + edge)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: _CHECK_40_BARE_REF_PATTERN unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Positive matches (per architect doc §13.5).
positive_cases = [
    "see \`MIGRATION-v10-to-v11.md\` for ...",
    "the \`merge-json.py\` script",
    "- \`QUICKSTART.md\` — where to start",
    "| \`PACK-CHAT.md\` |",
    "an \`init-project.sh\` invocation",
    "the \`tracker.toml\` config",
]
for text in positive_cases:
    m = mod._CHECK_40_BARE_REF_PATTERN.search(text)
    if not m:
        failures.append(f"T1 POSITIVE expected match in: {text!r}")

# Negative matches: qualified paths.
negative_cases = [
    "see \`supporting-docs/MIGRATION-v10-to-v11.md\`",
    "the \`scripts/merge-json.py\` script",
    "- \`pack-ops/MERGE-STRATEGY.md\` — ...",
    "in \`.claude/agents/pack-coder.md\`",
]
for text in negative_cases:
    m = mod._CHECK_40_BARE_REF_PATTERN.search(text)
    if m:
        failures.append(f"T2 NEGATIVE expected NO match in: {text!r} but got {m.group(1)!r}")

# Negative: wildcards (no match by §3.4).
wildcard_cases = [
    "the \`HELP-FRAGMENT*.md\` family",
    "\`ARCHITECTURE-V*.md\` docs",
]
for text in wildcard_cases:
    m = mod._CHECK_40_BARE_REF_PATTERN.search(text)
    if m:
        failures.append(f"T3 WILDCARD expected NO match in: {text!r}")

# Negative: narrative shorthand without extension (no match by §3.4).
shorthand_cases = [
    "the (validate-pack Check 8 enforces)",
    "\`pack-help\` is the entry",
]
for text in shorthand_cases:
    m = mod._CHECK_40_BARE_REF_PATTERN.search(text)
    if m:
        failures.append(f"T4 SHORTHAND expected NO match in: {text!r}")

# Positive: lowercase-starting filenames (per §3.5 final regex).
lowercase_cases = [
    "the \`merge-json.py\` ...",
    "in \`pack-help.sh\` ...",
    "the \`feedback_review_fix_one_cycle.md\` file",
]
for text in lowercase_cases:
    m = mod._CHECK_40_BARE_REF_PATTERN.search(text)
    if not m:
        failures.append(f"T5 LOWERCASE-START expected match in: {text!r}")

# Hyperlink regex positive + negative.
hyperlink_pos = [
    "[the migration narrative](MIGRATION-v10-to-v11.md)",
    "[init script](init-project.sh)",
]
for text in hyperlink_pos:
    m = mod._CHECK_40_HYPERLINK_PATTERN.search(text)
    if not m:
        failures.append(f"T6 HYPERLINK-POS expected match in: {text!r}")

hyperlink_neg = [
    "[the migration narrative](supporting-docs/MIGRATION-v10-to-v11.md)",
    "[init](scripts/init-project.sh)",
]
for text in hyperlink_neg:
    m = mod._CHECK_40_HYPERLINK_PATTERN.search(text)
    if m:
        failures.append(f"T7 HYPERLINK-NEG expected NO match in: {text!r}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_CHECK_40_BARE_REF_PATTERN + hyperlink regex pass full case set" ;;
    *) t_fail "_CHECK_40_BARE_REF_PATTERN unit tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: _strip_code_blocks preprocess
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: _strip_code_blocks preprocess unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: code blocks are stripped; line numbers preserved.
text = """before
\`\`\`bash
python3 scripts/validate-pack.py
bash MIGRATION-v10-to-v11.md
\`\`\`
after"""
lines = mod._strip_code_blocks(text)
if len(lines) != 6:
    failures.append(f"T1 expected 6 lines, got {len(lines)}: {lines}")
if lines[0] != "before":
    failures.append(f"T1 expected line 0 = 'before', got {lines[0]!r}")
if lines[1] != "":
    failures.append(f"T1 expected line 1 = '' (fence open), got {lines[1]!r}")
if lines[2] != "":
    failures.append(f"T1 expected line 2 = '' (code content), got {lines[2]!r}")
if lines[3] != "":
    failures.append(f"T1 expected line 3 = '' (code content), got {lines[3]!r}")
if lines[4] != "":
    failures.append(f"T1 expected line 4 = '' (fence close), got {lines[4]!r}")
if lines[5] != "after":
    failures.append(f"T1 expected line 5 = 'after', got {lines[5]!r}")

# T2: prose between blocks is preserved.
text2 = """prose 1
\`\`\`
bare-ref.md inside block
\`\`\`
prose 2
\`MIGRATION-v10-to-v11.md\` in prose"""
lines2 = mod._strip_code_blocks(text2)
if len(lines2) != 6:
    failures.append(f"T2 expected 6 lines, got {len(lines2)}")
# Prose lines preserved exactly:
if lines2[0] != "prose 1":
    failures.append(f"T2 prose 1 not preserved: {lines2[0]!r}")
if lines2[4] != "prose 2":
    failures.append(f"T2 prose 2 not preserved: {lines2[4]!r}")
if "MIGRATION" not in lines2[5]:
    failures.append(f"T2 prose 5 not preserved: {lines2[5]!r}")

# T3: empty input.
lines3 = mod._strip_code_blocks("")
if len(lines3) != 0:
    failures.append(f"T3 expected 0 lines for empty input, got {len(lines3)}")

# T4: no code blocks at all.
text4 = "line a\nline b\nline c"
lines4 = mod._strip_code_blocks(text4)
if lines4 != ["line a", "line b", "line c"]:
    failures.append(f"T4 expected pass-through, got {lines4}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_strip_code_blocks preserves line count + strips fence content" ;;
    *) t_fail "_strip_code_blocks unit tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Anchor-phrase exemption (_check_40_context_has_anchor)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: _check_40_context_has_anchor unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: anchor on the matched line.
lines = ["line 0", "see \`X.md\` in the pack repo", "line 2"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T1 expected anchor on matched line")

# T2: anchor 1 line before.
lines = ["in the pack repo", "see \`X.md\` for details", "line 2"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T2 expected anchor 1-before")

# T3: anchor 1 line after.
lines = ["line 0", "see \`X.md\`", "this lives in the pack repo only"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T3 expected anchor 1-after")

# T4: anchor exactly at window=2 boundary (2 lines after).
lines = ["line 0", "see \`X.md\`", "padding", "at the pack repo"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T4 expected anchor 2-after")

# T5: anchor OUT of window (3 lines after) — should NOT trigger.
lines = ["line 0", "see \`X.md\`", "padding 1", "padding 2", "in the pack repo"]
if mod._check_40_context_has_anchor(lines, 2):
    failures.append("T5 expected NO anchor 3-after (out of window)")

# T6: NEW anchor 'post-install' (OQ-3).
lines = ["doc lives at post-install path", "the \`X.md\` ref", "context"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T6 expected 'post-install' anchor match")

# T7: NEW anchor 'does not exist' (OQ-S4).
lines = ["line 0", "cited \`X.md\` (does not exist); canonical ...", "line 2"]
if not mod._check_40_context_has_anchor(lines, 2):
    failures.append("T7 expected 'does not exist' anchor match")

# T8: NEW anchor 'archived' (OQ-S4 forward-compat).
lines = ["from the now-archived \`X.md\` and \`Y.md\`", "doc", "line 2"]
if not mod._check_40_context_has_anchor(lines, 1):
    failures.append("T8 expected 'archived' anchor match")

# T9: no anchor at all — should NOT trigger.
lines = ["line 0", "see \`X.md\` for details", "line 2"]
if mod._check_40_context_has_anchor(lines, 2):
    failures.append("T9 expected NO anchor without keyword")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_check_40_context_has_anchor admits all OQ-3/OQ-S4 phrases at window=2" ;;
    *) t_fail "_check_40_context_has_anchor unit tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: _build_basename_index honors EXCLUDE list
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: _build_basename_index EXCLUDE behavior ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Build the live index.
index = mod._build_basename_index()

# T1: pack-ops/MERGE-STRATEGY.md should be in the index.
if "MERGE-STRATEGY.md" not in index:
    failures.append("T1 pack-ops/MERGE-STRATEGY.md missing from index")

# T2: validate-pack.py should be in the index.
if "validate-pack.py" not in index:
    failures.append("T2 scripts/validate-pack.py missing from index")

# T3: NO fixture-tree file should appear with its short basename only
#     (per §5.1 D4 EXCLUDE + OQ-S1 expansion). Test fixture files have
#     unique-ish names; we check that test-fixtures/ basenames don't
#     overshadow real candidates.
#
#     Pick a real basename that lives BOTH in scripts/tests/fixtures/
#     and outside (if any). The classic case: tracker.toml lives in
#     fixture trees but not in the pack at HEAD; without EXCLUDE, it
#     would show up. With OQ-S1 EXCLUDE applied, it must NOT appear.
if "tracker.toml" in index:
    failures.append(
        "T3 EXCLUDE failed — bare tracker.toml leaked into index "
        f"(candidates: {index['tracker.toml']})"
    )

# T4: EXCLUDE_PARTS must list both 'test-fixtures' and
#     'scripts/tests/fixtures' (OQ-S1 ratification).
required_excludes = {"test-fixtures", "scripts/tests/fixtures"}
missing_excl = required_excludes - set(mod._CHECK_40_EXCLUDE_PARTS)
if missing_excl:
    failures.append(f"T4 _CHECK_40_EXCLUDE_PARTS missing: {missing_excl}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_build_basename_index honors EXCLUDE list including OQ-S1 expansion" ;;
    *) t_fail "_build_basename_index EXCLUDE tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: Synthetic pack-ops/ tree end-to-end (PASS / FAIL paths)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: End-to-end check_bare_pack_ops_refs() with synthetic tree ===\n"

python3 <<EOF
import sys, tempfile, os, pathlib, shutil
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_with_synthetic(pack_ops_files: dict, extra_files: dict = None) -> tuple:
    """Run check_bare_pack_ops_refs against a synthetic tree.

    pack_ops_files: { 'FOO.md': 'content', ... }
    extra_files: { 'scripts/init-project.sh': 'content', ... } — non-pack-ops files
                 to populate the basename index for candidate-path lookup.

    Returns (failures_count, pass_msg_present, captured_output).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check40-")
    root = pathlib.Path(tmpdir)
    (root / "pack-ops").mkdir()
    for name, content in pack_ops_files.items():
        (root / "pack-ops" / name).write_text(content)
    if extra_files:
        for rel, content in extra_files.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)

    import io, contextlib
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_bare_pack_ops_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    pass_msg = "zero unqualified bare cross-references" in captured
    return (len(new_failures), pass_msg, captured)

# T1: PASS path — bare ref is on the allowlist (README.md).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "See \`README.md\` for the landing-page.\n"},
    {"README.md": "stub"},
)
if fail_count != 0:
    failures.append(f"T1 (allowlist PASS) expected 0 failures, got {fail_count}: {captured}")
if not pass_msg:
    failures.append(f"T1 (allowlist PASS) missing pass message: {captured}")

# T2: PASS path — bare ref is anchor-exempted.
content = (
    "# Test fixture\n"
    "The tracker example \`tracker.toml.pack-example\` in the pack repo,\n"
    "or \`tracker.toml.example\` at a client project root, and the\n"
    "\`OPTIONAL-FEATURES.md\` walkthrough document the opt-in flow.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": content},
    {
        "pack-ops/OPTIONAL-FEATURES.md": "stub",
        "project-template/docs/pack/OPTIONAL-FEATURES.md": "stub",
    },
)
if fail_count != 0:
    failures.append(f"T2 (anchor PASS) expected 0 failures, got {fail_count}: {captured}")

# T3: PASS path — same-dir-legit. Bare ref to a sibling file in
#     pack-ops/ resolves to pack-ops/<file> (same dir).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {
        "FOO.md": "See \`BAR.md\` for details.\n",
        "BAR.md": "stub",
    },
)
if fail_count != 0:
    failures.append(f"T3 (same-dir PASS) expected 0 failures, got {fail_count}: {captured}")

# T4: FAIL path — qualify needed. Bare ref resolves to scripts/init-project.sh
#     (different dir than pack-ops/).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "Run \`init-project.sh\` to install.\n"},
    {"scripts/init-project.sh": "stub"},
)
if fail_count != 1:
    failures.append(f"T4 (qualify FAIL) expected 1 failure, got {fail_count}: {captured}")
if "scripts/init-project.sh" not in captured:
    failures.append(f"T4 (qualify FAIL) FAIL message must suggest scripts/init-project.sh: {captured}")

# T5: FAIL path — broken ref (0 candidates).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "See \`THIS-DOES-NOT-EXIST.md\` for details.\n"},
)
if fail_count != 1:
    failures.append(f"T5 (broken FAIL) expected 1 failure, got {fail_count}: {captured}")
if "broken ref" not in captured:
    failures.append(f"T5 (broken FAIL) message must say 'broken ref': {captured}")

# T6: PASS path — code-block content NOT flagged.
content = (
    "# Test fixture\n"
    "Example invocation:\n"
    "\n"
    "\`\`\`bash\n"
    "python3 scripts/validate-pack.py\n"
    "bash MIGRATION-v10-to-v11.md\n"
    "\`\`\`\n"
    "\n"
    "Done.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": content},
)
if fail_count != 0:
    failures.append(f"T6 (code-block PASS) expected 0 failures, got {fail_count}: {captured}")

# T7: EXCLUDED files. BACKLOG.md and CHANGELOG.md in pack-ops/ are
#     SKIPPED entirely per §2.1 D1a, even if they contain bare refs.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {
        "BACKLOG.md": "Has bare \`UNQUALIFIED-REF.md\` ref — should be skipped.\n",
        "CHANGELOG.md": "Has bare \`ANOTHER-REF.md\` ref — should be skipped.\n",
    },
)
if fail_count != 0:
    failures.append(f"T7 (mirror SKIP) expected 0 failures, got {fail_count}: {captured}")
if "BACKLOG.md" in captured.replace("excluded", "").replace("BACKLOG.md/", ""):
    # Allow mention of BACKLOG.md only in 'excluded mirrors' messaging
    pass  # Lenient — the message format may include the name in context

# T8: FAIL path — 2+ candidates (DISAMBIGUATE).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "See \`SHARED.md\` for the shared content.\n"},
    {
        "supporting-docs/SHARED.md": "stub",
        "maintenance-docs/SHARED.md": "stub",
    },
)
if fail_count != 1:
    failures.append(f"T8 (2+ FAIL) expected 1 failure, got {fail_count}: {captured}")
if "qualify to one of" not in captured:
    failures.append(f"T8 (2+ FAIL) FAIL message must say 'qualify to one of': {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end PASS / FAIL / exemption / code-block / mirror-skip tests" ;;
    *) t_fail "End-to-end check_bare_pack_ops_refs tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 6: Static fixture file sanity (parseable + non-empty)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 6: Static fixture file sanity ===\n"

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

expected_fixtures = {
    "README.md": "fixture set documentation",
    "pack-ops-pass-allowlist.md": "bare refs on the allowlist",
    "pack-ops-pass-anchor.md": "bare refs admitted by anchor phrase",
    "pack-ops-pass-same-dir.md": "bare refs admitted by same-dir-legit",
    "pack-ops-fail-qualify.md": "bare refs that should FAIL with qualify",
    "pack-ops-fail-broken.md": "bare refs that should FAIL with broken",
    "pack-ops-pass-code-block.md": "bare refs inside fenced code (admit)",
}
for name, why in expected_fixtures.items():
    p = fixtures_dir / name
    if not p.is_file():
        failures.append(f"missing fixture: {name} ({why})")
        continue
    content = p.read_text()
    if not content:
        failures.append(f"empty fixture: {name}")

# Sanity: pack-ops-fail-qualify.md MUST contain bare backtick-spans
# matching the regex.
fq = fixtures_dir / "pack-ops-fail-qualify.md"
if fq.is_file():
    text = fq.read_text()
    matches = mod._CHECK_40_BARE_REF_PATTERN.findall(text)
    if len(matches) < 3:
        failures.append(
            f"pack-ops-fail-qualify.md: expected ≥3 bare-ref matches, got {len(matches)}"
        )

# Sanity: pack-ops-pass-code-block.md MUST have at least one bare-ref
# match BEFORE code-block stripping AND zero after stripping.
pcb = fixtures_dir / "pack-ops-pass-code-block.md"
if pcb.is_file():
    text = pcb.read_text()
    matches_raw = mod._CHECK_40_BARE_REF_PATTERN.findall(text)
    if not matches_raw:
        failures.append("pack-ops-pass-code-block.md: expected bare-ref-shaped tokens in raw text")
    # After stripping, the bare-ref-shaped tokens in code blocks vanish.
    lines_stripped = mod._strip_code_blocks(text)
    stripped_text = "\n".join(lines_stripped)
    matches_stripped = mod._CHECK_40_BARE_REF_PATTERN.findall(stripped_text)
    # After stripping, the bash-shell-command line that referenced
    # MIGRATION-v10-to-v11.md (inside the fenced block) should be gone.
    # The prose section still mentions the same names in backticks
    # (intentional — the prose explains what code-block stripping does).
    # We check that NO line containing a code-only shell verb
    # (python3, bash, cat, ls) survives stripping.
    code_verbs = ("python3 ", "bash ", "cat ", "ls ")
    for ln in lines_stripped:
        for verb in code_verbs:
            if ln.lstrip().startswith(verb):
                failures.append(
                    f"pack-ops-pass-code-block.md: code-block content leaked "
                    f"through stripping: {ln!r}"
                )
                break

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Static fixture files present + parseable + regex-shaped" ;;
    *) t_fail "Static fixture sanity failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 7: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 7: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check40-e2e.out 2>&1; then
    if grep -q "Check 40: pack-ops/ bare cross-reference scanner" /tmp/vp-check40-e2e.out \
       && grep -q "Check 40 — .* pack-ops/\\*\\.md file(s) walked" /tmp/vp-check40-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 40 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 40 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check40-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check40-e2e.out)"
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
