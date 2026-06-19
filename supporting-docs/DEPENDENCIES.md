# DEPENDENCIES.md — Tool Dependencies

This document lists all tools required or optionally used by the AI Agent Config Pack v11
unified template. Install required tools before running `bootstrap.sh` or `validate.sh`.

---

## CLI Tools (all projects)

### Claude Code CLI (required)
Agent runner and PM chat host for Claude Code workflows.
- Requires: Node.js 18+
- Install: https://docs.anthropic.com/en/docs/claude-code
- Verify: `claude --version`

### OpenAI Codex CLI (required for Codex workflows)
Agent runner and PM chat host for Codex workflows. Configured via `.codex/`.
- Install: https://github.com/openai/codex
- Verify: `codex --version`

### Antigravity CLI (required for Antigravity workflows)
Agent runner and PM chat host for Antigravity CLI (`agy`) workflows. Agent
definitions ship as a plugin bundle at
`.agents-plugin/optiquity-agents/agents/*.md` (16 role templates installed
once with `agy plugin install`). Uses `agent-run.sh` for invocation.
- Requires: Node.js 18+
- Install: see the Antigravity CLI docs at https://antigravity.google/docs
- Verify: `agy --version`

### Node.js 18+ (required)
Shared dependency for Claude Code CLI, Antigravity CLI, and mcp-local-rag.
- Install: https://nodejs.org/ or `brew install node`
- Verify: `node --version`

### Homebrew (required on macOS)
Package manager used to install most other tools listed here.
- Install: https://brew.sh
- Verify: `brew --version`

---

## Apple / Swift projects

### Xcode 26.3+ (required)
Includes the Swift compiler, xcodebuild, and the built-in AI coding agent.
- Install: Mac App Store or https://developer.apple.com/xcode/
- Verify: `xcodebuild -version`

### swift-format (optional)
Swift code formatter. Used by `scripts/format.sh`.
If not installed, `format.sh` warns and exits 0 — the build is not blocked.
- Install: `brew install swift-format`
- Verify: `swift-format --version`
- Reference: https://github.com/apple/swift-format

---

## Python Server Template

### uv (required)
Python package manager and virtual environment tool. Used by `bootstrap.sh` and `validate.sh`.
- Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Docs: https://docs.astral.sh/uv/
- Verify: `uv --version`

### ruff (required)
Python linter and formatter. Used by `format.sh` and `validate.sh`.
Installed automatically via `uv sync` from `pyproject.toml`.
- Manual install: `uv add --dev ruff`
- Verify: `ruff --version`
- Reference: https://docs.astral.sh/ruff/

### pyright (required)
Python static type checker. Used by `validate.sh`.
Installed automatically via `uv sync` from `pyproject.toml`.
- Manual install: `uv add --dev pyright`
- Verify: `pyright --version`
- Reference: https://github.com/microsoft/pyright

### pytest (required)
Python test runner. Used by `validate.sh`.
Installed automatically via `uv sync` from `pyproject.toml`.
- Manual install: `uv add --dev pytest`
- Verify: `pytest --version`
- Reference: https://docs.pytest.org/

---

## gRPC / Proto (all templates with a proto/ directory)

### buf (required)
Protocol Buffer linting and code generation. Used by `proto-gen.sh`, `bootstrap.sh`, and `validate.sh`.
- Install: `brew install bufbuild/buf/buf`
- Docs: https://buf.build/docs/installation
- Verify: `buf --version`

### swift-protobuf / protoc-gen-swift (required for Swift proto generation)
Swift Protobuf plugin. Used by `proto-gen.sh`.
- Install: `brew install swift-protobuf`
- Verify: `protoc-gen-swift --version`
- Reference: https://github.com/apple/swift-protobuf

### grpc-swift-2 / protoc-gen-grpc-swift (required for Swift gRPC generation)
Swift gRPC plugin. Used by `proto-gen.sh`.
- Install: `brew install grpc-swift` (if available) or build from source
- Reference: https://github.com/grpc/grpc-swift-2
- Verify: `which protoc-gen-grpc-swift` (must be on PATH)

---

## Quick Reference

| Tool | Required for | Install |
|---|---|---|
| Claude Code CLI | Claude workflows | https://docs.anthropic.com/en/docs/claude-code |
| Codex CLI | Codex workflows | https://github.com/openai/codex |
| Antigravity CLI | Antigravity workflows | https://antigravity.google/docs |
| Node.js 18+ | Claude CLI, Antigravity CLI, mcp-local-rag | https://nodejs.org/ |
| Homebrew | All (macOS) | https://brew.sh |
| Xcode 26.3+ | Apple projects | Mac App Store |
| swift-format | Apple (optional) | `brew install swift-format` |
| uv | Python projects | https://docs.astral.sh/uv/ |
| ruff | Python projects | `uv add --dev ruff` |
| pyright | Python projects | `uv add --dev pyright` |
| pytest | Python projects | `uv add --dev pytest` |
| buf | Proto/gRPC | `brew install bufbuild/buf/buf` |
| swift-protobuf | Swift gRPC | `brew install swift-protobuf` |
| grpc-swift-2 | Swift gRPC | https://github.com/grpc/grpc-swift-2 |
| mcp-local-rag | CLI PM chat (optional) | Auto via `npx -y mcp-local-rag` |
| gh CLI | Deferred tracker feature only (dormant) | `brew install gh` |
| gh-sub-issue | Deferred tracker feature only (dormant) | `gh extension install yahsan2/gh-sub-issue` |

---

## CLI tools (optional, per-feature)

### gh CLI (required only for the deferred tracker feature — dormant)

GitHub's official command-line tool. Used by the tracker abstraction
(`scripts/lib/tracker-provider-gh.sh`) to read and write GitHub Issues
when a project is in tracker mode. Tracker integration is DEFERRED
indefinitely and flat-file per-entry is the sole supported
mode, so `gh` is not needed for normal operation — flat-file
(`BACKLOG.md`) tracking requires no GitHub CLI. (The tracker code that
uses `gh` is retained dormant and test-covered for a future
resumption.)

- Install: `brew install gh` (macOS); see https://cli.github.com/ for
  Linux / Windows installers.
- Auth: `gh auth login` against the repo's GitHub account; minimum
  scopes are `repo` (issues read/write) plus `read:org` if the repo is
  in an organization.

### gh-sub-issue (required only for the deferred tracker feature — dormant)

`gh` extension that adds first-class sub-issue commands. The dormant
tracker code uses sub-issues to link phase-tasks to their parent BD.
Tracker integration is deferred; this extension is not needed
for flat-file operation.

- Install: `gh extension install yahsan2/gh-sub-issue`
- Verify: `gh sub-issue --help` exits 0.
- Reference: https://github.com/yahsan2/gh-sub-issue

See `docs/pack/OPTIONAL-FEATURES.md` § "Tracker integration (deferred)".

---

## CLI PM Chat (Optional)

These tools are only needed if using the Claude Code CLI as the PM chat session
instead of the Claude Desktop app. Setup is in `supporting-docs/SETUP-NEW.md` Step 10, Option B (Claude Code CLI).
For daily session management after setup, see `supporting-docs/CLI-PM-SETUP.md`.

### mcp-local-rag (required for CLI PM chat)
Local RAG server for semantic search over METHODOLOGY.md.
Runs entirely locally — no API keys required.
- Requires: Node.js 18+ (already required for Claude Code CLI)
- Install: Automatic via `npx -y mcp-local-rag` on first use (no separate install step)
- First ingest: Downloads embedding model (~90MB) automatically — takes 1-2 minutes
  once per machine, then works offline and instantly for all future ingests
- Update: `npx --prefer-online -y mcp-local-rag --help` (re-ingest docs after updating)
- Reference: https://github.com/shinpr/mcp-local-rag

### Disk space (for RAG index)
The RAG index for METHODOLOGY.md is small (under 5MB per project).
Stored in `.claude/rag-index/` within the project directory (gitignored).
