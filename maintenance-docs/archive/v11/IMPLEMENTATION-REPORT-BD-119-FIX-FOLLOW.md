# IMPLEMENTATION-REPORT-BD-119-FIX-FOLLOW

**Agent:** pack-coder (worktree `agent-a510baa936d121c3d`)
**Branch:** `worktree-agent-a510baa936d121c3d`
**Base HEAD:** `17a0cda` (`docs: v11 — pack-reviewer report for BD-115 + BD-119 …`)
**Final HEAD:** `17a0cda` (working-tree changes only — no commits per pack-coder
rules; Pack Chat will commit)
**Scope:** Batch 8a fix-follow — addresses B1 (BLOCKER) + S1..S5 (SHOULD-FIX)
from `maintenance-docs/v11-implementation/PACK-REVIEW-BD-115-BD-119.md`.
N1, N2, N3 (NICE-TO-HAVE) deliberately not addressed (deferred to follow-up
BDs per the prompt).

---

## Pre-flight (verbatim)

```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a510baa936d121c3d
17a0cda3ba98f5ececf54d3c5acde94ff229d323
worktree-agent-a510baa936d121c3d
17a0cda docs: v11 — pack-reviewer report for BD-115 + BD-119 (1 BLOCKER, 5 SHOULD-FIX, 3 NICE-TO-HAVE)
d2cd9b4 docs: v11 — BD-119 C-7: migrator-framework doc refresh
861c158 refactor: v11 — BD-119 C-6: cut migrate-v10-to-v11.sh over to framework adapter
9f9f052 feat: v11 — BD-119 C-5: behavior-preservation harness (mandatory pre-C-6 gate)
3724d72 docs: v11 — reshape BD-114 for public usability + open BD-125 companion doc
0532526 docs: v11 — clarify BD-116 sequencing note + expand BD-121 scope (validate-pack + supporting-docs ripple)
23b0cb0 feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)
e41831f docs: v11 — BD-124 pack-coder skills (implementation-report, verification-harness, commit-discipline) (Open, blocked on BD-119)
9d4efd6 feat: v11 — BD-119 C-4: implement stages + manifest engine + manifest unit tests
5934547 docs: v11 — BD-119 C-5934547: BD-121/122/123 v9 sunset + fixture convention + tracker.toml.example relocation (Open)
maintenance-docs/v11-implementation/PACK-REVIEW-BD-115-BD-119.md
scripts/lib/migrator-core.sh
scripts/lib/migrator-manifest.sh
scripts/lib/migrator-stages.sh
scripts/test-migrator-behavior-preservation.sh
scripts/test-migrator-core.sh
scripts/test-migrator-manifest.sh
```

(Note: the last commit-message entry above is reproduced as I observed it from
`git log --oneline -10`; the literal commit-list line is preserved from the
preflight output.)

---

## Files changed inventory

| Path | Change type | Line delta |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | modified | +12 / −6 |
| `.github/workflows/validate-pack.yml` | modified | +12 / 0 |
| `scripts/test-migrator-behavior-preservation.sh` | modified | +273 / −165 |
| `CHANGELOG.md` | modified (revert) | +2 / −24 |
| `GEMINI.md` | modified (trinity align) | +3 / −3 |
| `scripts/validate-pack.py` | modified (docstring) | +21 / −15 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-FIX-FOLLOW.md` | new | +N (this file) |

No lib files modified — public-API surface remains frozen.

---

## B1 (BLOCKER) — adapter no longer auto-resolves PACK

**Location:** `scripts/migrate-v10-to-v11.sh:247-256`

**Choice:** Hybrid of options (a) and (b) from the review. The adapter
sources the framework via `$SCRIPT_DIR/lib/migrator-core.sh` (not
`$PACK/...`), so the framework is reachable for `--help` and unknown-option
parsing without requiring PACK. The framework's `_stage_preflight` then
fires with `die "PACK environment variable not set" "$EXIT_PACK_INVALID"`
(rc=10) when the user actually attempts a migration without exporting
PACK. The PACK auto-resolve is removed; the header comment is rewritten
to record the architectural intent.

**Why not pure option (a) [keep `$PACK` source path, drop the fallback]?**
That would make `bash migrate-v10-to-v11.sh --help` fail with a `source:
no such file or directory` error (rc!=0), regressing test cases 1.1
("`--help` rc=0") and 1.2 ("`--bogus` typed error") in
`scripts/tests/test-migrate-v10-to-v11.sh`. SCRIPT_DIR-relative sourcing
is sound because the framework lib is co-resident with the adapter in the
same pack repo by construction.

**Why not pure option (b) [explicit guard at top of adapter]?** Same
problem: the guard would refuse `--help` runs that don't export PACK,
regressing 1.1 / 1.2.

**Diff:**

```diff
--- a/scripts/migrate-v10-to-v11.sh
+++ b/scripts/migrate-v10-to-v11.sh
@@ -244,12 +244,18 @@ migrator_post_report_hook() {

 # ── Source the framework + run ─────────────────────────────────────────────

-# `$PACK` is required by every framework helper; resolve to the pack repo
-# this script lives in if the caller did not export it.
-PACK="${PACK:-$(cd "$SCRIPT_DIR/.." && pwd)}"
-export PACK
+# Source the framework via SCRIPT_DIR — the lib lives in the same pack as
+# this adapter, so we do NOT need $PACK to be set just to source it. This
+# preserves `--help` / unknown-option behavior even when PACK is unset, and
+# lets the framework's `_stage_preflight` enforce the documented
+# `EXIT_PACK_INVALID=10` path (architecture §3.2 invariant I1) when the
+# user actually attempts a migration without exporting PACK.
+#
+# Do NOT auto-resolve PACK here. The architecture/PLAN treat unset PACK as
+# a fatal preflight, not a recoverable default; substituting a fallback
+# silently breaks the documented exit-code contract.

 # shellcheck source=lib/migrator-core.sh disable=SC1091
-. "$PACK/scripts/lib/migrator-core.sh"
+. "$SCRIPT_DIR/lib/migrator-core.sh"

 migrator_run "$@"
```

**Verification:**

```
$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -3
Passed: 39
Failed: 0
All tests passed.
```

Case 1.3 (`missing PACK rc=10`) now passes; cases 1.1/1.2 remain green.

---

## S1 (SHOULD-FIX) — wire 3 new test scripts into CI

**Location:** `.github/workflows/validate-pack.yml`

Added four steps under the existing `tests` job (each with `if: always()`
so a failure in one does not mask the others), positioned after the
`migrate-v10-to-v11 tests (BD-085)` step:

- `migrator-core tests (BD-119)` → `bash scripts/test-migrator-core.sh`
- `migrator-manifest tests (BD-119)` → `bash scripts/test-migrator-manifest.sh`
- `build test fixtures (BD-115/116/117)` → `bash test-fixtures/build.sh --all --clean`
- `migrator behavior-preservation tests (BD-119)` → `bash scripts/test-migrator-behavior-preservation.sh`

The build-fixtures step is required because the v10 fixtures are
gitignored; the harness's auto-build fallback handles missing fixtures
locally, but landing an explicit step makes failures isolatable. The
behavior-preservation harness now iterates over BOTH v10 fixtures plus
the 5 negative legs in a single invocation (per S2), so a single CI step
is sufficient.

**Diff:**

```diff
--- a/.github/workflows/validate-pack.yml
+++ b/.github/workflows/validate-pack.yml
@@ -92,6 +92,18 @@ jobs:
       - name: migrate-v10-to-v11 tests (BD-085)
         if: always()
         run: bash scripts/tests/test-migrate-v10-to-v11.sh
+      - name: migrator-core tests (BD-119)
+        if: always()
+        run: bash scripts/test-migrator-core.sh
+      - name: migrator-manifest tests (BD-119)
+        if: always()
+        run: bash scripts/test-migrator-manifest.sh
+      - name: build test fixtures (BD-115/116/117)
+        if: always()
+        run: bash test-fixtures/build.sh --all --clean
+      - name: migrator behavior-preservation tests (BD-119)
+        if: always()
+        run: bash scripts/test-migrator-behavior-preservation.sh
       - name: template-translations tests
```

**Verification:** `bash -n` n/a (YAML); each referenced script verified
in its own section below. Workflow YAML is syntactically valid (verified
by inspection — only additive run-step entries that mirror existing
patterns).

---

## S2 (SHOULD-FIX) — harness expanded to 15 assertions

**Location:** `scripts/test-migrator-behavior-preservation.sh`

The harness was rewritten to:

1. Iterate over BOTH `v10-realistic-ot` and `v10-minimal` fixtures by
   default (5 axes × 2 fixtures = 10 axis assertions). When the user
   passes a fixture name as `$1`, the harness restricts to that fixture
   and SKIPS negative legs (back-compat for one-shot runs).
2. Add 5 negative-leg tests asserting BASELINE / ADAPTER exit-code
   parity for the documented failure paths from PLAN §8.4:
   - N1 — `EXIT_PACK_INVALID` (10): PACK env var unset
   - N2 — `EXIT_NOT_GIT` (11): target is not a git repo
   - N3 — `EXIT_DIRTY` (12): target has uncommitted changes
   - N4 — `EXIT_NOT_BASELINE` (13): target not at v10
   - N5 — `EXIT_BASELINE_MISSING` (14): override `V10_TAG` to a missing
     tag
3. Update the header comment to reflect the new 15-assertion contract.

`_run_impl` now takes per-fixture prefix arguments so artifacts from
multiple runs do not collide in `$RESULTS_DIR`. `_neg_invoke` uses
`env -i HOME PATH` to give the negative-leg invocations a clean
environment (otherwise `PACK` would leak from the harness's exported
copy and N1 would not actually exercise unset-PACK).

**Verification:**

```
$ bash scripts/test-migrator-behavior-preservation.sh 2>&1 | tail -10
  pass: [neg] N1 EXIT_PACK_INVALID (PACK unset) baseline=adapter=10 (expected 10)
  pass: [neg] N2 EXIT_NOT_GIT (target not a git repo) baseline=adapter=11 (expected 11)
  pass: [neg] N3 EXIT_DIRTY (uncommitted changes) baseline=adapter=12 (expected 12)
  pass: [neg] N4 EXIT_NOT_BASELINE (target not at v10) baseline=adapter=13 (expected 13)
  pass: [neg] N5 EXIT_BASELINE_MISSING (v10 tag missing) baseline=adapter=14 (expected 14)

=== Results: 15 passed, 0 failed ===
```

15/15 (10 axis + 5 negative). Single-fixture invocation still works:
`bash scripts/test-migrator-behavior-preservation.sh v10-realistic-ot`
produces 5/5 (preserving prior behavior).

The harness file delta is large (+273 / −165) because the per-fixture
sweep is now refactored into `_sweep_fixture()` for both fixtures to
share. No PLAN §13.3 forbidden soft-fixes were introduced (no
allow-listing, no extra redactions, no continue-on-error, no harness
disable).

(Full file content not embedded inline due to length; see the file at
`scripts/test-migrator-behavior-preservation.sh` in the worktree.)

---

## S3 (SHOULD-FIX) — CHANGELOG.md reverted to d7b3f07 state

**Location:** `CHANGELOG.md:80-110` (pre-revert) — review cited 81-95 +
102-107.

Reverted both hunks added by C-7 (commit `d2cd9b4`):

- The "Scope C — Migrator framework refactor (BD-119)" block.
- The "Migrator-framework regression coverage (BD-119)" bullet under
  "Audit artifacts."
- Restored the prior "Dog-food validation: validate-pack passes all
  25 Checks; CI runs 17 test suites green." line. (Note: validate-pack
  now actually has 26 Checks and CI now runs more than 17 test suites,
  but per PLAN §2.3 + CLAUDE.md, CHANGELOG entries land at v11.0
  release time — the Pack Chat process will refresh these counts then,
  with claims that match landed state at that moment.)

**Verification:**

```
$ git show d7b3f07:CHANGELOG.md > /tmp/cl-d7.md
$ diff /tmp/cl-d7.md CHANGELOG.md
(empty — files match)
```

CHANGELOG.md is byte-identical to its `d7b3f07` state.

**Diff:**

```diff
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -78,36 +78,14 @@ Each version is available as a git tag (v1, v2, …).
 - BD-086 — README.md v11.0 row + Repository Layout updates.
 - BD-087 — This CHANGELOG entry.

-**Scope C — Migrator framework refactor (BD-119)**
-
-- BD-119 — Introduce the N→N+1 migrator framework at
-  `scripts/lib/migrator-{core,stages,manifest}.sh`. The v10→v11 migrator
-  ...
-  `PLAN-BD-119.md`.
-
 **Audit artifacts (release evidence):**

 - Customization-preservation regression coverage:
   `scripts/tests/test-customization-preserve.sh` (72 tests) +
   validate-pack Check 25 (BD-089) — both run on every push.
-- Migrator-framework regression coverage (BD-119):
-  `scripts/test-migrator-core.sh` (public-API unit tests) +
-  ...
-  Check 26 lints adapter manifests.
 - Semantic audit: `maintenance-docs/v11-research/MAINTAINER-CHECK-AUDIT-2026-05-07.md`.
-- Dog-food validation: validate-pack passes all 26 Checks; CI runs
-  the test-suite matrix green.
+- Dog-food validation: validate-pack passes all 25 Checks; CI runs
+  17 test suites green.
```

(Diff abbreviated for readability; the full pre/post hunk is in
`git diff CHANGELOG.md` on the worktree.)

---

## S4 (SHOULD-FIX) — trinity wording byte-identical

**Locations:** `CLAUDE.md:35-40`, `AGENTS.md:29-34`, `GEMINI.md:23-28`

CLAUDE.md and AGENTS.md were already canonical ("`MIGRATOR_*` vars + the
hook functions" and "rewrite — that regresses the framework." on the
same line). GEMINI.md was the outlier; it was updated to match.

**Diff:**

```diff
--- a/GEMINI.md
+++ b/GEMINI.md
@@ -22,10 +22,10 @@ Key docs: `README.md` (version table), `BACKLOG.md` (BD-NNN items),

 **Migrator framework (BD-119).** When authoring a new
 `scripts/migrate-vN-to-vM.sh`, source `scripts/lib/migrator-core.sh` and
-supply the adapter contract (`MIGRATOR_*` vars + hook functions). See
+supply the adapter contract (`MIGRATOR_*` vars + the hook functions). See
 `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for the
-contract. Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite —
-that regresses the framework.
+contract. Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite — that
+regresses the framework.

 ---
```

**Verification:**

```
$ grep -A 5 "Migrator framework (BD-119)" CLAUDE.md > /tmp/c.txt
$ grep -A 5 "Migrator framework (BD-119)" AGENTS.md > /tmp/a.txt
$ grep -A 5 "Migrator framework (BD-119)" GEMINI.md > /tmp/g.txt
$ diff /tmp/c.txt /tmp/a.txt && diff /tmp/c.txt /tmp/g.txt && echo "TRINITY ALIGNED"
TRINITY ALIGNED
```

The "Migrator framework (BD-119)" paragraph is now byte-identical across
all three pack-root trinity files.

---

## S5 (SHOULD-FIX) — Check 26 docstring aligned with implementation

**Location:** `scripts/validate-pack.py:1696-1714`

The docstring previously claimed the libs would "source cleanly enough to
expose the documented public-API names" — but the implementation uses
regex matching against file contents, never sources. The new docstring:

- Lists the precise contract: file presence, `bash -n` syntax validity,
  6 public-API function-name regex matches, 8 exit-code constant regex
  matches, `EXIT_NOT_V10` synonym presence.
- Explicitly states the check uses regex matching, NOT sourcing.
- Preserves the pre-C-2 lenient-mode disposition.

**Diff:**

```diff
--- a/scripts/validate-pack.py
+++ b/scripts/validate-pack.py
@@ -1695,22 +1695,28 @@ def check_help_fragment_tracker_byte_identity() -> None:
 def check_migrator_framework_inventory() -> None:
     """Check 26 — BD-119 migrator-framework inventory.

-    Asserts the three new shared libraries are present, shell-syntax
-    valid, and (when present) source cleanly enough to expose the
-    documented public-API names per ARCHITECTURE-BD-119.md §3.2 and
-    PLAN-BD-119.md §3.
-
-    Lenient mode: if scripts/lib/migrator-core.sh is absent (early
+    Asserts, per ARCHITECTURE-BD-119.md §3.2 and PLAN-BD-119.md §3, that
+    the three new shared libraries (`migrator-core.sh`,
+    `migrator-stages.sh`, `migrator-manifest.sh`) are present and pass
+    `bash -n` syntax validation, and that `migrator-core.sh` contains:
+
+      - regex matches for the 6 public-API function-name declarations
+        (frozen at C-3 of PLAN-BD-119.md): `migrator_run`,
+        `migrator_dispatch`, `migrator_detect_target_version`,
+        `migrator_select_adapter`, `migrator_baseline_to_tmp`,
+        `migrator_target_surface_for_version`;
+      - regex matches for the 8 `readonly`-declared exit-code
+        constants: `EXIT_PACK_INVALID`, `EXIT_NOT_GIT`, `EXIT_DIRTY`,
+        `EXIT_NOT_BASELINE`, `EXIT_BASELINE_MISSING`, `EXIT_LIB_MISSING`,
+        `EXIT_ALREADY_MIGRATED`, `EXIT_INTERNAL`;
+      - the `EXIT_NOT_V10` back-compat synonym (PLAN §3.5).
+
+    The check uses regex matching against the file contents — it does
+    NOT source the file, so it does not detect runtime-only defects.
+
+    Lenient mode: if `scripts/lib/migrator-core.sh` is absent (early
     commits before C-2), the check returns OK with a notice. Once the
-    file lands, the check is strict on syntax + public-API surface.
-
-    Public-API names frozen at C-3 of PLAN-BD-119.md:
-        migrator_run
-        migrator_dispatch
-        migrator_detect_target_version
-        migrator_select_adapter
-        migrator_baseline_to_tmp
-        migrator_target_surface_for_version
+    file lands, the check is strict on syntax + the regex surface above.
     """
```

Implementation logic untouched (no behavior change). Check 26 still
passes.

**Verification:**

```
$ python3 scripts/validate-pack.py 2>&1 | grep -E "Check 26|PASSED" | tail -5
── Check 26: BD-119 migrator-framework inventory ──
PASSED — all checks clean
```

---

## Verification suite (8 commands)

| # | Command | Result |
|---|---|---|
| 1 | `bash -n scripts/migrate-v10-to-v11.sh` | OK (no output) |
| 2 | `bash scripts/test-migrator-behavior-preservation.sh` | `=== Results: 15 passed, 0 failed ===` |
| 3 | `bash scripts/test-migrator-core.sh` | `=== Results: 19 passed, 0 failed ===` |
| 4 | `bash scripts/test-migrator-manifest.sh` | `=== Results: 12 passed, 0 failed ===` |
| 5 | `bash scripts/test-detect.sh` | `=== Results: 40 passed, 0 failed ===` |
| 6 | `bash scripts/tests/test-migrate-v10-to-v11.sh` | `Passed: 39 / Failed: 0` (39/39) |
| 7 | `python3 scripts/validate-pack.py` | `PASSED — all checks clean` (26/26) |
| 8 | `diff <(git show d7b3f07:CHANGELOG.md) CHANGELOG.md` | empty (CHANGELOG matches d7b3f07) |

All 8 verification commands green. Critical regression resolved:
`test-migrate-v10-to-v11.sh: 39/39` (was 38/39 on HEAD before B1 fix).

---

## Plan deviations

None. The five fixes follow the review's recommended dispositions
verbatim. The B1 fix uses a hybrid of options (a)+(b) as documented in
the B1 section above; this is the only spot where the review left two
options open and the reviewer expected the implementer to pick. The
chosen approach keeps `--help` / unknown-option parsing working without
requiring PACK while still letting the framework's preflight emit the
documented `EXIT_PACK_INVALID=10` path when PACK is genuinely unset.

---

## New POQs

None. The fix-follow scope was deliberate; no design questions were
opened.

---

## Definition-of-Done

- [x] B1 fixed — `scripts/migrate-v10-to-v11.sh` no longer auto-resolves
      PACK; framework preflight handles the missing-PACK case;
      `test-migrate-v10-to-v11.sh` is back to 39/39.
- [x] S1 wired — three new test scripts (+ a fixture-build step) added
      to `.github/workflows/validate-pack.yml` under the `tests` job
      with `if: always()`.
- [x] S2 → 15/15 — `test-migrator-behavior-preservation.sh` now
      iterates 2 fixtures × 5 axes (10) + 5 negative-leg exit-code
      parity tests (5) = 15 assertions; all green locally.
- [x] S3 reverted — `CHANGELOG.md` byte-identical to `d7b3f07`.
- [x] S4 trinity byte-identical — CLAUDE.md / AGENTS.md / GEMINI.md
      "Migrator framework (BD-119)" paragraph identical wording +
      identical line-breaks.
- [x] S5 docstring aligned — Check 26 docstring describes regex-based
      checks accurately and explicitly states it does NOT source the
      lib files.
- [x] Full test suite green — verification suite §1..§8 above.
- [x] No source modified outside scope — lib files
      (`migrator-core.sh` / `migrator-stages.sh` / `migrator-manifest.sh`)
      untouched. Public API surface remains frozen.
- [x] Report written — this file.

---

## Proposed commit message

```
fix: v11 — BD-119 fix-follow: B1 BLOCKER + S1..S5 SHOULD-FIX (Batch 8a review)

Addresses pack-reviewer findings in
maintenance-docs/v11-implementation/PACK-REVIEW-BD-115-BD-119.md:

- B1 (BLOCKER): scripts/migrate-v10-to-v11.sh no longer auto-resolves
  PACK. Sources the framework via SCRIPT_DIR (PACK-independent) and
  lets _stage_preflight emit EXIT_PACK_INVALID=10 when PACK is unset.
  Restores test-migrate-v10-to-v11.sh case 1.3 (38/39 → 39/39).
- S1: wires test-migrator-core.sh, test-migrator-manifest.sh, and
  test-migrator-behavior-preservation.sh (+ test-fixtures/build.sh
  --all --clean) into .github/workflows/validate-pack.yml.
- S2: expands test-migrator-behavior-preservation.sh to 15 assertions
  per PLAN §8.4 (2 fixtures × 5 axes + 5 negative-leg exit-code
  parity tests).
- S3: reverts CHANGELOG.md mid-version edits from C-7 (PLAN §2.3
  forbade them); CHANGELOG now byte-identical to d7b3f07.
- S4: aligns trinity wording — GEMINI.md now byte-identical to
  CLAUDE.md / AGENTS.md for the "Migrator framework (BD-119)"
  paragraph (+ "the hook functions"; identical line-break).
- S5: aligns scripts/validate-pack.py Check 26 docstring with the
  regex-based implementation (no longer claims the libs are sourced).

Verification: test-migrate-v10-to-v11.sh 39/39;
test-migrator-behavior-preservation.sh 15/15;
test-migrator-core.sh 19/19; test-migrator-manifest.sh 12/12;
test-detect.sh 40/40; validate-pack.py 26/26.
```

---

## End of report
