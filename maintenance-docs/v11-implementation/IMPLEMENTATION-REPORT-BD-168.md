# IMPLEMENTATION REPORT — BD-168 (Batch 19, Commit 19e)

Status: implementation complete; ready for Pack Chat review + commit.

Branch: `v11-dev`
HEAD SHA at start: `91e497c591412a6bc0588ca0637727ce7c982803`
HEAD SHA at end: `91e497c591412a6bc0588ca0637727ce7c982803` (unchanged — agent
made no commits per `feedback_agents_never_commit`).
Working tree: 2 modified, 1 new file; no other paths touched.

---

## §1 — Summary

BD-168 lands the three per-entry split CI validators per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §10 and
`PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.6. Added to
`scripts/validate-pack.py`: a `STREAMS` constant binding the pack-side
per-entry tree tuples (per integration parent §10.6 pack-side scope),
plus three new check functions — Check 32 (mirror-in-sync), Check 33
(TOC-in-sync), Check 34 (cross-reference integrity) — each invoking the
BD-164 helpers (`scripts/lib/per-entry/{mirror-generate,toc-regenerate}.sh`)
via subprocess for byte-identical comparison. The three checks fold the
six candidate checks per §10.4 (`_rules.md` existence, filename
conformance, and `_v8-resolved-archive.md` byte stability all collapse
into Check 32 pre-checks / main check). Each SKIPs gracefully when the
per-entry tree is absent (per §10.5), so pack-self CI passes today.
Created `scripts/tests/test-validate-pack-checks-32-33-34.sh` (46/46
tests; green and red fixtures for each check) and wired it into
`.github/workflows/validate-pack.yml` as a new tests-job step (step
count 40 → 41) per the Batch 21c "test-not-in-CI" empirical heuristic.
The pre-existing Check 32 (`check_tracker_phase_task_invariants`,
BD-106) was renumbered to Check 35 (banner + docstring text only — the
function name is unchanged) to make room for the new sequence; this is
called out in §7 below as a planner-pass undercount finding.

---

## §2 — Files modified / created

| Path | Pre-lines | Post-lines | Net | Type |
|---|---:|---:|---:|---|
| `scripts/validate-pack.py` | 2916 | 3536 | +620 | modified |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 0 | 508 | +508 | new |
| `.github/workflows/validate-pack.yml` | 235 | 238 | +3 | modified |

`git diff --numstat` reports `623\t3\tscripts/validate-pack.py` (623
inserted, 3 deleted, net +620; the deletions are the four-line block
starting `# ── Check 32: Phase-task lib invariants ...` whose banner +
comment header relocated as part of the renumber to Check 35) and
`3\t0\t.github/workflows/validate-pack.yml`. No other paths touched.

---

## §3 — Per-file change detail

### §3.1 — `scripts/validate-pack.py`

#### §3.1.1 — Top-of-file additions

- Added `tempfile` to the standard-library imports (used by Check 32 +
  Check 33 for the temp snapshot of the on-disk mirror / TOC).
- Added `STREAMS` constant block immediately after `SKILLS_DIR`:
  - List of 4-tuples: `(stream_key, stream_dir_relative, mirror_relative, entry_regex)`.
  - Pack-side scope only per integration parent §10.6 — entries: `pack-backlog`
    (`backlog/` → `BACKLOG.md`, regex `^BD-\d+\.md$`) and `pack-changelog`
    (`changelog/` → `CHANGELOG.md`, regex `^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$`).
  - Stream keys MATCH the BD-164 helper keys (`PE_STREAM_KEYS` in
    `scripts/lib/per-entry/_lib.sh`) so subprocess invocation passes
    them straight through.
  - Comment block cites integration parent §10.6 + Addendum #1 §9.1
    planner-deferred qualifier.
- Added `PER_ENTRY_LIB = REPO_ROOT / "scripts" / "lib" / "per-entry"`
  (sibling helper directory, used by all three subprocess invocations).
- Top-of-file docstring extended with descriptions for Checks 32, 33,
  34, plus a Check 35 entry noting the renumber-from-32.

#### §3.1.2 — Check 32: `check_mirror_in_sync` (new)

Per integration parent §10.1 pseudo-code (with §9.2 disclaimer noting
"planner refines exact implementation"):

- For each `STREAMS` tuple:
  - **SKIP** if `<REPO_ROOT>/<stream_dir>` does not exist (per
    §10.5 backward-compat for pre-v11.0 clients / pre-BD-102
    dog-food pack-self) — emits an OK-line with "not present (skipping ...)".
  - **Pre-check (a)** per §10.4: `<stream_dir>/_rules.md` must exist;
    FAIL with `"_rules.md missing — required for v11.0 per-entry
    contract"` if absent.
  - **Pre-check (b)** per §10.4: every basename in `<stream_dir>/`
    must either match the stream's entry regex OR be a known
    supporting basename (one of `_rules.md`, `_intro.md`, `_toc.md`,
    `_v8-resolved-archive.md`, `_format.md`); FAIL listing the
    offenders if not.
  - **Main check (folds pre-check (c))** per §10.4: snapshot the
    on-disk mirror to a temp file alongside it, set
    `PE_FORCE_OVERWRITE_MIRROR=1`, invoke
    `per_entry_regenerate_mirror <stream_key> <stream_dir> <mirror_path>`
    via subprocess. The helper either no-ops (in-sync — leaves
    on-disk mirror untouched) or rewrites the mirror (out-of-sync).
    Compare the new on-disk content to the snapshot:
    - identical → leave on-disk untouched, emit OK with byte count.
    - differ → restore the snapshot atomically (so the working tree
      is unchanged), FAIL with "out of sync ... re-run
      `per_entry_regenerate_mirror ...`".
  - The v8-archive byte-stability check (sidecar §5.h candidate
    Check 6) is implicitly covered: any edit to
    `_v8-resolved-archive.md` changes what the regenerator emits in
    the trailing block, which the snapshot compare catches.
- Helper `_list_unknown_files(stream_dir, entry_regex,
  known_supporting)` — pure Python, no subprocess; iterates
  `stream_dir`, returns basenames that match neither the regex nor the
  supporting set.
- Helper `_per_entry_run_helper(helper_func, args)` — subprocess
  wrapper that sources `_lib.sh` + the named helper file, invokes the
  function with quoted args, returns `(rc, stdout, stderr)`. (Note:
  `check_mirror_in_sync` uses an inlined subprocess call to pass the
  `PE_FORCE_OVERWRITE_MIRROR` env var; the helper is retained as a
  named seam for future reuse.)

#### §3.1.3 — Check 33: `check_toc_in_sync` (new)

Per integration parent §10.2 ("same shape as Check 32"):

- For each `STREAMS` tuple:
  - **SKIP** if the per-entry tree directory does not exist.
  - **Defensive SKIP** if `_rules.md` is absent (Check 32 already
    FAILed on the same condition; suppress the duplicate).
  - **Main check**: snapshot the on-disk `_toc.md` (if any), invoke
    `per_entry_regenerate_toc <stream_key> <stream_dir>` via
    subprocess. Compare the new on-disk `_toc.md` to the snapshot:
    - identical → restore not needed (helper is no-op when in sync);
      emit OK.
    - on-disk had no `_toc.md` but regenerator produced one →
      delete the produced file (restore tree to pre-check state),
      FAIL with `"_toc.md absent — run per_entry_regenerate_toc ..."`.
    - on-disk differs from regenerator output → restore the snapshot,
      FAIL with `"_toc.md is out of sync — re-run
      per_entry_regenerate_toc ..."`.
- Working-tree restore guarantee verified by test B2.4 + B3.3.

#### §3.1.4 — Check 34: `check_cross_reference_integrity` (new)

Per integration parent §10.3 pseudo-code (with §9.2 disclaimer):

- Module-level `CROSS_REF_RE = re.compile(r"\b(BD-\d+|TD-\d+|phase-\d+(?:\.\d+)?|v\d+\.\d+(?:-[a-z0-9-]+)?)\b")`
  — matches `BD-NNN`, `TD-NNN`, `phase-N` and `phase-N.M`, and
  `vN.M` with optional `-suffix` per §11.2.
- Helper `_collect_defined_ids(stream_key, stream_dir, entry_regex)` —
  collects defined IDs from the entry filenames (per §10.3, "the
  filename IS the ID").
- Helper `_extract_references(text, skip_v8_archive)` — walks lines;
  emits `(ref, line_no)` for each regex match; suppresses anything
  after a line matching `^## Resolved — v\d+` per §11.3.
- Main loop:
  - Build `defined_all` = union of defined IDs across all loaded
    streams (pack-backlog + pack-changelog).
  - **SKIP** with OK if no per-entry tree exists for any stream
    (per §10.5).
  - For each per-entry file (skipping supporting files starting with
    `_` and explicitly skipping `_v8-resolved-archive.md` per §11.3):
    - Read the file; extract refs with `skip_v8_archive=True` (in
      case the entry file itself contains an embedded v8 archive
      header).
    - For each ref:
      - If `ref in defined_all`, OK (silent).
      - If `ref == self_id` (filename minus `.md`), OK (silent —
        self-references are always defined).
      - Otherwise, FAIL with `"<file>:<line> references <ref> — no
        matching entry file found ..."`.
- Final OK summary names file count + ref count.

Cross-stream references INSIDE the loaded set (e.g. a pack-backlog
entry referencing a pack-changelog `vN.M`) ARE validated since both
streams are loaded. References to `phase-N` (project-side) or `TD-NNN`
(project-side) are flagged as dangling because the project streams are
NOT loaded per integration parent §10.6 — this is correct behavior;
test C5 exercises this case with a `phase-3` reference.

#### §3.1.5 — Existing Check 32 renumbered to Check 35

The pre-existing `check_tracker_phase_task_invariants` was labeled
"Check 32" in its banner and docstring (BD-106 / V3.3 §3 line 27 — phase-
task lib invariants). To make room for the new BD-168 Check 32 / 33 / 34
sequence:

- Banner above the function: `# ── Check 32: Phase-task lib invariants
  ...` → `# ── Check 35: Phase-task lib invariants ...` (with note
  that it was renumbered from Check 32).
- Function docstring opening: `"""Check 32 — phase-task lib presence
  ..."""` → `"""Check 35 (renumbered from Check 32 in BD-168) —
  phase-task lib presence ..."""`.
- Print banner inside the function: `print("\n── Check 32: Phase-task
  lib invariants (BD-106) ──")` → `print("\n── Check 35: Phase-task lib
  invariants (BD-106) ──")`.
- Top-of-file docstring: added Check 35 entry citing BD-106 + the
  renumber-from-32 origin.

The function NAME (`check_tracker_phase_task_invariants`) is unchanged
— this is a pure banner/docstring renumber. No callers re-renamed
(there are none — the only caller is `main()` which uses the function
name, not the banner text).

#### §3.1.6 — main() ordering

Inserted the three new checks immediately after
`check_skill_cell_consistency()` (Check 31) and immediately before
`check_tracker_phase_task_invariants()` (now Check 35). Inline comment
block names BD-168 + integration parent §10 + cites the §10.5 SKIP
behavior.

### §3.2 — `scripts/tests/test-validate-pack-checks-32-33-34.sh` (new)

Executable bash script (chmod +x set), 508 lines, bash 3.2 +
macOS BSD utility compatible (verified — local bash is 3.2.57; runs
all 46 tests cleanly). Header comment block enumerates the test
strategy + groups + Architecture references.

Structure:
- `run_check <function_name> <scratch_repo>` — invokes a single
  validator check function via a Python subprocess that monkey-patches
  `vp.REPO_ROOT = scratch_repo` and `vp.STREAMS = [pack-backlog
  tuple]` before calling. Returns 0/1 matching the validator's
  failures-collected exit semantic. This isolates each check from the
  real pack repo so the test scratch trees are the only state.
- `build_green_pack_backlog <scratch_repo>` — materializes a green
  pack-backlog tree under `<scratch_repo>/backlog/` (3 entries, intro,
  v8 archive, _rules.md) and runs the BD-164 mirror/TOC regenerators
  to produce the canonical mirror + `_toc.md`. The fixture is byte-
  identical round-trip from the start.
- Test groups (per the test runner header):
  - **Group D** (3 tests): structural smoke — `STREAMS` constant has
    `pack-backlog` + `pack-changelog`, both 4-tuples.
  - **Group A** (15 tests): Check 32 mirror-in-sync — green
    in-sync mirror passes; hand-edited mirror FAILs with restored
    working tree; missing `_rules.md` FAILs (pre-check a); non-
    conforming filename FAILs (pre-check b); v8-archive edit FAILs
    (folded pre-check c).
  - **Group B** (10 tests): Check 33 TOC-in-sync — green in-sync
    `_toc.md` passes; hand-edited `_toc.md` FAILs with restored
    working tree; missing `_toc.md` FAILs with restored tree.
  - **Group C** (12 tests): Check 34 cross-reference integrity —
    green refs all resolve; dangling `BD-555` FAILs naming the file
    + line + ref; `BD-999` inside `_v8-resolved-archive.md` is
    SKIPed per §11.3; `BD-101` self-ref passes; dangling `phase-3`
    FAILs (exercises §10.6 cross-stream scope from the failure
    side).
  - **Group E** (6 tests): SKIP behavior — scratch repo with NO
    `backlog/` directory triggers the §10.5 graceful SKIP for each
    of the three checks (rc=0, "not present" / "no per-entry trees
    present" message).

Working-tree restoration is asserted explicitly via `shasum` pre/post
comparison in A2.4, B2.4, and B3.3 — the validator MUST NOT mutate
the working tree on FAIL paths (so re-running the validator after a
fix gives the same result; no side effects).

### §3.3 — `.github/workflows/validate-pack.yml`

Added a new tests-job step immediately after the existing
`recommendation-state-schema tests (BD-079, validate-pack Check 30)`
step:

```yaml
      - name: validate-pack Check 32/33/34 tests (BD-168, per-entry split validators)
        if: always()
        run: bash scripts/tests/test-validate-pack-checks-32-33-34.sh
```

Step count: 40 → 41. The `if: always()` matches every other tests-job
step's pattern (per the workflow comment block — "per-suite steps -
independent so one failure surfaces all"). Per Batch 21c's
"test-not-in-CI" empirical heuristic, wiring is mandatory in the same
commit as the test — the test exists but never runs is a review red
flag.

---

## §4 — Verification

All commands run from
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

### §4.1 — `python3 scripts/validate-pack.py` (full validator)

Tail of output (Checks 32 / 33 / 34 SKIP gracefully because pack-self
has no `/backlog/` or `/changelog/` per-entry tree until BD-102 dog-
food fires; Check 35 (renumbered) passes; overall PASSED):

```
── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### §4.2 — `bash scripts/tests/test-validate-pack-checks-32-33-34.sh`

Tail of output (46/46 PASS):

```
=== Group E: SKIP behavior (no per-entry tree present) ===
  PASS E1.1 no tree → Check 32 rc=0 (SKIP)
  PASS E1.2 no tree → Check 32 says 'not present'
  PASS E1.3 no tree → Check 33 rc=0 (SKIP)
  PASS E1.4 no tree → Check 33 says 'not present'
  PASS E1.5 no tree → Check 34 rc=0 (SKIP)
  PASS E1.6 no tree → Check 34 says 'no per-entry trees present'

=== Summary ===
PASS: 46
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (46/46).
```

Per-group summary:
- Group D (STREAMS structural smoke): 3/3 PASS.
- Group A (Check 32 mirror-in-sync, including pre-checks a/b/c): 15/15 PASS.
- Group B (Check 33 TOC-in-sync): 10/10 PASS.
- Group C (Check 34 cross-reference integrity, including v8-archive
  SKIP, self-ref, cross-stream phase-N flag): 12/12 PASS.
- Group E (§10.5 SKIP behavior, all three checks): 6/6 PASS.

### §4.3 — Baseline regression suite (zero regression)

| Suite | Result |
|---|---|
| `bash scripts/tests/test-per-entry.sh` | 57/57 PASS |
| `bash scripts/tests/test-init-project.sh` | 34/34 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 61/61 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 87/87 PASS |
| `bash scripts/tests/tracker-agent-read-test.sh` | 31/31 PASS |
| `python3 scripts/validate-pack.py` | PASSED — all 33 invoked checks (numbered Check 1–11 and 16–35; Checks 12–15 retired per v9 sunset) clean |

All baseline tail outputs verified identical (modulo new Check 32/33/34
banners) to pre-edit baselines run before the implementation began.

### §4.4 — Bash 3.2 compatibility

Local shell: `GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)`
— the new test runner runs cleanly; no `declare -A`, no `[[ =~ ]]`,
no `readarray`/`mapfile`, no `<<<` here-strings, no `&>` redirect, no
GNU `sed -i ''` patterns. Python wrapper invocations use heredoc
PYEOF + env-var argument passing (no shell-array-to-Python translation).

### §4.5 — Working-tree-restore invariant (FAIL paths)

Tests A2.4, B2.4, and B3.3 assert that after a FAIL path, the working
tree is byte-identical to its pre-check state (validated via `shasum`
pre/post comparison; B3.3 validates by file existence — the regenerator
produced a new file but the validator deleted it before returning).
This is critical: the validator is a CI gate, not a fixer; it MUST
NOT mutate the working tree.

### §4.6 — `git rev-parse HEAD` (pre / post)

Pre-implementation: `91e497c591412a6bc0588ca0637727ce7c982803`
Post-implementation: `91e497c591412a6bc0588ca0637727ce7c982803`
(unchanged — no agent commits per `feedback_agents_never_commit`).

`git status` shows: 2 modified, 1 untracked, no other paths.

---

## §5 — Definition-of-Done checklist

| # | Criterion | Status |
|---|---|---|
| A.1 | 3 checks total per integration parent §10.4 (NOT 6 — others fold into Check 32 pre-checks). | PASS — Check 32 includes pre-check (a) `_rules.md`, (b) filename conformance, and (c) v8-archive byte-stability via the main divergence compare; Checks 33 + 34 are standalone per their distinct invariants. |
| A.2 | Each check SKIPs gracefully when per-entry tree absent (per §10.5). | PASS — verified by Group E (E1.1–E1.6) tests; verified live in §4.1 against pack-self (no `/backlog/` or `/changelog/` directory). |
| A.3 | Pack-side scope only per §10.6. | PASS — `STREAMS` includes only `pack-backlog` and `pack-changelog`; project-side trees are not loaded. Test C5 confirms cross-stream `phase-3` references are flagged as dangling (correct per §10.6). |
| A.4 | Check 34 SKIPs the v8 archive per §11.3. | PASS — `_v8-resolved-archive.md` is explicitly skipped via `v8_archive_basenames` set; `_extract_references(skip_v8_archive=True)` also suppresses anything after a `## Resolved — v\d+` H2 header inside any per-entry file. Test C3 verifies no FAIL for the historical `BD-999` reference inside the archive. |
| A.5 | `STREAMS` constant matches the tuple shape per §18.2 #5 + Addendum #1 §9.1 planner-deferred qualifier. | PASS — 4-tuples `(stream_key, stream_dir_relative, mirror_relative, entry_regex)`; structural smoke D1.1–D1.3 verifies. Tuple shape is planner-final (Addendum #1 §9.1 named "(planner picks function names + STREAMS constant shape)"). |
| A.6 | Each pseudo-code in §10 had its disclaimer per Addendum #1 §9 — planner refines exact implementation. | PASS — both `check_mirror_in_sync` and `check_cross_reference_integrity` docstrings open with "Pseudo-code sketches the behavioral contract; planner refines exact implementation (per Addendum #1 §9.2 disclaimer)." |
| A.7 | Each new check uses the existing check-function shape (banner, OK/FAIL prints, exit codes). | PASS — each function emits `\n── Check NN: <name> (BD-NNN) ──` banner, uses the pre-existing `ok()` / `fail()` helpers, runs inside `main()` so failures accumulate in the module-level `failures` list per the existing exit-code convention. |
| B.1 | `python3 scripts/validate-pack.py` PASSES on the pack repo as-is (Checks 32/33/34 SKIP). | PASS — see §4.1. |
| B.2 | `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` PASSES — green and red fixtures both correctly classified. | PASS — 46/46; see §4.2. |
| B.3 | All baseline tests preserved (zero regression). | PASS — see §4.3 (test-per-entry 57/57, test-init-project 34/34, test-migrate-v10-to-v11 43/43, test-migrate-v10-to-v11-dry-run 61/61, test-migrate-v10-to-v11-gates 87/87, tracker-agent-read 31/31). |
| B.4 | New test runner step is wired in `.github/workflows/validate-pack.yml` (step count increases by 1). | PASS — pre 40 steps → post 41 steps; new step "validate-pack Check 32/33/34 tests (BD-168, per-entry split validators)" is sourced via `bash scripts/tests/test-validate-pack-checks-32-33-34.sh`. |
| B.5 | Python 3 compatibility (existing validate-pack.py is Python 3). | PASS — uses `pathlib`, `tempfile`, `subprocess`, `re`, `os` — all stdlib; no Python 4+ features; `tomllib` import (already top-of-file) requires Python 3.11+ which is the existing baseline. |
| C.1 | No state-changing git verbs. | PASS — only `git status`, `git diff --numstat`, `git rev-parse HEAD` were invoked. HEAD unchanged. |
| C.2 | Bash 3.2 + macOS BSD-utility compatible for the test runner. | PASS — local bash is 3.2.57; new runner passes all 46 tests; no GNU-isms (verified via `grep -E "declare -A|readarray|mapfile|<<<|&>"` returns empty). |
| C.3 | Out-of-scope items surfaced to Pack Chat with no deferral recommendation. | PASS — see §7 below; the planner-pass undercount of pre-existing checks is surfaced as an in-v11.0 observation only (no deferral language). |

---

## §6 — Plan deviations

**Zero plan deviations.** The implementation matches the
plan §5.6 spec exactly:

- 3 checks added (Check 32 / 33 / 34 — not 6); pre-checks fold per §10.4.
- `STREAMS` constant added near `REPO_ROOT` per §18.2 #5.
- Test runner placed at `scripts/tests/test-validate-pack-checks-32-33-34.sh`
  per the §5.6 file table; coder picked single-file inline-fixture
  approach per §18.2 #6 planner-deferred (no separate
  `scripts/tests/fixtures/per-entry/` subdir — synthetic trees built
  inline in `mktemp` scratch directories). The §5.6 file table named
  the fixtures-out approach as an alternative; coder picked the
  inline approach because the green-fixture is small (3 entries +
  preamble + v8 archive + 4 supporting files), the green/red contrast
  reads better in-line, and the `build_green_pack_backlog` helper is
  reused across all 5 test groups.
- CI wiring lands in the same commit per Batch 21c "test-not-in-CI"
  empirical heuristic — the new tests-job step is appended after the
  existing `recommendation-state-schema tests` step.

The pre-existing Check 32 (`check_tracker_phase_task_invariants`) was
renumbered to Check 35 — see §7 for context. This was a mechanical
banner/docstring relabel, not a plan deviation; the plan undercounted
the pre-existing checks (named "31 check functions" but there were
actually 32; see §7).

---

## §7 — Out-of-scope items / observations for Pack Chat decision

**Surfaced for Pack Chat decision (no deferral recommendation per
`feedback_no_deferral_without_user_direction`):**

### §7.1 — Planner-pass pre-state undercount

`PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.6 "Pre-state" line states:

> "validate-pack.py has 31 check functions (highest is
> `check_skill_cell_consistency` Check 31 at line 2425, verified by
> `grep -n "^def check_"`)."

Direct verification (see §4 baseline run timestamp pre-edit):
`grep -n "^def check_" scripts/validate-pack.py | wc -l` returns 32,
not 31. The 32nd function is `check_tracker_phase_task_invariants`
which was already labeled "Check 32" in its banner. The plan line was
incorrect.

To honor the architect-doc mandate of three NEW checks numbered 32 / 33
/ 34, this implementation renumbered the pre-existing Check 32 banner
to Check 35 (function name unchanged). The renumber is a pure cosmetic
relabel — the function still runs, still passes, still exercises the
same `tracker-phase-task.sh` invariants per BD-106 / V3.3 §3 line 27.

**For Pack Chat to confirm:** the renumber-to-35 approach is
acceptable. Alternatives Pack Chat may prefer (NOT recommended by the
implementer; the renumber was the lowest-friction in-commit fix):
- (a) Re-allocate the new BD-168 checks as Check 33 / 34 / 35 and
  leave the existing Check 32 (BD-106) in place. This contradicts
  the architect-doc + plan which name the new checks as 32 / 33 / 34;
  it would also require Pack Chat to update integration parent §10
  banner numbers in a follow-up PM-only edit.
- (b) Accept the renumber-to-35 (this implementation's choice). No
  follow-up PM-only edits required.

### §7.2 — `test-per-entry.sh` not wired into CI (BD-164 territory)

While inspecting the workflow, I noticed
`scripts/tests/test-per-entry.sh` (BD-164, landed in Commit 19a) has
NO step in `.github/workflows/validate-pack.yml`. This is the same
"test-not-in-CI" gap that Batch 21c's empirical heuristic flags. The
implementer did NOT touch this because BD-164 is 19a's territory, not
19e's, and PR scope discipline forbids re-opening landed BD work.

**For Pack Chat to consider:** add a wiring step for
`bash scripts/tests/test-per-entry.sh` in 19h / 19i, or as a
`fix:` commit between 19e and 19h. The runner exists, passes 57/57
locally, and would block any future regression to the BD-164 helper
contract once wired. This is observation-only — Pack Chat decides
whether to treat it as scope-creep into 19e or a separate
out-of-batch fix.

### §7.3 — Project-side per-entry trees not validated by pack CI (per §10.6)

Per integration parent §10.6, project-side per-entry trees under
`project-template/docs/project/<stream>/` are validated by the
client's CI, not by `validate-pack.py`. The pack ships canonical
templates (`_rules.md`, `_intro.md`, `_format.md`) for the three
project streams (verified — `project-template/docs/project/{backlog,
changelog,implementation-plan}/_rules.md` all present per BD-167,
landed in Commit 19b-pack); but no entry files exist in those
directories during pack development.

This is correct per the architect-doc scope. No action needed —
named here so Pack Chat is aware that the validator's STREAMS
constant deliberately excludes the three project-side streams.

### §7.4 — Subprocess invocation cost

Each Check 32 + Check 33 invocation spawns a `bash -c` subprocess
that sources `_lib.sh` + the relevant helper. Per integration parent
§7.2 cost calculation, the per-stream cost is ~1.5 sec at v11.0
baseline; ~10 sec at v13 scale. CI tolerable. The pack-self CI today
SKIPs all subprocess invocations (no per-entry tree exists), so the
observed overhead is zero until BD-102 dog-food fires.

If BD-102 measures higher-than-expected overhead, possible
optimizations include batching multiple stream regenerations into one
subprocess + shared `_lib.sh` source. NOT a v11.0 concern; named
here only as a forward observation. NO deferral recommendation —
this is observation-only, not a scoping decision.

### §7.5 — Interaction with BD-102 dog-food

When BD-102 (Batch 23 per `EXECUTION-PLAN-V11.0.md:434`) lands the pack-self per-entry tree migration,
Checks 32 / 33 / 34 will fire on every push. A divergence between
`backlog/BD-NNN.md` files and the regenerated `BACKLOG.md` mirror
will cause CI to FAIL with a clear runnable recovery instruction
(per BD-168 retro M1: the FAIL message emits the fully-self-contained
`bash -c '. _lib.sh && . mirror-generate.sh && PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror pack-backlog backlog BACKLOG.md'` form).
This is the intended invariant per Goal 2 source-of-truth. Named here so Pack Chat is aware that Pack Chat workflow may
need a small dance after PM-only `BACKLOG.md` edits land — first
re-run the regenerator before staging, OR (preferred) edit the
per-entry file directly and let CI catch the drift if forgotten.

The sample pre-commit hook flagged in §18.1 #6 of the integration
parent + §5.6 of Addendum #1 was named optional + planner-decision;
this implementation does NOT ship the hook (deferred per the planner-
deferred Item #6, which Pack Chat may opt to add later).

---

End of report.
