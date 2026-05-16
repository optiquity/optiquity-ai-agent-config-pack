# Stream contract — project-backlog

Per-stream contract. Pointer-heavy by design. Pack-shipped immutable
(updates only on pack version bump per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Stream identity

- Stream name: `project-backlog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/backlog/`

## Filename convention

Per-entry files match `^TD-\d+\.md$` (e.g., `TD-001.md`). Three-
digit zero-padded TD-NNN per `ARCHITECTURE-V3.3-DELTA.md` §6.4.

## Entry contract

One v10-grammar TD entry per file, byte-additive on the legacy
monolithic per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3. The first
line is an HTML-comment back-pointer ABOVE the bold-header per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §2; the
byte-identical span begins at `**TD-NNN — <Title>**`. Grammar:
`ARCHITECTURE-V3.1-DELTA.md` §3 A2 + `ARCHITECTURE-V3.3-DELTA.md`
§6.4.

## Lifecycle states admitted

- `Open` — entry is active.
- `Resolved` — entry is closed; carries `Resolution:` plus inline
  `✅ RESOLVED (Phase NN)` annotation per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3.

Project backlog uses only these two states (per
`ARCHITECTURE-V3.3-DELTA.md` §6.3).

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

The per-entry helpers (`scripts/lib/per-entry/`) read this list at
runtime per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §7.5.
Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md` Part 7, and pack `PACK-AGENTS.md` (the
project-side analog ships in PM-CHAT.md). The monolithic
`docs/project/BACKLOG.md` is a regenerated mirror — read-stable but
never source of truth; hand-edits are silently overwritten on the
next regeneration.
