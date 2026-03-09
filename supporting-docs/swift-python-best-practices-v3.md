# Swift 6 / Python Best Practices Reference — v3
### For CLAUDE.md / AGENTS.md — iOS, iPadOS, macOS, Python Server
### Transport: gRPC + Proto3 for all first-party client/server communication
### gRPC libraries: grpc-swift-2 (Swift) + grpc.aio (Python) | Schema management: buf CLI v2

**Platform Tag Legend**
| Tag | Meaning |
|-----|---------|
| `[General]` | Any codebase / language-agnostic |
| `[Apple]` | iOS + iPadOS + macOS |
| `[iOS/iPadOS]` | iOS and iPadOS, not macOS |
| `[iOS]` | iOS only |
| `[iPadOS]` | iPadOS only |
| `[macOS]` | macOS only |
| `[Swift]` | All Apple platforms, Swift-specific |
| `[SwiftUI]` | SwiftUI-specific |
| `[UIKit/AppKit]` | UIKit or AppKit-specific |
| `[Python]` | Python server only |
| `[Proto3]` | Applies to .proto files regardless of platform |
| `[gRPC]` | Applies to gRPC usage on any platform |

**Scope clarification:** "First-party" means APIs and servers you own and build.
"Third-party" means external services (payment processors, social auth, analytics, etc.)
gRPC + Proto3 rules apply to first-party only. Third-party rules use their native protocols.

---

## 1. SOLID Principles

1. **Single Responsibility Principle (SRP)** `[General]`
   Each class, struct, or function should have exactly one reason to change. If you cannot describe a type's purpose in one sentence without using "and," it has too many responsibilities.

2. **Open/Closed Principle** `[General]`
   Code should be open for extension and closed for modification. Use protocols (Swift) and abstract base classes / Protocol classes (Python) to allow new behavior without editing existing code.

3. **Liskov Substitution Principle** `[General]`
   Subtypes must be fully substitutable for their base type without altering program correctness. Especially relevant when using the mutable-subclass-of-immutable-parent pattern — the subclass must not violate base-type invariants.

4. **Interface Segregation Principle** `[General]`
   Many small, focused protocols/interfaces are better than one large general-purpose one. No type should be forced to depend on methods it doesn't use.

5. **Dependency Inversion Principle** `[General]`
   High-level modules must not depend on low-level modules; both should depend on abstractions (protocols/interfaces). Concrete implementations are injected, never created internally.

---

## 2. General Design Principles

6. **DRY — Don't Repeat Yourself** `[General]`
   Every piece of knowledge has a single authoritative representation. Duplication of logic (not just code) is the target. In a Proto3 context, this means never duplicating a message definition across .proto files — import instead.

7. **YAGNI — You Aren't Gonna Need It** `[General]`
   Never build a feature speculatively. Build for current requirements; extend when the need is real. Critical for MVP discipline. In gRPC: don't define RPC methods that have no current caller.

8. **KISS — Keep It Simple** `[General]`
   Prefer the simplest correct solution. Clever code is a liability. Simple code is easier to test, debug, and hand off to an AI agent.

9. **Composition Over Inheritance** `[General]`
   Build complex behavior by composing simple components rather than deep class hierarchies. Inheritance couples tightly; composition is flexible.

10. **Principle of Least Privilege** `[General]`
    Every component (code module, API scope, OS permission) should request and use only the minimum access it needs.

11. **Fail Fast** `[General]`
    Detect and report errors as close to the source as possible. Guard clauses, preconditions, and early returns over deeply nested conditionals. In gRPC: return the most specific canonical status code immediately when a precondition fails.

12. **Separation of Concerns** `[General]`
    Distinct concerns (networking, persistence, business logic, presentation) live in distinct layers. No layer reaches past its immediate neighbor.

---

## 3. Architectural Patterns *(Descriptive — choose per project)*

13. **MVVM (Model-View-ViewModel)** `[SwiftUI]`
    Best fit for SwiftUI-primary apps. View observes ViewModel; ViewModel transforms domain models into view state. No business logic in View. ViewModel is not aware of any specific View type.

14. **MVC (Model-View-Controller)** `[UIKit/AppKit]`
    The native UIKit/AppKit pattern. Valid when UIKit components dominate. *Anti-pattern: Massive View Controller* — see §16.

15. **The Composable Architecture (TCA)** `[Apple]`
    Unidirectional data flow (Action → Reducer → State → View). Highly testable; steep learning curve. Best for complex, deeply stateful apps. Use the `@Reducer` macro (TCA 1.x).

16. **VIPER** `[Apple]`
    View-Interactor-Presenter-Entity-Router. Maximum separation of concerns; highest verbosity. Best for large team projects with strict module ownership. Likely over-engineered for solo/small team work.

17. **Clean Architecture (Layered)** `[General]`
    Three concentric layers: Presentation → Domain (Use Cases + Entities) → Data (Repositories + Sources). The innermost Domain layer has zero dependencies on outer layers. Works symmetrically for both Swift and Python. Generated Protobuf types live in the Data layer, never in Domain.

18. **Coordinator Pattern** `[UIKit/AppKit]`
    Separates navigation logic from ViewControllers. Each Coordinator owns a navigation flow. In SwiftUI, `NavigationStack` + typed NavigationPath reduces the need, but Coordinators remain useful for complex branching flows.

19. **Module-Based / Feature-Based Architecture** `[Apple]`
    Divide the app into independently compilable Swift packages (local or remote). Enforces dependency boundaries, reduces build times, enables parallel development.

20. **Service Layer** `[General]`
    Stateless service objects encapsulate business logic. Services depend on Repository abstractions, not concrete data sources. One service per bounded domain context. gRPC stubs are injected into services, not called directly from business logic.

21. **Repository Pattern** `[General]`
    Abstracts data sources (remote gRPC service, local DB, cache) behind a unified interface. Business logic never calls gRPC stubs, CoreData, or SQLAlchemy directly. Enables seamless swapping of persistence or transport mechanisms and simplifies test doubles.

---


### Universal Layer Discipline *(applies regardless of chosen pattern)*

175. **Document Pattern Before Implementation** `[General]`
     Choose one primary architecture pattern per app target and document the choice in README.md or ARCHITECTURE.md before writing production code. Mixed-pattern seams within a target require explicit documentation and justification.

176. **Physical Layer Separation** `[General]`
     Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may skip past its immediate neighbor (Presentation → Domain → Data; never Presentation → Data directly).

177. **Domain Layer Has No Framework Imports** `[General]`
     The domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, GRPCCore, grpcio, or any persistence or networking framework. This boundary is verifiable as an import graph.

178. **Generated Types Live in the Data Layer** `[gRPC]` `[General]`
     Generated Protobuf and gRPC types are transport types. They reside in the data layer only. They must never appear in domain-layer or presentation-layer type signatures. This rule is the in-code enforcement of §83 (Protobuf Message → Domain Model Mapping).

179. **Every Cross-Layer Dependency Is a Protocol** `[General]`
     Every boundary between layers is expressed as a protocol abstraction. Concrete types are injected into the consuming layer; the consuming layer never instantiates them directly.

180. **Shared State Has Explicit Ownership Documentation** `[General]`
     Every shared mutable state declaration documents: the owner type, the owning actor or thread, the lifecycle (who creates it, who destroys it), and the mutation contract. Undocumented shared mutable state is treated as a defect in code review.

181. **Services Are Stateless by Default** `[General]`
     Services contain no instance state unless explicitly designed as stateful. Stateful services document their state variables, threading guarantees, and invalidation policy at the class or type definition.

182. **Navigation Logic Lives Outside Views and ViewModels** `[Apple]`
     Routing, navigation, and flow orchestration do not live in View or ViewModel types. Use Coordinator (UIKit/AppKit), NavigationStack with a typed `NavigationPath` (SwiftUI), or a Router type, depending on the chosen pattern.

---
## 4. Design Patterns

22. **Builder Pattern** `[General]`
    Construct complex objects step-by-step through a fluent interface. Pairs naturally with the immutability rule — use a mutable `Builder` type to configure, then produce a final immutable product. Also useful for constructing complex Protobuf messages in test code without polluting production call sites.

23. **Factory Method / Abstract Factory** `[General]`
    Create objects without specifying the exact class at the call site. Use for platform-specific implementations (e.g., different persistence backends per platform) and for test double injection. Use factories to create configured gRPC channels for different environments (dev, staging, prod).

24. **Dependency Injection (Constructor Injection preferred)** `[General]`
    Pass all dependencies into a type's initializer. Property injection is a fallback; method injection for contextual dependencies. Never use a type's initializer to create its own dependencies. gRPC stubs/clients are always injected, never instantiated inside business logic.

25. **Strategy Pattern** `[General]`
    Encapsulate interchangeable algorithms behind a common protocol/interface. Use for swappable serialization formats, authentication strategies, data source selection, and ML inference backends.

26. **Observer Pattern** `[General]`
    Decouple event producers from consumers. In Swift: `@Observable`, Combine publishers, `AsyncStream`. In Python: callback registries, event emitters, or pub/sub (Redis, RabbitMQ). For gRPC server-streaming and bidirectional-streaming RPCs, bridge the stream to an `AsyncStream` (Swift) or `async for` generator (Python) at the transport boundary so the rest of the app uses idiomatic async patterns.

27. **State Pattern / State Machine** `[General]`
    Model explicit states as an enum with associated values rather than boolean flag combinations. A type can only be in one state at a time; transitions are explicit and exhaustive. Model gRPC call lifecycle (idle, connecting, active, closing, closed, failed) as a state machine, not a set of boolean flags.

28. **Command Pattern** `[General]`
    Encapsulate an operation as an object. Enables undo/redo, queuing, and audit logging. Natural fit for user actions in document-based apps and for async job queues in Python.

29. **Decorator Pattern** `[General]`
    Add behavior to an object without modifying its class. In Python: use `@decorator` syntax. In Swift: use protocol extensions or wrapper `struct` types conforming to the same protocol as the wrapped type. gRPC interceptors (§17) are the preferred decorator mechanism for cross-cutting gRPC concerns.

30. **Adapter Pattern** `[General]`
    Convert the interface of one type to the interface expected by another. Critical at the gRPC boundary: generated Protobuf message types are adapted into domain model types immediately after receipt. Domain models are never passed directly to gRPC stubs.

31. **Facade Pattern** `[General]`
    Provide a simplified interface to a complex subsystem. Use to wrap generated gRPC stubs and their channel/metadata management behind a clean service protocol. Callers see a simple `async throws` interface, not gRPC machinery.

32. **Proxy Pattern** `[General]`
    Control access to an object. Use for lazy loading, caching, access control, and logging without modifying the underlying type.

33. **Chain of Responsibility** `[General]`
    Pass a request along a chain of handlers until one processes it. The gRPC interceptor chain is the canonical implementation of this pattern for all gRPC traffic. Python middleware stacks (Starlette, FastAPI) implement it for HTTP traffic.

34. **Template Method** `[General]`
    Define the skeleton of an algorithm in a base type; subclasses/conformers fill in the steps. Use when multiple types share a common process with varying steps.

---

## 5. Swift / Apple-Specific Patterns

35. **Protocol-Oriented Programming (POP)** `[Swift]`
    Prefer protocols and protocol extensions over class inheritance. Enables composition of behavior across unrelated types. Default implementations in extensions provide opt-in behavior without forcing inheritance. Define a protocol wrapping each gRPC stub to enable test doubles without a live server.

36. **Value Type-First Design** `[Swift]`
    Default to `struct` for all domain model and data types. Use `class` only when reference semantics, identity equality, or Objective-C interop is explicitly required. Note: generated gRPC/Protobuf Swift types are `struct`s by default — this aligns with this rule, but they must still be mapped to domain types before entering business logic.

37. **`@Observable` for View Models** `[SwiftUI]`
    Use the `@Observable` macro (iOS 17+/macOS 14+) for all new ViewModel types. Prefer over `ObservableObject` + `@Published` for new code. Coexist with legacy `ObservableObject` types.

38. **`@MainActor` for UI-Bound Types** `[Swift]`
    Annotate ViewModels and any type that updates UI state with `@MainActor`. This makes the compiler enforce main-thread access rather than relying on runtime discipline.

39. **Actor Isolation for Shared Mutable State** `[Swift]`
    Use `actor` types for any shared mutable state accessed concurrently. Never share mutable state across actor boundaries without `Sendable`-conforming types. gRPC streaming responses are consumed inside an actor or passed across boundaries only as `Sendable`-conforming value types.

40. **`Sendable` Discipline** `[Swift]`
    All types crossing actor or task boundaries must conform to `Sendable`. Generated Protobuf Swift types conform to `Sendable` — verify this holds after each `protoc` run and after grpc-swift updates. Value types (`struct`, `enum`) with `Sendable` stored properties are implicitly `Sendable`.

41. **Structured Concurrency** `[Swift]`
    Use `async let`, `TaskGroup`, and `withThrowingTaskGroup` for child tasks. Use `withTaskCancellationHandler` to clean up on cancellation. For gRPC streaming calls, cancellation of the enclosing Swift `Task` must propagate cancellation to the gRPC call — use `withTaskCancellationHandler` to call `call.cancel()` on the gRPC stream.

42. **Typed Throws (Swift 6)** `[Swift]`
    Use `throws(SpecificErrorType)` for functions where the error type is known. At the gRPC boundary, translate `GRPCStatus` into a domain-specific typed error before rethrowing. Callers of repository/service methods should never see raw `GRPCStatus` errors.

43. **`@frozen` Enums** `[Swift]`
    Mark enums `@frozen` when their case set is guaranteed stable across module updates (e.g., in a published framework). Enables exhaustive `switch` without `@unknown default`. Do not use in apps — only frameworks. Note: generated Protobuf Swift enums are NOT `@frozen` because proto enums must handle unknown values — always include `@unknown default` when switching on them.

44. **ViewModifier Pattern** `[SwiftUI]`
    Encapsulate reusable view behavior or styling into a named `ViewModifier` type. Eliminates repeated modifier chains and makes intent explicit at the call site.

45. **`UIViewRepresentable` / `NSViewRepresentable`** `[SwiftUI]`
    Bridge UIKit/AppKit components into SwiftUI using `UIViewRepresentable` (iOS/iPadOS) or `NSViewRepresentable` (macOS). Always implement `updateUIView`/`updateNSView` to sync state changes from SwiftUI to the wrapped view.

46. **`PreferenceKey` for Child→Parent Communication** `[SwiftUI]`
    Use `PreferenceKey` when a child view needs to communicate data upward through the view tree and `@Binding` is insufficient (e.g., reporting measured sizes, scroll positions).

47. **SwiftUI `Environment` for DI** `[SwiftUI]`
    Use `@Environment` and `@EnvironmentObject` (or `@Environment` with `@Observable` in iOS 17+) for injecting dependencies into the view tree. Keep injected types coarse-grained; do not inject fine-grained services through environment.

---

## 6. Immutability Rules

48. **`let` by Default, `var` by Exception** `[Swift]`
    All properties and local variables are `let` unless mutation is explicitly required. The compiler enforces this. Any use of `var` requires a conscious decision.

49. **Custom Types Are Immutable Unless Specified** `[Swift]`
    All custom classes and objects are immutable by default. Any class requiring mutable state must be a subclass of an immutable parent class. The parent class defines the interface; the subclass adds only mutable properties, never removes invariants (LSP applies). Generated Protobuf types are immutable structs and satisfy this rule automatically.

50. **Frozen Python Dataclasses for Domain Models** `[Python]`
    Use `@dataclass(frozen=True)` for all domain model / value object types in Python. This mirrors the Swift immutability requirement and prevents accidental mutation in service layers. Note: generated Protobuf Python classes are mutable — map them to frozen dataclasses at the gRPC boundary.

51. **Immutable Transport Models at the Boundary** `[General]`
    Deserialize / decode all incoming data (gRPC Protobuf messages for first-party; JSON responses for third-party) into immutable model objects immediately at the transport boundary. Any transformation to a mutable working representation is a deliberate, named, explicit step — not an in-place mutation.

52. **Copy-on-Write Semantics for Custom Value Types** `[Swift]`
    For custom value types that wrap a reference type internally, implement CoW manually using `isKnownUniquelyReferenced`. Swift's standard collections do this automatically; custom types must not assume they inherit it.

53. **`let`-Bound Constants for Configuration** `[General]`
    All configuration constants are `let`-bound (Swift) or `Final` class attributes / module-level constants (Python). Never use global mutable config variables. gRPC channel configuration (host, port, TLS settings, keepalive) is expressed as an immutable configuration value type, not loose global variables.

---

## 7. Concurrency

54. **`async`/`await` First** `[Swift]` `[Python]`
    Prefer `async`/`await` over callback-based APIs, completion handlers, and Combine for new code. grpc-swift's async API and Python `grpcio-aio` (asyncio gRPC) are the required clients — do not use the synchronous gRPC stubs in production application code.

55. **Never Block the Main Thread** `[Apple]`
    I/O, heavy computation, and synchronous network calls are never performed on the main thread. All gRPC calls are `await`ed from a non-`@MainActor` context; results are dispatched to `@MainActor` only for UI binding.

56. **Propagate Cancellation** `[Swift]` `[Python]`
    Long-running async tasks check `Task.isCancelled` at each suspension point (Swift) or handle `asyncio.CancelledError` without swallowing it (Python). For gRPC streaming calls: Swift — use `withTaskCancellationHandler` to cancel the gRPC call object when the Swift Task is cancelled. Python — cancelling the asyncio task must cancel the gRPC stream iterator.

57. **Coexist Combine + async/await** `[Swift]`
    Combine remains valid for complex reactive pipelines (debounce, merge, map chains). Bridge gRPC server-streaming and bidirectional-streaming responses to `AsyncStream` first; then bridge to Combine via `AsyncStream.publisher` if existing Combine pipelines consume it. Do not feed raw gRPC stream callbacks into Combine subjects.

58. **Python asyncio for I/O-Bound Work** `[Python]`
    All I/O-bound operations (gRPC calls, DB queries, outbound HTTP, file I/O) use `async def` with `grpcio-aio`. CPU-bound operations (ML inference, data processing) are offloaded via `asyncio.run_in_executor` with a `ProcessPoolExecutor`.

59. **Background Task Scheduling** `[iOS/iPadOS]`
    Use `BGTaskScheduler` (`BGAppRefreshTask`, `BGProcessingTask`) for background work. Respect system scheduling constraints. Register all tasks in `Info.plist`. Never rely on undocumented background execution time. gRPC calls initiated from background tasks must set an appropriate deadline shorter than the system-granted background time.

---

## 8. Error Handling

60. **Domain-Specific Typed Error Enums** `[General]`
    Define one error enum per domain layer (e.g., `NetworkError`, `PersistenceError`, `AuthError`). Each case carries associated values providing context. gRPC `GRPCStatus` / Python `grpc.RpcError` is translated at the repository/service boundary into a domain error — it never propagates into business logic or UI layers raw.

61. **Never Swallow Errors** `[General]`
    Every `catch` block must handle, log, or rethrow. An empty `catch {}` block is a code review failure.

62. **`Result<Success, Failure>` for Storable Errors** `[Swift]`
    Use `Result` when an error must be stored, passed as a value, or returned from a non-throwing synchronous context. Use `throws` for propagation, `Result` for storage.

63. **gRPC Status Code Mapping at the Transport Boundary** `[gRPC]`
    gRPC canonical status codes (`NOT_FOUND`, `INVALID_ARGUMENT`, `UNAUTHENTICATED`, `PERMISSION_DENIED`, `UNAVAILABLE`, `DEADLINE_EXCEEDED`, etc.) are mapped to typed domain errors at the repository layer. Business logic selects behavior based on domain error type, never by inspecting raw gRPC status codes. For third-party REST APIs: HTTP status codes are mapped to domain errors at the network layer using the same discipline.

64. **Rich Error Details with `google.rpc.Status`** `[gRPC]` `[Proto3]`
    For error responses requiring structured detail (field validation failures, quota information, retry guidance), use `google.rpc.Status` with populated `details` field using well-known types from `google/rpc/error_details.proto` (`BadRequest`, `ErrorInfo`, `RetryInfo`, `QuotaFailure`). Never encode error detail in a custom top-level Protobuf message field.

65. **Python Exception Hierarchy** `[Python]`
    Define custom exceptions inheriting from appropriate stdlib base exceptions. Never use bare `except:` or `except Exception:` without re-raising or structured logging. For gRPC server handlers: catch domain exceptions and translate them into `grpc.StatusCode` + detail string before returning — never let unhandled exceptions surface as `INTERNAL` status codes in production.

66. **Exponential Backoff with Jitter for Retries** `[General]`
    Retry transient gRPC failures (`UNAVAILABLE`, `DEADLINE_EXCEEDED`) with exponential backoff and random jitter. Never retry `INVALID_ARGUMENT`, `NOT_FOUND`, `ALREADY_EXISTS`, `PERMISSION_DENIED`, or `UNAUTHENTICATED` — these are not transient. Cap maximum retry count and delay. Make retry behavior configurable per RPC type.

---

## 9. Security

67. **Keychain for All Sensitive Credentials** `[Apple]`
    Tokens, passwords, private keys, and sensitive identifiers are stored in the Keychain. Never in `UserDefaults`, `AppStorage`, plist files, or the filesystem. This includes gRPC auth tokens and any refresh tokens.

68. **No Hardcoded Secrets** `[General]`
    No API keys, secrets, tokens, or credentials appear in source code, plist files, or asset catalogs. Swift: use Keychain + server-vended tokens passed as gRPC call metadata. Python server: use environment variables + a secrets manager (AWS Secrets Manager, HashiCorp Vault, or `.env` + `pydantic-settings` for local dev only).

69. **TLS for All gRPC Channels (First-Party)** `[gRPC]`
    All first-party gRPC channels use TLS — no plaintext channels in production. On Apple platforms: configure the grpc-swift channel with `.tls(GRPCTLSConfiguration.makeClientDefault())`. Verify server certificates using the system trust store. For production APIs with a fixed server certificate, implement certificate pinning by providing a custom `NIOSSLTrustRoots` configuration with the pinned certificate or public key hash — do NOT use `URLSessionDelegate` cert pinning for gRPC; gRPC uses NIO transport with its own TLS stack.

70. **gRPC Auth Tokens in Call Metadata, Not in Messages** `[gRPC]` `[Proto3]`
    Authentication tokens (JWT, OAuth access tokens, API keys) are passed as gRPC call metadata (HTTP/2 headers), never as fields in Protobuf request messages. A gRPC interceptor handles token injection on the client side and token validation on the server side — auth logic never appears in handler business logic.

71. **App Transport Security (ATS)** `[Apple]`
    `NSAllowsArbitraryLoads` is never set to `true` globally. gRPC uses HTTP/2 over TLS — this is ATS-compliant by default. Any ATS exceptions are scoped to specific domains and documented.

72. **Input Validation at Every Trust Boundary** `[General]`
    All external input (user input, gRPC request fields, third-party API responses, deep link parameters) is validated before processing. In Python gRPC handlers: validate request message fields explicitly at the handler entry point using Pydantic validators or manual checks before passing to business logic. In Swift: validate incoming gRPC response fields before mapping to domain models.

73. **SQL Injection Prevention** `[Python]`
    Always use parameterized queries or ORM query builders. User input from gRPC request fields is never interpolated into SQL strings.

74. **JWT / OAuth 2.0 Best Practices** `[General]`
    Use short-lived access tokens (≤15 min) with refresh token rotation. Validate all claims (`exp`, `iss`, `aud`, `sub`) server-side in the gRPC auth interceptor on every request. Revoke refresh tokens on logout.

75. **Privacy Manifests** `[Apple]`
    Every App Store submission includes a `PrivacyInfo.xcprivacy` manifest declaring all accessed required reason APIs and all third-party SDK data practices. This is an App Store requirement enforced since May 2024.

76. **Minimum Permissions** `[Apple]`
    Request location, camera, microphone, contacts, and other sensitive permissions only at the moment of first use, with a clear purpose string. Never pre-request permissions at launch.

77. **Biometric Authentication** `[Apple]`
    Use `LocalAuthentication` for Face ID / Touch ID. Always provide a fallback to passcode. Handle `LAError` cases explicitly. After successful biometric auth, retrieve the gRPC auth token from Keychain and inject it into the gRPC channel credentials or per-call metadata.

78. **Rate Limiting on All gRPC Handlers** `[Python]`
    Implement server-side rate limiting in a gRPC server interceptor. Apply per-user and per-IP limits. Return `RESOURCE_EXHAUSTED` status code (the gRPC equivalent of HTTP 429) with a `RetryInfo` error detail containing the recommended retry delay.

79. **Sandboxing and Entitlements** `[Apple]`
    App Sandbox is enabled. Entitlements are the minimum required set. Each entitlement is justified in comments.

80. **Secure Coding — Avoid `unsafe`** `[Swift]`
    Use of `unsafe` APIs is minimized, isolated to clearly named wrapper functions, and accompanied by a safety invariant comment. Never use `@unchecked Sendable` to silence Swift 6 concurrency warnings without ensuring actual thread safety.

81. **Dependency Vulnerability Scanning** `[General]`
    Regularly scan third-party dependencies: `swift package update` + review changelogs (Swift); `pip-audit` or `safety` (Python); monitor `grpc-swift` and `grpcio` release notes for security patches. Block known-vulnerable versions when CI is adopted.

---

## 10. Networking & API Design

82. **gRPC Stub Behind a Protocol (First-Party)** `[gRPC]` `[General]`
    All first-party gRPC calls are made through a protocol-typed client abstraction. ViewModels and services depend on the protocol, never on a concrete generated gRPC stub. This enables test doubles without a running server. For third-party REST APIs: the same principle applies — wrap in a protocol-typed client, never call `URLSession` directly from business logic.

83. **Protobuf Message → Domain Model Mapping (First-Party)** `[gRPC]`
    Generated Protobuf message types are the Data Transfer Objects at the gRPC transport boundary. They are mapped to immutable domain model types immediately upon receipt. Domain models are never passed to gRPC stubs as request messages; construct Protobuf request messages from domain types at the call site. Generated types never appear in ViewModel, Presenter, or UI layer signatures.

84. **`Codable` / `Decodable` for Third-Party REST APIs** `[Swift]`
    All third-party API response models conform to `Codable`. JSON field names are decoupled from Swift property names via `CodingKeys` enums. Date decoding strategies are set explicitly on the `JSONDecoder`. This rule does not apply to first-party APIs, which use Protobuf.

85. **Pydantic v2 for Third-Party REST and Internal Validation** `[Python]`
    Pydantic `BaseModel` types are used for: consuming third-party REST API responses, parsing incoming webhook payloads, and internal service-layer validation objects that do not cross the gRPC boundary. For first-party gRPC interfaces, the generated Protobuf Python classes are the transport types; map them to `@dataclass(frozen=True)` domain objects at the handler boundary.

86. **Protobuf as Schema Source of Truth (First-Party)** `[Proto3]` `[General]`
    `.proto` files are the single authoritative definition for all data schemas and service contracts shared between Swift clients and Python servers. Swift client types and Python server types are generated from these files using `protoc`. No first-party shared schema is defined anywhere other than a `.proto` file. OpenAPI specs are used only when consuming or publishing third-party REST APIs.

87. **ISO 8601 for Third-Party REST; `google.protobuf.Timestamp` for Proto3** `[General]`
    In third-party REST API integrations: dates and timestamps are ISO 8601 strings in UTC. In all first-party Proto3 message definitions: use `google.protobuf.Timestamp` for all date/time fields. Use `google.protobuf.Duration` for all duration fields. Never use plain `int64` Unix timestamps in Protobuf messages — the intent is ambiguous.

88. **Cursor-Based Pagination in gRPC List RPCs** `[gRPC]` `[Proto3]`
    List RPCs return a `next_page_token` string field and accept a `page_token` string field. Page size is bounded server-side. Clients must not assume a specific page size. Define a reusable `PageRequest` / `PageResponse` message in a shared `common.proto` rather than duplicating pagination fields across services.

89. **gRPC Service Versioning** `[gRPC]` `[Proto3]`
    All gRPC service definitions include a version in their package name: `package com.example.myservice.v1;`. Breaking changes are introduced in a new package version (`v2`), never applied to an existing versioned package. Non-breaking additions (new fields, new RPC methods) may be added to existing versions.

90. **Idempotency Keys for Mutating RPCs** `[gRPC]` `[Proto3]`
    Non-idempotent unary RPCs that create or initiate operations include an `idempotency_key` string field in the request message. The server deduplicates using this key within a defined window. Define this field consistently across all such RPCs.

91. **Offline-First / Optimistic Updates** `[iOS/iPadOS]`
    Where UX requires it, update local state optimistically before gRPC call confirmation. Roll back on error response. The local cache is the source of truth for display; sync status is surfaced to the user.

---

## 11. Data Persistence

92. **Repository Pattern for All Persistence** `[General]`
    Business logic accesses data exclusively through Repository interfaces. No View, ViewModel, or Service directly calls CoreData, SwiftData, SQLAlchemy, or any raw DB API.

93. **SwiftData / Core Data on `@MainActor`** `[Apple]`
    The view context / `ModelContext` is accessed only on the main thread/actor. Background operations use a dedicated background context.

94. **Plan Migrations from Day One** `[General]`
    Define a migration strategy before writing the first schema. In Swift: lightweight migration for minor changes; custom policies for destructive changes. In Python: use Alembic or the framework's built-in migration tool. Never drop and recreate in production.

95. **No Raw SQL in Application Code** `[Python]`
    All database interactions use an ORM or query builder. Raw SQL is isolated in explicitly named `_raw_query` methods with a comment explaining why the ORM is insufficient.

96. **Explicit Cache Invalidation Strategy** `[General]`
    Every cache has a documented TTL and explicit invalidation trigger(s). Cache invalidation logic lives alongside the cache implementation. For data fetched via gRPC, document whether server-streaming updates invalidate the cache or whether polling is used.

---

## 12. Testing

97. **Test Pyramid Discipline** `[General]`
    Many unit tests > fewer integration tests > fewest UI tests. UI tests cover only critical, high-value user flows. Fast tests run in CI; slow tests are gated.

98. **Protocol-Based gRPC Test Doubles** `[Swift]` `[gRPC]`
    Wrap generated gRPC stubs in a protocol. Provide a fake implementation returning canned Protobuf response messages in tests. Use `grpc-swift`'s built-in test server utilities for integration tests that require a real gRPC transport. Never make live gRPC calls in unit tests.

99. **Swift Testing Framework (`@Test`, `#expect`)** `[Swift]`
    Use the Swift Testing framework for all new test code. Coexist with legacy XCTest suites without rewriting them.

100. **`pytest` with `pytest-asyncio` and `grpcio-testing`** `[Python]`
     Use `pytest` as the standard test runner. Use `pytest-asyncio` for async tests. Use `grpcio-testing` or in-process gRPC server utilities for handler integration tests. Use fixtures over `setUp`/`tearDown`. Use `pytest-cov` for coverage reporting.

101. **Deterministic Tests** `[General]`
     Tests never depend on real system time, random seeds, or live network calls. Inject a `Clock` protocol (Swift) or mock `datetime.now` (Python). All gRPC calls use protocol-typed test doubles. No test connects to a live server.

102. **Test Naming Convention** `[General]`
     Swift: `testWhenConditionThenExpectedOutcome()`. Python: `test_<what>_<condition>_<expected_outcome>`. Test names are self-documenting failure messages.

103. **Protobuf Schema Compatibility Testing** `[gRPC]` `[Proto3]`
     When `.proto` files change, run `buf breaking` (from the `buf` CLI) to detect backward-incompatible changes before merging. Wire compatibility is verified by a dedicated test that serializes a known message with the old schema and deserializes with the new schema. Add this to the pre-merge checklist (and later to CI).

104. **Snapshot Testing for UI** `[SwiftUI]` `[UIKit/AppKit]`
     Use snapshot tests for complex UI components to catch unintended visual regressions. Snapshots are committed to source control and reviewed in PRs.

105. **Test Double Hierarchy** `[General]`
     Use the simplest test double that satisfies the test: Dummy → Stub → Fake → Spy → Mock. Overuse of full mocks indicates a design problem (too many dependencies).

---

## 13. Shared Schema: Proto3 Source of Truth

106. **One Service Definition Per `.proto` File** `[Proto3]`
     Each gRPC service is defined in its own `.proto` file. Shared message types (common request/response wrappers, pagination types, error detail types) live in dedicated `common.proto` or domain-specific shared files and are imported by service files. Never define a message and a service in the same file unless the message is used exclusively by that service.

107. **Versioned Protobuf Field Deprecation** `[Proto3]`
     When a field is no longer needed, mark it with the `[deprecated = true]` option and add a comment explaining the replacement. Reserve the field number and name using `reserved` after the deprecation period. Never remove a field number and reuse it — this causes silent data corruption on the wire. Never rename a field without a transition period.

108. **`proto3 optional` for Truly Nullable Fields** `[Proto3]`
     In Proto3, all scalar fields have default values (0, false, empty string) and cannot distinguish "absent" from "default." Use the `optional` keyword (proto3 optional, supported in protoc 3.15+) for fields where the distinction between absent and default is semantically meaningful. Document every `optional` field's nullability contract in a comment. Do not use wrapper types (`google.protobuf.Int32Value`, etc.) for this purpose in new code.

109. **Consistent gRPC Error Response Shape** `[gRPC]` `[Proto3]`
     All gRPC error responses use gRPC status codes + `google.rpc.Status` with `details` populated from `google/rpc/error_details.proto`. There is no custom error message Protobuf type. Swift: decode error details from the gRPC trailing metadata using grpc-swift's `GRPCStatus.makeError` utilities. Python: attach error details using the `grpcio-status` library.

---

## 14. Apple Platform-Specific Concerns

110. **Scene-Based Lifecycle** `[Apple]`
     Use `UISceneDelegate` (UIKit) or SwiftUI's `App` / `Scene` protocol for lifecycle management. The `UIApplicationDelegate` handles only app-wide concerns (push notification registration, background URL session handling). gRPC channels are created at scene activation and cancelled/torn down at scene background.

111. **Adaptive Layouts with Size Classes** `[iOS/iPadOS]`
     Build adaptive UIs using `@Environment(\.horizontalSizeClass)`, `@Environment(\.verticalSizeClass)`, and `GeometryReader`. Avoid hardcoded point dimensions.

112. **iPad Multitasking Support** `[iPadOS]`
     Support Split View and Slide Over from the start. Use `UISplitViewController` or SwiftUI `NavigationSplitView` for two/three-column layouts. Avoid fixed-width layouts.

113. **macOS Menu Bar and Keyboard Shortcuts** `[macOS]`
     Provide complete menu bar integration using `CommandMenu` (SwiftUI) or `NSMenu` (AppKit). All primary actions have keyboard shortcuts.

114. **Mac Catalyst — Handle `UIUserInterfaceIdiom.mac`** `[macOS]`
     When shipping via Catalyst, explicitly detect and handle `.mac` idiom. Optimize the toolbar, remove touch-specific controls, adopt `NSToolbar` via `UIWindowScene.titlebar`.

115. **Universal Links and Deep Linking** `[Apple]`
     Implement Universal Links (HTTPS-based) for all navigable content. Test all deep link paths including cold-start launch.

116. **Dynamic Type Support** `[Apple]`
     All text uses Dynamic Type. In SwiftUI: use named text styles. In UIKit: use `UIFontMetrics` for custom fonts. Test at all accessibility text sizes.

117. **VoiceOver and Accessibility** `[Apple]`
     All interactive elements have `accessibilityLabel`, `accessibilityHint`, and `accessibilityValue`. Audit with the Accessibility Inspector.

118. **Dark Mode via Semantic Colors** `[Apple]`
     Use semantic color names exclusively. No hardcoded hex or RGB values in production UI code.

119. **App Lifecycle State Handling** `[iOS/iPadOS]`
     Handle `sceneDidEnterBackground` (save state, cancel non-essential gRPC streams), `sceneWillResignActive` (pause animations, hide sensitive data), and `sceneWillEnterForeground` (refresh stale data, reconnect gRPC channels if needed).

120. **Memory Warning Handling** `[iOS/iPadOS]`
     Implement `didReceiveMemoryWarning`. Clear image caches, evict non-critical data, cancel low-priority background gRPC streams.

---

## 15. Python Server-Specific

121. **Type Annotations Everywhere** `[Python]`
     All function signatures, class attributes, and module-level variables have type annotations. Enforced with `mypy` in strict mode. No `Any` without a `# type: ignore` comment explaining the exception. Generated Protobuf Python stubs provide type hints — use them.

122. **Dependency Injection via Constructors** `[Python]`
     Avoid module-level global state. Inject database sessions, HTTP clients, gRPC stubs, and configuration via class constructors or function parameters.

123. **Async Context Managers for Resources** `[Python]`
     Database connections, HTTP client sessions, gRPC channels, and file handles are managed with `async with`. Resources are never leaked. gRPC channel lifecycle (creation, health check, shutdown) is managed in a dedicated context manager, not scattered across handlers.

124. **Pydantic Settings for Configuration** `[Python]`
     Use `pydantic-settings` for all application configuration. Configuration is loaded from environment variables with type validation and documented defaults. gRPC server port, TLS cert paths, keepalive settings, and max message sizes are all configured through this system.

125. **Structured Logging** `[Python]`
     Use `structlog` or the stdlib `logging` module with a JSON formatter. Log entries include `request_id`, `user_id` (where applicable), and structured context. Never use `print()`. In gRPC server interceptors, log the RPC method name, status code, and latency for every request.

126. **Background Task Idempotency** `[Python]`
     All Celery / ARQ / RQ tasks are idempotent by design. Use task-level idempotency keys. Implement dead-letter queues for failed tasks. Set explicit retry limits and backoff.

127. **WebSocket / gRPC Bidirectional Streaming State Management** `[Python]`
     Track connection/stream state explicitly (connecting, connected, disconnecting, disconnected). Implement keepalive to detect stale connections. Handle disconnection and reconnection gracefully without leaking stream objects. For gRPC bidirectional streaming: use `async for` to consume the request iterator; handle `grpc.aio.AbortError` and `asyncio.CancelledError` to clean up server-side resources.

128. **ML Model Versioning** `[Python]`
     ML models are versioned explicitly (semantic version or content hash), never referenced as "latest." Use a model registry or version-tagged artifact paths. Model loading is isolated to a dedicated `ModelRegistry` service. gRPC inference RPCs include a `model_version` field in the request message so clients can target a specific version.

129. **Inference Isolated from Business Logic** `[Python]`
     ML inference code (model loading, preprocessing, prediction, postprocessing) lives in a dedicated service class, not in gRPC handler functions. Handler functions call the inference service and map results to Protobuf response messages. This enables independent testing, versioning, and scaling of the inference layer.

130. **Data Pipeline Idempotency** `[Python]`
     Each stage of a data pipeline is idempotent — running a stage twice on the same input produces the same output. Stages are independently restartable from checkpoints.

131. **Virtual Environment and Pinned Dependencies** `[Python]`
     Always develop inside a virtual environment. All direct AND transitive dependencies are pinned. Use `pyproject.toml` + a lockfile (`uv.lock`, `poetry.lock`). The lockfile is committed to source control. `grpcio`, `grpcio-tools`, `grpcio-status`, and `protobuf` are pinned and kept in sync — version mismatches between these packages cause subtle runtime errors.

132. **`__all__` for Public Module API** `[Python]`
     Define `__all__` in every module to explicitly declare its public interface.

133. **N+1 Query Prevention** `[Python]`
     ORM queries for collections use eager loading. Every new query path is reviewed for N+1 patterns before merging.

---

## 16. gRPC and Proto3

134. **Proto3 Syntax; Never Proto2 for New Files** `[Proto3]`
     All new `.proto` files use `syntax = "proto3";`. Proto2 is not used in new code. If interoperating with a third-party proto2 schema, isolate it in a dedicated adapter layer.

135. **`.proto` File Organization and Naming** `[Proto3]`
     File names are `lower_snake_case.proto`. Package names follow reverse-domain convention: `package com.example.appname.domain.v1;`. Directory structure mirrors the package hierarchy. One service per file; shared messages in a `common/` subdirectory. Generated Swift code goes into a dedicated Swift package; generated Python code goes into a dedicated `generated/` module — neither is edited manually.

136. **Never Edit Generated Code** `[gRPC]` `[Proto3]`
     Files produced by `protoc` or `buf generate` are never hand-edited. They are regenerated from `.proto` files whenever the schema changes. Treat them as build artifacts. Add the generated directories to `.gitignore` or, if committed for deployment convenience, add a prominent warning header and a pre-commit hook to detect drift.

137. **Field Number Stability is Inviolable** `[Proto3]`
     Once a field number is assigned and released, it is never reused for a different field, even if the original field is deleted. Reserve deleted field numbers immediately: `reserved 4, 7;` and `reserved "old_field_name";`. Violating this causes silent data corruption when old and new clients communicate.

138. **Use `buf` for Schema Management** `[Proto3]`
     Use the `buf` CLI for linting `.proto` files (`buf lint`), detecting breaking changes (`buf breaking`), and code generation (`buf generate`). A `buf.yaml` lint configuration and a `buf.gen.yaml` generation configuration are committed to source control alongside the `.proto` files.

139. **gRPC Streaming Pattern Selection** `[gRPC]` `[Proto3]`
     Choose the RPC pattern based on communication semantics:
     - **Unary RPC**: Single request, single response. Use for all CRUD operations and queries.
     - **Server-streaming**: Single request, stream of responses. Use for live feeds, real-time updates, large result sets, and ML inference results delivered incrementally.
     - **Client-streaming**: Stream of requests, single response. Use for chunked file uploads, batch ingestion, and sensor data accumulation.
     - **Bidirectional streaming**: Stream of requests, stream of responses. Use for real-time collaborative features, chat, and interactive ML inference sessions.
     Do not use bidirectional streaming as a general-purpose WebSocket replacement — use it only where the bidirectional, asynchronous semantics are genuinely required.

140. **Always Set Deadlines on gRPC Calls** `[gRPC]`
     Every gRPC call has an explicit deadline. Swift (grpc-swift): set `.timeout` in `CallOptions`. Python (grpcio-aio): pass `timeout=` to the stub call. Never issue a gRPC call with no deadline — the call may hang indefinitely. Deadline values are defined as named constants in a configuration type, not magic number literals at call sites.

141. **gRPC Interceptors for Cross-Cutting Concerns** `[gRPC]`
     Authentication, authorization, structured logging, metrics, distributed tracing, and retry logic are implemented in gRPC interceptors (Swift: `ClientInterceptor`/`ServerInterceptor`; Python: `grpc.aio.ClientInterceptor`/`grpc.aio.ServerInterceptor`). Handler business logic contains none of these concerns. The interceptor chain is assembled at application startup and is testable independently.

142. **gRPC Keepalive Configuration** `[gRPC]`
     Configure gRPC keepalive on both client and server to detect stale connections. Swift: set `keepalive` in `GRPCChannelPool.Configuration`. Python: set `grpc.keepalive_time_ms`, `grpc.keepalive_timeout_ms`, and `grpc.keepalive_permit_without_calls` channel arguments. Mismatched keepalive settings between client and server cause `GOAWAY` frames and unexpected disconnects.

143. **gRPC Health Checking Protocol** `[gRPC]` `[Python]`
     Python servers implement the standard gRPC Health Checking Protocol (`grpc_health_checking`). This enables load balancers, orchestrators (Kubernetes), and client-side channel management to detect unhealthy servers. Swift clients use `GRPCHealthCheck` to verify channel health before issuing calls after a reconnect.

144. **gRPC Server Reflection in Development; Disabled in Production** `[gRPC]` `[Python]`
     Enable gRPC server reflection in development and staging environments to support tooling (`grpcurl`, Postman, BloomRPC). Disable it in production builds — server reflection exposes the full service schema to any client that can reach the server.

145. **Well-Known Types Over Custom Equivalents** `[Proto3]`
     Use Protobuf well-known types from `google/protobuf/` for common patterns:
     - `google.protobuf.Timestamp` → date/time (never `int64` Unix seconds)
     - `google.protobuf.Duration` → time spans (never `int64` milliseconds)
     - `google.protobuf.FieldMask` → partial updates / sparse field selection
     - `google.protobuf.Empty` → RPCs with no meaningful request or response payload
     Do not create custom Protobuf message types that duplicate well-known type semantics.

146. **`FieldMask` for Partial Update RPCs** `[Proto3]` `[gRPC]`
     Update RPCs that allow partial field updates accept a `google.protobuf.FieldMask` field specifying which fields to apply. The server applies only the fields named in the mask. This prevents accidental full-object overwrites from clients that only intended to update one field.

147. **Maximum Message Size Configuration** `[gRPC]`
     Set explicit maximum inbound and outbound message size limits on both client channels and server configuration. The default (4MB) is appropriate for most unary RPCs. For RPCs transferring large payloads (ML model outputs, file content), either increase the limit with documentation justifying the value, or use streaming RPCs to avoid buffering large messages entirely.

148. **Proto3 Enum — Always Provide a Zero `_UNSPECIFIED` Case** `[Proto3]`
     Every Proto3 enum must have a zero-value case named `ENUM_NAME_UNSPECIFIED`. This is the default when a field is not set and is returned by clients that do not recognize a new enum value. Switch statements on proto enums (Swift) must include `@unknown default` handling for this case and for future cases.

149. **gRPC Channel Pooling** `[gRPC]` `[Swift]`
     Use `GRPCChannelPool` (grpc-swift) rather than creating a new channel per request or per view model. A channel pool manages connection lifecycle, handles reconnection, and shares HTTP/2 connections efficiently. Pool configuration (minimum connections, maximum connections, idle timeout) is expressed as a named configuration type.

150. **Protobuf for ML Inference Payloads** `[gRPC]` `[Proto3]`
     ML inference request and response messages use Protobuf with appropriate field types: `repeated float` or `bytes` for tensor data. For large tensor payloads, use server-streaming RPCs to deliver results incrementally. Define a standard `InferenceMetadata` message included in all inference responses (model version, latency, confidence) rather than duplicating these fields per service.

---

## 17. Anti-Patterns to Avoid

151. **Massive View Controller** `[UIKit/AppKit]`
     View Controllers containing data fetching, business logic, persistence, and navigation. Use Coordinators for navigation, ViewModels for state, and Services/Repositories for data.

152. **God ViewModel** `[SwiftUI]`
     ViewModels managing multiple unrelated features in a single class. Split by feature or use case.

153. **God Object** `[General]`
     A class that knows too much or does too much. If a type has more than 7–10 public methods or more than 5 dependencies, it is a candidate for decomposition.

154. **Stringly-Typed Code** `[General]`
     Using raw strings for keys, identifiers, state values, and notification names. Replace with enums, typed constants, and `RawRepresentable` types. In gRPC context: never construct RPC method paths as raw strings — use generated stub methods exclusively.

155. **Force Unwrapping** `[Swift]`
     Using `!` to force-unwrap optionals in production code. Any force-unwrap requires a comment explaining why nil is impossible.

156. **Implicitly Unwrapped Optionals (IUOs)** `[Swift]`
     Declaring `var property: Type!` except for `@IBOutlet` and two-phase initialization requirements.

157. **`print()` for Logging** `[General]`
     Using `print()` (Swift) or bare `print()` (Python) for production diagnostics. Use `os.Logger` / `OSLog` in Swift; `structlog` or configured `logging` in Python.

158. **Singleton Abuse** `[General]`
     Using singletons as a substitute for dependency injection. gRPC channels and stubs are especially susceptible — a `static let shared` gRPC client makes testing impossible and multi-environment support difficult. Use DI; a DI container can manage a single shared instance without making it a global.

159. **Retain Cycles** `[Swift]`
     Closures that capture `self` strongly in a class that retains the closure. Always use `[weak self]` in escaping closures. In gRPC streaming: the stream response handler must use `[weak self]` if stored on a reference type, or the response handler and the object holding it will form a cycle.

160. **`@unchecked Sendable` Without Justification** `[Swift]`
     Every use of `@unchecked Sendable` requires a comment explaining the manual invariant being maintained.

161. **Blocking Async Context** `[Swift]` `[Python]`
     Calling synchronous blocking code from within an `async` function. This includes the synchronous gRPC stub variants (non-`aio` Python stubs, or using `GRPCChannel` without the async API in Swift) inside async contexts. Always use the async gRPC APIs.

162. **Mutable Global State** `[General]`
     Global variables mutated at runtime. In Swift 6: the compiler flags these as concurrency errors. In Python: module-level mutable state is especially dangerous in async gRPC servers where handlers run concurrently.

163. **Using gRPC Bidirectional Streaming as a Generic WebSocket** `[gRPC]`
     Bidirectional streaming RPCs have specific semantics (both sides stream independently and asynchronously). Using them as a drop-in WebSocket replacement for simple request/response multiplexing adds complexity without benefit. Use unary RPCs with server-streaming for push notifications; reserve bidirectional streaming for genuinely bidirectional flows.

164. **Reusing or Renaming Proto3 Field Numbers** `[Proto3]`
     The most dangerous anti-pattern in Protobuf. Reusing a field number for a different type or purpose causes silent data corruption when clients and servers have different schema versions. There is no runtime error — wrong data is silently decoded. Use `reserved` immediately when removing a field.

165. **Hardcoded gRPC Deadlines as Magic Numbers** `[gRPC]`
     Deadline values scattered as numeric literals throughout call sites. Define deadlines as named constants (`AuthService.defaultDeadline`, `InferenceService.streamingDeadline`) in the service configuration type and reference them at call sites.

166. **Calling gRPC Stubs Directly from ViewModels or Views** `[gRPC]` `[Apple]`
     Generated gRPC stubs are transport-layer details. ViewModels and Views call Repository or Service protocol abstractions. The concrete implementation of those protocols makes gRPC calls. Keeping stubs out of the ViewModel layer enables UI testing without a live server.

167. **Ignoring gRPC `UNAVAILABLE` as a Fatal Error** `[gRPC]`
     `UNAVAILABLE` is a transient error indicating the server is temporarily unreachable. It must be retried with backoff, not surfaced to the user as a permanent failure. Only after exhausting retry attempts should a user-visible error be displayed.

168. **N+1 Queries** `[Python]`
     Loading a collection and then issuing one query per item in a loop. Always caught in code review; always fixed before merge.

169. **Direct CoreData/SwiftData Access in Views** `[Apple]`
     SwiftUI Views or UIViewControllers directly accessing `NSManagedObjectContext` or `ModelContext` for mutations. All persistence goes through ViewModels or Repositories.

170. **Premature Optimization** `[General]`
     Optimizing code before profiling. Use Instruments (Apple) or `cProfile`/`py-spy` (Python) to identify actual bottlenecks. Write correct, clear code first.

171. **Magic Numbers and Strings** `[General]`
     Unexplained numeric literals or raw string values embedded in logic. All magic values are replaced with named constants or enum cases with documentation.

172. **Not Handling Background/Foreground Transitions** `[iOS/iPadOS]`
     Apps that ignore lifecycle transitions fail to save state, display stale data, leave gRPC streams open unnecessarily, and may violate App Store privacy guidelines.

173. **Anemic Domain Model** `[General]`
     Domain objects that are pure data containers with no behavior. Evaluate whether the domain object should own its invariants. Note: generated Protobuf types are intentionally anemic — this is correct for transport types. The anti-pattern applies to domain model types, which should encapsulate domain logic.

174. **Editing Generated Protobuf / gRPC Code** `[gRPC]` `[Proto3]`
     Any manual edit to a file produced by `protoc` or `buf generate` will be overwritten the next time code generation runs, creating a confusing source of truth problem. All customization belongs in wrapper types, extension files, or interceptors.

---

## 19. grpc-swift-2 Implementation Rules

*grpc-swift-2 (https://github.com/grpc/grpc-swift-2) is the Swift Concurrency-native gRPC implementation. Use it for all new Swift gRPC code. Do not use grpc-swift v1 APIs in new files.*

183. **Import `GRPCCore` and the NIO Transport** `[Swift]` `[gRPC]`
     Import `GRPCCore` for the core API and `GRPCNIOTransportHTTP2` (or its NIO Posix variant) for the NIO transport. The v1 `GRPC` module must not be imported in new code.

184. **Unary Call Pattern** `[Swift]` `[gRPC]`
     `let response = try await client.someMethod(request, options: callOptions)` — always supply `callOptions` with a named timeout constant.

185. **Server-Streaming Call Pattern** `[Swift]` `[gRPC]`
     `for try await message in client.serverStream(request, options: callOptions).messages { ... }` — the `for try await` loop is the idiomatic pattern; do not accumulate messages into an array when streaming semantics are required.

186. **Client-Streaming and Bidirectional Call Patterns** `[Swift]` `[gRPC]`
     Client-streaming: `try await client.clientStream { writer in try await writer.write(request) }`. Bidirectional: manage the writer in the closure and iterate responses with `for try await msg in stream.messages { ... }`.

187. **`RPCError` Is the Transport Error Type** `[Swift]` `[gRPC]`
     Catch `RPCError` (GRPCCore) at the repository or service boundary. Map `.code` (`RPCError.Code`) to domain errors before rethrowing. `RPCError` must not propagate past the boundary. Do not reference the v1 `GRPCStatus` type in new code.

188. **Swift Task Cancellation Propagates Automatically** `[Swift]` `[gRPC]`
     In grpc-swift-2, cancelling the enclosing Swift `Task` automatically cancels the underlying gRPC call. Explicit `call.cancel()` is not required for Task-scoped calls. For legacy interop only, use `withTaskCancellationHandler`.

189. **`ClientInterceptor` for Cross-Cutting Client Concerns** `[Swift]` `[gRPC]`
     Implement auth token injection, structured logging, retry logic, and distributed tracing as `ClientInterceptor` conformances (GRPCCore). Interceptors are registered at channel construction, not per-call.

190. **Single `GRPCClient` Per App or Scene Lifecycle** `[Swift]` `[gRPC]`
     Manage one `GRPCClient` instance per app or scene lifecycle. Never create a new channel per request, view, or view model. Tie channel creation to scene activation and channel teardown to scene background or foreground resignation.

191. **Verify `Sendable` Conformance After Code Generation** `[Swift]` `[gRPC]`
     After every `buf generate` run, verify that generated Protobuf Swift struct types still conform to `Sendable`. Cross-actor streaming of generated messages requires `Sendable`; absence of the conformance is a concurrency error.

---

## 20. Python grpc.aio Implementation Rules

*`grpc.aio` is the asyncio-native gRPC implementation in `grpcio`. Use it for all server and client code. Do not use `grpc.server(...)` or synchronous stubs in production code.*

192. **Start Server with `grpc.aio.server(...)`** `[Python]` `[gRPC]`
     `server = grpc.aio.server(interceptors=[...])`. The synchronous `grpc.server(...)` is incompatible with asyncio event loops. Always use the `aio` variant.

193. **All Handler Methods Are `async def`** `[Python]` `[gRPC]`
     Every servicer handler method is `async def`. Blocking code in an async handler stalls the entire event loop. Offload CPU-bound work: `await asyncio.get_event_loop().run_in_executor(executor, fn, *args)`.

194. **Return gRPC Errors via `context.abort(...)`, Never by Raising** `[Python]` `[gRPC]`
     Error responses use `await context.abort(grpc.StatusCode.CODE, "detail string")`. Never raise bare Python exceptions from handlers — unhandled exceptions surface as `INTERNAL` status with no client-visible detail.

195. **Rich Error Details via `grpcio-status`** `[Python]` `[gRPC]`
     For structured error details (field validation failures, retry guidance, quota info), use `grpcio-status` and `await context.abort_with_status(grpcio_status.to_status(Status(...)))` with `error_details.proto` message types.

196. **`grpc.aio.ServerInterceptor` for Cross-Cutting Server Concerns** `[Python]` `[gRPC]`
     Subclass `grpc.aio.ServerInterceptor` for auth, structured logging (method name, status code, latency), metrics, and rate limiting. Implement `async def intercept(self, continuation, call_details)`. Do not inline these in servicer handlers.

197. **Client Channels Inside `async with` Blocks** `[Python]` `[gRPC]`
     All gRPC channels (`grpc.aio.secure_channel()` or `grpc.aio.insecure_channel()`) are managed in `async with` blocks. Never use synchronous channel constructors in async code. Never leave a channel open past its logical scope.

198. **Catch `grpc.aio.AioRpcError` at Service Boundaries** `[Python]` `[gRPC]`
     Catch `grpc.aio.AioRpcError` at the service or repository implementation. Inspect `.code()` and `.details()`. Map to domain exceptions before rethrowing. `AioRpcError` must not propagate into domain or business logic layers.

199. **Handle `asyncio.CancelledError` in Streaming Handlers** `[Python]` `[gRPC]`
     Streaming handlers that allocate resources must catch `asyncio.CancelledError`, release resources, and re-raise. Swallowing `CancelledError` prevents cooperative cancellation and leaks resources.

200. **Pin `grpcio`, `grpcio-tools`, `grpcio-status`, `grpcio-reflection` to the Same Version** `[Python]` `[gRPC]`
     These four packages must be pinned to identical versions in `pyproject.toml`. Version drift between them causes silent code-generation mismatches and runtime errors that are difficult to diagnose.

---

## 21. Proto Scaffold and Code Generation (buf)

*The `proto/` directory at the repo root is the source of truth for all first-party service contracts. `buf` manages linting, breaking-change detection, and code generation.*

201. **`proto/buf.yaml` — Lint and Breaking-Change Configuration** `[Proto3]`
     Every repo with first-party gRPC has a `proto/buf.yaml` using `version: v2`, `lint.use: [STANDARD]`, and `breaking.use: [FILE]`. Commit this file alongside the `.proto` files.

202. **`proto/buf.gen.yaml` — Code Generation Configuration** `[Proto3]` `[gRPC]`
     `buf.gen.yaml` specifies all code generation plugins. Swift (grpc-swift-2): `local: protoc-gen-swift` + `local: protoc-gen-grpc-swift` with `Client=true, Server=false`. Python (grpc.aio): `remote: buf.build/protocolbuffers/python` + `remote: buf.build/grpc/python` + `remote: buf.build/protocolbuffers/pyi`. Commit this file alongside `buf.yaml`.

203. **`proto/common/v1/common.proto` — Shared Message Types** `[Proto3]`
     Shared reusable messages (`PageRequest`, `PageResponse`, `AuditInfo`) live in `common/v1/common.proto`. Service `.proto` files import this file. Do not duplicate pagination or audit fields in individual service files.

204. **Generated Code Goes to Dedicated, Gitignored Directories** `[Proto3]` `[gRPC]`
     Swift generated code: `generated/swift/`. Python generated code: `server/src/generated/`. Both directories are in `.gitignore`. Run `scripts/proto-gen.sh` to regenerate after schema changes. Never commit generated code unless explicitly required for deployment and a drift-detection check exists.

205. **`scripts/proto-gen.sh` — Single Command for All Code Generation** `[General]`
     The repo provides `scripts/proto-gen.sh` that: verifies prerequisites (buf CLI, language-specific plugins), runs `buf lint`, runs `buf generate`, creates output directories, and reports results. One script runs the full generate cycle.

206. **`buf breaking` Before Every Schema Merge** `[Proto3]`
     Run `buf breaking --against .git#branch=main` (or the stable branch) before merging any `.proto` change. Breaking changes require a package version bump (`v1` → `v2`). This is enforced in the pre-merge checklist and, eventually, in CI.

---

## 18. Agent Phase Routing

*Which AI coding agent system to use for each engineering phase.*

Both Claude Code and Codex can perform any phase. The assignments below identify the default (better-suited) system per phase. Override when task characteristics favor the other system. When capability is equal, Claude Code is the default.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | `ios-architect` or `planner` | Multi-file context, extended reasoning |
| API and schema design | **Claude Code** | `grpc-schema` | Schema tools, buf integration |
| Planning / task breakdown | **Claude Code** | `planner` | Tiebreaker — both systems comparable |
| Dependency evaluation | **Claude Code** | `docs-researcher` | Web search, nuanced tradeoff analysis |
| Implementation | **Codex** | `coder` | workspace-write sandbox, strong code generation |
| Code review | **Claude Code** | `reviewer` | Deep multi-file analysis, Bash diagnostics |
| Testing | **Codex** | `tester` | Pattern generation, approval flow for new test files |
| Debugging | **Claude Code** | `coder` | Multi-step reasoning, Bash for live diagnostics |
| Refactoring | **Codex** | `coder` | Mechanical changes in workspace-write sandbox |
| Documentation | **Claude Code** | `docs-researcher` | Tiebreaker — multi-file context aids consistency |
| Repo operations | **Codex** | `repo-ops` | workspace-write sandbox, scripting strength |
| Local validation | **Codex** | `repo-ops` | workspace-write sandbox; can execute scripts |

Invoke a specific agent:
- Claude Code: `claude --agent grpc-schema`
- Codex: `codex --agent coder`

---

*Last updated: 2026-03 (v3). Targets Swift 6, Xcode 26.3, Python 3.12+, grpc-swift-2 (Swift Concurrency-native), grpcio 1.6x+ (grpc.aio), buf CLI v2, App Store distribution. gRPC + Proto3 applies to all first-party client/server communication; third-party integrations use their native protocols. Item count: 206 items + phase routing table (§18).*
