# PACK-REVIEW-BD-106 — Phase task entity model + identifier scheme + parser/emitter

**Reviewer scope:** BD-106 (commit `bf26789`)
**Reviewer:** pack-reviewer (per-BD, no prior reviews; experiment 2026-05-15)
**Date:** 2026-05-15

## Summary

Verdict: **clean-with-MUSTs** (minor). The BD-106 implementation is
sound: 60/60 tests pass, the §6.R schema is 16/16 MATCH against the
architect's independent ratification (per
`ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md` §A.6), SHA-256 byte-identity
on the `### Tasks` slice round-trip is proven, and the Path-3-forbidden
invariant has both a runtime negative-test (Test 5.6) and a hard
absence in the lib. The findings below are not BLOCKERs — they are
correctness / convention issues that would benefit from being fixed
before BD-107 / BD-108 land downstream consumers.

Counts: 0 BLOCKER · 2 MUST · 6 SHOULD · 4 NIT.

## Findings

### Finding F1
- **Severity:** MUST
- **Location:** `scripts/lib/tracker-phase-task.sh:156`, `scripts/lib/tracker-phase-task.sh:450`, `scripts/lib/tracker-sidecar.sh:315`, `scripts/lib/tracker-labels.sh:227`, `scripts/lib/tracker-labels.sh:242`, `scripts/lib/tracker-migrate-forward.sh:223`, `scripts/lib/tracker-migrate-reverse.sh:101`
- **Title:** New error sites bypass `tracker_error_emit` and break the typed-error contract
- **Description:** Every existing tracker-* lib uses
  `tracker_error_emit "<code>" "<message>"` (V1 §2.5, V3 §27.1
  Layer 2 — see `scripts/lib/tracker-errors.sh` lines 46-52 and the
  ten-call sites already in `tracker-migrate-forward.sh`,
  `tracker-labels.sh`'s `labels_ensure`, etc.). BD-106 introduces
  seven NEW error sites that emit a bare `printf 'ERROR: <ad-hoc>'
  >&2; return 1` instead of routing through `tracker_error_emit`.
  Consequence: the messages skip the canonical `MESSAGE:` line,
  the verbatim context block, and the `→ Run: <verb-from-table>`
  Layer-2 trailer (V3 §27.1). Downstream consumers that grep / parse
  for the typed envelope (per the existing `tracker-errors-test.sh`
  60-assertion suite shape) will silently miss BD-106's failures.
  This is a contract regression on a design that the rest of the
  codebase honors uniformly.
- **Suggested fix:** Replace the seven `printf 'ERROR: ...' >&2;
  return 1` blocks with `tracker_error_emit "<code>" "<message>"`
  calls. Codes available from `tracker-errors.sh`:
  - `tracker_phase_task_parse` missing-file → `tracker_error_emit
    "not-found" "tracker_phase_task_parse: $path does not exist"`.
  - `tracker_phase_task_emit` empty-input → `tracker_error_emit
    "validation" "empty input to tracker_phase_task_emit"`.
  - `tracker_sidecar_compose_phase_tasks_block` empty-input →
    `tracker_error_emit "validation" "empty input to ..."`.
  - The two label helpers + the forward+reverse mapping helpers →
    `tracker_error_emit "validation" "<helper>: <reason>"`.
  Update `test-tracker-phase-task.sh` 2.6 to
  `assert_contains "$err" "ERROR: not-found"` (already passes)
  AND add a check that `MESSAGE:` and `→ Run:` are present so the
  contract is enforced going forward.
- **Source:** `scripts/lib/tracker-errors.sh` lines 22-39 (D-7 / V1 §9
  contract); existing call-site precedent in
  `scripts/lib/tracker-migrate-forward.sh` lines 326, 457, 647,
  660, 683, 1165, and `scripts/lib/tracker-labels.sh` lines 153,
  183.

### Finding F2
- **Severity:** MUST
- **Location:** `scripts/lib/tracker-phase-task.sh:111-113` (exported
  `tracker_phase_task_dependency_re`) vs `scripts/lib/tracker-phase-task.sh:184-186`
  (Python parser `DEP_ENTRY`)
- **Title:** Exported regex and internal parser regex have divergent
  capture-group semantics
- **Description:** The exported regex is
  `^[[:space:]]*-[[:space:]]+(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)([[:space:]].*)?$`
  (POSIX ERE). Bash callers using `[[ "$line" =~ $re ]]` get:
  group 1 = the pack-id, group 2 = optional `.M`, group 3 =
  ` <annotation>` (leading space included).
  The Python parser's `DEP_ENTRY` is
  `^\s*-\s+(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?\s*$` —
  group 1 = pack-id, group 3 = annotation **with leading whitespace
  consumed** by the inner `\s+`, then `.strip()`-ed.
  The two regexes are NOT capture-equivalent. BD-108 (already
  blocked-by BD-106) is expected to consume
  `tracker_phase_task_dependency_re` via bash for parsing; it will
  see leading whitespace in the annotation field that the canonical
  parser strips. The IMPLEMENTATION-REPORT §2 cites "splitting
  would force the regex to live in two places" as the rationale for
  the single-file design — but the regex DOES live in two places
  (bash + Python), with subtly different semantics.
- **Suggested fix:** Either (a) align the bash regex shape to
  `(phase-...)([[:space:]]+(.*))?` so group 3 has the same
  trim-equivalent meaning as Python's group 3, OR (b) document the
  divergence in the function docstring and add an assertion in
  `test-tracker-phase-task.sh` Group 1 that runs both regexes
  against the same set of representative lines and confirms group-1
  capture equivalence and documents group-3 differences. (Option
  (a) is the stronger fix and avoids surprising BD-108.)
- **Source:** ARCHITECTURE-V3.3-DELTA.md §6.R.3 line 459
  (canonical regex); IMPLEMENTATION-REPORT-BD-106.md §2 (rationale
  for single-file is regex-co-location, which the implementation
  does not actually achieve across the bash/Python language
  boundary).

### Finding F3
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-sidecar.sh:329-339` (yaml_quote)
  + `scripts/tests/test-tracker-phase-task.sh` Group 4
- **Title:** YAML-quoting branch is untested; tests exercise only
  the unquoted path
- **Description:** `yaml_quote()` quotes when the annotation
  contains `:`, `#`, `"`, `'`, `\n`, `\t`, has leading/trailing
  whitespace, or is empty. Test 4.2 only exercises empty
  (`annotation: ""`) and the bareword `(must complete migration
  scaffold first)` path. There is no test that an annotation
  containing `:` (e.g. "see TD-029: blocking") is correctly
  emitted as `annotation: "see TD-029: blocking"` and round-trips
  byte-identically. Per V3.3 §6.R.3 the quoting rule is
  load-bearing for round-trip identity; an emitter regression
  would silently break sidecar parse on a real-world annotation.
- **Suggested fix:** Add to the IMPLEMENTATION-PLAN.md fixture (or
  a new fixture) one Dependencies entry whose annotation contains
  a colon and one whose annotation contains `#`, then assert in
  Test 4.2 that the sidecar emits the quoted form
  (`annotation: "..."`) and Test 3.x exercises the round-trip on
  that fixture.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §6.R.3 lines 474-479
  (quoting rule); IMPLEMENTATION-REPORT-BD-106.md §6.4
  (round-trip claim is restricted to ROUNDTRIP.md slice, which
  contains no quoting cases).

### Finding F4
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-phase-task.sh:329-376` (parser
  bullet handling)
- **Title:** Round-trip byte-identity claim is narrower than the
  emitter docstring suggests; non-canonical bullet names silently
  re-canonicalize on emit
- **Description:** The emitter (line 497-499) hardcodes the
  canonical METHODOLOGY § Part 4 bullet names: `Problem / Goal /
  Success`, `Files created/modified`, `Definition of done`. The
  parser's `normalize_bullet_name()` (line 191-203) accepts
  variants — e.g. `Problem`, `Files`, `dod`. After parse → emit,
  the variants are canonicalized. So a fixture authored with
  `- **DoD**: …` would parse to `definition_of_done` and emit as
  `- **Definition of done**: …` — NOT byte-identical to the
  source. Likewise `- **Problem**: …` becomes `- **Problem / Goal
  / Success**: …`. The emitter docstring at line 420-425 says
  "round-trip identity holds" which is true ONLY when the source
  uses canonical names + canonical separator (`: `) + no trailing
  whitespace. ROUNDTRIP.md happens to satisfy all three.
- **Suggested fix:** Either (a) extend the parser to remember the
  exact bullet-name spelling and pass it through to the emitter
  (preserve verbatim), OR (b) tighten the emitter docstring to
  state the byte-identity preconditions (canonical names +
  canonical `: ` separator + no trailing whitespace) and add a
  fixture-and-test pair that confirms a NON-canonical input
  parses semantically but does NOT round-trip byte-identically
  (so the boundary is documented and tested). Option (b) is the
  cheaper fix; option (a) costs grammar-state memory but matches
  the "byte-identical round-trip" claim more faithfully.
- **Source:** ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md §A.3.5 lines
  268-282 (slice byte-identity claim); current emitter docstring
  at `scripts/lib/tracker-phase-task.sh:64-67`.

### Finding F5
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-phase-task.sh:178` (BULLET_HEAD
  separator class)
- **Title:** Parser accepts em-dash and hyphen separators that the
  emitter never produces — round-trip drift on em-dash bullet
  inputs
- **Description:** BULLET_HEAD is
  `^-\s+\*\*([^*]+?)\*\*\s*[:—-]\s*(.*)$`. The character class
  `[:—-]` accepts colon, em-dash, OR hyphen as the bullet-name /
  body separator. The emitter ALWAYS produces colon (`f'- **{name}**:
  {body}'` at lines 468 and 471). Result: a source line
  `- **Problem** — body` parses successfully but emits as
  `- **Problem / Goal / Success**: body`. Same drift mechanism as
  F4. The tolerance is one-way and undocumented.
- **Suggested fix:** Either (a) drop em-dash + hyphen from the
  separator class so the parser is strict to colon (matches
  METHODOLOGY § Part 4 canonical), OR (b) preserve the source
  separator on each bullet and replay it in the emitter. Option (a)
  is mechanical; option (b) requires per-bullet separator memory.
  Recommend (a) since METHODOLOGY § Part 4 line 304 uses only the
  colon separator.
- **Source:** `supporting-docs/METHODOLOGY.md:304-309` (canonical
  bullet syntax uses colon).

### Finding F6
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-migrate-forward.sh:183-190`
  (`tmf_mapping_set`) interaction with new
  `tmf_mapping_set_phase_task_order` at line 218-238
- **Title:** Order-of-operations risk: re-invoking `tmf_mapping_set`
  on a phase entry wipes its `task_order`
- **Description:** `tmf_mapping_set` is the existing pre-BD-106
  helper; line 188 reads `. + {($k): {id: $id, url: $url}}`. The
  `+` operator at top level REPLACES `.[$k]` wholesale, so any
  additive fields previously written by
  `tmf_mapping_set_phase_task_order` (e.g.
  `mapping["phase-3"].task_order`) are silently lost on a second
  `tmf_mapping_set "phase-3" ...`. Forward migrators that retry
  phase-epic creation (e.g. checkpoint resume per V1 §6.4) must
  re-write task_order after every `tmf_mapping_set` for the same
  phase or accept silent loss. Test 6.2 happens to use the safe
  ordering (set first, then set_task_order) and so does not
  surface the regression. There is no test for the unsafe ordering.
- **Suggested fix:** Either (a) change `tmf_mapping_set` to
  `'.[$k] = ((.[$k] // {}) + {id: $id, url: $url})'` (additive,
  matching the pattern used by the new helper at line 234-235),
  OR (b) add a runtime warning + a test that asserts
  `tmf_mapping_set` after `tmf_mapping_set_phase_task_order`
  preserves task_order. Option (a) is one-line, broadly safer,
  and matches the v11.0 design intent of additive id-map.
- **Source:** `scripts/lib/tracker-migrate-forward.sh:194-197`
  (commit comment "id-map handling — additive — existing v10
  entries are untouched; v11 phase-task entries simply add new
  keys alongside" — but `tmf_mapping_set` itself is non-additive
  on the entry level).

### Finding F7
- **Severity:** SHOULD
- **Location:** `README.md:202-203`
- **Title:** Repo-layout glob does not list `tracker-phase-task.sh`
- **Description:** README.md line 202 lists
  `tracker-{config,init,labels,errors,sidecar,mirror,agent-read}.sh`
  as the tracker subsystem libs. Line 203 lists
  `tracker-migrate-{forward,reverse}.sh`. Neither glob includes
  the new `tracker-phase-task.sh`. The CLAUDE.md "What agents may
  modify" rule requires agents to consult README.md for repo
  structure ("the Repository Layout section is the authoritative
  reference"). After BD-106, that authoritative reference is
  stale.
- **Suggested fix:** Extend the line 202 glob to
  `tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task}.sh`
  with a one-line comment cross-referencing V3.3 §2 D-21 / BD-106.
  Trinity rule does NOT engage (README.md is single-file).
- **Source:** `CLAUDE.md` "Repo structure" section ("Do not rely on
  any hardcoded directory listing here; the structure changes
  between major versions" — pushes responsibility to README,
  which is now stale); pack-reviewer checklist item "README
  layout".

### Finding F8
- **Severity:** SHOULD
- **Location:** `scripts/validate-pack.py` (no new check)
- **Title:** validate-pack does not enforce the Path-3-forbidden
  invariant or the BD-106 lib presence
- **Description:** Test 5.6 in `test-tracker-phase-task.sh`
  asserts `tracker_labels_folded_into` does NOT exist. This is a
  test-layer guard. CI runs validate-pack on every push (per
  CLAUDE.md "CI validation"); a future maintainer who adds
  `tracker_labels_folded_into` to `tracker-labels.sh` without
  re-running test-tracker-phase-task would land the violation.
  validate-pack should also catch it. Two related gaps: there is
  no validate-pack check that `scripts/lib/tracker-phase-task.sh`
  exists at v11.0, no check that the canonical label set
  excludes `folded-into:*`, and no check that the V3.3 §3 line 27
  Path-3-forbidden grep returns zero hits across `scripts/lib/`
  for `folded-into` (the existing release-readiness grep checks
  per IMPLEMENTATION-PLAN-ADDENDUM-4 §6.2 are documented but not
  yet wired into validate-pack).
- **Suggested fix:** Add a check (numbered next available, e.g.
  Check 36) `check_tracker_phase_task_invariants` that:
  1. asserts `scripts/lib/tracker-phase-task.sh` exists.
  2. greps `scripts/lib/tracker-labels.sh` for
     `tracker_labels_folded_into` and FAILs if present.
  3. greps `scripts/lib/` for the literal `folded-into` and FAILs
     if present (V3.3 §3 line 27 invariant).
  Wire into the CHECKS list near the other tracker-* checks. Trinity
  rule does NOT engage (validate-pack is single-file).
- **Source:** ARCHITECTURE-V3.3-DELTA.md §3 line 27 (Path 3
  forbidden); pack-reviewer checklist item "validate-pack.py
  alignment" ("If new files or directories are added, verify that
  CI validation accounts for them").

### Finding F9
- **Severity:** SHOULD
- **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-106.md:86-87`
  (§3 final paragraph) and `:312` (§9), `:316` (§10)
- **Title:** IMPLEMENTATION-REPORT prose is stale on §6.R existence
  (was correct at write-time; superseded by commit 342d8b8)
- **Description:** The IMPLEMENTATION-REPORT §3 says: "V3.3 §6.R
  is not literally a section in `ARCHITECTURE-V3.3-DELTA.md`; the
  delta document does NOT contain a `§6.R` heading." This was
  true at the moment the coder finished. Commit 342d8b8 (landed
  ~4 minutes BEFORE bf26789, the BD-106 commit) formalized §6.R
  into V3.3-DELTA.md (lines 384-493 of the current
  V3.3-DELTA.md). §9 plan-deviations and §10 new-POQs in the
  IMPLEMENTATION-REPORT carry the same stale framing
  ("interpretation note", "the §6.R reference appears to be a
  forward-looking pointer in the prompt"). A future maintainer
  reading the report sees a contradiction with the live spec.
- **Suggested fix:** Append a one-paragraph note to §3 (or
  preferably to a NEW §13 "Post-land update — §6.R formalized")
  that records the architect ratification trail:
  "After this report was written, V3.3-DELTA was extended with
  the §6.R section (commit 342d8b8). The architect's
  ARCHITECTURE-V3.3-DELTA-ADDENDUM-1 §A.6 records 16/16 MATCH
  against the implementation. The interpretation-note framing in
  §3, §9, §10 is preserved as historical context — §6.R exists
  in the live spec from 2026-05-14 forward, with no contradiction
  to this implementation."
  IMPLEMENTATION-REPORT-* files are coder-authored and not
  PM-only by pack convention; Pack Chat or a follow-up coder pass
  may apply this edit.
- **Source:** Commit `342d8b8` log; ARCHITECTURE-V3.3-DELTA.md
  §6.R lines 384-493; ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md §A.6
  (16/16 MATCH).

### Finding F10
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-phase-task.sh:437-446`
- **Title:** Duplicate "Implementation note: …" comment block
- **Description:** Lines 437-440 and 442-446 contain near-identical
  paragraphs explaining why JSON is passed via `TPT_DOC_JSON`
  rather than stdin. The second paragraph adds one sentence about
  bash 3.2 portability; the first four lines are duplicated.
- **Suggested fix:** Delete lines 437-441 (keeping the longer
  block at 442-446 as the canonical comment).
- **Source:** Internal consistency.

### Finding F11
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-phase-task.sh:361-367`
- **Title:** Comment claims blank line "ends the dependencies
  block" but code does not clear `current_bullet`
- **Description:** Lines 361-363 read:
  ```
  elif raw.strip() == '':
      # Blank line ends the dependencies block.
      pass
  ```
  The comment promises behavior the code does not implement —
  `current_bullet` stays set to `'dependencies'`. In practice,
  the next line that matches BULLET_HEAD or NESTED_BULLET resets
  the state correctly, so there is no observable bug, but the
  comment is misleading.
- **Suggested fix:** Either implement the behavior (`current_bullet
  = None` after a blank line in dependencies mode) or correct the
  comment to say "Blank line is allowed inside the dependencies
  block; state is unchanged until the next bullet header."
- **Source:** Internal consistency.

### Finding F12
- **Severity:** NIT
- **Location:** `scripts/tests/test-tracker-phase-task.sh:165` and
  the absent error-path test for `tracker_phase_task_emit`
- **Title:** No test exercises `tracker_phase_task_emit` empty-input
  failure path
- **Description:** The runner covers the empty-input failure path
  for `tracker_phase_task_parse` (Test 2.6) but does NOT cover
  the empty-input failure path for `tracker_phase_task_emit`
  (line 449-452). Symmetric coverage would catch a regression in
  the emitter's input validation.
- **Suggested fix:** Add a Group 3 assertion:
  ```
  if tracker_phase_task_emit "" >/dev/null 2>&1; then
      t_fail "3.5 emit rejects empty input" "expected rc=1"
  else
      t_pass "3.5 emit rejects empty input"
  fi
  ```
  (Bumps assertion count from 60 → 61 and the runner header
  group description should mention it.)
- **Source:** Symmetric coverage with Test 2.6.

### Finding F13
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-phase-task.sh:84-85` (V1 §6.4
  ref)
- **Title:** Reference path `ARCHITECTURE-V3.2-DELTA.md` cited but
  no `ARCHITECTURE-V1.md` file exists in the repo
- **Description:** The header docstring cites
  "ARCHITECTURE-V3.3-DELTA.md §2, §3.5, §4.1-§4.4, §5.3, §6.4;
  ARCHITECTURE-V3.2-DELTA.md §4.1, §4.2, §4.3" (lines 78-79).
  Both files exist. However, prose elsewhere in the lib
  references "V1 §6.7" (line 64), "V1 §5.3" (line 76), etc. The
  base spec is `ARCHITECTURE.md` (no V1 suffix); other tracker-*
  libs use the same V1-prefixed shorthand without trouble, but
  it can confuse a reader who searches for `ARCHITECTURE-V1.md`
  and finds nothing.
- **Suggested fix:** No change required (the V1 shorthand is
  established convention across the tracker-* libs and matches
  the §-numbering of `ARCHITECTURE.md`). Leave to author
  judgment.
- **Source:** Convention parity with existing libs.

## Coverage notes

What I reviewed:
- The full BD-106 diff (`git show bf26789`) — every changed line
  in `tracker-phase-task.sh`, `tracker-sidecar.sh`,
  `tracker-labels.sh`, `tracker-migrate-forward.sh`,
  `tracker-migrate-reverse.sh`, the test runner, and the two
  fixtures.
- ARCHITECTURE-V3.3-DELTA.md §2 / §3.5 / §4 / §5.3 / §6.R
  (formalised in commit 342d8b8).
- ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md (the architect's §6.R
  ratification trail; §A.6 16/16 MATCH).
- ARCHITECTURE.md §2.1 / §2.2 / §6.6 / §6.6.1 / §6.7 (V1
  abstractions; verified `target` field name on `Issue.links`).
- IMPLEMENTATION-PLAN-ADDENDUM-4.md §6.R (RESOLVED-RATIFIED
  status confirmed; §6.P/§6.Q untouched per prompt rule).
- BACKLOG.md BD-106 entry (line 884-896).
- IMPLEMENTATION-REPORT-BD-106.md (allowed per prompt; treated as
  factual, not as architecture).
- METHODOLOGY.md § Part 4 (canonical phase-task grammar) and
  § Part 7 (Procedure 1 gate-check; tracker references).
- README.md Repository Layout section (line 170-240).
- CHANGELOG.md BD-106 entry (line 113).
- validate-pack.py CHECKS index + tracker-related sections.
- Pack-root CLAUDE.md / AGENTS.md and project-template trinity for
  any required parity edits (none — confirmed).
- `scripts/lib/tracker-errors.sh` for the typed-error contract that
  Finding F1 is grounded in.
- Cross-grep for `tracker_phase_task` / `phase_tasks` /
  `dependency_edges` / `derived-from` / `promoted-to` /
  `folded-into` across the entire repo (excluding the explicitly-
  excluded BD-107 / BD-108 / PACK-REVIEW-* surfaces).

What I deferred:
- I did NOT re-run the test runner; trusted IMPLEMENTATION-REPORT
  §6.1 (60/60 PASS) and §6.4 (SHA-256 round-trip identity).
- I did NOT verify the existing `tracker-migrate-forward-test.sh`
  126/0 baseline or the customization-preserve 233/0 baseline;
  trusted the report.
- I did NOT read PACK-REVIEW-*.md files (per prompt exclusion).
- I did NOT read BD-107 / BD-108 BACKLOG entries or
  IMPLEMENTATION-REPORT files (per prompt exclusion). I noted
  during cross-grep that `scripts/pack-td.sh`,
  `scripts/lib/tracker-promote.sh`, `scripts/lib/tracker-links.sh`,
  `scripts/lib/tracker-cycle-check.sh` exist on `v11-dev` HEAD
  (added in commit `aae4712` for BD-108). I confirmed these are
  not part of BD-106's diff and intentionally restricted my
  review to the BD-106 surface; the cross-grep returned a single
  hit (`scripts/pack-td.sh:62 source "$LIB_DIR/tracker-phase-task.sh"`)
  which is a downstream consumer and not a defect of BD-106.
- §6.P / §6.Q MAINTAINER CHECK items are NOT flagged as gaps per
  prompt instruction.
- I did not review the SCHEMA.md reverse-emit grammar drift
  (templates-archive `phase-task-v11.0/SCHEMA.md` documents
  `#### N.M <task title>` without em-dash and `- **Problem /
  Goal / Success:** <body>` shape that differs from METHODOLOGY
  § Part 4) — this is a pre-existing inconsistency between the
  template archive and METHODOLOGY canonical, NOT introduced by
  BD-106. Worth a follow-up architecture task but out of scope
  for this review.
