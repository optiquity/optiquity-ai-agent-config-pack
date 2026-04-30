# Step 12 Review Report — V10-DESIGN.md Independent Audit

*Reviewer: pack-reviewer (independent review session)*
*Date: 2026-04-21*
*Document under review: `maintenance-docs/V10-DESIGN.md` (3,364 lines, DRAFT — PENDING REVIEW)*
*Inputs: V10-PREDESIGN.md, V10-DESIGN-PROCESS-PLAN.md, step-12-reviewer-input.md (DN-1..DN-4), V9-DESIGN.md, V9-AUDIT-REPORT.md, CLAUDE.md, PACK-AGENTS.md, README.md*

---

## Summary of verdict

**Status: NOT APPROVED.** Blocking findings below must be resolved before
Step 13 approval. The document is substantially complete — every CD is
carried into Part 2 as an AD, every OQ is resolved or explicitly deferred,
and every V10-PREDESIGN design requirement is addressed. However, four
developer-note corrections (DN-1 through DN-4) are not yet applied, and
several cross-reference defects in Appendix A and Part 11 point at
sections that do not exist. Findings are grouped by severity below per
the audit-methodology scale.

| Severity | Count |
|---|---:|
| Critical (block approval) | 4 |
| Functional (must fix before approval) | 7 |
| Polish (may roll to v10.x) | 4 |

---

## What the document got right

Before the findings, confirmation of correctness on the high-stakes items:

- **Completeness (Part 2).** Every Candidate Decision CD-1 through CD-13
  in V10-PREDESIGN Part 2 is carried forward as AD-1 through AD-13 with
  decision, rationale, and rejected-alternatives structure matching the
  V9-DESIGN.md decisions 1–9 convention.
- **OQ resolution (Part 13 §13.5).** All 14 open questions are either
  resolved in Parts 3–10 or carried as deferred items in Part 13
  §§13.1–13.4 with explicit resolution targets. Deferred items are
  demonstrably non-blocking for v10.0.
- **Per-BD dedicated sections.** BD-045 has Part 3; BD-046 has Parts 4
  (prompts), 5 (custom agents), 6 (migration); BD-044 has Part 7. Each
  section explicitly references the other BDs' integration points
  (§3.10, §5.13, §6.11, §7.13).
- **Trinity rule compliance.** Part 3 §3.8, Part 8 §8.5 audit trinity
  symmetry. The only asymmetry (Codex plain-bullet vs. markdown-bold in
  auditor-architecture, Part 3 §3.7) is explicitly justified by the
  pre-existing TOML-embedded-string pattern in those files — this
  matches the exception carve-out in CLAUDE.md's trinity rule.
- **Stale-reference sweep (Part 4 §4.8, Part 8 §8.6).** The
  PROMPT-TEMPLATES.md stale-reference inventory is thorough and
  partitions into must-update operational docs vs. annotate-only
  historical records (V9 Lesson 5 explicitly applied).
- **CI validation (Part 5 §5.11, Part 8 §§8.2.6).** Four new
  validate-pack.py checks (6, 7, 8, 9) are specified with test cases in
  Part 10 §10.1 V-CI-01 through V-CI-10.
- **Migration safety (Part 6 §§6.1, 6.5, 6.7, 6.8).** Rollback plan,
  Procedure 5-R reconciliation, seven-stage sentinel resumability,
  `x-` in-place-skip preservation are all internally consistent.
- **README.md Repository Layout obligation (Part 7 §7.12, Part 8 row
  55).** The migration-guide naming convention and new files are
  surfaced to README.md.
- **BACKLOG.md BD resolution (Part 8 row 64).** BD-044/045/046 resolution
  at v10.0 ship is tracked.

---

## Critical findings (block approval)

### C1 — DN-1 not applied: "required" language for capabilities pattern

**Evidence.** "Required" / "required coding practices" appears 8 times in
Part 3 referring to the capabilities pattern:

- Line 462 §3.1 first principle: "LSP and capabilities are independent
  required practices."
- Line 463 §3.1: "both required coding practices, applied
  independently."
- Line 466 §3.1: "required regardless of whether the other is in use."
- Line 520 §3.2 trinity section text: "both required coding practices,
  applied independently."
- Line 528 §3.2 trinity section text: "required regardless of whether
  the other is in use."
- Line 561 §3.3 apple-architecture-core rule 11: "Capabilities and LSP
  are independent required practices; apply each on its own merits."
- Line 607 §3.4 python-best-practices rule 14: "Capabilities and LSP
  are independent required practices."
- Line 656 §3.5 future-language template N1: "Capabilities and LSP are
  independent required practices."
- Line 693 §3.6 architecture-review rule 14: "both must be present
  where each applies."
- Line 741 §3.7 auditor-architecture Claude/Gemini markdown bullet:
  "Capabilities and LSP are independent required practices — file
  capability findings under this bullet, not under LSP."
- Line 751 §3.7 auditor-architecture Codex bullet: same phrasing.
- Line 773 §3.9: "The formulation is never softened. The pattern is
  never presented as an LSP escape hatch. In every location it is a
  first-class proactive design tool."

DN-1 is **diametrically opposed** to §3.9's "never softened" language.
The capabilities pattern is a recommended best practice championed
proactively; not a mandated practice. LSP remains required.

**Required fix.**

1. Rewrite the LSP-vs-capabilities relationship text (lines 462–466,
   519–528, and the short-form paraphrase at line 773) to: LSP is a
   required coding practice; the capabilities pattern is a recommended
   best practice applied proactively during architecture. Absence of
   capabilities is a suggestion/finding, not a defect.
2. Update the architecture-review rules 14–17 (§3.6) to say the
   architecture-review skill *flags* capability absence as a
   recommendation/finding, not a failure.
3. Update the auditor-architecture scope bullet (§3.7) to say the agent
   *surfaces* capability-pattern absence as a suggestion, not a defect.
4. Update §3.9 itself — replace "never softened" with a statement of
   what IS required verbatim (LSP) and what is recommended (capabilities).
5. Per DN-1 closing sentence, add a one-line note in Part 3 §3.1 or
   Part 11 that the BD-045 BACKLOG entry's "required" language is
   superseded by this design decision, and will be updated when BD-045
   is resolved at v10.0 ship.

**Affected V10-DESIGN sections:** §3.1, §3.2, §3.3, §3.4, §3.5, §3.6,
§3.7, §3.9; Part 8 rows 1–9 captions reference the verbatim text and
will need to reflect the updated wording; Part 10 V-BD045-06 ("Each
uses BD-045 formulation verbatim or closely paraphrased; never softens
to 'escape hatch'") must be rewritten — the new pass condition is
"uses the LSP = required, capabilities = recommended formulation
consistently; never states capabilities is required."

### C2 — DN-2 not applied: PLATFORM-SKILLS.md four dimensions not supported

**Evidence.** PLATFORM-SKILLS.md defines four skill-selection dimensions
(Platform Targets, Languages, Component Roles, Communication Protocols).
The v10 design does not mention these dimensions in any of the three
locations where they need to be surfaced:

1. **Part 5 §5.1 clarifying questions** (line 1075, also Procedure 5.1
   step 2 at line 1272): clarifying questions ask about purpose, phase,
   read-only/write, tool requirements, variants, skills, routing —
   **nothing about which dimension the custom item covers.**
2. **Part 5 §5.2 `## Custom agents` column spec** (lines 1107–1120):
   columns are Agent, Purpose, Phase routed to, Tier 1 skills, Tier 2
   skills, Read/write mode. No Dimension column.
3. **Part 5 §5.2 `## Custom skills` column spec** (lines 1132–1142):
   columns are Skill, Description, Loaded by. No Dimension column.
4. **Part 5 §5.7 Procedure 5 outline** (lines 1272, 1291): identical
   omission — clarifying questions for 5.1 and 5.2 do not prompt for a
   dimension.

The detection scan (§5.8) does not classify by dimension, the
registration artifacts list (§5.9) does not verify dimension presence,
and the PM-CHAT.md additions (§5.10) do not reference the four
dimensions.

**Required fix.**

1. Add a Dimension column to both PLATFORM-SKILLS.md `## Custom agents`
   and `## Custom skills` section specs in §5.2, with allowed values
   drawn from the four pack dimensions plus a free-text Other fallback
   for future dimensions. Column semantics: "Which PLATFORM-SKILLS.md
   dimension this custom item extends."
2. Update the clarifying-question list in §5.1 and in Procedure 5.1
   step 2 (§5.7) to include: "Which PLATFORM-SKILLS.md dimension does
   this custom agent/skill extend — Platform Targets, Languages,
   Component Roles, or Communication Protocols?"
3. Update the prompt-template format (§4.5) and the per-agent exceptions
   table in PROMPT-AUTHORING.md (§4.3) to accept a Dimension value so
   the PM chat's prompt-generation workflow can propagate it.
4. Update §5.13 "Integration with other BDs" and Part 8 row 42 to
   specify that the pack-side PLATFORM-SKILLS.md template must preserve
   the four-dimension classification scheme when rendering the
   placeholder `## Custom agents` / `## Custom skills` sections (so the
   illustrative rows show the Dimension column).

**Affected V10-DESIGN sections:** §5.1, §5.2, §5.7, §5.9, §4.3, §4.5,
§8.2.3 row 42; and Part 10 V-PM5-01/02 must verify Dimension column
population.

### C3 — DN-3 not applied: Codex `name` AND `description` fields

**Evidence.** Codex agent files require both `name` and `description`
TOML fields; agents missing either are silently ignored
("malformed agent role definition"). The design mentions only `name =`:

- **AD-1 table row 2** (line 105): `Codex agent | .codex/agents/x-<name>.toml | TOML \`name = "x-<name>"\``
  — no `description` field shown in the Identifier-value column.
- **AD-2** (line 134): generic "Codex TOML with `developer_instructions`"
  — does not name `description` as required.
- **Part 5 §5.1 row 2** (line 1055): "`.codex/agents/x-<name>.toml` |
  AD-2 row: Codex pack agents" — indirect; no explicit `description`
  requirement surfaced.
- **Part 5 §5.9 Registered custom agent clause 2** (line 1402):
  "`.codex/agents/x-<name>.toml` exists with valid TOML
  (`name = "x-<name>"`)." — **only `name` listed.**

Grep for `description` in the document (lines 903, 1069, 3194, 3195,
3196) shows it appears only as:
- line 903 — a reserved-but-unused frontmatter key for prompts;
- line 1069 — "draft agent description" in a natural-language sense;
- lines 3194–3196 — commit-message format rules.

There is no reference in the design to Codex TOML `description` as a
required field for an agent file to be loaded.

**Required fix.**

1. Update AD-1 table row 2 Identifier-value column to list both
   fields: `TOML \`name = "x-<name>"\` + \`description = "..."\``.
2. Update AD-2 to enumerate the required Codex TOML fields: `name`,
   `description`, `developer_instructions` (and whichever others are in
   pack pack agents — verify against existing v9.3 `.codex/agents/*.toml`
   pack files).
3. Update Part 5 §5.1 artifact table Codex row to note "both `name` and
   `description` required" (with a pointer to AD-2).
4. Update Part 5 §5.9 Registered-custom-agent clause 2 to require
   **both** `name = "x-<name>"` AND a non-empty `description`. Missing
   `description` → Unregistered.
5. Update any worked example or pseudocode in Part 5 showing a Codex
   TOML file to include a `description = "..."` line.
6. Update validate-pack.py Check 8 or add a new check (§5.11, Part 10
   §10.1) that Codex agent TOML files have both fields non-empty.

**Affected V10-DESIGN sections:** AD-1, AD-2, §5.1, §5.9, §5.11, Part
10 V-CI-03 (or a new V-CI test), V-PM5-01.

### C4 — DN-4 not applied: no v9.x preservation statement

**Evidence.** Part 0 and Part 1 do not contain an explicit statement
that v10 preserves all v9.x functionality unless explicitly noted
otherwise.

- **Part 0 "How to use this document"** (lines 15–35) scopes the
  document's reading order and confirms coverage of CDs/OQs/DRs, but
  does not state v9.x preservation as a design principle.
- **Part 1 "Why v10 Exists"** (lines 40–82) explains the three problems
  v10 solves but does not say what v10 preserves.
- **No other section** in the document contains a "v9.x compatibility"
  or "no regression" statement.

The individual v9.x capabilities DN-4 enumerates are mostly covered
implicitly, but none is explicitly confirmed as preserved:

| DN-4 capability | Design coverage | Explicit preservation statement? |
|---|---|---|
| Developer choice of Claude Code / Claude Desktop / Codex / Gemini for PM chat | Part 9 §9.6 per-tool coverage table; Part 6 §6.9 all-four-surface prompt; Part 4 §4.1 token-budget table covers all four | No |
| Interchangeable Claude/Codex/Gemini per phase routing | §5.1 trinity routing-table additions; Part 11 L3 | No |
| PACK-FEEDBACK.md mechanism | Part 7 §7.8 skill-gap logging uses PACK-FEEDBACK.md | No |
| All v9.x agent roles (16) | §5.3 pack roster enumerates 16 v9.3 agents | No (implicit via roster) |
| Desktop Commander / filesystem MCP | Part 4 §4.1 RAG table; Part 6 §6.9 "Claude Desktop + filesystem MCP" | No |
| mcp-local-rag for large-file RAG | Part 4 §4.1 RAG table; METHODOLOGY.md freshness check retained per §4.7 | No |

**Required fix.**

1. Add a new subsection to Part 1 (or Part 0) titled **"v9.x
   compatibility"** with the exact statement: "v10 preserves all v9.x
   functionality unless explicitly noted otherwise. The following v9.x
   capabilities are preserved:" followed by the six bullets from DN-4.
2. For each capability, cross-reference the section where it is
   concretely preserved (§5.3 for agent roster, §9.6 for PM chat tool
   flexibility, §7.8 for PACK-FEEDBACK.md, §4.1 and §6.9 for RAG /
   Desktop, etc.).
3. Add a companion statement naming known per-tool limitations (Codex
   hooks only fire for Bash per Step 2 C-3; Claude Desktop without
   filesystem MCP requires manual file upload; Codex skill loading
   verification pending per §13.1). These are documented known
   limitations, not silent omissions.
4. Part 6 §6.9 migration guide outline should gain an explicit "What
   does NOT change from v9.3" section alongside the existing "What
   changed in v10" (§2 of the outline) so a developer reading only the
   migration guide also sees the preservation contract.

**Affected V10-DESIGN sections:** Part 1 (or Part 0), Part 6 §6.9
MIGRATION outline, Appendix A "PM chat tool flexibility" row.

---

## Functional findings (must fix before approval)

### F1 — AD-4 cross-reference to "AD-8 below" is wrong

**Location.** Part 2 AD-4 line 196: "The PM chat does **not** edit
`.codex/config.toml` — no per-agent registration entry exists in
documented Codex (AD-8 below)."

**Problem.** AD-8 is "Prompt templates reorganized into per-agent
files." It does not address Codex config.toml at all. The correct
resolution of Codex config.toml (OQ-2) is in Part 5 §5.4 and is
connected to AD-3 (PM chat is the creation mechanism).

**Fix.** Replace "(AD-8 below)" with "(Part 5 §5.4 resolves OQ-2)" or
"(see Part 5 §5.4)."

### F2 — Appendix A section references point at nonexistent sections

**Location.** Appendix A (lines 3316–3333) has four broken
cross-references:

1. Line 3324 "Resource considerations": `Part 5 §5.12 and §17.5
   (detection scan cost; PLATFORM-SKILLS/PM-CHAT sizing); Part 7 §13.7
   (init-project.sh runtime)`
   - Part 5 §5.12 is "Incremental testability and rollback" — NOT
     detection scan cost / sizing.
   - `§17.5` does not exist (the document has no Part 17; Part 5 tops
     out at §5.13).
   - `Part 7 §13.7` does not exist (Part 7 tops out at §7.13).
2. Line 3326 "Document access patterns": `Part 7 §13.2 (QUICKSTART.md
   as router, not procedure)` — §13.2 does not exist. Intended target
   appears to be Part 7 §7.9 (the three-path router).
3. Line 3328 "PM chat tool flexibility": `Part 7 §13.3 (init-project.sh
   end-of-run prompt works on all four surfaces)` — §13.3 does not
   exist. Intended target appears to be Part 7 §7.8 (skill-gap tracking
   and end-of-run PM chat prompt).
4. Line 3331 "Incremental testability": `Part 6 §6.8 (seven migration
   stages …)` — see F5 stage-count error.

**Fix.** Replace each broken reference with the correct in-document
section. The Resource-considerations row's "detection scan cost" and
"PLATFORM-SKILLS/PM-CHAT sizing" claims need genuine supporting
sections to point at, or the claim text should change — no section
currently quantifies detection-scan cost or document sizing in a way
that directly supports the "Resource considerations" design
requirement beyond Part 4 §4.1.

### F3 — Part 11 Lesson references point at nonexistent sections

**Location.** Part 11 (lines 3037–3136):

1. Line 3059 L1: "**Part 5 §3.2 single-path rationale for custom-file
   creation.**" — Part 5 has no §3.2; Part 5 sections are §5.1–§5.13.
   The single-path rationale is in AD-3 (Part 2). Intended target is
   likely AD-3 or a §5.X section.
2. Line 3080 L2: "**Part 7 §12.2** (via Part 7's reference to Step 2
   facts). All CLI-adjacent claims in init-project.sh design cite
   Step 2." — Part 7 has no §12.2 (§7.1–§7.13). Part 12 §12.2 exists
   but is about cross-BD coordination, not Step 2 CLI facts. There is
   no Part 7 section that specifically aggregates "all CLI-adjacent
   claims cite Step 2." The claim itself may not be accurate — the
   actual Step 2 citations in the design are concentrated in Part 2
   AD-1 (line 97) and Part 5 §§5.4, 5.6, 5.8.
3. Line 3089 L3: "**Part 3 §3.2, §3.7, §3.8.**" — these sections
   exist. Consistent. No change needed.

**Fix.** Rewrite L1 and L2 references to point at actual sections.
Suggested: L1 → "Part 2 AD-3 single-path rationale"; L2 → "Part 2
AD-1 (Codex hyphen rule from Step 2 smoke test), Part 5 §5.4 (OQ-2
per Step 2 C-1), Part 5 §5.8 (detection at PM-chat layer per Step 2
C-3)."

### F4 — Part 13 §13.5 CD-9 reference

**Location.** Line 3294: "CD-9 → AD-9 + Part 5 §5.1 row 4, §6.2".

**Problem.** Part 5 has no §6.2. Part 6 §6.2 is "Baseline — v9.3 only,"
which has nothing to do with CD-9 (custom-agent prompts live in the
prompts directory). Most likely intended reference is Part 5 §5.2
(Custom sections spec for PLATFORM-SKILLS.md) or §5.9 (registration
artifacts).

**Fix.** Verify intent and rewrite the section reference. Either
remove the `§6.2` trailing fragment or replace with the correct
§5.X target.

### F5 — Migration stage-count inconsistency (Part 6 §6.8; Part 8 row 45)

**Location.**

- Line 1757 Part 6 §6.8: "The migration is one logical operation
  decomposing into **seven** stages."
- Lines 1763–1772: table lists S0, S1, S2, S3, S4, S5, S6, S7 —
  **eight** rows, all labeled "Stage."
- Line 2555 Part 8 row 45: "seven stages S0–S7" — same error.
- Line 3331 Appendix A: "seven migration stages" — same error.

**Problem.** S0 is "Pre-flight." The sentinel convention in Part 6 §6.3
(line 1578: "write sentinel `stage-S0.done`") treats S0 as a stage.
The "seven" count is therefore either wrong (should be eight) or S0
needs to be relabeled as "Pre-flight" outside the numbered stage set
to justify the seven-count.

**Fix.** Either (a) change every "seven stages" to "eight stages" and
update Part 8 row 45 accordingly, or (b) relabel S0 as "Pre-flight"
and retain "seven stages S1–S7" — then Part 6 §6.3 sentinel path
should change from `stage-S0.done` to `preflight.done` to stay
consistent. Option (a) is the smaller edit.

### F6 — init-project stage-count inconsistency (Part 7 §7.6; Part 8 row 49)

**Location.**

- Line 2112 Part 7 §7.6: "Both paths share the same **10 stages**
  (S0–S10)."
- Lines 2115–2127: table lists S0 through S10 — **eleven** rows.
- Line 2564 Part 8 row 49: "10 stages S0–S10" — same error.

**Fix.** Same as F5 — either (a) "11 stages" or (b) call S0 "Detection
+ preview" and retain "10 stages S1–S10." Option (a) is the smaller
edit.

### F7 — Part 3 §3.9's "never softened" contract contradicts DN-1

**Location.** Lines 769–776 §3.9.

**Problem.** This section codifies the exact opposite of what DN-1
requires: it states the wording is "never softened" and "never
presented as an LSP escape hatch. In every location it is a first-class
proactive design tool."

The "first-class proactive design tool" framing is correct and should
stay. "Never softened" to "required regardless of whether the other is
in use" is what DN-1 wants changed. A rewrite is needed that
distinguishes:

- LSP: required, never softened, never an escape hatch.
- Capabilities pattern: recommended best practice, proactive design
  tool, not a mandate. Absence is a recommendation/finding, not a
  defect.

**Fix.** Rewrite §3.9 to say: "Wherever the drafts state the
relationship, LSP remains required. The capabilities pattern remains
recommended — not required — and is always presented as a first-class
proactive design tool rather than an escape hatch. The
recommended-not-required framing is never softened to 'required,' and
never exaggerated to 'mandatory.'"

---

## Polish findings (may roll to v10.x)

### P1 — Part 3 §3.1 first bullet quotes V10-PREDESIGN (not BD-045 BACKLOG)

**Location.** Lines 462–466 §3.1 first bullet cites "BD-045's exact
formulation." Cross-check whether the exact text is in the BD-045
BACKLOG entry or was introduced in V10-PREDESIGN. If BACKLOG, the C1
fix must not silently change it; if V10-PREDESIGN, note the origin.
Minor hygiene only.

### P2 — Part 6 §6.1 failure-mode row references "v10-predesign assumption"

**Location.** Line 1541: "`.codex/config.toml` has hand-written
`[agents.<name>]` entries (speculative v10-predesign assumption)".

Once the Codex-config-toml resolution is final (Part 5 §5.4), this row
could drop the "speculative v10-predesign assumption" qualifier — the
behavior is deterministic now.

### P3 — Part 5 §5.3 pack roster is hand-maintained

**Location.** Lines 1146–1179. The hardcoded roster in PM-CHAT.md is
the authoritative list, enforced by validate-pack.py Check 7. When
future versions add a pack agent, the roster must be updated in the
same commit. This is documented (line 1181) but the risk is real —
V9 Lesson 4 / L5 pattern. A note in §5.3 referencing V9 Lesson 4 would
strengthen the maintenance contract.

### P4 — Part 8 row 10 "design artifact" row

**Location.** Line 2473 Part 8 row 10 is labeled "design artifact —
Part 3 §3.5 template". This is not a file change in the pack repo for
v10.0 — it is a template preserved in V10-DESIGN.md for future use.
Consider moving it out of the touch-point inventory (which is meant
to enumerate files that change in v10.0) into a separate "Preserved
design-doc content" list, or mark it more clearly as non-change. Minor
clarity only.

---

## Verification sweep results

### Trinity rule integrity

- Part 3 §3.8 trinity symmetry audit: PASS.
- Part 8 §8.5 trinity-rule integrity audit across all v10 BD edits:
  PASS.
- The auditor-architecture Codex plain-bullet asymmetry is the only
  asymmetry and is justified explicitly. PASS.
- After DN-2 is applied, the PLATFORM-SKILLS.md Dimension column change
  does not affect trinity files (it is a non-trinity doc), so trinity
  integrity is preserved by the fix.

### Stale-reference sweep

- **PROMPT-TEMPLATES.md:** Part 4 §4.8 and Part 8 §8.6 exhaustively
  enumerate touch points. Grep through V10-DESIGN.md itself confirms
  every reference is either a legitimate reference to the v9.3
  artifact being migrated from (§6.4 diff source, §6.1 failure-mode
  row, §4.1 token budget, §4.3 line references for content extraction)
  or an entry in the sweep target list. No stale "PROMPT-TEMPLATES.md
  as current pack artifact" references. PASS.
- **`prompts/README.md` (old name):** Grep shows no lingering
  references. PASS.
- **Codex `config.toml` per-agent registration:** removed per Part 5
  §5.4. Part 4 touch-point row and Part 5 workflow sub-step explicitly
  retracted (line 2612). PASS.

### Cross-reference integrity

- FAIL on Appendix A (F2), Part 11 (F3), AD-4 (F1), Part 13 §13.5 CD-9
  (F4). Fixes above.
- Internal Part 6 §6.8 stage count (F5) and Part 7 §7.6 stage count
  (F6) inconsistencies flagged above.

### Part 8 (touch-point inventory) ↔ Parts 3–7

Spot-check: every file named in Parts 3–7 appears in Part 8, and every
Part 8 row traces to a design section (via the "Source" column). One
minor nit in P4 above. No file omitted.

### Part 11 V9-lesson mapping

- L1 references broken in one bullet (F3).
- L2 references broken in one bullet (F3).
- L3, L4, L5 references all land on real sections. PASS.
- The lesson claims themselves — that V10-DESIGN applies each V9
  lesson — hold up when the broken refs are repaired.

### Part 9 / Part 10 coverage

Every Part 9 CP cell cross-references a Part 10 test via the
`[V-M1-NN]` / `[V-M2-NN]` / `[V-M3-NN]` tags. Spot-check: V-M1-01,
V-M2-01, V-M3-01, V-PM5-01, V-X-PRESERVE-01 all defined. Coverage
summary §10.16 maps every Part 9 cell to a test group. PASS.

### Migration safety (Part 6 ↔ Part 10)

- Rollback plan §6.7 has rehearsal test V-M1-ROLLBACK (§10.3). PASS.
- Incremental testability §6.8 has V-INC-01..V-INC-09 (§10.14). PASS.
- `x-` preservation §6.1 has V-X-PRESERVE-01..03 (§10.11). PASS.
- Pre-flight invariant §6.2 "PROMPT-TEMPLATES.md exists" — path is
  `docs/pack/PROMPT-TEMPLATES.md` in project context, matching Part 8
  row 69 location. PASS.

### BACKLOG accuracy

Part 8 row 64 tracks BD-044/045/046 resolution at v10.0 ship. DN-1's
closing observation — "The BD-045 BACKLOG entry also uses 'required'
and should be noted as superseded by this design decision" — is not
yet captured in V10-DESIGN.md. Recommend adding a row or annotation
in Part 11 L4 (stale verification-checklist lesson) or Part 12 §12.4
(ship boundary) that the BD-045 BACKLOG entry's "required" language
will be revised at v10.0 ship when BD-045 is resolved. This is part of
the C1 fix.

---

## Recommended disposition

1. **Block approval until C1–C4 are applied.** All four are developer-
   instructed corrections.
2. **Require F1–F7 fixed in the same pass** before Step 13 approval.
   These are cross-reference defects in the authoritative section
   lookup — leaving them would leave the design doc unable to act as
   its own lookup reference for Phase 3 implementation planning.
3. **P1–P4 can defer to a v10.x polish pass** without blocking
   approval, but are logged here so they are not forgotten.
4. **Re-audit after fix.** After the pack chat applies the corrections
   and re-runs Step 12, verify specifically:
   - DN-1 replacement wording in all eight §3 locations and §3.9
     rewrite.
   - DN-2 Dimension column present in §5.2 both sections, dimension
     clarifying question in §5.1 and Procedure 5.1/5.2.
   - DN-3 `name` + `description` required stated in AD-1, AD-2,
     §5.1 Codex row, §5.9 clause 2. validate-pack.py check updated.
   - DN-4 explicit preservation statement in Part 1 (or Part 0);
     six-capability bullet list with cross-refs.
   - F1–F7 cross-references repaired and stage counts reconciled.

---

*End of Step 12 Review Report.*
