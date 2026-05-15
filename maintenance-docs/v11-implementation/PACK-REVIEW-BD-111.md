# PACK-REVIEW-BD-111 — first-class blocks/blocked-by via addBlockedBy + removeBlockedBy GraphQL

**Reviewer scope:** BD-111 (commit `0ec5eaf`; link + unlink combined per scope-extension `eca769b`)
**Reviewer:** pack-reviewer (per-BD = end-of-batch for single-BD Batch 18; 2026-05-15)
**Date:** 2026-05-15

## Summary

Verdict: **clean-with-MUSTs (3 MUST, 4 SHOULD, 5 NIT)**. The core implementation
(`addBlockedBy` / `removeBlockedBy` mutation chains, operand inversion for
`kind=blocks`, FORBIDDEN classifier patch, fixture-driven dispatch test
harness, comment-fallback preservation for `related|duplicates`) is correct,
well-tested, and lands cleanly. The 99/0 test result was independently
re-run and verified. validate-pack passes 32/32. Bash syntax is clean.
Public `provider_link` / `provider_unlink` shapes are unchanged.

The MUSTs are all about consistency / accuracy of supporting documentation
and a real downstream impact on the migrate-reverse decoder that is not
covered by the BD-111 §5 backwards-compat note: post-BD-111 `provider_link
... blocked-by` writes go to the first-class GH dependency edge and are
**no longer** readable by `tracker-migrate-reverse.sh:_tmr_decode_blockers`,
which still reads body comment markers only. No new BD is being requested
here — the question is whether the IMPL REPORT §5 conclusion ("No migration
script is required for v11.0") is correct given that the round-trip
property silently degrades for new writes. That conclusion needs revision
or an explicit follow-up task.

The SHOULDs cover (a) the EXTERNAL-RESEARCH section misattribution that
propagates across 6 sites in source + report + BACKLOG (cite `§1.5`
everywhere; actual section is `§1.3`), (b) two stale doc-comments in
sibling libs that still describe the comment-marker fallback as the
current behavior, (c) duplicated subsection in IMPL REPORT §6, (d)
mis-stated per-Group test counts in IMPL REPORT §6.

The NITs are wording fixes that don't affect correctness.

Counts: 3 MUST · 4 SHOULD · 5 NIT · 0 BLOCKER.

## Findings

### Finding F1
- **Severity:** MUST
- **Location:**
  - `scripts/lib/tracker-migrate-reverse.sh:367-378` (`_tmr_decode_blockers` — body-marker reader; UNCHANGED by BD-111)
  - `scripts/lib/tracker-migrate-forward.sh:951-959` (forward writer — now via BD-111 first-class API)
  - `scripts/tests/tracker-migrate-roundtrip-test.sh:308-355` (round-trip test still says "BD-111 pending — comment-fallback does not round-trip")
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:147-150` (§5 conclusion)
- **Title:** Round-trip migrate-reverse degrades silently for post-BD-111 writes; IMPL REPORT §5 conclusion is incorrect
- **Description:** The pre-BD-111 implementation wrote `Blocked by #N` as a
  comment on the issue body (via `tracker_provider_gh_comment`); the reverse
  decoder at `tracker-migrate-reverse.sh:341 _tmr_decode_blockers` reads the
  issue body for the regex `(?:Blocked by|blocked-by|blocks)[\s:]*#(\d+)`
  to reconstruct the `Blockers:` field. After BD-111, `provider_link
  blocked-by` writes a first-class `addBlockedBy` GraphQL edge and **no
  longer writes the body comment**. The reverse decoder is unchanged and
  has no path to query first-class dependency edges. So:
    1. The **forward orchestrator** (`tracker_migrate_forward.sh:951`) calls
       `tracker_links_create_blocked_by` → `provider_link "x" "y"
       "blocked-by"` → first-class `addBlockedBy` mutation.
    2. The **reverse decoder** still scans body text → finds nothing → the
       Blockers list is empty → round-trip is broken for new writes.
  IMPL REPORT §5 concludes "No migration script is required for v11.0 —
  the legacy markers are harmless." That's correct for **legacy reads**
  (pre-BD-111 markers persist and are still read), but **incorrect for
  new writes** (post-BD-111 first-class edges are invisible to the reverse
  decoder, so the round-trip property degrades).
  The round-trip test at `tracker-migrate-roundtrip-test.sh:316-328` is
  still passing the "BD-111 pending — comment-fallback does not round-trip"
  branch (lines 320-324); the comment at line 314 promises it "auto-flips
  to a positive round-trip check when BD-111 closes" but that flip will
  not happen with BD-111 alone — it needs the reverse decoder to also
  query the first-class edge graph (e.g., a new `getBlockedBy` GraphQL
  query in `_tmr_decode_blockers`).
- **Suggested fix:** Take ONE of:
  (a) Update IMPL REPORT §5 to acknowledge that post-BD-111 forward writes
      are not readable by the reverse decoder, list this as a documented
      gap in §9, and either propose a follow-up BD or accept the gap
      explicitly with a rationale.
  (b) Update the round-trip-test narrative comment at
      `tracker-migrate-roundtrip-test.sh:314-315` to reflect that BD-111
      alone does not close the gap; the gap closes only after the reverse
      decoder also adopts a first-class read path.
  (c) Surface this as scope for a separate BD (e.g., BD-NNN — extend
      `_tmr_decode_blockers` to query `getBlockedBy` first-class edges
      and fold them into the Blockers list).
  Per pack rule "BDs are reserved for new scope / new feature / new
  architecture," option (c) is justified — BD-111 documented its goal as
  the link/unlink swap, not the reverse-decoder retrofit. The decision is
  Pack Chat's; the review's job is to flag the gap.
- **Source:** IMPL REPORT §5 claim vs `tracker-migrate-reverse.sh:341-378`
  observable behavior; round-trip test annotation at lines 308-355.

### Finding F2
- **Severity:** MUST
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:189-220`
- **Title:** §6 "Fake-`gh` harness extension" subsection is duplicated verbatim
- **Description:** The subsection appears twice (lines 190-204 and 206-220)
  with near-identical content. The first occurrence ends with "now used
  by both 1.17 (link) and 1.20 (unlink) test suites"; the second says
  "All 22 pre-existing test cases in Group 1 still pass without
  modification." This is a merge artifact from the scope-extension
  follow-up — the coder added a second copy when updating §6 for the
  unlink suite without removing the original. Internal-consistency
  defect; misleading to a future maintainer who reads "this section
  was kept twice."
- **Suggested fix:** Delete one of the two subsections (preserve the
  first, which is the more accurate / scope-extension-aware version),
  keeping `reset_fake_gh()` line. Net delete ~15 lines.
- **Source:** Pack rule "implementation reports are factual"; §6
  internal duplication.

### Finding F3
- **Severity:** MUST
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:158-164`
- **Title:** §6 per-Group test counts are wrong (Group 1 claimed 79, actual 70; Group 3 claimed 12, actual 21)
- **Description:** §6 reports:
    ```
    Group 1 (happy-path):  79 PASS
    Group 2 (error map):    8 PASS
    Group 3 (stub backend): 12 PASS
    ─────────────────────────
    Total:                 99 PASS / 0 FAIL
    ```
  Independently re-running `bash scripts/tests/tracker-provider-test.sh`
  and counting PASS lines per group yields:
    - Group 1: **70** (not 79)
    - Group 2: 8 (matches)
    - Group 3: **21** (not 12)
    - Total: 99 (matches by coincidence; 70+8+21 = 99)
  The total is right but the per-group breakdown is wrong. The error
  may have come from miscounting sub-assertions in the BD-111 1.17a-e /
  1.20a-c suites. A future maintainer who tries to verify the per-group
  count will be confused.
- **Suggested fix:** Re-run the test suite and update §6 to:
    ```
    Group 1 (happy-path):  70 PASS
    Group 2 (error map):    8 PASS
    Group 3 (stub backend): 21 PASS
    ─────────────────────────
    Total:                 99 PASS / 0 FAIL
    ```
  Also reconcile the line in §6 that says "All 22 pre-existing test cases
  in Group 1 still pass without modification" — the baseline was 22 base
  tests numbered 1.1-1.22 (BD-060 era); 1.17 expanded into 1.17a-e,
  1.19 split into 2 assertions, 1.20a-c added, and 1.20→1.21 / 1.21→1.22
  / 1.22→1.23 renumbered. Group 1 pass-count (70) reflects the post-BD-111
  expansion; the baseline-22 count is no longer Group 1's actual pass count.
- **Source:** IMPL REPORT §6 per-group counts vs actual test-runner output.

### Finding F4
- **Severity:** SHOULD
- **Location:** Multiple — six sites total
  - `scripts/lib/tracker-provider-gh.sh:23` (head-of-file Reference block; pre-existing from BD-060 — not introduced by BD-111 but propagated by BD-111's new comments)
  - `scripts/lib/tracker-provider-gh.sh:72` (FORBIDDEN classifier comment)
  - `scripts/lib/tracker-provider-gh.sh:481` (link function header)
  - `scripts/lib/tracker-provider-gh.sh:482` (link function header — 2nd cite)
  - `scripts/lib/tracker-provider-gh.sh:559` (unlink function header)
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:44, 45, 59, 71, 96, 317`
  - `BACKLOG.md:980` (BD-111 Description block; pre-existing from when BD was opened)
- **Title:** EXTERNAL-RESEARCH §1.5 references should be §1.3 (issue dependencies section)
- **Description:** Every BD-111 site that cites `EXTERNAL-RESEARCH §1.5`
  for the addBlockedBy / removeBlockedBy / FORBIDDEN evidence basis is
  pointing at the wrong section. The actual issue-dependencies section
  is `§1.3 Issue dependencies (Blocks / Blocked by)` at lines 78-94.
  `§1.5` is `Projects (Projects v2)` at lines 121-138 — completely
  unrelated. Line numbers cited (line 86 / 87) are correct (they fall
  in §1.3); section number is wrong throughout. A future maintainer
  trying to verify the cite will jump to §1.5, see Projects v2 content,
  and be unable to corroborate the addBlockedBy claim.
  This misattribution is partially pre-existing (the pack head-of-file
  comment at line 23 and the BACKLOG Description at line 980 inherited
  the bad cite from BD-060 era) but BD-111 propagated it into 4 new
  source-code comment sites + 6 IMPL REPORT sites without catching
  the error.
- **Suggested fix:** Replace all 12+ occurrences of `EXTERNAL-RESEARCH §1.5`
  with `EXTERNAL-RESEARCH §1.3` (preserving the line-86 / line-87 line
  numbers, which are correct). Optionally also fix the head-of-file comment
  (`scripts/lib/tracker-provider-gh.sh:23`) and the BACKLOG description
  (`BACKLOG.md:980`) — these are pre-existing but cleanly addressable in
  the BD-111 scope-fix pass since the file is being touched.
- **Source:** EXTERNAL-RESEARCH.md heading inventory:
  `### 1.3 Issue dependencies (Blocks / Blocked by)` at line 78;
  `### 1.5 Projects (Projects v2)` at line 121.

### Finding F5
- **Severity:** SHOULD
- **Location:**
  - `scripts/lib/tracker-links.sh:84` ("V1 §2.7.1 row 12; comment-marker fallback "Blocked by #NNN" until the GraphQL issue-dependency mutation is wired")
  - `scripts/lib/tracker-links.sh:235-238` (in `tracker_links_create_blocked_by`: "The github backend currently uses a comment-marker fallback for blocked-by per V1 §2.7.1 row 12")
  - `scripts/tests/tracker-migrate-forward-test.sh:989` ("which falls back to a `gh issue comment "Blocked by #NNN"` call")
- **Title:** Stale doc-comments in sibling libs/tests still describe the comment-marker fallback as the current behavior
- **Description:** Three sites in code adjacent to the BD-111 change still
  describe the BD-060-era comment-marker fallback as the current behavior.
  `tracker-links.sh:84` and `tracker-links.sh:235` are passive descriptive
  comments (not load-bearing logic) that explain what `provider_link
  blocked-by` does; with BD-111 the description is wrong (no comment-write
  happens; `addBlockedBy` GraphQL is invoked). `tracker-migrate-forward-test.sh:989`
  similarly says "which falls back to a `gh issue comment` call" describing
  the F3a routing — also stale. None of these affect runtime behavior, but
  they will mislead any future maintainer reading the source for context.
- **Suggested fix:** In `tracker-links.sh:84`, change "comment-marker
  fallback "Blocked by #NNN" until the GraphQL issue-dependency mutation
  is wired" to "first-class `addBlockedBy` GraphQL mutation per BD-111
  (formerly comment-marker fallback "Blocked by #NNN" — V1 §2.7.1 row
  12 + BD-111 swap)". In `tracker-links.sh:235-238`, change "currently
  uses a comment-marker fallback for blocked-by" to "uses the first-class
  `addBlockedBy` GraphQL mutation per BD-111". In `tracker-migrate-forward-test.sh:989`,
  change "(which falls back to a `gh issue comment "Blocked by #NNN"`
  call)" to "(which routes through `provider_link blocked-by` →
  `addBlockedBy` GraphQL per BD-111)".
- **Source:** BD-111's swap of `tracker_provider_gh_link` `blocks|blocked-by`
  case from `tracker_provider_gh_comment` to `addBlockedBy`.

### Finding F6
- **Severity:** SHOULD
- **Location:** `scripts/tests/tracker-provider-test.sh:362-369` (1.17c) and `:461-470` (1.20c)
- **Title:** Error-path tests fail at the FIRST gh call (`gh repo view`), not at the GraphQL mutation step the comment claims
- **Description:** Test 1.17c is documented as "GraphQL error path
  (simulated EMU FORBIDDEN response) — fail the api-graphql call and
  verify a typed error is emitted." But the test sets `FAKE_GH_EXIT=1`
  globally (which applies to ALL gh calls, not just the GraphQL one)
  and `FAKE_GH_STDERR_FILE=emu_err_file`. The link chain's first call
  is `gh repo view --json nameWithOwner --jq .nameWithOwner` (line
  515 of tracker-provider-gh.sh) — that call exits 1 with the EMU
  stderr, the classifier maps FORBIDDEN → `auth-insufficient-scope`,
  and `_gh_run` returns 1. The chain short-circuits BEFORE reaching
  the api-graphql step. Same for 1.20c (the test stops at `gh repo
  view` with a 404, never reaches `removeBlockedBy`).
  The typed error code is nonetheless correct
  (`auth-insufficient-scope` for FORBIDDEN; `not-found` for 404), so
  the assertion passes. But the test's narrative is misleading — a
  future maintainer reading the comment would conclude that the
  api-graphql failure was tested, when in reality the
  `gh repo view` failure was tested. The wire-shape behavior is the
  same in both cases (because the classifier doesn't care which gh
  call produced the stderr), so this is not a coverage gap; it's a
  test-clarity issue.
- **Suggested fix:** Two acceptable resolutions:
  (a) Update the test comments to reflect what's actually tested:
      "1.17c: When ANY gh call in the link chain fails with EMU
      FORBIDDEN stderr, the typed error should be `auth-insufficient-scope`."
  (b) Use the dispatch-mode harness to make ONLY the api-graphql call
      fail (e.g., write a `api-graphql` fixture that contains an error
      response and write a separate fake-gh hook that reads the input
      and returns nonzero only when v1==api && v2==graphql). This
      would faithfully test the GraphQL-step failure path. Option (b)
      requires a small extension to the dispatch harness.
  Option (a) is sufficient for the BD-111 fix-pass; option (b) is
  better future-test infrastructure but out of scope.
- **Source:** Test 1.17c / 1.20c narrative comments vs actual `_gh_run`
  short-circuit behavior at `tracker-provider-gh.sh:111-117`.

### Finding F7
- **Severity:** SHOULD
- **Location:** `scripts/tests/tracker-provider-test.sh:339`
- **Title:** Test 1.17a "does NOT comment on issue body" assertion checks the wrong thing
- **Description:** The line is:
    ```bash
    assert_contains "1.17a does NOT comment on issue body" "$log_contents" "graphql"
    ```
  The label says "does NOT comment on issue body" but the assertion is
  a POSITIVE check that the log contains "graphql" — it asserts the
  presence of "graphql," not the absence of a comment-write. That
  positive check is functionally redundant with line 336 (which already
  asserts `addBlockedBy` is in the log; finding `addBlockedBy` implies
  the GraphQL call happened). The actual negative check ("does not
  invoke `issue comment`") is correctly performed by the if/grep block
  on lines 341-345. The misleading label on line 339 is harmless to
  test correctness but confusing to read.
- **Suggested fix:** Either (a) delete line 339 (it's redundant with
  line 336's `addBlockedBy` check and lines 341-345's negative check),
  or (b) rename the label to "1.17a invokes graphql verb (positive
  cross-check)". Option (a) is cleaner.
- **Source:** Test code at line 339; if/grep idiom at 341-345 already
  covers the intended negative assertion.

### Finding F8
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-provider-gh.sh:498`
- **Title:** Comment cite "see ARCHITECTURE.md §2.4 line 334" points to a Blockers/Unblocks mapping note, not a fallback-escape-hatch documentation
- **Description:** Line 498 says "(the V3 §28 fallback path is preserved
  as an escape hatch; see ARCHITECTURE.md §2.4 line 334)." Reading
  ARCHITECTURE.md line 334-338, the actual content is "The pack's
  BACKLOG entry format already uses two kinds — `Blockers` and
  `Unblocks` (METHODOLOGY § Part 7 line 994). These map to `blocked-by`
  and its inverse..." This is unrelated to the comment-marker fallback
  escape hatch; it's about how the BACKLOG fields map to link.kind. The
  cite is misleading. (Separately, "V3 §28" is also wrong: V3 §28 is
  about pack-help and recommendations — the comment-marker fallback
  is not codified in any numbered section.)
- **Suggested fix:** Drop the "ARCHITECTURE.md §2.4 line 334" cite (it
  doesn't support the claim). Optionally also drop or qualify the "V3
  §28 fallback path" reference — it's a colloquial reference to BD-060's
  fallback behavior, not a section in any architecture doc.
- **Source:** ARCHITECTURE.md §2.4 line 334-338 actual content vs the
  cite's claim; ARCHITECTURE-V3.md §28 actual scope (pack-help / OQ-19 / OQ-20).

### Finding F9
- **Severity:** NIT
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:96`
- **Title:** §3 cites "V1 §9.4" for `auth-insufficient-scope` but ARCHITECTURE.md §2.5 has no §9.4 subdivision
- **Description:** §3 says "EMU `FORBIDDEN: Unauthorized; path:
  addBlockedBy` → typed `auth-insufficient-scope` (V1 §9.4)." The
  pack's V1-equivalent architecture doc (ARCHITECTURE.md) lists typed
  error codes in §2.5 (lines 340-372) without §9.4 subsection
  numbering — `auth-insufficient-scope` is in the §2.5 table at line
  355. The §9.4 cite is either pointing at a non-existent subsection
  or relying on a numbering convention that no longer holds.
- **Suggested fix:** Change "V1 §9.4" to "ARCHITECTURE.md §2.5 (typed
  error codes table)".
- **Source:** ARCHITECTURE.md §2.5 lines 340-372 actual structure.

### Finding F10
- **Severity:** NIT
- **Location:** `BACKLOG.md:974-977` (BD-111 File/Symbol field)
- **Title:** File/Symbol does not list `_gh_classify_error` as touched
- **Description:** The BD-111 implementation also added `*"FORBIDDEN"*`
  to `_gh_classify_error` at line 69 of `tracker-provider-gh.sh`. The
  File/Symbol field lists only `tracker_provider_gh_link()` and
  `tracker_provider_gh_unlink()`. The classifier change is small and
  arguably folded into "everything `addBlockedBy` needs to work,"
  but for traceability completeness, the helper should be named.
- **Suggested fix:** Append "+ `_gh_classify_error` (FORBIDDEN
  pattern addition for EMU wire shape)" to the File/Symbol field.
  This is a NIT — the surface change is small and the cross-reference
  in §3 of IMPL REPORT covers the audit trail.
- **Source:** Diff at `tracker-provider-gh.sh:69`.

### Finding F11
- **Severity:** NIT
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:51, 61, 280`
- **Title:** Worst-case fix-up size estimate is inconsistent (one line vs ≤8 lines)
- **Description:** §2 line 51 says the wrong-guess fix is "one line in
  the mutation string below plus one fixture line update." §2 line 61
  says "one-line edit at `tracker-provider-gh.sh:527` + two
  test-assertion key updates." §2 follow-up line 85 says "one-line
  edit at `tracker-provider-gh.sh` `tracker_provider_gh_unlink()`
  GraphQL string + one fixture key in `gh-remove-blocked-by.json`."
  §7 line 296 says "Worst-case fix-up footprint if any name-guess
  is wrong (combined add + remove sides): ≤ 8 lines across
  `tracker-provider-gh.sh` + 4 lines across the two fixture files +
  ~6 test-assertion key updates." The numbers are roughly consistent
  but the pattern of "one line + N test-assertion updates" doesn't
  consistently account for the test assertions in the per-component
  estimates. Not a defect; just modestly imprecise.
- **Suggested fix:** Either standardize the footprint estimate format
  (per-component: M code-lines + N fixture-lines + P test-assertion
  updates) or just keep the §7 line 296 combined estimate as the
  authoritative number and remove the per-component sub-estimates.
- **Source:** IMPL REPORT internal cross-comparison.

### Finding F12
- **Severity:** NIT
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md:166-188`
- **Title:** Test renumbering language is consistent but the displayed sub-counts mix labels and assertion counts
- **Description:** §6 lists "1.17a: kind=blocked-by → ... (9 sub-assertions
  including negative...)" and "1.17b ... (5 sub-assertions)" etc. Counting
  sub-assertions vs labels differs: assert_eq, assert_contains, and the
  if/grep blocks each emit one PASS line; the IMPL REPORT's "9 sub-assertions"
  is correct for 1.17a (2 assert_eq + 7 assert_contains + 1 if-grep PASS = 10;
  or 9 if you exclude line 339). Slightly fuzzy but not load-bearing.
- **Suggested fix:** Either drop the per-test sub-assertion counts (the
  total at the top is the authoritative number) or align them precisely
  by re-counting from PASS-line output.
- **Source:** IMPL REPORT §6 sub-assertion counts vs actual test PASS lines.

## Coverage notes

- Reviewed `git show 0ec5eaf` and `git diff eca769b..0ec5eaf` end-to-end.
  Read `IMPLEMENTATION-REPORT-BD-111.md` §1-§9 + DoD; read both fixture
  files; read the full `tracker_provider_gh_link()` and
  `tracker_provider_gh_unlink()` post-change in
  `scripts/lib/tracker-provider-gh.sh`; read tests 1.17a-e + 1.18-1.19 +
  1.20a-c + 1.21-1.23 in `scripts/tests/tracker-provider-test.sh`. Read
  `scripts/lib/tracker-provider.sh:136-137` to verify the public dispatch
  signature is unchanged. Read `scripts/lib/tracker-errors.sh` (typed-error
  surface; no changes needed). Read `scripts/lib/tracker-migrate-reverse.sh:325-378`
  (the body-comment-marker reader; basis of F1). Read `scripts/lib/tracker-links.sh:79-95, 230-243`
  (callers of `provider_link`; basis of F5). Read `scripts/lib/tracker-migrate-forward.sh:902-1003`
  (forward orchestrator routing; basis of F1's downstream impact).
- **Independently re-ran tests:**
    - `bash scripts/tests/tracker-provider-test.sh` → 99 PASS / 0 FAIL ✓
    - `bash scripts/tests/test-tracker-cycle-check.sh` → 26 PASS / 0 FAIL
    - `bash scripts/tests/test-tracker-links.sh` → 43 PASS / 0 FAIL
    - `bash scripts/tests/tracker-errors-test.sh` → 60 PASS / 0 FAIL
    - `bash scripts/tests/test-tracker-promote-{direct,path1,path2}.sh` → 31 / 80 / 59 PASS / 0 FAIL each
    - `bash scripts/tests/test-tracker-phase-task.sh` → 90 PASS / 0 FAIL
    - `bash scripts/tests/tracker-migrate-roundtrip-test.sh` → 45 PASS / 0 FAIL (with the BD-111-pending narrative branch still firing — basis of F1 sub-finding)
    - `bash scripts/tests/tracker-migrate-forward-test.sh` → 134 PASS / 0 FAIL (Group 6 BD-108 routing intact — basis of F5 stale-comment finding)
    - `python3 scripts/validate-pack.py` → 32/32 OK ✓
    - `bash -n` syntax check on both modified .sh files → OK_SYNTAX ✓
- **Trinity rule:** N/A — no edits to any of CLAUDE.md / AGENTS.md /
  GEMINI.md (root or `project-template/`).
- **Validate-pack alignment:** No new directories or top-level files
  were added. Two new fixtures land in the existing
  `scripts/tests/fixtures/tracker-provider/` directory (alongside
  `gh-issue-list.json`, `gh-issue-view.json`, `stub-backend.sh`).
  validate-pack does not enumerate this fixture directory; no Check
  alignment is required.
- **Migration safety:** F1 is the migration-safety finding. Beyond F1,
  there are no MIGRATION-guide or QUICKSTART changes implied by BD-111.
- **README repository layout:** `README.md` does not list
  `scripts/tests/fixtures/`, so the fixture additions don't require a
  layout update. Verified via grep — only `tracker-provider.sh` and
  `tracker-provider-gh.sh` are listed at lines 201-202; no fixture
  inventory is maintained.
- **BACKLOG entry accuracy:** Status: Open with the 2026-05-15 backstamp
  is correct for review-time. Per pack memory "Implicit BD status flip
  on batch completion," Pack Chat will flip to Resolved as the final
  step of the batch — not in scope for this review.
- **Pack memory `feedback_no_prior_reviews_to_reviewer` compliance:**
  Confirmed — this review did not read any prior `PACK-REVIEW-*.md`
  file. References were limited to ARCHITECTURE / EXTERNAL-RESEARCH /
  IMPL REPORT (allowed inputs).
- **§9 known limitations escalation check:** §9 item 1 (cycle / cap
  error wire shapes routed through generic `validation` — to be
  tightened at integration-test land-time) is correctly scoped as a
  known limitation; it's appropriate for offline scope. §9 item 6
  (re-verified comment-fallback footprint) is accurate. **§9 item 1
  also correctly notes "N/A on the unlink side."** None of the listed
  §9 limitations need escalation to a finding — they're correctly
  classified as accept-with-follow-up. The unlisted gap is what F1
  flags (the reverse decoder retrofit).
- **No state-changing git verbs run.** Only `git status` / `git diff`
  / `git log` / `git rev-parse` / `git show` were used.
