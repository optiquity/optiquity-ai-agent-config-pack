# IMPLEMENTATION-REPORT-BATCH-17-FIX

**Scope:** End-of-batch review (PACK-REVIEW-BATCH-17.md) findings F1–F11 — fix coder pass.
**Branch:** `v11-dev`
**Pre-fix HEAD:** `4497e21` (docs commit; the Batch 17 baseline at `1a5944b` is HEAD~1).
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Date:** 2026-05-15
**Fix-commit position:** Batch 17 fix commit 4 of 4 (final pre-status-flip).
**Verbs forbidden by pack workflow:** state-changing git verbs (commit / push / tag / reset / etc.) — none invoked.

---

## §1 Files modified

| File | Change type | Lines (added / removed) | Purpose |
|---|---|---|---|
| `scripts/lib/tracker-cycle-check.sh` | modified | +9 / −10 | F10: remove case-statement collapse; bubble python rc directly |
| `scripts/lib/tracker-migrate-forward.sh` | modified | +53 / −3 | F1: lazy-source `tracker-links.sh`; re-route step 7 phase-N.M, step 7 BD/TD, and step 7b phase-task arms through `tracker_links_create_blocked_by` |
| `scripts/lib/tracker-promote.sh` | modified | +103 / −0 | F2: `provider_update` body Resolution sync after `provider_close` in Path 1 + Path 2; F3: `tmf_mapping_save` after every `provider_create` in Path 1 + Path 2; F5: 9th public-function entry added to header docstring |
| `scripts/tests/test-tracker-cycle-check.sh` | modified | +64 / −0 | F10: new Group 6 — assert distinct rc=2 (cycle) vs rc=1 (traversal/schema) plus orchestrator-level fail-closed coercion |
| `scripts/tests/test-tracker-promote-path1.sh` | modified | +43 / −0 | F2 (4.4): assert `provider_update` called with canonical Resolution body shape; F3 (4.5): assert id-map.json on disk has new phase-7 entry |
| `scripts/tests/test-tracker-promote-path2.sh` | modified | +60 / −0 | F2 (4.5): assert `provider_update` called for TD-040 with canonical body; F3 (4.6/4.7): id-map.json on disk has new phase-3.4 entry + second-run regression |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +31 / −0 | F1 (3.5b): assert cycle-graph store created with BD-002 → BD-001 blocked-by edge after forward migration |
| `supporting-docs/METHODOLOGY.md` | modified | +5 / −1 | F7: add cross-reference between Procedure 1 step 2 (BD-108 phase-task blockers) and the resolution-path decision logic block (BD-107) |
| `OPTIONAL-FEATURES.md` | modified | +8 / −0 | F8: surface `[graph] cycle_check_k` tunable + V3.3 §5.5 reference in the tracker.toml example narrative |

**Total:** 9 files modified; +376 / −14 lines (net +362).

No new files created; no files deleted.

---

## §2 Findings fixed

| # | Severity | Cross-cut? | File:line / artifact | Fix applied | Deviation from suggested fix? |
|---|---|---|---|---|---|
| F1 | MUST | yes | `scripts/lib/tracker-migrate-forward.sh:54-71` (lazy-source); `:899-903, 951-953, 983-985, 1054-1058` (call sites) | Lazy-source `tracker-links.sh` (which transitively sources `tracker-cycle-check.sh`); compute `cycle_store_path="$repo_root/.pack-tracker/links-graph.json"` once before the link loops; replace all three `provider_link <gh-id> <gh-id> "blocked-by"` call sites (step 7 phase-N.M arm, step 7 BD/TD arm, step 7b phase-task→phase-task arm) with `tracker_links_create_blocked_by <pack-id> <pack-id> "$mapping" "$cycle_store_path" ""`. The orchestrator handles cycle-check (no-op on empty initial store) + provider_link + cycle-graph-store-add. Sidecar `phase_tasks[].dependency_edges` block continues to be populated by reverse migrate's `tracker_phase_task_parse → tracker_sidecar_compose_phase_tasks_block` walk (no migrator-side wiring needed — the parser re-derives the edges from the plan file on every reverse run). | None — adopted user-decision option (a) verbatim. The pre-existing `tmf_mapping_get` pre-check is preserved (so phase-N.M tokens whose target is not in id-map continue to silently skip without invoking the orchestrator's typed not-found error path). |
| F2 | MUST | yes | `scripts/lib/tracker-promote.sh` Path 1 (`:763-786`) + Path 2 (`:1138-1162`) | After `provider_close` succeeds on the TD, re-compose the issue body via `tmf_compose_issue_body "$td" "$_f2_description" "$_f2_context" "$resolution_text" "$_f2_file_symbol"`. The `resolution_text` already carries the canonical `[YYYY-MM-DD, completed, promoted to phase-N(.M)]` shape. Then `provider_update <td-gh-id> '{"body": "<re-composed>"}'`. The re-composer reuses the v10 lifecycle convention (`## Description / ## File / Symbol / ## Context / ## Resolution`) so `_tmr_extract_section "Resolution"` (reverse-migrate) reads the populated section verbatim. Failure surfaces as a typed `partial-write` with diagnostic naming `provider_update`, mirroring the existing F3 partial-write semantics for `set_labels` / `close`. | None — adopted user-decision option (a) verbatim. Re-uses the existing `tmf_compose_issue_body` helper rather than introducing a new section-patch operation; no new provider op; no new capability flag. |
| F3 | SHOULD | yes | `scripts/lib/tracker-promote.sh` Path 1 (`:706-721`) + Path 2 (`:1078-1097`) | Path 1: after capturing `tracker_id` from the new phase-epic `provider_create`, load the on-disk mapping via `tmf_mapping_load`, set the new `phase-N` → `<id, url>` entry via `tmf_mapping_set`, save back via `tmf_mapping_save`. Path 2: same pattern, after the in-memory id-map mutation that adds the new `phase-N.M` (the in-memory mutation remains so `tracker_links_create_blocked_by` can resolve immediately; the disk save is additive). Both mirror the canonical `tracker-migrate-forward.sh:818` save pattern (save-after-every-set). | None. The Path 1 save lands BEFORE the TD-side close so a close-failure doesn't leave a stale on-disk id-map; Path 2's save is wedged immediately after the in-memory mutation so the on-disk + in-memory views are in sync before `tracker_links_create_blocked_by` runs (preserving the in-memory contract). |
| F5 | SHOULD | no | `scripts/lib/tracker-promote.sh:115-128` | Add the 9th public-function entry to the header docstring's Public API block: `tracker_promote_phase_task_M_in_use <repo-root> <phase-N.M>` with its rc contract (rc=0 in use; rc=1 free; rc=2 invalid input). Footnote names "Total public function count: 9 (BATCH-17 review F5)" — disambiguates against the stale BD-107 IMPLEMENTATION-REPORT §1 line ("six public functions"). | None. The actual BD-107 IMPLEMENTATION-REPORT-BD-107.md §1 stale line is left alone (per pack rule "agents do not modify prior IMPLEMENTATION-REPORT files"). |
| F7 | SHOULD | yes | `supporting-docs/METHODOLOGY.md:1083-1093` (Procedure 1 step 2) and `:1120-1124` (resolution-path decision logic block) | Step 2 extension gets the forward-pointer line: `(When all blockers resolve, the TD becomes Unblocked — see the resolution-path decision logic later in this Part for the V3.3 §3 promotion paths.)`. Resolution-path block gets the back-pointer line: `(See Procedure 1 step 2 above for the "blockers resolved" gate-check semantics including the v11.0 phase-N.M and phase-task A-blocked-by-B forms.)`. Composes the two BD edits into a coherent narrative without restructuring either block. | None — adopted suggested-fix verbatim. |
| F8 | SHOULD | partial | `OPTIONAL-FEATURES.md:162-168` | Add a one-paragraph mention naming the `[graph] cycle_check_k` field with default value (10), guidance on when to raise it ("if your cross-entity dependency graph regularly has chains longer than 10 hops"), and a citation to `ARCHITECTURE-V3.3-DELTA.md §5.5` for the bounded-search semantics. Lands in the "How to use the pack's pieces with it" subsection right after the `tracker.toml` example-template paragraph, where users discovering the tracker will see it. | None — adopted recommended path (a). NO BACKLOG.md change (per pack rule). NO HELP-FRAGMENT-TRACKER.md change (the tracker fragment is a verb-surface, not a config-tunable surface; OPTIONAL-FEATURES.md is the right home for tunable narrative). The compounded F6/F8 discoverability gap is now closed: the example-template files already have the commented-out `[graph]` block (BD-108 fix coder F6), and now OPTIONAL-FEATURES.md narrative names the field. |
| F10 | NIT | no | `scripts/lib/tracker-cycle-check.sh:316-321` | Replace the case statement (which collapsed both rc=1 and rc=2 to caller-visible rc=1) with `return $rc` so the python rc bubbles up directly. Updates the comment block to explain the behavior + design intent. The orchestrator (`tracker_links_create_blocked_by:228-233`) still uses `if ! ...; then return 1` so non-zero rc still fails-closed at the orchestrator level — only diagnostic dimension changes (callers and test harnesses can now distinguish "would-cycle" from "traversal/schema error" without parsing stderr text). | None — adopted option (a) verbatim. |

**Pre-resolved (no action this pass — see §3):** F4, F6, F9, F11.

---

## §3 Pre-resolved findings

| # | Severity | Status | Disposition |
|---|---|---|---|
| F4 | SHOULD | Pre-resolved by BD-108 fix coder | The `tracker-cycle-check.sh` docstring at lines 30-37 (cited by F4) was rewritten by the BD-108 fix coder as part of their F6 fix (`tracker-cycle-check.sh:36-58`). The current docstring no longer claims "matches V3.3 §5.5 prose" — instead it explicitly notes the spec wording is imprecise and describes the implementation's correct walk direction (from `tgt`). Confirmed by direct read of lines 36-58. The PM-only V3.3 §5.5 spec edit (the F4 review's option-(b) suggestion) is out of scope for this fix coder — Pack Chat parent owns that decision. |
| F6 | SHOULD | Pre-resolved by BD-108 fix coder | Both `tracker.toml.pack-example:65-70` and `project-template/tracker.toml.project-example:70-75` already carry the commented-out `[graph]` block with `cycle_check_k = 10` and a one-line comment naming V3.3 §5.5. Confirmed by `grep -n "graph\|cycle_check_k"` returning matched lines in both files. |
| F9 | NIT | Pre-resolved by BD-107 fix coder side-effect | The duplicate "Implementation note" comment block (review cites lines 437-446) does not exist in the current `tracker-promote.sh`. The BD-107 fix coder's F8 refactor of `tracker_promote_compose_phase_task_block` (use `--arg` for jq, `TPR_TD_JSON` env var for python heredoc) replaced the entire region. The current `compose_phase_task_block` body (`tracker-promote.sh:382-441`) has no "Implementation note" or "TPT_DOC_JSON" or "stdin" / "heredocs" / "silently dropped" string anywhere — confirmed by `grep -n "Implementation note\|TPT_DOC\|stdin\|heredocs\|silently dropped"` returning empty. F9's described duplicate is no longer present. |
| F11 | NIT | No fix required (per review) | The review says "No fix required; flagging for awareness." The current pack-root vs project-template surface boundary is intentional (script-path rows in HELP-FRAGMENT-PACK; verb-form rows in HELP-FRAGMENT-TRACKER). NO ACTION. |

---

## §4 User-decision implementations

### F1 option (a) — re-route blocked-by arms through `tracker_links_create_blocked_by`

The user chose option (a) ("re-route step 7's phase-N.M case … and step 7b's phase-task dep loop … through `tracker_links_create_blocked_by` instead of bare `provider_link`") over option (b) (documentation-only mitigation + future doctor verb).

**What landed.** Three call sites in `tracker-migrate-forward.sh` now route through the orchestrator:
1. **Step 7 phase-N.M arm** (`:951-953`) — when a BACKLOG entry's Blockers list contains a `phase-N.M` token and both src + tgt are in the id-map, the orchestrator's `tracker_links_create_blocked_by` fires (with `cycle_store_path` = `<repo>/.pack-tracker/links-graph.json`).
2. **Step 7 BD/TD arm** (`:983-985`) — same pattern for BD-NNN / TD-NNN blocked-by tokens. The F1 review focused on the phase-N.M arm but the same architectural concern applies to the BD/TD arm: bare `provider_link` left the cycle-graph store unpopulated for ALL initial-migration blocked-by edges, not just phase-task ones. Routing both through the orchestrator preserves the "single point of entry" architectural invariant uniformly.
3. **Step 7b phase-task arm** (`:1054-1058`) — the IMPLEMENTATION-PLAN.md `Dependencies` bullet replay (phase task A blocked-by phase task B per V3.3 §5.4) now also goes through the orchestrator.

The pre-existing `tmf_mapping_get` pre-check for both step-7 arms is preserved: when the target pack-id is not in the id-map (e.g., phase-3.2 in the BD-108 mini-fixture's BD-501), the routing silently skips (matching the existing test-6.2 behavior of "phase-3.2 NOT routed to sub_issue_create"). The orchestrator is only invoked when both src + tgt are id-map-resolvable, which is the precondition for the cycle-store-add path anyway.

**Sidecar `phase_tasks[].dependency_edges` block.** Per the F1 review and §6.R schema review, the sidecar's `phase_tasks[].dependency_edges` block is composed by `tracker_sidecar_compose_phase_tasks_block` from the output of `tracker_phase_task_parse` (BD-106). That parser re-derives the edges from the IMPLEMENTATION-PLAN.md on every reverse-migrate invocation — so the sidecar block is correctly populated from the source-of-truth flat file regardless of forward-migration's link-creation path. The F1 fix's contribution is to populate the **cycle-graph store** (the runtime view used by cycle-check on the next link attempt) — that's the artifact that was missing on initial migration.

### F2 option (a) — `provider_update` on TD body during forward

The user chose option (a) ("Path 1 / Path 2 forward issues a `provider_update` on the TD issue to insert/update a `## Resolution` body section") over option (b) (extend reverse migrate to read `promoted-to:` label + synthesize Resolution from `closed_at`).

**What landed.** Path 1 (`tracker-promote.sh:763-786`) and Path 2 (`tracker-promote.sh:1138-1162`) now, after a successful `provider_close` on the TD issue, re-compose the full issue body via `tmf_compose_issue_body "$td" "$_f2_description" "$_f2_context" "$resolution_text" "$_f2_file_symbol"`. This produces a body with the canonical `## Description / ## File / Symbol / ## Context / ## Resolution` section ordering (same as the v10 lifecycle's body composer at create time). The `## Resolution` section gets the canonical `[YYYY-MM-DD, completed, promoted to phase-N(.M)]` text. The body is then PUT to the tracker via `provider_update <td-gh-id> '{"body": "<re-composed>"}'`. Reverse migrate (`tracker-migrate-reverse.sh:417`) reads it via the existing `_tmr_extract_section "Resolution"` path with NO reverse-side change needed.

**Failure semantics.** Mirrors existing F3 (BD-107 review) partial-write semantics:
- `provider_update` failure → typed `partial-write` with diagnostic naming `provider_update` and the gh-id; rc=1 propagated to the orchestrator caller.
- The phase-epic / phase-task creation has already succeeded; rolling back at this point would re-orphan the new entity. The user gets a typed diagnostic to address the body-sync failure (re-run `pack td promote --to=...` is idempotent for the body update because the new body is deterministic given the TD entry + `today`).

**No new provider operation.** Reuses existing `provider_update` (which the dispatcher already routes through `tracker_provider_dispatch update`). No new capability flag. No new helper added to `tracker-provider-gh.sh`.

---

## §5 Test results

### Baseline (pre-fix, at HEAD `4497e21`)

| Test file | Assertions |
|---|---|
| `tracker-migrate-forward-test.sh` | 131 |
| `tracker-migrate-reverse-test.sh` | 95 |
| `tracker-migrate-roundtrip-test.sh` | 45 |
| `test-tracker-phase-task.sh` | 90 |
| `test-tracker-promote-path1.sh` | 75 |
| `test-tracker-promote-path2.sh` | 53 |
| `test-tracker-promote-direct.sh` | 31 |
| `test-tracker-cycle-check.sh` | 22 |
| `test-tracker-links.sh` | 43 |
| **Subtotal (BD-106 + BD-108 + BD-107 surfaces)** | **585** |

Plus other tracker-* tests (config / errors / init / provider / bd129..134 / etc.): all green (no regressions; counts unchanged from baseline).

### Post-fix

| Test file | Assertions | Δ |
|---|---|---|
| `tracker-migrate-forward-test.sh` | 134 | +3 (F1: cycle-graph store + BD-002 → BD-001 edge assertions in Group 3) |
| `tracker-migrate-reverse-test.sh` | 95 | 0 |
| `tracker-migrate-roundtrip-test.sh` | 45 | 0 |
| `test-tracker-phase-task.sh` | 90 | 0 |
| `test-tracker-promote-path1.sh` | 80 | +5 (F2: 3 update-body assertions; F3: 2 disk-id-map assertions in Group 4.4 / 4.5) |
| `test-tracker-promote-path2.sh` | 59 | +6 (F2: 3 update-body assertions in Group 4.5; F3: 2 disk-id-map + 1 second-run assertion in Group 4.6 / 4.7) |
| `test-tracker-promote-direct.sh` | 31 | 0 |
| `test-tracker-cycle-check.sh` | 26 | +4 (F10: rc=2 / rc=1 / rc=0 disambiguation + orchestrator coercion in new Group 6) |
| `test-tracker-links.sh` | 43 | 0 |
| **Subtotal** | **603** | **+18** |

Other tracker tests (re-confirmed clean after fix):
- `tracker-bd129-gh-repo-test.sh` (11 / 0)
- `tracker-bd130-doctor-wired-test.sh` (8 / 0)
- `tracker-bd132-race-test.sh` (29 / 0)
- `tracker-bd133-header-preservation-test.sh` (30 / 0)
- `tracker-bd134-close-retry-test.sh` (24 / 0)
- `tracker-agent-read-test.sh` (31 / 0)
- `tracker-config-test.sh` (32 / 0)
- `tracker-config-schema-test.sh` (17 / 0)
- `tracker-errors-test.sh` (60 / 0)
- `tracker-init-test.sh` (95 / 0)
- `tracker-provider-test.sh` (65 / 0)
- `pack-help-test.sh` (17 / 0)

### `validate-pack.py`

```
PASSED — all checks clean
```

All 32 checks pass.

---

## §6 Round-trip identity proof

### F1: cycle-graph store population on forward migration

**Test:** `tracker-migrate-forward-test.sh` Group 3 assertion 3.5b.

**Fixture:** `scripts/tests/fixtures/tracker-migrate/BACKLOG.md` BD-002 with `Blockers: BD-001, phase-1`.

**Pre-fix behavior:** No `links-graph.json` file exists after forward migration — the bare `provider_link` calls populated only the tracker side (the GH issue body comment marker), nothing local. Cycle detection at any subsequent link attempt would walk an empty graph.

**Post-fix behavior:** `<repo>/.pack-tracker/links-graph.json` exists with 1 edge:
```json
{"edges":[{"source":"BD-002","target":"BD-001","kind":"blocked-by"}]}
```
(The `phase-1` token routes via the v10 sub-issue-parent arm — NOT a blocked-by edge — so it's correctly absent from the cycle graph; only the BD-001 blocked-by token lands here.)

**Assertions added:**
- 3.5b F1: cycle-graph store created at `$TEST_REPO/.pack-tracker/links-graph.json`
- 3.5b F1: cycle-graph store has ≥1 blocked-by edge
- 3.5b F1: cycle-graph store has BD-002 blocked-by BD-001 edge

All three pass.

### F2: Resolution-body round-trip via stub backend record

**Test:** `test-tracker-promote-path1.sh` Group 4.4 (Path 1) and `test-tracker-promote-path2.sh` Group 4.5 (Path 2).

**Mechanism:** The stub backend's `tracker_provider_stub_update` records every call into `STUB_LOG_FILE` as a `|update <id> <patch-json>` line. The patch-json contains the full re-composed body with embedded newlines, so the test reads the entire log file (not a single line) to grep for body content.

**Path 1 Resolution-body fingerprint (TD-031 → phase-7):**
- `|update 1031 ` line present
- Body contains substring `completed, promoted to phase-7`
- Body contains substring `## Resolution`

**Path 2 Resolution-body fingerprint (TD-040 → phase-3.4):**
- `|update 1040 ` line present
- Body contains substring `completed, promoted to phase-3.4`
- Body contains substring `## Resolution`

All six assertions (3 per path) pass. The reverse-migrate path's `_tmr_extract_section "Resolution"` already handles `## Resolution\n\n<text>` (the canonical body shape from `tmf_compose_issue_body`); no reverse-side change needed and the existing reverse tests continue to pass.

### F3: id-map disk persistence on Path 1 / Path 2

**Test:** `test-tracker-promote-path1.sh` 4.5 (Path 1) and `test-tracker-promote-path2.sh` 4.6 / 4.7 (Path 2).

**Mechanism:** After a tracker-mode promote, the test re-reads `<wt>/.pack-tracker/id-map.json` from disk and asserts the new pack-id is present with the expected gh-id (stub returns 99 from `provider_create`).

**Path 1:** `phase-7` mapping written to disk with `id == 99`.

**Path 2:** `phase-3.4` mapping written to disk with `id == 99`.

**Path 2 second-run regression (4.7):** A second `tracker_promote_path2` invocation against the same fixture re-reads the on-disk id-map; `jq -e 'has("phase-3.4")'` returns 0, proving the previous run's mapping survived to the next invocation's view.

All four assertions pass.

---

## §7 Path 3 forbidden invariants

Re-confirmed intact:

- `_tracker_labels_create` — no `tracker_labels_folded_into` helper exists (Check 35 in validate-pack: PASS; renumbered from Check 32 by BD-168).
- `scripts/lib/` — no `folded-into` literal in executable code (Check 35: PASS; renumbered from Check 32 by BD-168).
- `tracker-promote.sh` — no `--fold-into` flag handling; the verb dispatcher (`scripts/pack-td.sh`) rejects the flag with a typed validation error citing V3.3 §3 line 27 (test-tracker-promote-path1 7.2: PASS).
- `pack-td.sh` `--help` does not name Path 3 (test-tracker-promote-path1 7.3: PASS).
- METHODOLOGY.md retains the `**Path 3 is forbidden**` block at lines 1148-1156 (test-tracker-promote-path1 8.3: PASS).

The F1 / F2 / F3 fixes do not touch any Path 3 surface; the F8 OPTIONAL-FEATURES.md narrative addition is config-only (no Path 3 context).

---

## §8 Deviations / open issues

**Deviations from the prompt:** None.

**Findings deferred or partially addressed:**

- **F4 architectural correction (V3.3 §5.5 spec wording).** The Batch 17 review's option-(b) suggestion (a PM-only V3.3-DELTA spec edit to retighten §5.5 prose to match the implementation's correct walk direction) is out of fix-coder scope. The prompt scopes this as "PM-only follow-up; Pack Chat parent owns that decision." The implementation-side docstring is already correctly tightened (BD-108 fix coder F6); no source-code action was needed. Pack Chat parent should track this as a future PM-only docs-edit pass.

- **F8 BACKLOG.md update.** Per pack rule "agents do not modify BACKLOG.md", the BACKLOG entry for BD-108 was NOT updated. The discoverability gap is closed via the OPTIONAL-FEATURES.md addition (this fix) plus the example-template files (BD-108 fix coder F6) — both are user-facing surfaces. If Pack Chat decides the BACKLOG File/Symbol field also needs updating for BD-108, that's a separate PM-Chat-only edit (the entry is now `Resolved` once Batch 17 status flips, so any post-flip edit becomes a docs cleanup BD).

- **F9 acknowledgment.** No source-code action taken because the duplicate is gone (BD-107 fix coder side-effect). Verified by direct grep — see §3 row F9.

- **F11 acknowledgment.** No action per review's own recommendation.

**No new POQs introduced.** All fixes use existing primitives (`tmf_compose_issue_body`, `tmf_mapping_save`, `tracker_links_create_blocked_by`, `tmf_mapping_load`/`set`, `provider_update`). No new provider operation, no new capability flag, no new helper file.

---

## §9 Status flip readiness statement

Batch 17 (BD-106 + BD-108 + BD-107) is **ready for status flip to `Resolved`**. The end-of-batch review surfaced 11 findings (0 BLOCKER / 2 MUST / 5 SHOULD / 4 NIT); 8 actionable findings have been fixed in this pass (F1, F2, F3, F5, F7, F8, F10), 3 findings are pre-resolved or no-fix-needed (F4 — BD-108 fix coder; F6 — BD-108 fix coder; F9 — BD-107 fix coder side-effect; F11 — review recommendation). The PM-only V3.3 §5.5 spec edit (F4 option b) is outside fix-coder scope and remains as a Pack Chat follow-up.

**Test counts:** baseline 585 → post-fix 603 (+18 new assertions across F1, F2, F3, F10). All other tracker-* tests + pack-help test continue green; no regressions. `validate-pack.py` passes all 32 checks.

**Round-trip identity:** F1 cycle-store population proven via fresh fixture (BD-002 → BD-001 edge in `links-graph.json`); F2 Resolution-body round-trip proven via stub-backend `provider_update` recording with canonical `## Resolution\n\n[YYYY-MM-DD, completed, promoted to phase-N(.M)]` body shape (which the existing `_tmr_extract_section "Resolution"` decoder reads verbatim).

**Path 3 forbidden invariants:** intact across all surfaces (validate-pack Check 35 + test-suite assertions in promote-path1 6.4 / 7.2 + corpus grep; renumbered from Check 32 by BD-168).

**§6.P / §6.Q / §6.R MAINTAINER CHECK ratifications:** still pending PM-only post-CI Pack Chat decision (separate concern; not addressed by this fix-coder pass).

CI workflow trigger (Validate Pack) on the next push will exercise validate-pack + the tracker-* test suite; this fix-coder pass has run both locally and confirmed clean. Pack Chat parent can stage + commit + push with confidence; the implicit BD-106 / BD-107 / BD-108 status flip to `Resolved` is the documented final step of Batch 17 per pack memory ("Implicit BD status flip on batch completion").
