---
name: python-best-practices
description: Use for Python language patterns, async/await, type hints, ruff and pyright rules, and idiomatic Python style.
allowed-tools: Read, Grep, Glob, Bash
---

## Type system and annotations

1. All public functions and methods must have type annotations. Run `pyright --strict`.
2. Use `@dataclass(frozen=True)` for domain model and value object types. Prevents accidental mutation.
3. Use `pydantic-settings` for environment-based configuration. Use Pydantic `BaseModel` for input validation at I/O boundaries.
4. Use `__all__` in all public modules to document the intended public surface.
5. Define custom exceptions inheriting from appropriate stdlib base exceptions.

## Async patterns

6. All I/O-bound operations use `async def` — gRPC calls, DB queries, outbound HTTP, file I/O.
7. CPU-bound work is offloaded via `asyncio.run_in_executor` with a `ProcessPoolExecutor`.
8. Handle `asyncio.CancelledError` in streaming handlers — clean up resources, then re-raise. Never swallow it.
9. Use async context managers for resource lifecycle (database connections, gRPC channels).

## Error handling

10. Never use bare `except:` or `except Exception:` without re-raising or structured logging.
11. Define one error hierarchy per domain layer. Map external errors (gRPC status, HTTP status) to domain exceptions at the boundary.
12. Every `except` block must handle, log, or re-raise. Empty exception handlers are defects.
13. Retry transient failures with exponential backoff and jitter. Never retry non-transient errors.

## Tooling

14. Use `ruff` for linting and formatting. No competing linters.
15. Use `pyright` in strict mode for static type checking.
16. Use `pytest` + `pytest-asyncio` for tests. Use fixtures over `setUp`/`tearDown`.
17. Test naming convention: `test_<what>_<condition>_<expected_outcome>`. Names are self-documenting failure messages.
18. For gRPC handler integration tests: use `grpcio-testing` or an in-process `grpc.aio.server` test harness. Never hit real network endpoints in unit or integration tests. Wrap gRPC clients behind protocol interfaces in the code under test so they can be substituted with fakes in unit tests.
19. Use `uv` for runtime and dependency management.
20. Pin all dependencies explicitly. Version drift in `grpcio` family causes generation mismatches.

## Style and idioms

21. Module-level constants are `UPPER_SNAKE_CASE`. Never use global mutable config variables.
22. Blocking synchronous I/O in async handlers is an anti-pattern — offload or convert.
23. No hardcoded secrets or API keys in source or config files.
24. Log every RPC with method name, status code, and latency using structured logging.
25. Side effects live near the edge of the system. Business logic is pure where possible.
