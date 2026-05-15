# PACK-REVIEW-BD-122-RETRO

Retroactive per-BD review of BD-122 ("Document `test-fixtures/`
`<vN>-<persona>` versioning convention"), part of Batch 21c per the
2026-05-15 review/fix cycle memory revision.

## Scope

- **BD:** BD-122
- **Original commit:** `400928a` (2026-05-09) "docs: v11 — BD-122
  fixture-naming convention + table versioning column"
- **In-scope files (per `git show --stat 400928a`):**
  - `test-fixtures/README.md` (+54 / −4 in commit; impl report counts
    +47 / −7 of substantive change)
  - `BACKLOG.md` (+4 / −2 — status flip + Resolved-line only)
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-122.md`
    (now at `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-122.md`)
- **Snapshot judged:** state of files AT commit `400928a`. Later
  additions (e.g., `v11-trinity-marker-prepped` row added by commit
  `4343b0a` 2026-05-10, "Realistic-OT fixtures: per-version pattern"
  subsection added by `3fa3322` 2026-05-12) are out of scope — they
  postdate BD-122 and are governed by their own BDs.
- **Out of scope:** all other BDs, all other batches, current-state
  drift unrelated to the original ship.

## Methodology

- Read `BACKLOG.md` BD-122 entry (problem, acceptance criteria, File/Symbol).
- Read `IMPLEMENTATION-REPORT-BD-122.md` (claimed deliverables + DoD checklist).
- Read `test-fixtures/README.md` at commit `400928a` and current.
- Cross-referenced state at `400928a` against later additions (BD-120, BD-136
  M-8) to distinguish in-scope review concerns from out-of-scope drift.
- Greppped for `BD-122` and `test-fixtures` references across the repo to
  identify cross-cutting touch points.
- Applied the 6 review dimensions and touch-point classification from
  `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.

## Findings

### F1 — `Adding a new fixture` procedure does not reference the new convention

- **Severity:** SHOULD
- **Dimension:** (c) touch points + cross-concept impact
- **Touch-point class:** OWNED
- **Evidence:** `test-fixtures/README.md` lines 129–135 (procedure unchanged
  by BD-122), vs the new `## Naming convention` section at lines 35–57 and
  the new `Versioning` column at line 26. Verified at commit `400928a` via
  `git show 400928a:test-fixtures/README.md` — the procedure block is
  byte-identical pre/post.
- **Description:** BD-122 adds a "Naming convention" section and a new
  "Versioning" column to the fixture table, but the immediately-relevant
  contributor procedure ("Adding a new fixture", 4 numbered steps) was not
  updated. Step 3 ("Document the new fixture in this README's table") tells
  a future contributor to add a row but doesn't remind them to (a) populate
  the new `Versioning` cell or (b) consult the convention to choose the
  fixture name. The convention exists; the procedure that consumes it
  doesn't link in. Future contributors who jump straight to the procedure
  (the natural entry point — it has the imperative steps) can miss the
  convention.
- **Suggested fix:** Add a parenthetical to step 3 and a step 0 referencing
  the convention. Concrete proposal:
  ```
  0. Pick a fixture name per the **Naming convention** above
     (`<vN>-<persona>` for version-pinned, bare hyphenated descriptor
     for version-agnostic).
  ...
  3. Document the new fixture in this README's table — populate all
     columns including `Versioning` (`v10-pinned`, `v11-pinned`, …, or
     `version-agnostic`).
  ```
- **Cross-concept impact:** None. Single-file, single-section edit; no
  other file references this procedure.
- **Rule/principle violated:** Design best practice #1 (single source of
  truth) — the convention IS the source of truth, but a procedure that
  doesn't cite it forks contributor mental models. Soft violation; the
  data still lives in one place, but the procedure-to-rule link is loose.

### F2 — `Versioning` column uses three values; convention text names two

- **Severity:** NIT
- **Dimension:** (a) completeness
- **Touch-point class:** OWNED
- **Evidence:** Column values populated at `400928a` are `v10-pinned`,
  `v11-pinned`, `version-agnostic` (3 distinct strings). Convention text at
  lines 39 and 48 names exactly two patterns: "version-pinned" and
  "version-agnostic". The mapping `v10-pinned` → "version-pinned (anchored
  to v10)" and `v11-pinned` → "version-pinned (anchored to v11)" is
  unstated; a reader must infer that `<vN>-pinned` is the canonical column
  spelling for version-pinned rows.
- **Description:** A reader of the convention section who looks at the
  table sees three distinct values where the rule names two classes. The
  inference is one short hop — `v10-pinned` and `v11-pinned` are obviously
  both version-pinned — but it is a hop, and the column-value pattern
  itself (`<vN>-pinned`) is a third implicit micro-rule the convention
  doesn't state. When `v12-flat-file` lands its row will use `v12-pinned`,
  reinforcing the unstated pattern.
- **Suggested fix:** One short clause in the convention section, e.g., add
  to the end of the version-pinned bullet (line 47):
  ```
  In the table above, version-pinned rows take the form `<vN>-pinned`
  (`v10-pinned`, `v11-pinned`, …); the version-agnostic class uses the
  literal value `version-agnostic`.
  ```
  Tiny — keeps the convention complete with respect to the column
  vocabulary it introduced in the same commit.
- **Cross-concept impact:** None.
- **Rule/principle violated:** Design best practice #1 (single source of
  truth) on column vocabulary.

### F3 — Convention text "snapshot of pack output" elides persona overlay

- **Severity:** NIT
- **Dimension:** (e) design best practice adherence
- **Touch-point class:** OWNED
- **Evidence:** `test-fixtures/README.md` line 55 ("Pick version-pinned
  when the fixture's content is a snapshot of pack output at a specific
  version."). Cross-check against fixtures present at `400928a`:
  `v11-tracker-on` (line 31) is "v11 install + `tracker.toml` with
  `mode.state = "tracker"` and `migration.forward_complete = true` set by
  hand"; `v10-realistic-ot` (line 29) is pack install + four canonical
  customizations.
- **Description:** "Snapshot of pack output at a specific version" is
  technically inaccurate for `v10-realistic-ot` and `v11-tracker-on` —
  both layer persona-specific overlays on top of pack output. The intent
  is clear from context (the version-pinned class includes "pack +
  overlay" rows whose overlay content is itself version-coupled), but the
  precise wording reads as if version-pinned ⇒ raw pack output only,
  which excludes 2 of the 4 version-pinned fixtures shipped at this
  commit.
- **Suggested fix:** Replace "snapshot of pack output at a specific
  version" with "snapshot of (pack output ± persona overlay) at a
  specific version" or equivalent phrasing that admits overlay-bearing
  fixtures.
- **Cross-concept impact:** None.
- **Rule/principle violated:** None of the 7 universal principles
  directly; flagged as accuracy-of-prose. Borderline declinable per the
  fix-all-but-trivial-decline rule.

## Dimensions exercised but yielding zero findings

- **(a) Completeness** beyond F2: BD-122's stated deliverables (Naming
  convention section, "When here vs. elsewhere" paragraph, table
  versioning column) all landed per the impl report DoD and verified by
  diff. No missing deliverable.
- **(b) Edge cases:** Convention text covers tagged-release pinning,
  current-HEAD pinning, and version-agnostic. The fourth class (frozen
  real-world snapshot at a non-tag commit, exemplified by the LATER-added
  `v11-trinity-marker-prepped`) was not yet visible at commit `400928a`
  — BD-136's M-8 fixture spec did not exist in `BACKLOG.md` at that time
  (verified via `git show 400928a:BACKLOG.md`). No retro finding; coverage
  was complete vs. then-existing fixtures.
- **(c) Touch points** beyond F1: Greppped repo-wide for `BD-122` and
  `test-fixtures` references. The only cross-cutting touch was
  `EXECUTION-PLAN-V11.0.md` Batch 1 row (line 284) and §6 Q2 timing
  question (line 414) — both procedural references, neither carries a
  contract that BD-122 broke. Root `README.md` line 211 "Repository
  Layout" mentions `test-fixtures/` as a single line and required no
  update.
- **(d) Pack rule adherence:** Trinity rule does not apply
  (`test-fixtures/README.md` is not in the trinity set). Pack-ops vs
  pack-product separation: `test-fixtures/` is pack-ops (test infra)
  end-to-end; the BD-122 edit stayed within pack-ops. CI validation
  (Check 26) unaffected per impl report. BACKLOG.md edit (status flip +
  Resolved-line) is PM-only territory but the commit was made by Pack
  Chat per the implicit-flip rule, not by an agent — correct procedure.
- **(e) Design best practices** beyond F3: Round-trip / typed errors /
  composition / mode-agnostic / idempotency / additive grammar — none
  apply to a docs-only convention edit.
- **(f) Concept-specific:** No concept-scope doc declared specifically
  for fixture-naming-convention concept; nothing pre-declared to verify.

## ARCH findings

None. No re-architecture trigger fires for any finding above.

## Methodology friction notes

- The methodology assumes a "convention/naming docs" finding mode but
  doesn't pre-declare a checklist for it. The dimensions checked here
  for a docs-only convention BD were: (1) does the rule cover all
  in-scope artifacts? (F2-style); (2) does the rule survive forward
  extension? (F3 pack-output-elision); (3) do procedures that consume
  the rule cite it? (F1 procedure-doesn't-link-convention); (4) do
  cross-cutting docs need updates? (none in this case). Suggest a
  future revision of `CONCEPTUAL-REVIEW-METHODOLOGY.md` add a
  "convention/naming docs" finding-mode checklist alongside the
  existing race-condition heuristic, since these BDs are common and
  share a recognizable pattern.
- The "frozen real-world snapshot" class that emerged with BD-136 M-8
  the day after BD-122 shipped is a textbook case where a convention
  established in BD-N+0 had to admit a new class introduced in BD-N+1.
  Not a BD-122 defect (the M-8 spec didn't exist at `400928a`), but a
  reminder that conventions are versioned artifacts and may need a
  small follow-on update when adjacent batches surface new shapes.

## Summary

Three findings: 1 SHOULD (F1, procedure-to-convention link), 2 NIT (F2
column-vocabulary, F3 prose accuracy). Zero MUST, zero ARCH. The
deliverable matches the BD-122 acceptance criteria; the gaps are
quality-of-doc improvements that the original end-of-batch review
plausibly missed because they are interior consistency issues within a
single file, not cross-file integration concerns.
