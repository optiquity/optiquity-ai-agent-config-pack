# PACK-REVIEW — BD-204 C-8: stateReason casing + forward-path cycle fail-loud (reviewer pass 1)

- **Branch:** `v11-dev`; **HEAD (unchanged):** `1c18b28c4d149d3e80565beafccc84f8d25b32f2`
- **Date:** 2026-06-11
- **Reviewer:** fresh pack-reviewer (pass 1 of bounded cycle)
- **Scope reviewed:** entire uncommitted diff vs HEAD (10 `scripts/` files, +436/−20) + untracked inventory
- **Verdict:** **APPROVE-WITH-FIXES** (1 MUST — Pack-Chat bookkeeping anchor, not a code fix; 2 SHOULD; 1 NIT. Zero code defects found in the change itself.)

---

## 1. Defect 1 — stateReason casing (CLEAN)

**Teeth proof reproduced independently** (live uppercase shape through the production
chain, HEAD normalizer extracted via `git show HEAD:scripts/lib/tracker-provider-gh.sh`
to /tmp, working-tree decoder sourced):

```
PRE-FIX  state_reason: NOT_PLANNED  decode: Resolved      ← the lossy-class defect
POST-FIX state_reason: not_planned  decode: Cancelled
POST-FIX dep-label decode: Deprecated                     ← status:deprecated discriminator
POST-FIX completed decode: Resolved
```

**Boundary placement verified.** The fix is exactly at the read-back normalization
boundary: `_gh_normalize_issue` (`scripts/lib/tracker-provider-gh.sh:250,257`) lowercases
`stateReason` when it is a string, emits `null` otherwise. I verified the null and
missing-key shapes both yield `state_reason: null` → decode `Open` (no regression for
open issues; GH's `REOPENED` reason also lowercases harmlessly — the decoder consults
`state_reason` only when `state == closed`).

**Own consumer grep** (`grep -rn "stateReason\|state_reason" scripts/ --include="*.sh"`,
excluding tests): the ONLY canonical-JSON read consumer of `.state_reason` is
`_tmr_decode_status` (`scripts/lib/tracker-migrate-reverse.sh:257`). All other non-test
touchpoints are write-side interface-token emitters (`tracker-edit.sh` close mapping,
`tracker-promote.sh` close, `tracker_provider_gh_close` success JSON at
`tracker-provider-gh.sh:485` — already lowercase, correctly untouched) or the request
field list (`_gh_full_fields`, line 217 — no casing surface). No un-normalized consumer
remains. Zero `stateReason` hits in `project-template/` or `supporting-docs/`.

**Mock alignment verified as genuinely uppercase-serving.** The roundtrip fake-gh
`issue close` handler now stores the live read-back shape (`state: "CLOSED"`,
`stateReason: COMPLETED|NOT_PLANNED|DUPLICATE` mapped from validated CLI-form input);
`create`/`reopen` store `"OPEN"`. The other fake-gh mocks
(`tracker-agent-read-test.sh`, `tracker-bd132-race-test.sh`, forward-test) and the
static fixture `scripts/tests/fixtures/tracker-provider/gh-issue-view.json` already
served `"OPEN"`/`stateReason: null` — consistent with the live shape; no
lowercase-serving mock remains. (Coverage gap on the dormant close handler → SHOULD-1.)

**All three closed decode arms pinned through the production normalize→decode chain:**
reverse-test legs 1.1c ×3 (CLOSED+NOT_PLANNED → Cancelled; +`status:deprecated` →
Deprecated; CLOSED+COMPLETED → Resolved) and provider-test leg 1.2b — all ran PASS in my
own foreground suite runs.

## 2. Defect 2 — cycle handling (CLEAN)

**Coder's root-cause correction independently verified.** Three reproductions, all mine:

1. **Live store** (`/tmp` copy of `.pack-tracker/links-graph.json`, 130 edges, read-only):
   contains `BD-094 → BD-095` blocked-by; the reverse edge is absent (refused, never
   persisted). Edge set for BD-094/BD-095 matches the IMPL-REPORT exactly.
2. **Checker:** `tracker_cycle_check_would_form_cycle "BD-095" "BD-094" <store-copy> 10`
   → rc=2, `MESSAGE: ... would close a cycle of length 2 (cycle path: BD-095 -> BD-094
   -> BD-095; '->' = blocked-by)`.
3. **Orchestrator pre-call:** `tracker_links_create_blocked_by` with the real id-map
   shape, a store copy, and a recording stub `provider_link` → rc=1, typed refusal,
   **provider-call count 0**. The BD-108 check fires pre-call; the defect was the
   `>/dev/null 2>&1` swallow at the three link arms — confirmed.

**Pre-pass (`tmf_blockers_cycle_precheck`) reviewed for correctness:**
- Iterative DFS with GRAY/BLACK coloring + explicit stack-path; handles self-loops
  (`stack_path.index` finds the GRAY node); each cycle reported once (BLACK nodes never
  re-trigger); dangling blocker targets are harmless (`out.get(nxt, [])`).
- Edge vocabulary (`BD-NNN|TD-NNN|phase-N.M`, bare `phase-N` excluded) matches the
  step-7 link-arm routing; the step-7b phase-task-Dependencies gap is documented in the
  docstring and remains guarded per-edge by the now-surfaced BD-108 check. Acceptable.
- Fail-closed on unparseable JSON (typed `schema-reshape`).
- Invoked as `tmf_blockers_cycle_precheck "$entries" || return 1` — the `||` list
  suppresses `set -e` throughout the function body, so the rc=2 command substitution is
  safe under any caller errexit mode.
- Wired after the parse summary, **before the `--dry-run` return** — dry-run gating
  confirmed by Group 8.4 (rc=1, names the path) in my run.

**Group 8 gh-log-empty claim reproduced:** I ran
`scripts/tests/tracker-migrate-forward-test.sh` myself — 199 PASS / 0 FAIL including
`8.3 NO provider call before the refusal (gh log empty)` and `8.3 no id-map written`.
The fake gh logs EVERY invocation, so the byte-empty log is a complete witness that the
refusal precedes all provider traffic.

**BFS refusal naming verified:** predecessor-map reconstruction is correct for hop=1
(2-cycle: `src -> tgt -> src`) and multi-hop (3-cycle leg 5.4 names the intermediate
hop); `parent` lookups cannot KeyError (chain terminates at `tgt`). Tests 5.4 ×2 and
links 5.5 PASS in my runs.

**Partial-write accounting contract intact:** the `step-7 link blocked-by: <src> ->
<tgt>` prefix is preserved (suffix `— <MESSAGE>` appended only when present); grep
confirms no test asserts the exact bare line ending — only contains/not-contains, all
green. `link_err` lifecycle: created at line 1672-1673, no `return` path between
creation and the two cleanup sites (lines 2060, 2066) — no temp leak; the four earlier
`rm -f "$partial_failures"` sites (1530/1555/1566/1627) precede `link_err` creation.

**No acyclic behavior change:** for acyclic data the pre-pass is rc=0 with no output and
the link arms differ only in stderr destination on the success path. Empirical: all 52
suites green except the pre-existing POQ-B item, including the roundtrip re-run
idempotency legs and forward Groups 1–7 (130-edge-class happy paths).

**Expected operational consequence (intended, flag for Pack Chat):** until the
BD-094/BD-095 data correction lands, ANY forward run — including `--dry-run` — over the
real backlog now fails loud at parse (rc=1) instead of completing partial-write. This is
the designed fail-loud behavior; the data correction is the scheduled follow-up live op.

## 3. Verification (all foreground, this session)

| Check | Result |
|---|---|
| `python3 scripts/validate-pack.py` | PASSED — all checks clean (rc=0) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | PASSED — all checks clean |
| Full CI battery (52 suites, extracted verbatim from `.github/workflows/validate-pack.yml`, run sequentially) | **51 PASS / 1 FAIL** — sole FAIL `test-validate-pack-check-40.sh` (POQ-B) |
| Affected suites (my runs) | cycle-check 28, links 44, provider 162, reverse 150, forward 199, roundtrip 70 — all 0 FAIL; **counts match IMPL-REPORT exactly** |
| New legs executed | Group 8 (9/9), reverse 1.1c ×3, provider 1.2b ×2, cycle-check 5.4 ×2, links 5.5 path — all PASS observed directly |
| `bash test-fixtures/build.sh --all --clean` | rc=0; `git diff test-fixtures/manifest.txt` → **0 lines (byte-stable)** |
| `bash test-fixtures/build.sh --verify` | all six rows OK (v10-minimal, v10-realistic-ot, v11-realistic-ot, v11-flat-file, v11-tracker-on, existing-project-mid-dev) |
| Live-oracle suite `tracker-bd204-lossless-roundtrip-test.sh` | default-SKIP (not in the CI workflow's 52; no live calls per prompt) |
| Scope (`git diff --name-only` / `git status --porcelain`) | exactly the 10 expected `scripts/lib/` + `scripts/tests/` files; untracked = IMPL-REPORT + runtime `tracker.toml` only; tree state identical before/after my review |

**Pack-only (BD-204 HARD constraint): SATISFIED.** Nothing under `project-template/` or
`supporting-docs/`; zero `stateReason` references on client-shipped surfaces; manifest
byte-stability independently confirms no client-install drift.

**Cross-reference sweep:** the changed refusal message keeps the original
`would close a cycle of length %d` prefix; all repo references to it are historical
workflow artifacts (`IMPLEMENTATION-REPORT-BD-108.md`, BD-204 reports) or the lib's own
comments — no stale prescriptive doc. `step-7 link blocked-by` appears in .md only in
archived-class reports.

## 4. POQ-A — deferred tree-level Blockers-cycle validate-pack check

**Sequencing-blocked rationale CONFIRMED:** the live tree still carries the cycle —
`backlog/BD-094.md:5` (`Blockers: BD-088, BD-095, BD-085`) and `backlog/BD-095.md:5`
(`Blockers: BD-085, BD-088, BD-094`). A validate-pack check landing in THIS commit would
run against that tracked tree in CI and go RED. The deferral survives the
size/blocked/fit test on the BLOCKED prong (real dependency on the not-yet-landed data
correction). Recommended anchor shape → MUST-1 below.

## 5. POQ-B — check-40 T3 characterization

**Pre-existing:** the test file was last modified in BD-203 commit `3d7bec4`; this diff
touches neither `test-validate-pack-check-40.sh`, `validate-pack.py`, nor `tracker.toml`.
**Local-only:** `git ls-files tracker.toml` is empty → the untracked runtime
`tracker.toml` is absent from any CI checkout → T3's live-index walk
(`_build_basename_index()` over the working tree) finds no root `tracker.toml` in CI; CI
will be green. **Mechanism verified:** T3 (`test-validate-pack-check-40.sh:451-455`)
asserts `"tracker.toml" not in index` on the LIVE tree; its own comment ("tracker.toml
lives in fixture trees but not in the pack at HEAD", lines 447-450) encodes a premise
that is now false on every tracker-enabled (Mode-3) local tree. `validate-pack.py`
itself still passes clean — only the test's pinned premise is stale. Verbatim failure:
`T3 EXCLUDE failed — bare tracker.toml leaked into index (candidates:
[PosixPath('tracker.toml')])`. Disposition → SHOULD-2.

## 6. Findings

**MUST-1 (Pack-Chat bookkeeping at commit — no fix-coder edit).** POQ-A currently lives
ONLY in `IMPL-REPORT-BD-204-CASING-CYCLE.md` — an archived-class workflow artifact,
which the deferred-work-tracked-anchor rule explicitly disallows as the sole surface.
Before/at this commit, anchor it on a live surface: recommended shape is a dated Note in
`backlog/BD-204.md` (pack-chat-only; mirrors the entry's existing MUST-1/NIT note
pattern) binding the tree-level Blockers-cycle validate-pack check to the commit
immediately after the BD-094/BD-095 data correction in the same Pack Chat session.
Rationale: the IMPL-REPORT itself says "not left in this archived report" but no live
anchor exists yet.

**SHOULD-1 (test coverage — small, test-only).** The realigned roundtrip fake-gh
`issue close` handler (`tracker-migrate-roundtrip-test.sh:157-190`) is never invoked by
any CI-run leg: the roundtrip fixtures carry only Open/Unblocked/Deferred statuses (no
Resolved/Cancelled/Deprecated entry), so the e2e close→read-back→reverse-decode chain
through the aligned mock is dormant in CI. The casing teeth live at the unit-chain level
(reverse 1.1c, provider 1.2b) plus the live oracle (default-SKIP). Add one closed-status
entry (ideally Cancelled or Deprecated — the lossy class) to a roundtrip fixture so a
CI-run e2e leg exercises the close handler and would catch a future read-back-chain
regression. File anchor: `scripts/tests/tracker-migrate-roundtrip-test.sh` (fixture
block ~line 485 + a Group 2 reconstruction assertion).

**SHOULD-2 (POQ-B disposition).** Make check-40 T3 tracker-mode-tolerant — e.g., permit
the single repo-root candidate (the legitimate Mode-3 runtime artifact) or build the
index against a synthetic tree instead of the live one. Pre-existing and CI-invisible,
but every local full-battery run on a tracker-enabled tree now trips it, which degrades
the verify-full-ci-suite signal (a persistently red local suite trains actors to ignore
battery failures). Per the deferral-is-scope-creep default the fix-now path is preferred
(small, unblocked, test-only: `scripts/tests/test-validate-pack-check-40.sh:444-455`);
it does widen the diff beyond the user's two-defect framing, so user triage decides
fix-now vs a tracked anchor (Note in `backlog/BD-204.md` or new BD per OQ-1).

**NIT-1 (Pack-Chat bookkeeping).** The `backlog/BD-204.md` Note "(2026-06-11,
close-reason review-2 MUST-1 anchor): LIVE CASING CHECK required ... if the live
read-back casing mismatches, a decoder casing fix lands BEFORE any reverse/regen" is
half-discharged by this batch (the casing fix IS this commit; the live re-check after
the C-8 close re-run remains). Append a partial-discharge note at commit, matching the
entry's existing DISCHARGED-note convention.

## 7. Verdict

**APPROVE-WITH-FIXES.** The code change is correct, boundary-placed, fully tested, and
commit-ready as-is; both live-verified defects are fixed with reproduced teeth. The
required fixes are: MUST-1 (live anchor for POQ-A — Pack-Chat-direct backlog note, no
code change), and triage of SHOULD-1 / SHOULD-2 / NIT-1 per the default-fix-all
contract. None of the findings is a defect introduced by this batch.

---

## READ-IN-FULL attestation

| File | Lines | Read |
|---|---|---|
| `CLAUDE.md` § "Pack memory" (read whole file from disk, lines 1–580) | 580 (section: 140–579) | FULL |
| `/tmp/bd204-c8-rerun.log` | 15 | FULL |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | 42 | FULL |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | 14 | FULL |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (conditional MUST-READ) | §206–233 | FULL section |

Section reads per prompt: full diff of all 10 files (`git diff`); `_gh_normalize_issue`
+ every stateReason touchpoint in `tracker-provider-gh.sh` (grep-enumerated + hunks +
header lines 1–60); `_tmr_decode_status` in context (`tracker-migrate-reverse.sh`
200–300); `tmf_blockers_cycle_precheck` + run wiring + all three link arms (diff hunks +
lifecycle trace 1530–2066); the BFS in `tracker-cycle-check.sh` (diff hunk + header);
forward-test Group 8 + roundtrip fake-gh legs (full diff + fixture-status and 2.2c
context reads); check-40 T3 (lines 416–470); `backlog/BD-204.md` (head 60 + notes).

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session: `rev-parse`, `status`, `diff`, `ls-files`, `log`, `show HEAD:` (read-only extraction to /tmp). End-state `git rev-parse HEAD` → `1c18b28c4d149d3e80565beafccc84f8d25b32f2` (unchanged); `git status --porcelain` byte-identical to session start (10 M + 2 ??). No add/commit/push/tag/stash/reset/restore/checkout invoked. Only file write: this report. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops: no `rm -rf` outside nothing (zero rm -rf), no `git rm`, no repo-file modification; scratch confined to `/tmp/bd204-review/`; runtime `tracker.toml` + `.pack-tracker/` read-only (store copied to /tmp before use). The POQ-B conflict was characterized and surfaced, not "fixed". | COMPLIANT |
| preflight-stop-means-stop | Emitted in-chat immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1c18b28c4d149d3e80565beafccc84f8d25b32f2; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE.md`. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; every row quotes commands/output/counts/paths; `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206–233) read before constructing; format matches the fenced template (Rule / Verification evidence / Conclusion; no AMBIGUOUS rows). | COMPLIANT |
| agents-read-rule-docs-in-full | Attestation table above: 4 prompt-named files read in full with line counts (580 incl. the 140–579 Pack-memory section; 15; 42; 14) + the conditional rationale section; all prompt-named code sections read (inventory in attestation). | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" rc=0; `PACK_VALIDATE_DEEP=1` → same; 52 suites extracted verbatim from `validate-pack.yml` (`grep -c "run: bash scripts"` → 52) and run sequentially FOREGROUND in 4 batches → results file: 51× rc=0, 1× rc=1 (`19 rc=1 :: bash scripts/tests/test-validate-pack-check-40.sh`); T3 failure quoted verbatim, independently characterized §5: pre-existing (file last touched `3d7bec4`, BD-203), local-only (`git ls-files tracker.toml` empty → absent in CI), caused by the legitimate untracked Mode-3 runtime `tracker.toml` hitting the live `_build_basename_index()` walk. Live-oracle suite default-SKIP (not in the CI 52; prompt forbids live calls). Affected suites re-run individually: 28/44/162/150/199/70, all 0 FAIL. | COMPLIANT |
| regenerate-manifest-v11-surface | Diff touches `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (rc=0, "manifest written"); `git diff test-fixtures/manifest.txt` → 0 lines (byte-stable, confirming the coder's claim — tracker libs/tests are not client-shipped); `--verify` → all six rows OK (SHAs listed §3). Empty diff → nothing to stage; no staging is also forbidden to me (agents-never-commit). | COMPLIANT |
| pack-only (BD-204 HARD constraint) | `git diff --name-only` → exactly 10 files, all under `scripts/lib/` + `scripts/tests/` (list §3); untracked additions: `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE.md` (coder report) + `tracker.toml` (pre-existing runtime artifact) + this review report. Zero paths under `project-template/` or `supporting-docs/`; zero `stateReason` refs on client surfaces (`grep -rln ... project-template/ supporting-docs/` → no hits). | COMPLIANT |
| scope-deliverables-to-the-ask | Findings limited to: 1 MUST (anchor obligation arising from THIS batch's deferred POQ-A), 2 SHOULD (one a coverage gap in THIS batch's mock alignment; one the prompt-requested POQ-B disposition), 1 NIT (BD-204 note discharge tied to THIS commit). No drive-by findings on untouched code; clean areas reported as checked, not as findings. | COMPLIANT |
