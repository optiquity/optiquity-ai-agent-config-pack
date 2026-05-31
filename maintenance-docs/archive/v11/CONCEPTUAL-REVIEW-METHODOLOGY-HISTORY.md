# CONCEPTUAL-REVIEW-METHODOLOGY-HISTORY — relocated history for `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`

**What this file is.** This archive holds the historical / empirical-provenance
content that was relocated out of the durable methodology doc
`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` when it was reshaped to a forward-only
methodology reference (commit C9 of the doc-concision-guardrails work). The active
methodology (review dimensions, touch-point classification, severity scheme, ARCH
triggers, race-condition / CI-step interrogation heuristics, convention-docs
checklist, reviewer prompt-construction discipline, report shape) lives in
`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. The material below is preserved verbatim
so future readers retain the dated empirical evidence that motivated each rule
without that provenance polluting the durable doc's forbidden-pattern budget.

**Provenance.** Originally the "Status" / "Empirical basis" creation note and the
six dated "Empirical basis (Batch 21c, 2026-05-15)" / "Empirical confirmation"
paragraphs of `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Each empirical-basis
claim that survives in the durable doc as a one-line summary points here ("Provenance
in HISTORY").

---

## Creation note (originally the "Status" + "Empirical basis" preamble)

Created 2026-05-15. Established 2026-05-15 after the Batch 17 per-BD vs end-of-batch
reviewer experiment empirically demonstrated that broader-scope reviews catch findings
narrower-scope reviews miss (and vice versa). The 73% cross-cut ratio at end-of-batch
suggested an even broader concept-level scope would catch a third class of findings.

## Race-condition heuristic — CI-workflow-vs-test-scripts re-confirmation

**Batch 21c re-confirmation (2026-05-15):** four retro reviewers (BD-078, BD-079,
BD-129) independently flagged 7 unwired test files; closed by single workflow edit
(commit `304078f`). When reviewing any commit that adds new `*-test.sh` files,
mandatory check: grep `.github/workflows/` for the new test path; if absent, MUST.

## CI-step interrogation heuristic — empirical basis

**Empirical basis (Batch 21c, 2026-05-15):** BD-118 retro reviewer applied this
interrogation and caught a MUST that the original end-of-batch review missed: the
manifest-verify step's preceding `--all --clean` step rewrote the committed
`manifest.txt` before `--verify` read it, so the verify step compared just-built
fixtures to a just-rewritten manifest — passes by construction. The reviewer's
verbatim friction note: "future per-BD review prompts for CI work should explicitly
require 'for every new CI step, identify a concrete change that would turn it red,
and confirm the wiring would actually surface that change' — that interrogation is
what surfaced this finding retroactively."

## Convention/naming docs review checklist — empirical basis

**Empirical basis (Batch 21c, 2026-05-15):** BD-122 retro reviewer flagged 3 findings
(1 SHOULD + 2 NITs) all in the convention document's procedure-rule-column triplet
that the original end-of-batch review missed; the reviewer's friction note suggested
adding a convention-docs checklist to this methodology, which is now codified in the
durable doc.

## File/Symbol scope from authoritative sources — empirical basis

**Empirical basis (Batch 21c, 2026-05-15):** the BD-112 retro trial prompt cited
`scripts/lib/three-way.sh` as the BD-112 surface; actual surface (per BACKLOG +
git --stat) was `scripts/lib/customization-preserve.sh`. Reviewer worked around the
error but flagged it as methodology friction; subsequent prompts in the batch sourced
from BACKLOG + git --stat correctly.

## Filename hygiene in reference-doc citations — empirical basis

**Empirical basis (Batch 21c, 2026-05-15):** five Group D+E reviewer prompts cited
`IMPLEMENTATION-PLAN-V11.0.md` (does not exist); canonical filename is
`EXECUTION-PLAN-V11.0.md`. Reviewers caught and worked around it; filename was later
corrected in Group A+B+C+G prompts. Lesson: every reference-doc path in a reviewer
prompt should be a recent `ls` confirmation, not a name recalled from training-pattern
context.

## Long output chunking — empirical basis

**Empirical basis (Batch 21c, 2026-05-15):** three coders blew through the threshold
despite the guidance in their prompts: BD-118 fix coder (588 lines, single Write
succeeded), BD-116 fix coder (733 lines, single Write succeeded), BD-101 fix coder
(791 lines, properly chunked via initial Write + Edit append). Single Writes succeeded
but the chunking discipline is the safer default; agents that miss this guidance need
explicit reminder. Future Pack Chat prompts MUST surface this rule prominently AND
include the BD-101 chunking pattern as the worked example.

## Empirical validation requirement — empirical confirmation

**Empirical confirmation (Batch 21c, 2026-05-15):** the per-BD-AND-per-batch review
cycle (codified in the `feedback_review_fix_one_cycle` pack memory rule on 2026-05-15)
was empirically validated retroactively across 13 BDs from prior multi-BD batches.
Aggregate findings: 7+ MUSTs caught at the per-BD review layer that the original
end-of-batch reviews missed (BD-078 missing acceptance criterion + test-not-CI,
BD-079 test-not-CI, BD-118 CI manifest tautology, BD-095 dry-run fingerprint subset,
BD-129 test-not-CI cross-BD pattern, BD-101 broken restore-from-backup.sh reference at
3 sites + Gate 2 coverage gap → BD-172). The "test-not-in-CI" heuristic was
independently flagged by 4 reviewers — strongest empirical case for codifying as a
named heuristic (now in the race-condition section + CI-step interrogation section of
the durable doc). Decision: per-BD review IS institutionalized for v11.0+ as the
default for multi-BD batches, with end-of-batch review remaining the cross-cut catch.

---

**End of CONCEPTUAL-REVIEW-METHODOLOGY-HISTORY.md.**
