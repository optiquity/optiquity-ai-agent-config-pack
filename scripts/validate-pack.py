#!/usr/bin/env python3
"""
Pack structural validation — runs locally and in GitHub Actions.

Checks:
  1. SKILL.md frontmatter: required fields present in every skill file
  2. Codex TOML files: all parse correctly
  3. TD-TBD sentinels: none in committed files (excluding docs that show the format)
  4. README version table: latest row matches latest git tag
  5. Agent file count: Claude, Codex, and Gemini agent dirs have the same count
  6. Prompts-directory format: per-agent frontmatter, variant→H2 consistency
     (PROMPT-AUTHORING.md was removed in v10.0; directory guidance lives in
     supporting-docs/METHODOLOGY.md § Prompt Authoring Principles)
  7. Pack agent roster: PM-CHAT.md ## Pack agent roster list matches
     .claude/agents/*.md stems
  8. Reserved x- prefix: no file or directory in the seven pack scan
     locations begins with `x-`
  9. Init-project structure: scripts/init-project.sh executable,
     scripts/lib/detect.sh defines the required v10 detection
     functions, QUICKSTART.md and the three supporting-docs setup /
     migration guides exist, and README.md Repository Layout names
     scripts/lib/ and the migration-guide naming convention.
  10. Prompt template triad compliance: every in-scope variant in
      project-template/docs/pack/prompts/*.md (excluding the kickoff
      variant identified by `**Convention exception:**`) contains
      `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and a
      file-based completion-report indicator (`REPORT FILE:` or
      `**Completion report:**`).

Exit 0 if all pass, exit 1 if any fail. Each failure prints the exact
file, line (where applicable), and problem.
"""

import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "project-template" / "skills"
CODEX_DIR = REPO_ROOT / "project-template" / ".codex"
CLAUDE_AGENTS_DIR = REPO_ROOT / "project-template" / ".claude" / "agents"
CODEX_AGENTS_DIR = REPO_ROOT / "project-template" / ".codex" / "agents"
GEMINI_AGENTS_DIR = REPO_ROOT / "project-template" / ".gemini" / "agents"
README = REPO_ROOT / "README.md"

REQUIRED_SKILL_FIELDS = {"name", "description", "allowed-tools"}

PROMPTS_DIR = REPO_ROOT / "project-template" / "docs" / "pack" / "prompts"
REQUIRED_PROMPT_FRONTMATTER = {"agent", "variants"}
RESERVED_PROMPT_FRONTMATTER = {"description", "deprecated-by", "notes"}

PM_CHAT = REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md"
PACK_SCAN_LOCATIONS = [
    REPO_ROOT / "project-template" / ".claude" / "agents",
    REPO_ROOT / "project-template" / ".codex" / "agents",
    REPO_ROOT / "project-template" / ".gemini" / "agents",
    REPO_ROOT / "project-template" / ".claude" / "skills",
    REPO_ROOT / "project-template" / ".codex" / "skills",
    REPO_ROOT / "project-template" / ".gemini" / "skills",
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
    REPO_ROOT / "supporting-docs" / "MIGRATION-v9-to-v10.md",
]

# The pack repo is mostly templates and documentation, where TD-TBD appears
# as a FORMAT EXAMPLE (teaching downstream projects the deferral syntax).
# The only meaningful TD-TBD check in the pack is: does BACKLOG.md have
# any entry where TD-TBD appears where a real BD-NNN number should be?
# The broader "no TD-TBD in committed code" check is for downstream projects.

failures = []


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    failures.append(msg)


def ok(msg: str) -> None:
    print(f"  OK: {msg}")


# ── Check 1: SKILL.md frontmatter ──────────────────────────────────────────

def check_skill_frontmatter() -> None:
    print("\n── Check 1: SKILL.md frontmatter ──")
    skill_dirs = sorted(SKILLS_DIR.iterdir()) if SKILLS_DIR.is_dir() else []
    if not skill_dirs:
        fail("No skill directories found in project-template/skills/")
        return

    for skill_dir in skill_dirs:
        if not skill_dir.is_dir():
            continue
        skill_file = skill_dir / "SKILL.md"
        if not skill_file.exists():
            fail(f"skills/{skill_dir.name}/SKILL.md — file missing")
            continue

        content = skill_file.read_text()
        if not content.startswith("---\n"):
            fail(f"skills/{skill_dir.name}/SKILL.md — no frontmatter (missing opening ---)")
            continue

        match = re.match(r"---\n(.+?)\n---", content, re.DOTALL)
        if not match:
            fail(f"skills/{skill_dir.name}/SKILL.md — malformed frontmatter (no closing ---)")
            continue

        frontmatter = match.group(1)
        fields = set()
        for line in frontmatter.split("\n"):
            if ":" in line:
                key = line.split(":", 1)[0].strip()
                fields.add(key)

        missing = REQUIRED_SKILL_FIELDS - fields
        if missing:
            for field in sorted(missing):
                fail(f"skills/{skill_dir.name}/SKILL.md — missing required field: {field}")
        else:
            ok(f"skills/{skill_dir.name}/SKILL.md")


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
    print("\n── Check 3: TD-TBD sentinels in BACKLOG.md ──")
    backlog = REPO_ROOT / "BACKLOG.md"
    if not backlog.exists():
        ok("No BACKLOG.md found (nothing to check)")
        return

    # Check for TD-TBD in BACKLOG entry identifier lines (e.g., "**TD-TBD — Title**")
    # This catches entries where the PM chat forgot to assign a real BD-NNN number.
    # TD-TBD in descriptive text (e.g., "The coder writes TD-TBD") is expected and excluded.
    content = backlog.read_text()
    found_any = False
    for i, line in enumerate(content.split("\n"), 1):
        # Match entry headers like "**TD-TBD — Some title**"
        if re.match(r"\*\*TD-TBD\s*—", line):
            fail(f"BACKLOG.md:{i} — entry has TD-TBD instead of a real BD-NNN number")
            found_any = True

    if not found_any:
        ok("BACKLOG.md — no unprocessed TD-TBD entry headers")


# ── Check 4: README version table vs git tag ────────────────────────────────

def check_readme_version() -> None:
    print("\n── Check 4: README version table vs git tag ──")
    if not README.exists():
        fail("README.md not found")
        return

    # Find the last table row with a version
    content = README.read_text()
    version_rows = re.findall(r"^\|\s*(v[\d.]+)\s*\|", content, re.MULTILINE)
    if not version_rows:
        fail("README.md — no version table rows found")
        return
    readme_version = version_rows[-1].strip()

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

        # Check if README version matches any tag (handles bare major tags like v8)
        if readme_version in tags:
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


# ── Check 5: Agent file count consistency ───────────────────────────────────

def check_agent_count() -> None:
    print("\n── Check 5: Agent file count consistency ──")
    claude_agents = sorted(CLAUDE_AGENTS_DIR.glob("*.md")) if CLAUDE_AGENTS_DIR.is_dir() else []
    codex_agents = sorted(CODEX_AGENTS_DIR.glob("*.toml")) if CODEX_AGENTS_DIR.is_dir() else []
    gemini_agents = sorted(GEMINI_AGENTS_DIR.glob("*.md")) if GEMINI_AGENTS_DIR.is_dir() else []

    claude_count = len(claude_agents)
    codex_count = len(codex_agents)
    gemini_count = len(gemini_agents)

    if claude_count == 0:
        fail("No Claude agent files found in project-template/.claude/agents/")
    if codex_count == 0:
        fail("No Codex agent files found in project-template/.codex/agents/")
    if gemini_count == 0:
        fail("No Gemini agent files found in project-template/.gemini/agents/")

    if claude_count == codex_count == gemini_count:
        ok(f"Claude agents: {claude_count}, Codex agents: {codex_count}, Gemini agents: {gemini_count} — match")
    else:
        fail(f"Agent count mismatch — Claude: {claude_count}, Codex: {codex_count}, Gemini: {gemini_count}")

    # Also check name correspondence
    claude_names = {p.stem for p in claude_agents}
    codex_names = {p.stem for p in codex_agents}
    gemini_names = {p.stem for p in gemini_agents}
    only_claude = claude_names - codex_names - gemini_names
    only_codex = codex_names - claude_names - gemini_names
    only_gemini = gemini_names - claude_names - codex_names
    missing_from_codex = claude_names - codex_names
    missing_from_gemini = claude_names - gemini_names
    if only_claude:
        fail(f"Agents only in Claude: {sorted(only_claude)}")
    if only_codex:
        fail(f"Agents only in Codex: {sorted(only_codex)}")
    if only_gemini:
        fail(f"Agents only in Gemini: {sorted(only_gemini)}")
    if missing_from_codex:
        fail(f"Agents in Claude but not Codex: {sorted(missing_from_codex)}")
    if missing_from_gemini:
        fail(f"Agents in Claude but not Gemini: {sorted(missing_from_gemini)}")


# ── Check 6: Prompts-directory format ───────────────────────────────────────

def check_prompts_directory() -> None:
    print("\n── Check 6: Prompts-directory format ──")
    if not PROMPTS_DIR.is_dir():
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — directory missing")
        return

    agent_files = sorted(PROMPTS_DIR.glob("*.md"))
    if not agent_files:
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — no per-agent prompt files found")
        return

    for f in agent_files:
        rel = f.relative_to(REPO_ROOT)
        content = f.read_text()

        # Rule 1: frontmatter opener + closer
        if not content.startswith("---\n"):
            fail(f"{rel} — no frontmatter (missing opening ---)")
            continue
        fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
        if not fm_match:
            fail(f"{rel} — malformed frontmatter (no closing ---)")
            continue
        fm = fm_match.group(1)

        # Parse frontmatter: simple line-based.
        # Supports `key: value` on one line and a `variants:` list in either
        # block style (indented `  - slug` lines) or inline `[a, b]` / `[]`.
        agent_value = None
        variants_slugs: list[str] = []
        seen_keys: list[str] = []
        current_list_key = None
        for line in fm.split("\n"):
            if not line.strip():
                current_list_key = None
                continue
            if line.startswith("  - "):
                if current_list_key == "variants":
                    variants_slugs.append(line[4:].strip())
                continue
            if line.startswith(" ") or line.startswith("\t"):
                # unrecognized indented content
                continue
            # top-level key line
            current_list_key = None
            if ":" in line:
                key, _, val = line.partition(":")
                key = key.strip()
                val = val.strip()
                seen_keys.append(key)
                if key == "agent":
                    agent_value = val
                elif key == "variants":
                    if val.startswith("["):
                        inner = val.strip("[]").strip()
                        if inner:
                            variants_slugs = [
                                s.strip().strip('"').strip("'") for s in inner.split(",")
                            ]
                        else:
                            variants_slugs = []
                    else:
                        # block-style list follows on subsequent indented lines
                        current_list_key = "variants"

        # Rule 2: required keys present
        missing = REQUIRED_PROMPT_FRONTMATTER - set(seen_keys)
        if missing:
            for m in sorted(missing):
                fail(f"{rel} — missing required frontmatter key: {m}")
            continue

        # Rule 3: no unknown top-level keys
        allowed = REQUIRED_PROMPT_FRONTMATTER | RESERVED_PROMPT_FRONTMATTER
        unknown = set(seen_keys) - allowed
        if unknown:
            for k in sorted(unknown):
                fail(f"{rel} — unknown frontmatter key: {k}")
            continue

        # Rule 4: stem matches agent: value
        if f.stem != agent_value:
            fail(f"{rel} — file stem '{f.stem}' does not match agent: '{agent_value}'")
            continue

        # Rule 5: variant slug ↔ H2 consistency
        body = content[fm_match.end():]
        h2_slugs = re.findall(r"^## Variant: (\S+)\s*$", body, re.MULTILINE)
        listed = set(variants_slugs)

        orphans = [s for s in h2_slugs if s not in listed]
        if orphans:
            fail(f"{rel} — orphan `## Variant:` H2 not listed in variants: {sorted(set(orphans))}")
            continue

        bad_slug = False
        for s in variants_slugs:
            count = h2_slugs.count(s)
            if count == 0:
                fail(f"{rel} — variant slug '{s}' listed but no matching `## Variant: {s}` H2")
                bad_slug = True
            elif count > 1:
                fail(f"{rel} — variant slug '{s}' has {count} `## Variant: {s}` H2s (expected 1)")
                bad_slug = True
        if bad_slug:
            continue

        ok(f"{rel} — {len(variants_slugs)} variant(s)")


# ── Check 7: Pack agent roster ──────────────────────────────────────────────

def check_pack_agent_roster() -> None:
    print("\n── Check 7: Pack agent roster ──")
    if not PM_CHAT.exists():
        fail(f"{PM_CHAT.relative_to(REPO_ROOT)} — file missing")
        return
    if not CLAUDE_AGENTS_DIR.is_dir():
        fail(f"{CLAUDE_AGENTS_DIR.relative_to(REPO_ROOT)} — directory missing")
        return

    content = PM_CHAT.read_text()

    # Extract bulleted stems between `^## Pack agent roster$` and the next
    # section boundary (next `^## ` H2 or `^---$` separator).
    lines = content.split("\n")
    in_section = False
    roster: list[str] = []
    for line in lines:
        if line.strip() == "## Pack agent roster":
            in_section = True
            continue
        if in_section:
            if line.startswith("## ") or line.strip() == "---":
                break
            if line.startswith("- "):
                roster.append(line[2:].strip())

    if not roster:
        fail(f"{PM_CHAT.relative_to(REPO_ROOT)} — `## Pack agent roster` section missing or empty")
        return

    actual_stems = {p.stem for p in CLAUDE_AGENTS_DIR.glob("*.md")}
    roster_set = set(roster)

    missing_from_roster = actual_stems - roster_set
    missing_from_disk = roster_set - actual_stems

    if missing_from_roster:
        fail(
            f"{PM_CHAT.relative_to(REPO_ROOT)} — agent(s) on disk but missing from "
            f"`## Pack agent roster`: {sorted(missing_from_roster)}"
        )
    if missing_from_disk:
        fail(
            f"{PM_CHAT.relative_to(REPO_ROOT)} — stem(s) in `## Pack agent roster` "
            f"with no matching `.claude/agents/*.md` file: {sorted(missing_from_disk)}"
        )

    if not missing_from_roster and not missing_from_disk:
        ok(f"PM-CHAT.md roster matches .claude/agents/ ({len(roster_set)} stems)")


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

    # (e) BD-059 test-migration harness present (architect Part 6.5).
    test_migration = REPO_ROOT / "scripts" / "test-migration.sh"
    fixtures_dir = REPO_ROOT / "maintenance-docs" / "test-fixtures"
    if not test_migration.exists():
        fail(f"{test_migration.relative_to(REPO_ROOT)} — file missing")
        any_failed = True
    elif not os.access(test_migration, os.X_OK):
        fail(f"{test_migration.relative_to(REPO_ROOT)} — not executable")
        any_failed = True
    else:
        ok(f"{test_migration.relative_to(REPO_ROOT)} — executable")
    if not fixtures_dir.is_dir():
        fail(f"{fixtures_dir.relative_to(REPO_ROOT)} — directory missing")
        any_failed = True
    else:
        # Each of three required fixtures must exist.
        for fixture in ("migration-v9.3-empty", "migration-v9.3-customized", "migration-v9.3-marker-convention"):
            fp = fixtures_dir / fixture
            if not fp.is_dir():
                fail(f"{fp.relative_to(REPO_ROOT)} — fixture directory missing")
                any_failed = True
            else:
                ok(f"{fp.relative_to(REPO_ROOT)} — exists")

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


# ── Check 10: Prompt template triad compliance ────────────────────────────

def check_prompt_triad_compliance() -> None:
    print("\n── Check 10: Prompt template triad compliance ──")
    if not PROMPTS_DIR.is_dir():
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — directory missing")
        return

    agent_files = sorted(PROMPTS_DIR.glob("*.md"))
    if not agent_files:
        fail(f"{PROMPTS_DIR.relative_to(REPO_ROOT)} — no per-agent prompt files found")
        return

    required_labels = ("**Problem:**", "**Goal:**", "**Success criteria:**")
    completion_indicators = ("REPORT FILE:", "**Completion report:**")
    exception_marker = "**Convention exception:**"
    variant_h2 = re.compile(r"^## Variant: (\S+)\s*$", re.MULTILINE)

    for f in agent_files:
        rel = f.relative_to(REPO_ROOT)
        content = f.read_text()

        # Body = text after the closing --- of YAML frontmatter, if present.
        if content.startswith("---\n"):
            fm_match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
            body = content[fm_match.end():] if fm_match else content
        else:
            body = content

        matches = list(variant_h2.finditer(body))
        if not matches:
            ok(f"{rel} — 0 variant(s) (placeholder file)")
            continue

        in_scope_pass = 0
        exempt: list[str] = []
        file_failed = False

        for i, m in enumerate(matches):
            slug = m.group(1)
            start = m.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
            variant_body = body[start:end]

            # Rule N.1 — Kickoff exception detection
            if exception_marker in variant_body:
                exempt.append(slug)
                continue

            # Rule N.2 — Triad presence
            missing_labels = [lbl for lbl in required_labels if lbl not in variant_body]

            # Rule N.3 — File-based completion-report indicator
            has_report_indicator = any(ind in variant_body for ind in completion_indicators)

            if missing_labels or not has_report_indicator:
                missing = list(missing_labels)
                if not has_report_indicator:
                    missing.append("REPORT FILE: or **Completion report:**")
                fail(f"{rel} — Variant: {slug} — missing labeled section(s): {missing}")
                file_failed = True
                continue

            in_scope_pass += 1

        if not file_failed:
            if exempt:
                ok(
                    f"{rel} — {in_scope_pass} variant(s) pass triad+report-file rule "
                    f"({len(exempt)} exempt: {', '.join(exempt)})"
                )
            else:
                ok(f"{rel} — {in_scope_pass} variant(s) pass triad+report-file rule")


def check_pack_agent_trinity() -> None:
    """Check 11 — pack-roster agent trinity-rule symmetry (informational).

    Per BD-059 success criterion #7, every pack-roster agent ships in three
    formats parallel across the three tools (.claude/.md, .codex/.toml,
    .gemini/.md). The trinity rule says behavioral content must match unless
    a divergence is provably tool-specific.

    This check runs scripts/compare-agent-trinity.py --all in lenient mode
    (whitespace + Markdown formatting normalized) and reports the count of
    agents whose body content diverges across the three. The check is
    INFORMATIONAL: it always exits OK with the count. Hard-failure
    enforcement requires a "trinity-asymmetry-by-design" marker convention
    the pack does not yet have. Until then, the count is a regression
    signal — reviewers should question any change that increases it.
    """
    print("\n── Check 11: Pack agent trinity-rule symmetry (informational) ──")
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


def check_three_way_helper_present() -> None:
    """Check 12 — `scripts/lib/three-way.sh` exists, has documented entry,
    and is sourced by `migrate-v9-to-v10.sh` (architect Part 6.1, BD-059).
    """
    print("\n── Check 12: Three-way classifier helper present (BD-059) ──")
    helper = REPO_ROOT / "scripts" / "lib" / "three-way.sh"
    if not helper.is_file():
        fail(f"{helper.relative_to(REPO_ROOT)} — file missing")
        return
    text = helper.read_text()
    if "# ENTRY: three_way_classify" not in text:
        fail(
            f"{helper.relative_to(REPO_ROOT)} — missing "
            "'# ENTRY: three_way_classify' documentation marker"
        )
        return
    migrate = REPO_ROOT / "scripts" / "migrate-v9-to-v10.sh"
    if not migrate.is_file():
        fail("scripts/migrate-v9-to-v10.sh — file missing")
        return
    if "lib/three-way.sh" not in migrate.read_text():
        fail("scripts/migrate-v9-to-v10.sh — does not source scripts/lib/three-way.sh")
        return
    ok(
        f"{helper.relative_to(REPO_ROOT)} — present, documented, "
        "sourced by migrate-v9-to-v10.sh"
    )


def check_merge_helpers_consistent() -> None:
    """Check 13 — every merge helper named in BD-059 exists on disk and is
    invoked by `migrate-v9-to-v10.sh` (architect Part 6.2).

    The four helpers map to the disposition table (architect Part 3):
      merge-trinity.py        — trinity (C1/C2/C3) S5
      merge-platform-skills.py — PLATFORM-SKILLS.md (D2) S5
      merge-json.py            — settings.json (K1), .mcp.json.example (K4) S3
      merge-toml.py            — config.toml (K2), requirements.toml (K3) S3
    """
    print("\n── Check 13: Merge helpers consistent (BD-059) ──")
    migrate = REPO_ROOT / "scripts" / "migrate-v9-to-v10.sh"
    if not migrate.is_file():
        fail("scripts/migrate-v9-to-v10.sh — file missing")
        return
    migrate_text = migrate.read_text()
    helpers = {
        "merge-trinity.py": "trinity (C1/C2/C3) splice in S5",
        "merge-platform-skills.py": "PLATFORM-SKILLS.md splice in S5",
        "merge-json.py": "K1 / K4 JSON merge in S3",
        "merge-toml.py": "K2 / K3 TOML merge in S3",
    }
    any_failed = False
    for name, role in helpers.items():
        helper_path = REPO_ROOT / "scripts" / name
        if not helper_path.is_file():
            fail(f"scripts/{name} — file missing")
            any_failed = True
            continue
        if name not in migrate_text:
            fail(
                f"migrate-v9-to-v10.sh does not invoke scripts/{name} "
                f"(expected for: {role})"
            )
            any_failed = True
    if not any_failed:
        ok("4 merge helpers present and invoked by migrate-v9-to-v10.sh")


def check_disposition_table_documented() -> None:
    """Check 14 — `MIGRATION-v9-to-v10.md` references each migration stage
    S0..S7 (architect Part 6.3 — cross-doc consistency check).
    """
    print("\n── Check 14: Migration disposition documented (BD-059) ──")
    migration_md = REPO_ROOT / "supporting-docs" / "MIGRATION-v9-to-v10.md"
    if not migration_md.is_file():
        fail("supporting-docs/MIGRATION-v9-to-v10.md — file missing")
        return
    text = migration_md.read_text()
    missing = [s for s in ("S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7")
               if f"**{s}**" not in text]
    if missing:
        fail(
            f"MIGRATION-v9-to-v10.md does not reference stages: "
            f"{missing} (expected as `**Sn**` in stage descriptions)"
        )
        return
    ok("MIGRATION-v9-to-v10.md references all 8 stages S0..S7")


def check_migration_test_runs_clean() -> None:
    """Check 15 — `scripts/test-migration.sh --quick` exits zero against
    the empty fixture (architect Part 6.4).

    Runs the empty-fixture path (~5–10s) so CI catches catastrophic
    migration regressions at push time. Full fixture suite is for
    pre-release verification, not every-push CI.
    """
    print("\n── Check 15: Migration test runs clean --quick (BD-059) ──")
    test_script = REPO_ROOT / "scripts" / "test-migration.sh"
    if not test_script.is_file():
        fail("scripts/test-migration.sh — file missing")
        return
    if not os.access(test_script, os.X_OK):
        fail("scripts/test-migration.sh — not executable")
        return
    import subprocess
    try:
        result = subprocess.run(
            ["bash", str(test_script), "--quick"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        fail("test-migration.sh --quick timed out (>120s)")
        return
    if result.returncode != 0:
        fail(f"test-migration.sh --quick exit code {result.returncode}")
        for line in (result.stdout + "\n" + result.stderr).strip().splitlines()[-15:]:
            print(f"    {line}")
        return
    # Extract pass count for the OK line.
    last_line = ""
    for line in result.stdout.splitlines():
        if "passed" in line and "failed" in line:
            last_line = line.strip()
    ok(f"test-migration.sh --quick passed ({last_line or 'see output'})")


def check_trinity_addenda_h2() -> None:
    """Check 16 — v10 trinity templates carry `## Project addenda` H2
    with the HTML-comment placeholder (OQ-P6 / OQ-5C-1, BD-059 C9).

    The H2 is the landing point for project-original sections during
    Procedure 5-C.2 reconciliation. Locking it via this check prevents
    accidental future removal.
    """
    print("\n── Check 16: Trinity ## Project addenda H2 (BD-059) ──")
    any_failed = False
    for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        path = REPO_ROOT / "project-template" / name
        if not path.is_file():
            fail(f"project-template/{name} — file missing")
            any_failed = True
            continue
        text = path.read_text()
        if "## Project addenda" not in text:
            fail(f"project-template/{name} — missing '## Project addenda' H2")
            any_failed = True
            continue
        if "<!-- Project addenda go here" not in text:
            fail(
                f"project-template/{name} — '## Project addenda' H2 present "
                f"but missing HTML-comment placeholder marker"
            )
            any_failed = True
            continue
        ok(f"project-template/{name} — '## Project addenda' H2 with placeholder")
    if any_failed:
        return


# ── Main ────────────────────────────────────────────────────────────────────

def main() -> None:
    print("=" * 60)
    print("Pack Structural Validation")
    print("=" * 60)

    check_skill_frontmatter()
    check_codex_toml()
    check_td_tbd_sentinels()
    check_readme_version()
    check_agent_count()
    check_prompts_directory()
    check_pack_agent_roster()
    check_reserved_x_prefix()
    check_init_project_structure()
    check_prompt_triad_compliance()
    check_pack_agent_trinity()
    check_three_way_helper_present()
    check_merge_helpers_consistent()
    check_disposition_table_documented()
    check_migration_test_runs_clean()
    check_trinity_addenda_h2()

    print("\n" + "=" * 60)
    if failures:
        print(f"FAILED — {len(failures)} issue(s) found")
        sys.exit(1)
    else:
        print("PASSED — all checks clean")
        sys.exit(0)


if __name__ == "__main__":
    main()
