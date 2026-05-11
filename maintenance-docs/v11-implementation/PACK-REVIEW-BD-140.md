# PACK-REVIEW-BD-140 — Skill-dimensions reframe BACKLOG entries (Batch 1 of 11)

**Reviewer:** pack-reviewer
**Date:** 2026-05-11
**Branch:** v11-dev
**Scope:** BD-140 batch — append 16 BD entries (BD-140..BD-155) to `BACKLOG.md`.
**Inputs read:** `BACKLOG.md`; `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md`; `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`. Per pack convention, no prior review reports were consulted.

---

## 1. Verdict

**Findings — fixes recommended, user decides.**

There are **no BLOCKER defects.** Coverage, blocker chain, references, and validator are all clean. Two SHOULD-FIX findings concern the `Status: Deferred` choice for BD-151..BD-155 (the spec literal text says `Status: Open`), and the structural placement of those five `Deferred` entries inside the `## Active — v11 Scope` section rather than the existing `## Deferred` H2 section (which is where the prior `Status: Deferred` precedent BD-055..BD-058 lives). Both are interpretive deviations from the plan, and either is defensible — the user should decide whether to keep, revert to spec literal, or relocate.

Two NIT findings concern in-block ordering and the `Type:` annotation extension, neither of which break tooling.

---

## 2. Coverage check

All 16 BDs are present and contiguous (BD-140..BD-155).

```
$ grep -cE "^\*\*BD-(14[0-9]|15[0-5]) " BACKLOG.md
16
```

Pre-batch highest BD = BD-139 (line 1515). New highest = BD-155 (line 1339). No gaps; no duplicates; no collisions with existing numbers.

Titles correspond row-for-row with `PLAN-SKILL-DIMENSIONS.md` §3 (BACKLOG additions table, lines 819-836). Wording was lengthened in several places for File/Symbol clarity (e.g. BD-147 title gains "+ Check 26 extension + BD-119 docs update"; BD-149 title gains "(no skill renames)") — those are clarifying extensions consistent with surrounding existing-BD title style (compare BD-139 title "BD-104 audit fix-follow (1 MAJOR + 2 MINOR + 2 NIT)" at line 1515). No substantive scope drift detected.

---

## 3. Format conformance

Sampled five existing Open / Resolved entries (BD-060 lines 33-44, BD-122 lines 1318-1335, BD-128 lines 1727-1737, BD-138 lines 1531-1540, BD-139 lines 1515-1527) and two existing Deferred entries (BD-055 lines 3417-3436, BD-057 lines 3461-3483).

**Heading style.** All existing entries use `**BD-NNN — Title**` (bold on a single line, em-dash separator). All 16 new entries match. No `## BD-NNN` headings used. `---` separators between entries match.

**Field order.** Existing entries use: `Type:` → `Status:` → `Blockers:` → `Unblocks:` → `File/Symbol:` → `Description:` → `Resolved:`. All 16 new entries match field order exactly.

**`Type:` value.** Existing convention is `Type: TODO(version)` followed by an optional em-dash annotation — see BD-138 ("— surfaced 2026-05-10 ..."), BD-139 ("— fix-follow per standing rule §5.B ..."), BD-127 ("— v10.1 backport ..."). All 16 new entries follow this pattern; none use `TODO(v11.0)` or `TODO(v12)` distinctions. **Conformant.**

**`Resolved:` line.** Existing Open entries leave `Resolved:` empty (e.g. BD-138 had `Resolved:` empty before flip to Resolved). Existing Deferred entries use `Resolved: n/a` (BD-055..BD-058, BD-031). New entries:
- BD-140..BD-150 (Open): `Resolved:` empty — conformant.
- BD-151..BD-155 (Deferred): `Resolved: n/a` — conformant with deferred-entry precedent.

**Blank-line separators.** All 16 new entries surrounded by `---` separators with one blank line on each side. Conformant.

**`Status: Deferred` semantics — divergence from spec literal text.** PLAN-SKILL-DIMENSIONS.md §2 Batch 1 implementation step 3 (line 124-126) reads: "Each entry: **Status: Open**. Blockers: v12. Description: motivation paragraph plus a one-line pointer to its architecture-doc section." The coder applied `Status: Deferred` instead, citing BD-055..BD-058 precedent. The §3 BACKLOG additions table column "Classification" reads `Open / Deferred to v12` (ambiguous between "Status: Open with v12 deferral noted in Blockers" and "Status: Deferred"). See SHOULD-FIX-1 below.

---

## 4. Blocker chain check

| BD | Spec critical-path Blockers | Actual entry Blockers | Match |
|----|----------------------------|------------------------|-------|
| BD-140 | None | none | ✓ |
| BD-141 | BD-140 | BD-140 | ✓ |
| BD-142 | BD-141 | BD-141 | ✓ |
| BD-143 | BD-142 | BD-142 | ✓ |
| BD-144 | BD-142 | BD-142 | ✓ |
| BD-145 | BD-141, BD-142 | BD-141, BD-142 | ✓ |
| BD-146 | BD-142, BD-143 | BD-142, BD-143 | ✓ |
| BD-147 | BD-142 | BD-142 | ✓ |
| BD-148 | BD-142, BD-143 | BD-142, BD-143 | ✓ |
| BD-149 | BD-142 | BD-142 | ✓ |
| BD-150 | BD-146, BD-148 | BD-146, BD-148 | ✓ |
| BD-151..BD-155 | v12 | v12 (with rationale) | ✓ |

All 16 entries' `Blockers:` fields encode the critical-path diagram in `PLAN-SKILL-DIMENSIONS.md` §1 correctly. No mismatches.

The `Unblocks:` fields are consistent with the inverse of the chain (e.g. BD-140's `Unblocks: BD-141..BD-150`; BD-142's `Unblocks: BD-143, BD-144, BD-145, BD-146, BD-147, BD-148, BD-149` — all the BDs whose `Blockers:` field references BD-142). No reverse-chain inconsistencies surfaced.

---

## 5. Reference spot-check

Sampled 5 entries' architecture-doc / plan-doc / file references:

1. **BD-141** cites `ARCHITECTURE-SKILL-DIMENSIONS.md §7.5` and `PLAN-SKILL-DIMENSIONS.md §2 Batch 2`. Both exist (architecture line 877 — "Risk — `python-data-architecture` predicate is fuzzy"; plan line 147 — "Batch 2 — BD-141"). File refs `scripts/lib/detect.sh`, `scripts/init-project.sh`, `scripts/add-capability.sh` all exist on disk.
2. **BD-142** cites `ARCHITECTURE-SKILL-DIMENSIONS.md §3-§5` and `PLAN-SKILL-DIMENSIONS.md §2 Batch 3 + §4.4`. All exist. File ref `project-template/docs/pack/PLATFORM-SKILLS.md` exists. The "lines 310-345" range cited in File/Symbol matches PLAN §4.4 line 879 ("do not edit lines 310-345").
3. **BD-146** cites `PLAN-SKILL-DIMENSIONS.md §2 Batch 7` and `ARCHITECTURE-SKILL-DIMENSIONS.md §3-§5 + §3.7-§3.8`. All exist. The "Check 31" identification matches plan §0 PLANNER NOTE (line 28-33: "Next free integer = Check 31"). Validator does NOT yet have a Check 31 (highest is Check 30) — verified independently — so BD-146's NEW-Check claim is accurate.
4. **BD-147** cites `ARCHITECTURE-SKILL-DIMENSIONS.md §6.5` and `PLAN-SKILL-DIMENSIONS.md §2 Batch 8 + §7.2`. All exist. References `scripts/migrate-v10-to-v11.sh` (exists) and `scripts/lib/migrator-skills.sh` as NEW (forward-declared per pack convention — acceptable). References Check 26 extension — Check 26 is "BD-119 migrator-framework inventory" (validate-pack.py line 1783-1811), which is the correct check to extend per plan §2 Batch 8.
5. **BD-155** cites `ARCHITECTURE-SKILL-DIMENSIONS.md §7.10`. Exists (line 953 — "Risk — naming inconsistency: `*-best-practices` vs `*-language` vs `*-architecture` vs `*-patterns`"). References `scripts/lib/migrator-skills.sh` as a v12 reuse target (forward-declared, BD-147 deliverable) — acceptable.

All five spot-checks PASS. File/Symbol fields name files that exist or are explicitly forward-declared NEW per pack convention.

---

## 6. Scope discipline

```
$ git diff --stat HEAD
 BACKLOG.md | 176 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 176 insertions(+)
```

Single file modified. The implementation report `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-140.md` is also untracked-new, but that is the report itself — not a scope violation per the prompt's note.

```
$ git diff HEAD -- BACKLOG.md | grep "^-" | grep -v "^---"
(no output)
```

**Pure additions; zero deletions.** No edits to existing entries. Conformant with the "append-only" spec.

No TD-TBD sentinels introduced (`grep "^+" diff | grep -i "TD-TBD"` empty). Check 3 of validate-pack.py is therefore not at risk.

---

## 7. Validator output

```
$ python3 scripts/validate-pack.py
... (all 30 checks executed) ...
============================================================
PASSED — all checks clean
```

Re-ran independently. PASSES. No new warnings. No regressions.

---

## 8. Findings list

### SHOULD-FIX-1 — `Status: Deferred` deviates from spec literal text for BD-151..BD-155

**Location:** `BACKLOG.md` lines 1341, 1352, 1363, 1374, 1385 (the five `Status: Deferred` lines for BD-151..BD-155).

**Issue.** `PLAN-SKILL-DIMENSIONS.md` §2 Batch 1 implementation step 3 (line 124) explicitly says: "Each entry: Status: Open. Blockers: v12." The coder applied `Status: Deferred`, citing the BD-055..BD-058 precedent (those entries do use `Status: Deferred`). The §3 classification table column reads `Open / Deferred to v12`, which is ambiguous — it could be read as "Open status, deferred classification noted in Blockers" or as "Deferred status".

The two precedents conflict:
- **Spec literal** (PLAN §2 Batch 1 step 3): `Status: Open`, deferral noted in `Blockers:` field.
- **Pack precedent** (BD-055..BD-058 in `## Deferred` section): `Status: Deferred`, with `Resolved: n/a`.

The coder picked the pack-precedent interpretation but only partially — see SHOULD-FIX-2 below.

**Proposed resolutions (user picks):**
- (A) Keep `Status: Deferred` and ALSO move BD-151..BD-155 into the `## Deferred` H2 section (lines 3397+), matching BD-055..BD-058's full pattern. Resolves SHOULD-FIX-2 simultaneously.
- (B) Revert to `Status: Open` per spec literal text. Keep entries in the v11 Active section. The deferral is then expressed only via `Blockers: v12 — ...`. Resolves SHOULD-FIX-2 simultaneously.

### SHOULD-FIX-2 — `Status: Deferred` entries placed in `## Active — v11 Scope` section, not the `## Deferred` H2 section

**Location:** `BACKLOG.md` lines 1339-1390 (the five v12-deferred entries) sit inside the `## Active — v11 Scope` section (which begins at line 23 and runs to line 1913). The repo's existing `## Deferred` H2 section starts at line 3397 and currently contains BD-031, BD-055, BD-056, BD-057, BD-058.

**Issue.** Internal-consistency mismatch: an entry with `Status: Deferred` lives inside `## Active`. The pack-precedent BD-055..BD-058 entries have `Status: Deferred` AND live in the `## Deferred` section together. The coder's choice mixes two precedents.

**Proposed resolutions:** see SHOULD-FIX-1 — both fixes resolve simultaneously by either moving the entries to `## Deferred` (option A) or flipping `Status:` to `Open` (option B).

### NIT-1 — In-block ordering: new entries are descending (BD-155 → BD-140); preceding block is ascending (..BD-122)

**Location:** `BACKLOG.md` line 1335 (BD-122 = Resolved, last entry before new block) → lines 1339-1402 (new block descending BD-155 → BD-140) → line 1515 (BD-139, descending block start).

**Issue.** The `## Active — v11 Scope` section is monotonically ascending through BD-122 (line 1318), then jumps to BD-139 (line 1515) and runs descending through BD-123 (line 1889). The new block (BD-155 → BD-140 in descending order) is inserted at the seam. The ordering direction inside the new block (descending) matches the immediately-following BD-139 → BD-123 descending block, but creates a non-monotonic sequence at the BD-122 → BD-155 boundary (122 < 155).

In strict monotonic-ascending convention, new entries would slot in as BD-140 → BD-155 ascending, placed AFTER BD-139 (which is currently the last v11 number before the descending block reverses). In strict monotonic-descending convention, the descending block (BD-139 → BD-123) would have started higher (at the new BD-155).

**Proposed resolution.** No required action — pack convention is not strict on ordering. If the user wants to tidy, the cleanest layout is to relocate the block to immediately above BD-139 (so the descending sequence reads BD-155 → BD-140 → BD-139 → BD-138 → ... → BD-123 monotonic descending), which would also push the BD-122 → ... → BD-060 ascending block to live as a separate temporal cluster (a v11.0 in-progress vs initial-v11-design split, which already exists implicitly).

### NIT-2 — `Type: TODO(version)` annotation lengthens vs the BD-055..BD-058 deferred-entry precedent

**Location:** `BACKLOG.md` lines 1340, 1351, 1362, 1373, 1384 (the `Type:` lines for BD-151..BD-155). Each reads: `Type: TODO(version) — surfaced 2026-05-11 during skill-dimensions reframe planning (per ... §7.X deferral disposition); recorded as part of BD-140 batch`.

**Issue.** BD-055..BD-058 use bare `Type: TODO(version)`. The new deferred entries' annotation is consistent with the v11.0 active-batch precedent (BD-138, BD-139 add similar em-dash annotations to `Type:`) but lengthier than the deferred-entry precedent.

**Proposed resolution.** None required. The annotation provides useful provenance and is consistent with the modern pack-repo style (BD-127 onward).

---

## 9. Verdict rationale

The batch is structurally and substantively correct. All 16 BDs are present and contiguous; all 11 Open-batch entries have correct blocker chains matching the critical-path diagram in PLAN §1; all referenced architecture-doc / plan-doc sections and file paths exist or are properly forward-declared as NEW; the validator passes; and the diff is pure-append on a single file with no edits to existing entries and no TD-TBD sentinels. The two SHOULD-FIX findings concern the same interpretive choice — whether `Status: Deferred` (per BD-055..BD-058 precedent) or `Status: Open` with v12 deferral noted in Blockers (per the spec's literal Batch 1 step 3 wording) is the correct treatment for BD-151..BD-155 — and this is best resolved by user judgment in one stroke (either keep Deferred and relocate to `## Deferred` H2 section, or flip to Open and keep in place). Neither choice blocks the downstream BD-141..BD-150 batches from executing; the blocker chain is unchanged either way. The two NITs are stylistic and require no action.

---

## 10. Doc path confirmation

`maintenance-docs/v11-implementation/PACK-REVIEW-BD-140.md` written.
