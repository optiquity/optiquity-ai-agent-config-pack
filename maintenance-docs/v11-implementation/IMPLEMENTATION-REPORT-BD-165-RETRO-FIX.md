# IMPLEMENTATION-REPORT-BD-165-RETRO-FIX — retroactive fix pass against PACK-REVIEW-BD-165-RETRO findings

**Branch:** `v11-dev`
**Pre-flight HEAD SHA:** `8fac7d0e92649c5261fe3759ce520d8b82c8c619`
**Final HEAD SHA (working-tree edits only; agent did not commit):** `8fac7d0e92649c5261fe3759ce520d8b82c8c619`
**Review input:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-165-RETRO.md`
**BD touched:** BD-165 (retro fix; no status change in this pass)

---

## §1 — Summary

This retro fix pass applies Pack Chat's triage decisions against the
PACK-REVIEW-BD-165-RETRO report: 5 fixes applied (M1, S1, S2, S3a,
S3b, N1) and 1 skip (N2, reviewer-self-withdrawn). M1 corrects the
inverted post-report advisory wording in
`scripts/migrate-v10-to-v11.sh`; S1 corrects the stale public-API
docstring header in `scripts/lib/per-entry/mirror-generate.sh`; S2
adds the BD-165-introduced `decompose.sh` entry to the README
Repository Layout; S3a creates a new CI test runner
`scripts/tests/test-migrate-v10-to-v11-decompose.sh` covering BD-165's
net-new functional surface (45 PASS / 0 FAIL across 5 groups); S3b
wires the new runner into `.github/workflows/validate-pack.yml`
between the BD-101 gates step and the BD-119 framework-test step; N1
recasts the IMPL-REPORT-BD-165 line-count claim in drift-resilient
phrasing and updates the §3.4 C quoted text to reflect M1's
corrected wording. All required verification commands PASS: bash -n
clean on 3 shell files; python3 YAML safe_load clean; validate-pack.py
clean; the new runner 45/45 PASS; all 8 baseline test suites
zero-regression (57/57 + 43/43 + 61/61 + 87/87 + 34/34 + 52/52 + 46/46
+ 19/19). HEAD unchanged. Pack Chat owns the commit.

---

## §2 — Files modified / created

| Path (absolute) | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` | 923 | 925 | +2 | MODIFIED (M1) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` | 332 | 337 | +5 | MODIFIED (S1) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md` | 431 | 432 | +1 | MODIFIED (S2; +1 line in Repository Layout block) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 0 | 458 | +458 | NEW (S3a) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml` | 242 | 245 | +3 | MODIFIED (S3b; one new tests-job step) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md` | 642 | 660 | +18 | MODIFIED (N1; §1 summary + §3.4 C + §5 DoD table cell) |

Inventory:
- **NEW:** 1 file (the test runner; executable bit set).
- **MODIFIED:** 5 files (in scope per the prompt).
- **DELETED:** 0 files.

---

## §3 — Per-fix detail

### §3.1 — M1: post-report advisory paragraph

**File:** `scripts/migrate-v10-to-v11.sh` (lines 699-702 after edit).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 M1 — "post-report advisory paragraph misrepresents the actual safety contract".

**Before (2 lines):**
```bash
say "Hand-edits to the mirrors are silently overwritten on the next"
say "regeneration unless --force-overwrite-mirror is acknowledged."
```

**After (4 lines):**
```bash
say "Hand-edits to the mirrors that diverge from the per-entry tree will BLOCK"
say "the next regeneration with exit code 31 (EXIT_GATE_FAILED). Re-run with"
say "--force-overwrite-mirror to acknowledge and overwrite the hand-edits, or"
say "reconcile the per-entry tree with the mirror by hand first."
```

The new wording matches Addendum #2 §4.2's BLOCK-by-default contract:
the migrator NEVER silently overwrites; `--force-overwrite-mirror` is
the explicit-acknowledgement signal that ADMITS the overwrite, not
the inverse. Net: advisory paragraph grows from 2 to 4 say-lines for
this segment; the section's overall paragraph length shifts upward by
2 lines.

### §3.2 — S1: mirror-generate.sh public-API header docstring

**File:** `scripts/lib/per-entry/mirror-generate.sh` (lines 22-29 after edit).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 S1 — "public-API header docstring is stale (pre-BD-165)".

**Before (3 lines, single non-interactive bullet):**
```
#           - Non-interactive: emit divergence warning to stderr and
#             return non-zero exit (BD-095-mode wiring in 19c
#             interprets the exit code per Addendum #2 §4).
```

**After (8 lines, 3 bullets matching the implementation):**
```
#           - Non-interactive with _MIGRATOR_MODE=dry-run: report divergence
#             to stdout (informational); return 0.
#           - Non-interactive with _MIGRATOR_MODE=apply|resume: BLOCK with
#             EXIT_GATE_FAILED=31 + recovery instruction naming
#             --force-overwrite-mirror (Addendum #2 §4 BD-095 bridge).
#           - Non-interactive with _MIGRATOR_MODE unset (direct callers
#             outside the migrator): preserve pre-BD-165 stderr warning +
#             rc=2 behavior for backward compatibility.
```

Now matches the case-block implementation at lines 292-330 of the
same file. Net: docstring grows by 5 lines.

### §3.3 — S2: README Repository Layout entry for decompose.sh

**File:** `README.md` (lines 206-210 after edit).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 S2 — "README Repository Layout omits the new adapter-private helper".

**Before:**
```
    └── migrate-v10-to-v11/                 v10→v11 adapter-private libs (v11; BD-095 + BD-101)
        ├── dry-run.sh, apply.sh, resume.sh    Two-phase mode dispatchers (BD-095)
        ├── checkpoint.sh                       BD-101 verification helpers
        └── gate-{1,2,3}-*.sh                   Pre/post Phase-A/Phase-B gates (BD-101)
```

**After:**
```
    └── migrate-v10-to-v11/                 v10→v11 adapter-private libs (v11; BD-095 + BD-101 + BD-165)
        ├── dry-run.sh, apply.sh, resume.sh    Two-phase mode dispatchers (BD-095)
        ├── checkpoint.sh                       BD-101 verification helpers
        ├── decompose.sh                        BD-165 — 6th post-dispatch sub-op + --force-overwrite-mirror bridge
        └── gate-{1,2,3}-*.sh                   Pre/post Phase-A/Phase-B gates (BD-101)
```

Ordering placed `decompose.sh` between `checkpoint.sh` and the
`gate-*.sh` block. The header annotation expands `(v11; BD-095 +
BD-101)` to `(v11; BD-095 + BD-101 + BD-165)` to record the BD
provenance addition. Net: +1 line.

### §3.4 — S3a: new CI test runner `scripts/tests/test-migrate-v10-to-v11-decompose.sh`

**File:** `scripts/tests/test-migrate-v10-to-v11-decompose.sh` (NEW; 458 lines; chmod +x).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 S3 — "No wired CI test covers BD-165's net-new functional surface".

**Test groups + cases (45 total assertions, all PASS):**

| Group | Cases | Coverage |
|---|---|---|
| Group 1 — 6th sub-op presence + sequencing | 6 assertions (1.0, 1.1, 1.2a-d) | Dry-run banner names BD-165 step; advisory paragraph has corrected M1 wording (`will BLOCK`, `EXIT_GATE_FAILED`, `force-overwrite-mirror`); pre-M1 inverted "silently overwritten" wording absent |
| Group 2 — --apply happy path | 15 assertions (2.0a, 2.0b, 2.1a-f, 2.2a-c, 2.3a-d, 2.4, 2.5) | --apply with --force-overwrite-mirror produces per-entry trees (3 backlog + 2 implementation-plan + 1 changelog entries); regenerated mirrors present; advisory paragraph emitted with M1 wording; Gate 2 PASS; HEAD unchanged (migrator never commits) |
| Group 3 — mode-aware divergence routing | 13 assertions (3.1 rc/stdout/disk, 3.2 rc/stderr/disk + 3.2x, 3.3 rc/stderr/disk, 3.4 rc/stderr/disk) | per_entry_regenerate_mirror invoked directly with _MIGRATOR_MODE values: dry-run rc=0 + stdout-report + mirror UNCHANGED; apply rc=31 + stderr ERROR/force-overwrite-mirror + mirror UNCHANGED; resume rc=31 (block path identical) + mirror UNCHANGED; apply+PE_FORCE_OVERWRITE_MIRROR=1 rc=0 + audit-trail warning + mirror OVERWRITTEN |
| Group 4 — dispatcher --force-overwrite-mirror intercept on resume | 6 assertions (4.0, 4.1a-c, 4.2a-b) | --resume WITHOUT --force-overwrite-mirror against pre-seeded divergence: rc=25 (fail_stage S5 = 20+5; the inner regenerator returns 31 but fail_stage wraps it to 25) + mirror UNCHANGED; --resume WITH --force-overwrite-mirror: rc=0 + mirror OVERWRITTEN + audit-trail warning emitted |
| Group 5 — backward compatibility (fall-through path) | 3 assertions (5.1a-c) | per_entry_regenerate_mirror invoked WITHOUT _MIGRATOR_MODE preserves pre-BD-165 contract: rc=2 + stderr warning naming force-overwrite-mirror + mirror UNCHANGED |

**Fixture strategy.** The in-tree `test-fixtures/v10-realistic-ot/`
has no `docs/project/*.md` files (per IMPL-REPORT-BD-165 §7.2), so
the runner synthesizes its own minimal v10-shape fixture under
`/tmp` via the `make_v10_target_with_project_docs` helper. The
fixture seeds:
- Trinity files (CLAUDE/AGENTS/GEMINI) sourced from the v10 tag
  (matches the BD-095/BD-101 test-runner pattern).
- `docs/project/BACKLOG.md` with 3 TD-NNN entries (TD-001 Open,
  TD-002 Open, TD-003 Resolved).
- `docs/project/IMPLEMENTATION-PLAN.md` with 2 `## Phase N — Title`
  H2-anchored entries (matches the decompose parser's
  `^## Phase (\d+) — ` regex at `decompose.sh:133-134`).
- `docs/project/CHANGELOG.md` with 2 `### YYYY-MM-DD — Phase N <slug>`
  H3-anchored entries (matches the decompose parser at
  `decompose.sh:139`).
- git init + initial commit so EXIT_DIRTY=12 preflight passes.

**Exit-code discovery.** Group 4 assertion 4.2a expects rc=25 (not
rc=31) for `--resume` blocked at the BD-165 sub-op. The mirror
generator returns EXIT_GATE_FAILED=31 from its apply|resume block
path, but the BD-165 decompose helper wraps that failure in
`fail_stage S5` (per `scripts/lib/migrate-v10-to-v11/decompose.sh:197`),
which exits with the framework's stage-failure formula (20 + stage
number = 25 for S5). The 4.2a test code-comment documents this.

**Bash 3.2 + macOS BSD compat.** Verified: no associative arrays, no
`&>`, no `readarray`/`mapfile`, no GNU-only flags. Uses subshells +
explicit env-var unset for isolation (no bash 4 namespace features).
`bash -n` clean.

### §3.5 — S3b: CI workflow wiring

**File:** `.github/workflows/validate-pack.yml` (lines 196-198 after edit).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 S3 (same finding as S3a).

**Inserted step (between the BD-101 gates step and the BD-119
framework-test step, matching the per-name list convention of the
tests job):**

```yaml
      - name: migrate-v10-to-v11 decompose tests (BD-165)
        if: always()
        run: bash scripts/tests/test-migrate-v10-to-v11-decompose.sh
```

YAML well-formedness verified via `python3 -c "import yaml;
yaml.safe_load(open('.github/workflows/validate-pack.yml'))"` —
clean.

### §3.6 — N1: IMPL-REPORT-BD-165 line-count claim clarification

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md`
(§1 summary + §3.4 C + §5 Definition-of-Done table cell).
**Review finding:** PACK-REVIEW-BD-165-RETRO.md §2 N1 — "IMPL-REPORT post-report advisory line-count claim is imprecise".

**Three edits applied (per the review's recommended Option (b) —
drift-resilient phrasing):**

1. §1 summary — "Added 16 say-lines (~12 displayed paragraph lines)"
   → "a short advisory paragraph (approximately 12 displayed lines)
   naming the rollback path and the divergence-block recovery
   instruction".
2. §3.4 C — quoted the corrected M1 wording verbatim AND added a
   prose paragraph explaining the retroactive correction context
   (per-Addendum-#2-§4 contract).
3. §5 Definition-of-Done — table cell for the "Post-report advisory
   paragraph length ~12 lines" row updated to drift-resilient
   phrasing ("approximately 12 displayed lines after rendering") and
   notes the post-retro-fix M1 wording compliance.

Net: +18 lines in the IMPL-REPORT to record the retroactive
correction trail.

---

## §4 — Verification

### §4.1 — Syntax checks (required per success criterion C)

```
$ bash -n scripts/migrate-v10-to-v11.sh && echo "OK"
OK

$ bash -n scripts/lib/per-entry/mirror-generate.sh && echo "OK"
OK

$ bash -n scripts/tests/test-migrate-v10-to-v11-decompose.sh && echo "OK"
OK

$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))" && echo "YAML OK"
YAML OK
```

### §4.2 — Pack validation

```
$ python3 scripts/validate-pack.py
  ...
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### §4.3 — New test runner (S3a)

```
$ bash scripts/tests/test-migrate-v10-to-v11-decompose.sh
...
=== Summary ===
Passed: 45
Failed: 0
All BD-165 decompose tests passed.
```

### §4.4 — Baseline test suites (zero-regression check)

```
$ bash scripts/tests/test-per-entry.sh
All per-entry tests PASSED (57/57).

$ bash scripts/tests/test-migrate-v10-to-v11.sh
Passed: 43
Failed: 0
All tests passed.

$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
Passed: 61
Failed: 0
All BD-095 tests passed.

$ bash scripts/tests/test-migrate-v10-to-v11-gates.sh
Passed: 87
Failed: 0
All BD-101 gate tests passed.

$ bash scripts/tests/test-init-project.sh
Passed: 34
Failed: 0
All tests passed.

$ bash scripts/tests/tracker-agent-read-test.sh
Passed: 52
Failed: 0
All tests passed.

$ bash scripts/tests/test-validate-pack-checks-32-33-34.sh
All BD-168 validate-pack Check 32/33/34 tests PASSED (46/46).

$ bash scripts/test-migrator-core.sh
=== Results: 19 passed, 0 failed ===
```

### §4.5 — HEAD unchanged check

```
$ git rev-parse HEAD
8fac7d0e92649c5261fe3759ce520d8b82c8c619
```

Same as the pre-flight HEAD captured at session start (§ header).

---

## §5 — Definition-of-Done checklist

| Criterion | Status | Evidence |
|---|---|---|
| A. All 5 FIX items applied per guidance (M1, S1, S2, S3a, S3b, N1) | **PASS** | §3.1 (M1), §3.2 (S1), §3.3 (S2), §3.4 (S3a), §3.5 (S3b), §3.6 (N1) |
| B. No SKIP item applied; skip-rationale documented in §7 | **PASS** | §7 below — N2 + 5 observations |
| C.1 `bash -n scripts/migrate-v10-to-v11.sh` clean (M1) | **PASS** | §4.1 |
| C.2 `bash -n scripts/lib/per-entry/mirror-generate.sh` clean (S1) | **PASS** | §4.1 |
| C.3 `bash -n scripts/tests/test-migrate-v10-to-v11-decompose.sh` clean (S3a) | **PASS** | §4.1 |
| C.4 `python3 -c "import yaml; yaml.safe_load(...)"` clean (S3b YAML) | **PASS** | §4.1 |
| C.5 `python3 scripts/validate-pack.py` PASSED | **PASS** | §4.2 |
| C.6 New runner PASS (target 12-15 assertions) | **PASS** | §4.3 — 45/45 (exceeded target, covers all 5 review-specified scenarios) |
| C.7 `bash scripts/tests/test-per-entry.sh` 57/57 PASS | **PASS** | §4.4 |
| C.8 `bash scripts/tests/test-migrate-v10-to-v11.sh` 43/43 PASS | **PASS** | §4.4 |
| C.9 `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` 61/61 PASS | **PASS** | §4.4 |
| C.10 `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` 87/87 PASS | **PASS** | §4.4 |
| C.11 `bash scripts/tests/test-init-project.sh` 34/34 PASS | **PASS** | §4.4 |
| C.12 `bash scripts/tests/tracker-agent-read-test.sh` 52/52 PASS (post-BD-167-retro baseline) | **PASS** | §4.4 |
| C.13 `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` 46/46 PASS | **PASS** | §4.4 |
| C.14 `bash scripts/test-migrator-core.sh` 19/19 PASS | **PASS** | §4.4 |
| D. Bash 3.2 + macOS BSD compatible (new test runner) | **PASS** | No associative arrays, no `&>`, no readarray/mapfile, no GNU-only flags; bash -n clean on darwin25 (bash 3.2.57) |
| E. HEAD unchanged when finished | **PASS** | §4.5 |

---

## §6 — Plan deviations

**Zero plan deviations.** All 5 fixes applied per the Pack Chat
triage decisions as specified in the prompt. Two minor implementation
decisions were made within the prompt's discretion:

1. **S3a Group 4 exit-code expectation.** The prompt's S3a Group 4
   spec said "assert rc=31" for the resume-block path; the actual
   rc is 25 (the BD-165 decompose helper wraps the inner
   EXIT_GATE_FAILED=31 in `fail_stage S5` which exits 25). The test
   asserts rc=25 with an inline comment documenting why. This is
   not a deviation from the success criterion (the test still
   regression-guards the dispatcher intercept's behavior); it's a
   correction of the prompt's assumed rc value to match the actual
   architecture (decompose helper wraps the regenerator's rc=31 in
   the fail_stage formula).
2. **S3a fixture changelog filename.** The prompt's Group 2
   assertion 2.1f expected one of "2026-04-15.md" or
   "2026-04-15-phase-1-milestone.md". The actual decomposed
   filename is `2026-04-15-phase-1-milestone.md` (the changelog
   decompose parser slugifies the entire phrase after the date —
   it does NOT match the `(?: — Phase (\d+))?` group because the
   phrase "Phase 1 milestone" has no terminator between "1" and
   "milestone"; the slug-form fallback fires instead). The test
   uses the actual filename. Pack-Chat-spec intent preserved
   (regression-guards the changelog decompose path).

Neither item introduces a new POQ — both are runtime-discovered
facts about pre-existing helper behavior that the test correctly
adapts to.

---

## §7 — Skip rationale (SKIP list — 1 finding + 5 observations)

### §7.1 — N2 (line-reference verification) — SKIP (reviewer self-withdrew)

PACK-REVIEW-BD-165-RETRO.md §2 N2 was self-withdrawn during the
reviewer's own verification ("Verified that the IMPL-REPORT line
reference is accurate. ... Resolution: WITHDRAW."). No action
required. The N2 entry remains in the review report as a documented
verification trail; no IMPL-REPORT correction needed.

### §7.2 — §4.1 (README BD-095/BD-101 test-case counts stale) — SKIP

PACK-REVIEW-BD-165-RETRO.md §4.1 noted stale test-case counts in
README.md for BD-095 (40 → actual 61) and BD-101 (39 → actual 87).
This drift PREDATES BD-165 (the test files weren't modified by
BD-165). Pack Chat triage logical-fit-defense: the same README
test-case-count surface that the upcoming Batch 19b cleanup batch
will sweep through; this fix-coder pass routes the observation
to that batch's natural scope rather than expanding scope here.
Per `feedback_deferral_is_scope_creep` the route is explicit (not
"defer to later phase").

### §7.3 — §4.2 (_passthru redundancy pattern) — SKIP (intentional + documented)

PACK-REVIEW-BD-165-RETRO.md §4.2 noted the `_passthru` + dispatcher
intercept creates a 3-way set/reset pattern for
`_MIGRATOR_FORCE_OVERWRITE_MIRROR`. This is intentional per
IMPL-REPORT-BD-165 §7.1 (the resume path never invokes
`_migrator_parse_args` so the dispatcher intercept is the only seam
that wires the flag into resume mode; the redundancy with the
parser-level case is intentional — idempotent re-set). Not a
defect; no action.

### §7.4 — §4.3 (project-side-only decomp) — SKIP (confirms architect binding)

PACK-REVIEW-BD-165-RETRO.md §4.3 confirms the `_v10_to_v11_decompose_streams`
helper's project-side-only scope matches integration parent §10.5
(pack-side decomp lands in Batch 22 BD-102 dog-food). This is an
architect-binding confirmation, not a finding. No action.

### §7.5 — §4.4 (first-migration divergence) — COVERED BY M1 FIX

PACK-REVIEW-BD-165-RETRO.md §4.4 noted that first-migration users
with pre-existing `docs/project/*.md` content will see divergence on
first regenerate and need `--force-overwrite-mirror`. The M1 fix
applied in §3.1 above directly addresses this: the corrected wording
now accurately describes the BLOCK contract, including the
`--force-overwrite-mirror` recovery flag. No separate action.
(The §4.4 observation noted "if M1 is fixed, the same fix opportunity
covers adding one sentence about this case" — M1's corrected wording
covers the general contract; first-migration users will see the
BLOCK behavior with a clear recovery instruction, matching the
architectural intent.)

### §7.6 — §4.5 (BD-165 BACKLOG status Open) — SKIP (correct pre-flip state)

PACK-REVIEW-BD-165-RETRO.md §4.5 noted that BACKLOG.md BD-165 entry
is still `Status: Open` — this is the correct pre-retro-review state.
The status flip to `Resolved` happens at commit 19h per
PLAN-PER-ENTRY-SPLIT-BATCH-19.md §0 as the implicit-batch-completion
flip (per `feedback_implicit_status_flip`). Not a finding; not in
scope for a coder pass (BACKLOG is PM-only).

---

## §8 — Out-of-scope observations

None beyond the FIX/SKIP list above. Per
`feedback_deferral_is_scope_creep` and the prompt's explicit "no
deferral language" rule, this section is intentionally empty for this
retro-fix pass — all surfaced observations from the review report
have been triaged into either FIX (applied in §3) or SKIP (rationale
in §7).

One non-deferral-framed observation for visibility (no action
recommended):

- **Test runner total-assertion count** ended at 45 (target was
  12-15 per the prompt's S3a sizing guidance). The expansion came
  from the 5-group scenario coverage — each scenario decomposes into
  multiple atomic assertions (rc + stream + on-disk + audit-trail).
  The runner stays within the existing test-runner line budget
  (~458 lines vs the existing siblings' 400-700 range). All 45
  PASS; no flakiness observed across multiple runs. No action.
