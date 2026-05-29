# RESEARCH-BD-195-SEGMENT-R6-pack-tests-fixtures

## Segment / owned paths (manifest)

- `scripts/tests/` — 45 `.sh` test files + `scripts/tests/fixtures/` tree.
- Top-level `scripts/test-*.sh` — 9 files (compare-agent-trinity, detect,
  dry-run-migration, migrator-capability-translation, migrator-core,
  migrator-manifest, migrator-skills, persona-contracts, restore-from-backup).
- `test-fixtures/` tracked files — `.gitignore`, `README.md`, `build.sh`,
  `manifest.txt`, and the `v11-trinity-marker-prepped/` quad (CLAUDE/AGENTS/
  GEMINI/README).

CORE QUESTION (per CLAUDE.md "Enumerate ENCODING surfaces"): do the test
assertions encode the CORRECT expected state, or does any test bake in a SEED
DEFECT — a hardcoded v11.1 expectation, a fixture/manifest expectation that
encodes the mis-versioning, a pack-self assertion that admits a forbidden
project-side concept, or a stale path-expectation about prison-moved docs?

## Coverage attestation

- Read in full: `test-issue-forms.sh`, `test-validate-pack-checks-36-37-38.sh`,
  `test-validate-pack-check-43.sh`, `test-per-entry.sh` (version-relevant
  regions), `template-translations-test.sh` (chain-resolver region),
  `test-tracker-phase-task.sh` (grammar region), the
  `template-versions/v11.1/bd-v11.1/SCHEMA.md` /
  `template-versions/translations.yaml` / `roundtrip/bd-v11.2/README.md`
  fixtures, and the version-relevant regions of `test-fixtures/build.sh` +
  `test-fixtures/README.md`.
- Whole-segment grep sweeps (all owned paths) for: `v11.1` / `11.1` / `v12`
  (Lens A); `frozen` / `freeze` / `released` / `unreleased` (Lens A); every
  prison-doc basename (Lens C); `phase-part` / `wi-part-letter` / `Part-x`
  (Lens B); `BD-` + `phase` + `TD-` co-occurrence on pack-self surfaces
  (Lens B); CI-wiring of the flagged test (Lens E).
- Skimmed (grep-screened, not line-read, justified by clean version/boundary
  sweep): the migrator test trio (`test-migrate-v10-to-v11-*.sh`),
  `recommendation-test.sh`, `recommendation-state-schema-test.sh`,
  `pack-help-test.sh`, `test-compare-agent-trinity.sh`,
  `test-persona-contracts.sh`, `test-v11-realistic-ot.sh`, the tracker test
  family, and checks 16/18/19/39/40/41/42 test files. All returned zero
  hits on the version/boundary/prison sweeps; spot-confirmed clean.
- prison/ docs: NOT read (PRISON RULE). Only their basenames were used as
  grep needles to detect stale references in owned files — none found.

## Findings count: BLOCKER 0 / MUST 1 / SHOULD 1 / NIT 0

---

## Findings

### R6-F01 — `test-issue-forms.sh` hard-attributes phase-parts to "v11.1" in 6 comment blocks (seed mis-versioning, CI-wired)
- Severity: MUST
- Category: Lens A (version) + Lens E (ENCODING, CI-wired) + seed-defect
- Surface(s): `scripts/tests/test-issue-forms.sh` — header comment block
  (the "added at v11.1 (BD-185 H.2)" sentence in the file-level docstring);
  `check_workitem()` body comment ("at v11.1 (BD-185 H.2). Per the ... rule");
  the pack-side forbidden-list comment ("added to the forbidden list at v11.1
  (BD-185 H.2)"); the `wi-part-letter` project-branch comment ("Added at v11.1
  (BD-185 H.2) for the mid-work phase expansion Part construct"); the Blockers
  Part-id comment ("Part-id forms admitted at v11.1 (BD-185 H.2)"); the Group 5
  disjoint-invariant comment ("option was added at v11.1 (BD-185 H.2)").
- Side: pack-self (test file; wired into CI at `.github/workflows/validate-pack.yml`
  `run: bash scripts/tests/test-issue-forms.sh`)
- Evidence:
  ```
  #      The `phase-part-skeleton` option and `wi-part-letter` field were
  #      added at v11.1 (BD-185 H.2) for the mid-work phase expansion
  #      Part construct.
  ```
  ```
      # added to the forbidden list at v11.1 (BD-185 H.2) — Parts are a
      # project-side mid-work expansion concept; pack-self-management
  ```
  (six occurrences of the literal `v11.1 (BD-185 H.2)` attribution; full grep
  list: lines for the docstring, `check_workitem` opts comment, forbidden-list
  comment, `wi-part-letter` comment, Blockers Part-id comment, Group 5 comment.)
- Why it's a problem: Violates the BD-195 CATEGORICAL FACT — "Phase-parts was
  ALWAYS v11.0 scope, never v11.1. Any doc/code labeling phase-parts ...
  'v11.1' ... is WRONG → a finding." These comments encode the exact
  mis-versioning that fractured the prior BD-185 attempt and that BD-195 is
  recovering. The defect is doubly significant because (a) it lives in a
  CI-wired ENCODING surface (per CLAUDE.md "Enumerate ENCODING surfaces" — the
  test is the F3 lock-step partner of the form file F1 + validator F2), so the
  wrong version label ships in the gate's own documentation, and (b) `BD-185
  H.2` is a prior-attempt commit-label that BD-195 Step 9 may wipe — citing it
  as the provenance of a v11.0 feature is a dangling reference to soon-to-be-
  superseded history. NOTE: the executable assertions themselves are
  version-neutral and structurally CORRECT (they assert `phase-part-skeleton`
  + `wi-part-letter` PRESENT on the project surface, DISJOINT from pack-side) —
  the defect is confined to the comment provenance/version labels, not the
  test logic.
- Recommendation: In all six comment locations, change "added at v11.1
  (BD-185 H.2)" → "added at v11.0 (phase-parts hierarchy work)" (or whatever
  the post-BD-195 canonical attribution is). Drop the `BD-185 H.2` sub-batch
  citation in favor of a stable BD/feature name, since the sub-batch label is
  recovery-volatile. Do NOT touch the assertions — they encode correct state.
  This edit must land in lock-step with any parallel re-attribution in the
  form file (`project-template/.github/ISSUE_TEMPLATE/work-item.yml` comment
  prose) and the validator (`scripts/validate-pack.py` per-surface comments)
  per the lock-step rule.
- Cross-segment touch points: The form file F1
  (`project-template/.github/ISSUE_TEMPLATE/work-item.yml`) and validator F2
  (`scripts/validate-pack.py` boundary checks) carry parallel version-
  attribution prose — likely owned by the form/script segments (R5 for the
  validator). Any segment auditing those surfaces should find the same v11.1
  label and the three must update together. Also: the actual form currently
  HAS the phase-part fields (committed under BD-185 at `e580dda`, now PAUSED
  per BD-195); BD-195 Step 9's wipe-or-salvage decision determines whether the
  fields + this test's assertions stay — but the v11.1 LABEL is wrong
  regardless of that decision.
- Confidence: high (literal categorical-fact contradiction in CI-wired text;
  six exact-string occurrences confirmed by grep).

### R6-F02 — `test-tracker-phase-task.sh` hardcodes `BD-NNN` admission in a project-side tracker dependency grammar as an expected invariant (BD-pack-only tension, unguarded by any validator)
- Severity: SHOULD
- Category: Lens B (boundary, BD-pack-only) + Lens E (ENCODING; no validator
  guards this invariant) + cross-segment: R5
- Surface(s): `scripts/tests/test-tracker-phase-task.sh` — Group 1 assertions
  `1.2 regex names BD-NNN` (asserts the exported bash regex contains
  `BD-[0-9]+`) and the `1.3` bash-vs-Python parity block, which inlines the
  Python parser regex `DEP = re.compile(r"^\s*-\s+(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)...")`
  and feeds it `'  - BD-108  trailing spaces in annotation  '` as a sample
  line that MUST match. Mirrors the source at
  `scripts/lib/tracker-phase-task.sh` `tracker_phase_task_dependency_re()`
  (returns `...(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)...`) and the
  embedded Python `DEP_ENTRY`.
- Side: cross (test asserts an invariant on a client-installed `scripts/lib/`
  surface — the tracker abstraction ships to client repos)
- Evidence:
  ```
  assert_contains "1.2 regex names BD-NNN"      "$dep_re" "BD-[0-9]+"
  ```
  ```
  sample_lines=(
      ...
      '  - BD-108  trailing spaces in annotation  '
      ...
      '  - phase-12.7 see TD-029: blocking on schema-bootstrap'
  ```
- Why it's a problem: Potential tension with `feedback_bd_pack_only_operational_rule`
  (pack memory, user-locked 2026-05-26): "client-facing content MUST NOT
  operationally treat BDs (dependency grammars, peer-tables, form admissions,
  parser regexes)." A tracker dependency-grammar regex admitting `BD-NNN` is
  precisely a named instance of the forbidden class ("dependency grammars ...
  parser regexes"). The test ENCODES `BD-NNN`-admission as a REQUIRED invariant
  (`assert_contains ... "BD-[0-9]+"`), which would actively resist any cleanup
  that removed BD from the client-facing grammar. I confirmed there is NO
  `validate-pack.py` check enforcing the BD-pack-only rule against the tracker
  libs (grep for `bd_pack_only` / a BD-deny check returned nothing), so this
  admission is unguarded — the test is the only ENCODING surface and it
  encodes the admission as desired. COUNTER-EVIDENCE (why this is SHOULD not
  MUST): the reverse-migration libs legitimately need BD in the grammar —
  `scripts/lib/tracker-migrate-reverse.sh` comments name "v10's `phase-N` /
  `TD-NNN` / `BD-NNN`" because v10 OT data can carry BD references that must
  round-trip faithfully; if the phase-task dependency grammar is consumed on
  the migration/round-trip path (not only on the client authoring path), the
  BD admission may be intentional fidelity, not a leak. Resolving which path
  this grammar serves is a source-design question owned by R5.
- Recommendation: Pair this with R5's finding on
  `scripts/lib/tracker-phase-task.sh`. R5 should determine whether the
  `tracker_phase_task_dependency_re` / `DEP_ENTRY` grammar is a client-facing
  authoring surface (→ BD admission is a BD-pack-only violation; strip
  `BD-\d+` from grammar AND from this test's `1.2`/`1.3` assertions in
  lock-step) or a migration-fidelity surface (→ BD admission is intentional;
  the test is correct but should carry a one-line comment citing the
  migration-fidelity rationale + a pointer to the BD-pack-only rule so future
  auditors don't re-flag it). Either way an explicit comment is owed. Do NOT
  edit unilaterally — this is a source-design call.
- Cross-segment touch points: R5 (`scripts/lib/tracker-phase-task.sh` source
  grammar; `scripts/lib/tracker-migrate-reverse.sh` and `tracker-promote.sh`
  which carry the same `phase-N|TD-NNN|BD-NNN` shape). The reconciliation pass
  should pair this test-side finding with R5's source-side verdict for ENCODING
  lock-step.
- Confidence: medium (the BD-in-grammar admission is real and matches the
  forbidden-class wording verbatim; the SHOULD vs MUST hinges on the migration-
  fidelity question, which is R5's source-design call, not mine to settle).

---

## Coverage map (every owned path → clean | finding-IDs)

### scripts/tests/ (.sh)
- `test-issue-forms.sh` → R6-F01
- `test-tracker-phase-task.sh` → R6-F02
- `test-validate-pack-checks-36-37-38.sh` → clean (version-neutral; correctly
  encodes pack/project boundary; `expected_extras` matches R5
  `_CLIENT_INSTALLED_FILES` — Lens E cross-checked OK)
- `test-validate-pack-check-43.sh` → clean (version-neutral; fixture targets
  resolve to real non-prison docs; `expected_extras` matches R5 inventory)
- `test-per-entry.sh` → clean (the `v11.1 — Patch release` changelog block is
  synthetic structural test data for the per-entry regenerator, which needs
  ≥2 version entries; verified real `pack-ops/CHANGELOG.md` has only v11.0)
- `template-translations-test.sh` → clean (`v11.0→v11.1→v12.0` is a
  hypothetical version chain exercising the multi-hop resolver; abstract
  version tokens, not a phase-parts claim)
- `test-validate-pack-check-16.sh` / `-18.sh` / `-19.sh` → clean (trinity-parity
  tests, version-neutral, Override-9-correct independence)
- `test-validate-pack-check-39.sh` / `-40.sh` / `-41.sh` / `-42.sh` → clean
  (version/boundary sweep zero hits)
- `test-validate-pack-checks-32-33-34.sh` → clean (`v11.0` is current-version
  fixture data; `frozen` refs are about the synthetic _v8 archive block)
- `test-migrate-v10-to-v11.sh` / `-decompose.sh` / `-dry-run.sh` / `-gates.sh`
  → clean (no v11.1/phase-part/prison hits; v10→v11.0 migration is correct)
- `test-add-capability.sh`, `test-customization-preserve.sh`,
  `test-init-project.sh`, `template-version-test.sh`,
  `recommendation-test.sh`, `recommendation-state-schema-test.sh`,
  `pack-help-test.sh` → clean (sweep zero hits; `bd-v11.0`/`td-v11.0` template
  markers + `bd-v11.1` reconcile-error inputs are legitimate fixture data)
- tracker family (`tracker-*-test.sh`, `test-tracker-*.sh`,
  `tracker-bd1XX-*-test.sh`) → clean (sweep zero version/boundary/prison hits;
  `provider_set_milestone 42 "v11.1"` is arbitrary-milestone-set test input)

### scripts/tests/fixtures/
- `template-versions/v11.1/bd-v11.1/SCHEMA.md` → clean (explicitly labeled
  "synthetic test fixture ... NOT the production v11.1 schema (none exists;
  v11.0 is the shipping version)" — actively affirms the categorical fact)
- `template-versions/translations.yaml` → clean (labeled "NOT the production
  manifest ... no v11.x has shipped yet")
- `roundtrip/bd-v11.0` / `bd-v11.1` / `bd-v11.2` → clean (forward-looking
  template-version-skip test scaffold; stubs explicitly v11.0-dated)
- `boundary-checks/`, `project-side-refs/`, `bare-cross-refs/`,
  `cmd-update-symmetry/`, `customization-preserve/`, `tracker-*` fixture dirs
  → clean (no phase-part / v11.1-as-current / prison-doc references)

### scripts/test-*.sh (top-level)
- `test-compare-agent-trinity.sh`, `test-detect.sh`,
  `test-dry-run-migration.sh`, `test-migrator-capability-translation.sh`,
  `test-migrator-core.sh`, `test-migrator-manifest.sh`,
  `test-migrator-skills.sh`, `test-persona-contracts.sh`,
  `test-restore-from-backup.sh` → clean (sweep zero hits; `test-migrator-core.sh`
  "frozen public surface" refers to the API-stability contract of
  migrator-core.sh, not a version freeze — correct usage)

### test-fixtures/ (tracked)
- `build.sh` → clean (the `frozen` refs at the `_build_realistic_for_version`
  header + v11 case comment CORRECTLY describe freezing as a FUTURE event:
  "When a future version freezes v11 (e.g., when v12 ships)"; "When v11.0 is
  tagged at Batch 24" — Batch 24 confirmed as the live BD-093 release-pin
  target per EXECUTION-PLAN-V11.0.md. Affirms v11.0 is currently unreleased.)
- `README.md` → clean (Determinism §: "v11-realistic-ot tracks the current
  pack HEAD ... When v11.0 is tagged at Batch 24" — correct unreleased-state
  handling; `frozen` refs describe the v11-trinity-marker-prepped snapshot and
  v10 tag pinning, not a v11.0 freeze)
- `manifest.txt` → clean (no version/boundary content; SHA rows; v11-* rows
  HEAD-drifting per documented invariant — no baked-in mis-versioning)
- `.gitignore` → clean
- `v11-trinity-marker-prepped/{CLAUDE,AGENTS,GEMINI,README}.md` → clean
  (frozen OT snapshot at commit fd6a0d6 per BD-136; "frozen" = source-pinned
  fixture provenance, not a version claim)
