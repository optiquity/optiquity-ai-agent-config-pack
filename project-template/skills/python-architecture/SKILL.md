---
name: python-architecture
description: Use when assessing Python server architecture, service layer boundaries, grpc.aio handler structure, repository pattern correctness, or long-term maintainability.
allowed-tools: Read, Grep, Glob, Bash
---

## Service layer boundaries

1. Identify service layer boundaries — verify servicers are thin adapters delegating to injected service objects.
2. Use constructor dependency injection. No module-level globals for services.
3. Check that domain model types are not exposed in gRPC servicer signatures. Only transport types (generated Protobuf) cross the gRPC boundary.
4. Services are stateless by default. Any state must be documented with owner, lifecycle, and thread-safety guarantees.

## Repository pattern

5. Verify repository pattern usage — data access logic belongs in repositories, not in service objects or servicers.
6. Prevent N+1 queries — use eager loading or batch queries at the repository layer.
7. Business logic never calls gRPC stubs, database drivers, or ORM methods directly. Only repository interfaces cross the data boundary.

## Async handler structure

8. Check async handler structure — no blocking synchronous I/O inside async handlers. Verify `await` is used consistently.
9. Verify grpc.aio usage — no synchronous `grpc.server()` or synchronous stubs in production code.
10. Background tasks must be idempotent — tasks that may be retried must be safe to run more than once.

## Domain model placement

11. Check Pydantic model placement — validation belongs at I/O boundaries (request ingress, external API responses). Domain objects should not be Pydantic models; use `@dataclass(frozen=True)`.
12. ML inference isolation — inference calls must not live in servicers or service objects. Isolate behind a protocol or interface.

## Middleware and cross-cutting concerns

13. Auth, logging, and metrics belong in gRPC interceptors, not in servicer implementations.
14. Flag middleware and interceptor correctness — interceptors subclass `grpc.aio.ServerInterceptor` and use `async def`.
