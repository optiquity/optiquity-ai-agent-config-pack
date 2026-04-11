---
name: error-handling
description: Use when designing, implementing, or reviewing error handling — domain error design, error propagation across layer boundaries, and retry policy. Platform-agnostic philosophy; language/protocol specifics come from the loaded platform skills.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

This skill defines universal error handling philosophy. Language-specific error types, concrete mapping tables (e.g., gRPC status → domain error), and async cancellation mechanics come from the platform skills loaded alongside this one (swift-best-practices, python-best-practices, grpc-patterns, rest-patterns). Apply this philosophy using the concrete types and conventions from those skills.

## Domain error design

1. Define one typed error type per domain layer. Each case or class carries associated context values (ids, messages, codes, retry guidance) — never a bare error with just a string message.
2. Domain errors are the only error types that propagate into business logic and presentation layers. Transport errors (HTTP status, gRPC status, filesystem errors, parser errors) must be mapped to domain errors at the boundary where they enter the system.
3. The error type hierarchy is part of the API contract — changes to it are versioned and reviewed like any other API change.

## Error propagation across boundaries

4. Map transport errors to domain errors at the repository or service boundary. Callers of repository and service methods never see raw transport errors.
5. Every `catch` or `except` block must handle, log, or re-raise. Silent swallowing is a defect. An empty catch block is a code review failure.
6. When logging a mapped error at the boundary, include: the method that failed, the original transport code, the mapped domain error type, and relevant structured context (request id, user id, deadline). Never log credentials or PII.
7. Do not leak transport error detail into user-facing messages. The user sees a domain-appropriate message; the log sees the technical detail.

## Retry policy

8. Retry only transient errors. Retryable conditions are categorized at the domain error level — never retry based on raw transport status in business logic.
9. Never retry client errors (not found, invalid argument, already exists, permission denied, unauthenticated). These are not transient — retrying them wastes resources and can corrupt state.
10. Use exponential backoff with jitter. Formula: `delay = min(base * 2^attempt + jitter(0, maxJitter), maxDelay)`.
11. Cap maximum retry count and maximum delay. Define defaults as a named value type or dataclass — no inline magic numbers. Reasonable starting defaults: base=0.5s, maxDelay=30s, maxAttempts=5, maxJitter=1.0s.
12. Make retry behavior configurable per operation type. A read may retry more aggressively than a write.

## Cancellation

13. Long-running operations must respect cancellation. When a cancellation signal arrives, clean up resources, log the cancellation, then propagate the signal — never swallow it.
14. Cancellation semantics are language- and framework-specific — consult the loaded platform skills (swift-best-practices, python-best-practices, grpc-patterns) for the correct mechanism.

## Output

When reviewing error handling, produce findings grouped by severity. Each finding includes: the file and symbol, the rule violated, and the recommended action. When designing error handling, produce: the domain error type definition, the mapping strategy from transport errors, and the retry policy for each operation category.
