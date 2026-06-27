# Project implementation plan

Human-only orientation for the project implementation-plan stream.
This file carries no rules — the per-stream contract lives in
`_rules.md`. Edit this file freely to fit your project; the pack
never overwrites it after install.

The implementation plan is a per-entry flat-file tree: one
`phase-N.md` file per phase (tasks inline), with a generated
`_toc.md` index and a generated `_index.md` ordering. The tree is
the sole source of truth and readable form.

## Orientation

- **Browse the phases.** Read `_toc.md` for the full phase
  inventory; read `_index.md` for the dependency-derived serial
  order. For a single phase, open its `phase-N.md` file directly.
- **The contract.** `_rules.md` declares the filename convention,
  the entry schema, the phase-state vocabulary, the supporting-file
  basenames, and write authority. Read it before adding or editing
  a phase.
- **Tasks live inline** in the phase file (no `phase-N.M.md`
  per-task files).
