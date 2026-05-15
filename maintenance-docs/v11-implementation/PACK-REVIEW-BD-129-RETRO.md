# PACK-REVIEW-BD-129-RETRO

**BD:** BD-129 (D-1, MAJOR) — gh CLI invocations missing `--repo` cause
`pack tracker init` to fail in repos without a GitHub remote
**Original commit:** `1bdd1f5421be5acab3e7e6a1c38b265a8b67d93d`
**Review type:** Retroactive per-BD review (Batch 21c)
**Branch:** `v11-dev`
**Reviewer:** pack-reviewer
**Methodology source:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`
(severity scheme + dimension framework + race-detection heuristic)

---

## 1. Scope declaration

### In-scope (BD-129 portion of `1bdd1f5`)

- `scripts/lib/tracker-config.sh` — `tracker_gh_repo_setup` helper
  (+43 lines at lines 221-262)
- `scripts/lib/tracker-provider-gh.sh` — helper invocation in `_gh_run`
  (+13 lines around line 90-106)
- `scripts/lib/tracker-labels.sh` — helper invocation in
  `tracker_labels_ensure` (+10 lines at lines 138-146)
- `scripts/tests/tracker-bd129-gh-repo-test.sh` — NEW (+246 lines)
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`

### Out of scope (BD-130 portion of same commit, reviewed separately)

- `scripts/lib/tracker-doctor.sh` (NEW)
- `scripts/pack-tracker.sh` (source-line addition)
- `scripts/tracker-migrate.sh` (function relocation + pointer comment)
- `scripts/tests/tracker-bd130-doctor-wired-test.sh`
- BD-130 portions of `tracker-provider-gh.sh`

---

## 2. Methodology notes

Surveyed:
- The full BD-129 diff via `git show 1bdd1f5 -- <files>`
- Current state of all four touched files (post-commit)
- Every `gh` invocation site reachable from tracker libs
  (`grep -n "gh " scripts/lib/tracker-provider-gh.sh` → 37 sites, up
  from 24 at commit time as later BDs added more — all flow through
  `_gh_run` so the fix continues to cover them)
- Cross-references to `tracker_gh_repo_setup` and
  `_TRACKER_PROVIDER_CONFIG_PATH` across the entire `scripts/` tree
- External callers of `_tracker_labels_create` in `scripts/lib/`
- CI workflow definition (`.github/workflows/validate-pack.yml`)
  to verify the new test is wired
- Sibling tests for GH_REPO leak handling
  (`tracker-migrate-reverse-test.sh` line 706 demonstrates other tests
  had to adapt to the export, confirming the helper's effect is real)
- Live execution of `tracker-bd129-gh-repo-test.sh` (11/11 PASS as of
  current HEAD)

Touch-point classification per finding follows
CONCEPTUAL-REVIEW-METHODOLOGY §"Touch-point classification".

---

## 3. Findings

### F1 — `tracker-bd129-gh-repo-test.sh` not wired into CI [MUST]

**Severity:** MUST
**Dimension:** (a) Completeness — the regression test exists but is
not executed by CI, so the fix's regression net is incomplete.
**Touch-point class:** OWNED (the test file and the workflow are
owned by the BD-129/130/132/etc. cluster of stability fixes).

**Evidence:**
- `IMPLEMENTATION-REPORT-BD-129.md` line 261-262 claims:
  > "Wired into the existing test convention (no test runner
  > registry needs updating; CI's `Validate Pack` workflow runs all
  > `tracker-*-test.sh` files via `bash scripts/tests/run-all-tests.sh`
  > per the existing layout)."
- Reality: `find scripts -name "run-all-tests*"` returns no results —
  the script does not exist.
- `.github/workflows/validate-pack.yml` lines 110-213 enumerate each
  test file by name with a dedicated `bash scripts/tests/<file>` step.
  There is no glob-based discovery and no shared runner.
- `grep -c "tracker-bd129\|tracker-bd130\|tracker-bd132" .github/workflows/validate-pack.yml`
  returns 0. None of the BD-N stability regression tests are wired.

**Impact:** Any future change that breaks `tracker_gh_repo_setup` or
its invocation seam (e.g., a refactor that removes the `_gh_run`
preflight, or a change to `tracker_repo_slug` that breaks the
parsing) will pass CI green. The 11 assertions in
`tracker-bd129-gh-repo-test.sh` are a regression net only when a
human happens to run the test locally.

**Concrete fix:** Add a step to
`.github/workflows/validate-pack.yml` immediately after the
`tracker-errors tests` block (around line 146), modelled after the
existing per-test invocations:

```yaml
      - name: tracker BD-129 gh-repo routing tests (BD-129)
        if: always()
        run: bash scripts/tests/tracker-bd129-gh-repo-test.sh
```

A broader, more durable fix is to convert the workflow's per-test
enumeration into a glob: `for f in scripts/tests/*-test.sh; do bash
"$f"; done`. That is out of scope for a BD-129 fix-follow but is the
right architectural direction (and would prevent the same gap in
BD-130, BD-132, BD-133, BD-134, etc.). For BD-129 alone, add the
single step.

**Cross-concept impact:** BD-130 (`tracker-bd130-doctor-wired-test.sh`),
BD-132 (`tracker-bd132-race-test.sh`), BD-133, BD-134 all share the
same gap. The CI-wiring fix-follow can be batched.

---

### F2 — `_tracker_labels_create` external caller in `tracker-promote.sh` is not covered by helper [SHOULD]

**Severity:** SHOULD
**Dimension:** (c) Touch points + cross-concept impact — a named
in-scope symbol (`_tracker_labels_create`, called out in BACKLOG entry's
`File/Symbol` line) has callers outside `tracker_labels_ensure` that the
helper-at-top placement does not reach.
**Touch-point class:** SHARED-RW (`_tracker_labels_create` is read AND
called by both `tracker-labels.sh` and `tracker-promote.sh`).

**Evidence:**
- `BACKLOG.md` line 1934 names `_tracker_labels_create` (file
  `tracker-labels.sh:183`, now line 210) explicitly as in-scope for the
  BD-129 fix.
- Implementation chose to plant the helper call at the top of
  `tracker_labels_ensure` (`tracker-labels.sh:138-146`), reasoning that
  this covers "the 2 raw `gh label list`/`create` sites".
- But `_tracker_labels_create` has another caller:
  `scripts/lib/tracker-promote.sh:671, 679, 1003, 1011`. Four direct
  call sites in `tracker_promote_path1` and `tracker_promote_path2`,
  invoked by `pack td promote` (`scripts/pack-td.sh:195, 209`).
- `pack-td.sh` does NOT export `_TRACKER_PROVIDER_CONFIG_PATH` before
  invoking the promote functions (verified by
  `grep -n _TRACKER_PROVIDER_CONFIG_PATH scripts/pack-td.sh` — no hits).
- `tracker_promote_path1` itself does NOT export the path either.
- Result: the FIRST gh call in the promote flow is `_tracker_labels_create
  "$derived_label"` (line 671). At this point `GH_REPO` is unset and
  `_TRACKER_PROVIDER_CONFIG_PATH` is unset, so the helper is a no-op
  even when the user has a valid `tracker.toml` on disk. gh falls back
  to git-remote resolution and emits the same misleading error BD-129
  was meant to fix, just on a different verb.

**Impact:** `pack td promote` against a working copy without a
GitHub remote (the exact failure mode BD-129 was meant to eliminate
across the tracker surface) will still fail at the `_tracker_labels_create`
step with a partial-write error. The user has done what BD-129 told
them to do (configure `backend.repo` in `tracker.toml`) but the fix
does not reach this code path.

**Concrete fix:** Two acceptable options:

1. (preferred — local fix) Plant the helper call at the top of
   `_tracker_labels_create` itself in `scripts/lib/tracker-labels.sh`
   (around line 210, before the `gh label create` line), mirroring the
   `tracker_labels_ensure` pattern. That single-site addition covers
   every existing and future external caller. Same pattern, same
   `declare -f tracker_gh_repo_setup` guard, no behavior change for
   already-covered callers (helper is idempotent).
2. (broader fix) Have the promote dispatcher set
   `_TRACKER_PROVIDER_CONFIG_PATH` before invoking
   `tracker_promote_path1` / `tracker_promote_path2`, mirroring the
   pattern in `tracker_init_run` (`tracker-init.sh:216`),
   `tracker_doctor_run` (`tracker-doctor.sh:168`), etc. That is more
   architecturally consistent (every dispatcher exports the path) but
   touches `pack-td.sh` which is outside BD-129's stated scope.

Recommend option 1 for the BD-129 fix-follow; option 2 for a separate
BD that audits ALL dispatchers for `_TRACKER_PROVIDER_CONFIG_PATH`
discipline.

**Cross-concept impact:** BD-106 (promotion-path label families),
BD-107 (promotion-path implementations) both rely on this code path
and would benefit from the fix.

---

### F3 — Implementation report claims a glob-based test runner that does not exist [SHOULD]

**Severity:** SHOULD (documentation defect that obscures F1)
**Dimension:** (a) Completeness — the report's own self-verification
narrative is incorrect.
**Touch-point class:** OWNED.

**Evidence:**
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md` lines
  259-263:
  > "A standalone mock-based regression suite. Wired into the existing
  > test convention (no test runner registry needs updating; CI's
  > `Validate Pack` workflow runs all `tracker-*-test.sh` files via
  > `bash scripts/tests/run-all-tests.sh` per the existing layout)."
- `find scripts -name "run-all-tests*"` returns nothing.
- `.github/workflows/validate-pack.yml` enumerates each test
  individually; there is no `tracker-*-test.sh` glob. (See F1.)

**Impact:** The report's authoritative-looking claim was the load-
bearing reason F1's gap was missed at original review time. Anyone
reading the report believes the test runs in CI; nobody verified.

**Concrete fix:** When F1 is addressed (CI step added), update or
move the implementation report to reflect the actual wiring. If the
report file is preserved as historical artifact, prepend a
"REVISION 2026-05-15: F1 fix-follow added explicit CI step" note.
The report currently lives at
`maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`; the
PM Chat owns archive-tree edits.

**Cross-concept impact:** The same failure mode (report claims CI
wires the test, CI does not) likely affects the BD-130, BD-132,
BD-133, BD-134 implementation reports authored under the same
mistaken assumption. Spot-check recommended.

---

### F4 — Helper exports unvalidated `backend.repo` value as `GH_REPO` [SHOULD]

**Severity:** SHOULD
**Dimension:** (b) Edge cases — a user-authored `tracker.toml` with
a malformed `backend.repo` value (e.g., `"foo"` without the slash, or
trailing whitespace, or an HTTPS URL accidentally pasted) propagates
silently into `GH_REPO`, then gh fails with a less-targeted error than
the original BD-129 problem.
**Touch-point class:** OWNED.

**Evidence:**
- `scripts/lib/tracker-config.sh:252-262`: helper does
  `slug=$(tracker_repo_slug "$cfg" 2>/dev/null) || return 0` then
  `[[ -n "$slug" ]] && export GH_REPO="$slug"`. No validation that
  `$slug` matches the canonical `owner/repo` format.
- The TOML reader at `scripts/lib/tracker-config.sh:135` accepts any
  quoted-string value for `backend.repo` (regex: `^[A-Za-z_][...]\s*=\s*(.+?)`,
  values are then unquoted with `raw[1:-1]` at line 147). So
  `repo = "https://github.com/owner/repo"` parses successfully.
- `gh` then sees `GH_REPO=https://github.com/owner/repo` and emits a
  generic error like `expected the "[HOST/]OWNER/REPO" format, got "<value>"`
  (gh CLI v2.x message). This error is then routed through
  `_gh_classify_error`'s default case (line 84) to typed
  `validation` error.

**Impact:** Less severe than the original BD-129 failure mode
(error is at least no longer "none of the git remotes…") but still
not a great user experience. The fix's claim that it eliminates the
misleading-error class is partially defeated for the misconfigured-toml
subcase.

**Concrete fix:** Add a one-line validation in the helper before
exporting:

```bash
[[ "$slug" == */* && "$slug" != *://* && "$slug" != *' '* ]] && export GH_REPO="$slug"
```

Or, even better, defer validation to a richer `tracker_config_validate`
function and have the helper depend on it. The minimal one-liner is
acceptable for a SHOULD fix.

**Cross-concept impact:** None — this is an OWNED touch point.

---

### F5 — `_gh_has_sub_issue_extension` calls `gh extension list` outside `_gh_run` [NIT]

**Severity:** NIT (defense-in-depth)
**Dimension:** (c) Touch points — a `gh` invocation site exists
outside the helper's coverage.
**Touch-point class:** OWNED.

**Evidence:**
- `scripts/lib/tracker-provider-gh.sh:35-44`: `_gh_has_sub_issue_extension`
  calls `gh extension list 2>/dev/null | grep -q "sub-issue"` directly,
  not through `_gh_run`.
- BD-129's helper is therefore not invoked before this `gh extension list`
  call.

**Impact:** Today, `gh extension list` is a global command that does
not consult git-remote resolution and does not need GH_REPO. So the
gap is benign as of gh CLI v2.x. However, it is a documented contract
violation of the "helper-as-belt-and-suspenders" pattern the
implementation report itself claims (line 248-249: "Idempotent and
safe to call from any tracker library that wraps a gh invocation.").

**Concrete fix:** Either (a) route the call through `_gh_run` for
consistency, or (b) add a comment at the call site explaining why
this `gh` invocation is exempt (`gh extension list` is repo-agnostic).
Option (b) is lighter weight and preserves the function's caching
pattern. Acceptable to defer entirely.

**Cross-concept impact:** None.

---

### F6 — Test 2.2 description is misleading vs. what it actually exercises [NIT]

**Severity:** NIT
**Dimension:** (b) Edge cases — the test name implies a multi-call
re-establishment behavior the test does not actually probe.
**Touch-point class:** OWNED.

**Evidence:**
- `scripts/tests/tracker-bd129-gh-repo-test.sh:160-170`:

  ```
  # 2.2 No remote resolution involved: scrub GH_REPO between calls
  # and verify _gh_run re-establishes it (exec inherits but a fresh
  # env start would still see it because the helper exports). For this
  # we just confirm the same call works repeatedly.
  unset GH_REPO
  : > "$GH_LOG"
  tracker_provider_gh_get 1 >/dev/null 2>&1 || true
  got=$(grep -c '^GH_REPO=DShaneNYC/example-repo|' "$GH_LOG" || true)
  [[ "$got" -ge 1 ]] && t_pass "2.2 _gh_run re-establishes GH_REPO after caller unset" \
      || t_fail "..."
  ```

- The test invokes `tracker_provider_gh_get 1` once after
  `unset GH_REPO`. It does NOT verify that a SECOND call re-establishes
  GH_REPO if the user's code unsets it between the first and second
  call. The current helper short-circuits on `GH_REPO` already-set, so
  if a caller unset GH_REPO between calls, the helper would in fact
  re-export it on the next call (correct behavior) — but the test
  doesn't actually demonstrate that two-call sequence.

**Impact:** False sense of coverage. The "re-establishes" guarantee is
arguably the most important user-facing invariant (caller unsets
GH_REPO mid-script, helper restores it), and the test as written only
proves "first call sets it after unset", which is the same as test 2.1.

**Concrete fix:** Restructure 2.2 to be:

```bash
# 2.2 Two-call sequence: caller unsets GH_REPO between calls;
# helper re-exports on the next gh invocation.
unset GH_REPO
: > "$GH_LOG"
tracker_provider_gh_get 1 >/dev/null 2>&1 || true   # 1st call: helper sets
unset GH_REPO                                       # caller scrubs
tracker_provider_gh_get 1 >/dev/null 2>&1 || true   # 2nd call: helper re-sets
got=$(grep -c '^GH_REPO=DShaneNYC/example-repo|' "$GH_LOG" || true)
[[ "$got" -ge 2 ]] && t_pass "2.2 _gh_run re-establishes GH_REPO between calls" \
    || t_fail "..."
```

**Cross-concept impact:** None.

---

### F7 — No regression coverage for non-GitHub remote (GHE-on-different-host etc.) [NIT]

**Severity:** NIT
**Dimension:** (b) Edge cases — BACKLOG entry's failure modes list
includes "non-GitHub remotes, internal mirrors, GHE-on-different-host";
the test only covers "no remote at all".
**Touch-point class:** OWNED.

**Evidence:**
- `BACKLOG.md:1933` (Unblocks line) and `:1935` (Description) name:
  - clones from local-path sources
  - non-GitHub remotes
  - internal mirrors
  - GHE-on-different-host
  - freshly-cloned repos before remote setup
  - monorepo subtree imports
- The test's Group 3 covers only "freshly-cloned with no remote
  configured" via `git init -q` followed by NOT adding any remote.
- A test variant adding `git remote add origin https://gitlab.com/x/y`
  before invoking `tracker_labels_ensure` would empirically prove
  GH_REPO wins over a hostile (non-GitHub) git remote — the central
  invariant BD-129 promises.

**Impact:** Limited. The mock-based test design proves that GH_REPO
is exported into the gh subprocess environment, and gh's own
documented contract is that GH_REPO overrides remote resolution. The
chain holds. But adding the variant would close a documented coverage
gap.

**Concrete fix:** Add a Group 3.5 or new Group 5 that:
1. `git init` and `git remote add origin https://gitlab.com/x/y`
2. Run `tracker_labels_ensure` with `_TRACKER_PROVIDER_CONFIG_PATH`
   set to a tracker.toml whose `backend.repo` differs from the gitlab URL
3. Assert all gh calls saw GH_REPO=<tracker.toml slug>, not the
   gitlab URL (which the fake gh would not even know about, but the
   GH_REPO line in the log is the assertion target)

**Cross-concept impact:** None.

---

### F8 — Implementation report file count and line count drift [NIT]

**Severity:** NIT (documentation-only; does not affect behavior)
**Dimension:** (a) Completeness.
**Touch-point class:** OWNED.

**Evidence:**
- `IMPLEMENTATION-REPORT-BD-129.md:243`:
  > `| `scripts/tests/tracker-bd129-gh-repo-test.sh` | NEW regression
  > test | +200 |`
- Actual: `wc -l scripts/tests/tracker-bd129-gh-repo-test.sh` = 246.
- Commit shows `+246` lines.
- Same report line 252 shows the `git diff --stat` output for the
  modified files (3 files, 66 lines) but does not include the new
  test (untracked at the time of diff). The "+200" is a rounded
  guess. NIT.

**Impact:** None.

**Concrete fix:** None required. Note for archive-tree
revision discipline: agents should run `wc -l <file>` for the
final number rather than estimating.

**Cross-concept impact:** None.

---

### F9 — Test file is not executable; sibling tests are [NIT]

**Severity:** NIT
**Dimension:** (e) Design best practice — convention asymmetry.
**Touch-point class:** OWNED.

**Evidence:**
- `ls -la scripts/tests/tracker-bd*.sh`:

  ```
  -rw-r--r--  tracker-bd129-gh-repo-test.sh
  -rw-r--r--  tracker-bd130-doctor-wired-test.sh
  -rwxr-xr-x  tracker-bd132-race-test.sh
  -rwxr-xr-x  tracker-bd133-header-preservation-test.sh
  -rwxr-xr-x  tracker-bd134-close-retry-test.sh
  ```
- `tracker-bd129-gh-repo-test.sh` and `tracker-bd130-doctor-wired-test.sh`
  (the two added in `1bdd1f5`) are not executable; the three later
  BD-13x tests are.
- Both invocation styles (`bash <file>` and direct execution) work,
  so this is purely cosmetic — but inconsistent with the file's own
  shebang (`#!/usr/bin/env bash` line 1) and with siblings.

**Impact:** None operationally. CI invokes via `bash`, local devs
typically do too. Cosmetic.

**Concrete fix:** `chmod +x scripts/tests/tracker-bd129-gh-repo-test.sh
scripts/tests/tracker-bd130-doctor-wired-test.sh`. PM Chat can do this
when batching CI-wiring fix-follows.

**Cross-concept impact:** None.

---

### F10 — Implementation report file lives in archive but is referenced as v11-implementation by other reports [NIT]

**Severity:** NIT (documentation pathing inconsistency)
**Dimension:** (a) Completeness.
**Touch-point class:** OWNED.

**Evidence:**
- `BACKLOG.md:1936` references
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-129.md`.
- Actual file location:
  `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-129.md`.
- The original commit landed the file under `v11-implementation/`,
  consistent with the BACKLOG reference. A later sweep moved it to
  `archive/v11/` (likely Pattern B per CLAUDE.md "Skill and agent
  maintenance" — workflow artifacts sweep to `maintenance-docs/archive/vN/`
  at version ship). This sweep was not paired with a BACKLOG-link
  update.

**Impact:** Click-through from the BACKLOG entry breaks. Reader has
to go fish.

**Concrete fix:** Two options:
1. Wait for the v11 ship sweep to renumber/relocate everything in a
   single batched edit (the implementation report archive move is in
   progress for many BDs).
2. PM Chat updates the BACKLOG line to point at the archive location
   in the same fix-follow as F1.

Either acceptable; option 2 is more deterministic.

**Cross-concept impact:** Likely affects multiple BD entries —
spot-check the `Resolved:` lines in `BACKLOG.md` against actual file
locations.

---

## 4. What the implementation got right

A focused review must affirm what worked. The BD-129 implementation
correctly:

1. **Chose the right approach.** `GH_REPO` env-var export is the
   documented gh CLI contract for "skip remote resolution"; it is
   strictly cleaner than per-call `--repo` flag injection across 26
   sites. The future-proofness argument in the report (new gh sites
   under `_gh_run` are auto-covered) has been borne out — the file
   now has 37 `_gh_run gh` sites (up from 24), all covered without
   additional edits.
2. **Preserved the test seam.** `GH_REPO` already-set short-circuits
   the helper. Tests, advanced callers, and CI overrides all work.
3. **Kept the fix in `lib/`.** Zero edits to `pack-tracker.sh` —
   correctly avoided BD-130's file-race lane.
4. **Wrote a meaningful regression test.** Group 3's `git init` +
   no-remote setup directly reproduces the BD-129 failure scenario;
   `assert_eq` of all-46-calls-saw-GH_REPO is a strong invariant.
5. **Documented the action-at-a-distance trade-off.** The
   implementation report calls it out explicitly with mitigations
   (docstrings, comments at each site, regression test). This is
   exactly the discipline the architecture-review skill asks for.
6. **Audited gh-call sites for completeness.** The report enumerates
   all 26 sites and rules out the 5 non-applicable callsites
   (auth-status, mirror, sidecar, migrate-forward, migrate-reverse,
   agent-read) with reasoning. The audit is thorough.
7. **Fail-soft semantics.** Helper never returns non-zero; downstream
   gh call surfaces typed errors normally if the helper was a no-op.
8. **Idempotent.** Safe to call repeatedly; the `${GH_REPO:-}` guard
   makes the second-and-later calls effectively free.

The fix's concept and core mechanism are sound. The findings above
concern coverage edges (F1, F2, F4, F5, F7), test description
clarity (F6), and documentation hygiene (F3, F8, F9, F10) — not the
fundamental design.

---

## 5. Coverage notes

In scope but not exhaustively reviewed:
- `tracker-provider-gh.sh`'s `gh search issues` semantics with
  `GH_REPO` set. `gh search` is search-scoped, not repo-scoped;
  GH_REPO does NOT inject `repo:` filters into search queries. This
  is a pre-existing concern unrelated to BD-129 (the search call
  was previously also unscoped); flagging it for awareness only,
  not as a BD-129 finding.
- The interaction between `tracker_provider_gh_set_milestone` and
  GH_REPO when the milestone is on a different repo than `backend.repo`
  — pre-existing assumption that all entities live in `backend.repo`.

---

## 6. Re-architect summary

No `ARCH` findings. All findings are scoped to the BD-129 fix
surface and adjacent code paths; none require re-architecting a
contract that crosses concept boundaries.

The closest thing to an architectural concern is F2 (helper-at-top
vs. helper-at-leaf placement). That is a design-pattern preference
within an established lib/dispatcher boundary, not a contract change.

---

## 7. Severity summary

| Severity | Count | Findings |
|---|---|---|
| BLOCKER | 0 | — |
| MUST | 1 | F1 |
| SHOULD | 3 | F2, F3, F4 |
| NIT | 6 | F5, F6, F7, F8, F9, F10 |
| ARCH | 0 | — |

**Recommended fix-follow scope:** F1 + F2 + F3 + F4 in one commit
(small, related, all in BD-129 territory). NITs F5-F10 either fold
into the same commit if trivially small, or defer to next CI/test
hygiene batch.

The MUST-tier finding (F1) is the only ship-relevant one — the
regression test is dead from a CI perspective until F1 is fixed,
which means BD-129's claim of "regression-net coverage" is currently
undelivered.
