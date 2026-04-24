# DHS AI Agent Config Pack

A versioned collection of Claude Code, Codex CLI, Gemini CLI, and Xcode AI
agent configuration files for Swift / Python / gRPC projects.

## What is this?

This pack provides per-project and machine-level configuration files that give
Claude Code, Codex CLI, Gemini CLI, and Xcode's built-in AI agents a shared,
consistent understanding of your projects — covering architecture rules, coding
standards, agent roles, skills, and shell scripts to validate agent output.

## Using the Config Pack

See [`QUICKSTART.md`](QUICKSTART.md) for full setup instructions.

## Version History

### Versioning convention
Major versions (v9, v10, …) mark large additions or breaking changes.
Minor versions (v8.0, v8.1, …) mark incremental improvements — doc updates,
new templates, prompt and workflow refinements. The bare major tag (e.g. `v9`)
always points to the latest minor of that major version.

| Version | Date         | Key Additions |
|---------|--------------|---------------|
| v1      | Mar 6, 2026  | Initial pack: apple-app and monorepo templates, 5 agents, 3 skills |
| v2      | Mar 6, 2026  | repo-ops + docs-researcher agents; 8 new skills; expanded xcode-companion-templates |
| v3      | Mar 9, 2026  | Per-template .gitignore + README; streamlined to apple-app-template |
| v4      | Mar 9, 2026  | grpc-schema agent + skill; .codex agents converted to .toml |
| v5      | Mar 9, 2026  | python-server-template; apple-app-plus-python-server monorepo; xcode-companion-templates in pack |
| v6      | Mar 11, 2026 | Proto scaffold; QUICKSTART.md; error-handling skill; proto-gen.sh script |
| v7      | Mar 23, 2026 | iOS 26 / Xcode 26.3 API docs; sync-xcode-docs.sh; Apple-first dependency policy |
| v8.0    | Mar 29, 2026 | apple-architect rename; python-architect; METHODOLOGY.md; PROMPT-TEMPLATES.md; VS Code companion; LSP rules; OT content merge; availability guard fix |
| v8.1    | Apr 1, 2026  | Post-release patches: METHODOLOGY single-source, ios-architect rename fixes, PROMPT-TEMPLATES verification updates, PM chat rules, BD-020–023 |
| v8.2    | Apr 2, 2026  | Workflow 4 mid-phase architect trigger; BACKLOG/TODO management system; Cancelled/Deprecated item statuses; Template 4 non-prescriptive fix requirement |
| v8.3    | Apr 3, 2026  | Architect rejected-alternative documentation rule; Apple-platform pattern selection rules (type-erasure, AsyncStream, ViewModel navigation) |
| v8.4    | Apr 5, 2026  | Prompt Authoring Principles in METHODOLOGY.md and PROMPT-TEMPLATES.md |
| v8.5    | Apr 6, 2026  | Standardized agent output report headers across Templates 2–7 |
| v8.6    | Apr 6, 2026  | DEPENDENCIES.md; minor versioning convention; version string corrections |
| v8.7    | Apr 6, 2026  | CLI PM chat: PM-CHAT.md template, /pm-startup skill, CLI-PM-SETUP.md, mcp-local-rag integration |
| v8.8    | Apr 7, 2026  | Pack CLI chat: PACK-CHAT.md, /pack-startup skill; corrections to mcp-local-rag docs (QUICKSTART.md, DEPENDENCIES.md, CLI-PM-SETUP.md); METHODOLOGY.md version string fix |
| v8.9    | Apr 9, 2026  | agent-run.sh added to all three templates: read-only/write permission flags per agent, Claude Code and Codex CLI support |
| v8.10   | Apr 2026     | v9 planning: V9-DESIGN.md, TOOL-COMPARISON.md, BACKLOG.md (BD-025–031); v9-dev branch created |
| v9.0    | Apr 2026     | Unified template replaces 3 per-type templates; composable skill library (30 skills); three-tool parity (Claude/Codex/Gemini); architect agent unified; 7-cluster auditor agent; PACK-FEEDBACK loop; language-specific scripts with wrappers; GEMINI.md + PLATFORM-SKILLS.md + PACK-FEEDBACK.md; GitHub Actions CI validation; agents read Xcode docs directly from bundle |
| v9.1    | Apr 2026     | BD-038 dynamic skill management (Active skills line in context files, proactive skill gap detection at phase gates); BD-041 project initialization brief (design brief prerequisite in PM-CHAT.md) |
| v9.2    | Apr 2026     | BD-042 pack reference docs moved to docs/pack/; document locations section added to context files |
| v9.3    | Apr 2026     | BD-043 Gemini native subagent architecture (`.gemini/agents/` with YAML frontmatter); GEMINI.md stripped to project context only; agent-run.sh transparent `@agent-name` translation; full Gemini doc audit |

## Repository Layout

```
project-template/                           Unified project template (v10)
├── .claude/agents/                         Claude agent files (16 agents)
├── .codex/agents/                          Codex agent files (16 agents)
├── .gemini/agents/                         Gemini agent files (16 agents)
├── .codex/config.toml                      Codex config (agent registry, profiles)
├── .claude/settings.json                   Claude Code settings (permissions, hooks)
├── skills/                                 Canonical skill library (30 skills) — distributed
│                                           to .claude/skills/, .codex/skills/, .gemini/skills/
│                                           at project creation by init-project.sh; not
│                                           present as a sub-directory in projects
├── docs/pack/                              Pack product docs shipped into each project
│   ├── PM-CHAT.md                          PM chat startup and operating instructions
│   ├── PLATFORM-SKILLS.md                  Skill-selection matrix by project type
│   ├── PACK-FEEDBACK.md                    Upstream feedback log to Pack Chat
│   └── prompts/                            Per-agent prompt templates (new in v10)
│       ├── coder.md                        variants: standard, fix-cycle
│       ├── reviewer.md                     variant: standard
│       ├── tester.md, planner.md,          variants: standard
│       │   docs-researcher.md,
│       │   architect.md (variant: mid-phase),
│       │   auditor.md (variant: standard)
│       ├── grpc-schema.md, repo-ops.md     placeholders (no variants shipped)
│       ├── pm-chat.md                      variants: kickoff, backlog-status-update,
│       │                                   generate-setup, generate-agent-kickoff
│       └── PROMPT-AUTHORING.md             Directory guidance (not a per-agent file)
├── scripts/                                Build, test, validation scripts (15)
├── CLAUDE.md                               Claude context file (unified template)
├── AGENTS.md                               Codex context file (unified template)
├── GEMINI.md                               Gemini context file (unified template)
├── agent-run.sh                            Agent launcher with per-tool flags
├── .mcp.json.example                       MCP config template
├── .gitignore                              Gitignore for projects
└── (conditional: proto/, server/, pyproject.toml, pyrightconfig.json)

supporting-docs/                            Pack product docs (copied to or consumed by projects)
├── METHODOLOGY.md                          Universal project methodology (copied to project root)
├── CLI-PM-SETUP.md                         CLI PM chat daily usage reference
├── DEPENDENCIES.md                         Tool dependencies reference
├── SETUP_TEMPLATE.md                       Per-project setup template (PM chat fills in)
├── SETUP-NEW.md                            Guide for setting up a new project (v10)
├── SETUP-EXISTING.md                       Guide for adding the pack to an existing project (v10)
├── AGENT_KICKOFF_TEMPLATE.md               Architecture kickoff template
├── MIGRATION-v9-to-v10.md                  Upgrade guide (v9.3 → v10.0)
└── MIGRATION-v8-to-v9.md                   Upgrade guide (historical; v8.x → v9.0)

maintenance-docs/                           Pack maintainer docs (design records, archives)
├── V9-DESIGN.md                            v9 architecture design record (v10 annotated)
├── V10-DESIGN.md                           v10 architecture design record
├── V10-IMPLEMENTATION-PLAN.md              v10 implementation plan
├── TOOL-COMPARISON.md                      Cross-tool capability reference
├── VERIFIED-NOTES.md                       Verified facts from official docs
├── RECOMMENDATIONS.md                      Practical recommendations for new projects
├── GEMINI-CLI-ANALYSIS.md                  Gemini CLI analysis (deprecated)
├── ANDROID-ANALYSIS.md                     Android support analysis (deprecated)
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
├── validate-pack.py                        CI structural validation
├── init-project.sh                         Initialize the pack in a new or existing project (v10)
├── migrate-v9-to-v10.sh                    v9.3 → v10.0 migration script (v10)
├── merge-platform-skills.py                PLATFORM-SKILLS.md splice helper (v10)
├── merge-trinity.py                        Trinity file splice helper (v10)
└── lib/
    └── detect.sh                           Shared detection library sourced by the scripts above

.github/workflows/                          GitHub Actions
└── validate-pack.yml                       Pack self-validation on every push

QUICKSTART.md                               Quick start router (three paths — NEW / EXISTING / MIGRATE)
PACK-CHAT.md                                Pack CLI chat operating instructions
PACK-AGENTS.md                              Pack agent routing (includes invocation guide)
BACKLOG.md                                  Pack improvement backlog
CLAUDE.md                                   Pack repo Claude context (not a template)
AGENTS.md                                   Pack repo Codex context (not a template)
GEMINI.md                                   Pack repo Gemini context (not a template)
README.md                                   This file
CHANGELOG.md                                Pack changelog
```

> Migration guides follow the naming convention `MIGRATION-vN-to-vM.md`.
> They always live in `supporting-docs/` and ship with the major version
> that introduces the destination pack version.

## Checking Out a Specific Version

```bash
git checkout v8        # Latest v8.x release
git checkout v7        # Older version
git diff v8 v9         # See what changed between major versions
git log --oneline      # Full version history
```

## `main` Branch Policy

`main` always points to the latest released version. Each version is also
available as a git tag. Use tags for stable references in project documentation.
