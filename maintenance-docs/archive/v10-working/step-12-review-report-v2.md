# Step 12 Re-Audit Report — V10-DESIGN.md (Round 2)

*Reviewer: pack-reviewer (independent re-audit session)*
*Date: 2026-04-21*
*Document under review: `maintenance-docs/V10-DESIGN.md` (3,422 lines, DRAFT — PENDING REVIEW)*
*Prior review: `maintenance-docs/v10-working/step-12-review-report.md`*
*Developer notes: `maintenance-docs/v10-working/step-12-reviewer-input.md` (DN-1..DN-4)*
*Inputs: V10-PREDESIGN.md, V10-DESIGN-PROCESS-PLAN.md, V9-DESIGN.md, CLAUDE.md, PACK-AGENTS.md, README.md*

---

## Verdict

**Status: NOT APPROVED (one Critical regression; two minor gaps).** All
other Critical (C1 partial, C2, C3, C4) and Functional (F1–F7) findings
from the prior round are resolved. Stage counts are reconciled. Trinity
rule compliance is preserved. Appendix A and Part 11 cross-references
now land on real sections.

One residual Critical issue (a single stale "required" sentence in
`python-best-practices` §3.4 rule 14) blocks approval under DN-1. Two
minor gaps identified against the prior review's explicit required-fix
checklist but do not rise to blocker status on their own.

| Severity | Count |
|---|---:|
| Critical (block approval) | 1 |
| Functional (must fix before approval) | 0 |
| Minor (should fix; non-blocking) | 3 |

---

## 1. Prior findings — RESOLVED / NOT RESOLVED matrix

### Critical

| ID | Subject | Status | Evidence |
|---|---|---|---|
| **C1** | DN-1 "required" language for capabilities | **PARTIAL — 1 regression remains** | §3.1 (506–515), §3.2 (568–576), §3.3 (608), §3.5 (703), §3.6 (740–741), §3.7 (790, 800), §3.9 (820–826) all updated to "LSP required / capabilities recommended" framing. **BUT** §3.4 python-best-practices rule 14 at **lines 655–656** still reads: *"Capabilities and LSP are independent required practices; apply each on its own merits."* This is the exact phrasing DN-1 rejects. Trinity-symmetric with apple-architecture-core §3.3 line 608 and future-language template §3.5 line 703 (both correctly reworded), so the omission is also an asymmetry introduced by the fix pass. |
| **C2** | DN-2 Dimension column | **RESOLVED** | `## Custom agents` column spec line 1157 includes `Dimension`; `## Custom skills` column spec line 1184 includes `Dimension`; column semantics paragraphs at 1166–1172 and 1193–1197 enumerate the four PLATFORM-SKILLS dimensions. Clarifying questions for Procedure 5.1 at line 1324 and Procedure 5.2 at line 1346 both include the dimension question. G-design gate at line 1119 surfaces "PLATFORM-SKILLS.md dimension" in the review artifact list. |
| **C3** | DN-3 Codex `name` + `description` | **RESOLVED** (with one minor gap — see §4.B) | AD-1 row 2 at line 142 lists both fields as required inline. AD-2 Codex bullet at lines 176–178 enumerates required fields and states Codex silently ignores agents missing either. §5.9 clause 2 at lines 1458–1459 requires both. §5.1 artifact table (line 1105) defers to "AD-2 row: Codex pack agents" rather than restating inline — acceptable indirection but less explicit than the prior review recommended. |
| **C4** | DN-4 v9.x preservation statement | **RESOLVED** | New Part 1 subsection "v9.x compatibility" at lines 84–119 opens with the exact statement "v10 preserves all v9.x functionality unless explicitly noted otherwise." Six required bullets plus an added seventh (v9.x skills) are present with cross-references to §5.1, §9.6, §7.8, §5.3, §5.6, §4.1, §4.7, §6.9. "Known per-tool limitations" subsection at 109–119 documents four limitations (Codex Bash-only hooks, Claude Desktop MCP optionality, Codex `x-` skill loading pending, Gemini hook verification pending), each linked to the deferred item in Part 13 where applicable. |

### Functional

| ID | Subject | Status | Evidence |
|---|---|---|---|
| **F1** | AD-4 "AD-8 below" → §5.4 | **RESOLVED** | Line 240: "The PM chat does **not** edit `.codex/config.toml` — no per-agent registration entry exists in documented Codex (Part 5 §5.4 resolves OQ-2)." |
| **F2** | Appendix A broken refs | **RESOLVED** | Line 3382 Resource considerations now cites "Part 4 §4.1 (token budget analysis); Part 5 §5.8 (detection scan cost is negligible — …)". Line 3384 Document access patterns now cites "Part 7 §7.9 (QUICKSTART.md as router, not procedure)". Line 3386 PM chat tool flexibility now cites "Part 7 §7.8 (init-project.sh end-of-run prompt)". Line 3389 Incremental testability now cites "eight migration stages S0–S7" and "eleven init-project.sh stages S0–S10". All targets exist and support the claims. |
| **F3** | Part 11 L1/L2 broken refs | **RESOLVED** | L1 at line 3116 now reads "Part 2 AD-3 single-path rationale for custom-file creation." L2 at lines 3137–3139 now reads "Part 2 AD-1 (Codex hyphen rule from Step 2 smoke test), Part 5 §5.4 (OQ-2 per Step 2 C-1), Part 5 §5.8 (detection at PM-chat layer per Step 2 C-3)." All four cited sections exist. |
| **F4** | Part 13 §13.5 CD-9 ref | **RESOLVED** (but see §4.C for a new OQ-7 defect in the same list) | Line 3352 now reads "CD-9 → AD-9 + Part 5 §5.1 row 4, §5.2". §5.2 exists and is the correct home for the `## Custom agents`/`## Custom skills` spec. |
| **F5** | Migration stage count | **RESOLVED** | Part 6 §6.8 line 1814: "eight stages (S0–S7)". Part 8 row 45 line 2612: "eight stages S0–S7". Appendix A line 3389: "eight migration stages S0–S7". Table at lines 1820–1829 still lists the correct 8 rows S0 through S7. |
| **F6** | init-project stage count | **RESOLVED** | Part 7 §7.6 line 2169: "Both paths share the same 11 stages (S0–S10)." Part 8 row 49 line 2621: "11 stages S0–S10". Appendix A line 3389: "eleven init-project.sh stages S0–S10". Table at 2172–2184 lists the correct 11 rows S0 through S10. |
| **F7** | §3.9 "never softened" rewrite | **RESOLVED** | Lines 820–826: "Wherever the drafts above state the relationship, LSP remains required. The capabilities pattern remains recommended — not required — and is always presented as a first-class proactive design tool rather than an escape hatch. The recommended-not-required framing is never softened to 'required,' and never exaggerated to 'mandatory.' Absence of capabilities is a recommendation/finding, not a defect. The developer may opt out if the architecture does not support it naturally." This matches the DN-1 framing exactly. |

### Polish (prior P1–P4)

Not re-audited in detail; none are blockers. P1–P4 remain eligible to
roll into v10.x.

---

## 2. DN-1 through DN-4 verification

### DN-1 — Capabilities as recommended best practice

- **"Required" → "recommended" sweep.** Applied in §3.1, §3.2, §3.3,
  §3.5 template, §3.6, §3.7 (both markdown and Codex bullets), §3.9.
  **NOT applied in §3.4 python-best-practices rule 14 (lines 655–656).**
  Sole remaining occurrence. This is a regression relative to the
  apple-architecture-core parallel rule at line 608 which correctly
  reads "LSP is required; the capabilities pattern is a recommended
  best practice." Symmetry across the per-language skills is broken.
- **LSP remains required.** Confirmed in every relationship statement
  (§3.1, §3.2 "Relationship to LSP", §3.3, §3.5, §3.6, §3.7, §3.9).
- **Developer opt-out language.** Present in §3.1 line 509 and §3.2
  line 575 ("If the capabilities pattern does not fit the project's
  architecture or the developer opts out, that is valid") and §3.9 line
  826.
- **architecture-review flags as recommendation.** §3.6 rule 14
  (line 741): "absence of capabilities is a finding, not a defect."
- **auditor-architecture surfaces as suggestion.** §3.7 line 790
  (Claude/Gemini) and line 800 (Codex): "LSP is required; capabilities
  are recommended — file capability findings under this bullet, not
  under LSP."
- **§3.9 rewritten.** See F7 RESOLVED above.
- **BACKLOG supersession note.** Present at §3.1 lines 513–515: "The
  BD-045 BACKLOG entry's original 'required' language is superseded by
  this design decision and will be updated when BD-045 is resolved at
  v10.0 ship."

**Status: NOT RESOLVED** due to line 655–656 regression only. See §4.A
for required fix.

### DN-2 — Four-dimension support

- **Dimension column in `## Custom agents`.** Present, line 1157.
- **Dimension column in `## Custom skills`.** Present, line 1184.
- **Column semantics paragraphs.** Present, lines 1166–1172 and
  1193–1197; enumerate the four PLATFORM-SKILLS dimensions.
- **Dimension question in Procedure 5.1 clarifying questions.** Present,
  line 1324.
- **Dimension question in Procedure 5.2 clarifying questions.** Present,
  line 1346.
- **G-design gate includes dimension review.** Line 1119 includes
  "PLATFORM-SKILLS.md dimension" in the artifact-under-review list.
- **Part 8 row 42 (PLATFORM-SKILLS.md) references §5.2.** Confirmed line
  2604 points at Part 5 §5.2.

**Status: RESOLVED.**

### DN-3 — Codex name and description

- **AD-1 row 2.** Line 142 lists both fields inline with the "both
  required; Codex silently ignores agents missing either field"
  qualification.
- **AD-2.** Lines 176–178 enumerate `name`, `description`,
  `model`, `approval_policy`, `sandbox_mode`, `developer_instructions`
  with "both required" annotation on name/description.
- **§5.1 Codex row (line 1105).** Defers to AD-2 via the Source-of-truth
  column ("AD-2 row: Codex pack agents"). Indirection is present; the
  explicit inline note the prior review recommended is not. See §4.B.
- **§5.9 clause 2 (lines 1458–1459).** Requires `name = "x-<name>"` and
  non-empty `description`; both required.
- **validate-pack.py check for Codex name+description.** Not added.
  §5.11 lists only Checks 6–9; Part 10 §10.1 V-CI-01..10 does not
  contain a check enforcing non-empty `name` + `description` on Codex
  TOMLs. See §4.B.

**Status: RESOLVED on the four document locations DN-3 names; minor
gaps on the recommended §5.1 inline annotation and the
validate-pack.py check.**

### DN-4 — v9.x preservation

- **Explicit preservation statement.** Part 1 subsection "v9.x
  compatibility" at lines 84–119 opens with the exact DN-4 sentence.
- **Six-bullet capability list.** Present, with cross-references. An
  additional bullet ("All v9.x skills (30)") is included; consistent
  with the preservation intent.
- **Known per-tool limitations.** Enumerated lines 109–119. Matches
  DN-4 requirement ("documented as known limitations, not silently
  accepted").
- **Part 6 §6.9 migration guide outline.** Section 2 at line 1846 is
  "What changed in v10 (three BD-item summaries + three structural
  shifts)". DN-4's companion request for a "What does NOT change from
  v9.3" subsection alongside is not added. See §4.C.
- **Appendix A "PM chat tool flexibility" row.** Line 3386 now cites
  "Part 1 §v9.x compatibility (preserved capabilities list)".

**Status: RESOLVED on the main requirement; minor gap on the Part 6
§6.9 outline companion subsection.**

---

## 3. Completeness re-check

### CD coverage (1–13)

Every CD-1..CD-13 maps to an Approved Decision AD-1..AD-13 in Part 2
and has a Part 13 §13.5 cross-reference entry. All AD entries retain
decision / rationale / alternatives-rejected structure. **PASS.**

### OQ coverage (1–14)

Part 13 §13.5 enumerates OQ-1..OQ-14 with a resolution section or
deferred item. OQ-7 is mapped to "Part 5 §5.3 (AD-3)" but §5.3 is the
pack-roster mechanism, not the creation-mechanism resolution — the
correct target for OQ-7 is AD-3 or §5.8. See §4.C. **MINOR
cross-reference defect, not a coverage defect** — OQ-7 is substantively
resolved in AD-3 and §5.8.

Part 13 §§13.1–13.4 carry four deferred items with explicit Phase 3/4
resolution targets and explicit confirmation that none blocks v10.0.
**PASS on coverage.**

### Appendix A coverage

Every V10-PREDESIGN Part 7 Design Requirement row has at least one
section reference. All referenced sections exist (verified by grep of
§-labels against in-document headings). Prior F2 broken targets are
all repaired. **PASS.**

### Renumbering integrity (BD-045 skill files)

§3.3 renumbers apple-architecture-core rules 11–23 → 15–27; §3.4
renumbers python-best-practices rules 14–32 → 18–36; §3.6 renumbers
architecture-review rules 14–15 → 18–19. Part 8 row 60 (line 2637) and
Part 10 V-BD045-07 (line 3027) call for a renumbering sweep. **PASS on
design-level intent; Phase 4 must execute.**

---

## 4. Remaining findings

### A. CRITICAL — DN-1 regression at §3.4 line 655–656

**Evidence.**

```
654: Reach for this pattern proactively during architecture — not only when
655: fixing an LSP violation. Capabilities and LSP are independent required
656: practices; apply each on its own merits.
```

This is rule 14 of python-best-practices in §3.4. It retains the exact
wording DN-1 directs to remove. The parallel rule 11 in §3.3
apple-architecture-core (line 608) and rule N1 in §3.5 future-language
template (line 703) were rewritten to "LSP is required; the capabilities
pattern is a recommended best practice. Apply each on its own merits."
but the python rule was missed.

**Required fix.** Replace lines 655–656 with:

> "…fixing an LSP violation. LSP is required; the capabilities pattern
> is a recommended best practice. Apply each on its own merits."

This is a one-line edit and restores symmetry across the three
per-language locations.

**Affects.** Part 3 §3.4 only. Part 8 row 5 and Part 10 V-BD045-06 do
not need updating — they already reference §3.4 generically. V-BD045-06
passes once the single line is corrected.

### B. MINOR — DN-3 §5.1 inline note and validate-pack check

1. **§5.1 Codex artifact row** (line 1105) uses "AD-2 row: Codex pack
   agents" as the format pointer. AD-2 contains the both-required
   requirement but a reader scanning the §5.1 table alone does not see
   it inline. The prior review recommended an explicit inline note.
   **Recommendation:** add ", incl. non-empty `name` + `description`"
   to the Source-of-truth cell, or an asterisk footnote under the
   table. Not a blocker — the pointer chain is complete.

2. **validate-pack.py check for Codex `description` non-empty** (prior
   review DN-3 fix item 6) is not present in §5.11 or Part 10 §10.1.
   Existing V-CI-09 (line 2894) tests only that
   `auditor-architecture.toml` parses after BD-045 edits; no check
   asserts every `.codex/agents/*.toml` has a non-empty `description`.
   **Recommendation:** extend validate-pack.py Check 8 or add a new
   check, and cover it in Part 10 §10.1 as V-CI-11. Not a blocker
   because §5.9 detection logic catches the gap at the project layer
   and the pack-side agents are guaranteed non-empty by the existing
   Codex-agent fix that motivated DN-3.

### C. MINOR — Residual cross-reference defect in Part 13 §13.5 and missing DN-4 companion subsection

1. **Part 13 §13.5 line 3363** reads "OQ-7 → Part 5 §5.3 (AD-3)". §5.3
   is the pack-roster mechanism (OQ-1's home). OQ-7 ("knowledgeable
   developer creates files outside PM chat") is substantively resolved
   in AD-3 and surfaced in §5.8 detection. **Recommendation:** change
   to "OQ-7 → AD-3 + Part 5 §5.8". Non-blocking documentation-integrity
   issue, not introduced by the fix pass but not caught by the prior
   round either.

2. **Part 6 §6.9 migration outline** at lines 1842–1858 has section 2
   "What changed in v10" but no companion section 2a / 2b titled
   "What does NOT change from v9.3". DN-4's fourth required fix
   explicitly calls for this. The Part 1 preservation statement partly
   absorbs the intent; adding a pointer paragraph or a single-line
   companion bullet in the §6.9 outline would close the DN-4
   requirement completely. Non-blocking.

---

## 5. No-regression sweep

### Trinity rule integrity

- §3.2 BD-045 trinity section and anti-pattern bullet — confirmed
  byte-identical intent across CLAUDE/AGENTS/GEMINI (placement text,
  wording).
- §3.7 auditor-architecture scope bullet — Claude and Gemini markdown
  identical; Codex plain-bullet deviation explicitly justified and
  consistent with existing file pattern.
- §5.6 trinity routing-table additions — TRIO marked; identical
  sub-section content specified.
- §8.5 trinity-rule integrity audit table unchanged; every BD-level
  trinity touch is marked TRIO (rows 1/2/3, 26/27/28, 39/40/41, 7/8/9).
- PM-CHAT.md explicitly called non-trinity at §5.10 line 1495 and L3
  line 3152.

**No new asymmetry introduced by fixes.** The §3.4 regression at line
655–656 is an internal asymmetry across the per-language skills (apple
and future-template say "recommended"; python still says "required"),
which is functionally a DN-1 regression rather than a trinity-rule
regression. Fix A resolves both framings simultaneously.

### Cross-reference sweep

- Appendix A references — all 9 rows point at extant sections.
- Part 11 L1–L5 references — all 5 land on extant sections.
- Part 13 §13.5 mapping — 13 CD entries correct; 14 OQ entries correct
  except OQ-7 (see §4.C.1).
- AD-4 "(AD-8 below)" — rewritten to §5.4 reference. Verified line 240.
- Stage counts — 8 migration / 11 init-project consistent across Part 6
  §6.8, Part 7 §7.6, Part 8 rows 45 and 49, Appendix A.
- PROMPT-TEMPLATES.md stale references — Part 4 §4.8 sweep list intact;
  Part 8 §8.6 grep plan intact.

### Maintenance-docs consistency

V10-PREDESIGN.md is marked for supersession banner at Step 13 (Part 8
row 63, §10.15, §12.4). No silent mutation of V9-DESIGN.md; annotation
obligations captured in Part 8 rows 36–37. **PASS.**

### validate-pack.py alignment

§5.11 Checks 6–9 + Check 1 sanity cover the new file classes added in
v10 (prompts-dir, pack roster, `x-` reservation, BD-044 structure).
Minor gap: Codex `description` check (see §4.B.2). Otherwise **PASS**.

### Migration safety

MIGRATION-v9-to-v10.md outline (§6.9), pre-flight invariants (§6.2–6.3),
eight-stage sentinel resumability (§6.8), in-place `x-` preservation
(§6.1), Procedure 5-R reconciliation (§6.5), rollback plan (§6.7) —
all internally consistent and survive the fix pass. Migration stage
count is now internally consistent (F5 RESOLVED). **PASS.**

### README layout

Part 8 row 55 and §7.12 obligate README.md Repository Layout to gain
`scripts/lib/`, `init-project.sh`, `migrate-v9-to-v10.sh`,
`merge-*.py`, `SETUP-NEW.md`, `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md`,
and the migration-guide naming convention. Obligation is captured;
execution is Phase 4. **PASS on design-level coverage.**

### BACKLOG accuracy

Part 8 row 64 tracks BD-044/045/046 resolution at v10.0 ship. BD-045
BACKLOG supersession note present at §3.1 lines 513–515. **PASS.**

---

## 6. Stage count verification (explicit per success criterion 6)

| Subject | Required text | Found at | Status |
|---|---|---|---|
| Migration | "eight stages S0–S7" | Part 6 §6.8 line 1814 ("eight stages (S0–S7)"); Part 8 row 45 line 2612 ("eight stages S0–S7"); Appendix A line 3389 ("eight migration stages S0–S7") | **PASS** |
| init-project | "11 stages S0–S10" | Part 7 §7.6 line 2169 ("same 11 stages (S0–S10)"); Part 8 row 49 line 2621 ("11 stages S0–S10"); Appendix A line 3389 ("eleven init-project.sh stages S0–S10") | **PASS** |

Tables at Part 6 §6.8 (rows S0..S7 = 8 rows) and Part 7 §7.6 (rows
S0..S10 = 11 rows) match the written stage counts. No residual
"seven"/"10" inconsistency remains.

---

## 7. Recommended disposition

1. **Apply Fix A before Step 13 approval.** One-line edit in §3.4 lines
   655–656. This restores DN-1 compliance and per-language symmetry.
2. **Apply Fix C.1 before Step 13 approval** (§13.5 OQ-7 cross-reference
   swap to "AD-3 + Part 5 §5.8"). Two-character change to the section
   number; same commit as Fix A.
3. **Consider Fixes B.1, B.2, C.2 as v10.x polish** unless the pack
   chat prefers to land them now. None blocks approval on its own.
4. **Re-audit** after Fixes A and C.1 land. Specifically grep for
   `required practice` in `maintenance-docs/V10-DESIGN.md` — expected
   result is zero matches post-fix.

---

## 8. What the document got right (unchanged from prior round)

- Every CD carried to AD with complete decision/rationale/alternatives.
- Every OQ resolved in Parts 3–10 or deferred in Parts 13.1–13.4 with
  Phase-3/4 resolution targets.
- Trinity rule symmetry preserved through all BD-045 + BD-046 edits.
- Stale-reference sweeps (Part 4 §4.8, Part 8 §8.6) partition operational
  vs. annotate-only correctly.
- Four new validate-pack checks (6–9) specified with test cases
  (V-CI-01..10).
- Migration safety (rollback, sentinel resumability, `x-` in-place skip,
  Procedure 5-R reconciliation) internally consistent.
- README.md Repository Layout obligation and BACKLOG resolution
  tracking in place.
- DN-2 (Dimension column + clarifying questions) applied in full.
- DN-4 (v9.x compatibility statement + limitations) applied in Part 1
  with cross-references.

---

*End of Step 12 Re-Audit Report (Round 2).*
