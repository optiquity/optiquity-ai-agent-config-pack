# IMPLEMENTATION-REPORT: Groupings amendment §5.1 (inter-grouping cycle detection)

## Metadata

- **Branch:** v11-dev
- **HEAD SHA (pre-edit baseline):** `a9d593f2680c708fd8cd762c09dc3d123ffefec8`
- **Agent:** pack-coder
- **Date:** 2026-05-24
- **Source amendment:** `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §5.1
- **User approval:** 2026-05-24 (amendment landed in v11.1+ scope; no v11.0 deferral)

## Files edited

| File | Lines before | Lines after | Delta |
|---|---|---|---|
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | 908 | 917 | +9 |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | 910 | 911 | +1 |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | 156 | 157 | +1 |
| **Totals** | **1974** | **1985** | **+11** |

Git diff stat:
```
maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md  |  1 +
maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md            | 15 ++++++++++++---
maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md    |  1 +
3 files changed, 14 insertions(+), 3 deletions(-)
```

(The +9 in REQUIREMENTS line-count vs +12 net-add in diff-stat reflects the `--- / +++ /  unchanged` accounting in `git diff --stat`; the source-of-truth is `wc -l` deltas above.)

## Placement decisions

### SC1: Where the new SC lands in Capability #13

**Decision:** Inserted as **SC13.22** under a new sub-heading **"Dependency-graph integrity (from §5.1 amendment to PLANNING-PROCESS-INSIGHTS-FROM-OT.md, user-approved 2026-05-24)"** appended at the end of Capability #13's success-criteria sequence (after the existing **Test fixtures** sub-section, before the **User-approved design decisions** sub-list).

**Rationale considered (3 options):**

1. **(Chosen) Append as SC13.22 in new sub-section at end of SC list, before User-approved design decisions.** Non-invasive (no renumbering of existing SC13.15-SC13.21). The new sub-heading "Dependency-graph integrity" makes the rule category explicit and parallel to existing sub-headings (Membership rule enforcement / Schema enforcement / Per-stream contract / Tracker config / Degenerate state / STATUS.md content / Infrastructure parity / Test fixtures). Adding a dedicated sub-heading also makes the §5.1 amendment provenance immediately visible to future readers (the heading carries the source citation).

2. **(Rejected) Insert as SC13.5.5 near membership-rule SCs.** Would have required intermediate `SC13.5.5` numbering breaking the integer sequence, OR renumbering SC13.5-SC13.21. The cycle detection check is structurally a graph-integrity check across MULTIPLE groupings (not a membership-rule check within ONE grouping per SC13.1-SC13.4) — the placement would have been a logical mismatch even before the renumbering cost.

3. **(Rejected) Append as bare SC13.22 with no sub-heading.** Would have placed the cycle-detection SC under the visual category of "Test fixtures" (the last existing sub-heading), which is wrong — cycle detection is a rule-enforcement criterion, not a fixture criterion. A new sub-heading was needed to break the visual grouping.

**Insertion point (file line numbers post-edit):**
- Sub-heading: line 634
- SC13.22 body: line 636

### SC2: Sub-list (b) count update

**Status:** PASS — count updated from "2 new mandatory checks" to "3 new mandatory checks".

**Before (line 637, pre-edit):**
> (b) Extend 4 existing checks ... + add 2 new mandatory checks (`check_grouping_per_stream_contract`, `check_grouping_membership_integrity`); SKIP conditional Kind-constraint check ...

**After (line 640, post-edit):**
> (b) Extend 4 existing checks ... + add 3 new mandatory checks (`check_grouping_per_stream_contract`, `check_grouping_membership_integrity`, `check_grouping_phase_dependency_cycles` per SC13.22 / §5.1 amendment); SKIP conditional Kind-constraint check ...

Additionally added sub-list item **(d)** at line 642 explicitly documenting the §5.1 amendment provenance and approval date, mirroring the pattern used in Capability #14 sub-list ("STATUS.md unified-dashboard design per user direction 2026-05-23 ..."). This sub-list-item-(d) addition is justified by the rule: when a sub-list represents user-approved design decisions, a new user-approved decision (cycle detection amendment) gets its own entry rather than being silently embedded in an existing entry.

**Function-name choice rationale:** The function name `check_grouping_phase_dependency_cycles` follows the existing pattern `check_grouping_<scope>` per sub-list (b) (consistent with `check_grouping_per_stream_contract` / `check_grouping_membership_integrity`). The architect may rename at architect-pass time per Capability #13 "Architect-level surfaces" → "Exact check function signatures and internal logic"; the name is illustrative-precision-for-planning, not contract.

### SC3: Capability #9 SC9.9 cross-reference

**Status:** PASS — appended to SC9.9 the cross-reference to SC13.22.

**Append text (line 432, post-edit):**
> Cycle-detection infrastructure (Tarjan SCC or equivalent; architect-decided per HANDOFF-V11.1-ARCHITECT.md) is shared with Capability #13 SC13.22 (phase-level dependency cycle validation per §5.1 amendment).

Placement rationale: SC9.9 is the "shared infrastructure" success criterion for Capability #9 (per the SC text itself: "Underlying reverse-lookup + derived-query algorithms are implemented as SHARED INFRASTRUCTURE consumed by both query verbs AND STATUS.md generator"). Adding the cycle-detection share-target there is the natural fit — SC9.9 already commits the verbs to shared infrastructure; SC13.22 references that same infrastructure. The architect choice (Tarjan SCC or equivalent) is named once here and once in HANDOFF, with both naming the same architect-decision surface (consistent vocabulary, no divergence).

## Cross-reference / extra updates beyond the minimum prompt scope

The following enhancements were added to make the amendment self-supporting:

1. **REQUIREMENTS Capability #13 Architect-level surfaces** (line 651) — added bullet "Cycle-detection algorithm choice + persistence model for SC13.22 (see HANDOFF-V11.1-ARCHITECT.md ...)". Rationale: SC13.22 has architect-decided choices (algorithm, persistence); they need to surface in the Architect-level surfaces list so the architect doesn't miss them.

2. **REQUIREMENTS Capability #13 Anchor / cross-references** (lines 654-667) — added 4 new cross-references:
   - Existing TOUCH-POINT entry now annotated with cycle-detection coverage pointer
   - BD-070 (typed-error contract used by SC13.22) — explicit cite
   - #9 SC9.8 / SC9.9 (shared cycle-detection infrastructure) — explicit cite
   - PLANNING-PROCESS-INSIGHTS-FROM-OT.md §4.2 + §5.1 (architect source for SC13.22)
   - HANDOFF-V11.1-ARCHITECT.md (architect choice surface)

3. **REQUIREMENTS Capability #13 sub-list (d)** (line 642) — new sub-list entry explicitly recording the §5.1 amendment provenance + user-approval date. Mirrors Capability #14 pattern.

These supplementary additions are NOT deviations from the prompt — they implement the prompt's SC6 (cross-reference consistency) and SC7 (no verbatim duplication; each doc carries its native role with short citations) at full fidelity rather than minimal-mechanical fidelity.

## Verification commands + outputs

### V1. SC13 count in REQUIREMENTS (expect ≥1 increase)
```
$ grep -c "SC13" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md
32
```
**Result:** PASS — the new SC13.22 plus 7 new cross-references to "SC13.22" (in SC9.9, in sub-list (b), in sub-list (d), in Architect-level surfaces, in 3 separate Anchor / cross-references bullets) substantially increased the SC13 occurrence count.

### V2. Cycle-detection references in REQUIREMENTS
```
$ grep -nE "cycle.detection|Phase-level dependency cycle|SC13.22" \
    maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md
432:- SC9.9. ... Cycle-detection infrastructure (Tarjan SCC or equivalent; architect-decided per HANDOFF-V11.1-ARCHITECT.md) is shared with Capability #13 SC13.22 (phase-level dependency cycle validation per §5.1 amendment).
636:- SC13.22. **Phase-level dependency cycle detection.** Cycles within a grouping's member-phase dependency graph ...
640:- (b) Extend 4 existing checks ... + add 3 new mandatory checks (`check_grouping_per_stream_contract`, `check_grouping_membership_integrity`, `check_grouping_phase_dependency_cycles` per SC13.22 / §5.1 amendment); ...
642:- (d) §5.1 amendment (cycle detection as 3rd new mandatory check) approved 2026-05-24 per architect insight from OT PA-013 worked failure mode ...
651:- Cycle-detection algorithm choice + persistence model for SC13.22 (see HANDOFF-V11.1-ARCHITECT.md "Open architect-level surfaces" entry)
654:- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.H + §10 (validator footprint; §10 carries cycle-detection coverage entry per §5.1 amendment)
658:- BD-070 (typed-error contract used by SC13.22)
662:- #9 SC9.8 / SC9.9 (shared cycle-detection infrastructure with derived-query verbs per SC13.22)
666:- PLANNING-PROCESS-INSIGHTS-FROM-OT.md §4.2 + §5.1 (architect source for SC13.22; OT PA-013 worked failure mode)
667:- HANDOFF-V11.1-ARCHITECT.md "Open architect-level surfaces" (algorithm + persistence choice for SC13.22)
```
**Result:** PASS — body SC at line 636; SC9.9 cross-ref at line 432; sub-list (b) and (d) updates at lines 640+642; Architect-level surfaces at line 651; 4 Anchor / cross-references entries at lines 654, 658, 662, 666-667.

### V3. Cycle-detection references in TOUCH-POINT
```
$ grep -nE "cycle.detection|Phase-level dependency cycle|SC13.22" \
    maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md
853:| Check (phase-level dependency cycles) | `check_grouping_phase_dependency_cycles()` | **Phase-level dependency cycle detection** (new check; covers REQUIREMENTS-GROUPINGS-V11.md Capability #13 SC13.22 per §5.1 amendment) ...
```
**Result:** PASS — new row at line 853 of §10.2 table.

### V4. Cycle-detection references in HANDOFF
```
$ grep -nE "cycle.detection|Phase-level dependency cycle|SC13.22" \
    maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md
53:- **#13 — Phase-level dependency cycle detection algorithm + persistence choice** (REQUIREMENTS-GROUPINGS-V11.md Capability #13 SC13.22 per §5.1 amendment to PLANNING-PROCESS-INSIGHTS-FROM-OT.md, user-approved 2026-05-24). ...
```
**Result:** PASS — new bullet at line 53 in "Open architect-level surfaces" section.

### V5. PLANNING-PROCESS-INSIGHTS-FROM-OT.md unchanged
```
$ git diff --stat maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md
(empty output — no changes)
```
**Result:** PASS — architect source doc preserved unchanged per SC8.

### V6. git status of v11-research/ (expect 3 modified files)
```
$ git status --short maintenance-docs/v11-research/
 M maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md
 M maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md
 M maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md
```
**Result:** PASS — exactly 3 modified files; no unintended edits.

(Note: the IMPL-REPORT itself will appear as untracked once written; the prompt scopes this report to the v11-research/ directory by IMPL-REPORT-* convention. Pack Chat stages the 3 edits + this IMPL-REPORT together per the next-steps line below.)

### V7. SC13.22 cross-reference consistency
```
$ grep -c "SC13.22" maintenance-docs/v11-research/{REQUIREMENTS-GROUPINGS-V11,TOUCH-POINT-INVENTORY-GROUPINGS-V2,HANDOFF-V11.1-ARCHITECT}.md
REQUIREMENTS-GROUPINGS-V11.md:8
TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:1
HANDOFF-V11.1-ARCHITECT.md:1
```
**Result:** PASS — same SC number `SC13.22` appears identically across all three docs. No SC-number drift. (REQUIREMENTS carries 8 occurrences because the SC is both defined and cross-referenced from 7 other points within the same doc; TOUCH-POINT and HANDOFF each carry 1 reference to the canonical SC13.22 in REQUIREMENTS.)

## Success criteria checklist

| SC | Description | Status | Evidence |
|---|---|---|---|
| SC1 | Capability #13 contains new SC for inter-grouping phase-cycle detection | **PASS** | REQUIREMENTS line 636 (SC13.22 body); placement at end-of-Capability #13 under new "Dependency-graph integrity" sub-heading; rationale documented above |
| SC2 | Capability #13 sub-list (b) count updated to reflect new total | **PASS** | REQUIREMENTS line 640 — "2 new mandatory checks" → "3 new mandatory checks" with the third check named explicitly; new sub-list-item (d) at line 642 records §5.1 amendment provenance |
| SC3 | Capability #9 SC9.9 cross-references new SC | **PASS** | REQUIREMENTS line 432 — appended cross-reference to SC13.22 naming shared cycle-detection infrastructure (Tarjan SCC architect-decided) |
| SC4 | TOUCH-POINT §10 extended with cycle-detection coverage entry | **PASS** | TOUCH-POINT line 853 — new row in §10.2 "NEW checks proposed" table naming the check, cross-referencing REQUIREMENTS SC13.22, noting shared infrastructure with Capability #9 SC9.9, citing BD-070 typed error, citing PA-013 failure mode |
| SC5 | HANDOFF "Open architect-level surfaces" gains cycle-detection entry | **PASS** | HANDOFF line 53 — new bullet under "Open architect-level surfaces" naming (a) algorithm choice (Tarjan SCC vs alternative), (b) persisted-cache vs rebuild-per-invocation, cross-referencing REQUIREMENTS SC13.22 |
| SC6 | Cross-references consistent across 3 docs | **PASS** | Same SC number `SC13.22` used uniformly across REQUIREMENTS (8x), TOUCH-POINT (1x), HANDOFF (1x); all three docs name the same architect-decision surfaces (algorithm + persistence) using consistent vocabulary |
| SC7 | No verbatim duplication; each doc carries native role | **PASS** | REQUIREMENTS = canonical SC text (full); TOUCH-POINT = single row in validator-footprint inventory table (compressed; named the check + cited REQ SC + named shared infra + named typed error + named failure-mode anchor); HANDOFF = forward-pointing architect-choice surface (compressed; named the two open architect choices + cited REQ SC + cited failure-mode anchor). No copy-paste of the full SC text across docs. |
| SC8 | PLANNING-PROCESS-INSIGHTS-FROM-OT.md preserved unchanged | **PASS** | `git diff --stat` empty for that file (V5 output) |

**All 8 SCs PASS.**

## Deviations from prompt

**Zero deviations.** All 8 SCs satisfied as specified; placement choice (SC13.22 appended to end of Capability #13 under a new "Dependency-graph integrity" sub-heading) was explicitly offered as a placement option in the prompt; no novel design decisions.

## Boundary discipline check

All three edited files are under `maintenance-docs/v11-research/`. This directory is:
- **Pack-internal** (not under `project-template/`)
- **Maintenance documentation** (not shipped to clients via `scripts/init-project.sh`)
- **Not v11-surface** for the `test-fixtures/manifest.txt` regeneration rule (the rule scopes to `project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`; `maintenance-docs/` is NOT in scope)

**Manifest regeneration check:** NOT required for this commit. The 3 edited files are under `maintenance-docs/v11-research/`, which falls outside the 4-directory v11-surface trigger. Verified by re-reading the trigger definition in CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule.

**No project-side SSOT investigation required.** The 3 edited docs are pack-internal architect/research artifacts. They are NOT shipped to clients; they exist solely to inform pack architect / planner / coder agents at v11.1+ architect-pass time. There is no project-side SSOT for "v11.1 groupings architecture requirements" — these docs ARE the pack-side SSOT for that work.

**No trinity rule trigger.** None of the edited files are part of any trinity (pack-root or project-template). The trinity rule does not apply.

**No PM-only file edits.** None of the edited files are in the PM-only list per `pack-ops/PACK-AGENTS.md`. All 3 files are appropriate pack-coder edit targets.

## New POQs introduced

**None.** The amendment is small, additive, and architecturally pre-scoped by the §5.1 source doc. The architect-decision surfaces (algorithm choice, persistence model) are explicitly surfaced as architect choices in HANDOFF; they are NOT new pack open-questions (POQs) — they are normal architect-pass decisions parallel to the other ~5 "Open architect-level surfaces" items already listed there.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All 3 in-scope files edited per prompt | **PASS** |
| Architect source doc preserved unchanged (SC8) | **PASS** |
| Cross-references consistent across 3 docs (SC6) | **PASS** |
| No verbatim duplication (SC7) | **PASS** |
| Cycle-detection check function name follows existing pattern | **PASS** (`check_grouping_phase_dependency_cycles` parallels `check_grouping_per_stream_contract` / `check_grouping_membership_integrity`) |
| BD-070 typed-error reference adopted | **PASS** (verified BD-070 in REQUIREMENTS at SC8.6 / SC9.6 / SC17.5 / Capability #8 Anchor cross-references; adoption is consistent with surrounding pattern) |
| §5.1 amendment provenance recorded in REQUIREMENTS | **PASS** (sub-list (d) added; sub-heading carries §5.1 citation) |
| All 7 verification commands run + captured | **PASS** |
| All 8 SCs PASS | **PASS** |
| No git state-changing commands run | **PASS** (only `git rev-parse HEAD`, `git status --short`, `git diff --stat` used — all read-only) |
| No files edited outside the 3-file scope | **PASS** (verified by `git status --short`) |
| Manifest regeneration NOT required (out-of-trigger directory) | **PASS** (`maintenance-docs/v11-research/` is not v11-surface) |
| Boundary-discipline pre-flight completed | **PASS** (no project-side leak; no trinity trigger; no PM-only file edits) |
| PREFLIGHT line emitted before IMPL-REPORT write | **PASS** (emitted prior to this Write call) |

## Files-changed inventory

| Path | Change type | Net lines |
|---|---|---|
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | modified | +9 |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | modified | +1 |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | modified | +1 |
| `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` | new (this report) | (report) |

No files deleted. No files moved. No files in scope outside `maintenance-docs/v11-research/`.

## Next steps for Pack Chat

Pack Chat to stage the 3 edited docs + this IMPL-REPORT and request user approval for combined commit.

Suggested commit message (Pack Chat refines):
```
docs: v11 — apply §5.1 amendment (inter-grouping cycle detection) to BD-186 artifacts (pack-only)
```

Suggested rationale for the `(pack-only)` scope keyword: all 4 files (3 edits + this IMPL-REPORT) live under `maintenance-docs/v11-research/` which is pack-internal; no `project-template/` touch; no `supporting-docs/` touch. CI Check 36 will verify the claim against the diff.


---

End of IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md.
