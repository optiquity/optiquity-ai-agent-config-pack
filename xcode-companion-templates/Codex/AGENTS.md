# AGENTS.md — Xcode 26.3 Codex Configuration
#
# This file lives at:
#   ~/Library/Developer/Xcode/CodingAssistant/codex/AGENTS.md
#
# It applies to every Xcode project on this machine.
# Do NOT commit this file into any app repository. It is user-local.
# Repo-level AGENTS.md files in each project take precedence for project-specific rules.

## Capability policy

Codex may perform all major engineering tasks in the active Xcode project:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for correctness-sensitive work.
- Use local models only where the verification path is strong.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform defaults

- SwiftUI first. UIKit or AppKit interop only when justified by platform gaps or measurable performance reasons.
- SPM first. No CocoaPods unless unavailable in SPM.
- Swift 6 strict concurrency for new code.

## Design rules

- Prefer immutable types by default.
- Mark classes `final` unless subclassing is required.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.

## Architecture — universal layer rules

- Separate presentation, domain, and data/transport layers. No layer skips its immediate neighbor.
- The domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, GRPCCore, or any networking or persistence framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. Never in domain or presentation type signatures.
- Every cross-layer dependency is expressed as a protocol. Concrete types are injected.
- Every shared mutable state declaration documents owner, actor/thread, lifecycle, and mutation contract.
- Services are stateless by default. Stateful services document their state and threading guarantees.
- Navigation logic lives outside View and ViewModel types.

## gRPC client rules (grpc-swift-2)

This machine uses grpc-swift-2 (https://github.com/grpc/grpc-swift-2).
Do not use grpc-swift v1 APIs in new code.

- Never call gRPC stubs from ViewModels or Views. Wrap behind a protocol.
- Auth tokens in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call has an explicit deadline using a named constant.
- Catch RPCError (GRPCCore), not GRPCStatus (v1). Map to domain errors at the boundary.
- Never hand-edit generated Protobuf or gRPC Swift code.
- One GRPCClient per app or scene lifecycle.

## Phase routing — default agent assignments

| Phase | Default | Key reason |
|---|---|---|
| Architecture / design | Claude Code | Multi-file context, extended reasoning |
| API and schema design | Claude Code | Schema tools, buf integration |
| Planning / task breakdown | Claude Code | Tiebreaker |
| Dependency evaluation | Claude Code | Web search, tradeoff analysis |
| Implementation | Codex | workspace-write sandbox |
| Code review | Claude Code | Deep multi-file analysis |
| Testing | Codex | Pattern generation |
| Debugging | Claude Code | Multi-step reasoning, Bash diagnostics |
| Refactoring | Codex | Mechanical changes in sandbox |
| Repo operations | Codex | workspace-write sandbox |

## Agent behavior

- Read existing code before adding new abstractions.
- Do not invent package APIs or Xcode settings.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- When using a local model, avoid high-risk changes unless a stronger model has reviewed the plan.
