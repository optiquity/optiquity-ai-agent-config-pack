# BD-175 EMERGENCY BATCH — Category A Archive Operation

**HEAD pre-archive:** `97b516324790d49ef35c1c5d0672b8bb62815088`
**HEAD post-archive (worktree state):** same SHA `97b5163` — no commits made (Pack Chat will stage + commit).
**Branch:** v11-dev
**Scope authority:** User-approved Category A archive per pack memory "Skill and agent maintenance" Pattern B (worked-example anchor: "workflow artifacts sweep to `maintenance-docs/archive/vN/` at version ship"). Operation executed mid-version per user instruction (Pattern B variant — interim batch-completion sweep).
**Operation:** 99 BD-175 batch artifacts moved from `maintenance-docs/v11-implementation/` → `maintenance-docs/archive/v11/`.

---

## 1. Archive scope summary

| Category | Files moved |
|----------|-------------|
| BD-175 COMMIT IMPL-REPORTs (Commits 1, 1-FIX, 2, 2-FIX, 3-12) | 15 |
| BD-175 fix/sweep IMPL-REPORTs (F1, F2A, F4-BUNDLE, NIT-1, SHOULD-1, T1-NIT, T1-NIT-SWEEP, END-OF-BATCH-FIX) | 8 |
| BD-176/177/178 IMPL-REPORTs | 7 |
| BD-179/180 IMPL-REPORTs (incl. FIX-1..5 and FIX-1..3) | 11 |
| BD-181/182/183/184 IMPL-REPORTs | 7 |
| PACK-REVIEW BD-175 COMMITs (1-11; no 12) | 12 |
| PACK-REVIEW BD-175 sweeps (T1-NIT-CUMULATIVE, F1, F2A, F4-BUNDLE, SHOULD-1, END-OF-BATCH, END-OF-BATCH-FIX) | 7 |
| PACK-REVIEWs BD-176..184 (incl. FIX-CYCLE / FIX-1..3 / SHOULD-2 / PRECONDITION / PASS-2) | 18 |
| BD-175 batch inputs / orchestration (survey, orchestration plan, phase plan, ARCHITECTURE-*-FIX-* chain, AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS, PATH-C-CURATION) | 14 |
| **Total moved** | **99** |

Source dir count: 229 before → 130 after (99 removed).
Destination dir count: 102 before → 201 after (99 added).
Counts symmetric — no file loss.

---

## 2. Files moved (enumerated by category)

### 2.1 IMPLEMENTATION-REPORTs — BD-175 COMMITs (15)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-2.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-2-FIX.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-2-FIX.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-5.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-5.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-6.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-6.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-7.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-7.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-8.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-8.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9A.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-9A.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-10.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-10.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-11.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-11.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-12.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-COMMIT-12.md` |

### 2.2 IMPLEMENTATION-REPORTs — BD-175 fix/sweep (8)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-F1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F2A.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-F2A.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-NIT-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-NIT-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-SHOULD-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-T1-NIT.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT-SWEEP.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-T1-NIT-SWEEP.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-END-OF-BATCH-FIX.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-175-END-OF-BATCH-FIX.md` |

### 2.3 IMPLEMENTATION-REPORTs — BD-176/177/178 (7)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-176.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-176.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-177.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-177-FIX.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-177-FIX-PASS-2.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-178.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-178-SHOULD-2.md` |

### 2.4 IMPLEMENTATION-REPORTs — BD-179/180 (11)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179-FIX-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179-FIX-2.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-3.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179-FIX-3.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-4.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179-FIX-4.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-179-FIX-5.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-179-FIX-5.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-ADDENDUM.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180-ADDENDUM.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180-FIX-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180-FIX-2.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-180-FIX-3.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180-FIX-3.md` |

### 2.5 IMPLEMENTATION-REPORTs — BD-181/182/183/184 (7)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-181.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-181.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-181-PRECONDITION.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-181-PRECONDITION.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-182.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-182.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-183.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183-FIX-1.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-183-FIX-1.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183-FIX-2.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-183-FIX-2.md` |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-184.md` | `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-184.md` |

### 2.6 PACK-REVIEWs — BD-175 COMMITs (12)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-1.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-1.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-2.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-2.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-3.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-3.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-4.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-4.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-5.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-5.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-6.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-6.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-7.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-7.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-8.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-8.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-9A.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-9A.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-9B.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-9B.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-10.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-10.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-11.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-COMMIT-11.md` |

Note: No `PACK-REVIEW-BD-175-COMMIT-12.md` exists on disk (BD-175 Commit 12 had no separate review cycle, per its IMPL-REPORT pattern).

### 2.7 PACK-REVIEWs — BD-175 sweeps (7)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-T1-NIT-CUMULATIVE.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-T1-NIT-CUMULATIVE.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F1.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-F1.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F2A.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-F2A.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F4-BUNDLE.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-F4-BUNDLE.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-SHOULD-1.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-SHOULD-1.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-END-OF-BATCH.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-END-OF-BATCH.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-END-OF-BATCH-FIX.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-175-END-OF-BATCH-FIX.md` |

### 2.8 PACK-REVIEWs — BD-176..184 (18)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-176.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-176.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-177.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-177.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-177-FIX-PASS-2.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-177-FIX-PASS-2.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-178.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178-SHOULD-2.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-178-SHOULD-2.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-179.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-179.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-179-FIX-CYCLE.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-179-FIX-CYCLE.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-180.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-180.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-180-FIX-1.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-180-FIX-1.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-180-FIX-2.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-180-FIX-2.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-180-FIX-3.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-180-FIX-3.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-181.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-181.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-181-PRECONDITION.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-181-PRECONDITION.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-182.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-182.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-183.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-183.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-183-FIX-1.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-183-FIX-1.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-183-FIX-2.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-183-FIX-2.md` |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-184.md` | `maintenance-docs/archive/v11/PACK-REVIEW-BD-184.md` |

### 2.9 BD-175 batch inputs / orchestration (14)

| Source | Destination |
|--------|-------------|
| `maintenance-docs/v11-implementation/BD-179-SURVEY-REPORT.md` | `maintenance-docs/archive/v11/BD-179-SURVEY-REPORT.md` |
| `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md` | `maintenance-docs/archive/v11/ORCHESTRATION-PLAN-BD-175.md` |
| `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` | `maintenance-docs/archive/v11/PLAN-BD-175-PHASE-5.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` | `maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-REPORT.md` | `maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-REPORT.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-V2-REPORT.md` | `maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-V2-REPORT.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` | `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` | `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-EXTENSION-REPORT.md` | `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-EXTENSION-REPORT.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-V2-AMENDMENT-REPORT.md` | `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-V2-AMENDMENT-REPORT.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` | `maintenance-docs/archive/v11/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` |
| `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK-FIX-REPORT.md` | `maintenance-docs/archive/v11/ARCHITECTURE-RE-LITIGATION-FRAMEWORK-FIX-REPORT.md` |
| `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` | `maintenance-docs/archive/v11/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` |
| `maintenance-docs/v11-implementation/PATH-C-CURATION.md` | `maintenance-docs/archive/v11/PATH-C-CURATION.md` |

---

## 3. Files NOT moved (Category B — kept in v11-implementation/)

Per user-approved scope, these 4 files STAY in `maintenance-docs/v11-implementation/` until v11.0 ship sweep (when they will archive with reference rewrites per Pattern B v11.0-ship sweep). All 4 verified to still exist post-archive.

| File | Active-reference sites | Rationale |
|------|------------------------|-----------|
| `ARCHITECTURE-BD-176.md` | `scripts/init-project.sh:1122,1237`; `scripts/tests/test-validate-pack-check-41.sh:4`; `scripts/validate-pack.py:204,4927,5108,5156,5159,5177,5237,5477`; `pack-ops/BACKLOG.md:1589,1598,1610,1618` | Referenced from Check 41 docstring, init-project.sh self-doc list comment, BACKLOG entries. Active design reference. |
| `ARCHITECTURE-BD-179.md` | `scripts/validate-pack.py:217,4539,4572,4664,4808,4909` (and ~7+ total refs) | Referenced 7+ times in Check 40 docstring and per-section comments. Active design reference. |
| `ARCHITECTURE-BD-182.md` | `CLAUDE.md:578,582`; `AGENTS.md:539,543`; `GEMINI.md:509,513` | Referenced from pack-root trinity Pack-memory bullet (boundary-investigation worked example). Active trinity reference. |
| `AUDIT-USER-CURATION.md` | `scripts/validate-pack.py:175,3771,4268,4299,4334`; `project-template/skills/boundary-investigation/SKILL.md:124`; `pack-ops/BOUNDARY-DEFINITION.md:5,94,100,101,113,137,143` | Referenced from Override 1/5/7/8 source citations in pack-ops/ docs + validate-pack.py allowlist rationale comments. Active design reference. |

---

## 4. Cross-ref safety verification

### 4.1 Category B refs intact (PASS)

All 4 Category B files verified present at `maintenance-docs/v11-implementation/<file>` post-archive. Reference paths in `scripts/`, `project-template/`, `pack-ops/`, and pack-root trinity still resolve to existing files.

### 4.2 Spot-check: non-BD-175-batch files NOT touched (PASS)

The following sample files (not in BD-175 batch scope; other batch lifecycles) confirmed still present at `maintenance-docs/v11-implementation/`:

- `ARCHITECTURE-BD-119.md`
- `ARCHITECTURE-CLEANUP-BATCH-19C.md`
- `EXECUTION-PLAN-V11.0.md`
- `RELEASE-GATE.md`
- `IMPLEMENTATION-REPORT-BD-169.md`
- `PACK-REVIEW-BD-169.md`
- `AUDIT-BD-032.md`
- `PLAN-BD-119.md`

### 4.3 SHOULD finding — stale source-of-design references to moved files [CLOSED via bundled fix in §4.4]

**Original finding:** `grep` of `scripts/`, `project-template/`, `pack-ops/`, and trinity for archived filenames identified references that would point to non-existent paths at `maintenance-docs/v11-implementation/` after the moves (the files moved to `maintenance-docs/archive/v11/`):

- `scripts/validate-pack.py:3717` — bare ref `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §8`.
- `pack-ops/BOUNDARY-DEFINITION.md:5` — 2 archived-file refs (REORG.md + REORG-FIX.md) co-located with 1 Category B ref (AUDIT-USER-CURATION.md).
- `pack-ops/BOUNDARY-DEFINITION.md:98` — 1 archived-file ref (REORG.md).
- `pack-ops/BOUNDARY-DEFINITION.md:113` — 1 archived-file ref (AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md) co-located with 1 Category B ref (AUDIT-USER-CURATION.md).

**Pack Chat triage decision (received 2026-05-21):** FIX-NOW + bundle into the same commit as the archive (logical bundling: archive + path updates for moved files). Per user's "I don't want anything to break" directive + carry-forward discipline `feedback_deferral_is_scope_creep`, refs MUST land in the same commit.

**Disposition:** **CLOSED** — fix applied. See §4.4 for per-edit details. Validator PASS preserved (see §5.1 post-fix output).

**Why this is the correct disposition:** Per the carry-forward 3-test framework (SIZE/BLOCKED/LOGICAL FIT), the rewrites are trivial (4 line edits), unblocked, and have direct LOGICAL FIT with the archive commit itself (same conceptual change: archiving moves these files, so qualified-path references must follow). Default FIX-NOW + bundle.

### 4.4 Stale reference fixes (bundled into archive commit)

Per Pack Chat triage decision, the 4 stale references identified in §4.3 were rewritten to point to the post-archive paths in `maintenance-docs/archive/v11/`. Two co-located Category B refs (to `AUDIT-USER-CURATION.md`) were explicitly preserved unchanged (file stays at `v11-implementation/` per the Category B keep-list).

| # | File | Line | Before | After |
|---|------|------|--------|-------|
| 1 | `scripts/validate-pack.py` | 3717 | `# layer per ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §8.` | `# layer per maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §8.` |
| 2 | `pack-ops/BOUNDARY-DEFINITION.md` | 5 (Source-of-design header) | `` `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` § ... + `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` § ... + `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Overrides 1 + 5. `` | `` `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` § ... + `maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` § ... + `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Overrides 1 + 5. `` (AUDIT-USER-CURATION.md ref preserved — Category B) |
| 3 | `pack-ops/BOUNDARY-DEFINITION.md` | 98 | `` An earlier design (`maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §2.1 + §3.3) `` | `` An earlier design (`maintenance-docs/archive/v11/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §2.1 + §3.3) `` |
| 4 | `pack-ops/BOUNDARY-DEFINITION.md` | 113 | `` the audit (`maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` §F) … User curation (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Overrides 3 + 4) `` | `` the audit (`maintenance-docs/archive/v11/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` §F) … User curation (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Overrides 3 + 4) `` (AUDIT-USER-CURATION.md ref preserved — Category B) |

**Category B preservation verified post-edit:**

- `pack-ops/BOUNDARY-DEFINITION.md:5` — `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` retained ✓
- `pack-ops/BOUNDARY-DEFINITION.md:100,101,137,143` — additional `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` refs unchanged ✓
- `pack-ops/BOUNDARY-DEFINITION.md:113` — `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` retained ✓

### 4.5 Surfaced: `pack-ops/BACKLOG.md:1405` stale ref (PM-only file — Pack Chat scope)

Re-scan post-fix identified ONE remaining stale reference to an archived file:

- `pack-ops/BACKLOG.md:1405`: `` `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md`. ``

Should point to `maintenance-docs/archive/v11/ORCHESTRATION-PLAN-BD-175.md` (file moved per §2.9 of this report).

**Why NOT fixed by this archive coder:** Per pack memory `feedback_pack_chat_does_no_fixes` § "What Pack Chat CAN edit directly" and §"Files you must NOT modify or move" in the prompt constraints, `pack-ops/BACKLOG.md` is a **PM-only file** (Pack-Chat-direct edit only). Sub-agents (including this coder) may NOT modify `pack-ops/BACKLOG.md` — this is a Pack Chat scope edit.

**Surfaced for Pack Chat fix-or-defer triage** with the same default-FIX-NOW + bundle disposition recommended for §4.3/§4.4. The fix is a single mechanical path rewrite Pack Chat may apply directly per the PM-only file scope rule, OR may defer with typed TD comment per pack memory `feedback_deferred_work_tracking`.

### 4.6 Active code refs to moved Category A files — comprehensive final scan

Post-fix scanner: zero stale qualified refs (`maintenance-docs/v11-implementation/<archived-file>`) remain in `scripts/`, `project-template/`, `supporting-docs/`, `pack-ops/` (except `BACKLOG.md` per §4.5), and pack-root trinity.

Sole remaining stale ref: `pack-ops/BACKLOG.md:1405` (PM-only file — §4.5 surface to Pack Chat).

---

## 5. Verification

### 5.1 validate-pack.py PASS (post-fix)

Run AFTER §4.4 stale-ref fixes applied:

```
$ python3 scripts/validate-pack.py
...
── Check 39: cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) forward-checked; 6 have explicit `cmd_update` mappings, 0 on forward exemption allowlist. 35 `cmd_update` entries reverse-checked; 35 resolve to existing files at HEAD, 0 on reverse exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings; no stale mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

Result: **PASS** — all 42 checks clean post-fix. The §4.4 edits preserved Check 40 cleanliness (the rewrites use qualified paths `maintenance-docs/archive/v11/...` — fully qualified, not bare; Check 40 scope is pack-ops/*.md only, and the qualified-form references continue to satisfy the bare-cross-ref scanner). Category B refs (`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`) still resolve to existing files.

### 5.2 Post-fix stale-reference scanner — zero stale refs in pack-coder scope

```
$ grep -rnE "maintenance-docs/v11-implementation/(ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS|ARCHITECTURE-DIRECTORY-REORGANIZATION|ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX|ARCHITECTURE-RE-LITIGATION-FRAMEWORK|AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS|PATH-C-CURATION|BD-179-SURVEY-REPORT|ORCHESTRATION-PLAN-BD-175|PLAN-BD-175-PHASE-5)" \
  --include="*.md" --include="*.py" --include="*.sh" --include="*.toml" --include="*.yml" --include="*.yaml" \
  -- pack-ops/ scripts/ project-template/ supporting-docs/ CLAUDE.md AGENTS.md GEMINI.md README.md

pack-ops/BACKLOG.md:1405:  `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md`.
```

Sole remaining hit is `pack-ops/BACKLOG.md:1405` — out of pack-coder scope per §4.5 (PM-only file → Pack Chat scope edit). All 4 in-scope stale refs are now correctly pointing to `maintenance-docs/archive/v11/`.

Bare-form scan (catches the line 3717 ref in `scripts/validate-pack.py`) also confirms post-fix correctness: the ref now reads `maintenance-docs/archive/v11/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md §8` (qualified, points to correct post-archive path).

### 5.3 git status — final state

```
$ git status -s | grep -c "^ M "
2
$ git status -s | grep -c "^ D "
99
$ git status -s | grep -c "^?? "
100
```

- 99 deletions in `maintenance-docs/v11-implementation/` (file moves out)
- 100 untracked files (99 file moves into `maintenance-docs/archive/v11/` + 1 new `IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md`)
- 2 modifications (`scripts/validate-pack.py` + `pack-ops/BOUNDARY-DEFINITION.md` — §4.4 stale-ref fixes)

Pack Chat staging with `git add -A` and `git diff -M --staged` will detect the 99 moves as renames (content preserved; only path changed). Shell `mv` was used per user-revised instruction (the original prompt clarification: `git mv` is a state-changing verb forbidden to sub-agents; shell `mv` falls within the user's pre-approved archive scope).

### 5.3 File-count audit

| Metric | Value | Expected | Pass |
|--------|-------|----------|------|
| Files moved (Category A) | 99 | ~70 (rough user estimate) | Within range (user said "~70"; precise enumeration = 99) |
| BD-175 batch files remaining in v11-implementation/ | 0 | 0 (excluding Category B) | PASS |
| Category B files still in v11-implementation/ | 4 | 4 | PASS |
| Files in v11-implementation/ pre-archive | 229 | — | (baseline) |
| Files in v11-implementation/ post-archive | 130 | 229 - 99 = 130 | PASS |
| Files in archive/v11/ pre-archive | 102 | — | (baseline) |
| Files in archive/v11/ post-archive | 201 | 102 + 99 = 201 | PASS |

**Note on user count estimate:** The prompt said "Expected file count: ~70 files" but the precise enumeration of the lists provided in the prompt yields 99. Breakdown vs prompt:

- IMPL-REPORTs (BD-175 COMMIT-1..12 + 2 FIX): 15 (prompt said 11; recount = 15 including 1, 1-FIX, 2, 2-FIX, 3, 4, 5, 6, 7, 8, 9A, 9B, 10, 11, 12)
- BD-175 fix/sweep IMPL-REPORTs: 8 ✓ (matches prompt)
- BD-176 IMPL-REPORT: 1 ✓
- BD-177 IMPL-REPORTs: 3 ✓
- BD-178 IMPL-REPORTs: 3 ✓
- BD-179 IMPL-REPORTs: 6 ✓
- BD-180 IMPL-REPORTs: 5 ✓
- BD-181 IMPL-REPORTs: 2 ✓
- BD-182 IMPL-REPORT: 1 ✓
- BD-183 IMPL-REPORTs: 3 ✓
- BD-184 IMPL-REPORT: 1 ✓
- PACK-REVIEW BD-175 COMMITs: 12 ✓
- PACK-REVIEW BD-175 sweeps: 7 ✓
- PACK-REVIEW BD-176: 1 ✓
- PACK-REVIEW BD-177: 2 ✓
- PACK-REVIEW BD-178: 2 ✓
- PACK-REVIEW BD-179: 2 ✓
- PACK-REVIEW BD-180: 4 ✓
- PACK-REVIEW BD-181: 2 ✓
- PACK-REVIEW BD-182: 1 ✓
- PACK-REVIEW BD-183: 3 ✓
- PACK-REVIEW BD-184: 1 ✓
- Inputs/orch: 14 ✓ (per prompt enumeration: 1 survey + 1 orch-plan + 1 phase-plan + 3 boundary-prev chain + 4 dir-reorg chain + 2 re-lit chain + 1 audit + 1 path-c)

Total: 15 + 8 + 1+3+3+6+5+2+1+3+1 + 12+7+1+2+2+2+4+2+1+3+1 + 14 = 99 ✓

The "~70" estimate appears to have been a rough mental count; the precise enumeration matches each listed file in the prompt. No silent scope expansion.

---

## 6. RC9 manifest status

Two distinct change classes in this commit:

**(a) File-move changes (Category A archive — §2 enumeration):** `maintenance-docs/` is NOT in the RC9 trigger glob (per pack memory `feedback_manifest_regen_on_v11_surface` and `CLAUDE.md` § "Regenerate test-fixtures/manifest.txt on every v11-surface commit" — trigger glob is `project-template/**`, `scripts/**`, `pack-ops/**`, `supporting-docs/**`). The 99 file moves between `maintenance-docs/v11-implementation/` and `maintenance-docs/archive/v11/` do NOT trigger manifest regen on their own.

**(b) §4.4 stale-ref fix edits:** `scripts/validate-pack.py` AND `pack-ops/BOUNDARY-DEFINITION.md` ARE in the RC9 trigger glob (`scripts/**` and `pack-ops/**`). Per the RC9 inclusive-trigger rule (false positives cost ~30-90s rebuild but produce no incorrect manifest), the commit DOES trigger manifest regen.

**Regen performed:**

```
$ bash test-fixtures/build.sh --all --clean
... [6 fixtures built] ...
manifest written: test-fixtures/manifest.txt

$ git status -s test-fixtures/manifest.txt
(empty — manifest unchanged)
```

**Result:** Manifest unchanged. The 2 edited files are not fixture-affecting in practice:
- `scripts/validate-pack.py` line 3717 is an inline comment (no executable-behavior change).
- `pack-ops/BOUNDARY-DEFINITION.md` is not copied to clients by `init-project.sh` (verified by absence from `_CLIENT_INSTALLED_FILES` self-doc list in `init-project.sh`).

**RC9 disposition:** Trigger satisfied (regen run; manifest verified). No `test-fixtures/manifest.txt` staging needed (no change to commit). Pack Chat's `git status` will show the manifest as clean — this is the correct post-rebuild state.

---

## 7. Carry-forward discipline

Applied rigorously per `.claude/skills/review/SKILL.md` § Carry-forward discipline:

- **Scope-adjacent observation 1 [CLOSED]:** §4.3 stale source-of-design references in `scripts/validate-pack.py` (line 3717) and `pack-ops/BOUNDARY-DEFINITION.md` (lines 5, 98, 113). **Initial disposition:** Surfaced as SHOULD finding for Pack Chat triage (carry-forward did NOT meet all 3 SIZE/BLOCKED/FIT tests → default FIX-NOW). **Pack Chat triage decision:** FIX-NOW + bundle into this same commit. **Final disposition:** CLOSED via §4.4 bundled fixes (4 edits applied; validator PASS preserved; Category B refs explicitly preserved). The carry-forward 3-test framework worked as designed: surface NOT silently fix → Pack Chat triages → fix-or-defer decision → if fix, bundle into the same commit as the underlying change for atomicity.

- **Scope-adjacent observation 2 [NEW — surfaced]:** §4.5 stale reference in `pack-ops/BACKLOG.md:1405` (to archived `ORCHESTRATION-PLAN-BD-175.md`). Out of pack-coder scope (PM-only file). Surfaced to Pack Chat for PM-only-scope fix-or-defer triage. SIZE: 1 line; BLOCKED: no; LOGICAL FIT: direct (same archive commit). Recommendation: FIX-NOW + bundle (same disposition as §4.3/§4.4 — Pack Chat applies directly per PM-only edit scope).

- **Scope-adjacent observation 3:** None. No other scope-adjacent observations surfaced during the archive enumeration or post-fix verification. All 99 files moved match the user-provided Category A list with zero additions; all 4 Category B files match the user-provided keep list with zero subtractions; 4 sanctioned ref-fixes applied per Pack Chat triage; 1 PM-only ref surfaced for Pack Chat scope.

- **Deferrals introduced:** Zero unconditional deferrals. All findings are either CLOSED (§4.3 via §4.4) or surfaced for Pack Chat in-batch fix-or-defer triage (§4.5).

---

## 8. Boundary discipline check

Initial archive operation: touches ONLY files in `maintenance-docs/` (pack-side). No `project-template/` edits, no `supporting-docs/` edits, no pack-shipped client-installable surface edits. Boundary discipline pre-flight (P-missed-7) does NOT apply.

**§4.4 stale-ref fix scope (added after Pack Chat triage):** touches `scripts/validate-pack.py` (pack-side) and `pack-ops/BOUNDARY-DEFINITION.md` (pack-side). Both are pack-side files with pack-side SSOT (their own design records: BD-179 architect doc for validate-pack.py Check 40 contract; BD-175 directory-architect doc + BD-175 audit-user-curation doc for BOUNDARY-DEFINITION.md). The edits are path rewrites only — no concept introduction, no rule additions, no cross-surface references introduced. Boundary discipline pre-flight (P-missed-7) confirms: pack-side file edited with pack-side path target (`maintenance-docs/archive/v11/`) — symmetric, no project-side surface touched, no SSOT investigation needed beyond the path rewrite mechanics.

---

## 9. Definition-of-Done checklist

| Item | Status | Evidence |
|------|--------|----------|
| All Category A files moved to archive | PASS | 99 files moved per §2 enumeration |
| Zero Category A files remaining in v11-implementation/ | PASS | §5.3 file-count audit |
| All 4 Category B files preserved in v11-implementation/ | PASS | §3 table + §4.1 |
| No non-BD-175-batch files touched (Category A scope) | PASS | §4.2 spot-check |
| Destination directory exists | PASS | `maintenance-docs/archive/v11/` pre-existed (102 files baseline); 99 added |
| File-name conflicts at destination | NONE | No collisions (verified by counts symmetric: 99 moved = 99 added) |
| validate-pack.py PASS post-archive AND post-fix | PASS | §5.1 output (final state, all 42 checks clean) |
| Cross-ref safety (Category B refs intact) | PASS | §4.1 + §4.4 explicit Category B preservation verified |
| Stale-reference SHOULD finding surfaced (§4.3) | PASS | §4.3 surfaced + §4.4 closed via Pack Chat fix-now triage |
| Stale-reference fixes applied (§4.4 bundled per Pack Chat triage) | PASS | 4 sanctioned edits applied; post-fix scanner zero stale refs in pack-coder scope |
| PM-only stale ref surfaced for Pack Chat (§4.5) | PASS | `pack-ops/BACKLOG.md:1405` surfaced (out of pack-coder scope) |
| Files moved-but-not-in-Category-A list | NONE | All 99 moves match the user-provided list exactly |
| Files edited outside Category A scope (sanctioned by Pack Chat) | 2 (per §4.4) | `scripts/validate-pack.py` + `pack-ops/BOUNDARY-DEFINITION.md` |
| Files edited outside both Category A scope AND Pack Chat sanction | 0 | All edits are either file moves (Category A) or Pack-Chat-sanctioned §4.4 fixes |
| Carry-forward discipline applied | PASS | §7 with explicit citations |
| RC9 manifest regen status documented | PASS | §6 — no regen needed (maintenance-docs/ not in trigger; scripts/validate-pack.py + pack-ops/BOUNDARY-DEFINITION.md ARE in trigger but see §6 caveat below) |
| Scope strictly limited to file moves + Pack-Chat-sanctioned ref fixes | PASS | Only `mv` operations + 4 Pack-Chat-sanctioned ref-fix Edits |
| IMPL-REPORT written + updated post-fix | PASS | This file |

---

## 10. Plan deviations

Zero deviations from user-approved scope at execution time. Each move corresponds to an explicit Category A list entry. The only items not in the user's narrative-prose count of "~70" but precisely in the user's enumerated list are the additional COMMIT IMPL-REPORTs (1-FIX, 2-FIX) and the additional sweep IMPL-REPORTs that the prompt narrative under-counted. See §5.3 reconciliation — precise enumeration matches each explicit list entry. Total = 99.

**Pack Chat triage-driven scope extension (post-initial-IMPL-REPORT, pre-commit):** Pack Chat extended scope to include §4.4 stale-reference fixes (`scripts/validate-pack.py:3717` + `pack-ops/BOUNDARY-DEFINITION.md` lines 5/98/113) per the convergence directive. This is NOT a plan deviation — it is an in-batch triage-driven fix bundle (carry-forward §7 closure) sanctioned by Pack Chat.

---

## 11. New POQs introduced

None. The §4.3 stale-reference observation was a SHOULD finding (now closed via §4.4 bundled fix). The §4.5 PM-only `BACKLOG.md:1405` ref is a surfaced finding for Pack Chat scope (single-line path rewrite), not an architectural open question.

---

## 12. Files changed inventory

| Path | Change type | Source |
|------|-------------|--------|
| `maintenance-docs/v11-implementation/<99-files>` | deleted (moved to archive) | §2 enumeration |
| `maintenance-docs/archive/v11/<99-files>` | new (received from v11-implementation/) | §2 enumeration |
| `scripts/validate-pack.py` | modified (1 line — comment-only path qualification + update) | §4.4 row 1 (Pack Chat triage) |
| `pack-ops/BOUNDARY-DEFINITION.md` | modified (3 lines — path updates; Category B refs preserved) | §4.4 rows 2-4 (Pack Chat triage) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md` | new (this report; lives in v11-implementation/ until v11.0 ship sweep) | initial write + post-fix update |

Total file operations:
- 99 deletions (paired with 99 additions = net renames via shell mv; Pack Chat staging detects via `git diff -M`)
- 2 modifications (scripts/validate-pack.py + pack-ops/BOUNDARY-DEFINITION.md, per §4.4)
- 1 new file (this IMPL-REPORT)

Net dir-state change:
- `maintenance-docs/v11-implementation/`: 229 → 131 (-99 + 1 new IMPL-REPORT)
- `maintenance-docs/archive/v11/`: 102 → 201 (+99)
- `scripts/validate-pack.py`: 1 line modified (no LOC change)
- `pack-ops/BOUNDARY-DEFINITION.md`: 3 lines modified (no LOC change)
- `test-fixtures/manifest.txt`: regen run per RC9; manifest unchanged; no staging needed (§6)

---

PREFLIGHT: 99/99 file moves complete; 4/4 §4.4 Pack-Chat-sanctioned stale-ref fixes complete (2 files modified: `scripts/validate-pack.py` + `pack-ops/BOUNDARY-DEFINITION.md`); verification PASS (validate-pack.py PASSES all 42 checks post-fix; Category B intact at v11-implementation/; 0 BD-175-batch files left in v11-implementation/; post-fix scanner shows zero stale refs in pack-coder scope — sole remaining ref in `pack-ops/BACKLOG.md:1405` surfaced for Pack Chat scope §4.5); RC9 manifest regen run per §6, manifest unchanged, no staging needed; HEAD `97b516324790d49ef35c1c5d0672b8bb62815088` (pre-archive; no commits made — Pack Chat will stage + commit); IMPL-REPORT updated at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md`.
