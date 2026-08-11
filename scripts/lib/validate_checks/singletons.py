"""validate_checks.singletons — the isolated single-connected-component checks
(BD-256 W14).

This module pools the 17 numbered checks that form no multi-check cluster (each
reads only the spine + its own body-local symbols) PLUS the 2 historically-
unnumbered checks whose banners read `── Check: … ──` (`number=None` in the
registry, label-selectable only):

  Check 2  — check_codex_toml                       (Codex TOML parse)
  Check 3  — check_td_tbd_sentinels                 (/backlog/ TD-TBD guard)
  Check 4  — check_readme_version                   (README ↔ git tag; reads README)
  Check 8  — check_reserved_x_prefix                (reserved `x-` prefix scan)
  Check 9  — check_init_project_structure           (BD-044 init structure)
  Check 11 — check_pack_agent_trinity               (trinity symmetry, informational)
  Check 17 — check_tool_config_capability_parity    (AGENT_CAPABILITIES parity)
  Check (None) — check_issue_template_forms         (BD-063 issue forms)
  Check (None) — check_template_archive_v11         (BD-064 archive, informational)
  Check 20 — check_gitignore_env_example_exception  (pack .gitignore exception)
  Check 19 — check_trinity_no_scaffolding_comments  (trinity scaffolding scan;
             a DUP-registered named-lambda entry — both project-template and
             pack-root invocations register under number 19)
  Check 25 — check_customization_detection_regression_guard (BD-089)
  Check 26 — check_migrator_framework_inventory     (BD-119 framework inventory)
  Check 42 — check_ci_workflow_wires_per_check_tests (BD-184/BD-219 allowlist)
  Check 58 — check_validate_job_carries_no_only_check (BD-219 wiring)
  Check 59 — check_check_registry_completeness      (BD-219 wiring proof;
             calls _build_check_registry() — see the HOLD note below)
  Check 60 — check_ci_shard_coverage                (BD-219 shard mirror)

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.singletons import
*`, so the registry assembled in the facade (`_build_check_registry()`) keeps
resolving each check by bare name. Single SSOT — no forked copy. Intra-module
order preserves the facade's source order (2, 3, 4, 8, 9, 11, 17, the two None
checks, 20, 19, 25, 26, 42, 58, 59, 60).

Check 19's two registry entries are NAMED LAMBDAS late-binding
`check_trinity_no_scaffolding_comments` from the facade's `import *`-bound
globals (project-template + pack-root surfaces register independently under
number 19 — an integer `--only-check 19` selects BOTH). The lambdas close over
the re-imported function + the core-seam `REPO_ROOT`, so the registry tuple
still builds and dispatches post-move.

── HOLD: Check 59's _build_check_registry() dependency (the W14 hazard) ──────
Check 59 (`check_check_registry_completeness`) calls `_build_check_registry()`,
which MUST live in the FACADE (its lambdas close over the facade's `import *`-
bound `check_*` + `REPO_ROOT`; it cannot move out of the facade until W15). A
top-level `from <facade> import _build_check_registry` here would be CIRCULAR —
the facade imports this module above its own `_build_check_registry` definition.

Resolution (the ONE permitted minimal non-verbatim change in this wave): a
module-level `_build_check_registry` placeholder (set to `None`) is declared
here as a deferred-resolution seam, and the FACADE INJECTS the real assembler
into this module immediately after defining it (a single
`validate_checks.singletons._build_check_registry = _build_check_registry`
line in the facade, placed right after the def). Check 59's body is otherwise
BYTE-IDENTICAL — its bare `_build_check_registry()` call resolves from this
module global at CALL time (the facade has injected the real callable by then;
the registry is never built at import time). This:
  (a) avoids the import cycle (no facade import at this module's top);
  (b) lets `--only-check 59` AND the full no-flag run resolve the assembler
      correctly (both go through the facade's `main()`, which has already
      injected the builder);
  (c) is minimal (one placeholder line here + one injection line in the facade;
      the check body itself is unchanged).
At W15, when `_build_check_registry()` lands in the facade as the final
assembler home, this injection contract is unchanged (the facade is still the
SSOT for the builder; it still injects it here).

── Singleton-OWNED load-time constants moved with the bodies ────────────────
`CODEX_DIR` (Check 2), `PACK_SCAN_LOCATIONS` (Check 8), `INIT_SCRIPT` /
`DETECT_LIB` / `REQUIRED_DETECT_FUNCTIONS` / `REQUIRED_BD044_DOCS` (Check 9)
are read ONLY by singleton checks (verified by grep at the extraction wave: no
check outside this module reads them), so they are singleton-OWNED, not a
≥2-module seam, and live here. They are not asserted by any test on the facade
re-export surface (no `mod.<const>` access in any test), so they are NOT in
`__all__` (module-internal). `PACK_SCAN_LOCATIONS` references
`OPTIQUITY_BUNDLE_AGENTS_DIR`, which IS a ≥2-module seam (read by
agents_skills's Checks 5/27 AND this module's Check 8 via `PACK_SCAN_LOCATIONS`)
— so per MUST-4 it is PROMOTED to `core` (byte-identical) and imported `from
.core` here, mirroring the W2 `_parse_manifest_records` seam-promotion. (POQ
flagged: the design/plan did not enumerate `OPTIQUITY_BUNDLE_AGENTS_DIR` as a
cross-module seam; this wave promotes it.)

── Spine + seams ────────────────────────────────────────────────────────────
The spine symbols (`REPO_ROOT`, `fail`, `ok`, `failures`) and the cross-module
seams `README` (Check 4) + `CHECK_REGISTRY_EXPECTED_COUNT` (Check 59) +
`OPTIQUITY_BUNDLE_AGENTS_DIR` (the promoted Check-8 seam) are imported `from
.core` — the single SSOT for the spine + W1 seams. (`failures` is imported for
the V3 failures-identity invariant — `core.failures is singletons.failures` —
matching the W2–W13 module convention; the singleton bodies append via `fail()`,
never rebind `failures`. `warn` is NOT imported: no singleton body warns.)
Standard-library `os`, `re`, `subprocess`, `sys`, `tomllib` and `pathlib.Path`
are imported directly at module top (Check 2/17 use `tomllib.load`; Check 9 uses
`os.access`; Check 11/60 use `sys.executable`; Check 4/3/9/26/42/58 use `re`;
Check 4/11/25/26/60 use `subprocess`; Check 19's signature + Check 25 use
`Path`), mirroring the established per-module convention (the spine `import *`
does not re-export stdlib names). Check 17 (`import json as _json`,
`import tomllib`), Check 19 (`import re`), Check 25 (`import shutil`,
`import tempfile`), and Check (None) issue-template (`import yaml`) keep their
body-local imports verbatim.

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

from .core import (
    REPO_ROOT,
    README,
    CHECK_REGISTRY_EXPECTED_COUNT,
    OPTIQUITY_BUNDLE_AGENTS_DIR,
    fail,
    ok,
    failures,
)


# ── Deferred-resolution seam for Check 59 (the W14 hazard; see module docstring).
# `_build_check_registry()` lives in the FACADE (its lambdas close over the
# facade's `import *`-bound check_*/REPO_ROOT) and CANNOT move here without a
# circular import. The facade injects the real assembler into this module
# immediately after defining it; Check 59's body resolves it from THIS module
# global at call time. Declared `None` here so the name exists for standalone
# import (V0) + linting; the registry is never built at import time.
_build_check_registry = None


# CODEX_DIR — singleton-OWNED (read only by Check 2).
CODEX_DIR = REPO_ROOT / "project-template" / ".codex"

# BD-221 (Antigravity conversion): the pack-template agent/skill surfaces a
# reserved-`x-` file could legitimately live in. The Antigravity end-state
# surfaces are the loose Claude/Codex agent dirs, the client agent bundle
# (optiquity-agents), and the shared skills POOL (`project-template/skills`,
# distributed loose to all CLIs by init-project), plus the prompts dir.
# Non-existent dirs are skipped (Check 8 `loc.is_dir()`).
# `OPTIQUITY_BUNDLE_AGENTS_DIR` is the ≥2-module seam imported `from .core`
# above (read here AND by agents_skills's Checks 5/27).
PACK_SCAN_LOCATIONS = [
    REPO_ROOT / "project-template" / ".claude" / "agents",
    REPO_ROOT / "project-template" / ".codex" / "agents",
    OPTIQUITY_BUNDLE_AGENTS_DIR,
    REPO_ROOT / "project-template" / "skills",
    REPO_ROOT / "project-template" / "docs" / "pack" / "prompts",
]

INIT_SCRIPT = REPO_ROOT / "scripts" / "init-project.sh"
DETECT_LIB = REPO_ROOT / "scripts" / "lib" / "detect.sh"
REQUIRED_DETECT_FUNCTIONS = [
    "detect_clean_working_tree",
    "detect_git_repo",
    "detect_pack_path",
    "detect_pack_version",
    "detect_ai_config",
    "detect_x_files",
    "detect_improperly_added_files",
]
REQUIRED_BD044_DOCS = [
    REPO_ROOT / "QUICKSTART.md",
    REPO_ROOT / "supporting-docs" / "SETUP-NEW.md",
    REPO_ROOT / "supporting-docs" / "SETUP-EXISTING.md",
    # MIGRATION-v9-to-v10.md removed in v11 with the v9 sunset (BD-121).
]


# ── Check 2: Codex TOML files ──────────────────────────────────────────────

def check_codex_toml() -> None:
    print("\n── Check 2: Codex TOML files ──")
    toml_files = sorted(CODEX_DIR.rglob("*.toml")) if CODEX_DIR.is_dir() else []
    if not toml_files:
        fail("No .toml files found in project-template/.codex/")
        return

    for toml_file in toml_files:
        rel = toml_file.relative_to(REPO_ROOT)
        try:
            with open(toml_file, "rb") as f:
                tomllib.load(f)
            ok(str(rel))
        except Exception as e:
            fail(f"{rel} — TOML parse error: {e}")


# ── Check 3: TD-TBD sentinels ──────────────────────────────────────────────

def check_td_tbd_sentinels() -> None:
    # BD-203 A10: repoint the TD-TBD guard from the monolith to the
    # `/backlog/` per-entry tree (the no-mirror SSOT). SKIP-on-absent is
    # preserved (the tree is absent pre-conversion). Scans every
    # `/backlog/*.md` entry body for an `**TD-TBD —` entry header (a PM
    # forgot to assign a real BD-NNN number). TD-TBD in descriptive text
    # (e.g., "The coder writes TD-TBD") is expected and excluded.
    print("\n── Check 3: TD-TBD sentinels in /backlog/ per-entry tree ──")
    backlog_dir = REPO_ROOT / "backlog"
    if not backlog_dir.is_dir():
        ok("No /backlog/ tree found (nothing to check)")
        return

    found_any = False
    for entry in sorted(backlog_dir.glob("*.md")):
        if entry.name.startswith("_"):
            continue  # supporting files are not entry content
        try:
            content = entry.read_text()
        except (OSError, UnicodeDecodeError):
            continue
        rel = entry.relative_to(REPO_ROOT)
        for i, line in enumerate(content.split("\n"), 1):
            # Match entry headers like "**TD-TBD — Some title**"
            if re.match(r"\*\*TD-TBD\s*—", line):
                fail(f"{rel}:{i} — entry has TD-TBD instead of a real BD-NNN number")
                found_any = True

    if not found_any:
        ok("/backlog/ — no unprocessed TD-TBD entry headers")


# ── Check 4: README version table vs git tag ────────────────────────────────

def check_readme_version() -> None:
    print("\n── Check 4: README version table vs git tag ──")
    if not README.exists():
        fail("README.md not found")
        return

    # Find the last table row with a version. The DISPLAY form may carry a
    # parenthetical release-state qualifier — `v11.0 (RC1)` — with the
    # bounded allowlist (work/alpha/beta lowercase, RC numbered, GA uppercase).
    # `[\d.]+` already covers the optional `.PATCH` segment.
    content = README.read_text()
    version_rows = re.findall(
        r"^\|\s*(v[\d.]+(?:\s*\((?:work|alpha|beta|RC\d+|GA)\))?)\s*\|",
        content, re.MULTILINE,
    )
    if not version_rows:
        fail("README.md — no version table rows found")
        return
    readme_version = version_rows[-1].strip()
    # Normalize the DISPLAY form to the git-TAG form before comparing to
    # tags: ` (X)` → `-X`, case preserved (git refs cannot carry spaces or
    # parentheses). A bare `v11.0` (no qualifier) normalizes to itself.
    readme_version_tag = re.sub(
        r"\s*\((work|alpha|beta|RC\d+|GA)\)$", r"-\1", readme_version)

    # Get latest git tag (most recent reachable tag)
    try:
        result = subprocess.run(
            ["git", "tag", "--sort=-version:refname"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
        if result.returncode != 0 or not result.stdout.strip():
            ok(f"README.md latest version: {readme_version} (no git tags — skipping)")
            return
        # Find the most specific tag (prefer v8.10 over v8)
        tags = [t.strip() for t in result.stdout.strip().split("\n") if t.strip().startswith("v")]
        if not tags:
            ok(f"README.md latest version: {readme_version} (no version tags — skipping)")
            return

        # Check if README version matches any tag (handles bare major tags
        # like v8). Compare the display→tag-normalized form against tags.
        if readme_version_tag in tags:
            ok(f"README.md version {readme_version} matches git tag")
        else:
            # Check if the README version is ahead of the latest tag (dev branch)
            # e.g., README says v9.0 but no v9.0 tag exists yet — that's expected on dev
            branch_result = subprocess.run(
                ["git", "branch", "--show-current"],
                capture_output=True, text=True, cwd=REPO_ROOT,
            )
            current_branch = branch_result.stdout.strip() if branch_result.returncode == 0 else ""
            if "dev" in current_branch:
                ok(f"README.md version {readme_version} (dev branch — tag will be created at release)")
            else:
                fail(f"README.md latest version is {readme_version} but no matching git tag exists (tags: {tags[0]}...)")

    except FileNotFoundError:
        ok(f"README.md latest version: {readme_version} (git not available — skipping)")


# ── Check 8: Reserved `x-` prefix ───────────────────────────────────────────

def check_reserved_x_prefix() -> None:
    print("\n── Check 8: Reserved `x-` prefix ──")
    any_violation = False
    for loc in PACK_SCAN_LOCATIONS:
        if not loc.is_dir():
            continue
        rel = loc.relative_to(REPO_ROOT)
        offenders = [p.name for p in loc.iterdir() if p.name.startswith("x-")]
        if offenders:
            any_violation = True
            for name in sorted(offenders):
                fail(f"{rel}/ — reserved `x-` prefix in pack: `{name}`")

    if not any_violation:
        ok(f"no `x-` entries in any of {len(PACK_SCAN_LOCATIONS)} pack scan locations")


# ── Check 9: Init-project structure (BD-044) ───────────────────────────────

def check_init_project_structure() -> None:
    print("\n── Check 9: Init-project structure (BD-044) ──")
    any_failed = False

    # (a) scripts/init-project.sh exists and is executable.
    if not INIT_SCRIPT.exists():
        fail(f"{INIT_SCRIPT.relative_to(REPO_ROOT)} — file missing")
        any_failed = True
    elif not os.access(INIT_SCRIPT, os.X_OK):
        fail(f"{INIT_SCRIPT.relative_to(REPO_ROOT)} — not executable (chmod +x)")
        any_failed = True
    else:
        ok(f"{INIT_SCRIPT.relative_to(REPO_ROOT)} — executable")

    # (b) scripts/lib/detect.sh exists; grep confirms required v10 functions.
    if not DETECT_LIB.exists():
        fail(f"{DETECT_LIB.relative_to(REPO_ROOT)} — file missing")
        any_failed = True
    else:
        content = DETECT_LIB.read_text()
        missing_fns = []
        for fn in REQUIRED_DETECT_FUNCTIONS:
            if not re.search(rf"^{re.escape(fn)}\s*\(\s*\)", content, re.MULTILINE):
                missing_fns.append(fn)
        if missing_fns:
            fail(
                f"{DETECT_LIB.relative_to(REPO_ROOT)} — missing required "
                f"function definition(s): {missing_fns}"
            )
            any_failed = True
        else:
            ok(f"{DETECT_LIB.relative_to(REPO_ROOT)} — all {len(REQUIRED_DETECT_FUNCTIONS)} required functions defined")

    # (c) BD-044 docs exist.
    for doc in REQUIRED_BD044_DOCS:
        if not doc.exists():
            fail(f"{doc.relative_to(REPO_ROOT)} — file missing")
            any_failed = True
        else:
            ok(f"{doc.relative_to(REPO_ROOT)} — exists")

    # (e) BD-059 test-migration harness — RETIRED in v11 (BD-121, v9 sunset).
    # The legacy `scripts/test-migration.sh` harness and the v9.3 fixture
    # set under `maintenance-docs/test-fixtures/` were removed when the
    # `migrate-v9-to-v10.sh` migrator was sunset. The v11 N->N+1 framework
    # ships its own test scripts at `scripts/test-migrator-{core,manifest,
    # behavior-preservation}.sh` — those are not asserted here; they run as
    # standalone CI steps in `.github/workflows/validate-pack.yml`.
    # (d) README.md Repository Layout mentions the detection library and
    # migration naming convention. ASCII tree rendering may split
    # `scripts/lib/` across lines, so match on the `detect.sh` filename
    # (unambiguous indicator that the library is documented).
    readme_path = REPO_ROOT / "README.md"
    if readme_path.exists():
        readme_text = readme_path.read_text()
        has_detect = "detect.sh" in readme_text
        has_migration_convention = "MIGRATION-vN-to-vM.md" in readme_text
        if not has_detect:
            fail(
                "README.md — Repository Layout does not mention the "
                "`scripts/lib/detect.sh` shared detection library"
            )
            any_failed = True
        if not has_migration_convention:
            fail(
                "README.md — missing migration-guide naming convention note "
                "(expected literal `MIGRATION-vN-to-vM.md`)"
            )
            any_failed = True
        if has_detect and has_migration_convention:
            ok("README.md — Repository Layout mentions detect.sh and migration naming convention")


def check_pack_agent_trinity() -> None:
    """Check 11 — project-template roster agent trinity-rule symmetry (informational).

    Per BD-059 success criterion #7, every project-template roster agent
    ships in parallel across the three tools (.claude/agents/*.md,
    .codex/agents/*.toml, and the Antigravity optiquity-agents plugin
    bundle .agents-plugin/optiquity-agents/agents/*.md). The trinity rule
    says behavioral content must match unless a divergence is provably
    tool-specific.

    This check runs scripts/compare-agent-trinity.py --all --pack REPO_ROOT
    in lenient mode (whitespace + Markdown formatting normalized) over those
    project surfaces and reports the count of agents whose body content
    diverges across the three. The check is INFORMATIONAL: it always exits
    OK with the count. Hard-failure enforcement requires a
    "trinity-asymmetry-by-design" marker convention the pack does not yet
    have. Until then, the count is a regression signal — reviewers should
    question any change that increases it.
    """
    print("\n── Check 11: Project agent trinity-rule symmetry (informational) ──")
    script = REPO_ROOT / "scripts" / "compare-agent-trinity.py"
    if not script.is_file():
        fail(f"{script.relative_to(REPO_ROOT)} — comparator script missing")
        return

    import subprocess
    try:
        result = subprocess.run(
            [sys.executable, str(script), "--all", "--pack", str(REPO_ROOT), "--summary-only"],
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception as e:
        fail(f"compare-agent-trinity.py invocation failed: {e}")
        return

    out = result.stdout.strip().splitlines()
    summary_line = next((l for l in out if l.startswith("summary:")), None)
    if summary_line is None:
        fail("compare-agent-trinity.py did not emit a summary line")
        return

    # Parse "summary: N agents checked; M divergent"
    m = re.search(r"summary:\s+(\d+)\s+agents checked;\s+(\d+)\s+divergent", summary_line)
    if not m:
        fail(f"could not parse summary: {summary_line!r}")
        return

    checked = int(m.group(1))
    divergent = int(m.group(2))
    divergent_list = next(
        (l[len("divergent: "):] for l in out if l.startswith("divergent: ")),
        "",
    )

    if divergent == 0:
        ok(f"{checked} agents checked — all trinity-symmetric")
    else:
        # Informational only — does not fail the check.
        print(
            f"  INFO: {checked} agents checked, {divergent} divergent "
            f"(lenient mode; tool-specific content allowed). "
            f"Divergent: {divergent_list}"
        )
        print(
            f"  INFO: review with `scripts/compare-agent-trinity.py --all` for details."
        )
        ok(f"{checked} agents checked, {divergent} divergent (informational; not a failure)")


# Checks 12, 13, 14, 15 — RETIRED in v11 (BD-121, v9 sunset).
#
#   Check 12: Three-way classifier helper present (sourced-by-v9-migrator).
#   Check 13: Merge helpers consistent (invoked-by-v9-migrator).
#   Check 14: Migration disposition documented in MIGRATION-v9-to-v10.md.
#   Check 15: scripts/test-migration.sh --quick runs clean.
#
# All four were tightly coupled to scripts/migrate-v9-to-v10.sh,
# scripts/test-migration.sh, maintenance-docs/test-fixtures/, and
# supporting-docs/MIGRATION-v9-to-v10.md — every one of which was
# deleted in BD-121 because no v9 clients remain. The check numbers
# 12..15 are intentionally NOT renumbered; subsequent check numbers
# are kept to preserve cross-references in BACKLOG / archive docs.
#
# Coverage of the shared lib files (scripts/lib/three-way.sh,
# customization-*.sh, detect.sh) — which remain in the pack, consumed
# by the BD-119 migrator framework and the v10->v11 adapter — moved to
# Check 25 (customization-detection regression guard) and Check 26
# (BD-119 migrator-framework inventory), plus the standalone test
# scripts run by .github/workflows/validate-pack.yml
# (test-migrator-core, test-migrator-manifest, test-detect).
# Note: test-migrator-behavior-preservation.sh was retired by BD-137
# after the BD-119 refactor it gated shipped clean.


def check_tool_config_capability_parity() -> None:
    """Check 17 — AGENT_CAPABILITIES expressed identically across the
    tool config files (architect Part 6 / OQ-7 / BD-059).

    The trinity rule applies to per-tool tool-level configuration: every
    capability one tool expresses in its config-file surface must be
    expressed by the other via its own convention. AGENT_CAPABILITIES
    is the v10 capabilities-pattern roster — shipped in:

      Claude  .claude/settings.json env.AGENT_CAPABILITIES (comma-list)
      Codex   .codex/config.toml [agent_capabilities] enabled (TOML list)

    Both must contain identical capability sets. (BD-221: the third
    capability leg is retired with the Antigravity conversion —
    Antigravity carries no AGENT_CAPABILITIES env surface; its
    permissions are an EXAMPLE-only `permissions{allow,deny,ask}`
    block that is never shipped.)
    """
    print("\n── Check 17: Tool-config AGENT_CAPABILITIES parity (BD-059) ──")
    pt = REPO_ROOT / "project-template"
    any_failed = False

    # Claude — JSON env.AGENT_CAPABILITIES
    claude_caps: set[str] | None = None
    claude_path = pt / ".claude" / "settings.json"
    if not claude_path.is_file():
        fail(".claude/settings.json — missing")
        return
    try:
        import json as _json
        claude_data = _json.loads(claude_path.read_text())
        claude_str = claude_data.get("env", {}).get("AGENT_CAPABILITIES", "")
        claude_caps = {c.strip() for c in claude_str.split(",") if c.strip()}
    except Exception as e:
        fail(f".claude/settings.json — parse failed: {e}")
        any_failed = True

    # Codex — TOML [agent_capabilities] enabled list
    codex_caps: set[str] | None = None
    codex_path = pt / ".codex" / "config.toml"
    if not codex_path.is_file():
        fail(".codex/config.toml — missing")
        return
    try:
        import tomllib
        with open(codex_path, "rb") as f:
            codex_data = tomllib.load(f)
        codex_caps = set(codex_data.get("agent_capabilities", {}).get("enabled", []))
    except Exception as e:
        fail(f".codex/config.toml — parse failed: {e}")
        any_failed = True

    if any_failed or claude_caps is None or codex_caps is None:
        return

    if claude_caps == codex_caps:
        ok(f"Claude and Codex agree on AGENT_CAPABILITIES ({len(claude_caps)} capabilities)")
        return

    # Surface the divergence.
    only_claude = sorted(claude_caps - codex_caps)
    only_codex = sorted(codex_caps - claude_caps)
    fail(
        f"Claude vs Codex divergent: "
        f"only-Claude={only_claude} only-Codex={only_codex}"
    )


def check_issue_template_forms() -> None:
    """Check (existing series) — `.github/ISSUE_TEMPLATE/*.yml` forms parse and
    have the required structural fields per V2 §4.1 / §4.2 / §4.3 (BD-063).

    Verifies, per surface (pack-root and project-template):
      - work-item.yml, inbound.yml, config.yml all exist and parse as YAML
      - Forms (work-item, inbound) have name/description/labels/body keys
      - work-item.yml's wi-type dropdown has the per-surface expected
        options. Pack-side admits ONLY `bd` (pack-development backlog
        item; the pack repo files BDs against itself per the
        deliverable-only rule — TD/phase concepts are project-side
        only and must not appear on pack-self-management surfaces).
        Project-side admits the project-side entry types it
        constructs as a deliverable (`td`, `phase-epic-skeleton`,
        `phase-task-skeleton`, `phase-part-skeleton`). The
        `phase-part-skeleton` option was added in v11.0 (BD-185)
        for the mid-work phase expansion Part construct. Per
        V3.3 §6.1 + BD-193 (project-side) + the "Project-side
        concepts on pack-side surfaces — deliverable-only" rule
        (pack memory, user-locked 2026-05-27).
      - inbound.yml's in-category dropdown has all 7 options
        (bug, feature-request, 5× pack-feedback-*) per V2 §4.3
      - config.yml has blank_issues_enabled = false

    GitHub validates field-level form schema server-side at upload time;
    this check guards against malformed YAML and missing top-level keys
    that would render the form non-functional after merge.
    """
    print("\n── Check: Issue template forms (BD-063) ──")
    try:
        import yaml  # type: ignore
    except ImportError:
        fail("PyYAML not available — cannot validate issue templates")
        return

    # Per-surface expected wi-type options.
    #
    # Pack-side ("pack-root") admits ONLY `bd` — the pack repo files
    # pack-development backlog items against itself. TD entries,
    # phase-epic-skeletons, phase-task-skeletons, and phase-part-skeletons
    # are project-side concepts and MUST NOT appear on pack-self-management
    # surfaces per the "Project-side concepts on pack-side surfaces —
    # deliverable-only" rule (pack memory, user-locked 2026-05-27).
    #
    # Project-side ("project-template") admits the project-side entry
    # types the pack constructs as a deliverable (`td`, `phase-epic-skeleton`,
    # `phase-task-skeleton`, `phase-part-skeleton`). It does NOT admit
    # `bd` because BD entries are pack-internal by construction and client
    # projects use TD entries (BD-193).
    #
    # `phase-part-skeleton` was added in v11.0 (BD-185) as the 4th
    # project-side entry type, representing the mid-work phase expansion
    # "Part" construct introduced in v11.0. Under BD-068 soft cap of 5
    # wi-type options per surface; no defense required.
    expected_wi_type_options_per_surface = {
        "pack-root": {"bd"},
        "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"},
    }
    expected_in_category_options = {
        "bug", "feature-request",
        "pack-feedback-workflow", "pack-feedback-prompt",
        "pack-feedback-agent-perf", "pack-feedback-friction",
        "pack-feedback-open-question",
    }

    surfaces = [
        ("pack-root", REPO_ROOT / ".github" / "ISSUE_TEMPLATE"),
        ("project-template", REPO_ROOT / "project-template" / ".github" / "ISSUE_TEMPLATE"),
    ]

    for label, dir_path in surfaces:
        for filename in ("work-item.yml", "inbound.yml", "config.yml"):
            path = dir_path / filename
            if not path.is_file():
                fail(f"{label}: {path.relative_to(REPO_ROOT)} missing")
                continue
            try:
                data = yaml.safe_load(path.read_text())
            except yaml.YAMLError as e:
                fail(f"{label}: {path.relative_to(REPO_ROOT)} — YAML parse error: {e}")
                continue

            if filename == "config.yml":
                if data.get("blank_issues_enabled") is not False:
                    fail(f"{label}: config.yml — blank_issues_enabled must be false")
                else:
                    ok(f"{label}: config.yml — blank_issues_enabled = false")
                continue

            # Forms (work-item, inbound)
            for required_key in ("name", "description", "labels", "body"):
                if required_key not in data:
                    fail(f"{label}: {filename} — missing required top-level key '{required_key}'")
                    break
            else:
                # Validate dropdown options for the type-discriminator field.
                body = data.get("body", [])
                if filename == "work-item.yml":
                    dropdown = next(
                        (b for b in body if b.get("type") == "dropdown" and b.get("id") == "wi-type"),
                        None,
                    )
                    if dropdown is None:
                        fail(f"{label}: work-item.yml — missing wi-type dropdown")
                    else:
                        opts = set(dropdown.get("attributes", {}).get("options", []))
                        expected = expected_wi_type_options_per_surface[label]
                        missing = expected - opts
                        extra = opts - expected
                        if missing or extra:
                            fail(
                                f"{label}: work-item.yml — wi-type options mismatch "
                                f"(missing: {sorted(missing) or 'none'}, "
                                f"extra: {sorted(extra) or 'none'})"
                            )
                        else:
                            ok(f"{label}: work-item.yml — {len(expected)} wi-type options correct (V3.3 §6.1 + BD-193)")
                elif filename == "inbound.yml":
                    dropdown = next(
                        (b for b in body if b.get("type") == "dropdown" and b.get("id") == "in-category"),
                        None,
                    )
                    if dropdown is None:
                        fail(f"{label}: inbound.yml — missing in-category dropdown")
                    else:
                        opts = set(dropdown.get("attributes", {}).get("options", []))
                        missing = expected_in_category_options - opts
                        extra = opts - expected_in_category_options
                        if missing or extra:
                            fail(
                                f"{label}: inbound.yml — in-category options mismatch "
                                f"(missing: {sorted(missing) or 'none'}, "
                                f"extra: {sorted(extra) or 'none'})"
                            )
                        else:
                            ok(f"{label}: inbound.yml — 7 in-category options correct (V2 §4.3)")


def check_template_archive_v11() -> None:
    """Informational — template archive directory v11.0 is well-formed (BD-064).

    Verifies (per BD-064 + Addendum 4 §2.2):
      - templates-archive/v11.0/INDEX.md exists
      - All six entry-type subdirectories exist with SCHEMA.md
        (bd, td, phase-epic, phase-task, phase-part, inbound)
      - templates-archive/v11.0/forms/{work-item,inbound}.yml exist
        and are byte-equal to the live .github/ISSUE_TEMPLATE/ copies

    This is a soft check (warning style, INFO/FAIL) per BD-064 plan:
      "logged in pack-internal CI for human review."
    Drift is reported as INFO, not as a numbered Check failure, so
    that release-cut commits that update the live forms before
    archiving don't have to land both edits in lockstep.
    """
    print("\n── Check: Template archive v11.0 integrity (BD-064; informational) ──")
    archive_root = REPO_ROOT / "maintenance-docs" / "v11-research" / "templates-archive" / "v11.0"
    if not archive_root.is_dir():
        print(f"  INFO: {archive_root.relative_to(REPO_ROOT)} not present (expected at v11.0 cut)")
        return

    index = archive_root / "INDEX.md"
    if index.is_file():
        ok(f"{index.relative_to(REPO_ROOT)} — present")
    else:
        print(f"  INFO: {index.relative_to(REPO_ROOT)} missing")

    for entry_type in ("bd", "td", "phase-epic", "phase-task", "phase-part", "inbound"):
        schema = archive_root / f"{entry_type}-v11.0" / "SCHEMA.md"
        if schema.is_file():
            ok(f"{schema.relative_to(REPO_ROOT)} — present")
        else:
            print(f"  INFO: {schema.relative_to(REPO_ROOT)} missing")

    # Compare archived forms against BOTH pack-side and project-template
    # client-side live forms. PACK-REVIEW-BD060-070 Finding #10 fix:
    # client-side drift was previously unmonitored; now both surfaces
    # are checked. Pack-side and client-side forms have intentional
    # differences (BD vs TD title placeholders, surface description),
    # so we record drift INFO-style for the client side without
    # treating it as a defect.
    surface_dirs = (
        ("pack",   REPO_ROOT / ".github" / "ISSUE_TEMPLATE"),
        ("client", REPO_ROOT / "project-template" / ".github" / "ISSUE_TEMPLATE"),
    )
    for form_name in ("work-item.yml", "inbound.yml"):
        archived = archive_root / "forms" / form_name
        if not archived.is_file():
            print(f"  INFO: {archived.relative_to(REPO_ROOT)} missing")
            continue
        for surface_label, live_dir in surface_dirs:
            live = live_dir / form_name
            if not live.is_file():
                print(f"  INFO: {live.relative_to(REPO_ROOT)} missing (live {surface_label} form expected)")
                continue
            if archived.read_bytes() == live.read_bytes():
                ok(f"forms/{form_name} — byte-equal to {surface_label}: {live.relative_to(REPO_ROOT)}")
            else:
                # Pack-side drift = stale archive; client-side drift =
                # expected (BD vs TD namespace differences). Both
                # report as INFO so a pack maintainer sees both.
                if surface_label == "pack":
                    print(
                        f"  INFO: forms/{form_name} drifted from pack "
                        f"{live.relative_to(REPO_ROOT)}; "
                        f"refresh the archive at next minor cut"
                    )
                else:
                    print(
                        f"  INFO: forms/{form_name} differs from client "
                        f"{live.relative_to(REPO_ROOT)} (expected — BD vs TD namespace)"
                    )


def check_gitignore_env_example_exception() -> None:
    """Check 20 — pack-template .gitignore keeps the !.env.example exception.

    The pack ships committable `.example` templates (e.g. config
    examples) as pack templates. The pack-template `.gitignore` must
    contain `!.env.example` after `.env.*` so fresh installs do not
    silently exclude the pack template. (Historically the v9->v10
    migrator's S0 step also injected this exception into existing
    project .gitignore files; that migrator was retired in v11
    per BD-121. BD-221: the env-template that previously drove this
    exception is retired with the Antigravity conversion; the generic
    `.env.*` + `!.env.example` exception is unchanged.) This check
    guards the pack-side template against drift.
    """
    print("\n── Check 20: Pack .gitignore !.env.example exception (BD-059) ──")
    path = REPO_ROOT / "project-template" / ".gitignore"
    if not path.is_file():
        fail("project-template/.gitignore — file missing")
        return
    text = path.read_text()
    has_envstar = any(
        line.strip() == ".env.*" for line in text.splitlines()
    )
    has_exception = any(
        line.strip() == "!.env.example" for line in text.splitlines()
    )
    if not has_envstar:
        fail("project-template/.gitignore — missing `.env.*` rule")
        return
    if not has_exception:
        fail(
            "project-template/.gitignore — has `.env.*` but missing "
            "`!.env.example` exception. Pack-tracked .env.example files "
            "would be silently ignored on fresh install."
        )
        return
    ok("project-template/.gitignore — `.env.*` + `!.env.example` exception present")


# Surfaces where Check 19 ADMITS the three well-formed BD-136 project-owned
# marker comment openings on top of the strict base allowlist. The client
# (project-template) trinity carries BD-136's byte-preservation markers — an
# empty `<!-- BEGIN project-owned -->` / `<!-- END project-owned -->` seed pair
# under `## Project addenda`, plus `<!-- OPTIONAL: keep this section … -->`
# `[CONDITIONAL]`-retirement hints — which are legitimate structural content,
# not fresh-install scaffolding. The pack-root trinity ships ZERO markers
# (BD-183), so it is EXCLUDED here and keeps the STRICT base allowlist: a
# would-be marker comment on pack-root is still caught as scaffolding. Mirrors
# `_CHECK_16_EXEMPT_SURFACES` (help_fragments.py) in shape, but is an ADMISSION
# set (extra allowed openings on the named surface), not an exemption that
# short-circuits the check.
_CHECK_19_MARKER_SURFACES: set[str] = {"project-template"}


def check_trinity_no_scaffolding_comments(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 19 — v10 trinity templates contain no fresh-install
    scaffolding HTML comments inside body sections.

    The pack ships trinity files with two legitimate HTML comment
    blocks:
      - The file-level `<!-- HOW TO USE THIS TEMPLATE -->` at top
        (above the first H2). Removed by Procedure 5-C.2 preamble
        step on migration.
      - The `<!-- Project addenda go here ... -->` marker before
        the empty `## Project addenda` H2. Preserved by design so
        the migration tooling can reliably locate the addenda
        landing point.
      - GEMINI.md only: the `<!-- Trinity-rule exception ... -->`
        comment documenting the GEMINI.md-intrinsic H2s.

    Any other `<!-- ... -->` block in a trinity file is fresh-install
    scaffolding ("Fill in the platform-specific defaults...", "Add
    platform-specific anti-patterns...", etc.). These leak into live
    project files when users pick "keep pack" during reconciliation
    and create persistent clutter. Catch them at validate-pack time.

    Parameters:
        trinity_root: directory containing the 3 trinity files. Default
            `None` resolves to `REPO_ROOT / "project-template"`
            (preserves the original single-location behavior). Pass
            `REPO_ROOT` for the pack-root trinity location.
        label: human-readable surface name used in FAIL/OK messages
            and file-path prefixes. Examples: `"project-template"`,
            `"pack-root"`.

    Per BD-183 (Override 9 compliance, mirroring BD-181's Check 18
    generalization): Each invocation checks WITHIN its own trinity
    location only. There is NO cross-location coupling — pack-root
    and project-template trinity carry different audiences and
    different rules by design (per pack-root trinity § Rules →
    Trinity rule note paragraph). Call this function once per
    trinity location; the invocations are independent.
    """
    # Sentinel pattern: callers in main() pass explicit (trinity_root, label).
    # `None` default kept for backward-compat with no-arg callers (test suite
    # / external use). Do not collapse to a literal default — call sites
    # declare their scope explicitly per BD-183 generalization design.
    if trinity_root is None:
        trinity_root = REPO_ROOT / "project-template"
    print(f"\n── Check 19 [{label}]: Trinity templates free of body scaffolding (BD-059, BD-183) ──")
    import re
    ALLOWED_OPENINGS = (
        "HOW TO USE THIS TEMPLATE",
        "Project addenda go here",
        "Trinity-rule exception",
        # Guardrail 2 (BD-173 H.13) per-line fence markers in trinity
        # files. The fence wraps the "Project SSOT-first" pack-only-files
        # enumeration block per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md
        # §2.4. Markers are intentional structural content, not
        # fresh-install scaffolding.
        "DENY-LIST-CONTENT-START",
        "DENY-LIST-CONTENT-END",
    )
    # BD-136 C2 — CLIENT trinity marker-section preservation. On the
    # project-template (client) surface ONLY, admit the three well-formed
    # project-owned marker comment openings. Bounded EXACTLY to the legitimate
    # BD-136 marker forms (measure-then-bound — do NOT broaden):
    #   • "OPTIONAL: keep this section" — the `[CONDITIONAL]`-retirement hint
    #     lead (N2-tightened; NOT bare `OPTIONAL:`, so a fresh-install
    #     `OPTIONAL: fill in …` scaffolding comment is STILL caught).
    #   • "BEGIN project-owned" — the seed/override BEGIN marker; also covers
    #     the annotated `BEGIN project-owned: renamed-from "…"` form (startswith).
    #   • "END project-owned" — the seed/override END marker.
    # Pack-root ships ZERO markers and keeps the STRICT base allowlist above —
    # a would-be marker comment on pack-root still FAILs Check 19.
    if label in _CHECK_19_MARKER_SURFACES:
        ALLOWED_OPENINGS = ALLOWED_OPENINGS + (
            "OPTIONAL: keep this section",
            "BEGIN project-owned",
            "END project-owned",
        )
    any_failed = False
    for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        path = trinity_root / name
        if not path.is_file():
            fail(f"{label}/{name} — file missing")
            any_failed = True
            continue
        text = path.read_text()
        for m in re.finditer(r"<!--(.*?)-->", text, flags=re.DOTALL):
            body = m.group(1).strip()
            if not body:
                continue
            first_line = body.splitlines()[0].strip()
            if any(first_line.startswith(prefix) for prefix in ALLOWED_OPENINGS):
                continue
            line_no = text[: m.start()].count("\n") + 1
            fail(
                f"{label}/{name}:{line_no} — fresh-install scaffolding "
                f"comment in body: {first_line[:80]!r}"
            )
            any_failed = True
    if not any_failed:
        ok(f"[{label}] All three trinity templates free of body-section scaffolding comments")


def check_customization_detection_regression_guard() -> None:
    """Check 25 — Customization-detection regression guard (BD-089).

    Synthetic fixture exercises the BD-088 library against a known v10-
    shape project with realistic customizations. Asserts:
      1. Every customized file produces exactly one finding row.
      2. A trinity file edited by the project surfaces as
         `customization-detected-needs-reconciliation` (not silently merged).
      3. An `x-`-prefixed custom agent surfaces as `project-only-file`.
      4. The truthful-report contract holds — every fixture file appears
         in the rendered report.md.

    Without this Check, a BD-088 regression (silently dropping a
    finding, returning success when a real-merge case occurs) could ship
    unnoticed. CI fails on regression.

    Coverage scope: this Check guards against silent disposition / report
    drops for the four most-load-bearing classes. Exhaustive class
    coverage (removed-by-pack-customized sidecar, JSON/TOML allowlist
    merges, pm-chat marker-section, all-three-absent early-return) is
    delegated to scripts/tests/test-customization-preserve.sh, which
    runs in CI per BD-083.
    """
    print("\n── Check 25: Customization-detection regression guard (BD-089) ──")
    import shutil
    import tempfile

    lib_dir = REPO_ROOT / "scripts" / "lib"
    needed = ["three-way.sh", "customization-preserve.sh", "customization-report.sh"]
    for n in needed:
        if not (lib_dir / n).is_file():
            fail(f"BD-088 library missing: {lib_dir.relative_to(REPO_ROOT)}/{n}")
            return

    tmpdir = tempfile.mkdtemp(prefix="vp-bd089-")
    try:
        state_dir = Path(tmpdir) / "state"
        # Build a tiny driver script that sources the BD-088 libs and
        # dispatches a fixture set covering: trinity-with-customization,
        # x-prefixed custom agent, unchanged-pack file. Capture the
        # dispositions TSV for assertion.
        driver = Path(tmpdir) / "driver.sh"
        driver.write_text(f"""#!/usr/bin/env bash
set -euo pipefail
export _CP_PACK_ROOT="{REPO_ROOT}"
source "{REPO_ROOT}/scripts/lib/three-way.sh"
source "{REPO_ROOT}/scripts/lib/customization-preserve.sh"
source "{REPO_ROOT}/scripts/lib/customization-report.sh"
customization_preserve_init "{state_dir}" ".v10-customized"

# Fixture 1: trinity with project customization (real-merge-required).
mkdir -p "{tmpdir}/files"
echo "v10-base" > "{tmpdir}/files/trinity-base.md"
echo "v10-base + project edit" > "{tmpdir}/files/trinity-ours.md"
echo "v11-pack edit" > "{tmpdir}/files/trinity-theirs.md"
cp "{tmpdir}/files/trinity-ours.md" "{tmpdir}/files/trinity-dest.md"
customization_preserve "{tmpdir}/files/trinity-base.md" \\
    "{tmpdir}/files/trinity-ours.md" "{tmpdir}/files/trinity-theirs.md" \\
    "CLAUDE.md" "{tmpdir}/files/trinity-dest.md" trinity >/dev/null

# Fixture 2: x-prefixed custom agent (project-only-file).
echo "x-agent body" > "{tmpdir}/files/x-mine.md"
customization_preserve "" "{tmpdir}/files/x-mine.md" "" \\
    ".claude/agents/x-mine.md" "{tmpdir}/files/x-mine.md" custom-agent >/dev/null

# Fixture 3: unchanged-pack file.
echo "same" > "{tmpdir}/files/unchanged.md"
customization_preserve "{tmpdir}/files/unchanged.md" \\
    "{tmpdir}/files/unchanged.md" "{tmpdir}/files/unchanged.md" \\
    "docs/pack/PM-CHAT.md" "{tmpdir}/files/unchanged.md" pm-chat >/dev/null

customization_report "{state_dir}/dispositions.tsv" "{state_dir}/report.md" \\
    "Check 25 fixture report" >/dev/null
""")
        driver.chmod(0o755)
        result = subprocess.run(
            ["bash", str(driver)],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            fail(f"BD-088 driver failed (rc={result.returncode}): {result.stderr.strip()}")
            return

        tsv = state_dir / "dispositions.tsv"
        if not tsv.is_file():
            fail("BD-088 driver produced no dispositions.tsv")
            return
        rows = [
            line.split("\t")
            for line in tsv.read_text().splitlines()
            if line and not line.startswith("#")
        ]
        if len(rows) != 3:
            fail(f"expected 3 dispositions for 3-fixture set; got {len(rows)}")
            for r in rows:
                fail(f"  row: {r}")
            return

        # Index by rel_path (column 3) for stable assertion.
        by_rel = {r[2]: r for r in rows}
        expected = {
            "CLAUDE.md": ("customization-detected-needs-reconciliation", "trinity"),
            ".claude/agents/x-mine.md": ("project-only-file", "custom-agent"),
            "docs/pack/PM-CHAT.md": ("unchanged-pack", "pm-chat"),
        }
        any_failed = False
        for rel, (exp_disp, exp_class) in expected.items():
            if rel not in by_rel:
                fail(f"truthful-report violation: fixture file '{rel}' missing from dispositions.tsv")
                any_failed = True
                continue
            row = by_rel[rel]
            if row[0] != exp_disp:
                fail(f"{rel}: expected disposition '{exp_disp}', got '{row[0]}'")
                any_failed = True
            if row[1] != exp_class:
                fail(f"{rel}: expected class '{exp_class}', got '{row[1]}'")
                any_failed = True

        # Truthful contract: every fixture rel must appear in report.md.
        report = (state_dir / "report.md").read_text()
        for rel in expected:
            if rel not in report:
                fail(f"truthful-report violation: '{rel}' missing from rendered report.md")
                any_failed = True

        if any_failed:
            return
        ok("3/3 fixture rows recorded with expected disposition + class")
        ok("truthful-report contract: every fixture file appears in report.md")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


# ── Check 24 RETIRED in BD-194 (per ARCHITECTURE-BD-194.md Candidate 6).
# Pack-side help-fragment existence is asserted by Check 23; project-side
# existence is asserted by Check 41 (_CLIENT_INSTALLED_FILES self-doc list
# integrity). No cross-surface content invariant is required or asserted.


# ── Check 26: BD-119 migrator-framework inventory ──────────────────────────

def check_migrator_framework_inventory() -> None:
    """Check 26 — BD-119 migrator-framework inventory.

    Asserts, per ARCHITECTURE-BD-119.md §3.2 and PLAN-BD-119.md §3, that
    the four shared libraries (`migrator-core.sh`, `migrator-stages.sh`,
    `migrator-manifest.sh`, and the BD-147 `migrator-skills.sh`) are
    present and pass `bash -n` syntax validation, and that
    `migrator-core.sh` contains:

      - regex matches for the 6 public-API function-name declarations
        (frozen at C-3 of PLAN-BD-119.md): `migrator_run`,
        `migrator_dispatch`, `migrator_detect_target_version`,
        `migrator_select_adapter`, `migrator_baseline_to_tmp`,
        `migrator_target_surface_for_version`;
      - regex matches for the 8 `readonly`-declared exit-code
        constants: `EXIT_PACK_INVALID`, `EXIT_NOT_GIT`, `EXIT_DIRTY`,
        `EXIT_NOT_BASELINE`, `EXIT_BASELINE_MISSING`, `EXIT_LIB_MISSING`,
        `EXIT_ALREADY_MIGRATED`, `EXIT_INTERNAL`;
      - the `EXIT_NOT_V10` back-compat synonym (PLAN §3.5).

    Per PLAN-SKILL-DIMENSIONS.md §7.2 (BD-147), the inventory now
    includes `migrator-skills.sh` as a fourth blessed framework lib.
    `migrator-skills.sh` must additionally declare its public-API
    function `migrator_skill_rename` (and the forward-declared
    `migrator_skill_split` wrapper).

    The check uses regex matching against the file contents — it does
    NOT source the file, so it does not detect runtime-only defects.

    Lenient mode: if `scripts/lib/migrator-core.sh` is absent (early
    commits before C-2), the check returns OK with a notice. Once the
    file lands, the check is strict on syntax + the regex surface above.
    """
    print("\n── Check 26: BD-119 migrator-framework inventory ──")
    core = REPO_ROOT / "scripts" / "lib" / "migrator-core.sh"
    stages = REPO_ROOT / "scripts" / "lib" / "migrator-stages.sh"
    manifest = REPO_ROOT / "scripts" / "lib" / "migrator-manifest.sh"
    skills = REPO_ROOT / "scripts" / "lib" / "migrator-skills.sh"

    if not core.is_file():
        ok("migrator-core.sh not yet present — skipping (lenient pre-C-2)")
        return

    # Strict mode: all four libs must exist and be syntax-valid.
    for lib in (core, stages, manifest, skills):
        if not lib.is_file():
            fail(f"migrator framework library missing: {lib.relative_to(REPO_ROOT)}")
            return
        rc = subprocess.run(
            ["bash", "-n", str(lib)],
            capture_output=True, text=True,
        )
        if rc.returncode != 0:
            fail(f"bash -n {lib.name} failed: {rc.stderr.strip()}")
            return
        ok(f"{lib.relative_to(REPO_ROOT)} syntax valid")

    # Public-API names must appear as function definitions in core.
    # BD-282 added migrator_pause as an additive extension to the frozen
    # public surface (adapters call it instead of `exit 0` to signal a
    # deliberate, --resume-able pause). Count auto-derives from the list.
    required_names = [
        "migrator_run",
        "migrator_dispatch",
        "migrator_detect_target_version",
        "migrator_select_adapter",
        "migrator_baseline_to_tmp",
        "migrator_target_surface_for_version",
        "migrator_pause",
    ]
    core_text = core.read_text()
    for name in required_names:
        # Match either `name() {` or `function name {` declarations.
        if not re.search(rf'(^|\n)\s*(function\s+)?{re.escape(name)}\s*\(\)\s*\{{',
                         core_text):
            fail(f"migrator-core.sh missing public-API function: {name}()")
            return
    ok(f"migrator-core.sh declares all {len(required_names)} public-API functions")

    # Exit-code constants must be present. BD-119 froze 8 baseline codes;
    # BD-101 added EXIT_GATE_FAILED (=31) for verification-gate failures.
    required_exits = [
        "EXIT_PACK_INVALID",
        "EXIT_NOT_GIT",
        "EXIT_DIRTY",
        "EXIT_NOT_BASELINE",
        "EXIT_BASELINE_MISSING",
        "EXIT_LIB_MISSING",
        "EXIT_ALREADY_MIGRATED",
        "EXIT_GATE_FAILED",
        "EXIT_INTERNAL",
    ]
    for sym in required_exits:
        if not re.search(rf'\breadonly\s+{re.escape(sym)}=', core_text):
            fail(f"migrator-core.sh missing exit-code constant: readonly {sym}=...")
            return
    ok(f"migrator-core.sh declares all {len(required_exits)} exit-code constants")

    # EXIT_NOT_V10 synonym preserved for back-compat (PLAN §3.5).
    if "EXIT_NOT_V10" not in core_text:
        fail("migrator-core.sh missing EXIT_NOT_V10 back-compat synonym")
        return
    ok("migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym")

    # BD-147 — migrator-skills.sh public-API surface. Both the skill-rename
    # adapter and the forward-declared skill-split wrapper must be present
    # as function definitions so adapters can rely on a stable API across
    # N→N+1 migrators (per ARCHITECTURE-SKILL-DIMENSIONS.md §6.5).
    skills_text = skills.read_text()
    skills_required_names = [
        "migrator_skill_rename",
        "migrator_skill_split",
    ]
    for name in skills_required_names:
        if not re.search(
            rf'(^|\n)\s*(function\s+)?{re.escape(name)}\s*\(\)\s*\{{',
            skills_text,
        ):
            fail(f"migrator-skills.sh missing public-API function: {name}()")
            return
    ok(
        f"migrator-skills.sh declares all {len(skills_required_names)} "
        "public-API functions"
    )

    # BD-147 — migrator-core.sh must source migrator-skills.sh so the
    # public API is available to per-version adapters via the same single
    # `source migrator-core.sh` entry point as the other framework libs.
    if "migrator-skills.sh" not in core_text:
        fail("migrator-core.sh does not source migrator-skills.sh")
        return
    ok("migrator-core.sh sources migrator-skills.sh")


# ── Check 42: CI test-wiring allowlist is valid + bounded (BD-184, BD-219) ──
#
# History: Check 42 was introduced by BD-184 to close the "missing test
# wiring" gap class (a disk test with no CI invocation) — a gap that
# surfaced 5 times across the BD-175 batch alone (BD-179/BD-183 FIXes).
# BD-219 C3 generalized it to full disk_KEEP_set == wired_set over a
# STATIC `tests`-job matrix.
#
# BD-219 redesign (dynamic auto-regen): the CI `tests` matrix is now
# DERIVED FROM DISK at run time (the `plan` job's `--emit-matrix`), so
# `wired_set` IS `disk_KEEP_set` by construction — the old equality is a
# tautology and the old failure mode ("forgot to paste the matrix")
# cannot occur. Adding a test requires only committing the test file; it
# is auto-discovered and sharded on the next push. The gap class Check 42
# closed is therefore eliminated by construction, NOT by this guard.
#
# Re-scoped charge (the assertions that STILL carry signal):
#   - ALLOWLIST VALIDITY (measure-then-bound, the core surviving guard):
#     every entry of scripts/ci-test-wiring-allowlist.txt must (a) exist
#     on disk and (b) match the disk-glob shape (scripts/test*.sh OR
#     scripts/tests/*.sh OR scripts/tests/fixture-dependent/*.sh) — so
#     the allowlist stays sized to EXACTLY the genuinely-excludable set.
#   - PARTITIONABILITY (cheap structural sanity): the disk KEEP set is
#     non-empty (an empty KEEP = the allowlist swallowed everything =
#     contamination FAIL); lenient SKIP if literally no test on disk.
#
# The disk glob here enumerates the SAME three explicit non-recursive
# dirs as ci-shard-plan.py parse_wired_tests() (test-ci-shard-plan.sh
# Group 6 asserts the two agree). scripts/tests/fixtures/ (the inert
# test-DATA tree) is NEVER swept in — no recursion.

def check_ci_workflow_wires_per_check_tests() -> None:
    """Check 42 — CI test-wiring allowlist is valid + bounded (BD-184, BD-219).

    RE-SCOPED in the BD-219 dynamic-autoregen redesign. The CI `tests` matrix is
    now disk-derived at run time (the `plan` job's `ci-shard-plan.py
    --emit-matrix`), so `wired_set == disk_KEEP_set` by construction and the old
    `disk_KEEP_set == wired_set` equality is a tautology with no failure mode.
    This check now asserts the two properties that STILL carry signal:

      (1) Allowlist VALIDITY (measure-then-bound). For every entry of
          scripts/ci-test-wiring-allowlist.txt:
            (a) the path EXISTS on disk (a stale allowlist line for a deleted
                test → FAIL naming it), AND
            (b) the path matches the disk-glob shape — scripts/test*.sh OR
                scripts/tests/*.sh OR scripts/tests/fixture-dependent/*.sh
                (an entry the glob could never produce is meaningless → FAIL).
      (2) PARTITIONABILITY (cheap structural sanity). The disk KEEP set
          (disk glob − allowlist) is NON-EMPTY (an empty KEEP means the
          allowlist swallowed every test = contamination → FAIL). Lenient SKIP
          when literally no test script is on disk.

    disk glob = {scripts/test*.sh + scripts/tests/*.sh
                 + scripts/tests/fixture-dependent/*.sh} — three EXPLICIT
    non-recursive dirs (mirrors ci-shard-plan.py parse_wired_tests();
    scripts/tests/fixtures/ inert data is never swept in). The 1-line allowlist
    reason text after a path is ignored by the parser.

    Cheap (ci-check-runtime-compounding): three dir globs + one small allowlist
    read; no subprocess, no real-tree scan, no yml read. Routes through
    `run_check` (per-check WARN budget).

    Lenient mode: if neither `scripts/` nor `scripts/tests/` holds any test*.sh
    the check SKIPs.
    """
    print("\n── Check 42: CI test-wiring allowlist is valid + bounded (BD-184, BD-219 redesign) ──")
    scripts_dir = REPO_ROOT / "scripts"
    tests_dir = REPO_ROOT / "scripts" / "tests"
    fxdep_dir = tests_dir / "fixture-dependent"
    allowlist_path = REPO_ROOT / "scripts" / "ci-test-wiring-allowlist.txt"

    # ── Enumerate the FULL disk test-script set (repo-relative paths) over the
    # SAME three explicit non-recursive dirs as ci-shard-plan.py
    # parse_wired_tests(). The fixture-dependent/ subdir is enumerated
    # explicitly; scripts/tests/fixtures/ (inert test data) is never reached
    # (no recursion) — a recursion would catastrophically wire the data files.
    disk_paths = set()
    for p in scripts_dir.glob("test*.sh"):
        disk_paths.add(f"scripts/{p.name}")
    if tests_dir.is_dir():
        for p in tests_dir.glob("*.sh"):
            disk_paths.add(f"scripts/tests/{p.name}")
    if fxdep_dir.is_dir():
        for p in fxdep_dir.glob("*.sh"):
            disk_paths.add(f"scripts/tests/fixture-dependent/{p.name}")
    if not disk_paths:
        ok("no scripts/test*.sh or scripts/tests/*.sh present — skipping (lenient)")
        return

    # ── Load the measure-then-bound allowlist (STRIP set). One repo-relative
    # path per line; `#` comments + blanks ignored; an inline `# reason` after
    # the path is dropped (first whitespace token only).
    allowlist = set()
    if allowlist_path.is_file():
        for raw in allowlist_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            allowlist.add(line.split()[0])

    # A path matches the disk-glob shape iff the glob COULD produce it:
    #   scripts/<test*.sh>  OR  scripts/tests/<*.sh>  OR
    #   scripts/tests/fixture-dependent/<*.sh>
    def _matches_glob_shape(path):
        if not path.endswith(".sh"):
            return False
        rest = path[len("scripts/"):] if path.startswith("scripts/") else None
        if rest is None:
            return False
        if "/" not in rest:
            return rest.startswith("test")           # scripts/test*.sh
        if rest.startswith("tests/"):
            tail = rest[len("tests/"):]
            if "/" not in tail:
                return True                           # scripts/tests/*.sh
            if tail.startswith("fixture-dependent/"):
                leaf = tail[len("fixture-dependent/"):]
                return "/" not in leaf                # .../fixture-dependent/*.sh
        return False

    problems = False
    # (1a) stale allowlist entry — path not on disk.
    for path in sorted(allowlist):
        if not (REPO_ROOT / path).is_file():
            problems = True
            fail(
                f"{path} — listed in scripts/ci-test-wiring-allowlist.txt "
                f"(intentionally-OUT) but DOES NOT EXIST on disk. Allowlist "
                f"staleness: remove its line (the allowlist must be sized to "
                f"EXACTLY the still-present STRIP set)."
            )
    # (1b) malformed allowlist entry — path not matching the disk-glob shape.
    for path in sorted(allowlist):
        if not _matches_glob_shape(path):
            problems = True
            fail(
                f"{path} — listed in scripts/ci-test-wiring-allowlist.txt but "
                f"does NOT match the disk-glob shape (scripts/test*.sh OR "
                f"scripts/tests/*.sh OR scripts/tests/fixture-dependent/*.sh). "
                f"An allowlist entry the glob can never produce is meaningless; "
                f"fix the path or remove the line."
            )

    disk_keep_set = disk_paths - allowlist

    # (2) partitionability: an empty KEEP set means the allowlist swallowed
    # every test on disk — contamination.
    if not disk_keep_set:
        problems = True
        fail(
            f"the disk KEEP set is EMPTY ({len(disk_paths)} test script(s) on "
            f"disk, all {len(allowlist)} of them allowlisted). The allowlist "
            f"has swallowed every test — the CI matrix would partition NOTHING. "
            f"Shrink scripts/ci-test-wiring-allowlist.txt to EXACTLY the "
            f"genuinely-un-runnable-in-CI set."
        )

    if problems:
        return

    ok(
        f"Check 42 — {len(disk_paths)} test script(s) on disk; "
        f"{len(allowlist)} allowlisted (intentionally-OUT, all valid: "
        f"exist + glob-shaped); {len(disk_keep_set)} KEEP (non-empty, "
        f"partitionable). The CI matrix is disk-derived at run time "
        f"(ci-shard-plan.py --emit-matrix); the allowlist is valid + bounded."
    )


def check_validate_job_carries_no_only_check() -> None:
    """Check 58 — the authoritative `validate` job carries NO `--only-check`.

    BD-219 C3 (design §6.4). The `--only-check` selector (BD-219 C1) is an
    opt-in per-check narrowing for the test battery's e2e legs. The full
    `validate` job MUST run ALL checks (no flag = all) so the authoritative
    coverage can never be silently narrowed. This check parses the workflow
    yml and FAILs if any `python3 scripts/validate-pack.py` invocation in the
    `validate` job carries a `--only-check` flag.

    Cheap (ci-check-runtime-compounding): one workflow-text regex; no
    subprocess, no real-tree scan. Routes through `run_check`.

    Lenient: workflow absent → SKIP.
    """
    print("\n── Check 58: validate job runs ALL checks (no --only-check) (BD-219) ──")
    workflow_path = REPO_ROOT / ".github" / "workflows" / "validate-pack.yml"
    if not workflow_path.is_file():
        ok(".github/workflows/validate-pack.yml absent — skipping (lenient)")
        return
    workflow_text = workflow_path.read_text()

    # Any `validate-pack.py` invocation line carrying `--only-check` anywhere
    # on it is a violation: the authoritative full run must never be narrowed.
    # The match is line-scoped so a `--only-check` on an unrelated line cannot
    # false-trigger.
    offenders = []
    invoke = re.compile(r"validate-pack\.py")
    flag = re.compile(r"--only-check")
    for raw in workflow_text.splitlines():
        if invoke.search(raw) and flag.search(raw):
            offenders.append(raw.strip())

    if offenders:
        for line in offenders:
            fail(
                f"the authoritative validate-pack.py run carries `--only-check`"
                f" — the full run must execute ALL checks (no flag = all). "
                f"Offending workflow line: `{line}`. Remove `--only-check` from"
                f" the full-run invocation; `--only-check` is for the per-check "
                f"test e2e legs only (BD-219 C1/C3)."
            )
        return
    ok("Check 58 — no `--only-check` on any validate-pack.py full-run "
       "invocation in the workflow; the authoritative run executes all checks.")


def check_check_registry_completeness() -> None:
    """Check 59 — CHECK_REGISTRY completeness (BD-219, the moved wiring proof).

    BD-219 C3 (design §6.4). Under `--only-check` (BD-219 C1) the per-check
    test e2e legs no longer IMPLICITLY prove "this check is wired into the
    full run" (selecting a check proves it is in the registry, not that the
    no-flag run executes it). This check restores that proof as an EXPLICIT
    asserted invariant:

      - `len(_build_check_registry()) == CHECK_REGISTRY_EXPECTED_COUNT`
        (a one-line bookkeeping constant, like the existing agent-count
        check — updated in lock-step whenever a check is added/removed), AND
      - every registry entry is a well-formed `(number, label, fn, budget)`
        4-tuple with a UNIQUE label and a CALLABLE fn (so the no-flag full
        run can dispatch every entry — `main()` iterates the registry).

    Net effectiveness UNCHANGED (stronger, in fact: an asserted invariant
    rather than an implicit e2e side-effect).

    Cheap (ci-check-runtime-compounding): builds the in-memory registry once
    (no subprocess, no I/O). Routes through `run_check`.
    """
    print("\n── Check 59: CHECK_REGISTRY completeness (BD-219 wiring proof) ──")
    registry = _build_check_registry()
    n = len(registry)

    if n != CHECK_REGISTRY_EXPECTED_COUNT:
        fail(
            f"CHECK_REGISTRY has {n} entr(y/ies) but "
            f"CHECK_REGISTRY_EXPECTED_COUNT == {CHECK_REGISTRY_EXPECTED_COUNT}."
            f" A check was added or removed without updating the expected-count"
            f" constant (the one-line bookkeeping edit, like the agent-count "
            f"check). Set CHECK_REGISTRY_EXPECTED_COUNT to {n} if the change is"
            f" intentional, or restore the missing registry entry."
        )
        return

    # Structural integrity: each entry is a 4-tuple; label unique; fn callable.
    labels = set()
    bad = []
    for entry in registry:
        if not (isinstance(entry, tuple) and len(entry) == 4):
            bad.append(f"malformed entry (not a 4-tuple): {entry!r}")
            continue
        number, label, fn, budget = entry
        if not callable(fn):
            bad.append(f"entry {label!r}: fn is not callable")
        if label in labels:
            bad.append(f"duplicate registry label: {label!r}")
        labels.add(label)

    if bad:
        for b in bad:
            fail(f"CHECK_REGISTRY integrity: {b}")
        return

    ok(
        f"Check 59 — CHECK_REGISTRY has {n} entr(y/ies) "
        f"(== CHECK_REGISTRY_EXPECTED_COUNT); every entry is a well-formed "
        f"(number, label, fn, budget) 4-tuple with a unique label + callable "
        f"fn. The no-flag full run executes every registered check."
    )


def check_ci_shard_coverage() -> None:
    """Check 60 — CI shard partition covers the wired set (BD-219 mirror).

    BD-219 C3 (design §6.3); BD-219 redesign repoints the source to disk. The
    AUTHORITATIVE run-time coverage assertion lives in the `tests-result`
    aggregation JOB (once per CI run). This is the convenience MIRROR: a thin
    validate-pack check that sub-invokes `scripts/lib/ci-shard-plan.py
    --assert-coverage` so a developer running `validate-pack` locally surfaces
    shard-coverage drift without pushing.

    `--assert-coverage` exits 0 iff `union(shards) == wired_KEEP_set` (the
    DISK-derived KEEP set — BD-219 redesign; no static yml include array), shards
    pairwise-disjoint, and the fixture cohesion set (tests under
    scripts/tests/fixture-dependent/ — LOCATION-based cohesion) is co-located in
    one shard.

    Cheap (ci-check-runtime-compounding): ONE sub-invocation of a stdlib-only
    module that globs the test dirs and reads two small committed files (the
    weights TSV + the allowlist) — NOT a subprocess-per-script and NOT a
    real-tree scan. The heavier assertion is NOT duplicated onto the ~24-spawn
    battery path: this is a single bounded subprocess routed through `run_check`
    (per-check WARN budget catches a regression).

    Lenient: if the shard-plan module is absent, SKIP (the module is the
    BD-219 deliverable; absence at a pre-BD-219 HEAD is not a failure).
    """
    print("\n── Check 60: CI shard partition covers the wired set (BD-219) ──")
    module_path = REPO_ROOT / "scripts" / "lib" / "ci-shard-plan.py"
    if not module_path.is_file():
        ok("scripts/lib/ci-shard-plan.py absent — skipping (lenient)")
        return
    try:
        proc = subprocess.run(
            [sys.executable, str(module_path), "--assert-coverage"],
            capture_output=True, text=True,
        )
    except Exception as exc:  # pragma: no cover - defensive
        fail(f"Check 60 — could not run ci-shard-plan.py --assert-coverage: {exc}")
        return
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout or "").strip()
        fail(
            f"ci-shard-plan.py --assert-coverage FAILED (exit "
            f"{proc.returncode}) — the CI shard partition does NOT cover the "
            f"wired KEEP set exactly. Detail:\n{detail}"
        )
        return
    ok("Check 60 — ci-shard-plan.py --assert-coverage passed; "
       "union(shards) == wired_KEEP_set, pairwise-disjoint, fixture cohesion "
       "group co-located.")


# ── __all__ — every singleton-OWNED symbol the facade / the tests reach ──────
# `from validate_checks.singletons import *` skips underscore names UNLESS they
# are listed here; and once `__all__` is declared it ALSO gates non-underscore
# names — so EVERY singleton check_* (incl. the 2 None-numbered, label-selectable
# checks, and Check 19's named-lambda-resolved function) MUST be enumerated, or
# the facade's `_build_check_registry()` assembly raises NameError. The 17+2
# checks below are the complete owned check surface. The singleton-OWNED
# load-time constants (CODEX_DIR / PACK_SCAN_LOCATIONS / INIT_SCRIPT /
# DETECT_LIB / REQUIRED_DETECT_FUNCTIONS / REQUIRED_BD044_DOCS) are NOT listed —
# no test reaches them on the facade re-export surface, so they stay
# module-internal. The `_build_check_registry` deferred-resolution seam is NOT
# listed — it is facade-INJECTED (the facade is the SSOT for the assembler; it is
# never re-exported FROM singletons). The `from .core` spine (`REPO_ROOT`,
# `README`, `CHECK_REGISTRY_EXPECTED_COUNT`, `OPTIQUITY_BUNDLE_AGENTS_DIR`,
# `fail`, `ok`, `failures`) is NOT re-listed — those are core-owned (the facade
# re-exports them via `from validate_checks.core import *`); `__all__` enumerates
# only singletons's OWN check bodies.
__all__ = [
    "check_codex_toml",                          # Check 2
    "check_td_tbd_sentinels",                    # Check 3
    "check_readme_version",                       # Check 4
    "check_reserved_x_prefix",                    # Check 8
    "check_init_project_structure",              # Check 9
    "check_pack_agent_trinity",                  # Check 11
    "check_tool_config_capability_parity",       # Check 17
    "check_issue_template_forms",                # Check (None)
    "check_template_archive_v11",                # Check (None)
    "check_gitignore_env_example_exception",     # Check 20
    "_CHECK_19_MARKER_SURFACES",                 # Check 19 client-marker admission set (BD-136)
    "check_trinity_no_scaffolding_comments",     # Check 19 (dup-registered lambda)
    "check_customization_detection_regression_guard",  # Check 25
    "check_migrator_framework_inventory",        # Check 26
    "check_ci_workflow_wires_per_check_tests",   # Check 42
    "check_validate_job_carries_no_only_check",  # Check 58
    "check_check_registry_completeness",         # Check 59
    "check_ci_shard_coverage",                   # Check 60
]
