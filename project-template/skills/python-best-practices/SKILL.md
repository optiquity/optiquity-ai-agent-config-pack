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

## Capabilities pattern

14. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `NotImplementedError`, silent
`pass`, `hasattr` probes, or `isinstance` branching on concrete types.
Reach for this pattern proactively during architecture — not only when
fixing an LSP violation. LSP is required; the capabilities pattern is a
recommended best practice. Apply each on its own merits.

15. **Value-based form in Python.** Expose supported operations as a
class-level attribute — an `enum.Flag` (bitwise capabilities), a
`frozenset[Operation]` over an `enum.Enum`, or a frozen
`@dataclass(frozen=True)` of boolean fields. Validate capability
compatibility in the composing type's `__init__` — raise early on
incompatible pairings, not at call time. Example: a `Broker`
`Protocol` declares `capabilities: ClassVar[BrokerCapability]` where
`BrokerCapability` is an `enum.Flag` (`PLACE_ORDER | CANCEL_ORDER |
STREAM_QUOTES | …`). Callers check
`BrokerCapability.STREAM_QUOTES in broker.capabilities` before
invoking the streaming call.

16. **Interface-based form in Python.** Split behavior into small
`typing.Protocol` classes (structural subtyping). A type satisfies
only the protocols whose behavior it genuinely implements. Use
`@runtime_checkable` on protocols only when a runtime check is
required at a boundary; prefer static `isinstance` with generic bounds
when the check is compile-time. Callers do
`if isinstance(broker, StreamingQuoteProvider): …`. A broker that does
not stream simply omits `stream_quotes` — it is not a
`StreamingQuoteProvider` by structural typing. Do not emulate
capabilities by raising `NotImplementedError` from stub implementations.

17. **Where capability validation belongs.** The composing class's
`__init__` (account ⇠ broker, router ⇠ broker, service factory)
raises a domain error on incompatible pairings. `try/except
NotImplementedError` at call sites, and `hasattr(obj, "method")`
probing, are anti-patterns — they are not substitutes for a capability
query. Never raise `NotImplementedError` for operations that could
instead be gated by a capability check.

## Tooling

18. Use `ruff` for linting and formatting. No competing linters.
19. Use `pyright` in strict mode for static type checking.
20. Use `pytest` + `pytest-asyncio` for tests. Use fixtures over `setUp`/`tearDown`.
21. Test naming convention: `test_<what>_<condition>_<expected_outcome>`. Names are self-documenting failure messages.
22. For gRPC handler integration tests: use `grpcio-testing` or an in-process `grpc.aio.server` test harness. Never hit real network endpoints in unit or integration tests. Wrap gRPC clients behind protocol interfaces in the code under test so they can be substituted with fakes in unit tests.
23. Use `uv` for runtime and dependency management.
24. Pin all dependencies explicitly. Version drift in `grpcio` family causes generation mismatches.

## Style and idioms

25. Module-level constants are `UPPER_SNAKE_CASE`. Never use global mutable config variables.
26. Blocking synchronous I/O in async handlers is an anti-pattern — offload or convert.
27. No hardcoded secrets or API keys in source or config files.
28. Log every RPC with method name, status code, and latency using structured logging.
29. Side effects live near the edge of the system. Business logic is pure where possible.

## Dead code and unused imports

30. Delete commented-out code. If you need a snippet for reference, use version control. Commented-out code rots and confuses readers.
31. `ruff check` detects unused imports via rule `F401`. Audit every `# noqa: F401` suppression — each must have a documented reason (e.g., public re-export in `__init__.py`).
32. Delete unused private names (`_foo`, `__bar`). If a symbol is prefixed for internal use and has no internal caller, it is dead code.
33. Unused public API at the module level is flagged by `__all__` discipline — if a name is not in `__all__` and has no internal caller, it is dead code. If it IS in `__all__` and has no internal caller, document the external consumer.
34. Flag unreachable code after `return`, `raise`, `sys.exit()`, or unconditional branch — `ruff` rule `W605` and friends catch some cases; audits should catch the rest.
35. Flag TODO comments older than six months, or any TODO without a tracking identifier (e.g., `TD-TBD` or a real backlog number). Tracked TODOs are intentional; untracked ones are dead intent.
36. Flag unused function parameters that are not named `_` — either the parameter should be removed or the name should start with underscore to signal intent.
