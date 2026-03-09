---
name: architecture-review
description: Use when assessing Python server architecture, module boundaries, dependency injection, async design, gRPC service layering, or long-term maintainability.
allowed-tools: Read, Grep, Glob, Bash
---

1. Identify modules, layers, and ownership boundaries.
2. Check constructor dependency injection is used for all services. Flag module-level globals used as service registries.
3. Verify gRPC servicers are thin adapters — business logic belongs in injected service objects, not in servicers.
4. Check async design: no blocking I/O in async handlers, proper use of async context managers.
5. Check input validation at I/O boundaries using Pydantic.
6. Check type annotation completeness on public APIs (pyright --strict compliance).
7. Flag N+1 query risks at the repository layer.
8. Check background task idempotency.
9. Verify structured logging is used (not print()).
10. Flag security risks: hardcoded credentials, missing input validation, SQL injection surface.
11. Give a recommendation with explicit tradeoffs.
