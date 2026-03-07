# CLAUDE.md

This repository targets Apple platforms, Xcode 26.3, GitHub, and Swift Package Manager.

## Capability policy

Claude may perform all major engineering tasks in this repository:

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

## Platform and stack defaults

- Target platforms: iOS, iPadOS, macOS.
- UI: SwiftUI first. Use UIKit or AppKit interop only for platform gaps, mature third-party UI frameworks, or performance-critical cases.
- Dependencies: Swift Package Manager first. Do not add CocoaPods or manual vendoring unless the package is unavailable or technically blocked in SPM.
- Source control: GitHub. Keep changes easy to review.
- Concurrency: For new code, follow Swift 6 strict concurrency and actor-safety. For legacy or third-party boundaries, be pragmatic and isolate unsafe edges.
- Server template variant: Python by default, but keep boundaries portable enough that future services can run on macOS, Linux, and Windows.

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
- Prefer `async` and `await` over callback pyramids.
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
- Third-party MCP-based UI automation is optional and should not replace native test coverage.

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

- Planning, coding, testing, review, refactoring, and repo operations are all allowed.
- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, Apple behavior, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.
- For high-risk changes, produce a plan, identify verification steps, and name the remaining risks.
