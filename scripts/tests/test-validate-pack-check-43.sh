#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-43.sh — synthetic fixture
# tests for BD-173 H.14 Check 43 (project-side bare cross-reference
# scanner; V11 leak-sweep prevention).
#
# These tests exercise the class-test resolution + allowlist +
# anchor-phrase + code-block-stripping + same-dir + qualified-path
# detection logic without mutating any real project-template/ or
# supporting-docs/ files. Each test stages a synthetic input (custom
# project-side markdown / shell / json file inside a tmp REPO_ROOT),
# invokes Check 43 against the tmp tree, and asserts PASS / FAIL as
# expected.
#
# Coverage:
#   Group 0: Module import + Check 43 symbol registration
#   Group 1: _CHECK_43_ALLOWLIST sanity (non-empty + rationale-keyed)
#   Group 2: _iter_client_installed_files() base-set verification
#   Group 3: Anchor-phrase aliasing (smoke test; Check 40 covers full)
#   Group 4: End-to-end synthetic-tree check (T1-T9 per §1.10)
#   Group 5: Static fixture file sanity (under scripts/tests/fixtures/project-side-refs/)
#   Group 6: End-to-end validate-pack.py exit-status on HEAD
#   Group 7: JC-2 broadening (BD-195 C2 §2.2 Step-5)
#   Group 8: BD-195 C3d — sanctioned pack-side-shipped freeze (Check 47) +
#            re-contamination regression (membership-gate, not content-skip)
#
# Usage: bash scripts/tests/test-validate-pack-check-43.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"
FIXTURES_DIR="$REPO_ROOT/scripts/tests/fixtures/project-side-refs"

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

printf "\n=== Group 0: Module import + Check 43 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_project_side_bare_internal_refs',
    '_CHECK_43_ALLOWLIST',
    '_CHECK_43_ANCHOR_PHRASES',
    '_CHECK_43_ANCHOR_WINDOW',
    '_CHECK_43_MIRROR_SKIP_BASENAMES',
    '_CHECK_43_PACK_INTERNAL_PREFIXES',
    '_CHECK_43_PACK_OPS_CLIENT_INSTALLED',
    '_check_43_context_has_anchor',
    '_iter_client_installed_files',
    # BD-195 C3d (Check 47 + walk-gate) — folded into this file.
    '_SANCTIONED_PACK_SIDE_SHIPPED',
    'check_sanctioned_pack_side_shipped',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check43-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check43-import.out; then
    t_pass "validate-pack.py imports + Check 43 symbols registered"
else
    t_fail "validate-pack.py import or Check 43 symbol registration failed" \
        "$(cat /tmp/vp-check43-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: _CHECK_43_ALLOWLIST sanity (non-empty + rationale)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 1: _CHECK_43_ALLOWLIST sanity ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: allowlist is non-empty.
if not mod._CHECK_43_ALLOWLIST:
    failures.append("T1 _CHECK_43_ALLOWLIST is empty")

# T2: ~30 entries minimum (per architect §1.4).
if len(mod._CHECK_43_ALLOWLIST) < 25:
    failures.append(
        f"T2 _CHECK_43_ALLOWLIST has only {len(mod._CHECK_43_ALLOWLIST)} entries; "
        f"expected >=25 per architect §1.4"
    )

# T3: every entry has a non-empty rationale string.
for key, val in mod._CHECK_43_ALLOWLIST.items():
    if not isinstance(val, str):
        failures.append(f"T3 {key} rationale is not a string: {val!r}")
    elif not val.strip():
        failures.append(f"T3 {key} rationale is empty")

# T4: load-bearing entries from §1.4 are present.
required_entries = {
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "README.md",
    "PACK-FEEDBACK.md",
    "METHODOLOGY.md",
    "INSTALL-PROCEDURES.md",
    "PM-CHAT.md",
    "PLATFORM-SKILLS.md",
    "BD-NNN.md",
    "TD-NNN.md",
    "phase-N.md",
    "_rules.md",
    "_intro.md",
    "_format.md",
    "BACKLOG.md",
    "CHANGELOG.md",
    "IMPLEMENTATION-PLAN.md",
    "tracker.toml",
    "MEMORY.md",
    "agent-run.sh",
}
missing = required_entries - set(mod._CHECK_43_ALLOWLIST.keys())
if missing:
    failures.append(f"T4 missing required entries from §1.4: {sorted(missing)}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_CHECK_43_ALLOWLIST shape + content sanity" ;;
    *) t_fail "_CHECK_43_ALLOWLIST sanity tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: _iter_client_installed_files() base-set verification
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 2: _iter_client_installed_files() base-set verification ===\n"

python3 <<EOF
import sys, pathlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: returns non-empty list of Path objects.
files = mod._iter_client_installed_files()
if not files:
    failures.append("T1 _iter_client_installed_files() returned empty list")
for f in files[:5]:
    if not isinstance(f, pathlib.Path):
        failures.append(f"T1 _iter_client_installed_files() returned non-Path: {f!r}")

# T2: includes project-template/ files.
strs = [str(f).replace("\\\\", "/") for f in files]
has_pt = any(s.startswith("project-template/") for s in strs)
if not has_pt:
    failures.append("T2 _iter_client_installed_files() missing project-template/ entries")

# T3: includes the explicit non-project-template entries (per
#     _CLIENT_INSTALLED_FILES inventory). Post-BD-193 F4/F5 + BD-194:
#     pack-ops/HELP-FRAGMENT-TRACKER.md is NOT a client-installed file
#     (project-template/docs/pack/HELP-FRAGMENT-TRACKER.md is the
#     install source per BD-193 F4/F5).
expected_extras = [
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    "scripts/pack-help.sh",
    "scripts/lib/detect.sh",
]
for entry in expected_extras:
    if entry not in strs:
        failures.append(
            f"T3 _iter_client_installed_files() missing expected entry: {entry}"
        )

# T4: deduplication — no entry appears twice.
if len(strs) != len(set(strs)):
    dupes = [s for s in strs if strs.count(s) > 1]
    failures.append(f"T4 _iter_client_installed_files() has duplicates: {sorted(set(dupes))[:5]}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_iter_client_installed_files() returns base set per §3.1" ;;
    *) t_fail "_iter_client_installed_files() base-set tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 3: Anchor-phrase exemption (smoke test; aliased from Check 40)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 3: _check_43_context_has_anchor smoke test ===\n"

python3 <<EOF
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# T1: alias identity — anchor phrases must be the SAME set as Check 40.
if mod._CHECK_43_ANCHOR_PHRASES is not mod._CHECK_40_ANCHOR_PHRASES:
    failures.append("T1 _CHECK_43_ANCHOR_PHRASES is not aliased to _CHECK_40_ANCHOR_PHRASES")

# T2: window alias identity.
if mod._CHECK_43_ANCHOR_WINDOW != mod._CHECK_40_ANCHOR_WINDOW:
    failures.append(
        f"T2 _CHECK_43_ANCHOR_WINDOW={mod._CHECK_43_ANCHOR_WINDOW} != "
        f"_CHECK_40_ANCHOR_WINDOW={mod._CHECK_40_ANCHOR_WINDOW}"
    )

# T3: anchor function admits "in the pack repo" on matched line.
lines = ["line 0", "see \`ARCH.md\` in the pack repo", "line 2"]
if not mod._check_43_context_has_anchor(lines, 2):
    failures.append("T3 expected 'in the pack repo' anchor on matched line")

# T4: anchor function admits "post-install" within window.
lines = ["doc lives at post-install path", "the \`X.md\` ref", "context"]
if not mod._check_43_context_has_anchor(lines, 2):
    failures.append("T4 expected 'post-install' anchor 1-before")

# T5: no anchor → not admitted.
lines = ["line 0", "see \`X.md\` for details", "line 2"]
if mod._check_43_context_has_anchor(lines, 2):
    failures.append("T5 expected NO anchor without keyword")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "_check_43_context_has_anchor smoke + aliasing verified" ;;
    *) t_fail "_check_43_context_has_anchor smoke tests failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 4: Synthetic-tree end-to-end (T1-T9 per §1.10)
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 4: End-to-end synthetic-tree tests (T1-T9 per §1.10) ===\n"

python3 <<EOF
import sys, tempfile, os, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_with_synthetic(project_files: dict, extra_files: dict = None,
                              installed_inventory_extras: list = None) -> tuple:
    """Run check_project_side_bare_internal_refs against a synthetic tree.

    project_files: { 'CLAUDE.md': 'content', ... } — files under project-template/
    extra_files: { 'maintenance-docs/.../ARCHITECTURE-FOO.md': 'stub', ... } — non-project-template files
                 to populate the basename index for candidate-path lookup.
    installed_inventory_extras: optional list of inventory entries to seed
                 into a synthetic init-project.sh _CLIENT_INSTALLED_FILES block.

    Returns (failures_count, pass_msg_present, captured_output).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check43-")
    root = pathlib.Path(tmpdir)
    (root / "project-template").mkdir()
    for name, content in project_files.items():
        target = root / "project-template" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
    if extra_files:
        for rel, content in extra_files.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)

    # Create a minimal scripts/init-project.sh with the
    # _CLIENT_INSTALLED_FILES inventory markers so the parser
    # finds at least one entry. Format per _parse_client_installed_files:
    # `#   <pack_relpath>  ->  <project_relpath>  [stage:<id>]`.
    init_path = root / "scripts" / "init-project.sh"
    init_path.parent.mkdir(parents=True, exist_ok=True)
    inventory_lines = [
        "#!/usr/bin/env bash",
        "# _CLIENT_INSTALLED_FILES_START",
        "#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S2]",
        "#   pack-ops/HELP-FRAGMENT-TRACKER.md  ->  docs/pack/HELP-FRAGMENT-TRACKER.md  [stage:S11]",
        "#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6]",
        "#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6]",
        "#   scripts/pack-help.sh  ->  scripts/pack-help.sh  [stage:S5]",
        "#   scripts/lib/detect.sh  ->  scripts/lib/detect.sh  [stage:S5]",
    ]
    if installed_inventory_extras:
        for entry in installed_inventory_extras:
            inventory_lines.append(f"#   {entry}  ->  {entry}  [stage:S1]")
    inventory_lines.append("# _CLIENT_INSTALLED_FILES_END")
    init_path.write_text("\n".join(inventory_lines) + "\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_side_bare_internal_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    pass_msg = "zero pack-internal bare cross-references" in captured
    return (len(new_failures), pass_msg, captured)

# T1: FAIL (pre-install-only supporting-docs/MIGRATION-v10-to-v11.md
#     when the file exists but is NOT in the client-install set).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "See \`MIGRATION-v10-to-v11.md\` for the upgrade.\n"},
    {"supporting-docs/MIGRATION-v10-to-v11.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T1 (pre-install MIGRATION-v10-to-v11 FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T2: PASS path — PACK-FEEDBACK.md bare ref + file resolves to
#     project-template/docs/pack/PACK-FEEDBACK.md.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "See \`PACK-FEEDBACK.md\` for feedback flow.\n",
     "docs/pack/PACK-FEEDBACK.md": "stub"},
)
if fail_count != 0:
    failures.append(f"T2 (PACK-FEEDBACK PASS) expected 0 failures, got {fail_count}: {captured}")

# T3: FAIL pack-internal target — bare ARCHITECTURE-V3.md resolves to
#     maintenance-docs/v11-research/ARCHITECTURE-V3.md.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "Per \`ARCHITECTURE-V3.md\` §28 the design has five stages.\n"},
    {"maintenance-docs/v11-research/ARCHITECTURE-V3.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T3 (ARCHITECTURE-V3.md pack-internal FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T4: FAIL pack-internal target — bare AUDIT-USER-CURATION.md resolves
#     to maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md
#     (BD-175 self-leak class).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "Per \`AUDIT-USER-CURATION.md\` Override 1 the file STAYS at pack root.\n"},
    {"maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T4 (AUDIT-USER-CURATION BD-175 self-leak FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T5: FAIL pack-internal qualified — pack-ops/MERGE-STRATEGY.md
#     qualified ref (pack-only path-prefix).
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "Per \`pack-ops/MERGE-STRATEGY.md\` the merge handles drift.\n"},
    {"pack-ops/MERGE-STRATEGY.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T5 (pack-ops/ qualified FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T6: PASS path — bare ref + anchor "in the pack repo" within ±2 lines.
content = (
    "# Test fixture\n"
    "In the pack repo, the architect doc lives at\n"
    "\`ARCHITECTURE-V3.md\` per the §28 design.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": content},
    {"maintenance-docs/v11-research/ARCHITECTURE-V3.md": "stub"},
)
if fail_count != 0:
    failures.append(
        f"T6 (anchor PASS) expected 0 failures, got {fail_count}: {captured}"
    )

# T7: PASS path — bare ref inside fenced code block.
content = (
    "# Test fixture\n"
    "Example invocation:\n"
    "\n"
    "\`\`\`bash\n"
    "python3 scripts/validate-pack.py\n"
    "cat maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md\n"
    "echo \`ARCHITECTURE-V3.md\` content\n"
    "\`\`\`\n"
    "\n"
    "Done.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": content},
    {"maintenance-docs/v11-research/ARCHITECTURE-V3.md": "stub"},
)
if fail_count != 0:
    failures.append(
        f"T7 (code-block PASS) expected 0 failures, got {fail_count}: {captured}"
    )

# T8: scripts/lib/detect.sh synthetic file with maintenance-docs/
#     qualified path-prefix in a shell comment.
#     This exercises the .sh-file scope (Check 43 walks
#     scripts/lib/detect.sh per _iter_client_installed_files).
detect_content = (
    "#!/usr/bin/env bash\n"
    "# Synthetic detect.sh; references pack-internal target:\n"
    "# maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md\n"
    "echo \"stub\"\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"FOO.md": "no leaks here\n"},
    {"scripts/lib/detect.sh": detect_content,
     "maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T8 (.sh maintenance-docs/ qualified path FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T9: PASS same-dir + allowlist — _intro.md is on the allowlist
#     (per-entry tree sibling).
content = (
    "# Per-stream rules\n"
    "See \`_intro.md\` for the intro template and \`_format.md\` for\n"
    "the per-entry format.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"docs/project/backlog/_rules.md": content,
     "docs/project/backlog/_intro.md": "stub",
     "docs/project/backlog/_format.md": "stub"},
)
if fail_count != 0:
    failures.append(
        f"T9 (_intro.md allowlist PASS) expected 0 failures, got {fail_count}: {captured}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T9 (PASS / FAIL / exemption / code-block)" ;;
    *) t_fail "End-to-end check_project_side_bare_internal_refs tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 5: Static fixture file sanity
# ─────────────────────────────────────────────────────────────────

printf "\n=== Group 5: Static fixture file sanity ===\n"

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
    "project-side-fail-per-entry-skeleton.md": "LEAK CLASS A per-entry skeleton bare ref",
    "project-side-fail-architect-doc-cite.md": "LEAK CLASS A architect doc cite",
    "project-side-fail-detect-sh-comment.sh": "LEAK CLASS D detect.sh comment",
    "project-side-fail-pmstartup-cite.md": "LEAK CLASS E pm-startup cluster",
    "project-side-fail-pmchat-self-prompt.md": "LEAK CLASS C pm-chat self-prompt",
    "project-side-fail-mcp-example.json": "LEAK CLASS C mcp example",
    "project-side-fail-audit-cite-in-skill.md": "LEAK CLASS F BD-175 self-leak",
    "project-side-pass-pack-feedback.md": "cross-boundary product feature",
    "project-side-pass-allowlist-methodology.md": "client-installed supporting-docs/",
    "project-side-pass-anchor-pack-repo.md": "anchor-phrase exemption",
    "project-side-pass-same-dir-skeleton.md": "per-entry skeleton sibling",
    "project-side-pass-code-block.md": "fenced code-block stripping",
}
for name, why in expected_fixtures.items():
    p = fixtures_dir / name
    if not p.is_file():
        failures.append(f"missing fixture: {name} ({why})")
        continue
    content = p.read_text()
    if not content:
        failures.append(f"empty fixture: {name}")

# Sanity: count = 13.
file_count = sum(1 for p in fixtures_dir.iterdir() if p.is_file())
if file_count != 13:
    failures.append(f"expected 13 fixture files, found {file_count}")

# Sanity: every FAIL fixture contains at least one bare-ref or
# qualified-path token matching Check 43's detection patterns.
fail_fixtures = sorted(p for p in fixtures_dir.glob("project-side-fail-*"))
for fp in fail_fixtures:
    text = fp.read_text()
    bare_matches = mod._CHECK_40_BARE_REF_PATTERN.findall(text)
    has_qualified = ("supporting-docs/" in text
                     or "maintenance-docs/" in text
                     or "pack-ops/" in text)
    if not bare_matches and not has_qualified:
        failures.append(
            f"FAIL fixture {fp.name} contains neither bare-ref tokens "
            f"nor qualified pack-only paths"
        )

# Sanity: PASS fixtures contain at least one bare-ref/qualified token
# that exercises an exemption tier.
pass_fixtures = sorted(p for p in fixtures_dir.glob("project-side-pass-*"))
if len(pass_fixtures) != 5:
    failures.append(
        f"expected 5 PASS fixtures (project-side-pass-*.md), got {len(pass_fixtures)}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "Static fixture files present (13 total) + parseable + regex-shaped" ;;
    *) t_fail "Static fixture sanity failed" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 6: End-to-end validate-pack.py — Check 43 RAN (PG-2-aware)
# ─────────────────────────────────────────────────────────────────
#
# BD-195 C2 (PG-2 / JC-2 broadening) note: with the broadened guard,
# `validate-pack.py` is RED-BY-DESIGN at HEAD until the C3/C4/C9
# client-surface STRIP fixes land in the same push group (PLAN-BD-195-
# REMEDIATION.md §3.2). A non-zero exit therefore does NOT indicate a
# Check 43 regression during the PG-2 window. This Group asserts only
# that Check 43 RAN (header + walk-report present); the synthetic
# Group 4 / Group 7 cases carry the PASS/FAIL behavior assertions that
# must hold standalone. The full-repo green state is asserted at the END
# of PG-2 (after the last STRIP fix), not by this per-check test.

printf "\n=== Group 6: End-to-end validate-pack.py — Check 43 ran ===\n"

python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check43-e2e.out 2>&1 || true
if grep -q "Check 43: Project-side bare cross-reference scanner" /tmp/vp-check43-e2e.out; then
    t_pass "validate-pack.py runs; Check 43 executes (PG-2 red-by-design tolerated)"
else
    t_fail "Check 43 did not run under validate-pack.py" \
        "Tail: $(tail -40 /tmp/vp-check43-e2e.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 7: JC-2 broadening (BD-195 C2 §2.2 Step-5) — synthetic cases
# ─────────────────────────────────────────────────────────────────
#
# Five cases per the PLAN §2.2 Step-5 verification contract:
#   (a) a `.example` file carrying a pack-only basename FAILs;
#   (b) durable proto-validity rule (resolve-within-tree) — BOTH
#       directions: in-tree proto basename VALID; external/pack-doc NOT;
#   (c) a commit-SHA provenance FAILs;
#   (d) a `supporting-docs/<installed-basename>` cite on a client
#       surface FAILs (prefix-tightening rule);
#   (e) a per-line-fenced supporting-docs SOURCE file does NOT trip the
#       prefix rule — assert fence-set vs client-surface-prefix-hit-set
#       DISJOINTNESS.

printf "\n=== Group 7: JC-2 broadening (C2 §2.2 Step-5) ===\n"

python3 <<EOF
import sys, tempfile, os, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def run_check_with_synthetic(project_files: dict, extra_files: dict = None,
                             installed_inventory_extras: list = None,
                             fence_files: list = None) -> tuple:
    """Run check_project_side_bare_internal_refs against a synthetic tree.

    project_files: { relpath-under-project-template/: content }
    extra_files:   { repo-relpath: content } (populates basename index +
                   pack-only trees, e.g. maintenance-docs/.. / pack-ops/..)
    installed_inventory_extras: extra _CLIENT_INSTALLED_FILES entries
    fence_files:   list of repo-relpaths to register on the per-line-fence
                   allowlist for this run (Group 7 case e).
    """
    tmpdir = tempfile.mkdtemp(prefix="vp-check43-g7-")
    root = pathlib.Path(tmpdir)
    (root / "project-template").mkdir()
    for name, content in project_files.items():
        target = root / "project-template" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
    if extra_files:
        for rel, content in extra_files.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)
    init_path = root / "scripts" / "init-project.sh"
    init_path.parent.mkdir(parents=True, exist_ok=True)
    inventory_lines = [
        "#!/usr/bin/env bash",
        "# _CLIENT_INSTALLED_FILES_START",
        "#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S2]",
        "#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6]",
        "#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6]",
    ]
    if installed_inventory_extras:
        for entry in installed_inventory_extras:
            inventory_lines.append(f"#   {entry}  ->  {entry}  [stage:S1]")
    inventory_lines.append("# _CLIENT_INSTALLED_FILES_END")
    init_path.write_text("\n".join(inventory_lines) + "\n")

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    saved_fence = mod._CHECK_37_PER_LINE_FENCE_FILES
    mod.failures.clear()
    mod.REPO_ROOT = root
    if fence_files is not None:
        mod._CHECK_37_PER_LINE_FENCE_FILES = tuple(fence_files)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_side_bare_internal_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod._CHECK_37_PER_LINE_FENCE_FILES = saved_fence
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return (len(new_failures), captured)

# (a) A .example file carrying a pack-only basename FAILs. The pack-only
#     basename must resolve EXCLUSIVELY into a pack-only tree; seed one in
#     maintenance-docs/ so the bare-prose axis catches it. The .example
#     file must be walked (axis iii ext broadening).
fail_count, captured = run_check_with_synthetic(
    {".codex/config.toml.example":
     "# Source: V11-FOO-RESEARCH.md for the MCP config rationale.\n"},
    {"maintenance-docs/V11-FOO-RESEARCH.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"(a) .example pack-only basename expected FAIL, got {fail_count}: {captured}"
    )

# (b) Durable proto-validity rule (BD-195 C2 §2.2 Step-4) — BOTH directions
#     of the resolve-within-tree predicate. The rule REPLACES the prior two
#     hardcoded proto allowlist basenames with a resolve-within-tree
#     predicate. We exercise the predicate directly because proto is NOT in
#     the bare-ref ext set, so the bare-ref/hyperlink matchers never produce
#     a proto basename — the rule is defensive and must be tested at the
#     predicate level. Build a synthetic proto tree and point REPO_ROOT at it.
proto_root_tmp = tempfile.mkdtemp(prefix="vp-check43-proto-")
proto_root_path = pathlib.Path(proto_root_tmp)
(proto_root_path / "project-template" / "proto" / "common" / "v1").mkdir(parents=True)
(proto_root_path / "project-template" / "proto" / "common" / "v1" / "common.proto").write_text(
    'syntax = "proto3";\n'
)
(proto_root_path / "project-template" / "proto" / "example" / "v1").mkdir(parents=True)
(proto_root_path / "project-template" / "proto" / "example" / "v1"
 / "example_service.proto").write_text('syntax = "proto3";\nimport "common/v1/common.proto";\n')
_saved_root = mod.REPO_ROOT
mod.REPO_ROOT = proto_root_path
try:
    # Direction (i): a proto basename that RESOLVES within the proto tree
    # is treated as VALID (admitted).
    if not mod._check_43_proto_resolves_in_tree("common.proto"):
        failures.append("(b-i) in-tree proto 'common.proto' expected VALID, got not-admitted")
    if not mod._check_43_proto_resolves_in_tree("example_service.proto"):
        failures.append(
            "(b-i) in-tree proto 'example_service.proto' expected VALID, got not-admitted"
        )
    # Direction (ii): the proto rule must NOT admit a non-resolving/external
    # proto basename, NOR a pack-doc basename (bound: resolve-within-tree ONLY).
    if mod._check_43_proto_resolves_in_tree("descriptor.proto"):
        failures.append(
            "(b-ii) external/non-resolving proto 'descriptor.proto' must NOT be admitted"
        )
    if mod._check_43_proto_resolves_in_tree("MERGE-STRATEGY.md"):
        failures.append("(b-ii) pack-doc basename 'MERGE-STRATEGY.md' must NOT be admitted")
finally:
    mod.REPO_ROOT = _saved_root
    shutil.rmtree(proto_root_tmp, ignore_errors=True)

# (c) A commit-SHA provenance FAILs.
fail_count, captured = run_check_with_synthetic(
    {"FOO.md": "Source of this block: commit 73d480e (research note).\n"},
)
if fail_count < 1:
    failures.append(
        f"(c) commit-SHA provenance expected FAIL, got {fail_count}: {captured}"
    )

# (d) A supporting-docs/<installed-basename> cite on a client surface
#     FAILs (prefix-tightening — METHODOLOGY.md IS installed but the
#     supporting-docs/ dir is absent at a client).
fail_count, captured = run_check_with_synthetic(
    {"FOO.md": "Copy supporting-docs/METHODOLOGY.md into docs/pack/.\n"},
)
if fail_count < 1:
    failures.append(
        f"(d) supporting-docs/<installed> prefix cite expected FAIL, got "
        f"{fail_count}: {captured}"
    )

# (e) A per-line-fenced supporting-docs SOURCE file does NOT trip the
#     prefix rule (disjointness: the fenced lines are skipped). Register
#     the synthetic source file on the fence allowlist and wrap the cite
#     in fence markers; expect 0 failures.
fenced_source = (
    "# METHODOLOGY (source)\n"
    "<!-- DENY-LIST-CONTENT-START -->\n"
    "Pre-install, this doc lives at supporting-docs/METHODOLOGY.md.\n"
    "<!-- DENY-LIST-CONTENT-END -->\n"
)
fail_count, captured = run_check_with_synthetic(
    {"FOO.md": "no leaks here\n"},
    {"supporting-docs/METHODOLOGY.md": fenced_source},
    installed_inventory_extras=["supporting-docs/METHODOLOGY.md"],
    fence_files=["supporting-docs/METHODOLOGY.md"],
)
if fail_count != 0:
    failures.append(
        f"(e) fenced supporting-docs SOURCE file expected PASS "
        f"(disjoint from prefix-hit set), got {fail_count}: {captured}"
    )

# (e') Disjointness assertion: the fence-set and the client-surface
#      prefix-hit-set are disjoint by construction — a fenced line is
#      skipped BEFORE the prefix scan runs (lineno in fence_skip ->
#      continue). Assert the un-fenced variant of the SAME content DOES
#      fail, proving the only difference is the fence.
unfenced_source = (
    "# METHODOLOGY (source)\n"
    "Pre-install, this doc lives at supporting-docs/METHODOLOGY.md.\n"
)
fail_count_unfenced, captured_u = run_check_with_synthetic(
    {"FOO.md": "no leaks here\n"},
    {"supporting-docs/METHODOLOGY.md": unfenced_source},
    installed_inventory_extras=["supporting-docs/METHODOLOGY.md"],
    fence_files=[],  # NOT fenced this time
)
if fail_count_unfenced < 1:
    failures.append(
        f"(e') un-fenced supporting-docs cite expected FAIL (proving the "
        f"fence — not the file — is what exempts case e), got "
        f"{fail_count_unfenced}: {captured_u}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "JC-2 broadening Step-5 cases (a-e + disjointness e')" ;;
    *) t_fail "JC-2 broadening Step-5 cases failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 8: BD-195 C3d — sanctioned pack-side-shipped freeze (Check 47)
#          + the re-contamination regression (membership-gate, not skip)
# ─────────────────────────────────────────────────────────────────
#
# Cases per PLAN-BD-195-REMEDIATION.md §C3d (architect §8.1/§8.2):
#   (0)   detect.sh is EXPLICITLY in _iter_client_installed_files()'s walk-set
#         (direct membership-admit proof — refactor-robust, independent of
#         Check 43's content logic);
#   (i)   a CLEAN synthetic detect.sh PASSES Check 43 (it is walked);
#   (ii)  a synthetic detect.sh with an INJECTED pack-internal ref still
#         FAILS Check 43 — the load-bearing re-contamination regression
#         proving the walk-gate is MEMBERSHIP-only, not a content silencer;
#   (iii) a non-template map entry NOT in _SANCTIONED_PACK_SIDE_SHIPPED
#         FAILS Check 47 (lazy-add blocked);
#   (iv)  a constant entry NOT in the map FAILS Check 47 (set-equality,
#         both directions).

printf "\n=== Group 8: BD-195 C3d sanctioned-set freeze + re-contamination regression ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

def build_tree(detect_content: str, extra_map_entries: list = None,
               omit_detect_from_map: bool = False) -> pathlib.Path:
    """Build a synthetic REPO_ROOT with the two sanctioned files present
    and a controllable _CLIENT_INSTALLED_FILES inventory."""
    root = pathlib.Path(tempfile.mkdtemp(prefix="vp-check47-"))
    (root / "project-template").mkdir()
    (root / "project-template" / "CLAUDE.md").write_text("clean\n")
    # The two sanctioned pack-side files on disk.
    (root / "scripts" / "lib").mkdir(parents=True)
    (root / "scripts" / "lib" / "detect.sh").write_text(detect_content)
    (root / "scripts" / "pack-help.sh").write_text("#!/usr/bin/env bash\necho ok\n")
    inv = [
        "#!/usr/bin/env bash",
        "# _CLIENT_INSTALLED_FILES_START",
        "#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S2]",
        "#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6]",
        "#   scripts/pack-help.sh  ->  scripts/pack-help.sh  [stage:S5]",
    ]
    if not omit_detect_from_map:
        inv.append("#   scripts/lib/detect.sh  ->  scripts/lib/detect.sh  [stage:S5]")
    for entry in (extra_map_entries or []):
        # Materialize the file so it is real at HEAD (Check 41-style realism).
        p = root / entry
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("#!/usr/bin/env bash\necho extra\n")
        inv.append(f"#   {entry}  ->  {entry}  [stage:S5]")
    inv.append("# _CLIENT_INSTALLED_FILES_END")
    ip = root / "scripts" / "init-project.sh"
    ip.parent.mkdir(parents=True, exist_ok=True)
    ip.write_text("\n".join(inv) + "\n")
    return root

def run(check_fn_name: str, root: pathlib.Path) -> tuple:
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            getattr(mod, check_fn_name)()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(root, ignore_errors=True)
    return (len(new_failures), captured)

CLEAN_DETECT = "#!/usr/bin/env bash\n# detect helpers; no pack-self refs.\necho ok\n"
# A pack-internal qualified path-prefix in a shell comment — the same
# leak shape Check 43's T8 case exercises.
DIRTY_DETECT = (
    "#!/usr/bin/env bash\n"
    "# Re-contamination: maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md\n"
    "echo ok\n"
)

# (0) MEMBERSHIP-ADMIT proof — assert scripts/lib/detect.sh is ACTUALLY in
#     the _iter_client_installed_files() walked set. The (i)/(ii) cases below
#     prove membership only IMPLICITLY (via the clean PASS / injected-ref
#     FAIL); this case asserts the walk-set contains detect.sh DIRECTLY, so
#     the proof survives a refactor that changes Check 43's content logic
#     without touching the membership gate. (architect §8.1 (ii) / PLAN R-9.)
membership_root = build_tree(CLEAN_DETECT)
saved_root_m = mod.REPO_ROOT
mod.REPO_ROOT = membership_root
try:
    walked = {str(p).replace("\\\\", "/") for p in mod._iter_client_installed_files()}
finally:
    mod.REPO_ROOT = saved_root_m
    shutil.rmtree(membership_root, ignore_errors=True)
if "scripts/lib/detect.sh" not in walked:
    failures.append(
        "(0) sanctioned scripts/lib/detect.sh NOT admitted to the "
        "_iter_client_installed_files() walk-set (membership gate must ADMIT "
        "it): " + str(sorted(walked))
    )

# (i) CLEAN sanctioned detect.sh PASSES Check 43 (it is walked).
fc, cap = run("check_project_side_bare_internal_refs", build_tree(CLEAN_DETECT))
if fc != 0:
    failures.append(f"(i) clean sanctioned detect.sh expected PASS, got {fc}: {cap}")

# (ii) INJECTED pack-internal ref into the walked detect.sh still FAILS
#      Check 43 — membership-gate is NOT a content skip.
root_dirty = build_tree(DIRTY_DETECT)
# Seed the resolving pack-internal target so the bare/qualified ref resolves.
tgt = root_dirty / "maintenance-docs" / "v11-implementation" / "ARCHITECTURE-FOO.md"
tgt.parent.mkdir(parents=True, exist_ok=True)
tgt.write_text("stub")
fc, cap = run("check_project_side_bare_internal_refs", root_dirty)
if fc < 1:
    failures.append(
        f"(ii) injected-ref detect.sh expected Check 43 FAIL (membership-gate, "
        f"not content-skip), got {fc}: {cap}"
    )

# (iii) a non-template map entry NOT in the frozen constant FAILS Check 47.
fc, cap = run(
    "check_sanctioned_pack_side_shipped",
    build_tree(CLEAN_DETECT, extra_map_entries=["scripts/lib/rogue.sh"]),
)
if fc < 1:
    failures.append(
        f"(iii) unsanctioned pack-side map entry expected Check 47 FAIL "
        f"(lazy-add blocked), got {fc}: {cap}"
    )
elif "rogue.sh" not in cap or "_SANCTIONED_PACK_SIDE_SHIPPED" not in cap:
    failures.append(
        f"(iii) Check 47 failure message must name the offending path + the "
        f"membership criterion, got: {cap}"
    )

# (iv) a constant entry NOT in the map FAILS Check 47 (set-equality both ways).
fc, cap = run(
    "check_sanctioned_pack_side_shipped",
    build_tree(CLEAN_DETECT, omit_detect_from_map=True),
)
if fc < 1:
    failures.append(
        f"(iv) sanctioned entry absent from the map expected Check 47 FAIL "
        f"(set-equality), got {fc}: {cap}"
    )

# (v) baseline: a well-formed 2-member map PASSES Check 47.
fc, cap = run("check_sanctioned_pack_side_shipped", build_tree(CLEAN_DETECT))
if fc != 0:
    failures.append(f"(v) frozen 2-member map expected Check 47 PASS, got {fc}: {cap}")

# (vi) the frozen constant is EXACTLY the two paths (sized to measured set).
if tuple(mod._SANCTIONED_PACK_SIDE_SHIPPED) != (
    "scripts/lib/detect.sh", "scripts/pack-help.sh"
):
    failures.append(
        f"(vi) _SANCTIONED_PACK_SIDE_SHIPPED must be exactly the 2 measured "
        f"paths, got {mod._SANCTIONED_PACK_SIDE_SHIPPED!r}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "C3d freeze + walk-gate: clean PASSES, injected-ref FAILS C43, lazy-add/missing FAIL C47" ;;
    *) t_fail "BD-195 C3d Check-47 / re-contamination regression failed (see Python output)" ;;
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
