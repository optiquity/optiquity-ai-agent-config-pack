# V10-PROMPT-STRUCTURE-DESIGN

**Author:** pack-architect (Phase 4 design pass)
**Date:** 2026-04-28
**Status:** Draft — design pass only. Planner pass follows in a separate
prompt and produces the implementation plan; this document does not edit
any pack source file.

---

## 0. Status and scope

This is in-flight v10.0 work. Phase 4 audit closed with C-V10-01 through
C-V10-14 landed (v10-dev tip `459161b` or descendant). C-V10-15 final
verification has not yet executed. A gap was identified post-audit: the
pack ships its own Prompt Authoring Principles plus ten prompt templates
that do not consistently follow them. Only `coder.md` Variant: fix-cycle
surfaces the labeled triad; the other variants bury Problem/Goal in
prose or omit the triad entirely. METHODOLOGY's existing language about
"prescriptive content allowed for agent X" is murky enough to be
mis-read as licensing solutions in the prompt.

Scope of this design pass:

- Specify the labeled-section convention every prompt template variant
  must follow.
- Specify how the convention applies per template / per variant
  including `pm-chat.md`'s special status.
- Specify how format requirements coexist with the triad without being
  mistaken for solutions.
- Audit file-based-reporting consistency across all ten templates.
- Draft the METHODOLOGY.md § Prompt Authoring Principles edit text
  that mandates the convention, in implementer-ready form.

Out of scope of this design pass (pushed to the planner / implementation
phases that follow):

- Rewriting any prompt template content (the planner pass specs the
  edits; an implementation commit pass applies them).
- Editing METHODOLOGY.md, PROMPT-AUTHORING.md, or PM-CHAT.md (the
  proposed METHODOLOGY edit text lives **in this document** as
  reference; the actual file edit happens in implementation).
- Changes to `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`
  files unless surfaced in Open Questions.
- Filing the BD-NNN entry to BACKLOG.md (Pack Chat owns this after
  the planner pass).
- Adding a `validate-pack.py` check to enforce the convention (file a
  follow-on BD if the design implies one is needed; not in this scope).

Schedule integration: this design pass → planner pass (separate
prompt) → implementation commits → C-V10-15 verification → ship.

---

## 1. Pre-resolved design decisions (D1–D8)

These decisions are project-lead-approved inputs to this design pass.
They are restated here verbatim so an implementer reading this document
later does not need to reconstruct context.

**D1. Authoritative home.** METHODOLOGY.md § Prompt Authoring
Principles is the single source of truth for the convention.
`docs/pack/prompts/PROMPT-AUTHORING.md` becomes a one-line
cross-reference.

**D2. Section label format.** Bolded inline labels
(`**Problem:**`, `**Goal:**`, `**Success criteria:**`) — the same
shape `coder.md` Variant: fix-cycle uses today for its per-fix entries.
H2/H3 markdown headers are explicitly rejected (see § 7).

**D3. Canonical section order, top to bottom, every prompt:**

1. Role + agent identity (one line)
2. Context (state of the world this prompt fires in)
3. Required reading
4. Problem
5. Goal
6. Success criteria
7. Files in scope
8. Constraints
9. Out of scope
10. Completion report (what the agent returns; **must** be file-based)

**D4. Per-prompt application, not per-task.** One Problem / Goal /
Success criteria triad per prompt. Multi-task prompts list tasks
under Goal. (Per-task `Definition of done` may still appear inside
the task list — it is task-scope detail, not a substitute for
prompt-scope Success criteria.)

**D5. Variant-level convention.** Each `## Variant: <slug>` block is
a distinct prompt; the convention attaches per variant. The file's
H1 + YAML frontmatter cover the file as a whole; the labeled
sections live inside each variant body.

**D6. No content exceptions for any agent.** Every prompt has the
triad. METHODOLOGY's "prescriptive content allowed" language refers
strictly to **format** requirements (output structure, parse-able
shape, citation discipline). Format requirements are communication
standards, not solutions. They may be added to specific agents
**alongside** the triad; they never replace or omit it.

**D7. `pm-chat.md` per-variant scope is the architect's call.** The
`kickoff` variant is a context handoff (project name, surface
declaration, pointer to Procedure 7) and is likely out of scope. The
other three variants (`backlog-status-update`, `generate-setup`,
`generate-agent-kickoff`) produce specific outputs and may fit. The
architect decides per variant with rationale (§ 5).

**D8. METHODOLOGY.md edit is in scope for the implementation phase
that follows this design pass.** The convention has to live where the
principles do. The PROMPT-AUTHORING.md edit is in scope only for the
cross-reference one-liner.

---

## 2. Per-template / per-variant table

Legend:

- **Current state** — what the variant looks like today.
- **Target state** — what it must look like after the convention is
  applied. Concrete shape, not full rewrite text.
- **Scope** — `in` (convention applies), `out` (convention does not
  apply), `partial` (variant is exempt from some sections; the
  exemptions are listed in the Notes column).

| File | Variant | Current state | Target state under the convention | Scope |
|---|---|---|---|---|
| `architect.md` | `mid-phase` | Has Context (inline label), Reviewer-findings list, "Your task:" prose. Triad absent — Problem and Goal must be inferred. Constraints scattered through closing prose. No file-based completion report. | All ten canonical sections in D3 order, with bolded inline labels. **Problem:** = the recurring/worsening reviewer-finding pattern (root-cause framing). **Goal:** = identified root causes documented + proposed exact text changes for ARCHITECTURE / IMPLEMENTATION_PLAN / CLAUDE / AGENTS. **Success criteria:** = each finding has a named root-cause document section and a proposed-change block in the specified format; reviewer findings traced to one or more of those root causes. **Constraints:** read-only; no source code changes; no build/test commands. **Completion report:** REPORT FILE path written by PM chat. | in |
| `auditor.md` | `standard` | No labeled triad. Heavy procedural / format content (skip rules, platform skills, file-scope guidance, spawn rules, consolidation rules, constraint). Output described inline ("Return the consolidated report to the developer"). No REPORT FILE. | All ten canonical sections. **Problem:** = the codebase has not had a recent full-codebase structural audit (or a fix-verification audit is needed). **Goal:** = consolidated cluster reports per `audit-methodology` skill, with skipped clusters disclosed. **Success criteria:** = executive summary + all subagent reports in cluster order + dedup applied per ownership precedence + `Next steps` section listing Critical/Major. The skip rules, platform-skill loadout, spawn mechanism, and consolidation order are **format requirements** (§ 3), grouped under **Constraints** + **Completion report**. | in |
| `coder.md` | `standard` | Triad absent at the prompt level. Per-task `Definition of done` is the closest analogue. Tasks list, scope constraint, root-md prohibition, deferral comment rules, verification, and a structured completion report present. No REPORT FILE. | All ten canonical sections. **Problem:** = the phase-N tasks are not yet implemented. **Goal:** = each listed task is implemented per its DOD; verification suite passes; deferred items reported. **Success criteria:** = verification suite passes with zero warnings; completion report covers files modified, test count, Unplanned-file-modifications and Deferred-items sections. **Constraints:** scope-constraint, root-md-prohibition, deferral-format rule. **Files in scope:** explicit list (today inside Tasks). **Completion report:** REPORT FILE path; existing report shape is the format spec (kept). Per-task DOD survives inside Goal as task detail. | in |
| `coder.md` | `fix-cycle` | **Only** template variant with the labeled triad today — but applied **per fix** (`Problem:` / `Expected behavior:` / `Success criteria:` per ❌ entry), not per prompt. PM-chat-must-describe-problems callout present. Structured completion report. No REPORT FILE. | All ten canonical sections at the prompt level. **Problem:** = the reviewer's pass-N findings (root-cause framing). **Goal:** = each ❌ fix listed is applied per its expected behavior. **Success criteria:** = re-review will mark all listed ❌ items resolved; verification passes; deferred items reported. The per-fix `Problem` / `Expected behavior` / `Success criteria` blocks survive inside Goal as **per-task scope detail** (consistent with D4). The wording on the per-fix `Expected behavior` label may be normalized to `Goal:` to align with the prompt-level triad — flagged as Open Question Q1. | in |
| `docs-researcher.md` | `standard` | No labeled triad. "Your job is to VERIFY..." inline goal. Items-to-verify list. Output format with citation discipline. No REPORT FILE. | All ten canonical sections. **Problem:** = phase-N depends on external claims that may have drifted from current docs. **Goal:** = each listed claim verified against current official documentation; discrepancies flagged with required-change. **Success criteria:** = every listed claim has either ✅ CONFIRMED + source URL or ⚠️ DISCREPANCY block; sources cited for every fact; report header line correct. Citation discipline + ✅/⚠️ structure are **format requirements** (§ 3). | in |
| `grpc-schema.md` | (no variants) | Placeholder file; zero variants ship. | No prompt-level change required today. METHODOLOGY edit (§ 6) mandates that **any future variant added** to this file must use the convention; that mandate is enforced by the PM chat at prompt-generation time, not by content in this file. | partial (no current variants; convention applies to any future variant) |
| `planner.md` | `standard` | No labeled triad. "Read X. Break Phase [N] into ordered implementation tasks" inline. No constraints section, no Files-in-scope section, no REPORT FILE. | All ten canonical sections. **Problem:** = phase-N is too complex to send to the coder without a task breakdown. **Goal:** = ordered task list with per-task DOD, dependencies, risks. **Success criteria:** = report contains the task list, dependency edges, risk-ranked first task, report-header format correct. **Constraints:** read-only; report only; no code. | in |
| `pm-chat.md` | `kickoff` | Developer-pasted prompt that establishes session context, declares shell vs. manual surface, and points at METHODOLOGY Procedure 7. Not an agent-task prompt. | Out of scope for the labeled triad (see § 5 for full rationale). The convention does **not** apply to this variant. | out |
| `pm-chat.md` | `backlog-status-update` | PM-chat self-prompt. Heavy mechanical / prescriptive content (BACKLOG entry schema, STATUS.md edits). Approval-gate banner present. | All ten canonical sections, applied to the PM chat as the "agent." **Problem:** = a BACKLOG/STATUS state-change requires recording. **Goal:** = the named entries are updated per the listed schema with no other files touched. **Success criteria:** = exact entries exist with the prescribed shape; phase-title links validate; cancelled/deprecated items have flag-for-review applied. The entry schema and STATUS-link conventions are **format requirements** (§ 3). | in |
| `pm-chat.md` | `generate-setup` | PM-chat self-prompt. Reads SETUP_TEMPLATE.md, fills placeholders, outputs SETUP.md content. | All ten canonical sections. **Problem:** = the project has no `SETUP.md`. **Goal:** = a complete `SETUP.md` produced from the pack template with all relevant placeholders filled and inapplicable sections removed. **Success criteria:** = output is a single complete `SETUP.md` ready to save; placeholder list answered; no template-only comment block remaining. **Required reading:** SETUP_TEMPLATE.md and the planning conversation. | in |
| `pm-chat.md` | `generate-agent-kickoff` | PM-chat self-prompt. Reads AGENT_KICKOFF_TEMPLATE.md, fills placeholders (incl. structural-decision checklist), outputs AGENT_KICKOFF.md. | All ten canonical sections. **Problem:** = the architect kickoff session has no kickoff brief. **Goal:** = a complete `AGENT_KICKOFF.md` produced from the pack template with project description, platform, pattern, structural decisions, and required stubs filled in. **Success criteria:** = output is a single complete `AGENT_KICKOFF.md`; structural-decision checklist enumerated with rationale slots; CLI launch command included. | in |
| `repo-ops.md` | (no variants) | Placeholder file; zero variants ship. | Same disposition as `grpc-schema.md` — no current variants; METHODOLOGY mandate covers any future variant. | partial (no current variants; convention applies to any future variant) |
| `reviewer.md` | `standard` | No labeled triad. Eight-dimension review list. Output format with ✅/❌/⚠️ markers + Verdict line. Pass-summary block. No REPORT FILE. | All ten canonical sections. **Problem:** = the coder's pass-N output is unverified against the architecture + plan. **Goal:** = an eight-dimension review producing a pass/fail verdict and a structured findings list. **Success criteria:** = report header correct; every dimension addressed (no skipping); findings tagged ✅/❌/⚠️; Pass summary block present; Verdict line ends the report. The eight review dimensions, ✅/❌/⚠️ markers, and Verdict-line format are **format requirements** (§ 3). | in |
| `tester.md` | `standard` | No labeled triad. Inline "Produce a test strategy for Phase [N]" goal. Per-component output structure. Constraint ("Output a report only"). No REPORT FILE. | All ten canonical sections. **Problem:** = phase-N has implementation-bound test gaps that must be characterized before implementation begins. **Goal:** = test strategy listing what is tested, what is not, related BACKLOG items, test type, and required doubles per component, with priority summary. **Success criteria:** = every source file in scope appears in the inventory; every component has the prescribed five-field block; Priority Summary present and ranked. **Constraints:** report only; no test code. | in |

**Summary count.** Templates with variants: 8 files × 13 variants. Of
those 13 variants: 12 are in scope; 1 (`pm-chat.md` Variant: kickoff)
is out of scope. Two placeholder files (`grpc-schema.md`, `repo-ops.md`)
ship zero variants today and contribute zero current variants to the
in-scope count, but any future variant added to either file is
governed by the convention via the METHODOLOGY mandate (§ 6).

---

## 3. Per-agent format-requirements table

This table distinguishes **format requirements** (allowed alongside
the triad) from **solutions** (forbidden everywhere). The
distinguishing rule:

> **Format requirements describe how the output is structured and how
> findings are communicated. Solutions describe how the agent should
> achieve the goal.** Format requirements are communication standards
> that make the agent's output legible to the PM chat, the reviewer,
> or downstream tooling. Solutions substitute for the agent's
> filesystem context and judgment.

A format requirement never tells the agent which library, pattern,
algorithm, or sequence of code edits to use. A solution does. The
triad is mandatory for every agent regardless of how many format
requirements accompany it.

| Agent | Permitted format requirements (allowed alongside triad) | Why this is format, not solution | Forbidden as solution (examples) |
|---|---|---|---|
| `architect` | Required-reading list; **proposed-change block format** (`Proposed change [N] — [Document name], [Section name]` / `Root cause:` / `Current text:` / `Proposed replacement:` / `Why this fixes it:`); read-only constraint. | The block format makes proposed edits parse-able by the PM chat for downstream approval and application. It does not tell the architect which root cause to identify or which document to point at. | "Use a Coordinator pattern for navigation"; "Move type X to the data layer"; "The fix is to add a capability mask to type Y." Naming any pattern, library, or structural direction in the prompt anchors the agent. |
| `auditor` (parent + subagents) | Skip rules; per-subagent platform-skill loadout; per-subagent file-scope rules; severity scale (Critical/Major/Minor); cluster order (security → architecture → tests → ops → code → ui → docs); ownership-precedence dedup rules; executive-summary structure; report-header format. All forwarded from the `audit-methodology` skill. | Severity, cluster order, dedup, and skip rules govern report **shape and consolidation**, not findings. The auditor still independently identifies what is wrong and at what severity. | "Flag this code as Critical"; "Skip findings of type X"; "Conclude that the architecture is sound." Telling the auditor what to find or hide is solution. |
| `coder` | Files-in-scope list; verification commands (`./scripts/format.sh`, `./scripts/validate.sh`, etc.); completion-report shape (header line; "Unplanned file modifications" section; "Deferred items" section); per-task DOD format. | These let the PM chat verify the run completed and parse what changed. The coder still independently determines how to implement each task. | Pseudocode; pattern names ("use MVVM here"); algorithm sketches; "implement using `URLSession.bytes(from:)` rather than `data(from:)`"; step-by-step "first do X, then do Y." |
| `docs-researcher` | URLs to check; specific claims to verify; ✅ CONFIRMED / ⚠️ DISCREPANCY block format; **citation discipline** (cite source for every fact; separate confirmed facts from unverified assumptions). | Citation discipline is a communication standard — it makes the verification chain auditable. The agent still independently judges whether a claim matches the source. | "Conclude that claim X is true"; "Recommend library Y to fix the discrepancy." Telling the researcher what to verify is fine; telling them what to conclude is solution. |
| `planner` | Report-header format; task-list shape (per-task: what / files / DOD / risk); dependency-edge format. | These make the breakdown directly consumable by subsequent coder prompts. The planner still independently determines how to decompose the phase. | "Break Phase N into these specific tasks: …"; "Task 1 should modify file X with method Y." Prescribing the breakdown is solution. |
| `repo-ops` / mechanical claude | Exact file operations, exact BACKLOG/STATUS edits, exact command sequences. | `repo-ops` is the **one** category where prescriptive content is the entire purpose — these prompts are mechanical. They still carry the triad: Problem (the mechanical change is required); Goal (specific edits applied); Success criteria (exact end state). | N/A — for fully mechanical operations, prescribing the operation is the prompt. The triad still binds: the prompt cannot ask `repo-ops` to design a directory layout, only to apply one. |
| `reviewer` | Eight review dimensions (architecture / concurrency / anti-patterns / plan-compliance / test-coverage / build-warnings / BACKLOG-and-deferral hygiene / unplanned-file-modifications); ✅/❌/⚠️ markers; Pass-summary block; Verdict line; verification command. | These define what the reviewer must check and how findings are rendered for downstream PM-chat parsing. They do not tell the reviewer which findings to surface or hide. The eight dimensions are scope-of-review, which is closer to format than to solution — the reviewer still judges each dimension independently. | "Overlook this issue"; "Pass the phase if X holds"; "Issue Y is a Minor, not a Major." Adjusting the reviewer's judgment is solution. |
| `tester` | Output structure (per-component five-field block); priority-summary format; report-only constraint. | The block format and priority summary make the strategy parse-able by the PM chat for downstream test-implementation prompts. The tester still independently determines the gaps and ranking. | "Write tests using XCTest, not Swift Testing"; "Use mocks here, not stubs"; "The first test should cover function X." Test patterns and choices are solution. |
| `grpc-schema` | (no variants ship) | When variants are added: schema-pattern guidance from the `grpc-patterns` skill is forwarded as format/scope requirement; the agent still designs the schema. | "Use field number 5 for X"; "Make Y a `oneof` with three branches." |

**Implementation note for the convention.** Format requirements
appear in the prompt under **Constraints** (when they govern
behavior — read-only, report-only, no-code, verification command) or
under **Completion report** (when they govern output shape —
ordered sections, header line, ✅/❌/⚠️ markers, citation discipline).
They never appear inside **Goal** or **Success criteria**, because
those sections describe *what* must be achieved, not *how it is
formatted*.

---

## 4. File-based-reporting audit

Pattern observed in PM-CHAT.md (`Behavioral rules` § "Agent report
file"): every agent prompt the PM chat generates **must** include a
`REPORT FILE:` path, and the agent writes its report to that file
rather than copy-pasting back into the chat. This is enforced by the
PM chat at prompt-generation time, but the **template** must signal
where the path goes — otherwise the PM chat is the only line of
defence and it is easy to miss.

Audit method: each variant inspected for (a) an explicit
`REPORT FILE:` line or placeholder; (b) a copy-paste back-to-chat
implication ("Output ...", "Return ... to the developer", "End with
..."); (c) a mixed shape; (d) absent altogether.

| File / variant | Current Completion-report style | Fix needed |
|---|---|---|
| `architect.md` Variant: mid-phase | Absent. Closing prose says "Output proposed doc changes only" — implicit copy-paste. | Y — add **Completion report** section with `REPORT FILE: <path>` placeholder and the existing proposed-change format as content under the report. |
| `auditor.md` Variant: standard | Mixed. Procedural rules describe the consolidation shape, but closing line says "Return the consolidated report to the developer" — implies copy-paste. | Y — replace closing line with `REPORT FILE: <path>` placeholder; consolidated-report shape stays as format content under the report. |
| `coder.md` Variant: standard | Absent (file-based). Has structured Completion-report content (header line, Unplanned-file-modifications, Deferred items) but no `REPORT FILE:` line. Implies the report is delivered inline. | Y — add `REPORT FILE: <path>` placeholder; existing report-content shape kept. |
| `coder.md` Variant: fix-cycle | Absent (file-based). Same shape as standard variant — structured report content, no path. | Y — same as standard. |
| `docs-researcher.md` Variant: standard | Absent (file-based). "Begin the report with this header line as the very first line of output" — copy-paste implied. | Y — add `REPORT FILE: <path>` placeholder; output format kept. |
| `grpc-schema.md` | N/A — placeholder, no variants. | N/A today; mandate applies to any future variant. |
| `planner.md` Variant: standard | Absent (file-based). "Begin the output with this header line as the very first line" — copy-paste implied. | Y — add `REPORT FILE: <path>` placeholder; task-breakdown format kept. |
| `pm-chat.md` Variant: kickoff | N/A — out of scope per § 5. The kickoff variant is a developer-pasted context handoff to the PM chat, not an agent task with a deliverable. | N/A |
| `pm-chat.md` Variant: backlog-status-update | Absent — but this is a **self-prompt the PM chat runs against itself** to make file edits to BACKLOG.md / STATUS.md. The "report" is the file edit + a confirmation line in chat. The Completion-report section still applies but its content is "confirm what was changed" + the diff summary. | Y — add Completion-report section that names the files edited and the change summary; no `REPORT FILE:` path because the artifact **is** the file edit (BACKLOG.md / STATUS.md). The convention's **Completion report** section becomes "confirm-what-changed" rather than "write to REPORT FILE." Flagged as design clarification: the convention's "must be file-based" rule is satisfied here by the **target file edit itself**, not by a separate report file. |
| `pm-chat.md` Variant: generate-setup | Absent — output is the SETUP.md file content, currently delivered inline ("Output the complete SETUP.md content ready to save to the project root"). | Y — Completion report says the artifact is `SETUP.md` written at the project root; explicit path. Same clarification as backlog-status-update — the artifact is the target file. |
| `pm-chat.md` Variant: generate-agent-kickoff | Absent — output is `AGENT_KICKOFF.md` file content, delivered inline. | Y — Completion report says the artifact is `AGENT_KICKOFF.md` written at the project root; explicit path. |
| `repo-ops.md` | N/A — placeholder, no variants. | N/A today; mandate applies to any future variant. |
| `reviewer.md` Variant: standard | Absent (file-based). Output format is structured (header, findings list, Pass summary, Verdict) but copy-paste implied. | Y — add `REPORT FILE: <path>` placeholder; output format kept. |
| `tester.md` Variant: standard | Absent (file-based). "Report header (first line of output)" — copy-paste implied. | Y — add `REPORT FILE: <path>` placeholder; report format kept. |

**Defect summary.** All 12 in-scope variants currently use either
copy-paste (output described as inline text) or mixed shape. Zero
variants currently include an explicit `REPORT FILE:` line. The
PM-CHAT.md "Agent report file" rule is the only line of defence, and
because the templates do not signal the path placeholder, a PM-chat
operator generating a prompt by copy/paste from the template is more
likely to forget the `REPORT FILE:` line than to remember it.

**Two distinct sub-cases for the convention's "must be file-based"
rule:**

- **Sub-case A — agent produces a report.** Agent variants that
  produce a report-style deliverable (architect mid-phase, auditor
  standard, coder standard + fix-cycle, docs-researcher, planner,
  reviewer, tester) take a `REPORT FILE: <path>` line. The agent
  writes markdown to that path; the PM chat reads it back.
- **Sub-case B — PM-chat self-prompt produces a target-file edit.**
  The three in-scope `pm-chat.md` variants
  (`backlog-status-update`, `generate-setup`,
  `generate-agent-kickoff`) edit or create a named project file
  (BACKLOG.md, STATUS.md, SETUP.md, AGENT_KICKOFF.md). The artifact
  is the target file itself; no separate report file is needed. The
  Completion-report section names the target file and lists what
  changed.

Both sub-cases satisfy the file-based-reporting principle. The
METHODOLOGY mandate (§ 6) names both sub-cases explicitly so the
distinction is clear to future implementers.

---

## 5. `pm-chat.md` per-variant scoping decision

D7 delegates the per-variant scoping decision for `pm-chat.md` to the
architect. Decision and rationale per variant:

### Variant: `kickoff` — **OUT of scope**

**Disposition.** The convention does not apply.

**Rationale.** This variant is not an agent-task prompt. It is a
developer-pasted opening message to a PM chat session. Its purpose is
context handoff: project name, key architectural decisions, surface
declaration (`shell` vs. `manual`), pointer to METHODOLOGY Procedure
7. There is no "Problem the agent must diagnose," no "Goal the agent
must achieve in a single run," and no single deliverable. The PM
chat's job after kickoff is the entire session, not a single
report-producing pass. Forcing the triad here would distort the
variant: "Problem: a new PM chat session has started" /
"Goal: read project documents and propose next action" — the labels
add no information and obscure the variant's actual function as a
session preamble.

What stays in this variant: the surface-declaration block, the
project-document checklist, the role-of-PM-chat description, the
post-declaration branch (shell → Procedure 7; manual → SETUP-NEW.md
fallback). What this variant inherits from the convention: nothing
explicit — but it does inherit the **file-based output rule by
proxy**, because every prompt the PM chat subsequently generates
follows the convention.

**Documentation marker.** The variant's italic descriptor at the top
of the body should explicitly say "This variant is a context handoff
and does not follow the prompt-authoring convention; it is the only
exception in `pm-chat.md`." This makes the exception visible to
future implementers and to validate-pack.py-style enforcement
(should one ever be added).

### Variant: `backlog-status-update` — **IN scope**

**Disposition.** Convention applies; sub-case B for the file-based-
reporting rule.

**Rationale.** This variant has a specific, bounded deliverable: a
named set of edits to BACKLOG.md / STATUS.md applied per a fixed
schema. The triad maps cleanly: Problem (a backlog or status state-
change is required), Goal (the named edits applied per schema, no
other files touched), Success criteria (the entries exist with the
prescribed shape; phase-title links validate; cancelled/deprecated
items have flag-for-review applied). The entry schema and STATUS-
link conventions are format requirements (§ 3) and remain.

### Variant: `generate-setup` — **IN scope**

**Disposition.** Convention applies; sub-case B.

**Rationale.** Bounded deliverable: a single complete `SETUP.md`
written from `SETUP_TEMPLATE.md` with placeholders filled. Triad
fits cleanly. The placeholder list and "remove sections that don't
apply" are part of Goal/Constraints, not solutions.

### Variant: `generate-agent-kickoff` — **IN scope**

**Disposition.** Convention applies; sub-case B.

**Rationale.** Bounded deliverable: a single complete
`AGENT_KICKOFF.md` written from `AGENT_KICKOFF_TEMPLATE.md`. Triad
fits cleanly. The structural-decisions checklist (type-erasure,
notification, ViewModel-navigation) is **scope content** — it
prescribes which architectural decisions the architect kickoff must
enumerate. It is not a solution because it does not pick the
decisions, only requires that they be enumerated.

**Note on structural-decisions checklist content.** The current
`generate-agent-kickoff` body includes "Note:" paragraphs that
describe what the chosen approach must satisfy (e.g., type-erasure
wrappers with `.base` accessors are an LSP violation; preferred is
protocol elevation). These are **architecture-rule reminders that
the architect agent must apply when evaluating each decision** —
not solutions for the kickoff-generation prompt to follow. They live
inside the AGENT_KICKOFF.md output and are read by the architect
later, not by the PM chat at generation time. They survive the
convention as content under Goal.

**Summary.** Of `pm-chat.md`'s four variants: 1 out of scope
(`kickoff`), 3 in scope (`backlog-status-update`, `generate-setup`,
`generate-agent-kickoff`).

---

## 6. Proposed METHODOLOGY.md § Prompt Authoring Principles edit

**Where it goes.** Replace and extend the existing § "Prompt
Authoring Principles" body in `supporting-docs/METHODOLOGY.md`
(currently lines ≈ 546–664). The headings below reflect the target
state of the section after the planner pass specs the implementation
edit.

**Implementer note.** The text below is the architect's draft. The
planner pass will integrate it into METHODOLOGY's existing structure
(remove or reframe the current "Exceptions — where prescriptive
content is appropriate" subsection so it does not contradict D6;
keep the existing "On scoping the problem statement," "When
generating prompts from IMPLEMENTATION_PLAN.md task entries," and
"PM chat self-check" subsections; cross-reference to
`docs/pack/prompts/PROMPT-AUTHORING.md` for the directory-level one-
liner). The architect does not stipulate the line-by-line splice; the
planner pass does.

---

### Draft METHODOLOGY.md § Prompt Authoring Principles (replacement / extension)

> ## Prompt Authoring Principles
>
> These principles apply to every prompt the PM chat generates and to
> every task entry written in IMPLEMENTATION_PLAN.md. They are not
> style guidance. They govern what information belongs in a prompt
> and what does not.
>
> ### The core rule: describe the problem, goal, and success criteria — not the solution
>
> Every prompt must answer:
>
> 1. **Problem** — the root cause, described at the category level,
>    not a single symptom. Include enough scope that the agent
>    recognizes all instances within the files-in-scope list — but
>    do not describe the solution.
> 2. **Goal** — what correct behavior looks like across the affected
>    scope when the prompt is complete. Describe the outcome, not the
>    steps.
> 3. **Success criteria** — the observable, verifiable state that
>    confirms the goal is achieved. What can be checked to know the
>    prompt's work is complete? At the IMPLEMENTATION_PLAN.md task
>    level this maps to the task's "Definition of done."
>
> Plus the surrounding sections: Context, Required reading, Files in
> scope, Constraints, Out of scope, Completion report.
>
> A prompt must never contain:
> - Pseudocode or implementation sketches
> - Framework, pattern, or library choices (unless already mandated
>   in ARCHITECTURE.md)
> - Step-by-step "how to" instructions
> - Proposed solutions that substitute for agent judgment
>
> **Why this rule exists.** Prescriptive prompts bypass the agent's
> ability to find the right approach from full filesystem context.
> The PM chat has not read every file in the repo — the agent has.
> The PM chat states what is wrong, what correct behavior looks like,
> and what confirms the work is complete. The agent determines how
> to achieve it.
>
> ### Mandatory section structure (canonical order)
>
> Every prompt template variant — every `## Variant: <slug>` block in
> every file under `docs/pack/prompts/` — uses bolded inline labels
> in the following order:
>
> 1. **Role + agent identity** (one line; the variant heading + one-
>    line italic descriptor satisfies this)
> 2. **Context:** state of the world this prompt fires in
> 3. **Required reading:** documents and files the agent must read
>    before starting; distinguish read-for-understanding vs. files in
>    scope
> 4. **Problem:** as defined above
> 5. **Goal:** as defined above
> 6. **Success criteria:** as defined above
> 7. **Files in scope:** explicit list the agent may create or
>    modify; the unplanned-file-modifications escape valve applies
> 8. **Constraints:** read-only / write rules, verification commands,
>    deferral-comment rules, root-md prohibition where applicable
> 9. **Out of scope:** explicit list of what the prompt is **not**
>    asking for, when relevant (omit if redundant with Constraints)
> 10. **Completion report:** what the agent returns, **always
>     file-based** — see "File-based reporting" below
>
> **Label format.** Bolded inline markdown labels —
> `**Problem:**`, `**Goal:**`, `**Success criteria:**`, etc. — placed
> at the start of the section content. H2 / H3 markdown headers are
> not used at the section level: a multi-section prompt body
> rendered as a forest of `##` headings is harder to scan and creates
> a heading-level conflict with the variant's own `##` heading.
>
> **Per-variant application.** The convention attaches to each
> `## Variant: <slug>` block, not to the file as a whole. Different
> variants of the same agent are distinct prompts and may differ in
> Constraints, Files in scope, and Completion-report shape, but all
> contain the triad and follow the canonical order.
>
> **One triad per prompt — not per task.** A prompt with multiple
> tasks (e.g., a coder phase with three implementation tasks; a fix-
> cycle with five reviewer findings) lists the tasks under **Goal**.
> Per-task **Definition of done** survives inside the task list as
> task-scope detail; it does not replace the prompt-level **Success
> criteria**.
>
> ### Format requirements vs. solutions
>
> No agent's prompt may contain solutions. The triad is mandatory
> for every agent without exception.
>
> "Format requirements" — output structure, parse-able shape,
> citation discipline, severity scales, verdict-line conventions —
> are a separate, narrower category. They are communication
> standards, not solutions. Format requirements may be added to
> specific agent prompts **alongside** the triad; they never replace
> or omit it.
>
> The distinguishing rule:
>
> > Format requirements describe **how the output is structured** and
> > **how findings are communicated**. Solutions describe **how the
> > agent should achieve the goal**.
>
> Format requirements appear in the prompt under **Constraints**
> (when they govern behavior — read-only, report-only, no-code,
> verification command) or under **Completion report** (when they
> govern output shape — header line, ordered sections, ✅/❌/⚠️
> markers, citation discipline). They never appear inside **Goal**
> or **Success criteria**.
>
> | Agent | Format requirements (allowed) | Solutions (forbidden) |
> |---|---|---|
> | `architect` | Required-reading list; proposed-change block format. | Pattern names; structural direction; library or framework choices. |
> | `auditor` | Skip rules; per-subagent platform-skill loadout; severity scale; cluster order; ownership-precedence dedup; executive-summary structure. All forwarded from `audit-methodology`. | Telling the auditor what to find or hide; pre-judging severity. |
> | `coder` | Files in scope; verification commands; completion-report shape (Unplanned-file-modifications, Deferred-items sections); per-task DOD format. | Pseudocode; pattern names; algorithm sketches; step-by-step "how to." |
> | `docs-researcher` | URLs; specific claims; ✅/⚠️ block format; citation discipline. | Telling the researcher what to conclude; proposing a fix to a discrepancy. |
> | `planner` | Report-header format; per-task field shape; dependency-edge format. | Prescribing the breakdown itself ("Phase N has these tasks: …"). |
> | `repo-ops` / mechanical claude | Exact operations and command sequences (the entire purpose of the agent). | N/A — but the prompt cannot ask `repo-ops` to **design** anything; only to apply a fully-specified operation. |
> | `reviewer` | Eight review dimensions; ✅/❌/⚠️ markers; Pass-summary block; Verdict line; verification command. | Adjusting the reviewer's judgment; pre-categorizing severity; instructing what to overlook. |
> | `tester` | Per-component output block; priority-summary format; report-only constraint. | Test pattern or framework choice; mock vs. stub direction; pre-ordered test plan. |
>
> ### File-based reporting
>
> Every prompt's **Completion report** section names a file the
> agent's output is written to. Two sub-cases:
>
> - **Sub-case A — agent produces a report.** A `REPORT FILE: <path>`
>   line names a markdown file the agent writes its report to (e.g.,
>   reviewer pass-N report, coder phase-N completion report,
>   architect mid-phase analysis, docs-researcher verification, planner
>   breakdown, tester strategy, auditor consolidated report). The PM
>   chat reads the file back; the agent does not copy-paste output
>   into chat.
> - **Sub-case B — PM-chat self-prompt produces a target-file edit.**
>   When the PM chat runs a self-prompt that edits or creates a
>   project file (BACKLOG.md, STATUS.md, SETUP.md,
>   AGENT_KICKOFF.md), the artifact **is** the target file edit. No
>   separate report file is required. The Completion-report section
>   names the target file and the change summary.
>
> Both sub-cases satisfy this rule. A prompt that asks an agent to
> "output the report" or "return the result to the developer" without
> naming a file is a defect.
>
> ### On scoping the problem statement
>
> *(existing subsection retained as-is — root-cause framing, files-
> in-scope as the bounding mechanism, audit-and-report behavior for
> unknown scope.)*
>
> ### When generating prompts from IMPLEMENTATION_PLAN.md task entries
>
> *(existing subsection retained as-is — reframe prescriptive task
> entries before forwarding; for agents where prescriptive content is
> permitted as **format**, forward as written.)*
>
> ### PM chat self-check before generating any prompt
>
> Before writing a prompt:
>
> 1. **Triad check.** Does the prompt body contain bolded labeled
>    `**Problem:**`, `**Goal:**`, and `**Success criteria:**`
>    sections? If not, add them before sending.
> 2. **Solution check.** Ask: *"Am I describing what needs to be
>    true, or how to do it?"* If the answer is "how to do it,"
>    rewrite as "what needs to be true." Format requirements (output
>    shape) are not solutions and are not affected by this check.
> 3. **Data-dependency trace.** *(existing subsection retained — for
>    each data field or behavior the phase requires, trace which
>    existing type holds the data and add the relevant file to the
>    files-in-scope list.)*
> 4. **REPORT FILE check.** Does the **Completion report** section
>    name a file the agent's output goes to (sub-case A) or the
>    target file the PM chat will edit (sub-case B)? If neither, add
>    one before sending.

---

**End of draft METHODOLOGY.md edit text.**

PROMPT-AUTHORING.md change in scope for the implementation phase: the
file becomes a one-line cross-reference — "See
`supporting-docs/METHODOLOGY.md` § Prompt Authoring Principles for
the convention every variant in this directory follows." The current
"Per-agent exceptions" table and "Self-check" sections are removed —
they are duplicated by, and will drift from, METHODOLOGY.md. The
directory-level "How to use these templates" framing (templates are
starting points; the PM chat customizes; multi-part phase header
convention) survives as a short paragraph above the cross-reference,
since it is directory-scoped guidance not prompt-authoring rule.

---

## 7. Rejected alternatives

### A. "Make the convention optional — recommended but not mandatory"

**Rejected.** The reason this design pass exists is that "recommended
but not mandatory" is what METHODOLOGY currently expresses ("every
prompt must answer Problem / Goal / Success criteria") and the result
is that 12 of 13 in-scope variants either bury or omit the triad.
Making compliance optional preserves the failure mode that prompted
the pass. Mandate is the only state that materially changes
behavior. D6 already commits to no exceptions for content; this
rejection makes that commitment binding.

### B. "Use H2 / H3 markdown headers for the labeled sections instead of bolded inline labels"

**Rejected.** Three reasons.

1. **Heading-level conflict.** The variant heading is `## Variant:
   <slug>`. Sibling sections at `##` would split a single variant
   into a flat sequence of equal-weight headings; the variant's own
   identity disappears. Demoting variants to `###` means each section
   becomes `####`, which is far down the heading hierarchy and still
   harder to scan than inline labels.
2. **Visual weight mismatch.** A `##` block carries the same weight
   as a top-level page section; a labeled inline phrase carries the
   weight appropriate for "this paragraph is the Problem statement."
   The information density of each section in a prompt template is
   2–8 lines. Markdown headers are designed for multi-paragraph
   sections.
3. **Existing precedent.** `coder.md` Variant: fix-cycle already uses
   bolded inline labels (`**Problem:**`, `**Expected behavior:**`,
   `**Success criteria:**`) per fix entry. D2 codifies this shape.
   Choosing markdown headers now would create two label conventions
   in the same file (per-prompt H2/H3, per-fix bolded inline) — more
   complexity, no benefit.

### C. "Exempt some agents from the triad entirely (revert to the existing 'Exceptions' table)"

**Rejected.** This is the status quo and it is exactly what got us
here. The existing METHODOLOGY exceptions table (`reviewer`,
`docs-researcher`, `repo-ops`, `tester`, `coder`, `architect`,
`planner`, `auditor`) lists what each agent "May prescribe" vs.
"Must not prescribe." A reader scanning that table sees the column
labelled "May prescribe" and reasonably concludes that reviewer's
"output format" or coder's "verification commands" exempt those
agents from the triad. They do not — but the table does not say so.

The fix is to keep the **format-vs-solution distinction** the
exceptions table tracks (it is genuinely useful) and re-frame it
explicitly as **format requirements that live alongside the
mandatory triad**, not as exemptions from it. This is what § 3 and
§ 6 do.

### D. "Apply the convention per file (one triad per template file) instead of per variant"

**Rejected.** Variants of the same agent serve different prompts —
`coder.md` Variant: standard implements new phase work; Variant:
fix-cycle resolves reviewer findings. The Problem, Goal, and
Success criteria differ between them, and the Constraints
(`PM chat must describe problems, not solutions` callout in fix-
cycle, the deferral / unplanned-modifications rules in standard) are
variant-specific. A file-level triad would be either generic enough
to be useless or specific enough to be wrong for at least one
variant. D5 codifies per-variant.

### E. "Keep the per-fix triad in `coder.md` Variant: fix-cycle as the only triad; do not add a prompt-level triad"

**Rejected** for the fix-cycle variant specifically. The per-fix
triad is the reviewer's findings, decomposed. The prompt-level
triad is the prompt's purpose — "the reviewer's pass-N findings
must be resolved before the phase can advance." These describe
different scopes (per-fix = task scope; per-prompt = prompt
scope), and D4 mandates per-prompt application. The per-fix triad
survives as task-scope detail under Goal; the prompt-level triad
sits above it. (Consistent: the same shape is used by `coder.md`
Variant: standard, where per-task `Definition of done` lives under
the prompt-level triad.)

---

## 8. Open questions for the project lead

Per Success criterion 8: none should arise if the eight pre-resolved
decisions are honored. The architect surfaces only **new** questions
arising from the per-template inspection.

### Q1 — Per-fix label normalization in `coder.md` Variant: fix-cycle

The current per-fix block uses `**Problem:**` / `**Expected
behavior:**` / `**Success criteria:**`. After the prompt-level triad
is added (which uses `**Problem:**` / `**Goal:**` / `**Success
criteria:**`), there are **two** triads in the same prompt with
slightly different middle-label wording (`Expected behavior` vs.
`Goal`).

Options:

- **Q1a.** Keep the per-fix middle label as `Expected behavior:`. It
  reads slightly more naturally for a single fix and matches the
  reviewer's mental model ("the reviewer found Y; expected behavior
  is X").
- **Q1b.** Rename the per-fix middle label to `Goal:` for label
  consistency across the convention. Costs one minor wording
  awkwardness ("Goal: the URL builder accepts non-Latin characters")
  in exchange for one consistent label set across the pack.

**Architect recommendation:** Q1b for symmetry. But this is a
naming choice with no functional effect, and the project lead may
prefer Q1a for readability. Flagging only because the planner pass
needs a definitive answer before specing the per-fix entry shape.

### Q2 — `pm-chat.md` Variant: kickoff documentation marker

§ 5 specifies that the kickoff variant's italic descriptor at the
top of the body should explicitly state that it is the only
exception. The current italic descriptor is *"Paste this at the
start of a new PM chat session to establish project context."*

Options:

- **Q2a.** Append a sentence: *"This variant is a context handoff
  and does not follow the prompt-authoring convention; it is the
  only exception in this directory."*
- **Q2b.** Add a separate one-line callout under the descriptor:
  *"**Convention exception:** kickoff is a context handoff, not an
  agent-task prompt. The labeled-section convention does not apply.
  All other variants and all other prompt files in this directory
  follow it."*

**Architect recommendation:** Q2b — the explicit callout makes the
exception findable by an implementer reading just this variant; the
appended sentence is easier to skim past.

### Q3 — `validate-pack.py` enforcement (out of scope here, file as follow-on?)

The convention is specified in METHODOLOGY.md (§ 6) and the PM-chat
self-check (item 1 of step 4 in the draft) covers prompt-generation
time. There is **no automated check** that newly-added prompt
template variants conform — a future commit could introduce a new
variant that omits the triad and the only line of defence is human
review.

`validate-pack.py` could grep each `docs/pack/prompts/*.md` file and
require that every `## Variant: <slug>` block (except the kickoff
exception, identifiable by file + slug or by the explicit exception
marker per Q2) contains `**Problem:**`, `**Goal:**`, and
`**Success criteria:**` substrings.

Per the read-only constraint on this design pass, the architect does
**not** propose a validate-pack.py change here. This is flagged as a
candidate **follow-on BD-NNN** for the project lead to file (or not)
after the planner pass and v10.0 ship. Not blocking.

### Q4 — PROMPT-AUTHORING.md scope after reduction

D1 says PROMPT-AUTHORING.md becomes a one-line cross-reference. § 6
notes that the directory-level "How to use these templates" framing
(starting-points, multi-part phase header convention) is directory-
scoped and survives as a short paragraph above the cross-reference.

Question: is the multi-part phase header convention (`Part [M]`
appended to phase title in report headers) directory-scoped or
prompt-authoring-scoped? It governs the **shape of agent reports**,
which is closer to prompt-authoring rule than to directory guidance.
If it is prompt-authoring-scoped, it should move to METHODOLOGY.md
alongside the file-based-reporting subsection.

Options:

- **Q4a.** Keep the multi-part header convention in
  PROMPT-AUTHORING.md as directory guidance.
- **Q4b.** Move it into METHODOLOGY.md § Prompt Authoring Principles
  → File-based reporting subsection (or a new "Report header
  conventions" subsection adjacent to it). PROMPT-AUTHORING.md
  collapses to a true one-liner.

**Architect recommendation:** Q4b. The multi-part header convention
is a report-shape rule that applies to every agent's completion
report, regardless of which file in `docs/pack/prompts/` the prompt
came from. METHODOLOGY is the right home. Reduces drift surface
between the two files.

---

## End of design document

The planner pass takes this document plus the cross-references it
names (METHODOLOGY.md, PROMPT-AUTHORING.md, the ten prompt template
files, PM-CHAT.md behavioral-rules section) and produces the
implementation plan: per-file edit list, commit sequencing, trinity-
rule check, validate-pack.py impact assessment, and verification
plan integrated with C-V10-15.
