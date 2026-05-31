# PACK-MEMORY-RATIONALE.md — rationale bodies for tagged Pack memory rules

**What this file is.** This is the read-on-demand rationale companion to the
`## Pack memory` rule corpus in the pack-root trinity (`CLAUDE.md` /
`AGENTS.md` / `GEMINI.md`). Each tagged rule in that corpus carries a thin
imperative line plus a `[rationale: <slug>]` pointer; the matching `## <slug>`
section below holds that rule's Why + How-to-apply-worked-example +
rejected-alternatives — moved out of the corpus so the corpus stays
application-grade and concise.

**Pack-only.** This file lives under `pack-ops/`. It is NOT a trinity file and
NOT installed to client projects by `scripts/init-project.sh`. It governs
pack-self-management only.

**Read-on-demand.** Agents do NOT load this file into every prompt. Pack Chat
does NOT paste rationale into spawn prompts — only the imperative lines plus
their slugs. An agent reads a `## <slug>` section here only when it hits an
ambiguous Rules-Applied row and follows the rule's `[rationale: <slug>]`
pointer.

**Never source-of-truth for the imperative.** The corpus imperative line is
authoritative for WHAT the rule requires. This file explains WHY and HOW; if
this file and the corpus imperative ever disagree, the corpus imperative wins.
The slug-set here is held in 1:1 bijection with the corpus `[rationale: slug]`
set (Check 45, wired in commit C3).

---

## agents-never-commit

Read-only git verbs (`status`, `diff`, `log`, `rev-parse`, `show`) are
allowed. Only Pack Chat may stage and commit, and only with explicit user
approval. The agent's output is its report file plus working-tree edits; Pack
Chat reads the report, verifies, then commits.

---

## per-action-approval-sub-agents

The "no state-changing operations without explicit per-action approval" rule
applies to Claude Code Pack Chat AND every sub-agent it spawns. State-changing
git verbs are forbidden to all agents per `PACK-AGENTS.md` § "Agent permission
rules"; destructive file operations (`rm -rf`, `git rm`, overwriting trusted
files) require Pack Chat to ask the user even when the overall task is
approved. Sub-agents inherit this rule by construction (they write only their
report + scoped working-tree files; they cannot commit). See
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
AUTHORITY signals — re-scope to land in v11.0 and surface the blast-radius to
the user. Only the user authorizes v11.1+ deferral; this default inverts only
on explicit user direction ("this is v11.1 work" / "defer this" / "don't block
v11.0 on this").

---

## deferral-is-scope-creep

Punted items lose context, multiply, require archaeology in future sessions.
Defending deferral rigorously requires (a) SIZE (architect-pass material; real
file/contract surface argument, not "felt big"), (b) BLOCKED (real dependency
on not-yet-landed artifact, not "feels related"), or (c) LOGICAL FIT (cleanly
belongs with another sibling BD/commit; concrete same-file/same-contract fit,
not "thematic"). When a new BD is created that is LARGE and UNBLOCKED, insert
it IMMEDIATELY AFTER the current BD or batch — do not park at end of v11.0, do
not park in a "next batch" with no anchor. When BLOCKED, insert at the exact
unblock point. Per OQ-1 (rewritten EXECUTION-PLAN §B), any new-BD-open
additionally requires user-discussion-and-approval.

---

## boundary-investigation-precedes-pack-defaults

Project and pack are intentionally designed differently. When making ANY
change to a project-side file (`project-template/` trees, project-shipped
content), an actor (reviewer, implementer, Pack Chat triage) MUST first
investigate whether a project-side SSOT exists for the concept being changed.
Pack-style mechanisms (`pack-ops/PACK-AGENTS.md` roster, Pack Chat orchestrator
role, pack-* agent names, `maintenance-docs/` design records, anything under
`pack-ops/`) are PACK-ONLY by construction — they do not exist at client
install, they do not govern project behavior, and importing them into
project-side files is a regression that breaks at client install or pollutes
project-design intent. The default instinct "reach for the pack mechanism I
know" is bias, not a starting point. Investigate the project-side SSOT FIRST.
Worked examples of the failure mode this rule prevents: BD-175 audit V1
(project trinity acquired `PACK-AGENTS.md` reference via a review-fix commit
when the project-side SSOT was `docs/pack/PM-CHAT.md`), V3 (project-side
`project-template/docs/pack/PLATFORM-SKILLS.md` acquired `PACK-AGENTS.md`
reference instead of pointing at `project-template/docs/pack/PM-CHAT.md`), V4
(project-side methodology doc became pack-internal by drift).
See the `boundary-investigation` skill (loaded by all pack agents) for the
SSOT-investigation methodology.

---

## preflight-stop-means-stop

Every pack-coder agent prompt MUST include both halves of this pattern:

- **PREFLIGHT (platform-neutral, REQUIRED for all CLIs).** After completing all
  in-scope file edits + verification, BEFORE writing the IMPL-REPORT, the coder
  emits ONE plain-text line: `PREFLIGHT: N/N in-scope file edits complete;
  verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`. Then it
  writes the IMPL-REPORT. Pack Chat treats this line as the trust signal that
  the report-write is starting from a complete-and-green state. If the coder
  cannot complete the preflight (some edit failed, some test failed), it
  reports what went wrong instead and does NOT write a partial IMPL-REPORT.

  Verification includes BOTH the in-scope test suite for the BD AND Check 43
  (V11 leak-sweep prevention; pack/project boundary scanner). When a pack-coder
  commit touches any file under project-template/, pack-ops/, supporting-docs/,
  or scripts/, the coder MUST run `python3 scripts/validate-pack.py` against the
  working tree before writing the PREFLIGHT line; Check 43 (and the rest of the
  validate-pack suite) MUST PASS. If Check 43 FAILs, the coder reports the
  failure (with file:line + matched basename + suggested remediation) INSTEAD
  OF writing the IMPL-REPORT — Pack Chat reviews and decides whether to fix in
  this commit or escalate.

  **Per-check test runs.** When the commit modifies any of:
  `scripts/validate-pack.py` (any function/check), `scripts/init-project.sh`
  `_CLIENT_INSTALLED_FILES_START/_END` inventory, `scripts/lib/` files
  referenced by validate-pack checks, or any file in the `_CHECK_*_ALLOWLIST`
  referenced surfaces — the coder MUST run all relevant per-check test files at
  `scripts/tests/test-validate-pack-check-*.sh` before writing the PREFLIGHT
  line. ALL tests MUST PASS. If any test FAILs, the coder reports the failure
  (file:line + test name + diagnostic) and does NOT write the IMPL-REPORT.
  "Relevant" = (a) the test file matching the check ID being modified, AND (b)
  any test file that exercises the same `_iter_*` helper or shared logic
  surface; when in doubt, run ALL per-check test files (cost: ~5-15s total).
  Worked example: BD-193 + BD-194 incident — BD-193 commit `85196d4` removed
  `pack-ops/HELP-FRAGMENT-TRACKER.md` from the inventory but didn't update
  `scripts/tests/test-validate-pack-check-43.sh` G2.T3 or
  `scripts/tests/test-validate-pack-checks-36-37-38.sh` G7.T3 expected_extras;
  both BD-193 and BD-194 PREFLIGHTs passed because `scripts/validate-pack.py`
  itself ran clean, but the
  per-check tests would have FAILed on push. Caught at BD-194 reviewer pass;
  resolved in `6c76582`.

- **STOP-MEANS-STOP preamble (CLAUDE-CODE-SPECIFIC ENFORCEMENT, REQUIRED for
  all CLIs as content).** The coder prompt opens with an explicit instruction:
  "If you receive a parent-session message containing the words stop / halt /
  revert / do not continue, you MUST immediately stop ALL work, including any
  in-progress Write. Partial files are acceptable; do not append to make
  consistent. Stop authority is absolute and unconditional." This text is
  platform-neutral; the in-band ENFORCEMENT mechanism is platform-conditional:
  - Claude Code: SendMessage tool (Agent Teams,
    `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`); SECURITY WARNING classifier flags
    subagent defiance at handoff. This is the enforced path the BD-169 incident
    exposed (see worked example in `feedback-pack-coder-preflight-pattern`
    memory pointer).
  - Codex CLI: No SendMessage equivalent (confirmed absent per issue #12462).
    Parent stop mechanism is `/agent` command or natural-language ("ask Codex to
    stop the subagent"). Reliability caveats per research §2.6.
  - Gemini CLI: No SendMessage equivalent (hub-and-spoke per docs). Parent stop
    mechanism is natural-language or `Ctrl+C` (terminates whole session per
    issue #3385). Reliability caveats per research §3.6.

Worked-example anchor: `feedback-pack-coder-preflight-pattern` memory pointer;
original incident BD-169 19g-pack, 2026-05-16.

---

## rules-applied-verification-block

**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery. Without this
block, agents cite rules they've followed but skip rules they didn't verify.
Verification evidence is the only mechanism that distinguishes "rule cited"
from "rule applied." Failure mode in BD-195 AC1 §6.2: architect cited prison
rule, manifest-regen rule, trinity rule — sound. But no verification evidence
for the empirical claim "the seed-corrected tree has NO `v11.1`-string
occurrences outside the allowlist." The claim was rule-shaped (a state-claim)
but had no verification block. The coder later proved it false (1213 hits in
114 files). Required Rules-Applied Verification Block with grep output would
have failed the claim at design time, not coder time.

**How to apply:** Format: per-rule table `Rule | Verification evidence |
Conclusion`. Pack Chat verifies the block exists, every row has non-empty
evidence, every VIOLATED row gets surfaced to the user BEFORE any downstream
work (planner spawn / coder spawn / commit). Empty entries = treated as
VIOLATED. N/A rows require explicit justification.

---

## empirical-evidence-blocks

**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery. BD-195 AC1 §6.2
claimed "after F-AC1-04 strips the v11.1 strings from validate-pack.py +
test-issue-forms.sh, and F-AC1-02 retires templates-archive/v11.1/, the working
tree has NO `v11.1`-string occurrences outside the allowlist." State-claim. No
grep run. No count captured. The claim was empirically wrong by three orders of
magnitude (1213 hits in 114 files). The architect could have grepped at design
time — they had the regex (they wrote it as part of Check 44's pattern).
Nothing required them to verify.

**How to apply:** Every architect or planner prompt requires (a) enumeration of
the state-claims the design makes (in advance) and (b) instruction that the
design output includes an Empirical-Evidence Block per state-claim. Pack Chat
scans every architect / planner output for state-claims; any without a
corresponding Empirical-Evidence Block entry is surfaced as a design defect
(route back to architect/planner; do not advance to planner / coder).

---

## ci-guard-measure-then-bound

**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery. BD-195 AC1 §6.2
designed Check 44 with an allowlist of 2 architect docs + 7 anchor phrases. The
architect assumed (without measurement) that C1-C6 fix-recipes would leave only
the allowlist-covered occurrences in the tree. The actual measurement at HEAD
`b547524a` (after C1-C6 landed) revealed 1213 occurrences across 114 files. The
allowlist was undersized; the fix-recipes were under-scoped to match the actual
contamination. The Pack Chat triage temptation was to "widen the allowlist" to
make the guard pass — which would have defeated Check 44's purpose (catching
contamination LIKE the BD-193 propagation it was designed to prevent). The
right fix was to redo the design with the actual measurement in hand.

**How to apply:** Any architect spawn that includes a CI-guard / validator /
allowlist deliverable: the prompt requires the architect to execute (a)
measurement-first phase (grep/walk the tree, produce occurrence list), (b)
categorization (per-occurrence KEEP/STRIP), (c) fix-recipe design for every
STRIP, (d) allowlist sized to KEEP only, (e) projected post-fix verification.
The design output includes the measurement evidence + per-occurrence
categorization + the projected-clean verification. Pack Chat does NOT advance
the design to planner if any of these steps are skipped.

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
operationally (pack-ops uses BDs in `BACKLOG.md` and batch labels in
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`); pack-root
configs (`.claude/`, `.codex/`,
`.gemini/` at pack-root) using project-side concepts for pack-self-management.

**The test:** "Is this pack-side surface being used to CONSTRUCT a project-side
deliverable, or is it part of pack-self-management?" If the surface IS the
deliverable's source-of-truth (templates, scripts that emit, validators that
check), project-side references are allowed. If the surface is
pack-self-management, project-side references are forbidden.

**Why:** User-locked 2026-05-27 during BD-185 reconciliation. The rule was
implicit in `feedback_pack_project_separation_of_concerns` +
`feedback_bd_pack_only_operational_rule` but not explicit. BD-193 applied the
asymmetric counterpart (removed BD from project-side forms) but did not
symmetrically clean up TD/phase from pack-side self-management surfaces. Worked
example: pack-root `.github/ISSUE_TEMPLATE/work-item.yml` admits `td`,
`phase-epic-skeleton`, `phase-task-skeleton` — these are stale pre-BD-193
inheritance and should be removed.

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

**Why:** User-locked 2026-05-27 post-BD-185-reconciliation pack-side re-audit
(methodology gap MF1). The original BD-185 reconciliation pack-side audit
walked the form file (F1) + the validator's per-surface dict (F2) but missed
`scripts/tests/test-issue-forms.sh` Group 2 + Group 5 assertions (F3'). The
test's hardcoded pack-root assertions encoded the pre-cleanup state and
required lock-step update with F1 + F2. Caught post-fact by the PREFLIGHT
per-check-test-runs gate (`ba9e09d`), NOT by the audit itself. The methodology
gap was treating `scripts/tests/*` as "constructor context" wholesale when the
correct granularity is per-assertion (constructor portions assert project-side
emission; self-management portions assert pack-side state). The `review` skill
at `.claude/skills/review/SKILL.md` + trinity mirrors carries the operational
checklist.

---

## skill-agent-maintenance-mechanical

Maintenance is mechanical, complete, reviewed, and rule-strict. Structural
change — including rule changes — requires architect-then-planner, never
convenience. Mechanical changes preserve client `x-` skills/agents conforming
to existing dimensions; breaking the `x-` contract escalates to structural and
requires architect-pass migrator coverage. Workflow artifacts
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
"project-template `CLAUDE.md`"). Cross-reference forms that STRIP the unique
filename also violate this rule's intent even when they avoid the literal `.md`
extension — bare-version shorthand like `V3.3 §3.X` as a reference to
`maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` sections is a leak
under the rule's spirit because the reader has no filename to follow, no path to
resolve, and the version shorthand is ambiguous (a `V3.3` reference could mean
any v3.3-versioned doc). Audit vocabulary scans that look
only for `*.md` patterns will MISS these; reviewers should treat bare-version
shorthand for pack-internal docs as the same leak class as explicit `*.md`
cites. Worked examples: BD-135 renamed the colliding `tracker.toml.example`
pair; BD-173 Batch 19c.H.9 NIT-1 fix expanded from L1207 doc-cite to 11
bare-V3.3 refs in `supporting-docs/METHODOLOGY.md` (audit-vocabulary-gap
pattern).

---

## architect-doc-reality-reconciliation

Worked example: BD-119 §9.2 addendum in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` names BD-160 as the
first realized consumer; the consumer carries the matching docstring; the
BD-160 IMPL-REPORT links both. This pattern is load-bearing for any future
shipped surface that pre-existed in an architect doc.

---

## regenerate-manifest-v11-surface

The trigger is intentionally inclusive — false positives (e.g., a
`scripts/test-*.sh` edit that doesn't actually affect fixtures, or a
`supporting-docs/MIGRATION-v10-to-v11.md` edit which is a pre-install reference
not copied to clients) cost ~30-90s of unnecessary rebuild but produce no
incorrect manifest change; false negatives within v11-surface are impossible
because every fixture-affecting file lives under one of these four directories.
Fixture-affecting paths today: all of `project-template/**` and `scripts/**`
(mass-copied by `scripts/init-project.sh` stages S1-S11);
`pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh` stage S11 copies
to client `docs/pack/`); `supporting-docs/METHODOLOGY.md` and
`supporting-docs/INSTALL-PROCEDURES.md` (`scripts/init-project.sh` stage S6
copies to client `docs/pack/`). Other files under `pack-ops/` and
`supporting-docs/` are not fixture-affecting today, but the directory-wide
trigger defends against future copy-site additions to `scripts/init-project.sh` or new
fixture-build readers. v11-* fixture row SHAs drift naturally with any
v11-surface change (per `test-fixtures/README.md` § Determinism and the
`_update_manifest` comment at `test-fixtures/build.sh:903-912`); a stale
manifest fails CI's `fixture manifest verify` step (BD-115, RELEASE-GATE item 5)
even when every functional test passes. **Why:** two incidents drove this rule:
(1) the 2026-05-17 incident where commit `667d2dd` shipped v11-surface
`project-template/` trinity edits without regenerating the manifest, CI failed
on the manifest-comparison step alone (all 40+ functional steps PASSED), and
recovery commit `ef9e5c7` had to land as a separate `fix:` commit; the drift was
the cumulative effect of three intentional v11-surface commits (`cf67a96`
BD-169 pack-product wording, `62f9eec` BD-169 review/fix, `479fef5` Batch 19
broad review/fix) since the last manifest regen at `a57dd04` (BD-160); (2) the
2026-05-19 incident where BD-175 Phase 5 Commit 8 `4120d19` modified
`supporting-docs/METHODOLOGY.md` (a client-installed file) without regenerating
the manifest under the prior strict trigger (which excluded `supporting-docs/`),
CI failed identically, and recovery commit `6c48f88` had to land as a separate
`fix:` commit. BD-176 expanded the trigger from 2 directories to 4 to close both
classes of false negative (pack-ops/ defensively; supporting-docs/
empirically). **How to apply:** before staging a commit whose diff includes any
file under `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`,
run `bash test-fixtures/build.sh --all --clean` from the pack root. Then check
`git diff test-fixtures/manifest.txt`: if non-empty, `git add
test-fixtures/manifest.txt` and stage it alongside the scope edits in the same
commit; if empty, your edit wasn't v11-surface (no staging needed). The manifest
diff after rebuild is the canonical authority — the trigger globs are a screen
for WHEN to run the rebuild. `--all --clean` is the canonical default (rebuilds
all six fixtures deterministically; v10-* rows are tag-pinned and only drift if
the v10 tag moves). Actors confident about which v11-* fixture is affected may
substitute `--name <fixture> --clean` per affected fixture, then `bash
test-fixtures/build.sh --verify` to confirm the remaining rows are unchanged
before staging. Cross-reference: the "Test infra is self-provisioned" bullet
above governs *test provisioning*; this bullet governs *manifest maintenance*
and is load-bearing for the `fixture manifest verify` CI gate (BD-115,
RELEASE-GATE item 5).

---

## cross-cli-reference-normalization

Per Override 9, byte-identical cross-trinity adoption of CLI-specific paths is
WRONG even when it visually closes drift — body-text drift and cross-CLI
references are different classes (see
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` §1 table). Worked
example: BD-178 SHOULD-1 byte-identically aligned `GEMINI.md`'s
`.claude/settings.json` reference (correct for CLAUDE form, wrong for
Gemini-audience); BD-182 corrected to `.gemini/.env` per §4.1.
