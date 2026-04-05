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

## iOS 26 / Xcode 26.3 platform features

- **Liquid Glass** is the current iOS 26 / macOS 26 design language for materials and visual effects. Use `.glassEffect()` and related modifiers rather than custom `Material` or `UIVisualEffectView` implementations. Evaluate Liquid Glass before reaching for any third-party visual effects library.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Treat it as the Apple-first option for any on-device language model need. Evaluate it before reaching for third-party ML inference frameworks. It does not require network access and respects App Sandbox.
- **Availability guards required.** Liquid Glass and FoundationModels require iOS 26+ / macOS 26+. If the project's deployment target is below iOS 26 / macOS 26, all usage of `.glassEffect()`, FoundationModels, and related APIs must be wrapped in `#available(iOS 26, *)` / `#available(macOS 26, *)` guards. Do not use these APIs as unconditional defaults on older deployment targets.
- **Check Apple frameworks before third-party packages.** For any new capability, verify whether an iOS 26 Apple framework covers the need before adding a dependency. This applies especially to ML, visual effects, and system integration features.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads from `shared-docs/ios26/` before web search.

## Architecture rules

- Default to immutable value types and immutable reference types.
- Allow mutation only when it clearly models evolving state, system boundaries, caches, stores, coordinators, or UI state holders.
- If a mutable type exists, keep its mutable surface area narrow and explicit.
- Prefer pure functions and deterministic transforms where practical.
- Prefer builders or dedicated factory helpers when initialization is complex, correctness-sensitive, or requires staged validation.
- Prefer protocol abstractions at boundaries, not everywhere.
- Avoid inheritance unless required by Apple frameworks or a stable abstraction clearly justifies it. Composition is the default.
- Avoid singleton sprawl. If shared state is necessary, document ownership, lifecycle, and thread-safety.
## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern per app target before writing production code. **Document the choice and rationale in `ARCHITECTURE.md` before implementation begins.** Do not write production code before the architecture decision is recorded.
- Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified.
- Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may reach past its immediate neighbor (presentation → domain → data; never presentation → data directly).
- Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, gRPC, grpcio, or any persistence or networking framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer type signatures or in presentation/view-model types.
- Every cross-layer dependency is expressed as a protocol abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
- Shared mutable state declares its owner type, owning actor or thread, lifecycle (who creates it, who destroys it), and mutation contract at the definition site. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services explicitly document their state variables, threading guarantees, and invalidation policy.
- Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern.


## Swift and Apple coding rules

- Prefer structs for models unless reference semantics are required.
- Mark classes `final` by default unless subclassing is explicitly required.
- Make invalid states unrepresentable where possible.
- Prefer typed errors, typed IDs, and explicit domain models over stringly typed state.
- Persistent domain objects carry a typed ID wrapper (a `UUID` wrapped in a named struct). Never use raw `UUID` or `String` at domain boundaries.
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

## Liskov Substitution Principle

- Every protocol method must have a meaningful implementation in every conforming type. Silent no-ops and unconditional "not supported" throws that are not gated by feature flags or capability checks are violations.
- No domain or presentation layer code may branch on the concrete type behind a protocol reference. Use capability flags or feature checks for all implementation differences.
- No concrete data-layer type may be referenced by name in domain or presentation code. Only protocol types and domain model types cross layer boundaries.
- When adding a new protocol, verify conformance correctness across all implementing types before committing.

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

## Scripts

The `scripts/` directory at the project root contains shell scripts that agents and developers
use to validate, test, format, and generate code. **Scripts must be copied from the pack template
and made executable before first use** (`chmod +x scripts/*.sh`).

| Script | When to run | Who calls it |
|---|---|---|
| `bootstrap.sh` | Once on first checkout or new machine | Human |
| `format.sh` | Before committing — formats Swift (swift-format) and/or Python (ruff) | Human or `repo-ops` agent |
| `test.sh` | After implementing — runs the test suite only | Human or `repo-ops` agent |
| `validate.sh` | Before committing — full build + test suite | Human or `repo-ops` agent |
| `proto-gen.sh` | After editing any `.proto` file — runs buf lint then buf generate | Human or `grpc-schema` agent |
| `agent-post-edit-check.sh` | **Never call manually** — fires automatically via Claude Code PostToolUse hook after every agent file edit | Claude Code hook |

**Required first-time setup:** Open `scripts/validate.sh` and `scripts/test.sh` and fill in:
```
XCODE_SCHEME="YourSchemeName"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
```
Until these are set, `xcodebuild` steps are skipped and the scripts only run `swift build`/`swift test`.
Find valid values: `xcodebuild -list` and `xcrun simctl list devices available`.

**Note:** `format.sh` is manual-only — it is not wired into the automatic post-edit hook.
Run it explicitly before committing or ask `repo-ops` to run it.

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


## grpc-swift-2 API rules

This repo uses grpc-swift-2 (https://github.com/grpc/grpc-swift-2), the Swift Concurrency-native gRPC implementation.
Do not use grpc-swift v1 APIs in new code.

- Import `GRPCCore` and the transport package (`GRPCNIOTransportHTTP2` or `GRPCNIOTransportHTTP2NIOPosix`).
- Unary calls: `let response = try await client.someMethod(request, options: callOptions)`
- Server-streaming: `for try await message in client.serverStream(request, options: callOptions).messages { ... }`
- Client-streaming: `try await client.clientStream { writer in try await writer.write(request) }`
- Bidirectional streaming: manage the writer in a closure; iterate responses with `for try await msg in stream.messages { ... }`
- Always supply `CallOptions` with a timeout. Define timeouts as named constants — never inline duration literals.
- Error handling: catch `RPCError` (GRPCCore). Inspect `.code` (type `RPCError.Code`) and `.message`. Map to domain errors at the repository or service boundary. `RPCError` must not cross that boundary.
- Cancellation: Swift Task cancellation propagates automatically to the underlying gRPC call in grpc-swift-2. Explicit `call.cancel()` is not required for Task-scoped calls.
- Interceptors: use `ClientInterceptor` protocol (GRPCCore) for auth, logging, retry, and tracing. Register interceptors at channel construction, not per-call.
- Channel lifecycle: manage one `GRPCClient` instance per app or scene lifecycle. Never create a new channel per request.
- After every `buf generate` run: verify generated Protobuf Swift types still conform to `Sendable`.

## Deferral comments and BACKLOG hygiene

Three comment types are recognized for deferring work. Use exactly this syntax:

```swift
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(severity): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```

**Valid scope values for TODO:** `phase-N`, `dependency`, `feature`, `perf`
**Valid severity values for KNOWN GAP:**
- `critical` — must eventually be addressed without exception
- `functional` — should be addressed; feature is incomplete without it
- `polish` — may be skipped; improves experience but does not affect correctness
**Source for VERIFY:** name the external source (e.g. `apple-docs`, `schwab-api`)

**Rules — read carefully:**
- Always write `TD-TBD` — never a real TD number. The PM chat assigns numbers after review.
- Report every deferral comment added in the "Deferred items" section of the completion report.
- Do not write to `BACKLOG.md`. Do not resolve or modify existing BACKLOG entries.
- Work that could be completed within the current phase scope is NOT a TODO — it is
  an incomplete task. The reviewer will flag it as an implementation plan compliance failure.
- Never use plain English deferral comments (`// Fix later`, `// Confirm this`, etc.).
  Use the typed format above or do not leave a comment.
- When citing a code location in a report, use the symbol name not the line number.
  Line numbers drift with every edit; symbol names are stable.

## Anti-patterns — never introduce these

- Massive view controllers or God ViewModels accumulating unrelated logic.
- Calling generated gRPC stubs directly from ViewModels or Views.
- Putting auth tokens or credentials in Protobuf message fields.
- @unchecked Sendable without documented and audited justification.
- Force unwraps outside tightly justified test-only or impossible-state contexts.
- Implicitly unwrapped optionals as a laziness shortcut.
- print() in production code — use os_log or a structured logger.
- Singleton sprawl for services that could be injected.
- Retain cycles, especially in gRPC streaming closures.
- Blocking the main thread with synchronous network or disk I/O.
- Mutable global state that is not documented as such.
- Domain types appearing in data-layer or transport-layer signatures.
- Hard deletion of user-modifiable objects — use soft-delete (tombstoning) where data must be preserved for audit or logging.
- Stringly-typed identifiers or state machines.
- Magic duration literals for gRPC deadlines — use named constants.
- Ignoring scene lifecycle transitions in long-lived gRPC streaming connections.
- Editing generated Protobuf or gRPC Swift code by hand.


## Phase routing — default agent assignments

Both Claude Code and Codex can execute any engineering phase in this repo.
The defaults below identify the better system for each phase. Override freely when task
characteristics favor the other system.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | apple-architect or planner | Multi-file context, extended reasoning |
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
