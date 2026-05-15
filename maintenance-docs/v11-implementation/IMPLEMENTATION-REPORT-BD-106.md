# IMPLEMENTATION-REPORT-BD-106 — Phase task entity model + identifier scheme + parser/emitter + label family

- Branch: `v11-dev`
- Pre-flight HEAD: `ef525c1e5e149387cfb35c704afa3a623eda40e7`
- Final worktree HEAD (no commits made by agent): `ef525c1e5e149387cfb35c704afa3a623eda40e7`
- Status flip: BACKLOG.md is PM-only; flip is performed by Pack Chat at commit time per pack workflow rule.

## §1 Files changed inventory

| Path | Change | Lines |
|---|---|---|
| `scripts/lib/tracker-phase-task.sh` | NEW | 516 |
| `scripts/lib/tracker-sidecar.sh` | MODIFIED (+113 / -6) | extends header docstring + adds `tracker_sidecar_compose_phase_tasks_block` helper |
| `scripts/lib/tracker-labels.sh` | MODIFIED (+60 / -6) | extends header + adds `tracker_labels_derived_from` / `tracker_labels_promoted_to` helpers |
| `scripts/lib/tracker-migrate-forward.sh` | MODIFIED (+55 / -0) | adds `tmf_mapping_set_phase_task_order` / `tmf_mapping_get_phase_task_order` |
| `scripts/lib/tracker-migrate-reverse.sh` | MODIFIED (+57 / -0) | adds `_tmr_phase_task_order` helper |
| `scripts/tests/test-tracker-phase-task.sh` | NEW | 338 |
| `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md` | NEW (fixture) | 54 |
| `scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP.md` | NEW (fixture) | 31 |

PM-only files NOT touched (per scope constraints): BACKLOG.md, CHANGELOG.md, README.md, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md, AGENTS.md, GEMINI.md, EXECUTION-PLAN-V11.0.md, RELEASE-GATE.md, V3.x architecture docs.

BD-107 / BD-108 surface NOT touched (out of scope per prompt): no `tracker-promote.sh`, no `tracker-links.sh`, no `tracker-cycle-check.sh`, no METHODOLOGY.md edits, no `pack-tracker.sh` verb additions.

## §2 Helper file structure decision (planner-deferred → resolved)

**Decision: single file `scripts/lib/tracker-phase-task.sh`** combining parser + emitter + grammar helpers.

**Rationale.**
- Parse and emit operate on the *same grammar surface* (METHODOLOGY § Part 4 + V3.3 §4.1/§4.2). The bullet-name normalization, the `phase-N.M` regex, and the `Dependencies` entry regex (V3.3 §5.3) live in one place — splitting would require duplicating the regex in two files (drift risk) or adding a third "common" file (overhead with no payoff at this size).
- The existing `tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` split is justified by their *disjoint algorithms* — forward = create issues + checkpoint cadence + close-retry; reverse = canonical-Issue-JSON walk + reconstruct. BD-106's parse/emit are the same shape on opposite directions and stay co-located.
- The existing `tracker-sidecar.sh` is single-file with both kinds of helpers (canonical emit + per-block extension hooks) — sets the precedent for combining direction-paired helpers.
- File size at 516 lines is well within the maintainable range for the codebase (compare: `tracker-migrate-forward.sh` ~1200 lines, `tracker-migrate-reverse.sh` ~900 lines).

The split-file option remains available for a future BD if the file grows past ~800 lines or if BD-108 / BD-107 add asymmetric content that breaks the parse/emit symmetry.

## §3 Sidecar `phase_tasks` block schema (V3.3 §4.3)

The composer `tracker_sidecar_compose_phase_tasks_block` emits this schema (sample produced from the `IMPLEMENTATION-PLAN.md` fixture):

```yaml
phase_tasks:
  phase-3:
    task_order: [3.1, 3.2, 3.3]
    tasks:
      phase-3.1:
        title: Schema bootstrap
        parent_phase: phase-3
        dependency_edges:
          - kind: blocked-by
            target: phase-2.4
            annotation: (must complete migration scaffold first)
          - kind: blocked-by
            target: TD-029
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
      phase-3.2:
        title: Reverse emitter
        parent_phase: phase-3
        dependency_edges:
          - kind: blocked-by
            target: phase-3.1
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
  phase-4:
    task_order: []
    tasks: {}
  phase-7:
    task_order: [7.1]
    tasks:
      phase-7.1:
        title: Consume phase-3 outputs
        parent_phase: phase-7
        dependency_edges:
          - kind: blocked-by
            target: phase-3.4
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
```

**V3.3 §4.3 compliance.** Schema carries forward V3.2 §4.3's structure (per-phase `task_order` + per-task block) and adds the V3.3 `dependency_edges` field per V3.3 §4.3 line 201.

**"Annotation sub-field" (per BD-106 spec — interpretation note).** V3.3 §6.R is not literally a section in `ARCHITECTURE-V3.3-DELTA.md`; the delta document does NOT contain a `§6.R` heading. The "annotation" sub-field requirement in the BD-106 prompt is satisfied per V3.3 §5.3 line 276, which states *"Prose annotations after the entry are permitted as free-text (e.g., `- phase-3.1 (must complete schema before this task)`); the parser captures only the matched ID prefix."* For round-trip identity (parse → emit → byte-identical), the prose annotation MUST be preserved. The implementation captures it as the `annotation` sub-field on each `dependency_edges[]` entry (kind / target / annotation). This extends V3.3 §4.3 line 201's two-field shape `{kind, target_pack_id}` with a third lossless-round-trip field. The parser-emitter contract holds: byte-identical round-trip on the `ROUNDTRIP.md` fixture (proof in §6.4 below). This interpretation is flagged here as a planner-deferred-to-coder decision; if the architect later authors a real V3.3 §6.R that contradicts this shape, the field can be renamed without changing the round-trip semantics.

## §4 Label family additions (V3.3 §3.5)

Two new helper functions added to `tracker-labels.sh`:

- `tracker_labels_derived_from <td-id>` — composes `derived-from:TD-NNN`. Validates input matches `TD-\d+`; rejects BD-NNN (BD derivation is not in V3.3 §3 scope for v11.0).
- `tracker_labels_promoted_to <phase-or-task-id>` — composes `promoted-to:phase-N` (Path 1) or `promoted-to:phase-N.M` (Path 2). Validates input matches the phase / phase-task identifier grammar; rejects malformed input (3-component IDs, TD-NNN targets, etc.).

**Path 3 forbidden (V3.3 §3 line 27).** There is intentionally NO `tracker_labels_folded_into` helper. Test 5.6 asserts the function does not exist at runtime — a regression here would surface immediately.

**Integration with existing `tracker-labels.sh` mechanisms.** `derived-from:` and `promoted-to:` are open-string label families: one label per concrete identifier. They are NOT in the canonical set ensured at `pack tracker init` time (since the concrete identifiers are not known at init time). They are created on demand at promotion time by BD-107 (which consumes these helpers + the existing `_tracker_labels_create` private). The header docstring on `tracker-labels.sh` was updated to document the integration boundary.

## §5 id-map handling design (V3.2 §4.1 step 5e + V3.3 §4.1)

**Storage shape.** Phase task IDs use the same top-level slot in `.pack-tracker/id-map.json` as BD-NNN / TD-NNN — `mapping["phase-N.M"] = {id, url}` — so the existing `tmf_mapping_get` / `tmf_mapping_set` continue to work for phase tasks without modification.

**Per-phase task ordering.** The phase epic's mapping entry gains an additive `task_order` field per V3.2 §4.1 step 5e (carried forward unchanged in V3.3 §4.1):

```json
{
  "phase-3":   {"id": "401", "url": "...", "task_order": ["1", "2", "3"]},
  "phase-3.1": {"id": "402", "url": "..."},
  "phase-3.2": {"id": "403", "url": "..."},
  "phase-3.3": {"id": "404", "url": "..."},
  "BD-001":    {"id": "10",  "url": "..."},
  "TD-029":    {"id": "29",  "url": "..."}
}
```

**Forward helpers** (`tracker-migrate-forward.sh`):
- `tmf_mapping_set_phase_task_order <data> <phase-N> <csv>` — additive write; preserves `id` + `url` on the phase entry. Rejects `phase-N.M` IDs (only phase-N accepts a task_order).
- `tmf_mapping_get_phase_task_order <data> <phase-N>` — emits a JSON array (possibly empty).

**Reverse helper** (`tracker-migrate-reverse.sh`):
- `_tmr_phase_task_order <mapping> <phase-N>` — reads explicit `task_order` if set; otherwise falls back to ascending numeric scan over all `phase-<N>.<M>` keys with matching phase prefix. The fallback handles bootstrapped repos that didn't go through forward migration but have phase tasks created directly via the form (D-4-V2 `phase-task-skeleton`).

**Round-trip safety.** `tmf_mapping_save` + `tmf_mapping_load` round-trip preserves `task_order` (test 6.6 PASS).

## §6 Verification gate evidence

### §6.1 New BD-106 test runner

```
$ bash scripts/tests/test-tracker-phase-task.sh

=== Group 1: identifier + grammar helpers ===
  PASS 1.1 compose phase-3.2
  PASS 1.1 compose phase-12.7
  PASS 1.2 regex names phase-N(.M)
  PASS 1.2 regex names TD-NNN
  PASS 1.2 regex names BD-NNN
  PASS 1.2 regex matches sample Dependencies entry

=== Group 2: parser correctness ===
  PASS 2.1 fixture parses 3 phases
  PASS 2.1 phase[0].phase_number = 3
  PASS 2.1 phase[0] has 3 tasks
  PASS 2.1 phase[0] task[0].pack_id
  PASS 2.1 phase[0] task[0].title
  PASS 2.2 sparse phase[1].tasks empty
  PASS 2.2 sparse phase[1].phase_number
  PASS 2.3 phase-3.1 has 2 deps
  PASS 2.3 dep[0].kind
  PASS 2.3 dep[0].target
  PASS 2.3 dep[0].annotation captured (round-trip)
  PASS 2.3 dep[1].target = TD-029
  PASS 2.3 dep[1].annotation empty
  PASS 2.4 phase-7.1 dep[0].target = phase-3.4
  PASS 2.5 phase-3.3 dep[1].target = BD-108
  PASS 2.6 missing file → typed error

=== Group 3: emitter + round-trip identity ===
  PASS 3.1 round-trip identity (parse → emit → diff = empty)
  PASS 3.2 emit is deterministic
  PASS 3.3 semantic round-trip preserves task pack_ids
  PASS 3.4 semantic round-trip preserves dependency targets

=== Group 4: sidecar phase_tasks block ===
  PASS 4.1 block has phase_tasks: header
  PASS 4.1 block names phase-3
  PASS 4.1 block names phase-3.1 task
  PASS 4.1 block has task_order
  PASS 4.2 dependency_edges block present
  PASS 4.2 kind: blocked-by emitted
  PASS 4.2 target: phase-2.4 emitted
  PASS 4.2 annotation captured
  PASS 4.2 empty annotation rendered ''
  PASS 4.3 sparse phase emits empty tasks: {}
  PASS 4.3 phase-4 has tasks: {}
  PASS 4.4 template_version = phase-task-v11.0
  PASS 4.4 extra_fields: {} placeholder
  PASS 4.5 parent_phase: phase-3 emitted
  PASS 4.5 parent_phase: phase-7 emitted

=== Group 5: label family helpers ===
  PASS 5.1 derived-from happy path
  PASS 5.2 derived-from rejects BD-NNN
  PASS 5.3 promoted-to phase-N
  PASS 5.4 promoted-to phase-N.M
  PASS 5.5 promoted-to rejects malformed (3-component id)
  PASS 5.5 promoted-to rejects TD-NNN target
  PASS 5.6 NO folded-into helper (Path 3 forbidden per V3.3 §3 line 27)

=== Group 6: id-map handling ===
  PASS 6.1 mapping_get phase-3.1 → 402
  PASS 6.1 mapping_get phase-3.2 → 403
  PASS 6.2 phase-3 still has gh id
  PASS 6.2 phase-3 still has url
  PASS 6.2 phase-3.task_order added
  PASS 6.3 get_phase_task_order
  PASS 6.3 missing phase → []
  PASS 6.3 set_phase_task_order rejects phase-N.M id (only phase-N accepted)
  PASS 6.4 reverse honors explicit task_order
  PASS 6.5 fallback ascending numeric
  PASS 6.6 save/load round-trip preserves task_order
  PASS 6.6 save/load round-trip preserves phase task gh id

=== Summary ===
Passed: 60
Failed: 0
All tests passed.
```

### §6.2 Existing baselines (no regression)

```
$ python3 scripts/validate-pack.py | tail -2
============================================================
PASSED — all checks clean

$ bash scripts/tests/test-customization-preserve.sh | tail -3
Passed: 233
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-forward-test.sh | tail -3
Passed: 126
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-reverse-test.sh | tail -3
Passed: 93
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-migrate-roundtrip-test.sh | tail -3
Passed: 39
Failed: 0
All tests passed.
```

### §6.3 Full tracker-* test sweep

All 14 tracker-related test runners pass (660 prior + 60 new = 720 total):

| Runner | Result |
|---|---|
| tracker-agent-read-test.sh | 31 / 0 |
| tracker-bd129-gh-repo-test.sh | 11 / 0 |
| tracker-bd130-doctor-wired-test.sh | 8 / 0 |
| tracker-bd132-race-test.sh | 29 / 0 |
| tracker-bd133-header-preservation-test.sh | 30 / 0 |
| tracker-bd134-close-retry-test.sh | 24 / 0 |
| tracker-config-schema-test.sh | 17 / 0 |
| tracker-config-test.sh | 32 / 0 |
| tracker-errors-test.sh | 60 / 0 |
| tracker-init-test.sh | 95 / 0 |
| tracker-migrate-forward-test.sh | 126 / 0 |
| tracker-migrate-reverse-test.sh | 93 / 0 |
| tracker-migrate-roundtrip-test.sh | 39 / 0 |
| tracker-provider-test.sh | 65 / 0 |
| **test-tracker-phase-task.sh** (NEW) | **60 / 0** |

### §6.4 Round-trip identity proof

```
$ bash -c '
source scripts/lib/tracker-phase-task.sh
parsed=$(tracker_phase_task_parse scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP.md 2>/dev/null)
tmp=$(mktemp -t roundtrip-proof.XXXXXX)
tracker_phase_task_emit "$parsed" > "$tmp"
diff scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP.md "$tmp"
echo "diff rc=$?"
shasum -a 256 scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP.md "$tmp"
rm -f "$tmp"
'

diff rc=0
43c68f97250916983804cb411f6eb43a8a32c80dbb68cb985d7ea2ea97dac243  scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP.md
43c68f97250916983804cb411f6eb43a8a32c80dbb68cb985d7ea2ea97dac243  /var/folders/.../roundtrip-proof.XXXXXX.cdrII1wwUr
```

Identical SHA-256: byte-equivalent round-trip proven for the `### Tasks` slice.

## §7 Test runner structure + coverage enumeration

The runner follows the `assert_eq` / `t_pass` / `t_fail` shape established by `tracker-migrate-forward-test.sh` / `tracker-migrate-reverse-test.sh`.

| Group | Coverage |
|---|---|
| 1. Identifier + grammar helpers | `compose_pack_id`, `dependency_re` shape, regex matches sample line |
| 2. Parser correctness | phase + task counts; sparse phase; dependency entries (kind/target/annotation); cross-phase + TD + BD references; missing-file error |
| 3. Emitter + round-trip | byte-identical round-trip on `ROUNDTRIP.md`; deterministic emit; semantic round-trip preserves pack_ids + dependency targets via re-parse |
| 4. Sidecar phase_tasks block | header / phase / task names; `dependency_edges` w/ kind/target/annotation; sparse-phase empty `tasks: {}`; `template_version: phase-task-v11.0`; `extra_fields: {}`; `parent_phase` wiring |
| 5. Label family helpers | `derived-from` happy + reject BD-NNN; `promoted-to` phase-N + phase-N.M happy paths; reject malformed; **assert NO `folded_into` helper exists** (Path 3 forbidden) |
| 6. id-map handling | phase-task IDs use existing slot; `set_phase_task_order` is additive; `get_phase_task_order`; reject `phase-N.M` for set; reverse-side explicit task_order honored; reverse-side ascending-numeric fallback; mapping save/load round-trip preserves task_order |

Total: 60 assertions across 6 groups.

## §8 Test fixtures

Two fixtures under `scripts/tests/fixtures/tracker-phase-task/` (verified directory did not previously exist before creation):

- `IMPLEMENTATION-PLAN.md` (54 lines) — broad fixture exercising V3.3 §4.4's coverage matrix:
  - One phase (`## Phase 3`) with three tasks `#### 3.1`, `#### 3.2`, `#### 3.3`.
  - Dependency entries with annotation, with TD-NNN target, with BD-NNN target.
  - One sparse phase (`## Phase 4`) with empty `### Tasks` block.
  - One cross-phase consumer (`## Phase 7` task `#### 7.1` referencing `phase-3.4` from a different phase).
  - Surrounding `### Verification`, `### Agent`, `### Risks` sections (parser correctly skips these as non-Tasks H3 zones).
- `ROUNDTRIP.md` (31 lines) — slice fixture for byte-identity round-trip. Contains only the slice the emitter owns (`## Phase` headers + `### Tasks` blocks). No `### Verification` / `### Agent` / `### Risks` because the emitter's scope per V3.3 §4.2 is the Tasks block grammar; surrounding prose is phase-epic body content owned by the existing `tracker-migrate-forward.sh` phase parser.

The slice / broader split is intentional and documented in the test runner Group 3 comments.

## §9 Plan deviations

**Zero strict deviations from V3.3 architecture or the BD-106 spec.** The single interpretation note (§3 above): the prompt references "V3.3 §6.R" for `dependency_edges.annotation`, but the delta document does not contain a literal `§6.R` heading; the requirement is satisfied per V3.3 §5.3's prose-annotation contract + V3.3 §4.3 line 201's `dependency_edges` field, extended with the lossless `annotation` sub-field needed for round-trip identity.

## §10 New POQs introduced

None. The §6.R reference appears to be a forward-looking pointer in the prompt; the architecture's existing §4.3 + §5.3 fully cover the requirement when taken together.

## §11 Definition of Done checklist (per BD-106 success criteria)

| Criterion | Result |
|---|---|
| `bash scripts/tests/test-tracker-phase-task.sh` PASS (round-trip byte-identical) | **PASS** (60 / 0; round-trip SHA-256 identical — §6.1, §6.4) |
| `bash scripts/tests/tracker-migrate-forward-test.sh` PASS (no regression) | **PASS** (126 / 0 — §6.2) |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` PASS (no regression) | **PASS** (93 / 0 — §6.2) |
| `python3 scripts/validate-pack.py` PASS (35 checks; no regression) | **PASS** (all clean — §6.2) |
| All test runners that source the modified libs continue PASS | **PASS** (14 / 14 tracker test runners green — §6.3) |
| Identifier format `phase-N.M` (lowercase, dash-separated) | **PASS** (`tracker_phase_task_compose_pack_id` + tests 1.1) |
| Sidecar `phase_tasks` schema with `id` (via map), `title`, `parent_phase`, `dependency_edges[]` (kind/target/annotation) | **PASS** (sample in §3; tests 4.1-4.5) |
| Label family `derived-from:` + `promoted-to:` propagated; NO `folded-into:` | **PASS** (helpers added; test 5.6 asserts non-existence of `folded_into`) |
| id-map handling for phase-task IDs alongside BD-/TD-NNN; phase entries gain `task_order` | **PASS** (tests 6.1-6.6) |
| Bash 3.2 compatible | **PASS** (no associative arrays, no mapfile, no `${var,,}`; python heredocs use env var rather than stdin to avoid heredoc-stdin clash) |
| Helpers in `scripts/lib/` per signal-6 carve-out (no new top-level scripts) | **PASS** (NEW file at `scripts/lib/tracker-phase-task.sh`) |
| Path 3 forbidden — no `folded-into:` label, no inline `(from TD-NNN)` body marker recognition | **PASS** (no helper, no parser branch; test 5.6 asserts) |
| No PM-only file edits | **PASS** (BACKLOG / CHANGELOG / README / V3.x docs untouched) |
| No state-changing git verbs | **PASS** (only `git rev-parse`, `git status`, `git diff` were run) |
| Implementation report at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-106.md` | **PASS** (this file) |

## §12 Full file content for new files (re-applicable seed)

For Pack Chat reapplication safety: the new files are listed in §1 inventory by absolute path. Their content is in the worktree at the paths shown; total new content ~939 lines (516 lib + 338 test + 54 + 31 fixtures). Re-creation from scratch is straightforward via the worktree files. The two modified libs (`tracker-sidecar.sh`, `tracker-labels.sh`, `tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`) carry purely additive content — additions appended to existing public-API comment blocks and at the end of the existing helper sections; existing functions are untouched.

## §13 Post-land update — §6.R formalized (per BD-106 review F9)

After this report was written, V3.3-DELTA was extended with the §6.R section (commit `342d8b8`, landed ~4 minutes BEFORE the BD-106 commit `bf26789`). The architect's `ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md` §A.6 records 16/16 MATCH against the implementation:

- §6.R.1 (Phase task identifier scheme `phase-N.M`) — implemented.
- §6.R.2 (sidecar `phase_tasks:` block schema with `id`, `title`, `parent_phase`, `dependency_edges[]`) — implemented; matches `tracker_sidecar_compose_phase_tasks_block` output verbatim.
- §6.R.3 (canonical Dependencies entry regex + YAML quoting rule for annotations containing `:` / `#` / `"` / `'` / `\n` / `\t`) — implemented; the annotation-quoting branch is now explicitly tested against the IMPLEMENTATION-PLAN.md fixture (BD-106 review F3 fix; see Test 4.6 / 4.7).
- §6.R.4 (label family `derived-from:` + `promoted-to:`; Path 3 forbidden) — implemented; runtime negative-test (Test 5.6) + CI invariant (validate-pack Check 32, added per BD-106 review F8 fix).

The interpretation-note framing in §3 ("V3.3 §6.R is not literally a section …"), §9 ("zero strict deviations … single interpretation note"), and §10 ("the §6.R reference appears to be a forward-looking pointer …") is preserved as **historical context** — at the time the original coder finished, the §6.R section did not yet exist in the live spec. From `2026-05-14` forward (commit `342d8b8`), §6.R exists in `ARCHITECTURE-V3.3-DELTA.md` (lines 384-493) with no contradiction to the BD-106 implementation.

**No re-implementation needed** — the §3 / §4 / §6.4 prose accurately describes the shipped behavior; only the framing assumption (that §6.R was a "forward-looking pointer") is superseded by the architect's ratification.

This §13 update is part of the BD-106 fix-pass commit (Batch 17 retrospective per-BD review) and reflects the F9 finding's suggested fix verbatim.
