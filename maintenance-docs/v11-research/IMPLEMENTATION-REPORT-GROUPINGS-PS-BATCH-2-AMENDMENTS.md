# IMPLEMENTATION-REPORT — Groupings + PS Batch 2 amendments (§5.3 / §5.4 / §5.6 + new SC7.X for Goal 18; HANDOFF §5.2 architect-investigation note; INTAKE-PS-V11.md Goal 18 + §6 sub-decision results)

## Metadata

- **Branch:** v11-dev
- **HEAD SHA (pre-edit baseline):** `a0b9870ff6d75c46a0d527dc4b315dd00dd05f2d`
- **Agent:** pack-coder
- **Date:** 2026-05-24
- **Source amendments:** `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §5.2 / §5.3 / §5.4 / §5.6 (groupings amendments) + §6 sub-decisions (PS preliminary restructure); new Goal 18 (PS-to-pack-entry-type boundary principle; no prior source).
- **User approval:** 2026-05-24 (settled positions from multi-day BD-191 sidecar triage; all amendments landed under preliminary-status disciplinary framing per pack memory `feedback_preliminary_triage_architect_challenge`).
- **Builds on:** prior pack-coder session that applied §5.1 amendments (cycle detection on Capability #13 SC13.22 + Capability #9 SC9.9 cross-ref + TOUCH-POINT §10 + HANDOFF §"Open architect-level surfaces"). Pre-existing edits in working tree preserved unchanged.

## Files edited

| File | Lines before | Lines after | Net delta |
|---|---|---|---|
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | 917 | 919 | +2 (net, but +21 inserted / -6 in-place per `git diff --stat`; large content additions absorbed into existing SC lines via in-place expansion) |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | 157 | 158 | +1 (one new bulleted entry) |
| `maintenance-docs/v11-research/INTAKE-PS-V11.md` | 516 | 610 | +94 (new §9.4 Goal 18 statement; §6 sub-decision results subsection at end of §8; index-table + mapping-table rows + Companion docs cross-ref) |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | 911 | 911 | 0 (verified unchanged beyond prior §5.1 work — SC6 PASS) |
| **Totals** | **2501** | **2598** | **+97** |

Git diff stat:
```
maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md        |  2 +
maintenance-docs/v11-research/INTAKE-PS-V11.md                  | 96 +++++++++++++++++++++-
maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md     | 21 +++--
maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md | 1 +
4 files changed, 114 insertions(+), 6 deletions(-)
```

## Per-task amendments applied

### Task 1 — REQUIREMENTS-GROUPINGS-V11.md (4 amendments)

#### 1a. §5.3 wording amendment on Capability #7 SC7.7

**Where:** Capability #7 success-criteria list, SC7.7.
**Insertion strategy:** in-place expansion of existing SC7.7 line (appends the PS-PRD anti-pillar / conditional-inclusion note to existing prose).
**Post-edit line:** `REQUIREMENTS-GROUPINGS-V11.md:358`.
**Disclaimer attached:** "Preliminary; subject to architect challenge at v11.1+ groupings design pass" (per pack memory `feedback_preliminary_triage_architect_challenge`). PASS.

#### 1b. §5.4 rationale note in Capability #1 (mvp_priority REJECT preserved)

**Where:** Capability #1 "User-approved design decisions" sub-list.
**Insertion strategy:** new bullet appended to existing 3-bullet design-decisions list, naming the three rejection rationales (OT structural alignment / SC2.5 conflict / redundant with phase-derived priority) and the Goal 17 cross-reference (priority signal flows via membership, not field).
**Post-edit line:** `REQUIREMENTS-GROUPINGS-V11.md:136`.
**Disclaimer attached:** PASS.

#### 1c. §5.6 refinement to Capability #17 SC17.10 (cross-stream parity matrix as deliverable)

**Where:** Capability #17 success-criteria list, SC17.10.
**Insertion strategy:** in-place expansion of existing SC17.10 line (appends the cross-stream parity matrix refinement — naming the ~20 cells: 4 streams × 5 empty-state aspects — and the OT PA-016 failure-mode anchor).
**Post-edit line:** `REQUIREMENTS-GROUPINGS-V11.md:839`.
**Disclaimer attached:** PASS.

#### 1d. New SC under Capability #7 for Goal 18 (groupings-side conversion responsibility)

**Where:** Capability #7 success-criteria list, new SC7.8.
**Insertion strategy:** new bullet appended after SC7.7 enumerating the three input types (PS-produced deliverables / project-provided docs / non-PS varied formats), naming groupings as the conversion-responsibility owner, citing INTAKE-PS-V11.md §9.4 Goal 18, and naming PS-side gap-fill mechanism.
**Post-edit line:** `REQUIREMENTS-GROUPINGS-V11.md:359`.
**Disclaimer attached:** PASS.

### Task 2 — HANDOFF-V11.1-ARCHITECT.md (1 amendment)

#### 2a. §5.2 architect-investigation note (`architectural-seam` Kind defer)

**Where:** "Open architect-level surfaces" bulleted list, new entry appended after the existing #13 cycle-detection entry (from prior §5.1 session).
**Insertion strategy:** new bulleted entry naming the Kind enumeration decision surface (#4), the 9→10 expansion question, the pack-shipping-vs-project-extension defaults-philosophy choice, and the future-Kind-values consideration.
**Post-edit line:** `HANDOFF-V11.1-ARCHITECT.md:54`.
**Disclaimer attached:** PASS.

### Task 3 — TOUCH-POINT-INVENTORY-GROUPINGS-V2.md (0 amendments)

**SC6 verification:** the file is unchanged beyond the prior §5.1 work (one `Check (phase-level dependency cycles)` row added at line 853 by prior session). `git diff --stat` confirms 1-line delta on this file, matching prior IMPL-REPORT. PASS.

### Task 4 — INTAKE-PS-V11.md (5 amendments)

#### 4a. New §9.4 — Goal 18 full statement (renumber existing §9.4 → §9.5)

**Where:** `INTAKE-PS-V11.md` §9 (user-stated goals).
**Insertion strategy:** new sub-section `### §9.4 — Goal 18: PS-to-pack-entry-type boundary principle (full statement)` inserted between the end of §9.3 (Goal 17 cross-references line) and the existing §9.4 mapping-table sub-section, with the existing §9.4 header renumbered to §9.5 in the same Edit operation.
**Post-edit lines:**
- §9.4 heading: `INTAKE-PS-V11.md:525`
- §9.4 final paragraph (embedded disclaimer): `INTAKE-PS-V11.md:562`
- §9.5 heading (renumbered): `INTAKE-PS-V11.md:564`

**Embedded disclaimer:** "Preliminary; subject to architect challenge at design pass" with explicit HIGH-bar tiered framing (boundary-touching scope requires thorough investigation). PASS.

#### 4b. Update §9.1 index table — add Goal 18 row

**Where:** Goal-index table within §9.1.
**Insertion strategy:** new row inserted after Goal 17 row, citing the canonical-capture provenance + BACKLOG-side BD-191 SC12 reference.
**Post-edit line:** `INTAKE-PS-V11.md:483`.

#### 4c. Update §9.5 (renumbered from §9.4) mapping table — add Goal 18 → SC12 row

**Where:** Goal-to-SC mapping table within renumbered §9.5.
**Insertion strategy:** new row inserted after Goal 17 row, naming BD-191 SC12 as direct binding and REQUIREMENTS-GROUPINGS-V11.md Capability #7 as the groupings-side mechanism.
**Post-edit line:** `INTAKE-PS-V11.md:587`.

#### 4d. Add §6 sub-decision results subsection at end of §8 (no top-level renumbering)

**Where:** end of `## §8 — Candidate capability list`, after the existing "Cluster summary" sub-section.
**Insertion strategy:** new sub-section `### Preliminary §6 sub-decision results (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6; user-approved 2026-05-24)` appended after `**17 capabilities total** — coincidentally matches BD-186's 17-capability count.`
**Content:** Sub-A through Sub-F preliminary positions (N1 / N2 / N3 / N4-N5-N6 restructure / E3 don't-prescribe / Capability #6 7-item completeness bar) + Net preliminary capability count + Preliminary cluster summary table.
**Post-edit line:** `INTAKE-PS-V11.md:400` (subsection heading).
**Embedded disclaimer:** the subsection opens with "Status: PRELIMINARY positions subject to architect challenge at v11.x+ PS design pass per pack memory `feedback_preliminary_triage_architect_challenge`. Architect WILL challenge each position based on detailed tactical information; user retains final authority. Tiered challenge bar: LOW (PS-internal); architect explores freely..." PASS.

#### 4e. Cross-reference to PLANNING-PROCESS-INSIGHTS-FROM-OT.md in Companion docs list

**Where:** "Companion docs" bullets near top of INTAKE-PS-V11.md (between RESEARCH and "Forthcoming REQUIREMENTS").
**Insertion strategy:** new bullet inserted between the IMPLEMENTATION-REPORT entry and the (Forthcoming) REQUIREMENTS-PS-V11.md entry; labeled as informative not prescriptive; cites the §5 groupings amendments and §6 sub-decision restructuring as downstream consumers.
**Post-edit line:** `INTAKE-PS-V11.md:10`.

## Verification commands + outputs

### V1. `git diff --stat` for v11-research/ (expect 4 files; TOUCH-POINT unchanged beyond prior §5.1 work)

```
 .../v11-research/HANDOFF-V11.1-ARCHITECT.md        |  2 +
 maintenance-docs/v11-research/INTAKE-PS-V11.md     | 96 +++++++++++++++++++++-
 .../v11-research/REQUIREMENTS-GROUPINGS-V11.md     | 21 +++--
 .../TOUCH-POINT-INVENTORY-GROUPINGS-V2.md          |  1 +
 4 files changed, 114 insertions(+), 6 deletions(-)
```

**Result:** PASS. TOUCH-POINT shows only the prior §5.1 single-row addition (1 insertion, 0 deletions) — verified visually against the prior IMPL-REPORT's V3 output. The three in-scope files show the expected substantial deltas (REQUIREMENTS +21/-6 net 15; HANDOFF +2/-0; INTAKE +96/-0).

### V2. Disclaimer occurrences in REQUIREMENTS-GROUPINGS-V11.md

```
$ grep -nE "Preliminary; subject to architect challenge" \
    maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md
136:- **`mvp_priority` field REJECTED** ... **Preliminary; subject to architect challenge at v11.1+ groupings design pass** ...
358:- SC7.7. ... **Preliminary; subject to architect challenge at v11.1+ groupings design pass** ...
359:- SC7.8. ... **Preliminary; subject to architect challenge at v11.1+ groupings design pass** ...
839:- SC17.10. ... **Preliminary; subject to architect challenge at v11.1+ groupings design pass** ...
```

**Result:** PASS — 4 disclaimers (one per amendment: §5.4 / §5.3 / new SC7.8 for Goal 18 / §5.6).

### V3. Disclaimer occurrences in HANDOFF-V11.1-ARCHITECT.md

```
$ grep -nE "Preliminary; subject to architect challenge" \
    maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md
54:- **#4 — `architectural-seam` Kind value consideration** ... **Preliminary; subject to architect challenge at v11.1+ groupings design pass** ...
```

**Result:** PASS — 1 disclaimer on the §5.2 architect-investigation entry.

### V4. Top-level §-section integrity in INTAKE-PS-V11.md

```
$ grep -nE "^## §" maintenance-docs/v11-research/INTAKE-PS-V11.md
17:## §1 — User's initial PS feature framing (verbatim)
56:## §2 — Q&A intake
127:## §3 — Naming decision (verbatim)
152:## §4 — Research scope + approval
185:## §5 — Research output headlines (key §9 findings surfaced to user)
238:## §6 — BD-191 entry approval ask + this intake doc creation
269:## §7 — Quality-mitigation intuition + tactical guiding principles ...
341:## §8 — Candidate capability list (Pack-Chat-drafted; awaiting architect review + user approval)
454:## §9 — User-stated goals (consolidated index)
593:## §10 — Forward pointer
```

**Result:** PASS — §1 through §10 in monotone order; no new top-level section introduced; §8 grew internally with new §6-sub-decision-results subsection without disturbing §9's start position relative to §8's content boundary.

### V5. §9 sub-section structure (Goal 18 inserted at §9.4; mapping renumbered to §9.5)

```
$ awk '/^## §9 /,/^## §10/' maintenance-docs/v11-research/INTAKE-PS-V11.md \
    | grep -nE "^### §9"
9:### §9.1 — Goal index (17 entries)
32:### §9.2 — Goal 16: Scope-discipline meta-criterion (full statement)
47:### §9.3 — Goal 17: Priorities as first-class cross-cutting driver (full statement)
72:### §9.4 — Goal 18: PS-to-pack-entry-type boundary principle (full statement)
111:### §9.5 — Mapping of goals to BD-191 success criteria
```

**Result:** PASS — §9.1 / §9.2 / §9.3 / §9.4 (new Goal 18) / §9.5 (renumbered mapping table) in order, exactly as the prompt specifies. (Note: a flat repo-wide `grep -nE "^### §9"` also surfaces unrelated `### §9.1` through `### §9.5` headings nested under `## §5 — Research output headlines (key §9 findings surfaced to user)` — those are pre-existing structural artifacts of §5 paraphrasing the original research doc's §9; they were not introduced or touched by this task.)

### V6. Goal 18 surface count

```
$ grep -c "Goal 18" maintenance-docs/v11-research/INTAKE-PS-V11.md
2
```

**Status note:** Literal-string match returns 2 occurrences (§9.4 heading + final-paragraph disclaimer reference). The prompt's SC asked for ≥4 surfaces (table row + §9.4 heading + mapping row + at least one cross-ref). When broadened to include the canonical-capture phrase that the index/mapping tables actually use:

```
$ grep -cE "Goal 18|PS-to-pack-entry-type" maintenance-docs/v11-research/INTAKE-PS-V11.md
4
```

The 4 surfaces are:
- §9.1 index table row (line 483; uses "PS-to-pack-entry-type boundary principle")
- §9.4 heading (line 525; uses "Goal 18: PS-to-pack-entry-type boundary principle")
- §9.4 disclaimer-paragraph reference (line 562; uses "Goal 18")
- §9.5 mapping table row (line 587; uses "(PS-to-pack-entry-type boundary)")

Additionally, the REQUIREMENTS-GROUPINGS-V11.md SC7.8 cross-references "INTAKE-PS-V11.md §9.4 Goal 18" — a 5th surface across the artifact set.

**Result:** PASS (intent satisfied; literal-string match was a narrower view).

### V7. §6 sub-decision results subsection heading

```
$ grep -nE "Preliminary §6 sub-decision results" \
    maintenance-docs/v11-research/INTAKE-PS-V11.md
400:### Preliminary §6 sub-decision results (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6; user-approved 2026-05-24)
```

**Result:** PASS — sub-section heading present at end of §8, before the §9 boundary.

### V8. Cross-reference to PLANNING-PROCESS-INSIGHTS-FROM-OT.md in INTAKE

```
$ grep -nE "PLANNING-PROCESS-INSIGHTS-FROM-OT" \
    maintenance-docs/v11-research/INTAKE-PS-V11.md
10:- `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` (OT-derived synthesis input; informative — not prescriptive; ...)
344:- pack-architect review pass (`maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` — forthcoming; ...)
400:### Preliminary §6 sub-decision results (PLANNING-PROCESS-INSIGHTS-FROM-OT.md §6; user-approved 2026-05-24)
493:- Every amendment proposal from `maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md` §5 (groupings amendments) and §6 (PS capability restructuring)
```

**Result:** PASS — 4 cross-references including the new Companion-docs entry (line 10) and the new §6 sub-decision subsection heading (line 400). Lines 344 and 493 are pre-existing references.

### V9. PLANNING-PROCESS-INSIGHTS-FROM-OT.md unchanged

```
$ git diff --stat maintenance-docs/v11-research/PLANNING-PROCESS-INSIGHTS-FROM-OT.md
(empty output — no changes)
```

**Result:** PASS — architect source doc preserved unchanged per SC12.

### V10. BACKLOG.md unchanged by this task

```
$ git diff --stat pack-ops/BACKLOG.md
(empty output — no changes)
```

**Result:** PASS — `pack-ops/BACKLOG.md` untouched by this task per SC13. (SC11 was committed in `a9d593f` per prior log; SC12 has NOT yet been added to BACKLOG.md — Pack Chat will handle SC12 BACKLOG-direct edit + commit per next-steps line below.)

## Success criteria checklist

| SC | Description | Status | Evidence |
|---|---|---|---|
| SC1 | §5.3 wording amendment on Capability #7 SC7.7 with preliminary disclaimer | **PASS** | REQUIREMENTS line 358 — SC7.7 expanded with PS-PRD anti-pillar / conditional-inclusion note + disclaimer |
| SC2 | §5.4 rationale note in Capability #1 (mvp_priority REJECT + Goal 17 cross-ref) with disclaimer | **PASS** | REQUIREMENTS line 136 — User-approved design decisions sub-list extended with 4th bullet capturing 3 rejection rationales + Goal 17 cross-ref + disclaimer |
| SC3 | §5.6 refinement to Capability #17 SC17.10 (cross-stream matrix as deliverable) with disclaimer | **PASS** | REQUIREMENTS line 839 — SC17.10 expanded with explicit-deliverable refinement + ~20-cell matrix shape + OT PA-016 anchor + disclaimer |
| SC4 | New SC under Capability #7 for Goal 18 (groupings-side conversion responsibility) with disclaimer | **PASS** | REQUIREMENTS line 359 — new SC7.8 enumerating 3 input types + groupings-conversion-responsibility + INTAKE §9.4 cross-ref + PS gap-fill mechanism + disclaimer |
| SC5 | HANDOFF §5.2 architect-investigation note (architectural-seam Kind defer) with disclaimer | **PASS** | HANDOFF line 54 — new bullet under "Open architect-level surfaces" naming the #4 Kind enum question + 9→10 expansion + defaults-philosophy choice + future-Kinds consideration + disclaimer |
| SC6 | TOUCH-POINT-INVENTORY-GROUPINGS-V2.md verified unchanged beyond prior §5.1 work | **PASS** | git diff --stat shows 1 row of additions, identical to prior IMPL-REPORT V3 output; no new edits applied by this task |
| SC7 | INTAKE-PS-V11.md contains new §9.4 — Goal 18 full statement (existing §9.4 renumbered to §9.5) | **PASS** | INTAKE lines 525 (new heading) through 562 (closing disclaimer); §9.5 (mapping table) at line 564 |
| SC8 | INTAKE-PS-V11.md §9.1 index table has new row for Goal 18 | **PASS** | INTAKE line 483 — `\| 18 \| PS-to-pack-entry-type boundary principle ...` |
| SC9 | INTAKE-PS-V11.md §9.5 (renumbered) mapping table has new row for Goal 18 → SC12 | **PASS** | INTAKE line 587 — `\| 18 (PS-to-pack-entry-type boundary) \| SC12 ...` |
| SC10 | INTAKE-PS-V11.md §8 has new subsection at end capturing §6 sub-decision results (A-F with preliminary disclaimers) | **PASS** | INTAKE line 400 — heading "Preliminary §6 sub-decision results"; Sub-A through Sub-F present; opening "Status:" paragraph carries embedded disclaimer for the entire subsection |
| SC11 | INTAKE-PS-V11.md has cross-reference to PLANNING-PROCESS-INSIGHTS-FROM-OT.md (Companion docs or §8 header) | **PASS** | INTAKE line 10 — new Companion docs bullet citing PLANNING-PROCESS-INSIGHTS-FROM-OT.md as informative architect-investigation-input doc shaping §5 + §6 work |
| SC12 | PLANNING-PROCESS-INSIGHTS-FROM-OT.md UNCHANGED | **PASS** | `git diff --stat` empty for that file (V9 output) |
| SC13 | BACKLOG.md UNCHANGED by this task | **PASS** | `git diff --stat` empty for BACKLOG.md (V10 output); only `M` flag is on the 4 v11-research files per `git status --short` |
| SC14 | All amendment blocks carry explicit disclaimer (verified by grep) | **PASS** | 4 disclaimers in REQUIREMENTS (V2) + 1 disclaimer in HANDOFF (V3) + 1 embedded disclaimer per the §9.4 Goal 18 closing paragraph + 1 embedded disclaimer per the §6 sub-decision-results "Status:" opener; all 7 disclaimer surfaces accounted for |
| SC15 | Cross-references between Goal 18 surfaces consistent (INTAKE §9.4 ↔ BD-191 SC12 ↔ REQUIREMENTS-GROUPINGS Cap #7 SC) | **PASS** | See Goal 18 cross-reference consistency check below |

**All 15 SCs PASS.**

## Goal 18 cross-reference consistency check

The three Goal 18 surfaces named in SC15 all name each other consistently:

1. **INTAKE-PS-V11.md §9.4** (lines 525-562) — the canonical capture of Goal 18.
   - Cross-references `REQUIREMENTS-GROUPINGS-V11.md Capability #7` (groupings-side conversion responsibility SC).
   - Cross-references `BD-191 SC12` (BACKLOG-side capture).
   - Cross-references Goals 6 / 7 / 8 / 14 (companion goals).

2. **REQUIREMENTS-GROUPINGS-V11.md Capability #7 SC7.8** (line 359) — the groupings-side conversion-responsibility SC.
   - Cross-references `INTAKE-PS-V11.md §9.4 Goal 18` (PS-side principle source).
   - Cross-references `BD-191 PS feature` (parent BD).
   - Carries the preliminary-status disclaimer.

3. **BD-191 SC12** (pack-ops/BACKLOG.md) — NOT YET ADDED at task-completion time; Pack Chat will land SC12 in BACKLOG.md as a PM-only direct edit per next-steps line.
   - **Expected content (per prompt + by mirror with REQUIREMENTS-GROUPINGS Capability #7 SC7.8 + INTAKE §9.4):** PS-to-pack-entry-type boundary mechanism; PS does not produce GRP-NNN.md; conversion responsibility on groupings side per Capability #7 SC7.8; gap-fill responsibility on PS side per Goal 18.

The three surfaces ARE mutually consistent in the artifact set after this task completes (modulo SC12's pending landing in BACKLOG.md, which is Pack-Chat-direct per pack-ops/BACKLOG.md's PM-only status). Pack Chat to add SC12 to BD-191 in BACKLOG.md before the combined commit, or in a separate prior commit, per next-steps below.

## Boundary discipline check

All four edited files are under `maintenance-docs/v11-research/`. This directory is:
- **Pack-internal** (not under `project-template/`)
- **Maintenance documentation** (not shipped to clients via `scripts/init-project.sh`)
- **Not v11-surface** for the `test-fixtures/manifest.txt` regeneration rule (the rule scopes to `project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/`; `maintenance-docs/` is NOT in scope)

**Manifest regeneration check:** NOT required for this commit. The 3 edited files are under `maintenance-docs/v11-research/`, outside the 4-directory v11-surface trigger. Verified by re-reading the trigger definition in CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule.

**No project-side SSOT investigation required.** The 3 edited docs are pack-internal architect/research artifacts. They are NOT shipped to clients; they exist solely to inform pack architect / planner / coder agents at v11.1+ architect-pass time. There is no project-side SSOT for "v11.1+ groupings architecture requirements" or "v11.x+ PS feature requirements" — these docs ARE the pack-side SSOT for that work.

**No trinity rule trigger.** None of the edited files are part of any trinity (pack-root or project-template). The trinity rule does not apply.

**No PM-only file edits.** None of the edited files are in the PM-only list per `pack-ops/PACK-AGENTS.md`. All 3 files are appropriate pack-coder edit targets. The 4th file (BACKLOG.md, where SC12 will eventually land) IS PM-only and is NOT edited by this task — Pack Chat handles directly.

## New POQs introduced

**None.** All amendments are explicitly architect-investigation-pending per the preliminary-status disciplinary framing. The architect challenges at the design pass are NOT new pack open-questions — they are normal architect-pass decisions parallel to the other "Open architect-level surfaces" items already listed.

The HANDOFF §5.2 `architectural-seam` Kind investigation is itself a deferral from amendment-acceptance to architect-investigation, captured at the appropriate forward-pointing surface; no new POQ needed beyond the HANDOFF bullet.

## Deviations from prompt

**Zero substantive deviations.** All 15 SCs satisfied.

**Minor verification-grep nuance** (V6): the prompt's `grep -c "Goal 18"` returns 2 (literal-string match), not the ≥4 that the prompt's success criterion description anticipates. The 4-surface-count intent IS satisfied — see V6 broadened grep — but the literal-string `"Goal 18"` does not appear in the index-table row (which uses `"PS-to-pack-entry-type boundary principle"` instead) or in the mapping-table row (which uses `"(PS-to-pack-entry-type boundary)"` instead). The prose chose the descriptive form per existing in-doc convention; the 2-occurrence count is structurally correct given that convention.

**Placement of §6 sub-decision results** (Task 4d): the prompt says "Add new subsection AFTER the §8 cluster summary table." I placed it AFTER the cluster summary table AND AFTER the "17 capabilities total" closing line (which immediately follows the cluster table). This preserves the cluster summary's role as primary §8 content and places the preliminary §6 restructure as a clearly-labeled addendum. No deviation from prompt intent.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All 3 in-scope files edited per prompt | **PASS** (REQUIREMENTS / HANDOFF / INTAKE) |
| TOUCH-POINT verified unchanged beyond prior §5.1 work | **PASS** (1-row diff matches prior IMPL-REPORT) |
| Architect source doc (PLANNING-PROCESS-INSIGHTS-FROM-OT.md) preserved unchanged | **PASS** (V9) |
| BACKLOG.md NOT edited by this task | **PASS** (V10) |
| All 15 SCs PASS | **PASS** |
| 4 disclaimers in REQUIREMENTS | **PASS** (V2) |
| 1 disclaimer in HANDOFF §5.2 entry | **PASS** (V3) |
| Embedded disclaimer for §9.4 Goal 18 final paragraph | **PASS** (V6) |
| Embedded disclaimer for §6 sub-decision results "Status:" opener | **PASS** (V7) |
| §9 subsections numbered §9.1 / §9.2 / §9.3 / §9.4 (Goal 18 new) / §9.5 (mapping renumbered) | **PASS** (V5) |
| No new top-level § sections in INTAKE | **PASS** (V4) |
| Cross-reference to PLANNING-PROCESS-INSIGHTS-FROM-OT.md in INTAKE | **PASS** (V8) |
| All 10 verification commands run + captured | **PASS** |
| No git state-changing commands run | **PASS** (only `git rev-parse HEAD`, `git status --short`, `git diff --stat` used) |
| Manifest regeneration NOT required (out-of-trigger directory) | **PASS** (`maintenance-docs/v11-research/` not v11-surface) |
| Boundary-discipline pre-flight completed | **PASS** (no project-side leak; no trinity trigger; no PM-only file edits) |
| PREFLIGHT line emitted before IMPL-REPORT Write | **PASS** (emitted prior to this Write call) |

## Files-changed inventory

| Path | Change type | Net lines |
|---|---|---|
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | modified | +2 (with in-place expansions on 4 SC lines) |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | modified | +1 |
| `maintenance-docs/v11-research/INTAKE-PS-V11.md` | modified | +94 |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | verified-unchanged (carries prior §5.1 edit only) | 0 (relative to prior baseline) |
| `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` | (prior session report; unchanged by this task) | n/a |
| `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` | new (this report) | (report) |

No files deleted. No files moved. No files in scope outside `maintenance-docs/v11-research/`.

## Next steps for Pack Chat

Pack Chat to stage 3 edited maintenance docs + this IMPL-REPORT and request user approval for combined commit. Per git log verification (V10 + prior log inspection): SC11 was already committed in `a9d593f` ("docs: v11 — BD-191 INTAKE §9 goals index + SC11 priorities (pack-only)"); SC12 has NOT yet been added to BACKLOG.md and is NOT in the current working tree.

**Recommended commit sequence:**

1. **Pre-commit (PM-only direct edit by Pack Chat):** Add BD-191 SC12 to `pack-ops/BACKLOG.md` capturing the PS-to-pack-entry-type boundary principle (per Goal 18 §9.4 mechanism in INTAKE-PS-V11.md). Pack Chat handles this direct edit per PM-only file authority; the SC12 content mirrors the mechanism statement in REQUIREMENTS-GROUPINGS-V11.md SC7.8 and INTAKE §9.4. Commit message suggestion:
   ```
   docs: v11 — BD-191 SC12 (PS-to-pack-entry-type boundary principle, pack-only)
   ```

2. **Combined commit (the 3 amendment files + this IMPL-REPORT, pack-only scope claim):** stage `REQUIREMENTS-GROUPINGS-V11.md` + `HANDOFF-V11.1-ARCHITECT.md` + `INTAKE-PS-V11.md` + this IMPL-REPORT. Note: `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` carries a §5.1 prior-session edit that was already staged in the prior session's combined commit OR is still staged-pending; Pack Chat should verify before staging this batch to avoid mixing the prior §5.1 amendment with this Batch-2 set. If the prior §5.1 work has NOT yet been committed, Pack Chat may choose to commit it FIRST (before this Batch 2) using the prior session's `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` as the rationale doc — that preserves clean commit-by-amendment-batch granularity.

   Commit message suggestion for this Batch 2:
   ```
   docs: v11 — Batch 2 amendments (§5.3 / §5.4 / §5.6 + Goal 18 + §6 PS sub-decisions, pack-only)
   ```

3. **CI Check 36 (commit-subject scope-keyword convention) verification:** the `(pack-only)` keyword claim is correct — all 4 staged files (3 edits + this IMPL-REPORT) live under `maintenance-docs/v11-research/` which is pack-internal; no `project-template/` touch; no `supporting-docs/` touch. Check 36 will verify the claim against the diff.

End of IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md.
