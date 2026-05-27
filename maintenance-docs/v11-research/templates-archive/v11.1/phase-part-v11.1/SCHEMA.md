# Schema — `phase-part-v11.1` (phase part)

This document fixes the on-tracker representation of a phase part at
template version `phase-part-v11.1`. Phase parts are sub-issue entities
introduced by mid-work phase expansion. A Part groups one or
more phase tasks under a single parent phase epic, at sub-issue depth 2
(phase epic at depth 1; tasks at depth 3 under their Part).

Parts are NEVER created at phase-birth time — a phase begins with zero
Parts. Parts are introduced by the `pack phase split` or
`pack tracker phase split` verb when a phase needs to be expanded
mid-work. Once introduced, Parts cannot be deleted nor collapsed
(no-collapse rule).

## 1. Identifier scheme

- Identifier: `Phase-N.Part-x` per the canonical grammar.
  - `Phase-N` — atom: integer phase number matching `[1-9][0-9]*`
    (no leading zero except `0` for v10-compat). N is the phase's
    birth-order ordinal; immutable per INV-1.
  - `Part-x` — atom: single lowercase ASCII letter matching `[a-z]`.
    Up to 26 Parts per phase (alphabet exhaustion is an architect-pass
    review trigger, not a default case).
- Uniqueness scope: per project, per phase. The pair `(N, x)` is unique
  across all Parts.
- Identity owner: pack (`pack phase split` and
  `pack tracker phase split` verbs).
- Round-trip carrier: title prefix `Phase N.Part x — <part title>`
  plus body marker `<!-- pack-id: phase-N.Part-x -->`.

**Prohibited forms**:
- Empty separator (`Phase-2..Part-a`): REJECTED. The grammar uses a
  single `.` separator; null-Part task forms skip the segment ENTIRELY.
- Lowercase `phase` / `part`: REJECTED. The grammar uses capitalized
  atoms (matches METHODOLOGY's prose-form `Phase N` / `Part a`).
- Numeric Part identifier (`Phase-7.Part-3`): REJECTED. Numeric Parts
  would collide with the legacy `phase-N.M` task convention.

## 2. Body marker trio

```
<!-- pack-id: phase-N.Part-x -->
<!-- template_version: phase-part-v11.1 -->
<!-- pack-version: v11 -->
```

The trio parallels the `phase-epic-v11.0` and `phase-task-v11.0` body
marker trios (same three marker types in the same order). All three
markers are REQUIRED on every phase-part-v11.1 entity. Parser/emitter
(`tracker-phase-part.sh`) validates the trio at read and write time.

When created via `provider.create()` (the day-to-day path triggered by
`pack tracker phase split`), the markers are written directly with the
resolved values. When created via the rare `wi-type=phase-part-skeleton`
form path (the form admits an additional wi-type option for
phase-parts), chat triage rewrites the markers from intake placeholders
to the specific values based on `wi-phase-number` + `wi-part-letter`
inputs.

## 3. Label family

Parts use the following labels. No new label namespace is introduced by
`phase-part-v11.1`; the families parallel `phase-task-v11.0`.

| Label | Source | Notes |
|---|---|---|
| `phase-part` | chat / programmatic create | provenance; never removed |
| `phase-N` | chat / programmatic create | parent phase membership; never removed |
| `template:phase-part-v11.1` | chat / programmatic create | updated by `pack tracker update-templates` |
| `status:<pending\|in-progress\|done\|deferred>` | chat / programmatic | mirrors Part state per §4 below |

**Excluded labels** (per the lifecycle invariant below):
- `status:merged-into:phase-N` — Parts cannot be merged into another
  Part (lifecycle merge complexity is reserved for the phase epic).
- `status:superseded-by:phase-N.M` (or v2 form) — Parts cannot supersede
  another Part. Same rationale.
- `status:cancelled` — the `cancelled` state extension applies to
  `phase-task-v11.0` only. Parts do not have a cancelled state; an
  unused Part exits via `status:deferred`.
- `derived-from:TD-NNN` — Parts are not derived from TD entries; the
  TD-promotion paths (per the TD-promotion carrier matrix in
  `../v11.0/phase-epic-v11.0/SCHEMA.md` and
  `../v11.0/phase-task-v11.0/SCHEMA.md`) target phase-epic (path 1) and
  phase-task (path 2), not phase-part.

## 4. State mapping

Restrictive taxonomy: four states only (LOAD-BEARING).

| Status label | Tracker state | `state_reason` | Semantic meaning |
|---|---|---|---|
| `status:pending` | open | — | Part declared but no task started |
| `status:in-progress` | open | — | At least one task in this Part is in-progress |
| `status:done` | closed | `completed` | All tasks in this Part are closed-completed |
| `status:deferred` | closed | `not_planned` | Part deferred mid-work; member tasks stay assigned (re-parenting forbidden per supersede-only rule). Trigger: all member tasks reach a terminal state but not all done. |

**Lifecycle invariant**:
- Parts are CREATED via mid-work expansion (`pack phase split` /
  `pack tracker phase split`). They cannot be created at phase-birth
  time (a phase begins with zero Parts per §12.12 invariant).
- Parts cannot be deleted nor collapsed. Collapse is REJECTED as
  anti-pattern. Deletion would conflict with the no-collapse rule.
- Empty Parts are FORBIDDEN at creation. Every Part must contain at
  least one task as a sub-issue child at creation time.
- Mid-life task re-parenting between Parts is FORBIDDEN — use
  `pack task supersede` instead.
- Deferral is the only "exit" path for an unused Part (mark
  `status:deferred`).

## 5. Body section grammar

The Part body contains a brief Goal, a Prerequisites section listing
upstream IDs, and an optional informational Member tasks section.

```
<!-- pack-id: phase-N.Part-x -->
<!-- template_version: phase-part-v11.1 -->
<!-- pack-version: v11 -->

## Goal

<free text — required; describes what work this Part groups together
and why it was carved out mid-phase>

## Prerequisites

<one ID per line — optional; accepts phase-N, Phase-N.Part-x,
Phase-N.Task-M, Phase-N.Part-x.Task-M, TD-NNN>

## Member tasks

<bullet list of member task IDs — optional; INFORMATIONAL only>
```

Section headings are H2 (`##`). Order is FIXED: Goal, Prerequisites,
Member tasks. Parser/emitter (`tracker-phase-part.sh`) enforces section
order; reverse migration depends on this order.

**Prerequisites grammar** (parallels `phase-task-v11.0` Dependencies
grammar; the grammar admits the additional Part-id forms):

- `phase-N` — depends on the entire phase N being complete
- `Phase-N.Part-x` — depends on a specific Part in another phase
- `Phase-N.Task-M` — depends on a specific task (null-Part task
  identifier per §1)
- `Phase-N.Part-x.Task-M` — depends on a specific Part-scoped task
- `phase-N.M` — legacy task identifier (continues to resolve via the
  backward-compat shim)
- `TD-NNN` — depends on a TD entry

Each line becomes one `provider.link()` call with `kind="blocked-by"`
post-creation. Cycle-checking per V3.3 §5.5 / `tracker.toml [graph]
cycle_check_k`.

**Member tasks section is INFORMATIONAL, not authoritative.** The
authoritative parent-child relationship between a Part and its
member tasks is via sub-issue parentage (see §6 below) — the Part is
the sub-issue parent of its member tasks. The body section is a
human-readable convenience that round-trips through reverse migration;
it does NOT define Part membership.

## 6. Sub-issue / hierarchy

Phase parts are children of their phase epic (`phase-N`) via:
- **First-class sub-issue parent** when `hierarchy.supported = true`
  in the backend's capability flags (github supports this; V1 §2.7.2).
- **Label fallback** `parent:phase-N` on the Part otherwise (V3.2 §2.7;
  fallback extension TBD).

Phase parts may not be parented to phase tasks —
a Part's parent is exactly one phase epic. Cross-phase relationships
are expressed via the Prerequisites section, not parent/child.

Phase parts are PARENTS of phase tasks at sub-issue depth 3 (phase
epic at depth 1; phase parts at depth 2; phase tasks at depth 3).
Re-parentage from phase-epic to phase-part is the responsibility of
`pack tracker phase split`; it uses the existing
`provider_sub_issue_unlink` + `provider_sub_issue_create` op pair.

Sub-issue depth cap is 8 levels per EXTERNAL-RESEARCH.md (V1 §2.7.2);
Part membership (depth 3) is well within the cap. 100 children per
parent; 1 parent per child — both caps preserved.

## 7. Reverse-emit grammar

**TBD — defined in `tracker-migrate-reverse.sh`.** Reverse-emit grammar
for phase-part-v11.1 is not yet specified at this archive cut; the
first reverse-migration of a Part-aware project will exercise the
grammar and feed it back into this SCHEMA via `tracker-migrate-reverse.sh`.

Anticipated shape (subject to design): Parts emit as H3 sub-sections
inside `phase-N.md` per the INLINE rule (no per-Part per-entry file).
H3 heading carries the Part identifier and title; H4 task headings
under the H3 belong to that Part.

```
### Part a — <part title>

<Goal section content>

#### N.M <task title>          (H4 task headers per phase-task-v11.0)
- ...
```

The H3 heading + H4 grouping IS the round-trip carrier for Part
membership in flat-file mode. Tracker-mode round-trip uses sub-issue
parentage (Part is parent of its tasks).

Tracker-only enrichment (reactions, comments, attachments) is
preserved in the reverse-migration sidecar per V1 §6.6.1.

## 8. Body marker reservations

The optional body marker `<!-- execution-note-status: historical -->`
is reserved for `phase-N.md` (the phase epic's prose document
representation in flat-file mode) and does NOT apply to
`phase-part-v11.1`. This marker signals that a phase epic's
execution-note prose has been superseded by current state; Parts do
not carry execution notes and therefore do not carry the
historical-status marker.

This section is included for completeness so SCHEMA readers understand
the historical-marker convention on phase epics, and that the marker
is intentionally absent from the Part body.
