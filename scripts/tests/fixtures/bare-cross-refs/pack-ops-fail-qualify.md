# Synthetic fixture — Check 40 FAIL path (qualify needed)

This fixture exercises the FAIL-with-qualify-suggestion path. Each
bare ref below resolves to exactly one file in the pack repo but
that file is in a DIFFERENT directory than this fixture; Check 40
MUST FAIL each one with a "qualify to `<one-path>`" message.

- The migrator script: `migrate-v10-to-v11.sh`
- Validator: `validate-pack.py`
- Init: `init-project.sh`
- JSON merge helper: `merge-json.py`
- TOML merge helper: `merge-toml.py`
- Migration narrative: `MIGRATION-v10-to-v11.md`
- Frozen migrator: `migrate-v9-to-v10.sh`
- Install procedure: `INSTALL-PROCEDURES.md`
