# Template archive — v11.1

This directory preserves the v11.1 form file and the per-entry-type
schema description for the new `phase-part-v11.1` entry type. See
`../README.md` for the archive contract.

The v11.1 archive cut introduces multi-part phase mid-work expansion +
execution-order mechanism. v11.0 remains the prior archive cut; v11.1
references v11.0 archive entries for entry types that did not change at
v11.1 and adds `phase-part-v11.1` as the 6th entry type.

## Entry types at v11.1

### Client-applicable entry types

| Entry type | Schema | `template_version` body marker | `template:` label |
|---|---|---|---|
| TD-NNN (project technical-debt item) | [../v11.0/td-v11.0/SCHEMA.md](../v11.0/td-v11.0/SCHEMA.md) | `td-v11.0` | `template:td-v11.0` |
| Phase epic (`phase-N`) | [../v11.0/phase-epic-v11.0/SCHEMA.md](../v11.0/phase-epic-v11.0/SCHEMA.md) | `phase-epic-v11.0` | `template:phase-epic-v11.0` |
| Phase task (`phase-N.M` / `Phase-N.Task-M`) | [../v11.0/phase-task-v11.0/SCHEMA.md](../v11.0/phase-task-v11.0/SCHEMA.md) | `phase-task-v11.0` | `template:phase-task-v11.0` |
| **Phase part (`Phase-N.Part-x`) — NEW in v11.1** | [phase-part-v11.1/SCHEMA.md](phase-part-v11.1/SCHEMA.md) | `phase-part-v11.1` | `template:phase-part-v11.1` |
| Inbound (bug / feature / pack-feedback) | [../v11.0/inbound-v11.0/SCHEMA.md](../v11.0/inbound-v11.0/SCHEMA.md) | `inbound-v11.0` | `template:inbound-v11.0` |

### Pack-internal entry types (informational only; NOT applicable to client projects)

| Entry type | Schema | `template_version` body marker | `template:` label |
|---|---|---|---|
| BD-NNN (pack-development backlog item) | [../v11.0/bd-v11.0/SCHEMA.md](../v11.0/bd-v11.0/SCHEMA.md) | `bd-v11.0` | `template:bd-v11.0` |

## v11.0 archive cross-reference

The v11.0 archive remains structurally frozen at 5 entry-type subdirs
(`bd-v11.0`, `td-v11.0`, `phase-epic-v11.0`, `phase-task-v11.0`,
`inbound-v11.0`) per Convention Y (v11.0 structural shape freeze;
USER-LOCKED 2026-05-26).

v11.1 references the v11.0 archive entries for unchanged entry types
(BD, TD, phase-epic, phase-task, inbound) rather than duplicating
them. The only NEW v11.1 entry type is `phase-part-v11.1` (introduced
by mid-work phase expansion).

**Intra-file additive extensions to v11.0 SCHEMAs are PERMITTED**
under Convention Y (backward-compatible content evolution; structural
shape stays frozen at 5 subdirs). This convention is exercised twice
at the v11.1 cut:

1. `../v11.0/phase-task-v11.0/SCHEMA.md` Section 3 (Label family) is
   extended to admit the new `status:cancelled` state value (per the
   `cancelled` state addition).
2. `../v11.0/INDEX.md` gains a forward-reference footnote pointing at
   v11.1 evolutions.

## v11.1 form file

The v11.1 form file at
`maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
is byte-identical to the live form
(`.github/ISSUE_TEMPLATE/work-item.yml` at pack root, mirrored
byte-identically to
`project-template/.github/ISSUE_TEMPLATE/work-item.yml`). The archive
form is CREATED in v11.1.

The live form is bumped to `template_version: work-item-v11.1`
and gains:
- a 5th `wi-type` dropdown option (`phase-part-skeleton`);
- a new `wi-part-letter` input (conditional on
  `wi-type=phase-part-skeleton`);
- description-text updates to admit `Phase-N.Part-x` and
  `Phase-N.Part-x.Task-M` identifier forms in Blockers, Unblocks,
  and Dependencies textareas.

Per the template-version delta table, only `work-item-v11.0` bumps to
`work-item-v11.1`; all four prior per-entry-type `template_version`
values (`bd-v11.0`, `td-v11.0`, `phase-epic-v11.0`, `phase-task-v11.0`,
`inbound-v11.0`) remain unchanged. The new `phase-part-v11.1` is the
only NEW per-entry-type template_version.

## Decision log cross-reference

The full record of 16 USER-LOCKED decisions (D1-D16) that shape this
archive cut includes:
- D1 (INV-7 breach: 5th `wi-type` option accepted)
- D2 (Part collapse REJECTED)
- D3 (empty Parts FORBIDDEN at creation)
- D4 (mid-life re-parenting FORBIDDEN; supersede-only)
- D5 (phase-task `cancelled` state ADDED)
- D11 (NEW `tracker-phase-part.sh` library accepted)
- D15 (Task letter-suffix REJECTED grammar-wide; `Task-M` integer-only)
- D16 (Convention Y: v11.0 structural shape frozen; intra-file additive
  extensions permitted)
