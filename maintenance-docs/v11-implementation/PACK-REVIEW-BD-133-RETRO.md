# PACK REVIEW — BD-133 (Retroactive, Batch 21c)

**BD:** BD-133 — Reverse migration preserves BACKLOG.md header preamble
**Original commit:** `c566c20` (combined with BD-131; only the BD-133
portion is in scope here)
**Author of original ship:** pack-coder (May 9 2026)
**Reviewer:** pack-reviewer (retrospective, Batch 21c, May 15 2026)
**Outcome:** Clean ship overall; the implementation correctly closes the
D-6 dog-food finding. **3 SHOULDs + 2 NITs** identified that the original
review pass missed; no MUSTs.

---

## Files in scope

Exactly the BD-133 portion of `c566c20`:

- **NEW** `scripts/lib/tracker-header-snapshot.sh` (+267 lines) — three-
  function sidecar module: `tracker_header_snapshot_path` /
  `tracker_header_snapshot_capture` / `tracker_header_snapshot_apply`;
  internal helpers `_ths_extract_preamble` / `_ths_preamble_is_substantive`.
- **MOD** `scripts/lib/tracker-migrate-reverse.sh` (+31 lines) — source
  guard for the new module + capture call before `_tmr_emit_backlog`
  (line 1087) + apply call after emit (lines 1097–1099).
- **NEW** `scripts/tests/tracker-bd133-header-preservation-test.sh`
  (+554 lines) — 30 asserts in 4 groups (module API, reverse-only,
  full forward→reverse, multi-cycle stability N=5).
- `IMPLEMENTATION-REPORT-BD-133.md` (now archived at
  `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-133.md`).

Out of scope (BD-131 portion of the same commit): `tracker-migrate-
forward.sh` `forward_complete` work + the BD-131 portion of
`tracker-migrate-forward-test.sh` (Group 5 + 4.3 add-on).

---

## What the implementation got right

Acknowledged before the findings, per the review skill:

1. **Cleanly bounded module.** New file is the right factoring — three
   public functions with a narrow contract, well-commented header,
   no leakage into the existing reverse path beyond two call sites.
2. **Atomic capture write.** `mktemp + mv` (line 184/203) gives an
   atomic snapshot rename even if reverse is interrupted mid-write.
3. **Substantive predicate is the right shape.** Stripping whitespace +
   `re.fullmatch(r'#\s*BACKLOG\s*', stripped, re.IGNORECASE)` correctly
   classifies the bare entries-only emitter output as "trivial" and
   refuses to capture it (lines 138–144) — without that guard, the
   first-write-wins property would lock in `# BACKLOG\n\n` after a
   prior reverse erased the user's preamble.
4. **First-write-wins is correctly enforced.** Test 1.2 explicitly
   verifies the second-call no-op semantic (lines 117–136).
5. **Composable with the mirror-header pipeline.** Reverse calls in
   strict order: `header_snapshot_capture` (1087) → `_tmr_emit_backlog`
   (1090) → `header_snapshot_apply` (1098) → ... →
   `tracker_mirror_header_strip` (1110). The snapshot may include the
   leading `<!-- ... -->` mirror-header bytes (because capture happens
   before any in-place strip), and the later mirror-strip cleans them
   up. The composition produces the right output across both initial
   and N≥2 cycles.
6. **Composable with BD-111.** BD-111's reverse-decoder retrofit
   operates inside `_tmr_decode_blockers` (per-issue blocker
   reconstruction); the header snapshot operates on the BACKLOG.md as
   a whole. Orthogonal axes — verified by reading both code paths;
   no shared state, no shared file region. The snapshot path is fully
   compatible with the post-BD-111 first-class GH dependency edges
   work.
7. **Atomicity-gate awareness.** The apply call is gated on
   `emit_failed=0` (line 1097) so a failed emit doesn't leave a
   half-applied file; the existing backup_dir restore-on-failure
   path (lines 1117–1133) brings back the original BACKLOG.md
   (preamble intact) without needing the snapshot to participate.
8. **Multi-cycle stability proven.** Group 4 (N=5 cycles) demonstrates
   the fixed-point property — the preamble does not degrade across
   repeated reverses, and the snapshot file is byte-equal to the
   original preamble after N rounds (test 4.3).
9. **Edge cases handled.** Tests 1.4 (missing BACKLOG.md → no-op) and
   1.6 (apply with no snapshot → no-op) confirm the no-crash contract.
10. **Test asymmetry is justified.** 554 test lines for 31 reverse-side
    lines + 267 module lines (1.86:1 test-to-impl ratio) is appropriate
    for a silent-data-loss surface. The 30 asserts give meaningful
    coverage of API isolation, reverse-only round-trip, full
    forward→reverse round-trip, and multi-cycle stability — all four
    distinct axes of the regression surface.

---

## Findings

Numbered by severity (SHOULD before NIT). Each finding includes
location, description, rationale, and concrete fix.

### F1 — SHOULD: Snapshot is never refreshed across user edits to the preamble

**Location:** `scripts/lib/tracker-header-snapshot.sh:161–206`
(`tracker_header_snapshot_capture`); enforced by test 1.2 lines
117–136.

**Description.** `tracker_header_snapshot_capture` returns no-op once
`<repo-root>/.pack-tracker/backlog-header.snapshot` exists. There is
no operator-facing affordance to refresh the snapshot when the user
genuinely edits the preamble between cycles. The user-edit-between-
cycles scenario:

1. `pack tracker init` (forward writes mirror header on top of
   user preamble + entries).
2. `pack tracker disable` (capture stores the preamble; apply restores
   it; mirror-strip cleans up). BACKLOG.md preamble = original.
3. User edits BACKLOG.md preamble in flat-file mode — adds a new
   `## How to use this file` subsection, fixes a typo, etc.
4. `pack tracker init` again — forward writes mirror header on the
   edited preamble.
5. `pack tracker disable` again — snapshot already exists from step 2
   (capture is no-op). Apply restores the **stale** preamble.
6. **The user's step-3 edits are silently discarded.**

**Why this matters.** V1 §6.3 declares BACKLOG.md a "read-only mirror"
in tracker mode (the mirror-header HTML comment says "Direct edits
will be overwritten"), so for users who fully respect that contract
the issue never surfaces. But "flat-file mode" in step 3 is
**explicitly authoritative** — the user is invited to edit. Their
preamble edits should round-trip on the next init→disable cycle, just
as their entry edits do.

**Why it's SHOULD, not MUST.** The implementation report's "Risks"
section partially anticipates the analogous case ("Snapshot drift
across pack versions"). The semantic is documented in the source
header comments (lines 20–26) and explicitly tested (1.2). So this is
a deliberate tradeoff against the "snapshot eats itself" failure
mode, not an oversight. But the tradeoff was made without a user-
facing escape hatch.

**Concrete fix (one of three, listed by ascending invasiveness):**

1. **Document the limitation in the implementation report's Risks
   section.** Add a third bullet enumerating the user-edit-between-
   cycles case and direct users to delete
   `.pack-tracker/backlog-header.snapshot` to refresh. Also surface
   this in `pack help` or a future `pack tracker doctor`-style hint.
2. **Refresh-only-when-substantive-and-different.** Replace the
   blanket no-op-if-snapshot-exists check with: extract candidate;
   if substantive AND not byte-equal to current snapshot, replace.
   This still avoids the "bare `# BACKLOG` eats the snapshot" failure
   mode (substantive predicate refuses) but picks up genuine user
   edits. Risk: if a future emitter writes a substantive-but-still-
   bad preamble (e.g., an apology comment), the snapshot would be
   degraded.
3. **Add a `--refresh-snapshot` operator flag** to `pack tracker
   disable` that explicitly recaptures. Conservative; no
   behavior change for non-flag callers.

Recommended for v11.0: option 1 (docs only). Option 2 should be
considered for v11.1 with explicit test coverage of the
substantive-but-bad case.

---

### F2 — SHOULD: Test "byte-equal" assertions actually verify "equal modulo trailing newlines"

**Location:** `scripts/tests/tracker-bd133-header-preservation-test.sh`
lines 268, 285, 439, 460, 509, 522.

**Description.** Three test groups (G2, G3, G4) extract preambles via
command substitution:

```bash
ORIGINAL_PREAMBLE=$(_ths_extract_preamble "$REPO/BACKLOG.md")
# ... reverse runs ...
POST_PREAMBLE=$(_ths_extract_preamble "$REPO/BACKLOG.md")
[[ "$ORIGINAL_PREAMBLE" == "$POST_PREAMBLE" ]] && t_pass "byte-equal"
```

Bash `$(...)` strips **trailing newlines** from the captured value.
So if the on-disk preamble post-reverse ends with `\n\n\n` while the
original ended with `\n\n`, both `ORIGINAL_PREAMBLE` and
`POST_PREAMBLE` would be assigned identical strings (both stripped to
the same content) and the assertion would PASS — even though the
files differ by one trailing newline.

The BD-133 commit message and the BACKLOG `Resolved:` line both make
the **byte-identical** claim. The test as written cannot reject a
trailing-newline drift.

**Why this is SHOULD.** Functional correctness is uncompromised
(trailing-newline differences are visually invisible and don't change
markdown rendering). But the regression-test contract should match the
documentation contract.

**Concrete fix.** Replace the `$(...)` extraction with a direct
file-vs-file diff:

```bash
_ths_extract_preamble "$REPO/BACKLOG.md" > "$WORK/post.preamble"
_ths_extract_preamble "$ORIGINAL_BACKLOG" > "$WORK/orig.preamble"
if cmp -s "$WORK/orig.preamble" "$WORK/post.preamble"; then
    t_pass "post-reverse preamble byte-equal to original"
else
    t_fail "..."
fi
```

`cmp -s` is byte-exact and would catch any trailing-newline drift.

---

### F3 — SHOULD: New `.pack-tracker/` sidecar file is not documented in ARCHITECTURE-V3

**Location:** `maintenance-docs/v11-research/ARCHITECTURE-V3.md`
(enumerates `.pack-tracker/recommendation-state.json` at §28.1.4 and
elsewhere; no mention of `backlog-header.snapshot`); also
`scripts/lib/tracker-doctor.sh:41` (only knows about `id-map.json`).

**Description.** ARCHITECTURE-V3 carefully enumerates which files
live under `.pack-tracker/` and explicitly documents the
recommendation-state file's purpose, schema, and gitignore status.
The new `.pack-tracker/backlog-header.snapshot` introduced by BD-133
is undocumented in the architecture corpus — only the source-file
header comment and the implementation report describe it. A future
reader of ARCHITECTURE-V3 would be unable to enumerate the full
sidecar surface.

**Why SHOULD, not MUST.** The file is functionally correct and lives
in the gitignored `.pack-tracker/` directory. No external system
depends on its presence/format. But the architecture doc's role is to
be the authoritative enumeration of the sidecar surface, and BD-133
silently expanded that surface.

**Concrete fix.** Add a one-paragraph entry to ARCHITECTURE-V3
near §28.1.4 (or a new sub-section under §6.5/§6.6) describing:

- File path: `<surface-root>/.pack-tracker/backlog-header.snapshot`.
- Purpose: per-surface preamble preservation across reverse round-
  trips.
- Lifecycle: created on first reverse where the BACKLOG.md preamble
  is substantive; never refreshed (first-write-wins); deleted only by
  manual operator action.
- Gitignore status: covered by the existing `.pack-tracker/` rule
  (no new `.gitignore` line needed).
- Cross-reference to `scripts/lib/tracker-header-snapshot.sh`.

---

### F4 — NIT: Test reaches into private helper `_ths_extract_preamble`

**Location:** `scripts/tests/tracker-bd133-header-preservation-test.sh`
lines 268, 285, 439, 460, 509, 522 (same six call sites as F2).

**Description.** The test sources `tracker-header-snapshot.sh` and
calls the underscore-prefixed internal helper `_ths_extract_preamble`
to compare original vs. post-reverse preambles. The underscore-prefix
convention in this codebase (consistent with `_tmf_*` / `_tmr_*` /
`_ths_*` patterns) signals "private". Tests reaching past the public
API binds the test to the implementation, not the contract. If a
future refactor inlines or renames `_ths_extract_preamble`, the test
will break for reasons unrelated to the regression it guards.

**Why NIT.** Functional behavior unaffected. Convention-only concern.

**Concrete fix.** Either (a) promote `_ths_extract_preamble` to public
(`tracker_header_snapshot_extract_preamble`) since it's evidently
useful as a building block; or (b) inline the regex in the test
itself (small Python here-doc, ~5 lines) so the test is self-
contained. Option (a) is preferred because the helper is genuinely
small and likely useful for future call sites (e.g., `pack tracker
doctor` snapshot-vs-current drift check).

---

### F5 — NIT: Snapshot may persistently store a stale mirror-header HTML comment

**Location:** `scripts/lib/tracker-header-snapshot.sh:92–113`
(`_ths_extract_preamble`) + `scripts/lib/tracker-migrate-reverse.sh`
ordering (capture at 1087, mirror-strip at 1110).

**Description.** When BD-133 capture runs against a tracker-mode
BACKLOG.md (which has the V1 §6.3 mirror-header HTML comment block
at top), the captured preamble bytes include that mirror header. The
`# Backlog` user title comes after it. The first-write-wins rule
means the captured mirror-header bytes (including the
`Last regenerated: <timestamp>` line) are persisted for all subsequent
cycles. They get re-prepended on every apply, then stripped by
`tracker_mirror_header_strip` — so the on-disk BACKLOG.md is correct,
but the on-disk **snapshot file** persistently contains a stale
timestamp.

**Why NIT.** Functionally invisible (the mirror-strip cleans every
cycle); only visible if a developer inspects the snapshot file. The
"stale timestamp" is meaningless in any operational sense.

**Concrete fix.** Strip a leading `<!-- ... -->` block in
`_ths_extract_preamble` before writing the snapshot. Two-line python
addition; tests 1.1 and 1.5 wouldn't change behavior because they
don't include a mirror header in their fixtures, but Group 3 (which
goes through real forward) would silently produce a cleaner snapshot
file. Could also be deferred to v11.1 since it's purely cosmetic.

---

## Touch-point classification

Per the review methodology:

- **Correctness (priority 1).** Functionally correct under the
  read-only-mirror contract. F1 surfaces a tradeoff at the contract
  boundary (user edits in flat-file mode between cycles); not strictly
  a correctness defect because the contract is documented (V1 §6.3),
  but it's a SHOULD because the contract violation produces silent
  data loss.
- **Security (priority 2).** No new attack surface. The snapshot file
  is operator-owned (gitignored, machine-local). No injection vectors
  in the regex / python-heredoc construction (input is read from a
  file path the operator controls).
- **Regressions (priority 3).** None. All seven existing test suites
  green; the new test exercises the prior-bug fixture.
- **Concurrency (priority 4).** Snapshot capture has a small TOCTOU
  window (file-existence check vs. `mktemp + mv`), but BD-132's race
  detection forbids concurrent disable runs at a higher level —
  collapses to a no-op concern in practice.
- **Architecture compliance (priority 5).** F3 — the new sidecar file
  is not documented in ARCHITECTURE-V3. F2 + F4 — test conventions
  drift slightly from "tests target public APIs" and "byte-equal
  means cmp -s".

## Six-dimension review (per skill methodology)

| Dimension | Verdict | Notes |
|---|---|---|
| Completeness | PASS | Snapshot captures every byte the apply needs. The leading-mirror-header inclusion is correctly composed with the downstream strip. F5 is cosmetic. |
| Failure-loud behavior | PASS with caveat (F1) | I/O failures correctly return 1 with tmp cleanup. The user-edit drop case (F1) is silent — that's the SHOULD. |
| Composition with BD-111 retrofit | PASS | Orthogonal code paths; verified by reading `_tmr_decode_blockers` (per-issue) vs. snapshot (whole-file). No shared state. |
| Test coverage proportionality | PASS | 1.86:1 test:impl ratio is appropriate for a silent-data-loss path. F2 + F4 are conventions, not coverage gaps. |
| Documentation | MIXED (F3) | Source header is excellent; ARCHITECTURE-V3 missed. |
| Operability | PASS with caveat (F1) | No `pack tracker doctor` hook for this sidecar. Future convenience improvement, not a ship-blocker. |

---

## Summary

BD-133 is a **clean ship** for v11.0. The core property — N round-
trips preserve the BACKLOG.md preamble byte-identical to the first-
capture — holds and is well-tested. The five findings above are
either documentation gaps (F1 docs portion, F3) or test-discipline
nits (F2, F4) or cosmetics (F5).

**Disposition recommended:**

- F1: address with a docs-only fix in this review-fix session (add a
  Risks-section bullet to the archived implementation report, or
  cross-reference the limitation in PACK-CHAT.md guidance for
  flat-file edits between cycles).
- F2: address by replacing `$()`-based extraction with `cmp -s` in
  the regression test in this review-fix session.
- F3: address with a paragraph addition to ARCHITECTURE-V3 in this
  review-fix session (small, additive, no design change).
- F4: defer to v11.1 unless cheap to land alongside F2 (promote
  `_ths_extract_preamble` to public + rename, ~10 lines).
- F5: defer to v11.1 (cosmetic).

**No MUST findings.** No ship-block. Implementation correctly resolves
the BD-102 Phase A D-6 dog-food finding and survives the realistic
init→disable workflow.

---

## Cross-reference accuracy

- BACKLOG.md BD-133 entry's `Resolved:` line accurately describes the
  approach (sidecar at `<repo-root>/.pack-tracker/backlog-header.snapshot`,
  first-write-wins, trivial-skip), test counts (30/30, 4 groups), and
  no-conflict rationale with BD-131.
- IMPLEMENTATION-REPORT-BD-133.md (archived) accurately describes
  file changes, module API, verification results, and the deferred
  items section ("None" — though F1's documentation gap should be
  added if the report is amended).
- BD-111's later reverse-decoder retrofit (scope-extended 2026-05-15,
  second extension) is fully compatible with BD-133's snapshot path.
  BD-111 operates inside `_tmr_decode_blockers` at line 445/550;
  BD-133 operates around `_tmr_emit_backlog` at lines 1087/1098.
  Distinct call surfaces, distinct file regions, no shared state.
