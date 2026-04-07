# CLI-PM-SETUP.md — CLI PM Chat Reference

This document covers daily usage, cross-machine workflow, and troubleshooting
for the CLI PM chat. **Setup is in QUICKSTART.md Steps 11C–11G.** Start there
if you haven't completed setup yet.

---

## Daily session start

**Normal resume (same machine, recent session):**
```bash
cd ~/Developer/[project]
git pull
claude --resume [project-short-name]-pm
```
No need to run `/pm-startup` — session history is current.

**After compaction or a long gap:**
```bash
cd ~/Developer/[project]
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
cd ~/Developer/[project]
git pull
claude --resume [project-short-name]-pm
/pm-startup
```

If no session exists yet on this machine, start one:
```bash
cd ~/Developer/[project]
git pull
claude
/rename [project-short-name]-pm
Ingest METHODOLOGY.md into the RAG index
Ingest PROMPT-TEMPLATES.md into the RAG index
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

When METHODOLOGY.md or PROMPT-TEMPLATES.md changes (new pack version installed),
re-ingest them:

```bash
cd ~/Developer/[project]
claude --resume [project-short-name]-pm
```

Then inside the session:
```
Re-ingest METHODOLOGY.md into the RAG index
Re-ingest PROMPT-TEMPLATES.md into the RAG index
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

## Troubleshooting

**mcp-local-rag not responding:**
```bash
cat .mcp.json                    # verify BASE_DIR is correct absolute path
npx -y mcp-local-rag --version  # re-run pre-warm if needed
```

**RAG returns stale or wrong results:**
Re-ingest the affected file. The `/pm-startup` skill checks modification dates
and flags this automatically.

**Compaction happened mid-session:**
Run `/pm-startup` — it re-reads BACKLOG.md, STATUS.md, and other key files
from disk to restore accurate context.

**PM-CHAT.md still shows `[PROJECT_NAME]`:**
The PM chat fills this in during the kickoff conversation (Template 1). If it
was skipped, ask the PM chat to read PM-CHAT.md, fill in the project name,
remove the template comment block, and commit the file.
