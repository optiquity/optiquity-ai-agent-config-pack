# ARCHITECTURE-V3.3-DELTA — phase tasks at L2, two-path TD promotion, cross-entity dependencies, two new auditor agents

## §0 Status

- Date: 2026-05-04.
- Author: pack-architect (refocused re-spawn).
- Scope: supersedes ARCHITECTURE-V3.2-DELTA.md in full. V3.2 is a historical proposal; it has not been integrated. V1 + V2 + V3 + V3.1-DELTA stand otherwise. The base IMPLEMENTATION-PLAN.md and Addenda 1, 2, 3 are approved and unchanged at the BD-content level; this delta enumerates extensions (§9 blast radius) the planner pass must absorb.
- This delta resolves five problem areas surfaced after V3.2 was reviewed:
  1. Phase tasks as first-class entities with placement matching the maintainer's mental model (L2, parented to phase epic at L1).
  2. Two TD-NNN promotion paths (Path 1 → new phase; Path 2 → new phase task) plus the small-no-blocker TD closure shape.
  3. Cross-entity dependencies between TDs and phase work, uniformly modeled at tracker level and flat-file level.
  4. A project-side issue-tracking auditor sub-agent (under the existing project-template auditor fan-out) covering BACKLOG / IMPLEMENTATION-PLAN / tracker entry health.
  5. A pack-side `pack-auditor` agent covering pack BACKLOG dependency-graph and entry health, distinct from `pack-reviewer`.
- D-1..D-20 status: D-1, D-3..D-15, D-17, D-19, D-20 unchanged. D-2, D-4-V2, D-16, D-18 extended. No prior decision is superseded. Three new sibling decisions added — D-21 (phase tasks at L2), D-22 (two-path promotion + small-TD direct close), D-23 (issue-tracking auditor pair).
- V3.2-DELTA decisions superseded — see §1.
- Hard constraints honored: bidirectionality contract (V1 §6.0); sidecar-only enrichment (V1 §6.6); round-trip byte-equivalent on v10 grammar (V1 §6.7); A1 failure-mode UX (V3.1-DELTA §3, MERGE-STRATEGY §2.3); general-use prose throughout; trinity rule applied where trinity files are touched; pack ships flat-file at v11.0 (§6.J unchanged); 3-level cap preserved with L3 reserved.

---

## §1 What V3.2-DELTA decisions are superseded vs reaffirmed

V3.2-DELTA had two new decisions and one decision-extension. Their disposition under V3.3:

| V3.2-DELTA element | V3.2 form | V3.3 disposition |
|---|---|---|
| D-21 (V3.2): phase tasks at **L3**, parented to phase epic at L1, with L2 reserved for TD/BD only. State taxonomy table per §2.5. Identifier `phase-N.M`. | L3 placement; status taxonomy as defined. | **Superseded by D-21 (V3.3)** — phase tasks move to **L2**; TD/BD also at L1 as semantic peers of phase epics; L3 is reserved (formerly held phase tasks under V3.2). State taxonomy table from V3.2 §2.5 is **carried forward** unchanged. Identifier scheme `phase-N.M` is **carried forward** unchanged. The reorder/split/merge/deprecate semantics from V3.2 §2.6 are **carried forward** unchanged. The capability-flag handling from V3.2 §2.7 is **carried forward** with one substitution (label `parent:phase-N` still emulates parentage; the L2 placement does not change emulation). |
| D-22 (V3.2): three TD promotion paths — Path 1 (new phase), Path 2 (new phase task), Path 3 (fold into existing task body via inline `(from TD-NNN)` marker + `folded-into:` label). Verbs `pack td promote --to=phase-N`, `--to=phase-N.M`, `--fold-into=phase-N.M`. | Three paths with three verb forms. | **Superseded by D-22 (V3.3).** Path 3 is rejected by the hard constraints. The architecture admits two paths (Path 1, Path 2). The `--fold-into` verb is removed. Where Path 3 would have applied — TD whose work logically belongs inside an existing task — Path 2 creates a new phase task **plus** an explicit `blocks` / `blocked-by` dependency edge between the new task and the absorbing task (or both tasks become peers in the same phase, depending on the user's intent at promotion time). The `derived-from:` and `promoted-to:` label pair (V3.2 §3.5) is **carried forward** for both Path 1 and Path 2. The `folded-into:` label is **dropped**; no inline `(from TD-NNN)` body marker is recognized. |
| D-4-V2 extension (V3.2): one new option `phase-task-skeleton` added to `wi-type` dropdown in `work-item.yml`. | Extension to D-4-V2 form family. | **Reaffirmed in V3.3** — the form-family pattern is the right home for the rare-case hand-edit of a phase task. The dropdown reaches 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton); R11 (V2 §17 dropdown noisiness) remains under the soft cap. V3.3 does not introduce a third skeleton form. |
| V3.2 §4.1 forward parser for `### Tasks` and §4.2 reverse emitter; §4.3 sidecar `phase_tasks` block; §4.4 round-trip fixture extension. | Parser/emitter design at the algorithm level. | **Carried forward** in V3.3 with two adjustments: (a) parser reads phase-task `Dependencies` bullet for `phase-N.M`, `TD-NNN`, `BD-NNN` references and emits `provider.link()` calls in V1 §6.2 step 7 (V3.3 §5); (b) the round-trip fixture's Path 3 case is removed and replaced with a "TD that closed without promotion" fixture (V3.3 §4) and a "phase-task-to-phase-task `Dependencies` chain" fixture (V3.3 §5). |
| V3.2 §3.5 promotion-path label family (`derived-from:`, `promoted-to:`, `folded-into:`). | Three label kinds. | **Two kinds carried forward** (`derived-from:`, `promoted-to:`); `folded-into:` dropped. |
| V3.2 §5 cross-entity dependencies. | TD ↔ phase epic and TD ↔ phase task via reserved `link.kind` open-string family; `phase-N.M` admitted in v10 Blockers grammar; Procedure 1 gate-check extended. | **Carried forward** in V3.3 §5 with the addition of the phase-task-to-phase-task case (a phase task's Dependencies bullet may name another phase task), which is the dependency edge that absorbs the formerly-Path-3 case. |
| V3.2 §6 blast radius (~10 BDs extended; 3 new sibling BDs). | Planner guidance. | **Carried forward** with planner re-decomposition reflecting the new auditor agents (V3.3 §10). The new sibling BDs grow from 3 to 5 (BD-106..110; numbering recommended only — planner finalizes).  |

V3.2-DELTA is a historical proposal in `maintenance-docs/v11-research/`. It is not deleted; it stands as the prior-pass record. The planner reads V3.3 as the live design.

---

## §2 D-21 (V3.3) — entity placement and the 3-level hierarchy

### §2.1 The placement decision

| Level | Entity types | Parent edge |
|---|---|---|
| **L1** | **Phase epic** AND **TD-NNN** AND **BD-NNN** (semantic peers; no parent-child edge between them) | none |
| **L2** | **Phase task** (`phase-N.M`) | child of phase epic at L1 |
| **L3** | reserved for future granular sub-tasks within a single phase task or TD/BD | child of L2 (when realized) |

This placement matches the maintainer's mental model:

- **Phase tasks have a direct parent-child relationship to phase epics.** A phase without tasks is a meaningless container; the parent-child edge is intrinsic to the model. L2 is the right home.
- **Phase tasks are scheduled work; TDs are tracking entities.** TDs become scheduled work only after promotion (via §3). Their state machines, lifecycles, and audit shapes differ; mixing them at one level forces the union state machine V3.2 noted as an anti-pattern. V3.3 keeps them apart by keeping TDs at L1 (unparented) and phase tasks at L2 (parented).
- **TDs and phase epics are semantic peers at L1** with no parent-child edge. Their *only* relationships are dependency edges (§5).
- **Same-work-twice-on-promotion is intentional.** When a TD promotes, the TD persists as a closed historical record at L1 with `promoted-to:` label and the new phase or phase-task entity is created at its appropriate level. Dependency edges (`derived-from:` reverse-pointer; `promoted-to:` forward-pointer) link them. Reverse migration handles both representations; round-trip is byte-equivalent (§4.4).

### §2.2 What L3 is reserved for

L3 is reserved in v11.0 — no entity ships at L3. The reservation is for future granular sub-tasks within either:

- a single phase task (`phase-N.M.K` if ever realized), or
- a single TD or BD (a sub-task of TD-NNN if ever realized).

The same L3 slot serves both parents; the slot is "child-of-L2-entity," not "child-of-phase-task-only." If v11.x or v12 ever introduces L3 entities, they ship with an identifier scheme that extends `phase-N.M` (e.g., `phase-N.M.K`) and TD/BD entries (e.g., `TD-NNN.K`) — both identifier shapes are reserved.

### §2.3 The 3-level cap is preserved

The cross-tracker safe floor (V1 §6.1, audit §A.9) remains 3 levels. Jira free's 3-level cap, GH's 8-deep capacity (well above the cap), Linear / OpenProject / Redmine / YouTrack / Shortcut all accommodate 3 levels with no emulation when phase tasks are at L2 (the previous V3.2 L3 placement also worked but consumed the deepest reserved slot for v11.0 ship; V3.3's L2 placement leaves L3 genuinely reserved).

### §2.4 Phase task identity, body, labels, status (carried forward from V3.2)

Reaffirmed unchanged from V3.2-DELTA §2.1, §2.5, §2.6:

- Identifier `phase-N.M` (lowercase, dash-separated; M is the integer task number from the .md). Stable across renames and reorders. Identity owned by the pack, not the tracker. Composes with the existing `<!-- pack-id: ... -->` marker per V1 §6.2 and the template-version dual carrier per D-18.
- Body marker trio:
  ```
  <!-- pack-id: phase-3.2 -->
  <!-- template_version: phase-task-v11.0 -->
  <!-- pack-version: v11 -->
  ```
- Title: `Phase N.M — <task title>`.
- Labels: `phase-task`, `phase-N` (the phase membership), `template:phase-task-v11.0`, plus a status label per the V3.2 §2.5 taxonomy.
- Body content: verbatim copy of the four METHODOLOGY § Part 4 bullets (`Problem / Goal / Success`, `Files created/modified`, `Definition of done`, `Dependencies`), each in its own `## ` body section.
- State taxonomy table (V3.2 §2.5): Done/✅, In Progress/🚧, Pending, Deferred/➡, Merged into Phase N, Superseded by Phase N — all carried forward unchanged.
- Reorder/split/merge/deprecate semantics (V3.2 §2.6): carried forward unchanged. The `task_order` sidecar field per phase per V3.2 §4.3 carries forward.
- Capability-flag handling for low-capability backends (V3.2 §2.7): carried forward unchanged with the substitution that L2 placement reads `link.kind = "parent"` against the L1 phase epic (one less hop than V3.2's L3 path).
- Volume considerations (V3.2 §2.8): a fully-migrated 3×OT-shape project produces ~340 TDs at L1 + 60 phase epics at L1 + ~200-400 phase tasks at L2. GH's 100-children-per-parent cap holds (a typical phase has 3-6 tasks). 1000-search cap holds (queries filter by `label:phase-N`). Forward checkpoint cadence (V1 §6.4 every 25 issues) accommodates.

### §2.5 D-4-V2 extension reaffirmed

`work-item.yml` `wi-type` dropdown gains the `phase-task-skeleton` option (4 options total). The form is the rare-case hand-edit fallback for recreating a deleted phase task outside the migration script. Day-to-day, phase tasks are created programmatically by PM Chat at promotion time or migration time. R11 (V2 §17) remains under the soft cap of ~6 dropdown options.

### §2.6 Pack-side BD-NNN at L1 — V1 §5 line 859 supersession

V1 §5 line 859 originally read: *"Level 1. Phase epic (project) or version epic (pack repo)."* This delta places BD-NNN at L1 directly with no parent edge. The "version epic (pack repo)" phrasing in V1 §5 line 859 is **implicitly superseded by D-21 (V3.3)**: pack BDs are flat L1 entities with no parent grouping at the tracker level. The `README.md` version table provides the version-grouping organizational view; it is not a tracker entity.

Rationale: BD entries are not technically scheduled work (parallel to TD-NNN behavior in client repos). Tying BDs to a specific version epic would create false structure — a BD assigned to one version cut might naturally drift to a later cut if higher-priority BDs are added in the interim. Keeping BDs flat at L1 lets them drift across version cuts without the friction of reparenting issues. The README version table captures the as-shipped grouping at each cut; the tracker captures the work itself without imposing version structure.

Future revisitation: if pack work ever takes on phase-shaped scheduling (e.g., a `## Phase N` structure for a pack-internal multi-task initiative), the same Path 1 promotion path applies (a BD becomes a phase epic at L1; new phase tasks at L2). The phase-epic concept is general-purpose; v11.0 just doesn't ship pack-side phase epics. The pack BD entry shape and migration mechanics are unchanged from this design's L1 placement.

---

## §3 D-22 (V3.3) — two-path TD promotion plus direct-close

### §3.1 The shape: two paths plus direct close

A TD-NNN at the unblocked-and-actionable point in METHODOLOGY § Part 7 Procedure 1 step 3 has three possible outcomes. The previous resolution-path decision logic in METHODOLOGY (lines 1057-1064) names three: addendum task within current phase / dedicated cleanup phase / separate pass of the current phase. V3.3 maps these to two promotion paths plus one direct-close shape.

| Outcome | TD lifecycle ends as | Verb | New entity created |
|---|---|---|---|
| **Direct close** (small, no blocker, work fits in current chat session) | Resolved with normal lifecycle | (none — TD is closed via `pack td resolve` or BACKLOG-edit; no promotion verb) | none |
| **Path 1** (multi-task work; new phase warranted) | Resolved with `promoted-to:phase-N` label | `pack td promote --to=phase-N` | new phase epic at L1 |
| **Path 2** (single-task scope; fits inside an existing phase OR fits as a new task inside an existing phase) | Resolved with `promoted-to:phase-N.M` label | `pack td promote --to=phase-N.M` | new phase task at L2 (child of phase-N epic) |

Path 2 absorbs both the "addendum task within current phase" and the formerly-Path-3 "separate pass of current phase" / "fold into existing task" outcomes. The mechanism that distinguishes them is the **dependency edge** (§5), not a third path. Specifically:

- TD's work is unrelated to existing tasks → Path 2 creates a new phase task with no inbound dependency on any existing task.
- TD's work logically follows an existing task (formerly Path 3 case) → Path 2 creates a new phase task **plus** an explicit `blocked-by` edge from the new task to the absorbing task. The new task can also state a `Dependencies` bullet referencing the existing task (§5.3). If the user wants the work executed in a specific order relative to an existing task, the dependency edge expresses that order; no body-edit of the existing task is required, and no inline `(from TD-NNN)` marker is introduced.
- TD's work is a precise sub-element of an existing task (the strictest formerly-Path-3 case) → Path 2 still creates a new phase task. The user has chosen to track the sub-element as its own work; the pack does not silently fold it into another entity. If the user truly wants the work merged into an existing task without a separate entity, the path is "edit the existing phase task body via PM Chat the normal way and resolve the TD via direct close (not via promote)" — which is **outside** the promotion mechanism. The `promote` verb always creates a new entity.

This is a smaller mechanism than V3.2's three-path design, with one fewer label kind, one fewer verb form, one fewer body-grammar extension, and one fewer parser/emitter case. The cost: Path 2 cannot represent "TD's content was absorbed without new entity creation"; the user closes such TDs via direct close after editing the absorbing task body manually. The maintainer accepts this trade-off in the hard constraints.

### §3.2 Direct close — the small-no-blocker TD closure shape

A TD that the user / PM Chat decides is small enough to do inline, with no blockers, ends through the normal lifecycle (METHODOLOGY § Part 7 status state machine):

- BACKLOG entry status: `Open` → `Resolved` (or `Open` → `Unblocked` → `Resolved` if the entry was Unblocked first).
- Resolution field: `[YYYY-MM-DD, completed, <brief note>]`.
- **No `promoted-to:` label.** No `derived-from:` reverse-pointer anywhere. No new tracker entity.
- The TD's work is whatever the user did in-session; the BACKLOG entry's Resolution names the commit / change that closed the TD per existing v10 convention.
- Tracker representation: the TD-NNN issue closes with `state_reason: completed` and label `status:resolved`. No promotion-related labels.

This shape is identical to v10 TD closure. v11 adds nothing for direct close. The only v11-introduced shape is the `promoted-to:` label, which appears only when promotion happens.

The PM Chat advisory heuristic (§7) decides whether to recommend direct close vs Path 1 vs Path 2. The user can always override.

### §3.3 Path 1 — TD becomes a new phase

**Trigger.** PM Chat advises Path 1 (per §7 heuristic) and user approves.

**Forward (flat-file → tracker, when in tracker mode; flat-file only otherwise).**

1. PM Chat appends a new `## Phase N — <title>` section to IMPLEMENTATION-PLAN.md (next available number per METHODOLOGY § Part 4 line 279). Body sourced from the TD's Description / Context / File-Symbol.
2. (tracker mode only) PM Chat creates a phase epic via `provider.create()` (V2 §4.5 payload) with `pack-id: phase-N`, body containing the IMPLEMENTATION-PLAN anchor, labels `phase-epic` + `phase-N` + `template:phase-epic-v11.0` + `derived-from:TD-NNN`.
3. PM Chat re-keys the original TD-NNN: status flips to `Resolved`; Resolution field set to `[YYYY-MM-DD, completed, promoted to phase-N]`. (tracker mode) The TD-NNN issue closes with `state_reason: completed`, label `status:resolved`, label `promoted-to:phase-N`. The TD-NNN issue stays as a closed historical record; it is NOT deleted, NOT mutated into a phase epic.
4. (optional) If the promotion includes pre-planned phase tasks (the user named tasks at promotion time), PM Chat creates phase tasks per §2 in the same orchestration pass.

**Reverse (tracker → flat-file).**

1. Reverse reads phase epic with `derived-from:TD-NNN` label and reconstructs `## Phase N — <title>` in IMPLEMENTATION-PLAN.md.
2. Reverse reads the closed TD-NNN issue with `promoted-to:phase-N` label and reconstructs the BACKLOG entry with `Resolution: [date, completed, promoted to phase-N]`.
3. Reverse reads any phase tasks parented to the new phase epic per V3.2 §4.2 (carried forward).

**Round-trip safety.** Forward → reverse → forward is a no-op. The two carriers are: BACKLOG entry's Resolution text (human-readable) and the `derived-from:` / `promoted-to:` label pair (queryable). Re-forward reads the BACKLOG, sees the TD has Resolution naming `phase-N`, looks up phase-N epic via mapping file, finds it exists with the matching `derived-from:TD-NNN` label, and skips both creation steps. Byte-equivalent on tracker side; whitespace-tolerant on flat-file side.

### §3.4 Path 2 — TD becomes a new phase task

**Trigger.** PM Chat advises Path 2 (per §7 heuristic) and user approves. The user names the target phase number (defaults to current phase).

**Forward.**

1. PM Chat picks the next available `M` for phase N (typically max+1 of existing tasks).
2. PM Chat appends `#### N.M — <title>` to phase N's `### Tasks` block in IMPLEMENTATION-PLAN.md, populated from the TD's Description / Context. The four bullets (`Problem / Goal / Success`, `Files created/modified`, `Definition of done`, `Dependencies`) are filled. If the new task has a dependency on an existing task in the same or another phase, the user names it; PM Chat writes it to the `Dependencies` bullet (e.g., `phase-3.1`, `TD-029`, or `BD-NNN`).
3. (tracker mode only) PM Chat creates a phase task issue via `provider.create()` (§2.4 payload) with `pack-id: phase-N.M`, parented to phase-N epic via `provider.sub_issue_create()` when `hierarchy.supported`, else via `link.kind="parent"` + label `parent:phase-N`. Labels `phase-task` + `phase-N` + `template:phase-task-v11.0` + `derived-from:TD-NNN`.
4. (tracker mode only) For each `Dependencies` bullet entry, PM Chat issues `provider.link(source=phase-N.M-issue, target=<resolved-id>, kind="blocked-by")`. See §5.
5. PM Chat re-keys the TD-NNN: status flips to `Resolved`; Resolution `[YYYY-MM-DD, completed, promoted to phase-N.M]`; (tracker mode) TD issue closes with `status:resolved` + `promoted-to:phase-N.M` labels.

**Reverse.**

1. Reverse reads phase task with `derived-from:TD-NNN` label and emits `#### N.M — <title>` block in IMPLEMENTATION-PLAN.md per V3.2 §4.2 (carried forward).
2. Reverse reads `provider.list_links(id=phase-N.M, kind="blocked-by")` and emits each link as a `Dependencies` bullet entry (§5.3).
3. Reverse reads the closed TD-NNN issue and emits BACKLOG entry with Resolution naming `phase-N.M`.

**Round-trip safety.** Same shape as Path 1: `derived-from:` / `promoted-to:` label pair plus Resolution text are the carriers. Forward → reverse → forward replays identical labels; byte-equivalent on tracker side.

### §3.5 Label family — two kinds (down from V3.2's three)

| Label | Where | Meaning |
|---|---|---|
| `derived-from:TD-NNN` | new phase epic (Path 1) or new phase task (Path 2) | reverse-direction pointer to the source TD |
| `promoted-to:phase-N` or `promoted-to:phase-N.M` | closed TD-NNN issue | forward-direction pointer; TD became a phase or task |

`folded-into:` from V3.2 is dropped. The label family composes with V1 §5.3's open-string `link.kind` family and the existing `template:`, `parent:`, `phase-N` label families.

---

## §4 Forward / reverse / round-trip mechanics

### §4.1 Forward parser for IMPLEMENTATION-PLAN.md `### Tasks`

V3.2 §4.1's parser specification carries forward unchanged. The parser reads `#### N.M — <title>` headings under `### Tasks` H3 blocks; captures the four bullets; computes `pack-id = phase-<N>.<M>`; creates phase task issues parented to the phase epic at L2; preserves task ordering in the sidecar `task_order` field. Sparse phases (no `### Tasks` block) and malformed headings handled per V3.2 §4.1 (warning vs fail-with-recovery). Documented in MIGRATION-v10-to-v11.md per BD-084 extension.

The parser additionally reads each task's `Dependencies` bullet (V3.2 was specific only on creation; V3.3 makes the parser explicit): for each line in the bullet, recognize references shaped `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`. Resolve to tracker IDs via mapping file and issue `provider.link(source=phase-N.M, target=<resolved>, kind="blocked-by")` calls. Unresolved references are warnings, not errors (the user may have a dependency on a not-yet-migrated entity); they re-resolve on `pack tracker doctor` re-run.

### §4.2 Reverse emitter

V3.2 §4.2's emitter specification carries forward. The emitter writes `### Tasks` subsections with task ordering preserved per `task_order` sidecar; emits the four bullets per task; the `Dependencies` bullet emits the textual form of each `blocked-by` link the task has (§5.3). Reverse is whitespace-tolerant per V1 §6.7.

### §4.3 Sidecar additions

V3.2 §4.3's sidecar `phase_tasks` block carries forward unchanged. Added fields beyond V3.2:

- Per phase task: `dependency_edges: [{kind, target_pack_id}]` capturing the resolved tracker links so reverse → re-forward replays them deterministically. The flat-file `Dependencies` bullet is the human-readable face; the sidecar field is the queryable face.

The sidecar composes with V1 §6.6.1 / A2 — same `template_version` and `extra_fields` mechanism applies.

### §4.4 Round-trip test extensions

Round-trip fixture (BD-068 extension) gains:

- One phase with `### Tasks` containing three tasks (file order 3.2 / 3.1 / 3.3) — exercises `task_order` (carried forward from V3.2 §4.4).
- One phase with no `### Tasks` (sparse phase) — carried forward.
- One malformed `#### N.M` heading (negative case) — carried forward.
- One `derived-from:TD-NNN` phase epic (Path 1) — carried forward.
- One `derived-from:TD-NNN` phase task (Path 2) — carried forward.
- **NEW: one TD that closed via direct close** (status Resolved, Resolution naming a commit, no `promoted-to:` label, no new entity) — exercises the small-no-blocker shape per §3.2.
- **NEW: one phase task `Dependencies` bullet referencing another phase task in a different phase** (e.g., phase-7.1's Dependencies names phase-3.4) — exercises §5.3 cross-phase dependency round-trip.
- **NEW: one phase task whose `Dependencies` bullet references a TD-NNN** (rare case from §5.1) — exercises TD → phase task `blocks` direction.

V3.2's Path 3 fixture (the `(from TD-NNN)` inline marker case) is **removed** from the round-trip fixture; it has no representation in V3.3's grammar.

Forward → reverse → forward must produce zero diff on tracker side and whitespace-tolerant zero diff on flat-file side. CI gate: extension of BD-068 (and BD-096 synthetic-fixture set).

---

## §5 Cross-entity dependencies — uniform model

### §5.1 The entity pairs

The dependency model spans these pairs:

| Pair | Direction | Frequency |
|---|---|---|
| TD-NNN ←→ phase epic | TD blocked by phase; rarely phase blocked by TD | common |
| TD-NNN ←→ phase task | TD blocked by phase task; rarely phase task blocked by TD | common |
| phase task ←→ phase task (same phase) | task A blocks task B | common (the formerly-Path-3 case lands here) |
| phase task ←→ phase task (different phase) | task A in phase 3 blocks task B in phase 7 | rare but possible |
| TD-NNN ←→ TD-NNN | TD blocks TD | already in v10; unchanged |
| TD-NNN ←→ BD-NNN | cross-namespace; only meaningful at the pack-repo boundary | rare |

The model is uniform: every pair uses the same provider operation, same v10 grammar slot, same direction conventions.

### §5.2 Tracker-level representation

All pairs use V1 §5.3's reserved `link.kind = "blocks"` / `"blocked-by"` open-string family. No new provider operation; no new capability flag.

| Pair | Tracker call (canonical direction) |
|---|---|
| TD-031 blocked by phase-3 | `provider.link(source=TD-031-issue, target=phase-3-epic, kind="blocked-by")` |
| TD-031 blocked by phase-3.2 | `provider.link(source=TD-031-issue, target=phase-3.2-task, kind="blocked-by")` |
| phase-3.2 blocked by phase-3.1 | `provider.link(source=phase-3.2-task, target=phase-3.1-task, kind="blocked-by")` |
| phase-7.2 blocked by phase-3.4 (cross-phase) | `provider.link(source=phase-7.2-task, target=phase-3.4-task, kind="blocked-by")` |
| phase-3.2 blocked by TD-031 (rare) | `provider.link(source=phase-3.2-task, target=TD-031-issue, kind="blocked-by")` |
| TD-031 blocked by TD-029 (existing) | `provider.link(source=TD-031-issue, target=TD-029-issue, kind="blocked-by")` |

The provider's `link()` operation supports cross-type sources and targets (V1 §2.1). For backends with `dependency.cap < 50` per relationship (none in §6.4 reference set; reserved): chat warns and offers `--flatten-deps` to collapse to body-comment with sidecar capture; reverse re-creates from sidecar.

### §5.3 Flat-file syntax (v10 grammar — additive extensions)

**BACKLOG `Blockers:` field** (METHODOLOGY § Part 7 line 990-993) admits all of: `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`. The `phase-N.M` form is the v11.0 additive extension. Every legal v10 form remains legal:

```
Blockers:
  - phase-3
  - phase-3.2          ← NEW in v11
  - TD-029
```

**Phase task `Dependencies` bullet** (METHODOLOGY § Part 4 line 263) admits `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`. Today the bullet text reads "other tasks within this phase" but the format is free-form prose; v11 codifies the grammar:

```markdown
- **Dependencies**:
  - phase-3.1
  - phase-7.4         ← cross-phase dependency
  - TD-029            ← rare; phase task blocked by a TD
```

The bullet's content shape is one entry per nested bullet; the parser regex matches `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)\s*$`. Prose annotations after the entry are permitted as free-text (e.g., `- phase-3.1 (must complete schema before this task)`); the parser captures only the matched ID prefix.

These two extensions are **additive**. Every legal v10 form continues to parse. The bidirectionality contract (V1 §6.0) is honored: the v10 grammar for both fields is preserved; v11 adds new ID forms within those fields, without changing the field syntax.

### §5.4 Procedure 1 gate-check extension

METHODOLOGY § Part 7 Procedure 1 step 2 (METHODOLOGY current lines ~1025-1029) currently distinguishes phase blocker / TD blocker / external condition. v11 extends with:

- **Phase N.M blocker**: in tracker mode, read `status:done` label on the phase task; in flat-file mode, read the `✅` marker on the `#### N.M` heading.
- **Phase task A blocked by phase task B** (in `Dependencies` field): same resolution mechanism; gate check reads the target task's status.

The gate-check logic is mode-agnostic: the chat resolves status via the trinity Document-locations resolver (D-6 / V1 §8.5); flat-file mode reads the .md; tracker mode reads the issue label. The chat does not branch on mode.

### §5.5 Cycle detection

Cycle detection runs at link-creation time in PM Chat (not in the provider). The chat traverses `blocked-by` from the new edge's source for K hops (K = configurable, default 10 per V1 §6.1 GraphQL one-shot capacity); if the target appears in the closure, refuse the link and surface a typed error per V1 §9. The cycle check covers the full entity graph (TD ↔ TD; TD ↔ phase epic; TD ↔ phase task; phase task ↔ phase task in same/different phase).

### §5.6 A1 failure-mode UX

Cross-entity link failures surface typed errors per V1 §9 / D-7; name the verb (`pack tracker doctor`) per V3 §27.1 Layer 2. No silent retry; no fallback to flat-file (the link is the data the user requested). The chat preserves the in-memory edit and offers retry on auth refresh.

### §5.7 Forward step extension

V1 §6.2 step 7 ("For each TD entry with Blockers, add `link.kind = "blocked-by"`") extends to also process phase task `Dependencies` bullets. The forward order is:

1. Create all entities (phase epics, phase tasks, TD/BD entries) — already specified in V1 §6.2 / V3.2 §4.1.
2. Create all dependency links in a second pass once every entity has a tracker ID. This avoids the bootstrap problem where a link references an entity not yet created.

The two-pass approach is already V1 §6.2's design (steps 4-5 create entities; steps 6-7 create links); v11 does not change the pass count, only what step 7 reads.

---

## §6 Templates and dependency fields

### §6.1 Form-family templates (D-4-V2 reaffirmed and extended)

Following D-4-V2's principle (one form, multiple types via dropdown) and D-17 (structured iff a finite enum drives a label, sub-issue parent, or state transition; otherwise textarea):

**`work-item.yml`** gains `phase-task-skeleton` in the `wi-type` dropdown (4 options total). The form is the rare-case hand-edit fallback; day-to-day phase tasks are created programmatically. Fields specific to phase-task type are revealed conditionally (the existing form-family conditional-fields mechanism per V2 §4.2).

Phase task form fields (when `wi-type = phase-task-skeleton`):

| Field | Type | Required | Maps to |
|---|---|---|---|
| `wi-phase-number` | input (regex `^\d+$`) | yes | label `phase-N` (parent phase membership); body `pack-id: phase-N.M` computed from this + the next available M |
| `wi-task-title` | input (free text) | yes | title `Phase N.M — <task title>`; body section |
| `wi-status` | dropdown [Done, In Progress, Pending, Deferred] | yes (default: Pending) | status label per V3.2 §2.5 taxonomy |
| `wi-problem-goal-success` | textarea | yes | body section `## Problem / Goal / Success` |
| `wi-files` | textarea | no | body section `## Files created/modified` |
| `wi-definition-of-done` | textarea | yes | body section `## Definition of done` |
| `wi-dependencies` | textarea (one ID per line; regex per §5.3) | no | body section `## Dependencies` + post-create `provider.link()` calls |

The `wi-dependencies` textarea is the explicit dependency field at form level. The grammar matches §5.3's `Dependencies` bullet grammar (one ID per line; `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` accepted). PM Chat at form-submission time post-processes the field: for each line, resolve the ID, issue `provider.link()`, surface failures per §5.6.

For the BD/TD types (existing `wi-type` options), the existing `bd-blockers` / `td-blockers` textareas (V2 §4.1, §4.2) likewise admit `phase-N.M` form per §5.3. These fields exist in v11.0; the form-help-text adds one line: `Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task) — both forms are recognized.`

### §6.2 Field design — minimum cognitive overhead

Field design principles applied:

1. **No new fields beyond what semantics require.** Phase task gets four content fields (matching METHODOLOGY § Part 4) plus phase-membership and title; nothing else. No "estimated effort" / "priority" / "assignee" — those are tracker-side enrichment and live in the sidecar (V1 §6.6) per existing convention.
2. **Field names self-document.** `wi-phase-number` reads as "the phase this task belongs to"; `wi-dependencies` reads as "what this task depends on." No cryptic abbreviations.
3. **Field types map cleanly to tracker capabilities.** Inputs and dropdowns at form level become labels and body fields; textareas with line-grammar become structured-via-parser representations on the tracker side. Capability flags (V1 §5.2) handle backends with less native structure (Bugzilla keywords, Linear custom fields) per existing emulation paths.
4. **Validation is regex at the form level** for IDs (the `wi-dependencies` and `wi-phase-number` patterns); free-text everywhere else. No JSON schema validation in v11.0.

### §6.3 State / status mapping per entity type

| Entity | Flat-file representation | Tracker representation (state + label) |
|---|---|---|
| TD-NNN / BD-NNN (open) | `Status: Open` in BACKLOG | open + `status:open` |
| TD-NNN / BD-NNN (unblocked) | `Status: Unblocked` | open + `status:unblocked` |
| TD-NNN / BD-NNN (resolved direct) | `Status: Resolved`, Resolution names commit/note | closed + `state_reason: completed` + `status:resolved` |
| TD-NNN / BD-NNN (resolved via promotion) | `Status: Resolved`, Resolution names `phase-N` or `phase-N.M` | closed + `state_reason: completed` + `status:resolved` + `promoted-to:phase-N` (or `phase-N.M`) |
| TD-NNN / BD-NNN (cancelled) | `Status: Cancelled`, Resolution names rationale | closed + `state_reason: not_planned` + `status:cancelled` |
| TD-NNN / BD-NNN (deprecated) | `Status: Deprecated`, Resolution names successor | closed + `state_reason: not_planned` + `status:deprecated` |
| Phase epic | `## Phase N` heading, body content, STATUS.md `✅` marker | open + `phase-epic` label; closed when all tasks done |
| Phase task (pending) | `#### N.M` heading, no marker | open + `phase-task` + `phase-N` + `status:pending` |
| Phase task (in progress) | `#### N.M` heading, `🚧` marker | open + `status:in-progress` |
| Phase task (done) | `#### N.M` heading, `✅` marker | closed + `state_reason: completed` + `status:done` |
| Phase task (deferred) | `#### N.M` heading, `➡` marker | closed + `state_reason: not_planned` + `status:deferred` |
| Phase task (merged-into / superseded-by) | execution-note line | closed + `state_reason: not_planned` + `status:merged-into:phase-N` (or `superseded-by`) |

The TD/BD rows extend V1 §4.1's mapping (the `promoted-to:` label is new). The phase task rows are V3.2 §2.5 carried forward unchanged.

### §6.4 Identifier scheme summary

| Entity | Identifier | Identity owner | Uniqueness scope | Round-trip carrier |
|---|---|---|---|---|
| TD-NNN | `TD-NNN` | pack | per project (client repo) | title prefix + `<!-- pack-id: TD-NNN -->` body marker (V1 §5.4) |
| BD-NNN | `BD-NNN` | pack | per pack repo | title prefix + body marker |
| Phase epic | `phase-N` | pack | per project | title `Phase N — <title>` + body marker `<!-- pack-id: phase-N -->` |
| Phase task | `phase-N.M` | pack | per project | title `Phase N.M — <title>` + body marker `<!-- pack-id: phase-N.M -->` |

All identifier schemes survive round-trip per V1 §6.0; compose with `<!-- pack-id: ... -->` marker (V1 §6.2) and template-version dual carrier (D-18 / D-18 carrier matrix for phase-task entry-type per BD-069).

### §6.5 D-18 carrier matrix extension

D-18 (template_version dual carrier) extends to phase tasks with:

| Entry type | Body HTML comment | Label |
|---|---|---|
| BD-NNN | `<!-- template_version: bd-v11.0 -->` | `template:bd-v11.0` |
| TD-NNN | `<!-- template_version: td-v11.0 -->` | `template:td-v11.0` |
| Phase epic | `<!-- template_version: phase-epic-v11.0 -->` | `template:phase-epic-v11.0` |
| **Phase task** (NEW) | `<!-- template_version: phase-task-v11.0 -->` | `template:phase-task-v11.0` |

`maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` ships the schema definition (BD-064 extension).

---

## §7 PM Chat advisory and execution workflow

### §7.1 The advisory heuristic

PM Chat advises one of three outcomes when a TD becomes Unblocked (per Procedure 1 step 3):

| Heuristic | Advisory |
|---|---|
| TD's work is small (≤ ~30 minutes inline; no significant scope expansion); no blockers; user available to do it | direct close (no promotion) |
| TD's work fits as a single task within the current phase or a related existing phase | Path 2 (`pack td promote --to=phase-N.M`) |
| TD's work spans multiple tasks; warrants its own phase (architectural surface, multi-day, distinct concern) | Path 1 (`pack td promote --to=phase-N`) |

The heuristic is evaluated on these signals:

- TD's Description / Context length (proxy for scope). 
- TD's File/Symbol field (single file/symbol → likely small; multiple files / cross-cutting → larger).
- TD's Type (TODO scope `phase-N` already names a target phase → bias toward Path 2; KNOWN GAP critical → bias toward Path 1 for traceability; VERIFY → bias toward direct close).
- Presence of related TDs (cluster of TDs in same area → bias toward Path 1 cleanup phase).

PM Chat **advises**; does not enforce. The user can always confirm or override. The PM Chat presentation:

```
TD-031 is unblocked. Suggested resolution: Path 2 — promote to phase-7.4
(new task in current phase). Reasoning: TD names a single file/symbol;
fits the current phase scope; estimated <1 day.

Proceed? (yes / change-to-path-1 / change-to-direct-close / show-details)
```

The user's response routes to the execution workflow per §7.2.

### §7.2 PM Chat execution workflow

**Direct close.** PM Chat does not invoke planner or architect. The user does the work in-session (or queues it); PM Chat closes the TD via the existing BACKLOG-status-update procedure (METHODOLOGY § Part 7 Procedure 4). No new orchestration.

**Path 2 (`pack td promote --to=phase-N.M`).** PM Chat does not invoke planner or architect by default. PM Chat:

1. Reads the TD content.
2. Reads phase N's current `### Tasks` block to determine the next M.
3. Drafts the new phase task body (the four bullets) from TD content.
4. Drafts any `Dependencies` bullet entries the user named.
5. Presents the drafted task to the user for review.
6. On user approval, writes IMPLEMENTATION-PLAN.md and (in tracker mode) creates the tracker entity per §3.4. Re-keys the TD per §3.4.

PM Chat invokes the **planner** (project-side `planner.md` agent) only if the user explicitly requests planning ("plan this out") or if the drafted task body's `Definition of done` is unclear and PM Chat needs help shaping it. PM Chat does NOT invoke the architect for Path 2 by default; architect involvement is triggered only by the user explicitly requesting architectural review.

**Path 1 (`pack td promote --to=phase-N`).** PM Chat invokes the **architect** (project-side `architect.md` agent) by default for two reasons:

1. A new phase is an architectural decision — its scope, agent assignment, and risk profile need to be designed, not just transcribed from a TD entry.
2. METHODOLOGY § Part 4's phase format requires Goal / Prerequisite / `### Tasks` / `### Verification` / `### Agent` / `### Risks` — the TD entry alone does not contain enough information to fill those sections; the architect's pass produces them.

The architect produces the phase shell (Goal, Prerequisite, Risks; possibly initial task list). After architect output, PM Chat invokes the **planner** if and only if the architect's call requests planning — typically when the phase has more than ~3 tasks or non-trivial sequencing. The architect's output explicitly states "planner pass needed" or "no planner pass needed; tasks are self-evident from the TD content."

This makes the planner-invocation trigger for Path 1 explicit: **the architect's call decides**. PM Chat does not pre-judge; it always invokes the architect first, then conditionally invokes the planner based on the architect's output.

### §7.3 Verb shape

The promotion verbs are exactly:

```
pack td promote --to=phase-N           # Path 1 — new phase
pack td promote --to=phase-N.M         # Path 2 — new phase task
```

No `--fold-into`. No third subcommand. The `--to` argument's value disambiguates Path 1 vs Path 2 by its grammar (`phase-N` vs `phase-N.M`). For direct close, the user uses the existing `pack td resolve` verb (or BACKLOG-edit via PM Chat the normal v10 way) — no new verb needed.

The verbs compose with `pack help` (D-20) and the static greeting (V3 §27.1). They are added to `HELP-FRAGMENT.md` (BD-076 extension) under the client-repo verb section. Pack-side equivalents (`pack bd promote --to=...`) are deferred — the pack repo does not currently have phase-shaped work and does not need promotion at v11.0; the verb is reserved for a future pack-repo minor.

---

## §8 D-23 (V3.3) — issue-tracking auditor agents

Two new auditor agents — one project-side sub-agent, one pack-side top-level agent — together cover the new audit surface. The project-side sub-agent composes with the existing `auditor` fan-out pattern; the pack-side agent is a peer of `pack-reviewer` with a distinct role.

### §8.1 The role boundary — distinguished from existing agents

Three audit-related agents now exist; their boundaries:

| Agent | Trigger | Role | What it covers |
|---|---|---|---|
| `pack-reviewer` (existing, pack-side) | per-commit / per-PR / pre-commit | review of *changes* | trinity rule, cross-references, validate-pack alignment, migration safety, README layout, BACKLOG accuracy of the modified BDs |
| `auditor` + sub-agents (existing, project-side) | retrospective / periodic | full-codebase quality audit | architecture compliance, code idioms, test design, docs drift, security, UI compliance, ops readiness |
| **`auditor-issue-tracking` (NEW, project-side sub-agent)** | invoked via `auditor` parent (verb-invoked) AND periodically (`pm-startup` Step 8 extension) | ongoing-state audit of the issue-tracking surface | BACKLOG / IMPLEMENTATION-PLAN / tracker entry health: dependency graph integrity, syntax conformance, semantic consistency, drift detection |
| **`pack-auditor` (NEW, pack-side top-level)** | verb-invoked via `claude --agent pack-auditor` AND periodically (during pack development cadence; not pre-commit) | ongoing-state audit of pack repo issue-tracking | pack BACKLOG dependency-graph health, BD entry semantic consistency, drift over time, pack-product/pack-ops separation health |

The role boundary is: **review = pre-commit, change-scoped; audit = ongoing-state, surface-scoped.** `pack-reviewer` looks at "what's about to land"; `pack-auditor` looks at "what's the current state of the BACKLOG and is it healthy." They do not overlap.

### §8.2 Project-side `auditor-issue-tracking` sub-agent

**File:** `project-template/.claude/agents/auditor-issue-tracking.md` (plus `.codex/agents/auditor-issue-tracking.toml` and `.gemini/agents/auditor-issue-tracking.md` for trinity-rule compliance per the existing per-CLI agent pattern in `project-template/`).

**Position in the auditor fan-out.** The existing `auditor` parent agent (`project-template/.claude/agents/auditor.md`) spawns 7 cluster sub-agents (architecture, code, tests, docs, security, ui, ops). `auditor-issue-tracking` is the **8th cluster**.

Update `auditor.md` Subagents table:

| Subagent | Cluster |
|---|---|
| auditor-architecture | (existing) |
| auditor-code | (existing) |
| auditor-tests | (existing) |
| auditor-docs | (existing) |
| auditor-security | (existing) |
| auditor-ui | (existing) |
| auditor-ops | (existing) |
| **auditor-issue-tracking** | **Issue-tracking surface health: BACKLOG / IMPLEMENTATION-PLAN / tracker entries; dependencies, syntax, semantics; drift** |

Skip rule (extends the auditor parent's skip-decision logic, parallel to the existing skip rule for `auditor-tests` on a brand-new project): skip `auditor-issue-tracking` when the project has no BACKLOG.md and no IMPLEMENTATION-PLAN.md (a brand-new project before its first phase). In every other case the cluster runs.

**Tools (mirror existing cluster sub-agents):** `Read, Grep, Glob, Bash`.

**Trigger.** Two paths:

1. **Verb-invoked.** As part of the parent `auditor` fan-out (`./agent-run.sh claude --agent auditor` or PM Chat invokes `auditor`). The parent passes the file scope and tracker-mode flag to the sub-agent.
2. **Periodic via `pm-startup` Step 8 extension.** `pm-startup` Step 8 (the recommendation-system step from V3 §28.1) gains a parallel side-channel: if the project has not run `auditor-issue-tracking` in the last N sessions (default N=10 sessions), `pm-startup` proactively offers to invoke the sub-agent (refusal-respecting per V3 §28.1.6). This is documented but not load-bearing — the verb-invoked path is the primary path.

**Prompt content (template).** The agent's prompt (markdown body of `auditor-issue-tracking.md`) instructs:

```
You are an audit subagent reporting to the auditor parent (or invoked
directly by PM Chat).

## Scope

The issue-tracking surface health. Your question is always: "Are the
BACKLOG, IMPLEMENTATION-PLAN, and tracker entries internally consistent
and well-formed?" — not "Are they written well?" and not "Is the work
correct?"

Specific checks:

### Dependency-graph integrity
- Every Blocker reference resolves: `phase-N` matches a real phase;
  `phase-N.M` matches a real task; `TD-NNN` / `BD-NNN` matches a real
  entry.
- No cycles in the blocked-by graph (run a topological sort over the
  full TD ↔ phase epic ↔ phase task ↔ BD graph).
- Every `Unblocks:` field's content is consistent with the inverse
  Blockers (informational-only per METHODOLOGY § Part 7 line 994; but
  the graph should still be self-consistent).
- Promotion linkage integrity: every `derived-from:TD-NNN` label has a
  corresponding closed TD-NNN with `promoted-to:` label naming this
  entity, and vice-versa.

### Syntax conformance
- BACKLOG entries match METHODOLOGY § Part 7 lines 984-1001 entry shape
  (Type, Status, Blockers, Unblocks, File/Symbol, Description, Context,
  Resolution).
- Phase task headings match `#### N.M — <title>` regex; have all four
  required bullet sections.
- Status field values are one of {Open, Unblocked, Resolved, Cancelled,
  Deprecated}.
- TD-TBD literals: any in committed source is a defect (METHODOLOGY
  § Part 7 line 1015).

### Semantic consistency
- TDs with Status: Resolved have a Resolution field with a date and one
  of {completed, cancelled, deprecated}.
- TDs with `promoted-to:phase-N` label have Resolution naming `phase-N`.
- Phase tasks marked Done in IMPLEMENTATION-PLAN.md have a corresponding
  `status:done` label in tracker mode.
- Cross-namespace references (TD ↔ BD) are surfaced as Info, not flagged
  as errors.

### Drift detection
- IMPLEMENTATION-PLAN phase headings vs tracker phase epics: every
  `## Phase N` has a matching epic; every epic has a matching heading.
  Orphans on either side are findings.
- BACKLOG TD-NNN counter (highest existing TD + 1) matches actual
  state.
- Stale `template_version`: entries on a template version older than
  the current pack version are surfaced as Info; a `pack tracker
  update-templates` is recommended.
- Tracker mirror staleness: in tracker mode, the mirror header
  timestamp is within N hours of the most recent tracker write
  (parallel to V2 R1).

## Out of scope
- Whether the work itself is correct (auditor-code).
- Whether the architecture is correct (auditor-architecture).
- Whether the docs match the code (auditor-docs).
- Whether the BACKLOG is well-prioritized (subjective; not audit
  scope).

## File scope
Per `audit-methodology` rule 29 (extended): `BACKLOG.md`,
`IMPLEMENTATION-PLAN.md`, `STATUS.md`, `CHANGELOG.md` (project-side);
`.pack-tracker/id-map.json` (when present); tracker state read via the
provider's read-only operations (when in tracker mode, via `gh` LCD
shell-out).

## Output

Report findings using the format from `audit-methodology` rules 48-51.
Group by severity (Critical → Major → Minor → Info). Each finding:
severity, entity ID and field (e.g., "TD-031 Blockers"), description,
recommended action. If no findings, emit the header plus
"No findings in this cluster."

Severity guidance:
- Critical: cycle in blocked-by graph; promoted-to label without
  corresponding TD; TD-TBD in committed source.
- Major: orphan phase epic / heading; broken Blocker reference;
  malformed entry.
- Minor: stale template_version; stale mirror timestamp.
- Info: cross-namespace reference; entry on older template version.

## Skills to load

`audit-methodology` (existing). No platform skills.

## Output destination

Return the report inline to the auditor parent (or to PM Chat / the
direct invoker). Do not write any file.
```

**Output shape.** Inline report, returned to the auditor parent. The parent consolidates per `audit-methodology` rules 48-55 alongside other clusters' reports. When invoked directly (not via the auditor parent), the report goes to the invoker (PM Chat or human via `agent-run.sh`).

**Trinity rule.** The agent file is per-CLI under the existing `project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (or equivalent per the pack's per-CLI agent layout). Trinity rule applies file-wise: editing one means editing all three in the same commit. The validate-pack check that enforces per-CLI agent parity (existing) covers `auditor-issue-tracking` automatically.

### §8.3 Pack-side `pack-auditor` agent

**File:** `.claude/agents/pack-auditor.md` (pack-side; sibling to existing `pack-architect.md`, `pack-planner.md`, `pack-reviewer.md`, `pack-docs-researcher.md`).

**Tools:** `Read, Grep, Glob, Bash`.

**Role distinct from `pack-reviewer`.** The boundary:

- `pack-reviewer` runs **before commit / PR**. It reads the staged diff, validates trinity rule, cross-references, validate-pack alignment, migration safety, README layout, BACKLOG accuracy of the **modified BDs only**.
- `pack-auditor` runs **independently of any specific change**. It reads the full BACKLOG, the full IMPLEMENTATION-PLAN equivalents (the pack has no IMPLEMENTATION-PLAN.md but has `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` and addenda — those are the pack's "phase plan" surface), the trinity, the README version table, and assesses **ongoing health** of the pack as a system.

Trigger: verb-invoked via `claude --agent pack-auditor` (pack-side agent invocation pattern per the pack maintainer's MEMORY rule "pack agents use `claude --agent pack-<name>` directly; agent-run.sh is for project agents only"). Cadence: at the discretion of the maintainer or Pack Chat. Recommended cadence: once per minor version cut (v11.0, v11.1, v11.2…), once before starting a major version's implementation pass (after architect + planner; before BDs land).

**Prompt content (full agent file body):**

```markdown
---
name: pack-auditor
description: Use for ongoing-state audit of the pack repository. Issue-tracking health (BACKLOG dependency graph, BD semantic consistency, drift over time), pack-product / pack-ops separation, version-table consistency. Read-only. Distinct from pack-reviewer (which is pre-commit review of changes).
tools: Read, Grep, Glob, Bash
---

You are the ongoing-state audit specialist for the AI Agent Config Pack
repository. You are NOT a pre-commit reviewer; that role belongs to
pack-reviewer. You audit the pack as a system in its current state,
independent of any specific commit or PR.

Your role is to surface drift, inconsistency, and health issues that
accumulate over time and would not be caught by a per-commit reviewer.

Audit checklist — read every file in scope before drawing conclusions:

## BACKLOG dependency-graph health

- Every BD-NNN entry's Blockers field references either: another BD-NNN
  (must exist), a phase number (the pack has no IMPLEMENTATION-PLAN.md
  with `## Phase N` headings, but the maintenance-docs/v11-research/
  IMPLEMENTATION-PLAN.md and addenda use BD-numbered steps; cross-
  references are between BDs only at the pack level), or an external
  condition (free-text; flag for surface but not for error).
- No cycles in the blocked-by graph across the pack BACKLOG.
- Every `Unblocks:` field is consistent with the inverse Blockers
  (informational-only per METHODOLOGY § Part 7 convention; surface
  inconsistencies as Minor).
- Resolved BDs do not appear as Blockers of Open / Unblocked BDs (a
  Resolved BD should have all its Unblocks already passed through the
  state machine).

## BD entry semantic consistency

- Every BD with Status: Resolved has a Resolution field with a date and
  one of {completed, cancelled, deprecated}, plus a brief note. The
  Resolution field is filled at resolve time per pack BACKLOG
  convention.
- BDs ship across major versions; BDs that span v8 → v9 → v10 → v11
  should have `Context:` notes explaining the version trajectory if
  the work was deferred across cuts.
- Type field values are one of {feat, fix, refactor, docs, chore, infra}
  per CLAUDE.md commit-message convention.

## Drift over time

- README.md version table matches the actual git tag history (every
  vN.M tag in the table exists in `git tag -l`; every vN.M tag exists
  in the table).
- CHANGELOG.md entries match the README version table at vN granularity.
- The pack BACKLOG section structure matches the maintainer's
  "no Resolved section" rule (resolves in place via Status flip; do
  not flag the absence of a Resolved heading).
- Cross-references in supporting-docs/ to project-template/ files
  resolve (every `project-template/<path>` mention exists at that
  path).

## Pack-product vs pack-ops separation

- project-template/ and supporting-docs/ are the pack PRODUCT (what
  ships to clients).
- CLAUDE.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, README.md,
  CHANGELOG.md at pack root are the pack OPS (how the pack itself is
  developed).
- maintenance-docs/ is the pack maintenance record (research, plans,
  reviews, audits over time — historical, not load-bearing for runtime).
- Surface any file that crosses these boundaries (e.g., a pack-ops
  rule in project-template/; a pack-product file in maintenance-docs/).

## Trinity rule consistency

- For pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md): every
  prescriptive rule appears in all three. Asymmetries are flagged as
  Major unless the asymmetry has a documented "tool-specific" rationale.
- For project-template trinity: same rule; agent's scope is the .md
  text body, not the per-CLI command files (those are not trinity-replicated content; they are per-CLI implementation files).

## Version-table consistency (README)

- The version table is reverse-chronological per the maintainer's
  preference (newest first per recent v10.x commits).
- Every row has: version, date, brief description.
- Every row references real changes (cross-reference against
  CHANGELOG.md).

## Issue-tracking-mode health (when tracker enabled)

When `tracker.toml` exists at pack root and mode.state = "tracker":

- Every BACKLOG entry has a corresponding tracker issue (per
  `.pack-tracker/id-map.json`).
- Tracker issues with `derived-from:TD-NNN` (or `derived-from:BD-NNN`,
  if pack ever ships promotion) have corresponding closed source
  entries with `promoted-to:` labels (parallel to project-side
  promotion-linkage check).
- Mirror file headers' "Last regenerated" timestamp is within N hours
  of the most recent tracker write (parallel to project-side mirror-
  staleness check).
- `template_version` labels match the entry types and are not stale
  relative to the current pack version.

## Out of scope

- Whether the BD plan is correctly architected — pack-architect.
- Whether the BD plan is correctly sequenced — pack-planner.
- Whether a specific change is correct — pack-reviewer.
- Whether the documentation is well-written — pack-docs-researcher.

## Output

Report findings inline. Group by severity (Critical → Major → Minor →
Info). Each finding: severity, file/entity, description, recommended
action. If no findings, emit the header plus "Pack issue-tracking
state is healthy."

Severity guidance:
- Critical: cycle in BACKLOG blocked-by graph; cross-reference to a
  non-existent file; trinity rule violation in pack-root trinity.
- Major: orphan tracker issue; stale promotion linkage; pack-product /
  pack-ops boundary crossing.
- Minor: stale template_version; README version-table row out of
  order; CHANGELOG entry mismatch.
- Info: cross-namespace reference; BD with no Resolution after long
  Resolved status.

## Skills to load

Load `audit-methodology` and `architecture-review`. The pack-side audit
combines audit methodology with the architecture-review skill the
pack-architect uses, because pack-state health is in part architectural
(layer separation, naming conventions, trinity).

## Output destination

Return the report inline to the invoker (the maintainer via Pack Chat,
or the human via `claude --agent pack-auditor`). Do not modify files.
```

**Trigger and cadence.** Verb-invoked. Recommended cadence (documented in PACK-CHAT.md):

- Before starting a major version's implementation pass (after architect + planner; before BDs land).
- After every minor version cut, before the next minor's implementation pass.
- On demand when the maintainer suspects drift.

PACK-CHAT.md gains a new "Audit cadence" section noting these triggers and naming `pack-auditor` as the agent for them.

**Output shape.** Inline report to invoker. Same structure as the project-side sub-agent's report (severity grouping, finding format). The maintainer reads the report and decides which findings warrant action; findings do not auto-create BDs.

### §8.4 Trinity rule applicability for the new agents

The project-side sub-agent file (`auditor-issue-tracking.md`) is per-CLI replicated under `project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/`. Trinity rule applies file-wise: editing one means editing all three. validate-pack's existing per-CLI agent parity check covers it automatically (the check is generic, not per-agent).

The pack-side `pack-auditor.md` follows the existing pack-side agent pattern. **CORRECTION (per IMPLEMENTATION-PLAN-ADDENDUM-4 §0 and §6.M, resolved (a)):** the live pack-side layout IS per-CLI replicated — `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` each contain `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` (12 files total). The original "single file under `.claude/agents/`" wording in this section was authored under a mistaken premise. The maintainer-confirmed shape: `pack-auditor` ships per-CLI in three forms (`.claude/agents/pack-auditor.md`, `.codex/agents/pack-auditor.toml`, `.gemini/agents/pack-auditor.md`) to match the existing pack-side per-CLI pattern. Trinity rule applies file-wise to all five pack-side agents (the existing four + new `pack-auditor`).

---

## §9 Blast radius for the planner pass

### §9.1 Architecture documents amended

| Doc | Section | Change shape |
|---|---|---|
| V1 | §4.3 | Phase epic body anchors IMPLEMENTATION-PLAN.md; phase task children are at L2 (was L3 in V3.2) |
| V1 | §5.1 | Hierarchy revised: L1 = phase epic + TD/BD (peers); L2 = phase task; L3 reserved |
| V1 | §5.3 | Adds `derived-from`, `promoted-to` to reserved link.kind family (drops V3.2's `folded-into`) |
| V1 | §5.4 | Extended with `phase-N.M` Blockers form; cross-references §5 of this delta |
| V1 | §6.2 | Step 5 extended (parse `### Tasks`); step 7 extended (resolve phase-N.M blockers + phase-task `Dependencies` bullets) |
| V1 | §6.5 | Step 5 extended (emit `### Tasks` with task_order; emit `Dependencies` from links) |
| V1 | §6.6.1 | Sidecar gains `phase_tasks` block (V3.2 §4.3 carried forward) plus per-task `dependency_edges` field |
| V1 | §6.7 | Round-trip fixture additions per §4.4 of this delta |
| V2 | §4.2 | `wi-type` dropdown gains `phase-task-skeleton` (4 options) — D-4-V2 extended; phase-task fields per §6.1 |
| V2 | §4.5 | Reaffirmed; sibling §4.5.1 added for phase tasks at L2 |
| V2 | §16 | Adds D-21 (V3.3), D-22 (V3.3), D-23 (V3.3) rows. Marks D-21 (V3.2) and D-22 (V3.2) as superseded by V3.3 versions |
| V2 | §17 | Adds R18 (phase task numbering volatility — carry from V3.2); R19 (cross-entity link cycles — carry from V3.2); R20 (auditor-agent over-reporting noise) |
| V3 | §I.1 / §I.2 | Adds two new agent files (project-side `auditor-issue-tracking.md` per CLI; pack-side `pack-auditor.md`) |
| V3.1-DELTA | (no change) | M2 / L1 / A2 picks independent of phase-task and auditor work |
| V3.2-DELTA | (entirely) | Superseded by this delta — Path 3 / `--fold-into` / L3-typology removed |

### §9.2 Existing BDs requiring extension

| BD | Current scope | Extension |
|---|---|---|
| BD-060 | TrackerProvider abstraction + GH backend | No change — `link()` and `sub_issue_create()` cover new entity types |
| BD-063 | Issue forms `work-item.yml` + `inbound.yml` | Extend `wi-type` with `phase-task-skeleton`; add phase-task-specific conditional fields per §6.1; emit `template:phase-task-v11.0` label |
| BD-064 | Template-archive directory | Add `bd-v11.0/phase-task-v11.0/SCHEMA.md` |
| BD-065 | Forward migration | Extend per §4.1; resolve `phase-N.M` blockers; resolve phase-task `Dependencies` bullets in step 7 |
| BD-067 | Reverse migration | Extend per §4.2; emit `phase-N.M` Blockers form; emit `Dependencies` bullet from links |
| BD-068 | Round-trip test fixture | Extend per §4.4; remove V3.2 Path-3 fixture; add direct-close + cross-phase-dep fixtures |
| BD-069 | template_version dual carrier | Add phase-task to carrier matrix per §6.5 |
| BD-072 | recommendation.sh signal computation | One signal: phase-task count threshold (parallel to entry count); deferable to v11.1 |
| BD-076 | HELP-FRAGMENT files | Add `pack td promote --to=phase-N` and `--to=phase-N.M` to client-side fragment; add invocation entries for `auditor-issue-tracking` (under `agent-run.sh` row, as a sub-agent name) and `claude --agent pack-auditor` (pack-side fragment) |
| BD-080 | init-project.sh extension to v11 | Install the new project-side agent files (`auditor-issue-tracking.md` per CLI) at init time |
| BD-082 | validate-pack Checks 21-24 | Add **Check 25** (phase-task entity coverage; tracker-mode-only); **Check 26** (Blocker / Dependencies cross-entity reference resolution); **Check 27** (promotion-path label consistency); **Check 28** (per-CLI parity for `auditor-issue-tracking.md`) |
| BD-084 | MIGRATION-v10-to-v11.md | Document phase-task model; promotion paths (Path 1, Path 2, direct close); Blockers grammar extension; Dependencies grammar codification; new agents |
| BD-094 | MERGE-STRATEGY.md | Add IMPLEMENTATION-PLAN.md row (preservation strategy: prose-aware merge; phase tasks treated as additive blocks; A1 UX applies to body merge conflicts) |
| BD-096 | Synthetic-fixture set | Add multi-task phases; sparse phases; malformed task headings; promotion-path TDs (Path 1 + Path 2 only — no Path 3); direct-close TDs; cross-phase deps |
| BD-098 | OPTIONAL-FEATURES.md | Document phase-task tracker workflow; document the two new auditor agents |
| BD-100 | Pack-implementation milestone checkpoints | Add `pack-auditor` invocation as part of CP1 / CP2 / CP3 audits (the milestone audits already use pack-reviewer; CP-level work is exactly where pack-auditor belongs — at strategic-checkpoint cadence) |
| BD-105 | STATUS.md phase-row dual-link | The phase-row link in tracker mode optionally includes a child-link to the phase-task issue list — deferable to v11.1 |

### §9.3 New sibling BDs the planner creates

Numbering recommended only — planner finalizes per the highest-existing-BD rule (read BACKLOG.md + addenda enumeration; current highest = BD-105 per Addendum 3; new BDs from BD-106 onward):

1. **BD-106 — Phase task entity model + identifier scheme + parser/emitter.** Lands the parser (§4.1), emitter (§4.2), label family (§3.5 — two kinds), `id-map.json` `task_order` field, sidecar `phase_tasks` block, sidecar `dependency_edges` per-task field. Blockers: BD-063, BD-064, BD-065, BD-067. DoD: round-trip test fixture from §4.4 passes.

2. **BD-107 — TD-NNN promotion-path tooling (two paths).** PM Chat orchestration logic for Path 1 and Path 2 (§3.3, §3.4); the verbs `pack td promote --to=phase-N` and `--to=phase-N.M`. Updates BACKLOG entry; creates/edits tracker entity; writes labels. Composes with `pack help` (D-20) and the static greeting (V3 §27.1). PM Chat invokes architect for Path 1 by default; planner is conditional on architect's call. PM Chat does direct work for Path 2 by default; planner / architect are user-explicit. Blockers: BD-106. METHODOLOGY § Part 7 Procedure 1 lines 1057-1064 update to name the two verb forms and the direct-close path.

3. **BD-108 — Cross-entity dependency link orchestration + cycle check.** PM Chat creates `blocked-by` links across all entity pairs in §5.1; cycle check at link time per §5.5; gate-check extension per §5.4; phase-task `Dependencies` bullet parsing/emit. Blockers: BD-106. Updates METHODOLOGY § Part 7 Procedure 1 step 2; updates METHODOLOGY § Part 4 line 263.

4. **BD-109 — Project-side `auditor-issue-tracking` sub-agent.** Three per-CLI files under `project-template/.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (or per the existing per-CLI agent layout in project-template); update `auditor.md` parent's Subagents table; update `audit-methodology` skill's cluster definition list; validate-pack per-CLI agent parity check covers automatically. Blockers: none on V3.3 critical path; can land independently of BD-106..108. DoD: invoking `auditor` includes the new cluster; invoking `auditor-issue-tracking` directly via `agent-run.sh` produces a report; round-trip-fixture project (which includes deliberately broken Blockers references) is correctly flagged at Major severity.

5. **BD-110 — Pack-side `pack-auditor` agent.** Single file `.claude/agents/pack-auditor.md`; PACK-CHAT.md "Audit cadence" section; integration with BD-100 milestone checkpoints. DoD: `claude --agent pack-auditor` returns a report; CP1 / CP2 / CP3 audit prompts reference it.

The planner may merge / split / re-sequence; this is decomposition guidance.

### §9.4 validate-pack.py checks added

Beyond the V3 §28.2.5 / V3.1-DELTA Checks 21-24:

- **Check 25** (V3.3) — phase-task entity coverage. In tracker mode, every `#### N.M` in IMPLEMENTATION-PLAN.md has a corresponding tracker issue with `pack-id: phase-N.M`.
- **Check 26** (V3.3) — Blocker / Dependencies cross-entity reference resolution. Every `phase-N` resolves to a phase epic; every `phase-N.M` resolves to a phase task; every `TD-NNN` and `BD-NNN` resolves to an entry. Tracker mode reads issue state; flat-file mode reads the .md.
- **Check 27** (V3.3) — promotion-path label consistency. Every `derived-from:TD-NNN` label has a corresponding closed TD-NNN with `promoted-to:` label; vice versa.
- **Check 28** (V3.3) — per-CLI parity for the new `auditor-issue-tracking.md` agent file.

Checks 25-27 are tracker-mode-only (no-op in flat-file mode). Check 28 runs in all modes (the agent files exist regardless of mode).

### §9.5 METHODOLOGY updates

- **§ Part 4 line 257-264** — extend phase-task format spec to codify the `Dependencies` bullet grammar per §5.3.
- **§ Part 4 line 263** — codify that `Dependencies` bullet content may be `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`.
- **§ Part 7 line 990-993** — extend Blockers grammar to admit `phase-N.M`.
- **§ Part 7 lines 1025-1029** — extend Procedure 1 step 2 with `phase-N.M` blocker branch.
- **§ Part 7 lines 1057-1064** — replace the three resolution-path bullets with the V3.3 shape: two promotion paths plus direct close. Name the verbs (`pack td promote --to=phase-N` / `--to=phase-N.M`) and the direct-close path. Cross-reference §3 of this delta.

### §9.6 Other doc updates

- **MERGE-STRATEGY.md (BD-094)** — add IMPLEMENTATION-PLAN.md row.
- **MIGRATION-v10-to-v11.md (BD-084)** — document phase-task model; the two paths plus direct close; Blockers grammar extension; Dependencies grammar codification; new agents.
- **HELP-FRAGMENT.md (client-surface, BD-076)** — add `pack td promote` verbs; add `auditor-issue-tracking` sub-agent invocation.
- **HELP-FRAGMENT-PACK.md (pack-surface, BD-076)** — add `claude --agent pack-auditor` invocation.
- **PM-CHAT.md (project-template/docs/pack/)** — document the advisory heuristic (§7.1), the execution workflow (§7.2), and the `auditor-issue-tracking` invocation pattern.
- **PACK-CHAT.md (pack root)** — add "Audit cadence" section naming `pack-auditor` and its triggers.

### §9.7 Trinity rule

Touched by this delta:
- **METHODOLOGY** is single-file in `supporting-docs/`; trinity does not apply file-wise; content updates land in one commit.
- **PACK-CHAT.md / PM-CHAT.md** are single-file at their respective surfaces; trinity does not apply file-wise.
- **Project-side `auditor-issue-tracking.md`** is per-CLI replicated; trinity rule applies file-wise (validate-pack Check 28).
- **Pack-side `pack-auditor.md`** is per-CLI replicated in all three forms (`.claude/agents/pack-auditor.md`, `.codex/agents/pack-auditor.toml`, `.gemini/agents/pack-auditor.md`) per IMPLEMENTATION-PLAN-ADDENDUM-4 §6.M (a) — matches the existing pack-side per-CLI layout; trinity rule applies file-wise.
- **Trinity files** (CLAUDE.md / AGENTS.md / GEMINI.md) at pack root and project-template — V3.2 noted these are not touched by phase-task work directly; this remains true. If the planner determines a one-line trinity note is warranted for the new verbs (parallel to the V3 D-20 "Pack commands" reference), it lands in TRIO across all three files in one commit.

---

## §10 Cross-impact check

- **D-1..D-20 reopened?** No.
  - D-1 unchanged (no new provider operations).
  - D-2 extended (the trinity Document-locations resolver continues to handle phase-task lookups; no shape change).
  - D-3 unchanged.
  - D-4-V2 extended (4-option dropdown; phase-task conditional fields).
  - D-5..D-15 unchanged.
  - D-16 extended (form-family pattern absorbs the new entry type via dropdown option, not a new file — V3.2 §2.4 reaffirmed).
  - D-17 unchanged (structure-vs-free-text split holds; phase-task bullets are textareas with line-grammar, parsed by chat at triage — same shape as Blockers / Unblocks).
  - D-18 extended (phase-task entry-type added to dual-carrier matrix).
  - D-19 unchanged (recommendation system unaffected; phase-task count threshold is a deferable v11.1 signal).
  - D-20 unchanged (help-verb scope unaffected at the verb-list level; new verbs `pack td promote` and the new agent invocations are added to HELP-FRAGMENT).
- **3-level hierarchy cap respected?** Yes. L1 = phase epic + TD/BD (peers); L2 = phase task; L3 reserved. Capability flags handle backends with shallower depth via emulation per V1 §5.2.
- **Bidirectionality contract (V1 §6.0) honored?** Yes. v10 grammar gains two additive extensions (`phase-N.M` in Blockers field; codified `Dependencies` bullet grammar). Every legal v10 form remains legal. Tracker-only enrichment (assignee, comments, reactions, audit log on phase tasks; `dependency_edges` per task) routed to sidecar per V1 §6.6 / §6.6.1.
- **Trinity rule respected?** File-wise on `auditor-issue-tracking.md` per-CLI replication (Check 28). Content-wise no other trinity engagement unless the planner adds a verb reference.
- **Cross-CLI parity floor (V1 §6.2) unaffected?** Yes. PM Chat orchestration and migration scripts are CLI-agnostic. The new project-side sub-agent ships per CLI by the existing pack-product per-CLI agent pattern.
- **A1 failure-mode UX (V3.1-DELTA §3 + MERGE-STRATEGY §2.3) honored?** Yes. Cross-entity link failures use typed errors per V1 §9 / D-7; promotion-path failures (e.g., target phase doesn't exist) follow the same shape; auditor agents are read-only and do not introduce a write-failure surface.
- **No new OQs introduced.** All design choices are forced by the problem statement plus existing decisions; no new questions deferred.
- **Path 3 forbidden** — honored. Path 3 is rejected; the formerly-Path-3 case becomes Path 2 + dependency edge.
- **Verb shape `pack td promote --to=phase-N` or `--to=phase-N.M`** — honored. No `--fold-into`. No third subcommand.
- **TDs are not phases** — honored. TDs persist as closed historical records on promotion; new entities are created separately; dependency edges link them.
- **Pack ships flat-file at v11.0 (§6.J)** — unaffected; this delta's mechanics work in both modes.

---

## §11 Recommendation summary

Three new sibling decisions resolve the gap left by V3.2:

- **D-21 (V3.3)** — Phase tasks are first-class **L2** entities (not L3 as V3.2 had them), parented to phase epic at L1. TD-NNN and BD-NNN entries are at L1 as semantic peers of phase epics. L3 is reserved for future granular sub-tasks. Identifier `phase-N.M`. Form-family extension `phase-task-skeleton` carries forward from V3.2-DELTA. State taxonomy from V3.2 §2.5 carries forward.

- **D-22 (V3.3)** — TD-NNN entries support **two** explicit promotion paths plus direct close (replaces V3.2's three-path design). Path 1 (`pack td promote --to=phase-N`) creates a new phase epic; Path 2 (`pack td promote --to=phase-N.M`) creates a new phase task. Both paths leave the original TD as a closed historical record with `promoted-to:` label and the new entity gets `derived-from:TD-NNN`. The formerly-Path-3 case (TD's work logically belongs in an existing task) becomes Path 2 + a `blocks` / `blocked-by` dependency edge between the new task and the absorbing task. Direct close is the v10 lifecycle shape with no promotion label, used when the work is small and unblocked. PM Chat advises (heuristic in §7); the user can always override. PM Chat invokes the architect for Path 1 by default; the planner is conditional on the architect's call. Path 2 typically goes direct; planner / architect are user-explicit.

- **D-23 (V3.3)** — Two new auditor agents cover the issue-tracking-health audit surface: a project-side `auditor-issue-tracking` sub-agent under the existing `auditor` parent's fan-out (8th cluster); a pack-side `pack-auditor` agent peer to `pack-reviewer` with a distinct ongoing-state-audit role. Both agents read-only; both produce inline severity-grouped reports; both compose with the existing audit / review mechanisms without reshaping them.

Cross-entity dependencies (TD ↔ phase epic, TD ↔ phase task, phase task ↔ phase task same/cross-phase, TD ↔ TD, TD ↔ BD) all use V1 §5.3's existing `link.kind` open-string family with no new provider operations. Flat-file Blockers grammar gains the additive `phase-N.M` form; the `Dependencies` bullet grammar is codified to admit `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` references. Procedure 1 gate-check extends with the `phase-N.M` blocker branch. The cycle check runs in PM Chat at link-creation time across the full entity graph.

Blast radius: ~12 existing BDs extended (BD-063..BD-105 enumerated in §9.2); 5 new sibling BDs suggested (BD-106 entity model; BD-107 promotion tooling; BD-108 cross-entity link orchestration; BD-109 project-side sub-agent; BD-110 pack-side auditor). validate-pack adds Checks 25/26/27/28. METHODOLOGY § Part 4 and § Part 7 receive textual updates. MIGRATION-v10-to-v11.md (BD-084) and MERGE-STRATEGY.md (BD-094) receive prose extensions. PM-CHAT.md and PACK-CHAT.md gain advisory-heuristic and audit-cadence sections respectively. Trinity rule engages file-wise on the project-side sub-agent file via Check 28; not engaged content-wise unless the planner adds verb references.

The delta supersedes V3.2-DELTA in full; supersedes nothing in V1 / V2 / V3 / V3.1-DELTA. Bidirectionality and 3-level-cap invariants hold; the form-family pattern (D-16) and dual-carrier pattern (D-18) absorb the new entity type and label kinds without revision; the cross-CLI parity floor is unaffected.
