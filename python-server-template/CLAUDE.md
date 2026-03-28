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


## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern per app target before writing production code. Document the choice and rationale in README.md or ARCHITECTURE.md before implementation begins.
- Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified.
- Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may reach past its immediate neighbor (presentation → domain → data; never presentation → data directly).
- Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, gRPC, grpcio, or any persistence or networking framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer type signatures or in presentation/view-model types.
- Every cross-layer dependency is expressed as a protocol abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
- Shared mutable state declares its owner type, owning actor or thread, lifecycle (who creates it, who destroys it), and mutation contract at the definition site. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services explicitly document their state variables, threading guarantees, and invalidation policy.
- Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern.

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

## Scripts

The `scripts/` directory at the project root contains shell scripts for validation, formatting,
testing, and code generation. **Copy from the pack template and make executable before first use**
(`chmod +x scripts/*.sh`).

| Script | When to run | Who calls it |
|---|---|---|
| `bootstrap.sh` | Once on first checkout or new machine | Human |
| `format.sh` | Before committing — runs ruff format and ruff check | Human or `repo-ops` agent |
| `test.sh` | After implementing — runs pytest | Human or `repo-ops` agent |
| `validate.sh` | Before committing — full build + test suite | Human or `repo-ops` agent |
| `proto-gen.sh` | After editing any `.proto` file — runs buf lint then buf generate | Human or `grpc-schema` agent |
| `agent-post-edit-check.sh` | **Never call manually** — fires automatically via Claude Code PostToolUse hook | Claude Code hook |

**Note:** `format.sh` is manual-only — not wired into the automatic post-edit hook.
Run it explicitly before committing or ask `repo-ops` to run it.

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


## grpc.aio API rules (asyncio-native gRPC)

This repo uses `grpc.aio` (asyncio-native) for all gRPC server and client code.
Do not use synchronous `grpc.server()` or synchronous stubs in production code.

- Start the server with `grpc.aio.server(interceptors=[...])`, not `grpc.server(...)`.
- All servicer handler methods are `async def`. Blocking code inside a handler stalls the event loop — offload CPU-bound work with `asyncio.run_in_executor(executor, ...)`.
- Unary handler: `async def MethodName(self, request: RequestType, context: grpc.aio.ServicerContext) -> ResponseType`
- Server-streaming: `async def` + `await context.write(response)` in a loop; return `None`.
- Client-streaming: `async for request in context: ...`
- Bidirectional: combine `async for request in context` with `await context.write(response)`.
- Return gRPC errors: `await context.abort(grpc.StatusCode.CODE, "detail string")`. Never raise bare Python exceptions from handlers — they become `INTERNAL` status with no visible detail.
- Rich error details: use `grpcio-status`. Attach `google.rpc.Status` with error_details via `context.abort_with_status(...)`.
- Server interceptors: subclass `grpc.aio.ServerInterceptor`. Implement `async def intercept(self, continuation, call_details)`.
- Client channels: use `grpc.aio.secure_channel()` (production) or `grpc.aio.insecure_channel()` (local dev) inside `async with` blocks.
- Client errors: catch `grpc.aio.AioRpcError`. Inspect `.code()` and `.details()`. Map to domain exceptions at the service or repository boundary.
- Streaming cancellation: handle `asyncio.CancelledError` in streaming handlers — clean up resources, then re-raise. Do not swallow it.
- Dependency pinning: `grpcio`, `grpcio-tools`, `grpcio-status`, and `grpcio-reflection` must be pinned to the same version.


## Phase routing — default agent assignments

Both Claude Code and Codex can execute any engineering phase in this repo.
The defaults below identify the better system for each phase. Override freely when task
characteristics favor the other system.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | ios-architect or planner | Multi-file context, extended reasoning |
| API and schema design | **Claude Code** | grpc-schema | Schema tools, buf integration |
| Planning / task breakdown | **Claude Code** | planner | Tiebreaker — both systems comparable |
| Dependency evaluation | **Claude Code** | docs-researcher | Web search, nuanced tradeoff analysis |
| Implementation | **Codex** | coder | workspace-write sandbox, strong code generation |
| Code review | **Claude Code** | reviewer | Deep multi-file analysis, Bash diagnostics |
| Testing | **Codex** | tester | Pattern generation, approval flow for new files |
| Debugging | **Claude Code** | coder | Multi-step reasoning, Bash for live diagnostics |
| Refactoring | **Codex** | coder | Mechanical changes in workspace-write sandbox |
| Documentation | **Claude Code** | docs-researcher | Tiebreaker — multi-file context aids consistency |
| Repo operations | **Codex** | repo-ops | workspace-write sandbox, scripting strength |
| Local validation | **Codex** | repo-ops | workspace-write sandbox; can execute scripts |

To invoke a specific agent in Claude Code: `claude --agent planner`
To invoke a specific agent in Codex: `codex --agent coder`
