# IMPLEMENTATION-REPORT-BD-131.md

BD-131 — Set `forward_complete = true` at end of clean forward
migration; document partial-create vs partial-close semantics.

- **Branch:** `v11-dev`
- **Worktree HEAD on entry:** `1bdd1f5421be5acab3e7e6a1c38b265a8b67d93d`
- **Worktree HEAD on exit:** `1bdd1f5421be5acab3e7e6a1c38b265a8b67d93d`
  (no commits — pack-coder cannot commit; Pack Chat owns staging)
- **Files modified:** 2 (no new files, no deletions)

---

## Summary

The `tracker_migrate_forward_run` orchestrator now writes
`tracker.toml [migration].forward_complete` with caller-decided
semantics — `true` on a clean create surface (every BACKLOG entry
+ phase epic produced a usable gh id), `false` on any
provider_create failure. Partial-CLOSE failures still flip to
`true` because the create surface is the strong signal for
`tracker_mode()` resolution; close-on-Resolved is a best-effort
post-create step (and BD-134 lands the retry-with-backoff that
drives the residual to ~0). A defensive read-back verification
emits a stderr WARN if the on-disk value disagrees with what we
just wrote — this catches any future regex regression in the
writer (the BD-131 surface mode), so `tracker_mode()` cannot
silently route to flat-file after a clean forward.

The existing writer was already correct for the clean-create case
(reproduced locally: forward run with partial closes → writer
fires → `forward_complete = true`), but the contract was
**implicit**: it depended on the call site only being reachable
when all creates succeeded. BD-131 codifies the contract
**explicitly** — a tracked `creation_ok` flag at the orchestrator
level, an explicit value parameter on the writer, defensive value
validation, and a read-back verifier — so future refactors that
elect to continue past a create failure cannot silently regress
the semantics.

---

## Where the fix landed

### Orchestrator surface

`scripts/lib/tracker-migrate-forward.sh::tracker_migrate_forward_run`

- New local: `creation_ok=1` declared near the top of the function,
  immediately after the partial-failures tempfile setup.
- Set to `0` immediately before each of the two `provider_create`
  early-return paths (entry create at the per-entry loop; phase
  epic create at the per-phase loop). Both paths still
  early-return; the explicit zero-set is a future-proof invariant
  for any refactor that converts the early-return into a
  continue-on-failure model.
- At step 11, the orchestrator computes `fc_value="true"|"false"`
  from `creation_ok` and passes it as the new second positional
  arg to `_tmf_update_tracker_toml`. Then it calls the new
  `_tmf_verify_forward_complete` helper to read back the value (a
  read-back failure produces a stderr WARN but does NOT abort the
  run — the mapping + closes already landed; the operator gets
  the WARN and can re-run init to recover).

### Writer surface

`scripts/lib/tracker-migrate-forward.sh::_tmf_update_tracker_toml`

- Now accepts a second positional arg `fc` whose value is written
  for `forward_complete`. Defaults to `"true"` to preserve
  pre-BD-131 behavior at every existing call site (none in the
  pack repo currently omit it after this change, but the default
  guarantees backward compatibility for any out-of-tree caller).
- Defensive: rejects any value other than `"true"` or `"false"`
  with a stderr WARN and `return 1` (does not write). Prevents
  out-of-schema strings from corrupting `tracker_mode()`
  resolution.
- Updated header docstring explicitly states the BD-131 semantics:
  `forward_complete = true` means "all issues created"
  (the strong signal for `tracker_mode()`), NOT "all closes
  succeeded" (BD-134's concern).

### New helper

`scripts/lib/tracker-migrate-forward.sh::_tmf_verify_forward_complete`

Reads back `migration.forward_complete` from the on-disk
tracker.toml via `tracker_config_get` and compares to the
expected value. Returns 0 on match, 1 on mismatch (with stderr
WARN naming expected vs actual). No-op (rc=0) when the cfg path
is absent — it's a best-effort safety net, not a hard
precondition.

---

## Implementation choice — semantics of `forward_complete = true`

Per the BD-131 prompt and the BD entry's recommendation:

| Outcome | `forward_complete` after step 11 |
|---|---|
| All creates succeeded, all closes succeeded | `true` |
| All creates succeeded, **some closes failed** | `true` (BD-131 contract — close failures are best-effort, do not degrade the create surface) |
| **Any create failed** (entry or phase epic) | `false` (early-return at the create site; step 11 never runs) |

Rationale (also embedded in the writer's header docstring): the
create surface is the strong signal for `tracker_mode()`. A
`forward_complete = false` after a partial-CLOSE run would
silently route downstream tooling to flat-file mode despite a
fully-mapped tracker — defeating the opt-in. BD-134 lands the
close retry-with-backoff that drives the residual to ~0, so the
partial-close window is being closed independently. Conversely, a
partial-CREATE run produces an incomplete mapping (missing entries
have no gh id), so routing downstream tooling to tracker mode
against that mapping would silently lose entries on the next
read; `false` keeps the operator on flat-file until a re-run
(`pack tracker init --resume`) completes the create surface.

---

## How verified

### Validator

```
python3 scripts/validate-pack.py
→ PASSED — all checks clean (28 checks)
```

### Test suites — every one named in the success criteria

| Suite | Result |
|---|---|
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | 11/11 PASS |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | 8/8 PASS |
| `scripts/tests/tracker-bd132-race-test.sh` | 29/29 PASS |
| `scripts/tests/tracker-migrate-forward-test.sh` | **126/126 PASS** (was 111; +15 new tests) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 93/93 PASS |

### Additional tracker test suites (not in success criteria, run as
collateral-regression check)

| Suite | Result |
|---|---|
| `scripts/tests/tracker-config-test.sh` | 32/32 PASS |
| `scripts/tests/tracker-init-test.sh` | 95/95 PASS |
| `scripts/tests/tracker-errors-test.sh` | 60/60 PASS |
| `scripts/tests/tracker-provider-test.sh` | 65/65 PASS |
| `scripts/tests/tracker-agent-read-test.sh` | 31/31 PASS |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 39/39 PASS |

### New tests added (in `tracker-migrate-forward-test.sh`)

**Group 4.3 extension** — 1 new assertion:

- `4.3 BD-131 forward_complete=true after partial-close (creates
  clean)`: after a forward run where every create succeeds but
  every close fails (fake gh `issue close` exits 1), tracker.toml
  reads `forward_complete = true`. Asserts the BD-131 contract
  that close failures do not degrade the create surface.

**New Group 5 — BD-131 forward_complete write semantics** — 14 new
assertions across 3 sub-groups:

- **5.1** — `_tmf_update_tracker_toml` round-trip with `"true"`
  and `"false"` arg; default-arg behavior; `5.1c` rejection of
  unexpected values with stderr WARN.
- **5.2** — `_tmf_verify_forward_complete` match → rc=0; mismatch
  → rc=1 + stderr WARN; missing cfg → rc=0 (no-op).
- **5.3** — Full integration: fake gh exits 1 on the 4th `issue
  create`. Asserts (a) forward returns rc=1 (early-return at the
  create site), (b) tracker.toml's `forward_complete` stays at
  the init-time `false` (so `tracker_mode()` keeps resolving to
  flat-file per V1 §3.2), (c) the partial mapping is still
  persisted (Finding #7 invariant — the resume seed survives).

### Local manual reproduction (pre-fix)

Before changes, with python3 on PATH, ran the partial-close
scenario manually against the test fixture:

```
=== EXIT 1 ===
[migration]
forward_complete = true        ← writer DOES flip on partial-close (existing
mapping_file = ".pack-tracker/id-map.json"   behavior matches BD-131 contract)
last_forward_run = "..."
```

So the writer was already correct in the test environment. The
user-reported "forward_complete = false after init" surface (BD
description) is most likely either (a) python3 not on PATH at
the time of the run (would silently fail — the writer's python
heredoc errors out on `python3: command not found`), or (b) a
silent regex regression in some intermediate code state we no
longer have. The BD-131 read-back verifier (`_tmf_verify_forward_complete`)
catches both classes — a missing python3 produces an empty
read-back which mismatches `"true"`, and any future regex
regression produces a visible WARN at the operator's terminal
instead of silent flat-file routing downstream.

---

## Files modified

| Path | Change | Line delta |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +102 / -9 |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +202 / -0 |

**Inventory:** 2 modified, 0 new, 0 deleted.

### Per-file change summary — `scripts/lib/tracker-migrate-forward.sh`

1. `tracker_migrate_forward_run`:
   - Added `local creation_ok=1` near top of function (just after
     `partial_failures` tempfile setup).
   - Added `creation_ok=0` line before the entry-create early-return
     and the phase-epic-create early-return.
   - Step 11 now branches on `creation_ok` to compute `fc_value`,
     passes it to `_tmf_update_tracker_toml`, then invokes the new
     `_tmf_verify_forward_complete` helper.
2. `_tmf_update_tracker_toml`:
   - Now accepts second positional arg `fc` (default `"true"`).
   - Defensive value-validation (rejects anything other than
     `"true"` / `"false"` with stderr WARN + rc=1, no write).
   - Python heredoc takes `fc` as `sys.argv[3]`.
   - Updated header docstring with the BD-131 contract.
3. **NEW** function `_tmf_verify_forward_complete`:
   - Reads back the on-disk value via `tracker_config_get`,
     compares to expected, emits stderr WARN on mismatch, returns
     0/1.

### Per-file change summary — `scripts/tests/tracker-migrate-forward-test.sh`

1. Group 4.3: 1 new assertion verifying tracker.toml
   `forward_complete = true` after a partial-close run.
2. **NEW** Group 5 (BD-131 forward_complete write semantics) —
   sub-groups 5.1 (writer round-trip + arg defaults +
   value-validation), 5.2 (verifier helper), 5.3 (full integration
   test of partial-CREATE → forward_complete stays false).

---

## Plan deviations

**None.** The fix landed exactly where the BD-131 prompt
recommended (the post-forward `tracker.toml` write site in
`tracker-migrate-forward.sh`). The semantics chosen match the
prompt's recommended defaults verbatim:

- "all issues created" → `true`
- "any issue creation failed" → `false`
- partial closes → `true` (deferred to BD-134's retry-with-backoff)

---

## New POQs introduced

**None.** The bug surface, the fix site, and the semantics were
all unambiguous from the BD-131 description.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| After `tracker_migrate_forward_run` completes successfully, `tracker.toml [migration] forward_complete` reads `true` | PASS — Group 4.3 + Group 3.7b assert this |
| After a forward run with any issue-creation failure, `forward_complete` remains `false` | PASS — Group 5.3 asserts this |
| `python3 scripts/validate-pack.py` PASSES — all 28 checks clean | PASS |
| `bash scripts/tests/tracker-bd129-gh-repo-test.sh` (11/11) | PASS |
| `bash scripts/tests/tracker-bd130-doctor-wired-test.sh` (8/8) | PASS |
| `bash scripts/tests/tracker-bd132-race-test.sh` (29/29) | PASS |
| `bash scripts/tests/tracker-migrate-forward-test.sh` (was 111/111) | PASS — now 126/126 |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` (93/93) | PASS |
| Add a test that asserts `forward_complete = true` after a clean forward | PASS — 4.3 + 3.7b cover clean-creation paths |
| Add a test that asserts `forward_complete = false` after partial-creation | PASS — Group 5.3 |
| BD-131 status NOT flipped (Pack Chat owns) | PASS — BACKLOG.md untouched |
| No PM-only files modified | PASS — only the two scripts above |
| No state-changing git verbs run | PASS — only `git status` / `git diff` / `git rev-parse` |
| Trinity files untouched | PASS — no CLAUDE.md / AGENTS.md / GEMINI.md edits |
| BD-129 / BD-130 / BD-132 work preserved | PASS — all three test suites still green |
| BD-133 territory untouched | PASS — `scripts/lib/tracker-migrate-reverse.sh` unmodified |

---

## Working-tree state (final)

```
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
	modified:   scripts/lib/tracker-migrate-forward.sh
	modified:   scripts/tests/tracker-migrate-forward-test.sh

no changes added to commit (use "git add" and/or "git commit -a")
```

---

## Deferred items

**None.** BD-131 scope is fully addressed. The adjacent BD-133
(reverse.sh header-preamble preservation) and BD-134 (close
retry-with-backoff) are intentionally out-of-scope per the
prompt's "Coordinate with BD-133" + "BD-134 territory" guidance.

---

## Notes for Pack Chat

- The BD-131 fix is primarily a **codification + defense-in-depth**
  pass. The pre-fix code was functionally correct in every
  reproducible scenario (verified locally — partial-close run
  flipped `forward_complete = true` as the BD contract specifies).
  The user-reported "forward_complete = false after init" surface
  was not reproducible from the pack repo's current code; the
  BD-131 changes nonetheless lock the contract behind explicit
  call-site tracking, an explicit value parameter on the writer,
  defensive value validation, and a read-back verifier — so any
  future regression (regex change, python3 missing on PATH,
  call-site refactor) becomes loud-failure instead of silent
  flat-file routing.
- 15 new test assertions land with this BD; all green. Total
  forward-test count: 111 → 126.
- Suggested commit message:
  `feat: v11 — BD-131 explicit forward_complete write semantics + read-back verify`
