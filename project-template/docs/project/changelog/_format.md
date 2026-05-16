# CHANGELOG Format Rules

This file is the project-side CHANGELOG entry-format spec. It is
project-side asymmetry: pack-side CHANGELOG has no `_format.md`
analog (per `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5 and §11). Pack-
shipped immutable: updates only on pack version bump (per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §3.3).

## Entry format

Each per-entry file contains one v10-grammar CHANGELOG entry. The
shape (per `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 411–421):

```
### YYYY-MM-DD — Phase N — <title>

**Summary**: <one-paragraph summary of what was completed>

**Tasks completed**:
- §N.0a — <task description>
- §N.0b — <task description>
- ...

**Backlog items addressed**: TD-NNN resolved. TD-NNN, TD-NNN
investigated and deferred with logging (blocked on <reason>).
TD-NNN–TD-NNN created from §N.M audit.

**Files created**: <comma-separated file list>
**Files modified**: <comma-separated file list>
**Test count**: <NNN> passing, <NNN> failing
**Build warnings**: <NNN>
```

For early-project iterations not tied to a numbered phase, use the
heading form `### YYYY-MM-DD — Architecture Iteration — <title>`
instead of `### YYYY-MM-DD — Phase N — <title>`.

## Rules

- **Append-only**: never edit prior entries. Add new entries at
  the top of the (regenerated) mirror, which corresponds to a new
  per-entry file with the most-recent date in the per-entry tree.
- **One entry per phase** at phase completion, committed in the
  same PR as the phase work.
- **Date** = the date the phase was committed to `main`.
- **Separator** (`---`) precedes every entry — including the
  first one. The mirror generator emits the separator
  deterministically; per-entry files do not contain `---`
  separators (the file boundary IS the separator per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.0).
- **Architecture Iteration** label for early-project architecture
  doc iterations (rather than `Phase N`).
- **BACKLOG.md**: mark resolved TD items ✅ in the same commit as
  the phase. (The `✅ RESOLVED (Phase NN)` annotation goes in the
  TD entry's bold-header per
  `ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.3.)
- **README.md**: update Known Limitations in the same commit when
  a TD that appears there is resolved.

## Filename mapping

The per-entry filename is `YYYY-MM-DD-<slug>.md` where `<slug>`
mirrors the heading suffix:

- `### 2026-04-20 — Phase 35 — Live Broker Sandbox Verification`
  → `2026-04-20-phase-35.md`
- `### 2026-03-20 — Architecture Iteration — Strategy Event Model`
  → `2026-03-20-architecture-iteration.md` (or a more specific
  slug if multiple iterations land on the same date).

The mirror generator emits entries in date-descending order (newest
first) per the append-only-historical convention.
