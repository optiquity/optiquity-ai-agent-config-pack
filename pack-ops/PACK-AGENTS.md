# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)

Platform-agnostic agent routing for work on the pack repo itself.
Read by Claude Code, Codex, and Antigravity when operating on this repo.

---

## Pack agents

Five dedicated agents exist for structured pack development work.
Agent files are in `.claude/agents/` (Claude), `.codex/agents/` (Codex),
and the Antigravity plugin bundle `.agents-plugin/pack-agents/agents/`.

| Agent | Class | Role | Mode |
|---|---|---|---|
| `pack-architect` | RO | Architecture and design decisions — file structure, naming conventions, cross-tool parity, migration strategy, version planning | Read-only |
| `pack-planner` | RO | Implementation planning — task breakdown, file dependency analysis, commit sequencing, verification strategy | Read-only |
| `pack-coder` | RW | Implementation execution — writes/edits scripts, fixtures, configs, agent files per an approved ARCHITECTURE/PLAN; runs verification; produces a report | Source-write within scope; **never** stages or commits |
| `pack-reviewer` | RO | Change review — trinity rule compliance, stale cross-references, doc consistency, CI alignment, migration safety | Read-only |
| `pack-docs-researcher` | RO | CLI tool documentation verification — features, flags, file formats against official docs. Tool dependency evaluation | Read-only |

The `Class` column is the **pack-side SSOT** for the read-write / read-only
two-class agent model (see "Two agent classes" below). It is checked
against each agent file's prose mandate header by `scripts/validate-pack.py`
Check 52 (set-equality; binds to the prose header, never `tools:`).

### Skills loaded by pack agents

Skills are in `.claude/skills/`, `.codex/skills/`, `.agents/skills/`
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
| `boundary-investigation` | pack-coder, pack-architect, pack-planner, pack-reviewer, pack-docs-researcher |

---

## How to invoke pack agents

### Sub-agent invocation (from pack chat)

The pack chat uses the Task tool to spawn pack agents for focused,
bounded questions within the current conversation:

- "Verify this Antigravity CLI flag exists" → spawn `pack-docs-researcher`
- "Review these changes before commit" → spawn `pack-reviewer`
- "Plan the commit sequence for these files" → spawn `pack-planner`
- "Implement the C-2 commit per PLAN-BD-NNN.md" → spawn `pack-coder`

The pack chat stays in control, receives the result, and continues.
Use this mode for questions that need a focused answer, not extended
back-and-forth.

**Inject the graph path into every spawn prompt (BD-226, Claude-only).**
Under worktree isolation a spawned agent's `$(git rev-parse
--show-toplevel)` resolves to the empty worktree root, where the gitignored
`graphify-out/` is not materialized. So the orchestrator MUST derive the
real graph path AT RUNTIME in its canonical checkout (the derivation formula
`$(git rev-parse --show-toplevel)/graphify-out/graph.json`) and INJECT the
resolved absolute literal into every spawn prompt — only when that canonical
`graphify-out/graph.json` exists (else inject no path). The agent uses the
injected `--graph <path>`, NEVER its own toplevel. See trinity `## Pack
memory` § "Graph-first context (BD-225)" for the full contract.

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

# Antigravity (from pack repo root)
# Install the pack agent bundle once, then invoke a pack agent via
# Antigravity's subagent mechanism (the bundled pack-<name> role).
agy plugin install ./.agents-plugin/pack-agents
agy        # then invoke the pack-architect (or pack-planner, pack-coder, ...) subagent
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
| Writing `/backlog/` entries | Pack chat only | PM-level decisions, user approval required |
| Writing `/changelog/` entries | Pack chat only | Version-level decisions |
| Writing to README.md version table | Pack chat only | Version-level decisions |
| Staging, committing, or pushing | Pack chat only | After explicit user approval; agents cannot run state-changing git verbs |

---

## Agent permission rules

These rules are enforced across every pack agent. They are also recorded
under "Pack memory" in CLAUDE.md / AGENTS.md / GEMINI.md so agents loading
their tool-native context file see them every session.

**Git state changes are forbidden for ALL agents; only Pack Chat stages
or commits.** Agents never commit — see trinity `## Pack memory`
`[rationale: agents-never-commit]` for the canonical imperative (the
forbidden verbs, the read-only-verb allowance, and the report-plus-
working-tree-edits deliverable contract).

**Source-write scope is the per-agent `Mode` in the roster above.**
Read-only agents (`pack-architect`, `pack-planner`, `pack-reviewer`,
`pack-docs-researcher`) Write/Edit only their caller-specified report;
`pack-coder` Write/Edits source within its caller-defined scope plus its
report — see the "Source-write within scope; never stages or commits"
roster cell and trinity `## Pack memory` `### Pack Chat scope` "What
Pack Chat CAN edit directly" for the canonical write-authority split.

### Two agent classes

Every pack agent is one of exactly two classes. The class is the
load-bearing safety classification — the platform provides **no safety
net for subagents** (a non-isolated background subagent can write the
parent working tree freely), so RW agents run in an isolated worktree
by class-default (not opt-in), and the class is what makes that
enforceable. RO agents run in the tree the work lives in.

- **RW (read-write) — `pack-coder`.** Writes/edits source files within
  the caller-scoped file set, runs verification, and writes its report.
  NEVER runs a state-changing git verb. RW agents run in an isolated
  worktree (class-default); the patch is NOT emitted up front. The patch
  is produced only after review-clean — the orchestrator SendMessage-s
  the most-recent RW agent to produce its `git diff` patch into the named
  `/tmp` handoff dir; only the orchestrator applies it.
- **RO (read-only) — `pack-architect`, `pack-planner`, `pack-reviewer`,
  `pack-docs-researcher`.** Write ONLY their single caller-specified
  report; read-only on the codebase otherwise. RO agents run in the tree
  the work lives in — the main checkout when the work is committed; the
  commit's live worktree when the work is still uncommitted there (cd in
  + verify pwd/HEAD); RO is NOT "always in-place". (`pack-reviewer`
  carries `Write, Edit` in its `tools:` to emit that one report — it is
  still RO; the class is keyed off the prose mandate header, never
  `tools:`.)

Both classes obey `agents-never-commit` + the full destructive-git-verb
ban identically (trinity `## Pack memory` `[rationale: agents-never-commit]`).

The class is declared with TRIPLE reinforcement: (1) the `Class` column
in the `## Pack agents` roster above (the SSOT); (2) the prose mandate
header on every pack agent file (`**Source-write within scope.**` for RW
/ `**Read-only.**` for RO); (3) the inline rules-in-force block in every
spawn prompt. `scripts/validate-pack.py` Check 52 asserts set-equality
between (1) and (2) — it reads the prose header, NEVER `tools:`.

**pack-chat-only files and directories** are off-limits to all agents unless the
caller's prompt explicitly scopes them in.

Files:
- `README.md` version table
- `PACK-CHAT.md`
- `PACK-AGENTS.md`
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root and `project-template/`)
- `PACK-MEMORY-RATIONALE.md` (rule↔rationale bijection partner for `## Pack memory`; edited only in lockstep with rule changes — BD-198)

Directories:
- `/backlog/` — pack per-entry tree (entries; supporting files
  pack-shipped via version-bump only).
- `/changelog/` — pack changelog per-entry tree.
- `project-template/docs/project/backlog/` — project per-entry tree
  canonical templates (ship into client projects).
- `project-template/docs/project/implementation-plan/`
- `project-template/docs/project/changelog/`

Within these directories, `_rules.md`, `_intro.md`, and `_format.md` are
pack-shipped immutable (updated on pack version bump only); `_toc.md` is
derived (regenerator output); per-entry files (e.g.,
`BD-NNN.md`, `TD-NNN.md`, `phase-N.md`, `YYYY-MM-DD-*.md`) are pack-chat-only
writes.

`pack-coder` MAY scope a per-entry directory in for an explicit BD when
Pack Chat's prompt scopes it — the same exception clause that applies to
the pack-chat-only files above.

Per trinity `## Pack memory` `[rationale: pack-chat-minor-edits-only]`, scoping
a pack-chat-only file into a coder prompt is the DEFAULT path for any MAJOR edit to it
(Pack Chat does only MINOR bookkeeping edits directly); the imperative + the
minor-vs-major boundary live in the corpus, not here.

Per-entry decomposition makes the per-entry trees the sole source of
truth (no monolithic mirror). The protected surface MUST cover them or
the source-of-truth invariant breaks: agents could write per-entry files
directly, bypassing Pack Chat write authority. This addition is a
Signal 9 trip per
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 (line 305–306); the architect pass behind v11.0 per-entry split is
the Signal 9 justification.

The pack-self per-entry trees `/backlog/` and `/changelog/` enumerated
above were created by BD-203 (pack self-migration Phase 1), which
converted the monolithic `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md`
into the trees and DELETED the monoliths (no mirror). The trees are the
live SSOT; there is no longer any monolithic file to read or regenerate.

- **Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation.** Every pack-coder
  (or coder-style fix-coder) agent emits the PREFLIGHT trust-signal line
  before any IMPL-REPORT write and halts immediately on a parent stop
  directive — see trinity `## Pack memory` `[rationale: preflight-stop-means-stop]`
  for the canonical imperative (PREFLIGHT line format, the
  `scripts/validate-pack.py` + Check 43 verification gate, the report-failure-
  instead-of-IMPL-REPORT behavior, the STOP-MEANS-STOP halt rule, and
  the cross-CLI scope notes for Codex / Antigravity).

- **Skill and agent maintenance.** Additions and modifications follow
  the maintainability principle in pack-repo trinity `## Pack memory`
  § "Repo conventions" ("Maintenance is mechanical, complete,
  reviewed, and rule-strict ..."). See
  `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
  §3 for thresholds.

---

## Agent behavior expectations

Every agent session on this repo:
1. Reads its tool-native context file before starting:
   Claude Code → CLAUDE.md · Codex → AGENTS.md · Antigravity → GEMINI.md
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
- BD-NNN numbering: read the `/backlog/` tree (e.g. `/backlog/_toc.md`) to find next available number
- Skills live in `.claude/skills/` (Claude), `.codex/skills/` (Codex), `.agents/skills/` (Antigravity)
- Agent files: `.claude/agents/` (Claude, markdown), `.codex/agents/` (Codex, TOML), `.agents-plugin/pack-agents/agents/` (Antigravity plugin bundle, markdown)
- Pack repo context files: CLAUDE.md (Claude), AGENTS.md (Codex), GEMINI.md (Antigravity), PACK-AGENTS.md (this file)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and confirm staged files before any commit.
