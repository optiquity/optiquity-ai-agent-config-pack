---
name: error-handling
description: Use when designing, implementing, or reviewing error handling for gRPC calls or handlers, domain error types, retry logic, or error propagation across layer boundaries. Default for: Debugging (Claude Code).
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

## Domain Error Design

1. Define one typed error type per domain layer. Swift: typed `enum` with `throws(DomainErrorType)`. Python: class hierarchy rooted at `AppError(Exception)`.
2. gRPC transport errors (`RPCError` in Swift grpc-swift-2; `grpc.aio.AioRpcError` in Python) must never cross the repository or service boundary. Map to domain errors at the boundary.
3. Domain errors are the only error types that propagate into business logic and presentation layers.

## gRPC Status → Domain Error Mapping (Swift — grpc-swift-2)

4. Catch `RPCError` at the repository implementation site. Map `RPCError.Code`:
   - `.notFound` → `YourDomainError.notFound(id:)`
   - `.unauthenticated` → `AuthError.unauthenticated`
   - `.permissionDenied` → `AuthError.permissionDenied`
   - `.invalidArgument` → `ValidationError.invalidRequest(message:)`
   - `.unavailable`, `.deadlineExceeded` → `NetworkError.transient(code:message:)` — retry eligible
   - `.internal` → `NetworkError.serverError(message:)` — not retryable
5. Use `throws(DomainErrorType)` in repository protocols — callers never handle `RPCError`.

## gRPC Status → Domain Error Mapping (Python — grpc.aio)

6. Catch `grpc.aio.AioRpcError` at the service or repository implementation site. Map `error.code()`:
   - `NOT_FOUND` → `NotFoundError(resource_type, id)`
   - `UNAUTHENTICATED` → `AuthenticationError(message)`
   - `PERMISSION_DENIED` → `AuthorizationError(message)`
   - `INVALID_ARGUMENT` → `ValidationError(message)`
   - `UNAVAILABLE`, `DEADLINE_EXCEEDED` → `TransientError(code, message)` — retry eligible
   - `INTERNAL` → `ServerError(message)` — not retryable

## gRPC Handler Error Responses (Python)

7. Return gRPC errors: `await context.abort(grpc.StatusCode.CODE, "detail string")`.
8. Rich error details: `await context.abort_with_status(grpcio_status.to_status(Status(...)))`.
9. Never let domain exceptions propagate from handlers unhandled — they become `INTERNAL` with no client-visible detail.

## Retry Logic

10. Retry only transient errors: `unavailable` / `UNAVAILABLE`, `deadlineExceeded` / `DEADLINE_EXCEEDED`.
11. Never retry: `notFound`, `invalidArgument`, `alreadyExists`, `permissionDenied`, `unauthenticated`.
12. Formula: `delay = min(base * 2^attempt + jitter(0, maxJitter), maxDelay)`
13. Defaults: base=0.5s, maxDelay=30s, maxAttempts=5, maxJitter=1.0s. Define as a named value type / dataclass — no inline magic numbers.

## Swift-Specific Rules

14. Use `Result<Success, Failure>` for storable errors (not thrown). Use `throws` for propagation.
15. Cancellation in grpc-swift-2: Swift Task cancellation propagates automatically. No explicit `call.cancel()` required.
16. Every `catch` block handles, logs, or rethrows. An empty `catch {}` is a code review failure.

## Python-Specific Rules

17. Never use bare `except:` or `except Exception:` without re-raising or structured logging.
18. Handle `asyncio.CancelledError` in streaming handlers: clean up, then re-raise. Never swallow.
19. Log mapped errors at the boundary with: rpc_method, domain error type, original code, and structured context.
