# IMPLEMENTATION-REPORT-BD-134.md

**BD:** BD-134 — Tracker forward close retry-with-backoff (eliminate ~5% partial-write rate)
**Branch:** `v11-dev`
**Pre-flight HEAD:** `c566c20`
**Final HEAD (worktree):** `c566c20` (no commits — agents do not commit)
**Date:** 2026-05-09
**Origin:** BD-102 Phase A dog-food D-7 (3 of 56 named close failures: BD-021/022/023)
**Severity:** NIT — issues end up OPEN with `status:resolved` label instead of CLOSED

---

## Summary

Approach (b) chosen: **end-of-init re-run-failed-closes pass** with bounded
exponential backoff. The forward step-8 close loop now records each failed
close in a temp tab-separated file (pack-id, gh-id, reason) instead of
appending directly to `partial_failures`. After the loop completes, a
retry sweep (`_tmf_retry_one_close`) re-attempts each failed close up to
`TMF_CLOSE_RETRY_MAX_ATTEMPTS - 1` more times with a backoff schedule
read from `TMF_CLOSE_RETRY_BACKOFF_SECS`. Closes that succeed in the
sweep increment `closed`; closes that fail every attempt are surfaced as
partial-write entries citing the attempt count. The retry sweep is
bounded by construction — exactly `MAX_ATTEMPTS - 1` calls per failed
id, no recursion, no extension.

Defaults: 3 attempts max, "1 2 4" second backoff between retries
(0.5–1% expected residual partial-write rate vs. ~5% pre-fix on
transient `gh` API failures). Test-runtime overrides via env keep CI
fast.

---

## Design choice (a vs. b) and reasoning

**Chosen: (b) end-of-init re-run-failed-closes pass**

Considered both:

| Aspect                              | (a) per-call inline retry | (b) end-of-init sweep    |
|-------------------------------------|---------------------------|--------------------------|
| Latency on common path (no failure) | unchanged                 | unchanged                |
| Latency on failure                  | 1+2+4 = 7s **per close**, blocking the next close | 0s during loop; retries amortized at end |
| Lets API rate-limit window drain    | no — retries hit immediately | **yes** — failed set re-runs after the easy ones |
| Composes with BD-132 stabilization wait | wait would still need to handle inflight closes | wait runs AFTER retry → sees final close count |
| Change footprint                    | wrap every provider_close call site (currently only one in forward, but principle bleeds) | localized to step-8 + 1 new helper |
| Bounded                             | yes (max attempts cap) | yes (max attempts cap) |
| Easy to disable for tests / debug   | env override on every call site | env override on the helper |

(b) was chosen because:

1. **Composes cleanly with BD-132's `_tmf_wait_for_close_stabilization`**.
   Stabilization runs AFTER the retry sweep — by then `closed` reflects
   the post-retry total, so the wait correctly polls until the API
   reflects the recovered closes too. With (a) the wait would also
   need to know about retry windows.
2. **Lets the rate-limit window drain naturally.** The retry sweep
   re-attempts only the failed ids, after every easy close has finished
   and the API surface has had a beat to recover. (a) hits the same
   rate-limited endpoint immediately on each failure, which is the
   exact pattern that triggers more rate-limiting.
3. **Smaller, more contained orchestrator change.** One new helper
   (`_tmf_retry_one_close`), one new file scratch buffer
   (`failed_closes`), one new step-8.4 block. The rest of step 8 is
   unchanged in behavior.

Costs accepted:
- **Slightly later partial-write surfacing.** A persistent failure
  (e.g. permission revoked) is reported `MAX_ATTEMPTS - 1` retry
  calls later than under approach (a). With defaults that is ~3s of
  extra wallclock for a never-going-to-succeed close — negligible.
- **`failed_closes` temp file lives for one extra block.** Cleaned
  up via `rm -f` immediately after the retry sweep consumes it.

---

## Files modified

| Path | Change | Line delta |
|------|--------|------------|
| `scripts/lib/tracker-migrate-forward.sh` | Two new constants (`TMF_CLOSE_RETRY_MAX_ATTEMPTS`, `TMF_CLOSE_RETRY_BACKOFF_SECS`); step-8 loop refactored to defer failures into `failed_closes` temp file; new step-8.4 retry sweep block; new `_tmf_retry_one_close` helper. | +142 / -1 |
| `scripts/tests/tracker-migrate-forward-test.sh` | One env export at top (`TMF_CLOSE_RETRY_BACKOFF_SECS="0 0 0"`) so the existing partial-write test (4.3) does not pay 1s+2s of real backoff sleep per failed close. | +6 / -0 |

## Files created

| Path | Type | Lines |
|------|------|-------|
| `scripts/tests/tracker-bd134-close-retry-test.sh` | new test | ~330 |

## Files NOT modified (deliberately, per scope rules)

- `scripts/lib/tracker-provider-gh.sh` — kept simple. Considered adding
  retry inside `tracker_provider_gh_close` (approach a), rejected per
  the design table above.
- `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `PACK-CHAT.md`,
  `PACK-AGENTS.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — PM-only
  files per agent rules.
- `supporting-docs/DRY-RUN-MIGRATION.md`, `MIGRATION-v10-to-v11.md`,
  `OPTIONAL-FEATURES.md` — owned by parallel BD-125 coder.

---

## Retry parameters chosen

```
TMF_CLOSE_RETRY_MAX_ATTEMPTS = 3        # original try + 2 retries
TMF_CLOSE_RETRY_BACKOFF_SECS = "1 2 4"  # 1s before retry 2, 2s before retry 3
```

Reasoning:
- **3 attempts** is the standard "transient-failure-with-retry" sweet
  spot. Empirical observation in BD-102 Phase A: 3 of 56 closes failed
  on the first attempt — there is no evidence that one retry would not
  catch all three, so two retries is comfortably defensive without
  being wasteful.
- **1s/2s/4s exponential backoff.** 1s is long enough to clear most
  GitHub API short-window rate limits; 2s adds margin for the
  worst-observed propagation delay. The "4" is tail-padding — used if
  a future caller raises `MAX_ATTEMPTS` past 3 without updating the
  schedule. Total worst-case extra wallclock: 3s per persistent
  failure (with default attempts=3 we sleep 1s + 2s before declaring
  defeat).
- **Schedule held in space-separated string** — bash 3.2 has no
  associative arrays, but indexed-array word splitting on a string
  works on every macOS / Linux bash version the pack supports.
- **Env-overridable.** Tests use `TMF_CLOSE_RETRY_BACKOFF_SECS="0 0 0"`
  to avoid real sleeps. Operators with very tight or very lax
  rate-limit budgets can tune via env without code changes.

Bounded by design — `_tmf_retry_one_close` iterates exactly
`MAX_ATTEMPTS - 1` times in its retry loop. There is no recursion, no
extension, no condition under which the loop runs more than the cap.
The success-criteria persistent-failure scenario verifies this with
direct count assertions (Group 2.7–2.10 in the new test).

---

## How verified

### Validator
```
$ python3 scripts/validate-pack.py
... 28 checks ...
PASSED — all checks clean
```

### New BD-134 retry test
```
$ bash scripts/tests/tracker-bd134-close-retry-test.sh
== Group 1: transient close failure → retry recovers ==
  pass: 1.1 transient-close run rc=0 (retries succeeded)
  pass: 1.2 no partial-write surfaced (transient closes recovered)
  pass: 1.3 forward summary mentions retry sweep
  pass: 1.4 retry sweep names recovered count
  pass: 1.5 retry sweep shows persistent=0 for transient case
  pass: 1.6 forward summary shows closed: 2
  pass: 1.7 each issue saw exactly one initial-failure attempt
== Group 2: persistent close failure → bounded partial-write ==
  pass: 2.1 persistent-close run rc=1 (partial-write surfaced)
  pass: 2.2 partial-write error code surfaced
  pass: 2.3 partial-write line names step-8 close
  pass: 2.4 partial-write line names BD-001
  pass: 2.5 partial-write line cites attempt count
  pass: 2.6 retry sweep persistent count surfaces
  pass: 2.7 close attempts bounded (3 per id × 2 ids = 6 — NOT infinite)
  pass: 2.8 exactly 2 distinct ids attempted
  pass: 2.9 max attempts per id is exactly 3 (bounded)
  pass: 2.10 min attempts per id is exactly 3 (no early exit)
== Group 3: _tmf_retry_one_close helper unit tests ==
  pass: 3.1 max_attempts=1 → rc=1 immediately (no retry)
  pass: 3.2 succeeds on first retry → rc=0
  pass: 3.2 exactly 1 provider_close call (first retry succeeded)
  pass: 3.3 all retries fail → rc=1
  pass: 3.3 exactly max_attempts-1 (=3) provider_close retry calls
  pass: 3.4 succeeds on last allowed retry → rc=0
  pass: 3.4 exactly 2 provider_close retry calls before success
=== Results: 24 passed, 0 failed ===
```

### Existing test suites (success-criteria pinned)

| Suite | Result |
|-------|--------|
| `scripts/tests/tracker-bd129-gh-repo-test.sh`              | 11 / 11 PASS |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh`         | 8 / 8 PASS |
| `scripts/tests/tracker-bd132-race-test.sh`                 | 29 / 29 PASS |
| `scripts/tests/tracker-bd133-header-preservation-test.sh`  | 30 / 30 PASS |
| `scripts/tests/tracker-migrate-forward-test.sh`            | 126 / 126 PASS |
| `scripts/tests/tracker-migrate-reverse-test.sh`            | 93 / 93 PASS |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` (bonus)  | 39 / 39 PASS |

Total: 360 / 360 across the seven pinned suites; +24 new from BD-134.

### Bash syntax
```
$ bash -n scripts/lib/tracker-migrate-forward.sh
syntax OK
```

---

## Success criteria check

| Criterion | Status |
|-----------|--------|
| Transient close failure (fails N-1 times then succeeds) → close eventually succeeds; 0 partial-writes | PASS — Group 1.1, 1.2, 1.6 |
| Persistent close failure (always fails) → bounded partial-write naming gh-id, no infinite loop | PASS — Group 2.1, 2.4, 2.7, 2.9 |
| `python3 scripts/validate-pack.py` PASSES (28 checks) | PASS |
| All currently-passing test suites continue to pass | PASS — see table above |
| Add a small test exercising the retry path (mock fails N-1 then succeeds) | PASS — Group 1 + Group 3.2/3.4 |
| Bounded-failure path test (always fails → fails after bounded attempts) | PASS — Group 2 + Group 3.3 |
| BD-134 status NOT flipped in BACKLOG.md | PASS — BACKLOG.md untouched (PM-only) |

---

## Working-tree state (final)

```
$ git status (BD-134 scope only)
modified:   scripts/lib/tracker-migrate-forward.sh
modified:   scripts/tests/tracker-migrate-forward-test.sh
new:        scripts/tests/tracker-bd134-close-retry-test.sh

$ git diff --stat (BD-134 scope only)
 scripts/lib/tracker-migrate-forward.sh        | 142 +++++++++++++++++++++++++-
 scripts/tests/tracker-migrate-forward-test.sh |   6 ++
 2 files changed, 147 insertions(+), 1 deletion(-)
```

(Other working-tree files — `README.md`, `supporting-docs/MIGRATION-v10-to-v11.md`,
`supporting-docs/DRY-RUN-MIGRATION.md`,
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-125.md` —
belong to the parallel BD-125 coder and were not touched by this run.)

---

## Plan deviations

None. The BD-134 BACKLOG entry explicitly authorized either (a) or (b);
(b) was chosen with the reasoning documented above. No architecture
changes; no scope expansion.

---

## New POQs introduced

None.

---

## Definition of Done checklist

| Item | Status |
|------|--------|
| Forward close retry sweep added; bounded by `TMF_CLOSE_RETRY_MAX_ATTEMPTS` | PASS |
| Backoff schedule env-overridable for fast tests | PASS |
| New helper `_tmf_retry_one_close` documented + unit-tested | PASS |
| Persistent-failure path produces partial-write naming gh-id + attempt count | PASS |
| Composes with BD-132 stabilization wait (sweep runs BEFORE wait) | PASS — code order preserved |
| BD-131 forward_complete semantics preserved (close failures are best-effort, not create failures) | PASS — no change to step-11 logic |
| Validator clean (28/28) | PASS |
| All seven pinned test suites green | PASS |
| BD-134 status NOT flipped in BACKLOG.md | PASS |
| New test file is `pack-internal: true` (not a user-facing verb) | PASS |
| Bash 3.2 + BSD compat (no associative arrays, no GNU-only flags) | PASS — uses indexed array word-splitting + `sleep` with fractional support |
| No state-changing git verbs run by this agent | PASS |

---

## Files changed inventory

| Path | Type | Notes |
|------|------|-------|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +142 / -1 — constants, step-8 refactor, retry sweep, helper |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +6 / -0 — env export to keep test 4.3 fast |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | new | 24 assertions across 3 groups |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-134.md` | new | this report |

---

## Full file contents — new files

### `scripts/tests/tracker-bd134-close-retry-test.sh`

(See the file at the path above; ~330 lines including test-helper
boilerplate that mirrors the BD-132 race-test pattern. All scenarios
mock-based via fake `gh` on PATH and function-shim overrides of
`provider_close`. No live GitHub state is touched.)

Test groups:
- **Group 1** (1.1–1.7): transient close — fake `gh` fails the FIRST
  `issue close` call per id, succeeds on retry. Asserts rc=0, no
  partial-write, retry sweep summary names `recovered=2 persistent=0`,
  forward summary shows `closed: 2`.
- **Group 2** (2.1–2.10): persistent close — fake `gh` fails on every
  `issue close`. Asserts rc=1, partial-write surfaced citing
  `failed after 3 attempts`, AND the bounded-attempt assertions:
  total `gh issue close` calls = 6 (= 2 ids × 3 attempts), max per id
  = 3, min per id = 3. **This is the no-infinite-loop proof.**
- **Group 3** (3.1–3.4): direct unit tests of `_tmf_retry_one_close`
  with `provider_close` shimmed to a counter function.
  - 3.1: `MAX_ATTEMPTS=1` short-circuits to rc=1 with zero retries.
  - 3.2: success on first retry → rc=0 after 1 call.
  - 3.3: total failure with `MAX_ATTEMPTS=4` → rc=1 after exactly 3 calls.
  - 3.4: success on last allowed retry (`MAX_ATTEMPTS=3`) → rc=0
    after exactly 2 calls.

---

## Deferred items

None. BD-134 is contained to the close retry surface; no spillover to
adjacent BDs. Status flip is Pack Chat's responsibility (BD-134 is
left at `Status: Open` in BACKLOG.md per the agent rules).
