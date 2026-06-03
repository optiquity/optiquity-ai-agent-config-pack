# PACK-FEEDBACK.md — Feedback to the AI Agent Config Pack

<!--
HOW TO USE THIS TEMPLATE

This file is installed by `scripts/init-project.sh` (or refreshed by
`init-project.sh --update` / `migrate-v10-to-v11.sh`) into your project
at `docs/pack/PACK-FEEDBACK.md`. You do not copy it manually.

This is the PM chat's running feedback log for the AI Agent Config Pack
itself. It is NOT a project log (use STATUS.md, BACKLOG.md, CHANGELOG.md
for project-level state). It is the upstream feedback channel from the
PM chat running this project to the Pack Chat maintaining the pack.

METHODOLOGY.md Part 10 provides the overview. This file contains the
full operational instructions — the PM chat reads them here, in the doc
it is actively writing to.

Agents must not write to this file. The PM chat owns it exclusively,
same permissions as BACKLOG.md.

Fill in [PROJECT_NAME] and the initial Status section during project
kickoff, then remove this HTML comment block and the italicized note
below.
-->

---
*Copied from: project-template/docs/pack/PACK-FEEDBACK.md — AI Agent Config Pack v11*
*Fill in Status section during kickoff, then remove this block and the
HTML comment above.*
---

<!-- DENY-LIST-CONTENT-START -->
# [PROJECT_NAME] — Pack Feedback Log

## Status

| Field | Value |
|---|---|
| Pack version in use | v11.[N] |
| Project name | [PROJECT_NAME] |
| Project start date | [YYYY-MM-DD] |
| Last delivery to Pack Chat | (never) |

---

## How to use this doc

This section is the operational reference for the PM chat. Read it when
working with this doc. METHODOLOGY.md Part 10 is the overview; this
section is the detail.

### What to observe

Log observations in four categories as they occur during normal work:

1. **Workflow execution** — for each Workflow (1–6 in METHODOLOGY.md Part 5): did it run as documented? What was confusing, improvised, or skipped? Every entry must say: which workflow, what was expected, what happened.
2. **Prompt generation** — for each per-agent prompt variant (in `docs/pack/prompts/<agent>.md`): what had to be customized heavily? Unclear placeholders? Missing information? Did the agent struggle because the variant lacked context?
3. **Agent performance** — per-agent, per-run: did it follow the instructions? Respect file scope? Use the output format? Hallucinate? Drift? Silently fail? Aggregate into per-agent patterns over time (patterns are more valuable to Pack Chat than individual incidents).
4. **User friction** — where the human got confused, asked twice, encountered unexpected behavior, or found documented behavior that didn't match tool behavior.

**Coverage gap awareness:** The pack has deep coverage for Apple/Swift/Xcode
and Python/uv/ruff. Other platforms, IDEs, and languages have thinner or
absent coverage. When this project uses a platform, IDE, editor, or language
where the pack's skills and context files feel thin or absent, observe and
record what's missing. This includes:

- **IDE and editor gaps:** Xcode has companion templates, post-edit hooks,
  and scheme configuration guidance. VS Code has basic companion templates
  but minimal workflow guidance. JetBrains, Cursor, and other editors have
  nothing. If the project uses an IDE other than Xcode, note what workflow
  guidance or hook integration is missing.
- **Platform gaps:** iOS and macOS have dedicated architecture skills,
  deployment skills, and prohibited-pattern lists. Android, Windows,
  embedded, and web platforms have deferred skills (not yet created). If
  the project targets a platform without dedicated skills, note what rules
  or patterns were missing from the context files and which skills the
  agents would have benefited from.
- **Platform update cycles:** When a major platform update ships (new OS
  version, new language version, new framework release, new IDE version),
  observe whether the pack's skills and context files needed updating.
  Record: what changed, how the gap was discovered (agent produced wrong
  advice? skill referenced deprecated API? context file had stale
  availability guards?), and how quickly the gap was noticed.

These observations flow into the normal observation categories above —
log them under Workflow, Prompt, Agent Performance, or User Friction as
appropriate. The Pack Chat uses this data to prioritize new skills and
platform coverage.

### Reporting cadence

**Default — workflow-complete boundaries only.** Do not interrupt in-progress work. Deliver feedback batches at:
- End of a phase (reviewer pass complete, commit done).
- End of a fix cycle that reached a passing verdict.
- End of an audit cycle (full auditor run + BACKLOG processing complete).
- End of a feature or phase group.

**Emergency — deliver immediately.** If something blocks the project or indicates a broken pack defect (agent hallucinates dangerous commands, audit rules produce repeated false-positive criticals, a workflow is structurally wrong), populate the `## Emergency Escalation` section and tell the user to forward to Pack Chat out-of-band. Do not wait.

### Workflow-boundary check (the PM chat must do this proactively)

At every workflow-complete boundary, **before** saying "ready for next phase," the PM chat must:

1. Review all Pack Chat Open Questions with Status: Not Ready. For each, assess whether observations from this phase provide enough data to transition to Ready. If so, transition it and tell the user: *"Pack Chat Q[N] now has enough data. I'll generate the delivery prompt."*
2. For each question with Status: Ready, generate the delivery prompt and present it to the user.
3. Briefly report the status of all open questions to the user, even if nothing changed: *"Pack Chat open questions: Q1 Not Ready (0 observations), Q2 Not Ready (1 observation, need more data)."*

This check is the PM chat's responsibility. The user should not have to ask for it.

### How delivery works

**Regular:** At a workflow-complete boundary, collect entries since the last delivery. Generate a Markdown batch with: pack version, project name, delivery date, the four observation categories (new entries only), updated answers to Open Questions. Output this for the user to forward to Pack Chat (email, GitHub issue on the pack repo, or pasted into a Pack Chat session). After delivery, mark delivered entries with a delivered-date and update the `## Delivery Log`.

**Emergency:** Output a minimal escalation message immediately: pack version, what happened, what was expected vs. observed, why it's severe. Log in both `## Emergency Escalation` and `## Delivery Log`.

### Scope boundaries

This doc is about **the pack**, not the project. The distinction:
- *"Workflow 5 is confusing because the skip rules aren't in `auditor.md` Variant: standard."* → **PACK-FEEDBACK.md** (observation about the pack).
- *"Phase 7 fix for auth middleware is deferred until the JWT library ships."* → **BACKLOG.md** (project-specific debt).

The PM chat records *observations*, never *solutions*. Pack Chat decides what to do. The PM chat does not modify the pack from within a project — the pack repo is upstream and read-only.

### What NOT to put here

- Project-specific debt (belongs in BACKLOG.md).
- Current phase state (belongs in STATUS.md).
- Rant without a concrete "expected vs. happened" structure.
- Solutions or proposals for how the pack should change.
- Anything already obvious from the pack repo itself.

### Permissions

| Role | May do | May not do |
|---|---|---|
| All agents (coder, reviewer, auditor, etc.) | Read only | Write anything |
| PM chat | Append entries; deliver batches; update Status fields | Modify past entries (append-only) |

The PM chat never asks an agent to write directly to this doc. Agent reports go into the agent's own completion report; the PM chat extracts observations and logs them here.

### Open Question status state machine

Every question in `## Pack Chat Open Questions` uses a Status field with
one of these values:

| Status | Meaning | Next state(s) |
|---|---|---|
| **Not Ready** | Observing; insufficient data to deliver. Default for new questions. | Ready, Deprecated |
| **Ready** | Enough data collected. Generate delivery prompt at next workflow boundary. | Prompt Provided, Deprecated |
| **Prompt Provided** | Delivery prompt generated and forwarded to Pack Chat. Awaiting response. Do NOT regenerate. | Closed, Resolved (No Change), Deprecated |
| **Closed** | Pack Chat delivered a fix; fix installed (e.g., new pack version pulled); PM chat told to close. **Terminal.** | — |
| **Resolved (No Change)** | Pack Chat reviewed and decided no pack change is needed. Question answered, no fix. **Terminal.** | — |
| **Deprecated** | Question no longer applicable — pack evolved, question malformed, or concern invalidated. **Terminal.** | — |

Always include a date when changing Status: `Status: Ready (2026-06-15)`.

---

## Emergency Escalation

*Populate entries here only when something is severe enough that it
blocks the project or indicates a broken v9 defect. Deliver immediately,
do not wait for a workflow boundary.*

*(empty)*

---

## Workflow Observations

*Dated, append-only entries. For each observation: which workflow, what
was expected, what happened, any context for Pack Chat. Observations
only — no solutions.*

### Workflow 1 — New project setup
*(no entries yet)*

### Workflow 2 — Per-phase execution (coder → reviewer)
*(no entries yet)*

### Workflow 3 — Per-phase execution with external API research
*(no entries yet)*

### Workflow 4 — Fix cycle
*(no entries yet)*

### Workflow 5 — Full-codebase audit
*(no entries yet)*

### Workflow 6 — New feature on a stable project
*(no entries yet)*

---

## Prompt Variant Observations

*For each variant used: which agent file and variant slug, what needed
heavy customization, unclear placeholders, missing information, did the
generated prompt produce good agent output.*

### pm-chat.md — Variant: kickoff
*(no entries yet)*

### coder.md — Variant: standard
*(no entries yet)*

### reviewer.md — Variant: standard
*(no entries yet)*

### coder.md — Variant: fix-cycle
*(no entries yet)*

### architect.md — Variant: mid-phase
*(no entries yet)*

### tester.md — Variant: standard
*(no entries yet)*

### docs-researcher.md — Variant: standard
*(no entries yet)*

### planner.md — Variant: standard
*(no entries yet)*

### pm-chat.md — Variant: backlog-status-update
*(no entries yet)*

### auditor.md — Variant: standard
*(no entries yet)*

### pm-chat.md — Variant: generate-setup
*(no entries yet)*

### pm-chat.md — Variant: generate-agent-kickoff
*(no entries yet)*

---

## Agent Performance Log

*One section per agent. For each run: date, task, did it follow
instructions, respect scope, use output format, hallucinate, drift, or
silently fail? Roll up per-agent patterns at the top of each section
over time.*

### coder
**Patterns:** *(filled in over time)*
*(no entries yet)*

### reviewer
**Patterns:** *(filled in over time)*
*(no entries yet)*

### planner
**Patterns:** *(filled in over time)*
*(no entries yet)*

### tester
**Patterns:** *(filled in over time)*
*(no entries yet)*

### docs-researcher
**Patterns:** *(filled in over time)*
*(no entries yet)*

### grpc-schema
**Patterns:** *(filled in over time)*
*(no entries yet)*

### repo-ops
**Patterns:** *(filled in over time)*
*(no entries yet)*

### architect
**Patterns:** *(filled in over time)*
*(no entries yet)*

### auditor (parent + 7 subagents)
**Patterns:** *(filled in over time; track per subagent if distinct
patterns emerge)*
*(no entries yet)*

---

## User Friction Log

*Dated entries. Focus on observable friction: human confused, asked
twice, unexpected behavior, documented flow didn't match tool UX.*

*(no entries yet)*

---

## Pack Chat Open Questions

> **Context:** Q1–Q4 are seed questions from the v9 auditor fix pass —
> deferred because the pack repo has no real application code to test
> against. Q5–Q6 are coverage gap questions that apply to any project
> using platforms, IDEs, or languages where the pack's coverage is thin.
> All require real-world data from downstream projects.
>
> **The PM chat's job:** observe for data relevant to these questions
> during normal work. At every workflow-complete boundary, assess whether
> new observations are sufficient to transition any question from Not
> Ready to Ready (see the status state machine in `## How to use this
> doc` above). When a question reaches Ready, generate the delivery
> prompt and present it to the user. The user should never have to
> remind you to check these.

### Q1 — Observability infrastructure vs. configuration boundary

**Asked by Pack Chat:** [v9 release date]
**Question:** The auditor splits observability into
`auditor-architecture` (does the wiring *exist* in code — logger
abstractions, metric collection points, trace propagation?) and
`auditor-ops` (is it *configured correctly* for the deployment target —
JSON logging, metrics endpoint exposed, tracing exporter?). See
`audit-methodology` rule 21.

Does this split hold in practice? When a real observability finding
surfaces, does the correct cluster own it? Are duplicates resolved
cleanly via ownership precedence (rules 33–39)? Are there findings at
the boundary where neither cluster owns them?

**Expected data source:** first auditor run on a project with
cloud-deployed observability (e.g., Python server with structured
logging + metrics export + OpenTelemetry tracing).

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet — waiting for first real audit)*
**Answer:** *(filled when Status reaches Ready or later)*

### Q2 — Systemic error handling threshold

**Asked by Pack Chat:** [v9 release date]
**Question:** `auditor-code` surfaces "systemic error handling" —
cross-cutting patterns like boundary mapping consistency and retry
policy uniformity — as distinct from per-function error-handling bugs.
See `audit-methodology` rule 16.

Is the distinction clear enough in practice? Is there a natural
threshold (e.g., errors unmapped at 3+ boundaries = systemic; 1
boundary = per-function)? Does the error-handling skill contain the
right mix of systemic and per-function rules?

**Expected data source:** first auditor run on a Swift or Python
codebase with non-trivial error-handling across module boundaries.

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet — waiting for first real audit)*
**Answer:** *(filled when Status reaches Ready or later)*

### Q3 — auditor-ui scope breadth

**Asked by Pack Chat:** [v9 release date]
**Question:** After the v9 split, `auditor-ui` covers only: view
thickness, accessibility gaps, incomplete UI states, platform UI
conventions. See `audit-methodology` rule 20.

On a real Apple project with substantial UI, does this cover enough?
Missing areas to watch for: localization, dark mode, Dynamic Type,
iPad split-view, custom gestures, watchOS/tvOS layouts. Is the scope
the right narrowness, or too narrow?

**Expected data source:** first auditor run on a real iOS or iOS+macOS
project with non-trivial UI.

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet — waiting for first real audit)*
**Answer:** *(filled when Status reaches Ready or later)*

### Q4 — python-architecture skill loading for non-server Python

**Asked by Pack Chat:** [v9 release date]
**Question:** `PLATFORM-SKILLS.md` loads `python-architecture` for
`auditor-code` only when a Python server is present. But performance
anti-patterns apply to any multi-file Python project. Should
`python-architecture` also load for non-server Python (CLI tools,
libraries, pipelines)?

**Expected data source:** first auditor run on a non-server multi-file
Python project.

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet — waiting for first real audit)*
**Answer:** *(filled when Status reaches Ready or later)*

### Q5 — IDE and editor coverage gaps

**Asked by Pack Chat:** [v9 release date]
**Question:** The pack has deep Xcode integration (companion templates,
`agent-post-edit-check.sh` hook, `XCODE_SCHEME` / `XCODE_DESTINATION`
config, iOS 26 doc sync). VS Code has basic companion templates but
minimal workflow guidance. JetBrains, Cursor, and other editors have
nothing.

Does the pack's guidance work for the IDE this project actually uses?
What workflow guidance, hook integration, or editor-specific configuration
is missing? If the project uses Xcode exclusively, note any Xcode-specific
gaps instead (e.g., Xcode 27 features the pack doesn't cover). If the
project uses multiple editors (e.g., VS Code for Python, Xcode for Swift),
note where the handoff between them is unclear.

**Expected data source:** any project, regardless of IDE. Apple-centric
projects can report Xcode gaps; non-Apple projects will surface
editor-coverage gaps naturally.

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet)*
**Answer:** *(filled when Status reaches Ready or later)*

### Q6 — Platform update cycle

**Asked by Pack Chat:** [v9 release date]
**Question:** When a major platform update ships (new OS version like
iOS 27 or macOS 27, new language version like Python 3.14 or Swift 7,
new framework release, new CLI tool version), the pack's skills and
context files may become stale. Availability guards, API references,
deprecated patterns, and tool-specific flags can all drift.

How does this project discover that pack content needs updating after a
platform update? Was there a lag between the update shipping and the
project noticing stale pack content? What content was affected (skills,
context files, scripts, agent behavior)? How was the gap surfaced —
did an agent give wrong advice, did a skill reference a deprecated API,
did a context file have stale availability guards, or did the user
notice manually?

**Expected data source:** any project that encounters a platform update
while using v9. May take months to produce data — that's expected.

**Status:** Not Ready
**Last updated:** [v9 release date] (seeded)
**Observations so far:** *(none yet)*
**Answer:** *(filled when Status reaches Ready or later)*

---

## Delivery Log

*Record of every feedback batch delivered to the Pack Chat. Append-only.*

| Date | Delivered sections | Pack Chat disposition | Notes |
|---|---|---|---|
| *(no deliveries yet)* | | | |
<!-- DENY-LIST-CONTENT-END -->
