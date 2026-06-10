# IMPL-REPORT — BD-204 GH_REPO resolution, review-fix pass 1 (F-1 / F-3 / F-4)

- **Date:** 2026-06-10
- **Branch:** `v11-dev`
- **HEAD (unchanged; working-tree edits only):** `1068c74a90b96fe78c48f73b818ed777c4deb873`
- **Coder:** fresh fix-coder instance (BD-204 reviewer pass 1 triage: FIX F-1, F-3, F-4)
- **Not acted on:** F-2 (procedural, already dispositioned per the prompt — no
  edit made to any rule documentation about git verbs, no code change).

## 1. F-1 (SHOULD) — HOST/-prefix strip in `_tmr_fetch_first_class_blocked_by`

**File:** `scripts/lib/tracker-migrate-reverse.sh` (function at line 390).

**Before:** the GH_REPO-preferred branch used the value verbatim
(`owner_repo="$GH_REPO"`), so a canonical host-prefixed slug
(`github.example.com/owner/repo` — the shape `tracker_gh_repo_setup` in
`scripts/lib/tracker-config.sh` documents and exports, line 278) made the
`cut -d/ -f1/-f2` split yield owner=HOST, repo=OWNER → GraphQL NOT_FOUND →
swallowed best-effort → silent `[]` Blockers loss on GHE reverse migrations.

**After:** inline strip local to the function, per the reviewer's
recommended shape (NOT a cross-lib call into the provider lib's private
`_gh_owner_repo`):

```bash
        owner_repo="$GH_REPO"
        case "$owner_repo" in
            */*/*) owner_repo="${owner_repo#*/}" ;;
        esac
```

plus a comment block explaining the F-1 rationale and the
inline-not-cross-lib decision. The best-effort error contract is fully
preserved: no new failure path — a still-degenerate post-strip value (e.g.
`github.com/owner` → `owner`, slash-less) falls through to the PRE-EXISTING
`[[ -z "$owner_repo" || "$owner_repo" != */* ]] → echo "[]"` guard at
(now) line 424 and never aborts the reverse run. bash-3.2/BSD-safe
(`case`, `${var#*/}` only). +17 lines (comment + 3 code lines), 0 deletions.

**Test (one mock leg, `scripts/tests/tracker-migrate-reverse-test.sh` 7.3b,
inserted between 7.3 and 7.4):** fake gh logs its argv to a file and DIES on
`repo view` (so the leg also proves GH_REPO preference, not fallback), serves
the existing `gh-list-blocked-by.json` fixture on `api graphql`. Two
invocations inside the one leg:

- `GH_REPO=github.example.com/fixture-org/fixture-repo` → asserts the logged
  GraphQL query carries `owner: "fixture-org"` + `name: "fixture-repo"`,
  negative-asserts `owner: "github.example.com"` absent, and the fetch still
  parses 2 edges.
- plain `GH_REPO=fixture-org/fixture-repo` → still works verbatim
  (`owner: "fixture-org"`, 2 edges).

`GH_REPO` unset + `PATH` restored + fake dir removed before 7.4. Suite
count 133 → 139 (+6 assertions, all PASS).

**Mutation check (proves the leg bites):** in a `/tmp/bd204-fix1-mutation`
COPY of `scripts/` (repo untouched), reverted the strip to verbatim
`owner_repo="$GH_REPO"` and re-ran the suite: `Passed: 136, Failed: 3` —
the three host-prefix split asserts failed loudly
(`7.3b owner split = fixture-org` / `name split = fixture-repo` /
`host must not leak`). Scratch dir removed afterward.

## 2. F-3 (NIT) — IMPL-REPORT §4 grep block relabeled as annotated

**File:** `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md` §4.

**Choice:** relabel (the reviewer's second option; "smallest honest edit
wins"). Re-running the grep post-FIX1 would have replaced the block with
line numbers from a DIFFERENT tree state (F-4 below shifts the call sites
by +12 lines), mixing the base pass's record with this pass's state. The
relabel keeps the block as an honest record of the base pass.

**Before (lead-in to the fenced grep):**

```
All five call sites now read `owner_repo=$(_gh_owner_repo) || return 1`
(applied via one `replace_all` exact-string edit — identical line text at
all five sites):
```

**After:** same sentence, continued with an explicit annotation label:

```
... all five sites). The grep block below is ANNOTATED, not verbatim (review
F-3 correction): the trailing `# link (was ~524)`-style comments were
added in this report to identify each site and do NOT exist in the file —
the actual call-site lines are bare; line numbers are as of this pass
(pre-review-fix):
```

The fenced block itself is byte-untouched; the "identical line text at all
five sites" claim (true of the file) no longer contradicts the fence. The
file is untracked, so this edit is invisible to `git diff` — current file
state is the deliverable.

## 3. F-4 (NIT) — post-strip shape guard in `_gh_owner_repo()`

**File:** `scripts/lib/tracker-provider-gh.sh` (helper now at lines 166-201).

**Treatment picked: the cheap shape guard with the existing typed
`tracker_error_emit` fail-loud idiom** (not the contract-comment
alternative). Why: the reviewer's F-4 detail names the concrete tightening
("validate exactly-one-slash-with-non-empty-segments post-strip") as the
fix; the comment-only alternative would leave the behavior gap open and
require a tracked deferral anchor per `deferred-work-tracked-anchor` —
the guard is ~8 lines, reuses the helper's existing validation-error arm
and message verbatim, and makes the anchor question moot.

**Before:** post-strip check was only `[[ "$slug" != */* ]]`, so
`GH_REPO=a/b/c/d` (strip-once → `b/c/d`) and `GH_REPO=owner/repo/`
(→ `repo/`) passed through to a malformed REST path (loud downstream, but
late and less targeted).

**After:**

```bash
        local owner_part="${slug%%/*}"
        local repo_part="${slug#*/}"
        if [[ "$slug" != */* || -z "$owner_part" || -z "$repo_part" \
              || "$repo_part" == */* ]]; then
            tracker_error_emit "validation" \
                "owner_repo: GH_REPO='$GH_REPO' is not a [HOST/]OWNER/REPO slug"
            return 1
        fi
```

Rejects (post-strip): slash-less (pre-existing), empty owner (`host//repo`
→ `/repo`), empty repo / trailing slash (`owner/repo/` strips to `repo/`),
≥3 slashes (`a/b/c/d` strips to `b/c/d`, repo_part `c/d` carries a slash).
Accepts exactly one-slash-with-non-empty-segments. Error type, message, and
rc are identical to the pre-existing slash-less arm — no new error shape.
The helper's header comment (step 2) was extended to document the degenerate
shapes. bash-3.2/BSD-safe (`local`, `${var%%/*}`, `${var#*/}`).

**Test (`scripts/tests/tracker-provider-test.sh` 1.17h, after 1.17g):**
`GH_REPO=a/b/c/d` → `provider_link 42 99 blocked-by` rc=1 + stderr carries
`not a [HOST/]OWNER/REPO slug`; `GH_REPO=optiquity/pack/` → rc=1 + same
typed message. `FAKE_GH_REPO_VIEW_FAIL` stays exported from 1.17f, so any
silent fallback to `gh repo view` would also fail loudly. Suite count
152 → 156 (+4 assertions, all PASS).

## 4. Verification evidence

All local, all mock — zero live GitHub calls (live oracle confirmed
default-SKIP below). Full log: `/tmp/bd204-fix1-battery.log`.

### 4.1 Syntax

```
bash -n scripts/lib/tracker-provider-gh.sh        → OK
bash -n scripts/lib/tracker-migrate-reverse.sh    → OK
bash -n scripts/tests/tracker-provider-test.sh    → OK
bash -n scripts/tests/tracker-migrate-reverse-test.sh → OK
```

### 4.2 Directly-affected suites

| Suite | Result |
|---|---|
| `tracker-provider-test.sh` | rc=0 — **156/156 PASS** (was 152; +4 = 1.17h×4, all enumerated PASS) |
| `tracker-migrate-reverse-test.sh` | rc=0 — **139/139 PASS** (was 133; +6 = 7.3b×6, all enumerated PASS) |

### 4.3 Full CI battery (every step of `.github/workflows/validate-pack.yml`, locally, in workflow order)

**58/58 STEP rows rc=0; `grep "^STEP" | grep -v "rc=0$"` → empty.**
Highlights: `validate-pack.py` rc=0 ("PASSED — all checks clean") both
plain and `PACK_VALIDATE_DEEP=1`; provider 156/156; reverse 139/139;
forward / roundtrip / phase-task / links / cycle-check / errors and all
per-check validate-pack suites rc=0; `test-v11-realistic-ot.sh` integration
**33/33 PASS**; migrator-core/-manifest/-capability/-skills rc=0; persona
contracts rc=0; `test-fixtures/build.sh --all --clean` rc=0 then
`--verify` rc=0 (all rows OK); template-translations 44/44,
template-version 36/36, issue-forms 77/77.

One workflow step replicated WITHOUT its git verb: step (a2)
`git checkout HEAD -- test-fixtures/manifest.txt` is forbidden to this
agent in any form per the prompt's constraints. Equivalent proof
substituted: post-rebuild `git diff --quiet -- test-fixtures/manifest.txt`
→ rc=0 (rebuilt manifest byte-identical to committed), so the restore step
is a no-op by construction and the subsequent `--verify` rc=0 compares
against the canonical pinned SHAs anyway. No checkout was run.

### 4.4 Live-oracle default-SKIP (no network)

```
$ env -u PACK_TRACKER_LIVE_GH bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)
rc=0
```

### 4.5 Manifest state (regenerate-manifest-v11-surface)

Trigger fired (`scripts/` touched). `bash test-fixtures/build.sh --all
--clean` rc=0 (battery step); `git diff --stat test-fixtures/manifest.txt`
→ **empty** (exit 0). Per the rule's canonical-authority clause no staging
is needed: `scripts/lib/` files are not in the sanctioned shipped set
(exactly `{scripts/lib/detect.sh, scripts/pack-help.sh}`) and
`scripts/tests/` is never installed.

## 5. Files changed inventory (this fix pass)

| Path | Change | FIX1 delta |
|---|---|---|
| `scripts/lib/tracker-migrate-reverse.sh` | modified (F-1) | +17/−0 (comment + inline strip) |
| `scripts/lib/tracker-provider-gh.sh` | modified (F-4) | header comment 3→5 lines; guard block +9 net (file `git diff --stat` vs HEAD now 86 changed lines, was 75 after the base pass) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified (F-1 test) | +46/−0 (7.3b leg) |
| `scripts/tests/tracker-provider-test.sh` | modified (F-4 test) | +19/−0 (1.17h leg; file now 193 changed lines vs HEAD, was 174) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md` | edited (F-3) | §4 lead-in relabeled (untracked file) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION-FIX1.md` | new | this report |

Cumulative working-tree `git diff --stat` vs HEAD `1068c74` (base BD-204
pass + this fix pass): 4 files, 330 insertions(+), 12 deletions(−).

End-state `git status --porcelain`: the 4 modified `scripts/` files + 3
untracked `maintenance-docs/` reports (base IMPL-REPORT, review report,
this report). Nothing else.

## 6. Plan deviations

None in scope or substance — all three findings fixed per the reviewer's
recommended shapes; F-2 untouched. One execution substitution, documented
in §4.3: the CI workflow's manifest-restore `git checkout` step was
replaced by an empty-diff equivalence proof because every `git checkout`
form is forbidden to this agent by the prompt. No state-changing git verb
of any kind was executed this session.

## 7. New POQs introduced

None. POQ-BD204-GHREPO-1 (from the base pass) is RESOLVED by F-1 in this
pass — no anchor needed; the base IMPL-REPORT §8 disposition ("inclusion in
the BD-204 fix batch") is what happened.

## 8. Boundary discipline check

No project-side surface touched. All edits are pack-side (`scripts/lib/`,
`scripts/tests/`, `maintenance-docs/`). No project-side SSOT investigation
required; no boundary-discipline stop triggered; no pack-only reference
added to any project-side file.

## 9. Read-in-full attestation

| File | Read | Lines (wc -l) |
|---|---|---|
| `CLAUDE.md` (pack root, incl. full `## Pack memory`) | full | 579 |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GHREPO-RESOLUTION.md` | full | 299 |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | full | 42 |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | full | 14 |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | full | 14 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ triggered by the memory file) | section | lines 196-240 read; section at 206-233 |

Section reads (prompt-named): `scripts/lib/tracker-migrate-reverse.sh`
`_tmr_fetch_first_class_blocked_by` + caller (lines 370-459 + grep of all
callers; caller at line 614 `tracker_migrate_reverse_reconstruct`);
`scripts/lib/tracker-config.sh` `tracker_gh_repo_setup` slug contract
(lines 240-294); `scripts/lib/tracker-provider-gh.sh` `_gh_owner_repo` +
`_gh_run`/`tracker_provider_gh_raw` plumbing (lines 115-205, 843-871);
`maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION.md`
(full, 334 lines pre-edit); `scripts/tests/tracker-migrate-reverse-test.sh`
(lines 1-110, 850-1046 — harness + Group 7); `scripts/tests/
tracker-provider-test.sh` (1.17 chain lines 440-509 + harness symbol grep);
`.github/workflows/validate-pack.yml` (full, 297 lines — battery
enumeration).

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| F-1: inline HOST/-strip in `_tmr_fetch_first_class_blocked_by`, no cross-lib call, best-effort contract preserved | PASS (§1; re-read lines 390-439) |
| F-1: one mock test leg — host-prefixed GH_REPO owner/name extraction + plain owner/repo still works | PASS (7.3b ×6 asserts; mutation check proves it bites) |
| F-3: §4 grep block made honest (relabeled annotated, not "verbatim") | PASS (§2; smallest honest edit) |
| F-4: reviewer-recommended treatment applied + which/why stated | PASS (§3 — guard picked; rationale given) |
| F-4: one mock assertion covering the guard | PASS (1.17h ×4 asserts) |
| F-2: NOT acted on; no rule-doc edits about git verbs | PASS (diff touches no rule docs) |
| pack-only end state | PASS (§5 status: scripts/ + maintenance-docs/ only) |
| No live GitHub calls | PASS (§4; oracle default-SKIP rc=0) |
| Targeted in-place edits only | PASS (5 Edit calls + this Write; edited regions re-read §1/§3) |
| Full CI battery green | PASS (§4.3, 58/58 rc=0) |
| Manifest regenerated + state documented | PASS (§4.5, empty diff) |
| No state-changing git verbs | PASS (§6; read-only verbs only, checkout step substituted) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session (complete list): `rev-parse HEAD` ×3, `status` / `status --porcelain` ×3, `diff --stat`, `diff --quiet -- test-fixtures/manifest.txt`, `diff --stat test-fixtures/manifest.txt` — all read-only. The workflow's `git checkout HEAD -- manifest.txt` step was NOT run; substituted with the empty-diff proof (§4.3). No add/commit/push/tag/stash/reset/restore/checkout. HEAD before = after = `1068c74a90b96fe78c48f73b818ed777c4deb873`. | COMPLIANT |
| per-action-approval-sub-agents | Destructive ops limited to self-created /tmp scratch: `rm -rf /tmp/bd204-fix1-mutation` (my own copy), `/tmp/bd204-fix1-battery.{sh,log}`, `/tmp/bd204-fix1-step.out` (my own). No repo-file deletion, no `git rm`, no trusted-file overwrite (all repo changes via targeted Edit; this report is a NEW file). | COMPLIANT |
| preflight-stop-means-stop | Emitted exactly one line before this Write: `PREFLIGHT: 3/3 fixes complete; verification PASS; HEAD 1068c74a90b96fe78c48f73b818ed777c4deb873; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GHREPO-RESOLUTION-FIX1.md` — after all edits + 58/58 battery PASS. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted measurements; format per `pack-ops/PACK-MEMORY-RATIONALE.md:227-233` (conditional MUST-READ section read this session, §9 row 6). No empty-evidence rows. | COMPLIANT |
| agents-read-rule-docs-in-full | §9 attestation: 5 named files read IN FULL with wc -l line counts (579/299/42/14/14) + the triggered rationale section + all prompt-named code sections. No named doc's content was derived instead of read (CLAUDE.md re-read via Read tool despite being present in context). | COMPLIANT |
| verify-full-ci-suite | §4.3: every `.github/workflows/validate-pack.yml` step run locally in workflow order, log `/tmp/bd204-fix1-battery.log`: `grep -c "^STEP"` → 58; `grep "^STEP" \| grep -v "rc=0$"` → empty. validate-pack PASS both modes; provider 156/156; reverse 139/139; integration `test-v11-realistic-ot.sh` 33/33; fixtures build+verify OK. Live oracle: `SKIP: live-GH oracle ...` rc=0 under `env -u PACK_TRACKER_LIVE_GH` (§4.4). Zero live GitHub calls. | COMPLIANT |
| regenerate-manifest-v11-surface | Trigger fired (scripts/ in diff); `test-fixtures/build.sh --all --clean` rc=0 (battery step `fixtures-build`); `git diff --stat test-fixtures/manifest.txt` → empty (exit 0, §4.5); `--verify` rc=0 all rows OK. Empty diff = no staging needed, with evidence. | COMPLIANT |
| edit-in-place-not-full-rewrite | 5 targeted Edit calls total (2 lib-gh, 1 lib-reverse, 1 test-prov, 1 test-reverse) + 1 Edit on the base IMPL-REPORT; zero full-file Writes on existing files. Edited regions re-read post-edit via Read (lib-gh 148-205, lib-reverse 390-439 — quoted in §1/§3); `git diff --stat` shows only the expected files; untouched text byte-stable (diff hunks only at the edited blocks). | COMPLIANT |
| pack-only | End-state `git status --porcelain` (§5): ` M` ×4 under `scripts/` + `??` ×3 under `maintenance-docs/` (base IMPL-REPORT, review report, this report). Zero `project-template/` or `supporting-docs/` paths; Check 36 pack-only deny-list satisfied. | COMPLIANT |
| scope-deliverables-to-the-ask | Diff = exactly the F-1 strip + 7.3b leg, the F-3 relabel, the F-4 guard + header-comment extension + 1.17h leg, and this report. Nothing for F-2 (no rule-doc edit); no opportunistic edits (e.g., base IMPL-REPORT §3/§4 line numbers NOT rewritten to post-FIX1 values — out of F-3's honesty scope). | COMPLIANT |
