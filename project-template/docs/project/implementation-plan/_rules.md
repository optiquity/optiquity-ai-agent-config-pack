# Stream contract — project-implementation-plan

> **Audience:** agents + PM Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / `_index.md` / any other
> doc. `_intro.md` is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Client-immutable: do not
edit this file in a client project — updates arrive only on a pack
version bump; the client's `verify-immutable.sh` enforces this.

## Stream identity

- Stream name: `project-implementation-plan`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/implementation-plan/`

## Source of truth — flat-file (no monolith)

**Flat-file mode (the sole supported mode).** The per-entry tree at
`docs/project/implementation-plan/` (plus its generated `_toc.md`
index and `_index.md` ordering) is the SOLE source of truth and
readable form — no monolithic mirror; do not recreate one. Validation
runs against the tree.

## Filename convention

Per-entry files match `^phase-\d+\.md$` (e.g., `phase-0.md`,
`phase-35.md`). One file per phase; tasks live inline in the phase file
(no `phase-N.M.md` per-task files).

## Entry contract

One phase epic per file, tasks inline. The first line is an
HTML-comment back-pointer ABOVE the phase heading; the content span
begins at the H2 phase heading (`## Phase N — <title>`).

## Entry schema (form-family)

- entry-types: phase-epic phase-part
- phase-epic-fields: ID Status Blockers Unblocks Goal Prerequisite
- phase-part-fields: (none required beyond Entry-Type)
- phase-epic-id-template: phase-N
- status-enum: done in-progress not-started blocked deferred superseded
- body-sections: Tasks Verification Agent Risks
- extension-fields-admitted: "Execution order" Superseded-By Merged-Into "Critical distinction"
- target-enum: current next-release next-minor next-major future-unassigned

Notes: `body-sections` are recognized, not mandated (the gold varies).
`phase-part` is lightweight (Entry-Type only); the validator tolerates
inline parts gracefully. Phase / part / task headings follow the
graceful naming convention: `### Phase-N.Part-x — `, `#### Phase-N.Part-x.Task-k — `,
and epic-task `#### N.M — ` directly under `### Tasks`.

## Target semantics

`Target:` is optional on phase-epics. Absent = no claim — NOT
`future-unassigned`. Present ⇒ exactly one `target-enum` token,
non-empty (present-but-empty FAILs; an unknown value FAILs). Each
token is a release-cycle deadline window, stated as an UPPER bound
only (landing earlier than the window opens violates nothing):

- `current` — due before the version now being built is released.
- `next-release` — due before the release AFTER the one now being
  built (the next release of ANY kind).
- `next-minor` — due before the next minor-or-major release; may slip
  past patch releases.
- `next-major` — due before the next major release; may slip past
  patch and minor releases.
- `future-unassigned` — unconstrained; never release-blocking; a
  specific version intent, when one exists, goes in the phase
  description as prose.

`next-minor` / `next-major` are meaningful only for release schemes
that distinguish those release kinds; projects without that
distinction use `current` / `next-release` / `future-unassigned`.

The `target-enum` declaration order is the ordinal scale. A grouping's
target derives as the maximum over its non-done and non-superseded
declaring members' targets (see `docs/project/groupings/_rules.md`
`## Derived status and target`).

Any phase may carry version prose in its description text; tooling
never interprets it.

Targets are claims maintained by the release-boundary procedure
(`docs/pack/PM-CHAT.md`); validation checks vocabulary, not currency.

An untargeted blocker of targeted work carries an implied bound,
computed from dependency edges, never stored. A declared target that
exceeds the bound provable from dependency edges and other phases'
declared targets is a validation FAIL. Where a garbled field or
dependency cycle makes a bound unprovable, validation reports that
defect itself and the conflict check speaks only to provable bounds.
The coherence check reads dependency edges read-only — targets never
alter dependency mechanics or ordering.

## Ordering — `_index.md`

`_index.md` stores the dependency-derived serial order of phase entries.
It is GENERATED (a topological seed from each phase's `Blockers` /
`Unblocks` / `Dependencies` / `Prerequisite` SSOT) and VALIDATED
(hard-dependency-order consistency + per-entry↔`_index.md` membership
sync). Dependencies stay SSOT in the entry files; `_index.md` is not a
competing source. Parallelization is a runtime decision, never stored.

"Never stored" is scoped to `_index.md`: the runtime decision IS
recorded — in the client-authored, committed
`docs/project/pm-session-state.json` snapshot, the live-orchestration
layer, whose schema is defined and enforced by the shipped
`validate-docs.sh` session-state axis. Parallelization mode, wave, and
runtime queue order live there, never in `_index.md`, which keeps only
the dependency-derived topological order (the constraint); the
snapshot's `queue` is the user-decided runtime sequence within that
constraint. The two may legitimately differ — a difference is not
drift to fix.

Grouping membership is an input to the order derivation: grouping-mates
(phases sharing a real grouping — GRP-000 excluded) are placed
contiguously wherever the declared dependency edges (`Blockers` /
`Unblocks` / `Dependencies` / `Prerequisite`) permit, interleaved only
where cross-group blockers force it. The affinity is a tie-break among
topologically valid orders and never constrains parallelization —
groupings still declare no order. Completable groupings' phases order
ahead of phases whose every grouping membership is deferral-poisoned,
wherever the declared dependency edges permit — a deterministic
tie-break of the same mechanism class.

## Lifecycle states admitted

Phase-state vocabulary:
not-started / in-progress / done / blocked / deferred / superseded.
State is annotated in the H2 heading via `🚧` (in-progress) /
`✅` (done) / `➡` (merged / superseded).
`Merged-Into` / `Superseded-By` are the extension fields that
accompany terminal supersession: a merged phase's `Status:` is
`superseded` with `Merged-Into` set. `merged-into` / `superseded-by`
are not state tokens.

Supersession is terminal: a superseded phase is frozen, never
revertible to any open state — revival is a NEW phase.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_index.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 4. Write procedure: author / edit a
`phase-N.md` entry directly. After any entry edit, regenerate `_toc.md`
and `_index.md` before staging by running
`bash scripts/per-entry-regen.sh implementation-plan` from the project
root (`bash scripts/per-entry-regen.sh --check` reports drift without
writing). Never hand-edit `_toc.md` or `_index.md`
(derived indexes).
