# AI Agent Config Pack v8 — Quick Start

This pack configures Claude Code, OpenAI Codex, and Xcode 26.3 to follow your project's
architecture rules, coding standards, and gRPC conventions automatically — without repeated prompting.

**New in v8:** `apple-architect` rename, `python-architect` agent, `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`,
project generation templates, VS Code companion files, LSP rules, OT content improvements,
availability guard fix for iOS 26 APIs, and Codex post-edit hook. See `CHANGELOG.md` for the
full list.

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

Then copy `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, and `PM-CHAT.md` separately from `supporting-docs/` — they are not included in the template directory:

```bash
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your/project/METHODOLOGY.md
cp /path/to/pack/supporting-docs/PROMPT-TEMPLATES.md /path/to/your/project/PROMPT-TEMPLATES.md
cp /path/to/pack/supporting-docs/PM-CHAT.md /path/to/your/project/PM-CHAT.md
```

> `PM-CHAT.md` contains `[PROJECT_NAME]` as a placeholder. The PM chat fills this
> in and commits the file during the kickoff conversation — no manual editing needed.

---

## Step 3 — Edit CLAUDE.md, AGENTS.md, and METHODOLOGY.md

Minimum edits before using any agent:

1. Add your chosen architecture pattern (MVVM, TCA, MV, Coordinator, etc.) to `CLAUDE.md` and `AGENTS.md`.
2. Add your Python server framework if using the server or monorepo template.
3. Review the anti-patterns section and add any project-specific ones.
4. `METHODOLOGY.md` can be left as-is initially — edit it later if project-specific notes are needed.

---

## Step 4 — Copy scripts and agent-run.sh, fix permissions, and run bootstrap

The `scripts/` folder and `agent-run.sh` must be copied from the pack template into your project.
`scripts/` is **not optional** — `agent-post-edit-check.sh` is wired into the Claude Code hook and
the Codex `post_edit_command`, and the other scripts are the primary way agents run validation and
formatting. `agent-run.sh` goes in the **project root** and is how you launch agents day-to-day.

```bash
# If scripts/ is missing from your project (copy from the correct template):
cp -r /path/to/pack/apple-app-template/scripts/ /path/to/your/project/scripts/

# Copy agent-run.sh to the project root:
cp /path/to/pack/apple-app-template/agent-run.sh /path/to/your/project/agent-run.sh

# Make everything executable — required after every fresh clone
chmod +x scripts/*.sh agent-run.sh

# Run bootstrap once per machine to resolve dependencies
./scripts/bootstrap.sh
```

**What each script does:**

| Script | Location | Purpose | When to run |
|---|---|---|---|
| `agent-run.sh` | Project root | Launch any agent with correct CLI flags. See `./agent-run.sh --help`. | Human only |
| `bootstrap.sh` | `scripts/` | Resolve SPM/Python dependencies. Run once per machine. | Manual, first checkout |
| `format.sh` | `scripts/` | Format code (swift-format and/or ruff). Manual only — not in the auto-hook. | Manual or `repo-ops`, pre-commit |
| `test.sh` | `scripts/` | Run the test suite only (no build step). | Manual or `repo-ops` |
| `validate.sh` | `scripts/` | Full build + test suite. The primary quality gate. | Manual or `repo-ops`, pre-commit |
| `proto-gen.sh` | `scripts/` | `buf lint` then `buf generate` after any `.proto` edit. | Manual or `grpc-schema` agent |
| `agent-post-edit-check.sh` | `scripts/` | Automatic build check after every agent file edit. **Never call manually.** | Auto via Claude Code hook |

---

## Step 5 — Fill in Xcode scheme and source directories (Apple templates only)

Open `scripts/validate.sh` and `scripts/test.sh`. Fill in these variables at the top:

```bash
XCODE_SCHEME="YourAppName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
# For macOS-only projects use: XCODE_DESTINATION="platform=macOS"
```

Find valid values: `xcodebuild -list` and `xcrun simctl list devices available`

**Also set the same values in `.claude/settings.json`** — the `env` block must contain them
so the automatic post-edit hook (`agent-post-edit-check.sh`) can read them. Setting them
only in `validate.sh` is not enough: the hook runs in a separate process and reads from
the environment, not from inside the script.

```json
"env": {
    "AGENT_CAPABILITIES": "...",
    "XCODE_SCHEME": "YourAppName",
    "XCODE_DESTINATION": "platform=iOS Simulator,name=iPhone 16,OS=latest"
}
```

**Also set `SWIFT_SOURCE_DIRS` in `scripts/format.sh`** if your project uses an
Xcode-generated directory layout (e.g. `MyApp/` and `MyAppTests/`) rather than SPM's
`Sources/` and `Tests/`. Leave it empty to use the find-all-swift-files fallback.

```bash
SWIFT_SOURCE_DIRS=""   # e.g. "MyApp MyAppTests" for Xcode-generated layout
```

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
git commit -m "Add AI agent configuration (v8)"
```

The `.gitignore` automatically excludes `.claude/settings.local.json`, `.mcp.json`,
and all generated Protobuf output.

---

## Step 11 — Set up the PM chat

The PM chat is your project manager for the entire project lifetime. It generates
all agent prompts, receives agent output for analysis, and makes all architectural
and planning decisions. It never writes code — that is the job of CLI agents.

You have two interface options. The methodology, rules, and procedures are identical
in both. Pick one as your primary PM chat for this project.

> **Using the Claude Desktop app alongside the CLI:**
> Regardless of which mode you pick as your PM chat, the Claude Desktop app is always
> available for side investigations and research — API exploration, architectural
> discussions, one-off analysis. When a Desktop app session produces something
> actionable, ask it to generate a briefing prompt and paste that into your PM chat
> at the start of the next session. Never run two PM chats simultaneously for the
> same project.

---

### Option A — Claude Desktop app

Best when: you prefer a persistent chat interface with GitHub connector search,
and are comfortable using Desktop Commander for small file writes.

**Step 11A — Create the Claude project**

1. Go to claude.ai → Projects → New Project
2. Name it after your app (e.g., "MyApp — PM")
3. Connect your GitHub repo via the GitHub connector
4. Sync the connector — `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, and `PM-CHAT.md`
   (all copied to your project repo in Step 2) will be searchable after sync.
   No manual file upload needed.

**Step 11B — Start the PM chat**

Open a new chat in your Claude project. Paste **Template 1 — PM Chat Kickoff Prompt**
from `PROMPT-TEMPLATES.md` with all [PLACEHOLDERS] filled in.

The PM chat will confirm it can see your project documents, fill in and commit
`PM-CHAT.md`, and tell you what to do next.

*Both options continue at Step 12 below.*

---

### Option B — Claude Code CLI

Best when: you want a non-blocking terminal session with native file and git access,
or you work across multiple machines and want git as the authoritative memory.

**Step 11C — Verify prerequisites (one-time per machine)**

```bash
claude --version      # must be installed — see https://docs.anthropic.com/en/docs/claude-code
node --version        # must be v18 or higher — brew install node
```

**Step 11D — First ingest note (mcp-local-rag)**

No action needed here. The embedding model (~90MB) downloads automatically the
first time you run an ingest command inside the CLI session (Step 11F). This takes
1-2 minutes once per machine, then works offline and instantly for all future
ingests. Nothing to install or pre-warm in advance.

**Step 11E — Configure mcp-local-rag for this project**

```bash
cd ~/Developer/YourProject
cp .mcp.json.example .mcp.json
```

Edit `.mcp.json` — the only value you need to change is `BASE_DIR` in the
`local-rag` entry. Set it to the absolute path of your project directory.
Leave the `xcode` entry exactly as it was in `.mcp.json.example`:

```json
"local-rag": {
  "command": "npx",
  "args": ["-y", "mcp-local-rag"],
  "env": {
    "BASE_DIR": "/Users/yourname/Developer/YourProject",
    "DB_PATH": "./.claude/rag-index",
    "CACHE_DIR": "./.claude/rag-cache"
  }
}
```

`.mcp.json` is gitignored — never commit it.

**Step 11F — Start the session, name it, and ingest reference docs**

```bash
cd ~/Developer/YourProject
git pull
claude
```

Once in the session, run these in order:

```
/rename yourproject-pm
Ingest METHODOLOGY.md into the RAG index
Ingest PROMPT-TEMPLATES.md into the RAG index
```

Ingestion takes a few seconds per file and only needs to be done once per machine
(or when the pack version changes and those files are updated).

**Step 11G — Run the startup check and complete kickoff**

```
/pm-startup
```

Review the startup report. Then paste **Template 1 — PM Chat Kickoff Prompt**
from `PROMPT-TEMPLATES.md` with all [PLACEHOLDERS] filled in.

The PM chat will fill in and commit `PM-CHAT.md` as part of this first session.

> **Daily sessions:** Resume with `claude --resume yourproject-pm` from the project
> directory. Run `/pm-startup` only when starting fresh, after a long gap, or after
> compaction. For cross-machine workflow and troubleshooting see
> `supporting-docs/CLI-PM-SETUP.md`.

*Both options continue at Step 12 below.*

---

## Step 12 — Generate SETUP.md and AGENT_KICKOFF.md

Ask the PM chat to generate these using **Templates 13 and 14** from `PROMPT-TEMPLATES.md`.
The PM chat reads the templates and fills in all values from your planning conversation.

The resulting files go in your project repo root:
- `SETUP.md` — step-by-step setup guide for this specific project on any machine
- `AGENT_KICKOFF.md` — architecture phase kickoff prompt for the architect agent

Commit both files.

---

## Step 13 — Run the architecture kickoff

```bash
cd ~/Developer/YourProject
./agent-run.sh claude --agent apple-architect   # or python-architect for Python projects
# Paste the full contents of AGENT_KICKOFF.md as your first message
```

---

## Common agent invocations

Use `./agent-run.sh` to launch any agent — it automatically applies the correct CLI flags for
read-only agents (permission bypass, git write block) and passes everything through for write
agents. Direct CLI invocation still works for one-off use; `agent-run.sh` ensures consistency
across the team. Run `./agent-run.sh --help` for the full agent list and flag details.

| Task | Command |
|---|---|
| Plan a feature before coding | `./agent-run.sh claude --agent planner "Plan [description]"` |
| Implement | `./agent-run.sh codex --agent coder "Implement [description]"` |
| Review code | `./agent-run.sh claude --agent reviewer "Review [file or module]"` |
| Design a gRPC service | `./agent-run.sh claude --agent grpc-schema "Design a service for [description]"` |
| Review a .proto change | `./agent-run.sh claude --agent grpc-schema "Review my changes to proto/[path]"` |
| Debug a build failure | `./agent-run.sh claude --agent coder "Debug: [error text]"` |
| iOS 26 API question | `./agent-run.sh claude --agent docs-researcher "How does [iOS 26 feature] work?"` |
| Run all validation | `./scripts/validate.sh` |
| Generate gRPC code | `./scripts/proto-gen.sh` |
| Sync iOS 26 docs after Xcode update | `./sync-xcode-docs.sh` (from pack root) |

---

## Phase routing cheat sheet

| Phase | Default | Agent |
|---|---|---|
| Architecture / design | Claude Code | `apple-architect` or `planner` (Swift); `python-architect` or `planner` (Python) |
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

Commit everything else, including `CLAUDE.md`, `AGENTS.md`, `agent-run.sh`, `.claude/`, `.codex/`, `scripts/`, `proto/`.

---

## Reference documents (not copied into project repos)

- `shared-docs/VERIFIED-NOTES.md` — what was verified from official docs and what was not
- `shared-docs/RECOMMENDATIONS.md` — practical next steps for each template
- `shared-docs/ios26/` — iOS 26 / Xcode 26.3 API reference docs (sync via `sync-xcode-docs.sh`)
- `swift-python-best-practices-v3.md` — the full 206-item best practices reference
- `METHODOLOGY.md` (in each project repo) — full methodology reference; see **Part 7 —
  BACKLOG and TODO Management** for deferral comment format, BACKLOG item format, and
  the four PM chat procedures (phase gate check, post-session processing, orphan audit,
  resolution)

---

## Upgrading an existing project to a new pack version

When upgrading an existing project, do not copy template files blindly — your
project-level customizations must be preserved.

For v7 → v8 upgrades, see the complete step-by-step instructions in:
**`supporting-docs/MIGRATION-v7-to-v8.md`**

That guide covers all 15 change categories in v8, organized by severity, with exact
text to insert, files to rename, and verification steps. It is self-contained — you
do not need to open any other file to complete the migration.

**Summary of v8 change scope:**
- Critical: `scripts/` directory, `post_edit_command`, `XCODE_SCHEME` env export
- High: `ios-architect` → `apple-architect` rename, `settings.local.example.json`
- Medium: `METHODOLOGY.md`, Scripts section in CLAUDE.md/AGENTS.md, `.gitignore` additions
- New files: `python-architect` agent (Python/monorepo only), VS Code companion files

For upgrades from versions earlier than v7, apply v7 changes first, then v8.
