---
name: python-server-architecture
description: Use when assessing Python server architecture — gRPC servicers / FastAPI request handlers, server lifecycle, async handler I/O, server interceptors / middleware, background-task patterns.
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `auditor-code`, `auditor-architecture`, and
`reviewer` whenever a **Python server is present** in the project — i.e.,
the project serves requests over gRPC, REST, or another protocol from a
Python process (per `docs/pack/PLATFORM-SKILLS.md` Dimension 3 "Python
server" row).

This skill is the *server-specific* half of the v10.x `python-architecture`
skill, split in v11.0 (the `python_data_marker_detected()` load
predicate and the trinity SKILL.md split into
`python-server-architecture` + `python-data-architecture`). Data and I/O rules
(repository pattern, N+1 prevention, Pydantic placement, ML isolation)
moved to `python-data-architecture` and load independently for both
server and non-server multi-file Python projects. Both skills should
load together for any Python server project; load
`python-data-architecture` alone for non-server multi-file Python.

Foundational dependency-injection / statelessness rules (constructor
DI for services, stateless-by-default service objects) appear in both
this skill and `python-data-architecture` because they apply equally
to server services and to repository/data services. The duplication
is intentional and load-order-independent.

## Service layer boundaries

1. Identify service layer boundaries — verify servicers are thin adapters delegating to injected service objects.
2. Use constructor dependency injection. No module-level globals for services. *(Mirrored in `python-data-architecture` rule 1; foundational across server and data services.)*
3. Check that domain model types are not exposed in gRPC servicer signatures. Only transport types (generated Protobuf) cross the gRPC boundary.
4. Services are stateless by default. Any state must be documented with owner, lifecycle, and thread-safety guarantees. *(Mirrored in `python-data-architecture` rule 2; foundational across server and data services.)*

## Async handler structure

5. Check async handler structure — no blocking synchronous I/O inside async handlers. Verify `await` is used consistently.
6. Verify grpc.aio usage — no synchronous `grpc.server()` or synchronous stubs in production code.
7. Background tasks must be idempotent — tasks that may be retried must be safe to run more than once.

## Middleware and cross-cutting concerns

8. Auth, logging, and metrics belong in gRPC interceptors (or framework middleware for REST), not in servicer / handler implementations. The substantive observability rules — what spans to create, which attributes to attach, which fields every log record must carry, how to wire trace ↔ log correlation — live in `python-observability-patterns` (loaded for any Python server project per the intersection table). This skill defines the *placement*; the patterns skill defines the *content*.
9. Flag middleware and interceptor correctness — interceptors subclass `grpc.aio.ServerInterceptor` and use `async def`.
