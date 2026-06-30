# CLAUDE.md — AI Agent Config Pack (Pack Repo)

This file is read by Claude Code CLI agents working on the pack repo itself.
It is NOT a template and is NOT copied to coding projects.

## Quick reference

- **Pack commands:** run `pack help` for the full verb list, or `/pack-help` in your CLI.
- **Recommended first action:** run `pack-startup` (or your CLI's equivalent).

---

## What this repo is

The Optiquity AI Agent Config Pack provides
versioned Claude Code, Codex, and Antigravity CLI agent configuration files for
Swift / Python / gRPC projects. It ships template directories, agent files,
skills, scripts, and supporting documentation.

---

## Repo structure

See `README.md` — the Repository Layout section is the authoritative reference.
Do not rely on any hardcoded directory listing here; the structure changes between
major versions.

Key files to read before working on the pack:
- `README.md` — version history and layout
- `/backlog/` — open BD-NNN items (per-entry tree; sole SSOT (committed state) — read `/backlog/_toc.md` for an index, `/backlog/_rules.md` for the contract)
- `/changelog/` — version history details (per-entry tree; sole SSOT (committed state) — read `/changelog/_toc.md` for an index, `/changelog/_rules.md` for the contract)
- `pack-ops/PACK-CHAT.md` — PM chat operating rules
- `pack-ops/PACK-AGENTS.md` — agent routing table for pack development work
- `/backlog/`, `/changelog/` — per-entry source-of-truth trees + readable form; the SOLE SSOT (committed state; read `/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream contract). There is no monolithic mirror.

**Migrator framework.** When authoring a new
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
| `pack-chat-only` | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and directories" Files list — notably PERMITS `project-template/` trinity (CLAUDE.md / AGENTS.md / GEMINI.md at `project-template/` ARE pack-chat-only per PACK-AGENTS.md) |
| (no keyword) | Mixed-scope implicit | Check 36 skipped (no claim to verify) |

The vocabulary is intentionally small. Use no keyword for mixed-surface
commits — keyword opt-in means actors who don't want the gate don't carry
it, but actors who claim a scope are held to it.

**Versioning:**
- **Number:** `vMAJOR.MINOR[.PATCH]` — unpadded integers. MAJOR and MINOR
  are always present; PATCH is omitted when zero (`v11.0`, never `v11.0.0`).
- **Qualifier (release state):** one of `alpha`, `beta`, `RC1`…`RCn`, `GA`.
  Only `RC` is numbered (unpadded, from 1). Casing: `alpha`/`beta`
  lowercase; `RC`/`GA` uppercase — identical casing in display and tag (no
  lowercased tag variant). A qualifier applies only to a `MAJOR.MINOR`; a
  PATCH is never qualified.
- **Display ↔ tag:** display shows the qualifier parenthetically —
  `vMAJOR.MINOR (X)`. The git tag rewrites ` (X)` to `-X`, case preserved
  (`v11.0-alpha`, `v11.0-RC1`, `v11.0-GA`) — the `-X` form exists only
  because git refs cannot contain spaces or parentheses.
- **GA is transient:** `(GA)` shows only briefly pre-launch; at launch the
  qualifier is dropped → the released steady state is the bare number
  (`v11.0`).
- **User decides every tag and every state transition** — no heuristic, no
  automation. Tooling only reads / displays / validates the version string
  that exists.
- **Forward-only:** v1–v10 and existing v11 references are locked (not
  renamed); the old two-level `vN.M` form stays valid. Major versions for
  large additions or breaking changes; minor versions for incremental
  changes. Bare major tag always floats to the latest minor (e.g. v9 →
  v9.0, then → v9.1).
- Tag move sequence: delete local + remote, recreate, push

**BD-NNN numbering:**
- Read the `/backlog/` tree (e.g. `/backlog/_toc.md`), find the highest existing BD-NNN, increment by 1
- Never assign a BD number without reading the current backlog first
- Reservation lists from other chats, planning docs, or sidecar
  sessions are NOT authoritative — always read the live `/backlog/` tree before
  assigning. Reserved-but-unwritten numbers are guesses, not commitments.
- **No letter suffix.** A SEPARATE BD never carries a letter suffix — an
  integer ID only, never an integer followed by a trailing letter. Assign the
  next INTEGER. A sub-part of an existing BD lives as a SECTION inside that
  BD's body, never a suffixed entry.

**What agents may modify:**
- Any file in template directories when the task explicitly requires it
- Files in supporting-docs/ or maintenance-docs/ when the task explicitly requires it
- The `/changelog/` tree only at version boundaries with explicit instruction
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
- The `/backlog/` + `/changelog/` per-entry trees (PM chat only, after user approval)
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
  with explicit user approval. The denied set (RW and RO agents alike,
  including but not limited to): `commit`, `push`, `add` / stage
  (`add -p`, `stage`, `restore --staged`), `stash` (all subcommands),
  `rm`, `mv`, `reset` (all modes), `restore`, `checkout` (incl.
  `checkout --`, branch switch), `clean`, `merge`, `rebase`,
  `cherry-pick`, `revert`, `am`, `apply`, `branch -d`/`-D`/create,
  `switch`, `worktree` (add/remove/move/prune), `config` (write),
  `remote` (write), `update-ref`, `update-index`, `pull`, `fetch`, `gc`,
  `reflog expire`, `filter-branch`, `tag` (create/delete), `notes`
  (write), `replace`. (`git diff` is the agent's read-only patch-emit and
  is allowed; only `git apply` — the patch-APPLYING form — is denied, and
  only the orchestrator applies patches.) Principle (the catch-all):
  read-only git verbs are allowed only; any git verb that changes
  repository, index, working-tree, ref, or config state is forbidden —
  including but not limited to the enumerated denylist. `[roles: universal]
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
  per-BD reviews to end-of-batch retroactive recovery.
- **Pack Chat presents triage to user before fix-coder spawns.** After
  every reviewer pass, Pack Chat reads the report, triages each
  finding (FIX vs SKIP, with rationale for SKIPs — default FIX-ALL per
  `feedback-fix-all-review-findings`), and surfaces the triage to the
  user. User can override per finding before fix-coder spawns. User
  approves the resulting fix commit, not per-finding. The
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
- **Inject the graph path into every spawn prompt (Claude-only).**
  Under worktree isolation a spawned agent's `$(git rev-parse
  --show-toplevel)` resolves to the empty worktree root where gitignored
  `graphify-out/` is absent, so the orchestrator MUST derive the real graph
  path AT RUNTIME in its canonical checkout (the derivation formula
  `$(git rev-parse --show-toplevel)/graphify-out/graph.json`) and INJECT the
  resulting absolute literal into every spawn prompt — only when that
  canonical `graphify-out/graph.json` exists (else inject no path). The agent
  queries with `graphify <verb> … --graph <injected>`, NEVER its own
  toplevel. See § "Graph-first context" for the full contract + the
  Claude-only Trinity-exempt note.
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
- **Reconciliation-instance independence.** A reconciliation pass (the round
  resolving an adversarial review's findings before the work advances) uses a
  FRESH, independent instance — NEVER the original author (contaminated +
  design-biased toward its own design) NOR the adversarial reviewer (biased
  toward its own findings). Applies to EVERY role — architect, planner, coder,
  reviewer, auditor, repo-ops, tester, grpc-schema, any other — with ONE
  exception: `docs-researcher`, which MAY be re-engaged/reused (factual
  inventory; accumulated context helps; no design bias). Two carve-outs
  override the default: (1) **user override** — the user EXPLICITLY asks to
  re-engage an existing agent (in Claude Code via `SendMessage` to that
  instance — the discoverability mechanism then re-finds it; on Codex /
  Antigravity via the platform's re-engage path); (2) **architect challenge** —
  a good, evidence- and logic-based reason argued per case (not a blanket
  exemption). REINFORCES `fresh-agent-default` (the independence principle
  applied to reconciliation) and SUBORDINATES the Agent-team "SendMessage for
  follow-ups" convenience: a reconciliation pass is a fresh spawn unless a
  carve-out fires. `[roles: universal]
  [rationale: reconciliation-instance-independence]`
- **Researcher-first pipeline for substantive content.** When agent
  work depends on domain knowledge verified against authoritative
  external sources (CLI docs, tool semantics, framework behavior),
  the pipeline is `pack-docs-researcher` → `pack-architect` →
  `pack-planner` → `pack-coder`. Architect runs AFTER researcher,
  not before, not skipped. The same-architect-vs-fresh-architect
  decision for the second architect pass is per-case user
  discussion at the second-pass decision point.
- **Large-BD pipeline standard (size-tiered).** Pack-side BD development
  runs ONE official pipeline: optional researcher(s) (internal census and/or
  external docs verification, per-need) → architect → adversarial architect
  review → [reconciliation if NEEDS-REWORK] → user design review → planner →
  adversarial planner review → [reconciliation if NEEDS-REWORK] → user
  planner-to-coder gate → parallel worktree coder waves (off the rule-10 map).
  Size signals: launch-gate / cross-surface (≥2 families) / blast-radius (≥3
  encoding surfaces or a required census) / structural (a NEW convention,
  NEW/changed CI check, tree shape, migration, or a NEW rule). A BD is LARGE —
  the two adversarial reviews + reconciliation the MINIMUM — if launch-gate
  fires OR ≥2 signals fire; else the base flow (researcher → architect →
  planner → coder + the bounded cycle), adversarial passes OPTIONAL at user
  election (one non-launch signal alone — e.g. a single-clause amend to an
  existing rule — does NOT mandate them). When in doubt, LARGE. Each stage
  obeys its own `## Pack memory` rule; the design-time cross-BD shared-surface
  scan runs per `cross-bd-collision-scan`.
  `[roles: universal] [rationale: large-bd-pipeline-standard]`
- **Cross-BD design-time collision scan.** At the architect stage,
  after the researcher produces the blast-radius set, the architect MUST
  intersect THIS BD's set with every open BD's blast-radius / structured-surface
  set and record collision-or-none in an Empirical-Evidence Block. It keys on
  the structured BLAST-RADIUS paths, NOT the free-text `File/Symbol` line (a
  TBD/prose field has zero recall); covers the pack AND project backlogs; a
  non-empty intersection is a COORDINATE signal (sequence the two co-editing
  BDs), not a gate. `[roles: architect] [rationale: cross-bd-collision-scan]`
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
  INCOMPLETE. A guard that ENUMERATES repo files draws its
  candidate set from git-TRACKED
  files (`git ls-files`), NEVER a raw filesystem walk (`rglob` /
  `os.walk` / `glob` / `find`); if git is unavailable / not a work
  tree, SKIP the check (lenient). Also verify the guard catches the
  ABSENCE-of-backing instance (a declared mapping with NO backing), not
  only the target-exists instance. `[roles: architect]
  [rationale: ci-guard-measure-then-bound]`

- **Uniquely + descriptively name every spawn.** Every spawned agent carries a
  unique, descriptive `name` of the shape `<role>-<bd>-<facet>[-<seq>]` (lowercase
  kebab, `^[a-z0-9][a-z0-9-]{2,47}$`): `<role>` the agent role token
  (`coder`/`fixcoder`/`reviewer`/`architect`/`planner`/`docsresearcher` — the
  `subagent_type` minus the `pack-` prefix); `<bd>` the work anchor (`bdNNN` or
  `batchNN`); `<facet>` a short scope tag (`cdocs`/`worktree`/`external`); append
  `-2`/`-3`… to keep a repeated `<role>-<bd>-<facet>` triple unique within a live
  cycle (uniqueness is a DISCIPLINE — no platform guarantees it). In Claude Code the
  `name` is the Agent-tool `name` parameter (addressable via `SendMessage({to:
  name})`); on Codex / Antigravity use the platform's agent-name field. A
  unique name is the key the discovery mechanism records and re-finds by. `[roles:
  universal] [rationale: spawn-unique-naming]`

### Sub-agent behavior (Claude-only)

- **Sub-agent isolation is keyed by agent class (RW → isolated worktree;
  RO → the work's tree).**
  - **RW class.** Read-WRITE sub-agents (coders, fix-coders — anything that
    mutates) run in an ISOLATED worktree. The FIRST coder of a commit CREATES
    it (per-spawn Agent-tool `isolation:"worktree"` — the TRIGGER, the only
    valid value); every subsequent RW agent in that cycle — fix-coders
    included — REUSES that worktree, NEVER a new one.
  - **RO class.** Read-ONLY sub-agents (reviewers, architects, planners,
    auditors, docs-researchers) run in the tree the work lives in: the main
    checkout when committed/on HEAD; the commit's live worktree when still
    uncommitted there (cd in + verify pwd/HEAD). RO is NOT "always in-place" —
    it goes where the work is.
  - **Base.** The developer should set `worktree.baseRef:"head"` so the
    worktree bases at local HEAD (unset/`fresh` bases at origin/main — a
    documented wrong-base degradation); see OPTIONAL-FEATURES.
  - **No up-front patch.** RW agents produce NO patch on return; the ENTIRE
    review/fix cycle runs INSIDE that one worktree, nothing reaching the
    canonical tree mid-cycle. The patch is produced ONLY after a RO reviewer
    confirms the work CLEAN — Pack Chat SendMessage-s the most-recent RW agent
    (`git diff > <handoff>/changes.patch`), then applies + commits (user
    approval); agents never commit.
  - **Runtime regime.** The agent VERIFIES its actual regime at runtime
    (pwd/HEAD ground-truth), never trusting settings.
  - **Lifecycle (teardown gate).** Fresh worktree per commit's first coder;
    remove ONLY after the commit is CONFIRMED landed (exit 0) — NOT
    right-after-use (it may be needed mid-cycle); a FAILED/aborted commit
    KEEPS the worktree as recovery fallback; NEVER tear down on a failed
    commit, NEVER rely on auto-removal.
  - **Live-worktree ASK gate (rule 9).** A commit's own reviewer/fix-coder is
    RULE-FIXED to that worktree (no ask). Any OTHER agent spawned while a live
    worktree with uncommitted work exists ⇒ Pack Chat ASKS the user BOTH
    placement (which tree) AND disposition (reuse vs abandon); it NEVER
    self-decides either.
  - **Parallelization map (rule 10).** For any multi-commit effort the
    architect + planner produce a parallel-vs-dependent map in its OWN
    section; Pack Chat schedules parallel worktree waves vs serial commits
    (same-file commits serialize).
  - `worktree.bgIsolation` governs background SESSIONS only (not sub-agents).
    Trinity-exempt (Claude-only).
- **Default sub-agent spawns to background.** Every Agent-tool
  invocation from Pack Chat uses `run_in_background: true` so the chat
  stays interactive while the sub runs. User has auto-mode on; the
  background sub will not block the chat. Trinity exemption: this rule
  references the Claude Code Agent tool's `run_in_background` parameter;
  Codex parallel-spawn behavior is implicit (parallel-by-default, capped
  by `agents.max_threads`); Antigravity parallel-spawn is implicit via its
  dynamic-subagent mechanism (the `define_subagent` / plugin-roster
  subagent invocation; preview). No cross-CLI parity
  edit needed — each platform's parallel-or-async behavior is
  platform-native.
- **Agent-team stage lifecycle + per-commit fresh-coder.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled, sub-agents spawned
  for a stage (architect → planner → coder → reviewer) stay alive
  within the stage; Pack Chat uses SendMessage for follow-ups against
  the same instance — including the sanctioned rule-4 post-review-clean
  patch step (SendMessage-ing the most-recent read-write agent to
  produce its `git diff` patch only after the review is clean). After
  the stage's commit lands, close ALL stage
  sub-agents and respawn fresh for the next stage. Additionally: each
  pack-coder commit gets a FRESH coder instance — never reuse a coder
  across commits, even within a stage. Per-BD review/fix cycle = fresh
  coder for the implementation, fresh coder for the fix. Trinity
  exemption: Agent Teams + SendMessage are Claude-Code-specific
  (Codex MAv2 `send_message` (flag-gated `multi_agent_v2`; issue #12462
  CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing +
  idle auto-rewake) now ship peer-messaging ANALOGS — but they are
  flag-gated / not-yet-GA-documented (Codex) and partly-unverified
  (Antigravity), so this MECHANISM stays Claude-only here.)
- **Record every spawn in the durable registry; re-find by name→agentId
  (Claude-only mechanism).** The orchestrator records each Agent-tool spawn —
  its unique `name` (see `### Agent invocation rules`
  `[rationale: spawn-unique-naming]`), `agentId` (from the spawn tool_result),
  `purpose`, `status` — into the gitignored per-clone ledger
  `graphify-out/.pack-spawn-registry.jsonl` (NEVER committed —
  `agents-never-commit`; modeled on `graphify-out/.pack-refresh-status`) and
  CONSULTS it to re-find a still-alive spawn with NO transcript archaeology
  (re-read from disk, so it survives a parent context compaction). Lookup
  precedence: **by NAME → by agentId** (both work as `SendMessage.to`,
  measured; there is NO message-id addressing primitive — do not invent one;
  terminal fallback is a fresh re-spawn). Consult ONLY after the
  `fresh-agent-default` gate authorizes a re-engage — this fixes HOW-to-find,
  not WHEN-to-reengage. The registry is a same-clone re-find aid, NOT a
  state-transfer mechanism: the committed snapshot (`session-state-snapshot`) is
  the SOLE in-flight-state authority. The MECHANISM is Claude-only
  here; Codex MAv2
  (`list_agents`/`resume_agent`) and Antigravity `agy` analogs exist but need
  their own verification + mapping. `[roles: universal]
  [rationale: spawn-registry-find]`
- **Trinity exemption.** This sub-section is Claude-specific (not
  mirrored in `AGENTS.md` / `GEMINI.md`) because its rules are built
  against Claude Code's Agent-tool mechanism — the Agent tool's spawn
  schema, the `run_in_background` parameter (Codex/Antigravity async
  spawning is implicit/platform-native, not a named parameter), and the
  Agent Teams / SendMessage peer-messaging primitives. Codex MAv2
  `send_message` (flag-gated `multi_agent_v2`; issue #12462
  CLOSED-COMPLETED) and Antigravity `agy` (inter-agent ID-addressing +
  idle auto-rewake) now ship peer-messaging ANALOGS, but they are
  flag-gated / not-yet-GA-documented (Codex) and partly-unverified
  (Antigravity) — so this mechanism stays Claude-only here.

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
  - pack-chat-only files (the `/backlog/` + `/changelog/` trees / README version table /
    PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root /
    `project-template/` trinity) — see `PACK-AGENTS.md` § "Agent
    permission rules" for the pack-chat-only list. pack-chat-only IS Pack-Chat-direct
    by construction.
  - Pack Chat may NOT edit project-template / supporting-docs /
    maintenance-docs / scripts / fixtures / agent definitions —
    those go to pack-coder.
- **Pack Chat does MINOR edits only; coder does every MAJOR edit and
  everything outside the small set.**
  - **The small pack-chat-only set:** the `/backlog/` + `/changelog/` trees,
    the `README.md` version table, `PACK-CHAT.md`, `PACK-AGENTS.md`, the
    trinity `CLAUDE/AGENTS/GEMINI.md` (pack root + `project-template/`),
    `PACK-MEMORY-RATIONALE.md`, and the per-entry tree directories
    (`/backlog/`, `/changelog/`, `project-template/docs/project/
    {backlog,implementation-plan,changelog}/`).
  - **Pack Chat may apply directly:** (a) bookkeeping tokens (a
    `Status:`/`Resolved:` state flip, a version bump, a dated note, a README
    version-table row, a CHANGELOG release-block append); (b) AUTHORING A NEW
    ENTRY — opening a substantive BD entry or a NEW version-boundary CHANGELOG
    entry — because a new entry is already user-reviewed governance (the user
    approves BD-opens and version-boundary CHANGELOG content).
  - **Every MAJOR edit goes to a `pack-coder`** scoped in by Pack Chat's
    prompt, under the bounded review/fix cycle. An edit is MAJOR if it
    SUBSTANTIVELY edits ALREADY-LANDED content (re-scoping an existing entry; a
    multi-field rewrite of a landed entry; a bulk hand-rewrite of a monolith),
    OR alters a rule/contract, OR touches any file OUTSIDE the small set.
    Deleting-and-reauthoring an existing entry-ID is a substantive edit of
    landed content (= MAJOR), NOT a new authoring — the new-entry carve-out
    covers genuinely new IDs only. When in doubt between a new-entry author and
    an existing-content edit, it is MAJOR (route to coder).
  - Pack Chat scoping a pack-chat-only file INTO a coder prompt is the
    supported path for major pack-chat-only work — NOT a boundary violation.
  - **Pack Chat retains only:** commits (`agents-never-commit`), irreducible
    user-approved destructive ops (deletions), and its own out-of-repo memory
    files.
  - A Pack-Chat-direct edit is still an IMPLEMENTATION: Pack Chat's
    `validate-pack`/parity/grep sanity pass is the bounded check on it; a
    NEW-ENTRY author rides on the user's own governance review of the
    open/changelog content (the user approves it), not a coder reviewer. The
    moment an edit instead touches ALREADY-LANDED content substantively — or
    any out-of-small-set file — it is MAJOR and the independent reviewer
    applies via the coder cycle.
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
  form** for pack entries. **There is no monolithic mirror**; do not
  recreate `pack-ops/BACKLOG.md` / `pack-ops/CHANGELOG.md`. The project streams (`docs/project/backlog/` /
  `implementation-plan/` / `changelog/`) are per-entry source of truth in
  flat-file mode; their monolithic `BACKLOG.md` /
  `IMPLEMENTATION-PLAN.md` / `CHANGELOG.md` files remain regenerated
  mirrors (read-stable but never source of truth) until BD-206 retires
  the project-side mirror. **Flat-file per-entry is the SOLE supported
  mode on both surfaces.** Write
  procedure per `<stream>/_rules.md`.
  STATUS.md and any other convenience view carry an explicit
  "never source of truth" disclaimer; if a convenience view drifts, the
  per-entry tree wins. Read more at
  `<stream>/_rules.md`. `[roles: universal]`
- **Live session state lives in the committed snapshot, never CLI memory.**
  `pack-ops/session-state.json` is the committed, CLI-agnostic
  current-frontier snapshot — the SSOT for resumable in-flight state
  (active BDs + sub-step, in-flight agents to re-spawn, queue order,
  parallelization mode, pending decisions, in-commit cycle position, and
  the boundary commit). Pack Chat REPLACES its fields on every state
  transition; it is never appended-to with a dated note or a history line.
  CLI memory is FORBIDDEN for state. History goes to
  BD / changelog / commit / handoff, never the snapshot. `/pack-startup`
  reads it to resume. `[roles: universal] [rationale: session-state-snapshot]`
- **The `/backlog/` tree has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the `Resolved:`
  line. Do not propose moving entries to a separate section. Flip in the
  per-entry file (`/backlog/BD-NNN.md`) and regenerate `_toc.md` (flat-file
  is the sole supported mode).
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
- **Records-style checks verify load-bearing backing.** Any check that
  RECORDS a mapping (install row, wiring claim, surface↔surface link)
  MUST verify the LOAD-BEARING reality (the target ships / the wire is
  reachable / the matcher BITES), not merely a necessary-but-insufficient
  property (the target exists). `[roles: architect coder]
  [rationale: declare-verify-backing]`
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
- **Manifest is push-time, tool-enforced — not a per-commit chore.**
  `test-fixtures/manifest.txt` is regenerated only at push, only when a
  fixture input changed, by `scripts/manifest-sync.sh` (run by the
  orchestrator before `git push`). Correctness is enforced by CI
  `build.sh --verify` + validate-pack Check 62 — do NOT regenerate the
  manifest per-commit. `[roles: universal]
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
- **Graph-first context when the knowledge graph exists.**
  - **G1 existence guard.** When a graph exists, prefer it for orientation /
    relationship / blast-radius / "what relates to X" / "where does Y live"
    questions (a `graphify query` is read-only, deterministic, ~0 tokens)
    BEFORE broad tree reads; else use grep/Read (a fresh clone has no graph,
    so the rule degrades with zero friction).
  - **G2 fallback.** If a query errors or returns nothing useful, fall back
    to file reads — never block on the graph.
  - **Two phases — the second never vetoes the first.**
    - **(1) DISCOVERY / RECALL** ("ALL surfaces related to X / where Y lives /
      blast radius of Z / what depends on W") is **graph-FIRST and mandatory
      when the graph exists**: run `graphify query`/`path`/`affected` to
      establish the candidate set BEFORE broad reads. grep/Read is NOT a
      substitute here — an a-priori grep bounds recall to what you already
      thought to search for, the exact recall the graph exists to widen.
    - **(2) VERIFICATION / PRECISION** (exact bytes, line counts, or SSOT
      VALUE at an ALREADY-IDENTIFIED surface) is grep/Read's job — to confirm
      what discovery surfaced.
  - **Fall through to grep/Read (skipping the graph) ONLY for these** — each
    a P2 or out-of-graph need, never a license to skip P1: **(i)** a
    verification read of a named surface (exact bytes/counts, AFTER discovery
    named it); **(ii)** an authoritative SSOT field VALUE (a BD `Status`, the
    README version table, a `_rules.md` contract); **(iii)** freshly-changed /
    uncommitted files (`git diff`/Read — not yet in the graph); **(iv)**
    whole-file exact content of a named file; **(v)** content the graph does
    NOT index (archive-dir / excluded-category).
  - **Completeness census.** A census that enumerates every literal
    occurrence (e.g. a rename gate grepping every hit to grep-zero) runs the
    grep as its VERIFICATION gate but does NOT replace discovery: when the
    graph exists, run it FIRST to find candidate surfaces, THEN grep each to
    grep-zero — "exhaustive enumeration, so grep the whole tree" is prohibited
    (the graph exists to widen enumeration beyond your a-priori pattern).
  - **Path-injection under worktree isolation.** The agent NEVER recomputes
    the graph path from its own toplevel (under worktree isolation it resolves
    to the empty worktree root where gitignored `graphify-out/` is not
    materialized). The ORCHESTRATOR evaluates the formula
    `$(git rev-parse --show-toplevel)/graphify-out/graph.json` AT RUNTIME in
    its canonical checkout and INJECTS the absolute literal into every spawn
    prompt; the agent uses THAT injected `--graph <path>` verbatim. The
    orchestrator injects ONLY when its canonical `graphify-out/graph.json`
    exists; if absent (fresh clone / graphify not installed / feature off) it
    injects NO path (or a "no graph available" token) and the agent proceeds
    with grep/Read. The agent runs the G1 check against the INJECTED path
    (never its own toplevel); G2 is unchanged.
  - **Worktree path-injection is Claude-only** (only Claude runs worktrees);
    the `AGENTS.md`/`GEMINI.md` graph-first path-resolution stays as-is
    (correct for their in-place execution; their worktree story is a future
    pack version). Do NOT "restore parity" by porting this injection contract.
  - **Invocation params.** `--graph` is ALWAYS absolute (a sub-agent may start
    in a different cwd); `--budget` tiers are 2000 human/interactive, 1500
    spawned agent, 1000 Pack-Chat prompt-construction; the backend is ALWAYS
    `--backend claude-cli` (the no-key subscription path — NEVER `claude`,
    which demands `ANTHROPIC_API_KEY`).
  - **Never preload the graphify skill** via `skills:` frontmatter (~32KB,
    build-oriented) — querying needs `Bash` only, which all 5 pack agents
    carry. Agents QUERY the graph; they never BUILD/refresh it (building costs
    subscription; it is a main-session/orchestrator job).
  - In Claude Code the session/skill auto-routes a `graphify` query and Claude
    subagents inherit this pack-root `CLAUDE.md`; pack agents are invoked via
    `claude --agent pack-<name>` or the Agent tool (`subagent_type=pack-<name>`).
  - **Boundary note.** The graph MAY index the whole repo incl.
    `project-template/`; consuming it for a deliverable question is fine — the
    rule + setup stay pack-side. `[roles: universal] [rationale: graph-first-context]`
- **Operating docs carry NO history, NO deferred-feature mentions; stay
  terse + structured.** An operating doc (a doc an agent/chat EXECUTES as
  live instruction — rules, agent/skill defs, prompts, write-contracts)
  carries (a) ZERO historical/audit-trail text (dated notes,
  `User-locked YYYY-MM-DD`, "BD-NNN did X" past-action narration,
  "per BD-NNN" / "carried from" provenance, incident/SHA refs); (b) ZERO
  description of a DEFERRED / unimplemented / off-by-default feature — even
  to say it is deferred (state only what currently exists and operates; the
  mention is re-added when the feature ships); and (c) is kept terse +
  structured (no mega-bullet run-ons, prose-that-should-be-a-table, or
  padding). LIVE forward-pointers to CURRENT in-flight work KEEP
  (`until BD-NNN`, an `ARCHITECTURE-*.md` path). History + roadmap belong in
  changelog/backlog entries, maintenance-docs, and IMPL reports (reference
  docs) — never copied into an operating doc.
  `[roles: universal] [rationale: operating-docs-no-history-no-bloat]`

### Project goals (v11)

- Flat-file per-entry is the sole supported mode.
- OT-style v10→v11 migration is automated; OT itself is read-only for
  testing (use `/tmp` clones or scratch fixtures, never write to real OT).
