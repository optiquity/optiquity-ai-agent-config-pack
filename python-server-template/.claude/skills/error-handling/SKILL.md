---
name: error-handling
description: Use when designing, implementing, or reviewing error handling for gRPC handlers, domain exception types, retry logic, or error propagation across layer boundaries. Default for: Debugging (Claude Code).
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

## Domain Exception Design

1. Define custom exceptions inheriting from a base `AppError(Exception)`. Subclass by layer: `NetworkError`, `PersistenceError`, `AuthError`, `ValidationError`.
2. `grpc.aio.AioRpcError` must never cross the service or repository boundary into domain logic. Map at the boundary.
3. Domain exceptions are the only exception types that propagate into business logic.

## gRPC Status → Domain Exception Mapping (grpc.aio)

4. Catch `grpc.aio.AioRpcError` at the service or repository implementation site.
5. Map `error.code()` (`grpc.StatusCode`) to domain exceptions:
   - `NOT_FOUND` → `NotFoundError(resource_type, id)`
   - `UNAUTHENTICATED` → `AuthenticationError(message)`
   - `PERMISSION_DENIED` → `AuthorizationError(message)`
   - `INVALID_ARGUMENT` → `ValidationError(message)`
   - `UNAVAILABLE`, `DEADLINE_EXCEEDED` → `TransientError(code, message)` — retry eligible
   - `INTERNAL` → `ServerError(message)` — not retryable

## gRPC Handler Error Responses

6. Return gRPC errors from handlers using: `await context.abort(grpc.StatusCode.CODE, "detail string")`
7. Attach rich error details: `await context.abort_with_status(grpcio_status.to_status(Status(...)))`
8. Never let domain exceptions propagate from handlers unhandled — they become `INTERNAL` with no client-visible detail.
9. Wrap handler bodies in try/except that catches known domain exceptions and aborts with the correct status code.

## Retry Logic

10. Retry only transient errors: `UNAVAILABLE`, `DEADLINE_EXCEEDED`.
11. Never retry: `NOT_FOUND`, `INVALID_ARGUMENT`, `ALREADY_EXISTS`, `PERMISSION_DENIED`, `UNAUTHENTICATED`.
12. Formula: `delay = min(base * (2 ** attempt) + random.uniform(0, max_jitter), max_delay)`
13. Defaults: base=0.5s, max_delay=30s, max_attempts=5, max_jitter=1.0s. Define as a `RetryPolicy` dataclass — no inline magic numbers.

## Python-Specific Rules

14. Never use bare `except:` or `except Exception:` without re-raising or structured logging. Both are code review failures.
15. Catch `asyncio.CancelledError` in streaming handlers: clean up resources, then re-raise. Never swallow it.
16. Log mapped errors at the boundary with structured context: `rpc_method`, `error_code`, `detail`, `user_id` (where applicable).
