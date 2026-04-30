# V10-F-G-DESIGN — Solution leakage in PM-chat-generated prompts

**Author:** pack-architect (Phase 4 patch design pass)
**Date:** 2026-04-29
**Status:** Draft — design pass only. Implementer (parent pack chat) commits
after project-lead approval. This document does not edit any pack source file.
**Related:** `maintenance-docs/V10-PHASE-4-VERIFICATION.md` § F-G (proposed;
v10.0 patch); supplementary findings — post-§4.8 real-project testing
(Phase 28 + Phase 32 paraphrased coder-prompt walk-throughs). Companion to
`V10-F-D-DESIGN.md` and `V10-F-E-F-F-DESIGN.md` (same Phase 4 patch cohort).

---

## 0. Status and scope

The v10 prompt-template structure (BD-049 labeled-section convention) ships a
strong scaffold and the PM chat applies it correctly at the format level —
Problem / Goal / Success criteria / Files-in-scope / Constraints / Completion
report all appear in the right places. But the F-G evidence (8 paraphrased
leakage cases drawn from Phase 28 logging and Phase 32 debug-panel coder
prompts) shows the PM chat crossing from "format/scope/constraints" into
"solution territory" inside otherwise well-structured prompts.

`supporting-docs/METHODOLOGY.md § Prompt Authoring Principles` (line 546)
already touches the format-vs-solutions distinction in three places:

- The core rule "describe the problem, goal, and success criteria — not the
  solution" (line 566) and its bulleted list of forbidden contents (lines 585–590).
- The dedicated subsection "Format requirements vs. solutions" (line 649),
  including the per-agent table of allowed format vs. forbidden solutions
  (lines 674–684).
- The PM-chat self-check item 2 "Solution check" (line 776).

The rule is present. The defect is that the rule remains abstract — "no
pseudocode, no pattern names, no library choices" — and the PM chat's actual
leakage cases are not pseudocode or pattern names. They are sub-implementation
choices: a parameter-injection technique, a SwiftUI scene API name, a polling
rate, a return-type shape, a snapshot-composition pattern. The rule's
abstract bullets do not give the PM chat a concrete pattern-match to recognize
these as solutions when generating prose under time pressure.

Scope of this design pass:

- Decide where the new "Format-vs-solutions: worked examples" subsection lands.
- Pick which of the 8 F-G leakage cases best teach the rule (RAG token budget).
- Articulate the rule statement form (numbered / callout / prose).
- Run the self-consistency check across `project-template/docs/pack/prompts/*.md`.
- Confirm trinity-rule compliance.
- Inventory the file cascade.
- Self-check: the new subsection itself must not violate the rule.
- Flag open questions for project lead.

Out of scope (deferred to implementation):

- Producing diffs or final prose.
- Editing any pack source file.
- Filing the BD-NNN entry (Pack Chat owns).
- Verification fixture rebuild planning (Pack Chat / pack-planner own).

---

## 1. Decision — summary

**Add a single new subsection — "Format-vs-solutions: worked examples" — to
`supporting-docs/METHODOLOGY.md § Prompt Authoring Principles`, positioned
immediately after the existing "Format requirements vs. solutions" subsection
(currently ending around line 691) and before "File-based reporting" (line 693).**

The subsection contains:

1. A 2-sentence rule restatement (no rule renumbering — the new subsection
   sits adjacent to the existing per-agent table and inherits its framing).
2. Four worked examples, each in a tight Negative / Positive / Why triplet.
3. One worked example explicitly illustrating "Files-in-scope is NOT
   solution leakage" (the F-G clarification).
4. No new prose duplicating content already covered in the surrounding
   subsections.

In addition, two of the existing prompt template files in
`project-template/docs/pack/prompts/` contain language that crosses the
format-vs-solutions line themselves and need parallel cleanup as part of
this patch — otherwise the PM chat reads them as canonical examples and
reproduces the leakage. See §4 (self-consistency check).

Total touch surface: **3 files** (METHODOLOGY + 2 prompt templates), zero
trinity changes.

---

## 2. Where the new subsection lands in METHODOLOGY

### 2.1 Decision: immediately after "Format requirements vs. solutions" (line 691), before "File-based reporting" (line 693)

The current canonical order of subsections (per BD-049 work) within
`## Prompt Authoring Principles`:

1. About `docs/pack/prompts/` (line 553)
2. The core rule: describe the problem, goal, and success criteria — not the solution (line 566)
3. Mandatory section structure (canonical order) (line 599)
4. **Format requirements vs. solutions (line 649)** — abstract rule + per-agent table
5. File-based reporting (line 693)
6. Multi-part phase report headers (line 717)
7. On scoping the problem statement (line 728)
8. On scoping the files-in-scope list (line 742)
9. When generating prompts from IMPLEMENTATION_PLAN.md task entries (line 757)
10. PM chat self-check before generating any prompt (line 768)

The new subsection — **"Format-vs-solutions: worked examples"** — slots in
as 4a, between the existing abstract treatment (subsection 4) and the
unrelated "File-based reporting" topic (subsection 5).

### 2.2 Rationale for this position

**Adjacency to the abstract rule it concretizes.** The reader (PM chat at
RAG-fetch time, or human pack maintainer reading the methodology
sequentially) encounters the abstract rule, the per-agent table, and the
worked examples in one cluster. The worked examples are not a separate
topic; they are the operational form of subsection 4. Splitting them with
intervening unrelated content (file-based reporting, header conventions)
would force the reader to context-switch in and out of the format-vs-solutions
topic.

**Pre-self-check positioning.** Subsection 10 (PM chat self-check) item 2
asks: *"Am I describing what needs to be true, or how to do it?"* That
question is exactly what the worked examples train pattern-matching for.
Placing the worked examples earlier in the section (subsection 4a) means
the self-check at subsection 10 references concepts the reader has already
seen.

**Rejected alternative — append at end of Prompt Authoring Principles.**
Append-at-end is the lowest-friction edit but breaks the topical clustering.
Worked examples on the format-vs-solutions distinction belong with the
abstract rule, not after the unrelated scoping/self-check subsections.

**Rejected alternative — fold examples inline into the existing subsection 4
prose.** This would inflate the existing subsection from ~45 lines to
~90 lines, mixing rule statement, per-agent table, and worked examples in
one block. Splitting into 4 + 4a keeps each subsection scannable and
preserves the per-agent table as a standalone reference table.

**Rejected alternative — new top-level Part in METHODOLOGY.** The defect
is internal to "Prompt Authoring Principles," not a new methodology topic.
A new Part would over-elevate it.

---

## 3. Worked examples — selection and form

### 3.1 Decision: 4 worked examples, drawn from the 8 F-G cases

The 8 F-G cases cluster into roughly 5 leakage categories:

| Category | F-G case(s) | Selected? |
|---|---|---|
| Specifying a testability technique | "must be injectable as a parameter (`maxFileSizeBytes`)" | **Yes — Example 1** |
| Specifying an API or framework symbol | "via `WindowGroup` or `Window`" | **Yes — Example 2** |
| Specifying architectural shape (return-type, composition pattern) | "DebugStateProvider is a protocol that returns a `DebugStateSnapshot` value type … snapshot has nested value types covering …" | **Yes — Example 3** |
| Specifying timing / lifecycle behavior | "polls on a 1 Hz timer"; "suspend the timer when the window is not visible" | **Yes — Example 4 (combined)** |
| Specifying presentation choice | "section headers and monospaced value rendering where appropriate" | Not selected — covered by Example 3's "architectural shape" pattern |
| Specifying commenting / justification format | "Justify the actor-vs-queue choice in a brief comment at the type's declaration"; `@unchecked Sendable` justification template verbatim | Not selected — narrower category; the rule generalizes from Examples 1–4 |

**Selection criteria applied:**

- **Category coverage over case-count.** Each selected example illustrates a
  distinct category of leakage, not just a different surface example of the
  same category. A reader who internalizes Examples 1–4 has the pattern.
- **Match the most common defect surfaces.** API/framework names (Example 2)
  and architectural-shape inventions (Example 3) are the two highest-frequency
  patterns in the F-G evidence — both selected.
- **Token budget.** 4 examples at ~6 lines each = ~24 lines total for
  examples, plus ~4 lines per Negative / Positive / Why frame = bounded
  growth. RAG ingest cost is one-time and small.

### 3.2 Plus one example: "Files-in-scope is NOT solution leakage"

The F-G entry's explicit clarification (lines 928 of V10-PHASE-4-VERIFICATION.md)
records that file paths in the Files-in-scope list — relayed from
`IMPLEMENTATION_PLAN.md`'s task entries — are **not** solution leakage even
though they specify a destination. They are scope/location guardrails. This
is documented as a "recurring point of confusion" in the F-G entry.

The new subsection includes one **Negative-shaped-as-Positive** example: a
Files-in-scope entry that *looks* prescriptive but is actually scope
relay, paired with a contrasting Negative example that *does* leak (an API
choice that the relay would have disguised as scope).

This is **Example 5** — distinct from Examples 1–4 in shape (it's a
"distinguish from" example, not a "don't do this" example), and earns its
slot precisely because the F-G entry flagged it as a recurring confusion.

### 3.3 Example shape — Negative / Positive / Why

Each example is rendered as three short labeled lines:

- **Negative (do not write):** [paraphrased leakage, drawn from F-G evidence]
- **Positive (write instead):** [the format/constraint version]
- **Why:** [one-line rationale]

This shape is uniform across all 5 examples. ~6 lines per example block
including the example header. The whole subsection lands at ~40 lines
(rule restatement + 5 example blocks + brief framing prose).

### 3.4 Examples — content sketches (not final prose)

The implementer (or pack-planner sequencing the patch) writes final prose;
the architect specifies content shape only.

**Example 1 — testability technique leakage**
- **Negative:** *"The size limit must be injectable as a parameter so tests
  can drive rotation with small payloads."*
- **Positive:** *"Rotation behavior must be testable with payloads small
  enough to trigger rotation in unit tests."*
- **Why:** The negative names a testability mechanism (parameter injection).
  The positive states the testability requirement; the coder chooses among
  parameter injection, an overridable static, a test-seam protocol, or
  another approach.

**Example 2 — API or framework name leakage**
- **Negative:** *"Declare the panel scene via `WindowGroup` or `Window`,
  whichever is consistent with how the existing app declares scenes."*
- **Positive:** *"The panel must be a separate scene matching the
  scene-declaration convention already used in the app."*
- **Why:** The negative names specific SwiftUI APIs. The positive names
  the constraint (separate scene; convention-matching) and lets the coder
  read the existing app to choose.

**Example 3 — architectural-shape invention**
- **Negative:** *"DebugStateProvider is a protocol that returns a
  DebugStateSnapshot value type; snapshot has nested value types covering
  [list]."*
- **Positive:** *"The panel content sections required: [list of sections
  from the plan]. The state-source design is the coder's choice."*
- **Why:** The negative invents a protocol-plus-snapshot-plus-nested-value-types
  composition pattern that did not appear in the implementation plan. Plan
  required panel content sections; the data-supply architecture is a coder
  decision.

**Example 4 — timing or lifecycle prescription**
- **Negative:** *"Poll the data source on a 1 Hz timer; suspend the timer
  when the window is not visible."*
- **Positive:** *"Panel data must reflect current state without measurable
  user-visible lag, and must not consume resources when the panel is
  hidden."*
- **Why:** The negative names a polling rate and a lifecycle mechanism. The
  positive names the observable requirements (freshness, idle behavior);
  the coder chooses polling vs. observation, rate, and visibility hook.

**Example 5 — Files-in-scope is NOT leakage (clarifying example)**
- **This is scope, not solution:** *"Files in scope: `Data/Logging/FileLogSink.swift`
  (new), `Data/Logging/LogRotation.swift` (new)."* These paths come from
  the implementation plan and enforce existing layer discipline (logging
  belongs in `Data/`). They are location guardrails.
- **This crosses into solution:** *"Use `FileManager.default.url(for:in:)`
  to resolve the log directory."* This names an API choice the coder
  should make.
- **Why:** Files-in-scope lists relay scope from the architect / planner /
  plan. They tell the coder where the work lives and where it does not. They
  do not specify how the work is done. API and data-structure choices made
  *inside* those files are the coder's.

### 3.5 Total subsection size estimate

- ~3 lines: subsection heading + 2-sentence rule restatement
- ~30 lines: 5 example blocks (Negative / Positive / Why × 5, ~6 lines each)
- ~3 lines: closing pointer back to subsection 4's per-agent table

**Total ~36 lines.** Comparable to the existing "Format requirements vs.
solutions" subsection (~45 lines including its per-agent table) and well
within RAG-cost-conscious budget.

---

## 4. Self-consistency check — existing prompt templates

**Critical step.** The PM chat reads `project-template/docs/pack/prompts/*.md`
as canonical examples of well-formed prompts. If those templates themselves
contain solution leakage, the PM chat reproduces the leakage faithfully —
no METHODOLOGY edit will fix it. The METHODOLOGY rule and the templates
must agree.

### 4.1 Audit — files reviewed

`coder.md`, `architect.md`, `planner.md`, `pm-chat.md` (all 4 variants).
Plus spot-check of `reviewer.md`, `tester.md`, `auditor.md`,
`docs-researcher.md`, `repo-ops.md`, `grpc-schema.md` (these were not
flagged in F-G evidence; brief check only).

### 4.2 Findings

**Clean (no parallel cleanup required):**

- `coder.md` — Variant: standard. Format-only structure. Tasks list,
  Constraints, deferral comment syntax, verification commands — all
  format/scope/constraint. No solution leakage in template body.
- `coder.md` — Variant: fix-cycle. Carries a callout (lines 120–123)
  explicitly stating *"PM chat must describe problems, not solutions … each
  fix entry states what is wrong and why … not pseudocode, implementation
  steps, or code of any kind."* This is a positive example of the rule, not
  a violation. **Clean.**
- `architect.md` — Variant: mid-phase. Read-only analysis pass; output is a
  proposed-change list. The Goal and Success criteria specify report
  structure (root-cause names, proposed change blocks, citation discipline).
  No solution leakage. **Clean.**
- `planner.md` — Variant: standard. Specifies report structure (per-task
  fields, dependency edges, risk identification). No solution leakage.
  **Clean.**
- `pm-chat.md` — Variant: kickoff. Carries documented convention exception.
  No prescriptive content beyond surface-detection and read-list. **Clean.**
- `pm-chat.md` — Variant: backlog-status-update. Specifies BACKLOG-entry
  schema (format), STATUS.md anchor format. All format. **Clean.**
- `pm-chat.md` — Variant: generate-setup. Specifies SETUP.md placeholder
  list. Format. **Clean.**

**Needs parallel cleanup (2 files / 1 variant):**

- **`pm-chat.md` — Variant: generate-agent-kickoff** (lines 264–286).
  The structural-decisions checklist embeds three "Note:" callouts that
  prescribe specific design choices to the architect agent:

  - Lines 264–270 (heterogeneous-collections Note): asserts that
    "Type-erasure wrappers that expose a `.base` accessor … are an LSP
    violation," that "Protocol elevation … is the preferred approach,"
    and conditions on when "Exhaustive enums are preferred."
  - Lines 271–278 (state-change-notification Note): asserts that
    "AsyncStream<Void> … forces every subscriber to perform an actor hop,"
    that "Typed payload streams … allow subscribers to filter," and
    that "AsyncChannel … is NOT suitable for fan-out."
  - Lines 280–287 (ViewModel-navigation Note): asserts that "ViewModels
    must not import SwiftUI," and prescribes specific output mechanisms
    ("typed stream or observable state property … a non-isolated closure
    injected by the caller … a delegate protocol").

  These three Notes prescribe architectural answers inside what should be
  a structural-decisions checklist for the architect to *decide*. Per the
  existing METHODOLOGY rule (line 687: *"Architect prompts — stronger
  restriction. Never include a proposed solution, pattern name, or
  structural approach in a prompt to an architect agent. A proposed
  solution in an architect prompt is not a suggestion — it anchors the
  agent."*), these Notes are the exact failure mode that rule prohibits.

  The Notes should either be removed entirely (the checklist alone
  surfaces the decisions; the architect reads CLAUDE.md for the universal
  rules) or relocated to CLAUDE.md / a platform skill where they live as
  permanent project rules rather than as inline guidance attached to a
  template.

- **`coder.md` — Variant: standard, "Tasks" placeholder block** (lines
  40–47). The template literal currently shows:
  ```
  1. [TASK DESCRIPTION — specific, measurable, with exact file paths]
     - Files to create: [list]
     - Files to modify: [list]
     - Definition of done: [verifiable criterion]
  ```
  The placeholder text "[TASK DESCRIPTION — specific, measurable, with exact
  file paths]" is fine — that is format guidance. **No edit needed here.**
  But the implementer should verify (during the F-G implementation pass)
  that the surrounding prose around line 21 (`**Problem:** Phase [N] tasks
  are not yet implemented`) and line 23 (`**Goal:** Each task in the
  **Tasks** list below is implemented per its Definition of done`) does
  not invite the PM chat to lift task-entry implementation prescriptions
  from `IMPLEMENTATION_PLAN.md` verbatim. METHODOLOGY subsection 9 (line
  757, "When generating prompts from IMPLEMENTATION_PLAN.md task entries")
  already covers this; the coder template prose does not currently
  contradict it. **No edit needed; flagged for verification only.**

### 4.3 Implementation note

The `pm-chat.md` Variant: generate-agent-kickoff cleanup is the
load-bearing self-consistency fix. Without it, every project that uses
`generate-agent-kickoff` produces an `AGENT_KICKOFF.md` that hands the
architect agent three pre-decided answers — and the architect anchors on
them. This is exactly the leakage F-G describes, just one workflow step
upstream of where F-G observed it. Fixing METHODOLOGY without fixing
this template would leave the leakage source intact.

### 4.4 Why these Notes are in the template (historical context)

The Notes were almost certainly added in an earlier pack version to
encode lessons learned from real architect mistakes (real LSP violations
in production code; real AsyncStream<Void> performance problems; real
ViewModels importing SwiftUI). Those lessons are valuable. They belong in
`project-template/CLAUDE.md` (universal architecture rules), in a
platform skill (e.g., `apple-architecture-core`), or in the
`AGENT_KICKOFF_TEMPLATE.md` itself as project-rule context — not as
inline prescriptions inside a checklist that asks the architect to
choose. The implementer (or a follow-up patch) decides the relocation
target; this design pass identifies the violation.

---

## 5. Rule statement form

### 5.1 Decision: brief prose introduction; no rule numbering

The new subsection opens with a 2-sentence prose framing, not a
"Rule N:" label or callout box. Reasons:

1. **Existing METHODOLOGY style.** The "Prompt Authoring Principles"
   section uses prose subsections, not numbered rules. Subsection 4
   ("Format requirements vs. solutions") opens with prose framing and
   contains a per-agent table; subsection 4a (the new worked-examples
   subsection) should match. Introducing a "Rule 6:" label here would
   create a single one-off numbered rule in an otherwise prose-organized
   section.
2. **The rule is already stated.** Subsection 4 establishes the rule
   ("No agent's prompt may contain solutions … format requirements
   describe how the output is structured; solutions describe how the
   agent should achieve the goal"). The new subsection's job is to make
   the rule pattern-matchable via examples, not to re-promulgate it.
   A "Rule N:" label would imply a new rule, not a worked illustration
   of the existing one.
3. **Token cost.** A callout box adds ~3 lines of formatting overhead
   (delimiters + blank lines) per use. Prose framing costs ~2 lines.

### 5.2 Recommended opening text shape

(For implementer reference; final wording is implementation work.)

> *"The format-vs-solutions distinction is easier to read in the abstract
> than to apply under time pressure. The examples below show the most
> common leakage shapes observed in v10 PM-chat-generated coder prompts
> (paraphrased from real cases). For each: the **Negative** line shows
> what NOT to write; the **Positive** line shows the format/constraint
> version; the **Why** line names the leakage category."*

Then the 5 examples per §3.4.

Then a closing pointer:

> *"The per-agent table in the previous subsection enumerates which
> format requirements are allowed for each agent. When in doubt: ask the
> §10 self-check question 2 — 'Am I describing what needs to be true, or
> how to do it?'"*

---

## 6. Cascade — files that change

### 6.1 Pack source files

| # | File | Change |
|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` (insert between current line 691 and current line 693, i.e., between end of "Format requirements vs. solutions" and start of "File-based reporting") | New subsection: `### Format-vs-solutions: worked examples`. ~36 lines per §3.5. Body per §3.4 + §5.2. |
| 2 | `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff lines 264–287 | Remove the three "Note:" prescriptive callouts inside the structural-decisions checklist. Either delete entirely (preferred — checklist items stand alone) or relocate the content to `project-template/CLAUDE.md` or `AGENT_KICKOFF_TEMPLATE.md` as project-rule context. Implementer or follow-up patch chooses relocation target. |
| 3 | `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` (only if option (b) of #2 is chosen — relocation target) | Receive the relocated content as project-rule context, framed as "rules the architect must respect" not as "the answer to this checklist item." Out of scope for this design pass to specify final placement; flag for implementer. |

### 6.2 Files NOT changed (and why)

- **`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.** No trinity
  changes. The new METHODOLOGY subsection lives where the trinity already
  references it (`docs/pack/METHODOLOGY.md` per V10-F-D resolution). The
  per-agent rule about prompt authoring is already stated in METHODOLOGY;
  trinity files do not duplicate METHODOLOGY content.
- **`coder.md`, `architect.md`, `planner.md`, `reviewer.md`, `tester.md`,
  `auditor.md`, `docs-researcher.md`, `repo-ops.md`, `grpc-schema.md`.**
  Per §4.2, all clean. No edits required.
- **Pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `PACK-AGENTS.md`.**
  Govern pack-repo agent behavior, not project PM chat behavior. Out of
  scope.
- **`supporting-docs/SETUP-NEW.md`, `MIGRATION-v9-to-v10.md`,
  `PM-CHAT.md`.** No prompt-authoring content. Out of scope.

### 6.3 Total touch surface

**2 file edits** (METHODOLOGY + pm-chat.md generate-agent-kickoff cleanup),
optionally a third file (AGENT_KICKOFF_TEMPLATE.md) if the implementer
chooses relocation over deletion of the three Notes. ~36 net lines added
to METHODOLOGY; ~24 lines removed from pm-chat.md (or ~24 relocated). No
trinity edits. No design-document overrides.

---

## 7. Trinity-rule compliance

Per CLAUDE.md trinity rule: when modifying `project-template/CLAUDE.md`,
make the parallel edit in `AGENTS.md` and `GEMINI.md` in the same commit.

**Under this design, none of the three trinity files are modified.** The
new METHODOLOGY subsection adds prose to a file the trinity already
references. The pm-chat.md cleanup removes prescriptive content from a
prompt template; trinity files do not reference that template's body.

If the implementer chooses option (b) for the Notes — relocation to
CLAUDE.md as universal architecture rules — then trinity-rule applies and
parallel AGENTS.md / GEMINI.md edits are required in the same commit. If
the implementer chooses option (a) — deletion — trinity is untouched.

**Trinity-rule status: clean under option (a); apply standard trinity
discipline under option (b). Neither option blocks the design.**

---

## 8. Self-check

| Property | Status |
|---|---|
| Rule statement terse (RAG token cost)? | **Yes.** ~36 lines total subsection. 2-sentence opening, 5 example blocks at ~6 lines each, 1-sentence closing pointer. No prose duplication of subsection 4 or self-check item 2. |
| Worked examples drawn from real F-G evidence? | **Yes.** All 5 examples paraphrase F-G entries (Phase 28 logging, Phase 32 debug panel) with no OT body content. Selection criteria documented in §3.1. |
| Cascade catches self-consistency issues in existing prompt templates? | **Yes.** §4 audit identified `pm-chat.md` Variant: generate-agent-kickoff lines 264–287 as containing the same leakage pattern; cleanup is included in the patch (not deferred). The other 9 prompt files / 6 other variants are clean. |
| Design itself free of format-vs-solutions violations? | **Yes — verified inline.** This document specifies the new subsection's *content shape* (number of examples, Negative/Positive/Why frame, target line count) and the *rule statement form* (prose vs. numbered, opening framing, closing pointer). It does not write the final prose. The 5 example sketches in §3.4 paraphrase F-G evidence rather than inventing new wording. The "what counts as scope vs. solution" guidance in §4 is constraint specification (which prompt-template lines violate the existing rule), not a solution prescription (how to rewrite them — that's implementer judgment). The recommended opening text in §5.2 is explicitly marked "for implementer reference" and not load-bearing. |
| Centralization preserved? | **Yes.** Rule + worked examples live in METHODOLOGY (RAG-indexed; dormant when not queried; single source of truth). Prompt templates carry no duplicated rule content — only positive-example structure. The pm-chat.md cleanup removes content that should not have been there, not content that's duplicated with METHODOLOGY. |
| Token-cost budget? | **+36 lines METHODOLOGY, −24 lines pm-chat.md = +12 net pack-wide.** RAG ingest delta is negligible. The METHODOLOGY addition is dormant when the PM chat is not generating prompts (same dormancy property as the rest of "Prompt Authoring Principles"). |
| Boundary discipline preserved? | **Yes.** No new write surfaces. METHODOLOGY is read-only to the PM chat at runtime (pack-distributed). Prompt templates are read-only to the PM chat at runtime (read on demand, body customized in-session). Both edits happen at pack-version time, not project-runtime. |
| Adjacent-precedent symmetry? | **Yes.** The new subsection sits in the same canonical-order cluster as "Format requirements vs. solutions" — the abstract rule + per-agent table + worked examples form one topical group, parallel to how "On scoping the problem statement" and "On scoping the files-in-scope list" form a paired scoping cluster (subsections 7–8). |

---

## 9. Open questions for project lead

**OQ-F-G-1.** For the `pm-chat.md` Variant: generate-agent-kickoff Notes
cleanup (§4.2): delete or relocate?
*Recommendation: **delete**, with a one-line addition to the checklist
stating "the architect must read CLAUDE.md and any active platform skills
for the universal rules constraining these decisions." This avoids
inflating CLAUDE.md or AGENT_KICKOFF_TEMPLATE.md with content that already
exists in skills (the LSP rule is in `project-template/CLAUDE.md` lines
72–76; the actor/concurrency notes belong in `swift-best-practices` or
`apple-architecture-core` skill if not already there). The checklist's
job is to surface decisions; the rules constraining those decisions live
in CLAUDE.md and skills. Project lead confirms.*

**OQ-F-G-2.** Should the per-agent table in the existing subsection 4
(METHODOLOGY lines 674–684) gain a new row for `pm-chat` itself?
*Currently the table covers `architect`, `auditor`, `coder`,
`docs-researcher`, `planner`, `repo-ops`, `reviewer`, `tester`. The PM
chat is not an agent (per `pm-chat.md` line 12: "the PM chat is the
consumer of these templates, not an agent"). But the F-G defect is PM
chat solution leakage — adding a `pm-chat` row clarifying "format
requirements (allowed): kickoff context, BACKLOG schema, STATUS anchor
format / solutions (forbidden): all of the above when generating prompts
for other agents (PM chat inherits the constraint of the target
agent)" might prevent future ambiguity. Recommendation: defer to v10.1.
The current patch focuses on pattern-recognition via worked examples;
table expansion is a separate (small) improvement. Project lead confirms
or absorbs into v10.0.*

**OQ-F-G-3.** Should the new subsection cite specific phase numbers
(e.g., "observed in OT Phase 28 and Phase 32") or stay phase-anonymous?
*Recommendation: **phase-anonymous**. The METHODOLOGY ships to all
projects; references to "Phase 28" are meaningless to projects that did
not run that phase. The examples are valuable on their own (paraphrased
patterns); citing OT-specific phase numbers in a pack-distributed doc
also violates the §6.7.7 sanitization principle from the verification
plan. Project lead confirms.*

**OQ-F-G-4.** Is there value in adding a single concrete *positive*
example of a complete coder-prompt skeleton (showing all 10 sections
correctly populated) somewhere in METHODOLOGY?
*Currently no such complete worked example exists; readers must compose
the canonical structure from subsections 3 + 4 + 5 + the per-agent table.
A "complete-skeleton" example would be ~60–80 lines of additional content
and would partially duplicate `coder.md` Variant: standard. Recommendation:
**out of scope for F-G**. The F-G defect is leakage *within* otherwise-
correctly-structured prompts; a complete skeleton would not address it.
File as v10.1 candidate if desired; project lead decides.*

**OQ-F-G-5.** Does the `coder.md` Variant: fix-cycle's existing callout
(lines 120–123: *"PM chat must describe problems, not solutions …"*) get
a parallel callout added to `coder.md` Variant: standard, or is the
single callout sufficient (since both variants are read by the same PM
chat)?
*Recommendation: **leave alone**. The fix-cycle callout exists because
fix-cycle prompts are higher-risk for solution leakage (the reviewer
already named the problem; the temptation to also name the fix is
strong). The standard variant is lower-risk. Adding a parallel callout
costs ~4 lines and adds redundancy. The METHODOLOGY worked-examples
subsection covers both variants centrally. Project lead confirms.*

---

## 10. Summary

**Decision:** add `### Format-vs-solutions: worked examples` to
METHODOLOGY § Prompt Authoring Principles, positioned between current
"Format requirements vs. solutions" and "File-based reporting"
subsections. ~36 lines: 2-sentence framing + 5 worked examples
(Negative / Positive / Why) drawn from F-G evidence — 4 illustrating
distinct leakage categories (testability technique, API/framework name,
architectural-shape invention, timing/lifecycle prescription) plus 1
clarifying that Files-in-scope is not solution leakage.

**Why position.** Adjacent to the abstract rule it concretizes;
pre-self-check; preserves topical clustering. The two rejected
positions (append-at-end, fold-inline) break clustering or inflate
subsection 4 past scannable size.

**Why these examples.** Category coverage (4 distinct leakage shapes) +
the F-G clarification (Files-in-scope ≠ leakage). Selection criteria:
distinct categories over case-count; match highest-frequency defect
surfaces (API/framework names; architectural-shape invention); RAG
token budget. 4 + 1 = 5 examples.

**Why prose framing (no rule numbering).** Existing METHODOLOGY style;
the rule is already stated in subsection 4; the new subsection
illustrates the existing rule rather than promulgating a new one.

**Self-consistency check.** `pm-chat.md` Variant: generate-agent-kickoff
lines 264–287 contain three "Note:" callouts that prescribe architectural
answers inside what should be an architect-decides checklist — the same
leakage pattern as F-G observed in coder prompts, one workflow step
upstream. Parallel cleanup is required as part of this patch (delete
preferred; relocation to CLAUDE.md or skill as alternative). The other
9 prompt template files / 6 other variants are clean.

**Cost.** 2 file edits (3 if relocation chosen), +12 net lines pack-wide.
No trinity changes (under deletion option). No design-document overrides.

**Trinity-rule:** clean under deletion option; standard trinity
discipline under relocation option. Neither blocks the design.

**Open questions:** 5, listed in §9; none block project-lead approval.
