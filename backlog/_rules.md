# Stream contract — pack-backlog

> **Audience:** agents + Pack Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files.
> This file is the single source for the per-stream rules; no rule is
> duplicated or fragmented across `_intro.md` / `_toc.md` / any other
> doc. `_intro.md` is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Updated only when the
pack changes the per-entry contract.

## Stream identity

- Stream name: `pack-backlog`
- Pack version that minted this contract: v11.0
- Directory: `/backlog/`

## Source of truth — no mirror

The per-entry tree at `/backlog/` (plus its generated `/backlog/_toc.md`
index) is the **SOLE source of truth and readable form** for pack
backlog entries. **There is no monolithic mirror.** The former
`pack-ops/BACKLOG.md` monolith was deleted at BD-203; do not recreate
it. To read entries, read the per-entry files (or `_toc.md` for an
index); to change an entry, edit its per-entry file and regenerate
`_toc.md`.

## Filename convention

Per-entry files match `^BD-\d+[a-z]*\.md$` (e.g., `BD-060.md`,
`BD-167b.md`). Three-or-more-digit BD-NNN with an OPTIONAL lowercase
suffix-letter run admitting the sub-entry forms `BD-167b.md` /
`BD-169b.md`.

## ID-extraction rule

The per-entry **filename is the ID**. For a header
`**BD-167b — <Title>**` the file is `BD-167b.md`. For a header carrying
a parenthetical qualifier — `**BD-195 (Code Red 3) — <Title>**` — the
file is `BD-195.md`: the parenthetical is TITLE TEXT, not part of the
ID (there is exactly one BD-195, so `BD-195.md` is unambiguous), and it
is preserved byte-faithfully in the entry body's bold-header line. The
ID is the captured `BD-\d+[a-z]*` group only.

## Entry contract

One BD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the entry's content span begins at
`**BD-NNN[suffix] — <Title>**`, followed by the `Type:` / `Status:` /
`Description:` (and optional `Blockers:` / `Unblocks:` / `File/Symbol:`
/ `Resolved:` / `Position:`) fields per the standard BACKLOG item
format (METHODOLOGY.md Part 7).

## Lifecycle states admitted

- `Open` — entry is active / not yet started.
- `Unblocked` — a pending-decision state between Open and Deferred
  (admitted as a canonical lifecycle state per BD-203).
- `Deferred` — deliberately postponed (user-authorized).
- `Resolved` — entry is closed; carries a `Resolved:` line.
- `Deprecated` — superseded / no longer pursued.
- `Cancelled` — abandoned without resolution.

Entries resolve **in place** by flipping `Status: Open` to
`Status: Resolved` and filling the `Resolved:` line — there is no
separate Resolved section.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP. There
is no `_v8-resolved-archive.md`: the former v8 summary-table rows
(BD-001..019) are real `BD-00N.md` per-entry files, not archived
history.

## Write authority

Writes are Pack-Chat authority (the pack-backlog tree is a pack-chat-only
directory per `pack-ops/PACK-AGENTS.md` § "pack-chat-only files and
directories"; agents edit it only when a caller scopes it in for an
explicit BD). After any entry edit, regenerate `_toc.md` via
`per_entry_regenerate_toc pack-backlog /backlog` before staging.
