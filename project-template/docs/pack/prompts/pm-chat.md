---
agent: pm-chat
variants:
  - kickoff
  - backlog-status-update
  - generate-setup
  - generate-agent-kickoff
---

# pm-chat — PM chat templates

The `agent:` value `pm-chat` is reserved. The PM chat is the consumer
of these templates, not an agent. Each variant is a prompt the PM chat
either receives (kickoff, pasted by the developer) or composes and
uses on itself (backlog-status-update, generate-setup,
generate-agent-kickoff).

## Variant: kickoff

*Paste this at the start of a new PM chat session to establish project context.*
*Fill in all [PLACEHOLDERS] before pasting.*

**Before pasting:**
- If you are running Gemini CLI and currently in plan mode (`/plan`), exit plan mode before continuing — kickoff requires shell execution.
- If you are pasting this into Claude Web or ChatGPT Web without shell access, reply `manual` when asked below.
- Shell-capable surfaces run kickoff auto-discovery (METHODOLOGY.md Procedure 7); non-shell surfaces use SETUP-NEW.md § Manual fallback.

I am starting a new Claude Chat session for **[PROJECT_NAME]**.

**Project:** [2-3 sentence description of what the project is and does]
**Platform:** [e.g., macOS 15+, Xcode 26.3, Swift 6 / Python 3.12+]
**Current phase:** Phase [N] — [Phase title] ([not started / in progress])
**Pack version:** AI Agent Config Pack v8

**Key architectural decisions already made:**
- [Architecture pattern, e.g., MVVM with layered domain/data/presentation]
- [Key protocol decisions, e.g., DataStore protocol over SwiftData]
- [Any other settled decisions]

**Before I do anything else:** I am about to run read-only discovery
commands and propose installs and file edits for your approval.
Confirm one of:

- `shell` — I have shell access on this surface (Claude Code CLI, Codex
  CLI, Gemini CLI, or Claude Desktop with Desktop Commander enabled).
- `manual` — I have no shell on this surface (Claude Web, ChatGPT Web).

Reply with the single word `shell` or `manual` before continuing.

**Project documents are in the GitHub repo.** The GitHub connector is connected.
Please search project knowledge to read:
- ARCHITECTURE.md
- IMPLEMENTATION_PLAN.md (current phase)
- STATUS.md
- BACKLOG.md

**Your role as PM chat:**
- Generate agent prompts for each phase (coder, reviewer, tester, docs-researcher)
- Analyze reviewer output and categorize findings
- Make architectural and planning decisions
- Never write code or make large file changes directly
- For small doc updates (STATUS.md, BACKLOG.md): use Desktop Commander if available,
  otherwise output content and git commands for me to run

Confirm you can see the project documents, then tell me the current state and what
we should do next.

If `PM-CHAT.md` exists in the project root with `[PROJECT_NAME]` still as a
placeholder, fill it in now: replace `[PROJECT_NAME]` with the actual project name,
update the "Additional project documents" section if needed, remove the template
comment block at the top, and commit it. This only needs to be done once.

If the **Active skills** line in the Skill loading section of `CLAUDE.md` still
contains placeholder text, populate it now: read `PLATFORM-SKILLS.md`, determine
the skill set for this project's type, and write the list. Apply the same line
to `AGENTS.md` and `GEMINI.md`. Commit.

---

**Next, based on your surface declaration:**

On `shell`: I will read `supporting-docs/METHODOLOGY.md` Procedure 7
directly (not via RAG — Procedure 7 is order-sensitive) and follow
its gates G7-discovery / G7-install / G7-edit / G7-machine before
any write or install.

On `manual`: I will point you at `supporting-docs/SETUP-NEW.md` §
Manual fallback (sub-sections 5.A–5.D) and wait for you to report
values back, then compose the corresponding edits for you to apply.

## Variant: backlog-status-update

*PM chat only — requires explicit user approval before executing. Do not use this
template to make changes the user has not reviewed and approved.*

Read `BACKLOG.md` [and/or `STATUS.md`] in full. Make exactly the following changes.
Do not modify any other file.

[DESCRIBE EXACT CHANGE — e.g.:]

**To add a new BACKLOG item:**
Add the following entry to BACKLOG.md:

```
**TD-[NNN] — [Short title]**
Type: TODO(scope) | KNOWN GAP(critical|functional|polish) | VERIFY(source)
Status: Open | Unblocked
Blockers:
  - [Named specific dependency — phase N, TD-NNN, or external condition]
  - [Additional blocker if any — all must resolve before item is actionable]
Unblocks: [TD-NNN, ...] or None
  ← informational only; PM chat derives actionability from Blockers, not this field
File/Symbol: `path/to/file` — `SymbolName`  ← optional; symbol name not line number; n/a if none
Description: [What the work is and why it was deferred]
Context: [What was known at deferral time — descriptive only, no proposed solution]
```

**To mark an item resolved, cancelled, or deprecated:**
Find TD-[NNN] and append the Resolution field:
```
Resolution: [date, one of: completed | cancelled | deprecated, brief note]
```
Change Status to: Resolved | Cancelled | Deprecated accordingly.
Do not delete the item or any other fields.

For Cancelled or Deprecated: after updating the item, flag all Open or Unblocked
items whose Blockers list names this TD-NNN for user review before proceeding.
Do not automatically unblock any of them.

**To update STATUS.md:**
- Mark Phase [N] as ✅ Complete in the phase table
- Update "Current Phase" to: Phase [N+1] — [Title] (not started)
- Update "Next Actions" to: [list]
- Update "Key Metrics" test count to: [N] passing, 0 failing
- Link every phase Title in the phase table to its heading in
  `IMPLEMENTATION_PLAN.md` using `[Title](IMPLEMENTATION_PLAN.md#anchor)` format.
  GitHub anchor: lowercase, spaces → hyphens, em-dash `—` removed (leaves `--`),
  special characters (backticks, colons, parentheses, periods, asterisks, slashes) stripped.
  Example: `## Phase 35 — Live Broker Sandbox Verification` →
  `[Live Broker Sandbox Verification](IMPLEMENTATION_PLAN.md#phase-35--live-broker-sandbox-verification)`.

Confirm what was changed.

## Variant: generate-setup

*PM chat fills this in using SETUP_TEMPLATE.md from the pack.*

Read `supporting-docs/SETUP_TEMPLATE.md` from the AI Agent Config Pack.
Using that template and our planning conversation, generate a complete `SETUP.md`
for [PROJECT_NAME].

Fill in all placeholder values based on what we have discussed:
- Project name: [PROJECT_NAME]
- GitHub username: [GITHUB_USERNAME]
- Repo name: [REPO_NAME]
- Platform: [PLATFORM]
- Xcode version: [XCODE_VERSION]
- Template to use: [TEMPLATE_NAME]
- Architect agent: [ARCHITECT_AGENT]
- [Any other project-specific values]

Remove any sections that don't apply to this project.
Output the complete SETUP.md content ready to save to the project root.

## Variant: generate-agent-kickoff

*PM chat fills this in using AGENT_KICKOFF_TEMPLATE.md from the pack.*

Read `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` from the AI Agent Config Pack.
Using that template and our architecture planning conversation, generate a complete
`AGENT_KICKOFF.md` for [PROJECT_NAME].

Fill in all placeholder values:
- Project description: [DESCRIPTION]
- Platform and targets: [PLATFORM]
- Architecture pattern: [PATTERN]
- External resources to read: [LIST WITH URLS]
- Key domain types: [LIST]
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
- Required stubs to generate: [LIST]
- Test infrastructure required: [LIST OR NONE]

Remove sections that don't apply.
Output the complete AGENT_KICKOFF.md content ready to save to the project root.
The developer will paste this directly into a CLI session with the architect agent:
`./agent-run.sh claude --agent architect` (or `codex`/`gemini` as appropriate).
