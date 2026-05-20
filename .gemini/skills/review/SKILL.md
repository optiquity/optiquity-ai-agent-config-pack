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

## Carry-forward discipline

A reviewer may surface a finding as "end-of-batch carry-forward" (or any analogous "defer to later phase / later BD / later batch" framing) ONLY if the finding meets ALL THREE of the following high-bar tests. This rule operationalizes pack memory "Deferral IS scope creep" (see trinity Pack memory § Workflow) inside the review process itself, so deferral discipline is enforced at the moment findings are classified — not after the fact.

1. **SIZE.** The finding requires architect-pass material work — new design surface, new contract negotiation, structural change spanning multiple files or layers. NOT "feels big" — provide a concrete file/contract surface argument (which files, which contracts, which design decisions are open).
2. **BLOCKED.** Real dependency on a not-yet-landed artifact — a sibling BD's implementation, a tool/framework version not yet adopted, a fixture or test harness not yet built. NOT "feels related" — name the specific blocker and the unblock event.
3. **LOGICAL FIT.** The finding cleanly belongs with another sibling BD/commit (concrete same-file / same-contract / same-symbol fit). NOT "thematic resemblance," "broader pattern," or "related area."

**Default: FIX NOW.** Every finding that does NOT meet ALL THREE tests must be surfaced as an in-scope review finding (BLOCKER / MUST / SHOULD / NIT) for fix-now triage by Pack Chat, not deferred to a later reviewer pass. Pack Chat's default-fix-all triage discipline (pack memory `feedback-fix-all-review-findings`) requires every finding to be visible at fix-or-defer triage time; carry-forward is not a way to bypass that triage.

**Forbidden carry-forward shapes.** These framings are NOT acceptable carry-forwards; the reviewer must classify them as in-scope findings (fix in the current cycle; expand the in-scope finding's scope to cover the broader pattern if needed):

- *"This is a broader pattern than just this commit."* — If the pattern is fixable now, expand the in-scope finding's scope to cover the pattern. Do not defer.
- *"End-of-batch reviewer might consider…"* / *"Worth ~N minutes of attention before the batch closes."* — If it's worth N minutes, it's a fix-now finding, not a carry-forward. N minutes does not justify deferral.
- *Forward-looking conjecture* (*"X is likely to grow"*, *"this could drift"*). — Not a finding; do not surface unless it represents a current defect with concrete evidence.
- *Design ratification* (*"this is a feature, not a bug"*, *"acknowledged tradeoff"*). — Not a finding; do not surface.
- *"Pack memory rule X recommends fix-now"* stated as the rationale but presented as carry-forward. — If pack memory recommends fix-now, surface as fix-now; do not contradict pack memory by deferring.

**If a finding qualifies as a true carry-forward**, explicitly cite which test it passes in the report using this format:

> CARRY-FORWARD: SIZE / BLOCKED / LOGICAL-FIT — &lt;concrete evidence: which files, which blocker, which sibling BD&gt;

If it does not qualify, surface it as a regular in-scope finding with severity. Hope is not a plan. Carry-forward without high-bar justification is tech debt accumulation by another name.
