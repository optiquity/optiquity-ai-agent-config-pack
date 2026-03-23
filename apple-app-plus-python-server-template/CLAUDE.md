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

## iOS 26 / Xcode 26.3 platform features

- **Liquid Glass** is the current iOS 26 / macOS 26 design language for materials and visual effects. Use `.glassEffect()` and related modifiers rather than custom `Material` or `UIVisualEffectView` implementations. Evaluate Liquid Glass before reaching for any third-party visual effects library.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Treat it as the Apple-first option for any on-device language model need. Evaluate it before reaching for third-party ML inference frameworks. It does not require network access and respects App Sandbox.
- **Check Apple frameworks before third-party packages.** For any new capability, verify whether an iOS 26 Apple framework covers the need before adding a dependency. This applies especially to ML, visual effects, and system integration features.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads from `shared-docs/ios26/` before web search.

## Architecture rules
## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern per app target before writing production code. Document the choice and rationale in README.md or ARCHITECTURE.md before implementation begins.
- Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified.
- Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may reach past its immediate neighbor (presentation → domain → data; never presentation → data directly).
- Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, gRPC, grpcio, or any persistence or networking framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer type signatures or in presentation/view-model types.
- Every cross-layer dependency is expressed as a protocol abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
- Shared mutable state declares its owner type, owning actor or thread, lifecycle (who creates it, who destroys it), and mutation contract at the definition site. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services explicitly document their state variables, threading guarantees, and invalidation policy.
- Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern.


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


## grpc-swift-2 API rules

This repo uses grpc-swift-2 (https://github.com/grpc/grpc-swift-2), the Swift Concurrency-native gRPC implementation.
Do not use grpc-swift v1 APIs in new code.

- Import `GRPCCore` and the transport package (`GRPCNIOTransportHTTP2` or its NIO Posix variant).
- Unary calls: `let response = try await client.someMethod(request, options: callOptions)`
- Server-streaming: `for try await message in client.serverStream(request, options: callOptions).messages { ... }`
- Client-streaming: `try await client.clientStream { writer in try await writer.write(request) }`
- Bidirectional: manage the writer in a closure; iterate responses with `for try await msg in stream.messages { ... }`
- Always supply `CallOptions` with a timeout. Define timeouts as named constants — never inline duration literals.
- Error handling: catch `RPCError` (GRPCCore). Inspect `.code` and `.message`. Map to domain errors at the repository or service boundary. `RPCError` must not propagate past that boundary.
- Cancellation: Swift Task cancellation propagates automatically to the underlying gRPC call. Explicit `call.cancel()` is not required for Task-scoped calls.
- Interceptors: use `ClientInterceptor` protocol (GRPCCore) for auth, logging, retry, and tracing. Register at channel construction, not per-call.
- Channel lifecycle: manage one `GRPCClient` instance per app or scene lifecycle. Never create a new channel per request.
- After every `buf generate` run: verify generated Protobuf Swift types still conform to `Sendable`.


## grpc.aio API rules (asyncio-native gRPC)

This repo uses `grpc.aio` (asyncio-native) for all gRPC server and client code.
Do not use synchronous `grpc.server()` or synchronous stubs in production code.

- Start the server with `grpc.aio.server(interceptors=[...])`, not `grpc.server(...)`.
- All servicer handler methods are `async def`. Blocking code inside a handler stalls the event loop — offload CPU-bound work with `asyncio.run_in_executor(executor, ...)`.
- Unary handler: `async def MethodName(self, request: RequestType, context: grpc.aio.ServicerContext) -> ResponseType`
- Server-streaming: `async def` + `await context.write(response)` in a loop; return `None`.
- Client-streaming: `async for request in context: ...`
- Bidirectional: combine `async for request in context` with `await context.write(response)`.
- Return gRPC errors: `await context.abort(grpc.StatusCode.CODE, "detail string")`. Never raise bare Python exceptions from handlers — they become `INTERNAL` status with no visible detail.
- Rich error details: use `grpcio-status`. Attach `google.rpc.Status` with error_details via `context.abort_with_status(...)`.
- Server interceptors: subclass `grpc.aio.ServerInterceptor`. Implement `async def intercept(self, continuation, call_details)`.
- Client channels: use `grpc.aio.secure_channel()` (production) or `grpc.aio.insecure_channel()` (local dev) inside `async with` blocks.
- Client errors: catch `grpc.aio.AioRpcError`. Inspect `.code()` and `.details()`. Map to domain exceptions at the service or repository boundary.
- Streaming cancellation: handle `asyncio.CancelledError` in streaming handlers — clean up resources, then re-raise. Do not swallow it.
- Dependency pinning: `grpcio`, `grpcio-tools`, `grpcio-status`, and `grpcio-reflection` must be pinned to the same version.

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


## Phase routing — default agent assignments

Both Claude Code and Codex can execute any engineering phase in this repo.
The defaults below identify the better system for each phase. Override freely when task
characteristics favor the other system.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | ios-architect or planner | Multi-file context, extended reasoning |
| API and schema design | **Claude Code** | grpc-schema | Schema tools, buf integration |
| Planning / task breakdown | **Claude Code** | planner | Tiebreaker — both systems comparable |
| Dependency evaluation | **Claude Code** | docs-researcher | Web search, nuanced tradeoff analysis |
| Implementation | **Codex** | coder | workspace-write sandbox, strong code generation |
| Code review | **Claude Code** | reviewer | Deep multi-file analysis, Bash diagnostics |
| Testing | **Codex** | tester | Pattern generation, approval flow for new files |
| Debugging | **Claude Code** | coder | Multi-step reasoning, Bash for live diagnostics |
| Refactoring | **Codex** | coder | Mechanical changes in workspace-write sandbox |
| Documentation | **Claude Code** | docs-researcher | Tiebreaker — multi-file context aids consistency |
| Repo operations | **Codex** | repo-ops | workspace-write sandbox, scripting strength |
| Local validation | **Codex** | repo-ops | workspace-write sandbox; can execute scripts |

To invoke a specific agent in Claude Code: `claude --agent planner`
To invoke a specific agent in Codex: `codex --agent coder`
