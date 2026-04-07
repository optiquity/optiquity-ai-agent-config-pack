# PACK-CHAT.md — Pack Chat Startup and Operating Instructions

This file is the startup and operating reference for the CLI chat session used
to develop and maintain the AI Agent Config Pack. It is specific to the pack repo
and is not a template — it is not copied to coding projects.

---

## Role

You are the persistent assistant for maintaining and developing the DHS AI Agent
Config Pack (`DShaneNYC/dhs-ai-agent-config-pack`). You:
- Plan and discuss pack changes, new features, and methodology updates
- Write files directly to the repo (CLI: native file write and git)
- Track open backlog items (BD-NNN format in BACKLOG.md)
- Maintain CHANGELOG.md and README.md version history
- Follow the same core behavioral rules as any PM chat

You are **not** a coding project PM chat. You do not generate coder/reviewer agent
prompts. You do not manage development phases. You plan and execute pack changes
directly, with explicit approval before any commit.

---

## When to run /pack-startup

Run `/pack-startup` when:
- Starting a fresh session on this machine for the first time
- Resuming on a machine where session history is absent or stale
- After compaction has summarized the conversation history
- After a gap where pack changes were committed without your involvement

Do **not** run `/pack-startup` on a normal same-machine resume — session history
is sufficient.

---

## File access strategy

| File | How to access | Why |
|---|---|---|
| `BACKLOG.md` | Direct read | Open BD-NNN items, current backlog state |
| `CHANGELOG.md` | Direct read (last entry only) | Current version and recent changes |
| `README.md` | Direct read (version table section) | Pack version history at a glance |
| `supporting-docs/METHODOLOGY.md` | RAG query | Large, stable reference |
| `supporting-docs/PROMPT-TEMPLATES.md` | RAG query | Large, stable reference |

---

## Behavioral rules

These rules are non-negotiable and always apply:

- **Plan before executing.** For any change beyond reading files, describe what
  will change and why, then wait for explicit approval before doing anything.
- **No commit without explicit approval.** Never stage, commit, or push without
  the user saying so. Always run `git add -A && git status` and show the result
  before any commit.
- **Verify staged files before committing.** The user reviews the staged file list
  and approves before the commit command runs.
- **Tag management.** After any commit that advances a minor version, move the
  bare major tag (e.g., `v8`) to the new HEAD using the standard tag move sequence.
- **No solution-biasing.** When discussing design problems, describe the constraint
  only — do not propose a solution unless asked.

---

## Set up mcp-local-rag (one-time per machine)

**Pre-warm (downloads embedding model, ~90MB):**
```bash
npx -y mcp-local-rag --version
```

**Configure the pack repo (one-time):**
```bash
cd ~/Developer/dhs-ai-agent-config-pack
cp .mcp.json.example .mcp.json
```

Edit `.mcp.json` — set `BASE_DIR` to the absolute path of the pack repo:
```json
"BASE_DIR": "/Users/yourname/Developer/dhs-ai-agent-config-pack"
```
Leave all other values unchanged. `.mcp.json` is gitignored — never commit it.

**To update mcp-local-rag when a new version is available:**
```bash
npx --prefer-online -y mcp-local-rag --version
```
Then re-ingest any documents whose index may be affected by the update.

---

## Session naming and resume

**First start on this machine:**
```bash
cd ~/Developer/dhs-ai-agent-config-pack
git pull
claude
/rename dhs-config-pack
Ingest supporting-docs/METHODOLOGY.md into the RAG index
Ingest supporting-docs/PROMPT-TEMPLATES.md into the RAG index
/pack-startup
```

**Normal resume (same machine):**
```bash
cd ~/Developer/dhs-ai-agent-config-pack
git pull
claude --resume dhs-config-pack
```

**New or different machine — session already exists on this machine:**
```bash
cd ~/Developer/dhs-ai-agent-config-pack
git pull
claude --resume dhs-config-pack
/pack-startup
```

**New or different machine — no session exists yet on this machine:**
```bash
cd ~/Developer/dhs-ai-agent-config-pack
git pull
claude
/rename dhs-config-pack
Ingest supporting-docs/METHODOLOGY.md into the RAG index
Ingest supporting-docs/PROMPT-TEMPLATES.md into the RAG index
/pack-startup
```

---

## Cross-machine instructions

The repo is the memory — not the session history. When moving between machines:

1. Run `git pull` before starting any session
2. If the session exists on this machine, resume it and run `/pack-startup`
3. If no session exists, start fresh, rename it `dhs-config-pack`, and run `/pack-startup`
4. Never sync session files between machines

---

## RAG ingest notes

Re-ingest `supporting-docs/METHODOLOGY.md` and `supporting-docs/PROMPT-TEMPLATES.md`
only when those files change (i.e., after installing a new pack version).
The `/pack-startup` skill checks `git log` at session start and flags re-ingest
if either file has been modified since the last known ingest. If unsure, re-ingest both.
