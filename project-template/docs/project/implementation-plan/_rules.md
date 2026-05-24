# Stream contract — project-implementation-plan

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump).

## Stream identity

- Stream name: `project-implementation-plan`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/implementation-plan/`

## Filename convention

Per-entry files match `^phase-\d+\.md$` (e.g., `phase-0.md`,
`phase-35.md`). One file per phase; tasks live inline in the phase
file (no `phase-N.M.md` per-task files).

## Entry contract

Phase epic + tasks inline: H2 phase heading (`## Phase N — <title>`),
`**Goal**:`, `**Prerequisite**:`, `---`, `### Tasks` (with
`#### N.M — <title>` sub-sections inline), `### Verification`,
`### Agent`, `### Risks`. The first line is an HTML-comment
back-pointer ABOVE the phase heading.

## Lifecycle states admitted

Phase-state vocabulary:
pending / in-progress / done / deferred / merged-into /
superseded-by. State is annotated in the H2 heading via `🚧`
(in-progress) / `✅` (done) / `➡` (merged / superseded).

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime. Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 4. The monolithic
`docs/project/IMPLEMENTATION-PLAN.md` is a regenerated mirror —
read-stable but never source of truth; hand-edits are silently
overwritten on the next regeneration.
