# IMPLEMENTATION-REPORT-BD-106-FIX

**Scope:** Apply 12 findings from `PACK-REVIEW-BD-106.md` (F1..F13; F13 = no-op per author judgment) against the BD-106 commit `bf26789`. Batch 17 retrospective per-BD review/fix cycle, applied 2026-05-15.

**Branch:** `v11-dev`
**Worktree HEAD at session end:** `c8dab78` (Pack Chat pre-staged `Batch 21c` docs commit during this session; my working-tree fix-edits sit on top).
**Worktree HEAD at session start:** `f209b04`.

## §1 Files modified

All edits are in the working tree only (no state-changing git verbs run by this agent).

| Path | Change type | Lines (+/−) | Findings addressed |
|---|---|---|---|
| `scripts/lib/tracker-phase-task.sh` | modified | +57 / −11 | F1 (2 sites), F2, F4 (docstring), F5, F10, F11 |
| `scripts/lib/tracker-sidecar.sh` | modified | +1 / −1 | F1 (1 site) |
| `scripts/lib/tracker-labels.sh` | modified | +2 / −2 | F1 (2 sites) |
| `scripts/lib/tracker-migrate-forward.sh` | modified | +11 / −3 | F1 (1 site), F6 |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +1 / −1 | F1 (1 site) |
| `scripts/tests/test-tracker-phase-task.sh` | modified | +153 / −9 | F1 (test contract), F2 (group-1 parity), F3 (yaml-quote), F4 (non-canonical), F6 (regression), F12 (emit empty) |
| `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md` | modified | +2 / 0 | F3 (annotations with `:` / `#`) |
| `scripts/tests/fixtures/tracker-phase-task/ROUNDTRIP-NONCANONICAL.md` | NEW | +9 / 0 | F4 (non-canonical fixture) |
| `scripts/validate-pack.py` | modified | +110 / 0 | F8 (Check 32 added + wired) |
| `README.md` | modified | +1 / −1 | F7 (repo-layout glob) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-106.md` | modified | +15 / 0 | F9 (§13 post-land update) |

**Net:** 11 files touched (10 modified + 1 new); ~356 insertions / ~28 deletions in the BD-106 fix scope (per `git diff --stat`).

## §2 Findings fixed

| # | Sev | Location (file:line, pre-fix) | Fix applied | Deviation from suggested fix? |
|---|---|---|---|---|
| F1 | MUST | 7 sites listed below | Replaced each ad-hoc `printf 'ERROR: ...' >&2; return 1` with `tracker_error_emit "<code>" "<message>"` using codes per the review (`not-found`, `validation`). Test 2.6 extended to assert all three lines of the typed-error contract (`ERROR:`, `MESSAGE:`, `→ Run:`) are emitted, locking the contract going forward. | None — followed suggested fix verbatim. |
| F1.1 | (site) | `tracker-phase-task.sh:156` (parser missing-file) | `tracker_error_emit "not-found" "tracker_phase_task_parse: $path does not exist"` | — |
| F1.2 | (site) | `tracker-phase-task.sh:450` (emit empty input) | `tracker_error_emit "validation" "empty input to tracker_phase_task_emit"` | — |
| F1.3 | (site) | `tracker-sidecar.sh:315` (compose empty input) | `tracker_error_emit "validation" "empty input to tracker_sidecar_compose_phase_tasks_block"` | — |
| F1.4 | (site) | `tracker-labels.sh:227` (derived_from invalid id) | `tracker_error_emit "validation" "tracker_labels_derived_from: invalid TD id $td"` | — |
| F1.5 | (site) | `tracker-labels.sh:242` (promoted_to invalid target) | `tracker_error_emit "validation" "tracker_labels_promoted_to: invalid target $target"` | — |
| F1.6 | (site) | `tracker-migrate-forward.sh:223` (set_phase_task_order invalid phase id) | `tracker_error_emit "validation" "tmf_mapping_set_phase_task_order: invalid phase id $phase_id"` | — |
| F1.7 | (site) | `tracker-migrate-reverse.sh:101` (_tmr_phase_task_order invalid phase id) | `tracker_error_emit "validation" "_tmr_phase_task_order: invalid phase id $phase_id"` | — |
| F2 | MUST | `tracker-phase-task.sh:112` (exported bash regex) | Adopted option (a): aligned bash group-3 to `[[:space:]]+(.*)` so the inner whitespace is consumed (matches Python `DEP_ENTRY`'s `\s+(.*)`). Bash now captures group 3 = ` <annotation-with-leading-ws>` and group 4 = annotation alone (analogous to Python group 2 / group 3). Added Test 1.3 group: 12 assertions across 6 representative lines verifying `bash group 1 == python group 1` and `bash group 4 == python group 3` (trim-equivalent). Updated the function docstring to document the bash-group / python-group mapping explicitly. | None — option (a), the suggested stronger fix. |
| F3 | SHOULD | `tracker-sidecar.sh:329-339` (yaml_quote untested branches) | Extended `IMPLEMENTATION-PLAN.md` fixture's phase-3.3 task with two new Dependencies entries: `TD-030 see TD-029: blocking on schema-bootstrap` (colon in annotation) and `TD-031 #issue-tracker-link` (hash in annotation). Test 4.6 asserts the sidecar emits each as `annotation: "<quoted>"`. Test 4.7 asserts the broader-fixture round-trip preserves the colon and hash annotations byte-equivalently through parse → emit → re-parse. | None — followed suggested fix; chose IMPLEMENTATION-PLAN.md extension (not a new fixture) per the review's lower-cost option. |
| F4 | SHOULD | `tracker-phase-task.sh:420-425` (emitter docstring) | Adopted option (b): tightened the emitter docstring with a dedicated "Round-trip byte-identity preconditions" block stating the three conditions (canonical bullet names, canonical `: ` separator, no trailing whitespace). Created a new fixture `ROUNDTRIP-NONCANONICAL.md` with `**Problem**`, `**Files**`, `**DoD**` aliases. Added Test 3.6 asserting (a) `diff` is NON-empty after parse → emit (canonicalization breaks byte-identity), (b) semantic round-trip still preserves pack_ids, (c) emitter produces canonical names in the output. | None — option (b) per the review's "cheaper fix" recommendation. |
| F5 | SHOULD | `tracker-phase-task.sh:178` (BULLET_HEAD `[:—-]`) | Adopted option (a): dropped em-dash + hyphen from the separator class; new regex is `r'^-\s+\*\*([^*]+?)\*\*\s*:\s*(.*)$'`. Comment in the lib explicitly cites METHODOLOGY § Part 4 line 304 canonical + BD-106 review F5 as the rationale. Verified all existing fixtures use colon separator (test runner stays green). | None — option (a), the recommended mechanical fix. |
| F6 | SHOULD | `tracker-migrate-forward.sh:188-189` (`tmf_mapping_set`) | Adopted option (a): changed jq filter from `'. + {($k): {id: $id, url: $url}}'` to `'.[$k] = ((.[$k] // {}) + {id: $id, url: $url})'`. Added Test 6.7: asserts `tmf_mapping_set` after `tmf_mapping_set_phase_task_order` preserves task_order across both retry (same id) and update (new id) cases. Function comment updated with a 7-line paragraph explaining the additive semantics + the BD-106 review F6 trail. | None — option (a), the one-line broadly safer fix. |
| F7 | SHOULD | `README.md:202` (repo-layout glob) | Extended glob to `tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task}.sh` and appended the comment `Tracker subsystem (v11; phase-task per V3.3 §2 D-21 / BD-106)`. Trinity rule does NOT engage (README.md is single-file). | None. |
| F8 | SHOULD | `scripts/validate-pack.py` (no Path-3-forbidden static check) | Added `check_tracker_phase_task_invariants` as Check 32 (next-free number; Checks 1-31 already used). Three asserts: (1) `scripts/lib/tracker-phase-task.sh` exists; (2) `tracker-labels.sh` does NOT contain a function definition for `tracker_labels_folded_into` (comment references are exempt — the libs legitimately document the prohibition); (3) no script under `scripts/lib/` contains the literal `folded-into` in executable (non-comment) code. Wired into `main()` after Check 31. | Refined the third invariant to exempt comment lines — the libs explicitly document the Path-3 prohibition in docstrings (`# tracker_labels_folded_into constructor.`). Without the exemption, all six legitimate documentation references would falsely fail. The structural intent (no executable folded-into anywhere) is preserved; documentation can still reference the forbidden state. |
| F9 | SHOULD | `IMPLEMENTATION-REPORT-BD-106.md:86-87, :312, :316` (stale §6.R framing) | Appended a new `## §13 Post-land update — §6.R formalized` section that records the architect ratification trail per the review's suggested prose, plus a 4-bullet mapping of §6.R.1-§6.R.4 to the implementation, plus a note explaining the historical-context preservation of §3 / §9 / §10. | None — used the review's suggested text as a starting point and extended with the §6.R.1-§6.R.4 mapping. |
| F10 | NIT | `tracker-phase-task.sh:437-441` (duplicate Implementation note) | Deleted the shorter duplicate paragraph (lines 437-441 pre-fix), keeping the longer block (442-446) which adds the bash-3.2-portability sentence. | None. |
| F11 | NIT | `tracker-phase-task.sh:361-363` (misleading blank-line comment) | Corrected the comment to: "Blank line is allowed inside the dependencies block; state is unchanged until the next bullet header (BULLET_HEAD or NESTED_BULLET) resets it." Lower-risk vs. implementing the behavior change. | None — chose comment-correct (review's recommendation). |
| F12 | NIT | `test-tracker-phase-task.sh:165` (missing emit empty-input test) | Added Test 3.5 per the review's suggested code, plus two additional assertions checking the typed-error envelope (`ERROR: validation`, `→ Run:`). Bumps assertion count by 3 (60 → 90 total — including all the new F1/F2/F3/F4/F6/F12 test additions). | None — extended slightly to also lock the typed-error contract on the emit path (parallel to F1's Test 2.6 enhancement). |
| F13 | NIT | `tracker-phase-task.sh:84-85` (V1-shorthand reference) | **No-op per the review's "leave to author judgment" disposition.** The V1 shorthand is established convention across tracker-* libs and matches the §-numbering of `ARCHITECTURE.md`. Documented as a no-op decision in §5 below. | None — adopted the review's no-op recommendation. |

**Total findings:** 13 listed (F1-F13). F1 has 7 sub-sites (rows F1.1-F1.7). F13 is a documented no-op. All other findings fully applied.

## §3 Test results

### Before (baseline at session start)

| Test runner | Assertions | Result |
|---|---|---|
| `test-tracker-phase-task.sh` | 60 | PASS |
| `tracker-migrate-forward-test.sh` | 126 | PASS |
| `tracker-migrate-reverse-test.sh` | 93 | PASS |
| `tracker-migrate-roundtrip-test.sh` | 39 | PASS |
| `test-customization-preserve.sh` | 233 | PASS |
| `tracker-errors-test.sh` | 60 | PASS |
| `tracker-config-test.sh` | (pass-only summary; count not displayed) | PASS |
| `tracker-init-test.sh` | (pass-only summary) | PASS |
| `tracker-provider-test.sh` | (pass-only summary) | PASS |
| `tracker-agent-read-test.sh` | (pass-only summary) | PASS |
| `tracker-bd133-header-preservation-test.sh` | (pass-only summary) | PASS |
| `validate-pack.py` | 31 checks | PASS |

### After (all 13 findings applied)

| Test runner | Assertions | Result | Delta |
|---|---|---|---|
| `test-tracker-phase-task.sh` | **90** | PASS | +30 (F1: +3, F2: +12, F3: +4, F4: +6, F6: +4, F12: +3 — totals across each fix's new assertions) |
| `tracker-migrate-forward-test.sh` | 126 | PASS | 0 (no regression from F6 additive change) |
| `tracker-migrate-reverse-test.sh` | 93 | PASS | 0 |
| `tracker-migrate-roundtrip-test.sh` | 39 | PASS | 0 |
| `test-customization-preserve.sh` | 233 | PASS | 0 |
| `tracker-errors-test.sh` | 60 | PASS | 0 |
| `tracker-config-test.sh` | (pass-only) | PASS | 0 |
| `tracker-init-test.sh` | (pass-only) | PASS | 0 |
| `tracker-provider-test.sh` | (pass-only) | PASS | 0 |
| `tracker-agent-read-test.sh` | (pass-only) | PASS | 0 |
| `tracker-bd133-header-preservation-test.sh` | (pass-only) | PASS | 0 |
| `validate-pack.py` | **32 checks** | PASS | +1 (Check 32 added per F8) |

**Test count delta breakdown** (`test-tracker-phase-task.sh`):

- F1 contract assertions on Test 2.6: `+2` (`MESSAGE:` line, `→ Run:` trailer; the `ERROR: not-found` assertion was pre-existing).
- F2 bash-vs-Python regex group parity: `+12` (6 sample lines × 2 assertions each — group-1 parity and group-4/group-3 trim equivalence).
- F3 yaml-quote on `:` / `#`: `+4` (Test 4.6 × 2; Test 4.7 × 2).
- F4 non-canonical fixture: `+6` (Test 3.6: diff-mismatch, pack_id semantic preservation, 3 × canonical-bullet-name assertions = 5; +1 from `t_pass` in the diff branch = 6).
- F6 regression test: `+4` (Test 6.7 × 4: task_order preserved, id preserved, id updated, task_order still present).
- F12 emit empty: `+3` (Test 3.5 × 3: rc=1, `ERROR: validation`, `→ Run:`).
- Subtotal: 2+12+4+6+4+3 = **31**. Net delta is 30 because Test 2.6's `ERROR: not-found` assertion was renamed/preserved, not incrementally added. Final: 60 + 30 = 90. ✓

### `validate-pack.py` Check 32 output (verified)

```
── Check 32: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed
```

## §4 Round-trip identity proof (SHA-256)

Verified on the canonical `ROUNDTRIP.md` fixture after all 13 fix edits:

```
ROUNDTRIP.md (source)  SHA-256: 43c68f97250916983804cb411f6eb43a8a32c80dbb68cb985d7ea2ea97dac243
Emitted (parse → emit) SHA-256: 43c68f97250916983804cb411f6eb43a8a32c80dbb68cb985d7ea2ea97dac243
```

**Match.** The F5 separator-class tightening (em-dash/hyphen removed) and F2 regex alignment did not alter the byte-identity contract on the canonical fixture, which uses colon separators and canonical bullet names.

The new `ROUNDTRIP-NONCANONICAL.md` fixture is INTENTIONALLY non-byte-identical on round-trip (per F4 fix; documented in the emitter docstring's "Round-trip byte-identity preconditions" block). Test 3.6 asserts the diff is non-empty AND that the semantic round-trip still preserves pack_ids and dependency targets.

## §5 Deviations / open issues

### Deviations from suggested fixes

| Finding | Deviation | Rationale |
|---|---|---|
| F8 | The third invariant (no `folded-into` literal anywhere under `scripts/lib/`) was refined to exempt **comment lines** (lines whose first non-whitespace character is `#`). | Without this exemption, three legitimate documentation references would falsely fail: `tracker-labels.sh:40-41` documents "`folded-into:` is NOT supported"; `tracker-labels.sh:238` says "intentionally no `tracker_labels_folded_into` constructor"; `tracker-phase-task.sh:87` says "does NOT emit a `folded-into:` label"; `tracker-promote.sh:54, :150` (BD-107 lib) also documents the prohibition. The structural intent of the invariant (no EXECUTABLE folded-into anywhere) is preserved. Similarly, the second invariant (no `tracker_labels_folded_into` definition) was refined to match the function-definition pattern `<name>(` or `function <name>`, not the bare name, to avoid triggering on the same comment references. |
| F12 | Added 2 additional assertions beyond the review's suggested single rc=1 check — locks the typed-error envelope (`ERROR: validation`, `→ Run:`) on the emit path. | Symmetric coverage with Test 2.6 (which was extended per F1 to lock the same three-line envelope on the parser path). Without the extra assertions the typed-error contract is only enforced on parser failures, not emitter failures. |
| F9 | Added a §6.R.1-§6.R.4 mapping bullet list beyond the review's suggested single-paragraph note. | Gives a future reader concrete mapping points (rather than asking them to re-derive the 16/16 MATCH from the addendum). Suggested text is preserved verbatim as the opening paragraph; the bullet list is an additive enrichment. |

### Open issues

None. All 13 findings applied (F13 is a documented no-op per the review's own disposition).

### F13 no-op disposition

The review explicitly disposes of F13 as "leave to author judgment" — the V1 shorthand convention (`V1 §6.7`, `V1 §5.3`, etc.) is established across the tracker-* libs and matches the §-numbering of `ARCHITECTURE.md` (the base spec, no V-suffix in filename). Changing the convention would require a sweeping rename across `scripts/lib/tracker-*.sh` (~10 files) — out of scope for a NIT fix-pass. No edit applied. Documented here for completeness.

## §6 BD-108 fix coder hand-off note

I edited two files that BD-108's commit `aae4712` also touches:

- **`scripts/lib/tracker-migrate-forward.sh`** — my F1 edit at line 223 (now `tracker_error_emit "validation" "tmf_mapping_set_phase_task_order: invalid phase id $phase_id"`) is within the BD-106 phase-task additive section (lines 192-280 per BD-106's original implementation). My F6 edit at lines 183-189 (`tmf_mapping_set` jq filter changed to additive form `.[$k] = ((.[$k] // {}) + {id: $id, url: $url})`) modifies the **existing pre-BD-106 helper**. BD-108's commit also extends this file with cross-entity dependency-link helpers. BD-108's fix coder should: (a) verify their new helpers in `tracker-migrate-forward.sh` do NOT re-introduce the non-additive `tmf_mapping_set` pattern; (b) verify their tests do not assume the previous wholesale-replace semantics of `tmf_mapping_set` on retry. The F6 fix is correctness-positive — any caller that relied on wholesale replacement to wipe a previous entry was already broken on a retry/checkpoint path.

- **`scripts/lib/tracker-migrate-reverse.sh`** — my F1 edit at line 101 (now `tracker_error_emit "validation" "_tmr_phase_task_order: invalid phase id $phase_id"`) is within the BD-106 phase-task additive section. BD-108's commit also extends this file. No semantic change beyond the error envelope; BD-108's fix coder needs no special handling here.

I did NOT touch any of the BD-107 files (`scripts/lib/tracker-promote.sh`, `scripts/pack-td.sh`, `scripts/tests/test-tracker-promote-*.sh`, `scripts/tests/fixtures/tracker-promote/`) or the BD-108 files I noticed in the worktree (`scripts/lib/tracker-links.sh`, `scripts/lib/tracker-cycle-check.sh`, `scripts/tests/test-tracker-links.sh`, `scripts/tests/test-tracker-cycle-check.sh`) — they are out of BD-106 scope.

**Validate-pack Check 32 cross-check:** my new Check 32 scans **all** of `scripts/lib/` for `folded-into` in executable code. BD-107's `scripts/lib/tracker-promote.sh:54, :150` contain `folded-into` references — both are in COMMENT lines (verified manually and via the live run reported in §3). If BD-107's fix coder ever moves those references out of comments (e.g. into a help-message string), Check 32 will fail and they will need to either (a) rephrase or (b) extend Check 32's exemption logic. Note that this is a desirable property — moving `folded-into` into executable code would violate V3.3 §3 line 27.

---

**Definition-of-Done checklist**

| Criterion | Result |
|---|---|
| Every F1-F13 finding has a fix applied (or documented no-op) | **PASS** (F13 = no-op per review; all others applied) |
| `test-tracker-phase-task.sh` continues to pass (60 → ≥61 per F12) | **PASS** (60 → 90, exceeds +1 requirement) |
| Full tracker-* regression green | **PASS** (forward 126/0, reverse 93/0, roundtrip 39/0, customization-preserve 233/0, errors 60/0, all single-pass tests green) |
| `validate-pack.py` passes with new Check 32 | **PASS** (32 checks PASS) |
| Round-trip identity (SHA-256) on existing fixture intact | **PASS** (43c68f97… matches source) |
| `IMPLEMENTATION-REPORT-BD-106.md` updated per F9 | **PASS** (§13 added) |
| No state-changing git verbs run by this agent | **PASS** (used only `git status`, `git diff`, `git log`, `git rev-parse`) |
| Markdown-only report; chunked Write if >300 lines | **PASS** (report at ~290 lines pre-final-table, single Write tool call) |
