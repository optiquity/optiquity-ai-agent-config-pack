# Stream contract — project-changelog

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump).

## Stream identity

- Stream name: `project-changelog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/changelog/`

## Filename convention

Per-entry files match `^\d{4}-\d{2}-\d{2}(-.+)?\.md$` (e.g.,
`2026-04-20-phase-35.md` or bare `2026-04-20.md` when the source
H3 anchor has no slug suffix). Date-first for lexical sorting;
trailing slug optional for human readability per
`scripts/lib/per-entry/_lib.sh` post-BD-164-retro Option B
(slug optional).

## Entry contract

One v10-grammar CHANGELOG entry per file. Shape: H3 heading
(`### YYYY-MM-DD — Phase N — <title>` or `### YYYY-MM-DD —
Architecture Iteration — <title>`), then body fields per the
Format Rules in `_format.md`. The first line is an HTML-comment
back-pointer ABOVE the H3 heading.

## Lifecycle states admitted

Append-only-historical — no lifecycle states. Once written, an
entry is never edited per the `_format.md` "Append-only" rule.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`
- `_format.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime. Files not matching the entry regex AND not in this list are SKIP.
`_format.md` is project-side only (no pack analog).

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 7 + `_format.md` (this directory).
The monolithic `docs/project/CHANGELOG.md` is a regenerated mirror —
read-stable but never source of truth; hand-edits are silently
overwritten on the next regeneration.
