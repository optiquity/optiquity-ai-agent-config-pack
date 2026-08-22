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
# Group 2c uses a QUOTED heredoc (so backticks in Python comments are not
# run as command substitution) and takes its paths from the environment.
export VP_CHECK39_REPO="$REPO_ROOT"

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
    '_parse_migrator_manifest_sources',
    '_CHECK_39_MIGRATOR_EXEMPTIONS',
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
# Group 2c: leg 3 — v10→v11 adapter manifest reverse direction (BD-093)
# ─────────────────────────────────────────────────────────────────
#
# Proves the widened leg BITES (declare-verify-backing): a
# `migrator_manifest()` / `migrator_directory_sweeps()` row whose pack-side
# source is not tracked at HEAD must FAIL, not merely be tolerated. The
# empirical case is the PROMPT-TEMPLATES.md row BD-093 deleted — retired in
# v10.0, silently inert at migration time, invisible to every prior gate.
#
# Hermetic: no test here creates a git repo, stages or commits. Each case
# stubs `validate_checks.boundary_refs.subprocess` so the leg's single
# `git ls-files -- project-template` call returns a controlled tracked set.

printf "\n=== Group 2c: leg-3 migrator-manifest reverse tests (BD-093) ===\n"

python3 <<'PYEOF'
import contextlib
import io
import os
import pathlib
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.environ["VP_CHECK39_REPO"] + "/scripts")
import importlib.util
spec = importlib.util.spec_from_file_location(
    "vp", os.environ["VP_CHECK39_REPO"] + "/scripts/validate-pack.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
bref = sys.modules["validate_checks.boundary_refs"]


def _patch_root(mod, root):
    mod.REPO_ROOT = root
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, "REPO_ROOT"):
                _m.REPO_ROOT = root


class FakeCompleted:
    def __init__(self, stdout="", returncode=0):
        self.stdout = stdout
        self.stderr = ""
        self.returncode = returncode


class FakeSubprocess:
    """Answers the leg-3 `git ls-files` call only, recording its argv so the
    DERIVED pathspec (S3) is assertable."""

    def __init__(self, tracked, rc=0):
        self.tracked = tracked
        self.rc = rc
        self.last_ls_files_cmd = None

    def run(self, cmd, **kw):
        if cmd[:2] == ["git", "ls-files"]:
            self.last_ls_files_cmd = list(cmd)
            return FakeCompleted("\n".join(self.tracked), self.rc)
        return FakeCompleted("", 1)


# The most recent stub instance, so a test can inspect the argv leg 3 issued
# (run_leg3 restores bref.subprocess in its finally block).
LAST_FAKE = []


failures = []

ADAPTER_TMPL = """#!/usr/bin/env bash
migrator_manifest() {
    cat <<'EOF'
%s
EOF
}

migrator_directory_sweeps() {
    cat <<'EOF'
%s
EOF
}
"""

# Non-canonical but entirely VALID adapter shapes. The adapter contract
# (`_migrator_required_hooks` in scripts/lib/migrator-core.sh) fixes the hook
# NAMES, not the heredoc spelling, so every shape below is a legal adapter.
# A parser that understands only the canonical `cat <<'EOF'` form returns no
# rows on these, the leg's `if mig_files or mig_dirs:` short-circuits, and
# Check 39 PASSES while checking nothing. T20-T23 pin that it bites on each.
ADAPTER_TMPL_RENAMED_MARKER = (
    ADAPTER_TMPL.replace("'EOF'", "'ROWS'").replace("\nEOF\n", "\nROWS\n"))
ADAPTER_TMPL_UNQUOTED = ADAPTER_TMPL.replace("<<'EOF'", "<<EOF")
ADAPTER_TMPL_COMMENT_FIRST = ADAPTER_TMPL.replace(
    "() {\n", "() {\n    # a leading comment\n")
ADAPTER_TMPL_INDENTED = (
    ADAPTER_TMPL.replace("cat <<'EOF'", "cat <<-'EOF'")
                .replace("\nEOF\n}", "\n\tEOF\n}"))

# An adapter whose manifest hook is the EMPTY `{ :; }` form (the shape
# migrator_relocations/migrator_artifact_installs already use in the live
# adapter). `%.0s` swallows the manifest-rows argument so the template still
# takes the same two format arguments as the others.
ADAPTER_TMPL_EMPTY_MANIFEST = """#!/usr/bin/env bash
migrator_manifest() { :; }%.0s

migrator_directory_sweeps() {
    cat <<'EOF'
%s
EOF
}
"""


def run_leg3(manifest_rows, sweep_rows, tracked, git_rc=0, exemptions=None,
             tmpl=None):
    """Run Check 39 with a synthetic adapter + stubbed git ls-files.

    Legs 1+2 are made trivially clean (one docs/pack file with a matching,
    resolvable cmd_update entry) so any failure counted here is leg 3's."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check39-leg3-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    (root / "project-template" / "docs" / "pack" / "FOO.md").write_text("# stub\n")
    (root / "scripts" / "init-project.sh").write_text(
        '#!/usr/bin/env bash\ncmd_update() {\n    local entries=(\n'
        '        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"\n'
        '    )\n    echo stub\n}\n')
    (root / "scripts" / "migrate-v10-to-v11.sh").write_text(
        (tmpl or ADAPTER_TMPL)
        % ("\n".join(manifest_rows), "\n".join(sweep_rows)))

    saved_root = mod.REPO_ROOT
    saved_sub = bref.subprocess
    saved_exempt = dict(bref._CHECK_39_MIGRATOR_EXEMPTIONS)
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    bref.subprocess = FakeSubprocess(tracked, git_rc)
    LAST_FAKE.append(bref.subprocess)
    if exemptions is not None:
        bref._CHECK_39_MIGRATOR_EXEMPTIONS.clear()
        bref._CHECK_39_MIGRATOR_EXEMPTIONS.update(exemptions)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_cmd_update_symmetry()
        n = len(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        bref.subprocess = saved_sub
        bref._CHECK_39_MIGRATOR_EXEMPTIONS.clear()
        bref._CHECK_39_MIGRATOR_EXEMPTIONS.update(saved_exempt)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
    return (n, captured)


TRACKED_OK = [
    "project-template/docs/pack/FOO.md",
    "project-template/CLAUDE.md",
    "project-template/scripts/validate.sh",
]

# T10 — PASS: every declared manifest row + sweep dir is tracked.
n, out = run_leg3(
    ["project-template/CLAUDE.md\tCLAUDE.md\ttrinity\ttransform"],
    ["project-template/scripts pack-script"],
    TRACKED_OK)
if n != 0:
    failures.append("T10 expected 0 failures for a fully-backed adapter, got %d\n%s" % (n, out))

# T11 — THE BITE: a manifest row whose source is NOT tracked (the empirical
# PROMPT-TEMPLATES.md case) must FAIL.
n, out = run_leg3(
    ["project-template/CLAUDE.md\tCLAUDE.md\ttrinity\ttransform",
     "project-template/docs/pack/PROMPT-TEMPLATES.md\tdocs/pack/PROMPT-TEMPLATES.md\tgeneric\ttransform"],
    ["project-template/scripts pack-script"],
    TRACKED_OK)
if n != 1:
    failures.append("T11 expected exactly 1 failure for a dead manifest row, got %d\n%s" % (n, out))
if "PROMPT-TEMPLATES.md" not in out or "migrator_manifest()" not in out:
    failures.append("T11 failure message did not name the dead row + hook:\n%s" % out)

# T12 — BITE on the sweep hook: a declared directory with nothing tracked
# under it must FAIL (no asymmetric coverage between the two hooks).
n, out = run_leg3(
    ["project-template/CLAUDE.md\tCLAUDE.md\ttrinity\ttransform"],
    ["project-template/scripts pack-script",
     "project-template/.gemini/agents pack-agent"],
    TRACKED_OK)
if n != 1:
    failures.append("T12 expected exactly 1 failure for a dead sweep dir, got %d\n%s" % (n, out))
if "migrator_directory_sweeps()" not in out:
    failures.append("T12 failure message did not name the sweep hook:\n%s" % out)

# T13 — a tracked-but-only-as-a-parent directory is backed (the sweep dir is
# a PARENT of tracked files, never itself a tracked path).
n, out = run_leg3(
    [], ["project-template/scripts pack-script"], TRACKED_OK)
if n != 0:
    failures.append("T13 expected 0 failures for a parent-of-tracked sweep dir, got %d\n%s" % (n, out))

# T14 — the exemption allowlist clears an intentionally-absent row.
n, out = run_leg3(
    ["project-template/docs/pack/PROMPT-TEMPLATES.md\tdocs/pack/PROMPT-TEMPLATES.md\tgeneric\ttransform"],
    [], TRACKED_OK,
    exemptions={"project-template/docs/pack/PROMPT-TEMPLATES.md": "test rationale"})
if n != 0:
    failures.append("T14 expected 0 failures when the row is allowlisted, got %d\n%s" % (n, out))

# T15 — allowlist is NOT a blanket: a DIFFERENT dead row still FAILs.
n, out = run_leg3(
    ["project-template/docs/pack/PROMPT-TEMPLATES.md\tdocs/pack/PROMPT-TEMPLATES.md\tgeneric\ttransform",
     "project-template/docs/pack/GHOST.md\tdocs/pack/GHOST.md\tgeneric\ttransform"],
    [], TRACKED_OK,
    exemptions={"project-template/docs/pack/PROMPT-TEMPLATES.md": "test rationale"})
if n != 1:
    failures.append("T15 expected exactly 1 failure (GHOST.md still dead), got %d\n%s" % (n, out))

# T16 — git unavailable => leg 3 SKIPs leniently, never a false FAIL.
n, out = run_leg3(
    ["project-template/docs/pack/PROMPT-TEMPLATES.md\tdocs/pack/PROMPT-TEMPLATES.md\tgeneric\ttransform"],
    [], [], git_rc=1)
if n != 0:
    failures.append("T16 expected 0 failures when git is unavailable, got %d\n%s" % (n, out))
if "skipping the migrator-manifest reverse leg" not in out:
    failures.append("T16 did not report the lenient skip:\n%s" % out)

# T17 — the REAL adapter must parse to a NON-EMPTY, well-formed result.
# UNCONDITIONAL BY DESIGN. An outer `if srcs != ([], []):` guard would gate
# the non-emptiness assertion on the result ALREADY being non-empty, so the
# one and only case it could never detect is total parser inertness — which
# is precisely the failure mode this test exists to pin. REPO_ROOT is
# restored by now, so this reads the REAL adapter.
f_rows, d_rows = bref._parse_migrator_manifest_sources()
if not f_rows:
    failures.append(
        "T17 real adapter yielded ZERO migrator_manifest rows — the parser is "
        "INERT, so leg 3 short-circuits and Check 39 passes checking nothing")
if not d_rows:
    failures.append(
        "T17 real adapter yielded ZERO migrator_directory_sweeps rows — the "
        "parser is INERT on the sweep hook")
if any("\t" in r or " " in r for r in f_rows + d_rows):
    failures.append(
        "T17 parsed rows are not bare paths: %r" % ((f_rows, d_rows),))

# T18 — LIVE summary floor. T17 pins the parser in isolation; this pins the
# number the CHECK ITSELF prints on the real tree, so a leg that quietly
# reports "0 row(s) reverse-checked" and passes cannot go unnoticed.
_repo = os.environ["VP_CHECK39_REPO"]
_r = subprocess.run(
    [sys.executable, _repo + "/scripts/validate-pack.py", "--only-check", "39"],
    cwd=_repo, capture_output=True, text=True)
_m = re.search(
    r"(\d+) v10.{0,3}v11 adapter manifest/sweep row\(s\) reverse-checked",
    _r.stdout)
if not _m:
    failures.append(
        "T18 leg-3 summary absent from the live --only-check 39 run "
        "(rc=%d):\n%s" % (_r.returncode, _r.stdout[-1500:]))
elif int(_m.group(1)) < 1:
    failures.append(
        "T18 live leg-3 summary reports %s row(s) reverse-checked — the leg "
        "is INERT on the real adapter" % _m.group(1))

# T19 — adapter absent entirely => leg 3 contributes nothing (Group 2b's
# synthetic trees have no adapter; this pins that backward compatibility).
_empty_root = pathlib.Path(tempfile.mkdtemp(prefix="vp-check39-noadapter-"))
_saved = mod.REPO_ROOT
try:
    _patch_root(mod, _empty_root)
    _srcs = bref._parse_migrator_manifest_sources()
finally:
    _patch_root(mod, _saved)
if _srcs != ([], []):
    failures.append("T19 absent adapter should parse to ([], []), got %r" % (_srcs,))

# T20-T23 — PARSER BITE across non-canonical adapter shapes. Each adapter is
# legal and carries the SAME dead manifest row; the leg must FAIL on every
# one. A parser that only understands `cat <<'EOF'` returns no rows here and
# these tests go to 0 failures — which is the regression they exist to catch.
DEAD_ROW = ("project-template/docs/pack/PROMPT-TEMPLATES.md\t"
            "docs/pack/PROMPT-TEMPLATES.md\tgeneric\ttransform")
GOOD_ROW = "project-template/CLAUDE.md\tCLAUDE.md\ttrinity\ttransform"
GOOD_SWEEP = "project-template/scripts pack-script"

for _tid, _label, _tmpl in (
    ("T20", "renamed heredoc marker", ADAPTER_TMPL_RENAMED_MARKER),
    ("T21", "unquoted heredoc", ADAPTER_TMPL_UNQUOTED),
    ("T22", "comment before the cat", ADAPTER_TMPL_COMMENT_FIRST),
    ("T23", "indented <<- heredoc", ADAPTER_TMPL_INDENTED),
):
    n, out = run_leg3([GOOD_ROW, DEAD_ROW], [GOOD_SWEEP], TRACKED_OK,
                      tmpl=_tmpl)
    if n != 1:
        failures.append(
            "%s (%s) expected exactly 1 failure for the dead row, got %d — "
            "the parser went INERT on this adapter shape, so leg 3 checked "
            "nothing\n%s" % (_tid, _label, n, out))
    elif "PROMPT-TEMPLATES.md" not in out:
        failures.append(
            "%s (%s) failure did not name the dead row:\n%s" % (_tid, _label, out))

# T24 — an EMPTY hook must yield NO rows, never the NEXT hook's rows. An
# unbounded heredoc scan runs past the empty `migrator_manifest() { :; }`
# and returns the sweep rows as manifest rows: `project-template/scripts` is
# then tested as a FILE, is not a tracked file path, and FAILs. A wrong
# answer is worse than an empty one, so this must stay at 0 failures.
n, out = run_leg3([DEAD_ROW], [GOOD_SWEEP], TRACKED_OK,
                  tmpl=ADAPTER_TMPL_EMPTY_MANIFEST)
if n != 0:
    failures.append(
        "T24 expected 0 failures for an empty manifest hook, got %d — the "
        "parser leaked the NEXT hook's rows into the manifest result\n%s"
        % (n, out))

# T25 — S3: the `git ls-files` pathspec is DERIVED from the declared rows,
# never hard-coded to `project-template`. The adapter contract imposes no
# such restriction and `supporting-docs/` is an equally legitimate
# client-deliverable root, so a row sourced there must be tested against a
# tracked set that CAN contain it — otherwise the leg FAILs with a message
# falsely asserting the source "is NOT tracked at HEAD, so it does not ship".
n, out = run_leg3(
    ["supporting-docs/MIGRATION-v10-to-v11.md\tdocs/MIGRATION.md\tgeneric\ttransform"],
    ["project-template/scripts pack-script"],
    TRACKED_OK + ["supporting-docs/MIGRATION-v10-to-v11.md"])
_cmd = LAST_FAKE[-1].last_ls_files_cmd
if not _cmd:
    failures.append("T25 leg 3 issued no `git ls-files` call at all")
else:
    _specs = _cmd[_cmd.index("--") + 1:] if "--" in _cmd else []
    if "supporting-docs" not in _specs:
        failures.append(
            "T25 pathspec %r omits `supporting-docs` — the pathspec is "
            "hard-coded, so a row sourced outside project-template/ is tested "
            "against a set that cannot contain it (false FAIL)" % (_specs,))
    if "project-template" not in _specs:
        failures.append("T25 pathspec %r dropped `project-template`" % (_specs,))
    if len(_specs) != 2:
        failures.append(
            "T25 expected exactly the 2 derived prefixes, got %r" % (_specs,))
if n != 0:
    failures.append(
        "T25 expected 0 failures for a tracked supporting-docs/ row, got "
        "%d\n%s" % (n, out))

if failures:
    for f in failures:
        print("FAILURE: " + f)
    sys.exit(1)
print("OK")
PYEOF
case $? in
    0) t_pass "leg-3 migrator-manifest reverse tests (T10-T25)" ;;
    *) t_fail "leg-3 migrator-manifest tests failed (see Python output above)" ;;
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
