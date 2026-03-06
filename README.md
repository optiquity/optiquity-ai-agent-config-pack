# DHS AI Agent Config Pack

A versioned collection of Claude Code, OpenAI Codex, and Xcode AI agent
configuration files for Swift / Python / gRPC projects.

## What is this?

This pack provides per-project and machine-level configuration files that give
Claude Code, OpenAI Codex, and Xcode's built-in AI agents a shared, consistent
understanding of your projects — covering architecture rules, coding standards,
agent roles, skills, and shell scripts to validate agent output.

See `QUICKSTART.md` (available from v6 onward) for full setup instructions.

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

## Repository Layout

```
├── apple-app-template/                     Template: iOS / macOS apps
├── python-server-template/                 Template: Python gRPC servers
├── apple-app-plus-python-server-template/  Template: monorepo (Apple + Python)
├── xcode-companion-templates/              Machine-level Xcode AI config
├── shared-docs/                            Reference notes
│   └── ios26/                              ← gitignored; sync via sync-xcode-docs.sh
├── supporting-docs/                        Guides, best practices, origin documents
│   ├── origins/                            Chat transcripts from pack creation
│   └── guides/                             Per-version setup guides (.docx)
├── QUICKSTART.md                           Quick start (v6+)
├── sync-xcode-docs.sh                      iOS 26 doc sync script (v7+)
└── CHANGELOG.md
```

## Checking Out a Specific Version

```bash
git checkout v7        # Latest
git checkout v6        # One version back
git diff v6 v7         # See exactly what changed between versions
git log --oneline      # Full version history
```

## Template Comparison

| Feature                    | apple-app | python-server | monorepo |
|----------------------------|-----------|---------------|---------|
| CLAUDE.md / AGENTS.md      | ✓         | ✓             | ✓       |
| iOS 26 support (v7+)       | ✓         | —             | ✓       |
| grpc-swift-2 rules         | ✓         | —             | ✓       |
| grpc.aio rules             | —         | ✓             | ✓       |
| Proto scaffold (v6+)       | ✓         | ✓             | ✓       |
| ios-architect agent        | ✓         | —             | ✓       |
| grpc-schema agent (v4+)    | ✓         | ✓             | ✓       |

## `main` Branch Policy

`main` always points to the latest released version. Each version is also
available as a git tag (`v1` through `v7`, and onward). Use tags for stable
references in project documentation.
