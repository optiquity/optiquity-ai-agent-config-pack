---
name: implementation
description: Use when adding code, fixing bugs, or making targeted refactors after the task is understood.
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
---

## Before writing code

1. Read the existing code path before introducing changes. Understand the current design, naming conventions, and patterns before modifying them.
2. Identify the smallest correct change that satisfies the task. Avoid bundling unrelated improvements.
3. For non-trivial changes, state the plan before executing: which files change, what each change does, and how to verify it.

## Making changes

4. Match the local style when it does not violate project rules. Consistency within a file is more important than personal preference.
5. Break multi-file changes into logical steps. Each step should leave the codebase in a buildable, testable state.
6. When adding a new type, function, or module, place it where existing similar items live. Do not create new organizational patterns without justification.
7. Extract common logic only when it is used in three or more places. Premature abstraction is worse than duplication.
8. When fixing a bug, make the minimal fix first. Refactor the surrounding code in a separate step if needed.

## Concurrency and safety

9. Every concurrency annotation, thread-safety marker, or unsafe escape must be intentional. Document non-obvious choices in code comments. See the project's language-specific skills for the exact annotations and constructs that require justification.
10. Never introduce unsafe constructs (force unwraps, unchecked type-safety overrides, bare unhandled errors) without documented justification.
11. Validate all external input at the boundary where it enters the system.

## After writing code

12. Run the build. Fix all compiler errors and warnings before proceeding.
13. Run the test suite. Fix any regressions introduced by the change.
14. Review your own diff before submitting. Check for: accidentally committed debug code, missing test updates, files that should not have changed.
15. Report the change in the completion report: what changed, which files were created or modified, and the verification path.
