# Stream contract — project-changelog

> **Audience:** agents + PM Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / any other doc. `_intro.md`
> is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump).

## Stream identity

- Stream name: `project-changelog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/changelog/`

## Source of truth — flat-file (no monolith)

**Flat-file mode (the sole supported mode).** The per-entry tree at
`docs/project/changelog/` (plus its generated `docs/project/changelog/_toc.md`
index) is the SOLE source of truth and readable form — no monolithic
mirror; do not recreate one. Validation runs against the tree.

## Filename convention

Per-entry files match `^\d{4}-\d{2}-\d{2}(-.+)?\.md$` (e.g.,
`2026-04-20-phase-35.md` or bare `2026-04-20.md` when the H3 anchor has
no slug suffix). Date-first for lexical sorting; the trailing slug is
optional for human readability.

## Entry contract

One CHANGELOG entry per file. The first line is an HTML-comment
back-pointer ABOVE the H3 heading; the content span begins at the H3
heading (`### YYYY-MM-DD — Phase N — <title>` or
`### YYYY-MM-DD — Architecture Iteration — <title>`).

## Entry structure (structured, not form-family)

- core-fields: Summary "Test count" Files
- core-required-when: code-bearing
- doc-only-exemption: zero-test-and-zero-files OR heading-class=doc
- extras: admitted
- entry-max-lines: 180
- summary-max-words: 250

Notes: `Files` is satisfied by ANY `**Files <verb>**:` label
(`Files modified` / `Files created` / `Files deleted` / `Files renamed`,
with an optional `(N)` count suffix). A code-bearing entry carries the
core set; a doc-only entry (zero `Test count` AND zero `Files`) is
Summary-only-valid. `extras` (e.g. `Sections updated`, `Build warnings`,
`Tasks completed`, `Backlog items addressed`) are admitted. Size caps
are cheap deterministic line / word counts.

## Filename mapping

The per-entry filename is `YYYY-MM-DD-<slug>.md` where `<slug>` mirrors
the heading suffix (e.g. `### 2026-04-20 — Phase 35 — Live Broker Sandbox`
→ `2026-04-20-phase-35.md`;
`### 2026-03-20 — Architecture Iteration — Strategy Event Model`
→ `2026-03-20-architecture-iteration.md`). Entries read in
date-descending order (newest first).

## Lifecycle states admitted

Append-only-historical — no lifecycle states. Once written, an entry is
never edited.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 7. Write procedure: write a new
per-entry file at `docs/project/changelog/<YYYY-MM-DD-slug>.md`
(append-only; one entry per phase at phase completion; date = the date
the phase was committed to `main`). After any entry add, regenerate
`_toc.md` before staging. Never hand-edit `_toc.md` (derived index).
