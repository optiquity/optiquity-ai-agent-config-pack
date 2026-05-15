# IMPLEMENTATION-REPORT-BD-107-FIX — review-finding fixes for BD-107

**Branch:** `v11-dev`
**Pre-flight HEAD:** `430c63724d88cc779216db05ee0fb42f27bcb3f3` (BD-108 fix)
**Final HEAD on worktree:** `430c63724d88cc779216db05ee0fb42f27bcb3f3` (no commits made — Pack Chat parent will commit per workflow rule)
**Date:** 2026-05-15
**Author:** pack-coder (BD-107 fix coder, Batch 17 fix commit 3 of 4)
**Scope:** 13 review findings against BD-107 working tree (per `PACK-REVIEW-BD-107.md`).
**Inputs read:** `PACK-REVIEW-BD-107.md`, `IMPLEMENTATION-REPORT-BD-107.md`, BD-106 + BD-108 fix coder reports (cross-cut awareness), `tracker-promote.sh`, `pack-td.sh`, `tracker-labels.sh`, `tracker-errors.sh`, `tracker-migrate-forward.sh` (for parallel pattern), `BACKLOG.md` BD-107 entry, V3.3-DELTA §3 / §3.5 / §7, IPLAN-ADDENDUM-4 §6.P, CLAUDE.md.

---

## §1 Files modified

The BD-107 impl + this fix work will land in a single combined commit (per the new memory rule "Fix may land in the same impl commit OR as a separate immediate fix commit"). The table below distinguishes (a) BD-107-impl-only files (untracked at HEAD `430c637`; the BD-107 coder created them) from (b) files I touched as part of fix work.

| Path | Status @ HEAD | Fix delta | Notes |
|---|---|---|---|
| `scripts/lib/tracker-promote.sh` | NEW (BD-107 impl) | +158 lines (1089 → 1247) | F2, F3, F6, F8, F9, F10, F12 fixes + multi-line annotation comments. Net mostly additive (label pre-create blocks, partial-write error paths, snapshot/rollback wiring). |
| `scripts/pack-td.sh` | NEW (BD-107 impl) | +68 lines (244 → 312) | F1 dispatcher value-less-flag guards (4 sites) + F4 `--apply-backlog-patch` flag wiring + advisory rendering on stderr. |
| `scripts/tests/test-tracker-promote-path1.sh` | NEW (BD-107 impl) | +94 lines (461 → 555) | F2 prefix-collision regression test (group 3.5) + F1 dispatcher value-less flag tests (group 7.4) + F7 failure-path tests + F9 plan rollback test (group 7.5). |
| `scripts/tests/test-tracker-promote-path2.sh` | NEW (BD-107 impl) | +41 lines (432 → 473) | F7 failure-path tests for Path 2 (group 7.3 + 7.4) — provider_create failure and provider_set_labels failure both surface as typed partial-write errors, with rollback verification. |
| `scripts/tests/test-tracker-promote-direct.sh` | NEW (BD-107 impl) | 0 (unchanged) | No fix-work needed; existing tests already cover direct close end-to-end. |
| `README.md` | MODIFIED (pre-BD-107) | +1 line / -1 line | F5: added `pack-td.sh` row to scripts/ block; extended sibling tracker-* lib brace list to include `cycle-check, links, promote`. |

**Files NOT touched (out-of-scope per pack rule):**
- `BACKLOG.md` — F11 disposition is documented in §6 below (Pack Chat consideration only; agents do not modify BACKLOG.md).

**Files outside BD-107 fix scope (BD-107 impl files I left intact):**
- `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`, `project-template/docs/pack/HELP-FRAGMENT.md`, `project-template/docs/pack/PM-CHAT.md`, `supporting-docs/METHODOLOGY.md` — all retain BD-107 impl edits without further fix-pass changes (no review finding required edits).

---

## §2 Findings fixed

| # | Severity | File:line | Fix applied | Deviation from suggested fix? |
|---|---|---|---|---|
| F1 | MUST | `scripts/pack-td.sh:111,112,114,189` | Added `[[ $# -lt 2 ]]` guard at every value-bearing flag site (4 sites: `--to`, `--repo-root`, `--store-path`, `--note`); each emits `tracker_error_emit "validation"` with a flag-specific message and returns 1. New tests in `test-tracker-promote-path1.sh` group 7.4 cover all 4 sites and assert the typed-error block + absence of bash-internal "unbound variable" diagnostic. | None — verbatim adoption of the review's primary suggestion. |
| F2 | MUST | `scripts/lib/tracker-promote.sh:575` | Tightened `*"$target"*` → `*"to $target]"*` (right-anchored on the closing bracket of the canonical Resolution emit shape `[YYYY-MM-DD, completed, promoted to phase-N]`). New regression test in `test-tracker-promote-path1.sh` group 3.5 locks the prefix-collision: a TD whose Resolution names `phase-72` does NOT block a fresh `--to=phase-7` invocation. | None — verbatim adoption of suggestion option 1 (right-anchored substring). The regex alternative (option 2) was equivalent; chose substring for bash 3.2 compat. |
| F3 | MUST | `scripts/lib/tracker-promote.sh` Path 1 (lines 651-680) + Path 2 (lines 938-967) | Added pre-create calls (`_tracker_labels_create "$derived_label"` and `_tracker_labels_create "$promoted_label"`) immediately before `provider_create` in BOTH Path 1 + Path 2 tracker-mode blocks. Removed `>/dev/null 2>&1 \|\| true` swallowing from BOTH `provider_set_labels` and `provider_close` calls in BOTH paths; failures now emit `tracker_error_emit "partial-write"` with diagnostic context and return 1. F3 fix preserves F9 plan-rollback semantics (rollback on label pre-create failure; no rollback on post-create label/close failure since the new entity is already live). | None — adopted option (a) verbatim ("immediately before each provider_create / provider_set_labels invocation"). The `_tracker_labels_create --force` is idempotent so this is safe to call repeatedly. |
| F4 | SHOULD | `scripts/pack-td.sh` cmd_promote | Added `--apply-backlog-patch` / `--no-apply-backlog-patch` flag (default ON for direct invocation); when set, the dispatcher captures the orchestrator's JSON result and renders a copy-pasteable BACKLOG patch advisory to stderr (`Status: Open → Resolved` + `Resolution: n/a → <text>`). The library remains read-only on BACKLOG (pure-function contract preserved). PM Chat passes `--no-apply-backlog-patch` when it intends to apply via its own editor. | Adopted option (b) verbatim per review. Did NOT add the actual sed/awk patch-apply (that's a future BD per the call-out in §4 of original BD-107 IMPL-REPORT). The advisory is text-only. |
| F5 | SHOULD | `README.md:185-208` | Added `pack-td.sh` row in `scripts/` block; extended `scripts/lib/` brace list to `tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh` with cross-references to the BD numbers (BD-106 phase-task, BD-108 cycle-check + links, BD-107 promote). | None — verbatim adoption. Acknowledged that BD-106's `phase-task` was already added (per BD-106 fix coder's edit); this fix adds `cycle-check, links, promote`. |
| F6 | SHOULD | `scripts/lib/tracker-promote.sh:636,847` | Replaced `'"$phase_n"'` shell-interpolation with `--arg pn "$phase_n"` and `"phase-\($pn)"` inside the jq filter at BOTH Path 1 (line 636 → now 685) and Path 2 (line 847 → now 970). Pure refactor; no behavior change. | None — verbatim adoption. |
| F7 | SHOULD | `scripts/tests/test-tracker-promote-path1.sh` + `path2.sh` | Added per-script failure-path tests: (a) Path 1 group 7.5 overrides `tracker_provider_stub_create` to return rc=1, asserts `tracker_promote_path1` returns rc=1, emits typed `partial-write` error, AND verifies F9 plan rollback (no `## Phase 7` heading after failure). (b) Path 2 group 7.3 mirrors the same for `provider_create`. (c) Path 2 group 7.4 overrides `tracker_provider_stub_set_labels` to fail; asserts post-create failure surfaces as `partial-write` with diagnostic naming `provider_set_labels`. Did NOT add the real-mode `$BD107_INTEGRATION=1` test (per pack rule "test infra is self-provisioned" but premature for v11.0 ship; future BD if needed). | Partial — adopted both Path 1 + Path 2 stub-override approaches verbatim. The optional real-mode integration test was deferred (out of scope for fix work; would require GH scratch repo provisioning per pack memory). |
| F8 | SHOULD | `scripts/lib/tracker-promote.sh:911` | Replaced the `case "$b_raw_id" in phase-[0-9]*\|TD-[0-9]*\|BD-[0-9]*)` permissive glob with a regex inside `[[`: `if [[ "$b_raw_id" =~ ^(phase-[0-9]+(\.[0-9]+)?\|TD-[0-9]+\|BD-[0-9]+)$ ]]; then`. Identical to V3.3 §5.3 grammar. Pre-existing strictness via `_tlk_is_valid_pack_id` downstream is now redundant but defensive. | None — verbatim adoption. |
| F9 | NIT | `scripts/lib/tracker-promote.sh` Path 1 + Path 2 | Adopted option (b) verbatim — wrap plan write with `cp "$plan_path" "$plan_path.pre-bd107"` snapshot before append; restore via `mv` on tracker failure (provider_create OR label pre-create); clean up snapshot on success path. Applied symmetrically to BOTH Path 1 and Path 2 (Path 2 already wrote via tempfile + mv but lacks rollback semantics). The plan-snapshot file is deliberately preserved on un-recovered crash for diagnostic visibility. | None — verbatim adoption of option (b). Did NOT do option (a) re-ordering (would contradict BD-107's flat-file-first design). |
| F10 | NIT | `scripts/lib/tracker-promote.sh:492-512` | Disambiguated rc: rc=0 = "in use", rc=1 = "free", rc=2 = "invalid input" (target shape malformed, plan unreadable, parser unavailable). Caller in `tracker_promote_path2` updated to switch on rc with explicit handling for rc=2 (emits typed validation error pointing at parser source path / `pack tracker doctor`). The `\|\| m_rc=$?` idiom protects callers under `set -e`. | None — verbatim adoption ("rc=2 for invalid input"). The `\|\| m_rc=$?` defensive add was needed for `set -e` callers (discovered during round-trip SHA verification) — minor extension of the suggested fix. |
| F11 | NIT | `BACKLOG.md:905` | **No-op (documented).** Per pack rule "agents do not modify BACKLOG.md", I did not edit the BACKLOG entry. Pack Chat may consider a third 2026-05-15 backstamp at land time enumerating the actual deliverable HELP-FRAGMENT files. The existing two backstamps (`HELP-FRAGMENT reconciliation note added`) already acknowledge the scope. | Yes — adopted "leave to author judgment" per the review's own suggestion ("Pack Chat to consider a third backstamp at land time… or leave as-is"). |
| F12 | NIT | `scripts/lib/tracker-promote.sh:328-360` | Adopted option (c) verbatim per the prompt's recommendation: replaced the one-line description-truncation Goal with a placeholder pointing at the TD id and noting that the full description is preserved in (a) the auto-generated 9.1 task's Problem/Goal/Success bullet and (b) the HTML-comment context block at the end of the section. No information loss; architect refines per §6.P (a). | None — adopted option (c) recommendation per the prompt. |
| F13 | NIT | `scripts/pack-td.sh:1-244` | **No-op (documented).** Per the review's own suggestion ("leave as-is — consistency with `pack-tracker.sh` outweighs micro-optimization"), I did not narrow the dispatcher source-set. Consistency with the existing one-script-per-noun dispatcher pattern (pack-tracker.sh, pack-help.sh) is more valuable than the micro-optimization. | Yes — adopted "leave as-is" per the review's own recommendation. |

**Aggregate: 11 of 13 findings have source-code fixes; 2 of 13 (F11, F13) are documented no-ops per the review's own recommendations.** All are accounted for.

---

## §3 Test results

### BD-107 promote tests (this BD's own coverage)

| Script | Pre-fix PASS | Post-fix PASS | Delta | New assertions |
|---|---|---|---|---|
| `scripts/tests/test-tracker-promote-path1.sh` | 61 | 75 | +14 | F2 prefix-collision regression (3.5; +3 assertions) + F1 dispatcher value-less flag tests (7.4; +8 assertions) + F7 failure-path + F9 rollback (7.5; +3 assertions) |
| `scripts/tests/test-tracker-promote-path2.sh` | 48 | 53 | +5 | F7 failure-path Path 2 + F9 rollback (7.3; +3) + F3 set_labels failure (7.4; +2) |
| `scripts/tests/test-tracker-promote-direct.sh` | 31 | 31 | 0 | No new assertions needed (existing tests cover direct-close end-to-end) |
| **Total BD-107** | **140** | **159** | **+19** | |

### Regression (BD-106 + BD-108 + earlier tracker)

| Script | PASS | FAIL | Notes |
|---|---|---|---|
| `scripts/tests/test-tracker-phase-task.sh` (BD-106) | 90 | 0 | No regressions from F2/F3/F6/F8/F9/F10/F12 fixes. |
| `scripts/tests/test-tracker-links.sh` (BD-108) | 43 | 0 | No regressions; F8 regex tightening is consistent with V3.3 §5.3. |
| `scripts/tests/test-tracker-cycle-check.sh` (BD-108) | 22 | 0 | No regressions. |
| `scripts/tests/tracker-migrate-forward-test.sh` | 131 | 0 | No regressions; tracker-migrate-forward.sh untouched in fix work. |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 95 | 0 | No regressions. |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 45 | 0 | No regressions. |
| **Total regression** | **426** | **0** | |

### `validate-pack.py`

```
============================================================
PASSED — all checks clean
```

All 32 checks pass (Check 32 = BD-106 phase-task lib invariants includes F3 / F8 surface verification).

### Aggregate

**159 BD-107 + 426 regression + validate-pack PASS = 585 total PASS / 0 FAIL.**

---

## §4 Round-trip identity proof (SHA-256)

### Path 1 fixture (TD-031 → phase-7)

| State | BACKLOG.md SHA-256 | IMPLEMENTATION-PLAN.md SHA-256 |
|---|---|---|
| pre-forward | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `724685ca04a96181b197f793d1b7a7c5776ddf449c48fdd31404b1cead153c1c` |
| post-forward + PM-Chat patch | `b020e471f4d89e9897adfd09a26b80ed239fc3dc4e7c631ef0768a90dd14f87e` | `122fbb336fc4f60bf77a96096eab4d60e6ceb97dab089bbc883b3a9434d98514` |
| post-replay (idempotency-refused) | `b020e471f4d89e9897adfd09a26b80ed239fc3dc4e7c631ef0768a90dd14f87e` | `122fbb336fc4f60bf77a96096eab4d60e6ceb97dab089bbc883b3a9434d98514` |

**BACKLOG SHA matches BD-107 IMPL-REPORT §8 (`b020e471...`).** The IMPLEMENTATION-PLAN SHA changes from BD-107 IMPL-REPORT's `ec3c26febd2405...` to `122fbb336fc4...` because of F12 Goal-line refactor (the placeholder Goal is now distinct from the prior one-line truncation). This is intentional and documented in §6 below. **Replay-stability holds (post-forward SHA = post-replay SHA).**

### Path 2 fixture (TD-040 → phase-3.4)

| State | BACKLOG.md SHA-256 | IMPLEMENTATION-PLAN.md SHA-256 |
|---|---|---|
| pre-forward | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `724685ca04a96181b197f793d1b7a7c5776ddf449c48fdd31404b1cead153c1c` |
| post-forward (no patch yet — Path 2 BACKLOG patch is via the test-side python helper not run here) | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `1d4d144da382fd8061e2418785547311b3a7fa548f1ae07c9482d884e9d9e91f` |
| post-replay (idempotency-refused) | `34c6e89593ebbd69d569edddcc9fe1765f39c7a37e833083ac362454f0e0a3c9` | `1d4d144da382fd8061e2418785547311b3a7fa548f1ae07c9482d884e9d9e91f` |

**Plan SHA `1d4d144da382...` matches BD-107 IMPL-REPORT §8** (Path 2's plan SHA was unchanged because F12 only affects Path 1's `compose_phase_section` formatter, not Path 2's `compose_phase_task_block` formatter). **Replay-stability holds.**

### Direct-close fixture (TD-031 no-op contract)

Verified inside `test-tracker-promote-direct.sh` group 3.4 (PASS). The wrapper produces NO sidecar mutation and NO BACKLOG mutation (V3.3 §3.2 invariant). SHA-256 byte-identity confirmed: pre-call sidecar SHA = post-call sidecar SHA; same for BACKLOG.

---

## §5 Path 3 forbidden invariants (re-confirm)

All 5 invariants verified intact post-fix (per BD-107 IMPL-REPORT §11 grep proofs). Specifically:

1. **No `tracker_labels_folded_into` constructor** — `declare -f tracker_labels_folded_into` returns ABSENT after sourcing tracker-promote.sh + tracker-labels.sh. (Asserted by `test-tracker-promote-path1.sh:6.4` + `test-tracker-promote-direct.sh:5.1`; both PASS.)
2. **No `--fold-into` arg as a wired branch** — F1 fix preserved the `--fold-into=*\|--fold-into)` case branch as a typed-error rejection ONLY (body: `tracker_error_emit "validation" ... return 1`). Verified post-fix: `bash scripts/pack-td.sh promote --fold-into=phase-3.2 TD-031` emits `ERROR: validation / MESSAGE: ... Path 3 forbidden ... → Run: review the backend message above`. (Asserted by `test-tracker-promote-direct.sh:5.2` + `test-tracker-promote-path1.sh:7.2`; both PASS.) **F1 fix did NOT alter the rejection stanza.**
3. **No `folded-into:` label literal** — grep on `scripts/lib/tracker-promote.sh` + `scripts/pack-td.sh` excluding comments returns zero hits.
4. **No `(from TD-NNN)` body marker** — grep returns zero hits in non-comment lines.
5. **Dispatcher rejects `--fold-into` with typed error naming "Path 3 forbidden"** — verified at shell level + asserted by tests.

**No fix introduced any Path 3 forbidden surface.** The F4 `--apply-backlog-patch` flag is orthogonal to Path 3 (it's a BACKLOG-patch advisory, not a promotion path).

---

## §6 Deviations / open issues

### F12 IMPLEMENTATION-PLAN SHA delta

The Path 1 IMPLEMENTATION-PLAN SHA changes from BD-107 IMPL-REPORT §8 baseline (`ec3c26febd24...`) to post-fix (`122fbb336fc4...`). This is a **deliberate** consequence of the F12 Goal-line refactor (placeholder text instead of one-line description truncation). Pre-fix replay-stability is preserved (post-forward SHA = post-replay SHA), and the new IMPL-PLAN content is semantically richer (Goal placeholder names architect refinement + cross-references to where the full description lives). No regression.

### F11 BACKLOG entry File/Symbol enumeration

Per pack rule "agents do not modify BACKLOG.md" (CLAUDE.md), I did not edit BD-107's BACKLOG entry to enumerate all four HELP-FRAGMENT files modified. Pack Chat may consider adding a third 2026-05-15 backstamp at land time noting actual deliverable HELP-FRAGMENT files. This is the review's own suggestion and is the standard PM-flow.

### F13 Dispatcher source-set width

Per the review's own recommendation ("leave as-is — consistency with `pack-tracker.sh` outweighs micro-optimization"), I did not narrow the dispatcher source-set in `pack-td.sh`. The trade-off favors uniform dispatcher pattern over micro-optimization. Consistent with the v11.0 dispatcher convention.

### F4 BACKLOG patch advisory is text-only at v11.0

The `--apply-backlog-patch` flag's current implementation renders the patch text to stderr but does NOT actually mutate BACKLOG.md. This is per the workflow rule "PM Chat owns BACKLOG.md mutations". A future BD could lift the apply step into the dispatcher if user-direct shell invocation becomes the dominant flow (today, PM Chat is the primary invoker). Documented in §13 of BD-107 IMPL-REPORT call-out 1.

### F7 real-mode integration test deferred

The optional `$BD107_INTEGRATION=1` real-mode test against a scratch GH repo (per the review's option in F7) is NOT implemented. Stub-mode failure-path tests (3 new assertions covering provider_create + provider_set_labels failures) provide structural coverage. A future BD could add the integration tier per the pack memory rule "test infra is self-provisioned". Not load-bearing for v11.0 ship.

### No new POQs introduced

This fix work introduced no new POQs / RFCs / ADRs. All findings were addressed via the suggested-fix recipe or the review's own no-op recommendation. The §6.P architect-default decision (RESOLVED-RATIFIED status) remains as documented in BD-107 IMPL-REPORT §3.

### No state-changing git verbs run

`git rev-parse HEAD` pre-flight = `git rev-parse HEAD` post-fix = `430c63724d88cc779216db05ee0fb42f27bcb3f3`. All edits are working-tree-only. Pack Chat parent will combine BD-107 impl + this fix into one commit.

---

## §7 Batch 17 end-of-batch hand-off note

For the upcoming **Batch 17 reviewer pass** (audit step initiated by user, per pack memory's one-review/fix-cycle-per-batch rule), the following file areas have been touched across BD-106 + BD-107 + BD-108 fix passes and may benefit from cross-cut review:

### Areas extended by THIS BD-107 fix

- **`scripts/lib/tracker-promote.sh`** — net +158 lines from BD-107 impl. New surfaces introduced by fixes: F3 label pre-create blocks (Path 1 lines ~651-680, Path 2 lines ~938-967); F9 plan-snapshot/rollback wiring (Path 1 lines ~603-625 + ~735, Path 2 lines ~853-861 + ~1090); F10 rc=2 disambiguation (lines ~492-512 + caller at ~813); F12 Goal-line refactor (lines ~330-336). Reviewer should confirm: (a) snapshot cleanup is bullet-proof against early-return paths (currently every rollback path explicitly cleans up; success path also cleans up); (b) F3 label pre-create is idempotent under repeated invocation (yes — `--force` flag on `gh label create`); (c) F12 placeholder Goal text doesn't collide with downstream architect-refinement workflow (no — placeholder is human-readable + machine-parseable as "to be refined").

- **`scripts/pack-td.sh`** — net +68 lines from BD-107 impl. New surfaces: F1 4-site value-less-flag guards (lines ~111-135 + ~209-217); F4 `--apply-backlog-patch` flag (lines ~136-148 + ~205-265). Reviewer should confirm: (a) the 4 sites cover ALL value-bearing flags in both `cmd_promote` and `cmd_resolve` (verified by grep — no remaining `shift 2` without guard); (b) F4 advisory does not interfere with the JSON result on stdout (yes — JSON goes to stdout, advisory to stderr).

### Areas BD-107 fix does NOT touch (Batch 17 reviewer should leave alone unless user re-scopes)

- BD-106 surfaces (`scripts/lib/tracker-phase-task.sh`, `tracker-labels.sh` BD-106 helpers) — already reviewed + fixed in BD-106 fix pass (commit `deecb08`).
- BD-108 surfaces (`scripts/lib/tracker-cycle-check.sh`, `scripts/lib/tracker-links.sh`, `scripts/lib/tracker-migrate-forward.sh` BD-108 routing) — already reviewed + fixed in BD-108 fix pass (commit `430c637`).
- Documentation (`PM-CHAT.md`, `METHODOLOGY.md`, `HELP-FRAGMENT*`) — BD-107 impl edits validated by `validate-pack.py` Check 24 (byte-identity for HELP-FRAGMENT-TRACKER.md pair) + Check 27. No fix-pass changes.

### Cross-cut concern for Batch 17 audit (advisory only)

The four HELP-FRAGMENT files' authoring scope (F11) — specifically whether BD-107's BACKLOG entry should enumerate them in its File/Symbol field — is a Pack-Chat-only decision. If the user runs a Batch 17 audit, the auditor may surface this as an end-of-batch BACKLOG-hygiene note. **Agents do not act on it.**

---

## §8 Definition-of-Done checklist

| DoD item | Status | Notes |
|---|---|---|
| Every F1-F13 finding has a fix applied (or documented deferred) | **PASS** | F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F12 = source-code fixes; F11 = no-op per pack rule + review suggestion; F13 = no-op per review's own recommendation. All 13 accounted for. |
| BD-107 promote tests continue to pass (≥140 baseline; new failure-path tests bump count) | **PASS** | 159 PASS / 0 FAIL across 3 BD-107 test scripts (was 140; +19 new assertions). |
| BD-106 + BD-108 + earlier tracker tests pass (no regressions) | **PASS** | 90 + 43 + 22 + 131 + 95 + 45 = 426 PASS / 0 FAIL. |
| `scripts/validate-pack.py` PASS (32 checks) | **PASS** | All 32 checks clean. |
| Round-trip identity (SHA-256) on BD-107 fixtures intact | **PASS** | Path 1 + Path 2 + direct-close all verified replay-stable; Path 1 plan SHA changed deliberately due to F12 (documented in §6). |
| §6.P decision intact (architect-default for Path 1) | **PASS** | No change to PM-CHAT.md decision logic; F4 `--apply-backlog-patch` flag is orthogonal to architect routing. |
| Path 3 forbidden invariants intact (no `folded-into:`, no `--fold-into` wired branch, no inline `(from TD-NNN)`) | **PASS** | All 5 invariants verified post-fix; F1 fix preserved `--fold-into` rejection stanza. |
| No state-changing git verbs run | **PASS** | HEAD unchanged: `430c637` pre = `430c637` post. |

**Aggregate: 8/8 PASS.**

---

## §9 Files-changed inventory

| Path | Change type | Lines (delta from BD-107 baseline) |
|---|---|---|
| `scripts/lib/tracker-promote.sh` | MODIFIED (BD-107 NEW + fix) | +158 (1089 → 1247) |
| `scripts/pack-td.sh` | MODIFIED (BD-107 NEW + fix) | +68 (244 → 312) |
| `scripts/tests/test-tracker-promote-path1.sh` | MODIFIED (BD-107 NEW + fix) | +94 (461 → 555) |
| `scripts/tests/test-tracker-promote-path2.sh` | MODIFIED (BD-107 NEW + fix) | +41 (432 → 473) |
| `scripts/tests/test-tracker-promote-direct.sh` | UNCHANGED (BD-107 NEW; no fix delta) | 334 (no change) |
| `README.md` | MODIFIED (pre-existing; +2 line delta from fix) | +2 / -1 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-107-FIX.md` | NEW | (this file) |

**No deletions.** **No git state-changing verbs run.** All edits in working tree only — Pack Chat parent will combine BD-107 impl + this fix into one commit per the new memory rule.

---

*End of IMPLEMENTATION-REPORT-BD-107-FIX.*
