# PACK-REVIEW — BD-197 FIX-SHOULDS (S3-2, S3-1 + harmonization)

**Reviewer:** pack-reviewer (fresh, focused) · **Date:** 2026-06-13 · **Branch:** v11-dev
**HEAD:** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`)
**Scope reviewed:** EXACTLY the two doc-text corrections + the plan-wide harmonization. No whole-plan/whole-design re-review (already covered by three prior adversarial passes).

---

## VERDICT: APPROVE

Both fixes are correct, complete, internally consistent, and introduced no collateral change. S3-2 (155→186) is exact and grep-clean. S3-1 (22→23 + all-three-reviews KEEP + measure-at-commit framing + narrow self-exception) is correct and the §1/§J/§K harmonization is complete (zero stale "22"-as-current, zero "BOTH/two reviews"). The one nuance — the live matcher now returns **24**, one ahead of the plan's documented **23** — is NOT a defect: the plan exhaustively frames the count as illustrative-as-of-now and mandates the C5 coder re-measure live at commit-time; the 24th file is the coder's own IMPL-REPORT (the documented "carrier set grows every pass" behavior). Surfaced below as informational only.

---

## Re-measurement results (independent)

| Check | Command | Result | Plan/doc says | Verdict |
|---|---|---|---|---|
| S3-2 stale `155` | `grep -c '155' …RECONCILED.md` | `0` | — | CLEAN |
| S3-2 `186` present | `grep -nE '186 validate-pack' …RECONCILED.md` | `867:the 186 validate-pack invocations in the battery.` | 186 | MATCH |
| S3-2 battery count | `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'` | `186` | 186 | MATCH |
| S3-1 matcher count | `rg -l --hidden --no-ignore 'no worktree isolation\|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures' \| wc -l` | `24` | 23 (measured-at-commit) | COVERED-BY-FRAMING (see N-1) |
| S3-1 ADVERSARIAL.md | `rg -c …` | `8` | 8 | MATCH |
| S3-1 ADVERSARIAL-2.md | `rg -c …` | `3` | 3 | MATCH |
| S3-1 ADVERSARIAL-3.md | `rg -c …` | `3` | 3 (new KEEP) | MATCH |
| stale "22"-as-current | `grep -nE 'returns \*\*22\*\*\|…\|22 files' plan` | `(none)` | — | CLEAN |
| stale "BOTH/two reviews" | `grep -niE 'BOTH PLAN-adversarial\|both plan reviews\|two PLAN-adversarial\|the 1st AND the 2nd/re-review' plan` | `(none)` | — | CLEAN |
| collateral | `git status --short` | only design doc (`M`, pre-existing) + plan + IMPL-REPORT (`??`) carry these fixes | — | CLEAN |

All measurements at HEAD `ae3d932`, 2026-06-13.

---

## Findings

### S3-2 — design doc `~155` → `186` — CORRECT
- `grep -c '155'` on `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` = `0`; zero stale battery-count occurrences remain.
- §17.7 line 867: `the 186 validate-pack invocations in the battery.` — exactly as specified.
- Independent measure of the battery confirms `186` (`grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk …` = `186`), matching the plan's EE-1.
- Diff isolation: `git diff …RECONCILED.md | grep -E '^[+-].*(155|186 validate-pack)'` returns exactly ONE line — `+the 186 validate-pack invocations in the battery.` No `-…155…` removal line, because `~155` lived inside the new (not-yet-committed) §17 block; it was corrected to `186` in place within that block. No other number touched.

### S3-1 — plan matcher count 22→23, all-three-reviews KEEP, framing — CORRECT
- §E Guard-A step 1 (line 226): "returns 23 files" + explicit MEASURED-AT-C5-COMMIT-TIME / "Do NOT anchor on this static number" language. Correct.
- §E Guard-A step 2(iii) (line 227, rendered within step 2): names "all three `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL{,-2,-3}.md` reviews" + the NARROW-exception restatement ("validator self-skip + ONLY the single check-53 test file + the measured doc carriers — do NOT widen to the whole `scripts/tests/` dir"). Correct.
- §E Guard-A step 5 PREFLIGHT (line 230): "RE-MEASURES the matcher LIVE at commit-time (do NOT trust this plan's as-of-now 23-file count)". Correct.
- §F EE-2 (lines 266/268/269): output 23 files, per-file counts pinned (ADVERSARIAL=8, -2=3, -3=3), breakdown "23 = 9 archive + 4 STRIP + 10 active-KEEP", KEEP names all three reviews, conclusion "SUPPORTED (corrected to 23)" with illustrative-not-static + narrow-exception restatement. Correct and self-consistent with §E.
- Independent re-measure confirms the three review docs match at 8/3/3 exactly as documented.

### Harmonization (§1/§J/§K) — COMPLETE
- Stale-"22"-as-current grep over the plan: CLEAN.
- Stale-"BOTH/two PLAN-adversarial reviews" grep over the plan: CLEAN.
- All remaining "22" mentions are HISTORY-only ("21, then 22 with the 2nd review" / "+1 over the prior 22") at lines 10, 255, 268, 403, 434 — correct and must stay (the 21→22→23 progression). Line 82's "line 22" is an unrelated SKILL.md line-number ref, correctly untouched.
- "23"-as-current present across §1 (10), §E (226, 230), §F (255, 266, 268, 269), §J (403, 411, 434), §K (445, 449, 464) — harmonized end-to-end.
- §1 line 7 + line 10, §J 411 + 434, §K 445 + 464 all now read "all THREE PLAN-adversarial reviews" with the `-ADVERSARIAL{,-2,-3}.md` enumeration. Complete.

### NARROW exception — INTACT
- §E 227, §F 268/269, §J 403 each state the exception as: validator self-skip (`entry.name == "validate-pack.py"`) + ONLY the single `scripts/tests/test-validate-pack-check-53.sh` + the measured doc carriers, explicitly "NOT the whole `scripts/tests/` dir." No widening introduced.

### No collateral — CONFIRMED
- `git status --short`: tracked `M` = only `ARCHITECTURE-…RECONCILED.md` (+ `backlog/BD-197.md`, `backlog/_toc.md`, both pre-existing prior-session work, NOT touched by these fixes); untracked `??` = the plan, the IMPL-REPORT, and the three review docs (prior-session artifacts). No change to `scripts/validate-pack.py`, the check-53 test, the 12-commit sequence, the keywords, §E/§F's pre-correction content, or the design's §17 carve-out spec (frozenset of one path `test-fixtures/manifest.txt`, §17.4 line 739–740, verified present and unchanged). The BD entries' diffs (`BD-197.md` +1, `_toc.md` +1) are inherited prior-session edits, not these fixes.

---

## Informational (NIT — no fix required pre-commit)

**N-1 — live matcher = 24, plan documents 23 (one behind reality).**
My independent re-measure returns **24** files, not 23. The delta vs the IMPL-REPORT's measured 23 is exactly +1 = `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-FIX-SHOULDS.md` (2 matches — it quotes the regex strings in its FIX-2 measurement-evidence block). This file did not exist as a matcher hit at the instant the coder ran its measurement (the coder measured BEFORE writing its own report). This is precisely the "BD-197-process/review-doc carrier set grows with every pass" phenomenon the plan documents at lines 226, 230, 268, 269, 403, 411, 434, and the plan repeatedly directs the C5 coder to "RE-MEASURE live at commit-time" and "never trust this plan's static enumerations." The number 23 is therefore framed as illustrative-as-of-now, not a load-bearing anchor — so this is NOT a correctness defect. Recommendation: leave as-is (chasing the number is the very anchoring the plan warns against; the C5 coder will measure the then-current set, which will include this IMPL-REPORT and this very review doc once written). If Pack Chat prefers a belt-and-suspenders touch, a one-token "(24 with the IMPL-REPORT; 25+ once this review lands — re-measure at C5)" parenthetical could be added at §F line 266, but it is optional and arguably noise given the framing already nails the principle.

**N-2 — §F per-file-count drift surfaced by the coder did not materialize.**
The harmonization IMPL-REPORT flagged that the plan's own self-count (EE-2 line 266: `PLAN-BD-197-WORKTREE-ISOLATION.md`=4) might shift after the harmonization edits. Independent re-measure confirms the plan still matches at exactly **4** — the substituted prose neither added nor removed regex-quoting occurrences. No fix needed; the surfaced concern was correctly conservative and is now resolved by measurement.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [reviewer] | Every claim backed by command + verbatim output + HEAD `ae3d9325889c41f7cba7a4289437cf7a87d04292` + date 2026-06-13. S3-2: `grep -c '155' …RECONCILED.md`→`0`; `grep -nE '186 validate-pack'`→`867:the 186 validate-pack invocations in the battery.`; `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'`→`186`. S3-1: `rg -l … \| wc -l`→`24`; per-file `rg -c` ADVERSARIAL/-2/-3 = `8`/`3`/`3`; stale-22 grep→`(none)`; stale-BOTH/two grep→`(none)`; `git status --short` quoted. IMPL-REPORT match count→`2`; PLAN self-count→`4`. | COMPLIANT |
| 2 | scope-deliverables-to-the-ask [universal] | Verified ONLY the two fixes + harmonization + collateral-absence + narrow-exception intactness; did NOT re-review the carve-out logic, 12-commit sequence, keywords, design §17 internals, or BD substance (deferred to the three prior adversarial passes). The single genuine nuance (live 24 vs documented 23) surfaced as informational, not inflated to a blocker. No coverage/edge-case sprawl. | COMPLIANT |
| 3 | agents-never-commit [universal] | Ran only read-only git verbs (`git rev-parse HEAD`, `git status`, `git status --short`, `git diff`, `git diff --stat`) + Read/Bash-grep/rg. Wrote exactly ONE file — this review doc at the prompted path `maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-FIX-SHOULDS.md`. No `git add`/`commit`/`push`/`tag`; HEAD unchanged `ae3d932` start→end. No sub-agents spawned. | COMPLIANT |
| 4 | rules-applied-verification-block [universal] | This block. Every rule from the prompt's RULES IN FORCE addressed with quoted evidence + terminal conclusion; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

*End of review — VERDICT APPROVE; HEAD `ae3d932` unchanged; one informational NIT (N-1: live 24 vs documented 23, fully covered by the plan's measure-at-commit framing — no pre-commit fix required).*
