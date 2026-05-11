# CLI-PM-SETUP.md — CLI PM Chat Reference

This document covers daily usage, cross-machine workflow, and troubleshooting
for the CLI PM chat on all three tools: Claude Code, Codex CLI, and Gemini CLI.
**Setup is in `supporting-docs/SETUP-NEW.md` Step 10 Option B (Claude Code CLI)
or Option D (Gemini CLI).** Start there if you haven't completed setup yet.

For startup procedures, file access strategy, and behavioral rules, see
`docs/pack/PM-CHAT.md` (the authoritative PM chat instructions).
This document covers the day-to-day operational details that PM-CHAT.md
references but does not repeat.

---

## Daily session start

**Normal resume (same machine, recent session):**
```bash
cd /path/to/your-project
git pull
claude --resume [project-short-name]-pm
```
No need to run `/pm-startup` — session history is current.

**After compaction or a long gap:**
```bash
cd /path/to/your-project
git pull
claude --resume [project-short-name]-pm
/pm-startup
```

**Session not found (use picker):**
```bash
claude --resume
```
Select your session by name from the list.

---

## Starting fresh on a new or different machine

The repo is the memory — not the session history. Session files are machine-local.

If a session already exists on this machine under the right name, just resume it:
```bash
cd /path/to/your-project
git pull
claude --resume [project-short-name]-pm
/pm-startup
```

If no session exists yet on this machine, start one:
```bash
cd /path/to/your-project
git pull
claude
/rename [project-short-name]-pm
Ingest METHODOLOGY.md into the RAG index
/pm-startup
```

The startup report gives full orientation from the repo files alone.
You do not need to copy session files between machines.

---

## Cross-machine workflow

1. Always `git pull` before starting any session on any machine
2. Commits made on machine A are immediately visible on machine B after `git pull`
3. Session history is a convenience — the repo files are the authoritative memory
4. Run `/pm-startup` after `git pull` on any machine where the session is stale

Never copy or sync `.claude/` session files between machines.

---

## Updating RAG after pack version changes

When METHODOLOGY.md changes (new pack version installed), re-ingest it:

```bash
cd /path/to/your-project
claude --resume [project-short-name]-pm
```

Then inside the session:
```
Re-ingest METHODOLOGY.md into the RAG index
```

The `/pm-startup` skill checks `git log` to detect whether re-ingest is needed
and will flag it if so. If unsure, re-ingest — it takes only a few seconds.

---

## Multiple CLI sessions

You can run as many named CLI sessions simultaneously as you want — each is a
separate terminal window with its own context. This means you can have a PM chat
session for one project alongside investigation or research sessions, without conflict.

**Running `/pm-startup` is what designates a session as the PM chat.** A session
that never runs `/pm-startup` is just a general Claude Code session. Name and run
`/pm-startup` to establish a session as PM chat; start unnamed sessions freely for
side work.

**Never run two PM chat sessions for the same project simultaneously.** The Desktop
app and the CLI PM chat must not both act as PM chat at the same time — pick one.

---

## Desktop app and CLI working together

The CLI PM chat is the primary PM chat for active project work. The Claude Desktop
app is available any time for focused side investigations and research:

1. CLI PM chat: phase gate checks, BACKLOG processing, prompt generation,
   coder/reviewer cycle management
2. Desktop app: API research, architectural side investigations, analysis questions
3. When the Desktop app produces something actionable, ask it to generate a briefing
   prompt — paste that into the CLI PM chat at the start of the next session
4. The CLI PM chat acts on it, commits any changes, and the repo stays current


---

## Gemini CLI daily workflow

**Normal resume:**
```bash
cd /path/to/your-project
git pull
gemini
/chat resume [project-short-name]-pm
```

**After a long gap or on a new machine:**
```bash
cd /path/to/your-project
git pull
gemini
/chat resume [project-short-name]-pm    # or start fresh if no saved session
```
Read BACKLOG.md, STATUS.md, PLATFORM-SKILLS.md, and the current phase from
IMPLEMENTATION-PLAN.md to verify state is current. Gemini loads GEMINI.md
automatically via the GEMINI.md hierarchy.

**Save before ending:**
```bash
/chat save [project-short-name]-pm
```

**Context compression:**
Use `/compress` when context grows large. After compression, re-read state
files (BACKLOG.md, STATUS.md, PLATFORM-SKILLS.md) to restore accuracy.

**Cross-session memory:**
Use `save_memory` to persist important cross-session facts to
`~/.gemini/GEMINI.md`. Reserve this for facts that must survive session loss
— project decisions, conventions, recurring context. Do not store state that
belongs in project files.

---

## Codex CLI / ChatGPT Web daily workflow

**Codex CLI resume:**
```bash
cd /path/to/your-project
git pull
codex --resume
```

**ChatGPT Web resume:** Continue the existing dedicated PM chat thread.

**After a long gap (ChatGPT Web):** Re-paste BACKLOG.md, STATUS.md, and the
current phase from IMPLEMENTATION-PLAN.md to refresh context. Long threads
degrade — start a new thread if the old one becomes unwieldy.

**File writes:** ChatGPT Web has no native file write. Output content for
manual application, or delegate writes to Codex CLI.

---

## Cross-machine workflow (all tools)

1. Always `git pull` before starting any session on any machine
2. Commits made on machine A are immediately visible on machine B after `git pull`
3. Session history is a convenience — the repo files are the authoritative memory
4. Run the appropriate startup procedure after `git pull` on any machine where
   the session is stale
5. Never copy or sync tool-specific session files between machines (`.claude/`,
   Gemini session files, ChatGPT threads)

---

## Troubleshooting

**mcp-local-rag not responding:**
```bash
cat .mcp.json    # verify BASE_DIR is correct absolute path
```
Then restart the CLI session. The embedding model downloads automatically on
first ingest — if that never completed, re-run the ingest command in the session.

**To update mcp-local-rag to the latest version:**
```bash
npx --prefer-online -y mcp-local-rag --help
```
Re-ingest your docs after updating — the vector index format may change between versions.

**RAG returns stale or wrong results:**
First check whether the index has orphans (paths that shouldn't be
there) or stale chunks (chunks reflecting outdated file content):

1. In your PM chat session, call the `local-rag` MCP `list` tool to
   read the current ingest. Compare against the manifest declared
   in `docs/pack/PM-CHAT.md` § RAG ingestion manifest.
2. If a path appears in `list` but not in the manifest, it is an
   **orphan** from a prior pack version or a retired file. Run
   `local-rag.delete <path>` for each orphan.
   **Re-ingestion alone will not remove orphans** — they live in
   the index until explicitly deleted.
3. If the manifest path's chunks reflect outdated content (the
   source file was edited after the last ingest), run
   `local-rag.delete <path>` followed by `local-rag.ingest <path>`
   to rebuild from current content.

This sequence is the same one `/pm-startup` Step 4 executes
automatically on every startup. The manual procedure is useful when
you want to trigger reconciliation outside of a startup, or when
investigating a specific suspected stale-retrieval incident.

See `supporting-docs/METHODOLOGY.md § RAG index hygiene` for the
underlying principle (orphans are confidently-wrong retrievals).

**Compaction happened mid-session:**
Run `/pm-startup` — it re-reads BACKLOG.md, STATUS.md, and other key files
from disk to restore accurate context.

**PM-CHAT.md still shows `[PROJECT_NAME]`:**
The PM chat fills this in during the kickoff conversation (`docs/pack/prompts/pm-chat.md` Variant: kickoff). If it
was skipped, ask the PM chat to read PM-CHAT.md, fill in the project name,
remove the template comment block, and commit the file.
