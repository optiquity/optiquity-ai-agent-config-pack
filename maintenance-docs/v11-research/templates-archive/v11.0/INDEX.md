# Template archive — v11.0

This directory preserves the v11.0 form files and per-entry-type
schema descriptions. See `../README.md` for the archive contract.

## Entry types at v11.0

### Client-applicable entry types

| Entry type | Schema | `template_version` body marker | `template:` label |
|---|---|---|---|
| TD-NNN (project technical-debt item) | [td-v11.0/SCHEMA.md](td-v11.0/SCHEMA.md) | `td-v11.0` | `template:td-v11.0` |
| Phase epic (`phase-N`) | [phase-epic-v11.0/SCHEMA.md](phase-epic-v11.0/SCHEMA.md) | `phase-epic-v11.0` | `template:phase-epic-v11.0` |
| Phase task (`phase-N.M`) | [phase-task-v11.0/SCHEMA.md](phase-task-v11.0/SCHEMA.md) | `phase-task-v11.0` | `template:phase-task-v11.0` |
| Phase part (`Phase-N.Part-x`) | [phase-part-v11.0/SCHEMA.md](phase-part-v11.0/SCHEMA.md) | `phase-part-v11.0` | `template:phase-part-v11.0` |
| Inbound (bug / feature / pack-feedback) | [inbound-v11.0/SCHEMA.md](inbound-v11.0/SCHEMA.md) | `inbound-v11.0` | `template:inbound-v11.0` |

### Pack-internal entry types (informational only; NOT applicable to client projects)

| Entry type | Schema | `template_version` body marker | `template:` label |
|---|---|---|---|
| BD-NNN (pack-development backlog item) | [bd-v11.0/SCHEMA.md](bd-v11.0/SCHEMA.md) | `bd-v11.0` | `template:bd-v11.0` |

Reference: V3.3 §6.5 D-18 carrier matrix.

## Archived forms

The forms preserved at v11.0 live under [forms/](forms/):

- [forms/work-item.yml](forms/work-item.yml) — composite form for TD,
  phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton
  (4-option `wi-type` dropdown per V3.3 §6.1 + the BD-193 bug-fix
  carve-out). The original v11.0 shipped form admitted a `bd` option;
  the BD-193 bug-fix carve-out removed it from the archive (clients use
  TD entries, not BD), leaving the four client-applicable wi-type
  options. v11.0 is unshipped, so the archive form is mutable and
  tracks the live client `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
  shape.
- [forms/inbound.yml](forms/inbound.yml) — composite form for bug,
  feature-request, and 5× pack-feedback subcategories (7-option
  `in-category` dropdown per V2 §4.3).

Both forms emit a coarse `template:work-item-v11.0` /
`template:inbound-v11.0` label at intake; chat triage specializes
to the entry-type-specific label per V3.3 §6.5.
