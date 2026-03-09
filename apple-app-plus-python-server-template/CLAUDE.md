# CLAUDE.md

This is a monorepo containing an Apple platform client (iOS, iPadOS, macOS) and a Python server.
All first-party client-server communication uses gRPC + Proto3 as the shared schema and transport layer.
Third-party APIs use their own native protocols (REST/JSON, etc.).

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

## Repo layout

- `client/` or `ios/` or project root — Swift/Xcode Apple platform client.
- `server/` — Python server source and tests.
- `proto/` — Proto3 schema definitions. This is the source of truth for all first-party API contracts.
- `scripts/` — Repo automation.

## Platform and stack defaults

### Apple client
- Target platforms: iOS, iPadOS, macOS.
- UI: SwiftUI first. UIKit or AppKit interop only for platform gaps, mature third-party UI frameworks, or performance-critical cases.
- Dependencies: Swift Package Manager first. No CocoaPods or manual vendoring unless technically blocked in SPM.
- Concurrency: Swift 6 strict concurrency for new code. Be pragmatic at legacy and third-party boundaries.

### Python server
- Python 3.12+.
- Prefer `uv` for runtime and dependency management.
- Prefer `pytest` + `pytest-asyncio` for tests.
- Prefer `ruff` for linting and formatting.
- Prefer `pyright` in strict mode for static type checking.
- Server code must run on macOS, Linux, and Windows unless a file or dependency explicitly documents a platform-specific exception.

### Shared schema
- gRPC + Proto3 for all first-party client-server communication.
- One service definition per `.proto` file.
- Use `buf` for lint, breaking-change detection, and code generation. Run `buf lint` and `buf breaking` before every schema merge.
- Never hand-edit generated code (Swift or Python). Regenerate from `.proto` source.
- Use `google.protobuf.Timestamp` for all date/time fields. Never raw string dates in proto.
- Use `google.rpc.Status` + `error_details.proto` for all gRPC error responses.
- Proto3 field numbers are inviolable. Never reuse a deleted field number. Use `reserved` on deletion.
- Enum zero value must always be `UNSPECIFIED` (e.g., `STATUS_UNSPECIFIED = 0`).

## Architecture rules

- Default to immutable value types and immutable reference types.
- Allow mutation only when it clearly models evolving state, system boundaries, caches, stores, coordinators, or UI state holders.
- Prefer pure functions and deterministic transforms where practical.
- Prefer protocol abstractions at boundaries, not everywhere.
- Avoid inheritance unless required by Apple frameworks or a stable abstraction clearly justifies it. Composition is the default.
- Keep UI, domain, persistence, and networking concerns separate.
- Avoid singleton sprawl. Document ownership, lifecycle, and thread-safety of all shared state.

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

## gRPC client rules (Swift/Apple side)

- Never call generated gRPC stubs directly from views or view models. Wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the transport boundary. Domain types must never be passed to stubs.
- Put auth tokens in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call must have an explicit deadline using a named constant, not a magic duration literal.
- Map gRPC status codes to typed domain errors at the boundary. Never surface raw gRPC status codes in UI.
- Track cancellation for streaming calls. Do not leak gRPC stream references across scene lifecycle transitions.
- Use GRPCChannelPool. Tie channel lifecycle to app or scene lifecycle.

## gRPC server rules (Python side)

- gRPC stubs (generated servicer classes) are never called from business logic directly.
- Implement servicers as thin adapters that delegate to injected service objects.
- Return `google.rpc.Status` with appropriate error_details for all error cases.
- Map gRPC status codes at the boundary. Never let raw gRPC status propagate into domain logic.
- Set and enforce request deadlines server-side. Handle DEADLINE_EXCEEDED explicitly.
- Use gRPC interceptors for cross-cutting concerns: auth, logging, metrics. Do not inline these in servicers.
- Log every RPC with: method name, status code, and latency. Use structured logging.
- Use `grpcio-testing` for server unit tests. Never hit real network endpoints in unit tests.
- Pin `grpcio` and `grpcio-tools` versions explicitly. Version drift causes generation mismatches.

## Python server rules

- All public functions and methods must have type annotations. Run `pyright --strict`.
- Use constructor dependency injection. Do not rely on module-level globals for services.
- Use async context managers for resource lifecycle (database connections, gRPC channels).
- Use `pydantic-settings` for environment-based configuration.
- Validate inputs at I/O boundaries using Pydantic. Do not trust incoming data.
- Keep side effects near the edge of the system. Business logic should be pure where possible.
- Use `__all__` in all public modules to document the intended public surface.
- Prevent N+1 queries. Use eager loading or batch queries at the repository layer.
- Background tasks must be idempotent.
- ML model inference must be isolated from business logic. Version models and document rollback procedures.

## Security

- Store credentials, tokens, and certificates in Keychain (Apple) or environment variables / secrets managers (Python).
- Never hardcode secrets, API keys, or certificates in source code.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.
- Auth tokens in gRPC call metadata, never in Protobuf message fields.
- Validate all incoming data at I/O boundaries on both client and server.
- Use App Transport Security (Apple). Document any ATS exceptions.
- Declare Privacy Manifests for all required reason APIs and third-party SDKs (Apple).
- Implement rate limiting on server-side. Return `RESOURCE_EXHAUSTED` for violations.
- Prevent SQL injection. Use parameterized queries. Never concatenate user input into queries.
- Use JWT or OAuth for auth. Validate tokens server-side on every request.
- Run dependency security scans regularly on both Swift (SPM) and Python (uv) dependency trees.

## Dependency intake policy

Before adding any third-party framework, package, or API:

1. Check whether platform or standard library APIs already solve the need.
2. Prefer actively maintained packages with clear licensing.
3. Evaluate cross-platform impact, security risk, binary size, and lock-in.
4. Record why the dependency is needed, what alternatives were rejected, and the exit plan.
5. Do not add a dependency when a local wrapper around platform APIs is simpler and safer.

## Testing expectations

- Add or update tests with every non-trivial change.
- Use unit tests for domain logic and state transitions.
- Use integration tests for storage, networking adapters, and module seams.
- Use protocol-based test doubles for gRPC stubs on the client side.
- Use grpcio-testing for server-side gRPC unit tests.
- Use XCUITest for native Apple UI coverage.
- Use pytest + pytest-asyncio for Python async tests.
- Verify schema compatibility with `buf breaking` before every proto merge.
- Do not claim code works without an actual verification path.

## Refactoring policy

- Do not mix unrelated refactors into feature work.
- Preserve external behavior unless the task explicitly changes behavior.
- When touching legacy code, improve naming, seams, and tests before broad rewrites.
- Prefer deleting dead code over preserving speculative abstractions.

## Build and repo hygiene

- Keep both the Swift client and Python server buildable independently and together.
- Do not commit secrets, generated junk, or machine-specific config.
- Do not commit generated Protobuf or gRPC code (Swift or Python). Regenerate via script.
- Prefer repo-local scripts over undocumented manual steps.
- Document any new setup requirement in README.md or docs/.

## Git workflow

- Make commits small and coherent.
- Include tests when behavior changes.
- Separate mechanical formatting from semantic changes when practical.
- Surface risky migrations early, especially proto schema changes.

## Anti-patterns — never introduce these

### Shared / gRPC
- Editing generated Protobuf or gRPC code by hand (Swift or Python).
- Reusing or renaming a deleted Proto3 field number.
- Auth tokens in Protobuf message fields.
- gRPC stubs called directly from ViewModels, Views, or business logic.
- Magic duration literals for gRPC deadlines.
- Skipping buf lint and buf breaking before a schema merge.

### Apple client
- Massive view controllers or God ViewModels.
- @unchecked Sendable without audited justification.
- Force unwraps as a convenience shortcut.
- print() in production code.
- Singleton sprawl for injectable services.
- Leaking gRPC stream references across scene lifecycle.

### Python server
- Module-level mutable global state used as service registry.
- Ignoring gRPC UNAVAILABLE as a fatal unrecoverable error without retry logic.
- N+1 database queries.
- Type annotations omitted on public APIs.
- Blocking synchronous I/O in async request handlers.
- Hardcoded secrets or API keys in source or config files.
- Concatenating user input into SQL queries.

## Agent behavior

When acting in this repo:
- Planning, coding, testing, review, refactoring, and repo operations are all allowed.
- Plan first for non-trivial work, especially for schema changes.
- Call out uncertainty explicitly.
- Do not invent APIs, Apple behavior, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.
- For high-risk changes (proto schema changes, concurrency, security), produce a plan, identify verification steps, and name the remaining risks.
