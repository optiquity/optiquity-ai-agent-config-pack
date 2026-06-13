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

Flat-file is the sole supported mode, and always the repo's committed
state: this directory is the **sole source of truth and readable form**
for pack backlog entries — one `BD-NNN.md` file per entry, plus a
generated `_toc.md` index. There is no monolithic `BACKLOG.md` mirror.
Tracker (GH Issues) integration is deferred (BD-214); see `_rules.md`
§ "Source of truth — flat-file (no monolith)".

## Reading entries

- For a full inventory grouped by status, read `_toc.md`.
- For a single entry, read its per-entry file directly at
  `/backlog/<BD-NNN>.md`. The first line is an HTML-comment back-pointer
  that names the contract at `/backlog/_rules.md`.

## Adding a new entry

Find the highest existing `BD-NNN` (across the tree), increment by 1.
How the entry is then written depends on the stream's mode — follow
`_rules.md` § "Write authority". Pack Chat writes; agents edit only
when scoped in.

## Resolving an entry

Entries resolve in place (`Status: Open` flips to `Status: Resolved`,
with the `Resolved:` line filled) — there is no separate Resolved
section. The write channel is mode-dependent — follow `_rules.md`
§ "Write authority".

## Cross-references

`BD-NNN`, `BD-NNNb`, and `vN` identifiers may appear in `Blockers:` /
`Unblocks:` / prose; cross-reference integrity is validated against the
defined-ID set of the tree.
