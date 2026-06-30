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

# PER_ENTRY_LIB moved to validate_checks.per_entry_sync (BD-256 W7 — Cluster F
# intra-cluster; sole source-consumer is Check 33's TOC-regenerator invocation)
# — re-imported via the facade's `from validate_checks.per_entry_sync import *`
# above. Derived there from the `from .core import REPO_ROOT` binding.
CODEX_DIR = REPO_ROOT / "project-template" / ".codex"
# SKILLS_DIR / CLAUDE_AGENTS_DIR / CODEX_AGENTS_DIR / OPTIQUITY_BUNDLE_AGENTS_DIR /
# REQUIRED_SKILL_FIELDS / PM_CHAT moved to validate_checks.agents_skills (BD-256
# W4 — Cluster C intra-cluster) — re-imported via the facade's `from
# validate_checks.agents_skills import *` above. The bare `OPTIQUITY_BUNDLE_AGENTS_DIR`
# reference in the load-time `PACK_SCAN_LOCATIONS` list below resolves from that
# re-import (placed above this point).
# README moved to validate_checks.core (BD-256 W1 seam) — re-imported via the
# facade's `from validate_checks.core import *` above (derives from REPO_ROOT).

# PROMPTS_DIR / REQUIRED_PROMPT_FRONTMATTER / RESERVED_PROMPT_FRONTMATTER moved
# to validate_checks.prompts (BD-256 W10 — Cluster I intra-cluster) — re-imported
# via the facade's `from validate_checks.prompts import *` above (single SSOT, no
# forked copy). Read only by Checks 6 and 10.

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


# ── Check 6 (check_prompts_directory) moved to validate_checks.prompts
# (BD-256 W10 — Cluster I) — re-imported via the facade's `from
# validate_checks.prompts import *` above (single SSOT, no forked copy). The
# Cluster-I-exclusive `PROMPTS_DIR` / `REQUIRED_PROMPT_FRONTMATTER` /
# `RESERVED_PROMPT_FRONTMATTER` constants moved with it. ──


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


# ── Check 10 (check_prompt_triad_compliance) moved to validate_checks.prompts
# (BD-256 W10 — Cluster I) — re-imported via the facade's `from
# validate_checks.prompts import *` above (single SSOT, no forked copy). Reads
# the same Cluster-I-exclusive `PROMPTS_DIR` constant as Check 6. ──


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


# ── Cluster E (Checks 16,22,23 + `_CHECK_16_EXEMPT_SURFACES` / `_VERB_RE` /
# `_PACK_INTERNAL_RE` / `_is_pack_internal`; the trinity-addenda + help-fragment
# family) now extracted to validate_checks.help_fragments (BD-256 W6) —
# re-imported via the facade's `from validate_checks.help_fragments import *`
# above. The Check-16 named-lambda registry entries below late-bind
# `check_trinity_addenda_h2` from those re-exported globals (single SSOT, no
# forked copy). The `# Check 21 RETIRED` interstitial breadcrumb moved with the
# block to help_fragments.py to preserve intra-module order. ──


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
