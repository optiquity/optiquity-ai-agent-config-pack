# Project backlog

Human-only orientation for the project backlog stream. This file
carries no rules — the per-stream contract lives in `_rules.md`.
Edit this file freely to fit your project; the pack never overwrites
it after install.

The backlog is a per-entry flat-file tree: one `TD-NNN.md` file per
backlog item, with a generated `_toc.md` index. The tree is the sole
source of truth and readable form.

## Orientation

- **Browse the inventory.** Read `_toc.md` for the full TD-NNN list.
  For a single item, open its `TD-NNN.md` file directly.
- **The contract.** `_rules.md` declares the filename convention,
  the entry schema, the lifecycle states, the supporting-file
  basenames, and write authority. Read it before adding or editing
  an entry.
- **Cross-references.** TD-NNN / phase-N / phase-N.M identifiers may
  appear in an entry's `Blockers` / `Unblocks` fields or in prose.
