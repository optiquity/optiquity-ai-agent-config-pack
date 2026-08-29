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
    '_parse_client_installed_file_stages',
    '_parse_client_installed_globs',
    '_install_glob_matches',
    '_CHECK_39_EXEMPTIONS',
    '_CHECK_39_REVERSE_EXEMPTIONS',
    '_parse_migrator_manifest_sources',
    '_CHECK_39_MIGRATOR_EXEMPTIONS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
# The array parser is RETIRED. The install map is the ONE declaration; a
# surviving second parser is exactly how the two drifted apart before.
if hasattr(mod, '_parse_cmd_update_entries'):
    print('FAIL_RETIRED _parse_cmd_update_entries still reachable')
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
# Group 1: the cmd_update axis, DERIVED from the real install map
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: map-derived cmd_update axis unit tests ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# The cmd_update axis is DERIVED from the install map — the explicit rows
# tagged cmd_update, union the family rows tagged cmd_update.
stage_map = mod._parse_client_installed_file_stages()
entries = {p for p, st in stage_map.items() if "cmd_update" in st}
glob_rows = mod._parse_client_installed_globs()
glob_patterns = [pat for pat, _d, st, _c in glob_rows if "cmd_update" in st]

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
    failures.append(f"T1 expected map rows missing: {sorted(missing)}")

# Sanity: row count is in the expected range (allowing growth).
if len(entries) < 15 or len(entries) > 50:
    failures.append(f"T2 explicit cmd_update row count {len(entries)} outside range 15-50")

# No comment lines should be parsed as rows.
for e in entries:
    if e.startswith("#"):
        failures.append(f"T3 comment line parsed as a row: {e!r}")

# T4: every explicit row carries a [class:...] operand — the class is a
# first-class operand of the declaration, not a copy-site-local secret.
text = (mod.REPO_ROOT / "scripts" / "init-project.sh").read_text()
import re as _re
_m = _re.search(
    r"_CLIENT_INSTALLED_FILES_START\s*\n(.+?)\n[^\n]*_CLIENT_INSTALLED_FILES_END",
    text, _re.DOTALL)
if not _m:
    failures.append("T4 could not capture the explicit block body")
else:
    for line in _m.group(1).splitlines():
        s = line.strip().lstrip("#").strip()
        if "->" not in s:
            continue
        if "[class:" not in s:
            failures.append(f"T4 explicit row lacks a [class:] operand: {s!r}")

# T5: the family block is non-empty and every family row is cmd_update-tagged
# and carries a class operand.
if not glob_rows:
    failures.append("T5 the GLOB block yielded no family rows")
if not glob_patterns:
    failures.append("T5 no family row is tagged cmd_update")
for pat, dest, st, cls in glob_rows:
    if not cls:
        failures.append(f"T5 family row lacks a [class:] operand: {pat}")
    if "[" in dest or "]" in dest:
        failures.append(f"T5 family DEST retains a bracketed operand: {dest!r}")

# T6: the prompts family is declared, and it is declared as a FAMILY (the
# non-recursive docs/pack/*.md leg can never reach prompts/).
if not any("docs/pack/prompts/" in p for p in glob_patterns):
    failures.append(f"T6 no cmd_update family row covers docs/pack/prompts/: {glob_patterns}")

# T7: the glob matcher does not let '*' cross a path separator.
if mod._install_glob_matches("project-template/scripts/*", "project-template/scripts/sub/deep.sh"):
    failures.append("T7 '*' must not cross '/' in an install-map family pattern")
if not mod._install_glob_matches("project-template/scripts/*", "project-template/scripts/test.sh"):
    failures.append("T7 '*' must match within one path segment")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "cmd_update axis derives correctly from the real install map" ;;
    *) t_fail "map-derived cmd_update axis tests failed" ;;
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

# Helper: build a synthetic REPO_ROOT with a custom scripts/init-project.sh
# carrying an install map (both blocks) and a custom
# project-template/docs/pack/ directory. Invoke check_cmd_update_symmetry
# against the synthetic root by swapping mod.REPO_ROOT in-place.
#
# \`map_rows\` and \`glob_rows\` are lists of row bodies WITHOUT the leading
# \`#   \` — the helper writes the markers and the comment prefix.
def _init_sh_with_map(map_rows: list, glob_rows: list) -> str:
    out = ["#!/usr/bin/env bash", "# _CLIENT_INSTALLED_FILES_START"]
    out += ["#   " + r for r in map_rows]
    out.append("# _CLIENT_INSTALLED_FILES_END")
    if glob_rows is not None:
        out.append("#")
        out.append("# _CLIENT_INSTALLED_GLOBS_START")
        out += ["#   " + r for r in glob_rows]
        out.append("# _CLIENT_INSTALLED_GLOBS_END")
    return "\n".join(out) + "\n"


def run_check_with_synthetic(map_rows: list, docs_pack_files: list,
                             exemptions: dict = None, glob_rows: list = None,
                             prompts_files: list = None) -> tuple:
    """Return (failures_count, pass_msg_present, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check39-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    for name in docs_pack_files:
        (root / "project-template" / "docs" / "pack" / name).write_text("# stub\n")
    if prompts_files:
        (root / "project-template" / "docs" / "pack" / "prompts").mkdir()
        for name in prompts_files:
            (root / "project-template" / "docs" / "pack" / "prompts" / name).write_text("# stub\n")
    (root / "scripts" / "init-project.sh").write_text(
        _init_sh_with_map(map_rows, glob_rows)
    )

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

ROW_FOO = "project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update,migrate]  [class:generic]"
ROW_BAR = "project-template/docs/pack/BAR.md  ->  docs/pack/BAR.md  [stage:S6,cmd_update,migrate]  [class:generic]"
GLOB_PROMPTS = "project-template/docs/pack/prompts/*.md  ->  docs/pack/prompts/*.md  [stage:S6,cmd_update,migrate]  [class:generic]"

# T1: PASS path — every docs/pack/*.md is covered by a map row
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO, ROW_BAR], ["FOO.md", "BAR.md"]
)
if fail_count != 0:
    failures.append(f"T1 (PASS path) expected 0 failures, got {fail_count}: {captured}")
if not pass_msg:
    failures.append(f"T1 (PASS path) missing pass message in output: {captured}")

# T2: FAIL path — a docs/pack/*.md file has no map row
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO], ["FOO.md", "BAZ.md"]
)
if fail_count != 1:
    failures.append(f"T2 (FAIL path) expected 1 failure, got {fail_count}: {captured}")
if "BAZ.md" not in captured:
    failures.append(f"T2 (FAIL path) FAIL message must name BAZ.md: {captured}")
if "cmd_update" not in captured:
    failures.append(f"T2 (FAIL path) FAIL message must reference cmd_update: {captured}")

# T2b: MUTATION BITE — the SAME row with the cmd_update token REMOVED must
# make the forward leg FAIL. This is what proves the leg reads the operand
# and not merely the row's presence.
ROW_FOO_NO_CU = "project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,migrate]  [class:generic]"
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO_NO_CU, ROW_BAR], ["FOO.md", "BAR.md"]
)
if fail_count != 1:
    failures.append(f"T2b (drop cmd_update token) expected 1 failure, got {fail_count}: {captured}")
if "FOO.md" not in captured:
    failures.append(f"T2b FAIL message must name FOO.md: {captured}")

# T3: PASS-with-exemption path — file is on the allowlist. The key is the
#     REPO-RELATIVE PATH: the forward direction spans two directories, so a
#     basename key would be ambiguous across them.
EXEMPT_KEY = "project-template/docs/pack/MIGRATION-INSTRUCTIONS.md"
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO],
    ["FOO.md", "MIGRATION-INSTRUCTIONS.md"],
    exemptions={EXEMPT_KEY: "pre-install reference; does not install to clients"}
)
if fail_count != 0:
    failures.append(f"T3 (exempt path) expected 0 failures, got {fail_count}: {captured}")
if "exempt per _CHECK_39_EXEMPTIONS" not in captured:
    failures.append(f"T3 (exempt path) must show exemption notice: {captured}")

# T3b: discrimination — the BASENAME of that same file does NOT exempt it.
#      T3 and T3b differ only in the key form, so T3's pass is attributable
#      to path-keying rather than to the file being covered some other way.
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO],
    ["FOO.md", "MIGRATION-INSTRUCTIONS.md"],
    exemptions={"MIGRATION-INSTRUCTIONS.md": "basename key — must NOT exempt"}
)
if fail_count != 1:
    failures.append(
        f"T3b (basename key) expected 1 failure — a basename key must not "
        f"exempt, got {fail_count}: {captured}")
if "exempt per _CHECK_39_EXEMPTIONS" in captured:
    failures.append(f"T3b a basename key must not produce an exemption notice: {captured}")

# T4: single-row map — forward and reverse both satisfied by one stub.
fail_count, pass_msg, captured = run_check_with_synthetic(
    ["project-template/docs/pack/STUB.md  ->  docs/pack/STUB.md  [stage:S6,cmd_update,migrate]  [class:generic]"],
    ["STUB.md"]
)
if fail_count != 0:
    failures.append(f"T4 (single-row pass) expected 0 failures, got {fail_count}: {captured}")

# T5: a map whose blocks yield NO cmd_update row at all. The check must
# FAIL defensively rather than PASS by vacuity — the empty-derivation path
# is the one that silently voids the whole guard.
fail_count_t5, pass_msg_t5, captured_t5 = run_check_with_synthetic(
    ["# only a comment, no parseable row"],
    ["FOO.md"]
)
if fail_count_t5 < 1:
    failures.append(f"T5 (no derivable rows) expected >=1 failure, got {fail_count_t5}: {captured_t5}")
if "install map" not in captured_t5:
    failures.append(f"T5 diagnostic must name the install map, not an array literal: {captured_t5}")

# ── Prompts leg (the non-recursive docs/pack/*.md glob never reaches it) ──

# T10: PASS — a prompts file covered by the family row.
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO], ["FOO.md"],
    glob_rows=[GLOB_PROMPTS], prompts_files=["architect.md", "coder.md"]
)
if fail_count != 0:
    failures.append(f"T10 (prompts covered by family row) expected 0 failures, got {fail_count}: {captured}")

# T11: MUTATION BITE — delete the prompts family row and EVERY prompts file
# must FAIL. Without this leg the whole prompts/ family was invisible.
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO], ["FOO.md"],
    glob_rows=[], prompts_files=["architect.md", "coder.md"]
)
if fail_count != 2:
    failures.append(f"T11 (drop prompts family row) expected 2 failures, got {fail_count}: {captured}")
if "prompts/architect.md" not in captured or "prompts/coder.md" not in captured:
    failures.append(f"T11 FAIL must name each uncovered prompts file: {captured}")
if "GLOB-block row" not in captured:
    failures.append(f"T11 remediation must name the GLOB block for a prompts miss: {captured}")

# T12: a cmd_update family row matching ZERO files FAILs (declare-verify-backing).
fail_count, pass_msg, captured = run_check_with_synthetic(
    [ROW_FOO], ["FOO.md"],
    glob_rows=[GLOB_PROMPTS], prompts_files=None
)
if fail_count < 1:
    failures.append(f"T12 (zero-match family row) expected >=1 failure, got {fail_count}: {captured}")
if "matches NO file" not in captured:
    failures.append(f"T12 diagnostic must say the family row matches no file: {captured}")

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

# Reverse-direction helper. Like run_check_with_synthetic but the map rows'
# pack_relpaths can point at arbitrary paths; the test controls which of
# those paths exist on disk via extant_paths.
def _init_sh_with_map(map_rows: list, glob_rows: list) -> str:
    out = ["#!/usr/bin/env bash", "# _CLIENT_INSTALLED_FILES_START"]
    out += ["#   " + r for r in map_rows]
    out.append("# _CLIENT_INSTALLED_FILES_END")
    if glob_rows is not None:
        out.append("#")
        out.append("# _CLIENT_INSTALLED_GLOBS_START")
        out += ["#   " + r for r in glob_rows]
        out.append("# _CLIENT_INSTALLED_GLOBS_END")
    return "\n".join(out) + "\n"


def run_reverse(map_rows: list, docs_pack_files: list, extant_paths: list,
                forward_exemptions: dict = None, reverse_exemptions: dict = None,
                glob_rows: list = None) -> tuple:
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
    (root / "scripts" / "init-project.sh").write_text(
        _init_sh_with_map(map_rows, glob_rows)
    )

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

R_FOO = "project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update,migrate]  [class:generic]"
R_STALE = "project-template/docs/pack/STALE.md  ->  docs/pack/STALE.md  [stage:S6,cmd_update,migrate]  [class:generic]"
R_EXTERN = "extern/IMAGINARY.md  ->  docs/pack/IMAGINARY.md  [stage:S6,cmd_update,migrate]  [class:generic]"

# T6: reverse-PASS path — every cmd_update row's pack_relpath exists on disk.
fail_count, captured = run_reverse(
    [R_FOO],
    docs_pack_files=["FOO.md"],
    extant_paths=["project-template/docs/pack/FOO.md"],
)
if fail_count != 0:
    failures.append(f"T6 (reverse PASS) expected 0 failures, got {fail_count}: {captured}")

# T7: reverse-FAIL path — a cmd_update row's pack_relpath does NOT exist
# on disk (BD-180 E PROMPT-TEMPLATES-style stale mapping).
fail_count, captured = run_reverse(
    [R_FOO, R_STALE],
    docs_pack_files=["FOO.md"],     # STALE.md NOT on disk
    extant_paths=["project-template/docs/pack/FOO.md"],
)
if fail_count != 1:
    failures.append(f"T7 (reverse FAIL stale) expected 1 failure, got {fail_count}: {captured}")
if "STALE.md" not in captured:
    failures.append(f"T7 (reverse FAIL stale) FAIL message must name STALE.md: {captured}")
if "stale" not in captured.lower():
    failures.append(f"T7 (reverse FAIL stale) FAIL message must contain word 'stale': {captured}")

# T8: reverse-PASS-with-exemption — stale row but on reverse exemption allowlist.
fail_count, captured = run_reverse(
    [R_FOO, R_EXTERN],
    docs_pack_files=["FOO.md"],
    extant_paths=["project-template/docs/pack/FOO.md"],
    reverse_exemptions={"extern/IMAGINARY.md": "intentional extern-resolved (test stub)"},
)
if fail_count != 0:
    failures.append(f"T8 (reverse exempt) expected 0 failures, got {fail_count}: {captured}")
if "exempt per _CHECK_39_REVERSE_EXEMPTIONS" not in captured:
    failures.append(f"T8 (reverse exempt) must show reverse exemption notice: {captured}")

# T9: combined forward+reverse failures — one of each.
fail_count, captured = run_reverse(
    [R_FOO, R_STALE],
    docs_pack_files=["FOO.md", "BAZ.md"],  # BAZ.md on disk but has no map row
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
    resolvable install-map row) so any failure counted here is leg 3's."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check39-leg3-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    (root / "project-template" / "docs" / "pack").mkdir(parents=True)
    (root / "project-template" / "docs" / "pack" / "FOO.md").write_text("# stub\n")
    (root / "scripts" / "init-project.sh").write_text(
        "#!/usr/bin/env bash\n"
        "# _CLIENT_INSTALLED_FILES_START\n"
        "#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md"
        "  [stage:S6,cmd_update,migrate]  [class:generic]\n"
        "# _CLIENT_INSTALLED_FILES_END\n")
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
    "init-fragment-pass.sh": "synthetic install map covering every docs/pack file",
    "init-fragment-fail-missing.sh": "synthetic install map missing one file's cmd_update coverage",
    "init-fragment-fail-malformed.sh": "synthetic install map with a broken operand",
}
for name, why in expected_fixtures.items():
    if not (fixtures_dir / name).is_file():
        failures.append(f"missing fixture: {name} ({why})")

import re
BLOCK_RE = re.compile(
    r"_CLIENT_INSTALLED_FILES_START\s*\n(.+?)\n[^\n]*_CLIENT_INSTALLED_FILES_END",
    re.DOTALL,
)


def _rows(path):
    """Rows in a fixture's explicit block that carry a cmd_update tag."""
    m = BLOCK_RE.search(path.read_text())
    if not m:
        return None
    out = []
    for line in m.group(1).splitlines():
        s = line.strip().lstrip("#").strip()
        if "->" in s and "cmd_update" in s:
            out.append(s)
    return out


# The fixtures model the MAP, not the retired array literal. A fixture still
# carrying \`local entries=(\` would be documenting a shape no parser reads.
# (Backticks are escaped: this heredoc is unquoted so \$REPO_ROOT expands,
# which also makes a bare backtick a command substitution.)
for name in ("init-fragment-pass.sh", "init-fragment-fail-missing.sh",
             "init-fragment-fail-malformed.sh"):
    f = fixtures_dir / name
    if f.is_file() and "local entries=(" in f.read_text():
        failures.append(f"{name}: still encodes the retired entries=() array shape")

pass_frag = fixtures_dir / "init-fragment-pass.sh"
if pass_frag.is_file():
    pr = _rows(pass_frag)
    if pr is None:
        failures.append("init-fragment-pass.sh: install-map block not parseable")
    elif len(pr) < 3:
        failures.append(f"init-fragment-pass.sh: expected >=3 cmd_update rows, got {len(pr)}")
    elif not all("[class:" in r for r in pr):
        failures.append("init-fragment-pass.sh: every row must carry a [class:] operand")

# The MISSING fragment must cover strictly fewer files than PASS.
miss_frag = fixtures_dir / "init-fragment-fail-missing.sh"
if miss_frag.is_file() and pass_frag.is_file():
    pr, mr = _rows(pass_frag), _rows(miss_frag)
    if pr is not None and mr is not None and len(mr) >= len(pr):
        failures.append(
            f"init-fragment-fail-missing.sh: expected fewer cmd_update rows than "
            f"the pass fragment ({len(mr)} vs {len(pr)})"
        )

# The MALFORMED fragment must carry a broken operand — otherwise it models
# nothing the parser can degrade on.
mal_frag = fixtures_dir / "init-fragment-fail-malformed.sh"
if mal_frag.is_file():
    mtext = mal_frag.read_text()
    if "[class:]" not in mtext and "[stage:]" not in mtext:
        failures.append(
            "init-fragment-fail-malformed.sh: must carry an empty/broken "
            "operand (e.g. \`[class:]\`) to model parser degradation"
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
       && grep -qE "Check 39 — .* file\(s\) forward-checked against the install map" /tmp/vp-check39-e2e.out \
       && grep -qE "[0-9]+ explicit \`cmd_update\` row\(s\) \+ [0-9]+ \`cmd_update\` GLOB row\(s\) reverse-checked" /tmp/vp-check39-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 39 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 39 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check39-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check39-e2e.out)"
fi

# Reverse leg 2 measures GLOB-row backing against git-TRACKED HEAD, falling
# back to a filesystem match only when git is unavailable. In this repo git
# IS available, so the fallback must NOT have fired — otherwise the leg is
# silently accepting gitignored build artifacts as "backed at HEAD".
if [ -f /tmp/vp-check39-e2e.out ]; then
    if grep -q "reverse leg 2 — git unavailable" /tmp/vp-check39-e2e.out; then
        t_fail "reverse leg 2 fell back to a filesystem match in a git work tree" \
            "$(grep 'reverse leg 2' /tmp/vp-check39-e2e.out)"
    else
        t_pass "reverse leg 2 measured GLOB-row backing against git-tracked HEAD"
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
