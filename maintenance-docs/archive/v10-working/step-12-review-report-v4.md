# Step 12 Re-Audit Report — V10-DESIGN.md (Round 4)

*Reviewer: pack-reviewer (independent re-audit session)*
*Date: 2026-04-21*
*Document under review: `maintenance-docs/V10-DESIGN.md` (3,423 lines, DRAFT — PENDING REVIEW)*
*Prior reviews: `step-12-review-report.md` (Round 1), `step-12-review-report-v2.md` (Round 2), `step-12-review-report-v3.md` (Round 3)*
*Developer notes: `step-12-reviewer-input.md` (DN-1..DN-4)*
*Inputs also consulted: V10-PREDESIGN.md, CLAUDE.md, PACK-AGENTS.md*

---

## Verdict

**Status: NOT APPROVED — six Functional cross-reference defects remain.**

All prior findings from Rounds 1–3 are resolved. DN-1 through DN-4 are fully
applied. Stage counts, trinity symmetry, CD→AD coverage, OQ resolution,
DN-compliance sweeps, and the five grep checks from Round 3 §8 all pass.

The Round 3 fix pass was scoped to the specific regex patterns surfaced in
Round 3 (`Part N §X.Y` with a decimal). The wider document-wide sweep this
round required per Success Criterion 3 surfaces **six additional stale
`Part N §M` references** (single-digit section numbers, not caught by the
Round 3 regex). By Round 1's own severity scale these are Functional defects:
leaving them leaves the design doc unable to act as its own lookup reference
for Phase 3 implementation planning.

Each is a one-line edit. No Critical, no regression, no trinity asymmetry,
and no content defect introduced by the Round 3 fixes.

| Severity | Count |
|---|---:|
| Critical (block approval) | 0 |
| Functional (must fix before approval) | 6 |
| Minor (non-blocking; should fix) | 2 (carryover B.2, C.2) |

A single targeted pass clears all six Functional defects; the document is
then approvable.

---

## 1. All prior findings — resolution matrix

### Round 1 — C1–C4 and F1–F7

| ID | Subject | Round 4 status | Evidence |
|---|---|---|---|
| **C1** | DN-1 "required" sweep across §3 | **RESOLVED** | §3.1 lines 506–515; §3.2 lines 568–576; §3.3 line 608; §3.4 lines 655–656 (Round 2 regression repaired); §3.5 line 703; §3.6 line 741; §3.7 lines 790 + 800; §3.9 lines 820–826. `grep -n "required practice" V10-DESIGN.md` → 0 matches. `grep -nE "independent required|Capabilities are required|required regardless"` → 0 matches. LSP-is-required language preserved in all relationship statements. |
| **C2** | DN-2 Dimension column + clarifying questions | **RESOLVED** | Dimension column at lines 1157 (`## Custom agents`) and 1184 (`## Custom skills`). Semantics paragraphs at 1166–1172 and 1193–1197 enumerate all four PLATFORM-SKILLS dimensions. Procedure 5.1 line 1324 and Procedure 5.2 line 1346 ask dimension. G-design review line 1119 surfaces it. |
| **C3** | DN-3 Codex `name` + `description` | **RESOLVED** | AD-1 row 2 line 142 lists both inline; AD-2 lines 176–178 enumerate; §5.1 row 2 line 1105 with inline both-required note (Round 2 B.1 applied); §5.9 clause 2 lines 1458–1459 requires both. |
| **C4** | DN-4 v9.x preservation statement | **RESOLVED** | Part 1 `### v9.x compatibility` lines 84–119 opens with exact DN-4 sentence; seven-bullet preservation list at 89–107 with cross-references; four documented per-tool limitations at 109–119. |
| **F1** | AD-4 "AD-8 below" → §5.4 | **RESOLVED** | Line 240: "(Part 5 §5.4 resolves OQ-2)". |
| **F2** | Appendix A broken refs | **RESOLVED** | Line 3383 Resource considerations → Part 4 §4.1, Part 5 §5.8; line 3385 Document access patterns → Part 7 §7.9; line 3387 PM chat tool flexibility → Part 7 §7.8, Part 1 §v9.x compatibility; line 3390 Incremental testability → eight stages / eleven stages. All targets exist. |
| **F3** | Part 11 L1/L2 broken refs | **RESOLVED** | L1 line 3117 → "Part 2 AD-3". L2 now correctly cites Part 2 AD-1, Part 5 §5.4, Part 5 §5.8 (Round 3 Minor 5.D typo at old line 3136 was repaired; current Part 11 wording reads "Part 2 AD-1 (Codex hyphen rule from Step 2 smoke test)"). |
| **F4** | Part 13 §13.5 CD-9 ref | **RESOLVED** | Line 3353 "CD-9 → AD-9 + Part 5 §5.1 row 4, §5.2". Both targets exist. |
| **F5** | Migration stage count | **RESOLVED** | §6.8 line 1814 "eight stages (S0–S7)"; Part 8 row 45 line 2613; Appendix A line 3390. Table at 1820–1829 has 8 rows. Consistent. |
| **F6** | init-project stage count | **RESOLVED** | §7.6 line 2170 "11 stages (S0–S10)"; Part 8 row 49 line 2622; Appendix A line 3390. Table at 2173–2185 has 11 rows. Consistent. |
| **F7** | §3.9 "never softened" rewrite | **RESOLVED** | Lines 820–826 match DN-1 framing exactly (LSP required / capabilities recommended / framing never softened to "required" or exaggerated to "mandatory" / absence is a finding not a defect / opt-out permitted). |

### Round 2 — A, B.1, B.2, C.1, C.2

| ID | Subject | Round 4 status | Evidence |
|---|---|---|---|
| **A** | §3.4 python rule 14 regression | **RESOLVED** | Lines 655–656: "LSP is required; the capabilities pattern is a recommended best practice. Apply each on its own merits." Byte-symmetric with §3.3 line 608 and §3.5 line 703. |
| **B.1** | §5.1 Codex row inline note | **RESOLVED** | Line 1105 includes "(both `name` and `description` required; Codex silently ignores agents missing either)". |
| **B.2** | validate-pack.py Codex `description` check | **NOT APPLIED (still minor; non-blocking per Rounds 2–3)** | §5.11 still has Checks 6–9 only. No V-CI test asserts every `.codex/agents/*.toml` has non-empty `description`. Status unchanged from Round 3 disposition; rolls to v10.x polish. |
| **C.1** | OQ-7 cross-ref | **RESOLVED** | Line 3364 "OQ-7 → AD-3 + Part 5 §5.8". Both targets exist. |
| **C.2** | §6.9 "What does NOT change" | **RESOLVED** | Line 1846 has the companion subsection per Round 3 verification. |

### Round 3 — 5.A, 5.B, 5.C, 5.D

| ID | Subject | Round 4 status | Evidence |
|---|---|---|---|
| **5.A** | "Part 4 §2.3 / §2.1 / §2.2 / §1.2" six occurrences | **RESOLVED** | `grep -nE "Part 4 §[123]\.[0-9]+" V10-DESIGN.md` → **zero matches** (success criterion 3, check 1). All six former occurrences (lines 318, 343, 346, 357, 1562, 2181) now use `Part 4 §4.2` or `Part 4 §4.1` per intent. |
| **5.B** | "Part 10 §3.1" two occurrences | **RESOLVED** | `grep -n "Part 10 §3" V10-DESIGN.md` → **zero matches** (success criterion 3, check 2). Former lines 149 and 1272 now read `Part 10 §10.1`. |
| **5.C** | "Part 7 §10" (two) and "Part 5 §8.2" (one) | **RESOLVED** | `grep -nE "Part 7 §10\b" V10-DESIGN.md` → **zero matches**. `grep -n "Part 5 §8\b" V10-DESIGN.md` → **zero matches** (success criterion 3, checks 3 and 4). Former line 432 now `Part 5 §5.8`; former lines 1509 and 1909 now `Part 7 §7.13` and `Part 7 §7.2`. |
| **5.D** | Part 11 L2 "Part 1 AD-1" typo | **RESOLVED** | `grep -n "Part 1 AD-" V10-DESIGN.md` → **zero matches** (success criterion 3, check 5). Current L2 wording reads "Part 2 AD-1". |

### Round 3 minor carryovers (5.E, 5.F)

- **5.E** (CD-9 listed twice in §5.1 CD-address line 1090). Not a defect per Round 3; informational. Unchanged.
- **5.F** (Procedure-5 insertion into METHODOLOGY.md Part 7). Flagged Round 3 as Phase 3 input; unverified against METHODOLOGY.md in this session. Unchanged; still Minor.

---

## 2. DN-1 through DN-4 — independent verification

### DN-1 — Capabilities as recommended best practice

- **Zero "required practice" instances for capabilities.** Grep confirms.
- **LSP remains required.** Confirmed in ten relationship statements
  (lines 506–507, 568, 608, 655, 703, 741, 790, 800, 820).
- **Developer opt-out clause.** §3.1 line 509; §3.2 line 575; §3.9 line 826.
- **architecture-review flags absence as finding.** §3.6 line 741.
- **auditor-architecture surfaces as suggestion.** §3.7 lines 790 (markdown)
  and 800 (Codex plain-bullet).
- **§3.9 rewritten.** Lines 820–826. Matches DN-1 exactly.
- **BD-045 BACKLOG supersession note.** §3.1 lines 513–515.
- **Per-language symmetry.** §3.3 rule 11 (608), §3.4 rule 14 (655–656),
  §3.5 rule N1 (703) — byte-identical.

**Status: RESOLVED.**

### DN-2 — Four-dimension support

- **Dimension column in both custom sections.** Lines 1157 and 1184.
- **Column semantics paragraphs enumerate all four dimensions.** Lines
  1166–1172 and 1193–1197.
- **Procedure 5.1 clarifying question.** Line 1324.
- **Procedure 5.2 clarifying question.** Line 1346.
- **G-design review artifact list.** Line 1119.
- **Part 8 row 42.** References Part 5 §5.2.

**Status: RESOLVED.**

### DN-3 — Codex `name` AND `description`

- **AD-1 row 2.** Line 142 inline, both required, Codex-ignores note.
- **AD-2.** Lines 176–178 enumerate required fields.
- **§5.1 Codex artifact row.** Line 1105 inline both-required note.
- **§5.9 Registered custom-agent clause 2.** Lines 1458–1459.
- **validate-pack.py check.** Still not added (Minor B.2 carryover).

**Status: RESOLVED** on the four design locations DN-3 names. B.2 remains
non-blocking polish.

### DN-4 — v9.x preservation

- **Explicit preservation statement.** Part 1 lines 84–87 open with exact
  DN-4 sentence.
- **Six required bullets.** All present at lines 89–104 plus an added
  seventh "All v9.x skills (30)" bullet at 100–101.
- **Known per-tool limitations.** Lines 109–119 document four limitations.
- **Part 6 §6.9 "What does NOT change" companion.** Line 1846.

**Status: RESOLVED.**

---

## 3. Cross-reference integrity — full document sweep

### 3.1 The five Round 3 §8 grep checks

| Check | Pattern | Result | Status |
|---|---|---:|---|
| 1 | `Part 4 §[123]\.[0-9]+` | 0 matches | **PASS** |
| 2 | `Part 10 §3` | 0 matches | **PASS** |
| 3 | `Part 7 §10\b` | 0 matches | **PASS** |
| 4 | `Part 5 §8\b` | 0 matches | **PASS** |
| 5 | `Part 1 AD-` | 0 matches | **PASS** |

All five Round 3 patterns clear. Fix pass for Round 3 findings is complete.

### 3.2 Wider sweep per Success Criterion 3 sentence 2

Success criterion 3 requires "a FULL document-wide sweep for any remaining
`§N.N` references where the section does not exist in the named Part. Do not
limit scope to the five patterns above."

Two regex passes were run:

- `grep -nE "Part [0-9]+ §[0-9]+(\.[0-9]+)?" V10-DESIGN.md` → 168 hits.
- `grep -nE "Part [0-9]+ §[0-9]+\b" V10-DESIGN.md | grep -vE "§[0-9]+\.[0-9]+"`
  (single-digit section numbers only) → **4 hits — all stale.**

Combined with two additional stale references surfaced by reading the lines
immediately adjacent to those four hits, **six Functional defects** were
identified. All six are Part 3–7 section references that use a pre-AD draft
numbering convention (e.g., "Part 6 §4", "Part 5 §5") that does not exist in
the assembled document. Each has a clear one-line fix.

See §4 below for the enumerated defects.

### 3.3 Every sub-section reference — individual check

All 168 `Part N §M` and `Part N §M.K` hits were bucketed by target Part and
cross-referenced against the Part's actual heading range (from
`grep -nE "^(## Part|### [0-9])" V10-DESIGN.md`). Summary:

| Target Part | Heading range | Refs pointing at existing sections | Refs pointing at non-existent sections |
|---|---|---:|---:|
| Part 3 | §3.1–§3.10 | all hits valid | 0 |
| Part 4 | §4.1–§4.8 | all valid | 0 (Round 3 5.A fixed) |
| Part 5 | §5.1–§5.13 | all valid except §5 and §7 | **2 (see 5.1 and 5.6 below)** |
| Part 6 | §6.1–§6.11 | all valid except §4, §9, §2.4 | **3 (see 5.2, 5.3, 5.4 below)** |
| Part 7 | §7.1–§7.13 | all valid | 0 (Round 3 5.C fixed) |
| Part 8 | §8.1–§8.6 | all valid except §1.4 | **1 (see 5.5 below)** |
| Part 9 | §9.1–§9.9 | all valid | 0 |
| Part 10 | §10.1–§10.16 | all valid | 0 (Round 3 5.B fixed) |
| Part 13 | §13.1–§13.5 | all valid | 0 |

No sub-section reference with decimal notation (`§N.K`) points at a
non-existent section. The six remaining defects are all single-digit
(`§N` without decimal) legacy numbering.

---

## 4. Remaining findings

### 4.A — FUNCTIONAL — "Part 6 §4" (AD-7, preservation splice rule)

**Evidence.** Line 300 reads:

```
299: content is preserved across pack upgrades by the migration splice rule
300: (Part 6 §4).
```

Part 6 has §6.1–§6.11. §6.6 is titled "PLATFORM-SKILLS.md and trinity merge
rules" and is the splice rule referenced here.

**Fix.** Replace `(Part 6 §4)` with `(Part 6 §6.6)` at line 300.

**Severity.** Functional — AD-7 is the design contract for the
`## Custom agents` / `## Custom skills` sections; its preservation-mechanism
cross-reference is a primary Phase 3 lookup target. Same severity standard as
Round 3 5.A–5.C.

### 4.B — FUNCTIONAL — "Part 5 §5" (AD-7, column spec)

**Evidence.** Line 302 reads:

```
302: Column specs are given in Part 5 §5 (exact headers, columns, and example
303: rows). A project with no customizations carries the headers with the
```

Part 5 has §5.1–§5.13. §5.2 is titled "PLATFORM-SKILLS.md — Custom sections
spec (CD-7 / AD-7)" and contains the column specs referenced here.

**Fix.** Replace `Part 5 §5` with `Part 5 §5.2` at line 302.

**Severity.** Functional — AD-7's column-spec reference is the other half of
the splice-rule pointer in 4.A. Same severity reasoning.

### 4.C — FUNCTIONAL — "Part 8 §1.4" (AD-11, commit sequencing)

**Evidence.** Line 457 reads:

```
456: and document-location edits. Single-version delivery allows coordinated
457: commits (Part 8 §1.4).
```

Part 8 has §8.1–§8.6. §8.4 is titled "Per-BD sequencing (for Phase 3)" and is
the commit-sequencing coverage referenced here.

**Fix.** Replace `Part 8 §1.4` with `Part 8 §8.4` at line 457.

**Severity.** Functional — AD-11 is the v10-scope AD for BD-045; its Phase-3
sequencing reference is required for downstream implementation planning.

### 4.D — FUNCTIONAL — "Part 6 §9" (AD-12, MIGRATION pattern)

**Evidence.** Line 469 reads:

```
468: `supporting-docs/MIGRATION-v9-to-v10.md` ships with v10.0; the automatable
469: option is `scripts/migrate-v9-to-v10.sh` with a paste-ready AI CLI prompt
470: pattern (Part 6 §9) matching the MIGRATION-v8-to-v9 convention.
```

Part 6 has §6.1–§6.11. §6.9 is titled "MIGRATION-v9-to-v10.md outline" and
is the paste-ready prompt pattern reference.

**Fix.** Replace `(Part 6 §9)` with `(Part 6 §6.9)` at line 469.

**Severity.** Functional — AD-12 is the target-version AD; its MIGRATION
artifact cross-reference drives Phase 3 script specification.

### 4.E — FUNCTIONAL — "Part 6 §2.4" (AD-13, pre-flight invariants)

**Evidence.** Line 483 reads:

```
482: **Decision.** `scripts/migrate-v9-to-v10.sh` supports exactly one source
483: baseline: v9.3 (git tag `v9.3`). Pre-flight invariants (Part 6 §2.4)
484: reject any other state. If a project is on v9.0/v9.1/v9.2, the developer
```

Part 6 has §6.1–§6.11. The pre-flight invariants live in §6.3 "Pre-flight
checks (S0)" (line 1618). §6.2 "Baseline — v9.3 only" at line 1601 states the
baseline commitment; pre-flight invariants that enforce that state are §6.3.
Per the prose ("Pre-flight invariants … reject any other state"), intended
target is §6.3.

**Fix.** Replace `(Part 6 §2.4)` with `(Part 6 §6.3)` at line 483. (If the
author intended §6.2 as the baseline statement rather than the invariant
enforcement, that change would also be acceptable; §6.3 is the better fit
given "reject any other state.")

**Severity.** Functional — AD-13 is the migration-baseline AD; pre-flight
invariants are cited in Part 10 verification tests (V-M1-01..V-M1-FAIL-*)
and must lookup correctly.

### 4.F — FUNCTIONAL — "Part 5 §7" (§4.6 agent-report convention)

**Evidence.** Line 1025 reads:

```
1024: chat always includes a REPORT FILE path and the framing appropriate to
1025: the agent's permission mode. This rule is added as a `## Behavioral rules`
     : bullet in PM-CHAT.md (Part 5 §7).
```

Part 5 has §5.1–§5.13. §5.10 is titled "PM-CHAT.md additions (summary)" and
is the correct pointer for a PM-CHAT.md `## Behavioral rules` bullet.

**Fix.** Replace `Part 5 §7` with `Part 5 §5.10` at line 1025.

**Severity.** Functional — §4.6 implements the agent-report-file convention
(V10-PREDESIGN Part 12) across all prompts and PM-CHAT.md. The PM-CHAT.md
integration reference is a primary Phase 3 lookup.

### Summary of the six Functional defects

| ID | Line | Current | Proposed | Rationale |
|---|---:|---|---|---|
| 4.A | 300 | `Part 6 §4` | `Part 6 §6.6` | Splice rule is in §6.6 |
| 4.B | 302 | `Part 5 §5` | `Part 5 §5.2` | Column spec is in §5.2 |
| 4.C | 457 | `Part 8 §1.4` | `Part 8 §8.4` | Sequencing is in §8.4 |
| 4.D | 469 | `Part 6 §9` | `Part 6 §6.9` | MIGRATION outline is in §6.9 |
| 4.E | 483 | `Part 6 §2.4` | `Part 6 §6.3` | Pre-flight invariants are in §6.3 |
| 4.F | 1025 | `Part 5 §7` | `Part 5 §5.10` | PM-CHAT.md additions are in §5.10 |

All six are one-line edits. No trinity file is affected. No content or
sequencing change. Once applied:

- `grep -nE "Part [0-9]+ §[0-9]+\b" V10-DESIGN.md | grep -vE "§[0-9]+\.[0-9]+"`
  should return zero matches.

---

## 5. No-regression sweep

### 5.1 Trinity rule integrity — PASS

- BD-045 trinity section (§3.2) and anti-pattern bullet — byte-identical
  across CLAUDE/AGENTS/GEMINI; §3.8 audit confirms.
- §3.7 auditor-architecture — Claude and Gemini markdown identical; Codex
  plain-bullet semantically identical; formatting deviation justified.
- §5.6 routing-table additions — TRIO marked.
- §6.6 trinity merge splice — atomic within S5.
- §8.5 audit table — every trinity touch marked TRIO.
- PM-CHAT.md explicitly non-trinity at §5.10 and Part 11 L3.
- No asymmetry introduced by Round 3 fixes.

### 5.2 Stale-reference sweep — PARTIAL PASS

- PROMPT-TEMPLATES.md sweep plan (Part 4 §4.8, Part 8 §8.6) — intact.
- Codex `config.toml` per-agent registration — removed per §5.4.
- `prompts/README.md` old name — no references.
- **Single-digit `Part N §M` legacy references — six remaining defects**
  (§4.A–§4.F above). These are the last remaining stale references.

### 5.3 CD / OQ coverage — PASS

CD-1..CD-13 → AD-1..AD-13, all carried with decision/rationale/alternatives.
OQ-1..OQ-14 all resolved in Parts 3–10 or deferred in §13.1–§13.4.

### 5.4 Migration safety — PASS

Rollback plan §6.7, Procedure 5-R §6.5, eight-stage sentinel resumability
§6.8, `x-` in-place skip §6.1, pre-flight invariants §6.2–§6.3 all internally
consistent. Stage counts reconciled (eight migration / eleven init-project).

### 5.5 CI validation alignment — PASS (with B.2 carryover)

§5.11 Checks 6–9 specified; V-CI-01..V-CI-10 defined. B.2 (Codex
`description` CI check) unchanged; non-blocking per prior rounds.

### 5.6 README layout obligation — PASS

Part 7 §7.12 and Part 8 row 55 obligate README.md Repository Layout updates
in Phase 4.

### 5.7 BACKLOG accuracy — PASS

Part 8 row 64 tracks BD-044/045/046 resolution at v10.0 ship. §3.1
lines 513–515 notes BD-045 BACKLOG supersession.

### 5.8 Maintenance-docs consistency — PASS

V10-PREDESIGN.md supersession at Step 13 tracked. V9-DESIGN.md / V9-AUDIT
annotation obligations captured.

### 5.9 Stage count verification — PASS

| Subject | Required | Found | Status |
|---|---|---|---|
| Migration | "eight stages S0–S7" | §6.8 line 1814; Part 8 row 45 line 2613; Appendix A line 3390; table at 1820–1829 (8 rows) | **PASS** |
| init-project | "11 stages S0–S10" | §7.6 line 2170; Part 8 row 49 line 2622; Appendix A line 3390; table at 2173–2185 (11 rows) | **PASS** |

---

## 6. Recommended disposition

1. **Apply 4.A through 4.F before Step 13 approval.** Six one-line section-
   number replacements. All targets verified.
2. **Keep B.2 (Codex `description` validate-pack check) on the v10.x polish
   list** unless the pack chat prefers to land it with this pass.
3. **Keep 5.E (CD-9 redundancy) and 5.F (METHODOLOGY.md Part 7 heading
   verification) on the v10.x polish / Phase 3 input list.**
4. **Re-audit after fixes.** Specifically grep:
   - `grep -nE "Part [0-9]+ §[0-9]+\b" V10-DESIGN.md | grep -vE "§[0-9]+\.[0-9]+"`
     — expected zero matches after 4.A–4.F are applied.
   - Re-run the five Round 3 §8 checks (all currently PASS; should remain
     PASS).

After 4.A–4.F are applied, the document is ready for Step 13 approval. The
combined Round 1–Round 4 fix history will have cleared every Critical and
Functional finding; only the two prior-round Minor carryovers (B.2, 5.F) and
the one informational item (5.E) will remain open, all targeted for v10.x
polish or Phase 3 verification.

---

## 7. What the document got right (reconfirmed across all four rounds)

- Every CD (1–13) carried to AD (1–13) with decision / rationale /
  alternatives-rejected structure.
- Every OQ (1–14) resolved in Parts 3–10 or deferred in Parts 13.1–13.4
  with Phase-3/4 resolution targets.
- Trinity symmetry preserved through all BD-045 + BD-046 edits with one
  justified Codex formatting deviation.
- Stale-reference sweep plans (Part 4 §4.8, Part 8 §8.6) partition
  operational vs. annotate-only cleanly per V9 Lesson 5.
- Four new validate-pack checks (6–9) specified with test cases
  V-CI-01..V-CI-10.
- Migration safety: rollback, sentinel resumability (eight stages S0–S7),
  `x-` in-place skip, Procedure 5-R reconciliation all internally consistent.
- README.md Repository Layout obligation (Part 7 §7.12, Part 8 row 55) and
  BACKLOG resolution tracking (Part 8 row 64) captured.
- DN-1 through DN-4 fully applied; DN-1 per-language symmetry maintained
  after Round 2 regression fix.
- Part 1 v9.x compatibility statement + seven preservation bullets + four
  documented limitations preserve the v9.x contract.
- Part 6 §6.9 migration outline includes "What does NOT change from v9.3"
  companion.
- Every Part 9 CP cell cross-references a Part 10 test; §10.16 coverage
  summary complete.
- Stage counts reconciled across all surfaces (eight migration, eleven
  init-project).
- Appendix A design-requirement cross-reference clean (Round 1 F2 and
  Round 2 follow-ups all landed).
- Part 11 V9-lesson cross-references clean (Round 1 F3, Round 3 5.D fixed).
- Part 13 §13.5 CD/OQ mapping clean (Round 1 F4, Round 2 C.1 fixed).
- The five Round 3 §8 grep patterns all PASS.

---

## 8. Final verdict

**NOT APPROVED.** Six Functional cross-reference defects (§4.A–§4.F) remain
blocking per the audit-methodology severity scale inherited from Round 1
("cross-reference defects in the authoritative section lookup — leaving
them would leave the design doc unable to act as its own lookup reference
for Phase 3 implementation planning").

All six are one-line single-digit section-number corrections. They were not
caught in Rounds 1–3 because the prior grep sweeps used `§N.N` (decimal)
patterns, while the defects use `§N` (integer-only) legacy numbering. The
wider sweep required by Success Criterion 3 surfaced them.

Expected disposition after fix pass: document is approvable at Step 13 with
only B.2, 5.E, and 5.F remaining as v10.x polish / Phase 3 notes.

---

*End of Step 12 Re-Audit Report (Round 4).*
