# PACK-REVIEW — Batch 19b cleanup commit 19b-5

**Reviewer:** pack-reviewer (19b-5)
**Date:** 2026-05-17
**Branch:** v11-dev
**HEAD SHA:** `4760649b4252e9ff9354dc813dd5cbf6897bac6b`
**Reviewed:** working-tree diff against HEAD `4760649` (coder did not commit)
**Source-of-truth docs read:**
- `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md` §1 row 52 (19b-5 scope)
- `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §B rows V11-12 (line 659), V11-13 (line 678), V11-14 (line 696), V11-15 (line 702)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md`
- `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (full file)

---

## §1 — Summary + verdict

**Verdict: APPROVE.**

The 19b-5 deliverable is a single 2-line addition (1 prose paragraph + 1 blank-line spacer) to `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` at lines 113-114. The inserted text is **verbatim** with V2 §B V11-13 architect-supplied paragraph (whitespace-normalised — V2 spec has hard-wrapped line breaks at ~60 cols, methodology file has flowed prose; the byte content is identical word-for-word). The placement is correct (immediately after the existing line 112 closer of the `## CI-step interrogation heuristic` section). The V11-12 and V11-14 "no edit" verdicts are independently verified as substantively correct. The V11-15 grep verification is correct on classification (all hits are historical or out-of-scope per V2 V11-15 row), with a minor enumeration discrepancy in the coder's report (see §6).

**Aspect verdicts:**

| Aspect | Reviewer verdict |
|---|---|
| V11-13 extension fidelity | PASS — verbatim match against V2 §B V11-13 wording |
| V11-13 placement | PASS — correctly inserted after existing CI-section closer at line 112 |
| V11-12 zero-edit | PASS — existing methodology section substantively covers the rule |
| V11-14 zero-edit | PASS — existing section is concrete (4 enumerated items + empirical basis), not header-only |
| V11-15 grep audit | PASS (with NIT) — all 9 live hits (not 8 as report says) are historical or out-of-scope; classification is correct |
| Out-of-scope check | PASS — only 1 tracked file modified |
| RC9 base case | PASS — no v11-surface globs touched |
| Validator + baseline tests | PASS — independently confirmed |

**Severity tally:** 0 BLOCKER, 0 MUST, 0 SHOULD, 2 NITs.

---

## §2 — Findings table

| Severity | File:line | Finding | Suggested remediation |
|---|---|---|---|
| NIT | `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md:175,178` | Coder's grep-hit-list table cites the `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` hit at **line 245** and the `PACK-REVIEW-BD-117-RETRO.md` hit at **lines 469-472**. Independent grep returns the supporting-docs hit at **line 247** (lines have shifted by +2 due to the coder's own V11-13 insertion before the IMPL-REPORT was written) and the BD-117-RETRO hits at **lines 469, 471, 472**. Classification is identical; only the line numbers in the report's grep table are pre-edit-state. | OPTIONAL — coder may correct line numbers in their IMPL-REPORT to post-edit state for record-keeping. Not load-bearing; the classifications are correct and the line-number drift is mechanical. Pack Chat may accept as-is per the "no fix for cosmetic IMPL-REPORT updates" pattern. |
| NIT | `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md:174-182` | Coder's grep-hit count says "8 hits" (table rows 1-7 inclusive of V1+V2 architect docs + planner doc, summing to 8 file-hits if you count V1 + V2 architect docs each as one row). My independent grep returns **9 file-hits** total (the 9th being the coder's own IMPL-REPORT `IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md`, which contains the verbatim grep verb literals and the per-row classification text). This is structurally a self-reference (the IMPL-REPORT documents its own grep, so its hits are tautologically present in the very report that classifies them). Out-of-scope per "workflow artifact archived in 19b-7" rule; non-load-bearing. | OPTIONAL — coder may note "9th hit is this IMPL-REPORT itself, self-reference" in a §6 footnote, or Pack Chat may accept as-is. The grep-result drift is a natural consequence of running the grep before the IMPL-REPORT is written. |

No MUST / SHOULD findings.

---

## §3 — V11-13 extension fidelity audit

### V2 architect-supplied wording (verbatim from V2 §B V11-13 row, lines 684-692)

```
**Must-include-in-prompt rule.** When the BD touches CI workflows
(`.github/workflows/*.yml` or any other CI configuration), the
agent prompt that generates the implementation OR the review MUST
explicitly require the agent to identify, for every new or modified
CI step, a concrete change that would turn it red AND confirm the
wiring would surface that change. Prompts that omit this requirement
have empirically missed CI gaps (BD-118 retro).
```

### New paragraph in methodology file (verbatim from `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:114`)

```
**Must-include-in-prompt rule.** When the BD touches CI workflows (`.github/workflows/*.yml` or any other CI configuration), the agent prompt that generates the implementation OR the review MUST explicitly require the agent to identify, for every new or modified CI step, a concrete change that would turn it red AND confirm the wiring would surface that change. Prompts that omit this requirement have empirically missed CI gaps (BD-118 retro).
```

### Fidelity verdict: PASS (verbatim match)

**Reasoning:** Word-for-word identical. The only differences are whitespace (V2 spec has hard-wrapped line breaks at ~60 cols for the architect-doc's prose-block formatting; methodology file uses flowed prose with no internal line breaks, which is the methodology file's house style for paragraph-level rules — see existing line 110 empirical-basis paragraph which is similarly flowed). The substantive content (scope expansion from REVIEW-only to "implementation OR review", `.github/workflows/*.yml` carve, "turn it red" requirement, BD-118 retro citation) is byte-identical on a per-word basis.

**Defensibility:** The whitespace adjustment is a defensible prose-flow normalisation matching the surrounding paragraph's style. The methodology file's existing prose paragraphs (lines 110, 125, 241, 247) all use flowed prose without internal line breaks; the new paragraph at line 114 conforms to this house style.

---

## §4 — V11-12 zero-edit verification

### V2 architect-supplied verification trigger (verbatim from V2 §B V11-12 row, lines 663-674)

```
Verification step for pack-coder: Read the existing section, verify
wording covers the retro-specific case (sourcing File/Symbol from
BACKLOG entry + git --stat <sha> rather than prose recall — applies
to retro-review prompts specifically, which run against historical
commits). If the wording is generic-only and doesn't name the retro
case, ADD one paragraph to that section:

[V2 architect-supplied paragraph]

If the existing wording covers this, no edit. Pack-coder reports
which.
```

### Existing methodology section (verbatim from `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:233-247`, the `### File/Symbol scope from authoritative sources, not prose recall` section)

```
### File/Symbol scope from authoritative sources, not prose recall

The reviewer's "BD scope anchor" section MUST source File/Symbol from:
1. The BD's own BACKLOG entry `File/Symbol:` field (authoritative)
2. `git show --stat <commit-sha>` for the BD's original commit (verifiable)

NEVER from the parent chat's prose recollection of what files the BD touched. Recollection drifts and corrupts the reviewer's scope.

**Empirical basis (Batch 21c, 2026-05-15):** the BD-112 retro trial prompt cited `scripts/lib/three-way.sh` as the BD-112 surface; actual surface (per BACKLOG + git --stat) was `scripts/lib/customization-preserve.sh`. Reviewer worked around the error but flagged it as methodology friction; subsequent prompts in the batch sourced from BACKLOG + git --stat correctly.
```

### Verdict: PASS — substantive coverage confirmed, no edit required

**Reasoning:** The existing section establishes the rule as a universal `MUST` ("MUST source File/Symbol from: 1. BACKLOG entry `File/Symbol:` field, 2. `git show --stat <commit-sha>` for the BD's original commit"). The wording explicitly names the two authoritative sources (BACKLOG + `git show --stat <commit-sha>`) and prohibits prose recall with "NEVER from the parent chat's prose recollection."

The V2 architect's proposed extension would name "retro-review prompts" specifically. However, the existing rule is stated as a universal MUST that applies to ALL reviewer prompts (including retro prompts by inclusion), AND the existing empirical-basis paragraph is literally a retro-case (BD-112 retro trial). The V2 row explicitly says "If the existing wording covers this, no edit" — and the coverage is substantive on three independently sufficient grounds:

1. The rule is universally applicable (no exclusion for retro prompts).
2. The empirical basis IS a retro-case (BD-112 retro trial), making the retro-applicability self-evident.
3. The two authoritative source verbs (BACKLOG `File/Symbol:` field + `git show --stat <commit-sha>`) are exactly the same authoritative sources the V2 extension would have named.

**Minor verb-choice variation:** existing uses `git show --stat <commit-sha>`; V2 proposed `git diff --stat <SHA>`. Both produce the file-changes-by-commit output needed; the existing verb (`git show --stat`) is arguably the more direct single-commit query. This is a lexical, not substantive, difference. No fix required; the coder's flag-2 disposition (no normalising edit) is correct.

---

## §5 — V11-14 zero-edit verification

### V2 architect-supplied verification trigger (verbatim from V2 §B V11-14 row, lines 698-700)

```
Verification step for pack-coder: Read the existing section, verify
wording is concrete (names the checklist items) and not just a
section header. If it is only a header / placeholder, file as
STRENGTHEN — but in this batch's scope, only flag for the user; do
NOT extend it without an architect pass per L4. The verification
check is read-and-report only.
```

### Existing methodology section (verbatim from `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:116-125`)

```
## Convention/naming docs review checklist

When reviewing convention documents (naming conventions, fixture conventions, file-class conventions, etc.), the standard six dimensions are insufficient. Add these convention-specific checks:

1. **Procedure ↔ rule consistency.** Does the "how to add a new <thing>" procedure cite the convention rules at the moment a contributor would need them?
2. **Column ↔ text consistency.** If the convention document includes a table column (e.g., "Versioning: v10-pinned / v11-pinned / version-agnostic"), does the prose convention text enumerate the same value space, or does it leave the column-value pattern unstated?
3. **Forward-compatibility for vN+1.** Does the convention scale to the next major version's surfaces without amendment? (Convention text codified in BD-N+0 must admit new classes introduced in BD-N+1 — see Batch 21c BD-122 ↔ BD-136 M-8 carry-forward in BD-136 File/Symbol.)
4. **Examples ↔ rule alignment.** Do the worked examples instantiate the rule, or contradict it via edge-case inclusion?

**Empirical basis (Batch 21c, 2026-05-15):** BD-122 retro reviewer flagged 3 findings (1 SHOULD + 2 NITs) all in the convention document's procedure-rule-column triplet that the original end-of-batch review missed; the reviewer's friction note suggested adding a convention-docs checklist to this methodology, which is now codified above.
```

### Verdict: PASS — section is concrete (not header-only), no flag required

**Reasoning:** The section enumerates **4 distinct concrete checks**, each with a named rule, a procedure question, and (for the Forward-compatibility check) a cross-reference to Batch 21c BD-122 ↔ BD-136. Each item is structured "**Name.** Diagnostic question." — the diagnostic-question form is operationally concrete (a reviewer can apply the question to any convention doc and produce a yes/no/partial answer). The empirical-basis paragraph names the BD-122 retro that motivated the checklist.

V2's STRENGTHEN trigger requires "only a header / placeholder" — the existing section is the opposite (substantive 4-item checklist + empirical basis). No flag required; coder's "no edit, no flag" verdict is correct.

---

## §6 — V11-15 grep audit (independent verification)

### Independent grep verb executed

```bash
grep -RIln 'IMPLEMENTATION-PLAN-V11.0.md' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/ 2>/dev/null
```

### Independent grep results (9 file-hits)

| # | File | Hit line(s) | In/Out-of-scope | Classification (per V2 V11-15) | Verdict |
|---|---|---|---|---|---|
| 1 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | 247 | In-scope (`supporting-docs/` per V2 V11-15 scope list) | HISTORICAL — empirical-basis prose for `### Filename hygiene in reference-doc citations` section; the entire paragraph's pedagogical value is the contrast between the wrong name and the canonical name (cf. "five Group D+E reviewer prompts cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); canonical filename is `EXECUTION-PLAN-V11.0.md`") | LEAVE AS-IS — matches coder verdict |
| 2 | `maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md` | 156 | In-scope (`maintenance-docs/`) — but classified PM-only / will be archived in 19b-7 per PLAN §1 row 54 | HISTORICAL — raw cleanup-input session-note item #15 / V11-15 source row; record of the input that motivated V11-15 fix | LEAVE AS-IS — matches coder verdict |
| 3 | `maintenance-docs/v11-implementation/PACK-REVIEW-BD-116-RETRO.md` | 554 | In-scope (`maintenance-docs/`) — but RETRO review doc, immutable per pack convention | HISTORICAL — review doc analyzing an old reviewer prompt that itself cited the wrong filename | LEAVE AS-IS — matches coder verdict |
| 4 | `maintenance-docs/v11-implementation/PACK-REVIEW-BD-117-RETRO.md` | 469, 471, 472 | In-scope (`maintenance-docs/`) — but RETRO review doc, immutable | HISTORICAL — same as #3, RETRO review analyzing wrong-filename prompts | LEAVE AS-IS — matches coder verdict |
| 5 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117-RETRO-FIX.md` | 448 | In-scope (`maintenance-docs/`) — but RETRO-FIX impl-report, immutable | HISTORICAL — fix-coder report explaining doc-name-confusion fix | LEAVE AS-IS — matches coder verdict |
| 6 | `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` | 83, 85, 710 (3 lines in 1 file) | Out-of-scope per V2 V11-15 scope (V2 architect doc is PM-only source-of-truth) | OUT-OF-SCOPE — V2 architect doc literally describes the V11-15 fix; references ARE the doc's subject matter (the grep-verb literal is on line 710) | LEAVE AS-IS — matches coder verdict |
| 7 | `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md` | 101 | Out-of-scope (superseded V1 architect doc; archived in 19b-7) | OUT-OF-SCOPE — V1 architect doc, superseded | LEAVE AS-IS — matches coder verdict |
| 8 | `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md` | 52, 273, 275 | Out-of-scope (planner doc, source-of-truth for this batch's scope; archived in 19b-7) | OUT-OF-SCOPE — planner doc defines the V11-15 fix being executed | LEAVE AS-IS — matches coder verdict |
| 9 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md` | 26, 63, 161, 166, 175, 176, 177, 178, 179, 180, 181 (11 lines) | Out-of-scope (this IMPL-REPORT is a workflow artifact, archived in 19b-7) | OUT-OF-SCOPE — IMPL-REPORT's grep-table contains the verbatim filename it is classifying; self-reference | LEAVE AS-IS — not enumerated in coder's table (see NIT-2 in §2) |

### Verdict on coder's enumeration: PASS with NIT

**Reasoning:**
- All 9 file-hits are correctly classifiable as HISTORICAL or OUT-OF-SCOPE.
- All classifications match (where the coder enumerated the hit).
- The coder's report says "8 hits total" and enumerates 7 rows (V1 + V2 architect docs each as one row = 8 file-hits). The 9th hit is the coder's own IMPL-REPORT, which is a structural self-reference (the IMPL-REPORT contains the grep-verb literal, classification table text, and per-row file references — every literal occurrence of `IMPLEMENTATION-PLAN-V11.0.md` in the report is part of the analysis BY DEFINITION). This is a non-load-bearing enumeration drift; the IMPL-REPORT is itself archived in 19b-7 and never read again as a live source-of-truth doc.
- The coder's `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` line cite is `:245` but the post-edit-state line is `:247` (the V11-13 insertion before this report was written shifted lines by +2). Non-load-bearing.

### Final verdict on V11-15 fix-or-leave decision: PASS — 0 source edits needed

The V2 V11-15 row's "If the reference is historical, leave it as-is and report" governs all 9 hits. The planner's pre-check (PLAN line 52) and the coder's expanded verification both correctly conclude no source edits are needed. Reviewer concurs.

---

## §7 — Out-of-scope check

### `git status --short` (independently re-run at review-time)

```
 M supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-3.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-4.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-5.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-2-RC9.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-2.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-4.md
?? maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md
```

**Modified tracked files:** exactly 1 — `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`. This is the sole in-scope edit. PASS.

**Untracked files (16 `??`):** all are pre-existing workflow artifacts from prior 19b commits (architect docs V1+V2+addendum, planner doc, 5 IMPL-REPORTs, 4 PACK-REVIEW docs, research doc, cleanup-inputs source doc). These are exempted-during-batch per the "Skill and agent maintenance" memory rule in CLAUDE.md ("Workflow artifacts... are exempted from the 'no new top-level doc' structural signal during their batch's active development; they sweep to `maintenance-docs/archive/vN/` at version ship as the final pre-tag step") AND scheduled for archive in 19b-7 per PLAN §1 row 54. The list will gain the new PACK-REVIEW-CLEANUP-BATCH-19B-19b-5.md file written by this review; same exemption applies.

**No out-of-scope edits.** PASS.

---

## §8 — Validator + baseline test independent verification

### `python3 scripts/validate-pack.py` (re-run at review-time)

```
============================================================
PASSED — all checks clean
```

All 35 checks PASS. Tail output shows clean Checks 30-35 (recommendation-state, skill-cell consistency, per-entry mirror/toc/cross-ref, phase-task lib invariants). PASS.

### Baseline test 1 — `scripts/tests/tracker-config-test.sh` (different from coder's choice)

```
=== Group 3: schema_version + dispatcher integration ===
  PASS 3.1 schema_version_check pass on schema_version=1
  PASS 3.2 schema_version_check on schema_version=99 → validation
  PASS 3.2 schema_version_check error names actual version
  PASS 3.3 schema_version_check missing key → validation
  PASS 3.4a no env var → github (default)
  PASS 3.4b _TRACKER_PROVIDER_CONFIG_PATH set → backend.name=stub
  PASS 3.4c override wins absolutely
  PASS 3.5 missing config file → github fallback

=== Summary ===
Passed: 32
Failed: 0
All tests passed.
```

**Status:** 32/32 PASS.

### Baseline test 2 — `scripts/tests/test-init-project.sh` (different from coder's choice)

```
=== Group 5: BD-166 sub-step 7 idempotency (proof loop) ===
  PASS 5.1 helper-level re-invocation rc=0
  PASS 5.2 docs/project/BACKLOG.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/IMPLEMENTATION-PLAN.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/CHANGELOG.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/backlog/_toc.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/implementation-plan/_toc.md byte-identical after helper re-invocation (idempotent)
  PASS 5.2 docs/project/changelog/_toc.md byte-identical after helper re-invocation (idempotent)

=== Summary ===
Passed: 67
Failed: 0
All tests passed.
```

**Status:** 67/67 PASS.

### Verification verdict: PASS

Validator + 2 independent baseline tests (different from coder's persona-contracts and tracker-init choices) all PASS. The supporting-docs prose edit cannot plausibly affect any of these tests (no script wiring, no fixture state, no template surface), but I confirmed empirically rather than by reasoning.

---

## §9 — RC9 recursive base case verification

### Diff against v11-surface globs

```bash
git diff --name-only | grep -E '^(project-template/|scripts/)'
# (empty output)
```

**Result:** zero edits to v11-surface globs (`project-template/*` or `scripts/*`). RC9 base case applies.

**Manifest regen required?** NO. The RC9 rule (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md` per the untracked file listed) defines manifest regen as required only when v11-surface files change. `supporting-docs/` is documentation surface, not packed-into-project surface — this is the textbook base case the RC9 rule contemplates. The coder's `§7` IMPL-REPORT analysis is correct.

PASS.

---

## §10 — Reviewer recommendation

**APPROVE the 19b-5 working-tree state for commit.**

The 2-line edit is a faithful application of V2 §B V11-13 architect-supplied wording with correct placement, defensible whitespace normalisation to match the surrounding methodology-file house style, and verified zero-edit verdicts on V11-12 / V11-14 / V11-15. Validator + 2 independent baseline tests PASS. RC9 base case applies — no manifest regen needed.

**Two NIT findings** (both in the IMPL-REPORT, not in the source edit):
1. Coder's grep-hit-list cites pre-edit line numbers (`:245` / `:469-472`) rather than post-edit (`:247` / `:469, 471, 472`).
2. Coder's hit-count says "8" but live grep returns 9 (the 9th being the coder's own IMPL-REPORT, a structural self-reference).

Per the pack memory rule `feedback_fix_all_review_findings`, default disposition is FIX. Per pack rule on "no fix for cosmetic IMPL-REPORT updates" and the workflow-artifact archive policy (the IMPL-REPORT is archived in 19b-7 and never re-read as a live source-of-truth doc), Pack Chat may reasonably triage these NITs as SKIP with the rationale "non-load-bearing IMPL-REPORT cosmetic drift; archived in 19b-7." The triage decision belongs to Pack Chat per the `feedback_pack_chat_does_no_fixes` rule.

**Commit-message guidance** (consistent with PLAN §1 row 52 commit-message template):

> `docs: v11 — Batch 19b cleanup — V11-13 must-include-in-prompt rule extension to CONCEPTUAL-REVIEW-METHODOLOGY.md (Batch 19b)`

Or, more concise:

> `docs: v11 — Batch 19b cleanup — V11-12/13/14 verification + V11-15 grep audit`

Pack Chat selects the commit message per house style.

**No follow-up needed beyond the routine 19b-6 / 19b-7 sequence already in PLAN §1.**
