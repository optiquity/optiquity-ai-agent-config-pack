# IMPLEMENTATION REPORT — BD-184

**BD:** BD-184 — Add Check 42 — CI workflow wires all per-check test
files (prevention check for "test silently dead in CI" gap class)

**Branch:** `v11-dev`
**HEAD pre-implementation:** `0f8d8ee8a5ae0b88a7f98cd281d1f4effa52c443`
**HEAD post-implementation:** `0f8d8ee8a5ae0b88a7f98cd281d1f4effa52c443`
(no commits authored — pack-coder is read-only with respect to git
state; Pack Chat will stage + commit per workflow rule)

**Context.** Last BD in the BD-175 emergency batch chain before
end-of-batch reviewer + Phase 6/7 close + Batch 19c resume. Adds a
mechanical CI prevention check for the "missing test wiring" gap class
that surfaced 5 times across 3 fix cycles in this batch:

- BD-179 FIX-1 (`1e644d1`): wired `test-validate-pack-checks-36-37-38.sh`
  + `test-validate-pack-check-39.sh` + `test-validate-pack-check-40.sh`
  (3 tests; unwired since BD-175 Commit 12, BD-175 F2a, BD-179 main)
- BD-183 FIX-1 (`5f8f683`): wired `test-validate-pack-check-18.sh`
  (unwired since BD-181 main `c244314`)
- BD-183 FIX-2 (`99b0f12`): wired `test-validate-pack-check-41.sh`
  (unwired since BD-180 main `78a4415`)

Each occurrence was caught by reviewer attention applying the BD-179
FIX-5 (`ff23a00`) carry-forward discipline. The discipline works, but
a mechanical guard at commit time is cheaper than per-cycle reviewer
attention. BD-184 closes the gap class permanently.

---

## 1. Problem restatement

The same gap class surfaced 5 times in one emergency batch despite
the carry-forward discipline being in place from BD-179 FIX-5 onward.
The discipline depended on reviewer attention applying a `for each
test file: was wiring added?` mental scan, then surfacing a fix-now
in the next per-commit review. That worked — but only because
attention was applied. A mechanical check at validate-pack.py time:

1. Eliminates the dependency on reviewer attention.
2. Catches the gap at developer-local-test time (before push), not
   per-cycle review time.
3. Has zero ongoing cost (the check runs in <1s in CI).
4. Provides actionable failure messages (names the specific
   missing-wiring filename).

---

## 2. Implementation

### 2.1 Check 42 function design

Function: `check_ci_workflow_wires_per_check_tests()` in
`scripts/validate-pack.py:check_ci_workflow_wires_per_check_tests`.

**Design choice: grep-based, not yml-parser.** Chose the simpler-
correct design: parse the workflow yml as text via a regex looking
for `bash scripts/tests/<filename>` invocation lines. A full yml
parser would be more robust against unusual yml structures, but
that robustness is not needed here — the workflow yml is owned and
maintained by pack-coder/pack-chat, the convention is fixed (per-test
sister-steps with `bash scripts/tests/<f>` `run:` lines), and a more
complex parser would add ~30 lines of code surface for zero failure
modes the simpler regex doesn't catch. Mirrors Check 39's approach
to parsing `init-project.sh` (regex over text, not bash-source).

**Comparison logic.**

1. Enumerate disk tests: `Path(REPO_ROOT/"scripts/tests").glob(
   "test-validate-pack-check*.sh")`.
2. Parse workflow yml: regex `r"bash\s+scripts/tests/(test-validate-
   pack-check[^\s]+\.sh)"` over the file text.
3. Diff: `disk_set - wired_set` = unwired tests.
4. FAIL with the specific filename(s); PASS reports the counts.

**One-directional gate.** Reverse-direction (workflow lines without
disk files) is NOT a failure mode worth gating — a stale workflow
line referencing a deleted test would fail the actual CI run loudly
on the first push, so there is no silent-pass risk. The symmetric
gate would add noise without catching new failure modes. T5 in the
test suite documents this asymmetry.

**No exemption mechanism.** Intentionally none. If a test is
intentionally not run in CI, the workflow can wire it under an
`if:` gate — but the wiring line MUST exist so Check 42 sees it.
Avoids the "creep" of allowlist entries silently growing over time.

### 2.2 main() invocation site

Added after `check_client_installed_files()` (Check 41), at the
end of the `main()` invocation list. Rationale: Check 42 gates a CI
infrastructure invariant rather than any single pack-product surface;
logical position is end-of-list, mirroring Check 41's end-of-list
landing for the adjacent BD-180 inventory gate. Documented at the
invocation site with a comment block referencing the gap-class
history.

### 2.3 test-validate-pack-check-42.sh design

Mirrors the test-validate-pack-check-41.sh harness shape (most-
recently-added per-check test; closest current pattern). Four test
groups:

**Group 0: Module import + Check 42 symbol registration.**
Confirms `check_ci_workflow_wires_per_check_tests` is importable
from validate-pack.py. Mirrors the Check 41 Group 0 shape exactly.

**Group 1: Real-state-at-HEAD PASS verification.**
Invokes Check 42 against the real REPO_ROOT and asserts PASS. Also
includes the *self-referential closure* check: at HEAD post-BD-184,
both `test-validate-pack-check-42.sh` AND its `bash scripts/tests/
test-validate-pack-check-42.sh` wiring line in the workflow yml MUST
be present. Also spot-checks that both naming forms (single-check
`check-NN.sh` AND bundled-check `checks-NN-NN-NN.sh`) appear on disk
— defends against a future refactor accidentally removing the
last single-form or bundled-form test (which would cause Group 2's
T8/T9 regression-guard tests to no longer exercise their intended
glob/grep behavior).

**Group 2: Synthetic REPO_ROOT PASS/FAIL tests (T1-T9).**

| Test | Coverage |
|------|----------|
| T1 | PASS path — every disk test has a wiring line; mixed naming forms |
| T2 | FAIL path — single-form `check-NN.sh` unwired (canonical gap-class shape) |
| T3 | FAIL path — bundled-form `checks-NN-NN-NN.sh` unwired (mirrors BD-179 FIX-1) |
| T4 | FAIL path — MULTIPLE unwired tests of mixed forms (mirrors BD-179 FIX-1 wiring 3 tests in one commit) |
| T5 | PASS path — extra workflow invocation WITHOUT a disk file (documents the intentional one-directional asymmetry) |
| T6 | SKIP path — `scripts/tests/` absent (lenient) |
| T7 | SKIP path — `.github/workflows/validate-pack.yml` absent (lenient) |
| T8 | Regression guard — disk glob `check*` (no trailing dash) catches bundled-form (would silently pass if glob were `check-*`) |
| T9 | Regression guard — workflow grep catches bundled-form (would FAIL the canonical-good state if grep missed `checks-`) |

Synthetic fixture pattern: each test uses `tempfile.mkdtemp()` +
patches `mod.REPO_ROOT` to point at the tmp dir, invokes the check,
captures stdout via `contextlib.redirect_stdout`, and restores state
in a `try/finally`. Mirrors Check 41's test-pattern exactly (file:
`scripts/tests/test-validate-pack-check-41.sh:run_check` helper).

**Group 3: End-to-end validate-pack.py exit-status on HEAD.**
Invokes `python3 scripts/validate-pack.py`, asserts exit 0, and
greps for the Check 42 header + count line + closure phrase.

### 2.4 Workflow wiring (self-referential closure)

Added a single `tests:` job sister-step after the Check 19 step
(last per-check test today) in `.github/workflows/validate-pack.yml`,
matching the canonical pattern:

```
      - name: validate-pack Check 42 tests (BD-184, CI workflow wires all per-check test files)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-42.sh
```

Position after Check 19 step maintains the temporal/numerical
convention (Check 42 is BD-184; landing after Check 19 BD-183 step
is BD-creation-order chronological).

**Self-referential closure.** This wiring is itself the contract
Check 42 enforces — Check 42 PASSing at HEAD requires its own
test wiring to be present. The three artifacts (check function +
test file + workflow wiring) land together so the closure holds
from the first PASS run.

---

## 3. Glob/grep pattern correctness verification

The critical design consideration from the prompt: glob/grep must
catch BOTH single-check and bundled-check naming forms.

**Empirical test (pre-implementation):**

```
$ ls scripts/tests/test-validate-pack-check-*.sh   # WRONG glob (with dash)
test-validate-pack-check-16.sh
test-validate-pack-check-18.sh
test-validate-pack-check-19.sh
test-validate-pack-check-39.sh
test-validate-pack-check-40.sh
test-validate-pack-check-41.sh
# MISSES: test-validate-pack-checks-32-33-34.sh, test-validate-pack-checks-36-37-38.sh

$ ls scripts/tests/test-validate-pack-check*.sh   # CORRECT glob (no dash)
test-validate-pack-check-16.sh
test-validate-pack-check-18.sh
test-validate-pack-check-19.sh
test-validate-pack-check-39.sh
test-validate-pack-check-40.sh
test-validate-pack-check-41.sh
test-validate-pack-checks-32-33-34.sh
test-validate-pack-checks-36-37-38.sh
```

**Implementation uses the correct glob:**
`tests_dir.glob("test-validate-pack-check*.sh")` (no trailing dash;
captures both `check-NN.sh` and `checks-NN-NN-NN.sh`).

**Workflow grep:**
`r"bash\s+scripts/tests/(test-validate-pack-check[^\s]+\.sh)"` —
again no trailing dash after `check`, so the `[^\s]+` filename body
captures both `-16.sh` AND `s-32-33-34.sh` shapes.

**Regression guards in test (T8 + T9).** Two synthetic tests
exercise these two behaviors directly:

- T8: stages ONLY a bundled-form test file on disk, wires NONE,
  expects FAIL on the bundled name. If the implementation had used
  the wrong glob, the bundled file would be invisible to the disk-
  walk and T8 would silently PASS — the wrong answer. T8 catches
  this regression mechanically.
- T9: stages a bundled-form disk test AND its bundled-form workflow
  wiring; expects PASS. If the implementation had used a grep that
  missed `checks-NN-NN-NN.sh` workflow lines, the bundled-form
  wiring would not be counted and T9 would FAIL — also the wrong
  answer. T9 catches this regression mechanically.

Together T8 + T9 lock the glob/grep correctness contract.

---

## 4. Self-referential closure verification

At HEAD post-implementation (working tree, pre-commit), Check 42
reports:

```
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.
```

Disk count = 9 (the 8 pre-BD-184 tests + the new
`test-validate-pack-check-42.sh`).
Workflow count = 9 (the 8 pre-BD-184 wirings + the new
`bash scripts/tests/test-validate-pack-check-42.sh` invocation).
Diff = empty set. PASS.

Group 1 of the test suite includes explicit assertions for:

- `"test-validate-pack-check-42.sh" in disk_tests` (test file is
  on disk).
- `"bash scripts/tests/test-validate-pack-check-42.sh" in
  workflow_text` (workflow wiring is in yml).

Both assertions pass, confirming the closure holds.

---

## 5. Files modified

**Diff stat:**

```
 .github/workflows/validate-pack.yml |   3 +
 scripts/validate-pack.py            | 154 ++++++++++++++++++++++++++++++++++++
 2 files changed, 157 insertions(+)
```

Plus one new file: `scripts/tests/test-validate-pack-check-42.sh`
(466 lines).

**Per-file purpose:**

| Path | Change type | Purpose |
|------|-------------|---------|
| `scripts/validate-pack.py` | modified | Add `check_ci_workflow_wires_per_check_tests()` function + module-docstring entry + `main()` invocation |
| `scripts/tests/test-validate-pack-check-42.sh` | new | Per-check test for Check 42 (4 groups, 9 synthetic T-cases + real-state-at-HEAD + e2e regression guard) |
| `.github/workflows/validate-pack.yml` | modified | New sister-step under `tests:` job invoking the new test (self-referential closure for Check 42's own gate) |

No other files touched — strict scope adherence.

---

## 6. Verification

### 6.1 `python3 scripts/validate-pack.py` — all 42 checks PASS

Run from working-tree HEAD post-implementation:

```
── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

Exit code 0. All 42 checks clean.

### 6.2 `bash scripts/tests/test-validate-pack-check-42.sh` — PASS

```
=== Group 0: Module import + Check 42 symbol registration ===
  PASS validate-pack.py imports + Check 42 symbol registered

=== Group 1: Real-state-at-HEAD PASS verification ===
OK
  PASS real-state-at-HEAD Check 42 PASSes + self-referential closure holds (test-42 file + wiring both present)

=== Group 2: Synthetic REPO_ROOT PASS/FAIL tests ===
OK
  PASS Synthetic PASS/FAIL tests (T1-T9 covering single + bundled naming forms, multi-unwired surfacing, lenient skips, and glob/grep regression guards)

=== Group 3: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0; Check 42 runs and reports clean

=== Summary ===
  PASS: 4
  FAIL: 0

All tests passed.
```

### 6.3 Adjacent test suites unchanged

Ran all 8 pre-existing per-check test files. All PASS:

| Test file | Result |
|-----------|--------|
| `test-validate-pack-check-16.sh` | PASS |
| `test-validate-pack-check-18.sh` | PASS |
| `test-validate-pack-check-19.sh` | PASS |
| `test-validate-pack-check-39.sh` | PASS |
| `test-validate-pack-check-40.sh` | PASS |
| `test-validate-pack-check-41.sh` | PASS |
| `test-validate-pack-checks-32-33-34.sh` | PASS (65/65) |
| `test-validate-pack-checks-36-37-38.sh` | PASS |

Zero regressions.

### 6.4 YAML syntax PASS

`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml')); print('YAML_OK')"` → `YAML_OK`.

### 6.5 Python syntax PASS

`python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read()); print('SYNTAX_OK')"` → `SYNTAX_OK`.

### 6.6 Bash syntax PASS

`bash -n scripts/tests/test-validate-pack-check-42.sh && echo BASH_SYNTAX_OK` → `BASH_SYNTAX_OK`.

---

## 7. RC9 manifest status

**Trigger.** Fires: `scripts/validate-pack.py` + `scripts/tests/test-
validate-pack-check-42.sh` are under `scripts/` (v11-surface trigger).
`.github/workflows/validate-pack.yml` is NOT v11-surface (the trigger
covers `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`
only).

**Action taken.** Ran `bash test-fixtures/build.sh --all --clean` per
RC9 protocol.

**Result.** `git diff test-fixtures/manifest.txt` is EMPTY (no
output). Confirmed expected outcome — all three modified files are
pack-internal (the validator + its test + the workflow yml are NOT
copied to clients by `init-project.sh`), so no fixture-affecting
change occurred. The cumulative-manifest-drift mechanism (per the
RC9 docstring) is unaffected.

No manifest staging needed.

---

## 8. Carry-forward discipline

Applied per `.claude/skills/review/SKILL.md` § "Carry-forward
discipline" to scope-adjacent observations encountered during
implementation. Zero deferrals; no scope-adjacent observations
required carry-forward.

Notes:

- The prompt explicitly scoped out "broader test-infrastructure
  improvements (e.g., extracting shared bash boilerplate to a lib)"
  per pack memory `feedback_no_deferral_without_user_direction`. I
  did not silently expand into infrastructure refactoring. The test
  helper pattern in `test-validate-pack-check-42.sh:run_check` is a
  per-test local helper (mirrors Check 41's `run_check` helper);
  extracting shared bash boilerplate across all 9 per-check tests
  is BD-185-or-later work.
- The Check 42 docstring documents the one-directional asymmetry
  (disk → workflow gated, workflow → disk not gated) explicitly so
  a future reviewer doesn't mistake it for a missing failure mode.
  This is in-scope clarification, not a defer.

---

## 9. Architect-doc-vs-reality reconciliation

BD-184 has no architect doc — explicitly mechanical pack-coder work
per the BACKLOG entry: "Implementation pattern: mechanical pack-coder
work (no architect spawn needed — Check 42 is a straightforward
file-glob-vs-workflow-grep comparison; pattern mirrors existing
checks)."

This IMPL-REPORT is the canonical reference for the Check 42 design.
Future reviewers/coders looking for Check 42 design rationale should
read this report (file: `maintenance-docs/v11-implementation/
IMPLEMENTATION-REPORT-BD-184.md`) AND the docstring at
`scripts/validate-pack.py:check_ci_workflow_wires_per_check_tests`.

No architect-doc addendum needed.

---

## 10. Boundary discipline check

No project-side files edited. All three changed paths are pack-side
(pack-internal infrastructure):

- `scripts/validate-pack.py` — pack-internal validator (not copied to
  clients).
- `scripts/tests/test-validate-pack-check-42.sh` — pack-internal test
  (not copied to clients).
- `.github/workflows/validate-pack.yml` — pack-internal CI workflow
  (not copied to clients).

Boundary discipline pre-flight (P-missed-7) not applicable to this
BD — no `project-template/`, `supporting-docs/`, or other pack-
shipped-to-client surface was touched.

---

## 11. Definition-of-Done checklist

| Item | Status |
|------|--------|
| Check 42 implemented in validate-pack.py + invoked in main() | PASS |
| `scripts/tests/test-validate-pack-check-42.sh` exists with full test coverage | PASS |
| Workflow yml has new sister-step for check-42 | PASS |
| `python3 scripts/validate-pack.py` exits 0 — all 42 checks PASS | PASS |
| Check 42's self-referential closure works (verifies its own test is wired) | PASS |
| `bash scripts/tests/test-validate-pack-check-42.sh` PASSes | PASS |
| Adjacent test suites unaffected (Check 16/18/19/39/40/41 + checks-32-33-34 + checks-36-37-38 still PASS) | PASS |
| RC9: empty manifest diff confirmed | PASS |
| IMPL-REPORT documents implementation + glob pattern correctness + self-referential closure verification | PASS |
| YAML syntax PASS | PASS |
| Python syntax PASS | PASS |
| Bash syntax PASS | PASS |

---

## 12. Files-changed inventory

| Path | Change type |
|------|-------------|
| `scripts/validate-pack.py` | modified |
| `scripts/tests/test-validate-pack-check-42.sh` | new (executable, +x) |
| `.github/workflows/validate-pack.yml` | modified |

(`test-fixtures/manifest.txt` unchanged after RC9 rebuild — diff
empty, no staging needed.)

---

## 13. Plan deviations

Zero.

The prompt's three implementation goals (Check 42 function +
test-validate-pack-check-42.sh + workflow wiring) were all
implemented mechanically per the spec. The "reasonable judgment
calls" enumerated in the prompt (grep-based parser; synthetic in-
test heredoc fixtures; position after Check 19; specific error
messages) all landed as recommended.

---

## 14. New POQs introduced

None.

---

PREFLIGHT: 3/3 in-scope file edits complete; verification PASS;
HEAD `0f8d8ee8a5ae0b88a7f98cd281d1f4effa52c443`; IMPL-REPORT written
to `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-184.md`.
