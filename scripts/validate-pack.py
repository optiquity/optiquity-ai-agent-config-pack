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
      and carry the required keys/types per
      `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1
      (`schema_version`, `[backend].name`, `[backend].repo`, `[mode].state`,
      `[mirror]`, `[id_namespace].prefix`, `[cli_acceleration].prefer`,
      `[migration].forward_complete`, `[migration].reverse_available`,
      `[migration].mapping_file`). Catches schema drift in the
      example files that ship to clients via init-project.sh.
  30. Recommendation-state JSON schema (BD-079): if
      `.pack-tracker/recommendation-state.json` exists at the pack
      root, it parses as JSON and matches the v1 schema documented in
      `scripts/lib/recommendation.sh` (V3 §28.1.4). Soft-passes when
      the file is absent (lazy-create is by design — fresh installs
      never write the file until first recommendation surface or
      persistent-refusal toggle, whichever comes first; see
      `recommendation_record_shown` and
      `recommendation_set_persistent_refusal` in
      `scripts/lib/recommendation.sh`). Catches state-file corruption
      before it causes runtime defaults.
  31. Skill-cell consistency (BD-146, v11 skill-dimensions reframe):
      every SKILL.md on disk under `project-template/skills/<name>/`
      appears in exactly one cell (one row of one Full-skill-inventory
      subsection) of `project-template/docs/pack/PLATFORM-SKILLS.md`,
      and every cell corresponds to a SKILL.md on disk. Catches
      orphan SKILL.md (on disk, missing from inventory), phantom cells
      (in inventory, no SKILL.md on disk), double-counted skills
      (listed in more than one inventory subsection), header drift
      (`### <subsection> (NN)` mismatch), and total drift
      (`**Total skills: NN**` mismatch). Check 27 was extended in the
      same BD to verify each agent's `## Skills to load` prose section
      cites only known skills (skill exists on disk AND is listed in
      PLATFORM-SKILLS.md) — see the in-line `[extension]` block at
      the end of `check_agent_canonical_phrases()`.
  32. Per-entry mirror in-sync (BD-168, v11.0 per-entry split): for each
      pack-side per-entry stream (`backlog/`, `changelog/`), the
      regenerated mirror (`pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`) is byte-
      identical to what the BD-164 mirror generator would produce from
      the on-disk per-entry tree. Pre-checks fold per integration parent
      §10.4: `_rules.md` exists per stream; per-entry filename
      conformance; `_v8-resolved-archive.md` byte-stable (covered by
      the main divergence check). SKIPs when the per-entry tree is
      absent (pre-BD-102 dog-food pack-self / pre-v11.0 client per §10.5).
      Pack-side scope only per §10.6 (project-side trees are validated
      by the client's CI).
  33. Per-entry `_toc.md` in-sync (BD-168, v11.0 per-entry split): for
      each pack-side per-entry stream, the on-disk `_toc.md` is byte-
      identical to what the BD-164 TOC regenerator would produce. Same
      SKIP behavior as Check 32.
  34. Cross-reference integrity (BD-168, v11.0 per-entry split): every
      `BD-NNN`, `TD-NNN`, `vN.M`, `phase-N[.M]` reference inside per-
      entry files resolves to a defined entry ID in the loaded streams
      (filename minus `.md` IS the ID per integration parent §10.3).
      Self-references and references inside `_v8-resolved-archive.md`
      are exempt per §11.3. SKIPs when no per-entry tree exists.
  35. Phase-task lib invariants (BD-106 / V3.3 §3 line 27): renumbered
      from Check 32 in BD-168 to make room for the per-entry split
      validators. `scripts/lib/tracker-phase-task.sh` exists;
      `tracker_labels_folded_into` is NOT defined in
      `scripts/lib/tracker-labels.sh`; the literal `folded-into` does
      NOT appear in executable code under `scripts/lib/`.
  36. Commit-scope honesty (BD-175 M5a per Architect C §8.1): for each
      commit in the walk range (`origin/main..HEAD` with fallbacks),
      parses the commit subject for scope keywords (`pack-only`,
      `project-only`, `PM-only` / `pack-memory-only`) and verifies the
      commit's touched paths match the claimed scope. PM-only PERMITTED-
      PATHS come from `pack-ops/PACK-AGENTS.md` § "PM-only files and
      directories" Files + Directories blocks — notably PERMITS
      `project-template/` trinity per the B1-cascade + S6 fix-pass.
      Implicit-scope commits (no keyword) are skipped — keyword opt-in
      per M1b convention.
  37. Project-side pack-only deny-list (BD-175 M5b per Architect C §8.2):
      walks files under `project-template/` and greps for literal
      references to pack-only files (`PACK-AGENTS.md`, `PACK-CHAT.md`,
      `HELP-FRAGMENT-PACK.md`), pack-only path prefixes
      (`maintenance-docs/`, `pack-ops/`), pack-* agent names, and the
      capitalized `Pack Chat` orchestrator role. Each hit FAILs unless
      the ±2-line context window contains a LEGITIMATE-context anchor
      phrase (`feedback`, `report back`, `escalation`, `stop and surface`
      per audit §D-4; plus pack-vs-project disambiguation anchors
      `in the pack repo`, `at the pack repo`, `pack-repo`, `pack repo only`
      per BD-175 Commit 12 anchor-phrase extension). Self-referential
      legitimate-documentation files (boundary-investigation skill,
      project coder/reviewer prompts, project trinity) are exempt.
  38. Pack-only-file siting (BD-175 M5c per Architect C §8.3): walks
      pack-root top-level prose files (.md / .txt); for each, counts
      pack-only-signal hits (deny-list patterns from Check 37) and
      FAILs files with signal count ≥ 3 unless the file is on the
      exemption list at `pack-ops/.boundary-exempt-root.txt` (1-entry
      post-B-fix per AUDIT-USER-CURATION.md Override 1 + 5 — only
      `tracker.toml.pack-example`) or on the structural-exempt list
      (README.md, QUICKSTART.md, pack-root trinity). Catches pack-only
      content mis-sited outside `pack-ops/`.
  39. cmd_update mapping/glob symmetry (BD-175 F2a per F4 bundle
      reviewer prevention-design feed-in #2; BD-180 reverse-direction
      extension 2026-05-20): bidirectional symmetry between
      `scripts/init-project.sh` `cmd_update` `entries=()` array and
      project-template surface.
      - Forward direction (BD-175 F2a): walks every file under
        `project-template/docs/pack/*.md` (the fresh-install S6 glob
        target) and verifies a corresponding explicit mapping entry
        exists. Catches the BD-175 Commit 10 failure mode
        (`OPTIONAL-FEATURES.md` installed at fresh init but not at
        update). Allowlist `_CHECK_39_EXEMPTIONS` admits files
        intentionally absent from `cmd_update` (default: empty —
        surface-over-silently-exempt).
      - Reverse direction (BD-180 observation E 2026-05-20): every
        `cmd_update` entry's `pack_relpath` must point at a file
        that exists at HEAD. Catches stale mappings whose source
        file was retired (empirical example: pre-BD-180,
        `project-template/docs/pack/PROMPT-TEMPLATES.md` mapped at
        scripts/init-project.sh:1122 referenced a file retired in
        v10.0). Allowlist `_CHECK_39_REVERSE_EXEMPTIONS` admits
        entries whose source intentionally lives outside the repo
        tree (default: empty).
      The check parses the `cmd_update` entries array via regex (does
      not source the shell file).
  41. _CLIENT_INSTALLED_FILES self-documenting list integrity
      (BD-180 observation G per ARCHITECTURE-BD-176.md §5.3): the
      `_CLIENT_INSTALLED_FILES_START` / `_CLIENT_INSTALLED_FILES_END`
      comment block in `scripts/init-project.sh` is an authoritative
      inventory of files install to clients. Check 41 asserts: (a)
      the START/END markers exist exactly once each, (b) the block is
      well-formed (at least one entry line), (c) every entry's
      `pack_relpath` exists at HEAD, and (d) every cmd_update
      `pack_relpath` is listed in the block. Catches drift between
      the self-documenting comment and the actual copy-site state.
      Allowlist `_CHECK_41_EXEMPTIONS` admits inventory entries
      whose source intentionally lives outside repo HEAD (default:
      empty).
  40. pack-ops/ bare cross-reference scanner (BD-179 per
      ARCHITECTURE-BD-179.md §3-§8): walks all `pack-ops/*.md` files
      EXCEPT regenerated mirrors (`pack-ops/BACKLOG.md` /
      `pack-ops/CHANGELOG.md`) and flags backtick-delimited filename
      refs that lack a directory qualifier (`MIGRATION-v10-to-v11.md`
      vs `supporting-docs/MIGRATION-v10-to-v11.md`). Uses regex over a
      code-block-stripped representation of the file (code blocks
      excluded per §3 D2 — shell-CWD-resolved by construction).
      Two-tier exemption per §6 D5: (a) hardcoded `_CHECK_40_ALLOWLIST`
      dict admits pack-root files, trinity members, memory cache, and
      concept-noun / generated-file / placeholder basenames; (b)
      `_CHECK_40_ANCHOR_PHRASES` admit refs whose surrounding ±2-line
      window carries a pack-vs-project disambiguation anchor
      (`in the pack repo`, `post-install`, `does not exist`,
      `archived`, etc.). Failure messages cite file:line + the bare
      basename + candidate-paths suggestion derived from a basename →
      paths index (EXCLUDE `.git/`, `maintenance-docs/archive/`,
      `test-fixtures/`, `scripts/tests/fixtures/`). Bootstrap
      discipline per §8 D7: the BD-179 commit qualifies all
      pre-existing bare refs (51 across 9 files per Phase 1 survey)
      so Check 40 PASSes at HEAD.
  42. CI workflow wires all per-check test files (BD-184): enumerates
      `scripts/tests/test-validate-pack-check*.sh` files on disk and
      verifies every one has a corresponding `bash scripts/tests/<file>`
      invocation in `.github/workflows/validate-pack.yml`. The glob
      `check*` (no trailing dash) catches BOTH single-check filenames
      (`test-validate-pack-check-NN.sh`) AND bundled-check filenames
      (`test-validate-pack-checks-NN-NN-NN.sh`). Closes the "missing
      test wiring" gap class that surfaced 5 times across 3 fix cycles
      in the BD-175 emergency batch. Self-referential closure: this
      check's PASS state depends on its OWN test
      (`test-validate-pack-check-42.sh`) being wired — BD-184 ships
      check + test + wiring together so the closure holds. No
      exemption mechanism: unwired tests must be wired (use
      workflow `if:` gates for intentionally-not-running tests).

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
import tempfile
import tomllib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "project-template" / "skills"

# ── Per-entry tree streams (BD-168 Checks 32 / 33 / 34) ─────────────────────
#
# Each stream tuple: (stream_key, stream_dir_relative, mirror_relative,
# entry_regex). Pack-side scope only per
# ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.6 — `validate-pack.py`
# runs in the pack repo CI; project-side per-entry trees under
# `project-template/docs/project/<stream>/` are pack-shipped canonical
# templates without entries during pack development, so they are NOT
# loaded here. Client projects validate their own per-entry trees
# (the regenerator's idempotency provides the implicit invariant).
#
# Stream keys MUST match the BD-164 helper keys in
# `scripts/lib/per-entry/_lib.sh` (`PE_STREAM_KEYS`); the bash regex
# strings here are mirrored from `pe_entry_regex_for_stream` for the
# Python-side filename conformance pre-check (Check 32 pre-check b).
STREAMS = [
    # (stream_key,        stream_dir_relative,  mirror_relative,                entry_regex)
    ("pack-backlog",      "backlog",            "pack-ops/BACKLOG.md",          r"^BD-\d+\.md$"),
    ("pack-changelog",    "changelog",          "pack-ops/CHANGELOG.md",        r"^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$"),
]
PER_ENTRY_LIB = REPO_ROOT / "scripts" / "lib" / "per-entry"
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
# The only meaningful TD-TBD check in the pack is: does pack-ops/BACKLOG.md have
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
    print("\n── Check 3: TD-TBD sentinels in pack-ops/BACKLOG.md ──")
    backlog = REPO_ROOT / "pack-ops" / "BACKLOG.md"
    if not backlog.exists():
        ok("No pack-ops/BACKLOG.md found (nothing to check)")
        return

    # Check for TD-TBD in BACKLOG entry identifier lines (e.g., "**TD-TBD — Title**")
    # This catches entries where the PM chat forgot to assign a real BD-NNN number.
    # TD-TBD in descriptive text (e.g., "The coder writes TD-TBD") is expected and excluded.
    content = backlog.read_text()
    found_any = False
    for i, line in enumerate(content.split("\n"), 1):
        # Match entry headers like "**TD-TBD — Some title**"
        if re.match(r"\*\*TD-TBD\s*—", line):
            fail(f"pack-ops/BACKLOG.md:{i} — entry has TD-TBD instead of a real BD-NNN number")
            found_any = True

    if not found_any:
        ok("pack-ops/BACKLOG.md — no unprocessed TD-TBD entry headers")


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
# (test-migrator-core, test-migrator-manifest, test-detect).
# Note: test-migrator-behavior-preservation.sh was retired by BD-137
# after the BD-119 refactor it gated shipped clean.


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
      - work-item.yml's wi-type dropdown has the per-surface expected
        options. Pack-side admits `bd` (the pack-development entry
        type); project-side does NOT admit `bd` because BD entries are
        a pack-internal concept and client projects use TD entries.
        Per V3.3 §6.1 + BD-193 boundary cleanup.
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

    # Per-surface expected wi-type options. Pack-side admits `bd` (the
    # pack-development entry type); project-side does NOT — BD entries
    # are pack-internal by construction and client projects use TD.
    expected_wi_type_options_per_surface = {
        "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"},
        "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
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
        comment documenting the Gemini-intrinsic H2s.

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


def check_trinity_h2_parity(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 18 — trinity templates have matching H2 structure at a given location.

    CLAUDE.md, AGENTS.md, GEMINI.md must agree on H2 names and order
    WITHIN their trinity location. The trinity rule applies — symmetry
    is the default. The only allowed asymmetry is tool-intrinsic
    content. GEMINI.md is permitted to add these specific H2s (and only
    these): `## Agent roster`, `## Gemini CLI operating notes`. Any
    other divergence is a defect.

    Without this check, drift like the v10.0 OT migration discovered
    (CLAUDE 'Platform and stack defaults' vs AGENTS 'Platform defaults'
    etc.) ships unnoticed and breaks Procedure 5-C.2's trinity-rule
    check during migration.

    Parameters:
        trinity_root: directory containing the 3 trinity files. Default
            is `REPO_ROOT / "project-template"` (preserves the original
            single-location behavior). Pass `REPO_ROOT` for the pack-root
            trinity location.
        label: human-readable surface name used in FAIL/OK messages and
            file-path prefixes. Examples: `"project-template"`,
            `"pack-root"`.

    Per BD-181 (Override 9 compliance): Each invocation checks byte
    parity WITHIN its own trinity location only. There is NO cross-
    location parity gate — pack-root and project-template trinity carry
    different audiences and different rules by design (per pack-root
    trinity § Rules → Trinity rule note paragraph). Call this function
    once per trinity location; the invocations are independent.
    """
    # Sentinel pattern (BD-181 / BD-183 NIT-1): callers in main() pass
    # explicit (trinity_root, label). `None` default kept for backward-compat
    # with no-arg callers (test suite Group 4 / external use). Do not collapse
    # to a literal default like `trinity_root: Path = REPO_ROOT / "project-template"`
    # — that would WORK for current callers but break the design intent that
    # call sites declare scope explicitly per BD-181 generalization.
    if trinity_root is None:
        trinity_root = REPO_ROOT / "project-template"
    print(f"\n── Check 18 [{label}]: Trinity H2 structure parity (BD-059, BD-181) ──")
    GEMINI_INTRINSIC_H2S = {"## Agent roster", "## Gemini CLI operating notes"}
    files = {
        name: trinity_root / name
        for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md")
    }
    h2_lists = {}
    for name, path in files.items():
        if not path.is_file():
            fail(f"{label}/{name} — file missing")
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
            f"[{label}] CLAUDE.md ↔ AGENTS.md H2 structure diverges "
            "(no tool-intrinsic carve-out allowed between these two):"
        )
        in_claude = [h for h in claude if h not in agents]
        in_agents = [h for h in agents if h not in claude]
        for h in in_claude:
            fail(f"  in {label}/CLAUDE.md only: {h}")
        for h in in_agents:
            fail(f"  in {label}/AGENTS.md only: {h}")
        return

    # GEMINI must equal CLAUDE *modulo* the allowed Gemini-intrinsic H2s.
    gemini_filtered = [h for h in gemini if h not in GEMINI_INTRINSIC_H2S]
    if gemini_filtered != claude:
        fail(
            f"[{label}] GEMINI.md H2 structure diverges from CLAUDE.md/AGENTS.md "
            "beyond the allowed Gemini-intrinsic H2s "
            f"({sorted(GEMINI_INTRINSIC_H2S)}):"
        )
        in_claude = [h for h in claude if h not in gemini_filtered]
        in_gemini = [h for h in gemini_filtered if h not in claude]
        for h in in_claude:
            fail(f"  in {label}/CLAUDE.md/AGENTS.md only: {h}")
        for h in in_gemini:
            fail(f"  in {label}/GEMINI.md only (and not in allowed-intrinsic set): {h}")
        return

    # Check that the Gemini-intrinsic H2s, if present, are positioned
    # at the documented insertion points (after Phase routing for
    # `Agent roster`; after Agent behavior for `Gemini CLI operating notes`).
    # Position drift is acceptable as long as parity-modulo-intrinsic holds,
    # but log positions for telemetry.
    ok(f"[{label}] CLAUDE.md ↔ AGENTS.md H2 structures match ({len(claude)} sections)")
    ok(f"[{label}] GEMINI.md adds {len(gemini) - len(gemini_filtered)} intrinsic H2(s); "
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

    # ── Check 27 extension (BD-146): Skills-to-load conformance ──
    # Per BD-146 Batch 7 of the v11 skill-dimensions reframe, the
    # per-agent "## Skills to load" prose section (currently used by
    # auditor-* subagents) must reference only skills that (a) exist
    # on disk as project-template/skills/<name>/SKILL.md and (b) are
    # known to PLATFORM-SKILLS.md (i.e., not a typo or stale removal).
    # This is the conformance leg of the BD-146 internal-consistency
    # gate; the cell-membership leg is enforced by Check 31.
    print("\n  [extension] Skills-to-load conformance vs PLATFORM-SKILLS (BD-146)")
    disk_skills = set()
    if SKILLS_DIR.is_dir():
        for d in SKILLS_DIR.iterdir():
            if d.is_dir() and (d / "SKILL.md").is_file():
                disk_skills.add(d.name)
    platform_skills_md = (
        REPO_ROOT / "project-template" / "docs" / "pack" / "PLATFORM-SKILLS.md"
    )
    known_skills: set[str] = set()
    if platform_skills_md.is_file():
        ps_text = platform_skills_md.read_text()
        # Any backticked identifier that matches a disk skill is "known."
        # The Full skill inventory tables list every skill in plain | name |
        # cells, so use those as the authoritative set when present.
        for tok in re.findall(r"`([a-z][a-z0-9-]+)`", ps_text):
            if tok in disk_skills:
                known_skills.add(tok)
        # Also harvest plain (non-backticked) skill names that appear as
        # the first column of an inventory table row — robust to either
        # `| name |` or `| `name` |` styles.
        for m in re.finditer(
            r"^\|\s*`?([a-z][a-z0-9-]+)`?\s*\|", ps_text, re.MULTILINE
        ):
            if m.group(1) in disk_skills:
                known_skills.add(m.group(1))
    # Walk every agent file with a "## Skills to load" H2 and validate
    # the backtick-quoted skill identifiers inside that section body.
    for agent_dir, pattern in agent_dirs:
        if not agent_dir.is_dir():
            continue  # already failed above
        for path in sorted(agent_dir.glob(pattern)):
            stem = path.stem
            if stem.startswith("x-"):
                continue
            text = path.read_text()
            section = _extract_skills_to_load_section(text)
            if section is None:
                continue  # agent has no Skills-to-load section (allowed)
            referenced = set(re.findall(r"`([a-z][a-z0-9-]+)`", section))
            file_failed = False
            # Filter to plausible skill names — must be on disk AND known
            # to PLATFORM-SKILLS.md. Skill names never contain underscores
            # (kebab-case convention), so a leading underscore filter
            # excludes detection-helper identifiers like
            # `swiftdata_marker_detected()` automatically.
            for skill in sorted(referenced):
                if "_" in skill:
                    continue  # not a skill identifier
                if skill not in disk_skills:
                    fail(
                        f"{path.relative_to(REPO_ROOT)} — '## Skills to "
                        f"load' references '{skill}' but no SKILL.md "
                        f"exists at project-template/skills/{skill}/"
                    )
                    any_failed = True
                    file_failed = True
                elif skill not in known_skills:
                    fail(
                        f"{path.relative_to(REPO_ROOT)} — '## Skills to "
                        f"load' references '{skill}' but PLATFORM-SKILLS.md "
                        f"does not list it as a known skill"
                    )
                    any_failed = True
                    file_failed = True
            if not file_failed:
                cited = sum(1 for s in referenced if "_" not in s)
                ok(
                    f"{path.relative_to(REPO_ROOT)} — Skills-to-load "
                    f"references conform ({cited} cited)"
                )

    if any_failed:
        return


def _extract_skills_to_load_section(text: str) -> str | None:
    """Return the body text under '## Skills to load' (up to the next
    H2), or None if the section is absent. Used by Check 27 extension."""
    m = re.search(
        r"^##\s+Skills to load\s*\n(.*?)(?=^##\s+|\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    return m.group(1) if m else None


# Surfaces where Check 16 (`## Project addenda` H2 + HTML-comment placeholder
# locking) does NOT apply. The mechanism is template-only infrastructure for
# Procedure 5-C.2 client reconciliation; surfaces that are NOT reconciled to
# client repos (e.g., pack-root trinity) have no `## Project addenda` H2 by
# design and the check short-circuits with an OK (exempt) message. Per
# BD-183 §2.4 Option (b) user-approved 2026-05-21.
_CHECK_16_EXEMPT_SURFACES: set[str] = {"pack-root"}


def check_trinity_addenda_h2(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 16 — v10 trinity templates carry `## Project addenda` H2
    with the HTML-comment placeholder (OQ-P6 / OQ-5C-1, BD-059 C9).

    The H2 is the landing point for project-original sections during
    Procedure 5-C.2 reconciliation. Locking it via this check prevents
    accidental future removal.

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

    Semantic scope (BD-183 §2.4 Option (b) — user-approved 2026-05-21):
    the `## Project addenda` H2 + HTML-comment placeholder marker is
    TEMPLATE-ONLY infrastructure tied to Procedure 5-C.2 reconciliation
    at client install / migration time. Surfaces that are NEVER
    reconciled (e.g., pack-root trinity — canonical ops-doc for
    pack-repo agents) have no `## Project addenda` H2 by design.
    Such surfaces are enumerated in `_CHECK_16_EXEMPT_SURFACES`
    (module-level constant immediately above this function). When the
    `label` parameter matches an exempt surface, this check short-
    circuits with an `OK (surface exempt)` message after printing
    its section header (so CI logs retain a uniform per-check
    structure). See IMPLEMENTATION-REPORT-BD-183.md §2.4 + §3.7 for
    the design record and the triage that landed Option (b).
    """
    # Sentinel pattern: callers in main() pass explicit (trinity_root, label).
    # `None` default kept for backward-compat with no-arg callers (test suite
    # / external use). Do not collapse to a literal default — call sites
    # declare their scope explicitly per BD-183 generalization design.
    if trinity_root is None:
        trinity_root = REPO_ROOT / "project-template"
    print(f"\n── Check 16 [{label}]: Trinity ## Project addenda H2 (BD-059, BD-183) ──")
    # Per-surface exemption (BD-183 §2.4 Option (b)): template-only check
    # short-circuits on surfaces that are NEVER reconciled to client repos.
    # See `_CHECK_16_EXEMPT_SURFACES` definition above for the exempt set.
    if label in _CHECK_16_EXEMPT_SURFACES:
        ok(f"[{label}] surface exempt — Check 16 is template-only "
           f"(`## Project addenda` mechanism has no purpose at non-reconciled "
           f"surface per BD-183 §2.4)")
        return
    any_failed = False
    for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):
        path = trinity_root / name
        if not path.is_file():
            fail(f"{label}/{name} — file missing")
            any_failed = True
            continue
        text = path.read_text()
        if "## Project addenda" not in text:
            fail(f"{label}/{name} — missing '## Project addenda' H2")
            any_failed = True
            continue
        if "<!-- Project addenda go here" not in text:
            fail(
                f"{label}/{name} — '## Project addenda' H2 present "
                f"but missing HTML-comment placeholder marker"
            )
            any_failed = True
            continue
        ok(f"[{label}] {name} — '## Project addenda' H2 with placeholder")
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
                REPO_ROOT / "pack-ops" / "PACK-CHAT.md",
                REPO_ROOT / "QUICKSTART.md",
                REPO_ROOT / "pack-ops" / "OPTIONAL-FEATURES.md",
                REPO_ROOT / "supporting-docs" / "INSTALL-PROCEDURES.md",
            ],
            "fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md",
        },
        "project-template": {
            "root": REPO_ROOT / "project-template",
            "docs": [
                REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md",
            ],
            "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
        },
    }
    tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"

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
    fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"
    tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
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
    pack_root = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
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
        # bool is a subclass of int in Python; reject bool when the
        # caller asked for int (or vice versa) so a stray
        # `schema_version = true` does not slip through. Mirrors
        # Check 30's defensive idiom for `user_re_enable_count`.
        if expected_type is int and isinstance(cur, bool):
            fail(f"{rel} — key {key_path}: expected int, got bool")
            failed = True
            return None
        if expected_type is bool and not isinstance(cur, bool):
            fail(f"{rel} — key {key_path}: expected bool, "
                 f"got {type(cur).__name__}")
            failed = True
            return None
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

    # backend.repo is load-bearing for the github backend (BD-129's
    # tracker_gh_repo_setup() exports it as GH_REPO). Required + non-
    # empty for any github-backed install. We require it for all
    # backends in v11.0 since `github` is the only first-class
    # backend; future backends with no repo concept will need a
    # backend-conditional check here.
    repo_slug = _require("backend.repo", str)
    if repo_slug is not None and not repo_slug.strip():
        fail(f"{rel} — backend.repo: empty string")
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

    # Bare calls: _require's side effect (fail registration on
    # missing/wrong-type) is the load-bearing behavior; no return
    # value needed here.
    _require("migration.forward_complete", bool)
    _require("migration.reverse_available", bool)
    mapping = _require("migration.mapping_file", str)
    if mapping is not None and not mapping.strip():
        fail(f"{rel} — migration.mapping_file: empty string")
        failed = True

    if not failed:
        ok(f"{rel} — schema OK (prefix={id_prefix!r}, "
           f"backend={backend_name!r}, mode={mode_state!r})")
    return not failed


# Pattern for the mirror-header `Last regenerated:` timestamp written
# by scripts/lib/tracker-mirror.sh:tracker_mirror_header_emit. Matches
# ISO 8601 UTC (Z-suffixed) anywhere on a line within the leading
# `<!-- ... -->` HTML-comment block (V1 §A.2 + V1 §6.5 step 8).
_MIRROR_HEADER_TS_RE = re.compile(
    r"Last regenerated:\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)"
)


def _read_mirror_last_regenerated(path: Path) -> "str | None":
    """Return the ISO 8601 `Last regenerated:` timestamp from a mirror
    file's leading HTML-comment header, or None if the file is absent
    / has no header / has no parseable timestamp line. Reads at most
    the first 4 KiB to avoid pulling huge mirrors into memory.
    """
    if not path.is_file():
        return None
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            head = f.read(4096)
    except Exception:
        return None
    m = _MIRROR_HEADER_TS_RE.search(head)
    return m.group(1) if m else None


def _check_mirror_staleness(live_cfg_path: Path) -> None:
    """V1 §A.2 acceptance criterion B — staleness leg.

    When the live tracker.toml has `mode.state == "tracker"` AND
    `migration.forward_complete == true`, walk each configured mirror
    file (`mirror.location_backlog` / `mirror.location_status` /
    `mirror.location_changelog`) and warn (via fail()) if the file's
    `Last regenerated:` header timestamp is older than
    `migration.last_forward_run`. Files with no header / no parseable
    timestamp are warned individually.

    Soft-passes silently when mode is flat-file or forward migration
    has not completed — those modes legitimately leave mirrors stale.
    """
    rel = live_cfg_path.relative_to(REPO_ROOT)
    try:
        with open(live_cfg_path, "rb") as f:
            cfg = tomllib.load(f)
    except Exception as e:
        fail(f"{rel} — TOML parse error: {e}")
        return

    mode_state = cfg.get("mode", {}).get("state")
    if mode_state != "tracker":
        ok(f"{rel} — mode.state={mode_state!r}, mirror-staleness "
           "check N/A (only fires for mode='tracker')")
        return

    migration = cfg.get("migration", {})
    if migration.get("forward_complete") is not True:
        ok(f"{rel} — migration.forward_complete is not true, "
           "mirror-staleness check N/A")
        return

    last_fwd = migration.get("last_forward_run")
    if not isinstance(last_fwd, str) or not last_fwd.strip():
        fail(f"{rel} — mode='tracker' + forward_complete=true but "
             "migration.last_forward_run is missing/empty; cannot "
             "compare mirror timestamps")
        return

    mirror = cfg.get("mirror", {})
    if not isinstance(mirror, dict):
        fail(f"{rel} — [mirror] table missing/malformed; cannot "
             "check mirror-staleness")
        return

    any_stale = False
    for key in ("location_backlog", "location_status", "location_changelog"):
        rel_path = mirror.get(key)
        if not isinstance(rel_path, str) or not rel_path.strip():
            # Schema validation on the example file already gates
            # required mirror keys; skip silently if absent here.
            continue
        mirror_path = REPO_ROOT / rel_path
        mirror_rel = rel_path
        if not mirror_path.is_file():
            fail(f"{rel} — mirror file '{mirror_rel}' "
                 f"(from mirror.{key}) does not exist on disk; "
                 "cannot check Last regenerated header")
            any_stale = True
            continue
        ts = _read_mirror_last_regenerated(mirror_path)
        if ts is None:
            fail(f"{mirror_rel} — no parseable 'Last regenerated:' "
                 "header (from mirror." + key + "); mirror may need "
                 "regeneration")
            any_stale = True
            continue
        # ISO 8601 Z-suffixed UTC sorts lexicographically; no need to
        # parse to datetime. Stale iff header timestamp < last_forward_run.
        if ts < last_fwd:
            fail(f"{mirror_rel} — Last regenerated {ts} is older than "
                 f"migration.last_forward_run {last_fwd}; mirror is "
                 "stale and must be regenerated")
            any_stale = True

    if not any_stale:
        ok(f"{rel} — mirrors are fresh (all 'Last regenerated' >= "
           f"last_forward_run {last_fwd})")


def check_tracker_config() -> None:
    """Check 29 — tracker.toml example schema + mirror staleness (BD-078).

    Both the pack-side `tracker.toml.pack-example` and the client-side
    `project-template/tracker.toml.project-example` must parse as TOML
    and carry the required keys/types per
    `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1.

    Catches schema drift in the example files that ship to clients
    via `init-project.sh` (per-BD-080 stage S11). If the examples
    fall out of sync with the live `scripts/lib/tracker-config.sh`
    reader expectations, every fresh install propagates the breakage.

    In addition (per V1 §A.2 acceptance criterion B), if a live
    `tracker.toml` exists at the pack root with `mode.state = "tracker"`
    AND `migration.forward_complete = true`, warn when any of the
    configured mirror files (`mirror.location_backlog`,
    `mirror.location_status`, `mirror.location_changelog`) carries a
    `Last regenerated:` header timestamp older than
    `migration.last_forward_run`. Soft-passes when no live
    `tracker.toml` is present (lazy-create is by design — fresh
    pack/client checkouts ship the example files only).

    Test-fixture variants under `test-fixtures/v11-*/tracker.toml.example`
    are intentionally NOT validated here: they are pinned migration
    inputs owned by BD-115/116/117 fixtures and may model historical
    schemas for migration-regression coverage. See F6 in
    PACK-REVIEW-BD-078-RETRO.md.
    """
    print("\n── Check 29: Tracker-config schema (BD-078) ──")
    pack_example = REPO_ROOT / "tracker.toml.pack-example"
    client_example = REPO_ROOT / "project-template" / "tracker.toml.project-example"

    _validate_tracker_toml(pack_example, expected_prefix="BD")
    _validate_tracker_toml(client_example, expected_prefix="TD")

    # V1 §A.2 acceptance criterion B — mirror-staleness warning when
    # a live tracker.toml exists, mode is tracker, and forward
    # migration completed. Soft-pass otherwise.
    live_cfg = REPO_ROOT / "tracker.toml"
    if live_cfg.is_file():
        _check_mirror_staleness(live_cfg)
    else:
        ok("tracker.toml absent at pack root — mirror-staleness "
           "leg soft-passes (lazy-create is by design)")


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

    Inner-shape scope (per BD-079 retro F-2 disposition): the
    `last_recommendation_signals` slot is checked for `(dict,)` only
    — keys and value types inside the dict are intentionally not
    validated here. Rationale: V3 §28.1.4 ships the inner-key set as
    a descriptive example (`bd_count_active`, `backlog_kb`) while
    `_rec_compute_pack_signals` and `_rec_compute_client_signals` in
    `scripts/lib/recommendation.sh` emit *different* per-surface key
    sets (pack: bd_count_active / bd_count_total / backlog_kb /
    backlog_growth_30d; client: td_count_active / td_count_total /
    backlog_kb / phase_count / implementation_plan_kb /
    td_tbd_comment_count / typed_deferral_count). The runtime reader
    at `recommendation.sh:360` defaults absent inner keys to 0 via
    `// 0`, and `recommendation_state_default()` emits an empty
    `{}` at fresh-create — so any dict shape is contract-conformant.
    Tightening to a per-surface key/value-type whitelist would be a
    future BD if signal-corruption becomes an empirical failure mode.
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


# ── Check 31: Skill-cell consistency (BD-146, v11) ──────────────────────────

# Subsection headers in the "Full skill inventory" block of
# PLATFORM-SKILLS.md. Each subsection is a markdown table whose first
# column is the skill name. The parenthesized integer in the header is
# the inventory count for that subsection.
_INVENTORY_SUBSECTIONS = [
    "Tier 0 base skills",
    "Dimensional skills",
    "Trigger-loaded skills",
    "PM chat operational skill",
]


def _parse_inventory_subsection(text: str, header: str) -> tuple[int, list[str]]:
    """Parse one '### <header> (NN)' subsection and return
    (declared_count, [skill_names]). The skill name is the first column
    of each table row in the subsection body (up to the next H3 / H2 /
    EOF). Returns (-1, []) if the subsection is absent.
    """
    pat = re.compile(
        rf"^###\s+{re.escape(header)}\s*\((\d+)\)\s*\n(.*?)(?=^###\s+|^##\s+|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    m = pat.search(text)
    if not m:
        return (-1, [])
    declared = int(m.group(1))
    body = m.group(2)
    skills: list[str] = []
    for line in body.split("\n"):
        # Skip header / separator rows. Skill names are kebab-case
        # identifiers in the first table column, optionally backticked.
        if not line.startswith("|"):
            continue
        if re.match(r"^\|\s*-+\s*\|", line):
            continue
        if re.match(r"^\|\s*Skill\s*\|", line):
            continue
        cell_match = re.match(r"^\|\s*`?([a-z][a-z0-9-]+)`?\s*\|", line)
        if cell_match:
            skills.append(cell_match.group(1))
    return (declared, skills)


def check_skill_cell_consistency() -> None:
    """Check 31 — skill-cell consistency vs PLATFORM-SKILLS.md (BD-146).

    Enforces the v11 skill-dimensions reframe internal-consistency
    contract: every SKILL.md on disk under
    `project-template/skills/<name>/` appears in exactly one cell
    (one row of one Full-skill-inventory subsection) of
    `project-template/docs/pack/PLATFORM-SKILLS.md`, and every cell
    in PLATFORM-SKILLS.md corresponds to a SKILL.md on disk.

    Failure modes detected:
      - Orphan SKILL.md  : present on disk, missing from inventory.
      - Phantom cell     : referenced in inventory, no SKILL.md on disk.
      - Double-counted   : same skill listed in more than one inventory
                           subsection (D1-implied skills load via
                           multiple D-table rows but appear in exactly
                           one inventory row — see ARCHITECTURE-SKILL-
                           DIMENSIONS.md §3.7-§3.8).
      - Header drift     : '### <subsection> (NN)' count does not match
                           the row count in that subsection's table.
      - Total drift      : '**Total skills: NN**' line disagrees with
                           the sum across all inventory subsections.

    The Full skill inventory subsections are the authoritative
    canonical-cell source per `maintenance-docs/v11-implementation/
    ARCHITECTURE-SKILL-DIMENSIONS.md` §3 — the dimension tables (D1-D5)
    and intersection table reference loading-mechanism descriptors;
    the inventory rows are the per-skill canonical cell.
    """
    print("\n── Check 31: Skill-cell consistency (BD-146, v11) ──")
    platform_skills_md = (
        REPO_ROOT / "project-template" / "docs" / "pack" / "PLATFORM-SKILLS.md"
    )
    if not platform_skills_md.is_file():
        fail("project-template/docs/pack/PLATFORM-SKILLS.md — file missing")
        return
    if not SKILLS_DIR.is_dir():
        fail("project-template/skills/ — directory missing")
        return

    text = platform_skills_md.read_text()

    # 1. Disk-side: enumerate SKILL.md directories on disk.
    disk_skills: set[str] = set()
    for d in sorted(SKILLS_DIR.iterdir()):
        if d.is_dir() and (d / "SKILL.md").is_file():
            disk_skills.add(d.name)

    # 2. PLATFORM-SKILLS-side: parse each inventory subsection and
    #    collect declared counts + per-subsection skill lists.
    subsection_data: dict[str, tuple[int, list[str]]] = {}
    any_failed = False
    for header in _INVENTORY_SUBSECTIONS:
        declared, skills = _parse_inventory_subsection(text, header)
        if declared == -1:
            fail(
                f"PLATFORM-SKILLS.md — '### {header} (NN)' subsection "
                f"missing or malformed (cannot find header line with "
                f"parenthesized count)"
            )
            any_failed = True
            continue
        subsection_data[header] = (declared, skills)
        actual = len(skills)
        if declared != actual:
            fail(
                f"PLATFORM-SKILLS.md — '### {header} ({declared})' header "
                f"count does not match table row count ({actual})"
            )
            any_failed = True
        else:
            ok(f"PLATFORM-SKILLS.md — '{header}': {declared} rows (header matches)")

    if any_failed:
        # Count drift makes downstream checks unreliable; still run them
        # so the developer sees every issue in one pass, but proceed.
        pass

    # 3. Build canonical cells (skill → list of subsections that hold it).
    cell_membership: dict[str, list[str]] = {}
    for header, (_, skills) in subsection_data.items():
        for s in skills:
            cell_membership.setdefault(s, []).append(header)

    inventory_skills = set(cell_membership.keys())

    # 4. Orphan SKILL.md: on disk, missing from inventory.
    orphans = sorted(disk_skills - inventory_skills)
    for s in orphans:
        fail(
            f"PLATFORM-SKILLS.md — orphan SKILL.md: "
            f"project-template/skills/{s}/SKILL.md exists on disk but is "
            f"not listed in any Full skill inventory subsection"
        )
        any_failed = True

    # 5. Phantom cell: in inventory, no SKILL.md on disk.
    phantoms = sorted(inventory_skills - disk_skills)
    for s in phantoms:
        sections = ", ".join(cell_membership[s])
        fail(
            f"PLATFORM-SKILLS.md — phantom cell: '{s}' listed in "
            f"inventory subsection(s) [{sections}] but no SKILL.md "
            f"exists at project-template/skills/{s}/"
        )
        any_failed = True

    # 6. Double-counted: skill appears in more than one inventory subsection.
    double_counted = sorted(s for s, secs in cell_membership.items() if len(secs) > 1)
    for s in double_counted:
        sections = ", ".join(cell_membership[s])
        fail(
            f"PLATFORM-SKILLS.md — double-counted: '{s}' listed in "
            f"more than one inventory subsection [{sections}] (each "
            f"skill must have exactly one canonical cell per "
            f"ARCHITECTURE-SKILL-DIMENSIONS.md §3)"
        )
        any_failed = True

    # 7. Total skills line consistency.
    total_match = re.search(r"\*\*Total skills:\s*(\d+)\*\*", text)
    declared_total = sum(d for d, _ in subsection_data.values()) if subsection_data else 0
    if total_match:
        stated_total = int(total_match.group(1))
        if stated_total != declared_total:
            fail(
                f"PLATFORM-SKILLS.md — '**Total skills: {stated_total}**' "
                f"disagrees with sum of subsection counts ({declared_total})"
            )
            any_failed = True
        elif stated_total != len(inventory_skills):
            fail(
                f"PLATFORM-SKILLS.md — '**Total skills: {stated_total}**' "
                f"disagrees with unique inventory row count "
                f"({len(inventory_skills)}) — likely a double-counted row"
            )
            any_failed = True
        else:
            ok(
                f"PLATFORM-SKILLS.md — total skills: {stated_total} "
                f"(header sum, inventory row count, and disk count "
                f"all agree)"
            )

    if not any_failed:
        ok(
            f"Skill-cell consistency: {len(disk_skills)} SKILL.md on disk, "
            f"all map to exactly one inventory cell; no orphans, "
            f"phantoms, or double-counts"
        )


# ── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ─────

# Note: an earlier draft of BD-168 defined a `_per_entry_run_helper(helper_func,
# args)` seam intended for shared subprocess invocation. The seam was never
# used — Check 32 inlines its own subprocess.run() to pass the
# PE_FORCE_OVERWRITE_MIRROR env var, and Check 33 also inlines for symmetry.
# The dead-code seam was removed per BD-168 retro fix N1 (favor actual-use
# over speculative-API per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`).


def _list_unknown_files(stream_dir: Path, entry_regex: str,
                        known_supporting: set) -> list:
    """List basenames in `stream_dir` that are neither known supporting
    files (e.g. `_rules.md`, `_intro.md`, `_toc.md`,
    `_v8-resolved-archive.md`, `_format.md`) nor matching the entry
    regex. Used by Check 32 pre-check (b) — non-conforming filenames
    per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.4.
    """
    if not stream_dir.is_dir():
        return []
    pattern = re.compile(entry_regex)
    unknown = []
    for child in sorted(stream_dir.iterdir()):
        if not child.is_file():
            continue
        name = child.name
        if name in known_supporting:
            continue
        if pattern.match(name):
            continue
        unknown.append(name)
    return unknown


def check_mirror_in_sync() -> None:
    """Check 32 — per-entry mirror is in-sync with per-entry tree (BD-168).

    Pseudo-code sketches the behavioral contract; planner refines exact
    implementation (per Addendum #1 §9.2 disclaimer).

    For each pack-side stream in STREAMS:

      - SKIP if the per-entry tree directory is absent (pre-BD-102
        dog-food pack-self / pre-v11.0 client) per
        ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.5.

      - Pre-check (a) per §10.4: `_rules.md` exists per stream; FAIL
        with "missing _rules.md for stream X".

      - Pre-check (b) per §10.4: per-entry filenames conform to the
        stream's regex (e.g., `^BD-\\d+\\.md$` for pack-backlog); FAIL
        with "non-conforming filenames: ..." enumerating offenders.

      - Pre-check (c) per §10.4: `_v8-resolved-archive.md` byte-stable —
        folded into the main divergence check (the v8 archive is part
        of the regenerated mirror's trailing block; if it differs, the
        cmp below catches it).

      - Main check: invoke the BD-164 mirror generator
        (`scripts/lib/per-entry/mirror-generate.sh::per_entry_regenerate_mirror`)
        against the on-disk per-entry tree, redirecting the canonical
        mirror argument to a temp file (the helper short-circuits to
        no-op if the on-disk mirror is byte-identical to what it would
        produce). Diff the temp output against the on-disk mirror; FAIL
        on any difference.

    Failure mode: developer hand-edited the mirror, OR forgot to invoke
    the regenerator before committing.

    Recovery: run the mirror regenerator and re-commit (named in the
    FAIL message).
    """
    print("\n── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──")

    # The set of known supporting basenames the BD-164 helpers may emit
    # per stream. Mirrors `pe_supporting_files_known_for_stream` in
    # `scripts/lib/per-entry/_lib.sh` (kept in lockstep — same hard-
    # coded source-of-truth split per integration parent §7.5).
    known_supporting_for = {
        "pack-backlog":   {"_rules.md", "_intro.md", "_toc.md",
                           "_v8-resolved-archive.md"},
        "pack-changelog": {"_rules.md", "_intro.md", "_toc.md"},
    }

    for stream_key, stream_rel, mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        mirror_path = REPO_ROOT / mirror_rel

        if not stream_dir.is_dir():
            ok(
                f"{stream_rel}/ — not present (skipping; pre-v11.0 "
                f"client or pre-BD-102 dog-food pack-self per integration "
                f"parent §10.5)"
            )
            continue

        # Pre-check (a): _rules.md exists per stream.
        rules_path = stream_dir / "_rules.md"
        if not rules_path.is_file():
            fail(
                f"{stream_rel}/_rules.md missing — required for v11.0 "
                f"per-entry contract (integration parent §10.4 pre-check)"
            )
            continue

        # Pre-check (b): per-entry filenames conform.
        known_supporting = known_supporting_for.get(stream_key, set())
        unknown = _list_unknown_files(stream_dir, entry_regex, known_supporting)
        if unknown:
            fail(
                f"{stream_rel}/: non-conforming filenames: "
                f"{unknown} — entry regex {entry_regex!r}; supporting "
                f"basenames {sorted(known_supporting)}"
            )
            continue

        # Main check: regenerate to a temp file under the same
        # directory as the canonical mirror (the helper requires the
        # mirror dir to exist so it can mktemp there for atomic mv).
        # Use a unique temp filename under REPO_ROOT to keep the
        # comparison byte-stable; clean up on every exit path.
        mirror_dir = mirror_path.parent
        if not mirror_dir.is_dir():
            fail(
                f"{mirror_rel}: parent directory does not exist — "
                f"per-entry tree present but canonical mirror parent "
                f"missing (cannot regenerate)"
            )
            continue

        # Build a temp regenerated copy by point-in-time-snapshotting
        # the on-disk mirror, asking the helper to regenerate the
        # mirror in place (which is a no-op iff in sync), then
        # comparing the post-helper mirror to the snapshot. This
        # avoids redirecting the helper's output (the helper writes
        # its output to <mirror_path>; we want to leave the on-disk
        # mirror untouched for the comparison).
        snap_fd, snap_path = tempfile.mkstemp(
            prefix=".per-entry-snap.", suffix=".md",
            dir=str(mirror_dir),
        )
        try:
            os.close(snap_fd)
            if mirror_path.is_file():
                # Snapshot existing mirror.
                snap_data = mirror_path.read_bytes()
                Path(snap_path).write_bytes(snap_data)
            else:
                # No on-disk mirror at all — divergence with empty.
                fail(
                    f"{mirror_rel}: per-entry tree present at "
                    f"{stream_rel}/ but mirror file absent — run "
                    f"`bash -c '. scripts/lib/per-entry/_lib.sh && "
                    f". scripts/lib/per-entry/mirror-generate.sh && "
                    f"per_entry_regenerate_mirror {stream_key} "
                    f"{stream_dir} {mirror_path}'` to materialize"
                )
                continue

            # Invoke the regenerator. With PE_FORCE_OVERWRITE_MIRROR=1
            # we bypass the divergence prompt + non-zero exit, so the
            # helper either no-ops (in sync) or rewrites the mirror
            # (out of sync). We restore the snapshot before returning
            # in either case.
            #
            # S5 (BD-168 retro fix): the helper's pe_warn
            # "PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited
            # mirror at <path>" (Addendum #2 §4.5 audit-trail) is
            # captured into result.stderr but is INTENTIONALLY silently
            # discarded on the divergence path below — in CI the
            # validator's FAIL message IS the audit trail, so the
            # helper's audit-trail line is redundant; the §4.5
            # audit-trail intent was anchored on the migrator path
            # (where the user runs the helper directly), not the CI
            # path. The discard is documented here so future readers
            # don't add a noisy re-surface accidentally.
            env = os.environ.copy()
            env["PE_FORCE_OVERWRITE_MIRROR"] = "1"
            quoted_args = " ".join(
                f"'{a}'" for a in [stream_key, str(stream_dir), str(mirror_path)]
            )
            script = (
                f". '{PER_ENTRY_LIB}/_lib.sh' && "
                f". '{PER_ENTRY_LIB}/mirror-generate.sh' && "
                f"per_entry_regenerate_mirror {quoted_args}"
            )
            result = subprocess.run(
                ["bash", "-c", script],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
                env=env,
            )
            if result.returncode != 0:
                # Helper failed for a reason other than divergence
                # (we forced through divergence with the env var).
                # Restore snapshot then FAIL with stderr.
                Path(snap_path).replace(mirror_path)
                fail(
                    f"{mirror_rel}: mirror regenerator failed "
                    f"(rc={result.returncode}); stderr: "
                    f"{result.stderr.strip()}"
                )
                continue

            # Compare new on-disk mirror vs. snapshot.
            new_data = mirror_path.read_bytes()
            if new_data == snap_data:
                # In sync — leave on-disk file untouched.
                Path(snap_path).unlink()
                ok(
                    f"{stream_rel}/ → {mirror_rel} byte-identical "
                    f"({len(new_data)} bytes)"
                )
            else:
                # Divergence — RESTORE the snapshot (so the working
                # tree is unchanged) and FAIL.
                Path(snap_path).replace(mirror_path)
                fail(
                    f"{mirror_rel} is out of sync with {stream_rel}/ — "
                    f"re-run `bash -c '. scripts/lib/per-entry/_lib.sh "
                    f"&& . scripts/lib/per-entry/mirror-generate.sh "
                    f"&& PE_FORCE_OVERWRITE_MIRROR=1 "
                    f"per_entry_regenerate_mirror {stream_key} "
                    f"{stream_dir} {mirror_path}'` before committing "
                    f"(the helper is sourced-not-executed; "
                    f"PE_FORCE_OVERWRITE_MIRROR=1 bypasses the "
                    f"divergence abort); restored on-disk mirror to "
                    f"pre-check state"
                )
        finally:
            # Defensive cleanup: if snap_path still exists the path
            # above didn't tidy up.
            if Path(snap_path).exists():
                try:
                    Path(snap_path).unlink()
                except OSError:
                    pass


# ── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ────

def check_toc_in_sync() -> None:
    """Check 33 — per-entry `_toc.md` is in-sync with per-entry tree (BD-168).

    Same SKIP behavior as Check 32 (no per-entry tree → SKIP per
    integration parent §10.5). Invokes the BD-164 TOC regenerator
    against the on-disk tree, snapshotting the on-disk `_toc.md`,
    asking the helper to regenerate in place, then comparing the
    post-helper `_toc.md` to the snapshot. Restore on either path so
    the working tree is unchanged.

    Failure mode: developer hand-edited `_toc.md`, OR forgot to invoke
    the TOC regenerator after editing the per-entry tree.

    Recovery: re-run the TOC regenerator and re-commit.
    """
    print("\n── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──")

    for stream_key, stream_rel, _mirror_rel, _entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel

        if not stream_dir.is_dir():
            ok(
                f"{stream_rel}/ — not present (skipping; pre-v11.0 "
                f"client or pre-BD-102 dog-food pack-self per integration "
                f"parent §10.5)"
            )
            continue

        # If _rules.md absent the stream is malformed; Check 32
        # already FAILed with the same diagnostic — emit a brief skip
        # here so Check 33 doesn't double-fail on the same condition.
        if not (stream_dir / "_rules.md").is_file():
            ok(
                f"{stream_rel}/_toc.md — skipped (Check 32 already "
                f"reported missing _rules.md)"
            )
            continue

        toc_path = stream_dir / "_toc.md"

        # M2 (BD-168 retro fix): create the snap in the system tempdir
        # (`dir=None`), NOT under `stream_dir/`. Rationale: a SIGKILL
        # between mkstemp() and the finally-block cleanup would leave a
        # leftover `.per-entry-toc-snap.XXXXXX.md` inside `stream_dir/`,
        # which Check 32 pre-check (b) (`_list_unknown_files`) would
        # flag as a non-conforming filename on the next CI run. The
        # snap is read-only consumed (no atomic rename across
        # filesystems required), so cross-filesystem placement is fine.
        snap_fd, snap_path = tempfile.mkstemp(
            prefix=".per-entry-toc-snap.", suffix=".md",
            dir=None,
        )
        try:
            os.close(snap_fd)
            had_existing_toc = toc_path.is_file()
            if had_existing_toc:
                snap_data = toc_path.read_bytes()
                Path(snap_path).write_bytes(snap_data)
            else:
                snap_data = None

            quoted_args = " ".join(
                f"'{a}'" for a in [stream_key, str(stream_dir)]
            )
            script = (
                f". '{PER_ENTRY_LIB}/_lib.sh' && "
                f". '{PER_ENTRY_LIB}/toc-regenerate.sh' && "
                f"per_entry_regenerate_toc {quoted_args}"
            )
            # S5 (BD-168 retro fix): any audit-trail stderr the helper
            # emits (Addendum #2 §4.5 anchored on the migrator path) is
            # captured but INTENTIONALLY discarded on the success-with-
            # divergence path below — in CI the validator's FAIL
            # message IS the audit trail. Documented for future readers.
            result = subprocess.run(
                ["bash", "-c", script],
                capture_output=True,
                text=True,
                stdin=subprocess.DEVNULL,
            )
            if result.returncode != 0:
                # Restore on-disk (if any) before failing. Use
                # write_bytes() not replace() so the restore is
                # cross-filesystem safe (the snap may now live in the
                # system tempdir per M2 retro fix; `os.rename` would
                # raise EXDEV if /tmp is on a different FS).
                if had_existing_toc:
                    toc_path.write_bytes(snap_data)
                fail(
                    f"{stream_rel}/_toc.md: regenerator failed "
                    f"(rc={result.returncode}); stderr: "
                    f"{result.stderr.strip()}"
                )
                continue

            new_data = toc_path.read_bytes() if toc_path.is_file() else None
            if had_existing_toc and new_data == snap_data:
                # In sync — leave the file untouched.
                Path(snap_path).unlink()
                ok(
                    f"{stream_rel}/_toc.md byte-identical "
                    f"({len(new_data)} bytes)"
                )
            elif not had_existing_toc and new_data is not None:
                # The on-disk tree had no _toc.md but the regenerator
                # produced one — that itself is a divergence (TOC
                # missing from the committed tree).
                toc_path.unlink()  # restore tree to original (no TOC)
                fail(
                    f"{stream_rel}/_toc.md absent — run "
                    f"`bash -c '. scripts/lib/per-entry/_lib.sh && "
                    f". scripts/lib/per-entry/toc-regenerate.sh && "
                    f"per_entry_regenerate_toc {stream_key} "
                    f"{stream_dir}'` to materialize before committing "
                    f"(the helper is sourced-not-executed); "
                    f"restored tree to pre-check state"
                )
            else:
                # Divergence — restore the snapshot, FAIL. Use
                # write_bytes() not replace() for cross-filesystem
                # safety (snap now lives in system tempdir per M2).
                if had_existing_toc:
                    toc_path.write_bytes(snap_data)
                fail(
                    f"{stream_rel}/_toc.md is out of sync — re-run "
                    f"`bash -c '. scripts/lib/per-entry/_lib.sh && "
                    f". scripts/lib/per-entry/toc-regenerate.sh && "
                    f"per_entry_regenerate_toc {stream_key} "
                    f"{stream_dir}'` before committing (the helper is "
                    f"sourced-not-executed; the regenerator "
                    f"unconditionally overwrites the on-disk file); "
                    f"restored on-disk file to pre-check state"
                )
        finally:
            if Path(snap_path).exists():
                try:
                    Path(snap_path).unlink()
                except OSError:
                    pass


# ── Check 34: cross-reference integrity (BD-168) ───────────────────────────

# Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §11.2, the reference
# regex matches BD-NNN, TD-NNN, vN.M (with optional `-suffix`),
# `phase-N`, and `phase-N.M`. Conservative — false positives in code
# blocks / quoted text are tolerated per §11.2.
CROSS_REF_RE = re.compile(
    r"\b("
    r"BD-\d+"
    r"|TD-\d+"
    r"|phase-\d+(?:\.\d+)?"
    r"|v\d+\.\d+(?:-[a-z0-9-]+)?"
    r")\b"
)


def _collect_defined_ids(stream_key: str, stream_dir: Path,
                         entry_regex: str) -> set:
    """Collect all defined entry IDs for a stream from per-entry filenames.

    For each file in `stream_dir` matching `entry_regex`, emit the ID
    (filename minus `.md`). Per integration parent §10.3 — the
    filename IS the ID.
    """
    if not stream_dir.is_dir():
        return set()
    pattern = re.compile(entry_regex)
    defined = set()
    for child in stream_dir.iterdir():
        if not child.is_file():
            continue
        if not pattern.match(child.name):
            continue
        defined.add(child.name[:-3])  # strip .md
    return defined


def _extract_references(text: str) -> list:
    """Extract (ref, line_no) pairs from `text` matching CROSS_REF_RE.

    Note: the v8-archive SKIP per integration parent §11.3 is enforced
    at the FILE level by the caller (the walk loop in
    `check_cross_reference_integrity` skips `_v8-resolved-archive.md`
    entirely). The earlier draft included a defensive in-text
    `skip_v8_archive` parameter that suppressed references after any
    line matching `^## Resolved — v\\d+\\b`; that parameter was removed
    per BD-168 retro fix N2 because (a) the file-level skip is
    sufficient and (b) the in-text version risked false negatives in
    per-entry pack-changelog files that might legitimately carry a
    `## Resolved — v11.0` H2 in their bodies.
    """
    refs = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        for match in CROSS_REF_RE.finditer(line):
            refs.append((match.group(1), line_no))
    return refs


def check_cross_reference_integrity() -> None:
    """Check 34 — cross-reference integrity (BD-168).

    Pseudo-code sketches the behavioral contract; planner refines exact
    implementation (per Addendum #1 §9.2 disclaimer).

    For each pack-side stream with a per-entry tree present:

      - Collect defined IDs: the filename of every entry file that
        matches the stream's entry regex (filename minus `.md` IS the
        ID per integration parent §10.3).

      - Walk every per-entry file in the stream; extract references
        matching CROSS_REF_RE (`BD-NNN`, `TD-NNN`, `vN.M`,
        `phase-N[.M]`); for each reference, FAIL with the offending
        file + line number + ref if the ref is not in the union of
        defined IDs across all loaded streams.

      - SKIP the `_v8-resolved-archive.md` archive section (per
        integration parent §11.3) — references inside it are
        historical and not subject to integrity validation.

    Cross-stream references are tolerated (a pack BD referencing a
    project TD is out of scope for pack-side validation per §10.6).
    Cross-stream references within the LOADED set (pack-backlog ↔
    pack-changelog) ARE validated since both streams are loaded.

    SKIP gracefully when no per-entry tree exists (per integration
    parent §10.5).
    """
    print("\n── Check 34: cross-reference integrity (BD-168) ──")

    # Build the union of defined IDs across loaded streams.
    defined_by_stream = {}
    any_stream_present = False
    for stream_key, stream_rel, _mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            continue
        any_stream_present = True
        defined_by_stream[stream_key] = _collect_defined_ids(
            stream_key, stream_dir, entry_regex
        )

    if not any_stream_present:
        ok(
            "no per-entry trees present (skipping; pre-v11.0 client or "
            "pre-BD-102 dog-food pack-self per integration parent §10.5)"
        )
        return

    defined_all = set()
    for ids in defined_by_stream.values():
        defined_all |= ids

    # The v8-archive SKIP per §11.3 applies to references INSIDE the
    # `_v8-resolved-archive.md` supporting file (per-stream only;
    # currently lives under pack-backlog).
    v8_archive_basenames = {"_v8-resolved-archive.md"}

    any_dangling = False
    total_files = 0
    total_refs = 0

    for stream_key, stream_rel, _mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            continue

        pattern = re.compile(entry_regex)
        # Walk per-entry files (NOT supporting files like _toc.md /
        # _rules.md / _intro.md — those are not entry content).
        for child in sorted(stream_dir.iterdir()):
            if not child.is_file():
                continue
            if child.name in v8_archive_basenames:
                # SKIP the v8 archive entirely per §11.3.
                continue
            if child.name.startswith("_"):
                # Other supporting files (e.g., _toc.md) — not entry
                # content; out of scope per integration parent §10.3
                # ("Walk every per-entry file").
                continue
            if not pattern.match(child.name):
                # Non-conforming files are reported by Check 32; skip
                # here to avoid double-reporting.
                continue

            total_files += 1
            try:
                text = child.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                fail(
                    f"{child.relative_to(REPO_ROOT)}: unable to read for "
                    f"cross-reference scan"
                )
                any_dangling = True
                continue

            refs = _extract_references(text)
            total_refs += len(refs)
            seen_ids_this_file = set()
            for ref, line_no in refs:
                if ref in defined_all:
                    continue
                # Self-reference (a file referencing its own ID) is
                # always defined — the ID lives in the filename.
                self_id = child.name[:-3]
                if ref == self_id:
                    continue
                # Track distinct dangling refs per file for clearer
                # output (don't flood with one FAIL per repeat).
                key = (ref, line_no)
                if key in seen_ids_this_file:
                    continue
                seen_ids_this_file.add(key)
                fail(
                    f"{child.relative_to(REPO_ROOT)}:{line_no} references "
                    f"{ref} — no matching entry file found in the loaded "
                    f"per-entry streams (defined-IDs scope: pack-backlog + "
                    f"pack-changelog per integration parent §10.6); fix "
                    f"the reference or restore the missing entry"
                )
                any_dangling = True

    if not any_dangling:
        # Suppress the per-stream OK line if no streams had files;
        # the any_stream_present guard above already SKIPed cleanly.
        if total_files > 0:
            ok(
                f"cross-reference integrity: {total_refs} reference(s) "
                f"across {total_files} per-entry file(s); all resolved "
                f"to defined IDs (or self-reference, or v8-archive "
                f"SKIPed per §11.3)"
            )


# ── Check 35: Phase-task lib invariants (BD-106 / V3.3 §3 line 27) ─────────
# (Renumbered from Check 32 in BD-168 to make room for the per-entry
# split validators per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.)

def check_tracker_phase_task_invariants() -> None:
    """Check 35 (renumbered from Check 32 in BD-168) — phase-task lib
    presence + Path-3-forbidden invariant.

    BD-106 lands `scripts/lib/tracker-phase-task.sh` and the V3.3 §3.5
    label family (`derived-from:`, `promoted-to:`). Path 3 is FORBIDDEN
    per V3.3 §3 line 27 — the tracker-labels.sh lib MUST NOT define a
    `tracker_labels_folded_into` constructor, and no script under
    `scripts/lib/` may carry the literal string `folded-into`.

    The runtime negative-test in `test-tracker-phase-task.sh` Test 5.6
    asserts the same invariant at lib-load time; this CI check is the
    static-analysis backstop catching the case where a future
    maintainer adds `tracker_labels_folded_into` to `tracker-labels.sh`
    without re-running the test runner.

    Three asserts:
      1. `scripts/lib/tracker-phase-task.sh` exists.
      2. `tracker_labels_folded_into` is NOT defined in
         `scripts/lib/tracker-labels.sh`.
      3. The literal `folded-into` does NOT appear anywhere in
         `scripts/lib/` (per V3.3 §3 line 27 invariant).
    """
    print("\n── Check 35: Phase-task lib invariants (BD-106) ──")
    lib_dir = REPO_ROOT / "scripts" / "lib"
    phase_task_lib = lib_dir / "tracker-phase-task.sh"
    labels_lib = lib_dir / "tracker-labels.sh"

    if not phase_task_lib.is_file():
        fail(
            f"{phase_task_lib.relative_to(REPO_ROOT)} — file missing "
            f"(BD-106 / V3.3 §2 D-21)"
        )
    else:
        ok(f"{phase_task_lib.relative_to(REPO_ROOT)} present")

    if labels_lib.is_file():
        # Detect a function DEFINITION (not a comment reference). A bash
        # function def matches `<name>()` or `function <name>` at the
        # start of a non-comment line. Comments may legitimately mention
        # the forbidden helper name when documenting the prohibition.
        defines_folded_into = False
        labels_def_lineno = 0
        for lineno, line in enumerate(labels_lib.read_text().splitlines(), start=1):
            stripped = line.lstrip()
            if stripped.startswith("#"):
                continue
            if (
                stripped.startswith("tracker_labels_folded_into(")
                or stripped.startswith("function tracker_labels_folded_into")
            ):
                defines_folded_into = True
                labels_def_lineno = lineno
                break
        if defines_folded_into:
            fail(
                f"{labels_lib.relative_to(REPO_ROOT)}:{labels_def_lineno} "
                f"— defines tracker_labels_folded_into; Path 3 is "
                f"FORBIDDEN per V3.3 §3 line 27"
            )
        else:
            ok(
                f"{labels_lib.relative_to(REPO_ROOT)} — no "
                f"tracker_labels_folded_into helper definition "
                f"(Path 3 forbidden)"
            )
    else:
        fail(f"{labels_lib.relative_to(REPO_ROOT)} — file missing")

    # Invariant 3: no `folded-into` literal in EXECUTABLE code under
    # scripts/lib/. Comments (lines whose first non-whitespace char is
    # `#`) are exempt because the libs explicitly DOCUMENT the
    # forbidden state in their docstrings (e.g. tracker-labels.sh
    # "Path 3 is forbidden by V3.3 §3 line 27 — Helpers below
    # intentionally have no `folded-into` constructor."). The grep is
    # performed in Python to avoid shelling out and to report all
    # offending files in one pass.
    offenders = []
    if lib_dir.is_dir():
        for path in sorted(lib_dir.rglob("*")):
            if not path.is_file():
                continue
            try:
                lines = path.read_text().splitlines()
            except (OSError, UnicodeDecodeError):
                continue
            for lineno, line in enumerate(lines, start=1):
                stripped = line.lstrip()
                if stripped.startswith("#"):
                    continue
                if "folded-into" in line:
                    offenders.append(
                        (path.relative_to(REPO_ROOT), lineno, line.strip())
                    )
    if offenders:
        for off, lineno, snippet in offenders:
            fail(
                f"{off}:{lineno} — contains literal `folded-into` in "
                f"executable code; V3.3 §3 line 27 forbids Path 3 "
                f"anywhere under scripts/lib/. Line: {snippet!r}"
            )
    else:
        ok(
            "scripts/lib/ — no `folded-into` literal in executable "
            "code (V3.3 §3 line 27); comment-only references allowed"
        )


# ── Check 36 / 37 / 38: BD-175 pack/project boundary prevention ────────────
#
# These three checks implement Architect C's M5a/M5b/M5c CI enforcement
# layer per maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §8.
#   - Check 36 (M5a): commit-scope honesty — catches TYPE-1/TYPE-3.
#   - Check 37 (M5b): project-side deny-list — catches TYPE-4.
#   - Check 38 (M5c): pack-only-file siting — catches mis-located content.
#
# The behavior contracts and rationales are documented in the architect
# doc; the comments below explain the concrete code shape only.


# Allowed scope-keyword vocabulary per pack-root trinity §
# "Commit-subject scope-keyword convention" (added by BD-175 Commit 12).
_SCOPE_KEYWORDS_PACK_ONLY = ("pack-only",)
_SCOPE_KEYWORDS_PROJECT_ONLY = ("project-only",)
_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")

# PM-only PERMITTED-PATHS per `pack-ops/PACK-AGENTS.md:142-148` Files block,
# with the post-Architect-B + B-fix path substitution: pack-root operational
# files now live under `pack-ops/`. README.md is permitted in full (the
# version-table-only narrower constraint stays a Pack Chat discipline rule
# per the §8.1a (README.md) note in the architect doc).
_PM_ONLY_PERMITTED_PATHS = {
    "README.md",
    "pack-ops/BACKLOG.md",
    "pack-ops/CHANGELOG.md",
    "pack-ops/PACK-CHAT.md",
    "pack-ops/PACK-AGENTS.md",
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
}

# PM-only PERMITTED-PATH PREFIXES — the per-entry tree directories per
# `pack-ops/PACK-AGENTS.md:150-158` Directories block.
_PM_ONLY_PERMITTED_PREFIXES = (
    "backlog/",
    "changelog/",
    "project-template/docs/project/backlog/",
    "project-template/docs/project/implementation-plan/",
    "project-template/docs/project/changelog/",
)

# `_PROJECT_SIDE_ROOTS` is REPLACED by `_iter_client_installed_files()`.
# See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3 for the contract.
# Reason: the previous constant restricted Check 37 to project-template/
# only, missing scripts/lib/detect.sh (installed verbatim per
# init-project.sh:894-895) and the other 4 client-installed files in
# pack-ops/ + supporting-docs/ + scripts/. The new helper parses the
# authoritative _CLIENT_INSTALLED_FILES inventory and walks the full
# client-installed surface.

# Pack-only path prefixes for scope honesty (Check 36 pack-only check):
# a `pack-only` commit MUST NOT touch any path under these prefixes.
_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")


def _read_boundary_exempt_root() -> set[str]:
    """Parse `pack-ops/.boundary-exempt-root.txt` (1-entry list per
    AUDIT-USER-CURATION.md Overrides 1 + 5 — only `tracker.toml.pack-example`
    post-B-fix). Returns the set of bare filenames permitted at pack root."""
    path = REPO_ROOT / "pack-ops" / ".boundary-exempt-root.txt"
    entries: set[str] = set()
    if not path.is_file():
        return entries
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        entries.add(stripped)
    return entries


def _commits_to_walk() -> list[tuple[str, str]]:
    """Return (sha, subject) pairs for commits to walk under Check 36.

    Range design (per Architect C §8.1 "implementation strategy" + the
    fact that v11-dev has historical commits with imperfect scoping that
    predate BD-175 Commit 12's convention codification):

    - Default: walk ONLY HEAD (the most-recent commit). This is the
      per-push CI gate pattern: enforce the convention on commits added
      in this push; historical commits stay un-audited. The trade-off
      is conservative — Check 36 catches new mis-scoping going forward,
      not historical violations. Historical violations are caught by
      the audit/review process, not the CI gate.

    - Environment override `PACK_CHECK_36_RANGE` may set a wider git
      log range (e.g., `origin/main..HEAD`) for one-shot audit runs.

    Returns (sha, subject) tuples in chronological order (oldest first);
    empty list means nothing to walk (e.g., merge commit with no diff).
    """
    range_spec = os.environ.get("PACK_CHECK_36_RANGE", "HEAD~0..HEAD")
    # `HEAD~0..HEAD` is a no-op range that returns nothing; use `-1`
    # form as the default.
    if range_spec == "HEAD~0..HEAD":
        cmd = ["git", "log", "-1", "--format=%H%x09%s", "HEAD"]
    else:
        cmd = ["git", "log", "--reverse", "--format=%H%x09%s", range_spec]
    try:
        res = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            cwd=str(REPO_ROOT),
        )
    except subprocess.CalledProcessError:
        return []
    out = res.stdout.strip()
    if not out:
        return []
    commits: list[tuple[str, str]] = []
    for line in out.splitlines():
        if "\t" not in line:
            continue
        sha, subject = line.split("\t", 1)
        commits.append((sha, subject))
    return commits


def _commit_paths(sha: str) -> list[str]:
    """Return the list of paths touched by the given commit (relative to
    repo root). Returns empty list on failure."""
    try:
        res = subprocess.run(
            ["git", "show", "--name-only", "--format=", sha],
            check=True,
            capture_output=True,
            text=True,
            cwd=str(REPO_ROOT),
        )
    except subprocess.CalledProcessError:
        return []
    return [line for line in res.stdout.splitlines() if line]


def _subject_has_keyword(subject: str, keywords: tuple[str, ...]) -> bool:
    """Case-insensitive boundary-anchored match of any keyword in the
    commit subject. The keyword must be preceded by start-of-string OR
    a non-keyword-character (whitespace, colon, em-dash, punctuation),
    and followed by a non-keyword-character (whitespace, colon, em-dash,
    punctuation, end-of-string).

    The keyword characters include `[a-z0-9-]`, so a keyword like
    `pack-only` does NOT match inside `pack-only-ish` (the trailing `-`
    is a keyword character, blocking the trailing boundary). This
    avoids spurious matches on prose words that happen to contain the
    keyword as a prefix or suffix.
    """
    subject_lower = subject.lower()
    # Boundary class: chars that are NOT part of a scope-keyword token
    # (whitespace, colon, em-dash, comma, period, semicolon, paren).
    # `-` is NOT in the boundary class because `-` appears INSIDE the
    # keywords (pack-only, project-only, etc.).
    boundary_class = r"[\s:—,.;()\[\]]"
    for kw in keywords:
        if kw not in subject_lower:
            continue
        pattern = (
            r"(^|" + boundary_class + r")"
            + re.escape(kw)
            + r"($|" + boundary_class + r")"
        )
        if re.search(pattern, subject_lower):
            return True
    return False


def _is_pack_only_path(path: str) -> bool:
    """A path is pack-only if it is NOT under any project-side prefix."""
    for prefix in _PROJECT_SIDE_PATH_PREFIXES:
        if path.startswith(prefix):
            return False
    return True


def _is_project_side_path(path: str) -> bool:
    """A path is project-side if it lives under one of the project-side
    path prefixes."""
    return path.startswith(_PROJECT_SIDE_PATH_PREFIXES)


def _is_pm_only_permitted(path: str) -> bool:
    """A path is PM-only-permitted if it appears in the canonical Files
    list OR under one of the canonical PM-only directory prefixes."""
    if path in _PM_ONLY_PERMITTED_PATHS:
        return True
    return path.startswith(_PM_ONLY_PERMITTED_PREFIXES)


def check_commit_scope_honesty() -> None:
    """Check 36 — commit-scope honesty (BD-175 M5a per Architect C §8.1).

    For every commit in the walk range, parse the commit subject for scope
    keywords (`pack-only`, `project-only`, `PM-only` / `pack-memory-only`)
    and verify the commit's touched paths match the claimed scope.

    Failure modes:
      - Subject claims `pack-only` but commit touches `project-template/`
        or `supporting-docs/`.
      - Subject claims `project-only` but commit touches paths outside
        `project-template/` + `supporting-docs/`.
      - Subject claims `PM-only` / `pack-memory-only` but commit touches
        any path NOT in the PM-only permitted-paths list (per
        `pack-ops/PACK-AGENTS.md` § "PM-only files and directories" + the
        per-entry directory block).

    Implicit-scope commits (no keyword) are skipped — keyword opt-in per
    M1b convention.
    """
    print("\n── Check 36: Commit-scope honesty (BD-175, M5a) ──")
    commits = _commits_to_walk()
    if not commits:
        ok("Check 36 — no commits in walk range; nothing to verify")
        return

    any_failed = False
    checked = 0
    skipped = 0
    for sha, subject in commits:
        is_pack_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PACK_ONLY)
        is_project_only = _subject_has_keyword(
            subject, _SCOPE_KEYWORDS_PROJECT_ONLY
        )
        is_pm_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PM_ONLY)
        if not (is_pack_only or is_project_only or is_pm_only):
            skipped += 1
            continue
        paths = _commit_paths(sha)
        if not paths:
            # Merge commit or empty diff — skip.
            skipped += 1
            continue
        checked += 1
        short_sha = sha[:7]
        offenders: list[str] = []
        if is_pack_only:
            offenders = [p for p in paths if _is_project_side_path(p)]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `pack-only` "
                    f"but touches project-side paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_project_only:
            offenders = [p for p in paths if not _is_project_side_path(p)]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `project-only` "
                    f"but touches pack-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_pm_only:
            offenders = [p for p in paths if not _is_pm_only_permitted(p)]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `PM-only` but "
                    f"touches non-PM-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                    + " (PM-only permitted set per pack-ops/PACK-AGENTS.md "
                    "§ 'PM-only files and directories')"
                )
                any_failed = True

    if not any_failed:
        ok(
            f"Check 36 — {checked} scope-claiming commit(s) verified clean; "
            f"{skipped} implicit-scope commit(s) skipped"
        )


# Check 37 deny-list — pack-only patterns that MUST NOT appear in
# project-side files (per Architect C §8.2 deny-list, with §16.1
# `pack-ops/` path-prefix addition and §16a HELP-FRAGMENT-TRACKER row
# clarification). Each entry: (literal-pattern, why) — the literal
# pattern is a substring grep target. The exception is by anchor-phrase
# in the surrounding context window (see _DENY_LIST_ANCHOR_PHRASES).
_DENY_LIST_FILENAMES = (
    ("PACK-AGENTS.md", "Pack-repo only"),
    ("PACK-CHAT.md", "Pack-repo only"),
    ("HELP-FRAGMENT-PACK.md", "Pack-repo only"),
)

# Path prefixes that name pack-only directories. Each match flags as
# contamination unless an anchor-phrase exception is found in the
# context window.
_DENY_LIST_PATH_PREFIXES = (
    ("maintenance-docs/", "Pack-only; not installed"),
    ("pack-ops/", "Pack-only top-level dir (relocated PACK × OPERATIONS files)"),
)

# Pack-* agent names (word-boundary-anchored).
_DENY_LIST_AGENT_NAMES = (
    "pack-architect",
    "pack-coder",
    "pack-planner",
    "pack-reviewer",
    "pack-docs-researcher",
)

# Capitalized `Pack Chat` orchestrator role. Audit §D-4 LEGITIMATE exception
# is by anchor-phrase context window.
_DENY_LIST_ROLE_NAME = "Pack Chat"

# Anchor phrases that, when found within the per-pattern context window
# (matched line + N lines before + N lines after), mark the match as
# LEGITIMATE per audit §D-4 (feedback-flow / escalation-path context, or
# pack-vs-project disambiguation context — the latter per BD-175 Commit
# 12 anchor-phrase extension to handle pack-repo disambiguation patterns
# like "in the pack repo" on HELP-FRAGMENT-TRACKER.md:49).
_DENY_LIST_ANCHOR_PHRASES = (
    "feedback",
    "report back",
    "escalation",
    "stop and surface",
    # Pack-vs-project disambiguation context. These mark a deliberate
    # callout that a named entity lives at the pack repo (not at the
    # client install) — e.g., "tracker.toml.pack-example in the pack
    # repo, or tracker.toml.example at a client project root".
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "pack repo only",
)

_DENY_LIST_ANCHOR_WINDOW = 2  # lines before/after the match


def _context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any of the anchor phrases appears in the
    `lineno` line (1-indexed) or in the ±N surrounding lines."""
    start = max(0, lineno - 1 - _DENY_LIST_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _DENY_LIST_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _DENY_LIST_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False


def _iter_client_installed_files() -> list[Path]:
    """Return the union of:
      (a) all regular files under project-template/ (recursive), and
      (b) the explicit non-project-template files in _CLIENT_INSTALLED_FILES.

    This replaces _PROJECT_SIDE_ROOTS-based walks for Checks 37 + 43.
    The source-of-truth for (b) is _CLIENT_INSTALLED_FILES_START/_END
    in scripts/init-project.sh, parsed via Check 41's
    _parse_client_installed_files() helper.

    Returns repo-relative Path objects, sorted, deduplicated. Skips
    binary files (deferred to caller via UnicodeDecodeError handling).

    Contract: see `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
    §3.1 for the verbatim function body + §3.2 for the rationale
    (replaces `_PROJECT_SIDE_ROOTS` constant; reuses the authoritative
    `_CLIENT_INSTALLED_FILES_START`/`_END` inventory in
    `scripts/init-project.sh` per BD-180 G).
    """
    out: list[Path] = []
    # (a) project-template/ recursive walk (existing behavior).
    root = REPO_ROOT / "project-template"
    if root.is_dir():
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            out.append(path.relative_to(REPO_ROOT))
    # (b) explicit non-project-template entries from _CLIENT_INSTALLED_FILES.
    entries, _, _, _, _ = _parse_client_installed_files()
    for entry in entries:
        if entry.startswith("project-template/"):
            continue  # already covered by (a)
        full = REPO_ROOT / entry
        if full.is_file():
            rel = full.relative_to(REPO_ROOT)
            if rel not in out:  # dedup defensive (project-template/ first)
                out.append(rel)
    return out


def _iter_project_side_files() -> list[Path]:
    """Thin alias delegating to `_iter_client_installed_files()`.

    DEPRECATED: kept as an alias so the Check 37 call-site
    (`check_project_side_deny_list`) does not need to change. Future
    cleanup may inline the delegation. See ARCHITECTURE-V11-GUARDRAILS-
    CONTRACT.md §3.2 for the migration plan.
    """
    return _iter_client_installed_files()


# Per-line fence allowlist for Check 37 (Guardrail 2 — BD-173 H.13).
# Replaces the legacy `_is_legitimate_deny_list_doc()` whole-file
# exemption. Files on this list MAY contain deny-list patterns INSIDE
# paired `<!-- DENY-LIST-CONTENT-START -->` / `<!-- DENY-LIST-CONTENT-END -->`
# fence markers; outside the fence, normal Check 37 rules apply.
#
# Constant shape: tuple of repo-relative path strings (POSIX form).
# Membership test is exact-string match via `_has_per_line_fence`.
#
# Contract: see `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
# §2.3 (constant) and §2.4 (fence-placement plan per file). The 4
# dual-surface entries (METHODOLOGY.md, INSTALL-PROCEDURES.md,
# detect.sh, pack-help.sh) were added 2026-05-24 per the H.12/H.13
# reorder — see `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`
# for the STOP-AND-ESCALATE evidence that drove the expansion.
_CHECK_37_PER_LINE_FENCE_FILES = (
    # Original 7 entries (project-template/ trinity + prompts + skill + PM-CHAT.md):
    "project-template/skills/boundary-investigation/SKILL.md",
    "project-template/docs/pack/PM-CHAT.md",
    "project-template/docs/pack/prompts/coder.md",
    "project-template/docs/pack/prompts/reviewer.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
    # 4 dual-surface additions (added 2026-05-24 per H.12/H.13 reorder).
    # These files carry LEGITIMATE pack-internal references in functional
    # dual-surface code (scripts/) or pedagogical role-name content
    # (supporting-docs/) that the fence covers without breaking script
    # semantics or doc explanatory purpose.
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    "scripts/lib/detect.sh",
    "scripts/pack-help.sh",
    # PACK-FEEDBACK.md (added 2026-05-24 during H.13 implementation —
    # architect-spec gap discovery, IMPL-REPORT-BD-173-Batch-19c-H.13.md
    # §7). Architect §2.3 originally classified this file as
    # anchor-phrase-legitimate (and thus NOT on the per-line fence list),
    # but empirically the file's `Pack Chat` references throughout the
    # template body lack the ±2-line "feedback" anchor in every context
    # window — the file's whole-file domain-vocabulary nature was
    # previously covered by the (now-removed) `_is_legitimate_deny_list_doc()`
    # whole-file exemption. Placing this file on the per-line fence list
    # with a whole-file fence preserves the architectural intent
    # (pack-vs-client feedback flow is the doc's reason for existing —
    # `Pack Chat` is unavoidable vocabulary).
    "project-template/docs/pack/PACK-FEEDBACK.md",
)


def _has_per_line_fence(rel_path: Path) -> bool:
    """Return True if rel_path is on the per-line-fence allowlist
    (i.e., the file MAY contain deny-list patterns INSIDE the fence
    markers; outside the fence, normal Check 37 rules apply).

    Replaces the legacy `_is_legitimate_deny_list_doc()` whole-file
    exemption (per `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
    §2.3).
    """
    return str(rel_path) in _CHECK_37_PER_LINE_FENCE_FILES


# Fence-marker line strings. The parser matches each MARKER as a
# suffix of the line's stripped right-hand side, allowing an optional
# shell-comment prefix (`# `) — so the same marker works in both
# markdown files and shell scripts:
#
#   Markdown:  `<!-- DENY-LIST-CONTENT-START -->`
#   Shell:     `# <!-- DENY-LIST-CONTENT-START -->`
#
# Per architect §2.5 invariant "each marker MUST be on its own line",
# the parser admits leading whitespace + an optional shell-comment
# prefix and rejects any other text on the line.
_FENCE_MARKER_START = "<!-- DENY-LIST-CONTENT-START -->"
_FENCE_MARKER_END = "<!-- DENY-LIST-CONTENT-END -->"


def _line_is_fence_marker(line: str, marker: str) -> bool:
    """Return True if line is exactly the fence marker (modulo leading
    whitespace + an optional `# ` shell-comment prefix).

    Per architect §2.3 shell-script fence-marker note: the shell `#`
    comment form preceding the marker is admitted so the line is a
    valid shell comment AND a valid fence marker for the parser.
    """
    stripped = line.strip()
    if stripped == marker:
        return True
    # Admit shell-comment prefix (`# <marker>` or `#<marker>`).
    if stripped.startswith("#"):
        rest = stripped[1:].lstrip()
        if rest == marker:
            return True
    return False


def _build_fence_skip_lineset(text: str) -> set[int] | None:
    """Parse the text for paired DENY-LIST-CONTENT-START / -END
    markers and return the set of 1-indexed line numbers INSIDE any
    fence (i.e., lines between paired markers, exclusive of the marker
    lines themselves).

    Multiple non-overlapping fences supported; nested fences NOT
    supported (return None on imbalance — caller emits a Check 37
    fail with the "fence-marker imbalance" diagnostic).

    Per architect §2.5 invariants:
      - Pairs MUST be balanced (every START followed by a matching END
        before the next START).
      - Fence range is EXCLUSIVE of the marker lines themselves.
      - Empty fence (START immediately followed by END) is permitted.
    """
    skip: set[int] = set()
    in_fence = False
    fence_start_line = 0
    for lineno, line in enumerate(text.splitlines(), start=1):
        if _line_is_fence_marker(line, _FENCE_MARKER_START):
            if in_fence:
                # Nested START — imbalance.
                return None
            in_fence = True
            fence_start_line = lineno
        elif _line_is_fence_marker(line, _FENCE_MARKER_END):
            if not in_fence:
                # END without matching START — imbalance.
                return None
            in_fence = False
            # Mark the interior lines (exclusive of markers).
            for inner in range(fence_start_line + 1, lineno):
                skip.add(inner)
            fence_start_line = 0
    if in_fence:
        # Unterminated START — imbalance.
        return None
    return skip


def check_project_side_deny_list() -> None:
    """Check 37 — project-side pack-only-reference deny list
    (BD-175 M5b per Architect C §8.2).

    Walks files under `project-template/` and greps for literal
    references to pack-only files / path prefixes / agent names / the
    capitalized `Pack Chat` orchestrator role. Each hit is a FAIL with
    file:line + matched pattern unless the context window contains a
    LEGITIMATE-context anchor phrase.

    Specific exemptions:
      - The `boundary-investigation` skill (Pattern A canonical single
        source at `project-template/skills/boundary-investigation/SKILL.md`,
        auto-distributed to all three CLI install paths via
        `stage_s4_skills()` at client install time) — its purpose is to
        teach the deny-list, so the entries appear as instructional
        content.
      - The project-side `coder.md` + `reviewer.md` prompt templates —
        same rationale.
      - The project trinity files — the "Project SSOT-first" bullet
        names the deny-list as instructional content.

    Anchor-phrase exception (per audit §D-4 LEGITIMATE designation):
      - `feedback`, `report back`, `escalation`, `stop and surface`
        (feedback-flow context per `PACK-FEEDBACK.md` / `PM-CHAT.md` /
        `METHODOLOGY.md` / `SETUP-EXISTING.md` LEGITIMATE designation)
      - `in the pack repo`, `at the pack repo`, `pack-repo`,
        `pack repo only` (pack-vs-project disambiguation context per
        BD-175 Commit 12 anchor-phrase extension — covers patterns like
        the `tracker.toml.pack-example` callout on
        `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49`)
    """
    print("\n── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──")
    any_failed = False
    files_walked = 0
    hits_clean = 0
    hits_fenced = 0

    for rel_path in _iter_project_side_files():
        full_path = REPO_ROOT / rel_path
        try:
            text = full_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        lines = text.splitlines()

        # Guardrail 2 (BD-173 H.13): per-line fence skip-set for
        # fence-allowlisted files. Files NOT on the allowlist get an
        # empty skip-set (no fence support outside the allowlist).
        if _has_per_line_fence(rel_path):
            fence_skip = _build_fence_skip_lineset(text)
            if fence_skip is None:
                fail(
                    f"{rel_path} — fence-marker imbalance "
                    f"(unmatched `<!-- DENY-LIST-CONTENT-START -->` / "
                    f"`<!-- DENY-LIST-CONTENT-END -->` markers; nesting "
                    f"NOT supported per ARCHITECTURE-V11-GUARDRAILS-"
                    f"CONTRACT.md §2.5). Remediation: balance markers "
                    f"so every START has a matching END before the next "
                    f"START."
                )
                any_failed = True
                fence_skip = set()
        else:
            fence_skip = set()

        for lineno, line in enumerate(lines, start=1):
            if lineno in fence_skip:
                hits_fenced += 1
                continue
            # Filename matches (bare).
            for fname, why in _DENY_LIST_FILENAMES:
                if fname in line:
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"file `{fname}` ({why}); no LEGITIMATE-context "
                        f"anchor phrase in ±{_DENY_LIST_ANCHOR_WINDOW} line "
                        f"window. Remediation: replace with project-side "
                        f"SSOT (e.g., docs/pack/PM-CHAT.md for agent "
                        f"roster) or remove the reference."
                    )
                    any_failed = True
            # Path-prefix matches.
            for prefix, why in _DENY_LIST_PATH_PREFIXES:
                if prefix in line:
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"path prefix `{prefix}` ({why}); no LEGITIMATE-"
                        f"context anchor phrase in ±{_DENY_LIST_ANCHOR_WINDOW} "
                        f"line window. Remediation: drop the cross-reference "
                        f"or replace with a project-side SSOT path."
                    )
                    any_failed = True
            # Agent-name word-boundary matches.
            for agent in _DENY_LIST_AGENT_NAMES:
                pattern = r"\b" + re.escape(agent) + r"\b"
                if re.search(pattern, line):
                    if _context_has_anchor(lines, lineno):
                        hits_clean += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — references pack-only "
                        f"agent name `{agent}` (pack-* agents are pack-"
                        f"repo only); no LEGITIMATE-context anchor in "
                        f"window. Remediation: use the project-side agent "
                        f"roster at docs/pack/PM-CHAT.md (unprefixed names: "
                        f"`architect`, `coder`, `planner`, `reviewer`, etc.)."
                    )
                    any_failed = True
            # Capitalized Pack Chat orchestrator-role match.
            if _DENY_LIST_ROLE_NAME in line:
                if _context_has_anchor(lines, lineno):
                    hits_clean += 1
                    continue
                fail(
                    f"{rel_path}:{lineno} — references `{_DENY_LIST_ROLE_NAME}` "
                    f"capitalized orchestrator role (pack-repo only — "
                    f"project-side equivalent is the project's PM chat); "
                    f"no LEGITIMATE-context anchor in window. Remediation: "
                    f"use `PM chat` (project-side orchestrator) or drop "
                    f"the reference."
                )
                any_failed = True

    if not any_failed:
        ok(
            f"Check 37 — {files_walked} project-side file(s) walked; "
            f"zero deny-list contamination "
            f"({hits_clean} anchored LEGITIMATE-context hit(s) accepted; "
            f"{hits_fenced} fenced LEGITIMATE-content line(s) exempt "
            f"per Guardrail 2)"
        )


# Check 38 — pack-only-file siting. For each file at pack-root (top-
# level), count pack-only signals (deny-list pattern hits); a file with
# count > threshold and not in the exempt list FAILs as "pack-only
# content sited outside pack-ops/".
_CHECK_38_PACK_ROOT_SCAN_GLOB = "*"
_CHECK_38_SIGNAL_THRESHOLD = 3  # heuristic; ≥N signals = pack-only content


def check_pack_only_file_siting() -> None:
    """Check 38 — pack-only-file siting (BD-175 M5c per Architect C §8.3).

    Per Architect C, the canonical post-B + B-fix design is that all
    PACK × OPERATIONS files live under `pack-ops/`. The only exception
    permitted at pack root is the 1-entry list in
    `pack-ops/.boundary-exempt-root.txt` (currently `tracker.toml.pack-
    example` per AUDIT-USER-CURATION.md Override 1).

    This check walks pack-root top-level files; for each, counts the
    pack-only-signal hits (deny-list patterns from Check 37) and FAILs
    when (a) the file is not in the exemption list AND (b) the file
    matches a pack-only-by-content heuristic via signal count > threshold.

    Implementation note: this is a coarse gate — semantic intent is
    not grep-detectable. The audit's V4 finding
    (`CONCEPTUAL-REVIEW-METHODOLOGY.md` is pack-only by content but was
    project-side by location) is the worked example this gate catches.
    Post B + B-fix, the relocations themselves cure the V4 case; this
    check is the regression guard.
    """
    print("\n── Check 38: Pack-only-file siting (BD-175, M5c) ──")
    exempt = _read_boundary_exempt_root()
    any_failed = False
    files_checked = 0

    # Walk pack root top-level files only (non-recursive).
    for path in sorted(REPO_ROOT.iterdir()):
        if not path.is_file():
            continue
        # Skip dotfiles (`.gitignore`, `.gitattributes`, etc. — these are
        # ecosystem-fixed names per trinity § Filename uniqueness exception).
        if path.name.startswith("."):
            continue
        # Skip the exemption list members.
        if path.name in exempt:
            continue
        # Skip files explicitly intended as pack-root user-facing (README,
        # QUICKSTART per AUDIT-USER-CURATION.md Override 7).
        if path.name in {"README.md", "QUICKSTART.md", "LICENSE", "Makefile"}:
            continue
        # Skip trinity at pack root (pack-root CLAUDE/AGENTS/GEMINI are
        # PM-only operating rules and legitimately reference pack-only
        # mechanisms — they ARE pack-only by audience).
        if path.name in {"CLAUDE.md", "AGENTS.md", "GEMINI.md"}:
            continue
        # Skip TOML / shell / Python config files that aren't markdown
        # content (this check targets prose pack-only content that may
        # have been mis-sited).
        if path.suffix not in {".md", ".txt"}:
            continue
        files_checked += 1
        try:
            text = path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        # Count pack-only signals in this file.
        signals = 0
        for fname, _ in _DENY_LIST_FILENAMES:
            signals += text.count(fname)
        for prefix, _ in _DENY_LIST_PATH_PREFIXES:
            signals += text.count(prefix)
        for agent in _DENY_LIST_AGENT_NAMES:
            signals += len(re.findall(r"\b" + re.escape(agent) + r"\b", text))
        signals += text.count(_DENY_LIST_ROLE_NAME)
        if signals >= _CHECK_38_SIGNAL_THRESHOLD:
            fail(
                f"{path.name} — sited at pack root with {signals} "
                f"pack-only signal(s) (deny-list patterns from Check 37); "
                f"threshold is {_CHECK_38_SIGNAL_THRESHOLD}. Pack-only "
                f"content should live under `pack-ops/` per BD-175 "
                f"directory architecture. Allowed exemption files are "
                f"listed in `pack-ops/.boundary-exempt-root.txt` "
                f"(1-entry post-B-fix per AUDIT-USER-CURATION.md "
                f"Override 1 + 5)."
            )
            any_failed = True

    if not any_failed:
        ok(
            f"Check 38 — {files_checked} pack-root prose file(s) checked; "
            f"no pack-only content mis-sited outside `pack-ops/`. "
            f"Exemption list: {sorted(exempt) or 'empty'}."
        )


# ── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ─────
#
# Scope: bidirectional symmetry between `scripts/init-project.sh`
# `cmd_update` `entries=()` array and project-template surface state.
#
# Forward direction (BD-175 F2a; `_CHECK_39_EXEMPTIONS`):
# `project-template/docs/pack/*.md` files must have explicit cmd_update
# mappings (catches the BD-175 Commit 10 OPTIONAL-FEATURES.md gap).
#
# Reverse direction (BD-180 observation E; `_CHECK_39_REVERSE_EXEMPTIONS`):
# every cmd_update entry's `pack_relpath` must resolve to a file at HEAD
# (catches the pre-BD-180 PROMPT-TEMPLATES.md stale-mapping gap; retired
# in v10.0 but mapping persisted at scripts/init-project.sh:1122).
#
# Exemption allowlists (empty by default): files intentionally absent from
# `cmd_update` mappings (forward) or whose source intentionally lives
# outside repo HEAD (reverse). Surface-over-silently-exempt: when in
# doubt, leave OUT and let Check 39 FAIL — Pack Chat triage decides
# per-file. Each entry MUST include a one-line rationale comment.
_CHECK_39_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD per BD-175 F2a IMPL-REPORT §6: all six
    # files under `project-template/docs/pack/*.md` currently have explicit
    # mappings. Add entries here only with a rationale comment.
}

_CHECK_39_REVERSE_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD per BD-180 observation E close: the
    # PROMPT-TEMPLATES.md stale entry was REMOVED from cmd_update in this
    # BD (retired in v10.0; mapping had been dead since the file deletion).
    # Add entries here only when a cmd_update source intentionally lives
    # outside the repo tree (e.g., a hypothetical extern-resolved path).
}


def _parse_cmd_update_entries() -> set[str]:
    """Parse `scripts/init-project.sh` `cmd_update` `entries=()` array.

    Returns the set of `pack_relpath` strings (the first colon-separated
    field of each entry). Parses via regex against the entries array
    delimited by `local entries=(` ... `)` — does not source the shell
    file. Returns an empty set if the file or array cannot be found.
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return set()
    text = init_sh.read_text()
    # Match the entries array literal. Non-greedy across newlines.
    m = re.search(
        r"local\s+entries=\(\s*\n(.+?)\n\s*\)\s*\n",
        text,
        re.DOTALL,
    )
    if not m:
        return set()
    body = m.group(1)
    paths: set[str] = set()
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # Strip surrounding quotes; entries are of the form
        # "pack_relpath:proj_relpath:class".
        if line.startswith('"') and '"' in line[1:]:
            content = line[1:line.index('"', 1)]
        else:
            continue
        pack_rel = content.split(":", 1)[0]
        if pack_rel:
            paths.add(pack_rel)
    return paths


def check_cmd_update_symmetry() -> None:
    """Check 39 — cmd_update mapping/glob coverage symmetry (BD-175 F2a + BD-180 E).

    Bidirectional symmetry between `scripts/init-project.sh`
    `cmd_update` `entries=()` array and project-template surface.

    Forward direction (BD-175 F2a): every file under
    `project-template/docs/pack/*.md` (the S6 fresh-install glob target)
    must have a corresponding explicit `cmd_update` mapping. Catches the
    BD-175 Commit 10 OPTIONAL-FEATURES.md fresh-init-only gap.

    Reverse direction (BD-180 observation E): every `cmd_update` entry's
    `pack_relpath` must resolve to a file at HEAD. Catches stale mappings
    whose source file was retired (pre-BD-180 example: PROMPT-TEMPLATES.md
    retired in v10.0 but mapping persisted at scripts/init-project.sh:1122).

    Exemption allowlists:
    - `_CHECK_39_EXEMPTIONS` — forward (file-on-disk lacks mapping;
      intentional).
    - `_CHECK_39_REVERSE_EXEMPTIONS` — reverse (mapping points outside
      repo HEAD; intentional).

    Lenient mode: if `scripts/init-project.sh` is absent (unlikely;
    REPO_ROOT issue) the check skips with a notice.
    """
    print("\n── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──")
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return
    pack_docs_dir = REPO_ROOT / "project-template" / "docs" / "pack"
    if not pack_docs_dir.is_dir():
        ok("project-template/docs/pack absent — skipping (lenient)")
        return

    entries = _parse_cmd_update_entries()
    if not entries:
        fail(
            "could not parse `cmd_update` entries=() array from "
            "scripts/init-project.sh — check that the array literal is "
            "still wrapped by `local entries=(` ... `)` per BD-175 F2a "
            "parsing contract"
        )
        return

    any_failed = False

    # ── Forward direction (BD-175 F2a) ───────────────────────────────────
    files_checked = 0
    exempted = 0
    for md in sorted(pack_docs_dir.glob("*.md")):
        files_checked += 1
        pack_rel = f"project-template/docs/pack/{md.name}"
        if pack_rel in entries:
            continue
        if md.name in _CHECK_39_EXEMPTIONS:
            exempted += 1
            ok(
                f"{md.name} — exempt per _CHECK_39_EXEMPTIONS: "
                f"{_CHECK_39_EXEMPTIONS[md.name]}"
            )
            continue
        fail(
            f"{pack_rel} — installs at fresh init (stage S6 glob loop at "
            f"scripts/init-project.sh:544) but has no explicit `cmd_update` "
            f"mapping; existing clients running `pack update` will silently "
            f"skip this file. Add an entry to the `entries=()` array in "
            f"`cmd_update` (scripts/init-project.sh ~L1108-L1133) of the "
            f"form: \"{pack_rel}:docs/pack/{md.name}:generic\". If the file "
            f"is intentionally pre-install-only or otherwise not for "
            f"client install, add it to `_CHECK_39_EXEMPTIONS` in "
            f"scripts/validate-pack.py with a one-line rationale."
        )
        any_failed = True

    # ── Reverse direction (BD-180 observation E) ─────────────────────────
    reverse_checked = 0
    reverse_exempted = 0
    for pack_rel in sorted(entries):
        reverse_checked += 1
        src_path = REPO_ROOT / pack_rel
        if src_path.is_file():
            continue
        if pack_rel in _CHECK_39_REVERSE_EXEMPTIONS:
            reverse_exempted += 1
            ok(
                f"{pack_rel} — exempt per _CHECK_39_REVERSE_EXEMPTIONS: "
                f"{_CHECK_39_REVERSE_EXEMPTIONS[pack_rel]}"
            )
            continue
        fail(
            f"{pack_rel} — `cmd_update` entry references a source file "
            f"that does not exist at HEAD; the mapping is stale (likely "
            f"the source file was retired or moved without removing the "
            f"entry). Either remove the entry from the `entries=()` array "
            f"in `cmd_update` (scripts/init-project.sh ~L1108-L1190), or "
            f"if the source intentionally lives outside repo HEAD, add it "
            f"to `_CHECK_39_REVERSE_EXEMPTIONS` in scripts/validate-pack.py "
            f"with a one-line rationale. Empirical precedent: BD-180 "
            f"observation E removed the stale `project-template/docs/pack/"
            f"PROMPT-TEMPLATES.md` mapping (file retired in v10.0)."
        )
        any_failed = True

    if not any_failed:
        ok(
            f"Check 39 — {files_checked} `project-template/docs/pack/*.md` "
            f"file(s) forward-checked; {files_checked - exempted} have "
            f"explicit `cmd_update` mappings, {exempted} on forward "
            f"exemption allowlist. {reverse_checked} `cmd_update` "
            f"entries reverse-checked; {reverse_checked - reverse_exempted} "
            f"resolve to existing files at HEAD, {reverse_exempted} on "
            f"reverse exemption allowlist. No asymmetric coverage between "
            f"S6 fresh-install glob and `cmd_update` explicit mappings; "
            f"no stale mappings."
        )


# ── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──────────────
#
# Per ARCHITECTURE-BD-179.md §3-§8. Walks `pack-ops/*.md` (excluding
# regenerated mirrors BACKLOG.md + CHANGELOG.md per §2.1 D1a) and flags
# backtick-delimited filename refs that lack a directory qualifier.
#
# Detection: P1 (bullet) + P2 (prose) + P3 (table) + P5 (hyperlink) regex
# patterns over a code-block-stripped representation per §3 D2. The first
# regex matches backtick-delimited filename spans like `MIGRATION-v10-to-v11.md`
# (no `/` in character class — qualified paths skip by construction). The
# hyperlink regex matches `](FILENAME.md)` form for `[link](FILENAME.md)`.
#
# Exemption: two-tier per §6 D5.
#   - `_CHECK_40_ALLOWLIST` — hardcoded dict (per §6.6 self-documenting
#     comment): pack-root files / trinity / memory cache / concept-noun
#     placeholders. PASS-with-notice.
#   - `_CHECK_40_ANCHOR_PHRASES` — contextual anchors in ±2-line window
#     around the hit. PASS-with-notice.
#   - Same-dir-legitimate — bare ref whose basename has exactly one
#     candidate path AND that path is in the same directory as the
#     referencing doc (e.g., bare `MERGE-STRATEGY.md` inside `pack-ops/`
#     resolves to `pack-ops/MERGE-STRATEGY.md`). PASS-with-notice. Per
#     Phase 1 survey §7.1 implicit-rule classification.
#
# Failure: FAIL with file:line + candidate-paths suggestion. Per §5.1
# triage: 0 candidates = broken ref; 1 candidate = qualify to <path>;
# 2+ = qualify to one of <paths>.

# Check 40 — pack-ops/ bare-cross-reference scanner — hardcoded allowlist.
# Extend this list when new bare references in pack-ops/ markdown are
# explicitly authorized (e.g., new pack-root files, new trinity members,
# new tool-specific exempt patterns). Adding an entry here is the
# intentional escape hatch for legitimate bareness; prefer qualifying
# the ref over allowlisting it unless the ref's bareness is load-bearing.
# Each addition lands in a BD's IMPL-REPORT with rationale per
# ARCHITECTURE-BD-179.md §6.5. (Self-documenting comment per §6.6,
# user-approved Q-B 2026-05-20.)
_CHECK_40_ALLOWLIST: dict[str, str] = {
    # Pack-root landing-page files — always resolvable at pack root per
    # `pack-ops/BOUNDARY-DEFINITION.md` §2 C1 (PACK × PRODUCT) classification.
    "README.md": "Pack-root landing-page doc (BOUNDARY-DEFINITION.md C1)",
    "QUICKSTART.md": "Pack-root installer doc (BOUNDARY-DEFINITION.md C1 + Override 7)",
    "LICENSE.md": "Pack-root deliverable; standard repo convention",
    "LICENSE": "Pack-root deliverable; extension-less licence file",
    # Pack-root trinity — always at pack root by Claude/Codex/Gemini contract
    # (BOUNDARY-DEFINITION.md §2 C3). Bare ref in pack-ops/ disambiguates
    # via the doc's own audience qualifier (pack-internal) per discipline.
    "CLAUDE.md": "Pack-root trinity (C3); see also project-template/CLAUDE.md",
    "AGENTS.md": "Pack-root trinity (C3); see also project-template/AGENTS.md",
    "GEMINI.md": "Pack-root trinity (C3); see also project-template/GEMINI.md",
    # Pack-memory `MEMORY.md` — the Claude-Code memory cache; bare ref
    # legitimate from any pack-side doc (the file lives in `~/.claude/...`,
    # not in the pack repo; bare ref is the actual reference shape).
    "MEMORY.md": "Claude-Code memory cache (external to pack repo)",
    # Concept-noun / generated-file / placeholder additions (OQ-S2,
    # user-approved 2026-05-20). Files generated at runtime / opt-in /
    # absent from pack repo at HEAD, or per-entry-tree filename
    # PATTERN placeholders (not real files).
    "tracker.toml": "Generated by `pack tracker init` (not in pack repo; pack ships tracker.toml.pack-example)",
    "id-map.json": "Generated tracker-mode metadata (not in pack repo)",
    "report.md": "Generated by scripts/lib/customization-report.sh (not in pack repo)",
    "manifest.txt": "RC9 manifest at test-fixtures/manifest.txt (per RC9 trigger rule)",
    "BD-NNN.md": "Per-entry backlog filename pattern (template; see /backlog/_format.md)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Claude-Code memory-cache feedback file (OQ-S3 Option A,
    # user-approved 2026-05-20). Same class as MEMORY.md.
    "feedback_review_fix_one_cycle.md": "Claude-Code memory cache feedback file (external to pack repo)",
    # Project-side HELP-FRAGMENT companion (referenced from
    # pack-ops/HELP-FRAGMENT-TRACKER.md, which is a byte-identical
    # mirror of project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
    # per Check 24). The bare ref is correct at the client-installed
    # location (resolves to docs/pack/HELP-FRAGMENT.md in the
    # client repo as a same-dir sibling); from pack-internal view it
    # would qualify to project-template/docs/pack/HELP-FRAGMENT.md
    # but qualifying it would break the byte-identity contract.
    "HELP-FRAGMENT.md": "Byte-identical mirror exception (Check 24); bare ref correct at client-installed location",
}

# Anchor phrases that, when found within the per-pattern context window
# (matched line + N lines before + N lines after), mark the match as
# legitimate per architect doc §6.4. A SUBSET of Check 37's anchor set,
# plus three new phrases scoped to Check 40's defect class.
_CHECK_40_ANCHOR_PHRASES = (
    # Inherit pack-vs-project disambiguation context from Check 37
    # (BOUNDARY-DEFINITION.md §6 cross-reference network).
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "in the project",
    "at the client",
    # Audience-bridge context per §6.4 + §7 D6. OQ-3 confirmed.
    "post-install",
    # OQ-S4 — self-flagging non-existence prose (e.g., L247
    # "...cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); ...").
    "does not exist",
    # OQ-S4 forward-compat — explicit "archived" qualifier in prose
    # (e.g., L195 "from the now-archived `ARCHITECTURE-V1.md` ...").
    "archived",
)

_CHECK_40_ANCHOR_WINDOW = 2  # lines before/after; matches Check 37 default

# Filename-extension classes Check 40 recognizes (per §3.3 final regex).
# Same set for the bullet/prose/table regex and the hyperlink regex.
_CHECK_40_FILE_EXTS = "md|sh|py|toml|yml|yaml|json|txt"

# Backtick-delimited bare ref (P1 + P2 + P3): `FILENAME.ext`. The first
# character class excludes `/` so qualified paths (`scripts/foo.sh`,
# `pack-ops/MERGE-STRATEGY.md`) are NOT matched. The first char is
# `[A-Za-z]` per §3.5 final (lowercase-starting filenames like
# `merge-json.py` must be admitted).
_CHECK_40_BARE_REF_PATTERN = re.compile(
    r"`([A-Za-z][A-Za-z0-9_.-]*\.(?:" + _CHECK_40_FILE_EXTS + r"))`"
)

# Markdown hyperlink (P5): `[link](FILENAME.ext)`. Same character class
# discipline as the bare-ref pattern.
_CHECK_40_HYPERLINK_PATTERN = re.compile(
    r"\]\(([A-Za-z][A-Za-z0-9_.-]*\.(?:" + _CHECK_40_FILE_EXTS + r"))\)"
)

# Code-block stripper: replace fenced code-block content (``` ... ```)
# AND indented 4-space code-block content with empty lines so line
# numbers are preserved. Single-backtick spans inside non-code-block
# prose are NOT stripped — those ARE the surface Check 40 looks for.
def _strip_code_blocks(text: str) -> list[str]:
    """Per `ARCHITECTURE-BD-179.md` §3.2 (code-block-stripping preprocess).

    Return list of lines with code-block content replaced by empty
    strings. Two mechanisms are recognized:

    1. **Fenced code blocks** (CommonMark §4.5) — lines whose first
       non-whitespace token is ` ``` ` (with optional language id) open
       and close the fence. All lines inside the fence (and the fence
       lines themselves) are replaced with empty strings.

    2. **Indented code blocks** (CommonMark §4.4) — outside a fenced
       block, a line that begins with 4 spaces of indentation AND
       follows a blank line begins an indented block. Consecutive
       lines that ALSO begin with 4-space indentation continue the
       block; blank lines INSIDE the block (between two indented
       lines) are tolerated. The block ends at the first non-blank
       line that is NOT 4-space-indented. All lines that participate
       in the block are replaced with empty strings.

       CommonMark edge cases (e.g., indented inside a list item is
       NOT an indented code block) are intentionally NOT modeled —
       pack-ops/ markdown convention favors fenced blocks, and the
       simple top-level "blank line then 4-space indent" rule covers
       every observed case without over-engineering (architect §3.2
       acknowledges the trade-off).

    Preserves total line count so file:line citations from Check 40
    remain accurate against the original file (matching Check 37
    convention).
    """
    raw_lines = text.splitlines()
    out: list[str] = []
    in_fence = False
    in_indented = False
    prev_blank = True  # treat "before line 0" as blank → indent can open at line 0
    for line in raw_lines:
        stripped = line.lstrip()
        # Fenced-block handling takes precedence over indented detection.
        if stripped.startswith("```"):
            in_fence = not in_fence
            in_indented = False  # fence trumps any pending indented context
            out.append("")  # the fence line itself is also stripped
            prev_blank = False
            continue
        if in_fence:
            out.append("")
            prev_blank = False
            continue

        # Indented-block handling.
        is_blank = line.strip() == ""
        is_indented_4 = line.startswith("    ")

        if in_indented:
            if is_indented_4:
                # Block continues.
                out.append("")
                prev_blank = False
                continue
            if is_blank:
                # Blank line inside indented block — keep block open;
                # emit empty line (line count preserved).
                out.append("")
                prev_blank = True
                continue
            # Non-indented non-blank line ends the block.
            in_indented = False
            # Fall through to emit this line as prose.
        else:
            if is_indented_4 and prev_blank:
                # Open new indented block at this line.
                in_indented = True
                out.append("")
                prev_blank = False
                continue

        out.append(line)
        prev_blank = is_blank
    return out


# EXCLUDE directories for the basename-index walk (per §5.1 D4).
# `scripts/tests/fixtures/` added per OQ-S1 ratification 2026-05-20.
_CHECK_40_EXCLUDE_PARTS = (
    ".git",
    "maintenance-docs/archive",
    "test-fixtures",
    "scripts/tests/fixtures",
    "node_modules",
)


def _build_basename_index() -> dict[str, list[Path]]:
    """Walk the pack repo and build a basename → [relative-paths] index.
    Used for the §5.1 D4 candidate-path lookup.

    Per §5.1 EXCLUDE list (with OQ-S1 expansion 2026-05-20):
      - `.git/` always skipped (pack-internal git state)
      - `maintenance-docs/archive/` (historical content with stale refs)
      - `test-fixtures/` (synthetic fixture content)
      - `scripts/tests/fixtures/` (per-script synthetic fixture trees)
      - `node_modules`-like dirs (defensive; not present at HEAD)
    """
    index: dict[str, list[Path]] = {}
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        try:
            rel = path.relative_to(REPO_ROOT)
        except ValueError:
            continue
        rel_str = str(rel).replace(os.sep, "/")
        # Skip excluded paths.
        skip = False
        for excl in _CHECK_40_EXCLUDE_PARTS:
            if rel_str == excl or rel_str.startswith(excl + "/"):
                skip = True
                break
        if skip:
            continue
        basename = path.name
        index.setdefault(basename, []).append(rel)
    return index


def _check_40_context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any Check-40 anchor phrase appears in the matched
    line or the ±_CHECK_40_ANCHOR_WINDOW surrounding lines.

    Parallel helper to `_context_has_anchor` (Check 37). Per §9.6, the
    coder may choose to refactor or to keep parallel; chose parallel
    here to avoid touching Check 37's code path for a non-Check-37 BD.
    """
    start = max(0, lineno - 1 - _CHECK_40_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _CHECK_40_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _CHECK_40_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False


def check_bare_pack_ops_refs() -> None:
    """Check 40 — pack-ops/ bare cross-reference scanner (BD-179 per
    ARCHITECTURE-BD-179.md §3-§8).

    Walks `pack-ops/*.md` (excluding `pack-ops/BACKLOG.md` and
    `pack-ops/CHANGELOG.md` — regenerated mirrors per §2.1 D1a) and
    flags backtick-delimited filename refs that lack a directory
    qualifier and are not exempt per the allowlist / anchor-phrase /
    same-dir-legitimate mechanisms.

    Failure modes:
      - Bare ref with 0 candidate paths → "broken ref"
      - Bare ref with 1 candidate path → "qualify to <path>"
      - Bare ref with 2+ candidate paths → "qualify to one of <paths>"

    PASS notices:
      - Allowlist hit → "exempt: <rationale>"
      - Anchor-phrase hit → "anchor-phrase-exempt"
      - Same-dir-legit → "same-dir resolution"
    """
    print("\n── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──")
    pack_ops_dir = REPO_ROOT / "pack-ops"
    if not pack_ops_dir.is_dir():
        ok("pack-ops/ absent — skipping (lenient)")
        return

    # Build basename index ONCE per Check 40 invocation per §5.3.
    index = _build_basename_index()

    # Excluded files per §2.1 D1a (regenerated mirrors).
    excluded_basenames = {"BACKLOG.md", "CHANGELOG.md"}

    any_failed = False
    files_walked = 0
    hits_allowlist = 0
    hits_anchor = 0
    hits_same_dir = 0
    hits_failed = 0

    for md_path in sorted(pack_ops_dir.glob("*.md")):
        if md_path.name in excluded_basenames:
            continue
        try:
            text = md_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        stripped_lines = _strip_code_blocks(text)
        rel_path = md_path.relative_to(REPO_ROOT)
        rel_dir = str(rel_path.parent).replace(os.sep, "/")

        for lineno, line in enumerate(stripped_lines, start=1):
            # Collect all bare-ref matches on this line (both regexes).
            matches: list[str] = []
            for m in _CHECK_40_BARE_REF_PATTERN.finditer(line):
                matches.append(m.group(1))
            for m in _CHECK_40_HYPERLINK_PATTERN.finditer(line):
                matches.append(m.group(1))
            if not matches:
                continue

            for basename in matches:
                # Tier 1: hardcoded allowlist.
                if basename in _CHECK_40_ALLOWLIST:
                    hits_allowlist += 1
                    continue
                # Tier 2: anchor-phrase exemption (±2-line window).
                if _check_40_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                # Tier 3: same-dir-legitimate per Phase 1 survey §7.1
                # implicit rule. If the basename has exactly one
                # candidate AND that candidate is in the same directory
                # as the referencing doc, the bareness is legitimate
                # (analogous to programming-language sibling-import
                # semantics).
                candidates = index.get(basename, [])
                if len(candidates) == 1:
                    candidate_dir = str(candidates[0].parent).replace(os.sep, "/")
                    if candidate_dir == rel_dir:
                        hits_same_dir += 1
                        continue

                # FAIL — emit triage per §5.1 D4 candidate-set size.
                if not candidates:
                    suggestion = (
                        "broken ref — no file with that basename exists "
                        "in the pack repo (excluding test-fixtures and "
                        "scripts/tests/fixtures synthetic trees)"
                    )
                elif len(candidates) == 1:
                    one = str(candidates[0]).replace(os.sep, "/")
                    suggestion = f"qualify to `{one}`"
                else:
                    paths = [str(c).replace(os.sep, "/") for c in candidates]
                    suggestion = (
                        "qualify to one of: " + ", ".join(f"`{p}`" for p in sorted(paths))
                    )
                fail(
                    f"{rel_path}:{lineno} — bare cross-reference "
                    f"`{basename}` (no directory qualifier). {suggestion}. "
                    f"Remediation: qualify the path OR add `{basename}` to "
                    f"`_CHECK_40_ALLOWLIST` in scripts/validate-pack.py with "
                    f"one-line rationale (per ARCHITECTURE-BD-179.md §6.5) "
                    f"OR wrap in a fenced code block if it is a shell/code "
                    f"example."
                )
                hits_failed += 1
                any_failed = True

    if not any_failed:
        ok(
            f"Check 40 — {files_walked} pack-ops/*.md file(s) walked; "
            f"zero unqualified bare cross-references "
            f"({hits_allowlist} allowlist-exempt + {hits_anchor} anchor-"
            f"phrase-exempt + {hits_same_dir} same-dir-legit hit(s) accepted)"
        )


# ── Check 43: project-side bare cross-reference scanner (BD-173 H.14) ──────
#
# Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1 (V11 leak-sweep
# prevention; class-test counterpart to Check 37's name-enumeration).
# Walks the canonical client-installed surface (`_iter_client_installed_files()`
# per Guardrail 3 §3.1) and flags bare backtick-delimited filename refs
# whose basename resolves into pack-only territory (`maintenance-docs/`
# or `pack-ops/` non-mirror) OR a non-client-installed `supporting-docs/`
# file. The class-test ("does this name resolve into pack-only
# territory?") is semantically different from Check 37's enumeration
# ("is this exact name in the deny-list?") — Check 43 catches future
# audit-vocabulary-gap leaks (e.g., `AUDIT-USER-CURATION.md`,
# `ARCHITECTURE-V3.md`) that the Check 37 enumeration would miss.
#
# Reuses Check 40 mechanism (basename index + code-block stripping +
# anchor-phrase aliases + bare/hyperlink regex). NO new regex. Different
# allowlist (project-side legitimate-resolution targets per §1.4).
#
# See `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
# §1.1-§1.12 for the verbatim contract.

# Check 43 — project-side bare-cross-reference scanner — hardcoded
# allowlist. Per §1.4 verbatim. Every entry maps to a file shipped to
# clients via `_CLIENT_INSTALLED_FILES` OR a name explicitly external/
# generated. Every entry carries a one-line rationale (Check 40 §6.5
# self-documenting allowlist convention).
_CHECK_43_ALLOWLIST: dict[str, str] = {
    # Project-side trinity (client-side resolution).
    "CLAUDE.md": "Project-side trinity at client root (also project-template/CLAUDE.md)",
    "AGENTS.md": "Project-side trinity at client root (also project-template/AGENTS.md)",
    "GEMINI.md": "Project-side trinity at client root (also project-template/GEMINI.md)",
    # Project-side README + LICENSE.
    "README.md": "Project-side or pack-side README (resolves at both)",
    "LICENSE.md": "Standard repo convention",
    "LICENSE": "Standard repo convention",
    # Pack-feedback cross-boundary product feature (PM chat writes here).
    "PACK-FEEDBACK.md": "Project-side cross-boundary feedback channel (docs/pack/)",
    # Project-side methodology / install docs (post-install at docs/pack/).
    "METHODOLOGY.md": "Project-side docs/pack/METHODOLOGY.md (client-installed)",
    "INSTALL-PROCEDURES.md": "Project-side docs/pack/INSTALL-PROCEDURES.md (client-installed)",
    "PM-CHAT.md": "Project-side docs/pack/PM-CHAT.md (client-installed orchestrator rules)",
    "PLATFORM-SKILLS.md": "Project-side docs/pack/PLATFORM-SKILLS.md (client-installed)",
    "OPTIONAL-FEATURES.md": "Project-side docs/pack/OPTIONAL-FEATURES.md (client-installed)",
    "HELP-FRAGMENT.md": "Project-side docs/pack/HELP-FRAGMENT.md (client-installed)",
    "HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-TRACKER.md (client-installed; byte-identical mirror per Check 24)",
    "SETUP-EXISTING.md": "Project-side docs/pack/SETUP-EXISTING.md (client-installed install doc)",
    # Per-entry skeleton filename PATTERNS (template placeholders, not real files).
    "BD-NNN.md": "Per-entry backlog filename pattern (template)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Per-entry tree sibling skeleton files (resolve same-dir within docs/project/<stream>/).
    "_rules.md": "Per-entry tree per-stream rules sibling (same-dir resolution)",
    "_intro.md": "Per-entry tree intro sibling (same-dir resolution)",
    "_format.md": "Per-entry tree format sibling (same-dir resolution)",
    # Project-side mirrors (regenerated; never source of truth but resolve at client install).
    "BACKLOG.md": "Project-side mirror (regenerated); at client docs/project/",
    "CHANGELOG.md": "Project-side mirror (regenerated); at client docs/project/",
    "IMPLEMENTATION-PLAN.md": "Project-side mirror (regenerated); at client docs/project/",
    "STATUS.md": "Project-side STATUS.md (PM chat maintains)",
    "ARCHITECTURE.md": "Project-side docs/project/ARCHITECTURE.md (PM/architect maintains)",
    # Generated / opt-in / external files.
    "tracker.toml": "Generated by `pack tracker init` (not in project repo at install)",
    "tracker.toml.example": "Project-side example shipped at client root",
    "id-map.json": "Generated tracker-mode metadata",
    "MEMORY.md": "Claude-Code memory cache (~/.claude/, external to project)",
    # Standard project scripts that resolve at client install.
    "agent-run.sh": "Project-side agent launcher at client root",
    # ── Option C absorption (BD-173 H.14 follow-up) — audit-vocabulary-gap
    # legitimates per H.14 IMPL-REPORT §7.2.2 Option A list. Per Pack Chat
    # triage (2026-05-24) Pack Chat user direction Option C hybrid:
    # allowlist legitimate audit-vocabulary-gap entries AND fix the
    # 5-6 real LEAK CLASS C catches. The entries below are basenames
    # the architect §1.4 spec did not anticipate but which are
    # ambiguous-by-design (generic basenames, agent prompt meta-refs),
    # template placeholders (generated by pm-chat), or legacy /
    # generated names (no real file at HEAD).
    # ── Template placeholders (generated by pm-chat self-prompt).
    "SETUP.md": "Template placeholder; generated by pm-chat self-prompt at install (no real file in pack repo)",
    "AGENT_KICKOFF.md": "Template placeholder; generated by pm-chat self-prompt at install (no real file in pack repo)",
    # ── Generic basenames (ambiguous-by-design at the meta-reference level).
    "SKILL.md": "Per-skill filename; ambiguous-by-design at the meta-reference level (~70 skills collide)",
    "config.toml": "Generic config basename; ambiguous (multiple candidate locations across CLIs)",
    "settings.json": "Generic config basename; ambiguous (xcode/vscode/CLI companion templates)",
    # ── Agent prompt meta-references (ambiguous-by-design; resolve to 3 candidates per agent: claude/gemini/docs-pack-prompts).
    "coder.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "architect.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "reviewer.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "planner.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "tester.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "auditor.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "docs-researcher.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    "auditor-architecture.md": "Agent prompt meta-reference; ambiguous (3 candidates: claude/gemini/docs-pack-prompts)",
    # ── Per-entry skeleton variants (similar to phase-N.md / BD-NNN.md already allowlisted).
    "phase-N.M.md": "Per-entry implementation-plan filename pattern variant (sub-phase placeholder)",
    "phase-0.md": "Per-entry implementation-plan filename pattern variant (phase-zero placeholder)",
    "phase-NN.md": "Per-entry implementation-plan filename pattern variant (two-digit phase placeholder)",
    "phase-35.md": "Per-entry implementation-plan filename pattern variant (specific phase example)",
    "TD-001.md": "Per-entry tech-debt filename pattern; specific instance placeholder in docs",
    # ── Custom skill placeholder.
    "x-foo.md": "x-prefix custom skill placeholder example (template; not a real file)",
    # ── Legacy / generated filenames (no real file at HEAD; broken-ref-by-design).
    "report.md": "Generic agent report filename; no real file at HEAD (template / generated)",
    "PROMPT-TEMPLATES.md": "Legacy doc name; not in pack repo at HEAD (referenced for legacy continuity)",
    "FEATURES.md": "Generic feature-list basename; no real file at HEAD (template / placeholder)",
    "V10-DESIGN.md": "Legacy v10-era design doc name; not in pack repo at HEAD",
    "MIGRATION-v9-to-v10.md": "Legacy migration doc; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-v9-to-v10.sh": "Legacy migration script; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-vN-to-vM.sh": "Migrator framework filename pattern (placeholder per BD-119 architect doc)",
    # ── Audit-methodology teaching examples (illustrative content in skill docs).
    "user_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "order_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "inventory_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
}

# Anchor-phrase reuse — Check 43 inherits Check 40's anchor-phrase set
# verbatim per §1.5. Aliases (rather than duplicates) so future anchor
# additions in Check 40 propagate. Implementation note: prefer aliasing
# over duplication; if a future maintainer needs to diverge, the alias
# is a one-line edit to a fresh tuple.
_CHECK_43_ANCHOR_PHRASES = _CHECK_40_ANCHOR_PHRASES  # alias; same set
_CHECK_43_ANCHOR_WINDOW = _CHECK_40_ANCHOR_WINDOW    # alias; 2

# Mirror-skip exclusions per §1.9 — regenerated project-side mirrors
# may legitimately mirror pack-internal cites from the per-entry source
# (Check 43 walks the source trees, not the mirrors).
_CHECK_43_MIRROR_SKIP_BASENAMES = ("BACKLOG.md", "CHANGELOG.md", "IMPLEMENTATION-PLAN.md")

# Pack-internal target prefixes for the FAIL (pack-internal target)
# verdict per §1.7. A bare ref whose basename resolves into one of these
# directories (with the noted exception for the client-installed mirror)
# FAILs as a pack-internal cite.
_CHECK_43_PACK_INTERNAL_PREFIXES = ("maintenance-docs/", "pack-ops/")

# pack-ops/ files that ARE client-installed (excluded from the pack-
# internal-target FAIL because they resolve at client install time).
_CHECK_43_PACK_OPS_CLIENT_INSTALLED = ("pack-ops/HELP-FRAGMENT-TRACKER.md",)


def check_project_side_bare_internal_refs() -> None:
    """Check 43 — project-side / client-installed bare cross-references
    to pack-internal files (V11 leak-sweep prevention; strategy §4.1).

    Walks the canonical client-installed surface
    (`_iter_client_installed_files()` per Guardrail 3 §3.1) and flags
    bare backtick-delimited filename refs whose basename resolves into
    pack-only territory (`maintenance-docs/` or `pack-ops/` non-mirror)
    or a non-client-installed `supporting-docs/` file.

    Reuses Check 40's mechanism (basename index + code-block stripping +
    anchor-phrase exemption + bare/hyperlink regex). Different from
    Check 40 in: (a) walked surface (project-side / client-installed
    instead of pack-ops/), (b) allowlist (project-side legitimate
    targets), (c) class-test FAIL semantic (resolves-into-pack-only
    instead of un-qualified candidate-suggestion).

    Failure modes:
      - FAIL (pack-internal target): basename resolves into
        `maintenance-docs/` OR `pack-ops/` (excluding client-installed
        `pack-ops/HELP-FRAGMENT-TRACKER.md`)
      - FAIL (pre-install-only `supporting-docs/`): basename resolves
        into `supporting-docs/<X>` AND `<X>` not in client-install set
      - FAIL (broken): 0 candidates AND not on allowlist AND no anchor
      - FAIL (ambiguous): 2+ candidates AND none is a client-installed
        legitimate target AND no same-dir match

    PASS notices:
      - Allowlist hit → "exempt: <rationale>"
      - Anchor-phrase hit → "anchor-phrase-exempt"
      - Same-dir-legit → "same-dir resolution"
      - Client-installed pack-side resolution → "client-installed-exempt"

    See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.1-§1.12 for the
    verbatim contract.
    """
    print("\n── Check 43: Project-side bare cross-reference scanner (BD-173) ──")

    # Build basename index ONCE per Check 43 invocation per §1.3
    # (same pattern as Check 40 §5.3). Reuses Check 40's _build_basename_index.
    index = _build_basename_index()

    # Build the set of supporting-docs/ filenames that ARE installed at
    # client per §1.6. Parse via Guardrail 3's helper.
    installed_supporting_docs: set[str] = set()
    try:
        entries, _, _, _, _ = _parse_client_installed_files()
        for entry in entries:
            if entry.startswith("supporting-docs/"):
                installed_supporting_docs.add(entry[len("supporting-docs/"):])
    except Exception:
        # Defensive: if parse fails, the inventory check (Check 41)
        # will surface the issue; Check 43 falls back to empty set
        # (every supporting-docs/ cite will FAIL pre-install-only).
        pass

    any_failed = False
    files_walked = 0
    hits_allowlist = 0
    hits_anchor = 0
    hits_same_dir = 0
    hits_client_installed = 0
    hits_fenced = 0

    walked_files = _iter_client_installed_files()

    for rel_path in walked_files:
        # Apply extension filter per §1.2 (matches Check 40's
        # _CHECK_40_FILE_EXTS). Skip files whose extension is not in
        # the recognized set so we do not walk arbitrary binary
        # content via the basename regex.
        suffix = rel_path.suffix.lstrip(".")
        if suffix not in _CHECK_40_FILE_EXTS.split("|"):
            continue
        # Mirror-skip exclusions per §1.9.
        if rel_path.name in _CHECK_43_MIRROR_SKIP_BASENAMES:
            continue
        full_path = REPO_ROOT / rel_path
        try:
            text = full_path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        files_walked += 1
        stripped_lines = _strip_code_blocks(text)
        rel_dir = str(rel_path.parent).replace(os.sep, "/")

        # Guardrail 2 (BD-173 H.13) fence skip-set — Check 43 inherits
        # the same per-line-fence semantics as Check 37 so deny-list-
        # teaching content (e.g., boundary-investigation/SKILL.md's
        # enumeration block) is exempt from class-test detection. Per
        # ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.12 — line 124
        # remediation note: "Catches only if line is OUTSIDE the
        # Guardrail 2 per-line fence."
        #
        # Note: imbalance is surfaced by Check 37; Check 43 silently
        # falls back to empty skip-set on imbalance so we do not
        # double-report the same failure.
        if _has_per_line_fence(rel_path):
            fence_skip = _build_fence_skip_lineset(text)
            if fence_skip is None:
                fence_skip = set()
        else:
            fence_skip = set()

        # Pre-compile a search across raw lines for qualified
        # supporting-docs/<X> path references (P1.10 LEAK CLASS C
        # — `supporting-docs/SETUP-NEW.md`, `supporting-docs/CLI-PM-SETUP.md`).
        # We scan the raw lines (post code-block stripping) for the
        # qualified path-prefix; bare-ref regex would not match the
        # qualified form because its first character class excludes `/`.
        for lineno, line in enumerate(stripped_lines, start=1):
            # Skip lines inside the Guardrail 2 fence (intentional
            # deny-list teaching content exempt per §1.12).
            if lineno in fence_skip:
                hits_fenced += 1
                continue
            # Qualified supporting-docs/<X> detection (pre-install-only FAIL).
            # Look for `supporting-docs/<filename>.<ext>` as a literal substring.
            import re as _re_local  # local alias for clarity
            for m in _re_local.finditer(
                r"supporting-docs/([A-Za-z0-9_-]+(?:\.[A-Za-z0-9]+)+)",
                line,
            ):
                fname = m.group(1)
                # If the file is NOT client-installed, this is a
                # pre-install-only leak class (LEAK CLASS C).
                if fname not in installed_supporting_docs:
                    # Apply anchor-phrase exemption per §1.5.
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — qualified reference "
                        f"`supporting-docs/{fname}` (pre-install reference; "
                        f"not shipped to clients via "
                        f"_CLIENT_INSTALLED_FILES inventory). Remediation: "
                        f"drop the cite OR replace with a project-side SSOT "
                        f"(e.g., docs/pack/PM-CHAT.md for orchestration rules) "
                        f"OR — if intentional pack-as-product cite — add an "
                        f"anchor phrase like \"in the pack repo\" within "
                        f"±2 lines."
                    )
                    any_failed = True

            # Qualified pack-ops/<X> and maintenance-docs/<X> detection
            # (LEAK CLASS D in scripts/lib/detect.sh comments / LEAK
            # CLASS for any qualified pack-only path-prefix in project-
            # side prose). Bare-ref regex would not match these because
            # of the `/` separator; explicit substring detection.
            for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:
                # Use a local import only to keep the qualified-prefix
                # detection scoped (mirrors the supporting-docs/ search
                # above).
                pattern = _re_local.compile(
                    _re_local.escape(prefix)
                    + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"
                )
                for m in pattern.finditer(line):
                    rest = m.group(1)
                    full_target = prefix + rest
                    # Allow the client-installed pack-ops/ mirror.
                    if full_target in _CHECK_43_PACK_OPS_CLIENT_INSTALLED:
                        hits_client_installed += 1
                        continue
                    # Allow project-side trinity references to pack-ops/PACK-FEEDBACK
                    # via anchor-phrase context (handled by the anchor scan below).
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — qualified reference "
                        f"`{full_target}` to pack-internal target "
                        f"(pack-only — not at client install). Remediation: "
                        f"drop the cite OR replace with a project-side SSOT "
                        f"(e.g., docs/pack/PM-CHAT.md for orchestration rules) "
                        f"OR — if intentional pack-as-product cite — add an "
                        f"anchor phrase like \"in the pack repo\" within "
                        f"±2 lines."
                    )
                    any_failed = True

            # Bare-ref matches (P1 + P2 + P3 + P5) reuse Check 40
            # regex patterns per §1.3 (NO new regex).
            matches: list[str] = []
            for m in _CHECK_40_BARE_REF_PATTERN.finditer(line):
                matches.append(m.group(1))
            for m in _CHECK_40_HYPERLINK_PATTERN.finditer(line):
                matches.append(m.group(1))
            if not matches:
                continue

            for basename in matches:
                # Tier 1: hardcoded allowlist (basename-keyed per §1.4).
                if basename in _CHECK_43_ALLOWLIST:
                    hits_allowlist += 1
                    continue
                # Tier 2: anchor-phrase exemption (±2-line window per §1.5).
                if _check_43_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                # Tier 3: same-dir-legitimate per Check 40 §7.1 pattern.
                # If the basename has exactly one candidate AND that
                # candidate is in the same directory as the referencing
                # doc, the bareness is legitimate (sibling-import
                # semantics).
                candidates = index.get(basename, [])
                if len(candidates) == 1:
                    candidate_dir = str(candidates[0].parent).replace(os.sep, "/")
                    if candidate_dir == rel_dir:
                        hits_same_dir += 1
                        continue

                # Class-test FAIL: does the basename resolve into pack-
                # only territory (`maintenance-docs/` or `pack-ops/`
                # excluding the client-installed mirror)?
                pack_internal_candidates = []
                for cand in candidates:
                    cand_str = str(cand).replace(os.sep, "/")
                    if cand_str in _CHECK_43_PACK_OPS_CLIENT_INSTALLED:
                        # Resolves to a client-installed file — legitimate.
                        continue
                    for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:
                        if cand_str.startswith(prefix):
                            pack_internal_candidates.append(cand_str)
                            break

                if pack_internal_candidates:
                    targets = ", ".join(f"`{t}`" for t in sorted(pack_internal_candidates))
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` resolves to pack-internal target "
                        f"{targets} (pack-only — not at client install). "
                        f"Remediation: drop the cite OR replace with a "
                        f"project-side SSOT (e.g., docs/pack/PM-CHAT.md "
                        f"for orchestration rules) OR — if intentional "
                        f"pack-as-product cite — add an anchor phrase like "
                        f"\"in the pack repo\" within ±2 lines OR add "
                        f"`{basename}` to `_CHECK_43_ALLOWLIST` in "
                        f"scripts/validate-pack.py with one-line rationale."
                    )
                    any_failed = True
                    continue

                # supporting-docs/<X> resolution where <X> not in
                # client-install set — FAIL pre-install-only.
                supporting_candidates = []
                for cand in candidates:
                    cand_str = str(cand).replace(os.sep, "/")
                    if cand_str.startswith("supporting-docs/"):
                        sd_name = cand_str[len("supporting-docs/"):]
                        if sd_name not in installed_supporting_docs:
                            supporting_candidates.append(cand_str)

                if supporting_candidates:
                    targets = ", ".join(f"`{t}`" for t in sorted(supporting_candidates))
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` resolves to {targets} (pre-install "
                        f"reference; not shipped to clients via "
                        f"_CLIENT_INSTALLED_FILES inventory). Remediation: "
                        f"drop the cite OR replace with a project-side SSOT."
                    )
                    any_failed = True
                    continue

                # No candidates AND not on allowlist AND no anchor → broken.
                if not candidates:
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` — broken ref (no file with that "
                        f"basename exists in the pack repo, excluding "
                        f"test-fixtures and scripts/tests/fixtures synthetic "
                        f"trees). Remediation: qualify the path, fix the "
                        f"typo, OR remove the reference."
                    )
                    any_failed = True
                    continue

                # Ambiguous: 2+ candidates, none of which is pack-internal,
                # none in supporting-docs/<X> non-installed, no same-dir
                # match. This is a legitimate-resolution ambiguity rather
                # than a pack-only leak — but still fails because the
                # bare cite resolves to multiple candidates none of
                # which is on the allowlist.
                if len(candidates) >= 2:
                    paths = [str(c).replace(os.sep, "/") for c in candidates]
                    fail(
                        f"{rel_path}:{lineno} — bare cross-reference "
                        f"`{basename}` is ambiguous (resolves to multiple "
                        f"non-allowlisted candidates). Remediation: "
                        f"qualify to one of: "
                        + ", ".join(f"`{p}`" for p in sorted(paths))
                        + f" OR add `{basename}` to `_CHECK_43_ALLOWLIST` "
                        f"in scripts/validate-pack.py with one-line rationale."
                    )
                    any_failed = True
                    continue

                # Single candidate that is NOT pack-internal AND NOT
                # supporting-docs/<X> non-installed AND NOT same-dir —
                # this is a legitimate cross-directory project-side
                # reference (e.g., a docs/pack/ → docs/project/ cite).
                # Accept as client-installed-exempt.
                hits_client_installed += 1

    if not any_failed:
        ok(
            f"Check 43 — {files_walked} project-side / client-installed "
            f"file(s) walked; zero pack-internal bare cross-references "
            f"({hits_allowlist} allowlist-exempt + {hits_anchor} anchor-"
            f"phrase-exempt + {hits_same_dir} same-dir-legit + "
            f"{hits_client_installed} client-installed-legit + "
            f"{hits_fenced} fenced-line(s) accepted)"
        )


def _check_43_context_has_anchor(lines: list[str], lineno: int) -> bool:
    """Return True if any Check-43 anchor phrase appears in the matched
    line or the ±_CHECK_43_ANCHOR_WINDOW surrounding lines.

    Parallel helper to `_check_40_context_has_anchor` (Check 40); uses
    the aliased anchor-phrase set per §1.5. Kept as a separate function
    to allow future divergence without touching Check 40's code path.
    """
    start = max(0, lineno - 1 - _CHECK_43_ANCHOR_WINDOW)
    end = min(len(lines), lineno - 1 + _CHECK_43_ANCHOR_WINDOW + 1)
    window = " ".join(lines[start:end]).lower()
    for anchor in _CHECK_43_ANCHOR_PHRASES:
        if anchor in window:
            return True
    return False


# ── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ───
#
# Per ARCHITECTURE-BD-176.md §5.3 (forward-referenced from BD-176 D4
# deferral; landed in BD-180 per LOGICAL-FIT criterion). The
# `_CLIENT_INSTALLED_FILES_START` / `_CLIENT_INSTALLED_FILES_END` comment
# block in `scripts/init-project.sh` is an authoritative inventory of
# files this script installs to clients. Check 41 enforces the
# discoverability contract:
#   (a) START + END markers each appear exactly once,
#   (b) the block has at least one entry line,
#   (c) every entry's `pack_relpath` exists at HEAD,
#   (d) every `cmd_update` `pack_relpath` is listed in the block.
#
# (d) is the load-bearing assertion: it prevents drift between the
# self-documenting list and the actual `cmd_update` array — an actor
# adding a cmd_update entry without updating the list trips this check.
#
# Exemption allowlist (empty by default): inventory entries whose source
# intentionally lives outside repo HEAD. Surface-over-silently-exempt:
# when in doubt, leave OUT and let Check 41 FAIL.
_CHECK_41_EXEMPTIONS: dict[str, str] = {
    # Intentionally empty at HEAD per BD-180 close: every entry in the
    # `_CLIENT_INSTALLED_FILES_START`/`_END` block resolves to a real
    # source file. Add entries here only when the inventory references
    # a path that intentionally does not exist at HEAD.
}


def _parse_client_installed_files() -> tuple[list[str], int, int, bool, bool]:
    """Parse `_CLIENT_INSTALLED_FILES` block from `scripts/init-project.sh`.

    Returns `(entries, start_count, end_count, regex_matched, body_has_content)`:
      - `entries`: list of `pack_relpath` strings extracted from each
        entry line between START and END markers. Empty list if either
        marker is not present exactly once OR the regex body-extraction
        fails OR the body contains no parseable `->` entries.
      - `start_count`: integer count of `_CLIENT_INSTALLED_FILES_START`
        marker occurrences in the file. Caller enforces == 1.
      - `end_count`: integer count of `_CLIENT_INSTALLED_FILES_END`
        marker occurrences in the file. Caller enforces == 1.
      - `regex_matched`: True if the body-extraction regex
        `START\\s*\\n(.+?)\\n[^\\n]*END` successfully captured a block
        body. False if regex failed (e.g., END appears textually before
        START, START+END on the same line, no body between adjacent
        marker lines, or unusual whitespace prevents body capture).
        When markers are not exactly-once, `regex_matched` is False by
        short-circuit (the caller short-circuits on the marker check
        before consulting this field).
      - `body_has_content`: True iff the regex matched AND the captured
        body contains at least one non-empty, non-whitespace-only line.
        False when regex failed (no body to inspect) OR when regex
        matched but the body is whitespace-only.

    The caller uses the `(regex_matched, body_has_content, entries)`
    triple to distinguish three SHOULD-2 disambiguation cases:
      (i)   `regex_matched=False`: regex-shape-mismatch (markers exist
            exactly once but body capture failed).
      (ii)  `regex_matched=True`, `body_has_content=True`, `entries=[]`:
            regex-shape-mismatch within the entry-line shape (body has
            content but no line matches `#   <pack>  ->  <proj>`).
      (iii) `regex_matched=True`, `body_has_content=False`, `entries=[]`:
            genuinely-empty inventory (body is whitespace-only) —
            preserves pre-BD-180 "no parseable entries" diagnostic.

    Entry line format (one per line, between START/END):
      `#   <pack_relpath>  ->  <project_relpath>  [stage:<copy-site ids>]`

    Comment-only lines (e.g., header context) between START and END are
    skipped (must not contain `->`); empty lines and full-comment lines
    without `->` are ignored.

    Exactly-once contract: both markers MUST appear exactly once each.
    The header docstring for Check 41 promises `(a) START + END markers
    each appear exactly once`; this function enforces that contract by
    returning the raw counts so the caller can emit specific
    `"expected exactly one ..., found N"` failure messages and the
    validator FAILs rather than silently swallowing duplicate markers
    (the failure mode the exactly-once contract is meant to catch).
    """
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        return ([], 0, 0, False, False)
    text = init_sh.read_text()
    start_marker = "_CLIENT_INSTALLED_FILES_START"
    end_marker = "_CLIENT_INSTALLED_FILES_END"
    start_count = text.count(start_marker)
    end_count = text.count(end_marker)
    # Exactly-once contract: short-circuit if either count != 1.
    # Caller emits specific "expected exactly one, found N" failure.
    if start_count != 1 or end_count != 1:
        return ([], start_count, end_count, False, False)
    # Extract block body between START and END markers. The non-greedy
    # `(.+?)\n[^\n]*` capture stops at the END-marker line.
    m = re.search(
        rf"{re.escape(start_marker)}\s*\n(.+?)\n[^\n]*{re.escape(end_marker)}",
        text,
        re.DOTALL,
    )
    if not m:
        # Markers exist exactly once each, but the regex failed to
        # capture a body — e.g., END appears textually before START, or
        # START + END on the same line, or unusual whitespace (e.g.,
        # truly-empty body between adjacent marker lines also lands
        # here because the `.+?` capture requires at least one char).
        # Signal to caller via regex_matched=False so the caller can
        # emit the regex-shape-mismatch diagnostic.
        return ([], start_count, end_count, False, False)
    body = m.group(1)
    body_has_content = any(line.strip() for line in body.splitlines())
    entries: list[str] = []
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped or not stripped.startswith("#"):
            continue
        # Remove the leading `#` and surrounding whitespace.
        content = stripped.lstrip("#").strip()
        if "->" not in content:
            continue
        # Format: `<pack_relpath>  ->  <project_relpath>  [stage:...]`
        pack_rel = content.split("->", 1)[0].strip()
        if pack_rel:
            entries.append(pack_rel)
    return (entries, start_count, end_count, True, body_has_content)


def check_client_installed_files() -> None:
    """Check 41 — _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G).

    Verifies the `_CLIENT_INSTALLED_FILES_START`/`_END` block in
    `scripts/init-project.sh` is well-formed AND every entry maps to a
    real file at HEAD AND every cmd_update entry is named in the block
    (drift-prevention contract).

    Allowlist: `_CHECK_41_EXEMPTIONS` (default: empty) admits inventory
    entries whose source intentionally lives outside repo HEAD.

    Lenient mode: if `scripts/init-project.sh` is absent (unlikely;
    REPO_ROOT issue) the check skips with a notice.
    """
    print("\n── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──")
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return

    entries, start_count, end_count, regex_matched, body_has_content = (
        _parse_client_installed_files()
    )

    # Exactly-once marker contract (BD-180 SHOULD-1 hardening). Distinct
    # diagnostics for missing-marker (count 0) vs duplicate-marker
    # (count >= 2) so a future maintainer who copy-pastes the inventory
    # block during a refactor sees a clear "found N" failure rather
    # than silent first-marker-wins behaviour.
    if start_count != 1 or end_count != 1:
        marker_errors: list[str] = []
        if start_count == 0:
            marker_errors.append(
                "missing `_CLIENT_INSTALLED_FILES_START` marker in "
                "scripts/init-project.sh (found 0; expected exactly 1)"
            )
        elif start_count > 1:
            marker_errors.append(
                f"duplicate `_CLIENT_INSTALLED_FILES_START` marker in "
                f"scripts/init-project.sh (found {start_count}; "
                f"expected exactly 1)"
            )
        if end_count == 0:
            marker_errors.append(
                "missing `_CLIENT_INSTALLED_FILES_END` marker in "
                "scripts/init-project.sh (found 0; expected exactly 1)"
            )
        elif end_count > 1:
            marker_errors.append(
                f"duplicate `_CLIENT_INSTALLED_FILES_END` marker in "
                f"scripts/init-project.sh (found {end_count}; "
                f"expected exactly 1)"
            )
        fail(
            "self-documenting list marker contract violated: "
            + "; ".join(marker_errors)
            + ". The block must be delimited by exactly one "
            "`_CLIENT_INSTALLED_FILES_START` marker and exactly one "
            "`_CLIENT_INSTALLED_FILES_END` marker per ARCHITECTURE-BD-176.md "
            "§5.3 / BD-180 observation G. Remove any duplicate markers or "
            "add the missing marker(s)."
        )
        return

    # Markers are exactly-once; disambiguate the empty-entries failure
    # modes (BD-180 SHOULD-2 hardening). Three distinct cases per
    # parser-output triple `(regex_matched, body_has_content, entries)`:
    #   (i)   `regex_matched=False`: markers exist exactly once each but
    #         their relative position / shape (e.g., END appears
    #         textually before START, START+END on the same line, no
    #         body between adjacent marker lines, or unusual whitespace)
    #         prevents body capture. This is a regex-shape-mismatch at
    #         the BODY-CAPTURE level — surface the specific diagnostic
    #         with concrete likely-cause guidance.
    #   (ii)  `regex_matched=True`, `body_has_content=True`, `entries=[]`:
    #         body captured successfully and has non-empty content lines,
    #         but no line matched the expected entry-line shape (e.g.,
    #         garbage between markers, non-comment shell content,
    #         comment lines without `->` separator). This is a regex-
    #         shape-mismatch at the ENTRY-SHAPE level — surface the
    #         entry-shape diagnostic NOT the legacy "no parseable
    #         entries" message (the block has content but the wrong
    #         shape; "no parseable entries" would be misleading).
    #   (iii) `regex_matched=True`, `body_has_content=False`, `entries=[]`:
    #         body captured but is whitespace-only (e.g., a single
    #         indented line that captured as ` ` between markers).
    #         Inventory is genuinely empty per the consumer's view;
    #         surface the legacy "no parseable entries" diagnostic
    #         (preserved pre-BD-180 message).
    if not entries:
        if not regex_matched:
            fail(
                "scripts/init-project.sh has exactly one "
                "`_CLIENT_INSTALLED_FILES_START` and exactly one "
                "`_CLIENT_INSTALLED_FILES_END` marker, but the block "
                "body could not be captured — the regex pattern "
                "`START\\s*\\n(.+?)\\n[^\\n]*END` did not match. Likely "
                "causes: (a) END marker appears textually before the "
                "START marker, (b) START and END markers on the same "
                "line, (c) no body between adjacent marker lines, "
                "(d) unusual whitespace around the markers (e.g., "
                "missing trailing newline after START, or missing "
                "leading newline before END). Note on case (c): an "
                "empty inventory is not a supported state in Check 41 "
                "at HEAD; if the pack genuinely no longer installs "
                "files to clients, Check 41 requires contract redesign "
                "(see ARCHITECTURE-BD-176.md §5.3 for design intent). "
                "The check intentionally surfaces this state rather "
                "than silently passing. Restore the canonical marker "
                "shape per ARCHITECTURE-BD-176.md §5.3 / BD-180 "
                "observation G: each marker on its own comment line, "
                "START preceding END, with body content between them."
            )
            return
        if body_has_content:
            fail(
                "scripts/init-project.sh has `_CLIENT_INSTALLED_FILES_START`/"
                "`_END` markers and the block body was captured by the "
                "regex, but the block body could not be parsed into "
                "inventory entries — the body has content lines but no "
                "line matches the expected entry shape. Likely causes: "
                "(a) entry lines missing the `->` separator, (b) entry "
                "lines not commented (must start with `#`), (c) "
                "malformed whitespace around `->`, (d) non-inventory "
                "content (e.g., shell statements) between the markers. "
                "Each entry line must be of the form "
                "`#   <pack_relpath>  ->  <project_relpath>  [stage:...]` "
                "between the START/END markers per ARCHITECTURE-BD-176.md "
                "§5.3 / BD-180 observation G."
            )
            return
        # regex_matched=True, body_has_content=False: body is captured
        # but whitespace-only. Preserve the pre-BD-180 diagnostic shape
        # so existing tests / documentation references remain valid.
        fail(
            "scripts/init-project.sh has `_CLIENT_INSTALLED_FILES_START`/"
            "`_END` markers but the block contains no parseable entries. "
            "Each entry must be a comment line of the form "
            "`#   <pack_relpath>  ->  <project_relpath>  [stage:...]` "
            "between the START/END markers."
        )
        return

    any_failed = False

    # (c) Every entry's pack_relpath exists at HEAD.
    files_checked = 0
    exempted = 0
    for pack_rel in entries:
        files_checked += 1
        if (REPO_ROOT / pack_rel).is_file():
            continue
        if pack_rel in _CHECK_41_EXEMPTIONS:
            exempted += 1
            ok(
                f"{pack_rel} — exempt per _CHECK_41_EXEMPTIONS: "
                f"{_CHECK_41_EXEMPTIONS[pack_rel]}"
            )
            continue
        fail(
            f"{pack_rel} — `_CLIENT_INSTALLED_FILES` inventory entry "
            f"references a source file that does not exist at HEAD. "
            f"Either remove the entry from the inventory block in "
            f"scripts/init-project.sh (between `_CLIENT_INSTALLED_FILES_"
            f"START` and `_CLIENT_INSTALLED_FILES_END`), update the "
            f"path to match the actual source location, or — if the "
            f"source intentionally lives outside repo HEAD — add it to "
            f"`_CHECK_41_EXEMPTIONS` in scripts/validate-pack.py with a "
            f"one-line rationale."
        )
        any_failed = True

    # (d) Every cmd_update pack_relpath is listed in the inventory block.
    cmd_update_paths = _parse_cmd_update_entries()
    inventory_set = set(entries)
    missing_in_inventory = sorted(cmd_update_paths - inventory_set)
    inventory_drift = 0
    for pack_rel in missing_in_inventory:
        # Allow `_CHECK_41_EXEMPTIONS` to silence individual drifts (rare).
        if pack_rel in _CHECK_41_EXEMPTIONS:
            continue
        fail(
            f"{pack_rel} — `cmd_update` mapping exists but the path is "
            f"NOT listed in the `_CLIENT_INSTALLED_FILES_START`/`_END` "
            f"self-documenting inventory in scripts/init-project.sh. Add "
            f"an entry to the inventory block of the form "
            f"`#   {pack_rel}  ->  <project_relpath>  [stage:...]` so "
            f"the discoverability contract holds. Per ARCHITECTURE-BD-176.md "
            f"§5.3, the inventory must be the authoritative shipped-to-"
            f"clients reference."
        )
        inventory_drift += 1
        any_failed = True

    if not any_failed:
        ok(
            f"Check 41 — {files_checked} `_CLIENT_INSTALLED_FILES` entry "
            f"(entries) checked; {files_checked - exempted} resolve to "
            f"existing files at HEAD, {exempted} on exemption allowlist. "
            f"{len(cmd_update_paths)} cmd_update path(s) cross-checked "
            f"against inventory; {inventory_drift} drift(s) (must be 0). "
            f"Self-documenting list is consistent with copy-site state."
        )


# ── Check 42: CI workflow wires all per-check test files (BD-184) ──────────
#
# Closes the "missing test wiring" gap class permanently via a mechanical
# CI guard. The gap surfaced 5 times across the BD-175 batch alone:
#   - BD-179 FIX-1 (`1e644d1`): wired
#     `test-validate-pack-checks-36-37-38.sh` + `test-validate-pack-check-39.sh`
#     + `test-validate-pack-check-40.sh` (3 tests; unwired since BD-175
#     Commit 12, BD-175 F2a, BD-179 main respectively)
#   - BD-183 FIX-1 (`5f8f683`): wired `test-validate-pack-check-18.sh`
#     (unwired since BD-181 main `c244314`)
#   - BD-183 FIX-2 (`99b0f12`): wired `test-validate-pack-check-41.sh`
#     (unwired since BD-180 main `78a4415`)
#
# Each occurrence was caught by reviewer attention applying the BD-179
# FIX-5 (`ff23a00`) carry-forward discipline. The discipline works, but
# a mechanical guard at commit time is cheaper than per-cycle reviewer
# attention. Check 42 is that mechanical guard.
#
# Naming-form note: the per-check test convention permits BOTH single-
# check filenames (`test-validate-pack-check-NN.sh`; e.g.,
# `test-validate-pack-check-16.sh`, `test-validate-pack-check-39.sh`) and
# bundled-check filenames (`test-validate-pack-checks-NN-NN-NN.sh`; e.g.,
# `test-validate-pack-checks-32-33-34.sh`,
# `test-validate-pack-checks-36-37-38.sh`). The disk glob and the workflow
# grep BOTH use `test-validate-pack-check*` (without the trailing dash)
# so the prefix captures both `check-` AND `checks-` variants. A glob
# of `test-validate-pack-check-*.sh` (with dash) would silently miss the
# bundled form — empirically verified pre-implementation.
#
# Exemption: there is intentionally no exemption mechanism. Every
# `test-validate-pack-check*.sh` test file under `scripts/tests/` MUST
# have a corresponding `bash scripts/tests/<filename>` invocation in
# `.github/workflows/validate-pack.yml`. If a test is intentionally not
# wired (e.g., manual-trigger only), the workflow can wire it under an
# `if:` gate — but the wiring line MUST exist so Check 42 sees it.

def check_ci_workflow_wires_per_check_tests() -> None:
    """Check 42 — CI workflow wires all per-check test files (BD-184).

    Enumerates `scripts/tests/test-validate-pack-check*.sh` files on
    disk and compares against the set of `bash scripts/tests/test-
    validate-pack-check*.sh` invocations in
    `.github/workflows/validate-pack.yml`. Any test file existing on
    disk without a corresponding workflow invocation FAILs with the
    specific filename(s) named.

    Glob `test-validate-pack-check*.sh` (no trailing dash) matches BOTH
    single-check filenames (`test-validate-pack-check-NN.sh`) AND
    bundled-check filenames (`test-validate-pack-checks-NN-NN-NN.sh`).
    Reverse-direction (workflow invocations without disk files) is NOT
    a failure mode worth gating — a stale workflow line referencing a
    deleted test would fail the actual CI run loudly, so there is no
    silent-pass risk; the symmetric gate would add noise without
    catching new failure modes.

    Self-referential closure: Check 42 PASSing at HEAD depends on its
    OWN test (`test-validate-pack-check-42.sh`) being wired in the
    workflow yml. The BD-184 implementation ships the test + the
    wiring + this check together so the closure holds.

    Lenient mode: if `.github/workflows/validate-pack.yml` is absent
    (unlikely at any reasonable pack-repo HEAD) the check SKIPs with a
    notice; if `scripts/tests/` is absent the check SKIPs similarly.
    """
    print("\n── Check 42: CI workflow wires all per-check test files (BD-184) ──")
    workflow_path = REPO_ROOT / ".github" / "workflows" / "validate-pack.yml"
    tests_dir = REPO_ROOT / "scripts" / "tests"
    if not workflow_path.is_file():
        ok(".github/workflows/validate-pack.yml absent — skipping (lenient)")
        return
    if not tests_dir.is_dir():
        ok("scripts/tests/ absent — skipping (lenient)")
        return

    # Enumerate per-check test files on disk. Glob `check*` (no trailing
    # dash) catches both `check-NN.sh` and `checks-NN-NN-NN.sh` shapes.
    disk_tests = sorted(p.name for p in tests_dir.glob("test-validate-pack-check*.sh"))

    # Parse workflow yml for `bash scripts/tests/test-validate-pack-check*.sh`
    # invocation lines. Same prefix discipline as the disk glob — the
    # filename character class `[^\s]+` after the prefix captures both
    # single-check and bundled-check forms. The regex anchors on the
    # literal `bash scripts/tests/test-validate-pack-check` prefix so
    # commented-out or prose-mentioned occurrences (e.g., in workflow
    # comments) that lack the `bash ` lead and the `.sh` end are not
    # falsely counted. We deliberately do NOT require the line to be a
    # full `run:` step — counting any `bash scripts/tests/<file>.sh`
    # occurrence is sufficient because the workflow yml is the only
    # consumer of these test files in CI, and a non-`run:` occurrence
    # is implausible enough that surfacing it as evidence-of-wiring is
    # a tolerable trade-off vs. a stricter parser that would need yml
    # awareness.
    workflow_text = workflow_path.read_text()
    invocation_pattern = re.compile(
        r"bash\s+scripts/tests/(test-validate-pack-check[^\s]+\.sh)"
    )
    workflow_invocations = sorted(set(invocation_pattern.findall(workflow_text)))

    # Diff: tests on disk without a workflow invocation.
    disk_set = set(disk_tests)
    wired_set = set(workflow_invocations)
    unwired = sorted(disk_set - wired_set)

    if unwired:
        for filename in unwired:
            fail(
                f"scripts/tests/{filename} — per-check test file exists "
                f"on disk but has NO corresponding `bash scripts/tests/"
                f"{filename}` invocation in `.github/workflows/"
                f"validate-pack.yml`. Per BD-184, every test file "
                f"matching the glob `scripts/tests/test-validate-pack-"
                f"check*.sh` MUST be wired into the CI workflow so the "
                f"test runs on every push. Remediation: add a sister-"
                f"step under the `tests:` job in `.github/workflows/"
                f"validate-pack.yml` of the form:\n"
                f"      - name: validate-pack <Check NN> tests (BD-NNN, "
                f"<short description>)\n"
                f"        if: always()\n"
                f"        run: bash scripts/tests/{filename}\n"
                f"This check intentionally has no exemption mechanism — "
                f"if the test is intentionally not run in CI, wire it "
                f"under an `if:` gate rather than leaving it unwired."
            )
        return

    ok(
        f"Check 42 — {len(disk_tests)} per-check test file(s) on disk; "
        f"{len(workflow_invocations)} workflow invocation(s) found; "
        f"zero unwired tests. CI workflow wiring is complete."
    )


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
    # ── BD-183: Check 16 generalized with (trinity_root, label). Both
    # invocations run; pack-root short-circuits via the per-surface
    # exemption mechanism (`_CHECK_16_EXEMPT_SURFACES`) because Check 16
    # enforces template-only `## Project addenda` H2 infrastructure tied
    # to Procedure 5-C.2 client reconciliation, which has no purpose at
    # the non-reconciled pack-root surface. Exemption was BD-183 §2.4
    # Option (b), user-approved 2026-05-21. Per Override 9, both
    # invocations are independent.
    check_trinity_addenda_h2(REPO_ROOT / "project-template", "project-template")
    check_trinity_addenda_h2(REPO_ROOT, "pack-root")
    # ── BD-181: Check 18 H2 parity runs INDEPENDENTLY at each trinity
    # location. Per Override 9 compliance: pack-root and project-template
    # trinity carry different audiences and different rules by design
    # (per pack-root trinity § Rules → Trinity rule note paragraph).
    # Each invocation enforces byte parity WITHIN its own trinity
    # location only; there is NO cross-location parity gate.
    check_trinity_h2_parity(REPO_ROOT / "project-template", "project-template")
    check_trinity_h2_parity(REPO_ROOT, "pack-root")
    # ── BD-183: Check 19 generalized with (trinity_root, label). Empirical
    # pre-check at HEAD confirms pack-root trinity PASSES Check 19 (zero
    # HTML comments at pack-root → zero scaffolding to find). Both
    # invocations run independently per Override 9 — within-trinity
    # parity at each location; no cross-location coupling.
    check_trinity_no_scaffolding_comments(REPO_ROOT / "project-template", "project-template")
    check_trinity_no_scaffolding_comments(REPO_ROOT, "pack-root")
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
    check_skill_cell_consistency()
    # ── BD-168 (Batch 19, Commit 19e): per-entry split validators. ──
    # Order: 32 (mirror-in-sync) → 33 (TOC-in-sync) → 34 (cross-refs).
    # Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10. Each SKIPs
    # gracefully when the per-entry tree is absent (pre-BD-102
    # dog-food pack-self / pre-v11.0 client).
    check_mirror_in_sync()
    check_toc_in_sync()
    check_cross_reference_integrity()
    check_tracker_phase_task_invariants()
    # ── BD-175 Commit 12 (Architect C M5a/b/c): pack/project boundary
    # prevention. Order: 36 (commit-scope honesty) → 37 (project-side
    # deny-list) → 38 (pack-only-file siting). Check 37 lands LAST in
    # the boundary trio per C §13 bootstrap-incompatibility note — the
    # 17 §D-9 contamination refs from audit must be resolved by Commits
    # 4-9 before Check 37 is enabled, otherwise Check 37 FAILs at HEAD.
    check_commit_scope_honesty()
    check_project_side_deny_list()
    check_pack_only_file_siting()
    # ── BD-175 F2a: cmd_update mapping/glob symmetry. Lands AFTER
    # the M5a/b/c boundary trio so the boundary-prevention surface is
    # complete before the install-coverage gate runs.
    check_cmd_update_symmetry()
    # ── BD-179: pack-ops/ bare cross-reference scanner. Lands AFTER
    # the M5a/b/c boundary trio + Check 39 cmd_update symmetry so the
    # directory-boundary + install-coverage gates run before Check 40's
    # prose-cross-reference gate. Per ARCHITECTURE-BD-179.md §8.3, the
    # BD-179 commit qualifies all current bare-ref hits in pack-ops/*.md
    # so Check 40 PASSes at HEAD.
    check_bare_pack_ops_refs()
    # ── BD-180 observation G: _CLIENT_INSTALLED_FILES self-documenting
    # list integrity per ARCHITECTURE-BD-176.md §5.3. Lands AFTER Check 39
    # (the cmd_update parser is shared) and after Check 40 (independent
    # surfaces) so the install-coverage + cross-reference gates run
    # before the inventory-drift gate.
    check_client_installed_files()
    # ── BD-173 H.14: project-side bare cross-reference scanner
    # (V11 leak-sweep prevention; class-test counterpart to Check 37's
    # name-enumeration). Lands AFTER Check 40 (independent surface)
    # and AFTER Check 41 (reuses _parse_client_installed_files()) so
    # the inventory-drift gate runs before Check 43's class-test gate.
    # Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.1-§1.12.
    check_project_side_bare_internal_refs()
    # ── BD-184: CI workflow wires all per-check test files. Closes the
    # "missing test wiring" gap class permanently — surfaced 5 times in
    # the BD-175 batch alone (caught each time by reviewer attention).
    # Lands LAST in main() because it gates a CI infrastructure invariant
    # rather than any single pack-product surface; logical position is
    # end-of-list (mirrors Check 41's end-of-list landing for the
    # adjacent BD-180 inventory gate).
    check_ci_workflow_wires_per_check_tests()

    print("\n" + "=" * 60)
    if failures:
        print(f"FAILED — {len(failures)} issue(s) found")
        sys.exit(1)
    else:
        print("PASSED — all checks clean")
        sys.exit(0)


if __name__ == "__main__":
    main()
