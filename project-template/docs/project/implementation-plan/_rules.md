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

Notes: `body-sections` are recognized, not mandated (the gold varies).
`phase-part` is lightweight (Entry-Type only); the validator tolerates
inline parts gracefully. Phase / part / task headings follow the
graceful naming convention: `### Phase-N.Part-x — `, `#### Phase-N.Part-x.Task-k — `,
and epic-task `#### N.M — ` directly under `### Tasks`.

## Ordering — `_index.md`

`_index.md` stores the dependency-derived serial order of phase entries.
It is GENERATED (a topological seed from each phase's `Blockers` /
`Unblocks` SSOT) and VALIDATED (hard-dependency-order consistency +
per-entry↔`_index.md` membership sync). Dependencies stay SSOT in the
entry files; `_index.md` is not a competing source. Parallelization is
a runtime decision, never stored.

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

## Lifecycle states admitted

Phase-state vocabulary:
not-started / in-progress / done / deferred / merged-into /
superseded-by. State is annotated in the H2 heading via `🚧`
(in-progress) / `✅` (done) / `➡` (merged / superseded).

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
and `_index.md` before staging. Never hand-edit `_toc.md` or `_index.md`
(derived indexes).
