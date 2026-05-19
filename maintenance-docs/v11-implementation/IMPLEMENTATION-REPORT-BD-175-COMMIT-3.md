# IMPLEMENTATION REPORT — BD-175 Commit 3 (M6-M8 supporting-docs/ → pack-ops/)

**Commit subject (target):** `feat: v11 — BD-175 directory reorg M6-M8 (supporting-docs/ → pack-ops/)`
**Branch:** v11-dev
**Pre-flight HEAD:** `fc1a136bf01449f2c482c2521a0f4261847e88b9`
**Final HEAD (working tree, not committed — Pack Chat commits):** `fc1a136bf01449f2c482c2521a0f4261847e88b9`
**Coder:** pack-coder (Claude Code)
**Plan reference:** `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` §2.3

---

## §1 Summary

Executed Commit 3 of BD-175 Phase 5: relocated 3 supporting-docs files to `pack-ops/` per Architect B §4.1 F-1 resolution + AUDIT-USER-CURATION.md Override 6, updated 4 LIVE forward-pointing cross-references on the pack-side surface, verified zero scripts/ references existed (no script edits needed), regenerated `test-fixtures/manifest.txt` per RC9. Total working-tree changes: 3 git mv + 4 modified files + 1 manifest. All architect docs, audit/review workflow artifacts, per-entry BACKLOG/CHANGELOG mirror entries, and historical-quote refs are correctly classified as HISTORICAL and left unchanged.

Verification: validate-pack.py 33 checks PASS; pack-ops/ shows 12 files (Commit 1's 2 + Commit 2's 7 + Commit 3's 3 = 12, including the hidden `.boundary-exempt-root.txt`); supporting-docs/ shows 10 files (post-move state matches plan §2.3.4 expected list); `bash scripts/dry-run-migration.sh --help` runs cleanly; manifest diff non-empty (3 v11-* SHAs drifted).

---

## §2 Step-by-step report

### Step 1 — git mv 3 supporting-docs files to pack-ops/

Executed three `git mv` operations (file history preserved per `git status --short` showing `R` markers):

```
git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
git mv supporting-docs/DRY-RUN-MIGRATION.md             pack-ops/DRY-RUN-MIGRATION.md
git mv supporting-docs/MERGE-STRATEGY.md                pack-ops/MERGE-STRATEGY.md
```

Content of all 3 files preserved byte-identical during the move (location-only change). Per Override 6 + B-fix §16 cascade closure, destination is `pack-ops/` (NOT `maintenance-docs/`).

### Step 2 — Update scripts that reference the moved files

`grep -n` against `scripts/migrate-v10-to-v11.sh` and `scripts/dry-run-migration.sh` for `supporting-docs/MERGE-STRATEGY.md`, `supporting-docs/DRY-RUN-MIGRATION.md`, `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`, and the bare filenames returned **zero hits in both scripts**. A repo-wide `scripts/` grep also returned zero hits. No script edits required.

The plan §2.3.3 listed these as candidate scripts to update; verification confirmed no current references existed. The fact that no script references survive is consistent with the migration scripts not relying on the old `supporting-docs/` filename paths; cross-references to the relocated docs live in user-facing doc surfaces, not in shell.

### Step 3 — Update LIVE cross-references

Per §2.3.2 case-by-case judgment + B-fix §6.5 live-vs-archive triage. Repo-wide grep (excluding `.git/` and `archive/`) on all three relocated paths returned 51 file hits. Per-file judgment applied:

**LIVE forward-pointing refs (UPDATED — 4 occurrences in 4 files):**

| # | File | Line | Before | After |
|---|---|---|---|---|
| 1 | `QUICKSTART.md` | 41 | `[\`supporting-docs/MERGE-STRATEGY.md\`](supporting-docs/MERGE-STRATEGY.md)` | `[\`pack-ops/MERGE-STRATEGY.md\`](pack-ops/MERGE-STRATEGY.md)` |
| 2 | `pack-ops/OPTIONAL-FEATURES.md` | 214 | `` `supporting-docs/MERGE-STRATEGY.md` for the per-file class matrix `` | `` `pack-ops/MERGE-STRATEGY.md` for the per-file class matrix `` |
| 3 | `pack-ops/PACK-CHAT.md` | 227 | `` `supporting-docs/MERGE-STRATEGY.md`. `` | `` `pack-ops/MERGE-STRATEGY.md`. `` |
| 4 | `project-template/docs/pack/PM-CHAT.md` | 401 | `` `docs/pack/MERGE-STRATEGY.md` (or `supporting-docs/MERGE-STRATEGY.md` in the pack repo) `` | `` `docs/pack/MERGE-STRATEGY.md` (or `pack-ops/MERGE-STRATEGY.md` in the pack repo) `` |

**HISTORICAL refs (LEFT UNCHANGED — frozen per plan §2.3.2 NOT MODIFIED categories + B-fix §6.4 + §6.5):**

All remaining 47 file hits across 47 files. See §5 for the full triage breakdown.

### Step 4 — Verify no trinity references to moved files

```
grep -n 'CONCEPTUAL-REVIEW-METHODOLOGY|supporting-docs/MERGE-STRATEGY|supporting-docs/DRY-RUN-MIGRATION' \
  CLAUDE.md AGENTS.md GEMINI.md
```

Result: **ZERO hits.** Trinity is clean as the plan §2.3.2 NOT MODIFIED clause anticipated. The trinity rule § "Repo conventions" §"Skill and agent maintenance is mechanical by default" bullet mentions `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (which lives at `maintenance-docs/v11-implementation/` — unaffected).

### Step 5 — Regenerate test-fixtures/manifest.txt (RC9 MANDATORY)

```
bash test-fixtures/build.sh --all --clean
```

Successful rebuild of all 6 fixtures. Manifest diff non-empty per RC9 expectation (project-template/docs/pack/PM-CHAT.md is v11-surface and was edited in Step 3):

```
-v11-realistic-ot  e7ff2315f8b8e3b4b6fb794e994d76506136bf20
-v11-flat-file  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
-v11-tracker-on  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
+v11-realistic-ot  cbab3ffc926939c0771f4317f8a0ae944bcaa62f
+v11-flat-file  b1d788ac557788eb98e7f14b899630701fd3b417
+v11-tracker-on  cce0f1ac3dda17328523f744cebc933c688c539c
```

3 v11-* fixtures drifted; v10-* fixtures unchanged (tag-pinned per `test-fixtures/README.md`). Pack Chat stages manifest alongside scope edits per RC9.

---

## §3 Per-file edit list

Excluding the 3 git-mv'd files (location-only change, content preserved):

| File | Change type | Lines affected | Description |
|---|---|---|---|
| `QUICKSTART.md` | modified | 41 | LIVE ref update: `supporting-docs/MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md` (markdown link, both label and href) |
| `pack-ops/OPTIONAL-FEATURES.md` | modified | 214 | LIVE ref update: `supporting-docs/MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md` (inline code) |
| `pack-ops/PACK-CHAT.md` | modified | 227 | LIVE ref update: `supporting-docs/MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md` (inline code) |
| `project-template/docs/pack/PM-CHAT.md` | modified | 401 | LIVE ref update: `supporting-docs/MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md` (inline code, within parenthetical "in the pack repo" disambiguator) |
| `test-fixtures/manifest.txt` | modified | 7-9 | RC9 regen: v11-realistic-ot, v11-flat-file, v11-tracker-on SHAs updated |

Total modified files: **5**. Total git-mv files: **3** (renames preserve history, no content change).

---

## §4 Verification results

### 4.1 — `python3 scripts/validate-pack.py`
**Status: PASS** — all checks clean (33 numbered checks + 2 informational; tail output shows `PASSED — all checks clean`).

### 4.2 — `ls pack-ops/`
**Status: PASS** — shows 12 files (11 visible + 1 hidden `.boundary-exempt-root.txt`). Matches plan §2.3.4 "after Commit 3 = 12 files":

```
.boundary-exempt-root.txt   (hidden, from Commit 1)
BACKLOG.md                  (from Commit 2)
BOUNDARY-DEFINITION.md      (from Commit 1)
CHANGELOG.md                (from Commit 2)
CONCEPTUAL-REVIEW-METHODOLOGY.md  (NEW — Commit 3)
DRY-RUN-MIGRATION.md             (NEW — Commit 3)
HELP-FRAGMENT-PACK.md       (from Commit 2)
HELP-FRAGMENT-TRACKER.md    (from Commit 2)
MERGE-STRATEGY.md                (NEW — Commit 3)
OPTIONAL-FEATURES.md        (from Commit 2)
PACK-AGENTS.md              (from Commit 2)
PACK-CHAT.md                (from Commit 2)
```

### 4.3 — `ls supporting-docs/`
**Status: PASS** — shows 10 files post-move (CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION, MERGE-STRATEGY are gone; remaining match plan §2.3.4 expected list):

```
AGENT_KICKOFF_TEMPLATE.md
CLI-PM-SETUP.md
DEPENDENCIES.md
INSTALL-PROCEDURES.md
METHODOLOGY.md
MIGRATION-v10-to-v11.md
MIGRATION-v8-to-v9.md
SETUP_TEMPLATE.md
SETUP-EXISTING.md
SETUP-NEW.md
```

### 4.4 — `grep -rn 'supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY\.md' --include=*.md --include=*.sh --include=*.py --exclude-dir=archive .`
**Status: PASS** — 92 line hits across 26 files; **all 92 in historical-context surfaces** (24 maintenance-docs/v11-implementation/ workflow artifacts + 1 pack-ops/BACKLOG.md per-entry mirror + the plan/audit docs being read). Zero LIVE forward-pointing hits per plan §2.3.4 wording ("architect docs allowed if they cite as historical 'Before:'"). See §5 triage.

### 4.5 — `grep -rn 'supporting-docs/DRY-RUN-MIGRATION\.md' ...`
**Status: PASS** — 11 line hits; **all in historical-context surfaces** (maintenance-docs/v11-implementation/ artifacts + pack-ops/BACKLOG.md). Zero LIVE forward-pointing hits. Outside-maintenance-docs check: `grep ... | grep -v 'maintenance-docs|pack-ops/BACKLOG|pack-ops/CHANGELOG'` returns **0 hits**.

### 4.6 — `grep -rn 'supporting-docs/MERGE-STRATEGY\.md' ...`
**Status: PASS** — 77 line hits; **all in historical-context surfaces** post-Step-3. Outside-maintenance-docs check: `grep ... | grep -v 'maintenance-docs|pack-ops/BACKLOG|pack-ops/CHANGELOG'` returns **0 hits**.

### 4.7 — `bash scripts/dry-run-migration.sh --help`
**Status: PASS** — script runs cleanly, prints full Usage block (29+ lines), no "file not found" errors. Confirms the move did not break the script's runtime path resolution.

### 4.8 — `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt`
**Status: PASS** — rebuild completes; manifest diff non-empty (3 v11-* SHAs drifted as expected since project-template/docs/pack/PM-CHAT.md is v11-surface and was edited). v10-* SHAs unchanged (tag-pinned). Pack Chat stages manifest with scope edits per RC9.

### 4.9 — Trinity check
**Status: PASS** — `grep -n 'CONCEPTUAL-REVIEW-METHODOLOGY|supporting-docs/MERGE-STRATEGY|supporting-docs/DRY-RUN-MIGRATION' CLAUDE.md AGENTS.md GEMINI.md` returns 0 hits. No trinity edits in this commit; trinity Check 18 H2 parity N/A.

### 4.10 — `git status --short`
**Status: PASS** — final state:

```
 M QUICKSTART.md
R  supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md -> pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
R  supporting-docs/DRY-RUN-MIGRATION.md -> pack-ops/DRY-RUN-MIGRATION.md
R  supporting-docs/MERGE-STRATEGY.md -> pack-ops/MERGE-STRATEGY.md
 M pack-ops/OPTIONAL-FEATURES.md
 M pack-ops/PACK-CHAT.md
 M project-template/docs/pack/PM-CHAT.md
 M test-fixtures/manifest.txt
```

3 renames (history preserved per `R` marker) + 4 modifications + 1 manifest = 8 working-tree changes. HEAD unchanged at `fc1a136` (agents never commit per pack memory `feedback_agents_never_commit`).

---

## §5 LIVE vs HISTORICAL maintenance-docs/v11-implementation/ triage

Per plan §2.3.2 + B-fix §6.5 case-by-case guidance. Of 51 file hits (3 paths combined), 4 are LIVE (updated in Step 3) and **47 are HISTORICAL (left unchanged)**.

### 5.1 — LIVE refs (UPDATED — 4 files)

Already enumerated in §2 Step 3.

### 5.2 — HISTORICAL refs (LEFT UNCHANGED — 47 files)

#### Category A: maintenance-docs/v11-implementation/ workflow artifacts (Pattern B exemption per CLAUDE.md "Skill and agent maintenance is mechanical by default")

Workflow artifacts produced during the v11-implementation cycle that sweep to `maintenance-docs/archive/v11/` at version ship. They describe state at the time of writing. Per B-fix §6.5: "Architect A's re-litigation work will touch many of these as part of the contamination triage" — but in this commit, all refs in these files are historical (audit subjects, "Before:" rows, MOVES table source columns, hypothetical/example state, methodology-source citations at the time the doc was written, file-symbol planning targets for past or now-resolved work).

Architecture/Audit/Re-litigation docs (already correctly updated per Phase 3 verification §1 Override 6 cascade — all refs that remain are historical "Before:" rows in MOVES tables, source columns in commit-sequencing tables, "git mv" command shown to coder, audit subject citations):

- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` — MOVES table source column + "Before:" row in §16 cascade detail
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` — MOVES table source column + "Before:" rows in §16 amendment record
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX-V2-AMENDMENT-REPORT.md` — Before/After report (explicitly historical Before/After format)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` — V4 source path (audit subject), `git mv` command shown to coder (instructional), V5 source path
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK-FIX-REPORT.md` — historical record of A's fix-pass
- `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` — hypothetical/example fixture references for Check 36 design
- `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS-FIX-REPORT.md` — historical record of C's fix-pass
- `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` — methodology-source citations (at time of writing)
- `ARCHITECTURE-BD-119.md` — past architect work (historical context for impl planning)
- `ARCHITECTURE-SIDECAR-LIFECYCLE.md` — design-time source-citation block + descriptions of what the files contained at design time
- `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` + `-ADDENDUM.md` — past architect work (historical state references)
- `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` — the audit itself; its subject is the files at their `supporting-docs/` location at audit-time
- `AUDIT-USER-CURATION.md` — quotes B's original proposal (`maintenance-docs/...`) verbatim in Override 6 context
- `PACK-REVIEW-PHASE-2-DESIGNS.md` + `-VERIFICATION.md` — review of past architect designs
- `PACK-REVIEW-BD-078-RETRO.md` through `PACK-REVIEW-BD-131-RETRO.md` (10 RETRO files) — all cite `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` in their "Methodology:" header as the methodology source at the time of the review
- `PACK-REVIEW-BD-117.md`, `PACK-REVIEW-BD-095-RETRO.md` — same pattern (methodology source + cross-references to past file state)

Plan/Execution docs:
- `PLAN-BD-175-PHASE-5.md` — this very plan describes the move that's being made (source-column refs)
- `PLAN-BD-119.md`, `PLAN-SKILL-DIMENSIONS.md`, `PLAN-PER-ENTRY-SPLIT-BATCH-19.md` — past planning docs (historical impl targets)
- `EXECUTION-PLAN-V11.0.md` — historical execution plan listing past batches
- `ORCHESTRATION-PLAN-BD-175.md` — orchestration plan describing past audit findings

Implementation reports / concept-area docs / research:
- `IMPLEMENTATION-REPORT-BD-117.md`, `IMPLEMENTATION-REPORT-BD-169.md`, `IMPLEMENTATION-REPORT-BD-101-RETRO-FIX.md`, `IMPLEMENTATION-REPORT-BD-175-COMMIT-2-FIX.md`, `IMPLEMENTATION-REPORT-SIDECAR-LIFECYCLE-FIX.md` — historical impl records of past commits
- `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` — version-pinned (v11.0) concept-area workflow artifact; refs describe the in-scope files and methodology source at concept-writing time
- `RESEARCH-BATCH-19B-STRATEGIC-RULES.md` — research artifact (historical survey at research-time)

**Total Category A: 26 files** (some with multiple line hits).

#### Category B: maintenance-docs/v11-research/ workflow artifacts

- `IMPLEMENTATION-PLAN-ADDENDUM-2.md`, `IMPLEMENTATION-PLAN-ADDENDUM-4.md`, `IMPLEMENTATION-PLAN-ADDENDUM.md`, `ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md` — past plan/architecture addenda

**Total Category B: 4 files**.

#### Category C: pack-ops/BACKLOG.md (per-entry mirror — historical BD records)

Per per-entry source-of-truth contract, each BD entry's `File/Symbol`, `Description`, `Resolved:`, and `Type:` lines describe past or planned work at the entry's creation/resolution time. These records are FROZEN by the per-entry contract — Resolved BDs are immutable history; Open BDs (BD-136, BD-175) carry `File/Symbol` planning targets that are accurate to entry-write time but supersede via subsequent commits.

Line hits in `pack-ops/BACKLOG.md`:
- L663 (BD-094 File/Symbol — Resolved entry)
- L698 (BD-095 Resolved line — historical)
- L1394 (BD-175 Description — describes what commit `aaa61b3` modified at the time)
- L1626 (BD-169 File/Symbol — Resolved entry)
- L1850 (BD-148 File/Symbol — Resolved entry)
- L1991 (BD-136 Type: note — surfaced state at entry-write time)
- L2041 (BD-136 spec File/Symbol — Open entry, planning target accurate to entry-write time)
- L2083 (BD-135 Resolved entry File/Symbol — historical)
- L2215 (BD-125 File/Symbol — Resolved entry)
- L2250 (BD-125 Resolved line — historical)
- L2324 (BD-123 Cancelled entry File/Symbol — historical)

All HISTORICAL per the per-entry contract.

#### Category D: pack-ops/CHANGELOG.md (regenerated mirror — historical change-log)

L72 (BD-094 entry), L143 (BD-148 entry), L187 (BD-148 entry) — historical change-log entries describing past BDs that touched files at their then-current `supporting-docs/` location.

**Triage decision rationale:** Per CLAUDE.md "Per-entry trees vs mirrors — mode-dependent source of truth" + plan §2.3.2 NOT MODIFIED clause + B-fix §6.4 FROZEN/§6.5 case-by-case. Editing historical BD/CHANGELOG entries to reflect the new path would falsify the historical record (each BD's File/Symbol records the file location at the time the work was done or planned).

---

## §6 Manifest regen output

```
$ bash test-fixtures/build.sh --all --clean
... (6 fixtures rebuilt cleanly) ...
manifest written: test-fixtures/manifest.txt

$ git diff test-fixtures/manifest.txt
-v11-realistic-ot  e7ff2315f8b8e3b4b6fb794e994d76506136bf20
-v11-flat-file  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
-v11-tracker-on  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
+v11-realistic-ot  cbab3ffc926939c0771f4317f8a0ae944bcaa62f
+v11-flat-file  b1d788ac557788eb98e7f14b899630701fd3b417
+v11-tracker-on  cce0f1ac3dda17328523f744cebc933c688c539c

$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

3 v11-* fixtures drifted (v11-realistic-ot, v11-flat-file, v11-tracker-on); all expected because `project-template/docs/pack/PM-CHAT.md` is v11-surface and was edited in Step 3. v10-* fixtures unchanged (tag-pinned per `test-fixtures/README.md` § Determinism). Pack Chat stages `test-fixtures/manifest.txt` alongside scope edits per RC9.

---

## §7 Plan deviations

**ZERO deviations from plan §2.3.**

Sub-notes (not deviations, just observations):

- **Step 2 produced zero script edits** (not a deviation — plan §2.3.2 listed the scripts as the EXPECTED set of script-edit candidates and the coder verifies via grep; zero hits means the candidates didn't actually contain references at HEAD `fc1a136`). The plan §2.3.4 verification step 7 (`bash scripts/dry-run-migration.sh --help` runs cleanly) passes regardless.
- **Total files modified in working tree (excluding the 3 git-mv'd) = 5** (4 LIVE refs + manifest), matching plan §2.3.2 "Total: ~7-9 files (3 git-mv + 2-3 scripts + 1-3 live maintenance-docs/v11-implementation/ refs + manifest)" with the scripts/maintenance-docs split landing at 0/0 instead of 2-3/1-3 — net within plan's ~7-9 range envelope (3+0+4+1 = 8 files).
- **`maintenance-docs/v11-implementation/` LIVE-ref count = 0** at this HEAD (plan anticipated 1-3 possible). The architect-fix-pass cycles (A-fix S1, B-fix-v2 §16, C-fix) plus Phase 3 verification confirmed architect docs were already correctly named at the post-move paths, so no LIVE refs survived in that surface for Commit 3 to touch.

---

## §8 New OQs

**None.** No new OQs surfaced during execution.

Three observations that are NOT new OQs (resolved within plan scope):

1. **Plan §2.3.2 listed `scripts/migrate-v10-to-v11.sh` and `scripts/dry-run-migration.sh` as candidate script edits.** Neither contains references to the moved paths at HEAD `fc1a136`. Plan §2.3.3 framing ("update `scripts/migrate-v10-to-v11.sh` + `scripts/dry-run-migration.sh` references; full grep") explicitly authorized the grep verification, which returned zero. Plan §2.3.5 "Trinity implications: None" remains correct. No surfacing needed.

2. **`pack-ops/BACKLOG.md` has 11 line hits to `supporting-docs/{MERGE-STRATEGY,DRY-RUN-MIGRATION,CONCEPTUAL-REVIEW-METHODOLOGY}.md`** — all inside specific BD entries (File/Symbol, Description, Resolved, Type) describing past or planned work at entry-write time. Per per-entry source-of-truth contract + CLAUDE.md "Per-entry trees vs mirrors — mode-dependent source of truth," these are HISTORICAL records. Treating them as LIVE refs to update would falsify the historical record (an OT-style "we cleaned up paths in history" anti-pattern). Decision: LEAVE UNCHANGED, consistent with §6.4 FROZEN doctrine applied to per-entry mirror artifacts.

3. **The `git mv` command shown in `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md:160` is instructional** ("Use `git mv supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` to preserve file history"). It names BOTH source and destination, where the source path is correctly named as the pre-move path. The instruction is for the coder (who reads it and executes it). Updating it post-move would render the instruction nonsensical (a `git mv pack-ops/X pack-ops/X` no-op). LEAVE UNCHANGED is the only sensible decision.

---

## §9 PREFLIGHT line

```
PREFLIGHT: 4/4 in-scope file edits complete (4 LIVE ref updates: QUICKSTART.md, pack-ops/OPTIONAL-FEATURES.md, pack-ops/PACK-CHAT.md, project-template/docs/pack/PM-CHAT.md) + 3 git mv renames + 1 manifest regen; verification PASS (validate-pack.py 33 checks PASS; pack-ops/ shows 12 files; supporting-docs/ shows 10 files; zero LIVE non-historical hits in repo-wide grep; dry-run-migration.sh --help runs cleanly); HEAD fc1a136bf01449f2c482c2521a0f4261847e88b9; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md
```

(Emitted before IMPL-REPORT write per pack memory `feedback_pack_coder_preflight_pattern`.)

---

## §10 Definition-of-Done checklist

| # | DoD item | Status | Evidence |
|---|---|---|---|
| 1 | All 3 supporting-docs files relocated via `git mv` (history preserved) | PASS | §2 Step 1; `git status` shows `R` markers |
| 2 | Destination is `pack-ops/` (NOT `maintenance-docs/`) per Override 6 | PASS | §2 Step 1 paths; `ls pack-ops/` shows all 3 new files |
| 3 | Content preserved byte-identical during move | PASS | `git mv` semantics; no content edits applied |
| 4 | Scripts updated where references existed | PASS (vacuously) | §2 Step 2 — zero script refs at HEAD; verification §4.7 confirms script runtime |
| 5 | LIVE pack-side cross-references updated to `pack-ops/` paths | PASS | §2 Step 3; 4 LIVE refs updated |
| 6 | HISTORICAL refs left unchanged (per §6.4 FROZEN / §6.5 case-by-case) | PASS | §5 triage; 47 files left unchanged with rationale |
| 7 | Trinity verification (zero refs to moved files in pack-root trinity) | PASS | §2 Step 4; zero hits |
| 8 | test-fixtures/manifest.txt regenerated per RC9 | PASS | §2 Step 5; §6 diff non-empty |
| 9 | All verification commands run; results captured in IMPL-REPORT | PASS | §4 |
| 10 | No state-changing git verbs beyond `git mv` | PASS | HEAD unchanged at `fc1a136`; only read-only verbs + `git mv` used |
| 11 | IMPL-REPORT written to specified path | PASS | This file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md` |
| 12 | PREFLIGHT line emitted before IMPL-REPORT write | PASS | §9 |

**All 12 DoD items PASS.**

---

## §11 Files-changed inventory (Pack Chat staging set)

| Path | Change type |
|---|---|
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | deleted (via `git mv`) |
| `supporting-docs/DRY-RUN-MIGRATION.md` | deleted (via `git mv`) |
| `supporting-docs/MERGE-STRATEGY.md` | deleted (via `git mv`) |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | new (via `git mv`) |
| `pack-ops/DRY-RUN-MIGRATION.md` | new (via `git mv`) |
| `pack-ops/MERGE-STRATEGY.md` | new (via `git mv`) |
| `QUICKSTART.md` | modified (L41 LIVE ref update) |
| `pack-ops/OPTIONAL-FEATURES.md` | modified (L214 LIVE ref update) |
| `pack-ops/PACK-CHAT.md` | modified (L227 LIVE ref update) |
| `project-template/docs/pack/PM-CHAT.md` | modified (L401 LIVE ref update) |
| `test-fixtures/manifest.txt` | modified (v11-* fixture SHAs regenerated per RC9) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md` | new (this report) |

Total: 3 renames (6 path-changes in git terms) + 4 modifications + 1 manifest + 1 new IMPL-REPORT = 12 path changes; Pack Chat stages all 12 for the Commit-3 commit.

---

## §12 Cross-references

- Plan: `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` §2.3
- Authority: `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 6
- Architect-fix v2: `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §11.3 step 3 + §16 cascade closure
- Architect B: `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §4.1 + §6.5
- Architect A: `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V4 implementation hint step 4
- Pack memory: `CLAUDE.md` § "Pack memory" → "Regenerate test-fixtures/manifest.txt on every v11-surface commit" + "Per-entry trees vs mirrors — mode-dependent source of truth" + `feedback_pack_coder_preflight_pattern` + `feedback_agents_never_commit`
- Predecessor commits: Commit 1 (`pack-ops/` scaffold) + Commit 2 (M1-M5 + M9-M10 root → `pack-ops/` MOVES) + Commit 2-fix + Commits BD-176 + BD-177 (per Pack Chat orchestration)
- Successor: parallel set ALPHA-EXPANDED (Commits 4, 5, 6, 7, 8, 9a, 11 per OQ-1 RESOLVED Path A) spawn after this Commit 3 lands per plan §8.2.1

---

*End of IMPLEMENTATION-REPORT-BD-175-COMMIT-3.md*
