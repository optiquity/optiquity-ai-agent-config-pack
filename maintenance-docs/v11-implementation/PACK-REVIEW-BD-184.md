# PACK-REVIEW — BD-184 (Check 42 CI workflow wiring prevention)

**Commit under review:** `1471e0e` — `feat: v11 — BD-184 Check 42 CI
workflow wiring prevention`

**Base:** `0f8d8ee` (BD-184 open commit)
**Branch:** `v11-dev`
**Reviewer scope:** Per-commit review for BD-184 main; final BD coder
commit in the BD-175 emergency batch.

---

## 1. Verdict

**APPROVE.** Zero blocking findings. Zero MUST findings. Zero SHOULD
findings. Two advisory NITs (both pre-acknowledged tradeoffs or
pre-existing out-of-scope conditions).

The commit implements the three artifacts described in the BACKLOG
entry (Check 42 function + `test-validate-pack-check-42.sh` + workflow
sister-step), all three verification gates pass at HEAD
(`validate-pack.py` exit 0 with all 42 checks PASS; test-42 suite 4/4
PASS; all 8 adjacent per-check test suites PASS), and the self-
referential closure holds empirically (9 disk tests / 9 workflow
invocations / 0 unwired).

---

## 2. Severity breakdown

| Severity | Count | Notes |
|----------|-------|-------|
| BLOCKER  | 0     | — |
| MUST     | 0     | — |
| SHOULD   | 0     | — |
| NIT      | 2     | Both advisory; one documented tradeoff, one pre-existing out-of-scope condition |

---

## 3. Per-design-element verification table

| Element | Status | Evidence |
|---------|--------|----------|
| Check 42 function exists with correct signature | PASS | `scripts/validate-pack.py:check_ci_workflow_wires_per_check_tests` (line 5291) — `def check_ci_workflow_wires_per_check_tests() -> None:` matches Check 39/40/41 signature shape |
| Disk glob catches BOTH single + bundled forms | PASS | `tests_dir.glob("test-validate-pack-check*.sh")` (line 5331); empirical `ls scripts/tests/test-validate-pack-check*.sh` returns all 9 files including `test-validate-pack-checks-32-33-34.sh` and `test-validate-pack-checks-36-37-38.sh` |
| Workflow grep catches BOTH single + bundled forms | PASS | Regex `r"bash\s+scripts/tests/(test-validate-pack-check[^\s]+\.sh)"` (line 5349); empirical `grep -E "bash\s+scripts/tests/test-validate-pack-check[^[:space:]]+\.sh" .github/workflows/validate-pack.yml` returns all 9 lines |
| Self-referential closure holds at HEAD | PASS | `test-validate-pack-check-42.sh` present on disk; `bash scripts/tests/test-validate-pack-check-42.sh` present in `.github/workflows/validate-pack.yml:183` — Group 1 of the test suite asserts both explicitly |
| FAIL path exercised in test (synthetic) | PASS | T2 (single-form FAIL), T3 (bundled-form FAIL), T4 (multi-unwired FAIL of 3) at `scripts/tests/test-validate-pack-check-42.sh` lines 268-331; FAIL message names the specific unwired filename(s) per assertion |
| T8/T9 regression guards present | PASS | T8 (line 380-399) stages bundled-only test with zero wiring, expects FAIL on bundled name (proves glob catches bundled form); T9 (line 401-418) stages bundled-form disk+wiring, expects PASS (proves grep catches bundled form) |
| Lenient skip when workflow yml absent | PASS | T7 (line 366-378); also empirically tested via `omit_workflow=True` |
| Lenient skip when scripts/tests/ absent | PASS | T6 (line 352-364); also empirically tested via `omit_tests_dir=True` |
| Reverse-direction asymmetry documented | PASS | T5 (line 333-350) documents the intentional one-directional gate (workflow → disk not gated); docstring at line 5304-5308 explicitly notes the design choice |
| main() invocation position coherent | PASS | Line 5489, after `check_client_installed_files()` (Check 41) — mirrors Check 41's end-of-list landing; comment block at 5482-5488 explains the rationale |
| Module docstring entry for Check 42 | PASS | Line 237-250 — covers glob/grep correctness, self-referential closure, and no-exemption-mechanism design choice |
| Workflow sister-step position | PASS | Line 181-183 — appended after Check 19 step (last per-check test); maintains BD-creation-order chronological convention |
| Workflow sister-step name uses BD-184 + Check 42 framing | PASS | `validate-pack Check 42 tests (BD-184, CI workflow wires all per-check test files)` — matches Check 16/18/19/39/40/41 naming convention |
| validate-pack.py exits 0 with all 42 checks PASS | PASS | Empirical run confirms `PASSED — all checks clean`; Check 42 reports `9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests` |
| test-validate-pack-check-42.sh exits 0 (PASS: 4 / FAIL: 0) | PASS | Empirical run confirms 4/4 PASS across all 4 groups |
| All 8 adjacent per-check test suites still PASS | PASS | Empirical run of all 8: check-16 (10/10), check-18 (7/7), check-19 (9/9), check-39 (6/6), check-40 (8/8), check-41 (4/4), checks-32-33-34 (65/65), checks-36-37-38 (6/6) |
| RC9 manifest unchanged (pack-internal change) | PASS | `bash test-fixtures/build.sh --verify` all 6 fixtures OK; commit does not stage `test-fixtures/manifest.txt` (correct — validate-pack.py + its tests + workflow yml are pack-internal, not copied to clients) |
| YAML syntax valid | PASS | Workflow yml parses cleanly per IMPL-REPORT §6.4 |
| Bash syntax valid | PASS | `bash -n` clean per IMPL-REPORT §6.6 |
| Boundary discipline (zero project-side edits) | PASS | `git show 1471e0e --name-only | grep -E "project-template/|supporting-docs/"` returns no matches — clean pack-internal-only commit |
| Commit subject ≤70 chars | PASS | Subject is 59 chars: `feat: v11 — BD-184 Check 42 CI workflow wiring prevention` |
| Commit message structure (what + why + closes) | PASS | Body cites the 5-occurrence gap-class context, names the three artifacts, includes verification line, references IMPL-REPORT as canonical reference, anticipates end-of-batch reviewer |

---

## 4. Findings

### NIT-1 — Regex matches `bash scripts/tests/<file>.sh` inside YAML comment lines (acknowledged tradeoff)

**Severity:** NIT (advisory; documented design tradeoff)

**File/Symbol:** `scripts/validate-pack.py:check_ci_workflow_wires_per_check_tests`
(regex at line 5348-5350)

**Problem.** The workflow grep `r"bash\s+scripts/tests/(test-validate-pack-check[^\s]+\.sh)"`
matches `bash scripts/tests/<file>.sh` substrings anywhere in the yml,
including inside YAML comment lines (`# - run: bash scripts/tests/test-
validate-pack-check-99.sh`). An actor who comments out a workflow step
rather than removing it would cause Check 42 to treat the test as
"wired" even though it doesn't actually run in CI. Empirical test:

```
'# comment: bash scripts/tests/test-validate-pack-check-99.sh' => ['test-validate-pack-check-99.sh']
```

**Fix.** None recommended; this is an acknowledged tradeoff. The Check
42 docstring (lines 5340-5346) explicitly documents the design choice:

> We deliberately do NOT require the line to be a full `run:` step
> — counting any `bash scripts/tests/<file>.sh` occurrence is sufficient
> because the workflow yml is the only consumer of these test files in
> CI, and a non-`run:` occurrence is implausible enough that surfacing
> it as evidence-of-wiring is a tolerable trade-off vs. a stricter
> parser that would need yml awareness.

**Rationale.** The empirical risk is low because (a) Pack Chat removes
rather than comments out, (b) any commented-out step would also be
visible to CI green-checks and the next reviewer pass, (c) the
alternative (yml-aware parser via `pyyaml`) doubles the code surface of
the check for a failure mode that has never occurred in practice.
Surfacing this NIT for visibility only — no fix needed.

### NIT-2 — Pre-existing module-docstring numbering disorder (41-before-40); BD-184 preserves but does not introduce

**Severity:** NIT (advisory; pre-existing condition, out of BD-184 scope)

**File/Symbol:** `scripts/validate-pack.py` module docstring lines
203-250

**Problem.** The module docstring's numbered list orders checks
41 → 40 → 42 (lines 203, 216, 237). The Check 41 entry was inserted
before the Check 40 entry in a prior BD (BD-180). BD-184 adds Check 42
at the bottom (correct insertion position relative to 42's number), but
preserves the existing 41-before-40 disorder.

**Pre-existing-condition evidence.** `git show 0f8d8ee:scripts/validate-pack.py`
(the pre-BD-184 commit) shows the same 41-before-40 ordering already
present.

**Fix.** None recommended within BD-184 scope. BD-184 itself adds
Check 42 in the correct numeric position relative to the existing
list-tail. Fixing the pre-existing 41-before-40 disorder is out of
scope for BD-184; it could be addressed in a future cosmetic-fix BD or
mentioned to the end-of-batch reviewer for awareness.

**Rationale.** This is a cosmetic readability issue, not a functional
defect. Calling it out here so the end-of-batch reviewer doesn't flag
it as a BD-184 carry-forward — it's a pre-existing condition that
predates this batch entirely.

---

## 5. Verification results

### 5.1 `python3 scripts/validate-pack.py` — exit 0

```
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

All 42 checks PASS. Exit code 0.

### 5.2 `bash scripts/tests/test-validate-pack-check-42.sh` — 4/4 PASS

```
=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

All four test groups PASS:
- Group 0: Module import + Check 42 symbol registration
- Group 1: Real-state-at-HEAD PASS + self-referential closure
- Group 2: Synthetic T1-T9 (PASS/FAIL/SKIP/regression guards)
- Group 3: End-to-end validate-pack.py exit-status on HEAD

### 5.3 Adjacent per-check test suites — all 8 PASS, zero regressions

| Test file | Result |
|-----------|--------|
| `test-validate-pack-check-16.sh` | PASS (10/10) |
| `test-validate-pack-check-18.sh` | PASS (7/7) |
| `test-validate-pack-check-19.sh` | PASS (9/9) |
| `test-validate-pack-check-39.sh` | PASS (6/6) |
| `test-validate-pack-check-40.sh` | PASS (8/8) |
| `test-validate-pack-check-41.sh` | PASS (4/4) |
| `test-validate-pack-checks-32-33-34.sh` | PASS (65/65) |
| `test-validate-pack-checks-36-37-38.sh` | PASS (6/6) |

### 5.4 Manifest verify — clean

`bash test-fixtures/build.sh --verify` reports all 6 fixtures OK with
no SHA drift. Commit does not stage `test-fixtures/manifest.txt`
(correct — the three modified files are pack-internal and not copied to
clients by `init-project.sh`).

### 5.5 Self-referential closure — empirically confirmed

- Disk: `ls scripts/tests/test-validate-pack-check*.sh` returns 9 files
  including `test-validate-pack-check-42.sh`.
- Workflow: `grep "bash scripts/tests/test-validate-pack-check[^[:space:]]+\.sh"`
  in `.github/workflows/validate-pack.yml` returns 9 invocations
  including `bash scripts/tests/test-validate-pack-check-42.sh` on
  line 183.
- Check 42 result: `9 per-check test file(s) on disk; 9 workflow
  invocation(s) found; zero unwired tests`.

### 5.6 Boundary discipline — clean

`git show 1471e0e --name-only` shows four files changed:
- `.github/workflows/validate-pack.yml` (pack-internal CI)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-184.md`
  (pack-internal docs)
- `scripts/tests/test-validate-pack-check-42.sh` (pack-internal test)
- `scripts/validate-pack.py` (pack-internal validator)

Zero `project-template/`, zero `supporting-docs/` edits. P-missed-7
boundary discipline N/A — no project-side surface touched.

### 5.7 Commit hygiene — clean

- Subject (59 chars): `feat: v11 — BD-184 Check 42 CI workflow wiring
  prevention` — under 70-char limit, follows `feat: vN — BD-NNN short
  description` format
- Body: cites gap-class context (5 occurrences, 3 fix cycles), names
  the three artifacts, verification line, IMPL-REPORT cross-reference,
  end-of-batch anticipation
- No scope-claiming keyword (mixed-scope implicit per Check 36
  convention — correct since the commit touches scripts/, .github/, and
  maintenance-docs/ across pack-internal-only surface)

---

## 6. Carry-forward observations

**Carry-forward discipline applied per `.claude/skills/review/SKILL.md`
§ "Carry-forward discipline".**

### 6.1 Decisions on observed items

| Observation | Test passed? | Disposition |
|-------------|--------------|-------------|
| NIT-1 (regex comment-line false-positive) | NONE of SIZE/BLOCKED/LOGICAL-FIT | Surface as in-scope advisory NIT; default no-fix per acknowledged tradeoff documented in docstring; Pack Chat triage decides |
| NIT-2 (pre-existing 41-before-40 disorder) | NONE of SIZE/BLOCKED/LOGICAL-FIT | Surface as in-scope advisory NIT; out of BD-184 scope per evidence (pre-existed at `0f8d8ee`); Pack Chat triage decides whether to fold a separate cosmetic-fix BD |

### 6.2 Items explicitly NOT carried forward

- **"Test infrastructure cleanup" (e.g., extracting shared bash
  boilerplate across all 9 per-check test files).** Considered
  carry-forward to a future BD-185+ test-infra-refactor work; rejected
  because (a) the IMPL-REPORT §8 already documents this as out-of-
  BD-184-scope per pack-memory `feedback_no_deferral_without_user_direction`,
  (b) the SIZE/BLOCKED/LOGICAL-FIT tests are not met for this batch,
  (c) the per-test local `run_check` helper pattern (mirrors Check 41)
  is acceptable today and not a defect.

- **"yml-aware parser to eliminate comment-line false-positive
  (NIT-1)."** Not carried forward because the IMPL-REPORT documents
  this as a deliberate design choice, the failure mode has never
  occurred in practice, and a stricter parser doubles code surface for
  zero observed benefit.

- **"Pre-existing 41-before-40 docstring disorder."** Not carried
  forward as architect-pass work because it's cosmetic-only and
  Pack-Chat-direct (PM-only `validate-pack.py`-docstring edit is
  trivial). If addressed, it belongs as a small fix-now alongside any
  future Check-NN BD that touches the docstring, not as a standalone
  BD.

### 6.3 End-of-batch reviewer hand-off note

The end-of-batch reviewer on the full BD-175 → BD-184 diff should be
aware that:

1. BD-184 introduces Check 42 cleanly and the self-referential closure
   holds at HEAD — no need to re-verify the BD-184 surface in detail.
2. The two NITs above are documented advisory items; both predate
   BD-184 in spirit (NIT-1 is a documented tradeoff; NIT-2 is a
   pre-existing condition). Neither blocks the batch.
3. The batch chain BD-175 → BD-184 is now structurally complete; the
   end-of-batch reviewer's mandate is cross-BD coherence (was the
   batch's narrative consistent? do the BDs collectively close the
   intended scope?), not per-commit re-review.

This concludes the per-commit review for the final BD coder commit in
the BD-175 emergency batch.

---

**Reviewer:** pack-reviewer (12th reviewer bound by carry-forward
discipline in this batch)
**Date:** 2026-05-21
**Branch HEAD verified:** `1471e0e`
**Output file:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-184.md`
