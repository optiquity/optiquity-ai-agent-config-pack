# IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS

## §1 — Scope

This implementation report covers the user-approved edits to two BD-185
documents following a Pack Chat decision-review session 2026-05-26 that
resolved all 7 planner POQs and introduced 2 derivative architectural
refinements (D15 + D16).

- **2 architect-doc edits** to `ARCHITECTURE-BD-185.md`:
  - **D15** — Letter-suffix removal + task numbering rule
  - **D16** — Convention Y (v11.0 archive intra-file additive-extension)
- **7 POQ resolutions** applied to `PLAN-BD-185.md`:
  - **POQ-1** — Defer `v11.1/forms/work-item.yml` creation from H.1 to H.2
  - **POQ-2** — `pack-only` keyword for H.1 + H.14
  - **POQ-3** — `pack-only` for scripts/-primary commits (already designated)
  - **POQ-4** — Path 2 extension to admit `Phase-N.Part-x` (no new path)
  - **POQ-5** — NEW `_order-generate.sh` script (replaces toc-regenerate.sh extension)
  - **POQ-6** — Convention Y: H.13 SCHEMA extension + H.14 INDEX forward-reference both land
  - **POQ-7** — Accept 16-commit plan (no PLAN content change)
- **D15 propagation** through PLAN (Mx? regex simplification across §1.4 C-1, §H.6, §H.10)
- **§6 POQs → §6a Decision log** replacement

All edits applied mechanically per user-locked spec. No re-litigation of
locked decisions (D1-D14 from original architect cycle; POQ-1 through
POQ-7 from this review; D15 + D16 from derivative discussion).

---

## §2 — Inputs read

| # | Path | Purpose |
|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | Target file 1 (1220 lines at start; committed at HEAD `062cb8f`) |
| 2 | `maintenance-docs/v11-implementation/PLAN-BD-185.md` | Target file 2 (1468 lines at start; untracked planner output not yet committed) |

**HEAD SHA at start of work:** `062cb8ffe7b21efb7bb0987fac2ea93e0f3382c9`.

**HEAD SHA at IMPL-REPORT write:** `062cb8ffe7b21efb7bb0987fac2ea93e0f3382c9`
(no git state changes; coder runs read-only git verbs only).

---

## §3 — ARCHITECTURE-BD-185.md edits

### D15 edits

#### Edit A — §4.1 Atomic identifiers table — Task row

**Source decision:** D15 — Letter suffix REJECTED grammar-wide; Task-M
integer-only.

**Before:**
```
| Task | `Task-Mx?` where `M` matches `[1-9][0-9]*` and optional suffix `x` matches `[a-z]` | `Task-3`, `Task-3d`, `Task-7` | M is birth-order ordinal per INV-2; the optional letter suffix `x` is a v11.1+ addition for compatible carry-forward (currently no v11.0 tasks use a letter suffix, but the grammar admits it for future flexibility). |
```

**After:**
```
| Task | `Task-M` where `M` matches `[1-9][0-9]*` (integer only; NO letter suffix per D15) | `Task-3`, `Task-7`, `Task-23` | M is birth-order ordinal per INV-2; task numbering is integer-only; new tasks always get next available integer after the last task in the phase. |
```

#### Edit B — §4.1 Composite identifiers table — Task forms

**Source decision:** D15 — Composite forms simplify (`Phase-N.Task-M`
and `Phase-N.Part-x.Task-M`).

**Before:**
```
| With Part | `Phase-N.Part-x.Task-Mx?` | `Phase-1.Part-a.Task-3d`, `Phase-7.Part-b.Task-12` | Used after mid-work split when a task belongs to a specific Part |
| Without Part (null-Part) | `Phase-N.Task-Mx?` | `Phase-2.Task-7`, `Phase-12.Task-3` | DEFAULT for phases without Parts (most phases). Skip the `.Part-X` segment entirely. |
```

**After:**
```
| With Part | `Phase-N.Part-x.Task-M` | `Phase-1.Part-a.Task-3`, `Phase-7.Part-b.Task-12` | Used after mid-work split when a task belongs to a specific Part |
| Without Part (null-Part) | `Phase-N.Task-M` | `Phase-2.Task-7`, `Phase-12.Task-3` | DEFAULT for phases without Parts (most phases). Skip the `.Part-X` segment entirely. |
```

#### Edit C — §4.1 Prohibited forms — add Letter suffix entry

**Source decision:** D15 — Letter suffix REJECTED for tasks.

**Before:**
Three prohibited forms (empty separator, lowercase atoms, numeric Part).

**After:** Added 4th entry:
```
- **Letter suffix on Task** (e.g., `Task-Md`, `Task-3a`): REJECTED per D15. Rationale: task numbers are birth-order ordinals per INV-2; letter suffix as positional indicator contradicts birth-order semantic. Insertion semantic uses dependency edges (`blocked-by` / `blocks`), not letter suffix. New tasks always get next available integer.
```

#### Edit D — NEW §4.1a "Task numbering rule — task number ≠ execution order"

**Source decision:** D15 — Task numbering rule clarified.

**Before:** §4.2 immediately followed §4.1.

**After:** Inserted new §4.1a section between §4.1 and §4.2 with the
verbatim content from the prompt spec:
- Task IDs are birth-order ordinals; M = creation order within phase
- New tasks always get next available integer (Task-13 after Task-12 even
  if Task-3 cancelled)
- **Task number does NOT define execution order**
- Execution order has its own mechanism (per §5)
- Cross-references to task IDs are STRICT

#### Edit E — §4.1 (§8.1 + §10.1) carry-forward propagation

**Source decision:** D15 propagation through §8.1 + §8.5 + §10.1 Check 34.

**Before (§8.1):**
```
| Part identifier grammar chosen | `Phase-N.Part-x.Task-Mx?` (with-Part) / `Phase-N.Task-Mx?` (null-Part) per C-1 user-lock | §4.1 |
```

**After (§8.1):**
```
| Part identifier grammar chosen | `Phase-N.Part-x.Task-M` (with-Part) / `Phase-N.Task-M` (null-Part) per C-1 user-lock; Task-M integer-only per D15 | §4.1 |
```

**Before (§8.5):**
```
| Check 34 (cross-reference integrity) | Extended to admit Part-id form `Phase-N.Part-x` and `Phase-N.Part-x.Task-Mx?` in cross-references AND legacy `phase-N.M` form continues to resolve |
```

**After (§8.5):**
```
| Check 34 (cross-reference integrity) | Extended to admit Part-id form `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` in cross-references AND legacy `phase-N.M` form continues to resolve |
```

**Before (§10.1 Check 34 bullets):**
```
  - `Phase-N.Part-x.Task-Mx?` (Part-scoped task identifier)
  - `Phase-N.Task-Mx?` (null-Part task identifier; v2 form)
```

**After (§10.1 Check 34 bullets):**
```
  - `Phase-N.Part-x.Task-M` (Part-scoped task identifier)
  - `Phase-N.Task-M` (null-Part task identifier; v2 form)
```

#### Edit F — §1.4 Decision log header rewrite

**Source decision:** D15 + D16 added; 14 → 16 decisions; second session
2026-05-26 added.

**Before:**
```
### §1.4 — Decision log (Pack Chat review session 2026-05-25)

All 10 architect POQs were resolved during a Pack Chat review session with the user 2026-05-25. Three additional design decisions emerged from user-driven refinements during the same session, plus INV-7 breach acceptance. The 14 decisions are recorded here as a comprehensive audit trail.
```

**After:**
```
### §1.4 — Decision log (Pack Chat review sessions 2026-05-25 + 2026-05-26)

All 10 architect POQs were resolved during a Pack Chat review session with the user 2026-05-25 (D1–D14). Two additional architectural refinements (D15 + D16) emerged during a subsequent Pack Chat review session 2026-05-26 that resolved the 7 planner POQs (PLAN-BD-185.md §6 → §6a). The 16 decisions are recorded here as a comprehensive audit trail.
```

#### Edit G — §1.4 Decision log table — D15 + D16 rows added

**Source decision:** D15 + D16.

**Before:** Table ended at D14 row.

**After:** Two new rows appended after D14:
```
| D15 | Task letter-suffix removed; task numbering rule clarified | User-driven (2026-05-26 POQ-4 discussion) | Letter suffix REJECTED grammar-wide; Task-M integer-only; new tasks get next integer; task number ≠ execution order; cross-refs strict | §4.1, §4.1a (NEW), §4.7 |
| D16 | Convention Y: v11.0 archive intra-file additive-extension allowed | User-driven (2026-05-26 POQ-6 discussion) | Structural shape frozen at 5 subdirs; intra-file content may evolve via backward-compatible additive extensions; admits D5 cancelled state addition to phase-task-v11.0/SCHEMA.md + v11.0/INDEX.md forward-reference footnote | §10.1 |
```

Plus footer sentence updated from session 2026-05-25 alone to mention
both sessions (2026-05-25 sessionId preserved; 2026-05-26 referenced as
"planner POQ resolution session").

### D16 edits

#### Edit H — §10.1 `check_template_archive_v11` rewrite

**Source decision:** D16 — Convention Y: structural shape frozen +
intra-file additive extensions allowed.

**Before:**
```
**`check_template_archive_v11`:**
- v11.0 archive frozen at 5 entry-type subdirs (unchanged).
- v11.1 archive cut: ...
```

**After:**
```
**`check_template_archive_v11`:**
- v11.0 archive **structural shape** is frozen at 5 entry-type subdirs (bd / td / phase-epic / phase-task / inbound) — no new directories added in the v11.0 archive after v11.0 ship. **Intra-file content MAY evolve** via backward-compatible additive extensions (e.g., new admitted state values, forward-reference footnotes to v11.1+ evolutions). This matches the pack's existing design philosophy of additive extension (cf. D12 LAZY backfill). BD-185 exercises this convention: `phase-task-v11.0/SCHEMA.md` Section 3 admits new `cancelled` state value (per D5); `v11.0/INDEX.md` may add a forward-reference footnote pointing to v11.1+ archive.
- v11.1 archive cut: ...
```

---

## §4 — PLAN-BD-185.md edits

### POQ-1 — Defer v11.1/forms/work-item.yml creation from H.1 to H.2

#### Edit 1a — H.1 Files modified

**Source POQ:** POQ-1.

**Before:**
```
**Files modified (3 CREATE):**
- ...SCHEMA.md (NEW)
- ...INDEX.md (NEW)
- ...forms/work-item.yml (NEW; byte-identical archive copy of post-H.2 live form — but per §4.3 the archive should be a placeholder until H.2 lands the live form, OR the archive should land WITH the live form in H.2; planner default: archive in H.1 carries the v11.0 baseline + planned-additions documented as inline comments, refreshed byte-identical in H.16 close pass — see POQ-1 in §6)
```

**After:**
```
**Files modified (2 CREATE):**
- ...SCHEMA.md (NEW)
- ...INDEX.md (NEW)

(Per POQ-1 resolution 2026-05-26: v11.1/forms/work-item.yml creation deferred to H.2, where it lands byte-identically with the live form. H.1 creates only SCHEMA + INDEX in the v11.1 archive.)
```

#### Edit 1b — H.1 Edit specification step 3

Updated to point to H.2 for archive forms file creation.

#### Edit 1c — H.1 Success criteria item 3

Updated to confirm v11.1/forms/work-item.yml is NOT created at H.1.

#### Edit 1d — H.1 PREFLIGHT line (3/3 → 2/2)

**Before:** `PREFLIGHT: 3/3 in-scope file edits complete; ...`
**After:** `PREFLIGHT: 2/2 in-scope file edits complete; ...`

#### Edit 1e — H.1 section header

**Before:** `### H.1 — v11.1 templates-archive cut (NEW phase-part-v11.1 + INDEX + forms)`
**After:** `### H.1 — v11.1 templates-archive cut (NEW phase-part-v11.1 + INDEX; forms deferred to H.2 per POQ-1 resolution 2026-05-26)`

#### Edit 1f — H.2 Files modified

**Before:**
```
**Files modified (2 EXTEND):**
- .github/ISSUE_TEMPLATE/work-item.yml (pack-root)
- project-template/.github/ISSUE_TEMPLATE/work-item.yml (client mirror; byte-identical to pack-root per existing convention)
```

**After:**
```
**Files modified (2 EXTEND + 1 CREATE):**
- .github/ISSUE_TEMPLATE/work-item.yml (pack-root, EXTEND)
- project-template/.github/ISSUE_TEMPLATE/work-item.yml (client mirror, EXTEND; byte-identical to pack-root per existing convention)
- maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml (NEW; byte-identical to live form post-H.2 edits per POQ-1 resolution 2026-05-26 — archive created here, not at H.1)
```

#### Edit 1g — H.2 Edit specification step 6 (NEW)

Added new step: "Create archive copy at maintenance-docs/v11-research/
templates-archive/v11.1/forms/work-item.yml byte-identical to the live
forms emitted in steps 1-5 (per POQ-1 resolution 2026-05-26 — eliminates
H.16-refresh placeholder pattern)."

#### Edit 1h — H.2 Verification commands

Added `diff project-template/.github/ISSUE_TEMPLATE/work-item.yml
maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
expected empty (byte-identical from creation per POQ-1).

#### Edit 1i — H.2 Success criteria + PREFLIGHT (2/2 → 3/3)

Success criteria items 4-5 updated to include v11.1 archive copy.
PREFLIGHT updated to `3/3 in-scope file edits complete`.

### POQ-2 — `pack-only` keyword for H.1 + H.14

#### Edit 2a — H.1 Commit subject scope keyword

**Before:**
```
**Commit subject scope keyword:** (no keyword). The commit touches only `maintenance-docs/` ...
**Commit message:** `feat: v11 — BD-185 v11.1 templates-archive cut (phase-part-v11.1 schema + INDEX + forms) (Batch 19d.1)`
```

**After:**
```
**Commit subject scope keyword:** `pack-only`. Per POQ-2 resolution 2026-05-26: `maintenance-docs/`-only commit; the `pack-only` keyword's deny-list (project-template/ + supporting-docs/) does not trip; precedent: commits `3a8b5ba` + `062cb8f` used `pack-only` for maintenance-docs/-only commits and CI passed.
**Commit message:** `feat: v11 — BD-185 v11.1 templates-archive cut (phase-part-v11.1 schema + INDEX) (Batch 19d.1) (pack-only)`
```

#### Edit 2b — H.14 Commit subject scope keyword

**Before:**
```
**Commit subject scope keyword:** (no keyword — maintenance-docs/ only; outside the CI Check 36 scope vocabulary; same condition as H.1 per POQ-2 in §6).
**Commit message:** `feat: v11 — BD-185 templates-archive cross-references (v11.0 ↔ v11.1) (Batch 19d.14)`
```

**After:**
```
**Commit subject scope keyword:** `pack-only`. Per POQ-2 resolution 2026-05-26: `maintenance-docs/`-only commit; `pack-only` keyword deny-list (project-template/ + supporting-docs/) does not trip; precedent: commits `3a8b5ba` + `062cb8f` used `pack-only` for maintenance-docs/-only commits and CI passed.
**Commit message:** `feat: v11 — BD-185 templates-archive cross-references (v11.0 ↔ v11.1) (Batch 19d.14) (pack-only)`
```

#### Edit 2c — §4 per-commit summary table H.1 + H.14 scope-keyword columns

Updated both rows to `pack-only` keyword + revised commit messages.

### POQ-3 — `pack-only` for scripts/-primary commits (clarification added)

#### Edit 3a — §3 "How to use this plan" item 5 — new note added

**Source POQ:** POQ-3.

**Before:** §3 item 5 stopped at "...exclusive scope keyword."

**After:** Added note paragraph below item 5:
"Note on `scripts/-primary` (per POQ-3 resolution 2026-05-26):
`scripts/-primary` in this PLAN refers to pack-root `/scripts/` only
(NOT `/project-template/scripts/`). The `pack-only` scope-keyword's
deny-list (project-template/ + supporting-docs/) actively guardrails
this separation — any accidental touch of `/project-template/scripts/`
would fail CI Check 36 under a `pack-only` claim, surfacing the
boundary violation at gate time."

No PLAN content change beyond this clarification (planner default for
H.4 / H.5 / H.6 / H.7 / H.8 / H.9 / H.10 / H.15 keyword stands).

### POQ-4 — Path 2 extension to admit `Phase-N.Part-x` (no new path)

#### Edit 4a — H.6 Files modified — tracker-promote.sh annotation

**Source POQ:** POQ-4.

**Before:**
```
- `scripts/lib/tracker-promote.sh` (admit `--to=Phase-N.Part-x` form if architect adds third promotion path; planner default: do NOT add Path 3 — INV-6 LOCKED; surface as POQ-4 if architect intent unclear)
```

**After:**
```
- `scripts/lib/tracker-promote.sh` (per POQ-4 resolution 2026-05-26: EXTEND existing Path 2 target-identifier grammar to admit `Phase-N.Part-x` form; NO new path introduced; INV-6 (Path 3 `--fold-into`) remains FORBIDDEN; NO `pack td promote --to=Phase-N.Part-x.Task-M` (task targets) admitted)
```

#### Edit 4b — H.6 Edit specification step 7

**Before:**
```
7. **`tracker-promote.sh`:** Planner default — do NOT add Path 3 (`--to=Phase-N.Part-x`). INV-6 (Path 3 forbidden) is LOCKED per C-4. Surface as POQ-4 in §6 if architect's "EXTEND" annotation in §14.2 implies a different intent.
```

**After:**
```
7. **`tracker-promote.sh`:** Per POQ-4 resolution 2026-05-26: EXTEND existing Path 2 (`pack bd promote --to=Phase-N`) target-identifier grammar to admit `Phase-N.Part-x` form. NO new path is introduced. Path 3 (`--fold-into`) remains FORBIDDEN per INV-6 / C-4. The Path 2 extension admits Part epic targets (`Phase-N.Part-x`) but NOT task targets (`Phase-N.Part-x.Task-M`) — task-level promotion would conflict with phase-task immutability invariants per INV-2.
```

#### Edit 4c — H.6 Success criteria #2

**Before:**
```
2. tracker-promote.sh unchanged (planner default; POQ-4 if architect intent diverges).
```

**After:**
```
2. tracker-promote.sh Path 2 extended to admit `Phase-N.Part-x` target (per POQ-4 resolution 2026-05-26); Path 3 still FORBIDDEN; task targets NOT admitted.
```

#### Edit 4d — H.6 Edit specification step 1 — D15 propagation

**Before:**
```
1. **`tracker-phase-task.sh`:** ... Admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-Mx?` in cross-reference resolution.
```

**After:**
```
1. **`tracker-phase-task.sh`:** ... Admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` in cross-reference resolution (Task-M integer-only per D15).
```

### POQ-5 — NEW `_order-generate.sh` script

#### Edit 5a — H.7 Files modified

**Source POQ:** POQ-5.

**Before:**
```
**Files modified (~3 EXTEND):**
- `scripts/lib/per-entry/_lib.sh` (new sort key extractor for ...)
- `scripts/lib/per-entry/mirror-generate.sh` (sort entries by new key; emit ...)
- `scripts/lib/per-entry/toc-regenerate.sh` (optional extension per D7 planner discretion; planner default: extend `_toc.md` to ALSO write `_order.md` as a sibling — see POQ-5 in §6)
```

**After:**
```
**Files modified (2 EXTEND + 2 CREATE):**
- `scripts/lib/per-entry/_lib.sh` (EXTEND; new sort key extractor for `project-implementation-plan` stream)
- `scripts/lib/per-entry/mirror-generate.sh` (EXTEND; sort entries by new key; emit `<!-- execution-order: NNN -->` in mirror per architect §5.3; orchestrates calls to BOTH `toc-regenerate.sh` (for `_toc.md`) AND `_order-generate.sh` (for `_order.md`))
- `scripts/lib/per-entry/_order-generate.sh` (NEW; parallel to `toc-regenerate.sh`; single-responsibility per file; emits `_order.md` SSOT-derived view per D7 + POQ-5 resolution 2026-05-26)
- `scripts/tests/test-_order-generate.sh` (NEW; parallel to existing per-entry test fixtures)
```

#### Edit 5b — H.7 Edit specification step 3 + new step 4

**Before:**
```
3. **`toc-regenerate.sh`:** Per D7 ... Two planner-discretion paths:
   - **(a)** Extend `toc-regenerate.sh` to also emit `_order.md` (sibling to `_toc.md`) — the SSOT-derived view file.
   - **(b)** Create a separate `_order-generate.sh` script ...
   - Planner default: **(a)** to minimize new script count; see POQ-5 in §6 if architect's "EXTEND" annotation implies (b).
```

**After:**
```
3. **`_order-generate.sh` (NEW):** Per POQ-5 resolution 2026-05-26 — create a new `scripts/lib/per-entry/_order-generate.sh` script parallel to `toc-regenerate.sh` (single-responsibility per file; matches existing per-entry script pattern per original architect POQ-7 review). `mirror-generate.sh` orchestrates calls to BOTH `toc-regenerate.sh` (for `_toc.md`) AND `_order-generate.sh` (for `_order.md`). Shared logic (entry walk, regex helpers) lives in existing `_lib.sh`.
4. **`scripts/tests/test-_order-generate.sh` (NEW):** Parallel to existing per-entry test fixtures; exercises the new script.
```

#### Edit 5c — H.7 PREFLIGHT line (3/3 → 4/4) + success criteria

PREFLIGHT updated to `4/4 in-scope file edits complete`. Success criteria
expanded from 6 → 9 items including filename uniqueness preservation.

#### Edit 5d — H.7 section header

**Before:** `### H.7 — Per-entry sort key + mirror-generate + ` _order.md ` SSOT-derived view (D7)`
**After:** `### H.7 — Per-entry sort key + mirror-generate + NEW ` _order-generate.sh ` + ` _order.md ` SSOT-derived view (D7 + POQ-5)`

#### Edit 5e — §4 per-commit summary table H.7

Updated H.7 row file list to include new script + test; commit message
adds `_order-generate.sh` mention.

### POQ-6 — Convention Y: H.13 SCHEMA extension + H.14 INDEX forward-reference both land

#### Edit 6a — H.14 Files modified

**Source POQ:** POQ-6 + D16.

**Before:**
```
**Files modified (~1-2 EXTEND):**
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (refresh cross-references if H.1 carried placeholders)
- `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` (forward-reference to v11.1 if not yet present at HEAD; verify needed at impl time per D6)
```

**After:**
```
**Files modified (2 EXTEND):**
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (EXTEND; finalize cross-references)
- `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` (EXTEND; add forward-reference footnote per POQ-6 resolution 2026-05-26 + D16 Convention Y)
```

#### Edit 6b — H.14 Edit specification

Rewrote step 2 to specify the verbatim forward-reference footnote text
per the prompt spec, citing D16 Convention Y as the architectural
permission.

#### Edit 6c — H.14 Verification commands

Updated to include `grep -nE "v11.1|phase-part-v11.1|D16|Convention Y"
v11.0/INDEX.md` verification of footnote presence; updated forms diff
commentary to note "already so from H.2 per POQ-1; no H.14-refresh needed."

#### Edit 6d — H.14 Per-commit reviewer scope

Added two bullets:
- v11.0/INDEX.md forward-reference footnote correctness
- v11.0 archive directory structure unchanged (per D16 Convention Y;
  intra-file content extensions in H.13 + H.14 permitted)

#### Edit 6e — H.14 Success criteria

Expanded from 4 → 5 items with new item 3:
"v11.0/INDEX.md carries forward-reference footnote naming v11.1 archive
+ phase-part-v11.1 + D5 cancelled state + D16 Convention Y (per POQ-6
resolution 2026-05-26)."

#### Edit 6f — H.13 reviewer scope — Convention Y reframe

**Before:** Reviewer scope bullet read "v11.0 SCHEMA cancelled-state
extension does NOT break v11.0 archive frozen invariant. Per architect
§10.1 'v11.0 archive frozen at 5 entry-types (unchanged)' — extending
a SCHEMA file within v11.0 archive is an SchemA file content change,
not a directory layout change."

**After:** Updated to reference D16 Convention Y as the architectural
permission for the intra-file additive change.

#### Edit 6g — §4 per-commit summary table H.14

Updated scope summary + file list + commit msg to reflect POQ-6 + D16.

### POQ-7 — Accept 16-commit plan (no PLAN content change)

#### Edit 7a — No content changes

Per POQ-7 resolution, planner default stands; no §3 / §4 / §5 PLAN
content edits beyond what other POQ resolutions changed. Captured in
§6a Decision log as "ACCEPTED planner default."

### D15 propagation through PLAN

#### Edit D15-prop-a — §1.4 C-1 restatement

**Before:**
```
- **C-1.** Part-id grammar: composite `Phase-N.Part-x.Task-Mx?` (with-Part) / `Phase-N.Task-Mx?` (null-Part); empty separator `Phase-N..Task-M` prohibited.
```

**After:**
```
- **C-1.** Part-id grammar (refined by D15 2026-05-26): composite `Phase-N.Part-x.Task-M` (with-Part) / `Phase-N.Task-M` (null-Part); empty separator `Phase-N..Task-M` prohibited; Task-M integer-only (no letter suffix per D15).
```

#### Edit D15-prop-b — §1.3 14 → 16 decisions

Updated §1.3 header from "14" → "16" and appended D15 + D16 rows to the
locked-decisions table.

#### Edit D15-prop-c — H.10 Check 34 bullets

**Before:**
```
   - `Phase-N.Part-x.Task-Mx?` (Part-scoped task)
   - `Phase-N.Task-Mx?` (null-Part task v2)
```

**After:**
```
   - `Phase-N.Part-x.Task-M` (Part-scoped task; Task-M integer-only per D15)
   - `Phase-N.Task-M` (null-Part task v2; Task-M integer-only per D15)
```

#### Edit D15-prop-d — H.10 check_template_archive_v11 — D16 reference

Updated language to reference D16 Convention Y for the v11.0 archive
SCHEMA + INDEX extensions.

### §6 POQs section replacement + §6a Decision log

#### Edit POQ-replace — §6 → "ALL RESOLVED 2026-05-26"

**Before:** 7 POQ-N sub-sections enumerating each tension (POQ-1
through POQ-7) for Pack Chat triage.

**After (verbatim per prompt spec):**
```
## §6 — Planner observations (POQs) — ALL RESOLVED 2026-05-26

All 7 planner POQs were resolved during a Pack Chat decision-review
session 2026-05-26. Two derivative architectural refinements (D15 +
D16) emerged from the discussion. See §6a Decision log below for the
full audit trail. The original POQ table is preserved in git history
(planner's first emission at 'planner-pass complete') for audit
purposes.
```

#### Edit POQ-6a — NEW §6a Decision log

Added §6a "Decision log (Pack Chat review session 2026-05-26)" with
9-row table verbatim per prompt spec (POQ-1 through POQ-7 + D15 + D16,
each with source / resolution / PLAN impact columns), followed by:
"All decisions are USER-LOCKED. No re-litigation in downstream commits."

---

## §5 — §6a Decision log confirmation

The §6a Decision log captures all 7 POQ + D15 + D16 with the full table
required by the prompt spec:

| # | Decision | Source | Resolution | PLAN impact |
|---|---|---|---|---|
| POQ-1 | v11.1/forms/work-item.yml creation site | Planner POQ-1 | DEFERRED to H.2 (byte-identical from creation) | H.1 file count -1; H.2 file count +1 |
| POQ-2 | Scope keyword for maintenance-docs/-only commits (H.1, H.14) | Planner POQ-2 | `pack-only` keyword (precedent: 3a8b5ba, 062cb8f) | H.1 + H.14 commit subjects gain (pack-only) |
| POQ-3 | `pack-only` for scripts/-primary commits | Planner POQ-3 | CONFIRMED planner default; also guardrails project-template/scripts/ touches | Clarification added to §5 |
| POQ-4 | `tracker-promote.sh` Path 2 extension | Planner POQ-4 | Extend Path 2 to admit `Phase-N.Part-x` target; NO new path; INV-6 preserved | H.6 edit specification refined |
| POQ-5 | `_order.md` emit site | Planner POQ-5 | NEW `_order-generate.sh` script (single-responsibility per file) | H.7 file count +2 (NEW script + test) |
| POQ-6 | v11.0/INDEX.md forward-reference + H.13 SCHEMA tension | Planner POQ-6 | Convention Y: structural shape frozen + intra-file additive extensions allowed; BOTH H.13 SCHEMA extension AND H.14 INDEX forward-reference land | H.14 file count +1; D16 architect-doc edit |
| POQ-7 | 16-commit batch size | Planner POQ-7 | ACCEPTED planner default | No changes |
| D15 | Letter-suffix removal + task numbering rule | User-driven (POQ-4 discussion 2026-05-26) | Task grammar simplifies to `Task-M` integer only; task number ≠ execution order rule documented | Architect doc D15 edits + PLAN regex simplifications |
| D16 | Convention Y for v11.0 archive intra-file additive-extension | User-driven (POQ-6 discussion 2026-05-26) | Structural shape frozen + intra-file additive content allowed | Architect doc D16 edits |

All decisions are USER-LOCKED. No re-litigation in downstream commits.

---

## §6 — Verification

### validate-pack.py run

Command: `python3 scripts/validate-pack.py`

Result: **PASSED — all checks clean** (last line of output). All 43
checks passed:
- Check 32 (mirror in-sync), Check 33 (TOC in-sync), Check 34
  (cross-reference integrity), Check 35 (phase-task lib invariants)
  all PASSED.
- New CI Check 36 (commit-scope honesty), Check 37 (project-side
  pack-only deny-list), Check 38 (pack-only-file siting), Check 39
  (cmd_update mapping/glob symmetry), Check 40 (pack-ops/ bare
  cross-reference scanner), Check 41 (_CLIENT_INSTALLED_FILES
  self-doc list integrity), Check 42 (CI workflow wires all
  per-check test files), Check 43 (project-side bare cross-reference
  scanner) all PASSED.

### Grep verification commands

```
grep -cE "Task-Mx\?|Mx\?" maintenance-docs/v11-implementation/PLAN-BD-185.md
→ 0   (zero stale Mx? regex outside audit-trail)

grep -cE "D15|D16" maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md
→ 7   (D15 + D16 entries in Decision log + body cross-references)

grep -cE "§6a — Decision log|POQ-1.*RESOLVED|RESOLVED 2026-05-26" \
     maintenance-docs/v11-implementation/PLAN-BD-185.md
→ 2   (§6 RESOLVED header + §6a Decision log header)

grep -nE "H.1 — v11.1 templates-archive|H.2 — Form-family|H.7 — Per-entry|H.14 — Templates-archive" \
     maintenance-docs/v11-implementation/PLAN-BD-185.md
→ 4 matches; H.1 + H.7 section headers updated to reflect POQ-1 + POQ-5 changes
```

All verification commands match the expected outcomes from the prompt spec.

### `letter suffix` grep result

```
grep -nE "Task-Mx\?|Mx\?|letter suffix" \
     maintenance-docs/v11-implementation/PLAN-BD-185.md
```

Returns one line at the C-1 restatement:
```
61: - **C-1.** Part-id grammar (refined by D15 2026-05-26): composite ...; Task-M integer-only (no letter suffix per D15).
```

This is the audit-trail mention of D15 itself (acceptable per the
prompt spec: "Expected: zero or only one match if a historical/
audit-trail mention is kept").

### git status verification

```
git status --short
→  M maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md
→ ?? maintenance-docs/v11-implementation/PLAN-BD-185.md
```

Only the two intended files. No source code changed. No files outside
`maintenance-docs/v11-implementation/` modified.

### HEAD unchanged

```
git rev-parse HEAD
→ 062cb8ffe7b21efb7bb0987fac2ea93e0f3382c9
```

HEAD remains at `062cb8f` (BD-185 architect cycle commit). Coder ran
no state-changing git verbs.

---

## §7 — Cross-references

- **Pack Chat decision-review session 2026-05-26** — resolved all 7
  planner POQs and introduced D15 + D16 derivative refinements.
- **sessionId reference:** previous session 2026-05-25 (sessionId
  `f6d6104f-9268-42ff-90cf-ac8ae35433e3`) resolved D1-D14 + INV-7
  breach; this 2026-05-26 session is the planner-POQ-resolution
  session and lives in the user's pack memory cache per
  `feedback_user_prescriptive_authority` + `feedback_triage_workflow_protocol`.
- **HEAD context:** `062cb8f` — BD-185 architect cycle commit (includes
  ARCHITECTURE-BD-185.md original D1-D14 decision log; PLAN-BD-185.md
  was untracked at this HEAD, this commit lands its first committed state).
- **Pack memory entries informing the work:**
  - `feedback_user_prescriptive_authority` (user-locked decisions are
    architect constraints downstream)
  - `feedback_planner_user_review_before_coder` (planner POQs surface
    to user before pack-coder spawn; this work IS the user-review
    application)
  - `feedback_no_solutions_in_agent_prompts` (coder reads architect
    + plan; applies edits mechanically; does not re-design)
  - `feedback_agents_never_commit` (no state-changing git verbs)
  - `feedback_filename_uniqueness` (new `_order-generate.sh` confirmed
    unique by file name structure; parallels existing `toc-regenerate.sh`)
- **Architect cross-references:**
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §1.4
    Decision log (now 16 decisions)
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §4.1
    + new §4.1a (D15)
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §10.1
    (D16 Convention Y)
- **Plan cross-references:**
  - `maintenance-docs/v11-implementation/PLAN-BD-185.md` §1.3 (now 16
    decisions including D15 + D16)
  - `maintenance-docs/v11-implementation/PLAN-BD-185.md` §6a Decision
    log (new section)

---

## §8 — Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | All D15 ARCHITECTURE edits applied (§4.1 task grammar + new §4.1a task numbering rule + §4.7 cleanups + §1.4 Decision log D15 row) | **PASS** |
| 2 | All D16 ARCHITECTURE edits applied (§10.1 rewrite + §1.4 Decision log D16 row) | **PASS** |
| 3 | All POQ-1 through POQ-7 PLAN edits applied per spec | **PASS** |
| 4 | §6 POQs section replaced with RESOLVED reference; §6a Decision log added | **PASS** |
| 5 | D15 propagation through PLAN complete (no stale `Mx?` regex outside audit-trail) | **PASS** (zero `Mx?` hits) |
| 6 | validate-pack.py PASS | **PASS** (all 43 checks clean) |
| 7 | No source code changed | **PASS** (only `maintenance-docs/v11-implementation/` touched) |
| 8 | IMPL-REPORT written | **PASS** (this file) |
| 9 | PREFLIGHT line emitted before IMPL-REPORT write | **PASS** |
| 10 | No state-changing git verbs run | **PASS** (HEAD unchanged at `062cb8f`) |

All 10 success criteria PASS.

---

## §9 — Files touched inventory

| Path | Change type | Description |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | MODIFIED | D15 + D16 edits: §1.4 Decision log (14 → 16 rows + intro rewrite); §4.1 Task atom + Composite forms + Prohibited forms; new §4.1a Task numbering rule; §8.1 + §8.5 carry-forward; §10.1 `check_template_archive_v11` rewrite |
| `maintenance-docs/v11-implementation/PLAN-BD-185.md` | MODIFIED | POQ-1 through POQ-7 resolutions: §1.3 14 → 16 decisions; §1.4 C-1 restatement (D15); §3 step 5 POQ-3 clarification; §4 per-commit summary table H.1 + H.2 + H.7 + H.14 rows; §5 H.1 (POQ-1 + POQ-2), H.2 (POQ-1), H.6 (POQ-4 + D15), H.7 (POQ-5), H.10 (D15 + D16), H.13 (D16 framing), H.14 (POQ-6 + POQ-2); §6 → "ALL RESOLVED" header; new §6a Decision log |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md` | NEW | This IMPL-REPORT (markdown only; 1 chunk via Write) |

Total files touched: **3** (1 modified + 1 modified-untracked + 1 new).

---

## End of IMPL-REPORT

This report follows the IMPL-REPORT chunking discipline — produced as
a single Write call under ~600 lines including verbatim before/after
quotes. No Edit-append needed. PREFLIGHT line was emitted prior to
this Write per `feedback_pack_coder_preflight_pattern` memory pointer.

Pack Chat next-steps:
1. Read this IMPL-REPORT (§3 + §4 + §6 sufficient for triage)
2. Triage: zero deviations from prompt spec; default fix-all not
   needed; no findings raised
3. Stage `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`
   (modified), `maintenance-docs/v11-implementation/PLAN-BD-185.md`
   (new), and `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md`
   (new) for commit
4. Compose commit message per CLAUDE.md commit-message-format rules
   (suggest: `docs: v11 — BD-185 architect-doc D15+D16 + plan
   POQ-1..7 resolutions (pack-only)`)
5. User approval → commit
