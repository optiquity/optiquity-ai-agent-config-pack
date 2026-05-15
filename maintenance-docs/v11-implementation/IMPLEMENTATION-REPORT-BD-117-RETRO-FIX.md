# IMPLEMENTATION-REPORT-BD-117-RETRO-FIX — RELEASE-GATE retro fix

**Coder:** pack-coder (Batch 21c retro-fix)
**Date:** 2026-05-15
**BD scope:** BD-117 retro fixes only (Batch 21c)
**Review input:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-117-RETRO.md` (3 SHOULD + 4 NIT)
**Worktree HEAD at start:** `94ae56c3d0a8de24a1a789829510a387f8314584` (`v11-dev`)

---

## 1. Summary

All 7 retro findings (F1–F7) addressed. F1, F2, F3, F5, F6, F7 landed
as direct edits to `maintenance-docs/v11-implementation/RELEASE-GATE.md`
(34-line net delta on a 281-line file). F4 landed as a direct edit to
the Batch 24 Pre-tag-check row in
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` because
the surface area was a single-row, ≤2-line cross-reference addition —
within the prompt's direct-edit threshold. The `Last updated:` line
in RELEASE-GATE.md was bumped to 2026-05-15 with a one-line summary of
the retro fixes (matches the doc's own "update the timestamp when this
doc changes" rule). No file outside the prompt's allow-list was
modified. No state-changing git verb was run.

---

## 2. Per-finding fix detail

### F1 — `four declarative hook functions` should be five (SHOULD, CONTRACT)

**Finding (paraphrased):** Item 1 says "the four declarative hook
functions" but BD-119 framework declares **five** hooks
(`migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook`). The miscount drifts the gate text from
the canonical contract in `ARCHITECTURE-BD-119.md` and
`scripts/lib/migrator-core.sh`.

**Fix:** Updated `RELEASE-GATE.md` item 1 asserts paragraph (lines
51–58) to read "five declarative hook functions" and named them inline,
so future hook-count drift requires updating both this doc and
ARCHITECTURE-BD-119 §4.1 in the same commit (per the reviewer's
suggested fix — "future-proof the gate against future hook-count
drift").

**Before:**

```
contract (`MIGRATOR_*` env vars + the four declarative hook
functions). It is **not** a copy-and-rewrite of a previous version's
migrator.
```

**After:**

```
contract (`MIGRATOR_*` env vars + the five declarative hook
functions: `migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook`). It is **not** a copy-and-rewrite of a
previous version's migrator.
```

---

### F2 — §2 "Run order" mis-groups item 4 with working-tree state (SHOULD, OWNED)

**Finding (paraphrased):** §2 line 30–32 puts items 1 and 4 in the
"working-tree state" bucket; §4 line 229 (now 247–251) correctly puts
items 1 and 5 in that bucket. Item 4 is push+CI state, not working-tree
state. §4 is correct; §2 swapped item 4 and item 5.

**Fix:** Per the prompt's guidance ("§4 is correct; update §2 to match
§4, not the reverse"), updated `RELEASE-GATE.md` §2 (lines 32–35) to
group items 1 and 5 as working-tree-state and clarify items 2, 3, 4
must be re-run on the candidate-tag SHA. Added a forward-pointer to §4
for the per-item ordering rationale, so the two passages reinforce each
other instead of restating the same fact in two places.

**Before:**

```
- **Run order:** items 1 and 4 are working-tree state checks (run any
  time during release prep); items 2, 3, 5 are command-driven and should
  be re-run on the exact candidate-tag commit immediately before tagging.
```

**After:**

```
- **Run order:** items 1 and 5 are working-tree state checks (run any
  time during release prep, but items 2, 3, 4 must be re-run on the
  exact candidate-tag commit immediately before tagging — see §4 for
  the per-item ordering rationale).
```

---

### F3 — Item 4 common failure mode misses post-fixup re-verification (NIT, OWNED)

**Finding (paraphrased):** Item 4's common failure mode covers only the
"never pushed" case. A more frequent failure path is fixup-commit-moves-
SHA, where items 1/2/3/5 caught a problem, the maintainer pushed a
fixup, and the prior CI run no longer matches the candidate tag SHA.

**Fix:** Appended a "Note on fixup commits" paragraph after item 4's
common-failure-mode paragraph (RELEASE-GATE.md lines 199–203). Phrased
as the reviewer suggested, with explicit "re-run items 2, 3, 5 against
the new SHA and re-verify item 4 against the new SHA's CI run" so the
maintainer reading item 4 in isolation gets the full replay-path
expectation without having to look back at §4.

**Before (unchanged paragraph):**

```
**Common failure mode:** the candidate-tag commit was created locally
but never pushed, so no CI run exists for that SHA. Push the commit
to its release branch, wait for CI, then re-run the gate. Do **not**
tag a SHA without a green CI run.
```

**After (paragraph appended below the unchanged one):**

```
**Note on fixup commits:** any fix to items 1/2/3/5 that lands a fixup
commit changes the candidate-tag SHA. After each fixup, re-run items
2, 3, 5 against the new SHA and re-verify item 4 against the new SHA's
CI run before tagging. The previous CI run no longer satisfies item 4
once the SHA has moved.
```

---

### F4 — `EXECUTION-PLAN-V11.0.md §7` Pre-tag check row does not cite RELEASE-GATE (SHOULD, SHARED-RO)

**Finding (paraphrased):** RELEASE-GATE bills itself as "the last
barrier before `git tag`" and points to EXECUTION-PLAN §7 for context,
but EXECUTION-PLAN §7's Batch 24 Pre-tag-check row does not list
"RELEASE-GATE.md 5 items pass" as a pre-tag criterion. A maintainer
reading EXECUTION-PLAN at Batch 24 could miss the gate entirely.

**Direct-edit vs deferral decision:** Per the prompt's decision rule
("if the EXECUTION-PLAN Batch 24 row edit is ≤2 lines and adds a
`RELEASE-GATE.md` cross-reference, do it directly"), this fix qualifies
as direct: a single-phrase addition to the existing single-row table
cell that adds one cross-reference to RELEASE-GATE.md. No restructuring
of the row's scope description, no other §7 rows touched, no other
EXECUTION-PLAN sections consulted. Direct edit applied.

**Fix:** Added "RELEASE-GATE.md 5 items satisfied (per-item evidence in
BD-093 release-pin BD's `Resolved:` line — see
`maintenance-docs/v11-implementation/RELEASE-GATE.md`)" to the Pass
criteria column of the Pre-tag-check row at EXECUTION-PLAN-V11.0.md
line 435.

**Before:**

```
| Pre-tag check | Batch 24 | all BDs in §1.1–1.5 Resolved; BD-059 verified-closed; CI fully green; final audit clean; per-entry split mirror+TOC in-sync (Check 32+33) | Hold release; resolve gates first |
```

**After:**

```
| Pre-tag check | Batch 24 | all BDs in §1.1–1.5 Resolved; BD-059 verified-closed; CI fully green; final audit clean; per-entry split mirror+TOC in-sync (Check 32+33); RELEASE-GATE.md 5 items satisfied (per-item evidence in BD-093 release-pin BD's `Resolved:` line — see `maintenance-docs/v11-implementation/RELEASE-GATE.md`) | Hold release; resolve gates first |
```

---

### F5 — Item 3 omits BD-115 trace from item body (NIT, SHARED-RO)

**Finding (paraphrased):** §5 cross-references BD-115 (mid-dev fixture
consumed by mid-dev contract); item 3 body cites BD-116 and BD-088 but
not BD-115. Asymmetric — every other §5 BD is named in the item it
gates.

**Fix:** Appended a one-paragraph cross-reference to item 3's
common-failure-mode block (RELEASE-GATE.md lines 162–164), naming the
BD-115 fixture path explicitly and forward-linking item 3 to item 5.
This satisfies the §5 ↔ per-item-body symmetry the reviewer flagged
and aids run order in §4 (item 3 contract requires fixture from item 5
land first conceptually).

**Before (end of item 3 common-failure-mode):**

```
... v11.0 example: BD-161
(missing skill installs surfaced by the migration contract).
```

**After (one paragraph added immediately after the above):**

```
The `mid-dev` contract requires the BD-115 mid-development fixture
under `test-fixtures/existing-project-mid-dev/` to be built and
verified — see item 5.
```

---

### F6 — Item 1 grep regex overly strict on whitespace (NIT, OWNED)

**Finding (paraphrased):** The regex
`'^MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)='` requires column-1
declaration. Framework adapter currently does that, so test passes —
but a maintainer wrapping the declarations in a function or `if` block
would silently fail the gate even though the contract is satisfied.

**Fix selection:** Reviewer offered (a) tighten ARCHITECTURE-BD-119
to forbid wrapping (out of BD-117 retro scope; would require editing
ARCHITECTURE-BD-119 which is read-only context here per the prompt) or
(b) loosen the regex to tolerate leading whitespace. Chose (b) as the
minimum-surface fix that keeps the BD-117 retro within scope. Updated
the regex to `'^[[:space:]]*MIGRATOR_...'`.

**Before:**

```bash
grep -E '^MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \
    scripts/migrate-v<N>-to-v<N+1>.sh
```

**After:**

```bash
grep -E '^[[:space:]]*MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \
    scripts/migrate-v<N>-to-v<N+1>.sh
```

**Regression check:** The canonical column-1 case
(`scripts/migrate-v10-to-v11.sh` lines 73–75) still matches — the
loosened regex is strictly a superset of the original (zero or more
leading whitespace, including the zero-whitespace canonical case). See
§4 Verification.

---

### F7 — Item 4 pass criterion silent on in-flight CI runs (NIT, OWNED)

**Finding (paraphrased):** Pass criterion says `status == "completed"`
and `conclusion == "success"`, which is correct, but doesn't tell the
maintainer "wait for the run to finish before re-checking" if they're
running the gate immediately after pushing the release commit.

**Fix:** Added a fourth bullet to item 4's pass-criterion list
(RELEASE-GATE.md lines 190–192) phrased as the reviewer suggested,
with the `gh run watch <run-id>` command for completeness.

**Before (3-bullet list):**

```
- At least one workflow run exists for `headSha == $RELEASE_SHA`.
- That run's `status == "completed"` and `conclusion == "success"`.
- Both the `validate` and `tests` jobs report `success` (use
  `gh run view <run-id> --json jobs` to drill in if the top-level
  conclusion is ambiguous).
```

**After (4-bullet list):**

```
- At least one workflow run exists for `headSha == $RELEASE_SHA`.
- That run's `status == "completed"` and `conclusion == "success"`.
- Both the `validate` and `tests` jobs report `success` (use
  `gh run view <run-id> --json jobs` to drill in if the top-level
  conclusion is ambiguous).
- If `status` is `queued` or `in_progress`, wait for the run to
  finish (`gh run watch <run-id>`) and re-check; do not proceed to
  tag until `status` is `completed` and `conclusion` is `success`.
```

---

### Auxiliary edit — `Last updated:` timestamp

Bumped the `Last updated:` line at RELEASE-GATE.md line 3 to
`2026-05-15` with a one-line description of the BD-117 retro fix
scope. This satisfies the doc's own §4 maintenance rule ("update the
`Last updated:` line whenever this document changes").

**Before:**

```
**Last updated:** 2026-05-12 (v11.0 development; BD-117).
```

**After:**

```
**Last updated:** 2026-05-15 (v11.0 development; BD-117 retro fix —
hook count, §2/§4 alignment, fixup re-verification, BD-115 trace,
regex tolerance, in-flight CI guidance).
```

---

## 3. Files modified

| Path | Change type | Net line delta | Findings addressed |
|---|---|---|---|
| `maintenance-docs/v11-implementation/RELEASE-GATE.md` | modified | +25 / −7 (net +18, file went 263 → 281 lines) | F1, F2, F3, F5, F6, F7, plus aux timestamp bump |
| `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | modified | +1 / −1 (net 0, file unchanged at 465 lines; row reflowed) | F4 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117-RETRO-FIX.md` | new | this report | (workflow artifact) |

`git diff --stat` cross-check (run at end of session):

```
.../v11-implementation/EXECUTION-PLAN-V11.0.md     |  2 +-
.../v11-implementation/RELEASE-GATE.md             | 34 +++++++++++++++++-----
2 files changed, 27 insertions(+), 9 deletions(-)
```

Files NOT touched (per prompt forbidden list): `BACKLOG.md`,
`CHANGELOG.md`, `scripts/lib/migrator-core.sh`,
`.github/workflows/validate-pack.yml`, `test-fixtures/README.md`, all
other files in the repo.

---

## 4. Verification

### F1 — hook count internally consistent across three docs

Authoritative source: `scripts/lib/migrator-core.sh` lines 147–153
declares `_migrator_required_hooks` as a 5-element bash array:

```
_migrator_required_hooks=(
    migrator_manifest
    migrator_directory_sweeps
    migrator_relocations
    migrator_artifact_installs
    migrator_post_report_hook
)
```

`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` lines
264–269 enumerates the same 5 hooks in the adapter shape example.

`maintenance-docs/v11-implementation/RELEASE-GATE.md` line 57 (post-fix)
now reads "five declarative hook functions" and lists the same 5 names
in the same order.

`grep -nE 'four declarative' RELEASE-GATE.md` returns zero matches
post-fix. `grep -nE 'five' RELEASE-GATE.md` returns 5 matches (lines 8,
20, 23, 57, 243), all internally consistent (item count, name count,
five-item-fixed rule).

**Result:** PASS — three docs agree on 5 hooks; no stale "four"
references remain.

---

### F2 — §2 and §4 working-tree groupings agree

`maintenance-docs/v11-implementation/RELEASE-GATE.md` §2 line 32 (post-
fix): "items 1 and 5 are working-tree state checks".

`maintenance-docs/v11-implementation/RELEASE-GATE.md` §4 line 247–248
(unchanged, was already correct): "Item ordering is significant for
items 1 and 5 (they are working-tree state — must be true at tag
time)".

Both passages now name {1, 5} as the working-tree-state items and {2,
3, 4} as the candidate-SHA-bound items. Item 4's own body (lines 161–
163) confirms it requires the workflow run on the **exact candidate-
tag SHA**, which is push+CI state — consistent with the new §2 grouping.

`grep -nE 'working-tree state' RELEASE-GATE.md` returns 2 matches (line
32, line 248), both naming items 1 and 5.

**Result:** PASS — §2 and §4 agree; item 4 body remains aligned with
both.

---

### F6 — loosened regex does not regress the existing positive case

Ran the new regex against the canonical adapter file to confirm
backwards compatibility:

```
$ grep -E '^[[:space:]]*MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \
    scripts/migrate-v10-to-v11.sh
MIGRATOR_FROM_VERSION="v10"
MIGRATOR_TO_VERSION="v11"
MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"
```

All three expected lines still match. The `[[:space:]]*` quantifier is
zero-or-more, so the column-1 canonical case continues to match
identically. The regex is now also tolerant of leading whitespace —
exactly the robustness improvement the reviewer suggested.

**Result:** PASS — no regression; adds tolerance for indented
declarations a future maintainer might write.

---

### F3, F5, F7 — additive prose checks

All three additions are pure prose appends; no syntax/regex/contract
checking required. Visual confirmation via `Read` after each edit
confirmed text landed at the intended location with no surrounding-text
disruption. `grep -nE 'BD-115|in_progress|gh run watch|fixup'` returned
the expected hits at the new locations (lines 162, 190, 191, 199).

**Result:** PASS — three prose additions verified in place.

---

### F4 — EXECUTION-PLAN cross-reference landed

`grep -n 'RELEASE-GATE' EXECUTION-PLAN-V11.0.md` returns 3 hits:

- line 35 (existing §1.1 BD-117 entry — unchanged)
- line 287 (existing §6 wave table — unchanged)
- line 435 (NEW — Pre-tag-check row pass criterion)

The Pre-tag-check row now contains the back-reference to
RELEASE-GATE.md, completing the bidirectional link the reviewer
flagged as missing.

**Result:** PASS — back-reference present; row remains a single
markdown table row.

---

### Auxiliary — `Last updated:` line bumped

RELEASE-GATE.md line 3–5 now records `2026-05-15` with the BD-117
retro-fix description. Satisfies the doc's own §4 self-maintenance
rule.

**Result:** PASS.

---

## 5. Out-of-scope items / observations

The following surfaced during review-doc reading or context cross-
checks but were **not** acted on. Pack Chat decides tracking per the
deferred-work rule.

1. **Reviewer methodology friction notes (PACK-REVIEW-BD-117-RETRO
   §7).** The reviewer flagged four prompt-template friction items
   (output-file vs system-reminder conflict, touch-point classification
   for prose docs, `IMPLEMENTATION-PLAN-V11.0.md` vs `EXECUTION-PLAN-
   V11.0.md` filename mismatch, and BD-138 batch-renumbering scope
   ambiguity) — these are tracked as Batch 21c retro-cycle infra
   improvements, not BD-117 fixes. No action taken; surfaced here for
   completeness so Pack Chat can decide whether they roll up into a
   single Batch 21c retro-template polish item.

2. **F6 alternative — ARCHITECTURE-BD-119 §4.1 explicit "no wrapping"
   rule.** The reviewer's option (a) was to tighten ARCHITECTURE-BD-119
   to forbid wrapping the `MIGRATOR_*` env-var declarations, making the
   regex's strictness intentional. Chose option (b) (loosen the regex)
   as the BD-117-scoped fix. Option (a) remains a possible future
   contract-tightening BD if the wrapping case becomes a real concern.
   Not opened as a deferred BD here — the loosened regex satisfies the
   robustness goal without requiring a contract change.

3. **EXECUTION-PLAN §7 row reflow.** The new Pre-tag-check row Pass
   criteria column is now noticeably longer than the others in the §7
   table. If Pack Chat finds the resulting render too wide, the
   `RELEASE-GATE.md` pointer could be moved to a footnote or to a
   separate row. Not done here — the prompt scoped the F4 fix to a
   single-row cross-reference, and the row remains a single table row.

4. **`Last updated:` description length.** Bumped the timestamp line to
   include a one-line summary of the retro fixes. Pack Chat may prefer
   the bare-date format. If so, a one-line follow-up edit can revert
   to `**Last updated:** 2026-05-15 (v11.0 development; BD-117 retro fix).`
   without retro-changing the substantive edits.

No new BDs proposed (BD-117 retro is fix-only per the prompt and the
"BDs reserved for new scope" rule). No POQs introduced. No deviation
from the prompt's plan.

---

## 6. Definition-of-Done checklist

| Criterion | Status |
|---|---|
| F1 (hook count) — RELEASE-GATE.md matches BD-119 5-hook reality | PASS |
| F2 (§2/§4 agreement) — both name {1, 5} as working-tree-state | PASS |
| F3 (item 4 fixup re-verification) — note appended to item 4 | PASS |
| F4 (EXECUTION-PLAN back-reference) — Batch 24 row cites RELEASE-GATE.md | PASS (direct edit, single-row) |
| F5 (item 3 BD-115 trace) — body now names BD-115 + forward-links item 5 | PASS |
| F6 (item 1 grep regex) — loosened to tolerate leading whitespace; canonical case still matches | PASS |
| F7 (item 4 in-flight CI) — bullet added with `gh run watch` | PASS |
| `Last updated:` line bumped per doc's own §4 rule | PASS |
| No edits to forbidden files (`BACKLOG.md`, `CHANGELOG.md`, `migrator-core.sh`, `validate-pack.yml`, `test-fixtures/README.md`) | PASS |
| No state-changing git verbs run | PASS |
| Implementation report exists at the prompt-specified path | PASS |
| Internal consistency verified for F1, F2, F6 | PASS |

All 7 findings addressed by direct fix. Zero deferrals. Zero new BDs.
Zero plan deviations.

---

## 7. Final HEAD SHA

`git rev-parse HEAD` at end of session: `94ae56c3d0a8de24a1a789829510a387f8314584`
(unchanged — no commits made by this agent, as per the "agents never
commit" pack rule). All edits are in the working tree, ready for Pack
Chat to stage and commit.
