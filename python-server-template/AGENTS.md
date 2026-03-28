# AGENTS.md

This repository is a terminal-first Python server repository.
It may serve gRPC, REST, WebSocket, or a combination.
When communicating with first-party clients, it uses gRPC + Proto3 as the shared schema.

Both Codex and Claude may perform planning, implementation, testing, review, debugging,
repo operations, and documentation work here. No work category is exclusive to one tool.

## Default workflow

1. Inspect the current repository state.
2. Read the closest relevant docs and config files before making non-trivial changes.
3. Prefer minimal, reversible edits.
4. Run the repo scripts in `scripts/` for formatting, tests, and validation.
5. Report what was verified, what was not verified, and any gaps.

## Python defaults

- Python 3.12+. Use `uv` for environment and dependency management.
- `ruff check` and `ruff format` for linting and formatting.
- `pyright --strict` for static analysis. All public functions and methods must have type annotations.
- `pytest` + `pytest-asyncio` for tests.
- Keep code cross-platform.
- Keep shell scripts POSIX-friendly. Add PowerShell equivalents if Windows-specific automation is needed.

## gRPC and Proto3 defaults

- Generated servicer classes are never called from business logic. Use thin adapter servicers delegating to injected services.
- Never hand-edit generated Protobuf or gRPC Python code.
- Run `buf lint` and `buf breaking` before every proto schema merge.
- Proto3 field numbers are inviolable. Use `reserved` on deletion.
- Auth tokens in gRPC metadata, never in message fields.
- Every call has an explicit deadline. Handle DEADLINE_EXCEEDED explicitly.
- Use gRPC interceptors for auth, logging, and metrics.
- Log every RPC: method name, status code, latency.
- Return google.rpc.Status with error_details for all gRPC errors.
- Use grpcio-testing for server-side unit tests.
- Pin grpcio and grpcio-tools versions explicitly.

## Architecture defaults

- Constructor dependency injection. No module-level globals for services.
- Async context managers for resource lifecycle.
- pydantic-settings for environment-based configuration.
- Pydantic for input validation at I/O boundaries.
- Structured logging. Never print() in production code.
- Cursor-based pagination for large collections.
- Background tasks must be idempotent.
- Prevent N+1 queries.

## Security defaults

- No hardcoded secrets, API keys, or credentials.
- TLS required for all gRPC connections.
- Validate all incoming data at I/O boundaries.
- Rate limiting with RESOURCE_EXHAUSTED for violations.
- Parameterized queries only. No user input concatenated into SQL.
- JWT or OAuth for auth. Validate tokens server-side on every request.

## Safety and correctness

- Do not read `.env`, `.env.*`, or `secrets/` unless explicitly required.
- Do not rewrite lockfiles or dependency constraints casually.
- Do not add networked services or background daemons without documenting the reason.
- Do not state that an external API or framework supports a feature unless that support was verified.
- Do not commit generated Protobuf or gRPC Python code.

## Scripts

The `scripts/` directory contains shell scripts agents and developers use to validate,
test, format, and generate code. Make them executable on first checkout: `chmod +x scripts/*.sh`.

| Script | Purpose | Call |
|---|---|---|
| `bootstrap.sh` | First-time setup — installs Python dependencies via uv | Manual, once per machine |
| `format.sh` | Run ruff format + ruff check. Manual only — not in the auto-hook | `repo-ops` or manual pre-commit |
| `test.sh` | Run pytest | `repo-ops` or manual |
| `validate.sh` | Full build + test suite | `repo-ops` or manual pre-commit |
| `proto-gen.sh` | Run buf lint + buf generate after .proto edits | `grpc-schema` or manual |
| `agent-post-edit-check.sh` | Auto build-check. **Never call manually.** | Claude Code PostToolUse hook only |

## Anti-patterns — never introduce

- Hand-editing generated Protobuf or gRPC Python code.
- Reusing deleted Proto3 field numbers.
- Auth tokens in Protobuf message fields.
- Business logic in gRPC servicers — delegate to injected services.
- Magic duration literals for gRPC deadlines.
- Skipping buf lint or buf breaking before schema merges.
- Module-level mutable globals as service registries.
- N+1 database queries.
- Blocking synchronous I/O in async handlers.
- Type annotations omitted on public APIs.
- print() in production code.
- Hardcoded secrets in source or config.
- User input concatenated into SQL queries.


## Phase routing — default agent assignments

Both Codex and Claude Code can execute any engineering phase in this repo.
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

To invoke a specific agent in Codex: `codex --agent planner`
To invoke a specific agent in Claude Code: `claude --agent reviewer`
