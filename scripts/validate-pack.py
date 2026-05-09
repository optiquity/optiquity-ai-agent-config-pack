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
     functions, QUICKSTART.md and the supporting-docs setup guides
     exist, and README.md Repository Layout names
     scripts/lib/ and the migration-guide naming convention.
     (Checks 12, 13, 14, 15 — the v9-era test-migration
     harness, the migrate-v9-to-v10.sh source/helpers checks, and
     the MIGRATION-v9-to-v10.md stages check — were retired in v11
     with the v9 sunset (BD-121).)
  10. Prompt template triad compliance: every in-scope variant in
      project-template/docs/pack/prompts/*.md (excluding the kickoff
      variant identified by `**Convention exception:**`) contains
      `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and a
      file-based completion-report indicator (`REPORT FILE:` or
      `**Completion report:**`).
  11. Pack agent trinity-rule symmetry (informational): pack-roster
      agent file content stays in lockstep across .claude/.codex/.gemini
      (BD-082-era informational guard).
  16. Trinity ## Project addenda H2 (BD-059): v10 trinity templates
      carry the `## Project addenda` H2 anchor required by Procedure
      5-S Task B.
  17. Tool-config AGENT_CAPABILITIES parity (BD-059): the
      AGENT_CAPABILITIES table is expressed identically in
      `agent-run.sh`, `.codex/config.toml.example`, and
      `.gemini/settings.json`.
  18. Trinity H2 structure parity (BD-059): CLAUDE.md, AGENTS.md, and
      GEMINI.md (project-template) share the same `##` heading
      sequence, modulo provably tool-specific sections.
  19. Trinity templates free of body scaffolding (BD-059): v10 trinity
      templates do not carry stale fresh-install scaffolding
      comments that should have been pruned.
  20. Pack .gitignore !.env.example exception (BD-059): pack-template
      .gitignore retains the `!.env.example` re-include after the
      `*.env*` ignore pattern.
  21. Pack-help per-CLI parity (BD-082): all three CLI surfaces
      (.claude/skills, .codex/skills, .gemini/skills) ship a
      `pack-help` skill that delegates to scripts/pack-help.sh.
  22. Help-fragment freshness (BD-082): every verb that pack prose
      references is present in the HELP-FRAGMENT shared content,
      pack-side and project-template-side.
  23. Help-fragment completeness (BD-082): every non-internal
      executable under `scripts/` is listed in
      `HELP-FRAGMENT-PACK.md` (and pack-internal scripts are marked
      `pack-internal: true`).
  24. HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1): the
      pack-root and project-template HELP-FRAGMENT-TRACKER.md copies
      are byte-identical.
  25. Customization-detection regression guard (BD-089): the
      customization-preserve fixture set produces the expected
      disposition + class for every fixture row, and the truthful
      report contract holds.
  26. BD-119 migrator-framework inventory: scripts/lib/migrator-core.sh
      (when present) is shell-syntax-valid and exposes the documented
      public-API function names + exit-code constants per
      ARCHITECTURE-BD-119.md §3.2 / PLAN-BD-119.md §3.
  27. Agent canonical-phrase compliance (v10.1): every project-template
      agent definition (.claude/.codex/.gemini × 16 agents) contains the
      canonical phrases for Permission profile, Output policy, and
      Hard rules — codified per profile (Read-only / Write-capable
      scoped / Write-capable script).
  28. PM-startup per-CLI parity (v10.1, BD-126): the canonical
      `project-template/skills/pm-startup/SKILL.md` and the three
      per-CLI surfaces (`.claude/skills/`, `.codex/skills/`,
      `.gemini/commands/pm-startup.toml`) agree on Step 4 substance
      (RAG reconciliation procedure) and the Step 6 `RAG:` summary
      template. Prevents v10.1-style backports landing only on the
      canonical SKILL while leaving live per-CLI surfaces stale.
  29. Tracker-config schema (BD-078): the pack-side
      `tracker.toml.pack-example` and the client-side
      `project-template/tracker.toml.project-example` parse as TOML
      and carry the required keys/types per ARCHITECTURE.md §3.1
      (`schema_version`, `[backend].name`, `[mode].state`,
      `[mirror]`, `[id_namespace].prefix`, `[cli_acceleration].prefer`,
      `[migration].forward_complete`, `[migration].reverse_available`,
      `[migration].mapping_file`). Catches schema drift in the
      example files that ship to clients via init-project.sh.
  30. Recommendation-state JSON schema (BD-079): if
      `.pack-tracker/recommendation-state.json` exists at the pack
      root, it parses as JSON and matches the v1 schema documented in
      `scripts/lib/recommendation.sh` (V3 §28.1.4). Soft-passes when
      the file is absent (lazy-create is by design — fresh installs
      never write the file until first persistent-refusal toggle).
      Catches state-file corruption before it causes runtime defaults.

Two additional informational checks (no number, soft / advisory):
  - Issue template forms (BD-063): `.github/ISSUE_TEMPLATE/*.yml`
    forms parse and have the required structural fields per V2
    §4.1 / §4.2 / §4.3, both pack-side and project-template-side.
  - Template archive v11.0 integrity (BD-064; informational):
    `maintenance-docs/v11-research/templates-archive/v11.0/` (when
    present) carries INDEX.md, per-entry-type SCHEMA.md files, and
    archived forms byte-equal to the live `.github/ISSUE_TEMPLATE/`
    copies.

Exit 0 if all pass, exit 1 if any fail. Each failure prints the exact
file, line (where applicable), and problem.
"""

import json
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
    # MIGRATION-v9-to-v10.md removed in v11 with the v9 sunset (BD-121).
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
# (test-migrator-core, test-migrator-manifest,
# test-migrator-behavior-preservation, test-detect).


def check_tool_config_capability_parity() -> None:
    """Check 17 — AGENT_CAPABILITIES expressed identically across the
    three tools' config files (architect Part 6 / OQ-7 / BD-059).

    The trinity rule applies to per-tool tool-level configuration: every
    capability one tool expresses in its config-file surface must be
    expressed by the other two via their own conventions. AGENT_CAPABILITIES
    is the v10 capabilities-pattern roster — shipped in:

      Claude  .claude/settings.json env.AGENT_CAPABILITIES (comma-list)
      Codex   .codex/config.toml [agent_capabilities] enabled (TOML list)
      Gemini  .gemini/.env AGENT_CAPABILITIES (comma-list)

    All three must contain identical capability sets.
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

    # Gemini — .env.example AGENT_CAPABILITIES line. The pack ships
    # the template at `.env.example` (the project-template's .gitignore
    # blocks plain .env to protect against secrets in projects;
    # `.env.example` is committable). init-project.sh creates the live
    # `.gemini/.env` from this template at fresh-install time. The
    # migration scripts (historically migrate-v9-to-v10.sh; today
    # migrate-v10-to-v11.sh) do NOT touch a project's
    # existing `.env` — only `.env.example` is migrated, so the project
    # can manually pick up new pack capabilities by diffing the example.
    gemini_caps: set[str] | None = None
    gemini_path = pt / ".gemini" / ".env.example"
    if not gemini_path.is_file():
        fail(".gemini/.env.example — missing")
        return
    try:
        for line in gemini_path.read_text().splitlines():
            line = line.strip()
            if line.startswith("AGENT_CAPABILITIES="):
                value = line.split("=", 1)[1].strip()
                gemini_caps = {c.strip() for c in value.split(",") if c.strip()}
                break
        if gemini_caps is None:
            fail(".gemini/.env.example — missing AGENT_CAPABILITIES line")
            any_failed = True
    except Exception as e:
        fail(f".gemini/.env.example — parse failed: {e}")
        any_failed = True

    if any_failed or claude_caps is None or codex_caps is None or gemini_caps is None:
        return

    if claude_caps == codex_caps == gemini_caps:
        ok(f"All three tools agree on AGENT_CAPABILITIES ({len(claude_caps)} capabilities)")
        return

    # Surface the divergence.
    if claude_caps != codex_caps:
        only_claude = sorted(claude_caps - codex_caps)
        only_codex = sorted(codex_caps - claude_caps)
        fail(
            f"Claude vs Codex divergent: "
            f"only-Claude={only_claude} only-Codex={only_codex}"
        )
    if claude_caps != gemini_caps:
        only_claude = sorted(claude_caps - gemini_caps)
        only_gemini = sorted(gemini_caps - claude_caps)
        fail(
            f"Claude vs Gemini divergent: "
            f"only-Claude={only_claude} only-Gemini={only_gemini}"
        )


def check_issue_template_forms() -> None:
    """Check (existing series) — `.github/ISSUE_TEMPLATE/*.yml` forms parse and
    have the required structural fields per V2 §4.1 / §4.2 / §4.3 (BD-063).

    Verifies, per surface (pack-root and project-template):
      - work-item.yml, inbound.yml, config.yml all exist and parse as YAML
      - Forms (work-item, inbound) have name/description/labels/body keys
      - work-item.yml's wi-type dropdown has all 4 options
        (bd, td, phase-epic-skeleton, phase-task-skeleton) per V3.3 §6.1
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

    expected_wi_type_options = {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"}
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
                        missing = expected_wi_type_options - opts
                        extra = opts - expected_wi_type_options
                        if missing or extra:
                            fail(
                                f"{label}: work-item.yml — wi-type options mismatch "
                                f"(missing: {sorted(missing) or 'none'}, "
                                f"extra: {sorted(extra) or 'none'})"
                            )
                        else:
                            ok(f"{label}: work-item.yml — 4 wi-type options correct (V3.3 §6.1)")
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
      - All five entry-type subdirectories exist with SCHEMA.md
        (bd, td, phase-epic, phase-task, inbound)
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

    for entry_type in ("bd", "td", "phase-epic", "phase-task", "inbound"):
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

    The pack ships `.gemini/.env.example` (and other `.example` files)
    as committable pack templates. The pack-template `.gitignore` must
    contain `!.env.example` after `.env.*` so fresh installs do not
    silently exclude the pack template. (Historically the v9->v10
    migrator's S0 step also injected this exception into existing
    project .gitignore files; that migrator was retired in v11
    per BD-121.) This check guards the pack-side template against drift.
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


def check_trinity_no_scaffolding_comments() -> None:
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
        comment documenting the Gemini-intrinsic H2s.

    Any other `<!-- ... -->` block in a trinity file is fresh-install
    scaffolding ("Fill in the platform-specific defaults...", "Add
    platform-specific anti-patterns...", etc.). These leak into live
    project files when users pick "keep pack" during reconciliation
    and create persistent clutter. Catch them at validate-pack time.
    """
    print("\n── Check 19: Trinity templates free of body scaffolding (BD-059) ──")
    import re
    ALLOWED_OPENINGS = (
        "HOW TO USE THIS TEMPLATE",
        "Project addenda go here",
        "Trinity-rule exception",
    )
    any_failed = False
    for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        path = REPO_ROOT / "project-template" / name
        if not path.is_file():
            fail(f"project-template/{name} — file missing")
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
                f"project-template/{name}:{line_no} — fresh-install scaffolding "
                f"comment in body: {first_line[:80]!r}"
            )
            any_failed = True
    if not any_failed:
        ok("All three trinity templates free of body-section scaffolding comments")


def check_trinity_h2_parity() -> None:
    """Check 18 — v10 trinity templates have matching H2 structure.

    CLAUDE.md, AGENTS.md, GEMINI.md must agree on H2 names and order.
    The trinity rule applies — symmetry is the default. The only allowed
    asymmetry is tool-intrinsic content. GEMINI.md is permitted to add
    these specific H2s (and only these): `## Agent roster`,
    `## Gemini CLI operating notes`. Any other divergence is a defect.

    Without this check, drift like the v10.0 OT migration discovered
    (CLAUDE 'Platform and stack defaults' vs AGENTS 'Platform defaults'
    etc.) ships unnoticed and breaks Procedure 5-C.2's trinity-rule
    check during migration.
    """
    print("\n── Check 18: Trinity H2 structure parity (BD-059) ──")
    GEMINI_INTRINSIC_H2S = {"## Agent roster", "## Gemini CLI operating notes"}
    files = {
        name: REPO_ROOT / "project-template" / name
        for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md")
    }
    h2_lists = {}
    for name, path in files.items():
        if not path.is_file():
            fail(f"project-template/{name} — file missing")
            return
        h2_lists[name] = [
            line.rstrip()
            for line in path.read_text().splitlines()
            if line.startswith("## ")
        ]

    claude = h2_lists["CLAUDE.md"]
    agents = h2_lists["AGENTS.md"]
    gemini = h2_lists["GEMINI.md"]

    # CLAUDE ↔ AGENTS must be exactly equal (no tool-intrinsic carve-out
    # between these two — Codex and Claude Code see the same content).
    if claude != agents:
        fail(
            "CLAUDE.md ↔ AGENTS.md H2 structure diverges (no tool-intrinsic "
            "carve-out allowed between these two):"
        )
        in_claude = [h for h in claude if h not in agents]
        in_agents = [h for h in agents if h not in claude]
        for h in in_claude:
            fail(f"  in CLAUDE.md only: {h}")
        for h in in_agents:
            fail(f"  in AGENTS.md only: {h}")
        return

    # GEMINI must equal CLAUDE *modulo* the allowed Gemini-intrinsic H2s.
    gemini_filtered = [h for h in gemini if h not in GEMINI_INTRINSIC_H2S]
    if gemini_filtered != claude:
        fail("GEMINI.md H2 structure diverges from CLAUDE.md/AGENTS.md "
             "beyond the allowed Gemini-intrinsic H2s "
             f"({sorted(GEMINI_INTRINSIC_H2S)}):")
        in_claude = [h for h in claude if h not in gemini_filtered]
        in_gemini = [h for h in gemini_filtered if h not in claude]
        for h in in_claude:
            fail(f"  in CLAUDE.md/AGENTS.md only: {h}")
        for h in in_gemini:
            fail(f"  in GEMINI.md only (and not in allowed-intrinsic set): {h}")
        return

    # Check that the Gemini-intrinsic H2s, if present, are positioned
    # at the documented insertion points (after Phase routing for
    # `Agent roster`; after Agent behavior for `Gemini CLI operating notes`).
    # Position drift is acceptable as long as parity-modulo-intrinsic holds,
    # but log positions for telemetry.
    ok(f"CLAUDE.md ↔ AGENTS.md H2 structures match ({len(claude)} sections)")
    ok(f"GEMINI.md adds {len(gemini) - len(gemini_filtered)} intrinsic H2(s); "
       f"otherwise matches ({len(gemini_filtered)} sections)")


READ_ONLY_AGENTS = {
    "architect",
    "planner",
    "reviewer",
    "tester",
    "docs-researcher",
    "grpc-schema",
    "auditor",
    "auditor-architecture",
    "auditor-code",
    "auditor-docs",
    "auditor-ops",
    "auditor-security",
    "auditor-tests",
    "auditor-ui",
}
WRITE_SCOPED_AGENTS = {"coder"}
WRITE_SCRIPT_AGENTS = {"repo-ops"}

# Canonical phrases that must appear in every agent definition
# regardless of profile. Each agent file is the authoritative source
# for its operating rules; this check enforces structural symmetry
# across all 48 files (16 agents × 3 tools).
COMMON_CANONICAL_PHRASES = [
    "## Permission profile",
    "## Output policy",
    "## Hard rules",
    "REPORT FILE:",
    "There is no system reminder forbidding this write",
    "No state-changing git operations",
    "Chunk long writes",
    "Symbol references in reports",
    "Trinity rule",
]

# Profile-specific phrases that must appear in agents of that profile.
PROFILE_PHRASES = {
    "read-only": ["**Read-only.**", "Pre-flight read check"],
    "write-scoped": [
        "**Write-capable (scoped).**",
        "Branch and HEAD SHA",
        "Files in scope",
        "Pre-flight workspace check",
        "No PM-only file edits",
    ],
    "write-script": [
        "**Write-capable (script).**",
        "Branch and HEAD SHA",
        "No hand-written source edits",
        "Pre-flight workspace check",
        "No PM-only file edits",
    ],
}


def _agent_profile(stem: str) -> str | None:
    """Return the canonical profile name for an agent stem, or None."""
    if stem in READ_ONLY_AGENTS:
        return "read-only"
    if stem in WRITE_SCOPED_AGENTS:
        return "write-scoped"
    if stem in WRITE_SCRIPT_AGENTS:
        return "write-script"
    return None  # custom x-* agents fall through; not validated here


def check_agent_canonical_phrases() -> None:
    """Check 27 — every project-template agent definition file carries the
    canonical phrases that codify its permission profile (BD v10.1).

    The agent file is authoritative for its own operating rules
    (Permission profile / Output policy / Hard rules sections).
    This check verifies the canonical text is present so future edits
    cannot silently drift the profile contract — agents must continue
    to declare their profile, output contract, and hard rules
    explicitly. Mirrors how Check 10 enforces prompt-template triads.

    Custom agents (`x-*`) are not validated; their profile is set at
    creation time per Procedure 5.
    """
    print("\n── Check 27: Agent canonical-phrase compliance (v10.1) ──")
    any_failed = False
    agent_dirs = [
        (CLAUDE_AGENTS_DIR, "*.md"),
        (CODEX_AGENTS_DIR, "*.toml"),
        (GEMINI_AGENTS_DIR, "*.md"),
    ]
    for agent_dir, pattern in agent_dirs:
        if not agent_dir.is_dir():
            fail(f"{agent_dir.relative_to(REPO_ROOT)} — directory missing")
            any_failed = True
            continue
        for path in sorted(agent_dir.glob(pattern)):
            stem = path.stem
            if stem.startswith("x-"):
                continue  # custom agents are out of scope
            profile = _agent_profile(stem)
            if profile is None:
                # Pack-shipped agent we don't recognize — flag it.
                fail(
                    f"{path.relative_to(REPO_ROOT)} — agent stem '{stem}' "
                    f"not in any known profile group; update "
                    f"READ_ONLY_AGENTS / WRITE_SCOPED_AGENTS / "
                    f"WRITE_SCRIPT_AGENTS in validate-pack.py"
                )
                any_failed = True
                continue
            text = path.read_text()
            missing = []
            for phrase in COMMON_CANONICAL_PHRASES:
                if phrase not in text:
                    missing.append(phrase)
            for phrase in PROFILE_PHRASES[profile]:
                if phrase not in text:
                    missing.append(phrase)
            if missing:
                rel = path.relative_to(REPO_ROOT)
                fail(
                    f"{rel} — profile '{profile}' missing canonical "
                    f"phrase(s): {missing}"
                )
                any_failed = True
            else:
                ok(
                    f"{path.relative_to(REPO_ROOT)} — profile "
                    f"'{profile}' canonical phrases present"
                )
    if any_failed:
        return


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


def check_pack_help_per_cli_parity() -> None:
    """Check 21 — per-CLI pack-help surface parity (BD-082).

    Per V3 §28.2.5 + DELTA L1, the pack-help verb is exposed via three
    per-CLI surfaces in lockstep:
      - .claude/skills/pack-help/SKILL.md   (Claude skill)
      - .codex/skills/pack-help/SKILL.md    (Codex skill)
      - .gemini/commands/pack-help.toml     (Gemini command)

    Per surface (pack-root + project-template/), all three must exist or
    all three must be absent. All three must reference scripts/pack-help.sh
    so the command actually invokes the pack-help shell.
    """
    print("\n── Check 21: Pack-help per-CLI parity (BD-082) ──")
    surfaces = {
        "pack-root":         REPO_ROOT,
        "project-template":  REPO_ROOT / "project-template",
    }
    triplets = {
        "claude": (".claude/skills/pack-help/SKILL.md",          "skill"),
        "codex":  (".codex/skills/pack-help/SKILL.md",           "skill"),
        "gemini": (".gemini/commands/pack-help.toml",            "command"),
    }
    any_failed = False
    for surface, root in surfaces.items():
        present, absent = [], []
        for cli, (rel, _kind) in triplets.items():
            (present if (root / rel).is_file() else absent).append(cli)
        if present and absent:
            fail(f"{surface}: pack-help parity violated — present in {sorted(present)}, missing in {sorted(absent)}")
            any_failed = True
            continue
        if not present:
            ok(f"{surface}: pack-help absent on all 3 CLIs (consistent — feature not installed)")
            continue
        # All three present — verify each references scripts/pack-help.sh.
        bad = []
        for cli, (rel, _kind) in triplets.items():
            text = (root / rel).read_text()
            if "scripts/pack-help.sh" not in text and "pack-help.sh" not in text:
                bad.append(cli)
        if bad:
            fail(f"{surface}: pack-help present but does not reference scripts/pack-help.sh on {sorted(bad)}")
            any_failed = True
            continue
        ok(f"{surface}: all 3 CLIs present and reference scripts/pack-help.sh")
    if any_failed:
        return


_VERB_RE = re.compile(
    # Match verb invocation shapes; existence-filter applied below to
    # filter project-template-only references and editorial mentions.
    # Allowed shapes:
    #   `pack <subcommand>[ <subcommand>]…`     — shell-verb form
    #   `/pack-<word>`                          — slash-command form
    #   `scripts/<path>.sh|.py`                 — explicit script path
    #   `<name>.sh` / `<name>.py`               — bare script name
    r"`(pack(?:\s\w+)+|/pack-\w+|scripts/[A-Za-z0-9._/-]+\.(?:sh|py)|[A-Za-z0-9][A-Za-z0-9._-]*\.(?:sh|py))`"
)
_PACK_INTERNAL_RE = re.compile(r"^#\s*pack-internal:\s*true\b", re.MULTILINE)


def _is_pack_internal(path: Path) -> bool:
    """Scan the first 2000 bytes of `path` for a `# pack-internal: true`
    marker. Used by Checks 22 and 23 to exempt internal helpers (CI test
    runners, migrator-only merge helpers) from user-facing-fragment rules.
    """
    try:
        head = path.read_text(errors="replace")[:2000]
    except OSError:
        return False
    return bool(_PACK_INTERNAL_RE.search(head))


def check_help_fragment_freshness() -> None:
    """Check 22 — Help-fragment freshness vs prose verb references (BD-082).

    Every verb-shape token (e.g. `pack help`, `/pack-help`, `pack tracker init`,
    `scripts/pack-help.sh`) referenced in the named user-facing docs must
    appear somewhere in the matching HELP-FRAGMENT*.md. Prevents prose
    docs drifting ahead of the help fragment.

    Conservative: only flags verbs that match the regex shape AND are
    absent from the fragment. Editorial mentions of unrelated commands
    are not flagged.
    """
    print("\n── Check 22: Help-fragment freshness (BD-082) ──")
    surfaces = {
        "pack-root": {
            "root": REPO_ROOT,
            "docs": [
                REPO_ROOT / "PACK-CHAT.md",
                REPO_ROOT / "QUICKSTART.md",
                REPO_ROOT / "OPTIONAL-FEATURES.md",
                REPO_ROOT / "supporting-docs" / "INSTALL-PROCEDURES.md",
            ],
            "fragment": REPO_ROOT / "HELP-FRAGMENT-PACK.md",
        },
        "project-template": {
            "root": REPO_ROOT / "project-template",
            "docs": [
                REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md",
            ],
            "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
        },
    }
    tracker_fragment = REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"

    any_failed = False
    for surface, cfg in surfaces.items():
        frag = cfg["fragment"]
        if not frag.is_file():
            fail(f"{surface}: help fragment missing: {frag.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        frag_text = frag.read_text()
        if tracker_fragment.is_file():
            frag_text += "\n" + tracker_fragment.read_text()
        surface_root = cfg["root"]
        verbs_referenced = set()
        for doc in cfg["docs"]:
            if not doc.is_file():
                continue
            for m in _VERB_RE.finditer(doc.read_text()):
                token = m.group(1)
                # Resolve script-shaped references against the surface
                # root so client-doc references resolve against the
                # client (project-template) tree, not the pack root.
                # Bare-name refs (e.g. `init-project.sh`) only count if
                # the file actually exists at scripts/<name> on the
                # surface — filters editorial mentions of names that
                # aren't real scripts on this surface.
                if token.startswith("scripts/"):
                    # Skip library / test directories — those are
                    # implementation details, not user-facing verbs.
                    if (token.startswith("scripts/lib/") or
                            token.startswith("scripts/tests/")):
                        continue
                    script_path = surface_root / token
                    if not script_path.is_file():
                        continue
                    if _is_pack_internal(script_path):
                        continue
                elif token.endswith(".sh") or token.endswith(".py"):
                    if "/" in token:
                        continue
                    script_path = surface_root / "scripts" / token
                    if not script_path.is_file():
                        continue
                    if _is_pack_internal(script_path):
                        continue
                verbs_referenced.add(token)
        missing = sorted(v for v in verbs_referenced if v not in frag_text)
        if missing:
            fail(f"{surface}: verbs referenced in prose but absent from help fragment ({frag.relative_to(REPO_ROOT)}):")
            for v in missing:
                fail(f"  missing: `{v}`")
            any_failed = True
            continue
        ok(f"{surface}: {len(verbs_referenced)} prose-referenced verb(s) all present in fragment")
    if any_failed:
        return


def check_help_fragment_completeness() -> None:
    """Check 23 — Help-fragment completeness vs scripts/ executables (BD-082).

    Every top-level executable script in scripts/ must appear in
    HELP-FRAGMENT-PACK.md unless the script declares `# pack-internal: true`
    near the top. Prevents the fragment going stale as new scripts ship.
    """
    print("\n── Check 23: Help-fragment completeness (BD-082) ──")
    fragment = REPO_ROOT / "HELP-FRAGMENT-PACK.md"
    tracker_fragment = REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"
    if not fragment.is_file():
        fail(f"pack-root help fragment missing: {fragment.name}")
        return
    text = fragment.read_text()
    if tracker_fragment.is_file():
        text += "\n" + tracker_fragment.read_text()

    scripts_dir = REPO_ROOT / "scripts"
    missing = []
    flagged_internal = []
    listed = []
    for entry in sorted(scripts_dir.iterdir()):
        if not entry.is_file():
            continue
        if entry.suffix not in (".sh", ".py"):
            continue
        if not os.access(entry, os.X_OK):
            continue
        # Skip the validate-pack helper itself — it's CI-only.
        if entry.name == "validate-pack.py":
            flagged_internal.append(entry.name)
            continue
        if _is_pack_internal(entry):
            flagged_internal.append(entry.name)
            continue
        if entry.name in text:
            listed.append(entry.name)
        else:
            missing.append(entry.name)
    if missing:
        fail(f"scripts/ executables missing from HELP-FRAGMENT-PACK.md (or mark with `# pack-internal: true`):")
        for n in missing:
            fail(f"  {n}")
        return
    ok(f"all {len(listed)} non-internal scripts/ executables listed in HELP-FRAGMENT-PACK.md "
       f"({len(flagged_internal)} marked pack-internal)")


def check_customization_detection_regression_guard() -> None:
    """Check 25 — Customization-detection regression guard (BD-089).

    Synthetic fixture exercises the BD-088 library against a known v10-
    shape project with realistic customizations. Asserts:
      1. Every customized file produces exactly one finding row.
      2. A trinity file edited by the project surfaces as
         `customization-detected-needs-reconciliation` (not silently merged).
      3. A `.gemini/.env` with project-set keys is preserved
         (BD-059 scenario).
      4. An `x-`-prefixed custom agent surfaces as `project-only-file`.
      5. The truthful-report contract holds — every fixture file appears
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
        # gemini-env with project-set key, x-prefixed custom agent,
        # unchanged-pack file. Capture the dispositions TSV for assertion.
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

# Fixture 2: gemini-env with project-set key (BD-059 scenario).
echo "AGENT_CAPABILITIES=swift,python" > "{tmpdir}/files/env-ours"
echo "AGENT_CAPABILITIES=swift" > "{tmpdir}/files/env-theirs"
cp "{tmpdir}/files/env-ours" "{tmpdir}/files/env-dest"
customization_preserve "" "{tmpdir}/files/env-ours" \\
    "{tmpdir}/files/env-theirs" \\
    ".gemini/.env" "{tmpdir}/files/env-dest" gemini-env >/dev/null

# Fixture 3: x-prefixed custom agent (project-only-file).
echo "x-agent body" > "{tmpdir}/files/x-mine.md"
customization_preserve "" "{tmpdir}/files/x-mine.md" "" \\
    ".claude/agents/x-mine.md" "{tmpdir}/files/x-mine.md" custom-agent >/dev/null

# Fixture 4: unchanged-pack file.
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
        if len(rows) != 4:
            fail(f"expected 4 dispositions for 4-fixture set; got {len(rows)}")
            for r in rows:
                fail(f"  row: {r}")
            return

        # Index by rel_path (column 3) for stable assertion.
        by_rel = {r[2]: r for r in rows}
        expected = {
            "CLAUDE.md": ("customization-detected-needs-reconciliation", "trinity"),
            ".gemini/.env": ("customization-detected-needs-reconciliation", "gemini-env"),
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
        ok("4/4 fixture rows recorded with expected disposition + class")
        ok("truthful-report contract: every fixture file appears in report.md")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def check_help_fragment_tracker_byte_identity() -> None:
    """Check 24 — Shared HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1).

    The tracker fragment is canonical at pack root and mirrored in the
    client template at project-template/docs/pack/. Per DELTA L1 the
    two MUST be byte-identical so install-time copies in BD-080 stage
    S11 produce a faithful client mirror.
    """
    print("\n── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) ──")
    pack_root = REPO_ROOT / "HELP-FRAGMENT-TRACKER.md"
    client    = REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md"
    if not pack_root.is_file():
        fail(f"pack-root canonical missing: {pack_root.name}")
        return
    if not client.is_file():
        fail(f"client mirror missing: project-template/docs/pack/{client.name}")
        return
    if pack_root.read_bytes() != client.read_bytes():
        fail(f"byte-identity violated: {pack_root.relative_to(REPO_ROOT)} != "
             f"{client.relative_to(REPO_ROOT)}")
        return
    ok(f"HELP-FRAGMENT-TRACKER.md byte-identical across pack-root and client mirror")


# ── Check 26: BD-119 migrator-framework inventory ──────────────────────────

def check_migrator_framework_inventory() -> None:
    """Check 26 — BD-119 migrator-framework inventory.

    Asserts, per ARCHITECTURE-BD-119.md §3.2 and PLAN-BD-119.md §3, that
    the three new shared libraries (`migrator-core.sh`,
    `migrator-stages.sh`, `migrator-manifest.sh`) are present and pass
    `bash -n` syntax validation, and that `migrator-core.sh` contains:

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

    if not core.is_file():
        ok("migrator-core.sh not yet present — skipping (lenient pre-C-2)")
        return

    # Strict mode: all three libs must exist and be syntax-valid.
    for lib in (core, stages, manifest):
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
    required_names = [
        "migrator_run",
        "migrator_dispatch",
        "migrator_detect_target_version",
        "migrator_select_adapter",
        "migrator_baseline_to_tmp",
        "migrator_target_surface_for_version",
    ]
    core_text = core.read_text()
    for name in required_names:
        # Match either `name() {` or `function name {` declarations.
        if not re.search(rf'(^|\n)\s*(function\s+)?{re.escape(name)}\s*\(\)\s*\{{',
                         core_text):
            fail(f"migrator-core.sh missing public-API function: {name}()")
            return
    ok(f"migrator-core.sh declares all {len(required_names)} public-API functions")

    # Exit-code constants must be present.
    required_exits = [
        "EXIT_PACK_INVALID",
        "EXIT_NOT_GIT",
        "EXIT_DIRTY",
        "EXIT_NOT_BASELINE",
        "EXIT_BASELINE_MISSING",
        "EXIT_LIB_MISSING",
        "EXIT_ALREADY_MIGRATED",
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


def _extract_pm_startup_sections(text: str) -> tuple[str, str]:
    """Extract (step4_block, step6_rag_line) from a pm-startup prompt body.

    `step4_block` is the prose under the `## Step 4` H2 up to but not
    including the next `## Step` heading (whitespace-trimmed).
    `step6_rag_line` is the line beginning with `**RAG:**` inside Step 6
    (whitespace-trimmed). Returns ("", "") for the line if absent — the
    caller decides whether absence is a failure.
    """
    step4_match = re.search(
        r"^##\s+Step\s+4\b[^\n]*\n(.*?)(?=^##\s+Step\s+\d)",
        text, flags=re.DOTALL | re.MULTILINE,
    )
    step4_block = step4_match.group(1).strip() if step4_match else ""

    rag_match = re.search(r"^\*\*RAG:\*\*[^\n]*", text, flags=re.MULTILINE)
    rag_line = rag_match.group(0).strip() if rag_match else ""

    return step4_block, rag_line


def check_pm_startup_per_cli_parity() -> None:
    """Check 28 — PM-startup per-CLI surface parity (v10.1, BD-126).

    The canonical `project-template/skills/pm-startup/SKILL.md` is the
    source of truth for the Step 4 RAG-reconciliation procedure and the
    Step 6 `RAG:` summary line. Three per-CLI surfaces ship with every
    pack install and must stay byte-substantively aligned with the
    canonical:

      - project-template/.claude/skills/pm-startup/SKILL.md  (Claude skill)
      - project-template/.codex/skills/pm-startup/SKILL.md   (Codex skill)
      - project-template/.gemini/commands/pm-startup.toml    (Gemini command)

    Without this check, v10.1-style RAG backports update the canonical
    only and leave the live surfaces stale (the F-8 BLOCKER pattern
    diagnosed in PACK-REVIEW-V10.1-BACKPORT.md). Gemini is especially
    vulnerable because `init-project.sh` regenerates `.claude` /
    `.codex` SKILL.md from the canonical at install time but never
    touches `.gemini/commands/pm-startup.toml`.

    Comparison rule: extracted Step 4 block AND Step 6 `RAG:` line
    must match the canonical exactly (whitespace-trimmed). For the
    Gemini surface, Step 4 / Step 6 are extracted from the
    triple-quoted `prompt` TOML string before comparison.
    """
    print("\n── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──")
    canonical = REPO_ROOT / "project-template" / "skills" / "pm-startup" / "SKILL.md"
    surfaces = [
        ("claude",
         REPO_ROOT / "project-template" / ".claude" / "skills" / "pm-startup" / "SKILL.md",
         "skill-md"),
        ("codex",
         REPO_ROOT / "project-template" / ".codex" / "skills" / "pm-startup" / "SKILL.md",
         "skill-md"),
        ("gemini",
         REPO_ROOT / "project-template" / ".gemini" / "commands" / "pm-startup.toml",
         "gemini-toml"),
    ]

    if not canonical.is_file():
        fail(f"canonical pm-startup SKILL missing: "
             f"{canonical.relative_to(REPO_ROOT)}")
        return

    canon_text = canonical.read_text()
    canon_step4, canon_rag = _extract_pm_startup_sections(canon_text)
    if not canon_step4:
        fail(f"canonical {canonical.relative_to(REPO_ROOT)} — "
             "Step 4 H2 block not found")
        return
    if not canon_rag:
        fail(f"canonical {canonical.relative_to(REPO_ROOT)} — "
             "Step 6 `**RAG:**` summary line not found")
        return

    any_failed = False
    for cli, path, kind in surfaces:
        if not path.is_file():
            fail(f"{cli}: pm-startup surface missing: "
                 f"{path.relative_to(REPO_ROOT)}")
            any_failed = True
            continue

        if kind == "skill-md":
            body = path.read_text()
        elif kind == "gemini-toml":
            try:
                with open(path, "rb") as f:
                    data = tomllib.load(f)
            except Exception as e:
                fail(f"{cli}: TOML parse error in "
                     f"{path.relative_to(REPO_ROOT)}: {e}")
                any_failed = True
                continue
            body = data.get("prompt", "")
            if not body:
                fail(f"{cli}: {path.relative_to(REPO_ROOT)} has no "
                     f"`prompt` key")
                any_failed = True
                continue
        else:
            fail(f"{cli}: unknown surface kind {kind!r}")
            any_failed = True
            continue

        step4, rag = _extract_pm_startup_sections(body)
        if step4 != canon_step4:
            fail(f"{cli}: {path.relative_to(REPO_ROOT)} — Step 4 "
                 "diverges from canonical "
                 f"{canonical.relative_to(REPO_ROOT)} "
                 "(RAG reconciliation procedure must match exactly)")
            any_failed = True
            continue
        if rag != canon_rag:
            fail(f"{cli}: {path.relative_to(REPO_ROOT)} — Step 6 "
                 "`**RAG:**` summary line diverges from canonical "
                 f"{canonical.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        ok(f"{cli}: {path.relative_to(REPO_ROOT)} — Step 4 + Step 6 "
           "RAG line match canonical")

    if any_failed:
        return


# ── Check 29: Tracker-config schema (BD-078) ────────────────────────────────

# Supported backend names per the example file comments
# ("github" first-class at v11.0; others reserved). Keep in lockstep
# with the comment block in the two example files.
_TRACKER_BACKENDS = ("github", "linear", "jira", "redmine")
_TRACKER_MODES = ("flat-file", "tracker")
_TRACKER_PREFER = ("gh", "mcp", "auto")
_TRACKER_SCHEMA_VERSION = 1


def _validate_tracker_toml(path: Path, expected_prefix: str) -> bool:
    """Validate a single tracker.toml example file.

    Returns True on PASS, False on FAIL. Records each failure via
    `fail()` with file path + key + expected vs actual context so the
    message names exactly what diverges.

    `expected_prefix` is the [id_namespace].prefix value the example
    file is supposed to ship with — "BD" for the pack-side example,
    "TD" for the client-side example.
    """
    rel = path.relative_to(REPO_ROOT)
    if not path.is_file():
        fail(f"{rel} — tracker example file missing")
        return False

    try:
        with open(path, "rb") as f:
            data = tomllib.load(f)
    except Exception as e:
        fail(f"{rel} — TOML parse error: {e}")
        return False

    failed = False

    def _require(key_path, expected_type, container=None):
        nonlocal failed
        cur = data if container is None else container
        for part in key_path.split("."):
            if not isinstance(cur, dict) or part not in cur:
                fail(f"{rel} — missing required key: {key_path}")
                failed = True
                return None
            cur = cur[part]
        if not isinstance(cur, expected_type):
            fail(f"{rel} — key {key_path}: expected "
                 f"{expected_type.__name__}, got {type(cur).__name__}")
            failed = True
            return None
        return cur

    schema_version = _require("schema_version", int)
    if schema_version is not None and schema_version != _TRACKER_SCHEMA_VERSION:
        fail(f"{rel} — schema_version: expected "
             f"{_TRACKER_SCHEMA_VERSION}, got {schema_version}")
        failed = True

    backend_name = _require("backend.name", str)
    if backend_name is not None and backend_name not in _TRACKER_BACKENDS:
        fail(f"{rel} — backend.name: expected one of "
             f"{list(_TRACKER_BACKENDS)}, got {backend_name!r}")
        failed = True

    mode_state = _require("mode.state", str)
    if mode_state is not None and mode_state not in _TRACKER_MODES:
        fail(f"{rel} — mode.state: expected one of "
             f"{list(_TRACKER_MODES)}, got {mode_state!r}")
        failed = True

    # [mirror] table — presence of the table itself, plus the four
    # operational keys init-project / mirror regen rely on.
    mirror = _require("mirror", dict)
    if mirror is not None:
        for k, ty in (
            ("enabled", bool),
            ("location_backlog", str),
            ("location_status", str),
            ("location_changelog", str),
            ("regenerate_on_write", bool),
        ):
            if k not in mirror:
                fail(f"{rel} — missing required key: mirror.{k}")
                failed = True
            elif not isinstance(mirror[k], ty):
                fail(f"{rel} — key mirror.{k}: expected "
                     f"{ty.__name__}, got {type(mirror[k]).__name__}")
                failed = True

    id_prefix = _require("id_namespace.prefix", str)
    if id_prefix is not None and id_prefix != expected_prefix:
        fail(f"{rel} — id_namespace.prefix: expected "
             f"{expected_prefix!r} for this surface, got {id_prefix!r}")
        failed = True

    prefer = _require("cli_acceleration.prefer", str)
    if prefer is not None and prefer not in _TRACKER_PREFER:
        fail(f"{rel} — cli_acceleration.prefer: expected one of "
             f"{list(_TRACKER_PREFER)}, got {prefer!r}")
        failed = True

    fwd = _require("migration.forward_complete", bool)
    rev = _require("migration.reverse_available", bool)
    mapping = _require("migration.mapping_file", str)
    if mapping is not None and not mapping.strip():
        fail(f"{rel} — migration.mapping_file: empty string")
        failed = True
    # Silence unused-binding lint; the _require side effects (fail
    # registration on missing key/wrong type) are the load-bearing
    # behavior here.
    _ = (fwd, rev)

    if not failed:
        ok(f"{rel} — schema OK (prefix={id_prefix!r}, "
           f"backend={backend_name!r}, mode={mode_state!r})")
    return not failed


def check_tracker_config() -> None:
    """Check 29 — tracker.toml example schema (BD-078).

    Both the pack-side `tracker.toml.pack-example` and the client-side
    `project-template/tracker.toml.project-example` must parse as TOML
    and carry the required keys/types per ARCHITECTURE.md §3.1.

    Catches schema drift in the example files that ship to clients
    via `init-project.sh` (per-BD-080 stage S11). If the examples
    fall out of sync with the live `scripts/lib/tracker-config.sh`
    reader expectations, every fresh install propagates the breakage.
    """
    print("\n── Check 29: Tracker-config schema (BD-078) ──")
    pack_example = REPO_ROOT / "tracker.toml.pack-example"
    client_example = REPO_ROOT / "project-template" / "tracker.toml.project-example"

    _validate_tracker_toml(pack_example, expected_prefix="BD")
    _validate_tracker_toml(client_example, expected_prefix="TD")


# ── Check 30: Recommendation-state JSON schema (BD-079) ─────────────────────

# Schema fields per scripts/lib/recommendation.sh:recommendation_state_default()
# (V3 §28.1.4). Tuples are (field, allowed-types). `type(None)` permitted
# for nullable timestamp fields per the default jq builder.
_REC_STATE_SCHEMA = (
    ("schema_version",                (str,)),
    ("surface",                       (str,)),
    ("persistent_refusal",            (bool,)),
    ("persistent_refusal_at",         (str, type(None))),
    ("last_recommendation_shown_at",  (str, type(None))),
    ("last_recommendation_signals",   (dict,)),
    ("user_re_enable_count",          (int,)),
)
_REC_STATE_SCHEMA_VERSION = "v1"
_REC_STATE_SURFACES = ("pack", "client")


def check_recommendation_state_schema() -> None:
    """Check 30 — recommendation-state.json schema (BD-079).

    If `.pack-tracker/recommendation-state.json` exists at the pack
    root, it must parse as JSON and match the v1 schema documented
    in `scripts/lib/recommendation.sh` (V3 §28.1.4).

    Soft-passes when the file is absent — lazy-create is by design,
    so a fresh pack checkout will not have one. The check fires only
    when the file is present, catching state-file corruption before
    `recommendation_state_load()` falls back to defaults at runtime
    (which silently masks the underlying corruption).
    """
    print("\n── Check 30: Recommendation-state JSON schema (BD-079) ──")
    state_file = REPO_ROOT / ".pack-tracker" / "recommendation-state.json"
    if not state_file.is_file():
        ok(".pack-tracker/recommendation-state.json absent — "
           "lazy-create is by design, nothing to validate")
        return

    rel = state_file.relative_to(REPO_ROOT)
    try:
        with open(state_file, "r") as f:
            data = json.load(f)
    except Exception as e:
        fail(f"{rel} — JSON parse error: {e}")
        return

    if not isinstance(data, dict):
        fail(f"{rel} — top-level JSON must be an object, "
             f"got {type(data).__name__}")
        return

    failed = False
    for field, allowed_types in _REC_STATE_SCHEMA:
        if field not in data:
            fail(f"{rel} — missing required field: {field}")
            failed = True
            continue
        value = data[field]
        # bool is a subclass of int in Python; reject bool where int
        # is the only allowed type to catch true/false mistakenly stored
        # as user_re_enable_count.
        if isinstance(value, bool) and bool not in allowed_types:
            fail(f"{rel} — field {field}: expected "
                 f"{[t.__name__ for t in allowed_types]}, got bool")
            failed = True
            continue
        if not isinstance(value, allowed_types):
            type_names = [t.__name__ for t in allowed_types]
            fail(f"{rel} — field {field}: expected one of "
                 f"{type_names}, got {type(value).__name__}")
            failed = True

    sv = data.get("schema_version")
    if isinstance(sv, str) and sv != _REC_STATE_SCHEMA_VERSION:
        fail(f"{rel} — schema_version: expected "
             f"{_REC_STATE_SCHEMA_VERSION!r}, got {sv!r}")
        failed = True

    surface = data.get("surface")
    if isinstance(surface, str) and surface not in _REC_STATE_SURFACES:
        fail(f"{rel} — surface: expected one of "
             f"{list(_REC_STATE_SURFACES)}, got {surface!r}")
        failed = True

    cnt = data.get("user_re_enable_count")
    if isinstance(cnt, int) and not isinstance(cnt, bool) and cnt < 0:
        fail(f"{rel} — user_re_enable_count: must be ≥ 0, got {cnt}")
        failed = True

    if not failed:
        ok(f"{rel} — schema OK (surface={surface!r}, "
           f"schema_version={sv!r})")


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
    # Checks 12, 13, 14, 15 retired in v11 (BD-121, v9 sunset) — see
    # comment block at the function definitions above.
    check_tool_config_capability_parity()
    check_trinity_addenda_h2()
    check_trinity_h2_parity()
    check_trinity_no_scaffolding_comments()
    check_gitignore_env_example_exception()
    check_issue_template_forms()
    check_template_archive_v11()
    check_pack_help_per_cli_parity()
    check_help_fragment_freshness()
    check_help_fragment_completeness()
    check_help_fragment_tracker_byte_identity()
    check_customization_detection_regression_guard()
    check_migrator_framework_inventory()
    check_agent_canonical_phrases()
    check_pm_startup_per_cli_parity()
    check_tracker_config()
    check_recommendation_state_schema()

    print("\n" + "=" * 60)
    if failures:
        print(f"FAILED — {len(failures)} issue(s) found")
        sys.exit(1)
    else:
        print("PASSED — all checks clean")
        sys.exit(0)


if __name__ == "__main__":
    main()
