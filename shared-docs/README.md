# AI agent config pack for Xcode 26.3, Claude, and Codex

This pack gives you a verified starting point for:

- separate GitHub repos per app
- Apple app repos using SwiftUI first, with UIKit or AppKit interop when needed
- SPM-first dependency policy
- cloud-first model routing with local fallback for lower-risk Codex work
- Swift 6 strict concurrency for new code, with pragmatic interop for legacy or third-party boundaries
- local development on macOS first, with future-friendly server guidance for macOS, Linux, and Windows

## Included template sets

- `apple-app-template/` - Apple app only
- `apple-app-plus-python-server-template/` - Apple app plus Python server in one repo
- `xcode-companion-templates/` - sample files and notes for Xcode's separate agent customization directories

## What is intentionally not hard-coded

These templates avoid hard-coding:

- your actual API keys or secrets
- your exact model names for Claude inside Xcode, because Xcode manages that selection in its UI
- project-specific MCP servers, because those vary a lot by repo and local tooling
- exact local-model wiring for Claude Code, because I could not verify first-party direct Claude Code support for Ollama or LM Studio from Anthropic's docs

## Recommended commit policy

Commit these:

- `CLAUDE.md`
- `AGENTS.md`
- `.claude/settings.json`
- `.claude/agents/**`
- `.claude/skills/**`
- `.codex/config.toml`
- `.codex/skills/**`
- optional example files like `.mcp.json.example` and `.claude/settings.local.example.json`

Do not commit these:

- `.claude/settings.local.json`
- real `.mcp.json` files if they contain local-only paths, tokens, or machine-specific settings
- any secret material in `.env`, `secrets/`, or service-account files

## Recommended next step

Use one template repo as your baseline. Once you have used it on a real project for a week, tighten the rules. Do not start with maximal automation everywhere.
