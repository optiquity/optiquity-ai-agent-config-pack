---
name: grpc-patterns
description: Use for gRPC service patterns — servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics, and gRPC-side cross-language conventions.
allowed-tools: Read, Grep, Glob, Bash
---

## Companion skill — Proto3 schema rules

Proto3 schema-design rules — field numbering invariants, backward /
forward compatibility, well-known types, `oneof` semantics, code-
generation options, package conventions, `buf` tooling — live in
`protobuf-patterns`. Load `protobuf-patterns` alongside this skill
whenever a gRPC-using project also ships `.proto` files (which is
nearly always the case). The two skills are independent: standalone
protobuf consumers (binary file format, IPC, non-gRPC RPC frameworks)
load `protobuf-patterns` only; this skill carries no schema rules.

## Protobuf ↔ domain type mapping (transport boundary)

1. Generated Protobuf types are Data Transfer Objects at the gRPC transport boundary. They must not appear in domain-layer type signatures, in business logic, or in presentation-layer types (ViewModels, views, handlers, services).
2. Mapper code lives in the data layer alongside the repository implementation that uses it. Mappers are unidirectional at the boundary: generated → domain on inbound responses, domain → generated on outbound requests.
3. Recommended mapper patterns (choose one per language and apply consistently):
    - Swift: an extension on the domain type with an init accepting the generated type (`extension User { init(_ proto: User_Pb) throws }`), plus a reverse `func toProto() -> User_Pb` on the domain type for outbound requests.
    - Python: module-level mapper functions near the repository (`def user_from_proto(proto: user_pb2.User) -> User` and `def user_to_proto(user: User) -> user_pb2.User`).
4. Mappers validate incoming data. An incoming Protobuf message with invalid field values produces a typed domain error at the mapper, not an exception deeper in business logic.

## gRPC service / call rules

5. Verify auth tokens are NOT in message fields — they belong in call metadata.
6. Verify `google.rpc.Status` + error_details.proto is used for all error envelopes.
7. Never hand-edit generated gRPC stub code (Swift or Python). Schema-side rules for generated-code edits live in `protobuf-patterns`; the gRPC-specific rule applies to servicer / client stub code as well.

## grpc-swift-2 client rules (Swift)

8. Generated Swift code must use grpc-swift-2 async API. Verify generated files import `GRPCCore`.
9. After `buf generate`: confirm generated Swift message types conform to `Sendable`. Log any missing conformances.
10. Verify Swift client code catches `RPCError` (GRPCCore). Flag any `GRPCStatus` v1 references in new code.
11. All `CallOptions` must supply a `.timeout`. Flag call sites where timeout is omitted.
12. Verify gRPC stubs are not called from SwiftUI Views or ViewModels. Flag violations.
13. Verify channel is a single `GRPCClient` per scene lifecycle or uses `GRPCChannelPool`. Flag per-request channel creation.
14. Cancellation: Swift Task cancellation propagates automatically to the underlying gRPC call in grpc-swift-2. Explicit `call.cancel()` is not required for Task-scoped calls. For streaming calls, use `withTaskCancellationHandler` to release downstream resources (UI bindings, observers, caches) when the Swift Task is cancelled.

## Swift gRPC → domain error mapping

15. Catch `RPCError` at the repository implementation site. `RPCError` must never cross the repository or service boundary into business logic.
16. Map `RPCError.Code` to domain error cases using this standard mapping (rename domain types to match the project's error enum):
    - `.notFound` → `DomainError.notFound(id:)`
    - `.unauthenticated` → `AuthError.unauthenticated`
    - `.permissionDenied` → `AuthError.permissionDenied`
    - `.invalidArgument` → `ValidationError.invalidRequest(message:)`
    - `.unavailable`, `.deadlineExceeded` → `NetworkError.transient(code:message:)` — retry eligible
    - `.internal` → `NetworkError.serverError(message:)` — not retryable
17. Use `throws(DomainErrorType)` in repository protocols — callers handle typed domain errors, never `RPCError`.

## grpc.aio server rules (Python)

18. Verify generated Python servicers use `grpc.aio.server(...)`. Flag synchronous server usage.
19. Verify all servicer handler methods are `async def`. Flag synchronous handlers.
20. Verify handlers use `await context.abort(grpc.StatusCode.CODE, "detail string")` for error responses. Flag bare exception raises.
21. Use `grpcio-status` for rich error details: attach `google.rpc.Status` via `context.abort_with_status(grpcio_status.to_status(Status(...)))`.
22. Never let domain exceptions propagate from handlers unhandled — they become `INTERNAL` with no client-visible detail. Catch domain exceptions in the handler and map them to `grpc.StatusCode` + detail.
23. Verify `grpcio`, `grpcio-tools`, `grpcio-status`, `grpcio-reflection` are all pinned to the same version.
24. Verify server interceptors subclass `grpc.aio.ServerInterceptor`.
25. Verify `asyncio.CancelledError` is not swallowed in streaming handlers — clean up resources, then re-raise.

## Python gRPC → domain error mapping (client side)

26. Catch `grpc.aio.AioRpcError` at the service or repository implementation site. `AioRpcError` must never cross the repository boundary into business logic.
27. Map `error.code()` to domain exception classes using this standard mapping (rename domain types to match the project's error hierarchy):
    - `NOT_FOUND` → `NotFoundError(resource_type, id)`
    - `UNAUTHENTICATED` → `AuthenticationError(message)`
    - `PERMISSION_DENIED` → `AuthorizationError(message)`
    - `INVALID_ARGUMENT` → `ValidationError(message)`
    - `UNAVAILABLE`, `DEADLINE_EXCEEDED` → `TransientError(code, message)` — retry eligible
    - `INTERNAL` → `ServerError(message)` — not retryable
28. Repository methods raise typed domain exceptions from an error hierarchy rooted at a project-defined base class (e.g., `AppError(Exception)`).

## Cross-language conventions

29. Schema changes must be validated against both Swift and Python generated code before merging. *(Schema-side compatibility rules are in `protobuf-patterns`; this rule covers the gRPC code-gen verification step.)*
30. Breaking changes require coordinated client and server releases — document the rollout order.
31. Shared enums used by both client and server must have identical semantics in both languages. Document any behavioral differences in enum handling (e.g., unknown enum values).
32. Deadline propagation: client-set deadlines must be respected server-side. Server handlers should check remaining deadline before starting expensive operations.
33. Error detail types (google.rpc error_details) must be understood by both client and server. Do not use language-specific error detail extensions.
