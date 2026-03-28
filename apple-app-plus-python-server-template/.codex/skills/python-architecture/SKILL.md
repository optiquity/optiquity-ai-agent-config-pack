---
name: python-architecture
description: Use when assessing Python server architecture, service layer boundaries, grpc.aio handler structure, repository pattern correctness, or long-term maintainability.
allowed-tools: Read, Grep, Glob, Bash
---

1. Identify service layer boundaries — verify servicers are thin adapters delegating to injected service objects.
2. Check that domain model types are not exposed in gRPC servicer signatures. Only transport types (generated Protobuf) cross the gRPC boundary.
3. Verify repository pattern usage — data access logic belongs in repositories, not in service objects or servicers.
4. Check Pydantic model placement — validation belongs at I/O boundaries (request ingress, external API responses). Domain objects should not be Pydantic models.
5. Check async handler structure — no blocking synchronous I/O inside async handlers. Verify `await` is used consistently.
6. Verify grpc.aio usage — no synchronous `grpc.server()` or synchronous stubs in production code.
7. Check background task idempotency — tasks that may be retried must be safe to run more than once.
8. Check ML inference isolation — inference calls must not live in servicers or service objects. Isolate behind a protocol/interface.
9. Flag stateful service objects — services must be stateless by default. Any state must be documented with owner, lifecycle, and thread-safety guarantees.
10. Flag middleware and interceptor correctness — auth, logging, and metrics belong in interceptors, not in servicer implementations.
