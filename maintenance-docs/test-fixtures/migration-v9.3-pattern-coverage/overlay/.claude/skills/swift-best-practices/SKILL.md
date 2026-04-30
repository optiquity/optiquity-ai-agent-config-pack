---
name: swift-best-practices
description: Use for Swift language patterns, concurrency, type system, Swift 6 strict concurrency rules, and idiomatic Swift style.
allowed-tools: Read, Grep, Glob, Bash
---

## Type system

1. Prefer `struct` for all model and data types. Use `class` only when reference semantics, identity equality, or Objective-C interop is required.
2. Mark classes `final` by default. Subclassing requires explicit justification.
3. Make invalid states unrepresentable — use enums with associated values over boolean flag combinations.
4. Prefer typed errors (`throws(SpecificError)` in Swift 6), typed IDs (UUID wrapped in a named struct), and explicit domain models over stringly typed state.
5. Use `@frozen` enums only in published frameworks where the case set is guaranteed stable. Never in apps.

## Immutability

6. `let` by default, `var` by exception. Every `var` requires a conscious decision.
7. All custom types are immutable by default. Mutable state requires documented justification.
8. Implement copy-on-write manually for value types wrapping reference types using `isKnownUniquelyReferenced`.
9. Configuration constants are `let`-bound. No global mutable config variables.

## Concurrency (Swift 6 strict)

10. `async`/`await` first. Prefer over completion handlers and Combine for new code.
11. Annotate ViewModels and UI-bound types with `@MainActor`.
12. Use `actor` for shared mutable state accessed concurrently.
13. All types crossing actor or task boundaries must conform to `Sendable`. Verify generated Protobuf types retain `Sendable` conformance after each generation.
14. Use structured concurrency: `async let`, `TaskGroup`, `withThrowingTaskGroup`. Use `withTaskCancellationHandler` for cleanup.
15. Never use `@unchecked Sendable` without documented, audited justification.
16. Any `@MainActor`, `nonisolated`, or `Sendable` decision must be intentional and documented when non-obvious.

## Error handling

17. Define one typed error enum per domain layer. Each case carries associated context values.
18. Never swallow errors — every `catch` must handle, log, or rethrow.
19. Use `Result<Success, Failure>` for storable errors; use `throws` for propagation.
20. Retry transient failures with exponential backoff and jitter. Never retry non-transient errors.

## Testing tooling

21. Use the Swift Testing framework (`@Test`, `#expect`, `#require`) for new test code. Coexist with legacy XCTest suites without rewriting them.
22. Test naming convention: `testWhenConditionThenExpectedOutcome()`. Names are self-documenting failure messages.
23. For gRPC client tests: wrap generated stubs in a protocol and provide fake implementations returning canned Protobuf response messages. Never hit real endpoints in unit tests.

## Style and idioms

24. Prefer protocol-oriented programming over class inheritance.
25. Use `@Observable` (iOS 17+/macOS 14+) for new ViewModels. Coexist with legacy `ObservableObject`.
26. Keep SwiftUI views thin — push logic into dedicated types.
27. Use `ViewModifier` for reusable view behavior. Eliminate repeated modifier chains.
28. Use `@Environment` for dependency injection into the view tree.
29. Prefer `guard` and early return over deeply nested conditionals.
30. Avoid force unwraps except in tightly justified test-only contexts.
31. No `print()` in production code — use `os_log` or structured logging.

## Dead code and unused imports

32. Delete commented-out code. If you need a snippet for reference, use version control to find it, not a comment. Commented-out code rots and confuses readers.
33. Delete unused `import` statements. Every import in a Swift file must be referenced somewhere in that file. The Swift compiler warns on unused imports only when `-warnings-as-errors` is set — audits should catch unreferenced imports explicitly.
34. Delete unused `internal` and `private` types, properties, methods, and functions. If a symbol is not referenced anywhere in the module, it is dead code.
35. Unused `public` API is harder to detect automatically (external callers may exist). Flag public symbols that have no internal callers AND no documentation explaining why they are public — if the symbol is undocumented and unused internally, it is likely accidentally public.
36. Flag dead enum cases: an enum case with no reference anywhere (not in switch statements, not in constructors) is dead code.
37. Flag unreachable code after `return`, `throw`, `fatalError`, or unconditional branch — the Swift compiler emits warnings but warnings can be ignored.
38. Flag TODO comments older than six months, or any TODO without a tracking identifier (e.g., `TD-TBD` or a real backlog number). Tracked TODOs are intentional; untracked ones are dead intent.

## Project additions

- FIXTURE-MARKER-L1: enforce project-specific Swift rule.
