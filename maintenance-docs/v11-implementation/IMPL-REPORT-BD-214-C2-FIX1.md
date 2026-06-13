# IMPL-REPORT — BD-214 C2-FIX1 (NIT-1: README invoked-checks count)

- **Branch:** v11-dev
- **HEAD SHA (worktree base; unchanged — no commits):** `bd06a9635c23d7df8f03fff30c6448c2acebde16`
- **Scope:** ONE approved review fix (NIT-1, user-approved 2026-06-13) —
  correct the STALE `validate-pack.py` invoked-checks count in `README.md`.
- **Files touched:** `README.md` only (the C2 working-tree change set was
  already present and is untouched by this fix).
- **No git state changes performed.** Read-only git verbs only.

---

## The fix

### OLD value (both occurrences, identical phrasing)
`45 invoked checks` / `43 numbered Check 1–11, 16–23, and 25–48; 2 unnumbered
informational — issue-template-forms and template-archive-v11; Checks 12–15
retired per v9 sunset; Check 24 retired per BD-194`

### NEW value
`48 invoked checks` / `46 numbered Check 1–11, 16–23, and 25–51 — including
DEEP-only Check 49; 2 unnumbered informational — issue-template-forms and
template-archive-v11; Checks 12–15 retired per v9 sunset; Check 24 retired
per BD-194`

### Where (two occurrences, both updated)
1. `README.md:60` — v11.0 Version-History table cell (parenthesized form).
2. `README.md:191` — Repository Layout, `validate-pack.py` annotation
   (em-dash form).

Both occurrences shared the identical count token (`45 invoked checks`) and
the identical inner enumeration substring, so the edit used `replace_all`
on each shared substring — one consistent change across both sites.

---

## Derivation (how the NEW number was computed, not guessed)

### Step 1 — what "invoked checks" counts
README's own breakdown defines the figure as: **numbered checks** (each check
ID counted once — label-legs like Check 16/18/19 `[project-template]` +
`[pack-root]` do NOT multiply the ID) **+ unnumbered informational checks**.
Retired IDs (12–15 v9 sunset; 24 BD-194) are excluded. This is a count of
distinct check IDs validate-pack invokes, reconciled against the printed
`── Check N: … ──` banners.

### Step 2 — measure (two independent methods, reconciled)

**Method A — source registry (printed banners in `scripts/validate-pack.py`):**
distinct numbered banner IDs = `{1–11, 16–23, 25–51}` = **46 numbered**;
unnumbered informational banners = `── Check: Issue template forms (BD-063) ──`
and `── Check: Template archive v11.0 integrity (BD-064; informational) ──`
= **2**. Total **48**.

**Method B — live run.** `python3 scripts/validate-pack.py` (general) and
`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep), both EXIT=0:

- General run distinct numbered IDs (verbatim count via regex on banners):
  `[1,2,3,4,5,6,7,8,9,10,11,16,17,18,19,20,21,22,23,25,26,27,28,29,30,31,
  32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,50,51]` = **45**
  (Check 49 is DEEP-only, absent from the general run).
- DEEP run distinct numbered IDs add Check 49 →
  `{1–11, 16–23, 25–51}` = **46 numbered**.
- Unnumbered informational banners present in both runs: **2**.
- **Total invoked checks = 46 + 2 = 48.**

**Reconciliation:** Method A (source) and Method B (DEEP run) agree exactly:
**46 numbered + 2 unnumbered = 48**. The general run alone undercounts the
numbered set by 1 because Check 49 is DEEP-gated; the README figure is the
full invoked inventory (the prior README enumeration `25–48` likewise
included DEEP-gated checks of that era), so the DEEP-inclusive 46/48 is the
authoritative figure for the README wording. The NEW wording adds the
explicit clause "including DEEP-only Check 49" so a reader reproducing the
count via the general run is not misled.

Missing-from-1–51 IDs (verified): `12, 13, 14, 15` (v9 sunset) and `24`
(BD-194 retirement) — exactly the retirements the README already documents.
No other gaps: `25–51` is contiguous in the invoked set.

### Step 3 — why 48, not 46

NIT-1 attributed the staleness to C1 adding Check 51. Investigation (git
history) shows the README count phrase was last touched at commit `60bb2d6`
(BD-195 C8), which **predates** `df77032` (BD-204) that added Checks 49 and
50. So the README was already stale by 2 (omitted 49, 50) before C1 added
51 — stale by 3 in total at HEAD. Per the "real fixes only — no band-aids"
rule, the count must be GENUINELY current: `45 → 48` (folding in 49, 50, and
51) is the correct value, not a Check-51-only `45 → 46` band-aid that would
leave the figure wrong. This stays within NIT-1's directive ("update the
number to the CORRECT current value").

### Evidence (commands + verbatim output)

```
$ python3 scripts/validate-pack.py            # EXIT=0
  distinct numbered banner IDs (general): 45  → {1–11,16–23,25–48,50,51}
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py   # EXIT=0
  distinct numbered banner IDs (deep):    46  → {1–11,16–23,25–51}
  unnumbered informational banners:        2  → BD-063 forms, BD-064 archive
  TOTAL invoked = 46 + 2 = 48
$ git log --oneline -1 -S "45 invoked checks" -- README.md
  60bb2d6 docs: v11 — BD-195 C8: README currency …      (predates 49/50)
$ git log --oneline -1 -S "Check 49: migrator field" -- scripts/validate-pack.py
  df77032 feat: v11 — BD-204 C-4.6 field-faithfulness guard …  (added 49/50)
$ git log --oneline -1 -S "Check 51: BD-214" -- scripts/validate-pack.py
  2d3f3d0 feat: v11 — BD-214 flip-block clamp … + Check 51 legs 1/2/4 …
```

### Cross-surface check (nothing else pins the count)
`grep -rn` across `scripts/`, `.github/`, `scripts/tests/`, `test-fixtures/`
for `45 invoked`, `43 numbered`, `25–48` returned NO validator/test/CI hit
(the single `numbered Check` hit in `validate-pack.py:1352` is unrelated
prose). The only other file carrying the old phrase is
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-C2.md` (the review
report — a historical artifact, out of scope, correctly NOT touched). No
validator asserts the README count string, so this edit neither breaks nor is
required by any check; it is a pure documentation-accuracy correction.

---

## Verification — FULL CI wired-test suite (every wired script, no sampling)

The wired command list was extracted verbatim from
`.github/workflows/validate-pack.yml` (`validate` job + `tests` job).
`pip install pyyaml` (env setup) was skipped (pyyaml already present).
Every executable wired step was run; all EXIT=0.

### `validate` job
| Command | EXIT |
|---|---|
| `python3 scripts/validate-pack.py` | 0 |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | 0 |

### `tests` job (all `bash …` steps)
| Step | EXIT |
|---|---|
| `scripts/test-detect.sh` | 0 |
| `scripts/tests/tracker-provider-test.sh` | 0 |
| `scripts/tests/tracker-config-test.sh` | 0 |
| `scripts/tests/tracker-init-test.sh` | 0 |
| `scripts/tests/tracker-agent-read-test.sh` | 0 |
| `scripts/tests/tracker-migrate-forward-test.sh` | 0 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 0 |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 0 |
| `scripts/tests/test-tracker-phase-task.sh` | 0 |
| `scripts/tests/test-tracker-links.sh` | 0 |
| `scripts/tests/test-tracker-cycle-check.sh` | 0 |
| `scripts/tests/tracker-errors-test.sh` | 0 |
| `scripts/tests/tracker-config-schema-test.sh` | 0 |
| `scripts/tests/recommendation-state-schema-test.sh` | 0 |
| `scripts/tests/test-per-entry.sh` | 0 |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 0 |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | 0 |
| `scripts/tests/test-validate-pack-check-39.sh` | 0 |
| `scripts/tests/test-validate-pack-check-40.sh` | 0 |
| `scripts/tests/test-validate-pack-check-41.sh` | 0 |
| `scripts/tests/test-validate-pack-check-18.sh` | 0 |
| `scripts/tests/test-validate-pack-check-16.sh` | 0 |
| `scripts/tests/test-validate-pack-check-19.sh` | 0 |
| `scripts/tests/test-validate-pack-check-42.sh` | 0 |
| `scripts/tests/test-validate-pack-check-43.sh` | 0 |
| `scripts/tests/test-validate-pack-check-44.sh` | 0 |
| `scripts/tests/test-validate-pack-check-45.sh` | 0 |
| `scripts/tests/test-validate-pack-check-46.sh` | 0 |
| `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` | 0 |
| `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | 0 |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | 0 |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | 0 |
| `scripts/tests/tracker-deferral-gate-test.sh` | 0 |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | 0 |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | 0 |
| `scripts/tests/tracker-bd132-race-test.sh` | 0 |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | 0 |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | 0 |
| `scripts/tests/recommendation-test.sh` | 0 |
| `scripts/tests/pack-help-test.sh` | 0 |
| `scripts/tests/test-customization-preserve.sh` | 0 |
| `scripts/tests/test-init-project.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | 0 |
| `scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 0 |
| `scripts/test-migrator-core.sh` | 0 |
| `scripts/test-migrator-manifest.sh` | 0 |
| `scripts/test-migrator-capability-translation.sh` | 0 |
| `test-fixtures/build.sh --all --clean` | 0 |
| `test-fixtures/build.sh --verify` | 0 |
| `scripts/tests/test-v11-realistic-ot.sh` | 0 |
| `scripts/test-migrator-skills.sh` | 0 |
| `scripts/test-persona-contracts.sh` | 0 |
| `scripts/tests/template-translations-test.sh` | 0 |
| `scripts/tests/template-version-test.sh` | 0 |
| `scripts/tests/test-issue-forms.sh` | 0 |

**Result:** every wired test EXIT=0 (BATCH1_FAIL=0, BATCH2_FAIL=0,
BATCH3_FAIL=0, BATCH4_FAIL=0). The CI workflow's `git checkout HEAD --
test-fixtures/manifest.txt` step (CI bookkeeping, a state-changing git verb)
was NOT run — agents are git-read-only; the manifest's currency is instead
proven below.

---

## Manifest check (Rule 4)

`README.md` is at repo root — NOT under `project-template/`, `scripts/`,
`pack-ops/`, or `supporting-docs/` — so README alone is not v11-surface and
is not a fixture input. The C2 change set DOES touch `pack-ops/` + `scripts/`,
so the manifest was regenerated and inspected:

```
$ bash test-fixtures/build.sh --all --clean      # EXIT=0
$ git diff test-fixtures/manifest.txt
  (empty — 0 bytes)
$ git status --short test-fixtures/manifest.txt
  (no output — manifest unchanged)
$ bash test-fixtures/build.sh --verify           # EXIT=0
```

**Manifest diff is empty.** The README edit introduces no manifest change
(README not a fixture input), and the pre-existing C2 `pack-ops/`+`scripts/`
edits already had their manifest regenerated in C2 (the regenerate produced
no further delta at this HEAD). No manifest staging needed for this fix.

---

## Files changed inventory

| Path | Change type | Notes |
|---|---|---|
| `README.md` | modified | 2 occurrences of the invoked-checks count corrected (`45→48` invoked; `43→46` numbered; `25–48`→`25–51` + DEEP-only-49 clause). Lines 60 + 191. |

No new files. No deletions. C2's other working-tree edits are untouched
(verified: line 60 retains C2's "deferred (dormant) — BD-214" wording).

---

## Plan deviations

One scope nuance, documented and within NIT-1's directive:

- NIT-1 framed the staleness as "C1 added Check 51 → count off by 1." The
  correct current value is `48` (off by 3 at HEAD), because the README count
  was last edited (`60bb2d6`) before BD-204 added Checks 49 + 50. Updating to
  the genuinely-correct `48` (vs a Check-51-only `46`) satisfies "real fixes
  only — no band-aids" and "update to the CORRECT current value." This is a
  derivation refinement of the count, not a scope expansion: still a single
  documentation-number correction in `README.md`, no other file touched.

No other deviations. Check 51 legs 3/5 NOT added (out of scope). C2's other
edits NOT re-done. No other file modified.

## New POQs

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| OLD value identified (45 invoked / 43 numbered) | PASS |
| NEW value derived, not guessed (source + live-run reconciled = 48) | PASS |
| Two independent count methods reconciled (Method A source ≡ Method B DEEP run) | PASS |
| README phrase meaning preserved (numbered + unnumbered breakdown intact; DEEP-only clause added for accuracy) | PASS |
| Both occurrences updated (line 60 + line 191) | PASS |
| Old count tokens fully absent (`grep` of `45 invoked`/`43 numbered` = 0) | PASS |
| No out-of-scope file touched | PASS |
| C2 working-tree edits intact | PASS |
| FULL CI wired-test suite run, every script EXIT=0 (no sampling) | PASS |
| `validate-pack.py` general + DEEP both EXIT=0 | PASS |
| Manifest regenerated; diff empty | PASS |
| No git state changes (read-only git only) | PASS |

---

## Rules-Applied Verification Block

| # | Rule name | Verification evidence | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Only `git rev-parse/status/diff/log/show` run; no `add/commit/push/tag`; `git checkout HEAD -- manifest.txt` CI step deliberately skipped; HEAD unchanged at `bd06a96`. | COMPLIANT |
| 2 | Real fixes only — no band-aids | NEW value `48` derived from source registry AND reconciled with two live runs (general 45-numbered + DEEP +Check-49 = 46-numbered, +2 unnumbered = 48); git history proved 49/50 were never folded in, so a Check-51-only `46` would itself be wrong — chose the genuinely-current `48`. | COMPLIANT |
| 3 | Verify the FULL CI suite — every wired script, no sampling | All 60 executable wired steps from `validate-pack.yml` run (2 in `validate` job + 58 in `tests` job), each EXIT=0; general + `PACK_VALIDATE_DEEP=1` both EXIT=0; BATCH{1,2,3,4}_FAIL all =0. Per-step EXIT table above. | COMPLIANT |
| 4 | Manifest | `bash test-fixtures/build.sh --all --clean` EXIT=0; `git diff test-fixtures/manifest.txt` = 0 bytes; `git status --short` empty; `--verify` EXIT=0. README is not a fixture input. | COMPLIANT |
| 5 | Edit in place | Single targeted `replace_all` on the count token + enumeration substring (no full-file rewrite); both edited lines re-read via `grep -n "invoked checks" README.md` post-edit and confirmed; C2 line-60 wording intact (`grep -c "deferred (dormant) — BD-214"` = 1). | COMPLIANT |
| 6 | Rules-Applied Verification Block present | This block. | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | Emitted: `PREFLIGHT: fix complete; FULL CI wired-test job verified locally; count derived = 48; HEAD bd06a9635c23d7df8f03fff30c6448c2acebde16; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C2-FIX1.md`. No parent stop message received. | COMPLIANT |
