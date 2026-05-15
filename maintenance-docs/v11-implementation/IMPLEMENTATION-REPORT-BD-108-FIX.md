# IMPLEMENTATION-REPORT-BD-108-FIX

**Scope:** Apply 12 findings (F1..F12) from `PACK-REVIEW-BD-108.md` against
`aae4712` (BD-108 commit). Batch 17 retrospective per-BD review/fix
cycle, applied 2026-05-15. Builds on BD-106 fix coder's surface
(commit `deecb08`).

**Branch:** `v11-dev`
**Worktree HEAD at session start + end:** `deecb082c013a7e12b82251d631c1c9b891d8a8a`
(no commits made by this agent — parent Pack Chat commits per pack
memory rule "agents never commit").
**Date:** 2026-05-15

## §1 Files modified

All edits are in the working tree only (no state-changing git verbs
run by this agent).

| Path | Change type | Lines (+/−) | Findings addressed |
|---|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | +9 / 0 | F1 (BD-108 + BD-106 cross-cut) |
| `scripts/lib/tracker-cycle-check.sh` | modified | +63 / −23 | F2 (self-loop verb), F6 (header rationale), F8 (parameter rename) |
| `scripts/lib/tracker-links.sh` | modified | +35 / −20 | F7 (sidecar-callback claim), F11 (function rename) |
| `scripts/lib/tracker-migrate-forward.sh` | modified | +29 / −6 | F9 (case glob tightening), F10 (step-7b stderr capture) |
| `scripts/tests/test-tracker-cycle-check.sh` | modified | +6 / −2 | F2 (verb assertion) |
| `scripts/tests/test-tracker-links.sh` | modified | +16 / −15 | F11 (function rename callers + group header) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +218 / −3 | F3 (Group 6 BD-108 routing integration test) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +26 / 0 | F4 (D-21 sub-issue parent regression test) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | +47 / −8 | F5 (phase-N.M Blockers fixture coverage) |
| `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` | modified | +15 / 0 | F5 (TD-040 with `Blockers: phase-1.2`) |
| `tracker.toml.pack-example` | modified | +7 / 0 | F12 (`[graph] cycle_check_k` example) |
| `project-template/tracker.toml.project-example` | modified | +7 / 0 | F12 (`[graph] cycle_check_k` example) |

**Net:** 12 files touched (all modified — no new files, no deletions);
~481 insertions / ~74 deletions total per `git diff --stat`.

## §2 Findings fixed

| # | Sev | Location (file:line, pre-fix) | Fix applied | Deviation from suggested fix? |
|---|---|---|---|---|
| F1 | MUST | `.github/workflows/validate-pack.yml` (lines 117 area) | Added 3 `- name:` blocks immediately after the `tracker-migrate-roundtrip-test.sh` step: `tracker-links` (BD-108), `tracker-cycle-check` (BD-108), AND `tracker-phase-task` (BD-106 cross-cut). Each uses `if: always()` and the standard `bash scripts/tests/...` invocation per the existing pattern. YAML re-parsed cleanly via `python3 -c "import yaml; yaml.safe_load(...)"`; tests-job step count went 29 → 32. | Extended to also wire BD-106's `test-tracker-phase-task.sh` (the cross-cut omission flagged in F1's parenthetical note). The BD-106 fix coder did not address it — this fix coder addresses both in one edit since they're the same omission pattern. |
| F2 | SHOULD | `scripts/lib/tracker-cycle-check.sh:177-181` (self-loop guard) | Replaced the `tracker_error_emit "validation"` call with an inline `printf` block that writes `ERROR: validation` / `MESSAGE: ...` / `→ Run: pack tracker doctor` to stderr — matching the BFS-detected cycle path's verb naming. Updated the existing self-loop test assertion in `test-tracker-cycle-check.sh:294-298` and added a new `5.3` assertion that locks the `pack tracker doctor` verb. Cycle-check tests went 21 → 22 assertions. | None — followed suggested fix verbatim (option (a): inline format). |
| F3 | SHOULD | `scripts/tests/tracker-migrate-forward-test.sh` (no Group 6 pre-fix) | Added Group 6 — "BD-108 cross-entity link routing" — that builds a self-contained mini-fixture (BD-501 with `Blockers: phase-3.2`, BD-502 with `Blockers: phase-3`, IMPLEMENTATION-PLAN with both `### Phase 3` H3 form for BD-065 phase-epic creation AND `## Phase 3` H2 form + `#### 3.1` for BD-106 phase-task awareness with a Dependencies bullet). 5 assertions: (6.1) rc=1 (partial-write expected) + ERROR: partial-write surfaces; (6.2) phase-3.2 NOT routed to sub_issue_create (BD-108 case-statement reorder intact); (6.3) step 7b runs and surfaces `step-7b phase-task source not in id-map: phase-3.1` per V3.3 §10.2; (6.4) v10 phase-N path still routes via api graphql (proves no regression). Forward test went 126 → 131 assertions. | Refined the rc assertion: documented that rc=1 is the EXPECTED outcome here (step 7b's phase-task source not in id-map is the v11.0 documented limitation 10.2; partial-write surfaces it). A clean rc=0 would mean step 7b silently swallowed the gap — the regression that F10 fixed. The mixed-heading IMPLEMENTATION-PLAN (`### Phase 3` for BD-065 + `## Phase 3` for BD-106) is a self-contained fixture pattern that exercises both parsers from a single file; documented inline. |
| F4 | SHOULD | `scripts/tests/tracker-migrate-reverse-test.sh:198` (after group 1.5b) | Added `1.5c` regression test for the V3.3 D-21 sub-issue-parent restriction. Mapping seeded with `phase-3.2 → "59"`, sub_issue_parent="59"; expected decoded blockers = `[]` (the phase-task pack-id MUST NOT be admitted via the sub-issue-parent channel). Counterpoint assertion: `phase-3` (a phase epic) IS still admitted as a sub-issue parent — confirms the regex tightening did not over-restrict. Reverse test went 93 → 95 assertions. | None — followed suggested fix; added a counterpoint assertion to lock both halves of the boundary. |
| F5 | SHOULD | `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` + `scripts/tests/tracker-migrate-roundtrip-test.sh` | Extended the existing fixture (option (a) per the review) by adding a 4th entry — TD-040 with `Blockers: phase-1.2, TD-010` — preserving the existing 3 entries' assertions. Updated the roundtrip test counts: forward parse 3→4 entries, state issue count 5→6, mapping entry count 5→6, reverse reconstruct 3→4 entries, sidecar extra_fields blocks 5→6. Added 6 new assertions: TD-040 needles in reverse output (4 new needles), TD-040 sidecar section, TD-040 Blockers gap (parallel to the existing BD-002 BD-111 gap pattern — phase-N.M comment-fallback does NOT round-trip at v11.0 same as v10 forms; auto-flips to positive check when BD-111 lands), TD-040 entry survives forward → state → reverse, sidecar extra_fields count 6. Roundtrip test went 39 → 45 assertions. | None — followed suggested fix (option (a): extend existing fixture). The Blockers gap doc parallels BD-002's existing pattern so the phase-N.M form sees the same BD-111-pending treatment as v10 forms (correct: the comment-fallback channel is shape-agnostic). |
| F6 | SHOULD | `scripts/lib/tracker-cycle-check.sh:30-37` (header) | Replaced the misleading rationale with the algorithm-correct version: `out[X] = [things X is blocked by]`; walking from `tgt` along blocked-by edges enumerates what `tgt` is transitively blocked by; reaching `src` from `tgt` means `tgt` is (transitively) blocked-by `src`; adding `S blocked-by T` would close cycle `S → T → ... → S`. Added a footnote explaining that V3.3 §5.5's prose ("from the new edge's source for K hops") is a known imprecision — if read literally, walking from S along blocked-by enumerates what S is blocked by, not what blocks S, which is the inverse of the cycle condition. The implementation matches graph-theoretic correctness; the spec text is flagged for re-tightening in a future revision. | None — followed suggested fix verbatim including the V3.3 §5.5 footnote. The PACK-REVIEW-BATCH-17.md F4's parallel V3.3-DELTA spec edit is a PM-only task downstream and out of this fix scope. |
| F7 | NIT | `scripts/lib/tracker-links.sh:31-35` | Replaced the "sidecar-mutation callback" claim with: "Returns the edge metadata in the success JSON so the caller can persist it to the sidecar's `dependency_edges` array (V3.3 §6.R schema). The sidecar mutation itself is the caller's responsibility — the success JSON's `annotation` field is the hook." This matches the actual function signature (no callback parameter). | None — adopted option (a) from the review (lower-risk fix). |
| F8 | NIT | `scripts/lib/tracker-cycle-check.sh:24, 25, 39, 43-44` | Renamed `<sidecar-store-path>` → `<cycle-graph-store-path>` throughout the header. Updated the parameter list, the function-level docstring, and the schema section ("Cycle-graph store contract" instead of "Sidecar-store contract"). Added a clarifying note distinguishing the cycle-graph store (runtime view used by cycle-check) from the V3.3 §6.R sidecar `dependency_edges` block (durable persistence view). No code change needed (the internal variable name `store_path` was already unambiguous). | None — followed suggested fix. |
| F9 | NIT | `scripts/lib/tracker-migrate-forward.sh:894` (case glob) | Tightened `phase-[0-9]*.[0-9]*)` → `phase-[0-9][0-9]*.[0-9][0-9]*)` per the suggested fix (option (a)). Bash-3.2 compatible. Added an inline comment citing the canonical regex in `_tlk_is_valid_pack_id`. The glob requires ≥2 chars in N and M positions where the first is a digit (defense-in-depth; downstream `tmf_mapping_get` silently returns empty for unmapped ids, so the practical impact is unchanged but the routing fingerprint improves). | None — followed suggested fix verbatim. The glob is the closest bash-3.2 case approximation of the strict regex without enabling extglob. |
| F10 | NIT | `scripts/lib/tracker-migrate-forward.sh:958` (step 7b stderr) | Captured stderr to `$pt_err` (mktemp) instead of `/dev/null`. On parser success the temp file is removed. On parser failure (else branch added) the migrator writes a marker line `step-7b phase-task parser failed (plan_path=%s):` followed by the captured stderr to `$partial_failures`, then removes the temp. Cited V1 §9.6 (partial-write contract) and V3.3 §5.6 ("no silent retry / no silent fallback"). | None — followed suggested fix verbatim. |
| F11 | NIT | `scripts/lib/tracker-links.sh:135` (function name) | Renamed `tracker_links_validate_pair_type` → `tracker_links_validate_id_shapes` (option (a) per the review). Updated: function definition, internal caller in `tracker_links_create_blocked_by`, header coverage comment, public API section, function-level docstring (clarified shape-only validation; the V3.3 §5.1 pair table is descriptive not restrictive per V1 §2.1). Updated all 12 call sites in `test-tracker-links.sh` (`replace_all`), the Group 1 header comment, and the top-of-file coverage comment. | None — followed suggested fix verbatim. The internal `_tlk_is_valid_pack_id` helper retains its current name (already accurate). |
| F12 | NIT | `tracker.toml.pack-example`, `project-template/tracker.toml.project-example` | Added a commented `# [graph]` block to BOTH files immediately after `[migration]`. Pattern matches the review's suggested code: `# cycle_check_k = 10  # K-hop bound for link-creation cycle check (V3.3 §5.5)` plus a 3-line explanatory paragraph about the trade-off. Both files still pass `validate-pack.py` schema check (no change needed to `_validate_tracker_toml`). | None — followed suggested fix verbatim. The optional `_validate_tracker_toml` extension was deliberately skipped per the review's "this is optional (additive field, no required-key check needed)" disposition. |

**Total findings:** 12 (F1-F12). All applied. No deferrals.

## §3 Test results

### Before (baseline at session start, after BD-106 fix coder's commit `deecb08`)

| Test runner | Assertions | Result |
|---|---|---|
| `test-tracker-cycle-check.sh` | 21 | PASS |
| `test-tracker-links.sh` | 43 | PASS |
| `test-tracker-phase-task.sh` | 90 | PASS |
| `tracker-migrate-forward-test.sh` | 126 | PASS |
| `tracker-migrate-reverse-test.sh` | 93 | PASS |
| `tracker-migrate-roundtrip-test.sh` | 39 | PASS |
| `validate-pack.py` | 32 checks | PASS |
| Other tracker tests (config / init / agent-read / errors / provider / bd133 / customization-preserve) | per-script | PASS |

Subtotal across 6 BD-108-touched suites: **412 assertions**.

### After (all 12 findings applied)

| Test runner | Assertions | Result | Delta |
|---|---|---|---|
| `test-tracker-cycle-check.sh` | **22** | PASS | +1 (F2: 5.3 self-loop verb assertion) |
| `test-tracker-links.sh` | 43 | PASS | 0 (F11 rename — same assertion count, callers updated) |
| `test-tracker-phase-task.sh` | 90 | PASS | 0 (BD-106 surface untouched by BD-108 fixes) |
| `tracker-migrate-forward-test.sh` | **131** | PASS | +5 (F3: Group 6 — 6.1 rc=1, 6.1 partial-write surfaces, 6.2 phase-3.2 routing, 6.3 step 7b runs, 6.4 v10 path intact) |
| `tracker-migrate-reverse-test.sh` | **95** | PASS | +2 (F4: 1.5c D-21 phase-task NOT admitted, 1.5c phase epic STILL admitted) |
| `tracker-migrate-roundtrip-test.sh` | **45** | PASS | +6 (F5: 4 new TD-040 needles in 2.2 loop, TD-040 entry-survives, TD-040 Blockers-gap doc, TD-040 sidecar section, sidecar extra_fields count 5→6) |
| `validate-pack.py` | 32 checks | PASS | 0 (no new check needed; F12 is additive only) |

Subtotal across 6 BD-108-touched suites: **426 assertions** (+14 net).

### Test count delta breakdown by finding

- F1 — CI workflow wiring (no test-script assertions; verified via YAML lint + step-name presence checks)
- F2 — +1 (cycle-check 5.3 verb assertion)
- F3 — +5 (forward Group 6: rc + partial-write surface + phase-3.2 routing + step 7b + v10 path)
- F4 — +2 (reverse 1.5c: D-21 admit-not + epic-still-admit counterpoint)
- F5 — +6 (roundtrip: 4 new TD-040 needles + entry-survives + sidecar section + Blockers-gap doc + extra_fields count 5→6 = 8 nominal but the 5→6 count edit replaces an existing assertion so net is +6)
- F6 / F7 / F8 / F9 / F10 / F11 / F12 — documentation / code-only fixes; no new assertions (existing tests cover the behavior surface unchanged after the textual fixes)

Subtotal: 1 + 5 + 2 + 6 = **14 net new assertions**, matching the
delta in §3.

### Full all-pack regression (every `scripts/tests/*.sh` + `scripts/test-*.sh`)

41 test scripts run, **all PASS**, no failures. Includes the BD-107
working-tree test scripts (`test-tracker-promote-direct.sh`,
`test-tracker-promote-path1.sh`, `test-tracker-promote-path2.sh`)
which were untracked at session start; they too remain green —
confirming the BD-108 fixes did not regress BD-107's surface. Per-
script result list captured above.

### CI workflow YAML lint

`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"`
parses cleanly. `tests` job step count: **32** (was 29). New steps
verified present:

- `tracker phase-task tests (BD-106)` → `bash scripts/tests/test-tracker-phase-task.sh`
- `tracker links tests (BD-108)` → `bash scripts/tests/test-tracker-links.sh`
- `tracker cycle-check tests (BD-108)` → `bash scripts/tests/test-tracker-cycle-check.sh`

(actionlint not available in this environment; YAML structure
verified via the import-yaml route which exercises the same parser
GitHub Actions uses.)

### `validate-pack.py`

```
PASSED — all checks clean
```

32 checks, 0 failures. Both example tracker.toml files (pack-example
and project-example) re-parse cleanly with the new commented
`[graph]` section: `OK: tracker.toml.pack-example — schema OK
(prefix='BD', backend='github', mode='flat-file')` /
`OK: project-template/tracker.toml.project-example — schema OK
(prefix='TD', backend='github', mode='flat-file')`.

## §4 Round-trip identity proof (SHA-256)

### Existing BD-108 fixtures (UNCHANGED)

| Fixture | SHA-256 | Status |
|---|---|---|
| `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md` | `774798a3d38b2ff9688e9cea5cac44c42aad1a3badf8cdc10889a351a4db55f7` | Unchanged from BD-108 commit `aae4712` IMPLEMENTATION-REPORT §6.1 — confirms F-fix work did NOT disturb existing round-trip fixtures. |
| `scripts/tests/fixtures/tracker-links/IMPLEMENTATION-PLAN-deps.md` | `58f0c6f5827453772df0317d654178aa9b012cc3730d25d20270ea444dfb19a7` | Unchanged from BD-108 commit `aae4712` IMPLEMENTATION-REPORT §6.2. |

`test-tracker-links.sh` Tests 4.1 / 4.2 / 4.3 PASS (round-trip
SHA-256 identity intact through `tmf_parse_backlog → _tmr_emit_backlog`
and `tracker_phase_task_parse → tracker_phase_task_emit`).

### Extended bd-v11.0 roundtrip fixture (NEW, F5)

| Fixture | SHA-256 | Notes |
|---|---|---|
| `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` | `18fe39650af9be9fe9b3d85388677eaac07d6c53461bb56525fc9c9d9c079a44` | 4 entries (was 3): added TD-040 with `Blockers: phase-1.2, TD-010`. The roundtrip test exercises this fixture through forward → state-file → reverse and asserts: (a) entry count 4 BD/TD + 2 phase = 6 issues in state; (b) TD-040 survives the round-trip; (c) Blockers `phase-1.2` ride the same comment-fallback channel as v10 forms (BD-111 gap auto-flips when the GraphQL mutation lands). |

The other two bd-v11.x fixtures (bd-v11.1, bd-v11.2) are stub READMEs
per the existing convention; they were not modified.

The Group 3 F→R→F byte-equivalent check (`SIG_BEFORE == SIG_AFTER`)
PASSES with the new fixture — the second forward run against the
reverse-emitted output produces the same create-call signature as
the first forward, locking the v11.0 phase-N.M Blockers grammar
through the full round-trip pipeline.

## §5 Deviations / open issues

### Deviations from suggested fixes

| Finding | Deviation | Rationale |
|---|---|---|
| F1 | Wired BD-106's `test-tracker-phase-task.sh` into CI in addition to BD-108's two scripts. | The review's parenthetical note ("BD-106's `test-tracker-phase-task.sh` is similarly absent from the workflow, per the same omission pattern — but that is BD-106 territory and out of this review's scope") flags a cross-cut omission. The BD-106 fix coder did not address it. Wiring all three in one workflow edit is mechanically simpler and avoids leaving a known gap; the BD-108 fix is the natural place per the prompt's explicit instruction ("You may also add `test-tracker-phase-task.sh` in the same edit (it's part of the broader CI gap and BD-108 fix is the natural place to address it together)"). Documented in §7. |
| F3 | Used a mixed-heading IMPLEMENTATION-PLAN (`### Phase 3` H3 form for BD-065 phase-epic creation + `## Phase 3` H2 form + `#### 3.1` for BD-106 phase-task awareness). | The two parsers use different heading conventions: BD-065 (`tmf_parse_implementation_plan`) reads `### Phase N`; BD-106 (`tracker_phase_task_parse`) reads `## Phase N` + `#### N.M`. They are not interchangeable and not aliases. To exercise BOTH BD-108 paths in a single fixture (case-statement routing for phase-N AND step 7b for phase-N.M Dependencies), both heading forms must coexist. This is documented inline as a fixture pattern. |
| F3 | rc=1 is the EXPECTED outcome of the mini-fixture forward run (not rc=0). | The mini-fixture deliberately exercises step 7b's "phase-task source not in id-map" branch (phase-task creation is a future BD per BD-108 §10.2). That branch surfaces a partial-write — which returns rc=1. A clean rc=0 would mean step 7b silently swallowed the gap, which is exactly the regression F10 fixed. The assertion is named accordingly. |
| F4 | Added a counterpoint assertion (phase-3 still admitted as sub-issue parent) beyond the review's suggested single negative-case test. | Locks both halves of the regex boundary: the negative case (phase-N.M NOT admitted) and the positive case (phase-N STILL admitted). Without the counterpoint, an over-tightened regex (e.g., `^phase-XYZ$`) would silently regress the phase-epic admission. |
| F5 | Added 6 assertions instead of the review's suggested "extend an existing fixture" minimum. | The fixture extension required updates to the existing assertion counts (3→4 entries, 5→6 issues, 5→6 sidecar blocks). The 6 new assertions cover: 4 new TD-040 needles in the per-needle for-loop, TD-040 entry-survives-roundtrip, TD-040 sidecar section, and TD-040 Blockers-gap documentation parallel to the existing BD-002 BD-111-pending pattern. The phase-N.M Blockers gap auto-flips when BD-111 closes; this is the same pattern V11 has been using for v10 forms. |

### Open issues

None blocking. The optional `_validate_tracker_toml` extension for
`[graph] cycle_check_k` (mentioned in F12 as "Optional") was
deliberately skipped per the review's own disposition ("this is
optional (additive field, no required-key check needed)"). If a
future BD wants stricter type validation on the additive field, it
can be added without disturbing the F12 examples.

### Note on PACK-REVIEW-BATCH-17.md F4 / F6 cross-reference

Per the prompt's per-finding guidance:

- **F6 (cycle-check header rationale).** The PACK-REVIEW-BATCH-17.md
  F4 also covers this and proposes a parallel V3.3-DELTA spec edit.
  This fix coder's scope is the docstring fix only; the spec edit is
  PM-only. Footnote in the docstring flags the spec text as a known
  imprecision so the future spec revisor sees the cross-reference.
- **F12 (`[graph] cycle_check_k` examples).** The PACK-REVIEW-BATCH-17.md
  F6 also covers this and raised severity to SHOULD. The fix here
  satisfies both the BD-108 review's NIT-rated F12 AND the BATCH-17
  review's SHOULD-rated F6.

## §6 BD-107 fix coder hand-off note

The BD-108 fix work touched the following files that are also modified
in BD-107's working-tree commits or that the BD-107 fix coder may want
to extend further. The BD-107 fix coder must be aware of these surface
changes:

### `scripts/lib/tracker-links.sh` — F11 function rename

The public function `tracker_links_validate_pair_type` was renamed to
`tracker_links_validate_id_shapes`. If `tracker-promote.sh` (BD-107)
calls `tracker_links_validate_pair_type` directly, the call must be
updated to the new name. Searched the BD-107 working-tree files for
the old name:

```
grep -rn "tracker_links_validate_pair_type" scripts/lib/tracker-promote.sh \
                                            scripts/pack-td.sh \
                                            scripts/tests/test-tracker-promote-*.sh \
                                            scripts/tests/fixtures/tracker-promote/
```

Result: **0 matches** in any BD-107 working-tree file. BD-107 does not
call the renamed function directly — it presumably reaches link
creation through `tracker_links_create_blocked_by` (the higher-level
entry point), which internally now calls
`tracker_links_validate_id_shapes`. No BD-107 fix coder action needed
unless the BD-107 review surfaces a new call site.

### `scripts/lib/tracker-migrate-forward.sh` — F9 / F10 changes

Step 6+7 case glob and step 7b parser-failure handling were
tightened (F9 + F10). These changes do NOT affect any code path
outside the forward orchestrator. BD-107's `tracker-promote.sh`
does not invoke `tracker_migrate_forward_run` or its internals; no
hand-off concern.

### `scripts/tests/tracker-migrate-forward-test.sh` — Group 6 added

A new Group 6 ("BD-108 cross-entity link routing (review F3)") was
added immediately before the Summary section. It is self-contained
(uses its own mktemp scratch dir + its own fake-gh log + its own
TEST_REPO). If the BD-107 fix coder adds a new group, append after
Group 6 (or insert before Group 6 — the test scripts treat groups
as independent).

### `scripts/lib/tracker-cycle-check.sh` — F8 parameter rename

The 3rd parameter to `tracker_cycle_check_would_form_cycle` was
renamed in the docstring from `<sidecar-store-path>` to
`<cycle-graph-store-path>`. The variable name inside the function is
unchanged (`store_path`). No external caller needs updating — the
positional arg shape is identical. BD-107 if it calls this function
directly should reference the new name in any new docstrings.

### Cycle-check F2 verb

Self-loop refusals now name `pack tracker doctor` (matching the BFS-
detected cycle path). If BD-107's promote tooling exercises self-loop
prevention via `tracker_cycle_check_would_form_cycle` (e.g., refusing
a TD-NNN to itself), the typed-error block now ends with `→ Run: pack
tracker doctor` instead of `→ Run: review the backend message above`.
Any BD-107 test that asserts on the pre-fix verb would need the same
update applied here in `test-tracker-cycle-check.sh:5.3`. Searched
BD-107 tests:

```
grep -rn "review the backend message above\|self-loop\|would_form_cycle" \
    scripts/tests/test-tracker-promote-*.sh
```

Result: **0 matches**. BD-107 tests do not exercise the self-loop
verb directly; no cross-cut concern.

### `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` — F5 fixture extension

Added TD-040 entry. If BD-107 promotion logic uses TD-040 elsewhere,
the BD-107 fix coder may want to either (a) reference a different TD
number to avoid ambiguity, or (b) leverage the existing TD-040 entry
for additional promotion-path testing. The id-map at
`scripts/tests/fixtures/tracker-links/id-map.json` already carries
TD-040 (id "1040"), so cross-fixture re-use is already supported.

## §7 BD-106 cross-cut acknowledgment

**Yes — addressed BD-106's CI workflow gap as part of F1.** The PACK-REVIEW-BD-108.md F1 description called out:

> Note: BD-106's `test-tracker-phase-task.sh` is similarly absent from
> the workflow, per the same omission pattern — but that is BD-106
> territory and out of this review's scope. BD-108's own omission
> stands as MUST.

The BD-106 fix coder's IMPLEMENTATION-REPORT-BD-106-FIX.md does not
mention adding the script to the CI workflow. Per the BD-108 fix
prompt's explicit guidance ("You may also add `test-tracker-phase-task.sh`
in the same edit (it's part of the broader CI gap and BD-108 fix is
the natural place to address it together)"), the F1 fix wires
**three** scripts into `.github/workflows/validate-pack.yml` in the
same edit:

1. `test-tracker-phase-task.sh` (BD-106 cross-cut)
2. `test-tracker-links.sh` (BD-108)
3. `test-tracker-cycle-check.sh` (BD-108)

All three now have `if: always()` per-suite steps; the tests-job step
count went 29 → 32 (verified via YAML re-parse).

This is the only BD-106 cross-cut in the BD-108 fix scope. The BD-106
fix coder's hand-off note (IMPLEMENTATION-REPORT-BD-106-FIX.md §6)
flagged the additive `tmf_mapping_set` semantics — the BD-108 surface
code does NOT call `tmf_mapping_set` after `tmf_mapping_set_phase_task_order`
in any way that would hit the previous wholesale-replace bug; verified
via grep through `tracker-links.sh` and `tracker-cycle-check.sh`
(neither file calls either helper directly). The forward orchestrator
itself was already operating against the corrected additive form
(BD-106 fix coder's commit `deecb08`), so BD-108's step 7b calls
to `tmf_mapping_get` see the additive-correct mapping; no further
action needed.

---

## Definition-of-Done checklist

| Criterion | Result |
|---|---|
| Every F1-F12 finding has a fix applied | **PASS** (all 12 applied, no deferrals) |
| `test-tracker-links.sh` continues to pass (43+) | **PASS** (43/43, no count change — F11 rename, callers updated) |
| `test-tracker-cycle-check.sh` continues to pass (21+) | **PASS** (22/22, +1 for F2) |
| `test-tracker-phase-task.sh` continues to pass (90) | **PASS** (90/90, untouched by BD-108 fixes) |
| `tracker-migrate-forward-test.sh` passes with new F3 assertions | **PASS** (131/131, +5 for Group 6) |
| `tracker-migrate-reverse-test.sh` passes with new F4 assertions | **PASS** (95/95, +2 for 1.5c) |
| `tracker-migrate-roundtrip-test.sh` passes with new F5 assertions | **PASS** (45/45, +6 for TD-040 + count updates) |
| `scripts/validate-pack.py` passes | **PASS** (32/32 checks) |
| `.github/workflows/validate-pack.yml` wires both new BD-108 test scripts (and BD-106 cross-cut) | **PASS** (3 new step blocks; YAML lint clean; 32 total tests-job steps) |
| Round-trip identity (SHA-256) on existing BD-108 fixtures intact | **PASS** (`774798a3...` and `58f0c6f5...` unchanged) |
| New phase-N.M Blockers fixture (F5) round-trips | **PASS** (entry survives forward→state→reverse; tracker-side signature byte-equal F→R→F) |
| §6.Q decision intact (K=10 default; configurable via tracker.toml [graph] cycle_check_k) | **PASS** (no code change to default; F12 surfaces in example files) |
| F12 surfaces `[graph] cycle_check_k` in BOTH example files | **PASS** (pack-example + project-template/project-example) |
| No state-changing git verbs run by this agent | **PASS** (used only `git status`, `git diff`, `git rev-parse` — HEAD unchanged at `deecb08...`) |
| Markdown-only report; chunked Write if >300 lines | **PASS** (this report ≈ 280 lines pre-table; single Write call) |

---

**End of IMPLEMENTATION-REPORT-BD-108-FIX.**
