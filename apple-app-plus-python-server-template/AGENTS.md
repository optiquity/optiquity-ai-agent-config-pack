# AGENTS.md

This repository targets Apple platforms and is optimized for Xcode 26.3, GitHub, and Swift Package Manager.

## Default operating mode

- Correctness before speed.
- Small diffs before sweeping rewrites.
- Buildable, testable, reviewable changes only.
- Cloud models are preferred for correctness-sensitive work.
- Local OSS models are acceptable for low-risk implementation, repetitive edits, and documentation.

## Platform defaults

- SwiftUI first.
- UIKit or AppKit interop only when justified by platform gaps, third-party framework constraints, or measurable performance reasons.
- SPM first. Do not introduce CocoaPods unless the dependency is unavailable through SPM and the value is proven.
- New code should follow Swift 6 strict concurrency expectations. Be pragmatic at legacy and third-party boundaries.

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

- Read existing code before adding new abstractions.
- Do not invent package APIs or Xcode settings.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- When using a local model, avoid high-risk architectural changes unless a stronger model has already reviewed the plan.


## Python server additions

- Prefer cross-platform Python tooling and scripts.
- Avoid shell steps that assume zsh, Homebrew, or macOS-specific paths for server workflows.
- Keep API contracts explicit and versionable.
- Isolate vendor SDKs behind small adapters.
