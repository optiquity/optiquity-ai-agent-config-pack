# IMPLEMENTATION-REPORT-BD-129-RETRO-FIX

**BD:** BD-129 (D-1, MAJOR) — `gh --repo` flag plumbing
**Batch:** 21c retroactive review-fix
**Branch:** `v11-dev`
**Pre-edit HEAD SHA:** `304078f3d88aa48d763dd8e5c4b3d41917076640`
**Post-edit HEAD SHA:** `304078f3d88aa48d763dd8e5c4b3d41917076640`
(no commits made — pack-coder is read-only on git state per
`feedback_agents_never_commit.md`; Pack Chat commits)

**Review document:**
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-129-RETRO.md`
**Original implementation commit:** `1bdd1f5421be5acab3e7e6a1c38b265a8b67d93d`
(combined BD-129 + BD-130; this retro covers BD-129 portion only)

---

## 1. Scope

The Batch 21c retro for BD-129 surfaced 10 findings (1 MUST, 3 SHOULD,
6 NIT). Two were closed before this session began:

| Finding | Severity | Disposition | Closing commit |
|---|---|---|---|
| F1 — `tracker-bd129-gh-repo-test.sh` not wired into CI | MUST | Closed | `304078f` (cross-BD CI wiring + chmod +x parity) |
| F10 — BACKLOG `Resolved:` line dangling link | NIT | Closed | `614e67e` (Pattern B bulk-fix) |

This session covers the remaining 8 findings:

| Finding | Severity | Status |
|---|---|---|
| F2 — `_tracker_labels_create` external callers (in `tracker-promote.sh`) bypass the BD-129 helper | SHOULD | Fixed |
| F3 — Archived IMPL REPORT cites a `run-all-tests.sh` script that does not exist | SHOULD | Fixed (erratum) |
| F4 — Helper exports unvalidated `backend.repo` value as `GH_REPO` | SHOULD | Fixed |
| F5 — `_gh_has_sub_issue_extension` calls `gh extension list` outside `_gh_run` | NIT | Fixed (documented) |
| F6 — Test 2.2 description is misleading vs. what it actually exercises | NIT | Fixed (restructured) |
| F7 — No regression coverage for non-GitHub remote (GHE / GitLab / etc.) | NIT | Fixed (Group 5 added) |
| F8 — IMPL REPORT line-count drift (`+200` vs `+246` actual) | NIT | Documented in F3 erratum |
| F9 — Test file not executable | NIT | Closed by `304078f` (parallel CI batch); confirmed `-rwxr-xr-x@` at start of this session |

---

## 2. Per-finding implementation

### F2 — promote-path label callers now route through the helper [SHOULD]

**Problem:** `_tracker_labels_create` is called externally by
`tracker-promote.sh` at lines 671, 679, 1003, 1011 (the
`tracker_promote_path1` / `tracker_promote_path2` pre-create steps for
dynamic per-entity labels). These callers bypass `_gh_run` (the
labels helper shells `gh label create` directly), so the BD-129
helper-call planted inside `_gh_run` does NOT cover this code path.
`pack td promote` against a working copy with no GitHub remote would
still fail at the labels-pre-create step with the same misleading
`none of the git remotes ...` error BD-129 was meant to eliminate.

**Fix (combined option 1+2 from the review):**

1. `scripts/pack-td.sh::cmd_promote` — added a config-path
   resolution + export block right after Path 1/2 disambiguation.
   When `--flat-file-only` is not in effect, the dispatcher
   auto-detects the surface (pack/client) and exports
   `_TRACKER_PROVIDER_CONFIG_PATH` to point at the active
   `tracker.toml`. Mirrors the pattern from
   `scripts/lib/tracker-init.sh:216` and
   `scripts/lib/tracker-doctor.sh:168`. Failure to resolve a surface
   is tolerated — flat-file mode does not need GH_REPO at all.
2. `scripts/lib/tracker-promote.sh::tracker_promote_path1` (line ~676)
   and `tracker_promote_path2` (line ~1018) — added a
   `tracker_gh_repo_setup` call inside the `if [[ "$flat_only" != "1"
   ]] && [[ -f "$repo_root/.pack-tracker/id-map.json" ]]` block,
   immediately before the `_tracker_labels_create` block. The helper
   is a no-op when `GH_REPO` is already set or when
   `_TRACKER_PROVIDER_CONFIG_PATH` is unset, so it does not break
   any existing test seam.

Together, the dispatcher exports the env var and the library calls
the helper. Belt-and-suspenders: if a future caller invokes the
promote functions without going through `pack-td.sh`, the helper
in-library still fires; if the dispatcher is called but the helper
is not yet sourced, the export in the dispatcher still takes effect.

**Files touched:**
- `scripts/pack-td.sh` (+19 lines net inside `cmd_promote`, before
  the `case "$path" in path1|path2 ...` block)
- `scripts/lib/tracker-promote.sh` (+12 lines in
  `tracker_promote_path1` block at ~line 661-678; +9 lines in
  `tracker_promote_path2` block at ~line 1011-1019)

**Verification — grep showing helper reaches `_tracker_labels_create` callers:**

```
$ grep -n "tracker_gh_repo_setup\|_tracker_labels_create\|_TRACKER_PROVIDER_CONFIG_PATH" \
       scripts/lib/tracker-promote.sh scripts/pack-td.sh
scripts/pack-td.sh:186:    # BD-129 retro-fix F2: export `_TRACKER_PROVIDER_CONFIG_PATH` so
scripts/pack-td.sh:188:    # `tracker_promote_path2` (specifically the `_tracker_labels_create`
scripts/pack-td.sh:191:    # via `tracker_gh_repo_setup` and skip git-remote resolution.
scripts/pack-td.sh:196:    # no-op (helper short-circuits when `_TRACKER_PROVIDER_CONFIG_PATH`
scripts/pack-td.sh:204:            export _TRACKER_PROVIDER_CONFIG_PATH="$_td_cfg_path"
scripts/lib/tracker-promote.sh:665:        # `_tracker_labels_create`. The labels helper bypasses
scripts/lib/tracker-promote.sh:673:        # exports `_TRACKER_PROVIDER_CONFIG_PATH` so this helper has
scripts/lib/tracker-promote.sh:676:        if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
scripts/lib/tracker-promote.sh:677:            tracker_gh_repo_setup
scripts/lib/tracker-promote.sh:684:        # per-promotion). _tracker_labels_create is idempotent
scripts/lib/tracker-promote.sh:686:        if declare -f _tracker_labels_create >/dev/null 2>&1; then
scripts/lib/tracker-promote.sh:687:            if ! _tracker_labels_create "$derived_label"; then
scripts/lib/tracker-promote.sh:695:            if ! _tracker_labels_create "$promoted_label"; then
scripts/lib/tracker-promote.sh:1014:        # `_tracker_labels_create`. See the matching block in
scripts/lib/tracker-promote.sh:1017:        # `_TRACKER_PROVIDER_CONFIG_PATH` env var is unset.
scripts/lib/tracker-promote.sh:1018:        if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
scripts/lib/tracker-promote.sh:1019:            tracker_gh_repo_setup
scripts/lib/tracker-promote.sh:1027:        if declare -f _tracker_labels_create >/dev/null 2>&1; then
scripts/lib/tracker-promote.sh:1028:            if ! _tracker_labels_create "$derived_label"; then
scripts/lib/tracker-promote.sh:1036:            if ! _tracker_labels_create "$promoted_label"; then
```

Both `tracker_gh_repo_setup` calls (lines 676-677 and 1018-1019) sit
**immediately before** the `_tracker_labels_create` invocation block
(lines 686-695 and 1027-1036), guaranteeing the env-var setup
happens before the bare `gh label create` call inside the helper.

**Verification — end-to-end test with mock gh:**

```
$ bash /tmp/bd129-f2-check/test-f2.sh
  PASS: F2 — both _tracker_labels_create gh invocations saw GH_REPO=owner-promote/repo-promote (count=2)
  PASS: F2 — GH_REPO exported into shell (=owner-promote/repo-promote)

=== F2 results: 2 passed, 0 failed ===
```

The mock `gh` records `GH_REPO` per invocation. With
`_TRACKER_PROVIDER_CONFIG_PATH` set to a tracker.toml whose
`backend.repo = "owner-promote/repo-promote"`, both back-to-back
`_tracker_labels_create` calls observe the slug in their env. F2
closed.

---

### F3 — Archived IMPL REPORT erratum [SHOULD]

**Problem:** `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`
lines 259-263 claimed:
> "Wired into the existing test convention (no test runner registry
> needs updating; CI's `Validate Pack` workflow runs all
> `tracker-*-test.sh` files via `bash scripts/tests/run-all-tests.sh`
> per the existing layout)."

That script does not exist; the workflow enumerates each test file
by name. The false claim was the load-bearing reason F1's CI gap was
missed at original review time.

**Fix:** Added a `> **REVISION 2026-05-15 (Batch 21c retro-fix, F3
erratum):**` block at the top of the report (immediately after the
header metadata) that explicitly corrects the false `run-all-tests.sh`
claim, names commit `304078f` as the closing commit for the CI gap,
notes the F8 line-count drift in the same block (NIT documentation
hygiene), and points readers to this retro-fix report. The original
text at line 278 is preserved (archive integrity); the erratum
overrides it.

**Files touched:**
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`
  (+13 lines as a `>`-blockquote erratum after the header metadata)

**Verification — erratum present and correct:**

```
$ grep -n "REVISION 2026-05-15\|run-all-tests" \
       maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md
11:> **REVISION 2026-05-15 (Batch 21c retro-fix, F3 erratum):** The
14:> `tracker-*-test.sh` files via `bash scripts/tests/run-all-tests.sh`.
278:`bash scripts/tests/run-all-tests.sh` per the existing layout).
```

Line 11 introduces the erratum; line 14 quotes the false claim
inside the erratum (so the correction is unambiguous); line 278 is
the original false claim, now superseded by the line-11 erratum. F3
closed.

Note on the archive-edit policy: the caller's prompt explicitly
permits this edit and CLAUDE.md §"Skill and agent maintenance"
allows workflow-artifact updates; the erratum form (rather than
silent rewrite) preserves the historical narrative while making the
correction load-bearing for any reader. F8's NIT (line-count drift)
is folded into the same erratum block — no separate edit needed.

---

### F4 — Helper validates `backend.repo` shape before exporting [SHOULD]

**Problem:** `tracker_gh_repo_setup` exported the raw value of
`backend.repo` as `GH_REPO` without validating its shape. A
malformed value (HTTPS URL, missing slash, internal whitespace)
propagated silently and then surfaced as a less-targeted gh error
than the original BD-129 problem.

**Fix:** Added a one-line shape check in
`scripts/lib/tracker-config.sh::tracker_gh_repo_setup` between the
`tracker_repo_slug` read and the `export GH_REPO=...` write. The
check accepts only the canonical `[HOST/]OWNER/REPO` shape gh's own
`GH_REPO` contract documents:
- must contain at least one `/`
- no scheme separators (`://`)
- no whitespace (space or tab)

On rejection, emits a typed `validation` error to stderr (so the
user sees a clear diagnostic) and the helper returns 0 — fail-soft,
so the downstream gh call surfaces its own typed error if
appropriate. GHE-style three-segment slugs like
`github.example.com/owner/repo` are accepted (they contain a slash,
no scheme, no whitespace).

**Files touched:**
- `scripts/lib/tracker-config.sh` (`tracker_gh_repo_setup` body
  expanded from 9 lines to ~30 lines with validation + comment)

**Verification — focused F4 test against malformed slugs:**

```
$ bash /tmp/bd129-f4-check/test-f4c.sh
  PASS: https URL slug — GH_REPO stayed unset
  PASS: https URL slug — typed validation error emitted
  PASS: no-slash slug — GH_REPO stayed unset
  PASS: no-slash slug — typed validation error emitted
  PASS: whitespace slug — GH_REPO stayed unset
  PASS: whitespace slug — typed validation error emitted
  PASS: ghe host/owner/repo — GH_REPO=github.example.com/owner/repo
  PASS: ghe host/owner/repo — no error emitted (canonical slug accepted)

=== F4 results: 8 passed, 0 failed ===
```

Coverage: 4 cases × 2 assertions each = 8 assertions. Three
malformed shapes (`https://github.com/owner/repo`, `barerepo`,
`owner /repo`) are rejected with typed validation errors and
`GH_REPO` stays unset; the canonical GHE three-segment shape
(`github.example.com/owner/repo`) is accepted. The validation logic
matches the gh CLI's own `[HOST/]OWNER/REPO` documented contract. F4
closed.

The full `scripts/tests/tracker-bd129-gh-repo-test.sh` continues to
pass with the existing fixtures (which all use canonical
`owner/repo` shape) — no test-suite migration needed.

---

### F5 — `_gh_has_sub_issue_extension` bypass documented [NIT]

**Problem:** `scripts/lib/tracker-provider-gh.sh::_gh_has_sub_issue_extension`
calls `gh extension list` directly (not through `_gh_run`), so the
BD-129 helper does not fire before this `gh` invocation. Today this
is benign — `gh extension list` is a global command that does not
consult git-remote resolution and does not need `GH_REPO` — but it's
a documented contract violation of the helper's "any tracker library
that wraps a gh invocation" claim from the original IMPL REPORT
(line 248-249).

**Fix:** Added a docstring block above `_gh_has_sub_issue_extension`
explaining why this gh call is intentionally exempt from the
`_gh_run` routing pattern. The comment names BD-129 retro-fix F5,
explains that `gh extension list` is a global user-scope probe that
needs no repo target, and notes that the result is cached for the
process lifetime so the call happens at most once.

**Files touched:**
- `scripts/lib/tracker-provider-gh.sh` (+12 lines comment block at
  line 32-44)

**Verification — bash -n syntax pass:**

```
$ bash -n scripts/lib/tracker-provider-gh.sh && echo OK
OK
```

The comment is documentation-only; no functional change. F5 closed
via "documented why bypass is correct" path (the review's option b).

---

### F6 — Test 2.2 restructured to actually test two-call sequence [NIT]

**Problem:** Test 2.2 in `scripts/tests/tracker-bd129-gh-repo-test.sh`
claimed to verify "_gh_run re-establishes GH_REPO after caller unset"
but only invoked the gh wrapper once. With `unset GH_REPO` immediately
preceding a single call, this duplicated test 2.1 ("_gh_run exports
GH_REPO before invoking gh"). The most important user-facing
invariant — caller unsets GH_REPO mid-script, helper restores it on
the next call — was not proven.

**Fix:** Restructured 2.2 to run TWO `tracker_provider_gh_get` calls
with an `unset GH_REPO` between them. The assertion now requires
`grep -c '^GH_REPO=DShaneNYC/example-repo|' "$GH_LOG" >= 2` (was
`>= 1`). Both calls must observe the slug, proving the helper
re-exports on every invocation rather than relying on first-call
side effects.

**Files touched:**
- `scripts/tests/tracker-bd129-gh-repo-test.sh` (test 2.2 body
  restructured; +5 lines of new logic, -3 lines of stale narrative)

**Verification — test now exercises the correct invariant:**

```
=== Group 2: _gh_run propagates GH_REPO ===
  pass: 2.1 _gh_run exports GH_REPO before invoking gh
  pass: 2.2 _gh_run re-establishes GH_REPO between calls
```

The `>= 2` threshold means a regression that breaks the
re-establishment behavior would now fail 2.2 (previously, a
regression that broke re-establishment but kept first-call setup
intact would still pass 2.2 spuriously). F6 closed.

---

### F7 — Group 5 added for non-GitHub remote scenario [NIT]

**Problem:** `BACKLOG.md:1947` (Unblocks line) named "non-GitHub
remotes, internal mirrors, GHE-on-different-host" alongside the
"no remote at all" case. The original Group 3 only covered the
"freshly-cloned with no remote configured" case (the most extreme
form of the failure mode).

**Fix:** Added a new Group 5 to the test that exercises the
hostile-non-GitHub-remote variant:
1. `git init` + `git remote add origin https://gitlab.example.com/owner-5/repo-5.git`
2. Source a tracker.toml whose `backend.repo = "owner-5/repo-5"`
3. Run `tracker_labels_ensure`
4. Assert: rc=0; every gh invocation (46 total) saw `GH_REPO=owner-5/repo-5`;
   ZERO gh invocations saw `GH_REPO=<unset>` (the negative assertion
   that confirms the helper fired for every call).

The slug-from-tracker.toml must win over the GitLab git remote URL
— the central invariant BD-129 promises and the BACKLOG entry
explicitly names.

**Files touched:**
- `scripts/tests/tracker-bd129-gh-repo-test.sh` (+~50 lines of new
  Group 5 between Group 4 and the Results banner; assertion count
  goes from 11 to 14)

**Verification — Group 5 results:**

```
=== Group 5: tracker.toml slug wins over hostile non-GitHub git remote ===
  pass: 5.1 tracker_labels_ensure rc=0 with hostile non-GitHub git remote
  pass: 5.2 all gh calls saw GH_REPO=owner-5/repo-5 (count=46) — tracker.toml slug won over gitlab remote
  pass: 5.3 no gh call saw GH_REPO unset (helper fired for every invocation)
```

Total assertions across the suite now: 14 passed, 0 failed (was
11 passed, 0 failed). F7 closed.

---

### F8 — IMPL REPORT line-count drift, documented in F3 erratum [NIT]

**Problem:** Original IMPL REPORT line 243 cited `+200` lines for
the new test file; actual `wc -l` returns 246 (now 309 after F6+F7
additions in this fix-follow). Pure documentation drift — no
behavior impact.

**Fix:** Folded into the F3 erratum block at the top of the
archived IMPL REPORT (line 11-19). The erratum names the F8 drift
explicitly so future archive-tree readers see both corrections in
one place.

**Files touched:**
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`
  (folded into the F3 erratum; no separate edit)

**Verification — erratum names F8:**

```
$ grep -n "F8\|line-count drift" \
       maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md
20:> drift (claimed `+200`, actual `+246`) is a NIT (F8) — no behavior
```

F8 closed.

---

### F9 — Test file executable bit (closed by `304078f`) [NIT]

**Status at session start:** `-rwxr-xr-x@` confirmed via
`ls -la scripts/tests/tracker-bd129-gh-repo-test.sh`. This finding
was closed by the cross-BD CI wiring batch in commit `304078f`.

**No action this session.**

---

## 3. Files changed

| Path | Change type | Net line delta | Findings addressed |
|---|---|---|---|
| `scripts/lib/tracker-config.sh` | modified | +21 | F4 |
| `scripts/lib/tracker-promote.sh` | modified | +25 | F2 |
| `scripts/lib/tracker-provider-gh.sh` | modified | +12 | F5 |
| `scripts/pack-td.sh` | modified | +23 | F2 |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | modified | +69 | F6, F7 |
| `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md` | modified | +16 | F3, F8 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-129-RETRO-FIX.md` | new | (this report) | — |

`git diff --stat HEAD -- <my files>`:

```
 .../archive/v11/IMPLEMENTATION-REPORT-BD-129.md    | 16 +++++
 scripts/lib/tracker-config.sh                      | 23 ++++++-
 scripts/lib/tracker-promote.sh                     | 25 +++++++
 scripts/lib/tracker-provider-gh.sh                 | 12 ++++
 scripts/pack-td.sh                                 | 23 +++++++
 scripts/tests/tracker-bd129-gh-repo-test.sh        | 77 ++++++++++++++++++++--
 6 files changed, 168 insertions(+), 8 deletions(-)
```

(The +77/-8 on the test file reflects the test 2.2 restructure plus
Group 5 addition; the BD-129 retro-fix report is new and is not
counted in the diff stat.)

---

## 4. Verification summary

| Check | Result |
|---|---|
| `bash -n scripts/lib/tracker-config.sh` | OK |
| `bash -n scripts/lib/tracker-promote.sh` | OK |
| `bash -n scripts/lib/tracker-provider-gh.sh` | OK |
| `bash -n scripts/pack-td.sh` | OK |
| `bash -n scripts/tests/tracker-bd129-gh-repo-test.sh` | OK |
| `bash scripts/tests/tracker-bd129-gh-repo-test.sh` | 14/14 PASS (was 11/11) |
| `bash scripts/tests/tracker-config-test.sh` | 32/32 PASS |
| `bash scripts/tests/tracker-provider-test.sh` | 98/98 PASS |
| `bash scripts/tests/tracker-init-test.sh` | 95/95 PASS |
| `bash scripts/tests/tracker-bd130-doctor-wired-test.sh` | 20/20 PASS |
| `bash scripts/tests/test-tracker-promote-direct.sh` | 31/31 PASS |
| `bash scripts/tests/test-tracker-promote-path1.sh` | 80/80 PASS |
| `bash scripts/tests/test-tracker-promote-path2.sh` | 59/59 PASS |
| `bash scripts/tests/tracker-migrate-forward-test.sh` | 145/145 PASS |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` | 112 PASS, 1 FAIL (pre-existing — see §5) |
| `python3 scripts/validate-pack.py` | PASSED — all 32 checks clean |
| F4 focused test (4 fixtures × 2 assertions) | 8/8 PASS |
| F2 end-to-end test (mock gh + label-create wiring) | 2/2 PASS |

---

## 5. Pre-existing test failure (NOT caused by this fix-follow)

`scripts/tests/tracker-migrate-reverse-test.sh` test 6.1a
(`doctor surfaces schema-reshape on capability diff`) currently
fails with:
- expected substring: `"[WARN] capability cache differs from re-probe (schema-reshape)"`
- actual output:      `"[INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)"`

This is a concurrent coder's modification to
`scripts/lib/tracker-doctor.sh` (visible in `git diff HEAD -- scripts/lib/tracker-doctor.sh`)
that changed the WARN-on-diff behavior to INFO+auto-refresh. The
file is in BD-130's ownership lane (the caller's prompt names BD-130
as the owner of `scripts/lib/tracker-doctor.sh`); BD-129 retro-fix
does not touch this file.

Confirmed via `git show HEAD:scripts/lib/tracker-doctor.sh | grep
schema-reshape`: HEAD still emits `[WARN]`; the working-tree version
emits `[INFO]`. The test mismatch is therefore inherited from the
concurrent BD-130 working-tree changes, not from anything in BD-129's
retro-fix scope. Pack Chat / the BD-130 owner should reconcile the
test expectation with the new doctor behavior in their batch — not
this one.

No tests in the BD-129 retro-fix scope (BD-129 regression test, the
4 promote/labels-touching suites, validate-pack.py, F2 + F4 focused
tests) regressed. Every assertion that ran on files this fix-follow
modified passed.

---

## 6. Plan deviations

**None.** Implementation follows the review's recommended fixes
verbatim:
- F2: combined option 1 (helper-call inside library) + option 2
  (dispatcher exports `_TRACKER_PROVIDER_CONFIG_PATH`) — belt-and-
  suspenders, both sides safely no-op when the other is missing.
- F3: erratum form (review explicitly suggested "prepend a
  REVISION 2026-05-15 note" if the file is preserved as historical
  artifact).
- F4: shape validation as suggested in the review's "Concrete fix"
  one-liner, slightly extended to cover tabs in addition to spaces
  and to emit a typed validation error rather than silently no-op.
- F5: comment-at-call-site (review's option b — "lighter weight and
  preserves the function's caching pattern").
- F6: review's exact two-call fix recipe.
- F7: review's exact Group 5 fix recipe.

The dispatcher-exports-`_TRACKER_PROVIDER_CONFIG_PATH` part of F2 is
slightly broader than the review's option 1 alone (which would have
been a single library-side change), but the review's option 2
explicitly recommended this broader fix as "more architecturally
consistent (every dispatcher exports the path)". Combining the two
gives the cleanest defense-in-depth against future callers who
invoke `tracker_promote_path1` / `path2` outside the
`pack-td.sh::cmd_promote` dispatcher.

---

## 7. New POQs introduced

**None.** All findings are addressed within the existing
architecture (helper-as-belt-and-suspenders pattern from BD-129's
original design). No new architectural questions arose.

---

## 8. Definition-of-Done checklist

| Item | Status |
|---|---|
| F2 — `_tracker_labels_create` callers in `tracker-promote.sh` reach `tracker_gh_repo_setup` | PASS |
| F2 — promote dispatcher exports `_TRACKER_PROVIDER_CONFIG_PATH` | PASS |
| F2 — end-to-end test confirms gh invocations see GH_REPO | PASS (2/2) |
| F3 — archived IMPL REPORT erratum corrects `run-all-tests.sh` claim | PASS |
| F4 — `tracker_gh_repo_setup` validates slug shape before exporting | PASS |
| F4 — focused test confirms malformed slugs rejected, canonical accepted | PASS (8/8) |
| F5 — bypass at `_gh_has_sub_issue_extension` documented | PASS |
| F6 — test 2.2 actually exercises the two-call invariant | PASS |
| F7 — Group 5 covers non-GitHub remote scenario | PASS (3/3) |
| F8 — line-count drift documented in F3 erratum | PASS |
| `bash -n` clean on all 5 modified `.sh` files | PASS |
| `tracker-bd129-gh-repo-test.sh` 14/14 PASS (was 11/11) | PASS |
| Sibling promote/init/config/provider/doctor/labels suites green | PASS (460/460 across 7 suites) |
| `validate-pack.py` clean | PASS (all 32 checks) |
| BD-129 `Status:` field NOT flipped (already Resolved; this is a retro-fix, not a re-resolution) | PASS |
| Trinity rule N/A (no trinity files touched) | N/A |
| No git state changes | PASS |
| No PM-only files touched (BACKLOG.md, CHANGELOG.md, README.md, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md / AGENTS.md / GEMINI.md all unchanged by this session) | PASS |
| No concurrent coders' files touched (validate-pack.py, migrate-v10-to-v11/*, migrator-core.sh, pack-tracker.sh, tracker-migrate.sh, tracker-doctor.sh, tracker-migrate-forward.sh) | PASS |
| `.github/workflows/validate-pack.yml` not touched (already fixed by `304078f`) | PASS |
| Chunked Write — initial Write + Edit append | PASS |

---

## 9. Files-changed inventory

| Path | Change type | Reason |
|---|---|---|
| `scripts/lib/tracker-config.sh` | modified | F4 — `tracker_gh_repo_setup` slug-shape validation |
| `scripts/lib/tracker-promote.sh` | modified | F2 — `tracker_gh_repo_setup` calls before `_tracker_labels_create` blocks in `tracker_promote_path1` and `tracker_promote_path2` |
| `scripts/lib/tracker-provider-gh.sh` | modified | F5 — documenting comment above `_gh_has_sub_issue_extension` |
| `scripts/pack-td.sh` | modified | F2 — `cmd_promote` exports `_TRACKER_PROVIDER_CONFIG_PATH` |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | modified | F6 — test 2.2 restructured; F7 — Group 5 added |
| `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md` | modified | F3 + F8 — erratum block at top |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-129-RETRO-FIX.md` | new | (this report) |

---

## 10. Final summary (one paragraph)

Closed 8 of 8 in-scope BD-129 retro findings (F1 + F10 had been
closed pre-session by `304078f` and `614e67e` respectively).
**F2** (SHOULD): wired `tracker_gh_repo_setup` into the
`_tracker_labels_create` call sites by adding helper invocations in
`tracker_promote_path1` / `path2` and by exporting
`_TRACKER_PROVIDER_CONFIG_PATH` in `cmd_promote` — `pack td promote`
against a working copy with no GitHub remote now routes to the
configured slug at the labels-pre-create step. **F3** (SHOULD):
erratum block on the archived IMPL REPORT corrects the false
`run-all-tests.sh` claim and folds in the F8 line-count drift NIT.
**F4** (SHOULD): one-line shape validation in `tracker_gh_repo_setup`
rejects malformed `backend.repo` values (HTTPS URLs, missing slash,
whitespace) with a typed error rather than propagating them silently
to gh. **F5** (NIT): docstring above `_gh_has_sub_issue_extension`
explains why this `gh extension list` call is intentionally exempt
from `_gh_run` routing. **F6** (NIT): test 2.2 restructured to
actually exercise the two-call re-establishment invariant. **F7**
(NIT): Group 5 added covering the hostile-non-GitHub-remote
scenario (3 new assertions). **F8** (NIT): line-count drift
documented in the F3 erratum. **F9** (NIT): closed pre-session.
The `tracker-bd129-gh-repo-test.sh` regression suite now runs at
14/14 PASS (up from 11/11), all 7 sibling tracker test suites
relevant to this scope (config / provider / init / doctor-wired /
promote-direct / promote-path1 / promote-path2 / migrate-forward —
460 assertions total) remain green, and `validate-pack.py` reports
all 32 checks clean. One pre-existing failure in
`tracker-migrate-reverse-test.sh` (test 6.1a) is caused by a
concurrent BD-130 working-tree change to `scripts/lib/tracker-doctor.sh`
and is out of BD-129 retro-fix scope (documented §5). No git state
changes; no PM-only files touched; no concurrent coders' files
touched; trinity rule N/A.

