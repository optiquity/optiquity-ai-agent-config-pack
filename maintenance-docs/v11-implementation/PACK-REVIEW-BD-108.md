# PACK-REVIEW-BD-108 — Cross-entity dependency link orchestration + cycle check + gate-check extension

**Reviewer scope:** BD-108 (commit `aae4712`)
**Reviewer:** pack-reviewer (per-BD, no prior reviews; experiment 2026-05-15)
**Date:** 2026-05-15

## Summary

Has-MUSTs. The implementation is functionally correct, the algorithm is
sound, the test suites pass cleanly (43 + 21 = 64 assertions), the
provider-op + capability-flag invariants are honoured (no new
operation, no new capability flag), and the round-trip identity claim
holds for both fixtures. However, **two new test scripts
(`test-tracker-links.sh` + `test-tracker-cycle-check.sh`) are not
wired into `.github/workflows/validate-pack.yml`** — the CI pipeline
will not catch regressions on either library. There is also one
SHOULD-grade verb-naming inconsistency relative to V3.3 §5.6 (self-loop
emits a different next-step verb than BFS-detected cycles), three
SHOULD-grade test-coverage gaps in the existing migrator test suites
(forward step 7b path, reverse `_tmr_decode_blockers` D-21 restriction,
roundtrip with phase-N.M Blockers), and several NIT-grade
documentation inconsistencies in the new libraries. No spec
divergence or shell-injection issue.

Severity counts:
- **BLOCKER:** 0
- **MUST:** 1
- **SHOULD:** 5
- **NIT:** 6

## Findings

### Finding F1
- **Severity:** MUST
- **Location:** `.github/workflows/validate-pack.yml` (lines 97-175)
- **Title:** New BD-108 test scripts are not wired into CI
- **Description:** `scripts/tests/test-tracker-links.sh` (43 assertions) and
  `scripts/tests/test-tracker-cycle-check.sh` (21 assertions) are NEW in
  this BD, but neither is invoked by the `Validate Pack` workflow.
  Greppable proof: `grep -c "test-tracker-links\|test-tracker-cycle-check"
  .github/workflows/validate-pack.yml` → 0. The workflow lists every
  tracker test script explicitly (no wildcard); the run that proves
  these tests are green is local-only. Future regressions in
  `tracker-links.sh` or `tracker-cycle-check.sh` will not be caught
  until the next maintainer notices. (Note: BD-106's
  `test-tracker-phase-task.sh` is similarly absent from the workflow,
  per the same omission pattern — but that is BD-106 territory and out
  of this review's scope. BD-108's own omission stands as MUST.)
- **Suggested fix:** Add two `- name:` blocks to `validate-pack.yml`
  immediately after the existing `tracker-migrate-roundtrip-test.sh`
  step (around line 117), each with `if: always()` and the standard
  `bash scripts/tests/...` invocation. Pattern matches lines 109-117.
- **Source:** Pack memory: "If new files or directories are added,
  verify that CI validation accounts for them." Also CLAUDE.md
  "CI validation: The Validate Pack GitHub Actions workflow runs on
  every push."

### Finding F2
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-cycle-check.sh:177-181` vs `:209-274`
- **Title:** Self-loop verb inconsistent with BFS-cycle verb (V3.3 §5.6)
- **Description:** V3.3 §5.6 mandates that cross-entity link failures
  "name the verb (`pack tracker doctor`)". The BFS-detected cycle path
  (Python heredoc, line 261-263) hard-codes `→ Run: pack tracker
  doctor` correctly. But the self-loop path (line 178) uses
  `tracker_error_emit "validation"` which the verb table
  (`scripts/lib/tracker-errors.sh:118`) maps to `→ Run: review the
  backend message above`. So the same library's two cycle-refusal
  paths name different next-step verbs for the same class of failure.
  Tests do not catch this: `test-tracker-cycle-check.sh:298` only
  asserts the self-loop emits a `→ Run:` line at all, not which verb.
- **Suggested fix:** In the self-loop guard at line 178, format the
  error inline (matching the BFS path) so it ends with `→ Run: pack
  tracker doctor`. Alternative: extend `tracker_error_emit` /
  `tracker_error_format` to accept an explicit verb override and pass
  `pack tracker doctor` from the cycle-detection callers. Whichever
  approach is chosen, also tighten the existing self-loop test
  assertion to `assert_contains "..." "$err" "pack tracker doctor"`.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §5.6 ("name the verb (`pack
  tracker doctor`) per V3 §27.1 Layer 2"); V1 §9 typed-error
  contract.

### Finding F3
- **Severity:** SHOULD
- **Location:** `scripts/tests/tracker-migrate-forward-test.sh` (lacks
  step 6+7 phase-N.M and step 7b coverage)
- **Title:** Forward orchestrator's new BD-108 paths have no
  migrator-level integration test
- **Description:** BD-108 changes
  `scripts/lib/tracker-migrate-forward.sh` in two places: (1) the step
  6+7 `case "$raw" in` statement gains a most-specific-first
  `phase-[0-9]*.[0-9]*)` arm that calls `provider_link blocked-by`
  (line 894-905); (2) a new step 7b parses
  IMPLEMENTATION-PLAN.md via `tracker_phase_task_parse` and replays
  each task's Dependencies bullet as `provider_link` (line 938-992).
  Neither path is exercised by `tracker-migrate-forward-test.sh` —
  greppable proof: `grep -c "phase-3.2\|phase-N.M\|step.7b\|tracker_phase_task_parse"
  scripts/tests/tracker-migrate-forward-test.sh` → 0. The unit-level
  link-orchestrator tests in `test-tracker-links.sh` do cover the
  blocked-by emission, but the orchestrator's case-statement routing
  and step-7b assembly are unique to the migrator and warrant their
  own assertion (e.g., a fixture BACKLOG entry with `Blockers:
  phase-3.2` produces a `provider_link "<entry-gh>" "<phase-task-gh>"
  "blocked-by"` call against the stub backend, not a
  `provider_sub_issue_create`).
- **Suggested fix:** Add 1-2 assertions to
  `tracker-migrate-forward-test.sh`: (a) BACKLOG entry with `Blockers:
  phase-3.2` routes to `provider_link` (not sub-issue create); (b)
  IMPLEMENTATION-PLAN with a Dependencies bullet triggers a step-7b
  `provider_link` invocation. Both can use the existing stub backend
  pattern in that test file.
- **Source:** Pack memory: "Skill and agent maintenance is mechanical
  by default … reviewed, and rule-strict." Test-coverage adequacy is
  a standing review criterion (this prompt §"Goal").

### Finding F4
- **Severity:** SHOULD
- **Location:** `scripts/tests/tracker-migrate-reverse-test.sh:187-198`
- **Title:** No regression test for `_tmr_decode_blockers` V3.3 D-21
  sub-issue parent restriction
- **Description:** BD-108 tightens
  `_tmr_decode_blockers` (`scripts/lib/tracker-migrate-reverse.sh:362-365`)
  so the sub-issue parent decoder admits ONLY phase epics (`^phase-\d+$`),
  not phase tasks (`phase-N.M`) — V3.3 §2 D-21. Pre-BD-108 used
  `pack_parent.startswith("phase-")` which would falsely admit a
  phase-task pack-id. The existing reverse test (group 1.5, lines
  187-194) uses a phase-3 sub-issue parent and does not exercise the
  new restriction. A regression in this regex would silently re-admit
  phase-task sub-issue parents and corrupt reverse-emitted Blockers
  fields without test failure.
- **Suggested fix:** Add one assertion to `tracker-migrate-reverse-test.sh`
  group 1.5: a mapping that includes `"phase-3.2": {"id": "59"}` plus
  `sub_issue_parent="59"` should produce blockers WITHOUT phase-3.2
  (the phase task pack-id must NOT appear in the sub-issue-parent
  channel; if it appeared in the body comment marker channel it would
  still ride through, but that is a separate code path).
- **Source:** ARCHITECTURE-V3.3-DELTA.md §2 D-21; BD-108 IMPLEMENTATION-REPORT
  §2 (third row).

### Finding F5
- **Severity:** SHOULD
- **Location:** `scripts/tests/tracker-migrate-roundtrip-test.sh` +
  `scripts/tests/fixtures/roundtrip/`
- **Title:** Round-trip test fixtures do not exercise phase-N.M
  Blockers grammar
- **Description:** The existing `tracker-migrate-roundtrip-test.sh`
  iterates `fixtures/roundtrip/bd-v11.x/` directories. Greppable proof:
  `grep -l "phase-3.2\|phase-N.M\|Dependencies"
  scripts/tests/fixtures/roundtrip/*/BACKLOG*.md` → 0. The `tracker-links`
  test 4.1 does exercise SHA-256 round-trip on a Blockers
  `phase-N.M, TD-NNN` fixture, but that test uses
  `tmf_parse_backlog → _tmr_emit_backlog` directly — it does NOT go
  through the full migrator forward → state-file → reverse pipeline
  that `tracker-migrate-roundtrip-test.sh` covers. The bidirectionality
  contract (V1 §6.0) for v11 phase-N.M shape is therefore not
  end-to-end test-asserted.
- **Suggested fix:** Either (a) extend an existing
  `fixtures/roundtrip/bd-v11.0/BACKLOG.md` to include one entry whose
  Blockers field names a `phase-N.M`, OR (b) add a new sub-fixture
  under `fixtures/roundtrip/bd-v11.0/` that the existing iteration
  loop will pick up. The state-file fake (the offline tracker-state
  JSON) already supports arbitrary string ids; no test infra change
  needed.
- **Source:** ARCHITECTURE-V1.md §6.0 bidirectionality contract;
  ARCHITECTURE-V3.3-DELTA.md §5.3 ("These two extensions are
  additive. Every legal v10 form continues to parse"); V3.3 §4.4
  round-trip extensions.

### Finding F6
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-cycle-check.sh:30-37`
- **Title:** Header rationale for traversal direction is incorrect
- **Description:** The header comment justifies starting BFS at the
  proposed-target with: "If we reach the proposed-source, then
  proposed-source is already (transitively) blocked by
  proposed-target". This rationale is backwards. Walking from
  `tgt` along blocked-by edges means: `out[tgt] = [things tgt is
  blocked by]`. Reaching `src` from `tgt` means there is a chain
  `tgt → ... → src` of "blocked-by" relationships, i.e.,
  **proposed-target is (transitively) blocked-by proposed-source**.
  Adding the proposed edge "S blocked-by T" then closes a cycle
  (S → T → ... → S). The algorithm is correct; only the rationale
  text is wrong, which makes the comment misleading for future
  maintainers debugging cycle-detection edge cases. (The reasoning
  matters because cycle-check correctness is hard to eyeball without
  it.)
- **Suggested fix:** Replace lines 33-37 with: "If we reach the
  proposed-source from the proposed-target, then **proposed-target
  is (transitively) blocked-by proposed-source** in the existing
  graph. Adding the proposed edge `S blocked-by T` (i.e., S → T)
  would then close a cycle S → T → ... → S, so we refuse it." Also
  consider noting that the V3.3 §5.5 prose ("from the new edge's
  source for K hops") would NOT detect cycles correctly if read
  literally — the implementation matches graph-theoretic correctness;
  the spec text wording is a known imprecision.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §5.5 (cycle detection
  semantics).

### Finding F7
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-links.sh:31-35` and `:38-44`
- **Title:** Header documents a sidecar-mutation callback that does
  not exist
- **Description:** The header reference (line 31-35) says: "Optionally
  appends the edge to the sidecar's `dependency_edges` array (V3.3
  §6.R schema: kind / target / annotation) when the caller passes a
  sidecar-mutation callback." But `tracker_links_create_blocked_by`
  takes only `<source-pack-id> <target-pack-id> <id-map-json>
  <store-path> [<annotation>]` — no callback parameter. The sidecar
  `dependency_edges` block is the caller's responsibility (the
  success JSON returns the annotation for the caller to consume).
  Similar issue: IMPLEMENTATION-REPORT §10.4 says the library "writes
  both" the cycle-graph store and the sidecar — but only the cycle-
  graph store is written.
- **Suggested fix:** Either (a) remove the "sidecar-mutation
  callback" claim from the header and clarify that the sidecar
  `dependency_edges` block is the caller's responsibility (the
  success JSON's `annotation` field is the hook for that), OR (b)
  implement the callback parameter in a future commit. Option (a) is
  the lower-risk fix for the current scope.
- **Source:** Internal consistency between header doc and function
  signature.

### Finding F8
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-cycle-check.sh:24, 25, 39, 43-44`
- **Title:** Parameter name "sidecar-store-path" conflates two
  distinct artifacts
- **Description:** The parameter is documented as `<sidecar-store-path>`
  and the lower section "Sidecar-store contract" describes its
  schema. But that file is the **cycle-graph store** (an in-memory
  edge index per V3.3 §6.R prose: "the in-memory edge index that
  tracker_links_create_blocked_by maintains"). The actual sidecar is
  V3.3 §6.R's per-task `dependency_edges` block in the
  `phase_tasks` sidecar — a different file with a different schema.
  The lower paragraph (lines 57-60) does clarify "The store is the
  durable cycle-graph view; the sidecar is the durable persistence
  view", but the parameter name itself remains ambiguous.
- **Suggested fix:** Rename the parameter / docstring to
  `<cycle-graph-store-path>` (or `<edge-store-path>`) throughout
  the header. No code change needed (the variable name `store_path`
  inside the function is already unambiguous).
- **Source:** Internal consistency; ARCHITECTURE-V3.3-DELTA.md §6.R
  ("sidecar `dependency_edges` per-task entry shape").

### Finding F9
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-migrate-forward.sh:894`
- **Title:** Bash glob `phase-[0-9]*.[0-9]*` is more permissive than
  the canonical `phase-N.M` regex
- **Description:** The new most-specific-first arm uses
  `phase-[0-9]*.[0-9]*)` which matches strings the strict regex
  `^phase-\d+(\.\d+)?$` would reject — e.g., `phase-3foo.4`,
  `phase-10-extra.5`, `phase-3.2.5`. None of these are valid
  pack-ids; the parser accepts arbitrary strings into the Blockers
  list, so a malformed entry would survive parse and reach this
  case statement. The downstream `tmf_mapping_get` would silently
  fail to find the malformed id, so the practical impact is "no link
  created and no error" — defensible but not defense-in-depth.
- **Suggested fix:** Either (a) tighten the case glob to
  `phase-[0-9][0-9]*.[0-9][0-9]*)` (no extra characters in the N or M
  positions; still bash-3.2 compatible), OR (b) add a one-line
  validation before the case (`if [[ ! "$raw" =~
  ^(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)$ ]]; then continue;
  fi`). Option (a) is minimally invasive.
- **Source:** Defense in depth; matches the canonical regex used by
  `_tlk_is_valid_pack_id` in `scripts/lib/tracker-links.sh:275`.

### Finding F10
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-migrate-forward.sh:958`
- **Title:** Step 7b silently swallows phase-task parser failures
- **Description:** The line `if pt_doc=$(tracker_phase_task_parse
  "$plan_path" 2>/dev/null); then` redirects all stderr from the
  parser to /dev/null. If the IMPLEMENTATION-PLAN.md is malformed
  (V3.3 §5.3 grammar violation, garbled bullets, etc.), the parser
  emits a typed error to stderr and returns rc=1 — the migrator
  then silently skips the entire phase-task dependency replay
  without any partial-failure log entry. Forward-migration users
  would see "0 cross-phase deps linked" with no diagnostic.
- **Suggested fix:** Capture stderr to a temp file (or to
  `$partial_failures`) so a parser failure is surfaced as a partial-
  write entry rather than silently dropped. Pattern: `if pt_doc=$(...
  2>"$tmp_err"); then ... else cat "$tmp_err" >> "$partial_failures";
  fi`.
- **Source:** V1 §9.6 partial-write contract; V3.3 §5.6 "no silent
  retry / no silent fallback".

### Finding F11
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-links.sh:135` (function name)
- **Title:** `tracker_links_validate_pair_type` validates id shapes,
  not pair types
- **Description:** The function name says "validate_pair_type" and
  the docstring (line 119-126) references "the six entity-pair
  types from V3.3 §5.1". But the implementation only checks each id's
  shape independently via `_tlk_is_valid_pack_id` — it does NOT enforce
  that the (src-shape, tgt-shape) pair matches one of the 6 documented
  pair types from V3.3 §5.1. For example, `BD-NNN ↔ BD-NNN` would
  pass validation but is not in the §5.1 pair list. (V3.3 §5.1's pair
  list is descriptive, not restrictive — the provider's `link()` is
  cross-type per V1 §2.1 — so accepting BD↔BD is not a correctness
  issue. The naming/docstring drift is the issue.)
- **Suggested fix:** Either (a) rename to
  `tracker_links_validate_id_shapes` (more accurate to behavior), OR
  (b) add explicit pair-type matrix enforcement (more strict). Option
  (a) is simpler and matches V3.3 §5.1's "uniform model" framing.
- **Source:** Internal consistency between function name and
  behavior; V3.3 §5.1 entity-pair table.

### Finding F12
- **Severity:** NIT
- **Location:** `tracker.toml.pack-example`,
  `project-template/tracker.toml.project-example`
- **Title:** Example tracker.toml files do not document the new
  `[graph] cycle_check_k` field
- **Description:** BD-108 introduces an additive `[graph] cycle_check_k`
  field in tracker.toml. The two example files that ship to clients
  (greppable proof: `grep -l "cycle_check_k\|graph\]"
  tracker.toml.pack-example
  project-template/tracker.toml.project-example` → 0) do not contain
  the new section, even as a commented-out line. Users who want to
  tune K cannot discover the field from the canonical example. The
  default (10) does work without setting the field, so this is purely
  a discoverability issue.
- **Suggested fix:** Add a commented `[graph]` block to both example
  files explaining the field and its default. Pattern:
  ```
  # [graph]
  # cycle_check_k = 10  # K-hop bound for link-creation cycle check (V3.3 §5.5)
  ```
  Optional: extend `_validate_tracker_toml` in `scripts/validate-pack.py`
  to validate the type if present, but this is optional (additive
  field, no required-key check needed).
- **Source:** Pack memory: examples ship via `init-project.sh`;
  schema-drift between examples and the live `tracker_config_get`
  reader propagates breakage to every fresh install.

## Coverage notes

**Reviewed:**
- The full BD-108 diff (`git show aae4712`) — 11 files / +1962 / -7.
- New libraries (`tracker-links.sh` 340L, `tracker-cycle-check.sh` 332L)
  end-to-end, including header docs, function bodies, error paths, and
  the embedded Python BFS.
- Migrator extensions: forward step 6+7 case-statement reorder, new
  step 7b phase-task replay, reverse `_tmr_decode_blockers` D-21
  restriction.
- METHODOLOGY edits across 3 surgical locations.
- Test scripts (`test-tracker-links.sh` 308L / 43 assertions;
  `test-tracker-cycle-check.sh` 309L / 21 assertions). Both run
  locally — confirmed PASS via `bash scripts/tests/test-tracker-*.sh`.
- BD-106 surface usage: confirmed `tracker_phase_task_parse` is
  called with the BD-106 contract (`{phases:[{tasks:[{pack_id,
  dependencies:[{kind, target, annotation}]}]}]}`). The lazy-source
  pattern in step 7b mirrors existing tracker-config / tracker-errors
  conventions.
- Provider-op + capability-flag confirmation: greppable evidence that
  `provider_link` is the only provider operation called; no
  `provider_capabilities` reads were added.
- Cycle-detection algorithm: traced the K-boundary semantics for
  K=10 (test 4.1 distance-9 detects, test 4.2 distance-11 misses,
  test 4.3 K=20 catches). Algorithm is sound; only the header
  rationale comment is wrong (Finding F6).
- Round-trip identity claim: re-ran the SHA-256 check via
  `bash scripts/tests/test-tracker-links.sh` — 4.1 (BACKLOG) and
  4.2 (IMPLEMENTATION-PLAN) both PASS.
- Validate-pack alignment: confirmed the existing
  `_validate_tracker_toml` does not need to change (the new `[graph]`
  field is additive and not required; the validator would not
  produce false positives).
- Trinity rule: BD-108 makes no edits to CLAUDE.md / AGENTS.md /
  GEMINI.md (pack-repo or project-template copies). Trinity N/A.
- Pack memory: agents-never-commit confirmed (HEAD unchanged at the
  time of report write); commit-message format `feat: v11 — BD-108
  ...` matches the standing rule; CHANGELOG was not touched (correct,
  per "version-tag boundaries only").

**Intentionally deferred:**
- BD-107 source files (`scripts/lib/tracker-promote.sh`,
  `scripts/pack-td.sh`, the three `test-tracker-promote-*.sh`
  scripts) — explicitly excluded per scope; they are present
  on-disk but untracked relative to the BD-108 commit.
- Other `PACK-REVIEW-*.md` reports — explicitly excluded per scope
  (parallel reviewer experiment; would bias this review).
- `maintenance-docs/v11-research/RESEARCH-*.md` and per-entry-shape
  archive files — out of scope.
- §6.P / §6.Q / §6.R MAINTAINER CHECK ratification status — per
  scope, treated as `recommendation (a) implemented`, not as an
  architecture gap. §6.Q's RESOLVED-RATIFIED flip in
  IMPLEMENTATION-PLAN-ADDENDUM-4.md is pure PM-only doc bookkeeping
  and not a coder/reviewer responsibility.

**Not reviewed:**
- BD-106 internal correctness (only its public surface as consumed
  by BD-108). Per scope.
- README.md Repository Layout staleness — BD-106 also did not update
  the README, so this is a batch-pattern concern, not BD-108-
  specific. The Repository Layout section currently lists
  `tracker-{config,init,labels,errors,sidecar,mirror,agent-read}.sh`
  but omits `tracker-links.sh`, `tracker-cycle-check.sh`,
  `tracker-phase-task.sh`, `tracker-migrate-{forward,reverse}.sh`,
  `tracker-provider*.sh`, `tracker-header-snapshot.sh`. A v11-cut-
  time pass would address this in one commit.
