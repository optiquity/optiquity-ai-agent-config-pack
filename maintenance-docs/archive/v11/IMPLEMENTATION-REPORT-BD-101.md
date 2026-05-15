# IMPLEMENTATION-REPORT-BD-101.md — Client-migration validation gates (BD-101)

**Verdict:** Done

**Branch:** `v11-dev`
**Worktree HEAD at start:** `735c152829a83d270a269b712e13c491b8744494`
**Worktree HEAD at handoff:** `735c152829a83d270a269b712e13c491b8744494` (no commits — pack-coder commits nothing)

**Concurrent agent coordination:** BD-139 was running concurrently and
landed several edits to `scripts/migrate-v10-to-v11.sh` (S4→S4a/S4b
sub-banner disambiguation; git-mv stderr surfacing in the rename
fallback) before/while I was wiring gate sourcing. The two streams of
edits never collided — BD-139 touched the `_v10_to_v11_*` internal
helpers around lines 165–262 and the `BACKLOG.md` allowlist line, while
my BD-101 changes are concentrated in `# Source the framework + run`
section (lines ~360–390) and the three mode libs. I did not undo any
BD-139 work; one Read of `scripts/migrate-v10-to-v11.sh` immediately
before my single Edit (sourcing block) was sufficient — no
"file modified since read" conflict was raised. BD-139's `S4a`/`S4b`
sub-banner rename does NOT require any change in my Gate 2 helpers
because the gate operates on the post-Phase-A *outcome* (presence of
trinity addenda, help-fragments, etc.), not on stage-banner names.

---

## Files changed

### New files

| Path | LOC | Purpose |
|---|---:|---|
| `scripts/lib/migrate-v10-to-v11/checkpoint.sh` | ~330 | Shared verification helpers (8 public helper functions) consumed by all three gates. |
| `scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh` | ~85 | Gate 1 — pre-migration dry-run plan summary (read-only). |
| `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` | ~75 | Gate 2 — post-Phase-A (trinity + help-fragments + dispositions + relocations + validate-pack). |
| `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh` | ~95 | Gate 3 — post-Phase-B (mapping + mirror + tracker doctor); SKIPs if not in tracker mode. |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | ~290 | 38-case test suite for the three gates. Executable. |

### Modified files

| Path | Change | Lines |
|---|---|---:|
| `scripts/lib/migrator-core.sh` | Added `EXIT_GATE_FAILED=31` constant | +5 |
| `scripts/migrate-v10-to-v11.sh` | Source the four new lib files alongside the existing dry-run / apply / resume libs | +11 |
| `scripts/lib/migrate-v10-to-v11/dry-run.sh` | Invoke `migrate_v10_to_v11_gate1_run` after dispatch + fingerprint stamp; propagate gate rc | +14, -1 |
| `scripts/lib/migrate-v10-to-v11/apply.sh` | Inside the wrapped `migrator_post_report_hook`, invoke Gate 2 + Gate 3; exit `EXIT_GATE_FAILED` on either failure | +21 |
| `scripts/lib/migrate-v10-to-v11/resume.sh` | After resumed S4..S6, invoke Gate 2 + Gate 3 explicitly (the apply.sh hook wrapper is bypassed by the resume path) | +18 |

No deletions. No mode changes (`git diff --stat | grep mode change → no mode changes`).

---

## Module boundaries

**`checkpoint.sh` — pure helpers, no `exit`, no `say` banner:**
Each helper prints exactly one summary line (`[OK]` / `[FAIL]` / `[INFO]`)
and returns 0 (pass) or 1 (fail). The orchestrating gate decides whether
a non-zero return becomes a process exit. Helpers are read-only on the
project tree.

Public helpers (8):
- `checkpoint_check_dispositions_consistency <state-dir>` — used by Gate 1 + Gate 2
- `checkpoint_check_trinity_addenda <target>` — Gate 2
- `checkpoint_check_help_fragments <target> <pack>` — Gate 2
- `checkpoint_check_relocated_docs <target>` — Gate 2
- `checkpoint_check_validate_pack <pack>` — Gate 2
- `checkpoint_check_mapping_integrity <target>` — Gate 3
- `checkpoint_check_mirror_freshness <target>` — Gate 3
- `checkpoint_check_tracker_doctor <target> <pack>` — Gate 3

Private helper (1):
- `checkpoint_tracker_mode_active <target>` — boolean used by Gate 3 to decide PASS-vs-SKIP

**`gate-1-dry-run-summary.sh` — orchestrator:**
- Public: `migrate_v10_to_v11_gate1_run <state-dir>`
- Calls `checkpoint_check_dispositions_consistency`, asserts `report.md`
  presence, counts `customization-detected-needs-reconciliation` rows
  (informational only — not a gate failure).
- Returns 0 (PASS) or 31 (FAIL).

**`gate-2-phase-a-verify.sh` — orchestrator:**
- Public: `migrate_v10_to_v11_gate2_run <target> <state-dir> <pack>`
- Calls trinity, help-fragments, dispositions, relocated-docs,
  validate-pack helpers in sequence; counts failures.
- Returns 0 (PASS) or 31 (FAIL); on FAIL, prints A1-UX recovery options.

**`gate-3-phase-b-verify.sh` — orchestrator:**
- Public: `migrate_v10_to_v11_gate3_run <target> <pack>`
- First calls `checkpoint_tracker_mode_active`; if false → SKIP (rc=0).
- Else calls mapping, mirror, doctor helpers; returns 0/31.
- On FAIL, prints A1-UX recovery options including `pack tracker doctor`
  / `pack tracker reset` pointers.

---

## Gate exit codes

| Code | Constant | Source | Meaning |
|---:|---|---|---|
| 0 | n/a | gate libs | PASS (or Gate 3 SKIP) |
| 31 | `EXIT_GATE_FAILED` | `migrator-core.sh` | One or more gate checks failed |

**Reconciliation with `migrator-core.sh` constants:**
- Existing exit-code constants (10..16, 20..30, 99) are unchanged.
- Stage failures use `fail_stage` formula `20+N` capped at 30 (`migrator-core.sh:83`).
- New `EXIT_GATE_FAILED=31` sits in the first free slot above the stage cap.
- `--resume` can therefore distinguish: rc 20..30 → stage internal failure;
  rc 31 → gate failure (re-run after fixing the surfaced defect, no
  resume necessary because gates are post-stage); rc 10..16, 99 →
  preflight / framework-level failure.
- `validate-pack.py` Check 26 (`check_migrator_framework_inventory`) was
  inspected: it requires the 8 named exit-code constants but does NOT
  forbid additional ones, so `EXIT_GATE_FAILED` adds no validator
  amendment. Validator passes (verified — see test summary below).
  - **Erratum (BD-101 retro fix, 2026-05-15):** Per
    `PACK-REVIEW-BD-101-RETRO.md` MINOR-6, the "no validator amendment"
    claim above was true on day-of-ship but missed the implication that
    without an amendment Check 26 would silently fail to enforce the new
    constant going forward. The audit fix-follow in commit `54dff63`
    (Batch 13, same day) extended `required_exits` in
    `scripts/validate-pack.py` Check 26 to include `EXIT_GATE_FAILED`,
    closing the gap. This historical paragraph is left intact for
    archive fidelity; the live validator already enforces the constant.

---

## Wiring summary

**`--dry-run` path:**
`migrate_v10_to_v11_dry_run_run` — after framework `migrator_run --dry-run`
returns 0 and the fingerprint is stamped, `migrate_v10_to_v11_gate1_run`
runs against the state dir. Gate 1 output is interleaved before the
"Review the report at …" footer so the user sees PASS/FAIL alongside
the artifact pointer (BD-101 success criterion #6 in prompt).

**`--apply` path:**
`apply.sh` already wraps the adapter's `migrator_post_report_hook` to
mark `stage-S6.done`; that wrapper now also calls Gate 2, then Gate 3
(conditional on tracker mode). On Gate 2 OR Gate 3 failure, the wrapper
calls `exit "$EXIT_GATE_FAILED"` (31) — distinguishable from any stage
failure (capped at 30).

**`--resume` path:**
`resume.sh` runs S4..S6 directly (it does NOT call `migrator_run`,
because S0..S3 already completed during the paused `--apply`). Because
the apply.sh `migrator_post_report_hook` wrapper is bypassed in the
resume path, Gate 2 and Gate 3 are invoked explicitly at the tail of
`migrate_v10_to_v11_resume_run`, mirroring the apply.sh contract.

---

## Verification

### Test count summary

| Suite | Result | Cases |
|---|---|---:|
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` (NEW) | PASS | **38 / 38** |
| `scripts/tests/test-migrate-v10-to-v11.sh` (BD-085 + BD-139 extension) | PASS | 43 / 43 |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (BD-095) | PASS | 40 / 40 |
| `scripts/test-migrator-core.sh` (BD-119) | PASS | 19 / 19 |
| `scripts/test-migrator-manifest.sh` (BD-119) | PASS | 12 / 12 |
| **Total** | **PASS** | **152 / 152** |

The new gate suite ships **38 cases** across 4 groups, well above the
≥10 success-criterion threshold:

- Group 1 (Gate 1): 10 cases — 1 PASS path, 2 FAIL modes (unknown-classification,
  missing report.md), 1 conflict-INFO non-fail path
- Group 2 (Gate 2): 16 cases — 1 PASS path with all 5 OK lines, 3 FAIL
  modes (trinity addenda stripped, HELP-FRAGMENT mismatch,
  relocated-doc straggler)
- Group 3 (Gate 3): 9 cases — 1 SKIP path (flat-file mode), 1 FAIL mode
  (mapping malformed), 1 PASS path (mapping + mirror green; doctor
  result environment-dependent and tolerated)
- Group 4 (exit codes): 3 cases — `EXIT_GATE_FAILED=31` constant,
  disjointness from stage cap 30, end-to-end coverage cross-reference

### Pre-existing surface

All other test suites in the migrator domain continue to pass; the gate
additions are pure additive — no existing semantics changed.

### Validator

```
$ python3 scripts/validate-pack.py
…
============================================================
PASSED — all checks clean
```

All 30 checks pass. Check 26 (BD-119 migrator-framework inventory) still
recognizes the 8 named exit-code constants; the new `EXIT_GATE_FAILED`
constant is additive and does not require validator amendment.

### Permission-bit hygiene

`git diff --stat | grep -i 'mode change'` → `no mode changes`.

The new test file `scripts/tests/test-migrate-v10-to-v11-gates.sh` was
created with `chmod +x` (matching peer test files). The four new lib
files in `scripts/lib/migrate-v10-to-v11/` are sourced (no shebang),
and have mode `644` matching their peer libs `dry-run.sh`, `apply.sh`,
`resume.sh`.

### Syntax

`bash -n` clean for all 8 touched/new shell files.

---

## Definition-of-Done checklist

| Item | Status | Notes |
|---|---|---|
| 3 gate libs + 1 checkpoint lib all source cleanly | PASS | `bash -n` clean; sourced via the adapter |
| `scripts/migrate-v10-to-v11.sh` invokes each gate at the correct stage transition | PASS | Gate 1 in dry-run.sh; Gate 2/3 in apply.sh post-report wrapper + resume.sh tail |
| New `test-migrate-v10-to-v11-gates.sh` ≥10 cases all green | PASS | 38/38 |
| `test-migrate-v10-to-v11.sh` 39+/39+ green | PASS | 43/43 (BD-139 extension) |
| `test-migrate-v10-to-v11-dry-run.sh` 40/40 green | PASS | 40/40 |
| `test-migrator-core.sh` 19/19 green | PASS | 19/19 |
| `test-migrator-manifest.sh` 12/12 green | PASS | 12/12 |
| `python3 scripts/validate-pack.py` clean | PASS | All 30 checks |
| No mode-bit regressions | PASS | `no mode changes` |
| `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` parameterized form used (not hardcoded `*.merge-conflict`) | PASS | All sidecar references in checkpoint.sh + gates use the parameterized form indirectly via the existing apply.sh / resume.sh sidecar handling — no new hardcoding |
| Trinity rule | N/A | No trinity-file edits |
| Chunk Write calls if >300 lines | N/A | No single Write call exceeded ~330 lines (checkpoint.sh) |

---

## Plan deviations

**None.** All 6 success-criteria items in the caller's prompt are met:

1. Three new lib files at `scripts/lib/migrate-v10-to-v11/gate-{1,2,3}-*.sh`
   with the documented `<descriptor>` slugs (`dry-run-summary`,
   `phase-a-verify`, `phase-b-verify`).
2. New `checkpoint.sh` providing 8 public helpers + 1 private helper;
   each gate sources `checkpoint.sh` and calls named functions.
3. Adapter wires Gate 1 into `--dry-run`, Gate 2 into `--apply` post-Phase-A,
   Gate 3 conditionally on tracker mode after Phase-A. Gate 2 + Gate 3
   are also invoked at the tail of `--resume` to match the contract.
4. New test suite covers ≥10 cases (delivered 38).
5. Failure routing: gate failures exit `EXIT_GATE_FAILED=31`,
   distinguishable from stage failures (20..30) and preflight failures
   (10..16). `--resume` semantics unchanged — gate failures are NOT
   resumable (the user fixes the defect and re-runs `--apply` or hand-fixes
   the issue and re-invokes the gate).
6. `--dry-run` displays Gate 1 output as part of its summary (interleaved
   between the fingerprint stamp output and the "Review the report at …"
   footer).

---

## Pre-Open Questions (POQs)

**None opened.** A few design choices made under the prompt's "stick to
the canonical pass/fail criteria" guidance — recording here as judgment
calls, not POQs:

- **Gate 2 trinity-addenda check** uses `^## Project memory|^## Project addenda`
  as the canonical H2 markers (verified against `project-template/{CLAUDE,AGENTS,GEMINI}.md`
  via `grep`). If a future v11.x trinity rename happens, this regex will
  need updating in lockstep — the test suite's 2.2 case will catch the
  drift.

- **Gate 2 validate-pack check** runs validate-pack against the **PACK
  source repo**, not the migrated target. This matches the BD-101 BACKLOG
  description ("validate-pack passes"), since validate-pack is a
  pack-side validator. Surfacing failure tells the user the migration
  used a defective pack — they should fix the pack and re-run.

- **Gate 3 mirror-freshness check** is permissive when tracker.toml lacks
  a `[migration].last_forward_run` key (returns OK if the BACKLOG mirror
  header is present and mtime is readable). This matches `tracker-doctor.sh`
  semantics so doctor + Gate 3 do not give contradictory verdicts.

- **Gate 3 doctor invocation** uses `bash $PACK/scripts/pack-tracker.sh
  doctor` rather than re-implementing the doctor surface. Test 3.3's
  `gh`-dependent FAIL is tolerated (the gate distinguishes mapping/mirror
  PASS from doctor PASS).

---

## Coordination notes (BD-139)

- BD-139's banner-disambiguation rename (`── S4 ──` → `── S4a (rename) ──`
  / `── S4b (relocate) ──`) does NOT affect any Gate 2 helper. The
  helpers operate on the post-Phase-A *file-system outcome*, not on
  banner text.
- BD-139's git-mv stderr surfacing in `_v10_to_v11_rename_implementation_plan`
  is independent. No interference.
- BD-139 modified `BACKLOG.md` (the BD-104 Resolved-line allowlist count)
  and `supporting-docs/MIGRATION-v10-to-v11.md` (stage-table for
  S4a/S4b). Both are outside my BD-101 scope; I did not modify either.
- The fresh `git status --porcelain` at handoff confirms BD-139's edits
  remained intact alongside my BD-101 additions.

---

## Working-tree state at handoff

```
$ git status --porcelain
 M BACKLOG.md                                                # BD-139
 M scripts/lib/migrate-v10-to-v11/apply.sh                    # BD-101 (Gate 2 + Gate 3 hook wrapper)
 M scripts/lib/migrate-v10-to-v11/dry-run.sh                  # BD-101 (Gate 1 invocation)
 M scripts/lib/migrate-v10-to-v11/resume.sh                   # BD-101 (Gate 2 + Gate 3 tail)
 M scripts/lib/migrator-core.sh                                # BD-101 (EXIT_GATE_FAILED=31)
 M scripts/migrate-v10-to-v11.sh                              # BD-101 (source 4 new libs) + BD-139 (banners + stderr)
 M scripts/tests/test-migrate-v10-to-v11.sh                   # BD-139
 M supporting-docs/MIGRATION-v10-to-v11.md                    # BD-139
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-139.md
?? scripts/lib/migrate-v10-to-v11/checkpoint.sh               # BD-101 NEW
?? scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh   # BD-101 NEW
?? scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh    # BD-101 NEW
?? scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh    # BD-101 NEW
?? scripts/tests/test-migrate-v10-to-v11-gates.sh             # BD-101 NEW
```

`git rev-parse HEAD` is unchanged from session start (`735c152`).
No commits made (per pack-coder discipline). Pack Chat applies the
diff and commits.
