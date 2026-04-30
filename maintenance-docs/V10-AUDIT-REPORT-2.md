# V10-AUDIT-REPORT-2.md

*Created: 2026-04-24*
*Audit scope: `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` (910 lines) only.*
*Continuation of `maintenance-docs/V10-AUDIT-REPORT.md`. Finding IDs
continue the AF-NNN sequence starting at AF-021.*
*Auditor: pack-reviewer (read-only).*
*Reference docs read for cross-checking (not audited here): V10-PREDESIGN.md,
V10-DESIGN.md, V10-IMPLEMENTATION-PLAN.md, V10-AUDIT-REPORT.md.*

---

## Part 1 — Status + scope

**What is V10-DESIGN-PROCESS-PLAN.md.** The 13-step workflow plan that
orchestrated the v10 design pass (the phase that produced V10-DESIGN.md).
V10-PREDESIGN.md Part 7 frames the v10 project as a four-phase progression
(process planning → design pass → implementation planning → implementation +
audit + ship). This plan's exit criterion is "V10-DESIGN.md is approved and
V10-PREDESIGN.md is superseded." That criterion was met at commit
`4df382d` ("v9 — V10-DESIGN.md APPROVED; V10-PREDESIGN.md superseded",
2026-04-21). The plan's substantive work is therefore complete; the file
now functions as a historical process artifact.

**What was audited.** Read all 910 lines of V10-DESIGN-PROCESS-PLAN.md.
Spot-checked every cross-reference to V10-PREDESIGN.md Parts 1–11,
V10-DESIGN.md Parts 0–13 + Appendix A, V10-IMPLEMENTATION-PLAN.md §6.1–§6.6,
BACKLOG.md BD-044/BD-045/BD-046 entries, and the pack-repo commit log for
the executed approval commit. Ran grep sweeps for `V10-DESIGN-PROCESS-PLAN`
across the pack to map live back-references (17 matches across 7 files —
see §6).

**What was not audited.** No file edits (read-only). No re-audit of items
already found in V10-AUDIT-REPORT.md. No scope expansion to
`v10-working/step-*.md` working reports (referenced from the plan but out
of scope per prompt).

**Method.** Dimension-aligned pass mirroring the main audit: consistency,
completeness, accuracy, contradictions, staleness, status/lifecycle,
plan-reality drift, confusing content, archive candidacy.

---

## Part 2 — Executive summary

**Findings by severity**

| Severity | Count |
|---|---:|
| Ship-blocker | 0 |
| Nice-to-fix (before Phase 4 planning benefits) | 4 |
| Note (defer / dismiss / informational) | 9 |
| **Total** | **13** |

**Readiness assessment for Phase 4: clean to cite with one caveat.** The
plan is substantively accurate against the artifacts it produced.
V10-DESIGN.md's part-structure, AD numbering (AD-1..AD-13), BACKLOG
blocker clearance, and the supersession banner on V10-PREDESIGN.md all
materialize as the plan specified. Exit criteria §8 items 1–7 are met; item
8 (`Validate Pack` passing on the approval commit) is assumed true. A
Phase-4 reader can trust the plan's narrative.

**The one caveat is lifecycle signposting.** The plan has no status header
and reads entirely in imperative/future tense ("Developer must explicitly
approve," "Phase 1 is complete. Phase 3 … can start"). A reader arriving
cold in Phase 4 will spend several paragraphs before recognizing that the
plan governed a completed phase. Recommend either (a) add a one-line
SUPERSEDED-style banner at the top, or (b) move to `maintenance-docs/archive/`
with path updates in the 9 live references from V10-DESIGN.md and 2 from
V10-PREDESIGN.md. See §5.

---

## Part 3 — Findings by dimension

### 3.1 Consistency

- **AF-024 (nice-to-fix)** — Plan Step 5 item 5 (line 343) characterizes
  CD-7 as "(PLATFORM-SKILLS.md `## Custom skills` section)" — singular.
  V10-DESIGN.md AD-7 (line 351) covers both `## Custom agents` AND
  `## Custom skills` sections. The plan's one-line framing understates
  the decision that actually landed. See §7 AF-024.

- **AF-028 (note)** — Plan line 791 cross-reference matrix characterizes
  CD-13 as "(v9.x baseline only)"; V10-DESIGN.md AD-13 specifies "Latest
  v9.3" as the baseline. The plan's wording was accurate at write time
  (v9.x = the v9.x lineage); the design pass tightened this to v9.3. No
  correctness defect, but a Phase-4 reader comparing plan vs. design sees
  two different labels.

### 3.2 Completeness

- No missing CD/OQ/BD artifacts. Plan Part 6 cross-reference matrix
  (lines 775–810) lists all 13 CDs and all 14 OQs explicitly; every one
  is resolved by a numbered step. Every Design Requirement from
  V10-PREDESIGN Part 7 is mapped to a step in the Part 6 matrix
  (lines 814–829). Every V9 lesson (L1–L5) is mapped (lines 834–845).

- **AF-023 (note)** — Plan Step 11 (line 637) anticipates "Part 2 —
  Approved Decisions (the former CDs, now AD-1 through AD-13 or
  renumbered)." V10-DESIGN.md Part 2 actually contains AD-1 through
  AD-18: five additional ADs (AD-14..AD-18, capability-addition
  mechanism) were introduced via a V10-DESIGN-2.md addendum merge
  recorded in V10-DESIGN.md Part 0 row 16. The plan did not and could
  not have anticipated this addendum. Plan-reality drift; no defect
  because Part 0 annotates the merge.

### 3.3 Accuracy

- Cross-references to V10-PREDESIGN.md Parts 1, 2, 3, 4, 5, 6, 7, 8, 9,
  10, 11 all resolve to existing parts with the named content (verified
  via `grep '^## Part' V10-PREDESIGN.md`). ✓
- Cross-references to V10-DESIGN.md Parts 0–13 all resolve (verified via
  `grep '^## Part ' V10-DESIGN.md`). Part structure matches plan Step 11
  item 1 exactly. ✓
- Step 13 executed-commit-message prediction is approximately correct
  but cosmetically different from the landed form — see AF-027.

- **AF-027 (note)** — Plan line 727 predicts commit message
  `docs: v9 — V10-DESIGN.md approved; supersedes V10-PREDESIGN.md`.
  Actual commit `4df382d` landed as
  `v9 — V10-DESIGN.md APPROVED; V10-PREDESIGN.md superseded` (no
  `docs:` prefix, uppercase `APPROVED`, reversed clause order). Not a
  defect; the plan anticipated approximate form and left wording to
  the committer. Informational.

### 3.4 Contradictions

- **AF-021 (note)** — Phase numbering is internally inconsistent with
  V10-PREDESIGN Part 7. V10-PREDESIGN.md lines 586–601 define four
  distinct phases: (1) Process planning, (2) Design pass, (3)
  Implementation planning, (4) Implementation + audit + ship. Under that
  framing, producing V10-DESIGN.md is Phase 2, not Phase 1. The plan at
  line 3 self-labels as "Phase 1 of the four-phase progression" and at
  line 733 says "Phase 1 is complete. Phase 3 (implementation planning)
  can start" — skipping Phase 2. Downstream, V10-IMPLEMENTATION-PLAN.md
  line 1 is titled "Phase 3 — v10.0 Implementation Plan (v2)," which
  matches V10-PREDESIGN's Phase 3 = implementation planning. The effect
  is that Phase 2 is never explicitly named anywhere in v10 artifacts.
  The plan implicitly collapses V10-PREDESIGN's Phases 1+2 into
  "Phase 1." This is not a correctness defect (the workflow succeeded)
  but it is a labeling contradiction with the document the plan
  references as its framing source.

- **AF-029 (note)** — Plan §3 Block D (line 393) and Step 6 heading
  (line 392) use "v9.x → v10.0"; V10-DESIGN Part 6 is titled
  "Design: Migration v9.3 → v10.0" (line 2041). The plan's wording
  was correct at write time; the design pass tightened the baseline to
  v9.3 per AD-13. Minor staleness if the plan is read live.

### 3.5 Staleness

- **AF-030 (note)** — Plan Step 4 (lines 244–251) describes
  `supporting-docs/PROMPT-TEMPLATES.md` as the current 741-line
  monolith, which is to be split. In post-v10 reality the file is
  scheduled for deletion in V10-IMPLEMENTATION-PLAN.md C-044-07 (§5
  line 153: "PROMPT-TEMPLATES.md deletion → moved to Phase 3 C-044-07").
  A Phase-4 reader of the plan who follows the reference to
  PROMPT-TEMPLATES.md will find it intact on v10-dev but scheduled for
  removal; the plan does not signal this outcome.

- **AF-032 (note)** — Plan §0 line 37 asserts "No BD beyond 044/045/046
  is in v10." This was true at write time. Current state: BD-047 (PM
  chat kickoff auto-discovery) has been folded into v10 scope and
  resolved on v10-dev (commit 2a0c8d5); BD-048 (capability-addition
  install-check) was filed during Phase 3-B. The plan's scope fence is
  now historically inaccurate. Only matters if the plan is treated as
  a live reference.

- **AF-033 (note)** — Plan §2 "Inputs every step can assume" (line 88)
  lists `maintenance-docs/V9-DESIGN.md` as a baseline input. Per the
  project-lead decision (main audit Part 10 OQ 6 → option c), V9-DESIGN.md
  is to be moved to `maintenance-docs/archive/V9-DESIGN.md`. If the plan
  is preserved in place, this path reference will become stale once the
  archive move lands.

### 3.6 Status header / lifecycle

- **AF-025 (nice-to-fix)** — The file has no status/front-matter block.
  Lines 1–10 open with the plan's introduction directly. V9-DESIGN.md
  carries a status header; V10-PREDESIGN.md carries a SUPERSEDED banner;
  V10-DESIGN.md carries a Part 0 status table; V10-IMPLEMENTATION-PLAN.md
  carries a header block. V10-DESIGN-PROCESS-PLAN.md is the only v10
  maintenance-doc of its size with no status marker. A Phase-4 reader
  cannot tell from the top of the file whether this is a live plan or a
  historical artifact. Evidence: lines 1–10 are workflow scope statements,
  not status. Suggested fix: add a dated banner (e.g., "*Status: Complete
  — all 13 steps executed; exit criteria met at commit 4df382d
  2026-04-21. See V10-DESIGN.md for approved output.*").

- **AF-026 (note)** — Entire file is written in imperative/future tense
  consistent with a live plan: "Developer must explicitly approve before
  Step 2" (line 124), "pack-architect produces" (line 215), "the PM chat
  detects inconsistency" (line 353), "Phase 1 is complete. Phase 3 …
  can start in a new session" (line 733). No passage is rewritten in
  historical voice after completion. If AF-025's status banner lands,
  tense matters less; if the file is moved to `archive/`, tense is
  immaterial because the archive location itself signals status.

### 3.7 Plan-reality drift

See §4 for full cross-check of plan exit criteria vs. landed reality. In
summary: all 9 exit criteria listed in Plan §8 materialized. The plan's
workflow was executed with three notable divergences, all of which the
landed design accommodates:

- **AF-022 (note)** — Plan §5 Checkpoint gates summary (lines 757–769)
  lists G9 ("Step 12 — pack-reviewer report resolution") as a single
  gate. V10-DESIGN.md Part 0 row 16 records "Review rounds: 5
  (step-12-review-report through step-12-review-report-v5)" — Step 12
  executed five times rather than once, iterating until no critical
  findings remained. The plan's Step 12 spec (line 701: "Any Critical
  finding goes back to pack-architect") supports iteration implicitly
  but does not name a round count. Not a defect; plan-reality drift
  only in that "one review" was imagined, "five rounds" landed.

- **AF-023** (already listed under Completeness) — the V10-DESIGN-2.md
  addendum producing AD-14..AD-18 is an unplanned iteration past the 13
  CDs the plan anticipated.

- No commits shipped outside Plan §4's two-commit budget in a way that
  violates the plan: Plan §4 says "Intermediate working drafts can be
  committed at developer discretion; each must leave the pack in a state
  where `Validate Pack` passes." The reviewer-round commits are within
  this provision.

### 3.8 Confusing content

- **AF-031 (note)** — The plan uses a "Block A / Block B / Block C /
  Block D / Block E / Block F" organizing layer (line 100 onward) that
  appears nowhere else in the v10 doc set. V10-DESIGN.md and
  V10-IMPLEMENTATION-PLAN.md reference the plan's *step numbers*
  (Step 1, Step 4, Step 11, etc.) but never its block letters. A
  Phase-4 reader who back-traces from V10-DESIGN.md §4.1 ("Per
  V10-DESIGN-PROCESS-PLAN Step 4 decision rule…") to the plan will find
  Step 4 inside "Block C" without any cross-doc referent for "Block C."
  Plan-local jargon, non-blocking.

- **AF-021** (already listed under Contradictions) — the "Phase 1
  complete → Phase 3 begins" sentence (line 733) is the single most
  confusing line for a reader who holds V10-PREDESIGN's Phase 2 in
  mind.

### 3.9 Archive candidacy

See §5 below for the explicit recommendation.

---

## Part 4 — Plan-reality drift check

Mapping Plan §8 exit criteria against landed artifacts:

| # | Plan exit criterion | Landed state | Verified? |
|---|---|---|---|
| 1 | `maintenance-docs/V10-DESIGN.md` exists with status **APPROVED** and dated approval record | V10-DESIGN.md Part 0 Status = APPROVED, Approved 2026-04-21, Approved-by David Shane | ✓ |
| 2 | V10-PREDESIGN.md carries supersession banner pointing to V10-DESIGN.md | V10-PREDESIGN.md lines 4–10 carry SUPERSEDED banner + prose notice | ✓ |
| 3 | Every CD from V10-PREDESIGN Part 2 is explicitly confirmed or changed in V10-DESIGN.md Part 2 | V10-DESIGN Part 13.5 maps CD-1→AD-1 … CD-13→AD-13 | ✓ |
| 4 | Every OQ from V10-PREDESIGN Part 3 is resolved in V10-DESIGN.md or listed in Part 13 with rationale | V10-DESIGN Part 13.5 maps all 14 OQs to resolving sections | ✓ |
| 5 | Every Design Requirement from V10-PREDESIGN Part 7 has a named home in V10-DESIGN.md | V10-DESIGN Appendix A maps each requirement to ≥1 section | ✓ |
| 6 | Part 8 lessons are mapped to V10-DESIGN.md via explicit appendix | V10-DESIGN Part 11 "V9 Lessons Carried Forward" | ✓ |
| 7 | BACKLOG.md reflects cleared blockers on BD-044/045/046 | BACKLOG.md BD-044 (line 806), BD-045 (line 909), BD-046 (line 1013) all Status: Unblocked with "design approval pass completed 2026-04-21" rationale | ✓ |
| 8 | Approval commit passed `Validate Pack` CI | Commit 4df382d; assumed clean per main-audit scope (not re-verified) | Assumed ✓ |
| 9 | Phase 3 can start in a new session with V10-DESIGN.md as sole input | V10-IMPLEMENTATION-PLAN.md exists (2264 lines); was authored from V10-DESIGN.md | ✓ |

**Unplanned iteration observed** (not a criterion failure):

- Five review rounds at Step 12 (AF-022) rather than the implied single
  gate.
- V10-DESIGN-2.md addendum producing AD-14..AD-18 (AF-023) — extended the
  13-CD budget by 5 ADs after initial approval.

**Net**: exit criteria met; plan governed iteration that exceeded its own
specification without violating any criterion.

---

## Part 5 — Archive-candidacy recommendation

**Three options, recommended in order.**

**Option A (recommended) — Leave in place with a one-line status banner
added at the top.** Insert a banner under the H1 of the form:

> *Status: Complete — all 13 steps executed; exit criteria met at commit
> `4df382d` (2026-04-21). This document is a historical process artifact;
> the approved output is `maintenance-docs/V10-DESIGN.md`. Do not use for
> live decisions.*

Lowest churn. No path updates required in the 9 live references from
V10-DESIGN.md or the 2 from V10-PREDESIGN.md. Resolves AF-025 completely
and AF-026 substantively.

**Option B — Move to `maintenance-docs/archive/V10-DESIGN-PROCESS-PLAN.md`
parallel to the V9-DESIGN.md archive decision.** Requires updating all 11
live references (see §6). Slightly higher churn, but parallel treatment
with V9-DESIGN.md is internally consistent. If Option B is chosen, the
same banner from Option A should also be added inside the moved file.

**Option C — Leave as-is.** Not recommended. The plan is the only v10
maintenance-doc of substantial size with no status marker; a Phase-4
reader will waste reading time establishing lifecycle.

**Rationale for preferring A over B.** V9-DESIGN.md has no live inbound
references in v10 docs — archiving it is a clean lift-and-shift. This plan
has 11 live inbound references; most of them are V10-DESIGN.md's own
*historical* citations ("Step 12 of the V10-DESIGN-PROCESS-PLAN" is
historical voice already). Moving the file makes those citations
technically stale without adding clarity. Adding a status banner in
place achieves the same lifecycle signal at lower cost.

---

## Part 6 — Cross-doc reference spot-check

Inbound references to V10-DESIGN-PROCESS-PLAN.md across the pack (grep
`V10-DESIGN-PROCESS-PLAN`):

| File | Line | Reference form | Status |
|---|---|---|---|
| V10-DESIGN.md | 1151 | "Per V10-DESIGN-PROCESS-PLAN Step 4 decision rule" | Live; accurate |
| V10-DESIGN.md | 3157 | Touch-point row citing "Steps 11–13" | Live; accurate |
| V10-DESIGN.md | 3158 | Touch-point row citing "Step 13" | Live; accurate |
| V10-DESIGN.md | 3159 | Touch-point row citing "Step 13" | Live; accurate |
| V10-DESIGN.md | 3720 | "Step 2 of the V10-DESIGN-PROCESS-PLAN" | Live; accurate |
| V10-DESIGN.md | 3786 | "Step 12 of the V10-DESIGN-PROCESS-PLAN" | Live; accurate |
| V10-DESIGN.md | 3793 | "V10-DESIGN-PROCESS-PLAN Step 1 G1" | Live; accurate |
| V10-DESIGN.md | 3851 | "V10-DESIGN-PROCESS-PLAN §4" | Live; accurate |
| V10-DESIGN.md | 3996 | "OQ-6 → V10-DESIGN-PROCESS-PLAN.md" | Live; accurate |
| V10-PREDESIGN.md | 322 | Process-plan pointer | Live; accurate |
| V10-PREDESIGN.md | 553 | "OQ-6 resolved: design approval process defined by V10-DESIGN-PROCESS-PLAN.md" | Live; accurate |

Outbound references from V10-DESIGN-PROCESS-PLAN.md to other docs:

| Target | Citation form | Spot-check result |
|---|---|---|
| V10-PREDESIGN.md Part 1 | line 3 "V10-PREDESIGN.md Part 7" | ✓ Part 7 exists (line 579) |
| V10-PREDESIGN.md Parts 2, 3, 7, 8, 9, 10, 11 | lines 14–25, 82, 523, 541, 550, 558 | ✓ All parts exist |
| V10-PREDESIGN.md Part 4 (touch point inventory) | lines 519, 524 | ✓ Part 4 exists (line 466) |
| V10-PREDESIGN.md CD-1..CD-13 | lines 108–113, 777–791 matrix | ✓ All 13 CDs listed in V10-PREDESIGN Part 2 |
| V10-PREDESIGN.md OQ-1..OQ-14 | lines 795–810 matrix | ✓ All 14 OQs listed in V10-PREDESIGN Part 3 |
| V10-PREDESIGN.md Part 8 lessons L1..L5 | lines 833–845 matrix | ✓ Part 8 "V9 Lessons Learned" exists |
| V9-DESIGN.md (format reference) | line 88, 524, 633, 681 | ✓ File exists; archive decision pending (AF-033) |
| V9-AUDIT-REPORT.md | line 585, 681 "(if present)" | ✓ File exists (correctly hedged) |
| PACK-AGENTS.md, PACK-CHAT.md | lines 42, 85, 87 | ✓ Files exist |
| README.md (layout), CLAUDE.md, BACKLOG.md | lines 84–86 | ✓ Files exist |
| TOOL-COMPARISON.md (maintenance-docs) | line 138 | ✓ File exists |
| `supporting-docs/PROMPT-TEMPLATES.md` | line 244, 292 | Live but scheduled for deletion in Phase 3 C-044-07 (AF-030) |
| `supporting-docs/METHODOLOGY.md` | line 327 | ✓ File exists; Procedure 6 landed as AD-16 |
| `supporting-docs/MIGRATION-v8-to-v9.md` (format ref) | line 398 | ✓ File exists (historical artifact) |
| `project-template/docs/pack/PM-CHAT.md` | line 245, 326 | ✓ File exists |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | line 323 | ✓ File exists |
| `project-template/skills/pm-startup/SKILL.md` | line 246 | ✓ File exists |
| `.github/workflows/validate-pack.yml`, `validate-pack.py` | lines 329, 535, 586, 590 | ✓ Files exist |

**No broken outbound references found.** Two known-future-stale
references (PROMPT-TEMPLATES.md deletion AF-030; V9-DESIGN.md archive
move AF-033) are flagged but not yet broken.

---

## Part 7 — Findings list

Severity: **ship-blocker** (must fix before v10.0 tags), **nice-to-fix**
(fix during Phase 4, not a release gate), **note** (defer, dismiss, or
informational). IDs continue from V10-AUDIT-REPORT.md (AF-001..AF-020).

---

### AF-021 — Phase numbering contradicts V10-PREDESIGN Part 7
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` lines 3
and 733.
**Issue:** V10-PREDESIGN.md Part 7 (lines 586–601) defines four phases:
(1) Process planning, (2) Design pass, (3) Implementation planning,
(4) Implementation + audit + ship. Producing V10-DESIGN.md is Phase 2
under that framing. The plan at line 3 self-labels as "Phase 1 of the
four-phase progression" and at line 733 says "Phase 1 is complete.
Phase 3 (implementation planning) can start in a new session." The plan
implicitly collapses Phases 1 and 2 into "Phase 1" and never names
Phase 2.
**Evidence:**
- Line 3: `*Plan type: Phase 1 of the four-phase progression (V10-PREDESIGN.md Part 7).*`
- Line 733: `**Exit condition.** Phase 1 is complete. Phase 3 (implementation planning) can start in a new session.`
- V10-PREDESIGN.md line 589: `1. **Process planning** — plan how to construct V10-DESIGN.md`
- V10-PREDESIGN.md line 592: `2. **Design pass** — construct V10-DESIGN.md.`
- V10-IMPLEMENTATION-PLAN.md line 1 is titled "Phase 3 — v10.0 Implementation Plan (v2)" — downstream usage matches V10-PREDESIGN's Phase 3.
**Impact:** Phase-4 reader holding V10-PREDESIGN's Phase 2 in mind will
be puzzled by the "Phase 1 → Phase 3" jump in plan Step 13. Not a
correctness defect; the workflow executed successfully.
**Suggested fix:** Either relabel the plan as "Phase 1 + Phase 2
combined" / "the design-pass workflow" in the header banner proposed by
AF-025, or add a one-line note under line 3 explicitly reconciling the
two numberings ("This plan is V10-PREDESIGN Part 7 Phase 1's output; it
also governs Phase 2's execution, which is why Step 13 hands off
directly to Phase 3.").

---

### AF-022 — Step 12 landed 5 review rounds; plan implied 1
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` §5
Checkpoint gates row G9 (line 768) and Step 12 (lines 673–703).
**Issue:** Plan §5 lists G9 as a single gate at Step 12. Step 12 prose
(line 701: "Any Critical finding goes back to pack-architect (re-enter
the relevant Block B–D step). Functional findings are fixed inline.
Polish findings can roll to v10.x.") supports iteration implicitly but
does not quantify it. V10-DESIGN.md Part 0 row 15 records "Review
rounds: 5 (step-12-review-report through step-12-review-report-v5)."
**Evidence:**
- V10-DESIGN.md line 15: `| Review rounds | 5 (step-12-review-report through step-12-review-report-v5) |`
- `ls maintenance-docs/v10-working/step-12-review-report*.md` shows report, -v2, -v3, -v5.
**Impact:** A Phase-4 reader reconstructing the design timeline from the
plan alone will under-count review iterations and under-estimate design
effort.
**Suggested fix:** Optional. If the plan remains live, add to §5 G9 row:
"In practice, executed as 5 iterative rounds (see V10-DESIGN.md Part 0)."
Otherwise accept as plan-reality drift.

---

### AF-023 — Plan anticipated AD-1..AD-13; reality has AD-1..AD-18
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
Step 11 item 1 (line 637).
**Issue:** Plan Step 11 item 1 proposes "Part 2 — Approved Decisions
(the former CDs, now AD-1 through AD-13 or renumbered; each with
rationale and rejected alternatives as in V9-DESIGN Decisions 1–9)."
V10-DESIGN.md Part 2 landed with AD-1..AD-18. AD-14..AD-18 are the
capability-addition mechanism introduced via a V10-DESIGN-2.md addendum
merge (V10-DESIGN.md Part 0 row 16, dated 2026-04-22 — one day after
initial approval).
**Evidence:**
- V10-DESIGN.md line 16: `| Merged | 2026-04-22: V10-DESIGN-2.md addendum merged (AD-14–AD-18 appended; …)`
- V10-DESIGN.md lines 553–762 contain AD-14..AD-18 bodies.
**Impact:** Plan understates the scope of approved decisions. A
Phase-4 reader using the plan as an index will need to augment it by
five ADs.
**Suggested fix:** If the plan is annotated with AF-025's status
banner, include in the banner: "V10-DESIGN.md Part 2 landed with
AD-1..AD-18; the final five (AD-14..AD-18) are the capability-addition
addendum not anticipated by this plan."

---

### AF-024 — Step 5 CD-7 description is narrower than AD-7 reality
**Severity:** nice-to-fix
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
Step 5 item 5 (line 343) and §6 CD-7 row (line 785).
**Issue:** Plan Step 5 item 5 says "CD-7 (PLATFORM-SKILLS.md
`## Custom skills` section). Specify the exact header, column
structure, and example row." V10-DESIGN.md AD-7 (line 351) is titled
"PLATFORM-SKILLS.md gains `## Custom agents` and `## Custom skills`
sections" — both sections, not just one. The plan's description of
CD-7 scope omits `## Custom agents`.
**Evidence:**
- Plan line 343: `Confirm/change CD-6 (custom skills load same way) and CD-7 (PLATFORM-SKILLS.md `## Custom skills` section).`
- V10-DESIGN.md line 351: `### AD-7 — PLATFORM-SKILLS.md gains `## Custom agents` and `## Custom skills` sections`
**Impact:** A Phase-4 reader using the plan as a scope reference for
CD-7 will miss the `## Custom agents` half. Minor — V10-DESIGN is the
authoritative source and catches the full scope.
**Suggested fix:** In the plan (if preserved live), amend Step 5 item 5
to "CD-7 (PLATFORM-SKILLS.md `## Custom agents` and `## Custom skills`
sections)." If the plan is status-banner-annotated as historical,
defer — V10-DESIGN.md is the authority.

---

### AF-025 — No status / lifecycle banner at top of file
**Severity:** nice-to-fix
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
lines 1–10.
**Issue:** The file opens with its H1 and an italic scope paragraph
directly. No status marker, no completion-date, no "see V10-DESIGN.md"
pointer. V9-DESIGN.md has a status header; V10-PREDESIGN.md has a
SUPERSEDED banner; V10-DESIGN.md has a Part 0 status table;
V10-IMPLEMENTATION-PLAN.md has a header block. This plan is the only
v10 maintenance-doc of substantial size with no lifecycle marker.
**Evidence:**
- File lines 1–10 are goal/scope statements ending at `*This plan itself also resolves OQ-6 …*` (line 7–8).
- No `*Status:`, `*Superseded by`, or equivalent tag.
**Impact:** Phase-4 reader cannot establish lifecycle from the first
screen of the document. Must scroll to Step 13 exit condition (line 733)
or cross-check commit log to realize the phase is complete.
**Suggested fix:** Insert the banner from §5 Option A immediately below
the H1:
> *Status: Complete — all 13 steps executed; exit criteria met at commit
> `4df382d` (2026-04-21). This document is a historical process artifact;
> the approved output is `maintenance-docs/V10-DESIGN.md`. Do not use for
> live decisions.*

Single-line `docs:` commit.

---

### AF-026 — File reads as live plan throughout (imperative tense)
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
entire body.
**Issue:** No passage is written in historical voice. The plan uses
"must," "will be," "developer approves," "produces" — consistent with
a live document being followed in real time.
**Evidence:** representative lines —
- Line 124: `Developer must explicitly approve before Step 2.`
- Line 215: `Produce concrete drafts — or spec precise enough that an implementer needs no design-level decisions`
- Line 353: `the PM chat detects inconsistency between …`
- Line 733: `Phase 1 is complete. Phase 3 (implementation planning) can start in a new session.`
**Impact:** Reinforces AF-025. A reader without the status banner will
believe the plan is live for several paragraphs.
**Suggested fix:** No mass rewrite required. AF-025's status banner
resolves the confusion without touching the body. If the file moves to
`archive/` (§5 Option B), the archive location itself signals status
and tense becomes immaterial.

---

### AF-027 — Predicted commit message diverges from executed form
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
Step 13 item 6 (line 727).
**Issue:** Plan predicts commit message
`docs: v9 — V10-DESIGN.md approved; supersedes V10-PREDESIGN.md`.
Commit `4df382d` landed as
`v9 — V10-DESIGN.md APPROVED; V10-PREDESIGN.md superseded` (no
`docs:` prefix, uppercase `APPROVED`, clause order reversed).
**Impact:** None functionally. A reader who cites the plan as a
commit-message style exemplar will see the actual commit differ.
**Suggested fix:** Informational only. Do not retrofit history.

---

### AF-028 — CD-13 baseline wording "v9.x" vs. AD-13 reality "v9.3"
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
§6 cross-reference matrix line 791.
**Issue:** Plan matrix says "CD-13 (v9.x baseline only)"; V10-DESIGN.md
AD-13 (line 537) specifies "Latest v9.3 is the only migration baseline."
The design pass tightened the baseline from "v9.x" to specifically v9.3.
**Impact:** A Phase-4 reader following the plan-to-AD trail will see
the baseline narrowed.
**Suggested fix:** None if AF-025 banner lands (banner signals
historical status); otherwise note the tightening in-line.

---

### AF-029 — Step 6 "v9.x → v10.0" vs. V10-DESIGN Part 6 "v9.3 → v10.0"
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
Block D heading (line 392) and Step 6 heading (line 392).
**Issue:** Plan uses "Migration design (v9.x → v10.0)" throughout Block
D; V10-DESIGN.md Part 6 (line 2041) is titled "Design: Migration v9.3 →
v10.0." Same tightening as AF-028.
**Impact:** Minor. A phase-4 reader comparing plan vs. design sees two
different labels.
**Suggested fix:** Same resolution as AF-028. No body edit required.

---

### AF-030 — Plan references PROMPT-TEMPLATES.md as live; v10 deletes it
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
Step 4 (line 244) and Step 6 (line 401).
**Issue:** Plan treats `supporting-docs/PROMPT-TEMPLATES.md` as the
current 741-line monolith to be split by the reorg. V10-IMPLEMENTATION-
PLAN.md §5 line 153 schedules `PROMPT-TEMPLATES.md deletion` as
commit C-044-07. In the landed v10 end-state the file no longer exists.
**Evidence:**
- Plan line 244: `- `supporting-docs/PROMPT-TEMPLATES.md` (current 741-line monolith).`
- V10-IMPLEMENTATION-PLAN.md line 153: `| PROMPT-TEMPLATES.md deletion | `supporting-docs/PROMPT-TEMPLATES.md` | 23 | C-044-07 (moved to Phase 3; see §5) |`
**Impact:** Phase-4 reader who follows the plan to PROMPT-TEMPLATES.md
will find the file still present on v10-dev but marked for deletion.
**Suggested fix:** None required. File deletion lands in its own
commit. If the plan's AF-025 banner lands, it already signals the
plan is historical.

---

### AF-031 — "Block A / Block B / … / Block F" organizing layer is plan-local jargon
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` §3
headings at lines 100, 177, 232, 390, 512, 624.
**Issue:** The plan groups its 13 steps into 6 Blocks (A–F). No other
v10 doc references these Blocks. V10-DESIGN.md and V10-IMPLEMENTATION-
PLAN.md cite *step numbers* only.
**Impact:** A Phase-4 reader following a cross-doc citation to
"Step 4 of V10-DESIGN-PROCESS-PLAN" will land inside Block C without
any prior exposure to Block C's meaning. Non-blocking.
**Suggested fix:** Either add a one-sentence gloss at §3 opening
("Blocks A–F are internal groupings of steps; other docs cite steps
directly."), or leave as-is. Low priority.

---

### AF-032 — Plan §0 "No BD beyond 044/045/046 is in v10" is now stale
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`
§0 line 37.
**Issue:** Plan asserts "No BD beyond 044/045/046 is in v10." Current
state: BD-047 (PM chat kickoff auto-discovery) is Resolved on v10-dev
(commit `2a0c8d5`); BD-048 was filed during Phase 3-B (commit `604895c`
"BD-048 filed").
**Evidence:**
- Plan line 37: `**BD items explicitly out of scope of this phase** (to be confirmed at Step 1 below): none. No BD beyond 044/045/046 is in v10.`
- BACKLOG.md line 1042: `**BD-047 — PM chat kickoff auto-discovery and install-check enhancement**`
**Impact:** Plan's scope fence is historically inaccurate. Only
matters if the plan is cited as live.
**Suggested fix:** None required — the plan was correct at write time.
AF-025's status banner resolves any "is this live?" confusion; no body
edit.

---

### AF-033 — V9-DESIGN.md path reference will break after archive move
**Severity:** note
**Doc + location:** `maintenance-docs/V10-DESIGN-PROCESS-PLAN.md` §2
line 88; also lines 524, 633, 681.
**Issue:** Plan lists `maintenance-docs/V9-DESIGN.md` as a baseline
input. Per main-audit Part 10 OQ 6 (project lead chose option c),
V9-DESIGN.md moves to `maintenance-docs/archive/V9-DESIGN.md`. Once
the move lands, the four path references in this plan become stale.
**Evidence:**
- Plan line 88: `- `maintenance-docs/V9-DESIGN.md` (as a format and quality reference for a completed design doc)`
- Main audit Part 10 item: V9-DESIGN.md → archive option c (chosen).
**Impact:** If the plan is preserved in place without the status
banner, Phase-4 readers following the path reference will hit a 404.
**Suggested fix:** When the V9-DESIGN.md archive move commit lands,
update the four references in this plan to
`maintenance-docs/archive/V9-DESIGN.md` — or rely on the AF-025 status
banner to signal that path references are frozen-in-time historical.

---

## Part 8 — Open questions for the project lead

Judgment calls only the project lead can resolve.

1. **AF-025 vs. §5 archive options.** Preferred resolution for
   AF-025 (status banner) and the §5 archive-candidacy question —
   Option A (banner in place), Option B (move to `archive/`), or
   Option C (no action)? Audit recommends A.

2. **AF-021 phase numbering.** Worth reconciling the plan's "Phase 1"
   self-label with V10-PREDESIGN Part 7's four-phase numbering, or
   leave as a known anomaly? If reconciling, a single line inside
   AF-025's banner suffices.

3. **AF-024 CD-7 wording correction.** Nice-to-fix in the plan body,
   or defer on the grounds that V10-DESIGN AD-7 is authoritative?
   Single-sentence edit if chosen.

4. **AF-033 V9-DESIGN.md path updates.** If the V9-DESIGN.md archive
   move lands (per main-audit decision 2), fold the V10-DESIGN-PROCESS-
   PLAN.md path updates into the same commit, or accept the brief
   stale-path window and patch separately?

5. **Out-of-scope reference flagged for awareness (not a finding).**
   The plan §2 line 82 references "`maintenance-docs/V10-PREDESIGN.md`
   (all 11 parts, in full)" — V10-PREDESIGN.md does have Parts 1–12
   (Part 12 "Agent Report File Convention" at line 822). Plan says
   "11 parts." Either V10-PREDESIGN had 11 parts at plan write time
   and Part 12 was added later, or the plan undercounts. Not in main
   audit. Flag for confirmation whether worth a correction.

---

*End of V10-AUDIT-REPORT-2.md.*
