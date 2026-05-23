# IMPLEMENTATION-REPORT — BD-173 Batch 19c.1 (H.1)

**Branch:** `v11-dev`
**Final HEAD on worktree (read-only):** `ad79bf0aef8598bed2132cd532c15d5625487d82`
**Working-tree changes:** `supporting-docs/METHODOLOGY.md` modified (+40 / -0).
**Per-batch decision:** H.1 SKIP per-commit reviewer (covered by H.4 sliding-window reviewer per V2 Decision 4 (b) + α-sliding refinement; end-of-batch H.17 reviewer is the final backstop).

## Summary

H.1 METHODOLOGY workflow clarifications applied; 4 NEW `>` callout blocks added to `supporting-docs/METHODOLOGY.md` per V2 §C.1 (METHODOLOGY half) + §C.2 + §D.3 + §C.10 (METHODOLOGY half rendered as callout per planner Observation 3 (b)). No other files touched. No git state changes. No manifest regen (Pack Chat handles RC9 step).

## Edits applied

### Edit 1 — §C.1 METHODOLOGY callout (always-reviewer cycle invariant)

- **V2 source section:** §C.1 second text block (`> **Cycle invariant — reviewer always runs.** ...`).
- **V2 source line range:** V2 lines 226-235 (the second fenced text block under §C.1, second "V2 text" sub-block).
- **Insertion location:** Part 5 Workflow 2, at the end of the Workflow 2 section, immediately after the pre-existing `agent-run.sh` callout (which closes at the original L420), and immediately before the `### Workflow 3` header.
- **At HEAD post-edit:** new callout occupies lines 422-431; followed by blank line at L432; Workflow 3 header at L433.
- **Before/after one-liner:**
  - BEFORE: `> per-CLI flag details.` (end of agent-run.sh callout) → blank → `### Workflow 3 ...`
  - AFTER: `> per-CLI flag details.` → blank → NEW `> **Cycle invariant — reviewer always runs.** ...` (10 content lines) → blank → `### Workflow 3 ...`
- **Edit type:** NEW callout block (10 content lines + 1 trailing blank).
- **Content fidelity:** verbatim against V2 §C.1 second "V2 text" block (no wording changes).

### Edit 2 — §C.2 STRENGTHEN (architect-trigger surface-even-mechanical)

- **V2 source section:** §C.2 (`> **Surface mechanical-looking trigger hits explicitly.** ...`).
- **V2 source line range:** V2 lines 250-258 (the "V2 text" fenced block under §C.2).
- **Insertion location:** Part 5 Workflow 4 → `#### Architect trigger conditions`, immediately after the "Trigger B" paragraph and BEFORE the pre-existing `> **Why this matters:** ...` callout.
- **At HEAD post-edit:** Trigger B paragraph ends at L533 (`whichever count is larger`); blank at L534; new callout occupies L535-542; blank at L543; pre-existing "Why this matters" callout begins at L544.
- **Before/after one-liner:**
  - BEFORE: `previous pass — whichever count is larger` → blank → `> **Why this matters:** ...`
  - AFTER: `previous pass — whichever count is larger` → blank → NEW `> **Surface mechanical-looking trigger hits explicitly.** ...` (8 content lines) → blank → `> **Why this matters:** ...`
- **Edit type:** NEW callout block (8 content lines + 1 trailing blank).
- **Content fidelity:** verbatim against V2 §C.2 "V2 text" block.

### Edit 3 — §D.3 cycle-termination clarification

- **V2 source section:** §D.3 (`> **Cycle termination.** The fix cycle terminates ...`).
- **V2 source line range:** V2 lines 697-708 (the "V2 text" fenced block under §D.3).
- **Insertion location:** Part 5 Workflow 4, immediately after the Workflow 4 fenced code block (closes at the original L449) and BEFORE the pre-existing `> **The PM chat does not execute fix passes directly.** ...` callout.
- **At HEAD post-edit:** fenced block closes at L460 (` ``` `); blank at L461; new callout occupies L462-471; blank at L472; pre-existing "PM chat does not execute fix passes directly" callout starts at L473.
- **Before/after one-liner:**
  - BEFORE: ` ``` ` (fence close) → blank → `> **The PM chat does not execute fix passes directly.** ...`
  - AFTER: ` ``` ` (fence close) → blank → NEW `> **Cycle termination.** ...` (10 content lines) → blank → `> **The PM chat does not execute fix passes directly.** ...`
- **Edit type:** NEW callout block (10 content lines + 1 trailing blank).
- **Content fidelity:** verbatim against V2 §D.3 "V2 text" block.

### Edit 4 — §C.10 METHODOLOGY half (architect-output user-reads, rendered as callout per planner Observation 3 (b))

- **V2 source section:** §C.10 second target ("V2 AFTER text" for METHODOLOGY.md Workflow 4 step 4).
- **V2 source line range:** V2 lines 505-513 (the "V2 AFTER text" fenced block under §C.10; the format in V2 is a numbered-step inside-fence rendering, "4. **Present proposed doc changes and wait for the user to read.** ...").
- **Format-shape conversion:** Per planner Observation 3 (b) approved by user 2026-05-23, the V2 numbered-step `4. **Present proposed doc changes and wait for the user to read.** Show the user...` was rendered as a `>` CALLOUT BLOCK after the fenced Workflow 4 block (paralleling the existing "The PM chat does not execute fix passes directly." callout), NOT as an in-fence step-4 STRENGTHEN. The substantive content is preserved verbatim; only the rendering shape changed from numbered-step-in-fence to `>` callout-after-fence. The leading `4. ` ordinal was dropped because the callout no longer sits inside the numbered list.
- **Insertion location:** Part 5 Workflow 4, immediately AFTER the pre-existing "The PM chat does not execute fix passes directly." callout (which closes at the original L453) and BEFORE the `#### PM chat triage protocol — reviewer findings` sub-section header.
- **At HEAD post-edit:** "PM chat does not execute fix passes directly" callout closes at L475; blank at L476; new callout occupies L477-484; blank at L485; `#### PM chat triage protocol` header at L486.
- **Before/after one-liner:**
  - BEFORE: `> The coder agent executes the fix; the PM chat does not.` → blank → `#### PM chat triage protocol — reviewer findings`
  - AFTER: `> The coder agent executes the fix; the PM chat does not.` → blank → NEW `> **Present proposed doc changes and wait for the user to read.** Show the user exactly what the architect proposes to change. The PM chat WAITS for the user to read the architect's full report before suggesting any follow-on step — do not auto-advance to the next step, do not auto-stage changes, do not propose "ready to commit" until the user has signaled they have read the report. Get explicit approval for each change before applying it.` (8 content lines) → blank → `#### PM chat triage protocol — reviewer findings`
- **Edit type:** NEW callout block (8 content lines + 1 trailing blank).
- **Content fidelity:** substantive content verbatim against V2 §C.10 "V2 AFTER text" block; only rendering shape converted from numbered-step prose to `>` callout block (no `4. ` ordinal). All other words preserved exactly.

## Anchor verification

V1-cited line numbers vs HEAD-actual anchor used (durable anchor was the surrounding-line content cues, not the line numbers, per the prompt's directive):

| V1 cite | V1 expectation | HEAD-actual anchor used | Drift? |
|---|---|---|---|
| §C.1 → L410 | "immediately after the fenced code block closing at L410" | Fenced block closes at L410 at HEAD as cited; but a pre-existing `agent-run.sh` callout (L412-420) sits between fence-close and Workflow 3. New `Cycle invariant` callout inserted AFTER the `agent-run.sh` callout (still at "end of Workflow 2 block" per PLAN §3 H.1 step 1's wording). | Position-drift only — not a wording drift. New callout placed at end of Workflow 2 cluster (after agent-run.sh callout), preserving "at end of Workflow 2 block" intent. |
| §C.2 → L503 | "Immediately after the Trigger B paragraph closing at L503" | Trigger B paragraph closes at L502-503 area at HEAD as cited; pre-existing "Why this matters" callout begins at L504. New callout inserted in the gap between L503 and the L504 callout — exactly as PLAN §3 H.1 step 2 specified ("insert the new callout BETWEEN Trigger B (L498-503) and the 'Why this matters' callout (L504-508)"). | No drift. |
| §D.3 → L449 | "Immediately after the Workflow 4 fenced code block closing at L449" | Workflow 4 fenced block closes at L449 at HEAD as cited; pre-existing "PM chat does not execute fix passes directly" callout starts at L451. New `Cycle termination` callout inserted between fence-close (L449) and pre-existing callout (L451), exactly as PLAN §3 H.1 step 3 specified. | No drift. |
| §C.10 → L522-523 | V2 BEFORE matches existing fenced step 4 line at L521-522 | Per planner Observation 3 (b), §C.10 METHODOLOGY half NOT applied as in-fence step-4 STRENGTHEN. Instead applied as NEW `>` callout block AFTER the pre-existing "PM chat does not execute fix passes directly" callout (which originally ended at L453) and BEFORE `#### PM chat triage protocol`. The fenced step 4 at L521-522 is UNCHANGED. | Not a drift — a deliberate format-shape change per planner Observation 3 (b) approved by user 2026-05-23. The in-fence step 4 wording remains the original ("Present proposed doc changes — show the user exactly..."); the new callout sits as a sibling reinforcement after fence-close. |

No genuine line-number drift was a blocker; all 4 insertion anchors at HEAD resolved cleanly via the surrounding-line content cues. The pre-existing `agent-run.sh` callout in Workflow 2 (which is a BD-178-era addition) accounts for the position-only drift in Edit 1; the §C.10 format-shape change is intentional (not drift) per planner Observation 3 (b).

## Format-shape conversion for §C.10 (planner Observation 3 (b))

Per planner Observation 3 (b) approved by user 2026-05-23, V2 §C.10 METHODOLOGY half lands as a NEW `>` CALLOUT BLOCK after the fenced Workflow 4 block, NOT as an in-fence step-4 STRENGTHEN.

- **V2 AFTER text in V2 doc** (lines 505-513): rendered as numbered-step prose inside the fence (`4. **Present proposed doc changes and wait for the user to read.** Show the user exactly what the architect proposes to change. ...`).
- **As applied in METHODOLOGY.md** (lines 477-484): rendered as `>` callout block after fence-close (paralleling the existing "The PM chat does not execute fix passes directly." callout at original L451-453, now at L473-475).
- **Substantive content preserved verbatim.** Only changes:
  - Dropped leading `4. ` ordinal (callout is no longer inside the numbered list).
  - Each line prefixed with `> ` for callout rendering.
  - Words otherwise identical to V2 source.
- **Position chosen:** AFTER the pre-existing "PM chat does not execute fix passes directly." callout (not before it). Rationale: the two callouts together form a behavioral-rules cluster reinforcing the user-reads-before-next-step posture, and the new §C.10 callout extends/specializes the prior "PM chat does not execute" callout to the architect-output decision class — logical-flow positions §C.10 immediately AFTER its more general sibling, so the more specific rule reads as an application of the broader one.
- **In-fence step 4 is UNCHANGED.** The original Workflow 4 fenced step 4 line ("Present proposed doc changes — show the user exactly what the architect proposes to change. Get explicit approval for each change before applying it.") at HEAD L521-522 was NOT modified — only the new callout was added below the fence. This is exactly what planner Observation 3 (b) directed: the prose strengthen reads as a callout AFTER fence, not as a wording change INSIDE fence.

## Strict-scope adherence

- **Commit subject scope keyword:** (mixed — no keyword) per PLAN §3 H.1 post-M-1 fix (CLAUDE.md Check 36 mixed-surface rule; commit touches supporting-docs/METHODOLOGY.md project-side + maintenance-docs/IMPL-REPORT pack-side + test-fixtures/manifest.txt pack-side).
- **Files edited:** EXACTLY ONE — `supporting-docs/METHODOLOGY.md`. Confirmed via `git diff --stat` showing only this file modified.
- **Files NOT edited:** all others. No trinity (CLAUDE.md / AGENTS.md / GEMINI.md at pack-root or project-template), no PM-CHAT.md, no scripts/, no test-fixtures/, no maintenance-docs/ except for this report's WRITE target.
- **Git state changes:** NONE. No `git add`, no `git commit`, no `git push`, no `git tag`, no `git reset`, no `git checkout` for state mutation. Only read-only `git status`, `git diff --stat`, `git rev-parse HEAD`.
- **Manifest regen:** NOT performed by coder. Pack Chat handles RC9 (`bash test-fixtures/build.sh --all --clean`) after this IMPL-REPORT lands, per the calling prompt's "Files OUT of scope" directive.
- **Observations beyond scope:** none fixed; surfaced below for Pack Chat triage.

## Observations (do NOT fix; for Pack Chat triage)

None blocking. Some notes recorded during reading:

1. **HEAD drift from prompt cite.** The calling prompt cited HEAD `4a3dfea`, but actual HEAD at coder pre-flight was `ad79bf0aef8598bed2132cd532c15d5625487d82`. Working tree was clean; no in-flight edits to reconcile. The drift is benign — no insertion anchor was affected because anchor matching was content-based, not line-number-based. Surfacing only because PLAN §3 H.0 step 1 instructs coder to "Verify HEAD: `git rev-parse HEAD` should match the plan's recorded HEAD `9a95bfa` or a descendant" — `ad79bf0` is a descendant of `4a3dfea` (which was itself a descendant of `9a95bfa`), so the chain is valid.

2. **Edit 1 position rationale — Workflow 2 cluster ordering.** Edit 1 (`Cycle invariant — reviewer always runs`) was placed AFTER the pre-existing `agent-run.sh` callout at end of Workflow 2 (so the callout sequence reads: fence-close → `agent-run.sh` callout → `Cycle invariant` callout → Workflow 3). The alternative position would have been BEFORE the `agent-run.sh` callout (so: fence-close → `Cycle invariant` callout → `agent-run.sh` callout → Workflow 3). I chose AFTER because the `agent-run.sh` callout is an annotation of the fence-block invocations (immediate context-attachment) and the `Cycle invariant` callout is a behavioral assertion about the workflow as a whole (logical-flow positions it after the immediate annotation). PLAN §3 H.1 step 1 said "at end of Workflow 2 block" without specifying inter-callout order; this rationale is the coder's interpretation of "end of block". Pack Chat can flip the ordering during review if preferred.

3. **No mid-pipeline reviewer-finding fixes.** Per the calling prompt's "Strict scope discipline" section, no other inconsistencies, typos, or improvements were addressed even when noticed. None notable were found in the read scope.

4. **V2 §C.10 AFTER text vs callout rendering — `4. ` ordinal handling.** When converting V2's numbered-step format `4. **Present proposed doc changes and wait for the user to read.**` to `>` callout, the `4. ` ordinal was dropped because the callout does not sit inside a numbered list. This is the only word-level deviation from V2 verbatim text; all other words are preserved exactly. The conversion is faithful to "shape change only" per planner Observation 3 (b) approved by user 2026-05-23.

## PREFLIGHT line

PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD ad79bf0aef8598bed2132cd532c15d5625487d82; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.1.md

## Files changed inventory

| Path | Change type | Lines delta |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | modified | +40 / -0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.1.md` | new (this report) | new file |

No other files touched.

## Definition-of-Done checklist

- [x] PASS — 4 NEW callout blocks added to `supporting-docs/METHODOLOGY.md` per V2 §C.1 (METHODOLOGY half) + §C.2 + §D.3 + §C.10 (METHODOLOGY half via planner Observation 3 (b) format-shape callout rendering).
- [x] PASS — All content verbatim from V2 source sections, modulo §C.10's intentional format-shape conversion from numbered-step prose to `>` callout (substantive content preserved verbatim; only `4. ` ordinal dropped + lines prefixed with `> `).
- [x] PASS — No other METHODOLOGY.md lines modified (verified via `git diff` showing only +40 / -0).
- [x] PASS — No other files touched (verified via `git status` showing only `supporting-docs/METHODOLOGY.md` modified).
- [x] PASS — No git state changes (no `git add`, no `git commit`, no state-mutating verbs).
- [x] PASS — No `test-fixtures/build.sh` invocation (Pack Chat handles RC9 manifest regen).
- [x] PASS — IMPL-REPORT written to the specified `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.1.md` path.
- [x] PASS — PREFLIGHT line emitted before IMPL-REPORT write (in chat output and in the report body).
- [x] PASS — No new POQs introduced (none surfaced from this scope).
- [x] PASS — No plan deviations (planner Observation 3 (b) format-shape conversion is per the prompt, not a deviation).
