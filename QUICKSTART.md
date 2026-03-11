# AI Agent Config Pack v6 — Quick Start

This pack configures Claude Code, OpenAI Codex, and Xcode 26.3 to follow your project's
architecture rules, coding standards, and gRPC conventions automatically — without repeated prompting.

---

## Step 1 — Choose a template

| Your project | Use this template |
|---|---|
| iOS / iPadOS / macOS app only | `apple-app-template/` |
| Python server only | `python-server-template/` |
| Swift client + Python server in one repo | `apple-app-plus-python-server-template/` |

---

## Step 2 — Copy the template into your project root

```bash
cp -r apple-app-template/. /path/to/your/project/
```

> The trailing `/.` is required — it ensures hidden directories (`.claude/`, `.codex/`, `.gitignore`) are included.

---

## Step 3 — Edit CLAUDE.md and AGENTS.md

Minimum edits before using any agent:

1. Add your chosen architecture pattern (MVVM, TCA, MV, Coordinator, etc.).
2. Add your Python server framework if using the server or monorepo template.
3. Review the anti-patterns section and add any project-specific ones.

---

## Step 4 — Fix execute permissions and run bootstrap

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

---

## Step 5 — Fill in Xcode scheme (Apple templates only)

Open `scripts/validate.sh` and `scripts/test.sh`. Fill in the two variables at the top:

```bash
XCODE_SCHEME="YourAppName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
```

Find valid values: `xcodebuild -list` and `xcrun simctl list devices available`

---

## Step 6 — Install swift-format (Apple templates only)

```bash
brew install swift-format
```

`scripts/format.sh` warns and exits 0 if swift-format is not installed, so this is not blocking.

---

## Step 7 — Set up proto code generation (if using gRPC)

Install prerequisites:

```bash
brew install bufbuild/buf/buf          # buf CLI
brew install swift-protobuf            # protoc-gen-swift (Apple templates)
brew install grpc-swift                # protoc-gen-grpc-swift (Apple templates)
# Python: uv add grpcio-tools grpcio grpcio-status grpcio-reflection
```

Replace the example service definition in `proto/example/v1/example_service.proto` with your own,
then generate:

```bash
./scripts/proto-gen.sh
```

---

## Step 8 — Install Xcode companion files (once per Mac)

```bash
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/codex
cp xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp xcode-companion-templates/ClaudeAgentConfig/settings.json \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp xcode-companion-templates/Codex/AGENTS.md \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
cp xcode-companion-templates/Codex/config.toml \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```

Repeat on each Mac (MacBook Pro and Mac mini separately).

---

## Step 9 — Commit

```bash
git add -A && git status   # verify nothing sensitive is staged
git commit -m "Add AI agent configuration (v6)"
```

The `.gitignore` automatically excludes `.claude/settings.local.json`, `.mcp.json`,
and all generated Protobuf output.

---

## Common agent invocations

| Task | Command |
|---|---|
| Plan a feature before coding | `claude --agent planner "Plan [description]"` |
| Implement | `codex --agent coder "Implement [description]"` |
| Review code | `claude --agent reviewer "Review [file or module]"` |
| Design a gRPC service | `claude --agent grpc-schema "Design a service for [description]"` |
| Review a .proto change | `claude --agent grpc-schema "Review my changes to proto/[path]"` |
| Debug a build failure | `claude --agent coder "Debug: [error text]"` |
| Run all validation | `./scripts/validate.sh` |
| Generate gRPC code | `./scripts/proto-gen.sh` |

---

## Phase routing cheat sheet

| Phase | Default | Agent |
|---|---|---|
| Architecture / design | Claude Code | `ios-architect` or `planner` |
| API and schema design | Claude Code | `grpc-schema` |
| Planning | Claude Code | `planner` |
| Dependency evaluation | Claude Code | `docs-researcher` |
| Implementation | Codex | `coder` |
| Code review | Claude Code | `reviewer` |
| Testing | Codex | `tester` |
| Debugging | Claude Code | `coder` |
| Refactoring | Codex | `coder` |
| Repo operations / validation | Codex | `repo-ops` |

---

## What NOT to put in Git

The `.gitignore` handles these automatically — do not commit them:

- `.claude/settings.local.json` — machine-specific Claude Code permission overrides
- `.mcp.json` — local MCP server configuration (may contain paths or keys)
- `generated/swift/` and `server/src/generated/` — generated Protobuf/gRPC code
- `.buf/` — buf CLI cache

Commit everything else, including `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.codex/`, `scripts/`, `proto/`.

---

## Reference documents (not copied into project repos)

- `shared-docs/VERIFIED-NOTES.md` — what was verified from official docs and what was not
- `shared-docs/RECOMMENDATIONS.md` — practical next steps for each template
- `swift-python-best-practices-v3.md` — the full 206-item best practices reference
