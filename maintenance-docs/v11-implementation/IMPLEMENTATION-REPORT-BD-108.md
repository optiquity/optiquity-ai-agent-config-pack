# IMPLEMENTATION-REPORT — BD-108

**Cross-entity dependency link orchestration + cycle check + gate-check
extension**

- **Branch:** `v11-dev`
- **HEAD SHA at session start + end:** `bf2678921778c7d5609b9c12cb28709af1b3d9e2`
  (no commits made — agents never commit per pack memory rule)
- **Date:** 2026-05-14
- **Session:** Batch 17 commit 2 of 3 (BD-106 → **BD-108** → BD-107)
- **Spec sources (read-only):** ARCHITECTURE-V3.3-DELTA.md §5; V1 §5.3 / §6.2 / §9;
  IMPLEMENTATION-PLAN-ADDENDUM-4.md §6.Q; METHODOLOGY.md § Part 4 + § Part 7

---

## §1 Files created

| Path | Lines | Purpose |
|---|---|---|
| `scripts/lib/tracker-cycle-check.sh` | 332 | Link-creation-time cycle detector + `[graph] cycle_check_k` reader + private `_tracker_cycle_check_store_add` mutator |
| `scripts/lib/tracker-links.sh` | 340 | Uniform cross-entity dependency orchestrator across the V3.3 §5.1 six entity-pair types; consumes cycle-check + provider_link |
| `scripts/tests/test-tracker-cycle-check.sh` | 309 | 21 assertions across 5 coverage groups (K-resolver, happy paths, refusal paths, K-boundary, failure modes) |
| `scripts/tests/test-tracker-links.sh` | 308 | 43 assertions across 5 coverage groups (pair-type validation, link creation per pair type, cycle-graph store + V3.3 §6.R compliance, round-trip identity, failure modes) |
| `scripts/tests/fixtures/tracker-links/id-map.json` | 14 | Reference id-map covering all 6 entity-pair types from §5.1 |
| `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md` | 12 | BACKLOG fixture with `Blockers: phase-3.2, TD-029` for round-trip §6 SHA-256 proof |
| `scripts/tests/fixtures/tracker-links/IMPLEMENTATION-PLAN-deps.md` | 10 | IMPLEMENTATION-PLAN fixture with annotated Dependencies bullets for round-trip §6 SHA-256 proof |

(Cycle-check tests use ephemeral `mktemp`-managed scratch dirs — no
committed reference fixtures under `scripts/tests/fixtures/tracker-cycle-check/`
because the small graph stores are byte-trivial to construct via the
`write_store` test helper.)

---

## §2 Files extended

| Path | Diff stat | Change |
|---|---|---|
| `scripts/lib/tracker-config.sh` | +8 / -0 | Header-comment documentation of the additive `[graph] cycle_check_k` field. The existing tiny-TOML reader already accepts the new section/key without code change. |
| `scripts/lib/tracker-migrate-forward.sh` | +85 / -1 | Step 6+7 case statement reordered so `phase-N.M` is recognised BEFORE the `phase-N*` glob (otherwise v10 routing would misfire to `provider_sub_issue_create`). Phase-N.M Blockers become `provider_link blocked-by`. New step 7b second-pass: parses IMPLEMENTATION-PLAN.md via `tracker_phase_task_parse` (lazy-sourced) and replays each task's `Dependencies` bullet as a `provider_link blocked-by` call. Failures surface via the existing `partial_failures` file (per V1 §9.6). |
| `scripts/lib/tracker-migrate-reverse.sh` | +20 / -8 | `_tmr_decode_blockers` tightened: sub-issue parent restricted to `^phase-\d+$` (phase epics only) per V3.3 §2 D-21 — phase tasks are L2 entities and are NOT sub-issue parents. Body comment-marker decoder unchanged in code, but the comment block now documents that the v11.0 `phase-N.M` form rides through verbatim via the existing `gh_to_pack` reverse lookup (the id-map already carries the `phase-N.M` keys per BD-106). |
| `supporting-docs/METHODOLOGY.md` | +21 / -3 | § Part 4 line 309 (Dependencies bullet codification: parser regex + 4 admitted ID forms + worked example). § Part 7 line 1037 (Blockers grammar admits `phase-N.M`). § Part 7 lines 1071-1080 (Procedure 1 step 2: phase-N.M blocker + phase-task-A-blocked-by-phase-task-B; mode-agnostic via D-6 / V1 §8.5). |

Total: 4 files extended, +134 / -12 lines net.

---

## §3 §6.Q decision + ratification status

**Decision:** implemented per recommendation **(a)** — K=10 default,
configurable via `tracker.toml [graph] cycle_check_k`.

- **Default K** is exposed as `readonly TRACKER_CYCLE_CHECK_K_DEFAULT=10`
  in `scripts/lib/tracker-cycle-check.sh`.
- **Config field** is read by `tracker_cycle_check_get_k <repo-root>`,
  which checks pack-surface `tracker.toml` then client-surface
  `docs/pack/tracker.toml`, falling back to 10 on absent / non-integer
  / non-positive values.
- **Schema additive**: existing tracker.toml schemas continue to load
  (no code change required to `scripts/lib/tracker-config.sh`'s tiny-
  TOML reader; the parser is shape-tolerant for new `[section]` blocks
  and the `tracker_config_get` helper accepts any dotted key). Verified
  by `tracker-config-test.sh` 32/0 (no regressions) and the new
  cycle-check test 1.2 ("reads tracker.toml [graph] cycle_check_k = 25").

**Ratification status (mirrors BD-106 / §6.R sequence):**
§6.Q is currently MAINTAINER CHECK in
`maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-4.md`
line 837. Per the same pattern that resolved §6.R post-BD-106,
**§6.Q awaits PM-only ratification post-CI** so the corpus marker can be
flipped to RESOLVED-RATIFIED. The implementation already conforms to
recommendation (a); ratification is purely a corpus-doc bookkeeping
step that this agent does not perform (no pack-ops file edits without
explicit caller instruction; PM-only file).

No fallback to (b) or (c) was needed — the additive `[graph]` section
loads cleanly through the existing parser.

---

## §4 Provider-op + capability-flag confirmation

**No new provider operation introduced.** The cross-entity link
orchestrator calls the existing `provider_link` function from
`scripts/lib/tracker-provider.sh`:

```bash
# scripts/lib/tracker-provider.sh:136
provider_link()             { _tracker_provider_dispatch link "$@"; }
```

Which dispatches via `_tracker_provider_dispatch` to the active
backend's `tracker_provider_<backend>_link` (the github backend is
`tracker_provider_gh_link` at `scripts/lib/tracker-provider-gh.sh:483`,
3-arg signature `<id> <other_id> <kind>`).

`tracker-links.sh` calls it as:

```bash
provider_link "$src_id" "$tgt_id" "blocked-by"
```

with `kind="blocked-by"` per V3.3 §5.2 canonical direction.

**No new capability flag introduced.** `provider_capabilities` was not
read by this BD; the V1 §5.3 `link.kind` open-string family already
admits `"blocked-by"` per the existing kind enum
(`blocks|blocked-by|related|duplicates|parent|child` — see
`tracker-provider-gh.sh:474`).

---

## §5 Cycle detection behavior + K-boundary note

**Algorithm:** type-agnostic BFS over the directed `blocked-by` edge
graph in the cycle-graph store. Walks forward from the proposed
*target* for K hops; if the proposed *source* appears in the closure,
the new edge would close a cycle and is refused.

**K-boundary semantic (per call-out 3 — surface to future maintainers):**

- A cycle whose closure depth is **≤ K** is detected. Test 4.1 in
  `test-tracker-cycle-check.sh` asserts this: chain TD-001 →...→ TD-010
  with proposed closing edge TD-010 → TD-001 reaches the source at
  hop 9 (within K=10) → REFUSED.
- A cycle whose closure depth is **> K** is **OUT OF SCOPE** of the
  detector (returns SAFE / rc=0). Test 4.2 asserts this: chain
  TD-001 →...→ TD-012 with proposed closing edge would close a cycle
  at hop 11; with K=10, the BFS terminates at hop 10 having reached
  TD-011 but not yet TD-012 → returns SAFE. **This is documented
  bounded-search behavior per V3.3 §5.5, NOT a bug.** The test name
  explicitly states "(bounded-search; not a bug)" so future maintainers
  reading the test do not misread it.
- The K override works: test 4.3 raises K to 20 and the same chain
  cycle is now detected → REFUSED.

To detect cycles longer than the default K, the user raises
`tracker.toml [graph] cycle_check_k`. The trade-off (search depth vs
GraphQL one-shot capacity per V1 §6.1) is the rationale for K=10
default per IPLAN-ADDENDUM-4 §6.Q recommendation (a).

**Self-loop guard:** if `src == tgt`, the edge is itself a 1-cycle
and is refused immediately without reading the store (see
`tracker_cycle_check_would_form_cycle`'s early `[[ "$src" == "$tgt" ]]`
guard). Test 3.1 covers this.

**Fail-closed semantics:** traversal errors (malformed JSON, missing
file with non-empty path, etc.) emit a typed `schema-reshape` error
and rc=1 — the caller refuses the link. Per V3.3 §5.6, no silent
retry. Test 5.2 covers malformed-store behavior.

---

## §6 Round-trip identity proof (SHA-256)

Two reference fixtures verified byte-identical through the v10
parser → v11 reverse-emitter / phase-task emitter pipeline.

### 6.1 BACKLOG fixture with `Blockers: phase-N.M, TD-NNN`

**Fixture:** `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md`

**SHA-256:** `774798a3d38b2ff9688e9cea5cac44c42aad1a3badf8cdc10889a351a4db55f7`

**Round-trip pipeline:**

```
src → tmf_parse_backlog (BD-065 forward parser; v10 grammar)
    → _tmr_emit_backlog  (BD-067 reverse emitter)
    → out
```

**Result:** `diff $src $out` produces empty output; SHA-256 of `out`
equals SHA-256 of `src`. Verified by test 4.1 in
`test-tracker-links.sh`. The parsed Blockers list is
`["phase-3.2","TD-029"]` — the v11.0 `phase-N.M` admission per V3.3
§5.3 works through the existing v10 parse_id_list (which is
shape-agnostic), and the reverse emitter joins with `, ` preserving
source order.

### 6.2 IMPLEMENTATION-PLAN fixture with annotated Dependencies bullets

**Fixture:** `scripts/tests/fixtures/tracker-links/IMPLEMENTATION-PLAN-deps.md`

**SHA-256:** `58f0c6f5827453772df0317d654178aa9b012cc3730d25d20270ea444dfb19a7`

**Round-trip pipeline:**

```
src → tracker_phase_task_parse  (BD-106 parser)
    → tracker_phase_task_emit   (BD-106 emitter)
    → out
```

**Fixture content includes the V3.3 §5.3 trailing annotation:**

```markdown
- **Dependencies**:
  - phase-3.2 (must complete migration scaffold first)
  - TD-029
```

**Result:** SHA-256 of `out` equals SHA-256 of `src`. Verified by
tests 4.2 + 4.3 in `test-tracker-links.sh`. The annotation
`(must complete migration scaffold first)` is captured by the parser
into the `dependencies[].annotation` sub-field per V3.3 §5.3 / §6.R
and replayed verbatim by the emitter.

---

## §7 Test results

**New test scripts:**

| Script | Assertions | Pass | Fail |
|---|---|---|---|
| `scripts/tests/test-tracker-cycle-check.sh` | 21 | 21 | 0 |
| `scripts/tests/test-tracker-links.sh` | 43 | 43 | 0 |

**Pre-existing tracker test regression check:**

| Script | Pass | Fail |
|---|---|---|
| `tracker-agent-read-test.sh` | 31 | 0 |
| `tracker-bd129-gh-repo-test.sh` | 0 (rc=0; non-counting harness) | 0 |
| `tracker-bd130-doctor-wired-test.sh` | 0 (rc=0; non-counting harness) | 0 |
| `tracker-bd132-race-test.sh` | 0 (rc=0; non-counting harness) | 0 |
| `tracker-bd133-header-preservation-test.sh` | 30 | 0 |
| `tracker-bd134-close-retry-test.sh` | 0 (rc=0; non-counting harness) | 0 |
| `tracker-config-schema-test.sh` | 0 (rc=0; non-counting harness) | 0 |
| `tracker-config-test.sh` | 32 | 0 |
| `tracker-errors-test.sh` | 60 | 0 |
| `tracker-init-test.sh` | 95 | 0 |
| `tracker-migrate-forward-test.sh` | 126 | 0 |
| `tracker-migrate-reverse-test.sh` | 93 | 0 |
| `tracker-migrate-roundtrip-test.sh` | 39 | 0 |
| `tracker-provider-test.sh` | 65 | 0 |
| `test-tracker-phase-task.sh` (BD-106) | 60 | 0 |

**All-pack regression check (every `scripts/tests/*.sh`):**

29 test scripts run, **1314 assertions, 0 failures**, all rc=0.

**Validate-pack:**

```
$ python3 scripts/validate-pack.py
PASSED — all checks clean
```

(Last 3 lines of output: `============================================================`,
`PASSED — all checks clean`, exit 0.)

---

## §8 Decision call-outs 4–6

### Call-out 4 — Annotation handling on Dependencies bullets

When a phase-task Dependencies bullet has trailing prose
(`- phase-3.1 (must complete schema)`), the annotation is captured
into the parser's `dependencies[].annotation` sub-field per V3.3 §5.3
+ §6.R schema. The emitter replays it verbatim (see test 4.3 in
`test-tracker-links.sh` — round-trip preserves
`(must complete migration scaffold first)`). For the link orchestration
surface (`tracker_links_create_blocked_by`), the annotation is an
optional positional argument and rides through the success JSON's
`annotation` field; the cycle-graph store does NOT carry annotations
(it is purely a graph view; the durable persistence is in the sidecar
`phase_tasks[].dependency_edges` block per V3.3 §6.R).

### Call-out 5 — Blockers `phase-N.M` ordering

When Blockers contains a mix of v10 forms (`TD-029`) and v11 forms
(`phase-3.2`), the forward processing order is **source order**
(byte-position in the BACKLOG.md `Blockers:` field). The
`tmf_parse_backlog` parser uses `parse_id_list` which splits on
`[,;\n]` and preserves order; the forward step 6+7 loop iterates the
resulting array in index order; reverse `_tmr_decode_blockers`
preserves order across the two channels (sub-issue parent first if
present, then comment-marker order); `_tmr_emit_backlog` joins with
`, ` in array order. End result: source order is preserved
forward → tracker → reverse for any mix of v10 and v11 Blockers.
Test 4.1's parsed `["phase-3.2","TD-029"]` confirms this ordering
through the round-trip.

### Call-out 6 — Test fixture organization

**`scripts/tests/fixtures/tracker-links/`** (committed reference fixtures):

```
id-map.json                          # 12 pack-ids covering all 6 V3.3 §5.1 pair types
BACKLOG-phase-task-blockers.md       # Round-trip pair 1 (Blockers: phase-N.M, TD-NNN)
IMPLEMENTATION-PLAN-deps.md          # Round-trip pair 2 (annotated Dependencies bullet)
```

The id-map covers `phase-3`, `phase-3.1`, `phase-3.2`, `phase-3.4`,
`phase-7`, `phase-7.1`, `phase-7.2`, `TD-029`, `TD-031`, `TD-040`,
`BD-108`, `BD-110` so future BDs (BD-107 promotion) can reuse the
same fixture without expansion. Pack-id naming aligns with the BD-106
phase-task fixture's `phase-3.4` / `phase-7.4` cross-phase pattern.

**`scripts/tests/fixtures/tracker-cycle-check/`** (intentionally absent):

The cycle-check tests construct small in-memory graph stores via the
`write_store` test helper at runtime, then write them to a per-run
`mktemp -d` scratch dir cleaned up by the `trap … EXIT` handler. No
committed reference fixtures because the graphs are byte-trivial
(empty / single edge / chain-of-N) and would just shadow the
test-internal data shape. Future maintainers extending the cycle
detector can either add new `write_store` calls or commit a
single-purpose JSON fixture as a reference.

---

## §9 BD-107 readiness statement

BD-107 (TD-NNN promotion-path tooling) needs to consume `tracker-links.sh`
for Path 2 ("new phase task + dependency edge"). The exported function
to call is:

**`tracker_links_create_blocked_by`**

Signature:

```bash
tracker_links_create_blocked_by \
    <source-pack-id> \
    <target-pack-id> \
    <id-map-json> \
    <store-path> \
    [<annotation>]
```

Returns:
- **rc=0** on success; success JSON on stdout with fields
  `source_pack_id`, `target_pack_id`, `source_tracker_id`,
  `target_tracker_id`, `kind` (always `"blocked-by"`), `annotation`.
- **rc=1** on validation / cycle / not-found / provider error; typed
  error block on stderr per V1 §9 with `→ Run:` next-step verb.

For Path 2, BD-107's `tracker-promote.sh` will:
1. Create the new phase task entity (BD-107 scope).
2. Add it to the id-map (BD-107 scope).
3. Call `tracker_links_create_blocked_by <new-phase-task> <td-id> <id-map> <store>`
   to wire the "phase task blocked by TD" edge in the same direction
   the v10 forward step 7 already creates (TD blocked by phase task);
   or invert per the actual promotion-path direction the BD-107
   architect chooses.

The library's pair-type validator (`tracker_links_validate_pair_type`)
already accepts the `phase-N.M ↔ TD-NNN` pair shape (test 1.6). The
cycle-check guard fires before the provider call, so an accidentally
self-referencing promotion is refused at link time with a typed
validation error naming `pack tracker doctor`.

`tracker-links.sh` will be sourced by `tracker-promote.sh` the same
way `tracker-migrate-forward.sh` lazy-sources `tracker-phase-task.sh`
(see the new step 7b block: `if ! declare -f X >/dev/null 2>&1; then
source <path-to-X>; fi`).

---

## §10 Open issues / known limitations

### 10.1 §6.Q ratification pending

§6.Q is currently MAINTAINER CHECK in
`maintenance-docs/v11-research/IMPLEMENTATION-PLAN-ADDENDUM-4.md`
line 837. Implementation conforms to recommendation (a); flipping
the corpus marker to RESOLVED-RATIFIED is a PM-only doc-bookkeeping
step (no code change). Mirrors the §6.R / BD-106 sequence. **Disposition
for Pack Chat:** flip §6.Q to RESOLVED-RATIFIED in the same commit
that lands BD-108, the same way §6.R was resolved post-BD-106.

### 10.2 Phase-task entity creation deferred to a future BD

The new step 7b in `tracker-migrate-forward.sh` parses phase-task
Dependencies and replays them as `provider_link blocked-by` calls,
but it will surface "phase-task source not in id-map" partial-failures
because phase-task entity *creation* (one tracker entity per phase
task) is not yet in scope at v11.0 forward orchestrator. The current
v10 forward step 5 only creates one phase epic per phase. Phase tasks
are documented in V3.3 §2 D-21 as L2 entities; their creation is a
future-BD scope item (likely a planner-deferred extension of BD-065
or a fresh BD when the V3.3 §4.1 phase-task creation step lands).

For now, the step 7b loop is **defensive**: it parses the bullets,
attempts the lookup, and gracefully degrades to a partial-failure
log line if either side of the dependency is missing from the
id-map. This means BD-108 ships the orchestration *path* but the
automatic creation of phase-task issues remains a future scope.
The library itself works end-to-end when callers (BD-107
`tracker-promote.sh`) populate the id-map first, then call
`tracker_links_create_blocked_by` directly — that is the BD-107
integration story.

### 10.3 GitHub `provider_link blocked-by` is comment-marker fallback

Per V1 §2.7.1 row 12, the github backend's `tracker_provider_gh_link`
emits a comment-marker fallback (`Blocked by #NNN`) for `blocked-by`
until the GraphQL issue-dependency mutation (GA 2025-08-21) is wired.
This is pre-existing behavior, not a BD-108 limitation. The reverse
decoder (`_tmr_decode_blockers`) already reads the comment marker for
round-trip; once the GraphQL mutation is wired in a future BD, the
comment-marker fallback can be removed without touching `tracker-links.sh`
(the abstraction is at the provider layer).

### 10.4 Cycle-graph store and sidecar are kept in sync by convention

The cycle-graph store (`<repo-root>/.pack-tracker/links-graph.json`
by convention; arbitrary path accepted) is a runtime view that
`tracker-links.sh` keeps in sync with the durable sidecar
`phase_tasks[].dependency_edges` block (V3.3 §6.R) by writing both
when an edge succeeds. There is no automatic reconciliation: if a
user manually edits the sidecar, the cycle store can drift. Per V3.3
§5.6, the diagnostic verb is `pack tracker doctor`; a future BD may
extend `tracker-doctor.sh` with a "rebuild cycle store from sidecar"
operation. For BD-108 + BD-107 integration, this is not a blocker.

### 10.5 No structural-change escalation

Per CLAUDE.md "Skill and agent maintenance is mechanical by default"
rule: this BD ships pack-product code (lib + tests + 1 method-doc
edit) and does not introduce new top-level docs at the pack-repo root
or amend any of the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md
copies). The only METHODOLOGY.md edits are minimal (3 surgical
locations: §Part 4 line 309, §Part 7 line 1037, §Part 7 lines
1071-1080), additive to v10 grammar, and explicitly cite V3.3 §5.x
for traceability.

---

## §11 Definition-of-Done checklist

| Item | Result |
|---|---|
| `scripts/lib/tracker-links.sh` ships with the 6-pair-type orchestration + cycle integration + sidecar persistence + typed errors | **PASS** |
| `scripts/lib/tracker-cycle-check.sh` ships with K-aware BFS + `[graph] cycle_check_k` reader + fail-closed semantics | **PASS** |
| `scripts/lib/tracker-migrate-forward.sh` extended: Blockers admits `phase-N.M`; step 7b reads phase-task Dependencies | **PASS** |
| `scripts/lib/tracker-migrate-reverse.sh` extended: phase-N.M blockers regenerate; sub-issue parent restricted to phase epics | **PASS** |
| `scripts/lib/tracker-config.sh` extended: `[graph] cycle_check_k` documented and accepted by the existing reader | **PASS** |
| `supporting-docs/METHODOLOGY.md` extended at 3 surgical locations (Dependencies bullet, Blockers grammar, Procedure 1 gate-check) | **PASS** |
| `scripts/tests/test-tracker-links.sh` ships and covers all 6 entity-pair types + sidecar + round-trip + failure modes | **PASS (43/43)** |
| `scripts/tests/test-tracker-cycle-check.sh` ships and covers K-resolver + cycle paths + K-boundary + failure modes | **PASS (21/21)** |
| Round-trip SHA-256 identity holds for at least 2 fixtures (Blockers `phase-N.M`; Dependencies bullet with annotation) | **PASS** (§6.1, §6.2) |
| `scripts/validate-pack.py` passes | **PASS** |
| Full `scripts/tests/*.sh` regression: 1314/0 across 29 test scripts | **PASS** |
| §6.Q decision implemented per recommendation (a); ratification flag noted in §3 + §10.1 | **PASS** (impl) / **PENDING** (PM-only ratification) |
| BD-107 prerequisite satisfied: `tracker_links_create_blocked_by` exported with documented signature | **PASS** (§9) |
| No new provider operation; no new capability flag | **PASS** (§4) |
| No state-changing git verbs (no add/commit/push/tag/mv/rm/reset); only working-tree edits | **PASS** (HEAD unchanged at `bf26789…`) |
| Trinity rule N/A (no edits to CLAUDE.md / AGENTS.md / GEMINI.md trinity in this BD) | **N/A** |
| Bash 3.2 + BSD-utils compatibility (no associative arrays, no `mapfile`, no GNU-only flags) | **PASS** |
| Markdown-only report; chunked Write calls (initial + Edit append for >300 lines) | **PASS** |

---

## §12 Files-changed inventory

| Path | Change |
|---|---|
| `scripts/lib/tracker-cycle-check.sh` | NEW (332 lines) |
| `scripts/lib/tracker-links.sh` | NEW (340 lines) |
| `scripts/lib/tracker-config.sh` | MODIFIED (+8 lines, header docs only) |
| `scripts/lib/tracker-migrate-forward.sh` | MODIFIED (+85 / -1) |
| `scripts/lib/tracker-migrate-reverse.sh` | MODIFIED (+20 / -8) |
| `supporting-docs/METHODOLOGY.md` | MODIFIED (+21 / -3 across 3 surgical locations) |
| `scripts/tests/test-tracker-cycle-check.sh` | NEW (309 lines) |
| `scripts/tests/test-tracker-links.sh` | NEW (308 lines) |
| `scripts/tests/fixtures/tracker-links/id-map.json` | NEW (14 lines) |
| `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md` | NEW (12 lines) |
| `scripts/tests/fixtures/tracker-links/IMPLEMENTATION-PLAN-deps.md` | NEW (10 lines) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-108.md` | NEW (this report) |

No files deleted.

---

## §13 Plan deviations

**Zero plan deviations.** The implementation follows V3.3-DELTA §5
end-to-end:

- §5.1 six entity-pair types — all six covered by tests (2.1–2.6).
- §5.2 uniform `link.kind = "blocked-by"`; no new provider op; no new
  capability flag — confirmed in §4.
- §5.3 flat-file syntax (Blockers admits `phase-N.M`; Dependencies
  bullet grammar codified) — confirmed in §6.1, §6.2, METHODOLOGY edits.
- §5.4 Procedure 1 gate-check extension — METHODOLOGY § Part 7 lines
  1071-1080 edit.
- §5.5 cycle detection at link-creation time, K=10 default — confirmed
  in §3, §5.
- §5.6 A1 failure-mode UX (typed errors, `pack tracker doctor` verb,
  no silent retry) — confirmed in §5, tests 5.x.
- §5.7 forward step extension (V1 §6.2 step 7 also processes phase-task
  Dependencies bullets in the second pass) — confirmed in
  `tracker-migrate-forward.sh` step 7b.

§6.Q recommendation (a) implemented as specified.
§6.R schema (already RESOLVED-RATIFIED post-BD-106) honored — the
cycle-graph store + sidecar `phase_tasks[].dependency_edges` separation
is documented in `tracker-cycle-check.sh` header comment as "graph
view vs persistence view".

No new POQs introduced.

---

**End of IMPLEMENTATION-REPORT-BD-108.**
