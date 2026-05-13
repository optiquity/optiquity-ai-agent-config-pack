# REVIEW — RESEARCH-PER-ENTRY-SPLIT.md

**Reviewer:** pack-architect (primary v11-dev chat)
**Date:** 2026-05-13
**Subject:** `maintenance-docs/v11-research/RESEARCH-PER-ENTRY-SPLIT.md` (1,048 lines, sidecar chat docs-researcher output, 2026-05-13)
**Purpose:** Pre-architect review. Evaluate whether the research is sufficient and right-sized for the sidecar's upcoming architect pass on per-entry flat-file decomposition of `BACKLOG.md` / `IMPLEMENTATION-PLAN.md` / `CHANGELOG.md`, and whether the eventual design will integrate cleanly into the current v11.0 ship plan.
**Scope of this review:** read-only. No design proposals. No edits to the research. No design choices made on behalf of the architect.

---

## 0. Executive summary

The research is **factually sound, well-cited, and tightly scoped**. Every section pulls its weight; nothing reads as filler. The architect can begin from this document without re-doing the v3.x corpus walk, the v10.1 source-tree inventory, the migrator-surface read, or the validate-pack scan.

Three gaps and two over-emphases are worth flagging before the architect starts:

- **Gap A — pack-product surface impact is under-enumerated.** Research §6 lists the agent / skill / PM-CHAT files that *read* BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN by name, but does not enumerate the file-access strategy table cells that would need re-pointing if "the file" becomes "a directory of files." Per-entry decomposition changes the read shape (one file vs. N files) and the architect needs that surface in front of them.
- **Gap B — the maintainability principle is not cited.** `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 signals 4, 5, 6, 8 are very likely tripped by any per-entry decomposition (new validator check, new top-level doc(s) under decomposition tree, possibly new script(s), migrator behavior change). The research does not cite this principle, and the architect must be told it applies.
- **Gap C — BD-104 collision window is not made explicit.** Research §5 notes BD-104 (`IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` rename) and notes the migrator owns it, but does not flag the temporal collision: the per-entry design lands AFTER BD-104 in the v11 batch sequence and the migrator post-dispatch hook order matters.
- **Over-emphasis A — §1's exhaustive citation grid is dense.** It is correct and necessary, but the architect will use it as a lookup table, not a read-through. A short "what to read first" pointer at the top of §1 would help.
- **Over-emphasis B — §3 (OT project-side state) is more detail than the architect strictly needs.** OT is a v10.1 client and the per-entry decomposition is fundamentally a *pack-side* design question (the prompt is explicit on this). The OT data is useful as cross-check evidence but the depth in §3 (OT phase-task identifier shape, multi-line `Blockers:` syntax variants, full type-vocabulary list) sits closer to "stuff the tracker forward/reverse migrators already grapple with" than to "stuff the per-entry decomposition design needs."

Net: the research is approve-with-followups. A small follow-up pass (Gaps A/B/C) plus an editorial pointer at top of §1 would make it a clean handoff. The architect can also work from the research as-is; the gaps are recoverable mid-design.

---

## 1. Per-section completeness and focus assessment

For each section: confirmed sufficient, OR specific gap / excess called out with line range.

### §1 — Authoritative v11 entry-shape design (lines 22–148)

**Verdict:** Confirmed sufficient for completeness. Slight excess in structure.

The section enumerates the V3.x corpus sections that touch entry shape, with section name + line range for each. Coverage spans V3.0, V3.1-DELTA, V3.2-DELTA, V3.3-DELTA, and the v11-research IMPLEMENTATION-PLAN.md. The architect can pull any cited section on demand.

Strengths:
- Cites V3.3-DELTA §2.6 (lines 91–100, "Pack-side BD-NNN at L1") and §6.4 (identifier scheme summary, lines 361–370). These are the load-bearing pack-side identifier-shape citations the architect needs first.
- Cites V3.1-DELTA §3 (A2 decision codifying v10 BACKLOG grammar as reverse-emit format, lines 180–255) — critical because the per-entry design must round-trip through this format.
- Names V3.2-DELTA §4.1 / V3.3-DELTA §4.1 forward-parser regex contracts.

Excess (minor):
- The section reads as a citation grid 126 lines long. The architect will use it as a lookup table, not a sequential read. Suggested follow-up: add a 5-line "start-here" pointer at top of §1 naming the 3-4 most load-bearing sections (V3.0 §28.1, V3.1-DELTA §3, V3.3-DELTA §6.4, IMPLEMENTATION-PLAN.md §1.4).

Gap: none.

### §2 — Pack-side current state (lines 150–254)

**Verdict:** Confirmed sufficient. No excess.

Lists pack-root `BACKLOG.md` and `CHANGELOG.md` with line counts, byte counts, section layout, sample entries, observed entry-field labels, observed cross-reference syntax, and observed lifecycle-state vocabulary. Confirms pack repo has no `IMPLEMENTATION-PLAN.md` (and back-cites V3 §28.1 line 603 for that fact).

Strengths:
- Sample entry at lines 178–189 (BD-156) shows the full field set the per-entry decomposition must round-trip.
- Observation at lines 205–209 that `Status:` text appears inside `Resolved:` narrative bodies (so naive `grep -n "Status: "` overcounts) is exactly the kind of edge-case the architect needs to know before designing a per-entry parser.
- Observation at lines 222–240 that CHANGELOG.md is organized as nested-bullet "scope buckets" with inline parenthetical BD references (`(BD-060)`, `(BD-065 / BD-068 / BD-070)`) — important because per-entry CHANGELOG decomposition is much harder than per-entry BACKLOG decomposition (CHANGELOG entries reference *multiple* BDs, often clustered).

Gap: none. The section is the cleanest in the document.

### §3 — Project-side current state (OT as v10.1 client reference) (lines 256–451)

**Verdict:** Confirmed sufficient for the questions a tracker-aware architect might ask, BUT **likely more detail than the per-entry decomposition design needs**.

Per the prompt, the architect is designing a pack-side decomposition. OT is a v10.1 client, which means:
- OT data informs the *tracker forward / reverse migration* contract (already designed in V3.x — out of scope for the per-entry decomposition).
- OT data informs the *project-template* per-entry decomposition (relevant if and only if the architect is designing decomposition for project-side too, which the prompt does not require).

Useful in §3 (keep):
- Lines 304–314: OT TD-001 sample entry showing `Context:` field (project-only) and the `✅ RESOLVED (Phase NN)` annotation pattern in the bold-header line.
- Lines 320–345: enumeration of project-side `Type:` vocabulary including `KNOWN GAP(critical|dependency|functional|polish)`, `TODO(architecture|...)`, `VERIFY(etrade-api|public-api|schwab-api)`. Useful as evidence that project-side carries a much wider Type vocabulary than pack-side.
- Lines 372–395: Phase 0 task structure including `#### N.M — <Task Title>` regex shape — already governed by V3.3-DELTA §4.1 forward parser; useful as ground-truth corpus.

Excess in §3 (could trim if research goes to a v2):
- Lines 357–371: full H2 layout enumeration of OT IMPLEMENTATION_PLAN.md (Phase 0 through Phase 18). The architect does not need the live phase list — only the *shape* of a phase entry, which is covered in lines 372–395.
- Lines 405–448: OT CHANGELOG.md sample entry. OT CHANGELOG is appended-history; the per-entry decomposition is designing for the *pack* CHANGELOG, which has a different shape (version-partitioned, scope-bucketed). The OT shape is informative for tracker-side reverse migration but tangential to the pack-side decomposition.

The architect should be told: "use §3 as cross-check, not as primary design input." A `note-to-architect` line at the top of §3 would do it.

### §4 — Pack vs project entry-shape differences (observable only) (lines 453–464)

**Verdict:** Confirmed sufficient. The table is exactly the right level of abstraction.

Strengths:
- Names the asymmetry explicitly: pack uses `Resolved:` field, project uses `Resolution:` field + inline `✅ RESOLVED` annotation.
- Documents the conflict between pack `CLAUDE.md:148-152` rule ("BACKLOG.md has no Resolved section, entries resolve in place") and the live file having `## Resolved — v8` at line 2248. **This is exactly the kind of fact the architect needs and would otherwise miss.**
- Names the bullet-style multi-line `Blockers:` shape in OT (TD-005) vs single-line `Blockers: None` (TD-001) — a real parser corner case.

Gap: none.

### §5 — v10.1 → v11.0 migration entry-shape touchpoints (lines 466–622)

**Verdict:** Confirmed sufficient on the migrator surface. **One gap: BD-104 temporal collision is not made explicit.**

Strengths:
- Establishes v10.1 baseline source SHA (`fa817044`) and confirms v10.1 has no migrator framework, no customization-preserve, no tracker libs (so anything the per-entry design adds is v11-new, not a regression risk against v10.1).
- Lines 488–520: enumerates `migrate-v10-to-v11.sh` manifest contents (13 rows) and explicitly observes **BACKLOG.md / IMPLEMENTATION-PLAN.md / IMPLEMENTATION_PLAN.md / CHANGELOG.md are NOT in the manifest**. This is the load-bearing fact for the architect: today these files are not migrated by the framework at all; they pass through the working tree untouched (or fall to generic-text via customization-preserve when the user has customized them — see §5's later treatment).
- Lines 556–578: documents `customization_classify()` 12-class ladder and confirms `BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION_PLAN.md` / `IMPLEMENTATION-PLAN.md` fall to `generic` (the default branch at line 176–177) and route through `_cp_strategy_text` (3-way text dispatch). Verified independently — accurate.
- Lines 587–606: enumerates the BD-119 framework hooks an entry-shape-aware stage could plug into. This is the right surface for the architect to design against.

Gap: BD-104 collision window not flagged.
- Lines 608–621 cite BD-104 as the owner of the `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` rename. But the research does not call out the **temporal sequencing**: per `EXECUTION-PLAN-V11.0.md` §4 Batch 12, BD-104 is one atomic commit ("large blast radius"). If per-entry decomposition for IMPLEMENTATION-PLAN.md ships in the same v11.0 train, the architect must decide whether decomposition happens **before** or **after** BD-104 inside the migrator post-dispatch hook. This is not just a sequencing question — it determines whether the per-entry parser sees `IMPLEMENTATION_PLAN.md` (underscore, v10) or `IMPLEMENTATION-PLAN.md` (hyphen, post-rename) as input.
- Suggested follow-up: add one paragraph to §5 citing `EXECUTION-PLAN-V11.0.md` §4 Batch 12 and naming the question (without resolving it — that's the architect's job).

### §6 — Workflow code paths that read or write entry data (lines 624–750)

**Verdict:** Confirmed sufficient on the pack-startup / agent-prompt surface. **Gap: file-access strategy table cells in PACK-CHAT.md and project-template/docs/pack/PM-CHAT.md are listed but not explicitly characterized as the surface that breaks under per-entry decomposition.**

Strengths:
- Enumerates pack-startup skills (Claude / Codex / Gemini) and the exact line numbers of `Read BACKLOG.md in full` and `Read only the most recent dated entry from CHANGELOG.md` directives.
- Enumerates pack-architect / pack-planner / pack-coder / pack-reviewer agent files with the line numbers where each references `BACKLOG.md` / `CHANGELOG.md`.
- Enumerates project-template pm-startup skill, repo-ops agent, coder agent, auditor agent, auditor-docs agent, and the project-template docs/pack/PM-CHAT.md — each with line numbers.

Gap: the architect needs to see these as a **surface** that changes shape, not as a list of files. Specifically:
- `PACK-CHAT.md:42-43` declares `BACKLOG.md` and `CHANGELOG.md` as "Direct read" targets. Under per-entry decomposition, the read shape changes from "open the file" to "iterate the directory" or "open one entry per ID." The strategy column in that table is wrong post-decomposition; the architect needs to know this.
- `project-template/docs/pack/PM-CHAT.md:119,121,123` declares the same three files as "Direct read" with size-justified strategies. Same surface change.
- The pack-startup skills (Claude / Codex / Gemini) say `Read BACKLOG.md in full` — under per-entry decomposition this directive becomes ambiguous (read which file? read the index? read all entries?). The architect must redesign the directive.

Suggested follow-up: a small subsection §6.3 "Read-shape directives that break under per-entry decomposition" enumerating the specific lines (skill files + PM-CHAT file-access tables) whose wording is currently file-shaped. The lines are already named in §6 — the gap is that they are listed as "where the file is read" rather than as "where the directive needs rewording." The architect will likely catch this anyway, but the research could surface it explicitly.

### §7 — validate-pack.py checks touching entry files (lines 752–779)

**Verdict:** Confirmed sufficient. Tight, single-purpose section.

Strengths:
- Identifies Check 3 (`check_td_tbd_sentinels`, lines 262–281) as the **only** numbered check that reads any of the three stream files directly.
- Confirms via function-name listing that no other check operates on these files.
- Cross-references Checks 21–24 (BD-082 family, pack-help fragments — not entry files), Check 25 (BD-089, customization-detection guard — not entry files), and Check 31 (BD-146, skill-cell consistency — not entry files) so the architect knows the validator footprint is small.

Gap: none. This section is exactly what the architect needs.

### §8 — Tracker-mode entry-shape interaction (citations to V3.x) (lines 781–898)

**Verdict:** Confirmed sufficient on the tracker-side surface. Slight excess in function enumeration depth.

Strengths:
- Names every function that reads or writes BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md across `tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`, `tracker-mirror.sh`, `tracker-agent-read.sh` with line numbers.
- Critical fact at lines 846–853: `tracker_migrate_reverse_run()` writes all four files (BACKLOG / IMPLEMENTATION-PLAN / STATUS / CHANGELOG) in a single atomic write list. **Per-entry decomposition will need to redesign this write surface** — the architect must know.
- Confirms `tracker-provider*.sh`, `tracker-config.sh`, `tracker-labels.sh`, `tracker-errors.sh` have NO references to entry-stream files — they are tracker-internal (lines 890–898).

Excess (minor):
- The function enumeration in tracker-migrate-forward.sh (lines 787–812) and tracker-migrate-reverse.sh (lines 825–853) reads as a function-by-function inventory. The architect needs to know **which functions touch the file as a unit vs as a stream of entries**, not the full function map. A 3-line summary at the top of each subsection would compress this.

Gap: none. The information is there; it's just denser than needed.

### §9 — Out-of-scope confirmation (explicit) (lines 900–937)

**Verdict:** Confirmed sufficient. The right defensive section to include.

Explicitly carves out STATUS.md (human-reference dashboard, not a per-entry stream), PACK-FEEDBACK.md (project-side outgoing buffer; pack-side feedback is GH issues per D-11), and METHODOLOGY.md (does not govern pack-self). All three carve-outs cite the authoritative reasons.

Gap: none.

### §10 — Read-record (lines 939–1045)

**Verdict:** Confirmed sufficient. Exactly the right hygiene record.

Lists every command run, every file read with line ranges, every directory listed. Reproducible.

Gap: none.

---

## 2. Smooth-integration concerns — by current v11 BD

The per-entry decomposition design must land smoothly into the v11.0 plan. Each integration point below names the BD, what the per-entry design intersects, and what the research currently says about it (or fails to say).

### 2.1 Skill-dimensions reframe (BD-141 .. BD-150)

**Plan position:** ahead of the per-entry decomposition; per `EXECUTION-PLAN-V11.0.md` §4 the reframe runs first ("Effective execution order from 2026-05-11 forward: 1. Skill-dimensions reframe (BD-140..BD-150)").

**Intersection:** none observable. The reframe operates on `project-template/skills/`, `project-template/docs/pack/PLATFORM-SKILLS.md`, `scripts/lib/detect.sh`, and validate-pack Check 31 — none of which the per-entry decomposition touches.

**Research coverage:** §1 cites BD-141 / BD-156 / BD-157 / BD-158 contextually as the "worked-example calibration set" but does not analyze them as integration points (correctly — they don't intersect).

**Risk:** low. No follow-up needed.

### 2.2 Migrator framework (BD-119)

**Plan position:** shipped (BD-119 framework + `migrator-core.sh` + `migrator-stages.sh` + `migrator-manifest.sh` are already in v11-dev). The contract is frozen for v11.0 unless an explicit framework BD reopens it.

**Intersection:** **the per-entry decomposition will require migrator hooks**. Specifically, decomposing `BACKLOG.md` (or `CHANGELOG.md` or `IMPLEMENTATION-PLAN.md`) into a directory tree means the v10→v11 migrator must:
- Detect a v10 monolithic file in the working tree.
- Split it into per-entry files (forward).
- Reconstitute it from per-entry files (reverse, for users opting back to monolithic).
- Preserve customizations across the split (the customization-preserve generic-text branch does not handle this — see 2.3).

The BD-119 contract (per `ARCHITECTURE-BD-119.md` §3.2 and §4) supports this through `migrator_post_dispatch_hook()` (already used by v10→v11 for BD-104 rename and BD-042 relocation). The per-entry decomposition becomes another post-dispatch hook step.

**Research coverage:** §5 (lines 587–606) enumerates the BD-119 hooks correctly. Lines 522–545 enumerate `migrator-core.sh`, `migrator-stages.sh`, `migrator-manifest.sh` and confirm none of them reference BACKLOG / CHANGELOG / IMPL-PLAN. The architect has the surface they need.

**Risk:** medium. The architect must explicitly decide whether per-entry decomposition runs **inside** the v10→v11 migrator (post-dispatch hook on `migrate-v10-to-v11.sh`) or **outside** it (separate `pack-decompose.sh` script invoked manually). The research correctly does not pre-decide this — that's the architect's call.

**Follow-up suggestion:** none needed; the surface is documented sufficiently.

### 2.3 Customization-preserve (BD-088)

**Plan position:** shipped. `customization-preserve.sh` is the BD-088 deliverable.

**Intersection:** **direct.** Today, `BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md` fall to the `generic` class (verified independently at `customization-preserve.sh:147-178`). Generic class routes to `_cp_strategy_text` (3-way text dispatch, lines 531–532). 3-way text dispatch is **wrong for entry-stream files** even today, because BACKLOG additions are append-only-ish but with sub-section partitions (`## Active — v11 Scope` etc.) — the 3-way merge can produce conflict markers that misplace BD entries across sections.

Under per-entry decomposition, this gets simpler in some ways (each entry is its own file, three-way per-file is well-defined) and harder in others (the *index* file, if any, becomes the new merge battleground).

**Research coverage:** §5 (lines 580–585) explicitly documents that BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN are unclassified → fall to generic → text-dispatch. This is exactly the right framing.

**Risk:** medium. The architect must decide whether per-entry decomposition adds new `customization_classify()` cases (e.g., `backlog-entry`, `changelog-version-block`, `implementation-plan-phase`) and corresponding strategy functions. This is a real BD-088 surface change.

**Follow-up suggestion:** none needed; the gap is correctly named in §5.

### 2.4 Naming convention codification (BD-149)

**Plan position:** Resolved (per the recent commit history showing batch 7c ships).

**Intersection:** zero. BD-149 is about skill-name suffixes (`*-best-practices`, `*-language`, `*-architecture`, `*-patterns`); per-entry decomposition is about entry-stream files. Disjoint.

**Risk:** none.

### 2.5 Maintainability principle (BD-159)

**Plan position:** open per BACKLOG.md:1410. Codifies "skill and agent maintenance is mechanical by default; structural change is opt-in and must be defended" in pack memory + pointers.

**Intersection: this is the most important integration point and the research does not cite it.**

Per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2, a change is **structural** if any of:
- Signal 4: "New validator check" (per-entry decomposition will almost certainly add at least one).
- Signal 5: "New top-level doc" (per-entry decomposition is itself a new design doc; the decomposed tree may also create new top-level docs depending on layout).
- Signal 6: "New script" (a `pack-decompose.sh` or similar would trigger this).
- Signal 8: "Migrator behavior change. Any change that requires a new migrator stage, a new manifest entry, or a new advisory file in `migrate-vN-to-vM.sh` — these touch BD-119 framework contracts."

Per-entry decomposition **trips signal 8 for sure** and very likely trips signals 4, 5, 6. By the principle, this is unambiguously a **structural** change requiring an architect pass with defended scope. That pass is the sidecar's upcoming work.

**Research coverage:** none. The maintainability principle is not cited anywhere in the research.

**Risk:** medium. The architect should be told: "per the maintainability principle, this is a structural change; you must defend the scope explicitly and the planner that integrates your design must respect §3 thresholds."

**Follow-up suggestion:** add a note (one paragraph) to §1 or §5 citing `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 signals 4, 5, 6, 8 and naming the structural-change implication. The architect should not get this from us indirectly via the prompt — it should be in the research.

### 2.6 Validate-pack Check 31 (BD-146)

**Plan position:** Resolved (per BACKLOG.md:1498).

**Intersection:** zero. Check 31 is skill-cell consistency in PLATFORM-SKILLS.md; per-entry decomposition does not touch this surface.

**Risk:** none. (But see 2.10 below — the per-entry decomposition will likely propose a NEW Check that is structurally similar to Check 31's "consistency-cell-check" pattern.)

### 2.7 Cross-pack rename (BD-104)

**Plan position:** scheduled for Batch 12 of `EXECUTION-PLAN-V11.0.md`. One atomic commit; large blast radius.

**Intersection:** **temporal**. BD-104 renames `IMPLEMENTATION_PLAN.md` (v10) → `IMPLEMENTATION-PLAN.md` (v11) inside the v10→v11 migrator post-dispatch hook (verified at `migrate-v10-to-v11.sh:144` and lines 167–219). Per-entry decomposition for IMPLEMENTATION-PLAN must decide whether to run **before or after** this rename.

If the per-entry decomposition runs **inside** the migrator, the order matters:
- Run before BD-104 rename → decomposer reads `IMPLEMENTATION_PLAN.md` (underscore).
- Run after BD-104 rename → decomposer reads `IMPLEMENTATION-PLAN.md` (hyphen).

If the per-entry decomposition runs **outside** the migrator, it doesn't matter for v10→v11 (migration completes the rename first), but it matters for any future v11→v12 migrator that further reshapes the file.

**Research coverage:** §5 (lines 608–621) names BD-104 and lists the citations but does not flag the temporal sequencing question.

**Risk:** medium. The architect will probably catch this on their own, but the research could surface it explicitly to save the architect a context-switch into `EXECUTION-PLAN-V11.0.md` Batch 12.

**Follow-up suggestion:** add one paragraph to §5 noting the BD-104 ordering question. **Do not propose a resolution** — that's the architect's call.

### 2.8 Tracker forward/reverse migration (BD-067, BD-131..BD-134)

**Plan position:** BD-131..BD-134 are open per `EXECUTION-PLAN-V11.0.md` Batches 7–10. They sit upstream of any per-entry decomposition that touches the tracker surface.

**Intersection:** **direct, but the research handles it well.** §8 enumerates the tracker forward/reverse functions and identifies that `tracker_migrate_reverse_run()` writes BACKLOG.md / IMPLEMENTATION-PLAN.md / STATUS.md / CHANGELOG.md as a single atomic write list (`tracker-migrate-reverse.sh:853-856` and `:922`).

Under per-entry decomposition, the reverse-emit step needs to write to a directory tree, not to single files. That is a tracker contract change.

**Research coverage:** correctly named in §8 lines 825–853. The architect can see the full reverse-emit surface.

**Risk:** medium-high. Tracker forward/reverse migration is the most fragile surface in v11.0 (per the BD-132 BLOCKER and BD-131 / BD-133 / BD-134 NIT/SHOULD-FIX list). Per-entry decomposition either:
- Lands BEFORE BD-131..BD-134 are merged → the per-entry design must avoid stepping on those open BDs.
- Lands AFTER BD-131..BD-134 → the per-entry design composes against the fixed tracker surface.

The research does not name this sequencing concern. Probably a planner-pass concern (primary chat owns integration), not an architect-pass concern, but worth flagging.

**Follow-up suggestion:** no change to the research; this becomes a concern the primary chat's planner addresses when sequencing the per-entry design into the v11 batch plan.

### 2.9 BACKLOG/CHANGELOG/IMPLEMENTATION-PLAN as PM-only files

**Plan position:** standing rule per `CLAUDE.md` lines 82–86 and `EXECUTION-PLAN-V11.0.md` §5.E.2.

**Intersection:** **load-bearing.** `BACKLOG.md` / `CHANGELOG.md` / `README.md` version table / `PACK-CHAT.md` / `PACK-AGENTS.md` / trinity files are PM-only — no agent edits without explicit Pack Chat authorization. Per-entry decomposition turns these into directories. The PM-only rule must be redefined in terms of "the BACKLOG-entry directory tree" rather than "BACKLOG.md the file."

**Research coverage:** §6 cites the agent files that reference BACKLOG / CHANGELOG (e.g., `pack-coder.md:34`, `repo-ops.md:69-70`) but does not characterize them as the PM-only-rule expression surface.

**Risk:** medium. The architect needs to know this surface gets rewritten by their design. Otherwise they will design the decomposition without considering whether the Pack Chat / agent permission boundary travels cleanly to a directory model.

**Follow-up suggestion:** add a §6.4 (or include in §6.3 if you accept the §6 follow-up suggestion above) noting the PM-only file rule and the lines in CLAUDE.md / PACK-AGENTS.md / PACK-CHAT.md / project-template/.claude/agents/{coder,repo-ops}.md / project-template/docs/pack/PM-CHAT.md where the rule is expressed.

### 2.10 Validate-pack new check (latent)

**Plan position:** none yet — this is a derived integration point.

**Intersection:** under the maintainability principle, **any new validate-pack check is a structural signal**. Per-entry decomposition will almost certainly need at least one new check (e.g., "every BD-NNN directory has the required files"; or "no orphaned BD references in CHANGELOG.md scope buckets").

**Research coverage:** §7 correctly enumerates today's validator surface but does not project forward to the new checks decomposition will require.

**Risk:** low for the architect (they'll see this need in design). Worth surfacing for the planner.

**Follow-up suggestion:** none for the research. The architect will reach this conclusion themselves.

---

## 3. Comments and suggestions for the docs-researcher

If a follow-up research pass is run, the following adjustments would tighten the document. None are blocking — the architect can work from the research as-is.

### 3.1 Add a §1 reading order pointer

`§1` is 126 lines of citations to the V3.x corpus + IMPLEMENTATION-PLAN.md. The architect will use it as a lookup grid, not a sequential read. A 5-line "start here" pointer at the top of §1 naming the 3-4 most load-bearing sections would orient them. Suggested anchors (without prescribing — these are observations from the citation grid):
- V3.0 §28.1 inflection-point signals (lines 566–1032)
- V3.1-DELTA §3 (the A2 grammar decision, lines 180–255)
- V3.3-DELTA §6.4 identifier-scheme summary (lines 361–370)
- v11-research IMPLEMENTATION-PLAN.md §1.4 reverse-migration emit (lines 167–209)

### 3.2 Add a §3 architect note

Add one note at top of §3: "OT data is included as cross-check for tracker-side forward/reverse migration contracts. Per-entry decomposition is fundamentally a pack-side design question; OT shapes are informative but not load-bearing."

### 3.3 Trim §3 detail (optional)

If §3 is rewritten, the OT IMPLEMENTATION_PLAN.md H2 phase listing (lines 357–371) and the OT CHANGELOG.md sample entry (lines 423–448) can be reduced to a single sentence each plus a line-range reference. The phase-task structure (lines 372–395) should stay — that's the ground-truth corpus for the V3.3-DELTA §4.1 forward-parser regex.

### 3.4 Add §5 BD-104 ordering paragraph

Add one paragraph noting that BD-104 ships in `EXECUTION-PLAN-V11.0.md` §4 Batch 12 as one atomic commit, and that any per-entry decomposition that touches IMPLEMENTATION-PLAN.md must decide whether to run before or after BD-104's rename. Do not propose a resolution.

### 3.5 Add §5 maintainability principle citation

Add one paragraph citing `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 signals 4, 5, 6, 8 and noting that per-entry decomposition is a structural change requiring an architect pass with defended scope. This is the principle the architect's design is operating under, and the research should make it visible.

### 3.6 Restructure §6 to surface the "read shape changes" surface

§6 currently lists the files that read entry data. A follow-up could add a §6.3 or §6.4 explicitly characterizing the file-access strategy table cells in PACK-CHAT.md (lines 42–43) and project-template/docs/pack/PM-CHAT.md (lines 119, 121, 123) plus the pack-startup skill directives (`Read BACKLOG.md in full`) as the surface whose wording breaks under per-entry decomposition.

### 3.7 Compress §8 function inventory

The forward / reverse function enumerations are dense. A 3-line summary at the top of each subsection (which functions read the file as a unit; which read it as a stream of entries; which write the whole file) would compress the lookup.

---

## 4. Open questions

Two categories: (a) factual gaps the docs-researcher could fill in a follow-up; (b) design tensions surfaced by the research that the architect should reason about explicitly.

### 4.1 Open questions for the docs-researcher (factual)

1. **Are there any pack-side `## Resolved — vN` historical sections in BACKLOG.md beyond the v8 one cited at line 2248?** The research notes the conflict between `CLAUDE.md:148-152` ("BACKLOG.md has no Resolved section") and the live file at line 2248. A full `grep -n "^## Resolved"` count would tell the architect whether this is a one-off historical artifact or a recurring pattern that any per-entry decomposition must handle.

2. **What is the current count of CHANGELOG.md "scope bucket" headings (`**Scope X — ...**`) and how do they distribute across version blocks?** The research observes the pattern in the v11.0 entry (lines 234–253) but does not establish whether scope buckets exist in older version blocks. This determines whether per-entry decomposition for CHANGELOG must handle scope-bucket grouping or only version-block grouping.

3. **What is the current size of `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`'s phase entries?** The research cites `IMPLEMENTATION-PLAN.md` (1,109 lines) at line 964 but does not establish the per-phase or per-task line distribution. Useful for architect to size entry-file granularity.

4. **Are there any `.gemini/` per-CLI agent files that reference BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN by name?** §6 enumerates Claude and Codex pack-startup skills but only refers to the Gemini commands TOML (`.gemini/commands/pack-startup.toml`) by inference. A direct grep confirmation would close the trinity-coverage gap.

5. **What is the OT-side `STATUS.md` shape?** §9 confirms STATUS.md is out of scope for the per-entry decomposition, but if STATUS.md is a per-phase dashboard (e.g., one row per phase), the architect may want to know — STATUS-row-per-phase and IMPLEMENTATION-PLAN-phase-per-file are correlated decompositions and the architect's design might want to be consistent. (This is a borderline question; could go to category 4.2 instead.)

### 4.2 Open questions for the future architect (design tensions)

1. **Does per-entry decomposition apply uniformly to all three streams, or per-stream?** The research establishes that BACKLOG, CHANGELOG, and IMPLEMENTATION-PLAN have very different shapes:
   - BACKLOG = entries (BD-NNN), partitioned by version-and-activity, with `Status:` lifecycle.
   - CHANGELOG = version blocks, scope-bucket-organized, with multi-BD references per bullet, append-only-historical.
   - IMPLEMENTATION-PLAN = phase entries with sub-task L3 entities (per V3.2-DELTA D-21 / V3.3-DELTA), with `Tasks` sub-sections.
   
   Decomposing BACKLOG into per-BD files is straightforward. Decomposing CHANGELOG into per-version files (or per-scope-bucket, or per-bullet) is a different shape. Decomposing IMPLEMENTATION-PLAN into per-phase or per-task is a different shape again. **Does the design choose one decomposition philosophy or three?**

2. **Where does the per-entry decomposition tree live in the repo?** Candidates the architect must rule on:
   - Pack-root: `/.backlog/BD-NNN.md` / `/.changelog/v11.0.md` / `/.implementation-plan/phase-NN.md` (parallels `.pack-tracker/`).
   - Subdirectory: `/maintenance-docs/backlog/`.
   - Inside an existing tree: `/docs/backlog/`.
   - Hidden state: `/.pack-state/backlog/`.
   Each has migrator implications (what does v10.1 → v11.0 do?), validate-pack implications, and pack-ops-vs-pack-product separation implications.

3. **Is the monolithic file abolished or retained as a generated mirror?** The research establishes that pack-startup skills, agents, and PM-CHAT files all read `BACKLOG.md` as a single file. If the per-entry tree replaces the file, every read site changes. If the file is retained as a generated mirror (analogous to the tracker mirror per V1 §6.3), the read sites stay but the write sites move. **Generated-mirror-or-replace is the central design tension.**

4. **How does per-entry decomposition compose with tracker mode?** Today there are two read modes (flat-file vs tracker, per V3.x). Per-entry decomposition is a third read shape. Does it sit:
   - Below tracker (flat-file flavor: monolithic-flat vs decomposed-flat, both feed forward migration to tracker)?
   - Beside tracker (third top-level mode)?
   - Inside tracker (the tracker stores per-entry; the file system mirrors per-entry)?

5. **What is the BACKLOG-vs-CLAUDE.md "no Resolved section" rule's status under decomposition?** §4 of the research (lines 463) names the conflict between the rule and the live `## Resolved — v8` section. Under per-entry decomposition, "Resolved" becomes a status field on each entry file, not a section. The rule may become trivially true (no sections at all) or trivially obsolete (no sectioning concept). **The architect should resolve this explicitly.**

6. **Does the per-entry decomposition propagate to `project-template/`?** The pack-side decomposition is the prompt scope. But `project-template/docs/project/BACKLOG.md` (and the OT live BACKLOG.md / IMPLEMENTATION_PLAN.md / CHANGELOG.md per §3) are the project-side analogs. If the design only decomposes pack-side, project-side stays monolithic — that's a defensible asymmetry but the architect must name it.

7. **Customization-preserve class: new class or generic-with-shape?** Today these files fall to `generic` and route through 3-way text dispatch (per §5 lines 580–585 and `customization-preserve.sh:147-178`). Under decomposition, the architect must decide whether to add `backlog-entry` / `changelog-version-block` / `implementation-plan-phase` as new classes (each with a dispatch strategy) or to treat the decomposed tree as still-generic-but-per-file. The former is more invasive; the latter requires the file paths to fall through to the existing dispatch.

---

## 5. Architect scope boundaries

Per the prompt, the sidecar's architect:
- Should NOT change the format of any existing entries.
- Should NOT touch primary-chat-owned files.
- Should produce only an architecture doc (no implementation, no edits to product files).

### 5.1 Concrete primary-chat-owned files the architect must not touch

These are PM-only / primary-chat-managed per the v11 standing rules. The architect's design doc may *reference* them; the architect must not *edit* them and must not propose edits in the same doc as the design.

- `BACKLOG.md` (pack root)
- `CHANGELOG.md` (pack root)
- `README.md` version table (pack root)
- `PACK-CHAT.md` (pack root)
- `PACK-AGENTS.md` (pack root)
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack root and `project-template/`)
- `EXECUTION-PLAN-V11.0.md` and any `PLAN-*.md` in `maintenance-docs/v11-implementation/`
- The v11-research authoritative corpus: `ARCHITECTURE-V3.md`, `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-V3.2-DELTA.md`, `ARCHITECTURE-V3.3-DELTA.md`, `IMPLEMENTATION-PLAN.md`

### 5.2 Concrete pack-product files the architect must not touch

The architect produces a design doc only. Even though the design will eventually require edits to these files, those edits are owned by the planner and coder passes that follow — not by the architect.

- `scripts/migrate-v10-to-v11.sh`
- `scripts/lib/migrator-core.sh` / `migrator-stages.sh` / `migrator-manifest.sh` / `migrator-skills.sh`
- `scripts/lib/customization-preserve.sh`
- `scripts/lib/tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` / `tracker-mirror.sh` / `tracker-agent-read.sh`
- `scripts/lib/detect.sh`
- `scripts/validate-pack.py`
- `project-template/skills/pm-startup/SKILL.md` and per-CLI copies
- `.claude/skills/pack-startup/SKILL.md` / `.codex/skills/pack-startup/SKILL.md` / `.gemini/commands/pack-startup.toml`
- `.claude/agents/pack-*.md` and the `project-template/.claude/agents/*.md`
- `project-template/docs/pack/PM-CHAT.md`

### 5.3 Existing-entry-format guard rail

**The architect must not change the format of existing entries.** Per V3.1-DELTA §3 (A2 decision), the v10 BACKLOG grammar is the authoritative format for reverse-migration emission. The per-entry decomposition must **preserve that grammar inside each per-entry file**. The architect may design the per-entry **container** (filename, location, index, mirror) but not the **entry shape** (the `**BD-NNN — Title**` header line, the `Type:` / `Status:` / `Blockers:` / `Unblocks:` / `File/Symbol:` / `Description:` / `Resolved:` field labels, the `---` separator, or the cross-reference syntax).

If the architect's design implies any change to the entry shape — even cosmetic — that is out of scope. The decomposition design must be byte-additive on entry format.

### 5.4 Signals in the research that suggest possible architect overreach

These are not flaws in the research; they are observations the architect may misread as license to expand scope. Each should be flagged in the architect's prompt with an explicit guard rail.

1. **§4 row "Required fields observed" (line 460) lists `Resolution:` (project) vs `Resolved:` (pack) and the `✅ RESOLVED (Phase NN)` annotation difference.** An architect could read this as an invitation to harmonize the field names. **Out of scope.** Pack and project use different field names because they have different state machines (per V3.3-DELTA §6.3); harmonization is a separate BD if at all.

2. **§4 row "Lifecycle states observed" (line 462) shows pack has 5 states (Open / Resolved / Deferred / Cancelled / Deprecated) vs project's 2 (Open / Resolved).** An architect could read this as license to redesign the state vocabulary. **Out of scope.** State vocabulary is governed by V3.3-DELTA §6.3 and is not a decomposition concern.

3. **§4 final row's documentation of the `## Resolved — v8` rule conflict.** An architect could read this as an invitation to "fix" the rule by abolishing the section or by amending CLAUDE.md. **Out of scope.** CLAUDE.md is PM-only. The architect may *flag* the conflict but must not propose a resolution that edits CLAUDE.md.

4. **§5's enumeration of the BD-119 framework hooks.** An architect could read this as license to add a new required hook to the framework contract. **Out of scope unless explicitly defended.** The framework contract is frozen for v11.0 unless a structural-change defense is made. Per the maintainability principle (`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 signal 8), changing the BD-119 contract is a structural signal in itself.

5. **§6 enumeration of the agent files / pack-startup skills.** An architect could read this as an invitation to redesign the pack-startup flow. **Out of scope.** The architect may name *which* files need updating to reflect the new read shape; the architect must not write the new file content. Those edits belong to the planner / coder passes the primary chat owns.

6. **§8 documentation of `tracker_migrate_reverse_run()` writing four files atomically.** An architect could read this as license to redesign the tracker reverse-emit contract. **Out of scope.** Per `EXECUTION-PLAN-V11.0.md` §4 Batches 7–10, the tracker surface is being repaired by BD-131..BD-134 in v11.0; the per-entry decomposition design must compose against that repaired surface, not redesign it.

### 5.5 Recommended explicit guard rails for the sidecar's architect prompt

When the sidecar spawns the architect, the prompt should include (paraphrased):

- "Output is one architecture doc under `maintenance-docs/v11-research/` (or `maintenance-docs/v11-implementation/`). No edits to any other file."
- "Do not change the format of any existing entry. The v10 BACKLOG grammar (per V3.1-DELTA §3 A2 decision) is the authoritative entry shape. Decomposition is byte-additive on entry format."
- "Do not propose edits to CLAUDE.md / AGENTS.md / GEMINI.md / PACK-CHAT.md / PACK-AGENTS.md / BACKLOG.md / CHANGELOG.md / README.md / EXECUTION-PLAN-V11.0.md / any `PLAN-*.md`. You may *reference* these files in your design as integration points; the planner pass that follows will handle the edits."
- "The maintainability principle (`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2) applies. Per-entry decomposition trips structural signal 8 (migrator contract change) and very likely signals 4 (new validator check), 5 (new top-level doc), 6 (new script). Defend each structural signal explicitly in your design's scope section."
- "The BD-119 framework contract is frozen for v11.0. If your design requires extending the contract, name that as a structural change and defend it; do not assume it."
- "The integration with `EXECUTION-PLAN-V11.0.md` Batches 7–10 (tracker repairs) and Batch 12 (BD-104 rename) is owned by the primary v11-dev chat's planner pass. Your design must be sequencing-agnostic with respect to those batches; flag any sequencing constraint your design imposes but do not pre-resolve it."

---

## 6. Conclusion

`RESEARCH-PER-ENTRY-SPLIT.md` is fact-finding research that does its job. The architect can begin from this document.

Three small follow-ups would tighten the handoff:
- **Gap A** — surface the read-shape change in the file-access strategy tables and pack-startup skill directives (§6 follow-up, see 1.§6 and 3.6).
- **Gap B** — cite the maintainability principle and name the structural signals decomposition trips (§5 follow-up, see 2.5 and 3.5).
- **Gap C** — flag the BD-104 ordering question without resolving it (§5 follow-up, see 2.7 and 3.4).

Without these follow-ups, the architect can still produce a sound design — they will reach the same observations through their own reading of the integration-point files. The follow-ups would save the architect ~30 minutes of cross-doc navigation and reduce the chance of an integration miss.

The research's restraint (no proposals, no analysis, fact-finding only) is exactly the right tone for a pre-architect pass. The architect can safely treat every cited fact as ground-truth without re-verification.

**Recommendation:** approve-with-followups. The sidecar may proceed to architect spawn either before or after the docs-researcher addresses the gaps; preference for "after" if the sidecar's schedule allows, but "before" is acceptable.

---

*End of review.*
