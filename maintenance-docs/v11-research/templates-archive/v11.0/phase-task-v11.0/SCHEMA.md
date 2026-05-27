# Schema — `phase-task-v11.0` (phase task)

This document fixes the on-tracker representation of a phase task at
template version `phase-task-v11.0`. Phase tasks are the L2 work units
under a phase epic. Day-to-day, phase tasks are created
**programmatically** by Pack Chat / PM Chat at migration time or
when phase tasks are added to a phase. The `phase-task-skeleton`
option in `work-item.yml` exists as a rare-case fallback.

Reference: ARCHITECTURE-V3.3-DELTA.md §2.4 / §2.5 / §6.1 / §6.3 / §6.4
/ §6.5, IMPLEMENTATION-PLAN-ADDENDUM-4.md §2.1 / §2.2.

## 1. Identifier scheme

- Identifier: `phase-N.M` (lowercase, dot-separated; M is the integer
  task number from IMPLEMENTATION-PLAN.md's `#### N.M` heading).
- Uniqueness scope: per project. Stable across renames and reorders
  (the M is the task's birth-order ordinal, not a positional index).
- Identity owner: pack (IMPLEMENTATION-PLAN.md authoritative).
- Round-trip carrier: title prefix `Phase N.M — <task title>` plus
  body marker `<!-- pack-id: phase-N.M -->`.

## 2. Body marker trio

```
<!-- pack-id: phase-N.M -->
<!-- template_version: phase-task-v11.0 -->
<!-- pack-version: v11 -->
```

When created via `provider.create()` (the day-to-day path), the
markers are written directly with the resolved values. When created
via the rare `wi-type=phase-task-skeleton` form path, chat triage
computes M as the next available task number under phase N and
rewrites the markers.

## 3. Label family

| Label | Source | Notes |
|---|---|---|
| `phase-task` | chat / programmatic create | provenance; never removed |
| `phase-N` | chat / programmatic create | parent phase membership; never removed |
| `template:phase-task-v11.0` | chat / programmatic create | updated by `pack tracker update-templates` |
| `derived-from:TD-NNN` | chat (TD-promotion path 2) | optional; one or more |
| `status:<pending\|in-progress\|done\|deferred\|merged-into:phase-N\|superseded-by>` | chat | mirrors phase task state; see V3.3 §6.3 |

State mapping per V3.3 §6.3:

| Marker (flat-file) | Status label | Tracker state | `state_reason` |
|---|---|---|---|
| (no marker) | `status:pending` | open | — |
| 🚧 | `status:in-progress` | open | — |
| ✅ | `status:done` | closed | `completed` |
| ➡ | `status:deferred` | closed | `not_planned` |
| (execution note: merged into phase-N) | `status:merged-into:phase-N` | closed | `not_planned` |
| (execution note: superseded by) | `status:superseded-by` | closed | `not_planned` |

## 4. Body section grammar

```
<!-- pack-id: phase-N.M -->
<!-- template_version: phase-task-v11.0 -->
<!-- pack-version: v11 -->

## Problem / Goal / Success

<free text — required>

## Files created/modified

<one path per line — optional>

## Definition of done

<bulleted criteria — required>

## Dependencies

<one ID per line — optional; accepts phase-N, phase-N.M, TD-NNN>
```

Section headings are H2 (`##`). Order is fixed: Problem/Goal/Success,
Files, Definition of done, Dependencies. Reverse migration depends on
this order.

Dependencies grammar (per V3.3 §5.3): one ID per line. Each line is:

- `phase-N` — depends on the entire phase N being complete
- `phase-N.M` — depends on a specific task in another phase
- `TD-NNN` — depends on a TD entry

Each line becomes one `provider.link()` call with `kind="blocked-by"`
post-creation. Cycle-checking per V3.3 §5.5 / `tracker.toml [graph]
cycle_check_k`.

## 5. Sub-issue / hierarchy

Phase tasks are children of their phase epic (`phase-N`) via:
- **First-class sub-issue parent** when `hierarchy.supported = true`
  in capability flags (github supports this).
- **Label fallback** `parent:phase-N` otherwise.

Phase tasks may not be parented to BD/TD entries or to other phase
tasks — a phase task's parent is exactly one phase epic. Cross-phase
relationships are expressed via the Dependencies section, not parent/
child.

## 6. Reverse-emit grammar

Reverse migration emits the phase task as the v10 IMPLEMENTATION_PLAN.md
sub-heading + bulleted body:

```
#### N.M <task title>          (no marker if status:pending)
#### 🚧 N.M <task title>        (if status:in-progress)
#### ✅ N.M <task title>        (if status:done)
#### ➡ N.M <task title>         (if status:deferred)
#### N.M <task title>          (with execution note for merged-into / superseded-by)

- **Problem / Goal / Success:** <body Problem section content>
- **Files created/modified:**
  - <path>
  - ...
- **Definition of done:**
  - <bullet>
  - ...
- **Dependencies:** <one per line>
```

Execution notes for `status:merged-into:phase-N` or
`status:superseded-by` emit a separate paragraph after the bullets:

```
*This task was merged into phase-N.M on YYYY-MM-DD.*
*This task was superseded by phase-N.M on YYYY-MM-DD.*
```

`derived-from:TD-NNN` labels emit at the foot of the task body as an
HTML comment for round-trip preservation per V1 §6.0:

```
<!-- derived-from: TD-NNN, TD-NNN, ... -->
```

Tracker-only enrichment (reactions, comments, attachments) is
preserved in the reverse-migration sidecar per V1 §6.6.1.
