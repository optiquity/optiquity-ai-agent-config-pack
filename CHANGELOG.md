# Changelog

All notable changes to the AI Agent Config Pack are documented here.
Each version is available as a git tag (v1, v2, …).

---

## v11 — May 2026

### v11.0 — Issue-tracker integration + customization-preservation fix

**Scope A — Issue-tracker integration (D-1..D-23)**

- D-1..D-2 — TrackerProvider abstraction (V1 §2.1): 18 ops + raw +
  capabilities. Canonical `gh` backend (`scripts/lib/tracker-provider-gh.sh`)
  with future-extensibility for forgejo/linear/jira. (BD-060)
- D-3 — Forward and reverse migration libraries
  (`scripts/lib/tracker-migrate-{forward,reverse}.sh`); idempotent.
  Forward: `BACKLOG.md` → tracker issues. Reverse: tracker issues →
  sidecar `BACKLOG.md`. (BD-065 / BD-068 / BD-070)
- D-4-V2 / D-16 / D-17 / D-18 — Issue template forms
  (`.github/ISSUE_TEMPLATE/work-item.yml`, `inbound.yml`, `config.yml`)
  with 4 wi-type + 7 in-category options. (BD-063)
- D-5 — Tracker config (`tracker.toml.example` template installed at
  project root by init-project.sh). (BD-061)
- D-6 / D-7 — Mirror file behavior + Source column convention.
- D-8 — Sidecar + template-version drift handling. (BD-067)
- D-9 / D-10 / D-11 — Failure UX + typed error model
  (`scripts/lib/tracker-errors.sh`); agent-read library
  (`scripts/lib/tracker-agent-read.sh`). (BD-066 / BD-069 / BD-071)
- D-19 — Inflection-point recommendation system
  (`scripts/lib/recommendation.sh`). Pack-side 3 signals + client-side
  6 signals; per-user state at `.pack-tracker/recommendation-state.json`;
  cooldown + persistent refusal flags. (BD-072 / BD-073 / BD-074)
- D-20 — Help-verb system: LCD shell verb `pack help`
  (`scripts/pack-help.sh`) + per-CLI `/pack-help` skills/commands +
  shared `HELP-FRAGMENT-PACK.md` / `docs/pack/HELP-FRAGMENT.md` +
  byte-identical `HELP-FRAGMENT-TRACKER.md` mirror per DELTA L1.
  (BD-075 / BD-076 / BD-077)
- D-21..D-23 — Recommendation routing rules in PACK-CHAT.md /
  project-template/docs/pack/PM-CHAT.md (BD-092 sweep).

**Scope B — v11 version cut + ride-alongs**

- BD-088 — Customization-preservation library (`scripts/lib/customization-preserve.sh`
  + `customization-report.sh`). 12 file classes; 8 canonical disposition
  tokens; truthful report (every file accounted for; no silent drops).
  Single-slot sidecars (`.v10-customized` for migrator, `.pre-update`
  for `init-project.sh --update`). 72 BD-088 fixture tests (137 total
  across BD-088 + BD-080 + BD-085; pack-help adds another 17 tested
  separately under BD-075/077) on bash 3.2.57. Closes BD-059.
- BD-080 — `init-project.sh` extensions: stage S11 (v11 client artifacts)
  + `--update` mode (consumes BD-088, sidecar-presence gate on re-run).
  30 fixture tests.
- BD-085 — `scripts/migrate-v10-to-v11.sh`: 7-stage migrator. Backup
  captures full working tree (preserves gitignored `.gemini/.env`). 35
  fixture tests using genuine v10-tag baseline content.
- BD-081 — Trinity addenda: `## Quick reference` block (Pack commands +
  Recommended first action) added to all 6 trinity files (pack-root +
  client) in lockstep.
- BD-082 — validate-pack Checks 21–24 (per-CLI parity / help-fragment
  freshness / completeness / `HELP-FRAGMENT-TRACKER.md` byte-identity).
  Surfaced + fixed help-fragment drift.
- BD-089 — validate-pack Check 25 (customization-detection regression
  guard). 4-fixture synthetic; class coverage delegated to
  `test-customization-preserve.sh` per BD-083.
- BD-083 — Aggregate CI workflow split into `validate` + `tests` jobs;
  17 independent test suites with `if: always()` failure isolation.
- BD-091 / BD-042 — Doc relocation tail; verified end-state by audit.
- BD-084 — `supporting-docs/MIGRATION-v10-to-v11.md` user-facing
  migration narrative.
- BD-094 — `supporting-docs/MERGE-STRATEGY.md` per-file
  customization-preservation matrix (user-readable surface for BD-088).
- BD-090 — QUICKSTART.md callout + cross-references.
- BD-092 — Cross-reference sweep (post-relocation paths + v11 verb
  references; tracker section in OPTIONAL-FEATURES.md; recommendation
  routing in PACK-CHAT.md / project-template PM-CHAT.md).
- BD-086 — README.md v11.0 row + Repository Layout updates.
- BD-087 — This CHANGELOG entry.

**Audit artifacts (release evidence):**

- Customization-preservation regression coverage:
  `scripts/tests/test-customization-preserve.sh` (72 tests) +
  validate-pack Check 25 (BD-089) — both run on every push.
- Semantic audit: `maintenance-docs/v11-research/MAINTAINER-CHECK-AUDIT-2026-05-07.md`.
- Dog-food validation: validate-pack passes all 25 Checks; CI runs
  17 test suites green.

**Carried over to future work (v11-Active BDs Open at v11.0 cut):**

- BD-078 — validate-pack `check_tracker_config` (V1 §A.2).
- BD-079 — validate-pack recommendation-state schema check.
- BD-093 — v11.0 release pin (tag move + README hash + CHANGELOG
  final). Lands as the release commit.
- BD-095 — `migrate-v10-to-v11.sh` `--dry-run` / `--apply` /
  `--resume` modes.
- BD-096 — Synthetic-fixture set (general-use coverage).
- BD-097 — Pre-release semantic audit pass (this release: gated
  BD-093 via SEMANTIC-AUDIT-REPORT.md).
- BD-098 — Tracker walkthrough refinement in OPTIONAL-FEATURES.md
  (initial shipped in BD-092).
- BD-099 — DEPENDENCIES.md `gh` optional-dep pointer.
- BD-100 — Pack-implementation milestone checkpoints (3 strategic
  audits during v11).
- BD-101 — Client-migration validation gates (3 in-script gates with
  pass/fail).
- BD-102 — Pack-repo dog-food migration (final v11 validation).
- BD-103 — `pack tracker reset` verb + 3-level recovery documentation.
- BD-104 — Cross-pack rename `IMPLEMENTATION_PLAN.md` →
  `IMPLEMENTATION-PLAN.md`.
- BD-105 — STATUS.md phase-row dual-link rendering (tracker mode).
- BD-106 — Phase task entity model + identifier scheme + parser/emitter.
- BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close).
- BD-108 — Cross-entity dependency link orchestration + cycle check +
  gate-check extension.
- BD-109 — Project-side `auditor-issue-tracking` sub-agent.
- BD-110 — Pack-side `pack-auditor` agent.
- BD-111 — First-class GitHub dependency-API mutation (replaces
  comment-marker fallback in `tracker_provider_gh_link`).
- BD-112 — Three-way diff filename mangling collision fix (affects both
  `customization-preserve.sh` and `migrate-v9-to-v10.sh`).

---

## v10 — April 2026

### v10.0 (post-release patches) — April 2026

**BD-059 — v10 migration preservation fix (in progress)**

The v10.0 release-as-tagged silently destroyed project customization
when the OT migration ran 2026-04-30. BD-059 captures the design,
plan, and implementation that closes the defect. v10.0 has not reached
production; the fix lands in `main` without a version bump. Commits
through G5 gate: design + plan + research bundle (4c55a69), three-way
classifier + backup-restore helpers (efd19a5), disposition-driven
migration with sidecars + skill-dir sibling preservation (9a09e5f),
JSON/TOML structured-config merges (f83d555), trinity-rule comparator
for pack-roster agent files (73d480e), procedure relocation to
`supporting-docs/INSTALL-PROCEDURES.md` (32a9543), cross-reference
sweep to INSTALL-PROCEDURES.md (ef222f1), trinity ## Project addenda
+ x-prefix convention + PM-CHAT project-owned markers (90ffaab),
migration test fixtures and end-to-end test runner (381d377),
validate-pack.py checks 12-16 for migration regression protection
(1bfe90b), add-capability.sh x-prefix forward contract (d06874d),
cross-tool capability + MCP parity (this commit).

**Procedure relocation (BD-059 C7)**

- `supporting-docs/INSTALL-PROCEDURES.md` — new doc hosting Procedures
  5 / 5-C / 5-S / 7. These are one-shot install / migration / kickoff
  procedures that fire a maximum of once per project and pollute
  METHODOLOGY.md with content irrelevant to ongoing project work.
  METHODOLOGY.md retains one-line pointer stubs at the same H3
  anchors so legacy cross-references resolve. Includes the new
  `## Project file conventions in pack-controlled directories`
  section per OQ-6(a) documenting the `x-` prefix contract.
  Procedure 5-C is new (umbrella reconciliation procedure for
  `*.v9-customized` sidecars produced by the fixed migration);
  Procedure 5-R is folded into Procedure 5-C.1 as a sub-procedure
  per OQ-P4. (BD-059)
- `scripts/migrate-v9-to-v10.sh` S5 — copies INSTALL-PROCEDURES.md
  from pack to project's `docs/pack/INSTALL-PROCEDURES.md` alongside
  METHODOLOGY.md. S6 sidecar naming unified on `.v9-customized`
  (PROMPT-TEMPLATES retirement now produces
  `docs/pack/PROMPT-TEMPLATES.md.v9-customized` instead of
  `docs/pack/prompts/_v9-backup.md`). End-of-run summary references
  Procedure 5-C / 5-C.1 instead of Procedure 5-R. (BD-059)
- `scripts/init-project.sh` S6 — copies INSTALL-PROCEDURES.md to
  fresh and existing projects via the `existing_classifier_copy`
  helper. (BD-059)
- `supporting-docs/METHODOLOGY.md` — Procedures 5 / 5.1–5.6 / 5-R /
  5-S / 7 bodies stripped; pointer stubs replace each section at the
  same H3 anchor. Procedure 5-C stub added (new). Procedure 6
  (capability addition) retained — it fires repeatedly throughout a
  project lifetime, not as a one-shot. (BD-059)

**Cross-tool capability + MCP parity (BD-059 C11, G5)**

- `project-template/.codex/config.toml` — adds `[agent_capabilities]`
  table mirroring `.claude/settings.json` `env.AGENT_CAPABILITIES`.
  Closes BD-059 success criterion (a).
- `project-template/.gemini/.env` (NEW) — `AGENT_CAPABILITIES` parity
  per OQ-Q4 user decision (Option A: `.env` file). Closes BD-059
  success criterion (a) for Gemini.
- `project-template/.gemini/settings.json` (NEW) — minimal Gemini CLI
  config with `mcpServers.local-rag` block parallel to
  `.mcp.json.example`. Closes BD-059 success criterion (b) for Gemini.
- `project-template/.codex/config.toml.example` (NEW) — sibling to
  live `config.toml` carrying a commented `[mcp_servers.local-rag]`
  STDIO block per `V10-CODEX-MCP-RESEARCH.md`. Codex CLI loads
  project-scoped config only for trusted projects (per Codex docs);
  the developer copies / symlinks this file when ready. Closes
  BD-059 success criterion (b) for Codex.
- `scripts/migrate-v9-to-v10.sh` S3 — extends K-class file iteration
  to include K5 (.gemini/settings.json), K6 (.gemini/.env), K7
  (.codex/config.toml.example). Existing projects pre-C11 had none of
  these files; migration treats them as `new-file-in-pack` and copies
  them in.
- `scripts/init-project.sh` S3 — same iteration extension for fresh
  projects. Verification checks added: `.gemini/.env` and
  `.gemini/settings.json` must be present after S3 (BD-059
  trinity-rule parity).
- `scripts/validate-pack.py` Check 17 (NEW) — `check_tool_config_capability_parity`.
  Reads `AGENT_CAPABILITIES` from each tool's config and asserts all
  three sets match. Hard-fails CI if Claude / Codex / Gemini
  capability rosters drift.

BD-059 success criteria (a) AGENT_CAPABILITIES parity and (b) MCP
server config parity now both satisfied. Final remaining work is the
end-to-end OT verification (revert + re-run) per OQ-8.

### v10.0 — April 2026

**Project initialization and migration**

- `scripts/init-project.sh` — new initialization script with detection-and-preview-and-confirm flow. Detects project class (`new`, `existing-empty`, `existing-with-marker-conflict`, `existing-clean`) via `scripts/lib/detect.sh` shared library; previews planned operations across 10 stages (S1–S10); requires explicit `Proceed?` confirmation before mutating the target. Distributes pack agents, skills, scripts, and trinity context files; copies `METHODOLOGY.md` to `docs/pack/METHODOLOGY.md`; emits an end-of-run PM chat kickoff prompt. Replaces the prior `cp -r` template-copy workflow. (BD-044)
- `scripts/migrate-v9-to-v10.sh` — new migration script for upgrading existing v9.3 projects to v10.0. Eight-stage pipeline (S0 pre-flight + S1 agents + S2 skills + S3 scripts/configs + S4 prompts/ creation + S5 trinity splice/merge + S6 PROMPT-TEMPLATES.md diff vs v9.3 + S7 report). Backup-by-default contract: every mutation backs up to `.pack-migration-backup/v9.3-to-v10.0/`; `_v9-backup.md` written to `docs/pack/prompts/` if PROMPT-TEMPLATES.md customization detected. Writes `postrun-pending` sentinel to trigger Procedure 5-S at next PM chat startup. (BD-046)
- `scripts/lib/detect.sh` — shared shell library used by both init and migrate scripts: `detect_clean_working_tree`, `detect_git_repo`, `detect_pack_path`, `detect_pack_version`, `detect_ai_config`, `detect_x_files`, `detect_improperly_added_files`, `detect_installed_capabilities`. Unit-tested by `scripts/test-detect.sh` (34 cases). (BD-044)
- `scripts/merge-platform-skills.py` and `scripts/merge-trinity.py` — splice/merge helpers used by migrate S5 to preserve project-owned `## Custom agents` / `## Custom skills` sections, `### Custom agents` sub-sections, and `**Active skills:**` lines while replacing pack-owned content. (BD-046)
- `QUICKSTART.md` rewritten as a three-path router (NEW / EXISTING / MIGRATE). `supporting-docs/SETUP_TEMPLATE.md` and `SETUP-NEW.md` rewritten; `SETUP-EXISTING.md` added; `MIGRATION-v9-to-v10.md` added. Step numbering preserved across docs for cross-reference stability (BD-047 collapsed Steps 5–8 of SETUP-NEW.md into Step 5). (BD-044, BD-047)

**Kickoff auto-discovery and Procedure 7**

- METHODOLOGY § Procedure 7 — kickoff auto-discovery and install-check. Triggered when developer pastes `Variant: kickoff` from `pm-chat.md`. Four gates: G7-discovery (Form R), G7-install (Form I), G7-edit (Form E), G7-machine (Form M). G7-discovery defaults to `yes` (read-only); the other three default to `skip`. Procedure 7's auto-discovery fills in Apple Xcode scheme/destination, swift-format install state, gRPC tooling state, Python tooling state, and Xcode CodingAssistant companion-files state — replacing manual SETUP-NEW Steps 5–8 on shell-capable surfaces. (BD-047)
- `pm-chat.md` `Variant: kickoff` rewritten — Convention exception (BD-049: kickoff is a context handoff, not an agent-task prompt; labeled-section convention does not apply). Surface-declaration block + Procedure 7 continuation pointer + manual-fallback pointer for non-shell surfaces. (BD-047)
- METHODOLOGY § 7.0 gate semantically codified (F-A.1): assistant declares surface AND emits one-message exit ramp before Form R. On shell-capable surfaces, surface declaration by inference is sanctioned (not a deviation). Reply grammar reused per § 7.5. (F-A)
- METHODOLOGY § 7.6 Preview rendering rule (F-A): Form I + Form M idempotency-collapsed cases render as single-line `note:` inside Form R results table — formalized as recognized rendering, not deviation. Cross-referenced from § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2. (F-A)
- `pm-chat.md` kickoff body discovery instruction surface-agnostic (F-A.2): the four-doc list (ARCHITECTURE.md / IMPLEMENTATION_PLAN.md / STATUS.md / BACKLOG.md) preserved as project-context contract; HOW-to-retrieve assertion replaced with "locate by whatever means your surface provides" (works on shell, Web with Project + connector, manual fallback). (F-A)

**Per-agent prompt templates**

- `project-template/docs/pack/prompts/` — new directory replacing the v9.3 monolithic `PROMPT-TEMPLATES.md`. 10 per-agent prompt template files (architect.md, auditor.md, coder.md, docs-researcher.md, grpc-schema.md, planner.md, pm-chat.md, repo-ops.md, reviewer.md, tester.md) with `## Variant: <name>` sections. (BD-046)
- Labeled-section convention enforced across all in-scope variants (BD-049): `**Problem:**` / `**Goal:**` / `**Success criteria:**` triad + `REPORT FILE:` or `**Completion report:**` indicator. `validate-pack.py` Check 10 added to enforce. METHODOLOGY § Prompt Authoring Principles updated to single-source the convention; `supporting-docs/PROMPT-AUTHORING.md` deleted (content migrated into METHODOLOGY). (BD-049)
- METHODOLOGY § Prompt Authoring Principles "Format-vs-solutions: worked examples" subsection (F-G): five paraphrased Negative/Positive/Why examples covering testability technique, API/framework name, architectural-shape invention, timing/lifecycle prescription, and the clarifying case that Files-in-scope is NOT solution leakage. Per-agent table extended with `pm-chat (self-prompt)` row. `swift-best-practices/SKILL.md` gains "## Design choices" section (entries 39–40) preserving substantive lessons (AsyncStream payload-design trade-offs; type-erasure-vs-protocol-elevation) as patterns rather than prescriptions. (F-G)

**Capabilities pattern**

- Trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) carry the capabilities-pattern section (BD-045): make what a type supports explicit and queryable. Two complementary forms documented (value-based + interface-based); explicit relationship-to-LSP guidance. Parallel content in `apple-architecture-core`, `python-architecture`, `architecture-review` skills. `auditor-architecture` agent extended with capabilities-scope rules. `audit-methodology` SKILL rule 15 covers the extension. (BD-045)

**Post-migration housekeeping**

- METHODOLOGY § Procedure 5-S — post-migration housekeeping (F-E + F-F). Triggered by sentinel `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` written by migrate S7. Two tasks under one trigger: Task A scans STATUS.md for stale pack-version markers; Task B grep trinity for unfilled placeholders and runs standalone Q&A for project identifiers. Re-entrant on partial completion (sentinel preserved if any task deferred). PM-chat self-cleans on completion. (F-E + F-F)
- pm-startup SKILL gains Step 0 trigger detection (F-E + F-F): detects both the new Procedure 5-S sentinel AND the existing Procedure 5-R `_v9-backup.md` trigger. Fixes a latent gap where Procedure 5-R routing was previously documented only in `MIGRATION-v9-to-v10.md` prose, not in the SKILL itself. (F-E + F-F)

**METHODOLOGY canonical location**

- `METHODOLOGY.md` canonical project-tree location is `docs/pack/METHODOLOGY.md` (F-D, fixing v10-dev implementation drift). Trinity table in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` rows already aligned at v9.3; v10 init and migration scripts now match. Migration script's S5 stage handles all four pre-states (docs/pack only / root only / both / neither): backs up whichever is present, writes v10 content to docs/pack/, removes any stale root copy with backup. Resolves both F-D (design contradiction) and F-C (legacy-cleanup defect) jointly. `init-project.sh` warns on stale root METHODOLOGY for existing projects (does not delete — operator action expected). `init-project.sh` blast_radius_sweep excludes METHODOLOGY.md from PROMPT-TEMPLATES sweep (METHODOLOGY legitimately documents v9→v10 PROMPT-TEMPLATES.md migration in Procedure 5-R). (F-D + F-C)

**Pack-repo validation**

- `scripts/validate-pack.py` extended from v9.3's 5 checks to **10 checks**: Check 6 (prompts directory format) per BD-046; Check 7 (pack-agent roster) per BD-046; Check 8 (reserved x- prefix) per BD-046; Check 9 (init-project structure) per BD-044; Check 10 (prompt-template triad compliance) per BD-049. (BD-044, BD-046, BD-049)
- `scripts/test-detect.sh` — 34 unit-test cases covering all 8 `scripts/lib/detect.sh` library functions. Validates detection logic without filesystem mutation. (BD-044)
- `scripts/add-capability.sh` — adds a pack-supported capability (e.g., adding gRPC to a pure-Swift project, or adding Python to an Apple project). Calls `detect.sh` to identify current state; updates skill loadout in trinity files; appends conditional sections. (BD-046)

**Custom agent and skill workflow**

- METHODOLOGY § Procedure 5 — custom agent and skill workflow (BD-046). 6 sub-procedures: 5.1 creating a custom agent; 5.2 creating a custom skill (standalone); 5.3 completing partial registration (Unregistered); 5.4 adopting an improperly-added file; 5.5 detection scan as a phase-gate step; 5.6 registration reference tables.
- METHODOLOGY § Procedure 5-R — prompt reconciliation after v9.3 → v10 migration (BD-046). Triggered by `_v9-backup.md` presence; walks developer through customization-vs-baseline diff and proposed v10 placement.
- METHODOLOGY § Procedure 6 — adding a pack-supported capability (BD-046). Triggered by `add-capability.sh` or developer request.
- `PLATFORM-SKILLS.md` `## Custom agents` and `## Custom skills` project-owned regions (BD-046). Trinity `### Custom agents` sub-section (BD-046).

**Phase 4 verification**

- `maintenance-docs/V10-PHASE-4-VERIFICATION.md` — comprehensive verification evidence for v10.0 ship-readiness. Captures §4.1 fixture evidence, §4.2 cross-surface docs-research pass (DR1 Codex CLI / DR2 Gemini CLI / DR3 Desktop Commander deferred to v10.1 per scope decision), §4.3 Claude Web manual-mode smoke, §4.4 synthetic migration smoke, §4.5 detect.sh unit tests, §4.6 OT real-project migration smoke, §4.7 OT post-migration kickoff smoke, §4.8 OT-vs-synthetic comparison, plus delta verifications §10–§13 for the v10.0 patch sequence (F-C, F-D, F-E, F-F, F-G, F-A) and §14 post-ship behavioral re-test. Live OT byte-identity verified at 13 post-baseline checkpoints across the entire effort.

**Notable supporting infrastructure**

- BD-038 dynamic-skill-management feature (carried from v9.1) re-verified working under v10 PM chat: `**Active skills:**` line in trinity files; PM chat checks coverage at every phase gate; flags skill gaps proactively.
- pack repo `Validate Pack` GitHub Actions workflow runs on every push.
- Three-tool parity preserved: agent file count + name correspondence enforced by `validate-pack.py` Check 5; skill distribution to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at project creation by `init-project.sh`.

**Deferred to v10.1** (per `V10-PHASE-4-VERIFICATION.md` §0.6 scope decision): live cross-surface verification runs against Codex CLI workspace-write sandbox, Gemini CLI plan-mode interaction, and Desktop Commander filesystem-MCP allowlist. Four v10.1 BACKLOG candidates filed at C-V10-18 sweep.

---

## v9 — April 2026

### v9.3 — April 2026

**BD-043 — Gemini CLI native subagent architecture and full doc audit**

- `.gemini/agents/` directory created with 16 agent files using Gemini CLI's
  native subagent format (Markdown with YAML frontmatter: `name`, `description`,
  `model`, `temperature`, `max_turns`). Agents are discovered automatically by
  Gemini CLI at session start.
- `project-template/GEMINI.md` stripped from ~700 lines to ~360 lines — all 16
  inline agent role definitions removed, replaced with short agent roster
  reference. Section ordering aligned with CLAUDE.md. Duplicate Skill loading
  section removed. Content parity improved (dependency intake, deferral comments,
  anti-patterns, build hygiene).
- `project-template/agent-run.sh` fixed for Gemini CLI: transparent `--agent`
  to `@agent-name` translation (interactive mode uses `-i`, headless mode
  prepends to `-p`). Auditor subagent prompts simplified — agent files provide
  system prompts. All "Option X" references removed.
- `scripts/validate-pack.py` Check 5 extended to enforce three-tool agent parity
  (Claude + Codex + Gemini file count and name correspondence).
- `project-template/skills/audit-methodology/SKILL.md` rules 58 and 66 corrected:
  Gemini has native subagents (subagents cannot call subagents); external
  orchestration retained for headless auditor.
- `maintenance-docs/TOOL-COMPARISON.md` Part 2 table corrected: agent definition
  format, invocation, launcher, and subagent support entries for Gemini.
- Full doc audit across 11 additional files: PACK-AGENTS.md, README.md,
  project-template/README.md, CLAUDE.md and AGENTS.md (trinity rule),
  DEPENDENCIES.md, PROMPT-TEMPLATES.md, MIGRATION-v8-to-v9.md, V9-DESIGN.md,
  V9-AUDIT-REPORT.md, GEMINI-CLI-ANALYSIS.md.

**Rename**

- Renamed from "DHS AI Agent Config Pack" to "Optiquity AI Agent Config Pack."
  Repo slug changed from `dhs-ai-agent-config-pack` to
  `optiquity-ai-agent-config-pack`. GitHub redirects the old URL. Display name
  updated in README.md, CLAUDE.md, AGENTS.md, GEMINI.md, PACK-CHAT.md, and
  pack-startup skill. Slug updated in PACK-CHAT.md, SETUP-NEW.md,
  SETUP-EXISTING.md, MIGRATION-v9-to-v10.md, MIGRATION-v8-to-v9.md, and
  settings.local.json. Archive docs preserved unchanged (historical records).
  No functional changes to agents, skills, scripts, or workflows.

---

## v8 — March 2026

### v8.10 — April 2026

**v9 planning documents**

- `supporting-docs/V9-DESIGN.md` — authoritative design record for v9: 8 design
  decisions with rationale and rejected alternatives, PM chat architecture for all
  three tools, full documentation change inventory, backlog map (BD-020–031),
  15-step implementation sequence with success criteria. Do not modify without
  explicit approval.
- `supporting-docs/TOOL-COMPARISON.md` — living capability reference for Claude,
  Codex, and Gemini: PM chat capability matrix (7 surfaces), agent invocation
  differences (including agent-run.sh, local model support, model profiles), skill
  loading mechanisms, approval model defaults, context window and cost guidance,
  cross-tool operational differences. Supersedes GEMINI-CLI-ANALYSIS.md and
  ANDROID-ANALYSIS.md.
- `BACKLOG.md` — added BD-025 through BD-031; BD-030 resolved (TOOL-COMPARISON.md
  committed in this version); BD-031 deferred post-v9.

**Branch strategy**

- `v9-dev` branch created from this commit. All v9 implementation work (Steps 2–15
  from V9-DESIGN.md) proceeds on `v9-dev`. The `main` branch continues v8.x patches
  independently.

---

### v8.9 — April 9, 2026

**Scripts**

- `agent-run.sh` added to all three templates (apple-app, python-server, monorepo)
  — standard launcher for Claude Code and Codex CLI agents; automatically applies
  read-only permission flags (`--permission-mode bypassPermissions`,
  `--disallowedTools git commit/push` for Claude; `--sandbox read-only`,
  `-a never` for Codex) to agents that should never write source files (reviewer,
  planner, apple-architect, docs-researcher, grpc-schema); write-permission agents
  (coder, tester, repo-ops) run with default permissions. Place in project root and
  use in place of direct `claude` / `codex` invocation for consistent flag behavior.

---

### v8.8 — April 7, 2026

**Pack CLI chat support**

- `PACK-CHAT.md` (pack repo root) — startup and operating instructions for the
  pack CLI chat session; covers role, file access strategy, behavioral rules,
  session naming, cross-machine instructions, and RAG ingest guidance. This is
  a pack-specific file — not a template and not copied to coding projects.
- `.claude/skills/pack-startup/SKILL.md` (pack repo root) — `/pack-startup` skill
  for pack chat session orientation: git pull, read BACKLOG.md and CHANGELOG.md,
  check RAG freshness for supporting-docs/METHODOLOGY.md and
  supporting-docs/PROMPT-TEMPLATES.md, report pack version and open BD items.
  Completely independent of the `/pm-startup` skill used by coding projects.
- `.mcp.json.example` (pack repo root) — mcp-local-rag configuration template
  for the pack repo itself; distinct from the template `.mcp.json.example` files
  which include an Xcode entry
- `.gitignore` (pack root) — add `.claude/rag-index/` and `.claude/rag-cache/`

**Corrections**

- `QUICKSTART.md`, `supporting-docs/DEPENDENCIES.md` — corrected embedding model
  download size from ~50MB to ~90MB (actual size per mcp-local-rag package)
- `supporting-docs/DEPENDENCIES.md`, `supporting-docs/CLI-PM-SETUP.md` — added
  mcp-local-rag update instructions (`npx --prefer-online`) and note to re-ingest
  docs after updating
- `QUICKSTART.md`, `PACK-CHAT.md`, `supporting-docs/DEPENDENCIES.md`,
  `supporting-docs/CLI-PM-SETUP.md` — removed invalid `npx -y mcp-local-rag --version`
  pre-warm step (`--version` flag does not exist); embedding model (~90MB) downloads
  automatically on first ingest; update command corrected to `--help`
- `supporting-docs/METHODOLOGY.md` — version string corrected from v8.6 to v8.8
  (file was modified in v8.7 and v8.8 but version header was not bumped)
- `PACK-CHAT.md`, `.claude/skills/pack-startup/SKILL.md` — removed mcp-local-rag
  from pack CLI chat entirely; the pack chat is the author of METHODOLOGY.md and
  PROMPT-TEMPLATES.md, not a consumer — direct read is correct; RAG is appropriate
  only for coding projects that use these files as stable reference
- `.mcp.json.example` (pack root) — deleted; no longer needed without mcp-local-rag
- `.gitignore` (pack root) — removed rag-index/rag-cache entries; no longer needed

---

### New files — methodology infrastructure
- `supporting-docs/METHODOLOGY.md` — universal project development methodology:
  tool roles, standard documents, agent roster, phase structure, 6 workflows,
  audit checkpoints, warning signs, document authoring rules
- `supporting-docs/PROMPT-TEMPLATES.md` — 14 ready-to-use agent prompt templates:
  PM chat kickoff, coder, reviewer, fix cycle, tester, docs-researcher, planner,
  BACKLOG/STATUS update, 4 audit prompts, SETUP.md and AGENT_KICKOFF.md generation
- `supporting-docs/SETUP_TEMPLATE.md` — fill-in-the-blanks template for generating
  a project-specific SETUP.md via PM chat
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` — fill-in-the-blanks template for
  the architecture phase kickoff prompt
- `supporting-docs/MIGRATION-v7-to-v8.md` — step-by-step upgrade guide for
  existing v7 projects including exact text for all additive changes
- `supporting-docs/ANDROID-ANALYSIS.md` — analysis of what would be needed for
  Android support; Gemini CLI recommendation for Android
- `supporting-docs/GEMINI-CLI-ANALYSIS.md` — analysis of Gemini CLI integration
- `supporting-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md` —
  raw source material (OptiquityTrader methodology guide, archived for reference)
- `METHODOLOGY.md` — copied to all three template roots
- `supporting-docs/guides/ai-agent-config-pack-v8-guide.docx` — v8 setup guide (.docx format; v9+ guides will be .md only)
- `supporting-docs/guides/ai-agent-config-pack-v8-guide.md` — Markdown version of the v8 guide (primary format going forward)

### New agents and skills
- `python-architect` agent (python-server, monorepo) — service layer, grpc.aio
  patterns, repository boundaries, Pydantic placement, ML isolation
- `python-architecture` skill (python-server, monorepo) — 10-item checklist
  mirroring ios-architecture/SKILL.md for Python server concerns

### Renamed
- `ios-architect` → `apple-architect` (apple-app, monorepo) — agent now clearly
  covers iOS, iPadOS, and macOS; all references updated

### Critical fix
- **BD-017** — iOS 26 platform features section now includes availability guard
  requirement: `.glassEffect()` and FoundationModels require `#available(iOS 26, *)`
  / `#available(macOS 26, *)` guards on older deployment targets (apple-app, monorepo,
  both Xcode companion files)

### Updated — all three templates
- `.codex/config.toml` — `post_edit_command` added; Codex now fires
  `agent-post-edit-check.sh` after every file edit (mirrors Claude Code hook)
- `.gitignore` (apple, monorepo) — complete Xcode artifact patterns merged from
  OptiquityTrader: `*.dSYM`, `*.hmap`, `*.ipa`, fastlane, Carthage/Build/
- `.claude/settings.local.example.json` — improved with common allow patterns
  (grep, ls, find, cat, open, WebSearch) and usage comment block
- `scripts/format.sh` — misleading "hook calls this" comment removed; now correctly
  documented as manual/pre-commit only
- `scripts/validate.sh` and `scripts/test.sh` (apple, monorepo) — warning upgraded
  to `⚠️  XCODE_SCHEME is not set` with clear actionable message
- `scripts/agent-post-edit-check.sh` (apple, monorepo) — now runs real
  `xcodebuild build` when XCODE_SCHEME is set; warns clearly when it is not

### Updated — CLAUDE.md and AGENTS.md (apple, monorepo)
- New `## Scripts` section — table of all scripts, when to run, who calls each
- New `## Liskov Substitution Principle` section — generalized from OptiquityTrader
- Typed ID wrapper rule added to Swift coding rules and Design rules
- Architecture section: ARCHITECTURE.md must be completed before production code
- Security: Request minimum required permissions/entitlements added
- Anti-patterns: domain types in transport signatures, hard deletion without
  tombstoning added; mutable global state added to Python section (monorepo)

### Updated — QUICKSTART.md
- Step 4 expanded: scripts/ copy instruction, permissions, bootstrap, full table
- Steps 11–13 added: Create Claude project, start PM chat, generate SETUP.md
  and AGENT_KICKOFF.md via PM chat templates

### Updated — BACKLOG.md
- `V8-BACKLOG.md` renamed to `BACKLOG.md`
- BD-008 through BD-019 added
- Active/Resolved/Deferred section structure introduced

---

## v7 — March 23, 2026

### New
- `shared-docs/ios26/` — Apple's own iOS 26 API docs extracted from the Xcode
  bundle (gitignored; sync locally with `sync-xcode-docs.sh`)
- `sync-xcode-docs.sh` (pack root) — syncs ios26 docs from installed Xcode app;
  re-run after each Xcode update

### Updated
- `docs-researcher` agent (apple, monorepo) — priority lookup: ios26/ first,
  then web search against developer.apple.com
- `CLAUDE.md` (apple, monorepo) — new iOS 26 / Xcode 26.3 platform features
  section (Liquid Glass, FoundationModels, Swift Concurrency)
- `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` — Apple-first
  dependency policy
- `xcode-companion-templates/Codex/AGENTS.md` — matching Codex policy
- `QUICKSTART.md` — v7 setup steps including sync-xcode-docs.sh

---

## v6 — March 11, 2026

### New
- `proto/` scaffold in all templates (buf.yaml, buf.gen.yaml, example .proto
  files) — starter schema for gRPC services
- `QUICKSTART.md` (pack root) — end-to-end setup guide
- `error-handling` skill (all templates) — standardised error handling checklist
- `scripts/proto-gen.sh` — runs `buf lint` then `buf generate`; agents call this
  after every .proto edit

### Updated
- All `CLAUDE.md` files — gRPC rules, buf CLI rules, proto anti-patterns
- `scripts/validate.sh` — stricter: runs `xcodebuild build-for-testing` then
  `xcodebuild test` when scheme is configured
- `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` — gRPC conventions
- `xcode-companion-templates/Codex/AGENTS.md` — matching Codex conventions

---

## v5 — March 9, 2026

### New
- `python-server-template/` — full template for standalone Python gRPC servers
  (CLAUDE.md, AGENTS.md, all agents + skills, scripts, pyproject.toml,
  pyrightconfig.json, src scaffold)
- `apple-app-plus-python-server-template/` — monorepo template combining Apple
  client and Python server
- `xcode-companion-templates/` added to the pack (previously machine-level only)

### Updated
- All agents — expanded with Python / gRPC / grpc.aio knowledge
- `scripts/` — bootstrap.sh and validate.sh updated for Python support

---

## v4 — March 9, 2026

### New
- `grpc-schema` agent (Claude + Codex) — Proto3 schema review, field evolution,
  buf validation
- `grpc-schema` skill — checklist for schema review tasks
- `.codex/agents/` — all Codex agents converted from YAML/md to `.toml` format

### Updated
- `apple-app-template/CLAUDE.md` — gRPC client rules, grpc-swift-2 patterns
- `apple-app-template/.claude/settings.json` — updated allowlist
- `apple-app-template/.codex/config.toml` — grpc-schema agent integration

---

## v3 — March 9, 2026

### New
- `.gitignore` added to each template (gitignores settings.local.json, .mcp.json,
  generated Protobuf output, .DS_Store, etc.)
- `README.md` added to each template — quick-start instructions for the template

### Changed
- Streamlined to `apple-app-template` only (monorepo template moved to v5
  when Python support matured)
- `shared-docs/` simplified — content consolidated and reduced

---

## v2 — March 6, 2026

### New agents
- `repo-ops` — git operations, script runs, repo housekeeping
- `docs-researcher` — documentation lookup, dependency research

### New skills
- `planning`, `implementation`, `review`, `testing`, `debugging`,
  `documentation`, `repo-ops`, `ios-architecture`

### Updated
- `xcode-companion-templates/` — full `CLAUDE.md` and `AGENTS.md` with project
  conventions and phase routing
- All existing agents — improved descriptions and tool listings
- `shared-docs/VERIFIED-NOTES.md` — expanded verification notes

---

## v1 — March 6, 2026

Initial release.

### Included
- `apple-app-template/` with 5 agents: planner, coder, reviewer, tester,
  ios-architect
- `apple-app-plus-python-server-template/` (early monorepo template)
- `xcode-companion-templates/` (minimal machine-level config)
- 3 skills: architecture-review, dependency-intake, ui-test-strategy
- `shared-docs/` with README, VERIFIED-NOTES, RECOMMENDATIONS
