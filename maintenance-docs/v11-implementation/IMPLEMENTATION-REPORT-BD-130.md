# IMPLEMENTATION-REPORT-BD-130

BD: **BD-130 / D-2 (BLOCKER)** — `pack tracker doctor` emits
"command not found" because `tracker_doctor_run` is defined in
`scripts/tracker-migrate.sh` but `scripts/pack-tracker.sh` never
sources that file.

Branch: `v11-dev`
Pre-flight HEAD SHA: `39d835eacb045a3388825090640e63541706b9c6`
Final HEAD SHA on worktree (commit not made by agent — Pack Chat
owns commits): `39d835eacb045a3388825090640e63541706b9c6` (worktree
edits only; no commit created)

---

## Summary

`pack tracker doctor` was broken at `39d835e`: invoking it returned
the shell error `tracker_doctor_run: command not found`. BD-067
wired the verb dispatch but failed to expose the implementing
function to `pack-tracker.sh`. BD-130 fixes this by relocating
`tracker_doctor_run` from `scripts/tracker-migrate.sh` (where it
was inline) to a new shared lib `scripts/lib/tracker-doctor.sh`
and sourcing that lib from both dispatchers.

After the fix:
- `bash scripts/pack-tracker.sh doctor` produces normal doctor
  output ([OK] / [WARN] / [INFO] lines) instead of a shell error.
- `bash scripts/tracker-migrate.sh doctor` continues to work (its
  legacy entry path is preserved by the same source line).
- All previously-passing test suites continue to pass.
- A new regression test (`tracker-bd130-doctor-wired-test.sh`,
  8/8 pass) guards the wiring.

---

## Design choice: option (a)

Of the three options listed in the BD-130 prompt, I chose
**option (a): extract `tracker_doctor_run` into a new
`scripts/lib/tracker-doctor.sh` and source it from both
dispatchers.**

Reasoning:

1. **Matches the surrounding lib structure.** Every other
   substantive tracker subcommand body lives in `scripts/lib/`:
   `tracker-init.sh` (init), `tracker-migrate-forward.sh` (forward
   + status report), `tracker-migrate-reverse.sh` (reverse). The
   `doctor` body was the only outlier — left inline in the legacy
   `scripts/tracker-migrate.sh` dispatcher because that was the
   only entry point at the time it was written. Extracting it
   restores the lib-vs-dispatcher separation the rest of the
   codebase already follows.

2. **Avoids cross-layer mixing.** Option (b) — having
   `pack-tracker.sh` source `scripts/tracker-migrate.sh` directly
   — would mix the `scripts/` and `scripts/lib/` layers. It would
   also pull `tracker-migrate.sh`'s own `cmd_*` dispatcher
   functions (`cmd_forward`, `cmd_reverse`, etc.) into
   `pack-tracker.sh`'s namespace, surfacing internals that
   `pack-tracker.sh` does not need.

3. **Single source of truth.** Option (c) — duplicating the
   function body — was rejected by the BD-130 prompt and would
   create two copies that drift.

4. **Both call sites preserved.** Both `scripts/pack-tracker.sh`
   (`cmd_doctor` line 170) and `scripts/tracker-migrate.sh`
   (`cmd_doctor` line 153) now find `tracker_doctor_run` via the
   same shared lib. Verified via Group 2 + Group 3 of the new
   test.

---

## Files modified

### NEW: `scripts/lib/tracker-doctor.sh` (203 lines)

Holds `tracker_doctor_run <repo-root>` — the entire health-check
body that was previously inline in `scripts/tracker-migrate.sh`
lines 156–334. Function logic is byte-identical to the prior
inline version; only the docblock header changed (now describes
the lib + sourcing contract). No `source` lines of its own — both
dispatchers that source this lib have already sourced
`tracker-config.sh`, `tracker-provider*.sh`, `template-version.sh`,
and `template-translations.sh`, which are the only dependencies.

### MODIFIED: `scripts/pack-tracker.sh` (+2 lines)

Added two lines after the existing `template-translations.sh`
source, before the `recommendation.sh` source:

```sh
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-doctor.sh"
```

This is the actual fix — `cmd_doctor` at line 170 now calls a
function that is in scope.

### MODIFIED: `scripts/tracker-migrate.sh` (-179 lines net)

Two changes:

1. Added `source "$LIB_DIR/tracker-doctor.sh"` to the source list
   alongside the existing `template-translations.sh` source.
2. Removed the inline `tracker_doctor_run()` definition (the
   ~178-line block previously at lines 156–334) and replaced it
   with a 4-line pointer comment naming the new lib + BD-130
   rationale.

Net effect: behavior preserved for `tracker-migrate.sh doctor`
(both groups 6.x of `tracker-migrate-reverse-test.sh` and the
test below confirm this), code consolidated into the shared lib.

### NEW: `scripts/tests/tracker-bd130-doctor-wired-test.sh` (110 lines)

Regression guard for the wiring. Four groups, 8 assertions:
- Group 1: `scripts/lib/tracker-doctor.sh` exists and defines
  `tracker_doctor_run()`.
- Group 2: `pack-tracker.sh doctor --repo-root <scratch>`
  produces the doctor banner and contains no `command not found`.
- Group 3: same for `tracker-migrate.sh doctor`.
- Group 4: both dispatchers contain the
  `source "$LIB_DIR/tracker-doctor.sh"` line (so a future
  refactor that removes the source can't silently re-break the
  verb).

---

## Verification

### Before/after of `pack tracker doctor`

**Before (at HEAD `39d835e`, prior to BD-130 edits):**

```
$ bash scripts/pack-tracker.sh doctor
scripts/pack-tracker.sh: line 170: tracker_doctor_run: command not found
```

(rc = 127; the verb is unusable.)

**After (BD-130 worktree edits, same HEAD):**

From a scratch dir `/tmp/bd130-scratch` (empty):

```
$ bash scripts/pack-tracker.sh doctor
doctor: /tmp/bd130-scratch
  [WARN] tracker.toml absent at /tmp/bd130-scratch/tracker.toml  → Run: pack tracker init
  [INFO] no mapping file (expected before first forward run)
  [WARN] /tmp/bd130-scratch/.github/ISSUE_TEMPLATE absent  → Run: pack tracker init
doctor: completed with 2 warning(s)
RC=1
```

From the pack-repo root:

```
$ bash scripts/pack-tracker.sh doctor
doctor: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
  [WARN] tracker.toml absent at /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/tracker.toml  → Run: pack tracker init
  [INFO] no mapping file (expected before first forward run)
  [INFO] BACKLOG.md has no mirror header (flat-file mode or post-reverse state)
  [OK]   /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/ISSUE_TEMPLATE present (3 templates)
  [OK]   template-version freshness: work-item=work-item-v11.0, inbound=inbound-v11.0, manifest=0 transitions (current)
doctor: completed with 1 warning(s)
RC=1
```

`bash scripts/tracker-migrate.sh doctor` (legacy entry) produces
identical output to the pack-repo invocation above — confirming
both call sites resolve the function from the same lib.

### Test suites (all passing)

| Suite | Result |
|---|---|
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` (NEW) | 8 / 8 pass |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | 11 / 11 pass |
| `scripts/tests/tracker-bd132-race-test.sh` | 29 / 29 pass |
| `scripts/tests/tracker-migrate-forward-test.sh` | 111 / 111 pass |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 93 / 93 pass (incl. groups 6.2 / 6.3 which exercise the relocated `tracker_doctor_run` in its `tracker-migrate.sh` call path — proves the function still works there) |
| `scripts/tests/tracker-init-test.sh` | 95 / 95 pass |

### Validator

```
$ python3 scripts/validate-pack.py
... (all 28 checks)
============================================================
PASSED — all checks clean
```

---

## Working-tree state

```
$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
	modified:   scripts/lib/tracker-config.sh           (BD-129)
	modified:   scripts/lib/tracker-labels.sh           (BD-129)
	modified:   scripts/lib/tracker-provider-gh.sh      (BD-129)
	modified:   scripts/pack-tracker.sh                 (BD-130, +2 lines)
	modified:   scripts/tracker-migrate.sh              (BD-130, -179 lines net)

Untracked files:
	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-129.md
	scripts/lib/tracker-doctor.sh                       (BD-130, NEW)
	scripts/tests/tracker-bd129-gh-repo-test.sh         (BD-129, NEW)
	scripts/tests/tracker-bd130-doctor-wired-test.sh    (BD-130, NEW)
	maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-130.md  (this file)
```

Diff summary (combined BD-129 + BD-130 worktree state):

```
$ git diff --stat
 scripts/lib/tracker-config.sh      |  43 +++++++++
 scripts/lib/tracker-labels.sh      |  10 ++
 scripts/lib/tracker-provider-gh.sh |  13 +++
 scripts/pack-tracker.sh            |   2 +
 scripts/tracker-migrate.sh         | 185 ++-----------------------------------
 5 files changed, 74 insertions(+), 179 deletions(-)
```

(Plus the four untracked files listed above — three lib/test
files and two implementation reports.)

---

## Interaction with BD-129

**Zero conflicts.** BD-129's modifications are confined to
`scripts/lib/tracker-config.sh`, `scripts/lib/tracker-labels.sh`,
`scripts/lib/tracker-provider-gh.sh`, and a new test file. BD-130
modifies a disjoint set: `scripts/pack-tracker.sh`,
`scripts/tracker-migrate.sh`, a new lib file, and a new test
file. The two BDs share no source-file lines.

Verified by running the BD-129 test suite (`tracker-bd129-gh-repo
-test.sh`) post-BD-130 edits: 11 / 11 still pass — BD-130's lib
relocation does not disturb the GH_REPO routing BD-129 added to
`tracker-labels.sh`.

The combined Batch-8 commit Pack Chat will create can stage all
five modified files + four untracked files as a single
combined-fix commit per `EXECUTION-PLAN-V11.0.md`.

---

## Definition of Done

| Criterion | Status |
|---|---|
| `bash scripts/pack-tracker.sh doctor` works from pack-repo root (no command-not-found) | PASS |
| `bash scripts/pack-tracker.sh doctor` works from a fresh scratch target (no command-not-found, doctor-emitted output) | PASS |
| `bash scripts/tracker-migrate.sh doctor` continues to work via the legacy entry path | PASS |
| `tracker_doctor_run` reachable from `pack-tracker.sh::cmd_doctor` AND `tracker-migrate.sh::cmd_doctor` | PASS |
| `python3 scripts/validate-pack.py` PASSES (all 28 checks clean) | PASS |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` 11 / 11 pass | PASS |
| `scripts/tests/tracker-bd132-race-test.sh` 29 / 29 pass | PASS |
| `scripts/tests/tracker-migrate-forward-test.sh` 111 / 111 pass | PASS |
| `scripts/tests/tracker-migrate-reverse-test.sh` 93 / 93 pass | PASS |
| `scripts/tests/tracker-init-test.sh` 95 / 95 pass | PASS |
| New wiring-regression test added | PASS (`scripts/tests/tracker-bd130-doctor-wired-test.sh`, 8 / 8) |
| Trinity rule respected (no asymmetric edits to CLAUDE.md / AGENTS.md / GEMINI.md) | PASS (none touched) |
| PM-only files untouched (BACKLOG / CHANGELOG / README / PACK-CHAT / PACK-AGENTS / CLAUDE / AGENTS / GEMINI) | PASS |
| No state-changing git verbs used | PASS (read-only `status`, `diff`, `rev-parse` only) |
| BD-130 status NOT flipped in BACKLOG.md (Pack Chat owns) | PASS (BACKLOG.md not modified) |
| BD-129 work preserved (no edits to BD-129-touched lines) | PASS |

All checks PASS.

---

## Plan deviations

None. The implementation matches BD-130 option (a) as outlined in
the prompt, with no scope expansion and no design changes.

---

## New POQs introduced

None. The fix is a straightforward extract-to-lib refactor with
zero behavior change for the function body.

---

## Files changed inventory

| Path | Change | Notes |
|---|---|---|
| `scripts/lib/tracker-doctor.sh` | NEW | 203 lines; holds `tracker_doctor_run()` body extracted from `tracker-migrate.sh`. |
| `scripts/pack-tracker.sh` | MODIFIED | +2 lines: shellcheck comment + `source "$LIB_DIR/tracker-doctor.sh"`. This line is the actual blocker fix. |
| `scripts/tracker-migrate.sh` | MODIFIED | -179 lines net: source line added (+2), inline 178-line `tracker_doctor_run()` definition replaced by a 4-line pointer comment. Behavior preserved. |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | NEW | 110 lines; 8 / 8 pass. Wiring regression guard. |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-130.md` | NEW | This report. |

---

## Deferred items

None. The BLOCKER is fully resolved within this BD's scope. Any
additional `pack tracker doctor` enhancements (e.g. JSON output,
selective check execution, `--strict` mode) are out of scope and
should be filed as new BDs if desired.
