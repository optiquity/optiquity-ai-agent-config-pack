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
