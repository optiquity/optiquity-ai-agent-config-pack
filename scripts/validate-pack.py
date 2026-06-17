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
  24. [RETIRED in BD-194 — see ARCHITECTURE-BD-194.md]
      HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1; superseded
      by Check 22 + Check 23 + Check 41 per-surface coverage). Per
      pack memory feedback_pack_project_separation_of_concerns
      (user-locked 2026-05-26), the pack-side and project-side
      HELP-FRAGMENT-TRACKER.md files are SEPARATE artifacts with
      SEPARATE audiences; byte-identity is coincidence, not contract.
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
      markers ("Flat-file mode" + "Tracker mode" for `backlog/`;
      "Mode invariance" for `changelog/`) — marker presence only.
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

import json
import os
import re
import subprocess
import sys
import tempfile
import time
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
    # BD-203: `mirror_relative` is retained as the deletion-target reference
    # only — for the PACK the per-entry tree + `_toc.md` is the SOLE SSOT;
    # there is no regenerated monolithic mirror (Check 32 inverted to 32′).
    # BD-211: pack-backlog regex is canonical `BD-NNN.md` — NO letter
    # suffix (the former suffix sub-entries were folded into their base
    # entries); A3: pack-changelog regex is per-release granularity (`vN.md`).
    ("pack-backlog",      "backlog",            "pack-ops/BACKLOG.md",          r"^BD-\d+\.md$"),
    ("pack-changelog",    "changelog",          "pack-ops/CHANGELOG.md",        r"^v\d+\.md$"),
]
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
CLAUDE_AGENTS_DIR = REPO_ROOT / "project-template" / ".claude" / "agents"
CODEX_AGENTS_DIR = REPO_ROOT / "project-template" / ".codex" / "agents"
# BD-221: the third agent surface is the Antigravity client plugin bundle
# (the 16-agent optiquity-agents roster). Checks 5 (count parity) and 27
# (canonical phrases) scan this bundle so the Antigravity agents are covered
# with no silent loss.
OPTIQUITY_BUNDLE_AGENTS_DIR = (
    REPO_ROOT / "project-template" / ".agents-plugin" / "optiquity-agents" / "agents"
)
README = REPO_ROOT / "README.md"

REQUIRED_SKILL_FIELDS = {"name", "description", "allowed-tools"}

PROMPTS_DIR = REPO_ROOT / "project-template" / "docs" / "pack" / "prompts"
REQUIRED_PROMPT_FRONTMATTER = {"agent", "variants"}
RESERVED_PROMPT_FRONTMATTER = {"description", "deprecated-by", "notes"}

PM_CHAT = REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md"
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

failures = []


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    failures.append(msg)


def ok(msg: str) -> None:
    print(f"  OK: {msg}")


def warn(msg: str) -> None:
    """Soft-advisory output — informational only, NEVER a gate failure.

    A `warn()` line is printed for the operator's attention but does NOT
    append to `failures`, so it never changes the exit code. Used by the
    JC-5 soft-advisory removed-doc guard (Check 48, BD-195 C6): accurate
    v8/v9 + process-history citations to removed docs must surface as a
    WARN without breaking CI.
    """
    print(f"WARN: {msg}")


# ── RUNTIME-BUDGET GUARD (BD-204 §4.7) ─────────────────────────────────────
#
# The durable prevention the prior >2h→<5min C-4.6 fix lacked. `main()` routes
# EVERY check through `run_check`, which times the wrapped call. Per the
# `ci-check-runtime-compounding` memory rule, a check that is fine ONCE is
# catastrophic at the battery's ~151× validate-pack invocation count, so a
# pathologically-slow check must not silently ship. The harness times each
# check (per-check WARN on overrun) and `main()` enforces a TOTAL-RUN HARD-FAIL
# on the GENERAL path only.
#
# Budget VALUES (measured-then-bounded per §4.7; the §3 measure-then-bound
# discipline, RUNTIME axis):
#   - Per-check WARN budget = 2.0 s. The slowest GENERAL check is well under
#     the ~1.3-1.4 s whole-run baseline (§4.6 EE), so 2.0 s per check is a
#     generous ceiling no current check approaches.
#   - Total general-run budget = 10 s. ~1.37 s baseline × a generous ~7×
#     safety factor; a general run over 10 s means a check regressed into the
#     general path (the C-4.6 shape) → hard FAIL. The 10 s total bound is NOT
#     applied to the deep (`PACK_VALIDATE_DEEP=1`) run — the deep run carries
#     its own larger TOTAL budget (~35 s = ~5 s general allowance + the 30 s
#     deep faithfulness-leg) so a legitimate deep run is never falsely failed.
RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0
RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0
RUN_CHECK_TOTAL_DEEP_BUDGET_S = 35.0
# Deep FAITHFULNESS-LEG per-check budget = 30 s (§4.7: "Deep faithfulness-check
# budget = 30 s"). This is the per-check WARN budget for Check 49's deep leg —
# DISTINCT from the deep TOTAL-run budget (35 s = ~5 s general allowance + this
# 30 s leg), which `main()` enforces below. The deep leg is MEASURED ~2.9 s, so
# 30 s is ~10× headroom; an Option-A per-entry-spawn regression (~142 s) blows
# it immediately.
RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S = 30.0

# ── BD-219 C3: CHECK_REGISTRY expected size — the registry-completeness
# bookkeeping constant (Check 59). The no-flag full run executes EVERY entry
# of `_build_check_registry()`; this constant is the explicit invariant that
# replaces the implicit "the per-check e2e leg proves the check is wired into
# main()" property that `--only-check` (BD-219 C1) would otherwise drop.
# UPDATE IN LOCK-STEP whenever a check is added/removed (a one-line edit, like
# the agent-count check). At the BD-219 dynamic-autoregen redesign the registry
# held 61 entries; BD-221 (Antigravity conversion) RETIRED Checks 21 + 28
# (−2), so the registry now holds 59 entries:
#   57 entries at C1's CHECK_REGISTRY introduction (§EE-P5)
# + 3 net-new C3 checks (58 validate-no-flag, 59 registry-completeness,
#                        60 shard-coverage mirror)
# + 1 net-new BD-219-redesign check (61 fixture-location backstop)
# − 2 retired in BD-221 (21 pack-help per-CLI parity, 28 pm-startup per-CLI
#                        parity — both obsoleted by the pooled-skill model).
# (Re-scoped Check 42 keeps its slot; numbers ≠ entry count — Checks
# 16/18/19 each register TWICE and 2 checks carry number=None.) This constant
# is the explicit invariant; the actual count is COMPUTED from
# len(_build_check_registry()) and asserted equal by Check 59 — never
# hard-coded anywhere else.
CHECK_REGISTRY_EXPECTED_COUNT = 59

# Accumulated per-check timings (name, elapsed_s) for the total-run guard.
_check_timings = []


def run_check(name, fn, budget_s=RUN_CHECK_PER_CHECK_WARN_BUDGET_S):
    """Time the wrapped check `fn` (a zero-arg callable); WARN on per-check
    budget overrun (§4.7).

    Records `(name, elapsed_s)` in `_check_timings` so `main()` can enforce the
    TOTAL-RUN budget after all checks complete. A per-check overrun is a LOUD
    WARN (validate-pack still completes — a slow check must not block unrelated
    work mid-investigation); the TOTAL-RUN budget is the hard FAIL (`main()`).
    """
    t0 = time.monotonic()
    fn()
    elapsed = time.monotonic() - t0
    _check_timings.append((name, elapsed))
    if elapsed > budget_s:
        warn(
            f"RUNTIME-BUDGET: check '{name}' took {elapsed:.2f}s > budget "
            f"{budget_s:.2f}s — investigate before merge"
        )


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

    Per BD-194: each surface authors its own HELP-FRAGMENT-TRACKER.md.
    Per-surface tracker fragment lookup via the surfaces dictionary; no
    cross-surface concatenation. Each surface's verbs are compared
    against the surface's own tracker fragment. See
    ARCHITECTURE-BD-194.md Candidate 6.
    """
    print("\n── Check 22: Help-fragment freshness (BD-082) ──")
    # Per BD-194: each surface authors its own HELP-FRAGMENT-TRACKER.md.
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
            "tracker_fragment": REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md",
        },
        "project-template": {
            "root": REPO_ROOT / "project-template",
            "docs": [
                REPO_ROOT / "project-template" / "docs" / "pack" / "PM-CHAT.md",
            ],
            "fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT.md",
            "tracker_fragment": REPO_ROOT / "project-template" / "docs" / "pack" / "HELP-FRAGMENT-TRACKER.md",
        },
    }

    any_failed = False
    for surface, cfg in surfaces.items():
        frag = cfg["fragment"]
        tracker_frag = cfg["tracker_fragment"]
        if not frag.is_file():
            fail(f"{surface}: help fragment missing: {frag.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        if not tracker_frag.is_file():
            fail(f"{surface}: tracker fragment missing: {tracker_frag.relative_to(REPO_ROOT)}")
            any_failed = True
            continue
        frag_text = frag.read_text() + "\n" + tracker_frag.read_text()
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

    Per BD-194: pack-side tracker fragment (pack-ops/HELP-FRAGMENT-TRACKER.md)
    is REQUIRED — fail-loud if missing (no silent fallback). Pack-side
    existence is the surface-local invariant this check enforces;
    project-side existence is enforced independently by Check 41
    (_CLIENT_INSTALLED_FILES). See ARCHITECTURE-BD-194.md Candidate 6.
    """
    print("\n── Check 23: Help-fragment completeness (BD-082) ──")
    fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"
    tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"
    if not fragment.is_file():
        fail(f"pack-root help fragment missing: {fragment.name}")
        return
    if not tracker_fragment.is_file():
        fail(f"pack-root tracker fragment missing: pack-ops/{tracker_fragment.name}")
        return
    text = fragment.read_text() + "\n" + tracker_fragment.read_text()

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
# The pack-side HELP-FRAGMENT-TRACKER.md and project-template-side
# HELP-FRAGMENT-TRACKER.md are SEPARATE artifacts with SEPARATE audiences
# per pack memory feedback_pack_project_separation_of_concerns (user-
# locked 2026-05-26). Pack-side existence is asserted by Check 23
# (fail-loud); project-side existence is asserted by Check 41
# (_CLIENT_INSTALLED_FILES self-doc list integrity). No cross-surface
# content invariant is required or asserted.


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


# ── Check 29: Tracker-config schema (BD-078) ────────────────────────────────

# Supported backend names per the example file comments
# ("github" first-class at v11.0; others reserved). Keep in lockstep
# with the comment block in the two example files.
_TRACKER_BACKENDS = ("github", "linear", "jira", "redmine")
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
    True for the client-side example (the client model keeps monolith
    mirrors until BD-206), False for the pack-side example (the pack
    deleted its monolith mirrors at BD-203, so the table's absence is
    valid-by-construction). When the table IS present, its keys are
    validated on either surface.
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

    # [mirror] table — surface-conditional presence (BD-204). Required
    # on the client surface (mirror_required=True); optional on the
    # pack surface, where the no-monolith shape omits it entirely.
    # When present (either surface), the table and its operational
    # keys are validated as before.
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

    # mirror_required is per-surface (BD-204): the pack example omits
    # [mirror] (no monolith post-BD-203); the client example keeps it
    # until BD-206.
    _validate_tracker_toml(pack_example, expected_prefix="BD",
                           mirror_required=False)
    _validate_tracker_toml(client_example, expected_prefix="TD",
                           mirror_required=True)

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
# §4.2): per-stream required mode markers in `_rules.md`. Check 32′
# asserts marker/heading PRESENCE only — never prose-pinning
# (anti-fragility). Allowlist sized to exactly the two pack streams
# (measure-then-bound: the markers landed in the Mode-3 ops Commit 1;
# project streams gain theirs at BD-206/207 and are NOT asserted here).
_RULES_MODE_MARKERS = {
    "pack-backlog":   ("Flat-file mode", "Tracker mode"),
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

      - Assert `_rules.md` carries the stream's required mode markers
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

        # BD-204 Mode-3 ops contract: required mode markers in _rules.md
        # (marker presence only — see _RULES_MODE_MARKERS above). The
        # pack-backlog contract must carry both mode headings
        # ("Flat-file mode" / "Tracker mode"); the pack-changelog
        # contract must carry the "Mode invariance" marker.
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
# token serves the project stream. The `vN.M` version token keeps its
# `-suffix` group (version-shaped, not ID-shaped).
CROSS_REF_RE = re.compile(
    r"\b("
    r"BD-\d+"
    r"|TD-\d+"
    r"|phase-\d+(?:\.\d+)?"
    r"|v\d+\.\d+(?:-[a-z0-9-]+)?"
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
_VERSION_POINT_RE = re.compile(r"^v(\d+)\.\d+(?:-[a-z0-9-]+)?$")


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
_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)

# pack-chat-only PERMITTED-PATHS per `pack-ops/PACK-AGENTS.md` § "pack-chat-only
# files and directories" Files list, with the post-Architect-B + B-fix path
# substitution: pack-root operational files now live under `pack-ops/`.
# README.md is permitted in full (the
# version-table-only narrower constraint stays a Pack Chat discipline rule
# per the §8.1a (README.md) note in the architect doc).
_PACK_CHAT_ONLY_PERMITTED_PATHS = {
    # BD-203 Commit 2 (A13-INVERSE): `pack-ops/BACKLOG.md` +
    # `pack-ops/CHANGELOG.md` are DELETED at BD-203 Commit 2 — the
    # per-entry trees `/backlog/` + `/changelog/` (covered by
    # `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` below) are the sole SSOT under
    # the no-mirror model. A `git rm`'d file cannot be a pack-chat-only
    # permitted PATH, so the two monolith entries are removed here in
    # lockstep with the deletion (the inverse of BD-209's A13 fold, which
    # had restored them transiently while both files still existed).
    "README.md",
    "pack-ops/PACK-CHAT.md",
    "pack-ops/PACK-AGENTS.md",
    "pack-ops/PACK-MEMORY-RATIONALE.md",
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
}

# pack-chat-only PERMITTED-PATH PREFIXES — the per-entry tree directories per
# `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" Directories list.
_PACK_CHAT_ONLY_PERMITTED_PREFIXES = (
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

# Scope-neutral generated artifact(s): auto-generated files that the
# `regenerate-manifest-v11-surface` rule FORCES to co-vary with a v11-surface
# edit on EITHER surface. They carry no surface-specific semantic content, so
# they are permitted in BOTH `project-only` and `pack-only` commits without
# counting as an offender. Sized EXACTLY to the measured forced-co-variant set
# (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17.3): manifest only.
# A hand-edited manifest is independently caught by `build.sh --verify`, so
# admitting it here does NOT let content smuggle past the boundary.
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})


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


def _is_scope_neutral_generated(path: str) -> bool:
    """True if `path` is an auto-generated, scope-neutral artifact that the
    regenerate-manifest rule forces to co-vary with v11-surface edits on
    EITHER surface (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17).
    Such paths are not offenders in either `project-only` or `pack-only`
    commits. Exact-string set-membership — NOT a `test-fixtures/` prefix, so
    the static `v11-trinity-marker-prepped/` snapshot + the `build.sh`/README
    recipe (real pack-side content) still count toward scope."""
    return path in _SCOPE_NEUTRAL_GENERATED_PATHS


def _is_pack_chat_only_permitted(path: str) -> bool:
    """A path is pack-chat-only-permitted if it appears in the canonical Files
    list OR under one of the canonical pack-chat-only directory prefixes."""
    if path in _PACK_CHAT_ONLY_PERMITTED_PATHS:
        return True
    return path.startswith(_PACK_CHAT_ONLY_PERMITTED_PREFIXES)


def check_commit_scope_honesty() -> None:
    """Check 36 — commit-scope honesty (BD-175 M5a per Architect C §8.1).

    For every commit in the walk range, parse the commit subject for scope
    keywords (`pack-only`, `project-only`, `pack-chat-only`)
    and verify the commit's touched paths match the claimed scope.

    Failure modes:
      - Subject claims `pack-only` but commit touches `project-template/`
        or `supporting-docs/`.
      - Subject claims `project-only` but commit touches paths outside
        `project-template/` + `supporting-docs/`.
      - Subject claims `pack-chat-only` but commit touches
        any path NOT in the pack-chat-only permitted-paths list (per
        `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" + the
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
        is_pack_chat_only = _subject_has_keyword(
            subject, _SCOPE_KEYWORDS_PACK_CHAT_ONLY
        )
        if not (is_pack_only or is_project_only or is_pack_chat_only):
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
            offenders = [
                p for p in paths
                if _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `pack-only` "
                    f"but touches project-side paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_project_only:
            offenders = [
                p for p in paths
                if not _is_project_side_path(p)
                and not _is_scope_neutral_generated(p)
            ]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `project-only` "
                    f"but touches pack-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                )
                any_failed = True
        if is_pack_chat_only:
            offenders = [p for p in paths if not _is_pack_chat_only_permitted(p)]
            if offenders:
                fail(
                    f"Commit {short_sha} subject claims `pack-chat-only` but "
                    f"touches non-pack-chat-only paths: "
                    + ", ".join(offenders[:8])
                    + (f" (+ {len(offenders) - 8} more)" if len(offenders) > 8 else "")
                    + " (pack-chat-only permitted set per pack-ops/PACK-AGENTS.md "
                    "§ 'pack-chat-only files and directories')"
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


# Pack-side-LOCATED, client-SHIPPED files. FROZEN. Each entry is a
# pack-operation runtime dependency (dependency-direction principle:
# init-project.sh/add-capability.sh/migrator source detect.sh; pack-help.sh
# sources detect.sh) AND must ship to clients (pack-help LCD floor). They
# are held to client-surface cleanliness by Check 43 and MUST stay clean.
# ADDING AN ENTRY requires architect+user authorization — see Check 47
# (set-equality freeze) and ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8
# (the dependency-direction membership criterion, §8.3).
_SANCTIONED_PACK_SIDE_SHIPPED = (
    "scripts/lib/detect.sh",
    "scripts/pack-help.sh",
)


def _iter_client_installed_files() -> list[Path]:
    """Return the union of:
      (a) all regular files under project-template/ (recursive), and
      (b) the explicit non-project-template files in _CLIENT_INSTALLED_FILES,
          split into two admitted classes: `supporting-docs/` entries are
          client-installed sources and pass through WITHOUT a membership
          check; every OTHER non-template entry (pack-side-located) is
          admitted ONLY if it is in _SANCTIONED_PACK_SIDE_SHIPPED (membership
          gate, NOT a content skip — admitted files stay fully walked +
          cleanliness-enforced by Check 43; an UNsanctioned pack-side entry
          is a hard error via Check 47). See
          ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.1/§8.2.

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
    #     `supporting-docs/` entries are client-installed sources (walked as
    #     before). PACK-SIDE-LOCATED entries (neither project-template/ nor
    #     supporting-docs/) are MEMBERSHIP-GATED to _SANCTIONED_PACK_SIDE_SHIPPED:
    #     the gate authorizes WHICH pack-side files may be walked as client
    #     surfaces — it is NOT a content skip. Admitted files stay fully walked
    #     and Check 43 still enforces cleanliness on them (re-adding a `BD-`
    #     token to detect.sh post-strip still FAILS Check 43). An UNsanctioned
    #     pack-side map entry is silently NOT admitted here and is turned into
    #     a HARD CI error by Check 47 (set-equality freeze).
    entries, _, _, _, _ = _parse_client_installed_files()
    for entry in entries:
        if entry.startswith("project-template/"):
            continue  # already covered by (a)
        if not entry.startswith("supporting-docs/") and (
            entry not in _SANCTIONED_PACK_SIDE_SHIPPED
        ):
            continue  # membership gate — Check 47 fails on unsanctioned entries
        full = REPO_ROOT / entry
        if full.is_file():
            rel = full.relative_to(REPO_ROOT)
            if rel not in out:  # dedup defensive (project-template/ first)
                out.append(rel)
    return out


# Companion-template directories — dev-environment configs a developer
# applies to their editor/IDE (NOT installed by init-project.sh, so NOT
# part of `_CLIENT_INSTALLED_FILES`). They are pack-shipped client-facing
# surfaces, so Check 37's pack-only deny-list applies to them as
# forward-protection (BD-196 C7, plan §3 D1). These are appended to
# Check 37's walk via `_iter_project_side_files()` ONLY — they are
# deliberately NOT added to `_iter_client_installed_files()`, which feeds
# Check 41's install inventory and Check 43's bare-cross-reference walk.
_CHECK_37_COMPANION_TEMPLATE_DIRS = (
    "xcode-companion-templates",
    "vscode-companion-templates",
)


def _iter_project_side_files() -> list[Path]:
    """Check 37's walk set: `_iter_client_installed_files()` PLUS the
    companion-template directories.

    Check 37 protects every pack-shipped client-facing surface from
    pack-only-reference contamination. That surface is the union of:
      (a) the client-installed inventory (`_iter_client_installed_files()`
          — project-template/ recursive + the explicit
          `_CLIENT_INSTALLED_FILES` extras), and
      (b) the companion-template directories
          (`_CHECK_37_COMPANION_TEMPLATE_DIRS`), which are dev-environment
          editor/IDE configs a developer applies manually — pack-shipped
          and client-facing, but NOT auto-installed by init-project.sh.

    The companion dirs are appended HERE (Check 37's walk) and NOT in
    `_iter_client_installed_files()` so that Check 41 (install inventory)
    and Check 43 (bare-cross-reference scanner) are unaffected — they
    walk only the auto-installed set. See ARCHITECTURE-V11-GUARDRAILS-
    CONTRACT.md §3.2 for the original alias rationale; BD-196 C7 plan §3
    D1 for the companion-template extension.
    """
    out = list(_iter_client_installed_files())
    seen = {str(p) for p in out}
    for dirname in _CHECK_37_COMPANION_TEMPLATE_DIRS:
        root = REPO_ROOT / dirname
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            rel = path.relative_to(REPO_ROOT)
            if str(rel) not in seen:
                out.append(rel)
                seen.add(str(rel))
    return out


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
    # architect-spec gap discovery, IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md
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

    Walks the Check 37 surface (`_iter_project_side_files()` — the
    client-installed inventory PLUS the companion-template directories
    `xcode-companion-templates/` + `vscode-companion-templates/` per
    BD-196 C7) and greps for literal references to pack-only files /
    path prefixes / agent names / the capitalized `Pack Chat`
    orchestrator role. Each hit is a FAIL with file:line + matched
    pattern unless the context window contains a LEGITIMATE-context
    anchor phrase.

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
        # pack-chat-only operating rules and legitimately reference pack-only
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
# Per ARCHITECTURE-BD-179.md §3-§8. Walks `pack-ops/*.md` (excluding the
# deleted-monolith basenames BACKLOG.md + CHANGELOG.md per §2.1 D1a — a
# defensive exemption retained post-BD-203; there is no regenerated mirror
# under the no-mirror model) and flags backtick-delimited filename refs
# that lack a directory qualifier.
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
    # Claude-Code `settings.json` — external user/project config the
    # developer authors; the pack ships NO settings file (BD-197 hard
    # constraint). Bare ref is load-bearing in OPTIONAL-FEATURES because
    # the same key (`worktree.baseRef`, `permissions.deny`) lives at EITHER
    # user scope (`~/.claude/settings.json`) OR project scope
    # (`.claude/settings.json`) — qualifying to one path would misrepresent
    # the documented "user OR project scope" choice. Same external-to-pack
    # class as MEMORY.md. (BD-197 C5; ARCHITECTURE-BD-179.md §6.5.)
    "settings.json": "Claude-Code user/project config (external to pack repo; scope-agnostic per BD-197 OPTIONAL-FEATURES)",
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
    # pack-ops/HELP-FRAGMENT-TRACKER.md and from project-template/docs/
    # pack/HELP-FRAGMENT-TRACKER.md). Per BD-194 the pack-side and
    # project-side HELP-FRAGMENT-TRACKER.md files are SEPARATE artifacts
    # with SEPARATE audiences (feedback_pack_project_separation_of_concerns,
    # user-locked 2026-05-26); the previous "byte-identical mirror"
    # rationale is retired with Check 24. The bare ref is correct at the
    # client-installed location (resolves to docs/pack/HELP-FRAGMENT.md
    # in the client repo as a same-dir sibling). Resolves via Check 41
    # _CLIENT_INSTALLED_FILES.
    "HELP-FRAGMENT.md": "Project-side mirror exception; resolves at client-installed location (see Check 41 _CLIENT_INSTALLED_FILES)",
}

# Anchor phrases that, when found within the per-pattern context window
# (matched line + N lines before + N lines after), mark the match as
# legitimate per architect doc §6.4. A SUBSET of Check 37's anchor set,
# plus three new phrases scoped to Check 40's defect class.
_CHECK_40_ANCHOR_PHRASES = (
    # Inherit pack-vs-project disambiguation context from Check 37
    # (the pack/project boundary rules in pack-ops/BOUNDARY-DEFINITION.md).
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "in the project",
    "at the client",
    # Audience-bridge context (intentional client-path references in
    # pack-internal docs that discuss what happens after init-project.sh
    # runs). Per ARCHITECTURE-BD-179.md §7 D6. OQ-3 confirmed.
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

    Walks `pack-ops/*.md` and flags backtick-delimited filename refs that
    lack a directory qualifier and are not exempt. `pack-ops/BACKLOG.md`
    and `pack-ops/CHANGELOG.md` are excluded by basename: under the
    BD-203 no-mirror model these monoliths are deleted (the per-entry
    `/backlog/` + `/changelog/` trees are the SSOT), so once gone the
    glob never yields them and the exclusion is inert; while they still
    exist (during conversion) the exclusion keeps the scan off
    conversion-input content.
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

    # Excluded basenames. BD-203 no-mirror model: BACKLOG.md /
    # CHANGELOG.md are the deleted monoliths (the `/backlog/` +
    # `/changelog/` per-entry trees are the SSOT); once deleted this set
    # never matches, and during conversion it keeps the scan off the
    # conversion-input monoliths. NOT "regenerated mirrors" — there is
    # no mirror.
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
    "HELP-FRAGMENT-TRACKER.md": "Project-side docs/pack/HELP-FRAGMENT-TRACKER.md (client-installed; per-surface authoritative per BD-193 F4/F5 + BD-194)",
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
    # ── Agent prompt meta-references (ambiguous-by-design; the basename exists
    #    in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity
    #    agent plugin bundle .agents-plugin/optiquity-agents/agents, and
    #    docs/pack/prompts). Basename-keyed; the value is documentation only.
    "coder.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "architect.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "reviewer.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "planner.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "tester.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "auditor.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "docs-researcher.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
    "auditor-architecture.md": "Agent-prompt meta-reference; ambiguous-by-design (the basename exists in ≥2 candidate dirs: .claude/agents, .codex/agents, the Antigravity agent plugin bundle .agents-plugin/optiquity-agents/agents, docs/pack/prompts)",
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
    # NOTE: `V10-DESIGN.md` was previously allowlisted as "not in pack repo
    # at HEAD" — but it EXISTS at maintenance-docs/archive/V10-DESIGN.md, so
    # the rationale was stale and the entry admitted a STRIP-classified leak
    # (BD-195 K4.1, README:9 bare-prose). Removed per ci-guard-measure-then-
    # bound (an allowlist entry must not admit a pack-only leak); the JC-2
    # bare-prose axis now correctly fires on it. The C3a recipe strips the
    # README:9 cite.
    "MIGRATION-v9-to-v10.md": "Legacy migration doc; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-v9-to-v10.sh": "Legacy migration script; sunset in v11 per BD-121 (no real file at HEAD)",
    "migrate-vN-to-vM.sh": "Migrator framework filename pattern (placeholder per BD-119 architect doc)",
    # ── Audit-methodology teaching examples (illustrative content in skill docs).
    "user_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "order_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    "inventory_repository.py": "Audit-methodology teaching example; illustrative code in skill docs (not a real file)",
    # NOTE: proto self-imports are NOT allowlisted by basename. They are
    # exempted by the DURABLE resolve-within-tree rule
    # (`_check_43_proto_resolves_in_tree`, BD-195 C2 §2.2 Step-4): any
    # `.proto` reference whose basename resolves to an existing file under
    # `project-template/proto/` is legitimate project-side content
    # (gRPC/protobuf is a supported language with dedicated skill(s)). A
    # basename list would go stale as the proto tree grows or skills add
    # example protos; the resolve-within-tree predicate survives that. The
    # rule is bounded to in-tree imports only (`ci-guard-measure-then-bound`).
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

# ── JC-2 broadening (BD-195 C2 §2.2) ──────────────────────────────────────
# Four-axis broadening of the client-surface leak guard. See
# `maintenance-docs/v11-implementation/PLAN-BD-195-REMEDIATION.md`
# § "C2 — JC-2 client-surface leak-guard broadening" §2.2.
#
# (iii) Walk-extension broadening: Check 43's walk filter is the
#       `_CHECK_40_FILE_EXTS` set. The JC-2 broadening adds the
#       client-shipped config-example + proto extensions (`.example`
#       double-extension files like `config.toml.example` /
#       `.env.example`, and `.proto`) so the leak scanner inspects
#       `.codex/config.toml.example`, `.mcp.json.example`,
#       `.agents/mcp_config.json.example`, and the proto tree. Kept
#       Check-43-local
#       (NOT folded into `_CHECK_40_FILE_EXTS`) so Check 40's pack-ops/
#       walk + the shared bare-ref regexes are unchanged.
_CHECK_43_EXTRA_WALK_SUFFIXES = ("example", "proto")

# (i) Bare-prose pack-doc-basename inventory: basenames whose EVERY
#     repo location is under a pack-only top-level tree (`maintenance-docs/`
#     or `pack-ops/`), minus the regenerated mirrors, the client-installed
#     `HELP-FRAGMENT-TRACKER.md`, and any basename on `_CHECK_43_ALLOWLIST`
#     (the curated client-resolvable set). Built from the tree (NOT a
#     hand-typed list) per `ci-guard-measure-then-bound`. The "every
#     location pack-only" bound is the over-fire guard: a basename that
#     ALSO has a project-side / client-installed instance (e.g.
#     `ARCHITECTURE.md`, `README.md`, `IMPLEMENTATION-PLAN.md`) is NOT a
#     pack-only-doc and is excluded — only basenames that resolve
#     EXCLUSIVELY into pack-only territory (e.g. `V10-DESIGN.md`,
#     `V10-CODEX-MCP-RESEARCH.md`, `MERGE-STRATEGY.md`) are targets. A
#     client surface that names one of these in NON-backtick prose (or
#     inside a qualified `docs/pack/<basename>` path the bare-ref regex's
#     `/`-exclusion misses) is a dead pointer.
_CHECK_43_PACK_ONLY_DOC_TREES = ("maintenance-docs", "pack-ops")

# (ii) commit-SHA-as-provenance: a `commit <7-40 hex>` provenance citation
#      on a client surface points at pack-repo git history the client
#      cannot resolve. Anchored to a `commit ` keyword to avoid matching
#      arbitrary hex tokens.
_CHECK_43_COMMIT_SHA_PATTERN = re.compile(r"\bcommit\s+[0-9a-f]{7,40}\b")

# JC-2 proto-validity rule (BD-195 C2 §2.2 Step-4): the shipped proto tree
# under this prefix. A proto reference whose basename resolves to an
# existing file WITHIN this tree is legitimate project-side content.
_CHECK_43_PROTO_TREE_PREFIX = "project-template/proto"


def _check_43_proto_resolves_in_tree(basename: str) -> bool:
    """Durable proto-validity rule (BD-195 C2 §2.2 Step-4).

    Return True iff `basename` is a `.proto` filename that resolves to an
    existing file WITHIN the shipped `project-template/proto/` tree. Such a
    reference is a legitimate proto self-import (gRPC/protobuf is a
    supported language with dedicated skill(s)) and is never a leak.

    This REPLACES the prior two hardcoded allowlist basenames
    (`common.proto`, `example_service.proto`) with a rule that survives the
    proto tree growing or skills adding example protos. It is bounded
    (`ci-guard-measure-then-bound`): it admits ONLY `.proto` basenames that
    actually resolve inside the proto tree — never an external/non-resolving
    proto path, never a pack-doc basename, never any other STRIP-class hit.
    A `google/protobuf/*` well-known import does NOT resolve in-tree and is
    therefore NOT admitted by this rule (it is an external import, out of
    scope for the leak guard).

    Defensive note: the current matcher tiers do not fire on proto imports
    at all (`.proto` is absent from `_CHECK_40_FILE_EXTS`, so the bare-ref /
    hyperlink regexes never produce a `.proto` basename), so this rule has
    no effect on the present fire-set. It exists so that any FUTURE
    matchable proto reference is correctly recognized as valid.
    """
    if not basename.endswith(".proto"):
        return False
    proto_root = REPO_ROOT / _CHECK_43_PROTO_TREE_PREFIX
    if not proto_root.is_dir():
        return False
    for cand in proto_root.rglob(basename):
        if cand.is_file():
            return True
    return False


def _build_pack_only_doc_basenames() -> set[str]:
    """Return the set of pack-only-doc basenames for the JC-2 bare-prose
    axis (i), measured from the tree (`ci-guard-measure-then-bound`).

    A basename is a target iff EVERY repo file with that basename lives
    under a pack-only top-level tree (`_CHECK_43_PACK_ONLY_DOC_TREES`),
    minus: the regenerated mirrors (`BACKLOG.md` / `CHANGELOG.md`), the
    client-installed `HELP-FRAGMENT-TRACKER.md`, and any basename on
    `_CHECK_43_ALLOWLIST` (the curated client-resolvable set). The
    "every-location-pack-only" rule is the over-fire bound: basenames
    with a project-side / client-installed instance (`ARCHITECTURE.md`,
    `README.md`, `IMPLEMENTATION-PLAN.md`, …) are excluded; only
    exclusively-pack-only docs (`V10-DESIGN.md`,
    `V10-CODEX-MCP-RESEARCH.md`, `MERGE-STRATEGY.md`) remain. `.git/` is
    skipped; the basename index's archive-exclusion does NOT apply here
    (archive docs ARE pack-only and must be catchable)."""
    mirror_skip = {"BACKLOG.md", "CHANGELOG.md", "HELP-FRAGMENT-TRACKER.md"}
    # Map basename -> set of top-level dirs it appears under.
    tops_by_basename: dict[str, set[str]] = {}
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        try:
            rel = path.relative_to(REPO_ROOT)
        except ValueError:
            continue
        parts = rel.parts
        if not parts or parts[0] == ".git":
            continue
        tops_by_basename.setdefault(path.name, set()).add(parts[0])
    pack_only_trees = set(_CHECK_43_PACK_ONLY_DOC_TREES)
    out: set[str] = set()
    for basename, tops in tops_by_basename.items():
        if basename in mirror_skip:
            continue
        if basename in _CHECK_43_ALLOWLIST:
            continue
        if tops and tops <= pack_only_trees:
            out.add(basename)
    return out


# ── BD-199: Check 43 hot-path precompilation ─────────────────────────────
# Check 43's bare-prose tier formerly rebuilt a regex string and ran
# re.search PER (line × basename) — O(lines × 586 basenames) ≈ 9.4M
# re.compile cache-misses, ~355 s wall. The fix (ARCHITECTURE-BD-199-
# VALIDATE-PACK-PERF.md §2.1–§2.2) collapses the N per-basename patterns
# into ONE precompiled alternation, scanned ONCE per line, with a per-line
# basename dedupe to reproduce the prior "first match per distinct basename"
# fire-set EXACTLY. The two qualified-prefix patterns (§2.3 Lever C) are
# likewise hoisted from re.compile-in-loop to module-precompiled constants.


def _build_bare_prose_alternation(
    pack_only_doc_basenames: "set[str]",
) -> "re.Pattern[str] | None":
    """Build the single precompiled bare-prose alternation for Check 43.

    Semantically identical to the former per-basename pattern
    `(?<![A-Za-z0-9_.-]) + re.escape(basename) + (?![A-Za-z0-9_.-])`:
    the lookbehind/lookahead boundary classes are byte-copied, and the
    alternatives are exactly `re.escape(b)` for each `b` in the set.

    Correctness constraint (ARCHITECTURE-BD-199 §2.1): Python alternation
    is FIRST-alternative-wins, NOT longest-match, so the alternatives are
    sorted by DESCENDING LENGTH before joining. Longest-first guarantees
    the regex prefers the longest valid basename at any position, which —
    combined with the trailing boundary lookahead — reproduces the union
    of the 586 independent single-basename searches. Returns None when the
    set is empty (no detector to build; caller skips the tier).
    """
    if not pack_only_doc_basenames:
        return None
    ordered = sorted(pack_only_doc_basenames, key=lambda b: (-len(b), b))
    alternation = "|".join(re.escape(b) for b in ordered)
    return re.compile(
        r"(?<![A-Za-z0-9_.-])(?:" + alternation + r")(?![A-Za-z0-9_.-])"
    )


# Qualified pack-internal prefix detectors (§2.3 Lever C). Formerly
# re.compile'd per (line × prefix) inside the Check 43 line loop; hoisted
# to a module-precompiled (prefix -> compiled pattern) mapping. The pattern
# body is byte-identical to the former in-loop construction
# (`re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"`).
_CHECK_43_PACK_INTERNAL_PREFIX_PATTERNS = {
    prefix: re.compile(
        re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"
    )
    for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES
}


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

    # JC-2 axis (i): pack-only-doc basename set (built from the tree, not
    # a hand-list) for the bare-prose detector. BD-195 C2 §2.2 Step-3 (b).
    pack_only_doc_basenames = _build_pack_only_doc_basenames()
    # BD-199: collapse the 586 per-basename patterns into ONE precompiled
    # descending-length-sorted alternation, built ONCE per invocation (was
    # rebuilt+searched per line × basename → 9.4M re.compile cache-misses).
    bare_prose_pattern = _build_bare_prose_alternation(pack_only_doc_basenames)

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
        # _CHECK_40_FILE_EXTS) PLUS the JC-2 walk-extension broadening
        # (BD-195 C2 §2.2 axis iii: `.example` double-extension config
        # samples + `.proto`). Skip files whose extension is not in the
        # recognized set so we do not walk arbitrary binary content via
        # the basename regex.
        suffix = rel_path.suffix.lstrip(".")
        if (
            suffix not in _CHECK_40_FILE_EXTS.split("|")
            and suffix not in _CHECK_43_EXTRA_WALK_SUFFIXES
        ):
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
                # JC-2 prefix tightening (BD-195 C2 §2.2 axis d): a
                # qualified `supporting-docs/<X>` path on a client surface
                # is a dead PATH regardless of whether <X> ships elsewhere
                # — there is no `supporting-docs/` directory at a client
                # install. Even an installed-elsewhere basename (e.g.
                # METHODOLOGY.md, which ships to docs/pack/) must be cited
                # by its client-resolvable `docs/pack/<X>` path, not the
                # pre-install `supporting-docs/` path. (Previously this
                # FAILed only when <X> was NOT in the installed set.)
                # Anchor-phrase exemption per §1.5 preserves intentional
                # pack-as-product cites; fenced lines are already skipped
                # above (disjoint from the client-surface prefix-hit set).
                if _check_43_context_has_anchor(stripped_lines, lineno):
                    hits_anchor += 1
                    continue
                installed_note = (
                    " (basename ships to a client-resolvable path; cite "
                    "that path, e.g. docs/pack/" + fname + ")"
                    if fname in installed_supporting_docs
                    else " (pre-install reference; not shipped to clients "
                    "via _CLIENT_INSTALLED_FILES inventory)"
                )
                fail(
                    f"{rel_path}:{lineno} — qualified reference "
                    f"`supporting-docs/{fname}` names the pre-install "
                    f"`supporting-docs/` directory, absent at a client "
                    f"install{installed_note}. Remediation: cite the "
                    f"client-resolvable `docs/pack/<X>` path OR drop the "
                    f"cite OR — if intentional pack-as-product cite — add "
                    f"an anchor phrase like \"in the pack repo\" within "
                    f"±2 lines."
                )
                any_failed = True

            # JC-2 axis (ii) — commit-SHA-as-provenance (BD-195 C2 §2.2).
            # A `commit <hex>` provenance citation on a client surface
            # points at pack-repo git history the client cannot resolve.
            if _CHECK_43_COMMIT_SHA_PATTERN.search(line):
                if not _check_43_context_has_anchor(stripped_lines, lineno):
                    fail(
                        f"{rel_path}:{lineno} — commit-SHA provenance "
                        f"citation (`commit <sha>`) names pack-repo git "
                        f"history not resolvable at a client install. "
                        f"Remediation: drop the commit-SHA provenance OR "
                        f"— if intentional pack-as-product cite — add an "
                        f"anchor phrase like \"in the pack repo\" within "
                        f"±2 lines."
                    )
                    any_failed = True
                else:
                    hits_anchor += 1

            # JC-2 axis (i) — bare-prose pack-doc-basename (BD-195 C2 §2.2).
            # A pack-only-doc basename named on a client surface in
            # NON-backtick prose (or inside a qualified `docs/pack/<X>`
            # path the bare-ref regex's `/`-exclusion misses) is a dead
            # pointer — the doc never ships to a client. The basename set
            # is built from the pack-only doc tree (NOT a hand-list) per
            # ci-guard-measure-then-bound. Match on word boundaries so a
            # basename inside a qualified path is caught; skip backtick-
            # isolated bare refs (those are handled by the bare-ref tier
            # below) to avoid double-flagging. Anchor-phrase exemption
            # preserves intentional pack-as-product cites.
            #
            # BD-199: ONE precompiled alternation (built once at function
            # entry) scanned per line via finditer, replacing the former
            # per-(line × basename) re.search loop. Each match's basename
            # is `m.group()`. Per-line dedupe by basename (`seen_on_line`)
            # reproduces the former "re.search = first occurrence, once per
            # distinct basename" fire-set EXACTLY — finditer yields ALL
            # occurrences (incl. the same basename twice on one line), so
            # the dedupe is the multiplicity-equivalence guarantee
            # (ARCHITECTURE-BD-199 §2.2). The boundary classes, backtick-
            # skip, anchor exemption, and fail() text are byte-identical to
            # the prior per-basename loop.
            if bare_prose_pattern is not None:
                seen_on_line: set[str] = set()
                for m in bare_prose_pattern.finditer(line):
                    doc_basename = m.group()
                    if doc_basename in seen_on_line:
                        continue
                    seen_on_line.add(doc_basename)
                    # Skip the backtick-isolated bare-ref form `X.md` — that
                    # is the existing bare-ref tier's surface (handled
                    # below); the bare-PROSE axis targets the non-backtick /
                    # qualified-path form the bare-ref regex misses.
                    start = m.start()
                    end = m.end()
                    if (
                        start > 0
                        and line[start - 1] == "`"
                        and end < len(line)
                        and line[end] == "`"
                    ):
                        continue
                    if _check_43_context_has_anchor(stripped_lines, lineno):
                        hits_anchor += 1
                        continue
                    fail(
                        f"{rel_path}:{lineno} — bare-prose reference to "
                        f"pack-only doc `{doc_basename}` (lives under "
                        f"maintenance-docs/ or pack-ops/; never shipped to a "
                        f"client). Remediation: drop the cite OR replace with "
                        f"a project-side SSOT (e.g., docs/pack/PM-CHAT.md) OR "
                        f"— if intentional pack-as-product cite — add an anchor "
                        f"phrase like \"in the pack repo\" within ±2 lines."
                    )
                    any_failed = True

            # Qualified pack-ops/<X> and maintenance-docs/<X> detection
            # (LEAK CLASS D in scripts/lib/detect.sh comments / LEAK
            # CLASS for any qualified pack-only path-prefix in project-
            # side prose). Bare-ref regex would not match these because
            # of the `/` separator; explicit substring detection.
            for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:
                # BD-199: pattern hoisted to a module-precompiled mapping
                # (was re.compile'd per line × prefix). Pattern body is
                # byte-identical to the former in-loop construction.
                pattern = _CHECK_43_PACK_INTERNAL_PREFIX_PATTERNS[prefix]
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
                # Tier 1b: durable proto-validity rule (BD-195 C2 §2.2
                # Step-4). A `.proto` basename that resolves WITHIN
                # `project-template/proto/` is a legitimate proto
                # self-import — never a leak. Bounded to resolve-in-tree
                # imports only (`ci-guard-measure-then-bound`); replaces the
                # prior two hardcoded proto basenames so the rule survives
                # the proto tree growing.
                if _check_43_proto_resolves_in_tree(basename):
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


def check_pack_memory_rationale_bijection() -> None:
    """Check 45 — pack-memory rule↔rationale bijection (BD-196).

    Enforces a set-equality bijection between two surfaces, over the
    PRESENT `[rationale:]` set (per ARCHITECTURE-DOC-CONCISION-
    GUARDRAILS.md §5.2):

      - the set of `[rationale: <slug>]` slugs tagged on imperative
        lines in `CLAUDE.md` `## Pack memory` (the corpus
        representative — trinity parity of AGENTS.md / GEMINI.md is
        separately enforced by Checks 16/18/19), AND

      - the set of `## <slug>` section headings in
        `pack-ops/PACK-MEMORY-RATIONALE.md`.

    FAIL if the two sets are not equal in EITHER direction:
      - an orphan corpus slug (a `[rationale: slug]` with no matching
        `## slug` heading), OR
      - an orphan rationale heading (a `## slug` with no live
        `[rationale: slug]` pointer in the corpus).

    Rules that carry NO `[rationale:]` tag are simply not in the set —
    the check does not require every spawn-rule to have a rationale.
    This makes drift impossible: you cannot delete a rule and orphan
    its rationale, or add a rationale for a rule that does not exist.

    Pattern: follows `check_mirror_in_sync` (Check 32) — a set-equality
    assertion between two surfaces. Trigger: any commit touching either
    file.

    Lenient mode: if either surface is absent (unlikely at any
    reasonable pack-repo HEAD) the check SKIPs with a notice rather
    than failing — a missing surface is an init/state problem, not a
    bijection violation.
    """
    print("\n── Check 45: pack-memory rule↔rationale bijection (BD-196) ──")

    corpus_path = REPO_ROOT / "CLAUDE.md"
    rationale_path = REPO_ROOT / "pack-ops" / "PACK-MEMORY-RATIONALE.md"

    if not corpus_path.is_file():
        ok("CLAUDE.md absent — skipping (lenient)")
        return
    if not rationale_path.is_file():
        ok("pack-ops/PACK-MEMORY-RATIONALE.md absent — skipping (lenient)")
        return

    # Restrict the corpus scan to the `## Pack memory` section so that a
    # `[rationale: slug]` appearing in unrelated prose elsewhere in
    # CLAUDE.md cannot pollute the set. The section runs from its `## `
    # heading to the next top-level `## ` heading (or EOF).
    corpus_lines = corpus_path.read_text().splitlines()
    in_pack_memory = False
    pack_memory_text_lines = []
    for line in corpus_lines:
        if line.startswith("## "):
            # Match the Pack memory H2 by its leading token; the heading
            # text is `## Pack memory (project-local learnings)`.
            in_pack_memory = line.startswith("## Pack memory")
            continue
        if in_pack_memory:
            pack_memory_text_lines.append(line)
    pack_memory_text = "\n".join(pack_memory_text_lines)

    rationale_re = re.compile(r"\[rationale:\s*([a-z0-9][a-z0-9-]*)\]")
    corpus_slugs = sorted(set(rationale_re.findall(pack_memory_text)))

    # Parse `## <slug>` headings from the rationale file. Slug headings
    # are the controlled-vocab kebab-case form; a `## ` heading that is
    # not a slug (e.g., a prose section header) would simply not match
    # the slug character class and be excluded — but by design every
    # `## ` heading in the rationale file IS a slug section.
    heading_re = re.compile(r"^##\s+([a-z0-9][a-z0-9-]*)\s*$", re.MULTILINE)
    rationale_text = rationale_path.read_text()
    rationale_slugs = sorted(set(heading_re.findall(rationale_text)))

    corpus_set = set(corpus_slugs)
    rationale_set = set(rationale_slugs)

    orphan_corpus_slugs = sorted(corpus_set - rationale_set)
    orphan_rationale_headings = sorted(rationale_set - corpus_set)

    if orphan_corpus_slugs:
        fail(
            f"CLAUDE.md `## Pack memory` carries {len(orphan_corpus_slugs)} "
            f"`[rationale: slug]` pointer(s) with NO matching `## <slug>` "
            f"heading in pack-ops/PACK-MEMORY-RATIONALE.md: "
            f"{orphan_corpus_slugs}. Per BD-196 / ARCHITECTURE-DOC-"
            f"CONCISION-GUARDRAILS.md §5.2 the rule↔rationale bijection "
            f"requires every corpus `[rationale: slug]` to resolve to "
            f"exactly one rationale section. Remediation: add the missing "
            f"`## <slug>` section(s) to pack-ops/PACK-MEMORY-RATIONALE.md "
            f"in the SAME commit, or remove the orphan `[rationale: slug]` "
            f"pointer(s) from the corpus."
        )
    if orphan_rationale_headings:
        fail(
            f"pack-ops/PACK-MEMORY-RATIONALE.md carries "
            f"{len(orphan_rationale_headings)} `## <slug>` heading(s) with "
            f"NO matching live `[rationale: slug]` pointer in CLAUDE.md "
            f"`## Pack memory`: {orphan_rationale_headings}. Per BD-196 / "
            f"ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §5.2 the rule↔"
            f"rationale bijection requires every rationale section to map "
            f"to exactly one live corpus pointer. Remediation: add the "
            f"`[rationale: slug]` pointer to the matching corpus rule in "
            f"the SAME commit, or remove the orphan `## <slug>` section "
            f"from the rationale file."
        )

    if not orphan_corpus_slugs and not orphan_rationale_headings:
        ok(
            f"Check 45 — {len(corpus_slugs)} corpus `[rationale: slug]` "
            f"pointer(s); {len(rationale_slugs)} rationale `## <slug>` "
            f"section(s); sets are equal (bijection holds, no orphans "
            f"in either direction)."
        )


# ── Check 46: boundary + spawn-rule pointer manifests (BD-196 C6) ──────────
# Combined reference-resolution + anti-restate check over the two
# machine-readable manifests authored by BD-196 (C5 + C6):
#   - pack-ops/.boundary-pointer-manifest.txt  (B5; the deleted BOUNDARY §6
#     entry-point network — surface → expected pointer to BOUNDARY-DEFINITION)
#   - pack-ops/.spawn-rule-manifest.txt         (§9.6; spawn-relevant rule
#     slug → canonical `## Pack memory` home + the reference surfaces where
#     the collapsed one-line pointer now lives)
#
# Two assertions (per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 + §9.6):
#   (a) REFERENCE-RESOLUTION (Check-34 pattern) — every named surface in
#       either manifest exists AND carries its expected resolving pointer.
#   (b) ANTI-RESTATE (the §9.6 substring scan, SC7-bounded) — no canonical
#       `## Pack memory` imperative BODY reappears verbatim in any spawn-rule
#       reference surface or spawn-relevant skill. The predicate scans the
#       imperative BODY (first clause, whitespace-normalized, >= a minimum
#       length) NOT the rule NAME, so a legitimate one-line reference that
#       merely NAMES a rule ("Agents never commit — see trinity `## Pack
#       memory` ...") cannot false-positive (the SC7 / §4.2-storm shape).
#
# Implemented as ONE function per PLAN §2 G-A (the design left the 3-vs-4
# split as a coder call; one function over both manifests minimizes surface
# and shares the manifest-parse + resolution helpers).

# The anti-restate scan targets: the spawn-rule reference surfaces +
# the spawn-relevant skills (the 4 the design names). Skills live under
# `.claude/skills/`; the trinity skill mirrors (.codex / .agents) carry
# identical content (parity-checked elsewhere) — scanning the .claude
# copy is sufficient for the anti-restate teeth.
_CHECK_46_ANTI_RESTATE_SURFACES = (
    "pack-ops/PACK-AGENTS.md",
    "pack-ops/PACK-CHAT.md",
    ".claude/skills/commit-discipline/SKILL.md",
    ".claude/skills/review/SKILL.md",
    ".claude/skills/planning/SKILL.md",
    ".claude/skills/implementation-report/SKILL.md",
)

# SC7 bound (measured 2026-05-30, HEAD 0cbd6d5): the NAIVE rule-NAME
# predicate stormed 6/6 on legitimate name-bearing references; the BODY
# predicate at >= 60 chars yields 0 hits post-C5-collapse AND still catches
# an injected verbatim restatement. The scan targets the whitespace-
# normalized imperative BODY (the text AFTER the bold rule name — see
# _check_46_extract_pack_memory_imperative_bodies, which discards the NAME
# group entirely), NOT the rule name. Rule-NAME length is therefore
# irrelevant to the bound: names are never scanned, so a long name cannot
# false-positive. The >= 60-char window is chosen empirically — every real
# `## Pack memory` imperative BODY's leading clause exceeds it (no false-
# negative: a genuine verbatim restatement is caught), while a legitimate
# one-line reference (which names the rule and paraphrases, rather than
# reproducing 60+ contiguous verbatim chars of an imperative body) cannot
# reach the threshold (no false-positive). The bound separates one-line
# NAME references from verbatim BODY restatements — it is body-derived,
# not name-derived.
_CHECK_46_ANTI_RESTATE_MIN_LEN = 60


def _parse_manifest_records(text: str) -> list:
    """Parse a blank-line-separated `key: value` manifest into records.

    Lines beginning with `#` are comments. A blank line ends a record.
    Repeated keys within a record are joined with a space (wrapped
    `references:` continuation lines). Returns a list of dicts.
    """
    records = []
    cur = {}
    for raw in text.splitlines():
        if raw.lstrip().startswith("#"):
            continue
        if not raw.strip():
            if cur:
                records.append(cur)
                cur = {}
            continue
        m = re.match(r"(\w+):\s*(.*)", raw)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if key in cur:
                cur[key] = (cur[key] + " " + val).strip()
            else:
                cur[key] = val
        elif cur:
            # A continuation line with no `key:` prefix (indented wrap of
            # the previous value). Append to the last key seen.
            last_key = list(cur.keys())[-1]
            cur[last_key] = (cur[last_key] + " " + raw.strip()).strip()
    if cur:
        records.append(cur)
    return records


def _check_46_extract_pack_memory_imperative_bodies(min_len: int) -> list:
    """Extract the canonical `## Pack memory` imperative BODY strings.

    Each bullet is `- **<name>.** <body...>`. We take the BODY (everything
    after the bold name), collapse whitespace, and keep the leading window
    if it is at least `min_len` chars. Returns the candidate substrings used
    by the anti-restate scan. The NAME is deliberately excluded so a
    one-line reference that names the rule cannot match (SC7 bound).
    """
    corpus_path = REPO_ROOT / "CLAUDE.md"
    if not corpus_path.is_file():
        return []
    lines = corpus_path.read_text().splitlines()
    in_pack_memory = False
    pm_lines = []
    for line in lines:
        if line.startswith("## "):
            in_pack_memory = line.startswith("## Pack memory")
            continue
        if in_pack_memory:
            pm_lines.append(line)
    pm_text = "\n".join(pm_lines)

    # Bullet bodies: text after the bold name up to the next top-level
    # bullet, blank line, or EOF.
    bodies = re.findall(
        r"^- \*\*.+?\*\*\s*(.+?)(?=\n- \*\*|\n\n|\Z)",
        pm_text,
        re.MULTILINE | re.DOTALL,
    )
    candidates = []
    for body in bodies:
        normalized = re.sub(r"\s+", " ", body).strip()[:120]
        if len(normalized) >= min_len:
            candidates.append(normalized)
    return candidates


def check_boundary_and_spawn_pointer_manifests() -> None:
    """Check 46 — boundary + spawn-rule pointer manifests (BD-196 C6).

    (a) Reference-resolution (Check-34 pattern): every surface named in
        pack-ops/.boundary-pointer-manifest.txt and
        pack-ops/.spawn-rule-manifest.txt exists on disk AND carries its
        expected resolving pointer.
          - boundary manifest: the surface contains the `pointer` substring
            (the BOUNDARY-DEFINITION.md basename).
          - spawn manifest: every surface named in the record's `references`
            field exists AND references the canonical home (`## Pack memory`)
            so the collapsed one-line pointer resolves to the SSOT.
    (b) Anti-restate (§9.6, SC7-bounded): no `## Pack memory` imperative
        BODY (first clause, whitespace-normalized, >= 60 chars) reappears
        verbatim in any spawn-rule reference surface or spawn-relevant skill.

    Lenient mode: a manifest that is absent SKIPs with a notice (an
    init/state problem, not a resolution violation).

    Pattern: composes Check 34 (cross-reference integrity) for the
    resolution half and a measure-then-bound substring scan for the
    anti-restate half. Per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md
    §4.3 + §9.6; PLAN-DOC-CONCISION-GUARDRAILS.md §2 (G-A: one function).
    """
    print(
        "\n── Check 46: boundary + spawn-rule pointer manifests (BD-196) ──"
    )

    boundary_manifest = REPO_ROOT / "pack-ops" / ".boundary-pointer-manifest.txt"
    spawn_manifest = REPO_ROOT / "pack-ops" / ".spawn-rule-manifest.txt"

    if not boundary_manifest.is_file() and not spawn_manifest.is_file():
        ok(
            "neither pointer manifest present (skipping; lenient) — "
            "pack-ops/.boundary-pointer-manifest.txt + "
            "pack-ops/.spawn-rule-manifest.txt are authored by BD-196 C5/C6"
        )
        return

    any_fail = False

    # ── (a1) Boundary-pointer manifest reference-resolution ──────────────
    boundary_surfaces = 0
    if boundary_manifest.is_file():
        records = _parse_manifest_records(boundary_manifest.read_text())
        for rec in records:
            surface = rec.get("surface")
            pointer = rec.get("pointer")
            if not surface or not pointer:
                fail(
                    f"pack-ops/.boundary-pointer-manifest.txt: a record is "
                    f"missing a `surface:` or `pointer:` field "
                    f"(record={rec!r}). Each record requires both."
                )
                any_fail = True
                continue
            boundary_surfaces += 1
            surface_path = REPO_ROOT / surface
            if not surface_path.is_file():
                fail(
                    f"pack-ops/.boundary-pointer-manifest.txt names surface "
                    f"`{surface}` which does NOT exist on disk. Per BD-196 / "
                    f"ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §4.3 the "
                    f"boundary-pointer manifest is the deleted BOUNDARY §6 "
                    f"entry-point network; every named surface must exist. "
                    f"Remediation: restore the surface or remove its manifest "
                    f"record in the SAME commit."
                )
                any_fail = True
                continue
            if pointer not in surface_path.read_text():
                fail(
                    f"surface `{surface}` no longer carries its expected "
                    f"BOUNDARY-DEFINITION pointer (substring `{pointer}` not "
                    f"found). Per BD-196 the boundary pointer network is "
                    f"CI-asserted: a surface that silently loses its pointer "
                    f"breaks the discoverability invariant. Remediation: "
                    f"restore the pointer to `{surface}`, or remove its "
                    f"record from pack-ops/.boundary-pointer-manifest.txt in "
                    f"the SAME commit."
                )
                any_fail = True

    # ── (a2) Spawn-rule manifest reference-resolution ────────────────────
    spawn_records = 0
    if spawn_manifest.is_file():
        records = _parse_manifest_records(spawn_manifest.read_text())
        # A reference surface resolves the collapsed one-line pointer if it
        # exists AND points at the canonical home (`## Pack memory`). The
        # surface basename is parsed from the `references:` free-text by
        # matching the known reference-surface basenames.
        known_ref_files = {
            "PACK-AGENTS.md": REPO_ROOT / "pack-ops" / "PACK-AGENTS.md",
            "PACK-CHAT.md": REPO_ROOT / "pack-ops" / "PACK-CHAT.md",
        }
        for rec in records:
            slug = rec.get("slug")
            canonical = rec.get("canonical", "")
            references = rec.get("references", "")
            if not slug or not references:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt: a record is missing "
                    f"a `slug:` or `references:` field (record={rec!r})."
                )
                any_fail = True
                continue
            spawn_records += 1
            if "## Pack memory" not in canonical:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt slug `{slug}`: the "
                    f"`canonical:` field must name `## Pack memory` (the "
                    f"single spawn-source per §9.2); got `{canonical}`."
                )
                any_fail = True
            # Each named reference surface must exist + point at the canonical
            # home so the collapsed pointer resolves to the SSOT.
            named = [b for b in known_ref_files if b in references]
            if not named:
                fail(
                    f"pack-ops/.spawn-rule-manifest.txt slug `{slug}`: the "
                    f"`references:` field names no known reference surface "
                    f"(expected one of {sorted(known_ref_files)}); got "
                    f"`{references[:80]}`."
                )
                any_fail = True
                continue
            for basename in named:
                ref_path = known_ref_files[basename]
                if not ref_path.is_file():
                    fail(
                        f"pack-ops/.spawn-rule-manifest.txt slug `{slug}` "
                        f"references `{basename}` which does NOT exist."
                    )
                    any_fail = True
                    continue
                if "## Pack memory" not in ref_path.read_text():
                    fail(
                        f"reference surface `{basename}` (named by spawn-rule "
                        f"slug `{slug}`) no longer points at the canonical "
                        f"home `## Pack memory`. Per BD-196 §9.6 the collapsed "
                        f"one-line reference MUST resolve to the SSOT. "
                        f"Remediation: restore the `## Pack memory` reference "
                        f"in `{basename}`, or update the manifest record."
                    )
                    any_fail = True

    # ── (b) Anti-restate substring scan (SC7-bounded) ────────────────────
    candidates = _check_46_extract_pack_memory_imperative_bodies(
        _CHECK_46_ANTI_RESTATE_MIN_LEN
    )
    restate_hits = 0
    for surface in _CHECK_46_ANTI_RESTATE_SURFACES:
        surface_path = REPO_ROOT / surface
        if not surface_path.is_file():
            # A spawn-relevant surface absent at HEAD is unexpected but not
            # a restatement violation; skip it silently (the boundary/spawn
            # resolution halts above would surface a missing required file).
            continue
        normalized = re.sub(r"\s+", " ", surface_path.read_text())
        for body in candidates:
            if body in normalized:
                restate_hits += 1
                fail(
                    f"anti-restate violation: surface `{surface}` contains a "
                    f"verbatim `## Pack memory` imperative BODY "
                    f"(>= {_CHECK_46_ANTI_RESTATE_MIN_LEN} chars): "
                    f"`{body[:80]}...`. Per BD-196 §9.6 a spawn-relevant rule "
                    f"is authored ONCE in `## Pack memory`; reference surfaces "
                    f"carry a ONE-LINE pointer, never a verbatim restatement. "
                    f"Remediation: collapse the restatement back to a one-line "
                    f"reference of the form \"<name> — see trinity `## Pack "
                    f"memory` `[rationale: <slug>]`\"."
                )
                any_fail = True

    if not any_fail:
        ok(
            f"Check 46 — boundary manifest: {boundary_surfaces} surface(s) "
            f"resolve their BOUNDARY-DEFINITION pointer; spawn manifest: "
            f"{spawn_records} rule(s) resolve to `## Pack memory`; "
            f"anti-restate: 0 verbatim imperative-body restatements across "
            f"{len(_CHECK_46_ANTI_RESTATE_SURFACES)} spawn-relevant surface(s) "
            f"({len(candidates)} candidate bodies scanned, "
            f">= {_CHECK_46_ANTI_RESTATE_MIN_LEN} chars)."
        )


# ── Check 44: M4 durable-doc concision gate (BD-196 C10) ───────────────────
# The M4 concision gate over the 7 durable pack-ops/ non-mirror rule docs
# (the M4 class per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 +
# PLAN-DOC-CONCISION-GUARDRAILS.md EE-P1). Two parts:
#
#   (a) THE TEETH (hard-fail) — forbidden-pattern count = 0 OUTSIDE the
#       allowlist. The forbidden patterns are report-only artifacts that
#       MUST NOT appear in forward-only durable rule docs (the C2 surface-
#       separation rule: SHAs/dates/Commit-N/Override-N/post-Commit/temporal
#       'will' belong in agent reports, not durable docs). Any matched line
#       NOT covered by a pack-ops/.concision-allowlist.txt record FAILs.
#       The allowlist is sized to the KEEP set EXACTLY (measure-then-bound):
#       only legitimate operational-behavioral occurrences are admitted; it
#       is NOT widened to swallow contamination.
#
#   (b) ADVISORY length (soft, never fails) — each doc carries a per-doc
#       advisory ceiling DERIVED from its measured legitimate (post-C4/C9
#       cleaned) content (ceil(measured * 1.15) — a 15% growth headroom,
#       per-doc, NOT a uniform round cap). Exceeding it emits an advisory
#       OK-notice, never a failure (length is a smell, not a hard rule;
#       the forbidden-pattern count is the enforcing teeth — ARCHITECTURE
#       §6 "SC1 limits": enforcing limit = 0-outside-allowlist; length is
#       per-doc advisory).
#
# Pattern: a fresh scan + the existing _parse_manifest_records() allowlist-
# file read pattern (shared with Check 46). Per ARCHITECTURE-DOC-CONCISION-
# GUARDRAILS.md §6 (M1-M4) + §7; PLAN-DOC-CONCISION-GUARDRAILS.md §3 C10.

# The M4 forbidden-pattern set — IDENTICAL to the C4/C9 canonical reshape
# probe (so the gate enforces exactly the contract those commits cleaned to):
#   dates / 7-40-hex SHAs / Commit N / Override N / post-Commit / temporal
#   'will '. The hex pattern is word-boundary-anchored (\b…\b) so ordinary
#   lowercase-hex-only English words do not false-match; the 'will' pattern
#   carries a trailing space (the canonical `\bwill ` probe form).
_CHECK_44_FORBIDDEN_PATTERNS = (
    ("date", re.compile(r"20[0-9]{2}-[0-9]{2}-[0-9]{2}")),
    ("sha", re.compile(r"\b[0-9a-f]{7,40}\b")),
    ("commit-N", re.compile(r"Commit [0-9]")),
    ("override-N", re.compile(r"Override [0-9]")),
    ("post-Commit", re.compile(r"post-Commit")),
    ("will", re.compile(r"\bwill ")),
)

# The 7 durable pack-ops/ non-mirror rule docs (M4 class) + each doc's
# per-doc ADVISORY line ceiling, DERIVED from its measured post-C4/C9
# cleaned content as ceil(measured * 1.15). These are NOT round numbers:
# each is anchored to the doc's actual cleaned size at HEAD 60ec0db
# (BOUNDARY 135, CONCEPTUAL-REVIEW 298, DRY-RUN 199, HELP-PACK 42,
# HELP-TRACKER 49, MERGE 484, OPTIONAL 235) with a uniform 15% growth
# headroom. BACKLOG.md / CHANGELOG.md are regenerated MIRRORS, NOT in
# the M4 class (EE-P1). The ceiling is advisory only (never fails).
_CHECK_44_DURABLE_DOCS = (
    ("pack-ops/BOUNDARY-DEFINITION.md", 156),
    ("pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md", 343),
    ("pack-ops/DRY-RUN-MIGRATION.md", 229),
    ("pack-ops/HELP-FRAGMENT-PACK.md", 49),
    ("pack-ops/HELP-FRAGMENT-TRACKER.md", 57),
    ("pack-ops/MERGE-STRATEGY.md", 557),
    ("pack-ops/OPTIONAL-FEATURES.md", 271),
)


def _check_44_load_allowlist() -> dict:
    """Parse pack-ops/.concision-allowlist.txt into {doc: [snippet, ...]}.

    Each record carries `doc:`, `pattern:`, `snippet:`, `reason:`. The
    matching key is (doc, snippet-substring) — line numbers are NOT used
    (they drift). Returns a dict mapping each doc path to its list of
    allowlisted snippet substrings. Reuses _parse_manifest_records().
    """
    allowlist_path = REPO_ROOT / "pack-ops" / ".concision-allowlist.txt"
    if not allowlist_path.is_file():
        return {}
    records = _parse_manifest_records(allowlist_path.read_text())
    by_doc: dict = {}
    for rec in records:
        doc = rec.get("doc")
        snippet = rec.get("snippet")
        if doc and snippet:
            by_doc.setdefault(doc, []).append(snippet)
    return by_doc


def check_durable_doc_concision() -> None:
    """Check 44 — M4 durable-doc concision gate (BD-196 C10).

    Scans the 7 durable pack-ops/ non-mirror rule docs (the M4 class) for
    forbidden report-only patterns (dates / 7-40-hex SHAs / Commit N /
    Override N / post-Commit / temporal 'will '). THE TEETH: any matched
    line NOT covered by a pack-ops/.concision-allowlist.txt record
    (doc match AND an allowlisted snippet is a substring of the line)
    FAILs — forbidden-pattern count must be 0 OUTSIDE the allowlist.

    ADVISORY: each doc also carries a per-doc advisory line ceiling
    (derived from measured cleaned content); exceeding it emits an
    OK-advisory notice, NEVER a failure (length is a smell, the
    forbidden-pattern teeth are the enforcement).

    Per ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md §6 (M1-M4) + §7;
    PLAN-DOC-CONCISION-GUARDRAILS.md §3 C10. The allowlist is sized to
    the KEEP set EXACTLY (measure-then-bound) — never widened to admit a
    contamination hit.

    Lenient mode: a durable doc absent at HEAD SKIPs that doc with a
    notice (an init/state problem, not a concision violation); a missing
    allowlist file means an empty allowlist (every forbidden hit then
    FAILs — fail-loud, never silently-pass).
    """
    print("\n── Check 44: M4 durable-doc concision gate (BD-196) ──")

    allowlist = _check_44_load_allowlist()

    any_fail = False
    scanned_docs = 0
    total_forbidden_outside = 0
    total_allowlisted = 0

    for doc_rel, advisory_ceiling in _CHECK_44_DURABLE_DOCS:
        doc_path = REPO_ROOT / doc_rel
        if not doc_path.is_file():
            ok(f"{doc_rel} absent — skipping that doc (lenient)")
            continue
        scanned_docs += 1
        snippets = allowlist.get(doc_rel, [])
        lines = doc_path.read_text().splitlines()

        for lineno, line in enumerate(lines, start=1):
            matched_patterns = [
                name for name, rx in _CHECK_44_FORBIDDEN_PATTERNS
                if rx.search(line)
            ]
            if not matched_patterns:
                continue
            # A line is allowlisted iff one of the doc's allowlist
            # snippets is a substring of the line (content-anchored, not
            # line-number-anchored — line numbers drift).
            covered = any(snip in line for snip in snippets)
            if covered:
                total_allowlisted += 1
                continue
            total_forbidden_outside += 1
            fail(
                f"{doc_rel}:{lineno} — M4 concision-gate forbidden pattern "
                f"{matched_patterns} OUTSIDE the allowlist: "
                f"`{line.strip()[:90]}`. Per BD-196 / ARCHITECTURE-DOC-"
                f"CONCISION-GUARDRAILS.md §6 (M4), durable pack-ops/ rule "
                f"docs are forward-only: dates / SHAs / Commit-N / "
                f"Override-N / post-Commit / temporal 'will' are report-only "
                f"artifacts (C2 surface-separation). Remediation: STRIP the "
                f"pattern from the durable doc (move provenance to the agent "
                f"report). The allowlist is sized to the legitimate KEEP set "
                f"EXACTLY and MUST NOT be widened to admit this hit — a "
                f"residual STRIP-class occurrence is a reshape gap, not an "
                f"allowlist entry."
            )
            any_fail = True

        # Advisory length (soft — never fails).
        n_lines = len(lines)
        if n_lines > advisory_ceiling:
            ok(
                f"{doc_rel} — ADVISORY: {n_lines} lines exceeds the per-doc "
                f"advisory ceiling {advisory_ceiling} (derived from measured "
                f"cleaned content). Advisory only — not a failure; consider "
                f"whether new content belongs in a report/rationale surface."
            )

    if not any_fail:
        ok(
            f"Check 44 — {scanned_docs} durable doc(s) scanned; "
            f"{total_forbidden_outside} forbidden pattern(s) outside the "
            f"allowlist (0 = clean); {total_allowlisted} allowlisted "
            f"operational occurrence(s) admitted (KEEP set)."
        )


# ── Check 47: sanctioned pack-side-shipped freeze (BD-195 C3d) ─────────────
# Freezes the bounded exception that lets `scripts/lib/detect.sh` +
# `scripts/pack-help.sh` ship to clients from their pack-side location.
# Asserts the install map's pack-side subset (non-project-template/,
# non-supporting-docs/ entries from _CLIENT_INSTALLED_FILES) EQUALS
# _SANCTIONED_PACK_SIDE_SHIPPED exactly (set equality — neither superset
# nor subset). Adding a pack-side shipped file to the map WITHOUT editing
# the frozen constant FAILS CI (the lazy `ship a new file from scripts/`
# path is mechanically blocked); a constant entry that left the map also
# FAILS. The membership TEST: a file qualifies ONLY IF (1) a pack operation
# depends on it at runtime AND (2) a client surface requires it shipped —
# default for new shipped files stays project-template/scripts/. See
# ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.2/§8.3.

def check_sanctioned_pack_side_shipped() -> None:
    """Check 47 — sanctioned pack-side-shipped set freeze (BD-195 C3d)."""
    print("\n── Check 47: sanctioned pack-side-shipped freeze (BD-195) ──")
    init_sh = REPO_ROOT / "scripts" / "init-project.sh"
    if not init_sh.is_file():
        ok("scripts/init-project.sh absent — skipping (lenient)")
        return

    entries, start_count, end_count, _, _ = _parse_client_installed_files()
    if start_count != 1 or end_count != 1:
        ok(
            "_CLIENT_INSTALLED_FILES markers not exactly-once — deferring to "
            "Check 41 (skipping set-equality)"
        )
        return

    map_pack_side = {
        e
        for e in entries
        if not e.startswith("project-template/")
        and not e.startswith("supporting-docs/")
    }
    frozen = set(_SANCTIONED_PACK_SIDE_SHIPPED)

    membership_test = (
        "A file qualifies for _SANCTIONED_PACK_SIDE_SHIPPED ONLY IF (1) a pack "
        "operation depends on it at runtime (sourced/invoked by init-project.sh, "
        "add-capability.sh, or the migrator) AND (2) a client surface requires "
        "it shipped. If only (2): default to project-template/scripts/. If only "
        "(1): keep pack-side, unshipped. Growth requires architect + user "
        "authorization citing ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.3."
    )

    if map_pack_side == frozen:
        ok(
            f"install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED "
            f"({len(frozen)} entr(ies)): {sorted(frozen)}"
        )
        return

    unsanctioned = sorted(map_pack_side - frozen)
    missing = sorted(frozen - map_pack_side)
    if unsanctioned:
        fail(
            f"_CLIENT_INSTALLED_FILES ships pack-side file(s) NOT in "
            f"_SANCTIONED_PACK_SIDE_SHIPPED: {unsanctioned}. {membership_test}"
        )
    if missing:
        fail(
            f"_SANCTIONED_PACK_SIDE_SHIPPED entr(ies) absent from the install "
            f"map: {missing}. A sanctioned file must ship (conjunct 2); if it "
            f"no longer ships, remove it from the frozen constant. {membership_test}"
        )


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


# ── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ─────────────────
#
# Structurally enforces "the guard drives the REAL functions, never a copy":
# FAILs CI if a reproduced gz64/base64 codec is (re)introduced INTO
# `validate-pack.py`. The C-4.6 (revert-#2) regression reproduced the
# gzip+base64 codec in Python — an OQ-4 violation a lossy codec change could
# FALSE-PASS, since a second copy can drift from the production
# `_tmf_gz64_encode` / `_tmr_decode_body_blob`. Check 49 instead sub-invokes
# the SHARED BATCH codec; this check makes a re-reproduction un-shippable
# regardless of review attention.
#
# Measure-then-bound (the §3 discipline): the guard's matching logic must run
# clean against validate-pack.py at HEAD AFTER the fix (Check 49 calls the
# shared codec via a `bash -c` seam — there is NO `import gzip`/`base64` doing
# the transform in this file). So the bound is "zero codec-transform tokens in
# this file's Python"; the seam string + this prose are not transform code.
def _check_50_strip_quoted_spans(line: str) -> str:
    """Remove single- and double-quoted spans from a source line, returning the
    UNQUOTED residual (for Check 50's per-occurrence token test).

    A deliberately small, robust quote-span stripper — NOT a full Python
    tokenizer (over-engineering it is out of scope; this is sufficient for the
    exploit class, a reproduced codec line that self-quotes its own token in a
    trailing string/comment). It walks the line char-by-char, dropping any span
    bounded by a matching `'` or `"` (the opening quote selects the closer);
    quote chars escaped with a backslash inside a span do not close it. A
    forbidden token that lives ONLY inside a quoted span (the denylist literals,
    a self-quoting comment copy) is removed; a BARE executable token in the
    code outside any quote survives in the residual and is flagged.
    """
    out = []
    i = 0
    n = len(line)
    quote = None  # the active opening quote char, or None outside a span
    while i < n:
        ch = line[i]
        if quote is None:
            if ch == "'" or ch == '"':
                quote = ch  # enter a quoted span; drop its contents
            else:
                out.append(ch)
        else:
            # Inside a quoted span: an escaped quote does not close it.
            if ch == "\\" and i + 1 < n:
                i += 2
                continue
            if ch == quote:
                quote = None  # span closed; the span chars were dropped
        i += 1
    return "".join(out)


_CHECK_50_FORBIDDEN_CODEC_TOKENS = (
    # A Python-level import of the codec primitives in validate-pack.py would
    # only exist to reproduce the transform — the seam runs the codec in a
    # subprocess (`bash -c`), it does not import gzip/base64 into THIS module.
    "import gzip",
    "import base64",
    "gzip.GzipFile",
    "gzip.compress",
    "gzip.decompress",
    "base64.b64encode",
    "base64.b64decode",
)


def check_validate_pack_no_reproduced_codec() -> None:
    """Check 50 — OQ-4 single-source codec guard (BD-204 §4.5).

    Scans `validate-pack.py`'s OWN Python source for a reproduced gz64/base64
    codec. Any forbidden token OUTSIDE the bash-seam string literal / comments
    FAILs — Check 49 must sub-invoke the shared batch codec, never re-implement
    it (the guard cannot FALSE-PASS a lossy codec change if it shares the one
    production codec).
    """
    print("\n── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ──")
    self_path = Path(__file__).resolve()
    src_lines = self_path.read_text().splitlines()

    # Determine the bash-seam string-literal span so a `gzip`/`base64` token
    # INSIDE the seam (which runs in a subprocess, the single-sourced codec's
    # python3 — NOT a Python reproduction in this module) is not falsely
    # flagged. The seam is the `_CHECK_49_SEAM_SCRIPT = r'''` ... `'''` block.
    seam_start = seam_end = None
    for i, line in enumerate(src_lines):
        if line.startswith("_CHECK_49_SEAM_SCRIPT = r'''"):
            seam_start = i
        elif seam_start is not None and seam_end is None and line.rstrip() == "'''":
            seam_end = i
            break

    hits = []
    for lineno, line in enumerate(src_lines, start=1):
        idx0 = lineno - 1
        # Skip the seam string literal (the legitimate single-sourced codec
        # invocation that runs in a subprocess).
        if seam_start is not None and seam_end is not None and \
                seam_start <= idx0 <= seam_end:
            continue
        # Skip pure-comment lines and the forbidden-token tuple that NAMES the
        # tokens (this guard's own bound declaration) — a `#`-led line or the
        # `_CHECK_50_FORBIDDEN_CODEC_TOKENS` literal is prose/data, not codec
        # transform code.
        stripped = line.lstrip()
        if stripped.startswith("#"):
            continue
        # The token-list literal lines carry the tokens as quoted strings; the
        # span between the tuple open and close is data, not executable codec.
        #
        # Strip every quoted-string span (single- AND double-quoted) from the
        # line FIRST, then test for the BARE token in the UNQUOTED residual.
        # This is per-OCCURRENCE, not per-line: a line that carries BOTH a real
        # bare codec call AND a quoted copy of the same token in a trailing
        # comment/string (e.g. `gzip.compress(buf) # "gzip.compress"`) keeps the
        # executable `gzip.compress(buf)` in the residual and is FLAGGED — the
        # prior per-line `f'"{token}"' in line` escape excused the whole line on
        # the quoted copy alone, letting a self-quoting reproduced codec EVADE
        # the guard (BD-204 C-4.6 review F-1). Legitimate denylist literals
        # (the bare `"gzip.compress"` definitions) have NO unquoted occurrence,
        # so they survive the strip with no residual hit and still PASS.
        residual = _check_50_strip_quoted_spans(line)
        for token in _CHECK_50_FORBIDDEN_CODEC_TOKENS:
            if token in residual:
                hits.append((lineno, token, line.strip()))

    if hits:
        for lineno, token, text in hits:
            fail(
                f"Check 50 — validate-pack.py:{lineno} reproduces the gz64/"
                f"base64 codec (`{token}`): `{text}`. The faithfulness guard "
                f"(Check 49) MUST sub-invoke the SHARED batch codec "
                f"(`_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch`), "
                f"never a copy (OQ-4 — a second codec can drift and FALSE-PASS "
                f"a lossy migration). Remove the reproduced codec; call the "
                f"shared seam."
            )
        return

    ok(
        "Check 50 — no reproduced gz64/base64 codec in validate-pack.py; "
        "Check 49 sub-invokes the shared batch codec (OQ-4 single-source)"
    )


# ── Check 51: BD-214 tracker-deferral flip-block guard ─────────────────────
#
# Anti-regression guard for the BD-214 tracker deferral (design §6.3). Five
# cheap, bounded legs (grep over ≤3 named files or 2 bounded per-entry trees;
# no whole-tree scan, no subprocess-per-entry — satisfies the runtime-
# compounding rule). All FIVE legs are now asserted (legs 1/2/4 landed in C1;
# legs 3 and 5 land in C3 alongside their fix-recipes — the pm-startup ×4
# Step-8 strip completes leg-3's `== 0`, and the install-map removal makes
# leg-5's `tracker.toml.example` absent):
#   leg 1 — the deferral clamp marker is created by C1 (tracker-config.sh);
#   leg 2 — the three verb gates are created by C1 (pack-tracker.sh init +
#           enable-recommendations; tracker-migrate.sh forward arm);
#   leg 3 — `recommendation_should_recommend` occurrences OUTSIDE the
#           allowlist {scripts/lib/recommendation.sh, scripts/tests/,
#           maintenance-docs/} == 0 (the 7 skill files — pack-startup ×3 +
#           pm-startup ×4 — are stripped across C2/C3; the strip COMPLETES
#           at C3, so this leg is added here);
#   leg 4 — entry-content grep-zero is ALREADY true at HEAD (line-anchored
#           patterns; the one BD-204:24 mid-line prose hit is excluded by the
#           `^` anchor — empty allowlist by construction);
#   leg 5 — `tracker.toml.example` is absent from the init-project.sh install
#           map (anti-reintroduction); C3 removes it from the map + the
#           self-doc block in the SAME commit as this leg.
_CHECK_51_CLAMP_FILE = "scripts/lib/tracker-config.sh"
# Leg 3 — recommendation invoker grep. The ONLY surfaces that wire the D-19
# recommendation invocation are the per-CLI session-startup skill/command
# files (design §6.3 / EE-7: pack-startup ×3 + pm-startup ×4). The scan is
# BOUNDED to those skill/command directories — a whole-tree rglob would be a
# runtime-compounding hazard across the battery's ~151 validate-pack
# invocations (feedback-ci-check-runtime-compounding); the dormant lib + its
# tests + historical maintenance-docs (the legitimate carriers) live OUTSIDE
# this bounded surface, so no allowlist is needed within it.
_CHECK_51_RECOMMEND_TOKEN = "recommendation_should_recommend"
# MAINTENANCE GUARD: this tuple is the EXHAUSTIVE set of CLI-surface
# skill/command directories leg 3 scans for live D-19 recommendation
# invokers. The leg is a bounded scan over exactly these dirs (not a
# whole-tree rglob), so any FUTURE CLI surface that can host
# `recommendation_should_recommend` (a new per-CLI skill or command
# directory) MUST be ADDED here — otherwise leg 3 develops a blind spot
# and a re-armed recommendation invoker on the new surface would pass the
# guard undetected. Keep this set in lock-step with the per-CLI startup
# skill/command surface. BD-221 (Antigravity conversion): Antigravity reads
# workspace skills at `.agents/skills/<name>/SKILL.md`, so the Antigravity
# skill dirs (pack-root `.agents/skills` + the client
# `project-template/.agents/skills` install target) are the third legs.
# Non-existent dirs are skipped.
_CHECK_51_RECOMMEND_SKILL_DIRS = (
    ".claude/skills",
    ".codex/skills",
    ".agents/skills",
    "project-template/.claude/skills",
    "project-template/.codex/skills",
    "project-template/skills",
    "project-template/.agents/skills",
)
# Leg 4 line-anchored entry-content artifact patterns (empty allowlist).
_CHECK_51_ENTRY_TREES = ("backlog", "changelog")
_CHECK_51_ENTRY_PATTERNS = (
    re.compile(r"^<!-- pack-entry-body-gz64:"),
    re.compile(r"^<!-- pack-id:"),
)
# Leg 5 — the install-map source token that, if present in init-project.sh,
# would re-ship the deferred `tracker.toml.example` flip material to clients.
_CHECK_51_INSTALL_MAP_FILE = "scripts/init-project.sh"
_CHECK_51_INSTALL_MAP_TOKEN = "tracker.toml.project-example:tracker.toml.example"


def check_tracker_deferral_flip_block() -> None:
    """Check 51 — BD-214 tracker-deferral flip-block guard (legs 1–5).

    leg 1: `tracker-config.sh` carries the BD-214 deferral clamp marker
           (`PACK_TRACKER_DEFERRAL_OVERRIDE` + the dated BD-214 comment).
    leg 2: the three verb gates are present — `pack-tracker.sh` gates
           `cmd_init` + `cmd_enable_recommendations`, and
           `tracker-migrate.sh`'s forward arm refuses.
    leg 3: `recommendation_should_recommend` occurrences OUTSIDE the
           allowlist {scripts/lib/recommendation.sh, scripts/tests/,
           maintenance-docs/} == 0 (no live invoker re-arms the deferred
           D-19 recommendation seam).
    leg 4: line-anchored entry-content artifact grep-zero over the per-entry
           trees (`backlog/` + `changelog/`) == 0 (empty allowlist).
    leg 5: `tracker.toml.example` is absent from the init-project.sh install
           map (the deferred flip material no longer ships to clients).
    """
    print("\n── Check 51: BD-214 tracker-deferral flip-block guard (legs 1-5) ──")
    any_fail = False

    # ── leg 1 — clamp marker in tracker-config.sh ──
    clamp_path = REPO_ROOT / _CHECK_51_CLAMP_FILE
    if not clamp_path.is_file():
        any_fail = True
        fail(f"Check 51 leg 1 — {_CHECK_51_CLAMP_FILE} not found")
    else:
        clamp_text = clamp_path.read_text()
        if "PACK_TRACKER_DEFERRAL_OVERRIDE" not in clamp_text \
                or "BD-214" not in clamp_text:
            any_fail = True
            fail(
                f"Check 51 leg 1 — {_CHECK_51_CLAMP_FILE} is missing the BD-214 "
                f"deferral clamp marker (`PACK_TRACKER_DEFERRAL_OVERRIDE` + a "
                f"`BD-214` dated comment). The clamp must be the first statement "
                f"of `tracker_mode()` forcing flat-file while tracker is deferred."
            )

    # ── leg 2 — the three verb gates ──
    pack_tracker_path = REPO_ROOT / "scripts/pack-tracker.sh"
    tracker_migrate_path = REPO_ROOT / "scripts/tracker-migrate.sh"
    pt_text = pack_tracker_path.read_text() if pack_tracker_path.is_file() else ""
    tm_text = tracker_migrate_path.read_text() if tracker_migrate_path.is_file() else ""

    def _gate_in_function(text: str, func: str) -> bool:
        """True iff the named function body carries the BD-214 deferral gate.

        Accepts EITHER a direct `PACK_TRACKER_DEFERRAL_OVERRIDE` check OR a
        call to the shared `_tracker_deferral_gate` helper (which wraps the
        override seam + typed refusal). Both are valid encodings of the gate.
        """
        marker = f"{func}() {{"
        start = text.find(marker)
        if start == -1:
            return False
        # Function body = from the marker to the next top-level `\n}` (a `}`
        # at column 0). Bounded slice; no whole-file scan beyond this span.
        end = text.find("\n}", start)
        body = text[start:end] if end != -1 else text[start:]
        return ("PACK_TRACKER_DEFERRAL_OVERRIDE" in body
                or "_tracker_deferral_gate" in body)

    if not _gate_in_function(pt_text, "cmd_init"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/pack-tracker.sh `cmd_init` is missing the "
            "BD-214 deferral gate (must refuse `pack tracker init` while tracker "
            "is deferred, unless PACK_TRACKER_DEFERRAL_OVERRIDE=1)."
        )
    if not _gate_in_function(pt_text, "cmd_enable_recommendations"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/pack-tracker.sh "
            "`cmd_enable_recommendations` is missing the BD-214 deferral gate "
            "(must refuse re-arming the D-19 recommendation seam while deferred)."
        )
    if not _gate_in_function(tm_text, "cmd_forward"):
        any_fail = True
        fail(
            "Check 51 leg 2 — scripts/tracker-migrate.sh `cmd_forward` (the "
            "FORWARD arm — the low-level flip path) is missing the BD-214 "
            "deferral gate. The reverse arm stays un-gated (escape hatch)."
        )

    # ── leg 3 — recommendation-invoker grep-zero (bounded to skill dirs) ──
    # Scan ONLY the per-CLI session-startup skill/command directories (the
    # sole surfaces that wire the D-19 invocation). Bounded by construction —
    # no whole-tree scan (runtime-compounding rule). A token hit here is a
    # live invoker re-arming the deferred D-19 seam (BD-214 scope 6).
    leg3_hits = []
    for skill_dir in _CHECK_51_RECOMMEND_SKILL_DIRS:
        base = REPO_ROOT / skill_dir
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            try:
                text = path.read_text()
            except (OSError, UnicodeDecodeError):
                continue
            if _CHECK_51_RECOMMEND_TOKEN in text:
                leg3_hits.append(path.relative_to(REPO_ROOT).as_posix())
    if leg3_hits:
        any_fail = True
        for hit in leg3_hits:
            fail(
                f"Check 51 leg 3 — live `{_CHECK_51_RECOMMEND_TOKEN}` invoker "
                f"in a session-startup skill/command file: {hit}. The D-19 "
                f"tracker opt-in recommendation is deferred (BD-214); no live "
                f"skill surface may re-arm it. Replace the Step-8 body with a "
                f"deferred note (the dormant lib + its tests keep the token)."
            )

    # ── leg 4 — line-anchored entry-content artifact grep-zero ──
    leg4_hits = []
    for tree in _CHECK_51_ENTRY_TREES:
        tree_dir = REPO_ROOT / tree
        if not tree_dir.is_dir():
            continue
        for md in sorted(tree_dir.glob("*.md")):
            try:
                lines = md.read_text().splitlines()
            except OSError:
                continue
            for lineno, line in enumerate(lines, start=1):
                for pat in _CHECK_51_ENTRY_PATTERNS:
                    if pat.match(line):
                        leg4_hits.append(f"{tree}/{md.name}:{lineno}: {line[:60]}")
    if leg4_hits:
        any_fail = True
        for hit in leg4_hits:
            fail(
                f"Check 51 leg 4 — entry-content tracker artifact present "
                f"(line-anchored, empty allowlist): {hit}. Committed entries "
                f"must carry ZERO tracker body/id artifacts while tracker is "
                f"deferred (BD-214 scope 1)."
            )

    # ── leg 5 — tracker.toml.example absent from the install map ──
    install_map_path = REPO_ROOT / _CHECK_51_INSTALL_MAP_FILE
    if not install_map_path.is_file():
        any_fail = True
        fail(f"Check 51 leg 5 — {_CHECK_51_INSTALL_MAP_FILE} not found")
    else:
        install_map_text = install_map_path.read_text()
        if _CHECK_51_INSTALL_MAP_TOKEN in install_map_text:
            any_fail = True
            fail(
                f"Check 51 leg 5 — {_CHECK_51_INSTALL_MAP_FILE} still maps "
                f"`tracker.toml.example` into the client install "
                f"(`{_CHECK_51_INSTALL_MAP_TOKEN}` present). The deferred "
                f"tracker flip material must NOT ship to clients (BD-214 D-C); "
                f"remove the install-map entry, the S11 copy, and the self-doc "
                f"comment line in the same commit (Checks 39/41/46 re-pin)."
            )

    if not any_fail:
        ok(
            "Check 51 — BD-214 flip-block guard: clamp marker present (leg 1), "
            "init + enable-recommendations + forward-arm gates present (leg 2), "
            "no live recommendation invoker in skill files (leg 3), "
            "entry-content artifact grep-zero over backlog/ + changelog/ "
            "(leg 4), tracker.toml.example absent from the install map (leg 5)."
        )


# ── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ────────────
#
# Guard-B (design §13.2 / §4.3 pack): assert SET-EQUALITY between
#   {the PACK-AGENTS roster `Class` cells}  ↔  {the per-agent-file PROSE
#    mandate headers}
# for the 5 pack agents × 3 CLIs.
#
# BINDS TO THE PROSE HEADER, NEVER `tools:` (design §13.2). `pack-reviewer`
# carries `Write, Edit` in its `tools:` yet is RO — keying on `tools:` would
# misclassify it. The discriminator is the mandate header
# (`**Source-write within scope.**` = RW / `**Read-only.**` = RO) and the
# roster `Class` column; the tool list is irrelevant to the class.
#
# Measure-then-bound (ci-guard-design-measure-then-bound): sized to EXACTLY
# the measured 5-agent pack set (1 RW `pack-coder` + 4 RO) — no broader. A
# NEW pack agent or a CLI surface that is not in this measured set MUST be
# ADDED to `_CHECK_52_PACK_AGENTS` / `_CHECK_52_AGENT_DIRS` in lock-step,
# else the guard develops a blind spot.
#
# Runtime (ci-check-runtime-compounding): a SINGLE bounded pass — at most
# 5 agents × 3 CLI dirs = 15 file reads + one roster read; NO whole-tree
# scan, NO subprocess-per-entry. Negligible across the battery's ~191
# validate-pack invocations.
_CHECK_52_ROSTER_FILE = "pack-ops/PACK-AGENTS.md"
# The EXHAUSTIVE measured pack-agent set (design §4.3 / RESEARCH-BD-197-
# AGENT-PERMISSION-INVENTORY §1.1): 1 RW + 4 RO. The roster Class cells are
# read from PACK-AGENTS.md; this tuple only bounds WHICH agents the guard
# inspects (the SSOT for the class VALUE is the roster, not this tuple).
_CHECK_52_PACK_AGENTS = (
    "pack-architect",
    "pack-coder",
    "pack-docs-researcher",
    "pack-planner",
    "pack-reviewer",
)
# The three CLI agent surfaces + the per-CLI file extension. Bounded — adding
# a CLI surface requires extending this map (enumerate-encoding-surfaces).
# BD-221 (Antigravity conversion): the third leg is the Antigravity pack-agents
# plugin bundle (.agents-plugin/pack-agents/agents).
_CHECK_52_AGENT_DIRS = (
    (".claude/agents", "md"),
    (".codex/agents", "toml"),
    (".agents-plugin/pack-agents/agents", "md"),
)
# Prose mandate-header signatures (the class discriminator — NEVER `tools:`).
_CHECK_52_RW_HEADER = "**Source-write within scope.**"
_CHECK_52_RO_HEADER = "**Read-only.**"


def _check_52_roster_classes(roster_text: str) -> dict:
    """Parse the PACK-AGENTS `## Pack agents` roster table; return
    {agent_name: "RW"|"RO"|"<bad>"} from the `Class` column.

    The roster row shape is `| `agent` | Class | Role | Mode |`. We locate
    each measured agent by its backticked name cell and read the SECOND
    pipe-delimited cell (the Class column). Bounded string ops; no regex
    backtracking risk.
    """
    classes = {}
    for line in roster_text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        name_cell = cells[0].strip().strip("`")
        if name_cell in _CHECK_52_PACK_AGENTS:
            classes[name_cell] = cells[1].strip()
    return classes


def _check_52_header_class(text: str):
    """Classify an agent file by its PROSE mandate header. Returns
    "RW" / "RO" / None (no recognized header) — NEVER keys on `tools:`."""
    has_rw = _CHECK_52_RW_HEADER in text
    has_ro = _CHECK_52_RO_HEADER in text
    if has_rw and not has_ro:
        return "RW"
    if has_ro and not has_rw:
        return "RO"
    # Both present, or neither — ambiguous → treat as unclassified so the
    # set-equality leg FAILs loudly (a file must carry exactly one header).
    return None


def check_pack_rw_ro_two_class() -> None:
    """Check 52 — BD-197 pack RW/RO two-class consistency (Guard-B).

    Asserts set-equality between the PACK-AGENTS roster `Class` cells and
    the per-agent-file PROSE mandate headers, for the 5 pack agents × 3
    CLIs. Binds to the prose header, NEVER `tools:` (pack-reviewer carries
    Write/Edit yet is RO). Sized to exactly the measured 5-agent set.
    """
    print("\n── Check 52: BD-197 pack RW/RO two-class consistency (Guard-B) ──")
    any_fail = False

    # ── Read the roster SSOT (the Class column). ──
    roster_path = REPO_ROOT / _CHECK_52_ROSTER_FILE
    if not roster_path.is_file():
        fail(f"Check 52 — roster SSOT {_CHECK_52_ROSTER_FILE} not found")
        return
    roster_classes = _check_52_roster_classes(roster_path.read_text())

    # Every measured agent MUST have a roster Class cell of RW or RO.
    for agent in _CHECK_52_PACK_AGENTS:
        cls = roster_classes.get(agent)
        if cls is None:
            any_fail = True
            fail(
                f"Check 52 — agent `{agent}` has NO `Class` cell in the "
                f"{_CHECK_52_ROSTER_FILE} `## Pack agents` roster. Every "
                f"pack agent MUST carry an RW/RO Class (the pack-side SSOT)."
            )
        elif cls not in ("RW", "RO"):
            any_fail = True
            fail(
                f"Check 52 — agent `{agent}` roster Class is `{cls}` "
                f"(expected exactly `RW` or `RO`) in {_CHECK_52_ROSTER_FILE}."
            )

    # ── Read each agent file's PROSE header; compare to the roster. ──
    for agent in _CHECK_52_PACK_AGENTS:
        roster_cls = roster_classes.get(agent)
        for dir_rel, ext in _CHECK_52_AGENT_DIRS:
            agent_path = REPO_ROOT / dir_rel / f"{agent}.{ext}"
            if not agent_path.is_file():
                any_fail = True
                fail(
                    f"Check 52 — agent file {dir_rel}/{agent}.{ext} not found "
                    f"(the measured pack set is 5 agents × 3 CLIs)."
                )
                continue
            header_cls = _check_52_header_class(agent_path.read_text())
            if header_cls is None:
                any_fail = True
                fail(
                    f"Check 52 — {dir_rel}/{agent}.{ext} carries no single "
                    f"recognized prose mandate header (expected exactly one of "
                    f"`{_CHECK_52_RW_HEADER}` or `{_CHECK_52_RO_HEADER}`)."
                )
                continue
            if roster_cls in ("RW", "RO") and header_cls != roster_cls:
                any_fail = True
                fail(
                    f"Check 52 — class MISMATCH for `{agent}`: roster Class "
                    f"`{roster_cls}` (in {_CHECK_52_ROSTER_FILE}) ≠ prose "
                    f"header `{header_cls}` (in {dir_rel}/{agent}.{ext}). The "
                    f"roster Class column and the per-agent prose mandate "
                    f"header must agree (set-equality; Guard-B binds to the "
                    f"prose header, never `tools:`)."
                )

    if not any_fail:
        ok(
            "Check 52 — pack RW/RO two-class set-equality holds: 5 agents × 3 "
            "CLIs; roster `Class` cells (1 RW `pack-coder` + 4 RO) ↔ per-agent "
            "prose mandate headers (bound to the header, never `tools:`)."
        )


# ── Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A) ───
#
# Guard-A (design §13.1 / §11.5 gate (a)): assert the worktree-isolation
# PROHIBITION PROSE — removed in C2 (the bug-era "Spawn all sub-agents with
# no worktree isolation" / "Do not pass `isolation:"worktree"`" rule) — does
# NOT reappear in any ACTIVE pack surface. This is the anti-regression /
# flip-block guard for the BD-197 un-prohibition.
#
# MATCHER — the PROHIBITION SIGNATURE ONLY (design §13.1, 2nd-adversarial
# G-1/G-2): `no worktree isolation` OR `Do not pass .*isolation.*worktree`.
# NEVER the bare setting-key names `baseRef`/`bgIsolation` — those are
# legitimate post-BD-197 content (the OPTIONAL-FEATURES section + the trinity
# mode-model bullet WRITE them); forbidding them would defeat the gate. The
# signature is the removed PROHIBITION wording, not the feature vocabulary.
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at C5
# commit-time (HEAD 9b7c74c, 2026-06-14): `rg -l --hidden --no-ignore
# 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git'
# -g '!test-fixtures'` returns 25 files — ALL under `maintenance-docs/`
# (9 under `maintenance-docs/archive/`, 16 under
# `maintenance-docs/v11-implementation/`). Categorization:
#   - STRIP set is EMPTY: every active rule surface (CLAUDE.md, root
#     AGENTS/GEMINI, the commit-discipline skill ×3, pack-ops operating
#     docs) returns 0 — C1/C2 stripped the active prohibition prose.
#   - KEEP set = the 25 process/history carriers, which by construction
#     live ONLY in `maintenance-docs/archive/` (retired history) and
#     `maintenance-docs/v11-implementation/` (the BD-196/BD-197 process
#     docs: research/design/plan/IMPL/review docs that QUOTE the
#     prohibition while documenting its removal). These two directories
#     are PROCESS/HISTORY surfaces — agents do not load them as rules — so
#     prohibition prose there is legitimate documentation of the removed
#     rule, not a re-instated active prohibition.
#
# ALLOWLIST = the two non-active process directories (sized to exactly where
# the legitimate carriers live, no broader). This is the measure-then-bound
# answer that is ALSO re-measure-stable: every future BD-197 review/IMPL doc
# lands under `maintenance-docs/v11-implementation/` and is absorbed without
# a static per-file list going stale (a per-file frozen list would be stale
# the moment this very C5 IMPL-REPORT lands). The directory scope is bounded
# to history/process — it does NOT admit any active rule surface.
#
# NARROW self-exception (decision 1; Check-51 self-skip precedent at
# `check_help_fragment_completeness` `entry.name == "validate-pack.py"`):
# because `scripts/` IS in the active scan scope, the validator source
# (this file, which QUOTES the matcher regex literal in the constants below)
# and the single new per-check test SELF-MATCH. So Guard-A:
#   (i)  self-skips the validator itself (`entry.name == "validate-pack.py"`);
#   (ii) allowlists ONLY the single new test file
#        `scripts/tests/test-validate-pack-check-53.sh` (NARROW — NOT the
#        whole `scripts/tests/` dir; that dir holds many unrelated tests and
#        a future test must not be able to smuggle prohibition prose).
#
# RUNTIME (ci-check-runtime-compounding): a SINGLE in-process whole-tree walk
# (`REPO_ROOT.rglob("*")`, the Check-40 precedent), text/markdown files only,
# in-process `re` matching — NO subprocess, NO subprocess-per-entry, NO `rg`
# fork. The active-tree exclusion list (`.git/`, `test-fixtures/`, the two
# allowlisted process dirs) keeps the scanned set small. Negligible across
# the battery's ~202 validate-pack invocations; `run_check` times it and
# WARNs on the 2.0 s per-check budget.
_CHECK_53_PROHIBITION_PATTERNS = (
    re.compile(r"no worktree isolation"),
    re.compile(r"Do not pass .*isolation.*worktree"),
)
# Files Guard-A scans: regular files with these suffixes (rule/prose surfaces).
_CHECK_53_SCAN_SUFFIXES = (".md", ".txt", ".py", ".sh", ".toml")
# ALLOWLIST — directory prefixes whose prohibition-prose hits are LEGITIMATE
# (history + BD-197 process docs). Sized to exactly the measured KEEP set's
# bounding dirs (measure-then-bound; re-measure-stable). Both are process/
# history surfaces, never active rule surfaces.
_CHECK_53_ALLOWLIST_DIR_PREFIXES = (
    "maintenance-docs/archive/",
    "maintenance-docs/v11-implementation/",
)
# ALWAYS-EXCLUDED dirs (not scanned at all): pack-internal git state +
# synthetic fixtures (the latter can carry arbitrary injected strings).
_CHECK_53_EXCLUDE_DIR_PREFIXES = (
    ".git/",
    "test-fixtures/",
    "scripts/tests/fixtures/",
    "node_modules/",
)
# NARROW self-exception (decision 1): the single new per-check test file is
# allowlisted by EXACT path (it QUOTES the matcher regex). NOT the whole
# `scripts/tests/` dir. The validator itself is self-skipped by name below.
_CHECK_53_SELF_TEST_ALLOWLIST = frozenset({
    "scripts/tests/test-validate-pack-check-53.sh",
})
_CHECK_53_SELF_SKIP_NAME = "validate-pack.py"


def _check_53_is_allowlisted(rel_str: str) -> bool:
    """True iff `rel_str` (POSIX relative path) is a legitimate prohibition-
    prose carrier: a process/history doc dir, the single new check-53 test,
    or the self-skipped validator. Bounded prefix/membership tests only."""
    if rel_str == f"scripts/{_CHECK_53_SELF_SKIP_NAME}":
        return True
    if rel_str in _CHECK_53_SELF_TEST_ALLOWLIST:
        return True
    for prefix in _CHECK_53_ALLOWLIST_DIR_PREFIXES:
        if rel_str.startswith(prefix):
            return True
    return False


def check_worktree_isolation_prohibition_flip_block() -> None:
    """Check 53 — BD-197 worktree-isolation prohibition flip-block (Guard-A).

    Asserts the removed worktree-isolation PROHIBITION PROSE
    (`no worktree isolation` / `Do not pass ...isolation...worktree`) does
    NOT reappear in any ACTIVE pack surface. The matcher keys on the
    prohibition SIGNATURE only — NEVER the legitimate setting keys
    `baseRef`/`bgIsolation`. Measure-then-bound allowlist = the two
    process/history directories that carry the legitimate documentation of
    the removed rule, PLUS the narrow self-exception (validator self-skip +
    ONLY the single check-53 test). Single in-process whole-tree walk; no
    subprocess.
    """
    print("\n── Check 53: BD-197 worktree-isolation prohibition flip-block (Guard-A) ──")
    offenders = []
    for path in sorted(REPO_ROOT.rglob("*")):
        # Self-skip the validator by NAME (Check-51 precedent) — it quotes
        # the matcher regex literal and would otherwise self-match.
        if path.name == _CHECK_53_SELF_SKIP_NAME:
            continue
        if not path.is_file():
            continue
        if path.suffix not in _CHECK_53_SCAN_SUFFIXES:
            continue
        try:
            rel = path.relative_to(REPO_ROOT)
        except ValueError:
            continue
        rel_str = str(rel).replace(os.sep, "/")
        # Skip always-excluded dirs (git state, fixtures).
        skip = False
        for excl in _CHECK_53_EXCLUDE_DIR_PREFIXES:
            if rel_str == excl.rstrip("/") or rel_str.startswith(excl):
                skip = True
                break
        if skip:
            continue
        # Skip allowlisted legitimate carriers (process/history docs + the
        # single check-53 test).
        if _check_53_is_allowlisted(rel_str):
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            continue
        for pat in _CHECK_53_PROHIBITION_PATTERNS:
            if pat.search(text):
                offenders.append(rel_str)
                break

    if offenders:
        for off in sorted(offenders):
            fail(
                f"Check 53 (Guard-A) — worktree-isolation PROHIBITION prose "
                f"reappeared in an active pack surface: {off}. BD-197 REMOVED "
                f"the prohibition (`no worktree isolation` / `Do not pass "
                f"isolation:\"worktree\"`); it must not return. If this is a "
                f"legitimate process/history doc, it belongs under "
                f"`maintenance-docs/archive/` or "
                f"`maintenance-docs/v11-implementation/` (the measured KEEP "
                f"dirs); an active rule surface must NOT re-state the removed "
                f"prohibition. The matcher keys on the prohibition signature "
                f"only — never the legitimate `baseRef`/`bgIsolation` keys."
            )
        return

    ok(
        "Check 53 (Guard-A) — worktree-isolation prohibition stays removed: "
        "zero prohibition-prose hits in active surfaces (allowlist = the two "
        "process/history doc dirs + the narrow validator/check-53-test "
        "self-exception; matcher keys on the prohibition signature, never the "
        "`baseRef`/`bgIsolation` setting keys)."
    )


# ── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ────────────
#
# Guard-A′ (design §13.1a / §11.5 gate (b)): the POSITIVE presence-check —
# the INVERSE of Guard-A (Check 53). Guard-A asserts the removed PROHIBITION
# prose does NOT reappear; Guard-A′ asserts the worktree-isolation feature
# STAYS DOCUMENTED on BOTH surfaces — that each OPTIONAL-FEATURES file DOES
# mention the legitimate setting keys + the in-session backstop recipe. This
# keeps the un-prohibited feature from silently vanishing from the docs.
#
# MANDATED 3-TOKEN FORM (user-approved 2026-06-14; BD-197 Note 14; design
# §13.1a / §18.4): assert BOTH `pack-ops/OPTIONAL-FEATURES.md` (authored in
# C5) AND `project-template/docs/pack/OPTIONAL-FEATURES.md` (authored in C8a)
# each mention the THREE tokens — `baseRef` (the REQUIRED base setting key),
# `bgIsolation` (the background-SESSION gate / BD-218 pointer — documented in
# its correct role, NOT as a subagent control), and `permissions.deny` (the
# documented-optional in-session mechanical-backstop recipe token, §18.2(ii)).
# The `permissions.deny`-token assertion was originally framed "optional
# (P3-architect call)" in the design; BD-197 Note 14 SUPERSEDES that — it is
# now a MANDATED C8b deliverable.
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at C8b
# commit-time (HEAD 286b4b1, 2026-06-14): the exact token strings each file
# carries were measured —
#   `grep -c 'baseRef'         pack-ops/OPTIONAL-FEATURES.md            => 10`
#   `grep -c 'bgIsolation'     pack-ops/OPTIONAL-FEATURES.md            =>  6`
#   `grep -c 'permissions\.deny' pack-ops/OPTIONAL-FEATURES.md          =>  4`
#   `grep -c 'baseRef'         project-template/docs/pack/OPTIONAL-FEATURES.md => 10`
#   `grep -c 'bgIsolation'     project-template/docs/pack/OPTIONAL-FEATURES.md =>  6`
#   `grep -c 'permissions\.deny' project-template/docs/pack/OPTIONAL-FEATURES.md => 4`
# All three tokens are present in BOTH files → the guard is GREEN ON ARRIVAL
# (C5 authored the pack tokens, C8a the project tokens). The assertion is
# sized to EXACTLY these 3 tokens × 2 files — no broader. The prose
# per-spawn `isolation` PARAMETER is explicitly NOT folded into the bounded
# check (it is prose, not a settings key — design §13.1a). The third token
# is the EXACT recipe string the docs carry (`permissions.deny`, matched as a
# literal substring with a real dot), NOT a broad pattern.
#
# WHY SUBSTRING (not regex): the three tokens are literal identifiers
# (`baseRef`, `bgIsolation`) and a literal recipe heading (`permissions.deny`,
# whose `.` is a real dot in the file, e.g. the prose ``the `permissions.deny`
# recipe`` and the JSON `"permissions": { "deny": [ ... ] }` block). A plain
# substring test for `permissions.deny` matches the documented recipe heading
# exactly and is sized no broader than the authored token. No setting-key
# token false-matches unrelated prose (they are unique identifiers).
#
# RUNTIME (ci-check-runtime-compounding): exactly TWO single-file reads (one
# per OPTIONAL-FEATURES surface), each followed by three bounded `in` substring
# tests — NO whole-tree walk, NO subprocess, NO subprocess-per-entry. Trivial
# (well under the per-check WARN budget) across the battery's validate-pack
# invocations; `run_check` times it.
_CHECK_54_OPTIONAL_FEATURES_SURFACES = (
    "pack-ops/OPTIONAL-FEATURES.md",
    "project-template/docs/pack/OPTIONAL-FEATURES.md",
)
# The MANDATED 3-token set (design §13.1a / BD-197 Note 14), sized to exactly
# the C5/C8a-authored tokens measured at C8b commit-time (no broader). Matched
# as literal substrings. `permissions.deny` is the in-session backstop recipe
# token (the `.` is a literal dot in the docs); the prose `isolation` param is
# deliberately NOT in this set.
_CHECK_54_REQUIRED_TOKENS = (
    "baseRef",
    "bgIsolation",
    "permissions.deny",
)


def check_optional_features_presence() -> None:
    """Check 54 — BD-197 OPTIONAL-FEATURES presence-check (Guard-A′).

    The POSITIVE inverse of Guard-A (Check 53): asserts BOTH OPTIONAL-FEATURES
    surfaces (`pack-ops/OPTIONAL-FEATURES.md` from C5 +
    `project-template/docs/pack/OPTIONAL-FEATURES.md` from C8a) each mention
    the MANDATED three tokens — `baseRef`, `bgIsolation`, and the
    `permissions.deny` recipe token (user-approved 2026-06-14; BD-197 Note 14;
    design §13.1a / §11.5 gate (b)). Keeps the un-prohibited worktree-isolation
    feature + its in-session backstop recipe DOCUMENTED on both surfaces.
    Measure-then-bound: sized to exactly the 3 authored tokens × 2 files. Two
    single-file reads + bounded substring tests; no subprocess, no whole-tree
    scan.
    """
    print("\n── Check 54: BD-197 OPTIONAL-FEATURES presence-check (Guard-A′) ──")
    any_fail = False
    checked = 0
    for surface in _CHECK_54_OPTIONAL_FEATURES_SURFACES:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 54 (Guard-A′) — OPTIONAL-FEATURES surface {surface} not "
                f"found (the presence-check covers exactly 2 surfaces: pack + "
                f"project)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 54 (Guard-A′) — could not read {surface}.")
            continue
        checked += 1
        missing = [tok for tok in _CHECK_54_REQUIRED_TOKENS if tok not in text]
        if missing:
            any_fail = True
            fail(
                f"Check 54 (Guard-A′) — {surface} is MISSING worktree-isolation "
                f"documentation token(s): {', '.join(missing)}. BOTH "
                f"OPTIONAL-FEATURES surfaces MUST document the worktree "
                f"isolation feature — `baseRef` (required base setting), "
                f"`bgIsolation` (background-session gate / BD-218), and the "
                f"`permissions.deny` in-session backstop recipe (MANDATED per "
                f"BD-197 Note 14). The feature must not silently vanish from "
                f"the docs (design §13.1a, the positive inverse of Guard-A)."
            )

    if not any_fail:
        ok(
            f"Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across "
            f"{checked} surface(s) (pack + project): all "
            f"{len(_CHECK_54_REQUIRED_TOKENS)} mandated tokens "
            f"(`baseRef`, `bgIsolation`, `permissions.deny` recipe) documented "
            f"in each. The un-prohibited worktree-isolation feature + its "
            f"in-session backstop recipe stay documented (BD-197 Note 14)."
        )


# ── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ─────
#
# Guard-C (design §13.3 / §5.4): assert the §5.1 destructive-git-verb DENYLIST
# + the catch-all principle line are ENUMERATED CONSISTENTLY across every
# surface that carries the `agents-never-commit` ban — so no surface silently
# drifts to a stale/short verb list (the C4 verb-folding must stay in parity).
#
# FOLD-vs-STANDALONE (decision 8 / §J3): the plan PREFERS folding verb-parity
# into an existing parity check. Surveyed at C5 commit-time — NO existing check
# fits without over-complication:
#   - Checks 16/18/19 (trinity parity) enforce BYTE parity WITHIN a single
#     trinity location; they neither span the non-trinity surfaces (the
#     commit-discipline skill ×3, pack-coder ×3, PACK-MEMORY-RATIONALE) nor
#     model "verb-SET membership" (their unit is whole-H2-block byte-equality).
#   - Check 45 (rationale↔rule bijection) operates over `[rationale:]` SLUGS,
#     not verb tokens; Check 46 is an ANTI-RESTATE substring scan (the
#     opposite teeth — it forbids verbatim re-statement, it does not assert a
#     shared vocabulary).
#   The 10 surfaces use THREE heterogeneous phrasings (trinity prose; the
#   skill's bulleted `- `git <verb>`` list; the pack-coder per-CLI prose with
#   the Codex `.toml` carrying ONE mid-sentence block). Folding a verb-set
#   membership assertion into any of the above would force that check to grow
#   a second, structurally-different unit — over-complication. So Guard-C is
#   a STANDALONE Check 56 (decision 8 escape hatch).
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at the N-2
# fix (HEAD 9b7c74c, 2026-06-14): all 28 verbs of the FULL §5.1 set asserted
# below + the catch-all principle phrase `including but not limited to` were
# measured present in ALL 10 surfaces (C4 landed the folded enumeration; S-1
# widened the asserted tuple from the 19-verb representative subset toward the
# full §5.1 set by adding `add`/`rm`/`mv`/`config`/`remote`/`gc`/`tag`/
# `notes`; N-2 added the last verb `am`). The asserted CANONICAL set is the
# FULL §5.1 set with NO exceptions, sized to the measured-consistent set.
# `am` is matched word-bounded by `_check_56_verb_present` as
# `(?<![\w-])am(?![\w-])`, which does NOT false-match inside "stream" /
# "command" / "spam" / "amend" (review-2 proved the old "substring-unsafe"
# rationale false; `am` is present-and-consistent across all 10 surfaces and
# asserts cleanly at 28/28). Each verb is matched as `git <verb>` (the
# phrasing all surfaces share) OR the bare token in a context-bounded way via
# word boundaries.
#
# RUNTIME (ci-check-runtime-compounding): 10 single-file reads + bounded
# substring/regex tests; NO subprocess, NO whole-tree scan. Trivial across the
# battery's ~202 validate-pack invocations.
# BD-221 (Antigravity conversion): the third commit-discipline skill mirror is
# `.agents/skills/commit-discipline/SKILL.md` (Antigravity reads workspace
# skills at `.agents/skills/<name>/SKILL.md`) and the third pack-coder agent
# surface is the Antigravity pack-agents plugin bundle
# (`.agents-plugin/pack-agents/agents/pack-coder.md`). The trinity `GEMINI.md`
# FILE stays. The enumeration set is still 10 surfaces.
_CHECK_56_VERB_PARITY_SURFACES = (
    "CLAUDE.md",
    "AGENTS.md",
    "GEMINI.md",
    "pack-ops/PACK-MEMORY-RATIONALE.md",
    ".claude/skills/commit-discipline/SKILL.md",
    ".codex/skills/commit-discipline/SKILL.md",
    ".agents/skills/commit-discipline/SKILL.md",
    ".claude/agents/pack-coder.md",
    ".codex/agents/pack-coder.toml",
    ".agents-plugin/pack-agents/agents/pack-coder.md",
)
# The CANONICAL §5.1 verb set — the FULL §5.1 destructive-git-verb denylist,
# the complete 28-verb set with NO exceptions, measured present in ALL 10
# surfaces (S-1 widened to 27; N-2 added the last verb `am`, HEAD 9b7c74c,
# 2026-06-14). `apply` is INCLUDED (the verb-precise deny; design §5.1 G-4 —
# denied for agents while `git diff` stays allowed). The 8 short/long verbs
# `add`/`rm`/`mv`/`config`/`remote`/`gc`/`tag`/`notes` were added at S-1 and
# `am` at N-2, each after measuring it present-and-consistent across all 10
# surfaces with the actual `_check_56_verb_present` matcher (no false-positive:
# each is genuinely enumerated in every surface's denylist). `am` matches
# word-bounded via `(?<![\w-])am(?![\w-])`, which does NOT false-match inside
# "stream" / "command" / "spam" / "amend" (review-2 disproved the prior
# "substring-unsafe" rationale). Sized to the measured-consistent set, which
# IS the full §5.1 set. Each is matched word-bounded.
_CHECK_56_CANONICAL_VERBS = (
    "commit", "push", "stash", "reset", "restore", "checkout",
    "clean", "merge", "rebase", "cherry-pick", "revert", "apply",
    "switch", "worktree", "update-ref", "update-index", "pull",
    "filter-branch", "replace",
    # S-1 additions (toward full §5.1 set; all measured present-and-consistent):
    "add", "rm", "mv", "config", "remote", "gc", "tag", "notes",
    # N-2 addition (completes the full §5.1 set — 28 verbs, no exceptions):
    "am",
)
# The catch-all principle phrase — the load-bearing closing of the denylist
# (design §5.2). Measured present in all 10 surfaces. BD-221: the phrase is
# matched WHITESPACE-NORMALIZED (runs of whitespace collapsed to one space)
# so a markdown LINE-WRAP between words ("including but not\nlimited to") still
# counts — the Antigravity pack-agents bundle pack-coder.md wraps the phrase
# across a line; a brittle byte-exact substring would miss it.
_CHECK_56_PRINCIPLE_PHRASE = "including but not limited to"


def _check_56_phrase_present(text: str, phrase: str) -> bool:
    """True iff `phrase` appears in `text` modulo whitespace runs (a
    markdown line-wrap inside the phrase still counts). Bounded string ops."""
    norm_text = " ".join(text.split())
    norm_phrase = " ".join(phrase.split())
    return norm_phrase in norm_text


def _check_56_verb_present(text: str, verb: str) -> bool:
    """True iff `verb` appears as a git-verb token in `text`. Word-bounded
    (so `pull` does not match inside `pull-request` etc.); the verb may be
    written as `git <verb>` (trinity/pack-coder prose) or as a bulleted
    `<verb>` token (the commit-discipline skill list)."""
    # `\b<verb>\b` with the verb's hyphen escaped — \b handles the boundary
    # for `cherry-pick`/`filter-branch`/`update-ref` (the `-` is a non-word
    # char so \b sits at the start/end of the whole hyphenated token).
    pat = re.compile(r"(?<![\w-])" + re.escape(verb) + r"(?![\w-])")
    return bool(pat.search(text))


def check_destructive_git_verb_parity() -> None:
    """Check 56 — BD-197 destructive-git-verb enumeration parity (Guard-C).

    Asserts the §5.1 denylist's canonical verb set + the catch-all principle
    phrase appear in every surface that enumerates the `agents-never-commit`
    ban (trinity ×3, PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder
    ×3). Standalone (decision 8 — folding over-complicates). Sized to the
    measured-consistent verb set. 10 single-file reads; no subprocess.
    """
    print("\n── Check 56: BD-197 destructive-git-verb enumeration parity (Guard-C) ──")
    any_fail = False
    checked = 0
    for surface in _CHECK_56_VERB_PARITY_SURFACES:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — verb-parity surface {surface} not found "
                f"(the measured enumeration set is 10 surfaces)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 56 (Guard-C) — could not read {surface}.")
            continue
        checked += 1
        missing_verbs = [
            v for v in _CHECK_56_CANONICAL_VERBS
            if not _check_56_verb_present(text, v)
        ]
        if missing_verbs:
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — {surface} is MISSING destructive git "
                f"verb(s) from the §5.1 denylist: {', '.join(missing_verbs)}. "
                f"Every surface that enumerates the agents-never-commit ban "
                f"MUST carry the full canonical verb set (enumerate-encoding-"
                f"surfaces; the C4 verb-folding must stay in parity)."
            )
        if not _check_56_phrase_present(text, _CHECK_56_PRINCIPLE_PHRASE):
            any_fail = True
            fail(
                f"Check 56 (Guard-C) — {surface} is MISSING the catch-all "
                f"principle phrase `{_CHECK_56_PRINCIPLE_PHRASE}` that closes "
                f"the denylist (design §5.2). The verb list AND the catch-all "
                f"must both appear so an unlisted future verb is still covered."
            )

    if not any_fail:
        ok(
            f"Check 56 (Guard-C) — destructive-git-verb enumeration parity "
            f"holds across {checked} surface(s) (trinity ×3, "
            f"PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder ×3): "
            f"all {len(_CHECK_56_CANONICAL_VERBS)} canonical §5.1 verbs + the "
            f"catch-all principle phrase present in each."
        )


# ── Check 55: BD-197 project RW/RO two-class consistency (Guard-B project) ──
#
# Guard-B PROJECT (design §13.2 / §4.3 project): assert SET-EQUALITY across
# the THREE project legs:
#   {PM-CHAT.md `## Permission profiles` Read-only rows}
#     ↔ {`project-template/agent-run.sh` READONLY_AGENTS array}
#     ↔ {per-agent-file PROSE mandate headers (RO)}
# and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
# agents × 3 CLIs. This is the PROJECT analog of Guard-B(pack) (Check 52,
# C3). It ships in C6b AFTER C6a made the three legs set-consistent, so it
# is GREEN on arrival.
#
# BINDS TO THE PROSE HEADER, NEVER `tools:` (design §13.2). Several RO
# project agents (`reviewer`, `architect`, `auditor`, …) carry
# `Write, Edit` in their Claude `tools:` line yet are RO — keying on
# `tools:` would misclassify them. The Antigravity bundle agent files carry
# NO `tools:` field at all (measured 0/16), so a `tools:`-keyed guard is
# impossible there anyway. The discriminator is the prose mandate header
# (`**Read-only.**` = RO / `**Write-capable (scoped).**` /
# `**Write-capable (script).**` = RW), the PM-CHAT profile table, and the
# `READONLY_AGENTS` runtime array — never the tool list.
#
# Measure-then-bound (ci-guard-design-measure-then-bound): sized to EXACTLY
# the measured 16-agent project set (2 RW `coder`/`repo-ops` + 14 RO) — no
# broader. A NEW project agent or a CLI surface not in this measured set
# MUST be ADDED to `_CHECK_55_PROJECT_AGENTS` / `_CHECK_55_RW_AGENTS` /
# `_CHECK_55_AGENT_DIRS` in lock-step, else the guard develops a blind spot.
#
# Runtime (ci-check-runtime-compounding): a SINGLE bounded pass — at most
# 16 agents × 3 CLI dirs = 48 file reads + one PM-CHAT read + one
# agent-run.sh read; NO whole-tree scan, NO subprocess-per-entry. Negligible
# across the battery's ~200+ validate-pack invocations.
_CHECK_55_PM_CHAT_FILE = "project-template/docs/pack/PM-CHAT.md"
_CHECK_55_AGENT_RUN_FILE = "project-template/agent-run.sh"
# The EXHAUSTIVE measured project-agent set (design §4.3 / RESEARCH-BD-197-
# AGENT-PERMISSION-INVENTORY §1.2): 16 agents = 2 RW + 14 RO.
_CHECK_55_PROJECT_AGENTS = (
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
    "coder",
    "repo-ops",
)
# The measured RW set — exactly two agents (design §4.3 / §13.2 project).
# Everything else in `_CHECK_55_PROJECT_AGENTS` is RO. This tuple is the
# bound the guard asserts the three legs agree on.
_CHECK_55_RW_AGENTS = ("coder", "repo-ops")
# The three CLI agent surfaces + the per-CLI file extension (project-template/).
# Bounded — adding a CLI surface requires extending this map
# (enumerate-encoding-surfaces). BD-221 (Antigravity conversion): the third leg
# is the Antigravity client plugin bundle (.agents-plugin/optiquity-agents/
# agents).
_CHECK_55_AGENT_DIRS = (
    ("project-template/.claude/agents", "md"),
    ("project-template/.codex/agents", "toml"),
    ("project-template/.agents-plugin/optiquity-agents/agents", "md"),
)
# Prose mandate-header signatures (the class discriminator — NEVER `tools:`).
# RW has two flavors on the project side: `coder` is scoped, `repo-ops` is
# script. Either RW header classifies the file RW; the RO header classifies
# it RO.
_CHECK_55_RW_HEADERS = (
    "**Write-capable (scoped).**",
    "**Write-capable (script).**",
)
_CHECK_55_RO_HEADER = "**Read-only.**"


def _check_55_pm_chat_ro_rows(pm_chat_text: str) -> set:
    """Parse the PM-CHAT `## Permission profiles` profile-assignment table;
    return the SET of agent names whose Profile cell is `Read-only`.

    The table row shape is `| `agent` | <Profile> |`. We locate each
    measured agent by its backticked name cell and read the SECOND
    pipe-delimited cell (the Profile). Bounded string ops; no regex
    backtracking risk. A row whose profile starts with `Write-capable`
    is NOT in the RO set.
    """
    ro_rows = set()
    for line in pm_chat_text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        name_cell = cells[0].strip().strip("`")
        if name_cell in _CHECK_55_PROJECT_AGENTS:
            if cells[1].strip() == "Read-only":
                ro_rows.add(name_cell)
    return ro_rows


def _check_55_readonly_agents(agent_run_text: str) -> set:
    """Parse the `READONLY_AGENTS=( ... )` bash array in agent-run.sh; return
    the SET of agent names it lists. Bounded line scan between the opening
    `READONLY_AGENTS=(` and the closing `)`."""
    agents = set()
    in_array = False
    for line in agent_run_text.splitlines():
        stripped = line.strip()
        if not in_array:
            if stripped.startswith("READONLY_AGENTS=("):
                in_array = True
            continue
        if stripped.startswith(")"):
            break
        # Strip inline comments + whitespace; one agent token per line.
        token = stripped.split("#", 1)[0].strip()
        if token:
            agents.add(token)
    return agents


def _check_55_header_class(text: str):
    """Classify an agent file by its PROSE mandate header. Returns
    "RW" / "RO" / None (no recognized header) — NEVER keys on `tools:`."""
    has_rw = any(h in text for h in _CHECK_55_RW_HEADERS)
    has_ro = _CHECK_55_RO_HEADER in text
    if has_rw and not has_ro:
        return "RW"
    if has_ro and not has_rw:
        return "RO"
    # Both present, or neither — ambiguous → treat as unclassified so the
    # set-equality leg FAILs loudly (a file must carry exactly one header).
    return None


def check_project_rw_ro_two_class() -> None:
    """Check 55 — BD-197 project RW/RO two-class consistency (Guard-B project).

    Asserts set-equality across three project legs — the PM-CHAT
    `## Permission profiles` Read-only rows, the `agent-run.sh`
    READONLY_AGENTS array, and the per-agent-file PROSE mandate headers —
    and that the RW set = exactly {`coder`, `repo-ops`}, for the 16 project
    agents × 3 CLIs. Binds to the prose header, NEVER `tools:` (project RO
    agents carry Write/Edit; Antigravity bundle files carry no `tools:`).
    Sized to the measured 16-agent set (2 RW + 14 RO).
    """
    print("\n── Check 55: BD-197 project RW/RO two-class consistency "
          "(Guard-B project) ──")
    any_fail = False

    expected_rw = set(_CHECK_55_RW_AGENTS)
    expected_ro = set(_CHECK_55_PROJECT_AGENTS) - expected_rw

    # ── Leg 1: the PM-CHAT profile-assignment table (the SSOT). ──
    pm_chat_path = REPO_ROOT / _CHECK_55_PM_CHAT_FILE
    if not pm_chat_path.is_file():
        fail(f"Check 55 — PM-CHAT SSOT {_CHECK_55_PM_CHAT_FILE} not found")
        return
    pm_ro = _check_55_pm_chat_ro_rows(pm_chat_path.read_text())

    # ── Leg 2: the agent-run.sh READONLY_AGENTS array. ──
    agent_run_path = REPO_ROOT / _CHECK_55_AGENT_RUN_FILE
    if not agent_run_path.is_file():
        fail(f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} not found")
        return
    run_ro = _check_55_readonly_agents(agent_run_path.read_text())
    # Bound the array RO set to the measured project agents (a stray token
    # would otherwise pollute the set-equality below).
    run_ro_measured = run_ro & set(_CHECK_55_PROJECT_AGENTS)

    # Leg 1 ↔ expected RO.
    if pm_ro != expected_ro:
        any_fail = True
        fail(
            f"Check 55 — PM-CHAT `## Permission profiles` Read-only rows "
            f"{sorted(pm_ro)} ≠ expected RO set {sorted(expected_ro)} "
            f"(measured 14 RO; the RW set is {sorted(expected_rw)}). The "
            f"PM-CHAT profile table is the project RW/RO SSOT — it must list "
            f"exactly the 14 Read-only agents."
        )

    # Leg 2 ↔ expected RO (the runtime projection must match the SSOT).
    if run_ro_measured != expected_ro:
        any_fail = True
        fail(
            f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} READONLY_AGENTS "
            f"{sorted(run_ro_measured)} ≠ expected RO set "
            f"{sorted(expected_ro)}. READONLY_AGENTS is a CI-checked "
            f"projection of the PM-CHAT profile table; the two must agree."
        )
    # Any token in the array that is NOT a known project agent is a defect.
    stray = run_ro - set(_CHECK_55_PROJECT_AGENTS)
    if stray:
        any_fail = True
        fail(
            f"Check 55 — {_CHECK_55_AGENT_RUN_FILE} READONLY_AGENTS lists "
            f"unknown agent(s) {sorted(stray)} not in the measured 16-agent "
            f"project set (enumerate-encoding-surfaces: extend "
            f"_CHECK_55_PROJECT_AGENTS in lock-step)."
        )

    # ── Leg 3: each agent file's PROSE header; compare to expected class. ──
    for agent in _CHECK_55_PROJECT_AGENTS:
        expected_cls = "RW" if agent in expected_rw else "RO"
        for dir_rel, ext in _CHECK_55_AGENT_DIRS:
            agent_path = REPO_ROOT / dir_rel / f"{agent}.{ext}"
            if not agent_path.is_file():
                any_fail = True
                fail(
                    f"Check 55 — agent file {dir_rel}/{agent}.{ext} not found "
                    f"(the measured project set is 16 agents × 3 CLIs)."
                )
                continue
            header_cls = _check_55_header_class(agent_path.read_text())
            if header_cls is None:
                any_fail = True
                fail(
                    f"Check 55 — {dir_rel}/{agent}.{ext} carries no single "
                    f"recognized prose mandate header (expected exactly one of "
                    f"`{_CHECK_55_RO_HEADER}` or one of "
                    f"{list(_CHECK_55_RW_HEADERS)})."
                )
                continue
            if header_cls != expected_cls:
                any_fail = True
                fail(
                    f"Check 55 — class MISMATCH for `{agent}`: expected "
                    f"`{expected_cls}` (PM-CHAT table + READONLY_AGENTS) ≠ "
                    f"prose header `{header_cls}` (in {dir_rel}/{agent}.{ext}). "
                    f"The PM-CHAT profile table, the READONLY_AGENTS array, "
                    f"and the per-agent prose mandate header must agree "
                    f"(set-equality; Guard-B binds to the prose header, never "
                    f"`tools:`)."
                )

    if not any_fail:
        ok(
            "Check 55 — project RW/RO two-class set-equality holds: 16 agents "
            "× 3 CLIs; PM-CHAT `## Permission profiles` Read-only rows (14) ↔ "
            "agent-run.sh READONLY_AGENTS (14) ↔ per-agent prose mandate "
            "headers; RW set = {`coder`, `repo-ops`} (bound to the prose "
            "header, never `tools:`)."
        )


# ── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity ───────
#              (Guard-C project)
#
# Guard-C PROJECT (design §13.3 / §5.4): the project analog of Check 56
# (Guard-C pack). Asserts that the destructive-git-verb DENYLIST is
# ENUMERATED CONSISTENTLY across every PROJECT surface that carries the
# "No destructive operations" / agents-never-commit ban — so the project
# trinity rule, the 48 per-agent Hard rules, and the `agent-run.sh`
# `--disallowedTools` launcher flags cannot silently drift to a stale/short
# verb list. Without this guard, a future edit could drop `git checkout`
# from one project surface (say the launcher) while leaving it in the
# trinity prose, and nothing would catch the divergence. Ships in C7b AFTER
# C7a (3457569) made the project verb enumeration consistent, so it is GREEN
# on arrival.
#
# FOLD-vs-NEW-CHECK (decision 8 / §J3, the C7b coder's call): a NEW
# STANDALONE Check 57 — NOT folded into Check 56 (Guard-C pack). Rationale:
#   - Check 56 is sized to the FULL §5.1 28-verb set across 10 PACK surfaces
#     that all carry the AGENT ABSOLUTE ban (a closed enumeration). The
#     PROJECT surfaces are heterogeneous: the project trinity carries the
#     PM/human "No destructive operations — needs approval" rule (a SUBSET:
#     working-tree/ref mutators only, with the `including but not limited to`
#     catch-all), while the 48 agent files + the launcher carry the agent
#     ban. So the project-consistent verb set is a measured INTERSECTION of
#     8 verbs (below), NOT the 28-verb pack set, and the catch-all principle
#     phrase is TRINITY-ONLY (the agent files use a closed "Forbidden: …"
#     enumeration with no catch-all). Folding two different canonical verb
#     sets + a surface-conditional principle-phrase assertion into Check 56
#     would force it to model two structurally-different surface families —
#     the same over-complication the C5 coder cited for keeping Check 56
#     standalone. A separate, single-responsibility Check 57 is cleaner
#     (decision 8 escape hatch: "author a standalone check ONLY if folding
#     over-complicates").
#   - C7b is therefore PRESENT (not dropped); the plan's "may drop to 11
#     commits if folded" branch does not apply (this guard is standalone).
#
# MEASURE-THEN-BOUND (ci-guard-design-measure-then-bound), live at C7b
# commit-time (HEAD 3457569, 2026-06-14): the asserted CANONICAL set is the
# 8-verb INTERSECTION measured present-and-consistent across ALL 52 project
# surfaces (trinity ×3 + 48 agent files + agent-run.sh) with the
# `_check_57_verb_present` matcher below:
#     checkout, clean, merge, rebase, reset, restore, stash, worktree
# EXCLUDED verbs + WHY (each measured NOT consistent across all 52, so
# asserting it would FALSE-FAIL a legitimately-divergent surface):
#   - `commit`/`push`/`apply`/`tag`: absent from the project TRINITY
#     "No destructive operations" bullet (3/3 trinity files) — that rule is
#     the human/PM needs-approval rule scoped to working-tree/ref mutators;
#     publish/index ops + `git apply` live in the AGENT ban, not the trinity.
#   - `add`: the only trinity hit is "`git worktree` (add/remove/prune)" — a
#     worktree-subcommand description, NOT the `git add` verb; the matcher's
#     ≥4-member slash-run rule correctly rejects that 3-member parenthetical,
#     so `add` measures 49/52 (trinity-absent) and is EXCLUDED.
#   - `rm`/`mv`/`config`/`switch`/`cherry-pick`/`revert`/`am`/etc.: not
#     enumerated consistently across the project families (e.g. `rm` is in
#     the trinity + launcher but not the agent Hard rules; `config` never
#     appears as a project deny verb).
# The 8-verb intersection is the verb-precise project-consistent set: it is
# the set of working-tree/ref mutators that the project trinity rule, the
# agent Hard rules, AND the launcher flags ALL enumerate. `git apply` (the
# verb-precise deny, §5.1 G-4) IS in the agent ban + launcher but NOT the
# trinity, so it is NOT in the consistent intersection — Check 56 (pack)
# already covers `apply` parity; Check 57 covers only the project-consistent
# intersection. Sized to the measured-consistent set, no broader.
#
# PRINCIPLE PHRASE (measure-then-bound, surface-scoped): the catch-all
# `including but not limited to` is asserted ONLY on the 3 trinity surfaces
# (measured present 3/3 there, 0/49 in the agent files + launcher). The
# trinity rule is open-ended (needs-approval, "including but not limited
# to the ones enumerated here"); the agent files carry a CLOSED absolute
# enumeration ("You MAY NOT run X, Y, Z" / "Forbidden: …") with no
# catch-all, and the launcher is a flag array. Asserting the catch-all on
# the agent files / launcher would FALSE-FAIL — so it is bounded to the
# trinity, where it is the load-bearing close of the open denylist.
#
# FORMAT-AGNOSTIC MATCHER (the project format variety the design names):
# the project surfaces enumerate verbs in THREE shapes —
#   (a) `git <verb>` prose (the trinity bullet + the agent Hard rules);
#   (b) `Bash(git <verb>:*)` launcher flags (agent-run.sh) — matched by the
#       same `git <verb>` rule since "Bash(git reset:" contains "git reset";
#   (c) a slash-separated `Forbidden: a/b/c/d` list (the 6 Codex auditor
#       `.toml` files) — matched by a slash-run of ≥4 verb tokens, which
#       distinguishes the deny list from the 3-member `(add/remove/prune)`
#       worktree-subcommand parenthetical.
# Word-boundary safe (so `clean` ≠ "cleanup", `merge` ≠ "merged"); no
# substring false-positive.
#
# RUNTIME (ci-check-runtime-compounding): 52 single-file reads (3 trinity +
# 48 agents + 1 launcher) + bounded regex tests per file; NO subprocess, NO
# whole-tree scan, NO per-entry subprocess storm. Trivial across the
# battery's ~200+ validate-pack invocations (measured wall-time in the C7b
# IMPL-REPORT).
_CHECK_57_TRINITY_SURFACES = (
    "project-template/CLAUDE.md",
    "project-template/AGENTS.md",
    "project-template/GEMINI.md",
)
# The 16 project agents × 3 CLIs (the same exhaustive set Check 55 binds to;
# kept as a local tuple so a NEW project agent or CLI surface must be added
# here in lock-step — enumerate-encoding-surfaces — else the guard develops a
# blind spot). The per-CLI extension differs (.md for Claude + the Antigravity
# bundle, .toml for Codex).
_CHECK_57_PROJECT_AGENTS = (
    "architect", "planner", "reviewer", "tester", "docs-researcher",
    "grpc-schema", "auditor", "auditor-architecture", "auditor-code",
    "auditor-docs", "auditor-ops", "auditor-security", "auditor-tests",
    "auditor-ui", "coder", "repo-ops",
)
# BD-221 (Antigravity conversion): the third leg is the Antigravity client
# plugin bundle (.agents-plugin/optiquity-agents/agents).
_CHECK_57_AGENT_DIRS = (
    ("project-template/.claude/agents", "md"),
    ("project-template/.codex/agents", "toml"),
    ("project-template/.agents-plugin/optiquity-agents/agents", "md"),
)
_CHECK_57_LAUNCHER_SURFACE = "project-template/agent-run.sh"
# The CANONICAL project-consistent verb set — the 8-verb INTERSECTION
# measured present in ALL 52 project surfaces (HEAD 3457569, 2026-06-14).
# These are the working-tree/ref mutators the project trinity rule, the agent
# Hard rules, AND the launcher --disallowedTools ALL enumerate. Sized to the
# measured-consistent set (see the measure-then-bound block above for every
# excluded verb + why).
_CHECK_57_CANONICAL_VERBS = (
    "checkout", "clean", "merge", "rebase",
    "reset", "restore", "stash", "worktree",
)
# The catch-all principle phrase — asserted ONLY on the trinity surfaces
# (the open needs-approval rule); the agent files carry a closed enumeration
# with no catch-all (measure-then-bound, surface-scoped).
_CHECK_57_PRINCIPLE_PHRASE = "including but not limited to"


def _check_57_verb_present(text: str, verb: str) -> bool:
    """True iff `verb` appears as a destructive-git-verb token in `text`,
    format-agnostic across the project surface families:
      (a) `git <verb>` (trinity prose + agent Hard rules) — also matches the
          launcher `Bash(git <verb>:*)` form (it contains `git <verb>`);
      (b) a slash-separated deny list `a/b/c/d` with >=4 members (the Codex
          auditor `Forbidden: …` form).
    Word-bounded so `clean` does not match inside `cleanup`, and the
    >=4-member slash-run rule rejects the 3-member `(add/remove/prune)`
    worktree-subcommand parenthetical (so `add` is not a false positive)."""
    v = re.escape(verb)
    # (a) `git <verb>` form (covers prose + the launcher `Bash(git <verb>:`).
    if re.search(r"git\s+" + v + r"(?![\w-])", text):
        return True
    # (b) slash-separated forbidden list with >=4 slash-joined verb tokens.
    for m in re.finditer(r"(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*", text):
        if verb in m.group(0).split("/"):
            return True
    return False


def check_project_destructive_git_verb_parity() -> None:
    """Check 57 — BD-197 PROJECT destructive-git-verb enumeration parity
    (Guard-C project).

    The project analog of Check 56 (Guard-C pack). Asserts the
    project-consistent canonical verb set (the measured 8-verb intersection)
    appears in every project surface that enumerates the "No destructive
    operations" / agents-never-commit ban — the project trinity ×3, the 48
    per-agent Hard rules (16 agents × 3 CLIs), and the `agent-run.sh`
    `--disallowedTools` launcher flags — and that the catch-all principle
    phrase appears on the trinity (the open needs-approval rule). Standalone
    Check 57 (decision 8 — folding into Check 56 over-complicates: different
    canonical set + a trinity-only catch-all). Format-agnostic matcher
    (`git <verb>` prose / `Bash(git <verb>:*)` launcher / slash-list).
    52 single-file reads; no subprocess.
    """
    print(
        "\n── Check 57: BD-197 PROJECT destructive-git-verb enumeration "
        "parity (Guard-C project) ──"
    )
    any_fail = False
    checked = 0

    # Build the full project surface list: trinity ×3 + 48 agents + launcher.
    surfaces = list(_CHECK_57_TRINITY_SURFACES)
    for dir_rel, ext in _CHECK_57_AGENT_DIRS:
        for agent in _CHECK_57_PROJECT_AGENTS:
            surfaces.append(f"{dir_rel}/{agent}.{ext}")
    surfaces.append(_CHECK_57_LAUNCHER_SURFACE)

    for surface in surfaces:
        path = REPO_ROOT / surface
        if not path.is_file():
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — verb-parity surface {surface} "
                f"not found (the measured enumeration set is "
                f"{len(surfaces)} project surfaces: trinity ×3, 48 agent "
                f"files, agent-run.sh)."
            )
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeDecodeError):
            any_fail = True
            fail(f"Check 57 (Guard-C project) — could not read {surface}.")
            continue
        checked += 1
        missing_verbs = [
            v for v in _CHECK_57_CANONICAL_VERBS
            if not _check_57_verb_present(text, v)
        ]
        if missing_verbs:
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — {surface} is MISSING "
                f"destructive git verb(s) from the project-consistent "
                f"denylist: {', '.join(missing_verbs)}. Every project surface "
                f"that enumerates the No-destructive / agents-never-commit "
                f"ban MUST carry the full canonical verb set "
                f"(enumerate-encoding-surfaces; the project trinity rule, the "
                f"48 agent Hard rules, and the agent-run.sh --disallowedTools "
                f"flags must stay in parity)."
            )
        # The catch-all principle phrase is asserted ONLY on the trinity
        # surfaces (the open needs-approval rule; the agent files + launcher
        # carry a closed enumeration with no catch-all — measure-then-bound).
        if surface in _CHECK_57_TRINITY_SURFACES \
                and _CHECK_57_PRINCIPLE_PHRASE not in text:
            any_fail = True
            fail(
                f"Check 57 (Guard-C project) — trinity surface {surface} is "
                f"MISSING the catch-all principle phrase "
                f"`{_CHECK_57_PRINCIPLE_PHRASE}` that closes the open "
                f"No-destructive denylist. The verb list AND the catch-all "
                f"must both appear in the trinity so an unlisted future verb "
                f"is still covered."
            )

    if not any_fail:
        ok(
            f"Check 57 (Guard-C project) — destructive-git-verb enumeration "
            f"parity holds across {checked} project surface(s) (trinity ×3, "
            f"48 agent Hard rules [16 agents × 3 CLIs], agent-run.sh "
            f"--disallowedTools): all {len(_CHECK_57_CANONICAL_VERBS)} "
            f"canonical project-consistent verbs present in each; the "
            f"catch-all principle phrase present on each trinity surface."
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
