# AI Agent Config Pack v9 — Quick Start

This pack configures Claude Code, Codex CLI, Gemini CLI, and Xcode 26.3 to follow your
project's architecture rules, coding standards, and conventions automatically — without
repeated prompting.

**New in v9:** Unified template (replaces three per-project-type templates), composable
skill library (30 skills), three-tool parity (Claude/Codex/Gemini), 7-cluster auditor
agent, PACK-FEEDBACK loop, platform-agnostic agents with skill-driven platform knowledge.
See `CHANGELOG.md` for the full list.

---

## Step 1 — Copy the unified template into your project root

v9 uses a single unified template for all project types. Copy it:

```bash
cp -r /path/to/pack/project-template/. /path/to/your/project/
```

> The trailing `/.` is required — it ensures hidden directories (`.claude/`, `.codex/`, `.gitignore`) are included.

Then copy the supporting docs into `docs/pack/` (not included in the template):

```bash
cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your/project/docs/pack/METHODOLOGY.md
cp /path/to/pack/supporting-docs/PROMPT-TEMPLATES.md /path/to/your/project/docs/pack/PROMPT-TEMPLATES.md
```

Then create the project docs and reference docs directories:

```bash
mkdir -p /path/to/your/project/docs/project
mkdir -p /path/to/your/project/docs/reference
```

> `docs/pack/` already exists from the template copy — it contains `PM-CHAT.md`,
> `PACK-FEEDBACK.md`, and `PLATFORM-SKILLS.md`. `PM-CHAT.md` and `PACK-FEEDBACK.md`
> have `[PROJECT_NAME]` placeholders — the PM chat fills them in during kickoff.
> `GEMINI.md`, `CLAUDE.md`, and `AGENTS.md` are in the project root (tool convention).
>
> `docs/project/` is where project state files go: `ARCHITECTURE.md`,
> `IMPLEMENTATION_PLAN.md`, `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` — created
> during the planning conversation.
>
> `docs/reference/` is for project-specific user-facing documentation (how-to
> guides, API references) — create files here as needed.

## Step 2 — Remove conditional files you don't need

The template includes files for all project types. Remove what doesn't apply:

| Your project | Remove |
|---|---|
| Swift-only (no Python, no gRPC) | `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/` |
| Swift + gRPC (no Python) | `pyproject.toml`, `pyrightconfig.json`, `server/` |
| Python-only (no Swift, no gRPC) | `proto/` |
| Python + gRPC | Nothing to remove |
| Swift + Python + gRPC (monorepo) | Nothing to remove |

---

## Step 3 — Fill in context files (CLAUDE.md, AGENTS.md, GEMINI.md)

All three context files have `[PLACEHOLDER]` and `[CONDITIONAL]` sections.
Minimum edits before using any agent:

1. Fill in `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]` in all three files.
2. Fill in `[PLATFORM_DEFAULTS]` for your project type (examples in the HTML comments).
3. Fill in or remove `[CONDITIONAL]` sections — delete sections that don't apply
   (e.g., remove the iOS 26 section for a Python-only server).
4. Fill in `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`,
   `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]` from
   the loaded skills. The PM chat does this during kickoff using `PLATFORM-SKILLS.md`.
5. `METHODOLOGY.md` can be left as-is initially.

---

## Step 4 — Fix permissions, distribute skills, and run bootstrap

Scripts and `agent-run.sh` are already in the template (copied in Step 1). Fix permissions
and run bootstrap:

```bash
# Make everything executable — required after every fresh clone
chmod +x agent-run.sh scripts/*.sh

# Distribute skills to each tool's expected location
./scripts/bootstrap.sh
```

`bootstrap.sh` detects which languages are present (Swift, Python, or both) and:
- Resolves language-specific dependencies (SPM for Swift, uv for Python)
- Copies `skills/*/SKILL.md` → `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`

See the Scripts table in `CLAUDE.md` for the full script inventory (16 entries).

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

## Step 8 — Install Xcode companion files (Apple projects only, once per Mac)

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

## Step 9 — Commit

```bash
git add -A && git status   # verify nothing sensitive is staged
git commit -m "Add AI agent configuration (v9)"
```

The `.gitignore` automatically excludes `.claude/settings.local.json`, `.mcp.json`,
and all generated Protobuf output.

---

## Step 10 — Set up the PM chat

> **Prerequisite: design brief.** Before starting the PM chat, you need a design
> brief covering at minimum: target platform(s), primary language(s), any known
> external APIs or services, and the project's definition of done for MVP. If you
> don't have one, produce it in a separate conversation first (a Claude Web side
> chat, a Gemini CLI session, or any other workspace). The PM chat consumes a
> design brief — it does not author one. See `PM-CHAT.md` § "Before starting a
> new project" for details.

The PM chat is your project manager for the entire project lifetime. It generates
all agent prompts, receives agent output for analysis, and makes all architectural
and planning decisions. It never writes code — that is the job of CLI agents.

You have three interface options. The methodology, rules, and procedures are
identical in all three. Pick one as your primary PM chat for this project.
See `PM-CHAT.md` (in the project root, copied from template) for full startup
procedures, behavioral rules, and cross-tool switching instructions.

> **Never run two PM chats simultaneously for the same project.** Pick one tool
> as your primary PM chat. The others are available for side investigations.

---

### Option A — Claude Desktop app

Best when: you prefer a persistent chat interface with GitHub connector search,
and are comfortable using Desktop Commander for small file writes.

**Step 10A — Create the Claude project**

1. Go to claude.ai → Projects → New Project
2. Name it after your app (e.g., "MyApp — PM")
3. Connect your GitHub repo via the GitHub connector
4. Sync the connector — `METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, and `PM-CHAT.md`
   (all copied to your project repo in Step 2) will be searchable after sync.
   No manual file upload needed.

**Step 10B — Start the PM chat**

Open a new chat in your Claude project. Paste **Template 1 — PM Chat Kickoff Prompt**
from `PROMPT-TEMPLATES.md` with all [PLACEHOLDERS] filled in.

The PM chat will confirm it can see your project documents, fill in and commit
`PM-CHAT.md`, and tell you what to do next.

*Both options continue at Step 11 below.*

---

### Option B — Claude Code CLI

Best when: you want a non-blocking terminal session with native file and git access,
or you work across multiple machines and want git as the authoritative memory.

**Step 10C — Verify prerequisites (one-time per machine)**

```bash
claude --version      # must be installed — see https://docs.anthropic.com/en/docs/claude-code
node --version        # must be v18 or higher — brew install node
```

**Step 10D — First ingest note (mcp-local-rag)**

No action needed here. The embedding model (~90MB) downloads automatically the
first time you run an ingest command inside the CLI session (Step 10F). This takes
1-2 minutes once per machine, then works offline and instantly for all future
ingests. Nothing to install or pre-warm in advance.

**Step 10E — Configure mcp-local-rag for this project**

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

**Step 10F — Start the session, name it, and ingest reference docs**

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

**Step 10G — Run the startup check and complete kickoff**

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

*All options continue at Step 11 below.*

---

### Option C — Gemini CLI

Best when: you want Gemini CLI as your primary tool, with native filesystem access,
`/chat save` for session persistence, and GEMINI.md hierarchy for automatic context.

**Step 10H — Start the Gemini CLI PM chat**

```bash
cd ~/Developer/YourProject
git pull
gemini
```

Gemini CLI loads `GEMINI.md` automatically. Read BACKLOG.md, STATUS.md,
PLATFORM-SKILLS.md, and the current phase from IMPLEMENTATION_PLAN.md.

Then paste **Template 1 — PM Chat Kickoff Prompt** from `PROMPT-TEMPLATES.md`
with all [PLACEHOLDERS] filled in.

**Step 10I — Save the session**

```bash
/chat save yourproject-pm
```

> **Daily sessions:** Resume with `gemini` then `/chat resume yourproject-pm`.
> Use `/compress` when context grows large. For cross-machine workflow see
> `supporting-docs/CLI-PM-SETUP.md`.

*All options continue at Step 11 below.*

---

## Step 11 — Generate SETUP.md and AGENT_KICKOFF.md

Ask the PM chat to generate these using **Templates 13 and 14** from `PROMPT-TEMPLATES.md`.
The PM chat reads the templates and fills in all values from your planning conversation.

The resulting files go in your project repo root:
- `SETUP.md` — step-by-step setup guide for this specific project on any machine
- `AGENT_KICKOFF.md` — architecture phase kickoff prompt for the architect agent

Commit both files.

---

## Step 12 — Run the architecture kickoff

```bash
cd ~/Developer/YourProject
./agent-run.sh claude --agent architect
# Paste the full contents of AGENT_KICKOFF.md as your first message
```

The architect agent is platform-agnostic — it loads the correct platform skills
based on the prompt generated by the PM chat from `PLATFORM-SKILLS.md`.

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
| iOS 26 API reference | Agents read directly from Xcode bundle (no sync step needed) |

---

## Phase routing cheat sheet

| Phase | Default | Agent |
|---|---|---|
| Architecture / design | Claude Code | `architect` |
| API and schema design | Claude Code | `grpc-schema` |
| Planning / task breakdown | Claude Code | `planner` |
| Dependency evaluation | Claude Code | `docs-researcher` |
| Implementation | Codex | `coder` |
| Code review | Claude Code | `reviewer` |
| Testing | Codex | `tester` |
| Debugging | Claude Code | `coder` |
| Refactoring | Codex | `coder` |
| Documentation | Claude Code | `docs-researcher` |
| Repo operations / validation | Codex | `repo-ops` |
| Full-codebase audit | Any | `auditor` |

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

- `maintenance-docs/VERIFIED-NOTES.md` — what was verified from official docs and what was not
- `maintenance-docs/RECOMMENDATIONS.md` — practical recommendations for new projects
- iOS 26 API docs — agents read directly from the Xcode bundle at `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`
- `swift-python-best-practices-v3.md` — the full 206-item best practices reference
- `METHODOLOGY.md` (in each project repo) — full methodology reference; see **Part 7 —
  BACKLOG and TODO Management** for deferral comment format, BACKLOG item format, and
  the four PM chat procedures (phase gate check, post-session processing, orphan audit,
  resolution)

---

## Upgrading an existing project to a new pack version

When upgrading an existing project, do not copy template files blindly — your
project-level customizations must be preserved.

For v8 → v9 upgrades, see: **`supporting-docs/MIGRATION-v8-to-v9.md`**

For v7 → v8 upgrades: use the v8 pack (`git checkout v8.9`) which contains
`supporting-docs/MIGRATION-v7-to-v8.md`. Apply v7→v8 first, then v8→v9.

**Summary of v9 change scope:**
- Unified template replaces three per-project-type templates
- `apple-architect` + `python-architect` merged into single `architect` agent
- 30-skill composable library with PLATFORM-SKILLS.md selection matrix
- Three-tool parity: Claude Code, Codex CLI, Gemini CLI
- 7-cluster auditor agent (new) with parent + 7 subagents
- PACK-FEEDBACK.md (new) — upstream feedback loop to Pack Chat
- Language-specific scripts with wrapper detection

For upgrades from versions earlier than v8, apply v8 changes first, then v9.
