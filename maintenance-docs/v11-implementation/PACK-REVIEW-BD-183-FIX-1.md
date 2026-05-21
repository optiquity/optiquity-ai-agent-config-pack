# PACK-REVIEW-BD-183-FIX-1 — Per-commit review (`5f8f683`)

**Reviewer:** pack-reviewer (BD-175 elevated-care, 10th reviewer in carry-forward chain)
**Date:** 2026-05-21
**HEAD reviewed:** `5f8f68381b2f951fd571f414976021e97f22b659` (BD-183 FIX-1: SHOULD-1 + NIT-2 + NIT-3 bundled)
**Predecessor:** `aeacbdc09dcf22f360efbd6c76668859c56b772c` (BD-183 main commit, APPROVE-WITH-FIXES per PACK-REVIEW-BD-183 §4)
**Branch:** `v11-dev`
**Scope reviewed:** Wire `scripts/tests/test-validate-pack-check-18.sh` (BD-181) into `.github/workflows/validate-pack.yml` as new sister-step (SHOULD-1); tighten `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md` §10 Observation 4 wording around file-move vs doc-restructure distinction (NIT-2); add label-presence-in-both-directions assertions to `scripts/tests/test-validate-pack-check-16.sh` Group 3 for parity with `-19.sh` Group 3 (NIT-3). NIT-1 explicitly SKIPPED per Pack Chat triage (commit subject on `aeacbdc` immutable).

---

## §1 Verdict

**APPROVE-WITH-FIXES.**

The three fixes are mechanically correct, file-disjoint, and verified end-to-end. The SHOULD-1 sister-step is positioned correctly per the BD-creation-order cluster convention (40 → 18 → 16 → 19 reflects BD-179 → BD-181 → BD-183 → BD-183). The NIT-2 wording faithfully replaces the "would become stale" framing with an explicit move-vs-restructure distinction and preserves the original observation's structural intent. The NIT-3 parity addition mirrors `-19.sh` Group 3's label-presence assertions correctly (the bracket form for PASS output, the path-prefix form for FAIL output) with an inline comment block documenting the form-choice rationale.

One SHOULD-tier finding surfaced: the prevention scanner the PACK-REVIEW-BD-183 §4 SHOULD-1 "Note" recommended (compare `scripts/tests/test-validate-pack-check-*.sh` against `.github/workflows/validate-pack.yml`) reveals that `test-validate-pack-check-41.sh` (BD-180, present since commit `78a4415`) is ALSO unwired in CI. Same gap class, same fix shape — surfacing as SHOULD-A per the same carry-forward-discipline reasoning that produced SHOULD-1 in the prior review.

Zero BLOCKER, zero MUST findings. The fix-coder addressed every triaged item correctly.

---

## §2 Severity breakdown

| Severity | Count |
|---|---|
| BLOCKER | 0 |
| MUST | 0 |
| SHOULD | 1 (gap-class twin of SHOULD-1: third unwired test surfaced by the scanner SHOULD-1 §4 Note recommended) |
| NIT | 1 (commit subject is 72 chars vs 70-char guideline; 2 chars over) |

---

## §3 Per-finding closure (from PACK-REVIEW-BD-183 §4)

| Prior finding | Closure status | Evidence |
|---|---|---|
| **SHOULD-1** — `test-validate-pack-check-18.sh` not wired to CI | **CLOSED** | `.github/workflows/validate-pack.yml:169-171` — new sister-step added: `name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)`, `if: always()`, `run: bash scripts/tests/test-validate-pack-check-18.sh`. Shape matches the surrounding sister-step cluster (Check 40 at `:166-168`; Check 16 at `:172-174`; Check 19 at `:175-177`). Position correct: between Check 40 and Check 16 per BD-creation-order convention (BD-179 → BD-181 → BD-183). YAML syntax PASS. The test itself PASSES (`bash scripts/tests/test-validate-pack-check-18.sh` → `PASS: 7, FAIL: 0`). |
| **NIT-1** — Commit subject exceeds prior-batch length envelope (88 chars on `aeacbdc`) | **SKIP HONORED** | Per Pack Chat triage explicitly cited in IMPL-REPORT-FIX-1 frontmatter and commit body: "NIT-1 SKIPPED per triage (commit subject on aeacbdc immutable; advisory only per pack-repo convention)." The `aeacbdc` subject is immutable on already-landed history; amend forbidden by pack memory § Workflow ("Always create NEW commits rather than amending"); net cost of fix > benefit. Skip-with-rationale is the correct disposition. |
| **NIT-2** — IMPL-REPORT §10 Observation 4 framing | **CLOSED** | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md:611, 613` — second bullet rewritten ("Robustness profile: section-number citations of the form 'per BD-183 §2.4' remain VALID as long as the referenced report preserves its §X.Y addressability … File MOVES … do NOT invalidate these citations … Only a doc-RESTRUCTURE that renumbers or removes §2.4 would invalidate them"); fourth bullet (carry-forward outcome) tightened with the closing clause "section-number citations are robust to file moves under the standard `maintenance-docs/` archive convention." First bullet (citations enumerated) and third bullet (user-visible CI output detail) preserved unchanged — the framing tightening did NOT add scope. |
| **NIT-3** — `-16.sh` Group 3 vs `-19.sh` Group 3 parity (label-presence assertions) | **CLOSED** | `scripts/tests/test-validate-pack-check-16.sh:317-330` — Group 3 now carries (a) leak-prevention in both directions (lines 318-321, preserved from pre-fix; new inline comment at `:317` labels them), AND (b) label-presence in both directions (lines 327-330, new). Inline comment block at `:322-326` documents the form choice rationale (PASS-path uses `[label]` bracket form per OK message; FAIL-path uses `label/name` path-prefix form per `check_trinity_addenda_h2`'s `fail(f"{label}/{name} — …")` shape). Parity verified by cross-grep: both `-16.sh:328` and `-19.sh:337` assert "location A label missing"; both `-16.sh:330` and `-19.sh:339` assert "location B label-prefix missing from FAIL output." Both test suites still PASS (`-16.sh`: 10/10; `-19.sh`: 9/9; the `-16.sh` count stays at 10 because the new assertions live inside the same outer Group 3 accumulator — matches IMPL-REPORT-FIX-1 §2.3 "Test-count behavior" explanation). |

All 3 FIXed findings closed cleanly; 1 SKIPped finding honored with documented rationale.

---

## §4 Findings

### SHOULD-A — `test-validate-pack-check-41.sh` ALSO not wired to CI (third gap-class instance; surfaced by the scanner that PACK-REVIEW-BD-183 §4 SHOULD-1 "Note" recommended)

**Severity:** SHOULD (advisory; not blocking the FIX-1 commit; same gap-class as SHOULD-1)
**File/symbol:** `.github/workflows/validate-pack.yml:166-177` — sister-step cluster (now Check 40 → Check 18 → Check 16 → Check 19, missing Check 41); `scripts/tests/test-validate-pack-check-41.sh` (existing, unwired since BD-180).

**Problem.** Running the unwired-test-detection scanner from PACK-REVIEW-BD-183 §4 SHOULD-1 "Note":

```
comm -23 <(ls scripts/tests/test-validate-pack-check-*.sh | xargs -n1 basename | sort) \
         <(grep -oE 'test-validate-pack-check-[0-9-]+\.sh' .github/workflows/validate-pack.yml | sort -u)
```

…against post-FIX-1 HEAD returns one line:

```
test-validate-pack-check-41.sh
```

This is the same gap class as BD-179 SHOULD-1 (`1e644d1`) and BD-183 SHOULD-1 (just-closed in this commit): a test file exists in `scripts/tests/` but is not invoked in `.github/workflows/validate-pack.yml`, so the test is "silently dead in CI." `test-validate-pack-check-41.sh` was added in commit `78a4415` (BD-180, "cmd_update mapping symmetry across remaining surfaces") and has never been wired into CI. It tests Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity, BD-180 observation G) and currently PASSes locally (4/4) but provides zero CI coverage.

This is the same fix shape as SHOULD-1: a single 3-line sister-step block in the same yml file. Per the carry-forward-discipline tests:

- **SIZE:** No. Single-line-per-step yml addition; not architect-pass material.
- **BLOCKED:** No. No dependency on unlanded work; the test file exists and passes today.
- **LOGICAL FIT:** Yes — fits the same yml file, same sister-step cluster, same fix shape as SHOULD-1. However, fitting an adjacent commit doesn't qualify for deferral because the gap-class precedent (BD-179 SHOULD-1) explicitly establishes fix-now for the identical failure mode. Per `.claude/skills/review/SKILL.md` § "Forbidden carry-forward shapes": "Pack memory rule X recommends fix-now stated as the rationale but presented as carry-forward" is forbidden.

Surfacing as in-scope SHOULD finding per default-FIX-all triage.

**Fix.** Add a fifth sister-step in the BD-creation-order cluster. BD-180 falls between BD-179 and BD-181, so the position is between Check 40 (BD-179) and Check 18 (BD-181). Insert at `.github/workflows/validate-pack.yml:169` (immediately after the existing Check 40 step):

```yaml
      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-40.sh
      - name: validate-pack Check 41 tests (BD-180, _CLIENT_INSTALLED_FILES self-doc list integrity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-41.sh
      - name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)
        if: always()
        run: bash scripts/tests/test-validate-pack-check-18.sh
```

Resulting cluster: Check 40 (BD-179) → Check 41 (BD-180) → Check 18 (BD-181) → Check 16 (BD-183) → Check 19 (BD-183). BD-creation order preserved.

**Rationale.** Per pack memory `feedback-deferral-is-scope-creep` and the BD-179 SHOULD-1 + BD-183 SHOULD-1 precedents: same gap class + same yml file + same single-line-per-step fix shape ⇒ fix-now, do not defer. The scanner FIX-1 SHOULD-1 §4 "Note" recommended as a coder pre-commit checklist addition is exactly what surfaced this finding; that the same scanner could have been run during FIX-1 implementation but wasn't is itself a small workflow gap (covered by Pack Chat carry-forward Observation A below — not a defect in this commit, but a candidate for the coder pre-commit checklist that the "Note" recommended).

**Note on prevention scope.** The proper anchor for "scanner that detects unwired test files" is either (a) a new validate-pack.py check (Check 42, anchored to the pattern), or (b) a coder pre-commit checklist line in `pack-ops/PACK-CHAT.md` or the relevant pack-coder agent definition. Per pack memory `feedback-deferred-work-tracking`: if the user defers SHOULD-A's prevention scaffolding to a future BD, the deferral MUST anchor to a live BD entry (not just sit in this report). Recommending FIX-now on this finding to close the immediate symptom; recommending Pack Chat triage on whether to open a new BD for the prevention-scaffolding itself.

---

### NIT-A — Commit subject exceeds 70-char guideline by 2 chars (72 chars)

**Severity:** NIT (advisory; not blocking; the prompt explicitly notes "this fix should respect the guideline")
**File/symbol:** Commit `5f8f683` subject: `fix: v11 — BD-183 SHOULD-1 wire BD-181 test + NIT-2/3 wording + parity` (72 chars).

**Problem.** The prompt § "Commit hygiene" states: "Subject ≤70 chars (the BD-183 main commit's 88-char subject was NIT-1 advisory; this fix should respect the guideline)." Measured length: 72 chars (`awk '{print length}'`). The subject exceeds the guideline by 2 chars. Per pack-repo precedent the overage is small enough to be cosmetic, and per pack memory § Workflow amend is forbidden, so the practical disposition is SKIP-with-rationale (the previous BD-183 NIT-1 had the same character class).

**Fix (advisory).** Either accept as-is (precedent for slight overage exists; the 72-char form preserves all essential scope tags) OR shorten by trimming "wording":

```
fix: v11 — BD-183 SHOULD-1 wire BD-181 test + NIT-2/3 + parity
```

(62 chars; drops "wording" since "+ parity" implies test-completeness which is what NIT-3 polishes; the body of the commit has the full detail anyway). Either disposition is defensible.

**Rationale.** Advisory polish only; same character class as the prior commit's NIT-1. Amend forbidden per pack memory. Net cost of fix (new commit replacing this one + lost git-history continuity) likely > benefit (2-char overage).

---

## §5 Verification results

### §5.1 `python3 scripts/validate-pack.py`

**Exit code: 0.** `PASSED — all checks clean`. All 41 checks green. Trinity-related output (verbatim from HEAD):

```
── Check 16 [project-template]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
  OK: [project-template] CLAUDE.md — '## Project addenda' H2 with placeholder
  OK: [project-template] AGENTS.md — '## Project addenda' H2 with placeholder
  OK: [project-template] GEMINI.md — '## Project addenda' H2 with placeholder

── Check 16 [pack-root]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
  OK: [pack-root] surface exempt — Check 16 is template-only (`## Project addenda` mechanism has no purpose at non-reconciled surface per BD-183 §2.4)

── Check 18 [project-template]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [project-template] CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: [project-template] GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)

── Check 18 [pack-root]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [pack-root] CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)
  OK: [pack-root] GEMINI.md adds 1 intrinsic H2(s); otherwise matches (5 sections)

── Check 19 [project-template]: Trinity templates free of body scaffolding (BD-059, BD-183) ──
  OK: [project-template] All three trinity templates free of body-section scaffolding comments

── Check 19 [pack-root]: Trinity templates free of body scaffolding (BD-059, BD-183) ──
  OK: [pack-root] All three trinity templates free of body-section scaffolding comments
```

### §5.2 Per-check test suites

| Suite | Result |
|---|---|
| `bash scripts/tests/test-validate-pack-check-16.sh` | exit 0; `PASS: 10, FAIL: 0` (NIT-3 additions verified passing) |
| `bash scripts/tests/test-validate-pack-check-18.sh` | exit 0; `PASS: 7, FAIL: 0` (now wired in CI per SHOULD-1) |
| `bash scripts/tests/test-validate-pack-check-19.sh` | exit 0; `PASS: 9, FAIL: 0` (unchanged in this commit; parity reference) |
| `bash scripts/tests/test-validate-pack-check-39.sh` | exit 0; `PASS: 6, FAIL: 0` (adjacent regression check) |
| `bash scripts/tests/test-validate-pack-check-40.sh` | exit 0; `PASS: 8, FAIL: 0` (adjacent regression check) |
| `bash scripts/tests/test-validate-pack-check-41.sh` | exit 0; `PASS: 4, FAIL: 0` (passes locally; SEE SHOULD-A — not wired in CI) |

**Grand total: 44 PASS / 0 FAIL across all 6 per-check validate-pack test suites. Zero regressions.**

### §5.3 YAML syntax

`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"` → exit 0. YAML valid.

### §5.4 Cluster ordering verification

`.github/workflows/validate-pack.yml:166-177` reads (post-FIX-1):

```
166:      - name: validate-pack Check 40 tests (BD-179, pack-ops/ bare-cross-reference scanner)
169:      - name: validate-pack Check 18 tests (BD-181, trinity H2 structure parity)
172:      - name: validate-pack Check 16 tests (BD-183, trinity ## Project addenda H2 + Option (b) exemption)
175:      - name: validate-pack Check 19 tests (BD-183, trinity templates free of body scaffolding)
```

BD-creation-order convention preserved: BD-179 → BD-181 → BD-183 → BD-183. Check 18 correctly positioned between Check 40 (BD-179) and Check 16 (BD-183). The IMPL-REPORT-FIX-1 §2.1 position-choice rationale is sound and matches what was committed.

### §5.5 Manifest

`git diff HEAD -- test-fixtures/manifest.txt` → empty. RC9 outcome confirmed: `.github/workflows/`, `maintenance-docs/`, and `scripts/tests/` edits are not in the v11-surface fixture-affecting copy paths. IMPL-REPORT-FIX-1 §5 documents the rebuild was run with empty diff.

### §5.6 Boundary discipline

`git diff --name-only aeacbdc..5f8f683` lists:

```
.github/workflows/validate-pack.yml
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183-FIX-1.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md
scripts/tests/test-validate-pack-check-16.sh
```

Zero `project-template/` edits. Zero `supporting-docs/` edits. Pack-internal scope only. P-missed-7 boundary discipline N/A (no client-shipped surface touched).

### §5.7 Trinity rule

N/A. No trinity content edited. The IMPL-REPORT modifications are pack-internal design records, and the workflow + test-script edits are pack-internal CI scaffolding. No CLAUDE.md / AGENTS.md / GEMINI.md (at pack-root OR project-template) modified.

### §5.8 NIT-3 parity cross-grep

```
scripts/tests/test-validate-pack-check-19.sh:337: failures.append(f"Override 9 — location A label missing: {out_a}")
scripts/tests/test-validate-pack-check-19.sh:339: failures.append(f"Override 9 — location B label-prefix missing from FAIL output: {out_b}")
scripts/tests/test-validate-pack-check-16.sh:328: failures.append(f"Override 9 (Check 16) — location A label missing from PASS output: {out_a}")
scripts/tests/test-validate-pack-check-16.sh:330: failures.append(f"Override 9 (Check 16) — location B label-prefix missing from FAIL output: {out_b}")
```

Both files now assert (a) leak-prevention in both directions and (b) label-presence in both directions within their respective Group 3 (Override 9). NIT-3 parity goal achieved.

### §5.9 NIT-2 substance-preservation cross-check

Reading `IMPLEMENTATION-REPORT-BD-183.md:609-613` in current HEAD, the four-bullet block is preserved with the changes scoped to bullets 2 + 4:

- Bullet 1 (citations enumerated): UNCHANGED. The four citation sites (constant comment block; exempt-OK message text; docstring; main() inline comment) are still listed.
- Bullet 2 (robustness): REWRITTEN. The new "Robustness profile" framing replaces "Future maintenance risk" with an explicit move-vs-restructure distinction. Adds the per-rule statement ("line numbers drift on any edit; named-section citations only drift on intentional restructure") explaining WHY named-section citations are robust. Preserves the cross-reference to `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` § Pattern B.
- Bullet 3 (user-visible CI output detail): UNCHANGED. The doubly-useful framing of the exempt-OK message is preserved verbatim.
- Bullet 4 (carry-forward outcome): TIGHTENED. The new clause "section-number citations are robust to file moves under the standard `maintenance-docs/` archive convention" reinforces the conclusion from bullet 2.

NIT-2 wording-tightening goal achieved without scope creep.

---

## §6 Carry-forward observations

Per `.claude/skills/review/SKILL.md` § "Carry-forward discipline" (SIZE / BLOCKED / LOGICAL-FIT high-bar), I evaluated scope-adjacent observations encountered during review. The discipline operationalizes pack memory "Deferral IS scope creep" — every finding that does not meet ALL THREE tests must be surfaced as an in-scope finding for fix-now triage, not deferred. This is the 10th review in the BD-175 elevated-care chain; the discipline applies to MY OWN output as rigorously as to anyone else's.

### Observation A — Pre-commit unwired-test scanner not yet adopted as workflow gate

The PACK-REVIEW-BD-183 §4 SHOULD-1 "Note" recommended adding the unwired-test scanner to "the coder's pre-commit checklist." If that scanner had run in FIX-1's coder preflight, it would have surfaced the Check 41 gap as a co-fix opportunity (one additional 3-line yml block in the same commit). It did not run in FIX-1's preflight, and SHOULD-A is the consequence. This observation is NOT a defect in the FIX-1 commit (the prompt did not require the scanner; the scanner's note is informal guidance for future workflow); it is a workflow-improvement candidate.

**Classification.** Not a finding on this commit. Pack Chat may wish to consider whether to (a) open a new BD anchoring the scanner-prevention work (validate-pack.py Check 42 candidate, or a coder pre-commit checklist update), or (b) treat the SHOULD-A surfacing here as sufficient closure. Per pack memory `feedback-deferred-work-tracking`, if deferred, it MUST anchor to a live BD — not "noted in this report and dropped." Recommending Pack Chat surface this to the user at triage.

### Observation B — IMPL-REPORT-FIX-1 §6 self-reports "carry-forward count: 0"

I verified this claim by reading the scope-adjacent observations the coder encountered. The 3 fixes ARE bounded by the prompt's PACK-REVIEW-BD-183 §4 triage decisions. The coder's preflight did not run the unwired-test scanner (which would have surfaced SHOULD-A) — that is a workflow-improvement gap, not a fix-coder defect. The coder's carry-forward discipline self-application is correct WITHIN the scope of the prompt given.

**Classification.** Not a finding. The fix-coder operated within the prompt's stated scope correctly.

### Observation C — NIT-A subject length

Surfaced as NIT-A in §4. Pack-repo convention permits slight overages; amend forbidden; net cost > benefit. SKIP-with-rationale recommended.

### Carry-forward count: **0.**

All observations are either surfaced as in-scope §4 findings (SHOULD-A, NIT-A) or classified as non-findings with rationale (Observation A as workflow-improvement candidate; Observation B as scope-correct fix-coder behavior). No deferrals. Pack memory `feedback-deferral-is-scope-creep` honored.

---

## §7 What the implementation got right

Acknowledging the strengths of this work, per `.claude/skills/review/SKILL.md` step 14 ("A review that only lists problems is incomplete"):

1. **SHOULD-1 position chosen with explicit BD-order rationale.** IMPL-REPORT-FIX-1 §2.1 documents the chosen position via empirical observation of the existing cluster's BD-creation-order convention (36/37/38 → 39 → 40 → 16/19), then derives Check 18's correct position (between Check 40 and Check 16). This is the right level of rigor for a workflow-file insertion: not "any reasonable spot" but "the spot that preserves the existing convention." Reviewable in isolation; correctly justified.

2. **NIT-2 wording rewrites the imprecise framing without scope creep.** The new "Robustness profile" bullet explicitly distinguishes file MOVES (which preserve §X.Y addressability) from doc RESTRUCTURE (which invalidates them). It adds the per-rule statement explaining WHY named-section citations are more robust than line numbers ("line numbers drift on any edit; named-section citations only drift on intentional restructure"). The fourth bullet's tightening reinforces this conclusion. Bullets 1 + 3 untouched — no scope creep, exactly the surgical fix the NIT requested.

3. **NIT-3 parity addition includes form-choice documentation.** The new label-presence assertions in `-16.sh` Group 3 use `[c16-loc-a]` for PASS and `c16-loc-b/` for FAIL, mirroring `-19.sh`'s same intentional asymmetry (PASS form is `[label]` from the OK message; FAIL form is `label/name` from the FAIL message). The new inline comment block at `:322-326` explains the form choice to future maintainers, including the citation to the underlying `fail(f"{label}/{name} — …")` message shape. This is the right level of test-as-documentation rigor.

4. **NIT-1 SKIP with explicit rationale in commit body.** The commit body explicitly documents: "NIT-1 SKIPPED per triage (commit subject on aeacbdc immutable; advisory only per pack-repo convention)." This preserves the audit trail for future readers — the skip is not silent.

5. **RC9 manifest hygiene documented.** IMPL-REPORT-FIX-1 §5 explicitly walks through the RC9 trigger evaluation (scripts/ touched ⇒ trigger fires) and the empty-diff outcome (pack-internal test-runner / CI-config / design-record edits, none in the six fixture-bake-in paths). Rebuild ran; outcome correctly attributed to scope-not-in-copy-path rather than to test-skip. This is the right defense-in-depth pattern for the RC9 rule.

6. **PREFLIGHT line present and accurate.** §7 of IMPL-REPORT-FIX-1 contains the required PREFLIGHT statement with the correct format: edit count, verification status, HEAD SHA, and target IMPL-REPORT path. Trust signal honored.

7. **File-disjoint fix bundling.** The 3 fixes touch 3 disjoint files (yml, IMPL-REPORT, test-16.sh). The disjointness justifies the single-coder approach over parallel coders; the bundling preserves single-commit attribution per `pack memory § Workflow`.

---

## §8 Recommendation to Pack Chat

**APPROVE the commit as-is.**

Triage items:

1. **SHOULD-A (Check 41 CI sister-step wiring).** FIX-NOW recommended per the same gap-class precedent that produced SHOULD-1 (BD-179 SHOULD-1 → BD-183 SHOULD-1). The fix is the same shape: 3 lines in the same yml file, inserted at the BD-order position (between Check 40 and Check 18). Defensible to bundle as `fix: v11 — BD-183 FIX-2 SHOULD-A wire BD-180 test (gap-class triplicate)` or to absorb into the next end-of-batch broad fix. Per pack memory `feedback-deferral-is-scope-creep`, fix-now strongly preferred — deferring would compound the same gap that two prior reviews already established as fix-now.

2. **NIT-A (subject length, 72 chars).** SKIP-with-rationale recommended. 2-char overage is cosmetic; amend forbidden per pack memory; net cost of fix > benefit. Same disposition as the prior BD-183 NIT-1.

3. **Observation A (prevention scanner workflow gap).** Pack Chat triage decision: open a new BD anchoring the prevention work (Check 42 validate-pack.py addition OR coder pre-commit checklist update in `pack-ops/PACK-CHAT.md`), OR treat the SHOULD-A surfacing as sufficient closure for now. If deferred, MUST anchor to a live BD per pack memory `feedback-deferred-work-tracking`.

End-of-batch reviewer pass on the full BD-175 chain should validate the Pack Chat triage decisions for these items.

---

**End of review.**
