# IMPL-REPORT — BD-204 close-reason fix, fix-coder pass 1 (MUST-1 + NIT-1)

- **Coder:** fresh fix-coder, pass 1 of the bounded review/fix cycle
  (recovery: prior instance died on a server-side API error mid-work)
- **Branch / HEAD:** v11-dev @ `84f6a83d02d8467362972b86d1eb642dec9f4177`
  (`git rev-parse HEAD`; all work is uncommitted working-tree state)
- **Date:** 2026-06-11
- **Findings fixed:** PACK-REVIEW-BD-204-CLOSE-REASON-FIX.md MUST-1 + NIT-1

## Summary

Both findings are now COMPLETE. The prior instance got further than the
spawn-state described: MUST-1's comment rewrite was in place and accurate,
and NIT-1's `-r` parsing was ALREADY present at every guard site (the
spawn-state's "forward-test and bd134 stubs do not have `-r`" did not match
the tree I found — verified empirically, see §3). My own contribution is
one targeted edit (MUST-1 symbol-name precision) plus full verification of
the inherited state.

## 1. Per-finding inherited-vs-completed accounting

| Finding | Inherited (prior instance) | Done by me |
|---|---|---|
| MUST-1 comment rewrite | The `"repo view")` arm comment in `scripts/tests/tracker-migrate-roundtrip-test.sh` was already rewritten to describe `_gh_owner_repo` (GH_REPO-preferred, HOST/-strip + post-strip shape guard, `gh repo view` fallback only when GH_REPO unset) — substantively accurate against source | Verified every claim against `scripts/lib/tracker-provider-gh.sh` + `scripts/lib/tracker-migrate-reverse.sh`; corrected two abbreviated caller names that were not real symbols (one targeted Edit, §2) |
| NIT-1 `-r` alias in hardened close stubs | ALL guard sites already parse `--reason` AND `-r` with identical vocabulary enforcement | Empirical enumeration of every `issue close` arm across the 4 files (13 arms: 11 guarded, 2 always-fail exempt); block-by-block consistency inspection; no edits needed |

## 2. MUST-1 — verification + the one correction

**Accuracy verification of the inherited rewrite** (every claim checked
against source this session):

- `_gh_owner_repo` exists at `scripts/lib/tracker-provider-gh.sh`
  (helper defined with docstring; BD-204 resolution-order steps 1-4).
- PREFERS `${GH_REPO}`: confirmed — `local slug="${GH_REPO:-}"` taken
  first; `*/*/*) slug="${slug#*/}"` HOST/-strip; post-strip shape guard
  (BD-204 review F-4) rejects degenerate slugs with a typed validation
  error.
- `gh repo view` fallback ONLY when GH_REPO unset/empty: confirmed —
  `slug=$(_gh_run gh repo view --json nameWithOwner --jq '.nameWithOwner')`
  is reached only after the `[[ -n "$slug" ]]` branch returns.
- Callers: `grep -n "_gh_owner_repo" scripts/lib/tracker-provider-gh.sh`
  → call sites at :621, :742, :800, :820, :840, which sit inside
  `tracker_provider_gh_link` (:605), `tracker_provider_gh_unlink` (:719),
  `tracker_provider_gh_sub_issue_create` (:778),
  `tracker_provider_gh_sub_issue_list` (:810),
  `tracker_provider_gh_sub_issue_unlink` (:829). All five callers named
  in the comment are real and complete.
- `_tmr_fetch_first_class_blocked_by` mirrors the GH_REPO-preferred order
  inline: confirmed at `scripts/lib/tracker-migrate-reverse.sh` (:390
  function; :399 GH_REPO-preferred branch; :421 `gh repo view` fallback;
  in-comment note that it is deliberately inline rather than a cross-lib
  call to `_gh_owner_repo`).
- No line-number refs anywhere in the comment (file + symbol names only).

**The one defect found in the inherited rewrite:** the caller list used
abbreviated names `_sub_issue_list` / `_sub_issue_unlink`, which are NOT
real symbols (the real functions are `tracker_provider_gh_sub_issue_list`
/ `tracker_provider_gh_sub_issue_unlink`); an exact-grep for the comment's
names would find nothing. Corrected with one targeted Edit.

**Before** (`scripts/tests/tracker-migrate-roundtrip-test.sh`, `"repo
view")` arm comment, 4 lines):

```
        # tracker_provider_gh_link / tracker_provider_gh_unlink /
        # tracker_provider_gh_sub_issue_create / _sub_issue_list /
        # _sub_issue_unlink), which PREFERS ${GH_REPO} (stripping an
        # optional HOST/ prefix, with a post-strip shape guard) and
```

**After** (6 lines; surrounding comment text byte-stable):

```
        # tracker_provider_gh_link / tracker_provider_gh_unlink /
        # tracker_provider_gh_sub_issue_create /
        # tracker_provider_gh_sub_issue_list /
        # tracker_provider_gh_sub_issue_unlink), which PREFERS
        # ${GH_REPO} (stripping an optional HOST/ prefix, with a
        # post-strip shape guard) and
```

Post-edit re-read of the full arm confirmed: comment flows correctly into
the unchanged `# runs `_gh_run gh repo view ...` ONLY as the GH_REPO-unset
fallback` continuation; `bash -n` clean.

### Anchor discharge (MUST-1)

The `/backlog/BD-204.md` dated note (2026-06-10, GH_REPO-resolution
review-3 NIT) — "stale BD-111-era comment in
`scripts/tests/tracker-migrate-roundtrip-test.sh` ... **Fix at the next
commit touching that file**" — is DISCHARGED by this fix pass: the stale
argument-less `gh repo view` description is replaced by an accurate,
verified description of the as-built `_gh_owner_repo` resolution, in the
same uncommitted change that touches the file. Pack Chat can mark the
BD-204 note satisfied when this commit lands (pack-chat-only bookkeeping;
not edited by me per scope).

## 3. NIT-1 — empirical enumeration of every close stub

Spawn-state said the roundtrip stub had `-r` but forward-test and bd134
did not. **Checked, not assumed:** `grep -n -- "--reason" <4 files>`
shows `-r` parsing present at EVERY guard site. Counts differ slightly
from both the prompt ("all 9") and the review ("1 + 9"): empirically
there are **11 vocabulary-guard sites + 2 always-fail stubs = 13
`issue close` arms** (the review under-counted forward-test at ×7; it
has 8 guarded arms). Full inventory, every block dumped and inspected
this session:

| # | File : guard line | Stub | `-r` parsed | Vocabulary enforcement |
|---|---|---|---|---|
| 1 | tracker-provider-test.sh:130 | provider fake (top-of-fake if-block) | YES | identical case-arm |
| 2 | tracker-migrate-forward-test.sh:541 | FAKEGH (4.3) | YES | identical case-arm |
| 3 | tracker-migrate-forward-test.sh:976 | FAKEGH_REC (quoted heredoc, literal `$`) | YES | identical case-arm |
| 4 | tracker-migrate-forward-test.sh:1136 | FAKEGH_CP | YES | identical case-arm |
| 5 | tracker-migrate-forward-test.sh:1373 | FAKEGH_C | YES | identical case-arm |
| 6 | tracker-migrate-forward-test.sh:1500 | FAKEGH_R1 | YES | identical case-arm |
| 7 | tracker-migrate-forward-test.sh:1588 | FAKEGH_R2 | YES | identical case-arm |
| 8 | tracker-migrate-forward-test.sh:1834 | FAKEGH_BD108 | YES | identical case-arm |
| 9 | tracker-migrate-forward-test.sh:2015 | FAKEGH_CR (Group 7) | YES | identical case-arm |
| 10 | tracker-migrate-roundtrip-test.sh:163 | roundtrip stateful fake (`--reason\|-r) reason="$2"`) | YES | identical case-arm |
| 11 | tracker-bd134-close-retry-test.sh:206 | bd134 transient (guard BEFORE transient simulation) | YES | identical case-arm |
| 12 | tracker-migrate-forward-test.sh:876 | FAKEGH_PF (always-fail: unconditional `HTTP 422` + `exit 1`) | EXEMPT | rejects everything by construction |
| 13 | tracker-bd134-close-retry-test.sh:271 | bd134 persistent (always-fail: unconditional `HTTP 503` + `exit 1`) | EXEMPT | rejects everything by construction |

"Identical case-arm" = each guard captures the value following `--reason`
OR `-r` and validates via the same
`completed|"not planned"|duplicate) ;; *) echo "fake-gh: invalid --reason
'<v>' (real gh vocabulary: {completed|not planned|duplicate})" >&2; exit 1`
pattern (heredoc-appropriate `\$` escaping verified per opener: unquoted
heredocs escape, the quoted `'FAKEGH_REC'` and the directly-written
roundtrip/provider/bd134 guards use literals). Negative sweep: no other
`issue close` arm exists in the 4 files (grep inventory above is
exhaustive). NIT-1 required no edits — inherited-complete, now verified.

## 4. Files changed (this fix pass)

| Path | Change type | Delta (mine) |
|---|---|---|
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified (already in BD-204 diff) | 4 lines → 6 lines in the `"repo view")` arm comment (+2 net) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX-FIX1.md` | new (this report) | — |

No other file edited by me. End-state `git status --porcelain` footprint
is IDENTICAL to spawn footprint plus this report: 7 ` M` files + 3 `??`
(coder IMPL-REPORT, review report, runtime `tracker.toml`) + this report.
Pack-Chat-owned C-8 runtime artifacts (`tracker.toml`, gitignored
`.pack-tracker/`) untouched.

## 5. Verification log (all FOREGROUND, this session)

| Step | Where | Result |
|---|---|---|
| `bash -n` ×5 (4 test files + tracker-provider-gh.sh) | real tree | all clean (incl. post-edit re-check of roundtrip test) |
| `tracker-provider-test.sh` | real tree | 160 passed / 0 failed, rc=0 |
| `tracker-migrate-forward-test.sh` | real tree | 190 passed / 0 failed, rc=0 |
| `tracker-migrate-roundtrip-test.sh` (post-edit) | real tree | 70 passed / 0 failed, rc=0 |
| `tracker-bd134-close-retry-test.sh` | real tree | 24 passed / 0 failed, rc=0 |
| `tracker-bd204-lossless-roundtrip-test.sh` unattended | real tree + isolated copy | pinned `SKIP: live-GH oracle` line, rc=0 both (live oracle default-SKIP; NOT run live; confirmed not a CI workflow step — `grep bd204 .github/workflows/validate-pack.yml` empty) |
| `python3 scripts/validate-pack.py` | real tree | rc=1 — EXACTLY 3 FAIL lines, all `tracker.toml — mirror file '{BACKLOG,STATUS,CHANGELOG}.md' ... does not exist on disk` = the known POQ-1 signature; zero issues from this change |
| `validate-pack.py` + `PACK_VALIDATE_DEEP=1` | isolated copy | both rc=0, `PASSED — all checks clean` |
| FULL CI battery — all 52 suite `run:` steps of `.github/workflows/validate-pack.yml` in CI order (detect, all tracker-*, all per-check validate-pack tests, bd129/130/132/133/134, recommendation, pack-help, customization-preserve, init-project, migrate ×4, migrator ×3, v11-realistic-ot, migrator-skills, persona-contracts, template ×2, issue-forms) | isolated copy `/tmp/bd204-fix1-checkout` WITHOUT root `tracker.toml`/`.pack-tracker/` | **ALL rc=0** (per-step `rc=0 :: <path>` lines captured in chunks A2/B2/C/D/E/F) |
| `build.sh --all --clean` → manifest diff → `--verify` | isolated copy | rc=0 → pre/post manifest `diff` rc=0 (EMPTY) → `--verify` rc=0 |
| Real-tree manifest | real tree | `git diff --quiet -- test-fixtures/manifest.txt` → EMPTY (read-only check) |
| Failure classification | both trees | the ONLY real-tree failure (`validate-pack.py` rc=1) maps 1:1 to the known 3-issue POQ-1 set; identical code in the artifact-free copy is fully green |

**Isolated-copy method notes (defects found and corrected in MY copy
provisioning, not in pack files):** (1) an unanchored rsync
`--exclude 'tracker.toml'` initially stripped the test-fixture
`tracker.toml` files (`scripts/tests/fixtures/*/tracker.toml`), causing
spurious forward/roundtrip failures — re-synced with root-anchored
`--exclude '/tracker.toml' --exclude '/.pack-tracker'` and re-ran the
ENTIRE battery from the top against the corrected copy (all results above
are from the corrected copy); (2) the repo is a git worktree (`.git` is a
gitdir pointer file) — the pointer was kept in the copy so `detect.sh`'s
read-only `git rev-parse` probes resolve, but NO git verb was run by me
inside the copy (the CI `git checkout HEAD -- manifest.txt` restore step
was replaced by the pre/post file `diff`, which is the same oracle).

## 6. Plan deviations

One, additive: the MUST-1 symbol-name correction (§2) — the inherited
rewrite was substantively accurate but cited two non-existent abbreviated
symbol names; the prompt's self-review constraint ("symbol names verified
against source") required the correction. No other deviation; NIT-1
needed zero edits.

## 7. New POQs

None introduced by this pass. POQ-1 (init writer `[mirror]`
surface-blindness) and POQ-2/POQ-3 (live `stateReason` shape /
decoder-token anchor) remain as dispositioned by the review — out of this
fix pass's scope by explicit prompt boundary.

## 8. Boundary discipline check

No project-side file (`project-template/`, `supporting-docs/`, or any
pack-shipped-to-client surface) touched by this pass — all edits are
pack-side test files under `scripts/tests/`. No boundary investigation
required; no pack-only reference introduced anywhere.

## 9. Definition of Done

| Item | Status |
|---|---|
| MUST-1: stale comment describes as-built `_gh_owner_repo` resolution, claims verified against source, no line-number refs | PASS |
| MUST-1: BD-204 dated-note anchor discharge documented (§2) | PASS |
| NIT-1: every hardened close stub parses `-r` with identical vocabulary enforcement; full enumeration with exempt stubs identified | PASS |
| Modified suites green in real tree (160/190/70/24, 0 failed) | PASS |
| Full CI battery green in isolated /tmp checkout (52 suites + validate + DEEP + fixtures build/diff/verify, all rc=0) | PASS |
| Real-tree validate-pack failures classified against known 3-issue POQ-1 set (exact match) | PASS |
| Manifest: rebuild run, diff EMPTY (isolated copy); real-tree manifest diff empty | PASS |
| End-state git footprint = spawn footprint + this report only | PASS |
| Untouched text byte-stable (targeted Edit only; post-edit re-read) | PASS |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs run this session: `rev-parse HEAD`, `status --porcelain`, `status`, `diff --stat`, `diff --quiet`, `rev-parse --git-dir` (read-only probe in copy) — all read-only. No add/commit/push/tag/stash/reset/restore/checkout anywhere; the CI manifest-restore step was replaced by a file `diff` in the copy. Output = working-tree edit (§4) + this report. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive op on trusted state: only self-provisioned `/tmp/bd204-fix1-checkout` + scratch logs were created/removed (`rm -rf /tmp/bd204-fix1-checkout ...` → "TMP CLEANED"); real-tree `tracker.toml` + `.pack-tracker/` untouched (end-state `git status --porcelain` = same 7 ` M` + 3 `??` + this report). | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted immediately before this Write: `PREFLIGHT: 2/2 fixes complete; verification PASS; HEAD 84f6a83d02d8467362972b86d1eb642dec9f4177; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX-FIX1.md`. No parent stop message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read this session (lines 206-233, format template followed). | COMPLIANT |
| 5. agents-read-rule-docs-in-full | Read IN FULL with line counts: `CLAUDE.md` `## Pack memory` section (lines 140-579 of 579; whole file also supplied verbatim in session context); `PACK-REVIEW-BD-204-CLOSE-REASON-FIX.md` (303 lines, full); `feedback_edit_in_place_not_full_rewrite.md` (15 lines); `feedback_verify_full_ci_suite.md` (43 lines); `feedback_agent_output_rules_applied_block.md` (15 lines); plus `PACK-MEMORY-RATIONALE.md` §206-233 per the conditional MUST-READ. | COMPLIANT |
| 6. verify-full-ci-suite | Real tree: 4 modified suites green (160/190/70/24, 0 failed). Isolated `/tmp/bd204-fix1-checkout` (no root tracker.toml/.pack-tracker): validate-pack rc=0, DEEP rc=0, ALL 52 workflow suite steps rc=0, fixtures build/diff/verify rc=0 — FOREGROUND in CI order (chunks A2/B2/C/D/E/F, per-step `rc=0 ::` lines). Live oracle: pinned SKIP rc=0 both trees, NOT run live. Real-tree failure classification: `validate-pack.py` rc=1 with EXACTLY the 3 `mirror file ... does not exist` FAILs = the known POQ-1 set; nothing else fails in the real tree's modified suites. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | `scripts/` touched → rebuild run: `bash test-fixtures/build.sh --all --clean` rc=0 in the isolated copy → pre/post `diff` of `test-fixtures/manifest.txt` rc=0 (EMPTY) → `--verify` rc=0 (`v11-tracker-on OK`, `existing-project-mid-dev OK` tail quoted in session). Real tree: `git diff --quiet -- test-fixtures/manifest.txt` → EMPTY. Reason verified by outcome: the edited files (`scripts/tests/*`, `scripts/lib/tracker-provider-gh.sh`) do not ship to fixtures, so no manifest row drifts; nothing to stage. | COMPLIANT |
| 8. edit-in-place-not-full-rewrite | Exactly ONE targeted Edit (old_string 4 lines → new_string 6 lines, §2); zero Write calls against pack files; post-edit re-read of the full `"repo view")` arm quoted in session confirms surrounding text byte-stable; `git diff --stat` for the file = `27 insertions(+), 5 deletions(-)` total uncommitted (inherited BD-204 + prior-instance + my +2). | COMPLIANT |
| 9. pack-only | End-state `git status --porcelain`: same 7 ` M` `scripts/` files + same 3 `??` as spawn, plus only this report. No `project-template/` or `supporting-docs/` path; C-8 runtime artifacts untouched. | COMPLIANT |
| 10. scope-deliverables-to-the-ask | Deliverables = MUST-1 completion (inherited-complete + one symbol-name correction by me) + NIT-1 completion (inherited-complete; verified by me, zero edits) + this report. Inherited-vs-done-by-me accounting in §1. No POQ-1/POQ-2 work, no other file touched. | COMPLIANT |

— end of fix report —
