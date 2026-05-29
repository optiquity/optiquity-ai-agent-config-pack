# RESEARCH-BD-195-SEGMENT-R5-pack-scripts-source

Read-only audit (BD-195 Step 3, whole-repo recovery audit). Segment R5 —
pack scripts, source (non-test). Five lenses: A version / B boundary /
C cross-reference / D trinity-parity / E ENCODING lock-step.

## Segment / owned paths (manifest)

Top-level (non-test): `scripts/validate-pack.py`, `scripts/init-project.sh`,
`scripts/migrate-v10-to-v11.sh`, `scripts/add-capability.sh`,
`scripts/pack-help.sh`, `scripts/pack-tracker.sh`, `scripts/pack-td.sh`,
`scripts/tracker-migrate.sh`, `scripts/restore-from-backup.sh`,
`scripts/dry-run-migration.sh`, `scripts/compare-agent-trinity.py`,
`scripts/merge-json.py`, `scripts/merge-toml.py`, `scripts/merge-trinity.py`,
`scripts/merge-platform-skills.py`.
`scripts/lib/` (~40 files incl. `migrate-v10-to-v11/` 8 + `per-entry/` 4).
`scripts/persona-contracts/` (3).
EXCLUDED (R6's): `scripts/tests/`, top-level `scripts/test-*.sh`.

## Coverage attestation

- Full reads: `scripts/validate-pack.py` Check `check_issue_template_forms`
  region + version-string + HELP-FRAGMENT inventory regions;
  `scripts/pack-tracker.sh` update-templates block; `scripts/lib/tracker-doctor.sh`
  manifest region; `scripts/lib/template-translations.sh` header;
  `scripts/lib/tracker-sidecar.sh` header; `scripts/lib/per-entry/toc-regenerate.sh`
  sort region; `scripts/lib/tracker-migrate-forward.sh` path-resolution +
  parser regions; `scripts/lib/tracker-migrate-reverse.sh` emit-path region;
  `scripts/lib/tracker-phase-task.sh` header; `scripts/pack-help.sh` dispatch;
  `scripts/lib/detect.sh` surface-detect region; `scripts/init-project.sh`
  client-copy + inventory regions.
- Whole-segment scans (grep): v11.1/frozen/prison/phase-part/BD-185 strings;
  all `maintenance-docs/` path citations resolved against disk + prison;
  prisoned-doc basenames across all owned `.sh`/`.py`; client-copy boundary.
- Skimmed (scanned not line-read; clean on targeted greps): `merge-*.py`,
  `add-capability.sh`, `recommendation.sh`, `migrate-v10-to-v11.sh` body,
  `persona-contracts/*` (confirmed pack-internal, not client-shipped),
  remaining `tracker-*.sh` / `migrator-*.sh` / `migrate-v10-to-v11/*.sh`.
  Basis: no version/prison/boundary signal on the cross-cutting greps; full
  line-read deferred as low-yield for the 5-lens question set.

## Findings count

BLOCKER 0 / MUST 1 / SHOULD 2 / NIT 1

## Findings

### R5-F01 — validate-pack.py mislabels phase-part-skeleton as a "v11.1" addition
- Severity: MUST
- Category: Lens A (version) + Lens E (validator-encoded) + seed-defect
- Surface(s): `scripts/validate-pack.py` — `check_issue_template_forms()`
  docstring + inline comments (three occurrences: the docstring "The
  `phase-part-skeleton` option was added at v11.1 (BD-185 H.2)"; the inline
  "`phase-part-skeleton` was added at v11.1 (BD-185 H.2) as the 4th
  project-side entry type, representing the mid-work phase expansion 'Part'
  construct introduced at v11.1").
- Side: pack-self (validator)
- Evidence:
  > `phase-part-skeleton` was added at v11.1 (BD-185 H.2) as the 4th
  > project-side entry type, representing the mid-work phase expansion
  > "Part" construct introduced at v11.1.
- Why it's a problem: Violates the BD-195 CATEGORICAL FACT — phase-parts was
  ALWAYS v11.0 scope, never v11.1; v11.0 is unreleased and was never frozen.
  This is exactly the mis-versioning categorical error BD-195 exists to
  expunge, now living inside a CI validator's authoritative comments. NOTE the
  RUNTIME dict is CORRECT: `expected_wi_type_options_per_surface["project-template"]`
  = `{"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"}`
  matches both shipped form files (verified: `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
  admits `phase-part-skeleton`; `pack-root` admits only `bd`). The defect is
  PURELY the "v11.1" version label in the three comment strings.
- Recommendation: Edit the three comment occurrences to attribute
  phase-part-skeleton to v11.0 (it is in-flight v11.0 scope under the
  restarted BD-185). Drop "introduced at v11.1" / "added at v11.1" wording;
  if a BD anchor is wanted, cite BD-185 without a v11.1 version label, or
  state "v11.0 scope (BD-185)". Do not touch the runtime dict — it is correct.
- Cross-segment touch points: The shipped form-file descriptions
  (`project-template/.github/ISSUE_TEMPLATE/work-item.yml`) and any architect/
  planner doc describing the phase-part wi-type option should be audited for
  the same "v11.1" label by the segment owning project-template + maintenance
  docs. Also: `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/`
  exists as a real archived template under a `v11.1/` directory — same
  mis-versioning at the archive surface; flagged for the maintenance-docs
  segment (validate-pack only checks `templates-archive/v11.0/`, so the
  validator does NOT assert the v11.1 archive dir and will not catch it).
- Confidence: high — categorical fact applied; runtime dict verified against
  both shipped form files; git history confirms phase-part is current scope.

### R5-F02 — tracker-migrate-forward.sh has a dead fallback to a now-prisoned/nonexistent maintenance-docs IMPLEMENTATION-PLAN.md
- Severity: SHOULD
- Category: Lens C (cross-reference) + behavioral (dead path)
- Surface(s): `scripts/lib/tracker-migrate-forward.sh` — Step 1+2 path
  resolution in the main forward function (`plan_path` assignment).
- Side: pack-self (runtime lib; pack-internal, not client-shipped)
- Evidence:
  > plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
  > [[ ! -f "$plan_path" ]] && plan_path="$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md"
- Why it's a problem: `$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md`
  does not exist anywhere in the repo (verified — the pack's plan corpus lives
  under `maintenance-docs/v11-implementation/` with no top-level
  `IMPLEMENTATION-PLAN.md`). The fallback is dead: it can only ever resolve to
  a missing path, after which line `[[ -f "$plan_path" ]]` is false and
  `phases='[]'`. It is a stale reference that pretends a pack-side plan
  location exists. (Guarded — no crash — hence SHOULD not BLOCKER.)
- Recommendation: Remove the dead `maintenance-docs/IMPLEMENTATION-PLAN.md`
  fallback line, OR repoint it to the actual pack plan mirror if a pack-surface
  forward-migration is intended to read one (none exists at that name today —
  pack uses BD-tracked backlog, not a phase plan, for self-management; see
  Lens B note in R5-F04). Simplest correct fix: delete the fallback line so
  `plan_path` is just `$repo_root/IMPLEMENTATION-PLAN.md` (client surface) /
  unset for pack.
- Cross-segment touch points: R6 — any forward-migrate test that asserts the
  fallback path resolution should be re-checked once this line is removed
  (Lens E pairing).
- Confidence: high — path nonexistence verified on disk; guard semantics read
  directly.

### R5-F03 — forward-migrate client BACKLOG/PLAN path resolution diverges from the pack's own canonical client layout (detect.sh + per-entry _rules.md)
- Severity: SHOULD
- Category: Lens C (cross-reference) + Lens E (encoding inconsistency) + behavioral
- Surface(s): `scripts/lib/tracker-migrate-forward.sh` — client-surface
  `backlog_path="$repo_root/BACKLOG.md"` (Step 1+2 and the mirror-only
  short-circuit) and `plan_path="$repo_root/IMPLEMENTATION-PLAN.md"`.
- Side: pack-self (runtime lib) / cross (project-side semantics)
- Evidence:
  > # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.
  > if [[ "$surface" == "pack" ]]; then backlog_path="$repo_root/pack-ops/BACKLOG.md"
  > else backlog_path="$repo_root/BACKLOG.md"; fi
  > plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
- Why it's a problem: The pack's own canonical CLIENT mirror locations are
  `docs/project/BACKLOG.md` and `docs/project/IMPLEMENTATION-PLAN.md`
  (`project-template/docs/project/backlog/_rules.md` line 45 "The monolithic
  `docs/project/BACKLOG.md` is a regenerated mirror"; same for
  implementation-plan `_rules.md`; `scripts/init-project.sh` lines 1006-1007
  + 1028 install empty mirrors at `docs/project/{BACKLOG,IMPLEMENTATION-PLAN}.md`).
  `scripts/lib/detect.sh::detect_pack_surface` correctly probes
  `"$target/docs/project/BACKLOG.md"` (with repo-root last-resort), so the
  pack is internally inconsistent: detection knows the v11 client layout but
  forward-migrate's client branch reads ONLY repo-root. The reverse
  counterpart (`scripts/lib/tracker-migrate-reverse.sh`, emit-path block)
  documents repo-root client emit as deliberate pre-v10 back-compat ("Client
  side has its own canonical locations under docs/project/ already handled by
  the project-side reverse path; the legacy root emit shape is preserved here
  for back-compat"). If that back-compat rationale also covers forward, the
  forward branch should SAY so; if it does not, forward silently parses zero
  entries/phases for a correctly-laid-out v11 client. Either way the asymmetry
  is undocumented on the forward side.
- Recommendation: Reconcile forward client-path resolution with detect.sh's
  candidate order (probe `docs/project/BACKLOG.md` then repo-root fallback),
  OR add an explicit comment on the forward client branch mirroring the
  reverse back-compat rationale so the repo-root-only behavior is a documented
  choice, not drift. Architect-level call on which; surface to user.
- Cross-segment touch points: R6 — forward-migrate fixtures place BACKLOG.md
  at fixture root (`scripts/tests/fixtures/tracker-migrate/BACKLOG.md`), which
  means the test layout may itself encode the repo-root assumption and would
  not catch a `docs/project/` client; flag for Lens-E reconciliation.
- Confidence: medium — canonical client locations and detect.sh order verified
  on disk; whether forward repo-root is intentional back-compat (like reverse)
  or true drift is undocumented on the forward side, hence the divergence not
  the severity is the firm part.

### R5-F04 — stale citations to a now-prisoned doc (ARCHITECTURE-V3.2-DELTA.md) in two lib headers
- Severity: NIT
- Category: Lens C (cross-reference) + prison-rule
- Surface(s): `scripts/lib/tracker-migrate-forward.sh` (mapping-helpers
  header comment) and `scripts/lib/tracker-phase-task.sh` ("Reference:" header
  comment).
- Side: pack-self (lib header comments)
- Evidence:
  > # documented in maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md
  > # §4.1 and carried forward unchanged in V3.3 §4.1.  (forward.sh)
  > # Reference: ARCHITECTURE-V3.3-DELTA.md §2, ...; ARCHITECTURE-V3.2-DELTA.md
  > #            §4.1, §4.2, §4.3.  (tracker-phase-task.sh)
- Why it's a problem: `ARCHITECTURE-V3.2-DELTA.md` was moved to
  `maintenance-docs/prison/` in BD-195 Step 2 (commit 4a3f5e2); no non-prison
  copy exists. Per the PRISON RULE prisoned docs are superseded and must not
  be cited/trusted. The cited path
  `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` no longer resolves.
  Low severity because both comments already note the content was "carried
  forward unchanged in V3.3" and cite the live V3.3-DELTA alongside, so the
  load-bearing reference is intact.
- Recommendation: Drop the `ARCHITECTURE-V3.2-DELTA.md` citations; rely on the
  live `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` §4.1 (and
  §4.1-§4.3) which both comments already reference as the carry-forward home.
- Cross-segment touch points: none in scripts; any other segment citing
  V3.2-DELTA at a non-prison path has the same stale-prison-ref defect.
- Confidence: high — prison location + commit + non-existence of a non-prison
  copy all verified.

## Notes (scanned, NOT findings — confirmed clean / legitimate)

- `scripts/pack-tracker.sh`, `scripts/lib/tracker-doctor.sh`,
  `scripts/lib/tracker-sidecar.sh` "v11.1+" strings are correct forward-looking
  statements (e.g., "At v11.0 no template-version transitions exist yet; this
  command becomes meaningful when v11.1+ ships with field changes"). They do
  NOT mislabel v11.0 work as v11.1 and respect "v11.0 ships now; v11.1+
  deferred." Not findings.
- `scripts/lib/template-translations.sh` `bd-v11.0`→`bd-v11.1` is an
  illustrative manifest-format example + a synthetic test fixture for chain
  resolution, explicitly "(no v11.x has shipped)". `scripts/lib/template-version.sh`
  `phase-task-v11.2`→`v11.2` is a version-suffix-parser example. Legitimate.
- `scripts/lib/per-entry/toc-regenerate.sh` "v11.1 above v11.0" is a
  descending-minor sort-order comment, not a versioning claim. Legitimate.
- `scripts/pack-help.sh` + `scripts/lib/detect.sh` are dual-surface tooling
  (run on both pack repo and client repo); their `pack-ops/` references are
  wrapped in explicit `<!-- DENY-LIST-CONTENT-START/END -->` boundary-scanner
  allowlist markers and the `client)` branch correctly uses `docs/pack/`. The
  BD-NNN in their comments document pack-development provenance; these are
  code comments (not RAG-indexed prose) in pack-authored tooling. No leak.
- `scripts/persona-contracts/*.sh` are pack-internal contract helpers (NOT
  copied to client by init-project.sh — verified); their BD-115/116/088
  references are pack-self, not client-facing. No boundary violation.
- `scripts/validate-pack.py` HELP-FRAGMENT inventory is post-BD-194 correct
  (pack-side authors `pack-ops/HELP-FRAGMENT-{PACK,TRACKER}.md`; the
  `_CLIENT_INSTALLED_FILES` inventory references project-side
  `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` only — matching the
  BD-193/194 separate-artifact fix). No stale-inventory defect.
- No prisoned-doc basename (other than V3.2-DELTA in R5-F04) is referenced by
  any owned script. No `prison/` path is cited by any owned script.
- "frozen"/"FROZEN" strings in `migrator-core.sh`, `migrator-skills.sh`,
  `validate-pack.py` BD-119 region refer to the migrator PUBLIC-API surface
  being frozen (a deliberate API-stability contract), NOT to v11.0 being
  frozen. Not the BD-195 "frozen v11.0" defect. Legitimate.

## Coverage map (every owned path → "clean" | finding-IDs)

- scripts/validate-pack.py → R5-F01 (rest clean)
- scripts/init-project.sh → clean
- scripts/migrate-v10-to-v11.sh → clean
- scripts/add-capability.sh → clean
- scripts/pack-help.sh → clean
- scripts/pack-tracker.sh → clean (v11.1+ strings legitimate)
- scripts/pack-td.sh → clean
- scripts/tracker-migrate.sh → clean
- scripts/restore-from-backup.sh → clean
- scripts/dry-run-migration.sh → clean
- scripts/compare-agent-trinity.py → clean
- scripts/merge-json.py / merge-toml.py / merge-trinity.py / merge-platform-skills.py → clean
- scripts/lib/tracker-migrate-forward.sh → R5-F02, R5-F03, R5-F04
- scripts/lib/tracker-migrate-reverse.sh → clean (back-compat documented)
- scripts/lib/tracker-phase-task.sh → R5-F04
- scripts/lib/detect.sh → clean
- scripts/lib/tracker-doctor.sh → clean (v11.1+ strings legitimate)
- scripts/lib/template-translations.sh → clean (example/fixture)
- scripts/lib/template-version.sh → clean (parser example)
- scripts/lib/tracker-sidecar.sh → clean (forward-looking)
- scripts/lib/per-entry/toc-regenerate.sh → clean (sort comment)
- scripts/lib/per-entry/{_lib.sh,decompose.sh,mirror-generate.sh} → clean
- scripts/lib/migrator-core.sh / migrator-skills.sh / migrator-manifest.sh / migrator-stages.sh → clean (API-frozen, not v11.0-frozen)
- scripts/lib/migrate-v10-to-v11/*.sh (8) → clean (greps clean; skimmed)
- scripts/lib/customization-preserve.sh / customization-report.sh / recommendation.sh / template-translations.sh / three-way.sh → clean
- scripts/lib/tracker-config.sh / tracker-init.sh / tracker-labels.sh / tracker-links.sh / tracker-cycle-check.sh / tracker-header-snapshot.sh / tracker-errors.sh / tracker-mirror.sh / tracker-promote.sh / tracker-provider.sh / tracker-provider-gh.sh / tracker-agent-read.sh → clean (greps clean; skimmed)
- scripts/persona-contracts/*.sh (3) → clean (pack-internal, not client-shipped)
