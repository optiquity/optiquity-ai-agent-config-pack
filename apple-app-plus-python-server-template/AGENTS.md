# AGENTS.md

This is a monorepo with an Apple platform client (iOS, iPadOS, macOS) and a Python server.
All first-party communication uses gRPC + Proto3. Third-party APIs use their own native protocols.

## Capability policy

Codex may perform all major engineering tasks in this repository:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for correctness-sensitive work (architecture, concurrency, security, review).
- Use local models only where the verification path is strong and results are likely equivalent.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Apple client defaults

- SwiftUI first. UIKit or AppKit interop only when justified by platform gaps, third-party constraints, or measurable performance reasons.
- SPM first. No CocoaPods unless unavailable in SPM.
- Swift 6 strict concurrency for new code. Be pragmatic at legacy and third-party boundaries.

## Python server defaults

- Python 3.12+. Use `uv` for environment and dependency management.
- Prefer `ruff`, `pyright --strict`, `pytest`, `pytest-asyncio`.
- Server code must run on macOS, Linux, and Windows unless explicitly documented otherwise.
- All public functions and methods have type annotations.

## Shared schema defaults

- gRPC + Proto3 for all first-party communication. Source of truth lives in `proto/`.
- Use `buf lint` and `buf breaking` before every schema merge.
- Never hand-edit generated Protobuf or gRPC code.
- Proto3 field numbers are inviolable. Use `reserved` on deletion.
- `google.protobuf.Timestamp` for all date/time fields.
- `google.rpc.Status` + error_details for all gRPC errors.

## Design rules

- Prefer immutable types by default.
- Use mutable state only for clearly stateful roles: stores, coordinators, caches, boundary adapters.
- Make invalid states unrepresentable.
- Prefer dependency injection over global state on both client and server.
- Keep UI, domain, persistence, and networking concerns separate.

## gRPC client rules (Swift)

- Never call gRPC stubs from ViewModels or Views. Always wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the boundary. Never pass domain types to stubs.
- Auth tokens in gRPC metadata, never in message fields.
- Every gRPC call has an explicit deadline using a named constant.
- Use GRPCChannelPool. Tie channel lifecycle to app or scene lifecycle.

## gRPC server rules (Python)

- Servicers are thin adapters delegating to injected service objects.
- Return google.rpc.Status with error_details for all errors.
- Log every RPC: method name, status code, latency. Use structured logging.
- Use gRPC interceptors for auth, logging, and metrics.
- Set and enforce deadlines. Handle DEADLINE_EXCEEDED explicitly.

## Security rules

- Credentials go in Keychain (Apple) or environment/secrets managers (Python). No hardcoded secrets.
- TLS required for all gRPC connections.
- Auth tokens in metadata, never in message fields.
- Validate all incoming data at I/O boundaries.
- Rate limit server-side. Return RESOURCE_EXHAUSTED for violations.
- Parameterized queries only. Never concatenate user input into SQL.

## Testing policy

- Add or update tests for non-trivial changes.
- Protocol-based test doubles for gRPC stubs (client). grpcio-testing for server-side unit tests.
- Never hit real network endpoints in unit or integration tests.
- Use pytest + pytest-asyncio for Python async tests.
- Run buf breaking before every proto schema merge.
- XCUITest for native Apple UI coverage.

## Git and review policy

- Keep commits coherent.
- Separate formatting-only changes from behavior changes.
- Preserve existing behavior during refactors unless the task says otherwise.
- Document setup changes.
- Do not commit generated Protobuf or gRPC code.
- Flag proto schema changes as high-risk in PR notes.

## Anti-patterns — never introduce

- Hand-editing generated Protobuf or gRPC code.
- Reusing deleted Proto3 field numbers.
- Auth tokens in Protobuf message fields.
- gRPC stubs called directly from ViewModels, Views, or business logic.
- Magic duration literals for gRPC deadlines.
- Skipping buf lint and buf breaking before schema merges.
- @unchecked Sendable without audited justification.
- Force unwraps as convenience.
- print() in production code.
- Module-level mutable globals as service registries.
- N+1 database queries.
- Blocking synchronous I/O in async handlers.
- Hardcoded secrets in source or config files.

## Agent behavior

- Planning, coding, testing, review, refactoring, and repo operations are all allowed.
- Read existing code before adding new abstractions.
- Do not invent package APIs, Xcode settings, or Python library behavior.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- For proto schema changes, always plan first and run buf lint + buf breaking before proposing a merge.
- When using a local model, avoid high-risk architectural changes unless a stronger model has already reviewed the plan.


## Phase routing — default agent assignments

Both Codex and Claude Code can execute any engineering phase in this repo.
The defaults below identify the better system for each phase. Override freely when task
characteristics favor the other system.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | apple-architect or planner | Multi-file context, extended reasoning |
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

To invoke a specific agent in Codex: `codex --agent planner`
To invoke a specific agent in Claude Code: `claude --agent reviewer`
