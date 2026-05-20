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

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

entries, start_seen, end_seen = mod._parse_client_installed_files()

if not start_seen:
    failures.append("real init-project.sh missing _CLIENT_INSTALLED_FILES_START marker")
if not end_seen:
    failures.append("real init-project.sh missing _CLIENT_INSTALLED_FILES_END marker")

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
    "project-template/.gemini/commands/pm-startup.toml",
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

python3 <<EOF
import sys, tempfile, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# Helper: build a synthetic REPO_ROOT with custom scripts/init-project.sh
# containing both a cmd_update entries=() array AND a
# _CLIENT_INSTALLED_FILES_START/_END block. Stage arbitrary extant paths
# under the synthetic root.
def run_check(cmd_update_body: str, inventory_lines: list,
              extant_paths: list,
              include_markers: tuple = (True, True),
              exemptions: dict = None) -> tuple:
    """Return (failures_count, captured_output)."""
    tmpdir = tempfile.mkdtemp(prefix="vp-check41-")
    root = pathlib.Path(tmpdir)
    (root / "scripts").mkdir()
    for ep in extant_paths:
        target = root / ep
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("# stub\n")
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

# T5: FAIL — START marker missing.
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

# T6: FAIL — END marker missing.
fail_count, captured = run_check(
    cmd_update_body,
    inventory_lines,
    extant_paths=["project-template/docs/pack/FOO.md"],
    include_markers=(True, False),
)
if fail_count < 1:
    failures.append(f"T6 (missing END marker) expected >=1 failure, got {fail_count}: {captured}")

# T7: FAIL — markers present but block empty.
fail_count, captured = run_check(
    cmd_update_body,
    ["# (no entries here, just a comment)"],
    extant_paths=["project-template/docs/pack/FOO.md"],
)
if fail_count < 1:
    failures.append(f"T7 (empty block) expected >=1 failure, got {fail_count}: {captured}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Synthetic PASS/FAIL tests (T1-T7)" ;;
    *) t_fail "Synthetic Check 41 tests failed (see Python output above)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: End-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check41-e2e.out 2>&1; then
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
