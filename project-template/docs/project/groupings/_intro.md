# Project groupings

Human-only orientation for the project groupings stream. This file
carries no rules — the per-stream contract lives in `_rules.md`.
Edit this file freely to fit your project; the pack never overwrites
it after install.

A grouping is a named, pure-structure list of implementation-plan
phases — a membership record (a user journey, a refactor cluster, a
release package, …), never an ordering or lifecycle surface. The stream
is a per-entry flat-file tree: one GRP-NNN.md file per grouping, with a
generated `_toc.md` index as the sole readable form.

## Orientation

- **Browse the inventory.** Read `_toc.md` for the Kind-grouped list.
  For a single grouping, open its GRP-NNN.md file directly.
- **The contract.** `_rules.md` declares the filename convention, the
  entry schema, the membership rules, the reserved GRP-000
  declared-ungrouped ledger, and write authority. Read it before adding
  or editing an entry.
- **Cross-references.** Member phases resolve to
  `docs/project/implementation-plan/` phase entries; a grouping's status
  and target are always derived from those entries at read time, never
  stored here.
