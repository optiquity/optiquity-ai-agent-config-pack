# PROMPT-AUTHORING.md — Directory guidance

This directory contains one file per agent. The PM chat reads
`<agent>.md` on demand, locates the requested variant by its `##
Variant: <slug>` heading, copies the body, and customizes it for the
task at hand. Read this file before generating any prompt.

## How to use these templates

These templates are **starting points**. The PM chat should customize, expand, or
contract each prompt based on:
- The specific project and its CLAUDE.md rules
- The current phase number and its tasks from IMPLEMENTATION_PLAN.md
- Context from recent code and doc reviews
- The platform (Swift, Python, or both)

Phase numbers, file names, scheme names, and verification commands must be updated
for each use. Remove sections that don't apply to the current phase.

## Per-agent exceptions

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

## Self-check

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

## Full authoring standard

See `supporting-docs/METHODOLOGY.md` § **Prompt Authoring Principles** for the full
authoring standard — problem/goal/success-criteria framing, required-reading vs
files-in-scope distinction, completion-report conventions, and the "describe the
problem, not the solution" rule.
