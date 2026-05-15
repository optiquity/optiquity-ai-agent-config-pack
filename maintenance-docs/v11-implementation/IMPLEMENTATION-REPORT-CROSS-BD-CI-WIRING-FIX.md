# IMPLEMENTATION-REPORT-CROSS-BD-CI-WIRING-FIX

**Type:** Cross-BD CI test-wiring fix (Batch 21c)
**Branch:** `v11-dev`
**Pre-edit HEAD:** `614e67ee908ea32308734873851e6e46fed4f98c`
**Date:** 2026-05-15
**Agent:** `pack-coder`
**Scope anchor:** Batch 21c retroactive per-BD reviews of BD-078, BD-079,
BD-129 each independently surfaced the same systemic gap — test scripts
authored alongside their BDs but never enumerated in
`.github/workflows/validate-pack.yml`. The workflow lists each test by
name (no glob, no auto-discovery), so unwired tests are dead from a CI
perspective despite passing locally. Four BD-13x sibling tests (BD-130,
BD-132, BD-133, BD-134) authored under non-Batch-21c BDs share the same
root cause and were named in the BD-129 retro reviewer's evidence (F1
"Cross-concept impact"). Single workflow edit closes 4 Batch 21c MUST
findings AND forward-prevents the same gap for the 4 sibling latents.

---

## 1. Summary

Wired all 7 unwired tracker-related test files into the `tests:` job of
`.github/workflows/validate-pack.yml`, immediately after the existing
`tracker error mapping tests (BD-066)` step (line 144-146 pre-edit) and
before the `recommendation tests (BD-072 / D-19)` step. Each new step
follows the established workflow convention: `name:` identifies the
test + originating BD; `if: always()` ensures one suite's failure does
not mask another's; `run: bash scripts/tests/<file>.sh` matches the
sibling-test invocation pattern with no soft-pass / no `|| true` /
no swallowed exit code. No existing step removed, reordered, or
modified. Workflow YAML still parses (verified). No edits to any of
the 7 test scripts. No edits to PM-owned files (`BACKLOG.md`,
`CHANGELOG.md`, `README.md`).

Net change: tests-job step count grows from 33 to 40 (+7).

---

## 2. Per-test wiring detail

All 7 new steps land in a contiguous block in
`.github/workflows/validate-pack.yml` between the existing
`tracker error mapping tests (BD-066)` step and the existing
`recommendation tests (BD-072 / D-19)` step. The diff snippet below is
shared across all 7 — they were applied in one atomic Edit so the
ordering is preserved and reviewable as a single unit:

```diff
       - name: tracker error mapping tests (BD-066)
         if: always()
         run: bash scripts/tests/tracker-errors-test.sh
+      - name: tracker-config-schema tests (BD-078, validate-pack Check 29)
+        if: always()
+        run: bash scripts/tests/tracker-config-schema-test.sh
+      - name: recommendation-state-schema tests (BD-079, validate-pack Check 30)
+        if: always()
+        run: bash scripts/tests/recommendation-state-schema-test.sh
+      - name: tracker BD-129 gh-repo routing tests (BD-129)
+        if: always()
+        run: bash scripts/tests/tracker-bd129-gh-repo-test.sh
+      - name: tracker BD-130 doctor-wired tests (BD-130)
+        if: always()
+        run: bash scripts/tests/tracker-bd130-doctor-wired-test.sh
+      - name: tracker BD-132 init-disable race tests (BD-132)
+        if: always()
+        run: bash scripts/tests/tracker-bd132-race-test.sh
+      - name: tracker BD-133 header-preservation tests (BD-133)
+        if: always()
+        run: bash scripts/tests/tracker-bd133-header-preservation-test.sh
+      - name: tracker BD-134 close-retry tests (BD-134)
+        if: always()
+        run: bash scripts/tests/tracker-bd134-close-retry-test.sh
       - name: recommendation tests (BD-072 / D-19)
         if: always()
         run: bash scripts/tests/recommendation-test.sh
```

### 2.1 `scripts/tests/tracker-config-schema-test.sh`

- **BD origin:** BD-078 (validate-pack.py Check 29 fixture suite, 9
  scenarios / 17 assertions, ship commit `91a9fc5`).
- **Batch 21c finding closed:** BD-078 F2 (MUST).
- **Workflow location:** lines 147-149 (post-edit).
- **Step name:**
  `tracker-config-schema tests (BD-078, validate-pack Check 29)`.
- **Invocation:** `bash scripts/tests/tracker-config-schema-test.sh`.
- **Pattern conformance:** matches sibling `tracker-errors-test.sh`
  step format (line 144-146 pre-edit) — `if: always()`, `bash
  scripts/tests/<file>` invocation, BD-N attribution in the name. The
  parenthetical `validate-pack Check 29` mirrors the BD-079 step's
  `validate-pack Check 30` mention (added below) — both make the
  CI failure trail back to the correct numbered Check at a glance.

### 2.2 `scripts/tests/recommendation-state-schema-test.sh`

- **BD origin:** BD-079 (validate-pack.py Check 30 fixture suite, 10
  scenarios / 19 assertions, ship commit `91a9fc5`).
- **Batch 21c finding closed:** BD-079 F1 (MUST).
- **Workflow location:** lines 150-152 (post-edit).
- **Step name:**
  `recommendation-state-schema tests (BD-079, validate-pack Check 30)`.
- **Invocation:** `bash scripts/tests/recommendation-state-schema-test.sh`.
- **Pattern conformance:** parallel-structure to BD-078's step (Check
  29 vs Check 30); placed adjacent to make the validator-Check
  fixture-suite cluster grep-able.

### 2.3 `scripts/tests/tracker-bd129-gh-repo-test.sh`

- **BD origin:** BD-129 / D-1 (gh CLI `--repo` / GH_REPO routing
  regression suite, 11 assertions, ship commit `1bdd1f5`).
- **Batch 21c finding closed:** BD-129 F1 (MUST).
- **Workflow location:** lines 153-155 (post-edit).
- **Step name:** `tracker BD-129 gh-repo routing tests (BD-129)`.
- **Invocation:** `bash scripts/tests/tracker-bd129-gh-repo-test.sh`.
- **Pattern conformance:** matches the sibling
  `tracker-errors-test.sh` step format; the `tracker BD-NNN <subject>`
  naming form is used consistently across all 5 BD-1xx tracker tests
  added in this fix-follow (2.3-2.7) so a CI failure surfaces the BD
  immediately.

### 2.4 `scripts/tests/tracker-bd130-doctor-wired-test.sh`

- **BD origin:** BD-130 (doctor-verb wiring regression — BD-067 wired
  the verb but did not source the lib; ship commit `1bdd1f5`).
- **Batch 21c finding:** Latent (named in BD-129 F1 as a sibling
  with the same root cause; not directly a Batch 21c MUST against
  BD-130 itself).
- **Workflow location:** lines 156-158 (post-edit).
- **Step name:** `tracker BD-130 doctor-wired tests (BD-130)`.
- **Invocation:** `bash scripts/tests/tracker-bd130-doctor-wired-test.sh`.
- **Pattern conformance:** same `tracker BD-NNN <subject>` form as 2.3.

### 2.5 `scripts/tests/tracker-bd132-race-test.sh`

- **BD origin:** BD-132 (init→disable silent-data-loss race fix
  regression suite — three-part fix: forward close-stabilization wait,
  reverse race-detection, reverse-loop loud-failure on skip).
- **Batch 21c finding:** Latent (named in BD-129 F1 cross-concept
  impact list).
- **Workflow location:** lines 159-161 (post-edit).
- **Step name:** `tracker BD-132 init-disable race tests (BD-132)`.
- **Invocation:** `bash scripts/tests/tracker-bd132-race-test.sh`.
- **Pattern conformance:** same form as 2.3-2.4. The `init-disable
  race` subject hints at the failure mode being guarded so a CI red
  immediately suggests the data-loss surface.

### 2.6 `scripts/tests/tracker-bd133-header-preservation-test.sh`

- **BD origin:** BD-133 / D-6 (BACKLOG.md preamble preservation
  across reverse migration — snapshot/apply pattern).
- **Batch 21c finding:** Latent (named in BD-129 F1 cross-concept
  impact list).
- **Workflow location:** lines 162-164 (post-edit).
- **Step name:** `tracker BD-133 header-preservation tests (BD-133)`.
- **Invocation:** `bash scripts/tests/tracker-bd133-header-preservation-test.sh`.
- **Pattern conformance:** same form as 2.3-2.5.

### 2.7 `scripts/tests/tracker-bd134-close-retry-test.sh`

- **BD origin:** BD-134 (forward step-8 close retry-with-backoff
  regression suite — drives partial-write rate from ~5% toward zero
  on transient gh API failures).
- **Batch 21c finding:** Latent (named in BD-129 F1 cross-concept
  impact list).
- **Workflow location:** lines 165-167 (post-edit).
- **Step name:** `tracker BD-134 close-retry tests (BD-134)`.
- **Invocation:** `bash scripts/tests/tracker-bd134-close-retry-test.sh`.
- **Pattern conformance:** same form as 2.3-2.6.

---

## 3. Files modified

| Path | Type | Line delta |
|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | +21 / -0 (7 new step blocks × 3 lines each = 21 added lines; 0 removed) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CROSS-BD-CI-WIRING-FIX.md` | new | +N (this report) |

**Files explicitly NOT touched** (per scope constraints):

- All 7 test scripts in `scripts/tests/` — gap is wiring only; the
  scripts themselves exist and pass locally.
- `BACKLOG.md` — Pack Chat handles BD entries (any deferral
  discoveries surface in §5).
- `CHANGELOG.md` — Pack Chat handles changelog entries.
- Any other workflow file or pack source.
- The trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) — no
  rule change involved; the fix is mechanical CI wiring.
- `PACK-CHAT.md` / `PACK-AGENTS.md` / `README.md` — out of scope for
  this fix.

---

## 4. Verification

### 4.1 YAML parse check

```
$ python3 -c "import yaml; d = yaml.safe_load(open('.github/workflows/validate-pack.yml')); print('YAML parse OK'); steps = d['jobs']['tests']['steps']; print('tests-job step count:', len(steps)); print('validate-job step count:', len(d['jobs']['validate']['steps']))"
YAML parse OK
tests-job step count: 40
validate-job step count: 4
```

YAML parses. The `tests:` job step count is 40 post-fix (was 33
pre-fix; +7 matches the 7 new steps added). The `validate:` job is
unaffected (4 steps). No existing step removed.

### 4.2 Wiring grep verification

```
$ grep -n "scripts/tests/" .github/workflows/validate-pack.yml | grep -E "(tracker-config-schema|recommendation-state-schema|tracker-bd129|tracker-bd130|tracker-bd132|tracker-bd133|tracker-bd134)"
149:        run: bash scripts/tests/tracker-config-schema-test.sh
152:        run: bash scripts/tests/recommendation-state-schema-test.sh
155:        run: bash scripts/tests/tracker-bd129-gh-repo-test.sh
158:        run: bash scripts/tests/tracker-bd130-doctor-wired-test.sh
161:        run: bash scripts/tests/tracker-bd132-race-test.sh
164:        run: bash scripts/tests/tracker-bd133-header-preservation-test.sh
167:        run: bash scripts/tests/tracker-bd134-close-retry-test.sh
```

All 7 new wiring lines present at the expected locations (147-167
block in the post-edit file).

### 4.3 Step-count drift / hardcoded count check

```
$ grep -n -E "step count|step total|N steps|[0-9]+ steps|[0-9]+ entries" .github/workflows/validate-pack.yml
(no output)
```

No header comment in `.github/workflows/validate-pack.yml` cites a
hardcoded step count, so no comment update is required to prevent
NIT-3-style count drift downstream. (For future reference: post-fix
`tests:` step count is 40.)

### 4.4 "Would this turn red?" interrogation per new step

For each new step, name a specific change to the underlying script
that should fail it, and confirm the wiring would surface that
failure as a red CI step. Each interrogation is grounded in the test
script's actual assertions (read at start of session).

#### 4.4.1 `tracker-config-schema-test.sh` (BD-078)

- **Specific change that should turn it red:** mutate
  `_TRACKER_SCHEMA_VERSION` in `scripts/validate-pack.py` from `1` to
  `2` without updating Test 2 ("Bad schema_version on pack-example")
  fixture's `schema_version = 99` to expect a different message — or
  remove the `_validate_tracker_toml` call entirely from
  `check_tracker_config()`.
- **Wiring catches it because:** the test exits non-zero on any
  `t_fail`; `bash scripts/tests/tracker-config-schema-test.sh` returns
  that non-zero; the workflow step has no `|| true`, no `continue-
  on-error`, no soft-pass, so GitHub Actions marks the step red and
  the `tests:` job fails.

#### 4.4.2 `recommendation-state-schema-test.sh` (BD-079)

- **Specific change that should turn it red:** remove the bool-
  rejection branch in `check_recommendation_state_schema()` (the one
  the BD-079 retro review's §6 acknowledged at lines 2308-2314), and
  Test 10 ("user_re_enable_count is bool") would no longer trigger a
  fail message.
- **Wiring catches it because:** Test 10's assertion expects a fail
  with "rejects bool-as-int"; if the branch is removed, the assertion
  flips and the test exits non-zero. The workflow step (no soft-pass)
  surfaces it as red.

#### 4.4.3 `tracker-bd129-gh-repo-test.sh` (BD-129)

- **Specific change that should turn it red:** remove the
  `tracker_gh_repo_setup` call from `_gh_run` in
  `scripts/lib/tracker-provider-gh.sh` (the seam BD-129 added).
  Group 3 ("freshly-cloned repo with no remote configured") asserts
  every gh call sees `GH_REPO=DShaneNYC/example-repo`; without the
  helper invocation, the GH_REPO line would be absent from the fake-
  gh log and the assertion fails.
- **Wiring catches it because:** non-zero exit propagates through
  `bash scripts/tests/tracker-bd129-gh-repo-test.sh` to the workflow
  step (no `|| true`, no swallow); CI step turns red.

#### 4.4.4 `tracker-bd130-doctor-wired-test.sh` (BD-130)

- **Specific change that should turn it red:** remove the line that
  sources `scripts/lib/tracker-doctor.sh` from
  `scripts/pack-tracker.sh`. The test's assertion 1 (`pack-tracker.sh
  doctor` does NOT emit "command not found") would fire because
  `tracker_doctor_run` would again be undefined.
- **Wiring catches it because:** non-zero exit on assertion failure;
  workflow step has no soft-pass; CI red.

#### 4.4.5 `tracker-bd132-race-test.sh` (BD-132)

- **Specific change that should turn it red:** remove the
  `_tmf_wait_for_close_stabilization` call (Part 1 of the BD-132 fix)
  from the forward emitter in
  `scripts/lib/tracker-migrate-forward.sh`. The test's race-window
  assertions would observe the un-stabilized close behavior and fail.
- **Wiring catches it because:** test exits non-zero on any race
  scenario failure; workflow step (no soft-pass) surfaces red.

#### 4.4.6 `tracker-bd133-header-preservation-test.sh` (BD-133)

- **Specific change that should turn it red:** delete the
  `tracker_header_snapshot_apply` call from the reverse emitter so
  the BACKLOG.md preamble is no longer prepended back after entries
  are written. Test groups 2-4 (round-trip preamble survival,
  multi-cycle stability) would all fail because the sentinel preamble
  would be missing from the round-tripped output.
- **Wiring catches it because:** non-zero exit; workflow step (no
  soft-pass) surfaces red.

#### 4.4.7 `tracker-bd134-close-retry-test.sh` (BD-134)

- **Specific change that should turn it red:** hardcode
  `TMF_CLOSE_RETRY_MAX_ATTEMPTS=1` (or remove the retry loop
  entirely) so transient close failures are no longer recovered.
  Group 1 ("Transient close fails N-1 times, succeeds on retry") would
  fail because the close would not be retried and partial-writes
  would be > 0.
- **Wiring catches it because:** non-zero exit from the failing
  group; workflow step has no soft-pass; CI red.

### 4.5 Pattern-conformance summary

All 7 new steps:
- Use the exact same 3-line block format as every existing step in
  the `tests:` job (`- name:` / `if: always()` / `run: bash …`).
- Use `if: always()` so a failure in one suite does not mask another's
  results (matches the file-header rationale at lines 7-8).
- Use `bash scripts/tests/<file>.sh` invocation matching every
  sibling tracker-* test step (verified against lines 116, 119, 122,
  125, 128, 131, 134, 137, 140, 143, 146 pre-edit).
- Have no `|| true`, no `continue-on-error: true`, no swallowed exit
  codes, no soft-pass, no fallback. Non-zero exit from the test
  script propagates 1:1 to step failure.
- Name the BD in the step name so a CI failure trail names the
  originating BD without grep.

---

## 5. Out-of-scope items / Pack Chat decisions

These were noticed during this fix but explicitly NOT acted on (per
scope constraints — deferred-work rule has Pack Chat decide tracking).

### 5.1 BACKLOG `Resolved:` line stale references (BD-078 F9, BD-079 F-4, BD-129 F10)

Three of the retro reviews flag the same systemic Pattern B sweep
side-effect: `BACKLOG.md` `Resolved:` lines point to
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-*.md`
paths that have been swept to `maintenance-docs/archive/v11/`. This
affects many BDs beyond the three retro-reviewed; agents cannot fix
(BACKLOG is PM-Chat-owned). Pack Chat may want to plan a dedicated
BACKLOG-link sweep batch.

### 5.2 Two BD-129/BD-130 test files lack +x bit (BD-129 F9)

`tracker-bd129-gh-repo-test.sh` and `tracker-bd130-doctor-wired-test.sh`
are 644 (not executable); the three later BD-13x sibling tests are
755. CI invokes via `bash` regardless so this is cosmetic; mentioned
for awareness only. NOT fixed here because (a) this fix's scope is
workflow wiring only, (b) `chmod` is a state-changing file op
(filesystem-mode metadata change) requiring user approval per pack
memory, and (c) the wiring works either way.

### 5.3 BD-078 F1 (acceptance criterion B — staleness warning) and other Batch 21c findings

Multiple Batch 21c retro reviews surfaced findings beyond CI wiring:
BD-078 F1 (the dropped `mode tracker` mirror staleness leg), BD-078
F3-F8, BD-079 F-2 / F-3, BD-129 F2-F8. None are addressed here
because this fix's scope is the cross-BD CI wiring only. Pack Chat
decides which findings get fix-shipped in subsequent batches.

### 5.4 Glob-based test discovery (BD-129 F1 alternative fix)

The BD-129 retro reviewer noted a "broader, more durable fix is to
convert the workflow's per-test enumeration into a glob: `for f in
scripts/tests/*-test.sh; do bash "$f"; done`. That is out of scope
for a BD-129 fix-follow but is the right architectural direction."
This fix takes the per-test enumeration approach (matches every
existing pattern in the workflow). A later BD could revisit if the
manual-enumeration drift becomes a recurring footgun. The file-header
comment at lines 7-8 already promises glob behavior ("runs every
`scripts/tests/*-test.sh` independently") — there is an existing
documentation-vs-implementation drift the comment / behavior gap that
a future BD could close.

### 5.5 `scripts/test-*` (non-`scripts/tests/`) test files

Some pack tests live at `scripts/test-*.sh` rather than under
`scripts/tests/` (e.g., `scripts/test-detect.sh`,
`scripts/test-migrator-core.sh`, `scripts/test-migrator-manifest.sh`,
`scripts/test-migrator-capability-translation.sh`,
`scripts/test-migrator-skills.sh`, `scripts/test-persona-contracts.sh`).
These are already wired (verified — lines 113, 170, 173, 176, 201,
204 pre-edit). Mentioned only to confirm no orphan test files in
that path family slipped through this audit.

---

## 6. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| 7 new steps added to `.github/workflows/validate-pack.yml` (one per test file) | PASS | §2.1-2.7 + §4.2 grep |
| `python3 -c "import yaml; yaml.safe_load(...)"` passes | PASS | §4.1 output |
| `IMPLEMENTATION-REPORT-CROSS-BD-CI-WIRING-FIX.md` exists with all required sections | PASS | This file (§1 Summary, §2 per-test detail, §3 files modified, §4 verification, §5 out-of-scope, §6 DoD) |
| No edits to forbidden files | PASS | §3 explicitly enumerates non-touched files |
| No edits to the 7 test scripts | PASS | Only `.github/workflows/validate-pack.yml` and this report touched |
| Step name pattern matches existing wired tests | PASS | §4.5 pattern-conformance summary |
| Each new step's "would this turn red?" interrogation is documented and credible | PASS | §4.4 (7 interrogations, one per step) |
| No `|| true` / soft-pass / swallowed exit codes in new steps | PASS | §4.5 + verifiable in §2 diff |
| Existing wired tests not regressed (no step removed/reordered) | PASS | §4.1 (validate-job count unchanged at 4; tests-job grew from 33→40 = +7 exact) |
| No state-changing git verbs run | PASS | This session ran only `git rev-parse HEAD` and `git status` (read-only) |
| YAML still parses post-edit | PASS | §4.1 |
| Trinity rule N/A | PASS | No trinity file touched |
| macOS bash 3.2 + BSD utils compatibility N/A for YAML | PASS | YAML, not shell |

---

## 7. Plan deviations

**None.** The fix is purely the cross-BD CI wiring described in the
scope. No new test logic, no test-script edits, no architecture
change, no PM-only file edits, no trinity edits, no scope creep into
the SHOULD/NIT findings the retro reviews surfaced.

---

## 8. New POQs introduced

**None.** No questions surfaced that aren't already covered by the
out-of-scope items in §5 (which Pack Chat triages, not POQs the
implementer raised).

---

## Appendix A — Full new-file content

This implementation does not create any new pack source files. The
only new file is this report itself. No fixture, library, script, or
documentation file was added. The 7 test scripts already existed on
disk pre-edit (verified by `ls scripts/tests/tracker-bd*-*.sh
scripts/tests/*config-schema*.sh scripts/tests/*recommendation-state*.sh`
returning all 7 paths).
