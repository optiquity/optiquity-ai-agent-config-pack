# Fixture: migration-v9.3-customized

A v9.3 project with realistic project customization applied as overlays
on top of the v9.3 baseline. Models the OT-shape failure case that BD-059
was filed to fix.

## Overlay contents

| File | Customization | Migration disposition |
|---|---|---|
| `CLAUDE.md` | Project name `FixtureProject` filled in; populated `**Active skills:**` line; `<!-- FIXTURE-MARKER-CLAUDE -->` comment | `customization-detected-needs-reconciliation` (Pattern P sidecar via `merge-trinity.py`) |
| `.claude/settings.json` | `XCODE_SCHEME` set to `FIXTURE-SCHEME-MARKER` | `merged-with-customization` (Pattern S key-merge via `merge-json.py`) |
| `scripts/x-fixture.sh` | Project-only script using the `x-` prefix | `project-only-file` (preserved untouched per OQ-6(b)) |

## Expected migration outcome

- Migration completes (exit 0).
- Disposition summary: K reconciliations needed (≥1, for CLAUDE.md).
- `CLAUDE.md.v9-customized` sidecar appears alongside the migrated
  `CLAUDE.md`; sidecar preserves the `FIXTURE-MARKER-CLAUDE` string.
- `.claude/settings.json` post-migration retains
  `FIXTURE-SCHEME-MARKER` (Pattern S merge worked).
- `scripts/x-fixture.sh` is preserved byte-identical.
- Report's "Reconciliation required" section is non-empty.
- The structural-truthfulness invariant: report does NOT contain
  `customization: none` (the C3 disposition machinery replaced the
  status.txt heuristic).
