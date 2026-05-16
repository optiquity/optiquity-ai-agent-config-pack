# Implementation Report — BD-160 + BD-170 Fix Pass (review remediation for commit `a57dd04`)

| Field | Value |
|---|---|
| Report subject | Application of FIX subset (S-1 + S-2 + N-1) from `PACK-REVIEW-BD-160-170.md` |
| Pre-fix HEAD | `a57dd04838c572e32c9d3ff69cc8884eb6e6ef9a` |
| Post-fix HEAD | `a57dd04838c572e32c9d3ff69cc8884eb6e6ef9a` (unchanged — coder does not commit) |
| Working-tree state | 3 modified files + 2 pre-existing untracked artifacts (review report + cleanup-inputs notes) |
| Branch | `v11-dev` |
| Coder | pack-coder (fix-pass subagent) |
| Date | 2026-05-16 |
| Skip rationale | Findings N-2 + N-3 skipped per Pack Chat triage (reviewer self-classified both as no-action) |

---

## 1 — Summary

Applied all three FIX-list items from Pack Chat's triage of
`PACK-REVIEW-BD-160-170.md`:

- **S-1** (SHOULD): updated the `_build_realistic_for_version` function
  header comment in `test-fixtures/build.sh` to enumerate the four
  per-version dispatch sites (was previously documented as two; BD-160
  added the C4 BACKLOG.md per-version case + BD-170 added the per-entry
  decompose / regenerate / round-trip block).
- **S-2** (SHOULD): appended a one-paragraph addendum to
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2
  pointing at BD-160 (commit `a57dd04`) as the realized first
  fixture-builder consumer of `migrator_target_surface_for_version`,
  while preserving the original BD-120-anchored design-intent text
  in-place (per the reviewer's recommended option (c) from the deferral
  assessment in PACK-REVIEW §6 / IMPL-REPORT §6).
- **N-1** (NIT): added the `v11-realistic-ot/` row to the
  `test-fixtures/` subtree in `README.md`'s Repository Layout block,
  placed between `v10-realistic-ot/` and `v11-flat-file/` to match
  surrounding alphabetic-by-version ordering.

Skipped per Pack Chat triage:

- **N-2**: reviewer self-classified as "No code change required"
  (meta-observation about future PLAN gate text for fixture-builder
  changes; the underlying CI gate at `validate-pack.yml:210` is
  operational and exercises the new code path on every push).
- **N-3**: reviewer self-classified as "No code change required"
  (meta-observation about future IMPL-REPORT prose style; the
  IMPL-REPORT is a workflow artifact destined for Pattern-B archive
  at v11.0 ship and the technical disposition is correct).

All 10 baseline test suites pass with zero regressions (499/0).
`validate-pack.py` PASSED — all 35 checks clean. v11-realistic-ot
fixture rebuild succeeds and reproduces the IMPL-REPORT §5 determinism
pin (HEAD SHA `85072fec8ad59e1badd86e0bde62f943811a7bba`). HEAD
unchanged (coder does not commit per `feedback_agents_never_commit`).

---

## 2 — Files modified / created

| Path | Change type | Lines delta | Rationale |
|---|---|---|---|
| `test-fixtures/build.sh` | modified | +18 / -4 (net +14) | FIX S-1: header comment enumerates 4 per-version dispatch sites + die-sentinel cross-ref |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` | modified | +15 / -0 | FIX S-2: addendum paragraph to §9.2 (in-place historical preservation + BD-160 realization pointer) |
| `README.md` | modified | +1 / -0 | FIX N-1: added `v11-realistic-ot/` row to `test-fixtures/` subtree in Repository Layout block |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-160-170-FIX.md` | created | +<this file> | required report deliverable |

No files deleted. No files renamed. No staging or commits performed
(reserved for Pack Chat per `feedback_agents_never_commit`).

---

## 3 — Per-fix detail

### 3.1 FIX S-1 — `_build_realistic_for_version` header comment

**File:** `test-fixtures/build.sh`
**Location:** function-header comment block immediately preceding the
function definition (the "Per-version dispatch" subsection and the
"Add a new vN" sentence at the comment's tail).

**Before** (the two relevant paragraphs):

```
# Per-version dispatch is confined to:
#   - Source-clone setup (only v10 needs the cloned-tag work-around).
#   - Which init-project.sh runner to invoke (`_run_vN_init`).
...
# Add a new vN by extending the two `case` blocks below, adding a
# `_run_vN_init` helper if the new version needs source-isolation
# different from the current pack HEAD, and wiring the dispatcher per
# the README "Realistic-OT fixtures: per-version pattern" subsection.
```

**After:**

```
# Per-version dispatch sites inside this function (search for
# `case "$ver" in` and `[[ "$ver" == ` to enumerate mechanically):
#   1. Source-clone setup case — only v10 needs the cloned-tag
#      work-around; v11 runs against the current pack HEAD.
#   2. Init-runner dispatch case — picks `_run_vN_init`.
#   3. C4 (TD-NNN BACKLOG.md) per-version target-path + intro-shape
#      case (added BD-160). v10 writes a root-level BACKLOG.md;
#      v11 appends the TD-NNN block to the pre-existing per-entry
#      empty-seed mirror at `docs/project/BACKLOG.md`.
#   4. Per-entry decompose / regenerate / round-trip block (added
#      BD-170), currently gated `if [[ "$ver" == "v11" ]]`.
#      Future vN whose surface includes a project-side per-entry
#      tree must extend this gate.
...
# Add a new vN by extending EACH of the four per-version dispatch
# sites listed above, adding a `_run_vN_init` helper if the new
# version needs source-isolation different from the current pack
# HEAD, and wiring the dispatcher per the README "Realistic-OT
# fixtures: per-version pattern" subsection. The BD-120-retro F2
# die-sentinel pattern (unsupported `vN` falls through to `die 4`)
# is the safety net that catches a partial extension.
```

**Drift-resilience choice:** numbered list with descriptive cues
(`case "$ver" in` / `[[ "$ver" == `) rather than hard-coded line
numbers, per the review's suggested-remediation rationale ("line
numbers shift when build.sh grows; prefer the descriptive form over
line-number citations"). The "search for ..." instruction lets a
future-vN extender re-enumerate mechanically even after further file
growth.

**Cross-reference:** the final paragraph now names the BD-120-retro F2
die-sentinel as the safety net that catches a partial extension —
explicitly tying the maintainability surface to the existing safety
mechanism so the two remain mentally co-located.

### 3.2 FIX S-2 — ARCHITECTURE-BD-119.md §9.2 addendum

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
**Location:** end of §9.2 ("BD-120 dependence on BD-119 (and what
helpers BD-119 should expose)"), immediately after the existing
**Decision:** paragraph and before §9.3.

**Before:** §9.2 ended with:

```
**Decision:** ship the helper as part of BD-119 — one-line addition to
the core's public surface, removes a future drift risk for free. If
BD-119's review finds the helper is not load-bearing it can be
deferred to BD-120's own scope without ripple.

### 9.3 What BD-120 inherits from BD-119
```

**After:** §9.2 now ends with:

```
**Decision:** ship the helper as part of BD-119 — one-line addition to
the core's public surface, removes a future drift risk for free. If
BD-119's review finds the helper is not load-bearing it can be
deferred to BD-120's own scope without ripple.

**Addendum (2026-05-16, BD-160):** The §9.2 main text above preserves
the original BD-120-anchored design intent (the helper was specified
and shipped under BD-119 with BD-120 as the named first consumer).
The realized first fixture-builder consumer of
`migrator_target_surface_for_version` is BD-160 (commit `a57dd04`,
2026-05-16), which wired the v11 case in `_build_realistic_for_version`
inside `test-fixtures/build.sh` — BD-120 itself shipped without
sourcing the helper (this was identified in the BD-120 retro F1 fix).
The historical framing and the post-realization framing are not
contradictory: §9.2 documents the architectural contract; BD-160
documents the contract's first realization. The in-code docstring at
`scripts/lib/migrator-core.sh` for `migrator_target_surface_for_version`
was updated in the same commit `a57dd04` to name BD-160 as the
realized consumer (with the BD-120-retro F1 context preserved); read
the two together for the full historical chain.

### 9.3 What BD-120 inherits from BD-119
```

**Design choices:**

- Marked with `**Addendum (2026-05-16, BD-160):**` so a future reader
  can immediately distinguish original architect text from the
  post-realization update (per the FIX prompt's explicit guidance).
- Preserves the BD-120-anchored historical framing of §9.2 in-place
  (per the reviewer's recommendation: "in-place historical
  preservation"). No re-writing of the existing four sub-section
  paragraphs.
- Cross-references the in-code docstring at
  `scripts/lib/migrator-core.sh` so the architecture-doc and the
  in-code documentation are mutually consistent on the helper's first
  real consumer (closes the gap the reviewer named in PACK-REVIEW §2
  S-2 evidence row 4: "The in-code docstring at
  `scripts/lib/migrator-core.sh:505-518` was correctly updated to name
  BD-160 as the consumer — so the in-code documentation and the
  architecture-doc are now mutually inconsistent on the helper's first
  real consumer").
- Names BD-120-retro F1 fix as the context for why BD-120 itself did
  not consume the helper (preserves the historical chain end-to-end).
- Explicitly states the design-intent vs realization distinction is
  not contradictory — pre-empts a future maintainer reading both
  framings and wondering which is authoritative (answer: both, for
  different things).

**Forward-pointing anchor established:** the §9.2 addendum is itself
the live forward-pointing surface that the reviewer's deferral
assessment (PACK-REVIEW §6) identified as missing. The BD-160 carry-
forward item named in `BACKLOG.md` BD-160's File/Symbol field is now
addressed and the §9.2 update is no longer anchorless when Pack Chat
flips BD-160 → Resolved.

### 3.3 FIX N-1 — README.md Repository Layout

**File:** `README.md`
**Location:** `test-fixtures/` subtree in the Repository Layout block.

**Before:**

```
├── v10-realistic-ot/                       Fake-OT shape (gitignored)
├── v11-flat-file/                          v11 client, no tracker (gitignored)
```

**After:**

```
├── v10-realistic-ot/                       Fake-OT shape (gitignored)
├── v11-realistic-ot/                       Fake-OT shape v11 (gitignored; BD-160 + BD-170; source-pinned to pack HEAD pre-v11.0)
├── v11-flat-file/                          v11 client, no tracker (gitignored)
```

**Style match notes:**

- Placement: between `v10-realistic-ot/` and `v11-flat-file/` follows
  the existing alphabetic-by-version ordering (v10 entries grouped,
  v11 entries grouped, then `existing-project-mid-dev`).
- Description form: "Fake-OT shape v11" parallels `v10-realistic-ot/`'s
  "Fake-OT shape" wording for symmetry.
- `(gitignored)` marker present per surrounding row convention.
- BD reference: `BD-160 + BD-170` matches the combined-commit
  attribution from PACK-REVIEW + BD-115 row's `(BD-115)` precedent.
- Source-pin note: "source-pinned to pack HEAD pre-v11.0" surfaces the
  v11-specific source semantics documented in `build.sh`'s function-
  header (and re-emphasized by the updated S-1 header comment above)
  so a Repository Layout reader is alerted to the determinism
  difference vs. v10-realistic-ot.
- Touched ONLY the Repository Layout block per FIX prompt scope; no
  version-table edits.

---

## 4 — Verification

Every command listed in the FIX prompt §Verification was run.
PASS/FAIL is unambiguous for each.

| # | Command | Result | Output tail |
|---|---|---|---|
| 1 | `bash -n test-fixtures/build.sh && echo "OK"` | PASS | `SYNTAX_OK` |
| 2 | `python3 scripts/validate-pack.py` | PASS | `PASSED — all checks clean` (all 35 checks) |
| 3 | `bash test-fixtures/build.sh --clean --name v11-realistic-ot` | PASS | `built: .../v11-realistic-ot` / `HEAD: 85072fec8ad59e1badd86e0bde62f943811a7bba` (matches IMPL-REPORT §5 determinism pin) |
| 4 | `bash scripts/tests/test-per-entry.sh` | PASS | `PASS: 57 / FAIL: 0` |
| 5 | `bash scripts/tests/test-init-project.sh` | PASS | `Passed: 67 / Failed: 0` |
| 6 | `bash scripts/tests/test-migrate-v10-to-v11.sh` | PASS | `Passed: 43 / Failed: 0` |
| 7 | `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | PASS | `Passed: 61 / Failed: 0` |
| 8 | `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | PASS | `Passed: 87 / Failed: 0` |
| 9 | `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | PASS | `Passed: 45 / Failed: 0` |
| 10 | `bash scripts/tests/tracker-agent-read-test.sh` | PASS | `Passed: 52 / Failed: 0` |
| 11 | `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | PASS | `PASS: 65 / FAIL: 0` |
| 12 | `bash scripts/test-migrator-core.sh` | PASS | `19 passed, 0 failed` |
| 13 | `bash scripts/test-persona-contracts.sh` | PASS | `Persona contract summary: 3/3 passed` (internal migration contract: `37 passed, 0 failed`) |
| 14 | `git rev-parse HEAD` | PASS | `a57dd04838c572e32c9d3ff69cc8884eb6e6ef9a` (unchanged — coder does not commit) |

**Aggregate test totals across the 10 baseline test suites:**
**499 passed / 0 failed.** Zero regressions.

**Determinism confirmation:** the v11-realistic-ot fixture rebuild
produced HEAD SHA `85072fec8ad59e1badd86e0bde62f943811a7bba`, which
matches the pin from `IMPLEMENTATION-REPORT-BD-160-170.md` §5
("two consecutive `--clean --name v11-realistic-ot` builds produced
identical content-SHA `f5bbb1c1...` + HEAD-SHA `85072fec8ad59e...`")
AND the row in `test-fixtures/manifest.txt:7`. The S-1 header-comment
change is a no-op semantically and the build produces the same fixture
SHA — exactly the expected outcome.

**Working-tree state after all fixes + verification:**

```
M README.md
M maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
M test-fixtures/build.sh
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-160-170.md
```

The two `??` (untracked) entries are pre-existing artifacts (the
review report this fix-pass consumed, plus a session-rules note
already present at session start per the initial `git status` reading).
This report (`IMPLEMENTATION-REPORT-BD-160-170-FIX.md`) will appear as
a third `??` row after this Write call completes; Pack Chat decides
the staging disposition.

---

## 5 — Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | FIX S-1 landed (header comment enumerates 4 dispatch sites) | PASS |
| 2 | FIX S-2 landed (§9.2 addendum pointing at BD-160 as realized consumer) | PASS |
| 3 | FIX N-1 landed (v11-realistic-ot row added to Repository Layout) | PASS |
| 4 | Out-of-scope source files untouched (BACKLOG.md, CHANGELOG.md, PACK-AGENTS.md, PACK-CHAT.md, trinity files, other architect docs) | PASS (`git status` confirms only 3 in-scope modified) |
| 5 | `bash -n test-fixtures/build.sh` passes | PASS |
| 6 | `python3 scripts/validate-pack.py` PASSES | PASS (all 35 checks) |
| 7 | v11-realistic-ot rebuild succeeds + reproduces determinism pin | PASS (`85072fec8ad...`) |
| 8 | All 10 baseline test suites pass (zero regressions) | PASS (499/0) |
| 9 | HEAD unchanged from pre-fix `a57dd04` | PASS |
| 10 | Coder did NOT run any state-changing git verb | PASS (only `git status` + `git rev-parse` used; no add/commit/push/etc.) |
| 11 | IMPL-REPORT written to FIX-prompt-named path | PASS (this file) |
| 12 | Drift-resilient phrasing in this report (relative references where line numbers would shift) | PASS (S-1 uses descriptive search-cue rather than line numbers in the post-fix surface) |
| 13 | Skip rationale for N-2 + N-3 documented with reviewer's own no-action citation | PASS (see §7) |
| 14 | Trinity rule check: no trinity files touched, no rule trigger | PASS (N/A — README.md is not in the CLAUDE/AGENTS/GEMINI trinity) |

All Definition-of-Done items: **14/14 PASS.**

---

## 6 — Plan deviations

**Zero plan deviations.** All three in-scope fixes (S-1, S-2, N-1) were
applied exactly as scoped by the FIX-prompt §"Fix list" wording. No
in-scope file was modified outside the scoped surface. No out-of-scope
file was modified. No state-changing git operation was performed.

The S-1 wording chose the descriptive-form variant ("search for `case
"$ver" in` and `[[ "$ver" == `") rather than enumerating line numbers,
matching the FIX prompt's explicit guidance: "Re-grep risk: line
numbers shift when build.sh grows; prefer the descriptive form over
line-number citations." This is the prompt's stated preference, not a
deviation.

The S-2 addendum landed all four bullets from the FIX prompt's
"addendum should:" list — BD-160 realized-consumer attribution
(bullet 1), in-place historical preservation (bullet 2), in-code
docstring cross-reference (bullet 3), and design-intent vs realization
non-contradiction note (bullet 4). The addendum is 5 sentences
(prompt's "~3-5 sentences" upper-bound). Marked with the explicit
header `**Addendum (2026-05-16, BD-160):**` per prompt directive.

The N-1 row used the prompt's suggested wording template ("Fake-OT
shape v11 ... BD-160 + BD-170 ... source-pinned to pack HEAD pre-
v11.0"), slightly compacted to fit the surrounding column-width
convention (the existing rows trim verbose descriptions; the prompt's
suggested wording is explicitly marked "refine to match surrounding
style").

---

## 7 — Skip rationale

### N-2 — IMPL-REPORT §7 row 2 verification-rigor observation

**SKIPPED.** Per the FIX prompt's "Skip list" guidance and the
reviewer's own suggested-remediation field in PACK-REVIEW-BD-160-170.md
§2 N-2: "No code change. If Pack Chat wants to upgrade verification
rigor for similar future fixture-builder changes, the PLAN gate text
could be updated to specify ..." The reviewer self-classified this
finding as no-action against the current commit; the underlying gate
(`validate-pack.yml:210` running `bash test-fixtures/build.sh --all
--clean` on every push) IS operational and DOES exercise BD-160's
+ BD-170's new code path because `v11-realistic-ot` is now in
`FIXTURE_NAMES`. No actionable item against this commit's surface;
N-2 documents an observation about future PLAN-text patterns, not a
defect.

### N-3 — IMPL-REPORT §5 prose-framing observation

**SKIPPED.** Per the FIX prompt's "Skip list" guidance and the
reviewer's own suggested-remediation field in PACK-REVIEW-BD-160-170.md
§2 N-3: "No code change required. Optional: future IMPL-REPORTs can
drop judgmental framing about the calling prompt and instead note the
substitution as a routine adaptation." The reviewer self-classified
this finding as no-action; the IMPL-REPORT it observes is a workflow
artifact destined for `maintenance-docs/archive/v11/` at v11.0 ship
per Pattern B, and the technical disposition (using `python3` instead
of `bash` for a `.py` file) was correct. No actionable item against
this commit's IMPL-REPORT; N-3 documents a prose-style observation
bounded by the Pattern-B sweep.

Both skip dispositions match the reviewer's own verdicts verbatim;
neither requires a forward-pointing anchor per
`feedback_deferred_work_tracking` because neither was deferred — both
were closed-no-action by the reviewer at the time of review.

---

## 8 — Out-of-scope observations

(Intentionally empty per `feedback_deferral_is_scope_creep` —
fix-coder agents do not introduce out-of-scope observations during
fix passes; any observed gap that the FIX prompt did not name must be
surfaced via Pack Chat triage, not via this report's prose. This
section exists to make the absence explicit so a future reader knows
the fix-coder did look for out-of-scope items and found none worth
surfacing outside the FIX-prompt scope.)

---

## End of report
