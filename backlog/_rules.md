# Stream contract — pack-backlog

> **Audience:** agents + Pack Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / any other doc. `_intro.md`
> is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Updated only when the pack
changes the per-entry contract.

## Stream identity

- Stream name: `pack-backlog`
- Pack version that minted this contract: v11.0
- Directory: `/backlog/`

## Source of truth — flat-file (no monolith)

**Flat-file mode (the sole supported mode).** The per-entry tree at
`/backlog/` (plus its generated `/backlog/_toc.md` index) is the SOLE
source of truth and readable form — no monolithic mirror; do not recreate
one. GH Issues are IGNORED by all tooling; inbound-feedback issues are a
human/PM triage channel only. Validation runs against the tree.

## Filename convention

Per-entry files match `^BD-\d+\.md$` (e.g., `BD-060.md`, `BD-167.md`).
Three-or-more-digit BD-NNN; NO letter suffix — a sub-part is an in-body
section, not a suffixed entry.

## ID-extraction rule

The per-entry **filename is the ID**: for a header `**BD-167 — <Title>**`
the file is `BD-167.md`. A parenthetical qualifier, if present, is TITLE
TEXT after the em-dash — never between the ID and the em-dash — and is
preserved byte-faithfully in the entry body's bold-header line. The ID is
the captured `BD-\d+` group only — no letter suffix, no pre-em-dash
parenthetical.

## Entry contract

One BD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the content span begins at `**BD-NNN — <Title>**`,
followed by the `Type:` / `Status:` / `Description:` fields per the
standard BACKLOG item format (METHODOLOGY.md Part 7).

**Field-faithful — the contract does not gate on a field allowlist.**
An entry body carries every top-level field VERBATIM. METHODOLOGY.md
Part 7 (the template SSOT) enumerates the COMMON fields (`Type:` /
`Status:` / `Blockers:` / `Unblocks:` / `File/Symbol:` /
`Description:` / `Context:` / `Resolution:`); EXTENSION fields
(`Target:`, `Position:`, etc.) are ADMITTED and PRESERVED. A future BD
adding a field needs no contract change here.

## Lifecycle states admitted

- `Open` — entry is active / not yet started.
- `Unblocked` — a pending-decision state between Open and Deferred
  (a canonical lifecycle state).
- `Deferred` — deliberately postponed (user-authorized).
- `Resolved` — entry is closed; carries a `Resolved:` line.
- `Deprecated` — superseded / no longer pursued.
- `Cancelled` — abandoned without resolution.

Entries resolve **in place** by flipping `Status: Open` to
`Status: Resolved` and filling the `Resolved:` line — no separate
Resolved section.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are Pack-Chat authority (the pack-backlog tree is a pack-chat-only
directory per `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
directories"; agents edit it only when a caller scopes it in for an
explicit BD). Write procedure: edit the per-entry file directly; entries
resolve in place. After any entry edit, regenerate `_toc.md` via
`per_entry_regenerate_toc pack-backlog /backlog` before staging. Never
hand-edit `_toc.md` (derived index).
