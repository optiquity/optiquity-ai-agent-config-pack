# Check 39 fixtures — cmd_update mapping/glob symmetry

Synthetic test fixtures for `scripts/validate-pack.py` Check 39
(BD-175 F2a). Mirror of the boundary-checks fixture pattern at
`scripts/tests/fixtures/boundary-checks/`.

Each fixture exercises a specific PASS / FAIL / parsing-edge case for
`_parse_cmd_update_entries()` and `check_cmd_update_symmetry()`.

## Files

- `init-fragment-pass.sh` — synthetic `init-project.sh` with a
  `cmd_update` function whose `entries=()` array contains explicit
  mappings for every `project-template/docs/pack/*.md` file the
  fixture set covers. Exercises the PASS-path: parser yields the
  full entry set; Check 39 reports zero asymmetric coverage.
- `init-fragment-fail-missing.sh` — synthetic `init-project.sh` with
  an `entries=()` array that omits one of the docs/pack files.
  Exercises the FAIL-path: parser yields a subset; Check 39 surfaces
  the missing file with a recommendation.
- `init-fragment-fail-malformed.sh` — synthetic `init-project.sh`
  whose `entries=()` array is structurally broken (e.g., missing
  closing paren on the same line, comment-only body). Exercises
  parser-degradation behavior: `_parse_cmd_update_entries()` returns
  empty set; Check 39 FAILs with the parse-failure message.

## Why static fixtures (vs. tmpdir generation only)

Group 2 of `test-validate-pack-check-39.sh` generates synthetic
fixtures in tmpdirs on the fly. The static fixtures here serve a
different purpose:

1. **Documentation anchor** — committed files make the test-coverage
   surface visible at code-review time.
2. **Regression scaffolding** — if future Check 39 changes break the
   parser, the static fixtures give a reproducible reference shape
   that doesn't depend on tmpdir cleanup or Python `tempfile`
   semantics.
3. **Out-of-band diagnosis** — a maintainer can manually invoke
   `_parse_cmd_update_entries()` against any of these fragments to
   reproduce a parsing edge case without running the full test
   harness.

The fixtures are NOT meant to be invocable as standalone shell scripts
— they're fragments containing only the `cmd_update` function body and
the `entries=()` array shape the parser needs.
