# IMPL-REPORT — BD-196 C11a Fix-coder pass 1 (one user-approved NIT)

- **Branch:** `v11-dev`
- **HEAD SHA (worktree, unchanged — agents never commit):** `b4fb89e703c11035acbfefbf22d873cbe7033fa3`
- **Scope:** ONE targeted MOVE within `## regenerate-manifest-v11-surface` in `pack-ops/PACK-MEMORY-RATIONALE.md`.
- **Finding addressed:** NIT (user-approved FIX) — base-case sentence was spliced
  mid-paragraph between the "…screen for WHEN to run the rebuild." sentence and
  the "`--all --clean` is the canonical default…" sentence, interrupting the
  WHEN→command flow.

---

## The edit (a MOVE, not a reword/deletion)

The base-case sentence was relocated from the splice point (immediately after
"…screen for WHEN to run the rebuild.") to AFTER the `--all --clean` /
`--name <fixture> --clean` guidance and BEFORE the "Cross-reference:" sentence.
This makes the WHEN→`--all --clean` flow contiguous and lets the base-case
sentence read cleanly in its own spot. The sentence content is preserved
verbatim, including the "empty-diff-→-not-v11-surface rule above is the final
authority" reinforcement.

### Before (spliced — WHEN sentence interrupted)

```
...the trigger globs are a screen
for WHEN to run the rebuild. Base case: the 3 pack-root trinity files
(`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at repo root) are NOT under any of the
four trigger directories, so a commit touching only them is never v11-surface
and needs no manifest regen; only their `pack-ops/` counterparts trigger (and
even then, the empty-diff-→-not-v11-surface rule above is the final authority). `--all --clean` is the canonical default (rebuilds
all six fixtures deterministically; v10-* rows are tag-pinned and only drift if
the v10 tag moves). Actors confident about which v11-* fixture is affected may
substitute `--name <fixture> --clean` per affected fixture, then `bash
test-fixtures/build.sh --verify` to confirm the remaining rows are unchanged
before staging. Cross-reference: the "Test infra is self-provisioned" bullet
above governs *test provisioning*; this bullet governs *manifest maintenance*
and is load-bearing for the `fixture manifest verify` CI gate (BD-115,
RELEASE-GATE item 5).
```

### After (WHEN→command contiguous; base-case moved to its own spot)

```
...the trigger globs are a screen
for WHEN to run the rebuild. `--all --clean` is the canonical default (rebuilds
all six fixtures deterministically; v10-* rows are tag-pinned and only drift if
the v10 tag moves). Actors confident about which v11-* fixture is affected may
substitute `--name <fixture> --clean` per affected fixture, then `bash
test-fixtures/build.sh --verify` to confirm the remaining rows are unchanged
before staging. Base case: the 3 pack-root trinity files
(`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at repo root) are NOT under any of the
four trigger directories, so a commit touching only them is never v11-surface
and needs no manifest regen; only their `pack-ops/` counterparts trigger (and
even then, the empty-diff-→-not-v11-surface rule above is the final authority).
Cross-reference: the "Test infra is self-provisioned" bullet
above governs *test provisioning*; this bullet governs *manifest maintenance*
and is load-bearing for the `fixture manifest verify` CI gate (BD-115,
RELEASE-GATE item 5).
```

The WHEN sentence is now "…screen for WHEN to run the rebuild. `--all --clean`
is the canonical default…" — contiguous, original phrasing restored. The
base-case sentence is intact and reads cleanly between the fixture-selection
guidance and the cross-reference.

---

## Verification results

| Check | Command | Result |
|---|---|---|
| validate-pack (full) | `python3 scripts/validate-pack.py` | **exit 0** — "PASSED — all checks clean" |
| Check 45 (bijection) | (in validate-pack log) | OK — 18 corpus pointers ↔ 18 rationale `## <slug>` sections; sets equal, bijection holds |
| Check 45 (dedicated test) | `bash scripts/tests/test-validate-pack-check-45.sh` | **exit 0** — PASS: 3, FAIL: 0 |
| Check 46 (boundary/spawn) | (in validate-pack log) | OK — boundary manifest 11 surfaces; spawn manifest 6 rules; anti-restate 0 verbatim restatements — NOT tripped |
| Heading count | `grep -c "^## "` | 20 before AND after (move preserved all headings; no slug added/removed) |
| Manifest regen | `bash test-fixtures/build.sh --all --clean` | exit 0; `git diff test-fixtures/manifest.txt` **EMPTY** (no staging needed — `pack-ops/PACK-MEMORY-RATIONALE.md` is not a fixture-affecting file under `pack-ops/`) |

The 18==18 bijection refers to the `[rationale: slug]` ↔ `## <slug>` corpus
mapping (Check 45); the 20 `^## ` lines include 2 non-slug sub-headings
("Rules-Applied Verification", "Empirical-Evidence Block"). Both counts are
unchanged by the move, as expected.

---

## Files changed

| Path | Change type |
|---|---|
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified (one MOVE within `## regenerate-manifest-v11-surface`) |

No other file touched. (`IMPLEMENTATION-REPORT-BD-196-C11a.md` and
`PACK-REVIEW-BD-196-C11a.md` are pre-existing untracked artifacts from the C11a
cycle, not produced by this fix-coder.)

## Plan deviations

None. The fix was applied exactly as specified in SECTION 3 (MOVE only;
content preserved; WHEN→command flow restored).

## New POQs introduced

None.

## Definition-of-Done

| Item | Status |
|---|---|
| WHEN→`--all --clean` sentence contiguous | PASS |
| Base-case sentence intact (incl. "empty-diff-→-not-v11-surface … final authority" reinforcement) and reads cleanly in new spot | PASS |
| 18 slugs unchanged (Check 45 bijection holds) | PASS |
| validate-pack.py exit 0 | PASS |
| Check 45 dedicated test passes | PASS |
| Check 46 not tripped | PASS |
| Manifest regen run + diff reported (empty) | PASS |
| No other change | PASS |
| No commit / no state-changing git verb | PASS |

---

## Rules-Applied Verification Block

| Rule (as named) | Verification evidence | Conclusion |
|---|---|---|
| Edit-in-place, not full rewrite | Single `Edit` call replacing one old_string with the same text reordered; `grep -c "^## "` = 20 before and after; no `## <slug>` added/removed; only `## regenerate-manifest-v11-surface` body touched | COMPLIANT |
| Enumerate ENCODING surfaces | `bash scripts/tests/test-validate-pack-check-45.sh` → exit 0, "PASS: 3, FAIL: 0"; validate-pack log Check 45 "18 corpus … 18 rationale … sets are equal (bijection holds)"; Check 46 "anti-restate: 0 … NOT tripped"; full `validate-pack.py` exit 0 | COMPLIANT |
| Regenerate manifest | `bash test-fixtures/build.sh --all --clean` exit 0; `git diff test-fixtures/manifest.txt` empty (reported, not staged) | COMPLIANT |
| Pack-coder PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 1/1 in-scope edit complete; verification PASS; HEAD b4fb89e703…` after edit + all verification PASSED; no parent stop signal received | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table | COMPLIANT |
| Agents never commit / no destructive ops / no deferral | Only `Read`/`Edit`/`Bash` (read-only git verbs: `rev-parse`, `status`, `diff`); no `git add/commit/push`; no `rm`; no deferral | COMPLIANT |
