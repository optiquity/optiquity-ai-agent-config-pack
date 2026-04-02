# AGENTS.md

This repository targets Apple platforms (iOS, iPadOS, macOS), Xcode 26.3, GitHub, and Swift Package Manager.
When this repo communicates with a first-party backend, it uses gRPC + Proto3.

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

## Platform defaults

- SwiftUI first. UIKit or AppKit interop only when justified by platform gaps, third-party constraints, or measurable performance reasons.
- SPM first. No CocoaPods unless unavailable in SPM and value is proven.
- New code follows Swift 6 strict concurrency. Be pragmatic at legacy and third-party boundaries.
- Client-server schema: gRPC + Proto3 for all first-party communication.

## Design rules

- Prefer immutable types by default.
- Use mutable state only for clearly stateful roles: stores, coordinators, caches, boundary adapters.
- Prefer value semantics for models unless reference semantics are required.
- Mark classes `final` unless subclassing is required.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin. Move orchestration elsewhere.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.
- Avoid inheritance unless framework requirements or a stable abstraction clearly justify it.
- Persistent domain objects carry a typed ID wrapper (a `UUID` wrapped in a named struct). Never use raw `UUID` or `String` at domain boundaries.
- Choose one primary architecture pattern before writing production code. **Document the choice in `ARCHITECTURE.md` before implementation begins.**

## gRPC client rules

- Never call generated gRPC stubs directly from views or view models. Wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the transport boundary. Never pass domain types to stubs.
- Never hand-edit generated Protobuf or gRPC Swift code. Regenerate from .proto source.
- Auth tokens go in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call must have an explicit deadline using a named constant.
- Map gRPC status codes to typed domain errors at the boundary. Never surface raw gRPC status in UI.
- Track cancellation for streaming calls. Do not leak stream references across scene lifecycle.
- Use GRPCChannelPool. Tie channel lifecycle to app or scene lifecycle.

## Security rules

- Credentials, tokens, and certificates go in Keychain. Never in UserDefaults or source code.
- No hardcoded secrets or API keys.
- TLS required for all gRPC connections.
- Validate all network data before use in domain logic or UI.
- Privacy Manifests required for all required reason APIs and third-party SDKs.
- Request minimum required permissions. Do not request entitlements not actively used.

## Liskov Substitution Principle

- Every protocol method must have a meaningful implementation in every conforming type. Silent no-ops and unconditional "not supported" throws not gated by capability checks are violations.
- No domain or presentation code may branch on the concrete type behind a protocol reference. Use capability flags for all implementation differences.
- No concrete data-layer type may be referenced by name in domain or presentation code.
- When adding a new protocol, verify conformance correctness across all implementing types before committing.

## Dependency and API policy

Before adding a third-party package or API:

1. Check whether Apple frameworks already solve the problem.
2. Prefer actively maintained SPM packages.
3. Evaluate license, security, binary size, lock-in, and cross-platform impact.
4. Capture rationale, alternatives, and rollback plan in docs or PR notes.

## Testing policy

- Add or update tests for non-trivial changes.
- Use protocol-based test doubles for gRPC stubs. Never hit real endpoints in unit or integration tests.
- Prefer unit tests for domain logic.
- Use integration tests at module seams.
- Use XCUITest for native UI coverage.
- Consider Maestro for black-box simulator flows only when it reduces effort.
- Do not claim code works without an actual verification path.

## Git and review policy

- Keep commits coherent.
- Separate formatting-only changes from behavior changes where practical.
- Preserve existing behavior during refactors unless the task says otherwise.
- Document setup changes.
- Do not commit generated Protobuf or gRPC Swift files.

## Scripts

The `scripts/` directory contains shell scripts agents and developers use to validate,
test, format, and generate code. Make them executable on first checkout: `chmod +x scripts/*.sh`.

| Script | Purpose | Call |
|---|---|---|
| `bootstrap.sh` | First-time setup — resolves SPM dependencies | Manual, once per machine |
| `format.sh` | Format Swift (swift-format). Manual only — not in the auto-hook | `repo-ops` or manual pre-commit |
| `test.sh` | Run test suite only | `repo-ops` or manual |
| `validate.sh` | Full build + test suite | `repo-ops` or manual pre-commit |
| `proto-gen.sh` | Run buf lint + buf generate after .proto edits | `grpc-schema` or manual |
| `agent-post-edit-check.sh` | Auto build-check. **Never call manually.** | Claude Code PostToolUse hook only |

Set `XCODE_SCHEME` and `XCODE_DESTINATION` in `validate.sh` and `test.sh` before first use —
without them, xcodebuild steps are skipped silently (a warning is printed).

## BACKLOG permissions and deferral comments

**What you may do:** Add typed deferral comments in code when you encounter work that
cannot be completed within the current phase scope. Report them in your completion report.

**What you may not do:** Write to `BACKLOG.md`. Resolve or modify existing BACKLOG entries.

**Deferral comment syntax (Swift):**
```swift
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(critical|functional|polish): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```
Always write `TD-TBD`. Never invent a TD number.

**BACKLOG write permissions by agent:**

| Agent | May do | May not do |
|---|---|---|
| `coder` | Write TD-TBD comments; report in completion report | Write to BACKLOG.md |
| `reviewer` | Add ⚠️ findings as new BACKLOG entries | Modify or resolve existing entries |
| `docs-researcher` | Read only | Write anything |
| `repo-ops` | Read only | Write anything |

## Anti-patterns — never introduce

- Calling gRPC stubs directly from ViewModels or Views.
- Auth tokens in Protobuf message fields.
- @unchecked Sendable without audited justification.
- Force unwraps as convenience.
- print() in production code.
- Singleton sprawl for injectable services.
- Mutable global state undocumented as such.
- Magic duration literals for gRPC deadlines.
- Editing generated Protobuf or gRPC code by hand.
- Leaking gRPC stream references across scene lifecycle.
- Domain types appearing in data-layer or transport-layer signatures.
- Hard deletion of user-modifiable objects — use soft-delete (tombstoning) where audit or logging requires data retention.

## Agent behavior

- Planning, coding, testing, review, refactoring, and repo operations are all allowed.
- Read existing code before adding new abstractions.
- Do not invent package APIs or Xcode settings.
- Prefer the smallest correct change.
- State uncertainty explicitly.
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
