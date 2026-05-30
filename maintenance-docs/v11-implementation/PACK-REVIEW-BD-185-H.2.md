# PACK-REVIEW — BD-185 H.2 (INLINE; sliding-window scope = H.2 alone)

## §1 Scope

INLINE per-BD review of H.2 (form-family extension, PROJECT-TEMPLATE-ONLY)
landed at HEAD `e580dda` against the user-locked spec in
`PLAN-BD-185-ADDENDUM.md` §4.2.

**Working-tree HEAD reviewed:** `e580dda7eb46c640a92afabd3469bbada17d1975`
**Pre-H.2 base:** `c770b96b6b99f56af2bba2a88019eafcdb28fc47`
**Branch:** `v11-dev`
**Per-spawn-prompt addendum §4.2:** "INLINE — sliding-window covers
H.2 alone (since H.3 + H.4 inline reviews fire later under their own
H.X scopes per original plan §3 (α-sliding) mapping)".

This review applies the 10-dimension reviewer-focus checklist from
the spawn prompt and the ENCODING-surface enumeration methodology
landed at `f19b585` + `42ce52d`.

## §2 Methodology

10 review dimensions (D1-D10) applied per spawn prompt. Verdict
categories:

- **CONFIRMED-CORRECT** — H.2 application matches user-locked spec.
- **REMEDIATION-NEEDED-MUST** — concrete defect requiring fix.
- **REMEDIATION-NEEDED-SHOULD** — improvement that would strengthen.
- **REMEDIATION-NEEDED-NIT** — cosmetic improvement.
- **AMBIGUOUS** — surface to user for discussion.

Carry-forward discipline per review skill: each finding defaults to
FIX NOW unless ALL THREE high-bar tests pass (SIZE / BLOCKED /
LOGICAL FIT).

ENCODING-surface enumeration applied per the review skill's
"Surface-rule audits — enumerate ENCODING surfaces" section: the
audited surface (form file) was traced through validator (`scripts/
validate-pack.py`), test (`scripts/tests/test-issue-forms.sh`),
archive snapshot, archive INDEX, and CI workflow before finalizing.

Verification commands executed against HEAD `e580dda`:

- `python3 scripts/validate-pack.py` → PASS (final line: "PASSED — all
  checks clean")
- `bash scripts/tests/test-issue-forms.sh` → 77 PASS / 0 FAIL
- `bash scripts/tests/test-validate-pack-check-43.sh` → 7 PASS / 0 FAIL
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` → 8 PASS / 0 FAIL
- `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` → 65 PASS / 0 FAIL
- `bash scripts/tests/test-validate-pack-check-41.sh` → 4 PASS / 0 FAIL
- `bash test-fixtures/build.sh --verify` → 6 fixtures OK

## §3 Per-dimension verdicts

### D1 — PROJECT-TEMPLATE-ONLY (boundary discipline)

**Verdict: CONFIRMED-CORRECT.**

Evidence:

- `git diff c770b96..e580dda --stat` shows ZERO mentions of
  `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root). Diff is
  empty for that path (verified explicitly via `git diff c770b96..
  e580dda -- .github/ISSUE_TEMPLATE/work-item.yml` → empty output).
- `git show c770b96:.github/ISSUE_TEMPLATE/work-item.yml | diff
  - .github/ISSUE_TEMPLATE/work-item.yml` → empty (byte-identical
  pre-H.2 vs HEAD).
- Pack-root form retains `{bd}` wi-type set at `.github/ISSUE_
  TEMPLATE/work-item.yml:22` (line: `- bd`).
- Deliverable-only rule preserved: project-template admits
  `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-
  skeleton}` per L25-28 of `project-template/.github/ISSUE_
  TEMPLATE/work-item.yml`; pack-root admits `{bd}`.

### D2 — 4-option count under BD-068 soft cap

**Verdict: CONFIRMED-CORRECT for live form; REMEDIATION-NEEDED-SHOULD
for the soft-cap-of-5 misstatement in `validate-pack.py` and
`INDEX.md` (see Finding F1 below).**

Evidence (correct application):

- Project-template `wi-type` options count = 4 (L25-28: `td`,
  `phase-epic-skeleton`, `phase-task-skeleton`,
  `phase-part-skeleton`).
- D1 (architect §1.4 row 1) reframed in addendum §2.1 — "Project-
  template 3→4 options stays AT but not OVER the BD-068 4-option
  soft cap; no defense required at either surface." The 4-option
  result matches.

**Defect F1 (REMEDIATION-NEEDED-SHOULD):** Documentation in two
files misstates the BD-068 soft cap as "5" when the cap is 4:

- `scripts/validate-pack.py:1123` — comment: `# "Part" construct
  introduced at v11.1. Under BD-068 soft cap of 5`
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md:79`
  — prose: `phase-part-skeleton (new at v11.1; under BD-068 soft
  cap of 5).`

The soft cap is **4** per ARCHITECTURE-BD-185.md §4.3 line 218
("INV-7 + INV-8 cap the `wi-type` dropdown at 4 options as a soft
cap (V2 §17 R11)") and addendum §2.1 D1 ("AT but not OVER the
BD-068 4-option soft cap"). If the cap were 5, the addendum's
phrasing would lose meaning (project-template at 4 wouldn't be
"AT" the cap).

The phrasing likely conflated the cap (4) with the would-have-
been-over-cap count (5) at pack-root in the original pre-
reconciliation H.2 plan. Should be corrected to "under BD-068
soft cap of 4" or "at the BD-068 4-option soft cap (project-
template 3→4)."

### D3 — wi-part-letter field correctness

**Verdict: CONFIRMED-CORRECT.**

Evidence:

- Field exists at `project-template/.github/ISSUE_TEMPLATE/work-
  item.yml:102-108`.
- Position correct (after `wi-task-title` at L96; before `wi-
  blockers` at L110) per addendum sub-edit 1b.
- Conditional semantics expressed via:
  - Label suffix: `Part letter (phase-part-skeleton only)` (L105)
  - Description: `Required for Type=phase-part-skeleton. The next
    available letter under phase N (a, b, c, ...).` (L106) —
    matches addendum verbatim.
  - `validations: required: false` (L108) — matches established
    conditional-field pattern (wi-task-title, wi-phase-number all
    use `required: false` + label suffix).

GitHub Issue Forms have no native conditional rendering, so the
label + description + validation pattern is the conventional
encoding. Pattern is consistent with sibling fields.

### D4 — Blockers/Unblocks/Dependencies admit Part-id forms; NO BD-NNN

**Verdict: CONFIRMED-CORRECT (no BD-NNN regression); SHOULD test
coverage gap (see Finding F2 below).**

Evidence (no BD-NNN regression):

- `grep -nE "BD-NNN|BD-[0-9]+" project-template/.github/ISSUE_
  TEMPLATE/work-item.yml` returns ONE match: L18 (`Pack-development
  items (BD-NNN) belong in the pack repo, not in this project.`).
  This is the BD-193 §6.1 boundary-defense markdown line — pre-
  existing, informational audience guidance, NOT an operationally-
  admitted identifier form in any input/textarea description.
- `wi-blockers` description (L114): admits `TD-NNN, #N, phase-N,
  phase-N.M, Phase-N.Part-x, Phase-N.Part-x.Task-M` (NO BD-NNN).
- `wi-unblocks` description (L122): same set (NO BD-NNN).
- `wi-dependencies` description (L179): `phase-N, phase-N.M,
  Phase-N.Part-x, Phase-N.Part-x.Task-M, TD-NNN` (NO BD-NNN).

All three descriptions correctly admit the Part-id forms per
addendum sub-edits 1c + 1d. BD-193 F2.d non-regression preserved.

**Defect F2 (REMEDIATION-NEEDED-SHOULD — test-coverage gap):**

`scripts/tests/test-issue-forms.sh` asserts the Part-id forms
exist in the `wi-blockers` description (L184-185) but does NOT
assert the same forms in the `wi-unblocks` and `wi-dependencies`
descriptions. The addendum §4.2 specifies all three descriptions
were edited; per the review skill's item 9 ("every behavior change
should have a corresponding test change") and the ENCODING-
surface lock-step rule, the test should cover all three.

Without test coverage, a future regression that removes Part-id
from `wi-unblocks` or `wi-dependencies` descriptions would not
fail the test.

Recommended fix (test additions only — no spec edit needed):

```bash
# After the existing wi-blockers Phase-N.Part-x asserts (L184-185):
unblocks_desc=$(yq_get "$path" "[b['attributes']['description'] for b in data['body'] if b.get('id')=='wi-unblocks'][0]")
if [[ "$surface_kind" == "project" ]]; then
    assert_contains "$label wi-unblocks description names Phase-N.Part-x"        "$unblocks_desc" "Phase-N.Part-x"
    assert_contains "$label wi-unblocks description names Phase-N.Part-x.Task-M" "$unblocks_desc" "Phase-N.Part-x.Task-M"
fi
deps_desc=$(yq_get "$path" "[b['attributes']['description'] for b in data['body'] if b.get('id')=='wi-dependencies'][0]")
if [[ "$surface_kind" == "project" ]]; then
    assert_contains "$label wi-dependencies description names Phase-N.Part-x"        "$deps_desc" "Phase-N.Part-x"
    assert_contains "$label wi-dependencies description names Phase-N.Part-x.Task-M" "$deps_desc" "Phase-N.Part-x.Task-M"
fi
```

### D5 — DISJOINT invariant holds

**Verdict: CONFIRMED-CORRECT.**

Evidence:

- Pack-root wi-type set = `{bd}` (`.github/ISSUE_TEMPLATE/work-
  item.yml:22`).
- Project-template wi-type set = `{td, phase-epic-skeleton,
  phase-task-skeleton, phase-part-skeleton}` (`project-template/
  .github/ISSUE_TEMPLATE/work-item.yml:25-28`).
- Intersection: ∅ (empty).
- `scripts/validate-pack.py:1125-1128` per-surface dict reflects
  this:
  ```python
  expected_wi_type_options_per_surface = {
      "pack-root": {"bd"},
      "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"},
  }
  ```
- `scripts/tests/test-issue-forms.sh` Group 5 assertion 5.1 PASS
  (verified by running the test → "5.1 wi-type options pack-side
  and project-side surfaces are DISJOINT (deliverable-only
  rule)" PASS).
- `scripts/tests/test-issue-forms.sh:264-272` documents the
  DISJOINT semantics with the addendum's deliverable-only rule
  framing.

### D6 — Archive snapshot byte-identical to project-template

**Verdict: CONFIRMED-CORRECT.**

Evidence:

- `maintenance-docs/v11-research/templates-archive/v11.1/forms/
  work-item.yml` exists (created in this commit; new file mode
  `100644` per `git diff`).
- `diff maintenance-docs/v11-research/templates-archive/v11.1/
  forms/work-item.yml project-template/.github/ISSUE_TEMPLATE/
  work-item.yml` → empty output (byte-identical).
- `diff maintenance-docs/v11-research/templates-archive/v11.1/
  forms/work-item.yml .github/ISSUE_TEMPLATE/work-item.yml`
  → non-empty (8+ property divergence including `name`,
  `description`, `title`, wi-type options, etc.; intentional per
  POQ-NEW-1 Option c).
- INDEX "Forms file" section updated (L53-93) from "Not yet
  created" placeholder to post-H.2 descriptive prose. Includes:
  - POQ-NEW-1 Option c cite (snapshot project-template only)
  - v11.0 archive precedent cite
  - Pack/project separation-of-concerns principle cite
  - 4 wi-type options enumeration
  - `wi-part-letter` field mention
  - Blockers/Unblocks/Dependencies description extensions

### D7 — ENCODING-surface lock-step completeness

**Verdict: CONFIRMED-CORRECT.**

ENCODING surfaces enumerated per the review skill's "Surface-rule
audits — enumerate ENCODING surfaces" methodology, traced against
the addendum §6.1 lock-step coordination map:

| # | Surface | Role | H.2 status |
|---|---|---|---|
| 1 | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | AUDITED (form file) | EDITED ✓ |
| 2 | `scripts/validate-pack.py` `expected_wi_type_options_per_surface` | ENCODING (validator dict) | EDITED L1125-1128 ✓ |
| 3 | `scripts/tests/test-issue-forms.sh` Group 2 + Group 5 | ENCODING (test assertions) | EDITED ✓ (modulo F2 coverage gap noted in D4) |
| 4 | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | CROSS-REFERENCE (archive snapshot) | NEW ✓ |
| 5 | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | CROSS-REFERENCE (archive INDEX) | EDITED L53-93 ✓ |
| 6 | `.github/workflows/validate-pack.yml` | ENCODING (CI workflow) | NOT EDITED ✓ (per addendum: no workflow change in H.2 — H.10 adds 4 new check invocations) |

No asymmetric coverage on the lock-step-required surfaces. The
single ENCODING gap (F2: test coverage for wi-unblocks /
wi-dependencies descriptions) is the only ENCODING-surface defect
identified.

### D8 — Check 22/23/41 informational note

**Verdict: CONFIRMED-CORRECT (no regression).**

These checks enforce surface-local invariants for HELP-FRAGMENT-
TRACKER and `_CLIENT_INSTALLED_FILES`, NOT work-item.yml. H.2
should not affect them. Verified at HEAD `e580dda`:

- Check 22 (Help-fragment freshness): `OK: pack-root: 9 prose-
  referenced verb(s) all present in fragment` ✓
- Check 23 (Help-fragment completeness): `OK: all 9 non-internal
  scripts/ executables listed in HELP-FRAGMENT-PACK.md (13 marked
  pack-internal)` ✓
- Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity):
  `OK: Check 41 — 37 entry(ies) checked; 37 resolve to existing
  files at HEAD, 0 on exemption allowlist` ✓

No H.2 regression on these checks.

### D9 — Manifest regen correctness

**Verdict: CONFIRMED-CORRECT.**

Evidence:

- `git diff c770b96..e580dda -- test-fixtures/manifest.txt` shows
  3 v11-* fixture SHAs drifted; v10-* and existing-* rows
  unchanged:
  ```
  -v11-realistic-ot  570b7f8628abaa0ebe8d5580797f790f1165eea7
  -v11-flat-file  4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
  -v11-tracker-on  8f584b117f39d5826c7360f0e45a56cc6bfc1fce
  +v11-realistic-ot  b99ecc7ed7816eaeea6bbeff8900032c68b3b762
  +v11-flat-file  cb89f83e0daa2b0d3b0b6ebd7fef9a63a0419c48
  +v11-tracker-on  0aadfe791c94c7a542dce017932051c033540dc4
  ```
- `bash test-fixtures/build.sh --verify` → all 6 fixtures OK at
  HEAD `e580dda`.
- v10-* tag-pinned rows unchanged; existing-project-mid-dev
  unchanged. Only v11-surface fixtures drifted, which is correct
  since `project-template/` (v11-surface) was edited.
- Manifest staged in same commit as the 5 scope edits per BD-176
  v11-surface trigger.

### D10 — IMPL-REPORT accuracy

**Verdict: CONFIRMED-CORRECT modulo two minor data points (see
Finding F3 below).**

The IMPL-REPORT (`maintenance-docs/v11-implementation/
IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md`) is comprehensive
and accurate for the substantive edits. BEFORE/AFTER blocks
match the actual diff. Success-criteria checklist (§10) PASS
results match independent verification.

**Defect F3 (REMEDIATION-NEEDED-NIT — IMPL-REPORT count
discrepancy):**

IMPL-REPORT §5.B claims:
> "Check enumeration count UNCHANGED at 41 raw `── Check ` lines
> (= 40 unique invoked checks per H.2 success criterion #8)"

Independent verification: `python3 scripts/validate-pack.py 2>&1
| grep -c "^── Check"` returns **43**, not 41. Per addendum §3.3:
> "43 invocations" = 38 numbered + 2 unnumbered + 3 dual-invocation
> = 40 unique invoked checks.

The "40 unique invoked checks" part is consistent (38 + 2 = 40).
The "41 raw lines" claim is off by 2 from the actual 43 raw lines.

This is cosmetic — does not affect correctness of H.2's edits;
the IMPL-REPORT's claim that the count is "unchanged" is true in
spirit (no H.2-introduced new checks) but states the wrong
absolute number. Future addenda or audit trails reading this
IMPL-REPORT may be misled by the 41-vs-43 inconsistency.

Suggested fix: update IMPL-REPORT §5.B to "Check enumeration
count UNCHANGED at 43 raw `── Check ` lines = 40 unique invoked
checks (per addendum §3.3 baseline; H.10 will bump to 47
invocations / 44 unique)."

## §4 Findings summary

| Finding | Severity | Priority | Location |
|---|---|---|---|
| **F1** — Soft-cap-of-5 misstatement (should be 4) | SHOULD | MEDIUM | `scripts/validate-pack.py:1123` + `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md:79` |
| **F2** — Missing test coverage for `wi-unblocks` + `wi-dependencies` description Part-id assertions | SHOULD | MEDIUM | `scripts/tests/test-issue-forms.sh` (add 4 assertions in project-side branch) |
| **F3** — IMPL-REPORT count claim (41 vs actual 43) | NIT | LOW | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md:308` |
| **A1** — `wi-phase-number` label + description don't mention `phase-part-skeleton` (architect §4.3 anticipated; addendum §4.2 silent) | AMBIGUOUS | MEDIUM | `project-template/.github/ISSUE_TEMPLATE/work-item.yml:90-91` |
| **A2** — Form `template_version` body marker not bumped to `work-item-v11.1` (architect §4.3 anticipated bump; addendum §4.2 silent) | AMBIGUOUS | MEDIUM | `project-template/.github/ISSUE_TEMPLATE/work-item.yml:7` (`template:work-item-v11.0` label) + L186 (`<!-- template_version: work-item-v11.0 -->` marker) |

**Per-category counts:**

- CONFIRMED-CORRECT: 8 dimensions overall PASS (D1, D2 substantive,
  D3, D5, D6, D7, D8, D9 PASS; D10 PASS modulo NIT)
- REMEDIATION-NEEDED-MUST: 0
- REMEDIATION-NEEDED-SHOULD: 2 (F1, F2)
- REMEDIATION-NEEDED-NIT: 1 (F3)
- AMBIGUOUS: 2 (A1, A2)

**Carry-forward discipline assessment:** No findings qualify as
carry-forward under the high-bar SIZE / BLOCKED / LOGICAL FIT
tests. All findings are fix-now or surface-now-as-AMBIGUOUS.

- F1 (soft-cap-of-5): Trivial wording fix (~5 minutes); no SIZE,
  no BLOCKED, no LOGICAL FIT to a sibling BD. Fix now.
- F2 (test coverage): 4 lines of test code to add; no SIZE, no
  BLOCKED, no LOGICAL FIT. Fix now.
- F3 (IMPL-REPORT NIT): 1-line edit to a closed IMPL-REPORT; the
  IMPL-REPORT is an artifact of H.2 and editing it after-the-fact
  may violate report-immutability conventions. Pack Chat should
  triage whether to amend the report or note the discrepancy in
  a follow-up.
- A1 and A2 are AMBIGUOUS because the addendum (user-locked spec)
  is SILENT on edits the architect anticipated. Per review skill
  guidance, surface to user; do not auto-classify.

## §5 AMBIGUOUS surface

### A1 — `wi-phase-number` description does not mention `phase-part-skeleton`

**Context.** `ARCHITECTURE-BD-185.md` §4.3 form-field additions
table (L233-239) states:

> | `wi-phase-number` | input (existing) | now also applies to
> `phase-part-skeleton` | "Phase the Part belongs to. Use 'N'." |

And `PLAN-BD-185.md` §5 H.2 sub-edit 2 (L257) states:

> 2. **`wi-phase-number` input** (existing): extend description
> to admit `phase-part-skeleton` audience: "Phase the Part
> belongs to. Use 'N'."

This was DROPPED in `PLAN-BD-185-ADDENDUM.md` §4.2 — the sub-edit
list there enumerates (1a) wi-type description + options;
(1b) wi-part-letter insertion; (1c) wi-blockers + wi-unblocks
description extensions; (1d) wi-dependencies description
extension. No `wi-phase-number` edit.

The H.2 coder followed the addendum (correct behavior — addendum
supersedes original plan). The live form's `wi-phase-number`
label/description (L90-91) still reads:

> label: Phase number (phase-epic-skeleton or phase-task-skeleton)
> description: Required for Type=phase-epic-skeleton (use "N") or
> Type=phase-task-skeleton (use "N" — the parent phase). Drives
> the `phase-N` label and the body `pack-id`.

Functionally, a Part needs `wi-phase-number` (Part identifier =
`Phase-N.Part-x`; the chat composes the title from `wi-phase-
number` + `wi-part-letter`). But the form's documentation tells
the user this field is only for phase-epic / phase-task — not
Part. A user filing a `phase-part-skeleton` issue via the form
may skip `wi-phase-number` based on the label.

**The ambiguity:** Is this a user-locked exclusion (addendum
intentionally narrows scope), or an oversight in the addendum
spec? The addendum's D1 reframe and Sub-edits list make no
explicit statement.

**Two interpretations:**

(a) **User-locked exclusion** (no fix required): The addendum is
authoritative; the architect's §4.3 was reconciled. If the user
intends `wi-phase-number` description to remain phase-task-only-
focused, the form may need a separate `wi-phase-number-for-part`
input later (or the chat must infer phase from the issue parent).
No fix in H.2.

(b) **Addendum spec oversight** (fix required): The architect
anticipated this edit because Parts genuinely need to know N (per
Phase-N.Part-x grammar). The addendum's sub-edits list is
incomplete. Recommend a small additional edit:

```yaml
# project-template/.github/ISSUE_TEMPLATE/work-item.yml:88-94
  - type: input
    id: wi-phase-number
    attributes:
      label: Phase number (phase-epic-skeleton, phase-task-skeleton, or phase-part-skeleton)
      description: Required for Type=phase-epic-skeleton (use "N"); Type=phase-task-skeleton (use "N" — the parent phase, drives `phase-N` label and body `pack-id`); or Type=phase-part-skeleton (use "N" — the parent phase the Part belongs to).
      placeholder: "3"
```

**Recommendation:** Surface to user for explicit ruling. Pack
Chat triage decides between (a) close A1 as "user-locked
exclusion accepted" or (b) issue a fix-coder spawn to apply the
small edit + companion test assertion.

### A2 — Form `template_version` body marker not bumped to v11.1

**Context.** `ARCHITECTURE-BD-185.md` §4.3 template_version delta
table (L256) states:

> | `work-item-v11.0` (form) | work-item-v11.0 | **work-item-v11.1**
> (BUMP) | `wi-type` adds option; `wi-part-letter` field added;
> description fields admit Part-id forms |

And §4.3 L258 states:

> Total template_version delta: ONE new template (phase-part-v11.1)
> + ONE bumped template (work-item-v11.0 → work-item-v11.1). Four
> existing templates unchanged.

`PLAN-BD-185.md` §5 H.2 success criterion #4 (L305) says:

> 4. Pack-root, project-template/, and v11.1 archive copies of
> work-item.yml are byte-identical.

Original plan was silent on the version bump itself, presumably
inheriting the bump from the architect doc.

`PLAN-BD-185-ADDENDUM.md` §4.2 success criteria (L682-705) makes
NO mention of template_version bump. Sub-edits list (1a-1d) makes
NO mention of changing the `template:work-item-v11.0` label or
the L186 `<!-- template_version: work-item-v11.0 -->` body marker
comment.

The H.2 coder followed the addendum: live form retains
`template:work-item-v11.0` label (L7) and `<!-- template_version:
work-item-v11.0 -->` body marker (L186).

**The ambiguity:** Same shape as A1 — was the v11.1 bump
intentionally dropped, or omitted by oversight?

**Two interpretations:**

(a) **User-locked v11.0 retention** (no fix required): The
addendum's silence is intentional; the form's body marker stays
at `work-item-v11.0` because the changes are backward-compatible
additive extensions (new dropdown option, new optional input
field, expanded description text — all of which existing v11.0-
filed issues can continue to satisfy). Treating this as
backward-compatible is consistent with Convention Y (D16 Class A:
intra-file additive extensions don't bump version).

(b) **Spec oversight; bump required** (fix required): The
architect explicitly said BUMP. The form's `wi-part-letter` field
addition is not a body marker but a form schema change, which
arguably warrants a form-version bump. Bumping would require
updating: `template:work-item-v11.0` → `template:work-item-v11.1`
in form labels (L7); body marker `template_version: work-item-
v11.0` → `work-item-v11.1` (L186); the `template:work-item-v11.0`
label provisioning in tracker-init; the archive INDEX's
"template-version delta table" prose; and validate-pack.py /
test-issue-forms.sh assertions if they hardcode the version.

**Note on Convention Y consistency.** Per addendum §2.1 D16
"Class A (additive extension): intra-file content extends
backward-compatibly; net new content added." This may justify
interpretation (a) — the form's schema changes are net new
additions, no removals.

**Recommendation:** Surface to user. The architect's §4.3 BUMP
statement is in tension with the addendum's silence. Pack Chat
triage decides which interpretation governs. If (a) is the
user-locked default, both architect doc §4.3 and INDEX delta
table prose should be updated to reflect the no-bump decision
(separately tracked, not H.2 scope).

## §6 Recommended remediation

### Fix-now batch (4 surface edits)

**F1 fix (validate-pack.py + INDEX.md):**

Edit `scripts/validate-pack.py:1123`:
```python
# BEFORE
# "Part" construct introduced at v11.1. Under BD-068 soft cap of 5
# wi-type options per surface; no defense required.

# AFTER
# "Part" construct introduced at v11.1. At the BD-068 4-option soft
# cap (project-template 3 → 4); no defense required (cap not
# exceeded). Per addendum D1 reframe.
```

Edit `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md:79`:
```markdown
# BEFORE
  `phase-part-skeleton` (new at v11.1; under BD-068 soft cap of 5).

# AFTER
  `phase-part-skeleton` (new at v11.1; at the BD-068 4-option soft
  cap; no defense required — cap not exceeded).
```

**F2 fix (test-issue-forms.sh):**

Add 4 new `assert_contains` calls in the project-side branch of
`check_workitem()` (post-L185), one pair each for `wi-unblocks`
and `wi-dependencies` descriptions (see D4 finding for the exact
code).

**F3 fix (IMPL-REPORT):**

Pack Chat decision: amend the closed IMPL-REPORT vs leave as-is
with a follow-up cite. If amended:

Edit `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-
BD-185-Batch-19d-H.2.md:308`:
```markdown
# BEFORE
Final output line: `PASSED — all checks clean`. Check enumeration
count UNCHANGED at 41 raw `── Check ` lines (= 40 unique invoked
checks per H.2 success criterion #8 — H.10 will add the 4 new
checks).

# AFTER
Final output line: `PASSED — all checks clean`. Check enumeration
count UNCHANGED at 43 raw `── Check ` lines (= 40 unique invoked
checks per H.2 success criterion #8 and addendum §3.3 baseline;
H.10 will add the 4 new checks taking the count to 47 invocations /
44 unique).
```

### AMBIGUOUS surface for user discussion

A1 + A2 → Pack Chat surfaces to user with both interpretations
and recommendation.

## §7 Acknowledgments

What H.2 got right (substantial):

1. **Boundary discipline.** Pack-root form deliberately untouched,
   preserving b4906d1's deliverable-only cleanup. The reviewer's
   D1 verification confirmed byte-identical pre-vs-post for the
   pack-root surface.

2. **ENCODING-surface lock-step.** All 5 in-scope surfaces (form,
   validator dict, test, archive snapshot, archive INDEX) updated
   in the same commit per the addendum §6.1 lock-step map. No
   asymmetric coverage modulo the F2 test-coverage gap (which is
   itself a within-the-test-surface gap, not a between-surfaces
   gap).

3. **BD-193 F2.d non-regression.** Four independent verification
   angles (live grep, YAML parse, test negative assertion,
   description scan) all confirm `bd` is not re-introduced to
   the project-template form and `BD-NNN` is not admitted in any
   blockers/unblocks/dependencies description.

4. **DISJOINT invariant.** Pack-root `{bd}` ∩ project-template
   `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-
   skeleton}` = ∅, verified by both the validator dict and the
   test's Group 5 assertion 5.1 PASS.

5. **POQ-NEW-1 Option c.** Archive snapshot is byte-identical to
   project-template form, matching the v11.0 archive precedent.
   The archive INDEX "Forms file" section comprehensively
   describes the snapshot decision with cross-references to
   POQ-NEW-1, BD-193, and the pack/project separation principle.

6. **wi-part-letter field placement and content.** Field
   correctly positioned after `wi-task-title` (the established
   conditional pattern). Description text matches addendum
   verbatim. Conditional semantics expressed via label suffix +
   description text + `required: false` (the only conditional
   encoding GitHub Issue Forms support).

7. **Manifest regen + RC9 trinity rule.** All 3 v11-* fixture
   SHAs drifted (correct for `project-template/` edit); v10-* and
   existing-* rows unchanged. Manifest staged in same commit.
   `build.sh --verify` PASS at HEAD.

8. **PREFLIGHT discipline.** PREFLIGHT line emitted per the
   trinity-cached pack-coder PREFLIGHT pattern. IMPL-REPORT
   §10 success-criteria checklist filled per the addendum
   spec; all 16 items PASS at HEAD verification.

9. **No state-changing git verbs.** Confirmed via `git log
   --oneline -10` — the commit `e580dda` was made by Pack Chat
   per user approval, not by the coder agent.

10. **Documentation reconciliation chain.** The IMPL-REPORT
    references all four planning docs (PLAN-BD-185, PLAN-BD-185-
    ADDENDUM, ARCHITECTURE-BD-185, ARCHITECTURE-BD-185-
    RECONCILIATION) plus the pack memory rules that govern the
    change. Boundary-discipline check (§9.D) is documented per
    the review skill's boundary-investigation methodology.

## §8 Cross-references

| Doc | Section | Role in this review |
|---|---|---|
| `maintenance-docs/v11-implementation/PLAN-BD-185.md` | §5 H.2 | Original (SUPERSEDED by addendum) |
| `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` | §4.2 | Authoritative H.2 spec (user-locked REPLACEMENT) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | §4.3 | Architect form-family design (informs A1, A2) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md` | §4.2 | WRONG-AND-NEEDS-REPLACEMENT verdict + POQ-NEW-1 |
| `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` | §2.1 D1 | Soft-cap = 4 framing (informs F1) |
| `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` | §3.3 | 43 raw / 40 unique check count baseline (informs F3) |
| `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` | §6.1 | H.2 ENCODING-surface lock-step map |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md` | §1-§14 | Coder's IMPL-REPORT (informs D10 and F3) |
| `.claude/skills/review/SKILL.md` | "Surface-rule audits — enumerate ENCODING surfaces" | Methodology applied for D7 |
| `.claude/skills/review/SKILL.md` | "Carry-forward discipline" | Applied to all findings |
| Trinity Pack memory § Pack memory | `feedback_pack_project_separation_of_concerns` | Cited in D1 boundary check |
| Trinity Pack memory § Pack memory | `feedback_enumerate_encoding_surfaces_in_audits` | Cited in D7 methodology |
| Trinity Pack memory § Pack memory | `feedback_pack_side_project_concepts_deliverable_only` | Cited in D5 invariant |
| Trinity Pack memory § Pack memory | `feedback_bd_pack_only_operational_rule` | Cited in D4 non-regression check |
| Live source | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` at HEAD `e580dda` | Form file under review |
| Live source | `.github/ISSUE_TEMPLATE/work-item.yml` at HEAD `e580dda` | Pack-root form (D1 unchanged-verification) |
| Live source | `scripts/validate-pack.py:1106-1128` at HEAD `e580dda` | Per-surface dict + F1 misstatement |
| Live source | `scripts/tests/test-issue-forms.sh:155-191` at HEAD `e580dda` | Test assertions + F2 gap |
| Live source | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` at HEAD `e580dda` | Archive snapshot |
| Live source | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md:53-93` at HEAD `e580dda` | Archive INDEX + F1 misstatement |
| Live source | `test-fixtures/manifest.txt` at HEAD `e580dda` | RC9 regen evidence |

---

End of review.

Reviewer note: H.2's substantive correctness is high — 8 of 10
dimensions are CONFIRMED-CORRECT, and the remaining 2 (D2 and D10)
PASS on the substantive question with subordinate documentation
defects (F1, F3) that are correctable in a single fix-coder pass.
The two AMBIGUOUS cases (A1, A2) deserve user attention before
H.3 fires, since both represent gaps between the architect's
design intent and the addendum's spec; resolving them now avoids
back-edit pressure later in the BD-185 multi-step pipeline.
