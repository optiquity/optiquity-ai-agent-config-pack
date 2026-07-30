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
      parity (BD-082). The client help skill (renamed pack-help → pm-help
      per BD-257) is now an ordinary pooled skill distributed loose to all
      CLIs; the "references scripts/pm-help.sh" assertion folded into
      Check 1 (SKILL.md frontmatter). The check number is intentionally
      NOT renumbered.
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
# project-template-shape family — Checks 50-57,72-75) now
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

# W6 (BD-256): the facade re-exports Cluster E (the trinity-addenda /
# help-fragment family — Checks 16,22,23) now extracted to
# validate_checks.help_fragments. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references resolve — including the Check-16 named
# lambdas (`check_trinity_addenda_h2`), which late-bind it + `REPO_ROOT` from
# these re-exported globals at invocation (V6 is the late-binding catch). The
# cluster's Check-22/23 helpers (`_VERB_RE`, `_is_pack_internal`) are
# Cluster-E-owned (no >=2-module seam). Single SSOT — the bodies live only in
# help_fragments.py; the facade carries no forked copy.
from validate_checks.help_fragments import *  # noqa: E402,F403  (Cluster E; single SSOT)

# W7 (BD-256): the facade re-exports Cluster F (the per-entry tree sync /
# integrity family — Checks 32,33,34) now extracted to
# validate_checks.per_entry_sync. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references (`check_mirror_in_sync` /
# `check_toc_in_sync` / `check_cross_reference_integrity`) resolve. The cluster
# reads the W1 `STREAMS` core seam there via `from .core` (single SSOT, no
# forked copy); its intra-cluster helpers/constants (`_list_unknown_files`,
# `_CANON_HEADER_RE`, `_RULES_MODE_MARKERS`, `_stream_is_id_shaped`,
# `CROSS_REF_RE`, `_VERSION_POINT_RE`, `_resolves_to_defined_id`,
# `_collect_defined_ids`, `_extract_references`) and `PER_ENTRY_LIB` (Check 33's
# TOC-regenerator path, sole-consumer Cluster F) are Cluster-F-owned (no
# >=2-module seam). Single SSOT — the bodies live only in per_entry_sync.py; the
# facade carries no forked copy.
from validate_checks.per_entry_sync import *  # noqa: E402,F403  (Cluster F; single SSOT)

# W8 (BD-256): the facade re-exports Cluster G (the cross-BD design-governance
# family — Checks 80,81,82) now extracted to validate_checks.cross_bd. Placed
# ABOVE _build_check_registry() so the registry's bare `check_*` references
# (`check_doc_constant_twin_bijection` / `check_open_bd_structured_surface_field`
# / `check_cross_bd_surface_advisory`) resolve. Check 80 resolves its 4 enrolled
# twin constants (`_PACK_CHAT_ONLY_PERMITTED_PATHS`, `_TRACKER_BACKENDS`,
# `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`) BY STRING NAME via
# `module_ns = globals()`; cross_bd imports all 5 (incl. the secondary
# `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`) `from .core`, so they live in cross_bd's
# globals() and the by-name resolution finds them (no KeyError). The
# A1-collapse presentation maps + markers + render fn + the twin registry + the
# Check 81/82 surface-grammar helpers travel there too (Cluster-G-owned). The
# dead-in-source `render_pack_chat_only_doc_section` is in cross_bd's `__all__`
# because test-validate-pack-check-80.sh calls it. Single SSOT — the bodies
# live only in cross_bd.py; the facade carries no forked copy.
from validate_checks.cross_bd import *  # noqa: E402,F403  (Cluster G; single SSOT)

# W9 (BD-256): the facade re-exports Cluster H (the BD-252 session-state
# snapshot family — Checks 77,78,79) now extracted to
# validate_checks.session_state. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references (`check_session_state_struct` /
# `check_session_state_fresh` / `check_session_state_grammar`) resolve. The 3
# checks read the `_session_state_load()` seam + the `_SESSION_STATE_*` schema /
# grammar constants `from .core` (the W1-promoted 8th cross-module seam); the
# Cluster-H-exclusive `_session_state_iter_string_values` helper travels there
# too (Cluster-H-owned, in session_state's `__all__`). Single SSOT — the bodies
# live only in session_state.py; the facade carries no forked copy.
from validate_checks.session_state import *  # noqa: E402,F403  (Cluster H; single SSOT)

# W10 (BD-256): the facade re-exports Cluster I (the per-agent prompt-directory
# family — Checks 6,10) now extracted to validate_checks.prompts. Placed ABOVE
# _build_check_registry() so the registry's bare `check_*` references
# (`check_prompts_directory` / `check_prompt_triad_compliance`) resolve. The 2
# checks read the spine (`REPO_ROOT` / `fail` / `ok`) `from .core`; the
# Cluster-I-exclusive `PROMPTS_DIR` + `REQUIRED_PROMPT_FRONTMATTER` +
# `RESERVED_PROMPT_FRONTMATTER` constants travel there too (Cluster-I-owned, in
# prompts's `__all__` — re-exported here so the facade's public surface stays
# byte-stable). Single SSOT — the bodies + constants live only in prompts.py;
# the facade carries no forked copy.
from validate_checks.prompts import *  # noqa: E402,F403  (Cluster I; single SSOT)

# W11 (BD-256): the facade re-exports Cluster J (the fixture-cohesion family —
# Checks 61,62) now extracted to validate_checks.fixtures. Placed ABOVE
# _build_check_registry() so the registry's bare `check_*` references
# (`check_fixture_dependent_location` / `check_manifest_structural`) resolve. The
# 2 checks read the spine (`REPO_ROOT` / `fail` / `ok`) `from .core`; the
# Cluster-J-exclusive helper `_load_fixture_names` (the build.sh FIXTURE_NAMES
# parser, read by BOTH checks) travels there too (Cluster-J-owned, in fixtures's
# `__all__` — re-exported here so the facade's public surface stays byte-stable).
# Single SSOT — the bodies + helper live only in fixtures.py; the facade carries
# no forked copy.
from validate_checks.fixtures import *  # noqa: E402,F403  (Cluster J; single SSOT)

# BD-256 W12: Cluster K (Checks 63 + 64) bodies + the Cluster-K-exclusive
# `_CHECK_64_*` constants + `_check_64_basename_for` helper moved verbatim to
# validate_checks.examples. Placed ABOVE _build_check_registry() so the registry's
# bare `check_*` references (`check_graphify_out_never_tracked` /
# `check_dangling_example_deliverable_refs`) resolve. The 2 checks read the spine
# (`REPO_ROOT` / `fail` / `ok` / `failures`) `from .core`; the `_CHECK_64_*`
# constants + `_check_64_basename_for` are Cluster-K-internal (read only by
# Check 64), underscore-prefixed, and NOT in examples's `__all__` (the W12 tests
# only `hasattr` the two `check_*`), so `import *` does not re-export them — they
# stay module-private. Single SSOT — the bodies + helpers live only in
# examples.py; the facade carries no forked copy.
from validate_checks.examples import *  # noqa: E402,F403  (Cluster K; single SSOT)

# BD-256 W13: Cluster L (Checks 48 + 49) bodies + the Cluster-L-exclusive
# `_REMOVED_DOC_BASENAMES` / `_REMOVED_DOC_SCAN_DIRS` frozen sets, the
# `_CHECK_49_SEAM_SCRIPT` bash seam, the `_check_49_*` helpers, and the
# `_CHECK_49_DISALLOWED_CONTROL` / `_CHECK_49_TITLE_MAX_CODEPOINTS` /
# `_CHECK_49_ENTRY_HEADER_RE` constants moved verbatim to
# validate_checks.migrator_docs. Placed ABOVE _build_check_registry() so the
# registry's bare `check_removed_doc_advisory` reference (48) AND the Check-49
# named-lambda — `lambda: check_migrator_field_faithfulness(REPO_ROOT / "backlog")`
# with `RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S` — both resolve (the lambda closes
# over this `import *`-bound `check_migrator_field_faithfulness` + the core-seam
# `REPO_ROOT`). The 2 checks read the spine + the `STREAMS` seam (`REPO_ROOT` /
# `STREAMS` / `fail` / `ok` / `warn` / `failures`) `from .core`; the `_REMOVED_DOC_*`
# sets are in migrator_docs's `__all__` (the W13 test reaches/patches them), while
# the `_CHECK_49_*` / `_check_49_*` symbols are Cluster-L-internal (read only by
# Check 49), underscore-prefixed, and NOT in migrator_docs's `__all__`, so
# `import *` does not re-export them — they stay module-private. Single SSOT — the
# bodies + helpers live only in migrator_docs.py; the facade carries no forked copy.
from validate_checks.migrator_docs import *  # noqa: E402,F403  (Cluster L; single SSOT)

# W14 (BD-256): the facade re-exports the 17 isolated single-component checks
# (2,3,4,8,9,11,17,19,20,25,26,42,58,59,60) + the 2 historically-unnumbered
# checks (check_issue_template_forms, check_template_archive_v11) now extracted
# to validate_checks.singletons. Placed ABOVE _build_check_registry() so the
# registry's bare `check_*` references resolve — including Check 19's two
# named-lambda entries (`lambda: check_trinity_no_scaffolding_comments(...)` for
# project-template + pack-root), which late-bind `check_trinity_no_scaffolding_
# comments` from this `import *`-bound global + the core-seam `REPO_ROOT`. The
# singleton-OWNED load-time constants (CODEX_DIR / PACK_SCAN_LOCATIONS /
# INIT_SCRIPT / DETECT_LIB / REQUIRED_DETECT_FUNCTIONS / REQUIRED_BD044_DOCS)
# moved with the bodies; they are module-internal (not in singletons's `__all__`,
# read only by singleton checks) so the facade does not re-export them. The checks
# read the spine + seams (`REPO_ROOT` / `README` / `CHECK_REGISTRY_EXPECTED_COUNT`
# / the promoted `OPTIQUITY_BUNDLE_AGENTS_DIR` / `fail` / `ok` / `failures`)
# `from .core`. Single SSOT — the bodies live only in singletons.py; the facade
# carries no forked copy.
from validate_checks.singletons import *  # noqa: E402,F403  (singletons; single SSOT)

# BD-222: Check 83 (check_wired_test_ci_fragility) lives in its own module
# (validate_checks.wired_test_fragility) per the FIRM own-module-per-new-isolated-
# check convention — it shares no non-core symbol with any cluster. Placed ABOVE
# _build_check_registry() so the registry's bare `check_wired_test_ci_fragility`
# reference resolves at assembly. Single SSOT — the body + leg patterns live only
# in wired_test_fragility.py; the facade carries no forked copy.
from validate_checks.wired_test_fragility import *  # noqa: E402,F403  (BD-222 Check 83; single SSOT)

# BD-224: Checks 86 (check_dashboard_approvals_file_cap) + 87
# (check_session_config_not_committed) + 88
# (check_dashboard_approvals_spec_shell_sync) live in their own module
# (validate_checks.pack_ops_hygiene) per the FIRM own-module-per-new-check
# convention — they share their module-private `_git_ls_files()` helper (Check 88
# also `_git_hash_object()`) with each other and no symbol with any cluster. Placed
# ABOVE _build_check_registry() so the registry's bare `check_*` references resolve
# at assembly. Single SSOT — the bodies + the shared helpers live only in
# pack_ops_hygiene.py; the facade carries no forked copy.
from validate_checks.pack_ops_hygiene import *  # noqa: E402,F403  (BD-224 Checks 86/87/88; single SSOT)

# BD-136: Check 91 (check_trinity_marker_wellformed) lives in its own module
# (validate_checks.trinity_markers) per the FIRM own-module-per-new-isolated-check
# convention (O-6) — its candidate set (the client trinity + token-filtered seed
# marker files) shares no symbol with any cluster, and a dedicated module also
# shrinks the BD-136↔BD-236 singletons.py co-edit surface. Placed ABOVE
# _build_check_registry() so the registry's bare `check_trinity_marker_wellformed`
# reference resolves at assembly. Single SSOT — the V-1..V-8 body lives only in
# trinity_markers.py; the facade carries no forked copy.
from validate_checks.trinity_markers import *  # noqa: E402,F403  (BD-136 Check 91; single SSOT)

# PER_ENTRY_LIB moved to validate_checks.per_entry_sync (BD-256 W7 — Cluster F
# intra-cluster; sole source-consumer is Check 33's TOC-regenerator invocation)
# — re-imported via the facade's `from validate_checks.per_entry_sync import *`
# above. Derived there from the `from .core import REPO_ROOT` binding.
# SKILLS_DIR / CLAUDE_AGENTS_DIR / CODEX_AGENTS_DIR / OPTIQUITY_BUNDLE_AGENTS_DIR /
# REQUIRED_SKILL_FIELDS / PM_CHAT moved to validate_checks.agents_skills (BD-256
# W4 — Cluster C intra-cluster) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above. BD-256 W14:
# `OPTIQUITY_BUNDLE_AGENTS_DIR` was PROMOTED to validate_checks.core (≥2-module
# seam — Checks 5/27 AND singletons's Check 8 via PACK_SCAN_LOCATIONS) and is
# re-exported via the `from validate_checks.core import *` above.
# README moved to validate_checks.core (BD-256 W1 seam) — re-imported via the
# facade's `from validate_checks.core import *` above (derives from REPO_ROOT).

# PROMPTS_DIR / REQUIRED_PROMPT_FRONTMATTER / RESERVED_PROMPT_FRONTMATTER moved
# to validate_checks.prompts (BD-256 W10 — Cluster I intra-cluster) — re-imported
# via the facade's `from validate_checks.prompts import *` above (single SSOT, no
# forked copy). Read only by Checks 6 and 10.

# CODEX_DIR (Check 2) / PACK_SCAN_LOCATIONS (Check 8) / INIT_SCRIPT / DETECT_LIB /
# REQUIRED_DETECT_FUNCTIONS / REQUIRED_BD044_DOCS (Check 9) moved to
# validate_checks.singletons (BD-256 W14 — singleton-OWNED load-time constants,
# read only by singleton checks) — re-imported via the facade's `from
# validate_checks.singletons import *` above only if listed in singletons's
# `__all__`; they are NOT (module-internal), so the facade no longer carries
# them and no test reaches them on the facade surface. Single SSOT — the
# constants live only in singletons.py; the facade carries no forked copy.

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


# ── Checks 2 (check_codex_toml) + 3 (check_td_tbd_sentinels) + 4
# (check_readme_version) moved to validate_checks.singletons (BD-256 W14 —
# isolated single-component checks) — re-imported via the facade's `from
# validate_checks.singletons import *` above (single SSOT, no forked copy). The
# singleton-OWNED `CODEX_DIR` constant (Check 2) moved with them; Check 4 reads
# the `README` W1 core seam `from .core`. ──


# ── Check 5 (check_agent_count) moved to validate_checks.agents_skills
# (BD-256 W4 — Cluster C) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above (single SSOT, no forked copy). ──


# ── Check 6 (check_prompts_directory) moved to validate_checks.prompts
# (BD-256 W10 — Cluster I) — re-imported via the facade's `from
# validate_checks.prompts import *` above (single SSOT, no forked copy). The
# Cluster-I-exclusive `PROMPTS_DIR` / `REQUIRED_PROMPT_FRONTMATTER` /
# `RESERVED_PROMPT_FRONTMATTER` constants moved with it. ──


# ── Check 7 (check_pack_agent_roster) moved to validate_checks.agents_skills
# (BD-256 W4 — Cluster C) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above (single SSOT, no forked copy). ──


# ── Checks 8 (check_reserved_x_prefix) + 9 (check_init_project_structure) moved
# to validate_checks.singletons (BD-256 W14 — isolated single-component checks) —
# re-imported via the facade's `from validate_checks.singletons import *` above
# (single SSOT, no forked copy). The singleton-OWNED load-time constants moved
# with them: `PACK_SCAN_LOCATIONS` (Check 8) + `INIT_SCRIPT` / `DETECT_LIB` /
# `REQUIRED_DETECT_FUNCTIONS` / `REQUIRED_BD044_DOCS` (Check 9). `PACK_SCAN_LOCATIONS`
# reads the W14-PROMOTED core seam `OPTIQUITY_BUNDLE_AGENTS_DIR` `from .core`. ──


# ── Check 10 (check_prompt_triad_compliance) moved to validate_checks.prompts
# (BD-256 W10 — Cluster I) — re-imported via the facade's `from
# validate_checks.prompts import *` above (single SSOT, no forked copy). Reads
# the same Cluster-I-exclusive `PROMPTS_DIR` constant as Check 6. ──


# ── Check 11 (check_pack_agent_trinity) + Check 17
# (check_tool_config_capability_parity), with the interstitial Checks 12-15
# RETIRED breadcrumb (BD-121, v9 sunset — the four v9-migrator-coupled checks
# whose coverage moved to Checks 25/26), moved to validate_checks.singletons
# (BD-256 W14 — isolated single-component checks) — re-imported via the facade's
# `from validate_checks.singletons import *` above (single SSOT, no forked copy).
# Both read the spine `from .core`; Check 11/17 use `sys.executable`/`tomllib`
# (stdlib imported at singletons module top). The 12-15 retirement context
# travels with the bodies to preserve intra-module order. ──


# ── The 2 historically-unnumbered checks check_issue_template_forms (BD-063
# issue forms) + check_template_archive_v11 (BD-064 archive integrity,
# informational) — both `number=None` in the registry, label-selectable only —
# moved to validate_checks.singletons (BD-256 W14) — re-imported via the facade's
# `from validate_checks.singletons import *` above (single SSOT, no forked copy).
# They read the spine `from .core`; check_issue_template_forms keeps its
# body-local `import yaml`. ──


# ── Check 20 (check_gitignore_env_example_exception) + Check 19
# (check_trinity_no_scaffolding_comments) moved to validate_checks.singletons
# (BD-256 W14 — isolated single-component checks) — re-imported via the facade's
# `from validate_checks.singletons import *` above (single SSOT, no forked copy).
# Both read the spine `from .core`. Check 19 has TWO named-lambda registry
# entries (project-template + pack-root surfaces, both under number 19); the
# lambdas late-bind `check_trinity_no_scaffolding_comments` from this `import *`-
# bound global + the core-seam `REPO_ROOT`. ──


# ── Checks 18 (check_trinity_h2_parity) + 27 (check_agent_canonical_phrases),
# their profile rosters (READ_ONLY_AGENTS / WRITE_SCOPED_AGENTS /
# WRITE_SCRIPT_AGENTS / COMMON_CANONICAL_PHRASES / PROFILE_PHRASES) + the
# _agent_profile / _extract_skills_to_load_section helpers moved to
# validate_checks.agents_skills (BD-256 W4 — Cluster C) — re-imported via the
# facade's `from validate_checks.agents_skills import *` above. The Check-18
# named-lambda registry entries late-bind `check_trinity_h2_parity` from those
# re-exported globals (single SSOT, no forked copy). ──


# ── Cluster E (Checks 16,22,23 + `_CHECK_16_EXEMPT_SURFACES` / `_VERB_RE` /
# `_PACK_INTERNAL_RE` / `_is_pack_internal`; the trinity-addenda + help-fragment
# family) now extracted to validate_checks.help_fragments (BD-256 W6) —
# re-imported via the facade's `from validate_checks.help_fragments import *`
# above. The Check-16 named-lambda registry entries below late-bind
# `check_trinity_addenda_h2` from those re-exported globals (single SSOT, no
# forked copy). The `# Check 21 RETIRED` interstitial breadcrumb moved with the
# block to help_fragments.py to preserve intra-module order. ──


# ── Check 25 (check_customization_detection_regression_guard) + Check 26
# (check_migrator_framework_inventory), with the interstitial Check 24 RETIRED
# breadcrumb (BD-194 Candidate 6), moved to validate_checks.singletons (BD-256
# W14 — isolated single-component checks) — re-imported via the facade's `from
# validate_checks.singletons import *` above (single SSOT, no forked copy). Both
# read the spine `from .core`; Check 25 keeps its body-local `import shutil` /
# `import tempfile`. The Check 24 retirement context travels with the bodies to
# preserve intra-module order. ──


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


# ── Cluster F (Checks 32′,33,34 + `_list_unknown_files` / `_CANON_HEADER_RE` /
# `_RULES_MODE_MARKERS` / `_stream_is_id_shaped` / `CROSS_REF_RE` /
# `_VERSION_POINT_RE` / `_resolves_to_defined_id` / `_collect_defined_ids` /
# `_extract_references` / `PER_ENTRY_LIB`; the per-entry tree sync / integrity
# family) now extracted to validate_checks.per_entry_sync (BD-256 W7) —
# re-imported via the facade's `from validate_checks.per_entry_sync import *`
# above. The cluster reads the `STREAMS` W1 core seam there via `from .core`
# (single SSOT, no forked copy). The Check 32′ inverted-guard preamble moved
# with the block to per_entry_sync.py to preserve intra-module order. ──

# ── Cluster G (Checks 80,81,82 + the A1-collapse presentation maps /
# markers / `render_pack_chat_only_doc_section` + the `_DOC_CONSTANT_TWINS`
# twin registry + count + `_doc_constant_twin_*` extractors + the Check 81/82
# surface grammar (`_CHECK_81_OPEN_BD_STATES` / `_CHECK_81_TBD_MARKERS` /
# `_CHECK_81_PATH_TOKEN_RE`) + `_check_81_*` helpers; the cross-BD
# design-governance family) now extracted to validate_checks.cross_bd (BD-256
# W8) — re-imported via the facade's `from validate_checks.cross_bd import *`
# above. The 4 enrolled twin constants (`_PACK_CHAT_ONLY_PERMITTED_PATHS`,
# `_TRACKER_BACKENDS`, `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`)
# + the secondary `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` stay in core (BD-256 W1
# seams); cross_bd imports them `from .core` so Check 80's by-name
# `module_ns = globals()` resolution finds them (single SSOT, no forked copy).
# `_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES` are ALSO read by Check 36's
# `_is_pack_chat_only_permitted` in boundary_refs (the W1 seam's other
# consumer). ──


# ── BD-252 session-state snapshot — Checks 77/78/79 ────────────────────────
# Checks 77/78/79 (struct/fresh/grammar) moved to validate_checks.session_state
# (BD-256 W9) — re-imported via the facade's `from validate_checks.session_state
# import *` above. Their shared `_SESSION_STATE_*` constants +
# `_session_state_load()` are the W1 core seam (in validate_checks.core,
# re-imported via `from validate_checks.core import *`), read by session_state's
# bodies here AND by Check 81's active-BD trigger in validate_checks.cross_bd.
# The committed, CLI-agnostic resumable session-state snapshot
# (`pack-ops/session-state.json`) schema + grammar detectors live in core.py.


# ── Check 42 (check_ci_workflow_wires_per_check_tests) moved to
# validate_checks.singletons (BD-256 W14 — isolated single-component check) —
# re-imported via the facade's `from validate_checks.singletons import *` above
# (single SSOT, no forked copy). The full BD-184/BD-219 history + re-scoped-charge
# comment block travels with the body to singletons.py to preserve intra-module
# order. Check 42 reads the spine `from .core`. ──


# ── Checks 61 (check_fixture_dependent_location) + 62 (check_manifest_structural)
# moved to validate_checks.fixtures (BD-256 W11 — Cluster J) — re-imported via
# the facade's `from validate_checks.fixtures import *` above (single SSOT, no
# forked copy). The Cluster-J-exclusive `_load_fixture_names` helper (the
# build.sh FIXTURE_NAMES parser, read by BOTH checks) moved with them. ──


# ── Checks 63 (check_graphify_out_never_tracked) + 64
# (check_dangling_example_deliverable_refs) moved to validate_checks.examples
# (BD-256 W12 — Cluster K) — re-imported via the facade's
# `from validate_checks.examples import *` above (single SSOT, no forked copy).
# The Cluster-K-exclusive `_CHECK_64_*` constants + `_check_64_basename_for`
# helper (read only by Check 64) moved with them; they are module-private (not in
# examples's `__all__`), so the facade does not re-export them. ──


# ── Checks 58 (check_validate_job_carries_no_only_check) + 59
# (check_check_registry_completeness) + 60 (check_ci_shard_coverage) moved to
# validate_checks.singletons (BD-256 W14 — isolated single-component checks) —
# re-imported via the facade's `from validate_checks.singletons import *` above
# (single SSOT, no forked copy). Check 59 calls `_build_check_registry()`, which
# STAYS in this facade (its lambdas close over the facade's `import *`-bound
# check_*/REPO_ROOT; it moves to the facade's final home at W15) — to avoid a
# circular import (the facade imports singletons above its own
# `_build_check_registry` def), the facade INJECTS the assembler into the
# singletons module immediately after defining it (see the injection line right
# below `_build_check_registry()` further down); Check 59's body resolves it
# from its module global at call time. Checks 59/60 read
# `CHECK_REGISTRY_EXPECTED_COUNT` (Check 59) + the spine `from .core`. ──


# Cluster L (BD-195 C6 / BD-204 §4.2/§4.6 — Checks 48 + 49: removed-doc advisory
# + migrator field/body faithfulness) moved to validate_checks.migrator_docs
# (BD-256 W13) — re-imported via the facade's `from validate_checks.migrator_docs
# import *` above (placed before _build_check_registry()). The Cluster-L-exclusive
# `_REMOVED_DOC_*` sets, the `_CHECK_49_SEAM_SCRIPT` bash seam, the `_check_49_*`
# helpers, and the `_CHECK_49_*` constants travel with the bodies. Check 49's
# registry entry is a named lambda — `lambda: check_migrator_field_faithfulness(
# REPO_ROOT / "backlog")` with `RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S` — which
# closes over the re-imported `check_migrator_field_faithfulness` + the core-seam
# `REPO_ROOT`. Single SSOT — no forked copy here.


# Cluster H (BD-252 session-state — Checks 77/78/79: struct/fresh/grammar) moved
# to validate_checks.session_state (BD-256 W9) — re-imported via the facade's
# `from validate_checks.session_state import *` above. The intra-cluster helper
# `_session_state_iter_string_values` travels with the bodies. Single SSOT — no
# forked copy here.


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
        # ── Check 21 RETIRED in BD-221 (Antigravity conversion): the client
        # help skill (pack-help → pm-help per BD-257) is a pooled skill; the
        # script-ref assertion (references scripts/pm-help.sh) folded into
        # Check 1. ──
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
        # ── BD-195 (C3d) / BD-257: sanctioned pack-side-shipped freeze —
        # EMPTY invariant. Lands LAST — it freezes _SANCTIONED_PACK_SIDE_SHIPPED
        # to EXACTLY the empty set () (no pack-side file ships to clients per the
        # no-dual-use rule / dependency-direction-placement conjunct (c)),
        # code-enforces that empty floor, and scans BOTH client-install paths
        # (init-project.sh's _CLIENT_INSTALLED_FILES via
        # _parse_client_installed_files() — shared with Checks 41/43 — AND
        # migrate-v10-to-v11.sh's copy vectors), so it sits after the inventory +
        # walk gates. Per ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md §8.2 (the
        # freeze anti-pattern, now frozen-empty; §8.3's admission path is
        # SUPERSEDED by BD-257 — growth forbidden).
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
        # surface. Cheap: a line scan
        # + regex per small entry + an in-memory map; no subprocess, no tree
        # walk.
        (82, "check_cross_bd_surface_advisory", check_cross_bd_surface_advisory, W),
        # Check 83 — wired-test CI-environment fragility guard (BD-222): the
        # standing anti-drift guard that took BD-219's first sharded CI run red.
        # Statically scans the CI-WIRED test set (raw three-glob −
        # ci-test-wiring-allowlist.txt, a Check-42 mirror) for three
        # CI-environment-fragile bug classes — (a) hardcoded dev/home paths,
        # (b) direct un-shimmed live-`gh` calls, (c) the `grep -c … || echo 0`
        # double-zero idiom — so the class is caught at validate-pack/PR time,
        # before push. Cheap: three dir globs + one allowlist parse + a read-once
        # regex pass over the small wired set; no subprocess.
        (83, "check_wired_test_ci_fragility", check_wired_test_ci_fragility, W),
        # Check 84 — project groupings contract schema specifics (BD-189):
        # the Check-74 analog for the groupings stream. Asserts the shipped
        # groupings `_rules.md` `## Entry schema` SPECIFICS (entry-type /
        # core-fields / kind-enum 10 unique lowercase-kebab slugs incl.
        # `unassigned` / exception-field / member-ref-pattern phase-N /
        # min-members 2 / field-order / reserved-id GRP-000) PLUS the
        # schema↔lib cross-agreement line (groupings-lib.sh RESERVED_ID
        # carries the schema-declared reserved ID; missing lib/line FAILs —
        # absence-of-backing) + a synthetic self-check that the matcher
        # bites. Two small file reads; self-check in-memory; no subprocess.
        (84, "check_project_groupings_contract",
              check_project_groupings_contract, W),
        # Check 85 — narration-twin regex-CONTENT parity guard (BD-271): a
        # NARROW DATA-parity check (source bytes + INTEGER-value flags,
        # load-bearing) between the two session-state narration-pattern
        # twins — `_SESSION_STATE_NARRATION_PATTERNS` (core.py, pack) and
        # `_SS_NARRATION_PATTERNS` (validate-docs.sh, client-shipped,
        # READ-ONLY input). AST-extracts both twins as TEXT, folds the
        # sanctioned bd<->td audience vocabulary (bounded to the measured
        # 2-axis set), and asserts count/duplicate/fold-reach/directionality
        # + a bidirectional (source, flags) compare. Complements Check 70's
        # STRUCTURAL client-gate parity (see DESIGN-BD-243-CLIENT-GATE.md
        # §C.3 addendum) — neither compares whole-gate behavior. Cheap:
        # reads exactly two named files; no subprocess, no tree walk.
        (85, "check_narration_twin_content_parity",
              check_narration_twin_content_parity, W),
        # ── BD-224 (C6): /pack-dashboard runtime-surface git-hygiene guards.
        # Check 86 caps the git-TRACKED pack-ops/dashboard-approvals/ set at
        # EXACTLY {dashboard.html, dashboard-url.txt, dashboard-shell.html}
        # (all-three-or-none first-commit atomicity — design §11.2 Check A /
        # F12). Check 87 asserts the
        # per-clone runtime pack-ops/session-config.json is never git-tracked
        # (design §11.2 Check B); Check 88 asserts the tracked render shell's
        # embedded spec-sha matches git hash-object of DASHBOARD-SPEC-PACK.md
        # (render-cache sync-guard; architecture §9). The three live in their own
        # module (validate_checks.pack_ops_hygiene) per the FIRM
        # own-module-per-new-check convention — they share their module-private
        # `_git_ls_files()` helper (Check 88 also `_git_hash_object()`) with each
        # other and no cluster symbol, and stay OUT of boundary_refs.py
        # (PLAN-BD224.md R7). All git-TRACKED-enumerated (git ls-files), O(one dir)
        # / O(1), SKIP-lenient off a work tree / absent surface. Land at the
        # registry tail alongside the adjacent CI-infra + git-hygiene guards
        # (63/83/84/85). Numbers 86/87/88 are the next contiguous integers after
        # the highest wired check (85).
        (86, "check_dashboard_approvals_file_cap",
              check_dashboard_approvals_file_cap, W),
        (87, "check_session_config_not_committed",
              check_session_config_not_committed, W),
        (88, "check_dashboard_approvals_spec_shell_sync",
              check_dashboard_approvals_spec_shell_sync, W),
        # Check 89 — HELP-FRAGMENT /pack-* command ↔ backing-skill parity
        # (BD-224): bidirectional gate — every advertised `/pack-<name>` slash
        # row in pack-ops/HELP-FRAGMENT-PACK.md is backed by a git-TRACKED
        # pack-<name>/SKILL.md in all three CLI roots, and every pack-*-named
        # command skill is advertised. Lives in the help-fragment-family module
        # (validate_checks.help_fragments) alongside Checks 16/22/23; shares the
        # promoted `_HELP_FRAGMENT_PACK` path constant with 22/23. git-TRACKED
        # enumeration (git ls-files, 3 roots), O(rows), SKIP-lenient off a work
        # tree. Number 89 is the next free integer (highest wired was 88).
        (89, "check_help_fragment_command_skill_parity",
              check_help_fragment_command_skill_parity, W),
        # Check 90 — CLIENT HELP-FRAGMENT /pm-* command ↔ backing-skill parity
        # (BD-257): the client analog of Check 89 — every advertised `/pm-<name>`
        # slash row in project-template/docs/pack/HELP-FRAGMENT.md is backed by a
        # git-TRACKED project-template/skills/pm-<name>/SKILL.md, and every
        # git-TRACKED pm-*-named command skill is advertised. SINGLE template
        # root (client skills live in ONE tree, unlike the pack's 3 CLI roots).
        # Lives in the help-fragment-family module (validate_checks.help_fragments)
        # alongside Checks 16/22/23/89; reuses the module's _git_ls_files_multi
        # helper. git-TRACKED enumeration (git ls-files, one pathspec), O(rows),
        # SKIP-lenient off a work tree. Number 90 is the next free integer
        # (highest wired was 89).
        (90, "check_help_fragment_command_skill_parity_client",
              check_help_fragment_command_skill_parity_client, W),
        # ── Check 91 — CLIENT trinity marker-section well-formedness (BD-136
        # V-1..V-8). LOUD DEVIATION — REGISTERED EXACTLY ONCE (project-template
        # only). This INTENTIONALLY BREAKS the 16/18/19 double-register pattern
        # (each of those registers TWICE — [project-template] + [pack-root]).
        # Check 91 does NOT get a [pack-root] tuple: pack-root trinity ships
        # ZERO markers / ZERO `## Project addenda` H2 / ZERO `[CONDITIONAL]`
        # (EEB-RC1b), so V-4/V-7 would FALSE-FAIL there and a pack-root leg would
        # otherwise be a pure no-op. Consequence: ONE new registry entry, so
        # CHECK_REGISTRY_EXPECTED_COUNT goes 87 → 88 (NOT 89) — see the matching
        # loud note at the constant in core.py. A second [pack-root] tuple here
        # would land the count at 89 and RED the Check 59 count-gate. Number 91
        # is the next free integer (highest wired was 90). git-TRACKED candidate
        # enumeration (git ls-files), O(lines), SKIP-lenient off a work tree.
        (91, "check_trinity_marker_wellformed[project-template]",
              lambda: check_trinity_marker_wellformed(REPO_ROOT / "project-template", "project-template"), W),
    ]


# ── BD-256 W14: Check 59 _build_check_registry injection (the circular-import
# resolution) ───────────────────────────────────────────────────────────────
# Check 59 (`check_check_registry_completeness`) moved to
# validate_checks.singletons (W14) but calls `_build_check_registry()`, which
# MUST stay in this facade (its lambdas close over the facade's `import *`-bound
# `check_*` + `REPO_ROOT`; it lands in the facade's final home at W15). A
# top-level `from <facade> import _build_check_registry` in singletons.py would
# be CIRCULAR — the facade imports singletons ABOVE this `_build_check_registry`
# definition. Resolution: INJECT the assembler into the already-loaded singletons
# module right after defining it. singletons.py declares a `_build_check_registry
# = None` deferred-resolution seam at module scope; this line overwrites it with
# the real callable, so Check 59's body (a verbatim bare `_build_check_registry()`
# call) resolves from its own module global at CALL time. Both `--only-check 59`
# and the no-flag full run go through this facade's `main()` (which has run this
# injection at import), so the assembler is always resolved. At W15 the facade
# stays the SSOT for the builder and this injection contract is unchanged.
validate_checks.singletons._build_check_registry = _build_check_registry


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
