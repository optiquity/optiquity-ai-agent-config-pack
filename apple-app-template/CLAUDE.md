# CLAUDE.md

This repository targets Apple platforms (iOS, iPadOS, macOS), Xcode 26.3, GitHub, and Swift Package Manager.
When this repo communicates with a first-party backend, it uses gRPC + Proto3 as the schema and transport layer.

## Capability policy

Claude may perform all major engineering tasks in this repository:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for architecture, concurrency, security, review, and other correctness-sensitive work.
- Use local models only where results are likely equivalent and the verification path is strong.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform and stack defaults

- Target platforms: iOS, iPadOS, macOS.
- UI: SwiftUI first. UIKit or AppKit interop only for platform gaps, mature third-party UI frameworks, or performance-critical cases.
- Dependencies: Swift Package Manager first. No CocoaPods or manual vendoring unless technically blocked in SPM.
- Source control: GitHub. Keep changes easy to review.
- Concurrency: For new code, follow Swift 6 strict concurrency and actor-safety. For legacy or third-party boundaries, be pragmatic and isolate unsafe edges.
- Client-server schema: gRPC + Proto3 for all first-party communication. Third-party APIs use their own native protocols.

## Architecture rules

- Default to immutable value types and immutable reference types.
- Allow mutation only when it clearly models evolving state, system boundaries, caches, stores, coordinators, or UI state holders.
- If a mutable type exists, keep its mutable surface area narrow and explicit.
- Prefer pure functions and deterministic transforms where practical.
- Prefer builders or dedicated factory helpers when initialization is complex, correctness-sensitive, or requires staged validation.
- Prefer protocol abstractions at boundaries, not everywhere.
- Avoid inheritance unless required by Apple frameworks or a stable abstraction clearly justifies it. Composition is the default.
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

## gRPC and Proto3 client rules

These rules govern how this repo consumes first-party gRPC services.

- Never call generated gRPC stubs directly from views or view models. Always wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the transport boundary. Domain types must never be passed to stubs.
- Never hand-edit generated Protobuf or gRPC Swift code. Regenerate from .proto source using buf or the project gen script.
- Put auth tokens (JWT, OAuth bearer) in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call must have an explicit deadline. Use named constants, not magic duration literals.
- Use google.rpc.Status + error_details.proto for error responses. Map gRPC status codes to typed domain errors at the boundary; never surface raw gRPC status codes in UI.
- For streaming calls, track cancellation explicitly. Avoid leaking gRPC stream references across scene lifecycle transitions.
- Use google.protobuf.Timestamp for all date/time in Protobuf messages.
- Use GRPCChannelPool rather than creating channels per request. Tie channel lifecycle to app or scene lifecycle.

## Security

- Store credentials, tokens, and certificates in Keychain. Never in UserDefaults, files, or source code.
- Never hardcode secrets, API keys, or certificates.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.
- Validate all data received from the network before using it in domain logic or UI.
- Use App Transport Security. Document any ATS exceptions with justification.
- Declare Privacy Manifests for all required reason APIs and third-party SDKs.
- Request minimum required permissions. Do not request entitlements not actively used.

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
- Use protocol-based test doubles for gRPC stubs. Never hit real endpoints in unit or integration tests.
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
- Do not commit generated Protobuf or gRPC Swift files. Regenerate via script.
- Prefer repo-local scripts over undocumented manual steps.
- Document any new setup requirement in README.md or docs/.

## Git workflow

- Make commits small and coherent.
- Include tests when behavior changes.
- Separate mechanical formatting from semantic changes when practical.
- Surface risky migrations early.

## Anti-patterns — never introduce these

- Massive view controllers or God ViewModels accumulating unrelated logic.
- Calling generated gRPC stubs directly from ViewModels or Views.
- Putting auth tokens or credentials in Protobuf message fields.
- @unchecked Sendable without a documented, audited justification.
- Force unwraps outside tightly justified test-only or impossible-state contexts.
- Implicitly unwrapped optionals as a laziness shortcut.
- print() in production code — use os_log or a structured logger.
- Singleton sprawl for services that could be injected.
- Retain cycles, especially in gRPC streaming closures.
- Blocking the main thread with synchronous network or disk I/O.
- Mutable global state that is not documented as such.
- Stringly-typed identifiers or state machines.
- Magic duration literals for gRPC deadlines — use named constants.
- Ignoring scene lifecycle transitions in long-lived gRPC streaming connections.
- Editing generated Protobuf or gRPC Swift code by hand.

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
