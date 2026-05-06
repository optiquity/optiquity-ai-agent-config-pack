# Schema — `td-v11.0` (project technical-debt item)

This document fixes the on-tracker representation of a TD entry at
template version `td-v11.0`. Structurally near-identical to
`bd-v11.0`; the differences are in the identifier prefix, the optional
`scope:*` and `severity:*` labels, and the v10 deferral-comment grammar.

Reference: ARCHITECTURE.md §4.1, ARCHITECTURE-V2.md §4.2,
ARCHITECTURE-V3.3-DELTA.md §6.3 / §6.4 / §6.5, METHODOLOGY.md
"Deferral comments and BACKLOG hygiene" section.

## 1. Identifier scheme

- Identifier: `TD-NNN`, three-digit zero-padded counter, owned by the
  client project (not the pack).
- Uniqueness scope: per project (client repo). Counter is per-project;
  two different projects may both have a `TD-001`.
- Identity owner: project (BACKLOG.md authoritative; tracker is a mirror).
- Round-trip carrier: title prefix (`TD-NNN: <title>`) plus body
  HTML-comment marker `<!-- pack-id: TD-NNN -->`.

## 2. Body marker trio

```
<!-- pack-id: TD-NNN -->
<!-- template_version: td-v11.0 -->
<!-- pack-version: v11 -->
```

Same intake-then-triage rewrite as BD: `pack-id: PENDING` and
`template_version: work-item-v11.0` at submission; chat triage
rewrites both based on `wi-type=td`.

## 3. Label family

| Label | Source | When applied | When removed |
|---|---|---|---|
| `work-item` | form `labels:` key | intake | never |
| `needs-triage` | form `labels:` key | intake | at triage |
| `template:work-item-v11.0` | form `labels:` key | intake | at triage (replaced by `template:td-v11.0`) |
| `template:td-v11.0` | chat triage | after `wi-type=td` | by `pack tracker update-templates` |
| `td-entry` | chat triage | at triage | never |
| `type:<feat\|fix\|refactor\|docs\|chore\|infra>` | chat triage from `wi-kind` | at triage | never |
| `scope:<phase-N\|dependency\|feature\|perf\|version>` | chat triage from `wi-td-scope` | at triage | never |
| `severity:<critical\|functional\|polish>` | chat triage from `wi-td-severity` | at triage (KNOWN GAP variant only) | never |
| `status:*` | chat triage from `wi-status` | at triage; updated on state change | when status flips |
| `promoted-to:phase-N` or `promoted-to:phase-N.M` | chat (TD-promotion path) | when TD is promoted into a phase | never |

State mapping per V3.3 §6.3 (identical to BD):

| `Status:` | tracker state | `state_reason` |
|---|---|---|
| Open | open | — |
| Unblocked | open | — |
| Resolved (direct) | closed | `completed` |
| Resolved (promotion) | closed | `completed` (+ `promoted-to:*`) |
| Cancelled | closed | `not_planned` |
| Deprecated | closed | `not_planned` |

## 4. Body section grammar

```
<!-- pack-id: TD-NNN -->
<!-- template_version: td-v11.0 -->
<!-- pack-version: v11 -->

## Description

<free text>

## Context

<free text — optional>

## Resolution

<free text — present only when status flipped to Resolved>
```

Mapping is the same as BD. Differences:
- Identifier prefix `TD-` in the title.
- `scope:*` label is required for TD entries (per
  METHODOLOGY.md "Deferral comments" section's valid scope list).
- `severity:*` label is present iff this TD originated as a
  KNOWN GAP comment per METHODOLOGY.md.

## 5. v10 deferral-comment correspondence

Project source-code deferral comments map to TD entries one-to-one
(the inbound side of the comment-to-tracker pipeline). Per
METHODOLOGY.md, three deferral comment types are recognized:

| Comment type | TD `Type` | TD labels | Notes |
|---|---|---|---|
| `// TODO(scope): TD-NNN — title` | TODO | `scope:<scope>` | `<scope>` ∈ phase-N, dependency, feature, perf, version |
| `// KNOWN GAP(severity): TD-NNN — title` | KNOWN GAP | `scope:*` (required), `severity:<severity>` | `<severity>` ∈ critical, functional, polish |
| `// VERIFY(source): TD-NNN — title` | VERIFY | `scope:dependency` (default) | `<source>` is the external authority being verified |

The `TD-TBD` placeholder used at deferral-write time is rewritten to
`TD-NNN` by the chat at triage when the TD is registered.

## 6. Reverse-emit grammar

```
**TD-NNN — <title>**
Type: <TODO|KNOWN GAP|VERIFY>
Status: <Status from status:* label, capitalized>
Scope: <from scope:* label>
Severity: <from severity:* label, if present>
Source: <from VERIFY's source token, if present — kept in body Context>
Blockers: <one per line, from blocked-by edges>
Unblocks: <one per line, from blocks edges>
File/Symbol: <file-symbol:* label value>
Description: <body Description section>
Context: <body Context section, if present>
Resolution: <body Resolution section, if present>
```

Tracker-only enrichment is preserved in the reverse-migration sidecar
per V1 §6.6.1.
