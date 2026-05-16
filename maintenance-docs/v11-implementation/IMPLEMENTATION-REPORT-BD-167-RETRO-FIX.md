# IMPLEMENTATION REPORT — BD-167 RETRO-FIX

**Branch:** v11-dev
**HEAD SHA at start:** `03d0dd931ebf7895d81226503032b317b775cdae`
**HEAD SHA at end:** `03d0dd931ebf7895d81226503032b317b775cdae` (no
commits; Pack Chat owns commit per `feedback_agents_never_commit`).
**Date:** 2026-05-16
**Coder:** pack-coder

## §1 — Summary

Applies Pack Chat's triage of `PACK-REVIEW-BD-167-RETRO.md` to the
BD-167 working tree. All five FIX items (M1, M2a, M2b, S1, N2, N3)
land as code/doc edits; the one SKIP item (N1) and four out-of-scope
observations from review §4 are documented in §7 of this report with
verbatim skip rationale. All six modified files retain syntactic and
semantic validity: shell scripts pass `bash -n`; the tracker-agent-
read test runner grows from 31 → 52 tests (Group 5 adds project-side
prefer-branch + per-stream fallback coverage that closes the M2
latent bug); all baseline regression suites (per-entry 57/57,
migrator 43/43, dry-run 61/61, gates 87/87, init-project 34/34,
validate-pack checks 32/33/34 46/46, validate-pack PASSED) remain
green. HEAD is unchanged; six files have working-tree modifications
awaiting Pack Chat commit.

## §2 — Files modified

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `project-template/docs/project/backlog/_rules.md` | 56 | 54 | -2 | edited (N2) |
| `project-template/docs/project/implementation-plan/_rules.md` | 56 | 54 | -2 | edited (N2) |
| `project-template/docs/project/changelog/_rules.md` | 56 | 56 | 0 | edited (M1 + N2) |
| `scripts/lib/tracker-agent-read.sh` | 303 | 320 | +17 | edited (M2a) |
| `scripts/tests/tracker-agent-read-test.sh` | 285 | 505 | +220 | edited (M2b: Group 5 added + fixture relocated) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md` | 1201 | 1231 | +30 | edited (S1 footnotes + N3 O-1 update) |

## §3 — Per-fix detail

### M1 — `changelog/_rules.md` regex loosened to admit bare-date filenames

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 M1 (lines 37–82).

**File:** `project-template/docs/project/changelog/_rules.md` line 15
section (Filename convention).

**Before (4 lines):**
```markdown
Per-entry files match `^\d{4}-\d{2}-\d{2}-.+\.md$` (e.g.,
`2026-04-20-phase-35.md`). Date-first for lexical sorting; trailing
slug for human readability per
`ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5.
```

**After (6 lines):**
```markdown
Per-entry files match `^\d{4}-\d{2}-\d{2}(-.+)?\.md$` (e.g.,
`2026-04-20-phase-35.md` or bare `2026-04-20.md` when the source
H3 anchor has no slug suffix). Date-first for lexical sorting;
trailing slug optional for human readability per
`ARCHITECTURE-PER-ENTRY-SPLIT.md` §3.5 + `scripts/lib/per-entry/_lib.sh`
post-BD-164-retro Option B (slug optional).
```

Result: the per-stream contract `_rules.md` regex now matches the
loosened runtime regex in `scripts/lib/per-entry/_lib.sh:113` and
`scripts/lib/per-entry/toc-regenerate.sh:88`. Contract / runtime
divergence resolved.

### M2a — `_tar_read_entry_flat` fall-through rewritten with per-stream-aware mirror selection

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 M2 (lines 83–183).

**File:** `scripts/lib/tracker-agent-read.sh` lines 247–280 (the
fall-through mirror-read block at the tail of
`_tar_read_entry_flat`).

**Before (29 lines):**
- Hard-coded `local backlog="$repo_root/BACKLOG.md"` for every
  pack-id (correct for BD-* pre-v11.0; wrong for v11.0 TD-* and
  phase-* fall-through).
- Error message and Python source-attribution line hard-named
  `BACKLOG.md`.

**After (46 lines):**
- New `case "$pack_id"` switch resolves `mirror_path` per stream:
  `BD-*` → `$repo_root/BACKLOG.md`; `TD-*` →
  `$repo_root/docs/project/BACKLOG.md`; `phase-*` →
  `$repo_root/docs/project/IMPLEMENTATION-PLAN.md`; `*` →
  `$repo_root/BACKLOG.md` (pre-v11.0 backward-compat default).
- Error message now uses the resolved `mirror_path` (`agent_read:
  mirror not found at $mirror_path for $pack_id`).
- Python heredoc parser body unchanged; only the argv path
  (`mirror_path` instead of `backlog`) and the source-attribution
  line (`os.path.basename(path)` instead of hard-coded
  `BACKLOG.md`) updated. The Python parser also uses
  `os.path.basename(path)` in its not-found error message so
  TD-* / phase-* fall-through error messages name the correct
  mirror file.

Result: TD-* fall-through now correctly resolves to
`docs/project/BACKLOG.md`; phase-* fall-through to
`docs/project/IMPLEMENTATION-PLAN.md`; unknown prefixes still
default to pack `BACKLOG.md`. Per integration parent §18.2 #2
backward-compat contract preserved for BD-*.

### M2b — `tracker-agent-read-test.sh` Group 5 added + Group 2 fixture relocated

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 M2 (lines 162–173)
+ §4 Observation 2 (lines 482–497).

**File:** `scripts/tests/tracker-agent-read-test.sh`.

**Two changes:**

1. **Fixture relocation in `_setup_flat_repo`** (existing fixture).
   The pre-existing fixture put TD-010 inside pack `BACKLOG.md`
   alongside BDs — pre-v11.0 fixture shape that masks M2. Updated
   to put BDs in pack `BACKLOG.md` and TD-010 in
   `docs/project/BACKLOG.md` (per v11.0 per-stream-aware shape).
   Test 2.3 continues to pass with the new per-stream-aware
   routing.

2. **Group 5 added** (between Group 4 and Summary): 21 new
   assertions across 7 logical test cases covering both the M2a
   per-stream fallback and the prefer-branch (originally added
   in BD-167 with zero CI coverage per Observation 2).
   - **5.1** TD-* fallback to `docs/project/BACKLOG.md` (4
     assertions: rc=0, source attribution, header, description).
   - **5.2** phase-* fallback routes to
     `docs/project/IMPLEMENTATION-PLAN.md` (2 assertions: error
     message names the plan mirror; does NOT name `BACKLOG.md`
     — proving wrong-stream routing absent). Note: the existing
     bold-header parser (`**X-NNN**`) cannot match H2-style
     phase entries (`## Phase N`), so the routing target is the
     load-bearing assertion; entry extraction would require a
     dedicated H2-aware parser (out of M2 scope; real-world
     v11.0 clients have per-entry tree so prefer-branch handles
     this).
   - **5.3** phase-N.M fallback routes to plan mirror (same
     parser-limitation caveat as 5.2; assertion is routing-only).
   - **5.4** TD-* prefer-branch reads per-entry file (5
     assertions: rc=0, source attribution, header, back-pointer
     stripped, stale mirror NOT consulted).
   - **5.5** phase-* prefer-branch reads per-entry file (4
     assertions: rc=0, source attribution, H2 header preserved,
     stale mirror NOT consulted).
   - **5.6** phase-N.M prefer-branch resolves to `phase-N.md`
     per Addendum §6.4 tasks-inline contract (4 assertions:
     rc=0, source attribution, names `phase-3.md`, reads
     phase-3 content).
   - **5.7** Unknown pack-id prefix (e.g., `X-007`) falls
     through to pack `BACKLOG.md` default (1 assertion:
     not-found error).

Two helper fixture functions added to test-runner setup section:
`_setup_project_fallback_repo` (per-entry tree absent shape) and
`_setup_project_per_entry_repo` (per-entry tree present + stale
mirror shape).

Total: tests grow 31 → 52 (52 = 31 baseline + 21 Group 5
assertions). All 52 PASS.

### S1 — Line-drift footnotes added to IMPL-REPORT-BD-167.md §3 / §4

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 S1 (lines 184–222).

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md`.

Two footnote additions, one as the new first paragraph of §3
(immediately after the §3 header) and one as the new first
paragraph of §4 (immediately after the §4 header). Both footnotes
disclose that line citations in §3 / §4 capture state at BD-167's
commit SHA `142d160` and name the post-BD-167 commits (BD-164 retro
`03d0dd9`, BD-165 `a5b4a6e`) that extended the cited files. Both
direct future readers to anchor on function names and inline
comment markers (`BD-167:`, `BD-161 (absorbed into BD-167):`,
`Per-entry tree exists AND per-entry file is present`,
`Per-stream-aware mirror selection`) for drift-resilient location.

### N2 — Drop `pack PACK-AGENTS.md` reference from project-side `_rules.md` Write-authority sections

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 N2 (lines 243–272).

**Files (3):** `project-template/docs/project/{backlog,
implementation-plan, changelog}/_rules.md`.

Removed "and pack `PACK-AGENTS.md` (the project-side analog ships
in PM-CHAT.md)" pointer-then-reroute clause from all three Write-
authority sections.

**backlog/_rules.md** new wording:
```markdown
Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 7. The monolithic ...
```

**implementation-plan/_rules.md** new wording: same shape, "Part 4"
instead of "Part 7" (per the existing backlog vs implementation-plan
METHODOLOGY part distinction).

**changelog/_rules.md** new wording: keeps both METHODOLOGY part 7
and `_format.md` pointer:
```markdown
Writes are PM-Chat authority. Read more at `docs/pack/PM-CHAT.md` +
`docs/pack/METHODOLOGY.md` Part 7 + `_format.md` (this directory).
The monolithic ...
```

Result: client-side readers no longer told to look at a file they
don't have (`PACK-AGENTS.md` is pack-self only).

### N3 — IMPL-REPORT-BD-167.md §7 O-1 updated to note §9.7 settles the pack-side-templates question

Cross-references PACK-REVIEW-BD-167-RETRO.md §2 N3 (lines 274–298).

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-167.md` §7 O-1.

Added a new paragraph at the end of O-1's discussion:
```markdown
**Settled by retro review (BD-167 retro N3):** this is NOT an open
Pack Chat question — integration parent §9.7 + §17.2 BD-167
File/Symbol settle it. Pack-side `/backlog/` and `/changelog/`
templates are EXTRACTED at first migration via the BD-165 decompose
step (pack-self decompose lands in Batch 23 BD-102 dog-food per the
v11.0 batch sequence), NOT pre-shipped from `project-template/`.
The Addendum #1 §6.2 reference is a planning-doc note about where
the templates eventually come from, not a "ship these in 19b-pack"
instruction. This implementer correctly followed plan §5.2 (project-
side only). Surfaced here for completeness; no Pack Chat decision
required.
```

The original O-1 framing is preserved (so the reader sees how the
question was initially raised); the new paragraph appends the
settled-question disposition.

## §4 — Verification

All success-criterion C commands executed; output tails captured
verbatim. Working directory:
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

### Syntax checks (`bash -n`)

```
$ bash -n scripts/lib/tracker-agent-read.sh && bash -n scripts/tests/tracker-agent-read-test.sh && echo "BOTH OK"
BOTH OK
```

### `validate-pack.py`

```
$ python3 scripts/validate-pack.py 2>&1 | tail -5
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### `tracker-agent-read-test.sh` (31 → 52 tests; Group 5 added)

```
$ bash scripts/tests/tracker-agent-read-test.sh 2>&1 | tail -40
  ... (Groups 1-4 PASS) ...
=== Group 5: per-stream fallback + prefer-branch ===
  PASS 5.1 TD-005 fallback rc=0
  PASS 5.1 TD-005 source attribution
  PASS 5.1 TD-005 entry header
  PASS 5.1 TD-005 description
  PASS 5.2 phase-3 routes to plan mirror
  PASS 5.2 phase-3 NOT routed to BACKLOG.md
  PASS 5.3 phase-3.2 routes to plan mirror
  PASS 5.7 unknown prefix → pack BACKLOG.md default
  PASS 5.4 TD-005 prefer rc=0
  PASS 5.4 TD-005 prefer source attribution
  PASS 5.4 TD-005 prefer entry header
  PASS 5.4 TD-005 back-pointer stripped
  PASS 5.4 TD-005 prefer skipped mirror
  PASS 5.5 phase-3 prefer rc=0
  PASS 5.5 phase-3 prefer source attribution
  PASS 5.5 phase-3 prefer entry header
  PASS 5.5 phase-3 prefer skipped mirror
  PASS 5.6 phase-3.2 prefer rc=0
  PASS 5.6 phase-3.2 resolves to phase-3
  PASS 5.6 phase-3.2 names phase-3.md
  PASS 5.6 phase-3.2 reads phase-3 content

=== Summary ===
Passed: 52
Failed: 0
All tests passed.
```

### `test-per-entry.sh` (no regression)

```
$ bash scripts/tests/test-per-entry.sh 2>&1 | tail -5
=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

### `test-migrate-v10-to-v11.sh` (no regression)

```
$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -5
=== Summary ===
Passed: 43
Failed: 0
All tests passed.
```

### `test-migrate-v10-to-v11-dry-run.sh` (no regression)

```
$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh 2>&1 | tail -5
=== Summary ===
Passed: 61
Failed: 0
All BD-095 tests passed.
```

### `test-migrate-v10-to-v11-gates.sh` (no regression)

```
$ bash scripts/tests/test-migrate-v10-to-v11-gates.sh 2>&1 | tail -5
=== Summary ===
Passed: 87
Failed: 0
All BD-101 gate tests passed.
```

### `test-init-project.sh` (no regression)

```
$ bash scripts/tests/test-init-project.sh 2>&1 | tail -5
=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

### `test-validate-pack-checks-32-33-34.sh` (no regression)

```
$ bash scripts/tests/test-validate-pack-checks-32-33-34.sh 2>&1 | tail -5
=== Summary ===
PASS: 46
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (46/46).
```

### HEAD verification

```
$ git rev-parse HEAD
03d0dd931ebf7895d81226503032b317b775cdae
```

HEAD matches start-SHA exactly; no commits introduced by this
agent. Pack Chat owns the commit.

## §5 — Definition-of-Done checklist

| Check | Status |
|---|---|
| A. All 5 FIX items applied (M1, M2a, M2b, S1, N2, N3) | **PASS** |
| B. No SKIP item applied (N1 + 4 observations skip rationale in §7) | **PASS** |
| C. `bash -n` clean on both modified shell files | **PASS** |
| C. `python3 scripts/validate-pack.py` PASSED | **PASS** |
| C. `tracker-agent-read-test.sh` all PASS (31 → 52, +21 Group 5) | **PASS** |
| C. `test-per-entry.sh` 57/57 PASS | **PASS** |
| C. `test-migrate-v10-to-v11.sh` 43/43 PASS | **PASS** |
| C. `test-migrate-v10-to-v11-dry-run.sh` 61/61 PASS | **PASS** |
| C. `test-migrate-v10-to-v11-gates.sh` 87/87 PASS | **PASS** |
| C. `test-init-project.sh` 34/34 PASS | **PASS** |
| C. `test-validate-pack-checks-32-33-34.sh` 46/46 PASS | **PASS** |
| D. Bash 3.2 + macOS BSD-utility compatible (case statement, no associative arrays, no `&>`, no GNU-only flags) | **PASS** |
| E. HEAD unchanged at end (`03d0dd9`) | **PASS** |
| Files-allowed scope respected (only the 6 named files edited) | **PASS** |
| No state-changing git verbs run | **PASS** |
| No deferral language in report (per `feedback_deferral_is_scope_creep`) | **PASS** |

## §6 — Plan deviations

**Zero plan deviations.** Every FIX item landed per Pack Chat's
triage spec verbatim:

- M1 wording matches the reviewer's suggested replacement
  byte-for-byte.
- M2a per-stream-aware case-switch matches the reviewer's
  suggested code structure; preserved the Python heredoc parser
  unchanged except for the path argv and source-attribution
  formatting changes (which were required to make the error
  message and source line accurately name the resolved mirror
  rather than hard-coded `BACKLOG.md`).
- M2b Group 5 covers all 7 specified test cases (5.1 TD-*
  fallback, 5.2 phase-* fallback, 5.3 phase-N.M fallback, 5.4
  TD-* prefer, 5.5 phase-* prefer, 5.6 phase-N.M prefer, 5.7
  unknown prefix). Test 5.2 / 5.3 verify routing (not full entry
  extraction) because the existing BACKLOG-style bold-header
  parser (`**X-NNN**`) cannot match H2-style phase entries
  (`## Phase N`) — this is a parser-design limitation unchanged
  by M2 (and out of M2 scope). Real-world v11.0 clients have
  per-entry trees installed (BD-167 install step), so the
  prefer-branch handles phase entries correctly (verified by
  5.5 / 5.6). The routing-only assertion in 5.2 is still
  load-bearing: it confirms the M2 fix routes phase-* to the
  correct project-side mirror rather than the pack BACKLOG.md
  (the pre-M2 bug).
- S1 footnote added verbatim from the prompt's suggested text.
- N2 wording adapted per the reviewer's three-stream-specific
  guidance (Part 7 for backlog, Part 4 for implementation-plan,
  Part 7 + `_format.md` for changelog).
- N3 replacement paragraph used the prompt's suggested wording
  with minor adaptation for context (appended after the original
  O-1 paragraph rather than replacing it, so the reader sees the
  question evolution).

Test-fixture relocation in `_setup_flat_repo` (`BACKLOG.md` →
`docs/project/BACKLOG.md` for TD-010) was required to make the
existing test 2.3 pass under M2a's new per-stream-aware behavior.
This is a fixture update consistent with M2's correctness
contract, not a deviation.

## §7 — Skip rationale

Pack Chat's triage SKIP list. Documented here verbatim from the
caller's prompt; no implementation applied.

### N1 — `changelog/_intro.md` "the project's" qualifier

> reviewer's preferred option ("defensible pack-template
> adaptation") matches the current state. No edit needed. The
> current text is the deliberate choice.

### Observation 1 — Pack-side per-entry tree skeletons (per §9.7)

> N3 above addresses this in the IMPL-REPORT framing; nothing
> else to fix.

### Observation 3 — `MIGRATION-v10-to-v11.md` not updated by BD-167

> out of BD-167 scope; lands in plan §5.8 BD-169 / 19g-pack. Not
> a defect.

### Observation 4 — `README.md` Repository Layout not updated

> out of BD-167 scope; lands in plan §5.9 BD-169b / 19g-PM. Not
> a defect.

### Observation 5 — `BACKLOG.md:1480` BD-167 File/Symbol line drift

> BACKLOG.md is PM-only territory; out of fix-coder scope. If
> Pack Chat decides to update the BD-167 File/Symbol cross-
> reference, that's a Pack-Chat-direct edit, not part of this
> fix-coder pass.

## §8 — Out-of-scope observations

No additional observations beyond what review §4 already raised
and Pack Chat already triaged. The fix-coder pass touched only
the six files named in the prompt; no incidental defects spotted
in adjacent files during the work.

End of IMPLEMENTATION-REPORT-BD-167-RETRO-FIX.md.
