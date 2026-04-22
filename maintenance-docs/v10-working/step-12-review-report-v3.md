# Step 12 Re-Audit Report — V10-DESIGN.md (Round 3)

*Reviewer: pack-reviewer (independent re-audit session)*
*Date: 2026-04-21*
*Document under review: `maintenance-docs/V10-DESIGN.md` (3,423 lines, DRAFT — PENDING REVIEW)*
*Prior reviews: `step-12-review-report.md` (Round 1), `step-12-review-report-v2.md` (Round 2)*
*Developer notes: `step-12-reviewer-input.md` (DN-1..DN-4)*
*Inputs also consulted: V10-PREDESIGN.md, V10-DESIGN-PROCESS-PLAN.md, CLAUDE.md, PACK-AGENTS.md, README.md, BACKLOG.md*

---

## Verdict

**Status: NOT APPROVED — three Functional cross-reference defects remain.** All Round 1 findings (C1–C4, F1–F7) and all Round 2 findings (A, B.1, B.2, C.1, C.2) that were committed as in-scope for this pass are resolved. DN-1 through DN-4 are fully applied. Stage counts, trinity symmetry, CD→AD coverage, OQ resolution, and DN-compliance sweeps all pass.

However, a wider cross-reference sweep surfaced **eleven occurrences of stale `Part N §X.Y` references across six distinct defects** that point at section numbers that do not exist in the named Part. These are pre-existing assembly-pass artifacts that survived Rounds 1 and 2 (Round 1 swept Appendix A and Part 11 only; Round 2 spot-checked the round-1 locations and Appendix A only). By Round 1's own severity scale these are Functional defects (the design document cannot act as its own lookup reference with these refs in place). Each is a one-line edit.

| Severity | Count |
|---|---:|
| Critical (block approval) | 0 |
| Functional (must fix before approval) | 3 defects / 11 occurrences |
| Minor (non-blocking; should fix) | 3 |

A single targeted fix pass clears the remaining Functional defects. No Critical, no regression from fixes.

---

## 1. Round 1 findings (C1–C4, F1–F7) — verification matrix

All independently re-verified against line numbers in the current document.

### Critical

| ID | Subject | Status | Evidence |
|---|---|---|---|
| **C1** | DN-1 "required" sweep across §3 | **RESOLVED** | §3.1 line 506–515 LSP required / capabilities recommended + BACKLOG supersession note; §3.2 line 568–576 Relationship-to-LSP paragraph + opt-out clause; §3.3 line 608 "LSP is required; the capabilities pattern is a recommended best practice"; §3.4 line 655–656 same phrasing (Round 2 regression repaired); §3.5 line 703 same phrasing; §3.6 line 741 "LSP is required, capabilities are recommended" + "absence is a finding, not a defect"; §3.7 lines 790, 800 same phrasing in Claude/Gemini markdown and Codex plain-bullet; §3.9 lines 820–826 rewritten. **Grep of `required practice`/`required practices` against V10-DESIGN.md → zero matches.** |
| **C2** | DN-2 Dimension column + clarifying questions | **RESOLVED** | Dimension column present in `## Custom agents` (line 1157) and `## Custom skills` (line 1184). Column semantics paragraphs at 1166–1172 and 1193–1197 enumerate the four PLATFORM-SKILLS dimensions. Procedure 5.1 step 2 line 1324 and Procedure 5.2 step 2 line 1346 both ask for dimension. G-design artifact list line 1119 surfaces dimension. |
| **C3** | DN-3 Codex `name` + `description` | **RESOLVED** | AD-1 row 2 line 142 lists both inline with "Codex silently ignores agents missing either field"; AD-2 line 176–178 enumerates required fields; §5.1 row 2 line 1105 inline note "both `name` and `description` required" (Round 2 B.1 recommendation accepted into design); §5.9 clause 2 line 1458–1459 requires both. |
| **C4** | DN-4 v9.x preservation | **RESOLVED** | Part 1 `### v9.x compatibility` subsection lines 84–119 opens with "v10 preserves all v9.x functionality unless explicitly noted otherwise." Seven-bullet preservation list with cross-references to §5.1, §9.6, §5.6, §7.8, §5.3, §4.1, §4.7, §6.9. "Known per-tool limitations" lines 109–119 document four documented limitations. |

### Functional

| ID | Subject | Status | Evidence |
|---|---|---|---|
| **F1** | AD-4 "AD-8 below" → §5.4 | **RESOLVED** | Line 240: "(Part 5 §5.4 resolves OQ-2)". |
| **F2** | Appendix A broken refs | **RESOLVED** | Line 3383 Resource considerations → "Part 4 §4.1" and "Part 5 §5.8" (both exist); line 3385 Document access patterns → "Part 7 §7.9" (exists); line 3387 PM chat tool flexibility → "Part 7 §7.8" and "Part 1 §v9.x compatibility" (both exist); line 3390 Incremental testability → "eight migration stages S0–S7" and "eleven init-project.sh stages S0–S10" (consistent with Part 6 §6.8 and Part 7 §7.6). |
| **F3** | Part 11 L1/L2 broken refs | **RESOLVED** | L1 line 3117 → "Part 2 AD-3 single-path rationale for custom-file creation" (AD-3 exists line 195). L2 lines 3136–3140 → "Part 1 AD-1" (typo in line 3136: "Part 1 AD-1" should likely be "Part 2 AD-1" — see §5.A below), "Part 5 §5.4", "Part 5 §5.8" (all exist). |
| **F4** | Part 13 §13.5 CD-9 ref | **RESOLVED** | Line 3353 "CD-9 → AD-9 + Part 5 §5.1 row 4, §5.2". §5.1 row 4 (Custom prompt file) exists line 1107; §5.2 exists line 1140. |
| **F5** | Migration stage count | **RESOLVED** | Part 6 §6.8 line 1814 "eight stages (S0–S7)"; Part 8 row 45 line 2613 "eight stages S0–S7"; Appendix A line 3390 "eight migration stages S0–S7"; table at 1820–1829 lists 8 rows. Consistent. |
| **F6** | init-project stage count | **RESOLVED** | Part 7 §7.6 line 2170 "11 stages (S0–S10)"; Part 8 row 49 line 2622 "11 stages S0–S10"; Appendix A line 3390 "eleven init-project.sh stages S0–S10"; table at 2173–2185 lists 11 rows. Consistent. |
| **F7** | §3.9 "never softened" rewrite | **RESOLVED** | Lines 820–826: "LSP remains required. The capabilities pattern remains recommended — not required … The recommended-not-required framing is never softened to 'required,' and never exaggerated to 'mandatory.' Absence of capabilities is a recommendation/finding, not a defect." Matches DN-1 exactly. |

---

## 2. Round 2 findings (A, B.1, B.2, C.1, C.2) — verification matrix

| ID | Subject | Status | Evidence |
|---|---|---|---|
| **A** | §3.4 python rule 14 regression | **RESOLVED** | Lines 655–656 now read: "LSP is required; the capabilities pattern is a recommended best practice. Apply each on its own merits." Byte-symmetric with §3.3 rule 11 (line 608) and §3.5 template rule N1 (line 703). |
| **B.1** | §5.1 Codex row inline note | **RESOLVED** (accepted from minor to applied) | Line 1105 row reads: "AD-2 row: Codex pack agents (both `name` and `description` required; Codex silently ignores agents missing either)." Reader no longer has to chase AD-2 to see the both-required rule. |
| **B.2** | validate-pack.py check for Codex `description` | **NOT APPLIED** (minor; still non-blocking per round 2 disposition) | §5.11 still lists only Checks 6–9. Part 10 §10.1 V-CI-09 tests only that `auditor-architecture.toml` parses after BD-045 edits; no check asserts every `.codex/agents/*.toml` has non-empty `description`. Round 2 disposition marked this non-blocking because §5.9 catches gaps at project layer and the pack-side agents are already fixed. Status unchanged; recommend adding in v10.x polish. |
| **C.1** | OQ-7 cross-ref | **RESOLVED** | Line 3364 now reads "OQ-7 → AD-3 + Part 5 §5.8". Both targets exist. |
| **C.2** | §6.9 "What does NOT change" | **RESOLVED** | Line 1846 adds section 2a: "What does NOT change from v9.3 (pointer to Part 1 §v9.x compatibility — agent roles, skills, tool interchangeability, PACK-FEEDBACK, Desktop/CLI options all preserved)." Outline has 16 sections now instead of 15; numbering consistent. |

---

## 3. DN-1 through DN-4 — independent verification

### DN-1 — Capabilities as recommended best practice

- **Zero instances of "required" for capabilities.** Confirmed by `grep -nE "required practice|required practices"` → no matches. `grep -nE "independent required|Capabilities are required|required regardless"` → no matches. `grep -nE "never softened"` → one match, line 823, inside the "never softened to 'required'" framing — this is the intended DN-1 phrasing, not a regression.
- **LSP remains required.** Eleven locations state LSP is required (lines 506, 507, 568, 608, 655, 703, 741, 790, 800, 820). No softening of LSP anywhere.
- **Developer opt-out present.** §3.1 line 509 ("or the developer explicitly opts out, that is valid"); §3.2 line 575 ("If the capabilities pattern does not fit the project's architecture or the developer opts out, that is valid"); §3.9 line 826 ("The developer may opt out if the architecture does not support it naturally").
- **architecture-review flags as recommendation.** §3.6 rule 14 line 741: "absence of capabilities is a finding, not a defect." Rules 15–17 describe what to flag but don't call any absence a defect.
- **auditor-architecture surfaces as suggestion.** §3.7 lines 790 (Claude/Gemini markdown) and 800 (Codex plain-bullet): "LSP is required; capabilities are recommended — file capability findings under this bullet, not under LSP."
- **§3.9 rewritten.** See F7 above.
- **BD-045 BACKLOG supersession noted.** §3.1 lines 513–515: "The BD-045 BACKLOG entry's original 'required' language is superseded by this design decision and will be updated when BD-045 is resolved at v10.0 ship."
- **Per-language symmetry.** §3.3 rule 11 (line 608), §3.4 rule 14 (lines 655–656), §3.5 template rule N1 (line 703) — all three now read "LSP is required; the capabilities pattern is a recommended best practice. Apply each on its own merits." Byte-identical across the three.

**Status: RESOLVED.**

### DN-2 — Four-dimension support

- **Dimension column in both custom sections.** Confirmed lines 1157 and 1184.
- **Column semantics paragraphs enumerate all four dimensions.** Confirmed lines 1166–1172 (custom agents) and 1193–1197 (custom skills): "Platform Targets, Languages, Component Roles, or Communication Protocols."
- **Clarifying questions for Procedure 5.1 (custom agent).** Line 1324: "which PLATFORM-SKILLS.md dimension this agent extends (Platform Targets, Languages, Component Roles, or Communication Protocols)".
- **Clarifying questions for Procedure 5.2 (custom skill).** Line 1346: same dimension question reframed for skills.
- **G-design review artifact.** Line 1119: "PLATFORM-SKILLS.md dimension" included in G-design review bundle.
- **PM chat and detection-scan integration.** §5.9 registration artifacts (line 1452 onwards) and §5.10 PM-CHAT.md additions do not need dimension logic (the Dimension value lives in the PLATFORM-SKILLS row; it is not a separate registration signal).

**Status: RESOLVED.**

### DN-3 — Codex `name` and `description`

- **AD-1 table row 2.** Line 142: "TOML `name = \"x-<name>\"` + `description = \"...\"` (both required; Codex silently ignores agents missing either field)."
- **AD-2.** Lines 176–178 enumerate required fields: `name`, `description` (both required — Codex silently ignores agents missing either), `model`, `approval_policy`, `sandbox_mode`, `developer_instructions`.
- **§5.1 Codex artifact row.** Line 1105 with inline both-required note (B.1 resolved).
- **§5.9 Registered-custom-agent clause 2.** Lines 1458–1459: "`.codex/agents/x-<name>.toml` exists with valid TOML (`name = \"x-<name>\"` and non-empty `description`; both required)."
- **validate-pack.py check.** Not added (B.2 not applied; minor per Round 2 disposition).

**Status: RESOLVED** on the four named locations. B.2 remains minor (non-blocking).

### DN-4 — v9.x preservation

- **Part 1 "v9.x compatibility" subsection.** Lines 84–119, opening statement exact DN-4 sentence. Seven-bullet preservation list (six required by DN-4 plus an added "All v9.x skills (30)" bullet). Cross-references populated.
- **Six required bullets.** ✓ developer choice of PM chat tool; ✓ tool interchangeability; ✓ PACK-FEEDBACK mechanism; ✓ v9.x agent roles (16); ✓ Desktop Commander / filesystem MCP; ✓ mcp-local-rag for large-file RAG.
- **Known per-tool limitations.** Lines 109–119 document four limitations (Codex Bash-only hooks, Claude Desktop MCP optional, Codex `x-` skill loading pending, Gemini hook verification pending).
- **Part 6 §6.9 "What does NOT change" companion.** Line 1846 section 2a added (C.2 resolved).

**Status: RESOLVED.**

---

## 4. Completeness re-check

### CD coverage (1–13) — PASS

All 13 CDs from V10-PREDESIGN Part 2 are carried forward as AD-1..AD-13. Each entry retains decision / rationale / alternatives-rejected structure. Part 13 §13.5 maps every CD:

- CD-1→AD-1, CD-2→AD-2, CD-3+OQ-7→AD-3, CD-4→AD-4+§5.1, CD-5→AD-5+§6.1, CD-6→AD-6+§5.1, CD-7→AD-7+§5.2, CD-8→AD-8+Part 4, CD-9→AD-9+§5.1 row 4 and §5.2, CD-10→AD-10+Part 7, CD-11→AD-11+Part 3, CD-12→AD-12+Part 6, CD-13→AD-13+§6.2.

### OQ coverage (1–14) — PASS

- OQ-1→§5.3, OQ-2→§5.4, OQ-3→§6.4, OQ-4→§4.7, OQ-5→§7.1, OQ-6→V10-DESIGN-PROCESS-PLAN.md, OQ-7→AD-3+§5.8, OQ-8→§5.5, OQ-9→§4.4, OQ-10→Part 12, OQ-11→§4.5, OQ-12→§7.3, OQ-13→Part 3 (nine locations), OQ-14→Part 10.
- Four deferred items in Part 13 §§13.1–13.4 with explicit Phase 3/4 resolution targets and confirmation that none blocks v10.0.

### Appendix A — PASS on targets listed; see §5 below for typographical edge cases

Every V10-PREDESIGN Part 7 Design Requirement has at least one section reference. All nine rows were individually verified — cited section numbers all exist.

### Renumbering intent — PASS at design level

§3.3 renumbers apple-architecture-core 11–23 → 15–27; §3.4 renumbers python-best-practices 14–32 → 18–36; §3.6 renumbers architecture-review 14–15 → 18–19. Part 8 row 60 (line 2638) and Part 10 V-BD045-07 (line 3028) call for a renumbering sweep in Phase 4.

---

## 5. New findings — cross-reference defects not caught in prior rounds

These defects were not introduced by the fix pass; they are pre-existing assembly-pass artifacts that survived Rounds 1 and 2. Round 1's scope was Appendix A + Part 11 + a spot-check; Round 2 re-verified only the Round 1 locations. A document-wide `grep -nE "Part [0-9]+ §[0-9]+\.[0-9]+"` surfaces the following.

### 5.A — FUNCTIONAL — "Part 4 §2.3 / §2.1 / §2.2 / §1.2" (Part 4 uses §4.1–§4.8)

**Evidence.** Part 4 headings are §4.1 through §4.8 (lines 846, 893, 907, 926, 949, 995, 1027, 1058). The following references use non-existent `§2.3 / §2.1 / §2.2 / §1.2` numbering, likely legacy from an earlier draft organized as top-level Part 4 = §1/§2/§3/§4:

| Line | Text fragment | Likely intended target |
|---:|---|---|
| 318 | "The file list (Part 4 §2.3 for full detail):" | Part 4 §4.2 (CD-8 file list) |
| 343 | "it is an architect-agent prompt (Part 4 §2.1)" | Part 4 §4.2 (corrections enumerated there) |
| 346 | "(Part 4 §2.2)" | Part 4 §4.2 |
| 357 | "All 14 templates in the v9.3 monolith have destinations in the split (Part 4 §1.2)" | Part 4 §4.1 (Per-segment table has Destination column) |
| 1562 | "**Prompts:** Part 4 §2.3 file list (ten canonical files + PROMPT-AUTHORING.md)" | Part 4 §4.2 |
| 2181 | "`prompts/` (entire directory per Part 4 §2.3 — 10 files + PROMPT-AUTHORING.md)" | Part 4 §4.2 |

**Fix.** Replace each `§2.3` / `§2.1` / `§2.2` / `§1.2` with the correct `§4.2` (or `§4.1` for line 357). Six one-line edits.

**Severity rationale.** By Round 1's own standard for F-defects ("cross-reference defects in the authoritative section lookup — leaving them would leave the design doc unable to act as its own lookup reference for Phase 3 implementation planning"), these are Functional.

### 5.B — FUNCTIONAL — "Part 10 §3.1" (Part 10 uses §10.1–§10.16)

**Evidence.** Part 10 headings are §10.1 through §10.16 (lines 2881, 2898, 2921, 2927, 2935, 2945, 2957, 2974, 2983, 3000, 3010, 3018, 3030, 3044, 3061, 3074). Two references use non-existent `§3.1`:

| Line | Text fragment | Intended target |
|---:|---|---|
| 149 | "A new pack CI check (Part 10 §3.1 V-CI-05/06) enforces this." | Part 10 §10.1 (V-CI-05 at line 2891 and V-CI-06 at line 2892) |
| 1272 | "validate-pack.py Check 8 (§5.8 and Part 10 §3.1 V-CI-05) enforces." | Part 10 §10.1 |

**Fix.** Replace `§3.1` with `§10.1` in both lines. Two one-line edits.

### 5.C — FUNCTIONAL — "Part 7 §10" and "Part 5 §8.2" (neither section exists)

**Evidence.** Part 7 has §7.1–§7.13; Part 5 has §5.1–§5.13.

| Line | Text fragment | Likely intended target |
|---:|---|---|
| 432 | "One list shared by all three mechanisms; maintained at Part 5 §8.2." | Part 5 §5.8 (the seven directories are enumerated there) — or Part 8 §8.2 if the intent is "pack-repo touch-point inventory." §5.8 is the more likely intent given the prose. |
| 1509 | "Check 9 — BD-044 structure. Detailed in Part 7 §10." | Part 7 §7.13 (Integration with other BDs — Check 9 cross-ref). Part 8 row 59 (line 2638) points at Part 7 §7.13, which confirms intent. |
| 1909 | "Shared detection library: `scripts/lib/detect.sh` (Part 7 §10)." | Part 7 §7.2 (the shared-library section). |

**Fix.** Three one-line edits. `§8.2` → `§5.8`; the two `§10` → `§7.13` and `§7.2` respectively per intent.

### 5.D — Minor — Part 11 L2 leading-"Part 1" typo

**Evidence.** Line 3136 in L2 reads "**Part 1 AD-1 Codex hyphen rule.**" — AD-1 lives in Part 2 (line 129). Round 2 recorded L2 as RESOLVED pointing at "Part 2 AD-1" (line 3138), but the bullet *two lines above* at 3136 still reads "Part 1 AD-1." This is an internal inconsistency within L2 itself.

**Fix.** Change "Part 1" → "Part 2" at line 3136. One-character edit.

### 5.E — Minor — §5.1 CD-address line mentions CD-9 twice (redundancy only)

**Evidence.** Line 1090: "Addresses V10-PREDESIGN CD-1, CD-2, CD-3, CD-4, CD-6, CD-7, CD-9 (all confirmed in Part 2 ADs) and OQ-1, OQ-2, OQ-7, OQ-8." The "CD-9" appears here but §5.1 concretely addresses AD-4 (creation workflow) and AD-9 (custom-prompt location via row 4). Part 13 §13.5 line 3353 also points CD-9 to §5.1 row 4. Not wrong, just informational.

**Status:** Not a defect. Included for completeness.

### 5.F — Minor — Procedure-5 cross-reference to "METHODOLOGY.md Part 7"

**Evidence.** §5.2 (line 1151 and 1179) and §5.7 (line 1313) state Procedure 5 is added to "METHODOLOGY.md Part 7 ('BACKLOG and TODO Management')". The factual heading in METHODOLOGY.md is not verified in this review. If the actual heading differs, the design doc will guide Phase 4 to an incorrect insertion point. Not verified; flagged for Phase 3 implementation planning.

**Status:** Minor (Phase 3 input), non-blocking.

---

## 6. No-regression sweep

### Trinity rule integrity — PASS

- BD-045 trinity section text (§3.2) and anti-pattern bullet — byte-identical intent across CLAUDE/AGENTS/GEMINI; identical language stated at Part 3 §3.8 audit table (line 807–816) and Part 8 §8.5 audit (line 2700–2712).
- §3.7 auditor-architecture — Claude and Gemini markdown byte-identical; Codex plain-bullet semantically identical; formatting deviation justified by pre-existing TOML-embedded-string pattern (line 803–805).
- §5.6 routing-table additions — TRIO marked; content identical.
- §6.6 trinity merge splice — two splices run atomically within migration stage S5.
- §8.5 audit table — every BD-level trinity touch marked TRIO (rows 1/2/3, 7/8/9, 26/27/28, 39/40/41).
- PM-CHAT.md explicitly non-trinity at §5.10 line 1495 and Part 11 L3 line 3152.

**No new asymmetry introduced by any fix in this round.**

### Stale-reference sweep — PARTIAL PASS

- PROMPT-TEMPLATES.md sweep plan at Part 4 §4.8 and Part 8 §8.6 intact.
- Codex `config.toml` per-agent registration — removed per §5.4. Round 2 confirmed; no regression.
- `prompts/README.md` old name — no remaining references.
- `Part 4 §2.3` / `Part 10 §3.1` / `Part 7 §10` / `Part 5 §8.2` / `Part 1 AD-1 (L2)` — **NEW broken references surfaced** in §5.A–§5.D above. These are stale in the sense of "referring to sections that do not exist under the current heading structure."

### CI validation alignment — PASS (with B.2 note)

§5.11 Checks 6–9 specified; Part 10 §10.1 V-CI-01..V-CI-10 tests defined. Check 1 sanity after BD-045 renumbering covered by V-CI-08. No check for Codex `description` non-empty on every TOML (B.2 minor); covered elsewhere by §5.9 project-layer detection and by the pack-side fix that motivated DN-3.

### Migration safety — PASS

Rollback plan §6.7, Procedure 5-R reconciliation §6.5, eight-stage sentinel resumability §6.8, `x-` in-place skip §6.1, pre-flight invariants §6.2–§6.3 all internally consistent. Migration stage count (eight, S0–S7) consistent across §6.8, Part 8 row 45, Appendix A.

### README layout obligation — PASS

Part 7 §7.12 and Part 8 row 55 obligate README.md Repository Layout to gain `scripts/lib/`, `scripts/init-project.sh`, `scripts/migrate-v9-to-v10.sh`, `scripts/merge-*.py`, `SETUP-NEW.md`, `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md`, and the migration-guide naming convention. Execution deferred to Phase 4.

### BACKLOG accuracy — PASS

Part 8 row 64 (line 2647) tracks BD-044/045/046 resolution at v10.0 ship. §3.1 lines 513–515 notes BD-045 BACKLOG supersession. BACKLOG.md entries for BD-044 (line 804), BD-045 (line 907), BD-046 (line 1013) are the ones being resolved; no edit to BACKLOG happens until Step 13 ship, per V10-DESIGN-PROCESS-PLAN.

### Maintenance-docs consistency — PASS

V10-PREDESIGN.md supersession at Step 13 tracked (Part 8 row 63; §10.15; §12.4). V9-DESIGN.md and V9-AUDIT-REPORT.md annotation obligations captured (Part 8 rows 36–37). V9 Lesson 4 and Lesson 5 applied (Part 11 L4, L5).

---

## 7. Stage count verification (explicit per success criterion 7)

| Subject | Required | Found at | Status |
|---|---|---|---|
| Migration (eight, S0–S7) | "eight stages S0–S7" | §6.8 line 1814 "eight stages (S0–S7)"; Part 8 row 45 line 2613 "eight stages S0–S7"; Appendix A line 3390; table §6.8 rows S0..S7 = 8 | **PASS** |
| init-project (eleven, S0–S10) | "11 stages S0–S10" | §7.6 line 2170 "11 stages (S0–S10)"; Part 8 row 49 line 2622 "11 stages S0–S10"; Appendix A line 3390; table §7.6 rows S0..S10 = 11 | **PASS** |

---

## 8. Recommended disposition

1. **Apply §5.A (six edits), §5.B (two edits), §5.C (three edits), §5.D (one-char edit) before Step 13 approval.** Twelve small edits total; all are one-line section-number replacements. They collectively bring the document's cross-reference integrity up to the standard Round 1 required for Appendix A and Part 11.
2. **Keep §5.E and §5.F on the v10.x polish list.**
3. **Keep B.2 (Codex `description` validate-pack check) on the v10.x polish list** unless the pack chat prefers to land it with the cross-ref pass.
4. **Re-audit after fixes.** Specifically grep:
   - `grep -nE "Part 4 §[123]\.[0-9]+" V10-DESIGN.md` — expected zero matches.
   - `grep -n "Part 10 §3" V10-DESIGN.md` — expected zero matches.
   - `grep -n "Part 7 §10\b" V10-DESIGN.md` — expected zero matches.
   - `grep -n "Part 5 §8" V10-DESIGN.md` — expected zero matches.
   - `grep -n "Part 1 AD-" V10-DESIGN.md` — expected zero matches.

After these pass, the document is ready for Step 13 approval.

---

## 9. What the document got right (unchanged from prior rounds; reconfirmed)

- Every CD (1–13) carried to AD (1–13) with decision / rationale / alternatives structure.
- Every OQ (1–14) resolved in Parts 3–10 or deferred in Parts 13.1–13.4 with Phase-3/4 resolution targets.
- Trinity symmetry preserved through all BD-045 + BD-046 edits with one justified Codex formatting deviation.
- Stale-reference sweep plans (Part 4 §4.8, Part 8 §8.6) partition operational vs. annotate-only cleanly per V9 Lesson 5.
- Four new validate-pack checks (6–9) specified with test cases V-CI-01..V-CI-10.
- Migration safety: rollback, sentinel resumability (eight stages S0–S7), `x-` in-place skip, Procedure 5-R reconciliation all internally consistent.
- README.md Repository Layout obligation (Part 7 §7.12, Part 8 row 55) and BACKLOG resolution tracking (Part 8 row 64) both captured.
- DN-1 through DN-4 fully applied; DN-1 per-language symmetry restored after Round 2 regression fix.
- Part 1 v9.x compatibility statement + seven preservation bullets + four documented limitations preserve the v9.x contract.
- Part 6 §6.9 migration outline now includes "What does NOT change from v9.3" companion.
- Every Part 9 CP cell cross-references a Part 10 test; Coverage summary §10.16 maps every cell group.
- Stage counts reconciled across all surfaces (eight migration, eleven init-project).

---

*End of Step 12 Re-Audit Report (Round 3).*
