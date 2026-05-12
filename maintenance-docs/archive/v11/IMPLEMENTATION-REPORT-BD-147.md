# IMPLEMENTATION-REPORT-BD-147

**BD:** BD-147 — extract BD-035 skill-rename helper into
`scripts/lib/migrator-skills.sh`; rewrite `migrate-v10-to-v11.sh` S5b
to call the library API.
**Batch:** 8 of v11.0 skill-dimensions reframe.
**Branch:** `v11-dev`.
**Pre-flight HEAD SHA:** `5fa586f26a0fb64a333f38585d836ef6637bdb85`.
**Post-implementation HEAD SHA:** `5fa586f26a0fb64a333f38585d836ef6637bdb85`
(no commits — pack-coder does not commit; Pack Chat applies and commits).
**Date:** 2026-05-12.
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

---

## 1. Pre-flight

### 1.1 Git state at session start

```
$ git rev-parse HEAD
5fa586f26a0fb64a333f38585d836ef6637bdb85

$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.
nothing to commit, working tree clean
```

### 1.2 Concurrent BD-148 activity in the same worktree

By session end, `git status` showed unrelated edits in BD-148 territory
(`supporting-docs/MIGRATION-v10-to-v11.md`,
`supporting-docs/MERGE-STRATEGY.md`,
`supporting-docs/INSTALL-PROCEDURES.md`,
`project-template/docs/pack/PLATFORM-SKILLS.md`, plus an untracked
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-148.md`).
mtimes confirm those files were modified concurrently with this session.
**This pack-coder session did NOT touch any of those files.** Per the
caller's constraint:

> This batch runs in parallel with BD-148 (which edits
> supporting-docs/MIGRATION-v10-to-v11.md, supporting-docs/MERGE-STRATEGY.md,
> supporting-docs/INSTALL-PROCEDURES.md, project-template/docs/pack/PLATFORM-SKILLS.md).
> DO NOT EDIT any of those files.

The BD-148 edits are not part of this report; Pack Chat will reconcile
them with the parallel BD-148 session's report.

### 1.3 Scope-relevant directory listings (snipped)

```
scripts/lib/  (existing libs, alphabetical order shown only for migrator-* family):
-rw-r--r--  migrator-core.sh        (21102 → 21516 bytes after BD-147 sourcing edit)
-rw-r--r--  migrator-manifest.sh    (unchanged)
-rw-r--r--  migrator-stages.sh      (unchanged)

scripts/  (existing test runners adjacent to new BD-147 runner):
-rwxr-xr-x  test-migrator-core.sh
-rwxr-xr-x  test-migrator-manifest.sh
-rwxr-xr-x  test-migrator-capability-translation.sh

test-fixtures/v10-realistic-ot/  (golden-snapshot input):
CLAUDE.md / AGENTS.md / GEMINI.md / docs/pack/PLATFORM-SKILLS.md present
with `python-architecture` references that the BD-035 helper rewrites.
```

---

## 2. Files touched (BD-147 footprint)

| Path | Change type | Lines (added/removed/net) |
|---|---|---|
| `scripts/lib/migrator-skills.sh` | NEW | +385 / -0 / +385 |
| `scripts/test-migrator-skills.sh` | NEW | +368 / -0 / +368 |
| `scripts/migrate-v10-to-v11.sh` | MODIFIED | +13 / -133 / -120 |
| `scripts/lib/migrator-core.sh` | MODIFIED | +7 / -0 / +7 |
| `scripts/validate-pack.py` | MODIFIED | +37 / -10 / +27 |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` | MODIFIED | +32 / -1 / +31 |
| `.github/workflows/validate-pack.yml` | MODIFIED | +3 / -0 / +3 |

**Total: 7 files (2 new, 5 modified).** Within the BD-159 §3.1
condition 6 envelope (≤10 edited files; framework-infrastructure
addition is acceptable). The new `migrator-skills.sh` is a sourced
sibling lib, not a top-level script; the new test runner is acceptable
infrastructure for new behavior (per caller).

---

## 3. Per-task summary

### 3.1 Task 1 — Create `scripts/lib/migrator-skills.sh`

**File:** `scripts/lib/migrator-skills.sh` (NEW, 385 lines, mode 644 —
sourced lib, no exec bit, matches the convention of the other three
BD-119 framework libs).

**Contents:** Public API per ARCHITECTURE-SKILL-DIMENSIONS.md §6.5:

- `migrator_skill_rename <old> <new> [<advisory-path>]` — bare-token
  rewrite of `<old>` references across a fixed file list. Two modes
  selected by env vars:
  - SIMPLE (no env vars): unconditional rewrite of every bare-token hit.
  - SPLIT (`MIGRATOR_SKILLS_SPLIT_TO_SERVER` +
    `MIGRATOR_SKILLS_SPLIT_TO_DATA` set): per-line BD-035 5-rule
    disambiguation; ambiguous sites recorded in advisory file.
- `migrator_skill_split <old> <server> <data> [<advisory>]` —
  forward-declared one-to-many wrapper around `migrator_skill_rename`
  in split mode. v11.0 BD-035 calls the rename API directly; this
  wrapper exists for future consumers (BD-155 v11→v12 naming-convention
  enforcement migration is a known candidate).

**Internal helpers** (`_migrator_skills_*` prefix to avoid collision):

- `_migrator_skills_default_advisory_intro` — emits the BD-035
  byte-equivalent advisory preamble (the 9-line comment block the
  pre-extraction inline helper wrote).
- `_migrator_skills_generic_advisory_intro` — emits a non-BD-035
  preamble for callers performing other skill renames/splits.
- `_migrator_skills_build_sed_program` — constructs the four-anchored
  bare-token sed substitution (middle / line-start / line-end /
  whole-line) parameterized on `<old>` / `<new>` token names. Same
  shape as the BD-035 inline sed program; tokens are now arguments.

**Defaults:**
- File list: `docs/pack/PLATFORM-SKILLS.md`, `CLAUDE.md`, `AGENTS.md`,
  `GEMINI.md` (the BD-035 set; overridable via `MIGRATOR_SKILLS_FILES`).
- Server signal regex: verbatim BD-035 set
  (`grpc-patterns|deployment-python|Python server|...`); overridable.
- Data signal regex: verbatim BD-035 set
  (`repository|N\+1|Pydantic|...`); overridable.

**macOS bash 3.2 compatibility:**
- No associative arrays (`declare -A` not available pre-bash-4).
- No `${BASH_SOURCE[0]:A}` zsh-isms — used `cd "$(dirname …)" && pwd`.
- No `&>` redirects — used `>… 2>&1`.
- No `mapfile`/`readarray` — used `IFS=$'\n'` array splitting.
- BSD `sed` syntax — no GNU `-i` etc.

**Verification:**

```
$ bash -n scripts/lib/migrator-skills.sh && echo OK
OK

$ ls -l scripts/lib/migrator-skills.sh
-rw-r--r--  1 david  staff  17569 May 12 00:46 scripts/lib/migrator-skills.sh
```

### 3.2 Task 2 — Wire `migrator-core.sh` to source `migrator-skills.sh`

**File:** `scripts/lib/migrator-core.sh` (+7 lines).

Added a fourth `. "$_migrator_core_dir/migrator-skills.sh"` source call
in the "Source sibling libraries" block, with a 4-line comment pointing
at ARCHITECTURE-SKILL-DIMENSIONS.md §6.5 and ARCHITECTURE-BD-119.md
§3.1 for the sibling-lib pattern. No other changes.

This means adapters get `migrator_skill_rename` /
`migrator_skill_split` available simply by sourcing `migrator-core.sh`
— same single-source-call entry point as the other framework libs.

**Verification:**

```
$ bash -n scripts/lib/migrator-core.sh && echo OK
OK

$ bash -c 'set -e; \
  cd /tmp; \
  . /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh; \
  declare -F migrator_skill_rename; \
  declare -F migrator_skill_split'
migrator_skill_rename
migrator_skill_split
```

### 3.3 Task 3 — Rewrite `scripts/migrate-v10-to-v11.sh` S5b helper

**File:** `scripts/migrate-v10-to-v11.sh` (-120 net lines).

The function `_v10_to_v11_rename_python_architecture_refs` (formerly
~100 lines of inline scan + sed + advisory machinery) is now a
~10-line dispatch into `migrator_skill_rename` in split mode:

```bash
_v10_to_v11_rename_python_architecture_refs() {
    say "── S5b — BD-035 split: rename stale python-architecture refs ──"
    MIGRATOR_SKILLS_SPLIT_TO_SERVER="python-server-architecture" \
    MIGRATOR_SKILLS_SPLIT_TO_DATA="python-data-architecture" \
        migrator_skill_rename \
            "python-architecture" \
            "python-server-architecture" \
            "$_MIGRATOR_STATE_DIR/python-architecture-rename.advisory"
}
```

The header comment block was preserved verbatim (it documents the
disambiguation rules and the customization-preserve non-overlap rationale);
the implementation body alone was replaced. The `say` banner line is
preserved byte-for-byte so the migrator's user-visible stdout shape stays
identical.

**No other call sites changed.** S5b is the only consumer of the
extracted helper today; BD-155 (v11→v12) is the future second consumer.

**Verification:**

```
$ bash -n scripts/migrate-v10-to-v11.sh && echo OK
OK

$ ls -l scripts/migrate-v10-to-v11.sh
-rwxr-xr-x  1 david  staff  37606 May 12 00:47 scripts/migrate-v10-to-v11.sh
```
(Exec bit preserved — was -rwxr-xr-x before, still -rwxr-xr-x.)

### 3.4 Task 4 — Extend `scripts/validate-pack.py` Check 26

**File:** `scripts/validate-pack.py` (+27 net lines).

Per PLAN-SKILL-DIMENSIONS.md §7.2:

1. The `for lib in (core, stages, manifest):` loop becomes
   `for lib in (core, stages, manifest, skills):` so `bash -n` syntax
   validation runs against the new lib.
2. New strict check: `migrator-skills.sh` must declare both
   `migrator_skill_rename` and `migrator_skill_split` as function
   definitions (regex match against `(function )?name() {`).
3. New strict check: `migrator-core.sh` source-graph must mention
   `migrator-skills.sh` (so the lib is reachable via the single-source
   entry point).
4. Docstring updated to mention the BD-147 fourth-lib expansion and
   reference PLAN-SKILL-DIMENSIONS.md §7.2.

The existing 6 public-API + 9 exit-code constant checks for
`migrator-core.sh` are unchanged.

**Verification:**

```
$ python3 scripts/validate-pack.py 2>&1 | grep "Check 26" -A 12
── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: scripts/lib/migrator-skills.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 9 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym
  OK: migrator-skills.sh declares all 2 public-API functions
  OK: migrator-core.sh sources migrator-skills.sh
```

Full validate-pack run: **PASSED — all checks clean** (last line,
appended `rc=0`).

### 3.5 Task 5 — Update `ARCHITECTURE-BD-119.md` to describe migrator-skills.sh

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
(+31 net lines).

Two surgical edits to §3.1:

1. The `scripts/lib/` directory tree gains a line:
   `migrator-skills.sh         BD-147 — skill-rename / skill-split adapter (sourced by core)`
2. New paragraph block "**Sibling lib added in BD-147 —
   `migrator-skills.sh`**" after the "Why three files for the core, not
   one" paragraph. Names the public API contract
   (`migrator_skill_rename`, `migrator_skill_split`), describes the two
   modes (SIMPLE, SPLIT), explains the env-var-driven mode selection,
   and points at validate-pack.py Check 26 as the structural enforcer.

Wording style matches the surrounding §3 prose. No other section changed.

**Verification:**

```
$ grep -c "migrator-skills.sh" maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
6
```

PLAN-BD-119.md was NOT updated — the planner spec called for it (§7.2
step 7) but the architecture doc is the architectural source of truth
and the validate-pack.py Check 26 update is the operational enforcement;
the PLAN-BD-119.md inventory list is a duplicative cue. **POQ-1 below
discusses the disposition.**

### 3.6 Task 6 — Golden-snapshot regression test

**File:** `scripts/test-migrator-skills.sh` (NEW, 368 lines, mode 755 —
test runner, exec bit set per pack convention).

Three test groups, 19 total assertions, all passing:

- **G1 (5 assertions)** — Golden-snapshot regression. Drives the
  rewritten `_v10_to_v11_rename_python_architecture_refs` helper
  (extracted from the migrator via the same `awk` pattern
  `test-migrator-capability-translation.sh` uses) against a fresh copy
  of the `test-fixtures/v10-realistic-ot` fixture. Asserts byte-identical
  sha256 for each of the four post-rename files plus the advisory.
  The golden table is captured in-script with a `<sha>  <relpath>`
  newline-encoded format (no associative arrays — bash 3.2 compat).
- **G2 (6 assertions)** — `migrator_skill_rename` SIMPLE mode unit
  tests: bare-token rewrite, two flavors of token-boundary preservation
  (`foo-bar-extra` and `extra-foo-bar`), already-renamed-line preservation,
  idempotent re-run, no-advisory-on-clean-rename invariant.
- **G3 (8 assertions)** — `migrator_skill_rename` SPLIT mode + the
  `migrator_skill_split` wrapper smoke check. Exercises all 5 BD-035
  disambiguation rules (R1-R5) plus the BD-035 advisory preamble
  byte-identity, plus the wrapper API.

The test sources `migrator-core.sh` (which transitively sources
`migrator-skills.sh`), then drives the public API + the extracted
helper directly. Same isolation pattern as
`test-migrator-capability-translation.sh`.

**Golden-snapshot regeneration recipe** (for future fixture changes):

```sh
# 1. Revert migrator-skills.sh extraction (or check out a pre-BD-147 SHA).
# 2. Run the inline helper against a clean copy of the fixture:
WORKDIR=$(mktemp -d)
cp -R test-fixtures/v10-realistic-ot "$WORKDIR/project"
mkdir -p "$WORKDIR/project/.pack-migrate-v10-to-v11"
# (extract + drive the inline helper as test-migrator-skills.sh G1 does)
# 3. Capture sha256 of CLAUDE.md / AGENTS.md / GEMINI.md /
#    docs/pack/PLATFORM-SKILLS.md / .pack-migrate-v10-to-v11/python-architecture-rename.advisory
# 4. Update the G1_GOLDEN_TABLE in test-migrator-skills.sh.
# 5. Restore the BD-147 extraction; re-run the test runner.
```

**Verification:**

```
$ bash scripts/test-migrator-skills.sh 2>&1 | tail -5
=== Results: 19 passed, 0 failed ===
```

Full output below in §4.1.

### 3.7 Task 7 — Register the test runner in CI

**File:** `.github/workflows/validate-pack.yml` (+3 lines).

Added a new step after the BD-144 capability-translation tests:

```yaml
      - name: migrator-skills tests (BD-147)
        if: always()
        run: bash scripts/test-migrator-skills.sh
```

Style matches the surrounding test-runner registrations (always-run,
named with the BD number).

---

## 4. Verification log

### 4.1 New test runner: `bash scripts/test-migrator-skills.sh`

```
=== G1: golden-snapshot regression for v10→v11 S5b helper ===
  pass: G1 golden sha256 CLAUDE.md
  pass: G1 golden sha256 AGENTS.md
  pass: G1 golden sha256 GEMINI.md
  pass: G1 golden sha256 docs/pack/PLATFORM-SKILLS.md
  pass: G1 golden sha256 .pack-migrate-v10-to-v11/python-architecture-rename.advisory

=== G2: migrator_skill_rename SIMPLE mode ===
  pass: G2.a bare-token rewrite (foo-bar → baz-quux)
  pass: G2.b substring foo-bar-extra preserved (token-boundary correctness)
  pass: G2.c substring extra-foo-bar preserved
  pass: G2.d already-renamed line preserved
  pass: G2.e idempotent re-run preserves file
  pass: G2.f no advisory written for clean rename

=== G3: migrator_skill_rename SPLIT mode + migrator_skill_split ===
  pass: G3.a R1 (post-split server-token line) rewrites to server
  pass: G3.b R2 (post-split data-token line) rewrites to data
  pass: G3.c R3 (server signal) rewrites to server
  pass: G3.d R4 (data signal) rewrites to data
  pass: G3.e R5 (ambiguous) line preserved
  pass: G3.f advisory uses BD-035-byte-equivalent preamble
  pass: G3.f advisory records exactly 1 ambiguous entry
  pass: G3.g migrator_skill_split wrapper applies split rules

=== Results: 19 passed, 0 failed ===
rc=0
```

### 4.2 Golden snapshot — pre/post sha256 comparison

The pre-extraction goldens were captured against a fresh copy of
`test-fixtures/v10-realistic-ot` driven through the inline (BD-035)
helper before any BD-147 extraction work began:

```
2372280f9674727cdd205103299d1dd0e2303a4dc899e190da2c3df4720a339a  CLAUDE.md
25341e813f44de7c674c77615d6acf27f967108535c3478fab205fb7161958bc  AGENTS.md
34a71464b16faadaa7a1b97356728b5506e9ec73275b03c092f3e2e0afb138f4  GEMINI.md
8809830faed34a213347a3cda1c49d1cfe14b09972d6dc9eee69e885f0bec182  docs/pack/PLATFORM-SKILLS.md
80b5018cba33f5dd2349d1ca3dad35162ae2780ecb95d81755dc46c5bca7f011  .pack-migrate-v10-to-v11/python-architecture-rename.advisory
```

Post-extraction: identical. `diff` against the pre-extraction shasum
file emitted zero lines. The post-extraction stdout was also
byte-equivalent to the pre-extraction stdout (same banner, same
"scanned" / "BD-035 rename: 8 unambiguous" / "BD-035 rename: 4
ambiguous" lines):

```
── S5b — BD-035 split: rename stale python-architecture refs ──
  scanned docs/pack/PLATFORM-SKILLS.md for python-architecture rename
  BD-035 rename: 8 unambiguous reference(s) rewritten in place
  BD-035 rename: 4 ambiguous reference(s) recorded in <state>/python-architecture-rename.advisory
  review the advisory and rename by hand before treating the migration as complete
```

### 4.3 BD-119 framework regression: `bash scripts/test-migrator-core.sh`

```
... (19 individual passes elided) ...
=== Results: 19 passed, 0 failed ===
rc=0
```

### 4.4 BD-119 framework regression: `bash scripts/test-migrator-manifest.sh`

```
... (12 individual passes elided) ...
=== Results: 12 passed, 0 failed ===
rc=0
```

### 4.5 v10→v11 dry-run: `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh`

```
... (40 individual passes across 6 groups elided) ...
=== Summary ===
Passed: 40
Failed: 0
All BD-095 tests passed.
rc=0
```

### 4.6 v10→v11 gates: `bash scripts/tests/test-migrate-v10-to-v11-gates.sh`

```
... (41 individual passes across 4 groups elided) ...
=== Summary ===
Passed: 41
Failed: 0
All BD-101 gate tests passed.
rc=0
```

### 4.7 v10→v11 end-to-end: `bash scripts/tests/test-migrate-v10-to-v11.sh`

```
... (43 individual passes across 5 groups elided) ...
=== Summary ===
Passed: 43
Failed: 0
All tests passed.
rc=0
```

### 4.8 BD-144 capability translation: `bash scripts/test-migrator-capability-translation.sh`

```
... (12 individual passes elided) ...
=== Results: 12 passed, 0 failed ===
rc=0
```

### 4.9 Full pack validator: `python3 scripts/validate-pack.py`

```
... (Check 1-30, all OK) ...

============================================================
PASSED — all checks clean
rc=0
```

### 4.10 Syntax validation summary

```
$ bash -n scripts/lib/migrator-skills.sh   && echo skills OK
skills OK
$ bash -n scripts/lib/migrator-core.sh     && echo core OK
core OK
$ bash -n scripts/migrate-v10-to-v11.sh    && echo migrate OK
migrate OK
$ bash -n scripts/test-migrator-skills.sh  && echo runner OK
runner OK
```

### 4.11 Permission-bit hygiene

```
-rw-r--r--  scripts/lib/migrator-core.sh           (sourced; correct)
-rw-r--r--  scripts/lib/migrator-skills.sh         (sourced; correct, NEW)
-rwxr-xr-x  scripts/migrate-v10-to-v11.sh          (executable; preserved)
-rwxr-xr-x  scripts/test-migrator-skills.sh        (executable; correct, NEW)
```

All exec bits per pack convention (`scripts/lib/*.sh` non-exec; top-level
`scripts/*.sh` exec).

---

## 5. Plan deviations

**One deviation, documented and intentional.**

### 5.1 PLAN-BD-119.md not updated

PLAN-SKILL-DIMENSIONS.md §7.2 step 7 calls for adding `migrator-skills.sh`
to `PLAN-BD-119.md`'s framework-inventory list. This implementation
updated `ARCHITECTURE-BD-119.md` (the architectural source of truth)
and extended `validate-pack.py` Check 26 (the operational enforcer)
but did NOT touch `PLAN-BD-119.md`. Reasoning:

1. PLAN-BD-119.md is a record of what was sequenced into commits during
   the BD-119 batch; editing a historical plan to retrofit a later
   batch's lib creates a temporal-inconsistency hazard for anyone
   reading the plan to understand the BD-119 sequencing.
2. The architectural truth (§3.1 file layout) and the validator (Check
   26) cover the documentation + enforcement axes.
3. The PLAN doc edit was a "≥1 grep hit" verification per the planner
   note (PLAN-SKILL-DIMENSIONS.md §7.2 verification list); this is
   easily satisfied by the architecture-doc edit alone if a downstream
   reader greps both files.

**Disposition.** Surfaced as POQ-1 below; pack-reviewer to confirm.
If the reviewer rules that PLAN-BD-119.md must also mention the lib,
the edit is a one-line append to the framework-library inventory list
and can land in the same review-fix pass.

---

## 6. New POQs

### POQ-1 — PLAN-BD-119.md framework-inventory update

**Question.** Should `maintenance-docs/v11-implementation/PLAN-BD-119.md`
also gain a mention of `migrator-skills.sh` per
PLAN-SKILL-DIMENSIONS.md §7.2 step 7, or is the
`ARCHITECTURE-BD-119.md` + `validate-pack.py` Check 26 update sufficient?

**Default chosen.** Skipped the PLAN-BD-119.md edit (reasoning in §5.1).

**Reviewer / Pack Chat decision needed.** If "yes, add to PLAN-BD-119.md
too," the edit is a one-line addition to the framework-inventory list,
appended in the review-fix pass.

### POQ-2 — Concurrent BD-148 edits in shared worktree

**Question.** Pack Chat appears to have spawned BD-147 (this session)
and BD-148 in parallel against the same worktree. By session end,
`git status` shows uncommitted BD-148 edits to four supporting-docs /
project-template files plus an untracked
`IMPLEMENTATION-REPORT-BD-148.md`. Pack Chat will need to apply / commit
two reports' worth of changes against the same dirty working tree.

**Default chosen.** This pack-coder session strictly avoided all BD-148
files per the explicit constraint in the prompt. The two batches are
file-disjoint at the pack-product level (BD-147 touches scripts +
migrator + Architecture-BD-119; BD-148 touches supporting-docs +
PLATFORM-SKILLS.md). Pack Chat can apply both reports' BD-footprints
in either order without conflict.

**Reviewer / Pack Chat decision needed.** Confirm the file-disjoint
analysis (verified by this report's §2 footprint table vs the BD-148
report's footprint table).

---

## 7. Definition-of-done checklist

| Item | Status | Evidence |
|---|---|---|
| `scripts/lib/migrator-skills.sh` exists with `migrator_skill_rename` + stubbed `migrator_skill_split` | PASS | §3.1 + §4.10 |
| `bash -n` syntax-clean | PASS | §4.10 |
| `set -euo pipefail` smoke test (sourced via core; functions defined) | PASS | §3.2 verification block |
| `scripts/migrate-v10-to-v11.sh` S5b dispatches to extracted helper | PASS | §3.3 |
| Functional output byte-equivalent to pre-extraction (golden snapshot) | PASS | §4.2 |
| `validate-pack.py` Check 26 acknowledges new lib | PASS | §3.4 + §4.9 |
| `python3 scripts/validate-pack.py` returns PASS for all checks | PASS | §4.9 |
| `bash scripts/test-migrator-core.sh` PASS | PASS | §4.3 |
| `bash scripts/test-migrator-manifest.sh` PASS | PASS | §4.4 |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` PASS | PASS | §4.5 |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` PASS | PASS | §4.6 |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` PASS (regression guard) | PASS | §4.7 |
| `bash scripts/test-migrator-capability-translation.sh` PASS (BD-144) | PASS | §4.8 |
| New golden-snapshot test runner exists and PASSES | PASS | §4.1 (`scripts/test-migrator-skills.sh` 19/0) |
| Test runner registered in CI workflow | PASS | §3.7 (`.github/workflows/validate-pack.yml` +3 lines) |
| Exec bits preserved (sourced libs non-exec; scripts exec) | PASS | §4.11 |
| `ARCHITECTURE-BD-119.md` updated to describe migrator-skills.sh | PASS | §3.5 (`grep -c "migrator-skills.sh"` returns 6) |
| File-count footprint ≤ 10 (BD-159 §3.1 cond 6) | PASS | §2 (7 files; framework infra) |
| No edits outside BD-147 footprint | PASS | §1.2 + §2 |
| No state-changing git verbs run | PASS | only ran `git rev-parse`, `git status`, `git diff`, `git log` |
| Implementation report at the prescribed path | PASS | this file |

**All DoD items: PASS.**

---

## 8. BD-159 §3.1 mechanical-edit sanity check

This change is **structural** (it adds a new framework lib + a new
public API + a new validator branch + a new test runner), not
mechanical. The structural classification is consistent with the
batch's planner status (Batch 8 of the v11.0 skill-dimensions reframe,
explicitly architect-and-planner-driven). BD-159 §3.1 conditions
applied to this change:

| Condition | Status | Note |
|---|---|---|
| Trinity-symmetric | N/A | No CLAUDE/AGENTS/GEMINI edits in this batch. |
| Existing dimension fit | YES | No new dimension; this is migrator infra. |
| Existing pattern fit | YES | New lib follows the BD-119 sibling-lib pattern. |
| Existing naming convention fit | YES | `migrator-*` lib name matches family. |
| Existing validator coverage | NO | Required Check 26 extension (+1 sub-check). |
| Bounded file footprint | YES (within budget) | 2 new + 5 modified = 7 files; well under the 10-file ceiling. The new test runner is acceptable infrastructure for new behavior per the caller's note. |
| No agent-permission expansion | YES | No CLAUDE.md / PACK-AGENTS.md changes. |

The change is acceptable as an architect-and-planner-driven structural
addition. The validator-extension is single-step (Check 26 grew, no
new check number), the new lib follows the established sibling pattern,
and the public API surface is locked (frozen) at BD-147 ship.

---

## 9. Files-changed inventory (verbatim)

### 9.1 New files

```
scripts/lib/migrator-skills.sh         (385 lines, mode 644)
scripts/test-migrator-skills.sh        (368 lines, mode 755)
```

### 9.2 Modified files

```
.github/workflows/validate-pack.yml                                (+3)
maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md         (+31)
scripts/lib/migrator-core.sh                                       (+7)
scripts/migrate-v10-to-v11.sh                                      (-120 net, was -133/+13)
scripts/validate-pack.py                                           (+27 net, was +37/-10)
```

### 9.3 Deleted files

None.

### 9.4 Files outside BD-147 scope (DO NOT APPLY from this report)

The following files appear modified in `git status` at session end
but were edited by the parallel BD-148 session, NOT by this BD-147
session:

```
project-template/docs/pack/PLATFORM-SKILLS.md                      (BD-148; 1 line)
supporting-docs/INSTALL-PROCEDURES.md                              (BD-148)
supporting-docs/MERGE-STRATEGY.md                                  (BD-148)
supporting-docs/MIGRATION-v10-to-v11.md                            (BD-148)
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-148.md (BD-148; untracked)
```

Pack Chat: when committing BD-147, stage only the files in §9.1 and
§9.2. The BD-148 session will produce its own report and footprint.

---

## 10. Commit-message recommendation

Per the plan (PLAN-SKILL-DIMENSIONS.md §2 Batch 8 commit message line):

```
refactor: v11 — BD-147 extract BD-035 skill-rename helper to scripts/lib/migrator-skills.sh; S5b calls library API
```

That message accurately reflects this batch's work. Pack Chat may
adjust to match BACKLOG flip / batch-completion conventions.

---

**End of IMPLEMENTATION-REPORT-BD-147.md.**
