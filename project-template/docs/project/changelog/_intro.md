# Project change log

Human-only orientation for the project changelog stream. This file
carries no rules — the per-stream contract lives in `_rules.md`.
Edit this file freely to fit your project; the pack never overwrites
it after install.

The changelog is a per-entry flat-file tree: one
`<YYYY-MM-DD-slug>.md` file per dated phase / architecture-iteration
record, with a generated `_toc.md` index. The tree is the sole
source of truth and readable form. It is the historical record of
architectural decisions and phase completions; current architecture
is documented in the project's `ARCHITECTURE.md`.

## Orientation

- **Browse the history.** Read `_toc.md` for the full
  date-descending history. For a single entry, open its
  `<YYYY-MM-DD-slug>.md` file directly.
- **The contract.** `_rules.md` declares the filename convention,
  the entry structure, the supporting-file basenames, and write
  authority. Read it before adding an entry.
- **Append-only.** Never edit a prior entry file. To correct a
  mistake, add a new entry that supersedes the prior one and
  document the supersession.
