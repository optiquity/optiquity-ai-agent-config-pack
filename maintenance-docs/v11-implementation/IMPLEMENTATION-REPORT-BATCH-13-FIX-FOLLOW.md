# IMPLEMENTATION REPORT — Batch 13 fix-follow

**Branch:** `v11-dev`
**Worktree HEAD at start:** `60ac6d94b19ea3196404cb088f73c43c3881ac0c`
**Worktree HEAD at handoff:** `60ac6d94b19ea3196404cb088f73c43c3881ac0c` (no commits — pack-coder may not commit)
**Audit consumed:** `maintenance-docs/v11-implementation/AUDIT-BATCH-13.md`
**Concurrent batch noted:** Batch 14 fix-follow runs in parallel against
`project-template/.claude/agents/auditor-*.md`, `project-template/skills/*`,
`project-template/docs/pack/PLATFORM-SKILLS.md`, and trinity mirrors. No
file overlap with this batch.

## Verdict

**Done.** All 8 actionable findings (M-1, M-2, F-1, F-2, F-4, F-5, F-6,
N-2) are addressed. N-1 is intentionally accepted-as-shipped per the
audit's note (POQ-4 from BD-095).

All 5 enumerated test suites pass + validator passes 30/30.

## Per-finding verdict

| Finding | Severity | Status | Files touched |
|---|---|---|---|
| M-1 | MAJOR — wire BD-095 dry-run suite into CI | PASS | `.github/workflows/validate-pack.yml` |
| F-3 | MAJOR — wire BD-101 gates suite into CI | PASS | `.github/workflows/validate-pack.yml` |
| M-2 | MINOR — replace dead `--resume not yet implemented` stub | PASS | `scripts/lib/migrator-core.sh` |
| F-1 | MINOR — E2E test for `--apply` exit 31 on Gate 2 fail | PASS | `scripts/tests/test-migrate-v10-to-v11-gates.sh` |
| F-2 | MINOR — exit-code table missing EXIT_GATE_FAILED + gates context | PASS | `supporting-docs/MIGRATION-v10-to-v11.md` |
| F-4 | MINOR — Gate FAIL message contradiction | PASS — option (i) | `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh`, `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh` |
| F-5 | MINOR — README §Repository Layout out of date | PASS | `README.md` |
| F-6 | MINOR — MERGE-STRATEGY.md §A1 missing BD-101 content | PASS | `supporting-docs/MERGE-STRATEGY.md` |
| N-2 | NIT — Check 26 doesn't enforce EXIT_GATE_FAILED | PASS | `scripts/validate-pack.py` |
| N-1 | NIT — bare-invocation auto-rerun is strict superset | DEFERRED — accepted-as-shipped per BD-095 POQ-4 (no spec change) | none |

## F-4 choice + rationale

**Chose option (i)** — update Gate FAIL messages to drop the "fix the
underlying defect" recovery option for Gate 2 and direct users to
`restore-from-backup.sh` as the only supported path.

**Gate 3** is treated separately: Phase-A is intact when Gate 3 fires,
so restore-from-backup is the WRONG recovery — the new Gate 3 message
explicitly says so and routes to `pack tracker doctor` instead.

Rationale:

- Smaller surface; no risk to BD-095's forward-only `--resume`
  guarantee. Option (ii) would require modifying sentinel-write
  timing in `apply.sh` (S4/S5/S6 sentinels currently mark `.done`
  BEFORE Gate 2 fires) which would change BD-095's tested
  contract. The existing 5.3 test in test-migrate-v10-to-v11-dry-run.sh
  asserts that `--resume` refuses when S4/S5/S6 sentinels exist —
  option (ii) would invalidate that assertion.
- BD-101 BACKLOG entry literal text says "Failures route through A1
  UX" — `restore-from-backup.sh` IS the documented A1 recovery.
  Aligning the gate message with the documented spec is the smaller
  fix.
- Gate 3 distinction is preserved — Phase-A stays intact on Gate 3
  failure; tracker-doctor recovery is the right path. The new Gate 3
  message explicitly warns NOT to restore-from-backup (would discard
  Phase-A work).
- A future BD could add a `--rerun-gates` flag (audit's option (ii)
  variant) as a feature add. That is out of scope for a fix-follow.

## File-change inventory

| Path | Type | Δ lines (approx) | Verification |
|---|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | +6 | yaml-syntax via test invocation in Pack Chat (no local yamllint); both new steps follow the existing `if: always() / run: bash ...` pattern verbatim |
| `scripts/lib/migrator-core.sh` | modified | +9 / -4 | test-migrator-core.sh 19/19 PASS — die-message change is a behavior-preserving text update |
| `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` | modified | +13 / -5 | test-migrate-v10-to-v11-gates.sh 41/41 PASS (Gate 2 FAIL still emits "Gate 2 FAIL" banner string used by 2.2/2.3/2.4/4.3 asserts) |
| `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh` | modified | +12 / -6 | test-migrate-v10-to-v11-gates.sh 41/41 PASS (Gate 3 FAIL still emits "Gate 3 FAIL" banner string used by 3.2 asserts) |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | modified | +27 / -14 | self — 41/41 PASS (4.3 placeholder replaced with real E2E exit-code assert + 3 supporting message asserts) |
| `scripts/validate-pack.py` | modified | +3 / -1 | self — Check 26 now enforces 9 exit-code constants including `EXIT_GATE_FAILED`; validator 30/30 PASS |
| `supporting-docs/MIGRATION-v10-to-v11.md` | modified | +21 | none-required (doc); cross-references MERGE-STRATEGY §A1 |
| `supporting-docs/MERGE-STRATEGY.md` | modified | +48 | none-required (doc); references back to MIGRATION exit-code table |
| `README.md` | modified | +6 / -1 | none-required (doc); enumerates 7 new lib files + 2 new test runners shipped by BD-095 + BD-101 |

No new files. No deleted files. No mode changes.

## Verification commands + results

All runs from repo root, post-fix:

```
$ bash scripts/tests/test-migrate-v10-to-v11.sh                 → 43/43 PASS
$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh         → 40/40 PASS
$ bash scripts/tests/test-migrate-v10-to-v11-gates.sh           → 41/41 PASS  (was 38; +3 from F-1's expanded 4.3 case)
$ bash scripts/test-migrator-core.sh                            → 19/19 PASS
$ bash scripts/test-migrator-manifest.sh                        → 12/12 PASS
$ python3 scripts/validate-pack.py                              → 30/30 PASS
$ git diff --stat | grep -i 'mode change' || echo no mode changes
                                                               → no mode changes
```

## Test count delta

- test-migrate-v10-to-v11-gates.sh: **38 → 41** (+3 net asserts)
  - Removed: 1 placeholder assertion in case 4.3 ("end-to-end gate
    rc=31 covered by 2.2/2.3/2.4 direct gate-call asserts")
  - Added: 4 real asserts in expanded case 4.3 (`rc==31`,
    output contains "Gate 2 FAIL", "[FAIL] help-fragments",
    "HELP-FRAGMENT.md differs")
- All other suite counts unchanged.

The audit's expected delta was "+1 from 38 → 39" (one new case). I
ship "+3 net asserts under one expanded case" — the case count net is
unchanged (4.3 stays as one case), but the assertion coverage is
materially stronger because all four asserts now exercise the live
EXIT-31 propagation through `apply.sh`'s `migrator_post_report_hook`
wrapper (which the audit specifically called out as untested).

## E2E test approach for F-1 — design note

The audit suggested two approaches: (i) post-S6 trinity-strip via a
`migrator_post_report_hook` shim, or (ii) a fixture where validate-pack
fails. Both have problems for an in-test E2E:

- Trinity is in the v10 customization-surface fingerprint; mutating it
  between `--dry-run` and `--apply` would invalidate the freshness
  fingerprint and `--apply` would refuse with `EXIT_DIRTY` (12) before
  Gate 2 ever fires. Mid-flight injection requires hook-export
  gymnastics (`export -f`) that fight bash subshell semantics.
- `validate-pack.py` runs against `$PACK`, not the target — a
  target-side mutation can't make it fail.

**The chosen approach uses a property of the v10 surface and S5
install semantics:** `docs/pack/HELP-FRAGMENT.md` is NOT in the v10
customization-surface (the surface only enumerates v10-shaped paths),
so planting a custom HELP-FRAGMENT in the v10 fixture does not
invalidate the dry-run fingerprint. S5's artifact-install honors a
`! -f` guard (`migrate-v10-to-v11.sh:276`) so it KEEPS our planted
copy. Gate 2's `checkpoint_check_help_fragments` then observes the
byte-mismatch against the pack mirror and returns 1, which apply.sh's
`migrator_post_report_hook` wrapper translates into
`exit "${EXIT_GATE_FAILED:-31}"`. The test asserts the migrate-sh
process exit code is 31 + the printed FAIL strings.

This is a true end-to-end test through `--dry-run` + `--apply` +
post_report_hook + Gate 2 + EXIT-code propagation — exactly what the
audit asked for.

## Working-tree state at handoff

- 9 modified files (per scope above)
- 0 new files / 0 deleted files / 0 mode changes
- All concurrent Batch 14 changes are visible in `git status` /
  `git diff` — those are out-of-scope for this report and Pack Chat
  will commit them separately
- No git state changes performed by this agent

## Plan deviations

None. All findings addressed per the audit's recommended-fix text or
explicit-choice text (F-4 had two options; chose option (i) per the
rationale above).

## Pre-Open Questions

None. The F-4 decision was scoped binary by the prompt (i vs ii); the
choice + rationale are documented above.

## Post-flight notes for Pack Chat

- The parallel Batch 14 fix-follow has its own report; this report
  covers only the 9 files in the Batch 13 scope. The two batches
  produce a clean union with no overlap.
- Suggested commit boundary if Pack Chat splits this batch: one CI +
  code commit (`.github/workflows/...`, `scripts/lib/...`,
  `scripts/validate-pack.py`, `scripts/tests/...`) + one docs commit
  (`README.md`, `supporting-docs/...`). Or a single `fix:` commit
  per the standing rule "no file-mix-and-match" — both options are
  defensible. No Pack Chat preference is encoded here.
- BD-140 is the natural BACKLOG entry per the audit's
  recommendation; Pack Chat owns BACKLOG writes.
