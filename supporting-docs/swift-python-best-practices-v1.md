# Swift 6 / Python Best Practices Reference
### For CLAUDE.md / AGENTS.md — iOS, iPadOS, macOS, Python Server

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
   Every piece of knowledge has a single authoritative representation. Duplication of logic (not just code) is the target.

7. **YAGNI — You Aren't Gonna Need It** `[General]`  
   Never build a feature speculatively. Build for current requirements; extend when the need is real. Critical for MVP discipline.

8. **KISS — Keep It Simple** `[General]`  
   Prefer the simplest correct solution. Clever code is a liability. Simple code is easier to test, debug, and hand off to an AI agent.

9. **Composition Over Inheritance** `[General]`  
   Build complex behavior by composing simple components rather than deep class hierarchies. Inheritance couples tightly; composition is flexible.

10. **Principle of Least Privilege** `[General]`  
    Every component (code module, API scope, OS permission) should request and use only the minimum access it needs.

11. **Fail Fast** `[General]`  
    Detect and report errors as close to the source as possible. Guard clauses, preconditions, and early returns over deeply nested conditionals.

12. **Separation of Concerns** `[General]`  
    Distinct concerns (networking, persistence, business logic, presentation) live in distinct layers. No layer reaches past its immediate neighbor.

---

## 3. Architectural Patterns *(Descriptive — choose per project)*

13. **MVVM (Model-View-ViewModel)** `[SwiftUI]`  
    Best fit for SwiftUI-primary apps. View observes ViewModel; ViewModel transforms domain models into view state. No business logic in View. ViewModel is not aware of any specific View type.

14. **MVC (Model-View-Controller)** `[UIKit/AppKit]`  
    The native UIKit/AppKit pattern. Valid when UIKit components dominate. *Anti-pattern: Massive View Controller* — see §11.

15. **The Composable Architecture (TCA)** `[Apple]`  
    Unidirectional data flow (Action → Reducer → State → View). Highly testable; steep learning curve. Best for complex, deeply stateful apps. Use the `@Reducer` macro (TCA 1.x).

16. **VIPER** `[Apple]`  
    View-Interactor-Presenter-Entity-Router. Maximum separation of concerns; highest verbosity. Best for large team projects with strict module ownership. Likely over-engineered for solo/small team work.

17. **Clean Architecture (Layered)** `[General]`  
    Three concentric layers: Presentation → Domain (Use Cases + Entities) → Data (Repositories + Sources). The innermost Domain layer has zero dependencies on outer layers. Works symmetrically for both Swift and Python.

18. **Coordinator Pattern** `[UIKit/AppKit]`  
    Separates navigation logic from ViewControllers. Each Coordinator owns a navigation flow. In SwiftUI, `NavigationStack` + typed NavigationPath reduces the need, but Coordinators remain useful for complex branching flows.

19. **Module-Based / Feature-Based Architecture** `[Apple]`  
    Divide the app into independently compilable Swift packages (local or remote). Enforces dependency boundaries, reduces build times, enables parallel development.

20. **Service Layer** `[General]`  
    Stateless service objects encapsulate business logic. Services depend on Repository abstractions, not concrete data sources. One service per bounded domain context.

21. **Repository Pattern** `[General]`  
    Abstracts data sources (remote API, local DB, cache) behind a unified interface. Business logic never calls URLSession, CoreData, or SQLAlchemy directly. Enables seamless swapping of persistence mechanisms.

---

## 4. Design Patterns

22. **Builder Pattern** `[General]`  
    Construct complex objects step-by-step through a fluent interface. Pairs naturally with the immutability rule — use a mutable `Builder` type to configure, then produce a final immutable product.

23. **Factory Method / Abstract Factory** `[General]`  
    Create objects without specifying the exact class at the call site. Use for platform-specific implementations (e.g., different persistence backends per platform) and for test double injection.

24. **Dependency Injection (Constructor Injection preferred)** `[General]`  
    Pass all dependencies into a type's initializer. Property injection is a fallback; method injection for contextual dependencies. Never use a type's initializer to create its own dependencies.

25. **Strategy Pattern** `[General]`  
    Encapsulate interchangeable algorithms behind a common protocol/interface. Use for swappable serialization formats, authentication strategies, data source selection, and ML inference backends.

26. **Observer Pattern** `[General]`  
    Decouple event producers from consumers. In Swift: `@Observable`, Combine publishers, NotificationCenter (last resort). In Python: callback registries, event emitters, or pub/sub (Redis, RabbitMQ).

27. **State Pattern / State Machine** `[General]`  
    Model explicit states as an enum with associated values rather than boolean flag combinations. A type can only be in one state at a time; transitions are explicit and exhaustive.

28. **Command Pattern** `[General]`  
    Encapsulate an operation as an object. Enables undo/redo, queuing, and audit logging. Natural fit for user actions in document-based apps and for async job queues in Python.

29. **Decorator Pattern** `[General]`  
    Add behavior to an object without modifying its class. In Python: use `@decorator` syntax. In Swift: use protocol extensions or wrapper `struct` types conforming to the same protocol as the wrapped type.

30. **Adapter Pattern** `[General]`  
    Convert the interface of one type to the interface expected by another. Critical at API response → domain model boundaries and at Swift/Python schema boundaries.

31. **Facade Pattern** `[General]`  
    Provide a simplified interface to a complex subsystem. Use to wrap third-party SDKs, complex internal modules, or multi-step workflows behind a single clean entry point.

32. **Proxy Pattern** `[General]`  
    Control access to an object. Use for lazy loading, caching, access control, and logging without modifying the underlying type.

33. **Chain of Responsibility** `[General]`  
    Pass a request along a chain of handlers until one processes it. Natural pattern for Python middleware (FastAPI/Starlette middleware), AppKit event responder chains, and multi-stage validation pipelines.

34. **Template Method** `[General]`  
    Define the skeleton of an algorithm in a base type; subclasses/conformers fill in the steps. Use when multiple types share a common process with varying steps.

---

## 5. Swift / Apple-Specific Patterns

35. **Protocol-Oriented Programming (POP)** `[Swift]`  
    Prefer protocols and protocol extensions over class inheritance. Enables composition of behavior across unrelated types. Default implementations in extensions provide opt-in behavior without forcing inheritance.

36. **Value Type-First Design** `[Swift]`  
    Default to `struct` for all model and data types. Use `class` only when reference semantics, identity equality, or Objective-C interop is explicitly required. Structs assigned to `let` are implicitly immutable.

37. **`@Observable` for View Models** `[SwiftUI]`  
    Use the `@Observable` macro (iOS 17+/macOS 14+) for all new ViewModel types. Prefer over `ObservableObject` + `@Published` for new code. Coexist with legacy `ObservableObject` types.

38. **`@MainActor` for UI-Bound Types** `[Swift]`  
    Annotate ViewModels and any type that updates UI state with `@MainActor`. This makes the compiler enforce main-thread access rather than relying on runtime discipline.

39. **Actor Isolation for Shared Mutable State** `[Swift]`  
    Use `actor` types for any shared mutable state accessed concurrently. Never share mutable state across actor boundaries without `Sendable`-conforming types.

40. **`Sendable` Discipline** `[Swift]`  
    All types crossing actor or task boundaries must conform to `Sendable`. Value types (`struct`, `enum`) with `Sendable` stored properties are implicitly `Sendable`. Reference types require explicit conformance or `@unchecked Sendable` with a documented justification.

41. **Structured Concurrency** `[Swift]`  
    Use `async let`, `TaskGroup`, and `withThrowingTaskGroup` for child tasks. Use `withTaskCancellationHandler` to clean up on cancellation. Avoid unstructured `Task { }` detachments except at top-level entry points (e.g., button actions).

42. **Typed Throws (Swift 6)** `[Swift]`  
    Use `throws(SpecificErrorType)` for functions where the error type is known. Eliminates the need for callers to cast or handle `any Error` when the domain error is predictable.

43. **`@frozen` Enums** `[Swift]`  
    Mark enums `@frozen` when their case set is guaranteed stable across module updates (e.g., in a published framework). Enables exhaustive `switch` without `@unknown default`. Do not use in apps — only frameworks.

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
    All custom classes and objects are immutable by default. Any class requiring mutable state must be a subclass of an immutable parent class. The parent class defines the interface; the subclass adds only mutable properties, never removes invariants (LSP applies).

50. **Frozen Python Dataclasses for Domain Models** `[Python]`  
    Use `@dataclass(frozen=True)` for all domain model / value object types in Python. This mirrors the Swift immutability requirement and prevents accidental mutation in service layers.

51. **Immutable API Response Models** `[General]`  
    Deserialize all API responses into immutable model objects immediately at the network boundary. Any transformation to a mutable working representation is a deliberate, named, explicit step — not an in-place mutation.

52. **Copy-on-Write Semantics for Custom Value Types** `[Swift]`  
    For custom value types that wrap a reference type internally, implement CoW manually using `isKnownUniquelyReferenced`. Swift's standard collections do this automatically; custom types must not assume they inherit it.

53. **`let`-Bound Constants for Configuration** `[General]`  
    All configuration constants are `let`-bound (Swift) or `Final` class attributes / module-level constants (Python). Never use global mutable config variables.

---

## 7. Concurrency

54. **`async`/`await` First** `[Swift]` `[Python]`  
    Prefer `async`/`await` over callback-based APIs, completion handlers, and (in Swift) Combine, for new code. Clearer control flow, better error propagation, and cooperative task cancellation.

55. **Never Block the Main Thread** `[Apple]`  
    I/O, heavy computation, and synchronous network calls are never performed on the main thread. Use `await` on background actors or `Task.detached(priority: .background)` for CPU-bound work.

56. **Propagate Cancellation** `[Swift]` `[Python]`  
    Long-running async tasks check `Task.isCancelled` at each suspension point (Swift) or handle `asyncio.CancelledError` without swallowing it (Python). Cancellation is a first-class operation, not an afterthought.

57. **Coexist Combine + async/await** `[Swift]`  
    Combine remains valid for complex reactive pipelines (debounce, merge, map chains). Use `AsyncSequence`/`AsyncStream` as the bridge between async/await code and Combine publishers. Do not rewrite working Combine pipelines unnecessarily.

58. **Python asyncio for I/O-Bound Work** `[Python]`  
    All I/O-bound operations (DB queries, outbound HTTP, file I/O) use `async def`. CPU-bound operations (ML inference, data processing) are offloaded via `asyncio.run_in_executor` with a `ProcessPoolExecutor`.

59. **Background Task Scheduling** `[iOS/iPadOS]`  
    Use `BGTaskScheduler` (`BGAppRefreshTask`, `BGProcessingTask`) for background work. Respect system scheduling constraints. Register all tasks in `Info.plist`. Never rely on undocumented background execution time.

---

## 8. Error Handling

60. **Domain-Specific Typed Error Enums** `[General]`  
    Define one error enum per domain layer (e.g., `NetworkError`, `PersistenceError`, `AuthError`). Each case carries associated values providing context. Layer boundaries wrap and re-throw with added context.

61. **Never Swallow Errors** `[General]`  
    Every `catch` block must handle, log, or rethrow. An empty `catch {}` block is a build warning at minimum, a code review failure at maximum.

62. **`Result<Success, Failure>` for Storable Errors** `[Swift]`  
    Use `Result` when an error must be stored, passed as a value, or returned from a non-throwing synchronous context. Use `throws` for propagation, `Result` for storage.

63. **HTTP Error Mapping at the Network Boundary** `[General]`  
    HTTP status codes are translated into typed domain errors at the network layer before entering business logic. Business logic never inspects raw HTTP status codes.

64. **Python Exception Hierarchy** `[Python]`  
    Define custom exceptions inheriting from appropriate stdlib base exceptions (`ValueError`, `RuntimeError`, `IOError`). Never use bare `except:` or `except Exception:` without re-raising or structured logging.

65. **Exponential Backoff with Jitter for Retries** `[General]`  
    Retry transient failures with exponential backoff and random jitter. Never retry immediately in a tight loop. Cap maximum retry count and maximum delay. Make retry behavior configurable.

---

## 9. Security

66. **Keychain for All Sensitive Credentials** `[Apple]`  
    Tokens, passwords, private keys, and sensitive identifiers are stored in the Keychain. Never in `UserDefaults`, `NSUserDefaults`, `AppStorage`, plist files, or the filesystem.

67. **No Hardcoded Secrets** `[General]`  
    No API keys, secrets, tokens, or credentials appear in source code, plist files, or asset catalogs. Swift: use Keychain + server-vended tokens. Python: use environment variables + a secrets manager (AWS Secrets Manager, HashiCorp Vault, or `.env` + `pydantic-settings` for local dev only).

68. **Certificate Pinning for Sensitive APIs** `[iOS/iPadOS]`  
    Implement TLS certificate / public key pinning for APIs handling sensitive data. Use `URLSession` with a custom `URLSessionDelegate` implementing `urlSession(_:didReceive:completionHandler:)`. Document pinned certificates and the rotation procedure.

69. **App Transport Security (ATS) — Never Globally Disabled** `[Apple]`  
    `NSAllowsArbitraryLoads` is never set to `true` globally. Any ATS exceptions are scoped to specific domains, documented in code comments, and justified in the App Store review notes.

70. **Input Validation at Every Trust Boundary** `[General]`  
    All external input (user input, API responses, deep link parameters, URL scheme payloads) is validated before processing. In Python: Pydantic v2 validators. In Swift: validate before binding to models.

71. **SQL Injection Prevention** `[Python]`  
    Always use parameterized queries or ORM query builders. User input is never interpolated into SQL strings. `text()` constructs in SQLAlchemy require explicit `bindparams`.

72. **JWT/OAuth 2.0 Best Practices** `[General]`  
    Use short-lived access tokens (≤15 min) with refresh token rotation. Validate all claims (`exp`, `iss`, `aud`, `sub`) server-side on every request. Revoke refresh tokens on logout.

73. **Privacy Manifests** `[Apple]`  
    Every App Store submission includes a `PrivacyInfo.xcprivacy` manifest declaring all accessed required reason APIs (`NSPrivacyAccessedAPITypes`) and all third-party SDK data practices. This is an App Store requirement (enforced since May 2024).

74. **Minimum Permissions** `[Apple]`  
    Request location, camera, microphone, contacts, and other sensitive permissions only at the moment of first use, with a clear purpose string explaining the need. Never pre-request permissions at launch.

75. **Biometric Authentication** `[Apple]`  
    Use the `LocalAuthentication` framework for Face ID / Touch ID. Always provide a fallback to passcode. Handle `LAError` cases explicitly (denied, biometryLockout, etc.).

76. **Rate Limiting on All Endpoints** `[Python]`  
    Implement server-side rate limiting on all public and authenticated API endpoints. Use token bucket or sliding window algorithms. Return `429 Too Many Requests` with `Retry-After` headers.

77. **CORS — Explicit and Restrictive** `[Python]`  
    Configure CORS with an explicit allowlist of origins. Never use wildcard `*` in production. Separate CORS configurations for public and credentialed endpoints.

78. **Dependency Vulnerability Scanning** `[General]`  
    Regularly scan third-party dependencies: `swift package update` + review changelogs (Swift); `pip-audit` or `safety` (Python). Block known-vulnerable versions in CI when CI is adopted.

79. **Sandboxing and Entitlements** `[Apple]`  
    App Sandbox is enabled. Entitlements are the minimum required set. No entitlements are added "just in case." Each entitlement is justified in comments.

80. **Secure Coding — Avoid `unsafe`** `[Swift]`  
    Use of `unsafe` APIs (`UnsafePointer`, `withUnsafeBytes`, etc.) is minimized, isolated to clearly named wrapper functions, and accompanied by a comment explaining the safety invariant being manually maintained. Swift 6 strict concurrency eliminates data races — do not use `@unchecked Sendable` to silence warnings without ensuring actual thread safety.

---

## 10. Networking & API Design

81. **Network Layer Behind a Protocol** `[General]`  
    All network calls are made through a protocol-typed client abstraction. ViewModels and services depend on the protocol, never on `URLSession` or a specific HTTP library directly.

82. **Request/Response DTO Separation** `[General]`  
    Use separate Data Transfer Object types for network serialization. DTOs are mapped to/from domain models at the network boundary. Domain models are never used as DTOs.

83. **`Codable` / `Decodable` Discipline** `[Swift]`  
    All network model types conform to `Codable`. JSON field names are decoupled from Swift property names via `CodingKeys` enums. Date decoding strategies are set explicitly on the `JSONDecoder`.

84. **Pydantic v2 for Python API Models** `[Python]`  
    All API request/response models are Pydantic `BaseModel` subclasses. Use `model_validator` for cross-field validation. `model_config = ConfigDict(frozen=True)` for response models.

85. **OpenAPI as Shared Schema Source of Truth** `[General]`  
    For shared Swift/Python models, an OpenAPI 3.x spec is the authoritative definition. Client models (Swift) and server models (Python) are either generated from or validated against this spec. Drift between the two sides is a build error, not a runtime surprise.

86. **ISO 8601 / RFC 3339 for All Dates** `[General]`  
    Dates and timestamps in APIs are always ISO 8601 strings in UTC. Local time conversion happens only at the presentation layer. Never pass Unix timestamps without documented time zone context.

87. **Cursor-Based Pagination** `[General]`  
    List endpoints use cursor-based pagination for datasets that change frequently. Offset-based pagination is acceptable only for small, stable datasets. Page size is bounded server-side.

88. **API Versioning from Day One** `[Python]`  
    All API routes include a version prefix (`/api/v1/`). Breaking changes are introduced in new versions, never applied to existing versioned endpoints.

89. **Idempotency Keys for Mutating Operations** `[General]`  
    Non-idempotent POST operations (creating orders, initiating payments) accept a client-generated idempotency key. The server deduplicates using this key for a defined window.

90. **Offline-First / Optimistic Updates** `[iOS/iPadOS]`  
    Where UX requires it, update local state optimistically before server confirmation. Roll back on server error. The local cache is the source of truth for display; sync status is surfaced to the user.

---

## 11. Data Persistence

91. **Repository Pattern for All Persistence** `[General]`  
    Business logic accesses data exclusively through Repository interfaces. No View, ViewModel, or Service directly calls CoreData, SwiftData, SQLAlchemy, or any raw DB API.

92. **SwiftData / Core Data on `@MainActor`** `[Apple]`  
    The view context / `ModelContext` is accessed only on the main thread/actor. Background operations use a dedicated background context created with `newBackgroundContext()` or in a `ModelActor`.

93. **Plan Migrations from Day One** `[General]`  
    Define a migration strategy before writing the first schema. In Swift: use lightweight migration for minor changes; write custom migration policies for destructive changes. In Python: use Alembic (SQLAlchemy) or the framework's built-in migration tool. Never drop and recreate in production.

94. **No Raw SQL in Application Code** `[Python]`  
    All database interactions use an ORM or query builder. Raw SQL is isolated in explicitly named `_raw_query` methods with a comment explaining why the ORM is insufficient.

95. **Explicit Cache Invalidation Strategy** `[General]`  
    Every cache has a documented TTL and explicit invalidation trigger(s). Cache invalidation logic lives alongside the cache implementation, not scattered across callers.

---

## 12. Testing

96. **Test Pyramid Discipline** `[General]`  
    Many unit tests > fewer integration tests > fewest UI tests. UI tests cover only critical, high-value user flows. Fast tests run in CI; slow tests are gated.

97. **Protocol-Based Mocking (Swift)** `[Swift]`  
    All injected dependencies are typed as protocols. Test doubles implement the protocol. Avoid third-party mocking frameworks when protocol conformance suffices.

98. **Swift Testing Framework (`@Test`, `#expect`)** `[Swift]`  
    Use the Swift Testing framework for all new test code. Coexist with legacy XCTest suites without rewriting them.

99. **`pytest` with `pytest-asyncio`** `[Python]`  
    Use `pytest` as the standard test runner. Use `pytest-asyncio` for async tests. Use fixtures over `setUp`/`tearDown`. Use `pytest-cov` for coverage reporting.

100. **Deterministic Tests** `[General]`  
     Tests never depend on real system time, random seeds, or live network calls. Inject a `Clock` protocol (Swift) or mock `datetime.now` (Python). Mock all network calls.

101. **Test Naming Convention** `[General]`  
     Swift: `testWhenConditionThenExpectedOutcome()`. Python: `test_<what>_<condition>_<expected_outcome>`. Test names are self-documenting failure messages.

102. **Contract Testing for Shared APIs** `[General]`  
     When Swift and Python share an API schema, write contract tests that verify both sides agree on field names, types, and nullable semantics. Consumer-driven contract testing (e.g., Pact) is preferred over manual mirroring.

103. **Snapshot Testing for UI** `[SwiftUI]` `[UIKit/AppKit]`  
     Use snapshot tests for complex UI components to catch unintended visual regressions. Snapshots are committed to source control and reviewed in PRs.

104. **Test Double Hierarchy** `[General]`  
     Use the simplest test double that satisfies the test: Dummy → Stub → Fake → Spy → Mock. Overuse of full mocks indicates a design problem (too many dependencies).

---

## 13. Shared Schema / Swift–Python Interoperability

105. **OpenAPI Spec as Single Source of Truth** `[General]`  
     *See item 85.* The OpenAPI spec is authored first ("spec-first" development). Code is generated from or validated against it. The spec lives in a shared repository location accessible to both Swift and Python tooling.

106. **Versioned Codable Models** `[Swift]`  
     When API response shapes change, maintain versioned `Decodable` implementations to support backward compatibility during rolling deployments. Use a `version` field in responses to select the correct decoder.

107. **Explicit Null Semantics** `[General]`  
     Define and document whether a missing field (key absent) and a null field (`null` / `nil`) have different meanings in your API contract. This must be consistent across the OpenAPI spec, Pydantic models, and Swift `Decodable` types.

108. **Consistent Error Envelope** `[General]`  
     All API error responses use a consistent JSON envelope: `{ "error": { "code": "...", "message": "...", "details": {...} } }`. Both Pydantic (Python) and a Swift `Decodable` type model this envelope identically.

---

## 14. Apple Platform-Specific Concerns

109. **Scene-Based Lifecycle** `[Apple]`  
     Use `UISceneDelegate` (UIKit) or SwiftUI's `App` / `Scene` protocol for lifecycle management. The `UIApplicationDelegate` handles only app-wide concerns (push notification registration, background URL session handling).

110. **Adaptive Layouts with Size Classes** `[iOS/iPadOS]`  
     Build adaptive UIs using `@Environment(\.horizontalSizeClass)`, `@Environment(\.verticalSizeClass)`, and `GeometryReader`. Avoid hardcoded point dimensions.

111. **iPad Multitasking Support** `[iPadOS]`  
     Support Split View and Slide Over from the start. Test all multitasking configurations. Avoid fixed-width layouts. Use `UISplitViewController` or SwiftUI `NavigationSplitView` for two/three-column layouts.

112. **macOS Menu Bar and Keyboard Shortcuts** `[macOS]`  
     Provide complete menu bar integration using `CommandMenu` (SwiftUI) or `NSMenu` (AppKit). All primary actions have keyboard shortcuts. Mac users rely on keyboard-driven navigation.

113. **Mac Catalyst — Handle `UIUserInterfaceIdiom.mac`** `[macOS]`  
     When shipping via Catalyst, explicitly detect and handle `.mac` idiom for Mac-specific behaviors. Optimize the toolbar, remove touch-specific controls, and adopt `NSToolbar` via `UIWindowScene.titlebar`.

114. **Universal Links and Deep Linking** `[Apple]`  
     Implement Universal Links (HTTPS-based) for all navigable content. Register URL schemes for app-specific protocol handling. Test all deep link paths including cold-start launch.

115. **Dynamic Type Support** `[Apple]`  
     All text uses Dynamic Type. In SwiftUI: use named text styles (`.body`, `.headline`). In UIKit: use `UIFontMetrics` for custom fonts. Test at all accessibility text sizes including the five extra-large sizes.

116. **VoiceOver and Accessibility** `[Apple]`  
     All interactive elements have `accessibilityLabel`, `accessibilityHint` (when non-obvious), and `accessibilityValue` (for stateful controls). Use `accessibilityElement(children: .combine)` for compound elements. Audit with the Accessibility Inspector.

117. **Dark Mode via Semantic Colors** `[Apple]`  
     Use semantic color names (`Color(.label)`, `Color(.systemBackground)`, asset catalog adaptive color sets) exclusively. No hardcoded hex or RGB values in production UI code.

118. **App Lifecycle State Handling** `[iOS/iPadOS]`  
     Handle `sceneDidEnterBackground` (save state, cancel non-essential work), `sceneWillResignActive` (pause animations, hide sensitive data), and `sceneWillEnterForeground` (refresh stale data, resume).

119. **Memory Warning Handling** `[iOS/iPadOS]`  
     Implement `didReceiveMemoryWarning` and `applicationDidReceiveMemoryWarning`. Clear image caches, evict non-critical data, and cancel low-priority background tasks.

---

## 15. Python Server-Specific

120. **Type Annotations Everywhere** `[Python]`  
     All function signatures, class attributes, and module-level variables have type annotations. Enforced with `mypy` in strict mode (`--strict`). No `Any` without a `# type: ignore` comment explaining the exception.

121. **Dependency Injection via Constructors** `[Python]`  
     Avoid module-level global state. Inject database sessions, HTTP clients, and configuration via class constructors or function parameters. Use FastAPI's `Depends()` system or equivalent for request-scoped injection.

122. **Async Context Managers for Resources** `[Python]`  
     Database connections, HTTP client sessions, and file handles are managed with `async with`. Resources are never leaked. Connection pools are sized and monitored.

123. **Pydantic Settings for Configuration** `[Python]`  
     Use `pydantic-settings` for all application configuration. Configuration is loaded from environment variables with type validation and documented defaults. No `os.environ.get()` scattered through application code.

124. **Structured Logging** `[Python]`  
     Use `structlog` or the stdlib `logging` module with a JSON formatter. Log entries include `request_id`, `user_id` (where applicable), and structured context fields. Never use `print()`. Log levels are respected: `DEBUG` for development, `INFO` for production events, `WARNING`/`ERROR` for actionable issues.

125. **Background Task Idempotency** `[Python]`  
     All Celery / ARQ / RQ tasks are idempotent by design. Use task-level idempotency keys. Implement dead-letter queues for failed tasks. Set explicit retry limits and retry backoff. Never fire-and-forget without error handling.

126. **WebSocket Connection State Management** `[Python]`  
     Track WebSocket connection state explicitly (connecting, connected, disconnecting, disconnected). Implement heartbeat/ping-pong to detect stale connections. Handle disconnection and reconnection gracefully without leaking connection objects.

127. **ML Model Versioning** `[Python]`  
     ML models are versioned explicitly (semantic version or content hash), never referenced as "latest." Use a model registry (MLflow, Weights & Biases) or version-tagged artifact paths. Model loading is isolated to a dedicated `ModelRegistry` service.

128. **Inference Isolated from Business Logic** `[Python]`  
     ML inference code (model loading, preprocessing, prediction, postprocessing) lives in a dedicated service class, not in route handlers or business logic. This enables independent testing, versioning, and scaling of the inference layer.

129. **Data Pipeline Idempotency** `[Python]`  
     Each stage of a data pipeline is idempotent — running a stage twice on the same input produces the same output. Stages are independently restartable from checkpoints. Critical for recovery from partial failures.

130. **Virtual Environment and Pinned Dependencies** `[Python]`  
     Always develop inside a virtual environment (`venv`, `conda`, or `uv`). All direct AND transitive dependencies are pinned. Use `pyproject.toml` + a lockfile (`uv.lock`, `poetry.lock`). The lockfile is committed to source control.

131. **`__all__` for Public Module API** `[Python]`  
     Define `__all__` in every module to explicitly declare its public interface. Prevents accidental exposure of private implementation details to `from module import *` consumers.

132. **N+1 Query Prevention** `[Python]`  
     ORM queries for collections use eager loading (`joinedload`, `selectinload` in SQLAlchemy; `select_related`/`prefetch_related` in Django ORM). Every new query path is reviewed for N+1 patterns before merging.

---

## 16. Anti-Patterns to Avoid

133. **Massive View Controller** `[UIKit/AppKit]`  
     View Controllers containing data fetching, business logic, persistence, and navigation. Violates SRP. Use Coordinators for navigation, ViewModels for state, and Services/Repositories for data.

134. **God ViewModel** `[SwiftUI]`  
     ViewModels managing multiple unrelated features or the entire screen's state in a single class. Split by feature or use case. A ViewModel serves one logical view unit.

135. **God Object** `[General]`  
     A class that knows too much or does too much. If a type has more than 7–10 public methods or more than 5 dependencies, it is a candidate for decomposition.

136. **Stringly-Typed Code** `[General]`  
     Using raw strings for keys, identifiers, state values, and notification names. Replace with enums, typed constants, and `RawRepresentable` types. Compiler-checked identifiers eliminate an entire class of runtime bugs.

137. **Force Unwrapping** `[Swift]`  
     Using `!` to force-unwrap optionals in production code. Use `guard let`, `if let`, `??`, or `preconditionFailure`/`fatalError` with an explanatory message for programmer-error cases. Any force-unwrap requires a code comment explaining why nil is impossible.

138. **Implicitly Unwrapped Optionals (IUOs)** `[Swift]`  
     Declaring `var property: Type!` except for `@IBOutlet` and cases where Swift's two-phase initialization requires it. IUOs in non-IB code almost always indicate a design flaw.

139. **`print()` for Logging** `[General]`  
     Using `print()` (Swift) or `print()`/bare `logging` calls (Python) for production diagnostics. Use `os.Logger` / `OSLog` in Swift; `structlog` or configured `logging` in Python.

140. **Singleton Abuse** `[General]`  
     Using singletons as a substitute for dependency injection. Singletons create hidden coupling, make testing difficult, and complicate multi-window / multi-scene scenarios. Use DI; a DI container can manage a single shared instance without making it a global.

141. **Retain Cycles** `[Swift]`  
     Closures that capture `self` strongly in a class that retains the closure. Always use `[weak self]` in escaping closures in classes. Use `[unowned self]` only when the closure's lifetime is provably shorter than `self`.

142. **`@unchecked Sendable` Without Justification** `[Swift]`  
     Using `@unchecked Sendable` to silence Swift 6 concurrency warnings without ensuring actual thread safety. Every use of `@unchecked Sendable` requires a comment explaining the manual invariant being maintained.

143. **Blocking Async Context** `[Swift]` `[Python]`  
     Calling synchronous blocking code (long computation, synchronous I/O) from within an `async` function, starving the cooperative thread pool. Offload to a detached task or `run_in_executor`.

144. **`DispatchQueue.main.async` When Already on Main** `[Swift]`  
     Unnecessarily wrapping already-main-thread code creates scheduling overhead and ordering confusion. Use `@MainActor` annotations at the type or function level instead.

145. **Mutable Global State** `[General]`  
     Global variables mutated at runtime. In Swift 6: the compiler flags these as concurrency errors. In Python: use module-level constants only; pass mutable state through DI.

146. **`Any` / `AnyObject` Overuse** `[Swift]`  
     Type-erasing with `Any` destroys compile-time safety. Use generics or typed existentials (`any Protocol`) instead. If `Any` is necessary, it lives at a named boundary with explicit casting.

147. **Exception-Driven Control Flow** `[Python]`  
     Using exceptions for normal, expected conditions (not errors). Exceptions are for exceptional conditions. Use return values, `Optional`, or `Result`-equivalent types for expected failure paths.

148. **N+1 Queries** `[Python]`  
     *See item 132.* Loading a collection and then issuing one query per item in a loop. Always caught in code review; always fixed before merge.

149. **Direct CoreData/SwiftData Access in Views** `[Apple]`  
     SwiftUI Views or UIViewControllers directly accessing `NSManagedObjectContext` or `ModelContext` for data mutations. All persistence goes through ViewModels or Repositories.

150. **Premature Optimization** `[General]`  
     Optimizing code before profiling. Use Instruments (Apple: Time Profiler, Allocations, Core Data) or `cProfile`/`py-spy` (Python) to identify actual bottlenecks. Write correct, clear code first.

151. **Magic Numbers and Strings** `[General]`  
     Unexplained numeric literals or raw string values embedded in logic. All magic values are replaced with named constants or enum cases with documentation.

152. **Not Handling Background/Foreground Transitions** `[iOS/iPadOS]`  
     Apps that ignore `sceneDidEnterBackground` / `sceneWillEnterForeground` fail to save state, display stale data, and may violate App Store guidelines around data privacy (sensitive data visible in the app switcher).

153. **Anemic Domain Model** `[General]`  
     Domain objects that are pure data containers with no behavior, with all logic pushed into service classes. Evaluate whether the domain object should own its invariants. Appropriate for simple CRUD; often a missed encapsulation opportunity for complex domains.

---

*Last updated: 2026-03. Targets Swift 6, Xcode 26.x, Python 3.12+, App Store distribution.*
