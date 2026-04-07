# AI Agent Config Pack v8 — Setup and Usage Guide

**Version 8.0 | March 29, 2026**
For Claude Code · OpenAI Codex · Xcode 26.3
Targets: Swift 6 · macOS/iOS · Python 3.12+ · grpc-swift-2 · grpc.aio · buf CLI v2

> **This guide covers v8.0.** For changes introduced in v8.1 and later (including
> the CLI PM chat, PM-CHAT.md, and updated step numbering), see `CHANGELOG.md`.
> The current setup reference is `QUICKSTART.md` in the pack root.

> **Note:** Starting with v9, setup guides will be published in Markdown format only.
> The `.docx` format is retained for v8 for continuity with previous versions.

---

## What Is This Pack?

This pack provides per-project and machine-level configuration files that give Claude Code, OpenAI Codex, and Xcode 26.3's built-in AI agents a shared, consistent understanding of your Swift/Python/gRPC projects — covering architecture rules, coding standards, agent roles, skills, shell scripts, and project methodology.

**New in v8:** apple-architect rename, python-architect agent, METHODOLOGY.md, PROMPT-TEMPLATES.md, project generation templates, VS Code companion files, LSP rules, OT content improvements, and a critical availability guard fix for iOS 26 APIs.

---

## Part 1 — What Changed in v8

### Critical fix (BD-017)

The iOS 26 platform features section previously said "Use `.glassEffect()`" unconditionally. This was wrong for any project targeting below macOS 26 / iOS 26. v8 adds the required availability guard note to all affected files.

### Renamed: ios-architect → apple-architect (BD-001)

The agent was always intended to cover iOS, iPadOS, and macOS. The name now reflects this. All references updated. Update your saved prompts: use `--agent apple-architect` instead of `--agent ios-architect`.

### New: python-architect agent and skill (BD-006)

The python-server and monorepo templates now have a dedicated architect agent for Python server work — service layer design, grpc.aio patterns, repository boundaries, Pydantic placement, ML inference isolation. Invoke with `claude --agent python-architect`.

### New: Codex post-edit hook (BD-002)

`.codex/config.toml` now includes `post_edit_command = "./scripts/agent-post-edit-check.sh"` — Codex now fires the build-check hook after every file edit, matching Claude Code's existing behavior.

### New: METHODOLOGY.md (BD-008)

A 400-line reference document in `supporting-docs/`. Covers tool roles, standard project documents, agent roster, phase structure, 6 standard workflows, audit checkpoints, warning signs, and document authoring rules. Copy to your project root (see Step 2) and upload to Claude project knowledge so the PM chat can search it.

### New: PROMPT-TEMPLATES.md (BD-009)

14 ready-to-use agent prompt templates in `supporting-docs/`. Templates include PM chat kickoff, coder, reviewer, fix cycle, tester, docs-researcher, planner, BACKLOG/STATUS update, 4 audit types, and SETUP.md/AGENT_KICKOFF.md generation. Upload to Claude project knowledge alongside METHODOLOGY.md.

### New: Project generation templates (BD-007)

`SETUP_TEMPLATE.md` and `AGENT_KICKOFF_TEMPLATE.md` in `supporting-docs/`. The PM chat uses these to generate project-specific `SETUP.md` and `AGENT_KICKOFF.md` files for each new project.

### New: VS Code companion files (BD-011)

`vscode-companion-templates/` at the pack root contains `.vscode/settings.json` (Ruff, Pyright, format-on-save), `extensions.json` (10 recommended extensions), and `tasks.json` (wired to project scripts). For python-server and monorepo projects.

### Updated: CLAUDE.md and AGENTS.md (BD-003, BD-016)

All three templates: new Scripts section with full table. Apple and monorepo templates: LSP section, typed ID wrapper rule, ARCHITECTURE.md emphasis, entitlements rule, two new anti-patterns, `.gitignore` Xcode patterns merged, `settings.local.example.json` improved.

### Updated: Scripts (BD-004, BD-005)

`format.sh`: misleading hook comment removed. `validate.sh`, `test.sh`, `agent-post-edit-check.sh`: XCODE_SCHEME warnings upgraded to clear ⚠️ messages; `agent-post-edit-check.sh` now runs a real `xcodebuild build` when XCODE_SCHEME is set.

### Updated: QUICKSTART.md (BD-010)

Three new steps: Step 11 (Create Claude project, upload files to project knowledge), Step 12 (Start PM chat with kickoff template), Step 13 (Generate SETUP.md and AGENT_KICKOFF.md).

---

## Part 2 — Complete Setup Guide

### Step 1 — Choose a template

| Project type | Template |
|---|---|
| iOS / iPadOS / macOS app only | `apple-app-template/` |
| Python server only | `python-server-template/` |
| Swift client + Python server | `apple-app-plus-python-server-template/` |

### Step 2 — Copy template and METHODOLOGY.md into your project

```bash
cp -r apple-app-template/. /path/to/your/project/
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your/project/METHODOLOGY.md
```

The trailing `/.` ensures hidden directories (`.claude/`, `.codex/`) are included.
METHODOLOGY.md is not in the template directory — it must be copied separately.

### Step 3 — Edit CLAUDE.md, AGENTS.md, and METHODOLOGY.md

Minimum edits: add your architecture pattern (MVVM, TCA, etc.), Python framework if applicable, any project-specific anti-patterns. METHODOLOGY.md can be left as-is initially.

### Step 4 — Copy scripts, fix permissions, run bootstrap

```bash
cp -r /path/to/pack/apple-app-template/scripts/ /path/to/your/project/scripts/
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

Scripts must be copied manually — they are not optional infrastructure.

### Step 5 — Fill in Xcode scheme (Apple templates only)

Open `scripts/validate.sh` and `scripts/test.sh` and set:

```bash
XCODE_SCHEME="YourAppName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
```

Until these are set, xcodebuild steps are skipped and a ⚠️ warning is printed.

### Step 6 — Install swift-format (Apple templates only)

```bash
brew install swift-format
```

`format.sh` warns and exits 0 if not installed — not blocking.

### Step 7 — Set up proto code generation (if using gRPC)

```bash
brew install bufbuild/buf/buf
brew install swift-protobuf
brew install grpc-swift
# Python: uv add grpcio-tools grpcio grpcio-status
```

Run after any `.proto` change: `./scripts/proto-gen.sh`

### Step 8 — Sync iOS 26 API reference docs (once per Mac, repeat after Xcode updates)

```bash
./sync-xcode-docs.sh
```

Run from the pack root. Requires Xcode 26.3 installed.

### Step 9 — Install Xcode companion files (once per Mac)

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

Replace v7 companion files if previously installed.

### Step 10 — Commit

```bash
git add -A && git status
git commit -m "Add AI agent configuration (v8)"
```

### Step 11 — Create the app's Claude project

1. claude.ai → Projects → New Project
2. Connect GitHub repo via GitHub connector
3. Upload to Project Knowledge:
   - `METHODOLOGY.md` (from your project repo root — copied there in Step 2)
   - `supporting-docs/PROMPT-TEMPLATES.md` (from the pack)

### Step 12 — Start the PM chat

Open a new chat in the Claude project. Paste Template 1 (PM Chat Kickoff Prompt) from `PROMPT-TEMPLATES.md` with all placeholders filled in.

### Step 13 — Generate SETUP.md and AGENT_KICKOFF.md

Ask the PM chat to generate these using Templates 13 and 14 from `PROMPT-TEMPLATES.md`. Commit the results to the project repo, then run the architecture kickoff:

```bash
claude --agent apple-architect
# Paste the full contents of AGENT_KICKOFF.md as your first message
```

---

## Part 3 — Migrating from v7 to v8

See `supporting-docs/MIGRATION-v7-to-v8.md` for the complete upgrade guide. Summary:

**Safe to replace:** Xcode companion files, scripts, `.codex/config.toml`

**Merge manually (preserve project customizations):** `CLAUDE.md`, `AGENTS.md`, `.gitignore`

**Agent rename:** `ios-architect` → `apple-architect` (file rename + `config.toml` + routing tables)

**New files to add:** Copy `supporting-docs/METHODOLOGY.md` to your project root; upload `METHODOLOGY.md` + `PROMPT-TEMPLATES.md` to Claude project knowledge

---

## Part 4 — Agent Reference

| Agent | Templates | Purpose |
|---|---|---|
| `apple-architect` | Apple, monorepo | Apple platform architecture design (iOS, iPadOS, macOS) |
| `python-architect` | Python, monorepo | Python server architecture design |
| `planner` | All | Task breakdown, sequencing, risk analysis |
| `coder` | All | Implementation, bug fixes, refactors |
| `reviewer` | All | Code review, correctness, concurrency |
| `tester` | All | Test strategy, coverage analysis |
| `docs-researcher` | All | API verification, documentation audit |
| `grpc-schema` | All | Proto3 schema design and review |
| `repo-ops` | All | Git operations, script runs, housekeeping |

### Phase routing defaults

| Phase | Default | Agent |
|---|---|---|
| Architecture / design (Swift) | Claude Code | `apple-architect` or `planner` |
| Architecture / design (Python) | Claude Code | `python-architect` or `planner` |
| API and schema design | Claude Code | `grpc-schema` |
| Planning | Claude Code | `planner` |
| Dependency evaluation | Claude Code | `docs-researcher` |
| Implementation | Codex | `coder` |
| Code review | Claude Code | `reviewer` |
| Testing | Codex | `tester` |
| Debugging | Claude Code | `coder` |
| Refactoring | Codex | `coder` |
| Repo operations | Codex | `repo-ops` |

---

## Part 5 — Scripts Reference

| Script | Purpose | When to run |
|---|---|---|
| `bootstrap.sh` | Resolve dependencies | Once per machine |
| `format.sh` | Format code (swift-format / ruff) | Manual, pre-commit |
| `test.sh` | Run test suite only | Manual or `repo-ops` |
| `validate.sh` | Full build + tests | Manual or `repo-ops`, pre-commit |
| `proto-gen.sh` | `buf lint` + `buf generate` | After any `.proto` edit |
| `agent-post-edit-check.sh` | Auto build-check | Never manually — fires via hook |
| `sync-xcode-docs.sh` | Sync iOS 26 API docs from Xcode | After Xcode updates (pack root) |

---

## Part 6 — New Project Workflow (v8)

1. Create GitHub repo and Xcode project
2. Copy pack template (`cp -r template/. project/`) and METHODOLOGY.md (`cp supporting-docs/METHODOLOGY.md project/`)
3. `chmod +x scripts/*.sh` and `./scripts/bootstrap.sh`
4. Edit `CLAUDE.md` and `AGENTS.md` with project-specific rules
5. Commit initial config
6. Create Claude project, connect GitHub repo, upload `METHODOLOGY.md` + `PROMPT-TEMPLATES.md` to project knowledge
7. Start PM chat with kickoff prompt (Template 1 from `PROMPT-TEMPLATES.md`)
8. Use PM chat to generate `SETUP.md` (Template 13) and `AGENT_KICKOFF.md` (Template 14)
9. Commit `SETUP.md` and `AGENT_KICKOFF.md`
10. Run architect agent with `AGENT_KICKOFF.md` → produces `ARCHITECTURE.md` + stubs
11. PM chat guides all subsequent phases

---

*AI Agent Config Pack v8 · March 29, 2026 · Swift 6 · grpc-swift-2 · grpc.aio · buf CLI v2 · Xcode 26.3*
