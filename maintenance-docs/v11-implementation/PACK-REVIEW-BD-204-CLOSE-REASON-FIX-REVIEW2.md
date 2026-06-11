# PACK-REVIEW — BD-204 close-reason fix, reviewer pass 2 (final of bounded cycle)

- **Reviewer:** fresh pack-reviewer, pass 2 (post review/fix pair 1)
- **Branch / HEAD:** v11-dev @ `84f6a83d02d8467362972b86d1eb642dec9f4177` (all reviewed work uncommitted)
- **Date:** 2026-06-11
- **Scope:** the ENTIRE uncommitted `git diff` vs HEAD (7 files, +466/-13), excluding
  the Pack-Chat-owned C-8 runtime artifacts (`tracker.toml`, gitignored `.pack-tracker/`)
- **Inputs:** both IMPL reports read in full; NO `PACK-REVIEW-*.md` read; NO live GitHub calls
- **Verdict:** **APPROVE** — commit-ready, conditional on MUST-1 (Pack-Chat
  commit-time bookkeeping only; NO fix-coder pass required, no working-tree code change)

---

## 1. Verdict summary

The combined change is correct, single-sited, well-pinned, and fully green under the
established verification criteria. I independently reproduced every load-bearing claim:
the translation is the only production `gh issue close` site; the hardened stubs reject
wrong vocabulary on BOTH `--reason` and `-r` (probed two stubs directly); reverting the
provider fix in an isolated copy turns 1.9b and Group 7 loudly red in exactly the C-8
partial-write shape; the rewritten `repo view` comment is fabrication-free against
source; the full CI battery is green in an isolated /tmp checkout and the only real-tree
failure is byte-for-byte the known 3-issue POQ-1 set; the manifest-diff-empty claim is
independently confirmed by rebuild.

One MUST (process/bookkeeping, Pack Chat), three NITs. No BLOCKER.

---

## 2. Findings

### MUST-1 — POQ-2/POQ-3 deferred work needs a tracked anchor at commit time (Pack Chat action)

- **Anchor:** `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md`
  §10 (POQ-2, POQ-3); `scripts/lib/tracker-provider-gh.sh` `_gh_normalize_issue`
  (`"state_reason": opt(data, "stateReason")` — passed through RAW);
  `scripts/lib/tracker-migrate-reverse.sh` `_tmr_decode_status` (lines 255-268,
  lowercase `not_planned|duplicate` match).
- **What I verified statically:** `_gh_normalize_issue` lowercases `state`
  (`(opt(data, "state", "OPEN") or "OPEN").lower()` — evidence gh returns upper-case
  enums) but passes `stateReason` through untransformed. The GraphQL `IssueStateReason`
  enum is upper-case (`NOT_PLANNED`); if the live read-back is that shape, a closed
  Deprecated/Cancelled issue decodes through `_tmr_decode_status`'s `*` fallback to
  **Resolved** on a live reverse — the `status:deprecated` label disambiguator never
  fires because the case-arm is never entered.
- **Why not a code BLOCKER here:** this is a PRE-EXISTING latent gap, not introduced by
  this diff, and the diff is precisely the instrumentation that will answer it: the new
  canary RECORDS the live `stateReason` read-back verbatim, and the new Deprecated
  status-oracle leg fails loudly on any decode mismatch at the next live rehearsal.
  The design choice (record, don't pin an unverifiable shape) is sound.
- **Why MUST:** Pack memory "Deferred work needs a tracked anchor" — POQ entries in an
  IMPL-REPORT are NOT acceptable anchors (workflow artifacts archive at version ship).
  POQ-2/POQ-3 (live stateReason-shape verification + potential `_tmr_decode_status` /
  store-side hardening) must land on a live forward-pointing surface — e.g. a dated note
  on `/backlog/BD-204.md` (pattern precedent: the existing line-25 and line-29 dated
  notes) — at or before this commit. This is pack-chat-only bookkeeping; no fix-coder
  spawn is warranted for it, which is why the verdict is APPROVE rather than
  APPROVE-WITH-FIXES.

### NIT-1 — count assertions use prefix-vulnerable substring matching

- **Anchor:** `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (close canary:
  `assert_contains ... "closed:     $N_CLOSED_BASELINE"`);
  `scripts/tests/tracker-migrate-forward-test.sh` Group 7 (`"closed:     2"`).
- `assert_contains` substring semantics mean `closed:     2` would also match a summary
  reading `closed:     25`. Mitigated: fixtures are controlled, Group 7 additionally
  pins `exactly 2 translated close invocations` via `grep -c`, and the lossless test
  backs the count with a per-issue `state == CLOSED` read. This is also the established
  idiom for the suite's existing count assertions (e.g. `created:    $N_BASELINE` at
  line 328). Cosmetic robustness only; fine to leave.

### NIT-2 — stub guards do not parse the `--reason=value` form

- **Anchor:** all 11 guard sites (e.g. `scripts/tests/tracker-provider-test.sh:130`,
  `scripts/tests/tracker-migrate-roundtrip-test.sh:163`).
- The guards capture the token FOLLOWING `--reason`/`-r`; an equals-joined
  `--reason=not_planned` would pass the guard unexamined. The production provider always
  emits separate tokens (`--reason "$cli_reason"`), so today's enforcement is complete;
  a future regression that switched to the equals form could mock-pass. Real gh accepts
  both forms, so this is a theoretical enforcement gap, not a current defect.

### NIT-3 — IMPL-REPORT narrative figure inconsistent with the flip log

- **Anchor:** `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md`
  §1 ("162 Resolved closes succeeded live") vs `/tmp/bd204-c8-flip.log` line 22
  (`closed:     167`) + line 15 (`persistent=5`). The log arithmetic says 167 closes
  succeeded (all necessarily `completed`, since all five not-planned closes failed);
  "162" appears to be a miscount. Report-only narrative inaccuracy; the report is a
  workflow artifact. Optional to correct.

---

## 3. What I checked (clean areas, with evidence)

### 3.1 Translation correctness + single-site claim — CLEAN

- Own grep across `scripts/lib/` + `scripts/*.sh`: the ONLY production
  `gh issue close` invocation is `scripts/lib/tracker-provider-gh.sh:465`
  (`_gh_run gh issue close "$id" --reason "$cli_reason"`). All other `issue close`
  matches are comments or test fakes.
- Translation is local and minimal: `cli_reason` set only when
  `$reason == "not_planned"`; the validation case-arm (line 457), all callers
  (`tracker-migrate-forward.sh:1730` status mapping; `tracker-edit.sh:93`), and the
  success JSON (`"state_reason": "$reason"` → interface token) are untouched —
  interface vocabulary preserved exactly as claimed.
- `gh issue close --help` (local gh 2.93.0): `--reason string  Reason for closing:
  {completed|not planned|duplicate}` — the CLI vocabulary claim is verbatim-true.
- The new docstring's claims all verify against the flip log (5 persistent step-8
  close failures: BD-021/022/023/103/123, "failed after 3 attempts" each).

### 3.2 Stub enforcement teeth — CLEAN (probed myself)

- **Probe 1 (provider-test fake, byte-extracted to /tmp):**
  `issue close 42 --reason not_planned` → rc=1 + `fake-gh: invalid --reason
  'not_planned' ...`; same via `-r` → rc=1; `--reason "not planned"` → rc=0;
  `--reason completed` → rc=0.
- **Probe 2 (roundtrip stateful fake, byte-extracted):** `--reason not_planned` → rc=1;
  `-r not_planned` → rc=1; `--reason wontfix` → rc=1; `--reason "not planned"` → rc=0,
  and the state file then carries `"stateReason":"not planned"` (live confirmation of
  the POQ-3 store-side observation).
- **End-to-end revert probe (isolated /tmp copy, fix reverted to the pre-fix verbatim
  pass-through):** `tracker-provider-test.sh` rc=1 with all 4 of the 1.9b legs FAIL;
  `tracker-migrate-forward-test.sh` rc=1 with Group 7 legs 7.1/7.2 FAIL (rc, no
  partial-write, summary count, both translated invocations) — exactly the C-8 shape.
  The new tests genuinely pin the behavior; they are not tautological.
- Guard inventory cross-checked: 11 guarded `issue close` arms + 2 always-fail stubs
  (`FAKEGH_PF`, bd134 persistent — reject everything by construction, correctly left
  unguarded). bd134 transient stub's guard sits BEFORE the transient-failure simulation
  (verified in diff), so a wrong-vocabulary close can never "recover".

### 3.3 Group 7 + 1.9b construction — CLEAN

- Group 7 mini-fixture covers Deprecated (BD-601) AND Cancelled (BD-602); deterministic
  gh ids 601/602 (counter seeded 600); negative leg 7.3 pins that `--reason not_planned`
  never reaches the CLI; `exactly 2 translated invocations` closes the count.
- 1.9b asserts rc=0, interface-token `state_reason` in the return JSON, the translated
  argv in `FAKE_GH_LOG`, and the negative leak grep.
- rc-capture idiom (`output_cr=$(...); rc_cr=$?`) is safe — both suites run `set -u`,
  not `set -e` — and matches the 11 existing `tracker_migrate_forward_run` call sites.
- The forward-test header-comment fix ("4.3 + Group 7" → "4.3" + parenthetical) resolves
  the would-be collision with the new Group 7; no other "Group 7" cross-reference in the
  repo refers to this suite (grep: hits in other test files are their own internal groups).

### 3.4 BD-909 canary + oracle legs — CLEAN

- Fixture grammar matches the sibling entries (optional fields vary across the cohort by
  design — BD-902 has no Description; File/Symbol is optional); BD-909 sits in the
  established 90x fixture-id namespace; references confined to the two BD-204 lossless
  files.
- **Oracle count consistency verified at the source:** forward step 8's close-status set
  is exactly `Resolved|Cancelled|Deprecated` (`tracker-migrate-forward.sh` close loop,
  with `Resolved → completed`, `Cancelled|Deprecated → not_planned`) — identical to the
  `N_CLOSED_BASELINE` grep class. Fixture closed-status count = 2 (BD-902 Resolved +
  BD-909 Deprecated), satisfying the new `>= 2` seed guard that prevents silent canary
  retirement.
- Read-back leg correctly RECORDS (echoes) `stateReason` rather than pinning an
  offline-unverifiable shape; the Deprecated round-trip count oracle is the loud
  failure path (see MUST-1 context).
- **Default-SKIP first:** unattended run on the real tree prints exactly
  `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0, before any
  other output; not a CI workflow step. `bash -n` clean. NOT run live (per scope).

### 3.5 Rewritten `repo view` comment vs `_gh_owner_repo` — CLEAN (no fabrication survives)

Every claim in the rewritten comment (`scripts/tests/tracker-migrate-roundtrip-test.sh`
`"repo view")` arm) checked against source:

- `_gh_owner_repo` defined at `scripts/lib/tracker-provider-gh.sh:168`.
- All five claimed callers are REAL, FULL symbol names enclosing the five call sites:
  `tracker_provider_gh_link` (:605/call :621), `tracker_provider_gh_unlink`
  (:719/:742), `tracker_provider_gh_sub_issue_create` (:778/:800),
  `tracker_provider_gh_sub_issue_list` (:810/:820),
  `tracker_provider_gh_sub_issue_unlink` (:829/:840). The FIX1 symbol-name correction
  (full names replacing the fabricated `_sub_issue_list`/`_sub_issue_unlink`
  abbreviations) is in place; exact-grep for each name now resolves. No other
  fabricated symbol found.
- PREFERS `${GH_REPO}` — true (`local slug="${GH_REPO:-}"` first); HOST/-strip — true
  (`*/*/*) slug="${slug#*/}"`); post-strip shape guard — true (one-slash, both segments
  non-empty, typed validation error otherwise); `gh repo view --json nameWithOwner
  --jq .nameWithOwner` ONLY as the GH_REPO-unset fallback — true (reached only after the
  `[[ -n "$slug" ]]` branch returns).
- `_tmr_fetch_first_class_blocked_by` mirrors the order inline — true
  (`tracker-migrate-reverse.sh` ~:399 GH_REPO-preferred + same `*/*/*` strip idiom,
  `gh repo view` fallback; in-code comment documents the deliberate inline choice).
- No line-number references in the comment (file + symbol only) — compliant with the
  architect-doc-reconciliation memory's drift rule.
- **Anchor discharge confirmed:** `/backlog/BD-204.md` line 29 dated note (2026-06-10,
  "Fix at the next commit touching that file") is genuinely discharged by this change —
  the same uncommitted diff touches that file and replaces the stale BD-111-era
  description. (Note flip itself is Pack Chat bookkeeping at commit.) The line-30 note
  (`scripts/pack-td.sh`) is NOT triggered — that file is untouched here.

### 3.6 Hygiene sweeps — CLEAN

- No plain-English deferral comments in added lines (the three `TODO(version)` hits are
  fixture entry-grammar `Type:` fields, not deferral markers).
- No new files outside `maintenance-docs/` workflow artifacts (exempt from the
  no-new-top-level-doc signal during the active batch); no validate-pack.py /
  README-layout / trinity / migration-doc obligations triggered (no shipped-surface,
  template, or structural change).
- `.pack-tracker/` confirmed gitignored (`.gitignore:12` via `git check-ignore`).

---

## 4. Verification matrix (all FOREGROUND, this session)

| Step | Where | Result |
|---|---|---|
| `tracker-provider-test.sh` | real tree | 160 passed / 0 failed, rc=0 |
| `tracker-migrate-forward-test.sh` | real tree | 190 passed / 0 failed, rc=0 (Group 7: 7/7) |
| `tracker-migrate-roundtrip-test.sh` | real tree | 70 passed / 0 failed, rc=0 |
| `tracker-bd134-close-retry-test.sh` | real tree | 24 passed / 0 failed, rc=0 |
| `tracker-bd204-lossless-roundtrip-test.sh` | real tree | pinned SKIP line, rc=0 (live oracle default-SKIP; not run live) |
| `bash -n` all 6 edited shell files | real tree | clean |
| `python3 scripts/validate-pack.py` | real tree | rc=1 — EXACTLY 3 FAILs, all `tracker.toml — mirror file '{BACKLOG,STATUS,CHANGELOG}.md' ... does not exist` = the known POQ-1 set, 1:1; zero issues from this change |
| `validate-pack.py` + `PACK_VALIDATE_DEEP=1` | isolated `/tmp/bd204-rev2-checkout` (no root tracker.toml / .pack-tracker; fixture tracker.tomls preserved) | both rc=0, `PASSED — all checks clean` |
| Full CI battery — all 52 `run:` suite steps of `.github/workflows/validate-pack.yml` in CI order | isolated copy | ALL rc=0 (chunks A-F; per-step `rc=0 ::` lines captured) |
| `test-fixtures/build.sh --all --clean` → manifest diff → `--verify` | isolated copy | rc=0 → pre/post `diff` EMPTY (0 lines) → `--verify` rc=0, all six rows OK |
| Real-tree manifest | real tree | `test-fixtures/manifest.txt` absent from `git status`/`git diff` (unchanged) |
| Revert-probe (fix removed in copy) | isolated copy | provider-test rc=1 (4× 1.9b FAIL); forward-test rc=1 (Group 7 FAILs) — teeth proven |
| Stub probes ×2 (provider fake + roundtrip stateful fake, byte-extracted) | /tmp | wrong vocab rc=1 on `--reason` AND `-r`; correct vocab rc=0 |

Failure classification: the ONLY real-tree failure is the validate-pack rc=1 mapping
exactly to the known 3-issue POQ-1 set (untracked C-8 `tracker.toml` `[mirror]` keys
naming deleted monoliths); identical code in the artifact-free isolated copy is fully
green. Nothing in this change causes or worsens it.

Session hygiene disclosure: stub probe 2 briefly created a scratch `@@STATE@@` file in
the repo root (the extracted fake's placeholder state path); it was my own scratch
artifact and was removed (`rm -f '@@STATE@@'`); end-state `git status --porcelain` is
byte-identical to spawn state plus this report.

---

## 5. Read-in-full attestations (rule 5)

| File | Lines | Read |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | 579 | IN FULL |
| `/tmp/bd204-c8-flip.log` | 34 | IN FULL |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | 43 | IN FULL |
| `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | 15 | IN FULL |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (conditional MUST-READ from the memory file) | §206-233 | section read |

Section reads per prompt also completed: `tracker_provider_gh_close` + `_gh_owner_repo`
+ `_gh_normalize_issue` (tracker-provider-gh.sh); forward step-8 close loop + status
mapping (tracker-migrate-forward.sh ~:1700-1760); `_tmr_decode_status` (:226-283) +
`_tmr_fetch_first_class_blocked_by` (:395-455) (tracker-migrate-reverse.sh); every
hardened close stub across the 4 test files (full diff + FIX1 13-arm inventory
cross-check); new oracle legs + BD-909 fixture entry; rewritten `repo view` comment.

---

## 6. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs run this session: `rev-parse HEAD`, `status --porcelain`, `diff` (+ `--name-only`/`--stat`), `check-ignore -v` — all read-only. No add/commit/push/tag/stash/reset/restore/checkout. The revert-probe edit was applied ONLY to the /tmp scratch copy, never the repo. Output = this report file only. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive op on trusted state: scratch confined to `/tmp/bd204-*` (self-provisioned); the one repo-root scratch file my probe created (`@@STATE@@`, 93 bytes, self-created seconds earlier) was removed with `rm -f` and end-state `git status --porcelain` verified identical to spawn + this report; C-8 runtime artifacts untouched. | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 84f6a83d02d8467362972b86d1eb642dec9f4177; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CLOSE-REASON-FIX-REVIEW2.md`. No parent stop message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; every row carries quoted command/output evidence; conditional MUST-READ (`PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block) read this session; no empty rows, no AMBIGUOUS. | COMPLIANT |
| 5. agents-read-rule-docs-in-full | §5 table above: CLAUDE.md 579 lines IN FULL; flip log 34 lines; feedback_verify_full_ci_suite.md 43 lines; feedback_agent_output_rules_applied_block.md 15 lines — each path + line count attested. | COMPLIANT |
| 6. verify-full-ci-suite | §4 matrix: 4 modified suites green on real tree (160/190/70/24, 0 failed) + lossless default-SKIP rc=0; isolated /tmp checkout (no tracker.toml/.pack-tracker): validate-pack rc=0, DEEP rc=0, ALL 52 workflow suite steps rc=0, fixtures build/diff/verify rc=0 — all FOREGROUND. Real-tree failure classified 1:1 against the known 3-issue POQ-1 set (`grep -c 'does not exist'` = 3; all three name `tracker.toml — mirror file`). Live oracle default-SKIP honored. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | Empty-diff claim INDEPENDENTLY verified: `build.sh --all --clean` rc=0 in the isolated copy → pre/post `diff` of `manifest.txt` rc=0, 0 lines → `--verify` rc=0 all six rows. Cause confirmed analytically: `grep -c tracker-provider-gh scripts/init-project.sh` = 0; `find test-fixtures -name 'tracker-provider-gh.sh'` empty; only `detect.sh` ships from `scripts/lib/`. Real-tree manifest unchanged in `git status`/`git diff`. | COMPLIANT |
| 8. pack-only (BD-204 HARD constraint) | `git diff --name-only` = exactly 7 `scripts/` paths (`scripts/lib/tracker-provider-gh.sh` + 5 test files + 1 fixture BACKLOG.md). Untracked additions = runtime `tracker.toml` (+ gitignored `.pack-tracker/`, confirmed `.gitignore:12`) + 2 IMPL reports + prior review report + this report. No `project-template/`, no `supporting-docs/` path anywhere in the diff. | COMPLIANT |
| 9. scope-deliverables-to-the-ask | Findings limited to real defects/conditions of THIS change: MUST-1 binds to the change's own POQ-2/3 disposition + the tracked-anchor memory rule; NIT-1/2 are properties of the added test code; NIT-3 is an inaccuracy in a report this commit will carry. Pre-existing latent decode gap reported only in its capacity as the change's acknowledged live-verification dependency, not "fixed" or expanded. | COMPLIANT |

— end of review —
