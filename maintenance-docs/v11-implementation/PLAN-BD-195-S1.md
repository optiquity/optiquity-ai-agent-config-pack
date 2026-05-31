# PLAN-BD-195-S1 — Mis-versioning de-contamination (segment S1)

**Author:** pack-planner (BD-195 segment S1 fix-plan). **READ-ONLY on source; implementation NOT performed here.**
**Date:** 2026-05-31. **Branch:** v11-dev. **HEAD:** `71f31d5228a17e0c8ea9de275f4e6630f642e92e` (`71f31d5`).
**Inputs sequenced FROM:** `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (P-NN detail + couplings), `ARCHITECTURE-BD-195-SEGMENTATION.md` (S1 definition, intra-S1 order, §5.2 "V2 §10 Groups A–G ARE the S1 recipes"), the held `ARCHITECTURE-BD-185-V2.md §10` + `PLAN-BD-185-V2.md §6` (fix recipes — **contamination-stripped**: their v11.1 framing is the very thing S1 removes; recipes re-verified against HEAD).
**Scope:** S1's 12 problems — **P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a, P-31b, P-31k**. The two BLOCKERs are P-01 + P-02.
**User decisions folded in (already made):** OQ-1 hybrid → **Pattern-B archive-sweep of the BD-185 attempt-records (P-09/P-17/P-18) to `maintenance-docs/archive/v11/` DURING S1**; OQ-3 → `PACK-REVIEW-BD-185-H.2.md` sweeps with P-17/P-18 (it is TRACKED at `3bef42b`, so its move is `git mv`-class, executed by Pack Chat at commit time). OQ-8 → P-13 path-normalization is the precondition for P-02.

**Categorical fact in force (not re-litigated):** v11.0 is UNRELEASED, never frozen; phase-parts was ALWAYS v11.0 scope, never v11.1. Every "v11.1" / "frozen v11.0" mislabel on an S1 surface is contamination to expunge.

**Why this plan does NOT transcribe the held V2 §10 specifics blind:** the SEGMENTATION EB-3 counted "32 templates-archive/v11" occurrences and called them all bare. Re-measured at `71f31d5` (EB-A1 below), the truly *bare* (missing the `maintenance-docs/v11-research/` prefix) recipe-relevant paths are far fewer, and PLAN-V2 §6 already normalized its recipe-step paths. P-13's real residue is in V2 §2/§3/D-4 prose, not in the §6 recipe steps a coder executes. This plan sizes P-13 to the actual residue, not the inflated 32.

---

## 1. The 12-problem coverage table (problem → commit)

Every S1 problem maps to exactly one commit; none dropped. Severity from the reconciled list.

| P-NN | Sev | Commit | What the commit does for this problem |
|---|---|---|---|
| **P-13** | SHOULD | **C1** | Normalize the bare `templates-archive/v11.x/...` recipe/prose paths in `ARCHITECTURE-BD-185-V2.md` (+ the 1 bare ref in `PLAN-BD-185-V2.md`) to full `maintenance-docs/v11-research/templates-archive/...` — the OQ-8 precondition for executing P-02. |
| **P-01** | BLOCKER | **C2** | De-contaminate the 3 `validate-pack.py` + 6 `test-issue-forms.sh` v11.1 comments → v11.0 (Groups D + F). |
| **P-02** | BLOCKER | **C3** | Retire the fictional `templates-archive/v11.1/` cut: relocate SCHEMA → `v11.0/phase-part-v11.0/`, fold the phase-part row into `v11.0/INDEX.md`, update the v11.0 archive form to the 4-option live shape, retire the duplicate (Groups A + B + C). |
| **P-12** | SHOULD | **C3** | Add `"phase-part"` as the 6th type to `check_template_archive_v11()` (Group E) — ENCODING lock-step with P-02; touches `scripts/`. |
| **P-08** | MUST | **C3** | Reverse the BD-193 PHASE-4 §3.1.2/§4.7-M-5 "CONFIRMED-CORRECT" verdict + PHASE-5 §4 S-1 "v11.1 archive cut" framing (the blessed source `v11.1/INDEX.md` is retired in this same commit). |
| **P-31a** | NIT | **C3** | `v11.0/INDEX.md` "Frozen forms"→"Archived forms"; bare "D16"→"BD-193 bug-fix carve-out" (Group G) — rides the P-02 archive cleanup. |
| **P-16** | SHOULD | **C4** | Add the forward "ordering subsystem SUPERSEDED by ORDERING-ADDENDUM §0.1" pointer to `ARCHITECTURE-BD-185-V2.md` (header/§0) — done BEFORE the attempt-records sweep so the swept V2 carries the correct cross-link. |
| **P-31k** | NIT | **C4** | `ARCHITECTURE-V3.3-DELTA.md` D-22/D-4-V2 rows — optional "overtaken by BD-193" addendum (live design doc; stays live, not swept). |
| **P-31b** | NIT | **C4** | `AUDIT-INVENTORY-BD-TD-PATH.md` D16 "frozen" wrapper snapshot — adopt corrected v11.0-mutable framing on the live audit doc (stays live, not swept). |
| **P-09** | MUST | **C5** | `PACK-REVIEW-BD-185-H.2.md` → Pattern-B archive-sweep to `maintenance-docs/archive/v11/` (TRACKED → `git mv`). OQ-3 disposition = sweep. |
| **P-17** | SHOULD | **C5** | The 6 `IMPLEMENTATION-REPORT-BD-185-*.md` attempt-records → Pattern-B archive-sweep (all TRACKED → `git mv`). OQ-1(S1 subset) disposition = sweep. |
| **P-18** | SHOULD | **C5** | `PACK-REVIEW-BD-185-H.1.md` → Pattern-B archive-sweep (TRACKED → `git mv`). |

**Coverage proof:** 12 of 12 mapped (P-13→C1; P-01→C2; P-02/P-12/P-08/P-31a→C3; P-16/P-31k/P-31b→C4; P-09/P-17/P-18→C5). No S1 problem omitted; the two BLOCKERs (P-01, P-02) land in C2 and C3 respectively.

---

## 2. Intra-S1 dependency graph + commit sequence

### 2.1 Hard edges (from the SEGMENTATION §3.2 + RECONCILED couplings, re-verified)

- **P-13 → P-02** (OQ-8 precondition): the V2 §10 / PLAN-V2 §6 recipes that drive P-02 must carry full archive paths before a coder executes them, or recipe steps resolve to a non-existent repo-root `templates-archive/`. P-13 lands FIRST.
- **P-02 ↔ P-12 ↔ P-08 ↔ P-31a** (lock-step, one commit C3): retiring the `v11.1/` cut (P-02) simultaneously (a) requires the validator's 6th type (P-12 — Group E targets the cut P-02 creates), (b) invalidates the BD-193 review/Phase-5 blessing of that cut (P-08 — the blessed `v11.1/INDEX.md` is retired in the same diff, so its "CONFIRMED-CORRECT" verdict must be reversed in lock-step), and (c) carries the cosmetic "Frozen forms"/D16 reword on the resulting `v11.0/INDEX.md` (P-31a — Group G rides Group B). These move together or the tree is internally inconsistent mid-sequence.
- **P-16 before C5** (soft sequencing): P-16 adds the forward ordering-addendum pointer to `ARCHITECTURE-BD-185-V2.md`. V2 is a held attempt-record but is NOT in the OQ-1 sweep set (it is an active design substrate, not an IMPL/REVIEW record — see §4.4). The pointer is added while V2 is live so the corrected cross-link is permanent.

### 2.2 Soft edges / independence

- **P-01 is independent** (comment-only; no precondition). BLOCKER-first convention places it at C2, immediately after the P-13 precondition.
- **P-31b, P-31k** are independent live-doc currency edits (C4); they ride C4 for work-shape adjacency (contamination-era residue on live docs that stay live).
- **P-09/P-17/P-18** are disposition moves (C5); they run LAST so the de-contamination of the active tree (C2–C4) is complete before the records leave it.

### 2.3 The commit sequence (5 commits)

```
C1  P-13          normalize bare archive paths in V2/PLAN-V2 prose      [precondition]
        │  (OQ-8: full paths must exist before the P-02 recipe runs)
        ▼
C2  P-01          de-contaminate validator + test comments (BLOCKER)    [scripts/ → manifest+tests]
        │  (independent; BLOCKER-first)
        ▼
C3  P-02 ⊕ P-12 ⊕ P-08 ⊕ P-31a   retire v11.1 cut + 6th type + reverse-blessing + reword (BLOCKER)
        │  (lock-step; depends on C1 paths; scripts/ → manifest+tests; archive deletion = destructive→user-approval)
        ▼
C4  P-16 ⊕ P-31k ⊕ P-31b   forward-pointer + 2 live-doc currency edits  [docs-only]
        │  (P-16 before the sweep so V2 carries the corrected link)
        ▼
C5  P-09 ⊕ P-17 ⊕ P-18      Pattern-B archive-sweep of 8 BD-185 attempt-records  [git mv → archive/v11/]
                            (Pack-Chat-executed git mv; coder does NOT move tracked files)
```

**Working-state guarantee:** `validate-pack.py` is green at HEAD (EB-A6) and stays green after every commit. C1 is docs-only (no code). C2 is comment-only (assertions/runtime unchanged). C3's Group E loop-extension passes because C3 also creates `v11.0/phase-part-v11.0/SCHEMA.md` in the same commit (the 6th type exists before the loop checks it). C4 is docs-only. C5 is a tracked-file move with inbound-ref repair (§3.5). CI passes at each intermediate step.

---

## 3. Per-commit detail (scope, file targets, de-contaminated recipe steps, sweep mechanics)

All recipe steps are adapted from the held V2 §10 Groups A–G + PLAN-V2 §6, **re-verified against HEAD `71f31d5`** and stripped of the v11.1 framing they describe (the recipe's *mechanics* are valid; the recipe docs' own v11.1 prose is contamination handled by P-13/P-16 + the sweep).

### C1 — P-13: normalize bare archive paths (OQ-8 precondition)

- **Subject:** `fix: v11 — BD-195 S1 normalize bare templates-archive paths in V2/PLAN-V2 (P-13; OQ-8 precondition)`
- **Scope keyword:** none (only `maintenance-docs/` touched; reads cleanest with no keyword).
- **File targets + exact edits:**
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` — the bare `templates-archive/v11.x/...` refs at **L102, L103, L104, L234, L259, L261, L274, L275, L286, L298, L320, L933** (EB-A1: 12 lines carry `templates-archive/v11` WITHOUT the `v11-research/` prefix). Prefix each to `maintenance-docs/v11-research/templates-archive/...`. NOTE: the §10 recipe steps themselves (L846–L886, Groups A–C) already carry FULL paths — verified; do NOT touch those.
  - `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` — the single bare ref at **L137** (a Group-H BACKLOG-prose mention; PLAN-V2 §6 recipe steps are already normalized per its own §6 preamble "BD-195 F-AC1-01"). Prefix to full path.
- **De-contamination caveat:** P-13 normalizes PATHS only. It does NOT touch the surrounding v11.1 *framing* prose in those docs (that framing is handled when V2/PLAN-V2's own disposition is decided — see §4.4; V2/PLAN-V2 are NOT in the C5 sweep set). P-13 is purely "make the recipe a coder will execute resolve to a real path."
- **Verification:** `grep -n "templates-archive/v11" ... | grep -v "v11-research/templates-archive"` returns ZERO bare hits in both files post-edit. No manifest regen (no `scripts/`). `validate-pack.py` green.
- **Dependencies:** none (first commit).

### C2 — P-01: de-contaminate validator + test comments (BLOCKER; Groups D + F)

- **Subject:** `fix: v11 — BD-195 S1 de-contaminate validate-pack/test v11.1→v11.0 comments (P-01 BLOCKER)`  — `pack-only`.
- **File targets + exact edits (re-verified at HEAD):**
  - `scripts/validate-pack.py` `check_issue_template_forms()` — **L1086** ("added at v11.1 (BD-185 H.2)"), **L1121** ("added at v11.1 (BD-185 H.2)"), **L1123** ("introduced at v11.1"). Replace with "added in v11.0 (BD-185)" / "introduced in v11.0", dropping the recovery-volatile `H.2` sub-batch label (per RECONCILED P-01: researchers agree direction v11.0; settle the BD-anchor wording here — recommend keep `(BD-185)`, drop `H.2`). **`expected_wi_type_options_per_surface` runtime dict is CORRECT — do NOT touch** (Group D).
  - `scripts/tests/test-issue-forms.sh` — the 6 comment blocks at **L19, L95, L139, L162, L180, L265** carrying "added at v11.1 (BD-185 H.2)". Same replacement. **Assertions are version-neutral and CORRECT — do NOT touch** (Group F).
- **Verification (PREFLIGHT-gated):** `bash scripts/tests/test-issue-forms.sh` PASS; `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASS; `bash scripts/tests/test-validate-pack-check-43.sh` PASS; `python3 scripts/validate-pack.py` full PASS. **Manifest regen REQUIRED** (`scripts/` touched): `bash test-fixtures/build.sh --all --clean`, stage `test-fixtures/manifest.txt` in this commit if the diff is non-empty. `grep -c "v11.1"` on both files = 0.
- **Dependencies:** independent of C1 in content (could run before C1), but sequenced after C1 to keep BLOCKER-then-BLOCKER ordering clean (P-01 BLOCKER → P-02 BLOCKER).

### C3 — P-02 ⊕ P-12 ⊕ P-08 ⊕ P-31a: retire the v11.1 cut + 6th type + reverse blessing + reword (BLOCKER; Groups A/B/C/E/G)

- **Subject:** `fix: v11 — BD-195 S1 retire fictional templates-archive/v11.1 cut → v11.0 + 6th archive type (P-02 BLOCKER, P-12, P-08, P-31a)`  — `pack-only`.
- **P-02 file targets + recipe (Groups A/B/C):**
  - **Group A — relocate SCHEMA.** `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` → `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`. Correct the `phase-part-v11.1` version tag at **L1, L4, L43, L49, L63, L69, L117, L187, L217** → `phase-part-v11.0` (EB-A3: 9 v11.1 hits). **KEEP grammar substance verbatim** (§1–§6, §8) — this is the SOLE live home of the user-approved phase-part grammar (V2 §2.B carve-out). Fix the §5 cross-refs to sibling v11.0 SCHEMAs (paths shift from `../v11.0/...` to `../...` once co-located). **No script consumes the SCHEMA path — zero code-consumer blast radius** (verified RECONCILED P-02).
  - **Group B — fold + retire INDEX.** EDIT `v11.0/INDEX.md`: add the phase-part row to the client-applicable table (`template_version`=`phase-part-v11.0`, label=`template:phase-part-v11.0`, schema link `phase-part-v11.0/SCHEMA.md`); update the "Frozen/Archived forms" wi-type enumeration to note the project-template form admits `phase-part-skeleton` (4 options). RETIRE `v11.1/INDEX.md` — remove the FALSE Convention-Y claims (the `status:cancelled` exercise that never happened, the `work-item-v11.0→v11.1` bump that never happened, the "v11.0 frozen at 5 subdirs" framing) and the D1–D16 cross-ref block (L95–107).
  - **Group C — relocate/reframe the form.** The v11.0 archive form `v11.0/forms/work-item.yml` is currently the **3-option** form (td/phase-epic-skeleton/phase-task-skeleton — EB-A4); the LIVE `project-template/.github/ISSUE_TEMPLATE/work-item.yml` is the **4-option** form (+`phase-part-skeleton`, +`wi-part-letter`, +Part-id Blockers grammar). UPDATE the v11.0 archive form to the 4-option live shape (markers stay `work-item-v11.0`, already correct). The retired `v11.1/forms/work-item.yml` duplicate is already byte-identical to the live 4-option form (EB-A4) — its content IS the update source. RETIRE the v11.1 duplicate. (D-3 mutable-archive is load-bearing here: updating the archived form is legitimate because v11.0 is unshipped.)
  - **Destructive-op gate:** after retiring all three `v11.1/` files the directory is empty and removed. **`git rm` / deletion is destructive → Pack Chat asks the user before the coder's working-tree deletions are committed** (`feedback-no-destructive-without-approval`).
- **P-12 file target + recipe (Group E):** `scripts/validate-pack.py check_template_archive_v11()` — the entry-type loop at **L1237** (`("bd","td","phase-epic","phase-task","inbound")`, 5 types) → add `"phase-part"` (6 types). Update the docstring count. `archive_root` (L1226, `…/v11.0`) + function name stay correct. After Group A the `v11.0/phase-part-v11.0/SCHEMA.md` exists, so the loop's existence-check passes. The form byte-compare (L1265) is INFO-style and reflects the now-4-option archive form (won't hard-fail).
- **P-08 file targets + recipe (reverse the blessing):** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 (L93+) + §4.7 M-5 — the "CONFIRMED-CORRECT" verdicts on the `v11.1/INDEX.md` heading + `phase-part-v11.1` row are now false (the blessed source is retired in this same commit); annotate them as REVERSED ("the v11.1 cut this verdict confirmed is retired per BD-195 S1; verdict superseded — phase-parts is v11.0"). `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` §4 S-1 (L141+) — the rewrite that "deepened the v11.1 archive cut framing" is annotated as superseded. **Do NOT rewrite the BD-193 records' history wholesale** — these are TRACKED historical records; add a dated correction note in place (they are BD-193 records, NOT BD-185 attempt-records, so they are NOT in the C5 sweep — see §4.4). Record the missed-finding in the BD-195 missed-finding ledger (Pack Chat / PM-only).
- **P-31a file target + recipe (Group G):** `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` — "Frozen forms" heading → "Archived forms"; bare "D16" cite → "BD-193 bug-fix carve-out". **KEEP the carve-out FACT** (L31–34). (This rides the Group B edit to the same file.)
- **Verification (PREFLIGHT-gated):** `python3 scripts/validate-pack.py` full PASS (the 6-type loop now finds `phase-part-v11.0/SCHEMA.md`); `bash scripts/tests/test-issue-forms.sh` + `test-validate-pack-checks-36-37-38.sh` + `test-validate-pack-check-43.sh` PASS. **Manifest regen REQUIRED** (`scripts/` touched). `grep -c "v11.1"` = 0 on `validate-pack.py`, the relocated SCHEMA, `v11.0/INDEX.md`; the `v11.1/` directory no longer exists (`find … v11.1 -type f` empty). The PHASE-4/PHASE-5 v11.1 hits are intentionally retained as historical record carrying a correction note (NOT counted against the active-code clean bar — see §5).
- **Dependencies:** **C1** (the P-02 recipe paths must resolve). The four problems are one lock-step commit.

### C4 — P-16 ⊕ P-31k ⊕ P-31b: forward-pointer + live-doc currency (docs-only)

- **Subject:** `fix: v11 — BD-195 S1 V2 forward ordering-pointer + V3.3-DELTA/BD-TD-PATH currency (P-16, P-31k, P-31b)`  — none (only `maintenance-docs/`).
- **P-16 file target + recipe:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` header (L3 "Status: Authoritative. Standalone.") / §0 — add a forward pointer: "the tracker-mode execution-ordering subsystem (§5.1/§5.2, D-7 mechanism clause, D-8, §7 ordering ops, §6 ordering reads/writes) is SUPERSEDED by `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §0.1; that addendum wins for ordering, this doc for all else." (EB-A5: V2 currently has ZERO `ORDERING-ADDENDUM` refs — the supersession is one-directional today.) Done BEFORE the C5 sweep so V2 carries the corrected cross-link permanently. **V2 itself is NOT swept** (it is the active design substrate BD-185 restart reads — §4.4).
- **P-31k file target + recipe:** `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` — the D-22/D-4-V2 rows (L27, L28) record project-side work-item.yml options overtaken by BD-193; add a one-line "overtaken by BD-193" addendum to each. (Live design doc; NOT a leak — pack-side architect doc designing a project-side deliverable is allowed; stays live, not swept.)
- **P-31b file target + recipe:** `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md` — the D16 "frozen at 5 subdirs" wrapper recorded at **L153, L743** (and the surrounding D16 framing). Adopt the corrected v11.0-mutable framing (annotate the snapshot: the "frozen" wrapper it records is rejected per BD-195 S1 CR-1; v11.0 archive is mutable while unshipped). Live audit doc; stays live.
- **Verification:** no manifest regen (docs-only). `validate-pack.py` green. V2 now resolves the ORDERING-ADDENDUM forward link (`grep -c ORDERING-ADDENDUM` ≥ 1).
- **Dependencies:** none on C2/C3 content; ordered after C3 for work-shape grouping; MUST precede C5 (P-16 edits V2 before any V2 disposition).

### C5 — P-09 ⊕ P-17 ⊕ P-18: Pattern-B archive-sweep of the 8 BD-185 attempt-records

- **Subject:** `docs: v11 — BD-195 S1 Pattern-B sweep 8 BD-185 attempt-records → archive/v11/ (P-09, P-17, P-18; OQ-1/OQ-3)`  — none (mixed `maintenance-docs/` move; reads cleanest with no keyword).
- **Mechanic: this is a `git mv`-class commit executed by PACK CHAT, not the coder.** All 8 files are TRACKED (EB-A2), so the move is `git mv <src> maintenance-docs/archive/v11/<name>`. The coder does NOT move tracked files (`feedback-no-destructive-without-approval` + agents-never-commit). Pack Chat performs the `git mv` at commit time with user approval; if any inbound-ref repair (§3.5) is needed in a NON-PM file, that repair goes to a coder edit folded into this commit or a sibling.
- **The 8 files swept (TRACKED) → `maintenance-docs/archive/v11/`:**
  1. `PACK-REVIEW-BD-185-H.2.md` (P-09; OQ-3; 25 v11.1 hits) — tracked at `3bef42b`.
  2. `PACK-REVIEW-BD-185-H.1.md` (P-18; 18 v11.1 hits).
  3. `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` (P-17; 38 v11.1).
  4. `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md` (P-17; 22 v11.1).
  5. `IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md` (P-17; 21 v11.1).
  6. `IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md` (P-17; 26 v11.1).
  7. `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md` (P-17; 8 v11.1).
  8. `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-REVIEW-FIXES.md` (P-17; 2 v11.1).
  (All currently in `maintenance-docs/v11-implementation/`.)
- **Why sweep, not de-contaminate in place (OQ-1/OQ-3 user decision):** these are workflow artifacts documenting the contaminated BD-185 attempt — a historical record of "what was done, including the error." Per V2 §10 Group H + RECONCILED P-17/P-18, rewriting their v11.1 prose loses the audit trail. Sweeping them out of the active `v11-implementation/` tree means the BD-185 restart never reads them as live spec; their v11.1 framing is preserved as history, not active state. `maintenance-docs/archive/v11/` is the established Pattern-B target (EB-A2 — already a tracked dir holding the v10 corpus).
- **Inbound-ref repair (the 7b sweep):** see §3.5 — the inbound refs are overwhelmingly BD-195 audit docs that legitimately name these files as audit *subjects* (those refs stay; they describe the records, which now live at the archive path). The two repair classes are (a) the records' cross-references to each other (move together → relative refs among the 8 stay valid), and (b) the `pack-ops/BACKLOG.md` Step-9 reference (PM-only; Pack Chat reconciles the path prose when the sweep lands).
- **Verification:** all 8 files present under `maintenance-docs/archive/v11/`; none remain in `v11-implementation/`. `git status` shows `R` (rename) for each (the post-mv-restage discipline applies if any swept file is then edited — none are here). No manifest regen (no `scripts/`). `validate-pack.py` green. After C5, `grep -rl "v11.1" maintenance-docs/v11-implementation/` no longer returns the 8 attempt-records (they moved); the active-tree clean bar is met (§5).
- **Dependencies:** runs LAST (after C2–C4 finish de-contaminating the active code/archive so the records leave a clean tree). C4 (P-16) must precede it so V2's forward pointer is in place — though V2 is NOT among the 8 swept files (§4.4), the sweep commit is the natural fence after which the BD-185 restart can proceed.

### 3.5 Inbound-reference repair detail (the 7b sweep for C5)

EB-A7 measured every inbound `.md` reference to the 8 swept files (excluding `.git/` and `prison/`). Disposition:

| Inbound referrer class | Files | Repair |
|---|---|---|
| BD-195 audit/research docs naming the records as audit SUBJECTS | `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`, `-REFRESH-POST-BD196.md`, `-SUPERSEDED-MAP.md`, `-RETAINED-DECISIONS.md`, `-LANDSCAPE-STATE.md`, `-R7-PREREAD.md`, `ARCHITECTURE-BD-195-SEGMENTATION.md`, `-RESCOPE.md`, `RESEARCH-BD-195-SEGMENT-R7-epicenter.md`, `PLAN-BD-195-INVESTIGATION.md` | **No repair / optional path-update.** These legitimately name the records; the names still resolve to the same files at the new archive path. If any cites a hard `v11-implementation/...` path, Pack Chat MAY update the path-prose, but the references are not broken cross-links (they are audit attributions). NOT a coder edit. |
| The 8 records cross-referencing each other | the 8 themselves | **Move together; relative refs among them stay valid.** No repair. |
| `pack-ops/BACKLOG.md` Step-9 line (L3167) | PM-only | **Pack Chat reconciles** the `maintenance-docs/v11-implementation/...` path prose to the archive path when the sweep lands (PM-only direct edit; coder does NOT touch BACKLOG). |

No non-PM live cross-link breaks (the audit docs are themselves in-flight BD-195 work, not client-shipped or load-bearing live design). This satisfies the "no stale references" risk for C5.

---

## 4. Design notes, contingencies, and the disposition boundary

### 4.1 Why P-08's BD-193 records are edited-in-place, NOT swept
P-08's surfaces are `PACK-REVIEW-BD-193-PHASE-4.md` + `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` — **BD-193** records, not BD-185 attempt-records. The OQ-1/OQ-3 user decision authorizes a Pattern-B sweep of the **BD-185** attempt-records (P-09/P-17/P-18) only. BD-193's in-scope work (per-surface wi-type split, `bd`-removal carve-out) is CORRECT and retained; only the v11.1 *framing* it propagated is the issue. The correct treatment is a dated correction-note in place (reversing the "CONFIRMED-CORRECT" verdict + flagging the S-1 deepening as superseded), preserving the record while signaling the reversal. Sweeping BD-193 records is out of the user's stated S1 scope; do not expand it.

### 4.2 P-31a Group G is APPROVED (not surface-to-user)
V2 §10 Group G + §11 OPEN-Q-1 flag the "Frozen forms"→"Archived forms" reword as cosmetic-surface-to-user. The mission prompt + the SEGMENTATION §2.1 place P-31a IN S1 as a fix; this plan treats Group G as approved and applies it in C3. (Pack Chat confirms the approval is live before the C3 coder spawns.)

### 4.3 The active-tree v11.1 clean bar excludes deliberately-retained history
S1's success bar (`grep "v11.1"` clean) applies to the **active in-scope surfaces being de-contaminated** — the validator, the test, the relocated SCHEMA, the v11.0 INDEX/forms, and the active `v11-implementation/` tree after the C5 sweep. It does NOT require zero `v11.1` strings in (a) the swept attempt-records (their v11.1 framing is preserved history at `archive/v11/`), (b) the BD-193 records (retained history with correction notes), or (c) the BD-195 audit docs that quote the mislabel to describe it. Expunging contamination ≠ erasing the historical record OF the contamination. §5 states the exact measurable bar per surface.

### 4.4 V2 / PLAN-V2 / ORDERING-ADDENDUM are NOT swept in S1
The BACKLOG Step-9 line lists `ARCHITECTURE-BD-185-V2.md`, `-ORDERING-ADDENDUM.md`, `PLAN-BD-185-V2.md` among "held BD-185-attempt artifacts." These are the **active design substrate** the BD-185 restart reads (the SEGMENTATION §5.2 finding: V2 §10 Groups A–G ARE the S1 recipes). S1 EDITS them (P-13 normalizes their paths in C1; P-16 adds V2's forward pointer in C4) but does NOT sweep them — sweeping the recipe substrate mid-S1 would remove the very recipes C3 executes. Their own disposition (track/prison/retain-as-restart-input) is the BD-185-restart's first decision (per the BACKLOG Step-9 anchor + the RETAINED-DECISIONS doc), NOT an S1 action. S1 leaves them live, path-corrected, and forward-linked. **This is a scope boundary, surfaced for user confirmation** — if the user wants V2/PLAN-V2/ADDENDUM ALSO swept in S1, that changes C5's file set and removes the C3 recipe source (would require inlining the recipes into this plan first). The plan's recommendation: keep them live through S1; defer their disposition to BD-185 restart.

### 4.5 P-13 sizing correction (vs SEGMENTATION EB-3's "32")
SEGMENTATION EB-3 counted 32 `templates-archive/v11` occurrences (V2=20 + PLAN-V2=12) and framed all as bare paths a coder would trip on. Re-measured at HEAD (EB-A1): V2 has 8 already-full + 12 bare; PLAN-V2 has 11 already-full + 1 bare. The §10 recipe STEPS in V2 (Groups A–C, L846–886) are already full-path; PLAN-V2 §6 recipe steps are already normalized. P-13's real residue is 12 V2 prose/D-4 lines + 1 PLAN-V2 line = **13 bare lines**, not 32 broken recipe steps. P-13 is still the OQ-8 precondition (a coder reading V2 §2/§3 prose could still mis-resolve), but it is a smaller, prose-level normalization. This does not change the ordering (P-13 still lands first); it right-sizes the commit.

---

## 5. Per-commit verification plan + the whole-S1 completion bar

### 5.1 Per-commit gates

| Commit | `validate-pack.py` | per-check tests | manifest regen | `grep "v11.1"`-clean target | destructive gate |
|---|---|---|---|---|---|
| C1 | PASS | — | no | 0 bare `templates-archive/v11` (prefix-less) in V2 + PLAN-V2 | — |
| C2 | PASS | `test-issue-forms.sh`, `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-43.sh` all PASS | **YES** (scripts/) | 0 in `validate-pack.py` + `test-issue-forms.sh` | — |
| C3 | PASS (6-type loop finds `phase-part-v11.0/SCHEMA.md`) | same three PASS | **YES** (scripts/) | 0 in `validate-pack.py`, relocated SCHEMA, `v11.0/INDEX.md`; `v11.1/` dir gone | **`git rm` of v11.1/ → user approval** |
| C4 | PASS | — | no | V2 carries the ORDERING-ADDENDUM forward link (≥1 ref) | — |
| C5 | PASS | — | no | 8 attempt-records no longer in `v11-implementation/`; present in `archive/v11/` | **`git mv` (Pack-Chat, user-approved)** |

### 5.2 The whole-S1 completion bar (de-contamination COMPLETE)

S1 is complete when ALL of the following hold at the post-C5 HEAD:

1. `grep -c "v11.1" scripts/validate-pack.py` = **0** and `grep -c "v11.1" scripts/tests/test-issue-forms.sh` = **0** (P-01).
2. `find maintenance-docs/v11-research/templates-archive/v11.1 -type f` returns **empty** (the directory is gone); `grep -rl "v11.1" maintenance-docs/v11-research/templates-archive/v11.0/` returns **empty** (the relocated SCHEMA + INDEX + form carry only `v11.0` tags) (P-02).
3. `check_template_archive_v11()` iterates **6** entry types incl. `phase-part`, and `python3 scripts/validate-pack.py` PASSES with the phase-part subdir verified (P-12).
4. `PACK-REVIEW-BD-193-PHASE-4.md` §3.1.2 + `IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` §4 S-1 carry a dated REVERSAL/SUPERSEDED note; the BD-195 missed-finding ledger records the propagation (P-08).
5. `v11.0/INDEX.md` reads "Archived forms" + "BD-193 bug-fix carve-out" (no "Frozen"/bare-D16), carve-out fact intact (P-31a).
6. `ARCHITECTURE-BD-185-V2.md` carries the forward ORDERING-ADDENDUM supersession pointer (P-16); `ARCHITECTURE-V3.3-DELTA.md` D-22/D-4-V2 + `AUDIT-INVENTORY-BD-TD-PATH.md` D16-wrapper carry the BD-193-overtaken / mutable-archive correction (P-31k, P-31b).
7. The 8 BD-185 attempt-records are at `maintenance-docs/archive/v11/`, absent from the active `v11-implementation/` tree; `pack-ops/BACKLOG.md` Step-9 path prose reconciled (P-09/P-17/P-18).
8. `python3 scripts/validate-pack.py` is GREEN; `test-fixtures/manifest.txt` regenerated on the two scripts-touching commits (C2, C3).
9. No bare `templates-archive/v11` (prefix-less) recipe path remains in V2/PLAN-V2 (P-13).

**Residual `v11.1` strings that are EXPECTED to remain (not failures):** the swept attempt-records (history at `archive/v11/`), the BD-193 records (history + correction note), the BD-195 audit/segmentation docs (they quote the mislabel to describe it), and V2/PLAN-V2's own remaining v11.1 framing prose (NOT swept in S1; their disposition is the BD-185-restart's call — §4.4). The clean bar is "the contamination is expunged from the surfaces that ENCODE active state," not "the word v11.1 appears nowhere."

---

## 6. Open risks and unknowns

- **R1 — V2/PLAN-V2/ADDENDUM disposition boundary (§4.4).** This plan keeps the BD-185 design substrate live through S1 (it IS the recipe source). If the user wants those three docs swept in S1, C5's set grows and C3 loses its recipe source — surface for confirmation before C3 spawns. *Recommendation: keep live; defer to BD-185 restart.*
- **R2 — P-08 in-place reversal vs sweep.** BD-193 records are edited-in-place (correction note) because they are out of the BD-185 sweep set (§4.1). If the user prefers BD-193 records also swept, that is a scope expansion beyond the stated OQ-1/OQ-3 decision — confirm. *Recommendation: in-place correction note.*
- **R3 — P-13 right-sized to 13 bare lines, not 32 (§4.5).** The SEGMENTATION's "32" conflated full-path refs with bare ones. If a reviewer expects 32 edits, the smaller count is correct and intentional — the §10/§6 recipe STEPS were already full-path. Low risk; documented via EB-A1.
- **R4 — C3 is a large lock-step commit (4 problems, deletion + scripts + 2 BD-193 doc edits).** It bundles a BLOCKER, the 6th-type, the blessing-reversal, and the reword. This is unavoidable: retiring `v11.1/INDEX.md` (P-02) and reversing the verdict that blessed it (P-08) and adding the validator type that the relocated SCHEMA enables (P-12) are one atomic state change (leaving any out leaves the tree internally inconsistent). The bounded review/fix cycle applies; if the reviewer flags it as too large, the architect-escalation path (split P-08's doc edits into a sibling commit) is available — but the P-02/P-12/P-31a archive+validator triple must stay atomic.
- **R5 — Manifest diff may be empty on C2/C3.** The manifest-regen rule stages `manifest.txt` only when the rebuild diff is non-empty. Comment-only edits (C2) may produce no manifest change; the coder runs the rebuild regardless and stages only if non-empty (per the rule's "when the manifest diff is non-empty" clause).
- **R6 — Byte-compare INFO drift on C3.** After Group C updates the v11.0 archive form to 4 options, `check_template_archive_v11()`'s byte-compare against the live project-template form should match (both 4-option). If they drift (e.g., a stray trailing newline), the check reports INFO (not FAIL) — verify the archive form is byte-equal to `project-template/.github/ISSUE_TEMPLATE/work-item.yml` at C3 (EB-A4 confirms the v11.1 duplicate is already byte-identical to live, so copying its content achieves byte-equality).
- **No `MAINTAINER CHECK NEEDED` items.** Every state question in this plan was resolved by read-only measurement at HEAD (the EB blocks). The only items routed to the user are the two scope-boundary confirmations (R1, R2), which are genuine scope decisions, not state queries.

---

## 7. Empirical-Evidence Blocks

All measurements 2026-05-31 at HEAD `71f31d5228a17e0c8ea9de275f4e6630f642e92e` (`71f31d5`), branch `v11-dev`.

**EB-A1 — P-13 bare-path residue is 13 lines (not 32).**
- *Command:* `grep -c "templates-archive/v11" <doc>` minus `grep -c "v11-research/templates-archive/v11" <doc>`; bare lines enumerated via `grep -n "templates-archive/v11" <doc> | grep -v "v11-research/templates-archive"`.
- *Output:* V2: 20 total − 8 full = 12 bare (L102,103,104,234,259,261,274,275,286,298,320,933). PLAN-V2: 12 total − 11 full = 1 bare (L137). Total bare = 13. V2 §10 Group A–C recipe steps (L846–886) are already FULL-path.
- *Interpretation:* P-13 normalizes 13 prose-level bare refs; the recipe STEPS are already correct. Still the OQ-8 precondition (V2 §2/§3 prose), right-sized.
- *Conclusion:* SUPPORTED.

**EB-A2 — All 8 BD-185 attempt-records are TRACKED; `archive/v11/` is a tracked dir.**
- *Command:* `git ls-files --error-unmatch` per file; `git ls-files maintenance-docs/archive/v11/ | head`.
- *Output:* All 8 (PACK-REVIEW-BD-185-H.1/H.2 + 6 IMPLEMENTATION-REPORT-BD-185-*) return TRACKED. `archive/v11/` holds tracked v10-corpus files.
- *Interpretation:* C5 sweep is `git mv`-class (Pack-Chat-executed, user-approved); target dir exists and is tracked. P-09's H.2 confirmed tracked at `3bef42b` (matches OQ-3 prompt).
- *Conclusion:* SUPPORTED.

**EB-A3 — P-02 SCHEMA carries 9 `v11.1` version-tag hits; relocation target is the SOLE live grammar home.**
- *Command:* `grep -n "phase-part-v11.1\|template_version\|template:phase-part" .../v11.1/phase-part-v11.1/SCHEMA.md`; `wc -l`.
- *Output:* 9 hits at L1,4,43,49,63,69,117,187,217; 224-line file. No other `phase-part` SCHEMA exists in the tree.
- *Interpretation:* Group A relocates + retags 9 lines, grammar verbatim. Zero code-consumer blast radius (no script reads the path — RECONCILED P-02).
- *Conclusion:* SUPPORTED.

**EB-A4 — Group C: v11.0 archive form is 3-option; live + v11.1-duplicate are 4-option.**
- *Command:* `diff -q <archive-v11.0-form> <live-project-template-form>` → DIFFER (45-line diff); `diff -q <v11.1-duplicate> <live>` → IDENTICAL; option blocks inspected.
- *Output:* v11.0 archive = {td, phase-epic-skeleton, phase-task-skeleton} (3). Live + v11.1-duplicate = +phase-part-skeleton, +wi-part-letter (4). Both carry `work-item-v11.0` markers.
- *Interpretation:* Group C updates the v11.0 archive form to the 4-option live shape (source content = the v11.1 duplicate, already byte-identical to live), then retires the v11.1 duplicate. The byte-compare in `check_template_archive_v11()` (INFO) then matches.
- *Conclusion:* SUPPORTED.

**EB-A5 — P-16: V2 has ZERO forward ORDERING-ADDENDUM pointer; ADDENDUM has the backward one.**
- *Command:* `grep -c "ORDERING-ADDENDUM" ARCHITECTURE-BD-185-V2.md`; `grep -n "ARCHITECTURE-BD-185-V2" .../ORDERING-ADDENDUM.md | head`.
- *Output:* V2 = 0; ADDENDUM L3/L10 reference V2 (backward link only). V2 L3 "Status: Authoritative. Standalone."
- *Interpretation:* The supersession is one-directional; P-16 adds V2's forward pointer. V2 stays live through S1 (§4.4).
- *Conclusion:* SUPPORTED.

**EB-A6 — CI is GREEN at HEAD (working-state baseline).**
- *Command:* `python3 scripts/validate-pack.py; echo exit=$?`.
- *Output:* `exit=0`; "PASSED — all checks clean".
- *Interpretation:* Both BLOCKERs are comment/archive-only (CI green today, per SEGMENTATION §4.1 L-CONTAM). Every S1 commit must keep this green; the per-commit gates (§5.1) enforce it.
- *Conclusion:* SUPPORTED.

**EB-A7 — C5 inbound refs are audit-subject attributions, not broken live cross-links.**
- *Command:* `grep -rln "<8 filenames>" --include="*.md" . | grep -v .git | grep -v /prison/`.
- *Output:* Referrers = the 8 records themselves + BD-195 audit/research docs (RECONCILED, REFRESH, SUPERSEDED-MAP, RETAINED-DECISIONS, LANDSCAPE-STATE, R7-PREREAD, SEGMENTATION, RESCOPE, R7-epicenter, PLAN-BD-195-INVESTIGATION) + `pack-ops/BACKLOG.md`.
- *Interpretation:* No client-shipped or load-bearing live design cross-link breaks. Audit docs name the records as subjects (refs survive the move). Only BACKLOG (PM-only, Pack-Chat-reconciled) carries a hard path. §3.5 repair table.
- *Conclusion:* SUPPORTED.

**EB-A8 — P-08 surfaces are BD-193 records, distinct from the BD-185 sweep set.**
- *Command:* file existence + `grep -c v11.1` + tracked check on PACK-REVIEW-BD-193-PHASE-4.md / IMPLEMENTATION-REPORT-BD-193-PHASE-5.md.
- *Output:* Both present, tracked; 21 + 14 v11.1 hits; "CONFIRMED-CORRECT" at PHASE-4 L93/95, "v11.1 archive cut" S-1 at PHASE-5 L141/146.
- *Interpretation:* These are BD-193 (not BD-185) records → out of the OQ-1/OQ-3 sweep scope → edited-in-place with a correction note (§4.1), not swept.
- *Conclusion:* SUPPORTED.

---

## 8. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| Architect/planner state-claims require Empirical-Evidence Blocks | §7 EB-A1…EB-A8 back every load-bearing claim with command + verbatim output + HEAD `71f31d5` + date 2026-05-31 + interpretation + SUPPORTED. P-13 sizing (EB-A1), tracked-status (EB-A2), SCHEMA tags (EB-A3), form options (EB-A4), P-16 pointer absence (EB-A5), CI baseline (EB-A6), inbound refs (EB-A7), P-08 distinctness (EB-A8) all measured, not assumed from the recipe docs. | COMPLIANT |
| Complete coverage of S1's 12 problems | §1 maps all 12 (P-01,P-02,P-08,P-09,P-12,P-13,P-16,P-17,P-18,P-31a,P-31b,P-31k) to commits C1–C5; none dropped; both BLOCKERs (P-01→C2, P-02→C3) placed. | COMPLIANT |
| Dependency-correct sequencing | §2 honors P-13→P-02 (C1 before C3) and the P-02↔P-08↔P-12↔P-31a lock-step (all in C3). Full intra-S1 graph in §2.1–§2.3. | COMPLIANT |
| De-contamination must be COMPLETE | §5.2 enumerates the 9-point completion bar (`grep "v11.1"` clean per active surface) + §5.2's explicit "expected-residual" list (history is not erased). Every in-scope surface enumerated so the coder leaves no active mislabel. | COMPLIANT |
| Pattern-matching anti-pattern / no-solutions-bias | Recipes adapted from V2 §10 / PLAN-V2 §6 and RE-VERIFIED against HEAD (EB-A1 corrects the "32" to 13; EB-A4 re-measures the form-option delta) — contaminated specifics not transcribed; §4.5 documents the right-sizing. | COMPLIANT |
| Planner output → user review → coder | This plan is a deliverable for user review; §6 surfaces R1/R2 scope-boundary confirmations; per-commit scope/targets/sequence/verification all reviewable. Not auto-approved. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | All tool actions read-only (Read, grep, find, ls, git ls-files/log/rev-parse, python3 read) + the single authorized Write (this plan via append). No `git add/commit/push/tag`; no `rm`/`mv` of any tracked file; C3 deletion + C5 `git mv` are flagged as Pack-Chat/user-approved actions, NOT performed here. | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert issued; proceeded to the single authorized deliverable. | COMPLIANT (N/A trigger) |

**End of PLAN-BD-195-S1.md.**
