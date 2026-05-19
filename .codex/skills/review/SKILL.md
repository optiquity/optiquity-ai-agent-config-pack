---
name: review
description: Use when reviewing correctness, regressions, missing tests, concurrency safety, or architecture drift.
allowed-tools: Read, Grep, Glob, Bash
---

## Review priorities (check in this order)

0. **Boundary discipline** — If reviewing a change to a file that ships to client repos (`project-template/` trees, or any pack-shipped client-installable surface), verify the change does NOT introduce references to pack-only files, pack-only mechanisms, pack-* agent names, or the `Pack Chat` orchestrator role. If it does, the finding is blocking. See trinity Pack memory `P-missed-7` for the underlying rule and worked examples; load the `boundary-investigation` skill for the SSOT-investigation methodology and the canonical deny-list. Frame-rotation reminder: when reviewing a commit or batch that touches both pack-side and project-side files, rotate frames — pack-side correct answer cites pack-side SSOT; project-side correct answer cites project-side SSOT.
1. **Correctness** — Does the code do what the task requires? Check logic errors, off-by-one mistakes, edge cases, nil/null handling, and boundary conditions.
2. **Security** — Check for credential exposure, injection vectors, unsafe deserialization, missing input validation, and overly broad permissions.
3. **Regressions** — Does the change break existing behavior? Check callers of modified functions, changed interface contracts, and removed functionality.
4. **Concurrency** — Check ownership of mutable state. Verify concurrency annotations and thread-safety markers are correct per the project's language-specific skills. Flag data races, missing locks, and unchecked safety overrides.
5. **Architecture compliance** — Does the change follow the project's layer discipline? Check for domain types leaking into transport or presentation layers, direct framework imports in the wrong layer, and navigation logic in ViewModels.

## What to examine

6. Read the implementation plan for the phase being reviewed. The code must match the plan. Deviations are findings.
7. Check every new type, function, and public API for appropriate naming, parameter types, and return types.
8. Verify error handling: no empty catch blocks, no swallowed errors, correct error propagation across boundaries.
9. Check test coverage: every behavior change should have a corresponding test change. Missing tests are findings.
10. Check for deferred work: `TODO`, `KNOWN GAP`, `VERIFY` comments must use the project's typed format with `TD-TBD`.

## Reporting findings

11. Every finding includes: severity (critical / major / minor), file and symbol, description of the issue, and recommended action.
12. Findings must be evidence-based. "This might have a problem" is not a finding. "Line 42 in UserService.swift catches RPCError but does not map it to a domain error, violating the error-handling boundary rule" is.
13. Distinguish between blocking findings (must fix before merge) and advisory findings (should fix but not blocking).
14. Acknowledge what the implementation got right. A review that only lists problems is incomplete — it must also confirm that the plan was followed and the success criteria are met.
