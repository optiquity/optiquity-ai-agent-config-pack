# GEMINI.md — AI Agent Config Pack (Pack Repo)

Context file for Gemini CLI working on this repo. Loaded automatically at session start.
Keep this file concise — it is loaded into every prompt.

## Quick reference

- **Pack commands:** run `pack help` for the full verb list, or `/pack-help` in your CLI.
- **Recommended first action:** run `pack-startup` (or your CLI's equivalent).

---

## What this repo is

Optiquity AI Agent Config Pack: versioned Claude Code, Codex, and Gemini CLI agent
configuration files for Swift / Python / gRPC projects. Ships template directories,
agent files, skills, scripts, and supporting documentation.

---

## Repo structure

See `README.md` (version table + Repository Layout) — authoritative reference; do
not rely on hardcoded directory listings here (structure changes between major
versions).

Key docs: `README.md` (version table), `/backlog/` (BD-NNN items;
per-entry tree, sole SSOT — `/backlog/_toc.md` index), `/changelog/`
(version history; per-entry tree, sole SSOT — `/changelog/_toc.md` index),
`pack-ops/PACK-CHAT.md` (PM chat rules), `pack-ops/PACK-AGENTS.md` (agent routing for pack
work). Per-entry trees are the SOLE SSOT + readable form (there is no
monolithic mirror — BD-203 deleted `pack-ops/BACKLOG.md` +
`pack-ops/CHANGELOG.md`): read `/backlog/_rules.md` and
`/changelog/_rules.md` for the per-stream contract before any per-entry
edit.

**Migrator framework (BD-119).** When authoring a new
`scripts/migrate-vN-to-vM.sh`, source `scripts/lib/migrator-core.sh` and
supply the adapter contract (`MIGRATOR_*` vars + the hook functions). See
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for the
contract. Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite — that
regresses the framework.

---

## Rules for agents working on this repo

**Commit format:** `feat: vN — BD-NNN description` | `fix: description` | `docs: description`
Where N is the current major version — read from README.md version table before committing.

**Approved `fix:` suffixes:** `fix: vN — BD-NNN description` (per-BD inline) | `fix: vN — BD-NNN ... (Batch N)` (batch-scoped) | `fix: vN — BD-NNN ... (Batch Nx)` (sub-batch) | `fix: vN — BD-NNN retroactive per-BD review-fix (Batch N)` (retro recovery) | `fix: vN — broad batch review/fix (Batch N)` (cross-BD batch fix). Other `fix:` shapes need Pack-Chat-discussion-and-user-approval.

**Commit-subject scope-keyword convention (CI-enforced via Check 36):**
When a commit's scope is exclusive to one surface, the subject MAY carry
one of three case-insensitive keywords. CI Check 36 verifies the diff
matches the claim; mismatches fail the gate with a file-path callout.

| Keyword | Meaning | Permitted touched paths |
|---|---|---|
| `pack-only` | Pack repo state only | Deny `project-template/` and `supporting-docs/` |
| `project-only` | Project-side state only | Deny pack-only paths |
| `pack-chat-only` | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` pack-chat-only Files list — PERMITS `project-template/` trinity |
| (no keyword) | Mixed-scope implicit | Check 36 skipped |

Use no keyword for mixed-surface commits — keyword opt-in.

**Versioning:** Minor tags (vN.M, vN.M+1) for incremental changes. Major tags for
breaking changes or large additions. Bare major tag always floats to latest minor.
Tag move sequence: delete local + remote, recreate, push.

**BD numbering:** Always read the `/backlog/` tree (e.g. `/backlog/_toc.md`) to find the highest existing BD
number, then increment by 1. Never assign a BD number from memory or
from another chat's reservation list — reservations are not authoritative.
No letter suffix on a SEPARATE BD — integer ID only, never a trailing letter;
next INTEGER; a sub-part is a SECTION in the parent BD's body.

**What agents may modify:**
- Template files, supporting-docs/, maintenance-docs/: when task explicitly requires
- The `/changelog/` tree: only at version boundaries with explicit instruction
- Scripts in template directories

**What agents must never modify without explicit instruction:**
- The `/backlog/` + `/changelog/` per-entry trees: PM chat only, after user approval
- README.md version table: PM chat only
- `pack-ops/PACK-CHAT.md` / CLAUDE.md / AGENTS.md / `pack-ops/PACK-AGENTS.md` / GEMINI.md: PM chat only

**Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md:**
When modifying `project-template/CLAUDE.md`, make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same commit.
Same project rules in all three. Only exception: provably tool-specific changes.
This rule also applies to the pack-repo copies of these three files.

Note: the trinity rule enforces parity (the three CLI files express the same
rules at a given trinity location — pack-root or project-template). It does
NOT verify that the rule is correct for the surface it lives on (pack-root
trinity vs project-template trinity carry different audiences and different
rules by design). For substance correctness across pack-vs-project surfaces,
see Pack memory `P-missed-7` (boundary discipline) and the
`boundary-investigation` skill.

**CI validation:** The `Validate Pack` GitHub Actions workflow runs on every push.
If it fails, fix before proceeding. Never skip or disable the workflow.

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
  tracked tech debt per `feedback-deferred-work-tracking` — never
  "noted in the report and dropped." Default fix-all preserves the
  small-fix-now contract that prevents tech debt accumulation
  (per `feedback-deferral-is-scope-creep`).
- **P-missed-7 — project-side investigation precedes pack-style
  defaults.** Before changing ANY project-side file (`project-template/`
  trees, project-shipped content), investigate whether a project-side
  SSOT exists for the concept and use it — never reach for a pack-style
  mechanism (`pack-ops/` files, Pack Chat orchestrator role, pack-* agent
  names, `maintenance-docs/` records) by default, since those are PACK-ONLY
  and importing them is a client-install regression. `[roles: universal]
  [rationale: boundary-investigation-precedes-pack-defaults]`

### Agent invocation rules

- **Pack agent invocation.** Pack agents are invoked from `gemini` via
  `@pack-<name>`, or as a sub-agent within Pack Chat. The pack repo has no
  `agent-run.sh` — that's a project template helper, not a pack invocation
  method.
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
  sub-agent prompt Pack Chat constructs MUST enumerate ALL applicable
  pack-memory rules + trinity sections INLINE as literal rule text
  (name + Why + How-to-apply), never by reference or hyperlink — before
  spawning ANY sub-agent, assemble a "Rules in force" block selecting
  the rules tagged for the spawn's role plus the universal rules. Pack
  Chat NEVER spawns an agent without the rules-in-force block.
  `[roles: universal] [rationale: enumerate-rules-inline]`

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
  - pack-chat-only files (the `/backlog/` + `/changelog/` trees / README version table /
    PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root /
    `project-template/` trinity) — see `PACK-AGENTS.md` § "Agent
    permission rules" for the pack-chat-only list. pack-chat-only IS Pack-Chat-direct
    by construction.
  - Per V2 §D, Gemini has no pack-shipped per-project memory cache
    (Gemini's "memory" IS the `GEMINI.md` hierarchy itself — there is
    no separate generated state directory analogous to the Claude
    memory cache). Pack rules reach Gemini via this `GEMINI.md`
    trinity surface only; the `/memory show` and `/memory reload`
    commands operate on this same hierarchy.
  - Pack Chat may NOT edit project-template / supporting-docs /
    maintenance-docs / scripts / fixtures / agent definitions —
    those go to pack-coder.
- **Pack Chat does MINOR edits only; coder does every MAJOR edit and
  everything outside the small set.** On the small pack-chat-only set — the
  `/backlog/` + `/changelog/` trees, the `README.md` version table, `PACK-CHAT.md`,
  `PACK-AGENTS.md`, the trinity `CLAUDE/AGENTS/GEMINI.md` (pack root +
  `project-template/`), `PACK-MEMORY-RATIONALE.md`, and the per-entry tree
  directories (`/backlog/`, `/changelog/`, `project-template/docs/project/
  {backlog,implementation-plan,changelog}/`) — Pack Chat may apply directly:
  (a) bookkeeping tokens (a `Status:`/`Resolved:` state flip, a version bump, a
  dated note, a README version-table row, a CHANGELOG release-block append); and
  (b) AUTHORING A NEW ENTRY — opening a substantive BD entry or authoring a NEW
  version-boundary CHANGELOG entry — because a new entry is already user-reviewed
  governance (the user approves BD-opens and version-boundary CHANGELOG content).
  Every MAJOR edit goes to a `pack-coder` scoped in by Pack Chat's prompt, under
  the bounded review/fix cycle. An edit is MAJOR if it makes a SUBSTANTIVE edit
  to ALREADY-LANDED content (re-scoping an existing entry; a multi-field rewrite
  of a landed entry; a bulk hand-rewrite of a monolith), OR alters a
  rule/contract, OR touches any file OUTSIDE the small set. Deleting-and-
  reauthoring an existing entry-ID is a substantive edit of landed content (=
  MAJOR), NOT a new authoring — the new-entry carve-out covers genuinely new IDs
  only. When in doubt between a new-entry author and an existing-content edit, it
  is MAJOR (route to coder). Pack Chat scoping a pack-chat-only file INTO a coder prompt
  is the supported path for major pack-chat-only work — it is NOT a boundary violation.
  Pack Chat retains only:
  commits (`agents-never-commit`), irreducible user-approved destructive ops
  (deletions), and its own out-of-repo memory files. A Pack-Chat-direct edit is
  still an IMPLEMENTATION: Pack Chat's `validate-pack`/parity/grep sanity pass is
  the bounded check on it; a NEW-ENTRY author rides on the user's own governance
  review of the open/changelog content (the user approves it), not a coder
  reviewer. The moment an edit instead touches ALREADY-LANDED content
  substantively — or any out-of-small-set file — it is MAJOR and the independent
  reviewer applies via the coder cycle.
  `[roles: universal] [rationale: pack-chat-minor-edits-only]`
- **Commit-approval requests include next-steps plan.** Every
  "Approve commit?" prompt to the user MUST include a numbered or
  bulleted list at the bottom of the approval message naming the
  concrete actions Pack Chat plans to take between this commit and
  the next anticipated commit. Each step names a concrete action
  (agent spawn + which agent; direct pack-chat-only edit + which file; test
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
  `pack-chat-only` in commit subjects, CI Check 36 verifies the commit diff
  matches the claimed scope. If a batch's work genuinely spans pack +
  project, the commit subject MUST NOT carry an exclusive scope
  keyword — use neutral framing ("BD-NNN cross-surface work") or
  explicitly split the batch into separate pack-side and project-side
  commits. Mis-framing a mixed-scope commit with a pack-only keyword
  is a CI failure, not a discipline note. The keyword vocabulary is
  defined in § "Rules for agents working on this repo" → commit-
  subject scope-keyword convention.

- **Pack Chat NO coder review; bounded reviewer/fix cycle.** Pack
  Chat NEVER reviews coder output directly and does NO fixes itself;
  every coder run is followed by a BOUNDED review/fix cycle — maximum
  2 review/fix pairs + 1 final reviewer pass = 3 reviewer / 2 fix-coder
  spawns per commit. If dirty after the final reviewer pass, STOP the
  cycle and spawn `pack-architect` to diagnose root cause + propose a
  path forward — no fix-coder pass 3 is allowed.
  `[roles: universal] [rationale: bounded-review-fix-cycle]`

### Repo conventions

- **Per-entry trees — sole SSOT (pack: no mirror).**
  The pack `/backlog/` and `/changelog/` per-entry trees (each with a
  generated `_toc.md` index) are the **SOLE source of truth and readable
  form** for pack entries. **There is no monolithic mirror** — BD-203
  deleted `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md`; do not
  recreate them. The project streams (`docs/project/backlog/` /
  `implementation-plan/` / `changelog/`) are per-entry source of truth in
  flat-file mode (the default — no `tracker.toml`, or `tracker.toml` with
  `mode.state = "flat-file"`); their monolithic `BACKLOG.md` /
  `IMPLEMENTATION-PLAN.md` / `CHANGELOG.md` files remain regenerated
  mirrors (read-stable but never source of truth) until BD-206 retires
  the project-side mirror. In tracker mode (`tracker.toml` with
  `mode.state = "tracker"` and `migration.forward_complete = true`), the
  tracker (e.g., GH Issues) is source of truth and the per-entry tree is
  regenerated from tracker state per the Mode 2 → Mode 3 transition
  contract. In tracker mode the tree + `_toc.md` are a ONE-WAY
  regenerated mirror — never hand-edit them; a hand-edit is overwritten
  without detection at the next `pack tracker tree-rebuild`, and all
  entry writes go through the tracker tooling (tracker mode is a
  per-checkout LOCAL opt-in — the committed PACK repo is always flat-file;
  `tracker.toml` is local and gitignored). Write procedure per
  `<stream>/_rules.md`.
  STATUS.md and any other convenience view carry an explicit
  "never source of truth" disclaimer; if a convenience view drifts, the
  per-entry tree (Mode 2) or the tracker (Mode 3) wins. Read more at
  `<stream>/_rules.md`. `[roles: universal]`
- **The `/backlog/` tree has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the `Resolved:`
  line. Do not propose moving entries to a separate section. The flip's
  write channel is mode-dependent: in flat-file mode, flip in the
  per-entry file (`/backlog/BD-NNN.md`) and regenerate `_toc.md`; in
  local tracker mode, the flip is a tracker write via the tracker
  tooling, and the tree reflects it at the next regeneration.
  `[roles: universal]`
- **Separate pack ops from pack product.** Pack ops files (CLAUDE.md,
  AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, the `/backlog/` + `/changelog/` trees, etc.)
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
- **Dependency-direction governs file location; client deliverables default
  to project-side.** A file's location is governed by DEPENDENCY DIRECTION,
  not ship-status: a project-side deliverable must NEVER be a runtime
  dependency of a pack operation (the reverse — pack-side libs being a
  dependency of project deliverables — is fine). The default home for a new
  client-shipped script is `project-template/scripts/`; BUT a file a pack
  operation depends on at runtime (e.g. `init-project.sh` `source`s it) MUST
  stay pack-side even if it also ships. A pack-side file may ship to clients
  ONLY when BOTH (1) a pack operation depends on it at runtime AND (2) a
  client surface invokes it — and ONLY via the frozen
  `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist in `scripts/validate-pack.py` (CI
  Check 47 enforces install-map↔constant set-equality; growing the constant
  requires architect+user sign-off). Current sanctioned set: exactly
  `{scripts/lib/detect.sh, scripts/pack-help.sh}`. `[roles: architect coder]
  [rationale: dependency-direction-placement]`

### Project goals (v11)

- Pack tracker opt-in works with little to no user intervention; flat-file
  is default; tracker is opt-in but easy.
- OT-style v10→v11 migration is automated; OT itself is read-only for
  testing (use `/tmp` clones or scratch fixtures, never write to real OT).

---

## Gemini CLI operating notes

Use `/chat save <tag>` to save session state before ending a session.
Use `save_memory` to persist cross-session facts to ~/.gemini/GEMINI.md.
Read-only agents (pack-reviewer, pack-docs-researcher) run in default mode — per-command approval. Do not use Plan Mode (`--approval-mode=plan`); it blocks all command execution. Invoke pack agents directly (`gemini` then `@pack-reviewer`) — the pack repo does not have agent-run.sh.
Native file write tools replace Desktop Commander — both achieve the same result.
Session files are local; sync state between machines via project docs (committed to repo).
