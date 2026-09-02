# Stream contract — project-groupings

> **Audience:** agents + PM Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / any other doc. `_intro.md`
> is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Client-immutable: do not
edit this file in a client project — updates arrive only on a pack
version bump.

## Stream identity

- Stream name: `project-groupings`
- Pack version that minted this contract: v11.0
- Directory: `docs/project/groupings/`

## Source of truth — flat-file (no monolith)

**Flat-file mode (the sole supported mode).** The per-entry tree at
`docs/project/groupings/` (plus its generated
`docs/project/groupings/_toc.md` index) is the SOLE source of truth and
readable form — no monolithic mirror; do not recreate one; no
GROUPINGS.md, ever. Validation runs against the tree.

## Filename convention

Per-entry files match `^GRP-\d{3,}\.md$`: exactly three digits,
zero-padded, through GRP-999; from GRP-1000 the number grows unpadded
(no leading zeros). Numbering: read the tree, increment the highest
existing number; real groupings start at GRP-001; reservation lists are
not authoritative. A rename is a new grouping plus a deletion — IDs are
never reused for different content.

## ID-extraction rule

The per-entry **filename is the ID**: the entry whose bold-header reads
`**GRP-NNN — <Title>**` lives in the file named GRP-NNN plus the `.md`
extension. The title is free text after the em-dash — never between the
ID and the em-dash — and is preserved byte-faithfully.

## Entry contract

One grouping per file — a pure-structure list of member phases. The
first line is an HTML-comment back-pointer ABOVE the bold-header; the
content span begins at `**GRP-NNN — <Title>**`, followed by the entry
fields per the schema below. The serialization is closed and
byte-canonical: fields in the declared `field-order`; plain
`Field: value` lines (no bold labels, no bullets); exactly one space
after each field colon; no trailing whitespace on any line; no blank
lines between fields; the `Member-phases:` value lists members ascending
by phase number with the exact `, ` separator and no duplicates; the
file ends with a single newline. Any two writers of the same logical
grouping produce byte-identical files. No free-floating prose:
`Doc-links:` and `Comment:` are the only annotation carriers —
single-line, opaque to tooling, byte-preserved, never split or
interpreted.

## Entry schema (form-family)

- entry-type: grouping
- core-fields: ID Kind Member-phases
- kind-enum: user-journey ambient-feature foundational-batch refactor-cluster release-package shared-feature architectural-pattern tech-debt-removal bug-fix unassigned
- optional-fields: "Single-member exception" Doc-links Comment
- exception-field: "Single-member exception"
- member-ref-pattern: phase-N
- min-members: 2
- field-order: Entry-Type Kind Member-phases "Single-member exception" Doc-links Comment
- reserved-id: GRP-000

## Kind enumeration

`Kind:` carries exactly one `kind-enum` slug — the grouping's own
classification, never derived from members and never encoded in the
title. The enum is FIXED: `unassigned` is the catch-all for a grouping
that fits no other Kind (and the pinned Kind of the reserved GRP-000);
the enum changes only on a pack version bump. Kind encodes no execution
order.

## Membership rules

- Members are PHASES only: `Member-phases:` admits `phase-N` tokens
  exclusively — no parts, tasks, or other entry IDs (a part belongs to
  its parent phase by containment).
- Minimum 2 members. Exactly 1 member requires the
  `Single-member exception: <rationale>` field — present if and only if
  the member count is 1. Zero members is never valid. GRP-000 is the
  sole exception to all three rules (see the reserved section).
- No duplicate members; canonical ascending order.
- Every member token must resolve to a
  `docs/project/implementation-plan/` phase entry; a dangling reference
  fails validation.
- A phase may belong to any number of groupings, EXCEPT that membership
  in GRP-000 is exclusive: a phase in GRP-000 and in any other grouping
  fails validation.
- Dissolution = delete the file. Dropping below 2 members without the
  exception field fails validation; nothing auto-edits membership.

## Reserved grouping — GRP-000

The schema's `reserved-id:` names ONE reserved grouping: GRP-000 is the
declared-ungrouped ledger — its member list IS the durable record of
phases deliberately ruled "stays ungrouped."

- Pinned bytes: the header is `**GRP-000 — Ungrouped (declared)**`; its
  Kind is `unassigned`.
- GRP-000 is legal with zero or one member (`Member-phases:` present,
  value may be empty); the `Single-member exception:` field is FORBIDDEN
  on GRP-000 at any member count.
- Created on first use, never pre-created — absence means zero rulings.
- Real-grouping numbering starts at GRP-001; GRP-000 is never re-minted.
- A per-phase rationale, when wanted, lives in GRP-000's own `Comment:`
  line — never in the phase file.
- Tooling treats GRP-000 as reserved: it joins no status rollup, no
  derived ordering, and no affinity placement, and it is refused as a
  relational query argument; its membership answers exactly one
  question — which phases are declared ungrouped.

## Derived status and target

A grouping carries NO lifecycle state of its own: it is present or
absent, and the grouping file stores no status and no target. Status and
target are DERIVED at read time from the member phases' `Status:` and
`Target:` fields (the implementation-plan tree is the source; see
`docs/project/implementation-plan/_rules.md` `## Target semantics`) and
are never written back. A grouping's derived target is the maximum over
its declaring members' targets on the `target-enum` ordinal scale; the
declarer set is exactly the members that are non-done and non-superseded
and carry a present, legal `Target:` — done and superseded members never
declare (spent claims) — while a present-but-illegal `Target:` on any
non-superseded member (done included) makes the derived target unknown.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md`. Write procedure: author / edit a per-entry
grouping file directly, in the closed serialization (sort members
ascending, emit the fixed field order, end with a single newline). After
any entry edit, regenerate `_toc.md` before staging by running
`bash scripts/per-entry-regen.sh groupings` from the project root
(`bash scripts/per-entry-regen.sh --check` reports drift without
writing). Never hand-edit
`_toc.md` (derived index). `_toc.md` axis: entries grouped by Kind
(alphabetical by slug), IDs ascending within each group; one row per
entry, exactly: `- GRP-NNN — <Title> (phases: N)` where N is the member
count.
