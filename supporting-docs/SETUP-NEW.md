# Setup Guide — New Project

This guide walks you through setting up a **new project** with the AI
Agent Config Pack v10.0. It is self-contained — follow the steps in
order.

Use this guide when you are creating a fresh repo (no code yet, or
only a README). For an existing project that has source and/or docs
but no AI agent configuration, see `SETUP-EXISTING.md` instead. For
upgrading from v10 to v11, see `MIGRATION-v10-to-v11.md`. (The
v9->v10 migrator was sunset in v11; v9.x is no longer supported —
reach out for migration guidance.)

**New in v10:** a single `scripts/init-project.sh` script replaces
the manual copy / conditional-remove / permissions / bootstrap dance.
It detects project state, previews every operation, and asks for
confirmation before writing. Per-agent prompt templates live in
`docs/pack/prompts/` (one file per agent, one `## Variant:` H2 per
template).

---

## Prerequisites

- **macOS 14+** (for Apple projects; Linux works for server-only
  projects).
- **Git 2.40+** and the `gh` GitHub CLI (optional but recommended).
- **Xcode 26+** for Apple projects.
- **Node.js 18+** (for `mcp-local-rag` if using Claude Code CLI as PM
  chat).
- **Pack cloned locally.** Clone the `optiquity-ai-agent-config-pack`
  repo to a stable location and use that location wherever
  `/path/to/pack` appears in this guide. Check out the v10 tag or track
  v10-dev. Set `PACK` to its absolute path in your shell:

  ```bash
  export PACK=/path/to/pack
  git -C "$PACK" fetch --tags
  git -C "$PACK" checkout v10.0   # or v10 floating tag
  ```

---

## Step 1 — Create the GitHub repo

Create a new repo on GitHub (via web, `gh`, or your IDE). Clone it:

```bash
cd ~/Developer
gh repo create YourProject --private --clone       # or create via web + git clone
cd YourProject
```

For an Apple app, pick a name that matches your Xcode scheme.

---

## Step 2 — (Apple only) Create the Xcode project

Create the Xcode project inside the cloned repo:

```bash
# In Xcode: File → New → Project → App → save into /path/to/your-project/
```

Commit the initial Xcode project before running `init-project.sh`:

```bash
git add -A && git commit -m "Initial Xcode project"
```

Skip this step for server-only (Python / Node) projects.

---

## Step 3 — Run `init-project.sh`

This single command handles everything that was manual in v9
(template copy, conditional-file removal, skills distribution,
permissions, bootstrap setup):

```bash
cd /path/to/your-project
"$PACK/scripts/init-project.sh" .
```

The script will:

1. Detect your project state (five classes: `new-empty`, `new-bare`,
   `existing-bare`, `existing-source`, `already-configured`).
2. Stop (exit 20) if any AI config is already present — tell you to
   archive the conflicting config (or, if you're already on a prior
   pack version, route you to the appropriate `MIGRATION-vN-to-vM.md`
   guide; v9.x is no longer supported).
3. Print a preview of every operation: files to add, `.gitignore`
   lines to merge, conditional files to remove based on detected
   languages, any skill-coverage gaps (e.g., Kotlin / TypeScript not
   covered).
4. Ask `Proceed? [y/N]` — default **No**. Only `y/Y/yes` proceeds.
5. Execute eleven stages (S0..S10) with inline verification at each
   step. Each stage exits non-zero with a clear diagnostic on any
   failure.
6. Print an end-of-run PM chat kickoff prompt (Step 10 below uses
   this).

Review the preview carefully before confirming. The script does not
commit — you review `git status` / `git diff` after it runs, then
commit yourself (Step 9).

If the script flags a skill-coverage gap (e.g., your project uses
Kotlin, for which the pack has no skill), the gap is logged in the
end-of-run kickoff prompt; the PM chat appends an entry to
`docs/pack/PACK-FEEDBACK.md` during kickoff.

Exit codes (reference):

| Code | Meaning |
|---|---|
| 0 | Success, or developer declined confirmation |
| 10 | `$PACK` invalid |
| 11 | Not a git repo (run `git init` first) |
| 12 | Working tree not clean |
| 20 | STOP — existing AI config |
| 21–30 | Stage N failure (code = 20 + N) |
| 31 | Blast-radius sweep failure |
| 40 | Conditional-removal failure |
| 99 | Internal error |

---

## Step 4 — Fill in context file placeholders

`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` have `[PLACEHOLDER]` and
`[CONDITIONAL]` sections. The PM chat will fill most of them in during
kickoff (Step 10), but a minimum set should be filled in manually
first:

1. Fill `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]` in all
   three files.
2. Fill `[PLATFORM_DEFAULTS]` for your project type (examples in the
   HTML comments inside each file).
3. Delete `[CONDITIONAL]` sections that don't apply (e.g., remove the
   iOS availability-guard section for a Python-only server project).
4. Leave `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`,
   `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`,
   `[PLATFORM_ANTIPATTERNS]` for the PM chat to fill during kickoff
   using `docs/pack/PLATFORM-SKILLS.md`.
5. The `**Active skills:**` line in each trinity file stays as a
   placeholder until the PM chat fills it during kickoff.

---

## Step 5 — (PM chat handles this during kickoff)

*Step numbers 6, 7, 8 are intentionally absent — Steps 5–8 collapsed into
this Step 5. Step numbering is preserved for cross-doc reference
stability; Steps 9–12 below retain their original numbers.*

On shell-capable surfaces (Claude Code CLI, Codex CLI, Gemini CLI,
Claude Desktop with Desktop Commander), the PM chat runs kickoff
auto-discovery (INSTALL-PROCEDURES.md Procedure 7) after you paste the
kickoff prompt in Step 10. It fills in Apple Xcode scheme variables,
installs swift-format, installs gRPC tooling, and installs Xcode
companion files — each behind an approval gate. **You do not need to
run anything in this step on a shell-capable surface.**

On surfaces without shell access (Claude Web, ChatGPT Web), declare
`manual` when the PM chat asks and follow the Manual fallback below.

### Manual fallback

Run these commands locally and report values back to the PM chat,
which will compose the corresponding file edits for you to paste.

#### 5.A — (Apple only) Xcode scheme variables

Open `scripts/validate-swift.sh` and `scripts/test-swift.sh`. Fill these at the
top:

```bash
XCODE_SCHEME="YourAppName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
# For macOS-only projects use: XCODE_DESTINATION="platform=macOS"
```

Find valid values:

```bash
xcodebuild -list
xcrun simctl list devices available
```

Set the same values in `.claude/settings.json` `env` block (so the
post-edit hook picks them up):

```json
"env": {
    "AGENT_CAPABILITIES": "...",
    "XCODE_SCHEME": "YourAppName",
    "XCODE_DESTINATION": "platform=iOS Simulator,name=iPhone 16,OS=latest"
}
```

If your Xcode project uses a non-SPM source layout (e.g. `MyApp/` and
`MyAppTests/` rather than `Sources/` and `Tests/`), also set
`SWIFT_SOURCE_DIRS` in `scripts/format-swift.sh`:

```bash
SWIFT_SOURCE_DIRS=""   # e.g. "MyApp MyAppTests" for Xcode-generated layout
```

#### 5.B — (Apple only) Install swift-format

```bash
brew install swift-format
```

`scripts/format.sh` warns and exits 0 if swift-format is not installed,
so this is not blocking — but you want it for local formatting.

#### 5.C — (gRPC only) Set up proto code generation

Install prerequisites:

```bash
brew install bufbuild/buf/buf              # buf CLI
brew install swift-protobuf                # Apple-side codegen
brew install grpc-swift                    # Apple-side gRPC
# Python-side:
# uv add grpcio-tools grpcio grpcio-status grpcio-reflection
```

Replace the example service in `proto/example/v1/example_service.proto`
with your own, then generate:

```bash
./scripts/proto-gen.sh
```

#### 5.D — (Apple only) Install Xcode companion files

Once per Mac (repeat on each machine you develop on):

```bash
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/codex
cp "$PACK/xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md" \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp "$PACK/xcode-companion-templates/ClaudeAgentConfig/settings.json" \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp "$PACK/xcode-companion-templates/Codex/AGENTS.md" \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
cp "$PACK/xcode-companion-templates/Codex/config.toml" \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```

Replace any older companion files if previously installed.

---

## Step 9 — Initial commit

```bash
git add -A && git status         # verify nothing sensitive is staged
git commit -m "Add AI agent configuration (v10.0)"
```

The `.gitignore` automatically excludes `.claude/settings.local.json`,
`.mcp.json`, and all generated Protobuf output.

---

## Step 10 — Set up the PM chat

> **Prerequisite — design brief.** Before starting the PM chat, you
> need a design brief covering at minimum: target platform(s), primary
> language(s), any known external APIs or services, and the project's
> definition of done for MVP. If you don't have one, produce it in a
> separate conversation first (a Claude Web side chat, a Gemini CLI
> session, or any other workspace). The PM chat consumes a design
> brief — it does not author one. See `docs/pack/PM-CHAT.md`
> § "Before starting a new project."

The PM chat is your project manager for the entire project lifetime.
It generates all agent prompts, receives agent output for analysis,
and makes all architectural and planning decisions. It never writes
code — that is the job of CLI agents.

Four surface options. The methodology, rules, and procedures are
identical in all four. Pick one as your primary PM chat.

> **Never run two PM chats simultaneously for the same project.**

### Option A — Claude Desktop

1. Go to claude.ai → Projects → New Project.
2. Name it after your app (e.g., "MyApp — PM").
3. Connect your GitHub repo via the GitHub connector.
4. Sync the connector — `METHODOLOGY.md` and `docs/pack/PM-CHAT.md`
   become searchable after sync.
5. Open a new chat in your project. Paste the kickoff prompt from
   `docs/pack/prompts/pm-chat.md` (Variant: kickoff) with all
   `[PLACEHOLDERS]` filled in.

### Option B — Claude Code CLI

```bash
cd /path/to/your-project
cp .mcp.json.example .mcp.json
# Edit .mcp.json: set BASE_DIR to the absolute path of this project.
# .mcp.json is gitignored — never commit it.

claude
/rename yourproject-pm
Ingest METHODOLOGY.md into the RAG index
/pm-startup
```

Then paste the kickoff prompt from `docs/pack/prompts/pm-chat.md`
(Variant: kickoff) with all `[PLACEHOLDERS]` filled in.

Daily sessions: `claude --resume yourproject-pm` from the project
directory. Run `/pm-startup` only when starting fresh, after a long
gap, or after compaction. For cross-machine workflow see
`supporting-docs/CLI-PM-SETUP.md`.

### Option C — Codex CLI

```bash
cd /path/to/your-project
codex
```

Paste the kickoff prompt from `docs/pack/prompts/pm-chat.md` (Variant:
kickoff) with all `[PLACEHOLDERS]` filled in.

Daily sessions: `codex --resume`.

### Option D — Gemini CLI

```bash
cd /path/to/your-project
gemini
```

Gemini CLI loads `GEMINI.md` automatically. Paste the kickoff prompt
from `docs/pack/prompts/pm-chat.md` (Variant: kickoff).

Save the session: `/chat save yourproject-pm`. Resume: `gemini` then
`/chat resume yourproject-pm`.

---

## Step 11 — Generate SETUP.md and AGENT_KICKOFF.md

Ask the PM chat to generate these using the PM-chat self-prompt
variants:

- `docs/pack/prompts/pm-chat.md` Variant: **generate-setup** — produces
  `SETUP.md` (project-specific setup guide for any machine).
- `docs/pack/prompts/pm-chat.md` Variant: **generate-agent-kickoff** —
  produces `AGENT_KICKOFF.md` (architect agent prompt for initial
  architecture phase).

The PM chat reads the relevant pack template
(`supporting-docs/SETUP_TEMPLATE.md`,
`supporting-docs/AGENT_KICKOFF_TEMPLATE.md`) and fills in all
placeholder values from your planning conversation.

Commit both files:

```bash
git add SETUP.md AGENT_KICKOFF.md
git commit -m "Add SETUP.md and AGENT_KICKOFF.md"
```

---

## Step 12 — Run the architecture kickoff

```bash
cd /path/to/your-project
./agent-run.sh claude --agent architect
# Paste the full contents of AGENT_KICKOFF.md as your first message
```

The architect agent is platform-agnostic — it loads the correct
platform skills via the skill-loading instructions the PM chat
generated from `docs/pack/PLATFORM-SKILLS.md`.

After the architect run, commit `ARCHITECTURE.md` and
`IMPLEMENTATION-PLAN.md` (the architect writes these files as its
output deliverables).

---

## Reference

### Common agent invocations

Use `./agent-run.sh` to launch any agent — it applies the right CLI
flags automatically (read-only permission bypass for read-only
agents; full pass-through for write agents). Run `./agent-run.sh
--help` for the full roster.

| Task | Command |
|---|---|
| Plan a feature before coding | `./agent-run.sh claude --agent planner "Plan [description]"` |
| Implement | `./agent-run.sh codex --agent coder` |
| Review code | `./agent-run.sh claude --agent reviewer "Review [file or module]"` |
| Design a gRPC service | `./agent-run.sh claude --agent grpc-schema "Design a service for [description]"` |
| Debug a build failure | `./agent-run.sh claude --agent coder "Debug: [error text]"` |
| Full-codebase audit | `./agent-run.sh claude --agent auditor` |
| Generate gRPC code | `./scripts/proto-gen.sh` |
| Run all validation | `./scripts/validate.sh` |

**Claude** executes inline prompts immediately. **Codex** and
**Gemini** start interactive — the agent activates, loads its
definition, acknowledges, and waits for you to paste the full task
prompt.

### Phase routing cheat sheet

| Phase | Default | Agent |
|---|---|---|
| Architecture / design | Claude Code | `architect` |
| API / schema design | Claude Code | `grpc-schema` |
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

### What NOT to put in Git

`.gitignore` handles these automatically:

- `.claude/settings.local.json` — machine-specific Claude Code
  permission overrides.
- `.mcp.json` — local MCP server configuration (may contain paths or
  keys).
- `generated/swift/` and `server/src/generated/` — generated
  Protobuf / gRPC code.
- `.buf/` — buf CLI cache.
- `.pack-migration-backup/` and `.pack-migrate-vN-to-vM/` —
  migration-script backup / state directories (created by
  `migrate-vN-to-vM.sh` on upgrade; absent on a fresh install).

Commit everything else, including `CLAUDE.md`, `AGENTS.md`,
`GEMINI.md`, `agent-run.sh`, `.claude/` (excluding the gitignored
local files), `.codex/`, `.gemini/`, `scripts/`, `proto/`.

---

## Upgrading later

When a new pack version ships, upgrade your project by running the
migration script for your current → target version:

- Currently at v9.3 — v9 is no longer supported (the v9->v10
  migrator was sunset in v11); reach out to the pack
  maintainer for migration guidance.
- Currently at v10.x — see `MIGRATION-v10-to-v11.md`.
- For future major versions — see the migration guide shipped
  with the next major pack version, naming convention
  `MIGRATION-vN-to-vM.md`.

Migration guides always live in `supporting-docs/` and ship with the
major version that introduces the destination pack version.
