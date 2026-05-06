# Schema — `bd-v11.1` (synthetic test fixture)

This is a synthetic v11.1 BD entry-type schema used by BD-069's
test suite to exercise `pack tracker update-templates` against a
fictional v11.0 → v11.1 transition. It is NOT the production
v11.1 schema (none exists; v11.0 is the shipping version).

## 1. Identifier scheme

Same as bd-v11.0 (BD-NNN three-digit zero-padded counter).

## 2. Body marker trio

```
<!-- pack-id: BD-NNN -->
<!-- template_version: bd-v11.1 -->
<!-- pack-version: v11 -->
```

## 3. Schema delta from bd-v11.0

- Added `wi-priority` field (optional, default empty).
- Renamed `Description` heading to `Summary`.
- Renamed `status:open` label to `status:active`.

These deltas are encoded in
`scripts/tests/fixtures/template-versions/translations.yaml` as
the v11.0 → v11.1 rules block.
