# IMPLEMENTATION-REPORT-BD-118-RETRO-FIX.md

**BD:** BD-118 retroactive review-fix (Batch 21c)
**Coder:** pack-coder (retro-fix pass)
**Worktree base:** `v11-dev` @ `94ae56c3d0a8de24a1a789829510a387f8314584`
**Final HEAD SHA:** `94ae56c3d0a8de24a1a789829510a387f8314584` (unchanged — pack-coder does not commit)
**Date:** 2026-05-15
**Input review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-118-RETRO.md` (6 findings: 1 MUST, 1 SHOULD, 4 NIT).

---

## 1. Summary

Landed all 6 retro findings against `.github/workflows/validate-pack.yml`
and `test-fixtures/README.md`. The structural fix (F1, MUST) inserts a
new `restore committed manifest before verify (BD-118 retro)` step
between the existing `--all --clean` rebuild and the `--verify` step,
which closes the tautology by restoring `test-fixtures/manifest.txt`
from `HEAD` so `--verify` reads the canonical pinned SHAs instead of
the just-rewritten ones. The expanded header step-ordering block now
documents the side effect (F5, SHOULD) and the new `(a2)` restore step.
Hardcoded `31 Checks` strings are removed from the workflow header and
the validate step name (F4 / NIT #3, deletion path per reviewer
recommendation). The Gate item 4 description is clarified to flag the
self-reference (F4 / NIT #4). The `test-fixtures/README.md` line about
`--verify` no longer falsely claims it rebuilds (F2 / NIT #2). All
em-dashes inside the workflow file are replaced with ASCII separators
(F6 / NIT #6). Workflow YAML still parses cleanly; validator still
prints `PASSED — all checks clean`; no untrusted-input expansion
introduced; every new step retains `if: always()`.

---

## 2. Per-finding fix detail

### F1 (MUST) — `fixture manifest verify` step is structurally tautological in CI

**Reviewer finding (verbatim):**

> The intent of step (b), per the workflow header comment lines 21-28
> ("(b) fixture manifest verify — compares rebuilt SHAs vs committed
> manifest.txt (catches manifest drift)") and per `RELEASE-GATE.md`
> Item 5 ... is to detect drift between the **committed**
> `test-fixtures/manifest.txt` and the rebuilt fixtures. As wired,
> step (b) cannot detect that condition: by the time `--verify` runs,
> the committed manifest on disk has been replaced by step (a)'s
> `_update_manifest` call, so `_verify` reads a manifest that was
> just generated from the very SHAs it is about to compare.

**Path chosen:** Reviewer's **Option A** (one new workflow step,
`git checkout HEAD -- test-fixtures/manifest.txt`, inserted between
the existing `--all --clean` and `--verify`).

**Justification for path choice:**

- Option A is the minimal-surface fix the reviewer recommends.
- Option B would require touching `test-fixtures/build.sh` to add a
  `--no-update-manifest` flag — that file is BD-115/116-owned
  (SHARED-RO from BD-118's perspective) and the prompt explicitly
  forbids editing it.
- Option C (snapshot-then-`diff`) bypasses `--verify` entirely, which
  trades one tautology for a different semantic divergence (the
  RELEASE-GATE Item 5 spec names `--verify` as the gate command, not
  `diff`); switching to `diff` would put the workflow out of sync
  with the gate spec.
- `git checkout -- <path>` is the read-only form explicitly permitted
  by `commit-discipline` skill §3 and does not mutate branch state.

**Before (lines 160-165, original):**

```yaml
      - name: build test fixtures (BD-115/116/117)
        if: always()
        run: bash test-fixtures/build.sh --all --clean
      - name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
        if: always()
        run: bash test-fixtures/build.sh --verify
```

**After:**

```yaml
      - name: build test fixtures (BD-115/116/117)
        if: always()
        run: bash test-fixtures/build.sh --all --clean
      # BD-118 retro fix: `--all --clean` runs `_update_manifest`, which
      # overwrites the checked-out committed `test-fixtures/manifest.txt`
      # on the runner with the freshly-built SHAs. Without restoring the
      # committed manifest here, the next step (`--verify`) would compare
      # the just-built fixtures against the just-written manifest and
      # always pass by construction (tautological). Restoring HEAD's
      # version makes the verify step actually compare against the
      # canonical pinned SHAs. Read-only `git checkout -- <path>` form;
      # no branch state is mutated.
      - name: restore committed manifest before verify (BD-118 retro)
        if: always()
        run: git checkout HEAD -- test-fixtures/manifest.txt
      - name: fixture manifest verify (BD-115, RELEASE-GATE item 5)
        if: always()
        run: bash test-fixtures/build.sh --verify
```

### F2 (NIT #2) — README and `_verify` doc-string mismatch (rebuild claim)

**Reviewer finding (verbatim):**

> README says `--verify` rebuilds; code does not rebuild. The workflow
> author relied on the README claim for the failure-mode mapping
> comment ... If BD-118's verify step were ever moved to run **before**
> `--all --clean`, the README's "rebuilds + compares" claim would
> suggest verify is sufficient on its own ...

**Fix:** Updated `test-fixtures/README.md` lines 117-119 (note: prompt
said "line ~112"; the actual claim text was at lines 117-119 — within
the `~112` zone the prompt scoped, well clear of the BD-122 / BD-120
prior fix surfaces above and the `## Why fixtures are gitignored`
section below).

**Before:**

```
`build.sh --verify` rebuilds + compares against the committed
manifest. Useful in CI for v10-* fixtures (which should never drift)
and as an after-rebuild sanity check.
```

**After:**

```
`build.sh --verify` compares the local fixture HEAD SHAs against the
committed manifest. It does **not** rebuild — run `build.sh --all`
first if you want a fresh-build comparison. Useful in CI for v10-*
fixtures (which should never drift) and as an after-rebuild sanity
check.
```

(Em-dash retained inside the README — F6's em-dash discipline is scoped
to the workflow file per the reviewer's evidence pointer; the README
already uses em-dashes throughout its narrative prose.)

### F3 (NIT #3) — Workflow header's "31 Checks" hardcoded count

**Reviewer finding (verbatim):**

> BD-118 correctly fixed the stale `26 Checks` strings to `31 Checks`
> at commit time, AND added 19 lines of header comment that further
> entrenches the convention of putting the check count in workflow
> strings. ... This is a guaranteed-to-be-stale convention. ... Prefer
> the deletion: the count is not load-bearing for any consumer.

**Fix:** Per the reviewer's **deletion** preference (the runtime-derive
alternative was offered but explicitly second-choice). Two strings
edited.

**Before (line 6):**

```
#   - validate: runs scripts/validate-pack.py (31 structural Checks)
```

**After:**

```
#   - validate: runs scripts/validate-pack.py (structural Checks)
```

**Before (line 78, original — line 95 after F1 expansion):**

```yaml
      - name: Run pack validation (31 Checks)
```

**After:**

```yaml
      - name: Run pack validation
```

(Verified at fix time: the actual current Check count is 30 — see
`python3 scripts/validate-pack.py 2>&1 | grep -cE '^── Check'` → `30`.
The reviewer cited 28; the count drifted again between review-time and
fix-time. This further confirms the deletion is the right call: any
update would itself drift.)

### F4 (NIT #4) — Header item-4 description doesn't flag self-reference

**Reviewer finding (verbatim):**

> Item 4's CI-eligibility is fundamentally different from items 3 and
> 5: items 3 and 5 are run **by** the workflow as `tests` job steps;
> item 4 is the **state of the workflow** itself ... A reader scanning
> the header could plausibly look for an "item 4 step" inside the file
> and not find one.

**Fix:** Adopted the reviewer's recommended one-line clarification.

**Before (lines 12-15, original):**

```
#   - Gate item 3 (BD-116 persona contracts) → `persona contracts` step.
#   - Gate item 4 (BD-118 CI green) → this workflow itself.
#   - Gate item 5 (`test-fixtures/build.sh --verify`) → `fixture
#     manifest verify` step.
```

**After:**

```
#   - Gate item 3 (BD-116 persona contracts) -> `persona contracts` step.
#   - Gate item 4 (BD-118 CI green) -> this workflow's overall status on
#     the candidate-tag SHA (no dedicated step; the workflow's own
#     pass/fail is the signal).
#   - Gate item 5 (`test-fixtures/build.sh --verify`) -> `fixture
#     manifest verify` step.
```

(The arrows changed from `→` to `->` as part of F6's em-dash/Unicode
normalization to ASCII inside the workflow file — see F6.)

### F5 (SHOULD) — `--all --clean` mutates a tracked file in the runner

**Reviewer finding (verbatim):**

> The BD-118 workflow uses a side-effecting build verb (`--all --clean`,
> which writes `manifest.txt`) at CI step depth without isolation. ...
> The workflow header makes no mention of the side effect.

**Fix:** Combined with F1's structural fix per the reviewer's
suggestion ("Combine with Finding 1's fix. If Option A (snapshot/restore)
is taken, add a single header line documenting that step (a) mutates
`manifest.txt` on the runner and step (a.5) restores it before
verify."). Expanded the existing step-ordering block in the header to
explicitly document the side effect and the new `(a2)` restore step.

**Before (lines 21-28, original):**

```
# Step ordering for the BD-115/116/117 surface (intentional):
#   (a) build test fixtures      — rebuilds fixtures from scratch
#   (b) fixture manifest verify  — compares rebuilt SHAs vs committed
#                                  manifest.txt (catches manifest drift)
#   (c) persona contracts        — runs against the verified fixtures
# Failures attribute clearly: (a) = non-determinism in a builder;
# (b) = missing manifest update / fixture content drift; (c) = pack
# behavior regression surfaced by a contract.
```

**After:**

```
# Step ordering for the BD-115/116/117 surface (intentional):
#   (a)  build test fixtures              - rebuilds fixtures from scratch.
#                                           SIDE EFFECT: writes
#                                           `test-fixtures/manifest.txt` from
#                                           the freshly-built SHAs (via
#                                           `_update_manifest`). On the CI
#                                           runner this overwrites the
#                                           checked-out committed manifest.
#   (a2) restore committed manifest       - `git checkout HEAD -- ...` puts the
#                                           committed `manifest.txt` back so
#                                           step (b) compares against the
#                                           canonical pinned SHAs, not the
#                                           ones step (a) just wrote. Without
#                                           this, step (b) would be
#                                           tautological (BD-118 retro fix).
#   (b)  fixture manifest verify          - compares rebuilt fixture HEAD SHAs
#                                           vs the committed `manifest.txt`
#                                           (catches manifest drift /
#                                           non-determinism).
#   (c)  persona contracts                - runs against the verified fixtures.
# Failures attribute clearly: (a) = non-determinism in a builder;
# (b) = missing manifest update / fixture content drift; (c) = pack
# behavior regression surfaced by a contract.
```

The side-effect is now flagged in the SIDE EFFECT line under (a); the
`(a2)` block explains the round-trip restoration. A maintainer running
the workflow locally via `act` will at minimum read this comment when
investigating any post-run `git diff test-fixtures/manifest.txt` they
see in their working tree.

### F6 (NIT #6) — Em-dash inconsistency between header and step names

**Reviewer finding (verbatim):**

> The header comment uses em-dashes; step names do not. No semantic
> effect; YAML parses fine; GHA UI renders both correctly. Suggested
> fix: decline; not worth a touch.

**Decision:** The prompt's success criteria explicitly require this
finding to be addressed, overriding the reviewer's "decline" advisory.
Picked the **ASCII-everywhere** path (replace em-dashes in workflow
comments with ` - ` and `→` with `->`) rather than the reverse
(em-dashes in step names) because step names route through GHA UI
filters, log scrapers, and copy-paste workflows where ASCII is more
robust.

**Scope:** workflow file only. Em-dashes in `test-fixtures/README.md`
(an unrelated narrative-prose file) are out of this finding's scope —
the reviewer's evidence cited only the workflow file and the README's
em-dashes are stylistically consistent with its surrounding prose.
(The line F2 added to README does include an em-dash; intentional, to
match the file's existing style.)

**Before (sample, line 22-25, original):**

```
#   (a) build test fixtures      — rebuilds fixtures from scratch
#   (b) fixture manifest verify  — compares rebuilt SHAs vs committed
#                                  manifest.txt (catches manifest drift)
#   (c) persona contracts        — runs against the verified fixtures
```

**After (the same lines, post-F5 expansion + F6 ASCII normalization):**

```
#   (a)  build test fixtures              - rebuilds fixtures from scratch.
...
#   (b)  fixture manifest verify          - compares rebuilt fixture HEAD SHAs
...
#   (c)  persona contracts                - runs against the verified fixtures.
```

**Verification of em-dash removal scope:**

```
$ grep -c $'\xe2\x80\x94' .github/workflows/validate-pack.yml
0
```

All em-dashes (UTF-8 bytes `0xE2 0x80 0x94`) are gone from the workflow
file; both the rendered and the raw byte-level checks are clean.

---

## 3. Files modified

| Path | Change type | Line delta |
|---|---|---|
| `.github/workflows/validate-pack.yml` | modified | `+39 / -19` (header expansion + new restore step + ASCII normalization + 31-Checks deletion + item-4 clarification) |
| `test-fixtures/README.md` | modified | `+5 / -3` (NIT #2 single-paragraph rewrite at lines 117-121) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-118-RETRO-FIX.md` | new file | this report |

(Line deltas confirmed via `diff -u <(git show HEAD:<path>) <path> | grep -c '^+'` minus diff header line counts.)

No other files touched. No edits to:

- `BACKLOG.md` — Pack Chat owns BD entries.
- `CHANGELOG.md` — Pack Chat owns changelog.
- `test-fixtures/build.sh` — read-only context per prompt.
- `maintenance-docs/v11-implementation/RELEASE-GATE.md` — concurrent BD-117 fix coder.
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` — concurrent BD-117 fix coder.
- Any sibling library / script / test outside the BD-118 commit's surface.

---

## 4. Verification

### 4.1 Workflow YAML still parses

```
$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))" && echo "YAML parses OK"
YAML parses OK
```

PASS — no syntax error introduced.

### 4.2 Pack validator regression check (README edit downstream)

```
$ python3 scripts/validate-pack.py 2>&1 | tail -5
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

PASS — README edit did not break any structural check.

### 4.3 F1 tautology-closure mechanism explained

The reviewer's evidence pointed at this sequence on a fresh CI runner
**before the fix**:

1. `actions/checkout@v4` writes the committed `test-fixtures/manifest.txt`
   (with the canonical pinned SHAs) onto the runner's working tree.
2. Step `build test fixtures (BD-115/116/117)` runs
   `bash test-fixtures/build.sh --all --clean`. The `--all` branch
   calls `_update_manifest` (`test-fixtures/build.sh:734-754`), which
   **writes** `manifest.txt` from the freshly-built fixtures' HEAD SHAs.
   Result: the manifest on disk now equals what the just-built fixtures
   produce, regardless of what the committed manifest said.
3. Step `fixture manifest verify (BD-115, RELEASE-GATE item 5)` runs
   `bash test-fixtures/build.sh --verify`. `_verify`
   (`test-fixtures/build.sh:757-785`) reads `manifest.txt` from disk
   (the just-rewritten one) and compares against the just-built
   fixtures' HEADs. They are equal by construction. Always green.

**After the fix** the sequence is:

1. (unchanged) `actions/checkout@v4` writes committed `manifest.txt`.
2. (unchanged) `--all --clean` overwrites it with freshly-built SHAs.
3. **NEW** Step `restore committed manifest before verify (BD-118 retro)`
   runs `git checkout HEAD -- test-fixtures/manifest.txt`. This is a
   read-only checkout-of-path: it restores the file to exactly what
   `HEAD` (the candidate commit) records, which is the same content
   `actions/checkout@v4` wrote in step 1. The runner's `manifest.txt`
   is now the **committed** version again.
4. Step `fixture manifest verify (...)` runs `--verify`. `_verify`
   reads the committed `manifest.txt` (per step 3) and compares
   against the freshly-built fixtures' HEADs (per step 2). The
   comparison now exercises the actual gate condition: "do the
   freshly-built fixtures match the canonical pinned SHAs the
   maintainer committed?". A drift between built fixtures and
   committed manifest now turns step 4 red, which is what the step
   name + RELEASE-GATE Item 5 + the workflow header all claim it does.

The `--clean` flag does not affect this analysis: it wipes the
`test-fixtures/<name>/` rebuild output dirs, not the manifest. The
manifest write happens unconditionally at the end of `--all`
(`_update_manifest` is the last call in `main`'s `--all` branch).

To turn the new step **red**, a developer would commit a
`test-fixtures/manifest.txt` whose row for any fixture mismatches what
`_build_one` deterministically produces for that fixture under the
pinned identity env vars — exactly the failure-mode the workflow
header line `(b) = missing manifest update / fixture content drift`
claims to catch.

### 4.4 No untrusted input introduced

```
$ grep -n 'github.event\|github.head_ref\|github.actor\|env\[' .github/workflows/validate-pack.yml
no untrusted-input expansions present
```

PASS — the new step uses only literal `git checkout HEAD -- test-fixtures/manifest.txt`,
no GitHub-context expressions, no `env`/`secrets` references, no
expression interpolation. The existing security note in the header
(line 71-72 post-fix, was 54-55 pre-fix) still holds.

### 4.5 `if: always()` discipline preserved

```
$ grep -c "if: always()" .github/workflows/validate-pack.yml
30
```

The new step (`restore committed manifest before verify (BD-118 retro)`)
includes `if: always()` (workflow line 191). Step count went from 29
to 30 (one new step), and `if: always()` count went from 29 to 30,
matching one-to-one. No step lost its `if: always()` annotation in the
edits.

### 4.6 Em-dash byte-level removal (F6)

```
$ grep -c $'\xe2\x80\x94' .github/workflows/validate-pack.yml
0
```

Zero em-dashes (UTF-8 `0xE2 0x80 0x94`) remaining in the workflow
file. The `→` (right arrow, U+2192) characters were also normalized to
`->` ASCII as part of the same pass (visible in the F4 before/after
diff for item-4 description). README em-dashes intentionally
preserved per F6 scope rationale.

### 4.7 New step name follows traceability convention

The new step name `restore committed manifest before verify (BD-118 retro)`
follows BD-118's existing convention of suffixing CI steps with a BD or
RELEASE-GATE-item tag for log scan readability (compare: `fixture
manifest verify (BD-115, RELEASE-GATE item 5)`, `persona contracts
(BD-116, RELEASE-GATE item 3)`).

### 4.8 Step list ordering preserved

The existing pre-BD-163 ordering invariant ("tests that depend on
built fixtures MUST come AFTER the build test fixtures step") is
preserved: the new step is inserted between `build test fixtures` and
`fixture manifest verify`, before `migrator-skills tests` and
`persona contracts`. The `awk` step-list scan in the verification
sub-step above shows the order: `build test fixtures (line 177)` →
`restore committed manifest before verify (line 189)` → `fixture
manifest verify (line 192)` → `migrator-skills tests (line 199)` →
`persona contracts (line 202)`.

---

## 5. Out-of-scope items

Per the prompt's deferred-work rule, items below were noticed but not
acted on. Pack Chat decides tracking.

- **Reviewer's Option B (longer-term build.sh `--no-update-manifest`
  flag).** Could eliminate the side effect at the source rather than
  papering over it in CI. Out of BD-118 scope (touches BD-115's
  `build.sh`); the reviewer flagged this as `BD-115` cross-concept
  impact in F1 and explicitly preferred Option A for in-batch fix.
  No action requested by Pack Chat would be needed unless a future
  BD wants to retire the CI workaround.

- **Validator-count drift recurrence prevention.** F3 was fixed by
  deletion, which makes the count not drift any more. If a future
  maintainer re-introduces a count claim somewhere, the deletion
  pattern is now precedent. The reviewer's runtime-derive alternative
  (a `::notice::` GHA annotation) was not adopted — the reviewer
  explicitly preferred the deletion. No action.

- **Concurrent BD-117 fix coder may also be editing this workflow's
  header for cross-references to RELEASE-GATE.md item descriptions.**
  Per the prompt, BD-117 fix coder is editing `RELEASE-GATE.md` and
  possibly `EXECUTION-PLAN-V11.0.md`. The Item 4 wording I added in
  the workflow header for F4 ("this workflow's overall status on the
  candidate-tag SHA (no dedicated step; the workflow's own pass/fail
  is the signal)") is the reviewer's own suggested phrasing from
  PACK-REVIEW-BD-118-RETRO.md F4 and matches the verbatim language in
  RELEASE-GATE.md lines 159-185 ("the GitHub Actions workflow ...
  shows both the `validate` and `tests` jobs green on the **exact
  candidate-tag SHA**"). If BD-117 retro fix changes the RELEASE-GATE
  Item 4 wording, Pack Chat may want to re-sync the workflow header
  comment; out of my scope.

- **`--all --clean` step name does not say `RELEASE-GATE item N`.**
  The build step itself is BD-115's owned surface, not a gate item; the
  reviewer noted in §4 (Acknowledgements) that BD-118 correctly
  suffixed only the steps that ARE gate items. No drift here. No
  action.

- **No new POQs raised.** All 6 findings had concrete fixes that fit
  cleanly inside BD-118's authorized surface plus the README's
  in-scope line. The reviewer's recommended Option A path was
  adopted as-is for F1 and combined with F5 per the reviewer's own
  combine-with-F1 suggestion.

- **No plan deviations.** Every fix matches the reviewer's recommended
  path; F4 (NIT #3) deletion was the reviewer's preferred option;
  F4 (NIT #4) phrasing is verbatim the reviewer's suggested
  parenthetical. F6 was the only finding the reviewer suggested
  declining; the prompt's success criteria explicitly required it
  to be addressed, so the ASCII-normalization path was chosen and
  documented in F6's subsection above.

---

## 6. Definition-of-Done checklist

| # | Success criterion (from prompt) | Status | Evidence |
|---|---|---|---|
| 1 | F1 (MUST): manifest-verify step actually detects committed-manifest drift on a fresh CI runner. | PASS | §2 F1 (Option A new step inserted between `--all --clean` and `--verify`); §4.3 mechanism walkthrough. |
| 2 | F2 (SHOULD): `--all --clean` step's mutation of a tracked file is documented. | PASS | §2 F5 (combined with F1 per reviewer); workflow header `SIDE EFFECT` line + new `(a2)` block. |
| 3 | F3 (NIT #2): `test-fixtures/README.md` line ~112 area accurately describes `--verify`. | PASS | §2 F2 README lines 117-121 rewrite; no false rebuild claim; line range within prompt-permitted area; no conflict with BD-122/BD-120 prior fix surfaces. |
| 4 | F4 (NIT #3): hardcoded "31 Checks" workflow strings stop drifting. | PASS | §2 F3 deletion at workflow header line 6 and Run-pack-validation step name; reviewer's preferred path adopted. |
| 5 | F5 (NIT #4): item-4 workflow header description notes item 4 is workflow's own status (no dedicated step). | PASS | §2 F4 (verbatim reviewer-suggested parenthetical adopted). |
| 6 | F6 (NIT #6): cosmetic em-dash inconsistency resolved. | PASS | §2 F6 (ASCII-everywhere path); §4.6 byte-level grep confirms zero em-dashes in workflow file. |
| 7 | Implementation report exists with required sections. | PASS | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-118-RETRO-FIX.md` (this file) — Summary, Per-finding, Files modified, Verification, Out-of-scope; section numbering 1-6 maps onto the prompt's 5-section spec (DoD added as conventional section 6 per `implementation-report` skill). |
| 8 | No edits to forbidden files. | PASS | §3 file inventory; only `.github/workflows/validate-pack.yml`, `test-fixtures/README.md`, and the new report file modified. No edits to `build.sh`, `RELEASE-GATE.md`, `EXECUTION-PLAN-V11.0.md`, `BACKLOG.md`, `CHANGELOG.md`, or any trinity / PM-only file. |
| 9 | No edits to README outside line ~112 area. | PASS | §3 file inventory; README edit at lines 117-121 only — well clear of BD-122 (commit `870f485`) and BD-120 (commit `94ae56c`) prior fix surfaces. |
| 10 | F1 fix verifiably closes the tautology. | PASS | §4.3 step-by-step mechanism: after `git checkout HEAD -- test-fixtures/manifest.txt`, `_verify` reads committed manifest; comparison now exercises actual gate condition. |
| 11 | Workflow YAML still parses. | PASS | §4.1 `python3 -c "import yaml; yaml.safe_load(...)"` clean; §4.2 `validate-pack.py` PASSED. |
| 12 | No untrusted-input expansion introduced. | PASS | §4.4 grep returns "no untrusted-input expansions present". |
| 13 | `if: always()` discipline preserved. | PASS | §4.5 `if: always()` count = 30, matches new step count. |

---

## 7. Proposed commit message

```
fix: v11 — BD-118 retro: close manifest-verify tautology + 5 ancillary fixes

Inserts a `git checkout HEAD -- test-fixtures/manifest.txt` step
between the `--all --clean` rebuild and `--verify` so the verify
step actually compares freshly-built fixtures against the
committed manifest instead of the just-rewritten one (F1, MUST).
Documents the side-effect of `--all` writing manifest.txt on the
runner (F5, SHOULD). Removes hardcoded `31 Checks` strings from
the workflow header and validate step name (F3 NIT). Clarifies
Gate item 4 description as the workflow's own status with no
dedicated step (F4 NIT). Updates `test-fixtures/README.md` to
stop falsely claiming `--verify` rebuilds (F2 NIT). Normalizes
em-dashes inside the workflow file to ASCII (F6 NIT).

Per `PACK-REVIEW-BD-118-RETRO.md` Batch 21c findings 1-6.
```

(Single-line preferred per `implementation-report` skill §1.9; multi-line
body included for the 6-finding summary. Pack Chat may rewrite.)
