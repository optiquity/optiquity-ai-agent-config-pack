# ARCHITECTURE — Skill and Agent Maintainability Principle

**Type:** Read-only architecture design (pack-architect output).
**Status:** Draft for pack-planner sequencing. No implementation in this doc.
**Date:** 2026-05-11.
**Branch context:** `v11-dev`.

This design codifies the user-stated maintainability principle for skills,
agents, and their relationships, surfaces the tensions in that principle,
chooses documentation locations and enforcement signals with explicit
defense, and conflict-checks against the existing pack rule set.

It does not propose a planner sequence — that work belongs to
`pack-planner` once this design is accepted.

The design must be read together with:

- `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`
  (the 5+3 model — provides the structural underpinnings the principle
  defends).
- `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §0 batch
  table and §7.3 (post-planner additions) — the recent-history evidence
  base for what "easy" looks like today.
- `project-template/docs/pack/PLATFORM-SKILLS.md` lines 1-563 (operational
  truth for skill selection; §"Extending this file" line 554 is BD-149's
  hosting site).
- `BACKLOG.md` BD-141 / BD-156 / BD-157 / BD-158 — worked examples of
  mechanical small additions that calibrate the threshold.
- `CLAUDE.md` (pack-repo root) "Pack memory" section, lines 93-174 — the
  governance home for any new standing rule.
- `PACK-AGENTS.md` — agent routing and permission rules (the surface that
  will reference the principle when prompting reviewers).
- `PACK-CHAT.md` — Pack Chat behavioral rules (the surface that will
  reference the principle when triaging new asks).

---

## 0. Executive summary

1. **The principle is not yet codified** anywhere in trinity governance,
   PACK-CHAT.md, PACK-AGENTS.md, or pack memory. A grep across those
   files for `maintainability`, `easy to add`, `scope creep`,
   `lightweight`, and `extensibility` returns zero hits (verified
   2026-05-11). The principle exists implicitly in the 5+3 model
   (`ARCHITECTURE-SKILL-DIMENSIONS.md` §3 / §6) and in worked examples
   (BD-141, BD-156, BD-157, BD-158) but has no enforceable home.
2. **One quotable sentence does the work.** The principle should ship as
   a single short rule, not a new policy doc. The structural defense of
   the principle (the 5+3 model) is already documented; the rule simply
   names the property the model protects.
3. **One canonical home, two thin pointers.** The full rule lives in the
   pack-repo trinity "Pack memory" section
   (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` lines 93-174). Two
   single-line pointers (`PACK-CHAT.md`, `PACK-AGENTS.md`) reference the
   home by name. The duplication tax is acceptable because the pointers
   are one line each and the trinity itself is governed by the existing
   trinity rule (so all three pack-repo trinity copies stay in sync
   automatically).
4. **One machine check, one human check, one cultural check.** Machine:
   `validate-pack.py` gains a single check that fails when a "small
   skill addition" PR also adds a new validator, a new doc file, or a
   new top-level dimension — a footprint-sniffer, not a content checker.
   Human: `pack-architect` and `pack-reviewer` prompts already include
   `architecture-review` skill loading; that skill's existing
   "minimum-viable-change" methodology is the human enforcement signal
   (see `architecture-review/SKILL.md` if present; this design treats
   it as the carrier). Cultural: Pack Chat's existing "PM-only files"
   approval gate naturally surfaces accumulation attempts.
5. **No new docs. No new scripts. One new validator check, possibly
   zero.** The design intentionally rejects creating
   `MAINTAINABILITY.md`, `SKILL-AUTHORING.md`, or any sibling
   architecture doc. Adding more docs to enforce a "no scope creep" rule
   is the purest possible form of the violation it forbids.


---

## 1. Diagnosis — what does "easy" look like today, and what threatens it

This section calibrates the principle against the recent worked examples
in `BACKLOG.md` and `PLAN-SKILL-DIMENSIONS.md` §7.3, then identifies the
structural and behavioral forces that pull the pack toward heavier
maintenance.

### 1.1 Worked examples — the calibration set

The four most recent skill-shaped additions establish the "easy" floor.
File counts and edit shapes derived from `PLAN-SKILL-DIMENSIONS.md` §0
batch table and the BD entries in `BACKLOG.md`:

| BD | Skill / change | New files | Edited files | Cross-edits to existing skills | Validator changes |
|---|---|---|---|---|---|
| BD-141 | `python_data_marker_detected()` helper | 0 | 3 (`scripts/lib/detect.sh` + 2 callers) | 0 | 0 |
| BD-156 | `protobuf-patterns` skill | 3 (SKILL.md trinity) | 4 (PLATFORM-SKILLS.md row + detect helper + add-capability row) | 3 (`grpc-patterns` × trinity refocus) | 0 (existing Check 31 catches it) |
| BD-157 | `apple-swiftdata-patterns` skill | 3 (SKILL.md trinity) | 3 (PLATFORM-SKILLS.md row + detect helper + init wiring) | 0 | 0 |
| BD-158 | `swift-concurrency-patterns` skill | 3 (SKILL.md trinity) | 3 (PLATFORM-SKILLS.md row + init + add-capability) | 6 (`swift-best-practices` × 3 + `apple-architecture-core` × 3 strip-and-cross-reference) | 0 |

The pattern is consistent: a new skill is **3 SKILL.md files plus 3-4
table edits plus 0-6 cross-edits to adjacent skills**, with validator
changes only when the skill introduces a new structural mechanism (none
of the four did). The BD-141 helper is even smaller — three edits to
two scripts, no new files.

This is the floor. Any maintainability rule that does not preserve this
floor is wrong.

### 1.2 Counter-examples — what "heavy" looks like

The skill-dimensions reframe (BD-142 + the surrounding 11 batches per
`PLAN-SKILL-DIMENSIONS.md` §0) and the migrator framework (BD-119) are
the heavy end of the spectrum. They are heavy for legitimate reasons:
BD-142 reframes the foundational model the lighter additions sit on;
BD-119 introduces a sequencer the rest of the migrator surface composes
against. **Heavy is not banned — heavy without a structural payoff is
banned.**

The principle must distinguish "heavy because it changes the model" from
"heavy because nobody pushed back on accumulation." The threshold
conditions in §4 below operationalize that distinction.

### 1.3 The forces that pull toward heavy maintenance

Without the principle codified, the following forces accumulate
unchecked:

1. **Validator-creep.** Every new structural convention can be
   validated. Past v11 work added Checks 21 / 27 / 28 / 29 / 30 / 31 in
   roughly 6 months (validate-pack.py header at line 5; verified by the
   `def check_*` listing). Each individual addition was justified;
   collectively they make the pack harder to evolve because every model
   change must reckon with N validators.
2. **Doc-creep.** `maintenance-docs/v11-implementation/` currently holds
   30+ files (verified by directory listing). Each is a justified
   record of in-flight work; together they make "the design" harder to
   find for a new contributor. The absence of a "no new doc unless"
   rule is what enabled the accumulation.
3. **Trinity-rule collateral cost.** The trinity rule (CLAUDE.md /
   AGENTS.md / GEMINI.md, pack-repo lines 70-76) is non-negotiable and
   correct, but every new top-level governance rule multiplies by 3 the
   maintenance cost of touching that rule. Codifying the principle in
   the trinity is the right place precisely because it raises the cost
   of adding the *next* governance rule — the multiplier is a feature.
4. **PM-only file ratchet.** The "What agents must never modify"
   list (CLAUDE.md lines 82-86) grew across versions. Each addition was
   defensible; the cumulative effect is that more and more pack
   evolution requires Pack Chat-only edits, slowing parallel work.
5. **Skill-suffix proliferation.** The four-suffix catalog
   (`*-best-practices`, `*-language`, `*-architecture`, `*-patterns`) is
   the visible symptom of historical accumulation. BD-149 codifies the
   convention without renaming; BD-155 (v12-deferred) is the rename
   migration. The principle's job is to prevent a fifth suffix from
   joining without a structural reason.

### 1.4 The user's stated tensions — reframed

The brief identifies four tensions; this design names how each is
resolved by the choices in §3-§7 below:

1. **Easy + detail-preserving.** The 5+3 model already separates
   *adding* a skill (mechanical: trinity SKILL.md + table row + maybe a
   marker helper) from *changing the model* (architectural pass). The
   principle's job is to keep the mechanical path mechanical.
   Detail-preservation is enforced by skill-internal authoring
   (SKILL.md content is not bounded by the principle); the principle
   bounds *the surrounding scaffold*, not the skill content itself.
2. **Findable + non-bloated.** Resolved by the one-canonical-home
   choice (§5). Pack memory in CLAUDE.md is read at every agent session
   (per `PACK-AGENTS.md` line 149); pointers are one line.
3. **Not forgotten + not duplicated.** Resolved by piggybacking on the
   trinity rule (which already enforces sync) and by the validator
   check (which fires when the rule is violated, ensuring it is
   surfaced rather than silently drifting).
4. **Documentation + script enforcement.** Resolved by §6 — the script
   enforcement is a footprint sniffer, not a content checker. The
   reviewer / architect human enforcement carries the content judgment
   the script cannot.


---

## 2. The principle — quotable form

The rule, in its canonical wording, is one paragraph plus a one-line
quotable summary. Both ship together; the summary is what gets quoted in
agent prompts and PR conversations, the paragraph is what ships in pack
memory.

### 2.1 Quotable summary (one sentence)

> **Adding or modifying a skill, agent, or their relationships is a
> mechanical edit by default; structural change is opt-in and must be
> defended.**

20 words exactly. Designed to be quotable verbatim.

### 2.2 Canonical paragraph (the pack-memory entry)

> **Skill and agent maintenance is mechanical by default.** Adding,
> modifying, or relating skills and agents must be a mechanical edit:
> trinity SKILL.md / agent-file edits, one PLATFORM-SKILLS.md row, an
> optional marker helper in `scripts/lib/detect.sh`, and any necessary
> cross-edits to adjacent skills. New top-level docs, new validators,
> new dimensions, or new conventions are **structural changes** and
> require an architecture pass with a defended scope. The 5+3 model in
> `project-template/docs/pack/PLATFORM-SKILLS.md` is the structural
> contract that makes the mechanical path possible; preserve it.

### 2.3 What the principle does NOT say

Explicit non-claims, to prevent over-application:

- It does **not** cap SKILL.md content size. Skills can carry as many
  rules as the domain warrants; rule depth is a content concern, not a
  scaffold concern.
- It does **not** forbid heavy work. BD-119 (migrator framework) and
  BD-142 (5+3 reframe) are correctly heavy; the principle requires that
  weight be *named and defended*, not avoided.
- It does **not** require the mechanical path to stay mechanical
  forever. When a structural change is approved, the mechanical
  baseline shifts; the principle re-applies to the new baseline.
- It does **not** eliminate Pack Chat / pack-architect judgment. The
  threshold conditions in §4 are signals, not gates; the architect /
  Pack Chat decides whether a borderline case is structural.


---

## 3. Threshold conditions — mechanical vs structural

A change is **mechanical** if every condition in §3.1 is true. A change
is **structural** if any condition in §3.2 is true. Borderline cases
(some §3.1 yes, some §3.2 yes) are surfaced to `pack-architect` for a
read-only design pass before `pack-coder` executes.

### 3.1 Mechanical signals — all must be true

The change is mechanical if all of the following hold:

1. **Trinity scope.** Edits to SKILL.md / agent-file / PLATFORM-SKILLS.md
   apply uniformly to all three trinity copies (Claude / Codex /
   Gemini) — no asymmetry.
2. **Existing dimension fit.** The new or modified skill loads via an
   existing D1-D5 selector or an existing intersection-table predicate
   shape. No new dimension, no new load mechanism.
3. **Existing pattern fit.** The skill follows one of the three
   organization patterns (`core+layers`, `siblings-without-core`,
   `standalone`) per `ARCHITECTURE-SKILL-DIMENSIONS.md` §2 without
   inventing a fourth.
4. **Existing naming convention fit.** The skill name uses one of the
   four codified suffixes (`*-best-practices`, `*-language`,
   `*-architecture`, `*-patterns`) per BD-149's codification.
5. **Existing validator coverage.** Validate-pack.py's existing checks
   (notably the upcoming Check 31 per BD-146) catch consistency drift
   without modification.
6. **Bounded file footprint.** The change touches:
   - 0-3 new files (typically: 3 trinity SKILL.md copies, OR 0 for
     content-only edits to existing skills, OR 1 helper function)
   - 0-10 edited files (typically: PLATFORM-SKILLS.md + 1-2 scripts +
     up to 6 trinity-replicated cross-edits to adjacent skills)
   - 0 new top-level docs in `maintenance-docs/`, `supporting-docs/`,
     pack root, or `project-template/docs/`
   - 0 new scripts (helpers added to existing `lib/` files do not count
     as new scripts)
   - 0 new validate-pack.py checks
7. **No agent-permission expansion.** No new entry in CLAUDE.md
   "What agents must never modify" list (lines 82-86); no new entry in
   PACK-AGENTS.md "PM-only files" list (lines 139-142); no change to
   the trinity rule, the agents-never-commit rule, the no-solutions
   rule, or any other rule in the "Pack memory" section.

The four worked examples (BD-141, BD-156, BD-157, BD-158) all satisfy
every condition in §3.1.

### 3.2 Structural signals — any one triggers an architect pass

A change is structural if any of the following hold:

1. **New top-level dimension or load mechanism.** Adding D6, adding a
   new load mechanism alongside Tier 0 / dimensional / trigger /
   intersection.
2. **New skill-organization pattern.** Adding a fourth pattern beyond
   `core+layers` / `siblings-without-core` / `standalone`.
3. **New skill-name suffix.** Adding `*-foo` outside the four codified
   suffixes.
4. **New validator check.** Any addition to `scripts/validate-pack.py`
   that introduces a new `check_*` function, regardless of triggering
   BD.
5. **New top-level doc.** Adding a new `.md` in pack root,
   `supporting-docs/`, `project-template/docs/`, or
   `maintenance-docs/v11-implementation/` that is not an
   `ARCHITECTURE-*.md` / `PLAN-*.md` / `IMPLEMENTATION-REPORT-*.md` /
   `PACK-REVIEW-*.md` / `AUDIT-*.md` / `RESEARCH-*.md` /
   `*-DISCOVERY.md` produced by the existing architect / planner /
   coder / reviewer / auditor / docs-researcher workflow.
6. **New script.** Adding a new top-level `scripts/*.sh` or `scripts/*.py`
   (helpers in `scripts/lib/` are not new scripts; they are
   library extensions).
7. **Trinity-asymmetry change.** Any change that intentionally diverges
   one trinity copy from the others — even a justified divergence
   needs the architect pass to record the justification.
8. **Migrator behavior change.** Any change that requires a new
   migrator stage, a new manifest entry, or a new advisory file in
   `migrate-vN-to-vM.sh` — these touch BD-119 framework contracts
   (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`).
9. **PM-only file expansion.** Any addition to the agents-never-modify
   list or the PM-only file list in PACK-AGENTS.md.
10. **Agent-roster change.** Adding or removing a pack agent or a
    project-template agent (a pack-architect / pack-planner / pack-coder /
    pack-reviewer / pack-docs-researcher peer, or one of the 16
    project-template agents per `README.md` Repository Layout).

The 5+3 reframe (BD-142) was structural by signals 1, 2, and 5 — and
correctly received a full architect pass before any coder work.

### 3.3 Borderline cases — the architect-pass gate

A few patterns sit on the boundary; the principle treats them as
borderline by design:

- **Promoting a skill from dimensional to Tier 0** — looks mechanical
  (one PLATFORM-SKILLS.md row move) but is a load-semantics change. The
  4 promotions in BD-142 (security-patterns, api-design, debugging,
  ui-test-strategy) were correctly bundled into the architect-pass
  reframe, not shipped as mechanical edits.
- **Adding a new intersection-table row** — mechanical IF the predicate
  composes existing dimension selectors (BD-156 / BD-157 example);
  structural IF the predicate introduces a new selector primitive
  (e.g., a "host language family" union that doesn't exist today).
- **Renaming a skill** — never mechanical even when the new name is in
  the codified suffix set, because rename touches the migrator surface
  (per BD-035 / BD-147 history). Always route through `pack-architect`
  for the migrator-impact assessment.

These cases are listed in the principle's pack-memory entry as
"if in doubt, ask the architect" — they are not enumerated, they are
characterized.


---

## 4. Documentation location — defended choice

The user's verbatim direction includes "These rules must be easily found
and not forgotten but not bloat the docs. Avoid duplicating the rules
without a really good reason." This section enumerates every plausible
home, scores each against findability / non-bloat / non-duplication,
and defends the recommendation.

### 4.1 The candidate locations

| # | Location | Findability | Bloat risk | Duplication tax |
|---|---|---|---|---|
| L1 | Pack-repo trinity `## Pack memory` (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` lines 93-174) | High — every pack agent reads this at session start (per `PACK-AGENTS.md` line 149) | Low — adding ~10 lines to a section that already carries 14 entries | Low — trinity rule already enforces sync (zero new tax) |
| L2 | `PACK-CHAT.md` "Behavioral rules" (lines 50-99) | Medium — only Pack Chat reads at startup, not all agents | Medium — section already has 8 numbered rules | Medium — would duplicate the trinity entry |
| L3 | `PACK-AGENTS.md` "Agent permission rules" (lines 109-143) | High for agents — every agent reads PACK-AGENTS.md | Medium — section is currently scoped to permissions, not authoring discipline | High — would duplicate the trinity entry verbatim |
| L4 | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` "Project memory" | None for pack maintenance | High — pollutes project-template trinity with pack-ops content (violates `feedback_ops_product_separation.md`) | N/A (rejected on ops/product separation grounds) |
| L5 | `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" (line 554) | Medium for skill authors specifically; low for agent authors and validator authors | Low — section is already the BD-149 home | Medium — partial duplication with trinity entry; covers skill axis only |
| L6 | `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6 or new section | Low — historical design records are not consulted at agent session time | Low — extending an existing doc | High — design records do not survive into v12+ as the operative rule |
| L7 | New dedicated doc (`MAINTAINABILITY.md` or `SKILL-AUTHORING.md`) | Variable — depends on who points at it | High — new doc joins the 30-file `maintenance-docs/` accumulation | The pure form of the violation the rule forbids |
| L8 | User auto-memory (`/Users/david/.claude/projects/.../memory/feedback_*.md`) | High for the user; zero for other contributors / agents | Low | Single-user — does not survive across the team |

### 4.2 Recommendation — L1 canonical, L3 single-line pointer, L5 single-line pointer

**Canonical home: L1** (pack-repo trinity `## Pack memory`).

**Why L1 wins:**

1. Every pack agent reads it at session start (verified at
   `PACK-AGENTS.md` line 149). Maximum findability for the audience that
   most needs the rule (agents writing skill / agent additions and
   reviewers checking them).
2. The trinity rule already governs sync — adding the entry costs zero
   new sync burden because the trinity rule is already paid.
3. The "Pack memory" section's existing entries (14 entries spanning
   workflow / agent invocation / repo conventions / project goals) are
   the same shape as this principle: short, quotable, authoritative.
   The principle slots into "Repo conventions" naturally.
4. It survives across versions — pack memory has carried entries since
   v9.x and continues to.

**Single-line pointer: L3** (`PACK-AGENTS.md` "Agent permission rules"
section).

**Why a pointer, not a copy:**

PACK-AGENTS.md is the file `pack-architect` and `pack-reviewer` consult
when constructing skill / agent change reviews. A one-line cross-reference
("Skill / agent additions follow the maintainability principle in
CLAUDE.md / AGENTS.md / GEMINI.md `## Pack memory`.") gives reviewers
the locator without copying the rule. The duplication tax is one line,
trivially paid.

**Single-line pointer: L5** (`project-template/docs/pack/PLATFORM-SKILLS.md`
"Extending this file" section).

**Why a pointer, not a copy:**

PLATFORM-SKILLS.md is read by skill authors directly. BD-149 is
already opening this section; adding a one-line pointer in the same BD
costs nothing extra. The pointer reads, in effect, "the structural
rules for new skills are codified here; the maintainability principle
governing whether a skill addition is mechanical vs structural is
recorded in the pack-repo trinity `## Pack memory`."

**Why no other locations.** L2 / L4 / L6 / L7 / L8 each fail at least
one of the three criteria. L7 in particular — a new dedicated doc — is
the configuration this design most actively rejects, because it would
be the principle's first violation.

### 4.3 The duplication tax — accounted for

Three locations carry text:

- L1 (pack-repo trinity, three files): the canonical paragraph plus
  one-sentence summary. Lines added: ~10 per file × 3 = ~30 lines
  total. Sync burden: governed by the existing trinity rule; if a
  contributor edits one and not the others, validate-pack's existing
  Check 18 (trinity H2 parity, per `validate-pack.py` line 1163) does
  NOT catch H3-level prose drift — but that's a known limitation of
  the trinity rule across the board, not a new gap.
- L3 (PACK-AGENTS.md): one line.
- L5 (PLATFORM-SKILLS.md): one line, byte-identical across the trinity
  copies of PLATFORM-SKILLS.md (it's a single source of truth file
  with three distributed copies per Check 9 byte-identity rule).

Total prose footprint: ~35 lines across 5 files, 4 of which are
trinity-replicated. **The duplication tax is the cost of one trinity
sync — already paid by the trinity rule for any other addition.**

### 4.4 What the L5 PLATFORM-SKILLS.md pointer specifically says

The BD-149 host section ("Extending this file") will document the
naming convention and the structural rules for new skills. This design
recommends BD-149's prose include a one-line cross-reference at the end
of the section, in this shape:

> **Maintainability rule.** Adding a new skill is a mechanical edit
> when it fits the existing dimensions, patterns, and naming
> conventions documented above. See the pack-repo trinity (`CLAUDE.md`
> / `AGENTS.md` / `GEMINI.md` `## Pack memory`) for the full
> mechanical-vs-structural threshold.

That sentence is what BD-149 should incorporate; this design does not
re-author the BD-149 prose, only specifies the cross-reference shape.


---

## 5. Enforcement signals

The user's verbatim direction includes "scripts must do the right
thing." This section names what each enforcement layer does and — just
as importantly — what each does NOT do.

### 5.1 Machine enforcement — `validate-pack.py`

**One new check, possibly zero.** The principle is structural; most of
its violations show up as additions of *other* artifacts that existing
checks already see. The judgment call is whether validate-pack should
gain a footprint-sniffer that fires when a single PR adds:

- a new `scripts/validate-pack.py` `check_*` function, AND
- a new SKILL.md trinity, AND
- no `ARCHITECTURE-*.md` design record under `maintenance-docs/`

simultaneously. That conjunction is exactly the "scope creep on a
mechanical addition" pattern the principle forbids.

**Recommendation.** Defer the new validator check. Reasoning:

1. The check is brittle — it requires diff-time analysis (what files
   were added together), which validate-pack.py does not currently do
   (it operates on the working tree, not on the diff).
2. The check is GitHub-Actions-couplable instead, but adding a workflow
   step to run a "PR shape" linter is itself a structural change
   (signal §3.2 condition 5/6). Doing so to enforce the principle
   would be self-violating.
3. The existing Check 31 (BD-146) is the de facto enforcement: if a
   skill addition somehow leaves PLATFORM-SKILLS.md inconsistent with
   the SKILL.md inventory, Check 31 fails. That covers the
   structural-coherence side. The "did this PR add too many things"
   side is a human judgment, not a machine judgment.

**What scripts already do correctly.** The relevant existing
enforcement, listed for the planner so nothing is duplicated:

- `validate-pack.py` Check 9 (skill byte-identity across trinity) —
  catches drift in SKILL.md content between `.claude/skills/`,
  `.codex/skills/`, `.gemini/skills/`. Verified at `validate-pack.py`
  per the `def check_*` listing.
- `validate-pack.py` Check 18 (trinity H2 parity, line 1163) — catches
  trinity drift at H2-section level for CLAUDE.md / AGENTS.md /
  GEMINI.md.
- `validate-pack.py` Check 27 (agent canonical phrases, line 1303) —
  catches agent files that drift from their canonical-phrase block.
- BD-146's Check 31 (planned, per `PLAN-SKILL-DIMENSIONS.md` Batch 7) —
  catches skill / PLATFORM-SKILLS.md inventory drift.

These four together enforce the *structural integrity* the principle
protects. The principle itself does not need its own validator.

**Reserved option.** If post-v11.0 experience shows scope-creep PRs
slipping past human review, a future BD can revisit the "PR shape
linter" idea. Not in v11.0 scope.

### 5.2 Human enforcement — `pack-architect` and `pack-reviewer`

The principle ships in pack memory; every pack agent reads pack memory
at session start (per PACK-AGENTS.md line 149). That means:

- `pack-architect` reads it before designing, so design proposals
  internalize the mechanical-vs-structural distinction.
- `pack-reviewer` reads it before reviewing, so review reports surface
  scope creep as a finding category. The existing
  `architecture-review` skill (loaded by both per PACK-AGENTS.md
  lines 28-29) already encodes minimum-viable-change methodology;
  the principle gives the reviewer a quotable hook.
- `pack-planner` reads it before sequencing, so plans separate
  mechanical batches from structural batches explicitly (the
  `PLAN-SKILL-DIMENSIONS.md` §0 batch table is the existing shape).

**Reviewer prompt requirement.** Pack Chat's invocation prompts for
`pack-reviewer` should include a standing reviewer task: "Flag any
change to a skill, agent, or their relationships that exceeds the
mechanical-edit footprint per pack memory." This is one sentence in
the existing reviewer prompt template; no new template needed.

### 5.3 Cultural enforcement — Pack Chat triage

Pack Chat is the first reader of every new BD. The existing PACK-CHAT.md
behavioral rules (lines 50-99) include "Plan before executing" and
"No solution-biasing" — both compatible with adding a triage check:

> When a new skill / agent / relationship change is proposed, name
> whether it is mechanical (per pack memory) or structural. If
> structural, route to `pack-architect` for a design pass before any
> coder work begins.

This is one sentence, slottable into the "Behavioral rules" list. It
operationalizes the principle at the workflow level — the principle
doesn't just sit in agent memory, it shapes the BD-routing question
Pack Chat asks first.

### 5.4 What enforcement does NOT cover

Explicit non-claims:

- The principle does not police SKILL.md *content* depth. A SKILL.md
  with 50 rules is fine if the domain warrants it; the principle
  cares about scaffold around the SKILL.md, not the SKILL.md itself.
- The principle does not police BACKLOG entry granularity. A BD that
  bundles three structural changes is a planning concern, not a
  principle concern.
- The principle does not police pack-product files in client projects.
  Project-template behavior is governed by the project-template trinity;
  this principle is pack-ops, not pack-product (per
  `feedback_ops_product_separation.md`).


---

## 6. Conflict check against existing pack rules

Each existing pack rule that the principle could intersect with is
listed below with an explicit conflict / non-conflict determination.

### 6.1 Trinity rule (CLAUDE.md lines 70-76)

**No conflict.** The trinity rule mandates that pack-repo trinity edits
sync across CLAUDE.md / AGENTS.md / GEMINI.md. The principle's home
(L1) is governed by this rule and benefits from it (zero new sync
tax). The principle reinforces the trinity rule by counting trinity
asymmetry as a structural signal (§3.2 condition 7).

### 6.2 Ops/product separation (CLAUDE.md lines 160-163;
`feedback_ops_product_separation.md`)

**No conflict.** The principle is pack-ops (lives in pack-repo
trinity, governs pack development workflow). The L4 location was
explicitly rejected on this rule's grounds. The L5 pointer in
`project-template/docs/pack/PLATFORM-SKILLS.md` is in pack-product
territory but only carries a cross-reference to the pack-ops home — it
does not import pack-ops content into pack-product.

### 6.3 Agents-never-commit (CLAUDE.md lines 102-107;
`feedback_agents_never_commit.md`)

**No conflict.** Orthogonal — that rule governs git state changes; this
rule governs change scope. The principle's enforcement signals (§5)
explicitly do not require any agent to gain git-state-change
permission.

### 6.4 No solutions in agent prompts (CLAUDE.md lines 131-134;
`feedback_no_solutions_in_agent_prompts.md`)

**Tension surfaced; no conflict.** The principle's reviewer prompt
addition (§5.2) names a *task category* ("flag scope-creep findings"),
not a solution. It is structurally identical to the existing standing
reviewer task ("flag trinity asymmetry"). No biasing, no
"recommend-X-over-Y" framing. Acceptable under the rule.

### 6.5 BD-NNN numbering (CLAUDE.md lines 60-62)

**No conflict.** The principle does not introduce new BDs by itself; if
a planner takes this design forward, the resulting BDs follow the
existing numbering convention (next free number from BACKLOG.md =
BD-159 as of 2026-05-11, since BD-158 is the highest existing per
`BACKLOG.md` line 1339).

### 6.6 One review/fix cycle per batch (CLAUDE.md lines 112-114;
`feedback_review_fix_one_cycle.md`)

**No conflict.** The principle's reviewer task addition is
within-batch behavior; it does not create a second review cycle.

### 6.7 Implicit BD status flip (CLAUDE.md lines 115-117)

**No conflict.** Orthogonal — that rule governs status transitions;
this rule governs change scope.

### 6.8 BACKLOG has no Resolved section (CLAUDE.md lines 157-159;
`reference_pack_backlog_structure.md`)

**No conflict.** Orthogonal.

### 6.9 Filename uniqueness (`feedback_filename_uniqueness.md`)

**No conflict; minor reinforcement.** That rule prefers unique
filenames so prose references are unambiguous. The principle
implicitly reinforces it by counting "new top-level doc" as a
structural signal (§3.2 condition 5) — a new doc is harder to keep
uniquely-named the more there are.

### 6.10 Pack Chat does not architect (CLAUDE.md lines 108-111;
`feedback_pack_chat_does_not_architect.md`)

**No conflict.** The principle's Pack Chat triage role (§5.3) is
routing, not architecture. Pack Chat asks "is this mechanical or
structural?" and routes structural cases to `pack-architect` — that's
exactly the rule's intent.

### 6.11 Worktree isolation broken from v11-dev clone
(`feedback_worktree_isolation_broken_from_v11_clone.md`)

**No conflict.** Orthogonal — that rule governs sub-agent spawning
mechanics.

### 6.12 No prior reviews to pack-reviewer (CLAUDE.md lines 135-137)

**No conflict.** The principle does not require feeding prior reviews
to reviewer; reviewer reads pack memory like every other agent.

### 6.13 Migrator framework (CLAUDE.md lines 35-40, BD-119)

**Tension surfaced; no conflict, but planner must note.** The
principle's structural-signal §3.2 condition 8 ("migrator behavior
change") aligns with the migrator framework rule that prohibits
copying `scripts/migrate-v10-to-v11.sh` to spawn a new migrator.
Both rules push migrator changes through architect oversight. The
principle generalizes the migrator-specific rule into a pack-wide
posture.

### 6.14 No pre-existing rule says the opposite

A grep across CLAUDE.md / PACK-CHAT.md / PACK-AGENTS.md and the user
auto-memory directory for "more docs", "always validate", "every skill
needs", "every agent needs" returned zero hits. There is no rule the
principle contradicts.


---

## 7. Pre-existing pack surfaces that violate the principle today

This section identifies pack surfaces that currently violate the
mechanical-edit posture, with explicit recommendations on whether to
address them in v11.0 or accept as legacy.

### 7.1 `maintenance-docs/v11-implementation/` accumulation (30+ files)

**Status.** 30+ design / plan / implementation-report / audit / review
files in a single directory (verified by `ls`).

**Violation severity.** Medium. Each file was justified at the time
(in-flight design / plan / report). Together, they make the v11 design
hard to reconstruct for a new contributor.

**Recommendation.** Accept as legacy through v11.0; address in v11.x as
a documentation-only consolidation BD. Specifically:

- After v11.0 ships, move resolved-batch artifacts
  (`IMPLEMENTATION-REPORT-*.md`, `PACK-REVIEW-*.md`, `AUDIT-*.md`)
  under `maintenance-docs/archive/v11/`.
- Keep `ARCHITECTURE-*.md` and `PLAN-*.md` for skills the principle
  governs (skill-dimensions, BD-119) at top level for ongoing
  reference.
- Do NOT do this in v11.0 — that work is itself structural and would
  delay v11.0 ship.

**Scope-creep risk going forward.** The principle prohibits new
top-level docs as a mechanical edit (§3.1 condition 6 / §3.2 condition
5). Once codified, the accumulation pattern stops at the line.

### 7.2 `validate-pack.py` check accumulation (currently ~30 checks per the
`def check_*` listing at script lines 187-2161)

**Status.** Numbered Checks 1-31 (with 12-15 retired per script line
768). Six new checks were added in v11.0 work (Checks 21, 27, 28, 29,
30, 31).

**Violation severity.** Low individually; the accumulation is the
concern, not any single check.

**Recommendation.** Accept as legacy. Each existing check has a
demonstrable value in catching specific drift. The principle's job is
to slow the *next* addition, not to retroactively retire any of these.

**Scope-creep risk going forward.** §3.2 condition 4 makes any new
`check_*` a structural signal — including for content that "feels"
mechanical. The architect pass for any future check is not optional.

### 7.3 PM-only file list expansion (CLAUDE.md lines 82-86)

**Status.** Six files listed: BACKLOG.md, README.md version table,
PACK-CHAT.md, CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md.

**Violation severity.** Low. The list is small and the additions
across versions were defensible.

**Recommendation.** Accept as legacy. The principle's §3.2 condition
9 prevents future expansion without architect pass.

### 7.4 Skill-suffix inconsistency (the four-suffix catalog)

**Status.** Per `ARCHITECTURE-SKILL-DIMENSIONS.md` §7.10, four
suffixes coexist (`*-best-practices`, `*-language`, `*-architecture`,
`*-patterns`).

**Violation severity.** Low. The codification (BD-149) closes the
naming-convention drift; the rename migration (BD-155, v12-deferred)
closes the inconsistency itself.

**Recommendation.** Already addressed by the existing plan. The
principle reinforces BD-149's importance — it is what stops a fifth
suffix.

### 7.5 Cross-skill duplication (concurrency, observability, accessibility
mentions scattered across skills)

**Status.** Per `ARCHITECTURE-SKILL-DIMENSIONS.md` §7.1 (observability),
§7.2 (accessibility), §7.3 (concurrency), several conceptual areas
have rule fragments duplicated across multiple skills.

**Violation severity.** Low for the principle (this is content
duplication, not scaffold creep). The principle does not police skill
content; it polices the scaffold around skills.

**Recommendation.** Accept as legacy; v12 BDs (BD-151 / BD-152 / BD-153
per `BACKLOG.md`) address the consolidation. The principle does not
require pre-emptive action.

### 7.6 No pre-existing pack memory entry contradicts the principle

A re-read of CLAUDE.md lines 93-174 confirms no existing entry would
need to be removed or weakened. The principle adds; it does not
displace.


---

## 8. Implementation surface (for the future planner pass)

Concrete file edits the principle requires. This is the surface a
future `pack-planner` would sequence; this design does NOT plan it.

### 8.1 Required edits

| File | Edit shape | Trinity-replicated? |
|---|---|---|
| `CLAUDE.md` (pack-repo root) `## Pack memory` § "Repo conventions" | Add the canonical paragraph + quotable summary per §2.1 / §2.2 | Yes — paired edit to AGENTS.md and GEMINI.md |
| `AGENTS.md` (pack-repo root) `## Pack memory` § "Repo conventions" | Same edit, byte-equivalent prose | Trinity sibling |
| `GEMINI.md` (pack-repo root) `## Pack memory` § "Repo conventions" | Same edit, byte-equivalent prose | Trinity sibling |
| `PACK-AGENTS.md` "Agent permission rules" or "Key conventions" | Add one-line cross-reference to pack-memory entry | No — single file |
| `PACK-CHAT.md` "Behavioral rules" | Add one-line triage rule per §5.3 | No — single file |
| `project-template/docs/pack/PLATFORM-SKILLS.md` "Extending this file" (line 554) | Add the L5 cross-reference per §4.4 | Yes via Check 9 byte-identity (file is single source, distributed at build time) |

### 8.2 Optional / deferred edits

| File | Edit shape | Defer rationale |
|---|---|---|
| `scripts/validate-pack.py` | New "PR-shape footprint" check | Deferred — see §5.1; brittle and self-violating |
| `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6 | Cross-link to this design's principle | Optional; existing §6 already implies the property |
| `project-template/docs/pack/prompts/reviewer.md` (per `README.md` Repository Layout) | Standing reviewer task per §5.2 | Deferred — applies to *project* reviewers, not pack reviewers; this principle is pack-ops |

### 8.3 BACKLOG entry

A single new BD (next free = BD-159 as of 2026-05-11 per
`BACKLOG.md` line 1339):

> **BD-159 — Codify skill / agent maintainability principle in pack
> memory + PACK-AGENTS pointer + PACK-CHAT triage rule + PLATFORM-SKILLS
> cross-reference.**

Total file footprint per the principle's own threshold conditions
(§3.1):

- 0 new files (the principle is doc-only)
- 6 edited files (3 trinity + PACK-AGENTS + PACK-CHAT + PLATFORM-SKILLS)
- 0 new validators
- 0 new scripts
- 0 new top-level docs (this architecture doc is itself a record under
  the architect/planner workflow, exempted by §3.2 condition 5
  parenthetical)

**The implementing BD is itself a mechanical change under its own
principle.** That is the design's basic sanity check.

### 8.4 What this design does NOT prescribe

- The exact wording of the PACK-AGENTS / PACK-CHAT pointer sentences.
  Those are author-time decisions for the BD's coder.
- Whether BD-159 ships in v11.0 or v11.1. That is a planner /
  Pack Chat scheduling decision; the principle works regardless.
- Whether to retroactively flag pre-existing violations (§7) as new
  BDs. That is also planner / Pack Chat scope.


---

## 9. Anti-patterns the principle rejects

These patterns are explicitly out of scope for "mechanical edit" and
must be either rejected outright or routed to architect:

### 9.1 "Every new skill needs its own validator"

**Rejected.** Validate-pack.py's structural-coherence checks (Check 9
byte-identity, Check 31 inventory consistency per BD-146) cover every
well-shaped new skill. A skill needing its own validator is a signal
the skill is doing something the existing model does not anticipate —
which is structural by §3.2 condition 4.

### 9.2 "Every new dimension needs a new architecture doc"

**Context-dependent — usually rejected.** A new dimension is structural
by §3.2 condition 1 and triggers an architect pass; that architect
pass produces an `ARCHITECTURE-*.md` per the existing
`maintenance-docs/v11-implementation/` convention (which §3.2 condition
5 explicitly exempts). What the principle rejects is *new docs that
are not produced by the architect/planner/coder/reviewer workflow* —
e.g., a freestanding `DIMENSIONS.md` policy doc parallel to
PLATFORM-SKILLS.md, or a `SKILL-AUTHORING.md` separate from the
"Extending this file" section.

### 9.3 "Every cross-skill relationship needs its own table"

**Rejected.** PLATFORM-SKILLS.md already carries the dimensional /
intersection / trigger tables. Adding a fifth table for, say,
"skill-to-skill cross-reference" is structural by §3.2 condition 1
(new load mechanism) and condition 5 (new top-level doc-shaped
artifact).

### 9.4 "Every new helper deserves its own lib/ file"

**Rejected.** Helpers parallel to `python_data_marker_detected()`,
`protobuf_marker_detected()`, `swiftdata_marker_detected()` belong in
`scripts/lib/detect.sh` as additional functions. Spinning up a new
`lib/markers.sh` to "organize" them is splitting for splitting's sake.
The principle's mechanical-edit definition (§3.1 condition 6)
explicitly counts library extensions as edits, not new files.

### 9.5 "Every new project shape needs a new project template"

**Rejected.** The pack ships one unified `project-template/` (per
README.md Repository Layout, line 88). Adding `project-template-web/`
or `project-template-android/` to support future D1 expansion is
structural; the unified template + dimensional skill loading is the
v11 contract.

### 9.6 "Every new convention should ship with a migration"

**Rejected for documentation-only conventions.** BD-149 codifies the
naming convention without renaming existing skills; BD-155 (v12) is
the optional rename migration. Documentation-only codification is
mechanical; rename migration is structural by §3.2 condition 8
(migrator surface change). Bundling the two doubles the cost of the
codification.

### 9.7 "Every BACKLOG ratchet should be enforced by a script"

**Rejected.** The PM-only file list, the BD numbering rule, the
no-Resolved-section convention — these are governed by Pack Chat /
human review. Scripting them adds maintenance cost without removing
the human verification step (because the script's outputs are still
read by humans). Existing examples like the BD-numbering rule
(CLAUDE.md lines 60-62) work without a validator and have for
multiple major versions.


---

## 10. Survivability story — how the principle persists

The user's verbatim direction includes "These rules must be easily
found and not forgotten." This section names the specific mechanisms
by which the principle survives across contributors / sessions /
months.

### 10.1 Survival mechanism 1 — pack memory is read every session

Every pack agent reads its tool-native context file before starting
(per `PACK-AGENTS.md` lines 148-153). That file's "Pack memory"
section is treated as standing rules. Adding the principle there
guarantees every architect / planner / coder / reviewer / docs-researcher
session sees it, regardless of which contributor or which CLI ran the
session, regardless of how much time has passed since the last edit.

This is the same mechanism that has carried the trinity rule, the
agents-never-commit rule, and the no-solutions rule across multiple
versions without drift.

### 10.2 Survival mechanism 2 — trinity rule enforces sync

The principle ships in 3 trinity files. The trinity rule (CLAUDE.md
lines 70-76) requires that any edit to one applies to all three.
Validate-pack's Check 18 (trinity H2 parity) catches H2-level
divergence; the human review process catches finer-grained drift.

If a contributor edits the principle in CLAUDE.md and forgets AGENTS.md
/ GEMINI.md, the next agent session running on Codex or Gemini reads a
stale copy — but the trinity-sync mistake itself is a known failure
mode the existing rule machinery already catches.

### 10.3 Survival mechanism 3 — quotable summary in agent prompts

The 20-word summary (§2.1) is short enough to quote verbatim in
reviewer prompts as a standing task. Pack Chat's existing reviewer
prompt template carries 5-7 standing tasks today; adding one more is
within the existing pattern. Once embedded, every reviewer invocation
re-states the principle to itself.

### 10.4 Survival mechanism 4 — validator backstops structural integrity

Even if every prose surface drifted, the existing validate-pack
checks (9 byte-identity, 18 trinity parity, 27 canonical phrase, 31
inventory consistency per BD-146) would catch the structural
violations the principle protects against. The principle is the
reason for those checks; the checks survive the principle's prose
even if the prose drifts.

### 10.5 Survival mechanism 5 — worked examples in BACKLOG

BD-141, BD-156, BD-157, BD-158 are now permanent BACKLOG entries
demonstrating the mechanical-edit footprint. Future contributors who
ask "what does easy look like?" can read those four BDs and replicate
the shape. The BACKLOG itself is a survival channel — entries persist
indefinitely.

### 10.6 Failure mode — what could still erode the principle

Honest assessment of what the design does NOT protect against:

1. **A single charismatic refactor that bundles 10 structural
   changes** could ship if Pack Chat does not enforce the §3.2
   triggers. Mitigation: the §5.3 Pack Chat triage rule.
2. **Slow validator-creep** — one new check per quarter, each
   individually defensible — would still accumulate. Mitigation: the
   §3.2 condition 4 architect-pass requirement, plus the cultural
   default that the answer to "should I add a check?" is "no, unless
   you can name the structural shift it enforces."
3. **Doc-creep via "this is just a record" files** — implementation
   reports, audit reports, review reports under `maintenance-docs/`
   are explicitly exempted from §3.2 condition 5 because they are
   produced by the existing agent workflow, not authored as policy.
   That exemption is necessary but creates a side channel. Mitigation:
   periodic consolidation BDs (§7.1 recommendation).

These failure modes are recognized; the principle does not pretend to
prevent them absolutely. It raises the cost of each, which is what
maintainability principles can do.


---

## 11. Open questions for Pack Chat / planner / user

These are decisions the design intentionally leaves to downstream
sequencing because they depend on schedule or preference, not on
architecture:

1. **Is BD-159 a v11.0 batch or a v11.1 follow-up?** It is small (6
   files, all doc edits) and would not block any existing v11.0 BD. It
   would be most valuable shipped *before* BD-149 codifies the naming
   convention so the naming codification has the principle's quotable
   summary to point at; that ordering is achievable in v11.0. But if
   v11.0 is already over-scoped, v11.1 is acceptable — the principle
   does not bind retroactively.
2. **Should the `pack-reviewer` agent file (`PACK-AGENTS.md` line 18)
   gain a "scope-creep finding" category in its checklist?** Adopting
   would make the principle visible at the agent-definition level, not
   just at the prompt-construction level. Recommend yes; defer to BD-159.
3. **Should the principle's quotable summary be included in
   `pack-startup` output** so every Pack Chat session re-prints it? Low
   cost; high visibility. Defer to BD-159 implementation.
4. **Should §7 pre-existing violations get their own remediation BDs
   in v11.x?** §7.1 (maintenance-docs accumulation) is the most
   visible. Recommend Pack Chat decide based on contributor pain
   signals, not on architectural urgency.

---

## 12. Final summary for Pack Chat

- **Doc path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
- **Principle in <20 words:** *Adding or modifying a skill, agent, or
  their relationships is a mechanical edit by default; structural
  change is opt-in and must be defended.*
- **Primary documentation location:** Pack-repo trinity `## Pack
  memory` § "Repo conventions" — `CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md` lines 93-174.
- **Primary enforcement signal:** `pack-architect` and `pack-reviewer`
  read pack memory at session start (per `PACK-AGENTS.md` line 149);
  the existing `architecture-review` skill carries minimum-viable-change
  methodology; existing validator checks (Check 9 byte-identity,
  Check 18 trinity parity, Check 31 inventory consistency per BD-146)
  catch structural-coherence violations. No new validator check; no
  new doc; no new script.

