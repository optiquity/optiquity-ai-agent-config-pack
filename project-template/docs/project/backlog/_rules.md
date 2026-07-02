# Stream contract — project-backlog

> **Audience:** agents + PM Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / any other doc. `_intro.md`
> is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Client-immutable: do not
edit this file in a client project — updates arrive only on a pack
version bump; the client's `verify-immutable.sh` enforces this.

## Stream identity

- Stream name: `project-backlog`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/backlog/`

## Source of truth — flat-file (no monolith)

**Flat-file mode (the sole supported mode).** The per-entry tree at
`docs/project/backlog/` (plus its generated `docs/project/backlog/_toc.md`
index) is the SOLE source of truth and readable form — no monolithic
mirror; do not recreate one. Validation runs against the tree.

## Filename convention

Per-entry files match `^TD-\d+\.md$` (e.g., `TD-001.md`). Three-digit
zero-padded TD-NNN.

## ID-extraction rule

The per-entry **filename is the ID**: for a header `**TD-NNN — <Title>**`
the file is `TD-NNN.md`. A parenthetical qualifier, if present, is TITLE
TEXT after the em-dash — never between the ID and the em-dash — and is
preserved byte-faithfully in the entry body's bold-header line.

## Entry contract

One TD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the content span begins at `**TD-NNN — <Title>**`,
followed by the entry fields per the schema below.

## Entry schema (form-family)

- entry-type: td
- core-fields: ID Marker Status Blockers Unblocks File/Symbol Description Context
- marker-enum: TODO "KNOWN GAP" VERIFY
- payload-by-marker: TODO=Scope "KNOWN GAP"=Severity VERIFY=Verify-Source
- scope-enum: phase-N dependency feature perf version
- severity-enum: critical functional polish
- verify-source: open-string
- status-enum: Open Unblocked Deferred Resolved Deprecated Cancelled
- resolved-requires: Resolution
- title-template: phase-N

The enforcement validates, per `td` entry: Entry-Type present + correct;
all core-fields present; Marker ∈ marker-enum; the Marker-keyed payload
field present + (for Scope/Severity) enum-valid; Status ∈ status-enum;
Resolution present iff Status=Resolved. `scope-enum`'s `phase-N` is the
templated pattern `phase-\d+` (matched literally OR as an enum member);
`verify-source` is presence-checked open-string, not enum-validated.

## Lifecycle states admitted

- `Open` — entry is active / not yet started.
- `Unblocked` — a pending-decision state between Open and Deferred.
- `Deferred` — deliberately postponed (user-authorized).
- `Resolved` — entry is closed; carries a `Resolution:` line.
- `Deprecated` — superseded / no longer pursued.
- `Cancelled` — abandoned without resolution.

Entries resolve **in place** by flipping `Status: Open` to
`Status: Resolved` and filling the `Resolution:` line — no separate
Resolved section.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 7. Write procedure: edit the per-entry
file directly; entries resolve in place. After any entry edit,
regenerate `_toc.md` before staging. Never hand-edit `_toc.md`
(derived index).
