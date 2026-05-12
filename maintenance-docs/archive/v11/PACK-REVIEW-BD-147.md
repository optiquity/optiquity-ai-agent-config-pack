# PACK-REVIEW-BD-147

**Verdict:** APPROVE WITH NITS — implementation is correct, framework-compliant, byte-equivalent, and fully tested; one trinity-class layout omission (README) and the POQ-1 PLAN-BD-119.md disposition warrant a one-pass fix in this batch.

**Date:** 2026-05-12.
**Reviewer:** pack-reviewer.
**Inputs read:** ARCHITECTURE-SKILL-DIMENSIONS.md §6.5; PLAN-SKILL-DIMENSIONS.md §2 Batch 8 / §4.5 / §7.2; ARCHITECTURE-BD-119.md (full); scripts/lib/migrator-core.sh; the 7 BD-147 working-tree files; the IMPLEMENTATION-REPORT-BD-147.md POQ section. **Not read:** any prior PACK-REVIEW-*.md (per prompt constraint); BD-148 in-flight files.
**Tests run during review:** `bash scripts/test-migrator-skills.sh` (19/19 PASS), `bash scripts/test-migrator-core.sh` (19/19 PASS), `bash scripts/test-migrator-manifest.sh` (12/12 PASS), `bash scripts/test-migrator-capability-translation.sh` (12/12 PASS), `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (40/40 PASS), `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` (41/41 PASS), `bash scripts/tests/test-migrate-v10-to-v11.sh` (43/43 PASS), `python3 scripts/validate-pack.py` (PASSED — all checks clean), `bash -n` on all four shells.

---

## 1. Per-concern findings

### Concern 1 — Migrator framework compliance (sibling-lib, not fork)

**Status:** PASS.

`scripts/lib/migrator-skills.sh` is a stand-alone library, sourced by
`scripts/lib/migrator-core.sh` at lines 47-53 alongside its three
sibling libs (`migrator-stages.sh`, `migrator-manifest.sh`). The
sourcing comment cites both `ARCHITECTURE-SKILL-DIMENSIONS.md §6.5`
and `ARCHITECTURE-BD-119.md §3.1`, marking the sibling-lib intent.

The new file does NOT duplicate any state-management, exit-code, or
preflight code from `migrator-core.sh` / `migrator-stages.sh`; it
contributes a new public API (`migrator_skill_rename`,
`migrator_skill_split`) and reads the framework's `_MIGRATOR_TARGET`
and `_MIGRATOR_STATE_DIR` plus `say` / `info` / `fail_stage` helpers
that already exist in core. No copy-and-rewrite. (Cf.
`scripts/lib/migrator-skills.sh:208-220` for the `_MIGRATOR_TARGET` /
`_MIGRATOR_STATE_DIR` reads, and lines 254-258 / 332-337 for the
`fail_stage` calls.)

The sourcing site is correct: `migrator-core.sh:41-53` resolves
`_migrator_core_dir` once and sources all three siblings via that
prefix, so adapters get the API via the existing single-source pattern.

### Concern 2 — API design

**Status:** PASS.

The signature in the prompt — `migrator_skill_rename <old-skill-dir> <new-skill-dir> [<advisory-text>]` — matches the architecture in
`ARCHITECTURE-BD-119.md:150-156` (positional, three args; mode
selection by env var). Implementation at
`scripts/lib/migrator-skills.sh:188-359` is positional, accepts
SIMPLE / SPLIT modes via `MIGRATOR_SKILLS_SPLIT_TO_SERVER` /
`MIGRATOR_SKILLS_SPLIT_TO_DATA` env vars, and validates that BOTH
must be set together (lines 198-206).

`migrator_skill_split <old> <new-server> <new-data> [<advisory-path>]`
is forward-declared at lines 373-385 as a thin wrapper around
`migrator_skill_rename` in split mode. Signature matches the
architecture (`ARCHITECTURE-BD-119.md:157-162`). Body is real (not a
stub-that-errors), wrapping the underlying call with the env-var
hand-off.

NIT (non-blocking): The `info "BD-035 rename: ..."` user-facing strings
at `scripts/lib/migrator-skills.sh:348` / `:350` / `:353` hardcode
"BD-035 rename" in the summary lines regardless of caller. A future
non-BD-035 caller will see "BD-035 rename: 0 unambiguous references
found to rewrite" even when renaming `foo-bar` → `baz-quux`. The G2
test does not assert on stdout text, so this would not fire there.
Also the special-case at lines 314-317 hardcodes the python-architecture
preamble selector. Both are explicitly authorized by
`ARCHITECTURE-BD-119.md:147-156` ("v11.0 BD-035 calls
`migrator_skill_rename` in split mode directly") and PLAN-SKILL-DIMENSIONS.md
§2 Batch 8 byte-equivalence requirement, so they remain acceptable for
v11.0. Recommend a v11.x follow-up to parameterize the `info` banner
and to require an explicit advisory-preamble override flag for
non-default callers.

### Concern 3 — S5b extraction byte-equivalence (golden-snapshot)

**Status:** PASS.

`scripts/migrate-v10-to-v11.sh:_v10_to_v11_rename_python_architecture_refs`
(post-extraction, lines 380-398) is a 13-line wrapper that sets the
two split-mode env vars and dispatches to `migrator_skill_rename`.
The pre-extraction 133-line inline body has been removed. Behavior
is byte-equivalent per the G1 golden-snapshot harness in
`scripts/test-migrator-skills.sh:114-170`, which:

1. Copies `test-fixtures/v10-realistic-ot` to a temp dir.
2. Extracts the post-extraction helper from `migrate-v10-to-v11.sh` via
   `awk` (lines 126-130 — exercises the actual call site, not the
   library in isolation).
3. Runs it against the fixture.
4. Asserts sha256 of the four rewritten files plus the generated
   advisory match the goldens captured pre-extraction (lines
   152-156).

All five G1 sha256 assertions PASS in this review's test run:

```
=== G1: golden-snapshot regression for v10→v11 S5b helper ===
  pass: G1 golden sha256 CLAUDE.md
  pass: G1 golden sha256 AGENTS.md
  pass: G1 golden sha256 GEMINI.md
  pass: G1 golden sha256 docs/pack/PLATFORM-SKILLS.md
  pass: G1 golden sha256 .pack-migrate-v10-to-v11/python-architecture-rename.advisory
```

Disambiguation rules (R1..R5) are exercised by G3.a..G3.e — all PASS.
Token-boundary correctness is exercised by G2.b/G2.c — all PASS.
Idempotency by G2.e — PASS.

### Concern 4 — Check 26 extension

**Status:** PASS.

`scripts/validate-pack.py:1786-1916` correctly extends Check 26 from
3 libs to 4. The `for lib in (core, stages, manifest, skills)` loop
at line 1829 covers all four; new sub-checks at lines 1885-1911
require:

- All public-API function names in `migrator-skills.sh`
  (`migrator_skill_rename`, `migrator_skill_split`) are defined.
- `migrator-core.sh` text contains the literal `migrator-skills.sh`
  (proves the sourcing wiring).

Live run during review:

```
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

Docstring (lines 1786-1810) updated to name 4 libs and reference
PLAN-SKILL-DIMENSIONS.md §7.2.

### Concern 5 — No regression in framework tests

**Status:** PASS.

| Test | Result |
|---|---|
| `bash scripts/test-migrator-core.sh` | 19 passed, 0 failed |
| `bash scripts/test-migrator-manifest.sh` | 12 passed, 0 failed |
| `bash scripts/test-migrator-capability-translation.sh` | 12 passed, 0 failed |

### Concern 6 — No regression in v10→v11 migrator tests

**Status:** PASS.

| Test | Result |
|---|---|
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 40 passed, 0 failed |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 41 passed, 0 failed |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43 passed, 0 failed |

### Concern 7 — CI wiring

**Status:** PASS.

`.github/workflows/validate-pack.yml:110-112` adds the new step:

```yaml
      - name: migrator-skills tests (BD-147)
        if: always()
        run: bash scripts/test-migrator-skills.sh
```

Placement is parallel to the BD-119 / BD-144 test runners (lines
102-109). `if: always()` matches the surrounding pattern so a prior
test failure does not prevent this one from running.

### Concern 8 — ARCHITECTURE-BD-119.md update

**Status:** PASS.

`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`:
- Line 112: `migrator-skills.sh` added to the §3.1 file-layout tree.
- Lines 141-169: New "Sibling lib added in BD-147" subsection with
  rationale, public-API freeze (the 2 functions), the SIMPLE / SPLIT
  mode contract, env-var inputs, and the Check-26 cross-reference.

The subsection lands inside §3 (framework structure), not as a new
top-level section, so it is consistent with the BD-159 mechanical-edit
principle for in-place architecture updates.

### Concern 9 — Permission bits

**Status:** PASS.

```
-rw-r--r--  scripts/lib/migrator-skills.sh    (sourced lib — non-executable, matches migrator-core.sh)
-rwxr-xr-x  scripts/test-migrator-skills.sh   (test runner — executable)
-rwxr-xr-x  scripts/migrate-v10-to-v11.sh     (unchanged exec bit)
-rw-r--r--  scripts/lib/migrator-core.sh      (unchanged non-exec bit)
```

Per PLAN-SKILL-DIMENSIONS.md §2 Batch 8 step 5 ("`migrator-skills.sh`
is sourced (no exec bit needed)"). `migrator-skills.sh` correctly
parallels `migrator-core.sh`'s 100644.

### Concern 10 — No out-of-scope edits

**Status:** PASS for BD-147 footprint.

`git status --porcelain` (filtered for BD-147 footprint) shows
exactly the 7 files listed in the prompt:

```
 M .github/workflows/validate-pack.yml
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
 M scripts/lib/migrator-core.sh
 M scripts/migrate-v10-to-v11.sh
 M scripts/validate-pack.py
?? scripts/lib/migrator-skills.sh
?? scripts/test-migrator-skills.sh
```

Plus `IMPLEMENTATION-REPORT-BD-147.md` (the implementer's report,
expected). The BD-148 files (MIGRATION-v10-to-v11.md, MERGE-STRATEGY.md,
INSTALL-PROCEDURES.md, PLATFORM-SKILLS.md) are present in the working
tree but mtime-distinct from the BD-147 session per the implementation
report §1.2 — out of scope and not reviewed here.

### Concern 11 — POQ-1 disposition (PLAN-BD-119.md not updated)

**Status:** ACCEPT WITH ONE FIX REQUESTED — see "Recommendation"
below.

The implementer skipped updating PLAN-BD-119.md per the
"temporal-inconsistency hazard" reasoning in
IMPLEMENTATION-REPORT-BD-147.md §5.1. Independent assessment:

**Argument for accepting the deviation as final:**
- PLAN-BD-119.md is the historical record of how BD-119 was
  sequenced into commits. Editing the inventory list to add a lib
  that was added in a downstream batch creates a small
  temporal-inconsistency: a future reader sees "Three new shared
  libraries" at line 39, an inventory of three at lines 67-69, and
  then a fourth lib referenced — without context that the fourth was
  added later. The implementer's reasoning is defensible.
- The architectural source of truth (ARCHITECTURE-BD-119.md §3.1)
  and the operational enforcer (validate-pack Check 26) both DO
  carry the four-lib state, which is what readers need for the lib
  to be discoverable.

**Argument for fixing in this session:**
- PLAN-SKILL-DIMENSIONS.md §7.2 step 7 explicitly directed the
  PLAN-BD-119.md edit; PLAN-SKILL-DIMENSIONS.md §7.2 verification
  list also names a `grep -n "migrator-skills.sh"
  maintenance-docs/v11-implementation/PLAN-BD-119.md → ≥1` check.
  Skipping it leaves a planner directive un-honored.
- The temporal-inconsistency concern can be resolved with a single
  framing sentence ("Updated post-BD-119 by BD-147 — see PLAN-SKILL-DIMENSIONS.md §7.2").
- `grep -n "migrator-skills" maintenance-docs/v11-implementation/PLAN-BD-119.md`
  currently returns 0 hits. The verification asserted in the
  expanded-scope plan is failing.

**Recommendation:** Apply a one-line edit to PLAN-BD-119.md adding
`migrator-skills.sh` to the framework-inventory list (e.g. between
lines 69 and 70 of PLAN-BD-119.md) with a parenthetical note
"`migrator-skills.sh` (added in BD-147 — see ARCHITECTURE-SKILL-DIMENSIONS.md
§6.5)". This is mechanical, satisfies the planner directive verbatim,
and the parenthetical defuses the temporal hazard.

### Concern 12 — Maintainability principle (BD-159)

**Status:** PASS for the file-count envelope; one omission noted.

File count: 5 modified + 2 new = 7 ≤ 10. New lib + new test runner
are infrastructure for new behavior (sibling lib for the BD-119
framework family), not new architecture/planner docs.
ARCHITECTURE-BD-119.md update is in-place to an existing arch doc
(legitimate). This is consistent with BD-159 §3.1's mechanical-edit
condition — see "Sanity check" section below.

**Omission noted (request fix in this batch):** README.md's
Repository Layout section (CLAUDE.md says it is "the authoritative
reference" for layout) lists three BD-119 framework libs at lines
195-197 but NOT `migrator-skills.sh`. It also lists
`scripts/test-migrator-core.sh` and `scripts/test-migrator-manifest.sh`
at lines 209-210 but NOT `scripts/test-migrator-skills.sh`. (The
similarly-omitted `scripts/test-migrator-capability-translation.sh`
appears to be a pre-existing BD-144 oversight, out of BD-147 scope —
flag separately.) Adding the two BD-147 entries is mechanical and
in-scope per BD-159 (file-count goes 7 → 8, still ≤ 10).

---

## 2. Migrator framework compliance check (sibling-lib pattern, no copy-and-rewrite)

PASS. `scripts/lib/migrator-skills.sh` is structurally a sibling, not
a fork:

- **No code duplication from migrator-core.sh.** New lib does not
  redeclare exit-code constants, helpers, parser, or stage runner.
  All cross-references go through the existing core API.
- **Sourced via the framework's single-source pattern.**
  `migrator-core.sh:47-53` adds `migrator-skills.sh` to the same
  `_migrator_core_dir`-resolved source block as the other two
  sibling libs; adapters get the new API via the same `source
  migrator-core.sh` they already do.
- **Internal helpers carry the `_migrator_skills_` prefix**
  (lines 105, 123, 158) so they cannot collide with adapter or core
  internals. Public API uses the `migrator_skill_*` prefix matching
  the framework's `migrator_*` convention.
- **Adapter contract surface unchanged.** `migrate-v10-to-v11.sh`
  did not gain a new `MIGRATOR_*` declaration or hook; it only
  swapped the inline body for the library call. Future adapters that
  do NOT need skill renames pay zero cost — `migrator-skills.sh` is
  loaded but the public functions are not called.
- **macOS bash 3.2 + BSD utils only.** Verified: `printf`, `grep
  -qE`, `sed`, `mktemp -t ... .XXXXXX`, no `&>`, no associative
  arrays, no `${BASH_SOURCE[0]:A}` zsh-isms. Matches the bash 3.2
  constraint stated in `migrator-core.sh:33-39`.

This is the architecture's "sibling lib" pattern executed correctly.

---

## 3. POQ-1 disposition recommendation

**Recommendation: REJECT the implementer's default; apply the
one-line PLAN-BD-119.md edit in this session as a review-fix.**

Rationale:

1. PLAN-SKILL-DIMENSIONS.md §7.2 step 7 explicitly directs the
   edit. The implementer's "temporal-inconsistency hazard" framing
   is defensible but is a stylistic preference, not a structural
   blocker. The planner already considered the inventory edit and
   chose to require it.
2. PLAN-SKILL-DIMENSIONS.md §7.2 verification list specifies `grep
   -n "migrator-skills.sh" maintenance-docs/v11-implementation/PLAN-BD-119.md
   → ≥1`. Skipping the edit puts the batch in a state where one of
   its own verification commands fails. That should not ship.
3. The temporal hazard is real but tractable — adding a parenthetical
   "(added in BD-147)" against the new inventory entry resolves it
   without distorting the BD-119 historical narrative.
4. This is exactly the "land mechanical fixes in the current
   review-fix pass" workflow per CLAUDE.md "One review/fix cycle per
   batch" pack memory.

If Pack Chat / user disagrees and wants to honor the implementer's
default, the deviation should be recorded in BACKLOG.md so a future
pack-architect pass can decide whether PLAN-SKILL-DIMENSIONS.md §7.2
verification list is itself the right rule (it might not be — the
implementer's argument has merit). But the default action for this
review is to fix the deviation, not to litigate the planner directive.

---

## 4. Sanity check against BD-159 §3.1 mechanical-edit conditions

BD-159 (codified in CLAUDE.md `## Pack memory` "Repo conventions")
states that skill / agent maintenance is mechanical by default;
structural change requires architect-then-planner. This BD-147 work
sits in the migrator-framework family, not skills/agents — but the
same principle applies:

- **Mechanical or structural?** Mechanical. The work is "extract an
  existing inline helper into a sibling lib"; the public API was
  pre-frozen by ARCHITECTURE-SKILL-DIMENSIONS.md §6.5 +
  ARCHITECTURE-BD-119.md §3.1 lines 141-169 BEFORE the implementer
  wrote any code. The architect already decided. The planner
  already sequenced.
- **File count envelope.** 7 ≤ 10. With the recommended README +
  PLAN-BD-119.md fix in this session: 9 ≤ 10. Within envelope.
- **No new top-level docs.** Implementation report
  (IMPLEMENTATION-REPORT-BD-147.md) is exempted under the workflow-
  artifacts clause; it sweeps to `maintenance-docs/archive/v11/`
  with the rest of the v11 workflow artifacts at version ship.
- **No client `x-` skill / agent contract break.** N/A — BD-147
  does not touch project-template/.

PASS on the BD-159 sanity check.

---

## 5. Required fixes for this review-fix pass

1. **PLAN-BD-119.md** — Add `migrator-skills.sh` to the
   framework-library inventory (per POQ-1 above and PLAN-SKILL-DIMENSIONS.md
   §7.2 step 7).
2. **README.md** — Repository Layout: add `migrator-skills.sh` to
   the `scripts/lib/` block (around line 198) and add
   `scripts/test-migrator-skills.sh` to the test-runner list (around
   line 211).

Both edits are mechanical, in-place, and bring file count to 9 ≤ 10
(within BD-159 envelope).

---

## 6. Optional v11.x follow-up (NOT for this batch)

- Parameterize `info "BD-035 rename: ..."` user-facing strings in
  `scripts/lib/migrator-skills.sh:348-353` to take an
  operation-name argument so non-BD-035 callers see neutral text.
- Replace the hardcoded `[[ "$old" == "python-architecture" ]]`
  preamble selector at `scripts/lib/migrator-skills.sh:314-317`
  with an explicit caller-supplied advisory-flavor flag, so future
  splits do not have to either reuse the BD-035 preamble or override
  via env var.
- Consider also adding `scripts/test-migrator-capability-translation.sh`
  to the README test list — a pre-existing BD-144 omission noticed
  during this review (separate BD or sweep at v11.0 close).

---

## 7. Summary

The BD-147 implementation correctly extracts the BD-035 S5b skill-rename
helper into a sibling library following the BD-119 framework pattern.
Byte-equivalence is proven by the G1 golden-snapshot test (5/5 PASS).
The new library is properly wired into Check 26, the CI workflow, and
ARCHITECTURE-BD-119.md. All seven adjacent test suites pass green
(186 individual assertions). The two non-blocking layout omissions
(PLAN-BD-119.md, README.md) and the POQ-1 disposition reversal can be
addressed mechanically in the current review-fix pass.

**Verdict:** APPROVE WITH NITS.
