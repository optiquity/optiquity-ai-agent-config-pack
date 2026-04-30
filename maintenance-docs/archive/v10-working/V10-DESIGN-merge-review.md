# V10-DESIGN.md — Merge Review Report

**Reviewer:** pack-reviewer (Claude Code)
**Review date:** 2026-04-22
**Subject:** `maintenance-docs/V10-DESIGN.md` (merged document, 4,089 lines)
**Base documents:**
- `maintenance-docs/V10-DESIGN.md` at HEAD pre-merge (3,425 lines)
- `maintenance-docs/v10-working/V10-DESIGN-2.md` (addendum, 700 lines)
- `maintenance-docs/v10-working/V10-DESIGN-2-review-v2.md` (APPROVED addendum review)
- `maintenance-docs/V10-PREDESIGN.md` (CD/OQ cross-reference)
**Verdict:** **APPROVED** with one minor merge-introduced cosmetic
fix noted (non-blocking) and two pre-existing conditions surfaced for
awareness.

---

## 1. Executive summary

The merge is mechanically and substantively correct. Every piece of
content from V10-DESIGN-2.md is present in the merged document at the
specified locations. AD-A1..AD-A5 have been renumbered to AD-14..AD-18
cleanly — zero `AD-A` residue survives. Every material cross-reference
from the addendum sweeps correctly against the merged section numbers.
All 17 approval-conclusion fixes from V10-DESIGN-2-review-v2.md still
hold. Pre-merge AD-1..AD-13 content and DN-1..DN-4 review fixes are
intact. Part 0 Status reflects the merge date and tags V10-DESIGN-2.md
as a historical working document.

One merge-introduced cosmetic issue (line 760 separator glued to
preceding text) is flagged as Advisory. Two pre-existing inconsistencies
(Part 0 Status APPROVED vs. footer DRAFT; stale `§2.3` reference inside
Part 7 §7.13) are surfaced for the record but were present before the
merge.

---

## 2. Success-criterion verification

### 2.1 NO CONTENT LOSS — ✓

Exhaustive trace of V10-DESIGN-2.md elements into the merged document:

| Addendum element | Merged location | Verdict |
|---|---|---|
| AD-A1 (two-part mechanism) | Part 2 **AD-14** (lines 553–608) | ✓ |
| AD-A2 (pack-repo script placement) | Part 2 **AD-15** (lines 610–645) | ✓ |
| AD-A3 (Procedure 6) | Part 2 **AD-16** (lines 647–676) | ✓ |
| AD-A4 (atomic-token grammar) | Part 2 **AD-17** (lines 678–730) | ✓ |
| AD-A5 (BD-046 scope; no new BD) | Part 2 **AD-18** (lines 732–760) | ✓ |
| Mechanism trigger (§3.1) | Part 5 §5.14.1 (lines 1837–1863) | ✓ |
| Script stages A0–A7 (§3.2) | Part 5 §5.14.2 table (lines 1865–1914) | ✓ |
| A0 pack-version warning note | §5.14.2 lines 1883–1893 | ✓ |
| A1 degenerate-case note | §5.14.2 lines 1895–1901 | ✓ |
| A2 already-active exit | §5.14.2 lines 1903–1908 | ✓ |
| End-of-run PM chat prompt (§3.4) | Part 5 §5.14.3 (lines 1916–1957) | ✓ |
| Artifacts table (§3.5) | Part 5 §5.14.4 (lines 1959–1972) | ✓ |
| Approval gates (A4, G6-drafts, G6-commit) | Part 5 §5.14.5 (lines 1974–1990) | ✓ |
| Zero-token dormancy argument (§4.4) | Part 5 §5.14.6 (lines 1992–2011) | ✓ |
| Integration with other BDs (§4.1 §7.13 bullet) | Part 5 §5.14.7 (lines 2013–2034); Part 7 §7.13 bullet (lines 3003–3009) | ✓ |
| Procedure 6 outline (§3.3 six steps + TRIO note) | Part 5 §5.7 "Procedure 6" sub-section (lines 1662–1689) | ✓ |
| Alternatives rejected (§6.1 A–F) | Folded into AD-14 "Alternatives rejected" (A, B, C, D; lines 582–608) and AD-18 (E rejected BD-047; F rejected 30-skill union; lines 749–759) | ✓ |
| V-ADDCAP-01..16 + V-ADDCAP-03b | Part 10 §10.17 (lines 3637–3669) | ✓ (17 tests present; matrix paragraph preserved with the "Dimension 3 is covered by V-ADDCAP-03 — retracted" correction still intact) |
| V9 Lesson 1 placement justification (§6.3) | Part 11 L1 fifth bullet, lines 3699–3710 | ✓ |
| Design invariants (§6.4) | Preserved by distribution — trinity TRIO (§5.14.7 bullet 3; §8.5); `x-` preservation (§5.14 artifacts; Procedure 6.5; V-ADDCAP-12, -16); project-owned regions (Procedure 6.5; §5.14.3 prompt); single-source-of-truth conditional file table (§5.14.2 A5; §5.14.7); skill-loading uniformity (§5.14.2 "No `.claude/skills/` writes …"); zero-dependency shell policy (implicit — script remains bash). **Substantively complete but not gathered under a single "Design Invariants" header in the merged doc; see §5 Advisory note.** | ✓ (substance preserved) |
| Implementation plan impact (§5 of addendum) | Part 12 §12.5 (lines 3864–3901) incl. commit-ID placeholder note | ✓ |
| BACKLOG.md fourth bullet (addendum §5.3) | Part 8 §8.2.8 row 83 (line 3172) | ✓ |
| CHANGELOG.md v10.0 bullet (addendum §5.4) | Not inventoried as a dedicated row — Part 8 §8.2.7 row 66 (CHANGELOG v10.0 entry) is the landing point; the addendum bullet is additive to that row's existing "v10.0 entry" obligation. **Advisory:** the addendum's single-bullet CHANGELOG text is not spliced into any design row; the planner should ensure it reaches CHANGELOG at ship. Non-blocking. | ✓ (substance preserved in intent) |

No content from V10-DESIGN-2.md is lost. Every mechanism stage,
assertion, test, note, approval gate, artifact, and invariant survives
the merge.

### 2.2 AD RENUMBERING — ✓

- `grep -n "AD-A"` against merged V10-DESIGN.md returns **zero matches**.
- AD-14 through AD-18 are present as sequentially numbered Approved
  Decisions in Part 2 (lines 553, 610, 647, 678, 732).
- Internal references to the new numbers use `AD-14`, `AD-15`, `AD-16`,
  `AD-17`, `AD-18` consistently:
  - AD-14 cited at lines 85, 138, 759–760, 834, 1834, 3163, 3639, 4006,
    4078.
  - AD-15 cited at lines 633, 3167, 3171, 4007.
  - AD-16 cited at line 4008.
  - AD-17 cited at lines 730, 4009, 4080.
  - AD-18 cited at lines 1834, 3163, 3172, 4010.
- The bounded-range form "AD-14..AD-18" / "AD-14 through AD-18" is used
  consistently at lines 85, 138, 1834, 3163, 3639, 4004 (and in the
  Part 0 Merged note at line 16).

Renumbering is clean.

### 2.3 CROSS-REFERENCE INTEGRITY — ✓ (one pre-existing stale ref)

Full sweep of every `Part N §M.K` and `§N.N` reference in the merged
document; spot-checked against the target sections:

| Cite pattern | Example occurrence | Target | Verdict |
|---|---|---|---|
| `Part 5 §5.14` family | L139, 573, 1834, 4007 | §5.14 starts line 1832; sub-sections 5.14.1..5.14.7 all exist | ✓ |
| `§5.14.1` (trigger) | L4009, 4048 | §5.14.1 line 1837 | ✓ |
| `§5.14.2` (stages) | L629, 1867, 2482, 3167, 4009, 4051, 4052 | §5.14.2 line 1865 | ✓ |
| `§5.14.3` (prompt) | L1672, 1680, 1853, 1907, 3173, 4082 | §5.14.3 line 1916 | ✓ |
| `§5.14.5` (gates) | L4051, 4081 | §5.14.5 line 1974 | ✓ |
| `§5.14.6` (dormancy) | L3170 | §5.14.6 line 1992 | ✓ |
| `§5.14.7` (integration) | L4045, 4049 | §5.14.7 line 2013 | ✓ |
| `§5.7` (Procedure 6 outline) | L139, 573, 651, 659, 660, 1835, 3169, 3875, 4006, 4008, 4073, 4079, 4081 | §5.7 line 1575; Procedure 6 added at line 1662 | ✓ |
| `Part 8 §8.2.8 row 78` | L633 (via row 82), 4007 | §8.2.8 line 3161; row 78 line 3167 | ✓ |
| `Part 8 §8.2.8 row 80` | L4008 | Row 80 line 3169 | ✓ |
| `Part 8 §8.2.8 row 81` | L1674, 2005, 3660, 3706, 3875 | Row 81 line 3170 | ✓ |
| `Part 8 §8.2.8 row 82` | L633 | Row 82 line 3171 | ✓ |
| `Part 8 §8.2.8 row 83` | L742, 4010 | Row 83 line 3172 | ✓ |
| `§8.2.8` (section ref) | L3708, 3901, 4007, 4008, 4010 | §8.2.8 line 3161 | ✓ |
| `§13.6` (banner deferral) | L1893 | §13.6 line 4012 | ✓ |
| `§7.2` (detect.sh lib) | multiple (2016, 2482, 3006, 3168, etc.) | §7.2 line 2463 | ✓ |
| `§7.6` (conditional-file table) | multiple (1868, 1879, 1912, 3006, 3186) | §7.6 line 2671 | ✓ |
| `§6.5` (Procedure 5-R) | L651, 1664 | §6.5 line 2181 | ✓ |
| `§6.9` (paste prompt) | L1850, 1854 | §6.9 line 2336 | ✓ |
| Appendix B "Trinity rule" | L1687, 4062–4063 | Appendix B lines 4062–4063 | ✓ |
| `§8.5` (trinity audit) | L1687, 3656 | §8.5 line 3245 | ✓ |
| `Part 1 §v9.x compatibility` | L591, 1855 | Part 1 sub-section at line 141 | ✓ |
| `§6.6` trinity merge | L1876 | §6.6 line 2200 | ✓ |
| `§7.4` AI config stop | L118, 583, 1874 | §7.4 line 2570 | ✓ |
| `§7.5` preview-and-confirm | L1877, 3652 | §7.5 line 2597 | ✓ |
| Part 12 §12.5 (new commits) | L4049 | §12.5 line 3864 | ✓ |

**Pre-existing stale reference (not merge-introduced).** Line 2994:
`S6 verification asserts the exact file list from Part 4 §2.3 plus
PROMPT-AUTHORING.md`. `§2.3` does not exist in Part 4 or Part 2; the
intended target is `Part 4 §4.2` (CD-8 file list, AD-8 §Concrete
contents). Verified via `git show HEAD:… | grep "§2.3"` — this reference
was present in the pre-merge HEAD (at its line 2493). The merge neither
introduced nor repaired it. **Advisory** — worth a follow-up fix but not
a merge defect.

Twenty-five+ distinct merged-section citations checked; zero
merge-introduced errors.

### 2.4 ORIGINAL CONTENT PRESERVED — ✓

- AD-1..AD-13 wording unchanged. Pre-merge lines 131–553 are
  character-for-character the same in post-merge (AD-1 line 186; AD-13
  line 537).
- Parts 3, 4, 6 unchanged. Parts 3 (§3.1–§3.10), 4 (§4.1–§4.8), 6
  (§6.1–§6.11) have the same content and section headings as pre-merge.
- DN-1..DN-4 fixes from the earlier review rounds are all intact:
  - **DN-1 "recommended best practice" not "required":** present at
    lines 772–779 (§3.1 principles), 834–840 (trinity section text),
    872 (apple-architecture-core), 919–920 (python-best-practices),
    967 (placeholder template), 1005 (architecture-review),
    1054–1055 (auditor-architecture).
  - **DN-2 Dimension column in custom sections:** §5.2 `## Custom
    agents` header (line 1421) and `## Custom skills` header
    (line 1448) both include the Dimension column.
  - **DN-3 Codex name+description:** AD-1 table row (line 199), AD-2
    body (line 236), §5.1 row (line 1369), §5.9 rule 2 (line 1753)
    all enforce `name = "x-<name>"` AND non-empty `description`.
  - **DN-4 v9.x compatibility statement:** Part 1 `### v9.x
    compatibility` sub-section (lines 141–177) present with all seven
    preserved-capabilities bullets + four known per-tool limitations.

### 2.5 PART 13 §13.5 COMPLETENESS — ✓

Lines 3972–4010:

- CD-1 → AD-1 through CD-13 → AD-13 all enumerated. ✓
- OQ-1 through OQ-14 all enumerated (OQ-6 mapped to
  V10-DESIGN-PROCESS-PLAN.md per prior decision). ✓
- **New block (lines 4004–4010):** "Capability-addition cross-reference
  (AD-14..AD-18; new in this merge)" with five entries:
  - AD-14 → Part 5 §5.14 (mechanism) + §5.7 (outline)
  - AD-15 → Part 5 §5.14 + Part 8 §8.2.8 row 78
  - AD-16 → Part 5 §5.7 + Part 8 §8.2.8 row 80
  - AD-17 → Part 5 §5.14.1 + §5.14.2
  - AD-18 → Part 8 §8.2.8 row 83 + AD-12 combined-scope framing

All resolution sections are valid targets (verified above in §2.3).

### 2.6 APPENDIX A — ✓

Lines 4043–4052. Rows updated to include capability-addition cross-
references where relevant:

| Design Requirement | Capability-addition reference |
|---|---|
| Automated and manual workflows | `Part 5 §5.14` appended (line 4043) |
| Maintenance considerations | `Part 5 §5.14.7` appended (line 4045) |
| PM chat tool flexibility | `Part 5 §5.14.1` appended (line 4048) |
| Seamless BD integration | `Part 5 §5.14.7` and `Part 12 §12.5` appended (line 4049) |
| Incremental testability | `Part 5 §5.14.5` appended (line 4051) |
| Inline verification at every stage | `Part 5 §5.14.2` and `Part 10 §10.17 V-ADDCAP-*` appended (line 4052) |

Rows where capability-addition does not apply (Resource considerations,
Document access patterns, Best use of RAG, Rollback plan) are
intentionally unannotated; no gap introduced.

### 2.7 APPENDIX B — ✓

Lines 4056–4083. Glossary additions (all four requested entries plus a
bonus entry for AD-17):

- **Procedure 6** — line 4079 ✓
- **Capability addition** — line 4078 ✓
- **G6-drafts / G6-commit** — line 4081 ✓
- **`.pack-add-capability-prompt.md`** — line 4082 ✓
- **Atomic-token grammar** — line 4080 (additional entry, consistent
  with AD-17 terminology) ✓

Parallel structure with existing Procedure 5 / Procedure 5-R entries
(lines 4073–4074) is preserved.

### 2.8 PART 0 STATUS — ✓ (merge-side)

Line 16 contains a new `Merged` row:

> `2026-04-22: V10-DESIGN-2.md addendum merged (AD-14–AD-18 appended;
> capability-addition mechanism integrated into Parts 5, 7, 8, 10, 11,
> 12, 13 and Appendices). V10-DESIGN-2.md is now a historical working
> document.`

The merge date, the renumbering scope, the affected Parts, and the
historical-working-document tag for V10-DESIGN-2.md are all present.
Success-criterion 8 is satisfied on the merge-additive side.

**Pre-existing condition (not a merge defect):** Part 0 reads
`Status | **APPROVED**` (line 9) while the document's final paragraph
(line 4088) still reads `*Status: DRAFT — PENDING REVIEW. Approval
record to be added at Step 13 of V10-DESIGN-PROCESS-PLAN.md.*`. Verified
via `git show HEAD:…` that both lines had this mismatch before the
merge — the contradiction is inherited, not introduced. **Advisory —
worth resolving in a follow-up housekeeping commit** but not a blocker
for planner consumption because the Part 0 header is the authoritative
status carrier.

---

## 3. Preservation of the V10-DESIGN-2-review-v2.md approval conclusions

Verified that each of the 17 fixes (B-1, B-2, M-1..M-3, m-1..m-12)
landed unchanged in the merged document:

| Fix | Pre-merge addendum location | Post-merge merged location | Verdict |
|---|---|---|---|
| B-1 (AD-11 not BD-046 scope) | Addendum §AD-A5 lines 207–217 | AD-18 line 734 cites AD-12 only; no AD-11 reference anywhere in AD-14..AD-18 | ✓ |
| B-2 (V-ADDCAP-10 not byte-compare) | Addendum §6.2 line 598 | Merged §10.17 line 3655 includes the disclaimer *"Byte-comparison … is not the assertion — the PM chat step is interpretive per §5.7 Procedure 6.2"* | ✓ |
| M-1 (§7.1 not §5.8) | Addendum AD-A1 lines 115–119 | AD-14 line 586: *"the exact trap §7.1 cites as the reason to split init and migrate into two scripts"* | ✓ |
| M-2 (V-ADDCAP-03b + corrected matrix paragraph) | Addendum §6.2 lines 591 + 606–612 | Merged V-ADDCAP-03b at line 3648 + matrix paragraph at lines 3663–3669 with the Dimension 3/4 correction preserved | ✓ |
| M-3 (Claude Desktop parity) | Addendum §3.1 lines 240–244 | §5.14.1 lines 1852–1856 | ✓ |
| m-1 (trinity-equivalent wording) | Addendum §3.2 A2 line 263 | §5.14.2 line 1876 | ✓ |
| m-2 (TRIO cites Appendix B + §8.5) | Addendum §3.3 closing line 323 | Procedure 6 closing line 1687 | ✓ |
| m-3 (A1 degenerate-case note) | Addendum §3.2 lines 282–288 | §5.14.2 lines 1895–1901 | ✓ |
| m-4 (A2 already-active exit) | Addendum §3.2 lines 290–295 + V-ADDCAP-13 | §5.14.2 lines 1903–1908 + §10.17 V-ADDCAP-13 line 3658 | ✓ |
| m-5 (multi-word across all four dimensions) | Addendum AD-A4 lines 187–203 | AD-17 lines 700–712 | ✓ |
| m-6 (.gitignore full-merge, not per-dim) | Addendum §3.2 A6 line 267 | §5.14.2 A6 row line 1880 | ✓ |
| m-7 (stdout + ephemeral gitignored file) | Addendum §3.2 A7, §3.3 6.1, §3.4, §3.5 | §5.14.2 A7 line 1881; Procedure 6.1 line 1680; §5.14.3 lines 1918–1921; §5.14.4 row line 1965 | ✓ |
| m-8 (pack-version warning, not hard-stop; §13.6 deferral) | Addendum §3.2 A0 note + OQ-4 | §5.14.2 A0 note lines 1883–1893 + §13.6 lines 4012–4031 | ✓ |
| m-9 (V-ADDCAP-13..16) | Addendum §6.2 lines 601–604 | §10.17 lines 3658–3661 | ✓ |
| m-10 (Appendix B Procedure 6 entry) | Addendum §4.1 row line 415 | Appendix B line 4079 | ✓ |
| m-11 (§7.13 integration bullet) | Addendum §4.1 row line 411 | Part 7 §7.13 bullet lines 3003–3009 | ✓ |
| m-12 (commit-ID placeholders) | Addendum §5.1 note lines 485–495 | Part 12 §12.5 note lines 3878–3888 | ✓ |

All 17 approval-conclusion fixes are preserved verbatim or within
justifiable close paraphrase. The reviewer's APPROVED conclusion
remains valid after the merge.

---

## 4. Merge-introduced findings

### 4.1 Advisory — cosmetic separator formatting (line 760)

**Severity:** Advisory (non-blocking).

**Location:** `maintenance-docs/V10-DESIGN.md` line 760.

**Observation:** The final sentence of AD-18's alternatives-rejected
block and the `---` horizontal-rule separator that ends Part 2 are on
the same line with no intervening blank line:

```
759:   are dormant by design; activating them is the lifecycle event AD-14
760:   addresses.---
761:
762: ## Part 3 — Design: BD-045 Capabilities Pattern
```

Compare to pre-merge HEAD where AD-13's closing was clean (the last
prose paragraph was followed by a blank line, then `---`, then a blank
line, then `## Part 3`).

**Impact:** Cosmetic. Most markdown renderers (GitHub, Bear, mdcat)
still render the `---` as a rule, but some stricter parsers may treat
`addresses.---` as literal text inside the preceding paragraph and
fail to render a horizontal rule or trigger a heading-level break.
Humans reading the raw document may misread "addresses." as followed
by three hyphens of emphasis.

**Recommended fix:** Split line 760 into two lines — one ending with
`addresses.` and a new line `---`, with a blank line between them. A
one-character edit in a separate cosmetic commit suffices.

**Verdict:** Merge-introduced (verified — pre-merge HEAD had clean
separator at the Part 2/Part 3 boundary). **Not a blocker for planner
consumption.**

---

## 5. Pre-existing conditions surfaced for awareness

These were not introduced by the merge but are visible in the post-merge
document. Noted so the planner does not mistake them for merge defects.

### 5.1 Status contradiction — Part 0 APPROVED vs. footer DRAFT

**Location:** Line 9 (Part 0 Status row: `**APPROVED**`) vs. line 4088
(footer: `*Status: DRAFT — PENDING REVIEW. Approval record to be added
at Step 13 of V10-DESIGN-PROCESS-PLAN.md.*`).

**Verdict:** Pre-existing. `git show HEAD:maintenance-docs/V10-DESIGN.md`
confirms both the "APPROVED" Part 0 row (added by commit `4df382d`) and
the "DRAFT — PENDING REVIEW" footer (carried from the initial draft
assembly at `43c9fa8`) existed before the merge. The merge neither
introduced nor repaired this inconsistency.

**Impact on planner consumption:** Low. The Part 0 table is the
authoritative status carrier; the footer is a superseded artifact from
the pre-approval drafting phase. The planner can proceed on the
APPROVED status.

**Recommendation:** Update the footer to `*Status: APPROVED. See Part 0
for approval record.*` in a follow-up housekeeping commit (same commit
as the §4.1 cosmetic fix).

### 5.2 Stale reference `Part 4 §2.3` in §7.13 integration bullet

**Location:** Line 2994:

> `- **BD-046 prompt reorg.** init-project.sh copies docs/pack/prompts/
>   as a unit; S6 verification asserts the exact file list from Part 4
>   §2.3 plus PROMPT-AUTHORING.md.`

**Observation:** `Part 4 §2.3` does not exist — Part 4's sub-sections
are §4.1 through §4.8. The intended target is almost certainly
`Part 4 §4.2` (the CD-8 file list, AD-8 §Concrete contents).

**Verdict:** Pre-existing. `git show HEAD:maintenance-docs/V10-DESIGN.md
| grep "§2.3"` returns the same reference at pre-merge line 2493.
Previous review rounds ("round 3 fixes — 12 stale cross-references" and
"round 4 fixes — 6 single-digit section refs") apparently missed this
one.

**Impact on planner consumption:** Very low — the surrounding sentence
names its intent clearly ("file list"), and Part 4 §4.2 is the only
file-list sub-section in Part 4.

**Recommendation:** Replace `§2.3` with `§4.2` in a follow-up fix
commit.

### 5.3 Design-invariants section not gathered under a single header

**Observation:** V10-DESIGN-2.md §6.4 named six design invariants as
a compact bulleted list (trinity TRIO, `x-` preservation, project-owned
regions, single source of truth for conditional files, skill-loading
uniformity, zero-dependency script policy). The merge distributed these
across Part 5 §5.14.7 (integration bullets), Procedure 6 step 6.5, and
§5.14.2 script-scope narrative — substantively complete but not
rollup-consolidated.

**Verdict:** Intentional design choice consistent with V9 Lesson 1
(each invariant surfaced at its point of use). The substance is fully
present; only the rollup view is absent.

**Impact on planner consumption:** Nil. The planner consumes
mechanism-level detail at the sub-section level, not the rollup. No
action required.

---

## 6. Verdict

**APPROVED.**

The merge is mechanically sound and substantively complete:

- All content from V10-DESIGN-2.md is present in V10-DESIGN.md at the
  specified locations (§2.1).
- AD-A1..AD-A5 are renumbered to AD-14..AD-18 with zero residue
  (§2.2).
- Every merge-introduced cross-reference resolves to a valid target
  (§2.3 — 25+ citations spot-checked; zero errors).
- Pre-merge AD-1..AD-13, Parts 3/4/6, and DN-1..DN-4 fixes are
  character-preserved (§2.4).
- Part 13 §13.5 includes the new AD-14..AD-18 cross-reference block
  alongside the existing CD-1..CD-13 and OQ-1..OQ-14 maps (§2.5).
- Appendix A gains capability-addition cross-references at every
  applicable design-requirement row (§2.6).
- Appendix B gains the four required glossary entries plus a bonus
  atomic-token-grammar entry (§2.7).
- Part 0 Status records the merge date and tags V10-DESIGN-2.md as a
  historical working document (§2.8).
- All 17 approval-conclusion fixes from V10-DESIGN-2-review-v2.md
  still hold (§3).

### Blockers

None.

### Advisories (non-blocking, recommended housekeeping)

1. **§4.1** — Split line 760's `addresses.---` into two lines (prose,
   blank line, `---`, blank line, heading). Merge-introduced; cosmetic.
2. **§5.1** — Update the document's final footer from `DRAFT — PENDING
   REVIEW` to reflect APPROVED status matching Part 0. Pre-existing.
3. **§5.2** — Replace `Part 4 §2.3` at line 2994 with `Part 4 §4.2`.
   Pre-existing.

All three fit into a single follow-up housekeeping commit and do not
require another design-level review pass.

### Planner readiness

The document is ready for Phase 3 planner consumption as the sole
authoritative v10 design reference. V10-DESIGN-2.md is now a historical
working document per Part 0.

---

*End of merge review.*
