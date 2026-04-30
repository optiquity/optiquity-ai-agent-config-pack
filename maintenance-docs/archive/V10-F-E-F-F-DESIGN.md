# V10-F-E-F-F-DESIGN — Post-migration housekeeping (stale pack-version markers + unfilled trinity placeholders)

**Author:** pack-architect (Phase 4 patch design pass)
**Date:** 2026-04-29
**Status:** Draft — design pass only. Implementer (parent pack chat) commits
after project-lead approval. This document does not edit any pack source file.
**Related:** `maintenance-docs/V10-PHASE-4-VERIFICATION.md` § F-E (proposed;
v10.0 patch) and § F-F (proposed; v10.1 candidate per the verification doc,
combined here per project-lead intent); Supplementary findings (`/pm-startup`
on OT clone). Companion to `V10-F-D-DESIGN.md` (METHODOLOGY canonical
location); same Phase 4 patch cohort.

---

## 0. Status and scope

`/pm-startup` on a v10-migrated real project (OT clone) flagged two
post-migration housekeeping defects that the migration script does not
address:

- **F-E.** Project-internal docs carry stale `**AI Agent Config Pack**: v9`
  markers (typically in `docs/project/STATUS.md`). Post-migration the
  project content says v9 even though the pack content is v10.
- **F-F.** Trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) carry
  unfilled `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, and
  `**Active skills:**` placeholders. Migration's S5 splice runs but does
  not surface these to the developer.

Both defects share four properties:

1. **Detection-resolvable.** `/pm-startup` already detects both today
   (per V10-PHASE-4-VERIFICATION.md line 829: "stale pack version in
   STATUS.md, unfilled trinity placeholders").
2. **PM-chat-resolvable.** Once surfaced, the PM chat can reconcile both
   in a structured Q&A — no scripting required.
3. **One-shot.** After reconciliation the work is done; the trigger
   should not fire again.
4. **Project-state-variable.** STATUS.md may not exist; trinity
   placeholders may already be filled; pre-state varies project-to-project.

The natural resolution shape — **a one-shot METHODOLOGY procedure triggered
at PM-chat startup, run once, self-cleans** — already has a precedent:
**Procedure 5-R** (METHODOLOGY.md line 1206), which reconciles v9.3
PROMPT-TEMPLATES customizations after migration via the same
trigger-execute-cleanup pattern.

Scope of this design pass:

- Decide whether F-E and F-F are one procedure or two.
- Choose a trigger mechanism that survives project-shape variation.
- Specify the self-cleanup mechanism.
- Decide how `/pm-startup` SKILL routes to the new procedure.
- Specify what migration script S7 must emit.
- Inventory the file cascade.
- Confirm trinity-rule compliance.
- Flag open questions for project lead.

Out of scope (deferred to implementation):

- Producing diffs.
- Editing any pack source file.
- Filing the BD-NNN entry (Pack Chat owns).
- Verification fixture rebuild planning (Pack Chat / pack-planner own).

---

## 1. Decision — summary

**One combined procedure: Procedure 5-S — post-migration housekeeping.**
Same shape as Procedure 5-R. Triggered by a single sentinel file written
by `migrate-v9-to-v10.sh` S7 (`.pack-migration-backup/v9.3-to-v10.0/postrun-pending`).
`/pm-startup` SKILL gains one explicit pre-Step-1 detection block that
checks for the sentinel and routes to Procedure 5-S; cleanup is the
deletion of the sentinel as the final procedure step. The procedure body
in METHODOLOGY is terse (~25 lines including a small per-task table) and
robust to STATUS.md absence and to already-filled placeholders.

The five specific design questions resolved:

| # | Question | Answer |
|---|---|---|
| 1 | F-E + F-F combined or split? | **Combined.** Single procedure with two task sub-sections. (§2) |
| 2 | Trigger mechanism? | **Sentinel file written by S7.** (§3) |
| 3 | Self-cleanup? | **Procedure deletes sentinel as final step.** (§4) |
| 4 | `/pm-startup` SKILL routing? | **Explicit per-procedure detection block** in pre-Step-1 — not a generic mechanism. (§5) |
| 5 | Robustness to project variation? | **Procedure scans for markers; "no markers found" is a clean exit, not a defect.** (§6) |

---

## 2. F-E + F-F combined or split?

### 2.1 Decision: combined

Both defects are **post-migration housekeeping** with identical lifecycle:
detected at first PM chat after migration, run once, never run again.
Splitting them produces two procedures with two triggers and two cleanup
paths and two `/pm-startup` SKILL detection blocks — a 2× cost across all
four files in the cascade for no semantic gain.

The procedure body has two task sub-sections (F-E task / F-F task) but
shares trigger, gate structure, completion criterion, and cleanup. The
shared scaffolding dominates the per-task content — combining is the
elegance-preserving choice (per CLAUDE.md "prefer fewer special cases").

### 2.2 Why combining is safe

- **Independent task execution.** Each task scans for its own marker
  pattern. If F-E's pattern is present and F-F's is not (or vice versa),
  the procedure runs the present task and skips the absent one. No
  cross-coupling.
- **Independent failure modes.** F-E reconciliation does not depend on
  F-F state and vice versa. If the developer defers one task, the
  other can still complete.
- **Same trigger-set predicate.** Both fire on "first PM chat after
  migration." Migration script S7 is the single point at which both
  conditions become true; that is the natural trigger point for both.

### 2.3 Why combining is preferred over Procedure 5-R-style splitting

Procedure 5-R is its own procedure (not combined with 5-S) because its
trigger condition (`_v9-backup.md` exists, indicating PROMPT-TEMPLATES
customization) is independent of the migration-completion condition (5-S
fires on every migration; 5-R fires only when customization exists).
Different triggers → different procedures. F-E and F-F share the same
trigger condition (every migration), so they share a procedure.

**Split rejection:** A split design would put the F-F task under 5-S
and create a separate "Procedure 5-T" for F-E, or vice versa. Both
procedures would carry the same sentinel-detection / sentinel-cleanup
boilerplate. The verification cost (two new procedures to test instead
of one) and the RAG cost (METHODOLOGY duplication) are the principal
penalties; no offsetting benefit.

---

## 3. Trigger mechanism

### 3.1 Decision: sentinel file written by migration script S7

The migration script's S7 stage writes a sentinel file:

```
.pack-migration-backup/v9.3-to-v10.0/postrun-pending
```

(Exact path/name is implementer's choice; the contract is "single sentinel
file inside the backup directory, written by S7, deleted by Procedure 5-S
final step.")

Procedure 5-S triggers on **presence of this file at PM chat startup.**

### 3.2 Rejected alternative — (a) reuse `_v9-backup.md`

`_v9-backup.md` only exists when v9.3 PROMPT-TEMPLATES.md diverged from
the pack baseline (per migrate-v9-to-v10.sh line 397). Per
V10-PHASE-4-VERIFICATION.md §4.6, OT's v9.3 PROMPT-TEMPLATES was
unmodified (the divergence-detection branch was not taken in real-project
testing — see line 391's `if "$v93_content" == "$proj_content" then ...
delete`). For OT and any project that did not customize PROMPT-TEMPLATES,
`_v9-backup.md` is never created and the trigger never fires —
**precisely the case in which `/pm-startup` actually surfaced F-E and
F-F.** Reusing `_v9-backup.md` would miss the most common case.

### 3.3 Rejected alternative — (c) detection-based (scan STATUS.md / trinity at every startup)

At first glance attractive: no sentinel, no script edit, just have
`/pm-startup` grep for the markers and fire if found. Defects:

1. **Runs at every session.** `/pm-startup` runs every PM chat session
   start (not just post-migration). Putting STATUS.md and trinity grepping
   there imposes the cost on every session forever, not just once.
2. **False positives forever.** A project that legitimately has
   `[PLATFORM_TARGETS]` somewhere in a quoted string in BACKLOG.md or in
   a project's own template will trigger every session. The "no false
   positives" property is not free; it's project-shape-dependent.
3. **No clear "done" signal.** A scan-based trigger fires until the
   markers are gone. A sentinel-based trigger fires until the procedure
   completes. The latter has explicit cleanup; the former depends on the
   developer (or PM chat) actually fixing every marker — and the
   procedure has no way to declare "this scan was good enough; stop
   nagging."
4. **Couples post-migration housekeeping with steady-state operation.**
   The sentinel pattern keeps post-migration concerns out of steady-state
   `/pm-startup` flow.

### 3.4 Rejected alternative — (d) hybrid (sentinel + scan-confirm)

Sentinel sets the flag; detection re-confirms work is needed before
running. Pros: catches "developer manually fixed markers between migration
and first PM chat" (sentinel present, but no work to do). Cons:
two-mechanism complexity. The same property is achievable with a single
mechanism: **sentinel + tolerant procedure** (procedure scans, finds
nothing, reports "all markers already addressed", deletes sentinel,
exits clean). That is the §6 design and absorbs (d)'s benefit without
adding a second mechanism.

### 3.5 Why sentinel is preferred

- **Explicit causality.** The trigger is set by the act that creates the
  problem (migration). Cleanup happens when the problem is fixed. No
  ambient scanning.
- **Robust to false positives.** Sentinel exists ⟺ recent migration
  pending reconciliation. No project-content state can spuriously
  set or clear it.
- **Symmetric with Procedure 5-R.** 5-R triggers on a file
  (`_v9-backup.md`) at a known path inside `docs/pack/prompts/`. 5-S
  triggers on a file inside `.pack-migration-backup/v9.3-to-v10.0/`.
  Same shape; the SKILL detection logic is parallel.
- **Cheap to implement.** One `mkdir -p` + one `touch`-equivalent in
  the migration script S7; one `[[ -f ... ]]` in `/pm-startup` SKILL.

### 3.6 Sentinel location rationale

Inside `.pack-migration-backup/v9.3-to-v10.0/` because:

- That directory already exists (created by S0); no new directory
  invention.
- The `.pack-migration-backup/` directory is documented as expected
  post-migration state (MIGRATION-v9-to-v10.md Step 2, Step 7).
- Deleting the entire backup directory after migration (per
  MIGRATION-v9-to-v10.md Step 7 — "you can delete the
  `.pack-migration-backup/` directory once you're confident") deletes
  the sentinel along with it, which is the correct semantics: if the
  developer has cleaned up the migration backup, post-migration
  housekeeping is no longer relevant.
- Putting the sentinel anywhere else (project root, `docs/`, etc.)
  would clutter project space with a one-shot file.

---

## 4. Self-cleanup mechanism

### 4.1 Decision: Procedure 5-S deletes the sentinel as its final step

Last numbered step of Procedure 5-S:

> *N. PM chat offers to remove the sentinel file*
> `.pack-migration-backup/v9.3-to-v10.0/postrun-pending`
> *and records the housekeeping in the commit message. Once removed,
> Procedure 5-S does not run again.*

This is verbatim parallel to Procedure 5-R step 6 (METHODOLOGY.md line
1226: *"PM chat offers to remove `_v9-backup.md` and records the
reconciliation in the commit message. Once removed, Procedure 5-R does
not run again."*).

### 4.2 Why "PM chat offers" not "PM chat deletes silently"

Same reason Procedure 5-R asks for confirmation: deletion is an
observable project-state change and should be developer-acknowledged.
The sentinel is small; leaving it in place an extra session has no
adverse effect. The bias is toward visible, approved cleanup.

### 4.3 Defer / partial-completion handling

If the developer defers either F-E task or F-F task (for example, "I'll
fix STATUS.md later"), the procedure does **not** delete the sentinel.
On next `/pm-startup`, the procedure fires again. The sentinel acts as
a persistent reminder until the developer explicitly says "we're done
with the housekeeping." This matches Procedure 5-R's behavior (which
also surfaces incrementally and only cleans up on completion).

The procedure tracks task completion through the developer's responses
in the same session; it does not need persistent state. If the session
ends mid-procedure, the next `/pm-startup` re-detects the sentinel and
re-runs the procedure from the top. The procedure must therefore be
**re-entrant** — re-scanning markers, presenting only those still
present. This is naturally satisfied by the §6 marker-scan design.

---

## 5. `/pm-startup` SKILL routing

### 5.1 Decision: explicit per-procedure detection block (not generic auto-discovery)

Add a single new step at the top of `/pm-startup` SKILL:

```
## Step 0 — Check for pending one-shot procedures

Run:
    [[ -f .pack-migration-backup/v9.3-to-v10.0/postrun-pending ]] && \
        echo "POSTRUN-PENDING: Procedure 5-S"
    [[ -f docs/pack/prompts/_v9-backup.md ]] && \
        echo "PROMPT-RECON-PENDING: Procedure 5-R"

If any line is emitted, do not run the standard startup sequence.
Instead, route to the named METHODOLOGY procedure(s) and run them now.
After all triggered procedures complete (or the developer defers),
resume the standard startup sequence at Step 1.
```

This adds **two if-checks** — one for the existing 5-R trigger (which is
currently routed through MIGRATION-v9-to-v10.md prose, not the SKILL —
fixing a latent gap) and one for the new 5-S trigger.

### 5.2 Rejected alternative — generic "scan METHODOLOGY for triggered procedures" mechanism

A generic mechanism would have the SKILL discover all triggered
procedures dynamically — for example, by reading METHODOLOGY's
machine-readable trigger metadata.

Rejected on three grounds:

1. **Scaling pressure is wrong-direction.** The pack has two one-shot
   procedures today (5-R, 5-S). Even if every future major version adds
   one more, we're at small N for the lifetime of the pack. A generic
   discovery mechanism is over-engineering for N≤5.
2. **Token cost.** A generic mechanism requires METHODOLOGY to encode
   triggers in a machine-readable format (front-matter blocks, special
   sections, or similar). Every procedure pays the encoding cost. The
   cost is paid forever in RAG ingest. The if-block approach costs ~3
   lines once per procedure in the SKILL and zero lines in METHODOLOGY.
3. **Failure modes are worse.** If METHODOLOGY trigger metadata drifts
   from actual procedure body content (a real risk during pack
   evolution), the generic mechanism fires the wrong procedure or fails
   to fire the right one. The if-block approach binds each trigger to
   its detection logic in code review — easy to verify; explicit.

### 5.3 The "scaling by N" objection addressed

Per the prompt's explicit framing: "Should /pm-startup SKILL get
explicit per-procedure detection logic added (one if-block per known
procedure trigger)? Or should /pm-startup get a generic 'scan METHODOLOGY
for triggered procedures' mechanism that auto-discovers all such
triggers?"

Per-procedure if-blocks scale linearly with the count of one-shot
procedures. The generic mechanism scales with constant SKILL code but
requires METHODOLOGY-side infrastructure. The crossover point is
"how many one-shot procedures will the pack ever have?" Realistic
answer: ≤5 across all foreseeable versions. Linear-with-N at N≤5 is
3–15 lines in the SKILL — clearly cheaper than building generic
trigger-discovery infrastructure once.

If the pack ever grows past N≈10 one-shot procedures, revisit the
choice. **Until then, per-procedure if-blocks are the elegance-preserving
choice.**

### 5.4 Step 0 placement rationale

Step 0 (before "Step 1 — Sync repo") because:

- One-shot procedures may need to interrupt the standard startup. If
  Procedure 5-S is mid-flight, computing "current phase" or "open
  BACKLOG count" is premature — those values may change as the
  developer reconciles trinity placeholders.
- Putting it after Step 1 wastes a `git pull` cycle on a session that's
  going to do reconciliation work, not phase work.
- Putting it last (after Step 6 reporting) means the report goes out
  with stale values that the procedure would then update — confusing.

### 5.5 SKILL distribution propagation

The SKILL source-of-truth lives at
`project-template/skills/pm-startup/SKILL.md`. `init-project.sh` S4
distributes it (per the script's lines 295–304) to:

- `.claude/skills/pm-startup/SKILL.md`
- `.codex/skills/pm-startup/SKILL.md`
- `.gemini/skills/pm-startup/SKILL.md`

**One source-of-truth edit; distribution is automatic.** No manual
trinity-style triple-edit required for the SKILL itself. (The trinity
rule applies to CLAUDE.md / AGENTS.md / GEMINI.md context files, not to
distributed skills.)

---

## 6. Robustness to project-specific variation

### 6.1 The "marker not found" problem

F-E specifies `**AI Agent Config Pack**: v9` in STATUS.md, but:

- A project may have STATUS.md at a non-standard path (e.g.,
  `docs/STATUS.md` instead of `docs/project/STATUS.md`).
- The marker may use `v9.3` or `Pack: v9` or
  `## AI Agent Config Pack version: v9` or any of a dozen variants.
- The project may have no STATUS.md at all (some v9.3 projects didn't
  use one).
- The marker may be at the correct version already (developer already
  fixed it, or the project was created at v10).

F-F specifies `[PROJECT_NAME]` / `[PLATFORM_TARGETS]` / `[TRANSPORT]`,
but:

- A subset may already be filled (some projects fill PROJECT_NAME but
  not PLATFORM_TARGETS, etc.).
- The Active-skills line may be already populated.
- Custom placeholders the project added may not match the standard set.

### 6.2 Decision: tolerant scan; "no markers found" is success

Procedure 5-S task structure:

```
Task A — STATUS.md pack-version reconciliation (F-E)
1. Search project for files matching docs/project/STATUS.md,
   docs/STATUS.md, STATUS.md (in priority order).
2. For each file found, grep case-insensitively for lines matching the
   pattern "AI Agent Config Pack" (or "Pack version") AND a "v9" token.
3. If matches: surface each match with proposed update to current pack
   version (read from METHODOLOGY.md first 5 lines, per pm-startup
   Step 6). Developer approves / edits / skips per match.
4. If no STATUS.md found, or no v9 markers found: report
   "Task A — no stale pack-version markers found; nothing to do."

Task B — Trinity placeholder reconciliation (F-F)
1. Grep CLAUDE.md, AGENTS.md, GEMINI.md for occurrences of the regex
   \[[A-Z_]+\] limited to whitelisted placeholder names
   (PROJECT_NAME, PLATFORM_TARGETS, TRANSPORT, PLATFORM_DEFAULTS,
   PLATFORM_ARCHITECTURE, LANGUAGE_RULES, GRPC_RULES, PLATFORM_SECURITY,
   PLATFORM_TESTING, PLATFORM_ANTIPATTERNS).
2. Grep the same files for the literal string
   "Active skills: [PM chat writes" (the placeholder Active-skills line).
3. If any matches: surface findings; ask the developer for project
   identifiers (project name, platform targets, transport); offer to
   fill placeholders consistently across all three trinity files
   (TRIO — same value in CLAUDE.md / AGENTS.md / GEMINI.md). For Active
   skills: invoke the standard PM-CHAT.md kickoff flow for the
   Active-skills line if it is not yet set.
4. If no placeholder regex matches and Active-skills is filled: report
   "Task B — trinity already fully reconciled; nothing to do."
```

### 6.3 Why a whitelisted placeholder regex (not just `\[[A-Z_]+\]`)

A pure `\[[A-Z_]+\]` regex would false-positive on:

- BACKLOG entries that quote example placeholders (e.g., `[PROJECT_NAME]`
  inside a markdown code fence, used as documentation).
- Trinity files that legitimately reference the placeholder names in
  prose explanation (the Active-skills line itself contains "PM chat
  writes ... Example: ...").

Whitelisting to the known set in V10-DESIGN.md and CLAUDE.md (lines 49,
56, 60–62 of `project-template/CLAUDE.md`: `[PLATFORM_DEFAULTS]`,
`[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`,
`[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`)
plus the project-identifier set (`[PROJECT_NAME]`, `[PLATFORM_TARGETS]`,
`[TRANSPORT]`) gives a closed-form list. Anything outside the whitelist
is by definition not a v10-template placeholder and should not be
flagged.

### 6.4 "No work to do" is a clean exit

If both tasks report "nothing to do," Procedure 5-S still:

1. Reports the clean state to the developer.
2. Offers to delete the sentinel.
3. Resumes the normal `/pm-startup` flow at Step 1.

This handles the case where the developer manually reconciled markers
between running the migration script and starting the first PM chat.
The sentinel is removed, the procedure does not fire again, and no
false positives are surfaced. This is the §3.4 "tolerant procedure
absorbs hybrid (d)'s benefit" property.

### 6.5 Re-entrancy under partial completion

If the developer reconciles Task A but defers Task B (or vice versa),
the procedure does not delete the sentinel. On the next `/pm-startup`:

- Task A re-scans → finds no v9 markers (already reconciled) → reports
  "nothing to do."
- Task B re-scans → finds remaining placeholders → resurfaces.
- Sentinel persists until both tasks report clean.

The re-scan cost is negligible (a few greps over <10 files). The
re-entrancy property is achieved without extra state.

---

## 7. What migration script S7 must do

### 7.1 High-level specification (not bash)

In `scripts/migrate-v9-to-v10.sh` stage `stage_s7_report` (after the
existing report-write block, before `write_sentinel "S7"`):

1. **Write the postrun-pending sentinel.**
   ```
   touch "$BACKUP_DIR/postrun-pending"
   ```
   (Or equivalent — a zero-byte file at this path. Optionally add a
   one-line content like `procedure: 5-S` for human readability if a
   developer cats the file.)

2. **Add a "Post-migration housekeeping" section to the report.**
   The existing report's "Next steps" section (migrate-v9-to-v10.sh
   line 437–443) gets a new bullet:
   ```
   - At your next PM chat session, expect the PM chat to invoke
     Procedure 5-S (post-migration housekeeping): scans STATUS.md
     for stale pack-version markers and trinity files for unfilled
     placeholders. The procedure self-cleans once you confirm
     completion.
   ```

3. **No other S7 changes required.** The sentinel is created
   unconditionally at the end of every successful migration. No
   conditional logic ("only set sentinel if F-E or F-F detectable")
   — the procedure itself handles "nothing to do" gracefully (§6.4),
   so an unconditional sentinel keeps S7 simple and uniform.

### 7.2 Idempotency under resumed migration

The existing S7 sentinel-skip pattern (`if sentinel_exists "S7"; then
... return 0; fi`, line 410) means S7 only runs once per migration.
Re-running migration (after rollback, fresh start) re-creates the
backup directory, the postrun-pending sentinel, and the S7 stage
sentinel together. No stale-sentinel risk.

### 7.3 Interaction with rollback

MIGRATION-v9-to-v10.md §12 rollback (per the script's reference at line
447) deletes `.pack-migration-backup/v9.3-to-v10.0/` and reverts the
migration commit. Postrun-pending sentinel goes with the directory.
**Rollback automatically deactivates Procedure 5-S** — exactly the
right semantics: a rolled-back migration has nothing to reconcile.

---

## 8. Cascade — files that change

### 8.1 Pack source files

| # | File | Change |
|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` (after line 1228, before line 1230 `Procedure 6` heading) | Insert new `### Procedure 5-S — Post-migration housekeeping` section. ~25–35 lines including a small task table. Body per §6.2. |
| 2 | `scripts/migrate-v9-to-v10.sh` `stage_s7_report` function (after line 449 `} > "$report"`, before `write_sentinel "S7"`) | Add `touch "$BACKUP_DIR/postrun-pending"`. Add a "Post-migration housekeeping" bullet to the report's "Next steps" list (around line 442 in the heredoc). |
| 3 | `project-template/skills/pm-startup/SKILL.md` (top of file, between current Step 1 and the YAML frontmatter — i.e., add a new "Step 0 — Check for pending one-shot procedures" before "## Step 1 — Sync repo") | New ~10-line block per §5.1. Includes both 5-R (existing latent gap) and 5-S detection. |
| 4 | `supporting-docs/MIGRATION-v9-to-v10.md` Step 4 (line 225 onward) | Add a bullet under "Expected behaviors": *"Procedure 5-S — post-migration housekeeping. Always runs after migration. PM chat scans STATUS.md and trinity files for stale pack-version markers and unfilled placeholders, surfaces findings, and reconciles with your input. Self-cleans on completion."* This is orientation only; the work happens via METHODOLOGY procedure (no instructions duplicated). |

### 8.2 Files NOT changed (and why)

- **CLAUDE.md / AGENTS.md / GEMINI.md (trinity, project-template).** No
  trinity changes. The procedure is invoked from METHODOLOGY (which the
  trinity already references via `docs/pack/METHODOLOGY.md` per V10-F-D
  resolution). No new project rules introduced.
- **Pack-repo CLAUDE.md / AGENTS.md / GEMINI.md.** Not affected. These
  govern pack-repo agent behavior, not project PM chat behavior.
- **`docs/pack/PM-CHAT.md`.** No edit. The new procedure is discovered
  via the SKILL Step 0; PM-CHAT.md does not need to know about specific
  procedures (it points at METHODOLOGY for procedure bodies).
- **`SETUP-NEW.md`.** Procedure 5-S is migration-specific (sentinel set
  by `migrate-v9-to-v10.sh`, not `init-project.sh`). New projects don't
  need it because new projects don't have stale v9 markers and the
  developer fills trinity placeholders via the standard kickoff flow
  (PM-CHAT.md `Variant: kickoff`, METHODOLOGY Procedure 7). No SETUP-NEW
  edit.
- **Pack-repo `README.md`.** No structural change to mention.
- **`.codex/skills/pm-startup/SKILL.md`, `.gemini/skills/pm-startup/SKILL.md`,
  `.claude/skills/pm-startup/SKILL.md`** in the pack repo: these don't
  exist (the pack repo's own `.claude/skills/` is for pack agents — see
  PACK-AGENTS.md line 22 — and pm-startup is not loaded by pack agents).
  Project-side copies are produced by `init-project.sh` from the
  source-of-truth at `project-template/skills/pm-startup/SKILL.md`. Edit
  propagates automatically on next `init-project.sh` run.

### 8.3 Total touch surface

**4 files to edit.** One METHODOLOGY procedure addition; one script edit
in S7; one SKILL Step-0 addition; one user-facing migration-doc bullet.
No trinity edits. No design-document overrides.

---

## 9. Trinity-rule compliance

Per CLAUDE.md trinity rule (lines 58–64): when modifying
`project-template/CLAUDE.md`, make the parallel edit in
`project-template/AGENTS.md` and `project-template/GEMINI.md` in the same
commit. Symmetry is the default; asymmetry requires justification.

**Under this design, none of the three trinity files are modified.** The
new procedure body lives in METHODOLOGY (the trinity already references
it via `docs/pack/METHODOLOGY.md`). The new SKILL Step lives in
`pm-startup/SKILL.md` (a single source-of-truth, distributed by
`init-project.sh`).

**Trinity-rule status: clean. No trinity changes required.**

If implementer encounters any trinity drift during the cascade
(unrelated to this patch), it should be addressed as a separate
trinity-symmetry fix, not as part of F-E/F-F resolution.

---

## 10. Self-check

| Property | Status |
|---|---|
| Follows Procedure 5-R precedent? | **Yes.** Same shape: trigger detection at PM-startup → procedure execution → trigger cleanup as final step. Adjacent procedure number (5-S follows 5-R, both in Part 7's "post-migration" cluster). |
| Procedure body terse (RAG-cost-aware)? | **Yes.** ~25–35 lines including the task table. Body refers out to existing concepts (TRIO, Procedure 7's kickoff Active-skills flow) rather than restating. No prose duplication of pm-chat.md or trinity content. |
| `/pm-startup` SKILL routing scales cleanly? | **Yes for N≤~10.** Linear-with-N if-block addition; explicit binding from trigger to procedure name; no METHODOLOGY-side machine-readable infrastructure to maintain. Generic mechanism deferred until N≈10 forces revisit (§5.3). |
| F-E and F-F robust to project variation? | **Yes.** Tolerant scans with closed-form whitelist; "no markers found" is a clean exit; STATUS.md absence handled; partial pre-filled placeholders handled (§6.2–§6.5). |
| Cleanup path defined? | **Yes.** Sentinel deletion as final procedure step; rollback-compatible (sentinel goes with backup dir); deferred-task case keeps sentinel until full completion (§4.3, §6.5). |
| Centralization preserved? | **Yes.** Procedure body lives in METHODOLOGY (single source). Migration-doc and SKILL contain triggers/orientation pointers only — no duplicated procedure text. |
| Token-cost budget? | **+4 file edits, ~50 net new lines pack-wide.** METHODOLOGY: ~30 lines. migrate-v9-to-v10.sh: ~3 lines. SKILL: ~10 lines. MIGRATION-v9-to-v10.md: ~3 lines. RAG ingest cost: METHODOLOGY +30 lines is dormant when sentinel absent (same dormancy property as Procedure 5-R). |
| Boundary discipline preserved? | **Yes.** Procedure 5-S writes only to STATUS.md and trinity files — already in the trinity write set per CLAUDE.md `## Document locations` and Procedure 6's existing trinity-write pattern. No new write boundaries introduced. PM chat already owns these surfaces. |

---

## 11. Open questions for project lead

**OQ-F-E-F-F-1.** F-F includes the Active-skills line. Procedure 7
(kickoff auto-discovery) already has machinery for filling this line
during initial kickoff. Should Procedure 5-S **invoke** Procedure 7's
kickoff Active-skills sub-flow when it finds the placeholder unfilled,
or should it run its own simpler Q&A (since the project has already
been kicked off and only the line is stale)?

*Recommendation: simpler standalone Q&A in 5-S — "what skills are
active for this project? Read PLATFORM-SKILLS.md to see options. PM
chat proposes the set based on project type; developer approves." This
avoids re-entering full Procedure 7 (which expects shell-capability
declaration, runs auto-discovery, etc.) for a project that's already
past kickoff. Kickoff Procedure 7 is for fresh projects; 5-S is for
post-migration cleanup of a populated project. Different contexts,
different Q&A surfaces. Project lead confirms.*

**OQ-F-E-F-F-2.** Should the F-E task pack-version source be
METHODOLOGY.md's first 5 lines (per pm-startup Step 6 pattern) or some
other authoritative location?

*Recommendation: METHODOLOGY.md first 5 lines, matching pm-startup
Step 6 (line 30 of `project-template/skills/pm-startup/SKILL.md`).
Single source of truth for "what version is the pack at." Project lead
confirms.*

**OQ-F-E-F-F-3.** STATUS.md priority list (`docs/project/STATUS.md`,
`docs/STATUS.md`, `STATUS.md`). Are there other plausible v9.3-era
locations? Does V10-DESIGN canonicalize STATUS.md to one path?

*V10-DESIGN.md and trinity tables (CLAUDE.md line 109 `### Document
locations`) place STATUS.md under `docs/project/`. Recommend the
priority list above; if a project lead knows of v9.3 projects with
STATUS.md elsewhere, add that path to the scan list. Project lead
confirms or supplements.*

**OQ-F-E-F-F-4.** F-E recommends scope "v10.0 patch"; F-F recommends
"v10.1 patch" per V10-PHASE-4-VERIFICATION.md lines 911 and 913. Does
combining them into one procedure mean both ship at v10.0, or should
v10.0 ship F-E only (Task A) with F-F (Task B) added at v10.1?

*Recommendation: ship both at v10.0. The combined procedure is the
elegance-preserving design (§2). Splitting the v10.0/v10.1 patch line
through the middle of one procedure body is less elegant than shipping
the unified procedure once. The verification doc's split severity
reflects defect-discovery context, not implementation cohesion. Project
lead confirms; if v10.0 must omit F-F, the procedure can ship with
Task A only and Task B added at v10.1 with a documented "Task B added
in v10.1" note.*

**OQ-F-E-F-F-5.** Does the pack want to formalize the
"one-shot-procedure trigger" pattern in METHODOLOGY itself (i.e., a
small Part 7 sub-section explaining the sentinel-based trigger pattern,
named so future procedures can reference it)?

*Recommendation: not in this patch. Two procedures (5-R, 5-S) is
enough precedent to recognize the pattern but not enough to require
abstraction. Defer until a third one-shot procedure is proposed; at
that point, factor out the shared shape into a Part 7 sub-section.
Project lead confirms or directs.*

---

## 12. Summary

**Decision:** add `Procedure 5-S — Post-migration housekeeping` to
METHODOLOGY Part 7. Combined F-E + F-F. Triggered by sentinel file
`.pack-migration-backup/v9.3-to-v10.0/postrun-pending` (written by
migrate-v9-to-v10.sh S7). Detected by `/pm-startup` SKILL via a new
"Step 0 — Check for pending one-shot procedures" block (also picks up
the existing 5-R trigger as a side-benefit). Self-cleaned by the
procedure's final step (delete sentinel). Robust to project variation
via tolerant scans and a closed-form placeholder whitelist.

**Why combined:** shared lifecycle (post-migration, one-shot, PM-chat-
resolvable). Single procedure with two task sub-sections is more
elegant than two procedures with parallel scaffolding.

**Why sentinel trigger:** explicit causality, no false positives, no
ambient scanning, symmetric with Procedure 5-R, cheap to implement.

**Why explicit per-procedure SKILL routing:** linear-with-N at small N,
no METHODOLOGY-side machine-readable infrastructure, easy to verify in
review. Revisit if N ever approaches 10.

**Cost:** 4 file edits, ~50 net lines pack-wide. No trinity changes.
No design-document overrides.

**Side effect:** fixes a latent gap in the existing 5-R routing
(currently surfaced only via MIGRATION-v9-to-v10.md prose, not in the
SKILL — Step 0 makes it explicit).

**Trinity-rule:** clean (no trinity changes).

**Open questions:** 5, listed in §11; none block project-lead approval.
