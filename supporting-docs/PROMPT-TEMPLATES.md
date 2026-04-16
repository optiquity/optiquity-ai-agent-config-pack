# PROMPT-TEMPLATES.md — Agent Prompt Templates

Version: 2.0 (v9, April 2026)

---

## How to use these templates

These templates are **starting points**. The PM chat should customize, expand, or
contract each prompt based on:
- The specific project and its CLAUDE.md rules
- The current phase number and its tasks from IMPLEMENTATION_PLAN.md
- Context from recent code and doc reviews
- The platform (Swift, Python, or both)

Phase numbers, file names, scheme names, and verification commands must be updated
for each use. Remove sections that don't apply to the current phase.

---

## Prompt Authoring Principles

> **Read this before generating any prompt.**
> Full details in `METHODOLOGY.md` — Prompt Authoring Principles section.

**The core rule:** Describe the *problem*, *goal*, and *success criteria* — not the solution.

Every prompt must answer:
- **Problem** — root cause at category level; enough scope for the agent to recognize all
  instances within the files-in-scope list, but no description of the solution
- **Goal** — what correct behavior looks like when done; outcome, not steps
- **Success criteria** — the observable, verifiable state that confirms the goal is achieved;
  what can be checked to know the task is complete; not a solution — the end state, not the path
- **Context** — what the agent cannot infer from ARCHITECTURE.md
- **Required reading** — distinguish files for understanding from files in scope to modify
- **Files in scope** — primary boundary; agent may make small focused changes to unlisted
  supporting files only if disclosed in an **"Unplanned file modifications"** section of the
  completion report; all other out-of-scope discoveries are reported, not fixed
- **Completion report** — files modified, verification results, out-of-scope discoveries

**Never include** in a prompt: pseudocode, implementation steps, pattern choices, or
proposed solutions (unless architecturally mandated in ARCHITECTURE.md).

**Scoping the problem:** Use root-cause framing, not file/line references. The
files-in-scope list does the bounding — keep it tight. If affected scope is unknown,
instruct the agent to audit the listed files and report findings for a follow-up decision.

**Exceptions by agent:**

| Agent | May prescribe | Must not prescribe |
|---|---|---|
| `reviewer` | Review criteria, output format, verification commands | Which issues to overlook |
| `docs-researcher` | Claims to verify, URLs, output format | How to resolve discrepancies |
| `repo-ops` / standard `claude` | Exact operations (fully mechanical) | N/A |
| `tester` | Audit scope, output format | Test patterns or structures |
| `coder` | Files in scope, verification commands, report format | Implementation approach, pseudocode |
| `architect` | Problem statement and required reading only | All solutions, pattern names, structural direction |
| `planner` | Scope to break down | How to break it down |
| `auditor` (parent + subagents) | Skip rules, file scopes, platform skills to load, output format from `audit-methodology` | Which findings to surface or hide, how to fix anything |

**When using IMPLEMENTATION_PLAN.md task entries:** If a task entry contains
implementation instructions rather than a problem/goal/success-criteria description,
reframe it before including it — extract what is wrong, what correct behavior looks
like, and what confirms the task is complete. Discard the how. Apply to coder, architect,
and planner prompts. For agents where prescriptive content is permitted (see table above),
forward plan content as written.

**Multi-part phases:** When a phase is split into sequential implementation chunks, use
**Part [M]** (not "pass") appended to the phase title in all report headers. Pass numbers
reset to 1 for each new part. Single-part phases use the existing header format — do not
append `, Part 1`. Full convention in METHODOLOGY.md Part 4.
- Example: `Phase 12 — Auth Flows, Part 2 — Reviewer Report, Pass 1`

**Self-check:** Before generating any prompt, ask: *"Am I describing what needs to be
true, or how to do it?"* If "how to do it" — rewrite as "what needs to be true."

---

## Template 1 — PM Chat Kickoff Prompt

*Paste this at the start of a new PM chat session to establish project context.*
*Fill in all [PLACEHOLDERS] before pasting.*

---

I am starting a new Claude Chat session for **[PROJECT_NAME]**.

**Project:** [2-3 sentence description of what the project is and does]
**Platform:** [e.g., macOS 15+, Xcode 26.3, Swift 6 / Python 3.12+]
**Current phase:** Phase [N] — [Phase title] ([not started / in progress])
**Pack version:** AI Agent Config Pack v8

**Key architectural decisions already made:**
- [Architecture pattern, e.g., MVVM with layered domain/data/presentation]
- [Key protocol decisions, e.g., DataStore protocol over SwiftData]
- [Any other settled decisions]

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


---

## Template 2 — Coder Prompt (Standard Structure)

*Generated by PM chat for each implementation phase.*

---

Read `ARCHITECTURE.md` in full. Read `CHANGELOG.md`. Read `IMPLEMENTATION_PLAN.md`
Phase [N] in full. Then read these specific files: [LIST FILES].

**Scope constraint:** Your primary task list is below. Do not modify files unrelated to
this phase. Do not modify `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, or `BACKLOG.md`.
If during implementation you identify a supporting file not listed here that requires a
small, focused change to expose data this phase genuinely needs (e.g., a new read-only
accessor, a new protocol method with a default no-op, or a minor addition to an existing
type), you may make that change — but you must call it out explicitly in your completion
report under a dedicated **"Unplanned file modifications"** section, stating the file,
the change, and why the listed task could not be completed without it. Do not use this
escape valve for broad refactors, new feature work, or changes that belong in a separate
phase.

**Root .md file prohibition:** Do not write to `CHANGELOG.md`, `STATUS.md`,
`BACKLOG.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `CLAUDE.md`, `AGENTS.md`,
`README.md`, or any other `.md` file in the project root. Writing root `.md` files is
exclusively the PM chat's responsibility.

**Deferral comments:** If during implementation you encounter work that cannot be
completed within this phase scope, add a typed deferral comment using exactly this
syntax (use the comment marker for the language you are writing):
```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(critical|functional|polish): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```
Always write `TD-TBD` — never invent a TD number. Report every deferral comment
you add in the "Deferred items" section of your completion report. Do not write
to `BACKLOG.md` — the PM chat handles that after user review.

**Next available TD number (for PM chat reference only — coder writes TD-TBD):** TD-[NNN]

**Tasks:**

1. [TASK DESCRIPTION — specific, measurable, with exact file paths]
   - Files to create: [list]
   - Files to modify: [list]
   - Definition of done: [verifiable criterion]

2. [NEXT TASK]

**Verification:** After all tasks, run:
```bash
./scripts/format.sh
./scripts/validate.sh
```
Confirm all tests pass and zero compiler warnings remain. `format.sh` exits 0 if swift-format is not installed — this is acceptable. `validate.sh` must exit 0 with zero warnings.

**Completion report:** Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Coder Report, Pass 1`
Then report which files were modified and the final test count.
[If this is the last task in the phase:] Include a **"Proposed CHANGELOG entry"** section
in this report, formatted exactly as it would appear in `CHANGELOG.md`: dated header,
summary paragraph, files created/modified list, and test count. Do not write to
`CHANGELOG.md` or any other `.md` file in the project root — the PM chat applies the
entry after reviewer approval.

**Unplanned file modifications** (required section — write "None" if no unlisted files were changed):
For each file changed that was not in the task scope:
- File: `path/to/file`
- Change: [brief description of what was added or modified]
- Why necessary: [why the listed task could not be completed without this change]

**Deferred items** (required section — write "None" if nothing was deferred):
For each deferral comment added this session:
- Comment: [exact comment text as written in the file]
- File/Symbol: `path/to/file` — `SymbolName`
- Description: [what the work is and why it cannot be done now]
- Blocker: [the specific dependency or condition preventing completion]
- Context: [any constraints or observations relevant at deferral time]

---

## Template 3 — Reviewer Prompt (Standard Structure)

*Generated by PM chat after coder completes a phase.*

> **This is a read-only review pass. Do not modify any files. Output a report only.**

---

This is reviewer pass **[N]** for Phase **[X]**.
[If N > 1:] The previous pass ([N-1]) had the following open ❌/⚠️ issues that the coder was asked to fix:
[PM chat inserts the open issue list from the prior reviewer report here]

Read `ARCHITECTURE.md` in full. Read `CHANGELOG.md` (Phase [X] entry).
Read `CLAUDE.md`. Read `IMPLEMENTATION_PLAN.md` Phase [X] in full.
Then read all files modified in Phase [X]: [LIST FILES].

Review for all eight of the following — do not skip any:

1. **Architecture compliance** — layer boundaries respected, no forbidden imports in
   domain files, no concrete types crossing layer boundaries
2. **Platform concurrency correctness** —
   Swift: actor isolation explicit and correct, no undocumented `@unchecked Sendable`, no data races;
   Python: async handler correctness, no blocking synchronous I/O in async paths
3. **Anti-pattern violations** — check against the anti-patterns list in `CLAUDE.md`
4. **Implementation plan compliance** — does the code match what Phase [N] specified?
   Any tasks done incorrectly or incompletely?
5. **Test coverage** — are the definitions of done from the implementation plan verified by tests?
6. **Build warnings** —
   Swift: run `xcodebuild build -scheme [XCODE_SCHEME] -destination '[XCODE_DESTINATION]' 2>&1 | grep "warning:"` and report any warnings;
   Python: run `ruff check` and `pyright` and report any warnings.
   Zero warnings is the standard.
7. **BACKLOG and deferral comment hygiene** —
   Run `grep -rn "TD-TBD" .` on all files modified in this phase. Any result is ❌ FAIL —
   it means the PM chat has not yet processed the coder's deferred items report and the
   session must not proceed to commit.
   Check that all deferral comments in reviewed files use the typed format
   (`// TODO(`, `// KNOWN GAP(`, `// VERIFY(` or language equivalents).
   Any plain-English deferral comment (e.g. `// Fix later`, `// Confirm this`) is ⚠️ WARN.
   For each TD-NNN found in reviewed files, confirm a matching BACKLOG entry exists.

8. **Unplanned file modifications** — if the coder's completion report includes an
   **"Unplanned file modifications"** section, review each disclosed change:
   - Was the change genuinely necessary for the listed tasks to compile or function correctly?
   - Is it small and focused (a new accessor, a protocol method, a minor addition to an existing type)?
   - Does it comply with architecture rules, layer discipline, and the anti-patterns list?
   ✅ PASS if the change is necessary, minimal, and compliant.
   ❌ FAIL if the change is a broad refactor, introduces new feature work, violates layer
   rules, or is not disclosed in the completion report.
   If no "Unplanned file modifications" section is present and no unlisted files were
   changed, this item is N/A.

[Add any phase-specific focus areas here — these are in addition to the eight above, not a replacement.]

**Verification** (run after reviewing, report results):
```bash
[VERIFICATION COMMAND — e.g., ./scripts/test.sh or pytest]
```
Confirm all tests pass.

**Output format:**
Begin the report with this header line as the very first line of output:
`Phase [X] — [Phase title] — Reviewer Report, Pass [N]`
Then list findings:
- ✅ PASS — [finding description]
- ❌ FAIL — [finding]: [exact description of what's wrong and what file/line]
- ⚠️ WARN — [finding]: [description — PM chat determines response via triage protocol]

**Pass summary (required at end of report):**
- Pass number: [N] for Phase [X]
- Regressions: [list any items that were ✅ in the previous pass and are now ❌ or ⚠️, or "None"]
- New issues this pass: [count of ❌/⚠️ items not present in the previous pass]
- Open issues previous pass: [count from prior pass, or "N/A — first pass"]

End with one of:
**Verdict: Ready to commit** — all ❌ items resolved
**Verdict: Needs fixes** — list all ❌ items that must be resolved first

---


---

## Template 4 — Fix Cycle Prompt

*Generated by PM chat after the fix plan has been presented and the user has given
explicit approval. Do not generate this prompt until the plan is approved.*

---

> **PM chat must describe problems, not solutions.** Each fix entry states what is
> wrong and why, what correct behavior looks like, and how the reviewer will verify the
> fix. It does not provide pseudocode, implementation steps, or code of any kind.
> The coder agent determines how to fix it.

Read `ARCHITECTURE.md` in full. Read `IMPLEMENTATION_PLAN.md` Phase [N].
Read these specific files: [LIST AFFECTED FILES].

**Root .md file prohibition:** Do not write to `CHANGELOG.md`, `STATUS.md`,
`BACKLOG.md`, `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `CLAUDE.md`, `AGENTS.md`,
`README.md`, or any other `.md` file in the project root. Writing root `.md` files is
exclusively the PM chat's responsibility.

The reviewer found the following issues that must be fixed before committing.
Fix each issue so that it meets the expected behavior described. Do not make changes
beyond what is required to resolve the listed issues. The same escape valve as in the
coder prompt applies: if a fix genuinely requires a small, focused change to an unlisted
supporting file, make it and disclose it in the completion report under **"Unplanned
file modifications."**

**❌ Fix 1 — [Issue title]**
File: `[path/to/file]`
Problem: [exact description of what is wrong and why]
Expected behavior: [what correct behavior looks like — no implementation instructions]
Success criteria: [what the reviewer will check to confirm this fix is complete]

**❌ Fix 2 — [Issue title]**
File: `[path/to/file]`
Problem: [exact description of what is wrong and why]
Expected behavior: [what correct behavior looks like — no implementation instructions]
Success criteria: [what the reviewer will check to confirm this fix is complete]

**Deferral comments:** If during a fix you encounter related work that cannot be
completed within this fix cycle's scope, add a typed deferral comment:
```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(critical|functional|polish): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```
Always write `TD-TBD` — never invent a TD number. Report every deferral comment
you add in the "Deferred items" section of your completion report.

**Verification:** After all fixes, run:
```bash
[VERIFICATION COMMAND]
```
Confirm all tests pass and zero warnings remain.

**Completion report:** Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Fix Cycle Coder Report, Pass [N]`

**Fixes applied** (one entry per ❌ item addressed):
- Fix [N] — [Issue title]: [what was changed to resolve it — no implementation detail, just what changed]

**Files modified:** [list all files changed]

**Unplanned file modifications** (required section — write "None" if no unlisted files were changed):
- File: `path/to/file`
- Change: [brief description of what was added or modified]
- Why necessary: [why the listed fix could not be completed without this change]

**Deferred items** (required section — write "None" if nothing was deferred):
For each deferral comment added this session:
- Comment: [exact comment text as written in the file]
- File/Symbol: `path/to/file` — `SymbolName`
- Description: [what the work is and why it cannot be done now]
- Blocker: [the specific dependency or condition preventing completion]
- Context: [any constraints or observations relevant at deferral time]

**Validation:** [test count and confirmation that zero warnings remain]

**Note:** Do not include a Proposed CHANGELOG entry. The PM chat will update the entry
proposed in the initial coder pass to reflect any changes made in fix passes before
applying it to `CHANGELOG.md`.

---

## Template 4b — Mid-Phase Architect Prompt

*Generated by PM chat when Trigger A or Trigger B is met during Workflow 4.*
*This prompt is only sent after the user has explicitly approved an architect pass.*
*The architect agent is read-only — it proposes doc changes as text output only.*
*The PM chat presents the proposed changes to the user for approval before applying them.*

---

> **This is a read-only analysis pass. Do not modify any files. Output proposed
> changes as text only. The PM chat will apply approved changes after this session.**

Read `ARCHITECTURE.md` in full. Read `IMPLEMENTATION_PLAN.md` Phase [N] in full.
Read `CLAUDE.md` in full. Read `AGENTS.md` in full.
Then read these specific files that the reviewer flagged: [LIST FILES FROM REVIEWER REPORT].

**Context — why this architect pass was triggered:**
[PM chat describes: which trigger fired (A or B), how many coder passes have run,
and the pattern of reviewer findings that indicates a design problem]

**Reviewer findings that this pass must address:**
[PM chat inserts the full ❌ and ⚠️ list from the most recent reviewer report]

**Your task:**
Identify the root cause of the recurring or worsening reviewer findings. Do not
assume the coder is making mistakes — assume the design documentation is ambiguous,
incomplete, or incorrect and is causing the coder to produce the wrong result.

For each root cause you identify:
1. Name it precisely — which section of which document contains the problem
2. Explain why it causes the reviewer findings
3. Propose the exact text change to `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`,
   or (only if no other doc can address it) `CLAUDE.md` or `AGENTS.md`

Format each proposed change as:

**Proposed change [N] — [Document name], [Section name]**
Root cause: [explanation]
Current text: [quote the existing text]
Proposed replacement: [exact new text]
Why this fixes it: [explanation]

Do not propose source code changes. Do not run any build or test commands.
Output proposed doc changes only.

---

## Template 5 — Tester Prompt (Test Strategy, Read-Only)

*Generated by PM chat before implementing tests for a complex phase.*

---

Read `ARCHITECTURE.md` in full. Read `CHANGELOG.md`. Read `BACKLOG.md`.
Use Glob to list every source file. Read them all. Build your own complete
inventory — do NOT rely on any pre-specified list of components.

Produce a test strategy for Phase [N] / [COMPONENT SCOPE].

For each component:
- What is currently tested (cite file and test suite name)
- What critical behaviors are NOT tested
- Which BACKLOG items relate to this component with no test coverage
- What type of test is appropriate (unit / integration / UI)
- What test doubles are needed

End with a Priority Summary: top gaps ranked by likelihood of catching a real bug,
with the specific test to write and the failure it would catch.

**Report header (first line of output):**
`Phase [N] — [Phase title] — Tester Report`

**Constraint:** Output a report only. Do not write any test code.

---

## Template 6 — Docs-Researcher Prompt

*Generated by PM chat for external API research or doc verification.*

---

Read `ARCHITECTURE.md` §[RELEVANT SECTIONS]. Read `IMPLEMENTATION_PLAN.md` Phase [N].

Your job is to VERIFY the following assumptions against current official documentation.
Do not confirm them — check their accuracy and flag any discrepancy.

**Items to verify:**

1. [SPECIFIC CLAIM TO CHECK]
   Check against: [URL]

2. [SPECIFIC CLAIM TO CHECK]
   Check against: [URL]

**Output format:**
Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Docs-Researcher Report`
Then list findings:
- ✅ CONFIRMED — [topic]: [evidence + source URL]
- ⚠️ DISCREPANCY — [topic]:
  What the plan assumes: [...]
  What the docs actually say: [...]
  Impact: [...]
  Required change: [...]

Separate confirmed facts from unverified assumptions. Cite sources for everything.
Do not make any code changes.

---

## Template 7 — Planner Prompt

*Optional — generated by PM chat for complex phases that need breakdown first.*

---

Read `ARCHITECTURE.md` in full. Read `IMPLEMENTATION_PLAN.md` Phase [N].
Read these files: [LIST RELEVANT FILES].

Break Phase [N] into ordered implementation tasks. For each task:
- What exactly needs to be done
- Which files will be created or modified
- What the verifiable definition of done is
- What the risk is and how to detect a problem early

Name any dependencies between tasks (which must complete before another can start).
Identify the highest-risk task and suggest how to approach it first.

Begin the output with this header line as the very first line:
`Phase [N] — [Phase title] — Planner Report`
Then output only the task breakdown and risk analysis. Do not write any code.

---


---

## Template 8 — BACKLOG / STATUS Update Prompt

*PM chat only — requires explicit user approval before executing. Do not use this
template to make changes the user has not reviewed and approved.*

---

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

Confirm what was changed.

---

## Template 9 — Auditor Invocation Prompt

*For the `auditor` parent agent — runs a full-codebase structural audit.
Spawns up to seven read-only subagents (one per cluster) and consolidates
their reports. See the `audit-methodology` skill for cluster definitions,
file scopes, severity scale, pass/fail thresholds, and report format.*

---

You are the audit coordinator. Run a full-codebase structural audit per the
`audit-methodology` skill.

**Skip rules for this project:** [PM CHAT FILLS THIS IN — for example:
"Skip auditor-ui (server-only project, no UI layer). Run the six
remaining clusters." Or: "Run all seven clusters." Or: "Skip auditor-tests
(first audit of a brand-new project) and auditor-ui (server-only). Run
the five remaining clusters." Note: auditor-ops is never skippable per
audit-methodology rule 46.]

**Platform skills to load per subagent** (the parent loads only `audit-methodology`;
each subagent loads the platform skills relevant to its cluster from the
project's PLATFORM-SKILLS.md profile):
- `auditor-architecture`: [PM CHAT FILLS — e.g., apple-architecture-core, ios-architecture, python-architecture]
- `auditor-code`: [e.g., swift-best-practices, python-best-practices, error-handling]
- `auditor-tests`: [e.g., testing, ui-test-strategy]
- `auditor-docs`: documentation
- `auditor-security`: security-patterns, dependency-swift, dependency-python
- `auditor-ui`: [if not skipped — e.g., apple-architecture-core, ios-architecture, swift-best-practices]
- `auditor-ops`: [e.g., deployment-apple, deployment-python]

**File scope guidance.** Compute per-subagent file scopes per
`audit-methodology` rules 25–32. Apply the always-exclude list (rule 25):
`**/.git/**`, `**/.build/**`, `**/DerivedData/**`, `**/node_modules/**`,
`**/.venv/**`, `**/Pods/**`, `**/__pycache__/**`, `**/generated/**`,
`**/*_pb2.py`, `**/*.pb.swift`, `**/*.pb.go`. Never pass generated code,
vendored dependencies, or test fixtures to any subagent.

**Spawn the subagents** per the per-tool mechanism (rules 56–60):
- Claude Code: parallel `Task` tool calls in a single message
- Codex CLI: native subagent invocation via `max_depth=2` config
- Gemini CLI: native subagents in `.gemini/agents/`, but subagents cannot call
  subagents — `agent-run.sh run_gemini_auditor` provides external orchestration

**Consolidate the reports** per rules 48–55:
1. Executive summary: total findings per severity, top 3 issues (highest
   severity first; tie-break by cluster order from rule 38), pass/fail
   verdict per rules 11–13, any skipped subagents with reason.
2. Append all subagent reports in cluster order (rule 53):
   security → architecture → tests → ops → code → ui → docs.
3. Resolve duplicates per ownership precedence rules 33–39. When a finding
   is attributed to one cluster, annotate the surviving entry with
   `(also detected by: <other-clusters>)` and remove the duplicate. Apply
   severity reconciliation per rule 39 — higher severity always wins.
4. Append a `## Next steps` section listing Critical and Major findings
   in priority order, cross-referencing this PM chat's BACKLOG processing
   workflow (METHODOLOGY.md Part 6).

**Constraint:** Read-only audit. Do not write to BACKLOG.md, STATUS.md, or
any other project file. Return the consolidated report to the developer.

---

## Templates 10–12 — Superseded

Templates 10 (Documentation Audit), 11 (Architecture / LSP Audit), and 12
(UI Audit) have been consolidated into Template 9 (Auditor Invocation).
The auditor's seven-cluster architecture covers all three audit dimensions
(plus four additional ones) in a single coordinated run with deduplicated
findings and a unified severity scale.

If you need to audit only one dimension — for example, to verify a fix — run
the corresponding subagent directly per `audit-methodology` rule 70:

```
./agent-run.sh <cli> --agent auditor-docs        # documentation drift
./agent-run.sh <cli> --agent auditor-architecture # layer/LSP/coupling
./agent-run.sh <cli> --agent auditor-ui          # view-thickness/accessibility
```

The subagent reports directly to the terminal; the parent is bypassed.

---

## Template 13 — Generate SETUP.md for This Project

*PM chat fills this in using SETUP_TEMPLATE.md from the pack.*

---

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

---

## Template 14 — Generate AGENT_KICKOFF.md for This Project

*PM chat fills this in using AGENT_KICKOFF_TEMPLATE.md from the pack.*

---

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

---

*Version 2.0 — AI Agent Config Pack v9, April 2026*
*These templates are starting points. Customize per project and phase.*
