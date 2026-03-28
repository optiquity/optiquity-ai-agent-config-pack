# AI Agent Config Pack v7 — Quick Start

This pack configures Claude Code, OpenAI Codex, and Xcode 26.3 to follow your project's
architecture rules, coding standards, and gRPC conventions automatically — without repeated prompting.

**New in v7:** iOS 26 API reference docs (`shared-docs/ios26/`), `sync-xcode-docs.sh` for keeping
them current, Apple-first dependency rules in Xcode companion files, and a project customization
reconciliation procedure (see bottom of this document).

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

## Step 4 — Copy scripts, fix permissions, and run bootstrap

The `scripts/` folder must be copied from the pack template into your project root if it isn't
there already. It is **not optional** — `agent-post-edit-check.sh` is wired into the Claude Code
hook and the Codex `post_edit_command`, and the other scripts are the primary way agents run
validation and formatting.

```bash
# If scripts/ is missing from your project (copy from the correct template):
cp -r /path/to/pack/apple-app-template/scripts/ /path/to/your/project/scripts/

# Make all scripts executable — required after every fresh clone
chmod +x scripts/*.sh

# Run bootstrap once per machine to resolve dependencies
./scripts/bootstrap.sh
```

**What each script does:**

| Script | Purpose | When to run |
|---|---|---|
| `bootstrap.sh` | Resolve SPM/Python dependencies. Run once per machine. | Manual, first checkout |
| `format.sh` | Format code (swift-format and/or ruff). Manual only — not in the auto-hook. | Manual or `repo-ops`, pre-commit |
| `test.sh` | Run the test suite only (no build step). | Manual or `repo-ops` |
| `validate.sh` | Full build + test suite. The primary quality gate. | Manual or `repo-ops`, pre-commit |
| `proto-gen.sh` | `buf lint` then `buf generate` after any `.proto` edit. | Manual or `grpc-schema` agent |
| `agent-post-edit-check.sh` | Automatic build check after every agent file edit. **Never call manually.** | Auto via Claude Code hook |

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

## Step 8 — Sync iOS 26 API reference docs (once per Mac, repeat after Xcode updates)

Run this from the pack root (not from any project repo):

```bash
./sync-xcode-docs.sh
```

This copies Apple's iOS 26 API documentation directly from the installed Xcode bundle into
`shared-docs/ios26/`. The `docs-researcher` agent reads these files when answering iOS 26 API
questions. Run again after any Xcode update.

If Xcode is not at `/Applications/Xcode.app`, override the path:

```bash
XCODE_APP=/path/to/Xcode.app ./sync-xcode-docs.sh
```

---

## Step 9 — Install Xcode companion files (once per Mac)

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
Replace v6 companion files if previously installed.

---

## Step 10 — Commit

```bash
git add -A && git status   # verify nothing sensitive is staged
git commit -m "Add AI agent configuration (v7)"
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
| iOS 26 API question | `claude --agent docs-researcher "How does [iOS 26 feature] work?"` |
| Run all validation | `./scripts/validate.sh` |
| Generate gRPC code | `./scripts/proto-gen.sh` |
| Sync iOS 26 docs after Xcode update | `./sync-xcode-docs.sh` (from pack root) |

---

## Phase routing cheat sheet

| Phase | Default | Agent |
|---|---|---|
| Architecture / design | Claude Code | `apple-architect` or `planner` |
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
- `shared-docs/ios26/` — iOS 26 / Xcode 26.3 API reference docs (sync via `sync-xcode-docs.sh`)
- `swift-python-best-practices-v3.md` — the full 206-item best practices reference

---

## Reconciling project customizations with a new pack version

When you upgrade existing projects from v6 (or earlier) to v7, do not copy template files
blindly — your project-level customizations must be preserved. Use this procedure:

### What changes between versions

v7 adds content to these files — it does not restructure or remove anything:

| File | What changed |
|---|---|
| `CLAUDE.md` (apple + monorepo) | New `## iOS 26 / Xcode 26.3 platform features` section added before `## Architecture rules` |
| `.claude/agents/docs-researcher.md` (apple + monorepo) | New `## iOS 26 / Xcode 26.3 API reference` block added after existing responsibilities |
| `.codex/agents/docs-researcher.toml` (apple + monorepo) | iOS 26 reference added to `developer_instructions` |
| Xcode companion `CLAUDE.md` | New `## iOS 26 / Xcode 26.3 platform features` section added before `## Design rules` |
| Xcode companion `AGENTS.md` | Same iOS 26 section added before `## Design rules` |
| `shared-docs/VERIFIED-NOTES.md` | Five new verified items added |

### Procedure for each existing project

**Step 1 — Identify your customizations.** Open your project's `CLAUDE.md` and note everything
you added after copying the template: architecture pattern, server framework, project-specific
anti-patterns, module names, team rules.

**Step 2 — Apply only the additive changes.** For each file in the table above, copy just the
new section from the v7 template into your project file at the same insertion point.
Do not replace the whole file.

For `CLAUDE.md` (apple or monorepo), insert this block between
`## Platform and stack defaults` and `## Architecture rules`:

```markdown
## iOS 26 / Xcode 26.3 platform features

- **Liquid Glass** is the current iOS 26 / macOS 26 design language for materials and visual
  effects. Use `.glassEffect()` and related modifiers rather than custom `Material` or
  `UIVisualEffectView` implementations. Evaluate Liquid Glass before reaching for any
  third-party visual effects library.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Treat it as the
  Apple-first option for any on-device language model need. Evaluate it before reaching for
  third-party ML inference frameworks. It does not require network access and respects App Sandbox.
- **Check Apple frameworks before third-party packages.** For any new capability, verify whether
  an iOS 26 Apple framework covers the need before adding a dependency.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads from
  `shared-docs/ios26/` before web search.
```

For `.claude/agents/docs-researcher.md`, append the `## iOS 26 / Xcode 26.3 API reference`
block from the v7 template after the existing `Responsibilities:` section.

**Step 3 — Verify the result compiles.** Run `./scripts/validate.sh` to confirm the project
still builds after the edit.

**Step 4 — Commit the update.** Use a commit message that distinguishes the pack update from
your project work, e.g.: `"Update AI agent config to v7 (iOS 26 API reference, Apple-first rules)"`

### What you should NOT overwrite

These files are safe to leave as-is in existing projects unless you want to adopt the new content:

- `AGENTS.md` — no changes from v7 template (unchanged from v6)
- All `.claude/skills/` files — unchanged from v6
- All `.claude/agents/` files except `docs-researcher.md` — unchanged
- All shell scripts — unchanged
- `.claude/settings.json`, `.codex/config.toml` — unchanged
- `proto/` files — project-specific, never overwrite

### Xcode companion files (machine-level, not in project repos)

Reinstall on each Mac after upgrading:

```bash
cp xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp xcode-companion-templates/Codex/AGENTS.md \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```

These are not project-specific, so replacement is safe — no customizations live there.
