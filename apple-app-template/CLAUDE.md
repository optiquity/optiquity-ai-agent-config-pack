# CLAUDE.md

This repository builds Apple-platform apps with SwiftUI first, UIKit or AppKit interop only where justified.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.

## Platform and stack defaults

- Target platforms: iOS, iPadOS, macOS.
- UI: SwiftUI first. Use UIKit or AppKit interop only for platform gaps, mature third-party UI frameworks, or performance-critical cases.
- Dependencies: Swift Package Manager first. Do not add CocoaPods or manual vendoring unless the package is unavailable or technically blocked in SPM.
- Source control: GitHub. Keep changes easy to review.
- Concurrency: For new code, follow Swift 6 strict concurrency and actor-safety. For legacy or third-party boundaries, be pragmatic and isolate unsafe edges.

## Architecture rules

- Default to immutable value types and immutable reference types.
- Allow mutation only when it clearly models evolving state, system boundaries, caches, stores, coordinators, or UI state holders.
- If a mutable type exists, keep its mutable surface area narrow and explicit.
- Prefer pure functions and deterministic transforms where practical.
- Prefer builders or dedicated factory helpers when initialization is complex, correctness-sensitive, or requires staged validation.
- Prefer protocol abstractions at boundaries, not everywhere.
- Avoid inheritance unless it is required by Apple frameworks or clearly simplifies a stable abstraction. Composition is the default.
- Keep UI, domain, persistence, and networking concerns separate.
- Avoid singleton sprawl. If shared state is necessary, document ownership, lifecycle, and thread-safety.

## Swift and Apple coding rules

- Prefer structs for models unless reference semantics are required.
- Mark classes `final` by default unless subclassing is explicitly required.
- Make invalid states unrepresentable where possible.
- Prefer typed errors, typed IDs, and explicit domain models over stringly typed state.
- Avoid force unwraps except in tightly justified test-only or impossible-state contexts.
- Prefer async or await over callback pyramids.
- Any `@MainActor`, `nonisolated`, `Sendable`, or `@unchecked Sendable` decision must be intentional and documented in code comments when non-obvious.
- Keep SwiftUI views thin. Push domain logic and orchestration into dedicated types.
- Use dependency injection for services, clients, repositories, stores, and coordinators.

## Dependency intake policy

Before adding any third-party framework or API:

1. Check whether Apple frameworks already solve the need well enough.
2. Prefer SPM packages with active maintenance, clear licensing, and recent activity.
3. Evaluate cross-platform impact, security risk, binary size, and lock-in.
4. Record why the dependency is needed, what alternatives were rejected, and the exit plan if the dependency becomes stale.
5. Do not add a dependency when a local wrapper around platform APIs is simpler and safer.

## Testing expectations

- Add or update tests with every non-trivial change.
- Use unit tests for domain logic and state transitions.
- Use integration tests for storage, networking adapters, and module seams.
- Use XCUITest for native UI coverage.
- Consider Maestro only for black-box end-to-end simulator flows where its speed or ergonomics are useful.
- Snapshot tests are optional. Use them only when they reduce review noise.

## Refactoring policy

- Do not mix unrelated refactors into feature work.
- Preserve external behavior unless the task explicitly changes behavior.
- When touching legacy code, improve naming, seams, and tests before broad rewrites.
- Prefer deleting dead code over preserving speculative abstractions.

## Build and repo hygiene

- Keep the repo buildable from Xcode and command line.
- Do not commit secrets, generated junk, or machine-specific config.
- Prefer repo-local scripts over undocumented manual steps.
- Document any new setup requirement in `README.md` or `docs/`.

## Git workflow

- Make commits small and coherent.
- Include tests when behavior changes.
- Separate mechanical formatting from semantic changes when practical.
- Surface risky migrations early.

## Agent behavior

When acting in this repo:

- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, Apple behavior, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.
