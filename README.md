# DHS AI Agent Config Pack

A versioned collection of Claude Code, OpenAI Codex, and Xcode AI agent
configuration files for Swift / Python / gRPC projects.

## What is this?

This pack provides per-project and machine-level configuration files that give
Claude Code, OpenAI Codex, and Xcode's built-in AI agents a shared, consistent
understanding of your projects — covering architecture rules, coding standards,
agent roles, skills, and shell scripts to validate agent output.

## Using the Config Pack

See [`QUICKSTART.md`](QUICKSTART.md) for full setup instructions (available from v6 onward).

## Version History

### Versioning convention
Major versions (v9, v10, …) mark large additions or breaking changes.
Minor versions (v8.0, v8.1, …) mark incremental improvements — doc updates,
new templates, prompt and workflow refinements. The bare major tag (e.g. `v8`)
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

## Repository Layout

```
├── apple-app-template/                     Template: iOS / macOS apps
├── xcode-companion-templates/              Machine-level Xcode AI config
├── vscode-companion-templates/             Machine-level VS Code config (v8+)
├── shared-docs/                            Reference notes
├── supporting-docs/                        Pack product docs (copied to or consumed by projects)
│   ├── METHODOLOGY.md                      Universal project methodology (v8+)
│   ├── PROMPT-TEMPLATES.md                 Agent prompt templates (v8+)
│   ├── PM-CHAT.md                          PM chat startup instructions template (v8.7+)
│   ├── CLI-PM-SETUP.md                     CLI PM chat daily usage reference (v8.7+)
│   ├── DEPENDENCIES.md                     Tool dependencies reference (v8.6+)
│   ├── SETUP_TEMPLATE.md                   New project setup template (v8+)
│   ├── AGENT_KICKOFF_TEMPLATE.md           Architecture kickoff template (v8+)
│   └── MIGRATION-v8-to-v9.md               Upgrade guide (v9)
├── maintenance-docs/                       Pack maintainer docs (design records, analysis, archives)
│   ├── origins/                            Source material and chat transcripts
│   ├── guides/                             Per-version setup guides (.docx)
│   ├── V9-DESIGN.md                        v9 architecture design record (v8.10+)
│   ├── TOOL-COMPARISON.md                  Cross-tool capability reference (v8.10+)
│   ├── GEMINI-CLI-ANALYSIS.md              Gemini CLI integration analysis (deprecated)
│   └── ANDROID-ANALYSIS.md                 Android support analysis (deprecated)
├── QUICKSTART.md                           Quick start (v6+)
├── PACK-CHAT.md                            Pack CLI chat startup instructions (v8.8+)
├── BACKLOG.md                              Pack improvement backlog (v8+, was V8-BACKLOG.md)
├── scripts/                                Pack-level scripts (CI validation)
├── .github/workflows/                      GitHub Actions (pack self-validation)
├── .mcp.json.example                       mcp-local-rag config template for pack repo (v8.8+)
└── CHANGELOG.md
```

## Checking Out a Specific Version

```bash
git checkout v8        # Latest
git checkout v7        # One version back
git diff v7 v8         # See exactly what changed between versions
git log --oneline      # Full version history
```

## Template Comparison

| Feature                    | apple-app | python-server | monorepo |
|----------------------------|-----------|---------------|---------|
| CLAUDE.md / AGENTS.md      | ✓         | ✓             | ✓       |
| METHODOLOGY.md (v8+, copy to project) | ✓ (copy from supporting-docs/) | ✓ (copy from supporting-docs/) | ✓ (copy from supporting-docs/) |
| agent-run.sh (v8.9+)       | ✓         | ✓             | ✓       |
| iOS 26 support (v7+)       | ✓         | —             | ✓       |
| grpc-swift-2 rules         | ✓         | —             | ✓       |
| grpc.aio rules             | —         | ✓             | ✓       |
| Proto scaffold (v6+)       | ✓         | ✓             | ✓       |
| apple-architect agent (v8) | ✓         | —             | ✓       |
| python-architect agent (v8)| —         | ✓             | ✓       |
| grpc-schema agent (v4+)    | ✓         | ✓             | ✓       |

## `main` Branch Policy

`main` always points to the latest released version. Each version is also
available as a git tag (`v1` through `v8`, and onward). Use tags for stable
references in project documentation.
