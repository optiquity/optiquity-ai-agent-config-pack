# PLAN-BD-195-EXECUTION — Code Red 3 master execution plan (Steps 1–9)

**BD:** BD-195 (Code Red 3) — v11.0 pristine-state recovery before the BD-185
restart (full-repo).
**Pass:** BD-195 master orchestration plan. Builds ON the approved Step-0
investigation-approach plan; does NOT redo segmentation.
**Author:** pack-planner (read-only orchestration pass).
**HEAD at authoring:** `e580dda7eb46c640a92afabd3469bbada17d1975`.
**Status:** DRAFT — goes to the user for review before Step 1 (the first
post-plan pass) runs.

---

## 0. What this document is — and is NOT

This is the **master execution plan** for ALL of BD-195: every step (1–9),
every agent pass, the review/fix cadence, every user gate, and the
verification/commit obligations — from creating + populating the prison
directory through the final audit and the Step-9 BD-185 decision.

It is **NOT** the investigation-approach plan. That plan
(`maintenance-docs/v11-implementation/PLAN-BD-195-INVESTIGATION.md`) is the
approved Step-0 deliverable; it defines the researcher/architect segmentation
(R1–R9 / A1–A9), the shared output-shape and surfacing standard, the
reconciliation passes, and the quality gates (QG-1…QG-8). This master plan
**uses that plan as the design for Steps 3–5** and orchestrates the complete
BD-195 sequence around it. Where the two could drift, §11 reconciles them.

This plan **plans the orchestration only.** It does NOT investigate the repo,
design fixes, extract retained decisions, or decide prison membership — every
one of those is produced by a later, user-gated step. No findings, no fix
designs, no prison-membership decisions appear here.

### Source inputs (read in full before executing this plan)

- **BD-195 entry in `pack-ops/BACKLOG.md`** (the directive; begins
  `**BD-195 (Code Red 3) — …**`). Steps 0–9, the Step-2 PRISON DISPOSITION
  RULE, the Surfacing standard, and the Quality bar are load-bearing.
- **`maintenance-docs/v11-implementation/PLAN-BD-195-INVESTIGATION.md`** (the
  approved investigation-approach plan; the design for Steps 3–5).
- **`CLAUDE.md` § "Pack memory"** — the process + boundary rules this plan
  honors at every step (see §2).

---

## 1. Goal and BD items addressed

**Goal.** Execute BD-195 end-to-end: recover v11.0 to a pristine
post-Batch-19c state, superseding the entire prior BD-185 attempt with new
docs while retaining the user's preapproved good decisions, FORWARD-FIX
BIASED TOWARD COMPLETE REDO — prior committed work is not anchored on or
salvaged unless a fix pass independently proves it correct.

**BD items addressed.** BD-195 (Code Red 3), Steps 1–9. (Step 0 — the
investigation-approach plan — is already complete.) BD-185 is referenced only
as the paused, in-scope-for-supersession item whose attempt BD-195 recovers;
this plan produces no BD-185 work. BD-193 / BD-194 (Code Red 2) are NOT
special-cased — they are in scope like everything else (directive Scope line).

**Success criteria for THIS plan.**
- Every BD-195 Step (1–9) has a concrete, sequenced execution definition
  (agent / inputs / outputs / user gate / verification).
- The review/fix cadence (Step 7) is explicitly defined and justified against
  CLAUDE.md's per-BD/per-commit-inline + once-per-batch-end rules.
- The prison disposition rule is propagated to every pass; a prisoned doc's
  status is unambiguous at every step.
- The investigation-approach plan is reconciled (every needed refinement,
  incl. §2.6, flagged) so the two plans are consistent.
- A reader can execute BD-195 end-to-end from this plan + the
  investigation-approach plan, with no gaps.

---

## 2. Standing process rules that bind EVERY step

These CLAUDE.md § "Pack memory" rules are constraints on every step below.
They are stated once here and referenced (not re-derived) per step.

- **Agents never commit.** No agent (incl. `pack-coder`) runs any
  state-changing git verb. Read-only git verbs only. The agent's deliverable
  is its report/output file plus working-tree edits. Pack Chat reads the
  report, verifies, then stages + commits with explicit user approval.
- **No destructive or state-changing op without explicit per-action
  approval.** `rm`/`git rm`/`mv`/overwrite of trusted files require Pack Chat
  to ask the user even inside an approved task. The Step-2 prison MOVE is the
  marquee instance — it is user-gated (§4).
- **Pack Chat does NO fixes; Pack Chat does not architect.** Architecture,
  planning, implementation, review, research → the matching `pack-*` agent.
  Pack Chat handles BACKLOG/CHANGELOG entries, routing, triage, approvals,
  commits, and the PM-only direct edits enumerated in CLAUDE.md.
- **Planner output → user review → coder spawn.** Every planner output
  (this plan; the Step-6 fix plan) is surfaced to the user for review and
  waits for explicit approval before the next stage spawns. No auto-approve.
- **Pack-architect spawn protocol.** Spawning an architect is NOT a
  Pack-Chat-direct decision — it requires explicit user approval (because it
  commits Pack Chat to a multi-stage pipeline). The Step-5 architect spawns
  and any architect-spawn that a fix's boundary/rule nature forces (§7) are
  gated on user approval.
- **Triage gate + commit gate.** After every reviewer pass: Pack Chat reads
  the report, triages every finding (default FIX-ALL; SKIP needs rationale +
  OQ-1 user-discussion-and-approval), surfaces the triage to the user, THEN
  spawns the fix-coder. The user approves the resulting fix commit (not
  per-finding). Two distinct gates: triage gate (reviewer→fix-coder) and
  commit gate (fix-coder IMPL-REPORT→`git commit`).
- **PREFLIGHT + STOP-MEANS-STOP per coder.** Every `pack-coder` prompt opens
  with the STOP-MEANS-STOP preamble and requires the PREFLIGHT line before the
  IMPL-REPORT write. When a coder commit touches any file under
  `project-template/`, `pack-ops/`, `supporting-docs/`, or `scripts/`, the
  coder runs `python3 scripts/validate-pack.py` (Check 43 + the full suite
  MUST PASS) before the PREFLIGHT line; per-check test files at
  `scripts/tests/test-validate-pack-check-*.sh` run when the commit modifies
  `validate-pack.py`, the `init-project.sh` inventory, `scripts/lib/` files
  referenced by checks, or allowlisted surfaces.
- **Manifest regen on v11-surface commits.** Any commit whose diff includes a
  file under `project-template/`, `scripts/`, `pack-ops/`, or
  `supporting-docs/` regenerates `test-fixtures/manifest.txt`
  (`bash test-fixtures/build.sh --all --clean`) and stages it in the SAME
  commit if the diff is non-empty.
- **Scope-keyword / CI Check 36.** A commit subject carries `pack-only` /
  `project-only` / `PM-only` ONLY when its diff is exclusive to that surface;
  CI Check 36 verifies the claim. BD-195 is "pack-only operational" by Type
  — but Step 7 fix commits that touch `project-template/` or
  `supporting-docs/` are CLIENT-SHIPPED-SURFACE edits and may NOT carry
  `pack-only`. Use the audience-correct keyword or neutral framing per commit
  (see §7, §10).
- **Sub-agent spawn defaults (Claude).** Spawn every sub-agent with
  `run_in_background: true` and NO `isolation: "worktree"` (worktree isolation
  is broken from a non-main clone — it checks out `origin/main`). Per-stage
  fresh instances; each `pack-coder` commit gets a FRESH coder.
- **Fresh-coder-per-commit.** Never reuse a coder across commits. Per-BD/
  per-segment review/fix = fresh coder for the implementation, fresh coder for
  the fix.
- **Boundary discipline (P-missed-7).** Any change to a project-side surface
  investigates the project-side SSOT FIRST; pack mechanisms are pack-only by
  construction. This is a design constraint on every architect/coder pass that
  touches `project-template/`.

---

## 3. THE PRISON DISPOSITION RULE — verbatim, propagated to every pass

The BD-195 directive Step 2 defines the rule. It MUST be stated **identically**
in every step below and in **every agent prompt** in the BD-195 sequence
(Step-1 extractor, Step-2 mover-aide, R1–R9, the researcher reconciler, A1–A9,
the architect reconciler, the Step-6 fix-planner, every Step-7 coder, every
Step-7 reviewer/fix-coder, every Step-8 auditor). The verbatim text:

> **PRISON DISPOSITION RULE.** A dedicated "prison" directory (distinct from
> `maintenance-docs/archive/`) holds every superseded doc — INCLUDING
> superseded docs that were already in `maintenance-docs/archive/` (archived
> AND superseded = doubly useless → prison). `maintenance-docs/archive/`
> retains ONLY non-superseded historical records. Presence in the prison =
> superseded/contaminated = IGNORED at every step; status is unambiguous
> without opening the file. No agent ever audits, edits, trusts, or treats as
> authoritative any doc inside the prison directory — its sole status is
> "superseded, ignore."

**Propagation mechanism (Pack Chat obligation).** Pack Chat pastes this exact
block into the top-matter of every BD-195 agent prompt, immediately after the
STOP-MEANS-STOP preamble (for coders) or the read-only directive (for
researchers/architects/auditors/planners). Every prompt additionally states
the **then-current prison directory path** (unknown until Step 2 completes;
"the prison does not yet exist" for the Step-1 extractor and the Step-2
mover-aide pre-read) so the agent's exclusion set is concrete.

**A prisoned doc's status at every step (unambiguous by construction):**

| Step | Prison state | A prisoned doc is… |
|---|---|---|
| 1 (Retained-Decisions) | Prison not yet created | n/a — Step 1 reads the contaminated sources IN PLACE to extract decisions BEFORE they are prisoned. |
| 2 (Prison move) | Prison created + populated | The move target. After the move: IGNORED. |
| 3+4 (Researchers) | Prison exists | Out of scope. Not in any segment's owned-path manifest. The QG-5 coverage audit subtracts prison paths. |
| Researcher reconciliation | Prison exists | Not ingested. A finding that references a prisoned doc as authoritative is a defect. |
| 5 (Architects) | Prison exists | Out of scope. Never a fix target. A fix may RE-POINT an in-scope reference AWAY from a prisoned doc (stale-ref), never INTO one. |
| Architect reconciliation | Prison exists | Not a blast-radius target. |
| 6 (Fix-planner) | Prison exists | Never sequenced into a commit. |
| 7 (Implementation) | Prison exists | Never edited. A coder that touches a prisoned path is a STOP-MEANS-STOP violation. |
| 8 (Audits) | Prison exists | Out of audit scope. The audit may VERIFY that no in-scope surface references a prisoned doc. |
| 9 (BD-185 decision) | Prison exists | Informs the "complete redo" bias — the prisoned BD-185 attempt is the superseded baseline. |


---

## 4. MASTER SEQUENCE (Steps 1–9) — the end-to-end order with gates

Each arrow is a checkpoint; `══USER══` marks a user gate (review / confirm /
approve / decide). Steps 3–5 expand the investigation-approach plan §4 order.

```
[Step 0 done] Investigation-approach plan approved
        │
        ▼
Step 1  Retained-Decisions extraction (one of THREE parallel
        pre-prison read-only passes; NO inter-dependency)
        pack-docs-researcher (or pack-architect) reads contaminated
        sources IN PLACE → AUDIT-BD-195-RETAINED-DECISIONS.md
        ══USER══ confirms the retained set
        │  (commit: PM-discussed; doc is a workflow artifact)
        │
        │  (the other two parallel pre-prison read-only passes:)
        ├─ Step 1b Supersession-mapping pass (WHOLE-REPO; dedicated agent)
        │     pack-docs-researcher reads INSIDE every doc + reads git log
        │     → AUDIT-BD-195-SUPERSEDED-MAP.md  (FACTUAL superseded→
        │        superseding mapping + evidence; NO opinion on purpose/why)
        ├─ R7 scoped pre-read (epicenter; pack-docs-researcher)
        │     → AUDIT-BD-195-R7-PREREAD.md  (retained-decision LEADS that
        │        enrich Step 1 + epicenter CONTEXT that enriches the
        │        supersession map; does NOT block Step 1 — Step 1 reads
        │        the epicenter directly)
        ▼  (all three complete before Step 2)
Step 2  Prison creation + population
        Pack Chat ASSEMBLES the membership PROPOSAL from the
        supersession map + Step-1 provenance + R7 epicenter context
        (Pack Chat does NOT identify) → ══USER══ confirms PATH + exact
        membership → Pack Chat performs the USER-APPROVED destructive
        git mv (per-action approval; agents never move)
        │  (commit: the move + every inbound-ref note)
        ▼
Step 3+4 Researcher segments R1…R9 (parallel batches per §2.7)   ◄── prison now excluded
        each: RESEARCH-BD-195-SEGMENT-R<N>-<short>.md
        (Step 4 blast-radius = part of each R-pass)
        │
        ▼
        Researcher-side reconciliation (pack-docs-researcher or
        pack-architect) → AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md
        ══USER══ reviews the ONE exhaustive problem list
        │  (commit: the 9 segment reports + the reconciled list)
        ▼
Step 5  Architect segments A1…A9 (parallel per §2.7)             ◄── consume reconciled problems
        each: ARCHITECTURE-BD-195-SEGMENT-A<N>-<short>.md
        (architect spawn ══USER══-gated per §2 architect protocol)
        │
        ▼
        Architect-side reconciliation (pack-architect) →
        ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md
        ══USER══ reviews the ONE coherent fix design
        │  (commit: the 9 segment reports + the reconciled fix design)
        ▼
Step 6  Fix-implementation planner (pack-planner; DISTINCT from
        this plan's author) → PLAN-BD-195-FIX-IMPLEMENTATION.md
        ══USER══ reviews the commit-sequenced fix plan
        │  (commit: the fix plan doc)
        ▼
Step 7  Implementation (pack-coder, fresh-per-commit) with the
        review/fix cadence of §7  ── validate-pack.py green at
        EVERY commit; per-commit ══USER══ commit gate; per-cycle
        triage ══USER══ gate
        │  (group cadence: default SEQUENTIAL; only the CODING of
        │   Step-6-PROVEN-disjoint groups may overlap; ALL commits /
        │   per-group reviews / triage / G7b gates SERIALIZE)
        ▼
Step 8  Final audit(s) (pack-reviewer + pack-architect auditor
        pass) → PACK-REVIEW / AUDIT docs
        ══USER══ reviews audit verdict (clean → BD-195 done)
        │  (commit: audit docs; BD-195 Status→Resolved is the
        │   implicit batch-completion flip)
        ▼
Step 9  BD-185 decision gate — wipe vs salvage (bias: complete
        redo)  ══USER══ DECIDES
```

### 4.1 Why Steps 1–2 precede the researcher segments (unchanged from §4 of the investigation plan)

- **Step 1 before Step 2** (directive order): the Retained-Decisions doc must
  be extracted from the contaminated sources BEFORE those sources are
  prisoned, or the preapproved decisions are lost.
- **Steps 1–2 before Step 3**: the prison directory must exist and be
  populated before the researcher segments declare their exclusion; QG-5
  diffs `git ls-files` *minus the prison paths*, well-defined only after Step 2.
- **R7 scoped pre-read runs IN PARALLEL with Step 1 and Step 1b (no
  inter-dependency)**: R7 (epicenter) produces `AUDIT-BD-195-R7-PREREAD.md`,
  whose outputs feed TWO consumers — neither a blocking edge into Step 1:
  (a) `retained-decision`-tagged LEADS that ENRICH the Step-1 extraction
  (non-blocking — the Step-1 extractor reads the epicenter directly, so it does
  not wait on R7), and (b) epicenter-deep CONTEXT that ENRICHES the Step-1b
  supersession map's epicenter entries. R7 is NOT a predecessor of Step 1; all
  three pre-prison passes run concurrently and converge BEFORE Step 2. The full
  R7 deep pass runs later, in Step 3, over the post-prison remainder.
  **Prison-membership IDENTIFICATION is owned by the dedicated whole-repo
  supersession-mapping pass (below), NOT by R7** — R7 is epicenter-scoped and
  would miss whole-repo supersession; the two are not overlapping
  identifications (R7 = retained-decision leads + epicenter depth; the
  supersession map = the single factual whole-repo superseded→superseding
  source).
- **The supersession-mapping pass supplies the prison-membership evidence**: a
  dedicated `pack-docs-researcher` reads INSIDE every doc across the ENTIRE
  repo AND reads the git commit history (`git log`) to produce
  `AUDIT-BD-195-SUPERSEDED-MAP.md` — a purely FACTUAL "doc X is superseded by
  doc Y (and Z)" mapping with the establishing evidence (the in-doc statement
  and/or the commit message), and NO opinion about a doc's purpose or why it
  was replaced. It runs in PARALLEL with Step 1 (both are read-only over the
  pre-prison repo) and completes BEFORE Step 2, because its mapping is the
  membership evidence Pack Chat assembles the proposal from. See § Step 2.
- **Residual-miss handling (supersession found late).** The supersession-
  mapping pass is comprehensive (whole-repo, in-doc + git-history), so it is
  expected to catch supersession BEFORE Step 2. Residual risk: a deep R1–R9
  segment (Step 3), reading its owned paths line-level, surfaces a superseded
  doc the map missed. Handling: the segment tags it `prison-candidate` (the
  investigation plan §3.3 tag, retained for exactly this late-discovery case)
  in its report; the researcher-side reconciliation collects such tags; Pack
  Chat assembles a SUPPLEMENTARY membership proposal and runs a second
  user-gated prison move (a small repeat of Step 2's G2a/G2b/S2-mv/commit
  before RECr's problem list is finalized, so the late-found superseded doc is
  excluded from the in-scope problem list). This keeps a SINGLE identification
  OWNER for the bulk pass (the Step-1b map) while giving the deep segments a
  safety-net channel — they do not re-do whole-repo identification, they only
  flag a stray miss.

### 4.2 Working-state invariant across the whole sequence

Steps 1–6 produce only **workflow-artifact docs** under
`maintenance-docs/v11-implementation/` (+ one `maintenance-docs/v11-research/`
for any R/A research output) and the **Step-2 prison move**. None of Steps 1–6
edits a `project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`
product surface, so `validate-pack.py` and the fixture manifest are unaffected
by Steps 1–6 EXCEPT where the Step-2 move touches a path the validator scans
(see §5 Step 2 verification). The product surface changes only in **Step 7**,
where the working-state invariant (`validate-pack.py` green at every commit)
is enforced commit-by-commit.


---

## 5. PER-STEP EXECUTION DEFINITIONS (1–9)

Each step: **Agent(s)** · **Inputs read** · **Outputs produced** · **User
gate** · **Verification / obligations**. Every agent prompt carries the §3
prison rule verbatim and the STOP-MEANS-STOP / read-only directive per §2.

### Step 1 — Retained-Decisions extraction

- **Agent.** `pack-docs-researcher` (extraction is evidence-gathering from
  existing sources, not fix-design). One instance, background. (If the user
  prefers a design-judgment framing, `pack-architect` is the alternative —
  but the task is "find and quote the preapproved decisions," which is
  researcher work; default `pack-docs-researcher`.)
- **Inputs read.** (a) The BD-195 directive Step 1. (b) The epicenter scope
  itself (§1.2 untracked V2 docs + §1.3 committed BD-185/BD-193/BD-194/groupings
  docs) — the extractor reads the epicenter DIRECTLY (it does not wait on R7).
  (c) The R7 pre-read's `AUDIT-BD-195-R7-PREREAD.md` retained-decision LEADS
  *if already available* — a non-blocking enrichment, since R7 runs in parallel
  (see § Step 1b sibling note and §4.1); the extractor proceeds without it if
  R7 has not yet completed. (d) Any chat-surfaced "user-approved" markers the
  prompt names. **Prison rule note:** the prison does NOT yet exist; Step 1
  reads the contaminated sources IN PLACE. **Sibling passes:** Step 1 is one of
  THREE parallel pre-prison read-only passes — the Step-1 extractor, the Step-1b
  supersession-mapping pass, and the R7 scoped pre-read — with NO
  inter-dependency; all three converge before Step 2 (§4.1, §6.1).
- **Outputs produced.** `maintenance-docs/v11-implementation/AUDIT-BD-195-RETAINED-DECISIONS.md`
  — a clean doc listing each preapproved good BD-185 decision with: the
  decision stated self-contained, the source doc(s) it was extracted from
  (so provenance is auditable BEFORE those sources are prisoned), and a
  one-line "why retained" per the surfacing standard. Findings framed as the
  AGENT's ("RESEARCHER FINDING: retained decision …").
- **User gate.** ══USER══ **confirms the retained set** (directive Step 1:
  "user confirms"). The user may add/remove/adjust. This is intent-dependent —
  a MAINTAINER DECISION the agent cannot pre-make.
- **Verification / obligations.** No product surface touched → no
  validate-pack / manifest obligation. Coverage check: every §1.3/§1.2
  epicenter doc the extractor read is listed as "scanned" (so the user sees
  the extraction was exhaustive over the epicenter, not cherry-picked). The
  doc is a workflow artifact (CLAUDE.md exempt-from-structural-signal);
  it sweeps to `maintenance-docs/archive/v11/` at version ship.
- **Commit.** Pack Chat commits the doc (PM-discussed). Subject:
  `docs: v11 — BD-195 Step 1 Retained-Decisions extraction (pack-only)`.
  Diff is `maintenance-docs/` only → `pack-only` keyword valid (Check 36
  denies `project-template/` + `supporting-docs/`; `maintenance-docs/` is
  neither). No manifest regen (not a v11-surface dir).

### Step 1b — Whole-repo supersession-mapping pass (the prison-membership evidence)

Runs in PARALLEL with Step 1 (both read-only over the pre-prison repo);
completes BEFORE Step 2. Labelled "1b" because it is a sibling read-only pass
to Step 1, not a successor — neither blocks the other.

- **Agent.** ONE `pack-docs-researcher` (read-only), fresh, background. This is
  a DEDICATED pass — the whole-repo supersession identification is the agent's
  job, NOT Pack Chat's.
- **What it does.** Reads INSIDE every doc across the ENTIRE repo (all of
  `maintenance-docs/` incl. `archive/`, `supporting-docs/`, `pack-ops/`, the
  trinity, READMEs, and any prose doc under `project-template/` /
  `scripts/` / docs trees) AND reads the git commit history (`git log`,
  including commit messages and rename/delete history). It produces a purely
  FACTUAL mapping: for each superseded doc, WHICH doc(s) superseded it
  ("doc X is superseded by doc Y / and Z"), each entry carrying the EVIDENCE
  that establishes the relationship — the in-doc statement (e.g., a
  "superseded by …" / "replaced by …" note inside X or Y) and/or the commit
  message that establishes it (e.g., "docs: … supersede X with Y").
- **Explicitly OUT of scope (hard constraint).** NO opinion about a doc's
  PURPOSE and NO opinion about WHY it was replaced — only the factual
  "what superseded what" relationship + its evidence. The agent does not
  recommend prison membership, does not judge contamination, and does not
  rank docs; it reports relationships and evidence. (Membership is Pack Chat's
  assembled PROPOSAL + the user's confirmation, Step 2.)
- **Inputs read.** Every doc in the repo (read IN PLACE — the prison does not
  yet exist); `git log` / `git log --follow` / `git log --diff-filter` history;
  the directive Step 2; the §1.3 epicenter candidate list (as a non-exhaustive
  starting index, not a limit — the pass is whole-repo). **Prison rule note:**
  the prison does NOT yet exist; the pass reads sources IN PLACE.
- **Outputs produced.**
  `maintenance-docs/v11-implementation/AUDIT-BD-195-SUPERSEDED-MAP.md` — the
  superseded→superseding mapping + per-entry evidence. Includes
  `maintenance-docs/archive/` docs that are ALSO superseded (the
  "archived-AND-superseded" subset the directive sends to the prison), each
  mapped to the doc(s) that superseded them with evidence. A coverage line
  attests the pass read every doc area (so the mapping is provably whole-repo,
  not epicenter-only).
- **User gate.** NONE directly on this pass's output — its mapping feeds the
  Step-2 membership proposal (G2a) where the user confirms. (The map is a
  factual artifact; the user's decision is at Step 2 on the assembled
  proposal.)
- **Verification / obligations.** No product surface touched → no
  validate-pack / manifest obligation. Coverage attestation: every doc area
  listed as read. The doc is a workflow artifact; it sweeps to
  `maintenance-docs/archive/v11/` at version ship.
- **Commit.** Committed together with the Step-1 Retained-Decisions doc in C1
  (both are pre-Step-2 read-only artifacts; see §8). Subject covers both:
  `docs: v11 — BD-195 Step 1 Retained-Decisions + supersession map (pack-only)`.

### Step 2 — Prison creation + population

- **Agent.** **NONE for the move** — agents never perform destructive/
  state-changing ops. Pack Chat performs the move directly under per-action
  user approval (CLAUDE.md no-destructive-without-approval; the move is `git
  mv` / `mkdir` + `mv`, a state-changing op). The whole-repo supersession
  IDENTIFICATION was done by the dedicated Step-1b `pack-docs-researcher` pass
  (`AUDIT-BD-195-SUPERSEDED-MAP.md`); Pack Chat does NOT identify — it only
  ASSEMBLES the membership PROPOSAL from that factual mapping (+ Step-1
  provenance + R7 epicenter context) for the user to confirm. No agent moves
  anything.
- **How superseded docs are IDENTIFIED across the ENTIRE repo.**
  Identification is owned by the dedicated **Step-1b supersession-mapping
  pass** (a `pack-docs-researcher`, NOT Pack Chat — USER DECISION). Pack Chat
  does NOT identify; it ASSEMBLES the membership PROPOSAL from three evidence
  inputs, then the user confirms:
  1. **The supersession map (`AUDIT-BD-195-SUPERSEDED-MAP.md`).** The primary
     evidence — the dedicated Step-1b pass's factual whole-repo
     superseded→superseding mapping, INCLUDING the "archived-AND-superseded"
     subset under `maintenance-docs/archive/` (the directive is explicit:
     superseded docs already in `archive/` go to the prison; `archive/` keeps
     ONLY non-superseded history). Every prison candidate traces to a map entry
     with its establishing evidence (in-doc statement and/or commit message).
  2. **Step-1 provenance.** Every source the Retained-Decisions doc extracted
     FROM is a prison candidate (its good content is now preserved elsewhere) —
     cross-checked against the map.
  3. **R7 epicenter context (`AUDIT-BD-195-R7-PREREAD.md`).** The R7 pre-read's
     epicenter-deep reading enriches the map's epicenter entries (it does NOT
     add a separate identification — the map is the single whole-repo source).
  Pack Chat assembles these into a per-doc candidate proposal with the map's
  evidence cited per candidate — NO new identification by Pack Chat, NO opinion
  added beyond what the map factually establishes.
- **Prison directory path / constraints** (investigation plan §4.3 — the path
  is a Step-2 user decision; the constraints are fixed):
  (a) distinct from `maintenance-docs/archive/`;
  (b) name makes "presence = superseded/contaminated" unambiguous;
  (c) outside any glob a researcher segment owns (so the QG-5 "minus prison
      paths" subtraction is clean);
  (d) outside `validate-pack.py`'s scanned surfaces (so CI does not lint
      prisoned content) — Pack Chat verifies the chosen path against the
      validator's path globs BEFORE the move and reports the check.
  A concrete candidate consistent with all four (for the user to accept or
  override): `maintenance-docs/prison/` — but the user confirms the exact
  path. **NOTE:** `maintenance-docs/prison/` is itself UNDER `maintenance-docs/`;
  Pack Chat MUST confirm `validate-pack.py` does not recursively scan
  `maintenance-docs/` for any check, else a `.boundary-exempt` / glob-exclusion
  adjustment lands in the same Step-2 commit (surfaced to the user).
- **Inputs read.** `AUDIT-BD-195-SUPERSEDED-MAP.md` (the primary membership
  evidence); the Step-1 Retained-Decisions doc (provenance); the R7 pre-read
  epicenter context (`AUDIT-BD-195-R7-PREREAD.md`); the directive Step 2; the
  validator path globs (to satisfy constraint (d)).
- **Outputs produced.** (a) The prison directory, populated. (b) Inbound-
  reference notes: any in-scope doc/script that referenced a now-prisoned file
  is FLAGGED (not yet fixed — the fix is designed in Step 5 and lands in
  Step 7) so the user sees the blast radius of the move. (Pack Chat may
  produce a `maintenance-docs/v11-implementation/AUDIT-BD-195-PRISON-MANIFEST.md`
  listing every moved path + its prior inbound references, as a workflow
  artifact.)
- **User gate.** ══USER══ **confirms the prison PATH + the exact membership
  set**, THEN ══USER══ **approves the destructive move** (per-action approval;
  two confirmations — what to move + that the move runs). MAINTAINER DECISION:
  path/name + membership are judgment + intent.
- **Verification / obligations.** After the move: `git status` shows the moved
  paths; Pack Chat runs `python3 scripts/validate-pack.py` to PROVE the move
  did not break a scanned surface (if the prison path is under a scanned glob,
  the exclusion adjustment is in the same commit and re-verified). The QG-5
  baseline for Step 3 is now `git ls-files` minus the confirmed prison paths.
  **Manifest:** the prison move does NOT touch `project-template/`/`scripts/`/
  `pack-ops/`/`supporting-docs/` (it moves `maintenance-docs/` docs), so no
  manifest regen — UNLESS a constraint-(d) glob adjustment touches
  `validate-pack.py` or a scanned config, in which case manifest regen +
  per-check tests apply to THAT commit.
- **Commit.** Pack Chat commits the move + the prison manifest doc + any
  exclusion adjustment. Subject:
  `docs: v11 — BD-195 Step 2 prison created + superseded docs moved (pack-only)`.
  If the commit touches `validate-pack.py`, drop `pack-only` is still valid
  (validate-pack.py is pack-internal, not `project-template/`/`supporting-docs/`),
  but per-check tests MUST run first.

### Step 3 (+4) — Researcher segments R1…R9 and the researcher reconciliation

- **Agents.** Nine `pack-docs-researcher` instances (one per segment R1…R9),
  spawned in parallel batches per the investigation plan §2.7 cadence, each
  background, NO worktree isolation, fresh instances. PLUS one reconciliation
  pass (a `pack-docs-researcher` or `pack-architect` — the reconciliation is
  index/de-dup/attestation work, default `pack-docs-researcher`; see §6 spawn
  cadence for concurrency).
- **Inputs read (per segment).** The segment's **owned-path manifest**
  (investigation plan §2.3); the §2.4 cross-cutting lenses A–E; the §3 shared
  output-shape + surfacing standard; the §6 quality gates (esp. QG-1/QG-2/QG-4
  the segment must satisfy). **Prison rule:** the segment's owned paths EXCLUDE
  the confirmed prison paths; the prompt states the prison path explicitly and
  the segment treats any prisoned doc as out of scope.
- **Outputs produced.** Per segment:
  `maintenance-docs/v11-implementation/RESEARCH-BD-195-SEGMENT-R<N>-<short>.md`
  (R-segments whose owned set is research-tree content may instead write under
  `maintenance-docs/v11-research/` per the naming convention — but the
  investigation plan §3.5 standardizes ALL segment reports under
  `v11-implementation/`; follow §3.5). Reconciliation:
  `maintenance-docs/v11-implementation/AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`
  (ONE exhaustive, de-duplicated problem list, §5.1 of the investigation plan).
- **User gate.** ══USER══ **reviews the ONE reconciled problem list.** The
  user decides what is in scope to fix (directive surfacing standard: "the user
  decides what to act on, if anything"). No per-segment user gate — segments
  reconcile first, the user sees ONE list.
- **Verification / obligations.** The reconciliation enforces QG-1 (coverage
  map complete per segment), QG-3 (output-shape), QG-4 (seed-sweep proof),
  **QG-5 (whole-repo coverage: `git ls-files` minus prison == union of the 9
  owned-path manifests + the 5 untracked V2 docs on R7)**, QG-8 (uniformity).
  A segment that fails a gate is BOUNCED back (re-spawned), not reconciled
  around. No product surface edited → no validate-pack / manifest obligation
  for Step 3 (these are read + report passes). Reports are workflow artifacts.
- **Commit.** Pack Chat commits the 9 segment reports + the reconciled list.
  Subject: `docs: v11 — BD-195 Step 3 researcher segments + reconciled problem list (pack-only)`.
  `pack-only` valid (`maintenance-docs/` only).

### Step 5 — Architect segments A1…A9 and the architect reconciliation

- **Agents.** Nine `pack-architect` instances (A1…A9 ≡ R1…R9), parallel per
  §2.7, background, NO isolation, fresh. PLUS one `pack-architect`
  reconciliation pass. **Architect spawn is ══USER══-gated** (§2 architect
  protocol) — Pack Chat surfaces the intent to spawn the architect phase and
  waits for approval (the architect phase commits the pipeline to a fix design).
- **Inputs read (per segment).** The matching reconciled problems (routed by
  segment ID + any cross-segment findings the reconciliation assigned to this
  A-segment); the §3 output-shape (architect records add **Fix design** +
  **Blast radius** fields per investigation plan §3.2); the boundary/process
  rules as DESIGN CONSTRAINTS (trinity rule, P-missed-7 SSOT-first,
  deliverable-only, separation-of-concerns, "skill/agent maintenance is
  mechanical by default" — a boundary-moving or rule-changing fix is an
  architect-level decision, never a mechanical patch). **Prison rule:** a fix
  may RE-POINT an in-scope reference AWAY from a prisoned doc; it may NEVER
  edit, trust, or point INTO a prisoned doc.
- **Outputs produced.** Per segment:
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-SEGMENT-A<N>-<short>.md`.
  Reconciliation:
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md`
  (ONE coherent fix design, §5.2 of the investigation plan), including the
  **global blast-radius union** (every file touched, every ENCODING surface —
  validator/tests/CI/docs — every trinity/quad mirror, the
  `test-fixtures/manifest.txt` regen trigger if any v11-surface path is in the
  union) and the **working-state ordering** (a valid topological commit order;
  QG-7).
- **User gate.** ══USER══ **reviews the ONE fix design.** Any
  `DESIGN CONFLICT — user decision` or boundary/rule-change fix is surfaced for
  the user's call. MAINTAINER DECISIONs surface here.
- **Verification / obligations.** Reconciliation enforces QG-6 (every problem
  maps to exactly one owning fix or an explicit won't-fix/user-decision with
  rationale) and **QG-7 (working-state design proof: a topological order under
  which `validate-pack.py` + the per-check test files for any touched check
  pass at every intermediate commit; the manifest-regen obligation named for
  any v11-surface path in the blast radius)**. No product surface edited yet →
  no live validate-pack / manifest run (the PROOF is on paper; execution is
  Step 7). Reports are workflow artifacts.
- **Commit.** Pack Chat commits the 9 segment reports + the reconciled fix
  design. Subject: `docs: v11 — BD-195 Step 5 architect segments + reconciled fix design (pack-only)`.


### Step 6 — Fix-implementation planner

- **Agent.** ONE `pack-planner` instance — **DISTINCT from this Step-0/master
  planner.** Fresh instance, background.
- **Inputs read.** `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md` (the ONLY
  design input — the planner sequences the approved fix design into commits);
  the §2 standing rules (it must produce a plan that HONORS PREFLIGHT +
  per-check tests + manifest regen + scope-keyword + the review/fix cadence of
  §7); the QG-7 topological order it inherits. **Prison rule:** no commit it
  sequences ever touches a prisoned path.
- **Outputs produced.**
  `maintenance-docs/v11-implementation/PLAN-BD-195-FIX-IMPLEMENTATION.md` —
  the commit-sequenced fix plan: ordered commits, per-commit file list, the
  review/fix cadence boundaries (§7), per-commit verification (validate-pack
  scope, which per-check tests, manifest-regen yes/no, scope-keyword), and the
  working-state guarantee (validate-pack green at every commit).
- **User gate.** ══USER══ **reviews the commit-sequenced fix plan**
  (planner→user→coder gate; §2). The user's last cheap window to redirect
  before implementation consumes agent time.
- **Verification / obligations.** No product surface edited → no live
  validate-pack / manifest run. The plan must EXHIBIT the topological order
  (inherited from QG-7) and assign each commit its verification obligations.
- **Commit.** Pack Chat commits the fix plan. Subject:
  `docs: v11 — BD-195 Step 6 fix-implementation plan (pack-only)`.

### Step 7 — Implementation (the review/fix cadence — the open question, resolved)

- **Agents.** `pack-coder` — **a FRESH instance per commit** (never reused
  across commits; §2). `pack-reviewer` per the cadence below. Fix-coder
  (fresh) per review cycle. All background, NO isolation.
- **Inputs read (per coder).** The specific commit's slice of
  `PLAN-BD-195-FIX-IMPLEMENTATION.md` + the matching fix design from
  `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md`. **Prison rule + STOP-MEANS-STOP
  + PREFLIGHT** in every prompt. **Boundary discipline (P-missed-7):** any
  `project-template/` edit investigates the project-side SSOT first.
- **Outputs produced (per coder).** Working-tree edits + an IMPL-REPORT
  (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-195-<commit-id>.md`).
  Reviewer outputs `PACK-REVIEW-BD-195-<scope>.md`; fix-coder outputs a
  fix IMPL-REPORT.

**THE REVIEW/FIX CADENCE (defined + justified).** BD-195's fix set is
**multi-commit and cross-surface** (the reconciled blast radius spans pack-ops
governance, pack-self agents/skills, client-shipped product, scripts, tests,
config, and frozen-archive pointers — investigation plan R1–R9). CLAUDE.md's
two binding rules are: (1) **"Per-BD review/fix runs INLINE, before the next
BD's coder spawns"** for multi-BD batches, and (2) **"end-of-batch reviewer
runs once on the full batch after all per-BD cycles complete."** BD-195 is ONE
BD with MANY commits, not many BDs — so the literal "per-BD" unit maps to a
**per-coherent-fix-group** unit here. The cadence is therefore a **COMBINATION**:

1. **Per-commit PREFLIGHT self-verification (every commit).** Every coder runs
   the PREFLIGHT gate before its IMPL-REPORT: in-scope verification PASS +
   `validate-pack.py` PASS (when the commit touches `project-template/` /
   `pack-ops/` / `supporting-docs/` / `scripts/`) + the relevant per-check
   test files PASS (when it modifies `validate-pack.py` / the `init-project.sh`
   inventory / `scripts/lib/` check-referenced files / allowlisted surfaces).
   This is NOT a reviewer pass — it is the coder's own green-state proof, and
   it runs at EVERY commit without exception. It is the floor that keeps
   `validate-pack.py` green at every intermediate commit (the working-state
   invariant). **Justification:** CLAUDE.md PREFLIGHT rule + the BD-193/BD-194
   incident (a commit passed because validate-pack ran clean but a per-check
   test would have failed on push — per-check tests are mandatory at the
   touching commit).

2. **Per-FIX-GROUP inline review/fix (the "per-BD" analog).** The Step-6 plan
   partitions the commits into **coherent fix groups** (a group = the commits
   that together realize one reconciled-fix-design cluster on one cohesive
   surface — e.g., "R1/A1 pack-ops governance fixes," "R5/A5 + R6/A6 source +
   its ENCODING tests as a lock-step pair," "R3/A3 client trinity + docs/pack").
   After a fix group's commits land, **a `pack-reviewer` runs INLINE on that
   group BEFORE the next DEPENDENT group's first coder spawns** → Pack Chat
   triages (default FIX-ALL, OQ-1 for SKIPs) → ══USER══ triage gate → fresh
   fix-coder → ══USER══ commit gate. **Proven-disjoint groups are EXEMPT from
   this cross-group wait:** when the Step-6 plan PROVES two groups share no file
   AND no ENCODING surface, the second group's CODING may begin before the first
   group's reviewer completes (a finding on the first group's surfaces cannot
   reach the disjoint second group's surfaces). The exemption is from waiting on
   the OTHER group's reviewer only — **each group still runs its OWN inline
   reviewer + triage cycle**, and **ALL COMMITS SERIALIZE regardless** (the
   working-state invariant + the single shared working tree + the per-commit
   G7b gate force one commit at a time, each an atomic green checkpoint).
   **Justification:** this is the direct analog of
   CLAUDE.md "per-BD review/fix runs INLINE, before the next BD's coder spawns"
   — the fix group is the BD-195 unit of coherent work; ENCODING-lock-step
   pairs (R5↔R6) MUST be one group so the validator/test lock-step is reviewed
   together (Lens E + the BD-193/BD-194 lesson).

3. **End-of-batch review (once, after ALL fix groups).** After every fix group
   completes, a single `pack-reviewer` end-of-batch pass runs over the FULL
   BD-195 fix set → triage → ══USER══ → fix → ══USER══. **Justification:**
   CLAUDE.md "end-of-batch reviewer runs once on the full batch after all
   per-BD cycles complete." This catches cross-group interactions the
   per-group reviews could not see (e.g., a cross-reference between a surface
   fixed in group 1 and one fixed in group 4).

   **Per-group vs per-commit reviewer — the explicit choice.** Reviewer passes
   are **per-fix-group, NOT per-commit.** Per-commit reviewer passes would
   violate the "one review/fix cycle per batch" spirit (endless cycles) and
   waste agent time; the per-commit floor is the PREFLIGHT self-verification
   (item 1), not a reviewer. Per-group is the correct granularity: large enough
   that a reviewer sees a coherent change, small enough that a defect is caught
   before it compounds. This is consistent with CLAUDE.md's prohibition on
   "a second review pass" within a unit — each fix group gets exactly ONE
   inline review/fix cycle, and the batch gets exactly ONE end-of-batch cycle.

   **Step-8 vs end-of-batch — not redundant.** The Step-7 end-of-batch review
   is a REVIEWER pass on the fix set (find defects in the fixes). Step 8 is the
   broader AUDIT (does the repo now satisfy the BD-195 pristine bar — seeds
   swept everywhere, no prisoned-doc references, boundary clean). They are
   different scopes (§Step 8).

- **Per-commit verification / obligations (every commit).** PREFLIGHT line;
  `validate-pack.py` PASS for any v11-surface-touching commit; per-check tests
  where applicable; **`test-fixtures/manifest.txt` regen** (run
  `bash test-fixtures/build.sh --all --clean`; stage if the diff is non-empty)
  for any commit touching `project-template/` / `scripts/` / `pack-ops/` /
  `supporting-docs/`; **scope-keyword honesty (Check 36)** — a commit touching
  `project-template/` or `supporting-docs/` may NOT carry `pack-only`; use the
  audience-correct keyword (`project-only` if exclusively client-shipped) or
  neutral framing if cross-surface; **trinity/quad parity** in the SAME commit
  for any trinity/quad edit (CLAUDE.md trinity rule).
- **User gates.** Per fix-group triage gate (══USER══) and per-commit commit
  gate (══USER══); end-of-batch triage gate (══USER══) and commit gate
  (══USER══). Every "Approve commit?" prompt carries the next-steps plan
  (CLAUDE.md commit-approval-next-steps rule).
- **Commits.** Per the Step-6 plan; subjects use the
  `feat:`/`fix:`/`docs:` + `vN — BD-195 …` format. Approved `fix:` shapes per
  CLAUDE.md (per-BD inline, `(Batch N)`, broad batch review/fix). Mixed-scope
  commits carry NO scope keyword.

### Step 8 — Final audit(s)

- **Agents.** TWO passes (different lenses; both background, fresh):
  1. **`pack-reviewer`** — a final review of the COMPLETE BD-195 fix set
     against the reconciled fix design (did every designed fix land correctly;
     any regressions; ENCODING lock-step intact).
  2. **`pack-architect` (auditor lens)** — a from-scratch audit that the repo
     now meets the BD-195 **pristine bar**: the two known seeds (version,
     boundary) are PROVABLY swept everywhere in scope; NO in-scope surface
     references a prisoned doc (Lens C against the prison); trinity/quad parity
     holds; the per-entry tree contracts (`<stream>/_rules.md`) are intact;
     `validate-pack.py` (all invoked checks) + every per-check test + the
     fixture manifest + the full CI suite are green.
  (If the user prefers, a `pack-docs-researcher` audit pass may substitute for
  or supplement pass 2 — the audit-vs-review distinction is the load-bearing
  point; the exact second agent is a per-case user call at the Step-8 gate.)
- **Inputs read.** The reconciled fix design + the reconciled problem list (to
  confirm every surfaced problem was addressed or explicitly user-deferred);
  the live repo state. **Prison rule:** the audit VERIFIES no in-scope surface
  references a prisoned doc; it never opens a prisoned doc as authoritative.
- **Outputs produced.** `PACK-REVIEW-BD-195-FINAL.md` and
  `AUDIT-BD-195-FINAL.md` (workflow artifacts).
- **Success criteria (BD-195 declared done only when ALL hold).**
  - Every reconciled problem is FIXED or explicitly user-deferred with a
    tracked anchor (CLAUDE.md deferred-work-tracking — an open BD / live
    `TD-TBD` comment / new BD inserted at the right position; archived report
    is NOT an acceptable anchor).
  - The two seeds are provably swept across the whole in-scope repo.
  - No in-scope surface references a prisoned doc (no stale-ref into prison).
  - `validate-pack.py` + all per-check tests + fixture manifest + CI suite
    green.
  - Trinity/quad parity holds at every trinity/quad location.
- **User gate.** ══USER══ **reviews the audit verdict.** Clean → BD-195 is
  done; per CLAUDE.md **implicit BD-status flip on batch completion**, Pack
  Chat flips BD-195 `Status: Open` → `Resolved` (and fills `Resolved:`) as the
  final step — no separate approval. NOT clean → the findings re-enter the
  Step-7 cadence (a fix-group cycle) until clean.
- **Verification / obligations.** The audit passes RUN `validate-pack.py`, the
  per-check tests, `bash test-fixtures/build.sh --verify`, and confirm the CI
  workflow wiring (Check 42) — and report the results in the audit doc. Any
  doc-only commit (the audit docs) is `pack-only`.

### Step 9 — BD-185 decision gate (wipe vs salvage)

- **Agent.** NONE — this is a pure ══USER══ DECISION. Pack Chat FRAMES it; it
  does not decide and does not recommend a salvage default (the directive's
  bias is **complete redo**).
- **How the call is framed for the user (bias: complete redo).** Pack Chat
  presents, per the decision-presentation protocol (one decision, full inline
  context, evidence-based):
  1. **The pristine baseline.** After Steps 1–8, v11.0 is at a verified-pristine
     post-Batch-19c state; the prior BD-185 attempt is in the prison
     (superseded). The Retained-Decisions doc (Step 1) holds the preapproved
     good decisions, preserved and confirmed.
  2. **The default the directive biases toward: COMPLETE REDO.** Start BD-185
     fresh from the pristine baseline + the Retained-Decisions doc; the prison
     BD-185 attempt is NOT anchored on or salvaged.
  3. **The salvage alternative (only if a fix pass independently PROVED a piece
     correct).** If Steps 3–8 surfaced and verified any prisoned BD-185
     artifact as independently correct, Pack Chat names exactly which artifact,
     the evidence that proved it correct, and the cost of re-deriving vs
     reusing it. ABSENT such proof, salvage is not offered — "feels reusable"
     is not proof (CLAUDE.md: prior work is salvaged ONLY if a fix pass
     independently proves it correct).
  4. **The decision the user makes.** Wipe (complete redo) vs salvage-the-named-
     proven-pieces. The user decides; this is a MAINTAINER DECISION.
- **Output.** No doc produced by BD-195 here — the decision SEEDS the BD-185
  restart (a separate BD's work, outside BD-195's scope). Pack Chat records the
  decision in the BD-185 entry's status line (PM-only edit) and, if the user
  authorizes the restart, opens/sequences BD-185's fresh plan as a NEW pass
  (not part of BD-195).
- **User gate.** ══USER══ DECIDES wipe vs salvage. This is the terminal BD-195
  gate.


---

## 6. AGENT-PASS INVENTORY (every spawn)

Every spawn: which agent · which step/segment · parallel vs sequential ·
fresh-instance discipline · background. All spawns are `run_in_background:
true`, NO `isolation: "worktree"` (CLAUDE.md sub-agent rules). Counts assume
the investigation plan's 9-segment granularity (a MAINTAINER DECISION the user
may re-granulate — the inventory scales 1:1 with segment count).

| # | Step | Agent | Instances | Parallel/Sequential | Fresh discipline |
|---|---|---|---|---|---|
| 1 | 1 | `pack-docs-researcher` (Retained-Decisions extractor) | 1 | — | fresh; closed after Step 1 commit |
| 2 | 1/2 | `pack-docs-researcher` (R7 scoped pre-read; epicenter context + retained-decision leads — NOT prison-candidate identification) → `AUDIT-BD-195-R7-PREREAD.md` | 1 | parallel with Step 1 + the supersession-map pass (NO inter-dependency) | fresh; ENRICHES Step 1 (non-blocking) + enriches the supersession map's epicenter entries; closed after C1 |
| 2b | 1b | `pack-docs-researcher` (whole-repo SUPERSESSION-MAPPING pass; reads inside every doc + `git log`; factual superseded→superseding map, no opinion) → `AUDIT-BD-195-SUPERSEDED-MAP.md` | 1 | parallel with Step 1 + R7 pre-read (all read-only over the pre-prison repo); completes before Step 2 | fresh; closed after C1 |
| 3 | 2 | — (Pack Chat ASSEMBLES the membership proposal from the supersession map; performs the move; no agent identifies or moves) | 0 | — | — |
| 4 | 3 | `pack-docs-researcher` × 9 (R1…R9) | 9 | parallel batches (§6.1) | fresh per segment; closed after Step 3 commit |
| 5 | 3 | `pack-docs-researcher` OR `pack-architect` (researcher-side reconciler) | 1 | sequential AFTER R1…R9 | fresh; closed after Step 3 commit |
| 6 | 5 | `pack-architect` × 9 (A1…A9) | 9 | parallel batches (§6.1) | fresh per segment; closed after Step 5 commit |
| 7 | 5 | `pack-architect` (architect-side reconciler) | 1 | sequential AFTER A1…A9 | fresh; closed after Step 5 commit |
| 8 | 6 | `pack-planner` (fix-implementation planner; DISTINCT from this planner) | 1 | sequential AFTER Step 5 | fresh; closed after Step 6 commit |
| 9 | 7 | `pack-coder` (implementation) | N (one FRESH per commit) | per the Step-6 plan; default SEQUENTIAL — only the CODING of proven-disjoint groups (no shared file + no shared ENCODING surface) may overlap; ALL commits / reviews-of-landed-state / triage / G7b gates SERIALIZE | FRESH per commit (never reused) |
| 10 | 7 | `pack-reviewer` (per-fix-group inline) | G (one per fix group) | sequential at each group boundary for DEPENDENT groups; reviewer analysis may overlap for proven-disjoint groups, but triage + fix commits serialize | fresh per group |
| 11 | 7 | `pack-coder` (fix-coder, per review cycle) | ≤ G + 1 | sequential after each triage gate | fresh per fix |
| 12 | 7 | `pack-reviewer` (end-of-batch, once) | 1 | sequential after all groups | fresh |
| 13 | 8 | `pack-reviewer` (final fix-set review) | 1 | sequential | fresh |
| 14 | 8 | `pack-architect` (final pristine-bar audit) | 1 | sequential (may run ∥ #13) | fresh |
| 15 | 9 | — (pure user decision; no agent) | 0 | — | — |

**Total agent spawns (9-segment granularity, before Step-7 commit count N and
group count G are known):** 1 extractor + 1 R7-pre-read + 1 supersession-map
pass + 9 researchers + 1 researcher-reconciler + 9 architects + 1
architect-reconciler + 1 fix-planner + 1 final-reviewer + 1 final-auditor =
**27 fixed**, PLUS Step-7's N coders + G group-reviewers + ≤G+1 fix-coders + 1
end-of-batch reviewer (sized by the Step-6 plan).

### 6.1 Spawn cadence / max concurrency (per the investigation plan §2.7)

- **Pre-prison read-only passes (Step 1 extractor ∥ R7 pre-read ∥
  supersession-mapping pass).** All three read the repo IN PLACE before the
  Step-2 prison move and have no inter-dependency (the extractor produces
  retained decisions; the supersession pass produces a factual superseded→
  superseding map; R7 produces epicenter context). They run FULLY IN PARALLEL —
  a genuine speedup with no quality loss. All three must COMPLETE before
  Step-2 membership assembly (the map + provenance + context are the proposal
  inputs). Identification of prison membership is owned solely by the
  supersession-mapping pass; R7 and the extractor do not identify.

- **Researchers (R1…R9).** Mostly independent → parallel. Two ordering
  constraints from §2.7: **R5 → R6** (or R5 ∥ R6 with a documented
  cross-reference handshake at reconciliation — R6 encodes invariants R5
  defines); and **R7's scoped pre-read runs in PARALLEL with Step 1 + Step 1b**
  (the three pre-prison passes — see the bullet above — with no
  inter-dependency) while R7's full deep pass runs later, in Step 3, over the
  post-prison remainder. Concurrency cap: the user's
  machine/agent-team limit (no hard cap imposed by this plan; batch in waves if
  the host throttles). Within Agent-Teams, spawn the stage's agents, keep them
  alive for follow-ups, close ALL after the Step-3 commit, respawn fresh for
  Step 5.
- **Architects (A1…A9).** After the reconciled problem list exists + the
  ══USER══ architect-spawn approval. Mostly parallel; any cross-segment fix the
  reconciliation flagged as coupled runs with an explicit dependency edge
  (named at reconciliation). Reconciler runs sequentially after A1…A9.
- **Coders (Step 7).** Default SEQUENTIAL (fresh-per-commit; validate-pack
  green at every commit means commits land one at a time). Two fix groups MAY
  run in parallel ONLY if the Step-6 plan proves their surfaces do not overlap
  (no shared file, no shared ENCODING surface) — otherwise sequential. **The
  parallelism is the CODING phase ONLY:** two proven-disjoint groups may EDIT
  concurrently in the shared working tree (disjoint file sets → no edit
  collision). **Commits, per-group reviews-of-landed-state, triage gates, and
  the per-commit G7b commit gate all SERIALIZE** — one commit at a time, each an
  atomic green checkpoint (the single shared tree has one staging surface; the
  working-state invariant forbids interleaving two groups' commits into a
  red intermediate state). So even fully-disjoint groups reconverge to a SERIAL
  commit/review/gate stream; only their edit-and-self-verify work overlaps.


---

## 7. CONSOLIDATED USER-GATE LIST

Every point the user reviews / confirms / approves / decides. (Triage gates +
commit gates recur per Step-7 fix group; counted as a pattern, not enumerated
per group.)

| Gate | Step | Type | What the user does |
|---|---|---|---|
| G0 | (pre) | review | Approve THIS master plan before Step 1 runs. |
| G1 | 1 | confirm | Confirm the Retained-Decisions set (add/remove/adjust). |
| G2a | 2 | confirm | Confirm the prison PATH/NAME + exact membership set. |
| G2b | 2 | approve | Approve the destructive prison MOVE (per-action). |
| G3 | 3 | review | Review the ONE reconciled problem list; decide scope to fix. |
| G4 | 5 | approve | Approve spawning the architect phase (architect-spawn protocol). |
| G5 | 5 | review | Review the ONE reconciled fix design; resolve DESIGN CONFLICTs. |
| G6 | 6 | review | Review the commit-sequenced fix plan (planner→user→coder). |
| G7a | 7 | triage | Per fix group: approve the reviewer-finding triage (FIX/SKIP). |
| G7b | 7 | commit | Per commit: approve the commit (with next-steps plan). |
| G8a | 8 | triage | Approve the final-review triage (if findings). |
| G8b | 8 | review | Review the audit verdict; clean → BD-195 Resolved. |
| G9 | 9 | decide | Decide BD-185 wipe vs salvage (bias: complete redo). |

Every commit in the whole sequence is additionally a commit gate (G7b
pattern): Pack Chat shows `git add -A && git status`, the staged files, and
the next-steps plan, and waits for explicit approval (CLAUDE.md: no commit
without explicit user approval).

---

## 8. COMMIT PLAN (what goes in each commit, in order)

The pack stays in a working state after EVERY commit — `validate-pack.py`
passes at every commit (vacuously for Steps 1–6 doc-only commits; enforced by
the PREFLIGHT floor for every Step-7 commit). Commit subjects follow CLAUDE.md
format (`docs:`/`feat:`/`fix:` + `vN — BD-195 …`); the scope keyword is
audience-correct (Check 36).

| # | Step | Commit contents | Subject (scope keyword) | Manifest? |
|---|---|---|---|---|
| C1 | 1/1b | `AUDIT-BD-195-RETAINED-DECISIONS.md` + `AUDIT-BD-195-SUPERSEDED-MAP.md` | `docs: v11 — BD-195 Step 1 Retained-Decisions + supersession map (pack-only)` | no |
| C2 | 2 | prison dir + moved docs + `AUDIT-BD-195-PRISON-MANIFEST.md` (+ any validator glob-exclusion) | `docs: v11 — BD-195 Step 2 prison move (pack-only)` | only if `validate-pack.py`/scanned config touched |
| C3 | 3 | 9 `RESEARCH-BD-195-SEGMENT-R<N>` + `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` | `docs: v11 — BD-195 Step 3 researcher + reconciled problems (pack-only)` | no |
| C4 | 5 | 9 `ARCHITECTURE-BD-195-SEGMENT-A<N>` + `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md` | `docs: v11 — BD-195 Step 5 architect + reconciled fix design (pack-only)` | no |
| C5 | 6 | `PLAN-BD-195-FIX-IMPLEMENTATION.md` | `docs: v11 — BD-195 Step 6 fix-implementation plan (pack-only)` | no |
| C6…Cm | 7 | per the Step-6 plan — one commit per coherent slice; fix-group review-fix commits interleaved | per-commit (audience-correct keyword or neutral) | YES if v11-surface touched |
| Cm+1 | 7 | end-of-batch review-fix commit (if findings) | `fix: v11 — broad batch review/fix (Batch BD-195)` | YES if v11-surface touched |
| Cn-1 | 8 | `PACK-REVIEW-BD-195-FINAL.md` + `AUDIT-BD-195-FINAL.md` | `docs: v11 — BD-195 Step 8 final audit (pack-only)` | no |
| Cn | 8 | BD-195 `Status: Open → Resolved` in `pack-ops/BACKLOG.md` (PM-only) | `docs: v11 — BD-195 Resolved (PM-only)` | no |

**Notes on the commit plan:**
- **C1…C5 and the Step-8 doc commits are `pack-only`** — their diffs are
  `maintenance-docs/` only (or `pack-ops/BACKLOG.md` for the Status flip, which
  is PM-only, not pack-only). Check 36 denies `project-template/` +
  `supporting-docs/` for `pack-only` — these commits touch neither.
- **C2 caveat.** If the prison path requires a `validate-pack.py` glob
  exclusion, that commit touches `scripts/` → per-check tests MUST run, and
  manifest regen applies (it is a `scripts/` touch). The `pack-only` keyword is
  still valid (validate-pack.py is pack-internal, not
  `project-template/`/`supporting-docs/`).
- **C6…Cm scope keywords (Step 7).** A commit exclusive to client-shipped
  surface (`project-template/` + `supporting-docs/`) carries `project-only`; a
  commit exclusive to pack-self surface carries `pack-only`; a commit spanning
  both carries NO keyword (neutral framing — "BD-195 cross-surface fix"). A
  trinity/quad commit at `project-template/` is `project-only`; the
  `project-template/` trinity is ALSO PM-only per PACK-AGENTS.md, so if Pack
  Chat makes that edit directly it is `PM-only` — but trinity SUBSTANCE fixes
  are coder work (Pack Chat does no fixes), so the coder edits and the commit
  is `project-only`. (Pack Chat edits the `project-template/` trinity directly
  ONLY for PM-only operational changes, not BD-195 substance fixes.)
- **Cn — the Status flip — is PM-only**, edited directly by Pack Chat (the
  Status flip is the implicit batch-completion flip, not a fix; Pack Chat may
  edit `pack-ops/BACKLOG.md` directly per CLAUDE.md PM-only).
- **No empty commits.** If a Step-7 fix group or the end-of-batch review
  produces no changes, no commit is created.

---

## 9. VERIFICATION PLAN

### 9.1 Per-step verification (summary)

| Step | CI / automated checks | Manual / agent checks | Grep / audit checks |
|---|---|---|---|
| 1 | none (doc-only) | extraction coverage over §1.3/§1.2 epicenter | — |
| 2 | `validate-pack.py` (prove move broke nothing) | prison path satisfies §4.3 (a)–(d); inbound-ref flags | `git ls-files` baseline = all minus prison |
| 3 | none (doc-only) | QG-1/QG-3/QG-4/QG-8 per segment | **QG-5: `git ls-files` minus prison == union of owned manifests + 5 V2 docs** |
| 5 | none (doc-only) | QG-6 fix-to-problem completeness | QG-7 topological-order proof |
| 6 | none (doc-only) | plan exhibits topological order + per-commit obligations | — |
| 7 | `validate-pack.py` + per-check tests + fixture-manifest verify at EVERY v11-surface commit; CI on every push | per-fix-group reviewer + end-of-batch reviewer; PREFLIGHT per commit | seed-sweep (`version`/`boundary`) re-grep on touched surfaces; no prisoned-path edit |
| 8 | `validate-pack.py` (all checks) + ALL per-check tests + `test-fixtures/build.sh --verify` + CI Check 42 (workflow wires all test files) | final review + pristine-bar audit | no in-scope surface references a prisoned doc; trinity/quad parity matrix |
| 9 | none (decision) | — | — |

### 9.2 The verification surface (concrete, current at HEAD `e580dda`)

- **`scripts/validate-pack.py`** — 40 invoked checks (per README + CLAUDE.md).
  Green at every Step-7 commit; full run at Step 8.
- **Per-check test files** — `scripts/tests/test-validate-pack-check-*.sh`
  (present today: checks 16, 18, 19, 39, 40, 41, 42, 43, the 32-33-34 group,
  the 36-37-38 group). Run when a commit modifies `validate-pack.py` / the
  `init-project.sh` inventory / `scripts/lib/` check-referenced files /
  allowlisted surfaces; ALL run at Step 8.
- **`test-fixtures/build.sh`** — `--all --clean` to regen + stage
  `test-fixtures/manifest.txt` on any v11-surface commit; `--verify` at Step 8.
  Stale manifest fails the CI `fixture manifest verify` step (RELEASE-GATE
  item 5) even when all functional tests pass.
- **CI workflow** — `.github/workflows/validate-pack.yml` runs on every push;
  Check 42 verifies the workflow wires all per-check test files. Never skip or
  disable.
- **CI Check 36** — commit-scope honesty; verifies a claimed `pack-only` /
  `project-only` / `PM-only` keyword against the commit diff.

### 9.3 Overall success criteria (BD-195 done)

All of: every reconciled problem fixed or user-deferred with a tracked anchor;
both seeds provably swept whole-repo; no in-scope reference into the prison;
`validate-pack.py` + all per-check tests + fixture manifest + CI green;
trinity/quad parity at every location; the Step-9 user decision recorded.


---

## 10. RECONCILING THE INVESTIGATION-APPROACH PLAN

This master plan consumes `PLAN-BD-195-INVESTIGATION.md` as the design for
Steps 3–5. The two are consistent EXCEPT for the refinements below, which the
directive forces and which the investigation plan should be updated to reflect
(a one-line edit per item, landed by Pack Chat when the user approves this
master plan — or noted as standing addenda if the investigation plan is left
as-is). Flagging these here makes the two plans consistent in operation even
before any edit.

### 10.1 §2.6 / §2.2 archive handling vs the prison rule (THE load-bearing reconciliation)

- **Investigation plan as written.** §2.2 says "`maintenance-docs/archive/`
  (252 files): in scope, but governed by the special handling rule in §2.6";
  §2.6 says R9/A9 read archived records for active outbound references +
  misleading mis-versioning, do NOT rewrite frozen history. R9 owns all 252
  archive files.
- **The directive's prison rule (Step 2).** Superseded docs **ALREADY IN
  `archive/`** (archived AND superseded = doubly useless) are MOVED TO THE
  PRISON in Step 2; `archive/` retains ONLY non-superseded historical records.
- **The reconciliation.** Because Step 2 runs BEFORE Step 3, by the time R9
  runs, the archive has ALREADY had its superseded subset removed to the
  prison. Therefore **R9/A9 audit only the NON-SUPERSEDED archive remainder**
  (252 minus whatever Step 2 prisoned out of `archive/`), NOT all 252. R9's
  owned-path manifest is computed AFTER Step 2 as `maintenance-docs/archive/`
  minus the prisoned-from-archive paths. The §2.6 archive rule still governs
  that remainder (frozen history; flag active stale pointers + misleading
  versioning only; narrowest user-gated edits). **Update to land in the
  investigation plan:** §2.2 and §2.6 should state "R9 owns the archive
  remainder after the Step-2 prison move (non-superseded records only); the
  superseded archive subset is prisoned in Step 2 and is out of scope." This is
  consistent with §2.3 R9 ("Frozen archive … do frozen records contain active
  outbound references that are now stale") — the remainder is exactly the
  frozen-and-still-valid history.
- **QG-5 interaction.** The QG-5 coverage audit (`git ls-files` minus prison ==
  union of owned manifests) already subtracts prison paths; since the
  prisoned-from-archive docs are IN the prison after Step 2, they are correctly
  excluded from BOTH sides of the QG-5 diff. No QG-5 change needed — only R9's
  owned-manifest definition is refined to "archive remainder."

### 10.2 R7 owned-set vs the prison move

**R7's prison role is now CONTEXT, not identification.** Per the USER DECISION,
whole-repo prison-membership identification is owned by the dedicated Step-1b
supersession-mapping pass (`AUDIT-BD-195-SUPERSEDED-MAP.md`), not by R7. R7's
pre-read supplies retained-decision leads (Step 1) and epicenter-deep context
that enriches the map's epicenter entries; it does NOT produce a separate
prison-candidate identification at the pre-read stage. (The `prison-candidate`
tag survives only as the deep-segment late-discovery safety net per §4.1
residual-miss handling.) The remainder of §10.2 (R7's full deep pass owns the
post-prison epicenter remainder) is unchanged.

- **Investigation plan.** R7 owns the §1.2 untracked V2 docs (5) + the §1.3
  committed BD-185/BD-193/BD-194/groupings docs + `templates-archive/` (13).
- **Reconciliation.** Many §1.3 docs are prime prison candidates (Step 2). After
  Step 2, R7's full deep pass (Step 3) owns only the epicenter docs that
  REMAIN OUTSIDE the prison. The investigation plan §4.1 already anticipates
  this ("the full R7 deep pass then runs in Step 3 over whatever epicenter docs
  remain OUTSIDE the prison") — so this is consistent; the master plan makes
  the timing explicit (R7 pre-read → Step 1 → Step 2 → R7 full pass on the
  remainder). No edit needed beyond confirming R7's owned manifest is the
  post-prison epicenter remainder.

### 10.3 Segment-report siting (§3.5)

- **Investigation plan §3.5** sites ALL segment reports under
  `maintenance-docs/v11-implementation/` (researcher + architect + both
  reconciliations). The master plan §5 follows this verbatim. (Note: a
  research-tree segment like R8's loose-doc coverage or R7's
  `v11-research/templates-archive/` content is still REPORTED under
  `v11-implementation/` per §3.5 — the report location is fixed even when the
  owned content lives in `v11-research/`.) Consistent; no edit.

### 10.4 Doc naming for the NEW BD-195 docs this master plan adds

The investigation plan §3.5 names the segment + reconciliation docs. This
master plan adds three NEW workflow-artifact doc names not in §3.5 (all under
`maintenance-docs/v11-implementation/`, all sweep to `archive/v11/` at ship):
- `AUDIT-BD-195-RETAINED-DECISIONS.md` (Step 1)
- `AUDIT-BD-195-SUPERSEDED-MAP.md` (Step 1b)
- `AUDIT-BD-195-R7-PREREAD.md` (R7 scoped pre-read)
- `AUDIT-BD-195-PRISON-MANIFEST.md` (Step 2)
- `PLAN-BD-195-FIX-IMPLEMENTATION.md` (Step 6)
- `IMPLEMENTATION-REPORT-BD-195-<commit-id>.md` (Step 7, per commit)
- `PACK-REVIEW-BD-195-FINAL.md` + `AUDIT-BD-195-FINAL.md` (Step 8)
All conform to the CLAUDE.md filename-uniqueness heuristic (BD-195-scoped,
unique) and the workflow-artifact naming patterns. No collision with existing
files (verified: no `*BD-195*` doc exists except `PLAN-BD-195-INVESTIGATION.md`
and this `PLAN-BD-195-EXECUTION.md`).

### 10.5 Reconciler-agent identity (§5.1 left it open)

The investigation plan §5.1/§5.2 does not pin the reconciler agent. This master
plan pins: researcher-side reconciler = `pack-docs-researcher` (or
`pack-architect` if the user prefers a design lens — it is index/de-dup/
attestation work); architect-side reconciler = `pack-architect` (it produces
the fix design + blast-radius union + topological order, which is architect
work). Consistent with §5; this is a refinement, not a conflict.


---

## 11. OPEN RISKS AND UNKNOWNS (orchestration-level)

These are risks this master plan's STRUCTURE is designed to contain — risks
about EXECUTING BD-195, not findings about the repo (findings are Step 3's
deliverable). The investigation plan §9 enumerates the investigation-level
risks; these are the additional orchestration risks.

1. **Prison-move stale references (the marquee risk).** Step 2 moves superseded
   docs; in-scope docs/scripts that referenced them now point into the prison.
   *Containment:* Step 2 produces the inbound-ref flags (the prison manifest);
   Lens C runs across all in-scope R-segments AFTER Step 2, surfacing every
   reference-into-prison as a `stale-ref` finding; A-segments design the
   re-point or removal; Step 7 lands it; Step 8 verifies "no in-scope surface
   references a prisoned doc." *Residual:* a reference in a Step-1/Step-2
   workflow doc (e.g., the Retained-Decisions doc cites a source that then gets
   prisoned) is EXPECTED and correct — those are provenance citations, not live
   pointers; they are not stale-ref defects.

2. **Prison path under a scanned glob → CI lint of prisoned content.** If the
   chosen prison path falls under a `validate-pack.py` scanned surface, CI
   would lint superseded content. *Containment:* §4.3 constraint (d) + the
   Step-2 obligation to verify the path against the validator globs BEFORE the
   move; an exclusion adjustment lands in the same Step-2 commit with per-check
   tests. *Residual:* if `maintenance-docs/` is recursively scanned by any
   future check, the exclusion must be maintained — flagged for the Step-2
   verifier.

3. **Step-7 working-state breakage (validate-pack red mid-sequence).**
   *Containment:* the PREFLIGHT floor at EVERY commit + the QG-7 topological
   order the Step-6 plan inherits (validate-pack green at every commit by
   construction). *Residual:* an ENCODING-lock-step gap (source fixed, test not)
   — contained by forcing R5↔R6 / source↔test into ONE fix group (§7) and the
   per-check test obligation.

4. **Scope-keyword (Check 36) failures on cross-surface Step-7 commits.** A fix
   that spans pack-self + client-shipped surface mis-claimed as `pack-only`
   fails CI. *Containment:* §8 commit-plan rules — audience-correct keyword or
   neutral framing per commit; the architect blast-radius (Step 5) reveals
   cross-surface fixes so the Step-6 planner can split commits.

5. **Manifest drift on v11-surface Step-7 commits.** A `project-template/` /
   `scripts/` / `pack-ops/` / `supporting-docs/` commit without manifest regen
   fails the CI fixture gate even when functional tests pass (the 667d2dd /
   4120d19 incident class). *Containment:* §2 + §9.2 manifest obligation at
   every v11-surface commit.

6. **Trinity/quad CI breakage.** A fix touches one CLI variant and not the
   others. *Containment:* the trinity rule as a Step-5 design constraint + the
   Step-7 same-commit parity obligation + the Step-8 parity matrix.

7. **Architect-spawn pipeline lock-in (process risk).** Spawning the Step-5
   architect phase commits Pack Chat to a multi-stage pipeline. *Containment:*
   the architect-spawn is ══USER══-gated (G4) — the user authorizes the pipeline
   before it fires.

8. **Reconciliation un-mergeability / explosion.** 9 segments × many findings
   may resist clean merge. *Containment:* QG-3/QG-8 (single template +
   vocabulary) + the Cross-segment-touch-points / Blast-radius hooks +
   the de-dup/theme-grouping procedure (investigation plan §5). *Residual:*
   scales with finding volume — if a reconciliation is unmanageable, Pack Chat
   re-granulates (the segment-count MAINTAINER DECISION) before Step 7.

9. **R7 pre-read vs Step-2 membership divergence.** The user's confirmed prison
   set (G2a) may differ from R7's pre-read candidates. *Containment:* R7's full
   pass re-scopes to the post-prison remainder by design (investigation plan
   §9 risk 1); the master plan sequences R7-full AFTER Step 2 so the divergence
   is absorbed, not propagated.

10. **Deferred-finding tracking at Step 8.** A user-deferred finding must land
    on a live forward-pointing anchor (open BD / live `TD-TBD` / new BD), never
    an archived report (CLAUDE.md deferred-work-tracking). *Containment:* the
    Step-8 success criterion makes "tracked anchor" a gate; Pack Chat opens the
    anchor (PM-only) before declaring BD-195 done.

11. **Migration-regression risk in Step 7.** A fix to migrator code/docs (R5
    `migrate-v10-to-v11.sh`, `lib/migrator-*`, `lib/migrate-v10-to-v11/`,
    `supporting-docs/MIGRATION-v10-to-v11.md`) regresses the v10→v11 path or the
    BD-119 framework. *Containment:* R5/R6 own these with behavioral-correctness
    questions; the BD-119 "do not copy-and-rewrite the framework" rule is a
    Step-5 design constraint; the migrator test files
    (`test-migrate-v10-to-v11-*.sh`, `test-migrator-*.sh`,
    `persona-contracts/contract-migration.sh`) run in the touching commit's
    PREFLIGHT and at Step 8.

### 11.1 Genuinely-unanswerable items for the user (MAINTAINER DECISIONs)

These are intent/judgment calls this read-only plan cannot and must not
pre-decide; each surfaces at its gate:

- **MAINTAINER DECISION (G1, Step 1):** which BD-185-attempt decisions are
  "preapproved good" and retained. Intent-dependent.
- **MAINTAINER DECISION (G2a, Step 2):** the prison directory PATH/NAME and the
  exact membership set (incl. which `archive/` docs are "superseded" → prison
  vs "non-superseded" → stay). Judgment + intent.
- **MAINTAINER DECISION (G3, Step 3):** which surfaced problems are in scope to
  fix (the surfacing standard: the user decides what to act on).
- **MAINTAINER DECISION (G4, Step 5):** authorize the architect phase spawn.
- **MAINTAINER DECISION (G5, Step 5):** resolve any `DESIGN CONFLICT` and any
  boundary-moving / rule-changing fix.
- **MAINTAINER DECISION (G9, Step 9):** BD-185 wipe vs salvage (bias: complete
  redo; salvage only for an independently-proven-correct named artifact).
- **MAINTAINER DECISION (standing, from investigation plan §9):** segment
  GRANULARITY (9 researcher + 9 architect). The shared standard, reconciliation,
  and gates hold at any granularity; re-granulating is low-cost at G0.

---

## 12. AFFECTED FILES

**Written by this pass (exactly one):**
- `maintenance-docs/v11-implementation/PLAN-BD-195-EXECUTION.md` (this doc).

**Docs this plan SCHEDULES later steps to produce** (named for the user's
forward visibility; all workflow artifacts under
`maintenance-docs/v11-implementation/`, sweeping to `archive/v11/` at ship):
- `AUDIT-BD-195-RETAINED-DECISIONS.md` (Step 1)
- `AUDIT-BD-195-SUPERSEDED-MAP.md` (Step 1b — the dedicated whole-repo
  supersession-mapping pass's factual superseded→superseding map + evidence)
- `AUDIT-BD-195-R7-PREREAD.md` (R7 scoped pre-read — epicenter retained-decision
  leads + epicenter context; one of the three parallel pre-prison passes)
- A prison directory (path a Step-2 user decision; §4.3 constraints) +
  `AUDIT-BD-195-PRISON-MANIFEST.md` (Step 2)
- 9 × `RESEARCH-BD-195-SEGMENT-R<1..9>-<short>.md` +
  `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (Step 3)
- 9 × `ARCHITECTURE-BD-195-SEGMENT-A<1..9>-<short>.md` +
  `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md` (Step 5)
- `PLAN-BD-195-FIX-IMPLEMENTATION.md` (Step 6)
- `IMPLEMENTATION-REPORT-BD-195-<commit-id>.md` per Step-7 commit;
  `PACK-REVIEW-BD-195-*` per Step-7 review cycle
- `PACK-REVIEW-BD-195-FINAL.md` + `AUDIT-BD-195-FINAL.md` (Step 8)

**Product surfaces this plan SCHEDULES Step 7 to touch** (the actual fix
targets — defined by the Step-5 reconciled fix design, NOT pre-judged here):
across `project-template/`, `scripts/` (incl. `validate-pack.py` + `lib/` +
tests), `pack-ops/`, `supporting-docs/`, pack-root + project-template trinity/
quad, `.github/` workflows + issue forms, and the `maintenance-docs/archive/`
remainder (narrowest user-gated edits per §2.6). The blast radius is the
Step-5 deliverable; this plan does not enumerate it.

**PM-only edits this plan SCHEDULES Pack Chat to make directly:**
- The Step-2 prison move (destructive; G2b-gated).
- BD-185 status-line note recording the Step-9 decision (Step 9).
- BD-195 `Status: Open → Resolved` in `pack-ops/BACKLOG.md` (Step 8, implicit
  batch-completion flip).
- Any §10 one-line edit to `PLAN-BD-195-INVESTIGATION.md` (a workflow artifact;
  if the user approves landing the reconciliation refinements there).

**No PM-only file is edited by THIS pass.** `pack-ops/BACKLOG.md`, README
version table, trinity files, etc. are read-only here (commit-discipline skill
§4 + CLAUDE.md PM-only list). This pass writes only its single output doc.

---

## 13. CONSOLIDATED STEP-BY-STEP EXECUTION TABLE

The whole plan as ONE navigable table — one row per discrete action (the §6
agent-pass rows + the §7 user gates where the gate IS the action). Reading this
table top-to-bottom is the execution order. Column 4 applies the rule:
parallelize ONLY where there is no dependency AND no quality loss; if a row is
not hard-blocked but would BENEFIT (even slightly) from another completing
first, it is sequenced AFTER and NOT parallelized.

Action IDs: `R7pre` = R7 scoped pre-read; `S-supmap` = whole-repo supersession-mapping pass; `S1x` = Step-1 extractor; `G#` = the
§7 user gates; `Rn` / `An` = researcher / architect segments; `RECr` / `RECa`
= reconcilers; `S6p` = Step-6 fix-planner; `S7c/S7r/S7f/S7e` = Step-7 coder /
group-reviewer / fix-coder / end-of-batch reviewer; `S8r/S8a` = Step-8 final
review / pristine-bar audit.

| Action | What it does | Who does it | Blocked by + why | Parallelizable |
|---|---|---|---|---|
| **G0** | Approve THIS master plan before any action runs | User reviews + approves | None | No — sequential gate; everything below is blocked by it (this plan is the authority for the sequence). |
| **R7pre** | Scoped pre-read of the epicenter → `AUDIT-BD-195-R7-PREREAD.md`: `retained-decision` LEADS that enrich Step 1 (non-blocking) + epicenter-deep CONTEXT that enriches the supersession map (NOT prison-candidate identification — that is `S-supmap`) | `pack-docs-researcher` (1, fresh, bg) | G0 (plan must be approved) — its scope/standard come from this plan | **Yes — parallel with S1x + S-supmap** (all three read-only over the pre-prison repo, no inter-dependency). Must complete before S2-prop (its context feeds the membership proposal). |
| **S1x** | Extract preapproved good BD-185 decisions IN PLACE → `AUDIT-BD-195-RETAINED-DECISIONS.md` (before prisoning) | `pack-docs-researcher` (1, fresh, bg) | G0 — needs the approved plan; reading sources IN PLACE requires they not yet be prisoned (Step 2 not run) | **Yes — parallel with R7pre + S-supmap** (all read-only over the pre-prison repo; R7pre's `AUDIT-BD-195-R7-PREREAD.md` enriches but does not block — the extractor reads the epicenter directly). Must complete before G1. |
| **S-supmap** | Read INSIDE every doc across the ENTIRE repo + read `git log` → `AUDIT-BD-195-SUPERSEDED-MAP.md`: FACTUAL "doc X superseded by doc Y/Z" mapping + evidence (in-doc statement and/or commit message); NO opinion on purpose/why | `pack-docs-researcher` (1, fresh, bg) | G0 — needs the approved plan; reads sources IN PLACE (prison not yet created) | **Yes — parallel with S1x + R7pre** (all read-only over the pre-prison repo, no inter-dependency). Must complete before S2-prop (its map is the membership evidence). |
| **C1** | Commit the Retained-Decisions doc + the supersession map | Pack Chat stages + commits (with user approval) | S1x + S-supmap — needs both docs | No — sequential after S1x + S-supmap (both pre-prison read-only passes complete). |
| **G1** | Confirm the Retained-Decisions set (add/remove/adjust) | User confirms | S1x (+ C1) — confirms the produced doc | No — sequential gate; Step 2 membership leans on the confirmed set. |
| **S2-prop** | ASSEMBLE the prison-membership PROPOSAL (PATH + exact set) from the supersession map (`AUDIT-BD-195-SUPERSEDED-MAP.md`) + Step-1 provenance + R7 epicenter context; verify path vs validator globs. Pack Chat does NOT identify | `S-supmap` agent IDENTIFIED the supersession; Pack Chat ASSEMBLES the proposal | G1 + S-supmap — the retained set must be confirmed so its sources can be safely prisoned, AND the supersession map (the membership evidence) must exist | No — sequential after G1 + S-supmap (hard-block: prisoning a source before its decision is retained loses the decision; and the map is the membership evidence). |
| **G2a** | Confirm the prison PATH/NAME + exact membership | User confirms | S2-prop — confirms the proposal | No — sequential gate. |
| **G2b** | Approve the destructive prison MOVE (per-action) | User approves | G2a — approves moving the confirmed set | No — sequential gate (no-destructive-without-approval). |
| **S2-mv** | Perform the user-approved destructive `git mv` into the prison; emit `AUDIT-BD-195-PRISON-MANIFEST.md` (moved paths + inbound-ref flags); land any validator glob-exclusion | Pack Chat performs (agents never move) | G2b — move runs only on approval | No — sequential after G2b. |
| **C2** | Commit the prison move + manifest doc (+ any validator exclusion; per-check tests + manifest regen IF `scripts/` touched) | Pack Chat stages + commits (with user approval) | S2-mv — needs the move done | No — sequential after S2-mv. |
| **R1…R9** | 9 researcher segments audit their owned paths (broad+deep, lenses A–E) → 9 `RESEARCH-BD-195-SEGMENT-R<N>` reports | `pack-docs-researcher` × 9 (fresh per segment, bg) | C2 — the prison must EXIST + be populated so the exclusion (and QG-5 baseline) is well-defined | **Yes — parallel with each other**, EXCEPT: **R6 is sequential — after R5** (R6 encodes invariants R5 defines; running R6 after R5 lets it cross-reference R5 findings for the Lens-E lock-step — slight-benefit + ENCODING dependency); R7-full is sequential — after C2 (it audits only the post-prison epicenter remainder). R1–R5, R8, R9 run fully in parallel. |
| **RECr** | Reconcile the 9 segment reports → ONE de-duplicated `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`; enforce QG-1/3/4/5/8 | `pack-docs-researcher` OR `pack-architect` (1, fresh, bg) | R1…R9 (ALL) — needs every segment's findings + coverage maps as input | No — sequential after ALL of R1…R9 (hard-block: cannot reconcile partial input). |
| **C3** | Commit the 9 researcher reports + the reconciled problem list | Pack Chat stages + commits (with user approval) | RECr — needs the reconciled list | No — sequential after RECr. |
| **G3** | Review the ONE reconciled problem list; decide scope to fix | User reviews + decides | RECr (+ C3) — reviews the produced list | No — sequential gate (user decides what is in scope before fixes are designed). |
| **G4** | Approve spawning the architect phase (architect-spawn protocol) | User approves | G3 — architect designs fixes only for the user-scoped problems | No — sequential gate (architect-spawn is user-gated; it commits the pipeline). |
| **A1…A9** | 9 architect segments design fixes for their matching reconciled problems (Fix design + Blast radius) → 9 `ARCHITECTURE-BD-195-SEGMENT-A<N>` reports | `pack-architect` × 9 (fresh per segment, bg) | G4 (phase approval) + RECr (the reconciled problems are the input) | **Yes — parallel with each other**, EXCEPT any cross-segment fix the reconciliation flagged as coupled runs with an explicit dependency edge (that A-segment sequences after its prerequisite — slight-benefit/hard-input per the named edge). Uncoupled A-segments run fully in parallel. |
| **RECa** | Reconcile the 9 architect reports → ONE `ARCHITECTURE-BD-195-RECONCILED-FIX-DESIGN.md` (global blast-radius union + QG-7 topological order); enforce QG-6 | `pack-architect` (1, fresh, bg) | A1…A9 (ALL) — needs every fix design + blast radius as input | No — sequential after ALL of A1…A9 (hard-block: cannot reconcile partial fix designs). |
| **C4** | Commit the 9 architect reports + the reconciled fix design | Pack Chat stages + commits (with user approval) | RECa — needs the reconciled design | No — sequential after RECa. |
| **G5** | Review the ONE fix design; resolve DESIGN CONFLICTs + boundary/rule-change fixes | User reviews + resolves | RECa (+ C4) — reviews the produced design | No — sequential gate. |
| **S6p** | Sequence the approved fix design into ordered commits → `PLAN-BD-195-FIX-IMPLEMENTATION.md` (per-commit verification + cadence boundaries) | `pack-planner` (1, fresh, bg; DISTINCT from this planner) | G5 — sequences only the user-approved fix design | No — sequential after G5 (hard-input: the approved design). |
| **C5** | Commit the fix-implementation plan | Pack Chat stages + commits (with user approval) | S6p — needs the plan | No — sequential after S6p. |
| **G6** | Review the commit-sequenced fix plan (planner→user→coder) | User reviews + approves | S6p (+ C5) — reviews the produced plan | No — sequential gate (last cheap redirect before implementation). |
| **S7c** | Implement one commit's slice (working-tree edits + IMPL-REPORT); run PREFLIGHT (validate-pack + per-check tests + manifest as applicable) | `pack-coder` (FRESH per commit, bg) | G6 — implements only the approved plan; each commit blocked by the prior committed state (validate-pack green at every commit ⇒ commits land one at a time) | **CODING may overlap for proven-disjoint groups ONLY** (Step-6 plan proves no shared file + no shared ENCODING surface → two coders EDIT concurrently in the shared tree without collision); **ALL COMMITS / per-group reviews-of-landed-state / triage (G7a) / commit gates (G7b) SERIALIZE** — one commit at a time, each an atomic green checkpoint. Dependent/overlapping groups are fully sequential. |
| **G7b** | Approve each Step-7 commit (with next-steps plan) | User approves; Pack Chat stages + commits | S7c (or S7f) — approves the produced edits | No — sequential gate per commit. |
| **S7r** | Inline review of a completed fix GROUP → `PACK-REVIEW-BD-195-<scope>` | `pack-reviewer` (one per fix group, fresh, bg) | The group's S7c commits (ALL in that group) — reviews the landed group; gates the next DEPENDENT group's coding | No — sequential at each group boundary for DEPENDENT groups (hard-block: cannot review an incomplete group; gates the next dependent group). Proven-disjoint groups are EXEMPT — their CODING may overlap this review; but triage (G7a) + any fix commit still serialize. |
| **G7a** | Per fix group: triage the reviewer findings (FIX/SKIP, default FIX-ALL) | Pack Chat triages → User approves the triage | S7r — triages the produced findings | No — sequential gate (triage gate between reviewer and fix-coder). |
| **S7f** | Apply the triaged fixes for a group (working-tree edits + fix IMPL-REPORT); PREFLIGHT | `pack-coder` (fix-coder, FRESH per fix, bg) | G7a — applies only the approved triage | No — sequential after G7a (hard-input: the approved triage). |
| **S7e** | End-of-batch review over the FULL BD-195 fix set (cross-group interactions) → review doc | `pack-reviewer` (1, fresh, bg) | ALL Step-7 fix groups complete (every S7c/S7r/S7f) — it is the once-per-batch pass after all per-group cycles | No — sequential after all groups (hard-block: cannot do end-of-batch before the batch is done). |
| **G8a*** | Triage the end-of-batch + final-review findings (if any); fix-coder applies | Pack Chat triages → User approves → `pack-coder` (fresh, bg) applies | S7e / S8r findings — triages what those passes produced | No — sequential gate (recurs if Step-8 passes surface findings; routes back into a fix cycle until clean). |
| **S8r** | Final review of the COMPLETE fix set vs the reconciled fix design (did every designed fix land; regressions; ENCODING lock-step intact) → `PACK-REVIEW-BD-195-FINAL.md` | `pack-reviewer` (1, fresh, bg) | S7e (the Step-7 batch — incl. any end-of-batch fix — must be complete) | **May run in parallel with S8a** (different lenses — review-the-fixes vs audit-the-pristine-bar; no shared output, no quality loss). Sequential — after S7e. |
| **S8a** | From-scratch pristine-bar audit (seeds swept whole-repo; no in-scope reference into the prison; trinity/quad parity; validate-pack + all per-check tests + fixture-manifest verify + CI Check 42 green) → `AUDIT-BD-195-FINAL.md` | `pack-architect` (auditor lens) (1, fresh, bg) | S7e (the batch must be complete to audit the end state) | **May run in parallel with S8r** (independent lens; no shared output). Sequential — after S7e. |
| **Cn-1** | Commit the final review + audit docs | Pack Chat stages + commits (with user approval) | S8r + S8a — needs both docs | No — sequential after S8r + S8a. |
| **G8b** | Review the audit verdict; clean ⇒ BD-195 done | User reviews | S8r + S8a (+ Cn-1) — reviews the produced verdict | No — sequential gate (if not clean, findings re-enter the G8a* fix cycle). |
| **Cn** | Flip BD-195 `Status: Open → Resolved` in `pack-ops/BACKLOG.md` (PM-only; implicit batch-completion flip) | Pack Chat edits directly + commits (with user approval) | G8b — flip happens only on a clean verdict | No — sequential after G8b. |
| **G9** | Decide BD-185 wipe vs salvage (bias: complete redo; salvage only for an independently-proven-correct named artifact) | Pack Chat FRAMES (no recommendation) → User DECIDES | Cn (BD-195 must be Resolved/pristine first) — the decision seeds the SEPARATE BD-185 restart | No — sequential terminal gate (the pristine baseline must exist before the wipe-vs-salvage call is meaningful). |

> *G8a is shown once but recurs: any findings from S7e, S8r, or S8a route
> through a triage → fix-coder → commit micro-cycle (the §7 cadence) until the
> Step-8 verdict is clean. It is not a one-shot row.

**Parallelization summary (the only genuine speedups without quality loss):**
(1) **S1x ∥ R7pre ∥ S-supmap** — the three pre-prison read-only passes run in
parallel (no inter-dependency; all read the repo IN PLACE before the Step-2
move); all three complete before S2-prop. (2) **R1…R9** in parallel — except
R6 sequences after R5 (ENCODING cross-reference benefit) and R7-full sequences
after the Step-2 prison move (post-prison remainder). (3) **A1…A9** in parallel
— except coupled segments follow their named dependency edge. (4) **S8r ∥
S8a** — the two final passes are independent lenses. (5) Within Step 7, the
CODING of two fix GROUPS may overlap ONLY if the Step-6 plan proves
non-overlapping surfaces (no shared file, no shared ENCODING surface); even
then, ALL COMMITS, per-group reviews-of-landed-state, triage gates, and G7b
commit gates SERIALIZE (one commit at a time, each an atomic green checkpoint) —
dependent/overlapping groups are fully sequential. Everything else is
sequential — each step's output is the next step's required input, or a state
(prison populated; group complete; verdict clean) must exist first, or it is a
user gate.

