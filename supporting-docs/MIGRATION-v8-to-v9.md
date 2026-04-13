# Migration Guide — v8 to v9

This guide covers upgrading existing projects from AI Agent Config Pack v8.x
to v9.0. It is self-contained — follow these steps in order without needing
any other document.

> **Automated option:** If you prefer to have a Claude Code CLI session
> execute the migration for you (with your review and approval at each
> step), see the **"Automated migration via Claude Code CLI"** section at
> the end of this guide. You can skip the manual steps below entirely.

For v7 → v8 upgrades: use the v8 pack (`git checkout v8.9`) which contains
`MIGRATION-v7-to-v8.md`. Apply v7→v8 first, then this guide.

---

## Overview of what changed in v9

v9 is a structural redesign. Changes fall into three categories:

**1. Replace wholesale** — agent files, scripts, config files, and companion
templates. These contain no project-specific content and can be overwritten.

**2. Create new** — files that didn't exist in v8: GEMINI.md, PLATFORM-SKILLS.md,
PACK-FEEDBACK.md, new Tier 2 skills, skill distribution to Codex and Gemini.

**3. Manual merge** — context files (CLAUDE.md, AGENTS.md, PM-CHAT.md) contain
project-specific customizations that must be preserved. These require careful
merging of v9 template structure around existing project content.

### Key changes

- **Unified template.** Three per-project-type template directories
  (`apple-app-template/`, `python-server-template/`,
  `apple-app-plus-python-server-template/`) are replaced by a single
  `project-template/`. Platform-specific behavior is determined by which
  skills the PM chat loads, not which template was copied.
- **Architect rename.** `apple-architect` and `python-architect` are merged
  into a single `architect` agent. Platform knowledge comes from loaded skills.
- **Skill library.** 30 skills (12 Tier 1 role skills + 17 Tier 2 platform
  skills + 1 PM chat operational skill). Skills are stored once in `skills/`
  and distributed to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
  at setup time.
- **Three-tool parity.** Claude Code, Codex CLI, and Gemini CLI are all
  first-class. GEMINI.md is the Gemini context file. PLATFORM-SKILLS.md is
  the skill-selection matrix.
- **7-cluster auditor.** New parent + 7 subagent auditor for full-codebase
  structural audits. Replaces the ad-hoc per-dimension audit templates.
- **PACK-FEEDBACK loop.** PM chat observes pack behavior in real projects
  and reports back to the Pack Chat (pack maintainer) at workflow boundaries.
- **Language-specific scripts.** Monolithic `format.sh`, `validate.sh`,
  `bootstrap.sh`, `test.sh` replaced by thin wrappers that call
  language-specific variants (`format-swift.sh`, `format-python.sh`, etc.).

---

## Before you start

**Prerequisites:**
- Your project is on v8.x (any v8 minor version).
- Working tree is clean: `git status` shows no uncommitted changes.
- You have the v9 pack available locally (cloned or downloaded).

**Back up:**
```bash
cd ~/Developer/[your-project]
git checkout -b migration-v8-to-v9
```

All migration changes happen on this branch. If anything goes wrong,
`git checkout main` returns to the pre-migration state.

---

## Step 1 — Replace agent files

Agent files contain no project-specific content — the project's rules live
in CLAUDE.md/AGENTS.md, not in the agent `.md` or `.toml` files.

```bash
PACK="/path/to/pack"

# Replace Claude agent files (removes old, adds new including auditor subagents)
rm -rf .claude/agents/
cp -r "$PACK/project-template/.claude/agents/" .claude/agents/

# Replace Codex agent files
rm -rf .codex/agents/
cp -r "$PACK/project-template/.codex/agents/" .codex/agents/

# Replace Codex config (new agent registry, max_depth=2 for auditor subagents)
cp "$PACK/project-template/.codex/config.toml" .codex/config.toml

# Replace Codex requirements
cp "$PACK/project-template/.codex/requirements.toml" .codex/requirements.toml

# Replace Claude settings (v9 permissions including Python tooling)
cp "$PACK/project-template/.claude/settings.json" .claude/settings.json

# Copy settings.local.example.json if you don't have one
cp -n "$PACK/project-template/.claude/settings.local.example.json" .claude/settings.local.example.json

# Replace agent-run.sh (v9 roster: 16 agents, Gemini CLI support)
cp "$PACK/project-template/agent-run.sh" agent-run.sh
chmod +x agent-run.sh

# Replace .mcp.json.example
cp "$PACK/project-template/.mcp.json.example" .mcp.json.example
```

**What this changes:**
- `apple-architect.md` / `.toml` → replaced by `architect.md` / `.toml`
- `python-architect.md` / `.toml` → replaced by `architect.md` / `.toml`
- 8 new auditor files added (parent + 7 subagents) per tool
- `.codex/config.toml` now registers 16 agents with `max_depth = 2`
- `agent-run.sh` now supports 16 agents across Claude, Codex, and Gemini

---

## Step 2 — Replace scripts

v9 scripts use a wrapper + language-specific model. The wrappers detect
which languages are present via marker files and call the right scripts.

```bash
# Replace entire scripts directory
rm -rf scripts/
cp -r "$PACK/project-template/scripts/" scripts/
chmod +x scripts/*.sh
```

**What this changes:**
- Monolithic `format.sh` → wrapper `format.sh` + `format-swift.sh` + `format-python.sh`
- Same pattern for `validate.sh`, `bootstrap.sh`, `test.sh`
- `agent-post-edit-check.sh` is now language-aware
- `proto-gen.sh` carried forward unchanged

**After copying:** If your project uses Xcode (Apple projects), open
`scripts/validate.sh` and `scripts/test.sh` and fill in:
```bash
XCODE_SCHEME="YourAppName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
```
Also set these in `.claude/settings.json` → `env` block (for the post-edit hook).

---

## Step 3 — Distribute skills

v9 has 30 skills. v8 had 14 (in `.claude/skills/` only). You need to:
- Copy the canonical `skills/` directory to the project root (new in v9)
- Replace `.claude/skills/` (clean out stale v8 skills like `grpc-schema`)
- Create `.codex/skills/` and `.gemini/skills/` (didn't exist in v8)

```bash
# Copy canonical skills/ directory to project root (new in v9 — bootstrap.sh
# uses this as the source for future skill distribution)
cp -r "$PACK/project-template/skills/" skills/

# Replace .claude/skills/ entirely (adds 16 new Tier 2 skills, removes stale grpc-schema)
rm -rf .claude/skills/
mkdir -p .claude/skills/
for skill in "$PACK/project-template/skills/"*/; do
    name=$(basename "$skill")
    cp -r "$skill" ".claude/skills/$name"
done

# Replace .codex/skills/ (may exist in some v8 projects with stale skills)
rm -rf .codex/skills/
mkdir -p .codex/skills/
for skill in "$PACK/project-template/skills/"*/; do
    name=$(basename "$skill")
    mkdir -p ".codex/skills/$name"
    cp "$skill/SKILL.md" ".codex/skills/$name/SKILL.md"
done

# Create .gemini/skills/ (new in v9 — delete first if it somehow exists)
rm -rf .gemini/skills/
mkdir -p .gemini/skills/
for skill in "$PACK/project-template/skills/"*/; do
    name=$(basename "$skill")
    mkdir -p ".gemini/skills/$name"
    cp "$skill/SKILL.md" ".gemini/skills/$name/SKILL.md"
done
```

**Verify:**
```bash
ls .claude/skills/ | wc -l    # should be 30
ls .codex/skills/ | wc -l     # should be 30
ls .gemini/skills/ | wc -l    # should be 30
```

> **Note:** The manual loops above are needed for the initial migration to
> clean out stale v8 skills (e.g., the renamed `grpc-schema`). After
> migration, `./scripts/bootstrap.sh` automatically distributes skills from
> the canonical `skills/` directory on every run — you won't need to repeat
> these manual loops.

---

## Step 4 — Create new files

These files are new in v9 and don't exist in v8 projects.

```bash
# GEMINI.md — Gemini CLI context file (equivalent to CLAUDE.md)
cp "$PACK/project-template/GEMINI.md" GEMINI.md

# PLATFORM-SKILLS.md — skill-selection matrix for the PM chat
cp "$PACK/project-template/PLATFORM-SKILLS.md" PLATFORM-SKILLS.md

# PACK-FEEDBACK.md — upstream feedback log to Pack Chat
cp "$PACK/project-template/PACK-FEEDBACK.md" PACK-FEEDBACK.md

# Replace METHODOLOGY.md with v9 version
cp "$PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md

# Replace PROMPT-TEMPLATES.md with v9 version
cp "$PACK/supporting-docs/PROMPT-TEMPLATES.md" PROMPT-TEMPLATES.md

# Replace .gitignore with v9 version (covers Python, proto, additional artifacts)
cp "$PACK/project-template/.gitignore" .gitignore
```

**After copying, fill in placeholders in GEMINI.md:**
- `[PROJECT_NAME]` → your project name
- `[PLATFORM_TARGETS]` → your targets (e.g., "macOS" or "iOS, iPadOS, macOS")
- `[TRANSPORT]` → your transport (e.g., "gRPC + Proto3" or "REST")
- `[PLATFORM_DEFAULTS]` → fill in from your existing CLAUDE.md's platform section
- Fill in or remove `[CONDITIONAL]` sections based on your project type

**Fill in placeholders in PACK-FEEDBACK.md:**
- `[PROJECT_NAME]` → your project name
- Pack version → v9.0
- Project start date → your project's original start date

**Remove the setup comment blocks** from GEMINI.md and PACK-FEEDBACK.md
(the `<!-- HOW TO USE THIS TEMPLATE -->` HTML comments at the top).

---

## Step 5 — Merge context files (manual — read carefully)

These files have project-specific content that must be preserved. Do NOT
replace them wholesale.

### CLAUDE.md

The v9 unified CLAUDE.md uses `[PLACEHOLDER]` and `[CONDITIONAL]` sections
where v8 had hardcoded platform content. Your v8 CLAUDE.md has real project
rules in those sections. The goal is to adopt the v9 structure while keeping
your project's rules.

**Option A — Diff and merge (recommended for heavily customized projects):**

1. Copy the v9 template to a temp file:
   ```bash
   cp "$PACK/project-template/CLAUDE.md" /tmp/claude-v9-template.md
   ```
2. Open your project's CLAUDE.md and `/tmp/claude-v9-template.md` side by side.
3. For each v9 section:
   - If it's a `[PLACEHOLDER]` section → keep your project's existing content
     for that topic, but adopt the v9 section heading and structure.
   - If it's a `[CONDITIONAL]` section → keep it if it applies to your project,
     delete it if it doesn't.
   - If it's a universal section (Architecture layer discipline, LSP,
     Dependency intake, Refactoring, Git workflow) → replace with the v9
     version (language-agnostic terminology).
4. Add these sections from v9 that don't exist in v8:
   - `## Skill loading` (points to PLATFORM-SKILLS.md)
   - The full v9 Scripts table (16 entries replacing the v8 table)
   - `PACK-FEEDBACK.md` in the deferral comments / PM-chat-owned file list
5. Update the phase routing table: replace `apple-architect` / `python-architect`
   with `architect`. Add `auditor` row.

**Option B — Replace and re-fill (recommended for lightly customized projects):**

1. Back up your current CLAUDE.md:
   ```bash
   cp CLAUDE.md CLAUDE.md.v8-backup
   ```
2. Replace with v9 template:
   ```bash
   cp "$PACK/project-template/CLAUDE.md" CLAUDE.md
   ```
3. Open `CLAUDE.md.v8-backup` and fill in the v9 template's `[PLACEHOLDER]`
   sections with your project's content:
   - `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`
   - `[PLATFORM_DEFAULTS]` → from your v8 "Platform and stack defaults" section
   - `[PLATFORM_ARCHITECTURE]` → from your v8 "Architecture rules" section
   - `[LANGUAGE_RULES]` → from your v8 language-specific coding rules
   - `[GRPC_RULES]` → from your v8 gRPC section (if applicable)
   - `[PLATFORM_SECURITY]` → from your v8 Security section (platform-specific parts)
   - `[PLATFORM_TESTING]` → from your v8 Testing section (platform-specific parts)
   - `[PLATFORM_ANTIPATTERNS]` → from your v8 Anti-patterns section (platform-specific)
4. Remove `[CONDITIONAL]` sections that don't apply.
5. Remove the setup comment blocks (`<!-- HOW TO USE THIS TEMPLATE -->`).

### AGENTS.md

Same approach as CLAUDE.md — either diff-and-merge or replace-and-re-fill.
AGENTS.md is typically less customized than CLAUDE.md.

### PM-CHAT.md

Replace entirely with the v9 version and re-fill the project name:
```bash
cp "$PACK/project-template/PM-CHAT.md" PM-CHAT.md
```
Open PM-CHAT.md and replace `[PROJECT_NAME]` with your project name.
If you had custom sections in the "Additional project documents" section
at the bottom, re-add them. Remove the setup comment block.

---

## Step 6 — Update Xcode companion files (Apple projects only)

```bash
cp "$PACK/xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md" \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp "$PACK/xcode-companion-templates/ClaudeAgentConfig/settings.json" \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp "$PACK/xcode-companion-templates/Codex/AGENTS.md" \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
cp "$PACK/xcode-companion-templates/Codex/config.toml" \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```
Repeat on each Mac.

---

## Step 7 — Remove conditional files you don't need

v9's unified template includes files for all project types. Your v8 project
may not need all of them. If these files don't exist in your v8 project,
don't add them now:

| Your v8 project type | Don't add |
|---|---|
| Apple-only (no Python, no gRPC) | `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/` |
| Apple + gRPC (no Python) | `pyproject.toml`, `pyrightconfig.json`, `server/` |
| Python-only (no Swift) | — (keep everything; remove Apple-specific `[CONDITIONAL]` sections from context files instead) |
| Monorepo | — (keep everything) |

If your v8 project already has `proto/`, `pyproject.toml`, etc., leave them
as they are — don't overwrite project-specific versions with the template's
example versions.

---

## Step 8 — Verify

Run these checks to confirm the migration is complete:

```bash
# 1. Bootstrap (resolves dependencies, distributes skills if bootstrap handles it)
./scripts/bootstrap.sh

# 2. Validate (build + test — may fail if XCODE_SCHEME is not set)
./scripts/validate.sh

# 3. Check for stale agent names
echo "=== Stale agent name check ==="
grep -rn '\bapple-architect\b' .claude/ .codex/ CLAUDE.md AGENTS.md GEMINI.md agent-run.sh 2>/dev/null | grep -v "apple-architecture"
grep -rn '\bpython-architect\b' .claude/ .codex/ CLAUDE.md AGENTS.md GEMINI.md agent-run.sh 2>/dev/null | grep -v "python-architecture"
echo "(both should return nothing)"

# 4. Verify agent count
echo "Claude agents: $(ls .claude/agents/ | wc -l | tr -d ' ') (expect 16)"
echo "Codex agents: $(ls .codex/agents/ | wc -l | tr -d ' ') (expect 16)"

# 5. Verify skill count
echo "Claude skills: $(ls .claude/skills/ | wc -l | tr -d ' ') (expect 30)"
echo "Codex skills: $(ls .codex/skills/ | wc -l | tr -d ' ') (expect 30)"
echo "Gemini skills: $(ls .gemini/skills/ | wc -l | tr -d ' ') (expect 30)"

# 6. Verify new files exist
for f in GEMINI.md PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
    if [ -f "$f" ]; then echo "OK: $f"; else echo "MISSING: $f"; fi
done

# 7. Verify agent-run.sh works
./agent-run.sh --help | head -5
```

---

## Step 9 — Commit

```bash
git add -A
git status    # review — verify nothing sensitive is staged
git commit -m "Upgrade AI Agent Config Pack v8 → v9"
```

After committing:
- If using Claude Desktop app PM chat: sync the GitHub connector.
- If using CLI PM chat: re-ingest the updated reference docs, then run
  `/pm-startup`. METHODOLOGY.md and PROMPT-TEMPLATES.md changed
  significantly in v9 — without re-ingesting, RAG searches return stale
  v8 content:
  ```bash
  claude --resume [project-short-name]-pm
  ```
  Inside the session:
  ```
  Re-ingest METHODOLOGY.md into the RAG index
  Re-ingest PROMPT-TEMPLATES.md into the RAG index
  /pm-startup
  ```

---

## What to do after migration

**Brief the PM chat on v9.** In your first session after migration, paste
this message so the PM chat understands the structural changes:

> This project has been migrated from AI Agent Config Pack v8 to v9.
> Key changes you need to know:
>
> 1. Read PLATFORM-SKILLS.md in full now. You select skills per agent per
>    task using the four-dimension model (Platform, Language, Role,
>    Protocol). Every agent prompt you generate must include the correct
>    skills from this matrix.
> 2. The architect agent is now unified — `architect` replaces
>    `apple-architect` and `python-architect`. Platform knowledge comes
>    from loaded skills.
> 3. Read METHODOLOGY.md Part 3 for the updated agent roster,
>    tester/planner trigger rules, and the reviewer-vs-tester-vs-auditor
>    disambiguation table.
> 4. Read METHODOLOGY.md Part 10 for the new PACK-FEEDBACK loop — you
>    now own PACK-FEEDBACK.md and must log observations at workflow
>    boundaries.
> 5. The auditor agent is new (7 subagents). See METHODOLOGY.md Part 6
>    for when and how to run it.
> 6. Run /pm-startup to re-read all state files.

**Fill in PLATFORM-SKILLS.md** — after the PM chat reads it, ask it to
determine the project's skill profile by answering the four dimension
questions (Platform targets, Languages, Component roles, Communication
protocols). This determines which skills are loaded for every future
agent prompt.

**Seed PACK-FEEDBACK.md** — fill in the Status section (pack version v9.0,
project name, start date). The PM chat will begin logging observations
per METHODOLOGY.md Part 10.

**Fill in GEMINI.md placeholders** — if not done in Step 4 above, fill in
all `[PLACEHOLDER]` and `[CONDITIONAL]` sections before using Gemini CLI.

---

## Project-type-specific notes

### Apple-only projects (no Python, no gRPC)

- The `architect` agent replaces `apple-architect`. Platform knowledge now
  comes from skills (`apple-architecture-core`, `ios-architecture`,
  `macos-architecture`) loaded by the PM chat.
- If your CLAUDE.md has extensive Apple-specific rules (iOS 26 features,
  SwiftUI conventions, etc.), use Option A (diff-and-merge) in Step 5
  to preserve them.
- Remove `[CONDITIONAL]` sections for Python and gRPC from CLAUDE.md,
  AGENTS.md, and GEMINI.md.

### Python server projects (no Swift)

- The `architect` agent replaces `python-architect`. Platform knowledge now
  comes from skills (`python-architecture`, `python-best-practices`) loaded
  by the PM chat.
- Remove `[CONDITIONAL]` sections for iOS 26, Swift, and Xcode from
  CLAUDE.md, AGENTS.md, and GEMINI.md.
- Remove the Xcode scheme setup from Step 2 (not applicable).
- Skip Step 6 (Xcode companion files).

### Monorepo projects (Swift + Python)

- Both `apple-architect` and `python-architect` are replaced by a single
  `architect` agent. The PM chat loads all relevant platform skills for
  both languages.
- Keep all `[CONDITIONAL]` sections — they all apply.
- Both sets of language-specific scripts will be called by the wrappers.

---

## Troubleshooting

**bootstrap.sh fails with "uv not found":**
Python tooling (uv, ruff, pyright) is required for Python projects.
Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`

**validate.sh skips xcodebuild:**
Set `XCODE_SCHEME` and `XCODE_DESTINATION` in `scripts/validate.sh`,
`scripts/test.sh`, and `.claude/settings.json` → `env` block.

**agent-run.sh says "unknown agent 'apple-architect'":**
The rename is complete. Use `architect` instead. If your PM chat or
scripts reference the old name, update them.

**Skills count is wrong after distribution:**
Re-run the skill distribution loop from Step 3. Verify the pack's
`project-template/skills/` has 30 directories: `ls "$PACK/project-template/skills/" | wc -l`

**GEMINI.md has unfilled [PLACEHOLDER] sections:**
Fill them in per Step 4. A fresh Gemini CLI session will load GEMINI.md
automatically and may behave incorrectly if placeholders are present.

---

## Automated migration via Claude Code CLI

Instead of executing the migration steps manually, you can paste the
prompt below into a fresh Claude Code CLI session. The session will
execute the migration guide steps, pause for your review at the merge
step (Step 5), and wait for your approval before committing.

**Setup:**

```bash
cd ~/Developer/[your-project]
claude
```

Before pasting, replace `/path/to/pack` in the prompt with the actual
path to your pack repo checkout. For example:
`PACK="$HOME/Developer/dhs-ai-agent-config-pack-v9"`

**Paste this prompt** (copy everything between the `---` lines):

---

You are performing a v8 → v9 migration of this project using the
AI Agent Config Pack. First, set the pack repo location — use this
variable in all copy commands that follow:

PACK="/path/to/pack"

Set $PACK to the absolute path of your local pack repo checkout
(the directory containing project-template/ and supporting-docs/).
If the pack has a v9-dev branch checked out via a worktree, use that
worktree's path.

Before starting: Verify the working tree is clean (git status shows
no uncommitted changes). If it is not clean, stop and tell me.

Instructions:

1. Read $PACK/supporting-docs/MIGRATION-v8-to-v9.md in full before
   doing anything.
2. Create a migration branch: git checkout -b migration-v8-to-v9
3. Execute guide Steps 1–4 (replace agents, replace scripts, distribute
   skills, create new files). Use $PACK in all copy commands.
4. Execute guide Step 5 (context file merge). Use Option A (diff-and-
   merge) if this project has customized CLAUDE.md or AGENTS.md content.
   Read the v8 backup and the v9 template side by side — preserve all
   project-specific rules, platform defaults, and anti-patterns while
   adopting the v9 section structure. Present the proposed merge for my
   review before applying it.
5. Execute guide Steps 6–7 (Xcode companion files if applicable,
   conditional file cleanup).
6. Run guide Step 8 verification checks and report the results.

Rules:

- Do NOT commit anything without my explicit review and approval.
  Show me git status and a summary of changes before any commit.
- If a command requires sudo or manual intervention (e.g., Xcode
  companion file installation to ~/Library/), tell me the command
  and wait for me to run it.
- Do NOT modify any file in the pack repo — only this project.
- After verification passes, present the "What to do after migration"
  section from the guide so I know the next steps (PM chat briefing,
  PLATFORM-SKILLS.md fill-in, PACK-FEEDBACK.md seeding).

---
