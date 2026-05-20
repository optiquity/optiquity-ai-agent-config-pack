# PACK-REVIEW-BD-175-F1

**Commit reviewed:** `88a0aea1f086266460f6966500ffff175297176e`
**Branch:** `v11-dev`
**Review date:** 2026-05-19
**Reviewer:** pack-reviewer (independent assessment)
**Scope:** Per-commit review of BD-175 F1 — qualify 3 sibling bare refs
in `pack-ops/MERGE-STRATEGY.md` cross-references list.

---

## §1 Verdict

**GO** — 0 BLOCKER / 0 MUST / 0 SHOULD / 1 NIT.

F1 cleanly resolves the deferred SHOULD finding from
`PACK-REVIEW-BD-175-COMMIT-9B.md`. The two REPLACE edits land
mechanically at L471 and L474 with surrounding prose untouched; L473
`QUICKSTART.md` is correctly left bare (file IS at pack root); L472
`docs/pack/OPTIONAL-FEATURES.md` is correctly preserved from Commit
9b's edit; commit scope is exactly the 2-line edit + IMPL-REPORT;
no manifest regen needed (pack-ops/ is not v11-surface under
current strict RC9); no out-of-scope edits to the 8 inline-prose
bare refs (which Pack Chat triage folded into BD-179 scope). The
single NIT is an out-of-scope ecosystem observation about the
audience-mismatch on L472 — flagged for visibility only, not
proposed for F1 fix.

---

## §2 Independent findings (per-scope-area assessment)

Scope items 1-7 from the prompt are evaluated in order. All seven
PASS the success criteria.

### Scope item 1 — Two REPLACE edits applied correctly

**PASS.** The post-edit file at `pack-ops/MERGE-STRATEGY.md` L466-474
reads:

```
## Cross-references

- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
- `QUICKSTART.md` — where to start
- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

- L471: now `` `supporting-docs/MIGRATION-v10-to-v11.md` `` —
  qualification matches the actual file location (verified by `ls`).
  Surrounding prose ` — the user-facing migration narrative`
  unchanged.
- L474: now `` `scripts/validate-pack.py` `` — qualification matches
  the actual file location. Surrounding prose ` Check 25 — CI
  regression guard for the truthful-report contract` unchanged.

Diff confirms exactly 2 insertions and 2 deletions, no other prose
touched (see §5 V1 below).

### Scope item 2 — L473 `QUICKSTART.md` correctly LEFT bare

**PASS.** `ls QUICKSTART.md` succeeds at pack root (verified). The
bare reference `` `QUICKSTART.md` `` is precision-accurate. Editing
it would introduce a regression in precision (e.g.,
`some-subdir/QUICKSTART.md` would point to a non-existent path).
The coder's restraint here is correct.

### Scope item 3 — L472 `docs/pack/OPTIONAL-FEATURES.md` unchanged

**PASS.** L472 reads `` `docs/pack/OPTIONAL-FEATURES.md` — tracker
opt-in walkthrough `` — byte-identical to Commit 9b's edit (verified
against `git show ee9b385 -- pack-ops/MERGE-STRATEGY.md`). The F1
diff (`git show 88a0aea -- pack-ops/MERGE-STRATEGY.md`) shows L472
untouched. See §6 for an audience-mismatch NIT noted but explicitly
outside F1 triage scope.

### Scope item 4 — Single file scope

**PASS.** `git show 88a0aea --stat` confirms exactly 2 files
modified:

- `pack-ops/MERGE-STRATEGY.md` (+2 / -2)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F1.md`
  (new, 348 lines)

Net commit: 350 insertions, 2 deletions. No other file touched.

### Scope item 5 — No bare refs remain in cross-references list; 8 inline-prose hits untouched

**PASS — both halves.**

Cross-references list (L470-480) is clean of bare refs to
`MIGRATION-v10-to-v11.md` or `validate-pack.py`:

```
$ grep -n "\`MIGRATION-v10-to-v11\.md\`\|\`validate-pack\.py\`" pack-ops/MERGE-STRATEGY.md
270:`validate-pack.py` Check 32 (mirror-in-sync) CI gate catches any
271:committed divergence. See `MIGRATION-v10-to-v11.md` § "Per-entry
313:`MIGRATION-v10-to-v11.md` § "Skill model changes" for the
329:§ "Monorepo D5 scoping note" and in `MIGRATION-v10-to-v11.md`
412:  positions, and `validate-pack.py` passes against the pack source.
426:`MIGRATION-v10-to-v11.md` Step 1's exit-codes table.
440:  `MIGRATION-v10-to-v11.md` §Rollback. (Note: the legacy
479:> `HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips
```

8 inline-prose hits remain (5 `MIGRATION-v10-to-v11.md`: L271, L313,
L329, L426, L440; 3 `validate-pack.py`: L270, L412, L479). All 8 are
outside the L470-480 Cross-references list region. The L226
narrative-shorthand `validate-pack Check 8` (no backticks, no
extension) was also untouched. Matches IMPL-REPORT §6 inventory
exactly (8 backticked inline + 1 unbacked shorthand = 9 total
out-of-scope observations).

All 8 (and the L226 shorthand) folded into BD-179 architect-pass
scope per user-approved triage 2026-05-19 (memory anchor
`project_bd175_bd179_architect_preapproved.md`).

### Scope item 6 — No manifest regen needed

**PASS.** `git show 88a0aea --stat | grep -i manifest` shows the
match only in the commit message body (which mentions "No manifest
regen — pack-ops/ not v11-surface under current strict RC9"). The
`--name-only` listing shows exactly 2 files: `pack-ops/MERGE-STRATEGY.md`
and `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F1.md`.
`test-fixtures/manifest.txt` is NOT in the commit. Correct: per
current strict RC9 codified at CLAUDE.md, manifest regen triggers
only on `project-template/` or `scripts/` edits. `pack-ops/` falls
outside that trigger glob. (BD-176 may expand this — explicitly
out of F1 scope.)

### Scope item 7 — No state-changing operations beyond the 2-line edit + IMPL-REPORT

**PASS.** Diff shows only 2 lines changed in `pack-ops/MERGE-STRATEGY.md`
(L471 and L474), plus the new IMPL-REPORT. No new BD opened, no
files renamed or deleted, no tag changes, no script changes. The
coder's IMPL-REPORT §6 explicitly states it does NOT propose
deferral or open a new POQ — surfacing only. Confirms scope
discipline.

---

## §3 Compare-to-IMPL-REPORT

After forming my independent findings above, I read
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F1.md`.

**Alignment:** Full. The IMPL-REPORT's verification evidence (V1-V6
in §5; the DoD checklist in §7-area; the §6 out-of-scope inventory)
matches my independent observations line-for-line:

- Same 2 edits (L471 + L474) with same BEFORE / AFTER quotes
- Same L473 / L472 non-edit rationales (QUICKSTART at root;
  OPTIONAL-FEATURES preserved from Commit 9b)
- Same 8 inline-prose hit inventory (L271/L313/L329/L426/L440 for
  MIGRATION; L270/L412/L479 for validate-pack) plus L226 shorthand
  and L479 HELP-FRAGMENT-PACK.md flag
- Same scope discipline (no manifest regen, no new POQ, no out-of-
  scope edits)
- PREFLIGHT line emitted at IMPL-REPORT §7 with HEAD SHA
  `8f6ce51bf1e864062f00d2e3a85769f5e12732dd` (the parent-HEAD at
  agent start — agent does not commit, so this matches Pack-Chat's
  subsequent commit at `88a0aea` with this F1 work folded in)
- All 14 DoD checkboxes marked PASS with verifiable evidence

**No discrepancies.** The IMPL-REPORT is faithful to the diff.

---

## §4 Severity-classified findings table

| Severity | Count | Notes                                                                      |
|----------|------:|----------------------------------------------------------------------------|
| BLOCKER  |     0 | —                                                                          |
| MUST     |     0 | —                                                                          |
| SHOULD   |     0 | —                                                                          |
| NIT      |     1 | Audience-mismatch observation about L472 (see §6); out of F1 scope          |

---

## §5 Verification commands run + output

### V1. Commit metadata + diff

```
$ git rev-parse HEAD
88a0aea1f086266460f6966500ffff175297176e

$ git show 88a0aea --stat
... (full output captured; relevant tail:)
 .../IMPLEMENTATION-REPORT-BD-175-F1.md             | 348 +++++++++++++++++++++
 pack-ops/MERGE-STRATEGY.md                         |   4 +-
 2 files changed, 350 insertions(+), 2 deletions(-)

$ git show 88a0aea -- pack-ops/MERGE-STRATEGY.md
... (diff hunk shows exactly 2 lines changed:)
@@ -468,10 +468,10 @@ default behavior):
 - `scripts/lib/customization-preserve.sh` — the BD-088 implementation
 - `scripts/lib/customization-report.sh` — the report renderer
 - `scripts/tests/test-customization-preserve.sh` — class-coverage tests
-- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
+- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
 - `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
 - `QUICKSTART.md` — where to start
-- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
+- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

### V2. File-location verifications

```
$ ls QUICKSTART.md supporting-docs/MIGRATION-v10-to-v11.md scripts/validate-pack.py docs/pack/OPTIONAL-FEATURES.md
QUICKSTART.md
scripts/validate-pack.py
supporting-docs/MIGRATION-v10-to-v11.md
ls: docs/pack/OPTIONAL-FEATURES.md: No such file or directory
```

- `QUICKSTART.md` — exists at pack root → L473 bare ref is precision-accurate. PASS
- `supporting-docs/MIGRATION-v10-to-v11.md` — exists → L471 qualification correct. PASS
- `scripts/validate-pack.py` — exists → L474 qualification correct. PASS
- `docs/pack/OPTIONAL-FEATURES.md` — does NOT exist in pack-repo
  (the actual file is at `pack-ops/OPTIONAL-FEATURES.md`; the
  `docs/pack/` path is the **post-SPLIT project-side** path created
  in client repos by Commit 10's TASK-T8 SPLIT). This is a Commit 9b
  decision, deliberately preserved in F1; see §6 NIT for the audience-
  mismatch observation.

### V3. Cross-reference list cleanliness (bare-ref grep)

```
$ grep -n "\`MIGRATION-v10-to-v11\.md\`\|\`validate-pack\.py\`" pack-ops/MERGE-STRATEGY.md
270:`validate-pack.py` Check 32 (mirror-in-sync) CI gate catches any
271:committed divergence. See `MIGRATION-v10-to-v11.md` § "Per-entry
313:`MIGRATION-v10-to-v11.md` § "Skill model changes" for the
329:§ "Monorepo D5 scoping note" and in `MIGRATION-v10-to-v11.md`
412:  positions, and `validate-pack.py` passes against the pack source.
426:`MIGRATION-v10-to-v11.md` Step 1's exit-codes table.
440:  `MIGRATION-v10-to-v11.md` §Rollback. (Note: the legacy
479:> `HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips
```

Zero hits in L470-480 (Cross-references list). 8 hits elsewhere
(inline prose) — all out-of-scope per prompt scope item 5 and
IMPL-REPORT §6.

### V4. Inventory of full file's ref tokens

```
$ grep -n "MIGRATION-v10-to-v11\|validate-pack\|OPTIONAL-FEATURES\|QUICKSTART" pack-ops/MERGE-STRATEGY.md
226:the pack never ships `x-`-prefixed scripts (validate-pack Check 8
270:`validate-pack.py` Check 32 (mirror-in-sync) CI gate catches any
271:committed divergence. See `MIGRATION-v10-to-v11.md` § "Per-entry
313:`MIGRATION-v10-to-v11.md` § "Skill model changes" for the
329:§ "Monorepo D5 scoping note" and in `MIGRATION-v10-to-v11.md`
412:  positions, and `validate-pack.py` passes against the pack source.
426:`MIGRATION-v10-to-v11.md` Step 1's exit-codes table.
440:  `MIGRATION-v10-to-v11.md` §Rollback. (Note: the legacy
471:- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
472:- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
473:- `QUICKSTART.md` — where to start
474:- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
479:> `HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips
```

Confirms the post-edit cross-references list (L471-474) plus the
known 9 out-of-scope inline observations from §6 of IMPL-REPORT.

### V5. Audience header verification (relevant to NIT)

```
$ sed -n '1,10p' pack-ops/MERGE-STRATEGY.md
# MERGE-STRATEGY.md — per-file customization preservation contract

> **Audience: pack-internal.** This document is pack-internal reference
> for pack maintainers running the migrator. ...
```

L1-8 explicitly labels the doc "**Audience: pack-internal.**" —
which informs the NIT in §6.

### V6. Commit 9b cross-reference (what was preserved)

```
$ git show ee9b385 -- pack-ops/MERGE-STRATEGY.md
... diff shows Commit 9b changed only L472 (OPTIONAL-FEATURES.md
→ docs/pack/OPTIONAL-FEATURES.md); F1's diff preserves that line
byte-identically.
```

PASS.

---

## §6 Out-of-scope observations

### NIT (out-of-scope; surface for visibility only)

**Audience-mismatch in the cross-references list (L472).**
`pack-ops/MERGE-STRATEGY.md` opens with an explicit
"**Audience: pack-internal.**" header at L3 and an intro paragraph
that this is a document for pack maintainers. The post-F1
cross-references list at L468-474 contains five pack-repo paths
(`scripts/lib/customization-preserve.sh`, `scripts/lib/customization-report.sh`,
`scripts/tests/test-customization-preserve.sh`,
`supporting-docs/MIGRATION-v10-to-v11.md`, `QUICKSTART.md`,
`scripts/validate-pack.py`) and one **post-install project-side
path** (`docs/pack/OPTIONAL-FEATURES.md`, which does not exist in
the pack-repo — the pack-repo copy is at `pack-ops/OPTIONAL-FEATURES.md`).

For a pack-internal-audience document, every cross-ref ideally
resolves at a pack-repo path. The L472 path is the right path for
the **client-installed** audience but the wrong path for the
**pack-maintainer** audience the doc explicitly addresses.

**Why this is NOT a F1 finding:**

- L472 was deliberately preserved by F1 per the user-approved triage
  prompt (scope item 3 explicitly directs "L472 ... unchanged
  (Commit 9b's edit preserved)").
- F1 was scoped to *align siblings to Commit 9b's precision baseline*,
  not to re-litigate the precision baseline itself.
- Pack Chat triage 2026-05-19 already folded systematic bare-ref
  treatment into BD-179's architect-pass scope — this audience-
  consistency question is the natural sibling of that work.

**Disposition recommendation:** Surface to Pack Chat for inclusion
in BD-179's architect-pass scope alongside the 8 inline-prose bare
refs. The architect can decide between (a) qualifying L472 to
`pack-ops/OPTIONAL-FEATURES.md` for audience-internal consistency,
(b) adding inline gloss like `docs/pack/OPTIONAL-FEATURES.md`
(installed location — pack-repo source at `pack-ops/`), or (c)
keeping as-is with rationale. Per OQ-1 (rewritten EXECUTION-PLAN
§B), any new BD-open requires explicit user-discussion-and-approval;
this observation does NOT propose a new BD but does surface the
question for the BD-179 architect to consider as part of an already-
approved scope.

### Other observations (also out of F1 scope; already noted in
IMPL-REPORT §6)

- 8 inline-prose bare refs at L270/L271/L313/L329/L412/L426/L440/L479
  — folded into BD-179 architect-pass scope per user-approved triage.
- L226 narrative shorthand `validate-pack Check 8` (no backticks, no
  extension) — also folded into BD-179.
- L479 `` `HELP-FRAGMENT-PACK.md` `` bare ref — surfaced by IMPL-REPORT
  §6 as a flag for future cross-reference audits; not F1 scope.

These are all in the BD-179 architect-pass funnel and do not
constitute findings against F1.

---

## §7 Summary

F1 lands cleanly: tight scope, correct edits at exactly the two
intended lines, correct restraint on the L473 and L472 non-edits,
correct restraint on the 8+1 inline-prose out-of-scope observations
(documented in IMPL-REPORT §6 for visibility but not touched), no
manifest regen (correctly identified as not required under current
strict RC9), no state-changing operations beyond the in-scope edit
and IMPL-REPORT write. The IMPL-REPORT is faithful to the diff and
its verification evidence is auditable.

**Verdict: GO.** No fixes required to ship F1. The single NIT is an
out-of-scope ecosystem observation surfaced for Pack Chat / user
visibility — not a F1 defect, and natural fit for BD-179's already-
approved architect-pass scope.
