# PACK-REVIEW-BD-131-RETRO

Retroactive per-BD review of BD-131 ("Set `forward_complete = true`
at end of clean forward migration; document partial-create vs
partial-close semantics"), part of Batch 21c per the 2026-05-15
review/fix cycle revision.

## Scope

- **BD:** BD-131
- **Original commit:** `c566c20` (2026-05-09) — combined BD-131 +
  BD-133 ship.
- **In-scope files (BD-131 portion only, per `git show c566c20`
  and the prompt's scope anchor):**
  - `scripts/lib/tracker-migrate-forward.sh` (+102 / −9 BD-131
    portion: `creation_ok` flag in `tracker_migrate_forward_run`,
    `fc` arg + defensive validation on `_tmf_update_tracker_toml`,
    NEW `_tmf_verify_forward_complete` helper, header docstring
    update).
  - `scripts/tests/tracker-migrate-forward-test.sh` (+202 / −0 BD-131
    portion: Group 4.3 partial-close addition (+1 assert), NEW
    Group 5 with 14 asserts in sub-groups 5.1 / 5.2 / 5.3).
  - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-131.md`
    (NEW; now at `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-131.md`
    after Pattern B sweep).
- **Out-of-scope (BD-133 portion of the same commit):**
  - `scripts/lib/tracker-header-snapshot.sh` (NEW).
  - `scripts/lib/tracker-migrate-reverse.sh` (header-snapshot
    wiring).
  - `scripts/tests/tracker-bd133-header-preservation-test.sh` (NEW).
  - Any BD-133-only assertions in `tracker-migrate-forward-test.sh`
    (header-snapshot wiring on the forward side).
- **Snapshot judged:** state of in-scope files AT commit `c566c20`,
  cross-referenced against current HEAD (`8014186`) where the
  changes still live untouched. No drift between `c566c20` and
  current HEAD inside the BD-131 surface.

## Methodology

- Read `BACKLOG.md` BD-131 entry (problem, acceptance criteria,
  File/Symbol, semantics question about partial-CLOSE vs partial-CREATE).
- Read `IMPLEMENTATION-REPORT-BD-131.md` (claimed deliverables +
  DoD checklist).
- Read `git show c566c20 -- scripts/lib/tracker-migrate-forward.sh`
  and `... -- scripts/tests/tracker-migrate-forward-test.sh` and
  filtered out the BD-133 portions (header-snapshot capture/apply
  calls + sidecar wiring).
- Read current state of `scripts/lib/tracker-migrate-forward.sh`
  (lines 753–761, 821–828, 875–879, 1198–1229, 1580–1666,
  1677–1690) to confirm no drift since `c566c20`.
- Read `scripts/lib/tracker-config.sh::tracker_mode` (lines 187–210)
  and `tracker_config_get` (lines 162–177) to validate that the
  verifier's read-back path returns the JSON-stringified `"true"`
  / `"false"` that the comparison expects.
- Empirically confirmed the verifier behavior on three TOMLs
  (forward_complete=true / =false / absent) via a sandbox invocation
  outside the test suite. Result: verifier returns the strings
  `true` / `false` / `<empty>` respectively, matching the orchestrator's
  expectations.
- Inspected sibling writers (`scripts/lib/tracker-init.sh` line 368
  init-time write; `scripts/lib/tracker-migrate-reverse.sh::_tmr_update_tracker_toml`)
  to confirm BD-131 didn't break their contracts.
- Greppped repo for `forward_complete`, `tracker_mode`, `BD-131` to
  identify cross-cutting touch points (`validate-pack.py` line 2249,
  `supporting-docs/MIGRATION-v10-to-v11.md` line 327,
  `maintenance-docs/v11-research/ARCHITECTURE.md` lines 519, 544,
  1937).
- Applied the 6 review dimensions and touch-point classification
  from `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`, with the
  prompt's risk-surface weighting (round-trip safety, idempotency,
  failure-mode coverage, composition with existing forward stages,
  state-file lifecycle).
- Did NOT read any `PACK-REVIEW-*.md` per the prompt.

## What the implementation got right

- **Contract codification.** Before BD-131, the writer was correct
  for the clean-create case by accident — it depended on the call
  site only being reachable when all creates succeeded. BD-131
  makes the contract explicit at three layers: orchestrator
  (`creation_ok` flag set on both early-return paths), writer
  (positional `fc` arg with defensive validation that rejects
  anything other than `"true"` / `"false"`), and read-back verifier
  (defense-in-depth WARN if the on-disk value disagrees with the
  written value). The verifier's mismatch arm even catches the
  "python3 missing on PATH" scenario the implementation report
  hypothesised as the source of the original BD-102 Phase A
  failure surface.
- **Semantics aligned with V1 §3.2 / D-5.** `forward_complete = true`
  iff the create surface is complete. Partial-CLOSE → `true`
  (delegated to BD-134's retry sweep). Partial-CREATE → early-return
  → step 11 never runs → `false` persists from init-time. This is
  exactly what the BD entry recommended (Resolution line: "set
  `forward_complete = true` at end of clean forward; recommend
  'all issues created' over 'all closes succeeded' since BD-134
  eliminates the close-failure case anyway"). No deviation.
- **Test asymmetry between partial-CLOSE and partial-CREATE.**
  Group 4.3's BD-131 add (`forward_complete = true` after
  partial-close) and Group 5.3 (`forward_complete = false` after
  partial-create rc=1) are mirror-image asserts that pin down both
  arms of the semantics contract simultaneously. The fixture-state
  pre-assertion in 5.3 (`5.3 fixture starts forward_complete=false`)
  is the right defensive pattern — it proves the post-test "false"
  state is the writer-didn't-flip case, not the writer-never-ran
  case.
- **Writer round-trip + value-rejection coverage.** Group 5.1's
  three asserts (writer with `"true"`, writer with `"false"`,
  default-arg behavior, then 5.1c's "yes" rejection + state
  preservation) exercise every meaningful branch of the writer's
  arg path.
- **Verifier helper has its own group.** Group 5.2 covers the
  match / mismatch / missing-cfg trio without entangling with the
  full integration path. This is the right unit-test granularity
  for a small defensive helper.
- **No PM-only files touched.** Implementation report's DoD
  checklist confirms `BACKLOG.md`, `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`,
  README untouched. Verified — `git show c566c20 --stat` shows
  only the two BD-131 source files + the BD-131 report were
  modified by BD-131 (the `BACKLOG.md` change in the same commit
  is the status flip on the BD-131 + BD-133 entries, which is the
  Pack Chat commit, not the pack-coder agent).
- **Backward compatibility at the writer.** The new `fc` arg
  defaults to `"true"` (line 1610), preserving every pre-BD-131
  call site's behavior. Asserted by 5.1b.
- **Read-back failure does NOT abort.** Line 1222
  `_tmf_verify_forward_complete "$cfg_path" "$fc_value" || true`
  intentionally swallows the rc=1 — the mapping + closes already
  landed, so a verifier failure is an operator-facing WARN, not a
  hard fail that would surprise the user with a non-zero exit after
  what is otherwise a successful migration. Correct call.

## Findings

### F1 — Resume scenario for `forward_complete = false → true` has no integration test

- **Severity:** SHOULD
- **Dimension:** (b) implicit expectations / unsurfaced
  invariants — the resume path is the documented recovery verb
  for partial-create failures, but its `forward_complete`
  transition is not asserted end-to-end.
- **Touch-point class:** OWNED (BD-131 is the BD that introduces
  the `creation_ok` invariant; resume-then-completes is the
  documented happy-path recovery for the `false` state the BD
  introduces).
- **Evidence:**
  - `BACKLOG.md` BD-131 Resolved-line guarantees: "Any create
    failure (entry or phase epic) early-returns at the create
    site so step 11 never runs and `forward_complete` stays at
    the init-time `false`."
  - `IMPLEMENTATION-REPORT-BD-131.md` lines 113–117 reference
    `pack tracker init --resume` as the recovery path: "`false`
    keeps the operator on flat-file until a re-run (`pack tracker
    init --resume`) completes the create surface."
  - `scripts/lib/tracker-migrate-forward.sh` lines 719–722 (resume
    state load), 766–768 (completed_pack_ids seed), 777–781
    (per-entry skip-already-completed branch). The orchestrator
    correctly skips entries whose `pack_id` is in
    `resume_state.completed_pack_ids` — those entries do NOT go
    through the `case … create)` arm and therefore do NOT touch
    `creation_ok`. Reaching the bottom with all remaining entries
    completed → `creation_ok=1` → step 11 writes `true`.
  - `scripts/tests/tracker-migrate-forward-test.sh` greps for
    "resume" → only line 519 (assertion that the partial-write
    error message contains the substring "resume options") and
    lines 973–974 (the 5.3 "resume seed" mapping-persistence
    assertion). No test calls `tracker_migrate_forward_run …
    1` (the resume=1 form) and verifies the `forward_complete`
    transition.
- **Description:** The resume path is the recovery contract for
  the new `forward_complete = false` state BD-131 introduces. A
  reasonable refactor — e.g., resetting `creation_ok=1` to `0`
  inside the resume branch's skip arm, or rebuilding
  `completed_pack_ids` from the mapping rather than the checkpoint
  — could quietly regress the resume → flip-to-true semantics
  without breaking any existing assertion. Today the resume +
  partial-create-then-resume-completes scenario is exercised only
  by Group 4.6 (`4.6 forward with cadence=2 rc=0` at line 767),
  which runs forward once with mid-run checkpointing but never
  validates `forward_complete` value. Test 4.6 was added for the
  BD-065 checkpoint cadence, not for BD-131's `creation_ok` flag.
- **Suggested fix:** Add a Group 5.4 test ("BD-131 resume flips
  forward_complete after completed re-run"). Sequence:
  1. Create a fake gh that fails on the 4th `issue create`.
  2. Run forward; assert rc=1 + `forward_complete = false` (the
     5.3 sequence — could share the fake gh fixture by parameter).
  3. Swap to a fake gh that succeeds on every create.
  4. Run `tracker_migrate_forward_run "$REPO" 0 1` (resume=1).
  5. Assert rc=0 + `forward_complete = true` on disk.
  6. Assert `last_forward_run` was updated to a newer ISO8601 than
     the partial-create run captured.
  This adds ~30 lines and 3–4 asserts. The test would fail
  immediately if anyone regresses the resume path's interaction
  with `creation_ok`. Cost is low; the recovery contract is the
  user-facing recovery story, so coverage is high-value.
- **Cross-concept impact:** None for BD-131 surface. The resume
  test would also incidentally exercise BD-065's checkpoint
  clear-on-success branch (line 1228 `tmf_checkpoint_clear`), but
  that's not BD-131 scope.
- **Rule/principle violated:** Design best practice #6
  (idempotency for orchestration verbs — re-running on
  already-applied state is no-op or replay-safe). BD-131's
  contract claims this property for the resume path; lack of a
  test for the post-recovery state lets a future regression
  silently break it.

### F2 — `creation_ok=0` is dead code on the current control flow; "future-proof" claim is unverified

- **Severity:** NIT
- **Dimension:** (a) within-BD correctness (paired-statement coverage).
- **Touch-point class:** OWNED.
- **Evidence:**
  - `scripts/lib/tracker-migrate-forward.sh` line 826
    (`creation_ok=0` at entry-create early-return) is followed
    immediately by lines 827–828 (`rm -f "$partial_failures"`,
    `return 1`). The assignment has no observable effect — the
    function returns before step 11 reads `creation_ok`.
  - `scripts/lib/tracker-migrate-forward.sh` line 877
    (`creation_ok=0` at phase-create early-return) is followed
    immediately by line 878 (`return 1`). Same story.
  - `scripts/lib/tracker-migrate-forward.sh` lines 753–761 (the
    comment block) and lines 1199–1207 (the step 11 comment) are
    explicit about this: "Set to 0 immediately before any
    provider_create early-return so step 11's tracker.toml writer
    can pass the right value to `forward_complete`. […] BD-131:
    mark creation surface incomplete so any future refactor that
    elects to continue past a create failure (instead of
    early-return) routes through step 11 with the right
    semantics."
  - Test 5.3 verifies the early-return → step 11 not reached →
    init-time `false` persists path. No test verifies the
    "creation_ok=0 set AND step 11 reached" branch — because the
    current code path makes it unreachable.
- **Description:** The dual-pin "future-proof" pattern is sound in
  principle (an invariant that becomes useful the moment someone
  removes the early-return is cheap to set up now), but as a
  contract claim it's unverified. If a future refactor removes
  the `return 1` at line 828 to "continue past failure to collect
  more entries", the step 11 `false` branch would fire — but is
  the code in step 11 + the writer correct for that case? Yes,
  per inspection of lines 1210–1215 (`fc_value` computed from
  `creation_ok`, then writer called with that value) and the
  Group 5.1 direct-writer-with-"false" tests. So the future-proof
  claim is honest — it just isn't end-to-end tested.
- **Suggested fix (none blocking):** This is genuinely a NIT.
  Three options if any improvement is wanted:
  1. Accept as-is. The future-proof comment + the direct-writer
     "false" tests in 5.1 jointly form a proof-by-composition; the
     missing integration test is OK because there's no current
     control flow that exercises it.
  2. Add a hook-based test that monkey-patches the orchestrator
     to skip the `return 1` at line 828, then asserts step 11
     reaches the false branch. Costly (requires shell function
     overriding) for low payoff.
  3. Delete the `creation_ok=0` lines and rely on the early-return
     as the sole semantics carrier. This removes the future-proof
     pattern; cost is that any future refactor that removes the
     early-return without also updating step 11 would silently
     break the contract. Net loss; do not do this.
  Recommendation: accept as-is (option 1). Document this finding
  for awareness; no fix required.
- **Cross-concept impact:** None.
- **Rule/principle violated:** None; the pattern is correct
  defense-in-depth. Listed here only because the prompt asks for
  every finding regardless of severity.

### F3 — Phase-create early-return leaks `partial_failures` tempfile (pre-existing; BD-131 inserted `creation_ok=0` in the same window without fixing the leak)

- **Severity:** NIT
- **Dimension:** (a) within-BD correctness; (c) touch points —
  pre-existing bug in the file BD-131 was actively editing.
- **Touch-point class:** ENCROACHED. The bug pre-dates BD-131
  (was present before c566c20), but BD-131 touched lines 875–879
  to insert `creation_ok=0` and could have noticed the asymmetry.
- **Evidence:**
  - Entry-create early-return (`tracker-migrate-forward.sh` lines
    821–829): `creation_ok=0` THEN `rm -f "$partial_failures"`
    THEN `return 1`. Tempfile cleaned up.
  - Phase-create early-return (`tracker-migrate-forward.sh` lines
    875–879): `creation_ok=0` THEN `return 1`. No `rm -f` for
    `$partial_failures`. The tempfile leaks.
  - The tempfile is created at line 750
    (`partial_failures=$(mktemp -t tmf-pf.XXXXXX)`) before either
    early-return.
- **Description:** A real (but tiny) tempfile leak in
  `/var/folders/.../tmf-pf.XXXXXX` when phase creation fails. The
  leak is mostly invisible — the OS GCs tempfiles eventually, the
  forward run is already failing so the operator's attention is
  elsewhere, and the phase-create failure is a rare case (phase
  epics are typically a much smaller cardinality than BACKLOG
  entries). But it IS an asymmetry vs the entry-create path, and
  BD-131 touched these lines.
- **Suggested fix:** Add `rm -f "$partial_failures"` between
  lines 877 and 878:
  ```bash
  if ! phase_result=$(provider_create "$phase_payload"); then
      # BD-131: see paired creation_ok comment above.
      creation_ok=0
      rm -f "$partial_failures"  # mirror the entry-create cleanup
      return 1
  fi
  ```
  Two lines, no behavior change beyond tempfile cleanup. If
  desired, add a tiny test asserting that
  `$TMPDIR/tmf-pf.*` is empty after a phase-create-fail run.
  Alternatively, hoist the tempfile creation into a trap-EXIT
  guard so neither early-return needs to remember the cleanup;
  that's a bigger refactor and out of BD-131 scope.
- **Cross-concept impact:** None — purely local cleanup.
- **Rule/principle violated:** Not a stated principle, but the
  "paired statements" coding hygiene (every `mktemp` paired with
  a guaranteed `rm -f` or trap) is generally respected in the
  rest of the file (see lines 1098–1099 for `failed_closes` paired
  with `rm -f "$failed_closes"` at line 1163, and lines 1026–1028
  for `pt_err` paired with `rm -f "$pt_err"` at line 1028 and
  1079).

### F4 — Writer's rc=1 on invalid `fc` value is not checked by the orchestrator

- **Severity:** NIT
- **Dimension:** (a) within-BD correctness — internal API contract
  inconsistency.
- **Touch-point class:** OWNED.
- **Evidence:**
  - `_tmf_update_tracker_toml` (lines 1608–1620) returns rc=1
    with a stderr WARN when `fc` is not `"true"` / `"false"`.
    This is the defensive-validation arm; the orchestrator owns
    both callsites.
  - Step 11 invocation at line 1215:
    `_tmf_update_tracker_toml "$cfg_path" "$fc_value"`. The
    return code is not captured or checked. If the writer rejects
    `fc_value`, the orchestrator silently continues.
  - Line 1222: `_tmf_verify_forward_complete "$cfg_path"
    "$fc_value" || true`. The verifier reads back the OLD value
    (e.g., init-time `false`), mismatches the expected
    `"true"` (or `"false"` depending on `creation_ok`), emits
    WARN, returns rc=1, but the `|| true` swallows it. The user
    sees a verifier WARN but no writer WARN unless they read
    stderr carefully — both WARNs are stderr, but the writer's
    message ("refusing to write unexpected forward_complete value
    'X'") is more informative than the verifier's ("read-back
    mismatch").
- **Description:** In practice this branch is unreachable from
  the orchestrator's own conditional — `fc_value` is set to
  exactly `"true"` or `"false"` by the `if [[ "$creation_ok" ==
  "1" ]]` block at lines 1209–1214. So the defensive-validation
  arm only fires for out-of-tree callers (or a future
  control-flow bug). Still, the defensive-validation chose to
  return rc=1 instead of `set -e` style termination, and the
  orchestrator ignores the rc — that's an inconsistency between
  "defensive at the callee" and "permissive at the caller".
- **Suggested fix:** Two equally-acceptable shapes; pick whichever
  fits style preferences:
  1. Check the writer's rc and emit a clearer error:
     ```bash
     if ! _tmf_update_tracker_toml "$cfg_path" "$fc_value"; then
         echo "forward: WARN: tracker.toml writer rejected forward_complete value '$fc_value' — see writer WARN above" >&2
     fi
     ```
  2. Convert the writer's defensive-rejection from rc=1-with-warn
     to rc=0-with-warn (matching the verifier's "warn but continue"
     pattern), since the orchestrator already implicitly treats it
     that way. This is the smaller code change.
  Both are NITs; the current behavior is fine in practice.
- **Cross-concept impact:** None.
- **Rule/principle violated:** Not a stated principle; an
  internal-API consistency concern.

### F5 — Test 5.3 captures `output_c` but never asserts on it

- **Severity:** NIT
- **Dimension:** (a) within-BD correctness — test hygiene.
- **Touch-point class:** OWNED.
- **Evidence:** `scripts/tests/tracker-migrate-forward-test.sh`
  line 955: `output_c=$(tracker_migrate_forward_run "$TEST_REPO_C"
  0 0 2>&1)`. Grep for `output_c` returns exactly one match —
  the assignment. The variable is never `assert_contains`-ed or
  examined.
- **Description:** Dead variable assignment. The 4.3 sibling
  block at lines 502–519 captures `output_pf` and uses it for
  three asserts (`4.3 surfaces ERROR: partial-write`, `4.3
  partial-write names step-8 close`, `4.3 partial-write next-step
  verb`). Test 5.3 captures `output_c` similarly but never asserts
  on it — likely a copy-paste leftover from the 4.3 template.
- **Suggested fix:** Either delete the assignment and write
  `tracker_migrate_forward_run "$TEST_REPO_C" 0 0 >/dev/null 2>&1
  ; rc_c=$?`, or add an assert on `output_c`. The natural assert
  would mirror 4.3 — e.g., `assert_contains "5.3 partial-create
  run surfaces propagated provider_create error" "$output_c"
  "validation failed"` (the fake gh emits "HTTP 422: validation
  failed" on the 4th create). That would also strengthen the test
  by confirming the orchestrator surfaces the provider error
  rather than swallowing it.
- **Cross-concept impact:** None.
- **Rule/principle violated:** None stated; test hygiene.

### F6 — Round-trip property: post-`disable` `forward_complete = true` lingers, with no documented reset path

- **Severity:** NIT (out-of-scope observation; logged for
  follow-up consideration, not a BD-131-introduced issue)
- **Dimension:** (b) implicit expectations + (d) failure-mode UX.
- **Touch-point class:** ADJACENT — observation about the
  composition between BD-131 (writes `forward_complete`) and the
  reverse / disable surface (which doesn't touch
  `forward_complete`).
- **Evidence:**
  - `scripts/lib/tracker-migrate-reverse.sh::_tmr_update_tracker_toml`
    (lines 779–821) flips `mode.state` to `"flat-file"` when
    `flip_to_flat_file=1` and writes `last_reverse_run`, but does
    NOT touch `migration.forward_complete`.
  - Result: after `pack tracker disable` (flip_mode=1),
    tracker.toml has `state = "flat-file"` AND
    `forward_complete = true`. `tracker_mode()`
    correctly returns `"flat-file"` because of the state check
    (tracker-config.sh:201–204).
  - If a user later manually edits tracker.toml to flip
    `state = "tracker"` (or some future `pack tracker enable`
    verb does), `tracker_mode()` will immediately resolve to
    `"tracker"` because `forward_complete` is still `true` from
    the original forward — even though the mapping might be stale
    (entries renumbered, dropped, or the BACKLOG.md re-edited).
- **Description:** Not a BD-131 regression. BD-131 deliberately
  scoped to "after a clean forward, flip the flag"; it didn't
  promise anything about subsequent reverse/disable behavior. But
  the conceptual review prompt asks about composition with
  existing forward stages and state-file lifecycle — this
  observation falls in that bucket. The current safe re-enable
  path is `pack tracker init`, which always rewrites
  `forward_complete` from a fresh run; that's correct. There is
  no `pack tracker enable` verb today (verified via grep for
  `cmd_enable` — only `cmd_enable_recommendations` exists, which
  is a separate feature). So in practice the lingering `true` is
  benign UNTIL someone adds a re-enable verb without
  re-validating the mapping.
- **Suggested fix:** Two options:
  1. (Recommended for v11.0 — no action required.) Document the
     invariant explicitly in `MIGRATION-v10-to-v11.md` near line
     327, or in V1 §6.5's reverse spec: "Reverse leaves
     `forward_complete` unchanged. The supported re-enable path
     is `pack tracker init`, which rewrites both flags
     atomically. Manual edits of `mode.state` without a fresh
     forward run will trip `tracker_mode()` against a possibly-stale
     mapping."
  2. Defer to a future BD if/when `pack tracker enable` is
     introduced. That verb would be responsible for either
     refusing-to-enable if `last_reverse_run > last_forward_run`,
     or for re-validating the mapping before flipping state back.
  Neither fix is blocking for BD-131.
- **Cross-concept impact:** Touches BD-133 (reverse migration)
  and BD-132 (race-detection on reverse-then-forward). Both have
  shipped without addressing this — explicitly out of their scope
  too.
- **Rule/principle violated:** Design best practice #2
  (round-trip safety). The round-trip claim is "byte-identical
  flat-file" not "byte-identical tracker.toml" — so this isn't a
  V1 §6.0 violation. Soft observation only.

## Cross-cutting check (touch-point matrix)

Per `CONCEPTUAL-REVIEW-METHODOLOGY.md` checklist:

- **Trinity rule.** BD-131 did not modify any of
  `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (root or project-template).
  Implementation report DoD line "Trinity files untouched: PASS"
  is verified by `git show c566c20 --stat`.
- **Validate-pack alignment.** `scripts/validate-pack.py` line 2249
  already enforces `migration.forward_complete` is `bool` (Check
  29). BD-131 writes only `true` / `false` literals, both of which
  the pack-example schema check accepts. No CI alignment change
  needed.
- **README repository layout.** No files added, moved, or removed
  by BD-131; only two existing files modified. README untouched
  (correct).
- **MIGRATION / QUICKSTART.** `MIGRATION-v10-to-v11.md` line 327
  references the V1 §3.2 semantics generically; BD-131 doesn't
  change the user-visible contract, just makes it actually work.
  QUICKSTART.md doesn't mention `forward_complete`. No migration-doc
  update required.
- **BACKLOG accuracy.** BD-131 entry (BACKLOG.md lines 1907–1914)
  is flipped to `Resolved` with a complete Resolved-line that
  matches what was shipped. Sibling BD-134 (line 1881) accurately
  references BD-131 contract. Cross-reference is clean.
- **Maintenance-docs consistency.** `IMPLEMENTATION-REPORT-BD-131.md`
  matches the shipped code (verified line-by-line against
  `c566c20`). The DoD checklist's "after a clean forward,
  `forward_complete` reads `true`" is covered by Group 4.3's
  BD-131 add (partial-close still flips true) AND by Group 3.7b
  (clean run; verified via existing assertions referenced by the
  implementation report at line 269). Group 5.3 covers the "any
  issue-creation failure → `false`" arm. All DoD bullets are
  truthful.

## Six-dimension assessment

- **(a) Within-BD correctness:** PASS with two NITs (F2, F3, F4,
  F5). The defensive layering — orchestrator-level invariant,
  writer-level arg + validation, helper-level read-back — is
  correct. No correctness defects in any reachable code path.
- **(b) Implicit expectations:** ONE SHOULD (F1 — resume path not
  end-to-end-tested) and ONE NIT-out-of-scope (F6 — lingering
  `forward_complete = true` across disable). The resume path
  matters because the BD entry explicitly names it as the
  recovery verb for partial-create.
- **(c) Touch points / cross-concept impact:** Clean. No
  unexpected touches into BD-133 surface (header snapshot),
  BD-132 surface (race detection), BD-134 surface (close retry),
  or BD-068 surface (tracker-migrate baseline). The implementation
  report's file-overlap check (also called out in `c566c20`
  commit message) is accurate.
- **(d) Failure-mode UX:** Good. Three layers of safety net:
  defensive validation in the writer (rejects bad values),
  read-back verifier (catches silent regex regressions / missing
  python3), and the operator-facing partial-write typed error at
  the end of the run carries the resume instruction. F1 + F4 are
  the only minor concerns here.
- **(e) Design best practices:** Mostly clean. Single-source-of-truth
  for the BD-131 contract lives in `_tmf_update_tracker_toml`
  header docstring (lines 1580–1607) and is mirrored in inline
  comments at the call site (lines 1199–1207). Idempotency-on-resume
  is claimed but not tested (F1).
- **(f) Concept-specific:** None unique to BD-131 — it's a tight
  one-bug-one-fix-one-test BD with a clear contract. The semantics
  question in the BD entry (partial-CLOSE vs partial-CREATE) was
  answered correctly and consistently with BD-134.

## Severity summary

- **MUST:** 0
- **SHOULD:** 1 (F1 — add resume-then-completes integration test)
- **NIT:** 4 (F2 — dead-code observation; F3 — phase tempfile
  leak; F4 — writer rc=1 not checked; F5 — `output_c` unused)
- **OUT-OF-SCOPE / FOLLOW-UP:** 1 (F6 — round-trip
  `forward_complete` lingering across disable)

## Recommendation

This is a clean-review BD with one SHOULD-class test-coverage gap
(F1) that any user-initiated audit cycle should consider before
v11.0 final ship. The NITs (F2, F3, F4, F5) are honest-to-find
on a methodical read and individually low-cost to address; F3 in
particular is a pre-existing leak that BD-131 touched without
noticing.

If batch-21c is operating under the "fix all reviewer findings"
default rule and the user wishes to land them in the current
batch, the suggested order is:
1. F1 (add the resume integration test — highest value).
2. F3 (two-line tempfile cleanup symmetry — trivial).
3. F5 (delete the `output_c` capture or add an assertion — trivial).
4. F4 (optional micro-tightening — defer if other priorities).
5. F2 (no action; document as design-intent).
6. F6 (defer; log in a follow-up BD only if `pack tracker enable`
   is added to scope).

If the user defers per the "fix-or-defer per finding, nits become
tech debt" rule, the SHOULD (F1) should still get a decision; the
NITs and the OUT-OF-SCOPE F6 are safe to log without action.

## Disposition

Awaiting user decision per `feedback_fix_all_review_findings`
rule: surface every finding (MUST/SHOULD/NIT) as fix-or-defer.
Default is fix-all; nits become tech debt if deferred.

End of report.
