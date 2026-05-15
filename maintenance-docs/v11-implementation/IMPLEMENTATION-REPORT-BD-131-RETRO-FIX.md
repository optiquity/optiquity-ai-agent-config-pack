# IMPLEMENTATION-REPORT-BD-131-RETRO-FIX

Retroactive review-fix for BD-131 ("Set `forward_complete = true` at
end of clean forward migration; document partial-create vs
partial-close semantics") per `PACK-REVIEW-BD-131-RETRO.md`. Part of
Batch 21c. Original BD-131 ship was commit `c566c20`; this fix lands
on top of HEAD `8014186` (Pack Chat will commit; agents do not).

## Branch + HEAD

- **Branch:** `v11-dev`
- **Base HEAD at start (pre-fix):** `304078f3d88aa48d763dd8e5c4b3d41917076640`
- **Worktree status at start:** clean for BD-131 surface; concurrent
  coders' edits visible in `git status` (BD-078 / BD-095 / BD-129 /
  BD-130 territory) but untouched by this session.
- **Final HEAD on this worktree:** `304078f3d88aa48d763dd8e5c4b3d41917076640`
  (no commits made; pack-coder agents never commit per pack workflow).
  The two BD-131 retro edits live as uncommitted working-tree changes
  for Pack Chat to stage + commit.

## Scope

Per the prompt, in-scope findings are F1–F5 from
`PACK-REVIEW-BD-131-RETRO.md`. F6 (`forward_complete = true` lingers
across `disable`) is OUT-OF-SCOPE; see §5 below.

| Finding | Severity | Disposition |
|---------|----------|-------------|
| F1 — resume-then-completes integration test missing | SHOULD | FIXED (Group 5.4 added) |
| F2 — `creation_ok=0` is dead code on current control flow | NIT | ACCEPTED AS-IS (reviewer's option 1) |
| F3 — phase-create early-return leaks `partial_failures` tempfile | NIT | FIXED (mirror cleanup line) |
| F4 — writer rc=1 not checked by orchestrator | NIT | FIXED (option 1: orchestrator checks rc) |
| F5 — `output_c` captured but unused in test 5.3 | NIT | FIXED (assert added) |
| F6 — post-`disable` `forward_complete = true` lingers | OUT-OF-SCOPE | DEFERRED (see §5) |

## Per-task summary

### F1 (SHOULD) — Group 5.4 resume-then-completes integration test

- **File:** `scripts/tests/tracker-migrate-forward-test.sh`
- **Touch:** +208 lines (new test block inserted between Group 5.3
  cleanup and Group 6 header).
- **Test name:** `5.4 BD-131 retro F1 — resume-then-completes flips forward_complete to "true"`
- **Assertion structure (sequence pinned by reviewer's suggested fix):**
  1. `5.4 phase-1 partial-create run rc=1` — fake gh fails on the
     4th `issue create` (mirrors 5.3's failure mode).
  2. `5.4 phase-1 forward_complete stays 'false'` — confirms step 11
     was not reached on the partial run.
  3. `5.4 phase-1 checkpoint persisted (resume seed)` — checkpoint
     file exists for phase 2 to consume. `TMF_CHECKPOINT_INTERVAL=2`
     override drives this (default 25 would not write before failure
     at idx=3).
  4. `5.4 phase-1 tracker_mode() → flat-file` — V1 §3.2 / D-5
     composition contract holds at the partial state.
  5. `5.4 phase-2 resume run rc=0` — load-bearing: resume must
     succeed end-to-end with the all-success fake gh. No partial-write
     surface.
  6. `5.4 BD-131 phase-2 resume flips forward_complete to 'true'` —
     **the load-bearing assertion**. A future regression that resets
     `creation_ok=0` inside the resume skip arm — or rebuilds
     `completed_pack_ids` from the mapping without driving step 11 —
     would fail here.
  7. `5.4 phase-2 resume writes last_forward_run` — confirms step 11
     ran (the partial run never reached step 11, so absence-then-presence
     is a clean signal).
  8. `5.4 phase-2 tracker_mode() → tracker` — user-visible recovery
     contract for BD-131.
  9. `5.4 phase-2 checkpoint cleared after resume success` — confirms
     `tmf_checkpoint_clear` ran (composition with BD-065 cadence
     and BD-132 stabilization-conditional clear).
  10. `5.4 phase-2 mapping has 7 entries (5 BACKLOG + 2 phases)` —
      confirms the create surface is fully complete after resume.
- **Implementation notes:**
  - Two distinct fake-gh binaries (`FAKE_BIN_R1` = fail-on-4th-create,
    `FAKE_BIN_R2` = always-succeed). Splitting the binaries makes the
    swap explicit and avoids state-mutation tricks.
  - Phase 2 fake gh continues the gh-id sequence at 4 (phase 1 emitted
    ids 1–3 successfully, attempt-4 failed); this avoids id collisions
    in the partial mapping.
  - `TMF_CHECKPOINT_INTERVAL=2` is exported and lib re-sourced (matching
    the 4.6 cadence-test pattern at lines 752–756). Restored to default
    after the test block via `unset` + re-source so later groups (6+)
    use the default cadence.
  - Phase 2 fake gh implements the BD-132 F-7 `CLOSED_IDS` tracking +
    `issue list --state closed` python helper (matching the 4.6 / 4.4
    pattern) so the step 8.5 stabilization poll completes cleanly.
    Without this the resume run would sit in stabilization-timeout
    territory and the checkpoint-cleared assertion would fail.

### F2 (NIT) — `creation_ok=0` is dead code

- **Disposition:** ACCEPTED AS-IS per reviewer's recommendation
  (option 1 in `PACK-REVIEW-BD-131-RETRO.md` lines 244–260).
- **Rationale:** The dual-pin "future-proof" pattern is sound
  defense-in-depth. The existing comments at lines 822–825 (entry
  arm) and 876 (phase arm) already document the future-proof intent.
  Group 5.1's direct-writer-with-"false" tests jointly form a
  proof-by-composition with the existing comments. Adding a
  monkey-patch test that overrides the `return 1` to validate the
  future-proof claim end-to-end would be costly for low payoff.
- **No code change.** The reviewer's NIT is documentation-grade — this
  report carries the disposition forward.

### F3 (NIT) — Phase-create early-return tempfile leak

- **File:** `scripts/lib/tracker-migrate-forward.sh`
- **Touch:** +5 lines at line 877 (after `creation_ok=0`, before
  `return 1`).
- **Change:** Inserted `rm -f "$partial_failures"` with a comment
  explaining the F3 rationale. Now the phase-create early-return path
  matches the entry-create early-return path (line 827 cleanup) byte-
  for-byte modulo the comment.
- **Verification:** `grep -n 'rm -f.*partial_failures'
  scripts/lib/tracker-migrate-forward.sh` shows 4 cleanup sites:
  - 827 (entry-create early-return) — pre-existing
  - 882 (phase-create early-return) — **NEW (F3 fix)**
  - 1270 (partial-write-then-emit late cleanup) — pre-existing
  - 1276 (clean-success late cleanup) — pre-existing
- **Why no test:** The reviewer noted that asserting `$TMPDIR/tmf-pf.*`
  is empty after a phase-create-fail run is possible but non-trivial
  (requires setting up a fake gh that fails on phase epic creation,
  not BACKLOG entry creation; and asserting on the tempdir is racy
  if other tests in parallel use the same `tmf-pf.` prefix). The
  fix is a 1-line mirror of an already-tested cleanup pattern; the
  payoff of a dedicated test is low. If desired, a follow-up could
  hoist the cleanup into a `trap "rm -f \$partial_failures" RETURN`
  guard so neither early-return needs to remember.

### F4 (NIT) — Writer rc=1 not checked by orchestrator

- **File:** `scripts/lib/tracker-migrate-forward.sh`
- **Touch:** +12 / −1 lines at line 1215 (replaces the bare
  `_tmf_update_tracker_toml "$cfg_path" "$fc_value"` call).
- **Change selected:** Reviewer's option 1 (orchestrator checks
  the writer's rc and emits a clearer follow-up WARN).
- **Why option 1 over option 2:** Option 2 (relax the writer to
  rc=0-with-warn) would weaken test 5.1c's `assert_contains "5.1c
  writer rejects unexpected value with stderr WARN"` semantics for
  direct-callers of the writer (e.g., a future tracker-doctor or
  init-time path). Option 1 keeps the writer's defensive contract
  intact AND closes the orchestrator-level gap. Both paths surface
  the rejection on stderr; option 1 surfaces it twice (writer's
  WARN + orchestrator's follow-up WARN) which is the safer
  defense-in-depth posture.
- **Why no dedicated test:** As the reviewer noted, the orchestrator's
  own conditional at lines 1215–1219 only ever passes "true" or
  "false" — so the F4 branch is unreachable from in-tree control flow
  today. Asserting on it would require a function-override hack
  (similar to F2's option 2 in the review). The follow-up WARN is
  the user-visible safety net; if a future refactor opens the gap,
  the WARN on stderr is the operator's first signal. The verifier
  helper (`_tmf_verify_forward_complete`, group 5.2) is the existing
  defense-in-depth layer for the on-disk read-back; F4 closes the
  symmetric gap on the writer-call side.

### F5 (NIT) — `output_c` captured but unused

- **File:** `scripts/tests/tracker-migrate-forward-test.sh`
- **Touch:** +8 lines at line 963 (between rc=1 assert and
  forward_complete=false assert).
- **Change:** Added `assert_contains "5.3 partial-create run surfaces
  propagated provider_create error" "$output_c" "validation failed"`.
  This mirrors 4.3's pattern (which uses `output_pf` for three
  asserts).
- **Why this assertion:** The fake gh emits `HTTP 422: validation
  failed` on the 4th create (line 923 of the test fixture). Asserting
  the orchestrator's captured stderr contains `validation failed`
  pins down two contracts simultaneously:
  1. The orchestrator surfaces the provider error (doesn't silently
     swallow it).
  2. `output_c` is now load-bearing rather than dead — preventing
     accidental future deletion of the assignment.

## Verification

### Syntax checks

```
$ bash -n scripts/lib/tracker-migrate-forward.sh
syntax OK

$ bash -n scripts/tests/tracker-migrate-forward-test.sh
syntax OK
```

### Test run results

Baseline (pre-fix): **134 passed / 0 failed**.

Post-fix: **145 passed / 0 failed** (+11 = 1 F5 + 10 Group 5.4).

Selected output (Group 5 only):

```
=== Group 5: BD-131 forward_complete write semantics ===
  PASS 5.1 writer with 'true' flips forward_complete=true
  PASS 5.1 writer with 'true' adds last_forward_run
  PASS 5.1 writer with 'false' sets forward_complete=false
  PASS 5.1b writer omitted-arg defaults to 'true'
  PASS 5.1c writer rejects unexpected value with stderr WARN
  PASS 5.1c rejected write leaves forward_complete unchanged
  PASS 5.2 verify match → rc=0
  PASS 5.2 verify mismatch → rc=1
  PASS 5.2 verify mismatch emits stderr WARN
  PASS 5.2b verify on missing cfg → rc=0 (no-op)
  PASS 5.3 fixture starts forward_complete=false
  PASS 5.3 partial-create run rc=1
  PASS 5.3 partial-create run surfaces propagated provider_create error  ← F5 NEW
  PASS 5.3 BD-131 forward_complete stays 'false' on partial-create
  PASS 5.3 partial-create mapping persisted (resume seed)
  PASS 5.4 phase-1 partial-create run rc=1                                 ← F1 NEW
  PASS 5.4 phase-1 forward_complete stays 'false'                          ← F1 NEW
  PASS 5.4 phase-1 checkpoint persisted (resume seed)                      ← F1 NEW
  PASS 5.4 phase-1 tracker_mode() → flat-file                              ← F1 NEW
  PASS 5.4 phase-2 resume run rc=0                                         ← F1 NEW
  PASS 5.4 BD-131 phase-2 resume flips forward_complete to 'true'          ← F1 NEW
  PASS 5.4 phase-2 resume writes last_forward_run                          ← F1 NEW
  PASS 5.4 phase-2 tracker_mode() → tracker                                ← F1 NEW
  PASS 5.4 phase-2 checkpoint cleared after resume success                 ← F1 NEW
  PASS 5.4 phase-2 mapping has 7 entries (5 BACKLOG + 2 phases)            ← F1 NEW
```

Full summary line: `Passed: 145, Failed: 0, All tests passed.`

### F3 cleanup symmetry confirmation

```
$ grep -n 'rm -f.*partial_failures' scripts/lib/tracker-migrate-forward.sh
827:                    rm -f "$partial_failures"   ← entry-create early-return (pre-existing)
882:            rm -f "$partial_failures"           ← phase-create early-return (NEW F3 fix)
1270:        rm -f "$partial_failures"              ← partial-write-then-emit late cleanup (pre-existing)
1276:    rm -f "$partial_failures"                  ← clean-success late cleanup (pre-existing)
```

Both early-return paths now have symmetric tempfile cleanup before
`return 1`.

### F4 orchestrator check confirmation

`scripts/lib/tracker-migrate-forward.sh` lines 1230–1232:

```bash
if ! _tmf_update_tracker_toml "$cfg_path" "$fc_value"; then
    echo "forward: WARN: tracker.toml writer rejected forward_complete value '$fc_value' — see writer WARN above; tracker_mode() will resolve to flat-file until init is re-run" >&2
fi
```

The previous `_tmf_update_tracker_toml "$cfg_path" "$fc_value"` bare
call was replaced.

## Files changed

| Path | Change type | Lines added | Lines removed |
|------|-------------|-------------|---------------|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +18 | −1 |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +216 | 0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-131-RETRO-FIX.md` | new | (this file) | 0 |

`git diff --numstat` (BD-131 retro surface only — concurrent coders'
edits not shown):

```
18      1       scripts/lib/tracker-migrate-forward.sh
216     0       scripts/tests/tracker-migrate-forward-test.sh
```

## Plan deviations

None. F1 was implemented as suggested by the reviewer (Group 5.4,
mirroring the 5.3 / 4.3 / 4.6 patterns). F3 was the 1-line cleanup
mirror as recommended. F4 chose option 1 (orchestrator checks rc) over
option 2 (relax writer to rc=0-with-warn); the rationale is documented
in the per-task block above (preserves test 5.1c semantics for
direct-callers). F5 used the reviewer's suggested needle (`validation
failed`).

## New POQs introduced

None. Two soft observations surfaced during implementation, neither
warranting a new POQ:

1. **`partial_failures` cleanup ergonomics.** The current 4-cleanup-site
   pattern (2 early-returns + 2 late paths) could be hoisted to a
   single `trap "rm -f \$partial_failures" RETURN` guard. This would
   make both F3-class regressions impossible. Out of scope for BD-131
   retro-fix; logged here for any future refactor.
2. **`creation_ok=0` future-proof claim is unverified.** F2's NIT
   stands as documentation. If anyone ever wants to add a unit-test
   layer that exercises the "creation_ok=0 set AND step 11 reached"
   branch, the cleanest shape is a function-override harness
   (`tracker_migrate_forward_run_no_early_return` mock). Not a POQ
   — just a known gap in the future-proof claim's test coverage.

## §5 — F6 (out-of-scope) deferred-work tracking

**F6 is OUT-OF-SCOPE for this retro-fix per the reviewer's
classification** (`PACK-REVIEW-BD-131-RETRO.md` lines 396–456,
severity NIT, touch-point class ADJACENT, and the explicit
"out-of-scope observation; logged for follow-up consideration, not a
BD-131-introduced issue" tag at line 399).

**Summary of F6 for Pack Chat's deferred-work backlog:**
- After `pack tracker disable` (which flips `mode.state = "flat-file"`
  via `_tmr_update_tracker_toml`), `migration.forward_complete = true`
  lingers in `tracker.toml` because the reverse path doesn't touch it.
- `tracker_mode()` correctly returns `"flat-file"` because of the
  state check (tracker-config.sh:201–204), so this is benign in the
  v11.0 surface.
- The lingering `true` becomes a hazard only if a future
  `pack tracker enable` verb (or a manual `state = "tracker"` edit)
  is added without re-validating the mapping.
- **Reviewer's recommended dispositions** (verbatim from review):
  1. Document the invariant in `MIGRATION-v10-to-v11.md` near line
     327 or in V1 §6.5's reverse spec ("Reverse leaves
     `forward_complete` unchanged. The supported re-enable path is
     `pack tracker init`, which rewrites both flags atomically.")
  2. Defer to a future BD if/when `pack tracker enable` is introduced.

**Pack Chat decision required:** route F6 to a new BD entry, fold it
into the existing reverse / disable BD scope, or accept as
known-benign for v11.0 with a documentation-only fix in
`MIGRATION-v10-to-v11.md`. The choice is non-blocking for BD-131
retro closure.

This pack-coder agent did NOT touch `tracker.toml`-write semantics on
the reverse path (`scripts/lib/tracker-migrate-reverse.sh` is BD-133
territory and explicitly listed as off-limits in the prompt's "Files
you must NOT touch" section).

## Definition-of-Done checklist

| Item | Status | Evidence |
|------|--------|----------|
| F1 implemented (resume-then-completes integration test) | PASS | Group 5.4 added; 10 new asserts; all pass |
| F2 disposition documented (accept-as-is) | PASS | Per-task block + reviewer's option 1 cited |
| F3 implemented (phase-create tempfile cleanup) | PASS | Line 882 mirror of line 827; grep shows symmetric pattern |
| F4 implemented (writer rc=1 surfaced at orchestrator) | PASS | Lines 1230–1232; option 1 selected with rationale |
| F5 implemented (`output_c` assertion added) | PASS | Line 963; uses reviewer's suggested needle |
| F6 documented as out-of-scope | PASS | §5 above with reviewer's dispositions surfaced for Pack Chat |
| `bash -n` clean on both edited files | PASS | Both syntax checks shown above |
| Existing test suite still green | PASS | 134 → 145 (+11), 0 failures |
| No edits outside BD-131 retro scope | PASS | `git diff` for the two files only shows F1+F3+F4+F5 changes; no BD-133 surface touched |
| No PM-only file edits (`BACKLOG.md`, `CHANGELOG.md`, etc.) | PASS | None modified |
| No state-changing git verbs run | PASS | Only `git rev-parse`, `git status`, `git diff` invoked |
| Trinity files untouched | PASS | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` not modified |
| Concurrent coders' files untouched (BD-078, BD-095, BD-129, BD-130) | PASS | Status output shows their edits as pre-existing; my session left them alone |
| New report file created | PASS | This file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-131-RETRO-FIX.md` |

End of report.
