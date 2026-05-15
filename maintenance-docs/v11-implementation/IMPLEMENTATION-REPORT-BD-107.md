# IMPLEMENTATION-REPORT-BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)

**Branch:** `v11-dev`
**Pre-flight HEAD:** `f209b044299b4846772f58cc9dec3cb04cf62432`
**Final HEAD on worktree:** `f209b044299b4846772f58cc9dec3cb04cf62432` (no commits made — Pack Chat parent will commit per workflow rule)
**Date:** 2026-05-14
**Author:** pack-coder
**Scope:** BD-107 only (Batch 17 commit 3 of 3)
**Spec read:** `BACKLOG.md:900-912`, `ARCHITECTURE-V3.3-DELTA.md` §3 / §7.1 / §7.2 / §7.3, `IMPLEMENTATION-PLAN-ADDENDUM-4.md` §6.P, BD-106 + BD-108 sources (`tracker-labels.sh`, `tracker-phase-task.sh`, `tracker-links.sh`, `tracker-cycle-check.sh`).
**Status of all DoD items:** PASS (see §9 + checklist below).

---

## §1 Files created (paths + line counts)

| Path | Lines | Notes |
|---|---|---|
| `scripts/lib/tracker-promote.sh` | 1089 | Orchestrator library — Path 1 / Path 2 / direct-close + reverse handlers + pure formatters + M-allocator. Heavy parsing offloaded to python3 (mirrors BD-106 / BD-108 pattern). |
| `scripts/pack-td.sh` | 244 | Verb dispatcher for the `pack td` namespace. Routes `promote --to=phase-N` → Path 1, `promote --to=phase-N.M` → Path 2, `resolve` → direct close. Rejects `--fold-into` with typed error per V3.3 §3 line 27. |
| `scripts/tests/test-tracker-promote-path1.sh` | 461 | Path 1 forward + reverse + round-trip + label invariants + dispatcher integration + doc sanity checks. 8 groups; 61 assertions. |
| `scripts/tests/test-tracker-promote-path2.sh` | 432 | Path 2 forward + reverse + round-trip + dependency-edge integration with BD-108 + dispatcher integration. 7 groups; 48 assertions. |
| `scripts/tests/test-tracker-promote-direct.sh` | 334 | Direct-close wrapper + v10-lifecycle preservation (no provider calls; no sidecar mutation; no labels) + Path 3 forbidden invariants. 5 groups; 31 assertions. |
| `scripts/tests/fixtures/tracker-promote/BACKLOG.md` | 39 | Test fixture with TD-031 (no blockers), TD-029 (no blockers), TD-040 (blockers: TD-029, phase-3.1). |
| `scripts/tests/fixtures/tracker-promote/IMPLEMENTATION-PLAN.md` | 27 | Seed plan with phase-3 (tasks 3.1, 3.2) + ### Verification / Agent / Risks subsections. |
| `scripts/tests/fixtures/tracker-promote/id-map.json` | 9 | Pre-populated id-map covering TD-029/031/040 + phase-3 / phase-3.1 / phase-3.2. |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-107.md` | (this file) | The report. |

**Total new code:** 1089 + 244 + 461 + 432 + 334 = **2560 LOC** plus 75 LOC of fixtures.

## §2 Files extended (paths + diff stats)

| Path | Insertions | Deletions | Notes |
|---|---|---|---|
| `HELP-FRAGMENT-PACK.md` | 1 | 0 | Adds `scripts/pack-td.sh <subcmd>` row to "Pack scripts" table (validate-pack Check enforces every executable script appears here). |
| `HELP-FRAGMENT-TRACKER.md` (pack root) | 20 | 0 | Mirrors project-template version verbatim per byte-identity invariant. New "TD promotion (v11+)" subsection + 3 colloquial mappings. |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 20 | 0 | Same content as pack-root (byte-identical). |
| `project-template/docs/pack/HELP-FRAGMENT.md` | 4 | 1 | Adds `pack td resolve <td-id>` row; tightens existing `pack td promote` rows to cite §3.3 / §3.4 in addition to §3.1. |
| `project-template/docs/pack/PM-CHAT.md` | 124 | 0 | Adds "TD resolution orchestration (v11+)" section — outcome table, advisory heuristic (V3.3 §7.1), execution workflow (V3.3 §7.2 incl. architect-default for Path 1 per §6.P (a)), verb shape (V3.3 §7.3), implementation reference. Inserted between "Recommendation routing (v11+)" and "Custom agent and skill workflow" sections. |
| `supporting-docs/METHODOLOGY.md` | 33 | 8 | Replaces the v10 three-outcome resolution-path decision logic block (lines 1120-1128) with V3.3 §3.1's three-outcome shape (direct close / Path 1 / Path 2). Adds an explicit "Path 3 is forbidden" note + supersession rationale. |

**Total doc deltas:** 202 insertions, 9 deletions across 6 files.

## §3 §6.P decision + ratification status (call-out 2)

**Implemented per recommendation (a) — architect by default for Path 1.**

§6.P resolution per `IMPLEMENTATION-PLAN-ADDENDUM-4.md:832-835`:
> **Recommendation: (a). Maintainer confirms at BD-107 land-time.**

The PM-CHAT.md "Execution workflow (V3.3 §7.2)" subsection codifies:

- **Path 1** invokes architect by default. Two rationales cited verbatim from V3.3 §7.2:
  1. New phase = architectural decision (scope, agent assignment, risk profile).
  2. METHODOLOGY § Part 4 phase format requires Goal / Prerequisite / `### Tasks` / `### Verification` / `### Agent` / `### Risks` — the TD entry alone cannot fill those.
- **Planner is conditional on the architect's call.** Architect's output explicitly states "planner pass needed" or "no planner pass needed; tasks are self-evident from the TD content."
- **Path 2** does NOT invoke architect/planner by default; planner only on explicit user request.
- **Direct close** does NOT invoke architect/planner.

**Ratification status (mirrors §6.Q / BD-108 + §6.R / BD-106 sequence).** The §6.P MAINTAINER CHECK is currently in `IMPLEMENTATION-PLAN-ADDENDUM-4.md:832` as recommendation (a). BD-107 implements per (a); the addendum's MAINTAINER CHECK awaits PM-only ratification post-CI. Suggested ratification text mirrors §6.R BD-106 land-time format: "**§6.P — RESOLVED-RATIFIED 2026-05-14 per V3.3-DELTA §7.2 + §3.3 + IPLAN-ADDENDUM-4 §6.P.** Maintainer chose option (a) at BD-107 land-time; PM-CHAT.md §"TD resolution orchestration" codifies architect-default for Path 1; planner conditional on architect's call; Path 2 + direct close do not invoke either by default. The §6.P MAINTAINER CHECK is now permanently resolved; no further re-evaluation at later BD land-times."

(Pack Chat parent applies the addendum edit per the BD-106 / BD-108 pattern; this report flags it but does not write to addendum docs per workflow scope.)

## §4 Verb dispatcher details (call-out 1)

**`scripts/pack-td.sh` was created** per the corrected BACKLOG (2026-05-14 second correction). The dispatcher follows the existing one-script-per-noun convention: `scripts/pack-tracker.sh` dispatches `pack tracker <verb>`, `scripts/pack-help.sh` is the LCD shell verb, and now `scripts/pack-td.sh` dispatches `pack td <verb>`.

Wired verbs:

- `pack td promote --to=phase-N <td-id>` → `tracker_promote_path1`
- `pack td promote --to=phase-N.M <td-id>` → `tracker_promote_path2`
- `pack td resolve <td-id> [--note "..."]` → `tracker_promote_direct_close`
- `pack td --help` / `pack td help` → usage manifest
- `pack td promote --fold-into=...` → typed validation error naming Path 3 forbidden (V3.3 §3 line 27 / §1 supersession)

**Consolidation decision (call-out 4 — see §10 below).** `pack td resolve` did not exist anywhere in the codebase before BD-107 (verified via grep: `grep -rn "pack td resolve\|td resolve\|td-resolve" scripts/ supporting-docs/ project-template/docs/` returned no hits other than the new BD-107 files). The corrected BACKLOG explicitly invited this consolidation call ("coder verifies whether the existing `pack td resolve` baseline — if any — should consolidate here"). Decision: **wire `resolve` here as a thin pass-through to `tracker_promote_direct_close`**, giving PM Chat a uniform verb surface across the V3.3 §3.1 three outcomes (no need for users to remember "promotion uses `td promote`, direct close uses `BACKLOG-edit via PM Chat`"). This is the minimum viable consolidation and does not preempt a richer `td resolve` (with full v10 BACKLOG mutation) being lifted into the dispatcher in a later BD.

**Reference dispatcher patterns followed.** `scripts/pack-tracker.sh` and `scripts/pack-help.sh` — same `set -euo pipefail` header, same `SCRIPT_DIR/LIB_DIR` resolution, same `usage()` + `cmd_<verb>()` + `main()` shape, same idempotent library-source pattern. Tests verified `pack-td.sh --help` exits 0 and prints the verb manifest; verbs correctly route to library functions in subshells; unknown verbs emit typed validation errors and exit 1.

## §5 Path 1 mechanics + label invariants

**Forward orchestration (`tracker_promote_path1 <td-id> <phase-N> <repo-root> [<flat-file-only>]`).** Steps per V3.3 §3.3:

1. Validate TD id shape (`^TD-[0-9]+$`); reject BD-NNN with typed error citing V3.3 §3 ("only TDs promote — BD derivation is not in scope at v11.0").
2. Validate phase-N target (must be `phase-N`, not `phase-N.M`); reject the wrong shape with a typed error pointing the user at `tracker_promote_path2`.
3. Read the TD entry from BACKLOG.md via `tmf_parse_backlog` (looks at both `<repo>/BACKLOG.md` and `<repo>/docs/project/BACKLOG.md` — covers both pack-repo + client-project layouts).
4. **Idempotency check** (call-out 5 — see §10): if the TD's existing Resolution names the target phase AND IMPLEMENTATION-PLAN.md already carries `## Phase N` block, refuse with a typed error directing the user to `pack tracker doctor`.
5. Compose phase section via `tracker_promote_compose_phase_section` and append to IMPLEMENTATION-PLAN.md (creates the file if absent).
6. Re-key TD's BACKLOG entry: status → Resolved, Resolution `[YYYY-MM-DD, completed, promoted to phase-N]`. Library returns the patch text in the result JSON; PM Chat owns the BACKLOG mutation per workflow rule (avoids embedding string-based BACKLOG editor logic in the library).
7. **Tracker mode side-effects** (skipped in flat-file mode or when `flat_only=1`):
   - `provider_create()` for the phase epic with labels `[phase-epic, phase-N, template:phase-epic-v11.0, derived-from:TD-NNN]`.
   - `provider_set_labels` on the TD's gh-id with `[status:resolved, promoted-to:phase-N]`.
   - `provider_close` on the TD's gh-id with `state_reason: completed`.

**Label invariants verified by test 6.x:**
- `derived-from:TD-NNN` (Path 1) → applied to the new phase epic. Helper: `tracker_labels_derived_from`.
- `promoted-to:phase-N` (Path 1) → applied to the closed TD. Helper: `tracker_labels_promoted_to`.
- **NO `folded-into:` label** anywhere — neither in the result JSON, nor in the IMPLEMENTATION-PLAN content, nor as a function definition. Path 3 forbidden invariant.
- **NO `tracker_labels_folded_into` constructor** — release-readiness invariant (mirrors BD-106 test 5.6).

**Pure formatter `tracker_promote_compose_phase_section`** emits the METHODOLOGY § Part 4 phase shell (Goal / Prerequisite / `### Tasks` placeholder / `### Verification` / `### Agent` / `### Risks`) populated from the TD's title, description, and File/Symbol fields. The TD's full Context is preserved as an HTML comment for architect reference (V3.3 §3.3 prose-attribution; not the V3.2 Path 3 inline `(from TD-NNN)` body marker form).

## §6 Path 2 mechanics + dependency-edge integration with BD-108

**Forward orchestration (`tracker_promote_path2 <td-id> <phase-N.M> <repo-root> [<id-map-json>] [<store-path>] [<flat-file-only>]`).** Steps per V3.3 §3.4:

1. Validate TD id + phase-N.M target (must be `phase-N.M`, not `phase-N`).
2. Read TD entry via `tmf_parse_backlog`.
3. **Idempotency** (call-out 6 — see §10): if `phase-N.M` already exists in IMPLEMENTATION-PLAN.md, refuse with typed validation error.
4. Compose `#### N.M — <title>` block via `tracker_promote_compose_phase_task_block` and insert into phase N's `### Tasks` zone via a python-based plan rewriter (preserves surrounding `### Verification`, `### Agent`, `### Risks` subsections — verified by test 3.2).
5. Re-key TD entry (return patch text in result JSON; PM Chat applies).
6. **Tracker mode side-effects:**
   - `provider_create()` for the phase task with labels `[phase-task, phase-N, template:phase-task-v11.0, derived-from:TD-NNN]`.
   - **Parent under phase-N epic.** Try `provider_sub_issue_create()` first; on failure, fall back to `provider_link(child, parent, "parent")` (matches the existing tracker-migrate-forward.sh pattern). No new capability flag introduced.
   - **For each Dependencies bullet entry on the TD's blockers field:** call `tracker_links_create_blocked_by(target=phase-N.M, source=blocker, id_map, store_path, "")` (BD-108 orchestrator). The new phase-N.M tracker id is added to the in-memory id-map first, since `tracker_links_create_blocked_by` requires both endpoints to resolve — verified by test 6.1/6.2.
   - `provider_set_labels` on TD with `[status:resolved, promoted-to:phase-N.M]`.
   - `provider_close` on TD with `state_reason: completed`.

**BD-108 integration confirmation (per test Group 6).** Test fixture's TD-040 has blockers `TD-029` and `phase-3.1`. After Path 2 promotes TD-040 → phase-3.4:

- Cycle-graph store at `.pack-tracker/links-graph.json` contains:
  - `{"source":"phase-3.4","target":"phase-3.1","kind":"blocked-by"}`
  - `{"source":"phase-3.4","target":"TD-029","kind":"blocked-by"}`
- `provider_link` was called twice (verified by `grep -cE '^\|link ' stub.log`).
- `result.dependency_edges` array has 2 entries, each carrying source/target/source_tracker_id/target_tracker_id/kind/annotation.

**Bullet form parsing.** The `tmf_parse_backlog` parser preserves the v10 multi-line Blockers bullet form (`  - TD-029` becomes the literal string `"- TD-029"` in the parsed JSON). Path 2's link orchestrator strips the leading `- ` before pack-id matching so both the v10 multi-line form and the v10 single-line CSV form route uniformly. Trailing free-text annotation (V3.3 §5.3) is preserved by splitting on the first whitespace boundary.

## §7 Direct close wrapper (call-out 7)

**Implementation: thin pass-through marker.** The `tracker_promote_direct_close <td-id> [<note>]` function emits a JSON-shaped "outcome record" but performs **no state mutation**:

- No `provider_create` call.
- No `provider_set_labels` call.
- No `provider_link` call.
- No `provider_close` call.
- No sidecar writes.
- No BACKLOG edits (PM Chat applies the v10-lifecycle status flip per METHODOLOGY § Part 7 Procedure 4).

**Result JSON shape:**

```json
{
  "td_id":            "TD-031",
  "outcome":          "direct-close",
  "promotion_labels": [],
  "new_entity":       null,
  "resolution_text":  "[2026-05-14, completed, completed inline]",
  "note":             "completed inline",
  "v10_lifecycle":    "use existing pack td resolve / BACKLOG-edit procedure (METHODOLOGY § Part 7 Procedure 4)"
}
```

**Rationale.** The wrapper exists so PM Chat has a uniform JSON entry point across the three V3.3 §3.1 outcomes (one of: `outcome="direct-close"` with `promotion_labels=[]` and `new_entity=null`, or the Path 1 / Path 2 result shapes with populated promotion_labels + tracker_id). The empty-array + null-entity contract makes the V3.3 §3.2 invariant ("no promotion label; no new entity") **programmatically legible** rather than implicit. Test Group 3 verifies this end-to-end: after a `tracker_promote_direct_close` call against a worktree with a sidecar file, both the sidecar's SHA-256 and the BACKLOG.md's SHA-256 are byte-identical to before the call.

The wrapper is NOT a pass-through to v10 `pack td resolve` (which doesn't exist as a baseline — see call-out 4 in §10). It is a **JSON marker** that PM Chat consumes to decide "no further orchestration needed; just flip the BACKLOG status."

## §8 Round-trip identity proof (SHA-256 hashes for ≥2 fixtures)

### Path 1 fixture (TD-031 → phase-7)

Worktree: copy of `scripts/tests/fixtures/tracker-promote/{BACKLOG.md,IMPLEMENTATION-PLAN.md}`.

| State | BACKLOG.md SHA-256 | IMPLEMENTATION-PLAN.md SHA-256 |
|---|---|---|
| before forward run | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `724685ca04a96181b197f793d1b7a7c5776ddf449c48fdd31404b1cead153c1c` |
| after forward run + PM Chat patch | `b020e471f4d89e9897adfd09a26b80ed239fc3dc4e7c631ef0768a90dd14f87e` | `ec3c26febd2405882a7e96dd59dcc95b788497c0dc0b9ecb0e843e92f73dd91e` |
| after replay (idempotency-refused) | `b020e471f4d89e9897adfd09a26b80ed239fc3dc4e7c631ef0768a90dd14f87e` | `ec3c26febd2405882a7e96dd59dcc95b788497c0dc0b9ecb0e843e92f73dd91e` |

**Result:** post-forward SHAs equal post-replay SHAs (byte-identical); pre-forward SHAs differ from post-forward SHAs (mutation occurred). Round-trip safety contract satisfied.

### Path 2 fixture (TD-040 → phase-3.4)

Worktree: copy of the same fixture.

| State | BACKLOG.md SHA-256 | IMPLEMENTATION-PLAN.md SHA-256 |
|---|---|---|
| before forward run | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `724685ca04a96181b197f793d1b7a7c5776ddf449c48fdd31404b1cead153c1c` |
| after forward run + PM Chat patch | `b25464f7a3e5afa8fe0c4fba2937790f50316d989ffb46d28bb21ce88744ac5f` | `1d4d144da382fd8061e2418785547311b3a7fa548f1ae07c9482d884e9d9e91f` |
| after replay (idempotency-refused) | `b25464f7a3e5afa8fe0c4fba2937790f50316d989ffb46d28bb21ce88744ac5f` | `1d4d144da382fd8061e2418785547311b3a7fa548f1ae07c9482d884e9d9e91f` |

**Result:** identical replay-stability invariants hold. Path 2 mutates IMPLEMENTATION-PLAN.md (inserts `#### 3.4 — Schema bootstrap helper` block in phase-3's `### Tasks` zone, BEFORE `### Verification`); subsequent replay is refused with typed error and SHAs do not change.

### Direct-close fixture (TD-031, no-op contract)

Worktree: copy of fixture BACKLOG.md + a synthetic `.pack-tracker/sidecar.json` containing `{"original":"sidecar-content"}`. Test Group 3.4 of `test-tracker-promote-direct.sh`:

| File | SHA-256 before | SHA-256 after `tracker_promote_direct_close TD-031 "small fix inline"` | Identical? |
|---|---|---|---|
| `.pack-tracker/sidecar.json` | (computed at runtime) | (same) | YES (assertion 3.4 PASS) |
| `BACKLOG.md` | (computed at runtime) | (same) | YES (assertion 3.4 PASS) |

**Result:** direct close is byte-equivalent — V3.3 §3.2 invariant ("v10 lifecycle unchanged; no labels; no new entity; no sidecar mutation") fully honoured.

## §9 Test results

### New tests (BD-107)

| Script | PASS | FAIL | Coverage |
|---|---|---|---|
| `scripts/tests/test-tracker-promote-path1.sh` | **61** | 0 | Verb classification, pure formatter, Path 1 forward (flat + tracker stub), reverse + round-trip, label invariants, dispatcher integration, doc sanity |
| `scripts/tests/test-tracker-promote-path2.sh` | **48** | 0 | M-allocator, formatter, Path 2 forward (flat + tracker), dependency-edge integration with BD-108, reverse + round-trip, dispatcher |
| `scripts/tests/test-tracker-promote-direct.sh` | **31** | 0 | Wrapper happy path, validation, v10 lifecycle preservation (no provider calls; no sidecar mutation), dispatcher, Path 3 forbidden invariants |
| **Total new** | **140** | **0** | |

### Regressions (existing BD-106 / BD-108 / cycle-check tests)

| Script | PASS | FAIL |
|---|---|---|
| `scripts/tests/test-tracker-phase-task.sh` (BD-106) | 60 | 0 |
| `scripts/tests/test-tracker-links.sh` (BD-108) | 43 | 0 |
| `scripts/tests/test-tracker-cycle-check.sh` (BD-108) | 21 | 0 |
| **Total regression** | **124** | **0** |

### `validate-pack.py`

```
============================================================
PASSED — all checks clean
```

All 31 validate-pack checks pass, including the byte-identity check between the pack-root `HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, and the pack-script-discoverability check (`scripts/pack-td.sh` row added to `HELP-FRAGMENT-PACK.md`).

### Aggregate

**264 PASS / 0 FAIL across all in-scope tests + validate-pack.**

## §10 Decision call-outs 3, 4, 5, 6, 8, 9, 10

### Call-out 3 — HELP-FRAGMENT reconciliation

**Decision:** the `pack td promote` verbs live in **both** surfaces:

- `HELP-FRAGMENT.md` (pre-existing per V3.3 §7.3 line 562: "added to `HELP-FRAGMENT.md` (BD-076 extension)" — the LCD shell verb manifest under "Project commands"). Pre-existing rows are tightened to add `§3.3` / `§3.4` cross-references and a NEW row added for `pack td resolve <td-id>`.
- `HELP-FRAGMENT-TRACKER.md` (both pack-root and project-template copies, byte-identical). New "TD promotion (v11+)" subsection table + 3 colloquial mappings. Mirrors the pre-existing tracker-verb pattern in the same file.

**Existing entries quoted (HELP-FRAGMENT.md before edit):**
```
| `pack td promote --to=phase-N` | Promote a TD-NNN to a new phase epic (Path 1; V3.3 §3.1). |
| `pack td promote --to=phase-N.M` | Promote a TD-NNN to a new phase task under phase N (Path 2; V3.3 §3.1). |
```

**After edit:**
```
| `pack td promote --to=phase-N` | Promote a TD-NNN to a new phase epic (Path 1; V3.3 §3.1 / §3.3). |
| `pack td promote --to=phase-N.M` | Promote a TD-NNN to a new phase task under phase N (Path 2; V3.3 §3.1 / §3.4). |
| `pack td resolve <td-id>` | Direct-close wrapper (V3.3 §3.2). No promotion label; no new entity. |
```

**Rationale.** HELP-FRAGMENT.md surfaces verbs at `pack help` first-screen; HELP-FRAGMENT-TRACKER.md surfaces tracker-context entries grouped under the tracker section. The `pack td` verbs cross both surfaces because they're useful to PM Chat (tracker-context) AND to plain shell users (LCD-context). Duplication is minimal — the `pack td resolve` row is the only entry unique to one surface (HELP-FRAGMENT.md got it as a NEW row).

### Call-out 4 — `pack td resolve` baseline

**Decision: wired as a thin pass-through to `tracker_promote_direct_close`.** The verb did not exist as a baseline (verified by grep). The corrected BACKLOG explicitly invited the consolidation call ("coder verifies whether the existing `pack td resolve` baseline — if any — should consolidate here").

Wiring `resolve` here gives PM Chat a uniform verb surface across the three V3.3 §3.1 outcomes. The implementation does not preempt a richer `td resolve` (with full v10 BACKLOG mutation + status flip + audit-comment) being lifted into the dispatcher in a later BD; today's wrapper emits a JSON marker, leaving the actual BACKLOG mutation to PM Chat per workflow rule.

### Call-out 5 — Path 1 idempotency

**Decision: refuse with typed validation error.** When the TD's existing Resolution names the target phase AND `## Phase N` already exists in IMPLEMENTATION-PLAN.md, the orchestrator refuses with:

```
ERROR: validation
MESSAGE: promote_path1: TD-NNN already promoted to phase-N; refusing duplicate run
(BACKLOG entry has Resolution naming phase-N and IMPLEMENTATION-PLAN.md already carries ## Phase N)
→ Run: pack tracker doctor to inspect; or choose a different --to target
```

**Rationale.** A no-op would silently mask user intent (was the user trying to re-promote, or did they fat-finger a different target?). A replay would risk doubling the phase block. Refusal with a typed error + next-step verb naming `pack tracker doctor` matches the V3.3 §5.6 / V1 §9 typed-error UX contract used by BD-108 cycle-check refusals — same shape.

### Call-out 6 — Path 2 M-allocation

**Decision: refuse with typed validation error.** When the user requests `--to=phase-N.M` with a specific M that's already taken (verified via `tracker_promote_phase_task_M_in_use`), the orchestrator refuses with:

```
ERROR: validation
MESSAGE: promote_path2: phase-N.M already exists in IMPLEMENTATION-PLAN.md; refusing to overwrite
(call-out 6: requested M is in use — pick a different M or run tracker_promote_next_phase_task_M for the next free slot)
```

**Rationale.** Same UX pattern as call-out 5. Auto-bumping to the next free M would silently mask user intent. The error message points the user at the next-free-M helper so the recovery path is explicit.

If the user wants the next-free-M behavior, they can omit the M (call `tracker_promote_next_phase_task_M` first to compute it) — that's a separate verb path. The dispatcher could in a future BD add `--to=phase-N` (no M) → auto-allocate-next form, but that's beyond BD-107's scope.

### Call-out 8 — PM-CHAT.md placement

**Decision:** the new "TD resolution orchestration (v11+)" section lands **after** "Recommendation routing (v11+)" and **before** "Custom agent and skill workflow". Both "Recommendation routing" and "TD resolution orchestration" are v11+ tracker-feature sections; grouping them puts the v11-additive content together. The "Custom agent and skill workflow" section that follows is feature-orthogonal (project-side custom agent registration), so the new section doesn't disrupt its context.

**Section structure:**
- Outcome table (V3.3 §3.1)
- "Path 3 is forbidden" callout (V3.3 §1 supersession)
- Advisory heuristic (V3.3 §7.1) — signals + presentation shape
- Execution workflow (V3.3 §7.2) — direct close / Path 2 / Path 1 sub-sections
- Verb shape (V3.3 §7.3)
- Implementation reference (orchestrator library + dispatcher script paths)

### Call-out 9 — METHODOLOGY edit surgical?

**YES — surgical edit.** The change is scoped to the existing "Resolution path decision logic" code block + 1 paragraph of surrounding prose. Adjacent procedures (Procedure 1 / Procedure 2 / Procedure 3) are untouched.

**Before edit (lines 1120-1128):**
```
**Resolution path decision logic:**
\`\`\`
Is the work small AND directly related to the upcoming phase's concerns?
  → Yes: addendum task within the current phase
  → No: Is the volume of unblocked items large, or do they span unrelated areas?
      → Yes: dedicated cleanup phase
      → No: separate pass of the current phase (same phase number, distinct prompt)
\`\`\`
The PM chat presents its reasoning and the user may override. Bias toward resolving now.
```

**After edit:** see `supporting-docs/METHODOLOGY.md:1120` — replaced with the V3.3 §3.1 three-outcome shape (direct close / Path 1 / Path 2), citing V3.3 §3.2 / §3.3 / §3.4 + §6.P; appended a "Path 3 is forbidden" paragraph naming the supersession + the "no `--fold-into` flag" invariant.

The number of lines doubles (8 → 30 in the code block + 9-line "Path 3 forbidden" paragraph) but the edit surface is contained: only the named decision-logic block changes.

### Call-out 10 — Test fixture organization

**Decision: extend the BD-106 / BD-108 pattern.** A new directory `scripts/tests/fixtures/tracker-promote/` was created at the same level as `tracker-phase-task/` and `tracker-links/`. Contents:

- `BACKLOG.md` — three TDs (TD-029, TD-031, TD-040). TD-031 has no blockers (Path 1 candidate); TD-040 has multi-blocker (Path 2 dependency-edge candidate).
- `IMPLEMENTATION-PLAN.md` — phase-3 with two tasks (3.1 + 3.2) + ### Verification + ### Agent + ### Risks subsections (so Path 2's plan-rewrite tests can verify the rewriter preserves them).
- `id-map.json` — pre-populated id map covering the three TDs + phase-3 + phase-3.1 + phase-3.2.

The fixture worktree is **copied** into a per-test scratch directory inside `mktemp`, so tests do not mutate the canonical fixture. The same `mk_worktree` / `mk_tracker_worktree` helper pattern is used across all three test scripts. Path 2's link tests reuse the existing BD-108 stub backend (`scripts/tests/fixtures/tracker-provider/stub-backend.sh`) — no duplicate backend stub.

## §11 Path 3 forbidden invariants (grep proofs)

All four invariants from BACKLOG / V3.3 §3 verified:

### 11.1 No `tracker_labels_folded_into` constructor

```bash
$ declare -f tracker_labels_folded_into 2>/dev/null && echo PRESENT || echo ABSENT
ABSENT
```

(asserted by test-tracker-promote-path1.sh group 6.4 + test-tracker-promote-direct.sh group 5.1; both PASS.)

### 11.2 No `--fold-into` arg as a wired branch in `pack-td.sh`

```bash
$ python3 -c '
import re
src = open("scripts/pack-td.sh").read()
m = re.search(r"^\s*--fold-into=\*\|--fold-into\)(.*?);;", src, re.DOTALL | re.MULTILINE)
print("BRANCH BODY:", m.group(1)[:200] if m else "NOT FOUND")
'
BRANCH BODY:
                tracker_error_emit "validation" \
                    "promote: --fold-into is not supported (Path 3 forbidden per V3.3 §3 line 27 / §1 supersession)"
                return 1
```

The `--fold-into` case branch exists ONLY as a typed-error rejection (with `tracker_error_emit` + `return 1` body). No wired implementation. Asserted by test-tracker-promote-direct.sh group 5.2 PASS.

### 11.3 No `folded-into:` label literal in new code (excluding comments)

```bash
$ grep -nE 'folded-into:' scripts/lib/tracker-promote.sh scripts/pack-td.sh \
    | grep -vE '(^|:)[0-9]+:[[:space:]]*#'
(no output)
```

All `folded-into:` mentions in the new code are inside comments documenting the prohibition. No emitter writes the label. Asserted by test-tracker-promote-direct.sh group 5.5 PASS.

### 11.4 No V3.2 `(from TD-NNN)` body marker emitted

```bash
$ grep -nE '\(from TD-' scripts/lib/tracker-promote.sh \
    | grep -vE '(^|:)[0-9]+:[[:space:]]*#'
(no output)
```

The pure formatter emits TD context inside an HTML comment for architect reference (V3.3 §3.3 prose-attribution), NOT the V3.2 inline body-text `(from TD-NNN)` shape. The only `(from TD-` matches are in comment-line documentation of the prohibition. Asserted by test-tracker-promote-direct.sh group 5.6 PASS.

### 11.5 Dispatcher rejects `pack td promote --fold-into=...`

```
$ bash scripts/pack-td.sh promote --fold-into=phase-3.2 TD-031
ERROR: validation
MESSAGE: promote: --fold-into is not supported (Path 3 forbidden per V3.3 §3 line 27 / §1 supersession)
→ Run: verify the issue id and re-run
```

(Asserted by test-tracker-promote-direct.sh group 5.4 + test-tracker-promote-path1.sh group 7.2; both PASS.)

## §12 PM-CHAT.md + METHODOLOGY.md + HELP-FRAGMENT edits (before/after for surgical sections)

### PM-CHAT.md (NEW SECTION, no replacement)

**Before:** absent — PM-CHAT.md had no TD resolution orchestration section. The closest existing content is the "Recommendation routing (v11+)" section (lines 364-391).

**After:** new "TD resolution orchestration (v11+)" section inserted between line 391 (end of Recommendation routing) and the next horizontal rule. Section structure documented above in call-out 8. Net insertion: **124 lines**.

### METHODOLOGY.md (SURGICAL REPLACEMENT)

**Before** (lines 1120-1128):
```
**Resolution path decision logic:**
\`\`\`
Is the work small AND directly related to the upcoming phase's concerns?
  → Yes: addendum task within the current phase
  → No: Is the volume of unblocked items large, or do they span unrelated areas?
      → Yes: dedicated cleanup phase
      → No: separate pass of the current phase (same phase number, distinct prompt)
\`\`\`
The PM chat presents its reasoning and the user may override. Bias toward resolving now.
```

**After** (lines 1120-1153, see file): the v10 three-outcome shape is replaced with the V3.3 §3.1 three-outcome shape (direct close / Path 1 / Path 2). Each outcome cites its V3.3 §3.x subsection + the corresponding verb. Closing paragraph: "PM Chat advises per V3.3 §7.1 heuristic ... bias toward resolving now." NEW paragraph added after the code block: "**Path 3 is forbidden** per V3.3 §3 line 27 / V3.3 §1 supersession ..." (9 lines). Net change: **+33 / -8 lines** (preserves the surrounding "Bias toward resolving now" UX guidance).

### HELP-FRAGMENT-PACK.md (1 NEW ROW)

Added one row in the "Pack scripts" table:

```
| `scripts/pack-td.sh <subcmd>` | TD orchestration — `promote --to=phase-N` (Path 1), `promote --to=phase-N.M` (Path 2), `resolve` (direct close per V3.3 §3.2). |
```

### HELP-FRAGMENT-TRACKER.md (NEW SECTION + 3 colloquial mappings; pack-root + project-template copies byte-identical)

**Before:** the file had only the "Tracker commands (v11+)" verb table + 7 colloquial mappings.

**After:** new "TD promotion (v11+)" section inserted between the tracker-commands table and the "Colloquial mappings" section. The "Colloquial mappings" table got 3 new rows for the `pack td` verbs. Both the pack-root copy and the project-template copy are now byte-identical (verified by validate-pack Check 27 PASS).

### HELP-FRAGMENT.md (1 NEW ROW + 2 row tightenings)

Pre-existing rows for `pack td promote --to=phase-N` and `pack td promote --to=phase-N.M` had their citations tightened from "V3.3 §3.1" to "V3.3 §3.1 / §3.3" and "V3.3 §3.1 / §3.4" respectively (cite the specific subsection that defines the mechanics). New row added for `pack td resolve`.

## §13 Open issues / known limitations

1. **PM Chat owns BACKLOG mutation.** The orchestrator library returns the patch text (`.resolution_text` field in result JSON) but does NOT write to BACKLOG.md itself. This is per the workflow rule that PM Chat owns BACKLOG.md mutations. A test that simulates the full forward + PM-Chat-applies-patch flow does so via inline python helpers; a future BD could lift the patch-application into the library if desired (mirroring the v10 status-flip procedure in METHODOLOGY § Part 7 Procedure 4).

2. **§6.P MAINTAINER CHECK awaits PM-only ratification post-CI.** Implemented per option (a); ratification text suggested in §3 of this report. Mirrors §6.Q / BD-108 + §6.R / BD-106 pattern. Not load-bearing for v11.0 ship — the recommendation is honoured in code + documentation.

3. **Path 1 reverse handler is read-only.** `tracker_promote_reverse_path1` / `tracker_promote_reverse_path2` walk the BACKLOG looking for the TD whose Resolution names the target phase. They emit JSON metadata (phase, derived_from, resolution) for round-trip verification but do NOT reconstruct the IMPLEMENTATION-PLAN content from the closed phase epic — that's `tracker-migrate-reverse.sh`'s job. The reverse handlers are diagnostic/audit-shaped helpers, not full-fidelity reverse migrators.

4. **Tracker-mode side-effects are best-effort with `|| true`.** Following the existing tracker-migrate-forward.sh pattern, `provider_set_labels` and `provider_close` calls in the orchestrator wrap `|| true` so a single backend failure does not break the entire promotion. Failures are silent — a future BD could surface them as partial-write typed errors (mirroring the BD-132 `_tmf_wait_for_close_stabilization` + BD-134 close-retry pattern).

5. **Sub-issue parent fallback is silent.** When `provider_sub_issue_create` fails (low-capability backend), the orchestrator falls back to `provider_link(child, parent, "parent")` without surfacing the fallback. The existing tracker-migrate-forward.sh pattern is the same; a future BD could log the fallback for observability.

6. **`tracker_promote_phase_task_M_in_use` uses string equality on task_number.** If a phase has tasks "1" and "10", a request for "phase-N.10" is correctly identified. Edge case: if a future schema introduces non-integer task numbers (e.g. "phase-N.1a"), the regex anchor on `[0-9]+` would need updating. Not a v11.0 concern.

7. **HELP-FRAGMENT.md isn't trinity-replicated.** Only one copy exists (project-template surface). The pack-root has HELP-FRAGMENT-PACK.md (separate file). HELP-FRAGMENT-TRACKER.md IS byte-identity-paired across pack-root + project-template (validated). This BD's edits respect the existing trinity / byte-identity contract; no new file relationships introduced.

---

## Definition-of-Done checklist

| DoD item | Status | Notes |
|---|---|---|
| `scripts/lib/tracker-promote.sh` exists with Path 1 / Path 2 / direct close + reverse handlers | **PASS** | 1089 LOC; six public functions documented in header. |
| `scripts/pack-td.sh` dispatcher created per `pack-<noun>.sh` convention | **PASS** | 244 LOC; modeled after pack-tracker.sh. |
| `pack td promote --to=phase-N` routes to Path 1 | **PASS** | Test 7.1 (path1) PASS. |
| `pack td promote --to=phase-N.M` routes to Path 2 | **PASS** | Test 7.1 (path2) PASS. |
| `pack td resolve` routes to direct close | **PASS** | Test 4.1 (direct) PASS. |
| `pack td promote --fold-into=...` rejected with typed error naming Path 3 forbidden | **PASS** | Test 7.2 (path1) + 5.4 (direct) PASS. |
| Path 1 forward + reverse + round-trip + label invariants | **PASS** | 61 PASS / 0 FAIL on test-tracker-promote-path1.sh. |
| Path 2 forward + reverse + round-trip + dependency-edge integration with BD-108 | **PASS** | 48 PASS / 0 FAIL on test-tracker-promote-path2.sh. |
| Direct close: no labels, no entity, no sidecar mutation, v10 lifecycle preserved | **PASS** | 31 PASS / 0 FAIL on test-tracker-promote-direct.sh. |
| Round-trip SHA-256 byte-identity for ≥2 fixtures | **PASS** | §8 of this report; Path 1 + Path 2 + direct-close all verified. |
| BD-106 / BD-108 regressions clean | **PASS** | 124 PASS / 0 FAIL. |
| `validate-pack.py` PASS | **PASS** | All 31 checks clean. |
| PM-CHAT.md "TD resolution orchestration" section | **PASS** | 124 lines added; cites V3.3 §3.1 / §3.2 / §3.3 / §3.4 / §7.1 / §7.2 / §7.3 / §6.P. |
| METHODOLOGY.md resolution-path decision logic updated to V3.3 §3 | **PASS** | Surgical replacement; Path 3 forbidden paragraph added. |
| HELP-FRAGMENT(-TRACKER) updated; byte-identity preserved | **PASS** | Both copies byte-identical (validate-pack PASS). |
| §6.P resolution (a) implemented; ratification flagged | **PASS** | Architect-default for Path 1; planner conditional; documented in PM-CHAT.md. |
| Path 3 forbidden invariants verified by grep | **PASS** | §11 of this report; all 5 grep checks PASS. |
| No state-changing git verbs run | **PASS** | HEAD unchanged: `f209b04` pre-flight = `f209b04` post-implementation. |

**Aggregate: 18/18 PASS.**

---

## Files-changed inventory

| Path | Change type | Lines |
|---|---|---|
| `scripts/lib/tracker-promote.sh` | NEW | +1089 |
| `scripts/pack-td.sh` | NEW (executable) | +244 |
| `scripts/tests/test-tracker-promote-path1.sh` | NEW (executable) | +461 |
| `scripts/tests/test-tracker-promote-path2.sh` | NEW (executable) | +432 |
| `scripts/tests/test-tracker-promote-direct.sh` | NEW (executable) | +334 |
| `scripts/tests/fixtures/tracker-promote/BACKLOG.md` | NEW | +39 |
| `scripts/tests/fixtures/tracker-promote/IMPLEMENTATION-PLAN.md` | NEW | +27 |
| `scripts/tests/fixtures/tracker-promote/id-map.json` | NEW | +9 |
| `HELP-FRAGMENT-PACK.md` | MODIFIED | +1 / -0 |
| `HELP-FRAGMENT-TRACKER.md` | MODIFIED | +20 / -0 |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | MODIFIED | +20 / -0 |
| `project-template/docs/pack/HELP-FRAGMENT.md` | MODIFIED | +4 / -1 |
| `project-template/docs/pack/PM-CHAT.md` | MODIFIED | +124 / -0 |
| `supporting-docs/METHODOLOGY.md` | MODIFIED | +33 / -8 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-107.md` | NEW | (this file) |

**No deletions.** **No git state-changing verbs run.** All edits in working tree only — Pack Chat parent will commit after review.

---

*End of IMPLEMENTATION-REPORT-BD-107.*
