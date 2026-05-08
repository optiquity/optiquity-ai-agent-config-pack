# CLAUDE.md — AI Agent Config Pack (Pack Repo)

This file is read by Claude Code CLI agents working on the pack repo itself.
It is NOT a template and is NOT copied to coding projects.

## Quick reference

- **Pack commands:** run `pack help` for the full verb list, or `/pack-help` in your CLI.
- **Recommended first action:** run `pack-startup` (or your CLI's equivalent).

---

## What this repo is

The Optiquity AI Agent Config Pack provides
versioned Claude Code, Codex, and Gemini CLI agent configuration files for
Swift / Python / gRPC projects. It ships template directories, agent files,
skills, scripts, and supporting documentation.

---

## Repo structure

See `README.md` — the Repository Layout section is the authoritative reference.
Do not rely on any hardcoded directory listing here; the structure changes between
major versions.

Key files to read before working on the pack:
- `README.md` — version history and layout
- `BACKLOG.md` — open BD-NNN items
- `CHANGELOG.md` — version history details
- `PACK-CHAT.md` — PM chat operating rules
- `PACK-AGENTS.md` — agent routing table for pack development work

---

## Rules for agents working on this repo

**Commit message format:**
```
feat: vN — BD-NNN short description
fix: brief description of what was corrected
docs: brief description of documentation change
```
Where N is the current major version (read from README.md version table).

**Versioning:**
- Minor versions (vN.0, vN.1, ...) for incremental changes
- Major versions for large additions or breaking changes
- Bare major tag always floats to the latest minor (e.g. v9 → v9.0, then → v9.1)
- Tag move sequence: delete local + remote, recreate, push

**BD-NNN numbering:**
- Read BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first

**What agents may modify:**
- Any file in template directories when the task explicitly requires it
- Files in supporting-docs/ or maintenance-docs/ when the task explicitly requires it
- CHANGELOG.md only at version boundaries with explicit instruction
- Scripts in template directories

**Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md:**
When modifying `project-template/CLAUDE.md`, always make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit.
These three files must express the same project rules. The only exception is a
change that is provably tool-specific (e.g., Claude Task tool syntax). Symmetry
is the default; asymmetry requires justification. This rule also applies to the
pack-repo copies of these three files.

**CI validation:** The `Validate Pack` GitHub Actions workflow runs on
every push. If it fails, fix before proceeding. Read the Actions log —
errors name the exact file and problem. Never skip or disable the workflow.

**What agents must never modify without explicit instruction:**
- BACKLOG.md (PM chat only, after user approval)
- README.md version table (PM chat only)
- PACK-CHAT.md (PM chat operating instructions)
- CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md (PM chat only)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and show staged files before committing.

---

## Pack memory (project-local learnings)

These entries codify learnings from prior sessions. They are authoritative —
treat them as standing rules, not suggestions. Pack Chat and all pack agents
must respect them. When a learning becomes stale, update or remove the entry
in the same commit as the behavior change.

### Workflow

- **Agents never commit.** No agent — including `pack-coder` — may run
  `git add`, `git commit`, `git push`, `git tag`, or any state-changing git
  verb. Read-only git verbs (`status`, `diff`, `log`, `rev-parse`, `show`)
  are allowed. Only Pack Chat may stage and commit, and only with explicit
  user approval. The agent's output is its report file plus working-tree
  edits; Pack Chat reads the report, verifies, then commits.
- **Pack Chat does not architect.** Architecture, planning, implementation,
  and review work goes to `pack-architect` / `pack-planner` / `pack-coder` /
  `pack-reviewer` directly. Pack Chat handles BACKLOG/CHANGELOG entries,
  routing, approvals, commits, and user-facing decisions.
- **One review/fix cycle per batch.** Run `pack-reviewer` once per batch,
  fix once, move on. Do not propose a second review pass; the final audit
  is user-initiated.
- **Implicit BD status flip on batch completion.** When a batch's review +
  fixes are clean and tests are green, flip its BDs to `Resolved` as the
  final step of the batch — no separate user approval needed.

### Agent invocation rules

- **Pack agent invocation.** Pack agents are invoked via `claude --agent
  pack-<name>` (separate session) or via the Agent tool with
  `subagent_type=pack-<name>` (sub-agent within Pack Chat). The pack repo
  has no `agent-run.sh` — that's a project template helper, not a pack
  invocation method.
- **Agent prompt requirements.** Every agent prompt must include: context
  (what the codebase is, what the task is), output file path, read-only
  flags where applicable, markdown-only directive for outputs, problem /
  goal / success criteria, and an instruction to chunk Write calls for
  outputs over ~300 lines.
- **No solutions in agent prompts.** Agent prompts contain only problem,
  goal, and success criteria. No proposed solutions, no "pick one" options,
  no biased framing. Architects/planners/coders/reviewers reach their own
  conclusions.
- **No prior reviews to pack-reviewer.** Reviewer prompts reference
  ARCHITECTURE / PLAN docs only — never prior `PACK-REVIEW-*.md` reports.
  Including a prior review biases the new review.

### Repo conventions

- **BACKLOG.md has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the
  `Resolved:` line. Do not propose moving entries to a separate section.
- **Separate pack ops from pack product.** Pack ops files (CLAUDE.md,
  AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.)
  are NEVER mixed into pack product files (`project-template/`,
  `supporting-docs/`). Same applies in reverse.
- **Test infra is self-provisioned.** Tests that need GitHub repos
  provision them via `gh` CLI with per-step approval and clean up after.
  Never touch existing real repos as test targets — use scratch repos
  or `/tmp` clones.

### Project goals (v11)

- Pack tracker opt-in works with little to no user intervention; flat-file
  is default; tracker is opt-in but easy.
- OT-style v10→v11 migration is automated; OT itself is read-only for
  testing (use `/tmp` clones or scratch fixtures, never write to real OT).
