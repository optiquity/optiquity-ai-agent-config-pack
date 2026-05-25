# AUDIT-PS-FULL-SESSION-REVIEWER.md

**Authored by:** pack-reviewer (full-session review pass for BD-191; technical-discipline-compliance focus)
**Date:** 2026-05-24
**Branch:** v11-dev
**HEAD at review:** `5534beb7078a95347a604d586aa819334ef8b943`
**Sponsoring BD:** BD-191 — Product Specialist (PS) requirements + v11.0/v11.1+ scope decision

**Scope:** Technical-discipline compliance review across 16 in-scope docs produced during the BD-191 sidecar session + 11 BD-190/191 commits. Companion pack-architect audit runs concurrently with focus on cross-doc design coherence (errors / omissions / conflicts) — this review is COMPLEMENTARY (artifact-mechanical layer) and does NOT duplicate the architect's surface.

**Discipline anchor:** Per pack memory `feedback_preliminary_triage_architect_challenge` (user-direction 2026-05-24), every disposition / scope verdict / capability shape / open architect decision in the session docs is PRELIMINARY. This review does NOT re-design preliminary positions; it checks that they are LABELED preliminary AND cite the discipline correctly. "I would have made a different design choice" is the downstream architect's lane, not the reviewer's.

---

## §1 — Read coverage

### §1.1 — In-scope docs read in full

All 16 docs read at full content level. Read order: INTAKE → REQUIREMENTS → HANDOFF → RESEARCH (skimmed for cross-ref validation) → PLANNING-PROCESS-INSIGHTS (skimmed for cross-ref validation) → 7 IMPL-REPORTs → 3 cross-feature touched portions.

| # | Doc | Lines | Coverage |
|---|---|---|---|
| 1 | `INTAKE-PS-V11.md` | 723 | Full content read |
| 2 | `REQUIREMENTS-PS-V11.md` | 1195 | Full content read |
| 3 | `HANDOFF-PS-ARCHITECT.md` | 227 | Full content read |
| 4 | `RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` | 985 | Cross-ref skim + closing-line check (anchor verification: §4.x / §8.x / §9.x) |
| 5 | `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` | 183 | Header + tail; mechanical-discipline check |
| 6 | `PLANNING-PROCESS-INSIGHTS-FROM-OT.md` | 638 | Header + anchor map (§3.x / §4.x / §5.x / §6.x / §7.x / §8.x) verified for cross-ref resolution |
| 7 | `IMPLEMENTATION-REPORT-PLANNING-PROCESS-INSIGHTS-FROM-OT.md` | n/a | Header + tail; mechanical-discipline check |
| 8 | `IMPLEMENTATION-REPORT-INTAKE-PS-V11-GOALS-INDEX.md` | 193 | Full content read |
| 9 | `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` | n/a | Header + tail + key verification commands |
| 10 | `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` | 376 | Full content read |
| 11 | `IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` | 271 | Full content read |
| 12 | `IMPLEMENTATION-REPORT-REQUIREMENTS-PS-V11.md` | 482 | Full content read |
| 13 | `IMPLEMENTATION-REPORT-HANDOFF-PS-ARCHITECT.md` | 227 | Full content read |
| 14 | `REQUIREMENTS-GROUPINGS-V11.md` (touched §5 amendments) | 1080 (full doc) | Touched portions read: Cap #1 mvp_priority reject (L132-141), Cap #7 SC7.7+SC7.8 (L345-365), Cap #13 SC13.22 (L634-642), Cap #17 SC17.10 (L837-839) |
| 15 | `HANDOFF-V11.1-ARCHITECT.md` (touched §5.1 / §5.2) | 158 (full doc) | Touched portions read: Open-architect-surfaces entries L53-54 |
| 16 | `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (touched §10.2) | 911 (full doc) | Touched portion read: §10.2 new-checks row L853 |

### §1.2 — Commits enumerated

11 BD-190/191 commits enumerated via `git log --grep="BD-19[01]" -20 v11-dev`:

| SHA | Subject | Files touched | Scope-keyword |
|---|---|---|---|
| `5534beb` | docs: v11 — BD-191 description no-orphans references (PM-only) | `pack-ops/BACKLOG.md` | PM-only |
| `2ca740d` | docs: v11 — BD-191 HANDOFF-PS-ARCHITECT.md entry-point (pack-only) | HANDOFF-PS-ARCHITECT.md + its IMPL-REPORT | pack-only |
| `e2a0c65` | docs: v11 — BD-191 REQUIREMENTS-PS-V11.md primary deliverable (pack-only) | REQUIREMENTS-PS-V11.md + its IMPL-REPORT | pack-only |
| `9756420` | docs: v11 — BD-191 walkthrough updates + Goal 19 + SC13 (pack-only) | INTAKE-PS-V11.md + WALKTHROUGH-UPDATES IMPL-REPORT + BACKLOG.md | pack-only |
| `7c699ae` | docs: v11 — BD-186 §5 + BD-191 §6 + Goal 18 amendments (pack-only) | 5 maintenance-docs + BACKLOG.md | pack-only |
| `a9d593f` | docs: v11 — BD-191 INTAKE §9 goals index + SC11 priorities (pack-only) | INTAKE-PS-V11.md + GOALS-INDEX IMPL-REPORT + BACKLOG.md | pack-only |
| `54a1531` | docs: v11 — OT planning-process synthesis (pre-triage, pack-only) | PLANNING-PROCESS-INSIGHTS + its IMPL-REPORT | pack-only |
| `3e15ea3` | docs: v11 — INTAKE-PS-V11.md §8 candidate capability list (pack-only) | INTAKE-PS-V11.md | pack-only |
| `32e78d2` | docs: v11 — BD-191 open (Product Specialist requirements, pack-only) | `pack-ops/BACKLOG.md` | pack-only |
| `337ac47` | fix: v11 — renumber BD-190 → BD-191 for PS (pack-only) | INTAKE-PS-V11.md + RESEARCH-LANDSCAPE IMPL-REPORT | pack-only |
| `a6423c3` | docs: v11 — INTAKE-PS-V11.md add quality-mitigation §7 (pack-only) | INTAKE-PS-V11.md | pack-only |

Pre-renumbering predecessors `17682c7` (PS landscape research) + `df64afc` (intake docs) also touched in-scope files but pre-date BD-191 numbering. Editorial note in INTAKE §1 acknowledges this preserved-as-historical-record framing — passes audit-trail discipline.

---

## §2 — Methodology

### §2.1 — Verification techniques applied

- **Closing-line check** — `grep -L "^End of " <file>` against each doc; cross-checked with `tail -2 <file>` for the canonical `End of <filename>.` form.
- **Cross-reference link integrity** — For each named section reference (`X.md §Y.Z`), opened the target file and verified the anchor exists. Tested: INTAKE §9.1 / §9.2 / §9.3 / §9.4 / §9.5 / §9.6; RESEARCH §4.8 / §8.4 / §8.6 / §9.1 / §9.2 / §9.3 / §9.4 / §9.5; PLANNING-PROCESS-INSIGHTS §3.x / §4.x / §5.x / §6.x / §7.x / §8.x; REQUIREMENTS-PS-V11 §10 numbered decisions; REQUIREMENTS-GROUPINGS Cap #7 SC7.8 / Cap #13 SC13.22 / Cap #17 SC17.10.
- **Pack memory rule citation accuracy** — For each cited rule (`feedback_preliminary_triage_architect_challenge` / `feedback_pattern_matching_out_of_context_antipattern` / `reference_pack_entry_type_semantics` / `feedback_user_prescriptive_authority` / `feedback_pack_chat_does_not_architect` / `feedback_planner_user_review_before_coder` / `feedback_deferral_is_scope_creep` / `feedback_review_fix_one_cycle` / `feedback_groupings_design_principles` / `feedback_no_solutions_in_agent_prompts` / `feedback_pack_chat_does_no_fixes`), verified the memory file exists in `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/` AND cross-checked whether the rule is also codified in pack-trinity `CLAUDE.md` `## Pack memory` section.
- **Naming conventions** — verified IMPL-REPORT-<doc>.md pattern + capability ID format (Cap #N vs Cap NN) + cluster names + BD numbering.
- **Section numbering integrity** — `grep -n "^## §\|^### §" <file>` for each doc; verified monotone order with no gaps.
- **Commit scope-keyword retrospective** — for each commit, ran `git show --name-only <SHA>` and verified the diff matches the declared scope-keyword per CLAUDE.md scope-keyword convention table.

### §2.2 — Severity classification

- **BLOCKER** — Cannot close BD-191 with this defect; would break audit trail, mis-cite discipline, or leak boundary.
- **MUST** — High-confidence finding; should be fixed unless explicit rationale to skip.
- **SHOULD** — Defensible finding; deferrable but worth flagging.
- **NIT** — Small finding; default-fix per pack memory `feedback_fix_all_review_findings`.
- **INFO** — Observation; not actionable but worth noting.

---

## §3 — BLOCKER findings

**None found.** No defects rise to the level of preventing BD-191 closure. The discipline framing is consistent across all 16 docs; cross-references resolve where they need to; the preliminary-triage-architect-challenge framing is applied uniformly.

---

## §4 — MUST findings

### MUST-1 — `INTAKE-PS-V11.md` §9.1 heading is stale: "Goal index (17 entries)" but the table contains 19 rows

**File / location:** `maintenance-docs/v11-research/INTAKE-PS-V11.md` line 547.

**Issue:** The §9.1 subsection heading reads `### §9.1 — Goal index (17 entries)` but the table beneath it now contains 19 rows (Goals 1-19). Goal 18 was added in commit `7c699ae` (BD-186 §5 + BD-191 §6 + Goal 18 amendments); Goal 19 was added in commit `9756420` (walkthrough updates + Goal 19). Both subsequent amendments added rows to the table but did not update the count in the heading.

**Classification:** Stale-cite / count-drift discipline. This is the kind of mechanical inconsistency that audit-trail discipline catches.

**Evidence:** `awk '/^### §9\.1/,/^### §9\.2 — Goal 16/' INTAKE-PS-V11.md | grep -c "^| [0-9]"` returns 19 (table rows). Heading: `grep -n "Goal index (17 entries)" INTAKE-PS-V11.md` → line 547 still says `(17 entries)`.

**Recommended-fix shape:** Pack Chat triages, then fix-coder edits the heading to `Goal index (19 entries)` (or removes the `(N entries)` clause entirely — both are valid). The discipline question is which: hard count or descriptive. The §9 section-intro already names "19 user-stated goals" implicitly via Goal-19 row presence; the count could be removed without information loss. Whichever shape Pack Chat / user prefer, the heading must be reconciled with the actual table size.

### MUST-2 — `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` missing closing-line `End of <filename>.`

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` end-of-file (line 183).

**Issue:** This IMPL-REPORT ends mid-prose with bullet item 4 (`Re-validation of fast-moving claims (§5 open questions) before architect-pass commits to specific positions.`) — no closing `End of ...` line, no `---` separator before EOF.

**Classification:** Mechanical convention drift. Other IMPL-REPORTs in this BD set (PLANNING-PROCESS-INSIGHTS IMPL-REPORT, INTAKE-PS-V11-GOALS-INDEX IMPL-REPORT, GROUPINGS-PS-BATCH-2 IMPL-REPORT, WALKTHROUGH-UPDATES IMPL-REPORT, REQUIREMENTS-PS-V11 IMPL-REPORT, HANDOFF-PS-ARCHITECT IMPL-REPORT) all carry the closing-line convention. The two outliers within this BD-191 batch are this IMPL-REPORT and `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` (see MUST-3). Pre-existing v11-research IMPL-REPORTs are inconsistent across the directory (47 missing out of 57 .md files), so the convention is not universal — but it IS the prevailing convention within the BD-191 batch.

**Recommended-fix shape:** Pack Chat triages whether to enforce the convention for this BD's docs; if yes, fix-coder appends `\n---\n\nEnd of IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md.\n` to both outliers (this one + MUST-3 target). If Pack Chat opts NOT to enforce (citing 47 pre-existing outliers in v11-research), document the decision so future reviewers don't re-flag the same item.

### MUST-3 — `IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` missing closing-line `End of <filename>.`

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-AMENDMENT-5-1.md` end-of-file (line 236).

**Issue:** This IMPL-REPORT ends mid-prose with the "Suggested rationale for the `(pack-only)` scope keyword: ..." sentence — no `End of ...` closing line. Sibling IMPL-REPORT `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` (the next-batch sibling at commit `7c699ae`) DOES carry the closing line at L375. The asymmetry within the same amendment-stream is the audit-trail concern.

**Classification:** Same mechanical-convention class as MUST-2.

**Recommended-fix shape:** Same as MUST-2 — Pack Chat decides whether to enforce; if yes, fix-coder appends closing line.

---

## §5 — SHOULD findings

### SHOULD-1 — REQUIREMENTS-PS-V11.md §3 C5 says methodology defaults are "LOCKED"; BD-191 SC8 says "NOT prescribed; defensible defaults"

**Files / locations:**
- `pack-ops/BACKLOG.md` BD-191 SC8 (BACKLOG.md line ~2926): "Methodology-position recommendations from §9.5 are surfaced as candidate defaults for architect consideration (NOT prescribed; defensible defaults)."
- `REQUIREMENTS-PS-V11.md` §3 framing (line 113): constraints C1-C7 are "LOCKED constraints (not preliminary at this level — they are direction-from-user) that bound architect design freedom."
- `REQUIREMENTS-PS-V11.md` §3.5 C5 (lines 158-164): "PS ships defensible methodology defaults per RESEARCH §9.5 ... Per-project override path supported."
- `HANDOFF-PS-ARCHITECT.md` §3 (line 78): "Methodology defensible defaults (LOCKED per RESEARCH §9.5..."

**Issue:** The user direction at BACKLOG SC8 says methodology defaults are CANDIDATES for architect consideration, NOT prescribed. The REQUIREMENTS-PS-V11.md elevates them to a LOCKED constraint (C5) and the HANDOFF-PS-ARCHITECT.md repeats the "LOCKED per RESEARCH §9.5" framing in §3. This creates ambiguity for the downstream architect: are methodology defaults locked positions they cannot challenge, or candidate positions they MUST challenge?

**Resolution path (informative — not reviewer-prescribed):** Two ways to reconcile. (a) C5 stays LOCKED in shape ("the pack SHIPS defensible defaults — not methodology-neutral") and the specific methodology values within the defaults table are architect-challengeable at LOW bar per Cap #5; (b) C5 is renamed to "Defensible defaults position" (locked) with the specific values explicitly framed as preliminary at LOW bar. Either reconciles BD-191 SC8's "NOT prescribed" framing with REQUIREMENTS C5's "LOCKED" framing.

**Classification:** Cross-doc consistency at design-decision level. This is closer to the architect-audit lane than to mechanical-discipline, but the language choice ("LOCKED" vs "candidate defaults") is a discipline-vocabulary inconsistency worth flagging.

**Recommended-fix shape:** Pack Chat triages: confirm with user whether C5 is intended as locked-shape-with-architect-tunable-values, or as candidate-defaults framing. Update REQUIREMENTS §3.5 + HANDOFF §3 wording to match the user's intent. The reviewer DOES NOT prescribe which framing is correct — both are defensible; the architect's challenge under `feedback_preliminary_triage_architect_challenge` is hampered if the doc says LOCKED while BACKLOG SC8 says NOT prescribed.

### SHOULD-2 — Pack memory `feedback_preliminary_triage_architect_challenge` is NEW (established 2026-05-24 in this BD-191 session) but NOT codified in pack-trinity `CLAUDE.md` `## Pack memory` section

**Files / locations:**
- Memory file: `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_preliminary_triage_architect_challenge.md` (exists; established 2026-05-24)
- Pack-trinity `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` `## Pack memory` section: does NOT contain a section for the preliminary-triage discipline
- Cited heavily across all BD-191 in-scope docs (REQUIREMENTS-PS-V11.md cites it 22 times; HANDOFF-PS-ARCHITECT.md cites it 8 times; INTAKE-PS-V11.md cites it 4 times)

**Issue:** Per the user-side `MEMORY.md` index discipline, "Trinity is the single source of truth; this file is a Claude-Code convenience cache. If this index disagrees with trinity, TRINITY WINS." The new rule established during the BD-191 sidecar is correctly captured in the user-side memory cache but has not been codified in the pack-trinity `CLAUDE.md` (or `AGENTS.md` / `GEMINI.md`). All 16 BD-191 docs cite the rule as if it were trinity-codified discipline.

**Companion gaps in same class:**
- `feedback_pattern_matching_out_of_context_antipattern` — exists in user-side memory cache; not in pack-trinity.
- `reference_pack_entry_type_semantics` — exists in user-side memory cache; not in pack-trinity.
- `feedback_user_prescriptive_authority` — exists in user-side memory cache; not in pack-trinity.
- `feedback_groupings_design_principles` — exists in user-side memory cache; not in pack-trinity.
- `feedback_pack_agent_rule_hallucination` — exists in user-side memory cache; presence in pack-trinity unverified.

**Classification:** Discipline-vocabulary gap. The rule citations resolve to memory-cache files but not to the canonical trinity. This is a PRE-EXISTING pack-state condition (not BD-191-introduced) but BD-191 surfaces it because BD-191 RELIES on these rules heavily.

**Recommended-fix shape:** Pack Chat surfaces to user; triages whether to (a) codify the cited memory-cache rules into pack-trinity `CLAUDE.md` `## Pack memory` as a separate BD/commit, OR (b) accept the cache-only state as designed (the memory cache is intentionally tier-1.5 per MEMORY.md preamble; codification to trinity may be deferred). If (a), the codification is itself a trinity edit subject to the trinity rule — all three files (CLAUDE/AGENTS/GEMINI) at pack-root need parallel edits. This finding may pre-exist BD-191's scope; surface to user before deciding.

### SHOULD-3 — `IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` opens with a header style inconsistent with the other 6 IMPL-REPORTs in the batch

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` lines 1-7.

**Issue:** This IMPL-REPORT opens with H1 `# Implementation Report — Research: Product Specialist Landscape` (uses em-dash form + colon, lowercased "Implementation Report"). Sibling IMPL-REPORTs use forms like `# IMPLEMENTATION-REPORT-<filename>.md` (file-name form) or `# IMPLEMENTATION-REPORT — <description>` (em-dash form, all-caps). The em-dash-with-colon form is non-standard for this batch.

Also: header metadata block uses `**Pair doc:**` / `**Agent:** pack-docs-researcher (sidecar session, BD-186 follow-up)` — the BD-186 reference at this commit `17682c7` was the pre-renumbering working assumption (the parent BD was "BD-190" not BD-186). The metadata `**Agent:** pack-docs-researcher (sidecar session, BD-186 follow-up)` is technically correct (research was BD-186 follow-up — groupings was BD-186; PS research was follow-on landscape work) but semantically reads as if PS landscape research is BD-186 scope, which it isn't.

**Classification:** Naming-convention drift + metadata-clarity. Inherited from pre-BD-191-renumbering work; preserved as-is per the audit-trail discipline (INTAKE §1 editorial note).

**Recommended-fix shape:** Pack Chat decides whether to (a) leave as-is per audit-trail discipline (this IMPL-REPORT pre-dates renumbering; commit `17682c7` is intentionally preserved), or (b) update the metadata to clarify the BD-191 association without rewriting history. Both are defensible. The h1 form normalization is a separate cosmetic choice.

### SHOULD-4 — `IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` cites pre-existing IMPL-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md line numbers that may have drifted

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-GROUPINGS-PS-BATCH-2-AMENDMENTS.md` lines 84-86 (and other post-edit line references throughout).

**Issue:** The IMPL-REPORT cites specific post-edit line numbers for INTAKE-PS-V11.md (e.g., "§9.4 heading: `INTAKE-PS-V11.md:525`" / "§9.4 final paragraph: `INTAKE-PS-V11.md:562`"). These line numbers were correct at write time (HEAD `a0b9870`) but DRIFTED after commit `9756420` added Goal 19 + §9.5 + walkthrough results (113 lines inserted). The IMPL-REPORT is a snapshot artifact — its line numbers should NOT be retroactively updated (audit-trail principle: archived IMPL-REPORTs are historical record), but readers using them today will find drift.

Per pack memory `feedback_architect_doc_vs_reality_reconciliation` (cached in CLAUDE.md `## Pack memory` § "Repo conventions"): the canonical pattern is `(file + symbol; never line numbers — line numbers drift)`. This IMPL-REPORT cites line numbers in violation of that pattern.

**Classification:** Pack-memory rule mis-application. IMPL-REPORTs are snapshot artifacts and may use line numbers for at-write-time evidence, but readers should be guided to use anchor-based navigation. Other IMPL-REPORTs in this BD set (e.g., WALKTHROUGH-UPDATES, HANDOFF-PS-ARCHITECT) similarly use line numbers in their verification commands AND symbol/anchor references — a mixed approach that is acceptable for snapshot artifacts.

**Recommended-fix shape:** No edit recommended for this snapshot IMPL-REPORT itself (preserve audit-trail). Surface as INFO for downstream IMPL-REPORT authoring: use anchor-based references (`§9.4 heading` / `Cap N6 Architect-bar line`) rather than line numbers, OR pair line numbers with anchors for forward-stability. This may already be discipline-aware; SHOULD-grade rather than MUST-grade because IMPL-REPORTs are snapshots.

---

## §6 — NIT findings

### NIT-1 — INTAKE-PS-V11.md §5 has subsection anchors `§9.1` through `§9.5` (research-doc-mirrored) that share numbering with §9 user-goals subsections

**File / location:** `maintenance-docs/v11-research/INTAKE-PS-V11.md` §5 (lines 185-228); §9 (lines 539+).

**Issue:** Section §5 of INTAKE ("Research output headlines (key §9 findings surfaced to user)") contains subsection headings `### §9.1 — Hard things to be careful of` through `### §9.5 — Defensible methodology positions`. These mirror RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md's §9.x subsections (correctly cited per §5's heading "key §9 findings"). Section §9 of INTAKE ("User-stated goals (consolidated index)") then has its OWN `### §9.1 — Goal index (17 entries)` through `### §9.6 — Mapping of goals to BD-191 success criteria` subsections.

The two anchor sets have IDENTICAL `### §9.x` markdown anchors with different semantic content. A reader using grep / anchor navigation tools may land at the wrong location. The IMPL-REPORTs (IMPL-REPORT-GROUPINGS-PS-BATCH-2 V5 verification command) and WALKTHROUGH-UPDATES IMPL-REPORT V1/V4 verification commands both surface this conflict in their grep outputs and note it as "pre-existing doc structure ... not introduced by this work".

**Classification:** Anchor-collision risk; pre-existing structural issue. Not a defect introduced by this BD; an inherited inconsistency that grew worse as INTAKE §9 was expanded.

**Recommended-fix shape:** Pack Chat decides whether to (a) rename §5's `§9.x` subsection headings to a distinct form (e.g., `### §5.1 — RESEARCH §9.1 hard-things-to-be-careful-of`) to break the anchor collision, OR (b) accept the collision as audit-trail framing per the editorial note (§5 mirrors RESEARCH's §9 structure intentionally). Option (a) eliminates the navigation hazard; option (b) preserves the framing-mirror. NIT-grade per pack memory `feedback_filename_uniqueness` (filename uniqueness heuristic) applied as anchor-uniqueness heuristic — not strict requirement.

### NIT-2 — REQUIREMENTS-PS-V11.md §2 references "19 user-stated goals" but the heading in INTAKE §9.1 still says "(17 entries)"

**File / location:** `REQUIREMENTS-PS-V11.md` §2 (line 57): "consolidated reference index of 19 user-stated goals captured verbatim in `INTAKE-PS-V11.md §9`."

**Issue:** The REQUIREMENTS doc correctly counts 19 goals (table at L63-84 has 19 rows). The INTAKE §9.1 heading mis-counts (see MUST-1). This is the downstream symptom of MUST-1: REQUIREMENTS is correct; INTAKE is stale.

**Classification:** Downstream symptom of MUST-1; tracked here for visibility but resolution belongs in MUST-1's fix.

**Recommended-fix shape:** Fix MUST-1; this NIT auto-closes.

### NIT-3 — `IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` files-changed table double-counts the IMPL-REPORT itself

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-INTAKE-PS-V11-WALKTHROUGH-UPDATES.md` lines 16 (and table at lines 251-253).

**Issue:** The header table at L13-17 says "Single file in scope; no other files edited" — but the report-itself is created by the coder. The "Files changed inventory" table at L251-253 correctly lists both the INTAKE edit AND the IMPL-REPORT-itself as new. Within-doc inconsistency: header says single-file; inventory table says two-files (one modified + one new). Standard self-report convention: IMPL-REPORTs ARE among the new-files-created by the coder (per all other IMPL-REPORTs in this batch).

**Classification:** Within-doc consistency NIT.

**Recommended-fix shape:** Adjust header to say "Single in-scope file edit (plus this IMPL-REPORT)" or remove "no other files" from L17. NIT-grade.

### NIT-4 — Commit `32e78d2` uses `(pack-only)` scope keyword when `(PM-only)` would be more precise

**File / location:** Commit `32e78d2` subject line: `docs: v11 — BD-191 open (Product Specialist requirements, pack-only)`. Touched files: only `pack-ops/BACKLOG.md`.

**Issue:** Per CLAUDE.md scope-keyword convention table, `pack-only` denies `project-template/` and `supporting-docs/` (which this commit satisfies — only touches `pack-ops/BACKLOG.md`). The `PM-only` keyword (per PACK-AGENTS.md PM-only list including BACKLOG.md) would be MORE precise. Both are valid CI Check 36 claims; `pack-only` is over-broad relative to the single-file scope. Comparable subsequent commit `5534beb` (also touches only BACKLOG.md) correctly uses `(PM-only)` — so this is an intra-batch inconsistency.

**Classification:** Scope-keyword precision NIT.

**Recommended-fix shape:** No retroactive commit-message edit recommended (git history rewrite is destructive per pack memory). Surface as discipline note for future BD-open commits: prefer `(PM-only)` when the commit touches only PM-only files. NIT-grade.

### NIT-5 — IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md does not name BD-191 explicitly in its metadata

**File / location:** `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` header L1-7.

**Issue:** This report was authored at commit `17682c7` (pre-renumbering, "BD-190" working assumption). Metadata says `**Agent:** pack-docs-researcher (sidecar session, BD-186 follow-up)`. After renumbering, the BD-191 association is implicit through cross-references but not explicit in this IMPL-REPORT's metadata.

**Classification:** Metadata-clarity NIT (also flagged in SHOULD-3).

**Recommended-fix shape:** Same as SHOULD-3. NIT severity preserved here for separate triage.

### NIT-6 — REQUIREMENTS-PS-V11.md §2 cross-cutting list states "Goals 1, 5, 7, 13, 16, 17, 18" but the same doc §1.2 implicitly elevates Goal 19 to cross-cutting via "PACK-PRIMARY first" framing

**File / location:** `REQUIREMENTS-PS-V11.md` §2 (lines 85-92): "Cross-cutting principles ... Goal 1 (CLIENT-SIDE ONLY) / Goal 5 / Goal 7 / Goal 13 / Goal 16 / Goal 17 / Goal 18".

**Issue:** Goal 19 (Human-readable PRD rendering) is framed in INTAKE §9.5 as "SECONDARY artifact derived from pack-primary"; in REQUIREMENTS §2 the cross-cutting list omits Goal 19. However REQUIREMENTS §8 ("Audience priority + human-readable rendering") elevates Goal 19's interaction with Goal 7 across multiple deliverables (N4 / N5 / N6 / N8). Whether Goal 19 should be in the cross-cutting list is a design-coherence question; the omission is defensible (Goal 19's mechanism is concentrated in Cap N8 + §8, not cross-cutting across all capabilities the way Goal 7 is). Worth flagging for cross-doc coherence audit.

**Classification:** Architect-coherence-lane finding; NIT under this reviewer's discipline-compliance pass.

**Recommended-fix shape:** Cross-reference to architect-audit; downstream architect can decide whether Goal 19 belongs in cross-cutting principles. NIT-grade for this reviewer.

---

## §7 — INFO observations

### INFO-1 — Closing-line convention is NOT uniform across `maintenance-docs/v11-research/`

**Observation:** Of 57 .md files in `maintenance-docs/v11-research/`, only 17 carry `End of <filename>.` closing lines (29% adoption). The convention IS adopted within the BD-191 batch (11 of 13 batch-authored .md files carry it; the 2 outliers are flagged in MUST-2 + MUST-3). Pre-existing v11-research docs are predominantly without closing lines.

**Action:** None required from this audit. Surface to Pack Chat as a separate discipline-decision: enforce closing-line convention across v11-research/ as a whole, OR scope the convention to specific doc categories (IMPL-REPORTs / authored-deliverables) and accept inconsistency elsewhere.

### INFO-2 — Pack memory rule citations use underscore form (e.g., `feedback_preliminary_triage_architect_challenge`)

**Observation:** Memory-cache filenames at `~/.claude/projects/.../memory/` use underscores (e.g., `feedback_preliminary_triage_architect_challenge.md`). User-side `MEMORY.md` index uses hyphens in display-name + underscores in file-link (e.g., `[Preliminary triage + architect-challenge discipline](feedback_preliminary_triage_architect_challenge.md)`). BD-191 docs cite the underscored file-name form, which matches the filesystem. PASS.

**Action:** None. Discipline-vocabulary is consistent within this BD's docs and resolves correctly to memory cache files.

### INFO-3 — IMPL-REPORTs cite pack-memory rule `feedback_groupings_design_principles` but this rule is itself preliminary (Goal 18 + Cap #7 SC7.8 user-approved 2026-05-24 same day as BD-191)

**Observation:** HANDOFF-PS-ARCHITECT.md §9 cites `feedback_groupings_design_principles` as authoritative locked groupings 5-core + C6 + C7 design principles at REQUIREMENTS-GROUPINGS-V11.md §1. SC7.8 (the Goal-18-side groupings-conversion-responsibility SC) was added 2026-05-24 — same date as BD-191 sidecar work. The "user-approved 2026-05-24" stamp lands on both surfaces simultaneously. The rule is authoritative per its memory-cache entry; the SC is preliminary per its in-doc disclaimer. Not contradictory but reader-confusing if not framed carefully.

**Action:** None. Surface for downstream architect awareness; the architect must distinguish "groupings design principles LOCKED" (rule) from "SC7.8 specific shape preliminary" (in-doc framing).

### INFO-4 — Cross-feature touched portions are correctly scoped (no out-of-scope edits found)

**Observation:** Per prompt scope, only §5 / §5.1 / §5.2 / §10.2 / Cap #7 SC7.8 / Cap #13 SC13.22 / Cap #17 SC17.10 / mvp_priority-reject sections of cross-feature docs (REQUIREMENTS-GROUPINGS / HANDOFF-V11.1-ARCHITECT / TOUCH-POINT-INVENTORY) were modified during BD-191. Verified via `git log --oneline -- <file>` on each cross-feature doc and read of the diffs at touched line ranges. No untouched-portion modifications. PASS.

**Action:** None.

### INFO-5 — BD numbering history correctly preserved per audit-trail discipline

**Observation:** INTAKE-PS-V11.md §1 editorial note explicitly preserves pre-renumbering commit messages (`17682c7`, `df64afc`, `a6423c3`) with their original "BD-190" text. Pack memory `reference_pack_backlog_structure` ("always read the live BACKLOG before assigning") was applied during the renumbering decision. Renumbering commit `337ac47` carries the right scope-keyword + correct file set. Audit-trail discipline preserved. PASS.

**Action:** None.

### INFO-6 — Commit-message format compliance is uniform across the 11 BD-190/191 commits

**Observation:** All 11 commits use the prescribed format `docs: vN — BD-NNN brief description (scope-keyword)` or `fix: vN — BD-NNN brief description (scope-keyword)`. The renumbering commit `337ac47` correctly uses `fix:` (per the CLAUDE.md approved suffix list for renumbering corrections). All N=11 satisfy CLAUDE.md commit-message-format conventions. PASS.

**Action:** None.

### INFO-7 — REQUIREMENTS-PS-V11.md is 1195 lines — substantially longer than the prompt's expected ~500-800 line guideline

**Observation:** IMPL-REPORT-REQUIREMENTS-PS-V11.md explicitly notes the length variance (482-line IMPL-REPORT acknowledges 1195 vs ~500-800 expected) and frames it as a quality outcome over prompt-guideline numeric. Per pack memory `feedback_chunk_long_outputs`, the coder appropriately chunked Writes (HEAD evidence supports — no Write-too-large error). The 1195-line length serves the architect-entry-point function well; the HANDOFF-PS-ARCHITECT.md at 227 lines provides the lightweight navigation layer per the deliberate two-tier design.

**Action:** None.

### INFO-8 — Section numbering is gap-free across all in-scope docs

**Observation:** Verified `grep -n "^## §\|^### §"` for each in-scope doc. All §N sections are monotonically numbered from §1 through their final § value. INTAKE §1-§10; REQUIREMENTS-PS-V11 §1-§11; HANDOFF-PS-ARCHITECT §1-§10; PLANNING-PROCESS-INSIGHTS §1-§8 (with §8 final); RESEARCH §1-§10. Subsection numbering is monotone within each section. PASS.

**Action:** None.

---

## §8 — Cross-cutting observations

### §8.1 — Preliminary-disclaimer discipline is CONSISTENTLY applied

The `Preliminary; subject to architect challenge at PS design pass` disclaimer (or its `v11.1+ groupings design pass` variant) appears uniformly across:
- REQUIREMENTS-PS-V11.md (22 occurrences: 1 doc-level + 21 per-capability)
- HANDOFF-PS-ARCHITECT.md (multi-instance: doc-level + §1 / §3 / §6 / §11.4 reinforcement)
- INTAKE-PS-V11.md (embedded in §9.4 Goal 18 + §9.5 Goal 19 statements; embedded in §8 §6 sub-decision results subsection + Walkthrough results subsection)
- REQUIREMENTS-GROUPINGS-V11.md (4 disclaimers on Cap #1 / Cap #7 SC7.7 / Cap #7 SC7.8 / Cap #17 SC17.10)
- HANDOFF-V11.1-ARCHITECT.md §5.2 architect-investigation entry

Discipline-compliance: PASS uniformly. The user's direction 2026-05-24 to apply preliminary-status framing to every triage decision is faithfully captured in all amendment surfaces.

### §8.2 — Architect-bar (LOW / HIGH) is CONSISTENTLY applied per pack memory tiered-bar guidance

Every per-capability entry in REQUIREMENTS-PS-V11.md §4 carries an explicit Architect bar (LOW or HIGH or LOW-with-HIGH-component). HANDOFF-PS-ARCHITECT.md §6 provides worked LOW vs HIGH examples mapped to specific capabilities. The boundary-with-existing-pack capabilities (#1 / #13 / #15 / N1 / N6 / #12 / #14 / #15) are correctly elevated to HIGH or LOW-with-HIGH-component per the rule's intent. PASS.

### §8.3 — Pack memory rule citations resolve to memory-cache files

All cited memory rule names (`feedback_preliminary_triage_architect_challenge` / `feedback_pattern_matching_out_of_context_antipattern` / `reference_pack_entry_type_semantics` / `feedback_user_prescriptive_authority` / `feedback_pack_chat_does_not_architect` / `feedback_planner_user_review_before_coder` / `feedback_deferral_is_scope_creep` / `feedback_review_fix_one_cycle` / `feedback_groupings_design_principles` / `feedback_no_solutions_in_agent_prompts` / `feedback_pack_chat_does_no_fixes`) resolve to existing memory-cache files. The cache-vs-trinity gap is captured in SHOULD-2 but the cited names themselves are correct.

### §8.4 — Cross-document reference links resolve

Verified cross-reference resolution for major surface pairs:
- REQUIREMENTS-PS-V11.md → INTAKE §9.x: §9.1 (index) / §9.2 (Goal 16) / §9.3 (Goal 17) / §9.4 (Goal 18) / §9.5 (Goal 19) all exist. PASS.
- REQUIREMENTS-PS-V11.md → RESEARCH §x.y: §4.8 (common-denominator PRD) / §8.4 (orthodoxy splits) / §8.6 (PRD-to-code traceability) / §9.1-§9.5 all exist. PASS.
- REQUIREMENTS-PS-V11.md → PLANNING-PROCESS-INSIGHTS §x.y: §3.1 (no-solutions) / §3.2 (anti-pillars) / §3.7 (seams) / §6.1 (capability additions) / §6.4 (7-item bar) / §7 (architect-investigation) / §8 (challenge questions) all exist. PASS.
- HANDOFF-PS-ARCHITECT.md → REQUIREMENTS-PS-V11.md §10 numbered decisions 1-30: verified at REQUIREMENTS lines 1084-1142. PASS.
- HANDOFF-PS-ARCHITECT.md → REQUIREMENTS-PS-V11.md §3.1-§3.7 C1-C7: verified. PASS.
- IMPL-REPORTs → REQUIREMENTS-PS-V11.md line numbers (verification-evidence): valid at write-time HEAD; may drift retroactively per SHOULD-4.

### §8.5 — Commit scope-keyword discipline is uniformly CI-Check-36-compliant

All 11 BD-190/191 commits' scope-keyword claims match their actual diffs:
- 4 commits scoped to `pack-ops/BACKLOG.md` only: 3 use `PM-only`, 1 uses `pack-only` (NIT-4 — pack-only over-broad but not wrong).
- 7 commits scoped to maintenance-docs/v11-research/ (some +BACKLOG.md): all use `pack-only`, all are valid (BACKLOG.md is in `pack-ops/`, which `pack-only` permits).
- No `project-template/` or `supporting-docs/` touches detected — `pack-only` keyword claims are CI-Check-36 sound.

### §8.6 — No trinity rule trigger fires for any in-scope file

The trinity files (CLAUDE.md / AGENTS.md / GEMINI.md at pack-root or project-template/) were NOT touched by any BD-190/191 commit. The trinity rule does not engage for this BD's scope. PASS.

### §8.7 — No manifest-regen trigger fires for any in-scope file

Per pack memory `feedback_manifest_regen_on_v11_surface`, the trigger fires only for paths under `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`. BD-190/191 commits touched `maintenance-docs/v11-research/` + `pack-ops/BACKLOG.md`. `pack-ops/BACKLOG.md` is in the trigger directory but is NOT a fixture-affecting file per the memory rule's "fixture-affecting paths today" list. No manifest regen required. PASS for all 11 commits.

### §8.8 — Sidecar audit-trail completeness

BD-191 entry in BACKLOG.md carries (a) INPUTS list (10 named source docs); (b) AUDIT-TRAIL list (7 named IMPL-REPORTs); (c) all 13 SCs with detailed prose. Cross-checked: every doc in the AUDIT-TRAIL list exists at the named path. Every doc in the INPUTS list exists. The sidecar audit-trail is complete per the "no-orphans" framing in the BD-191 description. PASS.

---

## §9 — Next steps for Pack Chat

### §9.1 — Triage ordering recommendation (reviewer-suggested; Pack Chat decides)

1. **MUST-1** (stale §9.1 heading count) — one-line fix; high audit-trail visibility; default FIX per `feedback_fix_all_review_findings`.
2. **MUST-2 + MUST-3** (closing-line on two IMPL-REPORTs) — two simple appends; Pack Chat decides whether to enforce the convention for the BD-191 batch or defer. If enforce: FIX both. If defer: document the decision so future reviewers don't re-flag.
3. **SHOULD-1** (LOCKED-vs-NOT-prescribed methodology defaults wording) — design-decision-shaped; user-discussion recommended before fixing. Resolution requires user adjudication, not reviewer prescription.
4. **SHOULD-2** (memory-cache rules not in pack-trinity) — surface to user; may pre-exist BD-191's scope; user decides whether to open a separate trinity-codification BD or accept the cache-tier framing.
5. **SHOULD-3 + NIT-5** (RESEARCH IMPL-REPORT metadata clarity) — same root cause; SHOULD-3 fix subsumes NIT-5. Pack Chat decides whether to update metadata or preserve audit-trail purity.
6. **SHOULD-4** (line-number drift in snapshot IMPL-REPORTs) — INFO/SHOULD-grade; no edit recommended but surface for future IMPL-REPORT authoring discipline.
7. **NIT-1 / NIT-2 / NIT-3 / NIT-4 / NIT-6** — default FIX per fix-all-findings unless explicit defer rationale (size / blocked / logical-fit per `feedback_deferral_is_scope_creep`).

### §9.2 — Discipline observations for next sidecar / batch

- The closing-line convention is INCONSISTENT in v11-research/ as a whole (29% adoption). If Pack Chat enforces it for BD-191 batch specifically, document the per-batch decision so the inconsistency doesn't propagate.
- The memory-cache-vs-trinity gap (SHOULD-2) is a pre-existing pack-state condition that BD-191 surfaces. This may warrant an explicit trinity-codification BD before downstream v11.x+ architecture work (cited rules need trinity-canonical status if architect/planner/coder MUST follow them).
- Line numbers in snapshot IMPL-REPORTs are stable at write-time but drift post-commit (SHOULD-4). The architect-doc-vs-reality reconciliation pattern in CLAUDE.md `## Pack memory` § "Repo conventions" prescribes file+symbol (not line numbers) — apply to future IMPL-REPORT authoring.

### §9.3 — BD-191 closure-readiness assessment

**No BLOCKER findings.** With MUST-1 fixed (stale heading) and Pack-Chat-decision on MUST-2 + MUST-3 (closing lines), the in-scope artifact set is discipline-compliant for BD-191 closure. SHOULD-1's resolution may be deferred to architect-pass (the architect would surface the LOCKED-vs-candidate ambiguity during their pass anyway per `feedback_preliminary_triage_architect_challenge`), or fixed now via user discussion. SHOULD-2 is pre-existing pack-state and should NOT block BD-191. NITs default-fix per discipline.

### §9.4 — Out-of-scope for this reviewer

Per the prompt's COMPLEMENTARY framing with the parallel pack-architect audit, the following are NOT this reviewer's lane and were intentionally left for the architect:
- Whether the 21-capability set is the right shape (architect-pass design challenge)
- Whether the 30 open architect decisions in §10 are the right surface enumeration (architect-pass design challenge)
- Whether Cap N8 (human-readable rendering) is correctly framed as architect-decided per §10 Decision #19 (architect-pass design challenge)
- Whether the LOW vs HIGH architect-bar assignment per capability is correctly tiered (architect-coherence audit)
- Whether INTAKE §7.5 (interview flow dynamics) correctly captures the user's intent (architect would re-investigate per `feedback_preliminary_triage_architect_challenge`)

If the parallel pack-architect audit surfaces overlapping findings with this review, the architect's lane takes precedence on design-coherence items; this reviewer's lane takes precedence on artifact-mechanical items.

---

End of AUDIT-PS-FULL-SESSION-REVIEWER.md.
