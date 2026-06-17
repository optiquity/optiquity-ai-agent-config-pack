#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-41.sh — synthetic fixture tests
# for BD-180 observation G Check 41 (`_CLIENT_INSTALLED_FILES` self-doc
# list integrity, per ARCHITECTURE-BD-176.md §5.3).
#
# Mirrors the test-validate-pack-check-39.sh harness pattern: each test
# stages a synthetic init-project.sh with a controlled inventory block,
# invokes Check 41 against the tmp tree, and asserts PASS / FAIL as
# expected.
#
# Usage: bash scripts/tests/test-validate-pack-check-41.sh

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
# Group 0: Module import + Check 41 symbol registration
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 0: Module import + Check 41 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_client_installed_files',
    '_parse_client_installed_files',
    '_CHECK_41_EXEMPTIONS',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check41-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check41-import.out; then
    t_pass "validate-pack.py imports + Check 41 symbols registered"
else
    t_fail "validate-pack.py import or Check 41 symbol registration failed" \
        "$(cat /tmp/vp-check41-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: _parse_client_installed_files against real init-project.sh
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: _parse_client_installed_files unit tests ===\n"

# Use a quoted heredoc (`<<'EOF'`) so bash performs ZERO substitution on
# the Python body — matches the Group 2 pattern for consistency and
# defends against a future Group 1 assertion containing backticks
# triggering bash command substitution. Inject REPO_ROOT and VALIDATE
# paths via environment variables that Python reads with os.environ.
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

entries, start_count, end_count, regex_matched, body_has_content = mod._parse_client_installed_files()

if start_count != 1:
    failures.append(f"real init-project.sh _CLIENT_INSTALLED_FILES_START count = {start_count} (expected exactly 1)")
if end_count != 1:
    failures.append(f"real init-project.sh _CLIENT_INSTALLED_FILES_END count = {end_count} (expected exactly 1)")
if not regex_matched:
    failures.append("real init-project.sh body-extraction regex did not match (expected well-formed inventory block)")
if not body_has_content:
    failures.append("real init-project.sh body has no content lines (expected real inventory entries between markers)")

# Sanity: real inventory should have >=20 entries today (38 at HEAD per BD-180).
if len(entries) < 20:
    failures.append(f"real inventory has only {len(entries)} entries (expected >=20)")

# Spot-check a few canonical paths are present.
required_subset = {
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    "project-template/docs/pack/PM-CHAT.md",
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    # BD-221: the Antigravity workspace MCP config example is the canonical
    # spot-check row (pm-startup is now a pool skill distributed LOOSE by
    # stage S4, not a per-CLI install-map row).
    "project-template/.agents/mcp_config.json.example",
}
missing = required_subset - set(entries)
if missing:
    failures.append(f"required subset missing from real inventory: {sorted(missing)}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_parse_client_installed_files parses real init-project.sh correctly" ;;
    *) t_fail "_parse_client_installed_files parse tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: Synthetic init-project.sh PASS/FAIL tests
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: Synthetic init-project.sh PASS/FAIL tests ===\n"

# Use a quoted heredoc (`<<'EOF'`) so bash performs ZERO substitution
# on the Python body — backticks inside assertion strings (e.g.,
# `_CLIENT_INSTALLED_FILES_START`) would otherwise trigger command
# substitution. Inject REPO_ROOT and VALIDATE paths via environment
# variables that Python reads with os.environ.
REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'
import os, sys, tempfile, pathlib
REPO_ROOT_PY = os.environ['REPO_ROOT']
VALIDATE_PY = os.environ['VALIDATE']
sys.path.insert(0, REPO_ROOT_PY + '/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', VALIDATE_PY)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Helper: build a synthetic REPO_ROOT with custom scripts/init-project.sh
# containing both a cmd_update entries=() array AND a
# _CLIENT_INSTALLED_FILES_START/_END block. Stage arbitrary extant paths
# under the synthetic root.
#
# `raw_init_sh`: when non-None, overrides the canonical scaffold entirely
# and writes the provided text verbatim to scripts/init-project.sh.
# Used for marker-uniqueness and regex-shape-mismatch tests (T8-T13)
# where the standard scaffold's exactly-one-START/exactly-one-END
# assumption is precisely what's under test.
def run_check(cmd_update_body: str, inventory_lines: list,
              extant_paths: list,
              include_markers: tuple = (True, True),
              exemptions: dict = None,
              raw_init_sh: str = None) -> tuple:
    """Return (failures_count, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check41-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    for ep in extant_paths:
        target = root / ep
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# stub\n")
    if raw_init_sh is not None:
        init_sh_content = raw_init_sh
    else:
        start_marker = "# _CLIENT_INSTALLED_FILES_START" if include_markers[0] else "# (start marker omitted)"
        end_marker = "# _CLIENT_INSTALLED_FILES_END" if include_markers[1] else "# (end marker omitted)"
        inventory_body = "\n".join(inventory_lines)
        init_sh_content = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
%s
    )
    echo "stub"
}

# Self-documenting inventory:
%s
%s
%s
''' % (cmd_update_body, start_marker, inventory_body, end_marker)
    (root / "scripts" / "init-project.sh").write_text(init_sh_content)

    import io, contextlib
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    saved_ex = dict(mod._CHECK_41_EXEMPTIONS)
    mod.failures.clear()
    mod.REPO_ROOT = root
    if exemptions is not None:
        mod._CHECK_41_EXEMPTIONS.clear()
        mod._CHECK_41_EXEMPTIONS.update(exemptions)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_client_installed_files()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        mod._CHECK_41_EXEMPTIONS.clear()
        mod._CHECK_41_EXEMPTIONS.update(saved_ex)
    return (len(new_failures), captured)

# T1: PASS path — inventory matches cmd_update; all sources exist.
cmd_update_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/AGENTS.md:AGENTS.md:trinity"'''
inventory_lines = [
    "#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]",
    "#   project-template/AGENTS.md  ->  AGENTS.md  [stage:S7,cmd_update]",
]
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=[
        "project-template/docs/pack/FOO.md",
        "project-template/AGENTS.md",
    ],
)
if fail_count != 0:
    failures.append(f"T1 (PASS) expected 0 failures, got {fail_count}: {captured}")
if "consistent with copy-site state" not in captured:
    failures.append(f"T1 (PASS) missing PASS-message: {captured}")

# T2: FAIL path — inventory entry's source does not exist on disk.
cmd_update_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
inventory_lines = [
    "#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]",
    "#   project-template/docs/pack/STALE.md  ->  docs/pack/STALE.md  [stage:S6,cmd_update]",
]
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=["project-template/docs/pack/FOO.md"],  # STALE.md missing
)
if fail_count != 1:
    failures.append(f"T2 (FAIL stale-inventory-entry) expected 1 failure, got {fail_count}: {captured}")
if "STALE.md" not in captured:
    failures.append(f"T2 FAIL message must name STALE.md: {captured}")
if "does not exist at HEAD" not in captured:
    failures.append(f"T2 FAIL message must say 'does not exist at HEAD': {captured}")

# T3: FAIL path — cmd_update entry NOT listed in inventory (drift).
cmd_update_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
        "project-template/docs/pack/EXTRA.md:docs/pack/EXTRA.md:generic"'''
inventory_lines = [
    "#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]",
    # EXTRA.md cmd_update entry present but inventory omits it
]
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=[
        "project-template/docs/pack/FOO.md",
        "project-template/docs/pack/EXTRA.md",
    ],
)
if fail_count != 1:
    failures.append(f"T3 (FAIL inventory-drift) expected 1 failure, got {fail_count}: {captured}")
if "EXTRA.md" not in captured:
    failures.append(f"T3 FAIL message must name EXTRA.md: {captured}")
if "NOT listed in the" not in captured:
    failures.append(f"T3 FAIL message must say 'NOT listed in the ...': {captured}")

# T4: PASS-with-exemption — inventory entry on _CHECK_41_EXEMPTIONS allowlist.
cmd_update_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
inventory_lines = [
    "#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]",
    "#   extern/IMAGINARY.md  ->  docs/pack/IMAGINARY.md  [stage:extern]",
]
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=["project-template/docs/pack/FOO.md"],
    exemptions={"extern/IMAGINARY.md": "intentional extern-resolved (test stub)"},
)
if fail_count != 0:
    failures.append(f"T4 (exempt) expected 0 failures, got {fail_count}: {captured}")
if "exempt per _CHECK_41_EXEMPTIONS" not in captured:
    failures.append(f"T4 (exempt) must show exemption notice: {captured}")

# T5: FAIL — START marker missing (count 0). BD-180 SHOULD-1: must
# surface the specific "found 0; expected exactly 1" diagnostic.
cmd_update_body = '''        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"'''
inventory_lines = ["#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6]"]
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=["project-template/docs/pack/FOO.md"],
    include_markers=(False, True),
)
if fail_count < 1:
    failures.append(f"T5 (missing START marker) expected >=1 failure, got {fail_count}: {captured}")
if "missing `_CLIENT_INSTALLED_FILES_START` marker" not in captured:
    failures.append(f"T5 must surface 'missing _CLIENT_INSTALLED_FILES_START' diagnostic: {captured}")
if "found 0" not in captured or "expected exactly 1" not in captured:
    failures.append(f"T5 must include 'found 0; expected exactly 1' in diagnostic: {captured}")

# T6: FAIL — END marker missing (count 0). Same SHOULD-1 contract.
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=["project-template/docs/pack/FOO.md"],
    include_markers=(True, False),
)
if fail_count < 1:
    failures.append(f"T6 (missing END marker) expected >=1 failure, got {fail_count}: {captured}")
if "missing `_CLIENT_INSTALLED_FILES_END` marker" not in captured:
    failures.append(f"T6 must surface 'missing _CLIENT_INSTALLED_FILES_END' diagnostic: {captured}")
if "found 0" not in captured or "expected exactly 1" not in captured:
    failures.append(f"T6 must include 'found 0; expected exactly 1' in diagnostic: {captured}")

# T7: FAIL — markers present, body captured by regex, body is
# whitespace-only (a single line with only spaces between markers).
# BD-180 SHOULD-2: must surface the legacy "no parseable entries"
# diagnostic (preserved pre-BD-180 message for the
# regex-matched-AND-body-whitespace-only case — the inventory is
# genuinely empty from the consumer's view). The body MUST be a
# single space line (not a fully empty line) so that the `.+?` capture
# matches the single space char; otherwise the regex fails entirely
# (covered by T7b).
raw_whitespace_only = (
    "#!/usr/bin/env bash\n"
    "cmd_update() {\n"
    '    local entries=(\n'
    '        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"\n'
    "    )\n"
    "    echo \"stub\"\n"
    "}\n"
    "\n"
    "# _CLIENT_INSTALLED_FILES_START\n"
    "   \n"  # body = three whitespace chars (no comment, no `->`)
    "# _CLIENT_INSTALLED_FILES_END\n"
)
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_whitespace_only,
)
if fail_count < 1:
    failures.append(f"T7 (whitespace-only body) expected >=1 failure, got {fail_count}: {captured}")
if "no parseable entries" not in captured:
    failures.append(f"T7 must preserve legacy 'no parseable entries' diagnostic for whitespace-only-body case: {captured}")
if "block body could not be captured" in captured:
    failures.append(f"T7 (whitespace-only body) must NOT trip the body-capture regex-shape-mismatch diagnostic: {captured}")
if "could not be parsed into inventory entries" in captured:
    failures.append(f"T7 (whitespace-only body) must NOT trip the entry-shape regex-shape-mismatch diagnostic: {captured}")

# T7b: FAIL — markers present but body is truly empty (no character
# between adjacent marker lines at all). With the canonical
# `START\s*\n(.+?)\n[^\n]*END` regex, a zero-length body cannot be
# captured (the `.+?` requires at least one char), so this case
# naturally trips the body-capture regex-shape-mismatch branch with
# the "no body between adjacent marker lines" likely-cause hint.
# Per FIX-3 Option C, empty inventory is not a supported state in
# Check 41 at HEAD; this test asserts the case-(i) body-capture
# diagnostic surfaces (rather than silently passing) for the truly-
# empty shape.
raw_truly_empty = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# Self-documenting inventory:
# _CLIENT_INSTALLED_FILES_START

# _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_truly_empty,
)
if fail_count < 1:
    failures.append(f"T7b (truly empty body between markers) expected >=1 failure, got {fail_count}: {captured}")
if "block body could not be captured" not in captured:
    failures.append(f"T7b must surface body-capture regex-non-match diagnostic (truly empty body cannot be captured by `.+?`): {captured}")
if "no body between adjacent marker lines" not in captured:
    failures.append(f"T7b must mention 'no body between adjacent marker lines' as a likely cause: {captured}")

# T8: FAIL — duplicate START marker (count 2). BD-180 SHOULD-1: must
# surface the "duplicate ... found 2; expected exactly 1" diagnostic.
raw_dup_start = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# First (intended) marker block:
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_END

# Accidental copy-paste duplicate START (e.g., during refactor):
# _CLIENT_INSTALLED_FILES_START
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_dup_start,
)
if fail_count < 1:
    failures.append(f"T8 (duplicate START marker) expected >=1 failure, got {fail_count}: {captured}")
if "duplicate `_CLIENT_INSTALLED_FILES_START` marker" not in captured:
    failures.append(f"T8 must surface 'duplicate _CLIENT_INSTALLED_FILES_START' diagnostic: {captured}")
if "found 2" not in captured or "expected exactly 1" not in captured:
    failures.append(f"T8 must include 'found 2; expected exactly 1' in diagnostic: {captured}")

# T9: FAIL — duplicate END marker (count 2). Same SHOULD-1 contract.
raw_dup_end = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# Intended marker block:
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_END

# Accidental copy-paste duplicate END:
# _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_dup_end,
)
if fail_count < 1:
    failures.append(f"T9 (duplicate END marker) expected >=1 failure, got {fail_count}: {captured}")
if "duplicate `_CLIENT_INSTALLED_FILES_END` marker" not in captured:
    failures.append(f"T9 must surface 'duplicate _CLIENT_INSTALLED_FILES_END' diagnostic: {captured}")
if "found 2" not in captured or "expected exactly 1" not in captured:
    failures.append(f"T9 must include 'found 2; expected exactly 1' in diagnostic: {captured}")

# T10: FAIL — both START and END duplicated (count 2 each). Must
# surface BOTH diagnostics.
raw_dup_both = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_END

# _CLIENT_INSTALLED_FILES_START
# _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_dup_both,
)
if fail_count < 1:
    failures.append(f"T10 (both markers duplicated) expected >=1 failure, got {fail_count}: {captured}")
if "duplicate `_CLIENT_INSTALLED_FILES_START` marker" not in captured:
    failures.append(f"T10 must surface duplicate-START diagnostic: {captured}")
if "duplicate `_CLIENT_INSTALLED_FILES_END` marker" not in captured:
    failures.append(f"T10 must surface duplicate-END diagnostic: {captured}")

# T11: FAIL — markers exist exactly once, block content present but
# non-parseable (regex-shape-mismatch: garbage lines that don't match
# the `#   <pack>  ->  <proj>` entry shape). BD-180 SHOULD-2: must
# surface the "block body could not be parsed into inventory entries"
# diagnostic, NOT the legacy "no parseable entries" diagnostic.
raw_garbage = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# _CLIENT_INSTALLED_FILES_START
echo "this is shell, not a comment"
some other content here
# but this comment has no arrow separator
# _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_garbage,
)
if fail_count < 1:
    failures.append(f"T11 (regex-shape-mismatch: garbage between markers) expected >=1 failure, got {fail_count}: {captured}")
if "block body could not be parsed into inventory entries" not in captured:
    failures.append(f"T11 must surface 'block body could not be parsed into inventory entries' diagnostic: {captured}")
if "block contains no parseable entries" in captured:
    failures.append(f"T11 (regex-shape-mismatch) must NOT trip the legacy 'no parseable entries' diagnostic: {captured}")

# T12: FAIL — markers on the SAME line (regex non-match for body
# capture). BD-180 SHOULD-2: must surface the
# "block body could not be captured ... regex ... did not match"
# diagnostic with the START-precedes-END / same-line / whitespace
# guidance, NOT the legacy diagnostic.
raw_same_line = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# _CLIENT_INSTALLED_FILES_START _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_same_line,
)
if fail_count < 1:
    failures.append(f"T12 (markers on same line) expected >=1 failure, got {fail_count}: {captured}")
if "block body could not be captured" not in captured:
    failures.append(f"T12 must surface regex-non-match diagnostic ('block body could not be captured'): {captured}")
if "START and END markers on the same line" not in captured:
    failures.append(f"T12 must mention 'START and END markers on the same line' as a likely cause: {captured}")
if "block contains no parseable entries" in captured:
    failures.append(f"T12 (regex-shape-mismatch) must NOT trip the legacy 'no parseable entries' diagnostic: {captured}")

# T13: FAIL — END marker appears textually BEFORE START marker (regex
# non-match for body capture; markers exist exactly once each). BD-180
# SHOULD-2: same regex-non-match diagnostic with the END-before-START
# cause surfaced.
raw_out_of_order = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# _CLIENT_INSTALLED_FILES_END
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_START
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_out_of_order,
)
if fail_count < 1:
    failures.append(f"T13 (END before START) expected >=1 failure, got {fail_count}: {captured}")
if "block body could not be captured" not in captured:
    failures.append(f"T13 must surface regex-non-match diagnostic ('block body could not be captured'): {captured}")
if "END marker appears textually before the START marker" not in captured:
    failures.append(f"T13 must mention 'END marker appears textually before the START marker' as a likely cause: {captured}")
if "block contains no parseable entries" in captured:
    failures.append(f"T13 (regex-shape-mismatch) must NOT trip the legacy 'no parseable entries' diagnostic: {captured}")

# T14: FAIL — placeholder `# (no entries)` between markers lands in
# case (ii), not case (iii). BD-180 FIX-2 §4.1 SHOULD: regression guard
# documenting that the historically-recommended `# (no entries)`
# placeholder (FIX-1 case-(i) wording, now removed) does NOT trip case
# (iii) "no parseable entries" — it has body content (the comment line
# is non-whitespace), so the parser sets `body_has_content=True`, the
# entry-loop produces `entries=[]` (no `->` separator), and the caller
# lands in case (ii) "block body could not be parsed into inventory
# entries". Documents the empirical behavior that motivated the FIX-2
# wording change AND defends against a future change attempting to
# special-case the placeholder (would need an explicit parser branch
# producing `body_has_content=False`, which this test would force the
# author to also test).
raw_placeholder_loop = '''#!/usr/bin/env bash
cmd_update() {
    local entries=(
        "project-template/docs/pack/FOO.md:docs/pack/FOO.md:generic"
    )
    echo "stub"
}

# _CLIENT_INSTALLED_FILES_START
# (no entries)
# _CLIENT_INSTALLED_FILES_END
'''
fail_count, captured = run_check(
    "",
    [],
    extant_paths=["project-template/docs/pack/FOO.md"],
    raw_init_sh=raw_placeholder_loop,
)
if fail_count < 1:
    failures.append(f"T14 (`# (no entries)` placeholder) expected >=1 failure, got {fail_count}: {captured}")
if "block body could not be parsed into inventory entries" not in captured:
    failures.append(f"T14 must land in case (ii) (entry-shape diagnostic), confirming placeholder advice would have produced a wording loop: {captured}")
if "block contains no parseable entries" in captured:
    failures.append(f"T14 (regex-matched + body-has-content) must NOT trip the legacy 'no parseable entries' diagnostic: {captured}")
if "block body could not be captured" in captured:
    failures.append(f"T14 (regex-matched) must NOT trip the body-capture regex-non-match diagnostic: {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T14 including T7/T7b SHOULD-2 disambiguation, T8-T10 SHOULD-1 duplicate-marker, and T14 FIX-2 placeholder-loop regression guard)" ;;
    *) t_fail "Synthetic Check 41 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 41 > /tmp/vp-check41-e2e.out 2>&1; then
    if grep -q "Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity" /tmp/vp-check41-e2e.out \
       && grep -qE "Check 41 — [0-9]+ \`_CLIENT_INSTALLED_FILES\` entry" /tmp/vp-check41-e2e.out \
       && grep -q "Self-documenting list is consistent" /tmp/vp-check41-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 41 runs and reports clean"
    else
        t_fail "validate-pack.py exits 0 but Check 41 output not detected" \
            "Tail: $(tail -10 /tmp/vp-check41-e2e.out)"
    fi
else
    t_fail "validate-pack.py exits non-zero on HEAD" \
        "Tail: $(tail -40 /tmp/vp-check41-e2e.out)"
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
