---
name: grpc-patterns
description: Use for Protobuf schema design, gRPC service patterns, buf tooling, field evolution, and cross-language gRPC conventions.
allowed-tools: Read, Grep, Glob, Bash
---

## Proto3 schema rules

1. Verify every deleted or renamed field has a `reserved` entry for both the field number and name.
2. Verify proto3 field numbers have never been reused or renumbered.
3. Verify enum zero value is `*_UNSPECIFIED = 0` on every enum.
4. Verify `google.protobuf.Timestamp` for all date/time fields; reject raw string date fields.
5. Verify auth tokens are NOT in message fields — they belong in call metadata.
6. Verify `google.rpc.Status` + error_details.proto is used for all error envelopes.
7. Check naming: snake_case fields, PascalCase messages and services, SCREAMING_SNAKE_CASE enum values.
8. One service per .proto file. Group related RPCs in one service.
9. Use `proto3 optional` for genuinely nullable scalar fields.
10. Use `FieldMask` for partial update RPCs.
11. Run `buf lint` — fix all violations before merging.
12. Run `buf breaking` against the prior stable version — any breaking change requires explicit justification and a version bump.
13. Never hand-edit generated Protobuf or gRPC code (Swift or Python).
14. Flag high-risk changes: removing fields, changing field types, renaming RPC methods.

## Protobuf ↔ domain type mapping (transport boundary)

15. Generated Protobuf types are Data Transfer Objects at the gRPC transport boundary. They must not appear in domain-layer type signatures, in business logic, or in presentation-layer types (ViewModels, views, handlers, services).
16. Mapper code lives in the data layer alongside the repository implementation that uses it. Mappers are unidirectional at the boundary: generated → domain on inbound responses, domain → generated on outbound requests.
17. Recommended mapper patterns (choose one per language and apply consistently):
    - Swift: an extension on the domain type with an init accepting the generated type (`extension User { init(_ proto: User_Pb) throws }`), plus a reverse `func toProto() -> User_Pb` on the domain type for outbound requests.
    - Python: module-level mapper functions near the repository (`def user_from_proto(proto: user_pb2.User) -> User` and `def user_to_proto(user: User) -> user_pb2.User`).
18. Mappers validate incoming data. An incoming Protobuf message with invalid field values produces a typed domain error at the mapper, not an exception deeper in business logic.

## grpc-swift-2 client rules (Swift)

19. Generated Swift code must use grpc-swift-2 async API. Verify generated files import `GRPCCore`.
20. After `buf generate`: confirm generated Swift message types conform to `Sendable`. Log any missing conformances.
21. Verify Swift client code catches `RPCError` (GRPCCore). Flag any `GRPCStatus` v1 references in new code.
22. All `CallOptions` must supply a `.timeout`. Flag call sites where timeout is omitted.
23. Verify gRPC stubs are not called from SwiftUI Views or ViewModels. Flag violations.
24. Verify channel is a single `GRPCClient` per scene lifecycle or uses `GRPCChannelPool`. Flag per-request channel creation.
25. Cancellation: Swift Task cancellation propagates automatically to the underlying gRPC call in grpc-swift-2. Explicit `call.cancel()` is not required for Task-scoped calls. For streaming calls, use `withTaskCancellationHandler` to release downstream resources (UI bindings, observers, caches) when the Swift Task is cancelled.

## Swift gRPC → domain error mapping

26. Catch `RPCError` at the repository implementation site. `RPCError` must never cross the repository or service boundary into business logic.
27. Map `RPCError.Code` to domain error cases using this standard mapping (rename domain types to match the project's error enum):
    - `.notFound` → `DomainError.notFound(id:)`
    - `.unauthenticated` → `AuthError.unauthenticated`
    - `.permissionDenied` → `AuthError.permissionDenied`
    - `.invalidArgument` → `ValidationError.invalidRequest(message:)`
    - `.unavailable`, `.deadlineExceeded` → `NetworkError.transient(code:message:)` — retry eligible
    - `.internal` → `NetworkError.serverError(message:)` — not retryable
28. Use `throws(DomainErrorType)` in repository protocols — callers handle typed domain errors, never `RPCError`.

## grpc.aio server rules (Python)

29. Verify generated Python servicers use `grpc.aio.server(...)`. Flag synchronous server usage.
30. Verify all servicer handler methods are `async def`. Flag synchronous handlers.
31. Verify handlers use `await context.abort(grpc.StatusCode.CODE, "detail string")` for error responses. Flag bare exception raises.
32. Use `grpcio-status` for rich error details: attach `google.rpc.Status` via `context.abort_with_status(grpcio_status.to_status(Status(...)))`.
33. Never let domain exceptions propagate from handlers unhandled — they become `INTERNAL` with no client-visible detail. Catch domain exceptions in the handler and map them to `grpc.StatusCode` + detail.
34. Verify `grpcio`, `grpcio-tools`, `grpcio-status`, `grpcio-reflection` are all pinned to the same version.
35. Verify server interceptors subclass `grpc.aio.ServerInterceptor`.
36. Verify `asyncio.CancelledError` is not swallowed in streaming handlers — clean up resources, then re-raise.

## Python gRPC → domain error mapping (client side)

37. Catch `grpc.aio.AioRpcError` at the service or repository implementation site. `AioRpcError` must never cross the repository boundary into business logic.
38. Map `error.code()` to domain exception classes using this standard mapping (rename domain types to match the project's error hierarchy):
    - `NOT_FOUND` → `NotFoundError(resource_type, id)`
    - `UNAUTHENTICATED` → `AuthenticationError(message)`
    - `PERMISSION_DENIED` → `AuthorizationError(message)`
    - `INVALID_ARGUMENT` → `ValidationError(message)`
    - `UNAVAILABLE`, `DEADLINE_EXCEEDED` → `TransientError(code, message)` — retry eligible
    - `INTERNAL` → `ServerError(message)` — not retryable
39. Repository methods raise typed domain exceptions from an error hierarchy rooted at a project-defined base class (e.g., `AppError(Exception)`).

## Cross-language conventions

40. Schema changes must be validated against both Swift and Python generated code before merging.
41. Breaking changes require coordinated client and server releases — document the rollout order.
42. Shared enums used by both client and server must have identical semantics in both languages. Document any behavioral differences in enum handling (e.g., unknown enum values).
43. Deadline propagation: client-set deadlines must be respected server-side. Server handlers should check remaining deadline before starting expensive operations.
44. Error detail types (google.rpc error_details) must be understood by both client and server. Do not use language-specific error detail extensions.
