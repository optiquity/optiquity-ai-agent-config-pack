# PACK-MEMORY-RATIONALE.md — rationale bodies for tagged Pack memory rules

**What this file is.** The read-on-demand rationale companion to the
`## Pack memory` rule corpus in the pack-root trinity (`CLAUDE.md` /
`AGENTS.md` / `GEMINI.md`). Each tagged rule in that corpus carries a thin
imperative line plus a `[rationale: <slug>]` pointer; the matching `## <slug>`
section below holds that rule's Why + How-to-apply-worked-example +
rejected-alternatives — moved out of the corpus so it stays
application-grade and concise.

**Pack-only.** This file lives under `pack-ops/`. It is NOT a trinity file and
NOT installed to client projects by `scripts/init-project.sh`. It governs
pack-self-management only.

**Read-on-demand.** Agents do NOT load this file into every prompt; Pack Chat
pastes only the imperative lines plus their slugs into spawn prompts, never the
rationale. An agent reads a `## <slug>` section only when it hits an ambiguous
Rules-Applied row and follows the rule's `[rationale: <slug>]` pointer.

**Never source-of-truth for the imperative.** The corpus imperative line is
authoritative for WHAT the rule requires. This file explains WHY and HOW; if
this file and the corpus imperative ever disagree, the corpus imperative wins.
The slug-set here is held in 1:1 bijection with the corpus `[rationale: slug]`
set (Check 45, wired in commit C3).

---

## agents-never-commit

Read-only git verbs (`status`, `diff` — incl. `diff > file`, the agent's
patch-emit — `log`, `rev-parse`, `show`, `ls-files`, `blame`) are allowed.
Only Pack Chat stages and commits, and only with explicit user approval.
The agent's on-return deliverable is its report file plus its edits (held
in the commit workspace). The `git diff` patch is NOT
emitted up front — it is the POST-review-clean artifact: only after a read-only
reviewer confirms the work clean does Pack Chat re-engage the most-recent
read-write agent (SendMessage) to produce the patch into the named handoff
dir (`cd <WS> && git diff > <handoff>/changes.patch`), then read the report,
apply that reviewed-clean patch, and commit.

**The denied set (RW and RO agents alike — "including but not limited
to").** No agent may run any state-changing git verb at any point:
`commit`, `push`, `add` / stage (`add -p`, `stage`, `restore --staged`),
`stash` (all subcommands), `rm`, `mv`, `reset` (all modes), `restore`,
`checkout` (incl. `checkout --` and branch switch), `clean`, `merge`,
`rebase`, `cherry-pick`, `revert`, `am`, `apply`, `branch -d`/`-D`/create,
`switch`, `worktree` (add/remove/move/prune), `config` (write), `remote`
(write), `update-ref`, `update-index`, `pull`, `fetch`, `gc`, `reflog
expire`, `filter-branch`, `tag` (create/delete), `notes` (write),
`replace`. Verb-precision matters for the merge-back model: `git apply`
(the patch-APPLYING form) is DENIED to agents — only the orchestrator
applies patches — while `git diff` (the patch-EMIT) stays allowed; a
backstop keying on the git verb must deny `apply` and never `diff` (the
`git diff > file` shell redirect is not a git verb, so it is not tripped).

**Principle (the catch-all).** Read-only git verbs are allowed only; any
git verb that changes repository, index, working-tree, ref, or config
state is forbidden — including but not limited to the enumerated denylist.
A verb not on the allowed read-only list is treated as forbidden when the
agent is unsure — closing the "the list never told me" gap for any unlisted
future verb.

---

## per-action-approval-sub-agents

The "no state-changing operations without explicit per-action approval" rule
applies to Pack Chat AND every sub-agent it spawns. State-changing git verbs
are forbidden to all agents per `PACK-AGENTS.md` § "Agent permission rules".
Destructive non-git shell ops (`rm`/`rm -rf`/`rmdir`/`unlink`/`find … -delete`/
`find … | xargs rm`/`mv <src>`/`shred`/`truncate`, or destructively
overwriting a file outside the owned dir) are the parallel ban for bare shell.
Each agent OWNS one unique work dir (its assigned handoff/scratch dir): it
writes all output there and may delete within it and within the OS temp roots
(`$TMPDIR`/mktemp), but deletes or overwrites NOTHING outside that boundary —
not another agent's dir, not a shared scratch root, not the repo/worktree, not
a broad glob. Cleanup of the owned dir is the orchestrator's/harness's job. On
Claude, the `deletion-boundary` `PreToolUse[Bash]` hook backstops this
best-effort for registered sub-agent spawns (Claude-only; see the
modes-enforcement family). See `feedback-no-destructive-without-approval` for
the memory-cache pointer.

---

## deferred-work-tracked-anchor

Archived reports are NOT acceptable anchors — work that lives only in an
archived doc is lost.

---

## no-deferral-without-user-direction

Pack Chat must NEVER propose "defer to v11.1" as a default option in
user-facing framings. Architect / reviewer / coder defer-recommendations are
SCOPING signals (often driven by prompt boundaries Pack Chat imposed), not
AUTHORITY signals — re-scope to land in v11.0 and surface the blast-radius.
Only the user authorizes v11.1+ deferral; the default inverts only on explicit
user direction ("this is v11.1 work" / "defer this" / "don't block v11.0").

---

## deferral-is-scope-creep

Punted items lose context, multiply, require archaeology in future sessions.
Defending deferral rigorously requires one of:

- **SIZE** — architect-pass material; a real file/contract surface argument,
  not "felt big".
- **BLOCKED** — a real dependency on a not-yet-landed artifact, not "feels
  related".
- **LOGICAL FIT** — cleanly belongs with another sibling BD/commit; concrete
  same-file/same-contract fit, not "thematic".

A new BD that is LARGE and UNBLOCKED inserts IMMEDIATELY AFTER the current BD
or batch — not parked at end of v11.0, not in a "next batch" with no anchor;
when BLOCKED, it inserts at the exact unblock point. Per OQ-1 (rewritten
EXECUTION-PLAN §B), any new-BD-open additionally requires
user-discussion-and-approval.

---

## boundary-investigation-precedes-pack-defaults

Project and pack are intentionally designed differently. When making ANY
change to a project-side file (`project-template/` trees, project-shipped
content), an actor (reviewer, implementer, Pack Chat triage) MUST first
investigate whether a project-side SSOT exists for the concept being changed.
Pack-style mechanisms (`pack-ops/PACK-AGENTS.md` roster, Pack Chat orchestrator
role, pack-* agent names, `maintenance-docs/` design records, anything under
`pack-ops/`) are PACK-ONLY by construction — they do not exist at client
install, do not govern project behavior, and importing them into project-side
files is a regression that breaks at install or pollutes project-design intent.
The instinct "reach for the pack mechanism I know" is bias, not a starting
point: investigate the project-side SSOT FIRST. Failure mode this prevents — a
project-side surface (the project trinity,
`project-template/docs/pack/PLATFORM-SKILLS.md`, a project-side methodology
doc) acquires a pack-internal reference (`PACK-AGENTS.md`, a pack-* mechanism)
when the correct project-side SSOT was `project-template/docs/pack/PM-CHAT.md`.
See the `boundary-investigation` skill (loaded by all pack agents) for the
SSOT-investigation methodology.

**Corollary — a client-shipped reference to a pack-repo path.** Classify the
target first: DELETE the reference if the target is genuinely pack-only;
FORWARD-LOOK it to the landed client path if the target is a genuine project
asset the client will have.

---

## preflight-stop-means-stop

Every pack-coder agent prompt MUST include both halves of this pattern:

- **PREFLIGHT (platform-neutral, REQUIRED for all CLIs).** After all in-scope
  file edits + verification, BEFORE writing the IMPL-REPORT, the coder emits ONE
  plain-text line: `PREFLIGHT: N/N in-scope file edits complete; verification
  PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`, then writes the
  report. Pack Chat treats this line as the trust signal that the report-write
  starts from a complete-and-green state. If the coder cannot complete the
  preflight (an edit failed, a test failed), it reports what went wrong instead
  and does NOT write a partial IMPL-REPORT.

  Verification includes BOTH the in-scope test suite for the BD AND Check 43
  (V11 leak-sweep prevention; pack/project boundary scanner). When the commit
  touches any file under project-template/, pack-ops/, supporting-docs/, or
  scripts/, the coder MUST run `python3 scripts/validate-pack.py` against the
  working tree before the PREFLIGHT line; Check 43 (and the rest of the suite)
  MUST PASS. If Check 43 FAILs, the coder reports the failure (file:line +
  matched basename + suggested remediation) INSTEAD OF the IMPL-REPORT — Pack
  Chat decides whether to fix in this commit or escalate.

  **Per-check test runs.** When the commit modifies any of:
  `scripts/validate-pack.py` (any function/check), `scripts/init-project.sh`
  `_CLIENT_INSTALLED_FILES_START/_END` inventory, `scripts/lib/` files
  referenced by validate-pack checks, or any file in the `_CHECK_*_ALLOWLIST`
  referenced surfaces — the coder MUST run all relevant per-check test files at
  `scripts/tests/test-validate-pack-check-*.sh` before the PREFLIGHT line. ALL
  MUST PASS; on any FAIL the coder reports it (file:line + test name +
  diagnostic) and does NOT write the IMPL-REPORT. "Relevant" = (a) the test
  file matching the check ID being modified, AND (b) any test exercising the
  same `_iter_*` helper or shared logic surface; when in doubt, run ALL
  per-check test files (~5-15s total). An inventory edit updating
  `scripts/validate-pack.py` but not the per-check test fixtures (e.g.
  `scripts/tests/test-validate-pack-check-43.sh` or
  `scripts/tests/test-validate-pack-checks-36-37-38.sh` expected_extras) passes
  validate-pack yet FAILs the per-check tests on push — which is why these runs
  are mandatory before the PREFLIGHT line.

- **STOP-MEANS-STOP preamble (CLAUDE-CODE-SPECIFIC ENFORCEMENT, REQUIRED for
  all CLIs as content).** The coder prompt opens with an explicit instruction:
  "If you receive a parent-session message containing the words stop / halt /
  revert / do not continue, you MUST immediately stop ALL work, including any
  in-progress Write. Partial files are acceptable; do not append to make
  consistent. Stop authority is absolute and unconditional." This text is
  platform-neutral; the in-band ENFORCEMENT mechanism is platform-conditional:
  - Claude Code: SendMessage tool (Agent Teams,
    `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`); SECURITY WARNING classifier flags
    subagent defiance at handoff — the enforced path for parent-stop.
  - Codex CLI: a MAv2 `send_message` analog exists (flag-gated
    `multi_agent_v2`, not-yet-GA-documented), usable where enabled; otherwise
    the parent stop mechanism is the `/agent` command or natural-language ("ask
    Codex to stop the subagent"). Reliability caveats per research §2.6.
  - Antigravity: parent-control stop is native — the parent can interrupt a
    running subagent by messaging it, or kill it entirely (the killed
    subagent's temporary git worktree is auto-cleaned); a subagent can also be
    cancelled directly via the Stop Subagent control. Re-verify the subagent
    lifecycle against `antigravity.google/docs/subagents` (preview); see
    `maintenance-docs/v11-implementation/RESEARCH-BD-221-ANTIGRAVITY-DOCS-CAPTURE.md`
    § "Subagent lifecycle".

---

## enumerate-rules-inline

**Why:** When a rule is knowable from pack memory but the agent does not
enumerate it as something to verify before declaring complete, design defects
ship past the architect → planner → Pack Chat → coder gates and are caught only
at coder runtime. Pasting the literal rule text into the prompt makes the rule
a thing the agent must verify, not discover. Token cost rises (the prompt
grows), but rule compliance becomes auditable because the agent's task and
rules are co-located.

The imperative requires the LITERAL rule text — name + Why + How-to-apply
paragraphs — pasted into the agent prompt (not by reference such as "see
MEMORY.md"; not by hyperlink). The agent reads its rules from the prompt; it
does not have to discover them.

**How to apply:** Before spawning ANY sub-agent, Pack Chat assembles the prompt
with these sections in order: (1) STOP-MEANS-STOP + permission boundaries; (2)
**"Rules in force" block** — copy the LITERAL rule text from every applicable
MEMORY.md entry; each rule's name + Why + How-to-apply MUST appear verbatim;
applicability is by topic (architect rules for architect spawns, coder rules
for coder spawns, etc.) PLUS universally applicable rules (trinity, prison,
no-state-changing-git, no-destructive-without-approval) in every spawn; (3)
task description; (4) **"Rules-applied verification" instruction** — output ends
with a Rules-Applied Verification Block (see `rules-applied-verification-block`);
(5) PREFLIGHT obligation where applicable; (6) IMPL-REPORT / output-file
requirement. Pack Chat NEVER spawns an agent without the rules-in-force block.

The receiving agent READS IN FULL the named rule docs (CLAUDE.md incl. `## Pack
memory`, PACK-AGENTS/PACK-CHAT, project-template/CLAUDE.md when touching code)
plus the curated task-relevant memory files; it derives no unread rule and
substitutes no cached copy for a direct read.

Ground every prompt directive in a user decision or an agent report; inject no
Pack-Chat opinion, no proposed solution, no biased framing.

---

## rules-applied-verification-block

**Why:** Without this block, agents cite rules they've followed but skip rules
they didn't verify. Verification evidence is the only mechanism that
distinguishes "rule cited" from "rule applied." A sound-sounding citation of a
state-claim ("the tree has NO X outside the allowlist") with no grep output
behind it can be flatly wrong; the block's actual command output would have
failed the claim at design time rather than at coder runtime.

**How to apply:** Format: per-rule table `Rule | Verification evidence |
Conclusion`. Pack Chat verifies the block exists, every row has non-empty
evidence, every VIOLATED row gets surfaced to the user BEFORE any downstream
work (planner spawn / coder spawn / commit). Empty entries = treated as
VIOLATED. N/A rows require explicit justification.

Format (the literal block an agent appends as the final section of its output):

```
## Rules-Applied Verification
| Rule | Verification evidence | Conclusion |
|---|---|---|
| <rule-name> | <command + actual output, or quoted file:line> | COMPLIANT / N/A:<reason> / VIOLATED:<reason> |
| ... | ... | ... |
```

---

## open-item-surfacing

**Why.** The pack's auto-accept paths — a review or intervention mode set to
`none`, or an intervention mode set to `ambiguity` — accept a spawned agent's
recommendation without user review. That is safe ONLY when every agent's
recommendation reliably exists and rests on evidence or logic; a bare "found a
gap" with no options and no recommendation forces the orchestrator to either
stall or guess. A uniform surfacing shape at every open item turns the
recommendation into a dependable input, so the auto-accept paths never act on
an absent or memory-derived judgment.

**How to apply.** When a spawned agent (architect / planner / coder / reviewer
/ docs-researcher) hits an open item — a question, a gap, a scope expansion, or
a decision — surface it with three parts: (1) enough context for the reader to
understand the problem, (2) the agent's OWN options, and (3) an evidence- or
logic-based recommendation, OR an explicit "no recommendation can be given"
when neither evidence nor logic yields one. A recommendation that leans on
remembered state, or that resolves the item by pushing the work onto another
actor or a new BD, does not satisfy the rule. The rule composes with each
role's existing surfacing channel: it tightens the coder POQ (a POQ carries
context + options + recommendation, never a bare gap) and shapes the planner's
genuinely-open `MAINTAINER CHECK NEEDED` items and the reviewer's findings.
Each spawn's Rules-Applied Verification Block records compliance.

**Rejected alternative.** Let each agent surface open items in whatever shape
it prefers and rely on the user to fill the gaps — rejected: the auto-accept
paths remove the user from the loop for exactly those items, so an unshaped or
missing recommendation there is a silent correctness failure, not a cosmetic
one.

---

## empirical-evidence-blocks

**Why:** A design's state-claim ("the tree has NO X outside the allowlist") is
worthless without the verification that backs it. An architect who has the
matching regex but is not required to run it can ship a claim wrong by orders
of magnitude — and a downstream coder discovers the gap only after the design
has advanced. Requiring the evidence at design time catches the false claim
before it propagates.

**How to apply:** Every architect or planner prompt requires (a) enumeration of
the state-claims the design makes (in advance) and (b) an Empirical-Evidence
Block per state-claim in the design output. Pack Chat scans every architect /
planner output for state-claims; any without a corresponding block entry is
surfaced as a design defect (route back to architect/planner; do not advance to
planner / coder).

Format (one entry per state-claim; the design output embeds this block):

```
## Empirical-Evidence Block
### State-claim 1: "<verbatim claim from design>"
- **Command:** <bash command>
- **Output:** <verbatim command output, code-fenced>
- **HEAD:** <SHA>; **Date:** <YYYY-MM-DD>
- **Interpretation:** <how the output supports the claim>
- **Conclusion:** SUPPORTED / NOT-SUPPORTED / PARTIAL — <reason>
### State-claim 2: ...
```

---

## ci-guard-measure-then-bound

**Why:** An allowlist sized by assumption rather than measurement is
undersized: the fix-recipes under-scope the actual contamination, and the
guard fails on the unmeasured residue. The triage temptation is then to "widen
the allowlist" to make the guard pass — defeating the guard's whole purpose (it
exists to catch exactly that contamination). The right fix is to redo the
design with the actual tree measurement in hand, not to widen the allowlist to
admit the hits.

**How to apply:** Any architect spawn that includes a CI-guard / validator /
allowlist deliverable: the prompt requires the architect to execute (a)
measurement-first phase (grep/walk the tree, produce occurrence list), (b)
categorization (per-occurrence KEEP/STRIP), (c) fix-recipe design for every
STRIP, (d) allowlist sized to KEEP only, (e) projected post-fix verification.
The design output includes the measurement evidence + per-occurrence
categorization + the projected-clean verification. Pack Chat does NOT advance
the design to planner if any of these steps are skipped.
Additionally, any step that ENUMERATES repo files derives its candidate
set from git-tracked files (`git ls-files`), never a raw filesystem walk
(`rglob`/`os.walk`/`glob`/`find`), with a lenient SKIP when git is
unavailable — so untracked OS/editor junk cannot mask a true hit or
raise a false one (the failure mode is invisible in clean checkouts and
fresh worktrees, visible only in long-lived local checkouts).

The same measure-then-bound spirit governs a rename, mass-find-replace, or
keyword-migration: rename EVERY occurrence and gate on a grep-ZERO completeness
census (coder PREFLIGHT + reviewer), never a hand-enumerated anchor list — the
grep-zero gate is the measurement that bounds the change to complete.

---

## bounded-review-fix-cycle

**Why:** Pack Chat's judgment is compromised when it doubles as reviewer — it
misses staging defects and false working-state-proof claims in work it authored
or shepherded; independent reviewer-agent verification is the structural fix.
Bounding the cycle (max 2 review/fix pairs + 1 final review) prevents the
infinite-loop race-condition shape (fix A breaks B, fix B re-breaks A) and
surfaces design defects via architect escalation rather than letting them hide
as repeated local findings. Two fix-coder passes is empirically enough for
genuine fix-work; if findings persist past that, the commit's design is wrong —
local patching can't fix it, only architect-level intervention can. This
sharpens "Pack Chat does NO fixes": Pack Chat NEVER reviews coder output
directly, and the maximum is 3 reviewer spawns / 2 fix-coder spawns per commit,
after which architect escalation is the only path.

**Cycle (per commit):**
1. **Coder** runs → edits + IMPL-REPORT + Rules-Applied Verification Block.
2. **Reviewer pass 1** (`pack-reviewer` fresh; rules-in-force). Clean → skip to
   step 7. Findings → step 3.
3. Pack Chat triages findings to user → user approves fix/defer per finding →
   **Fix-coder pass 1** (`pack-fix-coder` fresh; rules-in-force; applies
   user-approved fixes).
4. **Reviewer pass 2** (`pack-reviewer` fresh; rules-in-force; re-verifies).
   Clean → skip to step 7. Findings → step 5.
5. Pack Chat triages → user approves → **Fix-coder pass 2** (FINAL fix-coder
   allowed).
6. **Reviewer pass 3** (`pack-reviewer` fresh; FINAL reviewer pass). Clean →
   step 7. Issues remain → **STOP cycle. Spawn `pack-architect`** to diagnose
   root cause + propose path forward to user (typical options: scope-down the
   commit / split into smaller commits / re-sequence / revert and redesign /
   defer to follow-up BD). User decides; no fix-coder pass 3.
7. Pack Chat brings G7b commit-approval to user with the latest clean reviewer
   report attached.

**How to apply:** Pack Chat spawns each agent with rules-in-force enumeration,
tracks which pass is active, and exposes it in progress markers (`**Reviewer
pass 1 of max-3 (C8 of 38)**`, `**Fix-coder pass 1 of max-2 (C8 of 38)**`,
`**Architect escalation (C8 of 38)**`). It routes reports to the user (does NOT
use Read/Edit/Bash to verify coder edits independently — even small mechanical
commits go through the full cycle). After Reviewer pass 3: no more fix-coders;
architect escalation only.

**Architect-escalation contract** (Reviewer pass 3 still dirty): Pack Chat
spawns `pack-architect` with the coder's IMPL-REPORT, all 3 reviewer reports,
both fix-coder reports, and the persistent-issue list. Architect produces
DIAGNOSIS (root cause) + PROPOSAL (path forward options). User decides — Pack
Chat does not pre-select.

**Final-reviewer-pass note:** Reviewer pass 3 exists ONLY to verify fix-coder
pass 2 closed the prior cycle's findings. It does NOT trigger a new fix round.
New findings at pass 3 + any unresolved prior findings together trigger
architect escalation.

**Position checkpoint:** restate the bounded-cycle position at every coder/fix
completion; a fix is never terminal (a post-fix reviewer ALWAYS runs); never
self-review.

---

## pack-side-project-concepts-deliverable-only

**ALLOWED:** pack-side scripts that emit project-side templates (e.g.,
`scripts/init-project.sh` stages that copy `project-template/` content);
pack-side validate-pack checks that verify project-side structure; pack-side
architecture/planner docs that design project-side surfaces; pack memory rules
that govern project-side semantics.

**FORBIDDEN:** pack-root form admitting `td` / `phase-epic-skeleton` /
`phase-task-skeleton` wi-type options (pack doesn't file TDs or phase-skeletons
against itself); `pack-ops/` files referencing project-side TD entries
operationally (pack-ops uses BDs in `/backlog/` and batch labels in
`maintenance-docs/archive/v11/EXECUTION-PLAN-V11.0.md`); pack-root
configs (`.claude/`, `.codex/`,
`.agents/` / `.agents-plugin/` at pack-root) using project-side concepts for pack-self-management.

**The test:** "Is this pack-side surface being used to CONSTRUCT a project-side
deliverable, or is it part of pack-self-management?" If the surface IS the
deliverable's source-of-truth (templates, scripts that emit, validators that
check), project-side references are allowed. If the surface is
pack-self-management, project-side references are forbidden.

**Why:** The rule is implicit in
`feedback_pack_project_separation_of_concerns` +
`feedback_bd_pack_only_operational_rule`, made explicit here. Removing BD
admissions from project-side forms has an easy-to-miss asymmetric counterpart:
symmetrically cleaning up TD/phase from pack-side self-management surfaces.
Worked example of the forbidden shape: a pack-root
`.github/ISSUE_TEMPLATE/work-item.yml` admitting `td`, `phase-epic-skeleton`,
`phase-task-skeleton` — pack does not file those against itself, so they should
be removed.

**Inverse direction (equally categorical):** project-related territory carries
NO reference to pack self-management — BD IDs, `pack-ops/`, `maintenance-docs/`,
pack-* agent names, validate-pack, the Pack Chat orchestrator role. Apply the
operational-vs-explanatory test to each candidate reference; surgical removal is
the default disposition.

---

## enumerate-encoding-surfaces

- The audited surface itself (form, config, library, doc).
- Any validator that asserts content invariants on the surface (e.g.,
  `scripts/validate-pack.py` per-surface tables).
- Any TEST file that asserts content invariants on the surface (e.g.,
  `scripts/tests/test-issue-forms.sh` for issue forms).
- Any CI workflow definition that references the surface or its tests.
- Any cross-reference docs (architect docs, planner docs, IMPL-REPORTs)
  describing the surface's expected state.

Each ENCODING surface must update in lock-step with the audited surface.
Asymmetric coverage (walking validators but not tests, or vice versa) misses
lock-step dependencies and creates audit gaps.

**Verdict sub-class.** LEAK (operational, test-encoded) — pack-self-management
state encoded in a test file's assertions, where the assertion's truth value
depends on whether the audited surface admits a forbidden concept. Treat the
same as a LEAK in the audited surface itself.

**Why:** An audit that walks the surface file + the validator's per-surface
dict but misses the TEST file's hardcoded assertions leaves the test encoding
the pre-cleanup state — and a per-check-test gate (not the audit) catches the
gap after the fact. The methodology trap is treating `scripts/tests/*` as
"constructor context" wholesale, when the correct granularity is per-assertion:
constructor portions assert project-side emission, self-management portions
assert pack-side state, and both must update in lock-step with the surface. The
`review` skill at `.claude/skills/review/SKILL.md` + trinity mirrors carries the
operational checklist.

---

## skill-agent-maintenance-mechanical

Maintenance is mechanical, complete, reviewed, and rule-strict. Structural
change — including rule changes — requires architect-then-planner, never
convenience. Mechanical changes preserve client `x-` skills/agents conforming
to existing dimensions; breaking the `x-` contract escalates to structural,
requiring architect-pass migrator coverage. Workflow artifacts
(architect/planner/coder/reviewer/auditor outputs: `ARCHITECTURE-*.md`,
`PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`,
`IMPLEMENTATION-REPORT-*-RETRO-FIX.md`, `PACK-REVIEW-*.md`,
`PACK-REVIEW-*-RETRO.md`, `AUDIT-*.md`, `RESEARCH-*.md`, `*-DISCOVERY.md`,
`CLEANUP-INPUTS-*.md`) are exempted from the "no new top-level doc" structural
signal during their batch's active development; they sweep to
`maintenance-docs/archive/vN/` at version ship as the final pre-tag step
(Pattern B). Threshold conditions and worked examples in
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.

---

## pack-repo-code-comment-deferrals

Cross-reference: the project-template section is canonical for the typed format;
the pack-repo follows the same convention so pack-coder behavior is consistent
across pack-repo and client-repo contexts.

---

## filename-uniqueness-heuristic

Quick check: `find . -name "<proposed-name>" -not -path "./.git/*"`.
Structurally required collisions are exempt (trinity files, the per-skill
skill-manifest name, ecosystem-fixed names such as the dot-gitignore /
pyproject-toml / Package-swift files); for these exempted collisions, prose
references must include path context ("pack-root `CLAUDE.md`" vs
"project-template `CLAUDE.md`").

Cross-reference forms that STRIP the unique filename also violate the rule's
intent even when they avoid the literal `.md` extension — bare-version
shorthand like `V3.3 §3.X` referencing
`maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` sections is a leak
under the rule's spirit: the reader has no filename to follow, no path to
resolve, and the version shorthand is ambiguous (a `V3.3` ref could mean any
v3.3-versioned doc). Audit scans looking only for `*.md` patterns MISS these,
so reviewers treat bare-version shorthand for pack-internal docs as the same
leak class as explicit `*.md` cites (the audit-vocabulary-gap pattern — a bare
`V3.3` ref in a doc like `supporting-docs/METHODOLOGY.md` is as much a leak as
an explicit `.md` cite).

---

## architect-doc-reality-reconciliation

Worked example: the §9.2 addendum in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` names the first
realized consumer; the consumer carries the matching docstring; the
IMPL-REPORT links both. This pattern is load-bearing for any future shipped
surface that pre-existed in an architect doc.

---

## regenerate-manifest-v11-surface

The trigger is intentionally inclusive — false positives (e.g., a
`scripts/test-*.sh` edit that doesn't affect fixtures, or a
`supporting-docs/MIGRATION-v10-to-v11.md` edit, a pre-install reference not
copied to clients) cost ~30-90s of unnecessary rebuild but produce no incorrect
manifest change; false negatives within v11-surface are impossible because every
fixture-affecting file lives under one of these four directories.
Fixture-affecting paths today: all of `project-template/**` (the client-shipped
content under it is a fixture input; the pack-ops copies are NOT) and `scripts/**`
minus the test set (`scripts/test*.sh`, `scripts/tests/**`) and the manifest
tooling itself (`scripts/manifest-sync.sh`, `scripts/lib/manifest-inputs.sh`);
`test-fixtures/build.sh`; `supporting-docs/METHODOLOGY.md` and
`supporting-docs/INSTALL-PROCEDURES.md` (`scripts/init-project.sh` stage S6
copies to client `docs/pack/`). The fixture-input predicate is the single source
of truth in `scripts/lib/manifest-inputs.sh`, shared by `scripts/manifest-sync.sh`
and validate-pack Check 62, so the input set cannot drift between the tool and
the check. v11-* fixture row SHAs drift naturally with any
v11-surface change (per `test-fixtures/README.md` § Determinism and the
`_update_manifest` comment in `test-fixtures/build.sh`); a stale
manifest fails CI's `fixture manifest verify` step even when every functional
test passes. **Why:** a manifest left stale after a v11-surface edit fails CI
on the manifest-comparison step alone, even when every functional step passes,
and the drift accumulates silently across multiple intentional v11-surface
commits — so each miss costs a separate recovery `fix:` commit.
**How to apply:** the manifest is NOT a per-commit chore — do NOT run
`build.sh --all --clean` and stage `test-fixtures/manifest.txt` per commit.
Instead, the orchestrator runs `scripts/manifest-sync.sh` ONCE before
`git push`: the tool checks the unpushed range against the fixture-input
predicate (`scripts/lib/manifest-inputs.sh`) and regenerates the manifest only
when a fixture input changed (rebuilds once via
`bash test-fixtures/build.sh --all --clean`, then commits the output iff the
manifest differs on disk). Correctness is enforced by two gates, not by prose:
CI `bash test-fixtures/build.sh --verify` (the authoritative SHA gate — fails RED
on any stale manifest at the pushed HEAD) and validate-pack Check 62 (a cheap
structural screen on the manifest's shape — row count, fixture names, SHA
format). Agents NEVER hand-edit or per-commit-regenerate the manifest; the tool
reconciles it at push and the two gates catch any miss. The design of record is
`maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md`.
Cross-reference: the "Test infra is self-provisioned" bullet above governs
*test provisioning*; this bullet governs *manifest maintenance* and is
load-bearing for the `fixture manifest verify` CI gate.

---

## cross-cli-reference-normalization

Byte-identical cross-trinity adoption of CLI-specific paths is
WRONG even when it visually closes drift — body-text drift and cross-CLI
references are different classes (see
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` §1 table). Worked
example: byte-identically copying `GEMINI.md`'s `.claude/settings.json`
reference is correct for the CLAUDE form but wrong for the Gemini audience,
which resolves to `.gemini/.env` per §4.1.

---

## dependency-direction-placement

Ship-status and dependency-direction are orthogonal; placement follows the
latter. A deliverable normally lives project-side, and a new client-shipped
script defaults to `project-template/scripts/`. A file a PACK OPERATION depends
on at runtime cannot live project-side without making a project deliverable a
dependency of a pack op — forbidden — so it stays pack-side.

Pack and project are SEPARATE surfaces whose behavior is MIRRORED but CUSTOMIZED
per side. There are NO dual-use files: even when a pack-side file and a client's
file would be byte-identical, the client gets its OWN customized copy under
`project-template/`, never the pack-side file itself. One file serving both a
pack op and a client surface couples the two — a pack-op change silently
rewrites client behavior, and vice-versa — the coupling the separation forbids.

Worked example: `scripts/lib/detect.sh` is `source`d by `scripts/init-project.sh` /
`scripts/add-capability.sh` / the migrator (all pack operations), so it STAYS
pack-side. The client needs equivalent detection, so it ships a SEPARATE
project-side copy — the pack-side file does NOT double as the client's. The
`_SANCTIONED_PACK_SIDE_SHIPPED` allowlist + CI Check 47 (install-map's pack-side
subset == the constant) is the bounded exception that would let a
pack-side-located file ALSO ship; its GOAL STATE is EMPTY. An empty allowlist
turns Check 47 into the machine-enforcement of the no-dual-use default: any
pack-side ship not in the constant fails CI. The set is SHRINK-ONLY and MAY
NEVER GROW — there is no admission path and no sign-off exception; the lazy
"ship from `scripts/` too" path fails by default. The dual-use-vs-separate-copy
analysis behind these pack-side placements lives in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md`
§8.

## pack-chat-minor-edits-only

**Why.** Letting Pack Chat edit pack-chat-only files directly at ANY depth
creates an asymmetry: coder edits flow through the bounded review/fix cycle, but
Pack-Chat-direct edits do not (Pack Chat cannot review itself — see
`bounded-review-fix-cycle`). On a large structural change this lets Pack Chat
hand-edit substantial pack-chat-only content with NO independent review while
the coder's edits get the cycle — landing un-reviewed substantive edits of
LANDED content. The fix makes review uniform per CLASS: substantive edits of
already-landed content + rule edits + out-of-small-set edits run through a coder
+ reviewer; NEW-entry authoring stays Pack-Chat-direct under the user's
governance approval.

**How to apply.** Classify every pack-chat-only edit by the §2 boundary in
ARCHITECTURE-BD-208.md (Option B): MINOR (Pack-Chat-direct) = (a) a bookkeeping
token (status flip / version bump / dated note / table row / decided-block
append) OR (b) authoring a GENUINELY NEW entry (BD-open at a new ID /
version-boundary CHANGELOG entry) — the user's governance approval IS the review.
MAJOR (→ coder) = a substantive edit of ALREADY-LANDED content (re-scope /
multi-field rewrite / structural rewrite), a rule edit, or any out-of-small-set
edit. A delete-and-reauthor of a landed ID is MAJOR (landed-content edit), not a
new author. Tie-break: when unsure new-vs-landed, MAJOR. Scoping a pack-chat-only file
INTO a coder prompt is the supported path and is NOT a boundary violation (the
same scope-in clause PACK-AGENTS.md § "Agent permission rules" already grants
per-entry dirs). A bookkeeping edit gets Pack Chat's `validate-pack`/parity/grep
sanity pass; a new-entry author rides the user's governance review; neither
self-promotes into a substantive edit of landed content (that is MAJOR).

**Rejected alternative.** "Let Pack Chat keep editing pack-chat-only at any
depth, just add a post-hoc reviewer pass on Pack-Chat edits." Rejected: Pack
Chat cannot spawn a reviewer on its OWN in-place edits without first packaging
them as a coder deliverable (no IMPL-REPORT, no fresh-context diff to review) —
the clean structural fix is to route major edits through the coder that already
produces the reviewable artifact. This composes `bounded-review-fix-cycle`
rather than bolting a second review path onto Pack Chat.

---

## spawn-unique-naming

**Why.** Re-finding a still-alive spawn — e.g. a docs-researcher to be
re-engaged — otherwise requires digging the `agentId` out of session JSONL by
hand (transcript archaeology). A unique, descriptive `name` is the stable key
the discovery mechanism records and re-finds by, eliminating that dig. The
discipline is CROSS-CLI because all three platforms (Claude Code, Codex,
Antigravity) spawn named agents, so the naming convention must be uniform
wherever an orchestrator later needs to re-find a spawn.

**How.** Every spawn carries a `name` of the shape `<role>-<bd>-<facet>[-<seq>]`
(lowercase kebab, `^[a-z0-9][a-z0-9-]{2,47}$`): the role token (`subagent_type`
minus the `pack-` prefix), the work anchor (`bdNNN`/`batchNN`), a short scope facet,
and a `-2`/`-3`… uniquifier to keep a repeated triple unique within a live cycle.
Uniqueness is enforced by DISCIPLINE — no platform guarantees it. The per-CLI
name-field reference is audience-correct in each trinity file (Claude Agent-tool
`name`; Codex agent `name`; Antigravity known agent ID / named-role type).

**Rejected alternative.** Free-form / non-descriptive names (the orchestrator cannot
tell two spawns apart, defeating re-find); UUID-suffixed names (machine-unique but
human-opaque, so a human re-find still requires archaeology — the exact failure the
rule closes).

---

## spawn-registry-find

**Why.** A unique name is only useful if a DURABLE place maps it to a
re-engageable handle and survives a parent context compaction. A gitignored
on-disk ledger gives the orchestrator a re-readable record of every spawn, so a
still-alive agent is re-found from disk with NO transcript archaeology — even
after the parent's context is compacted and the in-memory spawn list is gone.

**How.** The orchestrator records each Agent-tool spawn as one JSON object per line
(`{name, agentId, purpose, status}`) in the gitignored per-clone ledger
`graphify-out/.pack-spawn-registry.jsonl` (modeled on the existing
`graphify-out/.pack-refresh-status` precedent — NEVER committed, per
`agents-never-commit`). Lookup precedence is by NAME → by agentId (both work as
`SendMessage.to`). The registry is consulted ONLY after the `fresh-agent-default`
gate authorizes a re-engage — it fixes HOW-to-find, not WHEN-to-reengage. This
MECHANISM is Claude-only; Codex MAv2 (`list_agents`/`resume_agent`) and Antigravity
`agy` analogs exist but need their own verification + mapping.

The registry is a same-clone history + re-find accelerator, NOT a transfer
mechanism: because it is gitignored it never reaches a fresh clone / another
machine / another CLI. The committed `pack-ops/session-state.json` snapshot
(`session-state-snapshot`) is the SOLE authority for the resumable in-flight
frontier; the registry is never read to answer "what is the current in-flight
frontier." This is a construction boundary, not a discipline: the resume path
(`/pack-startup`) reads only the snapshot, so a stale registry tail can never
mislead a resume — the two surfaces are not both authorities.

**Rejected alternative.** A committed manifest (`agents-never-commit` forbids the
mid-task commit and it churns the tree); the Agent-Teams `members` list (teams-only,
not durable across compaction); a message-id addressing tier (no such primitive
exists — do not invent one).

---

## reconciliation-instance-independence

**Why.** A reconciliation pass resolves an adversarial review's findings
cleanly. The original author is contaminated and design-biased toward its own
design (it will defend it); the adversarial reviewer is biased toward its own
findings (it will over-fix to vindicate them). A FRESH instance reading both the
design AND the review as inputs is the only party with no stake in either — the
same independence rationale as `fresh-agent-default`, "No prior reviews to
pack-reviewer", and the per-commit fresh-coder rule, applied to the
reconciliation step.

**How.** The reconciliation pass spawns a NEW instance of the relevant discipline (a
fresh architect to reconcile an architect design; a fresh planner for a plan; etc.),
handed the design + the adversarial review as SUBJECTS to reconcile. `docs-researcher`
is exempt — its work is factual inventory, accumulated context helps, and it carries
no design bias. Carve-out (1): the user EXPLICITLY asks to re-engage an existing agent
(Claude `SendMessage`, found via the spawn registry; Codex/Antigravity per-platform
re-engage). Carve-out (2): an architect-challenge per-case evidence/logic argument.

**Rejected alternative.** (i) Reuse the original author "because it has the context" —
that context IS the contamination. (ii) Reuse the adversarial reviewer "because it
knows the findings" — that knowledge IS the bias. (iii) A blanket "any agent may be
reused if the user said so once" — the carve-out is per-instance/explicit, not
standing. (iv) Exempt MORE roles than `docs-researcher` — only factual-inventory work
qualifies for the no-design-bias exemption.

**The general fresh-agent default.** Every agent task is a FRESH spawn;
re-engaging an existing or in-flight agent (SendMessage) is the exception that
requires an explicit user decision. Reconciliation independence is this same
default applied to the reconciliation pass.

---

## large-bd-pipeline-standard

**Why.** The rigorous large-BD development flow — optional researcher(s), an
architect, an adversarial architect review, reconciliation, a planner, an
adversarial planner review, reconciliation, the user gates, and parallel
worktree coder waves — has run in practice (it is the worked precedent the
recent launch-gate BDs followed), but it was scatter-documented: the chain
lived implicitly across separate `## Pack memory` rules and the adversarial
passes were captured only in out-of-repo Pack-Chat memory. A fresh session or
spawned agent could not rely on a single in-repo statement of WHEN the heavy
pipeline is mandatory versus optional. Codifying ONE size-tiered standard in
the SSOT gives every actor a deterministic, audit-clear test instead of
folklore — and prevents both under-rigor (skipping an adversarial pass on a
launch-gate BD) and over-rigor (spending the adversarial budget on a routine
one-clause rule tweak).

**How.** For a LARGE BD the official pipeline is DETERMINISTIC — every stage
mandatory except reconciliation, which runs ONLY when the preceding adversarial
pass returned findings (no findings ⇒ nothing to reconcile, a logical
consequence, never a discretionary skip): docs-researcher (ALWAYS first —
internal census always; external-docs verification per-need) → architect →
adversarial architect review → reconciliation architect (if findings) → user
design review → planner → adversarial planner review → reconciliation planner
(if findings) → user planner-to-coder gate → parallel worktree coder waves (off
the rule-10 map; each commit's bounded review/fix cycle in its worktree;
patches applied sequentially under the conflict protocol; superseded docs
deleted; the audit set preserved). The docs-researcher and both adversarial
passes are UNCONDITIONAL for a LARGE BD. The size-tiering test runs four yes/no
signals against repo state or the BD entry — never a vibe:

- **L1 launch-gate** — the BD is a launch blocker for the current major
  (its `Target:`/`Position:` marks it so, or the user names it launch-gating).
- **L2 cross-surface** — the edit-set spans ≥2 families of: trinity
  `## Pack memory` · `pack-ops/` operating docs · `scripts/`+validators ·
  `project-template/` product · agent/skill definitions.
- **L3 blast-radius** — the BD changes a rule/contract/validator that ≥3
  surfaces ENCODE (per `enumerate-encoding-surfaces`), OR a researcher
  blast-radius census is REQUIRED before design.
- **L4 structural** — the BD adds a NEW convention, a NEW or changed CI check,
  a file-tree-shape change, a migration path, or a NEW rule. (Tightening:
  amending a CLAUSE of an EXISTING rule, with no new check/convention/tree
  change, does NOT fire L4.)

The CONSEQUENCE is decoupled from any single signal: a BD is LARGE — running
the deterministic flow above (both adversarial reviews mandatory) — iff L1
(launch-gate) fires alone, OR ≥2 of the four signals fire. Otherwise it runs
the base flow (optional researcher → architect → planner → coder + the bounded
review/fix cycle); there the two adversarial passes are elective (at user
election). A single non-launch signal alone (e.g. a one-clause amend to an
existing rule) does NOT make the BD large. Tie-break: when genuinely in doubt between base-flow and
mandatory-adversarial, treat as LARGE (the rigor is the conservative error,
mirroring the "when in doubt … it is MAJOR" disposition in
`pack-chat-minor-edits-only`). Launch-gate stands alone because a launch
blocker is the one axis where a missed adversarial pass is irrecoverable (it
ships into the cut); every other signal alone is recoverable at base-flow
rigor. The escalation detail the terse trinity body omits lives here: a LARGE
BD takes the two adversarial reviews as the MINIMUM, and a larger or
higher-stakes gap may take ADDITIONAL adversarial rounds beyond the minimum
two, at architect/planner judgment. Each stage continues to obey its own
`## Pack memory` rule — the umbrella NAMES and ORDERS the stages; it does not
override any of them.

The umbrella NAMES and ORDERS the stages; the design-time cross-BD shared-
surface scan it points to at the architect stage is its own tagged rule
(`cross-bd-collision-scan`), keeping this umbrella at its concision floor.

**Boundary (vs `reconciliation-instance-independence`).** The umbrella NAMES
the adversarial stages; `reconciliation-instance-independence` governs the
fresh-instance reconciliation that follows a NEEDS-REWORK verdict —
complementary, not overlapping.

**Rejected alternative.** Re-tagging the three existing untagged pipeline
rules (`Researcher-first pipeline`, `Pack-architect spawn protocol`,
`Planner output → user review → coder spawn`) so the umbrella could enumerate
their slugs inline — rejected as scope creep: it would force new bijection
rows and rationale sections for rules that already work untagged, for no
behavior change. The umbrella REFERENCES them by category ("Each stage obeys
its own `## Pack memory` rule") instead, requiring exactly one new slug and
one new rationale section.

**Researcher blast-radius mapping (reference-heavy change).** For a
reference-heavy structural change the researcher exhaustively maps the blast
radius — every reference categorized and dispositioned, counts reconciled —
before the architect designs, so the architect works from a complete surface
census rather than an a-priori guess.

---

## cross-bd-collision-scan

**Why.** Two open BDs that edit the SAME surface — the same rule bullet, the
same validator check, the same template file — can be designed in isolation and
then collide at integration, where one BD's patch silently undoes or conflicts
with the other's. The collision is cheap to catch at design time (intersect the
two blast-radius sets) and expensive to catch at merge time (a conflicted
patch, a regressed rule, a re-review). The recurring failure mode was that no
stage owned the cross-BD check: the researcher maps THIS BD's blast radius, the
architect designs against it, but neither looked sideways at the OTHER open BDs'
surfaces. Pinning the scan to the architect stage — after the researcher set
exists, before the design hardens — makes the collision a design input, not a
merge surprise.

**How.** At the architect stage, once the researcher's blast-radius set exists,
the architect intersects THIS BD's set with every open BD's blast-radius /
structured-surface set and records collision-or-none in an Empirical-Evidence
Block. Keying on the researcher blast-radius set (not the free-text
`File/Symbol` line) is the load-bearing design choice — the field that ACTUALLY
catches a missed collision is the structured surface set, whereas a prose/TBD
`File/Symbol` gives the scan zero recall. The scan is a COORDINATE signal
(sequence two co-editing BDs), never a hard gate: legitimate concurrent edits
are normal and the sequencing protocol handles them. It runs over the pack
backlog and the project backlog template alike; the client-side counterpart
ships as a documented workflow deliverable, not this pack rule.

**Boundary (vs `large-bd-pipeline-standard`).** The umbrella NAMES and ORDERS
the pipeline stages and points to this scan at the architect position; this
rule carries the scan's mechanics (what to intersect, what to key on, that it
is a coordinate signal not a gate). The umbrella stays at its concision floor;
the scan lives here.

---

## graph-first-context

**Why.** The pack is doc/reference/agent-heavy; agents and Pack Chat re-read the
file tree for orientation, which is token-expensive. A compact knowledge
subgraph (built by `graphify`, gitignored at `graphify-out/`) answers
orientation / relationship / blast-radius / "what relates to X" / "where does Y
live" questions at ~0 tokens — a deterministic local CLI query, no LLM call:
that is the token-efficiency win graph-first buys. The graph is a per-clone,
gitignored, manual opt-in — a clone with no graph is the DEFAULT, so the rule
must degrade gracefully (G1 existence guard) and never block on a failed query
(G2 fallback). It is NOT a hard dependency of any task — a best-effort
accelerator only.

**How to apply.** When the graph exists, DISCOVERY/RECALL ("what relates to X /
where does Y live / blast radius of Z") is graph-FIRST and mandatory: query the
graph to establish the candidate surface set before broad tree reads. grep/Read
is the VERIFICATION layer — exact bytes/counts at a named surface, an
authoritative SSOT field VALUE (a BD `Status`, the README version table, a
`_rules.md` contract), freshly-changed/uncommitted files (`git diff`/Read),
whole-file content of a named file, and content the graph does not index
(archive/excluded) — none of which licenses skipping graph-first discovery; a
literal-occurrence census runs the graph FIRST to find candidates, THEN greps
each to grep-zero. If the graph is absent or a query fails or returns nothing
useful, use normal tools (G1 + G2). `--graph` is ALWAYS absolute; `--budget`
tiers are 2000 human / 1500 spawned agent / 1000 Pack-Chat prompt-construction;
the backend is ALWAYS `--backend claude-cli` (no-key subscription — never
`claude`, which demands `ANTHROPIC_API_KEY`). Agents QUERY, never BUILD
(building is a main-session/orchestrator job and the only step that costs
subscription). Worked example: to scope which files a coder needs, Pack Chat
runs `graphify query`/`affected` and names those exact files in the prompt
instead of "read the tree." The rule lives in the pack-root trinity
(`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`), normalized per CLI audience
(`cross-cli-reference-normalization`). Boundary: the graph MAY index the whole
repo incl. `project-template/`, but the rule + every setup artifact stay
pack-side (`bd-pack-only`).

**Rejected alternatives.** (a) An untagged convention bullet — rejected: the
rule is spawn-relevant `[roles: universal]`, and the tagged form gives it a
discoverable rationale pointer (this section) under the Check 45 bijection.
(b) `graphify claude install`'s auto-written `CLAUDE.md` section — rejected:
it writes only `CLAUDE.md` (breaking trinity symmetry) AND a surprise
PreToolUse hook the pack does not want. (c) Per-agent-frontmatter enablement
(a `skills:`/`tools:` change) — unnecessary: querying needs `Bash` only, which
all 5 pack agents already carry, and preloading the ~32KB build-oriented
graphify skill is wasteful for a read-only query.

---

## operating-docs-no-history-no-bloat

**Why.** An operating doc is re-read on essentially every agent and chat
invocation (the standing battery is ~155 per cycle). History and roadmap text
in such a doc costs context tokens on every one of those reads, buries the live
rule under provenance prose, and serves no operational purpose — an agent acting
on the doc never needs to know which past change introduced a rule or that some
not-yet-built feature exists. The Why and the future live in their right homes
(entry stores, maintenance docs, IMPL reports); the operating doc states only
what currently operates.

**How to apply.** Three bans, applied when authoring or editing any
operating doc:

- *No history.* Strip every historical / audit-trail shape: dated notes and
  lock-stamps (the `YYYY-MM-DD` form), past-action narration that says a
  `BD-NNN` entry did something, `per BD-NNN`-style provenance justification,
  bare `(BD-NNN)` origin tags on a rule, commit-hash and prior-event
  references, and "carried-from" provenance. Strip the provenance WITHOUT
  losing the operative meaning — restate the rule as a standalone directive
  (e.g. turn "BD-NNN added these gates" into "These gates ensure …"), so the
  instruction survives intact and only the origin tag is removed.
- *No deferred-feature mentions.* Remove any prose that describes a deferred,
  unimplemented, or off-by-default feature — even prose whose only purpose is
  to say the feature is deferred. State only what currently exists and
  operates; the mention is re-added when the feature actually ships.
- *Terse + structured.* Convert mega-bullet run-ons and
  prose-that-should-be-a-table into clauses or tables, and delete padding —
  while preserving every directive, trigger, and exception (a clause-set
  before/after the edit must be equal modulo deleted padding).

**KEEP.** A LIVE forward-pointer to CURRENT in-flight work stays: a pointer
to an open entry the agent must still act on (the `until BD-NNN` form for a
migration in flight) and a cross-reference to a live `ARCHITECTURE-*.md`
companion doc that exists and is read at task time. Two tests gate a KEEP:
the token must point at live pending work AND keeping it must NOT require
describing a deferred feature. Format and grammar examples (an illustrative
filename or date pattern a write-contract emits) also KEEP — they are
examples the doc acts on, not provenance.

**Carve-out.** The rule binds operating docs ONLY. Reference docs —
changelog and backlog entry stores, maintenance docs, and IMPL reports —
are the correct homes for history and roadmap and are unrestricted; the rule
never strips them.

**Rejected alternatives.** (a) Keeping provenance "for traceability" —
rejected: traceability lives in the entry stores and version control, not in
the doc an agent executes. (b) Keeping a deferred-feature note "so readers
know it is coming" — rejected: an agent never operates a deferred feature, so
the note is pure context cost; it returns when the feature ships.

---

## session-state-snapshot

**Why.** Resumable live state — which BDs are active, which agents are mid-flight,
the user-decided queue order, the parallelization mode, the in-commit cycle
position — used to live ONLY in CLI native memory (a per-CLI store) and the
gitignored spawn registry. Neither travels: a fresh clone, a different machine,
or a different CLI cannot read either, so a resume lost the frontier and a
hand-maintained running note drifted stale (it accreted stacked entries and
lessons until it no longer matched the committed tree). A single committed,
CLI-agnostic snapshot fixes both failures at once: it travels with `git pull`,
any CLI reads it identically, and CI can enforce its shape.

**How.** Pack Chat keeps `pack-ops/session-state.json` — a committed JSON data
file (outside every operating-doc `.md` family glob; one OUT-OF-FAMILY literal
for the Check 69 closed-world meta-check) — as the SOLE authority for the
current resumable frontier. It is OVERWRITTEN field-by-field on every state
transition (a spawn, a completion, a commit landing, a queue reorder, a
parallel↔serial change, a pending-decision capture/resolution, a review/fix
advance), never appended-to. CLI memory is forbidden for state. The committed
boundary commit is the durable resume anchor; `/pack-startup` reads the snapshot
to report the resume frontier. Three bespoke checks (struct / freshness / no-
history grammar) enforce well-formedness, boundary-reachability, and the never-
history rule at the validate-pack gate (CI + per-commit) — bare `BD-NNN` tags are
legitimate state, but a second date, an off-field SHA, narration, or growth past
the size cap fails the build.

**Rejected alternative.** (a) Keep state in CLI memory or the gitignored spawn
registry — neither travels across machine/CLI/fresh-clone, the exact gap that
loses the frontier on resume. (b) Append a stacked running note — append
behavior is the root cause: it merges history+state into one blob that drifts
stale. (c) Make the snapshot an `.md` operating doc with a content-anchored
history allowlist — its BD-lines change on every overwrite, so the allowlist
goes stale instantly; a non-`.md` data file plus a bespoke grammar check is the
clean fit. (d) Commit the spawn registry instead — it is ~95% append-only
history, violates `agents-never-commit` (agents write it), and bloats the tree.

---

## memory-not-an-ssot

**Why.** Out-of-repo CLI memory is a per-clone, per-machine, un-versioned
store the pack cannot control. A pack/project RULE cached there forks from its
in-repo source the moment the in-repo rule changes, and an actor reading the
cache acts on a stale rule with no audit trail the user could trace — the exact
silent-drift failure the in-repo SSOT + trinity-wins model exists to prevent.
The prohibition is only safe if paired with a positive discipline: re-reading
the rules from the in-repo SSOT at the start of every commit means no actor
ever needs the cache, so the cache can hold zero rules without loss.

**How to apply.** (1) NEVER author a memory that states a pack/project rule —
the rule's sole home is the in-repo SSOT (trinity `## Pack memory` +
`[rationale:]` bodies, `PACK-CHAT.md`, `PACK-AGENTS.md`, the `/backlog/` +
`/changelog/` trees + `_rules.md`, `README.md`). (2) At the start of every
commit, Pack Chat re-reads the applicable in-repo rules from that SSOT (not
from memory, not from prior-session recall). (3) Unsaved state or notes go to a
BD, a doc, or `pack-ops/session-state.json` (`session-state-snapshot`), never a
memory. The ONLY memories about pack/project rules that may exist are the three
meta-governance memories that encode clauses (1)-(3) — they are pointers to
this rule, not rule content themselves, so they cannot go stale (if this rule
changes, they still point here).

**Rejected alternative.** (a) Two separate slugs (a "no-rule-in-memory"
prohibition + a "re-read-at-commit" discipline) — rejected: they are one
principle (the re-read is what makes the prohibition safe), so one slug keeps
the bijection at one row. (b) Keep "process/ops rules as memories, just reduce
the count" (the pre-strengthening framing) — rejected by user direction: a
process/ops rule is still a RULE and still goes stale in an un-versioned cache;
the durable home is the in-repo SSOT. (c) A CI guard that scans the memory dir
for rule-content — impossible: the memory dir is out-of-repo + gitignored +
per-clone, invisible to CI.

---

## declare-verify-backing

**Why.** A check that RECORDS a mapping can pass while the mapping is hollow.
Verifying a necessary-but-insufficient property — the target merely EXISTS, the
gate is merely PRESENT, the token merely APPEARS — leaves the load-bearing
reality unchecked: an install row whose pack file ships but is never copied at
fresh-install; a wiring claim where the wire is unreachable; a surface↔surface
link whose matcher never BITES. The check then certifies a declaration the
runtime does not honor, which is the exact silent-drift failure the gate was
built to catch. The fix is to verify the reality the declaration ASSERTS, not a
proxy that happens to be true.

**How to apply.** Any architect or coder authoring (or extending) a
record-style check — one that mirrors a declared mapping, install row, wiring
claim, or surface↔surface link — must identify the load-bearing reality the
record asserts and verify THAT: the target ships AND is copied at install; the
wire is reachable from its caller; the matcher fires against a synthetic
violation (it BITES). Existence of the target is necessary but never
sufficient. Pair this with `ci-guard-measure-then-bound`: the guard must catch
the ABSENCE-of-backing instance (a declared mapping with NO backing), not only
the target-exists instance.

**Rejected alternative.** A generic runtime "backing exists" meta-check across
all record-style checks — rejected: there is no uniform signal for "backing
exists" across heterogeneous declarations (a copy site, a reachable wire, a
biting matcher are structurally different), so a generic check is either trivial
(re-verifying target-exists, the insufficient property) or impossibly broad.
The discipline lands as a TAGGED design-time rule the spawn-prompt assembler
selects (`enumerate-rules-inline`) and the Rules-Applied block verifies, not as
a new validator check.

---

## ci-check-runtime-compounding

**Why.** `scripts/validate-pack.py` is not run once — the CI battery and the
local verification loop invoke it many times over, so a check's true cost is its
single-run cost multiplied by that invocation count. A check that reads the
whole tree, shells a subprocess per entry, or scales with total file count
looks cheap in isolation but silently taxes every future battery run; the
compounding is invisible until the suite is slow enough to discourage running
it. Bounding per-invocation cost keeps the full suite cheap enough to run on
every commit, which is what `verify-full-ci-suite` depends on.

**How to apply.** Author each check to scale with the caller's target set, not
the repo — O(lines-touched), reading only the files in scope. Avoid a
whole-tree filesystem walk, a per-entry subprocess storm, and re-reading the
same file across checks. Draw any enumerated candidate set from git-tracked
files, and skip cleanly when the input is out of scope. Treat the cost as
per-run times the battery invocation count, and prefer an in-process,
single-pass shape over anything that fans out.

**Rejected alternative.** "Optimize later if the suite gets slow" — rejected:
the compounding is baked in at authoring time and a slow suite erodes the
run-it-every-commit discipline before anyone profiles it; cheap-per-invocation
is a design constraint, not a tuning pass.

---

## edit-in-place-not-full-rewrite

**Why.** A full-file rewrite of an operating doc or source file discards the
surrounding structure the author did not intend to touch — cross-references,
ordering, adjacent rules, formatting conventions — and makes the diff
unreviewable (every line appears changed even where nothing did). Targeted
in-place edits keep the diff proportional to the actual change, so a reviewer
can see exactly what moved, and they preserve the parts of the file that were
already correct. A rewrite also risks silently dropping content the editor
never read.

**How to apply.** Edit the specific lines or sections the task requires, using
the smallest surgical change that lands the intent. Reserve a full rewrite for
when the user explicitly asks for one. After any edit, re-read the file and
confirm the section map is intact — that no adjacent rule, heading, or
cross-reference was disturbed and the change sits where it belongs.

**Rejected alternative.** "Rewrite the whole file for consistency" as a default
— rejected: consistency is achieved by targeted edits plus a post-edit re-read,
not by regenerating content the change never needed to touch; a rewrite trades
a reviewable diff for an unreviewable one.

---

## fail-loud-delete-old-source

**Why.** When an SSOT moves, keeping the old source alive as a mirror invites
silent drift: two copies diverge and a reader cannot tell which is
authoritative. Deleting the old source instead makes every stale reference
break at once — a loud, locatable failure that gets fixed — rather than a quiet
divergence that ships. The same logic applies to a superseded doc: archiving it
leaves a plausible-looking wrong source in the tree, while deleting it forces
consumers onto the live one. Loud breakage is cheaper than quiet wrongness.

**How to apply.** On an SSOT migration, DELETE the old source outright — do not
leave a regenerated mirror behind. When a doc is superseded, remove it entirely
rather than moving it to an archive. Then fix the dangling references the
deletion exposes; each break points at a consumer that must be repointed. The
sole exception is a still-active doc that carries a single stale element:
reconcile that element in place rather than deleting the whole doc.

**Rejected alternative.** Keep the old artifact "for reference" or as a
read-only mirror — rejected: a second copy is a second source of truth in
practice, and it drifts; the value of deletion is precisely the loud break that
a mirror suppresses.

---

## design-discipline-challenge

**Why.** A structural pattern that fits one use-case is not automatically right
for another: adopting it by resemblance rather than by verified property-fit
imports assumptions that may not hold, and the mismatch surfaces later as
rework. Likewise, an early triage verdict is a first read, not a ruling — it was
reached before the design was worked through. Treating both as provisional, and
having the architect actively challenge them at design time, catches the wrong
pattern and the wrong triage before they harden into a plan.

**How to apply.** Before adopting a pattern for a new use-case, verify it is a
deliberate, evidence-based choice whose properties actually fit the goal and
respect the boundaries — never a match on surface resemblance. Treat every
triage decision as PRELIMINARY and challenge each during design on a tiered
bar: an internal, easily-reversible choice gets a LOW bar; a pack-boundary or
client-facing choice gets a HIGH bar; a user-goals choice gets a HIGH bar but
remains open to a reasoned challenge. Record the challenge and its outcome.

**Rejected alternative.** Accept the preliminary triage as settled to save a
design pass — rejected: the triage was formed with less information than the
design has, so skipping the challenge locks in an under-informed call; the
challenge is where cheap redirection happens.

---

## verify-availability-not-existence

**Why.** A capability existing somewhere is not the same as it being usable on
the target the design will actually run against. An API, plan feature, or tool
can exist in general yet be unavailable on this account tier, this plan, this
GA-vs-preview state, or this installed variant — so a design that assumes "it
exists, therefore we can use it" fails at runtime on the real target. Checking
usability on the concrete target closes the gap between "documented" and
"works here."

**How to apply.** When a design leans on an external capability, verify it is
USABLE on the actual target — the specific account type, plan, GA-vs-preview
status, and installed variant that will run it — not merely that the capability
exists in the abstract. Capture the availability check as evidence (the command
run and its result), so the reviewer can confirm the dependency is real on the
target rather than assumed.

**Rejected alternative.** Treat vendor docs listing a feature as proof it is
usable — rejected: documentation describes the general capability, not this
target's entitlement; only a check against the real account/plan/variant proves
availability.

---

## verify-full-ci-suite

**Why.** `scripts/validate-pack.py` is one job among the wired checks; passing
it alone does not prove the change is green, because integration tests and the
deep-mode pass exercise behavior the standard validator does not. A commit
verified on the narrow check can still break a wired test that only runs in the
full battery, so the narrow pass gives false confidence. Running the complete
suite is the only measurement that matches what CI will actually assert.

**How to apply.** For per-commit verification — coder and reviewer alike — run
every wired test in the validate workflow across both jobs, plus
`PACK_VALIDATE_DEEP=1`, not `scripts/validate-pack.py` in isolation. Treat the
integration tests as part of the encoding-surface set (`enumerate-encoding-
surfaces`): a change to a surface they cover is not verified until they run
green. Confirm the full battery is green before declaring the work done.

**Rejected alternative.** Run only `scripts/validate-pack.py` for speed and let
CI catch the rest — rejected: deferring the full battery to CI moves the failure past the
cheap local window and breaks the run-it-every-commit contract; the suite is
kept cheap (`ci-check-runtime-compounding`) precisely so it can run every time.

---

## pack-entry-type-semantics

**Why.** The pack's entry types form a fixed component hierarchy, and treating
that shape as flexible produces malformed entries that downstream tooling and
readers cannot interpret. A phase is not a container for parts at creation; a
part exists only as an evolution of an existing entry; a task is a component of
a phase; a grouping holds phases. Encoding these relationships as a stable rule
keeps every entry well-formed and keeps deliverable-emitting scripts and
validators reasoning about one consistent structure.

**How to apply.** When creating or reasoning about pack entry types, honor the
fixed hierarchy: never create a phase already carrying parts (parts arise only
by evolution); treat tasks as components of a phase; let groupings contain
phases only. Preserve the component hierarchy as given rather than inventing a
new nesting. This is a definitional rule for constructing project-side
deliverables, not a pack self-management concept.

**Rejected alternative.** Allow ad-hoc nesting (a phase authored with parts, a
grouping holding tasks) when convenient — rejected: the hierarchy is what makes
entries machine-interpretable and cross-referenceable, so a convenience
exception breaks the tooling that assumes the fixed shape.

---

## public-bound-no-leak

**Why.** The pack is going public, so its client/public surfaces —
`project-template/`, `supporting-docs/`, `.github/`, the repo-root `README.md`,
and the pack-root trinity — must never carry the target project's product name
or its domain-specific vocabulary. A single re-introduced token would leak the
sponsoring application into a shipped or published artifact. The one-time scrub
removed every such token from those surfaces; this rule is the standing
discipline that keeps them clean, and validate-pack Check 93
(`scripts/lib/validate_checks/no_leak.py`) is its enforcement backstop — leg 1
bans the literal product name in ANY git-tracked file (tree-wide), leg 2 bans
the domain vocabulary on the client/public subset. Internal dev-history surfaces
(`backlog/`, `changelog/`, `maintenance-docs/`, `test-fixtures/`) are out of
leg-2 scope: they keep their internal shorthand and fixture-name keeps per the
two-tier keep-list. Those keeps are PERMANENT — this repo is the single work
repo and goes public with its history intact, so there is no separate scrubbed
copy and the internal-surface exemption is a settled decision, not pending
cleanup; do not re-open it.

**How to apply.** Before adding text to any client/public surface, keep the
target project's name and its domain-specific vocabulary out of it entirely;
refer to them only abstractly ("the target project", "the domain vocabulary").
The literal token set is authored ONCE — in the Check 93 module's config —
and lives NOWHERE else in shipped prose. This rule and its corpus
imperative are THEMSELVES worded abstractly, because the trinity `## Pack memory`
sections are leg-2 surfaces (and every tracked file is a leg-1 surface): writing
a literal token here to "illustrate" the rule would itself be the leak the rule
forbids. If Check 93 flags a surface, remove the offending token — never widen
the check's allowlist to admit it (the leg-1 allowlist is empty; the leg-2
allowlist is sized to exactly one legitimate row-name keep).

**Rejected alternative.** Enumerate the banned token set inline in the rule text
so actors can see exactly what to avoid — rejected: the rule text ships on
leg-2-scanned public surfaces, so listing the literals would re-introduce the
very leak Check 93 exists to prevent, making the corpus its own counter-example.
The single source of truth for the token set is the check's config; the prose
points at it abstractly.
