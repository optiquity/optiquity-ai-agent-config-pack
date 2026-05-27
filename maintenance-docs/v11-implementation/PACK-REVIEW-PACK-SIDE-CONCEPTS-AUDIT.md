# PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md

Pack-side audit against the user-locked rule "Project-side concepts on
pack-side surfaces — deliverable-only" (trinity §Pack memory §Repo
conventions; locked 2026-05-27 during BD-185 reconciliation).

Read-only review pass against v11-dev working tree.

---

## §1 — Scope

### §1.1 — HEAD SHA

Working-tree HEAD at review start: `d424aac41395b6f0a3950be4805fc84e3e6c6a1b`
(short: `d424aac`).

Confirmed via `git rev-parse HEAD` (allowed read-only verb per
`commit-discipline` skill §3).

### §1.2 — Rule reference

Rule lives in pack-root trinity at byte-identical wording across the
three files:

- `CLAUDE.md` L488-524
- `AGENTS.md` L449-485
- `GEMINI.md` L419-455

The rule states (paraphrased; full text at the three lines above):

> Project-side concepts (TD entries, phases, phase parts, phase tasks)
> on pack-side surfaces MUST be limited to constructing project-side
> deliverables. They MUST NOT appear in pack operations or pack
> templates/configs for pack-self-management.

The rule's worked example calls out the pack-root form
(`.github/ISSUE_TEMPLATE/work-item.yml`) as a known leak.

### §1.3 — Audit scope (pack-side surfaces only)

Per prompt §"Surfaces to audit":

1. Pack-root forms (`.github/ISSUE_TEMPLATE/*.yml`)
2. Pack-root configs (`.claude/`, `.codex/`, `.gemini/` at pack-root)
3. Pack-ops/ all files
4. Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at root)
5. Pack-root `scripts/` — self-management portions only
6. Pack-root `EXECUTION-PLAN-V11.0.md` (lives under
   `maintenance-docs/v11-implementation/`) + other
   pack-self-management docs at pack-root
7. `maintenance-docs/` design docs about pack-self-management

### §1.4 — Out-of-audit (allowed by rule)

Per prompt §"Out-of-audit": `project-template/**`, `supporting-docs/**`,
`scripts/init-project.sh`, `scripts/validate-pack.py` (verifies
project-side structure — constructor), pack-side `maintenance-docs/`
architect docs that DESIGN project-side surfaces,
`maintenance-docs/v11-research/templates-archive/**`, pack memory
entries that govern project-side semantics.

`scripts/validate-pack.py` is partly out-of-audit (its primary role is
project-side validation), BUT its embedded expectation tables for
pack-self-management surfaces are IN audit scope (worked example: the
pack-root form's `wi-type` expected-options dict at L1102 is what the
form fix must update in lock-step).

---

## §2 — Methodology

### §2.1 — The test

For each pack-side surface that mentions a project-side concept
(`TD-NNN`, `phase-N`, `phase-N.M`, `phase-epic`, `phase-task`,
`phase-epic-skeleton`, `phase-task-skeleton`, `td-entry`, etc.),
apply the test:

> "Is this pack-side surface being used to CONSTRUCT a project-side
> deliverable, or is it part of pack-self-management?"

If the surface IS the source-of-truth or emitter for a project-side
artifact (templates copied to client, scripts that emit, validators
that check), project-side references are ALLOWED.

If the surface is pack-self-management (the form/config/script
operates on the PACK REPO ITSELF), project-side references are
FORBIDDEN.

### §2.2 — Verdict categories

- **LEGITIMATE** — surface is constructing project-side deliverable;
  references allowed by rule.
- **LEAK (operational)** — surface is pack-self-management AND
  operationally treats project-side concepts (e.g., form admits TD;
  validator's pack-self-management expectation expects TD). Per
  rule: forbidden; fix required.
- **LEAK (cosmetic/audit-trail)** — surface is pack-self-management
  AND mentions project-side concepts narratively (audit trail of
  pack-development BDs that constructed project-side surfaces).
  Reviewed case-by-case; many are necessary; some may be stale.
- **AMBIGUOUS** — borderline; surface to user.

### §2.3 — Search strategy

Used `grep -rn -E "(\\bTD-[0-9]+|phase-epic|phase-task|td-entry|phase-task-skeleton|phase-epic-skeleton)"`
across every surface in §1.3 audit scope. Cross-checked against the
explicit deny-list cited in the rule's worked example. Then read
each hit in context to assign a verdict.

### §2.4 — Severity assignment

- **HIGH** — operational leak in a surface that is consulted at
  runtime (form options drive issue creation; validator
  expectation drives CI gate).
- **MEDIUM** — operational leak in a surface that influences but
  does not directly construct (docstring/comment that misleads
  future maintainers).
- **LOW** — cosmetic/audit-trail mention with no operational
  weight (BD entry narrative, IMPLEMENTATION-REPORT history).

---

## §3 — Per-surface findings

### §3.1 — Surface category 1: Pack-root forms (`.github/ISSUE_TEMPLATE/`)

Files audited:
- `.github/ISSUE_TEMPLATE/work-item.yml`
- `.github/ISSUE_TEMPLATE/inbound.yml`
- `.github/ISSUE_TEMPLATE/config.yml`

#### §3.1.1 — `.github/ISSUE_TEMPLATE/work-item.yml`

**Verdict: LEAK (operational) — HIGH.**

This form is the pack-root work-item intake form. The pack repo
uses this form to file pack-development items against itself (per
the form's L1 name `"Pack work item (BD / TD / phase-epic /
phase-task)"` and L2 description). Per the new rule's worked
example (pack-root trinity L501-507 / L514-520 / L484-490), the
form is pack-self-management and MUST NOT admit project-side
concepts.

Leak inventory (all in `work-item.yml`):

| Line | Content | Class |
|---|---|---|
| L1 | `name: Pack work item (BD / TD / phase-epic / phase-task)` | LEAK |
| L2 | `description: ... project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton.` | LEAK |
| L21 | `description: Pick BD for pack-development items; TD for project items; phase-epic-skeleton or phase-task-skeleton for hand-edited phase skeletons (rare).` | LEAK (operational; the dropdown copy) |
| L24-26 | `options: - bd / - td / - phase-epic-skeleton / - phase-task-skeleton` | LEAK (operational; the dropdown options) |
| L32 | `label: Kind (BD / TD only)` | LEAK |
| L33 | `description: Required for Type=bd or Type=td. The METHODOLOGY § Part 7 type ...` | LEAK |
| L47 | `description: Defaults to Open for BD/TD. Phase tasks default to Pending.` | LEAK |
| L62-73 | wi-td-scope dropdown (entire field — `TD scope (TD only)`) | LEAK |
| L75-84 | wi-td-severity dropdown (entire field — `TD severity (TD only, KNOWN GAP variant)`) | LEAK |
| L86-92 | wi-phase-number input (entire field — phase-skeleton-only) | LEAK |
| L94-99 | wi-task-title input (entire field — phase-task-skeleton-only) | LEAK |
| L104-105 | wi-blockers description: `... phase token. Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task) ...` | LEAK (operational) |
| L126 | wi-description description: `For BD/TD/phase-epic-skeleton. (Phase task skeletons use Problem / Goal / Success below instead.)` | LEAK |
| L144-149 | wi-problem-goal-success textarea (phase-task-skeleton only) | LEAK |
| L150-156 | wi-files textarea (phase-task-skeleton only) | LEAK |
| L157-163 | wi-definition-of-done textarea (phase-task-skeleton only) | LEAK |
| L164-171 | wi-dependencies textarea (phase-task-skeleton only; description names `phase-N`, `phase-N.M`, `TD-NNN`) | LEAK |

The rule's worked example explicitly calls out L24-26 (the `wi-type`
dropdown options `td`, `phase-epic-skeleton`, `phase-task-skeleton`),
but every field listed above is operationally dependent on the
forbidden wi-type options. Removing only the dropdown options without
removing the dependent fields would leave the form internally
inconsistent (dependent fields with no parent type).

The pack form's correct wi-type options after fix: `{bd}` (only —
because pack-root files BDs against itself, not TDs/phase-skeletons).

Severity HIGH because this is a runtime-active form — until fixed,
any user/agent filing a pack-development item against this repo is
presented with the stale options and may file an entry the pack
cannot route.

#### §3.1.2 — `.github/ISSUE_TEMPLATE/inbound.yml`

**Verdict: LEGITIMATE.**

This form admits external bug reports / feature requests /
pack-feedback observations from project users. The `in-category`
dropdown options (L21-27: `bug`, `feature-request`,
`pack-feedback-workflow`, etc.) carry no TD/phase admissions. No
project-side concepts in the form. Clean.

#### §3.1.3 — `.github/ISSUE_TEMPLATE/config.yml`

**Verdict: LEGITIMATE.**

Disables blank issues and routes open-ended questions to GH
Discussions. No project-side concepts. Clean.

### §3.2 — Surface category 2: Pack-root CLI configs

Directories audited:
- `.claude/` (agents/, skills/, settings.local.json)
- `.codex/` (agents/, skills/)
- `.gemini/` (agents/, commands/, skills/)

**Verdict: LEGITIMATE (clean).**

`grep -rn -E "(\\bTD-[0-9]+|phase-epic|phase-task|td-entry)"
.claude/ .codex/ .gemini/` returned **zero hits** at pack-root.

These config directories define pack-* agents (pack-architect,
pack-planner, pack-coder, pack-reviewer, pack-docs-researcher) and
their skills; pack-* agents operate on pack-self-management workflows
and correctly do not admit TD/phase concepts.

### §3.3 — Surface category 3: `pack-ops/` files

Files audited (every file under `pack-ops/`):
- `BACKLOG.md` — pack-development backlog
- `CHANGELOG.md` — pack-development changelog
- `PACK-AGENTS.md` — agent routing table
- `PACK-CHAT.md` — PM chat operating rules
- `HELP-FRAGMENT-PACK.md` — pack-side help fragment
- `HELP-FRAGMENT-TRACKER.md` — tracker help fragment (pack-side audience)
- `OPTIONAL-FEATURES.md`
- `MERGE-STRATEGY.md`
- `DRY-RUN-MIGRATION.md`
- `CONCEPTUAL-REVIEW-METHODOLOGY.md`
- `BOUNDARY-DEFINITION.md`

#### §3.3.1 — `pack-ops/BACKLOG.md`

**Verdict: LEAK (cosmetic/audit-trail) — LOW.**

`grep -c -E "(\\bTD-[0-9]+|phase-epic|phase-task)" pack-ops/BACKLOG.md`
returns multiple hits. Read in context, every hit I sampled falls into
the audit-trail class:

- L83 — `BD-063` description: `"routes by Type dropdown (bd / td /
  phase-epic-skeleton; phase-task-skeleton added by BD-106
  extension)"` — describes the form BD-063 shipped (the very form
  this audit flags as a leak in §3.1).
- L96 — `BD-064` File/Symbol: `"templates-archive/v11.0/{INDEX.md,
  bd-v11.0,td-v11.0,phase-epic-v11.0,phase-task-v11.0,inbound-v11.0,
  forms}"` — describes the project-side templates archive BD-064
  constructed.
- L156-157 — `BD-068`-area phase-task fixture description
- L393 — `BD-NNN` description: `"Checks (phase-task coverage /
  cross-entity ref resolution / promotion-label ...)"`
- L899 — `BD-106` File/Symbol — `scripts/lib/tracker-phase-task.sh`
  (the script that CONSTRUCTS project-side phase-tasks)
- L906 — `BD-106` Resolved narrative
- L1000 — `BD-108` Resolved narrative covering `TD-040 Blockers` test
  fixture round-trip
- L2485 — `BD-132` Resolved narrative (`bd-entry` / `td-entry` /
  `phase-epic` label-scoped count)
- L3024 — `BD-193` description (the BD that introduced the
  project-side asymmetric counterpart)
- L3032 — `BD-193` discussing the LEAK class definition itself

These are pack-development BD entries describing pack-self-management
work that constructed project-side surfaces. Removing the references
would erase the audit trail of how pack-development built the
project-side artifacts. Per the rule, narrative/audit-trail mentions
in pack-self-management entries are NOT forbidden — only OPERATIONAL
treatment is forbidden.

`pack-ops/BACKLOG.md` does NOT operationally treat TD/phase concepts
(no entry-type admissions, no first-class TD dependency grammars in
the BACKLOG body). It only DESCRIBES project-side concepts through
its BD entries' historical record.

Severity LOW. No fix required.

#### §3.3.2 — `pack-ops/CHANGELOG.md`

**Verdict: LEGITIMATE (clean).**

`grep -c` returns **zero** matches against TD/phase pattern. Clean.

#### §3.3.3 — All other pack-ops/ files (PACK-AGENTS.md, PACK-CHAT.md, HELP-FRAGMENT-*.md, OPTIONAL-FEATURES.md, MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md, CONCEPTUAL-REVIEW-METHODOLOGY.md, BOUNDARY-DEFINITION.md)

**Verdict: LEGITIMATE (clean).**

`grep -rn -E "(\\bTD-[0-9]+|phase-epic|phase-task)"` across these
files returns **zero hits**. Pack-ops operating documentation is
clean of project-side concept operational treatment.

### §3.4 — Surface category 4: Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`)

**Verdict: LEGITIMATE (clean of operational leak; rule-documentation mentions are intended).**

`grep` for TD/phase concepts returns exactly the rule's own
documentation:

- `CLAUDE.md` L501-507: the rule's `FORBIDDEN:` example block citing
  `td`, `phase-epic-skeleton`, `phase-task-skeleton`.
- `CLAUDE.md` L523: the rule's `Why:` worked-example reference to
  `phase-epic-skeleton`, `phase-task-skeleton`.
- `AGENTS.md` L462-484: same mirror at trinity parity.
- `GEMINI.md` L432-454: same mirror at trinity parity.

These mentions are the RULE NAMING the forbidden concepts — meta-content
necessary for the rule to be readable. They are not operational
admissions. Trinity parity is consistent. Clean.

### §3.5 — Surface category 5: Pack-root `scripts/` — self-management portions

Scripts audited (filtered to pack-self-management focus):
- `scripts/pack-help.sh` — emits help text
- `scripts/pack-td.sh` — `pack td` verb
- `scripts/pack-tracker.sh` — `pack tracker` verb
- `scripts/tracker-migrate.sh` — migration entry point
- `scripts/migrate-v10-to-v11.sh`
- `scripts/dry-run-migration.sh`
- `scripts/add-capability.sh`
- `scripts/init-project.sh` (constructor; allowed by rule)
- `scripts/restore-from-backup.sh`
- `scripts/compare-agent-trinity.py`, `scripts/merge-*.py`
- `scripts/lib/recommendation.sh`, `scripts/lib/tracker-*.sh`,
  `scripts/lib/migrator-*.sh`, `scripts/lib/customization-*.sh`,
  `scripts/lib/detect.sh`, `scripts/lib/three-way.sh`,
  `scripts/lib/template-translations.sh`,
  `scripts/lib/template-version.sh`, `scripts/lib/per-entry/`

**Verdict: LEGITIMATE (clean of pack-self-management leak; all hits are constructor context).**

#### §3.5.1 — `scripts/pack-td.sh`

The script's entire purpose is to operate on PROJECT-side TD
entries — `pack td resolve <td-id>`, `pack td promote --to=phase-N
<td-id>`, `pack td promote --to=phase-N.M <td-id>`. This is a
CONSTRUCTOR that emits/manipulates project-side artifacts (BACKLOG.md
TD entries, IMPLEMENTATION-PLAN.md phase epics). The script's docstring
at L1-32 names V3.3 §3.1 outcome paths for project-side TD resolution.

Per rule: "scripts that emit project-side templates" — allowed.

#### §3.5.2 — `scripts/lib/tracker-phase-task.sh`

Library that parses + emits project-side phase-task entries from
project-side `IMPLEMENTATION-PLAN.md`. Per docstring L1-5: "phase-task
entity model" — emits project-side. Allowed by rule.

#### §3.5.3 — `scripts/lib/tracker-promote.sh`

Library that promotes a project-side TD entry into a project-side
phase epic (Path 1) or phase task (Path 2) — see L21-67 docstring.
Constructs project-side artifacts. Allowed by rule.

#### §3.5.4 — Other scripts/lib/tracker-*.sh

All inspected. Each operates on or emits project-side tracker
artifacts (BACKLOG/IMPLEMENTATION-PLAN/STATUS/CHANGELOG;
`.pack-tracker/` cycle store; sidecar). All constructors. Allowed.

#### §3.5.5 — `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, etc.

Explicit out-of-audit per prompt §1.4 (emit project-side; allowed).

### §3.6 — Surface category 6: Pack-root EXECUTION-PLAN-V11.0 + other pack-self-management docs at pack-root

#### §3.6.1 — `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`

**Verdict: LEGITIMATE (clean).**

`grep -n -E "(\\bTD-[0-9]+|phase-epic|phase-task)"` returns **zero
hits** across 516 lines. EXECUTION-PLAN governs pack-development
batches (BD-* labels) only. Clean.

#### §3.6.2 — Pack-root `README.md`

L218 contains a directory-listing entry naming `scripts/lib/tracker-{...,
phase-task,...}.sh`. This describes the script files (one of which is
a constructor for project-side phase-tasks). Reading-context: this
is a README directory listing for the pack repo's `scripts/lib/`
contents — pack-self-management documentation describing the file
inventory. The mention is descriptive of pack-side scripts that
CONSTRUCT project-side artifacts.

**Verdict: LEGITIMATE (LOW-severity descriptive mention).** The
README is describing pack-side script inventory; the phase-task
script exists because it constructs project-side artifacts.
Removing the mention would hide a real pack-side script. No fix.

#### §3.6.3 — Pack-root `QUICKSTART.md`, `LICENSE.md`

Clean of TD/phase per grep. No findings.

### §3.7 — Surface category 7: `maintenance-docs/` design docs about pack-self-management

Strategy: separate the maintenance-docs into two categories:

- **Project-side design docs** (allowed by rule per prompt §"Out-of-audit") —
  e.g., `ARCHITECTURE-BD-185.md`, `ARCHITECTURE-BD-194.md`,
  `ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md`,
  `AUDIT-INVENTORY-BD-TD-PATH.md`, `AUDIT-DISPOSITION-BD-TD-PATH.md`,
  IMPLEMENTATION-REPORT-* (designs/reports about project-side
  surfaces).
- **Pack-self-management design docs** (in audit scope) —
  architectural docs about pack-self-management workflows:
  `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`,
  `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md`,
  `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`,
  `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`,
  `ARCHITECTURE-SKILL-DIMENSIONS.md`,
  `AUDIT-PRE-19C-BOUNDARY-LEAKS.md`,
  `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md`,
  `ARCHITECTURE-CLEANUP-BATCH-19C-*.md`.

Sampled the pack-self-management category for TD/phase operational
leak:

- `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`,
  `ARCHITECTURE-SKILL-DIMENSIONS.md`,
  `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`,
  `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` — all about pack-side
  CLI / agent / skill machinery; no operational TD/phase admissions
  observed.
- `ARCHITECTURE-CLEANUP-BATCH-19C-*` — about pack-self-management
  cleanup batch coordination; some narrative TD/phase mentions
  describe project-side work that the batch BDs constructed
  (audit-trail class, LOW).

**Verdict: LEGITIMATE (clean of operational leak; audit-trail mentions are necessary).**

`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`,
`IMPLEMENTATION-REPORT-BD-194.md` etc. — these are the IMPLEMENTATION
reports for the BDs that constructed the project-side asymmetric
counterpart of the very leak this audit catches. They MUST mention
TD/phase to describe what they did. LEGITIMATE per the rule's
"architecture/planner docs that design project-side surfaces"
exclusion.

No findings in §3.7.

### §3.8 — Validation surface (audit-scope crossover): `scripts/validate-pack.py`

`scripts/validate-pack.py` is primarily a project-side validator
(out-of-audit at the doc level). However, its embedded **expectation
tables** for pack-self-management surfaces are in audit scope because
those tables OPERATIONALLY codify what the pack-self-management
surface must contain.

#### §3.8.1 — `scripts/validate-pack.py` L1101-1104 (Check 23: issue template forms)

```python
expected_wi_type_options_per_surface = {
    "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"},
    "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
}
```

**Verdict: LEAK (operational) — HIGH.**

The `"pack-root"` key's expectation set includes `td`,
`phase-epic-skeleton`, `phase-task-skeleton`. This expectation table
ENFORCES the stale form options via CI: removing the options from
`.github/ISSUE_TEMPLATE/work-item.yml` without updating this
expectation table will fail Check 23 (`work-item.yml — wi-type
options mismatch (extra: none, missing: ['phase-epic-skeleton',
'phase-task-skeleton', 'td'])`).

Per rule: this is the pack-self-management CI gate. The expectation
SET for `"pack-root"` must be reduced to `{"bd"}` in lock-step with
the form fix in §3.1.1.

The `"project-template"` key (set to `{"td", "phase-epic-skeleton",
"phase-task-skeleton"}`) is LEGITIMATE — it validates the project-side
deliverable form (out-of-audit per prompt §1.4; allowed by rule).

#### §3.8.2 — `scripts/validate-pack.py` other check definitions

L140 (Check 34 docstring naming `BD-NNN`, `TD-NNN`, `vN.M`,
`phase-N[.M]` reference IDs that the per-entry tree must resolve) —
this validates project-side per-entry trees. Constructor context.
LEGITIMATE.

L3634-3658 (Check 35 — phase-task lib invariants per BD-106 /
V3.3 §3 line 27) — validates that `scripts/lib/tracker-phase-task.sh`
(constructor) is present and `folded-into` is NOT in executable code.
This is a pack-side check ABOUT the pack-side constructor for
project-side phase-tasks. The check's existence is constructor-context
LEGITIMATE.

L5191 (`"TD-001.md"` filename pattern) — fixture-naming reference in
the per-entry validators. LEGITIMATE.

### §3.9 — Validation-workflow surface: `.github/workflows/validate-pack.yml`

L136-138 names the test runner: `bash scripts/tests/test-tracker-phase-task.sh`.
This invokes the test suite for the pack-side phase-task constructor
library. CI invocation of a test for a constructor. LEGITIMATE.

---

## §4 — Validation check — pack-root work-item.yml (per user direction)

The user surfaced the pack-root `.github/ISSUE_TEMPLATE/work-item.yml`
form's stale `td` + `phase-epic-skeleton` + `phase-task-skeleton`
admissions during BD-185 reconciliation triage (2026-05-27). The
prompt instructs this audit to catch the same finding independently.

### §4.1 — Required findings — confirmed

- **`.github/ISSUE_TEMPLATE/work-item.yml` description** — L21 reads:
  `"Pick BD for pack-development items; TD for project items;
  phase-epic-skeleton or phase-task-skeleton for hand-edited phase
  skeletons (rare)."` — confirms the forbidden phrase per the rule.
  Per §3.1.1 inventory, this is flagged as LEAK (operational; HIGH).
- **`.github/ISSUE_TEMPLATE/work-item.yml` options** — L24-26 enumerate:
  `td`, `phase-epic-skeleton`, `phase-task-skeleton` — confirms the
  forbidden admissions per the rule. Per §3.1.1 inventory, flagged as
  LEAK (operational; HIGH).

### §4.2 — Recommended solution (this audit)

Match the prompt's stated expectation:

> "remove the td + phase-skeleton options from the pack-root form's
> wi-type dropdown"

…AND extend per §3.1.1 inventory and §3.8.1 cross-link:

**Cascade required for a complete fix:**

1. Remove the three forbidden wi-type options (L24-26) from
   `.github/ISSUE_TEMPLATE/work-item.yml`, leaving `bd` as the sole
   option.
2. Remove or rewrite all dependent fields (L62-73 wi-td-scope,
   L75-84 wi-td-severity, L86-92 wi-phase-number, L94-99
   wi-task-title, L144-149 wi-problem-goal-success, L150-156 wi-files,
   L157-163 wi-definition-of-done, L164-171 wi-dependencies) — these
   only exist to support the removed options.
3. Rewrite L1 form name from `"Pack work item (BD / TD / phase-epic
   / phase-task)"` → `"Pack work item (BD)"` (or equivalent).
4. Rewrite L2 description, L21 dropdown description, L32 Kind label,
   L33 Kind description, L47 Initial status description, L104-105
   Blockers description (drop the phase token grammar — pack-self
   does not file phase tokens against itself), L126 Description
   field description — to drop TD/phase admissions.
5. Update `scripts/validate-pack.py` L1102 expectation set from
   `{"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"}` to
   `{"bd"}` in lock-step.
6. Update `pack-ops/BACKLOG.md` BD-063 narrative IF needed to add a
   "subsequent BD-NNN removed TD/phase admissions per
   project-side-concepts-on-pack-side-surfaces rule" note (the
   narrative-update is optional / audit-trail-only; the BD-063
   entry itself remains a historical record).

### §4.3 — Divergence check

This audit's recommended solution (above) does NOT diverge from the
prompt's stated expectation ("remove the td + phase-skeleton options
from the pack-root form's wi-type dropdown"). It EXTENDS the prompt
solution to capture the dependent-field cascade and the
validator-expectation lock-step.

The extension is mechanically forced by the form's structure: the
prompt-stated fix is necessary but not sufficient; without the
extensions the form is internally inconsistent (dependent fields
without parent wi-type) and CI breaks (validator expectation drift).
Per `commit-discipline` skill §3 (read-only verbs only): the
recommendation is read-only — no source modified.

---

## §5 — Findings summary

### §5.1 — Per-verdict counts

| Verdict | Count | Severity distribution |
|---|---|---|
| LEAK (operational) | 2 surfaces | HIGH ×2 |
| LEAK (cosmetic / audit-trail) | 1 surface (pack-ops/BACKLOG.md narratives) | LOW |
| LEGITIMATE | All other audited surfaces | — |
| AMBIGUOUS | 0 | — |

### §5.2 — HIGH-severity findings

**F1 (HIGH).** `.github/ISSUE_TEMPLATE/work-item.yml` admits `td`,
`phase-epic-skeleton`, `phase-task-skeleton` wi-type options (L24-26)
and supporting fields (L62-171 various). Pack-root form is
pack-self-management; per rule, must not admit project-side concept
options. See §3.1.1 inventory, §4 validation, §4.2 cascade.

**F2 (HIGH).** `scripts/validate-pack.py:1102` codifies the
pack-root form's expected wi-type options as `{"bd", "td",
"phase-epic-skeleton", "phase-task-skeleton"}`. The validator's
expectation MUST be reduced to `{"bd"}` in lock-step with F1 fix or
F1 will fail CI (Check 23). See §3.8.1.

### §5.3 — LOW-severity findings

**F3 (LOW).** `pack-ops/BACKLOG.md` BD-063, BD-064, BD-068, BD-106,
BD-108, BD-132, BD-193 entries narratively mention TD/phase concepts
in description / File/Symbol / Resolved fields. These are
audit-trail mentions describing pack-development BDs that
constructed project-side artifacts. Per rule and prompt §"verdict
categories": narrative/audit-trail mentions in pack-self-management
entries are reviewed case-by-case; necessary records of
pack-development history. **No fix required** — removing the
mentions would erase historical context of how pack-side BDs
constructed project-side surfaces.

### §5.4 — Surfaces NOT in this audit's findings (clean)

- Pack-root `.claude/`, `.codex/`, `.gemini/` configs — zero hits
  for project-side concepts
- `pack-ops/CHANGELOG.md` — zero hits
- `pack-ops/PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`,
  `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`,
  `MERGE-STRATEGY.md`, `DRY-RUN-MIGRATION.md`,
  `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `BOUNDARY-DEFINITION.md` —
  zero hits
- Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) — only
  the rule's own documentation references the forbidden concepts;
  trinity parity is consistent
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` —
  zero hits
- Pack-root `scripts/` self-management portions — all hits are
  constructor context (LEGITIMATE)
- `maintenance-docs/v11-implementation/ARCHITECTURE-*` and
  `IMPLEMENTATION-REPORT-*` — design docs and reports for
  project-side surfaces (per prompt §"Out-of-audit")

---

## §6 — AMBIGUOUS surface (items needing user discussion)

**None.**

The audit produced two HIGH operational leaks (F1, F2), one LOW
audit-trail class (F3, no-fix), and all other surfaces clean. No
borderline cases require user clarification — the prompt's worked
example explicitly named the form leak; the validator-expectation
leak (F2) is mechanically downstream of F1 and required to keep CI
green when F1 lands.

If the user wants a discussion before remediation: the only
discussion-worthy item is whether F3 should attract a single
"narrative update" commit to BD-063 noting the post-fact rule
adoption. This audit recommends NO additional narrative — the
existing BD-063 narrative is historical record; future BD-NNN
(which removes the form options) will carry its own narrative
explaining the post-rule cleanup. No AMBIGUOUS flag.

---

## §7 — Recommended remediation

### §7.1 — Single coordinated commit / BD recommended

Per the cascade in §4.2, the fix involves two files in lock-step
(form + validator) and SHOULD land in a single commit with a new BD
NUMBER reserved against the live BACKLOG (per pack memory: "Read
pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment
by 1"). The BD opens immediately after BD-194 (currently the most
recent) per the deferral-is-scope-creep rule (unblocked work
inserted immediately after current batch).

### §7.2 — Scope of the new BD-NNN

| Action | File | Lines |
|---|---|---|
| Reduce wi-type options to `{bd}` | `.github/ISSUE_TEMPLATE/work-item.yml` | L24-26 |
| Remove / rewrite dependent fields | `.github/ISSUE_TEMPLATE/work-item.yml` | L62-99, L144-171 |
| Rewrite form name + description | `.github/ISSUE_TEMPLATE/work-item.yml` | L1-2, L21, L32-33, L47, L104-105, L126 |
| Reduce expectation set | `scripts/validate-pack.py` | L1102 |

### §7.3 — Test plan

- `python3 scripts/validate-pack.py` MUST PASS after the
  coordinated commit; Check 23 (`Issue template forms`) MUST
  report `pack-root: work-item.yml — N wi-type options correct`
  with the new count (1) and not the prior count (4).
- `bash scripts/tests/test-issue-forms.sh` (if present) MUST PASS.
- Test-fixtures manifest regen (per pack memory `feedback_manifest_regen_on_v11_surface`):
  the new BD does NOT touch `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/` — only `.github/` and
  `scripts/validate-pack.py`. `scripts/validate-pack.py` IS under
  `scripts/`, SO the manifest regen trigger IS active. Run
  `bash test-fixtures/build.sh --all --clean` before staging;
  stage manifest delta alongside the scope edits.

### §7.4 — Commit-scope keyword

Per pack-root trinity § "Commit-subject scope-keyword convention":
the commit will touch `.github/` and `scripts/`. Neither
`project-template/` nor `supporting-docs/` is touched, so `pack-only`
is the correct keyword: `fix: v11 — BD-NNN remove TD/phase admissions
from pack-root work-item form (pack-only)`.

The `scripts/validate-pack.py` edit is also under `scripts/` (pack
surface). The commit MUST NOT touch `project-template/` (already
correctly handled by BD-193 — the project-side form has no `bd`
admission per `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
L24-27).

### §7.5 — No remediation required for F3

Per §5.3, the LOW-severity audit-trail mentions in
`pack-ops/BACKLOG.md` are historical records of pack-development BDs
that constructed project-side surfaces. The rule does not forbid
historical narrative; only operational treatment is forbidden.

---

## §8 — Cross-references

### §8.1 — Pack memory anchors

The new rule lives in pack-root trinity § Pack memory § Repo
conventions, at:

- `CLAUDE.md` L488-524 (`Project-side concepts on pack-side surfaces
  — deliverable-only`)
- `AGENTS.md` L449-485 (trinity mirror)
- `GEMINI.md` L419-455 (trinity mirror)

Related pack memory entries (cited in the new rule's `Why:` block):

- `feedback_pack_project_separation_of_concerns` (user-locked
  2026-05-26)
- `feedback_bd_pack_only_operational_rule` (user-locked 2026-05-26)
- `feedback_client_facing_token_economy` (user-locked 2026-05-26)

### §8.2 — Architect docs that constructed the asymmetric project-side counterpart

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md`
  §1.2(6) names the project-side form divergence (`bd` wi-type
  option removed from `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
  by BD-193 F2.d).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  documents the BD-193 changes that closed the project-side leak.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` is the
  Check 24 byte-identity gate replacement design.

The pack-side cleanup (this audit's F1+F2) is the asymmetric
counterpart: BD-193 cleaned project-side; the new pack-side BD-NNN
will clean pack-side per the deliverable-only rule.

### §8.3 — Validator surface cross-reference

`scripts/validate-pack.py:1098-1163` (Check 23 — Issue template
forms, per BD-063) — the expectation table at L1102 is the
co-dependent surface required for F1 fix lock-step.

### §8.4 — Validation workflow

`.github/workflows/validate-pack.yml` runs `scripts/validate-pack.py`
on every push. F1 fix without F2 will fail CI Check 23.

### §8.5 — Read-only enforcement statement

Per prompt §"Read-only enforcement" and `commit-discipline` skill §3:
this review made no source modifications and ran no state-changing
git verbs. The only file written by this review is this report at
`maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`.
HEAD remains `d424aac41395b6f0a3950be4805fc84e3e6c6a1b` at review
completion (verifiable post-review via `git rev-parse HEAD`).
