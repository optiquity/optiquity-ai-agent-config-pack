# PACK-CHAT.md — Pack Chat Startup and Operating Instructions

This file is the startup and operating reference for the CLI chat session used
to develop and maintain the AI Agent Config Pack. It is specific to the pack repo
and is not a template — it is not copied to coding projects.

---

## Role

You are the persistent assistant for maintaining and developing the DHS AI Agent
Config Pack (the `dhs-ai-agent-config-pack` repo). You:
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
| `supporting-docs/METHODOLOGY.md` | Direct read (on demand) | Author of this file — read directly when needed |
| `supporting-docs/PROMPT-TEMPLATES.md` | Direct read (on demand) | Author of this file — read directly when needed |

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
- **Separation of pack operations and pack product.** The files and workflows used
  to maintain the pack repo (PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md, AGENTS.md,
  GEMINI.md, BACKLOG.md, CHANGELOG.md, README.md) are completely separate from
  the files the pack ships to coding projects (everything under `project-template/`,
  `supporting-docs/`, `maintenance-docs/`). Never mix the two — do not add product
  file references to operational key-file lists, do not add pack-maintenance
  workflows to project methodology, and do not let pack operational concerns leak
  into template content. If a boundary feels unclear, ask before crossing it.
- **Delegate to pack agents when appropriate.** Four pack agents exist for
  structured work: `pack-architect`, `pack-planner`, `pack-reviewer`, and
  `pack-docs-researcher`. See PACK-AGENTS.md for their roles, invocation
  methods, and when to use each. Use sub-agent invocation (Task tool) for
  focused bounded questions within the current conversation. Recommend a
  separate terminal session for substantial work (major design, deep research,
  extended planning). Do not duplicate work an agent is doing — delegate and
  wait for results. Do not use pack agents for PM-level decisions (BACKLOG
  entries, CHANGELOG entries, version management) — those remain pack chat
  responsibilities.
- **Check CI after every push.** After every commit and push, check the
  `Validate Pack` workflow status. If the GitHub MCP server is configured
  for this repo (see note below), use `list_workflow_runs` to check
  directly. If not, remind the user to check the GitHub Actions tab (or
  run `gh run list --workflow=validate-pack.yml -L 1`). If CI fails,
  read the error, fix the file, and re-push before continuing. CI failures
  are fix-immediately items — never defer them to BACKLOG.

> **GitHub MCP server (optional, pack repo only):** The official GitHub
> MCP server enables the Pack Chat to check CI status, read workflow logs,
> and interact with GitHub directly. Without it, the Pack Chat must ask
> the user to check CI manually. To configure: add the GitHub MCP server
> to the pack repo's `.mcp.json` (not the project template's
> `.mcp.json.example` — that is for downstream projects). See
> https://github.com/github/github-mcp-server for setup. This is a pack
> repo operational tool, not a project dependency.

---

## Session naming and resume

Replace `~/[dev-directory]/dhs-ai-agent-config-pack` with the actual path where
you cloned the repo. Replace `pack-chat` with your preferred session name if desired
— use it consistently across machines.

**First start on this machine:**
```bash
cd ~/[dev-directory]/dhs-ai-agent-config-pack
git pull
claude
/rename pack-chat
/pack-startup
```

**Normal resume (same machine):**
```bash
cd ~/[dev-directory]/dhs-ai-agent-config-pack
git pull
claude --resume pack-chat
```

**New or different machine — session already exists on this machine:**
```bash
cd ~/[dev-directory]/dhs-ai-agent-config-pack
git pull
claude --resume pack-chat
/pack-startup
```

**New or different machine — no session exists yet on this machine:**
```bash
cd ~/[dev-directory]/dhs-ai-agent-config-pack
git pull
claude
/rename pack-chat
/pack-startup
```

---

## Cross-machine instructions

The repo is the memory — not the session history. When moving between machines:

1. Run `git pull` before starting any session
2. If the session exists on this machine, resume it and run `/pack-startup`
3. If no session exists, start fresh, rename it `pack-chat`, and run `/pack-startup`
4. Never sync session files between machines

---

## Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current

These four files describe how agents should behave when working on the pack repo.
They must stay accurate. After any commit that changes the repo's structure, naming
conventions, agent roster, workflow, or core operating rules:

- Review all four files for anything that has become stale
- Update in the same commit as the structural change, or in the immediately following commit
- Do not let a minor version tag land with stale agent context files
