# PACK-REVIEW — BD-204 gh close-reason vocabulary fix (C-8 live-flip defect)

- **Reviewer:** fresh pack-reviewer, pass 1 of the bounded review/fix cycle
- **Branch / HEAD:** v11-dev @ `84f6a83d02d8467362972b86d1eb642dec9f4177` (uncommitted change)
- **Date:** 2026-06-11
- **Scope reviewed:** entire `git diff` vs HEAD (7 files, +450/-8), EXCLUDING the
  Pack-Chat-owned C-8 runtime artifacts (untracked root `tracker.toml`,
  gitignored `.pack-tracker/`) which were verified untouched by this change.

## VERDICT: APPROVE-WITH-FIXES

The close-reason fix itself is correct, single-site, interface-preserving, and
now pinned at three layers (unit 1.9b, end-to-end Group 7, live-oracle BD-909
canary). The four modified suites are green; the FULL CI battery is green in an
isolated checkout without the runtime artifacts; every real-tree failure traces
to exactly the POQ-1 mirror-key cause. One MUST (a fired tracked-anchor
obligation in the BD-204 entry, comment-only) and one NIT.

---

## Findings

### MUST-1 — BD-204 dated-note anchor fires on this commit and was not honored

- **Anchor:** `/backlog/BD-204.md`, Note (2026-06-10, GH_REPO-resolution
  review-3 NIT): "stale BD-111-era comment in
  `scripts/tests/tracker-migrate-roundtrip-test.sh` (the fake-gh dispatch
  block) still describes the old argument-less `gh repo view` slug-resolution
  idiom; comment-only, no behavioral exposure ... **Fix at the next commit
  touching that file.**"
- **This change touches that file** (`tracker-migrate-roundtrip-test.sh` is in
  the diff) and does NOT fix the comment. The stale comment is the `"repo
  view")` arm comment at lines ~239-247: "the production code does
  `_gh_run gh repo view --json nameWithOwner --jq .nameWithOwner` in multiple
  places (sub_issue_create, link, unlink, _tmr_fetch_first_class_blocked_by)".
  Verified stale against current production: those sites now call
  `_gh_owner_repo()` (`scripts/lib/tracker-provider-gh.sh:168`, callers at
  :621 / :740), which PREFERS `${GH_REPO}` and only falls back to the
  argument-less `gh repo view --json nameWithOwner --jq .nameWithOwner` at
  :201 — one site, fallback-only, not "multiple places". Neither d227cc4 nor
  1068c74 (the two 2026-06-10 commits touching the file) fixed it; grep for
  "argument-less" in the file returns nothing changed.
- **Why MUST:** the note is a live tracked anchor per Pack memory
  ("Deferred work needs a tracked anchor"); its trigger condition is exactly
  this commit. Skipping it silently re-defers tracked work without user
  authorization. Cost is a few comment lines in a file already in the diff.
- **Fix:** reword the comment to describe the current idiom (GH_REPO-preferred
  via `_gh_owner_repo`; `gh repo view` is the no-GH_REPO fallback only), in
  this change's fix pass. The BD-204 note can then be marked satisfied by
  Pack Chat.

### NIT-1 — guard flag-parsing breadth differs between the provider-test fake and the other 9 stubs

- `scripts/tests/tracker-provider-test.sh` fake parses both `--reason` and
  `-r` (lines ~129-133); the 9 other hardened stubs
  (`tracker-migrate-forward-test.sh` ×7, `tracker-migrate-roundtrip-test.sh`,
  `tracker-bd134-close-retry-test.sh`) parse `--reason` only. Production
  invokes only `--reason` (`tracker-provider-gh.sh:465`), so no coverage gap
  exists today; a future `-r` invocation would slip past 9 of 10 mocks.
  Optional consistency tighten; if deferred, it needs no anchor beyond this
  note (the production-invocation grep is the real guard).

No BLOCKER. No SHOULD beyond the assessments below (which concern
pre-existing, out-of-diff state surfaced as POQs, not defects in this change).

---

## Assessment 1 — Translation correctness: CLEAN

- **Real CLI vocabulary confirmed locally:** `gh issue close --help` →
  `-r, --reason string  Reason for closing: {completed|not planned|duplicate}`
  (space form; help example uses `--reason "not planned"`). Matches the C-8
  failure shape in `/tmp/bd204-c8-flip.log` lines 29-33 (all five
  Deprecated/Cancelled closes failed 3x; the 162 `completed` closes succeeded
  → `closed: 167`).
- **Translation exactly at the CLI invocation:**
  `scripts/lib/tracker-provider-gh.sh:463-465` — `cli_reason` local;
  `[[ "$reason" == "not_planned" ]] && cli_reason="not planned"`; only the
  `_gh_run gh issue close` argv changes. `completed`/`duplicate` pass through
  unchanged (identical in both vocabularies).
- **Interface vocabulary untouched:** the validation case-arm (:457
  `completed|not_planned|duplicate`), the success JSON (:466 emits the
  interface token `$reason`, not `$cli_reason`), and the docstring contract
  (:437) all keep `not_planned`. Callers verified unaffected:
  `scripts/lib/tracker-migrate-forward.sh:1727-1731` (step-8 map
  `Cancelled|Deprecated → not_planned`) and `_tmf_retry_one_close` (:2201
  contract comment, passes reason through to `provider_close`);
  `scripts/lib/tracker-edit.sh:88-93` (`Deprecated|Cancelled → not_planned`).
  Existing interface-layer pins (provider-test 4.4/4.4b `|close:42:not_planned`)
  remain correct and untouched.
- **Single-site audit (my own grep, not the coder's):**
  `grep -rn -- "--reason" scripts/lib/ scripts/*.sh project-template/scripts/`
  excluding tests → exactly 2 hits, both in `tracker-provider-gh.sh`
  (the :440 docstring + the :465 invocation). No other production gh-CLI
  close-reason site exists. Shipped-docs sweep: zero `--reason` references in
  `supporting-docs/`, `project-template/`, `pack-ops/`.

## Assessment 2 — Mock enforcement has teeth: CLEAN

- **Direct probes (run by me, not taken from the IMPL report):**
  - Probe 1, provider-test fake (byte-extracted from the `<<'FAKE_GH'`
    heredoc): `issue close 42 --reason not_planned` → rc=1 +
    `fake-gh: invalid --reason 'not_planned' ...`; `--reason "not planned"` →
    rc=0; `-r not_planned` → rc=1; `--reason completed` → rc=0.
  - Probe 2, bd134 transient stub (built via the suite's real
    `build_fake_gh_transient_close`): wrong vocabulary fails rc=1 on first
    AND second call (never "recovers" — guard runs BEFORE the transient
    simulation; state file confirms the wrong-vocab id was never marked
    `seen:`); valid `"not planned"` follows the intended transient path
    (503 first, rc=0 on retry).
- **All 10 stubs verified in the diff** against the IMPL §3 survey; the two
  always-fail stubs (`FAKEGH_PF`, bd134 persistent) are correctly exempt
  (reject everything by construction). Heredoc escaping audited per opener:
  unquoted heredocs (FAKEGH:520, FAKEGH_CP:1121, FAKEGH_C:1350, FAKEGH_R1:1481,
  FAKEGH_R2:1573, FAKEGH_BD108:1817, FAKEGH_CR:2000, bd134 FG, forward 4.3)
  use `\$` escapes; the quoted `'FAKEGH_REC'`:941 uses literals +
  `@@CLOSED_IDS@@` substitution; roundtrip/provider guards live in
  directly-written scripts. All consistent.
- **Group 7 genuinely end-to-end:** mini-fixture BD-601 `Status: Deprecated` +
  BD-602 `Status: Cancelled` decomposed to a per-entry tree, full
  `tracker_migrate_forward_run` against the vocabulary-enforcing fake;
  asserts rc=0 / no partial-write / `closed:     2` (matches the
  `tracker-migrate-forward.sh:1877` summary format) / both
  `issue close 60N --reason not planned` in the gh log / exactly 2 translated
  invocations / negative grep that `--reason not_planned` never reaches the
  CLI. Pre-fix this reproduces the C-8 shape exactly. Run result: 7 legs PASS
  within 190/0.
- **No coverage deleted:** the diff is additive except the header-comment
  reword ("(4.3 + Group 7)" → "(4.3)" with Group 7 parenthetical — correct,
  no Group 7 existed pre-fix) and the BD108 combined no-op arm split
  (`"issue close"|"issue reopen"|...` → guarded close arm + the remaining
  three verbs; behavior-equivalent for the other verbs).

## Assessment 3 — Oracle canary correctness: CLEAN

- **BD-909 fixture entry** (`scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`)
  is grammar-conformant with its 7 siblings and with `/backlog/_rules.md`
  Entry contract (Type/Status/Blockers/Unblocks/Description/Resolved;
  `Deprecated` is an admitted lifecycle state per `_rules.md` § Lifecycle).
  ID 909 collides with nothing (real backlog tops out at BD-213; fixture
  BD-9xx namespace; mid-cycle-create BD-908 distinct; repo-wide BD-909 grep
  hits only the fixture, the oracle test, and the IMPL report). The fixture
  has exactly one consumer (the oracle test) — no other suite pins its count.
- **Count assertions consistent with the now-8-entry fixture:**
  `N_CLOSED_BASELINE` is measured (`grep -hcE '^Status:
  (Resolved|Cancelled|Deprecated)$'` summed via the existing Deferred-canary
  awk idiom) = 2 (BD-902 Resolved + BD-909 Deprecated); the `die` floor (>=2)
  prevents silent canary retirement; the post-forward leg asserts the summary
  needle `closed:     $N_CLOSED_BASELINE` (exact spacing verified against
  `tracker-migrate-forward.sh:1877` and the live flip log line 22); all other
  oracle counts are dynamic and auto-adapt.
- **Default-SKIP guard still first:** lines 60-66 remain the first action
  (`PACK_TRACKER_LIVE_GH` unset OR gh missing OR auth not OK → pinned SKIP,
  exit 0). Unattended run verified: prints the pinned SKIP line, rc=0.
- **stateReason read-back leg records verbatim, does not pin:** asserts only
  `state == CLOSED` (raw gh casing) and ECHOES the `stateReason` value — the
  correct posture given POQ-2 (pinning a guessed shape would bake in the same
  class of mock-blindness this BD fixes). The new Deprecated count-round-trip
  status-oracle leg (`_dep_before == _dep_after`) is the loud failure if the
  live shape doesn't decode back through `_tmr_decode_status`.

## Assessment 4 — POQ-1 disposition: real BD-204-scope defect; SEPARATE IMMEDIATE COMMIT (do not fold into this fix pass)

- **Defect confirmed real and in BD-204 scope:**
  `scripts/lib/tracker-init.sh:343-360` (`_tracker_init_write_config`)
  hardcodes `[mirror] enabled = true` + `location_backlog/status/changelog =
  "BACKLOG.md"/"STATUS.md"/"CHANGELOG.md"` for ALL surfaces, surface-blind
  (no surface param reaches the writer). The BD-204 entry's SSOT/MIRROR
  paragraph requires the `tracker.toml [mirror]` table get the no-monolith
  retire-or-repoint (OPEN-mechanics bullet: "retiring/repointing `[mirror]` +
  Check 29"). Check 29′ landed its half
  (`scripts/validate-pack.py:2791-2799`: live pack config that OMITS
  `[mirror]` or has `enabled = false` → staleness N/A soft-pass; a config
  DECLARING enabled mirrors with missing files still FAILs) — the init writer
  did not. Live consequence reproduced: real-tree `validate-pack.py` fails
  with exactly the 3 `tracker.toml — mirror file '...' does not exist on
  disk` issues and nothing else.
- **What the writer should emit:** surface=pack → OMIT the `[mirror]` table
  entirely (the Check 29′ docstring names this as the Mode-3 pack shape;
  `enabled = false` is the alternative soft-pass arm). surface=client → KEEP
  the current bare-name keys until BD-206 retires the project-side mirror
  (`project-template/tracker.toml.project-example:37-42`: bare names are
  intentional — "trinity ## Document locations resolves to actual paths" —
  and the pack validator's staleness leg only runs on the PACK live config,
  so client bare names never hit it). The writer therefore needs a surface
  parameter, which `tracker_init_run` already has in hand.
- **Why NOT fold into this fix pass (size/blocked/fit test):**
  - FIT fails: different contract (init config-writer + Check 29 example
    schema) and different files from the close-reason translation; nothing
    same-file/same-contract with this diff.
  - SIZE is non-trivial: beyond the writer branch, `tracker.toml.pack-example`
    still declares `[mirror] enabled = true` (lines 33-37) and Check 29's
    example-schema REQUIRES the `[mirror]` table + all keys
    (`validate-pack.py:2686-2700` `_require("mirror", dict)`), so dropping
    [mirror] from the pack example forces a per-surface schema branch;
    `tracker-init-test.sh` has zero mirror-key assertions today (grep empty)
    but its init-output expectations need the new pack-shape legs.
  - NOT blocked: nothing it needs is unlanded. So: its own coder + bounded
    review cycle, as the immediate next commit in the C-8 resume batch —
    before the BD-204 end-of-BD audit, and ideally before the close re-run so
    the local battery is green for the rehearsal. Two companion actions ride
    with it: (a) Pack Chat (owner) deletes the `[mirror]` table from the live
    runtime `tracker.toml` (the artifact predates the fix; init re-run also
    regenerates it); (b) the new BD-or-anchor per OQ-1 needs
    user-discussion-and-approval if it opens as a BD rather than riding
    BD-204's open scope (it fits BD-204's existing OPEN-mechanics scope, so
    no new BD appears necessary).

## Assessment 5 — POQ-2: decoder expectation confirmed; oracle leg + one-shot live check close the DETECTION question; remedy stays anchored

- **Decoder expectation confirmed:** `_tmr_decode_status`
  (`scripts/lib/tracker-migrate-reverse.sh:255-271`) matches `state_reason`
  against exact lowercase `completed` / `not_planned|duplicate`; anything
  else closed falls through `*` → Resolved.
- **No normalization layer intervenes — concrete new evidence beyond the
  IMPL report:** `_gh_normalize_issue`
  (`scripts/lib/tracker-provider-gh.sh:237-238`) lowercases `state`
  (`.lower()` — needed because gh emits `OPEN`/`CLOSED`) but passes
  `stateReason` through VERBATIM. That asymmetry means the decoder sees
  exactly whatever casing/shape gh emits, and the fact that `state` NEEDS
  lowering is a strong prior that `stateReason` arrives as a GraphQL-style
  enum too (e.g. `NOT_PLANNED`), in which case a closed
  Deprecated/Cancelled issue would decode to Resolved via the `*` fallback —
  and `COMPLETED` would mask the problem on the Resolved cohort by reaching
  the same answer through the fallback. The Deprecated canary is therefore
  exactly the right probe.
- **Closure:** (a) the one-shot check the coder recommends
  (`gh issue view 21 -R DShaneNYC/... --json state,stateReason` immediately
  after the C-8 close re-run, BEFORE any reverse run) answers the shape
  question empirically in seconds; (b) the oracle's recorded read-back +
  Deprecated count-round-trip leg fail loudly on the next rehearsal if the
  shape mismatches. Together these fully close the DETECTION question. The
  REMEDY (harden `_tmr_decode_status` and/or normalize `state_reason` in
  `_gh_normalize_issue` to a case/shape-insensitive match — the latter is the
  single-site fix mirroring this BD's boundary-translation pattern) is
  correctly NOT in this diff (the right normalization target is unverifiable
  offline) but MUST carry a tracked anchor (BD-204 in-body section, or a
  typed `# VERIFY(live): TD-TBD` per the deferral-comment convention) when
  Pack Chat lands this commit — the IMPL report's §10 disposition says
  "surfaced to Pack Chat", which is not yet an anchor. POQ-3 (the roundtrip
  stateful fake now stores the CLI form `"not planned"` for any future mock
  not-planned close, while the decoder expects the interface token) correctly
  folds into the same anchor — no test is red today (verified: no mock
  fixture closes via not_planned through that fake).

---

## Verification log (all FOREGROUND, this session)

| Step | Where | Result |
|---|---|---|
| `gh issue close --help` vocabulary | local | `{completed|not planned|duplicate}` confirmed |
| Stub probes (provider-test fake; bd134 transient builder) | /tmp extraction | wrong vocab rc=1 both; translated form rc=0; no transient "recovery" on wrong vocab |
| `tracker-provider-test.sh` | real tree | 160 passed / 0 failed (incl. 1.9b ×4) |
| `tracker-migrate-forward-test.sh` | real tree | 190 passed / 0 failed (incl. Group 7 ×7 legs) |
| `tracker-migrate-roundtrip-test.sh` | real tree | 70 passed / 0 failed |
| `tracker-bd134-close-retry-test.sh` | real tree | 24 passed / 0 failed |
| `tracker-bd204-lossless-roundtrip-test.sh` unattended | real tree | pinned SKIP line, rc=0 (guard first; NOT run live) |
| `bash -n` all 6 edited shell files | real tree | clean |
| `python3 scripts/validate-pack.py` | real tree | rc=1 — EXACTLY the 3 `tracker.toml — mirror file ... does not exist` issues (POQ-1 signature; zero issues from this change) |
| FULL CI battery — every `run:` step of `.github/workflows/validate-pack.yml` (validate-pack, DEEP, all 45 test suites, `build.sh --all --clean`, manifest diff, `--verify`) | isolated copy at `/tmp/bd204-review-checkout` WITHOUT `tracker.toml`/`.pack-tracker/` (prompt-sanctioned method) | **ALL rc=0**, including every suite the real tree fails (tracker-init, checks-36..46, check-40, check-49, migrate-v10-to-v11 ×4, test-v11-realistic-ot, persona-contracts) |
| Failure classification | both trees | every real-tree failure is POQ-1-environmental by construction: identical code, artifacts removed → green |
| Manifest claim (rule 7) | isolated copy | `build.sh --all --clean` rc=0 → `git diff test-fixtures/manifest.txt` EMPTY; `--verify` rc=0; stated reason verified (`test-fixtures/v11-flat-file/scripts/lib/` contains only `detect.sh`; `scripts/tests/` not in the copy set) |

## Review-checklist coverage (clean items)

- **Trinity rule:** N/A — no CLAUDE/AGENTS/GEMINI file (pack-root or
  project-template) in the diff.
- **Cross-reference integrity:** BD-909 referenced only by fixture + oracle +
  IMPL report; the lossless fixture has exactly one consumer; no doc pins the
  old 7-entry count; no shipped doc references `--reason`; forward-test header
  comment fixed to avoid the Group-7 collision. One stale-comment obligation
  found (MUST-1, pre-existing anchored item, fires on this commit).
- **Maintenance-docs consistency:** IMPL report present and accurate against
  my independent measurements (file set, +450/-8, suite counts, ENV
  classification all reproduced).
- **validate-pack.py alignment:** no new files/dirs needing CI coverage (the
  report is a workflow artifact, Pattern-B exempt; fixture edit is inside an
  existing fixture).
- **Migration safety / README layout / BACKLOG accuracy:** no client-facing
  file, no file added/moved/removed, BD-204 stays Open (this is a mid-BD fix
  commit; status flip is end-of-batch per pack memory).
- **Scope keyword:** proposed subject carries `(pack-only)` — diff touches
  only `scripts/` (+ untracked maintenance-docs report); Check 36 will pass.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs run this session: `rev-parse HEAD`, `status --porcelain`, `diff` (×several, incl. in the /tmp copy), `log`, `show` — all read-only. No add/commit/push/tag/stash/reset/restore/checkout anywhere (the CI `git checkout HEAD -- manifest.txt` step was replaced by `git diff --quiet -- test-fixtures/manifest.txt` → "MANIFEST DIFF EMPTY" in the copy). Output = this report file only. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops on trusted state: temp dirs self-created under /tmp (`/tmp/bd204-probe`, `/tmp/bd204-review-checkout`) and only those were rm'd/modified; `tracker.toml` + `.pack-tracker/` in the REAL tree untouched (post-review `git status --porcelain` shape identical to start: 7 ` M` + 2 `??` + this report). | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 84f6a83d02d8467362972b86d1eb642dec9f4177; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CLOSE-REASON-FIX.md`. No parent stop message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block read this session (lines 206-236, format template followed). | COMPLIANT |
| 5. agents-read-rule-docs-in-full | Read IN FULL with line counts: `CLAUDE.md` (580 lines, including the complete `## Pack memory` section, lines 140-579); `/tmp/bd204-c8-flip.log` (34 lines); `feedback_verify_full_ci_suite.md` (42 lines); `feedback_agent_output_rules_applied_block.md` (14 lines). Section reads per prompt: `tracker_provider_gh_close` + neighbors (provider :400-480), forward close step + `_tmf_retry_one_close` (:1700-1800, :2190-2260), `_tmr_decode_status` (reverse :200-290), all 10 hardened stubs (full diff + in-file context), oracle BD-909 legs + head (:1-80, :276+, :355+, :677+), `tracker-init.sh` writer (:300-400), Check 29′ (`validate-pack.py:2680-2855`), `/backlog/_rules.md` (95 lines), `/changelog/_rules.md` (67 lines), `/backlog/BD-204.md` (full), IMPL-REPORT (382 lines, full). | COMPLIANT |
| 6. verify-full-ci-suite | Real tree: `validate-pack.py` rc=1 with exactly 3 mirror-file issues (quoted in Verification log). Isolated `/tmp/bd204-review-checkout` (no tracker.toml/.pack-tracker): validate-pack rc=0, DEEP rc=0, and ALL 45 workflow test steps + fixture build/diff/verify rc=0 — run FOREGROUND in CI order across chunks A-E2 (per-step `rc=0 :: <cmd>` lines captured). Live oracle: default-SKIP verified (pinned SKIP, rc=0); NOT run live. Classification: every real-tree failure is POQ-1-environmental — proven by the identical-code clean-checkout green, exactly the prompt-sanctioned method. The four modified suites green in BOTH trees (160/190/70/24, 0 failed). | COMPLIANT |
| 7. regenerate-manifest-v11-surface | Coder's claim independently reproduced in the isolated copy: `bash test-fixtures/build.sh --all --clean` rc=0 → `git diff --quiet -- test-fixtures/manifest.txt` → "MANIFEST DIFF EMPTY"; `--verify` rc=0. Stated reason verified: `ls test-fixtures/v11-flat-file/scripts/lib/` → `detect.sh` only; neither `tracker-provider-gh.sh` nor `scripts/tests/` ships to fixtures. | COMPLIANT |
| 8. pack-only (BD-204 HARD) | `git diff --name-only` = exactly the 7 expected `scripts/` files (1 lib + 5 tests + 1 test fixture). Untracked = `maintenance-docs/.../IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md` (coder report) + `tracker.toml` (pre-existing runtime) + this review report; `.pack-tracker/` gitignored (`.gitignore:12`). No `project-template/` or `supporting-docs/` path anywhere in the diff. | COMPLIANT |
| 9. scope-deliverables-to-the-ask | 1 MUST + 1 NIT, both concrete defects/obligations in or fired-by this change; POQ-1/POQ-2 handled as the prompt's requested assessments (disposition recommendations, no fixes performed); no out-of-scope edits, no review of the Pack-Chat-owned runtime artifacts beyond read-only attribution. | COMPLIANT |

— end of review —
