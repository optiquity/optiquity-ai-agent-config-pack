# IMPL-REPORT — BD-204 GH_REPO resolution, fix-coder pass 2 (FINAL)

- **Date:** 2026-06-10
- **Branch:** `v11-dev`
- **HEAD (unchanged, working-tree-only change):** `1068c74a90b96fe78c48f73b818ed777c4deb873`
- **Coder:** fresh fix-coder instance (pass 2 of the bounded review/fix cycle)
- **Scope:** exactly the two user-approved comment-accuracy NITs from
  `PACK-REVIEW-BD-204-GHREPO-RESOLUTION-REVIEW2.md` (NIT-1, NIT-2).
  Comment text only; zero behavior diffs.

## 1. Per-finding fixes

### NIT-1 — `scripts/lib/tracker-provider-gh.sh` guard comment + docstring

**Behavior evidence (re-derived locally, sandboxed subshell sourcing the lib;
no live GitHub calls):**

```
GH_REPO=[owner/repo]                    -> rc=0 out=[owner/repo]
GH_REPO=[github.example.com/owner/repo] -> rc=0 out=[owner/repo]
GH_REPO=[/owner/repo]                   -> rc=0 out=[owner/repo]   <- silently normalized, NOT fail-loud
GH_REPO=[a/b/c/d]                       -> rc=1 out=[]
GH_REPO=[owner/repo/]                   -> rc=1 out=[]
GH_REPO=[owner]                         -> rc=1 out=[]
GH_REPO=[/owner]                        -> rc=1 out=[]
GH_REPO=[host//repo]                    -> rc=1 out=[]
```

`/owner/repo` matches `*/*/*` (the leading `*` matches empty), so `${slug#*/}`
strips the empty leading segment as a zero-length HOST and the remaining
`owner/repo` passes the post-strip guard. The old comment's "leading slash ...
fail loud" claim was false for the two-slash case. Identical probe output
before and after the edit (run both times this session) — zero behavior change.
Reviewer's primary recommendation taken: comment corrected, guard NOT tightened
(normalization is the intended, benign behavior).

**Edit 1a — guard comment (was lines 177-182). Before:**

```
        # Post-strip shape guard (BD-204 review F-4): accept exactly
        # OWNER/REPO — one slash, both segments non-empty. Degenerate
        # shapes (slash-less; >=3 slashes pre-strip, e.g. a/b/c/d;
        # trailing or leading slash) fail loud here with a typed
        # validation error instead of passing a malformed slug through
        # to the REST path / owner-name split.
```

**After (now lines 179-189):**

```
        # Post-strip shape guard (BD-204 review F-4): accept exactly
        # OWNER/REPO — one slash, both segments non-empty. Degenerate
        # shapes (slash-less; >=3 slashes pre-strip, e.g. a/b/c/d;
        # trailing slash; empty owner or repo segment post-strip,
        # e.g. /owner or host//repo) fail loud here with a typed
        # validation error instead of passing a malformed slug through
        # to the REST path / owner-name split. One benign exception:
        # a leading slash on a two-slash value (/owner/repo) is NOT
        # rejected — the empty leading segment is stripped above as a
        # zero-length HOST and the remaining valid OWNER/REPO is
        # accepted.
```

**Edit 1b — helper docstring (cited in NIT-1's location alongside the guard
comment; was lines 155-159). The enumerated degenerate-set was accurate but
silent on the normalized case; one clause added so both cited locations agree.
Before (tail of resolution-order item 2):**

```
#      (fail loud, never silently fall back past a caller-supplied
#      value).
```

**After (now lines 158-161):**

```
#      (fail loud, never silently fall back past a caller-supplied
#      value). Exception: a leading slash on a two-slash value
#      (/owner/repo) is normalized — the empty leading segment is
#      stripped as a zero-length HOST — and accepted.
```

### NIT-2 — `scripts/lib/tracker-migrate-reverse.sh` degradation-path comment

**Behavior evidence (path-trace re-derived locally):** the strip branch only
fires for ≥2-slash values (`*/*/*`); `${var#*/}` removes one segment + slash,
always leaving a non-empty string containing ≥1 slash — so the line-426
`[[ -z "$owner_repo" || "$owner_repo" != */* ]]` → `[]` guard is unreachable
from the strip path (it remains reachable from the `gh repo view` fallback
arm). Probe over every degenerate ≥2-slash class:

```
in=[a/b/c/d]      post-strip=[b/c/d]  hits-424-guard=no
in=[owner/repo/]  post-strip=[repo/]  hits-424-guard=no
in=[a/b/]         post-strip=[b/]     hits-424-guard=no
in=[a//]          post-strip=[/]      hits-424-guard=no
in=[//x]          post-strip=[/x]     hits-424-guard=no
in=[a//b]         post-strip=[/b]     hits-424-guard=no
```

The real degradation path for a still-degenerate value is the GraphQL
`repository(owner:, name:)` lookup failing → swallowed by the `provider_raw`
error branch (`if ! response=$(provider_raw ...); then echo "[]"`) → `[]`.
The comment now names that path.

**Edit 2 — (was lines 410-413). Before:**

```
        # is a private helper of tracker-provider-gh.sh. The
        # best-effort contract is preserved: a still-degenerate value
        # falls through to the existing [] guard below and never
        # aborts the reverse run.
```

**After (now lines 410-415):**

```
        # is a private helper of tracker-provider-gh.sh. The
        # best-effort contract is preserved: a still-degenerate value
        # always keeps >=1 slash post-strip (so the [] shape guard
        # below cannot catch it) and instead degrades via the failed
        # GraphQL repository() lookup → swallowed provider_raw error
        # branch → [] — it never aborts the reverse run.
```

## 2. Comment-only proof (zero behavior diffs)

- Both Edit calls' old/new strings consist exclusively of `#`-prefixed lines.
- `git diff` (vs HEAD) over the two lib files, filtered to changed lines that
  are NOT comments, shows ONLY the pre-existing BD-204 code from prior passes
  (the `_gh_owner_repo` helper body, the five call-site swaps, the reverse-lib
  `case` strip) — exactly the reviewer's §1 footprint; no new non-comment line
  was added or removed by this pass.
- `bash -n` both files → `syntax OK provider` / `syntax OK reverse`.
- The `_gh_owner_repo` probe matrix is byte-identical pre- and post-edit (§1).

## 3. Verification (rule 6 — full CI battery)

Full battery, every step of `.github/workflows/validate-pack.yml` run locally
in workflow order (runner `/tmp/bd204-fix2-battery.sh`, log
`/tmp/bd204-fix2-battery.log`):

- `grep -c "^STEP"` → **57**; `grep "^STEP" | grep -v "rc=0$"` → **empty**
  (57/57 rc=0).
- Includes: `validate-pack.py` rc=0 plain AND `PACK_VALIDATE_DEEP=1`; all
  tracker suites; all per-check suites (16/18/19/29/30/32-34/36-46/48/49-50);
  migrator-* suites; `test-fixtures/build.sh --all --clean` rc=0;
  `build.sh --verify` rc=0; `test-v11-realistic-ot.sh` integration rc=0;
  persona contracts; template-*; issue-forms.
- Directly-affected suites, exact counts: provider **Passed: 156 / Failed: 0**;
  reverse **Passed: 139 / Failed: 0** (same counts as reviewer pass 2 —
  comment edits changed nothing).
- Workflow step (a2) `git checkout HEAD -- test-fixtures/manifest.txt` was NOT
  run (git-state-changing verb forbidden to this agent); substituted with the
  equivalence proof `git diff --quiet -- test-fixtures/manifest.txt` → rc=0
  post-rebuild (rebuilt manifest byte-identical to committed → the restore is
  a no-op by construction), then `--verify` rc=0.
- Live oracle stayed default-SKIP: `env -u PACK_TRACKER_LIVE_GH bash
  scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` →
  `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0.
  Zero live GitHub calls made this session.

## 4. Files changed inventory (this pass)

| Path | Change type | Delta |
|---|---|---|
| `scripts/lib/tracker-provider-gh.sh` | modified (comment-only) | guard comment 6→11 lines; docstring +2 lines (net +7) |
| `scripts/lib/tracker-migrate-reverse.sh` | modified (comment-only) | degradation comment 4→6 lines (net +2) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION-FIX2.md` | new (this report) | — |

End-state `git status --porcelain`: the same four ` M scripts/...` rows as at
session start + the four pre-existing `??` reports + this report. HEAD
unchanged at `1068c74`. No new files beyond this report; no deletions.

## 5. Plan deviations / POQs / boundary check

- **Plan deviations:** none. Both NITs fixed per the reviewer's recommended
  (minimal-comment-edit) resolutions; no guard tightening, no behavior change.
- **New POQs:** none.
- **Boundary discipline check:** all edits are pack-side
  (`scripts/lib/` + this `maintenance-docs/` report); no `project-template/`
  or `supporting-docs/` surface touched — no project-side SSOT investigation
  required.

## 6. Definition of Done

| Item | Result |
|---|---|
| NIT-1 comment corrected to actual behavior (normalize-and-accept, not fail-loud), grounded by probe | PASS |
| NIT-2 comment names the real degradation path (GraphQL failure → swallowed `provider_raw` error → `[]`), grounded by path-trace | PASS |
| Zero behavior diffs (comment-only delta; probe matrix byte-identical; non-comment diff lines = prior passes only) | PASS |
| `bash -n` both edited files | PASS |
| Full CI battery 57/57 rc=0 (incl. provider 156/156, reverse 139/139, integration, fixtures build+verify) | PASS |
| Manifest regen run; `git diff test-fixtures/manifest.txt` empty (no staging needed) | PASS |
| Live oracle default-SKIP; zero live GitHub calls | PASS |
| pack-only end-state footprint (4 in-scope `scripts/` files + reports only) | PASS |
| No git state-changing verbs run | PASS |

## 7. Read-in-full attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `CLAUDE.md` (pack root, incl. full `## Pack memory` section) | full (Read tool, despite context copy) | 579 (wc -l) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION-REVIEW2.md` | full | 304 (wc -l; 305 display lines via Read) |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | full | 14 (wc -l) |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | full | 42 (wc -l) |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | full | 14 (wc -l) |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ) | section | lines 196-235 |
| `.github/workflows/validate-pack.yml` | full | 297 |

Section reads (scope-named code): `_gh_owner_repo` + full docstring
(`tracker-provider-gh.sh` lines 140-214 pre-edit, 148-209 re-read post-edit);
`_tmr_fetch_first_class_blocked_by` (`tracker-migrate-reverse.sh` lines
390-449 pre-edit, 396-430 re-read post-edit).

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session (complete list): `rev-parse HEAD` ×2, `status` / `status --porcelain` ×2, `git diff` (filtered, two lib files), `git diff --quiet -- test-fixtures/manifest.txt` ×2 — all read-only. Workflow step (a2) `git checkout HEAD -- manifest.txt` NOT run; substituted with `git diff --quiet` → rc=0 (§3). No add/commit/push/tag/stash/reset/restore/checkout. HEAD before = after = `1068c74a90b96fe78c48f73b818ed777c4deb873`. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op executed: no `rm -rf` on repo paths (battery scratch confined to `/tmp/bd204-fix2-battery.{sh,log}`; test harnesses clean their own mktemp dirs), no `git rm`, no overwrite of any trusted file (this report is NEW at the prompted path). `git status --porcelain` before = after for tracked files (same 4 ` M` rows, §4). | COMPLIANT |
| preflight-stop-means-stop | Emitted exactly one line immediately before this Write: `PREFLIGHT: 2/2 fixes complete; verification PASS; HEAD 1068c74a90b96fe78c48f73b818ed777c4deb873; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION-FIX2.md` — emitted only after both edits + full battery PASS. No parent stop/halt/revert message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted measurements; format per `pack-ops/PACK-MEMORY-RATIONALE.md:227-233` (conditional MUST-READ section read this session, §7 row 6). No empty-evidence rows. | COMPLIANT |
| agents-read-rule-docs-in-full | §7 attestation: all 5 prompt-named files read IN FULL with wc -l line counts (579 / 304 / 14 / 42 / 14) + the triggered rationale section + the workflow file (297) + both scoped code regions pre- and post-edit. | COMPLIANT |
| verify-full-ci-suite | §3: every `validate-pack.yml` step run locally in workflow order; log `/tmp/bd204-fix2-battery.log`: `grep -c "^STEP"` → 57; `grep "^STEP" \| grep -v "rc=0$"` → empty. `validate-pack.py` rc=0 plain + DEEP; provider `Passed: 156 / Failed: 0`; reverse `Passed: 139 / Failed: 0`; integration `test-v11-realistic-ot.sh` rc=0; fixtures build + verify rc=0. Live oracle `SKIP: live-GH oracle ...` rc=0 under `env -u PACK_TRACKER_LIVE_GH`. Zero live GitHub calls. | COMPLIANT |
| regenerate-manifest-v11-surface | Trigger fired (`scripts/` in diff); `bash test-fixtures/build.sh --all --clean` rc=0 (battery step `fixtures-build`); post-rebuild `git diff --quiet -- test-fixtures/manifest.txt` → rc=0 (empty diff) + `build.sh --verify` rc=0 — comment-only lib edits are not fixture-affecting; no staging needed. | COMPLIANT |
| edit-in-place-not-full-rewrite | Three targeted Edit calls (no Write on any existing file); both edited regions re-read post-edit via Read tool (provider lines 148-209, reverse lines 396-430 — quoted in §1, actual bytes not intent); untouched text byte-stable (non-comment `git diff` lines = prior passes' code only, §2). | COMPLIANT |
| pack-only | End-state `git status --porcelain`: exactly the four in-scope ` M scripts/...` rows + the four pre-existing `??` `maintenance-docs/` reports + this report (quoted §4). Zero `project-template/` or `supporting-docs/` paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverable = exactly the two approved comment corrections (NIT-1: guard comment + the docstring the finding's location cites; NIT-2: one comment block) + this report. No guard tightening, no test changes, no other file touched (§4 inventory). | COMPLIANT |
