---
name: error-handling
description: Use when designing, implementing, or reviewing error handling for gRPC calls, domain error types, retry logic, or error propagation across layer boundaries. Default for: Debugging (Claude Code).
# allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

## Domain Error Design

1. Define one typed error enum per domain layer: `NetworkError`, `PersistenceError`, `AuthError`, `ValidationError`. Each case carries associated values with context.
2. `RPCError` (grpc-swift-2) must never cross the repository or service boundary into domain or presentation layers. Map at the boundary.
3. Domain errors are the only error types that propagate into business logic and UI.
4. Use `throws(DomainErrorType)` (Swift 6 typed throws) in repository protocol methods — callers never handle `RPCError`.

## gRPC Status → Domain Error Mapping (grpc-swift-2)

5. Catch `RPCError` at the repository implementation site.
6. Map `RPCError.Code` to domain errors:
   - `.notFound` → `YourDomainError.notFound(id:)`
   - `.unauthenticated` → `AuthError.unauthenticated`
   - `.permissionDenied` → `AuthError.permissionDenied`
   - `.invalidArgument` → `ValidationError.invalidRequest(message:)`
   - `.unavailable`, `.deadlineExceeded` → `NetworkError.transient(code:message:)` — retry eligible
   - `.internal` → `NetworkError.serverError(message:)` — not retryable
7. Never expose raw `RPCError` or its `.code` values to ViewModels or Views.

## Retry Logic

8. Retry only transient errors: `unavailable`, `deadlineExceeded`.
9. Never retry: `notFound`, `invalidArgument`, `alreadyExists`, `permissionDenied`, `unauthenticated`.
10. Formula: `delay = min(base * pow(2, attempt) + jitter(0, maxJitter), maxDelay)`
11. Defaults: base=0.5s, maxDelay=30s, maxAttempts=5, maxJitter=1.0s. Express as a named `RetryPolicy` struct — no inline magic numbers.

## Swift-Specific Rules

12. Use `Result<Success, Failure>` when an error must be stored or passed as a value (not thrown synchronously).
13. Use `throws` for error propagation; `Result` for storage and deferred handling.
14. Cancellation in grpc-swift-2: Swift Task cancellation propagates automatically. No explicit `call.cancel()` required.
15. Every `catch` block handles, logs, or rethrows. An empty `catch {}` is a code review failure requiring justification.
16. Log mapped errors at the boundary with: rpc method name, domain error type, original gRPC code, and structured context.
