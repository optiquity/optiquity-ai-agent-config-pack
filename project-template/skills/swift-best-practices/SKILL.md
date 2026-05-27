---
name: swift-best-practices
description: Use for Swift language patterns, type system, immutability, error handling, testing tooling, and idiomatic Swift style.
allowed-tools: Read, Grep, Glob, Bash
---

## Companion skill — Swift concurrency rules

The substantive Swift concurrency rules — async/await semantics,
structured concurrency, actor isolation, Sendable conformance design,
`@preconcurrency` boundaries, AsyncSequence / AsyncStream patterns,
data-race avoidance under Swift 6 strict checking, continuation
bridging, and Grand Central Dispatch (GCD) — live in
`swift-concurrency-patterns`. That skill loads as D1-implied for
D1 ∈ {ios, macos} alongside this one (see
`docs/pack/PLATFORM-SKILLS.md`). This skill carries only the
language-style touchpoints that surface during routine Swift
authoring (`@MainActor` on ViewModels; `Sendable` on types crossing
boundaries; `actor` for shared mutable state); the design rules and
anti-patterns are in the companion skill.

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

## Concurrency touchpoints (style level)

10. `async`/`await` first for new code. Prefer over completion
    handlers and Combine. Substantive concurrency design rules are
    in `swift-concurrency-patterns`.
11. Annotate ViewModels and UI-bound observable types with
    `@MainActor`. The actor-isolation, reentrancy, and global-
    actor rules live in `swift-concurrency-patterns`.
12. Use `actor` for shared mutable state accessed concurrently.
    Choose `actor` over `class` + `DispatchQueue` for Swift-only
    surfaces — see `swift-concurrency-patterns` for the full
    selection rules and reentrancy pitfalls.
13. Verify generated Protobuf types retain `Sendable` conformance
    after each `proto-gen` pass. Loss of conformance breaks the
    data → presentation actor hop. Sendable design rules are in
    `swift-concurrency-patterns`.

## Error handling

14. Define one typed error enum per domain layer. Each case carries associated context values.
15. Never swallow errors — every `catch` must handle, log, or rethrow.
16. Use `Result<Success, Failure>` for storable errors; use `throws` for propagation.
17. Retry transient failures with exponential backoff and jitter. Never retry non-transient errors.

## Testing tooling

18. Use the Swift Testing framework (`@Test`, `#expect`, `#require`) for new test code. Coexist with legacy XCTest suites without rewriting them.
19. Test naming convention: `testWhenConditionThenExpectedOutcome()`. Names are self-documenting failure messages.
20. For gRPC client tests: wrap generated stubs in a protocol and provide fake implementations returning canned Protobuf response messages. Never hit real endpoints in unit tests.

## Style and idioms

21. Prefer protocol-oriented programming over class inheritance.
22. Use `@Observable` (iOS 17+/macOS 14+) for new ViewModels. Coexist with legacy `ObservableObject`.
23. Keep SwiftUI views thin — push logic into dedicated types.
24. Use `ViewModifier` for reusable view behavior. Eliminate repeated modifier chains.
25. Use `@Environment` for dependency injection into the view tree.
26. Prefer `guard` and early return over deeply nested conditionals.
27. Avoid force unwraps except in tightly justified test-only contexts.
28. No `print()` in production code — use `os_log` or structured logging.

## Dead code and unused imports

29. Delete commented-out code. If you need a snippet for reference, use version control to find it, not a comment. Commented-out code rots and confuses readers.
30. Delete unused `import` statements. Every import in a Swift file must be referenced somewhere in that file. The Swift compiler warns on unused imports only when `-warnings-as-errors` is set — audits should catch unreferenced imports explicitly.
31. Delete unused `internal` and `private` types, properties, methods, and functions. If a symbol is not referenced anywhere in the module, it is dead code.
32. Unused `public` API is harder to detect automatically (external callers may exist). Flag public symbols that have no internal callers AND no documentation explaining why they are public — if the symbol is undocumented and unused internally, it is likely accidentally public.
33. Flag dead enum cases: an enum case with no reference anywhere (not in switch statements, not in constructors) is dead code.
34. Flag unreachable code after `return`, `throw`, `fatalError`, or unconditional branch — the Swift compiler emits warnings but warnings can be ignored.
35. Flag TODO comments older than six months, or any TODO without a tracking identifier (e.g., `TD-TBD` or a real backlog number). Tracked TODOs are intentional; untracked ones are dead intent.

## Design choices

36. Heterogeneous domain collections — protocol elevation over type-erasure-with-downcasting. Type-erasure wrappers that expose a `.base` accessor for downcasting to a concrete type are an LSP violation: runtime type interrogation disguised as abstraction. Prefer protocol elevation (move all needed behavior into the protocol as requirements) when callers should remain concrete-type-agnostic. Use exhaustive enums when the concrete type must be known at call sites and the type set is fixed and internal to the module.

*(AsyncStream payload design — relocated to `swift-concurrency-patterns` as part of the v11.0 split into a separate skill.)*
