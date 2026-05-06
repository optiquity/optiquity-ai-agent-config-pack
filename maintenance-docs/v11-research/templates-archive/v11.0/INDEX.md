# Template archive — v11.0

This directory preserves the v11.0 form files and per-entry-type
schema descriptions. See `../README.md` for the archive contract.

## Entry types at v11.0

| Entry type | Schema | `template_version` body marker | `template:` label |
|---|---|---|---|
| BD-NNN (pack-development backlog item) | [bd-v11.0/SCHEMA.md](bd-v11.0/SCHEMA.md) | `bd-v11.0` | `template:bd-v11.0` |
| TD-NNN (project technical-debt item) | [td-v11.0/SCHEMA.md](td-v11.0/SCHEMA.md) | `td-v11.0` | `template:td-v11.0` |
| Phase epic (`phase-N`) | [phase-epic-v11.0/SCHEMA.md](phase-epic-v11.0/SCHEMA.md) | `phase-epic-v11.0` | `template:phase-epic-v11.0` |
| Phase task (`phase-N.M`) | [phase-task-v11.0/SCHEMA.md](phase-task-v11.0/SCHEMA.md) | `phase-task-v11.0` | `template:phase-task-v11.0` |
| Inbound (bug / feature / pack-feedback) | [inbound-v11.0/SCHEMA.md](inbound-v11.0/SCHEMA.md) | `inbound-v11.0` | `template:inbound-v11.0` |

Reference: V3.3 §6.5 D-18 carrier matrix.

## Frozen forms

The forms shipped at v11.0 are preserved byte-for-byte under
[forms/](forms/):

- [forms/work-item.yml](forms/work-item.yml) — composite form for BD,
  TD, phase-epic-skeleton, phase-task-skeleton (4-option `wi-type`
  dropdown per V3.3 §6.1).
- [forms/inbound.yml](forms/inbound.yml) — composite form for bug,
  feature-request, and 5× pack-feedback subcategories (7-option
  `in-category` dropdown per V2 §4.3).

Both forms emit a coarse `template:work-item-v11.0` /
`template:inbound-v11.0` label at intake; chat triage specializes
to the entry-type-specific label per V3.3 §6.5.
