# PACK-REVIEW — BD-204 GH_REPO resolution lib fix, reviewer pass 3 (FINAL)

- **Date:** 2026-06-10
- **Branch:** `v11-dev`; **HEAD:** `1068c74a90b96fe78c48f73b818ed777c4deb873` (unchanged throughout review)
- **Reviewer:** fresh pack-reviewer instance (pass 3 of the bounded review/fix cycle — final pass)
- **Scope:** the ENTIRE uncommitted working-tree diff vs HEAD `1068c74`, reviewed fresh and on its own merits. Prior `PACK-REVIEW-*` reports NOT read (bias rule).

## Verdict

**APPROVE** — the change is commit-ready. Zero BLOCKER / MUST / SHOULD findings. One NIT
(stale comment in an out-of-footprint test file), suitable for tech-debt anchoring or a
ride-along in a future BD-204 commit; it does not dirty this diff.

## 1. Footprint verified

`git diff --name-only` = exactly the four expected files:

```
scripts/lib/tracker-migrate-reverse.sh        (+19)
scripts/lib/tracker-provider-gh.sh            (+93/−some, 5 call-site swaps)
scripts/tests/tracker-migrate-reverse-test.sh (+46)
scripts/tests/tracker-provider-test.sh        (+193/−12)
```

Untracked additions: exactly the five named BD-204 cycle reports
(`IMPL-REPORT-BD-204-GHREPO-RESOLUTION{,-FIX1,-FIX2}.md`,
`PACK-REVIEW-BD-204-GHREPO-RESOLUTION{,-REVIEW2}.md`) + this report. Note: the
review prompt's parenthetical said "two IMPL, two FIX"; the actual artifact set is
one base IMPL + two FIX + two reviews — the correct artifacts for a
base-pass + 2-fix-pass cycle; no unexpected files.

No `project-template/`, `supporting-docs/`, or any other surface touched. HEAD identical
before and after review.

## 2. Findings

### NIT-1 — stale fake-gh comment in `scripts/tests/tracker-migrate-roundtrip-test.sh:192-200`

The roundtrip suite's fake-gh `repo view` arm carries a BD-111-era comment: "the
production code does `_gh_run gh repo view --json nameWithOwner --jq .nameWithOwner`
in multiple places (sub_issue_create, link, unlink, _tmr_fetch_first_class_blocked_by)".
Post-BD-204 this enumeration is inaccurate: those sites now route through
`_gh_owner_repo` (GH_REPO-preferred), and `gh repo view` is consulted only on the
GH_REPO-unset fallback (provider lib via `_gh_run`; reverse lib via its own bare
fallback arm). The fake arm itself remains functionally required — the roundtrip suite
runs GH_REPO-unset, so the fallback path still fires and the suite passes (51/51 in the
battery). Comment text only; the file is outside this change's four-file footprint, so
fixing it here would have widened the diff. Recommend: fold the one-comment correction
into the next BD-204 commit that touches the roundtrip suite, or anchor as tech debt
per `feedback-deferred-work-tracking`. The fake is slug-insensitive for `/repos/...`
paths (`tracker-migrate-roundtrip-test.sh:300` extracts the issue number regardless of
slug), so an ambient `GH_REPO` cannot break its assertions — no behavioral exposure.

No other findings.

## 3. Success-criterion verification (what was checked, including clean areas)

### 3.1 Helper + guard — `_gh_owner_repo()` (`scripts/lib/tracker-provider-gh.sh:168-208`)

Read the helper + full docstring and all five call sites in current state. Independent
sandboxed probe (`env -i bash`, libs sourced, zero live GitHub calls):

```
GH_REPO=[owner/repo]                      -> rc=0 out=[owner/repo]
GH_REPO=[github.example.com/owner/repo]   -> rc=0 out=[owner/repo]
GH_REPO=[/owner/repo]                     -> rc=0 out=[owner/repo]   (documented silent normalization)
GH_REPO=[a/b/c/d]                         -> rc=1 out=[]
GH_REPO=[owner/repo/]                     -> rc=1 out=[]
GH_REPO=[owner]                           -> rc=1 out=[]
GH_REPO=[/owner]                          -> rc=1 out=[]
GH_REPO=[host//repo]                      -> rc=1 out=[]
GH_REPO=[owner//]                         -> rc=1 out=[]
GH_REPO=[//]                              -> rc=1 out=[]
GH_REPO=[github.example.com/owner/repo/]  -> rc=1 out=[]
```

- Both canonical shapes accepted; every degenerate shape rejected via typed
  `tracker_error_emit "validation"` (verified `tracker-errors.sh:49` emits to stderr,
  returns 1) — fail-loud, never a silent fallback past a caller-supplied value.
- Comment claims match probed behavior EXACTLY, including the leading-slash wording:
  the guard comment (lines 179-189) and docstring item 2 (lines 152-161) both document
  `/owner/repo` as normalize-and-accept (empty leading segment stripped as zero-length
  HOST), which the probe confirms. The reject-set enumeration (slash-less; >=3 slashes
  pre-strip; trailing slash; empty owner/repo segment post-strip) is exhaustive against
  the probe matrix.
- Fallback gating correct: `gh repo view` (via `_gh_run`, typed-error classifying) fires
  ONLY when `GH_REPO` is unset/empty (line 172-173 guard structure); empty repo-view
  output gets its own typed error (lines 202-205).
- `tracker_gh_repo_setup` pre-call matches `_gh_run`'s guard (`declare -f` check); the
  setup helper (`tracker-config.sh:252-283`) is no-op when GH_REPO pre-set (test seam
  preserved) and exports the canonical `[HOST/]OWNER/REPO` shape — the strip is the
  correct complement.
- All five call sites swapped (`tracker_provider_gh_link`, `_unlink`,
  `_sub_issue_create`, `_sub_issue_list`, `_sub_issue_unlink`); `sub_issue_list`'s
  `cut -d/` owner/name split receives the bare slug. Command-substitution call shape
  (`owner_repo=$(_gh_owner_repo) || return 1`) propagates stderr + rc correctly.
- Checked-clean edge: a caller-supplied GH_REPO with internal whitespace passes the
  shape guard but fails downstream loud via `_gh_run`'s typed classification;
  `tracker_gh_repo_setup` already rejects whitespace at export time. No silent path.

### 3.2 Reverse-path strip — `_tmr_fetch_first_class_blocked_by` (`tracker-migrate-reverse.sh:390-456`)

Read the full function. Independent probe with a PATH-prepended fake gh that fails
every call:

```
GH_REPO=[a/b/c/d]                       -> rc=0 out=[[]]
GH_REPO=[owner/]                        -> rc=0 out=[[]]
GH_REPO=[host//repo]                    -> rc=0 out=[[]]
GH_REPO=[github.example.com/owner/repo] -> rc=0 out=[[]]
```

- Host-prefixed shape strips to bare `OWNER/REPO` before the `cut -d/` split (same
  `*/*/*` idiom as the provider lib); plain `owner/repo` passes untouched.
- Best-effort `[]` contract intact: every degenerate value degrades to `[]` with rc=0;
  the function never aborts the reverse run.
- The degradation-path comment (lines 411-415) names the ACTUAL path and I verified the
  claim structurally: the entry condition requires >=1 slash; the strip only fires on
  >=2 slashes and removes exactly one segment, so post-strip always retains >=1 slash —
  the line-426 `[[ -z || != */* ]]` → `[]` guard is provably unreachable from the strip
  branch (it remains reachable from the repo-view fallback arm). Degradation flows via
  the failed GraphQL `repository()` lookup → swallowed `provider_raw` error branch
  (lines 440-443) → `[]`, exactly as the comment states.
- The inline-strip-not-cross-lib-call rationale is sound: `_gh_owner_repo` is a private
  (`_gh_`-prefixed, per the lib's own header contract line 16) helper of
  `tracker-provider-gh.sh`, and its fail-loud contract would violate this function's
  best-effort contract anyway.

### 3.3 Coverage — new legs genuinely pin behavior

- **Kill switch:** `FAKE_GH_REPO_VIEW_FAIL` (provider-test fake gh, lines 110-119)
  reproduces the real non-clone-cwd death for any `repo ...` argv, checked AFTER
  logging so regressions are visible in `FAKE_GH_LOG`. Legs 1.17f (link), 1.20d
  (unlink), 1.21b (sub_issue_create), 1.21d (sub_issue_unlink) assert success with
  repo-view dead AND grep-assert `repo view` absent from the log.
- **Host-prefix legs:** 1.17g (REST path uses bare slug; `/repos/github.com/` leak
  asserted absent), 1.21c (GraphQL `owner=` split; `owner=github.com` leak asserted
  absent — matches the real invocation `-F "owner=$owner"` at
  `tracker-provider-gh.sh:769`), reverse-suite 7.3b (host-prefixed AND plain shapes,
  with a fake that DIES on repo view, proving GH_REPO supplied the slug).
- **Shape-guard legs:** 1.17h (`a/b/c/d` and `optiquity/pack/` → rc=1 + typed
  validation message asserted; kill switch still armed so a silent fallback would also
  fail loud).
- **Ambient scrub:** suite-start `unset GH_REPO` + `reset_fake_gh` extended to scrub
  `GH_REPO` and `FAKE_GH_REPO_VIEW_FAIL` — necessary and sufficient: the provider suite
  is the only suite asserting the fallback path is consulted (1.17a/1.20a), and no
  tracker.toml is in scope so `tracker_gh_repo_setup` cannot re-export. The reverse
  suite's 7.3 already had its own pre-existing `unset GH_REPO` (line 946); the
  roundtrip/forward suites are slug-insensitive (§2 NIT-1 analysis).
- **No coverage deleted:** the only removed test lines are the 1.17a/1.20a assertion
  LABELS (re-labeled "(GH_REPO-unset fallback)") — the assertions themselves
  (`assert_contains ... "repo view"`) are retained. All other test changes are additive.
- **Mutation checks (independent, /tmp copies, repo untouched):**
  (a) reverting the link call site to the old `_gh_run gh repo view` idiom → suite
  rc=1, 8 assertions fail (1.17f x5, 1.17g x2, 1.17h x1) — the kill switch bites;
  (b) removing the reverse-lib `case` strip → suite rc=1, 3 assertions fail (7.3b
  owner/name/leak) — the host-prefix leg bites. Both copies deleted after use.
- Dispatch-infra reuse verified: 1.21b's `api-issue-100`/`api-issue-42`/`api-graphql`
  file names match `_fake_gh_select_stdout`'s mapping (lines 120-155);
  `provider_sub_issue_create 100 '{"existing_id":"42"}'` exercises the existing-id
  branch (`tracker-provider-gh.sh:732-734`), bypassing create. Suites use `set -u`
  only (no `set -e`), so the rc-capture patterns are sound.

### 3.4 Completeness — no remaining un-fixed patterns

Independent greps over `scripts/lib/` + `scripts/*.sh`:

- `gh repo view` remaining: ONLY `tracker-provider-gh.sh:201` (the `_gh_owner_repo`
  fallback, GH_REPO-unset-gated, via `_gh_run`) and `tracker-migrate-reverse.sh:421`
  (the best-effort `[]`-contract fallback arm, GH_REPO-unset/no-slash-gated). Both are
  the fixed patterns. `tracker-bd204-lossless-roundtrip-test.sh:773` passes an explicit
  repo argument (not argument-less) — out of scope and correct.
- Verbatim-GH_REPO owner/name splits: only `tracker-migrate-reverse.sh:416-419` (now
  stripped) and the helper itself. No other consumer reads `GH_REPO` for splitting in
  any tracker lib (`tracker-config.sh` occurrences are the exporter; test files are
  harness).
- Five-site claim: exactly 5 swap hunks in the diff; exactly 2 `_gh_owner_repo` call
  patterns existed for the mutation check's uniqueness assertion at the link/unlink
  sites plus 3 sub-issue sites — consistent.

### 3.5 Verification, manifest, scope, comment-only claim

- **Full CI battery (rule 6):** every step of `.github/workflows/validate-pack.yml`
  (read in full, 297 lines) run locally in workflow order via `/tmp/bd204-review3-battery.sh`,
  log `/tmp/bd204-review3-battery.log`: `grep -c "^STEP"` → **58**;
  `grep "^STEP" | grep -v "rc=0$"` → **empty** (58/58 rc=0). Includes
  `validate-pack.py` plain + `PACK_VALIDATE_DEEP=1`; all tracker suites; all per-check
  suites; migrator suites; `test-fixtures/build.sh --all --clean` + `--verify`;
  `test-v11-realistic-ot.sh`; migrator-skills; persona contracts; template suites;
  issue-forms. Directly-affected suites: provider **Passed: 156 / Failed: 0**, reverse
  **Passed: 139 / Failed: 0** (matches the FIX2 IMPL-REPORT claims). Workflow step (a2)
  `git checkout HEAD -- manifest.txt` substituted (git-state-changing verb forbidden)
  with `git diff --quiet -- test-fixtures/manifest.txt` → rc=0 post-rebuild (restore is
  a no-op by construction), then `--verify` rc=0 against the committed manifest.
- **Live oracle:** `env -u PACK_TRACKER_LIVE_GH bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
  → `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0. Zero
  live GitHub calls made this session.
- **Manifest (rule 7):** trigger fired (`scripts/` in diff); post-`--all --clean`
  rebuild, `git diff test-fixtures/manifest.txt` EMPTY — tracker libs/tests are not
  client-installed fixture content; the working tree's committed manifest is correct
  as-is; no staging needed. The empty-diff claim in the IMPL reports is verified.
- **pack-only (rule 8):** end-state `git status --porcelain` = the 4 ` M scripts/...`
  rows + the 5 named `??` reports (+ this report after its Write). No
  `project-template/` or `supporting-docs/` path anywhere in the diff — BD-204's HARD
  constraint holds.
- **FIX2 comment-only claim independently verified:** `git diff -U0` over both lib
  files filtered to non-comment changed lines yields EXACTLY the `_gh_owner_repo` body,
  the five call-site swaps, and the reverse-lib 3-line `case` strip — i.e., the
  pass-1/pass-2 code footprint; pass 3 (FIX2) contributed `#`-comment lines only. The
  probe matrix (§3.1) matches FIX2's recorded matrix byte-for-byte in classification.

### 3.6 Standing-checklist sweep

- **Trinity rule:** N/A — no trinity file touched.
- **Cross-reference integrity:** grepped `_gh_owner_repo` and `gh repo view`
  repo-wide. One stale comment found (NIT-1, §2). Remaining `gh repo view` doc
  references are historical workflow artifacts (archive/, BD-204 cycle reports,
  PACK-REVIEW-BD-111) — point-in-time records, no update obligation — or live
  auth-verification guidance (`pack-ops/OPTIONAL-FEATURES.md:186`,
  `project-template/docs/pack/OPTIONAL-FEATURES.md:151`,
  `supporting-docs/DEPENDENCIES.md:149`) that remains correct advice (verifies gh
  auth/reachability; not lib slug-resolution).
- **Maintenance-docs consistency:** no prescriptive design record encodes the old
  five-site idiom as a decision; BD-129's resolved backlog entry is historical.
- **validate-pack.py alignment:** no new files/dirs added to validated surfaces; new
  test legs live inside already-CI-wired suites (both named in `validate-pack.yml`
  steps). Check 42 (workflow wires per-check test files) green in battery.
- **Migration safety:** pack-side tracker machinery only; not client-installed; no
  MIGRATION/QUICKSTART impact.
- **README layout:** no files added/moved/removed (cycle reports are workflow
  artifacts, exempt during active development; swept at version ship).
- **BACKLOG accuracy:** BD-204 (`backlog/BD-204.md`) is `Status: Open` and this is
  mid-BD rehearsal-surfaced lib work — no status flip due; the entry's
  REHEARSAL-CONFIRMATION dated note concerns the separate re-close question and is
  unaffected.

## 4. Read-in-full attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `CLAUDE.md` (pack root) incl. full `## Pack memory` section | full (Read tool, in addition to context copy) | 579 (wc -l) |
| `backlog/BD-129.md` | full | 9 (wc -l) |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | full | 42 (wc -l) |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | full | 14 (wc -l) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ) | section | lines 196-235 |
| `.github/workflows/validate-pack.yml` | full | 297 |

Scoped code reads: `_gh_owner_repo` + docstring + all five call sites
(`tracker-provider-gh.sh` lines 1-230, 700-810); `_tmr_fetch_first_class_blocked_by`
(`tracker-migrate-reverse.sh` lines 380-469); `tracker_gh_repo_setup` slug contract
(`tracker-config.sh` lines 215-294); `tracker_error_emit` (`tracker-errors.sh` lines
30-79); full diffs of all four changed files; the three IMPL/FIX reports (inventory
cross-check); the new/changed test legs in both suites plus surrounding harness
(`tracker-provider-test.sh` lines 100-174, `tracker-migrate-reverse-test.sh` lines
920-1002). Prior `PACK-REVIEW-*.md` files NOT read.

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session (complete list): `status --porcelain` x2, `diff` / `diff --stat` / `diff --name-only` / `diff -U0` / `diff --quiet -- test-fixtures/manifest.txt` (incl. battery step), `rev-parse HEAD` x2 — all read-only. Workflow step (a2) `git checkout` NOT run; substituted with `git diff --quiet` → rc=0 (§3.5). No add/commit/push/tag/stash/reset/restore/checkout in any form. HEAD before = after = `1068c74a90b96fe78c48f73b818ed777c4deb873`. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op on repo paths: mutation checks ran in `/tmp/bd204-mutation` + `/tmp/bd204-mut2` COPIES (rm -rf confined to those /tmp dirs + a /tmp probe dir); no `git rm`; no overwrite of any tracked/trusted file (this report is NEW at the prompted path). End-state `git status --porcelain` tracked rows identical to session start (§1). | COMPLIANT |
| preflight-stop-means-stop | Emitted exactly one line immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1068c74a90b96fe78c48f73b818ed777c4deb873; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION-REVIEW3.md`. No parent stop/halt/revert message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted measurements; format per `pack-ops/PACK-MEMORY-RATIONALE.md:227-233` (conditional MUST-READ section read this session, §4 attestation). No empty-evidence rows; no AMBIGUOUS conclusions. | COMPLIANT |
| agents-read-rule-docs-in-full | §4 attestation: all 4 prompt-named files read IN FULL with wc -l counts (579 / 9 / 42 / 14) + the triggered rationale section + the workflow (297) + all prompt-named code regions (helper, five sites, `_tmr_fetch_first_class_blocked_by`, `tracker_gh_repo_setup`). Prior reviews not read per prompt. | COMPLIANT |
| verify-full-ci-suite | §3.5: log `/tmp/bd204-review3-battery.log`: `grep -c "^STEP"` → 58; `grep "^STEP" \| grep -v "rc=0$"` → empty. `validate-pack.py` rc=0 plain + DEEP; provider `Passed: 156 / Failed: 0`; reverse `Passed: 139 / Failed: 0`; integration `test-v11-realistic-ot.sh` rc=0; fixtures build + verify rc=0; live oracle `SKIP: live-GH oracle ...` rc=0 under `env -u PACK_TRACKER_LIVE_GH`. Zero live GitHub calls. | COMPLIANT |
| regenerate-manifest-v11-surface | Trigger fired (`scripts/` in diff); battery ran `build.sh --all --clean` rc=0; post-rebuild `git diff --quiet -- test-fixtures/manifest.txt` → rc=0 ("manifest diff EMPTY") + `build.sh --verify` rc=0 — empty-manifest-diff claim VERIFIED; no staging needed. | COMPLIANT |
| pack-only | End-state `git status --porcelain` (quoted §1): exactly 4 ` M scripts/...` rows + 5 pre-existing `??` BD-204 reports (+ this report). `git diff --name-only` = the four expected `scripts/` files. Zero `project-template/` / `supporting-docs/` paths. | COMPLIANT |
| scope-deliverables-to-the-ask | One finding filed (NIT-1, §2), a real staleness created by this change's semantics, with file:line anchor + rationale + no-behavioral-exposure analysis. Clean areas reported as checked (§3), no speculative redesign requests, no out-of-ask demands. Deliverable = this report only. | COMPLIANT |
