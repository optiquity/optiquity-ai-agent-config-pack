# Fixture: migration-v9.3-empty

A v9.3-baseline project with **no project customizations**. Used as the
fast-path fixture for `scripts/test-migration.sh --quick` (CI).

## Expected migration outcome

Running `migrate-v9-to-v10.sh` against a project built from this fixture
should produce:

- Migration completes with exit code 0.
- Disposition summary: N pack-updates, 0 merges, 0 reconciliations needed.
- `report.md` "Reconciliation required" section is empty.
- No `*.v9-customized` sidecars created anywhere in the project tree.
- `dispositions.tsv` contains only `unchanged-pack` and
  `pack-update-applied` rows (plus `removed-by-design` for
  `docs/pack/PROMPT-TEMPLATES.md` retirement).
- v10 trinity templates land in place, replacing v9.3 versions.
- `.codex/requirements.toml` (K3) added to project tree (was missing pre-v10
  for non-customized projects).

This fixture has no `overlay/` directory because there are no
customizations to apply.
