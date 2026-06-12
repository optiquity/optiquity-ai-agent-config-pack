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

## Source of truth — mode-dependent (no monolith in either mode)

The stream operates in one of two modes, read from the LOCAL pack
`tracker.toml` (`[mode] state` + `[migration] forward_complete`;
absent file = flat-file). Tracker mode is a per-checkout LOCAL
opt-in: `tracker.toml` is gitignored and never committed, so the
repo's COMMITTED state is always flat-file — every checkout and
every version bump ships flat-file — and a local opt-in is sticky
across pulls and version bumps by construction.

**Flat-file mode (default).** The per-entry tree at `/backlog/` (plus
its generated `/backlog/_toc.md` index) is the SOLE source of truth
and readable form. There is no monolithic mirror — the former
`pack-ops/BACKLOG.md` was deleted at BD-203; do not recreate it. GH
Issues are IGNORED by all tooling in this mode; inbound-feedback
issues are a human/PM triage channel only. Validation runs against
the tree.

**Tracker mode (`state = "tracker"` + `forward_complete = true`,
local).** The tracker is the SOLE source of truth on the opted-in
checkout. Entry identity is the `<!-- pack-id: BD-NNN -->` body
marker — never an issue number. The per-entry tree + `_toc.md` are a
REGENERATED MIRROR of tracker state: read-stable, never hand-written.
A hand-edit to any `BD-NNN.md` or to `_toc.md` is INVALID and is
OVERWRITTEN WITHOUT DETECTION at the next tree rebuild — the write
direction is one-way (tracker → tree, always); this is a
regeneration, NOT a sync. There is still no monolith, ever. `_toc.md`
regenerates on EVERY tree materialization.

**Published tree + single writing authority.** Because tracker mode
is local, the COMMITTED tree (+ `_toc.md`) remains the published
flat-file SSOT for every non-opted checkout; the (single)
tracker-mode maintainer keeps it current by running
`pack tracker tree-rebuild` and committing the regenerated tree
through the normal commit gates — the COMMIT is the publication act.
While the maintainer's local state is tracker mode, the committed
tree is a PUBLISHED MIRROR of the tracker even though the repo's
committed state is formally flat-file. A second writer must NOT
(a) hand-edit `/backlog/` entry files or `_toc.md` and commit — the
edit is silently CLOBBERED at the maintainer's next tree-rebuild
publication (the tracker, not the committed tree, is what the
maintainer's rebuild reads); nor (b) opt in to tracker mode on a
second machine and publish concurrently — two publishers race on the
committed tree. Entry-state changes route through the tracker (GH
Issues) or through the maintainer. If the single-writer assumption
ever breaks, the safe degradation is `pack tracker disable` back to
flat-file, where the committed tree is directly writable again.

## Filename convention

Per-entry files match `^BD-\d+\.md$` (e.g., `BD-060.md`, `BD-167.md`).
Three-or-more-digit BD-NNN; NO letter suffix (canonical per BD-211 — a
sub-part is an in-body section, not a suffixed entry).

## ID-extraction rule

The per-entry **filename is the ID**. For a header `**BD-167 — <Title>**`
the file is `BD-167.md`. A parenthetical qualifier, if present, is TITLE
TEXT after the em-dash — never between the ID and the em-dash; it is
preserved byte-faithfully in the entry body's bold-header line. The ID
is the captured `BD-\d+` group only (canonical per BD-211 — no letter
suffix, no pre-em-dash parenthetical).

## Entry contract

One BD entry per file. The first line is an HTML-comment back-pointer
ABOVE the bold-header; the entry's content span begins at
`**BD-NNN — <Title>**`, followed by the `Type:` / `Status:` /
`Description:` fields per the standard BACKLOG item format
(METHODOLOGY.md Part 7).

**Field-faithful — the contract does not gate on a field allowlist.**
The Mode-2→3 migrator is FIELD-FAITHFUL: it carries every top-level
entry field VERBATIM (the entry body is preserved byte-for-byte as the
`pack-entry-body-gz64` blob), so the contract does NOT depend on
enumerating which fields are "allowed". METHODOLOGY.md Part 7 (the
template SSOT) enumerates the COMMON fields (`Type:` / `Status:` /
`Blockers:` / `Unblocks:` / `File/Symbol:` / `Description:` /
`Context:` / `Resolution:`); EXTENSION fields (`Target:`, `Position:`,
etc.) are ADMITTED and PRESERVED. A future BD adding a field needs no
contract change here — the carrier carries whatever bytes the entry
body has.

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
explicit BD). The write PROCEDURE is mode-dependent (mode per
§ "Source of truth — mode-dependent (no monolith in either mode)"):

- **Flat-file mode:** edit the per-entry file directly; entries
  resolve in place. After any entry edit, regenerate `_toc.md` via
  `per_entry_regenerate_toc pack-backlog /backlog` before staging.
  Never hand-edit `_toc.md` (derived index).
- **Tracker mode:** ALL entry creates / edits / status flips go
  through the tracker tooling (`pack tracker` verbs /
  `tracker_edit_entry`), which recomposes the H2 projection + the
  `pack-entry-body-gz64` blob atomically. NEVER edit a `BD-NNN.md`
  file or `_toc.md` by hand — the edit is overwritten without
  detection at the next rebuild. Direct GH-web edits are NOT a write
  path: body edits are blocked loudly by the divergence comparator
  at the next rebuild (`--force` = blob-wins); label/state-only
  flips are a coherence defect detected by `pack tracker doctor` and
  at rebuild. After any tracker write batch — and ALWAYS before
  committing tree state — run `pack tracker tree-rebuild`, then
  stage the regenerated tree + `_toc.md` through the normal commit
  gates. The local `tracker.toml` and `.pack-tracker/` are NEVER
  staged (gitignored local state).
