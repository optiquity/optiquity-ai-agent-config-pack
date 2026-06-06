# PACK-REVIEW — BD-204 C-5 CI-fix (tracker-bd134-close-retry-test reconcile)

**Headline: PASS.** The fix reconciles `tracker-bd134-close-retry-test.sh`'s
fixture seed from the deleted `pack-ops/BACKLOG.md` monolith to the per-entry
tree (the C-5 forward read-side SSOT) using the exact roundtrip-test pattern.
All 24 close-retry assertions are byte-identical to HEAD (coverage preserved);
bd134 now passes 24/24; the full CI suite (53 steps) + `validate-pack.py` +
fixture manifest verify are all green. Scope is the single test file —
pack-only, no production code, no `project-template/` touch.

Reviewer: pack-reviewer · branch `v11-dev` · HEAD `e228b38` · read-only.

---

## Scope confirmation

`git diff --name-status` → `M scripts/tests/tracker-bd134-close-retry-test.sh`
only (1 file, +27/−5). Two untracked files exist (`IMPL-REPORT-BD-204-C5-CIFIX.md`,
`RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md`) — not part of this diff, not read.
No `project-template/` change. Diffstat: 32 lines, 1 file.

---

## Check 1 — Fixture reconcile correct: PASS

The diff makes exactly three substantive changes, all in the test's fixture
plumbing:

1. **Sources the per-entry libs** (new lines 83–85): `per-entry/_lib.sh` +
   `per-entry/decompose.sh` — identical to `tracker-migrate-roundtrip-test.sh`
   lines 47/49.
2. **Drops the monolith write.** HEAD wrote the 2-entry backlog directly to
   `cat > "$repo/pack-ops/BACKLOG.md"`. WT writes the same content to a temp
   monolith (`_mono=$(mktemp …)`), then `per_entry_decompose "pack-backlog"
   "$_mono" "$repo/backlog"` and `rm -f "$_mono"`. The only remaining
   `pack-ops/BACKLOG.md` mentions are in the explanatory comment (lines 115,
   121) — no write.
3. **Creates `$repo/backlog`** via `mkdir -p` before the decompose call
   (decompose.sh:54 requires the stream dir to pre-exist), and retains
   `mkdir -p "$repo/pack-ops"` as the surface marker so
   `tracker_config_auto_surface` still returns `"pack"`.

Invocation matches the public signature `per_entry_decompose <key> <mono>
<stream_dir>` (decompose.sh:39–42) and the roundtrip precedent
(roundtrip-test.sh:357/370). The forward read-side now finds the tree under
`<repo>/backlog/` — the original CI-red root cause (bd134 sought
`<repo>/backlog`, found none) is resolved. No monolith fallback was added
anywhere; the no-monolith fail-loud model is preserved.

---

## Check 2 — Coverage preserved (assertion-by-assertion vs HEAD): PASS

Extracted all `assert_eq` / `assert_contains` / `assert_not_contains` lines
from `git show HEAD:` and from the working tree, normalized line-continuations,
and diffed:

```
HEAD assert count: 24
WT   assert count: 24
diff head_asserts.txt wt_asserts.txt → (empty) → IDENTICAL
```

Every close-retry assertion is intact and unchanged:

- **Group 1 (transient → recovered):** 1.1 rc=0, 1.2 no partial-write, 1.3
  retry-sweep mention, 1.4 `recovered=2`, 1.5 `persistent=0`, 1.6 `closed: 2`,
  1.7 one initial-failure per id.
- **Group 2 (persistent → bounded surface):** 2.1 rc=1, 2.2 partial-write
  code, 2.3 `step-8 close` naming, 2.4 names `BD-001`, 2.5 `failed after 3
  attempts`, 2.6 `persistent=2`, 2.7 bounded 6 total (3×2, NOT infinite), 2.8
  exactly 2 distinct ids, 2.9 max-per-id=3, 2.10 min-per-id=3.
- **Group 3 (`_tmf_retry_one_close` unit):** 3.1 max=1 disables retry, 3.2
  first-retry success + 1 call, 3.3 all-fail rc=1 + 3 calls, 3.4 last-allowed
  retry + 2 calls.

The two fake-`gh` helper bodies (`build_fake_gh_transient_close`,
`build_fake_gh_persistent_close`) are byte-identical to HEAD (diff empty for
both). Only the fixture SEED moved monolith → tree; the behavior coverage is
not weakened or dropped.

---

## Check 3 — Same-class sweep genuine (no other CI-red lurking): PASS

Independently re-ran the intersection: tests that WRITE the
`pack-ops/BACKLOG.md` monolith as a fixture AND exercise the pack
forward/reverse path.

- **Tests that `cat >` a `pack-ops/BACKLOG.md` fixture:** exactly one besides
  bd134 — `tracker-agent-read-test.sh:38`. It sources ONLY
  `tracker-agent-read.sh` and makes ZERO `tracker_migrate_forward_run` /
  `_reverse_run` calls; it asserts `Source: flat-file (BACKLOG.md)` attribution.
  That monolith seed is a LEGITIMATE flat-file-source fixture, NOT a
  forward-path seed — not in the CI-red class, correctly left alone.
- **Forward/reverse tests:** `tracker-migrate-forward-test.sh` (13 run calls)
  and `tracker-migrate-roundtrip-test.sh` (5 run calls) both seed via
  `per_entry_decompose` (2 each) and write NO monolith — already reconciled in
  C-4/C-5. `tracker-migrate-reverse-test.sh` (5 run calls) writes no monolith
  (reverse PRODUCES the tree). `tracker-bd133-header-preservation-test.sh` runs
  no forward/reverse and writes no monolith.

Conclusion: bd134 was the only un-reconciled monolith-seed-forward test. No
other CI-red lurking.

---

## Check 4 — Full CI green (entire set run, not a subset): PASS

Enumerated the 53 run commands from `.github/workflows/validate-pack.yml`
(`validate` job + `tests` job) and ran every one in CI order, plus
`validate-pack.py` and the fixture build/verify.

- **`python3 scripts/validate-pack.py`** → `PASSED — all checks clean`, rc=0.
- **Tests steps 1–45** → all PASS (verbatim PASS list captured), including
  step 34 `tracker-bd134-close-retry-test.sh`.
- **bd134 verbatim:** `=== Results: 24 passed, 0 failed ===`.
- **Step 46 `build.sh --all --clean`** → rc=0; manifest diff EMPTY
  (`git diff --quiet test-fixtures/manifest.txt` → clean — no drift).
- **Step 47 `build.sh --verify`** → rc=0 (all fixture HEAD SHAs match committed
  manifest).
- **Steps 48–53** (`test-v11-realistic-ot.sh`, `test-migrator-skills.sh`,
  `test-persona-contracts.sh`, `template-translations-test.sh`,
  `template-version-test.sh`, `test-issue-forms.sh`) → all PASS.

**Aggregate: 53/53 CI run steps PASS + validate-pack PASS + manifest verify
PASS.** Final tracked-file state: only `M scripts/tests/tracker-bd134-close-retry-test.sh`;
manifest clean; no `project-template/` change.

(Note on method: the CI `restore committed manifest` step does
`git checkout HEAD -- test-fixtures/manifest.txt`; as a read-only reviewer I did
NOT mutate git state — instead I verified the post-build manifest diff is empty,
which makes the subsequent `--verify` comparison equivalent to the CI flow and
non-tautological since the rebuilt SHAs match the committed pins.)

---

## Findings (severity-ranked)

**None.** No BLOCKER / MUST / SHOULD / NIT findings. The fix is minimal,
correct, pattern-consistent with the roundtrip reconcile, coverage-preserving,
and the full suite is green. Recommend proceeding to commit.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| Verify the FULL CI suite | Ran all 53 enumerated steps from `validate-pack.yml` in order + `validate-pack.py` + `build.sh --all --clean`/`--verify`. Aggregate 53/53 PASS; validate-pack `PASSED — all checks clean`; manifest verify rc=0. bd134 `24 passed, 0 failed`. | COMPLIANT |
| Coverage not weakened (assertion-by-assertion vs HEAD) | `diff` of all 24 normalized assert lines HEAD↔WT → empty (IDENTICAL); both fake-gh helper bodies diff-empty vs HEAD. | COMPLIANT |
| Enumerate ENCODING surfaces (same-class sweep) | `grep -rn 'cat >.*pack-ops/BACKLOG.md'` → only bd134 + `tracker-agent-read-test.sh`; the latter sources only `tracker-agent-read.sh`, 0 forward/reverse calls (legitimate flat-file fixture). All forward/reverse tests tree-seeded or monolith-free. | COMPLIANT |
| Fix the test, not the behavior | `git diff --name-status` = 1 test file; no `scripts/lib/` change; remaining `pack-ops/BACKLOG.md` mentions are comments only; no monolith fallback added (decompose seeds the tree). | COMPLIANT |
| Pack/project separation + scope | `git diff --name-only \| grep project-template/` → none; final status only `M scripts/tests/tracker-bd134-close-retry-test.sh`; pack-only. | COMPLIANT |
| Empirical evidence + Rules-Applied block | All claims above carry quoted command output (diff results, rc values, `24 passed, 0 failed`, manifest-clean check); this table present. | COMPLIANT |
| Read-only (no edits/fixes/commits) | Only writes are this one report; no production/test file edited; no `git add`/`commit`/`tag`; no git-state mutation (manifest verified via diff, not checkout). | COMPLIANT |
