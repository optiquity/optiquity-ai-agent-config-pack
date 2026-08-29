# Check 39 fixtures — cmd_update mapping/glob symmetry

Synthetic test fixtures for `scripts/validate-pack.py` Check 39.
Mirror of the boundary-checks fixture pattern at
`scripts/tests/fixtures/boundary-checks/`.

Each fixture models the **install map** — the single machine-readable
declaration in `scripts/init-project.sh` that Check 39 derives the
`cmd_update` axis from. The map has two blocks sharing one row grammar:

```
#   <pack_relpath>  ->  <project_relpath>  [stage:<ids>]  [class:<token>]
```

* the explicit block — one row per installed file;
* the family block — one row per source pattern, `*` matching within a
  single path segment and a `{a,b,c}` DEST group fanning out.

The `cmd_update` axis is the set of rows whose `[stage:]` operand contains
the `cmd_update` token. There is no second declaration to drift from: these
fixtures deliberately carry **no `entries=()` array**, because no parser
reads that shape any more.

## Files

- `init-fragment-pass.sh` — an install map covering every
  `project-template/docs/pack/*.md` file the fixture set models, plus the
  prompts family as a GLOB row. Exercises the PASS path: every file is
  covered on the `cmd_update` axis and Check 39 reports zero asymmetric
  coverage.
- `init-fragment-fail-missing.sh` — the same map with `BAZ.md`'s row
  removed. Exercises the FAIL path: the file installs at fresh init but
  nothing covers it on the update axis, so Check 39 names it and points at
  the explicit block.
- `init-fragment-fail-malformed.sh` — rows carrying broken (empty)
  `[stage:]` and `[class:]` operands, so the derived axis is empty.
  Exercises the defensive-failure contract: Check 39 must FAIL with the
  cannot-derive diagnostic, never PASS by vacuity.

## Why static fixtures (vs. tmpdir generation only)

Group 2 of `test-validate-pack-check-39.sh` generates synthetic maps in
tmpdirs on the fly. The static fixtures here serve a different purpose:

1. **Documentation anchor** — committed files make the test-coverage
   surface, and the row grammar itself, visible at code-review time.
2. **Regression scaffolding** — if a future Check 39 change breaks the
   parser, these give a reproducible reference shape that does not depend
   on tmpdir cleanup or Python `tempfile` semantics.
3. **Out-of-band diagnosis** — a maintainer can point
   `_parse_client_installed_file_stages()` /
   `_parse_client_installed_globs()` at any of these fragments to
   reproduce a parsing edge case without running the full harness.

The fixtures are NOT meant to be invocable as standalone shell scripts —
they are fragments carrying the map blocks the parsers need.
