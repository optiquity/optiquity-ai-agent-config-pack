# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)

Platform-agnostic agent routing for work on the pack repo itself.
Read by Claude Code, Codex, and Gemini when operating on this repo.

---

## Pack agents

Five dedicated agents exist for structured pack development work.
Agent files are in `.claude/agents/`, `.codex/agents/`, and `.gemini/agents/`.

| Agent | Role | Mode |
|---|---|---|
| `pack-architect` | Architecture and design decisions — file structure, naming conventions, cross-tool parity, migration strategy, version planning | Read-only |
| `pack-planner` | Implementation planning — task breakdown, file dependency analysis, commit sequencing, verification strategy | Read-only |
| `pack-coder` | Implementation execution — writes/edits scripts, fixtures, configs, agent files per an approved ARCHITECTURE/PLAN; runs verification; produces a report | Source-write within scope; **never** stages or commits |
| `pack-reviewer` | Change review — trinity rule compliance, stale cross-references, doc consistency, CI alignment, migration safety | Read-only |
| `pack-docs-researcher` | CLI tool documentation verification — features, flags, file formats against official docs. Tool dependency evaluation | Read-only |

### Skills loaded by pack agents

Skills are in `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
(copied from `project-template/skills/` — not read from there at runtime).

| Skill | Used by |
|---|---|
| `planning` | pack-planner, pack-architect |
| `architecture-review` | pack-architect, pack-planner, pack-reviewer |
| `documentation` | pack-architect, pack-docs-researcher |
| `review` | pack-reviewer |
| `dependency-intake` | pack-docs-researcher |
| `implementation-report` | pack-coder |
| `verification-harness` | pack-coder |
| `commit-discipline` | pack-coder, pack-architect, pack-planner, pack-reviewer, pack-docs-researcher |

---

## How to invoke pack agents

### Sub-agent invocation (from pack chat)

The pack chat uses the Task tool to spawn pack agents for focused,
bounded questions within the current conversation:

- "Verify this Gemini CLI flag exists" → spawn `pack-docs-researcher`
- "Review these changes before commit" → spawn `pack-reviewer`
- "Plan the commit sequence for these files" → spawn `pack-planner`
- "Implement the C-2 commit per PLAN-BD-NNN.md" → spawn `pack-coder`

The pack chat stays in control, receives the result, and continues.
Use this mode for questions that need a focused answer, not extended
back-and-forth.

### Separate terminal session (developer-initiated)

For substantial work that benefits from a dedicated conversation:

```bash
# Claude Code
claude --agent pack-architect
claude --agent pack-planner
claude --agent pack-coder
claude --agent pack-reviewer
claude --agent pack-docs-researcher

# Codex CLI
codex --agent pack-architect
codex --agent pack-planner
codex --agent pack-coder

# Gemini CLI (from pack repo root)
gemini    # then type: @pack-architect (or @pack-planner, @pack-coder, ...)
```

Use this mode for:
- Major design work (v10 design pass, migration strategy)
- Deep research requiring multiple web searches
- Extended planning sessions with back-and-forth iteration
- Independent review that should not be influenced by the pack chat's
  prior context

### Feeding results back to the pack chat

When a separate session produces output the pack chat needs:
1. Copy the key findings or decisions (not the full transcript)
2. Paste them into the pack chat with context: "The pack-architect
   session concluded X. Here is the summary: ..."
3. The pack chat incorporates the result and continues

---

## When agents are used vs. pack chat direct

| Work type | Who does it | Why |
|---|---|---|
| Design decisions, architecture | `pack-architect` (separate session) | Extended reasoning, clean context |
| Implementation planning | `pack-planner` (separate session or sub-agent) | Structured output, file analysis |
| Implementation (writing/editing source) | `pack-coder` (separate session or sub-agent) | Plan execution against source; produces report + working-tree edits |
| Pre-commit review | `pack-reviewer` (sub-agent) | Bounded scope, checklist-driven |
| Tool documentation verification | `pack-docs-researcher` (sub-agent or separate) | Web search, source verification |
| Writing BACKLOG.md entries | Pack chat only | PM-level decisions, user approval required |
| Writing CHANGELOG.md entries | Pack chat only | Version-level decisions |
| Writing to README.md version table | Pack chat only | Version-level decisions |
| Staging, committing, or pushing | Pack chat only | After explicit user approval; agents cannot run state-changing git verbs |

---

## Agent permission rules

These rules are enforced across every pack agent. They are also recorded
under "Pack memory" in CLAUDE.md / AGENTS.md / GEMINI.md so agents loading
their tool-native context file see them every session.

**Git state changes are forbidden for ALL agents.** No agent — including
`pack-coder` — may run `git add`, `git commit`, `git push`, `git tag`,
`git rebase`, `git merge`, `git reset`, `git stash`, or `git checkout`
(except `git checkout -- <path>` for read-only inspection at a different
ref). Read-only verbs (`status`, `diff`, `log`, `rev-parse`, `show`,
`ls-files`, `blame`) are allowed.

**Source modifications are restricted by agent role:**
- `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher`
  are read-only on source. Their only Write/Edit calls go to the report
  file the caller specifies.
- `pack-coder` may Write/Edit source files within the scope its caller
  defines, plus its report file. Outside that scope, read-only.

**Every agent produces a report file.** The report is a markdown document
at a caller-specified path. It is the agent's primary deliverable. For
`pack-coder`, the report plus the working-tree edits are both consumed
by Pack Chat.

**Only Pack Chat may stage or commit.** When an agent finishes, Pack Chat
reads the report, verifies (re-runs tests / inspects diffs), then stages
and commits with explicit user approval. Agents cannot delegate this step
to themselves.

**PM-only files** are off-limits to all agents unless the caller's prompt
explicitly scopes them in: BACKLOG.md, CHANGELOG.md, README.md version
table, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md / AGENTS.md / GEMINI.md
(root and `project-template/`).

---

## Agent behavior expectations

Every agent session on this repo:
1. Reads its tool-native context file before starting:
   Claude Code → CLAUDE.md · Codex → AGENTS.md · Gemini → GEMINI.md
   The "Pack memory" section in that file is authoritative — treat it as
   standing rules. All three should also read PACK-AGENTS.md for the
   agent routing table and permission rules above.
2. Reads only the files explicitly listed in the prompt or required by the
   agent definition.
3. Does not modify files unless the agent role permits it (see Agent
   permission rules above) and the prompt explicitly requests it.
4. Reports what it found and confirms no unexpected changes.
5. Never stages or commits — that's Pack Chat's job.

---

## Key conventions to follow

- Commit format: `feat: vN — BD-NNN description` / `fix: description` (N = current major version)
- BD-NNN numbering: read BACKLOG.md to find next available number
- Skills live in `.claude/skills/` (Claude), `.codex/skills/` (Codex), `.gemini/skills/` (Gemini)
- Agent files: `.claude/agents/` (markdown), `.codex/agents/` (TOML), `.gemini/agents/` (markdown with YAML frontmatter)
- Pack repo context files: CLAUDE.md (Claude), AGENTS.md (Codex), GEMINI.md (Gemini), PACK-AGENTS.md (this file)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and confirm staged files before any commit.
