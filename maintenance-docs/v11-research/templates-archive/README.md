# Templates archive

This directory preserves every shipped template version of the issue
forms (`work-item.yml`, `inbound.yml`) and the per-entry-type schema
descriptions that the form serves. The archive is the
single-source-of-truth for `pack tracker update-templates` (V2 §19) and
the reverse-migration sidecar's `template_version` translation flow
(V1 §6.6.1 / V3.3 D-18 carrier matrix).

## Why it exists

GitHub issue forms evolve over the lifetime of the pack. When a v11.1
form ships, entries created on the v11.0 form remain in the tracker
indefinitely. Without an archive of the v11.0 schema, the pack would
have no way to:

1. Migrate older entries forward (e.g. rename a renamed field).
2. Reverse-emit older entries to the v10 BACKLOG grammar.
3. Detect when an entry's body or label set is on a stale schema.

The archive solves all three by freezing every shipped version
verbatim and providing a per-entry-type schema document the migration
scripts can read.

## Layout

```
templates-archive/
├── README.md                     ← this file
└── v11.0/                        ← one directory per pack-version cut
    ├── INDEX.md                  ← lists every entry type at this version
    ├── <entry-type>-v11.0/       ← one per entry type (V3.3 §6.5)
    │   └── SCHEMA.md             ← identifier scheme, body marker trio,
    │                               label family, body section grammar,
    │                               reverse-emit grammar
    └── forms/                    ← frozen byte-copy of the form files
        ├── work-item.yml         ← shipped as .github/ISSUE_TEMPLATE/work-item.yml at this version
        └── inbound.yml
```

## Versioning rules

- One directory per **pack minor version** (e.g. `v11.0/`, `v11.1/`).
- Forms are archived verbatim at every minor cut. No retroactive edits.
- Per-entry-type schemas (`<entry-type>-v<N.M>/SCHEMA.md`) are one per
  type per minor: BD, TD, phase-epic, phase-task, inbound at v11.0.
- A future `translations.yaml` (V2 §19.4) will live at the top of this
  directory once `pack tracker update-templates` ships.

## What lives here vs in `.github/ISSUE_TEMPLATE/`

`.github/ISSUE_TEMPLATE/` holds the **live** form files used by GitHub
to render the New Issue UI. Editing those files changes the user
experience immediately. The archive holds **frozen** copies for
historical reference and migration.

When a new version ships, the live forms are updated first, then the
old shipped versions are copied into the archive in a separate commit.
The archive is append-only after a release tag.

## Pack-repo only

This archive is a pack-repo artifact. Client projects do not maintain
their own archive. They pull relevant archive entries from the pack
into their pack-side mirror at install / upgrade time, handled by
the pack-upgrade migration sequence in `INSTALL-PROCEDURES.md`.

Reference: ARCHITECTURE-V2.md §19.4, ARCHITECTURE-V3.3-DELTA.md §6.5.
