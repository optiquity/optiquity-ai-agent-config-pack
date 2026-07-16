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

# T5: indented 4-space code block (CommonMark §4.4) is stripped.
#     Open after a blank line; close at the first non-indented non-blank
#     line. Bare-ref-shaped tokens INSIDE the indented block must be
#     erased so Check 40 cannot see them.
text5 = """before prose

    indented \`BARE-REF.md\` here
    another indented \`OTHER.md\` line

after prose"""
lines5 = mod._strip_code_blocks(text5)
if len(lines5) != 6:
    failures.append(f"T5 expected 6 lines, got {len(lines5)}: {lines5}")
if lines5[0] != "before prose":
    failures.append(f"T5 expected line 0 = 'before prose', got {lines5[0]!r}")
if lines5[1] != "":
    failures.append(f"T5 expected line 1 = '' (blank), got {lines5[1]!r}")
if lines5[2] != "":
    failures.append(f"T5 expected line 2 = '' (indented stripped), got {lines5[2]!r}")
if lines5[3] != "":
    failures.append(f"T5 expected line 3 = '' (indented stripped), got {lines5[3]!r}")
if lines5[4] != "":
    failures.append(f"T5 expected line 4 = '' (blank, closes block), got {lines5[4]!r}")
if lines5[5] != "after prose":
    failures.append(f"T5 expected line 5 = 'after prose', got {lines5[5]!r}")
# Most-important assertion: bare-ref tokens must NOT survive stripping.
stripped_text5 = "\n".join(lines5)
if "BARE-REF.md" in stripped_text5 or "OTHER.md" in stripped_text5:
    failures.append(
        f"T5 indented-block content leaked through stripping: {stripped_text5!r}"
    )

# T6: indented block NOT opened without a preceding blank line.
#     A 4-space-indented line that immediately follows a non-blank
#     prose line is a continuation/wrapped line, not a code block.
#     The bare-ref token in such a line must remain visible.
text6 = """prose paragraph line 1
    continuation \`KEEP-VISIBLE.md\` (no blank before; not a code block)
after"""
lines6 = mod._strip_code_blocks(text6)
if len(lines6) != 3:
    failures.append(f"T6 expected 3 lines, got {len(lines6)}: {lines6}")
if "KEEP-VISIBLE.md" not in "\n".join(lines6):
    failures.append(
        f"T6 non-code-block 4-space indent erroneously stripped: {lines6}"
    )

# T7: indented block tolerates a blank line between two indented lines
#     (CommonMark allows this; block continues).
text7 = """before

    indented line 1 \`A.md\`

    indented line 2 \`B.md\`

after"""
lines7 = mod._strip_code_blocks(text7)
if len(lines7) != 7:
    failures.append(f"T7 expected 7 lines, got {len(lines7)}: {lines7}")
stripped_text7 = "\n".join(lines7)
if "A.md" in stripped_text7 or "B.md" in stripped_text7:
    failures.append(
        f"T7 indented block (with internal blank) did not fully strip: {stripped_text7!r}"
    )
if lines7[0] != "before" or lines7[6] != "after":
    failures.append(f"T7 prose boundaries not preserved: {lines7}")

# T8: fenced block takes precedence over a pending indented context.
#     If a fence opens after a blank line + 4-space indent, the fence
#     wins and no spurious indented-block state lingers.
text8 = """before

\`\`\`
fenced content \`INSIDE-FENCE.md\`
\`\`\`

    indented \`INSIDE-INDENT.md\` after fence

after"""
lines8 = mod._strip_code_blocks(text8)
stripped_text8 = "\n".join(lines8)
if "INSIDE-FENCE.md" in stripped_text8:
    failures.append(f"T8 fenced content leaked: {stripped_text8!r}")
if "INSIDE-INDENT.md" in stripped_text8:
    failures.append(f"T8 indented-after-fence content leaked: {stripped_text8!r}")
if lines8[0] != "before":
    failures.append(f"T8 prose 'before' not preserved: {lines8[0]!r}")
if lines8[-1] != "after":
    failures.append(f"T8 prose 'after' not preserved: {lines8[-1]!r}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_strip_code_blocks preserves line count + strips fence AND indented blocks" ;;
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

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


failures = []

# Build the live index.
index = mod._build_basename_index()

# T1: pack-ops/MERGE-STRATEGY.md should be in the index.
if "MERGE-STRATEGY.md" not in index:
    failures.append("T1 pack-ops/MERGE-STRATEGY.md missing from index")

# T2: validate-pack.py should be in the index.
if "validate-pack.py" not in index:
    failures.append("T2 scripts/validate-pack.py missing from index")

# T3: fixture-tree EXCLUDE semantics, on an ISOLATED synthetic tree
#     (per §5.1 D4 EXCLUDE + OQ-S1 expansion; reshaped for BD-204 C-8
#     SHOULD-2). The original leg asserted "tracker.toml" absent from
#     the LIVE index, premised on "tracker.toml lives in fixture trees
#     but not in the pack at HEAD" — FALSE on any tracker-enabled
#     (Mode-3) working tree, where a root tracker.toml is a legitimate
#     runtime artifact, so the leg failed locally on such trees while
#     validate-pack itself stayed green. Build the index against a
#     synthetic tree instead: same-basename copies under BOTH excluded
#     fixture roots must be EXCLUDED while a root-level copy must be
#     INDEXED — pinning that the EXCLUDE is effective AND not
#     over-broad, independent of the live tree's tracker mode.
import tempfile, shutil, pathlib, os, subprocess
t3_tmp = tempfile.mkdtemp(prefix="vp-check40-t3-")
t3_root = pathlib.Path(t3_tmp)
(t3_root / "test-fixtures" / "ft").mkdir(parents=True)
(t3_root / "test-fixtures" / "ft" / "tracker.toml").write_text("fixture copy")
(t3_root / "scripts" / "tests" / "fixtures" / "rt").mkdir(parents=True)
(t3_root / "scripts" / "tests" / "fixtures" / "rt" / "tracker.toml").write_text("fixture copy")
(t3_root / "tracker.toml").write_text("root runtime analog")
# BD-244: _build_basename_index() enumerates git ls-files (tracked-only), so the
# synthetic tree MUST be a git work tree with its files staged.
_t3_env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
           "HOME": str(t3_root), "PATH": os.environ.get("PATH", "")}
subprocess.run(["git", "init", "-q"], cwd=t3_root, env=_t3_env, check=True)
subprocess.run(["git", "add", "-A"], cwd=t3_root, env=_t3_env, check=True)
saved_root_t3 = mod.REPO_ROOT
try:
    _patch_root(mod, t3_root)
    t3_index = mod._build_basename_index()
finally:
    _patch_root(mod, saved_root_t3)
    shutil.rmtree(t3_tmp, ignore_errors=True)
t3_cands = sorted(str(p) for p in t3_index.get("tracker.toml", []))
if t3_cands != ["tracker.toml"]:
    failures.append(
        "T3 EXCLUDE failed — expected exactly the root tracker.toml "
        f"candidate, got: {t3_cands} (fixture-tree copies must be "
        "excluded; the non-fixture root copy must be indexed)"
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
import sys, tempfile, os, pathlib, shutil, subprocess
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def _patch_root(mod, root):
    """Set REPO_ROOT on the facade alias AND every loaded validate_checks.*
    submodule (BD-256 W2 wave-invariant). The check body now lives in
    validate_checks.boundary_refs and reads boundary_refs.REPO_ROOT; a
    facade-only patch would NOT bite. Setting it on every loaded
    validate_checks.* reaches the read wherever the body resolves it."""
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


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

    # BD-244: _build_basename_index() enumerates git ls-files (tracked-only), so
    # the synthetic tree MUST be a git work tree with its files staged.
    _env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
            "HOME": str(root), "PATH": os.environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=_env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=_env, check=True)

    import io, contextlib
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_bare_pack_ops_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
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

# T7: EXCLUDED basenames. BD-203 no-mirror model: BACKLOG.md and
#     CHANGELOG.md are the deleted monoliths (the per-entry trees are the
#     SSOT). The Check 40 walk excludes these basenames, so even a
#     synthetic pack-ops/BACKLOG.md carrying a bare ref is SKIPPED (the
#     exclusion is inert once the files are gone, and harmless while they
#     still exist during conversion). NOT "regenerated mirrors".
fail_count, pass_msg, captured = run_check_with_synthetic(
    {
        "BACKLOG.md": "Has bare \`UNQUALIFIED-REF.md\` ref — should be skipped.\n",
        "CHANGELOG.md": "Has bare \`ANOTHER-REF.md\` ref — should be skipped.\n",
    },
)
if fail_count != 0:
    failures.append(f"T7 (monolith-basename SKIP) expected 0 failures, got {fail_count}: {captured}")
if "BACKLOG.md" in captured.replace("excluded", "").replace("BACKLOG.md/", ""):
    # Lenient — the message format may include the name in context
    pass

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

# T9: EXCLUDED basename — the verbatim dashboard build spec. BD-224:
#     DASHBOARD-SPEC-PACK.md is a USER-OWNED byte-faithful source committed
#     verbatim; its bare \`pack-help.sh\` reference cannot be qualified without
#     violating byte-faithfulness, so the Check 40 walk excludes the basename
#     (excluded_basenames). Even a synthetic pack-ops/DASHBOARD-SPEC-PACK.md
#     carrying that bare ref is SKIPPED. This is the Check-40 surface's OWN
#     exclusion — SEPARATE from the _CHECK_OPERATING_DOC_EXEMPT entry that
#     exempts the spec from Checks 65/67/68/69 (Check 40 walks pack-ops/*.md on
#     its own glob and never consults _iter_operating_docs).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"DASHBOARD-SPEC-PACK.md": "The help table names \`pack-help.sh\` + command set.\n"},
    {"scripts/pack-help.sh": "stub"},
)
if fail_count != 0:
    failures.append(f"T9 (spec-basename SKIP) expected 0 failures, got {fail_count}: {captured}")

# T9b: CONTROL — the SAME bare ref in a NON-excluded pack-ops doc DOES fail,
#      proving the exclusion (not a harmless ref) is what clears T9. The bare
#      \`pack-help.sh\` has one candidate scripts/pack-help.sh in a different dir
#      than pack-ops/ (and is not on _CHECK_40_ALLOWLIST) → qualify FAIL.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "The help table names \`pack-help.sh\` + command set.\n"},
    {"scripts/pack-help.sh": "stub"},
)
if fail_count != 1:
    failures.append(f"T9b (spec-exclusion control) expected 1 failure, got {fail_count}: {captured}")
if "scripts/pack-help.sh" not in captured:
    failures.append(f"T9b (spec-exclusion control) FAIL message must suggest scripts/pack-help.sh: {captured}")

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

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 40 > /tmp/vp-check40-e2e.out 2>&1; then
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
