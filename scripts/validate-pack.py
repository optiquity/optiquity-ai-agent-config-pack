#!/usr/bin/env python3
"""
Pack structural validation — runs locally and in GitHub Actions.

Checks:
  1. SKILL.md frontmatter: required fields present in every skill file
  2. Codex TOML files: all parse correctly
  3. TD-TBD sentinels: none in committed files (excluding docs that show the format)
  4. README version table: latest row matches latest git tag
  5. Agent file count: Claude, Codex, and Gemini agent dirs have the same count

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

    print("\n" + "=" * 60)
    if failures:
        print(f"FAILED — {len(failures)} issue(s) found")
        sys.exit(1)
    else:
        print("PASSED — all checks clean")
        sys.exit(0)


if __name__ == "__main__":
    main()
