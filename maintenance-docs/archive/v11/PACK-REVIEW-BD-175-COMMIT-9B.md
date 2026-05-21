# PACK-REVIEW-BD-175-COMMIT-9B

**Reviewer:** pack-reviewer (per-commit review, background spawn concurrent with Commit 12 coder)
**Commit reviewed:** `ee9b385` "feat: v11 — BD-175 TASK-T5 MERGE-STRATEGY D8.6 ref-update (Override 8 cascade)"
**HEAD at review:** `de7f10c`
**Branch:** `v11-dev`
**Scope:** Verify coder satisfied `PLAN-BD-175-PHASE-5.md` §2.9b spec (single-hunk REPLACE in `pack-ops/MERGE-STRATEGY.md`)
**References consulted:** `PLAN-BD-175-PHASE-5.md` §2.9b + row 9b of §4.2 table; `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §3.5 D8.6; `pack-ops/MERGE-STRATEGY.md` at HEAD (lines 1-25, 455-482); diff `git show ee9b385`. IMPL-REPORT consulted AFTER independent findings formed (§3 below).

---

## §1 Verdict

**GO** — ship as-is; advance to Commit 12 coder.

The commit is a faithful, minimal-surface execution of PLAN §2.9b. The single-hunk REPLACE matches the architect spec byte-for-byte (`OPTIONAL-FEATURES.md` → `docs/pack/OPTIONAL-FEATURES.md`); the target file at `project-template/docs/pack/OPTIONAL-FEATURES.md` exists at HEAD (Commit 10 landed); surrounding prose is byte-identical pre/post; scope discipline is exemplary (1 file, +1/-1 lines, no trinity, no scripts, no project-template, no manifest). All 6 PLAN §2.9b.4 verification commands reproduce PASS. Item 8 (sibling-bare-refs assessment) yields one SHOULD-class finding documented in §4 — the commit-message-asserted rationale ("all 3 resolve at canonical pack-repo paths") is partially inaccurate (L471 `MIGRATION-v10-to-v11.md` actually lives at `supporting-docs/`, not pack root nor `pack-ops/`). Because the non-edit decision for sibling refs is explicitly out of PLAN §2.9b scope and was deliberately scoped out of the BD-175 §C/§D re-litigation framework (architect doc OQ-4 acknowledges F-4 QUICKSTART audience split as not designed), the finding does not block the commit — it should be triaged as a candidate Commit 12 cleanup or successor BD per the coder's own §6 recommendation.

---

## §2 Independent findings (per scope item)

### §2.1 — Item 1: Single-hunk REPLACE — exactly 1 file modified, exactly 1 line changed, no scope creep

**PASS.** `git show ee9b385 --numstat` returns:

```
274  0  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md
1    1  pack-ops/MERGE-STRATEGY.md
```

`pack-ops/MERGE-STRATEGY.md`: +1/-1 (single hunk). The 274-line IMPL-REPORT is the coder's standard output and does not count against scope creep per pack convention. No additional files; no manifest regen; no fixture changes; no script edits; no template edits. Verified scope-clean.

### §2.2 — Item 2: L472 post-edit reads `docs/pack/OPTIONAL-FEATURES.md`

**PASS.** `sed -n '472p' pack-ops/MERGE-STRATEGY.md` returns:

```
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

Byte-identical to PLAN §2.9b.2 "AFTER" spec. Note that the PLAN spec named L465 as the abstract target; actual line is L472 due to expected drift from post-Commit-2/3 relocation + Commit-9a audience-header insertion. Per the pack-memory rule "Architect-doc-vs-reality reconciliation" (line numbers drift; match on content uniqueness), this is correct execution — the BEFORE-text was unique in the file, so the content-match Edit produced an unambiguous result. The coder's `§9` Plan-Deviations clarification correctly framed this as a non-deviation.

### §2.3 — Item 3: Surrounding prose byte-identical pre/post

**PASS.** Pre-edit content at L468-L474 (from `git show ee9b385^:pack-ops/MERGE-STRATEGY.md`):

```
- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
- `QUICKSTART.md` — where to start
- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

Post-edit, only L472 (`OPTIONAL-FEATURES.md` line) changes. The 3 sibling lines (L468-L470 `scripts/lib/...`/`scripts/tests/...`) and the 3 trailing sibling lines (L471, L473, L474) are byte-identical. File line-count unchanged at 482 lines pre/post. The bullet outside the bare-ref token (`— tracker opt-in walkthrough`) is preserved byte-identically.

### §2.4 — Item 4: No bare `OPTIONAL-FEATURES.md` references remain

**PASS.** `grep -n "\`OPTIONAL-FEATURES\.md\`" pack-ops/MERGE-STRATEGY.md` returns no hits (exit code 1). `grep -c 'OPTIONAL-FEATURES\.md' pack-ops/MERGE-STRATEGY.md` returns 1 — that single remaining mention is the qualified `docs/pack/OPTIONAL-FEATURES.md` at L472. Zero bare references remain in the file.

### §2.5 — Item 5: Project-side file exists at HEAD

**PASS.** `ls project-template/docs/pack/OPTIONAL-FEATURES.md` returns:

```
-rw-r--r--@ 1 david  staff  7872 May 19 14:40 project-template/docs/pack/OPTIONAL-FEATURES.md
```

The project-side file exists (Commit 10 SPLIT landed), so the new `docs/pack/OPTIONAL-FEATURES.md` reference at L472 will resolve at client repos once `init-project.sh` installs the project-side file (per Commit 10's install plumbing).

### §2.6 — Item 6: No manifest regen needed

**PASS.** `git show ee9b385 --stat` shows only 2 paths:
- `pack-ops/MERGE-STRATEGY.md` (scope edit)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` (IMPL-REPORT)

No `test-fixtures/manifest.txt` entry. Per PLAN §2.9b.2 ("MODIFIED (test-fixtures/manifest.txt): NONE — pack-ops/ is NOT v11-surface per RC9 base case") and the pack-memory rule "Regenerate manifest on v11-surface commits" (trigger globs are `project-template/` and `scripts/` only; `pack-ops/` is excluded), no manifest regen was required and none was performed. Correct.

### §2.7 — Item 7: Scope discipline (no trinity, no scripts, no project-template, no pack-ops/OPTIONAL-FEATURES.md)

**PASS.** Diff confirms only `pack-ops/MERGE-STRATEGY.md` was modified:
- No `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` edits (Trinity untouched — N/A per PLAN §2.9b.5: "MERGE-STRATEGY.md is a single pack-side migration helper doc")
- No `scripts/` edits
- No `project-template/` edits
- No `pack-ops/OPTIONAL-FEATURES.md` edits (that file is Commit 10 territory; explicitly out-of-scope per PLAN §2.9b)
- No `supporting-docs/` edits
- No `test-fixtures/` edits

Scope is rigorously narrow.

### §2.8 — Item 8: Sibling bare refs in same cross-references list (L470-474)

**Independent judgment: SHOULD-class finding — partial defect in the commit-message rationale, but the non-edit decision itself is defensible.**

The Cross-references list at L468-L474 contains 7 entries; the coder edited only 1 (L472, the D8.6 target). The 3 sibling bare refs left untouched are:

| Line | Bare ref | Actual location | Resolvability comment |
|---|---|---|---|
| L471 | `` `MIGRATION-v10-to-v11.md` `` | `supporting-docs/MIGRATION-v10-to-v11.md` | **NOT at pack root or `pack-ops/`** — bare ref relies on reader knowing the `supporting-docs/` convention |
| L473 | `` `QUICKSTART.md` `` | `/QUICKSTART.md` (pack root) | Bare ref resolves at pack root for a pack-side reader; OK under "pack-internal refs in a pack-internal doc" framing |
| L474 | `` `validate-pack.py` Check 25 `` | `scripts/validate-pack.py` Check 25 | NOT at pack root — bare ref relies on reader knowing pack convention (analogous to coder's note in §6.1.c about path-resolvability asymmetry with L468-L470 entries which DO use `scripts/lib/` and `scripts/tests/` path prefixes) |

The commit-message rationale claims:

> all 3 resolve at canonical pack-repo paths for the pack-maintainer audience

That assertion is **partially inaccurate**:
- L471 `MIGRATION-v10-to-v11.md` does NOT live at pack root nor `pack-ops/`. It lives at `supporting-docs/MIGRATION-v10-to-v11.md`. A bare ref does not resolve canonically — it resolves only by convention.
- L474 `validate-pack.py` is at `scripts/validate-pack.py`, not pack root. Asymmetric with L468-L470 which use path-prefixed `scripts/lib/` / `scripts/tests/` entries.
- L473 `QUICKSTART.md` does live at pack root, so its bare ref is at-least-correct as a pack-root-relative resolvable reference.

The coder's own IMPL-REPORT §6.1 is more rigorous than the commit message — §6.1.a correctly notes that L471 location needs verification and surfaces it as a possible Commit 12 cleanup; §6.1.c correctly notes the path-resolvability asymmetry of L474 with sibling entries L468-L470. The IMPL-REPORT framing should have been carried into the commit-message rationale verbatim.

**Why this is SHOULD (not MUST) for this commit:**
1. PLAN §2.9b spec **explicitly** scopes this commit to "L465 ONLY" (single-hunk); §2.9b.3 Constraints state "do not re-edit the audience header (lands in 9a)" and define the edit as the single D8.6 ref-update. The architect-spec scope precludes the sibling edits in this commit.
2. Architect doc `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` does NOT include L471/L473/L474 in §C/§D contamination scope. OQ-4 (line 707) explicitly acknowledges F-4 (QUICKSTART audience split) was NOT designed by this framework: "QUICKSTART.md does not surface in the §C / §D contamination findings". So the sibling-ref bare-state is outside the BD-175 re-litigation universe by design.
3. Per pack-memory "Deferral IS scope creep / tech debt", however, the sibling-ref hygiene observation must NOT be silently dropped. The coder's §6 recommendation (surface for Pack Chat triage as Commit 12 cleanup candidate or new sub-BD) is the correct disposition; this finding needs an anchor — see §4 below.
4. The commit-message rationale inaccuracy is informational (audit-trail readability) — it does not affect the ship-correctness of the edit itself.

**Finding logged at SHOULD severity:** the commit-message rationale should be corrected (or annotated by a follow-on commit / BACKLOG entry) to reflect IMPL-REPORT §6.1's more rigorous framing, AND the 3 sibling-ref hygiene observations need a tracked anchor (live BD entry or Commit 12 broad-fix scope) per the "Deferral IS scope creep" rule.

---

## §3 Compare-to-IMPL-REPORT

Read `IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md` after forming the independent findings above. Comparison:

### §3.1 Alignments

- **§2.1 (single-hunk scope).** IMPL-REPORT §2 + §5.5 + §5.6 confirm exactly 1 file, +1/-1, single-hunk. Aligned.
- **§2.2 (L472 post-edit text).** IMPL-REPORT §3 + §5.2 reproduce the same `sed` output. Aligned.
- **§2.3 (surrounding prose).** IMPL-REPORT §4 quotes the same L460-L475 pre-edit context I verified independently. Aligned.
- **§2.4 (zero bare refs).** IMPL-REPORT §5.4 reproduces the same zero-hit `grep` result. Aligned.
- **§2.5 (project-side file exists).** IMPL-REPORT §5.1 confirms the `ls` of `project-template/docs/pack/OPTIONAL-FEATURES.md`. Aligned (exact same file size 7872 bytes and timestamp May 19 14:40 reported).
- **§2.6 (no manifest).** IMPL-REPORT §2 and §8 (DoD row "No manifest regen needed") confirm the same RC9 base-case reasoning. Aligned.
- **§2.7 (scope discipline).** IMPL-REPORT §5.5 + §8 + §11 confirm no out-of-scope edits. Aligned.
- **Line-number drift (L465 spec → L472 actual).** IMPL-REPORT §3 + §9 correctly frame this as content-uniqueness-matched, not a deviation. Aligned with pack-memory "Architect-doc-vs-reality reconciliation".

### §3.2 Divergences

- **§2.8 sibling-bare-refs rationale.** This is the only meaningful divergence. The IMPL-REPORT §6.1 framing is MORE RIGOROUS than the commit-message rationale: §6.1.a explicitly hedges ("recommend Pack Chat verify file location"), §6.1.c explicitly notes the path-resolvability asymmetry of L474 with L468-L470. The commit message asserts all 3 "resolve at canonical pack-repo paths" with more confidence than the IMPL-REPORT supports. The IMPL-REPORT also includes a §6.3 prevention-mechanism candidate (a `validate-pack.py` check for bare-cross-reference-list-items) that is a valuable Commit-12-scope suggestion. The commit-message scope-compression dropped these IMPL-REPORT nuances.
- **Pre-commit HEAD SHA.** IMPL-REPORT was written when HEAD was `4e240ec`; the commit landed at `ee9b385`; HEAD at review is `de7f10c` (so at least Commit 12 work has progressed since). No defect — this is normal progression. Logged for traceability.

### §3.3 Independent assessment validation

The 7 PASS items in §2 align with the coder's own DoD checklist (IMPL-REPORT §8). The 1 SHOULD finding in §2.8 corresponds to a soft observation the coder noted in §6 but did not surface as a triage-required finding. Reviewer judgment: the coder's §6 was conscientious but should have been escalated to "Pack Chat triage required" status more prominently — it's currently buried as "Out-of-scope observations" when it deserves "finding for next-commit-or-BD anchor".

---

## §4 Severity-classified findings table

| Severity | File:line | Finding | Rationale | Suggested fix |
|---|---|---|---|---|
| BLOCKER | — | (none) | All 6 PLAN §2.9b.4 verification commands PASS; scope clean; resolvable post-edit. | — |
| MUST | — | (none) | No defect that violates PLAN/architect spec. | — |
| SHOULD | `pack-ops/MERGE-STRATEGY.md:471, :473, :474` | 3 sibling bare refs in same cross-references list left unqualified; commit-message rationale claims "canonical pack-repo paths" but L471 (`MIGRATION-v10-to-v11.md` → `supporting-docs/MIGRATION-v10-to-v11.md`) and L474 (`validate-pack.py` → `scripts/validate-pack.py`) do not actually live at pack root. L473 (`QUICKSTART.md`) is at pack root and OK. | The non-edit is defensible (out of PLAN §2.9b scope; out of architect re-litigation §C/§D scope per OQ-4); the rationale framing is partially inaccurate. Per "Deferral IS scope creep", the 3 sibling observations need a tracked anchor. | (a) Acknowledge in Commit 12 broad-fix scope (Architect C M3a/M3b/M4/M5 prevention mechanisms can absorb L468-L474 cross-references-list normalization), OR (b) open a new BD inserted immediately after the current batch (per pack-memory "unblocked new BDs insert immediately after current BD/batch") covering bare-cross-reference-list hygiene in `pack-ops/` files. The IMPL-REPORT §6.3 proposed `validate-pack.py` check is a strong candidate for inclusion in (a) or (b). |
| NIT | `pack-ops/MERGE-STRATEGY.md` commit message | "all 3 resolve at canonical pack-repo paths" overstates the case versus IMPL-REPORT §6.1's more hedged framing | Audit-trail readability; the commit message is immutable but future references to this commit's rationale should defer to IMPL-REPORT §6.1 over the commit-subject footer. | No retroactive edit (git history immutable). Document the §6.1 IMPL-REPORT framing as the authoritative rationale in any successor BD's "prior-art" section. |

**Severity rollup:** 0 BLOCKER, 0 MUST, 1 SHOULD, 1 NIT. GO verdict.

---

## §5 Verification commands run + output

### §5.1 HEAD + commit stats
```bash
$ git rev-parse HEAD
de7f10c983015bf865ce921dd041cbf0f2c2027c

$ git show ee9b385 --stat --format=""
 .../IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md      | 274 +++++++++++++++++++++
 pack-ops/MERGE-STRATEGY.md                         |   2 +-
 2 files changed, 275 insertions(+), 1 deletion(-)
```

### §5.2 Numerical diff
```bash
$ git diff ee9b385^ ee9b385 --numstat
274  0  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md
1    1  pack-ops/MERGE-STRATEGY.md
```

### §5.3 Single-hunk content diff
```bash
$ git show ee9b385 -- pack-ops/MERGE-STRATEGY.md
@@ -469,7 +469,7 @@ default behavior):
 - `scripts/lib/customization-report.sh` — the report renderer
 - `scripts/tests/test-customization-preserve.sh` — class-coverage tests
 - `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
-- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
+- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
 - `QUICKSTART.md` — where to start
 - `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

### §5.4 L472 post-edit
```bash
$ sed -n '472p' pack-ops/MERGE-STRATEGY.md
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

### §5.5 Bare-ref hit count (item 4)
```bash
$ grep -n '`OPTIONAL-FEATURES\.md`' pack-ops/MERGE-STRATEGY.md
(no output; exit code 1 = zero hits)
$ grep -c 'OPTIONAL-FEATURES\.md' pack-ops/MERGE-STRATEGY.md
1   # the single remaining qualified ref at L472
```

### §5.6 Project-side file exists
```bash
$ ls -la project-template/docs/pack/OPTIONAL-FEATURES.md
-rw-r--r--@ 1 david  staff  7872 May 19 14:40 project-template/docs/pack/OPTIONAL-FEATURES.md
```

### §5.7 Pre/post line-count parity (surrounding prose unchanged)
```bash
$ git show ee9b385^:pack-ops/MERGE-STRATEGY.md | wc -l   # 482
$ git show ee9b385:pack-ops/MERGE-STRATEGY.md  | wc -l   # 482
```

### §5.8 Sibling-file location audit (item 8)
```bash
$ find . -name "MIGRATION-v10-to-v11*" -not -path "*/.git/*"
./supporting-docs/MIGRATION-v10-to-v11.md   # NOT at pack root, NOT in pack-ops/
$ ls QUICKSTART.md                           # at pack root → bare ref resolves
QUICKSTART.md
$ ls scripts/validate-pack.py                # NOT at pack root → bare ref relies on convention
scripts/validate-pack.py
```

### §5.9 Pre-edit context confirmation
```bash
$ git show ee9b385^:pack-ops/MERGE-STRATEGY.md | sed -n '468,474p'
- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough        # ← the edit target
- `QUICKSTART.md` — where to start
- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

All 9 verification commands reproduce expected results. Commit is correctly executed per PLAN §2.9b.

---

## §6 Out-of-scope observations (not actionable for Commit 9b, logged for traceability)

### §6.1 The IMPL-REPORT §6.3 prevention-mechanism candidate is strong

The coder proposed (IMPL-REPORT §6.3) a `validate-pack.py` check that scans pack docs (MERGE-STRATEGY.md and similar) for cross-reference list items where the entry is a bare filename and the named file does NOT exist at the same directory as the doc. This is a high-value catch-all for the exact contamination class that surfaced as L471/L473/L474 in this commit's inspection. Recommend Pack Chat surface to user as either:
- (a) **In-scope addition to Commit 12** (Architect C M5a/M5b/M5c new-checks scope), justifying as a co-arising prevention-mechanism candidate.
- (b) **New BD inserted immediately after this batch** per the pack-memory "Deferral IS scope creep" rule — large-but-unblocked work should not be parked.

Either disposition needs the user's explicit OQ-1 sign-off per EXECUTION-PLAN §B per pack-memory "feedback_deferral_is_scope_creep". Surface as a triage question to the user when presenting Commit 9b for commit-approval (already landed in this case; defer to next anchor).

### §6.2 The architect-doc OQ-4 acknowledgement is the architect's blanket cover for not designing the sibling-ref edits

ARCHITECTURE §10.1 OQ-4 (line 707) explicitly acknowledges F-4 QUICKSTART audience-split was not designed: "QUICKSTART.md does not surface in the §C / §D contamination findings — it is a structural anti-pattern flagged in §F but not yielding per-finding decisions for Architect A". This is the architect cover for L473's non-edit. There is no parallel OQ for L471 (`MIGRATION-v10-to-v11.md`) or L474 (`validate-pack.py`), but the §C/§D framework's targeted-hit scoping implicitly excludes them too. The non-edit is architecturally defensible; the commit-message rationale framing is the only mismatch.

### §6.3 RC9 manifest behavior verified consistent with prior Commit-9a

This commit, like Commit 9a, edits `pack-ops/MERGE-STRATEGY.md` which is NOT v11-surface per current strict RC9 base case. Manifest is correctly not regenerated. PLAN §4.2 row 9b explicitly confirms this in the v11-surface column ("N (pack-ops/)"). No defect; logged for completeness.

### §6.4 PREFLIGHT line per pack-memory

IMPL-REPORT §7 quotes the PREFLIGHT line emitted by the coder: `PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 4e240eca46e33940e52e3ab5953b406f72e4e832; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-9B.md`. The format matches pack-memory `feedback_pack_coder_preflight_pattern` exactly. PREFLIGHT discipline is correct.

### §6.5 No prior-PACK-REVIEW reads (pack-memory compliance)

Per pack-memory `feedback_no_prior_reviews_to_reviewer`, no prior `PACK-REVIEW-*.md` files were read. Architect (`ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`) and Plan (`PLAN-BD-175-PHASE-5.md`) consulted only. IMPL-REPORT consulted only AFTER independent assessment (§3 above).

---

End of PACK-REVIEW-BD-175-COMMIT-9B.
