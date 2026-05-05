# ARCHITECTURE-V3.2-DELTA — phase tasks as first-class entities and TD lifecycle promotion

## §0 Status

- Date: 2026-05-04
- Scope: closes a pre-implementation gap identified after V3.1-DELTA was approved. V1 + V2 + V3 + V3.1-DELTA stand otherwise. This delta:
  1. Promotes phase tasks (the numbered items inside `### Tasks` per METHODOLOGY § Part 4 lines 256-264) to first-class tracker entities.
  2. Designs the three TD-NNN promotion paths (TD → phase, TD → phase task, TD → part of task).
  3. Designs cross-entity dependencies between TD-NNN entries and phase work at both the tracker and the flat-file layer.
- Author: pack-architect (focused re-spawn).
- All three concerns share one root: V1 §5 modeled L1 = phase epic, L2 = TD/BD, L3 reserved. Phase tasks have no slot. Once phase tasks become first-class L2/L3 entities, the promotion paths and cross-entity dependencies follow without further new mechanism.
- D-1..D-20 status: D-4-V2, D-16, D-17, D-18 carry forward unchanged. D-1 (provider surface) gains no new operations. D-5, D-6, D-7, D-8 reaffirmed. Two new sibling decisions added (D-21 phase-task entity, D-22 TD promotion paths). One existing decision extended (D-4-V2 admits a third Type option in `work-item.yml`).
- No new OQs introduced. The 3-level hierarchy floor (V1 §5.1, audit §A.9) is preserved.
- Hard constraints honored: bidirectionality contract V1 §6.0; sidecar-only enrichment per V1 §6.6; round-trip byte-equivalent on v10 grammar per V1 §6.7; failure-mode UX consistent with A1 (V3.1-DELTA §3, MERGE-STRATEGY §2.3); general-use prose; trinity rule applied where trinity files are touched; pack ships in flat-file mode at v11.0 (§6.J unchanged).

---

## §1 The root problem in one frame

V1 §5 (lines 849-880) modeled the dependency hierarchy as:

- L1 = phase epic / version epic.
- L2 = TD-NNN / BD-NNN.
- L3 = reserved (rare sub-tasks within a single TD/BD).

V1 §4.3 (and V2 §4.5) treated phase epics as anchor-only: their body holds the IMPLEMENTATION_PLAN.md anchor; the phase's *contents* (Goal, Prerequisite, `### Tasks`, `### Verification`, `### Agent`, `### Risks`) live exclusively as prose inside the .md.

This is fine when the unit of work is the phase. It breaks when:

- The user wants to pause work mid-stream at task N.M with a closeable artifact.
- The user wants to do non-blocking concurrent work in two different phases (the phase epic is the only addressable surface, so closing one task affects the phase-epic state machine).
- The user wants to deprecate or re-scope task N.M with audit history (the only audit is `git log` of the .md edit).
- The user wants to reorder, split, or merge tasks (no entity-level audit; only diff history).
- The user wants per-task assignee, comments, reactions, review (the granularity is currently the phase).
- A TD-NNN entry is actually a phase-shaped item or a task-shaped item, not an atomic L2 entry (Procedure 1 resolution-path logic in METHODOLOGY § Part 7 lines 1057-1064 already names this: addendum task | dedicated cleanup phase | separate pass — the architecture has no L2 representation for "TD that became a phase task" or "TD that became a phase").
- A TD-NNN's Blocker is `phase-N.M` (a task within phase N), not just `phase-N` — V1 §5.4 only models the `phase-N` form.

The root: phase tasks are missing from the entity model. Once they are added, the promotion and cross-dependency designs follow.

---

## §2 Decision D-21 — phase tasks are first-class L3 entities

### §2.1 The decision

A phase task (`#### N.M — <title>` per METHODOLOGY § Part 4 line 257) is a first-class tracker entity with the following identity and shape:

- **Identifier.** `phase-N.M` (lowercase, dash-separated; M is the integer task number from the .md). Stable across renames and reorders. `phase-3.2` survives a title change of `#### 3.2`. Identity is owned by the pack, not the tracker (consistent with V1 §5.4 TD-NNN identity policy).
- **Hierarchy slot.** L3 in V1 §5.1, parented to its phase epic at L1. The L2 slot remains TD/BD-only.
- **Tracker representation.** A GH issue with `type: Task`, parented to the phase epic via sub-issue link when `hierarchy.supported`; `link.kind = "parent"` plus label `parent:phase-N` when not.
- **Title.** `Phase N.M — <task title>`.
- **Body marker trio (D-18 dual carrier).**
  ```
  <!-- pack-id: phase-3.2 -->
  <!-- template_version: v11.0.0/phase-task -->
  <!-- pack-version: v11 -->
  ```
- **Labels.** `phase-task`, `phase-N` (the phase membership), `template:phase-task-v11.0.0`. Status label per §2.5.
- **Body content.** Verbatim copy of the four METHODOLOGY § Part 4 bullets for the task: `Problem / Goal / Success`, `Files created/modified`, `Definition of done`, `Dependencies`. Each in its own `## ` body section so reverse migration parses them by heading.

### §2.2 Why L3, not L2

L2 is reserved for TD/BD entries because TDs and phase tasks have different semantics:

- TD-NNN entries are *deferred* work tracked in BACKLOG; their state machine includes Open/Unblocked/Resolved/Cancelled/Deprecated (METHODOLOGY § Part 7 lines 1003-1013).
- Phase tasks are *planned* work inside an active phase; their state set is the smaller Done / In Progress / Pending / Deferred (INTERNAL-INVENTORY line 472-479 OT shape; this is what STATUS.md `✅` markers communicate today).

Mixing them at L2 would force the state machine to be the union of both, which neither tracker workflow nor reverse migration handles cleanly. Keeping phase tasks at L3 preserves V1 §5.1's L2 contract for backlog items and V1 §5.1's reservation for "rare sub-tasks within a single TD/BD" — phase tasks are exactly the "subordinate work item" L3 was reserved for, just within a phase epic instead of within a single TD.

### §2.3 3-level cap is preserved

L1 phase epic → L2 TD-NNN (when the TD is a phase task; see §3.2) → L3 phase task. The phase task at L3 is the deepest the design goes. This sits at the cross-tracker safe floor (V1 §6.1, audit §A.9). Jira free's 3-level cap, Shortcut's 2-level cap (where phase task collapses to a checklist per §2.7), and OpenProject's configurable hierarchy all accommodate this without emulation.

For backends with `hierarchy.supported = false` or `depth_ceiling < 3` (Bugzilla, Trello cards-only), §5.2 capability-flag handling already specifies `link.kind = "parent"` + label emulation; phase tasks reuse the same emulation path with `parent:phase-N` label.

### §2.4 Form treatment composes with D-4-V2

Phase tasks are normally created by PM Chat at migration time or when a planner adds a task to a phase, via `provider.create()` with a fixed payload — exactly the pattern V2 §4.5 already uses for phase epics. **No new form file is added.**

`work-item.yml` (D-4-V2) gains one new option in the `wi-type` dropdown: `phase-task-skeleton` (parallel to the existing `phase-epic-skeleton`). It exists as a hand-edit fallback for the rare case PM Chat needs to recreate a deleted phase task outside the migration script. Day-to-day, phase tasks are created programmatically.

D-4-V2 is **extended, not superseded.** The form-family pattern (D-16) is preserved: new entry type adds a dropdown option, not a file. Risk R11 (V2 §17 dropdown noisiness) is unaffected — `wi-type` now has 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton), well below the soft cap of ~6 from R11.

### §2.5 State / status mapping

The flat-file STATUS.md / IMPLEMENTATION_PLAN.md status taxonomy for phase tasks (per OT shape, INTERNAL-INVENTORY lines 472-479; codified by the pack only as `✅` per METHODOLOGY § Part 7 line 1027) maps to GH state + label as follows:

| Flat-file token | Tracker state | Status label | Closure reason |
|---|---|---|---|
| `Done` / `✅` | closed | `status:done` | `state_reason: completed` |
| `In Progress` / `🚧` | open | `status:in-progress` | n/a |
| `Pending` / (default) / no marker | open | `status:pending` | n/a |
| `Deferred` / `➡` | closed | `status:deferred` | `state_reason: not_planned` |
| `Merged into Phase N` / `➡ Merged` | closed | `status:merged-into:phase-N` | `state_reason: not_planned` |
| `Superseded by Phase N` / `➡ Superseded` | closed | `status:superseded-by:phase-N` | `state_reason: not_planned` |

The `merged-into` and `superseded-by` labels carry the redirect target as a label-suffix, the same shape `template:<entry-type>-<version>` already uses (D-18). Reverse migration (§4.2) reconstructs the prose marker from the label.

This taxonomy is **additive to V1's existing label scheme** — it does not collide with the BACKLOG-side labels `status:open / unblocked / resolved / cancelled / deprecated` (which apply only to TD/BD work items, never to phase tasks; the chat distinguishes by the `phase-task` label vs `td-entry` / `bd-entry` label). Capability-flag implication: backends without status-label vocabulary (Trello-as-lists) declare `status_taxonomy.custom = true` and emulate via list moves; this is already the V1 §6.3 design for status portability.

### §2.6 Identifier scheme survives reorder, split, merge

Phase numbers are append-only (METHODOLOGY § Part 4 line 277-281). Task numbers within a phase are NOT append-only by stated rule, but in practice they are stable across the phase's life — IMPLEMENTATION_PLAN.md is hand-maintained and the planner does not renumber tasks once written. The pack convention this delta adopts:

- **Reorder.** The numeric prefix `N.M` does not change; only the textual order in IMPLEMENTATION_PLAN.md changes. The tracker entity keeps its `pack-id: phase-3.2`. Reverse migration emits tasks in the order specified by a new sidecar field `task_order: [3.1, 3.3, 3.2]` per phase (round-trip-safe; §4.2). If the user manually edits the .md to reorder, the sidecar is updated by `pack tracker reset --rebuild-from-flat` (the existing reset verb from BD-103).
- **Split.** Task `phase-3.2` splits into `phase-3.2` and `phase-3.4` (next available integer suffix). The original entity keeps its `pack-id`; the new entity gets a fresh `pack-id: phase-3.4` and label `parent:phase-3.2:split`. Audit trail on tracker side is the issue create event + parent label.
- **Merge.** Task `phase-3.3` merges into `phase-3.2`. `phase-3.3` closes with `state_reason: not_planned` and label `merged-into:phase-3.2`; `phase-3.2` body gets an appended note. Mirrors the §2.5 `merged-into` status semantics.
- **Deprecate.** Task `phase-3.2` deprecates: closes with `state_reason: not_planned` and label `status:deferred` plus `disposition:deprecated`. Audit on tracker = issue close event + comment with rationale; on flat = a `> **Execution note**: deprecated YYYY-MM-DD — <reason>` line appended to the task in the .md (METHODOLOGY § Part 4 line 254 already authorizes execution notes).

### §2.7 Capability-flag handling for low-capability backends

- `hierarchy.supported = false` (Bugzilla): phase tasks emulated via label-only — `parent:phase-N` plus `phase-task` plus a body section pointing at the parent phase epic by URL. Reverse migration recovers the parent from the label. Round-trip works (§4.4).
- `depth_ceiling < 3` (none in §6.4 reference set; reserved): the chat warns at opt-in and offers `--flatten-phase-tasks` flag that demotes tasks to checklist items inside the phase epic body. Round-trip in flatten mode preserves `Definition of done` per task as a checklist line; sidecar captures everything else (Files created/modified, Dependencies, Problem/Goal/Success). This is the Shortcut / Trello path.
- `dropdown.multiple` not supported: not relevant — phase tasks use single labels.

### §2.8 Volume considerations

OT current state (INTERNAL-INVENTORY): 60 phases (0..58 with gaps). At ~3-6 tasks per phase typical, a fully-migrated OT-shaped project produces 200-400 phase task issues at L3 plus 60 phase epics at L1 plus ~340 TD entries at L2. This sits below GH's 100-children-per-parent cap (max ~6-8 tasks per phase) and well below 1000-search-cap (V1 §6.1; queries are filtered by `label:phase-N` and never bulk-fetched per §7.1). The forward migration script's checkpoint cadence (V1 §6.4 every 25 issues) accommodates the additional volume.

---

## §3 Decision D-22 — TD-NNN promotion paths

### §3.1 The three paths from the problem statement

The METHODOLOGY § Part 7 Procedure 1 resolution-path decision logic (lines 1057-1064) already names three lifecycle outcomes for an Unblocked TD-NNN:

- **Addendum task within current phase** (TD becomes a numbered task inside an existing `### Tasks` subsection).
- **Dedicated cleanup phase** (TD becomes its own `## Phase N`).
- **Separate pass of the current phase** (TD becomes a part of an existing task or a sibling subtask).

This delta gives each path an explicit forward / reverse / round-trip representation.

### §3.2 Path 1 — TD becomes a phase

**Trigger.** PM Chat user approval per Procedure 1 step 3 with disposition "dedicated cleanup phase."

**Forward (flat-file → tracker).**
1. PM Chat appends a new `## Phase N` section to IMPLEMENTATION_PLAN.md (next available number per Part 4 line 279).
2. PM Chat creates a phase epic via `provider.create()` (V2 §4.5) with `pack-id: phase-N`, body containing the IMPLEMENTATION_PLAN anchor, label `phase-epic` and label `derived-from:TD-031`.
3. PM Chat re-keys the original TD-NNN: status flips to `Resolved`, Resolution field set to `[YYYY-MM-DD, completed, promoted to phase-N]`. The TD-NNN issue stays open as a closed historical record (state = closed, state_reason = completed, label `status:resolved`, label `promoted-to:phase-N`).
4. PM Chat creates phase tasks for the new phase per §2 if the promotion includes pre-planned tasks.

**Reverse (tracker → flat-file).**
1. Reverse migration reads phase epic with `derived-from:TD-031` label and reconstructs the `## Phase N` section in IMPLEMENTATION_PLAN.md.
2. Reverse migration reads the closed TD-NNN issue with `promoted-to:phase-N` label and reconstructs the BACKLOG entry with `Resolution: [date, completed, promoted to phase-N]`.
3. The link is preserved in both directions: the BACKLOG entry's Resolution field names the phase; the phase epic's body has a "Promoted from TD-031" note (and the label is the queryable face).

**Round-trip safety.** Forward → reverse → forward is a no-op: the BACKLOG-side Resolution text and the phase epic's `derived-from:` label are the two carriers; reverse reads the label, re-forward writes the same label. The phase task list (if any) round-trips per §2.

### §3.3 Path 2 — TD becomes a phase task

**Trigger.** PM Chat user approval per Procedure 1 step 3 with disposition "addendum task within current phase."

**Forward.**
1. PM Chat picks the next available `M` for phase N (typically max+1 of the existing tasks within the phase).
2. PM Chat appends a `#### N.M — <title>` section to phase N's `### Tasks` block in IMPLEMENTATION_PLAN.md, populated from the TD-NNN's Description / Context.
3. PM Chat creates a phase task issue via `provider.create()` (§2) with `pack-id: phase-N.M`, label `phase-task`, label `phase-N`, label `derived-from:TD-031`, body sections from the TD content.
4. PM Chat re-keys the TD-NNN: status flips to `Resolved` with Resolution `[YYYY-MM-DD, completed, promoted to phase-N.M]`, label `promoted-to:phase-N.M`.

**Reverse.**
1. Reverse reads phase task with `derived-from:TD-031` label and emits the `#### N.M — <title>` block in IMPLEMENTATION_PLAN.md.
2. Reverse reads the closed TD-NNN issue and emits BACKLOG entry with Resolution naming `phase-N.M`.

**Round-trip safety.** The `derived-from:` and `promoted-to:` label pair is the canonical carrier; the prose "promoted to phase-N.M" in the Resolution field is the human-readable face. Forward → reverse → forward replays the same labels; byte-equivalent on tracker side.

### §3.4 Path 3 — TD becomes part of a task

**Trigger.** PM Chat user approval per Procedure 1 step 3 with disposition "separate pass of the current phase" or with the user-explicit "fold this TD into existing task N.M" decision.

This is the path with the least fidelity in v10 grammar — a TD becoming a sub-element of an existing task does not have a named entity slot (there is no L4). The design treats it as a body-edit of the existing phase task plus a TD resolution:

**Forward.**
1. PM Chat reads existing phase task `phase-N.M`. Appends to its `Definition of done:` body section a new bullet derived from the TD: e.g., `- (from TD-031) <task description>`.
2. PM Chat updates the phase task issue body (the chat is the writer per V1 §7).
3. PM Chat re-keys the TD-NNN: status flips to `Resolved` with Resolution `[YYYY-MM-DD, completed, folded into phase-N.M definition-of-done]`, label `folded-into:phase-N.M` (distinct from `promoted-to:` so reverse can tell the difference).

**Reverse.**
1. Reverse reads the phase task body, parses `Definition of done` bullets, recognizes lines beginning with `- (from TD-NNN)` as fold markers (an inline grammar that survives the v10 file shape because IMPLEMENTATION_PLAN.md is a flat file and the grammar is just markdown).
2. Reverse emits BACKLOG entry for TD-031 with Resolution naming the fold target.

**Round-trip safety.** The `(from TD-NNN)` inline marker plus the `folded-into:` label is the dual carrier (parallel to D-18 pattern). Reverse migration's IMPLEMENTATION_PLAN emit (V1 §6.5 step 5) preserves the inline markers verbatim. Re-forward reads the .md, sees the `(from TD-NNN)` bullets, recognizes them as fold records, re-issues the labels.

If a future TD-resolution editor strips the `(from TD-NNN)` prefix from the bullet, the label still tells reverse what to emit; the chat surfaces a discrepancy via `pack tracker doctor` and offers reconciliation.

### §3.5 The promotion-path label family (additive, no new mechanism)

Three new label kinds, all reserved-string family per V1 §5.3 capability `link.kind` open-string contract:

| Label | Where it lives | What it means |
|---|---|---|
| `derived-from:TD-NNN` | New phase epic / phase task | Reverse-direction pointer to the source TD |
| `promoted-to:phase-N` or `promoted-to:phase-N.M` | Closed TD-NNN issue | Forward-direction pointer; TD became a phase or task |
| `folded-into:phase-N.M` | Closed TD-NNN issue | TD merged into a task's definition-of-done |

These labels join the existing `template:<entry-type>-vX.Y.Z` (D-18) and `parent:<id>` (V1 §5.3 emulation) families. Repo-level label budget: 3 new kinds × ~50 active TDs × 60 phases × ~6 tasks/phase = bounded; the label-set growth is per-issue, not per-repo (V2 R12 mitigation already applies via `pack tracker update-templates` GC sub-step).

**Capability-flag handling.** Backends without first-class labels (Bugzilla keywords + flags) emulate via the keyword field; backends with closed label sets (Jira workflow-only) emulate via custom field per §6.4. The `link.kind = "promoted-to"` open-string is the cross-tracker carrier.

---

## §4 Forward and reverse migration extensions

### §4.1 Forward parser for IMPLEMENTATION_PLAN.md `### Tasks`

V1 §6.2 step 5 already creates phase epics by walking `## Phase N — <title>` headings. This delta extends step 5 with a sub-step:

```
5. For each phase in IMPLEMENTATION_PLAN.md:
   a. Phase epic created (V2 §4.5 payload).
   b. Parse the phase's `### Tasks` subsection:
      - Find each `#### N.M — <title>` heading (regex
        ^####\s+(\d+)\.(\d+)\s+—\s+(.+)$).
      - For each task, capture:
        - The four bullet sections (Problem/Goal/Success;
          Files created/modified; Definition of done;
          Dependencies). Bullet starts at `- **<name>**:` or
          `- **<name>** —`. Trailing content runs until the
          next bullet or the next `#### ` heading.
        - Any leading attributes (none in current pack
          format; reserved for future use).
      - Compute pack-id = `phase-<N>.<M>`.
      - Create phase task issue (§2 payload) parented to phase
        epic.
   c. If `### Tasks` is missing:
      - Phase epic still created.
      - Forward emits a warning (via tracker-errors.sh per BD-070):
        "Phase N has no `### Tasks` subsection; no phase tasks
        created. Run `pack tracker doctor` if this is unexpected."
      - Migration does NOT fail. (METHODOLOGY § Part 4 permits
        the section but does not enforce its presence; the
        chat must tolerate sparse phases.)
   d. If `#### N.M` heading is malformed (missing em-dash,
      missing title, non-integer M):
      - Forward fails for this phase with diagnostic naming
        the line number and the expected regex.
      - Recovery: user fixes the .md; re-runs forward (idempotent
        per V1 §6.4).
   e. Order preservation: capture the order of `#### N.M`
      headings as they appear and write to mapping file:
      .pack-tracker/id-map.json[phase-N].task_order =
      ["3.1", "3.3", "3.2"].  (See §2.6.)
```

The parser is **deterministic, regex-based, and operates on the plain markdown — no AST**. It is robust to:

- Whitespace variation (one or more spaces around the em-dash).
- Trailing whitespace per line.
- Empty `### Tasks` subsection (phase epic created; no tasks).
- Tasks appearing before any `### Tasks` heading (treated as malformed; warning).
- Tasks under a non-`### Tasks` subsection (e.g., `### Verification` with embedded task-shaped headings) — only `#### ` headings *under* an `### Tasks` H3 are recognized as tasks. The parser tracks current H3 state.

The full grammar is documented in MIGRATION-v10-to-v11.md (BD-084 extension; see §6).

### §4.2 Reverse emit for `### Tasks`

V1 §6.5 step 5 emits phase headings into IMPLEMENTATION_PLAN.md. This delta extends step 5:

```
5. For each phase epic, emit `## Phase N — <title>` heading
   into IMPLEMENTATION_PLAN.md (only if it does not exist):
   a. Emit Goal, Prerequisite from phase epic body.
   b. Emit `### Tasks` heading.
   c. For each phase task with parent = this phase epic:
      - Read task_order from id-map.json[phase-N].task_order;
        emit tasks in that order.
      - For each task, emit:
        #### N.M — <title>
        - **Problem / Goal / Success**: <body section content>
        - **Files created/modified**: <body section content>
        - **Definition of done**: <body section content>
        - **Dependencies**: <body section content>
   d. Emit `### Verification`, `### Agent`, `### Risks` from
      phase epic body sidecar (these are phase-level, not
      task-level; they live in the phase epic body).
   e. Whitespace: one blank line between tasks; one blank line
      between subsections; trailing newline at file end. Round-
      trip whitespace-tolerant per V1 §6.7.
```

Round-trip guarantee per V1 §6.7: forward → reverse → diff against original IMPLEMENTATION_PLAN.md is empty (whitespace-tolerant). Round-trip test fixture (BD-068 extension) includes one phase with three tasks in non-sequential order to exercise `task_order` preservation.

### §4.3 Sidecar additions for phase tasks

Per V1 §6.6.1 (V3.1-DELTA §3 / A2), the sidecar captures tracker-only data. Phase tasks add the following sidecar entries when v10 grammar can't represent something:

- `task_order` per phase (as above; §2.6, §4.2).
- Per-task tracker-only metadata: assignee, comments, reactions, review affordances. These have no v10 grammar slot — IMPLEMENTATION_PLAN.md tasks have no Resolution / Audit fields.
- Task state changes that don't round-trip via the body (e.g., reopened-after-done): captured as audit log entries in the sidecar.

The sidecar schema gains a new top-level `phase_tasks` block:

```
phase_tasks:
  phase-3:
    task_order: [3.1, 3.3, 3.2]
    tasks:
      phase-3.2:
        assignee: <if any>
        comments: [<list of {author, date, body}>]
        reactions: {<map>}
        audit_log: [<state changes>]
        template_version: v11.0.0/phase-task
        extra_fields: {<v11.x-only fields>}
```

This composes with V1 §6.6.1 / A2 — the same `template_version` and `extra_fields` mechanism applies to phase tasks. No new sidecar mechanism is invented.

### §4.4 Round-trip test extension

V1 §6.7 / BD-068's `roundtrip-test` fixture is extended with:

- One phase with `### Tasks` containing three tasks `#### 3.1`, `#### 3.2`, `#### 3.3`, in the file order 3.2 / 3.1 / 3.3 (exercises `task_order`).
- One phase with no `### Tasks` subsection (sparse phase).
- One phase with a missing-em-dash heading (negative case; expects a recovered-with-warning result, not crash).
- One TD-NNN entry in BACKLOG.md with `(from TD-031)` fold marker in a phase task's Definition-of-done bullet (exercises Path 3 round-trip).
- One `derived-from:TD-NNN` phase epic (exercises Path 1 round-trip).
- One `derived-from:TD-NNN` phase task (exercises Path 2 round-trip).

Forward → reverse → forward must produce zero diff on the tracker side and whitespace-tolerant zero diff on the flat-file side. CI gate addition; new BD or extension of BD-068 (see §6).

---

## §5 Cross-entity dependencies between TDs and phase work

### §5.1 The two cases from the problem statement

- **Common case — TD blocked by phase work.** A TD-NNN whose Blockers list names `phase-N` (entire phase) or `phase-N.M` (specific task). v10 syntax: `Blockers: phase-3` or `Blockers: phase-3.2`. Read by the chat at gate-check time (Procedure 1 step 2).
- **Rare case — TD blocks phase task.** A phase task whose Dependencies bullet names `TD-NNN`. v10 syntax: `- **Dependencies**: TD-031`. The dependency is *into* the task from the TD.

### §5.2 Tracker-level representation

Both cases use V1 §5.3 reserved `link.kind = "blocks"` / `"blocked-by"` (the open-string family). Direction explicit:

| Case | Tracker operation | Direction |
|---|---|---|
| TD-031 blocked by phase-3 (entire phase) | `provider.link(source=TD-031-issue, target=phase-3-epic, kind="blocked-by")` | TD → phase epic |
| TD-031 blocked by phase-3.2 (one task) | `provider.link(source=TD-031-issue, target=phase-3.2-task, kind="blocked-by")` | TD → phase task |
| Phase task 3.2 blocked by TD-031 (rare) | `provider.link(source=phase-3.2-task, target=TD-031-issue, kind="blocked-by")` | phase task → TD |

The provider's existing `link()` operation (V1 §2.1) supports cross-type sources and targets. No new operation. No capability flag changes. Reserved values per V1 §5.3 hold.

For backends with `dependency.cap < 50` per relationship (none in §6.4 reference set; reserved): the chat warns and offers `--flatten-deps` to collapse the link to a body comment. Sidecar captures the original link; reverse re-creates it.

### §5.3 Flat-file syntax (v10 grammar preserved + extended)

**v10 today (METHODOLOGY § Part 7 line 990-993):**
```
Blockers:
  - phase-3
  - TD-029
```

**v11 extends the Blockers grammar to admit `phase-N.M`:**
```
Blockers:
  - phase-3.2          ← NEW: blocked by a specific task
  - TD-029
```

The grammar extension is **additive**: every legal v10 Blocker is still legal in v11. The parser change in `pm-chat.md backlog-status-update` variant: regex `^phase-\d+(\.\d+)?$` instead of `^phase-\d+$`. Reverse migration (§4.2) emits the `phase-N.M` form when the tracker shows a TD blocked by a phase task. METHODOLOGY § Part 7 lines 990-993 are updated to allow the extended form (see §6 blast radius).

**Phase task Dependencies bullet** (METHODOLOGY § Part 4 line 263) admits TD-NNN today (the bullet just says "other tasks within this phase" but the format is free-form prose). v11 codifies: bullet contents may be `phase-N.M`, `TD-NNN`, or `BD-NNN` references. Parser change in §4.1 step (b) reads these and emits `provider.link(...)` calls in V1 §6.2 step 7.

### §5.4 Procedure 1 gate check extension

METHODOLOGY § Part 7 Procedure 1 step 2 (lines 1025-1029) currently distinguishes:
- Phase N blocker: has phase been committed and marked ✅ in STATUS.md?
- TD-NNN blocker: does that item have Status: Resolved?
- External condition: judgment call.

v11 extends this list with a new branch:
- **Phase N.M blocker**: does the phase task have Status: Done (in tracker mode, label `status:done`; in flat-file mode, `✅` marker on the task's `#### N.M` line)?

The gate-check logic is reverse-migration-safe: the chat-resolved `phase-N.M` blocker reads the same data via the trinity Document-locations resolver (D-6); flat-file mode reads the `#### N.M` heading and looks for a status marker; tracker mode reads the phase task issue label. The chat does not branch on mode — the resolver picks (V1 §8.5).

### §5.5 Cycle detection

The cross-entity dependency graph admits new cycle shapes:

- TD-031 blocked by phase-3.2; phase-3.2 has Dependency on TD-031 (rare, but possible by user error).

The provider's `link()` does not detect cycles; PM Chat does at link time. The check is: traverse `blocked-by` from the new edge's source for K hops (K = configurable; default 10 per V1 §6.1 GraphQL one-shot capacity); if the target appears in the closure, refuse the link with diagnostic. Implemented in PM Chat orchestration (BD spec; see §6), not in the provider.

### §5.6 A1 failure-mode UX

If a cross-entity link fails (e.g., target issue archived; rate limit; auth):
- Surface typed error per V1 §9 (D-7); name the verb (`pack tracker doctor`) per Layer 2 (V3 §27.1).
- Do NOT silently retry; do NOT fallback to flat-file (the link is the data the user requested).
- The chat preserves the in-memory edit and offers to retry on auth refresh.

This composes with A1 (V3.1-DELTA §3 / MERGE-STRATEGY §2.3) — the same failure-mode shape applies to dependency operations as to entry-content operations.

---

## §6 Blast radius for the planner pass

### §6.1 Architecture sections amended

| Doc | Section | Change shape |
|---|---|---|
| V1 | §4.3 (phase epic body) | Reaffirmed; adds phase task children at L3 (delta §2) |
| V1 | §5.1 (3-level hierarchy) | Reaffirmed; L3 reservation now realized for phase tasks |
| V1 | §5.3 (reserved link.kind values) | Adds `derived-from`, `promoted-to`, `folded-into` to the open-string family |
| V1 | §5.4 (TD ↔ phase resolution) | Extended with phase-N.M form; cross-references §5 of this delta |
| V1 | §6.2 (forward algorithm) | Step 5 extended (parse `### Tasks`); step 6 extended (cross-entity links); step 7 extended (TD blockers may name phase-N.M) |
| V1 | §6.5 (reverse algorithm) | Step 5 extended (emit `### Tasks` with task_order) |
| V1 | §6.6.1 (sidecar) | Adds `phase_tasks` top-level block |
| V1 | §6.7 (round-trip) | Test fixture additions per delta §4.4 |
| V2 | §4.2 (`work-item.yml` Type dropdown) | Adds `phase-task-skeleton` option (4 options total) |
| V2 | §4.5 (phase epic system issue) | Reaffirmed; sibling §4.5.1 added for phase tasks |
| V2 | §16 decisions table | Adds D-21, D-22 rows (architect's recommended IDs; planner finalizes numbering if collisions) |
| V2 | §17 risks | Adds R18 (phase task numbering volatility), R19 (cross-entity link cycles) |
| V3 | §I.1 / §I.2 (artifact list) | No new files; modifies forward/reverse scripts and roundtrip test fixture |
| V3.1-DELTA | (no change) | The three V3.1 picks (M2 / L1 / A2) are independent of phase-task work |

### §6.2 BDs requiring extension (from existing IMPLEMENTATION-PLAN + Addenda 1, 2, 3)

| BD | Current scope | Extension needed |
|---|---|---|
| BD-060 | TrackerProvider abstraction + GH backend | No change — existing `link()` and `sub_issue_create()` cover the new entity types |
| BD-063 | Issue forms `work-item.yml` + `inbound.yml` | Extend `wi-type` dropdown with `phase-task-skeleton` option; emit `template:phase-task-v11.0.0` label; document in form help text |
| BD-064 | Template-archive directory | Add `bd-v11.0/phase-task-v11.0.0/SCHEMA.md` schema definition |
| BD-065 | Forward migration | Extend step 5 per §4.1 of this delta; extend step 6 with cross-entity links; extend step 7 to admit `phase-N.M` blockers |
| BD-067 | Reverse migration | Extend step 5 per §4.2; emit Blockers with `phase-N.M` form when applicable |
| BD-068 | Round-trip test fixture | Extend with phase task fixtures per §4.4 |
| BD-069 | template_version dual carrier | Add phase-task entry-type to the carrier matrix |
| BD-072 | recommendation.sh signal computation | One signal addition: phase task count crossing a threshold (parallel to entry count); not load-bearing for v11.0 — could defer to v11.1 |
| BD-082 | validate-pack Checks 21-24 | Add Check 25: phase-task entity coverage (every `#### N.M` in IMPLEMENTATION_PLAN.md has a corresponding tracker issue when in tracker mode); Check 26: cross-entity link consistency |
| BD-084 | MIGRATION-v10-to-v11.md | Document phase task model + promotion paths + Blockers grammar extension |
| BD-094 | MERGE-STRATEGY.md | Add row for IMPLEMENTATION_PLAN.md (preservation strategy: prose-aware merge; phase tasks treated as additive blocks); A1 UX applies to phase task body merge conflicts |
| BD-096 | Synthetic-fixture set | Add fixtures with multi-task phases, sparse phases, malformed task headings, promotion-path TDs |
| BD-098 | OPTIONAL-FEATURES.md | Document phase task tracker workflow |
| BD-105 | STATUS.md phase-row dual-link | The phase-row link in tracker mode now optionally includes a child link to the phase tasks issue list (e.g., the GH "sub-issues" view); architect's hint to the planner — could defer to v11.1 |

### §6.3 New sibling BDs the planner should create

The architect's hint, not a prescription. Suggested ~3 new BDs (numbering continues from BD-105 → BD-106..108):

1. **BD-106 — Phase task entity model + identifier scheme + migration parser/emitter.** Lands the parser (§4.1), emitter (§4.2), label family (§3.5), id-map.json `task_order` field. Blockers: BD-063, BD-064, BD-065, BD-067. Definition of Done: roundtrip test fixture from §4.4 passes; deterministic parsing of `### Tasks` per the grammar.

2. **BD-107 — TD-NNN promotion-path tooling.** PM Chat orchestration logic for the three paths (§3.2-§3.4): the verb `pack td promote --to=phase-N` / `--to=phase-N.M` / `--fold-into=phase-N.M`. Updates BACKLOG entry; creates/edits tracker entity; writes labels. Blockers: BD-106. The verb composes with `pack help` (D-20) and the static greeting (V3 §27.1).

3. **BD-108 — Cross-entity dependency link orchestration + cycle check.** PM Chat creates `blocked-by` / `blocks` links across (TD ↔ phase epic) and (TD ↔ phase task) boundaries; cycle check at link time per §5.5; gate-check extension per §5.4. Blockers: BD-106. Updates METHODOLOGY § Part 7 Procedure 1 step 2; updates pm-chat.md backlog-status-update variant.

The planner may merge / split / re-sequence; this is decomposition guidance.

### §6.4 validate-pack.py checks added

- **Check 25** — when in tracker mode, every `#### N.M` heading in IMPLEMENTATION_PLAN.md has a corresponding tracker issue with `pack-id: phase-N.M`.
- **Check 26** — every TD-NNN body's Blockers list resolves: `phase-N` resolves to a phase epic; `phase-N.M` resolves to a phase task; `TD-NNN` resolves to another work-item issue.
- **Check 27** — promotion-path label consistency: every `derived-from:TD-NNN` label has a corresponding closed TD-NNN issue with `promoted-to:` or `folded-into:` label.

These are tracker-mode-only checks. In flat-file mode they are no-ops (no tracker to check against).

### §6.5 Documentation updates

- METHODOLOGY § Part 4 line 257-264: extend task format spec with the `(from TD-NNN)` fold marker (§3.4) — make it explicit that fold markers are recognized.
- METHODOLOGY § Part 7 lines 990-993: extend Blockers grammar to admit `phase-N.M`.
- METHODOLOGY § Part 7 lines 1025-1029: extend Procedure 1 step 2 with the `phase-N.M` blocker branch.
- METHODOLOGY § Part 7 lines 1057-1064: extend Procedure 1 resolution-path decision logic with the explicit promotion-path verb name (`pack td promote --to=...`).
- MERGE-STRATEGY.md (BD-094): add IMPLEMENTATION_PLAN.md row.
- MIGRATION-v10-to-v11.md (BD-084): document phase task model + promotion + Blockers extension.
- HELP-FRAGMENT.md (client surface): add `pack td promote` verb to the verb manifest.
- HELP-FRAGMENT-PACK.md: not changed (BD entries don't promote to phases the same way — pack v11+ may revisit).
- pm-chat.md backlog-status-update variant: extend Blockers parser regex.
- pm-startup skill Step 2: phase task discovery now goes through resolver (already trinity-resolved per V1 §8.5; no prompt-text change beyond §1.5).

### §6.6 Trinity rule applicability

This delta touches METHODOLOGY (single-file, supporting-docs/) and PM-CHAT.md / PACK-CHAT.md. The trinity files (CLAUDE.md / AGENTS.md / GEMINI.md at pack root and project-template) are NOT touched directly by this delta — phase task vocabulary is a pack-runtime concept, not a per-CLI concern. The pack-help skill and pack-startup/pm-startup skills carry forward unchanged from V3 / V3.1-DELTA.

If the planner determines that the trinity files need a one-line note about phase task verbs (parallel to the V3 one-line "Pack commands" reference per D-20), it applies in TRIO across all three trinity files in one commit. Otherwise the trinity rule does not engage for this delta.

---

## §7 Cross-impact check

- **D-1..D-20 reopened?** No.
  - D-4-V2 extended (one new option in `wi-type` dropdown) but not superseded; the form-family contract holds.
  - D-16 (multi-template strategy) reaffirmed; new entry type adds a dropdown option, not a file.
  - D-17 (structure-vs-free-text) reaffirmed; phase task body uses textareas for the four bullet sections.
  - D-18 (template_version dual carrier) reaffirmed; phase task entries get `template:phase-task-v11.0.0` label and matching HTML comment.
  - D-19, D-20 reaffirmed (recommendation system / help system unchanged).
- **3-level hierarchy cap respected?** Yes. L1 = phase epic; L2 = TD/BD; L3 = phase task. Capability flags handle backends with shallower depth via emulation per V1 §5.2.
- **Bidirectionality contract (V1 §6.0) honored?** Yes. Every new entity type has full content fidelity in both directions. v10 grammar gains one extension (`phase-N.M` in Blockers; `(from TD-NNN)` fold markers). Tracker-only enrichment (assignee, comments, reactions, audit log on phase tasks) routed to sidecar per V1 §6.6 / §6.6.1.
- **Trinity rule respected?** Not engaged by default — this delta does not touch trinity files. If the planner adds a one-line trinity note for `pack td promote`, the rule applies.
- **Cross-CLI parity floor (V1 §6.2) unaffected?** Yes. All new behavior is at the chat orchestration layer (PM Chat) and at the migration-script layer (LCD bash), both of which are CLI-agnostic by construction.
- **A1 failure-mode UX (V3.1-DELTA §3 + MERGE-STRATEGY §2.3) honored?** Yes. Cross-entity link failures use the typed-error mechanism per V1 §9 / D-7; the same A1 escape-hatch shape applies.
- **No new OQs introduced.** All design choices are forced by the problem statement plus existing decisions; no new questions deferred.

---

## §8 Recommendation summary

Two new sibling decisions resolve the gap:

- **D-21** — Phase tasks are first-class L3 tracker entities. Identifier `phase-N.M`. Created programmatically by PM Chat. Body holds the four METHODOLOGY § Part 4 bullet sections. Status taxonomy maps Done / In-Progress / Pending / Deferred / Merged-into / Superseded-by to GH state + status labels. `work-item.yml` gains a `phase-task-skeleton` Type option for hand-edit fallback. Capability-flag handling preserved for low-capability backends (Bugzilla, Trello, Shortcut) via existing emulation paths.

- **D-22** — TD-NNN entries support three explicit promotion paths: TD → phase (Path 1; `derived-from:` / `promoted-to:` label pair); TD → phase task (Path 2; same label pair); TD → part of task (Path 3; `(from TD-NNN)` inline body marker plus `folded-into:` label). All three round-trip through forward / reverse migration with byte-equivalent v10 grammar.

Cross-entity dependencies (TD ↔ phase epic, TD ↔ phase task) use V1 §5.3's existing `link.kind` open-string family with no new provider operations. Flat-file Blockers grammar gains one additive form (`phase-N.M`). Procedure 1 gate-check (METHODOLOGY § Part 7) extends with the `phase-N.M` blocker branch.

Blast radius: ~10 existing BDs extended (mostly BD-063, BD-064, BD-065, BD-067, BD-068, BD-069, BD-082, BD-084, BD-094, BD-096); ~3 new sibling BDs suggested (BD-106 entity model + parser/emitter; BD-107 promotion tooling; BD-108 cross-entity link orchestration). validate-pack adds Checks 25/26/27 (tracker-mode-only). MIGRATION-v10-to-v11.md (BD-084) and MERGE-STRATEGY.md (BD-094) get prose extensions per §6.5. Trinity rule not engaged unless the planner adds a `pack td promote` verb reference to the trinity (optional).

The delta is purely additive to V1 / V2 / V3 / V3.1-DELTA; no decision is superseded; the bidirectionality and 3-level-cap invariants hold; the form-family pattern (D-16) and dual-carrier pattern (D-18) absorb the new entity types without revision.
