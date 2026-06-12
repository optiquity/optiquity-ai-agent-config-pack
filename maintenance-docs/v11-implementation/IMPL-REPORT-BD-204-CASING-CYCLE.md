# IMPL-REPORT — BD-204 C-8: stateReason casing normalization + forward-path cycle fail-loud (pack-only)

- **Branch:** `v11-dev`
- **Base HEAD (unchanged by this work — no git state changes):** `1c18b28c4d149d3e80565beafccc84f8d25b32f2`
- **Date:** 2026-06-11
- **Coder:** fresh pack-coder (BD-204 C-8 two-defect batch)
- **Proposed commit subject:** `fix: v11 — BD-204 stateReason casing normalization + forward-path cycle fail-loud (pack-only)`

Scope: exactly the two live-verified C-8 defects. All edits are pack-side
(`scripts/lib/`, `scripts/tests/`). No edits to `tracker.toml`,
`.pack-tracker/`, or `backlog/` (per prompt: the BD-094/BD-095 data
correction is a Pack Chat live operation after this commit).

---

## Defect 1 — stateReason casing (POQ-2, empirically answered)

### Root cause

The live gh read-back carries **GraphQL-enum casing** for `stateReason`
(verbatim live evidence supplied by Pack Chat, 2026-06-11):

```
$ gh issue view 21 -R DShaneNYC/optiquity-ai-agent-config-pack --json number,state,stateReason
{"number":21,"state":"CLOSED","stateReason":"NOT_PLANNED"}   (same for #103, #123)
```

`_gh_normalize_issue` (`scripts/lib/tracker-provider-gh.sh`) lowercased
`state` but passed `stateReason` through **verbatim**. The reverse decoder
`_tmr_decode_status` (`scripts/lib/tracker-migrate-reverse.sh`) matches the
canonical lowercase vocabulary `completed` / `not_planned|duplicate`, so
`NOT_PLANNED` fell through the `*` arm → every closed Deprecated/Cancelled
issue silently decoded to **Resolved** on reverse — a lossy-class bug.

**Teeth proof (pre-fix vs fixed), run in-session:**

```
--- PRE-FIX (HEAD) normalizer ---          --- FIXED normalizer ---
state_reason: NOT_PLANNED                  state_reason: not_planned
decode: Resolved                           decode: Cancelled
```

### Fix (at the provider boundary — all consumers fixed at once)

1. **`scripts/lib/tracker-provider-gh.sh` — `_gh_normalize_issue`:**
   `state_reason` now emits `stateReason.lower()` when the field is a
   string, `null` otherwise. Docstring records the live evidence and the
   lossy-class consequence. Write side untouched (`tracker_provider_gh_close`
   already emits the lowercase interface token in its success JSON).
2. **Read-path audit of every `stateReason`/`state_reason` touchpoint in
   `scripts/lib/tracker-provider-gh.sh`:**
   - `_gh_full_fields` — request field list only; no casing surface.
   - `_gh_normalize_issue` — FIXED (the only read-back normalization site).
   - `tracker_provider_gh_close` success JSON — already lowercase interface
     token (`completed|not_planned|duplicate`); correct, untouched.
   - `tracker_provider_gh_list` / `tracker_provider_gh_search` projections —
     do not request or surface `stateReason`; nothing to fix.
   - Repo-wide grep: the only canonical-JSON *consumer* of `.state_reason`
     is `_tmr_decode_status`; `tracker-edit.sh` / `tracker-promote.sh`
     touchpoints are write-side (interface tokens), untouched.
3. **`scripts/lib/tracker-migrate-reverse.sh` — `_tmr_decode_status`
   header comment:** added the casing-contract cross-reference (canonical
   JSON arrives lowercase; `_gh_normalize_issue` is the normalization site).
   No decoder logic change — the canonical contract is normalized input.
4. **Mock alignment (`scripts/tests/tracker-migrate-roundtrip-test.sh`
   stateful fake-gh):** the `issue close` handler now stores the
   **live-verified read-back shape** (`state: "CLOSED"` +
   `stateReason: COMPLETED|NOT_PLANNED|DUPLICATE`, mapped from the CLI-form
   input it validates), `issue reopen` stores `"OPEN"`, and `issue create`
   stores `"OPEN"` — pre-fix the mock stored the CLI-form reason
   (`"not planned"`, lowercase-with-space), which neither matched the live
   shape nor the decoder vocabulary, i.e. a lowercase-style mock that
   would mask a normalization regression.
5. **New test legs pinning the real contract:**
   - `scripts/tests/tracker-provider-test.sh` leg **1.2b**: `provider_get`
     over live-shape raw JSON (`CLOSED`/`NOT_PLANNED`) → canonical
     `state == closed`, `state_reason == not_planned`.
   - `scripts/tests/tracker-migrate-reverse-test.sh` legs **1.1c** (×3):
     live-shape raw gh JSON → production `_gh_normalize_issue` →
     `_tmr_decode_status`, pinning all three closed arms of the real
     contract: `CLOSED+NOT_PLANNED` → **Cancelled**;
     `CLOSED+NOT_PLANNED` + `status:deprecated` label → **Deprecated**
     (the label is the only Deprecated/Cancelled discriminator — both
     statuses close as `not_planned` per DP-3); `CLOSED+COMPLETED` →
     **Resolved**.

---

## Defect 2 — forward-path cycle handling (BD-094/BD-095 mutual block)

### Root cause — why the BD-108 check "did not fire" (empirically resolved)

The prompt's framing was "ROOT-CAUSE why it did not fire pre-call." The
in-session reproduction shows the BD-108 check **DID fire pre-call — its
refusal was swallowed**, making it observationally identical to a swallowed
provider error. Evidence chain (all commands run in this session at HEAD
`1c18b28`):

1. **The live cycle-graph store has the data.**
   `.pack-tracker/links-graph.json` (130 edges — matching the run-3 log's
   `blocked-by=130`) contains `BD-094 blocked-by BD-095` (plus BD-094's
   other two edges and BD-095's two non-cyclic edges). The store-write
   lifecycle in the forward context works: store entries are persisted
   per-edge after each successful/idempotent provider link, and within a
   run BD-094 (numerically earlier) is processed before BD-095, so the
   store always holds the first direction before the second is attempted.
2. **The checker detects the cycle against that exact store.**
   `tracker_cycle_check_would_form_cycle "BD-095" "BD-094" <store-copy> 10`
   → rc=2 with
   `MESSAGE: cycle_check: edge BD-095 blocked-by BD-094 would close a cycle of length 2`.
3. **The orchestrator refuses BEFORE any provider call.** Reproduced the
   exact forward-arm invocation (`tracker_links_create_blocked_by` with the
   real id-map + store copy + a recording stub `provider_link`): rc=1, the
   typed cycle refusal on stderr, and the provider-call log **empty**.
4. **Run-1 (empty store) simulation:** replaying BD-094's then BD-095's
   blockers in source order against an empty store shows 5 provider_link
   calls (94→88, 94→95, 94→85, 95→85, 95→88) and a **local pre-call
   refusal** of 95→94 — the cyclic edge never reaches the provider even on
   a first run.
5. **The actual defect:** all three forward link arms invoked the
   orchestrator as `tracker_links_create_blocked_by ... >/dev/null 2>&1`,
   so the typed refusal was discarded and the partial-failure entry was the
   bare, cause-less line `step-7 link blocked-by: BD-095 -> BD-094` —
   byte-identical to what a provider failure produces, unactionable, and
   retried verbatim on every idempotent re-run (3× live). The quoted GH
   `addBlockedBy` VALIDATION error is what a *direct* attempt at the edge
   produces GH-side (GH holds `BD-094 blocked-by BD-095`, so its own cycle
   validation rejects the reverse edge); under the migrator's own runs the
   local check refuses first. Both layers agree the data is unrepresentable
   — the failure was *loudness*, not *detection*.
   Additionally the refusal message named only the cycle *length*, not the
   path, and nothing caught the cyclic data at parse time, so the run
   always completed `partial-write` instead of failing loud.

### Fix (three layers)

1. **Parse-time pre-pass — `tmf_blockers_cycle_precheck` (new function,
   `scripts/lib/tracker-migrate-forward.sh`):** full (un-bounded) iterative
   DFS over the parsed entries' Blockers digraph. Edge vocabulary matches
   the step-7 blocked-by routing exactly (`BD-NNN`, `TD-NNN`, `phase-N.M`;
   bare `phase-N` is a step-6 sub-issue parent link and is excluded, same
   exclusion as the V3.3 §5.5 checker). Wired into
   `tracker_migrate_forward_run` immediately after the parse summary and
   **before the `--dry-run` return** — so (a) a data cycle fails the run
   loud with a typed validation error naming **every cycle's full path**
   and **zero provider calls / zero disk mutations**, and (b) `--dry-run`
   doubles as the parse-time tree-level check that catches cyclic Blockers
   data before any live run (requirement (b), parse-time variant — see
   POQ-A for the validate-pack variant). Fail-closed on unparseable
   entries JSON (typed `schema-reshape`). Live-topology output:

   ```
   ERROR: validation
   MESSAGE: forward: Blockers data contains dependency cycle(s) — refusing before any provider call. GitHub cannot represent a blocked-by cycle (its own addBlockedBy validation rejects it); fix the Blockers: lines of the entries named below and re-run.
     cycle path: BD-094 -> BD-095 -> BD-094 ('->' = blocked-by)
   → Run: pack tracker doctor
   ```

2. **Cycle path in the per-edge refusal
   (`scripts/lib/tracker-cycle-check.sh` BFS):** predecessor tracking; the
   refusal now reads
   `... would close a cycle of length 2 (cycle path: BD-095 -> BD-094 -> BD-095; '->' = blocked-by)`
   (verified for 2- and 3-cycles, including the intermediate hop).

3. **Un-swallow the orchestrator's stderr at all three forward arms**
   (step-7 phase-task arm, step-7 BD/TD arm, step-7b phase-task-dep arm,
   `scripts/lib/tracker-migrate-forward.sh`): stderr is captured per edge
   (`2>"$link_err"`, one mktemp per run, removed with `partial_failures`),
   and the first typed `MESSAGE:` line is folded into the partial-failure
   entry: `step-7 link blocked-by: <src> -> <tgt> — <typed message>`. Any
   per-edge failure (a step-7b cycle the pre-pass doesn't model, or a real
   provider error) is now diagnosable; the prefix shape is preserved so
   existing assertions (`assert_not_contains "step-7 link blocked-by"` in
   the roundtrip re-run legs) still hold.

### Mock e2e reproduction (required by the prompt)

`scripts/tests/tracker-migrate-forward-test.sh` new **Group 8** rebuilds the
BD-094/BD-095 topology (BD-701 `Blockers: BD-703, BD-702` + BD-702
`Blockers: BD-703, BD-701` + shared non-cyclic BD-703, mirroring
BD-085/BD-088) in a per-entry pack tree and runs the real
`tracker_migrate_forward_run` against a logging-only fake gh:

- 8.1 run rc=1, typed `ERROR: validation`, names the Blockers-cycle cause
- 8.2 names the full cycle path `BD-701 -> BD-702 -> BD-701`
- 8.3 **gh log byte-empty** (no create, no link mutation — no provider
  call at all) and no id-map written
- 8.4 `--dry-run` rc=1 with the same path-naming message
- 8.5 the pre-fix swallowed `step-7 link blocked-by` shape is absent

All 9 legs PASS (and would FAIL pre-fix: pre-fix the same fixture ran to
`partial-write` with the bare step-7 line — the C-8 live shape).

---

## Files changed (10 modified; 0 new; 0 deleted; +436 / −20)

| Path | Type | Δ | What |
|---|---|---|---|
| `scripts/lib/tracker-provider-gh.sh` | modified | +21/−1 | D1 fix: `_gh_normalize_issue` lowercases `stateReason`; boundary docstring |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +7 | D1: `_tmr_decode_status` casing-contract cross-ref comment |
| `scripts/lib/tracker-cycle-check.sh` | modified | +22/−4 | D2: BFS predecessor tracking; refusal names full cycle path |
| `scripts/lib/tracker-migrate-forward.sh` | modified | +189/−12 | D2: `tmf_blockers_cycle_precheck` (new fn) + run wiring + 3 arms un-swallowed + `link_err` lifecycle |
| `scripts/tests/tracker-provider-test.sh` | modified | +19 | D1 leg 1.2b (live CLOSED/NOT_PLANNED → canonical) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +21 | D1 legs 1.1c ×3 (normalize→decode chain, all closed arms) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | +20/−3 | D1 mock alignment (close stores CLOSED+enum reason; reopen/create store OPEN) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +140 | D2 Group 8 e2e (2-cycle fixture, 9 legs) |
| `scripts/tests/test-tracker-cycle-check.sh` | modified | +13 | D2 legs 5.4 (2-cycle + 3-cycle path assertions) |
| `scripts/tests/test-tracker-links.sh` | modified | +4 | D2: orchestrator-surfaced refusal names cycle path |

No new files; no full-file rewrites (all targeted Edits; untouched hunks
byte-stable per `git diff`). `test-fixtures/manifest.txt` byte-stable after
rebuild (see verification) — not staged because the diff is empty.

---

## Verification evidence

All commands run FOREGROUND in this session at the pack root.

**Validators:**

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | `PASSED — all checks clean` |

**Directly-affected suites (post-fix counts):**

| Suite | Result |
|---|---|
| `scripts/tests/test-tracker-cycle-check.sh` | 28 PASS / 0 FAIL |
| `scripts/tests/test-tracker-links.sh` | 44 PASS / 0 FAIL |
| `scripts/tests/tracker-provider-test.sh` | 162 PASS / 0 FAIL |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 150 PASS / 0 FAIL |
| `scripts/tests/tracker-migrate-forward-test.sh` | 199 PASS / 0 FAIL |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 70 PASS / 0 FAIL |

New legs confirmed executed: forward Group 8 (9/9 PASS), reverse 1.1c
(3/3 PASS), provider 1.2b (2/2 PASS), cycle-check 5.4 (2/2 PASS), links
5.5 path leg (PASS).

**Full unattended CI battery (the `Validate Pack` workflow's `tests` job
list, 52 suites, run in 5 foreground batches):** 51 PASS, 1 FAIL.

- Parts 1/3/4/5 (37 suites incl. `test-detect`, all `tracker-*`,
  per-entry, init-project, all `test-migrate-v10-to-v11*`, migrator-core/
  manifest/capability/skills, persona-contracts, template-translations/
  version, issue-forms, `test-v11-realistic-ot.sh`): **all PASS**.
- Part 2 (15 validate-pack check suites): 14 PASS, **1 FAIL —
  `scripts/tests/test-validate-pack-check-40.sh`**, verbatim:
  ```
  FAILURES
    T3 EXCLUDE failed — bare tracker.toml leaked into index (candidates: [PosixPath('tracker.toml')])
  ```
  Root-caused in-session: the T3 leg's own comment assumes
  "tracker.toml … not in the pack at HEAD", but the **untracked runtime
  `tracker.toml` at the repo root** (live C-8 ops artifact; present in
  `git status` before this session began; explicitly out of this task's
  scope — "Do NOT touch tracker.toml") is picked up by the live
  working-tree walk in `_build_basename_index()`. NOT caused by these
  edits (nothing here touches Check 40, the index builder, or
  tracker.toml); `git ls-files tracker.toml` is empty → the file is
  absent from any CI checkout, so CI will NOT see this failure. Reported
  verbatim per the prompt's instruction; surfaced as POQ-B below.
- Fixture infra: `bash test-fixtures/build.sh --all --clean` rc=0;
  `git diff test-fixtures/manifest.txt` **empty** (the edited tracker libs
  and tests are not client-shipped per the `_SANCTIONED_PACK_SIDE_SHIPPED`
  dependency-direction contract, so no fixture row drifts);
  `bash test-fixtures/build.sh --verify` → all six rows OK
  (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`,
  `existing-project-mid-dev` + tag-pinned v10 rows).
- Live-oracle suite `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
  default-SKIPPED (live GitHub scratch-repo test; prompt forbids live
  calls). Note: its close-canary leg already pins the live `stateReason`
  read-back and will exercise the fixed decode chain on its next live run.

**Defect-level empirical evidence (run in-session):** store-state jq dump
(130 edges; BD-094/BD-095 edge set), checker rc=2 against the store copy,
orchestrator-with-stub reproduction (empty provider log), run-1 empty-store
simulation (5 calls + local refusal), pre-fix-vs-fixed decode teeth proof
(`git show HEAD:` sourced read-only).

---

## Requirement (b) disposition + POQs

**(b) parse-time variant — DELIVERED in this batch:**
`tmf_blockers_cycle_precheck` runs before any provider call and before the
`--dry-run` return, so `pack tracker forward --dry-run` is a zero-mutation
tree-level check that catches cyclic `Blockers:` data before any live run.

**POQ-A (validate-pack tree-level variant — sequencing-blocked, NOT
landed):** a validate-pack check over `/backlog/` Blockers cycles is small
(same DFS over parsed `Blockers:` lines) but would be **CI-RED on this
commit**: the live tree still contains the BD-094/BD-095 mutual block, and
the data correction is scheduled as a Pack Chat live operation AFTER this
commit. Recommended disposition: land the check in the follow-up commit
immediately after the data correction (same Pack Chat session), anchored
per the deferred-work rule (open/extend a BD or attach to the BD-204
closeout) — not left in this archived report.

**POQ-B (check-40 T3 vs runtime tracker.toml):** `test-validate-pack-
check-40.sh` T3 asserts `tracker.toml` never appears in the live basename
index, which is false whenever the (legitimate, untracked, tracker-mode)
runtime `tracker.toml` exists at the pack root. Local-only failure today
(CI checkouts lack the untracked file), but every local full-battery run on
a tracker-enabled tree will trip it. Needs a Pack Chat decision: exclude
untracked/root `tracker.toml` from the index walk, or re-pin the T3 leg.
Out of this batch's two-defect scope; no edit made.

**Plan deviations:** none in deliverables. One framing correction to the
prompt's defect-2 hypothesis, with evidence: the BD-108 check *did* fire
pre-call in the forward path (store lifecycle is sound); the defect was the
swallowed refusal + missing cycle path + no parse-time gate. All three are
fixed; the prompt's required end-state (loud pre-call failure naming both
IDs and the cycle path; no provider attempt for the cyclic edge; mock e2e
reproduction) is met exactly.

---

## Boundary discipline check

No project-side surfaces touched: every edit is under `scripts/lib/` or
`scripts/tests/` (pack-side; not under `project-template/` or
`supporting-docs/`; not in the client install map — manifest byte-stable
confirms). No pack-only references added to any client-shipped file. No
boundary-discipline stop required.

## READ-IN-FULL attestation

| File | Lines | Read |
|---|---|---|
| `CLAUDE.md` § "Pack memory" (lines 140–579 of 579 on disk) | 440 | FULL (the named section, in full, from disk — disk version is newer than the session-context snapshot; disk wins) |
| `/tmp/bd204-c8-rerun.log` | 15 | FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 42 | FULL |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 14 | FULL |
| `~/.claude/.../memory/feedback_manifest_regen_on_v11_surface.md` | 15 | FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 14 | FULL |

Conditional MUST-READs honored: `pack-ops/PACK-MEMORY-RATIONALE.md`
§ `rules-applied-verification-block` (and the adjacent
`regenerate-manifest-v11-surface` anchor located) read before constructing
the block below. Section reads per prompt: `_gh_normalize_issue` + every
stateReason touchpoint (full 944-line provider file read), `_tmr_decode_status`,
`tracker_links_create_blocked_by` + cycle BFS + store lifecycle (both files
read in full: 366 + 370 lines), the forward link step + run entry/report
sections, `test-tracker-cycle-check.sh` in full (377 lines).

## Definition of Done

| Item | Status |
|---|---|
| D1: `stateReason` normalized to lowercase at the provider boundary | PASS (`_gh_normalize_issue`; teeth-proven pre/post) |
| D1: all other read paths surfacing stateReason audited | PASS (list/search/close audited; only normalize site fixed; consumers enumerated) |
| D1: fake-gh mocks return live-verified UPPERCASE shape | PASS (roundtrip close/reopen/create store CLOSED/OPEN + enum reason) |
| D1: test legs pin closed+NOT_PLANNED → Deprecated/Cancelled | PASS (reverse 1.1c ×3 incl. label discriminator; provider 1.2b) |
| D2: root cause established empirically (store lifecycle / check firing) | PASS (4-step evidence chain; check fired, refusal swallowed) |
| D2: data cycle detected BEFORE any provider call, fails loud with both IDs + cycle path | PASS (pre-pass + Group 8.1–8.3: gh log byte-empty) |
| D2: parse-time check catches cyclic data before any live run | PASS (`--dry-run` gate; Group 8.4) — validate-pack variant = POQ-A |
| D2: mock e2e reproduces BD-094/BD-095 mutual-block topology | PASS (forward-test Group 8, 9/9) |
| Full CI battery + validate-pack (plain + DEEP), foreground | PASS with 1 verbatim-reported pre-existing local-only failure (POQ-B, unrelated to these edits, absent in CI) |
| Manifest regenerated + diff checked | PASS (rebuilt `--all --clean`; diff empty → nothing to stage; `--verify` OK) |
| No git state changes; no out-of-scope files touched | PASS (`git status`: 10 in-scope modified + pre-existing untracked `tracker.toml` + this report) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only git verbs run: `rev-parse`, `status`, `diff`, `ls-files`, `show HEAD:` (read-only extraction to /tmp). HEAD unchanged: `1c18b28c4d149d3e80565beafccc84f8d25b32f2`. No add/commit/push/tag/stash/reset/restore/checkout invoked anywhere in session. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops: no `rm -rf` outside self-created mktemp scratch (`/tmp/bd204-*`, test-internal mktemps), no `git rm`, no trusted-file overwrite; the out-of-scope check-40/tracker.toml conflict was surfaced as POQ-B and STOPPED at, not "fixed" by touching tracker.toml. | COMPLIANT |
| preflight-stop-means-stop | One-line `PREFLIGHT: 10/10 in-scope file edits complete; verification PASS (…); HEAD 1c18b28…; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE.md` emitted in-chat immediately before this Write; the single battery FAIL was qualified inline in that line (pre-existing, unrelated, CI-invisible) rather than hidden. No parent stop message received. | COMPLIANT |
| agent-output-rules-applied-block | This table; every row carries quoted command output, counts, or file evidence; `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block read before constructing (format: per-rule table, Rule / Verification evidence / Conclusion). | COMPLIANT |
| agents-read-rule-docs-in-full | Attestation table above: 6 named files read in full with line counts (440-line Pack-memory section incl.; 15; 42; 14; 15; 14); conditional rationale sections read; named code sections read incl. two full files (tracker-links.sh 366, tracker-cycle-check.sh 370, provider 944, cycle test 377). | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean"; `PACK_VALIDATE_DEEP=1` → same; 52-suite battery run foreground in 5 batches → 51 PASS / 1 FAIL (`test-validate-pack-check-40.sh` T3, verbatim quoted in report, root-caused to pre-existing untracked runtime tracker.toml, `git ls-files tracker.toml` empty → absent in CI); fixture `build --all --clean` rc=0 + `--verify` all rows OK; live-oracle suite default-SKIP (no live calls per prompt). Affected-suite counts: 28/44/162/150/199/70 all 0-FAIL. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → ran `bash test-fixtures/build.sh --all --clean` (rc=0, "manifest written"); `git diff --stat test-fixtures/manifest.txt` → empty output (byte-stable; tracker libs/tests not client-shipped per `_SANCTIONED_PACK_SIDE_SHIPPED`); per the trinity rule's base-case, empty diff → nothing to stage; `--verify` confirms all six rows. | COMPLIANT |
| edit-in-place-not-full-rewrite | 12 targeted Edit calls + 0 full-file Writes on existing files (`git diff --stat`: 10 files, +436/−20 — largest file 2357→~2530 lines, far from rewrite); edited regions re-read via `git diff` hunks post-edit (lib diffs quoted in-session); untouched text byte-stable by construction of Edit + confirmed by hunk-scoped diff. | COMPLIANT |
| pack-only | End-state `git status --short`: exactly the 10 in-scope `scripts/lib/` + `scripts/tests/` modified files, the pre-existing untracked runtime `tracker.toml` (not mine, untouched), and this report under `maintenance-docs/v11-implementation/`. Nothing under `project-template/` or `supporting-docs/`. | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverables = exactly defect 1 + defect 2 + their test coverage; the two out-of-scope discoveries (validate-pack tree-check sequencing; check-40 T3 vs runtime tracker.toml) surfaced as POQ-A/POQ-B with dispositions, no edits made for them; `backlog/`, `tracker.toml`, `.pack-tracker/` untouched per prompt. | COMPLIANT |
