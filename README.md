# Optiquity AI Agent Config Pack

The Config Pack is a versioned **multi-agent project workflow system** for
Claude Code, Codex CLI, and Gemini CLI. A persistent **PM Chat** session
orchestrates role-shaped agents (architect, coder, reviewer, tester, planner,
auditor, docs-researcher, grpc-schema, repo-ops) using shared context files,
skill libraries, and validation scripts — the same configuration works
identically across every CLI. Focused on software development with extensive
support for Apple platforms, Python, and gRPC; extensible to any project
type. Maintained by [Optiquity, Inc.](https://optiquity.com)

## What is this?

Per-project and machine-level configuration files that give Claude Code, Codex
CLI, Gemini CLI, and IDEs such as Xcode's built-in AI a shared, consistent
understanding of your projects — architecture rules, coding standards, agent
roles, skills, and shell scripts that validate agent output. The PM Chat is
the human-coordinated coordination layer; agents are invoked via
`agent-run.sh` and report back through paste-able output, so the workflow is
deterministic, auditable, and identical across CLIs.

## Using the Config Pack

### Terminology

| Term | Definition |
|---|---|
| **You** | The lead contributor, project coordinator, product manager, software engineer, and ultimate decision maker for your project. |
| **Config Pack** | This multi-agent project workflow system. |
| **PM Chat** | The persistent chat session for running and tracking the workflow of any project that uses the Config Pack. Technically the **Project Manager Chat** or, if you prefer, the **Product Manager Chat** — since you are the ultimate decision maker, this is a distinction without a difference. |
| **Pack Chat** | The persistent chat session for contributing to and maintaining the Config Pack itself. |
| **Agent** | A role-shaped CLI invocation (architect, coder, reviewer, tester, planner, auditor, docs-researcher, grpc-schema, repo-ops). The same agent definitions ship for Claude Code, Codex CLI, and Gemini CLI; the PM Chat invokes them via `agent-run.sh`. |

### With Your Projects

See [`QUICKSTART.md`](QUICKSTART.md) for full setup instructions.

### Contributing to the Config Pack

After checking out the Config Pack repo, `cd` into the repo directory and launch the **Pack Chat** by starting a fresh session in Claude Code, Codex CLI, or Gemini CLI. Run `/pack-startup` first; from there, customize your session and workspace however you want.

## Optional features and settings

Each CLI ships its own optional or experimental features that the Config Pack
can plug into. See [`OPTIONAL-FEATURES.md`](OPTIONAL-FEATURES.md) for the
current list — including Claude Code's Agent Teams (parallel teammates that
share a task list and message each other) and equivalents for Codex CLI and
Gemini CLI as they ship.

## Version History

### Versioning convention
Major versions (v9, v10, …) mark large additions or breaking changes.
Minor versions (v9.0, v9.1, …) mark incremental improvements — doc updates,
new templates, prompt and workflow refinements. The bare major tag (e.g. `v9`)
always points to the latest minor of that major version.

| Version | Date         | Key Additions |
|---------|--------------|---------------|
| v11.0   | May 2026     | Issue-tracker integration (Phase A — D-1..D-23 surfacing as forced trinity addenda + per-CLI `/pack-help` + HELP-FRAGMENT shared content; Phase B — opt-in tracker abstraction with `gh` backend, forward/reverse migration, recommendation system); BD-088 customization-preservation library + truthful report (BD-059 fix); migrate-v10-to-v11.sh; init-project.sh `--update`; validate-pack.py expanded to 25 Checks (per-CLI parity, help-fragment freshness/completeness, byte-identity, customization regression guard); aggregate CI test runner across 17 suites |
| v10.0   | Apr 29, 2026 | Procedure 7 kickoff auto-discovery + Procedure 5-S post-migration housekeeping; per-agent prompt templates under docs/pack/prompts/ with labeled-section convention (BD-049); init-project.sh + migrate-v9-to-v10.sh; capabilities pattern (BD-045); METHODOLOGY canonical at docs/pack/; format-vs-solutions worked examples; validate-pack.py expanded to 10 checks |
| v9.3    | Apr 2026     | BD-043 Gemini native subagent architecture (`.gemini/agents/` with YAML frontmatter); GEMINI.md stripped to project context only; agent-run.sh transparent `@agent-name` translation; full Gemini doc audit |
| v9.2    | Apr 2026     | BD-042 pack reference docs moved to docs/pack/; document locations section added to context files |
| v9.1    | Apr 2026     | BD-038 dynamic skill management (Active skills line in context files, proactive skill gap detection at phase gates); BD-041 project initialization brief (design brief prerequisite in PM-CHAT.md) |
| v9.0    | Apr 2026     | Unified template replaces 3 per-type templates; composable skill library (30 skills); three-tool parity (Claude/Codex/Gemini); architect agent unified; 7-cluster auditor agent; PACK-FEEDBACK loop; language-specific scripts with wrappers; GEMINI.md + PLATFORM-SKILLS.md + PACK-FEEDBACK.md; GitHub Actions CI validation; agents read Xcode docs directly from bundle |
| v8.10   | Apr 2026     | v9 planning: V9-DESIGN.md, TOOL-COMPARISON.md, BACKLOG.md (BD-025–031); v9-dev branch created |
| v8.9    | Apr 9, 2026  | agent-run.sh added to all three templates: read-only/write permission flags per agent, Claude Code and Codex CLI support |
| v8.8    | Apr 7, 2026  | Pack CLI chat: PACK-CHAT.md, /pack-startup skill; corrections to mcp-local-rag docs (QUICKSTART.md, DEPENDENCIES.md, CLI-PM-SETUP.md); METHODOLOGY.md version string fix |
| v8.7    | Apr 6, 2026  | CLI PM chat: PM-CHAT.md template, /pm-startup skill, CLI-PM-SETUP.md, mcp-local-rag integration |
| v8.6    | Apr 6, 2026  | DEPENDENCIES.md; minor versioning convention; version string corrections |
| v8.5    | Apr 6, 2026  | Standardized agent output report headers across Templates 2–7 |
| v8.4    | Apr 5, 2026  | Prompt Authoring Principles in METHODOLOGY.md and PROMPT-TEMPLATES.md |
| v8.3    | Apr 3, 2026  | Architect rejected-alternative documentation rule; Apple-platform pattern selection rules (type-erasure, AsyncStream, ViewModel navigation) |
| v8.2    | Apr 2, 2026  | Workflow 4 mid-phase architect trigger; BACKLOG/TODO management system; Cancelled/Deprecated item statuses; Template 4 non-prescriptive fix requirement |
| v8.1    | Apr 1, 2026  | Post-release patches: METHODOLOGY single-source, ios-architect rename fixes, PROMPT-TEMPLATES verification updates, PM chat rules, BD-020–023 |
| v8.0    | Mar 29, 2026 | apple-architect rename; python-architect; METHODOLOGY.md; PROMPT-TEMPLATES.md; VS Code companion; LSP rules; OT content merge; availability guard fix |
| v7      | Mar 23, 2026 | iOS 26 / Xcode 26.3 API docs; sync-xcode-docs.sh; Apple-first dependency policy |
| v6      | Mar 11, 2026 | Proto scaffold; QUICKSTART.md; error-handling skill; proto-gen.sh script |
| v5      | Mar 9, 2026  | python-server-template; apple-app-plus-python-server monorepo; xcode-companion-templates in pack |
| v4      | Mar 9, 2026  | grpc-schema agent + skill; .codex agents converted to .toml |
| v3      | Mar 9, 2026  | Per-template .gitignore + README; streamlined to apple-app-template |
| v2      | Mar 6, 2026  | repo-ops + docs-researcher agents; 8 new skills; expanded xcode-companion-templates |
| v1      | Mar 6, 2026  | Initial pack: apple-app and monorepo templates, 5 agents, 3 skills |

## Repository Layout

```
project-template/                           Unified project template (v11)
├── .claude/agents/                         Claude agent files (16 agents)
├── .codex/agents/                          Codex agent files (16 agents)
├── .gemini/agents/                         Gemini agent files (16 agents)
├── .claude/skills/pack-help/               Claude pack-help skill (v11; invokes pack-help.sh)
├── .codex/skills/pack-help/                Codex pack-help skill (v11)
├── .gemini/commands/pack-help.toml         Gemini pack-help command (v11)
├── .codex/config.toml                      Codex config (agent registry, profiles)
├── .claude/settings.json                   Claude Code settings (permissions, hooks)
├── .github/ISSUE_TEMPLATE/                 Issue template forms (v11; BD / TD / inbound)
│   ├── work-item.yml                       BD or TD entry form
│   ├── inbound.yml                         External-input entry form
│   └── config.yml                          Disables blank issues
├── skills/                                 Canonical skill library (30 skills) — distributed
│                                           to .claude/skills/, .codex/skills/, .gemini/skills/
│                                           at project creation by init-project.sh; not
│                                           present as a sub-directory in projects
├── docs/pack/                              Pack product docs shipped into each project
│   ├── HELP-FRAGMENT.md                    Per-project verb reference (v11; rendered by pack-help.sh)
│   ├── HELP-FRAGMENT-TRACKER.md            Shared tracker section (v11; byte-identical to pack root, DELTA L1)
│   ├── PM-CHAT.md                          PM chat startup and operating instructions
│   ├── PLATFORM-SKILLS.md                  Skill-selection matrix by project type
│   ├── PACK-FEEDBACK.md                    Upstream feedback log to Pack Chat
│   └── prompts/                            Per-agent prompt templates
│       ├── coder.md                        variants: standard, fix-cycle
│       ├── reviewer.md                     variant: standard
│       ├── tester.md, planner.md,          variants: standard
│       │   docs-researcher.md,
│       │   architect.md (variant: mid-phase),
│       │   auditor.md (variant: standard)
│       ├── grpc-schema.md, repo-ops.md     placeholders (no variants shipped)
│       └── pm-chat.md                      variants: kickoff, backlog-status-update,
│                                           generate-setup, generate-agent-kickoff
│                                           (directory guidance: see supporting-docs/METHODOLOGY.md
│                                            § Prompt Authoring Principles)
├── scripts/                                Build, test, validation scripts (15)
├── CLAUDE.md                               Claude context file (unified template; "Quick reference" addendum v11)
├── AGENTS.md                               Codex context file (unified template; "Quick reference" addendum v11)
├── GEMINI.md                               Gemini context file (unified template; "Quick reference" addendum v11)
├── agent-run.sh                            Agent launcher with per-tool flags
├── tracker.toml.example                    Tracker opt-in config template (v11)
├── .mcp.json.example                       MCP config template
├── .gitignore                              Gitignore for projects
└── (conditional: proto/, server/, pyproject.toml, pyrightconfig.json)

supporting-docs/                            Pack product docs (copied to or consumed by projects)
├── METHODOLOGY.md                          Universal project methodology (copied to project root)
├── INSTALL-PROCEDURES.md                   Procedures 5 / 5-C / 5-S / 7 (host for v10/v11 install steps)
├── CLI-PM-SETUP.md                         CLI PM chat daily usage reference
├── DEPENDENCIES.md                         Tool dependencies reference
├── SETUP_TEMPLATE.md                       Per-project setup template (PM chat fills in)
├── SETUP-NEW.md                            Guide for setting up a new project (v10)
├── SETUP-EXISTING.md                       Guide for adding the pack to an existing project (v10)
├── AGENT_KICKOFF_TEMPLATE.md               Architecture kickoff template
├── MERGE-STRATEGY.md                       Per-file customization-preservation matrix (v11)
├── MIGRATION-v10-to-v11.md                 Upgrade guide (v10.0 → v11.0)
├── MIGRATION-v9-to-v10.md                  Upgrade guide (v9.3 → v10.0)
└── MIGRATION-v8-to-v9.md                   Upgrade guide (historical; v8.x → v9.0)

maintenance-docs/                           Pack maintainer docs (design records, archives)
├── TOOL-COMPARISON.md                      Cross-tool capability reference
├── VERIFIED-NOTES.md                       Verified facts from official docs
├── RECOMMENDATIONS.md                      Practical recommendations for new projects
├── GEMINI-CLI-ANALYSIS.md                  Gemini CLI analysis (deprecated)
├── ANDROID-ANALYSIS.md                     Android support analysis (deprecated)
├── archive/                                Superseded design records, plans, verifications, audits (v9, v10, and earlier)
│   ├── V9-DESIGN.md                        v9 architecture design record
│   ├── V9-AUDIT-REPORT.md                  v9 audit report
│   ├── V10-DESIGN.md                       v10 architecture design record
│   ├── V10-IMPLEMENTATION-PLAN.md          v10 implementation plan
│   ├── V10-PREDESIGN.md, V10-DESIGN-PROCESS-PLAN.md
│   ├── V10-AUDIT-REPORT.md, V10-AUDIT-REPORT-2.md
│   ├── V10-PROMPT-STRUCTURE-{DESIGN,PLAN}.md
│   ├── V10-PHASE-3B-{DESIGN,PLAN}{,-v2}.md
│   ├── V10-PHASE-4-PLAN.md, V10-PHASE-4-VERIFICATION{,-PLAN}{,-v2}.md
│   ├── V10-F-{A,D,E-F-F,G}-{DESIGN,PLAN}.md  v10 feature designs and plans
│   └── v10-working/                        v10 working drafts (step-NN, phase-3 reviews, V10-DESIGN-2 drafts)
├── origins/                                Source material and chat transcripts
└── guides/                                 Per-version setup guides

xcode-companion-templates/                  Machine-level Xcode AI config (per Mac)
vscode-companion-templates/                 Machine-level VS Code config (per project)

.claude/agents/                             Pack-specific Claude agents (4)
.codex/agents/                              Pack-specific Codex agents (4)
.gemini/agents/                             Pack-specific Gemini agents (4)
.claude/skills/, .codex/skills/,            Pack agent skills (copied from project-template/skills/)
  .gemini/skills/

scripts/                                    Pack-level scripts
├── validate-pack.py                        CI structural validation (25 Checks; pack-internal)
├── init-project.sh                         Initialize the pack in a new or existing project (v10; --update mode v11)
├── migrate-v9-to-v10.sh                    v9.3 → v10.0 migration script (v10; frozen)
├── migrate-v10-to-v11.sh                   v10.0 → v11.0 migrator (v11; thin adapter on the BD-119 framework at lib/migrator-*.sh)
├── add-capability.sh                       Add a pack-supported capability to an existing project (v10)
├── pack-help.sh                            LCD shell help-verb (v11; renders HELP-FRAGMENT)
├── pack-tracker.sh                         Tracker — init / status / mirror-rebuild / disable / doctor / update-templates / enable-recommendations (v11)
├── tracker-migrate.sh                      Lower-level tracker forward/reverse wrapper (v11)
├── restore-from-backup.sh                  v9.3 → v10 backup restore (v10; legacy)
├── merge-{json,toml,trinity,platform-skills}.py   Migrator-only merge helpers (pack-internal)
└── lib/                                    Shared bash libraries
    ├── detect.sh                           Detection helpers (project class, language markers, surface)
    ├── three-way.sh                        4-case three-way classifier (BD-088 / migrators)
    ├── customization-preserve.sh           BD-088 customization-preservation orchestrator (v11)
    ├── customization-report.sh             Truthful migration report renderer (v11)
    ├── migrator-core.sh                    BD-119 N→N+1 migrator framework — sequencer + public API (v11)
    ├── migrator-stages.sh                  BD-119 framework — preflight / backup / dispatch / report stage helpers (v11)
    ├── migrator-manifest.sh                BD-119 framework — manifest parser + validator (v11)
    ├── recommendation.sh                   Inflection-point recommendation system (v11; D-19)
    ├── tracker-provider.sh                 TrackerProvider abstraction (v11; D-1)
    ├── tracker-provider-gh.sh              gh-CLI backend (v11; D-2)
    ├── tracker-{config,init,labels,errors,sidecar,mirror,agent-read}.sh   Tracker subsystem (v11)
    ├── tracker-migrate-{forward,reverse}.sh    Forward / reverse migration libs (v11; D-3 / D-8)
    └── template-{translations,version}.sh  Template freshness helpers (v11)

scripts/test-migrator-core.sh               BD-119 unit tests — public API surface (v11)
scripts/test-migrator-manifest.sh           BD-119 unit tests — manifest parser/validator (v11)
scripts/test-migrator-behavior-preservation.sh   BD-119 byte-equivalence harness vs. pre-refactor monolith (v11)

.github/workflows/                          GitHub Actions
└── validate-pack.yml                       Pack self-validation on every push

test-fixtures/                              Persistent baseline fixtures for tests + dog-food
                                            (built dirs are gitignored; recipe is committed)
├── README.md                               How fixtures are used + how to rebuild
├── build.sh                                Deterministic rebuild script (BD-113)
├── manifest.txt                            Expected git SHA per fixture
├── v10-minimal/                            Bare v10 install (gitignored)
├── v10-realistic-ot/                       Fake-OT shape (gitignored)
├── v11-flat-file/                          v11 client, no tracker (gitignored)
├── v11-tracker-on/                         v11 client + synthesized tracker.toml (gitignored)
└── existing-project-mid-dev/               In-progress Swift+Python+gRPC project, no pack files (gitignored; BD-115)

QUICKSTART.md                               Quick start router (three paths — NEW / EXISTING / MIGRATE)
OPTIONAL-FEATURES.md                        Tool settings for features and settings used with non-pack related functionality
HELP-FRAGMENT-PACK.md                       Pack-side verb reference (v11; rendered by pack-help.sh)
HELP-FRAGMENT-TRACKER.md                    Shared tracker section (v11; canonical; mirrored to project-template/docs/pack/)
tracker.toml.example                        Pack-side tracker config template (v11)
PACK-CHAT.md                                Pack CLI chat operating instructions
PACK-AGENTS.md                              Pack agent routing (includes invocation guide)
BACKLOG.md                                  Pack improvement backlog
CLAUDE.md                                   Pack repo Claude context (not a template; "Quick reference" addendum v11)
AGENTS.md                                   Pack repo Codex context (not a template; "Quick reference" addendum v11)
GEMINI.md                                   Pack repo Gemini context (not a template; "Quick reference" addendum v11)
README.md                                   This file
CHANGELOG.md                                Pack changelog
.github/ISSUE_TEMPLATE/                     Pack-side issue forms (v11)
└── work-item.yml, inbound.yml, config.yml
```

> Migration guides follow the naming convention `MIGRATION-vN-to-vM.md`.
> They always live in `supporting-docs/` and ship with the major version
> that introduces the destination pack version.

## Checking Out a Specific Version

```bash
git checkout v10       # Latest v10.x release
git checkout v7        # Older version (please don't do this for no reason)
git diff v8 v9         # See what changed between major versions
git log --oneline      # Full version history
```

## `main` Branch Policy

`main` always points to the latest released version. Each version is also
available as a git tag. Use tags for stable references in project documentation.

## License

The Optiquity AI Agent Config Pack is distributed under the
[Optiquity AI Agent Config Pack License](LICENSE.md) — a
**source-available** (not OSI-approved) license that allows free use
and modification with two notable conditions:

- The Pack must always be free wherever it is offered.
- If You distribute the Pack or a modification (in any form,
  including bundled into a paid product or service), You must also
  publish a free, publicly downloadable copy of that exact version
  with attribution to Optiquity, Inc.

See [`LICENSE.md`](LICENSE.md) for the complete terms, including
modification ownership, attribution requirements, and the conditions
governing forks.

## Contact
Email:       [config-pack@optiquity.com](mailto:config-pack@optiquity.com)
Web:         [Optiquity, Inc.](https://optiquity.com)

---

> Created by David H. Shane and formerly "DHS AI Agent Config Pack." Renamed
> at v10.0 to reflect ownership by Optiquity, Inc. The pack provides the same
> configuration files and workflows — the name change has no effect on
> functionality or migration paths.
