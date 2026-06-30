"""validate_checks.agents_skills — Cluster C: the agent/skill inventory +
trinity-H2-parity + canonical-phrase + tracker/recommendation-config + skill-cell
family (BD-256 W4).

This module owns Cluster C's 8 check bodies (Checks 1, 5, 7, 18, 27, 29, 30, 31)
plus their intra-cluster helpers and constants — SKILL.md frontmatter (1), agent
file-count parity across the Claude/Codex/Antigravity-bundle surfaces (5), the
PM-CHAT pack agent roster (7), trinity H2-structure parity at a given location
(18, registered TWICE as a named lambda — project-template + pack-root), agent
canonical-phrase + Skills-to-load conformance (27), tracker.toml example schema +
mirror staleness (29), recommendation-state.json schema (30), and
PLATFORM-SKILLS.md skill-cell consistency (31).

Bodies are MOVED VERBATIM from the facade (`scripts/validate-pack.py`); the
facade re-exports every symbol here via `from validate_checks.agents_skills
import *`, so the registry assembled in the facade (`_build_check_registry()`)
keeps resolving each `check_*` name — including the Check-18 named-lambda
entries, which late-bind `check_trinity_h2_parity` from the facade globals it is
re-exported into. Single SSOT — no forked copy.

Intra-cluster symbols moved with the bodies (read only by Cluster C checks):
the agent/skill directory constants `SKILLS_DIR` / `CLAUDE_AGENTS_DIR` /
`CODEX_AGENTS_DIR` / `OPTIQUITY_BUNDLE_AGENTS_DIR`, `PM_CHAT`,
`REQUIRED_SKILL_FIELDS`, the profile rosters `READ_ONLY_AGENTS` /
`WRITE_SCOPED_AGENTS` / `WRITE_SCRIPT_AGENTS` + `COMMON_CANONICAL_PHRASES` /
`PROFILE_PHRASES` + the `_agent_profile` / `_extract_skills_to_load_section`
helpers, the tracker-config constants/helpers (`_TRACKER_MODES` /
`_TRACKER_PREFER` / `_TRACKER_SCHEMA_VERSION` / `_MIRROR_HEADER_TS_RE` +
`_validate_tracker_toml` / `_read_mirror_last_regenerated` /
`_check_mirror_staleness`), the recommendation-state schema constants
(`_REC_STATE_SCHEMA` / `_REC_STATE_SCHEMA_VERSION` / `_REC_STATE_SURFACES`), and
the skill-inventory constants/helper (`_INVENTORY_SUBSECTIONS` /
`_parse_inventory_subsection`).

Cross-module note (re-exported back to the facade): `SKILLS_DIR` /
`CLAUDE_AGENTS_DIR` / `OPTIQUITY_BUNDLE_AGENTS_DIR` are also read by the
facade-local load-time `PACK_SCAN_LOCATIONS` list (which Check 8 consumes;
Check 8 lands in `singletons` at W14). The facade's `from
validate_checks.agents_skills import *` is placed ABOVE that list so the bare
names resolve at facade load time — the same late-binding the registry relies
on. No core promotion is needed (these dirs are Cluster-C-owned, not a ≥2-module
seam).

Spine + seams: the spine symbols (`fail`, `ok`, `failures`) and the cross-module
seam this cluster reads (`REPO_ROOT`, `_TRACKER_BACKENDS`) are imported `from
.core` — the single SSOT for the spine + 8 W1 seams. (`_TRACKER_BACKENDS` is the
W1 seam Checks 29 here + the Check 80 twin both resolve by name. `failures` is
imported for the V3 failures-identity invariant — `core.failures is
agents_skills.failures` — matching the W2/W3 module convention; the Cluster C
bodies append via `fail()`, never rebind `failures`.)

See `scripts/lib/validate_checks/README.md` and
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
"""

import json
import re
import subprocess
import tomllib
from pathlib import Path

from .core import (
    REPO_ROOT,
    fail,
    ok,
    failures,
    _TRACKER_BACKENDS,
    OPTIQUITY_BUNDLE_AGENTS_DIR,
)


SKILLS_DIR = REPO_ROOT / "project-template" / "skills"

CLAUDE_AGENTS_DIR = REPO_ROOT / "project-template" / ".claude" / "agents"
CODEX_AGENTS_DIR = REPO_ROOT / "project-template" / ".codex" / "agents"
# BD-221: the third agent surface is the Antigravity client plugin bundle
# (the 16-agent optiquity-agents roster). Checks 5 (count parity) and 27
# (canonical phrases) scan this bundle so the Antigravity agents are covered
# with no silent loss. BD-256 W14: `OPTIQUITY_BUNDLE_AGENTS_DIR` is now a
# ≥2-module seam (this cluster's Checks 5/27 + singletons's Check 8 via
# PACK_SCAN_LOCATIONS), so it is PROMOTED to `core` (MUST-4) and imported
# `from .core` above; it is kept in this module's `__all__` below so the
# facade's existing re-export surface is byte-stable (no test that reaches
# `mod.OPTIQUITY_BUNDLE_AGENTS_DIR` regresses).

REQUIRED_SKILL_FIELDS = {"name", "description", "allowed-tools"}

PM_CHAT = REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md"


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
            continue

        # BD-221 (folded from retired Check 21, OQ-C): the pooled `pack-help`
        # skill body MUST reference `scripts/pack-help.sh` so the skill actually
        # invokes the pack-help shell when an agent runs it.
        if skill_dir.name == "pack-help" and "pack-help.sh" not in content:
            fail(
                f"skills/{skill_dir.name}/SKILL.md — pack-help skill does not "
                f"reference `scripts/pack-help.sh` (the body must invoke the "
                f"pack-help shell; folded from retired Check 21 per BD-221)"
            )
            continue

        ok(f"skills/{skill_dir.name}/SKILL.md")


# ── Check 5: Agent file count consistency ───────────────────────────────────

def check_agent_count() -> None:
    # BD-221 (Antigravity conversion): the third leg is the Antigravity client
    # plugin bundle (optiquity-agents). The check is Claude↔Codex loose-agent
    # 2-way parity PLUS plugin-roster count parity (the bundle ships the same
    # named roster).
    print("\n── Check 5: Agent file count consistency ──")
    claude_agents = sorted(CLAUDE_AGENTS_DIR.glob("*.md")) if CLAUDE_AGENTS_DIR.is_dir() else []
    codex_agents = sorted(CODEX_AGENTS_DIR.glob("*.toml")) if CODEX_AGENTS_DIR.is_dir() else []
    bundle_agents = (
        sorted(OPTIQUITY_BUNDLE_AGENTS_DIR.glob("*.md"))
        if OPTIQUITY_BUNDLE_AGENTS_DIR.is_dir() else []
    )

    claude_count = len(claude_agents)
    codex_count = len(codex_agents)
    bundle_count = len(bundle_agents)

    if claude_count == 0:
        fail("No Claude agent files found in project-template/.claude/agents/")
    if codex_count == 0:
        fail("No Codex agent files found in project-template/.codex/agents/")
    if bundle_count == 0:
        fail(
            "No agent files found in the Antigravity client plugin bundle "
            "project-template/.agents-plugin/optiquity-agents/agents/"
        )

    if claude_count == codex_count == bundle_count:
        ok(f"Claude agents: {claude_count}, Codex agents: {codex_count}, "
           f"Antigravity bundle agents: {bundle_count} — match")
    else:
        fail(f"Agent count mismatch — Claude: {claude_count}, "
             f"Codex: {codex_count}, Antigravity bundle: {bundle_count}")

    # Also check name correspondence. The bundle roster must carry the same
    # 16 agent names as the loose Claude/Codex surfaces (plugin-roster parity).
    claude_names = {p.stem for p in claude_agents}
    codex_names = {p.stem for p in codex_agents}
    bundle_names = {p.stem for p in bundle_agents}
    only_claude = claude_names - codex_names - bundle_names
    only_codex = codex_names - claude_names - bundle_names
    only_bundle = bundle_names - claude_names - codex_names
    missing_from_codex = claude_names - codex_names
    missing_from_bundle = claude_names - bundle_names
    if only_claude:
        fail(f"Agents only in Claude: {sorted(only_claude)}")
    if only_codex:
        fail(f"Agents only in Codex: {sorted(only_codex)}")
    if only_bundle:
        fail(f"Agents only in the Antigravity bundle: {sorted(only_bundle)}")
    if missing_from_codex:
        fail(f"Agents in Claude but not Codex: {sorted(missing_from_codex)}")
    if missing_from_bundle:
        fail(f"Agents in Claude but not the Antigravity bundle: {sorted(missing_from_bundle)}")


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


def check_trinity_h2_parity(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
    """Check 18 — trinity templates have matching H2 structure at a given location.

    CLAUDE.md, AGENTS.md, GEMINI.md must agree on H2 names and order
    WITHIN their trinity location. The trinity rule applies — symmetry
    is the default. The only allowed asymmetry is tool-intrinsic
    content. GEMINI.md is permitted to add these specific H2s (and only
    these): `## Agent roster`, `## Antigravity CLI operating notes`. Any
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
    GEMINI_INTRINSIC_H2S = {"## Agent roster", "## Antigravity CLI operating notes"}
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

    # GEMINI.md must equal CLAUDE *modulo* the allowed GEMINI.md-intrinsic H2s.
    gemini_filtered = [h for h in gemini if h not in GEMINI_INTRINSIC_H2S]
    if gemini_filtered != claude:
        fail(
            f"[{label}] GEMINI.md H2 structure diverges from CLAUDE.md/AGENTS.md "
            "beyond the allowed GEMINI.md-intrinsic H2s "
            f"({sorted(GEMINI_INTRINSIC_H2S)}):"
        )
        in_claude = [h for h in claude if h not in gemini_filtered]
        in_gemini = [h for h in gemini_filtered if h not in claude]
        for h in in_claude:
            fail(f"  in {label}/CLAUDE.md/AGENTS.md only: {h}")
        for h in in_gemini:
            fail(f"  in {label}/GEMINI.md only (and not in allowed-intrinsic set): {h}")
        return

    # Check that the GEMINI.md-intrinsic H2s, if present, are positioned
    # at the documented insertion points (after Phase routing for
    # `Agent roster`; after Agent behavior for
    # `Antigravity CLI operating notes`).
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
    # BD-221 (Antigravity conversion, MUST-1): the third leg is the
    # Antigravity client plugin bundle (optiquity-agents) — so the Antigravity
    # bundle agents are scanned for the canonical permission-profile phrases
    # with no silent coverage loss.
    agent_dirs = [
        (CLAUDE_AGENTS_DIR, "*.md"),
        (CODEX_AGENTS_DIR, "*.toml"),
        (OPTIQUITY_BUNDLE_AGENTS_DIR, "*.md"),
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


_TRACKER_MODES = ("flat-file", "tracker")
_TRACKER_PREFER = ("gh", "mcp", "auto")
_TRACKER_SCHEMA_VERSION = 1


def _validate_tracker_toml(path: Path, expected_prefix: str,
                           mirror_required: bool) -> bool:
    """Validate a single tracker.toml example file.

    Returns True on PASS, False on FAIL. Records each failure via
    `fail()` with file path + key + expected vs actual context so the
    message names exactly what diverges.

    `expected_prefix` is the [id_namespace].prefix value the example
    file is supposed to ship with — "BD" for the pack-side example,
    "TD" for the client-side example.

    `mirror_required` is the per-surface [mirror] requirement (BD-204):
    False on both surfaces — no surface keeps a monolith mirror (the
    per-entry tree + `_toc.md` is the sole SSOT and readable form), so a
    [mirror] table's absence is valid-by-construction. When the table IS
    present, its keys are validated on either surface.
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

    # [mirror] table — optional on both surfaces (no monolith mirror on
    # either surface; the no-monolith shape omits it entirely). When
    # present (either surface), the table and its operational keys are
    # validated as before.
    mirror = None
    if mirror_required or "mirror" in data:
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

    # BD-204 Check 29′ — no-mirror surface guard (measure-then-bound).
    # The Mode-3 pack live tracker.toml omits the [mirror] table (no
    # monolith to point at). When the live config has NO [mirror] table
    # OR mirror.enabled is false/absent, staleness is N/A — soft-pass,
    # exactly as flat-file mode does above. A config that DECLARES
    # [mirror] enabled=true but is missing the file falls through to the
    # staleness branches below and still FAILs (guard does not widen).
    if "mirror" not in cfg or not cfg.get("mirror", {}).get("enabled"):
        ok(f"{rel} — no [mirror] table / mirror disabled — no-mirror "
           "surface, mirror-staleness check N/A")
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
    `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1. The [mirror]
    table requirement is per-surface (BD-204): required on the client
    example, optional-by-construction on the pack example (the pack
    deleted its monolith mirrors at BD-203).

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

    Check 29″ (BD-204 local-opt-in model,
    ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md §B7): the
    live `tracker.toml` must NEVER be git-tracked at the pack root.
    The repo's committed state is always flat-file — tracker mode is a
    per-checkout LOCAL opt-in carried by a gitignored root
    `/tracker.toml` — so a TRACKED `tracker.toml` would ship a
    tracker-mode default to every checkout. FAILs when
    `git ls-files --error-unmatch tracker.toml` succeeds; soft-passes
    when the file is absent, untracked, or REPO_ROOT is not a git
    work tree (per-check fixture runs).
    """
    print("\n── Check 29: Tracker-config schema (BD-078) ──")
    pack_example = REPO_ROOT / "tracker.toml.pack-example"
    client_example = REPO_ROOT / "project-template" / "tracker.toml.project-example"

    # mirror_required is False on both surfaces: no surface keeps a
    # monolith mirror (the per-entry tree + `_toc.md` is the sole SSOT
    # and readable form). When a [mirror] table IS present, its keys are
    # still validated.
    _validate_tracker_toml(pack_example, expected_prefix="BD",
                           mirror_required=False)
    _validate_tracker_toml(client_example, expected_prefix="TD",
                           mirror_required=False)

    # V1 §A.2 acceptance criterion B — mirror-staleness warning when
    # a live tracker.toml exists, mode is tracker, and forward
    # migration completed. Soft-pass otherwise.
    live_cfg = REPO_ROOT / "tracker.toml"
    if live_cfg.is_file():
        _check_mirror_staleness(live_cfg)
    else:
        ok("tracker.toml absent at pack root — mirror-staleness "
           "leg soft-passes (lazy-create is by design)")

    # Check 29″ — never-tracked leg (BD-204 local-opt-in model). The
    # CI realization of "the repo's committed state is always
    # flat-file": a git-TRACKED root tracker.toml is a hard FAIL.
    # `git ls-files --error-unmatch` rc==0 means TRACKED; any non-zero
    # rc (file absent, untracked, not a git work tree) soft-passes.
    try:
        proc = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "ls-files",
             "--error-unmatch", "tracker.toml"],
            capture_output=True, text=True)
        tracked = (proc.returncode == 0)
    except Exception:
        tracked = False
    if tracked:
        fail("tracker.toml is git-TRACKED at the pack root — the "
             "pack's committed state is always flat-file; tracker "
             "mode is a per-checkout LOCAL opt-in and `tracker.toml` "
             "is gitignored (BD-204). Untrack it: "
             "`git rm --cached tracker.toml`")
    else:
        ok("tracker.toml is not git-tracked at the pack root "
           "(local-opt-in contract holds — Check 29″)")


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


__all__ = [
    "SKILLS_DIR",
    "CLAUDE_AGENTS_DIR",
    "CODEX_AGENTS_DIR",
    "OPTIQUITY_BUNDLE_AGENTS_DIR",
    "REQUIRED_SKILL_FIELDS",
    "PM_CHAT",
    "check_skill_frontmatter",
    "check_agent_count",
    "check_pack_agent_roster",
    "check_trinity_h2_parity",
    "READ_ONLY_AGENTS",
    "WRITE_SCOPED_AGENTS",
    "WRITE_SCRIPT_AGENTS",
    "COMMON_CANONICAL_PHRASES",
    "PROFILE_PHRASES",
    "_agent_profile",
    "check_agent_canonical_phrases",
    "_extract_skills_to_load_section",
    "_TRACKER_MODES",
    "_TRACKER_PREFER",
    "_TRACKER_SCHEMA_VERSION",
    "_validate_tracker_toml",
    "_MIRROR_HEADER_TS_RE",
    "_read_mirror_last_regenerated",
    "_check_mirror_staleness",
    "check_tracker_config",
    "_REC_STATE_SCHEMA",
    "_REC_STATE_SCHEMA_VERSION",
    "_REC_STATE_SURFACES",
    "check_recommendation_state_schema",
    "_INVENTORY_SUBSECTIONS",
    "_parse_inventory_subsection",
    "check_skill_cell_consistency",
]
