# Fixture: migration-v9.3-marker-convention

A v9.3 project that early-adopted the v10 marker convention for
`PLATFORM-SKILLS.md` `## Custom agents` and `## Custom skills` sections.
Tests that the migration's `merge-platform-skills.py` splice preserves
project-owned regions verbatim through the v9.3 → v10 migration.

## Overlay contents

| File | Customization | Migration disposition |
|---|---|---|
| `docs/pack/PLATFORM-SKILLS.md` | Two appended sections (`## Custom agents`, `## Custom skills`) with `FIXTURE-MARKER-CUSTOM-AGENT` and `FIXTURE-MARKER-CUSTOM-SKILL` rows | Pattern X splice via `merge-platform-skills.py` — Custom-* regions copied verbatim from project; pack-owned region above replaced from v10 template |

## Expected migration outcome

- Migration completes (exit 0).
- Post-migration `docs/pack/PLATFORM-SKILLS.md` retains both fixture
  marker strings (the splice copies project-owned regions verbatim).
- Pack-owned region above the `## Custom agents` heading reflects the
  v10 template content.
