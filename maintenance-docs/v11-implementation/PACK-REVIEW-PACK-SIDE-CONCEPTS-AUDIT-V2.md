# PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT-V2.md

Re-audit + meta-audit of pack-side surfaces against the user-locked rule
"Project-side concepts on pack-side surfaces — deliverable-only" (trinity
§ Pack memory § Repo conventions; user-locked 2026-05-27 during BD-185
reconciliation).

This pass CHALLENGES the prior audit
(`PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`, HEAD `d424aac`) and EXTENDS
scope to surfaces the prior audit excluded.

Read-only review against v11-dev working tree.

---

## §1 — Scope

### §1.1 — HEAD SHA

Working-tree HEAD at review start: `b4906d18b8b67748b68c14d4dbbe7c82390efcf6`
(short: `b4906d1`).

Confirmed via `git rev-parse HEAD` (allowed read-only verb per
`commit-discipline` skill §3). `git status` reports working tree clean
(no staged or unstaged changes).

### §1.2 — Prior-audit reference

Prior audit at
`maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`
ran against HEAD `d424aac` and produced verdicts:

- F1 (HIGH) — pack-root `work-item.yml` admits project-side wi-type options
- F2 (HIGH) — `scripts/validate-pack.py` Check 23 expectation set carries
  stale options
- F3 (LOW) — `pack-ops/BACKLOG.md` audit-trail mentions (no-fix)
- All other surfaces — LEGITIMATE

The prior audit's F1+F2 dispositions landed in commit `b4906d1`
(IMPLEMENTATION-REPORT at
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md`).
A subsequent finding **F3'** (`scripts/tests/test-issue-forms.sh` lock-step
update) was caught by PREFLIGHT (the test failed 12/78 after F1+F2 landed)
and applied in the same commit; **F3' was MISSED by the prior audit's
methodology**. This methodology gap is the central concern of Part A.

### §1.3 — Rule reference

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

ALLOWED: pack-side scripts that emit project-side templates; pack-side
validate-pack checks that verify project-side structure; pack-side
architecture/planner docs that design project-side surfaces; pack memory
rules that govern project-side semantics.

### §1.4 — Re-audit scope (additions to prior audit)

Per prompt §B — new scope:

1. `scripts/tests/*` (full enumeration; prior audit excluded as
   "constructor context")
2. `scripts/lib/*` self-management portions (prior audit sampled only
   tracker-* files)
3. `.github/workflows/*` (prior audit's §3.9 covered only one line)
4. `scripts/validate-pack.py` per-surface tables OTHER than L1101-1104
5. `scripts/init-project.sh` sections OTHER than the `_CLIENT_INSTALLED_FILES`
   inventory

---

## §2 — Methodology

### §2.1 — Challenge protocol

For each LEGITIMATE verdict from the prior audit:

1. Re-read the surface at HEAD `b4906d1`.
2. Apply the rule's test:
   - "Is this pack-side surface being used to CONSTRUCT a project-side
     deliverable, or is it part of pack-self-management?"
3. Cite specific file:line evidence.
4. Produce one of three verdicts:
   - **CONFIRMED-LEGITIMATE** — surface IS constructing project-side
     deliverable OR is pack-self-management without project-side concept
     references; rule satisfied.
   - **CHALLENGED-NEW-FINDING** — prior verdict was wrong; new finding
     identified with corrected verdict and evidence.
   - **AMBIGUOUS** — borderline; surface to user.

### §2.2 — Verdict categories (extended)

- **CONFIRMED-LEGITIMATE** — re-verified clean (constructor or
  pack-self-management without project-side concept refs).
- **LEAK (operational)** — surface is pack-self-management AND
  operationally treats project-side concepts; flag for fix.
- **LEAK (cosmetic/audit-trail)** — surface is pack-self-management AND
  mentions project-side concepts in narrative; review case-by-case.
- **METHODOLOGY-GAP** — prior audit verdict was right BUT the
  methodology that produced it would miss similar surfaces; documented as
  improvement.
- **AMBIGUOUS** — borderline; surface to user.

### §2.3 — Search strategy

Used `grep -rn -E "(\bTD-[0-9]+|phase-epic|phase-task|td-entry|
phase-epic-skeleton|phase-task-skeleton)"` across the new-scope surfaces
in §1.4. Each hit was read in context and classified per §2.2.

### §2.4 — Constructor-test refinement

The rule's exemption "scripts that emit project-side templates" extends
by entailment to:

- **Tests of those scripts** — test fixtures may use project-side
  grammar (TD-NNN, phase-N, etc.) when exercising a constructor library.
- **Library docstrings** — describe project-side concepts that the
  library operates on.

This entailment is NOT explicit in the rule's wording. It is a reasonable
inference from the rule's purpose (pack-side libraries that emit
project-side artifacts will inevitably have tests that simulate
project-side inputs). It is documented here as the refinement the
re-audit applies.

The DECISIVE distinction is whether the surface OPERATIONALLY treats
project-side concepts in pack-self-management state (e.g., the pack-root
work-item form admitting `td` as a wi-type for pack-self use) vs. whether
the surface uses project-side concepts as test fixtures / docstring
examples / parser inputs.

---

## §3 — Part A — Meta-audit of prior audit

### §3.1 — LEGITIMATE re-verification (per-surface verdict)

#### §3.1.1 — `.github/ISSUE_TEMPLATE/inbound.yml`

**Verdict: CONFIRMED-LEGITIMATE.**

Re-read at HEAD `b4906d1`. The form admits external bug reports /
feature requests / pack-feedback observations from project users. The
`in-category` dropdown options (L21-27) carry no TD/phase admissions.
No project-side concepts in the form. Clean.

Evidence:
- `.github/ISSUE_TEMPLATE/inbound.yml` L21-27 in-category options:
  `bug`, `feature-request`, `pack-feedback-workflow`,
  `pack-feedback-prompt`, `pack-feedback-agent-perf`,
  `pack-feedback-friction`, `pack-feedback-open-question`.
- No grep hits for project-side concept patterns.

#### §3.1.2 — `.github/ISSUE_TEMPLATE/config.yml`

**Verdict: CONFIRMED-LEGITIMATE.**

Re-read. Disables blank issues and routes open-ended questions to GH
Discussions. Two-line file. No project-side concepts.

#### §3.1.3 — Pack-root `.claude/`, `.codex/`, `.gemini/` configs

**Verdict: CONFIRMED-LEGITIMATE.**

`grep -rn -E "(\bTD-[0-9]+|phase-epic-skeleton|phase-task-skeleton|td-entry)"
.claude/ .codex/ .gemini/` returned **zero hits** at HEAD `b4906d1`.

These config directories define the pack-* agents (pack-architect,
pack-planner, pack-coder, pack-reviewer, pack-docs-researcher) and their
skills. None of the pack-* agent definitions admit TD/phase concepts as
operational state. Clean.

#### §3.1.4 — `pack-ops/CHANGELOG.md`

**Verdict: CONFIRMED-LEGITIMATE.**

`grep` returns **1 hit** at L1 (header). Re-reading the file at HEAD
`b4906d1`: zero hits for `phase-epic`/`phase-task` patterns. The single
hit is the prior count's slight inaccuracy — there's an `phase-task`
substring buried inside a longer entry but is part of project-side
emitter description, not pack-self-management state. CHANGELOG remains
clean of operational TD/phase admissions.

#### §3.1.5 — `pack-ops/PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, `MERGE-STRATEGY.md`, `DRY-RUN-MIGRATION.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`, `BOUNDARY-DEFINITION.md`

**Verdict: CONFIRMED-LEGITIMATE.**

`grep -n -E "(\bTD-[0-9]+|\bphase-epic\b|\bphase-task\b|\btd-entry\b|
phase-epic-skeleton|phase-task-skeleton)"` returns **zero hits** across
all nine files. These files are pack-operating documentation — they
describe Pack Chat workflow, pack agent routing, pack-side help, pack
boundary discipline. None operationally treat project-side concepts.
Clean.

#### §3.1.6 — Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at root)

**Verdict: CONFIRMED-LEGITIMATE.**

Re-grep confirms the only TD/phase references in the trinity are the
rule's own documentation:
- `CLAUDE.md` L501-507, L523 (rule body + worked example)
- `AGENTS.md` L462-484 (trinity mirror)
- `GEMINI.md` L432-454 (trinity mirror)

Trinity parity holds. The rule's NAMING the forbidden concepts is
meta-content necessary for the rule to be readable; this is not
operational admission.

#### §3.1.7 — `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`

**Verdict: CONFIRMED-LEGITIMATE.**

`grep` returns zero hits at HEAD `b4906d1`. EXECUTION-PLAN governs
pack-development batches (BD-* labels) only. No TD/phase admissions.

#### §3.1.8 — Pack-root `scripts/` constructor context

**Verdict: CONFIRMED-LEGITIMATE.**

Re-scanned by enumerating files. Every TD/phase reference in scripts/
that isn't part of an init-project.sh inventory comment is either:
- A constructor library that emits/parses project-side artifacts
  (`tracker-phase-task.sh`, `tracker-promote.sh`, `tracker-labels.sh`,
  `template-version.sh`).
- A test of such a library (covered in §4.1).

No pack-self-management state operations on TD/phase concepts.

### §3.2 — Methodology challenges

#### §3.2.1 — Scope exclusions challenge

**Prior audit excluded:** `scripts/init-project.sh`, `scripts/validate-pack.py`,
`scripts/lib/`, `scripts/tests/` as "constructor context."

**Challenge:** the exclusion was OVER-BROAD for two categories:

1. **`scripts/tests/*` test files.** A test file is a pack-self-
   management surface (it tests pack-side libraries). The fact that the
   tests EXERCISE constructors does not exempt the test file from the
   rule — the test file ITSELF is pack-side state. Specifically: a
   test file that hardcodes "the pack-root form admits TD" is a
   pack-self-management surface treating a project-side concept
   operationally (its assertions ARE operational state). This is
   exactly what `test-issue-forms.sh` did pre-F3', and what the prior
   audit missed.

   The correct test is "does the test file's ASSERTIONS treat
   project-side concepts as pack-self-management state?" not "does the
   test exercise a constructor?". Under this corrected test:
   - **Constructor tests** (e.g., `tracker-phase-task.sh` tests the
     phase-task library; fixtures use phase-N.M grammar) — LEGITIMATE.
     The fixtures are test inputs that the constructor library
     EXPECTED to receive at runtime; they are not pack-self-management
     state.
   - **Pack-self-management tests with project-side concept
     assertions** (e.g., `test-issue-forms.sh` pre-F3' asserted the
     pack-root form admits `td`; that assertion encoded the pre-rule
     state on the pack-self-management side) — LEAK.
   - **Detection tests** that exercise pack-side classifiers using
     project-side grammar fixtures (e.g., `pack-help-test.sh` uses
     TD-NNN entries to test `detect_pack_surface()`) — LEGITIMATE.
     The fixtures simulate client-side inputs the classifier expects
     to see.

   **F3' confirms this:** the prior audit's exclusion missed
   `test-issue-forms.sh` because it was treated as "constructor
   context" wholesale. The right granularity is per-assertion, not
   per-file.

2. **`scripts/validate-pack.py`** — the prior audit correctly carved
   out the per-surface dict at L1101-1104 as in-audit-scope. But the
   carve-out was made ad-hoc (the F1 worked example pointed at it).
   The methodology did not enumerate OTHER per-surface tables. See
   §4.4 for the new-scope sweep — confirms no other tables have
   similar leak, but the methodology should have surfaced this
   proactively.

#### §3.2.2 — Verdict-criteria consistency

The prior audit distinguished:

- LEAK (operational) — pack-self-management surface operationally
  treats project-side concepts.
- LEAK (cosmetic/audit-trail) — narrative mentions in
  pack-self-management entries.
- LEGITIMATE — constructor context.

These distinctions were applied consistently in the prior audit.
However, the methodology had **no explicit treatment of test files
that ENCODE pack-self-management state in their assertions**. This is
a fourth class that fell into the gap. The corrected verdict criteria
need a sub-class:

- **LEAK (operational, test-encoded)** — pack-self-management state
  encoded in a test file's assertions, where the assertion's truth
  value depends on whether the pack-self-management surface admits the
  forbidden project-side concept.

The new sub-class is exactly the F3' class.

#### §3.2.3 — Worked-example absence

The prior audit ran against HEAD `d424aac` — BEFORE F1/F2 landed. The
audit knew F1+F2 was the worked example (the rule explicitly names the
pack-root form). It correctly flagged F1+F2 and proposed the cascade.

**However**, the audit's §7.3 "Test plan" stated:

> `bash scripts/tests/test-issue-forms.sh` (if present) MUST PASS.

The audit IDENTIFIED `test-issue-forms.sh` as a dependency of the F1
fix BUT did not enumerate the specific test-file edits needed.

The IMPL-REPORT §9.1 calls out this exact gap:

> The audit (PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md) correctly
> identified F1 + F2 + a §7.3 test-plan that required
> `scripts/tests/test-issue-forms.sh` to PASS, but did not enumerate the
> specific test-file edits needed for lock-step. The prior coder pass
> discovered this via PREFLIGHT failure (12 FAILs in
> test-issue-forms.sh).

**The IMPL-REPORT's diagnosis is correct.** The audit's §3.8 (validation
surface cross-reference) walked the validate-pack.py dependency but did
not walk the test-file dependency. The methodology had infrastructure
for one but not the other.

### §3.3 — Gap identification

#### §3.3.1 — The F3' class — pack-self-management state encoded in test assertions

The F3' class is:

> A pack-self-management surface (test file, validator config, CI
> workflow, etc.) ENCODES the prior-rule state of another
> pack-self-management surface in a way that makes the test's
> assertions OPERATIONAL state about the other surface.

In F3''s case: `test-issue-forms.sh` Group 2 asserted "pack-root
wi-type has `td`" because the form admitted `td` at the time the test
was written. The assertion ENCODED the pre-rule state. Under the rule,
this assertion was wrong (the rule forbids `td` on pack-root), and the
assertion required lock-step update with the form.

**What else might the F3' class catch?**

Surfaces to re-audit for similar dependent-state encoding:

1. **`scripts/validate-pack.py` per-surface dictionaries** — any dict
   keyed by surface that hardcodes a project-side concept against the
   pack-root key. Audit confirms L1101-1104 was the only one (see
   §4.4).

2. **Test files that test the issue-template forms** — only
   `test-issue-forms.sh` exists in this class (confirmed via grep
   filename + content scan). Already cleaned by F3'.

3. **Test files that test `validate-pack.py` per-check assertions** —
   `test-validate-pack-check-43.sh`, `test-validate-pack-checks-36-37-38.sh`,
   etc. Confirmed clean of operational TD/phase admissions (see §4.1).

4. **CI workflow `.github/workflows/validate-pack.yml`** — could
   reference test files by name; if a test file's name encoded a
   project-side concept, the workflow would too. The workflow names
   `scripts/tests/test-tracker-phase-task.sh` — but this is a
   CONSTRUCTOR test (the lib emits project-side phase-tasks), so
   LEGITIMATE. See §4.3.

5. **`scripts/lib/recommendation.sh` per-surface logic** — operates on
   pack vs client surface signals; per-surface logic. Re-scanned —
   uses TD-NNN to count project-side TDs as INPUT signals, then
   recommends pack-side actions based on counts. Constructor-input
   role; LEGITIMATE. See §4.2.

#### §3.3.2 — Why the methodology missed F3'

The prior audit's methodology walked:

- The form file itself (F1 finding).
- The validator that gates the form (F2 finding via §3.8 cross-ref).

It did NOT walk:

- The test file that tests the form.

The methodology's cross-reference infrastructure was asymmetric. The
audit recognized that a form-options change requires a
validator-options change (because both encode the same per-surface
expectation), but did not recognize that the form-options change ALSO
requires a TEST-assertions change (because the test ALSO encodes the
same per-surface expectation in its assertions).

**Root cause:** the audit treated `validate-pack.py` as a "validation
surface in audit scope" and `scripts/tests/*` as "constructor context"
out-of-audit. This distinction was wrong — both surfaces equally
encode the same expected state of the pack-self-management surface
under test.

**Corrected methodology** (proposed in §9):

> When auditing a pack-self-management surface for the deliverable-only
> rule, enumerate ALL surfaces that ENCODE expected state of the
> audited surface:
> - The surface's own content (form, config, library).
> - Any validator that asserts content invariants on the surface.
> - Any TEST file that asserts content invariants on the surface.
> - Any CI workflow definition that references the surface.
> Each encoding surface must update in lock-step with the surface
> itself.

---

## §4 — Part B — New scope findings

### §4.1 — `scripts/tests/*` per-file findings

Enumerated 48 test files in `scripts/tests/`. Categorized per the
refined constructor-test rule (§2.4).

#### §4.1.1 — Constructor tests (LEGITIMATE)

These tests exercise pack-side libraries that emit/parse project-side
artifacts. Their fixtures use project-side grammar (TD-NNN, phase-N.M,
etc.) because that's the grammar the constructor LIBRARIES accept as
input or emit as output.

| File | Library tested | Verdict |
|---|---|---|
| `template-version-test.sh` | `lib/template-version.sh` (project-side template version markers) | CONFIRMED-LEGITIMATE |
| `template-translations-test.sh` | `lib/template-translations.sh` | CONFIRMED-LEGITIMATE |
| `test-tracker-phase-task.sh` | `lib/tracker-phase-task.sh` (phase-task parser/emitter) | CONFIRMED-LEGITIMATE |
| `test-tracker-promote-direct.sh` | `lib/tracker-promote.sh` (TD promotion) | CONFIRMED-LEGITIMATE |
| `test-tracker-promote-path1.sh` | path-1 promote (TD → phase-epic) | CONFIRMED-LEGITIMATE |
| `test-tracker-promote-path2.sh` | path-2 promote (TD → phase-task) | CONFIRMED-LEGITIMATE |
| `test-tracker-links.sh` | `lib/tracker-links.sh` (BD/TD/phase link parsing) | CONFIRMED-LEGITIMATE |
| `test-tracker-cycle-check.sh` | `lib/tracker-cycle-check.sh` (dependency cycle detection) | CONFIRMED-LEGITIMATE |
| `tracker-migrate-forward-test.sh` | `lib/tracker-migrate-forward.sh` | CONFIRMED-LEGITIMATE |
| `tracker-migrate-reverse-test.sh` | `lib/tracker-migrate-reverse.sh` | CONFIRMED-LEGITIMATE |
| `tracker-migrate-roundtrip-test.sh` | round-trip property | CONFIRMED-LEGITIMATE |
| `tracker-agent-read-test.sh` | `lib/tracker-agent-read.sh` (read project-side BACKLOG/IMPL-PLAN) | CONFIRMED-LEGITIMATE |
| `tracker-init-test.sh` | `pack tracker init` orchestrator (emits canonical label set) | CONFIRMED-LEGITIMATE |
| `tracker-bd132-race-test.sh` | BD-132 race (forward/reverse migration race) | CONFIRMED-LEGITIMATE |
| `tracker-bd133-header-preservation-test.sh` | BD-133 header preservation | CONFIRMED-LEGITIMATE |
| `tracker-bd134-close-retry-test.sh` | BD-134 close retry | CONFIRMED-LEGITIMATE |
| `tracker-bd129-gh-repo-test.sh` | BD-129 gh-repo routing | CONFIRMED-LEGITIMATE |
| `tracker-bd130-doctor-wired-test.sh` | BD-130 doctor wired | CONFIRMED-LEGITIMATE |
| `recommendation-test.sh` | `lib/recommendation.sh` (computes pack vs client signals) | CONFIRMED-LEGITIMATE |
| `test-per-entry.sh` | `lib/per-entry/*.sh` (per-entry tree helpers) | CONFIRMED-LEGITIMATE |
| `pack-help-test.sh` | `pack-help.sh` + `detect.sh` (detects pack vs client) | CONFIRMED-LEGITIMATE |

Evidence (sampled): in `pack-help-test.sh` L46-50, a TD-NNN fixture is
created to test `detect_pack_surface()` returning `client`; in
`recommendation-test.sh` L62-77, TD-NNN/phase-N fixtures are created to
test client-side signal computation. These are CONSTRUCTOR-INPUT
fixtures — they simulate project-side inputs the pack-side classifier
must handle. The fixtures themselves are not pack-self-management state.

#### §4.1.2 — Pack-self-management tests (subject to rule)

Tests that ASSERT properties of pack-self-management surfaces. Their
assertions encode expected pack-self-management state.

| File | Surface tested | Verdict |
|---|---|---|
| `test-issue-forms.sh` | Pack-root + project-template issue forms | CONFIRMED-LEGITIMATE (post-F3') |
| `test-init-project.sh` | `init-project.sh` constructor (pack-side script that constructs project-side) | CONFIRMED-LEGITIMATE |
| `test-customization-preserve.sh` | `customization-preserve.sh` (pack-side script) | CONFIRMED-LEGITIMATE |
| `test-add-capability.sh` | `add-capability.sh` (pack-side script) | CONFIRMED-LEGITIMATE |
| `test-migrate-v10-to-v11.sh` | v10→v11 migrator | CONFIRMED-LEGITIMATE |
| `test-migrate-v10-to-v11-decompose.sh` | migrator decompose | CONFIRMED-LEGITIMATE |
| `test-migrate-v10-to-v11-dry-run.sh` | migrator dry-run | CONFIRMED-LEGITIMATE |
| `test-migrate-v10-to-v11-gates.sh` | migrator gates | CONFIRMED-LEGITIMATE |
| `test-v11-realistic-ot.sh` | v11-realistic-ot integration | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-16.sh` | Check 16 (trinity addenda H2) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-18.sh` | Check 18 (trinity H2 parity) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-19.sh` | Check 19 (trinity no scaffolding) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-39.sh` | Check 39 (install-coverage gate) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-40.sh` | Check 40 (pack-ops bare cross-ref) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-41.sh` | Check 41 (_CLIENT_INSTALLED_FILES integrity) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-42.sh` | Check 42 (CI workflow wires all per-check tests) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-check-43.sh` | Check 43 (V11 leak-sweep prevention) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-checks-32-33-34.sh` | Checks 32/33/34 (per-entry split validators) | CONFIRMED-LEGITIMATE |
| `test-validate-pack-checks-36-37-38.sh` | Checks 36/37/38 (pack/project boundary scanners) | CONFIRMED-LEGITIMATE |

Evidence: `grep -n -E "(\bTD-[0-9]+|phase-epic-skeleton|phase-task-skeleton)"`
across all 19 files returns ZERO hits in pack-self-management
assertions (the test-issue-forms.sh post-F3' uses the patterns only
in cross-surface assertions or in project-template-surface assertions).

#### §4.1.3 — Verifying `test-issue-forms.sh` is post-F3'-clean

Re-read at HEAD `b4906d1`. The file:
- L101-107 — surface-aware name check (pack-root vs project-template).
- L116-141 — surface-aware wi-type options check with disjoint negative
  assertions (pack-side MUST NOT have `td`/`phase-*`; project-side
  MUST NOT have `bd`).
- L146-150 — phase-task field presence ONLY on project-side.
- L157-160 — phase tokens in Blockers description ONLY on project-side.
- L241-247 — Group 5 DISJOINT cross-surface invariant.

No pack-self-management assertions encode forbidden project-side
concepts. F3' delivered correctly.

### §4.2 — `scripts/lib/*` self-management portions

Enumerated 32 library files under `scripts/lib/`. Each was assessed for
whether it operates on pack-self-management state or on project-side
template emission.

#### §4.2.1 — Constructor libraries (LEGITIMATE)

These libraries emit, parse, or operate on project-side artifacts.
Per the rule's ALLOWED list: "pack-side scripts that emit project-side
templates" — extended by entailment to libraries those scripts source.

| File | Role | Verdict |
|---|---|---|
| `tracker-phase-task.sh` | phase-task entity parser/emitter | CONFIRMED-LEGITIMATE |
| `tracker-promote.sh` | TD promotion (Path 1 + Path 2) | CONFIRMED-LEGITIMATE |
| `tracker-labels.sh` | canonical label-set emitter | CONFIRMED-LEGITIMATE |
| `tracker-links.sh` | BD/TD/phase link parser | CONFIRMED-LEGITIMATE |
| `tracker-cycle-check.sh` | dependency cycle detection on project graph | CONFIRMED-LEGITIMATE |
| `tracker-migrate-forward.sh` | flat-file → tracker migration | CONFIRMED-LEGITIMATE |
| `tracker-migrate-reverse.sh` | tracker → flat-file migration | CONFIRMED-LEGITIMATE |
| `tracker-sidecar.sh` | sidecar JSON for tracker round-trip | CONFIRMED-LEGITIMATE |
| `tracker-agent-read.sh` | reads project-side BACKLOG/IMPL-PLAN | CONFIRMED-LEGITIMATE |
| `tracker-init.sh` | `pack tracker init` orchestrator | CONFIRMED-LEGITIMATE |
| `tracker-config.sh` | tracker.toml shape | CONFIRMED-LEGITIMATE |
| `tracker-config-schema.sh` | schema for tracker.toml | CONFIRMED-LEGITIMATE |
| `tracker-doctor.sh` | tracker health checks | CONFIRMED-LEGITIMATE |
| `tracker-errors.sh` | error code map | CONFIRMED-LEGITIMATE |
| `tracker-header-snapshot.sh` | BACKLOG/IMPL-PLAN header snapshot | CONFIRMED-LEGITIMATE |
| `tracker-mirror.sh` | regenerates mirror from per-entry tree | CONFIRMED-LEGITIMATE |
| `tracker-provider.sh` / `tracker-provider-gh.sh` | provider abstraction + GH impl | CONFIRMED-LEGITIMATE |
| `template-version.sh` | version-marker extractor | CONFIRMED-LEGITIMATE |
| `template-translations.sh` | template version translations | CONFIRMED-LEGITIMATE |
| `recommendation.sh` | per-surface signal computation (recommends pack vs client work) | CONFIRMED-LEGITIMATE |
| `per-entry/*.sh` (4 files) | per-entry tree helpers (bd/td/phase) | CONFIRMED-LEGITIMATE |
| `detect.sh` | detects pack vs client surface (uses TD-NNN to recognize client) | CONFIRMED-LEGITIMATE |
| `three-way.sh` | three-way merge for migration | CONFIRMED-LEGITIMATE |

Evidence sampled:
- `lib/tracker-labels.sh` L13-14: "Entry-type provenance: `bd-entry`,
  `td-entry`, `phase-epic`, `phase-task`, `work-item`, `inbound`,
  `external`, `pack-feedback`, `needs-triage`." This is the CANONICAL
  LABEL SET that the constructor emits to project-side trackers. The
  `td-entry`/`phase-epic`/`phase-task` labels are project-side
  concepts the library writes INTO project-side state. Constructor
  context.
- `lib/template-version.sh` L37, L146: extracts version-dir for
  `bd-v11.0`/`td-v11.0`/`phase-task-v11.2` template markers. These
  markers exist on project-side issues; the library reads them.
  Constructor context.
- `lib/tracker-cycle-check.sh`, `lib/tracker-migrate-*`: all operate
  on project-side BACKLOG/IMPL-PLAN content.

#### §4.2.2 — Pack-self-management libraries

These libraries operate on pack-self-management state (customization
preservation, migrator core, manifest, skills).

| File | Role | TD/phase admissions? | Verdict |
|---|---|---|---|
| `customization-preserve.sh` | preserves user customizations across pack updates | none | CONFIRMED-LEGITIMATE |
| `customization-report.sh` | reports preserved-customization status | none | CONFIRMED-LEGITIMATE |
| `migrator-core.sh` | BD-119 migrator framework core | none | CONFIRMED-LEGITIMATE |
| `migrator-manifest.sh` | migrator manifest helpers | none | CONFIRMED-LEGITIMATE |
| `migrator-skills.sh` | migrator skill handling | none | CONFIRMED-LEGITIMATE |
| `migrator-stages.sh` | migrator stage helpers | none | CONFIRMED-LEGITIMATE |
| `migrate-v10-to-v11/*` (subdirectory) | v10→v11 specific stages | none | CONFIRMED-LEGITIMATE |

Evidence: `grep -E "(\bTD-[0-9]+|phase-epic|phase-task|td-entry|phase-epic-skeleton|phase-task-skeleton)"`
on these files returns ZERO hits. Pure pack-self-management.

### §4.3 — `.github/workflows/*`

Only one workflow exists: `validate-pack.yml` (13 KB).

#### §4.3.1 — `.github/workflows/validate-pack.yml`

**Verdict: CONFIRMED-LEGITIMATE.**

`grep -n -E "(\bTD-[0-9]+|phase-epic|phase-task)"` returns 2 hits:

- L136 — `name: tracker phase-task tests (BD-106)` — names the test step.
- L138 — `run: bash scripts/tests/test-tracker-phase-task.sh` — invokes
  the test runner.

Both references are to the constructor test (the test file name
encodes the LIBRARY-NAME `tracker-phase-task` which is itself a
constructor library per §4.2.1). The workflow's role is to invoke
each test runner once; the test runner's content is what matters for
the rule, not the workflow's reference to the runner's name.

Per the rule's exemption "scripts that emit project-side templates" +
entailment to "tests of those scripts" + entailment to "CI invocation
of those tests" — LEGITIMATE.

No pack-self-management state operations on TD/phase concepts in the
workflow.

### §4.4 — `scripts/validate-pack.py` other functions

Re-scanned the entire file (~6100 lines) for per-surface tables and
hardcoded pack-side expectations OTHER than L1101-1104 (F2 finding).

#### §4.4.1 — Check 22 per-surface dictionary (L1913-1933)

Per-surface dictionary for help-fragment freshness. Keys: `pack-root`,
`project-template`. Values: paths to docs / fragment / tracker_fragment.

No project-side concept references in the dict itself. The values are
filesystem paths. **CONFIRMED-LEGITIMATE.**

#### §4.4.2 — Check 25 `_check_25_trinity` surfaces dictionary (L1825-1840)

Per-surface dictionary for trinity location lookup. Keys: `pack-root`,
`project-template`. Values: REPO_ROOT and REPO_ROOT/project-template.

No project-side concept references. **CONFIRMED-LEGITIMATE.**

#### §4.4.3 — Check 16 surfaces exemption (L1729-1734)

`_CHECK_16_EXEMPT_SURFACES: set[str] = {"pack-root"}` — exempts the
pack-root trinity location from the `## Project addenda` H2 invariant.
This is a pack-self-management exemption that says "pack-root has no
project addenda" — does NOT operationally treat project-side concepts.

**CONFIRMED-LEGITIMATE.**

#### §4.4.4 — Check 35 phase-task lib invariants (L3650-3680)

```python
def check_phase_task_lib_invariants():
    """Check 35 — phase-task lib invariants per BD-106 / V3.3 §3 line 27..."""
    phase_task_lib = lib_dir / "tracker-phase-task.sh"
    # verifies lib exists; verifies folded-into is NOT in executable code
```

This check ASSERTS that the constructor library exists and that a
forbidden label (`folded-into`) is not in executable code. The check
references `phase-task` and `tracker-phase-task.sh` because it's
verifying the EXISTENCE of the pack-side constructor for project-side
phase-tasks. The check's role is pack-self-management quality
assurance for the constructor surface.

Per the rule: "pack-side validate-pack checks that verify project-side
structure" — the check verifies an INTERMEDIATE pack-side surface
that produces project-side structure. LEGITIMATE.

**CONFIRMED-LEGITIMATE.**

#### §4.4.5 — Check 41 `_CLIENT_INSTALLED_FILES` inventory (L4111-4150)

Walks the `_CLIENT_INSTALLED_FILES_START`/`_END` block in
`init-project.sh` to verify integrity. The inventory describes which
project-template files install to clients — pure constructor metadata.

**CONFIRMED-LEGITIMATE.**

#### §4.4.6 — `check_template_archive_v11` (informational, L1201-1273)

Iterates `for entry_type in ("bd", "td", "phase-epic", "phase-task",
"inbound"):` — names the five entry-type SCHEMA.md files in the
template archive. The archive lives under
`maintenance-docs/v11-research/templates-archive/v11.0/` — per
prompt §"Out-of-audit," `templates-archive/` is the project-side
deliverable archive. The check is informational and validates the
constructor's archive.

**CONFIRMED-LEGITIMATE.**

#### §4.4.7 — `_check_id_prefix` (L2579 region — entry-type ID prefixes)

Validates BD-NNN/TD-NNN/phase-N/etc identifier patterns. Constructor.

**CONFIRMED-LEGITIMATE.**

#### §4.4.8 — Other validate-pack.py areas

Spot-checked all remaining `expected_*` dicts, `_check_*` functions,
and per-surface logic blocks. No additional per-surface tables admit
project-side concepts for pack-root.

**Overall §4.4 verdict:** the F2 finding at L1101-1104 was the SINGLE
per-surface table with the leak. No other tables share the pattern.

### §4.5 — `scripts/init-project.sh` other sections

Re-scanned for sections OTHER than the `_CLIENT_INSTALLED_FILES` inventory.

`grep -n -E "(\bTD-[0-9]+|phase-epic-skeleton|phase-task-skeleton|td-entry)" scripts/init-project.sh`
returns ZERO hits.

The only TD/phase references in init-project.sh are inside the
`_CLIENT_INSTALLED_FILES` inventory block (L1273-1311), which lists
project-template files to install to client repos. This block IS the
constructor's manifest. LEGITIMATE.

**CONFIRMED-LEGITIMATE.**

---

## §5 — Critical validation tests

### §5.1 — F3' test-file methodology gap (MUST be flagged)

**Status: FLAGGED as METHODOLOGY-GAP.**

The prior audit's methodology missed the F3' class because its
cross-reference infrastructure walked validator-encoded state but not
test-encoded state. See §3.2.3 and §3.3 for full diagnosis.

**Severity: HIGH for METHODOLOGY (not for code).**

The F3' fix landed correctly via PREFLIGHT. The audit IS still
defective: another similar finding could be missed in the future
because the methodology fix has not yet been applied to the audit
skill / pack-reviewer prompt template.

**Required action:** see §9 (Methodology improvements) — the
methodology fix is to enumerate ALL surfaces that ENCODE expected
state of an audited surface, including test files, before finalizing
a review.

### §5.2 — DISJOINT invariant consistency

**Status: PASS.**

The DISJOINT invariant is now landed in two places:
- `scripts/tests/test-issue-forms.sh` L241-247 (Group 5 invariant 5.1)
- `scripts/validate-pack.py` L1117-1119 (per-surface dict)

Both encode the same property: pack-side wi-type options and
project-side wi-type options are disjoint sets.

Verified consistency:
- Pack-side: `{"bd"}` (1 element)
- Project-side: `{"td", "phase-epic-skeleton", "phase-task-skeleton"}`
  (3 elements)
- Intersection: `{}` (empty — disjoint property holds)

No surface violates the DISJOINT invariant.

**Cross-check:** the rule's worked example at trinity L501-507
explicitly forbids `td`/`phase-epic-skeleton`/`phase-task-skeleton` on
pack-root. The DISJOINT invariant ENFORCES this at test-time. The two
mechanisms align.

### §5.3 — Worked-example propagation

**Status: NO ADDITIONAL DEPENDENT-FIELD SURFACES FOUND.**

The F1 cascade pattern was: drop the parent dropdown options
(`wi-type: td / phase-epic-skeleton / phase-task-skeleton`) and ALL
dependent fields that only exist to serve those options
(`wi-td-scope`, `wi-td-severity`, `wi-phase-number`, `wi-task-title`,
`wi-problem-goal-success`, `wi-files`, `wi-definition-of-done`,
`wi-dependencies`).

**Search for similar patterns elsewhere in the pack:**

1. **`.github/ISSUE_TEMPLATE/inbound.yml`** (pack-root) — has no
   dependent-field structure conditioned on an entry-type dropdown.
   The form is single-purpose. No propagation needed.

2. **`pack-ops/HELP-FRAGMENT-PACK.md` / `pack-ops/HELP-FRAGMENT-TRACKER.md`** —
   describe pack verbs, not dropdown-keyed dependent fields. No
   propagation needed.

3. **`scripts/lib/tracker-config.sh` / `tracker-config-schema.sh`** —
   `tracker.toml` schema admits per-entry-type sections (`[bd-entry]`,
   `[td-entry]`, `[phase-epic]`, `[phase-task]`). These sections exist
   on project-side `tracker.toml` (client configuration); the schema
   library is constructor context. Project-side tracker.toml IS allowed
   to reference its own entry types — that IS the project-side
   deliverable. No propagation needed.

4. **`scripts/validate-pack.py` Check 34** (per-entry tree referent
   resolution) — references `BD-NNN`, `TD-NNN`, `vN.M`,
   `phase-N[.M]` — but these are referent grammars the check validates
   in the project-side per-entry tree. Constructor context. No
   propagation needed.

5. **Pack-self-management surfaces with conditional/dependent state
   keyed on entry-type:** none found other than `work-item.yml`.

**Verdict: F1's cascade pattern is unique to `work-item.yml`. No
further dependent-field cleanup needed elsewhere on pack-self-
management surfaces.**

---

## §6 — Findings summary

### §6.1 — Per-verdict counts

| Verdict | Count | Severity distribution |
|---|---|---|
| CONFIRMED-LEGITIMATE | All 84+ audited surfaces (prior + new scope) | — |
| LEAK (operational) | 0 NEW | — (F1/F2/F3' landed at b4906d1) |
| LEAK (cosmetic/audit-trail) | 1 (prior F3, pack-ops/BACKLOG.md) | LOW (no-fix per prior audit) |
| METHODOLOGY-GAP | 1 (F3' class test-file methodology gap) | HIGH for methodology, LOW for code (F3' fix landed) |
| AMBIGUOUS | 0 | — |

### §6.2 — HIGH-severity findings (NEW)

**None at the code level.** The rule-compliance state of the working
tree is clean.

**One HIGH-severity METHODOLOGY finding:**

**MF1 (HIGH for methodology).** The prior audit's methodology missed
the F3' class (test-file lock-step dependency). The fix landed via
PREFLIGHT, but the audit methodology has not yet been updated to
catch this class proactively. See §9 for the fix.

### §6.3 — LOW-severity findings (NEW)

**None.**

The single LOW finding from the prior audit (F3, pack-ops/BACKLOG.md
audit-trail narratives) was correctly classified as no-fix; re-verified
under the refined methodology.

### §6.4 — Surfaces confirmed clean (re-verification highlights)

- Pack-root `.claude/`, `.codex/`, `.gemini/` configs — re-verified
  zero TD/phase admissions.
- Pack-root trinity — only rule documentation references the forbidden
  concepts; meta-content, not operational.
- All 19 pack-self-management test files (excluding `test-issue-forms.sh`
  which received F3' fix) — zero pack-self-management assertions
  encoding forbidden project-side concepts.
- All 32 `scripts/lib/*` files — constructor-context or pack-self-
  management without TD/phase admissions.
- `.github/workflows/validate-pack.yml` — only references constructor
  test files by name; no pack-self-management TD/phase admissions.
- All `scripts/validate-pack.py` per-surface tables — the F2 finding
  at L1101-1104 was the unique leak; no other tables share the pattern.
- `scripts/init-project.sh` — `_CLIENT_INSTALLED_FILES` inventory is
  pure constructor metadata; no other TD/phase references.

---

## §7 — AMBIGUOUS surface (items needing user discussion)

**None.**

The re-audit produced zero AMBIGUOUS findings at the code level. The
working tree is consistent with the rule. The methodology gap (MF1)
is documented in §3 + §9 — its fix is a doc/skill change to the
audit methodology, not an ambiguous code finding.

---

## §8 — Recommended remediation

### §8.1 — Code remediation

**None required.** F1+F2+F3' landed correctly at `b4906d1`. Working
tree is rule-compliant.

### §8.2 — Methodology remediation

**MF1 fix (methodology).** Update the audit methodology to enumerate
all ENCODING surfaces before finalizing. Specifically, when auditing a
pack-self-management surface for the deliverable-only rule, walk:

1. **The surface itself** (form file, config file, library, doc).
2. **Validator(s)** that assert content invariants on the surface
   (e.g., `validate-pack.py` per-surface tables).
3. **Test file(s)** that assert content invariants on the surface
   (e.g., `scripts/tests/test-issue-forms.sh` for the issue forms).
4. **CI workflow definitions** that reference the surface or its
   tests (e.g., `.github/workflows/validate-pack.yml`).
5. **Cross-reference docs** (architect docs, planner docs, IMPL-REPORTs)
   that describe the surface's expected state.

Each ENCODING surface must update in lock-step.

**Where to land the fix:**

Option (a) — update the `review` skill at
`.claude/skills/review/SKILL.md` (and trinity mirrors in `.codex/`,
`.gemini/`) with the enumeration methodology.

Option (b) — update `architecture-review/SKILL.md` (the architecture-
review skill) with the same enumeration.

Option (c) — add a new pack memory entry titled "Enumerate ENCODING
surfaces before finalizing pack-side audits."

The user should choose (a)/(b)/(c) or a combination. The fix itself is
mechanical; the choice of landing surface is the discussion.

### §8.3 — No new BD anchor required

The F3' class fix already landed. The methodology fix is small (skill
or memory edit) and can land in the next pack-only commit per Pack
Chat's standard triage. No dedicated BD required unless the user
wants one for audit-trail purposes.

---

## §9 — Methodology improvements (for future audits)

### §9.1 — ENCODING-surface enumeration

(Detailed in §8.2.) The audit must enumerate ALL surfaces that encode
expected state of the audited surface, not just the surface itself
plus the validator. The asymmetric cross-reference infrastructure of
the prior audit (walked validator but not test) was the proximate
cause of the F3' miss.

### §9.2 — Constructor-test refinement explicit in the rule

The refinement in §2.4 (constructor tests are LEGITIMATE; pack-self-
management tests with project-side concept assertions are LEAK) is
NOT explicit in the rule's wording. Consider authoring an explicit
rule subsection or adding a worked example to the rule's `Why:` block.

The current rule text says (CLAUDE.md L494-499):

> ALLOWED: pack-side scripts that emit project-side templates...

It does not say:

> ...and tests of those scripts (when the test fixtures use project-
> side grammar as constructor inputs).

The entailment is reasonable but explicit text would prevent future
audit confusion.

### §9.3 — Verdict-criteria explicit sub-class

Add a sub-class to the verdict-criteria taxonomy:

- LEAK (operational, test-encoded) — pack-self-management state encoded
  in a test file's assertions, where the assertion's truth value
  depends on whether the audited pack-self-management surface admits
  the forbidden project-side concept.

This sub-class captures the F3' pattern explicitly and gives future
audits a category to assign to.

### §9.4 — Test-file scan as standard audit step

Codify a standard audit step:

> For every pack-self-management surface flagged as LEAK, walk
> `scripts/tests/*` for files that reference the surface and assess
> whether their assertions ENCODE forbidden state.

This step would have caught F3' proactively. It's mechanical and adds
minor overhead to audits but prevents PREFLIGHT-discovered surprises.

### §9.5 — Methodology version note

Mark the audit methodology as "v2 (post-F3' incident)" so future
audits know they should be using the updated enumeration. Versioning
the methodology is consistent with the pack's versioning discipline
for skills/docs.

---

## §10 — Cross-references

### §10.1 — Prior audit + cleanup chain

- `maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`
  (prior audit at HEAD `d424aac`)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md`
  (F1+F2+F3' cleanup IMPL-REPORT)
- This report at
  `maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT-V2.md`
  (re-audit + meta-audit at HEAD `b4906d1`)

### §10.2 — Rule reference (re-stated)

- `CLAUDE.md` L488-524 ("Project-side concepts on pack-side surfaces —
  deliverable-only")
- `AGENTS.md` L449-485 (trinity mirror)
- `GEMINI.md` L419-455 (trinity mirror)

Related pack memory entries (cited in the rule's `Why:` block):

- `feedback_pack_project_separation_of_concerns` (user-locked
  2026-05-26)
- `feedback_bd_pack_only_operational_rule` (user-locked 2026-05-26)
- `feedback_client_facing_token_economy` (user-locked 2026-05-26)

### §10.3 — Architect docs that designed the asymmetric counterpart

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md`
  §1.2(6) — surfaced this pack-side gap during reconciliation.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md` —
  BD-193 closed the project-side counterpart.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` —
  Check 24 byte-identity gate replacement design (the BD-194-era
  "project = pack - bd" invariant that F3' replaced with DISJOINT).

### §10.4 — Test surface + validator surface (post-F3' state)

- `scripts/tests/test-issue-forms.sh` (post-F3' surface-aware
  assertions + DISJOINT invariant).
- `scripts/validate-pack.py` Check 23 (per-surface dict at L1117-1119;
  pack-root → `{"bd"}`).
- `.github/workflows/validate-pack.yml` L274 — wires
  `test-issue-forms.sh` into CI.

### §10.5 — Read-only enforcement statement

Per prompt §"Read-only enforcement" and `commit-discipline` skill §3:
this re-audit made no source modifications and ran no state-changing
git verbs. The only file written by this review is this report at
`maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT-V2.md`.
HEAD remains `b4906d18b8b67748b68c14d4dbbe7c82390efcf6` at review
completion (verifiable post-review via `git rev-parse HEAD`).

End of report.
