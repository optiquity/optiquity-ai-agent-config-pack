# IMPLEMENTATION-REPORT — BD-195 S1 commit C3

**Agent:** pack-coder. **Branch:** v11-dev. **HEAD (unchanged; no git state change):** `cae3c21ef122907d272950d1f984432db77fce3e` (`cae3c21`).
**Date:** 2026-05-31. **Commit:** C3 of segment S1 (P-02 BLOCKER ⊕ P-12 ⊕ P-08 ⊕ P-31a).
**Plan:** `maintenance-docs/v11-implementation/PLAN-BD-195-S1.md` §C3 (Groups A/B/C/E/G + P-08).
**Mode:** NON-DESTRUCTIVE only. No file deleted. The `v11.1/` directory retirement is FLAGGED below for Pack Chat (user-approved deletion).

---

## 1. Pre-flight

- `git rev-parse HEAD` → `cae3c21ef122907d272950d1f984432db77fce3e` (matches prompt-stated base).
- `git status` at start → clean working tree.
- `python3 scripts/validate-pack.py` baseline → exit 0, "PASSED — all checks clean".
- Confirmed base contains all C3 targets: `v11.1/phase-part-v11.1/SCHEMA.md`, `v11.0/INDEX.md`, `v11.0/forms/work-item.yml`, `v11.1/forms/work-item.yml`, `project-template/.github/ISSUE_TEMPLATE/work-item.yml`, `scripts/validate-pack.py`, the two BD-193 records.

---

## 2. Per-Group execution

### Group A — relocate SCHEMA (as CREATE)

**Action:** CREATED `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md` as the de-contaminated copy of `…/v11.1/phase-part-v11.1/SCHEMA.md`. The old v11.1 SCHEMA is LEFT in place (Pack Chat deletes the v11.1/ dir).

**Tag-correction proof (9 hits → `phase-part-v11.0`):** The source `v11.1/phase-part-v11.1/SCHEMA.md` carried `v11.1` at L1, L4, L43, L49, L63, L69, L117, L187, L217 (matches plan EB-A3 exactly — verified via `grep -n "v11.1"`). All 9 corrected in the new file:
- L1 heading `# Schema — \`phase-part-v11.0\` (phase part)`
- L4 prose `template version \`phase-part-v11.0\``
- L43 body-marker `<!-- template_version: phase-part-v11.0 -->`
- L49 `…on every phase-part-v11.0 entity`
- L63 `No new label namespace is introduced by \`phase-part-v11.0\``
- L69 label-table `\`template:phase-part-v11.0\``
- L117 §5 body-marker `<!-- template_version: phase-part-v11.0 -->`
- L187 §7 `Reverse-emit grammar for phase-part-v11.0 is not yet specified`
- L217 §8 `…does NOT apply to \`phase-part-v11.0\``

**§5 cross-ref co-location fix (Group A):** In the source, the §3 Excluded-labels TD-promotion cross-refs pointed at `../v11.0/phase-epic-v11.0/SCHEMA.md` and `../v11.0/phase-task-v11.0/SCHEMA.md` (the SCHEMA lived one level up under `v11.1/`). Now co-located under `v11.0/`, corrected to sibling paths `../phase-epic-v11.0/SCHEMA.md` and `../phase-task-v11.0/SCHEMA.md`. (These are the only cross-ref paths in the SCHEMA; §5 Prerequisites grammar carries no inter-SCHEMA file paths.)

**Grammar verbatim:** §1–§6 and §8 substance is byte-identical to the source except for the 9 version-tag corrections + the 2 co-location path fixes. No grammar rule altered (identifier scheme, prohibited forms, marker trio, label family, state taxonomy, body section grammar, sub-issue hierarchy, marker reservations all preserved).

**Post-create grep:** `grep -c "v11.1"` on the new SCHEMA = **0**.

### Group B — `v11.0/INDEX.md` fold the phase-part row

**Action:** EDITED `v11.0/INDEX.md` (did NOT touch `v11.1/INDEX.md` — that is RETIRED via deletion).

- Added the phase-part row to the Client-applicable entry-types table (between phase-task and inbound rows):
  `| Phase part (\`Phase-N.Part-x\`) | [phase-part-v11.0/SCHEMA.md](phase-part-v11.0/SCHEMA.md) | \`phase-part-v11.0\` | \`template:phase-part-v11.0\` |`
- Updated the forms wi-type enumeration note to the 4-option live shape (see Group G text below — Group B + G ride the same heading block).

### Group C — `v11.0/forms/work-item.yml` 4-option live shape

**Action:** UPDATED `v11.0/forms/work-item.yml` from the 3-option archive shape to the 4-option live shape. Source content = `v11.1/forms/work-item.yml`, which is byte-identical to the live `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (plan EB-A4 confirmed; re-verified `diff` exit 0). Markers stay `work-item-v11.0` (2 occurrences: the `template:work-item-v11.0` label + the `<!-- template_version: work-item-v11.0 -->` body marker — both preserved, NOT bumped).

**Before:** 3 wi-type options (`td`, `phase-epic-skeleton`, `phase-task-skeleton`); "Pack work item" name; no `wi-part-letter`; Blockers/Unblocks/Dependencies grammar without Part-id forms.
**After:** 4 wi-type options (+`phase-part-skeleton`); `wi-part-letter` input added; Blockers/Unblocks/Dependencies grammar admits `Phase-N.Part-x` + `Phase-N.Part-x.Task-M`.

**Byte-equality proof:** `diff -q v11.0/forms/work-item.yml project-template/.github/ISSUE_TEMPLATE/work-item.yml` → identical (exit 0). This makes the validator's INFO byte-compare against the client surface pass cleanly (R6 risk resolved). `grep -c "phase-part-skeleton"` = 4; `grep -c "work-item-v11.0"` = 2; `grep -c "v11.1"` = **0**.

> **Decision note (Group C — name/intro framing).** The pre-edit v11.0 archive form carried a pack-flavored header ("Pack work item", "pack-managed", "Pack Chat"). The plan (Group C / EB-A4) directs the update source to be the v11.1 duplicate, which is the project-template-shaped (client-facing) 4-option form, and describes the v11.0 archive as "project-template-shaped … the archive captures the client-facing form." I therefore adopted the full byte-identical client shape so the validator byte-compare against the client surface is exact. This is plan-faithful (EB-A4 "source content = the v11.1 duplicate, already byte-identical to live") and matches the v11.1/INDEX.md archive-contract description that the archive captures "what clients install."

### Group E — validator 6th type (P-12; minimal + correct)

**Action:** EDITED `scripts/validate-pack.py` `check_template_archive_v11()`. Two minimal changes only:

1. Loop (was L1237): `("bd", "td", "phase-epic", "phase-task", "inbound")` → `("bd", "td", "phase-epic", "phase-task", "phase-part", "inbound")` (5 → 6 types; `phase-part` inserted before `inbound`, mirroring the INDEX row order).
2. Docstring count: `All five entry-type subdirectories … (bd, td, phase-epic, phase-task, inbound)` → `All six entry-type subdirectories … (bd, td, phase-epic, phase-task, phase-part, inbound)`.

Nothing else in the validator touched. `archive_root` stays `…/v11.0` (L1226); function name unchanged; the form byte-compare block (INFO) unchanged. The 6th-type existence-check passes because Group A created `v11.0/phase-part-v11.0/SCHEMA.md` in this same commit — verified in the validate-pack output: `OK: maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md — present`.

`grep -c "v11.1"` on `scripts/validate-pack.py` = **0** (was already 0 at HEAD — C2 cleaned the comments; C3 introduces none).

### Group G — `v11.0/INDEX.md` reword (P-31a)

**Action:** EDITED `v11.0/INDEX.md` heading + forms paragraph.

- `## Frozen forms` → `## Archived forms`.
- Bare "D16" cite → "BD-193 bug-fix carve-out" (twice in the work-item.yml bullet).
- "3-option `wi-type` dropdown" → "4-option `wi-type` dropdown" (now reflects Group C).
- KEPT the carve-out FACT: the bullet still records that the original v11.0 shipped form admitted a `bd` option and the BD-193 bug-fix carve-out removed it (clients use TD, not BD).
- Added the v11.0-mutable framing ("v11.0 is unshipped, so the archive form is mutable and tracks the live client … shape") — supports the Group C update legitimacy (D-3 mutable-archive).

### P-08 — annotate BD-193 records (in place; no history rewrite)

Three dated correction notes added IN PLACE (blockquote prefix before each existing verdict; existing text preserved verbatim below each note). These are TRACKED BD-193 historical records, NOT BD-185 attempt-records — NOT swept; their retained v11.1 hits are intentional historical record carrying the correction note.

**(a) `PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 F1.b (was ~L93):**
> **CORRECTION (2026-05-31, BD-195 S1 — VERDICT REVERSED).** The `templates-archive/v11.1/INDEX.md` this verdict CONFIRMED-CORRECT is RETIRED per BD-195 S1: there was never a v11.1 archive cut. Phase-parts are v11.0 scope (v11.0 is UNRELEASED, never frozen). The `phase-part-v11.1` row, the `## Entry types at v11.1` heading, and the "v11.0 frozen at 5 subdirs" framing were contamination. The verdict below is SUPERSEDED — the corrected state folds the phase-part row into `templates-archive/v11.0/INDEX.md` as `phase-part-v11.0`. This historical record is preserved with the correction note in place.

**(b) `PACK-REVIEW-BD-193-PHASE-4.md` §4.7 M-5 (was ~L559):**
> **CORRECTION (2026-05-31, BD-195 S1 — FRAMING SUPERSEDED).** This M-5 finding (and its remediation options, including "actually create the v11.1 archive forms directory") was framed around a v11.1 archive cut that never existed. Per BD-195 S1 the fictional `templates-archive/v11.1/` cut is retired; the phase-part work is v11.0 scope. The corrected resolution is NOT to create a v11.1 forms directory but to update the existing `templates-archive/v11.0/forms/work-item.yml` to the 4-option live client shape (done in BD-195 S1). The finding is preserved as historical record with this correction note in place.

**(c) `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` §4 S-1 (was ~L141):**
> **CORRECTION (2026-05-31, BD-195 S1 — SUPERSEDED).** This S-1 rewrite deepened the v11.1-archive-cut framing ("the v11.1 forms/ subdirectory will be populated when the v11.1 archive cut is completed"). Per BD-195 S1 there is no v11.1 archive cut — it was a mis-versioning contamination. Phase-parts are v11.0 scope; v11.0 is UNRELEASED and never frozen. The `templates-archive/v11.1/INDEX.md` this S-1 edited is RETIRED in BD-195 S1, and the phase-part row + 4-option form now live under `templates-archive/v11.0/`. This S-1 entry is preserved as historical record with the correction note in place; the AFTER text below is superseded.

No wholesale rewrite. The original verdicts/framing remain below each note for audit continuity.

> **Missed-finding ledger note (for Pack Chat, PM-only):** Plan §5.2 item 4 + §C3 P-08 recipe direct that the BD-195 missed-finding ledger record the BD-193 propagation of the v11.1 contamination. That ledger entry is a PM-only / Pack-Chat write (BACKLOG / pack-memory surface) — NOT performed by this coder. Flagged here for Pack Chat to record.

---

## 3. v11.1/ DELETION FLAGGED for Pack Chat (NOT performed)

Per the destructive-op gate, the coder did NOT delete anything. After this commit's relocations, the following three `v11.1/` files are fully superseded and should be deleted by Pack Chat (user-approved), after which the directory becomes empty and is removed:

```
maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml
maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md
```
→ resulting empty dirs to remove: `…/v11.1/phase-part-v11.1/`, `…/v11.1/forms/`, `…/v11.1/`.

All three are TRACKED (per plan), so the deletion is `git rm`-class executed by Pack Chat at commit time with user approval. The new `v11.0/phase-part-v11.0/SCHEMA.md` + the updated `v11.0/INDEX.md` + `v11.0/forms/work-item.yml` carry the de-contaminated equivalents.

**Verification posture:** all gates below are GREEN **with `v11.1/` still present**. The validator's `archive_root` is `maintenance-docs/v11-research/templates-archive/v11.0` (L1226) — it scans v11.0/ ONLY, so leaving v11.1/ in the tree does not fail it. Post-deletion the tree is identical from the validator's perspective.

---

## 4. Verification results

| Gate | Command | Result |
|---|---|---|
| validate-pack | `python3 scripts/validate-pack.py` | **exit 0** — "PASSED — all checks clean"; 6-type loop reports `OK: …/v11.0/phase-part-v11.0/SCHEMA.md — present` |
| test-issue-forms | `bash scripts/tests/test-issue-forms.sh` | **exit 0** — "Failed: 0 / All tests passed." |
| checks 36/37/38 | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` | **exit 0** — "All tests passed." |
| check 43 | `bash scripts/tests/test-validate-pack-check-43.sh` | **exit 0** — "All tests passed." |
| grep v11.1 — validate-pack.py | `grep -c "v11.1" scripts/validate-pack.py` | **0** |
| grep v11.1 — new SCHEMA | `grep -c "v11.1" …/v11.0/phase-part-v11.0/SCHEMA.md` | **0** |
| grep v11.1 — v11.0/INDEX.md | `grep -c "v11.1" …/v11.0/INDEX.md` | **0** |
| grep v11.1 — v11.0 form | `grep -c "v11.1" …/v11.0/forms/work-item.yml` | **0** |
| form byte-equal to client | `diff -q …/v11.0/forms/work-item.yml project-template/.github/ISSUE_TEMPLATE/work-item.yml` | identical (exit 0) |

**Manifest regen (scripts/ touched):** `bash test-fixtures/build.sh --all --clean` → exit 0. `git diff --stat test-fixtures/manifest.txt` → **EMPTY** (no manifest change; the manifest enumerates `project-template/` surface content, which C3 did not alter — C3 touches `maintenance-docs/` archive + the validator only). No manifest staging needed this commit.

---

## 5. Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md` | **new** (Group A — de-contaminated relocation) |
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | modified (Group B row + Group G reword) |
| `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | modified (Group C — 4-option live shape) |
| `scripts/validate-pack.py` | modified (Group E — 6th type + docstring count) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` | modified (P-08 — two correction notes, in place) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` | modified (P-08 — one correction note, in place) |

**`git status --short`:**
```
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md
 M maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md
 M maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md
 M maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml
 M scripts/validate-pack.py
?? maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/
```
(The `??` is the new SCHEMA dir — untracked, staged by Pack Chat. The `v11.1/` deletions are NOT yet present in status because the coder did not delete — Pack Chat performs them.)

---

## 6. Plan deviations

**Zero substantive deviations.** One framing decision documented inline (Group C name/intro — adopted the full byte-identical client shape per EB-A4's "source content = the v11.1 duplicate"; this is the plan's stated source, not a deviation). The C3 scope (Groups A/B/C/E/G + P-08) executed exactly as the plan's §C3 specifies. The two BLOCKER-adjacent destructive steps (v11.1/ deletion) are correctly deferred to Pack Chat per the destructive-op gate.

## 7. New POQs introduced

None.

---

## 8. Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| Group A: new SCHEMA created, 9 tags → phase-part-v11.0, §5 cross-refs co-located, grammar verbatim | PASS |
| Group B: phase-part-v11.0 row folded into v11.0/INDEX.md | PASS |
| Group C: v11.0 form updated to 4-option live shape, markers stay work-item-v11.0, byte-equal to client | PASS |
| Group E: validator 6th type added + docstring count; nothing else touched | PASS |
| Group G: "Frozen forms"→"Archived forms"; "D16"→"BD-193 bug-fix carve-out"; carve-out fact kept | PASS |
| P-08: dated REVERSED/superseded notes in place on PHASE-4 §3.1.2, §4.7 M-5, PHASE-5 §4 S-1; no history rewrite | PASS |
| validate-pack.py exit 0 (6-type loop finds new SCHEMA) | PASS |
| test-issue-forms + checks-36-37-38 + check-43 PASS | PASS |
| grep -c "v11.1" = 0 on validate-pack.py, new SCHEMA, v11.0/INDEX.md (+ v11.0 form) | PASS |
| Manifest regen run; diff reported (EMPTY) | PASS |
| NO destructive ops; v11.1/ deletion FLAGGED with exact paths for Pack Chat | PASS |
| No git state change; HEAD unchanged at cae3c21 | PASS |

---

## 9. Boundary discipline check

C3's edits are all PACK-SIDE surfaces (`maintenance-docs/v11-research/templates-archive/…`, `maintenance-docs/v11-implementation/…`, `scripts/validate-pack.py`). None touch `project-template/`, `supporting-docs/`, or any client-shipped surface — the live `project-template/.github/ISSUE_TEMPLATE/work-item.yml` was READ ONLY (as the byte-source reference for Group C) and NOT modified. No project-side SSOT investigation required; no pack-only reference was introduced into any project-side file. No boundary-discipline stop. The pack-side archive (`templates-archive/`) is the correct SSOT for the v11.0 template-archive cut.

---

## 10. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| No destructive ops on own authority | No `rm`/`git rm`/delete run. `find …/v11.1 -type f` still returns all 3 files (INDEX.md, forms/work-item.yml, phase-part-v11.1/SCHEMA.md). Deletion paths flagged in §3 for Pack Chat. | COMPLIANT |
| Empirical (measure before/after) | SCHEMA tag-correction measured: source `grep -n "v11.1"` = 9 hits at L1,4,43,49,63,69,117,187,217 (= EB-A3); new SCHEMA `grep -c "v11.1"` = 0. Form `diff -q` exit 0 vs client. All grep bars quoted in §4. | COMPLIANT |
| SCHEMA grammar verbatim | §1–§6/§8 substance unchanged; only the 9 version tags + 2 §3 co-location cross-ref paths edited. No identifier/marker/label/state/section/hierarchy grammar rule altered. | COMPLIANT |
| Validator logic minimal + correct (P-12) | Two edits only: loop tuple 5→6 (`phase-part` inserted before `inbound`) + docstring "five…inbound"→"six…phase-part, inbound". `archive_root`, function name, byte-compare block untouched. validate-pack exit 0; 6th-type OK line present. | COMPLIANT |
| P-08 annotate, not rewrite history | Three blockquote correction notes added BEFORE existing verdicts; original text preserved verbatim below each. BD-193 records (not BD-185 attempt-records) → not swept; retained v11.1 hits intentional + carry note. | COMPLIANT |
| Edit-in-place, not full rewrite | All non-create edits are targeted Edit calls on specific regions; new SCHEMA is the only Write (a legitimate CREATE per Group A). Surrounding content confirmed intact via post-edit greps. | COMPLIANT |
| Regenerate manifest (scripts/ touched) | `bash test-fixtures/build.sh --all --clean` exit 0; `git diff --stat test-fixtures/manifest.txt` EMPTY → reported in §4. | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat after ALL edits + verification PASS, noting v11.1/ deletion PENDING Pack Chat + that validator scans v11.0/ only so green-with-v11.1-present holds. No parent stop issued. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops / no deferral | No state-changing git verb run; only read-only verbs + validate-pack + tests + manifest build. HEAD unchanged at cae3c21. No work deferred beyond the explicitly-Pack-Chat-owned v11.1/ deletion + PM-only ledger note. | COMPLIANT |
| Boundary discipline pre-flight (P-missed-7) | §9 — all edits pack-side; live project-template form read-only; no pack-only ref added to a project-side file. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-195-S1-C3.md.**
