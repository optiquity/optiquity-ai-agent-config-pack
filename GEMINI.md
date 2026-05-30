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

Key docs: `README.md` (version table), `pack-ops/BACKLOG.md` (BD-NNN items;
regenerated mirror — per-entry source at `/backlog/`), `pack-ops/CHANGELOG.md`
(version history; regenerated mirror — per-entry source at `/changelog/`),
`pack-ops/PACK-CHAT.md` (PM chat rules), `pack-ops/PACK-AGENTS.md` (agent routing for pack
work). Per-entry trees: read `/backlog/_rules.md` and
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
| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` PM-only Files list — PERMITS `project-template/` trinity |
| (no keyword) | Mixed-scope implicit | Check 36 skipped |

Use no keyword for mixed-surface commits — keyword opt-in.

**Versioning:** Minor tags (vN.M, vN.M+1) for incremental changes. Major tags for
breaking changes or large additions. Bare major tag always floats to latest minor.
Tag move sequence: delete local + remote, recreate, push.

**BD numbering:** Always read `pack-ops/BACKLOG.md` to find the highest existing BD
number, then increment by 1. Never assign a BD number from memory or
from another chat's reservation list — reservations are not authoritative.

**What agents may modify:**
- Template files, supporting-docs/, maintenance-docs/: when task explicitly requires
- `pack-ops/CHANGELOG.md`: only at version boundaries with explicit instruction
- Scripts in template directories

**What agents must never modify without explicit instruction:**
- `pack-ops/BACKLOG.md`: PM chat only, after user approval
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
  is user-initiated. Fixes land in the current session. New-BD-opens
  follow the OQ-1 rule per EXECUTION-PLAN §B step 5 + W8 "Deferral IS
  scope creep" (size/blocked/fit + user-discussion-and-approval).
- **Implicit BD status flip on batch completion.** When a batch's review +
  fixes are clean and tests are green, flip its BDs to `Resolved` as the
  final step of the batch — no separate user approval needed.
- **Per-action approval extends to sub-agents.** The "no state-changing
  operations without explicit per-action approval" rule applies to
  Gemini CLI Pack Chat AND every sub-agent it spawns. State-changing
  git verbs are forbidden to all agents per `PACK-AGENTS.md` § "Agent
  permission rules"; destructive file operations (`rm -rf`, `git rm`,
  overwriting trusted files) require Pack Chat to ask the user even
  when the overall task is approved. Sub-agents inherit this rule by
  construction (they write only their report + scoped working-tree
  files; they cannot commit).
- **Deferred work needs a tracked anchor.** When work is genuinely
  deferred (user-authorized; survives the `feedback-deferral-is-scope-
  creep` size/blocked/fit test), it MUST land on a live forward-pointing
  surface AND be scheduled to a specific anchor: an open BD entry, a
  live `// TODO(scope): TD-TBD` comment in code per `project-template/
  CLAUDE.md` § "Deferral comments and BACKLOG hygiene", or a new BD
  inserted at the appropriate plan position. Archived reports are NOT
  acceptable anchors — work that lives only in an archived doc is lost.
- **No deferral to v11.1+ without explicit user direction.** While
  v11.0 is unlaunched, ALL work surfaced during v11.0 development MUST
  land in v11.0 unless the user explicitly authorizes deferral. Pack
  Chat must NEVER propose "defer to v11.1" as a default option in
  user-facing framings. Architect / reviewer / coder defer-
  recommendations are SCOPING signals (often driven by prompt
  boundaries Pack Chat imposed), not AUTHORITY signals — re-scope to
  land in v11.0 and surface the blast-radius to the user. Only the user
  authorizes v11.1+ deferral; this default inverts only on explicit
  user direction ("this is v11.1 work" / "defer this" / "don't block
  v11.0 on this").
- **Deferral IS scope creep.** Deferring unblocked work to a later BD
  or batch is tech debt and scope creep. Punted items lose context,
  multiply, require archaeology in future sessions. Defending deferral
  rigorously requires (a) SIZE (architect-pass material; real file/
  contract surface argument, not "felt big"), (b) BLOCKED (real
  dependency on not-yet-landed artifact, not "feels related"), or
  (c) LOGICAL FIT (cleanly belongs with another sibling BD/commit;
  concrete same-file/same-contract fit, not "thematic"). When a new
  BD is created that is LARGE and UNBLOCKED, insert it IMMEDIATELY
  AFTER the current BD or batch — do not park at end of v11.0, do not
  park in a "next batch" with no anchor. When BLOCKED, insert at the
  exact unblock point. Per OQ-1 (rewritten EXECUTION-PLAN §B), any
  new-BD-open additionally requires user-discussion-and-approval.
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
  defaults.** Project and pack are intentionally designed differently.
  When making ANY change to a project-side file (`project-template/`
  trees, project-shipped content), an actor (reviewer, implementer,
  Pack Chat triage) MUST first investigate whether a project-side SSOT
  exists for the concept being changed. Pack-style mechanisms
  (`pack-ops/PACK-AGENTS.md` roster, Pack Chat orchestrator role,
  pack-* agent names, `maintenance-docs/` design records, anything
  under `pack-ops/`) are PACK-ONLY by construction — they do not exist
  at client install, they do not govern project behavior, and importing
  them into project-side files is a regression that breaks at client
  install or pollutes project-design intent. The default instinct
  "reach for the pack mechanism I know" is bias, not a starting point.
  Investigate the project-side SSOT FIRST. Worked examples of the
  failure mode this rule prevents: BD-175 audit V1 (project trinity
  acquired `PACK-AGENTS.md` reference via a review-fix commit when the
  project-side SSOT was `docs/pack/PM-CHAT.md`), V3 (project-side
  `PLATFORM-SKILLS.md` acquired `PACK-AGENTS.md` reference instead of
  pointing at `PM-CHAT.md`), V4 (project-side methodology doc became
  pack-internal by drift). See the `boundary-investigation` skill
  (loaded by all pack agents) for the SSOT-investigation methodology.

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
- **Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern.** Every pack-coder
  agent prompt MUST include both halves of this pattern:

  - **PREFLIGHT (platform-neutral, REQUIRED for all CLIs).** After
    completing all in-scope file edits + verification, BEFORE writing
    the IMPL-REPORT, the coder emits ONE plain-text line:
    `PREFLIGHT: N/N in-scope file edits complete; verification PASS;
    HEAD <SHA>; about to Write IMPL-REPORT to <path>`. Then it writes
    the IMPL-REPORT. Pack Chat treats this line as the trust signal
    that the report-write is starting from a complete-and-green state.
    If the coder cannot complete the preflight (some edit failed,
    some test failed), it reports what went wrong instead and does
    NOT write a partial IMPL-REPORT.

    Verification includes BOTH the in-scope test suite for the BD AND
    Check 43 (V11 leak-sweep prevention; pack/project boundary scanner).
    When a pack-coder commit touches any file under project-template/,
    pack-ops/, supporting-docs/, or scripts/, the coder MUST run
    `python3 scripts/validate-pack.py` against the working tree before
    writing the PREFLIGHT line; Check 43 (and the rest of the validate-
    pack suite) MUST PASS. If Check 43 FAILs, the coder reports the
    failure (with file:line + matched basename + suggested remediation)
    INSTEAD OF writing the IMPL-REPORT — Pack Chat reviews and decides
    whether to fix in this commit or escalate.

    **Per-check test runs.** When the commit modifies any of:
    `scripts/validate-pack.py` (any function/check),
    `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES_START/_END`
    inventory, `scripts/lib/` files referenced by validate-pack
    checks, or any file in the `_CHECK_*_ALLOWLIST` referenced
    surfaces — the coder MUST run all relevant per-check test files
    at `scripts/tests/test-validate-pack-check-*.sh` before writing
    the PREFLIGHT line. ALL tests MUST PASS. If any test FAILs, the
    coder reports the failure (file:line + test name + diagnostic)
    and does NOT write the IMPL-REPORT. "Relevant" = (a) the test
    file matching the check ID being modified, AND (b) any test
    file that exercises the same `_iter_*` helper or shared logic
    surface; when in doubt, run ALL per-check test files (cost:
    ~5-15s total). Worked example: BD-193 + BD-194 incident —
    BD-193 commit `85196d4` removed `pack-ops/HELP-FRAGMENT-TRACKER.md`
    from the inventory but didn't update `test-validate-pack-check-43.sh`
    G2.T3 or `test-validate-pack-checks-36-37-38.sh` G7.T3
    expected_extras; both BD-193 and BD-194 PREFLIGHTs passed because
    `validate-pack.py` itself ran clean, but the per-check tests
    would have FAILed on push. Caught at BD-194 reviewer pass;
    resolved in `6c76582`.

  - **STOP-MEANS-STOP preamble (REQUIRED for all CLIs as content;
    Gemini enforcement is UI-based).** The coder prompt opens with
    an explicit instruction: "If you receive a parent-session message
    containing the words stop / halt / revert / do not continue, you
    MUST immediately stop ALL work, including any in-progress Write.
    Partial files are acceptable; do not append to make consistent.
    Stop authority is absolute and unconditional." Gemini has no
    SendMessage equivalent (hub-and-spoke per docs — subagents
    report findings back to the main agent only) and no documented
    transcript-classifier handoff-check equivalent of Claude Code's
    SECURITY WARNING; parent-side enforcement relies on
    natural-language directive or `Ctrl+C` (which terminates the
    whole Gemini session per issue #3385, not just the current
    operation). Reliability caveats per research §3.6 (subagent
    hangs on interactive terminal prompts per issue #21052;
    generalist agent hangs per #21409; agent keeps stopping mid
    task per #14043; interruption is not first-class-supported per
    discussion #4323). Authoritative full text and Claude-side /
    Codex-side enforcement notes: pack-root `CLAUDE.md`
    `## Pack memory` `### Agent invocation rules` "Pack-coder
    PREFLIGHT + STOP-MEANS-STOP pattern" bullet.

  Worked-example anchor: BD-169 19g-pack incident, 2026-05-16
  (Claude-side; the platform-neutral PREFLIGHT half of the lesson
  applies equally to Gemini pack-coder prompts).

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
  `COMPLIANT` / `N/A: <reason>` / `VIOLATED: <reason>`.

  **Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.
  Without this block, agents cite rules they've followed but skip
  rules they didn't verify. Verification evidence is the only
  mechanism that distinguishes "rule cited" from "rule applied."
  Failure mode in BD-195 AC1 §6.2: architect cited prison rule,
  manifest-regen rule, trinity rule — sound. But no verification
  evidence for the empirical claim "the seed-corrected tree has NO
  `v11.1`-string occurrences outside the allowlist." The claim was
  rule-shaped (a state-claim) but had no verification block. The
  coder later proved it false (1213 hits in 114 files). Required
  Rules-Applied Verification Block with grep output would have
  failed the claim at design time, not coder time.

  **How to apply:** Format: per-rule table `Rule | Verification
  evidence | Conclusion`. Pack Chat verifies the block exists, every
  row has non-empty evidence, every VIOLATED row gets surfaced to
  the user BEFORE any downstream work (planner spawn / coder spawn /
  commit). Empty entries = treated as VIOLATED. N/A rows require
  explicit justification.

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
  / PARTIAL with reason).

  **Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.
  BD-195 AC1 §6.2 claimed "after F-AC1-04 strips the v11.1 strings
  from validate-pack.py + test-issue-forms.sh, and F-AC1-02 retires
  templates-archive/v11.1/, the working tree has NO `v11.1`-string
  occurrences outside the allowlist." State-claim. No grep run. No
  count captured. The claim was empirically wrong by three orders of
  magnitude (1213 hits in 114 files). The architect could have
  grepped at design time — they had the regex (they wrote it as part
  of Check 44's pattern). Nothing required them to verify.

  **How to apply:** Every architect or planner prompt requires (a)
  enumeration of the state-claims the design makes (in advance) and
  (b) instruction that the design output includes an Empirical-
  Evidence Block per state-claim. Pack Chat scans every architect /
  planner output for state-claims; any without a corresponding
  Empirical-Evidence Block entry is surfaced as a design defect
  (route back to architect/planner; do not advance to planner /
  coder).

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
  default — which defeats the guard's purpose.

  **Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.
  BD-195 AC1 §6.2 designed Check 44 with an allowlist of 2 architect
  docs + 7 anchor phrases. The architect assumed (without
  measurement) that C1-C6 fix-recipes would leave only the
  allowlist-covered occurrences in the tree. The actual measurement
  at HEAD `b547524a` (after C1-C6 landed) revealed 1213 occurrences
  across 114 files. The allowlist was undersized; the fix-recipes
  were under-scoped to match the actual contamination. The Pack Chat
  triage temptation was to "widen the allowlist" to make the guard
  pass — which would have defeated Check 44's purpose (catching
  contamination LIKE the BD-193 propagation it was designed to
  prevent). The right fix was to redo the design with the actual
  measurement in hand.

  **How to apply:** Any architect spawn that includes a CI-guard /
  validator / allowlist deliverable: the prompt requires the
  architect to execute (a) measurement-first phase (grep/walk the
  tree, produce occurrence list), (b) categorization (per-occurrence
  KEEP/STRIP), (c) fix-recipe design for every STRIP, (d) allowlist
  sized to KEEP only, (e) projected post-fix verification. The
  design output includes the measurement evidence + per-occurrence
  categorization + the projected-clean verification. Pack Chat does
  NOT advance the design to planner if any of these steps are
  skipped.

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
  - PM-only files (BACKLOG.md / CHANGELOG.md / README version table /
    PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root /
    `project-template/` trinity) — see `PACK-AGENTS.md` § "Agent
    permission rules" for the PM-only list. PM-only IS Pack-Chat-direct
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
  wins. Read more at `<stream>/_rules.md`.
- **`pack-ops/BACKLOG.md` has no Resolved section.** Entries resolve in place by
  flipping `Status: Open` to `Status: Resolved` and filling the
  `Resolved:` line. Do not propose moving entries to a separate section.
- **Separate pack ops from pack product.** Pack ops files (CLAUDE.md,
  AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.)
  are NEVER mixed into pack product files (`project-template/`,
  `supporting-docs/`). Same applies in reverse.
- **Project-side concepts on pack-side surfaces — deliverable-only.**
  References to project-side concepts (TD entries, phases, phase
  parts, phase tasks) on pack-side surfaces MUST be limited to
  constructing project-side deliverables. They MUST NOT appear in
  pack operations or pack templates/configs for pack-self-management.

  **ALLOWED:** pack-side scripts that emit project-side templates
  (e.g., `scripts/init-project.sh` stages that copy
  `project-template/` content); pack-side validate-pack checks that
  verify project-side structure; pack-side architecture/planner docs
  that design project-side surfaces; pack memory rules that govern
  project-side semantics.

  **FORBIDDEN:** pack-root form admitting `td` / `phase-epic-skeleton`
  / `phase-task-skeleton` wi-type options (pack doesn't file TDs or
  phase-skeletons against itself); `pack-ops/` files referencing
  project-side TD entries operationally (pack-ops uses BDs in
  `BACKLOG.md` and batch labels in `EXECUTION-PLAN-V11.0.md`);
  pack-root configs (`.claude/`, `.codex/`, `.gemini/` at pack-root)
  using project-side concepts for pack-self-management.

  **The test:** "Is this pack-side surface being used to CONSTRUCT a
  project-side deliverable, or is it part of pack-self-management?"
  If the surface IS the deliverable's source-of-truth (templates,
  scripts that emit, validators that check), project-side references
  are allowed. If the surface is pack-self-management, project-side
  references are forbidden.

  **Why:** User-locked 2026-05-27 during BD-185 reconciliation. The
  rule was implicit in `feedback_pack_project_separation_of_concerns`
  + `feedback_bd_pack_only_operational_rule` but not explicit.
  BD-193 applied the asymmetric counterpart (removed BD from
  project-side forms) but did not symmetrically clean up TD/phase
  from pack-side self-management surfaces. Worked example: pack-root
  `.github/ISSUE_TEMPLATE/work-item.yml` admits `td`,
  `phase-epic-skeleton`, `phase-task-skeleton` — these are stale
  pre-BD-193 inheritance and should be removed.
- **Enumerate ENCODING surfaces in pack-side audits.** When auditing
  a pack-side surface for rule compliance (e.g., the deliverable-only
  rule above), enumerate ALL surfaces that ENCODE expected state of
  the audited surface:

  - The audited surface itself (form, config, library, doc).
  - Any validator that asserts content invariants on the surface
    (e.g., `scripts/validate-pack.py` per-surface tables).
  - Any TEST file that asserts content invariants on the surface
    (e.g., `scripts/tests/test-issue-forms.sh` for issue forms).
  - Any CI workflow definition that references the surface or its tests.
  - Any cross-reference docs (architect docs, planner docs, IMPL-REPORTs)
    describing the surface's expected state.

  Each ENCODING surface must update in lock-step with the audited
  surface. Asymmetric coverage (walking validators but not tests, or
  vice versa) misses lock-step dependencies and creates audit gaps.

  **Verdict sub-class.** LEAK (operational, test-encoded) — pack-self-
  management state encoded in a test file's assertions, where the
  assertion's truth value depends on whether the audited surface admits
  a forbidden concept. Treat the same as a LEAK in the audited surface
  itself.

  **Why:** User-locked 2026-05-27 post-BD-185-reconciliation pack-side
  re-audit (methodology gap MF1). The original BD-185 reconciliation
  pack-side audit walked the form file (F1) + the validator's
  per-surface dict (F2) but missed
  `scripts/tests/test-issue-forms.sh` Group 2 + Group 5 assertions
  (F3'). The test's hardcoded pack-root assertions encoded the
  pre-cleanup state and required lock-step update with F1 + F2.
  Caught post-fact by the PREFLIGHT per-check-test-runs gate
  (`ba9e09d`), NOT by the audit itself. The methodology gap was
  treating `scripts/tests/*` as "constructor context" wholesale when
  the correct granularity is per-assertion (constructor portions
  assert project-side emission; self-management portions assert
  pack-side state). The `review` skill at
  `.claude/skills/review/SKILL.md` + trinity mirrors carries the
  operational checklist.
- **Test infra is self-provisioned.** Tests that need GitHub repos
  provision them via `gh` CLI with per-step approval and clean up after.
  Never touch existing real repos as test targets — use scratch repos
  or `/tmp` clones.
- **Skill and agent maintenance is mechanical by default.**
  Maintenance is mechanical, complete, reviewed, and rule-strict.
  Structural change — including rule changes — requires
  architect-then-planner, never convenience. Mechanical changes
  preserve client `x-` skills/agents conforming to existing
  dimensions; breaking the `x-` contract escalates to structural
  and requires architect-pass migrator coverage. Workflow artifacts
  (architect/planner/coder/reviewer/auditor outputs:
  `ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`,
  `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`,
  `PACK-REVIEW-*.md`, `PACK-REVIEW-*-RETRO.md`,
  `AUDIT-*.md`, `RESEARCH-*.md`, `*-DISCOVERY.md`,
  `CLEANUP-INPUTS-*.md`) are exempted from the "no new top-level
  doc" structural signal during their batch's active development;
  they sweep to `maintenance-docs/archive/vN/` at version ship as
  the final pre-tag step (Pattern B). Threshold conditions and
  worked examples in `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
  §3.
- **Pack-repo code-comment deferrals.** Code comments in pack-repo
  source (`scripts/`, `proto/`, any non-template source) that defer
  work MUST use the typed format defined in `project-template/CLAUDE.md`
  § "Deferral comments and BACKLOG hygiene" — never plain English
  `// TODO`, `// fix later`, or `// FIXME` markers. Typed format:
  `// TODO(scope): TD-TBD — title`, `// KNOWN GAP(severity): TD-TBD —
  title`, `// VERIFY(source): TD-TBD — title` (substitute `#` for `//`
  in Python). Cross-reference: the project-template section is canonical
  for the typed format; the pack-repo follows the same convention so
  pack-coder behavior is consistent across pack-repo and client-repo
  contexts.
- **Filename uniqueness heuristic.** When introducing new files in the
  pack repo, prefer names that don't collide with any other file
  anywhere in the repo, so prose references are unambiguous even when
  the path is omitted. Quick check: `find . -name "<proposed-name>"
  -not -path "./.git/*"`. Structurally required collisions are exempt
  (trinity files, per-skill `SKILL.md`, ecosystem-fixed names like
  `.gitignore` / `pyproject.toml` / `Package.swift`); for these exempted collisions, prose references
  must include path context ("pack-root `CLAUDE.md`" vs "project-template
  `CLAUDE.md`"). Cross-reference forms that STRIP the unique filename
  also violate this rule's intent even when they avoid the literal
  `.md` extension — bare-version shorthand like `V3.3 §3.X` as a
  reference to `ARCHITECTURE-V3.3-DELTA.md` sections is a leak under
  the rule's spirit because the reader has no filename to follow, no
  path to resolve, and the version shorthand is ambiguous (a `V3.3`
  reference could mean any v3.3-versioned doc). Audit vocabulary
  scans that look only for `*.md` patterns will MISS these; reviewers
  should treat bare-version shorthand for pack-internal docs as the
  same leak class as explicit `*.md` cites. Worked examples: BD-135
  renamed the colliding `tracker.toml.example` pair; BD-173 Batch 19c.H.9
  NIT-1 fix expanded from L1207 doc-cite to 11 bare-V3.3 refs in
  `supporting-docs/METHODOLOGY.md` (audit-vocabulary-gap pattern).
- **Architect-doc-vs-reality reconciliation.** When a BD realizes a
  design anticipated in an architect doc, ship the reconciliation
  chain: (a) in-code docstring naming the realized consumer (file +
  symbol; never line numbers — line numbers drift), (b) architect-doc
  addendum cross-referencing the realized consumer, (c) IMPL-REPORT
  cross-reference linking both. Worked example: BD-119 §9.2 addendum
  in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  names BD-160 as the first realized consumer; the consumer carries
  the matching docstring; the BD-160 IMPL-REPORT links both. This
  pattern is load-bearing for any future shipped surface that pre-
  existed in an architect doc.
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`. Any commit whose diff includes
  a file under any of these four directories MUST also regenerate
  `test-fixtures/manifest.txt` and stage it alongside the scope edits
  in the SAME commit. The trigger is intentionally inclusive — false
  positives (e.g., a `scripts/test-*.sh` edit that doesn't actually
  affect fixtures, or a `supporting-docs/MIGRATION-v10-to-v11.md`
  edit which is a pre-install reference not copied to clients) cost
  ~30-90s of unnecessary rebuild but produce no incorrect manifest
  change; false negatives within v11-surface are impossible because
  every fixture-affecting file lives under one of these four
  directories. Fixture-affecting paths today: all of
  `project-template/**` and `scripts/**` (mass-copied by
  `scripts/init-project.sh` stages S1-S11);
  `pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh`
  stage S11 copies to client `docs/pack/`);
  `supporting-docs/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md`
  (`scripts/init-project.sh` stage S6 copies to client `docs/pack/`).
  Other files under `pack-ops/` and `supporting-docs/` are not
  fixture-affecting today, but the directory-wide trigger defends
  against future copy-site additions to `init-project.sh` or new
  fixture-build readers. v11-* fixture row SHAs drift naturally with
  any v11-surface change (per `test-fixtures/README.md` § Determinism
  and the `_update_manifest` comment at
  `test-fixtures/build.sh:903-912`); a stale manifest fails CI's
  `fixture manifest verify` step (BD-115, RELEASE-GATE item 5) even
  when every functional test passes. **Why:** two incidents drove
  this rule: (1) the 2026-05-17 incident where commit `667d2dd`
  shipped v11-surface `project-template/` trinity edits without
  regenerating the manifest, CI failed on the manifest-comparison
  step alone (all 40+ functional steps PASSED), and recovery commit
  `ef9e5c7` had to land as a separate `fix:` commit; the drift was
  the cumulative effect of three intentional v11-surface commits
  (`cf67a96` BD-169 pack-product wording, `62f9eec` BD-169 review/
  fix, `479fef5` Batch 19 broad review/fix) since the last manifest
  regen at `a57dd04` (BD-160); (2) the 2026-05-19 incident where
  BD-175 Phase 5 Commit 8 `4120d19` modified
  `supporting-docs/METHODOLOGY.md` (a client-installed file) without
  regenerating the manifest under the prior strict trigger (which
  excluded `supporting-docs/`), CI failed identically, and recovery
  commit `6c48f88` had to land as a separate `fix:` commit. BD-176
  expanded the trigger from 2 directories to 4 to close both classes
  of false negative (pack-ops/ defensively; supporting-docs/
  empirically). **How to apply:** before staging a commit whose diff
  includes any file under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
- **Cross-CLI reference normalization in `project-template/` trinity.**
  When editing references to per-CLI paths or commands in
  `project-template/{CLAUDE,AGENTS,GEMINI}.md`, substitute the
  audience-correct canonical value per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`
  §4.1 canonical reference table. Per Override 9, byte-identical
  cross-trinity adoption of CLI-specific paths is WRONG even when it
  visually closes drift — body-text drift and cross-CLI references are
  different classes (see `ARCHITECTURE-BD-182.md` §1 table). Worked
  example: BD-178 SHOULD-1 byte-identically aligned `GEMINI.md`'s
  `.claude/settings.json` reference (correct for CLAUDE form, wrong
  for Gemini-audience); BD-182 corrected to `.gemini/.env` per §4.1.

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
