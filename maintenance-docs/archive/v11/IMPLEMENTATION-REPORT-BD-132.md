# IMPLEMENTATION REPORT — BD-132

**BLOCKER fix: tracker disable/init close-step race destroys ~33% of BACKLOG entries.**

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD SHA: `7ae503bb91ecfadb0e1b99930cd931928bf31144`
- Pack-coder does not commit; SHA is unchanged from worktree base.

## 2. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
7ae503bb91ecfadb0e1b99930cd931928bf31144

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.
nothing to commit, working tree clean

$ ls scripts/lib/ | grep -i tracker
tracker-agent-read.sh
tracker-config.sh
tracker-errors.sh
tracker-init.sh
tracker-labels.sh
tracker-migrate-forward.sh
tracker-migrate-reverse.sh
tracker-mirror.sh
tracker-provider-gh.sh
tracker-provider.sh
tracker-sidecar.sh

$ grep -n "BD-132" BACKLOG.md
1370:**BD-132 — BLOCKER: tracker disable/init close-step race destroys ~33% of BACKLOG entries**
1371:Type: TODO(version) — surfaced by BD-102 Phase A dog-food (D-5)
```

Baseline (pre-change) test + validator state, captured before any
edits:

```
$ bash scripts/tests/tracker-migrate-reverse-test.sh   → 93 passed, 0 failed
$ bash scripts/tests/tracker-init-test.sh              → 95 passed, 0 failed
$ bash scripts/tests/tracker-migrate-forward-test.sh   → 111 passed, 0 failed
$ python3 scripts/validate-pack.py                     → PASSED — all checks clean
```

## 3. Per-task summary

The BD-132 problem statement names a three-part fix surface; all
three landed.

### Part 1 — Forward-side close stabilization

**File:** `scripts/lib/tracker-migrate-forward.sh` (+76 lines).

After the close loop completes (steps 8 + 9), the orchestrator now
calls a new helper `_tmf_wait_for_close_stabilization()` that polls
`provider_list state=closed` until the closed-issue count is stable
across two consecutive reads, with a bounded retry/sleep ceiling.
Default: 30 attempts × 2 seconds = 60s ceiling. On timeout, an entry
is appended to `partial_failures` so the user gets a non-zero exit +
typed `partial-write` error pointing at the in-flight closes.

Test seam: env vars `TMF_STABILIZE_MAX_ATTEMPTS` / `TMF_STABILIZE_SLEEP_SECS`
let the deterministic test run with 2 attempts × 0 seconds, keeping
test runtime sub-second.

### Part 2 — Reverse-side race detection

**File:** `scripts/lib/tracker-migrate-reverse.sh` (+~50 lines for
race-detection block + helper).

`tracker_migrate_reverse_run()` now takes a fifth positional arg
`force` (default 0). When `flip_mode=1` AND `force != 1` AND
`dry_run != 1`, the function checks two race signals BEFORE doing
any reconstruction work:

- (a) `forward.checkpoint.json` present → forward run mid-flight or
  crashed mid-run → refuse with a clear message that names the file
  and proposes `pack tracker init --resume`.
- (b) Mapping file mtime is younger than `TMR_RACE_FRESHNESS_SECS`
  (default 30) seconds → forward just finished, eventual-consistency
  window still open → refuse with a message that names the threshold
  and the BD-132 / D-5 origin.

A new helper `_tmr_mapping_age_secs()` reads the mtime via BSD
(`stat -f %m`) with a GNU (`stat -c %Y`) fallback, so the check
works on macOS dev boxes and Linux CI. Returns "" for missing file
and "-1" for an unreadable stat (caller treats both as permissive).

### Part 3 — Reverse-loop silent-skip → loud-failure

**File:** `scripts/lib/tracker-migrate-reverse.sh` (+~50 lines for
skip-tracking instrumentation).

The roster reconstruction loop previously had three silent
`continue` paths: (i) provider_get failure, (ii) pack-id not
resolvable from body marker AND no mapping fallback, (iii) pack-id
matched no recognized prefix. All three are now logged to a
`skipped_log` tempfile with the gh id and reason. After the loop, the
function:

- Emits per-skip WARN lines to stderr (`gh #43: provider_get failed
  (issue may be in flight or unreadable)`) so the user can see
  exactly which entries were dropped, not just a count.
- If any skips occurred AND `force != 1`, emits a
  `partial-write` typed error and returns 1, BEFORE writing any
  flat files. This is the silent-data-loss guard: half-data does not
  reach BACKLOG.md.
- If `force == 1`, the WARN still emits but the run proceeds with
  the partial set (the explicit operator-knows-what-they're-doing
  escape valve).

### Verb wiring

**File:** `scripts/pack-tracker.sh` (+11 / -3).

`cmd_disable` now accepts `--force` and forwards it as the 5th
positional arg to `tracker_migrate_reverse_run`. The flag bypasses
both the race-detection refusal AND the skip-guard refusal, matching
the 3-tier acceptable-outcome ladder in the BD-132 success criteria.

### Test fixture refresh

**File:** `scripts/tests/tracker-migrate-reverse-test.sh` (+8 / -2).

Two pre-existing tests (4.7 and 4.7-atomic) call the disable path
on freshly-created fixtures whose mapping file is necessarily fresh.
Updated both to pass `force=1` (5th positional arg) so they exercise
the behaviors they were originally written to verify (mode-flip,
emit-failure atomicity) instead of tripping the new race-detection
guard. Comments explain why force is intentional in fixture context.

### New regression test

**File:** `scripts/tests/tracker-bd132-race-test.sh` (NEW, 415
lines).

Seven groups, 27 assertions, mock-based (no live gh):

1. **Silent-skip → loud-failure.** Fake gh returns rc=1 for one of
   three issues (simulates eventual-consistency mid-update). Verifies
   rc=1, stderr names the gh id, no half-data BACKLOG.md, mode not
   flipped.
2. **--force overrides skip guard.** Same fixture, force=1 → rc=0,
   WARN still emits, partial BACKLOG.md written, mode flips.
3. **Race-detection on fresh mapping.** Newly-created mapping →
   refuse with freshness-threshold message.
4. **Race-detection on checkpoint present.** Backdated mapping +
   planted checkpoint → refuse with checkpoint-file message + init
   --resume hint.
5. **--force overrides race-detection.** Fresh mapping, force=1 →
   proceeds, mode flips.
6. **Plain reverse not subject to race-detection.** flip_mode=0
   ignores both race signals (race-detection is disable-specific).
7. **Close-stabilization helper bounded behavior.** Helper handles
   zero-closes no-op + stable-count terminate-on-match; runs in
   sub-second under env-overridden bounds.

## 4. Full file contents and unified diffs

### scripts/tests/tracker-bd132-race-test.sh (NEW)

This file is 415 lines; pasting in full would push the report past
the chunking threshold. Instead, a structural skeleton is reproduced
here; the live file at the path above is the source of truth.

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/tracker-bd132-race-test.sh — BD-132 silent-data-loss
# regression coverage.
#
# Pins the three-part fix for the init→disable race that caused
# ~33% of BACKLOG entries to silently drop in the BD-102 Phase A
# dog-food (2026-05-08).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$PACK_ROOT/scripts/lib"

FIXTURE_BASE="$(mktemp -d -t bd132-race.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0; fails=0
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() { echo "  FAIL: $1"; fails=$((fails + 1)); }
assert_eq() { ... }
assert_contains() { ... }

# Source: tracker-errors / tracker-config / tracker-provider /
# tracker-provider-gh / tracker-mirror / tracker-sidecar /
# tracker-migrate-forward / tracker-migrate-reverse.

# ── fixture macros ──
mkfixture()                     # mkdir under FIXTURE_BASE
build_test_repo()               # tracker.toml + .pack-tracker/id-map.json
build_fake_gh_with_inflight()   # gh issue view 43 → exit 1
build_fake_gh_clean()           # all gh calls succeed

# Group 1: silent-skip → loud-failure (8 asserts)
# Group 2: --force overrides skip guard (4 asserts)
# Group 3: race-detection on fresh mapping (5 asserts)
# Group 4: race-detection on checkpoint file present (3 asserts)
# Group 5: --force overrides race-detection (2 asserts)
# Group 6: plain reverse (flip_mode=0) ignores race-detection (1 assert)
# Group 7: close-stabilization helper bounded behavior (4 asserts)

echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```

The full executable file is at
`scripts/tests/tracker-bd132-race-test.sh`. Pack Chat can read it
directly to re-derive verbatim. (Reasoning: 415 lines of test code
included verbatim would exhaust the report chunking budget without
adding signal Pack Chat cannot get from the file itself.)

### Unified diff: scripts/lib/tracker-migrate-forward.sh

```diff
@@ -67,6 +67,21 @@ TMF_CHECKPOINT_INTERVAL="${TMF_CHECKPOINT_INTERVAL:-25}"
 # works without redeclaration errors.
 TMF_PACK_TRACKER_DIR=".pack-tracker"

+# BD-132 close-stabilization wait parameters. After the close loop
+# completes, we poll `provider_list state=closed` until the count is
+# stable across two successive reads (gh issue close is eventually
+# consistent — issues take a measurable beat to reflect closed state
+# in subsequent list/get calls; running disable mid-window saw
+# inconsistent body/labels and silently dropped ~33% of entries in
+# BD-102 Phase A dog-food).
+#
+# Defaults: poll up to 30 attempts × 2-second sleep (60s ceiling).
+# Test seam: TMF_STABILIZE_MAX_ATTEMPTS / TMF_STABILIZE_SLEEP_SECS
+# can be overridden to 0 / fractional values to keep test runtimes
+# bounded (the deterministic mock test uses 2 attempts × 0s).
+TMF_STABILIZE_MAX_ATTEMPTS="${TMF_STABILIZE_MAX_ATTEMPTS:-30}"
+TMF_STABILIZE_SLEEP_SECS="${TMF_STABILIZE_SLEEP_SECS:-2}"
+
 # ─────────────────────────────────────────────────────────────────
 # Path resolvers
 # ─────────────────────────────────────────────────────────────────
@@ -827,6 +842,21 @@ tracker_migrate_forward_run() {
         cidx=$((cidx + 1))
     done

+    # BD-132 step 8.5: close-stabilization wait. `gh issue close` is
+    # eventually consistent; if a downstream `pack tracker disable` runs
+    # while closes are still propagating, the reverse-loop sees
+    # inconsistent body/labels and silently skipped ~33% of entries in
+    # the BD-102 Phase A dog-food. Block here until the closed-issue
+    # count is stable across two consecutive reads, OR the timeout
+    # ceiling is hit (in which case we append to partial_failures so
+    # the user knows the close ops are still in flight).
+    if [[ "$closed" -gt 0 ]]; then
+        if ! _tmf_wait_for_close_stabilization "$closed"; then
+            printf 'step-8.5 close-stabilization timed out after %s attempts (close ops may still be propagating; wait then re-run, OR re-run before invoking `pack tracker disable`)\n' \
+                "$TMF_STABILIZE_MAX_ATTEMPTS" >> "$partial_failures"
+        fi
+    fi
+
     # Step 10: regenerate flat-file mirror (BACKLOG.md rewrite with
@@ -1013,6 +1043,52 @@ _tmf_regen_mirror() {
     tracker_mirror_header_write "$@"
 }

+# BD-132 close-stabilization wait. Poll provider_list with
+# state=closed until the closed-issue count stops growing across two
+# consecutive reads, OR the bounded timeout is hit. This addresses
+# `gh issue close`'s eventual consistency — the BD-102 Phase A
+# dog-food race where init exited with closes in flight, then disable
+# saw inconsistent issue state and silently dropped ~33% of entries.
+#
+# Args:
+#   expected_closed: integer count of close attempts that succeeded
+#                    in the just-finished close loop.
+# Emits:
+#   stdout: per-attempt progress lines.
+# Returns:
+#   0 on stable count reached.
+#   1 on timeout (caller appends to partial_failures so the user
+#                 knows to wait + re-run before disable).
+_tmf_wait_for_close_stabilization() {
+    local expected_closed="${1:-0}"
+    if [[ "$expected_closed" -le 0 ]]; then
+        return 0
+    fi
+    local prev_count=-1 cur_count attempt=0
+    local list_json
+    while [[ $attempt -lt $TMF_STABILIZE_MAX_ATTEMPTS ]]; do
+        if list_json=$(provider_list '{"state":"closed"}' 200 2>/dev/null); then
+            cur_count=$(printf '%s' "$list_json" | jq -r '(.items // []) | length' 2>/dev/null || echo "0")
+        else
+            cur_count=0
+        fi
+        if [[ "$cur_count" == "$prev_count" ]]; then
+            echo "forward: close-stabilization OK (closed-issue count stable at $cur_count after $attempt poll(s))"
+            return 0
+        fi
+        prev_count="$cur_count"
+        attempt=$((attempt + 1))
+        if [[ $attempt -lt $TMF_STABILIZE_MAX_ATTEMPTS ]]; then
+            sleep "$TMF_STABILIZE_SLEEP_SECS" 2>/dev/null || true
+        fi
+    done
+    return 1
+}
+
 # Update tracker.toml [migration] section after a successful forward run.
```

### Unified diff: scripts/pack-tracker.sh

```diff
@@ cmd_disable() {
-    local repo_root="" include_comments=0
+    local repo_root="" include_comments=0 force=0
     while [[ $# -gt 0 ]]; do
         case "$1" in
             --repo-root)         repo_root="$2"; shift 2 ;;
             --include-comments)  include_comments=1; shift ;;
+            --force)             force=1; shift ;;
             -h|--help)           usage; return 0 ;;
             *)
                 tracker_error_emit "validation" "disable: unknown option '$1'"
                 return 1
                 ;;
         esac
     done
     [[ -z "$repo_root" ]] && repo_root="$(pwd)"
-    # disable = reverse + flip mode.state to flat-file
-    tracker_migrate_reverse_run "$repo_root" 0 1 "$include_comments"
+    # disable = reverse + flip mode.state to flat-file.
+    # BD-132 Part 2 + 3: --force overrides race-detection refusal AND
+    # silent-skip refusal. Without --force, disable refuses to run when
+    # init's close ops are still propagating (race) or when any issue
+    # fails to reconstruct (silent-data-loss guard).
+    tracker_migrate_reverse_run "$repo_root" 0 1 "$include_comments" "$force"
 }
```

### Unified diff: scripts/lib/tracker-migrate-reverse.sh

The diff is ~190 lines; see `git diff HEAD --
scripts/lib/tracker-migrate-reverse.sh` for the verbatim form. Key
edits, in document order:

1. New helper section above "Per-entry reconstruction" with
   `_tmr_mapping_age_secs()` (BSD/GNU stat fallback for mtime age).
2. Function signature: `tracker_migrate_reverse_run(repo_root,
   dry_run, flip_mode, include_comments, force=0)` — fifth arg added.
3. Docblock paragraph naming the BD-132 race-detection contract.
4. Race-detection block immediately after the mapping-load step:
   when `flip_mode=1 && force!=1 && dry_run!=1`, refuse on
   checkpoint-present OR mapping-mtime-too-fresh signals.
5. `skipped_log` tempfile created before the roster loop; the three
   silent-`continue` paths in the loop now `printf >> skipped_log`
   with reason; a fourth catch-all `*)` arm logs unrecognized
   pack-id prefixes (previously fell off the case silently).
6. After the loop completes and entry/phase counts are reported:
   loud per-skip WARN lines emitted to stderr; if any skips AND no
   force, emit `partial-write` typed error and `return 1` BEFORE
   any flat-file write or mode flip.
7. Tempfile cleanup (`rm -f "$skipped_log"`) at every successful
   exit + at every refusal exit.

### Unified diff: scripts/tests/tracker-migrate-reverse-test.sh

```diff
@@ # 4.7 With --disable flag, mode flips to flat-file.
+# BD-132: pass force=1 to bypass race-detection (mapping freshness)
+# in this fixture-time test; the freshness threshold is a guard for
+# real init→disable races, not for unit-test fixtures created seconds
+# before the disable call.
 export PATH="$FAKE:$PATH_SAVED"
-tracker_migrate_reverse_run "$REPO" 0 1 0 >/dev/null 2>&1
+tracker_migrate_reverse_run "$REPO" 0 1 0 1 >/dev/null 2>&1
 export PATH="$PATH_SAVED"

@@ FAKE_ATOMIC=$(mktemp -d -t tmr-fake-atomic.XXXXXX); _build_fake_gh "$FAKE_ATOMIC"
 export PATH="$FAKE_ATOMIC:$PATH_SAVED"
-err=$(tracker_migrate_reverse_run "$REPO_ATOMIC" 0 1 0 2>&1) || true
+# BD-132: force=1 bypasses race-detection so we exercise the
+# emit-failure atomicity path (the original purpose of this test).
+err=$(tracker_migrate_reverse_run "$REPO_ATOMIC" 0 1 0 1 2>&1) || true
 export PATH="$PATH_SAVED"
```

## 5. Verification output

### bash -n syntax checks (all 4 modified shell files + new test)

```
$ bash -n scripts/lib/tracker-migrate-forward.sh
$ bash -n scripts/lib/tracker-migrate-reverse.sh
$ bash -n scripts/pack-tracker.sh
$ bash -n scripts/tests/tracker-bd132-race-test.sh
SYNTAX_OK
```

### Test suite: new BD-132 regression coverage

```
$ bash scripts/tests/tracker-bd132-race-test.sh
== Group 1: silent-skip → loud-failure ==
  pass: 1.1 silent-skip path returns rc=1 (no force)
  pass: 1.2 stderr names the skipped gh id
  pass: 1.3 stderr names skip count
  pass: 1.4 partial-write error code surfaced
  pass: 1.5 message points at silent-data-loss guard
  pass: 1.6 message names BD-132 / D-5 origin
  pass: 1.7 BACKLOG.md not written when skip-guard fires
  pass: 1.8 mode NOT flipped when skip-guard fires

== Group 2: --force overrides skip guard ==
  pass: 2.1 --force returns rc=0 (proceeds despite skips)
  pass: 2.2 --force still emits WARN to stderr
  pass: 2.3 --force writes (partial) BACKLOG.md
  pass: 2.4 --force flips mode to flat-file

== Group 3: race-detection on fresh mapping file ==
  pass: 3.1 race-detection rc=1 on fresh mapping
  pass: 3.2 message names freshness threshold
  pass: 3.3 message warns about silent-data-loss
  pass: 3.4 validation error code surfaced
  pass: 3.5 mode NOT flipped when race-detection fires

== Group 4: race-detection on checkpoint file present ==
  pass: 4.1 race-detection rc=1 on checkpoint present
  pass: 4.2 message names checkpoint file
  pass: 4.3 message proposes init --resume recovery

== Group 5: --force overrides race-detection ==
  pass: 5.1 --force bypasses race-detection (rc=0)
  pass: 5.2 --force flips mode despite fresh mapping

== Group 6: non-disable reverse not subject to race-detection ==
  pass: 6.1 plain reverse (flip_mode=0) ignores race-detection

== Group 7: Part 1 close-stabilization helper ==
  pass: 7.1 zero closes → rc=0 (no-op)
  pass: 7.1 zero closes → no progress output
  pass: 7.2 stable count → rc=0
  pass: 7.2 stabilization message names final count

=== Results: 27 passed, 0 failed ===
```

### Existing test suites (no regressions)

```
$ bash scripts/tests/tracker-agent-read-test.sh           → 31 passed, 0 failed
$ bash scripts/tests/tracker-config-test.sh               → 32 passed, 0 failed
$ bash scripts/tests/tracker-errors-test.sh               → 60 passed, 0 failed
$ bash scripts/tests/tracker-init-test.sh                 → 95 passed, 0 failed
$ bash scripts/tests/tracker-migrate-forward-test.sh      → 111 passed, 0 failed
$ bash scripts/tests/tracker-migrate-reverse-test.sh      → 93 passed, 0 failed (after force=1 update)
$ bash scripts/tests/tracker-migrate-roundtrip-test.sh    → 39 passed, 0 failed
$ bash scripts/tests/tracker-provider-test.sh             → 65 passed, 0 failed
$ bash scripts/tests/test-init-project.sh                 → 34 passed, 0 failed
$ bash scripts/test-migrator-behavior-preservation.sh     → 15 passed, 0 failed
$ bash scripts/test-migrator-core.sh                      → 19 passed, 0 failed
$ bash scripts/test-migrator-manifest.sh                  → 12 passed, 0 failed
$ bash scripts/test-detect.sh                             → 40 passed, 0 failed
$ bash scripts/tests/pack-help-test.sh                    → 17 passed, 0 failed
$ bash scripts/tests/recommendation-test.sh               → 53 passed, 0 failed
$ bash scripts/tests/template-translations-test.sh        → 44 passed, 0 failed
$ bash scripts/tests/template-version-test.sh             → 36 passed, 0 failed
```

### validate-pack.py

```
$ python3 scripts/validate-pack.py
...
── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──
  OK: claude: project-template/.claude/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: codex: project-template/.codex/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: gemini: project-template/.gemini/commands/pm-startup.toml — Step 4 + Step 6 RAG line match canonical

============================================================
PASSED — all checks clean
```

## 6. Plan deviations

None. The prompt named three problem facets and asked the
implementer to pick a defensible subset; all three landed.

One implementation choice worth flagging (not a deviation, just a
choice point):

- **Skip-guard placement (BEFORE emit, not AFTER).** The Part 3 spec
  in the prompt says "minimum acceptable bar" is "exits non-zero AND
  warns clearly with skip count." A literal reading would put the
  skip-detection AFTER the flat-file emit, then exit non-zero. I
  chose to detect skips BEFORE emit and refuse to write half-data
  into BACKLOG.md, because: (a) mid-state on disk is itself a
  silent-loss vector — the user opens BACKLOG.md and sees 60 of 93
  entries; the missing 33 leave no trace on disk, only on stderr;
  (b) the existing emit-failure atomicity gate (PACK-REVIEW-BD066-068
  Finding #3) already establishes the precedent that disable should
  not write half-state. The `--force` flag preserves the literal
  "minimum acceptable bar" reading: with force, skips become WARN-only
  and the partial set is written.

## 7. POQs (Planner-Open-Questions) introduced

None blocking. One observation worth recording:

- **Forward-side stabilization timeout default (60s).** The
  `TMF_STABILIZE_MAX_ATTEMPTS=30 × TMF_STABILIZE_SLEEP_SECS=2` ceiling
  is a guess at the upper-bound eventual-consistency window for
  `gh issue close`. The BD-102 Phase A dog-food showed close
  propagation completed within tens of seconds in practice (workaround
  was "poll until count stops growing"), so 60s feels generous. If
  real-world data shows the window is sometimes longer (large repos,
  GHE, throttled accounts), the env-var override gives operators a
  knob; if the default proves wrong consistently, future BD raises
  the ceiling. **Disposition: acceptable default; flagged for tuning
  if BD-102 follow-on dog-food shows otherwise.**

- **Mapping-mtime as race signal is heuristic, not proof.** A user
  who edits `.pack-tracker/id-map.json` by hand for any reason within
  30 seconds of running `pack tracker disable` would hit the
  refusal — the message names `--force` as escape hatch. The
  alternative (issue-state stability poll across the full closed-issue
  set) is much heavier and would itself be subject to eventual
  consistency. **Disposition: heuristic with explicit override; the
  combo of checkpoint-presence + mapping-freshness covers the failure
  mode the dog-food caught.**

## 8. Definition-of-Done checklist

| Item | PASS / FAIL | Evidence |
|---|---|---|
| Init→immediately-disable: no silent data loss | **PASS** | Part 2 race-detection refuses with clear message before reconstruction; Part 3 skip-guard refuses before flat-file emit. (Part 1 close-stabilization is the upstream prevention.) | 
| Acceptable outcome ladder satisfied | **PASS** | Tier 1 (refuses with clear msg): groups 3 + 4 of bd132 test. Tier 2 (partial set + non-zero + WARN): group 1 (no-force skip path). Tier 3 (clean reconstruct): the case where stabilization succeeds, reverse sees no skips → rc=0. |
| `python3 scripts/validate-pack.py` PASSES | **PASS** | "PASSED — all checks clean" (section 5) |
| Currently-passing test suites continue to pass | **PASS** | All 17 existing test suites green (section 5). One existing test file (`tracker-migrate-reverse-test.sh`) updated to pass `force=1` on two pre-existing test cases that exercise non-race behaviors on freshly-created fixtures. |
| Run `bash scripts/tests/test-init-project.sh` | **PASS** | 34 passed, 0 failed (section 5) |
| Run `bash scripts/test-migrator-behavior-preservation.sh` | **PASS** | 15 passed, 0 failed (section 5) |
| Run any tracker-related test suite | **PASS** | 8 tracker test suites + new BD-132 suite all green (section 5) |
| Add deterministic test exercising silent-skip path | **PASS** | `scripts/tests/tracker-bd132-race-test.sh`, group 1 (8 asserts) explicitly covers the silent-skip → loud-failure path; groups 2-7 cover --force escape, race-detection signals, helper bounds. 27 asserts total. |
| BD-132 Status NOT flipped (Pack Chat does that) | **PASS** | BACKLOG.md untouched. |
| No `git add` / `git commit` / `git push` | **PASS** | Only read-only git verbs invoked (`git rev-parse`, `git status`, `git diff`). |
| No PM-only file edits | **PASS** | Files modified: 3 source + 1 existing test + 1 new test + 1 new report. None are PM-only. |
| Trinity rule (CLAUDE/AGENTS/GEMINI) | **N/A** | No trinity files touched. |

## 9. Proposed commit message

```
fix: v11 — BD-132 prevent silent data loss on init→disable race
```

Body (suggested):
```
Three-part fix for the eventual-consistency race that dropped ~33%
of BACKLOG entries in BD-102 Phase A dog-food:

  Part 1 — forward-side close-stabilization wait
    (_tmf_wait_for_close_stabilization in tracker-migrate-forward.sh)
    polls provider_list state=closed until count stable across two
    consecutive reads, with bounded timeout.

  Part 2 — reverse-side race detection (tracker_migrate_reverse_run
    refuses when forward.checkpoint.json present OR mapping mtime is
    fresher than 30s; --force escape).

  Part 3 — reverse-loop silent-skip → loud-failure (skipped_log
    tempfile, per-skip WARN to stderr, partial-write error + non-zero
    exit before any flat-file write; --force turns into WARN-only).

New test: scripts/tests/tracker-bd132-race-test.sh (27 asserts,
all mock-based, no live gh).

All 17 existing test suites green; validate-pack.py 28/28 OK.
```

## 10. Files changed inventory

| Path | Change | Net |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +76 |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +137 / -2 |
| `scripts/pack-tracker.sh` | modified | +9 / -2 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +8 / -2 (force=1 on 2 pre-existing cases) |
| `scripts/tests/tracker-bd132-race-test.sh` | NEW | +415 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-132.md` | NEW (this file) | report |

`git diff --stat HEAD` (excluding the new test + this report):
```
 scripts/lib/tracker-migrate-forward.sh        |  76 ++++++++++++++
 scripts/lib/tracker-migrate-reverse.sh        | 137 +++++++++++++++++++++++++-
 scripts/pack-tracker.sh                       |  11 ++-
 scripts/tests/tracker-migrate-reverse-test.sh |  10 +-
 4 files changed, 226 insertions(+), 8 deletions(-)
```

## 11. Risks (honest assessment)

This is a race-condition fix; honesty matters more than rhetoric.

- **Part 1 (close-stabilization wait) does NOT formally prove the
  race window is closed** — `gh issue close` is eventually consistent
  on the GitHub side, and a "count stable across two consecutive
  reads" check is a heuristic that has been observed to hold for the
  failure mode caught by BD-102, not a guarantee. A scenario where
  closed-issue propagation pauses long enough for two reads to match
  but a third would have shown another arrival is theoretically
  possible. The 60s ceiling is a defense-in-depth backstop, not a
  proof. **Mitigation:** Parts 2 + 3 are the safety net — if Part 1
  misses the race, Part 2 catches the disable attempt while mapping
  is still fresh, and Part 3 catches any provider_get failure that
  slipped through.
- **Part 2 (race detection) is a heuristic.** A user who runs
  `pack tracker disable` exactly 31 seconds after `init` exits could
  still hit the race window if propagation is unusually slow. The
  `--force` escape exists for advanced operators but masks the
  detection. **Mitigation:** Part 3 backstops Part 2; the skip-guard
  is content-aware (checks every issue), not time-based.
- **Part 3 (skip detection) DOES prove no silent data loss in the
  current execution path** — the test shows that any provider_get
  failure or unresolvable pack_id triggers a non-zero exit before
  any flat-file write. This is the ground-truth guarantee. The
  failure mode it cannot catch is one where every issue resolves
  cleanly but its CONTENT is stale (e.g., body fully populated but
  `state_reason` not yet propagated). For the current
  status-decoding logic, stale `state_reason` would still produce a
  valid (if possibly-wrong) v10 entry — not silent data loss, but
  potentially silent wrong-status. **Mitigation:** Part 1's
  close-count-stability poll is the upstream defense for this; if
  closed-count is stable, state_reason has propagated.
- **Test coverage limitation.** The new test is mock-based; a real
  end-to-end smoke test against a scratch GitHub repo (per the
  test-infra-self-provisioned rule) would add confidence but was
  not run because the prompt scoped against live `gh issue`
  mutations. Future BD-102 Phase B dog-food re-run is the practical
  validation.

**Summary judgment:** Silent data loss is now CONVERTED-TO-LOUD-FAILURE
in every code path the fix covers. Whether it is fully PREVENTED
depends on Part 1's heuristic holding in production; even when Part 1
fails, Part 2 and Part 3 ensure the user sees an explicit refusal +
diagnostic rather than a silently-truncated BACKLOG.md. This satisfies
the BD-132 success criterion's middle tier ("refuses to proceed with
a clear message" — acceptable: explicit failure beats silent loss)
and reaches for the top tier ("reconstructs all entries cleanly")
when the wait succeeds.

