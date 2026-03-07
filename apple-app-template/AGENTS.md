# AGENTS.md

This repository targets Apple platforms and is optimized for Xcode 26.3, GitHub, and Swift Package Manager.

## Capability policy

Codex may perform all major engineering tasks in this repository:

- planning
- architecture
- implementation
- refactoring
- debugging
- testing
- code review
- dependency review
- repo operations
- documentation

These are all allowed. No task category is reserved exclusively for another tool.

Default preference only:
- use a stronger cloud model for architecture, concurrency, security, review, and other correctness-sensitive work
- use local models only where results are already likely to be equivalent and the verification path is strong

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against the code, tests, docs, or tooling output. Do not guess.

## Platform defaults

- SwiftUI first.
- UIKit or AppKit interop only when justified by platform gaps, third-party framework constraints, or measurable performance reasons.
- SPM first. Do not introduce CocoaPods unless the dependency is unavailable through SPM and the value is proven.
- New code should follow Swift 6 strict concurrency expectations. Be pragmatic at legacy and third-party boundaries.
- In the server template variant, Python is the default backend, but boundaries should stay portable enough for services that may later run on macOS, Linux, and Windows.

## Design rules

- Prefer immutable types by default.
- Use mutable state only for clearly stateful roles such as stores, coordinators, caches, or boundary adapters.
- Prefer value semantics for models unless reference semantics are required.
- Mark classes `final` unless subclassing is required.
- Prefer builders or validated factories when object creation is complex or order-sensitive.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin and move orchestration elsewhere.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.
- Avoid inheritance unless framework requirements or a stable abstraction clearly justify it.

## Dependency and API policy

Before adding a third-party package or API:

1. Check whether Apple frameworks already solve the problem.
2. Prefer actively maintained SPM packages.
3. Evaluate license, security, binary size, lock-in, and cross-platform impact.
4. Capture rationale, alternatives, and rollback plan in docs or PR notes.

## Testing policy

- Add or update tests for non-trivial changes.
- Prefer unit tests for domain logic.
- Use integration tests at module seams.
- Use XCUITest for native UI coverage.
- Consider Maestro for black-box simulator flows only when it reduces effort.
- Do not claim code works without an actual verification path.

## Git and review policy

- Keep commits coherent.
- Separate formatting-only changes from behavior changes where practical.
- Preserve existing behavior during refactors unless the task says otherwise.
- Document setup changes.

## Agent behavior

- Planning, coding, testing, review, refactoring, and repo operations are all allowed.
- Read existing code before adding new abstractions.
- Do not invent package APIs or Xcode settings.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- When using a local model, avoid high-risk architectural changes unless a stronger model has already reviewed the plan.
