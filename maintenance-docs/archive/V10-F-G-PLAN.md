# V10-F-G-PLAN — Solution leakage in PM-chat-generated prompts (planner pass)

**Author:** pack-planner (v10.0 patch — F-G resolution)
**Date:** 2026-04-29
**Implements:** `maintenance-docs/V10-F-G-DESIGN.md` (architect pass, 2026-04-29; project-lead approved with two modifications — see §0).
**Status:** Draft — planner output. Read-only on every pack source. No edits, no commits. Implementer (parent Pack Chat) executes after project-lead approval of this plan.
**Scope:** v10.0 patch resolving F-G (PM-chat-generated coder prompts cross from format/scope into solution territory). Companion to F-D + F-C (commits `1de2d23` / `603234e` / `55d1834`) and F-E + F-F (3-commit cohort) already landed.

---

## 0. How to read this plan

V10-F-G-DESIGN.md is the authoritative design input. The decision (new "Format-vs-solutions: worked examples" subsection in METHODOLOGY § Prompt Authoring Principles, between current line 691 and line 693), Negative/Positive/Why example shape, the 5-example selection (4 leakage categories + 1 Files-in-scope clarifying example), and the self-consistency cleanup of `pm-chat.md` Variant: generate-agent-kickoff are baked-in here and not re-litigated.

**Project-lead modifications (already approved; treat as constraints):**

- **D1.** Design approved as written.
- **D2 (OQ-F-G-1, modified).** Delete the three pm-chat.md generate-agent-kickoff Notes (lines 261–286) AND replace with **a single checklist-style pointer line** that references **all three trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) AND active skills** (architect's recommendation cited only `CLAUDE.md`; project lead expanded for trinity symmetry).
- **D3 (OQ-F-G-2, REVERSED).** Add a `pm-chat` row to the per-agent table at METHODOLOGY lines 674–684 in this v10.0 patch (architect recommended deferring to v10.1; project lead pulled it in).
- **D4 (OQ-F-G-3, accepted).** Worked examples are phase-anonymous — no "Phase 28" / "Phase 32" cites in pack-distributed METHODOLOGY.
- **D5 (OQ-F-G-4, accepted).** No complete-skeleton example in this patch.
- **D6 (OQ-F-G-5, accepted).** No parallel callout in `coder.md` Variant: standard.

The implementer can execute this plan literally without further architectural calls.

---

## 1. Goal and BD items addressed

**Goal:** Eliminate solution leakage in PM-chat-generated prompts by (a) adding pattern-matchable worked examples to METHODOLOGY § Prompt Authoring Principles, (b) extending the per-agent table to cover pm-chat self-prompts, (c) cleaning up the `pm-chat.md` Variant: generate-agent-kickoff template — which currently contains three prescriptive Notes that anchor the architect agent and reproduce the same leakage one workflow step upstream — and (d) preserving the substantive concurrency and LSP design lessons from those deleted Notes by adding two new entries to `project-template/skills/swift-best-practices/SKILL.md` (per project-lead resolution of FB-3, which expanded the original Option (a) preserve-in-skills choice to cover BOTH the AsyncStream payload-design lesson AND the heterogeneous-collection / type-erasure / LSP lesson in the same skill addition).

**BD items in scope:**
- F-G → one BD-NNN (assigned at C-V10-18 BACKLOG sweep).
- This plan does NOT file the BD entry; it produces the edits the BD entry's "Resolution" line will reference.

---

## 2. Commit shape decision

**Decision: 3 commits**, matching the F-E + F-F pattern. C2 is a 3-file atomic patch (expanded from the original 2-file scope by project-lead resolution of FB-3 — see §9.3).

| Commit | Type | Files | Purpose |
|---|---|---|---|
| **C1** | `docs:` | `maintenance-docs/V10-F-G-DESIGN.md`, `maintenance-docs/V10-F-G-PLAN.md` | Land the design + plan documents. |
| **C2** | `feat:` | `supporting-docs/METHODOLOGY.md`, `project-template/docs/pack/prompts/pm-chat.md`, `project-template/skills/swift-best-practices/SKILL.md` | Atomic 3-file behavioral patch — METHODOLOGY worked-examples subsection + per-agent table pm-chat row + pm-chat.md Notes cleanup with trinity+skills pointer + swift-best-practices SKILL additions preserving the substantive AsyncStream and LSP/type-erasure lessons (FB-3 resolution). |
| **C3** | `docs:` | `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (append §12) | Delta-verification evidence section. |

**Rationale (why atomic for C2; why the docs-vs-impl-vs-evidence split):**

1. **Atomic for C2 because the four edits are tightly coupled.** The new METHODOLOGY worked-examples subsection and the pm-chat row in the per-agent table are both content additions inside the same `## Prompt Authoring Principles` section — splitting them creates a misleading intermediate state where the pm-chat row references concepts the worked-examples subsection has not yet introduced. The pm-chat.md cleanup is the self-consistency partner of the METHODOLOGY change — landing METHODOLOGY without the pm-chat.md cleanup leaves the canonical example template still containing the exact pattern the new METHODOLOGY subsection forbids. The swift-best-practices SKILL.md additions (E4) are the substantive home for the concurrency and LSP design lessons being removed from pm-chat.md — landing the pm-chat.md cleanup (E3) without the SKILL additions (E4) creates an intermediate state where the pointer text in pm-chat.md says "read the active skills for the universal rules" but the skills do not yet carry the lessons the deleted Notes embodied. Atomic eliminates all four intermediate states.
2. **C1 separated from C2** so the design + plan documents are reviewable as reference artifacts before the implementation lands, matching F-D / F-E+F-F precedent.
3. **C3 separated from C2** so the behavioral patch is reviewable independently of the evidence capture, and so evidence regeneration does not require re-touching the behavioral diff.
4. **`validate-pack.py` does not assert any of the new content.** Check 6 (Prompts-directory format) verifies frontmatter and variant→H2 consistency in `project-template/docs/pack/prompts/*.md` — it does NOT inspect the body of variants for prescriptive content. Check 10 (Prompt template triad compliance) verifies every in-scope variant contains `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and a file-based completion-report marker — those four markers are NOT removed by this patch (the Notes deletion is inside the Files-in-scope/placeholder list, not inside the triad). No METHODOLOGY-content checks exist. The SKILL.md addition adds two new numbered entries inside an existing skill file — no validate-pack.py check inspects skill body content. Splitting C2 therefore offers no validate-pack.py-driven gating value.
5. **Trinity rule is not engaged in C2** (per design §7 / D2). The pointer text in pm-chat.md *references* the trinity files (mentions them by name as a read-target for the architect), but does not *edit* them. The SKILL.md addition is in `project-template/skills/swift-best-practices/SKILL.md` — also not a trinity file. The existing `project-template/CLAUDE.md` line 395 anti-pattern reference (one-liner about branching on concrete types instead of querying capability) stays as-is per project-lead direction; it is NOT added to AGENTS.md / GEMINI.md as part of this patch. The broader trinity-asymmetry on anti-patterns remains a separate / non-F-G concern. No trinity-symmetry gate to satisfy in C2.
6. **Touch surface for C2 is moderate (3 files; ~+50 lines METHODOLOGY, ~−24 lines / +9 lines pm-chat.md, ~+18 lines SKILL.md = ~+53 net).** A single coherent commit is easier to review than three or four thin ones, and the four edits share a single thematic intent (make the format-vs-solutions rule pattern-matchable while preserving the substantive design lessons in their canonical home).

**Rejected alternative — split C2 into "METHODOLOGY first; pm-chat.md second; SKILL.md third":** triples approval overhead; introduces misleading intermediate states (e.g., the canonical template still demonstrating the leakage pattern the just-added subsection forbids; or the pm-chat.md pointer text referencing skill content that has not yet landed); produces no checkpoint that validate-pack.py would gate on.

**Rejected alternative — split SKILL.md addition into a separate v10.1 BACKLOG entry:** was the original architect/planner default before FB-3 surfaced. Project-lead reversed this — preserving the substantive lessons in the same patch as the deletion eliminates a window during which the pack is internally inconsistent (pm-chat.md pointer says "read the skills" but the skills do not yet carry the relevant content).

**Rejected alternative — combine C1+C2+C3 into one commit:** mixes design docs (which should be reviewable separately) with behavioral changes; mixes verification evidence (captured AFTER implementation runs) with the implementation itself; breaks the established F-D / F-E+F-F pattern.

---

## 3. Affected files (complete list)

### 3.1 Files edited in C2 (3)

| # | File | Edit area | Purpose |
|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | Two distinct edits in `## Prompt Authoring Principles`: (a) per-agent table at lines 674–684 — insert one new row for `pm-chat`; (b) insert new `### Format-vs-solutions: worked examples` subsection between current line 691 (end of "Format requirements vs. solutions") and current line 693 (start of "File-based reporting"). | Make the format-vs-solutions rule pattern-matchable via worked examples; clarify that the rule applies to PM chat self-prompts. |
| 2 | `project-template/docs/pack/prompts/pm-chat.md` | Variant: generate-agent-kickoff structural-decisions checklist, lines 259–287 (the three □ items each carrying a prescriptive `Note:` block). | Delete the three Notes (~24 lines). Add a one-line pointer instruction (per D2) directing the architect to read the three trinity files and active skills for the universal rules constraining these decisions. |
| 3 | `project-template/skills/swift-best-practices/SKILL.md` | Append a new section after entry 38 (the last current entry, in the "Dead code and unused imports" section). New section heading `## Design choices`; two new numbered entries 39 (AsyncStream payload design) and 40 (heterogeneous domain collections — protocol elevation over type-erasure-with-downcasting). | Preserve the substantive concurrency and LSP design lessons currently embedded in pm-chat.md's prescriptive Notes (which E3 deletes). Per FB-3 resolution: the skill is the canonical home for both lessons. |

### 3.2 Files edited in C1 (2)

- `maintenance-docs/V10-F-G-DESIGN.md` — already on disk (architect output); add to git in C1.
- `maintenance-docs/V10-F-G-PLAN.md` — this file; add to git in C1.

### 3.3 Files edited in C3 (1)

- `maintenance-docs/V10-PHASE-4-VERIFICATION.md` — append new `## §12 Delta verification — F-G patch` section after the existing `## §11` section (last existing line: 1106). Template per §5.4 of this plan.

### 3.4 Files NOT edited (verified)

- `project-template/CLAUDE.md` (line 172 LSP rule), `AGENTS.md` (line 96 LSP rule), `GEMINI.md` (line 129 LSP rule) — trinity LSP content already present and symmetric. The new pm-chat.md pointer line *names* these three files as a read-target for the architect; it does not modify their content. **Trinity-rule status: clean.**
- `project-template/docs/pack/prompts/coder.md`, `architect.md`, `planner.md`, `reviewer.md`, `tester.md`, `auditor.md`, `docs-researcher.md`, `repo-ops.md`, `grpc-schema.md` — per design §4.2, all variants other than `pm-chat.md` Variant: generate-agent-kickoff are clean. No edits required. (D6 confirms no parallel callout in `coder.md` Variant: standard.)
- Other variants in `pm-chat.md` (kickoff, backlog-status-update, generate-setup) — clean per design §4.2. No edits required.
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` — design §4.4 / §6.1 listed this as a possible relocation target for the deleted Notes. D2 chose deletion-with-pointer over relocation, so AGENT_KICKOFF_TEMPLATE.md is NOT edited in this patch. The pointer says "the architect must read CLAUDE.md / AGENTS.md / GEMINI.md and active skills" — the substantive concurrency and LSP/type-erasure lessons land in `project-template/skills/swift-best-practices/SKILL.md` via E4 (FB-3 resolution); the LSP rule itself is also already canonical in the trinity (CLAUDE/AGENTS/GEMINI lines 172/96/129).
- `project-template/CLAUDE.md` line 395 anti-pattern bullet ("Branching on concrete types to discover what an abstraction supports, instead of querying a capability value or interface") — stays as-is. NOT removed; NOT mirrored into AGENTS.md / GEMINI.md as part of this patch. The substantive type-erasure / LSP lesson is carried by the new swift-best-practices SKILL entry 40 (E4); the broader trinity-asymmetry concern on anti-patterns (OQ-2 follow-up) remains a separate / non-F-G issue.
- `scripts/init-project.sh`, `scripts/migrate-v9-to-v10.sh`, `scripts/validate-pack.py`, `scripts/test-detect.sh` — no edits. Pack-distribution mechanics unaffected; METHODOLOGY and prompts/ contents propagate via existing copy paths; no new validation checks introduced.
- `project-template/CLAUDE.md` Pack-version markers, `README.md` (pack root), `BACKLOG.md`, `CHANGELOG.md` — out of plan scope; handled by Pack Chat at C-V10-18 BACKLOG sweep.
- `maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md` — no edit. New subsection is post-Phase-4 ship-blocker work; the v2 plan does not assert worked-example presence.

### 3.5 Cross-reference audit (verified)

- `Format-vs-solutions: worked examples` references in pack content (excluding V10-F-G-DESIGN.md and this plan): zero before C2; one hit (the new subsection heading) after C2.
- `pm-chat` row in METHODOLOGY per-agent table: zero hits before C2; one hit after C2.
- The three deleted Notes' content phrases — "Type-erasure wrappers", "AsyncStream<Void>", "ViewModels must not import SwiftUI" — currently exist in `pm-chat.md`. Post-C2, the LSP rule itself remains in the trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` LSP section) where it is canonical; the substantive AsyncStream-payload-design and type-erasure-vs-protocol-elevation lessons land in `project-template/skills/swift-best-practices/SKILL.md` as new entries 39 and 40 (E4); the pm-chat.md occurrences are removed. The "ViewModels must not import SwiftUI" lesson is NOT separately preserved by this patch — it is a concrete navigation-coupling assertion that the Format-vs-solutions rule says belongs in the architect's diagnosis output, not the prompt's pre-decision; the apple-architecture-core skill carries the underlying layer-discipline rules. Post-C2 grep verification: `grep -rn "AsyncStream<Void>" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs` should return exactly 1 hit (the new SKILL entry 39); pre-E4-but-post-E3 it would return 0 — see §9.1 R1 (RESOLVED) and §9.3 FB-3 (RESOLVED).

---

## 4. Edit order within C2

The implementer applies edits in this order within the atomic C2 commit. Order is chosen so an interrupted edit session leaves the most-critical correctness in place first, each step's verification check can run cleanly before the next edit lands, and the substantive content (E4 SKILL additions) lands BEFORE the pointer text (E3) that references it — so at no intermediate state does the pm-chat.md pointer reference skill content that has not yet landed.

| Step | File | Why this order |
|---|---|---|
| E1 | `supporting-docs/METHODOLOGY.md` per-agent table — insert `pm-chat` row (lines 674–684 area) | Smallest, lowest-risk edit. Lands the table-row addition first; if the implementer is interrupted, the table is enlarged but otherwise consistent. |
| E2 | `supporting-docs/METHODOLOGY.md` Format-vs-solutions: worked examples subsection (between current lines 691 and 693) | Larger METHODOLOGY insertion. Lands second so the per-agent table is already updated and the new subsection's closing pointer ("see the per-agent table in the previous subsection") is consistent with the just-edited table. Both METHODOLOGY edits land before the cross-file edits, so any METHODOLOGY rollback (e.g., self-consistency re-read fails) does not cascade. |
| E4 | `project-template/skills/swift-best-practices/SKILL.md` — append new `## Design choices` section with entries 39 (AsyncStream payload design) and 40 (heterogeneous domain collections — protocol elevation over type-erasure) | Lands BEFORE E3 so when E3's pm-chat.md pointer says "the architect must read the universal rules constraining these decisions in CLAUDE.md / AGENTS.md / GEMINI.md and any active skills listed in the trinity Active skills line", the swift-best-practices skill genuinely carries those substantive rules at the time E3 lands. Reverses no METHODOLOGY work. Pure append. |
| E3 | `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff cleanup (lines 259–287) | Lands last so when the cleanup pointer says "the architect must read the universal rules in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` and active skills", (a) METHODOLOGY already carries the worked-examples subsection that explains *why* this redirect exists, and (b) the swift-best-practices skill (E4) already carries the substantive AsyncStream and LSP/type-erasure lessons the redirect implicitly promises the architect will find. The pointer text in E3 is honest only after E4 lands. |

**Edit-order justification (E1 → E2 → E4 → E3):** The chosen order prioritizes (a) METHODOLOGY edits clustered first (E1, E2 — same file, sequential), (b) substantive content landings (E4) before pointer landings (E3) so no intermediate state has a pointer referencing missing content, (c) lowest-risk edits earlier so an interrupted session leaves the pack maximally consistent. The alternative E1 → E2 → E3 → E4 was rejected because between E3-landing and E4-landing the pm-chat.md pointer would reference "active skills" content that does not yet exist in the swift-best-practices skill — a (transient, but real) self-inconsistency. The alternative E4 → E1 → E2 → E3 is also valid (substantive content first, all else after) but offers no practical advantage and breaks the natural same-file-edits-cluster pattern.

`validate-pack.py` is not run incrementally between these edits — Check 6 / Check 10 do not gate on any of the new content, and no validate-pack.py check inspects skill body content. It is run **once** after all four edits land, before commit (per §6 checklist).

---

## 5. Per-file edit specifications

### 5.1 Edit E1 — `supporting-docs/METHODOLOGY.md` per-agent table — insert pm-chat row

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** 674 (table header) through 683 (last data row — `tester`); line 684 is the spacer line `> **Update this table when any agent is added or changed.**`.
**Insertion point:** after current line 683 (the `tester` row), before line 684 (the spacer / update note). The table is alphabetically ordered; adding `pm-chat` after `tester` breaks alphabetical order — but `pm-chat` is conceptually a **non-agent** (per `pm-chat.md` line 12: "the PM chat is the consumer of these templates, not an agent"). Place it **last** with a brief footnote-style hint in the agent column to mark its different status, rather than splicing into the alphabetical body.

**Placement decision rationale:** Two viable placements:
- (a) Alphabetical — between `planner` and `repo-ops`. Risks reader inferring pm-chat is an agent.
- (b) Last — after `tester`, before the spacer. Marks pm-chat's distinct nature visually; preserves the agent-only alphabetical block for the eight true agents.

**Choice: (b) — last.** Rationale: pm-chat is structurally different (it consumes templates rather than running as an agent); placing it last avoids contradicting the existing pm-chat.md line 12 framing. The new row uses `pm-chat (self-prompt)` in the Agent column to make the distinction explicit at-a-glance.

**Insert text (paste verbatim, immediately after the `tester` row at line 683, immediately before line 684 `> **Update this table...**`):**

```markdown
| `pm-chat` (self-prompt) | When generating a prompt for any other agent, the PM chat may specify the same format requirements that agent's row allows. When generating its own self-prompts (BACKLOG entries, STATUS anchors, SETUP.md, AGENT_KICKOFF.md), the PM chat may specify the target file's schema and section structure. | Inheriting the target agent's solution-forbidden list — a PM-chat-authored coder prompt may not contain pseudocode or pattern names, a PM-chat-authored architect prompt may not contain proposed solutions or pattern names, etc. The PM chat is bound by every constraint that applies to the agent it is prompting. |
```

**Verification check for this edit:**

```bash
# After edit, confirm the new pm-chat row is present and the existing rows unchanged.
grep -nE '^\| `(pm-chat|tester|reviewer|repo-ops|planner|docs-researcher|coder|auditor|architect)' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 9 hits — the 8 existing agent rows plus the new pm-chat row.
grep -c '^| `pm-chat`' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1.
grep -n 'Update this table when any agent is added or changed' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit; line moved down by one (~685).
```

### 5.2 Edit E2 — `supporting-docs/METHODOLOGY.md` Format-vs-solutions: worked examples subsection

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** line 691 ends the "Format requirements vs. solutions" subsection (the "Architect prompts — stronger restriction" paragraph that ends with "The architect diagnoses and proposes."); line 692 is blank; line 693 starts `### File-based reporting`.

**NOTE on line drift after E1:** edit E1 inserts one new row into the table at line 683, shifting all subsequent lines down by one. After E1 lands, the "Architect prompts — stronger restriction" paragraph ends around line 692; blank line at 693; `### File-based reporting` starts at line 694. The implementer applies E2 by anchoring on the **content** ("The architect diagnoses and proposes." → blank line → `### File-based reporting`), not the absolute line number.

**Insertion point:** after the line ending "The architect diagnoses and proposes." and the blank line that follows, insert the new subsection content, then a blank line, then the existing `### File-based reporting` heading remains unchanged.

**Insert text (paste verbatim):**

```markdown
### Format-vs-solutions: worked examples

The format-vs-solutions distinction is easier to read in the abstract
than to apply under time pressure. The examples below show the most
common leakage shapes observed in PM-chat-generated coder prompts
(paraphrased from real cases). For each: the **Negative** line shows
what NOT to write; the **Positive** line shows the format/constraint
version; the **Why** line names the leakage category.

**Example 1 — testability technique**
- **Negative:** *"The size limit must be injectable as a parameter so tests can drive rotation with small payloads."*
- **Positive:** *"Rotation behavior must be testable with payloads small enough to trigger rotation in unit tests."*
- **Why:** The negative names a testability mechanism (parameter injection). The positive states the testability requirement; the coder chooses among parameter injection, an overridable static, a test-seam protocol, or another approach.

**Example 2 — API or framework name**
- **Negative:** *"Declare the panel scene via `WindowGroup` or `Window`, whichever is consistent with how the existing app declares scenes."*
- **Positive:** *"The panel must be a separate scene matching the scene-declaration convention already used in the app."*
- **Why:** The negative names specific platform APIs. The positive names the constraint (separate scene; convention-matching) and lets the coder read the existing app to choose.

**Example 3 — architectural-shape invention**
- **Negative:** *"`StateProvider` is a protocol that returns a `StateSnapshot` value type; the snapshot has nested value types covering [list]."*
- **Positive:** *"The panel content sections required: [list of sections from the plan]. The state-source design is the coder's choice."*
- **Why:** The negative invents a protocol-plus-snapshot-plus-nested-value-types composition pattern that did not appear in the implementation plan. The plan required panel content sections; the data-supply architecture is a coder decision.

**Example 4 — timing or lifecycle prescription**
- **Negative:** *"Poll the data source on a 1 Hz timer; suspend the timer when the window is not visible."*
- **Positive:** *"Panel data must reflect current state without measurable user-visible lag, and must not consume resources when the panel is hidden."*
- **Why:** The negative names a polling rate and a lifecycle mechanism. The positive names the observable requirements (freshness, idle behavior); the coder chooses polling vs. observation, rate, and visibility hook.

**Example 5 — Files-in-scope is NOT solution leakage (clarifying)**
- **This is scope, not solution:** *"Files in scope: `Data/Logging/FileLogSink.swift` (new), `Data/Logging/LogRotation.swift` (new)."* Paths come from the implementation plan and enforce existing layer discipline (logging belongs in `Data/`). They are location guardrails.
- **This crosses into solution:** *"Use `FileManager.default.url(for:in:)` to resolve the log directory."* This names an API choice the coder should make.
- **Why:** Files-in-scope lists relay scope from the architect / planner / plan. They tell the coder where the work lives and where it does not. They do not specify how the work is done. API and data-structure choices made *inside* those files are the coder's.

The per-agent table in the previous subsection enumerates which format requirements are allowed for each agent. When in doubt: ask the self-check question 2 below — "Am I describing what needs to be true, or how to do it?"
```

**Self-consistency self-check (the implementer re-reads the just-inserted subsection before moving to E3):** confirm the inserted text itself contains zero solution prescriptions. The Negative lines paraphrase real leakage and are explicitly framed as "do not write"; they do not prescribe behavior to any future PM chat. The Positive lines state requirements (testable / convention-matching / observable) without naming APIs or patterns. The Why lines name leakage categories (testability mechanism, API/framework name, architectural-shape invention, polling rate / lifecycle mechanism, scope vs. implementation distinction) — they do not prescribe how to fix leakage, only how to recognize it. The closing pointer references the per-agent table and the existing self-check question 2 — both already-published constraints, not new prescriptions. **Self-consistency: PASS.**

**Verification check for this edit:**

```bash
# Confirm the new subsection heading is present and well-positioned.
grep -n '^### Format-vs-solutions: worked examples' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit, between the current "Format requirements vs. solutions" subsection
# (line 649 area) and "### File-based reporting" (now ~line 730 area post-insert).

# Confirm all 5 example markers present.
grep -nE '^\*\*Example [1-5] — ' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 5 hits, in numeric order, all within the new subsection.

# Confirm the closing pointer is present.
grep -n 'Am I describing what needs to be true, or how to do it' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 2 hits — one in the new subsection's closing pointer, one in the existing
# self-check item 2 (around line 776 pre-edit; now shifted further down post-insert).

# Confirm File-based reporting heading still present and not accidentally removed.
grep -c '^### File-based reporting' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1.
```

### 5.3 Edit E3 — `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff cleanup

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md`
**Lines (current):** 259–287 (the three □ checklist items each carrying a prescriptive `Note:` block, plus the wrap-up `□ [Any other...]` item at lines 287–288).

**Local style observation:** the surrounding context (lines 256–290) is a placeholder list using `-` bullets and indented `□` checklist items. Each `□` item carries a short title line; the existing three problem items have an indented `Note:` block extending across multiple lines. The new pointer must match this `□` checklist style, not introduce a new prose paragraph.

**Before (current text, lines 256–289):**

```
- Architecture constraints: [LIST — include project-specific ones]
  - Architecture decisions required (architect must evaluate each and document
    the chosen approach AND rejected alternatives with rationale before
    producing any stub code):
      □ Heterogeneous domain collections: type-erasure wrappers / exhaustive
        enums / protocol elevation — which and why
          Note: Type-erasure wrappers that expose a .base accessor for downcasting
          to a concrete type are an LSP violation — they are runtime type
          interrogation disguised as abstraction. Protocol elevation (moving all
          needed behavior into the protocol as requirements) is the preferred
          approach. Exhaustive enums are preferred when the concrete type must be
          known at the call site and the set of types is fixed and internal.
      □ Domain state change notification: coarse broadcast / typed payload
        streams / observation framework — granularity, back pressure,
        actor-hop cost at expected update frequency
          Note: AsyncStream<Void> (contentless broadcast) forces every subscriber
          to perform an actor hop and re-fetch all state on every signal regardless
          of relevance. Typed payload streams (AsyncStream<ChangeType>) allow
          subscribers to filter by relevance before crossing actor boundaries.
          AsyncChannel from swift-async-algorithms is a competing-consumer
          rendezvous channel — it is NOT suitable for fan-out to multiple
          independent subscribers.
      □ ViewModel-to-navigation coupling: direct navigator injection /
        route-intent stream / closure-based — what the ViewModel emits vs.
        what the View layer executes
          Note: ViewModels must not import SwiftUI. A ViewModel that imports SwiftUI
          cannot be tested independently of a view hierarchy and violates the
          framework-independence goal. ViewModels must express navigation intent as
          output that the View layer consumes, including a typed stream or observable
          state property of a ViewModel-defined enum, a non-isolated closure injected
          by the caller, or a delegate protocol defined by the ViewModel. The ViewModel
          never holds or calls a navigator directly.
      □ [Any other correctness-sensitive structural decisions specific to
        this project]
```

**After (replacement text):**

```
- Architecture constraints: [LIST — include project-specific ones]
  - Architecture decisions required (architect must evaluate each and document
    the chosen approach AND rejected alternatives with rationale before
    producing any stub code):
      □ Heterogeneous domain collections: type-erasure wrappers / exhaustive
        enums / protocol elevation — which and why
      □ Domain state change notification: coarse broadcast / typed payload
        streams / observation framework — granularity, back pressure,
        actor-hop cost at expected update frequency
      □ ViewModel-to-navigation coupling: direct navigator injection /
        route-intent stream / closure-based — what the ViewModel emits vs.
        what the View layer executes
      □ [Any other correctness-sensitive structural decisions specific to
        this project]
      □ Before recording rationale on any of the above, the architect must
        read the universal rules constraining these decisions in `CLAUDE.md`,
        `AGENTS.md`, and `GEMINI.md` (LSP / capability-pattern / layer
        discipline / shared-state documentation), plus any active skills
        listed in the trinity `**Active skills:**` line (concurrency,
        platform architecture, language-specific rules). The PM chat does
        not pre-decide these structural choices in this checklist —
        per `supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked
        examples`, prescribing a structural answer in an architect prompt
        anchors the agent and is forbidden.
```

**Edit summary:** delete the three `Note:` blocks (lines 261–270 LSP note, 272–278 AsyncStream note, 281–286 ViewModel note); preserve the three `□` decision titles unchanged; preserve the existing `□ [Any other ...]` item; append one new `□` item at the end of the inner checklist that points the architect at the trinity files + active skills (per D2) and cross-references the new METHODOLOGY subsection.

**Trinity-symmetry check on the pointer:** the pointer text names all three trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) explicitly per D2. The architect's design recommendation cited only `CLAUDE.md`; this plan honors the project-lead modification to name all three (developer-readable; preserves trinity symmetry per CLAUDE.md trinity rule even though no trinity file is *edited*).

**Verification check for this edit:**

```bash
# Confirm the three deleted Note phrases are gone.
grep -c 'Type-erasure wrappers that expose a .base accessor' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0.
grep -c 'AsyncStream<Void>' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0.
grep -c 'ViewModels must not import SwiftUI' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0.

# Confirm the three checklist titles are preserved.
grep -c '□ Heterogeneous domain collections' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1.
grep -c '□ Domain state change notification' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1.
grep -c '□ ViewModel-to-navigation coupling' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1.

# Confirm the new pointer line is present and references all three trinity files + active skills + the new METHODOLOGY subsection.
grep -c 'CLAUDE.md.*AGENTS.md.*GEMINI.md' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 (the new pointer; no other line in pm-chat.md names all three).
grep -c 'active skills' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: ≥ 1 (at least the new pointer; possibly other pre-existing references).
grep -c 'Format-vs-solutions: worked examples' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 (the cross-reference in the new pointer).
```

### 5.4 Edit E4 — `project-template/skills/swift-best-practices/SKILL.md` — append AsyncStream + heterogeneous-collections entries

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md`
**Lines (current):** the file is 64 lines total. The last numbered entry is **38** ("Flag TODO comments older than six months..."), inside the `## Dead code and unused imports` section, ending at line 64. There is no trailing blank line in the source after entry 38 — the file ends at the period of entry 38's text.

**Insertion point:** end of file. Append a new H2 section heading `## Design choices` after the existing entry 38, then the two new numbered entries (39 and 40) using project-lead-approved verbatim wording.

**Numbering verification:** read of the file 2026-04-29 confirms entries 1–38 in this order:
- Type system: 1–5
- Immutability: 6–9
- Concurrency (Swift 6 strict): 10–16
- Error handling: 17–20
- Testing tooling: 21–23
- Style and idioms: 24–31
- Dead code and unused imports: 32–38

Last existing entry: **38**. New entries are therefore **39** and **40**.

**Why a new section (not append to existing sections):** topically, entry 39 (AsyncStream payload design) fits the Concurrency section (10–16) and entry 40 (heterogeneous collections / type-erasure / LSP) fits Type system (1–5) or Style and idioms (24–31). Inserting them topically would require renumbering entries 11–38 (entry 39 inserted into Concurrency) and 32–38 (entry 40 inserted into Style and idioms), shifting roughly 30 entry numbers and breaking every external reference to those entry numbers (if any exist in the pack docs or in user projects). Appending under a new `## Design choices` section preserves the existing numbering invariant — entries 1–38 keep their numbers; new entries are 39 and 40 — at the cost of slight topical scatter (concurrency-related advice in two sections rather than one). The numbering-stability gain outweighs the topical-clustering loss.

**Local style observations (from reading the existing file):**
- Section headings use `## H2 Capitalized first word, lowercase rest` (e.g., `## Type system`, `## Dead code and unused imports`).
- Each numbered entry begins on a new line as `N. Sentence.` — number, period, space, sentence-cased text, trailing period at end of each sentence.
- Multi-sentence entries continue on the same logical line wrapped to the column the editor renders; subsequent sentences are still part of the same numbered item.
- Continuation lines (when an entry wraps across rendered lines via `\n` in source) are NOT indented in this file's source — each numbered entry occupies one source line that may be very long. (Verified by reading entries 4, 13, 23, 34 — all single-source-line.)
- Entries within a section are NOT separated by blank lines (verified entries 32–38 are consecutive lines).
- Sections ARE separated from the next section by a single blank line, then the next `## Heading` (verified between sections via offset reads of lines 5–7, 21–23, 38–40, etc.).

**Insert text (paste verbatim — append after the last character of entry 38, with a leading blank line and section heading; new entries on single source lines per local style):**

```markdown

## Design choices

39. AsyncStream payload design — choose by subscriber filtering needs. Typed payload streams (`AsyncStream<ChangeType>`) let subscribers filter by relevance before crossing actor boundaries. Content-less broadcast (`AsyncStream<Void>`) forces every subscriber to actor-hop and re-fetch state on every signal regardless of relevance. AsyncChannel (swift-async-algorithms) is a competing-consumer rendezvous channel — not a fan-out broadcast. Weigh subscriber count, payload size, filtering needs, and back-pressure characteristics at design time.
40. Heterogeneous domain collections — protocol elevation over type-erasure-with-downcasting. Type-erasure wrappers that expose a `.base` accessor for downcasting to a concrete type are an LSP violation: runtime type interrogation disguised as abstraction. Prefer protocol elevation (move all needed behavior into the protocol as requirements) when callers should remain concrete-type-agnostic. Use exhaustive enums when the concrete type must be known at call sites and the type set is fixed and internal to the module.
```

**Style-conformance note:** the project-lead-approved wording was provided as multi-line text with indented continuation. The pack's local style for this file is single-source-line entries (per verification above). The semantics, period placement, and verbatim phrase content are preserved exactly; only the source-line wrapping is adjusted to match the file's local convention. No words added; no words removed; no words paraphrased. If the project lead prefers the multi-line wrapped form (for diff readability) over the single-line form (for local-style consistency), surface as a follow-up flag-back; the default per local-style-match is single-source-line.

**Verification check for this edit:**

```bash
# Confirm the new section heading is present.
grep -n '^## Design choices' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 hit, on a new line near end of file.

# Confirm both new numbered entries present in numeric order.
grep -nE '^(39|40)\. ' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 2 hits, line numbers consecutive or near-consecutive, in order 39 then 40.

# Confirm key phrases present verbatim.
grep -c 'AsyncStream<ChangeType>' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 (only in new entry 39).
grep -c 'AsyncStream<Void>' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 (only in new entry 39 — was 0 before E4).
grep -c 'competing-consumer' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 (new entry 39).
grep -c 'protocol elevation' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 (new entry 40).
grep -c '\.base accessor for downcasting' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 (new entry 40).

# Confirm the existing entries 1–38 are unchanged (no accidental renumbering).
grep -cE '^[0-9]+\. ' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 40 (was 38; +2 new).
grep -nE '^38\. Flag TODO comments older than six months' \
  /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/skills/swift-best-practices/SKILL.md
# Expect: 1 hit, line ~64 (entry 38 unchanged).
```

### 5.5 Edit C3 — append §12 to `maintenance-docs/V10-PHASE-4-VERIFICATION.md`

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/maintenance-docs/V10-PHASE-4-VERIFICATION.md`
**Insertion point:** end of file (current last line: 1106). Append the new `## §12 Delta verification — F-G patch` section after the existing `## §11` section (which ends at line 1106 with the F-A / F-G pending note).

**Section template (paste verbatim, fill bracketed values):**

```markdown

## §12 Delta verification — F-G patch

**Date:** [ISO 8601 UTC timestamp]
**Patch commits:** [C1 short SHA] (design + plan docs), [C2 short SHA] (3-file behavioral patch — METHODOLOGY + pm-chat.md + swift-best-practices SKILL.md per FB-3 resolution), [C3 short SHA — this commit]
**Scope:** Delta-only re-verification per project-lead Decision 2 and FB-3 resolution. Confirms the new METHODOLOGY § Format-vs-solutions: worked examples subsection landed; the per-agent table gained the pm-chat row; pm-chat.md Variant: generate-agent-kickoff Notes deletion + trinity+skills pointer landed; the swift-best-practices SKILL.md gained new entries 39 (AsyncStream payload design) and 40 (heterogeneous domain collections — protocol elevation over type-erasure); pack-distribution propagation works for fresh-init (METHODOLOGY, prompts/, and skills/ all copy correctly to docs/pack/ and to the tool-specific .claude/skills/, .codex/skills/, .gemini/skills/ dirs). Full §4.6 / §4.7 / §4.8 NOT re-run; historical evidence retained as-was.

### §12.1 Static checks — METHODOLOGY landings

- New subsection heading `### Format-vs-solutions: worked examples` present in `supporting-docs/METHODOLOGY.md`: [OK].
- All 5 example markers (`**Example 1 — `, `**Example 2 — `, `**Example 3 — `, `**Example 4 — `, `**Example 5 — `) present in numeric order: [OK].
- Closing pointer references self-check question 2 (`Am I describing what needs to be true, or how to do it`): [OK].
- New per-agent table row for `pm-chat` present at end of table (after `tester` row, before update-note line): [OK].
- Existing 8 agent rows (`architect`, `auditor`, `coder`, `docs-researcher`, `planner`, `repo-ops`, `reviewer`, `tester`) all preserved unchanged: [OK].
- Subsection ordering preserved: `### Format requirements vs. solutions` → `### Format-vs-solutions: worked examples` → `### File-based reporting`: [OK].

### §12.2 Static checks — pm-chat.md cleanup

- Three deleted Note phrases gone (`Type-erasure wrappers that expose a .base accessor`, `AsyncStream<Void>`, `ViewModels must not import SwiftUI`): all 3 [OK].
- Three □ checklist titles preserved (`Heterogeneous domain collections`, `Domain state change notification`, `ViewModel-to-navigation coupling`): all 3 [OK].
- New pointer line present and names all three trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) plus `active skills`: [OK].
- New pointer cross-references new METHODOLOGY subsection (`Format-vs-solutions: worked examples`): [OK].
- Existing `□ [Any other correctness-sensitive structural decisions specific to this project]` item preserved: [OK].

### §12.3 Self-consistency check — new METHODOLOGY subsection

Re-read `### Format-vs-solutions: worked examples` end-to-end after edit. Confirm:
- No Negative or Positive lines name a specific API, framework symbol, library, or pattern as a *prescription* (Negative lines name them only to mark "don't write this"; Positive lines name only requirements / constraints).
- No Why line prescribes how to fix leakage (Why lines name categories only).
- The closing pointer references already-published constraints (per-agent table; self-check question 2), not new prescriptions.

**Result:** [PASS — the new subsection itself is constraint specification, not solution prescription].

### §12.4 Pack-distribution propagation

- Fresh init harness:
  - Fixture: `/tmp/v10-fg-fixtures/fresh-init/` (fresh git-init repo with seed README).
  - `init-project.sh` exit: [0].
  - `docs/pack/METHODOLOGY.md` present in fixture: [OK].
  - New subsection `### Format-vs-solutions: worked examples` present in fixture's `docs/pack/METHODOLOGY.md`: [OK].
  - New per-agent table `pm-chat` row present in fixture's `docs/pack/METHODOLOGY.md`: [OK].
  - `docs/pack/prompts/pm-chat.md` present in fixture: [OK].
  - Three deleted Note phrases absent from fixture's `docs/pack/prompts/pm-chat.md`: [OK].
  - New pointer line present in fixture's `docs/pack/prompts/pm-chat.md`: [OK].

### §12.4-bis SKILL propagation to tool-specific skill dirs (FB-3 resolution evidence)

- Canonical edit:
  - `project-template/skills/swift-best-practices/SKILL.md` total numbered entries: [40] (was 38; +2 new — entries 39 and 40).
  - New `## Design choices` section heading present at end of file: [OK].
  - Entry 39 (`AsyncStream payload design — choose by subscriber filtering needs.`) verbatim project-lead-approved wording present: [OK].
  - Entry 40 (`Heterogeneous domain collections — protocol elevation over type-erasure-with-downcasting.`) verbatim project-lead-approved wording present: [OK].
  - Verbatim phrase `AsyncStream<Void>` appears in canonical SKILL.md: [1 hit, in entry 39].
  - Verbatim phrase `protocol elevation` appears in canonical SKILL.md: [1 hit, in entry 40].
  - Pre-existing entries 1 and 38 unchanged (sanity check that no renumbering occurred): [OK].
- Tool-specific skill-dir propagation in fresh-init fixture:
  - `.claude/skills/swift-best-practices/SKILL.md`: [PRESENT / ABSENT (init-script conditional)] — if present, all six SKILL assertions above also pass: [OK].
  - `.codex/skills/swift-best-practices/SKILL.md`: [PRESENT / ABSENT (init-script conditional)] — if present, all six SKILL assertions above also pass: [OK].
  - `.gemini/skills/swift-best-practices/SKILL.md`: [PRESENT / ABSENT (init-script conditional)] — if present, all six SKILL assertions above also pass: [OK].
  - `diff` between canonical SKILL.md and each populated tool-specific copy: [byte-identical / known-tool-specific-transform-only].
- Cross-reference: `grep -rn "AsyncStream<Void>" project-template supporting-docs` returns exactly 1 hit (in `project-template/skills/swift-best-practices/SKILL.md`); 0 hits in `project-template/docs/pack/prompts/pm-chat.md`. The substantive lesson is preserved in its canonical home; the prompt template no longer carries the prescriptive Note.

### §12.5 Pack-level regression guards

- `python3 scripts/validate-pack.py` exit: [0].
  - Check 6 (Prompts-directory format) on `pm-chat.md`: [PASS] — frontmatter and variant→H2 consistency unaffected by checklist-content edits.
  - Check 10 (Prompt template triad compliance) on every variant in `pm-chat.md`: [PASS] — `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and file-based completion-report markers untouched in every variant.
- `bash scripts/test-detect.sh` exit: [0]; reports [34/34] passing.

### §12.6 Trinity-rule check

- `git diff project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` returns empty: [OK].
- The pm-chat.md pointer line names all three trinity files; trinity files are read-targets only and are not edited. Trinity-symmetry preserved.

### §12.7 Sanitization

All fixtures synthetic — built under `/tmp/v10-fg-fixtures/`. No OT content involved. No sanitization required per §6.7.7 rules. Live OT clone untouched (no OT_LIVE rev-parse occurred during this delta). Worked examples in METHODOLOGY are phase-anonymous per project-lead Decision 4 (OQ-F-G-3) — no `Phase 28` / `Phase 32` cites.

### §12.8 Cleanup

- `rm -rf /tmp/v10-fg-fixtures` executed; directory absent. [OK].

### §12.9 Pass / fail summary

| Check | Result |
|---|---|
| METHODOLOGY new subsection landed (heading + 5 examples + closing pointer) | [PASS] |
| METHODOLOGY per-agent table pm-chat row landed | [PASS] |
| pm-chat.md three Notes deleted | [PASS] |
| pm-chat.md new pointer present (trinity + active skills + METHODOLOGY cross-ref) | [PASS] |
| swift-best-practices SKILL.md new `## Design choices` section + entries 39 and 40 landed verbatim (FB-3 resolution) | [PASS] |
| AsyncStream<Void> phrase migrated from pm-chat.md (0 hits post-E3) to swift-best-practices SKILL entry 39 (1 hit post-E4) | [PASS] |
| New METHODOLOGY subsection self-consistency (no solution leakage in the rule itself) | [PASS] |
| Fresh-init propagation (METHODOLOGY + pm-chat.md + swift-best-practices SKILL.md all correct in fixture, including tool-specific .claude/.codex/.gemini skill-dir copies where init populates them) | [PASS] |
| validate-pack.py | [PASS exit 0] |
| test-detect.sh | [PASS 34/34] |
| Trinity-rule (no trinity edits; SKILL edit is in project-template/skills/, not a trinity file; CLAUDE.md line 395 untouched) | [PASS empty diff] |

**Outcome:** **F-G resolved.** Worked examples make the format-vs-solutions rule pattern-matchable; the per-agent table covers PM-chat self-prompts; the canonical pm-chat.md template no longer reproduces the leakage pattern in its own checklist; the substantive AsyncStream payload-design and type-erasure-vs-protocol-elevation lessons land in their canonical home (swift-best-practices SKILL entries 39 and 40), so E3's pointer text is honest about what active skills carry. **FB-3 resolved** in the same patch (project-lead chose Option (a) expanded scope).

### §12.10 Flag-back updates

- **F-G → RESOLVED** (worked examples + per-agent table extension + pm-chat.md self-consistency cleanup + swift-best-practices SKILL entries 39/40 preserving substantive AsyncStream and type-erasure lessons).
- **FB-3 → RESOLVED** (project-lead chose Option (a) expanded scope; executed by E4 in same C2 commit).
- **OQ-2 trinity-asymmetry follow-up (anti-patterns symmetry between CLAUDE.md line 395 and AGENTS.md/GEMINI.md)** — **NOT addressed by this patch**; remains a separate / non-F-G concern. Implicitly mitigated by the substantive content now living in the swift-best-practices skill (read by all three tools via skill-loading), so the trinity one-liner asymmetry is lower-impact than originally scoped.
- **F-A** still pending v10.0 patch.
```

---

## 6. Per-commit verification checklist

Adapted from `V10-PHASE-4-PLAN.md` Part 7 / `V10-F-E-F-F-PLAN.md` §6 shape, specialized for this patch.

### 6.1 Pre-C2-commit checks

```
[ ] git status                          — staged files match the 3 listed in §3.1:
       supporting-docs/METHODOLOGY.md
       project-template/docs/pack/prompts/pm-chat.md
       project-template/skills/swift-best-practices/SKILL.md
[ ] git diff --stat                     — METHODOLOGY ~+50 lines net (1 row + ~45 line subsection); pm-chat.md ~−24 / +9 net; SKILL.md ~+4 lines net (1 blank + 1 heading + 2 entries).
[ ] git diff --name-only                — exactly the 3 files; no surprise additions.
[ ] §5.1 grep checks (E1)               — all expected hit-counts match.
[ ] §5.2 grep checks (E2)               — all expected hit-counts match.
[ ] §5.4 grep checks (E4)               — all expected hit-counts match (note ordering: E4 verification runs BEFORE E3 verification per the E1→E2→E4→E3 edit order; SKILL.md must show entries 39 and 40 present and verbatim phrases match).
[ ] §5.3 grep checks (E3)               — all expected hit-counts match.
[ ] python3 scripts/validate-pack.py    — exits 0.
[ ] bash scripts/test-detect.sh         — exits 0; reports 34/34 passing.
[ ] Self-consistency re-read            — implementer reads the new METHODOLOGY worked-examples subsection top-to-bottom and confirms no solution prescription. Per §5.2 inline self-check.
[ ] Trinity rule N/A                    — `git diff project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` returns empty. (E4 edits the swift-best-practices skill, NOT a trinity file — confirm no trinity diff slipped in.)
[ ] Cross-reference audit               — `grep -rn "AsyncStream<Void>" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs` returns exactly 1 hit in `project-template/skills/swift-best-practices/SKILL.md` (the new entry 39); 0 hits in `pm-chat.md`. `grep -rn "Type-erasure wrappers that expose a .base" ...` returns 0 hits in `pm-chat.md`; the new entry 40 uses the rephrased "`.base` accessor for downcasting" wording. `grep -rn "ViewModels must not import SwiftUI" ...` returns 0 hits in `pm-chat.md` (this lesson is intentionally not preserved in skills per §3.5). Trinity LSP content (CLAUDE/AGENTS/GEMINI lines around 172/96/129) untouched. CLAUDE.md line 395 anti-pattern bullet untouched.
[ ] §7 delta harness                    — fresh-init fixture build passes; output captured to /tmp; ready for §12 evidence section. The harness includes new §11.4 / §12.4 assertions for SKILL propagation to the 3 tool-specific skill dirs.
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`.
```

### 6.2 Post-C2-commit checks

```
[ ] git log --oneline -1                — commit message matches §8 spec.
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm post-commit).
[ ] gh run watch                        — Validate Pack workflow green on v10-dev branch.
```

### 6.3 Pre-C3-commit checks

```
[ ] §7 harness output captured to /tmp/v10-fg-fixtures/fresh-init.{stdout,stderr}.txt.
[ ] §12 section drafted with bracketed values filled from §7 outputs.
[ ] git diff maintenance-docs/V10-PHASE-4-VERIFICATION.md — only an append; no edits to existing §1–§11 content.
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`.
```

**If validate-pack.py fails post-C2:** roll back per established pattern (`git reset --soft HEAD~1`), fix, recommit. Pack must remain working at every intermediate commit.

---

## 7. Verification harness — delta evidence

Per established F-D / F-E+F-F precedent (delta-only re-verification). Full §4.6 / §4.7 / §4.8 NOT re-run.

This patch is text-only (no script changes), so harness scope is much smaller than F-D. The harness verifies (a) METHODOLOGY content propagates correctly to a fresh-init project, and (b) pm-chat.md content propagates correctly to a fresh-init project. State A/B/C/D matrix from F-D is NOT applicable (no migration-path interaction here — METHODOLOGY and prompts/ already propagate via the existing copy paths that F-D confirmed work; this patch only changes the *content* of those files).

**Decision:** Single fresh-init harness sufficient. No migration harness required (the migration script does not parse METHODOLOGY content or prompts/ content; it copies them whole).

**All operations within `/tmp/`. Live OT untouched. Live pack on `main` untouched.**

### 7.1 Pre-flight — pack repo state

```bash
cd /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
git status --porcelain        # Expect: empty (post-C2-commit) or only the 2 patched files (pre-C2-commit on staged tree).
git rev-parse HEAD            # Capture for §12 evidence.
PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
```

### 7.2 Fixture base directory

```bash
mkdir -p /tmp/v10-fg-fixtures
cd /tmp/v10-fg-fixtures
```

### 7.3 §12.4 — Fresh-init propagation harness

```bash
mkdir -p /tmp/v10-fg-fixtures/fresh-init
cd /tmp/v10-fg-fixtures/fresh-init
git init -q
echo "# fresh-init test fixture (F-G)" > README.md
git add README.md && git commit -q -m "seed"

PACK="$PACK" "$PACK/scripts/init-project.sh" . \
  > /tmp/v10-fg-fixtures/fresh-init.stdout.txt 2> /tmp/v10-fg-fixtures/fresh-init.stderr.txt
echo "init-project.sh exit: $?"

# Assert METHODOLOGY landed at docs/pack and carries the new subsection + per-agent table row.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present" || echo "FAIL"
grep -q '^### Format-vs-solutions: worked examples' docs/pack/METHODOLOGY.md \
  && echo "OK: new subsection present" || echo "FAIL"
[[ $(grep -cE '^\*\*Example [1-5] — ' docs/pack/METHODOLOGY.md) == 5 ]] \
  && echo "OK: 5 examples present" || echo "FAIL"
grep -q '^| `pm-chat` (self-prompt)' docs/pack/METHODOLOGY.md \
  && echo "OK: per-agent table pm-chat row present" || echo "FAIL"

# Assert pm-chat.md cleanup landed.
[[ -f docs/pack/prompts/pm-chat.md ]] && echo "OK: pm-chat.md present" || echo "FAIL"
[[ $(grep -c 'AsyncStream<Void>' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: AsyncStream<Void> Note gone" || echo "FAIL"
[[ $(grep -c 'Type-erasure wrappers that expose a .base accessor' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: LSP Note gone" || echo "FAIL"
[[ $(grep -c 'ViewModels must not import SwiftUI' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: ViewModel Note gone" || echo "FAIL"
grep -q 'CLAUDE.md.*AGENTS.md.*GEMINI.md' docs/pack/prompts/pm-chat.md \
  && echo "OK: trinity pointer present" || echo "FAIL"
grep -q 'active skills' docs/pack/prompts/pm-chat.md \
  && echo "OK: active-skills pointer present" || echo "FAIL"
grep -q 'Format-vs-solutions: worked examples' docs/pack/prompts/pm-chat.md \
  && echo "OK: METHODOLOGY cross-ref present" || echo "FAIL"
```

### 7.4 §12.4-bis — SKILL propagation to tool-specific skill dirs

This subsection verifies that the new entries 39 and 40 added to `project-template/skills/swift-best-practices/SKILL.md` propagate via `init-project.sh` to all three tool-specific skill directories that the init script populates: `.claude/skills/`, `.codex/skills/`, and `.gemini/skills/`. (The fresh-init harness in §7.3 already verifies the canonical `docs/pack/` copy; this subsection adds the tool-specific propagation assertions per the F-G amendment scope.)

```bash
# Reuse the §7.3 fresh-init fixture (do NOT re-init).
cd /tmp/v10-fg-fixtures/fresh-init

# Determine which tool-specific skill dirs init-project.sh actually populated.
# (init-project.sh stages may be conditional; the harness asserts only on dirs that exist.)
for dir in .claude/skills .codex/skills .gemini/skills; do
  if [[ -d "$dir/swift-best-practices" ]]; then
    echo "DIR PRESENT: $dir/swift-best-practices"
    skill_file="$dir/swift-best-practices/SKILL.md"
    [[ -f "$skill_file" ]] && echo "  OK: SKILL.md present" || { echo "  FAIL: SKILL.md missing"; continue; }
    grep -q '^## Design choices' "$skill_file" \
      && echo "  OK: '## Design choices' section present" || echo "  FAIL: section missing"
    grep -q '^39\. AsyncStream payload design' "$skill_file" \
      && echo "  OK: entry 39 present" || echo "  FAIL: entry 39 missing"
    grep -q '^40\. Heterogeneous domain collections' "$skill_file" \
      && echo "  OK: entry 40 present" || echo "  FAIL: entry 40 missing"
    grep -q 'AsyncStream<Void>' "$skill_file" \
      && echo "  OK: AsyncStream<Void> verbatim phrase present" || echo "  FAIL: phrase missing"
    grep -q 'protocol elevation' "$skill_file" \
      && echo "  OK: 'protocol elevation' phrase present" || echo "  FAIL: phrase missing"
    # Confirm pre-existing entries unaffected.
    grep -q '^38\. Flag TODO comments older than six months' "$skill_file" \
      && echo "  OK: entry 38 unchanged" || echo "  FAIL: entry 38 corrupted"
    grep -q '^1\. Prefer .struct. for all model and data types' "$skill_file" \
      && echo "  OK: entry 1 unchanged" || echo "  FAIL: entry 1 corrupted"
    # Total entry count.
    n=$(grep -cE '^[0-9]+\. ' "$skill_file")
    [[ "$n" == "40" ]] && echo "  OK: 40 numbered entries total" || echo "  FAIL: entry count = $n (expected 40)"
  else
    echo "DIR ABSENT: $dir/swift-best-practices  (init-project.sh did not populate this tool-specific copy in this fixture; not a failure if init logic is conditional)"
  fi
done

# Cross-check: the canonical project-template copy and any populated tool-specific copies must agree on the new entries.
canonical="$PACK/project-template/skills/swift-best-practices/SKILL.md"
for dir in .claude/skills .codex/skills .gemini/skills; do
  if [[ -f "$dir/swift-best-practices/SKILL.md" ]]; then
    if diff -q "$canonical" "$dir/swift-best-practices/SKILL.md" > /dev/null; then
      echo "OK: $dir/swift-best-practices/SKILL.md byte-identical to canonical"
    else
      echo "INFO: $dir/swift-best-practices/SKILL.md differs from canonical (may be expected if init-project.sh applies tool-specific transforms; review diff)"
      diff "$canonical" "$dir/swift-best-practices/SKILL.md" | head -40
    fi
  fi
done
```

**Acceptance criteria:** for every tool-specific skill dir that `init-project.sh` populates with `swift-best-practices/SKILL.md`, the file must contain entries 39 and 40 verbatim, the new `## Design choices` section heading, the verbatim phrases `AsyncStream<Void>` and `protocol elevation`, and 40 total numbered entries. Pre-existing entries 1 and 38 must be unchanged. If `init-project.sh` is conditional (e.g., copies skills only for tools selected during init), the assertions apply only to populated dirs. If a populated copy diverges from the canonical, the diff must be expected (e.g., a known tool-specific transform); unexpected divergence is a FAIL and triggers diagnosis before C2 commits.

### 7.5 §12.5 — Pack-level regression guards

```bash
cd "$PACK"
python3 scripts/validate-pack.py
echo "validate-pack.py exit: $?"           # Expect: 0
bash scripts/test-detect.sh
echo "test-detect.sh exit: $?"             # Expect: 0; reports 34/34 passing
```

### 7.6 §12.8 — Cleanup

```bash
rm -rf /tmp/v10-fg-fixtures
ls -ld /tmp/v10-fg-fixtures 2>&1
# Expect: "No such file or directory"
```

### 7.7 Evidence destination

The §12 evidence section is appended to `maintenance-docs/V10-PHASE-4-VERIFICATION.md` after the existing `## §11` section (current last line: 1106). Template per §5.4. The C3 commit lands the appended section.

---

## 8. Commit messages (proposed)

Per CLAUDE.md commit message format and the F-D / F-E+F-F precedent.

### 8.1 C1 commit message

```
docs: v10 — V10-F-G design + plan (solution leakage in PM-chat prompts)

Architect (V10-F-G-DESIGN.md) and planner (V10-F-G-PLAN.md) outputs
for F-G — PM-chat-generated coder prompts cross from format/scope into
solution territory in several places. Decision: add a worked-examples
subsection to METHODOLOGY § Prompt Authoring Principles; extend the
per-agent table to cover pm-chat self-prompts (project-lead reversal
of OQ-F-G-2); clean up pm-chat.md Variant: generate-agent-kickoff
Notes that anchor the architect agent (project-lead modification of
OQ-F-G-1 — pointer references all three trinity files + active
skills, not just CLAUDE.md).

No source files modified by this commit. Behavioral patch lands in
the next commit.
```

### 8.2 C2 commit message

```
feat: v10 — BD-NNN F-G worked examples + pm-chat.md self-consistency

Resolves F-G (solution leakage in PM-chat-generated prompts) per
V10-F-G-DESIGN.md (architect 2026-04-29; project-lead approved with
two modifications) and V10-F-G-PLAN.md (planner 2026-04-29).

Files touched:
  supporting-docs/METHODOLOGY.md
    — new ### Format-vs-solutions: worked examples subsection
      (5 examples, Negative/Positive/Why; phase-anonymous)
    — per-agent table extended with pm-chat (self-prompt) row
      covering inheritance of target-agent solution constraints
  project-template/docs/pack/prompts/pm-chat.md
    — Variant: generate-agent-kickoff: deleted three prescriptive
      Notes (LSP / AsyncStream<Void> / ViewModel-import-SwiftUI)
      that anchored the architect agent
    — added one checklist pointer item directing the architect to
      read CLAUDE.md / AGENTS.md / GEMINI.md and active skills for
      the universal rules constraining the structural decisions

Trinity rule: clean — pm-chat.md pointer references the trinity
files but does not edit them. CLAUDE.md / AGENTS.md / GEMINI.md
LSP content (lines ~172 / 96 / 129) is canonical and unchanged.

Verification: §12 delta-evidence harness in V10-PHASE-4-VERIFICATION.md
(separate docs: commit) — fresh-init propagation passes; the new
METHODOLOGY subsection is itself solution-prescription-free
(self-consistency re-read confirmed); validate-pack.py exits 0;
test-detect.sh 34/34.

BD-NNN to be assigned at C-V10-18 BACKLOG sweep.
```

### 8.3 C3 commit message

```
docs: v10 — V10-PHASE-4-VERIFICATION §12 delta evidence (F-G)
```

---

## 9. Risks and assumptions

### 9.1 Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 (RESOLVED) | The `AsyncStream<Void>` and type-erasure/LSP substantive content currently in `pm-chat.md` Notes is NOT separately preserved in `swift-best-practices` or `apple-architecture-core` skills (the architect's design §4.4 assumed it might be there or could be relocated; D2 chose deletion + pointer over relocation). After this patch, the substantive concurrency and type-erasure guidance would not exist in any pack-distributed file. | Medium — confirmed true per the cross-reference audit (§3.5) before FB-3 surfaced. | **RESOLVED by E4** (project-lead resolution of FB-3 — see §9.3): the substantive AsyncStream payload-design lesson lands as `swift-best-practices` SKILL entry 39, and the type-erasure-vs-protocol-elevation lesson lands as entry 40, both in the same C2 commit. The pointer in pm-chat.md (E3) now genuinely references content that exists. The "ViewModels must not import SwiftUI" lesson is the only deleted-Note content NOT preserved by this patch — it is a layer-discipline concrete that the apple-architecture-core skill's general layer rules already cover at the principle level. |
| R2 | The new METHODOLOGY worked-examples subsection itself contains solution prescription (an ironic regression — the F-G fix introducing F-G). | Low | §5.2 inline self-consistency check + §6.1 pre-commit re-read step. The §12.3 evidence row records the verification. |
| R3 | Check 10 (Prompt template triad compliance) fails because the pm-chat.md edit accidentally removes one of the four required markers from a variant. | Very low | The edit is inside the Files-in-scope/placeholder list of the generate-agent-kickoff variant, not inside its `**Problem:**` / `**Goal:**` / `**Success criteria:**` / `**Completion report:**` sections (those are at lines 229–248 / 298–303 area, well outside the 259–287 edit window). §6.1 includes `python3 scripts/validate-pack.py` as a pre-commit gate. |
| R4 | The new per-agent table pm-chat row is read by future maintainers as elevating pm-chat to "agent" status, contradicting `pm-chat.md` line 12. | Low | The row's Agent column reads `pm-chat (self-prompt)` (with the parenthetical), and the row is placed last (after the alphabetical agent block) per §5.1's placement-decision rationale. The "self-prompt" qualifier and trailing position together signal pm-chat's distinct status. |
| R5 | Line numbers in `supporting-docs/METHODOLOGY.md` drift between E1 and E2 (E1 inserts one row, shifting downstream lines by one). The implementer applies E2 by anchoring on absolute line 691 instead of on content. | Low | §5.2 explicitly notes the line drift and instructs the implementer to anchor on content ("The architect diagnoses and proposes." → blank → `### File-based reporting`), not on the absolute line number. |
| R6 | CI (`Validate Pack` GitHub Actions workflow) does not exercise content propagation through `init-project.sh`, only validate-pack.py. So the §7 fresh-init harness must be run locally. | Medium — known CI shape limitation. | The §7 harness IS the verification. Implementer runs it; project lead reviews evidence. CI is a regression backstop, not the primary gate. |

### 9.2 Assumptions

| # | Assumption | Resolution |
|---|---|---|
| A1 | `## Prompt Authoring Principles` subsection ordering at the time of edit matches the architect's §2.1 enumeration (subsection 4 → 4a → 5 placement). | **Confirmed** — METHODOLOGY lines 649 (`### Format requirements vs. solutions`), 691 ("Architect prompts — stronger restriction" closing), 693 (`### File-based reporting`) read 2026-04-29. |
| A2 | Per-agent table at lines 674–684 is the only such table in METHODOLOGY (no other pm-chat row already exists somewhere else). | **Confirmed** — `grep -nE '^\| \`(pm-chat\|architect)' supporting-docs/METHODOLOGY.md` returns 1 hit (architect at line 676); no pm-chat row anywhere. |
| A3 | The three Notes in pm-chat.md (lines 261–286) are the only solution-leakage source in the prompt templates per design §4.2 audit. | **Confirmed** — design §4.2 audited all 4 prompt files / 13 variants and identified only this one cleanup. Spot-check additions during this plan (re-read coder.md / architect.md headers) found no additional leakage. |
| A4 | `validate-pack.py` Check 6 does not inspect prompt-variant body content beyond frontmatter + variant→H2 mapping. | **Confirmed** — Check 6 source (validate-pack.py lines 283–393) reads frontmatter and matches `## Variant: ` headings against frontmatter `variants:` list. Body content of variants is not parsed. |
| A5 | `validate-pack.py` Check 10 verifies the four triad markers per variant; the pm-chat.md edit window (lines 259–287, inside the placeholder list) is well outside the variant's triad sections (Problem at line 229, Goal at 232, Success criteria at 236, Completion report at 298). | **Confirmed** by reading pm-chat.md offset 200–300. |
| A6 | The trinity LSP rule lines (`CLAUDE.md` line 172, `AGENTS.md` line 96, `GEMINI.md` line 129) are present and trinity-symmetric so the pm-chat.md pointer's reference to all three is honest. | **Confirmed** — grep for `Liskov` / `LSP` / `Substitution` returns matching headings in all three files at the cited lines. |
| A7 | Active skills line (`**Active skills:**`) exists in trinity per V10-F-E-F-F-PLAN.md Procedure 5-S Task B, and is therefore an appropriate pointer target. | **Confirmed** — the line is part of the trinity content; project-lead D5 confirmed Task B handles its placeholder reconciliation. |

### 9.3 Flag-backs (conditions where implementer pauses)

The implementer MUST flag-back to the parent agent before proceeding if:

- **FB-1.** `validate-pack.py` Check 6 or Check 10 fails after E3 lands. Diagnose before proceeding to commit; the edit may have inadvertently shifted a frontmatter line or removed a triad marker.
- **FB-2.** The §5.2 self-consistency re-read of the new METHODOLOGY subsection identifies any line that prescribes a solution (introduces the very leakage F-G is fixing). Pause; revise; re-read; do not commit until clean.
- **FB-3 (RESOLVED — project-lead chose Option (a), expanded scope).** Original concern: cross-reference audit confirms `AsyncStream<Void>` content exists *only* in pm-chat.md and nowhere in the skills; deletion-with-pointer would remove the substantive concurrency guidance from the pack entirely. **Resolution:** project-lead chose **Option (a) preserve in skills**, and expanded scope to cover BOTH the AsyncStream payload-design lesson (Note 2) AND the LSP / type-erasure lesson (Note 1) in the same `swift-best-practices` SKILL.md addition. Implementation: E4 in §5.4. The original Option (b) (defer to v10.1 BACKLOG) and Option (c) (accept the loss) are NOT taken. The trinity-asymmetry sub-concern (CLAUDE.md line 395 has the type-erasure anti-pattern as a one-liner; AGENTS.md/GEMINI.md do not) is implicitly resolved: the substantive content now lives in the swift-best-practices skill where all three tools read it via the existing skill-loading mechanism. The trinity one-liner asymmetry on anti-patterns remains a separate / non-F-G concern and is NOT addressed by this patch. **No flag-back needed during implementation** — execute E4 per §5.4 specification.
- **FB-4.** Trinity-rule `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns non-empty. The plan asserts no trinity edits — any trinity diff is unexpected and requires diagnosis before commit.
- **FB-5.** The §7.3 fresh-init harness fails any assertion. Do NOT commit C2 (or, if already committed, do NOT commit C3) before the failure is diagnosed.

---

## 10. Cascading-effect checks

### 10.1 Will the new METHODOLOGY subsection trigger validate-pack.py Check 6?

**Answer: NO.** Check 6 (`scripts/validate-pack.py` lines 283–393) inspects `project-template/docs/pack/prompts/*.md` files only — it does not read `supporting-docs/METHODOLOGY.md`. The new subsection adds content to METHODOLOGY, which Check 6 ignores.

### 10.2 Will the per-agent table pm-chat row interact with any existing agent-routing check?

**Answer: NO.** Check 5 (Agent file count consistency, validate-pack.py lines 240–280) compares filenames in `.claude/agents/`, `.codex/prompts/`, and `.gemini/`. The METHODOLOGY per-agent table is documentation, not enumerated by Check 5. Check 7 (Pack agent roster, lines 397–446) compares `PM-CHAT.md` `## Pack agent roster` against `.claude/agents/*.md` stems — also not interacting with METHODOLOGY content.

### 10.3 Will the pm-chat.md Notes deletion break Check 6 or Check 10?

**Check 6 (Prompts-directory format):** verifies frontmatter + variant→H2 consistency. The deletion is inside the body of an existing variant, well after the frontmatter and well within (not crossing) the `## Variant: generate-agent-kickoff` H2. **No breakage.**

**Check 10 (Prompt template triad compliance):** verifies every in-scope variant in `project-template/docs/pack/prompts/*.md` (excluding the kickoff variant identified by `**Convention exception:**`) contains `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and a file-based completion-report indicator (`REPORT FILE:` or `**Completion report:**`).

The Variant: generate-agent-kickoff section's triad markers are at:
- `**Problem:**` — line 229.
- `**Goal:**` — line 232.
- `**Success criteria:**` — line 236.
- `**Completion report:**` — line 298 (with sub-case B framing).

The edit window is **lines 259–287**, fully between Success criteria (236) and Completion report (298). All four markers untouched. **No breakage.**

The kickoff variant (`pm-chat.md` Variant: kickoff) carries the `**Convention exception:**` callout and is excluded from Check 10. The generate-agent-kickoff variant is a different variant (separate `## Variant:` heading), is in scope for Check 10, and as verified above retains all four markers post-edit.

### 10.4 Will the pm-chat.md edit interact with `init-project.sh` or `migrate-v9-to-v10.sh`?

**Answer: NO.** Both scripts copy `project-template/docs/pack/` recursively (init-project.sh stage S4-S5; migrate stage S5-S6). They do not parse prompt-template content. Content changes propagate via the existing copy paths; no script-level interaction.

### 10.5 Will the new METHODOLOGY content trigger `init-project.sh` `blast_radius_sweep` (per F-D §10.0 surfacing)?

**Answer: NO.** The blast-radius-sweep scans `docs/pack/` for `PROMPT-TEMPLATES` references (per F-D §10.0). The new METHODOLOGY subsection does NOT add any `PROMPT-TEMPLATES` mention (verified — none of the §5.2 insert text contains the string `PROMPT-TEMPLATES`). The pre-existing `--exclude='METHODOLOGY.md'` mitigation from F-D commit `55d1834` continues to apply regardless.

---

## 11. Open-question resolutions

### 11.1 OQ-F-G-1 (project-lead modified) — pm-chat.md Notes cleanup: delete or relocate?

**Resolution: DELETE the three Notes AND replace with a one-line checklist pointer that references all three trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) AND active skills.** Per project-lead D2. Architect's recommendation cited only `CLAUDE.md`; project-lead expanded for trinity symmetry (developer-readable in the prompt template even though no trinity file is itself edited). See §5.3 for the verbatim pointer text.

### 11.2 OQ-F-G-2 (project-lead REVERSED) — add pm-chat row to per-agent table now or defer to v10.1?

**Resolution: ADD in this v10.0 patch.** Per project-lead D3. Architect recommended deferring; project-lead pulled it in. The new row clarifies that PM chat self-prompts inherit the constraints of the agent they are prompting. See §5.1 for the verbatim row content and the placement-decision rationale (last position; `pm-chat (self-prompt)` qualifier).

### 11.3 OQ-F-G-3 (project-lead accepted) — phase-anonymous worked examples?

**Resolution: PHASE-ANONYMOUS.** Per project-lead D4. The §5.2 example text contains no `Phase 28` / `Phase 32` cites. The architect's example sketches in design §3.4 already paraphrase rather than cite; this plan retains that discipline and adapts API names to be platform-neutral where possible (e.g., Example 3 uses `StateProvider` / `StateSnapshot` rather than the OT-specific `DebugStateProvider` / `DebugStateSnapshot`).

### 11.4 OQ-F-G-4 (project-lead accepted) — complete-skeleton example?

**Resolution: NOT IN THIS PATCH.** Per project-lead D5. May be filed as a v10.1 BACKLOG candidate at C-V10-18 sweep. Out of plan scope.

### 11.5 OQ-F-G-5 (project-lead accepted) — parallel callout in coder.md Variant: standard?

**Resolution: NOT IN THIS PATCH.** Per project-lead D6. The single fix-cycle callout suffices; the new METHODOLOGY worked-examples subsection covers both variants centrally.

---

## 12. Self-check

- **Can the implementer execute the 4 edits + harness + 3 commits without further architectural calls?** Yes — every edit (E1, E2, E4, E3 in execution order) has its file, line range, before/after snippet (or insertion-point spec for the SKILL append), and grep verification check. The §7 harness is copy-pasteable bash and includes the new §7.4 SKILL-propagation subsection. No design questions remain (D1–D6 baked-in; OQ-F-G-1..5 resolved per §11; FB-3 resolved per §9.3 — Option (a) expanded scope).
- **Are the worked examples in §5.2 actually phase-anonymous and terse?** Yes — no `Phase 28` / `Phase 32` cites; the OT-specific `DebugStateProvider`/`DebugStateSnapshot` names from the architect's design §3.4 are softened to generic `StateProvider`/`StateSnapshot` to read as platform-neutral. Subsection length: ~50 lines including the opening framing, 5 example blocks, and closing pointer — within the architect's ~36-line target plus a small margin for the 5th example's three-bullet shape.
- **Is the pm-chat.md replacement text properly referencing all three trinity files (not just CLAUDE.md) per the OQ-F-G-1 modification?** Yes — §5.3's pointer reads "the architect must read the universal rules constraining these decisions in `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` (LSP / capability-pattern / layer discipline / shared-state documentation), plus any active skills listed in the trinity `**Active skills:**` line".
- **Did the per-agent table pm-chat row get included per OQ-F-G-2 reversal?** Yes — §5.1 specifies the row content, placement decision (last; with `(self-prompt)` qualifier), and verification check.
- **Does the new subsection itself avoid solution leakage?** Yes — §5.2's inline self-consistency check confirms (a) Negative lines name leakage only to mark "do not write", (b) Positive lines state requirements without naming APIs/patterns, (c) Why lines name leakage categories without prescribing fixes, (d) closing pointer references already-published constraints. The self-check is repeated in §6.1 pre-commit checklist.
- **Trinity-rule check:** §3.4 confirms no trinity edits required. The pm-chat.md pointer *references* the trinity files (names them as a read-target for the architect agent) but does not *edit* their content. §6.1 includes a `git diff` empty-check on all three trinity files as a regression guard.
- **Cascading-effect checks complete:** §10 covers validate-pack.py Checks 5 / 6 / 7 / 10, init-project.sh / migrate-v9-to-v10.sh interaction, and the F-D blast-radius-sweep interaction. No interactions identified.
- **Flag-backs surfaced:** FB-1, FB-2, FB-4, FB-5 in §9.3 remain active gates during implementation. **FB-3 is RESOLVED** prior to implementation (project-lead chose Option (a) expanded to both Note 1 and Note 2 — see §9.3); E4 in §5.4 executes that resolution. No FB-3 surfacing during implementation; the cross-reference audit in §6.1 still runs but as a verification of E4's correctness (entry 39 contains `AsyncStream<Void>`; pm-chat.md does not), not as a flag-back trigger.

---

## 13. Summary

**Decision:** 3-commit pattern (C1 docs design+plan, C2 atomic 3-file behavioral patch, C3 docs §12 delta evidence) matching the F-E + F-F shape. C2 expanded from 2-file to 3-file by project-lead resolution of FB-3 (preserve substantive AsyncStream + LSP/type-erasure lessons in `swift-best-practices` SKILL).

**Edits in C2 (execution order E1 → E2 → E4 → E3):**
1. **E1** — `supporting-docs/METHODOLOGY.md` per-agent table at lines 674–684 — insert `pm-chat (self-prompt)` row at end (after `tester` row).
2. **E2** — `supporting-docs/METHODOLOGY.md` between current lines 691 and 693 — insert new `### Format-vs-solutions: worked examples` subsection (5 examples, Negative/Positive/Why; phase-anonymous).
3. **E4** — `project-template/skills/swift-best-practices/SKILL.md` end of file — append new `## Design choices` section with entries 39 (AsyncStream payload design — typed payload streams vs. content-less broadcast vs. AsyncChannel) and 40 (heterogeneous domain collections — protocol elevation over type-erasure-with-downcasting). Verbatim project-lead-approved wording. **Lands before E3 so E3's pointer text is honest.**
4. **E3** — `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff lines 259–287 — delete three prescriptive Notes; preserve the three □ titles unchanged; add one new `□` checklist pointer item naming all three trinity files + active skills + cross-referencing the new METHODOLOGY subsection.

**Verification:** single fresh-init harness under `/tmp/v10-fg-fixtures/` extended with new §7.4 SKILL-propagation assertions across `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`; validate-pack.py exit 0; test-detect.sh 34/34. All within /tmp; live OT and live pack-on-main untouched. Self-consistency re-read confirms the new METHODOLOGY subsection itself is leakage-free. §12 evidence template (with §12.4-bis SKILL propagation block) ready for C3.

**Trinity rule:** clean (no trinity edits; pointer references only; SKILL edit is in `project-template/skills/`, not a trinity file; CLAUDE.md line 395 anti-pattern bullet untouched).

**Open questions resolved:** OQ-F-G-1 (delete + trinity-symmetric pointer per D2), OQ-F-G-2 (add pm-chat row now per D3), OQ-F-G-3 (phase-anonymous per D4), OQ-F-G-4 (no complete skeleton per D5), OQ-F-G-5 (no parallel coder callout per D6).

**Flag-backs surfaced:** FB-1, FB-2, FB-4, FB-5 in §9.3 remain active during implementation. **FB-3 (concurrency + type-erasure content preservation) is RESOLVED** prior to implementation by project-lead choice of Option (a) expanded scope; E4 executes that resolution. No FB-3 surfacing during implementation.

**BD entry:** F-G → one BD-NNN, assigned at C-V10-18 BACKLOG sweep (out of plan scope).
