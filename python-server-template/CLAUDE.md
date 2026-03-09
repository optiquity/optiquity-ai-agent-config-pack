# CLAUDE.md

This repository is a Python server repository. It may serve gRPC, REST, WebSocket, or a combination.
When this server communicates with first-party Apple or other clients, it uses gRPC + Proto3 as the shared schema.
Third-party API integrations use their own native protocols (REST/JSON, etc.).

Intended for terminal-first workflows in Claude Code, Codex CLI, VS Code, and the standalone Claude and Codex apps.

## Scope

Both Claude and Codex may perform all major work categories in this repository:
planning, architecture, implementation, refactoring, debugging, testing, review,
dependency review, repository operations, documentation.

No task category is exclusive to one tool. Default preferences are only preferences.

## Platform and runtime goals

- Server code must run on macOS, Linux, and Windows unless a file or dependency explicitly documents a platform-specific exception.
- Python 3.12+ unless a project constraint requires otherwise.
- Prefer `uv` for Python runtime and dependency management.
- Prefer `pytest` + `pytest-asyncio` for tests.
- Prefer `ruff` for linting and formatting.
- Prefer `pyright` in strict mode for static type checking.

## Engineering defaults

- Correctness first.
- Prefer simple, explicit APIs.
- Prefer immutable data where practical.
- Treat global mutable state as a code smell unless required by framework boundaries.
- Validate inputs at I/O boundaries.
- Keep side effects near the edge of the system. Business logic should be pure where possible.

## Python coding rules

- All public functions and methods must have type annotations. Run `pyright --strict` to enforce.
- Use constructor dependency injection. Do not rely on module-level globals for services.
- Use async context managers for resource lifecycle (database connections, gRPC channels).
- Use `pydantic-settings` for environment-based configuration.
- Use Pydantic for input validation at all I/O boundaries.
- Use `__all__` in all public modules to document the intended public surface.
- Use structured logging. Log at appropriate levels. Never use print() in production code.

## gRPC and Proto3 server rules

These rules apply when this server exposes or consumes gRPC services.

- Generated servicer classes (stubs) are never called from business logic. Implement servicers as thin adapters that delegate to injected service objects.
- Never hand-edit generated Protobuf or gRPC Python code. Regenerate from `.proto` source using buf or the project gen script.
- Use `buf lint` and `buf breaking` before every proto schema merge.
- Proto3 field numbers are inviolable. Never reuse a deleted field number. Use `reserved` on deletion.
- Enum zero value must always be `UNSPECIFIED` (e.g., `STATUS_UNSPECIFIED = 0`).
- Return `google.rpc.Status` with `error_details.proto` for all gRPC error responses.
- Map gRPC status codes at the boundary. Never let raw gRPC status propagate into domain logic.
- Set and enforce request deadlines server-side. Handle `DEADLINE_EXCEEDED` explicitly.
- Use gRPC interceptors for cross-cutting concerns: auth, structured logging (log method + status + latency), metrics. Do not inline these in servicers.
- Log every RPC with: method name, status code, and latency.
- Use `grpcio-testing` for server-side gRPC unit tests. Never hit real network endpoints in unit tests.
- Pin `grpcio` and `grpcio-tools` versions explicitly. Version drift causes generation mismatches.
- Use `google.protobuf.Timestamp` for all date/time fields. Never raw string dates in proto.
- One service definition per `.proto` file. Group related RPCs in one service.

## Security

- Never hardcode secrets, API keys, certificates, or credentials in source code or config files.
- Use environment variables or a secrets manager for all credentials. Use `pydantic-settings` to load them.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.
- Auth tokens in gRPC call metadata, never in Protobuf message fields.
- Validate all incoming data at I/O boundaries using Pydantic.
- Implement rate limiting. Return `RESOURCE_EXHAUSTED` gRPC status for violations.
- Prevent SQL injection. Use parameterized queries or an ORM. Never concatenate user input into queries.
- Use JWT or OAuth for authentication. Validate tokens server-side on every request.
- Run dependency security scans regularly (`uv` supports pip-audit; consider integrating it).
- Never store plaintext passwords. Use bcrypt, Argon2, or equivalent.

## Performance and data rules

- Prevent N+1 queries. Use eager loading or batch queries at the repository layer.
- Background tasks must be idempotent. Document the idempotency key or mechanism.
- ML model inference must be isolated from business logic. Version models explicitly. Document the rollback procedure.
- Data pipeline steps must be idempotent. Document the checkpoint strategy.
- Use cursor-based pagination for large collection responses.

## Dependency policy

- Add new dependencies only with a short justification.
- Prefer mature packages with active documentation.
- Pin or constrain versions deliberately. Use `uv lock` for deterministic installs.
- Prefer cross-platform libraries and tools.
- Avoid dependencies that force a single editor, IDE, shell, or hosting platform unless required.

## Layout expectations

Common directories in this repo may include:
- `src/` — app source code
- `tests/` — automated tests
- `proto/` — Proto3 schema files (if using gRPC)
- `scripts/` — repo automation
- `docs/` — architecture notes, ADRs, API references

## Validation rules

Before claiming work is done, run the strongest applicable checks available locally.
The validation scripts in `scripts/` are the default entry points:
- `./scripts/bootstrap.sh`
- `./scripts/format.sh`
- `./scripts/test.sh`
- `./scripts/validate.sh`

If a tool is not installed, say so explicitly instead of pretending validation passed.

## Testing expectations

- Add or update tests with every non-trivial change.
- Unit tests for domain logic and state transitions.
- Integration tests for storage, gRPC adapters, and module seams.
- Use `grpcio-testing` for gRPC server unit tests.
- Use `pytest-asyncio` for all async test cases.
- Verify schema compatibility with `buf breaking` before every proto merge.
- Tests must be deterministic. Avoid time-dependent, random, or network-dependent behavior without fakes or fixtures.

## Anti-patterns — never introduce these

- Editing generated Protobuf or gRPC Python code by hand.
- Reusing or renaming a deleted Proto3 field number.
- Auth tokens in Protobuf message fields.
- gRPC servicers containing business logic directly — use injected service objects.
- Magic duration literals for gRPC deadlines — use named constants.
- Skipping buf lint and buf breaking before a schema merge.
- Module-level mutable globals used as service registries.
- Ignoring gRPC UNAVAILABLE as a fatal unrecoverable error without retry/backoff logic.
- N+1 database queries.
- Blocking synchronous I/O inside async request handlers.
- Type annotations omitted on public APIs.
- print() in production code — use the structured logger.
- Hardcoded secrets, API keys, or credentials in source or config files.
- Concatenating user input into SQL queries.
- Anemic domain models — domain objects should have behavior, not just be data bags.
