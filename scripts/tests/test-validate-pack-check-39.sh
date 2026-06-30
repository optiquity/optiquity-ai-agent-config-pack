#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-39.sh — synthetic fixture
# tests for BD-175 F2a Check 39 (cmd_update mapping/glob symmetry).
#
# These tests exercise the per-check parsing + symmetry logic without
# mutating any real pack files. Each test stages a synthetic input
# (custom init-project.sh fragment or docs/pack/ directory layout
# inside a tmp REPO_ROOT), invokes Check 39 against the tmp tree,
# and asserts PASS / FAIL as expected.
#
# Usage: bash scripts/tests/test-validate-pack-check-39.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
FIXTURES_DIR="$REPO_ROOT/scripts/tests/fixtures/cmd-update-symmetry"

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

printf "\n=== Group 0: Module import + Check 39 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_cmd_update_symmetry',
    '_parse_cmd_update_entries',
    '_CHECK_39_EXEMPTIONS',
    '_CHECK_39_REVERSE_EXEMPTIONS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check39-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check39-import.out; then
    t_pass "validate-pack.py imports + Check 39 symbols registered"
else
    t_fail "validate-pack.py import or Check 39 symbol registration failed" \
        "$(cat /tmp/vp-check39-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: _parse_cmd_update_entries — parses real init-project.sh
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: _parse_cmd_update_entries unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Parse real init-project.sh.
entries = mod._parse_cmd_update_entries()

# Must find at least the 5 known docs/pack entries (HELP-FRAGMENT,
# OPTIONAL-FEATURES, PACK-FEEDBACK, PLATFORM-SKILLS, PM-CHAT) plus the
# trinity and the config files.
required_subset = {
    "project-template/docs/pack/PM-CHAT.md",
    "project-template/docs/pack/PLATFORM-SKILLS.md",
    "project-template/docs/pack/PACK-FEEDBACK.md",
    "project-template/docs/pack/HELP-FRAGMENT.md",
    "project-template/docs/pack/OPTIONAL-FEATURES.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
}
missing = required_subset - entries
if missing:
    failures.append(f"T1 expected entries missing: {sorted(missing)}")

# Sanity: entries count is in expected range (15-30 today, allowing growth).
if len(entries) < 15 or len(entries) > 50:
    failures.append(f"T2 entries count {len(entries)} outside expected range 15-50")

# No comment lines should be parsed as entries.
for e in entries:
    if e.startswith("#"):
        failures.append(f"T3 comment line parsed as entry: {e!r}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_parse_cmd_update_entries parses real init-project.sh correctly" ;;
    *) t_fail "_parse_cmd_update_entries parse tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic init-project.sh fragments (PASS / FAIL paths)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic init-project.sh PASS/FAIL fragment tests ===\n"

python3 <<EOF
import sys, tempfile, os, re, pathlib
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

# Helper: build a synthetic REPO_ROOT with custom scripts/init-project.sh
# (only the entries=() array body matters for the parser) and a custom
# project-template/docs/pack/ directory. Invoke check_cmd_update_symmetry
# against the synthetic root by swapping mod.REPO_ROOT in-place.
def run_check_with_synthetic(entries_body: str, docs_pack_files: list, exemptions: dict = None) -> tuple:
    """Return (failures_count, pass_msg_present, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check39-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    for name in docs_pack_files:
        (root / "project-template" / "docs" / "pack" / name).write_text("# stub\n")
    init_sh_content = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
%s
    )
    echo "stub"
}
''' % entries_body
    (root / "scripts" / "init-project.sh").write_text(init_sh_content)

    # Capture stdout + mod.failures.
    import io, contextlib
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    saved_exemptions = dict(mod._CHECK_39_EXEMPTIONS)
    if exemptions is not None:
        mod._CHECK_39_EXEMPTIONS.clear()
        mod._CHECK_39_EXEMPTIONS.update(exemptions)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cmd_update_symmetry()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        mod._CHECK_39_EXEMPTIONS.clear()
        mod._CHECK_39_EXEMPTIONS.update(saved_exemptions)
    pass_msg = "no asymmetric coverage" in captured.lower()
    return (len(new_failures), pass_msg, captured)

# T1: PASS path — every docs/pack/*.md has an explicit cmd_update mapping
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/BAR.md:docs/pack/BAR.md:generic"'''
fail_count, pass_msg, captured = run_check_with_synthetic(
    entries_body, ["FOO.md", "BAR.md"]
)
if fail_count != 0:
    failures.append(f"T1 (PASS path) expected 0 failures, got {fail_count}: {captured}")
if not pass_msg:
    failures.append(f"T1 (PASS path) missing pass message in output: {captured}")

# T2: FAIL path — a docs/pack/*.md file lacks an explicit cmd_update mapping
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
# BAZ.md added on disk but missing from cmd_update entries:
fail_count, pass_msg, captured = run_check_with_synthetic(
    entries_body, ["FOO.md", "BAZ.md"]
)
if fail_count != 1:
    failures.append(f"T2 (FAIL path) expected 1 failure, got {fail_count}: {captured}")
if "BAZ.md" not in captured:
    failures.append(f"T2 (FAIL path) FAIL message must name BAZ.md: {captured}")
if "cmd_update" not in captured:
    failures.append(f"T2 (FAIL path) FAIL message must reference cmd_update: {captured}")

# T3: PASS-with-exemption path — file is on the allowlist
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
fail_count, pass_msg, captured = run_check_with_synthetic(
    entries_body,
    ["FOO.md", "MIGRATION-INSTRUCTIONS.md"],
    exemptions={"MIGRATION-INSTRUCTIONS.md": "pre-install reference; does not install to clients"}
)
if fail_count != 0:
    failures.append(f"T3 (exempt path) expected 0 failures, got {fail_count}: {captured}")
if "exempt per _CHECK_39_EXEMPTIONS" not in captured:
    failures.append(f"T3 (exempt path) must show exemption notice: {captured}")

# T4: empty docs/pack/ directory — forward direction passes vacuously.
# To satisfy reverse direction we must also create the source file that
# the entry references. The synthetic helper creates docs_pack_files in
# docs/pack/, so reusing STUB.md as both the entry source and an on-disk
# file under docs/pack/ satisfies both directions.
fail_count, pass_msg, captured = run_check_with_synthetic(
    '''        "project-template/docs/pack/STUB.md:docs/pack/STUB.md:generic"''',
    ["STUB.md"]
)
if fail_count != 0:
    failures.append(f"T4 (vacuous-pass-with-stub) expected 0 failures, got {fail_count}: {captured}")

# T5: comment-only entries body — array exists but no real entries.
#     Parser should return empty set; check should FAIL (cannot prove symmetry).
# NOTE: parser regex requires at least one non-blank, non-comment quoted line.
# Use a degenerate case: entries=() with only comments.
fail_count_t5, pass_msg_t5, captured_t5 = run_check_with_synthetic(
    '''        # only a comment, no real entries''',
    ["FOO.md"]
)
# Either we get a parse-failure FAIL, or we get a missing-mapping FAIL for FOO.md.
# Both are acceptable defensive behavior — we just require fail_count >= 1.
if fail_count_t5 < 1:
    failures.append(f"T5 (comment-only entries) expected ≥1 failure, got {fail_count_t5}: {captured_t5}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS / FAIL / exempt fragment tests" ;;
    *) t_fail "Synthetic fragment tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2b: Reverse-direction synthetic tests (BD-180 observation E)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2b: Reverse-direction (BD-180 E) synthetic tests ===\n"

python3 <<EOF
import sys, tempfile, os, re, pathlib
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

# Reverse-direction helper. Like run_check_with_synthetic but pack_relpaths
# in the entries body can point at arbitrary paths; the test controls
# which of those paths exist on disk via extant_paths.
def run_reverse(entries_body: str, docs_pack_files: list, extant_paths: list,
                forward_exemptions: dict = None, reverse_exemptions: dict = None) -> tuple:
    """Return (failures_count, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check39-rev-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    for name in docs_pack_files:
        (root / "project-template" / "docs" / "pack" / name).write_text("# stub\n")
    # Stage arbitrary extant pack_relpaths.
    for ep in extant_paths:
        target = root / ep
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# stub\n")
    init_sh_content = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
%s
    )
    echo "stub"
}
''' % entries_body
    (root / "scripts" / "init-project.sh").write_text(init_sh_content)

    import io, contextlib
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    saved_fwd = dict(mod._CHECK_39_EXEMPTIONS)
    saved_rev = dict(mod._CHECK_39_REVERSE_EXEMPTIONS)
    mod.failures.clear()
    _patch_root(mod, root)
    if forward_exemptions is not None:
        mod._CHECK_39_EXEMPTIONS.clear()
        mod._CHECK_39_EXEMPTIONS.update(forward_exemptions)
    if reverse_exemptions is not None:
        mod._CHECK_39_REVERSE_EXEMPTIONS.clear()
        mod._CHECK_39_REVERSE_EXEMPTIONS.update(reverse_exemptions)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cmd_update_symmetry()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        mod._CHECK_39_EXEMPTIONS.clear()
        mod._CHECK_39_EXEMPTIONS.update(saved_fwd)
        mod._CHECK_39_REVERSE_EXEMPTIONS.clear()
        mod._CHECK_39_REVERSE_EXEMPTIONS.update(saved_rev)
    return (len(new_failures), captured)

# T6: reverse-PASS path — every cmd_update entry's pack_relpath exists on disk.
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
fail_count, captured = run_reverse(
    entries_body,
    docs_pack_files=["FOO.md"],
    extant_paths=["project-template/docs/pack/FOO.md"],
)
if fail_count != 0:
    failures.append(f"T6 (reverse PASS) expected 0 failures, got {fail_count}: {captured}")

# T7: reverse-FAIL path — cmd_update entry's pack_relpath does NOT exist
# on disk (BD-180 E PROMPT-TEMPLATES-style stale mapping).
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/STALE.md:docs/pack/STALE.md:generic"'''
fail_count, captured = run_reverse(
    entries_body,
    docs_pack_files=["FOO.md"],     # STALE.md NOT on disk
    extant_paths=["project-template/docs/pack/FOO.md"],
)
if fail_count != 1:
    failures.append(f"T7 (reverse FAIL stale) expected 1 failure, got {fail_count}: {captured}")
if "STALE.md" not in captured:
    failures.append(f"T7 (reverse FAIL stale) FAIL message must name STALE.md: {captured}")
if "stale" not in captured.lower():
    failures.append(f"T7 (reverse FAIL stale) FAIL message must contain word 'stale': {captured}")

# T8: reverse-PASS-with-exemption — stale entry but on reverse exemption allowlist.
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "extern/IMAGINARY.md:docs/pack/IMAGINARY.md:generic"'''
fail_count, captured = run_reverse(
    entries_body,
    docs_pack_files=["FOO.md"],
    extant_paths=["project-template/docs/pack/FOO.md"],
    reverse_exemptions={"extern/IMAGINARY.md": "intentional extern-resolved (test stub)"},
)
if fail_count != 0:
    failures.append(f"T8 (reverse exempt) expected 0 failures, got {fail_count}: {captured}")
if "exempt per _CHECK_39_REVERSE_EXEMPTIONS" not in captured:
    failures.append(f"T8 (reverse exempt) must show reverse exemption notice: {captured}")

# T9: combined forward+reverse failures — one of each.
entries_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/STALE.md:docs/pack/STALE.md:generic"'''
fail_count, captured = run_reverse(
    entries_body,
    docs_pack_files=["FOO.md", "BAZ.md"],  # BAZ.md on disk but not in entries
    extant_paths=["project-template/docs/pack/FOO.md"],  # STALE.md not extant
)
# Expect 2 failures: forward (BAZ.md missing mapping) + reverse (STALE.md absent source).
if fail_count != 2:
    failures.append(f"T9 (combined fail) expected 2 failures, got {fail_count}: {captured}")
if "BAZ.md" not in captured:
    failures.append(f"T9 forward leg must name BAZ.md: {captured}")
if "STALE.md" not in captured:
    failures.append(f"T9 reverse leg must name STALE.md: {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Reverse-direction synthetic tests (T6/T7/T8/T9)" ;;
    *) t_fail "Reverse-direction tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Static fixture files exercise PASS / FAIL / exempt cases
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: Static fixture file sanity ===\n"

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

# Expected fixture inventory (drives Group 3 + serves as a documentation
# anchor for what cases the check covers).
expected_fixtures = {
    "README.md": "fixture set documentation",
    "init-fragment-pass.sh": "synthetic init-project.sh with all entries present",
    "init-fragment-fail-missing.sh": "synthetic init-project.sh with one entry missing",
    "init-fragment-fail-malformed.sh": "synthetic init-project.sh with malformed entries array",
}
for name, why in expected_fixtures.items():
    if not (fixtures_dir / name).is_file():
        failures.append(f"missing fixture: {name} ({why})")

# Parse the PASS fragment — must yield a non-empty entries set.
pass_frag = fixtures_dir / "init-fragment-pass.sh"
if pass_frag.is_file():
    import re
    text = pass_frag.read_text()
    m = re.search(r"local\s+entries=\(\s*\n(.+?)\n\s*\)", text, re.DOTALL)
    if not m:
        failures.append(f"init-fragment-pass.sh: entries array not parseable")
    else:
        body = m.group(1)
        ec = body.count('"project-template/')
        if ec < 3:
            failures.append(f"init-fragment-pass.sh: expected ≥3 entries, got {ec}")

# Parse the MISSING fragment — must yield a smaller entries set than PASS.
miss_frag = fixtures_dir / "init-fragment-fail-missing.sh"
if miss_frag.is_file() and pass_frag.is_file():
    import re
    pass_text = pass_frag.read_text()
    miss_text = miss_frag.read_text()
    pm = re.search(r"local\s+entries=\(\s*\n(.+?)\n\s*\)", pass_text, re.DOTALL)
    mm = re.search(r"local\s+entries=\(\s*\n(.+?)\n\s*\)", miss_text, re.DOTALL)
    if pm and mm:
        pec = pm.group(1).count('"project-template/')
        mec = mm.group(1).count('"project-template/')
        if mec >= pec:
            failures.append(
                f"init-fragment-fail-missing.sh: expected fewer entries than "
                f"pass fragment ({mec} vs {pec})"
            )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Static fixture file sanity (PASS / FAIL fragments parseable)" ;;
    *) t_fail "Static fixture sanity failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 39 > /tmp/vp-check39-e2e.out 2>&1; then
    if grep -q "Check 39: cmd_update mapping/glob symmetry" /tmp/vp-check39-e2e.out \
       && grep -qE "Check 39 — .* file\(s\) forward-checked" /tmp/vp-check39-e2e.out \
       && grep -qE "[0-9]+ \`cmd_update\` entries reverse-checked" /tmp/vp-check39-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 39 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 39 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check39-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check39-e2e.out)"
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
