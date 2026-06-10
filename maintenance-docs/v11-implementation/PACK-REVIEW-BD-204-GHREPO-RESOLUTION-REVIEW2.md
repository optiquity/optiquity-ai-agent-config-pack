# PACK-REVIEW — BD-204 GH_REPO resolution fix, reviewer pass 2 (fresh)

- **Date:** 2026-06-10
- **Branch:** `v11-dev`
- **HEAD (uncommitted working-tree diff reviewed):** `1068c74a90b96fe78c48f73b818ed777c4deb873`
- **Reviewer:** fresh pack-reviewer instance (pass 2 of the bounded review/fix cycle)
- **Scope:** the ENTIRE uncommitted change (`git diff` vs HEAD), every hunk and the
  resulting state, on its own merits. Prior `PACK-REVIEW-*.md` NOT read (its
  existence as an untracked file was confirmed via `git status` only).

## Verdict

**APPROVE-WITH-FIXES** — the change is functionally commit-ready: helper and
guard behavior are correct at all five sites, the reverse-path strip is correct
and contract-preserving, coverage genuinely pins the fixed behaviors, the
completeness sweep is clean, and the full CI battery is green (57/57 steps
rc=0). Two NIT-level findings, both comment-accuracy only (no behavior defect),
surfaced for standard fix-or-defer triage. No BLOCKER / MUST / SHOULD findings.

## 1. Footprint verification

`git status --porcelain` + `git diff --name-only` at HEAD `1068c74`:

```
 M scripts/lib/tracker-migrate-reverse.sh
 M scripts/lib/tracker-provider-gh.sh
 M scripts/tests/tracker-migrate-reverse-test.sh
 M scripts/tests/tracker-provider-test.sh
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION-FIX1.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION.md
```

Exactly the expected four modified `scripts/` files + the three named untracked
reports (+ this report). `git diff --stat`: 4 files, 330 insertions(+), 12
deletions(-) — matches the FIX1 report's cumulative inventory.

## 2. Helper + guard correctness (`_gh_owner_repo`, five sites) — CLEAN

**Resolution order** (`scripts/lib/tracker-provider-gh.sh:166-201`): (1)
`tracker_gh_repo_setup` guard — identical `declare -f` idiom `_gh_run` uses at
lines 116-118, so GH_REPO is exported from the active `tracker.toml`'s
`backend.repo` when a config is in scope; setup itself (verified at
`scripts/lib/tracker-config.sh:252-283`) is a no-op when GH_REPO is pre-set and
exports only canonical `[HOST/]OWNER/REPO` (F4 shape validation, no `://`, no
whitespace, ≥1 slash). (2) GH_REPO-preferred with HOST/-strip (`case */*/*` →
`${slug#*/}` — strips exactly one leading segment only when ≥2 slashes
present). (3) `gh repo view` fallback via `_gh_run` ONLY when GH_REPO
unset/empty (rc≠0 classified by `_gh_classify_error`; rc=0-but-empty gets its
own typed validation error naming both remedies). Fail-loud both arms; no
silent fallback past a caller-supplied value.

**Five call sites** — all replaced with `owner_repo=$(_gh_owner_repo) || return 1`
(verified by grep on the resulting file): `tracker_provider_gh_link` (line 595),
`tracker_provider_gh_unlink` (line 680), `tracker_provider_gh_sub_issue_create`
(line 738), `tracker_provider_gh_sub_issue_list` (line 758),
`tracker_provider_gh_sub_issue_unlink` (line 778). REST consumers
(`/repos/$owner_repo/issues/N`) and the GraphQL owner/name `cut -d/` split
(lines 759-760, sub_issue_list) all receive bare `OWNER/REPO` post-strip.

**Shape guard truth table** — verified empirically by sourcing the lib in a
sandboxed subshell and probing (actual output):

```
GH_REPO=[owner/repo]                  -> rc=0 out=[owner/repo]
GH_REPO=[github.example.com/owner/repo] -> rc=0 out=[owner/repo]
GH_REPO=[a/b/c/d]                     -> rc=1 out=[]   (typed validation)
GH_REPO=[owner/repo/]                 -> rc=1 out=[]   (typed validation)
GH_REPO=[/owner/repo]                 -> rc=0 out=[owner/repo]  ← see NIT-1
GH_REPO=[owner]                       -> rc=1 out=[]   (typed validation)
GH_REPO=[host//repo]                  -> rc=1 out=[]   (typed validation)
GH_REPO=[/owner]                      -> rc=1 out=[]   (typed validation)
```

No legitimate canonical shape is rejected; every degenerate shape either fails
loud via the typed `tracker_error_emit "validation"` arm (which prints to
stderr and the helper then `return 1`s — verified against
`scripts/lib/tracker-errors.sh:49-52`) or — in the single leading-slash case —
is silently normalized to a VALID bare slug (behavior is benign; the comment
overstates, see NIT-1). The error message names the original `$GH_REPO`, not
the stripped value — good diagnosability. bash-3.2-safe constructs only
(`local`, `case`, `${var%%/*}`, `${var#*/}`).

## 3. Reverse-path strip (`_tmr_fetch_first_class_blocked_by`) — CLEAN

`scripts/lib/tracker-migrate-reverse.sh:399-427`: the GH_REPO-preferred branch
(gated on `-n` AND `== */*`) now strips the optional HOST/ prefix with the same
`case */*/*` idiom before the `cut -d/ -f1/-f2` split at lines 428-429 — so
`github.example.com/owner/repo` yields `owner`/`repo` and plain `owner/repo`
passes through untouched (one-slash values never match `*/*/*`).

**Best-effort `[]` contract preserved** — verified by tracing every path: no
new failure exit was added. A slash-less GH_REPO falls to the pre-existing
`gh repo view` fallback (whose failure → `[]`); a degenerate post-strip value
(e.g. `b/c/d` from `a/b/c/d`, or `repo/` from `owner/repo/`) flows into a
GraphQL `repository(owner:, name:)` lookup that fails → swallowed by the
`provider_raw` error branch at line 438 → `[]`. The function cannot abort the
reverse run on any input. Consistency with provider-side semantics is the
designed asymmetry: mutation paths (provider) fail loud; the reverse decoder
degrades — both sides now strip HOST/ identically. The inline-strip-not-
cross-lib-call decision is sound: `_gh_owner_repo` is a private helper of
`tracker-provider-gh.sh` and its fail-loud contract would BREAK the reverse
function's best-effort contract if imported. One comment nuance: see NIT-2.

## 4. Coverage adequacy — CLEAN (assertions inspected directly)

**Kill switch** (`tracker-provider-test.sh:110-119`): `FAKE_GH_REPO_VIEW_FAIL`
fires on any `repo` argv AFTER the `FAKE_GH_LOG` append — so a regression that
re-consults `gh repo view` is BOTH visible in the log (fails the negative
grep assertion) AND fatal to the chain (rc=1 fails the `rc=0` and JSON-shape
assertions). The legs genuinely bite; this is not friendly-stub theater. The
emitted stderr is the verbatim live-rehearsal error string.

**New provider legs** (29 assertions, 127 → 156): 1.17f (link via GH_REPO,
repo-view dead, 5 asserts incl. negative log grep + REST-slug + mutation name),
1.17g (host-prefix strip in REST path + `/repos/github.com/` negative), 1.17h
(shape guard: `a/b/c/d` and `optiquity/pack/` → rc=1 + typed message, with the
kill switch still armed so a silent fallback would also fail), 1.20d (unlink/
removeBlockedBy mirror of 1.17f), 1.21b (sub_issue_create GraphQL path with
extension cache pinned `_GH_SUB_ISSUE_EXT_CACHED="no"` — variable name verified
against lib lines 47-56), 1.21c (sub_issue_list owner/name SPLIT: asserts
`owner=optiquity` + `repo=pack` + negative `owner=github.com` — matches the
real `-F owner=... -F repo=...` argv shape at lib line 762), 1.21d
(sub_issue_unlink, fifth site). All 29 enumerated PASS in my independent run.

**New reverse leg** (6 assertions, 133 → 139): 7.3b's fake DIES on `repo view`
(proves GH_REPO supplied the slug, not the fallback) and asserts the logged
GraphQL query carries `owner: "fixture-org"` / `name: "fixture-repo"` with a
negative `owner: "github.example.com"` — these assertions fail by construction
if the strip is reverted (consistent with the FIX1 mutation-check claim of
3 failures on revert; I verified the assertion logic directly rather than
re-running the mutation). The plain `owner/repo` second invocation pins
no-strip-on-one-slash. `assert_not_contains` exists in this suite's harness
(line 27). `G7_FIXTURE` points into the persistent fixtures dir (line 931),
not the removed temp dirs — no dangling reference.

**Environment independence:** suite-level `unset GH_REPO` before sourcing
(provider suite line 177); `reset_fake_gh` scrubs `GH_REPO` +
`FAKE_GH_REPO_VIEW_FAIL` (line 193-196); each new leg unsets its exports;
7.3 already had `unset GH_REPO` and 7.3b unsets before 7.4. The harness uses
`set -u` (no `set -e`), so the `rc=$?`-after-assignment captures in 1.17f/g/h,
1.20d, 1.21b/c/d are valid. I also surveyed the OTHER suites that stub
`repo view` without scrubbing GH_REPO (`tracker-agent-read`, `bd132`, `bd134`,
`tracker-migrate-forward`, `tracker-migrate-roundtrip`): their fakes dispatch
on wildcard patterns (`/repos/*/issues/*`) and their assertions are
slug-agnostic (mutation names, marker lines, call counts — e.g. forward suite
6.1-6.4), so no ambient-GH_REPO-sensitive assertion exists outside the suites
that scrub. CI runners do not set GH_REPO (Actions sets `GITHUB_REPOSITORY`).

**No coverage deleted:** 1.17a / 1.20a `repo view` log assertions are retained
and relabeled `(GH_REPO-unset fallback)`; chain comments updated to document
the fallback-vs-preferred split. All pre-existing assertions still present.

## 5. Completeness sweep — CLEAN

Greps run by me across `scripts/lib/` + `scripts/*.sh` on the resulting tree:

- `grep -rn "repo view"` → exactly TWO executable sites remain:
  `tracker-provider-gh.sh:194` (the helper's own documented fallback, gated on
  GH_REPO unset) and `tracker-migrate-reverse.sh:419` (the reverse decoder's
  best-effort fallback, gated on GH_REPO unset-or-slash-less). All other hits
  are comments. Zero ungated argument-less slug resolutions.
- `grep -rn "nameWithOwner"` (non-test) → same two sites only.
- `grep -rn 'cut -d/'` in libs → two split pairs only: provider sub_issue_list
  (lines 759-760, fed by `_gh_owner_repo`, post-strip) and reverse fetch
  (lines 428-429, fed by the inline strip or the bare `nameWithOwner`
  fallback). No verbatim-GH_REPO owner/name split remains anywhere.
- Other `GH_REPO` consumers (`tracker-labels.sh`, `tracker-promote.sh`) route
  through `tracker_gh_repo_setup` + gh's own env handling (BD-129 pattern,
  no self-resolution) — unaffected and correct.

## 6. Report hygiene — CLEAN

Base IMPL-REPORT §4 (`IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md:74-78`) now
labels the grep block: "The grep block below is ANNOTATED, not verbatim (review
F-3 correction): the trailing `# link (was ~524)`-style comments were added in
this report ... line numbers are as of this pass (pre-review-fix)". I verified
the underlying claim against the file: the actual call-site lines ARE bare and
identical at all five sites. The annotation is now honest. (The §4 line
numbers, e.g. "line 183", have drifted to 194 post-FIX1; the "as of this pass
(pre-review-fix)" label covers this explicitly — acceptable as a dated record.)

## 7. Verification + scope — ALL GREEN

**Full CI battery** (every step of `.github/workflows/validate-pack.yml`, run
locally by me in workflow order; log `/tmp/bd204-review2-battery.log`):
**57/57 STEP rows rc=0**; `grep "^STEP" | grep -v "rc=0$"` → empty. Includes:
`validate-pack.py` rc=0 plain AND `PACK_VALIDATE_DEEP=1`; provider **156/156**;
reverse **139/139**; forward / roundtrip / phase-task / links / cycle-check /
errors / all per-check suites rc=0; `test-fixtures/build.sh --all --clean`
rc=0; `test-v11-realistic-ot.sh` integration rc=0; migrator-* / persona /
template-* / issue-forms rc=0. The workflow's `git checkout HEAD --
test-fixtures/manifest.txt` restore step (a2) was NOT run — git-state-changing
verbs are forbidden to this agent; substituted with the equivalence proof
`git diff --quiet -- test-fixtures/manifest.txt` → rc=0 post-rebuild (rebuilt
manifest byte-identical to committed, so the restore is a no-op by
construction), then `build.sh --verify` rc=0 (all rows OK).

**Manifest claim** (rule 7): trigger fired (`scripts/` in diff); rebuild run;
`git diff` on the manifest empty → the IMPL reports' "no staging needed" claim
is correct (lib/test files are not fixture-affecting; the sanctioned shipped
set is exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}`).

**Live-oracle** stayed default-SKIP: `env -u PACK_TRACKER_LIVE_GH bash
scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` → `SKIP: live-GH
oracle ...`, rc=0. Zero live GitHub calls made during this review.

**pack-only** (rule 8): diff touches only the four `scripts/` files; untracked
additions only the three named reports + this one; zero `project-template/` or
`supporting-docs/` paths. The proposed commit subject's `(pack-only)` keyword
will pass CI Check 36.

## 8. Findings

### NIT-1 — guard comment overstates the leading-slash rejection
`scripts/lib/tracker-provider-gh.sh:177-182` (F-4 guard comment: "Degenerate
shapes (slash-less; >=3 slashes pre-strip, e.g. a/b/c/d; trailing or leading
slash) fail loud here") and the helper docstring at lines 155-159. Empirically
(probe in §2), `GH_REPO=/owner/repo` does NOT fail loud: the leading empty
segment matches `*/*/*`, is stripped as a zero-length "HOST", and the result
`owner/repo` passes the guard (rc=0). The BEHAVIOR is acceptable — the
normalized output is a valid bare slug, nothing malformed passes through, and
no legitimate shape is rejected — but the comment claims a rejection that does
not happen. Recommended action (smallest honest edit): correct the comment to
say a leading slash is stripped as an empty HOST segment and accepted (or, if
strict rejection is preferred, add `|| "$GH_REPO" == /*` to the guard plus one
test assertion — either resolution is fine; the comment fix is minimal).
`/owner` and `//repo`-class inputs DO fail loud as documented.

### NIT-2 — reverse-lib comment names the wrong degradation mechanism
`scripts/lib/tracker-migrate-reverse.sh:411-413`: "a still-degenerate value
falls through to the existing [] guard below and never aborts the reverse
run." The "never aborts / degrades to []" half is true and verified, but a
post-strip degenerate value can never actually hit the line-424
`[[ -z ... || != */* ]]` guard (stripping a ≥2-slash value always leaves ≥1
slash and a non-empty string); the real degradation path is the GraphQL
NOT_FOUND → swallowed `provider_raw` failure → `[]` at line 438-441.
Recommended action: reword to "degrades via the GraphQL-failure `[]` path
below" (one-line comment edit). No behavior change needed.

### Process observation (not a new finding)
The base pass's accidental `git stash` + `git stash pop` is disclosed as a
VIOLATED row in the base IMPL-REPORT and was dispositioned at pass-1 triage
(F-2, no action). Current state verified clean: `git stash list` → empty,
HEAD unchanged at `1068c74`. Nothing further required from this pass.

## 9. What was checked (clean areas, for the record)

- Helper resolution order, setup-guard parity with `_gh_run`, typed-error arms,
  and `tracker_error_emit` stderr/rc semantics — clean (§2).
- All five call sites + their REST/GraphQL consumers receive bare OWNER/REPO —
  clean (§2).
- Reverse-path strip + best-effort contract traced on every input class —
  clean (§3).
- Kill-switch ordering (log-then-die), all 35 new assertions inspected for
  genuine pinning, harness rc-capture validity under `set -u`, fixture/`log`
  variable scoping in 1.17/1.20/1.21 blocks and 7.3b, cross-suite ambient-
  GH_REPO exposure — clean (§4).
- Repo-wide completeness greps — clean (§5).
- IMPL-report honesty (§4 annotation label; suite-count arithmetic 127→156 =
  +29 and 133→139 = +6 both reconcile with the assertion inventory) — clean.
- No new deferral comments introduced (no untyped TODO/FIXME in the diff);
  POQ-BD204-GHREPO-1 from the base pass is genuinely resolved by F-1 (no
  dangling anchor needed).
- bash-3.2/BSD compatibility of all new constructs — clean.

## 10. Read-in-full attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `CLAUDE.md` (pack root, incl. full `## Pack memory` section) | full | 579 (wc -l) |
| `backlog/BD-129.md` | full | 9 (wc -l; 10 display lines via Read) |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | full | 42 (wc -l) |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | full | 14 (wc -l) |
| `.claude/skills/review/SKILL.md` | full | 74 |
| `.claude/skills/architecture-review/SKILL.md` | full | 48 |
| `.claude/skills/commit-discipline/SKILL.md` | full | 174 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ) | section | lines 196-240 |

Section reads (prompt-named): `_gh_owner_repo` + `_gh_run` + all five call
sites + sub-issue ops + `_gh_has_sub_issue_extension`
(`tracker-provider-gh.sh` lines 100-209, 580-700 via grep anchors, 700-810);
`_tmr_fetch_first_class_blocked_by` + caller (`tracker-migrate-reverse.sh`
lines 370-459); `tracker_gh_repo_setup` slug contract (`tracker-config.sh`
lines 217-283); `tracker_error_emit` (`tracker-errors.sh:49-52`); the full
working-tree `git diff`; both IMPL reports (full, 339 + 295 lines);
`.github/workflows/validate-pack.yml` (full, 297 lines);
`tracker-provider-test.sh` lines 1-230 + 356-525 + 526-746;
`tracker-migrate-reverse-test.sh` lines 880-1046 region + harness greps.
The prior `PACK-REVIEW-BD-204-GHREPO-RESOLUTION.md` was NOT read.

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session (complete list): `rev-parse HEAD` ×2, `status --porcelain` ×2, `diff` / `diff --stat` / `diff --name-only` / `diff --quiet -- test-fixtures/manifest.txt`, `stash list` (read-only listing, empty), `log` (none needed beyond status snapshot) — all read-only. The CI workflow's `git checkout HEAD -- test-fixtures/manifest.txt` step was NOT run; substituted with `git diff --quiet -- test-fixtures/manifest.txt` → rc=0 (§7). HEAD before = after = `1068c74a90b96fe78c48f73b818ed777c4deb873`. No add/commit/push/tag/stash/reset/restore/checkout executed. Output = this report file only. | COMPLIANT |
| per-action-approval-sub-agents | No destructive operation executed: no `rm -rf` on repo paths (battery scratch confined to `/tmp/bd204-review2-battery.log` + the harness's own self-created mktemp dirs cleaned by the test scripts' own traps), no `git rm`, no file overwrite (this report is a NEW file at the prompted path). Repo content untouched — `git status --porcelain` before = after (same 4 ` M` + 3 `??` rows, §1). | COMPLIANT |
| preflight-stop-means-stop | Emitted exactly one line immediately before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 1068c74a90b96fe78c48f73b818ed777c4deb873; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION-REVIEW2.md`. No parent stop/halt/revert message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted measurements; format per `pack-ops/PACK-MEMORY-RATIONALE.md:227-233` (conditional MUST-READ section read this session, §10 row 8). No empty-evidence rows; no AMBIGUOUS conclusions. | COMPLIANT |
| agents-read-rule-docs-in-full | §10 attestation: 4 prompt-named files read IN FULL with line counts (579 / 9 / 42 / 14 by wc -l) + 3 skills (74 / 48 / 174) + the triggered rationale section + all prompt-named code symbols (`_gh_owner_repo` + five sites, `_tmr_fetch_first_class_blocked_by`, `tracker_gh_repo_setup`). No named doc derived instead of read (CLAUDE.md re-read via Read tool despite being present in context). Prior review report NOT read per prompt. | COMPLIANT |
| verify-full-ci-suite | §7: every `.github/workflows/validate-pack.yml` step run locally in workflow order; log `/tmp/bd204-review2-battery.log`: `grep -c "^STEP"` → 57; `grep "^STEP" \| grep -v "rc=0$"` → empty. `validate-pack.py` rc=0 plain + DEEP; provider 156/156 + reverse 139/139 (independent runs, summaries quoted §7); integration `test-v11-realistic-ot.sh` rc=0; fixtures build + verify rc=0. Live oracle: `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` rc=0 under `env -u PACK_TRACKER_LIVE_GH`. Zero live GitHub calls. | COMPLIANT |
| regenerate-manifest-v11-surface | Trigger fired (`scripts/` in diff); `bash test-fixtures/build.sh --all --clean` rc=0 (battery step `fixtures-build`); post-rebuild `git diff --quiet -- test-fixtures/manifest.txt` → rc=0 (empty diff, §7); `build.sh --verify` rc=0. Empty-diff claim in both IMPL reports independently CONFIRMED — no staging needed. | COMPLIANT |
| pack-only (BD-204 HARD constraint) | `git diff --name-only` → exactly `scripts/lib/tracker-migrate-reverse.sh`, `scripts/lib/tracker-provider-gh.sh`, `scripts/tests/tracker-migrate-reverse-test.sh`, `scripts/tests/tracker-provider-test.sh` (§1, quoted). `git status --porcelain` untracked rows: the 3 named `maintenance-docs/` reports + this report. Zero `project-template/` or `supporting-docs/` paths. Check 36 pack-only deny-list satisfied. | COMPLIANT |
| scope-deliverables-to-the-ask | Findings limited to two real comment-accuracy defects in the change (NIT-1 empirically demonstrated by probe output; NIT-2 by path-tracing); no forward-looking conjecture, no design ratification, no carry-forwards (none qualified — both NITs are fix-now-sized). Clean areas reported as one-line confirmations (§9), not expanded. Single deliverable at the prompted path. | COMPLIANT |
