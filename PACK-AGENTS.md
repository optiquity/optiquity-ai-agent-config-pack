# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)

Platform-agnostic agent routing for work on the pack repo itself.
Read by Claude Code, Codex, and Gemini when operating on this repo.

---

## Pack agents

Four dedicated agents exist for structured pack development work.
Agent files are in `.claude/agents/`, `.codex/agents/`, and `.gemini/agents/`.

| Agent | Role | Mode |
|---|---|---|
| `pack-architect` | Architecture and design decisions — file structure, naming conventions, cross-tool parity, migration strategy, version planning | Read-only |
| `pack-planner` | Implementation planning — task breakdown, file dependency analysis, commit sequencing, verification strategy | Read-only |
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

---

## How to invoke pack agents

### Sub-agent invocation (from pack chat)

The pack chat uses the Task tool to spawn pack agents for focused,
bounded questions within the current conversation:

- "Verify this Gemini CLI flag exists" → spawn `pack-docs-researcher`
- "Review these changes before commit" → spawn `pack-reviewer`
- "Plan the commit sequence for these files" → spawn `pack-planner`

The pack chat stays in control, receives the result, and continues.
Use this mode for questions that need a focused answer, not extended
back-and-forth.

### Separate terminal session (developer-initiated)

For substantial work that benefits from a dedicated conversation:

```bash
# Claude Code
claude --agent pack-architect
claude --agent pack-planner
claude --agent pack-reviewer
claude --agent pack-docs-researcher

# Codex CLI
codex --agent pack-architect
codex --agent pack-planner

# Gemini CLI (from pack repo root)
gemini    # then type: @pack-architect
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
| Pre-commit review | `pack-reviewer` (sub-agent) | Bounded scope, checklist-driven |
| Tool documentation verification | `pack-docs-researcher` (sub-agent or separate) | Web search, source verification |
| Writing BACKLOG.md entries | Pack chat only | PM-level decisions, user approval required |
| Writing CHANGELOG.md entries | Pack chat only | Version-level decisions |
| Writing to README.md version table | Pack chat only | Version-level decisions |
| Committing or pushing | Developer only | After explicit approval |

---

## Agent behavior expectations

Every agent session on this repo:
1. Reads its tool-native context file before starting:
   Claude Code → CLAUDE.md · Codex → AGENTS.md · Gemini → GEMINI.md
   All three should also read PACK-AGENTS.md for the agent routing table.
2. Reads only the files explicitly listed in the prompt or required by the
   agent definition.
3. Does not modify files unless the agent role permits it and the prompt
   explicitly requests it. All four pack agents are read-only by default.
4. Reports what it found and confirms no unexpected changes.

---

## Key conventions to follow

- Commit format: `feat: vN — BD-NNN description` / `fix: description` (N = current major version)
- BD-NNN numbering: read BACKLOG.md to find next available number
- Skills live in `.claude/skills/` (Claude), `.codex/skills/` (Codex), `.gemini/skills/` (Gemini)
- Agent files: `.claude/agents/` (markdown), `.codex/agents/` (TOML), `.gemini/agents/` (markdown with YAML frontmatter)
- Pack repo context files: CLAUDE.md (Claude), AGENTS.md (Codex), GEMINI.md (Gemini), PACK-AGENTS.md (this file)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and confirm staged files before any commit.
