# DEPENDENCIES.md — Tool Dependencies

This document lists all tools required or optionally used by the AI Agent Config Pack
scripts and templates. Install required tools before running `bootstrap.sh` or `validate.sh`.

---

## All Templates

### Claude Code CLI (required)
The primary agent runner for all CLI-based workflows.
- Requires: Node.js 18+
- Install: https://docs.anthropic.com/en/docs/claude-code
- Verify: `claude --version`

### Homebrew (required on macOS)
Package manager used to install most other tools listed here.
- Install: https://brew.sh
- Verify: `brew --version`

---

## Apple App Template

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

## OpenAI Codex Integration

### OpenAI Codex CLI (required for .codex/ workflows)
Configured via the `.codex/` directory in each template.
- Install: https://github.com/openai/codex
- Verify: `codex --version`

---

## Quick Reference

| Tool | Required for | Install |
|---|---|---|
| Claude Code CLI | All | https://docs.anthropic.com/en/docs/claude-code |
| Homebrew | All (macOS) | https://brew.sh |
| Xcode 26.3+ | Apple templates | Mac App Store |
| swift-format | Apple (optional) | `brew install swift-format` |
| uv | Python templates | https://docs.astral.sh/uv/ |
| ruff | Python templates | `uv add --dev ruff` |
| pyright | Python templates | `uv add --dev pyright` |
| pytest | Python templates | `uv add --dev pytest` |
| buf | Proto/gRPC | `brew install bufbuild/buf/buf` |
| swift-protobuf | Swift gRPC | `brew install swift-protobuf` |
| grpc-swift-2 | Swift gRPC | https://github.com/grpc/grpc-swift-2 |
| OpenAI Codex CLI | Codex workflows | https://github.com/openai/codex |
