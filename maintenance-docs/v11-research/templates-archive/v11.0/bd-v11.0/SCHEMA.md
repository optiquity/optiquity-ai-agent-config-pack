# Schema — `bd-v11.0` (pack-development backlog item)

**SCOPE: PACK-INTERNAL.** This SCHEMA documents the pack-development
backlog entity (BD-NNN) and applies to the pack repository only. BD
entries are NOT a client-project concept; client projects use TD-NNN
(see `../td-v11.0/SCHEMA.md`) for technical-debt items. This file is
preserved here as the on-tracker representation contract for the pack
repo's own backlog and is consumed by pack-internal migration scripts.

This document fixes the on-tracker representation of a BD entry at
template version `bd-v11.0`. The migration scripts (forward and
reverse) and `pack tracker update-templates` (BD-069) read this file
to translate between the v10 BACKLOG.md grammar and the GH issue
representation.

Reference: ARCHITECTURE.md §4.1, ARCHITECTURE-V2.md §4.2,
ARCHITECTURE-V3.3-DELTA.md §6.3 / §6.4 / §6.5, IMPLEMENTATION-PLAN.md
BD-064 + Addendum 4 §2.2.

## 1. Identifier scheme

- Identifier: `BD-NNN`, three-digit zero-padded counter, owned by the
  pack repository.
- Uniqueness scope: per pack repo. Counter advances across the entire
  pack history; never reused after delete.
- Identity owner: pack (BACKLOG.md authoritative; tracker is a mirror).
- Round-trip carrier: title prefix (`BD-NNN: <title>`) plus body
  HTML-comment marker `<!-- pack-id: BD-NNN -->`.

## 2. Body marker trio

Every BD issue body opens with three HTML comments emitted by the
form's trailing `markdown` block (chat-triage rewrites the
`template_version` from the coarse `work-item-v11.0` to the specific
`bd-v11.0` after the `wi-type=bd` choice is processed):

```
<!-- pack-id: BD-NNN -->
<!-- template_version: bd-v11.0 -->
<!-- pack-version: v11 -->
```

- `pack-id`: the assigned BD identifier. Set to `PENDING` at form
  submission; chat triage rewrites to `BD-NNN`.
- `template_version`: the entry-type schema version. `bd-v11.0` at
  this archive version. Chat triage rewrites from coarse
  `work-item-v11.0` after dropdown processing.
- `pack-version`: the major pack version that authored the form. `v11`
  for any v11.x form.

## 3. Label family

| Label | Source | When applied | When removed |
|---|---|---|---|
| `work-item` | form `labels:` key | intake | never (provenance) |
| `needs-triage` | form `labels:` key | intake | at triage |
| `template:work-item-v11.0` | form `labels:` key | intake | at triage (replaced by `template:bd-v11.0`) |
| `template:bd-v11.0` | chat triage | after `wi-type=bd` | by `pack tracker update-templates` |
| `bd-entry` | chat triage | at triage | never (provenance) |
| `type:<feat\|fix\|refactor\|docs\|chore\|infra>` | chat triage | at triage from `wi-kind` | never |
| `status:open` / `status:unblocked` / `status:resolved` / `status:cancelled` / `status:deprecated` | chat triage | mirrors `wi-status`; updated on state change | when status flips |
| `promoted-to:phase-N` or `promoted-to:phase-N.M` | chat (TD-promotion path) | when BD is promoted into a phase | never |
| `derived-from:TD-NNN` | chat | optional | never |

State mapping per V3.3 §6.3:

| `Status:` | tracker state | `state_reason` |
|---|---|---|
| Open | open | — |
| Unblocked | open | — |
| Resolved (direct) | closed | `completed` |
| Resolved (promotion) | closed | `completed` (+ `promoted-to:*`) |
| Cancelled | closed | `not_planned` |
| Deprecated | closed | `not_planned` |

## 4. Body section grammar

The issue body after the marker trio mirrors the v10 BACKLOG.md entry:

```
<!-- pack-id: BD-NNN -->
<!-- template_version: bd-v11.0 -->
<!-- pack-version: v11 -->

## Description

<free text>

## Context

<free text — optional>

## Resolution

<free text — present only when status flipped to Resolved>
```

Section headings are H2 (`##`). Order is fixed: Description, Context,
Resolution. Reverse migration depends on this order.

The `Type:`, `Status:`, `Blockers:`, `Unblocks:`, and `File/Symbol:`
fields from v10 are mapped to labels and link relationships, not to
body sections:

- `Type:` → `type:<kind>` label + the issue's GH `issueType` field.
- `Status:` → `status:*` label + GH state.
- `Blockers:` → first-class `blocked-by` dependency relationships
  (V1 §2.7 + BD-111). Each line of the form `BD-NNN`, `TD-NNN`,
  `phase-N`, or `phase-N.M` becomes one `provider.link()` call.
- `Unblocks:` → first-class `blocks` relationships (inverse of
  Blockers across the data set; not authored independently).
- `File/Symbol:` → `file-symbol:<value>` label, kept short for label
  budget.

## 5. Reverse-emit grammar

Reverse migration (V1 §6.5) reconstructs the v10 BACKLOG.md entry from
the issue:

```
**BD-NNN — <title>**
Type: <type:* label value>
Status: <Status from status:* label, capitalized>
Blockers: <one per line, from blocked-by edges>
Unblocks: <one per line, from blocks edges>
File/Symbol: <file-symbol:* label value>
Description: <body Description section>
Context: <body Context section, if present>
Resolution: <body Resolution section, if present>
```

The `**BD-NNN — <title>**` line uses the title prefix and free-text
title; the `pack-id` body marker is the authoritative source for the
identifier (the title prefix is a convenience copy that may drift if
the user edited the title manually — the chat reconciles).

Tracker-only enrichment (reactions, attachments, comments other than
link markers) is preserved in the reverse-migration sidecar per
V1 §6.6.1.
