# REVIEW — RESEARCH-PER-ENTRY-SPLIT-ADDENDUM.md (second-pass)

**Reviewer:** pack-architect (primary v11-dev chat)
**Date:** 2026-05-13
**Subject:** `maintenance-docs/v11-research/RESEARCH-PER-ENTRY-SPLIT-ADDENDUM.md` (562 lines, sidecar chat docs-researcher follow-up output, 2026-05-13)
**Predecessor review:** `maintenance-docs/v11-implementation/REVIEW-RESEARCH-PER-ENTRY-SPLIT.md` (this reviewer's first-pass review of the original 1,048-line research document)
**Purpose:** Second-pass review of the addendum the docs-researcher produced in response to the first-pass review's gaps, comments, and open questions. Closure check + new-concern surface + scope-creep audit + factual spot-check + architect-prompt guard-rail re-evaluation.
**Scope:** read-only. No design proposals. No edits to the addendum or the original research. No design choices made on behalf of the architect.

---

## 0. Executive summary

The addendum is **complete, disciplined, and on-target**. It addresses every prior-review tightening suggestion (§3.1–§3.7) and every prior-review factual question (§4.1.1–§4.1.5) with file:line citations, no proposals, and no scope creep. The §10 finding (IMPLEMENTATION-PLAN.md is `## §`-section organized, not `## Phase`-organized — 8 H2 sections, 34 BD entries, typical 15–30 lines per BD) is a substantive correction to one of the assumed mental models that was implicit in the original research's §3 OT framing.

Closure status (12 prior-review items):
- Tightening suggestions §3.1–§3.7 (7 items): **all CLOSED.**
- Factual questions §4.1.1–§4.1.5 (5 items): **all CLOSED.**
- Gaps A / B / C from prior-review §0 executive summary (rolled up from §3.6 / §3.5 / §3.4 + §2.5 / §2.7 / §2.9): **all CLOSED.**
- Over-emphases A / B from prior-review §0 (§1 reading-order density; §3 OT depth): **A CLOSED via the §1 reading-order pointer; B CLOSED via the §2 architect-orientation note + §3 compressed-alternative drop-in.**
- Architect-overreach signals §5.4 (1–6): not in scope of the addendum (those go to the architect's prompt, not to the research). **Status unchanged; addendum does not affect them.**
- Architect prompt guard rails §5.5: **one amendment recommended** (see §5 of this review) reflecting the §10 mental-model correction.

Factual spot-check (10+ claims sampled; every one verified clean):
- V3.3-DELTA §6.4 heading line correction (360, not 361) — **verified.** `### §6.4` at line 360; `### §6.5` at line 371.
- V3.1-DELTA §3 / §4 line ranges (180–255) — **verified.** `## §3` at line 180; `## §4` at line 256.
- Pack `## Resolved` H2 single-occurrence claim (line 2248 only) — **verified.** Single grep hit.
- CHANGELOG `**Scope X**` 3-bucket count, all in v11 block — **verified.** Lines 12, 43, 124; v11 H2 spans lines 8–268.
- IMPLEMENTATION-PLAN.md 8 H2 sections + 34 BD entries — **verified.** `grep -n '^## '` returns 8 matches at the addendum-cited lines; `grep -cE '^\*\*BD-'` returns 34.
- migrator-core.sh post-dispatch hook at line 222 — **verified clean.** Lines 217–225 carry the `if declare -F migrator_post_dispatch_hook >/dev/null 2>&1; then` block at line 222 exactly.
- migrate-v10-to-v11.sh hook body at lines 134–149 — **verified clean.** Function definition at line 134; `_v10_to_v11_rename_implementation_plan` call at line 144; closing brace at line 149.
- Maintainability principle §3.2 heading at line 274 — **verified.** Heading reads exactly `### 3.2 Structural signals — any one triggers an architect pass`.
- Pack-startup `Read BACKLOG.md in full` at .claude/.codex/.gemini directives — **verified clean.** Claude line 19; Codex line 19; Gemini commands TOML line 16; all three directives match the addendum's quoted wording byte-for-byte.
- OT STATUS.md is 139 lines, 6 H2s — **verified.** `wc -l` returns 139; `grep -n '^# \|^## '` returns 1 H1 + 6 H2 at the addendum-cited line numbers.

**Recommendation:** **APPROVE-FOR-ARCHITECT** with one minor amendment to the prior review's §5.5 guard-rail set (reflecting the §10 mental-model correction — see §5 below). The architect can proceed with the addendum + original research + amended guard-rail set as the complete pre-architect input.

---

## 1. Closure check — every prior-review item mapped

### 1.1 Tightening suggestions (prior review §3.1–§3.7)

| Prior-review item | Addendum section | Closure status | Notes |
|---|---|---|---|
| §3.1 — Add §1 reading-order pointer (4 anchor citations) | §1 (lines 20–39) | **CLOSED** | Names exactly the four anchors the prior review suggested. Includes byte-precise V3.3-DELTA off-by-one correction (360 not 361), which is a reviewer-level helpful catch the prior review didn't make. |
| §3.2 — Add §3 architect orientation note ("OT data is cross-check, not load-bearing") | §2 (lines 43–48) | **CLOSED** | Drop-in note matches the prior review's recommended wording almost verbatim. |
| §3.3 — Trim §3 detail (compressed alternative) | §3 (lines 52–124) | **CLOSED** | Provides a drop-in replacement block that preserves the load-bearing phase-task structure (verbatim per the prior review's "should stay" instruction) while collapsing the OT IMPLEMENTATION_PLAN.md H2 listing and OT CHANGELOG.md sample to one-sentence + line-range pointers. Architect can substitute or not — addendum does not edit the original research, which is correct restraint. |
| §3.4 — Add §5 BD-104 ordering paragraph (no resolution proposed) | §4 (lines 128–148) | **CLOSED** | States the temporal collision factually, names BD-104's Batch 12 placement at `EXECUTION-PLAN-V11.0.md:265`, names the migrator hook body location at `scripts/migrate-v10-to-v11.sh:134-149` and the framework gate at `scripts/lib/migrator-core.sh:222`. **Does not propose a resolution** (correct — that's the architect's call). Strong addition relative to the prior-review request. |
| §3.5 — Add §5 maintainability principle citation | §5 (lines 151–182) | **CLOSED** | Cites the principle's §3.2 heading line (274) and quotes signals 4 (lines 285–287), 5 (lines 288–294), 6 (lines 295–297), and 8 (lines 301–304) verbatim with exact line ranges. Closes prior-review §2.5 Gap B exactly. |
| §3.6 — Restructure §6 to surface the read-shape change | §6 (lines 186–256) | **CLOSED** | Enumerates the surface across pack-side (PACK-CHAT.md table, .claude/.codex/.gemini pack-startup) and project-side (PM-CHAT.md table, project-template/skills/pm-startup + per-CLI mirrors + .gemini commands TOML) with file:line citations and ≤ 3-line quotes per surface. Each surface is annotated "This wording reads the file as a single unit" — exactly the characterization the prior review asked for. |
| §3.7 — Compress §8 function inventory by shape | §7 (lines 260–288) | **CLOSED** | Three-bucket summary per function (reads-as-unit / reads-as-stream / writes-whole-file) for both forward and reverse. The "reads as a stream of entries" bucket is correctly empty in both directions today — useful negative evidence the architect can build on. |

**All 7 tightening suggestions closed.**

### 1.2 Factual questions (prior review §4.1.1–§4.1.5)

| Prior-review question | Addendum section | Closure status | Answer |
|---|---|---|---|
| §4.1.1 — Pack `## Resolved — vN` H2 count | §8 (lines 292–301) | **CLOSED** | Exactly 1 (the v8 one at line 2248). Confirmed one-off historical artifact, not recurring pattern. |
| §4.1.2 — CHANGELOG `**Scope X**` bucket count + per-version distribution | §9 (lines 305–342) | **CLOSED** | 3 scope buckets, all in v11 block (lines 12, 43, 124). Versions v1–v10 have zero scope buckets. Per-version breakdown table provided. Confirms scope-bucket pattern is v11-only innovation. |
| §4.1.3 — IMPLEMENTATION-PLAN.md per-phase / per-task line distribution | §10 (lines 346–384) | **CLOSED + CORRECTION** | The file is **not phase-organized** — it is `## §`-section organized (8 H2 sections), with `### §N.M` H3 sub-sections inside the large §1 (13 sub-sections) and §2 (7 sub-sections). 34 BD entries; typical BD-entry block 15–30 lines (BD-060 = 20, BD-063 = 19, BD-088 = 29, BD-085 = 19). **This is a substantive mental-model correction — see §2 below.** |
| §4.1.4 — `.gemini/` references to entry files | §11 (lines 388–435) | **CLOSED** | Pack-root: 8 matches across 5 files. Project-template: 15 matches across 5 files. Trinity-coverage gap closed. Only `commands/pm-startup.toml:76` references IMPLEMENTATION-PLAN.md by name. |
| §4.1.5 — OT STATUS.md shape | §12 (lines 439–487) | **CLOSED** | 139 lines, 6 H2 dashboard rubrics (Current Phase / Phase Completion / Active Backlog / Key Metrics / Next Actions / How to Update This File). **Per-section structure, NOT per-phase or per-task.** Architect can keep STATUS shape consistent with no decomposition pressure (which §9 of the original research already declared out of scope). |

**All 5 factual questions closed.**

### 1.3 Gaps A / B / C and over-emphases A / B (prior review §0)

| Item | Closure | Where addressed in addendum |
|---|---|---|
| Gap A — pack-product surface impact under-enumerated | **CLOSED** | §6 enumerates the read-shape change surface end to end, both pack-side and project-side. |
| Gap B — maintainability principle not cited | **CLOSED** | §5 cites the principle's §3.2 with verbatim signal text and exact line ranges. |
| Gap C — BD-104 collision window not made explicit | **CLOSED** | §4 states the temporal collision factually with three-citation evidence (EXECUTION-PLAN line 265, migrator-core line 222, migrate-v10-to-v11 lines 134–149). |
| Over-emphasis A — §1 citation grid density | **CLOSED** | §1 of the addendum is the 5-line "start-here" pointer the prior review asked for. |
| Over-emphasis B — §3 OT depth | **CLOSED** | §2 + §3 deliver the architect orientation note + the compressed-§3 drop-in. The original §3 stays in the research file (correct — addendum does not edit), and the architect can use the compressed alternative if they prefer. |

**All gaps and over-emphases closed.**

### 1.4 Architect-overreach signals (prior review §5.4) — informational

The prior review's §5.4 named six signals in the original research that an architect could misread as license to expand scope. None of those signals were addressed by the addendum, which is correct — they are guard-rail material for the architect's prompt, not research-pass material. The §5.4 enumeration stands; see §5 of this review for the one amendment recommended in light of §10.

---

## 2. New concerns surfaced by the addendum

### 2.1 §10 mental-model correction — IMPLEMENTATION-PLAN.md is §-section organized, not phase-organized

**The finding.** Addendum §10 establishes that `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` is organized as `## §0` … `## §7` (8 H2 sections), with `### §N.M` H3 sub-sections inside the large §1 (13 sub-sections, BD-060..BD-083 cluster) and §2 (7 sub-sections, BD-084..BD-093 cluster). BD entries inside each H3 use `**BD-NNN — <title>**` bold headers, with typical entry size 15–30 lines.

**What this corrects.** The original research §3 (OT IMPLEMENTATION_PLAN.md as `## Phase NN` organized) created an implicit assumption that the *pack-side* IMPLEMENTATION-PLAN.md might also be phase-organized — making "decompose by phase" feel like a natural symmetric decomposition unit across both surfaces. The §10 finding shows pack-side IMPLEMENTATION-PLAN.md has **no phases** at all; the natural decomposition unit candidates are `## §`-section, `### §N.M` sub-section, or `**BD-NNN**` entry — not `## Phase NN`.

This is exactly the kind of subtle integration-point miss the prior review's §2 was meant to surface, and the addendum has done so without prompting (the prior review §4.1.3 only asked for line distribution; the docs-researcher discovered the structural-shape mismatch in the course of answering and reported it as a corrective finding). Good docs-researcher discipline.

**Effect on prior-review §4.2 design tensions.** This finding does not abolish any of the §4.2 design tensions; it sharpens tension §4.2.1 ("Does per-entry decomposition apply uniformly to all three streams, or per-stream?"). Specifically:

- The pack-side IMPLEMENTATION-PLAN.md decomposition candidates collapse to: per-§ section (8 entries), per-§N.M sub-section (~20 entries), per-BD entry (34 entries). **None of these are phase-shaped.**
- The OT-side IMPLEMENTATION_PLAN.md is `## Phase NN` shaped (per §3 of the original research and the compressed §3 in the addendum).
- The pack-side BACKLOG.md is per-BD-NNN shaped (per §2 of the original research).
- The OT-side BACKLOG.md is per-TD-NNN shaped, partitioned by `## Phase NN` (per the original §3 / addendum compressed §3).

So the per-stream variability is now sharpened: pack-side has zero phase concept; OT-side has phase concept; the architect must decide whether the pack-side decomposition unit is `## §`, `### §N.M`, or `**BD-NNN**`, and whether to align with OT-side `## Phase NN` (asymmetry the design must justify) or differ (asymmetry the design must justify).

**This is not a new design tension — it is a *concretization* of an existing one (§4.2.1 from the prior review).** No prior-review item is invalidated; one item gains precision.

**Effect on §4.2.6 ("Does decomposition propagate to project-template?").** Sharpened similarly: project-template/docs/project/IMPLEMENTATION_PLAN.md is the OT-shaped (phase-organized) target; the pack-side decomposition unit cannot directly mirror because pack-side has no phases. The architect must defend the pack/project decomposition asymmetry explicitly if they decompose differently.

### 2.2 §11 finding — `commands/pm-startup.toml:76` is the only `.gemini/` IMPLEMENTATION-PLAN.md reference

**The finding.** Addendum §11 confirms only one Gemini surface references IMPLEMENTATION-PLAN.md by name (project-template, not pack-root). Pack-root .gemini/ has zero IMPLEMENTATION-PLAN.md references (consistent with pack repo not having an IMPLEMENTATION-PLAN.md until the v11-research one).

**Why this matters.** It confirms that any pack-side IMPLEMENTATION-PLAN.md decomposition has zero pack-root .gemini/ surface to update — the read-shape change for IMPLEMENTATION-PLAN.md is project-template only. The architect can scope the IMPLEMENTATION-PLAN.md decomposition's pack-startup surface change accordingly. This is a load-bearing scope-narrowing fact.

**No new design tension.** This narrows tension §4.2.3 ("Is the monolithic file abolished or retained as a generated mirror?") for the IMPLEMENTATION-PLAN.md case specifically — the file is consumed by exactly one Gemini surface in project-template + the equivalents in .claude/.codex (per addendum §6). The mirror-vs-replace decision has a smaller blast radius for IMPLEMENTATION-PLAN than for BACKLOG.md.

### 2.3 §12 finding — OT STATUS.md is 139 lines, 6 dashboard H2s, no per-phase / per-task structure

**The finding.** OT STATUS.md is a per-section dashboard with 6 H2s (Current Phase / Phase Completion / Active Backlog / Key Metrics / Next Actions / How to Update This File), where Phase Completion is itself a single table listing all phases. There is no per-phase H2 or per-task H2.

**Effect on the architect's design.** STATUS.md was already declared out of scope per original research §9. The §12 confirmation eliminates the "STATUS-row-per-phase and IMPLEMENTATION-PLAN-phase-per-file are correlated decompositions" speculation the prior review §4.1.5 raised. STATUS.md is a flat dashboard; per-entry decomposition does not apply to it; the architect can keep STATUS shape unchanged. No new tension; one speculative tension dissolved.

### 2.4 No NEW design tensions introduced by the addendum

I checked each of the prior-review §4.2 design tensions (1–7) against the addendum's findings:

- §4.2.1 (uniform vs per-stream decomposition) — sharpened by §10 (see 2.1 above); not invalidated.
- §4.2.2 (where the per-entry tree lives in the repo) — unchanged; addendum surfaces no new candidate locations.
- §4.2.3 (monolithic abolished vs generated mirror) — narrowed by §11 (see 2.2 above); IMPLEMENTATION-PLAN scope is smaller than BACKLOG/CHANGELOG scope.
- §4.2.4 (composition with tracker mode) — unchanged; addendum §7 confirms tracker functions read/write at file granularity, not entry granularity, but this was already known.
- §4.2.5 (BACKLOG-vs-CLAUDE.md "no Resolved section" rule) — answered by §8 (1 occurrence is one-off, not recurring); the architect can treat the rule as effectively true and the v8 H2 as historical residue.
- §4.2.6 (propagation to project-template) — sharpened by §10 (see 2.1 above) and §11 (see 2.2 above).
- §4.2.7 (customization-preserve class) — unchanged; addendum does not touch customization-preserve.

**Net.** No new design tensions. Two existing tensions (§4.2.1, §4.2.6) sharpened by the §10 + §11 findings. One speculative tension (§4.1.5 borderline-question) dissolved by §12.

---

## 3. Scope-creep / focus-drift audit

The addendum is a docs-researcher follow-up; per the parent's stated constraints (lines 12–17: "fact-only, file:line citations everywhere, pack/project boundary preserved, V3.x cited not analyzed"), it should remain fact-finding with zero design proposals.

**Section-by-section scope check:**

| Addendum section | Content type | Scope OK? |
|---|---|---|
| §1 — Reading-order pointer | Citation list with verified line ranges | YES — fact-finding |
| §2 — §3 architect orientation note | Single-paragraph fact statement (drop-in for original §3 top) | YES — fact-finding |
| §3 — Compressed §3 alternative | Drop-in replacement block of factual material | YES — fact-finding (presented as drop-in, not as edit; the architect chooses whether to use it) |
| §4 — BD-104 ordering paragraph | Three-citation factual statement of temporal collision; **explicitly does not propose a resolution** | YES — fact-finding |
| §5 — Maintainability principle citation | Direct quotes of §3.2 signals 4/5/6/8 with line ranges; concluding sentence "Per-entry decomposition is a structural change implicating signals 4 …, 5 …, 6 …, and 8 …" — this is restating principle-implication, not proposing design | YES — borderline-but-OK; the implication is the principle's, not the docs-researcher's |
| §6 — Read-shape change surface enumeration | File:line citations + ≤ 3-line quotes + per-quote characterization "This wording reads the file as a single unit" | YES — fact-finding; the characterization is observational, not prescriptive |
| §7 — Compressed §8 function summary | Three-bucket categorization of existing functions by read/write shape | YES — fact-finding categorization |
| §8 — Pack-side `## Resolved` count | Single grep result | YES — fact-finding |
| §9 — CHANGELOG scope-bucket distribution | grep results + per-version table | YES — fact-finding |
| §10 — IMPLEMENTATION-PLAN.md size distribution | grep + line-range table + per-§ BD distribution | YES — fact-finding (the "structural-shape mismatch" finding is a reported observation, not a design proposal) |
| §11 — `.gemini/` references | grep results + per-file annotations | YES — fact-finding |
| §12 — OT STATUS.md shape | wc / grep / structural enumeration | YES — fact-finding |
| §13 — Read-record | Reproducibility log | YES — required hygiene |

**§5 borderline observation.** The closing sentence of §5 ("Per-entry decomposition is a structural change implicating signals 4 …, 5 …, 6 …, and 8 …") leans toward analysis. It is, however, a *direct restatement* of what the principle's §3.2 says when applied to the prior-review-named change class — the signals quoted verbatim above force exactly this conclusion. The docs-researcher is not proposing anything; they are stating the principle's literal implication. This is acceptable because:
1. The closing sentence does not say "the design should…" or "the architect must…" — both of those would be design territory.
2. The closing sentence is symmetric to the original research's §5 customization-preserve framing ("BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN are unclassified → fall to generic → text-dispatch") — that, too, was a principle-implication restatement and the prior review did not flag it as scope creep.

**Net scope finding:** zero scope creep. Zero design proposals. The addendum holds the docs-researcher discipline cleanly.

---

## 4. Factual accuracy spot-check

The handoff already flagged the V3.3-DELTA §6.4 off-by-one correction (360 not 361). The addendum is unusually precise about line numbers, and several claims invite verification. I sampled 10 claims (the prompt asks for at least 3); every one verified clean.

| # | Addendum claim | Source | Verification result |
|---|---|---|---|
| 1 | V3.3-DELTA §6.4 heading at line 360, §6.5 at line 371 (correction from prior review's 361–370) | `ARCHITECTURE-V3.3-DELTA.md` | **VERIFIED.** `grep -n "^### §6.4\|^### §6.5"` returns `360:### §6.4 Identifier scheme summary` and `371:### §6.5 D-18 carrier matrix extension`. Off-by-one correction is correct. |
| 2 | V3.1-DELTA §3 at line 180; §4 at line 256 | `ARCHITECTURE-V3.1-DELTA.md` | **VERIFIED.** `grep -n "^## §3 \|^## §4"` returns `180:## §3 Decision: §4.2 BACKLOG format drift in reverse migration — picked A2` and `256:## §4 Cross-impact check`. |
| 3 | Pack `## Resolved` H2 = 1 occurrence at line 2248 | `BACKLOG.md` | **VERIFIED.** `grep -n "^## Resolved"` returns single hit `2248:## Resolved — v8 (March 2026)`. |
| 4 | CHANGELOG `**Scope` = 3 hits at lines 12 / 43 / 124 | `CHANGELOG.md` | **VERIFIED.** `grep -nE '^\*\*Scope'` returns exactly the three claimed lines with the claimed text (Scope A / B / C). |
| 5 | CHANGELOG version-block boundaries (11 H2s, v1..v11 at the addendum-cited lines) | `CHANGELOG.md` | **VERIFIED.** `grep -n '^## '` returns 11 H2s; line numbers (8, 269, 421, 465, 621, 641, 660, 676, 691, 705, 723) match the addendum's table exactly. v11 spans 8–268, so all three Scope buckets at 12/43/124 fall inside the v11 block as claimed. |
| 6 | IMPLEMENTATION-PLAN.md 8 H2 sections at the addendum-cited lines | `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` | **VERIFIED.** `grep -n '^## '` returns 8 H2s at lines 3, 22, 545, 819, 942, 1028, 1052, 1085 — matches the addendum's table line-for-line. |
| 7 | IMPLEMENTATION-PLAN.md 34 BD entries | same file | **VERIFIED.** `grep -cE '^\*\*BD-'` returns 34. |
| 8 | IMPLEMENTATION-PLAN.md §1 has 13 H3 sub-sections | same file | **VERIFIED.** `grep -nE '^### §1\.'` returns 13 hits (§1.1 through §1.13). First BD inside §1 at line 26 (BD-060) — matches addendum's "first BD at line 26." |
| 9 | migrator-core.sh post-dispatch hook gate at line 222 | `scripts/lib/migrator-core.sh` | **VERIFIED.** `sed -n '217,225p'` shows the `if declare -F migrator_post_dispatch_hook >/dev/null 2>&1; then` line at exactly line 222. |
| 10 | migrate-v10-to-v11.sh hook body at lines 134–149 with `_v10_to_v11_rename_implementation_plan` call at line 144 | `scripts/migrate-v10-to-v11.sh` | **VERIFIED.** Function definition opens at line 134; `_v10_to_v11_rename_implementation_plan` call at line 144; closing brace at line 149. |
| 11 (bonus) | Maintainability principle §3.2 heading at line 274 | `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` | **VERIFIED.** `sed -n '274p'` returns `### 3.2 Structural signals — any one triggers an architect pass`. |
| 12 (bonus) | OT STATUS.md = 139 lines, 6 H2s at the addendum-cited lines | `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md` | **VERIFIED.** `wc -l` returns 139; `grep -n '^# \|^## '` returns 1 H1 + 6 H2s at lines 1, 7, 14, 80, 106, 117, 128 — matches the addendum's enumeration line-for-line. |
| 13 (bonus) | `.claude/skills/pack-startup/SKILL.md:19` reads `Read \`BACKLOG.md\` in full.` (and same at .codex line 19, .gemini commands TOML line 16) | three pack-startup surfaces | **VERIFIED.** Direct grep returns all three lines with the exact wording. |

**Factual accuracy: 13/13 PASS.** Every spot-checked claim verified clean against the source. The docs-researcher's evidence discipline is consistent with — and arguably more precise than — the original research's.

**One non-defect note.** The addendum's §10 BD-entry size sample (`BD-085 spans lines 601–619 (19 lines)`) sits inside §1 (which the addendum says ends at line 544). I checked: BD-085 at line 601 is inside §2 (which spans 545–818), not §1. The addendum text correctly attributes BD-085 to §2 in the per-section breakdown ("§2 (Scope B BDs, lines 545–818): 7 H3 sub-sections (§2.1..§2.7); BD entries BD-084..BD-093 cluster"). No defect; just confirming the apparent §1/§2 boundary is consistent.

---

## 5. Architect-prompt guard rails — re-evaluation

The prior review's §5.5 produced six paste-ready guard rails for the sidecar's architect prompt. With the addendum in hand, each guard rail still holds. **One amendment is recommended** to reflect the §10 mental-model correction.

### 5.1 Existing guard rails — still complete?

| Prior-review §5.5 guard rail (paraphrased) | Still complete? |
|---|---|
| 1. Output is one architecture doc; no edits to other files. | YES — unchanged. |
| 2. Do not change the format of any existing entry; v10 BACKLOG grammar is byte-additive. | YES — unchanged. The addendum's §3 compressed alternative + §10 BD-entry-size sampling do not alter the guard rail. |
| 3. Do not propose edits to PM-only files. | YES — unchanged. |
| 4. Maintainability principle §3.2 applies; defend each structural signal explicitly. | YES — strengthened. The addendum §5 quotes signals 4/5/6/8 verbatim, so the architect can be told "see addendum §5 for the verbatim signal text" and skip a context switch. |
| 5. BD-119 framework contract is frozen for v11.0; extending it requires a structural-change defense. | YES — unchanged. |
| 6. Sequencing into EXECUTION-PLAN-V11.0.md Batches 7–10 + Batch 12 is the primary chat's planner concern; design must be sequencing-agnostic with respect to those batches; flag constraints, do not pre-resolve them. | YES — unchanged. The addendum §4 makes the BD-104 collision factually explicit (a strengthening), but the guard rail's "flag constraints, do not pre-resolve" wording stays correct. |

### 5.2 Recommended new guard rail (one) — pack vs project decomposition asymmetry

**Trigger.** Addendum §10 establishes that the pack-side IMPLEMENTATION-PLAN.md is `## §`-section organized (8 H2s; 34 BD entries; 13 H3 sub-sections in §1; 7 in §2). Addendum §3 (drop-in compressed alternative) confirms the OT-side IMPLEMENTATION_PLAN.md is `## Phase NN` organized (per the architect's already-known mental model). Addendum §11 confirms the only Gemini surface that names IMPLEMENTATION-PLAN.md is `project-template/.gemini/commands/pm-startup.toml:76`.

**Risk if no guard rail added.** An architect, reading the addendum, may assume per-entry decomposition can use the same unit on both sides ("entries everywhere"). It cannot — pack side has zero phases, OT side has 28+ phases. Decomposing pack-side IMPLEMENTATION-PLAN.md by `## §` section produces 8 files; decomposing OT-side by `## Phase NN` produces 28+ files. These are different shapes. The architect must either (a) defend an asymmetric pack-vs-project decomposition, or (b) restrict the BD-162-shaped decomposition to pack-side only (project-side untouched in v11), or (c) propose a single decomposition unit that maps cleanly onto both surfaces.

**Recommended new guard-rail bullet (paraphrased; insert after the existing §5.5 bullets):**

> "Per addendum §10, the pack-side `IMPLEMENTATION-PLAN.md` is `## §`-section organized (8 H2 sections, 34 `**BD-NNN**` entries, typical 15–30 lines per BD). The OT-side `IMPLEMENTATION_PLAN.md` (project-template surface analog) is `## Phase NN` organized (per the original research §3 / addendum §3 compressed alternative). These two surfaces use *different* decomposition-unit candidates. If your design proposes per-entry decomposition for IMPLEMENTATION-PLAN, you must either (a) name the pack-side unit and the project-side unit separately and defend the asymmetry, or (b) restrict decomposition to pack-side only and explicitly leave project-side untouched, or (c) propose a single decomposition unit (e.g., `**BD-NNN**` on the pack side and `**TD-NNN**` on the project side, both ignoring the higher-level grouping) that composes onto both surfaces. Do not assume `## Phase NN` is a universal decomposition unit — it is not present on the pack side at all."

This is the **only** new guard rail recommended. The other prior-review guard rails carry over unchanged.

### 5.3 No amendment needed to the architect-overreach signals (prior review §5.4)

The prior review's §5.4 enumerated six signals an architect could misread as license to overreach. None of those six signals are altered by the addendum's findings; the architect-prompt should still surface all six. The addendum reduces the chance of misreading on the maintainability-principle and BD-104-ordering fronts (because §5 + §4 of the addendum give the architect the verbatim principle text and the verbatim collision facts, removing the "I had to derive this myself" friction that could push an architect into resolution-proposal mode).

---

## 6. Open items / minor observations (non-blocking)

These are observations that do not block APPROVE-FOR-ARCHITECT and do not require addendum changes; they are surfaced for completeness.

### 6.1 §3 compressed alternative is presented as drop-in but does not edit the original

The addendum §3 provides a markdown-fenced replacement block (lines 64–124) explicitly framed as "the architect can substitute this block for the original §3 in full." This is the right discipline (the addendum is research, not an edit), but it leaves the eventual question — does the architect read the original §3 or the compressed §3? — to the architect. Both are factual. The architect should pick whichever they find easier to consume; both produce the same set of facts.

**Recommendation.** None required. The dual-availability is the docs-researcher's correct response to the prior review's "trim if §3 goes to a v2" suggestion.

### 6.2 §6 omits the validate-pack file directive surface

Addendum §6 enumerates the read-shape change surface across PACK-CHAT, PM-CHAT, pack-startup, pm-startup. It does not enumerate `scripts/validate-pack.py` Check 3 (`check_td_tbd_sentinels`, lines 262–281 per the original research §7), which also reads BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN. The omission is *probably* correct — Check 3 reads the files for sentinel scanning, which is shape-agnostic to per-entry decomposition (sentinel scan reduces to "scan each entry file" under decomposition; the directive doesn't break, it just iterates). But the architect should be aware Check 3 lives in their integration footprint regardless.

**Recommendation.** None required. The original research §7 (still in scope) carries the Check 3 enumeration; the architect will see it.

### 6.3 §10 sub-section count for §1 is 13, but addendum says "BD-060..BD-083 cluster" — the cluster is 24 BDs in 13 sub-sections

Minor wording observation: addendum §10 reports §1 has 13 H3 sub-sections containing the BD-060..BD-083 cluster. BD-060..BD-083 is 24 BDs (60, 61, …, 83 inclusive), which means each H3 sub-section contains roughly 1–3 BDs. This is consistent with the typical BD-entry size of 15–30 lines and the §1 line range of 22–544 (~520 lines / 24 BDs ≈ 22 lines/BD). The accounting is internally consistent. Just noting that "13 H3 sub-sections" and "BD-060..BD-083 cluster" are both correct — they describe two different granularities, which is exactly the architect's design tension (per-§ vs per-§N.M vs per-BD).

**Recommendation.** None required. The architect benefits from seeing the count at multiple granularities.

### 6.4 Grand total of file:line citations in the addendum

Spot count: §1 cites 4 anchors with 8 file:line ranges; §4 cites 3 file paths with 3 specific line numbers + 1 line range; §5 cites 1 file with 5 line ranges; §6 cites 8 files with 13 line numbers; §7 cites 2 files with 8 specific function-line numbers; §8–§12 cite 4 files with verified grep / wc outputs. Net: ~30 file:line citations across 562 lines of addendum, every one verified clean for the 13 I sampled.

This citation density is higher than the original research (which had ~18 such citations per 1,048 lines). The addendum is more evidence-dense per line than the original, which is appropriate for fact-finding follow-up work.

---

## 7. Recommendation

**APPROVE-FOR-ARCHITECT.**

The addendum closes every gap, comment, and open question from the prior review. It introduces zero scope creep. It surfaces one substantive mental-model correction (§10) that sharpens — but does not invalidate — two existing prior-review design tensions (§4.2.1, §4.2.6). Its factual accuracy holds across 13 spot-checked claims. The maintainability-principle quotation in §5 and the BD-104-ordering paragraph in §4 give the architect direct verbatim access to the two principle/sequencing concerns the prior review flagged as Gaps B and C.

**Action items for the sidecar before architect spawn:**

1. **Add one new guard-rail bullet to the architect prompt** — the pack vs project decomposition asymmetry guard rail per this review's §5.2. Paste-ready text is provided there.
2. **Keep all six prior-review §5.5 guard rails** — none need amendment; the addendum strengthens (not weakens) them.
3. **Keep all six prior-review §5.4 architect-overreach signals** — the addendum does not affect them.
4. **The architect can read either the original §3 or the §3 compressed alternative from the addendum** — both are factual; the dual-availability is correct.
5. **The architect's primary input set is now: original research (1,048 lines) + addendum (562 lines).** Total ~1,600 lines. The architect can begin from these two documents as a complete pre-architect input set.

**The sidecar may proceed to architect spawn.** No further docs-researcher pass is needed unless the architect surfaces a new factual question during their pass.

---

*End of second-pass review.*
