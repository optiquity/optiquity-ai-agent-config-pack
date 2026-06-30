#!/usr/bin/env python3
"""
Pack structural validation — runs locally and in GitHub Actions.

Checks:
  1. SKILL.md frontmatter: required fields present in every skill file
  2. Codex TOML files: all parse correctly
  3. TD-TBD sentinels: none in committed files (excluding docs that show the format)
  4. README version table: latest row matches latest git tag
  5. Agent file count: Claude, Codex loose dirs + the Antigravity agent bundle have the same count
  6. Prompts-directory format: per-agent frontmatter, variant→H2 consistency
     (PROMPT-AUTHORING.md was removed in v10.0; directory guidance lives in
     supporting-docs/METHODOLOGY.md § Prompt Authoring Principles)
  7. Pack agent roster: PM-CHAT.md ## Pack agent roster list matches
     .claude/agents/*.md stems
  8. Reserved x- prefix: no file or directory in the pack scan
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
      agent file content stays in lockstep across .claude/.codex + the
      Antigravity pack-agents plugin bundle (BD-082-era informational
      guard).
  16. Trinity ## Project addenda H2 (BD-059): v10 trinity templates
      carry the `## Project addenda` H2 anchor required by Procedure
      5-S Task B.
  17. Tool-config AGENT_CAPABILITIES parity (BD-059): the
      AGENT_CAPABILITIES table is expressed identically across the
      Claude and Codex tool-config surfaces
      (`.claude/settings.json`, `.codex/config.toml`).
  18. Trinity H2 structure parity (BD-059): CLAUDE.md, AGENTS.md, and
      GEMINI.md (project-template) share the same `##` heading
      sequence, modulo provably tool-specific sections.
  19. Trinity templates free of body scaffolding (BD-059): v10 trinity
      templates do not carry stale fresh-install scaffolding
      comments that should have been pruned.
  20. Pack .gitignore !.env.example exception (BD-059): pack-template
      .gitignore retains the `!.env.example` re-include after the
      `*.env*` ignore pattern.
  21. [RETIRED in BD-221 — Antigravity conversion] Pack-help per-CLI
      parity (BD-082). pack-help is now an ordinary pooled skill
      distributed loose to all CLIs; the "references scripts/pack-help.sh"
      assertion folded into Check 1 (SKILL.md frontmatter). The check
      number is intentionally NOT renumbered.
  22. Help-fragment freshness (BD-082): every verb that pack prose
      references is present in the HELP-FRAGMENT shared content,
      pack-side and project-template-side.
  23. Help-fragment completeness (BD-082): every non-internal
      executable under `scripts/` is listed in
      `HELP-FRAGMENT-PACK.md` (and pack-internal scripts are marked
      `pack-internal: true`).
  24. [RETIRED in BD-194 — see ARCHITECTURE-BD-194.md] Help-fragment
      cross-surface byte-identity; superseded by Check 22 + Check 23 +
      Check 41 per-surface coverage.
  25. Customization-detection regression guard (BD-089): the
      customization-preserve fixture set produces the expected
      disposition + class for every fixture row, and the truthful
      report contract holds.
  26. BD-119 migrator-framework inventory: scripts/lib/migrator-core.sh
      (when present) is shell-syntax-valid and exposes the documented
      public-API function names + exit-code constants per
      ARCHITECTURE-BD-119.md §3.2 / PLAN-BD-119.md §3.
  27. Agent canonical-phrase compliance (v10.1): every project-template
      agent definition (.claude/.codex loose dirs + the Antigravity
      optiquity-agents plugin bundle × 16 agents) contains the
      canonical phrases for Permission profile, Output policy, and
      Hard rules — codified per profile (Read-only / Write-capable
      scoped / Write-capable script).
  28. [RETIRED in BD-221 — Antigravity conversion] PM-startup per-CLI
      parity (v10.1, BD-126). pm-startup collapsed to a single pooled
      `project-template/skills/pm-startup/SKILL.md` SSOT distributed
      loose to all CLIs; the per-CLI byte-parity surfaces no longer
      exist. The check number is intentionally NOT renumbered.
  29. Tracker-config schema (BD-078): the pack-side
      `tracker.toml.pack-example` and the client-side
      `project-template/tracker.toml.project-example` parse as TOML
      and carry the required keys/types per
      `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1
      (`schema_version`, `[backend].name`, `[backend].repo`, `[mode].state`,
      `[mirror]` (per-surface, BD-204: required on the client example;
      optional/omitted on the no-monolith pack example),
      `[id_namespace].prefix`, `[cli_acceleration].prefer`,
      `[migration].forward_complete`, `[migration].reverse_available`,
      `[migration].mapping_file`). Catches schema drift in the
      example files that ship to clients via init-project.sh.
      Check 29″ (BD-204 local-opt-in model): FAILs if a live
      `tracker.toml` is ever git-TRACKED at the pack root — the pack's
      committed state is always flat-file; tracker mode is a
      per-checkout LOCAL opt-in (`/tracker.toml` is root-anchored
      gitignored). Probed via `git ls-files --error-unmatch`;
      soft-passes when the root is not a git work tree.
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
  32. No pack monolith exists — Check 32′ (BD-203 no-mirror inversion of
      the BD-168 Check 32): for each pack-side per-entry stream
      (`backlog/`, `changelog/`), assert the former monolith
      (`pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`) is ABSENT — under
      the no-mirror model the per-entry tree (+ `_toc.md`) is the SOLE
      source of truth; the monolith is a deleted conversion-input, NOT a
      regenerated mirror. Also assert `_rules.md` + `_toc.md` are present
      and per-entry filenames conform, and (BD-204 Mode-3 ops contract)
      that each pack stream's `_rules.md` carries its required mode
      marker ("Flat-file mode" for `backlog/`; "Mode invariance" for
      `changelog/`) — marker presence only.
      SKIPs when the per-entry tree is
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
      Self-references are exempt; supporting files (leading-underscore
      basenames such as `_toc.md`) are not walked. (The former
      `_v8-resolved-archive.md` SKIP is DEAD post-BD-203 B8 — the
      BD-001..019 entries are now normal per-entry files, so no
      v8-archive supporting file is emitted.) SKIPs when no per-entry
      tree exists.
  35. Phase-task lib invariants (BD-106 / V3.3 §3 line 27): renumbered
      from Check 32 in BD-168 to make room for the per-entry split
      validators. `scripts/lib/tracker-phase-task.sh` exists;
      `tracker_labels_folded_into` is NOT defined in
      `scripts/lib/tracker-labels.sh`; the literal `folded-into` does
      NOT appear in executable code under `scripts/lib/`.
  36. Commit-scope honesty (BD-175 M5a per Architect C §8.1): for each
      commit in the walk range (`origin/main..HEAD` with fallbacks),
      parses the commit subject for scope keywords (`pack-only`,
      `project-only`, `pack-chat-only`) and verifies the
      commit's touched paths match the claimed scope. pack-chat-only PERMITTED-
      PATHS come from `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
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
      except the deleted-monolith basenames (`pack-ops/BACKLOG.md` /
      `pack-ops/CHANGELOG.md`) — a defensive exemption retained post-BD-203
      so the scan never matches the conversion-input monoliths (there is
      no regenerated mirror under the no-mirror model) — and flags
      backtick-delimited filename
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
  42. CI test-wiring allowlist is valid + bounded (BD-184, BD-219
      redesign): RE-SCOPED. The CI `tests` matrix is now disk-derived
      at run time (the `plan` job's `ci-shard-plan.py --emit-matrix`),
      so `wired_set == disk_KEEP_set` by construction and the old
      `disk_KEEP_set == wired_set` equality is a tautology with no
      failure mode (the "missing test wiring" gap is eliminated by
      construction). Check 42 now asserts (1) ALLOWLIST VALIDITY —
      every `scripts/ci-test-wiring-allowlist.txt` entry exists on
      disk AND matches the disk-glob shape ({`scripts/test*.sh` +
      `scripts/tests/*.sh` + `scripts/tests/fixture-dependent/*.sh`});
      and (2) PARTITIONABILITY — the disk KEEP set (disk glob minus
      allowlist) is non-empty. Fails naming a stale (not-on-disk),
      malformed (wrong-shape), or all-swallowing allowlist.

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

import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import tomllib
from pathlib import Path

# ── BD-256 facade import glue ───────────────────────────────────────────────
#
# scripts/validate-pack.py is the frozen CI entrypoint and is now a thin facade
# over the scripts/lib/validate_checks package. Make the directory that holds
# the package (the sibling `lib/` of this file) importable regardless of cwd, so
# BOTH `python3 scripts/validate-pack.py` from any directory AND the tests'
# spec_from_file_location()+exec_module() import path resolve `import
# validate_checks`. resolve() makes this robust to a relative __file__.
#
# W1: the facade now CONSUMES the package — `from validate_checks.core import *`
# re-imports the shared spine (`REPO_ROOT`, `failures`, `fail`/`ok`/`warn`,
# `run_check`, `_check_timings`, the `RUN_CHECK_*` budgets,
# `CHECK_REGISTRY_EXPECTED_COUNT`) and the 8 cross-module seams (`STREAMS`,
# `README`, `_session_state_load` + `_SESSION_STATE_*`,
# `_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES`, `_TRACKER_BACKENDS`,
# `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`), which now live ONLY
# in `core.py` (single SSOT, no forked copy). This star-import is placed ABOVE
# the first use (the still-inline `check_*` bodies, `_build_check_registry()`,
# and `main()`), so every bare reference to those names in the still-inline code
# resolves from core. It is the facade's first UNGUARDED package consumer — the
# package MUST be reachable on every real invocation path (it is co-located with
# the facade under `scripts/lib/`).
#
# The W0 guarded `import validate_checks` is retained as-is below (it tolerated a
# standalone copy of the facade with no sibling `lib/`). The check-49/50
# single-source teeth that exec such a copy now land the copy BESIDE a real
# `lib/` (BD-256 W1 SHOULD-1 test-49 fix), so the unguarded core import resolves
# there too.
_VALIDATE_CHECKS_LIB = Path(__file__).resolve().parent / "lib"
if _VALIDATE_CHECKS_LIB.is_dir() and str(_VALIDATE_CHECKS_LIB) not in sys.path:
    sys.path.insert(0, str(_VALIDATE_CHECKS_LIB))
try:
    import validate_checks  # noqa: E402,F401  (package marker; bodies land per-wave)
except ModuleNotFoundError:
    # A standalone copy of this facade (no sibling validate_checks package) — the
    # package is legitimately absent. Tolerated so copied-facade test idioms load.
    pass
# UNGUARDED: the facade consumes the spine + seams; they live only in core now.
from validate_checks.core import *  # noqa: E402,F403  (spine + 8 seams; single SSOT)
from validate_checks import core  # noqa: E402,F401  (V3 failures-identity handle)

# W2 (BD-256): the facade re-exports Cluster A (the boundary / cross-reference /
# operating-doc / deny-list family — Checks 35-41,43,47,65,67-71) now extracted
# to validate_checks.boundary_refs. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references resolve. Single SSOT — the bodies live
# only in boundary_refs.py; the facade carries no forked copy.
from validate_checks.boundary_refs import *  # noqa: E402,F403  (Cluster A; single SSOT)

# W3 (BD-256): the facade re-exports Cluster B (the RW/RO + git-verb-parity +
# project-template-shape + immutable-integrity family — Checks 50-57,72-76) now
# extracted to validate_checks.discipline_parity. Placed ABOVE
# _build_check_registry() so the registry's bare `check_*` references resolve.
# Single SSOT — the bodies live only in discipline_parity.py; the facade carries
# no forked copy.
from validate_checks.discipline_parity import *  # noqa: E402,F403  (Cluster B; single SSOT)

# W4 (BD-256): the facade re-exports Cluster C (the agent/skill inventory +
# trinity-H2-parity + canonical-phrase + tracker/recommendation-config +
# skill-cell family — Checks 1,5,7,18,27,29,30,31) now extracted to
# validate_checks.agents_skills. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references resolve — including the Check-18 named
# lambdas (`check_trinity_h2_parity`), which late-bind it from these re-exported
# globals. Placed ABOVE the load-time `PACK_SCAN_LOCATIONS` list below so the
# re-exported agent/skill directory constants (`SKILLS_DIR`, `CLAUDE_AGENTS_DIR`,
# `OPTIQUITY_BUNDLE_AGENTS_DIR`) resolve when that facade-local list (Check 8's
# input; Check 8 lands in singletons at W14) is built. Single SSOT — the bodies
# live only in agents_skills.py; the facade carries no forked copy.
from validate_checks.agents_skills import *  # noqa: E402,F403  (Cluster C; single SSOT)

# W5 (BD-256): the facade re-exports Cluster D (the doc-concision / anti-restate
# / pointer-manifest family — Checks 45,46,44,66) now extracted to
# validate_checks.doc_concision. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references resolve. The cluster reads the W2
# cross-module helper `_parse_manifest_records` from core (Check 46 manifest
# parse + Check 44/66 allowlist-file reads). Single SSOT — the bodies live only
# in doc_concision.py; the facade carries no forked copy.
from validate_checks.doc_concision import *  # noqa: E402,F403  (Cluster D; single SSOT)

# ── Check 48 (BD-195 C6): JC-5 soft-advisory removed-doc guard ─────────────
# Frozen measure-then-bound set (PLAN-BD-195-REMEDIATION.md §2.3 Step-1):
# basenames of docs REMOVED from the repo that are still cited (as accurate
# v8/v9 + process history). Each was verified ABSENT from the tree at design
# time (`find . -name <name>` → 0). The guard WARNs (never fail()s) on each
# occurrence so the accurate-history citations surface without breaking CI
# (JC-5: NO hand-correction).
#
# BD-203 A12: the accurate-history citations relocate from the two deleted
# monoliths INTO the per-entry trees, so the scan is REPOINTED to walk the
# `/backlog/` + `/changelog/` per-entry directories (every `*.md` entry +
# supporting file). SKIP-on-absent is preserved (the trees are absent
# pre-conversion), so Check 48 reports 0 hits cleanly at the pre-conversion
# state. No full-repo walk — scoped to the two tree dirs.
_REMOVED_DOC_BASENAMES = (
    "GEMINI-CLI-ANALYSIS.md",
    "ANDROID-ANALYSIS.md",
    "V10-PREDESIGN.md",
    "ARCHITECTURE-BD-185.md",
    "PLAN-BD-185.md",
)
_REMOVED_DOC_SCAN_DIRS = (
    "changelog",
    "backlog",
)

PER_ENTRY_LIB = REPO_ROOT / "scripts" / "lib" / "per-entry"
CODEX_DIR = REPO_ROOT / "project-template" / ".codex"
# SKILLS_DIR / CLAUDE_AGENTS_DIR / CODEX_AGENTS_DIR / OPTIQUITY_BUNDLE_AGENTS_DIR /
# REQUIRED_SKILL_FIELDS / PM_CHAT moved to validate_checks.agents_skills (BD-256
# W4 — Cluster C intra-cluster) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above. The bare `OPTIQUITY_BUNDLE_AGENTS_DIR`
# reference in the load-time `PACK_SCAN_LOCATIONS` list below resolves from that
# re-import (placed above this point).
# README moved to validate_checks.core (BD-256 W1 seam) — re-imported via the
# facade's `from validate_checks.core import *` above (derives from REPO_ROOT).

PROMPTS_DIR = REPO_ROOT / "project-template" / "docs" / "pack" / "prompts"
REQUIRED_PROMPT_FRONTMATTER = {"agent", "variants"}
RESERVED_PROMPT_FRONTMATTER = {"description", "deprecated-by", "notes"}

# BD-221 (Antigravity conversion): the pack-template agent/skill surfaces a
# reserved-`x-` file could legitimately live in. The Antigravity end-state
# surfaces are the loose Claude/Codex agent dirs, the client agent bundle
# (optiquity-agents), and the shared skills POOL (`project-template/skills`,
# distributed loose to all CLIs by init-project), plus the prompts dir.
# Non-existent dirs are skipped (Check 8 `loc.is_dir()`).
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

# The pack repo is mostly templates and documentation, where TD-TBD appears
# as a FORMAT EXAMPLE (teaching downstream projects the deferral syntax).
# The only meaningful TD-TBD check in the pack is: does any `/backlog/*.md`
# per-entry file (BD-203 no-mirror SSOT) have an entry where TD-TBD appears
# where a real BD-NNN number should be?
# The broader "no TD-TBD in committed code" check is for downstream projects.

# ── Spine moved to validate_checks.core (BD-256 W1) ─────────────────────────
# `failures`, `fail`/`ok`/`warn`, the `RUN_CHECK_*` budget constants,
# `CHECK_REGISTRY_EXPECTED_COUNT`, `_check_timings`, and `run_check` now live
# ONLY in `scripts/lib/validate_checks/core.py` (single SSOT, no forked copy).
# They are re-imported via the facade's `from validate_checks.core import *`
# above, so every bare reference below + in `_build_check_registry()` / `main()`
# resolves from core. The RUNTIME-BUDGET GUARD rationale (BD-204 §4.7) and the
# BD-219 C3 CHECK_REGISTRY_EXPECTED_COUNT derivation comment travel with the
# definitions in core.py.


# ── Check 1 (check_skill_frontmatter) moved to validate_checks.agents_skills
# (BD-256 W4 — Cluster C) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above (single SSOT, no forked copy). ──


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
    # bounded allowlist (alpha/beta lowercase, RC numbered, GA uppercase).
    # `[\d.]+` already covers the optional `.PATCH` segment.
    content = README.read_text()
    version_rows = re.findall(
        r"^\|\s*(v[\d.]+(?:\s*\((?:alpha|beta|RC\d+|GA)\))?)\s*\|",
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
        r"\s*\((alpha|beta|RC\d+|GA)\)$", r"-\1", readme_version)

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


# ── Check 5 (check_agent_count) moved to validate_checks.agents_skills
# (BD-256 W4 — Cluster C) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above (single SSOT, no forked copy). ──


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


# ── Check 7 (check_pack_agent_roster) moved to validate_checks.agents_skills
# (BD-256 W4 — Cluster C) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above (single SSOT, no forked copy). ──


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

    Per BD-059 success criterion #7, every pack-roster agent ships in
    parallel across the tools (.claude/.md, .codex/.toml, and the
    Antigravity pack-agents plugin bundle .md). The trinity rule says
    behavioral content must match unless a divergence is provably
    tool-specific.

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


# ── Checks 18 (check_trinity_h2_parity) + 27 (check_agent_canonical_phrases),
# their profile rosters (READ_ONLY_AGENTS / WRITE_SCOPED_AGENTS /
# WRITE_SCRIPT_AGENTS / COMMON_CANONICAL_PHRASES / PROFILE_PHRASES) + the
# _agent_profile / _extract_skills_to_load_section helpers moved to
# validate_checks.agents_skills (BD-256 W4 — Cluster C) — re-imported via the
# facade's `from validate_checks.agents_skills import *` above. The Check-18
# named-lambda registry entries late-bind `check_trinity_h2_parity` from those
# re-exported globals (single SSOT, no forked copy). ──


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


# ── Check 21 RETIRED in BD-221 (Antigravity conversion) ──────────────────────
# `check_pack_help_per_cli_parity` is removed. pack-help is now an ordinary
# pooled skill (`project-template/skills/pack-help/SKILL.md`) distributed loose
# to all CLIs by init-project — there is no per-CLI parity triplet to enforce.
# The one load-bearing assertion ("the pack-help SKILL.md body references
# `scripts/pack-help.sh`") is FOLDED into Check 1 (SKILL.md frontmatter walk).
# The registry entry + the `CHECK_REGISTRY_EXPECTED_COUNT` were decremented in
# lock-step (61 → 59 with Check 28). No per-check test existed for Check 21.


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

    Per surface: verbs are compared against that surface's own help
    fragment (no cross-surface concatenation).
    """
    print("\n── Check 22: Help-fragment freshness (BD-082) ──")
    # Per-surface fragment lookup per the surface dictionary; no
    # cross-surface concatenation.
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

    any_failed = False
    for surface, cfg in surfaces.items():
        frag = cfg["fragment"]
        if not frag.is_file():
            fail(f"{surface}: help fragment missing: {frag.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        frag_text = frag.read_text()
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
    if not fragment.is_file():
        fail(f"pack-root help fragment missing: {fragment.name}")
        return
    text = fragment.read_text()

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


# ── Check 28 RETIRED in BD-221 (Antigravity conversion) ──────────────────────
# `check_pm_startup_per_cli_parity` (and its `_extract_pm_startup_sections`
# helper, which had no other consumer) are removed. pm-startup is now a single
# pooled SSOT (`project-template/skills/pm-startup/SKILL.md`) distributed loose
# to all CLIs by init-project — the per-CLI byte-parity surfaces this check
# guarded no longer exist, so there is nothing to keep in sync. The registry
# entry + the `CHECK_REGISTRY_EXPECTED_COUNT` were decremented in lock-step
# (61 → 59 with Check 21). No per-check test existed for Check 28.


# ── Checks 29 (check_tracker_config) + 30 (check_recommendation_state_schema)
# + 31 (check_skill_cell_consistency), their constants
# (_TRACKER_MODES / _TRACKER_PREFER / _TRACKER_SCHEMA_VERSION /
# _MIRROR_HEADER_TS_RE / _REC_STATE_SCHEMA / _REC_STATE_SCHEMA_VERSION /
# _REC_STATE_SURFACES / _INVENTORY_SUBSECTIONS) + helpers
# (_validate_tracker_toml / _read_mirror_last_regenerated /
# _check_mirror_staleness / _parse_inventory_subsection) moved to
# validate_checks.agents_skills (BD-256 W4 — Cluster C) — re-imported via the
# facade's `from validate_checks.agents_skills import *` above. Check 29 reads
# the `_TRACKER_BACKENDS` W1 core seam there via `from .core` (single SSOT, no
# forked copy). ──


# ── Check 32′: no pack monolith exists (BD-203, inverts BD-168 Check 32) ───
#
# BD-203 retires the old "mirror-in-sync" Check 32 and REPLACES it with an
# inverted guard. Under the no-mirror model a pack stream's per-entry tree
# (+ `_toc.md`) is the SOLE source of truth + readable form; there is NO
# regenerated monolithic mirror to be "in sync" with. The guard's job
# therefore inverts to: for each pack stream whose tree is present, assert
# the monolith file is ABSENT and the `_rules.md` + `_toc.md` supporting
# files are present. The check still SKIPs when the tree is absent
# (pre-conversion state), so it is vacuously satisfied today (tree absent)
# and PASSES by construction at the post-conversion end-state (tree present
# + monolith deleted). See ARCHITECTURE-BD-203-V3.md §4 (Check 32′).


def _list_unknown_files(stream_dir: Path, entry_regex: str,
                        known_supporting: set) -> list:
    """List basenames in `stream_dir` that are neither known supporting
    files (e.g. `_rules.md`, `_intro.md`, `_toc.md`) nor matching the
    entry regex. Used by Check 32 pre-check (b) — non-conforming
    filenames per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.4.
    (Post-BD-203 B8 there is no `_v8-resolved-archive.md` supporting
    file — the BD-001..019 entries are now normal per-entry files — so
    it is no longer a known-supporting basename; see the
    `known_supporting_for` set in `check_mirror_in_sync`.)
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


# BD-211: canonical per-entry line-2 header for ID-shaped streams —
# `**<ID>-NNN — <Title>**` where <ID> is BD or TD. NO letter suffix and
# NO pre-em-dash parenthetical qualifier (a parenthetical, if present, is
# TITLE TEXT after the em-dash). Used by the Check 32′ header guard.
_CANON_HEADER_RE = re.compile(r"^\*\*(?:BD|TD)-\d+ — .+\*\*$")

# BD-204 Mode-3 ops contract (ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md
# §4.2): per-stream required mode marker in `_rules.md`. Check 32′
# asserts marker/heading PRESENCE only — never prose-pinning
# (anti-fragility). Allowlist sized to exactly the two pack streams
# (measure-then-bound; project streams gain theirs at BD-206/207 and are
# NOT asserted here). Flat-file per-entry is the sole supported mode, so
# `pack-backlog` declares only the "Flat-file mode" marker.
_RULES_MODE_MARKERS = {
    "pack-backlog":   ("Flat-file mode",),
    "pack-changelog": ("Mode invariance",),
}


def _stream_is_id_shaped(entry_regex: str) -> bool:
    """Return True iff `entry_regex` is an `[A-Z]+-\\d+`-shaped ID stream
    (pack-backlog / project-backlog) vs a version-shaped stream
    (pack-changelog `^v\\d+\\.md$`). Derived from the SAME STREAMS
    `entry_regex` the filename loop consumes — the single source of
    stream-applicability for both the filename conformance check and the
    BD-211 canonical-header guard (enumerate-encoding-surfaces: no
    hard-coded "pack-backlog" in two places). The canonical ID streams
    anchor their filename regex on an uppercase letter run before the
    digit run; version streams anchor on a literal `v`.
    """
    return bool(re.match(r"^\^[A-Z]+-", entry_regex))


def check_mirror_in_sync() -> None:
    """Check 32′ — no pack monolith exists (BD-203; inverts BD-168 Check 32).

    For each pack-side stream in STREAMS:

      - SKIP if the per-entry tree directory is absent (pre-conversion
        pack-self / pre-v11.0 client). Vacuously satisfied today.

      - Assert the monolith file (the stream's former `mirror_relative`)
        is ABSENT. Under the no-mirror model the tree is the SOLE SSOT;
        a monolith co-existing with a tree is the wrong-model state the
        check now forbids. FAIL if the monolith is present.

      - Assert `_rules.md` is present (the per-entry contract SSOT).

      - Assert `_rules.md` carries the stream's required mode marker(s)
        (BD-204 Mode-3 ops contract; `_RULES_MODE_MARKERS` — marker
        presence only, never prose-pinning).

      - Assert `_toc.md` is present (the no-mirror readable index).

      - Assert per-entry filenames conform to the stream's entry regex
        (a useful tree-integrity invariant); FAIL on non-conforming
        filenames.

    Never regenerates a mirror — under no-mirror there is nothing to
    regenerate or sync.
    """
    print("\n── Check 32′: no pack monolith exists (BD-203) ──")

    # The set of known supporting basenames a pack stream may carry.
    # Mirrors `pe_supporting_files_known_for_stream` in
    # `scripts/lib/per-entry/_lib.sh` (kept in lockstep).
    known_supporting_for = {
        "pack-backlog":   {"_rules.md", "_intro.md", "_toc.md"},
        "pack-changelog": {"_rules.md", "_intro.md", "_toc.md"},
    }

    for stream_key, stream_rel, mirror_rel, entry_regex in STREAMS:
        stream_dir = REPO_ROOT / stream_rel
        mirror_path = REPO_ROOT / mirror_rel

        if not stream_dir.is_dir():
            ok(
                f"{stream_rel}/ — not present (skipping; pre-conversion "
                f"pack-self or pre-v11.0 client)"
            )
            continue

        # Inverted assertion: the tree is present, so the monolith MUST
        # be absent (no-mirror SSOT).
        if mirror_path.is_file():
            fail(
                f"{mirror_rel} still present while {stream_rel}/ tree "
                f"exists — under the no-mirror model the per-entry tree "
                f"(+ _toc.md) is the SOLE source of truth; delete the "
                f"monolith ({mirror_rel}) so the tree is the only SSOT"
            )
            continue

        # _rules.md must exist (per-entry contract SSOT).
        rules_path = stream_dir / "_rules.md"
        if not rules_path.is_file():
            fail(
                f"{stream_rel}/_rules.md missing — required for the "
                f"per-entry contract (the sole rules SSOT)"
            )
            continue

        # BD-204 Mode-3 ops contract: required mode marker(s) in _rules.md
        # (marker presence only — see _RULES_MODE_MARKERS above). The
        # pack-backlog contract must carry the "Flat-file mode" heading
        # (flat-file per-entry is the sole supported mode); the
        # pack-changelog contract must carry the "Mode invariance" marker.
        required_markers = _RULES_MODE_MARKERS.get(stream_key, ())
        if required_markers:
            try:
                rules_text = rules_path.read_text(
                    encoding="utf-8", errors="replace")
            except OSError:
                rules_text = ""
            missing_markers = [m for m in required_markers
                               if m not in rules_text]
            if missing_markers:
                fail(
                    f"{stream_rel}/_rules.md missing required mode "
                    f"marker(s) {missing_markers} — the Mode-3 ops "
                    f"contract (BD-204) requires the mode-conditional "
                    f"sections; restore the marker heading(s)"
                )
                continue

        # _toc.md must exist (no-mirror readable index).
        toc_path = stream_dir / "_toc.md"
        if not toc_path.is_file():
            fail(
                f"{stream_rel}/_toc.md missing — required as the "
                f"no-mirror readable index (regenerate via "
                f"per_entry_regenerate_toc {stream_key} {stream_dir})"
            )
            continue

        # Filename conformance (tree-integrity invariant).
        known_supporting = known_supporting_for.get(stream_key, set())
        unknown = _list_unknown_files(stream_dir, entry_regex, known_supporting)
        if unknown:
            fail(
                f"{stream_rel}/: non-conforming filenames: "
                f"{unknown} — entry regex {entry_regex!r}; supporting "
                f"basenames {sorted(known_supporting)}"
            )
            continue

        # BD-211: canonical line-2 header guard. For each ID-shaped
        # stream (derived from the SAME entry_regex the filename loop
        # uses — version-shaped streams like pack-changelog are SKIPped
        # so the version grammar is never mis-asserted), the line-2 bold
        # header (BELOW the line-1 `<!-- per-entry source: ... -->`
        # back-pointer) MUST match `**<ID>-NNN — <Title>**` with NO
        # letter suffix and NO pre-em-dash parenthetical. This is the
        # tree-integrity invariant "the FILENAME is the ID, the HEADER
        # must match the ID-grammar".
        if _stream_is_id_shaped(entry_regex):
            bad_headers = []
            for child in sorted(stream_dir.iterdir()):
                if not child.is_file():
                    continue
                name = child.name
                if name in known_supporting:
                    continue
                if not re.compile(entry_regex).match(name):
                    continue
                try:
                    with open(child, "r", encoding="utf-8", newline="") as f:
                        lines = f.read().splitlines()
                except OSError:
                    continue
                # Line 2 is the bold header below the line-1 back-pointer.
                header = lines[1] if len(lines) >= 2 else ""
                if not _CANON_HEADER_RE.match(header):
                    bad_headers.append((name, header))
            if bad_headers:
                detail = "; ".join(
                    f"{n}: {h!r}" for n, h in bad_headers
                )
                fail(
                    f"{stream_rel}/: non-canonical line-2 header(s) "
                    f"(BD-211 — must be `**<ID>-NNN — <Title>**`, NO "
                    f"letter suffix, NO pre-em-dash parenthetical): "
                    f"{detail}"
                )
                continue

        ok(
            f"{stream_rel}/ — no monolith present; _rules.md + _toc.md "
            f"present; filenames conform (no-mirror SSOT)"
        )


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
# BD-211: the cross-ref TOKEN for BD/TD is canonical `BD-NNN` / `TD-NNN`
# — NO letter suffix (the former suffix sub-entries were folded into
# their base entries; no suffix ID exists). CROSS-SURFACE: the `TD-\d+`
# token serves the project stream. The version token after `vMAJOR.MINOR`
# carries EITHER an optional `.PATCH` segment OR a bounded release-state
# qualifier `-(?:alpha|beta|RC\d+|GA)` (alpha/beta lowercase, RC numbered,
# GA uppercase) — never both, because a PATCH is NEVER qualified. Old
# two-level `vN.M` still tokenizes (both the patch and the qualifier are
# optional).
CROSS_REF_RE = re.compile(
    r"\b("
    r"BD-\d+"
    r"|TD-\d+"
    r"|phase-\d+(?:\.\d+)?"
    r"|v\d+\.\d+(?:\.\d+|(?:-(?:alpha|beta|RC\d+|GA))?)"
    r")\b"
)

# BD-203 FLAG-b (measure-then-bound): under per-release changelog
# granularity (CHANGE 2) the pack-changelog defined-ID set is the set of
# MAJOR versions (`v11`, `v10`, … — one `vN.md` per `## vN` release). A
# point-release reference `vN.M` (e.g. `v11.0`, `v9.3`) lives INSIDE its
# major release file's body (the H2 block carries the nested `### vN.M`
# subsections verbatim — ARCHITECTURE-BD-203-V3.md §2.3). So a `vN.M`
# reference RESOLVES iff its MAJOR `vN` entry is defined. This mapping is
# sized EXACTLY to the per-release granularity decision (resolve `vN.M`
# to `vN`); it does NOT widen the allowlist to admit unclassified hits —
# a `vN.M` whose major `vN` is undefined still FAILs.
_VERSION_POINT_RE = re.compile(
    r"^v(\d+)\.\d+(?:\.\d+|(?:-(?:alpha|beta|RC\d+|GA))?)$")


def _resolves_to_defined_id(ref: str, defined_all: set,
                            loaded_prefixes: set,
                            highest_defined_major: int = None) -> bool:
    """True iff `ref` resolves to a defined entry ID OR is an out-of-scope
    cross-stream reference per the Check 34 documented contract.

    Resolution paths:
      - Direct hit in the loaded defined-ID set.
      - (BD-203 FLAG-b) a `vN.M` point-release reference whose MAJOR
        `vN` entry is defined (the point release lives inside the major
        `vN.md` release file under per-release granularity). Sized
        EXACTLY to the granularity mapping — a `vN.M` whose major is
        undefined still FAILs.
      - (BD-203 D1, measure-then-bound forward-ref tolerance) a `vN.M`
        point-release reference whose MAJOR `vN` is GREATER than the
        highest defined changelog major is a genuine FORWARD reference
        (a version that does not exist YET — e.g. "required before
        tagging v12.0" when the highest released major is v11). This is
        sized EXACTLY to `major > highest-defined-major`, NOT a token
        allowlist: a `vN.M` whose major is `<=` the highest defined but
        undefined (an in-range gap / typo) still FAILs. When no
        changelog major is loaded (`highest_defined_major is None`) this
        path does not fire.
      - (Cross-stream tolerance, §10.6 — the check's documented
        contract) a reference whose ID-prefix belongs to a stream that
        is NOT loaded is out of scope for this validation. A pack-side
        run loads only the pack streams (pack-backlog ↔ pack-changelog),
        so a `TD-` reference (project-backlog) is tolerated — the
        project tree is not present to validate against. This makes the
        implementation honor the docstring's "cross-stream references
        are tolerated" clause (previously asserted but not enforced).
    """
    if ref in defined_all:
        return True
    m = _VERSION_POINT_RE.match(ref)
    if m and f"v{m.group(1)}" in defined_all:
        return True
    # BD-203 D1 — measure-then-bound forward-ref tolerance: a `vN.M`
    # whose MAJOR `vN` exceeds the highest defined changelog major is a
    # forward reference to a version that does not exist yet (not a
    # dangling entry-ref). Sized to `major > highest-defined` — an
    # in-range-but-undefined major (a gap/typo) still FAILs.
    if (m and highest_defined_major is not None
            and int(m.group(1)) > highest_defined_major):
        return True
    # Cross-stream tolerance: if the ref's prefix is not among the
    # loaded streams' prefixes, it targets an unloaded stream (§10.6).
    if "TD-" not in loaded_prefixes and ref.startswith("TD-"):
        return True
    return False


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

    Note: post-BD-203 B8 there is no `_v8-resolved-archive.md` SKIP — the
    BD-001..019 entries are now normal per-entry files, so no v8-archive
    supporting file is emitted. The caller's walk loop in
    `check_cross_reference_integrity` skips leading-underscore supporting
    files generically (`startswith("_")`), which covers any such file
    without a special case. (An earlier draft also carried a defensive
    in-text `skip_v8_archive` parameter that suppressed references after
    any line matching `^## Resolved — v\\d+\\b`; that parameter was
    removed per BD-168 retro fix N2 because the file-level skip is
    sufficient and the in-text version risked false negatives in
    per-entry pack-changelog files that might legitimately carry a
    `## Resolved — v11.0` H2 in their bodies.)
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

      - Supporting files (leading-underscore basenames such as
        `_toc.md`) are not walked. (Post-BD-203 B8 there is no
        `_v8-resolved-archive.md` archive file — the BD-001..019 entries
        are now normal per-entry files — so the former §11.3 archive SKIP
        is dead; the generic leading-underscore guard covers any such
        supporting file.)

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

    # BD-203 D1 — compute the highest defined changelog MAJOR once (the
    # pack-changelog defined IDs are `vN`; parse the integer N from each
    # `^v\d+$` member). Used by `_resolves_to_defined_id` to tolerate a
    # genuine `vN.M` FORWARD reference (major > highest-defined). `None`
    # when no changelog major is loaded (the forward-ref path then does
    # not fire). Sized to the forward-ref category, never a token list.
    _major_re = re.compile(r"^v(\d+)$")
    _defined_majors = [
        int(mm.group(1)) for did in defined_all
        for mm in (_major_re.match(did),) if mm
    ]
    highest_defined_major = max(_defined_majors) if _defined_majors else None

    # The ID-prefixes of the LOADED streams (for cross-stream tolerance,
    # §10.6). A reference whose prefix is not loaded targets an unloaded
    # stream and is out of scope. Map each loaded stream key to its
    # reference-token prefix.
    _stream_prefix = {
        "pack-backlog": "BD-",
        "pack-changelog": "v",
        "project-backlog": "TD-",
        "project-implementation-plan": "phase-",
        "project-changelog": "",
    }
    loaded_prefixes = {
        _stream_prefix[k] for k in defined_by_stream
        if k in _stream_prefix
    }

    # BD-203 B8: the former `_v8-resolved-archive.md` SKIP is DEAD — the
    # 19 BD-001..019 entries are now normal `BD-00N.md` per-entry files
    # (pre-normalize Commit 1), so no v8-archive supporting file is
    # emitted. Any leading-underscore supporting file is already skipped
    # by the `startswith("_")` guard below; no special-case basename set
    # is needed.

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
                if _resolves_to_defined_id(
                    ref, defined_all, loaded_prefixes,
                    highest_defined_major,
                ):
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
                f"to defined IDs (or self-reference; leading-underscore "
                f"supporting files are not walked)"
            )

# `_PACK_CHAT_ONLY_PERMITTED_PATHS` + `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` moved
# to validate_checks.core (BD-256 W1 seams — read by Check 36's
# `_is_pack_chat_only_permitted` + the Check 80 twin-registry) — re-imported via
# the facade's `from validate_checks.core import *` above. (The
# `_PACK_CHAT_ONLY_PATH_ANNOTATIONS` presentation map below stays inline; it
# travels with `render_pack_chat_only_doc_section` / Check 80 in a later wave.)

# ─────────────────────────────────────────────────────────────────────────
# A1 COLLAPSE (BD-255 Part A, design §3.1 Layer 1): the pack-chat-only twin.
#
# `_PACK_CHAT_ONLY_PERMITTED_PATHS` + `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`
# above are the SOLE SSOT for the pack-chat-only permitted set. The
# `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" Files +
# Directories bullets are DERIVED from them via the annotation map +
# `render_pack_chat_only_doc_section()` below — the doc is generated output,
# never a hand-maintained second surface (the `fail-loud: delete-the-old-
# source` idiom applied to representation). The ordered annotation map fixes
# BOTH the rendering order AND the friendly parenthetical for each entry;
# its keys are asserted set-equal to the membership constants so the constant
# stays the membership authority and the map is the presentation layer in the
# same logical unit.
#
# The narrower `README.md version table` constraint is a Pack Chat DISCIPLINE
# (the constant holds bare `README.md`; the "version table" scope lives as the
# annotation, not as a separate constant member).
_PACK_CHAT_ONLY_PATH_ANNOTATIONS = (
    ("README.md", "version table"),
    ("pack-ops/PACK-CHAT.md", "PM chat operating rules"),
    ("pack-ops/PACK-AGENTS.md", "agent routing + permission rules"),
    (
        "pack-ops/PACK-MEMORY-RATIONALE.md",
        "rule↔rationale bijection partner for `## Pack memory`; "
        "edited only in lockstep with rule changes",
    ),
    ("CLAUDE.md", "pack-root trinity"),
    ("AGENTS.md", "pack-root trinity"),
    ("GEMINI.md", "pack-root trinity"),
    ("project-template/CLAUDE.md", "project-template trinity"),
    ("project-template/AGENTS.md", "project-template trinity"),
    ("project-template/GEMINI.md", "project-template trinity"),
    (
        "pack-ops/session-state.json",
        "live-session snapshot; Pack-Chat-overwritten on every state transition",
    ),
)

_PACK_CHAT_ONLY_PREFIX_ANNOTATIONS = (
    ("backlog/", "pack per-entry tree (entries)"),
    ("changelog/", "pack changelog per-entry tree"),
    (
        "project-template/docs/project/backlog/",
        "project per-entry tree canonical templates (ship into client projects)",
    ),
    ("project-template/docs/project/implementation-plan/", "project per-entry tree"),
    ("project-template/docs/project/changelog/", "project per-entry tree"),
)

# Markers delimiting the GENERATED bullet block inside the PACK-AGENTS.md
# § "pack-chat-only files and directories" section. The text between (and
# including) these markers is `render_pack_chat_only_doc_section()` output.
_PACK_CHAT_ONLY_DOC_BEGIN = (
    "<!-- GENERATED:pack-chat-only-permitted-set — do not hand-edit; "
    "`_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES` in scripts/validate-pack.py "
    "govern (never source of truth here) -->"
)
_PACK_CHAT_ONLY_DOC_END = "<!-- /GENERATED:pack-chat-only-permitted-set -->"


def render_pack_chat_only_doc_section() -> str:
    """Render the GENERATED pack-chat-only Files + Directories bullet block
    for `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories".

    The constant `_PACK_CHAT_ONLY_PERMITTED_PATHS` /
    `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` are the membership SSOT; the ordered
    annotation maps supply the rendering order + the friendly parenthetical.
    Raises ValueError if the annotation-map key sets diverge from the
    membership constants (the collapse invariant — neither surface may drift
    from the other because both derive from this single render).
    """
    path_keys = [p for p, _ in _PACK_CHAT_ONLY_PATH_ANNOTATIONS]
    prefix_keys = [p for p, _ in _PACK_CHAT_ONLY_PREFIX_ANNOTATIONS]
    if set(path_keys) != _PACK_CHAT_ONLY_PERMITTED_PATHS:
        raise ValueError(
            "pack-chat-only path annotation map diverges from "
            "_PACK_CHAT_ONLY_PERMITTED_PATHS: "
            f"only-in-map={sorted(set(path_keys) - _PACK_CHAT_ONLY_PERMITTED_PATHS)} "
            f"only-in-constant={sorted(_PACK_CHAT_ONLY_PERMITTED_PATHS - set(path_keys))}"
        )
    if set(prefix_keys) != set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES):
        raise ValueError(
            "pack-chat-only prefix annotation map diverges from "
            "_PACK_CHAT_ONLY_PERMITTED_PREFIXES: "
            f"only-in-map={sorted(set(prefix_keys) - set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES))} "
            f"only-in-constant={sorted(set(_PACK_CHAT_ONLY_PERMITTED_PREFIXES) - set(prefix_keys))}"
        )
    lines: list[str] = [_PACK_CHAT_ONLY_DOC_BEGIN, ""]
    lines.append("Files:")
    for path, annotation in _PACK_CHAT_ONLY_PATH_ANNOTATIONS:
        lines.append(f"- `{path}` ({annotation})")
    lines.append("")
    lines.append("Directories:")
    for prefix, annotation in _PACK_CHAT_ONLY_PREFIX_ANNOTATIONS:
        lines.append(f"- `{prefix}` — {annotation}")
    lines.append("")
    lines.append(_PACK_CHAT_ONLY_DOC_END)
    return "\n".join(lines)


# ─────────────────────────────────────────────────────────────────────────
# DOC↔CONSTANT TWIN REGISTRY (BD-255 Part A, design §3.1 Layer 3) + Check 80.
#
# A `_DOC_CONSTANT_TWINS` row enrolls a hand-authored doc↔constant twin (a
# prose set a doc maintains as its audience SSOT, restated by an enforcement
# constant, with nothing structurally forcing co-variance). Each row is tagged
# by GUARD-KIND:
#   - "bijection": the doc region's set is cleanly extractable, so Check 80
#     asserts doc-set == constant-set (the Check-45/52 idiom). Drift-proof.
#   - "recorded": the doc surface is a PROSE FLOOR — a clean set extraction is
#     infeasible (the rejected prose-parse the design forbids for Check 54/56).
#     Check 80 asserts only that the constant SYMBOL RESOLVES (the MUST-2
#     backstop record); the bespoke check (54/56) keeps its one-way guard.
#
# The F2 defeater — opt-in enrollment — is answered NOT by auto-discovery
# (infeasible; no syntactic twin-signal exists, design §2.5) but by the
# Check-59-style COMPLETENESS LEG in Check 80: len(...) == EXPECTED_COUNT +
# every symbol resolves. Enrollment is a count-gated, reviewable governance act.
#
# Row shape: (label, doc_paths, region/anchor, constant_symbol_name, guard_kind)
#   - label: a short human tag for messages.
#   - doc_paths: tuple of REPO_ROOT-relative doc files carrying the region.
#   - region: a human description of the region/anchor (for messages).
#   - constant_symbol_name: the module-attribute NAME (resolved via getattr at
#     check time — also the completeness-leg "symbol resolves" target).
#   - guard_kind: "bijection" | "recorded".
_DOC_CONSTANT_TWINS = (
    # A1 (BIJECTION) — LOCKS the A1 collapse: the generated PACK-AGENTS.md
    # pack-chat-only region (between the GENERATED markers) must EQUAL
    # render_pack_chat_only_doc_section() output (the constant-derived render).
    # This activates the A1 divergence guard that was dormant pending #80.
    (
        "A1 pack-chat-only permitted set",
        ("pack-ops/PACK-AGENTS.md",),
        "the GENERATED:pack-chat-only-permitted-set region",
        "_PACK_CHAT_ONLY_PERMITTED_PATHS",
        "bijection",
    ),
    # TRACKER (BIJECTION) — the "Supported at v11.0: ... reserved" backend
    # comment block in BOTH example files ↔ _TRACKER_BACKENDS. The comment is a
    # single delimited line (quoted first-class + a comma-delimited reserved
    # parenthetical), regex-clean, identical in both files → a real bijection.
    # (_TRACKER_MODES / _TRACKER_PREFER are NOT separate clean comment-block
    # twins — their tokens are scattered prose definitions across TOML tables,
    # not a single "supported set" comment; the backend line is the only clean
    # one, per the BD-255 census.)
    (
        "tracker supported backends",
        ("tracker.toml.pack-example", "project-template/tracker.toml.project-example"),
        'the "Supported at vN: ... reserved" backend comment line',
        "_TRACKER_BACKENDS",
        "bijection",
    ),
    # Check 54 (RECORDED residual) — OPTIONAL-FEATURES surfaces ↔
    # _CHECK_54_REQUIRED_TOKENS. The surface is rich human prose (a prose
    # floor); a set-equality bijection is the rejected prose-parse. Check 54
    # keeps its presence-only one-way guard; this row is the MUST-2 backstop
    # record (symbol-resolve only).
    (
        "OPTIONAL-FEATURES required tokens",
        (
            "pack-ops/OPTIONAL-FEATURES.md",
            "project-template/docs/pack/OPTIONAL-FEATURES.md",
        ),
        "OPTIONAL-FEATURES prose (presence-only; prose floor)",
        "_CHECK_54_REQUIRED_TOKENS",
        "recorded",
    ),
    # Check 56 (RECORDED residual) — trinity destructive-git-verb enumeration ↔
    # _CHECK_56_CANONICAL_VERBS. The surface is rich human prose with sub-form
    # parentheticals; a clean set extraction is infeasible (the prose-parse the
    # design rejects). Check 56 keeps its bespoke one-way guard; this row is the
    # MUST-2 backstop record (symbol-resolve only).
    (
        "destructive-git-verb canonical set",
        ("CLAUDE.md", "AGENTS.md", "GEMINI.md"),
        "the agents-never-commit destructive-verb enumeration across the "
        "_CHECK_56_VERB_PARITY_SURFACES set (prose floor; sub-form "
        "parentheticals make a clean extraction infeasible)",
        "_CHECK_56_CANONICAL_VERBS",
        "recorded",
    ),
)

# The count-gate (the CHECK_REGISTRY_EXPECTED_COUNT idiom). Check 80's
# completeness leg asserts len(_DOC_CONSTANT_TWINS) == this. Adding/removing a
# twin row is a deliberate, count-gated, reviewable edit.
_DOC_CONSTANT_TWINS_EXPECTED_COUNT = 4


def _doc_constant_twin_doc_set(label, doc_paths, region, symbol_name):
    """Extract the doc-region SET for a BIJECTION twin row, per its label.

    Returns a `set[str]` of the tokens the doc region enumerates, or raises
    ValueError if the region/markers are absent (a structural break the check
    surfaces as a FAIL). Dispatches on the row label because each bijection
    twin has its own (small, bespoke) region grammar — exactly the Check-45/52
    pattern, scoped to the measured surfaces (measure-then-bound).
    """
    if symbol_name == "_PACK_CHAT_ONLY_PERMITTED_PATHS":
        # A1: the doc set IS the membership the rendered region encodes. The
        # rendered block is the constant-derived SSOT; the bijection is the
        # doc's region == render_pack_chat_only_doc_section() output. We compare
        # the extracted path/prefix backtick tokens, not the whole block, so a
        # cosmetic whitespace edit is not a false RED.
        doc_path = REPO_ROOT / doc_paths[0]
        text = doc_path.read_text()
        begin = _PACK_CHAT_ONLY_DOC_BEGIN
        end = _PACK_CHAT_ONLY_DOC_END
        if begin not in text or end not in text:
            raise ValueError(
                f"{doc_paths[0]} is missing the GENERATED pack-chat-only "
                f"region markers"
            )
        region_text = text.split(begin, 1)[1].split(end, 1)[0]
        # Each rendered bullet is `- `<path-or-prefix>` (...)` / `- `<...>` — ...`.
        return set(re.findall(r"^- `([^`]+)`", region_text, re.MULTILINE))
    if symbol_name == "_TRACKER_BACKENDS":
        # Backend comment line: # Supported at <ver>: "<first>". Others
        # (<a>, <b>, <c>) reserved. The full set = first-class ∪ reserved.
        line_re = re.compile(
            r'#\s*Supported at [^:]+:\s*"([^"]+)"\.\s*Others\s*'
            r'\(([^)]+)\)\s*reserved\.'
        )
        sets_per_file = []
        for rel in doc_paths:
            doc_path = REPO_ROOT / rel
            text = doc_path.read_text()
            m = None
            for line in text.splitlines():
                mm = line_re.search(line)
                if mm:
                    m = mm
                    break
            if m is None:
                raise ValueError(
                    f"{rel} is missing the 'Supported at ...: ... reserved' "
                    f"backend comment line"
                )
            first_class = m.group(1).strip()
            reserved = [t.strip() for t in m.group(2).split(",") if t.strip()]
            sets_per_file.append(frozenset([first_class] + reserved))
        # All example files must agree (the shipped comment is identical).
        if len(set(sets_per_file)) != 1:
            raise ValueError(
                f"tracker backend comment sets diverge across {list(doc_paths)}: "
                f"{[sorted(s) for s in sets_per_file]}"
            )
        return set(sets_per_file[0])
    raise ValueError(
        f"no bijection doc-set extractor for twin '{label}' "
        f"(symbol {symbol_name})"
    )


def _doc_constant_twin_const_set(module_ns, symbol_name):
    """Return the CONSTANT-side SET for a BIJECTION twin row.

    `module_ns` is this module's globals() (robust under either import path).
    The row names ONE representative symbol; the A1 twin's membership SSOT is
    actually TWO constants (paths + prefixes) whose UNION the rendered doc
    region encodes — so the A1 const set is that union. Other bijection twins
    are a single set-like constant.
    """
    if symbol_name == "_PACK_CHAT_ONLY_PERMITTED_PATHS":
        return set(module_ns["_PACK_CHAT_ONLY_PERMITTED_PATHS"]) | set(
            module_ns["_PACK_CHAT_ONLY_PERMITTED_PREFIXES"]
        )
    return set(module_ns[symbol_name])


def check_doc_constant_twin_bijection() -> None:
    """Check 80 — generic doc↔constant twin-bijection + completeness leg (BD-255).

    The generic A-mechanism (design §3.1 Layer 3). For each enrolled
    `_DOC_CONSTANT_TWINS` row:
      - guard_kind "bijection": assert the doc-region SET equals the constant
        SET (the Check-45/52 set-equality idiom — missing/extra two-sided). This
        LOCKS the A1 collapse + guards the tracker backend twin.
      - guard_kind "recorded": assert only that the constant SYMBOL RESOLVES to
        a real module attribute (the MUST-2 backstop record; the surface is a
        prose floor — its bespoke check keeps the one-way guard).

    PLUS the Check-59-style COMPLETENESS LEG:
      - len(_DOC_CONSTANT_TWINS) == _DOC_CONSTANT_TWINS_EXPECTED_COUNT
        (enrollment is count-gated — adding/removing a twin without the count
        bump FAILs), AND
      - every registered constant symbol resolves to a real module attribute.

    This does NOT auto-discover unregistered twins (infeasible, design §2.5 — no
    syntactic twin-signal exists), but makes enrollment a deliberate, reviewable,
    count-gated governance act + makes each enrolled bijection drift-proof.

    Cheap (ci-check-runtime-compounding): per row = one small doc read + a
    region extract + a set compare; the completeness leg is in-memory set
    arithmetic. Same cost class as Check 45/52/59 — no subprocess, no tree walk.

    Lenient: a doc-surface file absent at HEAD SKIPs that row's bijection leg
    (an init/state problem, not a drift); the completeness leg always runs.
    """
    print("\n── Check 80: doc↔constant twin-bijection + completeness (BD-255) ──")

    # Resolve registered symbols against THIS module's globals (robust whether
    # the module is imported by name or loaded via spec_from_file_location).
    module_ns = globals()

    # ── Completeness leg (count-gate) ──
    n = len(_DOC_CONSTANT_TWINS)
    if n != _DOC_CONSTANT_TWINS_EXPECTED_COUNT:
        fail(
            f"_DOC_CONSTANT_TWINS has {n} row(s) but "
            f"_DOC_CONSTANT_TWINS_EXPECTED_COUNT == "
            f"{_DOC_CONSTANT_TWINS_EXPECTED_COUNT}. A twin was enrolled or "
            f"removed without the count bump (the count-gate, like "
            f"CHECK_REGISTRY_EXPECTED_COUNT). Set the constant to {n} if the "
            f"change is intentional, or restore the missing row. Per BD-255 "
            f"design §3.1 Layer 3 the completeness leg makes enrollment loud."
        )
        return

    # ── Completeness leg (every symbol resolves) ──
    unresolved = [
        sym for (_l, _d, _r, sym, _k) in _DOC_CONSTANT_TWINS
        if sym not in module_ns
    ]
    if unresolved:
        fail(
            f"_DOC_CONSTANT_TWINS registers {len(unresolved)} constant "
            f"symbol(s) that do NOT resolve to a module attribute: "
            f"{unresolved}. Per BD-255 design §3.1 Layer 3 every registered "
            f"twin symbol must name a real constant. Remediation: fix the "
            f"symbol name in the row, or remove the row + bump the count."
        )
        return

    any_fail = False
    bijection_rows = 0
    recorded_rows = 0
    skipped_rows = 0

    for label, doc_paths, region, sym, kind in _DOC_CONSTANT_TWINS:
        if kind == "recorded":
            # Symbol-resolve already verified above; record-only row.
            recorded_rows += 1
            continue
        if kind != "bijection":
            any_fail = True
            fail(
                f"twin '{label}' has unknown guard_kind {kind!r} "
                f"(expected 'bijection' | 'recorded')."
            )
            continue
        # Lenient: skip the bijection leg if any doc surface is absent at HEAD.
        missing_files = [p for p in doc_paths if not (REPO_ROOT / p).is_file()]
        if missing_files:
            ok(
                f"twin '{label}' — doc surface(s) {missing_files} absent; "
                f"skipping bijection (lenient)"
            )
            skipped_rows += 1
            continue
        try:
            doc_set = _doc_constant_twin_doc_set(label, doc_paths, region, sym)
            const_set = _doc_constant_twin_const_set(module_ns, sym)
        except ValueError as exc:
            any_fail = True
            fail(
                f"twin '{label}' — could not extract the doc-region set from "
                f"{region} ({list(doc_paths)}): {exc}. The region/markers may "
                f"have drifted. Per BD-255 design §3.1 Layer 3."
            )
            continue
        except KeyError as exc:
            # A constant the const-set builder resolves did NOT exist in
            # module_ns. The completeness leg already covers every DIRECTLY
            # named row symbol, but a bijection builder may read a SECONDARY
            # un-named constant (e.g. the A1 row's union reads both
            # `_PACK_CHAT_ONLY_PERMITTED_PATHS` and
            # `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`). A missing such constant
            # must FAIL loud-but-clean (naming the symbol), never crash with an
            # uncaught traceback (a guard fails gracefully — design §3.1
            # Layer 3 / ci-guard-measure-then-bound).
            any_fail = True
            fail(
                f"twin '{label}' — could not resolve a constant the bijection "
                f"const-set builder reads (row symbol `{sym}`): missing "
                f"module attribute {exc}. A required SSOT constant was "
                f"deleted/renamed. Remediation: restore the named constant or "
                f"update the builder + row. Per BD-255 design §3.1 Layer 3."
            )
            continue
        only_doc = sorted(doc_set - const_set)
        only_const = sorted(const_set - doc_set)
        if only_doc or only_const:
            any_fail = True
            fail(
                f"twin '{label}' — doc↔constant DRIFT (bijection broken). "
                f"In {region} ({list(doc_paths)}) but NOT in `{sym}`: "
                f"{only_doc}. In `{sym}` but NOT in the doc region: "
                f"{only_const}. Per BD-255 design §3.1 Layer 3 the enrolled "
                f"twin must be a set-equality bijection. Remediation: edit the "
                f"SSOT then regenerate/sync the derived surface in the SAME "
                f"change (for A1 the constant is the SSOT; re-render the "
                f"PACK-AGENTS.md region via render_pack_chat_only_doc_section())."
            )
            continue
        bijection_rows += 1

    if not any_fail:
        ok(
            f"Check 80 — {n} twin(s) enrolled (== "
            f"_DOC_CONSTANT_TWINS_EXPECTED_COUNT); every symbol resolves; "
            f"{bijection_rows} bijection row(s) hold set-equality, "
            f"{recorded_rows} recorded-residual row(s) resolve, "
            f"{skipped_rows} bijection leg(s) skipped (surface absent)."
        )


# ── Checks 81 + 82: cross-BD shared-edit-surface collision detection
# (BD-255 Part C, sub-type C; design §3.3 C-i prereq + C-ii backstop) ──────────
#
# Open-backlog states whose entries are subject to the surface checks. The
# lifecycle enum (`backlog/_rules.md` § "Lifecycle states admitted") is
# Open / Unblocked / Deferred / Resolved / Deprecated / Cancelled. Only the
# ACTIVE (not-postponed, not-closed) entries matter for collision detection:
# Open + Unblocked. Deferred/Resolved/Deprecated/Cancelled are excluded
# (sized EXACTLY to the active-design population — measure-then-bound).
_CHECK_81_OPEN_BD_STATES = ("Open", "Unblocked")

# The bare/TBD/placeholder markers that disqualify a `File/Symbol` field from
# being a STRUCTURED repo-relative path list (the F4 enabler — design §3.3).
# A field carrying any of these (case-insensitive) is a placeholder, NOT a
# parseable surface set, even if it also names a concrete backtick path
# (e.g. BD-020 "n/a — new file `...` to be created"; BD-253 "TBD by
# architect. Likely surfaces: `...`"; BD-245/254 "candidate surfaces"). The
# set is sized EXACTLY to the design's enumerated reject-list (measure-then-
# bound — DESIGN-RECONCILED §3.3 C-i / the FAIL-leg spec), no broader.
_CHECK_81_TBD_MARKERS = (
    "tbd",
    "to be determined",
    "to be created",
    "architect to detail",
    "candidate surfaces",
    "n/a",
)

# A backtick-quoted repo-relative path token inside a `File/Symbol` field — a
# backtick span whose first segment is followed by EITHER another `/<segment>`
# (a multi-segment path), OR a `.<ext>` suffix (a repo-root file like
# `CLAUDE.md` / `validate-pack.py`), OR a single trailing `/` (a repo-relative
# directory like `project-template/` / `backlog/` — including a single-segment
# directory the multi-segment alternative would otherwise miss). This is the
# structured-surface signal the collision scan keys on (design §3.3: the
# researcher blast-radius / structured surface set, NOT free-text prose). The
# trailing-slash directory case keeps the matcher sized to the real structured
# File/Symbol population (ci-guard-measure-then-bound) — a bare backtick word
# with NO slash and NO extension is still NOT a path token (no false
# positives). Used by BOTH Check 81 (≥1 token ⇒ structured) and Check 82 (the
# surface→BDs map keys). Bounded to the field VALUE (no tree walk, no
# subprocess).
_CHECK_81_PATH_TOKEN_RE = re.compile(
    r"`([A-Za-z0-9_][A-Za-z0-9_./-]*"
    r"(?:/[A-Za-z0-9_./-]+|\.[A-Za-z0-9_]+|/))`"
)


def _check_81_iter_open_bds():
    """Yield `(rel_path, bd_id, status, file_symbol_value)` for every
    git-tracked-shape `backlog/BD-*.md` entry in an active-design state
    (`_CHECK_81_OPEN_BD_STATES`).

    The candidate set is the per-entry `backlog/BD-*.md` files (the tree IS
    the SSOT — `ci-guard-measure-then-bound`: the enumeration is the tracked
    per-entry entry set, NOT a filesystem walk of the whole repo). Entries
    whose `Status:` is not active (Deferred/Resolved/Deprecated/Cancelled) or
    whose name is a supporting `_`-prefixed file are SKIPPED.

    `file_symbol_value` is the `File/Symbol:` field VALUE — the colon-tail of
    the field header line PLUS any subsequent indented/bulleted continuation
    lines, up to the next top-level field line (`^<Field>:` or `^**`). `None`
    when the entry carries no `File/Symbol` field. Cheap: one small read +
    line scan per entry; no subprocess, no tree walk.
    """
    backlog_dir = REPO_ROOT / "backlog"
    if not backlog_dir.is_dir():
        return
    field_line_re = re.compile(r"^[A-Z][A-Za-z0-9/ _-]*:")
    for entry in sorted(backlog_dir.glob("BD-*.md")):
        if entry.name.startswith("_"):
            continue
        try:
            text = entry.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        rel = entry.relative_to(REPO_ROOT)
        m_id = re.match(r"(BD-\d+)\.md$", entry.name)
        bd_id = m_id.group(1) if m_id else entry.stem
        m_st = re.search(r"^Status:\s*(\S+)", text, re.MULTILINE)
        status = m_st.group(1) if m_st else None
        if status not in _CHECK_81_OPEN_BD_STATES:
            continue
        # Extract the File/Symbol field VALUE (header colon-tail + bulleted
        # continuation up to the next top-level field).
        lines = text.splitlines()
        fs_value = None
        for i, line in enumerate(lines):
            if re.match(r"^File/Symbol\b", line):
                head = line.split(":", 1)
                value_lines = [head[1] if len(head) > 1 else ""]
                for cont in lines[i + 1:]:
                    if field_line_re.match(cont) or cont.startswith("**"):
                        break
                    value_lines.append(cont)
                fs_value = "\n".join(value_lines)
                break
        yield (rel, bd_id, status, fs_value)


def _check_81_field_is_structured(fs_value):
    """True iff `fs_value` is a STRUCTURED repo-relative path list (the F4
    enabler): it carries ≥1 backtick repo-relative path token AND no bare/TBD
    placeholder marker. A `None`/empty field, a bare-TBD field, or a
    "candidate surfaces"/placeholder field (even one that also names a path)
    is NOT structured. design §3.3 C-i FAIL-leg spec."""
    if not fs_value:
        return False
    low = fs_value.lower()
    if any(marker in low for marker in _CHECK_81_TBD_MARKERS):
        return False
    return bool(_CHECK_81_PATH_TOKEN_RE.search(fs_value))


def _check_81_active_bd_ids():
    """Return the set of BD-IDs in the committed session-state `active[]`
    list (the in-design trigger — BD-252's mechanism, NOT a new backlog Status
    token; design DECISION C2-a). Reads `pack-ops/session-state.json` via the
    shared `_session_state_load()`; returns an EMPTY set (SKIP-lenient) when
    the snapshot is absent, unparseable, or carries no usable `active[]` (a
    fresh clone / pre-feature HEAD must not crash the check)."""
    loaded = _session_state_load()
    if loaded is None or loaded[0] == "PARSE_ERROR":
        return set()
    data = loaded[0]
    if not isinstance(data, dict):
        return set()
    active = data.get("active")
    if not isinstance(active, list):
        return set()
    ids = set()
    for member in active:
        if isinstance(member, dict):
            bd = member.get("bd")
            if isinstance(bd, str) and re.match(r"^BD-\d+$", bd):
                ids.add(bd)
    return ids


def check_open_bd_structured_surface_field() -> None:
    """Check 81 — structured `File/Symbol` prerequisite for active-design BDs
    (BD-255 Part C, design §3.3 C-i; TWO-MODE).

    The F4 enabler: the cross-BD collision scan keys on a STRUCTURED surface
    set, so at least ONE side of any pair must be parseable. This check
    GUARANTEES that for every BD in active design.

    - FAIL leg (gate): for every open `backlog/BD-*.md` whose BD-ID is in the
      committed session-state `active[]` list (the in-design trigger —
      DECISION C2-a; BD-252's existing mechanism, NOT a new backlog Status
      token), its `File/Symbol` field MUST be a structured repo-relative path
      list (≥1 backtick path token + no bare/TBD placeholder). A bare/TBD or
      missing field for an active BD FAILs.
    - WARN leg (advisory, NEVER fail): for every OTHER active-state open BD
      with a bare/TBD/missing `File/Symbol`, WARN (visibility without
      false-blocking legitimately-early entries — the Check-48 warn idiom).

    SKIP-lenient: if `pack-ops/session-state.json` is absent/unparseable the
    `active[]` set is empty (no FAIL leg fires), so the check degrades to the
    WARN leg only — a fresh clone / pre-feature HEAD never crashes or
    false-fails.

    GREEN over the live backlog (re-derived): session-state `active[]`
    currently holds ONLY BD-255; BD-255's `File/Symbol` is a structured
    backtick repo-relative path list → FAIL leg PASSES; the bare/TBD open BDs
    (BD-020/245/253/254) are NOT in `active[]` → WARN leg → exit 0.

    Cheap (ci-check-runtime-compounding): one small JSON read + a line scan of
    each small open entry (~28 entries today). No subprocess, no tree walk.
    """
    print(
        "\n── Check 81: structured File/Symbol prereq for active-design BDs "
        "(BD-255) ──"
    )

    active_ids = _check_81_active_bd_ids()
    failed = 0
    warned = 0
    active_ok = 0
    for rel, bd_id, _status, fs_value in _check_81_iter_open_bds():
        structured = _check_81_field_is_structured(fs_value)
        if bd_id in active_ids:
            if not structured:
                failed += 1
                detail = "missing" if not fs_value else "bare/TBD/placeholder"
                fail(
                    f"{rel} — {bd_id} is in active design (session-state "
                    f"`active[]`) but its `File/Symbol` field is {detail} (no "
                    f"structured repo-relative path list). The cross-BD "
                    f"collision scan (Check 82 / the design-time blast-radius "
                    f"intersection) needs ≥1 parseable surface side. "
                    f"Remediation: replace the placeholder with a structured "
                    f"backtick repo-relative path list. Per BD-255 design "
                    f"§3.3 C-i (the F4 structured-surface prerequisite)."
                )
            else:
                active_ok += 1
        else:
            if not structured:
                warned += 1
                warn(
                    f"{rel} — {bd_id} (open, not yet in active design) has a "
                    f"bare/TBD/missing `File/Symbol` field; structure it into a "
                    f"repo-relative path list before the architect stage so "
                    f"the cross-BD collision scan can key on it (advisory only "
                    f"— NOT a gate failure; Check-48 warn idiom). Per BD-255 "
                    f"design §3.3 C-i."
                )

    if failed == 0:
        ok(
            f"Check 81 — every active-design BD ({len(active_ids)} in "
            f"session-state `active[]`; {active_ok} with a structured "
            f"File/Symbol) carries a structured repo-relative path list; "
            f"{warned} not-yet-active open BD(s) with a bare/TBD field WARNed "
            f"(advisory, exit code unaffected)."
        )


def check_cross_bd_surface_advisory() -> None:
    """Check 82 — cross-BD shared-edit-surface advisory (BD-255 Part C,
    design §3.3 C-ii; ADVISORY backstop).

    Parses every active-state open `backlog/BD-*.md` `File/Symbol` field for
    its backtick repo-relative path tokens, builds a `surface → [BD-IDs]` map,
    and WARNs (advisory, NEVER `fail()` — the Check-48 precedent; two open BDs
    legitimately co-editing a surface is NORMAL, the signal is "coordinate,"
    not "forbidden") when ≥2 open BDs name the SAME surface. The design-time
    blast-radius intersection scan (the C-i pipeline rule, landed separately)
    is the load-bearing prevention; this CI backstop is defense-in-depth.

    C2-PROOF (re-derived): #82 WARNs on the BD-245↔BD-253 collision — both name
    `project-template/scripts/validate-docs.sh` in their structured/likely
    surface fields. The shared surface + the BD pair are named in the WARN.

    Cheap (ci-check-runtime-compounding): one line scan + regex over each
    small open entry's File/Symbol field (~28 entries today) + an in-memory
    map build. No subprocess, no tree walk.
    """
    print(
        "\n── Check 82: cross-BD shared-edit-surface advisory (BD-255) ──"
    )

    surface_to_bds = {}
    for _rel, bd_id, _status, fs_value in _check_81_iter_open_bds():
        if not fs_value:
            continue
        seen = set()  # de-dup repeated paths within one entry's field
        for m in _CHECK_81_PATH_TOKEN_RE.finditer(fs_value):
            surface = m.group(1)
            if surface in seen:
                continue
            seen.add(surface)
            surface_to_bds.setdefault(surface, []).append(bd_id)

    overlaps = 0
    for surface in sorted(surface_to_bds):
        bds = sorted(set(surface_to_bds[surface]))
        if len(bds) >= 2:
            overlaps += 1
            warn(
                f"shared edit surface `{surface}` is claimed by {len(bds)} "
                f"open BDs: {', '.join(bds)} — coordinate/sequence these "
                f"(advisory only, NOT a gate failure; the load-bearing "
                f"prevention is the design-time blast-radius intersection "
                f"scan). Per BD-255 design §3.3 C-ii."
            )

    ok(
        f"Check 82 — cross-BD surface advisory: {overlaps} shared "
        f"surface(s) WARNed across {len(surface_to_bds)} distinct surface(s) "
        f"named by active-state open BDs; advisory only (exit code "
        f"unaffected)."
    )


# ── BD-252 session-state snapshot — Checks 77/78/79 ────────────────────────
# The `_SESSION_STATE_*` constants + `_session_state_load()` moved to
# validate_checks.core (BD-256 W1 seam — read by Checks 77/78/79, which land in
# a later wave) — re-imported via the facade's `from validate_checks.core import
# *` above. The committed, CLI-agnostic resumable session-state snapshot
# (`pack-ops/session-state.json`) schema + grammar detectors travel with the
# definitions in core.py.


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


# ── Check 61: fixture-dependent test location backstop (BD-219 redesign) ────
#
# The BD-219 dynamic-autoregen redesign uses LOCATION-based fixture cohesion:
# a test that depends on a BUILT fixture (test-fixtures/<name>/, a gitignored
# build artifact) MUST live under scripts/tests/fixture-dependent/, so the
# partitioner auto-pins it into the single shard that builds fixtures. A
# fixture-dependent test SAVED ELSEWHERE would land in a non-fixture shard and
# either redden CI (loud) or silently SKIP (effectiveness loss). This backstop
# converts "saved in the wrong dir" from a silent-SKIP / CI-RED surprise into a
# named, early, fix-recipe'd guard hit.
#
# Signal (H2 lower-bound, measure-then-bound): a KEEP test whose BODY references
# a built `test-fixtures/<NAME>` path where NAME is a build.sh FIXTURE_NAMES
# entry. False positives (a prose/comment mention that is NOT a real fixture
# dependency) are designed to ZERO on the current tree by rewording the two
# benign comment mentions (pack-help-test.sh, test-migrate-v10-to-v11-decompose.sh)
# so they do not name a FIXTURE_NAMES fixture verbatim — Check 61 needs NO
# exempt list. If a NEW non-fixture test legitimately must name a FIXTURE_NAMES
# path in prose, reword the mention (the cheap, drift-free fix) rather than
# widening this guard.


def _load_fixture_names():
    """Return the build.sh FIXTURE_NAMES set (the H2 backstop signal source).

    Single source: parse the `readonly FIXTURE_NAMES=( ... )` array in
    test-fixtures/build.sh. Returns an empty set if the file or array is absent
    (the caller treats an empty set as "no signal" → lenient SKIP).
    """
    build_sh = REPO_ROOT / "test-fixtures" / "build.sh"
    if not build_sh.is_file():
        return set()
    text = build_sh.read_text()
    m = re.search(r"readonly\s+FIXTURE_NAMES=\((.*?)\)", text, re.DOTALL)
    if not m:
        return set()
    return set(re.findall(r'"([^"]+)"', m.group(1)))


def check_fixture_dependent_location() -> None:
    """Check 61 — fixture-dependent tests live under fixture-dependent/ (BD-219).

    BD-219 dynamic-autoregen redesign backstop. Fixture cohesion is LOCATION-
    based: a test that depends on a built fixture MUST live under
    scripts/tests/fixture-dependent/ (the partitioner pins everything there into
    the single fixture-building shard). This guard catches a fixture-dependent
    test saved in the WRONG directory before it can ship as a silent-SKIP or a
    CI-RED surprise.

    For each KEEP test (disk glob − allowlist) whose BODY references a built
    `test-fixtures/<NAME>` path (NAME ∈ build.sh FIXTURE_NAMES) AND is NOT under
    scripts/tests/fixture-dependent/ → FAIL naming the file + the remediation
    "move it to scripts/tests/fixture-dependent/".

    False-positive bound (measure-then-bound): the only NON-fixture-dependent
    tests that name a FIXTURE_NAMES path do so in benign comments; those
    comments are reworded in the same commit so this guard has ZERO false
    positives and needs NO exempt list. The 5 genuinely-fixture-dependent tests
    live under fixture-dependent/ and so do NOT trigger the backstop.

    Cheap (ci-check-runtime-compounding): three dir globs + one small read +
    one regex per KEEP file (same cost class as Check 42); no subprocess, no
    real-tree scan. Routes through `run_check`.

    Lenient: if build.sh / FIXTURE_NAMES is absent (no signal) → SKIP.
    """
    print("\n── Check 61: fixture-dependent tests live under fixture-dependent/ (BD-219) ──")
    scripts_dir = REPO_ROOT / "scripts"
    tests_dir = scripts_dir / "tests"
    fxdep_dir = tests_dir / "fixture-dependent"
    allowlist_path = scripts_dir / "ci-test-wiring-allowlist.txt"

    fixture_names = _load_fixture_names()
    if not fixture_names:
        ok("test-fixtures/build.sh FIXTURE_NAMES absent — skipping (lenient)")
        return

    # Disk KEEP set — same three explicit non-recursive dirs as Check 42.
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

    allowlist = set()
    if allowlist_path.is_file():
        for raw in allowlist_path.read_text().splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            allowlist.add(line.split()[0])
    keep = sorted(disk_paths - allowlist)

    # H2 signal: a body reference to test-fixtures/<NAME> for a FIXTURE_NAMES
    # NAME. Anchor the path so a bare `test-fixtures/manifest.txt` or
    # `test-fixtures/<non-FIXTURE_NAMES>/` does not match.
    names_alt = "|".join(re.escape(n) for n in sorted(fixture_names))
    signal = re.compile(r"test-fixtures/(?:" + names_alt + r")(?:[/\"' ]|$)")

    prefix = "scripts/tests/fixture-dependent/"
    misplaced = []
    for rel in keep:
        if rel.startswith(prefix):
            continue  # correctly placed — location is the cohesion signal
        try:
            body = (REPO_ROOT / rel).read_text()
        except OSError:
            continue
        if signal.search(body):
            misplaced.append(rel)

    if misplaced:
        for rel in misplaced:
            fail(
                f"{rel} — references a built fixture (test-fixtures/<FIXTURE_NAME>) "
                f"but is NOT under scripts/tests/fixture-dependent/. The BD-219 "
                f"CI partitioner uses LOCATION-based fixture cohesion: a "
                f"fixture-dependent test MUST live under "
                f"scripts/tests/fixture-dependent/ so it is pinned into the "
                f"single shard that builds fixtures. Remediation: move it to "
                f"scripts/tests/fixture-dependent/ (and fix its `../` repo-root "
                f"depth). If the reference is a benign prose/comment mention "
                f"(NOT a real fixture dependency), reword the comment so it does "
                f"not name a FIXTURE_NAMES fixture verbatim."
            )
        return

    ok(
        f"Check 61 — {len(keep)} KEEP test(s) scanned; every test that "
        f"references a built fixture lives under scripts/tests/fixture-dependent/"
        f" (location-based cohesion intact; zero misplaced fixture tests)."
    )


def check_manifest_structural() -> None:
    """Check 62 — test-fixtures/manifest.txt is structurally well-formed (BD-228).

    BD-228 push-time-manifest method backstop (design §3.2). A CHEAP structural
    well-formedness SCREEN on the committed manifest — NOT the authoritative
    SHA-correctness gate. The authoritative gate stays the existing CI
    `test-fixtures/build.sh --verify` step (DESIGN §3.1), which rebuilds the
    fixtures and compares each row's SHA against the freshly-built fixture HEAD.
    Check 62 only catches a truncated / garbled / wrong-row-count / wrong-name /
    non-hex manifest INSTANTLY in the always-run `validate` job, before the
    expensive rebuild runs.

    It deliberately does NOT assert SHA-CORRECTNESS (only that each SHA is a
    40-hex token), so a comment-only edit to a fixture input that legitimately
    leaves the manifest unchanged is never a false positive (DESIGN §3.2(ii)).

    Asserts (on test-fixtures/manifest.txt, skipping `#`/blank lines):
      (a) exactly len(FIXTURE_NAMES) data rows (== 6 on the current tree);
      (b) the row NAMES, as a SET, equal `_load_fixture_names()`
          (the build.sh FIXTURE_NAMES set — the single source of truth);
      (c) each row is `<name>  <sha>` and the SHA matches `^[0-9a-f]{40}$`.

    Cheap (ci-check-runtime-compounding): ONE small file read + a per-line
    regex over the 6-row manifest + reuse of the existing `_load_fixture_names()`
    helper. NO fixture rebuild, NO subprocess, NO subprocess-per-entry, NO
    whole-real-tree scan — negligible cost across the ~155-invocation battery.
    Routes through `run_check`.

    Lenient: if build.sh / FIXTURE_NAMES is absent (no signal source) → SKIP
    (mirrors the Check 61 lenient pattern; the names set is the screen's oracle).
    """
    print("\n── Check 62: test-fixtures/manifest.txt is structurally well-formed (BD-228) ──")
    manifest_path = REPO_ROOT / "test-fixtures" / "manifest.txt"
    expected_names = _load_fixture_names()
    if not expected_names:
        ok("test-fixtures/build.sh FIXTURE_NAMES absent — skipping (lenient)")
        return
    if not manifest_path.is_file():
        fail(
            "test-fixtures/manifest.txt is MISSING but build.sh FIXTURE_NAMES is "
            "present. The committed manifest is the only product of build.sh and "
            "MUST exist. Remediation: run `bash test-fixtures/build.sh --all "
            "--clean` (or `bash scripts/manifest-sync.sh`) and commit the result."
        )
        return

    sha_re = re.compile(r"^[0-9a-f]{40}$")
    seen_names = []
    for lineno, raw in enumerate(manifest_path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 2:
            fail(
                f"test-fixtures/manifest.txt line {lineno}: expected exactly two "
                f"whitespace-separated fields `<fixture-name>  <sha>`, got "
                f"{len(parts)}: {line!r}. The manifest is generated by build.sh; "
                f"do not hand-edit — run `bash scripts/manifest-sync.sh`."
            )
            continue
        name, sha = parts
        if not sha_re.match(sha):
            fail(
                f"test-fixtures/manifest.txt line {lineno}: SHA {sha!r} for "
                f"fixture {name!r} is not a 40-character lowercase hex git SHA "
                f"(^[0-9a-f]{{40}}$). Check 62 is a structural screen; "
                f"SHA-correctness is enforced by `build.sh --verify` in CI."
            )
        seen_names.append(name)

    expected_count = len(expected_names)
    if len(seen_names) != expected_count:
        fail(
            f"test-fixtures/manifest.txt has {len(seen_names)} data row(s); "
            f"expected exactly {expected_count} (one per build.sh FIXTURE_NAMES "
            f"entry). The manifest is generated by build.sh; do not hand-edit — "
            f"run `bash scripts/manifest-sync.sh`."
        )

    seen_set = set(seen_names)
    if seen_set != expected_names:
        missing = sorted(expected_names - seen_set)
        extra = sorted(seen_set - expected_names)
        fail(
            f"test-fixtures/manifest.txt row names do not match build.sh "
            f"FIXTURE_NAMES. missing={missing} extra={extra}. The manifest's "
            f"fixture names must be exactly the build.sh FIXTURE_NAMES set; run "
            f"`bash scripts/manifest-sync.sh` to regenerate."
        )

    if seen_set == expected_names and len(seen_names) == expected_count:
        ok(
            f"Check 62 — test-fixtures/manifest.txt structurally well-formed: "
            f"{expected_count} data row(s), names == build.sh FIXTURE_NAMES, "
            f"every SHA a 40-hex token (structural screen only; SHA-correctness "
            f"enforced by `build.sh --verify` in CI)."
        )


def check_graphify_out_never_tracked() -> None:
    """Check 63 — graphify-out/ is never tracked (BD-225).

    BD-225 git-hygiene guard (design §5.2). `graphify-out/` is the Graphify
    knowledge-graph build artifact — a per-clone, regenerated directory that
    must NEVER be committed (it is gitignored by the `.gitignore` entry C1
    declares). This check is the CI enforcement that pairs with that
    `.gitignore` entry: it FAILs loud the moment any `graphify-out/` path is
    tracked, so a stray `git add` of the build artifact can never slip in.

    Measure-then-bound (ci-guard-measure-then-bound): the guard's matching
    logic — `git ls-files graphify-out/` — returns 0 rows at HEAD, so the
    legitimate tracked-graph-artifact set is EMPTY. There is nothing to
    allowlist; the guard runs CLEAN against current AND projected-post-C1
    state, and the allowlist is sized to exactly zero.

    O(1) cost (ci-check-runtime-compounding): a SINGLE `git ls-files
    graphify-out/` subprocess — NO tree scan, NO per-entry subprocess storm.
    The cost is ~0 regardless of the battery's per-invocation multiplier.
    Routes through `run_check`.

    Resolves the git root via `cwd=REPO_ROOT` (the module-level constant) so
    the per-check test can monkeypatch `mod.REPO_ROOT` to a /tmp repo (N-4 —
    mirrors the Check 62 test's technique).

    Lenient ONLY if `git` itself is unavailable (mirrors Check 62's
    lenient-skip); never swallows a real "tracked path found" failure.
    """
    print("\n── Check 63: graphify-out/ is never tracked (BD-225) ──")
    try:
        result = subprocess.run(
            ["git", "ls-files", "graphify-out/"],
            capture_output=True, text=True, cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        ok("git not available — skipping (lenient)")
        return
    if result.returncode != 0:
        ok("git ls-files unavailable (not a git work tree) — skipping (lenient)")
        return

    tracked = [line for line in result.stdout.splitlines() if line.strip()]
    if tracked:
        fail(
            f"graphify-out/ has {len(tracked)} tracked path(s): "
            f"{', '.join(tracked)}. graphify-out/ is the Graphify knowledge-graph "
            f"build artifact — a per-clone, regenerated directory that must NEVER "
            f"be committed. Remediation: `git rm -r --cached graphify-out/` and "
            f"confirm `.gitignore` carries `graphify-out/`."
        )
        return
    ok("Check 63 — graphify-out/ is not tracked (gitignored build artifact; "
       "0 tracked paths).")


# ── Check 64 (BD-231): dangling-.example deliverable referential-integrity gate.
# The MCP/config `.example` family the BD cares about. Each member is a
# `project-template/`-rooted dotfile-`.example` whose BASENAME is cited across
# the deliverable surface (README layout block + project-template/** +
# supporting-docs/**). The matcher is BOUNDED to exactly this family
# (ci-guard-measure-then-bound): a single compiled alternation over the three
# basenames, NOT an over-broad `\b\S+\.example\b` sweep that would re-classify
# unrelated `.example` cites. Closes the Check-43 leading-dot-dotfile blind spot
# (DESIGN-BD-231 §4.1: `_CHECK_40_BARE_REF_PATTERN` requires `[A-Za-z]` first,
# so a leading-dot `.mcp.json.example` token is NEVER matched by Check 43).
_CHECK_64_EXAMPLE_FAMILY = (
    ".mcp.json.example",
    ".agents/mcp_config.json.example",
    ".codex/config.toml.example",
)
# Match either the full relative path or the bare basename for each family
# member (docs cite both forms — e.g. `.mcp.json.example` and
# `.agents/mcp_config.json.example`).
_CHECK_64_REF_PATTERN = re.compile(
    r"(?:\.agents/mcp_config\.json\.example"
    r"|\.codex/config\.toml\.example"
    r"|\.mcp\.json\.example"
    r"|\bmcp_config\.json\.example"
    r"|\bconfig\.toml\.example)"
)
# EXCLUDE path-prefixes (DESIGN-BD-231 §4.3): history is immutable, pack-only
# surfaces are not client deliverables, and the fixture trees are synthetic.
# Relative-to-REPO_ROOT POSIX prefixes.
_CHECK_64_EXCLUDE_PREFIXES = (
    "changelog/",
    "backlog/",
    "pack-ops/",
    "maintenance-docs/",
    "test-fixtures/",
    "scripts/tests/fixtures/",
    ".git/",
)
# The deliverable surface walked (DESIGN-BD-231 §4.3 INCLUDE): pack-root
# README.md (its project-template/ layout block), project-template/**,
# supporting-docs/**. README is included as a single file (only its layout
# block cites the family); the two trees are walked recursively.
_CHECK_64_INCLUDE_TREES = ("project-template", "supporting-docs")


def _check_64_basename_for(token: str) -> str:
    """Map a matched ref token to the family member basename it denotes."""
    if token.endswith("mcp_config.json.example"):
        return ".agents/mcp_config.json.example"
    if token.endswith("config.toml.example"):
        return ".codex/config.toml.example"
    return ".mcp.json.example"


def check_dangling_example_deliverable_refs() -> None:
    """Check 64 — no dangling MCP/config `.example` reference in deliverable docs (BD-231).

    Referential-integrity gate (DESIGN-BD-231 §4). For the MCP/config
    `.example` family — `.mcp.json.example` (Claude), `.agents/mcp_config.json
    .example` (Antigravity), `.codex/config.toml.example` (Codex) — every cite
    on the DELIVERABLE surface (pack-root `README.md` layout block,
    `project-template/**`, `supporting-docs/**`) MUST resolve to an existing
    file under `project-template/`. A cite of a family member whose target file
    is ABSENT is a dangling reference -> FAIL with `file:line` + the dangling
    token + a restore-or-drop remediation.

    Why a NEW check, not Check 43 (DESIGN-BD-231 §4.1): Check 43's
    `_CHECK_40_BARE_REF_PATTERN` requires the first char to be `[A-Za-z]`, so a
    leading-dot dotfile like `.mcp.json.example` is NEVER matched, and
    `.example` is not in `_CHECK_40_FILE_EXTS`. Check 43's green status is
    therefore NOT evidence these refs resolve — it is blind to them. This check
    is the targeted matcher that closes that blind spot.

    measure-then-bound (ci-guard-measure-then-bound): the matcher is bounded to
    exactly the three-member MCP/config family (`_CHECK_64_REF_PATTERN`), NOT an
    over-broad `.example` sweep; the surface is bounded to the deliverable
    INCLUDE trees minus the EXCLUDE path-prefixes (history / pack-only /
    fixtures). Every KEEP cite auto-passes once its target exists — there is no
    basename allowlist that could silently admit a real dangling ref; the only
    bound is the EXCLUDE list.

    Cheap (ci-check-runtime-compounding): a single bounded walk over README +
    project-template/** + supporting-docs/** with ONE compiled-regex scan per
    line — no whole-tree scan, no per-entry subprocess. Routes through
    `run_check`.

    Resolves all paths via `REPO_ROOT` (the module-level constant) so the
    per-check test can monkeypatch `mod.REPO_ROOT` to a /tmp fixture root and
    exercise the dangling-ref FAIL path without touching the real tree.
    """
    print("\n── Check 64: no dangling MCP/config .example deliverable refs (BD-231) ──")

    # The legitimate target set: family members that actually exist under
    # project-template/. A cite resolves iff its basename is present here.
    present_targets = set()
    for rel in _CHECK_64_EXAMPLE_FAMILY:
        if (REPO_ROOT / "project-template" / rel).is_file():
            present_targets.add(rel)

    def _excluded(rel_posix: str) -> bool:
        return any(rel_posix.startswith(p) for p in _CHECK_64_EXCLUDE_PREFIXES)

    # Build the bounded deliverable file set.
    walked: list[Path] = []
    readme = REPO_ROOT / "README.md"
    if readme.is_file():
        walked.append(readme)
    for tree in _CHECK_64_INCLUDE_TREES:
        root = REPO_ROOT / tree
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            rel_posix = path.relative_to(REPO_ROOT).as_posix()
            if _excluded(rel_posix):
                continue
            walked.append(path)

    dangling = []          # (file:line, token, basename)
    refs_checked = 0
    for path in walked:
        rel_posix = path.relative_to(REPO_ROOT).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue       # binary / unreadable file — nothing to cite
        for lineno, line in enumerate(text.splitlines(), start=1):
            for m in _CHECK_64_REF_PATTERN.finditer(line):
                token = m.group(0)
                basename = _check_64_basename_for(token)
                refs_checked += 1
                if basename not in present_targets:
                    dangling.append((f"{rel_posix}:{lineno}", token, basename))

    if dangling:
        for loc, token, basename in dangling:
            fail(
                f"{loc} — dangling MCP/config .example reference `{token}`: "
                f"the cited deliverable template `project-template/{basename}` "
                f"does NOT exist. Remediation: restore "
                f"`project-template/{basename}` OR drop the cite. (BD-231 Check 64)"
            )
        return

    ok(
        f"Check 64 — {len(walked)} deliverable file(s) walked; {refs_checked} "
        f"MCP/config .example reference(s) checked; every cite resolves to an "
        f"existing project-template/ template ({len(present_targets)} family "
        f"target(s) present)."
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


def check_removed_doc_advisory() -> None:
    """Check 48 — JC-5 soft-advisory removed-doc guard (BD-195 C6).

    SOFT-ADVISORY ONLY: WARNs (never fail()s; never changes the exit
    code) when a citation in a scanned file resolves to a doc REMOVED
    from the repo. Covers the K3.12 + K3.13 accurate-history citations
    WITHOUT hand-correcting them (JC-5: leave accurate v8/v9 + process
    history intact).

    BD-203 A12: the citations relocated from the two deleted monoliths
    INTO the per-entry trees, so the scan walks every `*.md` file under
    the `/backlog/` + `/changelog/` directories (`_REMOVED_DOC_SCAN_DIRS`)
    instead of the monolith files. SKIP-on-absent is preserved (a tree
    absent at this HEAD is not an advisory condition).

    Measure-then-bound (PLAN-BD-195-REMEDIATION.md §2.3): the bounded
    set of removed-doc basenames is frozen in `_REMOVED_DOC_BASENAMES`
    (each verified ABSENT from the tree at design time). Every hit is a
    warning; NONE is a STRIP / gate failure.

    The token boundary `(?<![\\w.-])` / `(?![\\w-])` ensures
    `ARCHITECTURE-BD-185.md` does NOT match the LIVE
    `ARCHITECTURE-BD-185-V2.md` (and likewise `PLAN-BD-185.md` vs
    `PLAN-BD-185-V2.md`) while still matching path-form citations such
    as `supporting-docs/GEMINI-CLI-ANALYSIS.md` and
    `maintenance-docs/V10-PREDESIGN.md`.
    """
    print("\n── Check 48: JC-5 soft-advisory removed-doc guard (BD-195) ──")

    # Compile the basename alternation ONCE. Leading guard rejects a
    # preceding word char, `.`, or `-` so a longer live basename that
    # merely ends with a removed name is not matched (but a `/` path
    # separator IS allowed — path-form citations are still removed-doc
    # references); trailing guard rejects a following word char or `-`
    # so `ARCHITECTURE-BD-185.md` does not match inside the live
    # `ARCHITECTURE-BD-185-V2.md`.
    alternation = "|".join(re.escape(name) for name in _REMOVED_DOC_BASENAMES)
    pattern = re.compile(r"(?<![\w.-])(?:" + alternation + r")(?![\w-])")

    total_hits = 0
    dirs_scanned = 0
    for stream_rel in _REMOVED_DOC_SCAN_DIRS:
        stream_dir = REPO_ROOT / stream_rel
        if not stream_dir.is_dir():
            # Lenient: a tree absent at this HEAD is not an advisory
            # condition (nothing to scan).
            continue
        dirs_scanned += 1
        for entry in sorted(stream_dir.glob("*.md")):
            rel = entry.relative_to(REPO_ROOT)
            try:
                text = entry.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                # Read failure is surfaced by other checks; the
                # soft-advisory simply skips an unreadable file.
                continue
            for line_no, line in enumerate(text.splitlines(), start=1):
                for m in pattern.finditer(line):
                    total_hits += 1
                    warn(
                        f"{rel}:{line_no} cites `{m.group(0)}` — a removed doc "
                        f"(JC-5 accurate-history citation; advisory only, NOT a "
                        f"gate failure, NOT hand-corrected)"
                    )

    # Always an OK summary line — the advisory NEVER fails the gate.
    ok(
        f"Check 48 — soft-advisory removed-doc scan: {total_hits} "
        f"removed-doc citation(s) WARNed across {dirs_scanned} per-entry "
        f"tree dir(s); advisory only (exit code unaffected)"
    )


# ── Check 49: migrator field/body faithfulness (BD-204 §4.2/§4.6) ──────────
#
# The deep CI guard that fails a LOSSY or CORRUPTING forward→reverse tracker
# migration (the C-2 19-field-drop hazard) OR a body-limit/title breach — the
# exact gap that shipped green in the dead `pack-extra-fields` carrier. It
# drives the SINGLE-SOURCED batch codec (Option B; design §4.6 (S)), NOT a
# reproduced codec (OQ-4 — see the §4.5 single-source check below) and NOT the
# per-entry real functions (Option A = measured 142 s, rejected).
#
# Three mandatory runtime constraints (`ci-check-runtime-compounding`, §4.6):
#   (P) ENV-GATE — the FIRST statement early-returns a SKIP unless
#       PACK_VALIDATE_DEEP=1, BEFORE any tree read, so the 151× general battery
#       path pays ~0 (the prior C-4.6 ran the heavy scan in the 151× main()).
#   (T) TARGET-TREE SCOPING — the check validates the CALLER's `tree_dir`, with
#       NO `tree_dir or REPO_ROOT/"backlog"` fallback (that `or` was the exact
#       C-4.6 bug: a 3-entry fixture paid the full real-211 cost).
#   (S) SEAM = the SHARED BATCH CODEC — ONE python3 over all entries via the
#       real `_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` /
#       `_tmf_neutralize_autolinks_batch` / `tmf_compose_issue_body_batch`
#       (measured 0.05 s), so the guard shares the production codec and cannot
#       FALSE-PASS a lossy codec change.
#
# The BYTE LEG is the §4.6.2 TWO-ASSERTION contract (NOT the forbidden
# `decode(encode(raw_body)) == raw_body` tautology):
#   (a) CODEC-LOSSLESS  decode(encode(raw_body)) == raw_body — the shared batch
#       codec round-trips the captured bytes; AND
#   (b) PARSE-FAITHFUL  PRE_PARSE_ORIGINAL_body == raw_body — the parser's
#       captured span equals the entry FILE's lines 2..EOF read BYTE-SAFELY
#       (a direct byte read of the file after the first `\n`, NEVER awk/a
#       text-normalizing read). THIS IS THE C-2 CATCH: if the parser strips/
#       normalizes ANY byte (a CR, a NUL, a field line, a prose block) leg (b)
#       FAILs. (Belt-and-suspenders with R-BODY-6, which scans the same raw
#       file bytes for a control byte.)
#
# Plus, per design §4.4/§3.3c/§3.3e:
#   - R-BODY-6 control-char leg: scan the entry FILE bytes (pre-parse, not a
#     decoded string) for NUL / CR / disallowed-C0-other-than-tab/LF.
#   - SIZE leg: the REAL composed Issue body length (via the shared batch
#     composer/codec) < provider_body_limit − SAFETY_MARGIN.
#   - TITLE leg: the ID-prefixed bold-header title ≤ 256 CODEPOINTS (R-TITLE-1).

# The bash seam that sources the migrator libs ONCE and drives the shared batch
# functions in ONE process each (Option B; design §4.6 (S)). It materializes
# the parse JSON + the framed decode + the framed composed-body into a temp
# dir, and prints `body_limit<TAB>margin` on stdout for the size leg. The
# guard's Python side reads the FILE bytes directly for the PRE-PARSE ORIGINAL
# (leg b) + R-BODY-6, so this seam carries only the codec/composer work.
_CHECK_49_SEAM_SCRIPT = r'''
set -u
LIB="$1"; TREE_KEY="$2"; TREE_DIR="$3"; OUTDIR="$4"
. "$LIB/per-entry/_lib.sh"
. "$LIB/tracker-errors.sh"
. "$LIB/tracker-config.sh" 2>/dev/null || true
. "$LIB/tracker-provider.sh"
. "$LIB/tracker-provider-gh.sh"
. "$LIB/tracker-migrate-forward.sh"
. "$LIB/tracker-migrate-reverse.sh"

# 1. Parse the TARGET tree → entries JSON (the SAME real parser the migration
#    uses; raw_body is the round-trip truth).
tmf_parse_backlog_tree "$TREE_KEY" "$TREE_DIR" > "$OUTDIR/tree.json" || exit 11

# 2. Frame every raw_body (length-prefixed _TMF_BATCH protocol; arbitrary
#    bytes safe), then drive the SHARED BATCH codec encode→decode in ONE
#    python3 each (Option B; no per-entry storm, no reproduction).
python3 - "$OUTDIR/tree.json" > "$OUTDIR/raw.frame" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
recs = [e["raw_body"].encode("utf-8") for e in d]
w = sys.stdout.buffer
w.write(("%d\n" % len(recs)).encode("ascii"))
for r in recs:
    w.write(("%d\n" % len(r)).encode("ascii")); w.write(r)
PY
_tmf_gz64_encode_batch     < "$OUTDIR/raw.frame" > "$OUTDIR/enc.frame" || exit 12
_tmr_decode_body_blob_batch < "$OUTDIR/enc.frame" > "$OUTDIR/dec.frame" || exit 13

# 3. Drive the SHARED BATCH composer over all entries (the REAL composer's
#    assembly: markers + neutralized H2 + gz64 blob) for the SIZE leg — its
#    output frame carries the real composed-body length per entry.
python3 - "$OUTDIR/tree.json" <<'PY' | tmf_compose_issue_body_batch > "$OUTDIR/composed.frame" || exit 14
import sys, json
d = json.load(open(sys.argv[1]))
w = sys.stdout.buffer
w.write(("%d\n" % len(d)).encode("ascii"))
for e in d:
    for key in ("pack_id", "description", "context", "resolution",
                "file_symbol", "raw_body"):
        b = (e.get(key) or "").encode("utf-8")
        w.write(("%d\n" % len(b)).encode("ascii")); w.write(b)
PY

# 4. The ACTIVE provider's body limit + the migrator's safety margin (the SAME
#    measurement the forward composer's §3.3c overflow gate uses).
BODY_LIMIT="$(printf '%s' "$(provider_capabilities 2>/dev/null)" | jq -r '.body.limit // empty' 2>/dev/null)"
MARGIN="${TMF_SIZE_SAFETY_MARGIN:-2048}"
printf '%s\t%s\n' "$BODY_LIMIT" "$MARGIN"
'''


def _check_49_read_frames(path):
    """Read a _TMF_BATCH length-prefixed framed stream → list[bytes]."""
    data = Path(path).read_bytes()
    i = data.index(b"\n")
    n = int(data[:i])
    pos = i + 1
    out = []
    for _ in range(n):
        j = data.index(b"\n", pos)
        length = int(data[pos:j])
        pos = j + 1
        out.append(data[pos:pos + length])
        pos += length
    return out


def _check_49_stream_key_for_tree(tree_path) -> str:
    """Resolve the per-entry STREAM KEY for a target tree (BD-204 C-4.6 F-3).

    The key only labels the stream for the seam's `pe_list_entry_files`
    entry-regex; the codec/byte work is key-agnostic. DERIVE it from the
    target tree's directory name against the `STREAMS` table (the SSOT for
    `stream_key ↔ stream_dir_relative`) — never hardcode — so a changelog-
    stream caller (`pack-changelog`) or a relocated tree resolves correctly.
    Defaults to `pack-backlog` (both §3.LF.5 deep homes target `/backlog/`)
    when no `STREAMS` row matches the tree's basename.
    """
    name = Path(tree_path).name
    for stream_key, stream_dir_relative, _mirror, _regex in STREAMS:
        if name == Path(stream_dir_relative).name:
            return stream_key
    return "pack-backlog"


# Disallowed control bytes (R-BODY-6): NUL, CR, and any C0 control char OTHER
# than tab (0x09) and LF (0x0A). DEL (0x7f) is included.
_CHECK_49_DISALLOWED_CONTROL = (
    set(range(0x00, 0x20)) - {0x09, 0x0A}
) | {0x7F}

# R-TITLE-1: the stored ID-prefixed title must be ≤ 256 CODEPOINTS.
_CHECK_49_TITLE_MAX_CODEPOINTS = 256
# The per-entry bold-header grammar (mirrors `_tmf_parse_backlog_file`'s
# ENTRY_HEADER) — group 1 = pack-id, group 2 = title text.
_CHECK_49_ENTRY_HEADER_RE = re.compile(
    r"^\*\*((?:BD|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$"
)


def check_migrator_field_faithfulness(tree_dir) -> None:
    """Check 49 — migrator field/body faithfulness (BD-204 §4.2/§4.6).

    `tree_dir` = the CALLER's target per-entry tree (a `Path`). DEEP-GATED:
    runs the heavy whole-tree verification ONLY under PACK_VALIDATE_DEEP=1
    (§4.6 (P)); the default path is a ~0 ms SKIP. There is NO
    `tree_dir or REPO_ROOT/"backlog"` fallback (§4.6 (T) — that `or` was the
    C-4.6 bug).
    """
    # (P) ENV-GATE — the FIRST statement, BEFORE any tree read. The 151×
    # general battery path early-returns here paying ~0.
    if os.environ.get("PACK_VALIDATE_DEEP") != "1":
        ok("SKIP: field-faithfulness deep check (set PACK_VALIDATE_DEEP=1)")
        return

    print("\n── Check 49: migrator field/body faithfulness (BD-204, DEEP) ──")
    tree_path = Path(tree_dir)
    if not tree_path.is_dir():
        fail(f"Check 49 — target tree {tree_path} is not a directory")
        return

    lib_dir = REPO_ROOT / "scripts" / "lib"
    # Stream key: DERIVE from `tree_dir` rather than hardcode (BD-204 C-4.6
    # review F-3). The key only labels the stream for `pe_list_entry_files`'s
    # entry-regex; the byte work is key-agnostic. Match the target tree's
    # directory name against the STREAMS table (the SSOT for stream_key ↔
    # stream_dir) so a future changelog-stream caller (or a relocated tree)
    # resolves the correct key instead of mis-labelling everything
    # `pack-backlog`. Default to `pack-backlog` for the `/backlog/` deep homes
    # (both §3.LF.5 deep homes today) when no STREAMS row matches.
    tree_key = _check_49_stream_key_for_tree(tree_path)

    with tempfile.TemporaryDirectory(prefix="vp-check49-") as outdir:
        # (S) SEAM = the SHARED BATCH CODEC — ONE bash invocation sourcing the
        # libs once and driving the real batch functions in one python3 each.
        result = subprocess.run(
            ["bash", "-c", _CHECK_49_SEAM_SCRIPT, "_",
             str(lib_dir), tree_key, str(tree_path), outdir],
            capture_output=True, text=True, stdin=subprocess.DEVNULL,
        )
        if result.returncode != 0:
            fail(
                f"Check 49 — shared batch-codec seam failed "
                f"(rc={result.returncode}); stderr: {result.stderr.strip()}"
            )
            return

        try:
            entries = json.loads((Path(outdir) / "tree.json").read_text())
            decoded = _check_49_read_frames(Path(outdir) / "dec.frame")
            composed = _check_49_read_frames(Path(outdir) / "composed.frame")
        except Exception as exc:  # noqa: BLE001 — surface any seam-output defect
            fail(f"Check 49 — could not read seam output: {exc}")
            return

        last = result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ""
        body_limit_raw, _, margin_raw = last.partition("\t")
        body_limit = int(body_limit_raw) if body_limit_raw.isdigit() else None
        margin = int(margin_raw) if margin_raw.strip().isdigit() else 2048

        n = len(entries)
        if not (len(decoded) == n and len(composed) == n):
            fail(
                f"Check 49 — seam record-count mismatch: {n} entries, "
                f"{len(decoded)} decoded, {len(composed)} composed"
            )
            return

        any_fail = False
        for idx, entry in enumerate(entries):
            pid = entry.get("pack_id", f"<entry-{idx}>")
            raw_body = (entry.get("raw_body") or "").encode("utf-8")

            # (a) CODEC-LOSSLESS — decode(encode(raw_body)) == raw_body.
            if decoded[idx] != raw_body:
                any_fail = True
                fail(
                    f"Check 49 — {pid}: codec round-trip is LOSSY "
                    f"(decode(encode(raw_body)) != raw_body): "
                    f"{_check_49_first_diff(raw_body, decoded[idx])}"
                )

            # (b) PARSE-FAITHFUL — PRE_PARSE_ORIGINAL_body == raw_body.
            # PRE_PARSE_ORIGINAL = the FILE's lines 2..EOF read BYTE-SAFELY
            # (a direct byte read after the first `\n`; NEVER awk). The C-2
            # catch: a parser-stripped/normalized byte makes this differ.
            entry_file = tree_path / f"{pid}.md"
            pre_parse_original = None
            if entry_file.is_file():
                file_bytes = entry_file.read_bytes()
                nl = file_bytes.find(b"\n")
                pre_parse_original = file_bytes[nl + 1:] if nl >= 0 else b""
                if pre_parse_original != raw_body:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: PARSE-FAITHFUL leg FAILED "
                        f"(PRE_PARSE_ORIGINAL != raw_body — the C-2 catch; a "
                        f"parse step stripped/normalized a byte): "
                        f"{_check_49_first_diff(pre_parse_original, raw_body)}"
                    )

                # R-BODY-6 control-char leg — scan the RAW FILE bytes (pre-parse,
                # not a decoded string) for a disallowed control byte.
                bad = _check_49_first_control_byte(pre_parse_original)
                if bad is not None:
                    any_fail = True
                    off, byte = bad
                    fail(
                        f"Check 49 — {pid}: R-BODY-6 disallowed control byte "
                        f"0x{byte:02x} at body offset {off} (raw-file scan; "
                        f"NUL/CR/C0-other-than-tab-LF/DEL forbidden)"
                    )

            # SIZE leg — the REAL composed Issue body length (shared batch
            # composer) < provider_body_limit − SAFETY_MARGIN.
            if body_limit is not None:
                composed_bytes = len(composed[idx])
                budget = body_limit - margin
                if composed_bytes > budget:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: composed Issue body "
                        f"{composed_bytes} bytes exceeds provider body limit "
                        f"{body_limit} − margin {margin} = {budget}"
                    )

            # TITLE leg — the ID-prefixed bold-header title ≤ 256 codepoints
            # (R-TITLE-1; CODEPOINT count, not byte count). The stored title
            # is `<ID>: <title>`.
            title = entry.get("title", "")
            if title:
                stored_title = f"{pid}: {title}"
                if len(stored_title) > _CHECK_49_TITLE_MAX_CODEPOINTS:
                    any_fail = True
                    fail(
                        f"Check 49 — {pid}: stored title {len(stored_title)} "
                        f"codepoints exceeds R-TITLE-1 limit "
                        f"{_CHECK_49_TITLE_MAX_CODEPOINTS}"
                    )

        if not any_fail:
            limit_note = (
                f"size leg vs provider body limit {body_limit} − margin {margin}"
                if body_limit is not None
                else "size leg SKIPPED (provider declares no body limit)"
            )
            ok(
                f"Check 49 — {n} entries byte-faithful (codec-lossless + "
                f"parse-faithful), control-char-clean, title ≤ "
                f"{_CHECK_49_TITLE_MAX_CODEPOINTS} codepoints, {limit_note}"
            )


def _check_49_first_control_byte(data: bytes):
    """Return (offset, byte) of the first disallowed control byte, or None."""
    for off, byte in enumerate(data):
        if byte in _CHECK_49_DISALLOWED_CONTROL:
            return (off, byte)
    return None


def _check_49_first_diff(a: bytes, b: bytes) -> str:
    """A short unified-style description of the first differing byte (§4.2)."""
    minlen = min(len(a), len(b))
    for i in range(minlen):
        if a[i] != b[i]:
            return (
                f"first differ at byte {i}: "
                f"{a[max(0, i - 8):i + 8]!r} vs {b[max(0, i - 8):i + 8]!r}"
            )
    return f"lengths differ: {len(a)} vs {len(b)} bytes"


def _session_state_iter_string_values(obj):
    """Yield every STRING value nested in a json.load-ed snapshot object.

    Recurses dicts (values only — keys are structure, not state) and lists.
    Used by C-grammar (79) to scan all state values for SHAs / dates /
    narration. Cheap — the snapshot is a small bounded object (byte cap).
    """
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from _session_state_iter_string_values(v)
    elif isinstance(obj, (list, tuple)):
        for v in obj:
            yield from _session_state_iter_string_values(v)


# `_session_state_load()` moved to validate_checks.core (BD-256 W1 seam — read
# by Checks 77/78/79 below) — re-imported via the facade's
# `from validate_checks.core import *` above.


def check_session_state_struct() -> None:
    """Check 77 — session-state snapshot structural well-formedness (BD-252).

    Parses `pack-ops/session-state.json` (`json.load`) and asserts the required
    P1-P9 key set (sized EXACTLY to the seed schema — measure-then-bound), plus
    that the two structural fields are well-typed: `boundary_commit` matches
    `^[0-9a-f]{7,40}$` and `checkpoint` is ISO-8601. Well-formedness so
    `/pack-startup` reads it deterministically and C-fresh / C-grammar can rely
    on the fields.

    SKIP-lenient when the snapshot is ABSENT (fresh clone / pre-feature HEAD —
    the seed ships in a LATER commit; until then this leg SKIPs, never fails).

    Cheap (ci-check-runtime-compounding): one small read + one json parse; no
    subprocess, no whole-tree scan.
    """
    print(
        "\n── Check 77: session-state snapshot structural well-formedness "
        "(BD-252) ──"
    )

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; the resumable "
            f"session-state snapshot is a live-state artifact, absent on a "
            f"fresh clone / pre-feature HEAD). When present, Check 77 asserts "
            f"the required P1-P9 key set + `boundary_commit` is 7-40 hex + "
            f"`checkpoint` is ISO-8601."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        fail(
            f"{_SESSION_STATE_FILE} — INVALID JSON (could not parse): "
            f"{loaded[2]}. The snapshot must be valid JSON so /pack-startup "
            f"reads it deterministically. Fix the JSON syntax."
        )
        return

    data, _raw = loaded
    any_fail = False

    if not isinstance(data, dict):
        fail(
            f"{_SESSION_STATE_FILE} — top-level JSON must be an OBJECT "
            f"(got {type(data).__name__}). The snapshot is a keyed "
            f"current-frontier object (P1-P9)."
        )
        return

    # Required-key set (sized EXACTLY to P1-P9 — measure-then-bound).
    present = set(data.keys())
    required = set(_SESSION_STATE_REQUIRED_KEYS)
    missing = sorted(required - present)
    if missing:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — missing required key(s): {missing}. The "
            f"snapshot must carry the full P1-P9 frontier set "
            f"{list(_SESSION_STATE_REQUIRED_KEYS)}."
        )

    # `boundary_commit` (P7) — present + 7-40 hex.
    bc = data.get(_SESSION_STATE_SHA_KEY)
    if _SESSION_STATE_SHA_KEY in present:
        if not isinstance(bc, str) or not _SESSION_STATE_SHA_FULL_RE.match(bc):
            any_fail = True
            fail(
                f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` must be a "
                f"7-40-char lowercase-hex commit SHA (got {bc!r}). It is the "
                f"single durable-boundary reference C-fresh resolves."
            )

    # `checkpoint` (P8) — present + ISO-8601.
    cp = data.get(_SESSION_STATE_DATE_KEY)
    if _SESSION_STATE_DATE_KEY in present:
        if not isinstance(cp, str) or not _SESSION_STATE_ISO_RE.match(cp):
            any_fail = True
            fail(
                f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_DATE_KEY}` must be an "
                f"ISO-8601 timestamp (e.g. `2026-06-29T00:00:00Z`); got {cp!r}. "
                f"It is the single freshness anchor."
            )

    if not any_fail:
        ok(
            f"Check 77 — {_SESSION_STATE_FILE}: valid JSON; required P1-P9 keys "
            f"present ({len(required)} keys); `{_SESSION_STATE_SHA_KEY}` is "
            f"7-40 hex; `{_SESSION_STATE_DATE_KEY}` is ISO-8601."
        )


def check_session_state_fresh() -> None:
    """Check 78 — session-state snapshot boundary freshness (BD-252).

    Reads `boundary_commit` and asserts it (a) resolves to a real commit
    (`git cat-file -e <sha>^{commit}`) AND (b) is an ancestor-of-or-equal-to
    HEAD (`git merge-base --is-ancestor <sha> HEAD`). When the boundary lags
    HEAD by more than the advisory threshold
    (`git rev-list --count <sha>..HEAD` > _SESSION_STATE_FRESH_WARN_THRESHOLD)
    the check ADVISORY-WARNs (NOT a fail — GATE DECISION 2).

    N2 (expected, not a failure): C-fresh advisory-WARNs as HEAD advances past a
    committed seed — the seed lags by the count of commits authored since it was
    written. That is the overwrite-on-every-change contract surfacing, not a
    defect; the WARN never changes the exit code.

    SKIP-lenient when the snapshot is ABSENT, when `boundary_commit` is absent /
    malformed (Check 77 owns that hard failure — C-fresh does not double-fail),
    or when git is unavailable / not a work tree (the Check 69 lenient idiom).

    Cheap (ci-check-runtime-compounding): one small read + 1-3 tiny git calls;
    no whole-tree scan.
    """
    print("\n── Check 78: session-state snapshot boundary freshness (BD-252) ──")

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; live-state "
            f"artifact absent on a fresh clone / pre-feature HEAD). When "
            f"present, Check 78 asserts `boundary_commit` resolves + is "
            f"ancestor-of-HEAD; advisory-WARN if it lags HEAD by "
            f">{_SESSION_STATE_FRESH_WARN_THRESHOLD} commit(s)."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        ok(
            f"{_SESSION_STATE_FILE} unparseable — skipping freshness (lenient; "
            f"Check 77 owns the JSON-parse failure)."
        )
        return

    data, _raw = loaded
    sha = data.get(_SESSION_STATE_SHA_KEY) if isinstance(data, dict) else None
    if not isinstance(sha, str) or not _SESSION_STATE_SHA_FULL_RE.match(sha):
        ok(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` absent / "
            f"malformed; skipping freshness (lenient; Check 77 owns that "
            f"structural failure)."
        )
        return

    def _git(args):
        try:
            return subprocess.run(
                ["git", *args], capture_output=True, text=True, cwd=REPO_ROOT,
            )
        except FileNotFoundError:
            return None

    # Git availability / work-tree probe (lenient SKIP — Check 69 idiom).
    probe = _git(["rev-parse", "--is-inside-work-tree"])
    if probe is None or probe.returncode != 0:
        ok(
            f"git unavailable / not a git work tree — skipping freshness "
            f"(lenient; never hard-fail a non-git environment)."
        )
        return

    # (a) boundary resolves to a real commit.
    exists = _git(["cat-file", "-e", f"{sha}^{{commit}}"])
    if exists is None or exists.returncode != 0:
        fail(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha!r} does "
            f"NOT resolve to a commit in this repo. The boundary must be a real "
            f"reachable commit. Re-author the snapshot at the current boundary "
            f"(the last landed commit SHA)."
        )
        return

    # (b) boundary is ancestor-of-or-equal-to HEAD.
    ancestor = _git(["merge-base", "--is-ancestor", sha, "HEAD"])
    if ancestor is None or ancestor.returncode != 0:
        fail(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha!r} is NOT "
            f"an ancestor of HEAD. The boundary must be a commit reachable from "
            f"HEAD (the durable frontier the snapshot was built against). "
            f"Re-author the snapshot at the current boundary."
        )
        return

    # Advisory freshness: how far behind HEAD (advisory WARN only — never fail).
    behind = _git(["rev-list", "--count", f"{sha}..HEAD"])
    n_behind = 0
    if behind is not None and behind.returncode == 0:
        n_behind = int(behind.stdout.strip() or "0")
    if n_behind > _SESSION_STATE_FRESH_WARN_THRESHOLD:
        warn(
            f"{_SESSION_STATE_FILE} — `{_SESSION_STATE_SHA_KEY}` {sha} lags "
            f"HEAD by {n_behind} commit(s) (> advisory threshold "
            f"{_SESSION_STATE_FRESH_WARN_THRESHOLD}). ADVISORY ONLY — this is "
            f"the overwrite-on-every-state-change contract surfacing (the seed "
            f"goes stale as HEAD advances; Pack Chat overwrites it on the next "
            f"transition). NOT a gate failure."
        )
    else:
        ok(
            f"Check 78 — {_SESSION_STATE_FILE}: `{_SESSION_STATE_SHA_KEY}` "
            f"{sha} resolves + is ancestor-of-HEAD ({n_behind} commit(s) "
            f"behind; <= advisory threshold "
            f"{_SESSION_STATE_FRESH_WARN_THRESHOLD})."
        )


def check_session_state_grammar() -> None:
    """Check 79 — session-state snapshot no-history grammar (BD-252).

    The bespoke anti-accretion grammar (DESIGN-RECONCILED §4). It PERMITS the
    snapshot's legitimate STATE — bare `BD-\\d+` tags (any number), exactly one
    date (only in `checkpoint`), exactly one SHA (only in `boundary_commit`) —
    and FORBIDS ACCRETION: a 2nd date, a 2nd SHA, any off-field SHA, the
    narration set (history shapes), and serialized size over the byte cap.

    Detector ORDERING (N3): the DECISIVE accretion detectors are the date / SHA
    / narration bounds; the byte cap is an anti-growth BACKSTOP (the structural
    teeth against append-growth that a token-count alone would miss) — it is
    checked LAST, after the precise bounds.

    SKIP-lenient when the snapshot is ABSENT or unparseable (Check 77 owns the
    parse failure).

    Cheap (ci-check-runtime-compounding): one small read + regex scans over a
    byte-capped object; no subprocess, no whole-tree scan.
    """
    print(
        "\n── Check 79: session-state snapshot no-history grammar (BD-252) ──"
    )

    loaded = _session_state_load()
    if loaded is None:
        ok(
            f"{_SESSION_STATE_FILE} absent — skipping (lenient; live-state "
            f"artifact absent on a fresh clone / pre-feature HEAD). When "
            f"present, Check 79 PERMITS bare BD-tags + 1 date (checkpoint) + 1 "
            f"SHA (boundary_commit) and FORBIDS accretion (2nd date/SHA, "
            f"off-field SHA, narration, size > {_SESSION_STATE_BYTE_CAP} B)."
        )
        return

    if loaded[0] == "PARSE_ERROR":
        ok(
            f"{_SESSION_STATE_FILE} unparseable — skipping grammar (lenient; "
            f"Check 77 owns the JSON-parse failure)."
        )
        return

    data, raw = loaded
    any_fail = False

    # Per-key string-value collection so date/SHA single-occurrence asserts can
    # key off the FIELD (JSON's keyed structure makes "only in `checkpoint` /
    # `boundary_commit`" exact — an advantage over a flat markdown scan).
    if isinstance(data, dict):
        sha_field_values = list(_session_state_iter_string_values(
            data.get(_SESSION_STATE_SHA_KEY)))
        date_field_values = list(_session_state_iter_string_values(
            data.get(_SESSION_STATE_DATE_KEY)))
    else:
        sha_field_values = []
        date_field_values = []
    all_values = list(_session_state_iter_string_values(data))

    # ── DECISIVE detector 1: dates. Exactly <=1 date, only in `checkpoint`.
    total_dates = 0
    off_field_dates = 0
    for v in all_values:
        hits = _SESSION_STATE_DATE_RE.findall(v)
        total_dates += len(hits)
    in_field_dates = sum(
        len(_SESSION_STATE_DATE_RE.findall(v)) for v in date_field_values)
    off_field_dates = total_dates - in_field_dates
    if total_dates > 1:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: found {total_dates} date(s) "
            f"(20YY-MM-DD); the snapshot PERMITS exactly ONE, only in "
            f"`{_SESSION_STATE_DATE_KEY}`. A 2nd dated note = a history stack. "
            f"Overwrite the frontier; move history to BD/changelog/commit."
        )
    if off_field_dates > 0:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: a date appears OUTSIDE "
            f"`{_SESSION_STATE_DATE_KEY}` ({off_field_dates} off-field). The "
            f"single checkpoint date must live ONLY in "
            f"`{_SESSION_STATE_DATE_KEY}`."
        )

    # ── DECISIVE detector 2: SHAs. Exactly <=1 SHA, only in `boundary_commit`.
    total_shas = 0
    for v in all_values:
        total_shas += len(_SESSION_STATE_SHA_RE.findall(v))
    in_field_shas = sum(
        len(_SESSION_STATE_SHA_RE.findall(v)) for v in sha_field_values)
    off_field_shas = total_shas - in_field_shas
    if total_shas > 1:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: found {total_shas} commit "
            f"SHA(s) (7-40 hex); the snapshot PERMITS exactly ONE, only in "
            f"`{_SESSION_STATE_SHA_KEY}`. Multiple stacked SHAs = the carry-"
            f"over's failure. Keep only the boundary SHA."
        )
    if off_field_shas > 0:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ACCRETION: a commit SHA appears OUTSIDE "
            f"`{_SESSION_STATE_SHA_KEY}` ({off_field_shas} off-field). The "
            f"single boundary SHA must live ONLY in `{_SESSION_STATE_SHA_KEY}`."
        )

    # ── DECISIVE detector 3: narration. ZERO history shapes. Bare BD-tags are
    # PERMITTED — strip them FIRST so a `bd-past-action` verb is the only thing
    # that fires on a BD-bearing value (a legal `"BD-219"` never trips).
    for v in all_values:
        stripped = _SESSION_STATE_BD_TAG_RE.sub("BD", v)
        for name, pat in _SESSION_STATE_NARRATION_PATTERNS:
            # bd-past-action must scan the ORIGINAL value (it needs the BD-\d+).
            scan_target = v if name == "bd-past-action" else stripped
            if pat.search(scan_target):
                any_fail = True
                fail(
                    f"{_SESSION_STATE_FILE} — ACCRETION: history/narration "
                    f"pattern `{name}` matched value {v[:80]!r}. The snapshot "
                    f"is current STATE only (bare BD-tags OK); history "
                    f"(lessons, carry notes, past-action narration) goes to "
                    f"BD/changelog/commit/handoff, never the snapshot."
                )
                break

    # ── BACKSTOP detector (N3): serialized byte size <= cap. Checked LAST — the
    # decisive detectors above catch the SHAPE of accretion; the cap catches its
    # GROWTH (a snapshot that grows over time is accreting).
    size = len(raw)
    if size > _SESSION_STATE_BYTE_CAP:
        any_fail = True
        fail(
            f"{_SESSION_STATE_FILE} — ANTI-GROWTH BACKSTOP: {size} bytes "
            f"exceeds the {_SESSION_STATE_BYTE_CAP}-byte cap. A true current-"
            f"frontier snapshot is small + bounded; growth over time is "
            f"accretion. Overwrite the frontier; move history out."
        )

    if not any_fail:
        ok(
            f"Check 79 — {_SESSION_STATE_FILE}: no-history grammar OK "
            f"(<=1 date in `{_SESSION_STATE_DATE_KEY}`, <=1 SHA in "
            f"`{_SESSION_STATE_SHA_KEY}`, bare BD-tags permitted, zero "
            f"narration, {size} B <= {_SESSION_STATE_BYTE_CAP} B cap)."
        )


# ── Main ────────────────────────────────────────────────────────────────────

def _build_check_registry():
    """Build the ordered CHECK_REGISTRY: the SINGLE source of the full-run
    check sequence AND the `--only-check` selector's resolution target.

    Each entry is a 4-tuple `(number, label, fn, budget_s)`:
      - `number`: the integer "Check N" the check prints in its banner, or
        `None` for the two historically-unnumbered checks
        (`check_issue_template_forms`, `check_template_archive_v11`, whose
        banners read `── Check: … ──`). A `number` is NOT unique — Checks
        16/18/19 each register TWICE (project-template + pack-root surfaces),
        so an integer selector matches BOTH entries of that number (preserving
        the "both invocations execute" per-check test assertions).
      - `label`: the existing `run_check` timing label (unique).
      - `fn`: a zero-arg callable (arg-bearing checks wrap in a named lambda so
        the timing label stays meaningful).
      - `budget_s`: the per-check WARN budget (defaults to the standard
        per-check budget; Check 49's deep faithfulness leg keeps its larger
        budget).

    The order is the full-run execution order (preserving per-check WARN timing
    + landing-order rationale documented inline below). `main()` iterates this
    registry for the no-flag full run, and resolves `--only-check` against it.
    Introduced by BD-219 C1 (the `--only-check` selector + a future C3 registry-
    completeness guard share this one source). Numbers are documented by the
    per-check banners, not hard-coded elsewhere.
    """
    W = RUN_CHECK_PER_CHECK_WARN_BUDGET_S
    # ── BD-204 §4.7: EVERY check routes through `run_check` (the runtime-
    # budget TIMING HARNESS) when dispatched. A per-check overrun WARNs; the
    # TOTAL-RUN budget is enforced as a hard FAIL at the END of main() (general
    # path only, no-flag full run). Arg-bearing checks (trinity 16/18/19) wrap
    # in a named lambda so the timing label stays meaningful.
    return [
        (1, "check_skill_frontmatter", check_skill_frontmatter, W),
        (2, "check_codex_toml", check_codex_toml, W),
        (3, "check_td_tbd_sentinels", check_td_tbd_sentinels, W),
        (4, "check_readme_version", check_readme_version, W),
        (5, "check_agent_count", check_agent_count, W),
        (6, "check_prompts_directory", check_prompts_directory, W),
        (7, "check_pack_agent_roster", check_pack_agent_roster, W),
        (8, "check_reserved_x_prefix", check_reserved_x_prefix, W),
        (9, "check_init_project_structure", check_init_project_structure, W),
        (10, "check_prompt_triad_compliance", check_prompt_triad_compliance, W),
        (11, "check_pack_agent_trinity", check_pack_agent_trinity, W),
        # Checks 12, 13, 14, 15 retired in v11 (BD-121, v9 sunset) — see
        # comment block at the function definitions above.
        (17, "check_tool_config_capability_parity", check_tool_config_capability_parity, W),
        # ── BD-183: Check 16 generalized with (trinity_root, label). Both
        # invocations run; pack-root short-circuits via the per-surface
        # exemption mechanism (`_CHECK_16_EXEMPT_SURFACES`) because Check 16
        # enforces template-only `## Project addenda` H2 infrastructure tied
        # to Procedure 5-C.2 client reconciliation, which has no purpose at
        # the non-reconciled pack-root surface. Exemption was BD-183 §2.4
        # Option (b), user-approved 2026-05-21. Per Override 9, both
        # invocations are independent. (Both register under number 16 — an
        # integer `--only-check 16` selects BOTH.)
        (16, "check_trinity_addenda_h2[project-template]",
              lambda: check_trinity_addenda_h2(REPO_ROOT / "project-template", "project-template"), W),
        (16, "check_trinity_addenda_h2[pack-root]",
              lambda: check_trinity_addenda_h2(REPO_ROOT, "pack-root"), W),
        # ── BD-181: Check 18 H2 parity runs INDEPENDENTLY at each trinity
        # location. Per Override 9 compliance: pack-root and project-template
        # trinity carry different audiences and different rules by design
        # (per pack-root trinity § Rules → Trinity rule note paragraph).
        # Each invocation enforces byte parity WITHIN its own trinity
        # location only; there is NO cross-location parity gate.
        (18, "check_trinity_h2_parity[project-template]",
              lambda: check_trinity_h2_parity(REPO_ROOT / "project-template", "project-template"), W),
        (18, "check_trinity_h2_parity[pack-root]",
              lambda: check_trinity_h2_parity(REPO_ROOT, "pack-root"), W),
        # ── BD-183: Check 19 generalized with (trinity_root, label). Empirical
        # pre-check at HEAD confirms pack-root trinity PASSES Check 19 (zero
        # HTML comments at pack-root → zero scaffolding to find). Both
        # invocations run independently per Override 9 — within-trinity
        # parity at each location; no cross-location coupling.
        (19, "check_trinity_no_scaffolding_comments[project-template]",
              lambda: check_trinity_no_scaffolding_comments(REPO_ROOT / "project-template", "project-template"), W),
        (19, "check_trinity_no_scaffolding_comments[pack-root]",
              lambda: check_trinity_no_scaffolding_comments(REPO_ROOT, "pack-root"), W),
        (20, "check_gitignore_env_example_exception", check_gitignore_env_example_exception, W),
        # The next two checks print an UNNUMBERED banner (`── Check: … ──`), so
        # they carry `number=None` — selectable by label only, never by integer.
        (None, "check_issue_template_forms", check_issue_template_forms, W),
        (None, "check_template_archive_v11", check_template_archive_v11, W),
        # ── Check 21 RETIRED in BD-221 (Antigravity conversion): pack-help is a
        # pooled skill; the script-ref assertion folded into Check 1. ──
        (22, "check_help_fragment_freshness", check_help_fragment_freshness, W),
        (23, "check_help_fragment_completeness", check_help_fragment_completeness, W),
        # ── Check 24 callsite removed in BD-194 (Candidate 6). See
        # ARCHITECTURE-BD-194.md §4-§5 + the retirement comment block above
        # the former check_help_fragment_tracker_byte_identity location.
        (25, "check_customization_detection_regression_guard", check_customization_detection_regression_guard, W),
        (26, "check_migrator_framework_inventory", check_migrator_framework_inventory, W),
        (27, "check_agent_canonical_phrases", check_agent_canonical_phrases, W),
        # ── Check 28 RETIRED in BD-221 (Antigravity conversion): pm-startup is a
        # single pooled SSOT; the per-CLI byte-parity surfaces no longer exist. ──
        (29, "check_tracker_config", check_tracker_config, W),
        (30, "check_recommendation_state_schema", check_recommendation_state_schema, W),
        (31, "check_skill_cell_consistency", check_skill_cell_consistency, W),
        # ── BD-168 (Batch 19, Commit 19e): per-entry split validators. ──
        # Order: 32 (mirror-in-sync) → 33 (TOC-in-sync) → 34 (cross-refs).
        # Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10. Each SKIPs
        # gracefully when the per-entry tree is absent (pre-BD-102
        # dog-food pack-self / pre-v11.0 client).
        (32, "check_mirror_in_sync", check_mirror_in_sync, W),
        (33, "check_toc_in_sync", check_toc_in_sync, W),
        (34, "check_cross_reference_integrity", check_cross_reference_integrity, W),
        (35, "check_tracker_phase_task_invariants", check_tracker_phase_task_invariants, W),
        # ── BD-175 Commit 12 (Architect C M5a/b/c): pack/project boundary
        # prevention. Order: 36 (commit-scope honesty) → 37 (project-side
        # deny-list) → 38 (pack-only-file siting). Check 37 lands LAST in
        # the boundary trio per C §13 bootstrap-incompatibility note — the
        # 17 §D-9 contamination refs from audit must be resolved by Commits
        # 4-9 before Check 37 is enabled, otherwise Check 37 FAILs at HEAD.
        (36, "check_commit_scope_honesty", check_commit_scope_honesty, W),
        (37, "check_project_side_deny_list", check_project_side_deny_list, W),
        (38, "check_pack_only_file_siting", check_pack_only_file_siting, W),
        # ── BD-175 F2a: cmd_update mapping/glob symmetry. Lands AFTER
        # the M5a/b/c boundary trio so the boundary-prevention surface is
        # complete before the install-coverage gate runs.
        (39, "check_cmd_update_symmetry", check_cmd_update_symmetry, W),
        # ── BD-179: pack-ops/ bare cross-reference scanner. Lands AFTER
        # the M5a/b/c boundary trio + Check 39 cmd_update symmetry so the
        # directory-boundary + install-coverage gates run before Check 40's
        # prose-cross-reference gate. Per ARCHITECTURE-BD-179.md §8.3, the
        # BD-179 commit qualifies all current bare-ref hits in pack-ops/*.md
        # so Check 40 PASSes at HEAD.
        (40, "check_bare_pack_ops_refs", check_bare_pack_ops_refs, W),
        # ── BD-180 observation G: _CLIENT_INSTALLED_FILES self-documenting
        # list integrity per ARCHITECTURE-BD-176.md §5.3. Lands AFTER Check 39
        # (the cmd_update parser is shared) and after Check 40 (independent
        # surfaces) so the install-coverage + cross-reference gates run
        # before the inventory-drift gate.
        (41, "check_client_installed_files", check_client_installed_files, W),
        # ── BD-173 H.14: project-side bare cross-reference scanner
        # (V11 leak-sweep prevention; class-test counterpart to Check 37's
        # name-enumeration). Lands AFTER Check 40 (independent surface)
        # and AFTER Check 41 (reuses _parse_client_installed_files()) so
        # the inventory-drift gate runs before Check 43's class-test gate.
        # Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1.1-§1.12.
        (43, "check_project_side_bare_internal_refs", check_project_side_bare_internal_refs, W),
        # ── BD-184 / BD-219 redesign: CI test-wiring allowlist is valid +
        # bounded. RE-SCOPED — the CI matrix is now disk-derived at run time
        # (the `plan` job's --emit-matrix), so the old `disk_KEEP_set ==
        # wired_set` equality is a tautology; Check 42 now asserts allowlist
        # validity (exist + glob-shaped) + KEEP partitionability. Lands at
        # the CI-infra end of main() rather than any single pack-product
        # surface; logical position is end-of-list (mirrors Check 41's
        # end-of-list landing for the adjacent BD-180 inventory gate).
        (42, "check_ci_workflow_wires_per_check_tests", check_ci_workflow_wires_per_check_tests, W),
        # ── BD-196 (C3): pack-memory rule↔rationale bijection. Lands AFTER
        # Check 42 (the CI-wiring infrastructure gate) because it is the
        # newest standing check and the §5.2 bijection composes the same
        # set-equality pattern as Check 32 over a distinct pair of surfaces
        # (CLAUDE.md `## Pack memory` `[rationale:]` set vs
        # pack-ops/PACK-MEMORY-RATIONALE.md `## <slug>` headings). Per
        # ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2.
        (45, "check_pack_memory_rationale_bijection", check_pack_memory_rationale_bijection, W),
        # ── BD-196 (C6): boundary + spawn-rule pointer manifests. Lands AFTER
        # Check 45 (the adjacent BD-196 bijection gate) and composes the same
        # reference-resolution pattern as Check 34 over the two pack-ops
        # manifests (.boundary-pointer-manifest.txt + .spawn-rule-manifest.txt)
        # plus the §9.6 SC7-bounded anti-restate substring scan. Per
        # ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 + §9.6 and
        # PLAN-DOC-CONCISION-GUARDRAILS.md §2 G-A (one combined function).
        (46, "check_boundary_and_spawn_pointer_manifests", check_boundary_and_spawn_pointer_manifests, W),
        # ── BD-196 (C10): M4 durable-doc concision gate. Lands AFTER Check 46
        # (the adjacent BD-196 manifest gate) and is the LAST BD-196 check —
        # the payoff the prior BD-196 commits (C4 reshaped BOUNDARY, C9
        # reshaped the other 6 durable docs) prepared. M4 = forbidden-pattern
        # count 0 OUTSIDE pack-ops/.concision-allowlist.txt (the teeth) +
        # per-doc advisory length. Per ARCHITECTURE-DOC-CONCISION-
        # GUARDRAILS.md §6 (M1-M4) + §7; PLAN-DOC-CONCISION-GUARDRAILS.md
        # §3 C10.
        (44, "check_durable_doc_concision", check_durable_doc_concision, W),
        # ── BD-195 (C3d): sanctioned pack-side-shipped freeze. Lands LAST —
        # it freezes the bounded dual-use-shipped-lib exception to exactly
        # {detect.sh, pack-help.sh} and reuses _parse_client_installed_files()
        # (shared with Checks 41/43), so it sits after the inventory + walk
        # gates. Per ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.2.
        (47, "check_sanctioned_pack_side_shipped", check_sanctioned_pack_side_shipped, W),
        # ── BD-195 (C6): JC-5 soft-advisory removed-doc guard. Lands LAST —
        # it is SOFT (WARN-only; never appends to `failures`, never changes
        # the exit code) and scoped to the per-entry trees (`/backlog/` +
        # `/changelog/` per BD-203 A12 `_REMOVED_DOC_SCAN_DIRS`, where the
        # accurate-history citations relocated when the monoliths were
        # deleted — no regenerated mirror under the no-mirror model), so it
        # neither gates nor depends on any prior check. Per
        # PLAN-BD-195-REMEDIATION.md §C6 / §2.3 (measure-then-bound JC-5).
        (48, "check_removed_doc_advisory", check_removed_doc_advisory, W),
        # ── BD-204 (C-4.6): migrator field/body faithfulness (DEEP-gated) +
        # the OQ-4 single-source codec guard. Check 49 is the deep CI guard
        # that fails a lossy/corrupting forward→reverse migration OR a body-
        # limit/title breach; it is a ~0 ms SKIP unless PACK_VALIDATE_DEEP=1
        # (§4.6 (P)), so the 151× general battery path is unaffected. The
        # caller passes the REAL `/backlog/` tree as the explicit target
        # (§4.6 (T): the caller chooses the target; there is NO internal
        # `or REPO_ROOT/"backlog"` fallback in the check body). Check 50
        # forbids a reproduced gz64/base64 codec in validate-pack.py — Check
        # 49 sub-invokes the SHARED batch codec (§4.5, OQ-4). Check 49 keeps
        # its larger deep-faithfulness per-check WARN budget.
        (49, "check_migrator_field_faithfulness",
              lambda: check_migrator_field_faithfulness(REPO_ROOT / "backlog"),
              RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S),
        (50, "check_validate_pack_no_reproduced_codec", check_validate_pack_no_reproduced_codec, W),
        # ── BD-214 (C1): tracker-deferral flip-block guard. Lands LAST — it is
        # the newest standing check, and its legs are cheap bounded greps over
        # named files + the two per-entry trees (no whole-tree scan). C1 ships
        # legs 1/2/4 only (the legs true at the C1 boundary); legs 3/5 land in
        # C2/C3 with their fix-recipes per the incremental-leg ordering. Per
        # ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md §6.3 + PLAN-BD-214-TRACKER-
        # DEFERRAL.md §4.
        (51, "check_tracker_deferral_flip_block", check_tracker_deferral_flip_block, W),
        # ── BD-197 (C3): pack RW/RO two-class consistency (Guard-B). A bounded
        # single-pass set-equality between the PACK-AGENTS roster `Class` cells
        # and the per-agent-file PROSE mandate headers (5 agents × 3 CLIs); binds
        # to the prose header, never `tools:` (pack-reviewer Write/Edit-yet-RO).
        # Per ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §13.2 + §4.3.
        (52, "check_pack_rw_ro_two_class", check_pack_rw_ro_two_class, W),
        # ── BD-197 (C5): worktree-isolation prohibition flip-block (Guard-A). A
        # single in-process whole-tree walk asserting the REMOVED prohibition
        # prose (`no worktree isolation` / `Do not pass ...isolation...worktree`)
        # does not reappear in any active pack surface. Matcher keys on the
        # prohibition signature ONLY — never the legitimate `baseRef`/`bgIsolation`
        # keys (design §11.5 G-1/G-2). Allowlist = the two process/history doc
        # dirs + the narrow validator self-skip + the single check-53 test
        # (decision 1, Check-51 self-skip precedent). Per
        # ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §13.1 + §11.5.
        (53, "check_worktree_isolation_prohibition_flip_block",
              check_worktree_isolation_prohibition_flip_block, W),
        # ── BD-197 (C8b): OPTIONAL-FEATURES presence-check (Guard-A′). The POSITIVE
        # inverse of Guard-A (Check 53): a bounded TWO-single-file pass asserting
        # BOTH OPTIONAL-FEATURES surfaces (pack-ops/OPTIONAL-FEATURES.md from C5 +
        # project-template/docs/pack/OPTIONAL-FEATURES.md from C8a) each mention the
        # MANDATED three tokens — `baseRef`, `bgIsolation`, and the
        # `permissions.deny` recipe token (user-approved 2026-06-14; BD-197 Note 14;
        # design §13.1a / §18.4 — supersedes the design's earlier "optional" framing)
        # — so the un-prohibited worktree-isolation feature + its in-session backstop
        # recipe stay DOCUMENTED on both surfaces. Measure-then-bound: sized to
        # exactly the 3 authored tokens × 2 files (the prose `isolation` param is NOT
        # folded in — design §13.1a). GREEN on arrival (C5 + C8a authored the
        # tokens). Check number 54. Per
        # ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §13.1a + §11.5 gate (b).
        (54, "check_optional_features_presence",
              check_optional_features_presence, W),
        # ── BD-197 (C5): destructive-git-verb enumeration parity (Guard-C). A
        # bounded 10-single-file pass asserting the §5.1 canonical verb set + the
        # catch-all principle phrase appear in every surface enumerating the
        # agents-never-commit ban (trinity ×3, PACK-MEMORY-RATIONALE,
        # commit-discipline ×3, pack-coder ×3). STANDALONE per decision 8 (folding
        # into an existing parity check over-complicates — see the check's
        # fold-vs-standalone comment block). Per
        # ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §13.3 + §5.4.
        (56, "check_destructive_git_verb_parity",
              check_destructive_git_verb_parity, W),
        # ── BD-197 (C6b): project RW/RO two-class consistency (Guard-B project).
        # A bounded single-pass set-equality across the three project legs — the
        # PM-CHAT `## Permission profiles` Read-only rows, the agent-run.sh
        # READONLY_AGENTS array, and the per-agent-file PROSE mandate headers
        # (16 agents × 3 CLIs); binds to the prose header, never `tools:` (project
        # RO agents carry Write/Edit; Antigravity bundle files carry no `tools:`).
        # The PROJECT analog of Guard-B(pack) (Check 52). Per ARCHITECTURE-BD-197-WORKTREE-
        # ISOLATION-RECONCILED.md §13.2 + §4.3. Check number 55 (a non-contiguous
        # gap relative to commit order is expected and tolerated; numbers ≠
        # commit order).
        (55, "check_project_rw_ro_two_class", check_project_rw_ro_two_class, W),
        # ── BD-197 (C7b): PROJECT destructive-git-verb enumeration parity
        # (Guard-C project). A bounded 52-single-file pass asserting the
        # project-consistent canonical verb set (the measured 8-verb intersection
        # checkout/clean/merge/rebase/reset/restore/stash/worktree) appears in
        # every project surface enumerating the No-destructive / agents-never-
        # commit ban (project trinity ×3, the 48 per-agent Hard rules [16 × 3
        # CLIs], agent-run.sh --disallowedTools), plus the catch-all principle
        # phrase on the trinity. The PROJECT analog of Guard-C pack (Check 56).
        # STANDALONE per decision 8 (folding into Check 56 over-complicates:
        # different canonical verb set + a trinity-only catch-all — see the
        # check's fold-vs-new-check comment block). Format-agnostic matcher
        # (`git <verb>` prose / `Bash(git <verb>:*)` launcher / Codex slash-list).
        # Check number 57. Per ARCHITECTURE-BD-197-
        # WORKTREE-ISOLATION-RECONCILED.md §13.3 + §5.4.
        (57, "check_project_destructive_git_verb_parity",
              check_project_destructive_git_verb_parity, W),
        # ── BD-219 (C3): CI-runtime-optimization upkeep guards. Land LAST —
        # they gate CI-infrastructure invariants (the workflow + the shard
        # partition + the registry itself) rather than any single pack-product
        # surface, mirroring Check 42's end-of-list landing for the adjacent
        # CI-wiring gate. Numbers 58/59/60 are the next contiguous integers
        # after the highest wired check (57) at the C3 boundary. Per
        # ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md §6.3/§6.4 +
        # PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md §C3.
        # Check 58 — the authoritative `validate` job carries no --only-check.
        (58, "check_validate_job_carries_no_only_check",
              check_validate_job_carries_no_only_check, W),
        # Check 59 — CHECK_REGISTRY completeness (the moved wiring proof:
        # restores C1's e2e legs' dropped implicit "wired into main()" proof).
        (59, "check_check_registry_completeness",
              check_check_registry_completeness, W),
        # Check 60 — CI shard partition covers the wired set (the convenience
        # validate-pack mirror of ci-shard-plan.py --assert-coverage; the
        # authoritative run-time assertion is the tests-result job).
        (60, "check_ci_shard_coverage", check_ci_shard_coverage, W),
        # Check 61 — fixture-dependent test location backstop (BD-219 dynamic-
        # autoregen redesign): a test that references a built fixture but is NOT
        # under scripts/tests/fixture-dependent/ fails loud with a "move it"
        # remediation. Lands at the end of the registry alongside the adjacent
        # CI-infra guards (42/58/59/60).
        (61, "check_fixture_dependent_location",
              check_fixture_dependent_location, W),
        # Check 62 — manifest structural well-formedness screen (BD-228 push-time
        # manifest method): a cheap structural backstop on
        # test-fixtures/manifest.txt (row count == FIXTURE_NAMES, names ==
        # FIXTURE_NAMES set, each SHA a 40-hex token). NOT the SHA-correctness
        # authority — that stays the existing CI `build.sh --verify`. Lands at the
        # registry tail alongside the adjacent CI-infra guards (58/59/60/61).
        (62, "check_manifest_structural",
              check_manifest_structural, W),
        # Check 63 — graphify-out/ never-tracked guard (BD-225): a cheap O(1)
        # `git ls-files graphify-out/` screen that FAILs loud if the Graphify
        # knowledge-graph build artifact (per-clone, gitignored) is ever
        # tracked. Pairs with the C1 `.gitignore` entry (enforces what it
        # declares). Lands at the registry tail alongside the adjacent CI-infra
        # guards (58/59/60/61/62).
        (63, "check_graphify_out_never_tracked",
              check_graphify_out_never_tracked, W),
        # Check 64 — dangling-.example deliverable gate (BD-231): a cheap bounded
        # walk over README + project-template/** + supporting-docs/** asserting
        # every MCP/config `.example` family cite resolves to an existing
        # project-template/ template. Closes the Check-43 leading-dot-dotfile
        # blind spot (DESIGN-BD-231 §4.1). Lands at the registry tail alongside
        # the adjacent CI-infra guards (58/59/60/61/62/63).
        (64, "check_dangling_example_deliverable_refs",
              check_dangling_example_deliverable_refs, W),
        # Check 65 — operating-doc no-history gate (BD-243): scans the
        # operating-doc IN set (_CHECK_65_OPERATING_DOCS) for history /
        # audit-trail patterns outside the K1-K13 KEEP allowlist. Owns the
        # date/SHA/Commit-N/Override-N/post-Commit axis moved from Check 44
        # plus the BD-provenance axis Check 44 never had. ACTIVATED at
        # BD-243 CG-14-prep-a: the scope is repointed (model B) to the
        # auto-discovered operating-doc IN set (tuple(_iter_operating_docs())),
        # so the check enforces over the full pack+project IN set.
        (65, "check_operating_doc_no_history",
              check_operating_doc_no_history, W),
        # Check 66 — operating-doc bullet-concision gate (BD-243, Gate 1b):
        # FAILs a bullet over the per-family character cap outside the
        # allowlist. Activated at CG-14 alongside the other BD-243 durable
        # gates.
        (66, "check_operating_doc_bullet_concision",
              check_operating_doc_bullet_concision, W),
        # Check 67 — operating-doc deferred-feature recall gate (BD-243,
        # Gate 2): FAILs a deferred/unimplemented-feature mention in an
        # operating doc outside the allowlist.
        (67, "check_operating_doc_no_deferred_feature",
              check_operating_doc_no_deferred_feature, W),
        # Check 68 — dangling-reference gate (BD-243, Gate 3): FAILs a file
        # reference in an operating doc whose target does not resolve, outside
        # the allowlist.
        (68, "check_dangling_file_refs",
              check_dangling_file_refs, W),
        # Check 69 — operating-doc scope-completeness meta-check (BD-243,
        # Gate 4): asserts every tracked operating-doc family member is
        # globbed-or-EXEMPT (env-robust, tracked-only).
        (69, "check_operating_doc_scope_completeness",
              check_operating_doc_scope_completeness, W),
        # Check 70 — shipped client doc-gate structural parity (BD-243, DC-2):
        # asserts the client-side doc gate (CG-CLIENT) is present + structurally
        # parallel to the pack-side operating-doc gate.
        (70, "check_client_doc_gate_parity",
              check_client_doc_gate_parity, W),
        # Check 71 — pack-root skill-mirror byte-identity (BD-243): for each
        # skill, asserts .codex/skills and .agents/skills SKILL.md are
        # byte-identical to the .claude/skills canonical (CB-04 unified them).
        # Reads 33 small files + byte-compares (no regex, no subprocess).
        (71, "check_pack_skill_mirror_identity",
              check_pack_skill_mirror_identity, W),
        # Check 72 — project-side empty-template shape + `_rules.md` schema
        # (BD-206): the shipped `project-template/docs/project/` template
        # carries the sanctioned sidecar vocabulary (no `_format.md`, no
        # monolith, no stray entry) and each `_rules.md` declares a
        # well-formed schema block. Reads ~6 small files; no subprocess.
        (72, "check_project_template_empty_shape",
              check_project_template_empty_shape, W),
        # Check 73 — project impl-plan `_index.md` consistency (BD-206 O11):
        # the MANDATORY `_index.md` validation (G-3), pack-side empty-template
        # leg. Validates the two hard properties (topological-order
        # consistency + per-entry↔_index.md membership sync) against the
        # shipped (empty) impl-plan stream + a synthetic self-check that the
        # matcher bites. Reads one stream dir (scandir + small reads); the
        # self-check is in-memory; no subprocess.
        (73, "check_project_index_consistency",
              check_project_index_consistency, W),
        # Check 74 — project changelog conformance (BD-206 O12): the
        # structured changelog conformance rule set (G-2/G-2b), pack-side
        # empty-template leg. Validates the reconciled rule (a NARRATIVE field
        # — Summary OR Scope — required for every entry; entry-max-lines;
        # summary-max-words; Test count + Files advisory) parsed from the
        # changelog `_rules.md` `## Entry structure` SSOT, against the shipped
        # (empty) changelog stream + a synthetic self-check that the matcher
        # bites. Reads one stream dir (scandir + small reads) + deterministic
        # line/word counts; self-check in-memory; no subprocess.
        (74, "check_project_changelog_conformance",
              check_project_changelog_conformance, W),
        # Check 75 — project impl-plan phase/part/task naming conformance
        # (BD-206 O13): the §3.5 GRACEFUL naming guard (a FORMAT check, not a
        # structural migration). Codifies the existing inline convention —
        # `### Phase-N.Part-x — ` / `#### Phase-N.Part-x.Task-k — ` — as a
        # deterministic template-shape check that FIRES ONLY on a malformed
        # Phase-prefixed heading; epic-task `#### N.M — ` anchors + inline
        # parts are tolerated (no forced refactor; no execution-order marker;
        # BD-185 per-part-file migration is OUT of scope). Validated against
        # the shipped (empty) impl-plan stream + a synthetic self-check that
        # the matcher bites. Reads one stream dir (iterdir + small reads) +
        # per-line regex scans; self-check in-memory; no subprocess.
        (75, "check_project_implplan_naming",
              check_project_implplan_naming, W),
        # Check 76 — pack-shipped immutable-file content-integrity (BD-246 U4):
        # verifies the pack's OWN immutable set (_IMMUTABLE_SHIPPED, the 3
        # _rules.md) against the shipped content-checksum manifest. Asserts
        # set-equality (folds in _IMMUTABLE_SHIPPED), version-gated content
        # hashes (in-process hashlib.sha256), and that verify-immutable.sh
        # ships + is executable + is wired into validate.sh (one-host wiring;
        # the integrity check is whole-set). SKIP-lenient when the manifest is
        # absent. Cheap: 3 small in-process digests + a couple of small reads;
        # no subprocess, no whole-tree scan.
        (76, "check_immutable_manifest", check_immutable_manifest, W),
        # Check 77 — session-state snapshot structural well-formedness
        # (BD-252): json.load `pack-ops/session-state.json` + assert the
        # required P1-P9 key set + `boundary_commit` 7-40 hex + `checkpoint`
        # ISO-8601. SKIP-lenient when the snapshot is absent (it ships in a
        # later commit). One small read + parse; no subprocess, no whole-tree
        # scan.
        (77, "check_session_state_struct", check_session_state_struct, W),
        # Check 78 — session-state snapshot boundary freshness (BD-252):
        # `boundary_commit` resolves + is ancestor-of-HEAD; advisory-WARN (NOT
        # fail) when it lags HEAD past the threshold (the overwrite-on-every-
        # change contract surfacing — expected as HEAD advances). SKIP-lenient
        # when absent / malformed boundary / non-git env. One small read +
        # 1-3 tiny git calls.
        (78, "check_session_state_fresh", check_session_state_fresh, W),
        # Check 79 — session-state snapshot no-history grammar (BD-252): the
        # bespoke anti-accretion check — PERMIT bare BD-tags + 1 date
        # (checkpoint) + 1 SHA (boundary_commit); FORBID a 2nd date/SHA, any
        # off-field SHA, the narration set, and size over the byte cap (the
        # anti-growth BACKSTOP, checked last). SKIP-lenient when absent /
        # unparseable. One small read + regex scans over a byte-capped object.
        (79, "check_session_state_grammar", check_session_state_grammar, W),
        # Check 80 — doc↔constant twin-bijection + completeness leg (BD-255
        # Part A, design §3.1 Layer 3): the generic A-mechanism. For each
        # enrolled _DOC_CONSTANT_TWINS row, "bijection" rows assert doc-set ==
        # constant-set (Check-45/52 idiom; LOCKS the A1 collapse + guards the
        # tracker backend twin); "recorded" rows assert symbol-resolve only
        # (prose floors — their bespoke checks keep the one-way guard). PLUS the
        # Check-59-style completeness leg (len == _DOC_CONSTANT_TWINS_EXPECTED_
        # COUNT + every symbol resolves). Cheap: per-row read + set compare; no
        # subprocess, no tree walk.
        (80, "check_doc_constant_twin_bijection", check_doc_constant_twin_bijection, W),
        # Check 81 — structured File/Symbol prereq for active-design BDs
        # (BD-255 Part C, design §3.3 C-i; TWO-MODE). FAIL leg: every open BD
        # in the committed session-state `active[]` (the in-design trigger,
        # DECISION C2-a) MUST carry a structured repo-relative path list.
        # WARN leg: other open BDs with a bare/TBD field WARN (advisory). One
        # small JSON read + a line scan per small open entry; no subprocess,
        # no tree walk. SKIP-lenient when session-state.json is absent.
        (81, "check_open_bd_structured_surface_field", check_open_bd_structured_surface_field, W),
        # Check 82 — cross-BD shared-edit-surface advisory (BD-255 Part C,
        # design §3.3 C-ii). Parses each active-state open BD's File/Symbol
        # backtick path tokens, builds a surface→BDs map, and WARNs (advisory,
        # NEVER fail — the Check-48 precedent) when ≥2 open BDs claim the same
        # surface (e.g. BD-245↔BD-253 on validate-docs.sh). Cheap: a line scan
        # + regex per small entry + an in-memory map; no subprocess, no tree
        # walk.
        (82, "check_cross_bd_surface_advisory", check_cross_bd_surface_advisory, W),
    ]


def _resolve_only_check(registry, selector):
    """Resolve a `--only-check` selector against the CHECK_REGISTRY.

    `selector` is the raw string from argparse. It matches an entry by:
      - INTEGER check number (e.g. `52`, or `16` which matches BOTH the
        project-template and pack-root entries of Check 16), OR
      - the exact `run_check` LABEL string (e.g.
        `check_pack_rw_ro_two_class`, or `check_trinity_h2_parity[pack-root]`).

    Returns the ordered list of matching `(number, label, fn, budget_s)`
    entries (registry order preserved). Returns an EMPTY list when nothing
    matches — `main()` turns that into a LOUD non-zero named error (never a
    silent no-op, which would turn a per-check test into a tautology =
    effectiveness loss).
    """
    matches = []
    # Numeric selector: match ALL entries whose number equals the integer.
    if selector.isdigit():
        want = int(selector)
        matches = [e for e in registry if e[0] == want]
    # Label selector (also tried when a numeric selector found nothing, so a
    # numeric-looking label could still resolve — though no label is numeric).
    if not matches:
        matches = [e for e in registry if e[1] == selector]
    return matches


def main(only_check=None) -> None:
    """Run the structural validation checks.

    `only_check` (BD-219 C1): when `None` (the no-flag default, and the value
    used by every in-process caller such as the §4.7 runtime-budget test's
    `mod.main()`), run the FULL CHECK_REGISTRY and enforce the TOTAL-RUN budget
    — byte-identical to the pre-BD-219 behavior. When a selector string is
    given (via `--only-check` in `__main__`), run ONLY the matching registry
    entries; the TOTAL-RUN budget is SUPPRESSED (a single check is not the real
    surface) while the per-check WARN budget STAYS active.
    """
    print("=" * 60)
    print("Pack Structural Validation")
    print("=" * 60)

    registry = _build_check_registry()

    if only_check is None:
        selected = registry
    else:
        selected = _resolve_only_check(registry, only_check)
        if not selected:
            # LOUD named error — never a silent no-op (effectiveness guard).
            fail(
                f"--only-check: unknown selector '{only_check}' — no check "
                f"matches that number or run_check label. Run with no flag to "
                f"list all checks, or pass a valid 'Check N' number / label."
            )
            print("\n" + "=" * 60)
            print(f"FAILED — {len(failures)} issue(s) found")
            sys.exit(1)
        labels = ", ".join(e[1] for e in selected)
        print(f"\n(--only-check {only_check}: running {len(selected)} "
              f"selected check(s): {labels})")

    for number, label, fn, budget_s in selected:
        run_check(label, fn, budget_s=budget_s)

    # ── BD-204 §4.7 RUNTIME-BUDGET GUARD — the TOTAL-RUN hard FAIL. A
    # general run over the 10 s total budget means a check regressed into
    # the general path (the C-4.6 compounding shape) → CI RED. This bound
    # is GENERAL-PATH-ONLY: a deep run (PACK_VALIDATE_DEEP=1) carries its
    # own larger total budget so a legitimate deep run is never falsely
    # failed. (The per-check WARN budget is enforced inside `run_check`.)
    # BD-219 C1: SUPPRESSED under `--only-check` — the sum of a single
    # selected check is not the real surface, so failing on it would be
    # meaningless. The no-flag full run keeps the total-run budget LIVE.
    if only_check is None:
        total_elapsed = sum(elapsed for _, elapsed in _check_timings)
        deep = os.environ.get("PACK_VALIDATE_DEEP") == "1"
        total_budget = (
            RUN_CHECK_TOTAL_DEEP_BUDGET_S if deep else RUN_CHECK_TOTAL_GENERAL_BUDGET_S
        )
        if total_elapsed > total_budget:
            path_label = "deep" if deep else "general"
            fail(
                f"RUNTIME-BUDGET: validate-pack total {total_elapsed:.2f}s > "
                f"{total_budget:.2f}s ({path_label} path) — a check regressed "
                f"into the run; investigate before merge"
            )
    else:
        print("(total-run budget N/A in single-check mode; "
              "per-check WARN budget stays active)")

    print("\n" + "=" * 60)
    if failures:
        print(f"FAILED — {len(failures)} issue(s) found")
        sys.exit(1)
    else:
        print("PASSED — all checks clean")
        sys.exit(0)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        prog="validate-pack.py",
        description="Pack structural validation. With no arguments, runs ALL "
                    "checks (the authoritative full run).",
    )
    parser.add_argument(
        "--only-check",
        metavar="N|LABEL",
        default=None,
        help="Run ONLY the check matching this number (e.g. 52) or run_check "
             "label (e.g. check_pack_rw_ro_two_class). The no-flag run is "
             "unchanged: ALL checks. (BD-219)",
    )
    args = parser.parse_args()
    main(only_check=args.only_check)
