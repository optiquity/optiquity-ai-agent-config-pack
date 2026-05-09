# IMPLEMENTATION REPORT — BD-133 (reverse migration preserves BACKLOG.md header preamble)

**BD:** BD-133 (D-6, MAJOR — surfaced by BD-102 Phase A dog-food).
**Branch:** `v11-dev`
**Implemented at HEAD:** `1bdd1f5` (working-tree state at handoff to Pack Chat).
**Author:** pack-coder (this report content reconstructed by Pack Chat from
the agent's final summary; agent declined to Write the report file claiming
a system instruction blocked it — a hallucination; content is verbatim
from the agent's response, captured here for audit-trail consistency).

---

## Summary

Reverse migration now preserves the BACKLOG.md header preamble byte-identical
across N round-trips. Implementation: option (b) — sidecar storage in a new
focused module (`scripts/lib/tracker-header-snapshot.sh`). The snapshot file
lives at `<repo-root>/.pack-tracker/backlog-header.snapshot` alongside
`id-map.json`. First-write-wins semantics guarantee subsequent reverses
don't degrade or replace the preamble. Trivial preambles (whitespace-only
or just a bare `# BACKLOG` title from a prior reverse) are not snapshotted,
preventing bootstrap from a never-had-preamble repo locking in a bad value.

Approach (a) — forward-time checkpoint snapshot — was rejected because it
would have required editing `scripts/lib/tracker-migrate-forward.sh`, which
BD-131 owns in this same batch (Batch 9). The sidecar approach lives
entirely in reverse + a new module and avoids any cross-BD file conflict.

## File changes

| File | Change | Notes |
|---|---|---|
| `scripts/lib/tracker-header-snapshot.sh` | **NEW** | Three functions: `tracker_header_snapshot_path`, `tracker_header_snapshot_capture`, `tracker_header_snapshot_apply`. Atomic write via `mktemp + mv`. |
| `scripts/lib/tracker-migrate-reverse.sh` | +31 lines | Source guard for the new module + capture call before `_tmr_emit_backlog` + apply call after emit. Lazy source so existing tests that source reverse.sh pick up the new module without changes. |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | **NEW** | 30 asserts across 4 groups (see Verification). |

**BD-131 files untouched:** `scripts/lib/tracker-migrate-forward.sh` and
`scripts/tests/tracker-migrate-forward-test.sh` retain their BD-131 diffs
exactly. Verified by reading `git diff --stat`.

## Module API

```
tracker_header_snapshot_path <repo-root>            # echoes the snapshot file path
tracker_header_snapshot_capture <repo-root>          # captures preamble (no-op if snapshot exists OR preamble is trivial)
tracker_header_snapshot_apply <repo-root> <out-file> # prepends snapshot to <out-file> if snapshot exists
```

Preamble = everything in the BACKLOG.md before the first line matching
`^\*\*BD-NNN — `, `^\*\*TD-NNN — `, or `^\*\*phase-N`. The snapshot is
captured exactly as bytes (no trimming, no normalization).

Trivial preambles (whitespace-only, or `# BACKLOG\n` alone) are skipped to
prevent first-reverse-after-prior-reverse from locking in a degraded value.

## Verification

**Validator:** `python3 scripts/validate-pack.py` → PASSED — all 28 checks clean.

**New round-trip test** (`scripts/tests/tracker-bd133-header-preservation-test.sh`) — **30/30 PASS**:
- **Group 1** (module API isolation): substantive capture, first-write-wins,
  trivial-preamble skip, missing-BACKLOG no-op, apply preserves snapshot +
  entries with single title line, apply no-op when snapshot absent.
- **Group 2** (reverse-only round-trip): pre-seeded mapping + sentinel
  preamble, one reverse cycle, post-reverse preamble byte-equal to
  original.
- **Group 3** (full forward → reverse round-trip via stateful fake gh, with
  `--disable` flip + `force=1` to bypass BD-132 freshness window): preamble
  byte-equal to original.
- **Group 4** (multi-cycle stability): 5 consecutive reverses, preamble
  byte-equal each cycle, snapshot file equals original preamble, exactly
  one title line at end.

**Existing test suites — all green, no regressions:**
- `scripts/tests/tracker-migrate-reverse-test.sh` — 93/93
- `scripts/tests/tracker-migrate-roundtrip-test.sh` — 39/39
- `scripts/tests/tracker-migrate-forward-test.sh` — 126/126 (BD-131 work intact)
- `scripts/tests/tracker-bd132-race-test.sh` — 29/29
- `scripts/tests/tracker-bd129-gh-repo-test.sh` — 11/11
- `scripts/tests/tracker-bd130-doctor-wired-test.sh` — 8/8

## Working-tree state at handoff

Modified: `scripts/lib/tracker-migrate-reverse.sh`
New: `scripts/lib/tracker-header-snapshot.sh`, `scripts/tests/tracker-bd133-header-preservation-test.sh`

BD-131 files (modified by BD-131, untouched by BD-133): `scripts/lib/tracker-migrate-forward.sh`, `scripts/tests/tracker-migrate-forward-test.sh`.

No git state changes performed. BD-133 status not flipped (Pack Chat owns).

## Deferred / open items

None. The fix is self-contained within the reverse path + the new module.
The first-write-wins semantics handle multi-cycle round-trips correctly.

## Risks

- **Snapshot drift across pack versions.** If a future pack release changes
  the BACKLOG.md preamble shape (e.g., adds a new "How to use this file"
  section), existing snapshots would lock in the older shape. Acceptable for
  v11.0 — the preamble is stable across the v10→v11 → v12 expected window.
  If becomes a problem, a `--refresh-snapshot` operator flag would address.
- **Pre-existing snapshot from a non-pack source.** If a user manually
  drops a `backlog-header.snapshot` file with arbitrary content, reverse
  would prepend that. Low risk — the sidecar dir is `.pack-tracker/` which
  is operator-owned anyway.

## Definition of Done

- [x] Reverse round-trip preserves BACKLOG.md header byte-identical
- [x] Multi-cycle (N=5) round-trips don't degrade the preamble
- [x] Validator PASS (28 checks)
- [x] All existing test suites green (no regressions)
- [x] New round-trip test added (30/30)
- [x] BD-131 forward.sh files untouched (no batch conflict)
- [x] BD-133 status not flipped (Pack Chat owns)
