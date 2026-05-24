# Check 43 fixtures — project-side bare cross-reference scanner

Synthetic test fixtures for `scripts/validate-pack.py` Check 43
(BD-173 H.14; V11 leak-sweep prevention). Mirror of the
`bare-cross-refs` fixture pattern at
`scripts/tests/fixtures/bare-cross-refs/`.

Each fixture exercises a specific PASS / FAIL / exemption case for
`check_project_side_bare_internal_refs()` and helpers
(reuses `_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`,
`_strip_code_blocks`, `_build_basename_index`; adds
`_CHECK_43_ALLOWLIST`, `_CHECK_43_ANCHOR_PHRASES`,
`_check_43_context_has_anchor`).

## Files

### FAIL fixtures (7 total)

These exercise the class-test failure paths per
`ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §1.7.

- `project-side-fail-per-entry-skeleton.md` — LEAK CLASS A (per-entry
  skeleton bare `ARCHITECTURE-PER-ENTRY-SPLIT.md` cite). Resolves
  into `maintenance-docs/` → FAIL pack-internal target.
- `project-side-fail-architect-doc-cite.md` — LEAK CLASS A
  (`ARCHITECTURE-V3.3-DELTA.md` bare ref). Resolves into
  `maintenance-docs/v11-research/` → FAIL pack-internal target.
- `project-side-fail-detect-sh-comment.sh` — LEAK CLASS D
  (`maintenance-docs/v11-implementation/ARCHITECTURE-FOO.md` in
  shell comment). Qualified-path detection → FAIL pack-internal
  target.
- `project-side-fail-pmstartup-cite.md` — LEAK CLASS E (pm-startup
  cluster `ARCHITECTURE-V3.md` bare ref). Resolves into
  `maintenance-docs/v11-research/` → FAIL pack-internal target.
- `project-side-fail-pmchat-self-prompt.md` — LEAK CLASS C
  (pm-chat self-prompt qualified `supporting-docs/SETUP-NEW.md`).
  SETUP-NEW.md not in client-install set → FAIL pre-install-only.
- `project-side-fail-mcp-example.json` — LEAK CLASS C
  (`.mcp.json.example` qualified `supporting-docs/CLI-PM-SETUP.md`).
  CLI-PM-SETUP.md not in client-install set → FAIL pre-install-only.
- `project-side-fail-audit-cite-in-skill.md` — LEAK CLASS F
  (BD-175 self-leak class — `AUDIT-USER-CURATION.md` bare ref).
  Resolves into `maintenance-docs/v11-implementation/` → FAIL
  pack-internal target.

### PASS fixtures (5 total)

These exercise the exemption tiers per §1.7.

- `project-side-pass-pack-feedback.md` — Cross-boundary product
  feature (`PACK-FEEDBACK.md` allowlist entry). PASS via
  `_CHECK_43_ALLOWLIST`.
- `project-side-pass-allowlist-methodology.md` — Client-installed
  supporting-docs/ (`METHODOLOGY.md` allowlist entry). PASS via
  allowlist.
- `project-side-pass-anchor-pack-repo.md` — "in the pack repo"
  anchor admits bare ref to pack-internal target. PASS via
  anchor-phrase exemption.
- `project-side-pass-same-dir-skeleton.md` — Per-entry skeleton
  sibling reference (`_intro.md` resolves same-dir within
  `docs/project/backlog/`). PASS via same-dir-legit OR allowlist
  (the basename is on the allowlist).
- `project-side-pass-code-block.md` — Bare ref inside a fenced
  code block. PASS via `_strip_code_blocks` preprocess.

## Total: 13 fixture files (7 FAIL + 5 PASS + 1 README)

## Why static fixtures (vs. tmpdir generation only)

Group 4 of `test-validate-pack-check-43.sh` generates synthetic
fixtures in tmpdirs on the fly (synthetic-tree end-to-end tests
T1-T9). The static fixtures here serve a different purpose:

1. **Documentation anchor** — committed files make the test-coverage
   surface visible at code-review time.
2. **Regression scaffolding** — if future Check 43 changes break the
   parser, the static fixtures give a reproducible reference shape
   that doesn't depend on tmpdir cleanup or Python `tempfile`
   semantics.
3. **Out-of-band diagnosis** — a maintainer can manually invoke
   `_CHECK_40_BARE_REF_PATTERN` (the regex Check 43 reuses) against
   any of these fragments to reproduce a pattern-match edge case
   without running the full test harness.

The fixtures are markdown / shell / json content snippets shaped
like real project-side / client-installed file content; they are
not loaded into the project-template/ directory at any point (the
test harness reads them as static inputs against an instrumented
Check 43 invocation).
