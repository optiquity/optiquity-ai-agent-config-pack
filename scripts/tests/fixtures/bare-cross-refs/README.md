# Check 40 fixtures — pack-ops/ bare cross-reference scanner

Synthetic test fixtures for `scripts/validate-pack.py` Check 40
(BD-179). Mirror of the boundary-checks fixture pattern at
`scripts/tests/fixtures/boundary-checks/`.

Each fixture exercises a specific PASS / FAIL / exemption case for
`check_bare_pack_ops_refs()` and helpers
(`_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`,
`_CHECK_40_ALLOWLIST`, `_CHECK_40_ANCHOR_PHRASES`,
`_check_40_context_has_anchor`, `_strip_code_blocks`,
`_build_basename_index`).

## Files

- `pack-ops-pass-allowlist.md` — synthetic pack-ops/ markdown with
  bare refs that ARE on the `_CHECK_40_ALLOWLIST` (e.g.,
  `README.md`, `CLAUDE.md`). Exercises the allowlist-exempt path.
- `pack-ops-pass-anchor.md` — synthetic pack-ops/ markdown with
  bare refs whose ±2-line context contains an anchor phrase (e.g.,
  `in the pack repo`, `post-install`, `does not exist`, `archived`).
  Exercises the anchor-phrase-exempt path.
- `pack-ops-pass-same-dir.md` — synthetic pack-ops/ markdown with
  bare refs whose basename has exactly one candidate AND that
  candidate is in the same directory (same-dir-legit per Phase 1
  survey §7.1 implicit rule).
- `pack-ops-fail-qualify.md` — synthetic pack-ops/ markdown with
  bare refs that resolve to a DIFFERENT directory (qualify needed;
  exercises the 1-candidate FAIL path).
- `pack-ops-fail-broken.md` — synthetic pack-ops/ markdown with
  bare refs that don't resolve to any file in the repo (broken;
  exercises the 0-candidate FAIL path).
- `pack-ops-pass-code-block.md` — synthetic pack-ops/ markdown
  where a bare-shaped ref appears INSIDE a fenced code block;
  exercises the `_strip_code_blocks` preprocess (code-block content
  must NOT be flagged per §3 D2).

## Why static fixtures (vs. tmpdir generation only)

Group 2 of `test-validate-pack-check-40.sh` generates synthetic
fixtures in tmpdirs on the fly. The static fixtures here serve a
different purpose:

1. **Documentation anchor** — committed files make the test-coverage
   surface visible at code-review time.
2. **Regression scaffolding** — if future Check 40 changes break the
   parser, the static fixtures give a reproducible reference shape
   that doesn't depend on tmpdir cleanup or Python `tempfile`
   semantics.
3. **Out-of-band diagnosis** — a maintainer can manually invoke
   `_CHECK_40_BARE_REF_PATTERN` against any of these fragments to
   reproduce a pattern-match edge case without running the full test
   harness.

The fixtures are markdown content snippets shaped like real
pack-ops/*.md content; they are not loaded into the pack-ops/
directory at any point (the test harness reads them as static
inputs against an instrumented Check 40 invocation).
