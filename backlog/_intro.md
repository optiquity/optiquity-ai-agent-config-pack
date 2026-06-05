# Pack backlog — how to use this tree

> **Audience:** humans.
> **Purpose:** orientation. This file is NOT read by agents and carries
> NO rules. The per-stream contract (filename regex, lifecycle states,
> ID-extraction, write authority) lives entirely in `_rules.md`. An
> agent reading only `_rules.md` + the entry files + `_toc.md` has
> everything it needs.

All planned improvements to the AI Agent Config Pack are tracked here.
Items use `BD-NNN` identifiers (pack backlog) rather than `TD-NNN`
(project backlog). Format follows the standard BACKLOG item format from
METHODOLOGY.md Part 7.

This directory is the **sole source of truth and readable form** for
pack backlog entries — one `BD-NNN.md` file per entry, plus a generated
`_toc.md` index. There is no monolithic `BACKLOG.md` mirror.

## Reading entries

- For a full inventory grouped by status, read `_toc.md`.
- For a single entry, read its per-entry file directly at
  `/backlog/<BD-NNN>.md`. The first line is an HTML-comment back-pointer
  that names the contract at `/backlog/_rules.md`.

## Adding a new entry

Find the highest existing `BD-NNN` (across the tree), increment by 1,
write a new per-entry file at `/backlog/BD-NNN.md`, then regenerate
`_toc.md`. Pack Chat writes; agents edit only when scoped in.

## Resolving an entry

Edit the per-entry file: flip `Status: Open` to `Status: Resolved` and
fill the `Resolved:` line. Entries resolve in place — there is no
separate Resolved section. Then regenerate `_toc.md`.

## Cross-references

`BD-NNN`, `BD-NNNb`, and `vN` identifiers may appear in `Blockers:` /
`Unblocks:` / prose; cross-reference integrity is validated against the
defined-ID set of the tree.
