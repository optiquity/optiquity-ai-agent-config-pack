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
#   Group 4: End-to-end synthetic-tree check (T1-T9 per §1.10; T10-T13 =
#            the BD-288 self-tree leg, incl. the anti-vacuity leg T11 that
#            tells a whole-walk leg apart from a citer-scoped one)
#   Group 5: Static fixture file sanity (under scripts/tests/fixtures/project-side-refs/)
#   Group 6: End-to-end validate-pack.py exit-status on HEAD
#   Group 7: JC-2 broadening (BD-195 C2 §2.2 Step-5)
#   Group 8: BD-257 — empty sanctioned set (no-dual-use) + Check 47 EMPTY
#            invariant (supersedes the BD-195 2-member freeze)
#   Group 9: BD-288 — the self-tree carve-out is load-bearing on the REAL
#            tree (mutation: remove it and the 5 banners FAIL) + the
#            post-STRIP residue is 0
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
    '_CHECK_43_PACK_INTERNAL_PREFIXES',
    '_CHECK_43_PACK_OPS_CLIENT_INSTALLED',
    '_check_43_context_has_anchor',
    '_iter_client_installed_files',
    # Check 47 sanctioned-set freeze + walk-gate — folded into this file.
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
    # BD-206: `_format.md` is FORBIDDEN (removed from the allowlist); the
    # generated `_index.md` ordering sidecar is admitted in its place.
    "_index.md",
    # The 3 project monolith basenames stay allowlisted at A1: they are
    # the v10→v11 conversion-INPUT and the bare-ref subject of
    # Wave-D-pending agent prompts / skills / trinity (BD-206 repoints
    # those to the per-entry streams in later waves).
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
#     _CLIENT_INSTALLED_FILES inventory). Post-BD-257 these are the
#     supporting-docs/ sources only — NO pack-side file ships to clients.
expected_extras = [
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
]
for entry in expected_extras:
    if entry not in strs:
        failures.append(
            f"T3 _iter_client_installed_files() missing expected entry: {entry}"
        )

# T3b: pack-side files are NO LONGER admitted to the base set (BD-257
#      empty sanctioned set — no pack-side file ships to clients).
for gone in ["scripts/pack-help.sh", "scripts/lib/detect.sh"]:
    if gone in strs:
        failures.append(
            f"T3b _iter_client_installed_files() must NOT include de-shipped "
            f"pack-side file: {gone}"
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
import sys, tempfile, os, pathlib, shutil, io, contextlib, subprocess
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
        "#   project-template/docs/pack/HELP-FRAGMENT.md  ->  docs/pack/HELP-FRAGMENT.md  [stage:S11]",
        "#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6]",
        "#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6]",
    ]
    if installed_inventory_extras:
        for entry in installed_inventory_extras:
            inventory_lines.append(f"#   {entry}  ->  {entry}  [stage:S1]")
    inventory_lines.append("# _CLIENT_INSTALLED_FILES_END")
    init_path.write_text("\n".join(inventory_lines) + "\n")

    # BD-244: _build_basename_index() / _build_pack_only_doc_basenames()
    # enumerate git ls-files (tracked-only), so the synthetic tree MUST be a
    # git work tree with its files staged.
    _env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
            "HOME": str(root), "PATH": os.environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=_env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=_env, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_side_bare_internal_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
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

# T8: a project-template/ .sh file with a maintenance-docs/ qualified
#     path-prefix in a shell comment FAILS Check 43. project-template/
#     files are always walked (part (a) of _iter_client_installed_files);
#     post-BD-257 no pack-side file is walked as a client surface (empty
#     sanctioned set), so the .sh-scope coverage rides a genuinely-walked
#     client script instead of the de-shipped detect.sh.
sh_content = (
    "#!/usr/bin/env bash\n"
    "# Synthetic client script; references pack-internal target:\n"
    "# maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md\n"
    "echo \"stub\"\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"scripts/foo.sh": sh_content},
    {"maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md": "stub"},
)
if fail_count < 1:
    failures.append(
        f"T8 (.sh maintenance-docs/ qualified path FAIL) expected >=1 failure, "
        f"got {fail_count}: {captured}"
    )

# T9: PASS same-dir + allowlist — `_intro.md`/`_rules.md` are SANCTIONED
#     per-entry tree siblings (BD-206: `_format.md` is FORBIDDEN, so the
#     PASS fixture references only sanctioned siblings).
content = (
    "# Per-stream rules\n"
    "See \`_intro.md\` for the intro template and \`_rules.md\` for\n"
    "the per-entry contract.\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"docs/project/backlog/_rules.md": content,
     "docs/project/backlog/_intro.md": "stub"},
)
if fail_count != 0:
    failures.append(
        f"T9 (_intro.md allowlist PASS) expected 0 failures, got {fail_count}: {captured}"
    )

# ── BD-288: the self-tree leg (qualified project-template/<X> refs) ──
#
# A client install has no project-template/ directory, so a
# project-template/-prefixed path on a client-installed surface is dead at
# every install. It stays invisible to Check 68 because the path DOES
# resolve in the pack repo.

# T10: FAIL — a project-template/<X> cite from a project-template/ citer.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"docs/pack/GUIDE.md":
        "See \`project-template/skills/foo/SKILL.md\` for the rule.\n",
     "skills/foo/SKILL.md": "stub"},
)
if fail_count < 1 or "docs/pack/GUIDE.md" not in captured:
    failures.append(
        f"T10 (project-template/ cite from a project-template/ citer) "
        f"expected >=1 failure naming docs/pack/GUIDE.md, got "
        f"{fail_count}: {captured}"
    )

# T11: FAIL — the SAME cite from a client-installed supporting-docs/ citer.
#      [BINDING, anti-vacuity] This leg is the ONLY assertion that
#      distinguishes a whole-walk leg from one scoped to citers under
#      project-template/. Under a citer-scoped conditional the leg never
#      runs here and this case passes trivially, so the assertion checks
#      the FAILURE TEXT names the supporting-docs/ citer — a bare
#      "some failure occurred" would not tell the two designs apart.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"skills/foo/SKILL.md": "stub"},
    {"supporting-docs/METHODOLOGY.md":
        "See \`project-template/skills/foo/SKILL.md\` for the rule.\n"},
)
if fail_count < 1 or "supporting-docs/METHODOLOGY.md" not in captured:
    failures.append(
        f"T11 (project-template/ cite from a client-installed "
        f"supporting-docs/ citer) expected >=1 failure naming "
        f"supporting-docs/METHODOLOGY.md — a citer-scoped leg would skip "
        f"this file entirely; got {fail_count}: {captured}"
    )

# T12: PASS — the self-provenance banner. The cited path EQUALS the citing
#      file's own repo-relative path, so it is source attribution (it names
#      where the file was copied FROM) and stays accurate at a client
#      install.
banner = (
    "# Guide\n"
    "*Copied from: project-template/docs/pack/GUIDE.md*\n"
)
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"docs/pack/GUIDE.md": banner},
)
if fail_count != 0:
    failures.append(
        f"T12 (self-provenance banner carve-out) expected 0 failures, got "
        f"{fail_count}: {captured}"
    )

# T13: FAIL — the carve-out is EQUALITY-scoped, not a blanket pass for any
#      "Copied from:" line. Byte-identical banner text placed in a
#      DIFFERENT file (so target != citer) must still FAIL. T12 + T13
#      pin the predicate from both sides: delete the carve-out and T12
#      flips; widen it to any banner line and T13 flips.
fail_count, pass_msg, captured = run_check_with_synthetic(
    {"docs/pack/OTHER.md": banner,
     "docs/pack/GUIDE.md": "stub"},
)
if fail_count < 1 or "docs/pack/OTHER.md" not in captured:
    failures.append(
        f"T13 (banner in a non-matching file) expected >=1 failure naming "
        f"docs/pack/OTHER.md — the carve-out must key on equality with the "
        f"citing file, not on the banner shape; got {fail_count}: {captured}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T13 (PASS / FAIL / exemption / code-block / self-tree leg)" ;;
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

python3 "$REPO_ROOT/scripts/validate-pack.py" --only-check 43 > /tmp/vp-check43-e2e.out 2>&1 || true
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
import sys, tempfile, os, pathlib, shutil, io, contextlib, subprocess
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


def _patch_attr(mod, name, value):
    """Set attribute `name` on the facade alias AND every loaded
    validate_checks.* submodule that already binds it (BD-256 W2
    wave-invariant). The check body's intra-cluster constant now lives in
    validate_checks.boundary_refs; a facade-only patch would NOT bite. This
    reaches the owning module's binding wherever the body resolves it."""
    setattr(mod, name, value)
    for _name, _m in list(sys.modules.items()):
        if _name == "validate_checks" or _name.startswith("validate_checks."):
            if hasattr(_m, name):
                setattr(_m, name, value)


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

    # BD-244: _build_basename_index() / _build_pack_only_doc_basenames()
    # enumerate git ls-files (tracked-only), so the synthetic tree MUST be a
    # git work tree with its files staged.
    _env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
            "HOME": str(root), "PATH": os.environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=_env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=_env, check=True)

    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    saved_fence = mod._CHECK_37_PER_LINE_FENCE_FILES
    mod.failures.clear()
    _patch_root(mod, root)
    if fence_files is not None:
        _patch_attr(mod, "_CHECK_37_PER_LINE_FENCE_FILES", tuple(fence_files))
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_side_bare_internal_refs()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        _patch_attr(mod, "_CHECK_37_PER_LINE_FENCE_FILES", saved_fence)
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
_patch_root(mod, proto_root_path)
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
    _patch_root(mod, _saved_root)
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
# Group 8: BD-257 — empty sanctioned set (no-dual-use) + Check 47
#          EMPTY invariant (supersedes the BD-195 2-member freeze)
# ─────────────────────────────────────────────────────────────────
#
# _SANCTIONED_PACK_SIDE_SHIPPED is now FROZEN EMPTY: no pack-side file
# ships to clients (dependency-direction-placement conjunct (c)). Cases:
#   (a) EMPTY-INVARIANT BITES — a non-empty _SANCTIONED_PACK_SIDE_SHIPPED
#       makes Check 47 FAIL (code-enforced shrink-only floor; the NEGATIVE
#       test proving the assertion has teeth);
#   (b) EMPTY + no pack-side ship — Check 47 PASSES (green);
#   (c) LAZY-ADD blocked — a pack-side install-map entry (empty constant)
#       FAILS Check 47 (set-equality: unsanctioned);
#   (d) WALK-GATE admits NOTHING pack-side — _iter_client_installed_files()
#       does not admit a pack-side map entry under the empty constant;
#   (e) the frozen constant is EXACTLY empty (sized to the measured set);
#   (f) MIGRATOR SCAN (install path 2) — the v10→v11 migrator copies NO
#       pack-side file into clients: a clean migrator PASSES; a direct
#       pack-side `cp "$PACK/…"` OR a pack-side directory-sweep row FAILS
#       (the load-bearing no-dual-use bite on the second install path).

printf "\n=== Group 8: BD-257 empty sanctioned-set + Check 47 empty-invariant ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib, os, subprocess
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

def build_tree(extra_map_entries: list = None,
               migrator_body: str = None) -> pathlib.Path:
    """Build a synthetic REPO_ROOT whose _CLIENT_INSTALLED_FILES inventory
    ships NO pack-side file (the BD-257 empty-sanction reality: only a
    project-template/ entry + a supporting-docs/ entry, both membership-free).
    extra_map_entries add pack-side rows to exercise the lazy-add/leak path.
    migrator_body (BD-257) writes scripts/migrate-v10-to-v11.sh so Check 47's
    migrator copy-vector scan (install path 2) can read it; None omits the
    migrator (the scan then lenient-skips)."""
    root = pathlib.Path(tempfile.mkdtemp(prefix="vp-check47-"))
    (root / "project-template").mkdir()
    (root / "project-template" / "CLAUDE.md").write_text("clean\n")
    (root / "supporting-docs").mkdir()
    (root / "supporting-docs" / "METHODOLOGY.md").write_text("doc\n")
    if migrator_body is not None:
        mg = root / "scripts" / "migrate-v10-to-v11.sh"
        mg.parent.mkdir(parents=True, exist_ok=True)
        mg.write_text(migrator_body)
    inv = [
        "#!/usr/bin/env bash",
        "# _CLIENT_INSTALLED_FILES_START",
        "#   project-template/CLAUDE.md  ->  CLAUDE.md  [stage:S2]",
        "#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6]",
    ]
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
    # BD-244: _build_basename_index() / _build_pack_only_doc_basenames()
    # enumerate git ls-files (tracked-only), so the synthetic tree MUST be a
    # git work tree with its files staged.
    _env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
            "HOME": str(root), "PATH": os.environ.get("PATH", "")}
    subprocess.run(["git", "init", "-q"], cwd=root, env=_env, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, env=_env, check=True)
    return root

def run(check_fn_name: str, root: pathlib.Path) -> tuple:
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    _patch_root(mod, root)
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            getattr(mod, check_fn_name)()
        new_failures = list(mod.failures)
        captured = buf.getvalue()
    finally:
        _patch_root(mod, saved_root)
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(root, ignore_errors=True)
    return (len(new_failures), captured)

# The check body reads boundary_refs._SANCTIONED_PACK_SIDE_SHIPPED directly;
# patch it on the SUBMODULE (a facade-only patch would not bite — same reason
# _patch_root walks every validate_checks.* submodule for REPO_ROOT).
BR = sys.modules['validate_checks.boundary_refs']

# (a) EMPTY-INVARIANT BITES — a NON-EMPTY _SANCTIONED_PACK_SIDE_SHIPPED makes
#     Check 47 FAIL (the code-enforced shrink-only floor; BD-257). This is the
#     load-bearing NEGATIVE test: without the empty-invariant assertion a
#     repopulated set would sail through set-equality if the map matched it.
_saved_const = BR._SANCTIONED_PACK_SIDE_SHIPPED
BR._SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/pack-help.sh",)
try:
    fc, cap = run("check_sanctioned_pack_side_shipped", build_tree())
finally:
    BR._SANCTIONED_PACK_SIDE_SHIPPED = _saved_const
if fc < 1:
    failures.append(
        f"(a) non-empty _SANCTIONED_PACK_SIDE_SHIPPED expected Check 47 FAIL "
        f"(empty-invariant), got {fc}: {cap}"
    )
elif "EMPTY" not in cap or "_SANCTIONED_PACK_SIDE_SHIPPED" not in cap:
    failures.append(
        f"(a) empty-invariant failure message must state the set must be "
        f"EMPTY and name the constant, got: {cap}"
    )

# (b) EMPTY constant + a map that ships NO pack-side file PASSES Check 47.
fc, cap = run("check_sanctioned_pack_side_shipped", build_tree())
if fc != 0:
    failures.append(
        f"(b) empty constant + no pack-side ship expected Check 47 PASS, "
        f"got {fc}: {cap}"
    )

# (c) LAZY-ADD blocked — a pack-side install-map entry (empty constant) FAILS
#     Check 47 (set-equality: unsanctioned).
fc, cap = run(
    "check_sanctioned_pack_side_shipped",
    build_tree(extra_map_entries=["scripts/lib/rogue.sh"]),
)
if fc < 1:
    failures.append(
        f"(c) unsanctioned pack-side map entry expected Check 47 FAIL "
        f"(lazy-add blocked), got {fc}: {cap}"
    )
elif "rogue.sh" not in cap or "_SANCTIONED_PACK_SIDE_SHIPPED" not in cap:
    failures.append(
        f"(c) Check 47 failure message must name the offending path + the "
        f"membership criterion, got: {cap}"
    )

# (d) WALK-GATE admits NOTHING pack-side — with the empty constant,
#     _iter_client_installed_files() does not admit a pack-side map entry.
d_root = build_tree(extra_map_entries=["scripts/lib/rogue.sh"])
saved_root_d = mod.REPO_ROOT
_patch_root(mod, d_root)
try:
    walked = {str(p).replace("\\\\", "/") for p in mod._iter_client_installed_files()}
finally:
    _patch_root(mod, saved_root_d)
    shutil.rmtree(d_root, ignore_errors=True)
if any("rogue.sh" in w for w in walked):
    failures.append(
        "(d) empty constant must NOT admit a pack-side map entry to the "
        "_iter_client_installed_files() walk-set: " + str(sorted(walked))
    )

# (e) the frozen constant is EXACTLY empty (sized to the measured set).
if tuple(BR._SANCTIONED_PACK_SIDE_SHIPPED) != ():
    failures.append(
        f"(e) _SANCTIONED_PACK_SIDE_SHIPPED must be exactly empty (), got "
        f"{BR._SANCTIONED_PACK_SIDE_SHIPPED!r}"
    )

# (f) MIGRATOR SCAN (BD-257, install path 2). Check 47 also scans the v10→v11
#     migrator for pack-side copies into clients. GREEN when every copy vector
#     (direct cp, directory-sweep rows, manifest rows) references
#     project-template/ only; RED when a pack-side source is (re-)introduced.
#     The load-bearing NEGATIVE test (declare-verify-backing): reverting the
#     de-ship — re-adding a pack-side cp of scripts/pack-help.sh — turns it
#     RED. Synthetic bodies use the heredoc marker ROWS (not EOF, which would
#     close the outer bash heredoc); the literal dollar sign is built with
#     chr(36) so NO '\$' appears in this bash heredoc (dodging set -u).
_D = chr(36)  # '$' — kept out of the outer bash heredoc source
_MIGRATOR_CLEAN = (
    '#!/usr/bin/env bash\n'
    'migrator_manifest() {\n'
    "    cat <<'ROWS'\n"
    'project-template/CLAUDE.md CLAUDE.md trinity transform\n'
    'ROWS\n'
    '}\n'
    'migrator_directory_sweeps() {\n'
    "    cat <<'ROWS'\n"
    'project-template/scripts pack-script\n'
    'ROWS\n'
    '}\n'
    '_hook() {\n'
    '    cp "' + _D + 'PACK/project-template/skills/pm-help/SKILL.md" client/skills/pm-help/SKILL.md\n'
    '}\n'
)

# (f1) clean migrator (all vectors project-side) → Check 47 PASS (GREEN).
fc, cap = run("check_sanctioned_pack_side_shipped",
              build_tree(migrator_body=_MIGRATOR_CLEAN))
if fc != 0:
    failures.append(
        f"(f1) clean migrator (project-side copies only) expected Check 47 "
        f"PASS, got {fc}: {cap}"
    )

# (f2) BITE — a direct pack-side cp of scripts/pack-help.sh (the reverted
#      de-ship) → Check 47 FAIL (RED).
_mig_cp = _MIGRATOR_CLEAN.replace(
    '_hook() {\n',
    '_hook() {\n    cp "' + _D + 'PACK/scripts/pack-help.sh" client/scripts/pack-help.sh\n',
)
fc, cap = run("check_sanctioned_pack_side_shipped",
              build_tree(migrator_body=_mig_cp))
if fc < 1:
    failures.append(
        f"(f2) migrator direct pack-side cp expected Check 47 FAIL "
        f"(no-dual-use bite), got {fc}: {cap}"
    )
elif "scripts/pack-help.sh" not in cap or "migrate-v10-to-v11.sh" not in cap:
    failures.append(
        f"(f2) migrator-copy failure message must name the offending path + "
        f"the migrator, got: {cap}"
    )

# (f3) BITE — a pack-side directory-sweep row (scripts/lib pack-lib) → RED.
_mig_sweep = _MIGRATOR_CLEAN.replace(
    'project-template/scripts pack-script',
    'project-template/scripts pack-script\nscripts/lib pack-lib',
)
fc, cap = run("check_sanctioned_pack_side_shipped",
              build_tree(migrator_body=_mig_sweep))
if fc < 1:
    failures.append(
        f"(f3) migrator pack-side sweep row expected Check 47 FAIL "
        f"(no-dual-use bite), got {fc}: {cap}"
    )
elif "scripts/lib" not in cap:
    failures.append(
        f"(f3) migrator sweep-row failure message must name the offending "
        f"path, got: {cap}"
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "BD-257 empty-sanction: non-empty FAILS C47 (empty-invariant), empty PASSES, lazy-add FAILS, walk-gate admits nothing, migrator clean PASSES / pack-side copy FAILS (install path 2)" ;;
    *) t_fail "BD-257 Check-47 empty-invariant / empty-sanction / migrator-scan regression failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 9: BD-288 self-tree carve-out necessity, against the REAL tree
# ─────────────────────────────────────────────────────────────────
#
# The Group-4 legs prove the carve-out's predicate on synthetic trees. This
# group proves it is LOAD-BEARING on the shipped tree: it re-runs the leg's
# own matcher over the real walk WITHOUT the carve-out and asserts the
# carve-out is exactly what keeps those lines green.
#
# Everything is derived from the shipped constants
# (_CHECK_43_SELF_TREE_PREFIXES / _CHECK_43_SELF_TREE_PREFIX_PATTERNS /
# _iter_client_installed_files), so a pattern that stops matching collapses
# the count to 0 and fails this group rather than passing vacuously.

printf "\n=== Group 9: BD-288 self-tree carve-out necessity (real tree) ===\n"

python3 <<EOF
import sys, os
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

# The banner population is a hand-authored set with no generator, so its
# SIZE is pinned here in lock-step. A new *Copied from:* banner is a
# reviewable event: add the file and update this count in the same change.
EXPECTED_BANNERS = 5

exts = set(mod._CHECK_40_FILE_EXTS.split("|")) | set(mod._CHECK_43_EXTRA_WALK_SUFFIXES)
carved = []
uncarved_fail = 0
for rel in mod._iter_client_installed_files():
    if rel.suffix.lstrip(".") not in exts:
        continue
    try:
        text = (mod.REPO_ROOT / rel).read_text()
    except (UnicodeDecodeError, OSError):
        continue
    rel_posix = str(rel).replace(os.sep, "/")
    stripped = mod._strip_code_blocks(text)
    if mod._has_per_line_fence(rel):
        fenced = mod._build_fence_skip_lineset(text) or set()
    else:
        fenced = set()
    for lineno, line in enumerate(stripped, 1):
        if lineno in fenced:
            continue
        for prefix in mod._CHECK_43_SELF_TREE_PREFIXES:
            for m in mod._CHECK_43_SELF_TREE_PREFIX_PATTERNS[prefix].finditer(line):
                target = prefix + m.group(1)
                # MUTATION: the carve-out (\`if target == rel_posix: continue\`)
                # is deliberately NOT applied here.
                if mod._check_43_context_has_anchor(stripped, lineno):
                    continue
                uncarved_fail += 1
                if target == rel_posix:
                    carved.append((rel_posix, lineno, line))

# (a) Without the carve-out the shipped tree FAILs — the carve-out is
#     load-bearing, not decorative.
if len(carved) != EXPECTED_BANNERS:
    failures.append(
        "carve-out necessity: expected %d self-provenance banner(s) to FAIL "
        "with the carve-out removed, got %d (%s). Either a banner was added "
        "or removed (update EXPECTED_BANNERS in the same change), or the "
        "self-tree pattern stopped matching."
        % (EXPECTED_BANNERS, len(carved),
           sorted((f, n) for f, n, _ in carved))
    )

# (b) Every carved occurrence is a provenance BANNER line. This is the
#     carve-out's safety argument: it clears self-references because they
#     are source attribution, not actionable pointers. Self-reference alone
#     is true by construction of the append above and would assert nothing;
#     banner-ness is measured from the line text, so a NON-banner
#     self-reference (a real dead pointer that happens to name its own
#     file) fires this leg instead of being silently cleared.
BANNER_MARKER = "Copied from"
non_banner = [(f, n, l.strip()[:70]) for f, n, l in carved
              if BANNER_MARKER not in l]
if non_banner:
    failures.append(
        "carve-out safety: %d carved occurrence(s) are NOT provenance "
        "banners (no %r on the line) — the carve-out would be clearing a "
        "non-attribution self-reference: %s"
        % (len(non_banner), BANNER_MARKER, non_banner)
    )

# (c) With the carve-out applied the residue is ZERO: the STRIPs and the
#     carve-out together leave nothing, so neither half is masking the
#     other.
residue = uncarved_fail - len(carved)
if residue != 0:
    failures.append(
        "self-tree residue: expected 0 non-banner project-template/ "
        "reference(s) on the client-installed walk, got %d" % residue
    )

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK carved=%d residue=%d" % (len(carved), residue))
EOF
case $? in
    0) t_pass "BD-288 self-tree carve-out is load-bearing on the real tree (removing it FAILs the 5 self-provenance banners) and the post-STRIP residue is 0" ;;
    *) t_fail "BD-288 self-tree carve-out necessity / residue assertion failed (see Python output)" ;;
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
