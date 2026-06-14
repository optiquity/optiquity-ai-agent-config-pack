# IMPL-REPORT — BD-197 fix the two non-blocking SHOULD findings (S3-2, S3-1)

**Agent:** pack-coder
**Date:** 2026-06-13
**Branch:** v11-dev
**HEAD at start + end (no state-changing git verbs run):** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`)
**Scope:** EXACTLY two doc-text corrections in two files. No other change. Carve-out
implementation (C0) NOT touched — that is a separate later commit.

---

## Pre-flight (hard rule)

- `git rev-parse HEAD` → `ae3d9325889c41f7cba7a4289437cf7a87d04292`
- `git status` confirmed branch `v11-dev`; the two target files present:
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — tracked, already `M` (pre-existing inherited working-tree diff from prior session work, +390/-84 vs HEAD; NOT my work).
  - `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — UNTRACKED (`??`); no committed baseline, so all FIX-2 edits live within the not-yet-committed file.
- Base correct: both files exist with the §17 / §E / §F sections the prompt named.

---

## FIX 1 (S3-2) — design doc stale CI-invocation count (~155 → 186)

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`, §17.7 (Runtime — ci-check-runtime-compounding).

**Whole-doc grep before editing** confirmed exactly ONE `155` occurrence, and it
referred to the validate-pack battery invocation count:

```
$ grep -nE '155' .../ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
867:the ~155 validate-pack invocations in the battery.
```

No other `155` anywhere in the doc → no unrelated number touched.

**Edit (line 867, in §17.7):**

- BEFORE: `no whole-tree scan; Check 36 still walks only the commits in its range / (default = HEAD only). Added cost is negligible and does not compound across / the ~155 validate-pack invocations in the battery.`
- AFTER: `... and does not compound across / the 186 validate-pack invocations in the battery.`

(Only the `~155` token → `186`; the surrounding sentence is unchanged.)

### Empirical confirmation of 186 (empirical-evidence-blocks)

- Command: `grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk -F: '{s+=$2} END{print s}'`
- Verbatim output:
  ```
  186
  ```
- HEAD/date: `ae3d932` / 2026-06-13.
- Interpretation: the validate-pack battery invokes `validate-pack.py` 186 times across `scripts/tests/*.sh`. The design's `~155` is stale; 186 is the measured value (and matches the plan's EE-1, which also records 186).
- Conclusion: SUPPORTED — `~155` corrected to `186`.

**Post-edit verification:**
```
$ grep -nE '186 validate-pack|155' .../ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
867:the 186 validate-pack invocations in the battery.
$ grep -c '155' .../ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
0
```
186 present at §17.7; zero `155` remaining anywhere in the doc.

---

## FIX 2 (S3-1) — plan Guard-A allowlist + measure-at-commit reinforcement (§E, §F EE-2)

**File:** `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md`.

### Live re-measure of the prohibition-only matcher (empirical-evidence-blocks)

- Command: `rg -l --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'`
- Verbatim count: `23` (`... | wc -l` → `23`).
- Verbatim per-file list (live, HEAD `ae3d932`, 2026-06-13):
  ```
  CLAUDE.md
  pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
  maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md
  maintenance-docs/archive/v11/PLAN-BD-175-PHASE-5.md
  maintenance-docs/archive/v11/PACK-REVIEW-CLEANUP-BATCH-19B-19b-1.md
  maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md
  maintenance-docs/archive/v11/PACK-REVIEW-V10.1-BACKPORT.md
  maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-181-PRECONDITION.md
  maintenance-docs/archive/v11/PLAN-CLEANUP-BATCH-19B.md
  maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md
  maintenance-docs/archive/v11/PACK-REVIEW-BD-181-PRECONDITION.md
  maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-180-FIX-2.md
  maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md
  maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md
  maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md
  maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL.md
  maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md
  maintenance-docs/v11-implementation/RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md
  maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
  maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md
  maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md
  maintenance-docs/v11-implementation/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md
  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C9.md
  ```
- Per-file match counts for the three PLAN-adversarial reviews (the KEEP carriers in question):
  ```
  PACK-REVIEW-BD-197-PLAN-ADVERSARIAL.md   = 8
  PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md = 3
  PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md = 3
  ```
- HEAD/date: `ae3d932` / 2026-06-13.
- Interpretation: the matcher returns **23** files = 9 archive + 4 STRIP + 10 active-KEEP. The delta vs the plan's recorded 22 is exactly +1 = `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md` (the 3rd review doc, 3 matches — it quotes the regex), which did not exist when the plan was last measured. This is precisely the behavior the plan's re-measure-at-commit mandate predicts (the BD-197-process/review-doc carrier set grows with every review pass).
- Conclusion: SUPPORTED — EE-2 count corrected 22 → 23; the 3rd review doc added to the KEEP-carrier enumeration; the static-count anchoring risk reinforced.

### Edits made (all in-place, §E Guard-A + §F EE-2 only)

1. **§E Guard-A step 1 (line 226)** — count 22 → 23 + measure-at-C5-commit reinforcement appended:
   - BEFORE: `**Live at this HEAD this matcher returns 22 files** (§F EE-2) — ... SELF-MATCH.`
   - AFTER: `**Live at this HEAD this matcher returns 23 files** (§F EE-2) — ... SELF-MATCH. **This 23-file count + the KEEP set below are MEASURED AT C5 COMMIT-TIME (illustrative as-of-now; the BD-197-process/review-doc set grows with every pass — this plan, each PLAN-adversarial review, any future review keeps matching). The C5 coder RE-MEASURES live at commit-time and allowlists EVERY then-existing BD-197-process/review doc that quotes the regex, plus the validator self-skip + the single check-53 test. Do NOT anchor on this static number.**`

2. **§E Guard-A step 2 (iii) (line 227)** — KEEP-carrier enumeration now names all three reviews + narrow-exception reinforcement:
   - BEFORE: `(iii) **allowlist the measured BD-197 doc carriers** (per-file KEEP, §F EE-2).`
   - AFTER: `(iii) **allowlist the commit-time-MEASURED BD-197 doc carriers** (per-file KEEP, §F EE-2 — as-of-now this includes all three \`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL{,-2,-3}.md\` reviews; the C5 coder re-measures and allowlists every then-existing BD-197-process/review doc that matches — NOT a static list). **The narrow exception stays NARROW: validator self-skip + ONLY the single check-53 test file + the measured doc carriers — do NOT widen to the whole \`scripts/tests/\` dir.**`

3. **§E Guard-A step 5 PREFLIGHT (line 230)** — re-measure-live reinforcement so the C5 coder does not trust the static count:
   - BEFORE: `**PREFLIGHT (decision 1):** the C5 coder asserts the matcher returns EXACTLY the measured legitimate set INCLUDING the just-authored validator (self-skipped) + the new check-53 test (allowlisted).`
   - AFTER: `**PREFLIGHT (decision 1):** the C5 coder RE-MEASURES the matcher LIVE at commit-time (do NOT trust this plan's as-of-now 23-file count) and asserts the matcher returns EXACTLY the then-measured legitimate set INCLUDING the just-authored validator (self-skipped) + the new check-53 test (allowlisted) + every then-existing BD-197-process/review doc that quotes the regex (the set keeps growing).`

4. **§F header re-measurement summary (line 255)** — delta note updated to 23 + 3rd-review attribution:
   - BEFORE: `... EE-2's prohibition-only matcher now returns **22** files (prior plan: 21), the +1 being \`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md\` (3 matches ...), exactly the re-review's own S-1 prediction. ...`
   - AFTER: `... EE-2's prohibition-only matcher now returns **23** files (prior plan: 21, then 22 with the 2nd review), the latest +1 being \`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md\` (3 matches — it QUOTES the regex), exactly as the re-measure-at-commit mandate predicts (the BD-197-process/review-doc carrier set grows with every review pass). ...`

5. **§F EE-2 Output (line 266)** — count 22 → 23, active 13 → 14, added the 3rd review (`=3`) to the per-file list, KEEP 9 → 10:
   - Added `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md`=3 (the 3rd/final plan review) to the per-file KEEP enumeration; updated `13 active` → `14 active` and `(these 9 are KEEP)` → `(these 10 are KEEP)`.

6. **§F EE-2 Interpretation (line 268)** — breakdown 22 (=9+4+9) → 23 (=9+4+10), +1 attribution to the 3rd review, KEEP allowlist "BOTH PLAN-adversarial reviews" → "all three PLAN-adversarial reviews — the 1st, the 2nd/re-review, AND the 3rd/final review", measure-at-C5 reinforcement.

7. **§F EE-2 Conclusion (line 269)** — `SUPPORTED (corrected to 22)` → `SUPPORTED (corrected to 23)`, "all three PLAN-adversarial reviews", explicit "this 23-file count + KEEP set are illustrative as-of-now, NOT static", and the narrow-exception-stays-narrow restatement.

### Post-edit verification (FIX 2)

```
$ grep -nE 'returns 23 files|23 = 9 archive|corrected to 23|PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3' PLAN-BD-197-WORKTREE-ISOLATION.md
226: ... returns 23 files ... (3rd review measure-at-commit reinforcement)
255: ... now returns **23** files ... PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md ...
266: ... **23 files** ... PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md`=3 ... (these 10 are KEEP)
268: **23 = 9 archive + 4 STRIP + 10 active-KEEP.** ... all three PLAN-adversarial reviews ...
269: SUPPORTED (corrected to 23) ... all three PLAN-adversarial reviews ...
```
23-file count, all-three-reviews KEEP enumeration, and measure-at-commit reinforcement all present in §E + §F.

---

## Confirmation: no other content changed

- **Only two files touched.** No edit to `scripts/validate-pack.py`, the check-53 test, the commit sequence, the BD entries, or any other doc.
- **Design doc:** my only change is the single §17.7 token `~155`→`186` (one `+` line at diff line 631; zero `155` remaining). The large pre-existing `M` working-tree diff (+390/-84) on this file was present at session start (it was already `M` in the pre-flight `git status`) and is prior-session work, NOT mine.
- **Plan doc:** UNTRACKED (`??`) at session start; all FIX-2 edits are in-place targeted `old→new` substitutions to §E (Guard-A) and §F (EE-2). Carve-out logic (C0 / §17 forced-co-variant, EE-10), the 12-commit sequence, Guard-B/Guard-C, and all other sections were NOT modified by me.

### Out-of-scope stale references SURFACED (not fixed — scope is §E + §F only)

The prompt scoped me to "only the EE-2 count/KEEP-list + the measure-at-commit reinforcement in §E/§F. Do NOT change ... any other §." The following sections of the PLAN doc carry the now-superseded "22" / "BOTH PLAN-adversarial reviews" narrative and are LEFT UNCHANGED per that scope directive. Surfacing for Pack Chat triage (they are internally inconsistent with the §E/§F edits I made):

- §1 attestation (line 10): `the prohibition-only matcher now returns **22** files ... the +1 is PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md`
- §1 Pass header (line 7): `S-1 Guard-A allowlist grows by BOTH PLAN-adversarial reviews`
- §J J-resolved-5 (line 403): `The matcher returns 22 live`
- §J J-resolved-12 (line 411): `names BOTH PLAN-adversarial reviews ... the matcher returns 22 live`
- §J anchors (line 433): `BOTH PLAN-adversarial reviews ... ADVERSARIAL.md (1st, 8) AND ...ADVERSARIAL-2.md (2nd, 3)`
- §J anchors (line 434): `The prohibition matcher now returns 22`
- §K Rules-Applied row 2 (line 445): `prohibition matcher **22** files`
- §K Rules-Applied row 6 (line 449): `measure the prohibition matcher (22 live)`
- §K PLAN-READY (line 464): `the one material delta is the 22-file prohibition matcher` and `S-1 (Guard-A allowlist grows by BOTH plan reviews)`

Recommendation (for Pack Chat, NOT applied by me): a follow-up scoped edit (or a widened re-prompt of this coder) to harmonize these §1/§J/§K references with the §E/§F 23-count + all-three-reviews KEEP set, so the plan is internally consistent before commit.

---

## Files changed inventory

| Path | Change type | My change |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` | modified (tracked, pre-existing `M`) | §17.7 only: `~155` → `186` (one line) |
| `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` | modified (untracked `??`) | §E Guard-A (steps 1, 2-iii, 5) + §F header + §F EE-2 (Output, Interpretation, Conclusion): 22 → 23, +3rd review KEEP, measure-at-commit reinforcement |

No new files (this IMPL-REPORT aside). No deletions.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| FIX 1: §17.7 `~155` → `186` | PASS |
| FIX 1: whole-doc grep for other validate-pack-battery `155` refs (found 1, corrected; no unrelated number touched) | PASS |
| FIX 1: 186 empirically confirmed via the prescribed command + output quoted | PASS |
| FIX 1: zero `155` remaining in design doc | PASS |
| FIX 2: §F EE-2 count updated to live measured value (23) | PASS |
| FIX 2: 3rd review doc added to per-file KEEP enumeration (all three ADVERSARIAL{,-2,-3}) | PASS |
| FIX 2: matcher re-measured LIVE; count + per-file list quoted | PASS |
| FIX 2: measure-at-C5-commit-time reinforcement added in §E + §F (do-not-anchor-on-static-count) | PASS |
| FIX 2: NARROW-exception decision kept intact (validator self-skip + ONLY check-53 test + measured doc carriers; NOT whole scripts/tests/) | PASS |
| Carve-out logic / commit sequence / other §§ unchanged | PASS |
| Only the two named files edited; nothing else | PASS |
| No state-changing git verb run | PASS |
| Out-of-scope stale refs surfaced (not silently fixed) | PASS |

---

## Plan deviations

ZERO. Both fixes applied exactly as scoped; out-of-scope stale references surfaced rather than fixed (per the explicit §E/§F-only scope + scope-deliverables-to-the-ask).

## New POQs introduced

None affecting design/architecture. One process note surfaced for Pack Chat: the §1/§J/§K stale "22"/"BOTH reviews" references (listed above) need a follow-up scoped edit to keep the plan internally consistent — this is a scope-boundary artifact of the §E/§F-only instruction, not a design gap.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | edit-in-place-not-full-rewrite [universal] | All edits were targeted `old_string → new_string` replacements via the Edit tool (8 edits total: 1 in the design doc, 7 in the plan), each matching a unique existing string. NO wholesale rewrite — both files retain all prior sections. Re-read the edited regions after editing (design §17.7 line 867; plan §E lines 225-231 + §F lines 255/266/268/269). Diff isolation confirmed: design doc shows exactly one `+the 186 validate-pack invocations` line at diff line 631 and `grep -c '155'`=0; no collateral change to surrounding prose. | COMPLIANT |
| 2 | empirical-evidence-blocks [coder] | FIX 1: `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'` → verbatim `186`; HEAD `ae3d932`; 2026-06-13. FIX 2: `rg -l ... 'no worktree isolation\|Do not pass .*isolation.*worktree' ...` → 23-file list quoted verbatim above; per-file counts ADVERSARIAL=8/-2=3/-3=3 quoted; HEAD `ae3d932`; 2026-06-13. Both counts backed by command + verbatim output + HEAD-SHA + date + interpretation + conclusion. | COMPLIANT |
| 3 | scope-deliverables-to-the-ask [universal] | Exactly the two prescribed fixes applied; only the two named files edited (`git status` shows only `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` and `PLAN-BD-197-WORKTREE-ISOLATION.md`). The 9 out-of-scope stale "22"/"BOTH reviews" refs in §1/§J/§K were SURFACED (with line numbers + recommendation), not silently fixed, honoring the explicit "do NOT change any other §" directive. No scope creep. | COMPLIANT |
| 4 | preflight-stop-means-stop [universal] | Emitted the single line `PREFLIGHT: 2/2 fixes complete; both files edited ...; HEAD ae3d932; about to Write IMPL-REPORT to <path>` only AFTER both edits done and after re-grep confirmed 186 present / zero 155 (design) and "23 files"/"corrected to 23"/all-three-reviews present (plan). No stop/halt/revert message received during the task. | COMPLIANT |
| 5 | agents-never-commit [universal] | Ran only read-only git verbs (`git rev-parse HEAD`, `git status`, `git ls-files --error-unmatch`, `git diff --stat`, `git diff`) + Read/Edit/Write/grep/rg. No `git add`/`commit`/`push`/`tag` or any state-changing verb. The orchestrator commits. | COMPLIANT |
| 6 | rules-applied-verification-block [universal] | This block. | COMPLIANT |

---

# Harmonization pass — make §1/§J/§K internally consistent with the corrected §E/§F

**Agent:** pack-coder (fresh)
**Date:** 2026-06-13
**Branch:** v11-dev
**HEAD at start + end (no state-changing git verbs run):** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`)
**File edited:** `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` (ONLY)

## Why

A prior FIX pass corrected §E (line 226) + §F (lines 255/266/268/269) of the plan
to the live measured value — prohibition-matcher count **23** (was 22), and the
Guard-A KEEP carrier set named all THREE PLAN-adversarial reviews
(`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL.md`, `-2.md`, `-3.md`). But the SAME
narrative still read stale in §1 (attestation + Pass summary), §J (decision
ledger J-resolved rows), and §K (out-of-scope + Rules-Applied + PLAN-READY),
leaving the doc internally inconsistent — §F said "23 / all three" while §1/§J/§K
still said "22 / BOTH (two) reviews". This pass harmonizes the WHOLE document to
§E/§F's already-correct framing.

## What changed (count + review-doc-set references ONLY — no other change)

10 targeted in-place edits across 9 stale references (line 464 carried two):

| § / location | Before (stale) | After (harmonized) |
|---|---|---|
| §1 line 7 (Pass / S-1 fold) | "S-1 Guard-A allowlist grows by BOTH PLAN-adversarial reviews" | "grows by all THREE PLAN-adversarial reviews — `…ADVERSARIAL.md`, `-2.md`, and `-3.md`" |
| §1 line 10 (attestation delta) | "now returns **22** files (prior plan: 21) — the +1 is `…ADVERSARIAL-2.md`" | "now returns **23** files (prior plan: 21, then 22 with the 2nd review) — the latest +1 is `…ADVERSARIAL-3.md` … all THREE … now match — see §F EE-2 … measure-at-C5-commit framing" |
| §J line 403 (J-resolved-5) | "The matcher returns 22 live (EE-2 corrected; +1 = the re-review doc, S-1)." | "returns 23 live as-of-now (§F EE-2; +1 over the prior 22 = the 3rd/final review doc, S-1) — but the C5 coder re-measures … illustrative, not static" |
| §J line 411 (J-resolved-12) | "now names BOTH PLAN-adversarial reviews (the 1st AND the 2nd/re-review …); the matcher returns 22 live" | "now names all THREE … (`…ADVERSARIAL.md` 1st, `-2.md` 2nd, `-3.md` 3rd …); the matcher returns 23 live as-of-now" |
| §K line 433 (out-of-scope) | "incl. BOTH PLAN-adversarial reviews … now includes `…ADVERSARIAL.md` (1st, 8) AND `…ADVERSARIAL-2.md` (2nd, 3) as KEEP carriers" | "incl. all THREE … includes `…ADVERSARIAL.md` (1st, 8), `…-2.md` (2nd, 3), AND `…-3.md` (3rd, 3) as KEEP carriers" |
| §K line 434 (HEAD note) | "now returns 22 (was 21 …; +1 = `…ADVERSARIAL-2.md` …)" | "now returns 23 (was 21 …, then 22 …; the latest +1 = `…ADVERSARIAL-3.md` …; all THREE … now match)" |
| §K Rules-Applied row 2 (line 445) | "prohibition matcher **22** files (… +1 = re-review doc, EE-2)" | "**23** files (… latest +1 = the 3rd/final review doc, all three … now match, EE-2)" |
| §K Rules-Applied row 6 (line 449) | "measure the prohibition matcher (22 live)" | "(23 live as-of-now)" |
| §K PLAN-READY (line 464, two refs) | "the one material delta is the 22-file prohibition matcher" + "S-1 (Guard-A allowlist grows by BOTH plan reviews)" | "the 23-file prohibition matcher — all three … now match" + "grows by all THREE plan reviews — `-ADVERSARIAL{,-2,-3}.md`" |

**Framing preserved (matches §E/§F):** the count is MEASURED AT C5 COMMIT-TIME
(illustrative as-of-now; the C5 coder re-measures + allowlists every then-existing
BD-197-process/review doc that matches + the validator self-skip + the single
check-53 test); the NARROW self-exception is intact. The "21 → 22 → 23" HISTORY
progression is kept parallel to §F (lines 255/268 already carry "21, then 22 with
the 2nd review").

## Verification (empirical — before/after grep)

**Before (stale-as-current references existed in §1/§J/§K):**
Pre-edit inventory grep located 9 stale references at lines 7, 10, 403, 411, 433,
434, 445, 449, 464 (matching the prior coder's enumeration; line numbers found by
grep, not trusted).

**After (POST-EDIT grep, command + verbatim output, HEAD `ae3d932`, 2026-06-13):**

Command A — stale "22"-as-current-count:
```
grep -nE 'returns \*\*22\*\*|returns 22 live|matcher \(22 live\)|\*\*22\*\* files|22-file prohibition|now returns 22|now 22\b|matcher returns 22|= 22 live' PLAN-BD-197-WORKTREE-ISOLATION.md
```
Output: `(none — CLEAN)` — zero stale "22"-as-current-count.

Command B — stale "BOTH/two reviews" (implying only two):
```
grep -nE 'BOTH PLAN-adversarial|BOTH plan reviews|both plan reviews|two reviews|two PLAN-adversarial|the 1st AND the 2nd/re-review' PLAN-BD-197-WORKTREE-ISOLATION.md
```
Output: `(none — CLEAN)` — zero stale two-review phrasings.

**Remaining "22" mentions confirmed HISTORY-only (correct, must stay):** lines 10,
255, 268, 434 = "then 22 with the 2nd review" (the 21→22→23 progression); line 403
= "+1 over the prior 22" (history); line 82 = `line 22 \`Must start with
worktree-agent-\`` (a SKILL.md line-number ref, unrelated to the matcher).

**Remaining "BOTH/both" confirmed legitimate non-review contexts (correct, must
stay):** the two Check-36 offender branches (`pack_only`/`project_only`); the two
OPTIONAL-FEATURES surfaces (pack + project); the two settings keys
(`baseRef`+`bgIsolation`); "both `project-template/` AND `scripts/`"; "both
directions"; "both files exist"; "both committed". None imply a review count.

**Remaining "two" in non-review contexts (correct, must stay):** "two-independent-
mechanisms mode-model" (subagent vs background-session axes), "two-class framing"
(RW/RO), "two settings keys". None are review-doc references.

**Current-count token harmonized to "23" across §1/§J/§K:** confirmed present at
lines 10, 403, 411, 434, 445, 449, 464 (plus §E line 226 + §F 255/266/268/269/230
already correct).

## Scope discipline / surfaced (not fixed)

- ONLY count + review-doc-set references were changed. The carve-out logic, the
  12-commit sequence, the keywords, §E/§F's already-correct content, the design
  doc, `validate-pack.py`, and the BD entries were NOT touched.
- **SURFACED (not fixed — out of this pass's count/review-doc scope):** §F EE-2
  line 266 states "`PLAN-BD-197-WORKTREE-ISOLATION.md`=4 (this plan)" as a live
  per-file match count. Once THIS harmonization edit lands, the plan's own
  match-count MAY shift (the substituted prose adds/removes occurrences of the
  matcher-quoted strings). §F already frames every per-file count as "MEASURED AT
  C5 COMMIT-TIME — illustrative as-of-now, NOT a static list" and mandates the C5
  coder re-measure live, so the doc is self-consistent on this point and no fix is
  required — flagged only for awareness. Per scope discipline I did NOT re-measure
  or alter §F's per-file counts.

## Rules-Applied Verification Block — Harmonization pass

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | edit-in-place-not-full-rewrite [universal] | 10 targeted Edit-tool `old_string → new_string` replacements (table above), each a unique existing string; NO wholesale rewrite — the file retains all 11 lettered sections (§A–§K) + attestation + Rules-Applied block in unchanged order. The harness confirmed each Edit applied (would have errored otherwise); no re-read needed per harness state tracking. | COMPLIANT |
| 2 | empirical-evidence-blocks [coder] | Before/after grep quoted verbatim above: Command A (stale "22"-as-current) → `(none — CLEAN)`; Command B (stale "BOTH/two reviews") → `(none — CLEAN)`; both at HEAD `ae3d9325889c41f7cba7a4289437cf7a87d04292`, date 2026-06-13. Remaining "22"/"BOTH"/"two" occurrences each categorized as HISTORY/legitimate-non-review with the specific context quoted. | COMPLIANT |
| 3 | scope-deliverables-to-the-ask [universal] | ONLY count (22/21→23 or measure-at-commit) + review-doc-set (BOTH/two→all THREE) references changed; carve-out logic, 12-commit sequence, keywords, §E/§F content, design doc, validate-pack.py, BD entries all untouched. `git status --short` shows only `PLAN-BD-197-WORKTREE-ISOLATION.md` (untracked `??`, as at pre-flight). The §F per-file-count drift surfaced, not fixed. | COMPLIANT |
| 4 | preflight-stop-means-stop [universal] | Emitted the single line `PREFLIGHT: harmonization complete; grep shows 0 stale count/review refs; HEAD ae3d9325889c41f7cba7a4289437cf7a87d04292; about to Write IMPL-REPORT to <path>` ONLY after both post-edit greps returned CLEAN. No stop/halt/revert message received during the task. | COMPLIANT |
| 5 | agents-never-commit [universal] | Ran only read-only git verbs (`git rev-parse HEAD`, `git status`, `git status --short`) + Read/Edit/grep/sed-via-Bash + this Edit-append. No `git add`/`commit`/`push`/`tag` or any state-changing verb; HEAD unchanged at `ae3d932` start→end. Orchestrator commits. | COMPLIANT |
| 6 | rules-applied-verification-block [universal] | This block. Every rule from the prompt's RULES IN FORCE addressed with quoted evidence + terminal conclusion; no empty cell; no AMBIGUOUS state. | COMPLIANT |

*End of Harmonization pass (2026-06-13 — §1/§J/§K harmonized to §E/§F's corrected 23-count + all-three-reviews framing; HEAD `ae3d932` unchanged).*
