# PACK-REVIEW-BD-132 — silent-data-loss race fix

Reviewer: pack-reviewer (Opus 4.7, 1M context)
Branch: v11-dev
HEAD (last committed): 7ae503b
Files staged for commit F: 7 (per `git diff --cached --stat`)
Scope: BD-132 three-part race fix (Parts 1/2/3) + new race-test fixture.

---

## Executive summary

The fix is structurally sound and meaningfully reduces the BD-102 Phase A
silent-data-loss surface. Part 3 (silent-skip → loud-failure with `--force`
escape valve) is unambiguously correct and well-tested. Part 1 (close-
stabilization wait) is a reasonable heuristic but has known limits; Part 2
(race-detection refusal) has one **substantive portability bug** that
silently disables the mapping-freshness signal on Linux/CI — the platform
on which BD-102 dog-food and most production users actually run. There is
also one **false-passing assertion** in the new test fixture and a small
set of NITs.

Overall verdict: **fix-then-commit.** The portability bug is a SHOULD-FIX
that the existing test suite cannot catch (the new race-test exercises
macOS BSD stat path; CI hits the GNU branch but no assertion notices the
guard never fires). Honest concurrency-safety verdict: the fix converts
silent loss to loud failure in every covered path on macOS; on Linux/CI
Part 2b is silently inert and only Part 2a + Part 3 catch the race —
which is still strictly better than HEAD, but not what the implementation
report and BACKLOG entry claim.

ESCALATE: pack-architect: **no.** The architectural shape (stabilize-then-
detect-then-loudfail with operator override) is the right response to
"external system is eventually consistent"; no design redesign is needed.
The remaining concerns are localized bugs and calibration questions, not
structural drift.

---

## Concurrency-safety verdict (focus area 1)

The three parts compose as follows:

- **Part 1** is a *probabilistic* preventer. Polling `state=closed` count
  for stability across two reads is a reasonable proxy for "GitHub has
  fully propagated the close ops", but it is not a proof. A close that
  propagates exactly between the two stable reads will be missed. With
  the default 2s poll interval, the window for an undetected-late-close
  is ~2s wide; that is small but nonzero.
- **Part 2** is a *defense-in-depth* refuser when Part 1 fails or is
  skipped (e.g., the operator runs `init` then `disable` from a separate
  shell). The checkpoint signal (2a) is a hard signal — present iff
  forward did not cleanly complete. The mapping-freshness signal (2b)
  is a soft signal — `mtime + 30s` window.
- **Part 3** is the *ultimate safety net*: if both Part 1 and Part 2 miss
  the race, any `provider_get` failure or pack-id resolution failure
  surfaces as a per-issue WARN + non-zero exit, refusing to write half-
  data into BACKLOG.md.

Concurrency-safety bottom line: **silent loss is converted to loud
failure in every covered path** if Part 3 functions correctly (it does;
see Group 1 of the new test). The race itself is *not* fully prevented —
Part 1 has the 2-second window noted above, and Part 2's calibration
(30s freshness vs. 60s stabilization ceiling) leaves a window where
stabilization timed out, mapping is older than 30s, but closes are still
in flight. In that scenario disable proceeds; Part 3 catches the resulting
silent skips and refuses. The user gets a partial-write error instead of
data loss — which is the correct fallback behavior. No silent-loss path
remains given Part 3.

Caveat: this analysis assumes Part 3 actually fires when issues are
in-flight. The fixture in Group 1 confirms this for the
`provider_get fails` case and the `pack-id absent` case. It does NOT
confirm it for the case the BD-102 dog-food actually saw — partially-
updated body where pack-id resolves but other fields are stale (see
Finding F-3).

---

## Findings

### F-1 (SHOULD-FIX, portability) — `_tmr_mapping_age_secs` BSD/GNU stat ordering silently disables Part 2b on Linux

File: `scripts/lib/tracker-migrate-reverse.sh:73-86`

The BSD/GNU stat fallback tries `stat -f %m` first, then `stat -c %Y`.
This works correctly on macOS (BSD `stat -f <fmt>` returns mtime). On
Linux GNU coreutils, `stat -f` is a *different command*: it switches to
filesystem-status mode, ignoring `%m` for mtime and instead using `%m`
to mean "Number of free file nodes for non-superuser" — and the format
string `%m` passed via `-f` is interpreted as "Maximum length of
filenames" depending on coreutils version. In practice on Linux this
call succeeds with rc=0 and prints a small positive integer (e.g., 255
or a free-nodes count). The function returns `now - 255` ≈ ~1.7e9
seconds, which is `≥ 0` and trivially `≥ TMR_RACE_FRESHNESS_SECS=30`,
so the freshness guard never trips.

Why it's wrong: CI runs on `ubuntu-latest` and the test fixture
(`tracker-bd132-race-test.sh` Group 3) creates `id-map.json` "now",
expects `1.1 race-detection rc=1 on fresh mapping`. On a Linux runner
this assertion either (a) fails because Part 2b never fires, or
(b) the test happens to pass because the `now - 255` value coincidentally
remains non-negative and the test doesn't actually validate the cause
of refusal vs. some other code path. Either way, Part 2b is silently
inert on the production target.

Why it matters: the BACKLOG entry and implementation report both claim
"BSD/GNU stat fallback for portability". A reviewer would assume Part 2b
is the load-bearing race-detection signal on Linux. On Linux, only
Part 2a (checkpoint file presence) fires — and the checkpoint is
unconditionally cleared by `tmf_checkpoint_clear` at
`tracker-migrate-forward.sh:874` regardless of stabilization timeout
(see F-4 below). So on Linux the only Part 2 signal that could fire
after a stabilization-timeout init is *gone*.

Fix direction: try GNU `stat -c %Y` first, OR detect BSD vs. GNU stat
explicitly via `stat --version 2>/dev/null` / `uname -s`, OR use
`python3 -c 'import os, sys; print(int(os.path.getmtime(sys.argv[1])))'`
which is unambiguous on every platform that already runs the rest of
the codebase.

---

### F-2 (SHOULD-FIX, test correctness) — assertion 1.7 is trivially true and does not test what it claims

File: `scripts/tests/tracker-bd132-race-test.sh:240-244`

The fixture in `build_test_repo` creates `tracker.toml` and
`.pack-tracker/id-map.json` only — it does NOT create
`$REPO/BACKLOG.md`. Assertion 1.7 (`BACKLOG.md not written when
skip-guard fires`) checks `[[ ! -f "$REPO/BACKLOG.md" ]]` after the
guarded run, but BACKLOG.md was never going to exist regardless of
guard behavior — there is nothing in the test that would have created
it on the failure path either, since the guard returns 1 *before*
`_tmr_emit_backlog` is called.

To prove the guard prevents BACKLOG.md emission, the fixture must
either (a) pre-seed BACKLOG.md with sentinel content and assert it is
unchanged, or (b) inspect a side-effect that *would* have happened on
the post-guard emission path. As written the assertion has no
discriminating power.

Fix direction: pre-seed BACKLOG.md with a sentinel string before the
guarded run; assert the sentinel survives.

Same critique applies more weakly to 1.8 (mode flip) — but that one is
discriminating because the fixture sets `mode.state = "tracker"` and
the success path would flip it; the guard prevents the flip. So 1.8
is fine.

---

### F-3 (SHOULD-FIX, test coverage) — Part 3 is not exercised against the actual BD-102 failure mode

File: `scripts/tests/tracker-bd132-race-test.sh:120-150` (build_fake_gh_with_inflight)

The fixture's "in-flight" simulation is `gh issue view 43` returning
non-zero exit + stderr `API error: issue temporarily unreadable`. This
exercises the `provider_get failed` skip path. The BD-102 Phase A
dog-food, however, observed *silent drops* — meaning `provider_get`
succeeded but the returned body was missing the `<!-- pack-id: ... -->`
marker (mid-update body). That is a different code path (the
`pack_id` resolution step at `tracker-migrate-reverse.sh:730-740`).

The test fixture should also cover: `provider_get` returns 0 with valid
JSON whose body lacks the pack-id marker AND whose mapping-fallback
gh_id → pack_id lookup also fails (e.g., the gh_id is not in the
mapping). Without this coverage, a regression that re-silences the
"body marker missing" path would slip past the test suite even though
Group 1 still passes.

Fix direction: add an issue 44 in the fixture that returns a valid
JSON with empty body / malformed body, AND is not in the id-map, then
assert the silent-skip log catches it with reason "pack-id not
resolvable".

---

### F-4 (NIT, calibration) — Part 1 timeout cleanup leaves Part 2a inert

File: `scripts/lib/tracker-migrate-forward.sh:853-874`

If `_tmf_wait_for_close_stabilization` times out (returns 1), the
caller appends a partial_failures line, but execution continues to
line 872 (mapping save) and line 874 (`tmf_checkpoint_clear`). The
checkpoint is cleared even when stabilization failed. Consequently,
the only Part 2 signals available to a downstream `disable` are the
mapping mtime (Part 2b) and the partial-write rc=1 surfaced to the
*calling shell* — but a separate-shell `pack tracker disable` has no
visibility into the prior shell's exit code.

This is not strictly a defect — Part 3 still catches the resulting
race — but it weakens the layered defense. A defensible alternative
is: on stabilization timeout, do NOT clear the checkpoint and emit a
distinct partial-failure line (`step-8.5 stabilization timeout —
checkpoint preserved as race signal`). Then Part 2a fires reliably
on every stabilization-timeout case.

Fix direction: gate `tmf_checkpoint_clear` on a "stabilization
succeeded" flag, OR write a sentinel file like
`.pack-tracker/forward.stabilization-timed-out` that Part 2 also
checks.

---

### F-5 (NIT, calibration) — 30s freshness threshold ≪ 60s stabilization ceiling

File: `scripts/lib/tracker-migrate-reverse.sh:666`

`TMR_RACE_FRESHNESS_SECS=30` is shorter than the stabilization
ceiling (`TMF_STABILIZE_MAX_ATTEMPTS=30 × TMF_STABILIZE_SLEEP_SECS=2`
= 60s). If forward stabilization actually takes ~50s in production
(plausible on a busy gh API), then mapping_mtime is recorded at
`forward_exit_time`, and disable run at `forward_exit_time + 31s` is
33% past the freshness window even though only 31s have passed since
the last close call (against an in-the-wild propagation that may
exceed that). Combined with F-1 (Linux: freshness check inert at all
times) and F-4 (checkpoint cleared even on timeout), the freshness
window has noticeably less leverage than the BACKLOG entry implies.

This is judgement-call calibration, not a defect. The user-facing
escape (Part 3) catches what slips through.

Fix direction: set `TMR_RACE_FRESHNESS_SECS` default to ≥
`TMF_STABILIZE_MAX_ATTEMPTS × TMF_STABILIZE_SLEEP_SECS` (≥60s
default), and document the relationship in the comment block.

---

### F-6 (NIT, naming/semantics) — `expected_closed` arg is taken but never compared

File: `scripts/lib/tracker-migrate-forward.sh:1062-1067`

`_tmf_wait_for_close_stabilization` accepts `expected_closed` and
only uses it to short-circuit the `<= 0` no-op path. The function
otherwise polls until `cur_count == prev_count` regardless of
`expected_closed`. The arg name implies the function will wait until
"the closed count reaches expected_closed" — a stronger guarantee
than what's implemented.

This is fine for the eventual-consistency use case (we don't know
the absolute target count when other migrations / closes are in
flight). But the name should reflect "non-zero indicator that closes
were attempted" rather than an expected target. A user reading this
function in isolation will misunderstand its semantics.

Fix direction: rename arg to `closes_attempted` or `nonzero_signal`
(boolean-ish), or actually use `expected_closed` as a sanity check
("if `cur_count` < expected_closed, propagation is still incomplete
even if stable across two reads — keep polling").

---

### F-7 (NIT, robustness) — stabilization poll caps at limit=200

File: `scripts/lib/tracker-migrate-forward.sh:1071`

`provider_list '{"state":"closed"}' 200` caps the result at 200
issues. A repo with >200 pre-existing closed issues will return 200
on every poll (regardless of the in-flight migration's closes), so
the count will *always* appear stable on the first compare. The
function returns rc=0 immediately ("stable at 200"), even though
the migration's own closes may not have propagated.

This is a subtle correctness issue for any non-trivial production
repo. Optiquity itself has well over 200 closed issues. In practice
the BD-102 Phase A dog-food fixture had 53 closes in a fresh repo,
so the existing test environment doesn't surface this. A
production user migrating an existing repo with N >> 200 closed
issues is exactly the case where Part 1 silently no-ops.

Fix direction: filter the stabilization poll to a label scoped to
the migration (e.g., `bd-entry`, OR a label set during forward
close calls). That restricts the count to migration-relevant issues
and re-establishes the stability signal.

---

### F-8 (NIT, error-handling) — provider_list failure path zeros the count

File: `scripts/lib/tracker-migrate-forward.sh:1071-1075`

When `provider_list` fails (network blip, gh auth glitch), the
function sets `cur_count=0`. If two consecutive failures occur,
`cur_count == prev_count == 0` triggers a "stable at 0" success
return — even if the actual count is 53 in flight. This is silent
masking of an API problem.

Fix direction: distinguish "list failed" from "0 results"; track a
`consecutive_failures` counter and return rc=1 (or skip the
comparison) when failures occur.

---

## Verdicts by focus area

| Focus area | Verdict |
|---|---|
| 1. Concurrency safety (does the fix solve the race?) | PASS with caveats — silent loss converted to loud failure on every covered path; full prevention is best-effort, Part 3 is the load-bearing safety net |
| 2. Logic correctness in the diff | PASS with NITs (F-6, F-8) — no off-by-ones, exit codes consistent (rc=1 + `partial-write` typed error) |
| 3. Test sufficiency | findings — F-2 (1.7 trivially passes), F-3 (BD-102 actual failure mode not exercised) |
| 4. Design choices (poll intervals, --force, mtime threshold) | findings — F-5 (30s vs. 60s mismatch), F-7 (limit=200 cap) |
| 5. Portability (bash 3.2 + BSD vs. Linux GNU) | findings — F-1 (BSD/GNU stat ordering) |
| 6. Architecture drift / module placement | PASS — `_tmf_*` and `_tmr_*` naming consistent with rest of file; helpers placed near related code |
| 7. Structural escalation signal | PASS — no architectural redesign needed |

---

## Counts by severity

- BLOCKER: 0
- SHOULD-FIX: 3 (F-1, F-2, F-3)
- NIT: 5 (F-4, F-5, F-6, F-7, F-8)

ESCALATE pack-architect: **no.**

---

## Overall verdict

**fix-then-commit.** F-1 is the load-bearing concern: the implementation
report and BACKLOG resolution claim portability that doesn't actually
hold on the CI/production target. F-2 is a test-correctness issue that
costs little to fix and meaningfully strengthens the guarantee. F-3
extends coverage to the actual BD-102 failure mode (different code path
than what's tested today).

The NITs (F-4 through F-8) are calibration / robustness improvements
that can land in a follow-up fix; they do not block this commit's
core claim of converting silent loss to loud failure, given that
Part 3 catches what Parts 1 and 2 miss.

If F-1 / F-2 / F-3 are out-of-scope for this commit and tracked as
follow-up BD-NNN entries, then commit-as-is is acceptable — but the
BD-132 resolution line should be amended to drop the
"BSD/GNU stat fallback for portability" claim until F-1 is landed,
since that claim is currently inaccurate on Linux.
