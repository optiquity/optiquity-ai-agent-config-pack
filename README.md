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

| Version | Date         | Key Additions |
|---------|--------------|---------------|
| v1      | Mar 6, 2026  | Initial pack: apple-app and monorepo templates, 5 agents, 3 skills |
| v2      | Mar 6, 2026  | repo-ops + docs-researcher agents; 8 new skills; expanded xcode-companion-templates |
| v3      | Mar 9, 2026  | Per-template .gitignore + README; streamlined to apple-app-template |
| v4      | Mar 9, 2026  | grpc-schema agent + skill; .codex agents converted to .toml |
| v5      | Mar 9, 2026  | python-server-template; apple-app-plus-python-server monorepo; xcode-companion-templates in pack |
| v6      | Mar 11, 2026 | Proto scaffold; QUICKSTART.md; error-handling skill; proto-gen.sh script |
| v7      | Mar 23, 2026 | iOS 26 / Xcode 26.3 API docs; sync-xcode-docs.sh; Apple-first dependency policy |
| v8      | Mar 29, 2026 | apple-architect rename; python-architect; METHODOLOGY.md; PROMPT-TEMPLATES.md; VS Code companion; LSP rules; OT content merge; availability guard fix |

## Repository Layout

```
├── apple-app-template/                     Template: iOS / macOS apps
├── python-server-template/                 Template: Python gRPC servers
├── apple-app-plus-python-server-template/  Template: monorepo (Apple + Python)
├── xcode-companion-templates/              Machine-level Xcode AI config
├── vscode-companion-templates/             Machine-level VS Code config (v8+)
├── shared-docs/                            Reference notes
│   └── ios26/                              ← gitignored; sync via sync-xcode-docs.sh
├── supporting-docs/                        Guides, best practices, origin documents
│   ├── origins/                            Chat transcripts from pack creation
│   ├── guides/                             Per-version setup guides (.docx)
│   ├── METHODOLOGY.md                      Universal project methodology (v8+)
│   ├── PROMPT-TEMPLATES.md                 Agent prompt templates (v8+)
│   ├── SETUP_TEMPLATE.md                   New project setup template (v8+)
│   ├── AGENT_KICKOFF_TEMPLATE.md           Architecture kickoff template (v8+)
│   ├── MIGRATION-v7-to-v8.md               Upgrade guide (v8+)
│   ├── GEMINI-CLI-ANALYSIS.md              Gemini CLI integration analysis (v8+)
│   └── ANDROID-ANALYSIS.md                 Android support analysis (v8+)
├── QUICKSTART.md                           Quick start (v6+)
├── BACKLOG.md                              Pack improvement backlog (v8+, was V8-BACKLOG.md)
├── sync-xcode-docs.sh                      iOS 26 doc sync script (v7+)
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
