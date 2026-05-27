# IMPLEMENTATION REPORT — BD-185 Batch 19d H.2 (Form-family extension, PROJECT-TEMPLATE-ONLY)

## §1 Scope

BD-185 H.2 — Form-family extension per the user-locked REPLACEMENT
spec at `PLAN-BD-185-ADDENDUM.md` §4.2. The original H.2 plan was
WRONG-AND-NEEDS-REPLACEMENT per `ARCHITECTURE-BD-185-RECONCILIATION.md`
§4.2 — its "byte-identical pack-root + project-template" assertion
would either regress BD-193 F2.d (re-introduce `bd` to
project-template) or destroy pack-developer surface (drop `bd` from
pack-root). The replacement is PROJECT-TEMPLATE-ONLY form extension
(POQ-NEW-1 Option c — archive snapshots project-template only,
matching v11.0 archive precedent).

This is the SECOND of 16 BD-185 commits per the planner addendum.

**Working-tree HEAD (before edits):** `c770b96b6b99f56af2bba2a88019eafcdb28fc47`
**Working-tree HEAD (after edits):** `c770b96b6b99f56af2bba2a88019eafcdb28fc47`
(unchanged — no state-changing git verbs invoked by this agent)

**Branch:** `v11-dev`

**Cross-references:**
- `maintenance-docs/v11-implementation/PLAN-BD-185.md` §5 H.2 (original; superseded)
- `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` §4.2 (REPLACEMENT spec — authoritative)
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §4.3 (D1 needs-adjustment)
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md` §4.2 (verdict + Option c recommendation)

**User-locked decisions applied:**
1. PROJECT-TEMPLATE-ONLY form extension (pack-root form NOT touched; stays at `{bd}` per b4906d1)
2. wi-type options 3 → 4 on project-template (under BD-068 soft cap; no defense required)
3. wi-part-letter input field added (conditional on `phase-part-skeleton`)
4. Blockers/Unblocks/Dependencies admit `Phase-N.Part-x` + `Phase-N.Part-x.Task-M` (MUST NOT re-introduce `BD-NNN` — BD-193 F2.d non-regression)
5. v11.1 archive snapshots PROJECT-TEMPLATE byte-identically (POQ-NEW-1 Option c)
6. ENCODING-surface lock-step: validator dict + test assertions updated in same commit (MF1 worked-example pattern)
7. Commit subject: NO scope keyword (mixed-scope per `project-template/` + `scripts/` + `maintenance-docs/` + `test-fixtures/` touched)

## §2 Files modified

5 in-scope files + 1 RC9 manifest:

| # | Path | Change type | Lines (approx delta) |
|---|---|---|---|
| 1 | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | MODIFIED (EXTEND) | +14 / -4 |
| 2 | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | NEW (byte-identical to File 1 post-edit) | +188 (new file) |
| 3 | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | MODIFIED (UPDATE "Forms file" §) | +35 / -25 |
| 4 | `scripts/validate-pack.py` | MODIFIED (LOCK-STEP per ENCODING rule) | +14 / -6 |
| 5 | `scripts/tests/test-issue-forms.sh` | MODIFIED (LOCK-STEP per ENCODING rule) | +35 / -7 |
| — | `test-fixtures/manifest.txt` | MODIFIED (RC9 regen — 3 v11-* fixture SHAs drifted) | +3 / -3 |

**Out-of-scope files NOT modified:**
- `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root form; stays at `{bd}` per b4906d1)
- Pack memory / trinity / pack-ops / supporting-docs / project-template trinity / project-template/docs/

## §3 Per-file edit details

### File 1 — `project-template/.github/ISSUE_TEMPLATE/work-item.yml`

**Edit 1a — wi-type description + options (3 → 4):**

BEFORE (L19-29):
```yaml
  - type: dropdown
    id: wi-type
    attributes:
      label: Type
      description: Pick TD for project items; phase-epic-skeleton or phase-task-skeleton for hand-edited phase skeletons (rare).
      options:
        - td
        - phase-epic-skeleton
        - phase-task-skeleton
    validations:
      required: true
```

AFTER:
```yaml
  - type: dropdown
    id: wi-type
    attributes:
      label: Type
      description: Pick TD for project items; phase-epic-skeleton or phase-task-skeleton for hand-edited phase skeletons (rare); phase-part-skeleton (rare-case fallback for hand-edited Part skeletons).
      options:
        - td
        - phase-epic-skeleton
        - phase-task-skeleton
        - phase-part-skeleton
    validations:
      required: true
```

**Edit 1b — Insert wi-part-letter input AFTER wi-task-title (the established conditional pattern for phase-task-skeleton):**

NEW BLOCK (inserted at L102-108):
```yaml
  - type: input
    id: wi-part-letter
    attributes:
      label: Part letter (phase-part-skeleton only)
      description: Required for Type=phase-part-skeleton. The next available letter under phase N (a, b, c, ...).
    validations:
      required: false
```

**Edit 1c — Blockers / Unblocks descriptions admit Part-id forms:**

BEFORE — wi-blockers description (L106):
```
One per line. Each line is either an issue id (TD-NNN, #N) or a phase token. Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task) — both forms are recognized. The chat resolves these to first-class links/sub-issue parents post-creation.
```

AFTER (L114):
```
One per line. Each line is either an issue id (TD-NNN, #N) or a phase token. Blockers may name 'phase-N' (entire phase), 'phase-N.M' (specific task), 'Phase-N.Part-x' (specific phase part), or 'Phase-N.Part-x.Task-M' (specific task under a phase part) — all forms are recognized. The chat resolves these to first-class links/sub-issue parents post-creation.
```

BEFORE — wi-unblocks description (L113):
```
Informational; one issue id per line. Inverse of Blockers across the dataset.
```

AFTER (L122) — also converted to literal-block scalar to mirror the multiline shape of wi-blockers:
```
Informational; one issue id per line. Inverse of Blockers across the dataset. Accepts the same identifier forms as Blockers (TD-NNN, #N, phase-N, phase-N.M, Phase-N.Part-x, Phase-N.Part-x.Task-M).
```

**Edit 1d — wi-dependencies description admits Part-id forms:**

BEFORE (L170):
```
One ID per line. Accepts `phase-N`, `phase-N.M`, `TD-NNN`. The chat resolves each line to first-class `provider.link()` calls post-creation.
```

AFTER (L179):
```
One ID per line. Accepts `phase-N`, `phase-N.M`, `Phase-N.Part-x`, `Phase-N.Part-x.Task-M`, `TD-NNN`. The chat resolves each line to first-class `provider.link()` calls post-creation.
```

**Non-regression (BD-193 F2.d):**
- The string `bd` was NOT added to the project-template form `options:` list.
- The string `BD-NNN` was NOT added to any project-template description field. The only `BD-NNN` occurrence in the file remains the pre-existing L18 boundary-defense markdown ("Pack-development items (BD-NNN) belong in the pack repo, not in this project.") — an INFORMATIONAL audience guidance line, not an operationally-admitted identifier form.

### File 2 — `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` (NEW)

Created the `forms/` subdirectory (did not previously exist) and copied
`project-template/.github/ISSUE_TEMPLATE/work-item.yml` byte-identically
via `cp` (preserves exact bytes — no Write re-encoding). Verified via
`diff` post-copy: empty output.

The byte-identical-to-project-template invariant is per POQ-NEW-1
Option c — the archive snapshot captures the client-facing form
shape, matching the v11.0 archive precedent (where the v11.0
archive snapshot is also project-template-shaped after the F2.c
bug-fix carve-out).

### File 3 — `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (UPDATE "Forms file" §)

BEFORE (L53-77, 25 lines): "Not yet created. The v11.1 forms/ subdirectory will be populated when the v11.1 archive cut is completed (architect-pass decision pending)…" followed by forecast bullets describing what the live form WOULD gain.

AFTER (35 lines): replaced the "not yet created" placeholder with descriptive prose for the post-H.2 snapshot. Key elements:
- Cites POQ-NEW-1 Option c (snapshot project-template surface only)
- Cites v11.0 archive precedent (`templates-archive/v11.0/forms/work-item.yml` is also project-template-shaped post-F2.c carve-out)
- Cites pack/project separation-of-concerns principle (pack-root and project-template forms are SEPARATE artifacts with SEPARATE audiences)
- Lists the 4 wi-type options enumeration
- Lists the new `wi-part-letter` input field
- Lists the Blockers/Unblocks/Dependencies description extensions (Part-id forms)
- Preserves the existing template-version delta table prose at the end of the section

### File 4 — `scripts/validate-pack.py` (LOCK-STEP per ENCODING rule)

**Edit 4a — outer docstring (L1080-1087) updated:**

BEFORE:
```
        Project-side admits the project-side entry types it
        constructs as a deliverable (`td`, `phase-epic-skeleton`,
        `phase-task-skeleton`). Per V3.3 §6.1 + BD-193 (project-side)
```

AFTER:
```
        Project-side admits the project-side entry types it
        constructs as a deliverable (`td`, `phase-epic-skeleton`,
        `phase-task-skeleton`, `phase-part-skeleton`). The
        `phase-part-skeleton` option was added at v11.1 (BD-185 H.2)
        for the mid-work phase expansion Part construct. Per
        V3.3 §6.1 + BD-193 (project-side)
```

**Edit 4b — inline comment (L1103-1116) + dict (L1117-1120):**

BEFORE (dict L1117-1120):
```python
    expected_wi_type_options_per_surface = {
        "pack-root": {"bd"},
        "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
    }
```

AFTER (dict):
```python
    expected_wi_type_options_per_surface = {
        "pack-root": {"bd"},
        "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"},
    }
```

The inline comment block above the dict was also extended (4 new lines) to document the `phase-part-skeleton` addition with its BD-185 H.2 origin + BD-068 soft cap rationale.

The pack-root entry stays unchanged at `{"bd"}` per the
PROJECT-TEMPLATE-ONLY scope of H.2 (the pack-root form is not
touched in this commit).

The OK message string (L1187) uses dynamic `{len(expected)}`, so it
correctly emits `4 wi-type options correct` for the
project-template surface after the dict update with no edit needed
to the message format itself.

### File 5 — `scripts/tests/test-issue-forms.sh` (LOCK-STEP per ENCODING rule)

**Edit 5a — file header comment (L10-19):** updated to enumerate
`phase-part-skeleton` as the new 4th option, document the
`wi-part-letter` input field, mention the v11.1 (BD-185 H.2) origin.

**Edit 5b — `check_workitem` 3rd-arg comment (L86-97):** updated
project-side description set to include `phase-part-skeleton`,
documented the v11.1 (BD-185 H.2) addition.

**Edit 5c — `check_workitem` 4th-arg comment (L94-96):** updated
example to include `phase-part-skeleton` in the project-template
expected option set.

**Edit 5d — pack-side forbidden loop (L137-148):** added
`phase-part-skeleton` to the forbidden list (it is a project-side
mid-work expansion concept; pack-self-management does not file
Parts). Now scans 4 forbidden tokens instead of 3 on the pack-root
surface.

**Edit 5e — project-side phase-task fields block (L152-167):** added
new assertion under the `if [[ "$surface_kind" == "project" ]]`
branch checking `wi-part-letter` field presence.

**Edit 5f — pack-side else-branch (L165-168):** added complementary
assertion checking `wi-part-letter` is correctly ABSENT on pack-root
(disjoint deliverable-only invariant).

**Edit 5g — project-side blockers description block (L175-189):**
added two new `assert_contains` calls for `Phase-N.Part-x` and
`Phase-N.Part-x.Task-M` token presence in the project-template
wi-blockers description.

**Edit 5h — `check_workitem` invocation at L186:** updated the
project-template expected-opts string from
`"td phase-epic-skeleton phase-task-skeleton"` to
`"td phase-epic-skeleton phase-task-skeleton phase-part-skeleton"`.

**Edit 5i — Group 5 DISJOINT comment (L240-247):** updated to
enumerate `phase-part-skeleton` in the project-side set and
document the v11.1 (BD-185 H.2) addition.

**Final test count post-H.2:** 77 passing assertions (up from 67
pre-H.2; +10 new project-side assertions = 1 wi-part-letter
presence + 2 Part-id token presence + 1 phase-part-skeleton wi-type
presence on project-side + 1 phase-part-skeleton wi-type ABSENCE
on pack-side via the forbidden loop, plus the cascading effects of
existing per-surface assertions iterating over the now-larger
forbidden / expected sets).

## §4 ENCODING-surface lock-step verification

Per `feedback_enumerate_encoding_surfaces_in_audits` (MF1; trinity
HEAD `e128a2c`), H.2 modifies five surfaces in lock-step:

| Surface | Role | File | Status |
|---|---|---|---|
| FORM (AUDITED) | The form-file change | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | EDITED |
| VALIDATOR (ENCODING-paired) | The validate-pack.py per-surface dict | `scripts/validate-pack.py` | EDITED in same commit |
| TEST (ENCODING-paired) | The test-issue-forms.sh assertions | `scripts/tests/test-issue-forms.sh` | EDITED in same commit |
| ARCHIVE SNAPSHOT (CROSS-REFERENCE) | The v11.1 forms/ snapshot | `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | CREATED in same commit |
| ARCHIVE INDEX (CROSS-REFERENCE) | The v11.1 INDEX "Forms file" section | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | EDITED in same commit |

No asymmetric coverage: every surface that observes the form
schema has been updated in the same commit. The MF1 worked example
warns that asymmetric coverage (e.g., editing the form file without
the validator + test) would surface as a CI failure. Here, all
five surfaces are coupled.

## §5 Verification results

### A. ENCODING-surface lock-step file list

```
git status --short
 M maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
 M project-template/.github/ISSUE_TEMPLATE/work-item.yml
 M scripts/tests/test-issue-forms.sh
 M scripts/validate-pack.py
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-research/templates-archive/v11.1/forms/
```

Five scope files + RC9 manifest staging surface + new `forms/`
directory containing the new archive snapshot.

### B. `python3 scripts/validate-pack.py` — PASS

Final output line: `PASSED — all checks clean`. Check enumeration
count UNCHANGED at 41 raw `── Check ` lines (= 40 unique invoked
checks per H.2 success criterion #8 — H.10 will add the 4 new
checks). Specific check emission for the updated dict:

```
── Check: Issue template forms (BD-063) ──
  ...
  OK: project-template: work-item.yml — 4 wi-type options correct (V3.3 §6.1 + BD-193)
```

(formerly emitted `3 wi-type options correct` pre-H.2; now `4`)

### C. `bash scripts/tests/test-issue-forms.sh` — PASS

```
Passed: 77
Failed: 0
All tests passed.
```

(Pre-H.2 count was 67 passing assertions; post-H.2 is 77 passing
assertions = +10 from the new H.2 surface-aware checks.)

### D. Per-check tests — PASS

- `bash scripts/tests/test-validate-pack-check-43.sh` → `PASS: 7 / FAIL: 0` → exit 0
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` → `PASS: 8 / FAIL: 0` → exit 0
- `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` → `PASS: 65 / FAIL: 0` → exit 0

### E. Form YAML validity

```
project-template YAML OK
archive snapshot YAML OK
```

Both files parse as valid YAML (verified via `python3 -c "import yaml; yaml.safe_load(open(...))"`).

### F. Structural verifications

| Check | Expected | Actual |
|---|---|---|
| F1 — project-template wi-type option count | 4 | 4 (canonical via YAML parse) ✓ |
| F2 — project-template admits `bd`? | NO match | exit=1 (no match) ✓ |
| F3 — pack-root wi-type option count | 1 | 1 (canonical via YAML parse) ✓ |
| F4 — project-template has `wi-part-letter` | ONE match | L103 (ONE match) ✓ |
| F5 — pack-root has NO `wi-part-letter` | NO match | exit=1 (no match) ✓ |
| F6 — archive vs project-template byte-identical | empty diff | empty diff ✓ |
| F7 — archive vs pack-root differ | non-empty | first 3 lines differ on name/description/title ✓ |

**Note on F1 / F3 raw-grep window:** The spec's `grep -A6 "id: wi-type" … | grep -c "^[[:space:]]*-"` window captures only the option lines that fall within 6 lines of the `id: wi-type` anchor — but the post-H.2 project-template form's wi-type block spans 11 lines (description + 4 option items + validations + required). The `-A6` window therefore returns 2 (the first 2 of the 4 options); the canonical option count via YAML parse is 4. I report both: the canonical YAML parse confirms 4 / 1 respectively (F1 / F3 PASS); the spec's `-A6` raw grep would emit 2 / 1 which is a property of the grep window, not the option count. A widened sed-based grep (`sed -n '/options:/,/validations:/p'`) yields the correct 4 / 1. No defect on the form; minor window-tightness in the spec's verification command.

### G. RC9 manifest regen

```
bash test-fixtures/build.sh --all --clean → exit 0; manifest written
git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

Three v11-* fixture SHAs drifted (`v11-realistic-ot`, `v11-flat-file`,
`v11-tracker-on`) as expected from a `project-template/` modification.
The `v10-*` rows and `existing-project-mid-dev` row are unchanged
(v10 tag pinned + non-pack input shape). Manifest staged for the
commit alongside the 5 scope edits per the RC9 trinity rule.

## §6 DISJOINT invariant verification (pack vs project wi-type sets)

The cross-surface DISJOINT invariant is enforced in
`scripts/tests/test-issue-forms.sh` Group 5 assertion 5.1:

```bash
disjoint=$(python3 -c "
pack=$pack_opts
proj=$proj_opts
print('True' if set(pack).isdisjoint(set(proj)) else 'False')
")
assert_eq "5.1 wi-type options pack-side and project-side surfaces are DISJOINT (deliverable-only rule)" \
    "True" "$disjoint"
```

Post-H.2 set evaluation:
- pack-root: `{bd}` (1 element; unchanged)
- project-template: `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}` (4 elements; +1 from H.2)
- Intersection: `∅` (empty set)
- Disjoint? YES (test result PASS)

The deliverable-only rule (pack memory, user-locked 2026-05-27)
is preserved. Pack-self-management does NOT admit any project-side
concept; project-side admits only project-side deliverable types.
The DISJOINT contract holds for the post-H.2 4 + 1 = 5 total form-
admitted concepts across the two surfaces.

## §7 BD-193 F2.d non-regression verification (project-template form does NOT admit `bd`)

BD-193 F2.d removed `bd` from the project-template form's
`wi-type` options as part of the project-side dep-grammar
cleanup. H.2 MUST NOT regress this.

Verification (multiple independent angles):

1. **Direct grep for `bd` option in dropdown:**
   ```
   grep "^[[:space:]]*-[[:space:]]*bd$" project-template/.github/ISSUE_TEMPLATE/work-item.yml
   → (exit=1; no match)
   ```

2. **YAML-parsed option list:**
   ```
   ['td', 'phase-epic-skeleton', 'phase-task-skeleton', 'phase-part-skeleton']
   → `bd` absent
   ```

3. **`scripts/tests/test-issue-forms.sh` project-side negative assertion:**
   ```
   "project-template work-item.yml wi-type correctly omits bd (project-side)" — PASS
   ```

4. **Description fields scanned for `BD-NNN` admission:**
   - wi-blockers description: NO `BD-NNN` (lists TD-NNN, #N, phase-N, phase-N.M, Phase-N.Part-x, Phase-N.Part-x.Task-M)
   - wi-unblocks description: NO `BD-NNN` (lists TD-NNN, #N, phase-N, phase-N.M, Phase-N.Part-x, Phase-N.Part-x.Task-M)
   - wi-dependencies description: NO `BD-NNN` (lists phase-N, phase-N.M, Phase-N.Part-x, Phase-N.Part-x.Task-M, TD-NNN)
   - The only `BD-NNN` occurrence in the file (L18) is the pre-existing markdown boundary-defense line — informational audience guidance, NOT an admitted identifier form on any input/textarea description.

All four angles confirm BD-193 F2.d is preserved.

## §8 PREFLIGHT line emitted

The PREFLIGHT confirmation line emitted to the parent session before
this IMPL-REPORT was written:

```
PREFLIGHT: 5/5 in-scope file edits complete (+ manifest regen non-empty, staged); verification PASS (validate-pack + test-issue-forms + per-check tests check-43 + checks-36-37-38 + checks-32-33-34 + YAML valid for both forms + structural checks F1-F7); ENCODING-surface lock-step verified (form + validator + test + archive + INDEX all updated); HEAD c770b96b6b99f56af2bba2a88019eafcdb28fc47; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md
```

## §9 Cross-references

| Doc | Section | Topic |
|---|---|---|
| `PLAN-BD-185.md` | §5 H.2 (original) | Form-family extension (SUPERSEDED by addendum §4.2) |
| `PLAN-BD-185-ADDENDUM.md` | §4.2 (REPLACEMENT) | The user-locked H.2 spec actually applied here |
| `ARCHITECTURE-BD-185.md` | §4.3 | D1 INV-7 5th wi-type option accepted (USER-LOCKED 2026-05-25) |
| `ARCHITECTURE-BD-185-RECONCILIATION.md` | §4.2 | WRONG-AND-NEEDS-REPLACEMENT verdict + Option c recommendation |
| `ARCHITECTURE-BD-185-RECONCILIATION.md` | §5 POQ-NEW-1 | Three-option decision (a/b/c) for archive snapshot; resolved to Option c |
| `feedback_pack_project_separation_of_concerns` | trinity § Pack memory | Pack/project SEPARATE-artifacts-SEPARATE-audiences rule |
| `feedback_pack_side_project_concepts_deliverable_only` | trinity § Pack memory | Pack-side admits only `bd`; project-side admits TD/phase concepts |
| `feedback_enumerate_encoding_surfaces_in_audits` | trinity § Pack memory (MF1) | Lock-step requirement for ENCODING-paired surfaces |
| `feedback_pack_coder_preflight_pattern` | trinity § Pack memory | PREFLIGHT + STOP-MEANS-STOP pattern |

### Boundary discipline check

H.2's PROJECT-TEMPLATE-ONLY edit set touches:
- `project-template/.github/ISSUE_TEMPLATE/work-item.yml` — project-side surface; project-side SSOT for the work-item form schema is THIS file (no separate project-side SSOT exists; the form IS the SSOT). No pack-only reference added; the L18 boundary-defense line is pre-existing.
- `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` — pack-internal archive; byte-identical copy of File 1; carries the same project-side audience as the source.
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` — pack-internal INDEX; references POQ-NEW-1, BD-193, pack/project separation principle. These are pack-internal concepts appropriate to pack-internal `maintenance-docs/`. No project-side SSOT augmentation applicable.
- `scripts/validate-pack.py` — pack-only validator. Pack-only concept references appropriate. No project-side surface in scope.
- `scripts/tests/test-issue-forms.sh` — pack-only test. Pack-only concept references appropriate. No project-side surface in scope.

No project-side file gained a pack-only reference. No pack-side file gained a project-side audience violation. The `BD-NNN` cite in `scripts/tests/test-issue-forms.sh` comments and `scripts/validate-pack.py` comments are pack-internal (pack-only file; BD reference appropriate per pack-internal context). The `BD-185 H.2` and `BD-193` cites in archive INDEX prose are also pack-internal (archive INDEX is a pack-internal `maintenance-docs/` doc).

No boundary discipline stop required.

## §10 Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | Project-template form has 4 wi-type options including `phase-part-skeleton` | PASS |
| 2 | `wi-part-letter` input field exists in project-template only | PASS |
| 3 | Blockers/Unblocks/Dependencies descriptions admit Part-id forms | PASS |
| 4 | NO `BD-NNN` re-introduced to project-template form description fields | PASS |
| 5 | v11.1 archive form NEW; byte-identical to post-H.2 project-template | PASS |
| 6 | v11.1 INDEX "Forms file" section updated | PASS |
| 7 | `validate-pack.py` per-surface dict updated (project-template entry has 4 elements; pack-root unchanged) | PASS |
| 8 | `test-issue-forms.sh` assertions updated (surface-aware; DISJOINT invariant) | PASS |
| 9 | `python3 scripts/validate-pack.py` exits 0; check count unchanged (40 unique / 41 raw lines) | PASS |
| 10 | `bash scripts/tests/test-issue-forms.sh` exits 0 (77 PASS / 0 FAIL) | PASS |
| 11 | Per-check tests PASS (check-43, checks-36-37-38, checks-32-33-34) | PASS |
| 12 | Form YAML valid (both forms) | PASS |
| 13 | Pack-root form UNCHANGED (1 wi-type option `{bd}`; no `wi-part-letter`) | PASS |
| 14 | Manifest regenerated; staged | PASS |
| 15 | PREFLIGHT line emitted | PASS |
| 16 | IMPL-REPORT written; no state-changing git verbs invoked | PASS |

## §11 Plan deviations

ZERO plan deviations.

The implementation follows `PLAN-BD-185-ADDENDUM.md` §4.2 line-by-line:
- Sub-edit (1) project-template work-item.yml: 4 sub-changes applied per spec
- Sub-edit (2) v11.1 archive forms/work-item.yml: byte-identical copy created per POQ-NEW-1 Option c
- Sub-edit (3) v11.1 INDEX.md: "Forms file" section L53-77 replaced with post-H.2 prose per spec
- Sub-edit (4) validate-pack.py: project-template entry extended from 3-element set to 4-element set; pack-root unchanged; docstrings extended
- Sub-edit (5) test-issue-forms.sh: surface-aware assertions updated; wi-part-letter presence/absence assertions added; Part-id token assertions added in wi-blockers branch; DISJOINT invariant verified

One minor implementation detail worth noting (not a deviation):

- Spec's verification command F1 / F3 use `grep -A6 "id: wi-type" … | grep -c "^[[:space:]]*-"`. This `-A6` window is too tight for the post-H.2 project-template form (4 options + description + 4 trailing structural lines = needs ~A11). The CANONICAL count (via YAML parse) confirms 4 / 1. I document this in §5.F with an alternative widened-window grep that emits the expected counts. Recommend the spec verification command be widened to `-A11` or migrated to a YAML-parse-based check in a future planner revision; this is informational only — not actionable in H.2.

## §12 New POQs introduced

ZERO new POQs.

The PROJECT-TEMPLATE-ONLY framing was resolved at architect-time
(POQ-NEW-1 → Option c per reconciliation §4.2 + user-lock 2026-05-26).
The implementation follows the resolution mechanically.

## §13 Files-changed inventory

| Path | Change type |
|---|---|
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | modified |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | new |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | modified |
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-issue-forms.sh` | modified |
| `test-fixtures/manifest.txt` | modified (RC9 staging) |

## §14 Commit message draft

Per `PLAN-BD-185-ADDENDUM.md` §4.2 "Commit message draft (post-update)" + the no-scope-keyword decision (mixed-scope per `project-template/` + `scripts/` + `maintenance-docs/` + `test-fixtures/`):

```
feat: v11 — BD-185 work-item.yml form-family extension (project-template 4th wi-type + part-letter input + archive snapshot) (Batch 19d.2)
```

Per `CLAUDE.md` § "Rules for agents working on this repo" → commit-subject scope-keyword convention: NO keyword (mixed-scope). Per CI Check 36, neutral framing skips the scope-claim verification. Other approved suffix shapes do not apply (this is a per-BD H.2 commit within Batch 19d, not a broad batch fix).

---

End of IMPL-REPORT.
