# Schema — `inbound-v11.0` (external bug / feature / pack-feedback)

This document fixes the on-tracker representation of an inbound entry
at template version `inbound-v11.0`. Inbound entries originate via the
`inbound.yml` form (V2 §4.3) and route to one of three downstream
paths based on Category: external bug, external feature request, or
upstream pack-feedback (which crosses the surface boundary to the
pack repo per V1 §7.5).

Reference: ARCHITECTURE.md §7.5 / §10, ARCHITECTURE-V2.md §4.3,
ARCHITECTURE-V3.3-DELTA.md §6.3 / §6.5, IMPLEMENTATION-PLAN.md
BD-064 + Addendum 4 §2.2.

## 1. Identifier scheme

- Inbound entries do not have a stable pack-side identifier prefix
  (no BD-NNN / TD-NNN). The GH issue number is the identifier.
- Round-trip carrier: GH issue number plus body marker
  `<!-- pack-id: PENDING -->` (which stays `PENDING` for external
  bugs and feature requests; pack-feedback entries get rewritten
  on the pack side after upstream receipt).

## 2. Body marker trio

```
<!-- pack-id: PENDING -->
<!-- template_version: inbound-v11.0 -->
<!-- pack-version: v11 -->
```

The form ships these markers verbatim; chat triage does not rewrite
them (no entry-type promotion happens for inbound — Category drives
labels, not identifier).

## 3. Label family

| Label | Source | When applied | Notes |
|---|---|---|---|
| `inbound` | form `labels:` key | intake | provenance; never removed |
| `needs-triage` | form `labels:` key | intake | removed at triage |
| `template:inbound-v11.0` | form `labels:` key | intake | updated by `pack tracker update-templates` |
| `external` | chat triage | when Category ∈ {bug, feature-request} | provenance; never removed |
| `pack-feedback` | chat triage | when Category starts with `pack-feedback-` | provenance; never removed |
| `type:bug` | chat triage | when Category=bug | never |
| `type:feature` | chat triage | when Category=feature-request | never |
| `pf-category:<workflow\|prompt\|agent-perf\|friction\|open-question>` | chat triage | when Category=pack-feedback-* | never |
| `status:open` / `status:resolved` / `status:cancelled` | chat | mirrors triage state | when state changes |

State mapping is the same as BD/TD per V3.3 §6.3.

## 4. Body section grammar

```
<!-- pack-id: PENDING -->
<!-- template_version: inbound-v11.0 -->
<!-- pack-version: v11 -->

## Observation / steps to reproduce

<free text — required>

## Context (project state, agent, files, environment)

<free text — optional>

## Expected behavior (bug only)

<free text — optional>

## Actual behavior (bug only)

<free text — optional>

## Pack version (pack-feedback only)

<one line — present iff Category starts with `pack-feedback-`>

## Project identifier (pack-feedback only)

<one line — present iff Category starts with `pack-feedback-`>
```

Section headings are H2 (`##`). Optional sections may be omitted; the
order of present sections is fixed.

## 5. Routing semantics

| Category | Routing |
|---|---|
| `bug` | Stays on the surface where it was filed. Triaged into the project's bug queue. |
| `feature-request` | Stays on the surface where it was filed. Triaged into the project's feature queue. |
| `pack-feedback-*` (5 sub-types) | Filed on either surface; client-side instances are mirrored upstream to the pack repo via V1 §7.5 (Pack Chat creates a pack-side inbound issue with the same body and a back-reference link). |

The chat performs the upstream mirroring at triage time — it is not
automatic on intake. The user can review the pack-feedback report
locally before the upstream copy is created.

## 6. Reverse-emit grammar

Inbound entries do not appear in v10 BACKLOG.md. They are external
intake; reverse migration drops them entirely from the markdown
mirrors and preserves them only in the tracker. This is intentional:
v10 had no way to represent inbound, so no reverse target exists.

Tracker-only state (the inbound issue itself, comments, reactions,
labels) is preserved by virtue of the issue remaining in the tracker
across migrations. The reverse-migration sidecar (V1 §6.6.1) does not
emit inbound issues.

## 7. `pack-id: PENDING` contract

The `<!-- pack-id: PENDING -->` body marker is permanent for inbound
entries. Unlike BD/TD entries (where chat triage rewrites `PENDING`
to `BD-NNN` / `TD-NNN`), inbound entries have no pack-side namespace
identity — the GH issue number is their identifier. The chat
explicitly does NOT rewrite `PENDING` for entries with `inbound` /
`external` / `pack-feedback` labels.

Forward migration (BD-065) does not write inbound entries to flat
files (the parser reads only BACKLOG.md, which by definition holds
no inbound entries). Reverse migration (BD-067) excludes inbound
entries from the BACKLOG.md regen for the same reason. Mirror
regen never sees an inbound entry's `PENDING` marker; the contract
holds without explicit handling.

This is the v11.0 design (PACK-REVIEW-BD060-070 Finding #8 closure).
