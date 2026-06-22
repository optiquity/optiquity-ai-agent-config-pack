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
The agent's on-return deliverable is its report file plus its worktree
edits (held in the commit's isolated worktree). The `git diff` patch is NOT
emitted up front — it is the POST-review-clean artifact: only after a read-only
reviewer confirms the work clean does Pack Chat re-engage the most-recent
read-write agent (SendMessage) to produce the patch into the named `/tmp`
handoff dir, then read the report, apply that reviewed-clean patch, and commit.

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
are forbidden to all agents per `PACK-AGENTS.md` § "Agent permission rules";
destructive file operations (`rm -rf`, `git rm`, overwriting trusted files)
require Pack Chat to ask the user even when the overall task is approved.
Sub-agents inherit this by construction (they write only their report + scoped
working-tree files; they cannot commit). See
`feedback-no-destructive-without-approval` for the memory-cache pointer.

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
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`); pack-root
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
script defaults to `project-template/scripts/`. But a file a PACK OPERATION
depends on at runtime cannot live project-side without making a project
deliverable a dependency of a pack op — forbidden. Worked example:
`scripts/lib/detect.sh` is `source`d by `init-project.sh:79` /
`scripts/add-capability.sh` / the migrator (all pack operations), so it stays
pack-side even though it ships (it is the dependency of the shipped
`scripts/pack-help.sh`);
promoting it to `project-template/scripts/lib/` was considered and RETRACTED for
that inversion (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md`
§8.0). The pack-side-ship exception is frozen to `_SANCTIONED_PACK_SIDE_SHIPPED`;
CI Check 47 holds the install-map's pack-side subset == that constant, so the
lazy "ship from `scripts/` too" path fails by default — growth is a
deliberate, sign-off-gated constant edit, never a stray map add.

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
