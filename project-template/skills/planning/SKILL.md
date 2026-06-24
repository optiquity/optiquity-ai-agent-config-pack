---
name: planning
description: Use when scoping non-trivial work, sequencing implementation, or deciding how to verify a change.
allowed-tools: Read, Grep, Glob, Bash
---

This skill is loaded by the adversarial planner-review stage of the large-phase development pipeline standard (METHODOLOGY Workflow 4.5).

## Scoping

1. Restate the goal in repo-specific terms — name the files, modules, and interfaces involved.
2. Identify what already exists that can be reused, extended, or must be modified.
3. Distinguish between what is in scope (must be done now) and what is adjacent (could be done but is not required). Flag adjacent work as potential future items, not current tasks.
4. If the scope is unclear, list the ambiguities explicitly and request clarification before planning.

## Task breakdown

5. Break the work into small, independently verifiable steps. Each step produces a testable outcome.
6. Order steps so that no step depends on a later step. When dependencies exist between steps, make them explicit.
7. Identify steps that can be parallelized (independent changes in different files or modules) vs. steps that must be sequential (one step's output is another's input).
8. Size each step so it can be completed and verified in one agent session. If a step requires multiple sessions, split it.

## Dependency and risk identification

9. Name external dependencies that could block progress: missing APIs, unresolved design questions, unavailable test infrastructure.
10. Identify the highest-risk step — the one most likely to require rework. Schedule it early so failures surface sooner.
11. For each risk, state the rollback plan: what happens if this step fails or produces an unexpected result.
12. Do not invent APIs, configuration behavior, or framework capabilities. Verify that assumed interfaces exist before planning against them.

## Verification strategy

13. Name the verification method for each step before execution begins: test name, script to run, condition to check.
14. Define the overall success criteria: what must be true when all steps are complete.
15. Identify what the reviewer will check and preemptively address those concerns in the plan.
