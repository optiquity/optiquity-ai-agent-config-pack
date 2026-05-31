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
- `pack-ops/BACKLOG.md` — open BD-NNN items (regenerated mirror; per-entry source at `/backlog/`)
- `pack-ops/CHANGELOG.md` — version history details (regenerated mirror; per-entry source at `/changelog/`)
- `pack-ops/PACK-CHAT.md` — PM chat operating rules
- `pack-ops/PACK-AGENTS.md` — agent routing table for pack development work
- `/backlog/`, `/changelog/` — per-entry source-of-truth trees (read `/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream contract; `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` are the regenerated mirrors)

**Migrator framework (BD-119).** When authoring a new
`scripts/migrate-vN-to-vM.sh`, source `scripts/lib/migrator-core.sh` and
supply the adapter contract (`MIGRATOR_*` vars + the hook functions). See
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for the
contract. Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite — that
regresses the framework.

---

## Rules for agents working on this repo

**Commit message format:**
```
feat: vN — BD-NNN short description
fix: brief description of what was corrected
docs: brief description of documentation change
```
Where N is the current major version (read from README.md version table).

**Approved suffixes for the `fix:` form:**
- `fix: vN — BD-NNN brief description` (per-BD inline fix in current batch)
- `fix: vN — BD-NNN ... (Batch N)` (fix attached to a specific batch)
- `fix: vN — BD-NNN ... (Batch Nx)` (fix attached to a sub-batch — e.g., 19b cleanup)
- `fix: vN — BD-NNN retroactive per-BD review-fix (Batch N)` (retro recovery
  of a per-BD cycle missed in a prior multi-BD batch)
- `fix: vN — broad batch review/fix (Batch N)` (end-of-batch cross-BD
  fix that does not bind to a single BD)

Other `fix:` shapes require Pack-Chat-discussion-and-user-approval before
they land — invented commit-message shapes break audit history.

**Commit-subject scope-keyword convention (CI-enforced via Check 36):**

When a commit's scope is exclusive to one surface, the commit subject MAY
carry one of three case-insensitive keywords. CI Check 36 verifies the
commit's `git diff --name-only` matches the claimed scope; mismatches fail
the gate with a file-path callout.

| Keyword (case-insensitive, in commit subject) | Meaning | Permitted touched paths |
|---|---|---|
| `pack-only` | Pack repo state only | Deny `project-template/` and `supporting-docs/` |
| `project-only` | Project-side state only | Deny pack-only paths (everything outside `project-template/` + `supporting-docs/`) |
| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` § "PM-only files and directories" Files list — notably PERMITS `project-template/` trinity (CLAUDE.md / AGENTS.md / GEMINI.md at `project-template/` ARE PM-only per PACK-AGENTS.md) |
| (no keyword) | Mixed-scope implicit | Check 36 skipped (no claim to verify) |

The vocabulary is intentionally small. Use no keyword for mixed-surface
commits — keyword opt-in means actors who don't want the gate don't carry
it, but actors who claim a scope are held to it.

**Versioning:**
- Minor versions (vN.0, vN.1, ...) for incremental changes
- Major versions for large additions or breaking changes
- Bare major tag always floats to the latest minor (e.g. v9 → v9.0, then → v9.1)
- Tag move sequence: delete local + remote, recreate, push

**BD-NNN numbering:**
- Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
- Reservation lists from other chats, planning docs, or sidecar
  sessions are NOT authoritative — always read the live BACKLOG before
  assigning. Reserved-but-unwritten numbers are guesses, not commitments.

**What agents may modify:**
- Any file in template directories when the task explicitly requires it
- Files in supporting-docs/ or maintenance-docs/ when the task explicitly requires it
- `pack-ops/CHANGELOG.md` only at version boundaries with explicit instruction
- Scripts in template directories

**Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md:**
When modifying `project-template/CLAUDE.md`, always make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit.
These three files must express the same project rules. The only exception is a
change that is provably tool-specific (e.g., Claude Task tool syntax). Symmetry
is the default; asymmetry requires justification. This rule also applies to the
pack-repo copies of these three files.

Note: the trinity rule enforces parity (the three CLI files express the same
rules at a given trinity location — pack-root or project-template). It does
NOT verify that the rule is correct for the surface it lives on (pack-root
trinity vs project-template trinity carry different audiences and different
rules by design). For substance correctness across pack-vs-project surfaces,
see Pack memory `P-missed-7` (boundary discipline) and the
`boundary-investigation` skill — those layers catch the V1-style regression
where actors mistook trinity parity for substance correctness.

**CI validation:** The `Validate Pack` GitHub Actions workflow runs on
every push. If it fails, fix before proceeding. Read the Actions log —
errors name the exact file and problem. Never skip or disable the workflow.

**What agents must never modify without explicit instruction:**
- `pack-ops/BACKLOG.md` (PM chat only, after user approval)
- README.md version table (PM chat only)
- `pack-ops/PACK-CHAT.md` (PM chat operating instructions)
- CLAUDE.md, AGENTS.md, GEMINI.md, `pack-ops/PACK-AGENTS.md` (PM chat only)

**No commit or push without explicit user approval.**
Always run `git add -A && git status` and show staged files before committing.

---

## Pack memory (project-local learnings)

These entries codify learnings from prior sessions. They are authoritative —
treat them as standing rules, not suggestions. Pack Chat and all pack agents
must respect them. When a learning becomes stale, update or remove the entry
in the same commit as the behavior change. To add, change, or remove a
spawn-relevant rule, follow the ordered propagation procedure in
`pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and
PACK-AGENTS.md current".

### Workflow

- **Agents never commit.** No agent — including `pack-coder` — may run
  `git add`, `git commit`, `git push`, `git tag`, or any other state-changing
  git verb at any point in any task; only Pack Chat stages/commits, and only
  with explicit user approval. `[roles: universal]
  [rationale: agents-never-commit]`
- **Pack Chat does not architect.** Architecture, planning, implementation,
  and review work goes to `pack-architect` / `pack-planner` / `pack-coder` /
  `pack-reviewer` directly. Pack Chat handles BACKLOG/CHANGELOG entries,
  routing, approvals, commits, and user-facing decisions.
- **One review/fix cycle per batch.** Run `pack-reviewer` once per batch,
  fix once, move on. Do not propose a second review pass; the final audit
  is user-initiated. Fixes land in the current session. New-BD-opens
  follow the OQ-1 rule per EXECUTION-PLAN §B step 5 + W8 "Deferral IS
  scope creep" (size/blocked/fit + user-discussion-and-approval).
- **Implicit BD status flip on batch completion.** When a batch's review +
  fixes are clean and tests are green, flip its BDs to `Resolved` as the
  final step of the batch — no separate user approval needed.
- **Per-action approval extends to sub-agents.** Every sub-agent obeys the
  same "no state-changing operation without explicit per-action approval"
  rule its parent obeys — never run a destructive file operation (`rm -rf`,
  `git rm`, overwriting a trusted file) on your own authority even when the
  overall task is approved; surface it and wait. `[roles: universal]
  [rationale: per-action-approval-sub-agents]`
- **Deferred work needs a tracked anchor.** When work is genuinely
  deferred (user-authorized; survives the `feedback-deferral-is-scope-
  creep` size/blocked/fit test), it MUST land on a live forward-pointing
  surface AND be scheduled to a specific anchor: an open BD entry, a
  live `// TODO(scope): TD-TBD` comment in code per `project-template/
  CLAUDE.md` § "Deferral comments and BACKLOG hygiene", or a new BD
  inserted at the appropriate plan position. `[roles: universal]
  [rationale: deferred-work-tracked-anchor]`
- **No deferral to v11.1+ without explicit user direction.** While
  v11.0 is unlaunched, ALL work surfaced during v11.0 development MUST
  land in v11.0 unless the user explicitly authorizes deferral; treat any
  architect/reviewer/coder defer-recommendation as a SCOPING signal, not an
  AUTHORITY signal — re-scope to land in v11.0 and surface the blast-radius.
  `[roles: universal] [rationale: no-deferral-without-user-direction]`
- **Deferral IS scope creep.** Treat deferring unblocked work to a later
  BD or batch as tech debt — defend any deferral only with (a) SIZE,
  (b) BLOCKED, or (c) LOGICAL FIT (concrete file/contract evidence, not
  "felt big"/"feels related"/"thematic"), else do the work now.
  `[roles: universal] [rationale: deferral-is-scope-creep]`
- **Per-BD review/fix runs INLINE, before next BD's coder spawns.**
  Multi-BD batches: each BD's review/fix runs inline (coder → reviewer
  → triage → fix-coder → commit → NEXT BD's coder). End-of-batch
  reviewer runs once on the full batch after all per-BD cycles
  complete. Single-BD batches: only one cycle needed. Never delay
  per-BD reviews to end-of-batch retroactive recovery (Batch-21c-
  style); that is an exception for pre-2026-05-15 batches only.
- **Pack Chat presents triage to user before fix-coder spawns.** After
  every reviewer pass, Pack Chat reads the report, triages each
  finding (FIX vs SKIP, with rationale for SKIPs — default FIX-ALL per
  `feedback-fix-all-review-findings`), and surfaces the triage to the
  user. User can override per finding before fix-coder spawns. User
  approves the resulting fix commit (not per-finding approval — that
  was the pre-2026-05-16 pattern and produced too much friction). The
  triage gate is between reviewer and fix-coder; the commit gate is
  between fix-coder IMPL-REPORT and the `git commit`.
- **Triage all reviewer findings; default fix-all; nits become tech
  debt.** Pack Chat surfaces every reviewer finding (BLOCKER / MUST /
  SHOULD / NIT) to the user as a fix-or-defer triage per finding. The
  default for all severities is FIX. NITs that are deferred (with
  user-discussion-and-approval per OQ-1 EXECUTION-PLAN §B) become
  tracked tech debt — never "noted in the report and dropped." Default
  fix-all preserves the small-fix-now contract that prevents tech debt
  accumulation. See `feedback-deferred-work-tracking` and
  `feedback-deferral-is-scope-creep` for the memory-cache pointers.
- **P-missed-7 — project-side investigation precedes pack-style
  defaults.** Before changing ANY project-side file (`project-template/`
  trees, project-shipped content), investigate whether a project-side
  SSOT exists for the concept and use it — never reach for a pack-style
  mechanism (`pack-ops/` files, Pack Chat orchestrator role, pack-* agent
  names, `maintenance-docs/` records) by default, since those are PACK-ONLY
  and importing them is a client-install regression. `[roles: universal]
  [rationale: boundary-investigation-precedes-pack-defaults]`

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
- **Researcher-first pipeline for substantive content.** When agent
  work depends on domain knowledge verified against authoritative
  external sources (CLI docs, tool semantics, framework behavior),
  the pipeline is `pack-docs-researcher` → `pack-architect` →
  `pack-planner` → `pack-coder`. Architect runs AFTER researcher,
  not before, not skipped. The same-architect-vs-fresh-architect
  decision for the second architect pass is per-case user
  discussion at the second-pass decision point.
- **Planner output → user review → coder spawn.** Pack-planner output
  is NEVER auto-approved into a pack-coder spawn. Pack Chat surfaces
  the plan to the user for thorough review (the user may comment, add
  constraints, request structural changes) and waits for explicit
  approval before spawning pack-coder. The planner-to-coder gate is the
  user's last cheap window to redirect work before implementation
  consumes hours of agent time and chat context.
- **Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern.** Before writing your
  IMPL-REPORT, emit ONE plain line `PREFLIGHT: N/N in-scope edits complete;
  verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>` only
  after all edits + verification (in-scope tests + `validate-pack.py` Check 43
  + any relevant per-check tests) PASS — if any failed, report what went wrong
  INSTEAD of a partial IMPL-REPORT; and at ANY point, a parent message saying
  stop/halt/revert/do-not-continue halts ALL work immediately (partial files
  OK; never append to "make consistent"). `[roles: universal]
  [rationale: preflight-stop-means-stop]`

- **Agent prompt enumerates ALL applicable rules inline.** Every
  sub-agent prompt Pack Chat constructs (`pack-architect` /
  `pack-planner` / `pack-coder` / `pack-reviewer` / `pack-fix-coder` /
  `pack-docs-researcher`) MUST enumerate ALL applicable pack-memory
  rules and trinity sections INLINE in the prompt body. Not by
  reference ("see MEMORY.md"); not by hyperlink. The LITERAL rule
  text — name + Why + How-to-apply paragraphs — is pasted into the
  agent prompt. The agent reads its rules from the prompt; it does
  not have to discover them.

  **Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.
  Both BD-195 design failures (C6 PM-only allowlist gap; C7 Check 44
  working-state proof failed by 1213 hits in 114 files) had the same
  shape: the relevant rule was knowable from pack memory but the
  architect did not enumerate it as something to verify before
  declaring complete. Design defects shipped past architect →
  planner → Pack Chat → coder gates, caught only at coder runtime.
  Token cost rises (architect prompt grows from ~500 lines to
  ~2000+ lines); rule compliance becomes auditable because the
  agent's task and rules are co-located.

  **How to apply:** Before spawning ANY sub-agent, Pack Chat
  assembles the prompt with these sections in order: (1) STOP-MEANS-
  STOP + permission boundaries; (2) **NEW "Rules in force" block** —
  copy the LITERAL rule text from every applicable MEMORY.md entry;
  each rule's name + Why + How-to-apply MUST appear verbatim;
  applicability is by topic (architect rules for architect spawns,
  coder rules for coder spawns, etc.) PLUS universally applicable
  rules (trinity, prison, no-state-changing-git, no-destructive-
  without-approval) in every spawn; (3) task description; (4) **NEW
  "Rules-applied verification" instruction** — output ends with a
  Rules-Applied Verification Block (see "Agent output requires
  Rules-Applied Verification Block" below); (5) PREFLIGHT obligation
  where applicable; (6) IMPL-REPORT / output-file requirement. Pack
  Chat NEVER spawns an agent without the rules-in-force block.

- **Agent output requires Rules-Applied Verification Block.** Every
  sub-agent output (architect design doc / planner plan / coder
  IMPL-REPORT / reviewer report / fix-coder report / docs-researcher
  report) MUST end with a **Rules-Applied Verification Block**. For
  each rule listed in the prompt's "Rules in force" block, the agent
  records: (a) **Rule name** as named in MEMORY.md; (b) **Verification
  evidence** — the actual measurement (grep output, file path, count,
  diff, command result), quoted not summarized; (c) **Conclusion** —
  `COMPLIANT` / `N/A: <reason>` / `VIOLATED: <reason>` (empty evidence is
  treated as VIOLATED; AMBIGUOUS is not an allowed terminal state).
  `[roles: universal] [rationale: rules-applied-verification-block]`

- **Architect/planner state-claims require Empirical-Evidence
  Blocks.** Every architect-design or planner-plan output MUST embed
  an **Empirical-Evidence Block** for every state-claim. A state-
  claim is any assertion about repo state or downstream state —
  e.g., "the tree has X," "the tree has NO X," "after step N the
  tree will contain Y," "the allowlist covers all legitimate
  references." Each state-claim is backed by: the actual command
  run; the actual output captured (count, paths, lines — not
  paraphrased); the date / HEAD-SHA at which the measurement was
  taken; the interpretation; a conclusion (SUPPORTED / NOT-SUPPORTED
  / PARTIAL with reason). `[roles: architect planner]
  [rationale: empirical-evidence-blocks]`

- **CI guard design — measure-then-bound.** When an architect
  designs a CI guard, validator, allowlist, or any check that will
  run against the repo at PR-time or CI-time, the architect MUST
  follow this contract: (1) **Measure first** — run the guard's
  matching logic against the actual current repo state; capture the
  complete list of occurrences; (2) **Categorize every occurrence**
  as KEEP (legitimate → allowlist) or STRIP (contamination →
  fix-recipe); (3) **Design fix-recipes** that strip every STRIP-
  classified occurrence; (4) **Size the allowlist exactly to the
  legitimate-set** — no broader; (5) **Verify post-design** the
  guard runs clean against the projected post-fix state. A design
  that declares an allowlist without measuring the tree first is
  INCOMPLETE. A design that widens the allowlist to admit borderline
  / unclassified hits is treating contamination as legitimate by
  default — which defeats the guard's purpose. `[roles: architect]
  [rationale: ci-guard-measure-then-bound]`

### Sub-agent behavior (Claude-only)

- **Spawn all sub-agents with no worktree isolation.** Do not pass
  `isolation: "worktree"` when calling the Agent tool from any chat in
  this repo. Run agents in-place against the parent chat's working
  tree. The Agent tool places sub-worktrees under the main clone's
  `.git/worktrees/` and checks them out at `origin/main` regardless
  of which worktree the parent chat is in — so an agent spawned from
  a v11-dev (or any non-main) chat would audit / edit stable content
  instead of the parent's branch. For parallelism across worktrees,
  open separate Claude Code chat sessions in separate worktree
  directories.
- **Default sub-agent spawns to background.** Every Agent-tool
  invocation from Pack Chat uses `run_in_background: true` so the chat
  stays interactive while the sub runs. User has auto-mode on; the
  background sub will not block the chat. Trinity exemption: this rule
  references the Claude Code Agent tool's `run_in_background` parameter;
  Codex parallel-spawn behavior is implicit (parallel-by-default, capped
  by `agents.max_threads`); Gemini parallel-spawn is implicit via `@`
  invocation. No cross-CLI parity edit needed — each platform's
  parallel-or-async behavior is platform-native.
- **Agent-team stage lifecycle + per-commit fresh-coder.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled, sub-agents spawned
  for a stage (architect → planner → coder → reviewer) stay alive
  within the stage; Pack Chat uses SendMessage for follow-ups against
  the same instance. After the stage's commit lands, close ALL stage
  sub-agents and respawn fresh for the next stage. Additionally: each
  pack-coder commit gets a FRESH coder instance — never reuse a coder
  across commits, even within a stage. Per-BD review/fix cycle = fresh
  coder for the implementation, fresh coder for the fix. Trinity
  exemption: Agent Teams + SendMessage are Claude-Code-specific
  (Codex / Gemini have no peer-messaging equivalent — confirmed absent
  per Codex issue #12462 and Gemini hub-and-spoke docs).
- **Trinity exemption.** This sub-section is Claude-specific (not
  mirrored in `AGENTS.md` / `GEMINI.md`) because it concerns Claude
  Code's Agent tool, `run_in_background` parameter, and Agent Teams /
  SendMessage features — none of which have equivalents in Codex CLI
  or Gemini CLI per research §2.5 / §2.7 / §3.5 / §3.7.

### Pack Chat scope

- **Pack Chat does NO fixes.** Pack Chat's role in any review/fix
  cycle is exactly: spawn pack-reviewer (in background) → read review
  report → triage findings (fix-or-skip per finding, with rationale
  for skips) → present triage to user → spawn fix-coder (in background)
  with the triage decisions → read the fix-coder IMPL-REPORT → stage +
  commit with user approval. Pack Chat does NOT use Edit / Write tools
  to apply review findings. NO threshold exception — there is no "small
  enough to skip the coder" carve-out. A one-line typo fix from a review
  finding goes to fix-coder. Rationale: auditability (fix-coder IMPL-
  REPORT carries the rationale doc), pattern consistency, background
  execution, Pack Chat context preservation.

- **What Pack Chat CAN edit directly** (this is NOT a contradiction
  of the rule above — these are not fixes):
  - Memory files (`~/.claude/projects/<slug>/memory/*.md`) — Pack
    Chat's own operating state, not pack work.
  - PM-only files (BACKLOG.md / CHANGELOG.md / README version table /
    PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root /
    `project-template/` trinity) — see `PACK-AGENTS.md` § "Agent
    permission rules" for the PM-only list. PM-only IS Pack-Chat-direct
    by construction.
  - Pack Chat may NOT edit project-template / supporting-docs /
    maintenance-docs / scripts / fixtures / agent definitions —
    those go to pack-coder.
- **Commit-approval requests include next-steps plan.** Every
  "Approve commit?" prompt to the user MUST include a numbered or
  bulleted list at the bottom of the approval message naming the
  concrete actions Pack Chat plans to take between this commit and
  the next anticipated commit. Each step names a concrete action
  (agent spawn + which agent; direct PM-only edit + which file; test
  run; etc.) — not a vague phase name. If nothing is planned beyond
  this commit, explicitly state "nothing planned." No exceptions for
  "obvious" next steps. Rationale: Pack Chat carries multi-step
  sequences in its head but the user only sees the immediate ask;
  surfacing the plan lets the user redirect BEFORE work happens,
  not after. Hard-stop authority (`feedback-no-destructive-without-
  approval`) attaches to the plan — the user can stop or redirect
  any planned step.
- **Pack-architect spawn protocol.** When work touches rules,
  operating docs, memory files, PACK-CHAT.md, PACK-AGENTS.md, or any
  trinity Pack-memory section, spawn `pack-architect` FIRST to design
  a strategy doc; coder applies mechanically after user approves the
  strategy. Pack-architect spawn is NOT a Pack-Chat-direct decision —
  even when scope clearly calls for it, the architect-spawn requires
  explicit user approval. Rationale: an architect pass commits Pack
  Chat to a multi-stage pipeline (architect → planner → coder →
  reviewer) and reorders future BD work; that ordering decision
  belongs to the user. Pack-planner / pack-coder / pack-reviewer /
  pack-docs-researcher follow standard Pack Chat triage (no
  per-spawn user approval).
- **Batch-scope claims are enforced by CI, not honor system.** When
  Pack Chat frames a batch as `pack-only`, `project-only`, or
  `PM-only` in commit subjects, CI Check 36 verifies the commit diff
  matches the claimed scope. If a batch's work genuinely spans pack +
  project, the commit subject MUST NOT carry an exclusive scope
  keyword — use neutral framing ("BD-NNN cross-surface work") or
  explicitly split the batch into separate pack-side and project-side
  commits. Mis-framing a mixed-scope commit with a pack-only keyword
  is a CI failure, not a discipline note. The keyword vocabulary is
  defined in § "Rules for agents working on this repo" → commit-
  subject scope-keyword convention.

- **Pack Chat NO coder review; bounded reviewer/fix cycle.** Pack
  Chat NEVER reviews coder output directly. Every coder run is
  followed by a BOUNDED review/fix cycle: **maximum 2 review/fix
  pairs + 1 final reviewer pass = 3 reviewer spawns / 2 fix-coder
  spawns per commit**. If issues remain after the final reviewer
  pass, this is a DESIGN-DEFECT SIGNAL — Pack Chat immediately
  spawns `pack-architect` to diagnose root cause + propose path
  forward; no fix-coder pass 3 is allowed.

  **Cycle (per commit):**
  1. **Coder** runs → edits + IMPL-REPORT + Rules-Applied
     Verification Block.
  2. **Reviewer pass 1** (`pack-reviewer` fresh; rules-in-force).
     Clean → skip to step 7. Findings → step 3.
  3. Pack Chat triages findings to user → user approves fix/defer
     per finding → **Fix-coder pass 1** (`pack-fix-coder` fresh;
     rules-in-force; applies user-approved fixes).
  4. **Reviewer pass 2** (`pack-reviewer` fresh; rules-in-force;
     re-verifies). Clean → skip to step 7. Findings → step 5.
  5. Pack Chat triages → user approves → **Fix-coder pass 2**
     (FINAL fix-coder allowed).
  6. **Reviewer pass 3** (`pack-reviewer` fresh; FINAL reviewer
     pass). Clean → step 7. Issues remain → **STOP cycle. Spawn
     `pack-architect`** to diagnose root cause + propose path
     forward to user (typical options: scope-down the commit /
     split into smaller commits / re-sequence / revert and redesign
     / defer to follow-up BD). User decides; no fix-coder pass 3.
  7. Pack Chat brings G7b commit-approval to user with the latest
     clean reviewer report attached.

  **Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.
  Pack Chat's judgment is compromised when it doubles as reviewer
  (BD-195 evidence: missed the C2 staging defect that required
  `--amend`; missed the C7 working-state-proof claim that failed by
  1213 hits). Independent reviewer-agent verification is the
  structural fix. Bounding the cycle (max 2 review/fix pairs + 1
  final review) prevents the infinite-loop race-condition shape
  (where fix A breaks B, fix B re-breaks A) and surfaces design
  defects via architect escalation rather than allowing them to
  hide as repeated local findings. Two fix-coder passes is
  empirically enough for genuine fix-work; if findings persist past
  that, the commit's design is wrong — local patching can't fix it,
  only architect-level intervention can.

  **How to apply:** Pack Chat spawns each agent with rules-in-force
  enumeration. Tracks which pass number is active and exposes it in
  progress markers (`**Reviewer pass 1 of max-3 (C8 of 38)**`,
  `**Fix-coder pass 1 of max-2 (C8 of 38)**`, `**Architect
  escalation (C8 of 38)**`). Routes reports to user (does NOT use
  Read/Edit/Bash to verify coder edits independently — even small
  mechanical commits go through the full cycle). After Reviewer
  pass 3: no more fix-coders; architect escalation only.

  **Architect-escalation contract** (Reviewer pass 3 still dirty):
  Pack Chat spawns `pack-architect` with the coder's IMPL-REPORT,
  all 3 reviewer reports, both fix-coder reports, and the
  persistent-issue list. Architect produces DIAGNOSIS (root cause)
  + PROPOSAL (path forward options). User decides — Pack Chat does
  not pre-select.

  **Final-reviewer-pass note:** Reviewer pass 3 exists ONLY to
  verify fix-coder pass 2 closed the prior cycle's findings. It
  does NOT trigger a new fix round. New findings at pass 3 + any
  unresolved prior findings together trigger architect escalation.

  Sharpens "Pack Chat does NO fixes" earlier in this subsection.

### Repo conventions

- **Per-entry trees vs mirrors — mode-dependent source of truth.**
  In flat-file mode (the default — no `tracker.toml`, or `tracker.toml`
  with `mode.state = "flat-file"`), the pack `/backlog/` and `/changelog/`
  trees, and the project `docs/project/backlog/` /
  `implementation-plan/` / `changelog/` trees, are source of truth for
  entry content. The monolithic `BACKLOG.md` / `CHANGELOG.md` /
  `IMPLEMENTATION-PLAN.md` files at the canonical locations are
  regenerated mirrors — read-stable but never source of truth. In
  tracker mode (`tracker.toml` with `mode.state = "tracker"` and
  `migration.forward_complete = true`), the tracker (e.g., GH Issues)
  is source of truth and BOTH the per-entry tree and the monolithic
  mirror are regenerated from tracker state per the Mode 2 → Mode 3
  transition contract. STATUS.md and any other convenience view carry
  an explicit "never source of truth" disclaimer; if a convenience
  view drifts, the per-entry tree (Mode 2) or the tracker (Mode 3)
  wins. Read more at `<stream>/_rules.md`. `[roles: universal]`
- **`pack-ops/BACKLOG.md` has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the
  `Resolved:` line. Do not propose moving entries to a separate section.
- **Separate pack ops from pack product.** Pack ops files (CLAUDE.md,
  AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.)
  are NEVER mixed into pack product files (`project-template/`,
  `supporting-docs/`). Same applies in reverse. `[roles: universal]`
- **Project-side concepts on pack-side surfaces — deliverable-only.**
  References to project-side concepts (TD entries, phases, phase
  parts, phase tasks) on pack-side surfaces MUST be limited to
  constructing project-side deliverables (templates, scripts that emit,
  validators that check); they MUST NOT appear in pack operations or
  pack-self-management templates/configs. `[roles: universal]
  [rationale: pack-side-project-concepts-deliverable-only]`
- **Enumerate ENCODING surfaces in pack-side audits.** When auditing or
  editing any pack-side surface for rule compliance, enumerate AND update
  in lock-step ALL surfaces that ENCODE its expected state — the surface
  itself, every validator + every TEST file that asserts its content
  invariants, every CI workflow referencing it, and cross-reference docs;
  asymmetric coverage (validators but not tests, or vice versa) creates
  audit gaps. `[roles: reviewer coder]
  [rationale: enumerate-encoding-surfaces]`
- **Test infra is self-provisioned.** Tests that need GitHub repos
  provision them via `gh` CLI with per-step approval and clean up after;
  never touch an existing real repo as a test target — use a scratch repo
  or a `/tmp` clone. `[roles: universal]`
- **Skill and agent maintenance is mechanical by default.**
  Keep skill/agent maintenance mechanical, complete, reviewed, and
  rule-strict, preserving the client `x-` contract; escalate any
  structural change — including a rule change or a broken `x-` contract —
  to architect-then-planner, never convenience. `[roles: universal]
  [rationale: skill-agent-maintenance-mechanical]`
- **Pack-repo code-comment deferrals.** Code comments in pack-repo
  source (`scripts/`, `proto/`, any non-template source) that defer
  work MUST use the typed format defined in `project-template/CLAUDE.md`
  § "Deferral comments and BACKLOG hygiene" — never plain English
  `// TODO`, `// fix later`, or `// FIXME` markers. Typed format:
  `// TODO(scope): TD-TBD — title`, `// KNOWN GAP(severity): TD-TBD —
  title`, `// VERIFY(source): TD-TBD — title` (substitute `#` for `//`
  in Python). `[roles: coder] [rationale: pack-repo-code-comment-deferrals]`
- **Filename uniqueness heuristic.** When introducing new files in the
  pack repo, prefer names that don't collide with any other file
  anywhere in the repo, so prose references are unambiguous even when
  the path is omitted (check `find . -name "<proposed-name>" -not -path
  "./.git/*"` before naming); structurally required collisions (trinity,
  per-skill `SKILL.md`, ecosystem-fixed names) are exempt but their prose
  refs MUST carry path context. `[roles: universal]
  [rationale: filename-uniqueness-heuristic]`
- **Architect-doc-vs-reality reconciliation.** When a BD realizes a
  design anticipated in an architect doc, ship the reconciliation
  chain: (a) in-code docstring naming the realized consumer (file +
  symbol; never line numbers — line numbers drift), (b) architect-doc
  addendum cross-referencing the realized consumer, (c) IMPL-REPORT
  cross-reference linking both. `[roles: architect coder]
  [rationale: architect-doc-reality-reconciliation]`
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`. Any commit whose diff includes
  a file under any of these four directories MUST also regenerate
  `test-fixtures/manifest.txt` (run `bash test-fixtures/build.sh
  --all --clean`) and stage it alongside the scope edits in the SAME
  commit when the manifest diff is non-empty. `[roles: coder]
  [rationale: regenerate-manifest-v11-surface]`
- **Cross-CLI reference normalization in `project-template/` trinity.**
  When editing references to per-CLI paths or commands in
  `project-template/{CLAUDE,AGENTS,GEMINI}.md`, substitute the
  audience-correct canonical value per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`
  §4.1 canonical reference table — NOT a byte-identical cross-trinity
  copy. `[roles: coder] [rationale: cross-cli-reference-normalization]`

### Project goals (v11)

- Pack tracker opt-in works with little to no user intervention; flat-file
  is default; tracker is opt-in but easy.
- OT-style v10→v11 migration is automated; OT itself is read-only for
  testing (use `/tmp` clones or scratch fixtures, never write to real OT).
